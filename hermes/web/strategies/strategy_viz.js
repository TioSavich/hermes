// strategy_viz.js
// Shared client for the Hermes /api/strategy_trace endpoint (worker op
// strategy_trace -> hermes/encyclopedia.pl strategy_trace_dict/3).
// Each strategy page is a thin shell that calls runStrategy(...) below.
//
// All number-line jumps come from the Prolog FSM; this file only renders them.

(function () {
  'use strict';

  const requestClientReady = window.HermesFetch ? Promise.resolve() : new Promise(function (resolve, reject) {
    const script = document.createElement('script');
    script.src = '../render/request.js';
    script.onload = resolve;
    script.onerror = function () { reject(new Error('The local request helper did not load.')); };
    document.head.appendChild(script);
  });

  // Render a number line with jumps. jumps = [{from, to, label}, ...].
  function drawNumberLine(svgId, startVal, jumps, finalVal) {
    const svg = document.getElementById(svgId);
    if (!svg) return;
    svg.innerHTML = '';

    const w = parseFloat(svg.getAttribute('width'));
    const h = parseFloat(svg.getAttribute('height'));
    const startX = 50, endX = w - 50;
    const y = h / 2 + 30;
    const tickH = 10;
    const labelOff = 20;
    const jumpHLarge = 60, jumpHSmall = 40;
    const jumpLabelOff = 15;
    const arrow = 5;
    const breakThreshold = 40;

    // Baseline.
    appendLine(svg, startX, y, endX, y, 'number-line-tick');
    // 0 tick.
    appendLine(svg, startX, y - tickH/2, startX, y + tickH/2, 'number-line-tick');
    appendText(svg, startX, y + labelOff, '0', 'number-line-label');

    // Range.
    let minV = startVal, maxV = finalVal;
    jumps.forEach(j => {
      minV = Math.min(minV, j.from, j.to);
      maxV = Math.max(maxV, j.from, j.to);
    });

    let dispStart = 0, scaleStartX = startX, drawBreak = false;
    if (Math.min(startVal, minV) > breakThreshold) {
      dispStart = minV - 10;
      scaleStartX = startX + 30;
      drawBreak = true;
      appendBreakSymbol(svg, scaleStartX - 15, y);
    }
    const dispEnd = maxV + 10;
    const range = Math.max(dispEnd - dispStart, 1);
    const scale = (endX - scaleStartX) / range;

    function valToX(v) {
      if (v < dispStart && drawBreak) return scaleStartX - 10;
      const sx = scaleStartX + (v - dispStart) * scale;
      return Math.min(sx, endX);
    }

    function tickAndLabel(v, idx) {
      const x = valToX(v);
      if (x < scaleStartX - 5 && v !== 0) return;
      appendLine(svg, x, y - tickH/2, x, y + tickH/2, 'number-line-tick');
      const off = labelOff * (idx % 2 === 0 ? 1 : -1.5);
      appendText(svg, x, y + off, v.toString(), 'number-line-label');
    }

    tickAndLabel(startVal, 0);
    let lastTo = startVal;
    jumps.forEach((j, idx) => {
      const x1 = valToX(j.from), x2 = valToX(j.to);
      if (x1 >= endX - 1 && x2 >= endX - 1) return;
      const isLarge = Math.abs(j.to - j.from) >= 10;
      const jh = isLarge ? jumpHLarge : jumpHSmall;
      const stagger = idx % 2 === 0 ? 0 : jh * 0.5;
      drawArc(svg, x1, y, x2, jh + stagger);
      appendText(svg, (x1 + x2) / 2, y - (jh + stagger) - jumpLabelOff, j.label, 'jump-label');
      tickAndLabel(j.to, idx + 1);
      lastTo = j.to;
    });

    if (finalVal !== lastTo && valToX(finalVal) <= endX) {
      tickAndLabel(finalVal, jumps.length + 1);
    }

    // End arrow.
    const endLineX = valToX(dispEnd);
    appendPath(svg, `M ${endLineX - arrow} ${y - arrow/2} L ${endLineX} ${y} L ${endLineX - arrow} ${y + arrow/2} Z`, 'number-line-arrow');

    // Start dot.
    appendCircle(svg, valToX(startVal), y, 4, 'stopping-point');
    appendText(svg, valToX(startVal), y + labelOff * 1.5, 'Start', 'number-line-label');
  }

  function appendLine(svg, x1, y1, x2, y2, cls) {
    const e = document.createElementNS('http://www.w3.org/2000/svg', 'line');
    e.setAttribute('x1', x1); e.setAttribute('y1', y1);
    e.setAttribute('x2', x2); e.setAttribute('y2', y2);
    e.setAttribute('class', cls);
    svg.appendChild(e);
  }
  function appendText(svg, x, y, text, cls) {
    const e = document.createElementNS('http://www.w3.org/2000/svg', 'text');
    e.setAttribute('x', x); e.setAttribute('y', y);
    e.setAttribute('class', cls); e.setAttribute('text-anchor', 'middle');
    e.setAttribute('font-size', '12px');
    e.textContent = text;
    svg.appendChild(e);
  }
  function appendBreakSymbol(svg, x, y) {
    const off = 4, h = 8;
    appendLine(svg, x - off, y - h, x + off, y + h, 'number-line-break');
    appendLine(svg, x + off, y - h, x - off, y + h, 'number-line-break');
  }
  function appendPath(svg, d, cls) {
    const e = document.createElementNS('http://www.w3.org/2000/svg', 'path');
    e.setAttribute('d', d); e.setAttribute('class', cls);
    svg.appendChild(e);
  }
  function appendCircle(svg, cx, cy, r, cls) {
    const e = document.createElementNS('http://www.w3.org/2000/svg', 'circle');
    e.setAttribute('cx', cx); e.setAttribute('cy', cy); e.setAttribute('r', r);
    e.setAttribute('class', cls);
    svg.appendChild(e);
  }
  function drawArc(svg, x1, y1, x2, arcH) {
    const cx = (x1 + x2) / 2, cy = y1 - arcH;
    appendPath(svg, `M ${x1} ${y1} Q ${cx} ${cy} ${x2} ${y1}`, 'jump-arrow');
    const dx = x2 - cx, dy = y1 - cy;
    const ang = Math.atan2(dy, dx) * 180 / Math.PI;
    const head = document.createElementNS('http://www.w3.org/2000/svg', 'path');
    head.setAttribute('class', 'jump-arrow-head');
    head.setAttribute('d', `M 0 0 L 5 2.5 L 5 -2.5 Z`);
    head.setAttribute('transform', `translate(${x2}, ${y1}) rotate(${ang + 180})`);
    svg.appendChild(head);
  }

  function escapeHtml(value) {
    return String(value)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  function renderActionTopology(topology) {
    if (!topology || topology.available === false || !topology.semantic_label) return '';
    const groundings = Array.isArray(topology.grounding_metaphors) && topology.grounding_metaphors.length
      ? topology.grounding_metaphors.join(', ')
      : 'unmapped';
    const terms = Array.isArray(topology.vocabulary_terms)
      ? topology.vocabulary_terms.slice(0, 8).join(', ')
      : '';
    const deformations = Array.isArray(topology.deformations)
      ? topology.deformations.slice(0, 3)
      : [];
    const entitlement = topology.requires_entitlement ? 'entitlement required' : 'base practice';
    const deformationList = deformations.length
      ? `<ul class="deformation-list">${deformations.map(d => {
          const grounding = d.grounding_evidence || {};
          const groundingLabel = `D${grounding.direct || 0}/A${grounding.adjacent || 0}/R${grounding.rollup || 0}`;
          const notebooks = Array.isArray(grounding.evidence_notebooks) && grounding.evidence_notebooks.length
            ? grounding.evidence_notebooks
            : (Array.isArray(grounding.notebooks) ? grounding.notebooks : []);
          const notebookText = notebooks.length ? ` · ${escapeHtml(notebooks.slice(0, 2).join(', '))}` : '';
          const divergence = d.divergence_summary ? `<span class="deformation-divergence">${escapeHtml(d.divergence_summary)}</span>` : '';
          const samples = Array.isArray(grounding.evidence_samples) ? grounding.evidence_samples : [];
          const sample = samples.length ? samples[0] : null;
          const sampleText = sample
            ? `<span class="evidence-sample">${escapeHtml(sample.notebook_title)} · ${escapeHtml(sample.source_title)} · ${escapeHtml(sample.source_location)}<br>${escapeHtml(sample.support_summary)}</span>`
            : '';
          return `<li><code>${escapeHtml(d.deformation_kind)}</code> · ${escapeHtml(d.delta_type)} · ${escapeHtml(d.binding_total)} binding(s) · ${escapeHtml(groundingLabel)}${notebookText}${divergence}${sampleText}</li>`;
        }).join('')}</ul>`
      : '';
    return `<div class="action-topology">
      <p class="meta"><strong>Action topology:</strong>
        <code>${escapeHtml(topology.operation)}:${escapeHtml(topology.kind)}</code>
        · ${escapeHtml(topology.semantic_label)}
        · ${escapeHtml(entitlement)}</p>
      <p class="meta"><strong>Grounding:</strong> ${escapeHtml(groundings)}</p>
      ${terms ? `<p class="meta"><strong>Vocabulary:</strong> ${escapeHtml(terms)}</p>` : ''}
      ${deformationList}
    </div>`;
  }

  // Public entry: wire a strategy page to the Prolog API.
  // Config: { strategy, op, a1Id, a2Id, btnId, outId, svgId, stepListId }.
  window.wireStrategyPage = function (cfg) {
    const a1El = document.getElementById(cfg.a1Id);
    const a2El = document.getElementById(cfg.a2Id);
    const btn = document.getElementById(cfg.btnId);
    const outEl = document.getElementById(cfg.outId);
    const stepEl = document.getElementById(cfg.stepListId);
    const svg = document.getElementById(cfg.svgId);

    btn.addEventListener('click', async function () {
      const a = parseInt(a1El.value, 10);
      const b = parseInt(a2El.value, 10);
      if (isNaN(a) || isNaN(b)) {
        outEl.innerHTML = '<div class="error-banner">Please enter valid integers for both operands.</div>';
        return;
      }
      try { await requestClientReady; }
      catch (err) { outEl.innerHTML = `<div class="error-banner">${err.message}</div>`; return; }
      const stopElapsed = HermesFetch.startElapsed(outEl, 'Computing in Prolog...');
      stepEl.innerHTML = '';
      svg.innerHTML = '';

      let envelope;
      try {
        const response = await HermesFetch.requestJSON('/api/strategy_trace', {
          method: 'POST',
          headers: {'Content-Type': 'application/json'},
          body: JSON.stringify({strategy: cfg.strategy, input: {a: a, b: b}}),
          timeoutMs: HermesFetch.HEAVY_PROLOG_TIMEOUT_MS
        });
        envelope = HermesFetch.requireOK(response);
      } catch (err) {
        HermesFetch.setState(outEl, err.kind === 'offline' || err.kind === 'timeout' ? 'offline' : 'broken', err.message);
        return;
      } finally { stopElapsed(); }

      const data = envelope && envelope.ok ? envelope.result : null;
      if (!data || data.ok === false) {
        const why = (data && data.note) || (envelope && envelope.error) || 'unknown';
        outEl.innerHTML = `<div class="error-banner">Prolog reported failure: ${why}</div>`;
        return;
      }

      const opSym = cfg.op;
      const jumps = data.jumps || [];
      const steps = data.steps || [];
      outEl.innerHTML = `<p><strong>${a} ${opSym} ${b} = ${data.result}</strong> (via ${data.strategy})</p>` +
                       `<p class="meta">${jumps.length} jump(s), ${steps.length} step(s) total.</p>` +
                       (data.action_topology ? renderActionTopology(data.action_topology) : '');

      for (const s of steps) {
        const li = document.createElement('li');
        li.textContent = `${s.label}  —  ${s.value}`;
        stepEl.appendChild(li);
      }

      // Use the first jump's `from` as the starting point when the
      // strategy's running trajectory doesn't begin at the input A.
      // (Sliding, for instance, tracks S_running, which starts at S.)
      const finalVal = jumps.length > 0 ? jumps[jumps.length - 1].to : Number(data.result);
      const trajStart = jumps.length > 0 ? jumps[0].from : a;
      drawNumberLine(cfg.svgId, trajStart, jumps, finalVal);
    });
  };

  async function postResult(path, body) {
    await requestClientReady;
    const response = await HermesFetch.requestJSON(path, {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify(body),
      timeoutMs: HermesFetch.HEAVY_PROLOG_TIMEOUT_MS
    });
    const envelope = HermesFetch.requireOK(response);
    return envelope && envelope.ok ? envelope.result : envelope;
  }

  function outcomeMarkup(data) {
    const fields = [
      ['Result', data.result],
      ['Expected', data.expected],
      ['Validity', data.validity],
      ['Viability context', data.viability_context || data.viability]
    ].filter(function (entry) {
      return entry[1] !== undefined && entry[1] !== null && entry[1] !== '';
    });
    return fields.map(function (entry) {
      const value = typeof entry[1] === 'object' ? JSON.stringify(entry[1]) : entry[1];
      return `<div><dt>${escapeHtml(entry[0])}</dt><dd><code>${escapeHtml(value)}</code></dd></div>`;
    }).join('');
  }

  // Wire the all-kinds strategy page. It shares the established trace,
  // number-line, and action-topology renderers above; only selection and the
  // raw JSON editor are page-specific.
  window.wireStrategyMachinePage = async function (cfg) {
    const familyEl = document.getElementById(cfg.familyId);
    const kindEl = document.getElementById(cfg.kindId);
    const editorEl = document.getElementById(cfg.editorId);
    const runEl = document.getElementById(cfg.runId);
    const statusEl = document.getElementById(cfg.statusId);
    const outcomeEl = document.getElementById(cfg.outcomeId);
    const stepsEl = document.getElementById(cfg.stepsId);
    const jumpsEl = document.getElementById(cfg.jumpsId);
    const topologyEl = document.getElementById(cfg.topologyId);
    const svgEl = document.getElementById(cfg.svgId);
    let strategies = [];

    function setStatus(message, isError) {
      statusEl.textContent = message;
      statusEl.className = isError ? 'machine-status error-banner' : 'machine-status meta';
    }

    function kindsFor(family) {
      return strategies.filter(function (entry) { return entry.operation === family; });
    }

    async function loadContract() {
      const family = familyEl.value;
      const kind = kindEl.value;
      if (!family || !kind) return;
      runEl.disabled = true;
      editorEl.value = '';
      setStatus('Loading the verified input example…', false);
      try {
        const contract = await postResult('/api/input_contract', {operation: family, kind: kind});
        editorEl.value = JSON.stringify(contract.example, null, 2);
        const url = new URL(window.location.href);
        url.searchParams.set('kind', kind);
        url.searchParams.set('family', family);
        history.replaceState(null, '', url);
        runEl.disabled = false;
        setStatus(`Ready to run ${family}:${kind}.`, false);
      } catch (err) {
        setStatus(`No verified input contract is registered for ${family}:${kind}. ${err.message}`, true);
      }
    }

    function fillKinds(preferredKind) {
      const entries = kindsFor(familyEl.value);
      kindEl.innerHTML = '';
      entries.forEach(function (entry) {
        const option = document.createElement('option');
        option.value = entry.kind;
        option.textContent = entry.kind.replace(/_/g, ' ');
        kindEl.appendChild(option);
      });
      if (preferredKind && entries.some(function (entry) { return entry.kind === preferredKind; })) {
        kindEl.value = preferredKind;
      }
    }

    async function runSelected() {
      let input;
      try {
        input = JSON.parse(editorEl.value);
      } catch (err) {
        setStatus(`The operand JSON is not valid: ${err.message}`, true);
        return;
      }
      if (!input || Array.isArray(input) || typeof input !== 'object') {
        setStatus('The operand editor needs one JSON object.', true);
        return;
      }

      setStatus('Running the selected automaton…', false);
      runEl.disabled = true;
      stepsEl.innerHTML = '';
      outcomeEl.innerHTML = '';
      jumpsEl.innerHTML = '';
      topologyEl.innerHTML = '';
      svgEl.innerHTML = '';
      svgEl.hidden = true;
      try {
        const data = await postResult('/api/strategy_trace', {
          strategy: kindEl.value,
          input: input
        });
        if (!data || data.ok === false) {
          throw new Error((data && data.note) || 'The automaton did not return a trace.');
        }

        outcomeEl.innerHTML = `<dl class="outcome-fields">${outcomeMarkup(data)}</dl>`;
        (data.steps || []).forEach(function (step) {
          const li = document.createElement('li');
          li.textContent = step.value ? `${step.label} — ${step.value}` : step.label;
          stepsEl.appendChild(li);
        });
        if (!stepsEl.children.length) {
          const li = document.createElement('li');
          li.textContent = 'This response carries no named execution steps.';
          stepsEl.appendChild(li);
        }

        const jumps = Array.isArray(data.jumps) ? data.jumps : [];
        if (jumps.length) {
          const first = jumps[0];
          const last = jumps[jumps.length - 1];
          svgEl.hidden = false;
          drawNumberLine(cfg.svgId, first.from, jumps, last.to);
          jumpsEl.innerHTML = `<p class="meta">${jumps.length} numeric jump(s) were extracted from the execution history.</p>`;
        } else {
          jumpsEl.innerHTML = '<p class="empty-state">No numeric jumps are present. This is expected when the state history does not carry a running numeric path.</p>';
        }

        if (data.action_topology) {
          topologyEl.innerHTML = renderActionTopology(data.action_topology);
        } else {
          topologyEl.innerHTML = '<p class="empty-state">No action-topology block is present. The trace seam does not attach that block to every registry kind.</p>';
        }
        setStatus(`Completed ${familyEl.value}:${kindEl.value}.`, false);
      } catch (err) {
        setStatus(err.message, true);
      } finally {
        runEl.disabled = false;
      }
    }

    familyEl.addEventListener('change', function () {
      fillKinds('');
      loadContract();
    });
    kindEl.addEventListener('change', loadContract);
    runEl.addEventListener('click', runSelected);

    try {
      setStatus('Loading the strategy catalog…', false);
      const catalog = await postResult('/api/strategies', {});
      strategies = Array.isArray(catalog.strategies) ? catalog.strategies : [];
      const families = Array.from(new Set(strategies.map(function (entry) { return entry.operation; }))).sort();
      families.forEach(function (family) {
        const option = document.createElement('option');
        option.value = family;
        option.textContent = family.replace(/_/g, ' ');
        familyEl.appendChild(option);
      });
      const params = new URLSearchParams(window.location.search);
      const requestedKind = params.get('kind') || '';
      const requestedEntry = strategies.find(function (entry) { return entry.kind === requestedKind; });
      const requestedFamily = params.get('family') || (requestedEntry && requestedEntry.operation) || '';
      if (requestedFamily && families.indexOf(requestedFamily) !== -1) familyEl.value = requestedFamily;
      fillKinds(requestedKind);
      await loadContract();
    } catch (err) {
      setStatus(err.message, true);
      familyEl.disabled = true;
      kindEl.disabled = true;
      runEl.disabled = true;
    }
  };

  window.HermesStrategyViz = {
    drawNumberLine: drawNumberLine,
    renderActionTopology: renderActionTopology
  };
})();
