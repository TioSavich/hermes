/*
 * hermes-shell.js — the one persistent app shell for every Hermes page.
 *
 * Drop a single tag in a page's <head> (or end of <body>):
 *
 *   <script defer src="/more-zeeman/render/hermes-shell.js"
 *           data-root="/more-zeeman/" data-app="/" data-active="base-ten"></script>
 *
 * It wraps the page's existing <body> content in an app frame: a grouped,
 * collapsible left sidebar (Workspace / Tools / Journey / Philosophy) and a
 * slim top bar (collapse toggle, page title, a slot the host page can fill).
 * It reads its palette from whichever token sheet the page already loaded —
 * warm hermes-tokens.css for the console + tools, dark hermes-tokens-dark.css
 * for the journey + philosophy pages — so one shell serves both worlds.
 *
 * Config (all optional; sensible server defaults):
 *   data-root   path to the more-zeeman/ dir      (default "/more-zeeman/")
 *   data-app    path to the console/server root   (default "/")
 *   data-active id of the current page (see IDS)  (default: guessed from URL)
 *   data-skin   "warm" | "dark" (only forces the mark tint; palette is CSS)
 *
 * No build step, no framework, no fetch. Injects its own CSS.
 */
(function () {
  "use strict";
  if (window.__hermesAppShell) return;
  window.__hermesAppShell = true;

  // ---- locate config on the script tag -----------------------------------
  function thisScript() {
    if (document.currentScript) return document.currentScript;
    var s = document.getElementsByTagName("script");
    for (var i = s.length - 1; i >= 0; i--) {
      if (/hermes-shell\.js(\?|$)/.test(s[i].src || "")) return s[i];
    }
    return null;
  }
  var S = thisScript();
  function attr(name, dflt) {
    var v = S && S.getAttribute(name);
    return (v == null || v === "") ? dflt : v;
  }
  var ROOT = attr("data-root", "/more-zeeman/");
  var APP = attr("data-app", "/");
  if (ROOT.slice(-1) !== "/") ROOT += "/";
  if (APP.slice(-1) !== "/") APP += "/";
  // Over file:// there is no server root; in a repo checkout the console pages
  // sit at ../hermes/app/web/ relative to more-zeeman/. This keeps the sidebar's
  // Workspace + Philosophy links working when pages are opened straight from disk.
  if (location.protocol === "file:" && APP === "/") APP = ROOT + "../hermes/app/web/";
  var FORCED_ACTIVE = attr("data-active", "");

  // mz(x) -> more-zeeman file ; app(x) -> console/server-root file
  function mz(f) { return ROOT + f; }
  function app(f) { return APP + f; }

  // ---- the app map -------------------------------------------------------
  // Each item: [id, label, href]. Sections group them.
  var NAV = [
    { title: "Workspace", kind: "console", items: [
      ["about",       "Start here",       app("about.html")],
      ["audience",    "Audience tour",    mz("audience-index.html")],
      ["discussions", "Discussions",      app("discussions.html")],
      ["console",     "Console",          app("console.html")],
      ["monitoring",  "Monitoring chart", mz("monitoring_chart.html")],
      ["atlas",       "Capability Atlas", mz("atlas.html")],
      ["witnesses",   "Witnesses",        mz("witnesses.html")],
    ]},
    { title: "Tools", kind: "tools", items: [
      ["visualizations", "All visualizers", mz("visualizations.html")],
      ["number-line",    "Number line",     mz("number-line/index.html")],
      ["fraction-bars",  "Fraction bars",   mz("fraction-bars/index.html")],
      ["area-model",     "Area model",      mz("area-model/index.html")],
      ["base-ten",       "Ace of Base",     mz("base-ten/index.html")],
      ["set-grouping",   "Set & grouping",  mz("set-grouping/index.html")],
      ["balance-scale",  "Balance scale",   mz("balance-scale/index.html")],
      ["place-value-chart", "Place-value chart", mz("place-value-chart/index.html")],
      ["notation",       "Notation",        mz("notation/index.html")],
      ["hybridization",  "Hybridization",   mz("hybridization/index.html")],
      ["gallery",        "Gallery",         mz("gallery.html")],
    ]},
    { title: "Critical Mathematics", kind: "critical", items: [
      ["no",         "Two ways to say no",   app("no.html")],
      ["breaks",     "Where it breaks",      app("breaks.html")],
      ["landing",    "The journey — overview", mz("landing.html")],
      ["snap",       "The Snap",    mz("index.html")],
      ["counting",   "Counting",    mz("counting.html")],
      ["crisis",     "Crisis",      mz("crisis.html")],
      ["strategies", "Strategies",  mz("strategies.html")],
      ["fractal",    "The Fractal", mz("fractal.html")],
      ["playground", "Playground",  mz("playground.html")],
      ["boundary",   "Boundary",    mz("boundary.html")],
      ["matrix",     "The Matrix",  mz("matrix.html")],
      ["muds",       "Meaning-Use Diagrams", mz("muds.html")],
    ]},
    { title: "Research wing", kind: "research", items: [
      ["bridge",       "The Bridge",       mz("bridge.html")],
      ["coordination", "Unit coordination", mz("coordination.html")],
      ["reorganization", "Reorganization", "/learner/reorg_demo.html"],
    ]},
  ];

  // ---- which item is active ----------------------------------------------
  function guessActive() {
    if (FORCED_ACTIVE) return FORCED_ACTIVE;
    var path = location.pathname;
    var file = (path.split("/").pop() || "index.html").toLowerCase();
    // tools live one dir deep: match the folder name
    var dirs = ["number-line", "fraction-bars", "area-model", "base-ten",
                "set-grouping", "balance-scale", "place-value-chart",
                "notation", "hybridization"];
    for (var i = 0; i < dirs.length; i++) {
      if (path.indexOf("/" + dirs[i] + "/") !== -1) return dirs[i];
    }
    var byFile = {
      "discussions.html": "discussions", "console.html": "console",
      "monitoring_chart.html": "monitoring", "visualizations.html": "visualizations",
      "atlas.html": "atlas", "witnesses.html": "witnesses",
      "gallery.html": "gallery", "audience-index.html": "audience",
      "landing.html": "landing", "index.html": "snap", "counting.html": "counting",
      "crisis.html": "crisis", "strategies.html": "strategies",
      "playground.html": "playground", "bridge.html": "bridge",
      "coordination.html": "coordination", "reorg_demo.html": "reorganization",
      "fractal.html": "fractal", "boundary.html": "boundary", "matrix.html": "matrix",
      "no.html": "no", "breaks.html": "breaks", "muds.html": "muds",
      "about.html": "about",
      "home.html": "home",
    };
    return byFile[file] || "";
  }
  var ACTIVE = guessActive();

  // ---- persisted collapse state ------------------------------------------
  var COLLAPSE_KEY = "hermes-shell-collapsed";
  function isCollapsed() {
    try { return localStorage.getItem(COLLAPSE_KEY) === "1"; } catch (e) { return false; }
  }
  function setCollapsed(v) {
    try { localStorage.setItem(COLLAPSE_KEY, v ? "1" : "0"); } catch (e) {}
  }

  // ---- CSS ---------------------------------------------------------------
  var CSS = `
  :root { --hshell-w: 236px; --hshell-top: 46px; }
  html.hshell-ready, html.hshell-ready body { height: 100%; }
  html.hshell-ready body {
    margin: 0; padding: 0; max-width: none; width: auto;
    display: grid; min-height: 100vh; height: 100vh;
    grid-template-columns: var(--hshell-w) minmax(0, 1fr);
    grid-template-rows: var(--hshell-top) minmax(0, 1fr);
    grid-template-areas: "brand top" "side main";
    transition: grid-template-columns .18s ease;
  }
  html.hshell-collapsed body { --hshell-w: 0px; }

  /* ---- brand cell (top-left) ---- */
  .hshell-brand {
    grid-area: brand; display: flex; align-items: center; gap: 9px;
    padding: 0 14px; min-width: 0; overflow: hidden;
    background: var(--paper-cool, var(--surface, #ede4cf));
    border-right: 1px solid var(--line, var(--border, rgba(0,0,0,.16)));
    border-bottom: 1px solid var(--line, var(--border, rgba(0,0,0,.16)));
    text-decoration: none; color: inherit;
  }
  .hshell-brand img { width: 26px; height: 26px; flex: 0 0 auto; border-radius: 5px; }
  .hshell-brand .nm { font: 600 15px/1 var(--serif, Georgia, serif); letter-spacing:.01em;
    color: var(--ink, var(--text, #1b1810)); white-space: nowrap; }
  .hshell-brand .sub { display:block; font: 500 8.5px/1.3 var(--mono, ui-monospace, monospace);
    letter-spacing:.14em; text-transform: uppercase; color: var(--muted, #6c6452); margin-top: 2px; }
  html.hshell-collapsed .hshell-brand { border-right: 0; padding-left: 10px; }
  html.hshell-collapsed .hshell-brand .nm, html.hshell-collapsed .hshell-brand .txt { display: none; }

  /* ---- top bar ---- */
  .hshell-top {
    grid-area: top; display: flex; align-items: center; gap: 12px;
    padding: 0 16px; min-width: 0;
    background: var(--paper-cool, var(--surface, #ede4cf));
    border-bottom: 1px solid var(--line, var(--border, rgba(0,0,0,.16)));
  }
  .hshell-toggle {
    flex: 0 0 auto; width: 30px; height: 30px; display: grid; place-items: center;
    background: transparent; border: 1px solid transparent; border-radius: 7px;
    color: var(--muted, #6c6452); cursor: pointer; transition: background .12s, color .12s;
  }
  .hshell-toggle:hover { background: rgba(127,127,127,.12); color: var(--ink, var(--text,#1b1810)); }
  .hshell-toggle svg { width: 17px; height: 17px; }
  .hshell-crumb { font: 600 13.5px/1 var(--serif, Georgia, serif);
    color: var(--ink, var(--text, #1b1810)); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
  .hshell-crumb .sec { color: var(--muted, #6c6452); font-weight: 400; }
  .hshell-crumb .sep { color: var(--muted, #6c6452); opacity: .5; margin: 0 7px; }
  .hshell-slot { margin-left: auto; display: flex; align-items: center; gap: 8px; min-width: 0; }

  /* ---- sidebar ---- */
  .hshell-side {
    grid-area: side; overflow-y: auto; overflow-x: hidden;
    background: var(--paper-cool, var(--surface, #ede4cf));
    border-right: 1px solid var(--line, var(--border, rgba(0,0,0,.16)));
    padding: 8px 10px 22px; scrollbar-width: thin;
  }
  html.hshell-collapsed .hshell-side, html.hshell-collapsed .hshell-brand { display: none; }
  .hshell-sec { margin-top: 12px; }
  .hshell-sec:first-child { margin-top: 4px; }
  .hshell-sec > .lbl {
    display: flex; align-items: center; gap: 7px; width: 100%;
    font: 600 9.5px/1 var(--mono, ui-monospace, monospace); letter-spacing: .15em;
    text-transform: uppercase; color: var(--muted, #6c6452);
    background: transparent; border: 0; cursor: pointer;
    padding: 8px 8px 6px; border-radius: 6px;
  }
  .hshell-sec > .lbl:hover { color: var(--ink, var(--text, #1b1810)); }
  .hshell-sec > .lbl .dot { width: 6px; height: 6px; border-radius: 50%; flex: 0 0 auto; }
  .hshell-sec > .lbl .chev { margin-left: auto; transition: transform .16s ease; opacity:.6; }
  .hshell-sec.closed > .lbl .chev { transform: rotate(-90deg); }
  .hshell-sec.closed > .items { display: none; }
  .hshell-item {
    display: block; text-decoration: none; border-radius: 7px;
    padding: 6px 10px 6px 21px; margin: 1px 0; position: relative;
    font: 400 13px/1.3 var(--serif, Georgia, serif);
    color: var(--ink-soft, var(--text, #1b1810)); opacity: .82;
    transition: background .12s, opacity .12s, color .12s;
  }
  .hshell-item:hover { background: rgba(127,127,127,.1); opacity: 1; }
  .hshell-item.active {
    opacity: 1; font-weight: 600; color: var(--ink, var(--text, #1b1810));
    background: var(--gold-pale, rgba(232,168,76,.14));
  }
  .hshell-item.active::before {
    content: ""; position: absolute; left: 8px; top: 7px; bottom: 7px; width: 3px;
    border-radius: 2px; background: var(--gold-deep, var(--snap, #a97c24));
  }

  /* ---- responsive: off-canvas under 860px ---- */
  @media (max-width: 860px) {
    html.hshell-ready body {
      grid-template-columns: 0 minmax(0,1fr);
      grid-template-areas: "top top" "main main";
    }
    .hshell-brand { position: fixed; }
    .hshell-side, .hshell-brand { position: fixed; top: 0; left: 0; width: var(--hshell-w, 236px); z-index: 60; }
    .hshell-side { top: var(--hshell-top); height: calc(100vh - var(--hshell-top)); }
    html.hshell-mobileopen { --hshell-w: 236px; }
    html:not(.hshell-mobileopen) .hshell-side, html:not(.hshell-mobileopen) .hshell-brand { display: none; }
    .hshell-scrim { position: fixed; inset: 0; z-index: 55; background: rgba(0,0,0,.4); }
    html:not(.hshell-mobileopen) .hshell-scrim { display: none; }
  }
  @media (min-width: 861px) { .hshell-scrim { display: none; } }

  /* ---- main content region ---- */
  .hshell-main { grid-area: main; min-width: 0; min-height: 0; overflow: auto; position: relative; }
  .hshell-main.fit { overflow: hidden; }
  /* legacy prose pages: fill the frame, but keep a centered reading column */
  .hshell-main.hshell-doc { padding: 12px clamp(16px, 4vw, 40px) 72px; }
  .hshell-main.hshell-doc > * { max-width: 720px; margin-left: auto; margin-right: auto; }
  /* wide interactive layouts (fractal canvas grid, playground stage) keep their room */
  .hshell-main.hshell-doc > .main-layout,
  .hshell-main.hshell-doc > .canvas-container { max-width: 1160px; }
  /* the sidebar eats width the page's own breakpoints don't know about:
     stack wide two-column layouts sooner so the canvas never gets crushed */
  @media (max-width: 1180px) {
    .hshell-main.hshell-doc > .main-layout { grid-template-columns: 1fr; }
  }
  /* the old "reveal" is retired: every phase is shown at once, no lurching */
  .hshell-main.hshell-doc .phase {
    opacity: 1 !important; max-height: none !important;
    overflow: visible !important; pointer-events: auto !important;
    transition: none !important;
  }
  `;

  // ---- SVG bits ----------------------------------------------------------
  var MARK = ROOT + "hermes_logo.svg";
  var ICON_MENU = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><line x1="4" y1="7" x2="20" y2="7"/><line x1="4" y1="12" x2="20" y2="12"/><line x1="4" y1="17" x2="20" y2="17"/></svg>';
  var CHEV = '<svg class="chev" width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 12 15 18 9"/></svg>';
  var SECTION_DOT = { console: "var(--rust,#b95238)", tools: "var(--gold-deep,var(--snap,#a97c24))",
    critical: "var(--teal-deep,var(--release,#2c5e66))",
    journey: "var(--teal-deep,var(--release,#2c5e66))", philosophy: "var(--muted,#6c6452)" };

  // ---- build DOM ---------------------------------------------------------
  function h(tag, cls, html) {
    var n = document.createElement(tag);
    if (cls) n.className = cls;
    if (html != null) n.innerHTML = html;
    return n;
  }

  function findActiveSection() {
    for (var i = 0; i < NAV.length; i++) {
      for (var j = 0; j < NAV[i].items.length; j++) {
        if (NAV[i].items[j][0] === ACTIVE) return { sec: NAV[i], item: NAV[i].items[j] };
      }
    }
    return null;
  }

  function build() {
    var style = h("style"); style.id = "hshell-css"; style.textContent = CSS;
    document.head.appendChild(style);

    // brand
    var brand = h("a", "hshell-brand");
    brand.href = mz("home.html");
    brand.title = "Hermes home";
    brand.innerHTML = '<img src="' + MARK + '" alt="">' +
      '<span class="txt"><span class="nm">Hermes</span>' +
      '<span class="sub">Hermeneutic Calculator</span></span>';

    // top bar
    var top = h("header", "hshell-top");
    var toggle = h("button", "hshell-toggle", ICON_MENU);
    toggle.setAttribute("aria-label", "Toggle navigation");
    var active = findActiveSection();
    var crumbHTML = active
      ? '<span class="sec">' + active.sec.title + '</span><span class="sep">/</span>' + active.item[1]
      : (document.title || "Hermes").replace(/\s*[—–|].*$/, "");
    var crumb = h("div", "hshell-crumb", crumbHTML);
    var slot = h("div", "hshell-slot"); slot.id = "hshell-slot";
    top.appendChild(toggle); top.appendChild(crumb); top.appendChild(slot);

    // sidebar
    var side = h("nav", "hshell-side");
    side.setAttribute("aria-label", "Sections");
    NAV.forEach(function (sec) {
      var secEl = h("div", "hshell-sec");
      var isActiveSec = active && active.sec === sec;
      if (!isActiveSec && active) secEl.className += " closed";
      var lbl = h("button", "lbl",
        '<span class="dot" style="background:' + (SECTION_DOT[sec.kind] || "var(--muted)") + '"></span>' +
        sec.title + CHEV);
      lbl.addEventListener("click", function () { secEl.classList.toggle("closed"); });
      secEl.appendChild(lbl);
      var items = h("div", "items");
      sec.items.forEach(function (it) {
        var a = h("a", "hshell-item" + (it[0] === ACTIVE ? " active" : ""), it[1]);
        a.href = it[2];
        if (it[0] === ACTIVE) a.setAttribute("aria-current", "page");
        items.appendChild(a);
      });
      secEl.appendChild(items);
      side.appendChild(secEl);
    });

    // wrap existing body content into main
    var main = h("div", "hshell-main");
    if (document.body.getAttribute("data-hshell-fit") === "1") main.classList.add("fit");
    if (document.body.getAttribute("data-hshell-doc") === "1") main.classList.add("hshell-doc");
    while (document.body.firstChild) main.appendChild(document.body.firstChild);

    var scrim = h("div", "hshell-scrim");

    document.body.appendChild(brand);
    document.body.appendChild(top);
    document.body.appendChild(side);
    document.body.appendChild(main);
    document.body.appendChild(scrim);

    // ---- interactions ----
    var mobile = function () { return window.matchMedia("(max-width: 860px)").matches; };
    function applyCollapsed() {
      document.documentElement.classList.toggle("hshell-collapsed", isCollapsed() && !mobile());
    }
    toggle.addEventListener("click", function () {
      if (mobile()) {
        document.documentElement.classList.toggle("hshell-mobileopen");
      } else {
        setCollapsed(!isCollapsed()); applyCollapsed();
      }
    });
    scrim.addEventListener("click", function () {
      document.documentElement.classList.remove("hshell-mobileopen");
    });
    window.addEventListener("resize", applyCollapsed);
    applyCollapsed();

    document.documentElement.classList.add("hshell-ready");
    window.HermesShell = { slot: slot, main: main };

    // ---- absorb any legacy nav (render/shell.js bar, shared.js top-bar) ----
    // shared.js injects its bar + discourse toggle on DOMContentLoaded, after
    // this defer script runs; adopt the discourse buttons into our top slot and
    // retire the old bars so pages carry one nav, not three.
    function integrateLegacy() {
      var db = document.querySelector(".discourse-buttons");
      if (db && db.parentNode !== slot) slot.appendChild(db);
      var junk = document.querySelectorAll(".top-bar, .hermes-shell, #journey-progress-bar, .journey-bar");
      for (var i = 0; i < junk.length; i++) {
        var b = junk[i];
        if (b === slot || b.closest(".hshell-side") || b.closest(".hshell-top")) continue;
        b.parentNode && b.parentNode.removeChild(b);
      }
    }
    window.addEventListener("load", integrateLegacy);
    setTimeout(integrateLegacy, 300);
    setTimeout(integrateLegacy, 900);
  }

  if (document.body) build();
  else document.addEventListener("DOMContentLoaded", build);
})();
