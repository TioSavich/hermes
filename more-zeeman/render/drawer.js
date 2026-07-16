/*
 * drawer.js — one unified render-only filmstrip drawer for every Hermes scene
 * format (the frozen render contract, docs/research_assets/specs/
 * 2026-06-23-render-contract-frozen.md). It dispatches on scene.format and walks
 * a {frames:[...]} document forward only; it never computes a result or edits a
 * scene. A scene compiler emits geometry as primitives plus a role atom per
 * fill; this drawer resolves each role to the CSS variable var(--fig-<role>)
 * defined once in more-zeeman/hermes-tokens.css, keeping a bar.color fallback
 * during the hex->role migration (§6).
 *
 * Formats handled (§2): fraction-bars, number-line (jumps + length), area-model,
 * base-ten-columns (the ported Ace-of-Base rod/flat/cube shapes), set-grouping,
 * balance-scale, hybridization-model, notation, and the spatial family
 * (coordinate-plane).
 *
 * The audience host shell (§5) reads doc.tuple, the per-frame verbs, and
 * doc.grounding (philosopher); scene + caption (freshman); doc.teacher (teacher).
 * A body class view-freshman|view-philosopher|view-teacher controls which panels
 * show. The Calculate button POSTs numerals to the worker bridge and renders the
 * returned witness frames; it does not recompute anything in JS.
 *
 * No build step, no dependencies. Exposes window.HermesDrawer.
 */

(function (global) {
  'use strict';

  var SVG_NS = 'http://www.w3.org/2000/svg';

  // --- Color roles -------------------------------------------------------
  // A fill resolves to var(--fig-<role>). During the hex->role migration a
  // scene may still carry a literal color; that wins as a fallback (§6). For
  // SVG attributes set in JS we read the computed CSS variable value.

  function cssVar(name, fallback) {
    try {
      var v = getComputedStyle(document.documentElement)
        .getPropertyValue(name);
      v = v && v.trim();
      return v || fallback;
    } catch (e) {
      return fallback;
    }
  }

  // Resolve a primitive's fill: an explicit hex (migration fallback) wins,
  // else the role maps to --fig-<role>, else a neutral default.
  function fillFor(prim, defaultRole) {
    if (prim && prim.color) return prim.color;
    var role = (prim && prim.role) || defaultRole || 'neutral';
    return cssVar('--fig-' + role, '#cabf9f');
  }

  function strokeColor() { return cssVar('--fig-stroke', '#0d0c08'); }
  function paperColor()  { return cssVar('--paper-bg', '#f4ead6'); }
  function labelColor()  { return cssVar('--fig-label', '#1b1810'); }

  function num(v) {
    var n = Number(v);
    return isFinite(n) ? n : 0;
  }

  // --- SVG helpers -------------------------------------------------------

  function svgEl(name, attrs) {
    var e = document.createElementNS(SVG_NS, name);
    if (attrs) {
      for (var k in attrs) {
        if (attrs.hasOwnProperty(k) && attrs[k] !== null && attrs[k] !== undefined) {
          e.setAttribute(k, attrs[k]);
        }
      }
    }
    return e;
  }

  function rect(svg, x, y, w, h, fill, sw) {
    svg.appendChild(svgEl('rect', {
      x: x, y: y, width: w, height: h,
      fill: fill, stroke: strokeColor(),
      'stroke-width': (sw === undefined ? 1.5 : sw)
    }));
  }

  function frameRect(svg, x, y, w, h, sw) {
    svg.appendChild(svgEl('rect', {
      x: x, y: y, width: w, height: h,
      fill: 'none', stroke: strokeColor(),
      'stroke-width': (sw === undefined ? 1.5 : sw)
    }));
  }

  function circle(svg, cx, cy, r, fill, sw) {
    svg.appendChild(svgEl('circle', {
      cx: cx, cy: cy, r: r,
      fill: fill, stroke: strokeColor(),
      'stroke-width': (sw === undefined ? 1.5 : sw)
    }));
  }

  function line(svg, x1, y1, x2, y2, stroke, w) {
    svg.appendChild(svgEl('line', {
      x1: x1, y1: y1, x2: x2, y2: y2,
      stroke: stroke || strokeColor(),
      'stroke-width': (w === undefined ? 1 : w)
    }));
  }

  function text(svg, x, y, str, size) {
    if (str === undefined || str === null || str === '') return;
    var t = svgEl('text', {
      x: x, y: y, 'text-anchor': 'middle',
      'dominant-baseline': 'central',
      'font-family': 'Georgia, "Times New Roman", serif',
      'font-size': (size || 18),
      fill: labelColor()
    });
    t.textContent = str;
    svg.appendChild(t);
  }

  // Let a learner grab a place-value block and slide it. This is a viewing
  // affordance only: dragging a block applies an SVG transform, it does not
  // recompute or change the scene the worker returned. Pointer coordinates are
  // mapped into SVG user units through the inverse screen CTM so the block
  // tracks the cursor under any scaling. Only base-ten blocks (class bt-block)
  // are draggable; every other format is left untouched. A guard makes this a
  // no-op where the SVG/pointer API is absent (e.g. the node test harness).
  function enableBlockDrag(svg) {
    if (!svg || typeof svg.querySelectorAll !== 'function') return;
    if (typeof svg.createSVGPoint !== 'function') return;
    var blocks = svg.querySelectorAll('.bt-block');
    if (!blocks || !blocks.length) return;
    var active = null, start = null, base = null;

    function toUser(evt) {
      var pt = svg.createSVGPoint();
      pt.x = evt.clientX; pt.y = evt.clientY;
      var ctm = svg.getScreenCTM();
      if (!ctm) return { x: 0, y: 0 };
      var p = pt.matrixTransform(ctm.inverse());
      return { x: p.x, y: p.y };
    }
    function parseT(g) {
      var t = g.getAttribute('transform');
      var m = t && /translate\(\s*(-?[\d.]+)[ ,]+(-?[\d.]+)/.exec(t);
      return m ? { x: parseFloat(m[1]), y: parseFloat(m[2]) } : { x: 0, y: 0 };
    }
    function down(g) {
      return function (evt) {
        active = g; start = toUser(evt); base = parseT(g);
        g.setAttribute('class', 'bt-block bt-grabbed');
        if (g.parentNode) g.parentNode.appendChild(g); // raise to front
        if (evt.preventDefault) evt.preventDefault();
      };
    }
    function move(evt) {
      if (!active) return;
      var p = toUser(evt);
      active.setAttribute('transform',
        'translate(' + (base.x + (p.x - start.x)) + ' ' + (base.y + (p.y - start.y)) + ')');
    }
    function up() {
      if (active) active.setAttribute('class', 'bt-block');
      active = null;
    }
    Array.prototype.forEach.call(blocks, function (g) {
      g.setAttribute('style', 'cursor:grab;');
      g.addEventListener('pointerdown', down(g));
    });
    svg.addEventListener('pointermove', move);
    svg.addEventListener('pointerup', up);
    svg.addEventListener('pointerleave', up);
  }

  // =====================================================================
  // Per-format bounds + draw. Each format returns a {minX,minY,maxX,maxY}
  // box and paints into a supplied <svg>. The frame loop unions bounds
  // across every frame so nothing is clipped, then draws the current frame.
  // =====================================================================

  // --- fraction-bars (P2) -----------------------------------------------

  function boundsBars(scene, b) {
    var bars = (scene && scene.bars) || [];
    for (var i = 0; i < bars.length; i++) {
      var bar = bars[i];
      growBox(b, num(bar.x), num(bar.y), num(bar.w), num(bar.h));
    }
  }

  function drawFractionBars(svg, scene) {
    var bars = scene.bars || [];
    for (var i = 0; i < bars.length; i++) {
      var bar = bars[i];
      var bx = num(bar.x), by = num(bar.y), bw = num(bar.w), bh = num(bar.h);
      rect(svg, bx, by, bw, bh, fillFor(bar, 'whole'));
      var splits = bar.splits || [];
      for (var s = 0; s < splits.length; s++) {
        var sp = splits[s];
        rect(svg, bx + num(sp.x), by + num(sp.y), num(sp.w), num(sp.h),
             fillFor(sp, 'highlight'), 0.75);
      }
      frameRect(svg, bx, by, bw, bh);
      var lbl = (bar.label !== undefined && bar.label !== null)
        ? bar.label : (bar.fraction || '');
      if (lbl) text(svg, bx + bw / 2, by + bh / 2, lbl, 20);
    }
  }

  // --- number-line (P1): jumps + length ---------------------------------

  function boundsNumberLine(scene, b) {
    if (scene.mode === 'length') {
      var bars = scene.bars || [];
      for (var i = 0; i < bars.length; i++) {
        var bar = bars[i];
        growBox(b, num(bar.x), num(bar.y), num(bar.w), num(bar.h));
      }
      return;
    }
    // jumps: lay the axis on a fixed band; arcs rise above it.
    growBox(b, NL_X0, NL_AXIS_Y - 130, NL_X0 + NL_W, NL_AXIS_Y + 60);
  }

  var NL_X0 = 60, NL_W = 760, NL_AXIS_Y = 200;

  // Fraction of the line width the compressed pre-break stretch occupies.
  var NL_BREAK_GAP = 0.12;

  function nlBrokenAxis(axis) {
    if (!axis || !axis.scaleBreak) return false;
    var min = num(axis.min), max = num(axis.max), brk = num(axis.breakEnd);
    return brk > min && brk < max;
  }

  function nlScale(axis) {
    var min = num(axis && axis.min), max = num(axis && axis.max);
    if (max <= min) max = min + 1;
    if (nlBrokenAxis(axis)) {
      // Piecewise: [min, breakEnd] compresses into the leading NL_BREAK_GAP
      // of the line; [breakEnd, max] spans the rest. The break glyph sits
      // inside the compressed stretch, so its position states what is skipped.
      var brk = num(axis.breakEnd);
      return function (v) {
        v = num(v);
        if (v <= min) return NL_X0;
        if (v >= brk) {
          return NL_X0 + NL_W * (NL_BREAK_GAP + (v - brk) / (max - brk) * (1 - NL_BREAK_GAP));
        }
        return NL_X0 + NL_W * NL_BREAK_GAP * ((v - min) / (brk - min));
      };
    }
    return function (v) {
      return NL_X0 + (num(v) - min) / (max - min) * NL_W;
    };
  }

  function drawNumberLine(svg, scene) {
    if (scene.mode === 'length') { drawLengthBars(svg, scene); return; }
    var axis = scene.axis || { min: 0, max: 10, ticks: [] };
    var sx = nlScale(axis);
    // The base line.
    line(svg, NL_X0, NL_AXIS_Y, NL_X0 + NL_W, NL_AXIS_Y, strokeColor(), 2);
    // Ticks.
    var ticks = axis.ticks || [];
    for (var t = 0; t < ticks.length; t++) {
      var tx = sx(ticks[t]);
      line(svg, tx, NL_AXIS_Y - 6, tx, NL_AXIS_Y + 6, strokeColor(), 1);
    }
    // Scale-break glyph inside the compressed stretch it actually skips.
    // Scenes generated before breakEnd existed carry no honest break
    // position, so they get a plain axis rather than a decorative glyph.
    if (nlBrokenAxis(axis)) {
      var bx = NL_X0 + NL_W * (NL_BREAK_GAP / 2);
      var bk = cssVar('--fig-scale-break', '#a97c24');
      line(svg, bx - 5, NL_AXIS_Y - 8, bx + 1, NL_AXIS_Y + 8, bk, 2);
      line(svg, bx + 4, NL_AXIS_Y - 8, bx + 10, NL_AXIS_Y + 8, bk, 2);
    }
    // Arc jumps. Each jump is a semicircular arc from->to, colored by role.
    var jumps = scene.jumps || [];
    for (var j = 0; j < jumps.length; j++) {
      drawJumpArc(svg, jumps[j], sx);
    }
    var intervals = scene.intervals || [];
    for (var ii = 0; ii < intervals.length; ii++) {
      drawNumberLineInterval(svg, intervals[ii], sx);
    }
    // Marks (running labels).
    var marks = scene.marks || [];
    for (var m = 0; m < marks.length; m++) {
      var mk = marks[m];
      var mxx = sx(mk.at);
      if (mk.role) {
        svg.appendChild(svgEl('circle', {
          cx: mxx, cy: NL_AXIS_Y, r: 5,
          fill: fillFor(mk, 'point'), stroke: strokeColor(), 'stroke-width': 1
        }));
      }
      text(svg, mxx, NL_AXIS_Y + 24, mk.label, 14);
    }
  }

  function drawNumberLineInterval(svg, interval, sx) {
    var x1 = sx(interval.from), x2 = sx(interval.to);
    var color = fillFor(interval, interval.role || 'iterated');
    line(svg, x1, NL_AXIS_Y, x2, NL_AXIS_Y, color, 5);
    var endpointX = interval.arrow === 'left' ? x2 : x1;
    svg.appendChild(svgEl('circle', {
      cx: endpointX, cy: NL_AXIS_Y, r: 7,
      fill: interval.endpoint === 'closed' ? color : paperColor(),
      stroke: color, 'stroke-width': 2
    }));
    var arrowX = interval.arrow === 'left' ? x1 : x2;
    var dir = interval.arrow === 'left' ? -1 : 1;
    svg.appendChild(svgEl('path', {
      d: 'M ' + arrowX + ' ' + NL_AXIS_Y +
         ' l ' + (-10 * dir) + ' -6 l 0 12 z', fill: color
    }));
  }

  function drawJumpArc(svg, jump, sx) {
    var x1 = sx(jump.from), x2 = sx(jump.to);
    var stroke = fillFor(jump, jump.role || 'jump-add');
    var midY = NL_AXIS_Y - Math.min(110, 22 + Math.abs(x2 - x1) * 0.35);
    var d = 'M ' + x1 + ' ' + NL_AXIS_Y +
            ' Q ' + ((x1 + x2) / 2) + ' ' + midY +
            ' ' + x2 + ' ' + NL_AXIS_Y;
    svg.appendChild(svgEl('path', {
      d: d, fill: 'none', stroke: stroke,
      'stroke-width': jump.tier === 'unit' ? 1.5 : 2.5
    }));
    // Arrowhead at the destination.
    var dir = x2 >= x1 ? 1 : -1;
    var ah = svgEl('path', {
      d: 'M ' + x2 + ' ' + NL_AXIS_Y +
         ' l ' + (-6 * dir) + ' -4 l 0 8 z',
      fill: stroke
    });
    svg.appendChild(ah);
    // The +by / -by label at the arc apex.
    var by = num(jump.by);
    var sign = jump.role === 'jump-sub' ? '-' : '+';
    var jumpLabel = jump.label || (sign + by);
    text(svg, (x1 + x2) / 2, midY - 8, jumpLabel, 13);
  }

  function drawLengthBars(svg, scene) {
    var bars = scene.bars || [];
    for (var i = 0; i < bars.length; i++) {
      var bar = bars[i];
      var bx = num(bar.x), by = num(bar.y), bw = num(bar.w), bh = num(bar.h);
      rect(svg, bx, by, bw, bh, fillFor(bar, 'whole'));
      if (bar.label) {
        text(svg, bx + bw + 8, by + bh / 2, bar.label, 13);
        // left-anchor the trailing label
        var last = svg.lastChild;
        last.setAttribute('text-anchor', 'start');
      }
    }
  }

  // --- area-model (P3) ---------------------------------------------------

  function boundsRects(scene, b) {
    var rects = (scene && scene.rects) || [];
    for (var i = 0; i < rects.length; i++) {
      var r = rects[i];
      growBox(b, num(r.x), num(r.y), num(r.w), num(r.h));
    }
  }

  function drawAreaModel(svg, scene) {
    var rects = scene.rects || [];
    for (var i = 0; i < rects.length; i++) {
      var r = rects[i];
      var x = num(r.x), y = num(r.y), w = num(r.w), h = num(r.h);
      var rows = Math.max(1, Math.round(num(r.rows) || 1));
      var cols = Math.max(1, Math.round(num(r.cols) || 1));
      rect(svg, x, y, w, h, fillFor(r, 'inner'));
      if (rows * cols <= 400) {
        var cw = w / cols, ch = h / rows;
        for (var c = 1; c < cols; c++) line(svg, x + c * cw, y, x + c * cw, y + h, strokeColor(), 0.5);
        for (var rr = 1; rr < rows; rr++) line(svg, x, y + rr * ch, x + w, y + rr * ch, strokeColor(), 0.5);
      }
      frameRect(svg, x, y, w, h);
      if (r.label) text(svg, x + w / 2, y + h / 2, r.label, 22);
    }
    drawSceneGridlines(svg, scene);
  }

  function drawSceneGridlines(svg, scene) {
    var gl = scene.gridlines || {};
    var vs = gl.v || [], hs = gl.h || [];
    if (vs.length < 2 || hs.length < 2) return;
    var x0 = num(vs[0]), x1 = num(vs[vs.length - 1]);
    var y0 = num(hs[0]), y1 = num(hs[hs.length - 1]);
    for (var i = 1; i < vs.length - 1; i++) {
      line(svg, num(vs[i]), y0, num(vs[i]), y1, strokeColor(), 0.8);
    }
    for (var j = 1; j < hs.length - 1; j++) {
      line(svg, x0, num(hs[j]), x1, num(hs[j]), strokeColor(), 0.8);
    }
  }

  // --- base-ten-columns (P4): the ported Ace-of-Base rod/flat/cube shapes -
  //
  // Generic over any base B (Ace of Base, not base-ten only). Each scene column
  // is {place, count, base, role}: place 0 = ones, 1 = the base place (rods of
  // B), 2 = base-squared (flats of B x B), 3 = base-cubed (cubes). Block sizes
  // scale with B, so a base-5 rod is five cells long and a base-12 rod is
  // twelve. The drawer lays the places out as clean columns, highest place on
  // the left, lowest on the right, each block stacked inside its own column —
  // it reads as "groups of B", not as a bunched heap.

  function boundsBaseTen(scene, b) {
    // The drawer owns the geometry; bound the laid-out blocks generously.
    var layout = baseTenLayout(scene);
    for (var i = 0; i < layout.length; i++) {
      var L = layout[i];
      growBox(b, L.x, L.y, L.w, L.h);
    }
    // Leave room under the lowest blocks for the per-place labels.
    growBox(b, BT_X0, BT_Y0, 1, layout.length ? 1 : 1);
    growBox(b, BT_X0, BT_LABEL_Y(layout), 1, 22);
  }

  var BT_CELL = 16;           // one ones-block edge, in user units
  var BT_X0 = 40, BT_Y0 = 40; // top-left origin of the leftmost place column
  var BT_COLGAP = 34;         // gap between two place columns
  var BT_STACKGAP = 8;        // vertical gap between stacked blocks of one place
  var BT_LANEGAP = 10;        // gap between stack lanes inside one place column
  var BT_MAXH = 320;          // a place column wraps into a new lane past this

  function placeRole(place) {
    return place === 0 ? 'unit' : place === 1 ? 'rod' : place === 2 ? 'flat' : 'cube';
  }

  // The block's drawn footprint scales with the base. A rod is 1 x B, a flat is
  // B x B, a cube is an isometric B-block. Units are always one cell.
  function blockW(place, base) {
    if (place === 0) return BT_CELL;             // unit: 1 x 1
    if (place === 1) return BT_CELL * base;      // rod: B long, one cell tall
    if (place === 2) return BT_CELL * base;      // flat: B x B
    return BT_CELL * base * 0.95;                // cube: isometric footprint
  }
  function blockH(place, base) {
    if (place === 0) return BT_CELL;             // unit
    if (place === 1) return BT_CELL;             // rod: one cell tall
    if (place === 2) return BT_CELL * base;      // flat
    return BT_CELL * base * 1.05;                // cube
  }

  // Lay each place out as its own column. Highest place sits on the left.
  // Within a place, blocks stack downward; once a stack would run past BT_MAXH
  // it starts a new lane to the right, still inside that place's column. Every
  // returned block carries its place/role/base plus its index, so the draw pass
  // and the drag handlers can identify it.
  function baseTenLayout(scene) {
    var base = Math.max(2, Math.round(num(scene.base) || 10));
    var cols = (scene.columns || []).slice().sort(function (a, b) {
      return num(b.place) - num(a.place); // highest place first (left)
    });
    var out = [];
    var x = BT_X0;
    for (var i = 0; i < cols.length; i++) {
      var col = cols[i];
      var place = Math.round(num(col.place));
      var count = Math.max(0, Math.round(num(col.count)));
      var role = placeRole(place);
      var bw = blockW(place, base), bh = blockH(place, base);
      // How many blocks fit in one vertical lane before wrapping.
      var perLane = Math.max(1, Math.floor((BT_MAXH) / (bh + BT_STACKGAP)));
      var lanes = Math.max(1, Math.ceil(count / perLane));
      for (var k = 0; k < count; k++) {
        var lane = Math.floor(k / perLane);
        var row = k % perLane;
        out.push({
          place: place, role: role, base: base, idx: out.length,
          x: x + lane * (bw + BT_LANEGAP),
          y: BT_Y0 + row * (bh + BT_STACKGAP),
          w: bw, h: bh
        });
      }
      // The column is as wide as its widest content (lanes side by side), with a
      // minimum so an empty place still reserves a labeled slot.
      var colW = Math.max(bw, BT_CELL) + (lanes - 1) * (bw + BT_LANEGAP);
      out._cols = out._cols || [];
      out._cols.push({ place: place, role: role, x: x, w: colW, count: count });
      x += colW + BT_COLGAP;
    }
    return out;
  }

  function BT_LABEL_Y(layout) {
    var maxY = BT_Y0;
    for (var i = 0; i < layout.length; i++) {
      var b = layout[i].y + layout[i].h;
      if (b > maxY) maxY = b;
    }
    return maxY + 18;
  }

  // A base-aware place name for the column label. Place 0 is "ones" in every
  // base; base 10 keeps the familiar names; any other base names the higher
  // places by the base itself.
  function placeLabel(place, base) {
    if (place === 0) return 'ones';
    if (base === 10) {
      return place === 1 ? 'tens' : place === 2 ? 'hundreds'
        : place === 3 ? 'thousands' : 'B^' + place;
    }
    if (place === 1) return 'groups of ' + base;
    if (place === 2) return base + '×' + base;
    if (place === 3) return base + '³';
    return base + '^' + place;
  }

  function drawBaseTen(svg, scene) {
    var base = Math.max(2, Math.round(num(scene.base) || 10));
    var layout = baseTenLayout(scene);
    for (var i = 0; i < layout.length; i++) {
      var L = layout[i];
      var g;
      if (L.place === 0) g = drawUnitBlock(svg, L);
      else if (L.place === 1) g = drawRodBlock(svg, L, base);
      else if (L.place === 2) g = drawFlatBlock(svg, L, base);
      else g = drawCubeBlock(svg, L, base);
      if (g && g.setAttribute) {
        g.setAttribute('class', 'bt-block');
        g.setAttribute('data-place', L.place);
        g.setAttribute('data-idx', L.idx);
      }
    }
    // Per-place column labels and counts, so an empty place still reads as a
    // place (no silent collapse to base-10 columns).
    var labelY = BT_LABEL_Y(layout);
    var meta = layout._cols || [];
    for (var c = 0; c < meta.length; c++) {
      var col = meta[c];
      var cxx = col.x + col.w / 2;
      text(svg, cxx, labelY, placeLabel(col.place, base), 12);
      text(svg, cxx, labelY + 16, '× ' + col.count, 11);
    }
  }

  // Ported from AceofBases script.js drawUnit/drawRod/drawFlat/draw3DCube,
  // refactored to SVG and to role-keyed CSS-variable fills. Each block draws
  // into its own <g> so the host page can let a learner grab and move it; the
  // group is returned to the caller for tagging.
  function blockGroup(svg) {
    var g = svgEl('g', {});
    svg.appendChild(g);
    return g;
  }

  // Parallels blockGroup: append a <g> carrying a transform and return it, so a
  // caller can draw into a reflected/translated coordinate frame. The notation
  // format uses this to mirror a single reversed glyph; the transform string is
  // computed by the caller (in the notation case, from the glyph's own x by the
  // scene compiler), never invented here.
  function gTransform(svg, transform) {
    var g = svgEl('g', { transform: transform });
    svg.appendChild(g);
    return g;
  }

  function drawUnitBlock(svg, L) {
    var g = blockGroup(svg);
    rect(g, L.x, L.y, BT_CELL, BT_CELL, fillFor({ role: 'unit' }), 1);
    return g;
  }

  function drawRodBlock(svg, L, base) {
    var g = blockGroup(svg);
    var len = BT_CELL * base;
    rect(g, L.x, L.y, len, BT_CELL, fillFor({ role: 'rod' }), 1);
    for (var i = 1; i < base; i++) {
      line(g, L.x + i * BT_CELL, L.y, L.x + i * BT_CELL, L.y + BT_CELL, strokeColor(), 0.5);
    }
    return g;
  }

  function drawFlatBlock(svg, L, base) {
    var g = blockGroup(svg);
    var len = BT_CELL * base;
    rect(g, L.x, L.y, len, len, fillFor({ role: 'flat' }), 1);
    for (var i = 1; i < base; i++) {
      line(g, L.x + i * BT_CELL, L.y, L.x + i * BT_CELL, L.y + len, strokeColor(), 0.4);
      line(g, L.x, L.y + i * BT_CELL, L.x + len, L.y + i * BT_CELL, strokeColor(), 0.4);
    }
    return g;
  }

  // Isometric cube — three visible faces, ported from draw3DCube.
  function drawCubeBlock(svg, L, base) {
    var g = blockGroup(svg);
    var s = BT_CELL * base;
    var dx = s * 0.5, dy = s * 0.25, h = s * 0.7;
    var cx = L.x + dx, cy = L.y + dy + h * 0.2;
    var face = fillFor({ role: 'cube' });
    poly(g, [[cx, cy], [cx + dx, cy - dy], [cx, cy - 2 * dy], [cx - dx, cy - dy]], face);
    poly(g, [[cx, cy], [cx - dx, cy - dy], [cx - dx, cy - dy + h], [cx, cy + h]], shade(face, 0.85));
    poly(g, [[cx, cy], [cx + dx, cy - dy], [cx + dx, cy - dy + h], [cx, cy + h]], shade(face, 0.7));
    return g;
  }

  function poly(svg, pts, fill) {
    var d = pts.map(function (p, i) { return (i ? 'L' : 'M') + p[0] + ' ' + p[1]; }).join(' ') + ' Z';
    svg.appendChild(svgEl('path', { d: d, fill: fill, stroke: strokeColor(), 'stroke-width': 0.6 }));
  }

  // Darken a resolved fill for cube side-faces. Accepts #rrggbb; if the value
  // is a var()/named color the original is returned (no shading).
  function shade(hex, factor) {
    var m = /^#([0-9a-f]{6})$/i.exec(hex && hex.trim());
    if (!m) return hex;
    var n = parseInt(m[1], 16);
    var r = Math.round(((n >> 16) & 255) * factor);
    var g = Math.round(((n >> 8) & 255) * factor);
    var b = Math.round((n & 255) * factor);
    return '#' + ((1 << 24) + (r << 16) + (g << 8) + b).toString(16).slice(1);
  }

  // --- set-grouping (P5) -------------------------------------------------

  function boundsSetGrouping(scene, b) {
    var dots = (scene && scene.dots) || [];
    for (var i = 0; i < dots.length; i++) {
      var d = dots[i], r = num(d.r) || 18;
      growBox(b, num(d.x) - r, num(d.y) - r, 2 * r, 2 * r);
    }
    var f10 = (scene && scene.frames10) || [];
    for (var f = 0; f < f10.length; f++) {
      growBox(b, num(f10[f].x), num(f10[f].y), num(f10[f].w), num(f10[f].h));
    }
    var bins = (scene && scene.bins) || [];
    for (var bi = 0; bi < bins.length; bi++) {
      growBox(b, num(bins[bi].x), num(bins[bi].y), num(bins[bi].w), num(bins[bi].h));
    }
  }

  function drawSetGrouping(svg, scene) {
    // Ten-frame outlines first (under the dots).
    var f10 = scene.frames10 || [];
    for (var f = 0; f < f10.length; f++) {
      frameRect(svg, num(f10[f].x), num(f10[f].y), num(f10[f].w), num(f10[f].h), 1);
    }
    // Bins (grouping containers).
    var bins = scene.bins || [];
    for (var bi = 0; bi < bins.length; bi++) {
      var bn = bins[bi];
      rect(svg, num(bn.x), num(bn.y), num(bn.w), num(bn.h), fillFor({ role: 'neutral' }), 1);
      if (bn.label) text(svg, num(bn.x) + num(bn.w) / 2, num(bn.y) + num(bn.h) - 8, bn.label, 12);
    }
    // Pair lines (zero-pair / make-ten coupling).
    var pl = scene.pairLines || [];
    for (var p = 0; p < pl.length; p++) {
      line(svg, num(pl[p].x1), num(pl[p].y1), num(pl[p].x2), num(pl[p].y2), strokeColor(), 1.25);
    }
    // Dots.
    var dots = scene.dots || [];
    for (var i = 0; i < dots.length; i++) {
      var d = dots[i];
      var rr = num(d.r) || 18;
      var fill = d.tag === 'empty' ? paperColor() : fillFor(d, 'unit');
      svg.appendChild(svgEl('circle', {
        cx: num(d.x), cy: num(d.y), r: rr,
        fill: fill, stroke: strokeColor(), 'stroke-width': 1.25
      }));
    }
  }

  // --- balance-scale (PB) ------------------------------------------------

  var BS_CX = 360, BS_BEAM_Y = 120, BS_BEAM_W = 520, BS_PAN_DROP = 120;

  function boundsBalance(scene, b) {
    growBox(b, BS_CX - BS_BEAM_W / 2 - 40, 40,
            BS_BEAM_W + 80, BS_BEAM_Y + BS_PAN_DROP + 160);
  }

  function drawBalance(svg, scene) {
    var beam = scene.beam || { tilt: 'level' };
    var tilt = beam.tilt === 'left_down' ? 10 : beam.tilt === 'right_down' ? -10 : 0;
    var rad = tilt * Math.PI / 180;
    var hw = BS_BEAM_W / 2;
    var lx = BS_CX - hw * Math.cos(rad), ly = BS_BEAM_Y + hw * Math.sin(rad);
    var rx = BS_CX + hw * Math.cos(rad), ry = BS_BEAM_Y - hw * Math.sin(rad);
    // Fulcrum.
    poly(svg, [[BS_CX, BS_BEAM_Y], [BS_CX - 18, BS_BEAM_Y + 70], [BS_CX + 18, BS_BEAM_Y + 70]],
         fillFor({ role: 'pan' }));
    // Beam.
    line(svg, lx, ly, rx, ry, strokeColor(), 5);
    // Pans.
    drawPan(svg, scene.pans && scene.pans.left, lx, ly + BS_PAN_DROP, 'left');
    drawPan(svg, scene.pans && scene.pans.right, rx, ry + BS_PAN_DROP, 'right');
  }

  function drawPan(svg, items, x, y, side) {
    // Pan dish.
    var panW = 150;
    line(svg, x, (y - BS_PAN_DROP), x, y - 30, strokeColor(), 1.25); // hanger
    svg.appendChild(svgEl('path', {
      d: 'M ' + (x - panW / 2) + ' ' + (y - 30) +
         ' Q ' + x + ' ' + (y + 28) + ' ' + (x + panW / 2) + ' ' + (y - 30),
      fill: fillFor({ role: 'pan' }), stroke: strokeColor(), 'stroke-width': 1.5
    }));
    // Contents: lay weights / x-boxes left to right.
    items = items || [];
    var cellW = 24, gap = 4, cx = x - panW / 2 + 14, cy = y - 44;
    for (var i = 0; i < items.length; i++) {
      var it = items[i];
      var count = Math.round(num(it.count));
      var role = it.role || (it.kind === 'x' ? 'x-box' : 'unit-weight');
      for (var k = 0; k < count; k++) {
        rect(svg, cx, cy, cellW, cellW, fillFor({ role: role }), 1);
        if (it.kind === 'x') text(svg, cx + cellW / 2, cy + cellW / 2, 'x', 13);
        cx += cellW + gap;
        if (cx > x + panW / 2 - cellW) { cx = x - panW / 2 + 14; cy -= cellW + gap; }
      }
    }
  }

  // --- place-value-chart -------------------------------------------------

  var PVC_X0 = 150, PVC_Y0 = 76, PVC_COL_W = 112, PVC_ROW_H = 44;
  var PVC_LABEL_W = 120, PVC_HEADER_H = 54, PVC_CARRY_H = 44;

  function boundsPlaceValueChart(scene, b) {
    var cols = (scene && scene.columns) || [];
    var rows = (scene && scene.rows) || [];
    var w = PVC_LABEL_W + Math.max(1, cols.length) * PVC_COL_W;
    var h = PVC_CARRY_H + PVC_HEADER_H + Math.max(1, rows.length) * PVC_ROW_H;
    growBox(b, PVC_X0 - PVC_LABEL_W, PVC_Y0 - PVC_CARRY_H, w, h);
  }

  function drawPlaceValueChart(svg, scene) {
    var cols = scene.columns || [];
    var rows = scene.rows || [];
    var carries = scene.carries || [];
    var n = Math.max(1, cols.length);
    var tableX = PVC_X0 - PVC_LABEL_W;
    var tableY = PVC_Y0;
    var tableW = PVC_LABEL_W + n * PVC_COL_W;
    var tableH = PVC_HEADER_H + Math.max(1, rows.length) * PVC_ROW_H;

    rect(svg, tableX, tableY, tableW, tableH, paperColor(), 0);
    frameRect(svg, tableX, tableY, tableW, tableH, 1.4);
    line(svg, PVC_X0, tableY, PVC_X0, tableY + tableH, strokeColor(), 1);
    line(svg, tableX, tableY + PVC_HEADER_H, tableX + tableW, tableY + PVC_HEADER_H, strokeColor(), 1);

    for (var c = 0; c <= n; c++) {
      var x = PVC_X0 + c * PVC_COL_W;
      line(svg, x, tableY, x, tableY + tableH, strokeColor(), c === 0 ? 1.2 : 0.75);
    }
    for (var r = 0; r <= rows.length; r++) {
      var y = tableY + PVC_HEADER_H + r * PVC_ROW_H;
      line(svg, tableX, y, tableX + tableW, y, strokeColor(), r === rows.length ? 1.2 : 0.75);
    }

    for (var i = 0; i < cols.length; i++) {
      var col = cols[i];
      text(svg, PVC_X0 + i * PVC_COL_W + PVC_COL_W / 2, tableY + 20,
           col.label || '', 11);
      if (col.value !== undefined) {
        text(svg, PVC_X0 + i * PVC_COL_W + PVC_COL_W / 2, tableY + 40,
             chartNumberLabel(col.value), 10);
      }
    }

    for (var ri = 0; ri < rows.length; ri++) {
      var row = rows[ri];
      var cy = tableY + PVC_HEADER_H + ri * PVC_ROW_H + PVC_ROW_H / 2;
      var label = row.label || row.role || '';
      var labelNode = svgEl('text', {
        x: tableX + PVC_LABEL_W - 12, y: cy,
        'text-anchor': 'end',
        'dominant-baseline': 'central',
        'font-family': 'Georgia, "Times New Roman", serif',
        'font-size': row.role === 'sum' ? 16 : 14,
        fill: labelColor()
      });
      labelNode.textContent = label;
      svg.appendChild(labelNode);

      var digits = row.digits || [];
      for (var di = 0; di < Math.min(digits.length, n); di++) {
        var role = row.role === 'sum' ? 'highlight' : 'neutral';
        if (row.role === 'sum') {
          rect(svg, PVC_X0 + di * PVC_COL_W + 3, cy - PVC_ROW_H / 2 + 3,
               PVC_COL_W - 6, PVC_ROW_H - 6, fillFor({ role: role }), 0.4);
        }
        text(svg, PVC_X0 + di * PVC_COL_W + PVC_COL_W / 2, cy,
             String(digits[di]), row.role === 'sum' ? 20 : 18);
      }
    }

    for (var k = 0; k < carries.length; k++) {
      drawPlaceValueCarry(svg, carries[k], cols);
    }
  }

  function columnIndexForPlace(cols, place) {
    for (var i = 0; i < cols.length; i++) {
      if (Number(cols[i].place) === Number(place)) return i;
    }
    return -1;
  }

  function drawPlaceValueCarry(svg, carry, cols) {
    var fromIdx = columnIndexForPlace(cols, carry.fromPlace);
    var toIdx = columnIndexForPlace(cols, carry.toPlace);
    if (fromIdx < 0 || toIdx < 0) return;
    var y = PVC_Y0 - 16;
    var x1 = PVC_X0 + fromIdx * PVC_COL_W + PVC_COL_W / 2;
    var x2 = PVC_X0 + toIdx * PVC_COL_W + PVC_COL_W / 2;
    var stroke = fillFor({ role: 'iterated' }, 'iterated');
    var dir = x2 >= x1 ? 1 : -1;
    line(svg, x1, y, x2, y, stroke, 1.6);
    line(svg, x2, y, x2 - 7 * dir, y - 5, stroke, 1.6);
    line(svg, x2, y, x2 - 7 * dir, y + 5, stroke, 1.6);
    text(svg, x2, y - 18, carry.label || ('+' + carry.amount), 12);
  }

  // --- hybridization-model ----------------------------------------------

  function boundsHybridization(scene, b) {
    var primitives = (scene && scene.primitives) || [];
    for (var i = 0; i < primitives.length; i++) {
      var p = primitives[i];
      if (p.kind === 'set-host' || (p.kind === 'radial-partition' && p.host === 'set')) {
        growHybridSetBounds(b, p);
      } else if (p.kind === 'triangle-host' || p.kind === 'parallel-partition') {
        growBox(b, num(p.x), num(p.y), num(p.w), num(p.h));
      } else if (p.kind === 'host-rect' || p.kind === 'home-rect') {
        growBox(b, num(p.x), num(p.y), num(p.w), num(p.h));
      } else if (p.kind === 'home-circle' || p.kind === 'host-circle' || p.kind === 'radial-partition') {
        var r = num(p.r) || 1;
        growBox(b, num(p.cx) - r, num(p.cy) - r, 2 * r, 2 * r);
        if (p.hostX !== undefined) {
          growBox(b, num(p.hostX), num(p.hostY), num(p.hostW), num(p.hostH));
        }
      } else if (p.kind === 'vertical-partition') {
        if (p.host === 'circle') {
          var cr = num(p.r) || 1;
          growBox(b, num(p.cx) - cr, num(p.cy) - cr, 2 * cr, 2 * cr);
        } else {
          growBox(b, num(p.x), num(p.y), num(p.w), num(p.h));
        }
      }
    }
  }

  function drawHybridization(svg, scene) {
    var primitives = scene.primitives || [];
    for (var i = 0; i < primitives.length; i++) {
      var p = primitives[i];
      if (p.kind === 'host-rect') drawHybridHostRect(svg, p);
      else if (p.kind === 'home-rect') drawHybridHomeRect(svg, p);
      else if (p.kind === 'host-circle') drawHybridHostCircle(svg, p);
      else if (p.kind === 'home-circle') drawHybridHomeCircle(svg, p);
      else if (p.kind === 'set-host') drawHybridSetHost(svg, p);
      else if (p.kind === 'triangle-host') drawHybridTriangleHost(svg, p);
      else if (p.kind === 'radial-partition') drawHybridRadialPartition(svg, p);
      else if (p.kind === 'vertical-partition') drawHybridVerticalPartition(svg, p);
      else if (p.kind === 'parallel-partition') drawHybridParallelPartition(svg, p);
    }
  }

  function drawHybridHostRect(svg, p) {
    var x = num(p.x), y = num(p.y), w = num(p.w), h = num(p.h);
    rect(svg, x, y, w, h, fillFor(p, 'whole'), 1.25);
    frameRect(svg, x, y, w, h, 1.75);
    text(svg, x + w / 2, y + h + 22, p.label || 'rectangle', 14);
  }

  function drawHybridHomeRect(svg, p) {
    var x = num(p.x), y = num(p.y), w = num(p.w), h = num(p.h);
    rect(svg, x, y, w, h, fillFor(p, 'whole'), 1.25);
    frameRect(svg, x, y, w, h, 1.75);
    text(svg, x + w / 2, y + h + 22, p.label || 'rectangle', 14);
  }

  function drawHybridHostCircle(svg, p) {
    var cx = num(p.cx), cy = num(p.cy), r = num(p.r);
    circle(svg, cx, cy, r, fillFor(p, 'whole'), 1.5);
    text(svg, cx, cy + r + 22, p.label || 'circle', 14);
  }

  function drawHybridHomeCircle(svg, p) {
    var cx = num(p.cx), cy = num(p.cy), r = num(p.r);
    circle(svg, cx, cy, r, fillFor(p, 'whole'), 1.5);
    text(svg, cx, cy + r + 22, p.label || 'circle', 14);
  }

  function drawHybridTriangleHost(svg, p) {
    var points = trianglePoints(p);
    svg.appendChild(svgEl('polygon', {
      points: points.map(function (pt) { return pt.x + ',' + pt.y; }).join(' '),
      fill: fillFor(p, 'whole'),
      stroke: strokeColor(),
      'stroke-width': 1.5
    }));
    text(svg, num(p.x) + num(p.w) / 2, num(p.y) + num(p.h) + 22, p.label || 'triangle', 14);
  }

  function drawHybridRadialPartition(svg, p) {
    if (p.host === 'set') {
      drawHybridRadialPartitionOnSet(svg, p);
      return;
    }
    var cx = num(p.cx), cy = num(p.cy);
    var segments = Math.max(2, Math.round(num(p.segments) || 2));
    var stroke = fillFor(p, 'iterated');
    var isDeformation = p.role === 'deformation';
    for (var i = 0; i < segments; i++) {
      var a = -Math.PI / 2 + (Math.PI * 2 * i / segments);
      var end = p.host === 'rectangle'
        ? rayRectIntersection(cx, cy, a, p)
        : { x: cx + Math.cos(a) * num(p.r), y: cy + Math.sin(a) * num(p.r) };
      if (isDeformation) {
        svg.appendChild(svgEl('line', {
          x1: cx, y1: cy, x2: end.x, y2: end.y,
          stroke: stroke,
          'stroke-width': 2.4,
          'stroke-dasharray': '9 5'
        }));
      } else {
        line(svg, cx, cy, end.x, end.y, stroke, 1.4);
      }
    }
    if (p.label) text(svg, cx, cy - (num(p.r) || 80) - 20, p.label, 13);
  }

  function drawHybridSetHost(svg, p) {
    var positions = hybridSetPositions(p);
    var r = num(p.r) || 24;
    for (var i = 0; i < positions.length; i++) {
      circle(svg, positions[i].x, positions[i].y, r, fillFor(p, 'whole'), 1.5);
    }
    if (p.label && positions.length) {
      var b = hybridSetBox(p);
      text(svg, (b.minX + b.maxX) / 2, b.maxY + 22, p.label, 14);
    }
  }

  function drawHybridRadialPartitionOnSet(svg, p) {
    var positions = hybridSetPositions(p);
    var r = num(p.r) || 24;
    var segments = Math.max(2, Math.round(num(p.segments) || 3));
    var stroke = fillFor(p, 'iterated');
    var fill = fillFor(p, p.role === 'deformation' ? 'deformation' : 'iterated');
    var isDeformation = p.role === 'deformation';
    for (var i = 0; i < positions.length; i++) {
      var pos = positions[i];
      if (shadeIncludes(p.shade, i + 1)) {
        svg.appendChild(svgEl('path', {
          d: sectorPath(pos.x, pos.y, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 / segments),
          fill: fill,
          opacity: isDeformation ? 0.7 : 0.45,
          stroke: 'none'
        }));
      }
      for (var s = 0; s < segments; s++) {
        var a = -Math.PI / 2 + (Math.PI * 2 * s / segments);
        svg.appendChild(svgEl('line', {
          x1: pos.x, y1: pos.y,
          x2: pos.x + Math.cos(a) * r,
          y2: pos.y + Math.sin(a) * r,
          stroke: stroke,
          'stroke-width': isDeformation ? 2.2 : 1.3,
          'stroke-dasharray': isDeformation ? '7 4' : null
        }));
      }
    }
    if (p.label && positions.length) {
      var b = hybridSetBox(p);
      text(svg, (b.minX + b.maxX) / 2, b.minY - 18, p.label, 13);
    }
  }

  function sectorPath(cx, cy, r, a0, a1) {
    var x0 = cx + Math.cos(a0) * r;
    var y0 = cy + Math.sin(a0) * r;
    var x1 = cx + Math.cos(a1) * r;
    var y1 = cy + Math.sin(a1) * r;
    var large = Math.abs(a1 - a0) > Math.PI ? 1 : 0;
    return 'M ' + cx + ' ' + cy +
      ' L ' + x0 + ' ' + y0 +
      ' A ' + r + ' ' + r + ' 0 ' + large + ' 1 ' + x1 + ' ' + y1 +
      ' Z';
  }

  function hybridSetPositions(p) {
    var count = Math.max(1, Math.round(num(p.count) || 3));
    var r = num(p.r) || 24;
    var x = num(p.x);
    var y = num(p.y);
    var gap = num(p.gap) || 18;
    if (count === 3) {
      return [
        { x: x, y: y },
        { x: x + 2 * r + gap, y: y },
        { x: x, y: y + 2 * r + gap }
      ];
    }
    var cols = Math.ceil(Math.sqrt(count));
    var positions = [];
    for (var i = 0; i < count; i++) {
      positions.push({
        x: x + (i % cols) * (2 * r + gap),
        y: y + Math.floor(i / cols) * (2 * r + gap)
      });
    }
    return positions;
  }

  function hybridSetBox(p) {
    var positions = hybridSetPositions(p);
    var r = num(p.r) || 24;
    var b = emptyBox();
    for (var i = 0; i < positions.length; i++) {
      growBox(b, positions[i].x - r, positions[i].y - r, 2 * r, 2 * r);
    }
    return b;
  }

  function growHybridSetBounds(b, p) {
    var box = hybridSetBox(p);
    if (isFinite(box.minX)) growBox(b, box.minX, box.minY, box.maxX - box.minX, box.maxY - box.minY);
  }

  function drawHybridParallelPartition(svg, p) {
    if (p.host === 'triangle') {
      drawHybridParallelPartitionOnTriangle(svg, p);
    } else {
      drawHybridParallelPartitionOnRect(svg, p);
    }
  }

  function drawHybridParallelPartitionOnRect(svg, p) {
    var x = num(p.x), y = num(p.y), w = num(p.w), h = num(p.h);
    var bands = Math.max(2, Math.round(num(p.bands) || 3));
    var bandH = h / bands;
    var fill = fillFor(p, p.role === 'deformation' ? 'deformation' : 'iterated');
    var stroke = fillFor(p, 'iterated');
    var isDeformation = p.role === 'deformation';
    for (var b = 1; b <= bands; b++) {
      if (shadeIncludes(p.shade, b)) {
        svg.appendChild(svgEl('rect', {
          x: x, y: y + (b - 1) * bandH, width: w, height: bandH,
          fill: fill, opacity: isDeformation ? 0.55 : 0.42,
          stroke: 'none'
        }));
      }
    }
    for (var i = 1; i < bands; i++) {
      var ly = y + bandH * i;
      svg.appendChild(svgEl('line', {
        x1: x, y1: ly, x2: x + w, y2: ly,
        stroke: stroke,
        'stroke-width': isDeformation ? 2.4 : 1.4,
        'stroke-dasharray': isDeformation ? '9 5' : null
      }));
    }
    if (p.label) text(svg, x + w / 2, y - 20, p.label, 13);
  }

  function drawHybridParallelPartitionOnTriangle(svg, p) {
    var x = num(p.x), y = num(p.y), w = num(p.w), h = num(p.h);
    var bands = Math.max(2, Math.round(num(p.bands) || 3));
    var bandH = h / bands;
    var fill = fillFor(p, p.role === 'deformation' ? 'deformation' : 'iterated');
    var stroke = fillFor(p, 'iterated');
    var isDeformation = p.role === 'deformation';
    for (var b = 1; b <= bands; b++) {
      if (shadeIncludes(p.shade, b)) {
        svg.appendChild(svgEl('polygon', {
          points: triangleBandPoints(p, y + (b - 1) * bandH, y + b * bandH),
          fill: fill,
          opacity: isDeformation ? 0.55 : 0.42,
          stroke: 'none'
        }));
      }
    }
    for (var i = 1; i < bands; i++) {
      var ly = y + bandH * i;
      var left = triangleXAtY(p, ly, 'left');
      var right = triangleXAtY(p, ly, 'right');
      svg.appendChild(svgEl('line', {
        x1: left, y1: ly, x2: right, y2: ly,
        stroke: stroke,
        'stroke-width': isDeformation ? 2.4 : 1.4,
        'stroke-dasharray': isDeformation ? '9 5' : null
      }));
    }
    if (p.label) text(svg, x + w / 2, y - 20, p.label, 13);
  }

  function trianglePoints(p) {
    var x = num(p.x), y = num(p.y), w = num(p.w), h = num(p.h);
    return [
      { x: x + w / 2, y: y },
      { x: x + w, y: y + h },
      { x: x, y: y + h }
    ];
  }

  function triangleXAtY(p, yVal, side) {
    var x = num(p.x), y = num(p.y), w = num(p.w), h = num(p.h);
    var t = h === 0 ? 1 : Math.max(0, Math.min(1, (yVal - y) / h));
    var topX = x + w / 2;
    return side === 'left'
      ? topX + (x - topX) * t
      : topX + (x + w - topX) * t;
  }

  function triangleBandPoints(p, y0, y1) {
    var left0 = triangleXAtY(p, y0, 'left');
    var right0 = triangleXAtY(p, y0, 'right');
    var left1 = triangleXAtY(p, y1, 'left');
    var right1 = triangleXAtY(p, y1, 'right');
    return [
      left0 + ',' + y0,
      right0 + ',' + y0,
      right1 + ',' + y1,
      left1 + ',' + y1
    ].join(' ');
  }

  function drawHybridVerticalPartition(svg, p) {
    var cols = Math.max(2, Math.round(num(p.columns) || 2));
    var stroke = fillFor(p, 'iterated');
    var isDeformation = p.role === 'deformation';
    if (p.host === 'circle') {
      drawHybridVerticalPartitionOnCircle(svg, p, cols, stroke, isDeformation);
    } else {
      drawHybridVerticalPartitionOnRect(svg, p, cols, stroke, isDeformation);
    }
  }

  function drawHybridVerticalPartitionOnRect(svg, p, cols, stroke, isDeformation) {
    var x = num(p.x), y = num(p.y), w = num(p.w), h = num(p.h);
    var colW = w / cols;
    var fill = fillFor(p, isDeformation ? 'deformation' : 'iterated');
    for (var c = 1; c <= cols; c++) {
      if (shadeIncludes(p.shade, c)) {
        svg.appendChild(svgEl('rect', {
          x: x + (c - 1) * colW, y: y, width: colW, height: h,
          fill: fill, opacity: isDeformation ? 0.55 : 0.42,
          stroke: 'none'
        }));
      }
    }
    for (var i = 1; i < cols; i++) {
      var lx = x + colW * i;
      svg.appendChild(svgEl('line', {
        x1: lx, y1: y, x2: lx, y2: y + h,
        stroke: stroke,
        'stroke-width': isDeformation ? 2.4 : 1.4,
        'stroke-dasharray': isDeformation ? '9 5' : null
      }));
    }
    if (p.label) text(svg, x + w / 2, y - 20, p.label, 13);
  }

  function drawHybridVerticalPartitionOnCircle(svg, p, cols, stroke, isDeformation) {
    var cx = num(p.cx), cy = num(p.cy), r = num(p.r);
    var left = cx - r;
    var colW = (2 * r) / cols;
    var fill = fillFor(p, isDeformation ? 'deformation' : 'iterated');
    for (var c = 1; c <= cols; c++) {
      if (shadeIncludes(p.shade, c)) {
        drawCircleVerticalBand(svg, cx, cy, r, left + (c - 1) * colW, left + c * colW, fill, isDeformation);
      }
    }
    for (var i = 1; i < cols; i++) {
      var x = left + colW * i;
      var dy = Math.sqrt(Math.max(0, r * r - Math.pow(x - cx, 2)));
      svg.appendChild(svgEl('line', {
        x1: x, y1: cy - dy, x2: x, y2: cy + dy,
        stroke: stroke,
        'stroke-width': isDeformation ? 2.4 : 1.4,
        'stroke-dasharray': isDeformation ? '9 5' : null
      }));
    }
    if (p.label) text(svg, cx, cy - r - 20, p.label, 13);
  }

  function drawCircleVerticalBand(svg, cx, cy, r, x0, x1, fill, isDeformation) {
    var steps = 12;
    var points = [];
    for (var i = 0; i <= steps; i++) {
      var t = i / steps;
      var x = x0 + (x1 - x0) * t;
      var dy = Math.sqrt(Math.max(0, r * r - Math.pow(x - cx, 2)));
      points.push(x + ',' + (cy - dy));
    }
    for (var j = steps; j >= 0; j--) {
      var tb = j / steps;
      var xb = x0 + (x1 - x0) * tb;
      var dyb = Math.sqrt(Math.max(0, r * r - Math.pow(xb - cx, 2)));
      points.push(xb + ',' + (cy + dyb));
    }
    svg.appendChild(svgEl('polygon', {
      points: points.join(' '),
      fill: fill,
      opacity: isDeformation ? 0.55 : 0.42,
      stroke: 'none'
    }));
  }

  function shadeIncludes(shade, index) {
    if (!Array.isArray(shade)) return false;
    for (var i = 0; i < shade.length; i++) {
      if (Number(shade[i]) === index) return true;
    }
    return false;
  }

  function rayRectIntersection(cx, cy, angle, p) {
    var x0 = num(p.hostX), y0 = num(p.hostY);
    var x1 = x0 + num(p.hostW), y1 = y0 + num(p.hostH);
    var dx = Math.cos(angle), dy = Math.sin(angle);
    var ts = [];
    if (Math.abs(dx) > 1e-6) {
      ts.push((x0 - cx) / dx);
      ts.push((x1 - cx) / dx);
    }
    if (Math.abs(dy) > 1e-6) {
      ts.push((y0 - cy) / dy);
      ts.push((y1 - cy) / dy);
    }
    var best = null;
    for (var i = 0; i < ts.length; i++) {
      var t = ts[i];
      if (t <= 0) continue;
      var x = cx + dx * t, y = cy + dy * t;
      if (x >= x0 - 0.5 && x <= x1 + 0.5 && y >= y0 - 0.5 && y <= y1 + 0.5) {
        if (best === null || t < best.t) best = { t: t, x: x, y: y };
      }
    }
    if (best) return best;
    var r = num(p.r) || 80;
    return { x: cx + dx * r, y: cy + dy * r };
  }

  function chartNumberLabel(v) {
    var n = Number(v);
    if (!isFinite(n)) return String(v);
    return Math.abs(n) >= 1000 ? n.toLocaleString('en-US') : String(n);
  }

  // --- notation ----------------------------------------------------------
  // The glyph-level language: a row of inscribed characters at (x,y), each
  // carrying its own optional deformation transform. The compiler
  // (strategies/render/notation_scene.pl) computes every x/y and fixes every
  // flip/ghost/mark; this drawer only applies them. A productive scene lays
  // straight glyphs with an empty marks list; a deformation routed through the
  // misconception lane sets exactly one glyph's flip:horizontal or ghost, or
  // appends one strikethrough / chain-equals / carry mark.

  function boundsNotation(scene, b) {
    var gs = (scene && scene.glyphs) || [];
    for (var i = 0; i < gs.length; i++) {
      var g = gs[i];
      growBox(b, num(g.x) - 12, num(g.y) - 16, 24, 28);   // one glyph slot
    }
    var ms = (scene && scene.marks) || [];
    for (var j = 0; j < ms.length; j++) {
      var m = ms[j];
      if (m.kind === 'carry') growBox(b, num(m.x) - 10, num(m.y) - 30, 24, 24);
      // strikethrough/chain-equals sit inside existing glyph boxes.
    }
  }

  function drawNotation(svg, scene) {
    var gs = (scene && scene.glyphs) || [];
    for (var i = 0; i < gs.length; i++) {
      var g = gs[i];
      if (g.flip === 'horizontal') {
        // The one new primitive: reflect this glyph about its own x. The anchor
        // 2*x is computed here from the glyph's x; which glyph flips arrives in
        // the scene from Prolog, never decided in JS.
        var grp = gTransform(svg, 'matrix(-1 0 0 1 ' + (2 * num(g.x)) + ' 0)');
        text(grp, num(g.x), num(g.y), g.ch, g.size);
      } else if (g.ghost && g.ghost !== 'none') {
        // Overwrite/self-correction: faint under-box, struck under-digit, then
        // the over-digit on top.
        frameRect(svg, num(g.x) - 10, num(g.y) - 14, 20, 26, 0.5);
        text(svg, num(g.x), num(g.y), g.ghost, g.size);
        line(svg, num(g.x) - 9, num(g.y), num(g.x) + 9, num(g.y),
             fillFor({ role: 'deformation' }), 1.5);
        text(svg, num(g.x), num(g.y) - 2, g.ch, g.size);
      } else {
        text(svg, num(g.x), num(g.y), g.ch, g.size);
      }
    }
    var ms = (scene && scene.marks) || [];
    for (var j = 0; j < ms.length; j++) {
      var m = ms[j], red = fillFor({ role: 'deformation' });
      if (m.kind === 'strikethrough') {
        line(svg, num(m.x1), num(m.y1), num(m.x2), num(m.y2), red, 2);
      } else if (m.kind === 'chain-equals') {
        line(svg, num(m.x) - 6, num(m.y) + 10, num(m.x) + 6, num(m.y) + 10, red, 1.5);
      } else if (m.kind === 'carry') {            // copy drawPlaceValueCarry pattern
        var carryDigit = (m.carry !== undefined && m.carry !== null)
          ? m.carry : m.amount;
        text(svg, num(m.x), num(m.y) - 22, '+' + carryDigit, 11);
        line(svg, num(m.x), num(m.y) - 16, num(m.x), num(m.y) - 6,
             fillFor({ role: 'iterated' }), 1);
      }
    }
  }

  // --- coordinate-plane (spatial family) --------------------------------
  // The Cartesian graphing surface. The compiler emits MATH coordinates (points,
  // axis bounds, a plotted path); this drawer maps math -> pixels within a fixed
  // band, exactly as the number line scales its axis. A plotted pair carries role
  // "point"; a sign-dropped pair carries role "deformation"; the plotted line
  // carries role "iterated".

  var CP_X0 = 60, CP_Y0 = 40, CP_W = 440, CP_H = 440;

  function boundsCoordinatePlane(scene, b) {
    // The band is fixed; leave room for axis-tick labels and point labels.
    growBox(b, CP_X0 - 34, CP_Y0 - 26, CP_W + 80, CP_H + 52);
  }

  // Build the math->px maps sx/sy for the given axes. y is inverted (screen y
  // grows downward). A degenerate axis (min==max) is widened by one unit.
  function cpMaps(axes) {
    var xMin = num(axes && axes.xMin), xMax = num(axes && axes.xMax);
    var yMin = num(axes && axes.yMin), yMax = num(axes && axes.yMax);
    if (xMax <= xMin) xMax = xMin + 1;
    if (yMax <= yMin) yMax = yMin + 1;
    return {
      xMin: xMin, xMax: xMax, yMin: yMin, yMax: yMax,
      sx: function (mx) { return CP_X0 + (num(mx) - xMin) / (xMax - xMin) * CP_W; },
      sy: function (my) { return CP_Y0 + (yMax - num(my)) / (yMax - yMin) * CP_H; }
    };
  }

  function drawCoordinatePlane(svg, scene) {
    var axes = scene.axes || { xMin: -1, xMax: 1, yMin: -1, yMax: 1 };
    var m = cpMaps(axes);
    var faint = cssVar('--fig-neutral', '#cabf9f');

    // Gridlines at each integer, if the plane is not too dense to read.
    if ((m.xMax - m.xMin) <= 40 && (m.yMax - m.yMin) <= 40) {
      for (var gx = Math.ceil(m.xMin); gx <= Math.floor(m.xMax); gx++) {
        line(svg, m.sx(gx), m.sy(m.yMin), m.sx(gx), m.sy(m.yMax), faint, 0.4);
      }
      for (var gy = Math.ceil(m.yMin); gy <= Math.floor(m.yMax); gy++) {
        line(svg, m.sx(m.xMin), m.sy(gy), m.sx(m.xMax), m.sy(gy), faint, 0.4);
      }
    }

    // The axes: the x-axis at y=0 and the y-axis at x=0, drawn only when the
    // origin line falls inside the window.
    if (m.yMin <= 0 && m.yMax >= 0) {
      var ax = m.sy(0);
      line(svg, m.sx(m.xMin), ax, m.sx(m.xMax), ax, strokeColor(), 1.5);
    }
    if (m.xMin <= 0 && m.xMax >= 0) {
      var ay = m.sx(0);
      line(svg, ay, m.sy(m.yMin), ay, m.sy(m.yMax), strokeColor(), 1.5);
    }

    // Integer tick labels along whichever axis is in view (skip 0, keep it clean).
    if (m.yMin <= 0 && m.yMax >= 0) {
      for (var tx = Math.ceil(m.xMin); tx <= Math.floor(m.xMax); tx++) {
        if (tx !== 0) text(svg, m.sx(tx), m.sy(0) + 14, String(tx), 11);
      }
    }
    if (m.xMin <= 0 && m.xMax >= 0) {
      for (var ty = Math.ceil(m.yMin); ty <= Math.floor(m.yMax); ty++) {
        if (ty !== 0) text(svg, m.sx(0) - 14, m.sy(ty), String(ty), 11);
      }
    }

    // The plotted path (a line / polyline) under the points.
    var path = scene.path || [];
    if (path.length >= 2) {
      var stroke = fillFor({ role: 'iterated' }, 'iterated');
      for (var i = 1; i < path.length; i++) {
        line(svg, m.sx(path[i - 1].x), m.sy(path[i - 1].y),
             m.sx(path[i].x), m.sy(path[i].y), stroke, 2.2);
      }
    }

    // The plotted points.
    var points = scene.points || [];
    for (var p = 0; p < points.length; p++) {
      var pt = points[p];
      var cx = m.sx(pt.x), cy = m.sy(pt.y);
      circle(svg, cx, cy, 6, fillFor(pt, 'point'), 1.25);
      if (pt.label) text(svg, cx + 4, cy - 14, pt.label, 12);
    }
  }

  // =====================================================================
  // The dispatch table + the frame walker.
  // =====================================================================

  // --- rigid-motion (spatial family) ------------------------------------
  // A transformation actuator: a small integer polygon moved by an isometry, the
  // image beside the pre-image so the motion reads as a congruence. The compiler
  // emits MATH coordinates (integer lattice vertices, axis bounds, an optional
  // line of reflection); this drawer maps math -> pixels within the same fixed
  // band the coordinate plane uses (cpMaps). The pre-image polygon carries role
  // "pre-image", the image polygon role "image", the reflection-by-rotation
  // attempt role "deformation". The line of reflection is a stroke-only guide.

  function boundsRigidMotion(scene, b) {
    // Same fixed band as the coordinate plane; room for tick and vertex labels.
    growBox(b, CP_X0 - 34, CP_Y0 - 26, CP_W + 80, CP_H + 52);
  }

  function drawRigidMotion(svg, scene) {
    var axes = scene.axes || { xMin: -1, xMax: 1, yMin: -1, yMax: 1 };
    var m = cpMaps(axes);
    var faint = cssVar('--fig-neutral', '#cabf9f');

    // Gridlines at each integer, if the plane is not too dense to read.
    if ((m.xMax - m.xMin) <= 40 && (m.yMax - m.yMin) <= 40) {
      for (var gx = Math.ceil(m.xMin); gx <= Math.floor(m.xMax); gx++) {
        line(svg, m.sx(gx), m.sy(m.yMin), m.sx(gx), m.sy(m.yMax), faint, 0.4);
      }
      for (var gy = Math.ceil(m.yMin); gy <= Math.floor(m.yMax); gy++) {
        line(svg, m.sx(m.xMin), m.sy(gy), m.sx(m.xMax), m.sy(gy), faint, 0.4);
      }
    }

    // The axes through the origin, drawn only when the origin line is in view.
    if (m.yMin <= 0 && m.yMax >= 0) {
      var axisY = m.sy(0);
      line(svg, m.sx(m.xMin), axisY, m.sx(m.xMax), axisY, strokeColor(), 1.5);
    }
    if (m.xMin <= 0 && m.xMax >= 0) {
      var axisX = m.sx(0);
      line(svg, axisX, m.sy(m.yMin), axisX, m.sy(m.yMax), strokeColor(), 1.5);
    }

    // Integer tick labels along whichever axis is in view (skip 0, keep it clean).
    if (m.yMin <= 0 && m.yMax >= 0) {
      for (var tx = Math.ceil(m.xMin); tx <= Math.floor(m.xMax); tx++) {
        if (tx !== 0) text(svg, m.sx(tx), m.sy(0) + 14, String(tx), 11);
      }
    }
    if (m.xMin <= 0 && m.xMax >= 0) {
      for (var ty = Math.ceil(m.yMin); ty <= Math.floor(m.yMax); ty++) {
        if (ty !== 0) text(svg, m.sx(0) - 14, m.sy(ty), String(ty), 11);
      }
    }

    // The line of reflection, when the motion carries one: a stroke-only guide
    // inked with the iterated token so it reads apart from the black axes.
    var ml = scene.mirrorLine;
    if (ml) {
      line(svg, m.sx(num(ml.x1)), m.sy(num(ml.y1)),
           m.sx(num(ml.x2)), m.sy(num(ml.y2)),
           cssVar('--fig-iterated', '#a97c24'), 2.0);
    }

    // The center of a rotation, marked as a small stroke-only cross.
    var mo = scene.motion;
    if (mo && mo.kind === 'rotation') {
      var ccx = m.sx(num(mo.cx)), ccy = m.sy(num(mo.cy));
      line(svg, ccx - 5, ccy, ccx + 5, ccy, strokeColor(), 1.2);
      line(svg, ccx, ccy - 5, ccx, ccy + 5, strokeColor(), 1.2);
    }

    // The three figure slots. Each vertex list is an integer polygon; the drawer
    // resolves the slot to its --fig-<role> ink. Draw pre-image, then image, then
    // the deformation attempt over them.
    rmPaintPolygon(svg, m, scene.preImage, 'pre-image');
    rmPaintPolygon(svg, m, scene.image, 'image');
    rmPaintPolygon(svg, m, scene.deformation, 'deformation');
  }

  // Fill a lattice polygon from a vertex list under the math->px maps m.
  function rmPaintPolygon(svg, m, verts, role) {
    if (!verts || verts.length < 2) return;
    var pts = [];
    for (var i = 0; i < verts.length; i++) {
      pts.push([m.sx(num(verts[i].x)), m.sy(num(verts[i].y))]);
    }
    poly(svg, pts, fillFor({ role: role }, role));
  }

  // --- polyform-tiling (spatial family) ---------------------------------
  // A rigid lattice tiling: unit cells and free polyominoes (the pentomino
  // vocabulary) seated edge to edge in a bounded region. The compiler emits
  // integer (col,row) lattice cells with a role — "piece" for a placed
  // polyomino / unit cell, "deformation" for a rotation overhang, a removed
  // corner, or a stalled residue — plus neutral holes for the cells not yet
  // covered. This drawer owns the cell-square geometry (it sizes and places the
  // squares), exactly as base-ten owns the rod/flat/cube shapes; the compiler
  // emits no pixel.

  var PT_X0 = 60, PT_Y0 = 44, PT_MAX = 440;

  // Size the square cells to fit the lattice inside a fixed band, and map a
  // 1-based (col,row) index (row 1 at the top) to its top-left pixel.
  function ptMetrics(scene) {
    var lat = scene.lattice || { cols: 1, rows: 1 };
    var cols = Math.max(1, num(lat.cols)), rows = Math.max(1, num(lat.rows));
    var cell = Math.min(PT_MAX / cols, PT_MAX / rows);
    return {
      cols: cols, rows: rows, cell: cell,
      gw: cell * cols, gh: cell * rows,
      cx: function (col) { return PT_X0 + (num(col) - 1) * cell; },
      cy: function (row) { return PT_Y0 + (num(row) - 1) * cell; }
    };
  }

  function boundsPolyformTiling(scene, b) {
    var m = ptMetrics(scene);
    growBox(b, PT_X0 - 18, PT_Y0 - 26, m.gw + 36, m.gh + 52);
  }

  function drawPolyformTiling(svg, scene) {
    var m = ptMetrics(scene);
    var faint = cssVar('--fig-neutral', '#cabf9f');

    // The lattice grid: one line at every column and row edge, so the cells read
    // as a lattice even where no piece has landed.
    for (var gx = 0; gx <= m.cols; gx++) {
      line(svg, PT_X0 + gx * m.cell, PT_Y0, PT_X0 + gx * m.cell, PT_Y0 + m.gh, faint, 0.5);
    }
    for (var gy = 0; gy <= m.rows; gy++) {
      line(svg, PT_X0, PT_Y0 + gy * m.cell, PT_X0 + m.gw, PT_Y0 + gy * m.cell, faint, 0.5);
    }

    // Neutral holes: the cells not yet covered (col/row only, no role).
    var holes = scene.holes || [];
    for (var h = 0; h < holes.length; h++) {
      rect(svg, m.cx(holes[h].col), m.cy(holes[h].row), m.cell, m.cell, faint, 0.6);
    }

    // Placed / deformation cells, filled by role ("piece" -> --fig-piece,
    // "deformation" -> --fig-deformation). Each distinct piece is tagged once so
    // pieces read apart within the single piece ink.
    var cells = scene.cells || [];
    var seen = {};
    for (var i = 0; i < cells.length; i++) {
      var c = cells[i];
      var x = m.cx(c.col), y = m.cy(c.row);
      rect(svg, x, y, m.cell, m.cell, fillFor(c, 'piece'), 1);
      if (c.role === 'piece' && c.piece && c.piece !== 'unit'
          && !seen[c.piece] && m.cell >= 18) {
        text(svg, x + m.cell / 2, y + m.cell / 2, String(c.piece), 11);
        seen[c.piece] = true;
      }
    }

    // The bounding lattice frame + its label.
    frameRect(svg, PT_X0, PT_Y0, m.gw, m.gh, 1.5);
    if (scene.regionLabel) {
      text(svg, PT_X0 + m.gw / 2, PT_Y0 + m.gh + 16, scene.regionLabel, 12);
    }
  }

  // --- angle-circular (spatial family) ----------------------------------
  // A turning task: two rays from a shared vertex, an arc marking the amount of
  // turn between them, optionally filled as a central-angle sector. The compiler
  // emits PIXELS (the vertex, whole-degree ray angles, px lengths); this drawer
  // turns a whole-degree angle plus a px length into a ray endpoint via cos/sin,
  // then samples the arc/sector along the sweep, as the number line turns a
  // magnitude into a tick. A reference ray and the turn arc carry the figure
  // stroke; the filled sector carries role "sector"; the over-long rays of the
  // ray-length break carry role "deformation".

  // A whole-degree angle (CCW from the baseline) + a px radius -> endpoint px.
  // Screen y grows downward, so a positive turn lifts the ray (vy - sin).
  function acEndpoint(vx, vy, angleDeg, radius) {
    var t = num(angleDeg) * Math.PI / 180;
    return [vx + radius * Math.cos(t), vy - radius * Math.sin(t)];
  }

  // The vertex, then the arc sampled from startDeg through sweepDeg at radius;
  // poly closes it into the classic angle wedge (two short radii + the arc).
  function acWedge(vx, vy, startDeg, sweepDeg, radius) {
    var pts = [[vx, vy]];
    var sweep = num(sweepDeg);
    var steps = Math.max(2, Math.ceil(Math.abs(sweep) / 6));
    for (var i = 0; i <= steps; i++) {
      pts.push(acEndpoint(vx, vy, num(startDeg) + sweep * (i / steps), radius));
    }
    return pts;
  }

  function boundsAngleCircular(scene, b) {
    var v = scene.vertex || { x: 0, y: 0 };
    var vx = num(v.x), vy = num(v.y);
    var reach = 0, rays = scene.rays || [];
    for (var i = 0; i < rays.length; i++) reach = Math.max(reach, num(rays[i].length));
    if (scene.arc) reach = Math.max(reach, num(scene.arc.radius));
    if (scene.sector) reach = Math.max(reach, num(scene.sector.radius));
    if (reach <= 0) reach = 40;
    var pad = 28;
    growBox(b, vx - reach - pad, vy - reach - pad, 2 * (reach + pad), 2 * (reach + pad));
  }

  function drawAngleCircular(svg, scene) {
    var v = scene.vertex || { x: 0, y: 0 };
    var vx = num(v.x), vy = num(v.y);

    // The filled central-angle sector, under the rays (role "sector").
    var sector = scene.sector;
    if (sector) {
      poly(svg, acWedge(vx, vy, sector.startDeg, sector.sweepDeg, num(sector.radius)),
           fillFor(sector, 'sector'));
    }

    // The turn arc: a thin wedge marking the amount of turn (fill none). Drawn
    // once, unchanged by ray length — the arc is the measure, not the sides.
    var arc = scene.arc;
    if (arc && num(arc.sweepDeg) > 0) {
      poly(svg, acWedge(vx, vy, arc.startDeg, arc.sweepDeg, num(arc.radius)), 'none');
    }

    // The rays from the vertex. A reference ray carries the figure stroke; an
    // over-long ray of the ray-length break carries role "deformation". Ray
    // length is drawn but is never the measure.
    var rays = scene.rays || [];
    for (var i = 0; i < rays.length; i++) {
      var ray = rays[i];
      var end = acEndpoint(vx, vy, ray.angleDeg, num(ray.length));
      var stroke = ray.role ? fillFor(ray, 'deformation') : strokeColor();
      line(svg, vx, vy, end[0], end[1], stroke, ray.role ? 2.4 : 1.8);
    }

    // The vertex, then the degree label just outside the arc along the bisector.
    circle(svg, vx, vy, 3, strokeColor(), 1);
    if (scene.label && scene.label !== '' && arc) {
      var mid = num(arc.startDeg) + num(arc.sweepDeg) / 2;
      var lp = acEndpoint(vx, vy, mid, num(arc.radius) + 18);
      text(svg, lp[0], lp[1], scene.label + '°', 12);
    }
  }

  // --- data-display (spatial family) ------------------------------------
  // A small family of statistical pictures: the bar chart, the dot plot, and the
  // touching pseudo-histogram of the bar/histogram-conflation break. Unlike the
  // coordinate plane, whose geometry is a MATH lattice this drawer scales, a data
  // display is laid out in PIXELS by the compiler (as the fraction bars are): a
  // bar's length is a rendered extent, so the compiler emits x/y/w/h and this
  // drawer draws the rect where it is told. A bar or stacked dot carries role
  // "bar"; the conflated touching bins carry role "deformation".

  var DD_X0 = 60, DD_Y0 = 40, DD_PLOT_H = 300;   // match dd_x0/dd_y0/dd_plot_h
  var DD_COL_W = 40, DD_DOT_R = 7;               // match dd_col_w/dd_dot_r
  var DD_BASELINE = DD_Y0 + DD_PLOT_H;           // 340, the compiler's dd_baseline
  var DD_PLOT_W = 480;                           // default baseline span; grows to fit

  function ddRightEdge(scene) {
    var right = DD_X0 + DD_PLOT_W;
    var boxPlot = scene && scene.boxPlot;
    if (boxPlot && num(boxPlot.xMax) > right) right = num(boxPlot.xMax);
    var bars = (scene && scene.bars) || [];
    for (var i = 0; i < bars.length; i++) {
      var r = num(bars[i].x) + num(bars[i].w);
      if (r > right) right = r;
    }
    var dots = (scene && scene.dots) || [];
    for (var d = 0; d < dots.length; d++) {
      var rd = num(dots[d].x) + DD_DOT_R;
      if (rd > right) right = rd;
    }
    return right;
  }

  function boundsDataDisplay(scene, b) {
    // Anchor the axis corner, a left gutter for the freqMax tick label, and a
    // lower band for the category / value tick labels; then grow to every mark.
    growBox(b, DD_X0 - 40, DD_Y0 - 16, 40, 16);
    growBox(b, DD_X0, DD_BASELINE + 22, ddRightEdge(scene) - DD_X0, 1);
    var bars = (scene && scene.bars) || [];
    for (var i = 0; i < bars.length; i++) {
      var bar = bars[i];
      growBox(b, num(bar.x), num(bar.y) - 16, num(bar.w), num(bar.h) + 16);
    }
    var dots = (scene && scene.dots) || [];
    for (var d = 0; d < dots.length; d++) {
      var dot = dots[d];
      growBox(b, num(dot.x) - DD_DOT_R, num(dot.y) - DD_DOT_R, 2 * DD_DOT_R, 2 * DD_DOT_R);
    }
    var boxPlot = scene && scene.boxPlot;
    if (boxPlot) {
      growBox(b, num(boxPlot.xMin) - 12, num(boxPlot.y) - 42,
              num(boxPlot.xMax) - num(boxPlot.xMin) + 24, 84);
    }
  }

  function drawDataDisplay(svg, scene) {
    var axes = scene.axes || { categoryLabels: [], freqMax: 0 };
    var mode = scene.mode || 'bar';
    var right = ddRightEdge(scene);

    if (mode === 'box' && scene.boxPlot) {
      var bp = scene.boxPlot;
      var y = num(bp.y), top = y - 30, bottom = y + 30;
      var xMin = num(bp.xMin), xQ1 = num(bp.xQ1), xMedian = num(bp.xMedian);
      var xQ3 = num(bp.xQ3), xMax = num(bp.xMax);
      line(svg, xMin, y, xMax, y, strokeColor(), 1.5);
      line(svg, xMin, top + 10, xMin, bottom - 10, strokeColor(), 1.5);
      line(svg, xMax, top + 10, xMax, bottom - 10, strokeColor(), 1.5);
      rect(svg, xQ1, top, Math.max(1, xQ3 - xQ1), bottom - top,
           fillFor(bp, 'bar'));
      frameRect(svg, xQ1, top, Math.max(1, xQ3 - xQ1), bottom - top);
      line(svg, xMedian, top, xMedian, bottom, strokeColor(), 2);
      text(svg, xMin, bottom + 16, String(bp.minimum), 11);
      text(svg, xQ1, top - 10, String(bp.q1), 11);
      text(svg, xMedian, bottom + 16, String(bp.median), 11);
      text(svg, xQ3, top - 10, String(bp.q3), 11);
      text(svg, xMax, bottom + 16, String(bp.maximum), 11);
      return;
    }

    // The two axes: the frequency (y) axis up the left edge, the category (x)
    // baseline across the bottom of the plot band.
    line(svg, DD_X0, DD_Y0, DD_X0, DD_BASELINE, strokeColor(), 1.5);
    line(svg, DD_X0, DD_BASELINE, right, DD_BASELINE, strokeColor(), 1.5);

    // The frequency scale: 0 at the baseline, the freqMax ceiling at the top.
    var freqMax = num(axes.freqMax);
    if (freqMax > 0) {
      text(svg, DD_X0 - 16, DD_Y0, String(freqMax), 11);
      text(svg, DD_X0 - 16, DD_BASELINE, '0', 11);
    }

    // The bars (a bar chart, or the touching pseudo-histogram): a rect at the
    // exact pixels the compiler emits, framed, its count marked above and its
    // category named below. The fill role rides on the bar (bar vs deformation).
    var bars = scene.bars || [];
    for (var i = 0; i < bars.length; i++) {
      var bar = bars[i];
      var bx = num(bar.x), by = num(bar.y), bw = num(bar.w), bh = num(bar.h);
      rect(svg, bx, by, bw, bh, fillFor(bar, 'bar'));
      frameRect(svg, bx, by, bw, bh);
      if (bar.count !== undefined && bar.count !== null) {
        text(svg, bx + bw / 2, by - 8, String(bar.count), 12);
      }
      if (bar.label) text(svg, bx + bw / 2, DD_BASELINE + 14, String(bar.label), 12);
    }

    // The stacked dots (a dot plot): one circle per observation at its emitted
    // pixel, equal values piling into a frequency column. Each dot carries role
    // "bar" (a stacked-dot fill).
    var dots = scene.dots || [];
    for (var d = 0; d < dots.length; d++) {
      var dot = dots[d];
      circle(svg, num(dot.x), num(dot.y), DD_DOT_R, fillFor(dot, 'bar'), 1);
    }

    // The value tick labels sit under the dot columns (one per integer value from
    // the least to the greatest, spaced one column apart).
    if (mode === 'dot') {
      var labels = axes.categoryLabels || [];
      for (var t = 0; t < labels.length; t++) {
        text(svg, DD_X0 + t * DD_COL_W, DD_BASELINE + 14, String(labels[t]), 11);
      }
    }
  }

  // --- solid-net (spatial family) ---------------------------------------
  // A solid unfolds to a planar net. The compiler emits PIXEL coordinates (a
  // polygon of integer pixel vertices per face, plus fold-crease segments); this
  // drawer inks one closed <path> per face through the shared `poly` helper and one
  // dashed <line> per fold crease. A net or isometric face carries role "face"; the
  // faces of an unfoldable arrangement carry role "deformation". Creases are
  // stroke, never fill — the crease reads as a fold, not a face.

  function boundsSolidNet(scene, b) {
    var faces = (scene && scene.faces) || [];
    for (var i = 0; i < faces.length; i++) {
      var pts = faces[i].points || [];
      for (var j = 0; j < pts.length; j++) {
        // a small pad leaves room for the centroid face label.
        growBox(b, num(pts[j].x) - 8, num(pts[j].y) - 8, 16, 16);
      }
    }
    var creases = (scene && scene.creases) || [];
    for (var k = 0; k < creases.length; k++) {
      var c = creases[k];
      growBox(b, num(c.x1), num(c.y1), 0, 0);
      growBox(b, num(c.x2), num(c.y2), 0, 0);
    }
  }

  function drawSolidNet(svg, scene) {
    var faces = scene.faces || [];
    for (var i = 0; i < faces.length; i++) {
      var f = faces[i];
      var raw = f.points || [];
      if (raw.length >= 3) {
        var pts = [];
        var cx = 0, cy = 0;
        for (var j = 0; j < raw.length; j++) {
          var px = num(raw[j].x), py = num(raw[j].y);
          pts.push([px, py]);
          cx += px; cy += py;
        }
        poly(svg, pts, fillFor(f, 'face'));
        if (f.label) text(svg, cx / raw.length, cy / raw.length, f.label, 12);
      }
    }
    // Fold creases: dashed segments drawn over the faces (stroke, no fill). The
    // shared `line` helper carries no dash, so the crease is built with svgEl,
    // exactly as every dashed stroke in this drawer is.
    var creases = scene.creases || [];
    var creaseInk = strokeColor();
    for (var k = 0; k < creases.length; k++) {
      var c = creases[k];
      svg.appendChild(svgEl('line', {
        x1: num(c.x1), y1: num(c.y1), x2: num(c.x2), y2: num(c.y2),
        stroke: creaseInk, 'stroke-width': 1.4, 'stroke-dasharray': '6 4'
      }));
    }
  }

  // --- geoboard (spatial family) ----------------------------------------
  // Pegs and a rubber-band polygon on the integer lattice. The compiler emits
  // MATH lattice coords; this reuses the coordinate-plane band (cpMaps + the CP_*
  // consts) to map math -> pixels. A peg carries role "peg"; the miscounted peg
  // carries role "deformation". The band is a heavier stroke; the enclosed region
  // fills faintly with the shared "whole" role.

  function boundsGeoboard(scene, b) {
    growBox(b, CP_X0 - 34, CP_Y0 - 26, CP_W + 80, CP_H + 52);
  }

  function drawGeoboard(svg, scene) {
    var lat = scene.lattice || { xMin: -1, xMax: 1, yMin: -1, yMax: 1 };
    var m = cpMaps({ xMin: lat.xMin, xMax: lat.xMax, yMin: lat.yMin, yMax: lat.yMax });

    // The enclosed region + the rubber band.
    var poly = scene.polygon || [];
    if (poly.length >= 3) {
      var d = poly.map(function (p, i) {
        return (i ? 'L' : 'M') + m.sx(p.x) + ' ' + m.sy(p.y);
      }).join(' ') + ' Z';
      svg.appendChild(svgEl('path', {
        d: d, fill: fillFor({ role: 'whole' }), 'fill-opacity': 0.5, stroke: 'none'
      }));
      for (var e = 0; e < poly.length; e++) {
        var a = poly[e], c = poly[(e + 1) % poly.length];
        line(svg, m.sx(a.x), m.sy(a.y), m.sx(c.x), m.sy(c.y), strokeColor(), 2.4);
      }
    }

    // The pegs: outside pegs are faint dots; boundary and interior pegs are the
    // counted lattice points (boundary drawn with a heavier ring); the
    // miscounted peg is inked --fig-deformation.
    var pegs = scene.pegs || [];
    for (var i = 0; i < pegs.length; i++) {
      var pg = pegs[i], px = m.sx(pg.x), py = m.sy(pg.y);
      var kind = pg.kind, role = pg.role || 'peg';
      if (role === 'deformation') {
        circle(svg, px, py, 6, fillFor({ role: 'deformation' }), 1.5);
      } else if (kind === 'boundary') {
        circle(svg, px, py, 5, fillFor({ role: 'peg' }), 2);
      } else if (kind === 'interior') {
        circle(svg, px, py, 4.5, fillFor({ role: 'peg' }), 1);
      } else {
        circle(svg, px, py, 2.5, fillFor({ role: 'neutral' }), 0.5);
      }
    }

    // The Pick area, labelled at the top of the lattice.
    if (scene.area !== undefined && scene.area !== null) {
      text(svg, m.sx((lat.xMin + lat.xMax) / 2), m.sy(lat.yMax) - 6,
           'area ' + scene.area, 13);
    }
  }

  var DISPATCH = {
    'fraction-bars':     { bounds: boundsBars,        draw: drawFractionBars },
    'number-line':       { bounds: boundsNumberLine,  draw: drawNumberLine },
    'area-model':        { bounds: boundsRects,       draw: drawAreaModel },
    'base-ten-columns':  { bounds: boundsBaseTen,     draw: drawBaseTen },
    'place-value-chart': { bounds: boundsPlaceValueChart, draw: drawPlaceValueChart },
    'set-grouping':      { bounds: boundsSetGrouping, draw: drawSetGrouping },
    'balance-scale':     { bounds: boundsBalance,     draw: drawBalance },
    'hybridization-model': { bounds: boundsHybridization, draw: drawHybridization },
    'notation':          { bounds: boundsNotation,    draw: drawNotation },
    'coordinate-plane':  { bounds: boundsCoordinatePlane, draw: drawCoordinatePlane },
    'rigid-motion':      { bounds: boundsRigidMotion,     draw: drawRigidMotion },
    'polyform-tiling':   { bounds: boundsPolyformTiling, draw: drawPolyformTiling },
    'angle-circular':    { bounds: boundsAngleCircular, draw: drawAngleCircular },
    'data-display':      { bounds: boundsDataDisplay,    draw: drawDataDisplay },
    'solid-net':         { bounds: boundsSolidNet,     draw: drawSolidNet },
    'geoboard':          { bounds: boundsGeoboard,      draw: drawGeoboard }
  };

  function emptyBox() { return { minX: Infinity, minY: Infinity, maxX: -Infinity, maxY: -Infinity }; }
  function growBox(b, x, y, w, h) {
    if (x < b.minX) b.minX = x;
    if (y < b.minY) b.minY = y;
    if (x + w > b.maxX) b.maxX = x + w;
    if (y + h > b.maxY) b.maxY = y + h;
  }

  function documentBounds(frames, canvas) {
    var b = emptyBox();
    for (var f = 0; f < frames.length; f++) {
      var scene = frames[f] && frames[f].scene;
      if (!scene) continue;
      var handler = DISPATCH[scene.format];
      if (handler) handler.bounds(scene, b);
    }
    if (!isFinite(b.minX)) {
      var c = canvas || {};
      return { minX: 0, minY: 0, maxX: num(c.width) || 720, maxY: num(c.height) || 380 };
    }
    return b;
  }

  function buildSvg(frame, bounds) {
    var pad = 24;
    var vbX = bounds.minX - pad, vbY = bounds.minY - pad;
    var vbW = (bounds.maxX - bounds.minX) + 2 * pad;
    var vbH = (bounds.maxY - bounds.minY) + 2 * pad;

    var svg = svgEl('svg', {
      xmlns: SVG_NS,
      viewBox: vbX + ' ' + vbY + ' ' + vbW + ' ' + vbH,
      preserveAspectRatio: 'xMidYMid meet'
    });
    rect(svg, vbX, vbY, vbW, vbH, paperColor(), 0);

    var scene = (frame && frame.scene) || {};
    var handler = DISPATCH[scene.format];
    if (handler) {
      handler.draw(svg, scene);
    } else {
      text(svg, vbX + vbW / 2, vbY + vbH / 2,
           'No drawer for format "' + (scene.format || '?') + '".', 16);
    }
    return svg;
  }

  // =====================================================================
  // The filmstrip controller + audience host shell.
  // =====================================================================

  function Drawer(opts) {
    this.opts = opts || {};
    this.stageId = this.opts.stage || 'stage';
    this.doc = { frames: [] };
    this.index = 0;
    this.bounds = null;
    this.playing = false;
    this.playTimer = null;
  }

  Drawer.prototype.el = function (id) { return document.getElementById(id); };

  // A render document must be a non-null object carrying (at least) a frames
  // array. A bare scalar, a string, or null is not drawable; ingest refuses it
  // rather than crashing on `doc.frames = ...` (which throws on a primitive).
  function isDrawable(doc) {
    return doc !== null && typeof doc === 'object' && !Array.isArray(doc);
  }

  Drawer.prototype.ingest = function (doc) {
    if (!isDrawable(doc)) {
      this.showError('Could not draw this: the engine returned ' + typeof doc);
      return;
    }
    this.doc = doc;
    this.doc.frames = Array.isArray(this.doc.frames) ? this.doc.frames : [];
    this.index = 0;
    this.bounds = documentBounds(this.doc.frames, this.doc.canvas);
    this.renderPanels();
    this.render();
  };

  Drawer.prototype.render = function () {
    var stage = this.el(this.stageId);
    if (!stage) return;
    while (stage.firstChild) stage.removeChild(stage.firstChild);

    var frames = this.doc.frames;
    if (this.doc.error && frames.length === 0) {
      var ep = document.createElement('p');
      ep.className = 'error';
      ep.textContent = this.doc.error;
      stage.appendChild(ep);
      return;
    }
    if (frames.length === 0) {
      var emp = document.createElement('p');
      emp.className = 'empty-state';
      emp.textContent = 'Change the inputs and Calculate.';
      stage.appendChild(emp);
      return;
    }
    var frame = frames[this.index];
    var svg = buildSvg(frame, this.bounds);
    svg.setAttribute('id', 'scene-svg');
    svg.setAttribute('width', '100%');
    stage.appendChild(svg);
    enableBlockDrag(svg);

    setText(this.el('caption'), (frame && frame.caption) || '');
    setText(this.el('counter'), 'step ' + (this.index + 1) + ' of ' + frames.length);

    var annot = this.el('annotation-flag');
    if (annot) annot.style.visibility = (frame && frame.sceneChanged === false) ? 'visible' : 'hidden';

    var slider = this.el('seek');
    if (slider) { slider.max = String(frames.length - 1); slider.value = String(this.index); }

    var prev = this.el('prev'), next = this.el('next');
    if (prev) prev.disabled = this.index <= 0;
    if (next) next.disabled = this.index >= frames.length - 1;

    this.renderVerbs();
  };

  // --- Audience panels (§5) ---------------------------------------------

  Drawer.prototype.renderPanels = function () {
    var doc = this.doc;
    // Header context.
    var bits = [];
    if (doc.kind) bits.push(doc.kind);
    var req = doc.request || {};
    Object.keys(req).forEach(function (k) {
      if (req[k] !== null && req[k] !== undefined && req[k] !== '') bits.push(k + ' ' + req[k]);
    });
    setText(this.el('context'), bits.join(' · '));
    setText(this.el('result'), doc.result ? ('result: ' + doc.result) : '');

    // Philosopher: tuple + grounding band.
    setText(this.el('tuple'), doc.tuple || '');
    this.renderGrounding(doc.grounding);

    // Teacher: the four channels.
    this.renderTeacher(doc.teacher);
  };

  Drawer.prototype.renderGrounding = function (g) {
    var band = this.el('grounding');
    if (!band) return;
    if (!g) { band.style.display = 'none'; band.innerHTML = ''; return; }
    band.style.display = '';
    band.innerHTML = '';
    addKV(band, 'practice', g.practice);
    addKV(band, 'metaphor', g.metaphor_label);
    addKV(band, 'gloss', g.metaphor_gloss);
    addKV(band, 'primitive', g.primitive);
    addKV(band, 'role', g.role);
  };

  Drawer.prototype.renderTeacher = function (t) {
    var panel = this.el('teacher');
    if (!panel) return;
    panel.innerHTML = '';
    if (!t) {
      panel.appendChild(textNode('div', 'no teacher layer for this claim', 'teacher-empty'));
      return;
    }
    addKV(panel, 'standard', t.standard);
    addKV(panel, 'embodied basis', t.embodied);
    addKV(panel, 'incompatibility', t.incompatibility_penumbra);
    addKV(panel, 'breaks at', formatBreaksAt(t.breaks_at));
    addKV(panel, 'repair', t.repair);
  };

  Drawer.prototype.renderVerbs = function () {
    var box = this.el('verbs');
    if (!box) return;
    box.innerHTML = '';
    var frames = this.doc.frames;
    for (var i = 0; i < frames.length; i++) {
      var span = document.createElement('span');
      span.className = 'verb-step' + (i === this.index ? ' verb-current' : '');
      span.textContent = (i + 1) + '. ' + (frames[i].verb || '');
      box.appendChild(span);
    }
  };

  // --- Navigation -------------------------------------------------------

  Drawer.prototype.goTo = function (i) {
    var n = this.doc.frames.length;
    if (n === 0) return;
    this.index = Math.max(0, Math.min(n - 1, i));
    this.render();
  };

  Drawer.prototype.setPlaying = function (on) {
    this.playing = on;
    var btn = this.el('play');
    if (btn) btn.textContent = on ? 'Pause' : 'Play';
    if (this.playTimer) { clearInterval(this.playTimer); this.playTimer = null; }
    var self = this;
    if (on) {
      this.playTimer = setInterval(function () {
        if (self.index >= self.doc.frames.length - 1) { self.setPlaying(false); return; }
        self.goTo(self.index + 1);
      }, 1400);
    }
  };

  Drawer.prototype.wire = function () {
    var self = this;
    bind(this.el('prev'), 'click', function () { self.setPlaying(false); self.goTo(self.index - 1); });
    bind(this.el('next'), 'click', function () { self.setPlaying(false); self.goTo(self.index + 1); });
    bind(this.el('seek'), 'input', function (e) { self.setPlaying(false); self.goTo(Number(e.target.value)); });
    bind(this.el('play'), 'click', function () { self.setPlaying(!self.playing); });
    bind(this.el('download'), 'click', function () { self.downloadSvg(); });

    document.addEventListener('keydown', function (e) {
      if (e.key === 'ArrowLeft') { self.setPlaying(false); self.goTo(self.index - 1); }
      else if (e.key === 'ArrowRight') { self.setPlaying(false); self.goTo(self.index + 1); }
    });

    // Audience toggle: buttons with data-view set the body class.
    var toggles = document.querySelectorAll('[data-view]');
    Array.prototype.forEach.call(toggles, function (b) {
      bind(b, 'click', function () { setView(b.getAttribute('data-view')); });
    });

    // The Calculate button: POST numerals to the worker bridge, render the
    // returned witness frames. No recompute in JS.
    bind(this.el('calculate'), 'click', function () { self.calculate(); });
  };

  // --- Worker bridge ----------------------------------------------------
  // POST the host's op + the numeric inputs to the configured bridge endpoint;
  // the worker returns an enriched render document. The drawer renders it as-is.

  Drawer.prototype.calculate = function () {
    var self = this;
    var op = this.opts.op;
    var endpoint = this.opts.endpoint || '/api/render';
    var payload = { op: op };
    Object.assign(payload, this.collectInputs());
    this.setBusy(true);
    fetch(endpoint, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    }).then(function (r) {
      return r.json().catch(function () { return null; }).then(function (body) {
        return { ok: r.ok, status: r.status, body: body };
      });
    }).then(function (resp) {
      self.setBusy(false);
      var body = resp.body;
      // A worker / handler error: {ok:false, error:...} or {error:...}.
      if (body && typeof body === 'object' && (body.ok === false || body.error)) {
        self.showError('The engine could not draw this: ' +
          (body.error || ('HTTP ' + resp.status)));
        return;
      }
      if (!resp.ok) {
        self.showError('The engine returned an error (HTTP ' + resp.status + ').');
        return;
      }
      // The render document IS the body: it carries a `frames` array, and also a
      // top-level `result` field holding the human answer (e.g. "x = 4", "73").
      // Do NOT unwrap body.result — that answer is a string, not an envelope. Only
      // unwrap a genuine {result:<document>} envelope whose result is itself a
      // frames document. (This is the bug that made every Calculate fail: the
      // drawer grabbed the answer string and could not draw it.)
      var doc = body;
      if (isDrawable(body) && !Array.isArray(body.frames)
          && isDrawable(body.result) && Array.isArray(body.result.frames)) {
        doc = body.result;
      }
      if (!isDrawable(doc) || !Array.isArray(doc.frames)) {
        self.showError('Could not draw this: the engine returned no frames.');
        return;
      }
      self.ingest(doc);
    }).catch(function (err) {
      self.setBusy(false);
      self.showError('Calculate failed: ' + (err && err.message ? err.message : err));
    });
  };

  // Cold-start: the worker loads the KB on the first request (~30s). While a
  // fetch is in flight, disable Calculate and show a working message so the page
  // does not look dead. Re-enabled on success or error.
  Drawer.prototype.setBusy = function (on) {
    var btn = this.el('calculate');
    if (btn) btn.disabled = !!on;
    if (on) {
      var stage = this.el(this.stageId);
      if (stage) {
        while (stage.firstChild) stage.removeChild(stage.firstChild);
        var p = document.createElement('p');
        p.className = 'loading';
        p.textContent = 'Working… (first run loads the engine, ~30s)';
        stage.appendChild(p);
      }
    }
  };

  Drawer.prototype.collectInputs = function () {
    var out = {};
    var inputs = document.querySelectorAll('[data-arg]');
    Array.prototype.forEach.call(inputs, function (el) {
      var key = el.getAttribute('data-arg');
      var v = el.value;
      out[key] = (el.type === 'number') ? Number(v) : v;
    });
    return out;
  };

  Drawer.prototype.showError = function (msg) {
    // Drop any stale document so the filmstrip controls cannot page back into a
    // drawing that no longer matches the inputs.
    this.doc = { frames: [], error: msg };
    this.index = 0;
    this.bounds = null;
    var slider = this.el('seek');
    if (slider) { slider.max = '0'; slider.value = '0'; }
    var prev = this.el('prev'), next = this.el('next');
    if (prev) prev.disabled = true;
    if (next) next.disabled = true;
    setText(this.el('counter'), '');
    var stage = this.el(this.stageId);
    if (!stage) return;
    while (stage.firstChild) stage.removeChild(stage.firstChild);
    var p = document.createElement('p');
    p.className = 'error';
    p.textContent = msg;
    stage.appendChild(p);
  };

  Drawer.prototype.downloadSvg = function () {
    if (this.doc.frames.length === 0) return;
    var svg = buildSvg(this.doc.frames[this.index], this.bounds);
    var vb = svg.getAttribute('viewBox').split(' ').map(Number);
    svg.setAttribute('width', vb[2]); svg.setAttribute('height', vb[3]);
    svg.removeAttribute('preserveAspectRatio');
    var body = new XMLSerializer().serializeToString(svg);
    var blob = new Blob(['<?xml version="1.0" encoding="UTF-8"?>\n' + body], { type: 'image/svg+xml' });
    var url = URL.createObjectURL(blob);
    var a = document.createElement('a');
    a.href = url;
    a.download = (this.doc.kind || 'frame') + '-step-' + (this.index + 1) + '.svg';
    document.body.appendChild(a); a.click(); document.body.removeChild(a);
    setTimeout(function () { URL.revokeObjectURL(url); }, 0);
  };

  // --- Loading ----------------------------------------------------------
  // Precedence: ?src=<url> ; else the configured worker op via ?a=&b=... ;
  // else the embedded <script type="application/json" id="frames"> block.

  Drawer.prototype.load = function () {
    var self = this;
    var params = new URLSearchParams(window.location.search);
    var src = params.get('src');
    if (src) {
      self.setBusy(true);
      return fetchJson(src).then(function (d) {
        self.setBusy(false);
        self.ingest(d);
      }).catch(function (err) {
        self.setBusy(false);
        self.showError('Could not load ' + src + ': ' +
          (err && err.message ? err.message : err));
      });
    }
    var embedded = document.getElementById('frames');
    if (embedded) {
      try { self.ingest(JSON.parse(embedded.textContent)); return Promise.resolve(); }
      catch (e) { self.showError('Bad embedded #frames JSON: ' + e.message); return Promise.resolve(); }
    }
    self.showError('No ?src= and no embedded #frames block.');
    return Promise.resolve();
  };

  function fetchJson(url) {
    return fetch(url).then(function (resp) {
      if (!resp.ok) throw new Error('HTTP ' + resp.status);
      return resp.json();
    }).then(function (d) {
      if (d && typeof d === 'object' && (d.ok === false || d.error)) {
        throw new Error(d.error || 'engine error');
      }
      // The document carries `frames` and its own `result` answer string — do not
      // unwrap that. Only unwrap a genuine {result:<frames-document>} envelope.
      if (d && typeof d === 'object' && !Array.isArray(d.frames)
          && d.result && typeof d.result === 'object' && Array.isArray(d.result.frames)) {
        return d.result;
      }
      return d;
    });
  }

  // --- Small DOM helpers ------------------------------------------------

  function setText(el, str) { if (el) el.textContent = str; }
  function bind(el, ev, fn) { if (el) el.addEventListener(ev, fn); }
  function setView(view) {
    document.body.className = document.body.className
      .replace(/\bview-\w+\b/g, '').trim() + ' view-' + view;
    var toggles = document.querySelectorAll('[data-view]');
    Array.prototype.forEach.call(toggles, function (b) {
      b.classList.toggle('active', b.getAttribute('data-view') === view);
    });
  }
  function addKV(parent, key, val) {
    if (val === undefined || val === null || val === '') return;
    var row = document.createElement('div');
    row.className = 'kv';
    var k = document.createElement('span'); k.className = 'kv-key'; k.textContent = key;
    var v = document.createElement('span'); v.className = 'kv-val'; v.textContent = String(val);
    row.appendChild(k); row.appendChild(v); parent.appendChild(row);
  }
  function formatBreaksAt(breaks) {
    if (!Array.isArray(breaks)) return breaks;
    return breaks.map(function (b) {
      if (b && typeof b === 'object') return b.reason || b.inference || '';
      return b;
    }).filter(function (b) { return b !== undefined && b !== null && b !== ''; }).join(', ');
  }
  function textNode(tag, str, cls) {
    var e = document.createElement(tag);
    if (cls) e.className = cls;
    e.textContent = str;
    return e;
  }

  // --- Public API -------------------------------------------------------

  global.HermesDrawer = {
    create: function (opts) {
      var d = new Drawer(opts);
      document.addEventListener('DOMContentLoaded', function () {
        d.wire();
        if (opts && opts.defaultView) setView(opts.defaultView);
        else setView('freshman');
        d.load();
      });
      return d;
    },
    // Exposed for tests / reuse.
    _internal: {
      fillFor: fillFor, buildSvg: buildSvg, documentBounds: documentBounds,
      baseTenLayout: baseTenLayout, DISPATCH: DISPATCH,
      formatBreaksAt: formatBreaksAt
    }
  };

})(typeof window !== 'undefined' ? window : this);
