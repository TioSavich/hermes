/*
 * shell.js — the single navigation bar for every public Hermes page.
 *
 * One script tag pointing at render/shell.js in a page head is the whole
 * wiring. The script finds the more-zeeman root from its own src, loads
 * shell.css beside itself, and injects a sticky top bar: the Hermes mark + a
 * home link to the front door, the page title, a Tools/Journey surface
 * switcher, and a "back to index" link to the current surface's index.
 *
 * It computes every link relative to the more-zeeman root, so the bar works
 * the same offline over file:// and on the :8765 server (where the directory
 * mounts under /more-zeeman/). No build step, no framework, no fetch.
 *
 * Surfaces (theory entry = landing.html):
 *   Tools   — the visualizers + visualizations.html (light token sheet)
 *   Journey — the narrative/philosophy pages (dark token sheet), index landing.html
 *   Console — Hermes, private, server root "/"  (the front door links it; the
 *             bar does not, since the console is not part of the public walk)
 */
(function () {
  "use strict";

  if (window.__hermesShellLoaded) return;
  window.__hermesShellLoaded = true;

  // --- locate this script and the more-zeeman root ------------------------
  function currentScript() {
    if (document.currentScript) return document.currentScript;
    var all = document.getElementsByTagName("script");
    for (var i = all.length - 1; i >= 0; i--) {
      if (/render\/shell\.js(\?|$)/.test(all[i].src || "")) return all[i];
    }
    return null;
  }

  var self = currentScript();
  // src like ".../more-zeeman/render/shell.js" or "../render/shell.js".
  // The root is the directory holding render/, i.e. shell.js src with the
  // trailing "render/shell.js" stripped. Keep it relative when it was given
  // relative so file:// keeps working.
  var src = (self && self.getAttribute("src")) || "render/shell.js";
  var root = src.replace(/render\/shell\.js(\?.*)?$/, "");
  if (root === "") root = "./";

  function href(rel) { return root + rel; }

  // --- load shell.css beside this script (once) ---------------------------
  if (!document.querySelector('link[data-hermes-shell-css]')) {
    var link = document.createElement("link");
    link.rel = "stylesheet";
    link.href = href("render/shell.css");
    link.setAttribute("data-hermes-shell-css", "1");
    document.head.appendChild(link);
  }

  // --- which surface is this page? ----------------------------------------
  // Tools pages live one directory deep under a visualizer folder, or are
  // visualizations.html at the root. Everything else public is Journey.
  var path = location.pathname;
  var file = path.split("/").pop() || "index.html";
  var TOOLS_DIRS = ["ace-of-base", "area-model", "balance-scale", "base-ten",
                    "fraction-bars", "number-line", "set-grouping"];
  var inToolsDir = TOOLS_DIRS.some(function (d) {
    return path.indexOf("/" + d + "/") !== -1;
  });
  var isTools = inToolsDir || file === "visualizations.html";
  var surface = isTools ? "tools" : "journey";

  // Index of the current surface (relative to the more-zeeman root).
  var surfaceIndex = isTools ? "visualizations.html" : "landing.html";

  // --- page title for the bar ---------------------------------------------
  var pageTitle = (document.title || "").replace(/\s*[—–|-].*$/, "").trim();
  if (!pageTitle) pageTitle = document.title || "";

  // --- build the bar ------------------------------------------------------
  // The Hermes mark mirrors the favicon: a framed bar diagram with a gold unit.
  var MARK =
    "data:image/svg+xml,%3Csvg%20xmlns='http://www.w3.org/2000/svg'%20viewBox='0%200%2016%2016'%3E" +
    "%3Crect%20x='1.5'%20y='3'%20width='13'%20height='10'%20fill='none'%20stroke='%23a97c24'%20stroke-width='1'/%3E" +
    "%3Crect%20x='4'%20y='3'%20width='0.8'%20height='10'%20fill='%23a97c24'/%3E" +
    "%3Crect%20x='11.2'%20y='3'%20width='0.8'%20height='10'%20fill='%23a97c24'/%3E" +
    "%3Crect%20x='6.5'%20y='6'%20width='3'%20height='4'%20fill='%23d4a747'/%3E%3C/svg%3E";

  var bar = document.createElement("nav");
  bar.className = "hermes-shell";
  bar.setAttribute("aria-label", "site");

  function el(tag, cls, text) {
    var n = document.createElement(tag);
    if (cls) n.className = cls;
    if (text != null) n.textContent = text;
    return n;
  }

  // home (mark + name) -> front door
  var home = el("a", "hermes-shell__home");
  home.href = href("landing.html");
  home.title = "Hermes home";
  var img = el("img", "hermes-shell__mark");
  img.src = MARK;
  img.alt = "";
  home.appendChild(img);
  home.appendChild(document.createTextNode("Hermes"));
  bar.appendChild(home);

  // page title
  if (pageTitle) {
    var t = el("span", "hermes-shell__title", pageTitle);
    bar.appendChild(t);
  }

  // right cluster: surface switcher + back to index
  var navRight = el("div", "hermes-shell__nav");

  var tools = el("a", "hermes-shell__link" + (surface === "tools" ? " hermes-shell__link--active" : ""), "Tools");
  tools.href = href("visualizations.html");
  if (surface === "tools") tools.setAttribute("aria-current", "page");
  navRight.appendChild(tools);

  var journey = el("a", "hermes-shell__link" + (surface === "journey" ? " hermes-shell__link--active" : ""), "Journey");
  journey.href = href("landing.html");
  if (surface === "journey") journey.setAttribute("aria-current", "page");
  navRight.appendChild(journey);

  // back to this surface's index — only when the page is not already that index
  if (file !== surfaceIndex) {
    var back = el("a", "hermes-shell__back", "back to index");
    back.href = href(surfaceIndex);
    navRight.appendChild(back);
  }

  bar.appendChild(navRight);

  // --- inject as the first body child, push the page down -----------------
  function inject() {
    if (document.querySelector(".hermes-shell")) return;
    document.body.insertBefore(bar, document.body.firstChild);
  }
  if (document.body) inject();
  else document.addEventListener("DOMContentLoaded", inject);
})();
