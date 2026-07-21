// src/api/hooks.js
//
// Extension hooks for the Fraction Bars canvas. This is the seam that lets
// future work bolt reasoning + reactive UI onto the manipulative WITHOUT
// touching the sealed core or breaking the CSP (no eval, no network, no
// innerHTML -- everything here is plain function registration + data export).
//
// Two audiences:
//
//   * PROLOG  -- a logic engine that wants the scene as facts it can query
//     ("is this set of bars a valid partition of the unit?", "which bars are
//     equivalent fractions?"). FB.Hooks.toProlog(scene) emits ground facts;
//     FB.Hooks.toFacts(scene) returns the same as structured objects. Register
//     FB.Hooks.on('render', cb) to recompute facts whenever the model changes.
//
//   * LIT (or any web-component / custom-element layer) -- reactive overlays
//     drawn on top of the bars (handles, hints, annotations). Register with
//     FB.Hooks.registerOverlay(fn); fn is called on every render with
//     { svgRoot, scene, doc, ns } and should (re)draw its own <g> (the SVG tree
//     is rebuilt each frame, so overlays are idempotent redraws, not one-time
//     mounts). A Lit ReactiveController can mirror this: subscribe to 'render',
//     read toFacts(scene), and update its host element positioned over .fb-stage.
//
// Nothing here is wired to a concrete engine yet -- it is the stable contract
// those engines attach to.

FB.Hooks = FB.Hooks || (function () {
	var listeners = {};   // event name -> [fn]
	var overlays = [];    // [fn({svgRoot,scene,doc,ns})]

	function on(name, fn) {
		if (typeof fn !== 'function') { return function () {}; }
		(listeners[name] || (listeners[name] = [])).push(fn);
		return function off() {
			var a = listeners[name] || [];
			var i = a.indexOf(fn);
			if (i > -1) { a.splice(i, 1); }
		};
	}

	function emit(name, payload) {
		var a = listeners[name];
		if (!a) { return; }
		for (var i = 0; i < a.length; i++) {
			try { a[i](payload); } catch (e) { /* a bad hook must never break the app */ }
		}
	}

	function registerOverlay(fn) {
		if (typeof fn !== 'function') { return function () {}; }
		overlays.push(fn);
		return function remove() {
			var i = overlays.indexOf(fn);
			if (i > -1) { overlays.splice(i, 1); }
		};
	}

	function runOverlays(ctx) {
		for (var i = 0; i < overlays.length; i++) {
			try { overlays[i](ctx); } catch (e) { /* isolate overlay errors */ }
		}
	}

	// ---- Prolog fact export --------------------------------------------------
	// Quote an atom for Prolog: lowercase atoms pass bare, anything else is
	// single-quoted with embedded quotes doubled.
	function atom(s) {
		s = String(s == null ? '' : s);
		if (/^[a-z][a-zA-Z0-9_]*$/.test(s)) { return s; }
		return "'" + s.replace(/\\/g, '\\\\').replace(/'/g, "\\'") + "'";
	}
	function num(n) { return String(Math.round(Number(n) || 0)); }
	function int(n) { return Math.round(Number(n) || 0); }

	function parseFrac(f) {
		var m = /^(\d+)\/(\d+)$/.exec(String(f || '').trim());
		return m ? { num: +m[1], den: +m[2] } : null;
	}

	// Structured facts (objects) -- convenient for JS consumers / Lit.
	function toFacts(scene) {
		scene = scene || {};
		var bars = scene.bars || [];
		var facts = [];
		for (var i = 0; i < bars.length; i++) {
			var b = bars[i];
			var id = 'b' + i;
			facts.push({ pred: 'bar', args: [id, int(b.x), int(b.y), int(b.w), int(b.h)] });
			if (b.isUnitBar) { facts.push({ pred: 'unit_bar', args: [id] }); }
			var fr = parseFrac(b.fraction);
			if (fr) { facts.push({ pred: 'fraction', args: [id, fr.num, fr.den] }); }
			if (b.label) { facts.push({ pred: 'label', args: [id, b.label] }); }
			var splits = b.splits || [];
			for (var s = 0; s < splits.length; s++) {
				facts.push({ pred: 'part', args: [id, s, int(splits[s].x), int(splits[s].w)] });
			}
			if (splits.length) { facts.push({ pred: 'parts_count', args: [id, splits.length] }); }
		}
		return facts;
	}

	// Ground Prolog program text, one fact per line.
	function toProlog(scene) {
		return toFacts(scene).map(function (f) {
			var args = f.args.map(function (a) {
				return (typeof a === 'number') ? String(a) : atom(a);
			});
			return f.pred + '(' + args.join(', ') + ').';
		}).join('\n');
	}

	return {
		on: on, emit: emit,
		registerOverlay: registerOverlay, runOverlays: runOverlays,
		toFacts: toFacts, toProlog: toProlog
	};
})();
