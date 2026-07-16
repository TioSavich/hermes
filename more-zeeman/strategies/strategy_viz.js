// strategy_viz.js
// Shared client for the Hermes /api/strategy_trace endpoint (worker op
// strategy_trace -> hermes/encyclopedia.pl strategy_trace_dict/3).
// Each strategy page is a thin shell that calls runStrategy(...) below.
//
// All number-line jumps come from the Prolog FSM; this file only renders them.

(function () {
  'use strict';

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
      outEl.textContent = 'Computing in Prolog...';
      stepEl.innerHTML = '';
      svg.innerHTML = '';

      let response, envelope;
      try {
        response = await fetch('/api/strategy_trace', {
          method: 'POST',
          headers: {'Content-Type': 'application/json'},
          body: JSON.stringify({strategy: cfg.strategy, input: {a: a, b: b}})
        });
        envelope = await response.json();
      } catch (err) {
        outEl.innerHTML = `<div class="error-banner">Network error: ${err.message}</div>`;
        return;
      }

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
})();
