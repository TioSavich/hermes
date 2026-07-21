// Copyright University of Massachusetts Dartmouth 2014
//
// Designed and built by James P. Burke and Jason Orrill
// Modified and developed by Hakan Sandir
//
// This Javascript version of Fraction Bars is based on
// the Transparent Media desktop version of Fraction Bars,
// which in turn was based on the original TIMA Bars software
// by John Olive and Leslie Steffe.
// We thank them for allowing us to update that product.

// FB.Pointer ports the original $('#fbCanvas').mousedown/mousemove/mouseup
// handlers (fractionbars.js) to unified Pointer Events so touch, mouse, and
// stylus all work. The original drew a live rubber-band rect onto a saved
// canvas snapshot; here the SVG renderer redraws the scene each move, and the
// in-progress drag rectangle is supplied to the scene via mouseDownLoc/
// mouseUpLoc + currentAction so the renderer can draw the preview.

FB.Pointer = FB.Pointer || {};

// Builds a clientToLocal(evt) -> {x,y} converter that maps client (screen)
// coordinates into the SVG viewBox space using the inverse screen CTM. Guarded
// so a missing getScreenCTM (e.g. in tests) degrades to raw offset coords.
FB.Pointer.makeClientToLocal = function (svgRoot) {
	return function clientToLocal(evt) {
		if (svgRoot && typeof svgRoot.getScreenCTM === 'function') {
			var ctm = svgRoot.getScreenCTM();
			if (ctm && typeof ctm.inverse === 'function') {
				// Prefer DOMPoint.matrixTransform when available.
				if (typeof svgRoot.createSVGPoint === 'function') {
					var pt = svgRoot.createSVGPoint();
					pt.x = evt.clientX;
					pt.y = evt.clientY;
					var local = pt.matrixTransform(ctm.inverse());
					return { x: local.x, y: local.y };
				}
				var inv = ctm.inverse();
				return {
					x: inv.a * evt.clientX + inv.c * evt.clientY + inv.e,
					y: inv.b * evt.clientX + inv.d * evt.clientY + inv.f
				};
			}
		}
		// Fallback: use offset/page coords relative to the element's bounds.
		var rect = (svgRoot && typeof svgRoot.getBoundingClientRect === 'function')
			? svgRoot.getBoundingClientRect()
			: { left: 0, top: 0 };
		return { x: (evt.clientX || 0) - rect.left, y: (evt.clientY || 0) - rect.top };
	};
};

// Produces an FB.Point from a local {x,y}.
FB.Pointer.pointFromLocal = function (loc) {
	return FB.Point.fromCoords(loc.x, loc.y);
};

// Reproduces the original mousedown handler. `loc` is the localized {x,y}.
// `shiftDown` honors `Utilities.shiftKeyDown || FB.Toolbar.selectionMode`.
FB.Pointer.handleDown = function (controller, loc, shiftDown) {
	var state = controller.state;

	controller.check_for_drag = true;
	controller.cacheUndoState();

	state.mouseDownLoc = FB.Pointer.pointFromLocal(loc);
	state.mouseLastLoc = null;

	var b = controller.barClickedOn();
	var m = controller.matClickedOn();

	var action = state.currentAction;

	if (action === 'bar' || action === 'mat') {
		// The original snapshotted the canvas (saveCanvas) so the rubber-band
		// rect could be drawn over it. With SVG we just keep mouseDownLoc set;
		// the renderer reads currentAction + mouseDownLoc/mouseUpLoc to draw the
		// preview rect during move. Nothing else to do on down.
		return;
	}

	if (action === 'repeat') {
		controller.addUndoState();
		if (b !== null) {
			b.repeat(state.mouseDownLoc);
		}
		controller.refresh();
		return;
	}

	// The click is being used to update the selected bars.
	if (b !== null) {
		if (FB.Pointer.indexOf(state.selectedBars, b) === -1) {
			// clicked-on bar is not already selected
			if (!shiftDown) {
				controller.clearSelection();
			}
			for (var i = 0; i < state.selectedBars.length; i++) {
				state.selectedBars[i].clearSplitSelection();
			}
			controller.barToFront(b);
			state.selectedBars.push(b);
			b.isSelected = true;
			b.selectSplit(state.mouseDownLoc);
		} else {
			// clicked bar is already selected
			for (var j = 0; j < state.selectedBars.length; j++) {
				state.selectedBars[j].clearSplitSelection();
			}
			if (!shiftDown) {
				b.selectSplit(state.mouseDownLoc);
			} else {
				controller.removeBarFromSelection(b);
			}
			controller.barToFront(b);
		}
		if (action === 'manualSplit') {
			controller.clearSelection();
		}
	} else if (m !== null) {
		if (FB.Pointer.indexOf(state.selectedMats, m) === -1) {
			// clicked-on mat is not already selected
			if (!shiftDown) {
				controller.clearSelection();
			}
			m.isSelected = true;
			state.selectedMats.push(m);
		} else {
			// clicked-on mat is already selected
			if (shiftDown) {
				controller.removeMatFromSelection(m);
			}
		}
	} else {
		controller.clearSelection();
	}
	controller.refresh();
};

// Reproduces the original mousemove handler body.
FB.Pointer.handleMove = function (controller, loc) {
	var state = controller.state;
	var p = FB.Pointer.pointFromLocal(loc);

	if (state.currentAction === 'manualSplit') {
		state.manualSplitPoint = p;
		controller.refresh();
	}

	if (state.mouseDownLoc !== null) {
		FB.Pointer.updateCanvas(controller, p);
	}
};

// Ports FractionBarsCanvas.updateCanvas: while a bar/mat is being drawn, track
// the current corner (mouseUpLoc) so the renderer draws the preview rect; while
// in manualSplit, track the split point; otherwise drag the selection.
FB.Pointer.updateCanvas = function (controller, currentLoc) {
	var state = controller.state;
	if (state.currentAction === 'bar' || state.currentAction === 'mat') {
		state.mouseUpLoc = currentLoc;
		controller.refresh();
	} else if (state.currentAction === 'manualSplit') {
		state.manualSplitPoint = currentLoc;
		controller.refresh();
	} else {
		controller.drag(currentLoc);
	}
};

// Reproduces the original mouseup handler body.
FB.Pointer.handleUp = function (controller, loc) {
	var state = controller.state;
	state.mouseUpLoc = FB.Pointer.pointFromLocal(loc);

	if (state.currentAction === 'bar' || state.currentAction === 'mat') {
		// Ignore degenerate "draws" -- a tap with little or no drag. On touch
		// devices a stray tap in Bar/Mat mode otherwise created an invisible
		// zero-size object that clutters the model and exports.
		var MIN_DRAW = 4;
		var d = state.mouseDownLoc, u = state.mouseUpLoc;
		var big = d && u && (Math.abs(u.x - d.x) >= MIN_DRAW || Math.abs(u.y - d.y) >= MIN_DRAW);
		if (big) {
			controller.addUndoState();
			if (state.currentAction === 'bar') { controller.addBar(); } else { controller.addMat(); }
		}
		FB.Toolbar.clearSelectionButton(controller);
	}

	if (controller.found_a_drag) {
		controller.finalizeCachedUndoState();
		controller.check_for_drag = false;
	}

	state.mouseUpLoc = null;
	state.mouseDownLoc = null;
	state.mouseLastLoc = null;

	controller.refresh();
};

// Plain replacement for the legacy $.inArray helper.
FB.Pointer.indexOf = function (arr, item) {
	for (var i = 0; i < arr.length; i++) {
		if (arr[i] === item) { return i; }
	}
	return -1;
};

// Attaches Pointer Event listeners to the SVG root. Uses setPointerCapture so
// drags continue when the pointer leaves the element. `opts.clientToLocal` may
// override the default CTM-based converter.
FB.Pointer.attach = function (svgRoot, controller, opts) {
	opts = opts || {};
	var clientToLocal = opts.clientToLocal || FB.Pointer.makeClientToLocal(svgRoot);
	var activePointerId = null;

	function shiftActive() {
		return (FB.Utilities.shiftKeyDown === true) ||
			(FB.Toolbar && FB.Toolbar.selectionMode === true);
	}

	function onDown(e) {
		if (activePointerId !== null) { return; }
		activePointerId = (e.pointerId !== undefined ? e.pointerId : 0);
		if (svgRoot.setPointerCapture && e.pointerId !== undefined) {
			try { svgRoot.setPointerCapture(e.pointerId); } catch (err) { /* ignore */ }
		}
		if (typeof e.preventDefault === 'function') { e.preventDefault(); }
		FB.Pointer.handleDown(controller, clientToLocal(e), shiftActive());
	}

	function onMove(e) {
		// Only react while a gesture is in progress (mouseDownLoc set), or when
		// manualSplit needs the live preview (original moved on every mousemove).
		if (activePointerId !== null && e.pointerId !== undefined &&
			e.pointerId !== activePointerId) { return; }
		FB.Pointer.handleMove(controller, clientToLocal(e));
	}

	function onUp(e) {
		if (activePointerId !== null && e.pointerId !== undefined &&
			e.pointerId !== activePointerId) { return; }
		if (svgRoot.releasePointerCapture && e.pointerId !== undefined) {
			try { svgRoot.releasePointerCapture(e.pointerId); } catch (err) { /* ignore */ }
		}
		activePointerId = null;
		FB.Pointer.handleUp(controller, clientToLocal(e));
	}

	svgRoot.addEventListener('pointerdown', onDown);
	svgRoot.addEventListener('pointermove', onMove);
	svgRoot.addEventListener('pointerup', onUp);
	svgRoot.addEventListener('pointercancel', onUp);

	return function detach() {
		svgRoot.removeEventListener('pointerdown', onDown);
		svgRoot.removeEventListener('pointermove', onMove);
		svgRoot.removeEventListener('pointerup', onUp);
		svgRoot.removeEventListener('pointercancel', onUp);
	};
};
