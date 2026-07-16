// mud-render.js — Brandom-style Meaning-Use Diagram renderer.
//
// Conventions followed (per Between Saying and Doing, ch. 1):
//   - P (practice/ability) drawn as a SHARP rectangle
//   - V (vocabulary) drawn as an ELLIPSE
//   - atomic MURs (PV-suff, VP-suff, PP-suff) drawn as solid arrows
//   - each atomic arrow carries a NUMBER (in a small circle) and a
//     TYPE TAG (e.g. "PV-1", "PP-2:elab")
//   - mechanism (for PP-suff with an elab justification) printed in
//     italic next to the arrow
//   - the RESULTANT relation (e.g. LX) is drawn as a dashed accent arrow
//     labeled "Res N: VV LX 1-2-3" with the composing atomic numbers
//
// Two rendering modes:
//   • renderLXSquare(focus)  — canonical 4-node square when the focal
//     practice participates in an LX edge. The default cross-mult view
//     uses this mode.
//   • renderSatellite(focus) — focal P in center, deployed Vs above,
//     PP-related Ps on the sides. Used when the focal practice has no
//     LX edge in the registry. Still uses numbered atomic arrows.
//
// All math is done in SVG user-space coordinates. The viewBox is
// 820×480, matching the <svg id="mud-svg"> in muds.html.

'use strict';

const SVG_NS = 'http://www.w3.org/2000/svg';

/* ─────────────────────────── pretty-printers ─────────────────────────── */

function prettyId(id) {
  return String(id).replace(/^[pv]_/, '').replace(/_/g, ' ');
}

function prettyPrinciple(p) {
  return String(p).replace(/_/g, ' ');
}

function prettyMechanism(m) {
  return String(m).replace(/_/g, ' ');
}

/* ─────────────────────────── svg primitives ─────────────────────────── */

function svgEl(name, attrs) {
  const el = document.createElementNS(SVG_NS, name);
  if (attrs) for (const k in attrs) el.setAttribute(k, attrs[k]);
  return el;
}

function clearSvg(svg) {
  Array.from(svg.children).forEach(ch => {
    if (ch.tagName.toLowerCase() !== 'defs') ch.remove();
  });
}

/* ─────────────────────────── node primitives ─────────────────────────── */

function wrapLabel(label, maxLen) {
  const text = prettyId(label);
  if (text.length <= maxLen) return [text];
  const words = text.split(' ');
  const lines = [];
  let cur = '';
  for (const w of words) {
    const probe = (cur + ' ' + w).trim();
    if (probe.length > maxLen) {
      if (cur) lines.push(cur);
      cur = w;
    } else {
      cur = probe;
    }
  }
  if (cur) lines.push(cur);
  if (lines.length <= 2) return lines;
  // collapse extras
  return [lines[0], lines.slice(1).join(' ')];
}

function addPNode(svg, x, y, id, opts) {
  opts = opts || {};
  const w = opts.w || 200;
  const h = opts.h || 64;
  const g = svgEl('g', { 'data-node': id, 'class': 'mud-node' });
  // background fill
  g.appendChild(svgEl('rect', {
    x: x - w/2, y: y - h/2, width: w, height: h, class: 'nd-p-fill'
  }));
  // border
  g.appendChild(svgEl('rect', {
    x: x - w/2, y: y - h/2, width: w, height: h,
    class: 'nd-p-stroke' + (opts.focus ? ' focus' : '') + (opts.ghost ? ' ghost' : '')
  }));
  // kind banner
  const kind = svgEl('text', {
    x: x, y: y - h/2 + 10, class: 'nd-kind p'
  });
  kind.textContent = 'PRACTICE';
  g.appendChild(kind);
  // label
  const lines = wrapLabel(id, 24);
  const yOff = lines.length === 1 ? 6 : 0;
  lines.forEach((ln, i) => {
    const t = svgEl('text', {
      x: x, y: y + yOff + i * 14,
      class: 'nd-label' + (ln.length > 18 ? ' small' : '')
    });
    t.textContent = ln;
    g.appendChild(t);
  });
  svg.appendChild(g);
  return { x, y, w, h, kind: 'P' };
}

function addVNode(svg, x, y, id, opts) {
  opts = opts || {};
  const rx = opts.rx || 95;
  const ry = opts.ry || 38;
  const g = svgEl('g', { 'data-node': id, 'class': 'mud-node' });
  g.appendChild(svgEl('ellipse', { cx: x, cy: y, rx, ry, class: 'nd-v-fill' }));
  g.appendChild(svgEl('ellipse', {
    cx: x, cy: y, rx, ry,
    class: 'nd-v-stroke' + (opts.focus ? ' focus' : '')
  }));
  const kind = svgEl('text', { x: x, y: y - ry + 12, class: 'nd-kind v' });
  kind.textContent = 'VOCABULARY';
  g.appendChild(kind);
  const lines = wrapLabel(id, 22);
  const yOff = lines.length === 1 ? 6 : 0;
  lines.forEach((ln, i) => {
    const t = svgEl('text', {
      x: x, y: y + yOff + i * 14,
      class: 'nd-label' + (ln.length > 16 ? ' small' : '')
    });
    t.textContent = ln;
    g.appendChild(t);
  });
  svg.appendChild(g);
  return { x, y, rx, ry, w: rx * 2, h: ry * 2, kind: 'V' };
}

/* ─────────────────────────── edge primitives ─────────────────────────── */

function edgePoint(node, tx, ty) {
  const dx = tx - node.x;
  const dy = ty - node.y;
  if (dx === 0 && dy === 0) return { x: node.x, y: node.y };
  if (node.kind === 'P') {
    const hx = node.w / 2, hy = node.h / 2;
    const sx = Math.abs(dx) / hx;
    const sy = Math.abs(dy) / hy;
    const t = 1 / Math.max(sx, sy);
    return { x: node.x + dx * t, y: node.y + dy * t };
  }
  const a = node.rx, b = node.ry;
  const t = 1 / Math.sqrt((dx*dx)/(a*a) + (dy*dy)/(b*b));
  return { x: node.x + dx * t, y: node.y + dy * t };
}

// Add a perpendicular offset to a straight edge so two arrows between the
// same pair of nodes (e.g. PV and VP between V_base and P_base) don't
// overlap.
function offsetEndpoints(p1, p2, offset) {
  if (!offset) return [p1, p2];
  const dx = p2.x - p1.x;
  const dy = p2.y - p1.y;
  const len = Math.hypot(dx, dy) || 1;
  const ox = -dy / len * offset;
  const oy =  dx / len * offset;
  return [{ x: p1.x + ox, y: p1.y + oy }, { x: p2.x + ox, y: p2.y + oy }];
}

// Numbered, labeled arrow.
//   spec.from, spec.to        nodes returned by addPNode/addVNode
//   spec.num                  the atomic-arrow number ("1", "2", "Res 5", ...)
//   spec.type                 the type tag ("PV-suff", "PP-suff:elab", "VP-suff", "VV: LX")
//   spec.mech                 italic mechanism string (optional)
//   spec.kind                 'atomic' | 'lx' | 'ghost'
//   spec.curve                bend amount in px (positive = right of straight line)
//   spec.offset               perpendicular offset of straight endpoints
//   spec.labelSide            -1 (above/left) or +1 (below/right); default -1
//   spec.labelDist            distance from midpoint to label, default 32
//   spec.numAlong             where along the path the number sits, 0..1; default 0.5
function addArrow(svg, spec) {
  const { from, to, num, type, mech, kind = 'atomic',
          curve = 0, offset = 0, labelSide = -1, labelDist = 32,
          numAlong = 0.5 } = spec;
  let p1 = edgePoint(from, to.x, to.y);
  let p2 = edgePoint(to, from.x, from.y);
  [p1, p2] = offsetEndpoints(p1, p2, offset);

  // path: straight line OR a quadratic bezier
  let pathD, midX, midY, tangentAngle, numX, numY;
  if (curve) {
    const mx = (p1.x + p2.x) / 2;
    const my = (p1.y + p2.y) / 2;
    const dx = p2.x - p1.x;
    const dy = p2.y - p1.y;
    const len = Math.hypot(dx, dy) || 1;
    const nx = -dy / len, ny = dx / len;
    const cx = mx + nx * curve;
    const cy = my + ny * curve;
    pathD = `M ${p1.x} ${p1.y} Q ${cx} ${cy} ${p2.x} ${p2.y}`;
    midX = (p1.x + 2*cx + p2.x) / 4;
    midY = (p1.y + 2*cy + p2.y) / 4;
    tangentAngle = Math.atan2(p2.y - cy, p2.x - cx);
    numX = midX; numY = midY;
  } else {
    pathD = `M ${p1.x} ${p1.y} L ${p2.x} ${p2.y}`;
    midX = (p1.x + p2.x) / 2;
    midY = (p1.y + p2.y) / 2;
    tangentAngle = Math.atan2(p2.y - p1.y, p2.x - p1.x);
    numX = p1.x + (p2.x - p1.x) * numAlong;
    numY = p1.y + (p2.y - p1.y) * numAlong;
  }

  // LX shadow underlay
  if (kind === 'lx') {
    svg.appendChild(svgEl('path', { d: pathD, class: 'arrow lx-shadow' }));
  }

  // main path
  const cls = kind === 'lx' ? 'arrow lx'
            : kind === 'ghost' ? 'arrow ghost'
            : 'arrow';
  const markerEnd = kind === 'lx' ? 'url(#arr-end-lx)'
                   : kind === 'ghost' ? 'url(#arr-end-ghost)'
                   : 'url(#arr-end)';
  svg.appendChild(svgEl('path', {
    d: pathD, class: cls, 'marker-end': markerEnd
  }));

  // label: TYPE on first line, MECH (italic, possibly wrapped) on next line(s)
  // offset perpendicular to the tangent
  const nx = -Math.sin(tangentAngle);
  const ny =  Math.cos(tangentAngle);
  const lx = midX + nx * labelDist * labelSide;
  const ly = midY + ny * labelDist * labelSide;

  const typeText = type || '';
  // wrap mech text into ~32-char lines
  let mechLines = [];
  if (mech) {
    const words = mech.split(' ');
    let cur = '';
    const maxChars = 30;
    for (const w of words) {
      const probe = (cur + ' ' + w).trim();
      if (probe.length > maxChars && cur) {
        mechLines.push(cur);
        cur = w;
      } else {
        cur = probe;
      }
    }
    if (cur) mechLines.push(cur);
  }
  const widestChars = Math.max(
    typeText.length,
    ...mechLines.map(l => l.length),
    0
  );
  const padW = widestChars * 5.4 + 20;
  const padH = 14 + mechLines.length * 12;
  if (typeText || mechLines.length) {
    svg.appendChild(svgEl('rect', {
      x: lx - padW/2, y: ly - padH/2, width: padW, height: padH, class: 'label-bg'
    }));
  }
  if (typeText) {
    const t = svgEl('text', {
      x: lx, y: mechLines.length ? ly - padH/2 + 8 : ly,
      class: 'arr-type' + (kind === 'lx' ? ' lx' : '')
    });
    t.textContent = typeText;
    svg.appendChild(t);
  }
  mechLines.forEach((ln, i) => {
    const baseY = typeText ? ly - padH/2 + 18 + i * 12 : ly - padH/2 + 8 + i * 12;
    const m = svgEl('text', { x: lx, y: baseY, class: 'arr-mech' });
    m.textContent = ln;
    svg.appendChild(m);
  });

  // number bubble — sits ON the line at the numAlong position
  if (num != null) {
    const r = String(num).length > 2 ? 12 : 9;
    svg.appendChild(svgEl('circle', {
      cx: numX, cy: numY, r: r,
      class: 'arr-num-bg' + (kind === 'lx' ? ' lx' : '')
    }));
    const t = svgEl('text', {
      x: numX, y: numY + 0.5,
      class: 'arr-num' + (kind === 'lx' ? ' lx' : '')
    });
    t.textContent = num;
    svg.appendChild(t);
  }
}

/* ─────────────────────── LAYOUT 1: LX SQUARE ─────────────────────── */
/*
 *   ┌─────────────────┐  PV-1                    ╭─────────────────╮
 *   │   P_meta        │ ──────────────────────▶  │   V_meta        │
 *   └────────┬────────┘                          ╰────────╳────────╯
 *            │                                        ╎
 *          PP-2:elab                            Res 5: VV LX (1-2-3-4)
 *            │  (mechanism)                          ╎ (dashed)
 *            ▼                                        ▼
 *   ┌─────────────────┐  PV-3                    ╭─────────────────╮
 *   │   P_base        │ ──────────────────────▶  │   V_base        │
 *   └─────────────────┘                          ╰─────────────────╯
 *                          ◀─── VP-4 ────────────
 */

function renderLXSquare(svg, data, focus, lxEdge) {
  clearSvg(svg);
  const W = 880, H = 480;
  svg.setAttribute('viewBox', `0 0 ${W} ${H}`);

  // lxEdge: [vMeta, vBase, principle]
  const [vMetaId, vBaseId, principle] = lxEdge;

  // Find a P_meta that deploys V_meta. Prefer the focal one if it does.
  const pMetaCandidates = data.pv_sufficient
    .filter(([p, v]) => v === vMetaId)
    .map(r => r[0]);
  let pMetaId = pMetaCandidates.includes(focus) ? focus
              : pMetaCandidates[0] || focus;

  // Find a P_base that deploys V_base AND is PP-elaborated INTO P_meta.
  // In Brandom, PP-suff:elab points from the basic practice TO the
  // elaborated one (the elaboration is what you get by composing the
  // basic practice). The data follows that convention.
  const ppToMeta = data.pp_sufficient.filter(r => r[1] === pMetaId);
  const ppNecToMeta = data.pp_necessary.filter(r => r[1] === pMetaId);
  const allPPToMeta = ppToMeta.concat(ppNecToMeta.map(r => [r[0], r[1], null]));
  const pBaseCandidates = allPPToMeta
    .map(r => r[0])
    .filter(p => data.pv_sufficient.some(([pp, v]) => pp === p && v === vBaseId));

  let pBaseId;
  let ppMech = null;
  if (pBaseCandidates.length) {
    pBaseId = pBaseCandidates[0];
    const sufRow = ppToMeta.find(r => r[0] === pBaseId);
    ppMech = sufRow ? sufRow[2] : null;
  } else {
    // Fallback: any P that deploys V_base
    const fallback = data.pv_sufficient.find(([p, v]) => v === vBaseId);
    pBaseId = fallback ? fallback[0] : null;
  }

  // Layout coordinates — a tidy square with generous margins.
  const xP = 200;        // P column x
  const xV = 660;        // V column x
  const yTop = 130;      // top row y
  const yBot = 360;      // bottom row y

  const nPmeta = addPNode(svg, xP, yTop, pMetaId, { focus: pMetaId === focus });
  const nVmeta = addVNode(svg, xV, yTop, vMetaId, {});
  const nPbase = pBaseId ? addPNode(svg, xP, yBot, pBaseId, { focus: pBaseId === focus }) : null;
  const nVbase = addVNode(svg, xV, yBot, vBaseId, {});

  // Atomic arrows.
  // 1. PV-1: P_meta → V_meta  (top horizontal)
  addArrow(svg, {
    from: nPmeta, to: nVmeta, num: '1', type: 'PV-suff',
    labelSide: -1, labelDist: 18
  });
  // 2. PP-2:elab: P_base → P_meta  (left vertical, points UP — basic
  //    practice elaborates INTO the meta practice)
  if (nPbase) {
    addArrow(svg, {
      from: nPbase, to: nPmeta, num: '2',
      type: 'PP-suff : elab',
      mech: ppMech ? prettyMechanism(ppMech) : null,
      labelSide: -1, labelDist: 110
    });
  }
  // 3. PV-3: P_base → V_base (bottom horizontal, slight up offset)
  if (nPbase) {
    addArrow(svg, {
      from: nPbase, to: nVbase, num: '3', type: 'PV-suff',
      offset: -14, labelSide: -1, labelDist: 14, numAlong: 0.3
    });
    // 4. VP-4: V_base → P_base (bottom horizontal, slight down offset)
    addArrow(svg, {
      from: nVbase, to: nPbase, num: '4', type: 'VP-suff',
      offset: -14, labelSide: 1, labelDist: 14, numAlong: 0.3
    });
  }
  // 5. Resultant LX: V_meta → V_base (right vertical, dashed accent)
  addArrow(svg, {
    from: nVmeta, to: nVbase, num: 'Res 5',
    type: 'VV : LX  (Res of 1·2·3)',
    mech: principle ? 'makes explicit: ' + prettyPrinciple(principle) : null,
    kind: 'lx',
    labelSide: 1, labelDist: 115
  });

  // Title + caption
  document.getElementById('mud-title').textContent =
    prettyId(vMetaId) + ' ⊢LX ' + prettyId(vBaseId);
  document.getElementById('mud-mode').textContent = 'LX SQUARE';
  document.getElementById('mud-caption').innerHTML = lxSquareCaption(
    pMetaId, vMetaId, pBaseId, vBaseId, principle, ppMech, data, focus
  );
}

function lxSquareCaption(pMeta, vMeta, pBase, vBase, principle, mech, data, focus) {
  const pMetaDesc = (data.practices.find(p => p.id === pMeta) || {}).description || '';
  const pBaseDesc = pBase ? (data.practices.find(p => p.id === pBase) || {}).description || '' : '';
  const principleText = principle ? prettyPrinciple(principle) : '';
  const mechText = mech ? prettyMechanism(mech) : '';

  return `<strong>Read the square as a recipe.</strong> The basic practice <code>${pBase || '—'}</code> deploys <code>${vBase}</code> (arrow 3) and is reciprocally specified by it (arrow 4). It elaborates into <code>${pMeta}</code> (arrow 2${mechText ? ', mechanism: <em>' + mechText + '</em>' : ''}), which deploys <code>${vMeta}</code> (arrow 1). Composing arrows 1–4 yields the resultant 5: <code>${vMeta}</code> is <strong style="color:var(--accent)">elaborated-explicating</strong> for <code>${vBase}</code>${principleText ? ' — it makes explicit ' + principleText : ''}.`;
}

/* ─────────────────────── LAYOUT 2: SATELLITE ─────────────────────── */
/*
 * Used when the focal practice has no LX edge in the registry.
 *   - focal P in the center
 *   - PV-sufficient vocabularies stacked above
 *   - PP-related practices flanking left/right
 */

function renderSatellite(svg, data, focus) {
  clearSvg(svg);
  const W = 880, H = 480;
  svg.setAttribute('viewBox', `0 0 ${W} ${H}`);

  const focalY = 280;
  const xFocal = 440;
  const xLeft = 145;
  const xRight = 735;

  // collect data
  const pvVocs = data.pv_sufficient.filter(r => r[0] === focus).map(r => r[1]);
  const ppElab = data.pp_sufficient.filter(r => r[0] === focus); // focus → other
  const ppBase = data.pp_sufficient.filter(r => r[1] === focus); // other → focus
  const ppNecElab = data.pp_necessary.filter(r => r[0] === focus);
  const ppNecBase = data.pp_necessary.filter(r => r[1] === focus);

  // dedupe elaborated/base lists
  const elabSet = new Map();
  ppElab.forEach(r => elabSet.set(r[1], { to: r[1], mech: r[2], necessary: false }));
  ppNecElab.forEach(r => { if (!elabSet.has(r[1])) elabSet.set(r[1], { to: r[1], mech: null, necessary: true }); });
  const baseSet = new Map();
  ppBase.forEach(r => baseSet.set(r[0], { from: r[0], mech: r[2], necessary: false }));
  ppNecBase.forEach(r => { if (!baseSet.has(r[0])) baseSet.set(r[0], { from: r[0], mech: null, necessary: true }); });
  const elabList = [...elabSet.values()].slice(0, 2);
  const baseList = [...baseSet.values()].slice(0, 2);

  // place focal P
  const nFocal = addPNode(svg, xFocal, focalY, focus, { focus: true });

  // place vocabularies (above focal)
  const nVocs = {};
  const vList = pvVocs.slice(0, 3);
  vList.forEach((v, i) => {
    let vx;
    if (vList.length === 1) vx = xFocal;
    else if (vList.length === 2) vx = xFocal + (i === 0 ? -130 : 130);
    else vx = xFocal + (i - 1) * 200;
    nVocs[v] = addVNode(svg, vx, 95, v);
  });

  // place left elab P
  const nLeft = {};
  baseList.forEach((rec, i) => {
    const y = focalY - 70 + i * 140;
    nLeft[rec.from] = addPNode(svg, xLeft, y, rec.from, { w: 180, h: 60 });
  });
  // place right base P
  const nRight = {};
  elabList.forEach((rec, i) => {
    const y = focalY - 70 + i * 140;
    nRight[rec.to] = addPNode(svg, xRight, y, rec.to, { w: 180, h: 60 });
  });

  // arrows
  let n = 1;
  // PV from focal to each vocab
  vList.forEach(v => {
    addArrow(svg, {
      from: nFocal, to: nVocs[v], num: String(n++),
      type: 'PV-suff',
      labelSide: 1, labelDist: 38, numAlong: 0.4
    });
  });
  // PP from left bases → focal
  baseList.forEach(rec => {
    addArrow(svg, {
      from: nLeft[rec.from], to: nFocal,
      num: String(n++),
      type: rec.necessary ? 'PP-nec' : 'PP-suff : elab',
      mech: rec.mech ? prettyMechanism(rec.mech) : null,
      kind: rec.necessary ? 'ghost' : 'atomic',
      labelSide: -1, labelDist: 36
    });
  });
  // PP from focal → right elab targets
  elabList.forEach(rec => {
    addArrow(svg, {
      from: nFocal, to: nRight[rec.to],
      num: String(n++),
      type: rec.necessary ? 'PP-nec' : 'PP-suff : elab',
      mech: rec.mech ? prettyMechanism(rec.mech) : null,
      kind: rec.necessary ? 'ghost' : 'atomic',
      labelSide: -1, labelDist: 36
    });
  });
  // VP edges visible? draw any V→focal VP arrows
  data.vp_sufficient.forEach(([v, p]) => {
    if (p === focus && nVocs[v]) {
      addArrow(svg, {
        from: nVocs[v], to: nFocal, num: String(n++),
        type: 'VP-suff', labelSide: -1, labelDist: 38,
        offset: 14
      });
    }
  });

  // caption
  const prac = data.practices.find(p => p.id === focus);
  const desc = prac ? prac.description : '';
  document.getElementById('mud-title').textContent = prettyId(focus) + ' neighborhood';
  document.getElementById('mud-mode').textContent = 'SATELLITE';
  const summary = [
    `<strong>${focus}</strong> — ${desc}`,
    `No LX resultant touches this practice in the current registry. The diagram shows its <em>atomic</em> MURs only: the vocabularies it PV-deploys, the practices it PP-elaborates (or is elaborated from), and any VP arrows specifying it.`
  ].join(' ');
  document.getElementById('mud-caption').innerHTML = summary;
}

/* ─────────────────────── public entry point ─────────────────────── */

function renderMud(data, focus) {
  const svg = document.getElementById('mud-svg');

  // What vocabularies does the focal practice PV-deploy?
  const focalVocs = new Set(
    data.pv_sufficient.filter(r => r[0] === focus).map(r => r[1])
  );

  // Score each lx_for edge for how well it fits the focal practice.
  // Best: focus is the P_meta — it deploys vMeta AND there is a
  //       PP-suff edge pointing INTO focus from a P_base that deploys vBase.
  //       This is the closed-square case (canonical cross-mult).
  // Good: focus deploys vMeta (so it can serve as P_meta).
  // OK:   focus deploys vBase (it's the practice being elaborated).
  // None: skip.
  function scoreLx(edge) {
    const [vm, vb] = edge;
    if (focalVocs.has(vm)) {
      // Does any P_base deploying vBase have a PP-suff edge into focus?
      const ppInto = data.pp_sufficient.some(r =>
        r[1] === focus &&
        data.pv_sufficient.some(([p, v]) => p === r[0] && v === vb)
      );
      if (ppInto) return 100;
      // Or: focus also deploys vBase (closed at the V level)
      if (focalVocs.has(vb)) return 80;
      return 50;
    }
    if (focalVocs.has(vb)) return 20;
    return 0;
  }

  let bestLx = null;
  let bestScore = 0;
  for (const edge of data.lx_for) {
    const s = scoreLx(edge);
    if (s > bestScore) { bestScore = s; bestLx = edge; }
  }

  if (bestLx) {
    renderLXSquare(svg, data, focus, bestLx);
    return;
  }
  renderSatellite(svg, data, focus);
}

window.MudRender = { renderMud, prettyId };
