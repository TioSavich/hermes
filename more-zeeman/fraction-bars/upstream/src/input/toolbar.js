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

// FB.Toolbar ports the original `$('a').click` dispatch switch and the
// `.colorBlock` / `.colorBlock1` handlers from fractionbars.js. The original
// coupled tool/action/window routing into one delegated click handler; this module
// exposes a pure `dispatch(controller, id, opts)` (so it is unit-testable
// without a DOM) plus a thin `bind(rootEl, controller, opts)` that wires
// click/pointerup listeners on the toolbar to `dispatch`.

FB.Toolbar = FB.Toolbar || {};

// When true, touch "add to selection" toggle stands in for the shift key in the
// original mousedown selection branch (replaces Utilities.shiftKeyDown). The
// pointer layer reads `shiftDown || FB.Toolbar.selectionMode`.
FB.Toolbar.selectionMode = false;

// UI hooks for the things the original delegated to dialogs / chrome (label
// editor, splits/iterate/make/properties dialogs, file open/save, print, hide).
// Task 11 (FB.Dialogs) installs these. Each is optional and called only if set.
FB.Toolbar.ui = {
	editLabel: null,        // window_label
	openSplits: null,       // window_split
	openIterate: null,      // window_iterate
	openProperties: null,   // window_properties
	openMake: null,         // action_make (Make dialog before makeMake)
	save: null,             // action_save
	open: null,             // action_open
	print: null,            // action_print
	clearAll: null,         // action_clearAll
	showAll: null,          // action_show
	previous: null,         // action_previous
	next: null,             // action_next
	hideButton: null,       // hide mode: hide the clicked element (id)
	onHideMode: null,       // hide mode entered/exited (active:boolean)
	onHideChanged: null,    // a tool was hidden / shown (refresh banner + Show All)
	setToolSelected: null,  // mark a tool element selected (id, on)
	setColorSelected: null  // mark a color swatch selected
};

// Routes a clicked element id through the original switch. `id` is the element's
// id attribute (e.g. 'tool_bar', 'action_copy', 'window_split'). Returns true if
// the id was handled.
FB.Toolbar.dispatch = function (controller, id, opts) {
	if (id === null || id === undefined) { return false; }
	opts = opts || {};
	var ui = FB.Toolbar.ui;
	var state = controller.state;

	// First, handle hide-mode: if a tool is in 'hide' currentAction and the
	// clicked element isn't a hide control, hide it and record it. (Original:
	// $(this).hide(); hiddenButtonsName.push(thisId).)
	if (state.currentAction === 'hide' && id.indexOf('hide') === -1) {
		if (ui.hideButton) { ui.hideButton(id); }
		if (ui.onHideChanged) { ui.onHideChanged(); }
		return true;
	}

	if (id.indexOf('tool_') > -1) {
		var toolName = id.substr(5, id.length);
		var tool_on = false;
		if (toolName.toString() === state.currentAction.toString()) {
			// Second press turns the tool off (clear_selection_button).
			tool_on = false;
			FB.Toolbar.clearSelectionButton(controller);
		} else {
			state.currentAction = toolName;
			tool_on = true;
			if (ui.setToolSelected) { ui.setToolSelected(id, true); }
		}
		controller.handleToolUpdate(toolName, tool_on);
		if (toolName === 'hide' && ui.onHideMode) { ui.onHideMode(tool_on); }
		controller.refresh();
		return true;
	}

	if (id.indexOf('action_') > -1) {
		switch (id.substr(7, id.length)) {
			case 'copy':
				controller.addUndoState();
				controller.copyBars();
				controller.refresh();
				break;
			case 'delete':
				controller.addUndoState();
				controller.deleteSelectedBars();
				controller.refresh();
				break;
			case 'join':
				controller.addUndoState();
				controller.joinSelected();
				controller.refresh();
				break;
			case 'setUnitBar':
				controller.addUndoState();
				controller.setUnitBar();
				controller.refresh();
				break;
			case 'measure':
				controller.addUndoState();
				controller.measureBars();
				controller.refresh();
				break;
			case 'make':
				// Original opened the Make dialog (fbCanvasObj.make()); the
				// dialog OK then calls controller.makeMake(n).
				controller.addUndoState();
				if (ui.openMake) { ui.openMake(); }
				controller.refresh();
				break;
			case 'breakApart':
				controller.addUndoState();
				controller.breakApartBars();
				controller.refresh();
				break;
			case 'clearSplits':
				controller.addUndoState();
				controller.clearSplits();
				controller.refresh();
				break;
			case 'pullOutSplit':
				controller.addUndoState();
				controller.pullOutSplit();
				controller.refresh();
				break;
			case 'undo':
				controller.undo();
				controller.refresh();
				break;
			case 'redo':
				controller.redo();
				controller.refresh();
				break;
			case 'save':
				if (ui.save) { ui.save(); }
				break;
			case 'open':
				if (ui.open) { ui.open(); }
				break;
			case 'print':
				if (ui.print) { ui.print(); }
				break;
			case 'clearAll':
				if (ui.clearAll) { ui.clearAll(); }
				break;
			case 'show':
				if (ui.showAll) { ui.showAll(); }
				break;
			case 'previous':
				if (ui.previous) { ui.previous(); }
				break;
			case 'next':
				if (ui.next) { ui.next(); }
				break;
		}
		return true;
	}

	if (id.indexOf('window_') > -1) {
		switch (id.substr(7, id.length)) {
			case 'label':
				controller.addUndoState();
				if (ui.editLabel) { ui.editLabel(); }
				break;
			case 'split':
				controller.addUndoState();
				if (ui.openSplits) { ui.openSplits(); }
				break;
			case 'iterate':
				controller.addUndoState();
				if (ui.openIterate) { ui.openIterate(); }
				break;
			case 'properties':
				if (ui.openProperties) { ui.openProperties(); }
				break;
		}
		return true;
	}

	return false;
};

// Ports clear_selection_button: clear mouse, clear selection, deselect tools,
// reset currentAction.
FB.Toolbar.clearSelectionButton = function (controller) {
	var state = controller.state;
	state.mouseDownLoc = null;
	state.mouseUpLoc = null;
	controller.clearSelection();
	if (FB.Toolbar.ui && FB.Toolbar.ui.setToolSelected) {
		FB.Toolbar.ui.setToolSelected(null, false); // null id => clear all
	}
	state.currentAction = '';
};

// Ports the .colorBlock click handler: set fill color, recolor selected bars.
FB.Toolbar.setColor = function (controller, color) {
	controller.setFillColor(color);
	controller.updateColorsOfSelectedBars();
	controller.refresh();
};

// Ports the .colorBlock1 click handler: set the canvas background color.
FB.Toolbar.setBackgroundColor = function (svgEl, color) {
	if (svgEl && svgEl.style) {
		svgEl.style.backgroundColor = color;
	}
};

// Wires the toolbar DOM: every element with an id matching tool_/action_/window_
// dispatches on click + pointerup (touch); color swatches recolor; the
// add-to-selection toggle drives FB.Toolbar.selectionMode.
FB.Toolbar.bind = function (rootEl, controller, opts) {
	opts = opts || {};
	if (!rootEl || !rootEl.querySelectorAll) { return; }

	var handle = function (el) {
		return function (e) {
			if (e && typeof e.preventDefault === 'function') { e.preventDefault(); }
			var id = el.getAttribute('id');
			FB.Toolbar.dispatch(controller, id, opts);
		};
	};

	var links = rootEl.querySelectorAll('[id^="tool_"],[id^="action_"],[id^="window_"]');
	for (var i = 0; i < links.length; i++) {
		var el = links[i];
		var h = handle(el);
		el.addEventListener('click', h);
	}

	// Foreground (fill) color swatches.
	var swatches = rootEl.querySelectorAll('.colorBlock');
	for (var s = 0; s < swatches.length; s++) {
		(function (sw) {
			sw.addEventListener('click', function () {
				var color = sw.getAttribute('data-color') ||
					(sw.style && sw.style.backgroundColor) || '';
				FB.Toolbar.setColor(controller, color);
				if (FB.Toolbar.ui && FB.Toolbar.ui.setColorSelected) {
					FB.Toolbar.ui.setColorSelected(sw);
				}
			});
		})(swatches[s]);
	}

	// Background color swatches.
	var bgSwatches = rootEl.querySelectorAll('.colorBlock1');
	var svgEl = opts.svgRoot || null;
	for (var b = 0; b < bgSwatches.length; b++) {
		(function (sw) {
			sw.addEventListener('click', function () {
				var color = sw.getAttribute('data-color') ||
					(sw.style && sw.style.backgroundColor) || '';
				FB.Toolbar.setBackgroundColor(svgEl, color);
			});
		})(bgSwatches[b]);
	}

	// The touch "add to selection" toggle (replaces shiftKey when true).
	if (opts.addToSelectionToggle) {
		var toggle = opts.addToSelectionToggle;
		toggle.addEventListener('click', function () {
			FB.Toolbar.selectionMode = !FB.Toolbar.selectionMode;
			if (toggle.setAttribute) {
				toggle.setAttribute('aria-pressed', FB.Toolbar.selectionMode ? 'true' : 'false');
			}
		});
	}
};
