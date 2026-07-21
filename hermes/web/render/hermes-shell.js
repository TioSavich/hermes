/*
 * hermes-shell.js — the one persistent app shell for every Hermes page.
 *
 * Drop a single tag in a page's <head> (or end of <body>):
 *
 *   <script defer src="/more-zeeman/render/hermes-shell.js"
 *           data-root="/more-zeeman/" data-app="/" data-active="base-ten"></script>
 *
 * It wraps the page's existing <body> content in an app frame: a grouped,
 * collapsible left sidebar (Practice / Theory / Research wing) and a
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
  // sit at ../app/web/ relative to hermes/web/. This keeps the sidebar's
  // Workspace + Philosophy links working when pages are opened straight from disk.
  if (location.protocol === "file:" && APP === "/") APP = ROOT + "../app/web/";
  var FORCED_ACTIVE = attr("data-active", "");

  // --- THE PRESENTATIONAL MAP (revisable; asserts nothing on disk) --------
  // Theme labels and assignments are orientation cues only. Re-theming a page
  // changes no route, folder, capability, or conceptual ownership.
  var THEMES = {
    recollection: { label: "Recollection",       light: "#5b4a9e", dark: "#b3a4ef" },
    norms:        { label: "Norms & curriculum", light: "#2f5f9e", dark: "#7ab0e6" },
    objects:      { label: "Objects",            light: "#a97c24", dark: "#e8a84c", lightInk: "#7a5a12" },
    body:         { label: "The feeling body",   light: "#b95238", dark: "#d4634a", lightInk: "#0d0c08" },
    negation:     { label: "Incompatibility",    light: "#3d6b45", dark: "#6b9e8c" },
    learner:      { label: "The learner",        light: "#2c7d78", dark: "#5bb4ae", lightInk: "#0d0c08" }
  };
  var PAGE = {
    console:        { theme: "norms",        lede: "Bring a mathematical discussion, computation, or lesson to the local workbench." },
    discussions:    { theme: "norms",        lede: "Build a claim-checked account of a discussion and keep the evidence attached." }, // R? recollection
    visualizations: { theme: "objects",      lede: "Run a representation filmstrip, then change its inputs when a worker is available." },
    witnesses:      { theme: "recollection", lede: "Query the finite witness families gathered from the loaded knowledge base." },
    monitoring:     { theme: "norms",        lede: "Assemble one lesson's standards, anticipated strategies, and recorded misconceptions." },
    gallery:        { theme: "objects",      lede: "Browse coded representation samples from the local asset manifest." },
    landing:        { theme: "recollection", lede: "Choose a door into Hermes or follow the theory journey from its shared entry." },
    no:             { theme: "negation",     lede: "Being wrong has structure: a rule, its domain, and the collision beyond that domain." },
    breaks:         { theme: "negation",     lede: "Run where a grounding metaphor or incompatibility relation reaches its boundary." },
    snap:           { theme: "body",         lede: "Drag the disc until accumulated tension produces a snap into another strategy." },
    counting:       { theme: "objects",      lede: "Counting by ones is correct and, past a point, unaffordable; follow the cost tally by tally." },
    crisis:         { theme: "body",         lede: "Work 38 + 55 by counting and mark the point where that method stops paying." },
    strategies:     { theme: "objects",      lede: "Run counting-on, COBO, and RMB as successively shorter strategic actions." },
    fractal:        { theme: "objects",      lede: "Run the nested strategy machines and change the conditions that propagate a snap." }, // R? body
    playground:     { theme: "body",         lede: "Drag one node and test when enough local snaps produce a new strategy ring." },
    boundary:       { theme: "objects",      lede: "Test what the action model handles at the boundary between counting and fractions." }, // R? negation
    matrix:         { theme: "body",         lede: "Follow each snap as it grows the memory grid and reorganizes repeated tallies." }, // R? objects
    muds:           { theme: "recollection", lede: "Trace the recorded relations between mathematical uses and their vocabularies." }, // R? negation
    scoreboard:     { theme: "norms",        lede: "Query commitments, entitlements, and inferential-strength records on one scoreboard." },
    atlas:          { theme: "recollection", lede: "Find each capability, the route that reaches it, and the page that calls it." },
    bridge:         { theme: "learner",      lede: "Run the formal bridge from a resource limit through consultation to a revised strategy." },
    coordination:   { theme: "learner",      lede: "Test how units are composed, repeated, and treated as new units." }, // R? objects
    reorganization: { theme: "learner",      lede: "Give the learner a fraction task, then test the strategy it builds after getting stuck." },
    "unit-echo":    { theme: "objects",      lede: "Run base regrouping beside fraction iteration at the same arity." },
    "fraction-bars":{ theme: "objects",      lede: "Draw a fraction operation from its action trace and change the operands." }
  };

  // mz(x) -> hermes/web file ; app(x) -> console/server-root file
  function mz(f) { return ROOT + f; }
  function app(f) { return APP + f; }

  // ---- the app map -------------------------------------------------------
  // Each item: [id, label, href]. Sections group them.
  var NAV = [
    { title: "Practice", kind: "practice", base: "light", items: [
      ["console",     "Console",          app("console.html")],
      ["explore",     "Explore lessons",  app("console.html#explore")],
      ["discussions", "Discussions",      app("discussions.html")],
      ["visualizations", "Visualizers",   mz("visualizations.html")],
      ["witnesses",   "Witnesses",        mz("witnesses.html")],
      ["monitoring",  "Monitoring chart", mz("monitoring_chart.html")],
      ["gallery",     "Gallery",          mz("gallery.html")],
    ]},
    { title: "Theory", kind: "theory", base: "dark", items: [
      ["landing",    "The journey — overview", mz("landing.html")],
      ["no",         "Two ways to say no",   app("no.html")],
      ["breaks",     "Where it breaks",      app("breaks.html")],
      ["snap",       "The Snap",    mz("index.html")],
      ["counting",   "Counting",    mz("counting.html")],
      ["crisis",     "Crisis",      mz("crisis.html")],
      ["strategies", "Strategies",  mz("strategies.html")],
      ["fractal",    "The Fractal", mz("fractal.html")],
      ["playground", "Playground",  mz("playground.html")],
      ["boundary",   "Boundary",    mz("boundary.html")],
      ["matrix",     "The Matrix",  mz("matrix.html")],
      ["muds",       "Meaning-Use Diagrams", mz("muds.html")],
      ["scoreboard", "Scoreboard",  mz("scoreboard.html")],
      ["atlas",      "Capability Atlas", mz("atlas.html")],
    ]},
    { title: "Research wing", kind: "research", base: "dark", items: [
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
    var byFile = {
      "discussions.html": "discussions", "console.html": "console",
      "monitoring_chart.html": "monitoring", "visualizations.html": "visualizations",
      "atlas.html": "atlas", "witnesses.html": "witnesses",
      "gallery.html": "gallery",
      "landing.html": "landing", "index.html": "snap", "counting.html": "counting",
      "crisis.html": "crisis", "strategies.html": "strategies",
      "playground.html": "playground", "bridge.html": "bridge",
      "coordination.html": "coordination", "reorg_demo.html": "reorganization",
      "fractal.html": "fractal", "boundary.html": "boundary", "matrix.html": "matrix",
      "no.html": "no", "breaks.html": "breaks", "muds.html": "muds",
      "scoreboard.html": "scoreboard",
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
  :root { --hshell-w: 236px; --hshell-top: 70px; }
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
    padding: 0 16px 24px; min-width: 0; position: relative;
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
  .hshell-chip { display: inline-block; margin-right: 8px; padding: 3px 7px;
    border: 1px solid var(--accent, currentColor); border-radius: 999px;
    color: var(--accent-ink, var(--accent, currentColor)); background: transparent;
    font: 600 9px/1 var(--mono, ui-monospace, monospace); letter-spacing: .06em;
    text-transform: uppercase; vertical-align: 1px; }
  .hshell-orientation { position: absolute; left: 0; right: 0; bottom: 0; height: 24px;
    display: flex; align-items: center; padding: 0 16px 0 58px; overflow: hidden;
    border-top: 1px solid color-mix(in srgb, var(--accent, currentColor) 32%, transparent);
    color: var(--muted, #6c6452); background: color-mix(in srgb, var(--accent, currentColor) 7%, transparent);
    font: 11px/1.2 var(--serif, Georgia, serif); white-space: nowrap; text-overflow: ellipsis; }
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
  .hshell-sec > .lbl .base {
    margin-left: auto; padding: 2px 5px; border: 1px solid var(--group-line);
    border-radius: 999px; color: var(--group-ink); background: var(--group-bg);
    font-size: 7.5px; letter-spacing: .09em; opacity: .78;
  }
  .hshell-sec[data-base="light"] { --group-bg: #f4ead6; --group-ink: #665f4f; --group-line: rgba(13,12,8,.22); }
  .hshell-sec[data-base="dark"] { --group-bg: #1a1710; --group-ink: #d4cfc0; --group-line: #3a3428; }
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
    background: color-mix(in srgb, var(--accent, var(--gold-deep, #a97c24)) 14%, transparent);
  }
  .hshell-item.active::before {
    content: ""; position: absolute; left: 8px; top: 7px; bottom: 7px; width: 3px;
    border-radius: 2px; background: var(--accent, var(--gold-deep, var(--snap, #a97c24)));
  }
  .hshell-item-dot { position: absolute; left: 9px; top: 50%; width: 6px; height: 6px;
    margin-top: -3px; border-radius: 50%; background: var(--item-accent, var(--muted)); }
  .hshell-item.active .hshell-item-dot { display: none; }

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

  /* ---- situated documentation ---- */
  .hshell-help-button {
    position: fixed; right: 18px; bottom: 18px; z-index: 70;
    width: 42px; height: 42px; border-radius: 50%; cursor: pointer;
    display: grid; place-items: center; padding: 0;
    border: 2px solid var(--accent, #a97c24);
    color: var(--accent-ink, var(--accent, #7a5a12));
    background: var(--paper-cool, var(--surface, #fffaf0));
    box-shadow: 0 5px 20px rgba(0,0,0,.24);
    font: 700 21px/1 var(--serif, Georgia, serif);
  }
  .hshell-help-button:hover, .hshell-help-button:focus-visible {
    background: color-mix(in srgb, var(--accent, #a97c24) 14%, var(--paper-cool, var(--surface, #fffaf0)));
    outline: 2px solid color-mix(in srgb, var(--accent, #a97c24) 45%, transparent);
    outline-offset: 2px;
  }
  .hshell-help-panel {
    position: fixed; right: 18px; bottom: 70px; z-index: 70;
    width: min(360px, calc(100vw - 28px)); height: min(470px, calc(100vh - 100px));
    display: grid; grid-template-rows: auto minmax(0, 1fr) auto auto;
    color: var(--ink, var(--text, #1b1810));
    background: var(--paper-cool, var(--surface, #fffaf0));
    border: 1px solid color-mix(in srgb, var(--accent, #a97c24) 42%, var(--line, var(--border, rgba(0,0,0,.2))));
    border-radius: 12px; overflow: hidden;
    box-shadow: 0 12px 36px rgba(0,0,0,.3);
  }
  .hshell-help-panel[hidden] { display: none; }
  .hshell-help-head {
    display: flex; align-items: center; gap: 8px; padding: 10px 12px;
    border-bottom: 1px solid var(--line, var(--border, rgba(0,0,0,.16)));
    font: 600 14px/1.2 var(--serif, Georgia, serif);
  }
  .hshell-help-close {
    margin-left: auto; border: 0; background: transparent; color: inherit;
    width: 28px; height: 28px; border-radius: 6px; cursor: pointer; font-size: 20px;
  }
  .hshell-help-close:hover { background: rgba(127,127,127,.12); }
  .hshell-help-conversation {
    overflow-y: auto; padding: 12px; display: flex; flex-direction: column; gap: 9px;
    font: 13px/1.45 var(--sans, system-ui, sans-serif);
  }
  .hshell-help-message { max-width: 90%; padding: 8px 10px; border-radius: 9px; white-space: pre-wrap; }
  .hshell-help-message.assistant { align-self: flex-start; background: rgba(127,127,127,.12); }
  .hshell-help-message.user {
    align-self: flex-end; color: var(--accent-ink, var(--ink, #1b1810));
    background: color-mix(in srgb, var(--accent, #a97c24) 17%, transparent);
  }
  .hshell-help-form { display: flex; gap: 7px; padding: 10px 10px 6px; }
  .hshell-help-input {
    min-width: 0; flex: 1; border: 1px solid var(--line, var(--border, rgba(0,0,0,.24)));
    border-radius: 7px; padding: 8px 9px; color: inherit;
    background: var(--paper, var(--surface-raised, #fff)); font: 13px/1.3 var(--sans, system-ui, sans-serif);
  }
  .hshell-help-submit {
    border: 1px solid var(--accent, #a97c24); border-radius: 7px; padding: 7px 10px;
    color: var(--accent-ink, var(--ink, #1b1810));
    background: color-mix(in srgb, var(--accent, #a97c24) 14%, transparent);
    cursor: pointer; font: 600 12px/1 var(--sans, system-ui, sans-serif);
  }
  .hshell-help-submit:disabled { cursor: wait; opacity: .55; }
  .hshell-help-state {
    min-height: 21px; padding: 0 11px 7px; color: var(--muted, #6c6452);
    font: 10px/1.4 var(--mono, ui-monospace, monospace);
  }
  .hshell-help-state.ready { color: #31733b; }
  .hshell-help-state.offline, .hshell-help-state.broken { color: #a13b2b; }
  @media (max-width: 520px) {
    .hshell-help-button { right: 14px; bottom: 14px; }
    .hshell-help-panel { right: 14px; bottom: 64px; height: min(440px, calc(100vh - 86px)); }
  }
  `;

  // ---- SVG bits ----------------------------------------------------------
  var MARK = ROOT + "hermes_logo.svg";
  var ICON_MENU = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><line x1="4" y1="7" x2="20" y2="7"/><line x1="4" y1="12" x2="20" y2="12"/><line x1="4" y1="17" x2="20" y2="17"/></svg>';
  var CHEV = '<svg class="chev" width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 12 15 18 9"/></svg>';
  // ---- build DOM ---------------------------------------------------------
  function h(tag, cls, html) {
    var n = document.createElement(tag);
    if (cls) n.className = cls;
    if (html != null) n.innerHTML = html;
    return n;
  }

  var requestClientPromise;
  function requestClient() {
    if (window.HermesFetch) return Promise.resolve(window.HermesFetch);
    if (requestClientPromise) return requestClientPromise;
    requestClientPromise = new Promise(function (resolve, reject) {
      var script = document.createElement("script");
      script.src = mz("render/request.js");
      script.onload = function () {
        if (window.HermesFetch) resolve(window.HermesFetch);
        else reject(new Error("The request helper did not load."));
      };
      script.onerror = function () { reject(new Error("The request helper is unavailable.")); };
      document.head.appendChild(script);
    });
    return requestClientPromise;
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
    var root = document.documentElement;
    var page = PAGE[ACTIVE];
    var declaredBase = root.getAttribute("data-hermes-base") ||
      getComputedStyle(root).getPropertyValue("--hermes-base").trim();
    var base = declaredBase === "dark" ? "dark" : "light";
    var theme = page && THEMES[page.theme];
    if (theme) {
      root.dataset.hermesTheme = page.theme;
      root.style.setProperty("--accent", theme[base]);
      // Chip text needs 4.5:1; a theme may name a darker ink for light bases
      // where its graphical accent alone would fall short.
      root.style.setProperty("--accent-ink",
        (base === "light" && theme.lightInk) || theme[base]);
    }
    var style = h("style"); style.id = "hshell-css"; style.textContent = CSS;
    document.head.appendChild(style);

    // brand
    var brand = h("a", "hshell-brand");
    brand.href = mz("landing.html");
    brand.title = "Hermes home";
    brand.innerHTML = '<img src="' + MARK + '" alt="">' +
      '<span class="txt"><span class="nm">Hermes</span>' +
      '<span class="sub">Hermeneutic Calculator</span></span>';

    // top bar
    var top = h("header", "hshell-top");
    var toggle = h("button", "hshell-toggle", ICON_MENU);
    toggle.setAttribute("aria-label", "Toggle navigation");
    var active = findActiveSection();
    var themeChip = theme ? '<span class="hshell-chip">' + theme.label + '</span>' : '';
    var crumbHTML = active
      ? themeChip + '<span class="sec">' + active.sec.title + '</span><span class="sep">/</span>' + active.item[1]
      : (document.title || "Hermes").replace(/\s*[—–|].*$/, "");
    var crumb = h("div", "hshell-crumb", crumbHTML);
    var slot = h("div", "hshell-slot"); slot.id = "hshell-slot";
    top.appendChild(toggle); top.appendChild(crumb); top.appendChild(slot);
    if (page && page.lede) {
      var orientation = h("div", "hshell-orientation");
      orientation.textContent = page.lede;
      top.appendChild(orientation);
    }

    // sidebar
    var side = h("nav", "hshell-side");
    side.setAttribute("aria-label", "Sections");
    NAV.forEach(function (sec) {
      var secEl = h("div", "hshell-sec");
      secEl.dataset.base = sec.base;
      var isActiveSec = active && active.sec === sec;
      if (!isActiveSec && active) secEl.className += " closed";
      var lbl = h("button", "lbl",
        '<span class="dot" style="background:var(--group-ink)"></span>' +
        sec.title + CHEV);
      lbl.addEventListener("click", function () { secEl.classList.toggle("closed"); });
      secEl.appendChild(lbl);
      var items = h("div", "items");
      sec.items.forEach(function (it) {
        var a = h("a", "hshell-item" + (it[0] === ACTIVE ? " active" : ""), it[1]);
        a.href = it[2];
        var itemPage = PAGE[it[0]], itemTheme = itemPage && THEMES[itemPage.theme];
        if (itemTheme) {
          a.style.setProperty("--item-accent", itemTheme[sec.base]);
          a.insertBefore(h("span", "hshell-item-dot"), a.firstChild);
        }
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

    // live, situated documentation
    var helpButton = h("button", "hshell-help-button", "?");
    helpButton.type = "button";
    helpButton.setAttribute("aria-label", "Ask about this page");
    helpButton.setAttribute("aria-expanded", "false");
    helpButton.setAttribute("aria-controls", "hshell-help-panel");
    var helpPanel = h("section", "hshell-help-panel");
    helpPanel.id = "hshell-help-panel";
    helpPanel.hidden = true;
    helpPanel.setAttribute("aria-label", "Live page documentation");
    var helpHead = h("div", "hshell-help-head", "Ask about this page");
    var helpClose = h("button", "hshell-help-close", "&times;");
    helpClose.type = "button";
    helpClose.setAttribute("aria-label", "Close documentation chat");
    helpHead.appendChild(helpClose);
    var helpConversation = h("div", "hshell-help-conversation");
    helpConversation.setAttribute("role", "log");
    helpConversation.setAttribute("aria-live", "polite");
    var helpIntro = h("div", "hshell-help-message assistant");
    helpIntro.textContent = "Ask why something is here, what an operation means, or how this page connects to another part of Hermes.";
    helpConversation.appendChild(helpIntro);
    var helpForm = h("form", "hshell-help-form");
    var helpInput = h("input", "hshell-help-input");
    helpInput.type = "text";
    helpInput.name = "question";
    helpInput.maxLength = 2000;
    helpInput.placeholder = "Why is this here?";
    helpInput.setAttribute("aria-label", "Question about this page");
    var helpSubmit = h("button", "hshell-help-submit", "Ask");
    helpSubmit.type = "submit";
    helpForm.appendChild(helpInput);
    helpForm.appendChild(helpSubmit);
    var helpState = h("div", "hshell-help-state");
    helpState.setAttribute("aria-live", "polite");
    helpPanel.appendChild(helpHead);
    helpPanel.appendChild(helpConversation);
    helpPanel.appendChild(helpForm);
    helpPanel.appendChild(helpState);

    document.body.appendChild(brand);
    document.body.appendChild(top);
    document.body.appendChild(side);
    document.body.appendChild(main);
    document.body.appendChild(scrim);
    document.body.appendChild(helpButton);
    document.body.appendChild(helpPanel);

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
    function setHelpOpen(open) {
      helpPanel.hidden = !open;
      helpButton.setAttribute("aria-expanded", open ? "true" : "false");
      if (open) helpInput.focus();
      else helpButton.focus();
    }
    function addHelpMessage(kind, text) {
      var message = h("div", "hshell-help-message " + kind);
      message.textContent = text;
      helpConversation.appendChild(message);
      helpConversation.scrollTop = helpConversation.scrollHeight;
    }
    helpButton.addEventListener("click", function () { setHelpOpen(helpPanel.hidden); });
    helpClose.addEventListener("click", function () { setHelpOpen(false); });
    helpPanel.addEventListener("keydown", function (event) {
      if (event.key === "Escape") setHelpOpen(false);
    });
    helpForm.addEventListener("submit", function (event) {
      event.preventDefault();
      var question = helpInput.value.trim();
      if (!question || helpSubmit.disabled) return;
      addHelpMessage("user", question);
      helpInput.value = "";
      helpSubmit.disabled = true;
      requestClient().then(function (client) {
        client.setState(helpState, "pending", "Reading this page's documentation...");
        return client.requestJSON("/api/help", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ question: question, page: ACTIVE }),
          timeoutMs: 120000
        }).then(function (result) { return { client: client, result: result }; });
      }).then(function (packet) {
        var result = packet.result;
        if (result.kind === "ok" && result.data && result.data.answer) {
          addHelpMessage("assistant", result.data.answer);
          packet.client.setState(helpState, "ready", "Answer grounded in the shipped documentation.");
          return;
        }
        var message = result.data && result.data.error
          ? result.data.error
          : packet.client.messageFor(result);
        addHelpMessage("assistant", message);
        packet.client.setState(helpState,
          result.kind === "offline" || result.kind === "timeout" || (result.data && result.data.error_type === "no_key") ? "offline" : "broken",
          message);
      }).catch(function (error) {
        addHelpMessage("assistant", error.message || "Live documentation is unavailable.");
        helpState.className = "hshell-help-state offline";
        helpState.textContent = "× Live documentation is unavailable.";
      }).finally(function () {
        helpSubmit.disabled = false;
        helpInput.focus();
      });
    });
    window.addEventListener("resize", applyCollapsed);
    applyCollapsed();

    document.documentElement.classList.add("hshell-ready");
    window.HermesShell = { slot: slot, main: main };

    // Retire static legacy bars still authored in older pages. Discourse
    // controls already live in the shell slot; this cleanup keeps one nav.
    function removeLegacyChrome() {
      var junk = document.querySelectorAll(".top-bar, .hermes-shell, #journey-progress-bar, .journey-bar");
      for (var i = 0; i < junk.length; i++) {
        var b = junk[i];
        if (b === slot || b.closest(".hshell-side") || b.closest(".hshell-top")) continue;
        b.parentNode && b.parentNode.removeChild(b);
      }
    }
    window.addEventListener("load", removeLegacyChrome);
    setTimeout(removeLegacyChrome, 300);
    setTimeout(removeLegacyChrome, 900);

  }

  if (document.body) build();
  else document.addEventListener("DOMContentLoaded", build);
})();
