/*
 * compare.js — the shared two-stage host for every more-zeeman compare page
 * (fraction-bars, number-line, area-model, …).
 *
 * Draws a productive/deformation pair as two filmstrips that share one step
 * index. It does not own the drawer: it reuses HermesDrawer._internal (buildSvg,
 * documentBounds) to render each side's frames, exactly the geometry the unified
 * single-stage host uses. Each compare worker op (fraction_compare,
 * number_line_compare, area_compare, …) returns
 *   { productive:{frames}, deformation:{frames}, note, productiveKind,
 *     deformationKind, canvas, [error] }
 * which the unified single-stage drawer cannot ingest (no top-level frames),
 * so this small host walks both sides itself.
 *
 * The page chooses which op the Calculate button POSTs by setting
 *   window.HermesCompare = { op: 'number_line_compare' }
 * before loading this script; it defaults to fraction_compare. On static pages
 * (GitHub Pages, no worker) Calculate is inert and the page renders from its
 * embedded #frames block — the op only matters when a live worker is present.
 *
 * No recompute in JS. The worker lays out the bars; this script steps them.
 */
(function () {
  'use strict';

  var DRAW = (window.HermesDrawer && window.HermesDrawer._internal) || null;
  var CFG = window.HermesCompare || {};
  var ENDPOINT = CFG.endpoint || '/api/render';
  var OP = CFG.op || 'fraction_compare';

  var state = { doc: null, index: 0, steps: 0 };

  function el(id) { return document.getElementById(id); }

  function clear(node) { while (node && node.firstChild) node.removeChild(node.firstChild); }

  function setText(node, txt) { if (node) node.textContent = txt || ''; }

  function showStageError(stageId, msg) {
    var stage = el(stageId);
    if (!stage) return;
    clear(stage);
    var p = document.createElement('p');
    p.className = 'error';
    p.textContent = msg;
    stage.appendChild(p);
  }

  function setBusy(on) {
    var btn = el('calculate');
    if (btn) btn.disabled = !!on;
    if (!on) return;
    ['prodStage', 'defStage'].forEach(function (id) {
      var stage = el(id);
      if (!stage) return;
      clear(stage);
      var p = document.createElement('p');
      p.className = 'loading';
      p.textContent = 'Working… (first run loads the engine, ~30s)';
      stage.appendChild(p);
    });
  }

  // Render one side's frame into its stage element via the shared drawer geometry.
  function drawSide(stageId, frames, bounds, index) {
    var stage = el(stageId);
    if (!stage) return;
    clear(stage);
    if (!DRAW || !Array.isArray(frames) || frames.length === 0) {
      showStageError(stageId, 'Nothing to draw on this side.');
      return;
    }
    var clamped = Math.max(0, Math.min(index, frames.length - 1));
    var svg = DRAW.buildSvg(frames[clamped], bounds);
    stage.appendChild(svg);
  }

  function caption(frames, index) {
    if (!Array.isArray(frames) || frames.length === 0) return '';
    var finished = index >= frames.length;
    var f = frames[Math.max(0, Math.min(index, frames.length - 1))];
    var text = (f && f.caption) || '';
    return finished ? 'This side has finished. ' + text : text;
  }

  function plainName(value) {
    var text = String(value || '').replace(/_/g, ' ').trim();
    return text ? text.charAt(0).toUpperCase() + text.slice(1) : '';
  }

  function researchValue(value) {
    if (value === undefined || value === null) return '';
    if (typeof value === 'string' || typeof value === 'number') return String(value);
    return JSON.stringify(value);
  }

  function setBoundary(message) {
    var note = el('boundaryNote');
    if (!note) return;
    note.textContent = message || '';
    note.hidden = !message;
  }

  function render() {
    var doc = state.doc;
    if (!doc) return;
    setText(el('result'), '');
    setBoundary('');
    setText(el('context'), plainName(doc.productiveKind) +
      (doc.deformationKind ? ' vs ' + plainName(doc.deformationKind) : ''));
    setText(el('prodKind'), plainName(doc.productiveKind));
    setText(el('defKind'), plainName(doc.deformationKind));
    setText(el('teacherNote'), doc.note || '');
    setText(el('formalNote'),
      (doc.productiveKind || '?') + ' → ' + (doc.deformationKind || '?') +
      (doc.family ? '  (family: ' + doc.family + ')' : ''));
    setText(el('divergenceNote'), doc.divergence
      ? 'Divergence for these inputs: productive result ' +
        researchValue(doc.divergence.productiveResult) + '; deformation result ' +
        researchValue(doc.divergence.deformationResult) + '.'
      : 'Divergence for these inputs: the two result fields agree.');
    setText(el('viabilityNote'), doc.viability
      ? 'Viability: ' + plainName(doc.viability.status) + '. Condition: ' +
        plainName(doc.viability.condition) + '. Validity: ' +
        plainName(doc.viability.validity) + '.'
      : 'No viability record is available for this comparison.');
    setText(el('compareNote'), doc.note || '');

    // An honest "not yet drawable as a 1-D bar divergence" pair: the worker
    // returns empty frames and an error string. Show it rather than a blank.
    var prod = (doc.productive && doc.productive.frames) || [];
    var def = (doc.deformation && doc.deformation.frames) || [];
    if (doc.error && prod.length === 0 && def.length === 0) {
      state.steps = 0;
      clear(el('prodStage'));
      clear(el('defStage'));
      setBoundary(doc.error);
      setText(el('prodCap'), '');
      setText(el('defCap'), '');
      setText(el('counter'), '');
      var slider0 = el('seek');
      if (slider0) { slider0.max = '0'; slider0.value = '0'; }
      var prev0 = el('prev');
      var next0 = el('next');
      if (prev0) prev0.disabled = true;
      if (next0) next0.disabled = true;
      return;
    }

    state.steps = Math.max(prod.length, def.length);
    if (state.index >= state.steps) state.index = state.steps - 1;
    if (state.index < 0) state.index = 0;

    var bounds = DRAW.documentBounds(prod.concat(def), doc.canvas);
    drawSide('prodStage', prod, bounds, state.index);
    drawSide('defStage', def, bounds, state.index);
    setText(el('prodCap'), caption(prod, state.index));
    setText(el('defCap'), caption(def, state.index));
    setText(el('counter'), state.steps ? ('step ' + (state.index + 1) + ' of ' + state.steps) : '');

    var slider = el('seek');
    if (slider) {
      slider.max = String(Math.max(0, state.steps - 1));
      slider.value = String(state.index);
    }
    var prev = el('prev');
    var next = el('next');
    if (prev) prev.disabled = state.index <= 0;
    if (next) next.disabled = state.index >= state.steps - 1;
  }

  function goTo(i) {
    if (!state.steps) return;
    state.index = Math.max(0, Math.min(i, state.steps - 1));
    render();
  }

  function ingest(doc) {
    state.doc = doc;
    state.index = 0;
    render();
  }

  // --- audience toggle (mirrors host.css view-freshman|teacher|philosopher) ---
  function setView(view) {
    document.body.className = 'view-' + view;
    var toggles = document.querySelectorAll('[data-view]');
    Array.prototype.forEach.call(toggles, function (b) {
      b.classList.toggle('active', b.getAttribute('data-view') === view);
    });
  }

  // --- worker bridge ----------------------------------------------------------
  function collectInputs() {
    var out = {};
    var inputs = document.querySelectorAll('[data-arg]');
    Array.prototype.forEach.call(inputs, function (node) {
      if (node.disabled || node.closest('[hidden]')) return;
      var key = node.getAttribute('data-arg');
      out[key] = (node.type === 'number') ? Number(node.value) : node.value;
    });
    return out;
  }

  function calculate() {
    var payload = { op: OP };
    Object.assign(payload, collectInputs());
    setBusy(true);
    fetch(ENDPOINT, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    }).then(function (r) {
      return r.json().catch(function () { return null; }).then(function (body) {
        return { ok: r.ok, status: r.status, body: body };
      });
    }).then(function (resp) {
      setBusy(false);
      var body = resp.body;
      // A transport / op failure with no drawable sides. (A drawable-but-honest
      // "not yet a 1-D divergence" pair still carries productive/deformation, so
      // it falls through to ingest and render() shows the error per stage.)
      if (body && typeof body === 'object' && (body.ok === false || (body.error && !body.productive))) {
        showStageError('prodStage', 'The engine could not draw this: ' +
          (body.error || ('HTTP ' + resp.status)));
        showStageError('defStage', '');
        return;
      }
      if (!resp.ok || !body || typeof body !== 'object') {
        showStageError('prodStage', 'The engine returned an error (HTTP ' + resp.status + ').');
        return;
      }
      // The compare document IS the body (productive/deformation/note). Some
      // worker transports wrap it as {result:<document>}; unwrap only that.
      var doc = body;
      if (!doc.productive && doc.result && typeof doc.result === 'object') doc = doc.result;
      ingest(doc);
    }).catch(function (err) {
      setBusy(false);
      showStageError('prodStage', 'Calculate failed: ' + (err && err.message ? err.message : err));
    });
  }

  function wire() {
    var prev = el('prev');
    var next = el('next');
    var seek = el('seek');
    var calc = el('calculate');
    if (prev) prev.addEventListener('click', function () { goTo(state.index - 1); });
    if (next) next.addEventListener('click', function () { goTo(state.index + 1); });
    if (seek) seek.addEventListener('input', function (e) { goTo(Number(e.target.value)); });
    if (calc) calc.addEventListener('click', calculate);
    document.addEventListener('keydown', function (e) {
      if (e.key === 'ArrowLeft') goTo(state.index - 1);
      else if (e.key === 'ArrowRight') goTo(state.index + 1);
    });
    var toggles = document.querySelectorAll('[data-view]');
    Array.prototype.forEach.call(toggles, function (b) {
      b.addEventListener('click', function () { setView(b.getAttribute('data-view')); });
    });
  }

  function load() {
    var params = new URLSearchParams(window.location.search);
    var src = params.get('src');
    if (src) {
      setBusy(true);
      fetch(src).then(function (r) { return r.json(); }).then(function (d) {
        setBusy(false); ingest(d);
      }).catch(function (err) {
        setBusy(false);
        showStageError('prodStage', 'Could not load ' + src + ': ' +
          (err && err.message ? err.message : err));
      });
      return;
    }
    var kind = params.get('kind') || params.get('case');
    var a = params.get('a');
    var b = params.get('b');
    if (kind || a || b) {
      var kindInput = document.querySelector('[data-arg="kind"]');
      if (kind && kindInput) {
        var known = Array.prototype.some.call(kindInput.options, function (option) {
          return option.value === kind;
        });
        if (!known) {
          var option = document.createElement('option');
          option.value = kind;
          option.textContent = kind.replace(/_/g, ' ');
          kindInput.appendChild(option);
        }
        kindInput.value = kind;
      }
      if (a && el('a')) el('a').value = a;
      if (b && el('b')) el('b').value = b;
      calculate();
      return;
    }
    var embedded = el('frames');
    if (embedded) {
      try { ingest(JSON.parse(embedded.textContent)); }
      catch (e) { showStageError('prodStage', 'Bad embedded JSON: ' + e.message); }
    }
  }

  document.addEventListener('DOMContentLoaded', function () {
    wire();
    setView('freshman');
    load();
  });
})();
