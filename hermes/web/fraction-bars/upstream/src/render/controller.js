// Copyright University of Massachusetts Dartmouth 2013
//
// Designed and built by James P. Burke and Jason Orrill
// Modified and developed by Hakan Sandir
//
// This Javascript version of Fraction Bars is based on
// the Transparent Media desktop version of Fraction Bars,
// which in turn was based on the original TIMA Bars software
// by John Olive and Leslie Steffe.
// We thank them for allowing us to update that product.

// FB.Controller ports the model-orchestration logic of the original
// FractionBarsCanvas (FractionBarsCanvas.js). Drawing methods are NOT ported
// here -- the SVG renderer (FB.Renderer) owns rendering. The legacy DOM helpers
// ($.inArray / $.each) are replaced with plain JS; alert(...) is replaced with an injected
// notify(msg) callback; refreshCanvas() becomes renderer.render(getScene()).

FB.Controller = FB.Controller || {};

FB.Controller.create = function (deps) {
	deps = deps || {};
	var renderer = deps.renderer || { render: function () {} };
	var notify = deps.notify || function () {};
	var getMarkedIterate = deps.getMarkedIterate || function () { return false; };

	var controller = {};

	// The controller's mutable model state. CanvasState reads bars/mats/unitBar
	// and the per-item isSelected flags off whatever object it is constructed
	// with, so the state object below is what we hand to `new FB.CanvasState`.
	var state = {
		bars: [],
		mats: [],
		selectedBars: [],
		selectedMats: [],
		lastSelectedBars: [],
		lastSelectedMats: [],
		unitBar: null,
		currentAction: '',
		currentFill: '#FFFF66',
		matFill: '#888888',
		mouseDownLoc: null,
		mouseUpLoc: null,
		mouseLastLoc: null,
		manualSplitPoint: null
	};
	controller.state = state;

	// Undo / redo stacks and drag-detection bookkeeping (ported verbatim).
	var mUndoArray = [];
	var mRedoArray = [];
	controller.mUndoArray = mUndoArray;
	controller.mRedoArray = mRedoArray;
	controller.CachedState = null;
	controller.check_for_drag = false; // store an undo state before a drag,
	controller.found_a_drag = false;   // and register it once we know it happened

	controller.getScene = function () {
		var scene = {
			bars: state.bars,
			mats: state.mats,
			currentAction: state.currentAction,
			manualSplitPoint: state.manualSplitPoint,
			shiftDown: FB.Utilities.shiftKeyDown === true,
			preview: null
		};
		// While drawing a bar/mat, expose a rubber-band preview rect so the
		// renderer can draw it (replacing the original canvas snapshot trick).
		if ((state.currentAction === 'bar' || state.currentAction === 'mat') &&
			state.mouseDownLoc && state.mouseUpLoc) {
			var p1 = state.mouseDownLoc, p2 = state.mouseUpLoc;
			scene.preview = {
				type: 'rect',
				x: Math.min(p1.x, p2.x),
				y: Math.min(p1.y, p2.y),
				w: Math.abs(p2.x - p1.x),
				h: Math.abs(p2.y - p1.y),
				fill: state.currentAction === 'mat' ? state.matFill : state.currentFill,
				stroke: '#000000'
			};
		}
		return scene;
	};

	// Change listeners: external consumers (e.g. the State API / Hermes bridge)
	// can register callbacks fired whenever the model is mutated/refreshed.
	var changeListeners = [];
	controller.onMutate = function (cb) {
		if (typeof cb === 'function') { changeListeners.push(cb); }
	};
	controller.notifyChange = function () {
		for (var i = 0; i < changeListeners.length; i++) {
			try { changeListeners[i](); } catch (e) { /* listener errors must not break the app */ }
		}
	};

	controller.refresh = function () {
		renderer.render(controller.getScene());
		controller.notifyChange();
	};

	// ----- Bar / Mat creation ------------------------------------------------

	controller.addBar = function (a_bar) {
		var b = null;
		if (a_bar === null || a_bar === undefined) {
			b = FB.Bar.createFromMouse(state.mouseDownLoc, state.mouseUpLoc, 'bar', state.currentFill);
		} else {
			b = a_bar;
		}

		state.bars.push(b);
		controller.clearSelection();
		controller.updateSelectionFromState();
		controller.refresh();
	};

	controller.addMat = function () {
		var m = FB.Mat.createFromMouse(state.mouseDownLoc, state.mouseUpLoc, 'mat', state.matFill);
		state.mats.push(m);
		controller.refresh();
	};

	// Also copy mats
	controller.copyBars = function () {
		if (state.selectedBars.length > 0) {
			for (var i = state.selectedBars.length - 1; i >= 0; i--) {
				state.bars.push(state.selectedBars[i].copy(true));
				state.selectedBars[i].isSelected = false;
			}
		}
		if (state.selectedMats.length > 0) {
			for (var j = state.selectedMats.length - 1; j >= 0; j--) {
				state.mats.push(state.selectedMats[j].copy(true));
				state.selectedMats[j].isSelected = false;
			}
		}
		controller.updateSelectionFromState();
	};

	controller.breakApartBars = function () {
		var newBars;
		if (state.selectedBars.length > 0) {
			for (var i = 0; i < state.selectedBars.length; i++) {
				newBars = state.selectedBars[i].breakApart();
				for (var j = 0; j < newBars.length; j++) {
					state.bars.push(newBars[j]);
				}
			}

			// all splits in bars copied...delete the original selection
			controller.deleteSelectedBars();
		}
	};

	controller.pullOutSplit = function () {
		var sel_split = null;

		for (var i = 0; i < state.selectedBars.length; i++) {
			if (state.selectedBars[i].selectedSplit !== null) {
				sel_split = state.selectedBars[i].selectedSplit;
				var newbar = FB.Bar.createFromSplit(sel_split, state.selectedBars[i].x, state.selectedBars[i].y);
				controller.addBar(newbar);
			}
		}
	};

	controller.clearSplits = function () {
		if (state.selectedBars.length > 0) {
			for (var i = 0; i < state.selectedBars.length; i++) {
				state.selectedBars[i].clearSplits();
			}
		}
	};

	// ----- Splits / iterate / make -------------------------------------------

	controller.makeSplits = function (num_splits, vert_horiz, whole_part) {
		var vert_truth = (vert_horiz === "Vertical");
		if (state.selectedBars.length > 0) {
			if (whole_part === "Whole") {
				for (var i = 0; i < state.selectedBars.length; i++) {
					var this_bar = state.selectedBars[i];
					this_bar.wholeBarSplits(num_splits, vert_truth);
				}
			} else {
				if ((state.selectedBars[0].splits.length === 0) || (state.selectedBars[0].selectedSplit === null)) {
					// No splits, or no selected split, so treat this like a whole bar split
					state.selectedBars[0].wholeBarSplits(num_splits, vert_truth);
				} else {
					state.selectedBars[0].splitSelectedSplit(num_splits, vert_truth);
				}
			}
			controller.refresh();
		}
	};

	controller.makeIterations = function (num_iterations, vert_horiz) {
		var vert_truth = (vert_horiz === "Vertical");
		if (state.selectedBars.length > 0) {

			if (!FB.Utilities.flag[0]) { controller.copyBars(); }

			state.selectedBars[0].iterate(num_iterations, vert_truth);

			controller.refresh();
		}
	};

	controller.makeMake = function (num_frac) {
		// Only build a bar for a finite, positive fraction. Guards against a
		// negative whole-number entry (which produced a negative-width rect) and
		// NaN/0 inputs.
		if (!(typeof num_frac === 'number' && isFinite(num_frac) && num_frac > 0)) { return; }
		if (state.selectedBars.length > 0) {
			state.bars.push(state.selectedBars[0].makeNewCopy(num_frac));
			controller.refresh();
		}
	};

	// ----- Measurement / unit bar --------------------------------------------

	controller.measureBars = function () {
		if (state.selectedBars.length === 0) { return; }
		// Guard: measuring requires a unit bar. Without this the original threw a
		// TypeError on this.unitBar.size and left the app wedged -- a common path
		// for a learner who taps Measure before Set Unit Bar.
		if (!state.unitBar || !(state.unitBar.size > 0)) {
			notify(FB.I18N && FB.I18N.t ? FB.I18N.t('measure_no_unit') : 'Set a unit bar first.');
			return;
		}
		for (var i = state.selectedBars.length - 1; i >= 0; i--) {
			state.selectedBars[i].fraction = FB.Utilities.createFraction(state.selectedBars[i].size, state.unitBar.size);
		}
	};

	controller.clearAllMeasurements = function () {
		for (var i = 0; i < state.bars.length; i++) {
			state.bars[i].isUnitBar = false;
			state.bars[i].fraction = '';
		}
	};

	controller.setUnitBar = function () {
		controller.clearAllMeasurements();
		if (state.selectedBars.length == 1) {
			state.selectedBars[0].isUnitBar = true;
			state.selectedBars[0].fraction = '';
			state.unitBar = state.selectedBars[0];
		}
	};

	controller.saveLabel = function (labelText, selectionType) {
		var barSelection = [];
		if (selectionType == FB.Utilities.USE_CURRENT_SELECTION) {
			barSelection = state.selectedBars;
		} else {
			barSelection = state.lastSelectedBars;
		}

		if (barSelection.length == 1) {
			barSelection[0].label = labelText;
		}
		state.lastSelectedBars = [];
		controller.refresh();
	};

	// Deletes both bars and mats that are selected
	controller.deleteSelectedBars = function () {
		var newBars = [];
		var unitBarDeleted = false;

		for (var i = 0; i < state.bars.length; i++) {
			if (!state.bars[i].isSelected) {
				newBars.push(state.bars[i]);
			} else {
				if (state.bars[i].isUnitBar) {
					unitBarDeleted = true;
				}
			}
		}
		state.bars = newBars;
		if (unitBarDeleted) {
			controller.clearAllMeasurements();
		}
		var newMats = [];
		for (i = 0; i < state.mats.length; i++) {
			if (!state.mats[i].isSelected) {
				newMats.push(state.mats[i]);
			}
		}
		state.mats = newMats;
	};

	// ----- Selection ---------------------------------------------------------

	// Works on bars and mats together
	controller.updateSelectionFromState = function () {
		state.selectedBars = [];
		for (var i = 0; i < state.bars.length; i++) {
			if (state.bars[i].isSelected) {
				state.selectedBars.push(state.bars[i]);
			}
		}
		state.selectedMats = [];
		for (i = 0; i < state.mats.length; i++) {
			if (state.mats[i].isSelected) {
				state.selectedMats.push(state.mats[i]);
			}
		}
	};

	controller.findBarForPoint = function (p) {
		for (var i = state.bars.length - 1; i >= 0; i--) {
			if (p.x > state.bars[i].x &&
				p.x < state.bars[i].x + state.bars[i].w &&
				p.y > state.bars[i].y &&
				p.y < state.bars[i].y + state.bars[i].h) {

				return (state.bars[i]);
			}
		}
		return null;
	};

	controller.findSplitForPoint = function (p) {
		var the_bar = controller.findBarForPoint(p);
		if (the_bar !== null) {
			return (the_bar.findSplitForPoint(p));
		} else {
			return (null);
		}
	};

	controller.findSomethingForPoint = function (p) {
		// Returns either a bar or a split that matches the point. Or null if no match.
		var the_bar = controller.findBarForPoint(p);
		if (the_bar !== null) {
			var the_split = the_bar.findSplitForPoint(p);
			if (the_split !== null) {
				return (the_split);
			} else {
				return (the_bar);
			}
		} else {
			return (null);
		}
	};

	controller.barClickedOn = function () {
		var split_key;
		for (var i = state.bars.length - 1; i >= 0; i--) {
			if (state.mouseDownLoc.x > state.bars[i].x &&
				state.mouseDownLoc.x < state.bars[i].x + state.bars[i].w &&
				state.mouseDownLoc.y > state.bars[i].y &&
				state.mouseDownLoc.y < state.bars[i].y + state.bars[i].h)
			{
				if (state.currentAction == "manualSplit") {
					controller.addUndoState();
					if (FB.Utilities.flag[1]) {
						split_key = FB.Utilities.shiftKeyDown;
					} else {
						split_key = false;
					}

					state.bars[i].splitBarAtPoint(state.mouseDownLoc, split_key);

				} else {
					state.bars[i].selectSplit(state.mouseDownLoc);
				}
				return state.bars[i];
			}
		}
		return null;
	};

	controller.barToFront = function (bar) {
		var new_list = [];

		for (var i = 0; i < state.bars.length; i++) {
			if (bar !== state.bars[i]) {
				new_list.push(state.bars[i]);
			}
		}
		new_list.push(bar);
		state.bars = new_list;
	};

	controller.matClickedOn = function () {
		for (var i = state.mats.length - 1; i >= 0; i--) {
			if (state.mouseDownLoc.x > state.mats[i].x &&
				state.mouseDownLoc.x < state.mats[i].x + state.mats[i].w &&
				state.mouseDownLoc.y > state.mats[i].y &&
				state.mouseDownLoc.y < state.mats[i].y + state.mats[i].h)
			{
				return state.mats[i];
			}
		}
		return null;
	};

	// Clear for bars and mats
	controller.clearSelection = function () {
		for (var i = 0; i < state.bars.length; i++) {
			state.bars[i].isSelected = false;
			state.bars[i].clearSplitSelection();
		}
		state.lastSelectedBars = state.selectedBars;
		state.selectedBars = [];

		for (var j = 0; j < state.mats.length; j++) {
			state.mats[j].isSelected = false;
		}
		state.lastSelectedMats = state.selectedMats;
		state.selectedMats = [];
	};

	// Clear for bars and mats
	controller.removeBarFromSelection = function (bar) {
		var new_list = [];

		for (var i = 0; i < state.selectedBars.length; i++) {
			if (bar !== state.selectedBars[i]) {
				new_list.push(state.selectedBars[i]);
			}
		}

		state.selectedBars = new_list;
		bar.isSelected = false;
		bar.clearSplitSelection();
	};

	controller.removeMatFromSelection = function (mat) {
		var new_list = [];

		for (var i = 0; i < state.selectedMats.length; i++) {
			if (mat !== state.selectedMats[i]) {
				new_list.push(state.selectedMats[i]);
			}
		}

		state.selectedMats = new_list;
		mat.isSelected = false;
	};

	// ----- Join --------------------------------------------------------------

	controller.joinSelected = function () {
		// TODO: bulletproof this
		// TODO: update this to allow for more than two bars to be joined.
		if ((state.selectedBars.length > 2) || (state.selectedBars.length === 1) || (state.selectedMats.length > 0)) {
			if (FB.Utilities.flag[3]) {
				notify("Birleştirme işlemi yapabilmek için lütfen iki kesir şeridi seçiniz.");
			} else {
				notify("Please select exactly two bars (and no mats) before attempting to Join.");
			}
			return;
		}
		var success = state.selectedBars[0].join(state.selectedBars[1]);

		if (success) {
			state.selectedBars[0].isSelected = false;
			controller.deleteSelectedBars();
			controller.updateSelectionFromState();
		}
	};

	// ----- Repeat tool -------------------------------------------------------

	controller.setupBarRepeats = function () {
		// For every bar, just set its repeatUnit. So that Repeat can work correctly.
		for (var i = state.bars.length - 1; i >= 0; i--) {
			state.bars[i].setRepeatUnit();
		}
	};

	controller.unsetBarRepeats = function () {
		for (var i = state.bars.length - 1; i >= 0; i--) {
			state.bars[i].repeatUnit = null;
		}
	};

	controller.handleToolUpdate = function (tool_name, tool_on) {
		// This is the Canvas' chance to do something when a tool switched on or off.
		// We are given the name of the tool, and a Boolean value of whether it was turned on or off.
		switch (tool_name) {
			case 'repeat':
				FB.repeatModeActive = !!tool_on;
				if (tool_on) {
					controller.setupBarRepeats();
				} else {
					controller.unsetBarRepeats();
				}
		}
	};

	// ----- Colors / drag -----------------------------------------------------

	controller.setFillColor = function (fillColor) {
		state.currentFill = fillColor;
	};

	controller.updateColorsOfSelectedBars = function () {
		var i;
		if (state.selectedBars.length > 0) {
			controller.addUndoState();
		}
		for (i = 0; i < state.selectedBars.length; i++) {
			if (state.selectedBars[i].hasSelectedSplit()) {
				state.selectedBars[i].updateColorOfSelectedSplit(state.currentFill);
			} else {
				state.selectedBars[i].color = state.currentFill;
			}
		}
		controller.refresh();
	};

	controller.drag = function (currentLoc) {
		if (state.mouseLastLoc === null || typeof (state.mouseLastLoc) == 'undefined') {
			state.mouseLastLoc = state.mouseDownLoc;
		}

		for (var i = 0; i < state.selectedBars.length; i++) {
			state.selectedBars[i].x = state.selectedBars[i].x + currentLoc.x - state.mouseLastLoc.x;
			state.selectedBars[i].y = state.selectedBars[i].y + currentLoc.y - state.mouseLastLoc.y;
		}

		for (i = 0; i < state.selectedMats.length; i++) {
			state.selectedMats[i].x = state.selectedMats[i].x + currentLoc.x - state.mouseLastLoc.x;
			state.selectedMats[i].y = state.selectedMats[i].y + currentLoc.y - state.mouseLastLoc.y;
		}

		if (controller.check_for_drag) {
			controller.found_a_drag = true;
			controller.check_for_drag = false;
		}

		state.mouseLastLoc = currentLoc;

		controller.refresh();
	};

	// ----- Undo / redo -------------------------------------------------------

	controller.addUndoState = function () {
		var newstate = new FB.CanvasState(state);
		newstate.grabBarsAndMats();
		mUndoArray.push(newstate);  // Push new state onto the stack

		while (mUndoArray.length > 100) {
			mUndoArray.shift();  // Shift states off the bottom of the undo stack
		}

		mRedoArray.length = 0; // When an undoable event happens, it clears the redo stack.
	};

	controller.cacheUndoState = function () {
		controller.CachedState = new FB.CanvasState(state);
		controller.CachedState.grabBarsAndMats();
	};

	controller.finalizeCachedUndoState = function () {
		if (controller.CachedState !== null) {
			mUndoArray.push(controller.CachedState);  // Push new state onto the stack

			while (mUndoArray.length > 100) {
				mUndoArray.shift();  // Shift states off the bottom of the undo stack
			}

			mRedoArray.length = 0; // When an undoable event happens, it clears the redo stack.
		}

		controller.check_for_drag = false;
		controller.found_a_drag = false;
	};

	controller.undo = function () {
		// Store current state in Redo stack
		// Pop an undo state off the stack
		// Restore undo state
		if (mUndoArray.length > 0) {

			var newstate = new FB.CanvasState(state);
			newstate.grabBarsAndMats();
			mRedoArray.push(newstate);  // Push new state onto the stack

			controller.restoreAState(mUndoArray.pop());
		}
	};

	controller.redo = function () {
		if (mRedoArray.length > 0) {

			var newstate = new FB.CanvasState(state);
			newstate.grabBarsAndMats();
			mUndoArray.push(newstate);  // Push new state onto the stack

			controller.restoreAState(mRedoArray.pop());
		}
	};

	controller.restoreAState = function (a_new_state) {
		// clear the bars and mats
		// copy bars and mats from the new state
		// set the unit bar, if any.
		var temp_bar;

		state.bars = [];
		state.mats = [];
		state.selectedBars = [];
		state.selectedMats = [];

		while (a_new_state.mBars.length > 0) {
			temp_bar = a_new_state.mBars.shift();
			state.bars.push(temp_bar);
		}

		while (a_new_state.mMats.length > 0) {
			state.mats.push(a_new_state.mMats.shift());
		}

		state.unitBar = a_new_state.mUnitBar;
		if (state.unitBar !== null) {
			state.unitBar.isUnitBar = true;
			state.unitBar.fraction = '1/1';
		}
		controller.clearSelection();
	};

	return controller;
};
