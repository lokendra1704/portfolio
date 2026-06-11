/* Benjamin Hadad · personal site
   Scroll state · seamless ticker · scroll reveals · nav scroll-spy */

(() => {
  "use strict";

  /* ---- collapse the header once the page is scrolled ---- */
  const setScrolled = () =>
    document.documentElement.classList.toggle("is-scrolled", window.scrollY > 24);
  setScrolled();
  window.addEventListener("scroll", setScrolled, { passive: true });

  /* ---- ticker: duplicate the track for a seamless -50% loop ---- */
  const track = document.querySelector("[data-ticker]");
  if (track) track.innerHTML += track.innerHTML;

  /* ---- reveal-on-scroll ---- */
  const reveals = document.querySelectorAll(".reveal, .reveal-stagger");
  if ("IntersectionObserver" in window) {
    const io = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (entry.isIntersecting) {
            entry.target.classList.add("is-visible");
            io.unobserve(entry.target);
          }
        }
      },
      { threshold: 0.16, rootMargin: "0px 0px -7% 0px" }
    );
    reveals.forEach((el) => io.observe(el));
  } else {
    reveals.forEach((el) => el.classList.add("is-visible"));
  }

  /* ---- nav scroll-spy ---- */
  const links = Array.from(document.querySelectorAll(".site-nav a"));
  const sections = links
    .map((a) => {
      const id = a.getAttribute("href");
      return id && id.startsWith("#") ? document.querySelector(id) : null;
    })
    .filter(Boolean);

  if ("IntersectionObserver" in window && sections.length) {
    const setActive = (id) => {
      for (const a of links) a.toggleAttribute("data-active", a.getAttribute("href") === id);
    };
    const spy = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (entry.isIntersecting) setActive("#" + entry.target.id);
        }
      },
      { rootMargin: "-42% 0px -53% 0px", threshold: 0 }
    );
    sections.forEach((s) => spy.observe(s));
  }
})();
