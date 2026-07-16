// src/render/svgRenderer.js
//
// SVG renderer ported from the original canvas drawBar/drawMat/refreshCanvas
// logic in fractionbarscanvas.js. The original used an immediate-mode canvas
// 2D context; here we rebuild the SVG tree deterministically on every render
// using createElementNS only (no innerHTML). Parity rules are preserved:
//  - base rect fill = bar.color
//  - each split: rect with fill split.color and a black stroke
//  - selected split: a 4x4 center marker rect
//  - selected bar/mat: outline stroke-width 2.5 (else 1)
//  - unit bar: "Unit Bar" caption below the bar
//  - fraction typeset at top-right (anchor end), label at bottom-left
//  - manual-split guide line drawn red when currentAction === 'manualSplit'
FB.Renderer = FB.Renderer || {};

(function () {
	var SVGNS = 'http://www.w3.org/2000/svg';

	FB.Renderer.create = function (svgRoot, doc) {
		var previewSpec = null;

		// Theme colors are read from CSS custom properties on the canvas each
		// render, so a skin swap (data-theme on <html>) instantly re-skins the
		// canvas marks too -- no per-theme renderer code, no inline styles. The
		// fallbacks ARE the original drab values, so an unstyled build is identical.
		var TH = {
			ink: '#000000', split: '#FF0000', guide: '#FF0000',
			halo: 'rgba(255,255,255,0.72)', font: 'Helvetica, Arial, sans-serif'
		};
		function readTheme() {
			try {
				var view = svgRoot && svgRoot.ownerDocument && svgRoot.ownerDocument.defaultView;
				if (!view || !view.getComputedStyle) { return; }
				var cs = view.getComputedStyle(svgRoot);
				function g(name, fb) { var v = cs.getPropertyValue(name); v = v && v.trim(); return v || fb; }
				TH.ink = g('--fb-ink', '#000000');
				TH.split = g('--fb-split-stroke', '#FF0000');
				TH.guide = g('--fb-guide', '#FF0000');
				TH.halo = g('--fb-label-halo', 'rgba(255,255,255,0.72)');
				TH.font = g('--fb-canvas-font', 'Helvetica, Arial, sans-serif');
			} catch (e) { /* keep defaults */ }
		}

		function elem(tag) {
			return doc.createElementNS(SVGNS, tag);
		}

		function rect(x, y, w, h, attrs) {
			var r = elem('rect');
			r.setAttribute('x', x);
			r.setAttribute('y', y);
			r.setAttribute('width', w);
			r.setAttribute('height', h);
			if (attrs) {
				for (var k in attrs) {
					if (Object.prototype.hasOwnProperty.call(attrs, k)) {
						r.setAttribute(k, attrs[k]);
					}
				}
			}
			return r;
		}

		function textNode(str, x, y, anchor) {
			var t = elem('text');
			t.setAttribute('x', x);
			t.setAttribute('y', y);
			t.setAttribute('fill', TH.ink);
			t.setAttribute('font-size', 12);
			t.setAttribute('font-family', TH.font);
			t.setAttribute('text-anchor', anchor === 'end' ? 'end' : 'start');
			t.textContent = String(str);
			return t;
		}

		// Translucent rounded "halo" drawn behind label / fraction text so it stays
		// legible over any bar fill or where bars overlap. Sized from the typeset
		// run's measured advance width (group.__fbWidth). Skipped when the active
		// theme sets --fb-label-halo to a fully transparent value.
		function haloFor(group, x, y, anchor, fs) {
			var w = group && group.__fbWidth ? group.__fbWidth : 0;
			if (!w) { return null; }
			var halo = TH.halo;
			if (!halo || halo === 'transparent' || /\b0\s*\)\s*$/.test(halo)) { return null; }
			var padX = fs * 0.4, padTop = fs * 1.02, padBot = fs * 0.5;
			var rx = (anchor === 'end') ? x - w - padX
				: (anchor === 'middle') ? x - w / 2 - padX : x - padX;
			return rect(rx, y - padTop, w + padX * 2, padTop + padBot, {
				fill: halo, stroke: 'none',
				rx: Math.max(2, fs * 0.3), ry: Math.max(2, fs * 0.3)
			});
		}

		// Place a typeset label/fraction (with halo) onto a layer.
		function placeLabel(layer, raw, x, y, anchor, fs, weight) {
			var grp = FB.Typeset.buildFractionSVG(doc, raw, {
				x: x, y: y, anchor: anchor, fontSize: fs,
				color: TH.ink, fontFamily: TH.font, fontWeight: weight || 'normal'
			});
			var h = haloFor(grp, x, y, anchor, fs);
			if (h) { layer.appendChild(h); }
			layer.appendChild(grp);
		}

		function renderMat(layer, m) {
			var g = elem('g');
			g.setAttribute('class', 'mat');
			g.appendChild(rect(m.x, m.y, m.w, m.h, {
				fill: m.color,
				stroke: TH.ink,
				'stroke-width': m.isSelected ? 2.5 : 1
			}));
			layer.appendChild(g);
		}

		function renderBar(layer, b) {
			var g = elem('g');
			g.setAttribute('class', 'bar');

			// base rect (fill only; the single black outline is drawn below, matching
			// the original drawBar which fillRect'd the base then strokeRect'd once).
			g.appendChild(rect(b.x, b.y, b.w, b.h, { fill: b.color, stroke: 'none' }));

			// splits -- the original drew split borders in red ('#FF0000').
			if (b.splits && b.splits.length > 0) {
				for (var i = 0; i < b.splits.length; i++) {
					var s = b.splits[i];
					g.appendChild(rect(b.x + s.x, b.y + s.y, s.w, s.h, {
						fill: s.color,
						stroke: TH.split,
						'stroke-width': 1
					}));
					if (s.isSelected === true) {
						// Selected-split marker: red, matching the original (which used
						// the prevailing red strokeStyle for the 4x4 center marker).
						var xcenter = s.x + (s.w / 2);
						var ycenter = s.y + (s.h / 2);
						g.appendChild(rect(b.x + xcenter - 2, b.y + ycenter - 2, 4, 4, {
							fill: 'none',
							stroke: TH.split,
							'stroke-width': 1
						}));
					}
				}
			}

			// selection outline (stroke-width 2.5 when selected else 1)
			g.appendChild(rect(b.x, b.y, b.w, b.h, {
				fill: 'none',
				stroke: TH.ink,
				'stroke-width': b.isSelected ? 2.5 : 1
			}));

			// unit bar caption below the bar
			if (b.isUnitBar) {
				placeLabel(g, 'Unit Bar', b.x, b.y + b.h + 15, 'start', 12, 'bold');
			}

			// fraction typeset at top-right (anchor end)
			if (b.fraction !== null && b.fraction !== undefined && String(b.fraction) !== '') {
				placeLabel(g, b.fraction, b.x + b.w - 5, b.y - 14, 'end', 13);
			}

			// label at bottom-left (typeset so mixed numbers / fractions render nicely)
			if (b.label !== null && b.label !== undefined && String(b.label) !== '') {
				placeLabel(g, b.label, b.x + 6, b.y + b.h - 6, 'start', 12);
			}

			layer.appendChild(g);
		}

		function hguide(x1, y1, x2, y2) {
			var line = elem('line');
			line.setAttribute('x1', x1);
			line.setAttribute('y1', y1);
			line.setAttribute('x2', x2);
			line.setAttribute('y2', y2);
			line.setAttribute('stroke', TH.guide);
			line.setAttribute('stroke-width', 1);
			return line;
		}

		// Hit-test helpers mirroring Bar.findSplitForPoint / findBarForPoint so the
		// overlay can reproduce the original drawBar manual-split guide.
		function barAt(bars, p) {
			for (var i = bars.length - 1; i >= 0; i--) {
				var b = bars[i];
				if (p.x > b.x && p.x < b.x + b.w && p.y > b.y && p.y < b.y + b.h) { return b; }
			}
			return null;
		}
		function splitAt(b, p) {
			if (!b || !b.splits) { return null; }
			for (var i = b.splits.length - 1; i >= 0; i--) {
				var s = b.splits[i];
				if (p.x > s.x + b.x && p.x < s.x + b.x + s.w &&
					p.y > s.y + b.y && p.y < s.y + b.y + s.h) { return s; }
			}
			return null;
		}

		function renderOverlay(layer, scene) {
			// rubber-band preview rect (from the scene, set during a bar/mat draw).
			var pv = scene.preview || previewSpec;
			if (pv && pv.type === 'rect') {
				layer.appendChild(rect(pv.x, pv.y, pv.w, pv.h, {
					fill: pv.fill || 'none',
					stroke: pv.stroke || '#000000',
					'stroke-width': 1
				}));
			}

			// manual-split red guide -- ported from the original drawBar logic: the
			// guide spans the full width/height of the bar (or split) under the
			// pointer, drawn only over a valid target. Direction follows the flag[1]
			// (two-way split enabled) + shift-key rule from the original.
			if (scene.currentAction === 'manualSplit' && scene.manualSplitPoint) {
				var p = scene.manualSplitPoint;
				var bars = scene.bars || [];
				var abar = barAt(bars, p);
				var asplit = abar ? splitAt(abar, p) : null;
				var thing = null, xoff = 0, yoff = 0;
				if (asplit) { thing = asplit; xoff = abar.x; yoff = abar.y; }
				else { thing = abar; }

				// split_key: original used flag[1] ? !shiftKeyDown : true
				var twoWay = !!(FB.Utilities && FB.Utilities.flag && FB.Utilities.flag[1]);
				var split_key = twoWay ? !scene.shiftDown : true;

				// Skip the ambiguous case the original guarded: pointer exactly
				// between existing splits of a bar that already has splits.
				var ambiguous = (asplit === null) && (abar !== null) && (abar.splits && abar.splits.length !== 0);
				if (thing !== null && !ambiguous) {
					if (!split_key) {
						// horizontal cut: full-width line at the pointer's y
						layer.appendChild(hguide(thing.x + xoff, p.y, thing.x + xoff + thing.w, p.y));
					} else {
						// vertical cut: full-height line at the pointer's x
						layer.appendChild(hguide(p.x, thing.y + yoff, p.x, thing.y + yoff + thing.h));
					}
				}
			}
		}

		function render(scene) {
			scene = scene || {};
			readTheme();
			var bars = scene.bars || [];
			var mats = scene.mats || [];

			svgRoot.replaceChildren();

			// mats first, then bars, then overlays
			var matLayer = elem('g');
			matLayer.setAttribute('class', 'mats');
			for (var mi = 0; mi < mats.length; mi++) {
				renderMat(matLayer, mats[mi]);
			}
			svgRoot.appendChild(matLayer);

			var barLayer = elem('g');
			barLayer.setAttribute('class', 'bars');
			for (var bi = 0; bi < bars.length; bi++) {
				renderBar(barLayer, bars[bi]);
			}
			svgRoot.appendChild(barLayer);

			var overlayLayer = elem('g');
			overlayLayer.setAttribute('class', 'overlay');
			renderOverlay(overlayLayer, scene);
			svgRoot.appendChild(overlayLayer);

			// Extension point: external layers (a Prolog reasoner drawing
			// constraint annotations, Lit-based custom-element overlays, etc.)
			// registered via FB.Hooks.registerOverlay are invoked here every
			// frame and (re)draw into the freshly rebuilt tree. See src/api/hooks.js.
			if (FB.Hooks && typeof FB.Hooks.runOverlays === 'function') {
				FB.Hooks.runOverlays({ svgRoot: svgRoot, scene: scene, doc: doc, ns: SVGNS });
			}
			if (FB.Hooks && typeof FB.Hooks.emit === 'function') {
				FB.Hooks.emit('render', scene);
			}

			return svgRoot.children.length;
		}

		function setPreview(spec) {
			previewSpec = spec || null;
		}

		return { render: render, setPreview: setPreview };
	};
})();
