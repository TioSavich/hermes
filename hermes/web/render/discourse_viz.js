/* Discourse rendering primitives for the discussions page.
   Hand-rolled SVG only; no libraries. Everything here draws what a report
   already carries — nothing is computed, inferred, or re-adjudicated.
   Exposed as window.HermesDiscourseViz:
     postureStrip(report)     -> Node|null  utterance × speaker strip of postures and PML operators
     tensionRepairMap(report) -> Node|null  speaker arc map of tensions (above) and repairs (below)
     structuralView(value)    -> Node       generic labeled rendering of a JSON payload
     renderPayload(el, data)  -> void       teacher summary + shape-specific view
     heatmap(spec)            -> Node|null  shaded count table (columns x labeled rows)
   New chart kinds should reuse svgEl/withTitle from here rather than
   re-rolling helpers. */
(function () {
  "use strict";

  const SVG_NS = "http://www.w3.org/2000/svg";

  /* The renderer carries its own styles so every consuming page draws the
     same way from one source. Injected once, before any page rule, so a
     page can still override locally. */
  (function injectStyles() {
    if (document.getElementById("discourse-viz-styles")) return;
    const style = document.createElement("style");
    style.id = "discourse-viz-styles";
    style.textContent = [
      ".viz-figure { margin: 6px 0 2px; }",
      ".viz-scroll { overflow-x: auto; }",
      ".viz-legend { display: flex; flex-wrap: wrap; gap: .35rem .9rem; margin: 4px 0 0; }",
      ".viz-chip { display: inline-flex; align-items: center; gap: .3rem; font: .72rem var(--mono, monospace); color: var(--muted, #665f4f); }",
      ".viz-chip svg { flex: 0 0 auto; }",
      ".viz-chip-note { font-style: italic; }",
      ".viz-tension { color: var(--rust, #b95238); }",
      ".viz-repair { color: var(--teal-deep, #2c5e66); }",
      ".viz-note { font-size: .78rem; color: var(--muted, #665f4f); border-left: 3px solid var(--line, rgba(13,12,8,.2)); padding-left: 10px; margin: 6px 0 0; }",
      ".viz-summary { max-width: 76ch; padding: .7rem .8rem; border: 1px solid var(--line, rgba(13,12,8,.15)); border-radius: 8px; background: var(--paper-cool, #ede4cf); }",
      ".viz-summary h3, .viz-section-title { margin: 0 0 .35rem; font-size: .88rem; }",
      ".viz-summary p { margin: .2rem 0; line-height: 1.45; }",
      ".viz-summary ul { margin: .3rem 0 0; padding-left: 1.2rem; }",
      ".viz-summary li { margin: .18rem 0; }",
      ".viz-section-title { margin-top: .8rem; }",
      ".payload-view { margin-top: 10px; font-size: .84rem; overflow-x: auto; }",
      "table.struct { width: auto; max-width: none; border-collapse: collapse; font-size: .8rem; margin: 4px 0; }",
      "table.struct th { font: .74rem var(--mono, monospace); color: var(--muted, #665f4f); font-weight: 500; text-align: left; vertical-align: top; padding: 3px 10px 3px 0; min-width: 12ch; }",
      "table.struct td { padding: 3px 10px 3px 0; min-width: 14ch; vertical-align: top; }",
      "table.struct th, table.struct td { border-bottom: 1px solid var(--line, rgba(13,12,8,.1)); }",
      "table.struct table.struct { margin: 0; }",
      ".struct-scalar { overflow-wrap: anywhere; }",
      ".struct-empty { color: var(--muted, #7a7466); font-style: italic; }",
      "ul.struct-list { margin: 2px 0; padding-left: 18px; font-size: .8rem; }",
      "pre.struct-deep { background: var(--paper-cool, #ede4cf); padding: 8px; border-radius: 6px; font-size: .74rem; overflow-x: auto; }",
      "details.raw-toggle { margin-top: 8px; font-size: .82rem; }",
      "details.raw-toggle summary { cursor: pointer; color: var(--muted, #665f4f); font: .78rem var(--mono, monospace); }",
      "details.raw-toggle pre { background: var(--paper-cool, #ede4cf); padding: 10px; overflow-x: auto; max-height: 300px; border-radius: 6px; font-size: .76rem; }"
    ].join("\n");
    document.head.appendChild(style);
  })();

  function svgEl(tag, attrs, styles) {
    const el = document.createElementNS(SVG_NS, tag);
    for (const k in (attrs || {})) el.setAttribute(k, attrs[k]);
    for (const k in (styles || {})) el.style[k] = styles[k];
    return el;
  }

  function htmlEl(tag, className, text) {
    const el = document.createElement(tag);
    if (className) el.className = className;
    if (text != null) el.textContent = text;
    return el;
  }

  function withTitle(node, text) {
    if (!text) return node;
    const t = svgEl("title");
    t.textContent = text;
    node.appendChild(t);
    return node;
  }

  /* ---------- shared report indexing ---------- */

  function utteranceNumber(id) {
    const m = /^u0*(\d+)$/.exec(String(id || ""));
    return m ? Number(m[1]) : null;
  }

  /* The strip and the map draw only what the record anchors: utterances
     referenced by a claim, a posture, or a reading. Unanchored talk is
     absent by construction, and the honesty note beside each drawing
     says so. */
  function indexReport(r) {
    const claims = r.claims || [];
    const postures = r.postures || [];
    const readings = (r.machine && r.machine.readings) || [];
    const extractions = (r.machine && r.machine.extractions) || [];

    const speakerOf = new Map(); // utterance id -> speaker
    (r.utterances || []).forEach(u => {
      if (u && u.id && u.speaker) speakerOf.set(u.id, u.speaker);
    });
    claims.forEach(c => { if (c.utterance && c.speaker) speakerOf.set(c.utterance, c.speaker); });
    postures.forEach(p => (p.utterances || []).forEach(u => {
      if (!speakerOf.has(u) && p.speaker) speakerOf.set(u, p.speaker);
    }));

    const claimUtterance = new Map(); // claim id (c1) -> utterance id
    extractions.forEach(x => { if (x.id && x.utterance_id) claimUtterance.set(x.id, x.utterance_id); });

    const referenced = new Set();
    claims.forEach(c => c.utterance && referenced.add(c.utterance));
    postures.forEach(p => (p.utterances || []).forEach(u => referenced.add(u)));
    readings.forEach(rd => (rd.utterance_ids || []).forEach(u => referenced.add(u)));

    const utterances = Array.from(referenced)
      .filter(u => utteranceNumber(u) != null)
      .sort((a, b) => utteranceNumber(a) - utteranceNumber(b));

    const speakers = [];
    utterances.forEach(u => {
      const s = speakerOf.get(u);
      if (s && !speakers.includes(s)) speakers.push(s);
    });
    postures.forEach(p => { if (p.speaker && !speakers.includes(p.speaker)) speakers.push(p.speaker); });

    return { claims, postures, readings, speakerOf, claimUtterance, utterances, speakers };
  }

  /* ---------- posture strip ---------- */

  const POLARITY_COLOR = {
    compressive: "var(--gold-deep, #7a5a12)",
    expansive: "var(--teal-deep, #2c5e66)"
  };
  const MODE_SHAPE = { subjective: "circle", objective: "square", normative: "diamond" };

  function operatorGlyph(cx, cy, pml, titleText) {
    const polarity = pml.polarity || (String(pml.operator || "").startsWith("comp") ? "compressive" : "expansive");
    const color = POLARITY_COLOR[polarity] || "var(--muted, #665f4f)";
    const open = /_poss$/.test(String(pml.operator || ""));
    const shape = MODE_SHAPE[pml.mode] || "circle";
    const r = 5;
    let node;
    if (shape === "circle") {
      node = svgEl("circle", { cx, cy, r });
    } else if (shape === "square") {
      node = svgEl("rect", { x: cx - r, y: cy - r, width: 2 * r, height: 2 * r });
    } else {
      node = svgEl("path", { d: `M ${cx} ${cy - r - 1} L ${cx + r + 1} ${cy} L ${cx} ${cy + r + 1} L ${cx - r - 1} ${cy} Z` });
    }
    node.style.stroke = color;
    node.style.strokeWidth = "1.6";
    node.style.fill = open ? "none" : color;
    return withTitle(node, titleText);
  }

  function postureStrip(r) {
    const ix = indexReport(r);
    if (!ix.utterances.length || (!ix.readings.length && !ix.postures.length)) return null;

    const COL = 24, LANE = 34, LEFT = 64, TOP = 8, AXIS = 44;
    const laneOf = new Map();
    ix.speakers.forEach((s, i) => laneOf.set(s, i));
    const UNATTRIBUTED = ix.speakers.length; // lane for readings whose utterance names no speaker
    let usesUnattributed = false;
    const colOf = new Map();
    ix.utterances.forEach((u, i) => colOf.set(u, i));

    const laneY = i => TOP + i * LANE + LANE / 2;
    const colX = i => LEFT + i * COL + COL / 2;

    const frag = htmlEl("figure", "viz-figure");
    const svg = svgEl("svg", { role: "img", "aria-label": "postures and PML operators by utterance and speaker" });

    // lane guides and speaker labels
    const laneCount = ix.speakers.length + 1; // reserve; trimmed below if unused
    for (let i = 0; i < laneCount; i++) {
      svg.appendChild(svgEl("line", {
        x1: LEFT - 6, y1: laneY(i), x2: colX(ix.utterances.length - 1) + COL / 2, y2: laneY(i)
      }, { stroke: "var(--line, rgba(13,12,8,.14))", strokeWidth: "1" }));
    }
    ix.speakers.forEach((s, i) => {
      const t = svgEl("text", { x: LEFT - 10, y: laneY(i) + 3, "text-anchor": "end" },
        { font: "10px var(--mono, monospace)", fill: "var(--ink, #0d0c08)" });
      t.textContent = s;
      svg.appendChild(t);
    });

    // posture spans: an underline in the speaker's lane across the posture's utterances
    ix.postures.forEach(p => {
      const cols = (p.utterances || []).map(u => colOf.get(u)).filter(c => c != null);
      if (!cols.length || !laneOf.has(p.speaker)) return;
      const y = laneY(laneOf.get(p.speaker)) + 10;
      const x1 = colX(Math.min.apply(null, cols)) - 7;
      const x2 = colX(Math.max.apply(null, cols)) + 7;
      const line = svgEl("line", { x1, y1: y, x2, y2: y },
        { stroke: "var(--acc-norms, #2f5f9e)", strokeWidth: "3", strokeLinecap: "round", opacity: ".75" });
      const said = [p.move, p.register ? "(" + p.register + ")" : "", p.response ? "; " + p.response : ""].join(" ").trim();
      svg.appendChild(withTitle(line, said));
    });

    // reading glyphs, one per reading at its first anchored utterance
    ix.readings.forEach(rd => {
      const pml = rd.pml || {};
      const ids = (rd.utterance_ids || []).filter(u => colOf.has(u));
      if (!ids.length || !pml.operator) return;
      const first = ids[0];
      let lane = laneOf.has(ix.speakerOf.get(first)) ? laneOf.get(ix.speakerOf.get(first)) : UNATTRIBUTED;
      if (lane === UNATTRIBUTED) usesUnattributed = true;
      const cy = laneY(lane);
      if (ids.length > 1) {
        svg.appendChild(svgEl("line", {
          x1: colX(colOf.get(first)), y1: cy, x2: colX(colOf.get(ids[ids.length - 1])), y2: cy
        }, { stroke: "var(--muted, #665f4f)", strokeWidth: "1", strokeDasharray: "2 3" }));
      }
      const title = [pml.operator, pml.mode, pml.force].filter(Boolean).join(" · ")
        + (rd.raw_text ? " — “" + rd.raw_text + "”" : "");
      svg.appendChild(operatorGlyph(colX(colOf.get(first)), cy, pml, title));
    });

    const lanesUsed = ix.speakers.length + (usesUnattributed ? 1 : 0);
    if (usesUnattributed) {
      const t = svgEl("text", { x: LEFT - 10, y: laneY(UNATTRIBUTED) + 3, "text-anchor": "end" },
        { font: "10px var(--mono, monospace)", fill: "var(--muted, #665f4f)" });
      t.textContent = "unattributed";
      svg.appendChild(t);
    } else {
      // drop the reserved guide line for the unused lane
      svg.removeChild(svg.childNodes[ix.speakers.length]);
    }

    // utterance axis
    ix.utterances.forEach((u, i) => {
      const t = svgEl("text", {
        x: colX(i), y: TOP + lanesUsed * LANE + 12,
        transform: `rotate(60 ${colX(i)} ${TOP + lanesUsed * LANE + 12})`
      }, { font: "9px var(--mono, monospace)", fill: "var(--muted, #665f4f)" });
      t.textContent = u;
      svg.appendChild(t);
    });

    const width = LEFT + ix.utterances.length * COL + 20;
    const height = TOP + lanesUsed * LANE + AXIS;
    svg.setAttribute("viewBox", `0 0 ${width} ${height}`);
    svg.setAttribute("width", width);
    svg.setAttribute("height", height);

    const scroller = htmlEl("div", "viz-scroll");
    scroller.appendChild(svg);
    frag.appendChild(scroller);
    frag.appendChild(stripLegend(ix.readings));
    return frag;
  }

  function stripLegend(readings) {
    const legend = htmlEl("div", "viz-legend");
    const ops = [];
    const modes = [];
    readings.forEach(rd => {
      const pml = rd.pml || {};
      if (pml.operator && !ops.includes(pml.operator)) ops.push(pml.operator);
      if (pml.mode && !modes.includes(pml.mode)) modes.push(pml.mode);
    });
    ops.sort(); modes.sort();
    ops.forEach(op => {
      const chip = htmlEl("span", "viz-chip");
      const s = svgEl("svg", { viewBox: "0 0 14 14", width: 14, height: 14 });
      s.appendChild(operatorGlyph(7, 7, {
        operator: op,
        polarity: op.startsWith("comp") ? "compressive" : "expansive",
        mode: "objective"
      }, ""));
      chip.appendChild(s);
      chip.appendChild(document.createTextNode(" " + op));
      legend.appendChild(chip);
    });
    modes.forEach(mode => {
      const chip = htmlEl("span", "viz-chip");
      const s = svgEl("svg", { viewBox: "0 0 14 14", width: 14, height: 14 });
      const g = operatorGlyph(7, 7, { operator: "x_nec", polarity: "compressive", mode }, "");
      g.style.stroke = "var(--muted, #665f4f)";
      g.style.fill = "var(--muted, #665f4f)";
      s.appendChild(g);
      chip.appendChild(s);
      chip.appendChild(document.createTextNode(" " + mode));
      legend.appendChild(chip);
    });
    legend.appendChild(htmlEl("span", "viz-chip viz-chip-note",
      "filled = _nec, open = _poss; underline = a posture span"));
    return legend;
  }

  /* ---------- tension / repair arc map ---------- */

  function anchorsToSpeakers(anchors, ix) {
    const found = [];
    let unresolved = 0;
    (anchors || []).forEach(a => {
      const u = /^c\d+$/.test(String(a)) ? ix.claimUtterance.get(a) : a;
      const s = ix.speakerOf.get(u);
      if (s) { if (!found.includes(s)) found.push(s); }
      else unresolved += 1;
    });
    return { speakers: found, unresolved };
  }

  function tensionRepairMap(r) {
    const ix = indexReport(r);
    const tensions = r.tensions || [];
    const repairs = r.repair_arcs || [];
    if (!tensions.length && !repairs.length) return null;

    // collect edges keyed by unordered speaker pair; self-arcs kept separately
    const edges = new Map(); // key -> {a, b, kind, sentences: []}
    const selfs = new Map(); // speaker -> {kind -> sentences}
    let unresolvedTotal = 0;
    function addEdges(rows, kind) {
      rows.forEach(row => {
        const res = anchorsToSpeakers(row.anchors, ix);
        unresolvedTotal += res.unresolved;
        const list = res.speakers;
        if (list.length === 1) {
          if (!selfs.has(list[0])) selfs.set(list[0], []);
          selfs.get(list[0]).push({ kind, sentence: row.sentence || "" });
          return;
        }
        for (let i = 0; i < list.length; i++) for (let j = i + 1; j < list.length; j++) {
          const key = kind + "|" + [list[i], list[j]].sort().join("|");
          if (!edges.has(key)) edges.set(key, { a: list[i], b: list[j], kind, sentences: [] });
          if (row.sentence) edges.get(key).sentences.push(row.sentence);
        }
      });
    }
    addEdges(tensions, "tension");
    addEdges(repairs, "repair");
    if (!edges.size && !selfs.size) return null;

    const speakers = ix.speakers.slice();
    edges.forEach(e => { [e.a, e.b].forEach(s => { if (!speakers.includes(s)) speakers.push(s); }); });
    const GAP = 92, LEFT = 40, MID = 110, ARC = 66;
    const xOf = new Map();
    speakers.forEach((s, i) => xOf.set(s, LEFT + i * GAP));

    const svg = svgEl("svg", { role: "img", "aria-label": "tensions and repairs between speakers" });

    edges.forEach(e => {
      const x1 = xOf.get(e.a), x2 = xOf.get(e.b);
      const above = e.kind === "tension";
      const apex = above ? MID - ARC * Math.min(1, Math.abs(x2 - x1) / (3 * GAP)) - 14
                         : MID + ARC * Math.min(1, Math.abs(x2 - x1) / (3 * GAP)) + 14;
      const color = above ? "var(--rust, #b95238)" : "var(--teal-deep, #2c5e66)";
      const path = svgEl("path", {
        d: `M ${x1} ${MID} Q ${(x1 + x2) / 2} ${apex} ${x2} ${MID}`
      }, { fill: "none", stroke: color, strokeWidth: String(1 + e.sentences.length), opacity: ".8" });
      svg.appendChild(withTitle(path, e.sentences.join("\n") || e.kind));
      if (e.sentences.length > 1) {
        const t = svgEl("text", { x: (x1 + x2) / 2, y: apex + (above ? -3 : 11), "text-anchor": "middle" },
          { font: "10px var(--mono, monospace)", fill: color });
        t.textContent = "×" + e.sentences.length;
        svg.appendChild(t);
      }
    });

    selfs.forEach((rows, s) => {
      const x = xOf.get(s);
      if (x == null) return;
      rows.forEach((row, k) => {
        const below = row.kind === "repair";
        const cy = below ? MID + 18 + k * 6 : MID - 18 - k * 6;
        const ring = svgEl("circle", { cx: x, cy, r: 7 }, {
          fill: "none", strokeWidth: "1.6",
          stroke: below ? "var(--teal-deep, #2c5e66)" : "var(--rust, #b95238)"
        });
        svg.appendChild(withTitle(ring, row.sentence || row.kind));
      });
    });

    speakers.forEach(s => {
      const x = xOf.get(s);
      svg.appendChild(svgEl("circle", { cx: x, cy: MID, r: 4 }, { fill: "var(--ink, #0d0c08)" }));
      const t = svgEl("text", { x, y: MID + 26, "text-anchor": "middle" },
        { font: "10px var(--mono, monospace)", fill: "var(--ink, #0d0c08)" });
      t.textContent = s;
      svg.appendChild(t);
    });

    const width = LEFT + speakers.length * GAP;
    svg.setAttribute("viewBox", `0 0 ${width} ${2 * MID}`);
    svg.setAttribute("width", width);
    svg.setAttribute("height", 2 * MID);

    const frag = htmlEl("figure", "viz-figure");
    const scroller = htmlEl("div", "viz-scroll");
    scroller.appendChild(svg);
    frag.appendChild(scroller);
    const legend = htmlEl("div", "viz-legend");
    legend.appendChild(htmlEl("span", "viz-chip viz-tension", "tension (arcs above)"));
    legend.appendChild(htmlEl("span", "viz-chip viz-repair", "repair (arcs below)"));
    if (unresolvedTotal) {
      legend.appendChild(htmlEl("span", "viz-chip viz-chip-note",
        unresolvedTotal + " anchor(s) name no recorded speaker and are not drawn"));
    }
    frag.appendChild(legend);
    return frag;
  }

  /* ---------- measured-count heatmap ---------- */

  /* Draws a count table as shaded cells with the count printed in each.
     The shading orders what the numbers already say; nothing is computed
     beyond the row maximum used for the shade. spec:
       { columns: ["comp_nec", ...], rows: [{label, counts:[...]}],
         ariaLabel } */
  function heatmap(spec) {
    const columns = spec.columns || [];
    const rows = spec.rows || [];
    if (!columns.length || !rows.length) return null;

    const ROW_H = 26;
    const HEAD_H = 22;
    const labelChars = Math.max.apply(null, rows.map(r => (r.label || "").length));
    const LEFT = Math.min(340, 16 + labelChars * 7.2);
    const CELL_W = Math.max(64, 14 + Math.max.apply(
      null, columns.map(c => String(c).length)) * 7.2);
    const width = LEFT + columns.length * CELL_W + 8;
    const height = HEAD_H + rows.length * ROW_H + 6;

    let max = 0;
    rows.forEach(r => (r.counts || []).forEach(c => {
      if (typeof c === "number" && c > max) max = c;
    }));

    const svg = svgEl("svg", {
      role: "img",
      "aria-label": spec.ariaLabel || "measured counts",
      viewBox: "0 0 " + width + " " + height,
      width: width, height: height
    });

    columns.forEach((c, j) => {
      const t = svgEl("text", {
        x: LEFT + j * CELL_W + CELL_W / 2, y: HEAD_H - 8,
        "text-anchor": "middle"
      }, { font: ".7rem var(--mono, monospace)", fill: "var(--muted, #665f4f)" });
      t.textContent = c;
      svg.appendChild(t);
    });

    rows.forEach((r, i) => {
      const y = HEAD_H + i * ROW_H;
      const lab = svgEl("text", {
        x: LEFT - 8, y: y + ROW_H / 2 + 3, "text-anchor": "end"
      }, { font: ".72rem var(--mono, monospace)", fill: "var(--ink, #0d0c08)" });
      lab.textContent = r.label;
      svg.appendChild(lab);
      (r.counts || []).forEach((c, j) => {
        const x = LEFT + j * CELL_W;
        const cell = svgEl("rect", {
          x: x + 1, y: y + 1, width: CELL_W - 2, height: ROW_H - 2, rx: 3
        }, {
          fill: "var(--teal-deep, #2c5e66)",
          fillOpacity: typeof c === "number" && c > 0 && max
            ? (0.1 + 0.5 * (c / max)).toFixed(3) : "0",
          stroke: "var(--line, rgba(13,12,8,.15))",
          strokeWidth: "1"
        });
        withTitle(cell, r.label + " / " + columns[j] + ": " +
          (typeof c === "number" ? c : "not counted"));
        svg.appendChild(cell);
        const t = svgEl("text", {
          x: x + CELL_W / 2, y: y + ROW_H / 2 + 3, "text-anchor": "middle"
        }, {
          font: ".74rem var(--mono, monospace)",
          fill: typeof c === "number" && c > 0
            ? "var(--ink, #0d0c08)" : "var(--muted, #9a927f)"
        });
        t.textContent = typeof c === "number" ? String(c) : "—";
        svg.appendChild(t);
      });
    });

    const scroller = htmlEl("div", "viz-scroll");
    scroller.appendChild(svg);
    const fig = htmlEl("figure", "viz-figure");
    fig.appendChild(scroller);
    return fig;
  }

  /* ---------- generic structural payload rendering ---------- */

  function isPlainObject(v) {
    return v != null && typeof v === "object" && !Array.isArray(v);
  }

  function objectArrayColumns(arr) {
    if (arr.length < 2 || !arr.every(isPlainObject)) return null;
    const cols = [];
    arr.forEach(o => Object.keys(o).forEach(k => { if (!cols.includes(k)) cols.push(k); }));
    return cols.length && cols.length <= 8 ? cols : null;
  }

  function structuralView(value, depth) {
    depth = depth || 0;
    if (depth > 4) {
      const pre = htmlEl("pre", "struct-deep");
      pre.textContent = JSON.stringify(value, null, 1);
      return pre;
    }
    if (value == null || typeof value !== "object") {
      return htmlEl("span", "struct-scalar", value == null ? "null" : String(value));
    }
    if (Array.isArray(value)) {
      if (!value.length) return htmlEl("span", "struct-scalar struct-empty", "empty list");
      const cols = objectArrayColumns(value);
      if (cols) {
        const table = htmlEl("table", "struct");
        const head = table.insertRow();
        cols.forEach(c => head.appendChild(htmlEl("th", null, c)));
        value.forEach(o => {
          const row = table.insertRow();
          cols.forEach(c => {
            const td = row.insertCell();
            if (c in o) td.appendChild(structuralView(o[c], depth + 1));
          });
        });
        return table;
      }
      const ul = htmlEl("ul", "struct-list");
      value.forEach(v => {
        const li = htmlEl("li");
        li.appendChild(structuralView(v, depth + 1));
        ul.appendChild(li);
      });
      return ul;
    }
    const keys = Object.keys(value);
    if (!keys.length) return htmlEl("span", "struct-scalar struct-empty", "empty record");
    const table = htmlEl("table", "struct");
    keys.forEach(k => {
      const row = table.insertRow();
      row.appendChild(htmlEl("th", null, k));
      const td = row.insertCell();
      td.appendChild(structuralView(value[k], depth + 1));
    });
    return table;
  }

  function recordShape(data) {
    if (!isPlainObject(data)) return "unknown";
    const utterances = Array.isArray(data.utterances) ? data.utterances : [];
    if (utterances.some(u => isPlainObject(u) && Array.isArray(u.features))) {
      return "surface_features";
    }
    if (utterances.some(u => isPlainObject(u) && Array.isArray(u.atoms))) {
      return "pragmatic_candidates";
    }
    if (["claims", "postures", "tensions", "repair_arcs"].some(k => Array.isArray(data[k]))) {
      return "discussion_report";
    }
    return "unknown";
  }

  function words(value) {
    return String(value || "recorded item").replace(/_/g, " ");
  }

  function countedKinds(rows, childKey) {
    const counts = new Map();
    (rows || []).forEach(row => (row[childKey] || []).forEach(item => {
      const key = words(item.kind || item.subtype);
      const amount = Number.isFinite(Number(item.count)) ? Number(item.count) : 1;
      counts.set(key, (counts.get(key) || 0) + amount);
    }));
    return Array.from(counts.entries()).sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0]));
  }

  function countSentence(rows, emptyText) {
    if (!rows.length) return emptyText;
    return rows.map(([name, count]) => `${count} ${name}`).join(", ") + ".";
  }

  function addSummaryLine(host, text) {
    host.appendChild(htmlEl("p", null, text));
  }

  function addSummaryList(host, rows) {
    if (!rows.length) return;
    const list = htmlEl("ul");
    rows.slice(0, 8).forEach(text => list.appendChild(htmlEl("li", null, text)));
    if (rows.length > 8) list.appendChild(htmlEl("li", null, `${rows.length - 8} more in the full record.`));
    host.appendChild(list);
  }

  function anchorsOverlap(left, right) {
    const rightSet = new Set(right || []);
    return (left || []).some(anchor => rightSet.has(anchor));
  }

  function discussionSummary(data) {
    const host = htmlEl("section", "viz-summary");
    host.appendChild(htmlEl("h3", null, "What the record says"));
    const claims = Array.isArray(data.claims) ? data.claims : [];
    const postures = Array.isArray(data.postures) ? data.postures : [];
    const tensions = Array.isArray(data.tensions) ? data.tensions : [];
    const repairs = Array.isArray(data.repair_arcs) ? data.repair_arcs : [];

    const postureClause = `${postures.length} posture${postures.length === 1 ? "" : "s"} ${postures.length === 1 ? "appears" : "appear"}.`;
    addSummaryLine(host, claims.length
      ? `${claims.length} mathematical claim${claims.length === 1 ? "" : "s"} appear; ${postureClause}`
      : `No mathematical claim appears; ${postureClause}`);
    addSummaryList(host, claims.map(claim =>
      `${claim.speaker || "Speaker unrecorded"}: “${claim.said || "claim wording absent"}”; ${claim.finding || "finding not recorded"}.`));
    addSummaryList(host, postures.map(posture =>
      `${posture.speaker || "Speaker unrecorded"} ${posture.move || "has a recorded posture"}${posture.response ? "; " + posture.response : ""}.`));

    if (!tensions.length) {
      addSummaryLine(host, "No tension is recorded.");
    } else {
      const tensionLines = tensions.map(tension => {
        const repaired = repairs.some(repair => anchorsOverlap(tension.anchors, repair.anchors));
        return `${repaired ? "Repaired tension" : "Open tension"}: ${tension.sentence || "wording absent"}`;
      });
      addSummaryList(host, tensionLines);
    }
    const unmatchedRepairs = repairs.filter(repair =>
      !tensions.some(tension => anchorsOverlap(tension.anchors, repair.anchors)));
    addSummaryList(host, unmatchedRepairs.map(repair =>
      `Repair recorded without a matching tension row: ${repair.sentence || "wording absent"}`));
    return host;
  }

  function featureSummary(data, childKey) {
    const isPragmatic = childKey === "atoms";
    const host = htmlEl("section", "viz-summary");
    host.appendChild(htmlEl("h3", null, "What the record says"));
    const utterances = Array.isArray(data.utterances) ? data.utterances : [];
    const kinds = countedKinds(utterances, childKey);
    addSummaryLine(host, `${utterances.length} utterance${utterances.length === 1 ? "" : "s"} were checked.`);
    addSummaryLine(host, countSentence(kinds,
      isPragmatic ? "No pragmatic candidate form was found." : "No listed surface feature was found."));
    const relations = Array.isArray(data.relations) ? data.relations : [];
    const relationCounts = new Map();
    relations.forEach(row => {
      const key = words(row.kind);
      relationCounts.set(key, (relationCounts.get(key) || 0) + 1);
    });
    addSummaryLine(host, countSentence(
      Array.from(relationCounts.entries()).sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0])),
      isPragmatic ? "No pragmatic relation candidate was found." : "No surface relation candidate was found."
    ));
    addSummaryLine(host, isPragmatic
      ? "These are candidates; this record assigns no commitment, uptake, settlement, posture, or tension."
      : "These are surface findings; this record assigns no posture or tension.");
    return host;
  }

  function utteranceHeatmap(data, childKey, label) {
    const utterances = Array.isArray(data.utterances) ? data.utterances : [];
    const columns = [];
    utterances.forEach(row => (row[childKey] || []).forEach(item => {
      const key = words(item.kind || item.subtype);
      if (!columns.includes(key)) columns.push(key);
    }));
    columns.sort();
    if (!columns.length) return null;
    return heatmap({
      columns,
      rows: utterances.map(row => {
        const byKind = Object.fromEntries(columns.map(column => [column, 0]));
        (row[childKey] || []).forEach(item => {
          const key = words(item.kind || item.subtype);
          byKind[key] += Number.isFinite(Number(item.count)) ? Number(item.count) : 1;
        });
        return {
          label: [row.id, row.speaker].filter(Boolean).join(" · ") || "utterance",
          counts: columns.map(column => byKind[column])
        };
      }),
      ariaLabel: label
    });
  }

  function pragmaticPostureReport(data) {
    const utterances = Array.isArray(data.utterances) ? data.utterances : [];
    const byId = new Map(utterances.map(row => [row.id, row]));
    const postures = (data.relations || []).filter(row =>
      row && ["named_stance_candidate", "adjacent_stance_candidate"].includes(row.kind)
    ).map(row => ({
      speaker: (byId.get(row.utterance_id) || {}).speaker,
      utterances: [row.target_utterance_id, row.utterance_id].filter(Boolean),
      move: `${words(row.stance)} candidate`,
      register: "surface wording",
      response: "interaction not assigned"
    }));
    return { utterances, claims: [], postures, machine: { readings: [], extractions: [] } };
  }

  function addView(container, title, node) {
    if (!node) return;
    container.appendChild(htmlEl("h3", "viz-section-title", title));
    container.appendChild(node);
  }

  function fullRecord(data) {
    const details = htmlEl("details", "raw-toggle");
    details.appendChild(htmlEl("summary", null, "Full record"));
    details.appendChild(structuralView(data));
    return details;
  }

  /* Recognized replies lead with the conclusions their fields license.
     Machine-register fields remain available in the collapsed full record. */
  function renderPayload(container, data) {
    container.textContent = "";
    const shape = recordShape(data);
    if (shape === "unknown") {
      container.appendChild(structuralView(data));
      return;
    }
    if (shape === "discussion_report") {
      container.appendChild(discussionSummary(data));
      addView(container, "Claims and postures", postureStrip(data));
      addView(container, "Tensions and repairs", tensionRepairMap(data));
    } else if (shape === "surface_features") {
      container.appendChild(featureSummary(data, "features"));
      addView(container, "Surface features by utterance",
        utteranceHeatmap(data, "features", "surface-feature counts by utterance"));
    } else if (shape === "pragmatic_candidates") {
      container.appendChild(featureSummary(data, "atoms"));
      addView(container, "Stance candidates", postureStrip(pragmaticPostureReport(data)));
      addView(container, "Candidate forms by utterance",
        utteranceHeatmap(data, "atoms", "pragmatic candidate counts by utterance"));
    }
    container.appendChild(fullRecord(data));
  }

  window.HermesDiscourseViz = {
    postureStrip, tensionRepairMap, heatmap, structuralView, renderPayload,
    _internal: { svgEl, indexReport, anchorsToSpeakers, operatorGlyph, recordShape }
  };
})();
