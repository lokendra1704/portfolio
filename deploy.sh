#!/usr/bin/env bash
#
# Deploy the portfolio.
#
# Usage:
#   ./deploy.sh ["commit message"]
#
# 1. Commits source and pushes to the 'portfolio' repo (origin/main).
# 2. Mirrors the built site into the user-site repo so it goes live at
#    https://lokendra1704.github.io/  (creating that repo if it doesn't exist).

set -euo pipefail

BRANCH="main"
USER_SITE_REPO="lokendra1704/lokendra1704.github.io"
USER_SITE_URL="https://lokendra1704.github.io/"
MESSAGE="${1:-Deploy: $(date +'%Y-%m-%d %H:%M:%S')}"

# Files/dirs that make up the deployable site.
SITE_FILES=(index.html styles.css script.js portrait.jpg)

cd "$(dirname "$0")"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: not a git repository." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# 1. Commit + push source to the portfolio repo.
# ---------------------------------------------------------------------------
if [[ -n "$(git status --porcelain)" ]]; then
  echo "Committing changes..."
  git add -A
  git commit -m "$MESSAGE"
else
  echo "No changes to commit."
fi

echo "Pushing source to origin/$BRANCH..."
git push origin "$BRANCH"

# ---------------------------------------------------------------------------
# 2. Publish to the user-site repo (https://lokendra1704.github.io/).
# ---------------------------------------------------------------------------
if ! command -v gh >/dev/null 2>&1; then
  echo "Error: the GitHub CLI (gh) is required to publish the user site." >&2
  echo "Install it from https://cli.github.com/ and re-run." >&2
  exit 1
fi

# Create the user-site repo if it doesn't exist yet.
# Note: match on exact full_name -- a renamed repo can leave a redirect that
# makes `gh repo view` resolve this name to a *different* repo.
if [[ "$(gh repo view "$USER_SITE_REPO" --json nameWithOwner -q .nameWithOwner 2>/dev/null)" != "$USER_SITE_REPO" ]]; then
  echo "Creating user-site repo $USER_SITE_REPO..."
  gh api -X POST user/repos -f name="lokendra1704.github.io" -F private=false \
    -f description="Personal site" >/dev/null
fi

# Stage the deployable files in a temp checkout and push them.
# Use an explicit origin URL (not `gh repo clone`) so a name redirect can't
# point us at the wrong repo.
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

cd "$TMP_DIR"
git init -q
git checkout -q -B "$BRANCH"
git remote add origin "https://github.com/$USER_SITE_REPO.git"
git fetch -q origin "$BRANCH" 2>/dev/null && git reset -q --hard "origin/$BRANCH" || true

# Copy current site files over.
cd - >/dev/null
for f in "${SITE_FILES[@]}"; do
  cp -R "$f" "$TMP_DIR/"
done

cd "$TMP_DIR"
git add -A
if [[ -n "$(git status --porcelain)" ]]; then
  git commit -q -m "$MESSAGE"
  echo "Pushing site to $USER_SITE_REPO..."
  git push -u origin "$BRANCH"
else
  echo "User site already up to date."
fi

# Make sure Pages is enabled (serve from main root).
if ! gh api "repos/$USER_SITE_REPO/pages" >/dev/null 2>&1; then
  gh api -X POST "repos/$USER_SITE_REPO/pages" \
    -f "source[branch]=$BRANCH" -f "source[path]=/" >/dev/null 2>&1 \
    && echo "GitHub Pages enabled." \
    || echo "Enable Pages manually in repo Settings → Pages (Branch: $BRANCH, Folder: /root)."
fi

echo "Done. Live at: $USER_SITE_URL"
