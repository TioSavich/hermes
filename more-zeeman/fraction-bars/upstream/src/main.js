// src/main.js -- application bootstrap.
//
// Wired on DOMContentLoaded. Assembles the renderer, controller, pointer input,
// toolbar, dialogs, gallery, i18n, keyboard shortcuts, and the external State API
// / postMessage bridge into a running app.
//
// No network, no eval, no innerHTML. DOM is built by the renderer/chrome via
// createElement(NS); this file locates elements and connects modules.

FB.Main = FB.Main || {};

FB.Main.boot = function (doc, win) {
	doc = doc || (typeof document !== 'undefined' ? document : null);
	win = win || (typeof window !== 'undefined' ? window : null);
	if (!doc) { return null; }

	// ----- DOM anchors -------------------------------------------------------
	var svgRoot = doc.getElementById('fbCanvas');
	var toolbarEl = doc.getElementById('fb-toolbar');
	var galleryEl = doc.getElementById('fb-gallery');

	// ----- Renderer ----------------------------------------------------------
	var renderer = (FB.Renderer && svgRoot)
		? FB.Renderer.create(svgRoot, doc)
		: { render: function () {} };

	// ----- i18n --------------------------------------------------------------
	var i18n = FB.I18N || null;
	if (i18n && typeof i18n.set === 'function') {
		var lang = (doc.documentElement && doc.documentElement.lang) || 'en';
		i18n.set(lang);
	}
	function translate(key) {
		return (i18n && typeof i18n.t === 'function') ? i18n.t(key) : key;
	}
	function applyI18n() {
		if (i18n && typeof i18n.apply === 'function') { i18n.apply(doc); }
	}

	// ----- Notify (late-bound to the dialog toast once dialogs exist) --------
	var notifyImpl = function (msg) { if (win && typeof win.alert === 'function') { win.alert(msg); } };
	function notify(msg) { return notifyImpl(msg); }
	FB.notify = notify; // model layer (Bar.alert shim) routes here

	// ----- Controller --------------------------------------------------------
	var controller = FB.Controller.create({
		renderer: renderer,
		notify: notify,
		getMarkedIterate: function () { return FB.Utilities.getMarkedIterateFlag(); }
	});

	// ----- Dialogs -----------------------------------------------------------
	var dialogs = (FB.Dialogs && typeof FB.Dialogs.init === 'function')
		? FB.Dialogs.init(doc, controller)
		: null;
	if (dialogs && typeof dialogs.notify === 'function') { notifyImpl = dialogs.notify; }
	function openDialog(id) { if (dialogs && dialogs.open) { dialogs.open(id); } }
	function closeDialog(id) { if (dialogs && dialogs.close) { dialogs.close(id); } }

	// ----- Splits preview widget --------------------------------------------
	var splitDisplay = doc.getElementById('split-display');
	var splitsWidget = (FB.SplitsWidget && splitDisplay)
		? FB.SplitsWidget.create(splitDisplay, doc)
		: null;
	function syncSplitsWidget() {
		if (!splitsWidget) { return; }
		var field = doc.getElementById('split-slider-field');
		var n = field ? parseInt(field.value, 10) : 2;
		var vertRadio = doc.getElementById('vert');
		var vertical = FB.Utilities.flag[1] ? !(vertRadio && !vertRadio.checked) : true;
		splitsWidget.setNumSplits(isFinite(n) ? n : 2).setVertical(vertical).refresh();
	}
	if (splitsWidget) {
		var slider = doc.getElementById('split-slider');
		if (slider) { slider.addEventListener('input', syncSplitsWidget); }
		var vr = doc.getElementById('vert'), hr = doc.getElementById('horiz');
		if (vr) { vr.addEventListener('change', syncSplitsWidget); }
		if (hr) { hr.addEventListener('change', syncSplitsWidget); }
	}

	// ----- App actions (file save/open/print/new, label, hide/show) ----------
	var actions = FB.AppActions ? FB.AppActions.create({
		document: doc, window: win, controller: controller, svgRoot: svgRoot,
		notify: notify,
		openFileDialog: function () { openDialog('dialog-file'); },
		closeFileDialog: function () { closeDialog('dialog-file'); }
	}) : null;

	// Multi-file Open: our own change handler drives Previous/Next navigation.
	var fileInput = doc.getElementById('fileInput');
	if (fileInput && actions) {
		fileInput.addEventListener('change', function (e) {
			actions.handleFiles(e && e.target ? e.target.files : null);
		});
	}

	// ----- Selection guard helper (ports the split/iterate/make guards) ------
	function requireOneBar(alertKey) {
		var n = controller.state.selectedBars.length;
		if (n !== 1) { notify(translate(alertKey)); return false; }
		return true;
	}

	// ----- Wire FB.Toolbar.ui hooks ------------------------------------------
	if (FB.Toolbar && FB.Toolbar.ui) {
		var ui = FB.Toolbar.ui;
		ui.editLabel = function () { if (actions) { actions.editLabel(); } };
		ui.openSplits = function () {
			if (!requireOneBar('select_bar_to_partition')) { return; }
			var bar = controller.state.selectedBars[0];
			if (splitsWidget && bar) { splitsWidget.setColor(bar.color); syncSplitsWidget(); }
			openDialog('dialog-splits');
		};
		ui.openIterate = function () {
			if (!requireOneBar('select_one_to_iterate')) { return; }
			openDialog('dialog-iterate');
		};
		ui.openMake = function () {
			if (!requireOneBar('select_one_to_make')) { return; }
			openDialog('dialog-make');
		};
		ui.openProperties = function () {
			// Reflect current flags into the radio controls before opening.
			function check(id, on) { var el = doc.getElementById(id); if (el) { el.checked = !!on; } }
			check('same', FB.Utilities.flag[0]); check('new', !FB.Utilities.flag[0]);
			check('two_horiz', FB.Utilities.flag[1]); check('one_horiz', !FB.Utilities.flag[1]);
			check('two_way', FB.Utilities.flag[2]); check('one_way', !FB.Utilities.flag[2]);
			check('lang_tr', FB.Utilities.flag[3]); check('lang_en', !FB.Utilities.flag[3]);
			openDialog('dialog-properties');
		};
		if (actions) {
			ui.save = actions.save; ui.open = actions.open; ui.print = actions.print;
			ui.clearAll = actions.clearAll; ui.showAll = actions.showAll;
			ui.previous = actions.previous; ui.next = actions.next;
			ui.hideButton = actions.hideButton;
			ui.onHideMode = actions.setHideMode;
			ui.onHideChanged = actions.updateHideUi;
			ui.setToolSelected = actions.setToolSelected;
			ui.setColorSelected = actions.setColorSelected;
		}
	}

	// Re-apply i18n when the Properties OK handler changes the language.
	if (dialogs) {
		var propsOk = doc.getElementById('properties-ok');
		if (propsOk) { propsOk.addEventListener('click', applyI18n); }
	}

	// ----- Toolbar -----------------------------------------------------------
	if (FB.Toolbar && toolbarEl && typeof FB.Toolbar.bind === 'function') {
		FB.Toolbar.bind(toolbarEl, controller, {
			svgRoot: svgRoot,
			addToSelectionToggle: doc.getElementById('fb-add-to-selection')
		});
	}

	// ----- Pointer input -----------------------------------------------------
	if (FB.Pointer && svgRoot && typeof FB.Pointer.attach === 'function') {
		FB.Pointer.attach(svgRoot, controller, {});
	}

	// ----- Theme / skin picker -----------------------------------------------
	// A skin is a data-theme attribute on <html>; all chrome + canvas colors are
	// CSS custom properties that cascade from it (see app.css). Persisted in
	// localStorage. After a swap we refresh so the renderer re-reads the themed
	// --fb-ink / --fb-split-stroke / --fb-guide / --fb-label-halo off the canvas.
	(function () {
		var sel = doc.getElementById('fb-theme');
		var root = doc.documentElement;
		function applyTheme(name) {
			if (name) { root.setAttribute('data-theme', name); }
			else { root.removeAttribute('data-theme'); }
			// Repaint the quick swatches to the theme's palette, then re-render so
			// the canvas re-reads themed --fb-ink / strokes / halo.
			if (FB.Swatches && typeof FB.Swatches.apply === 'function') {
				FB.Swatches.apply(doc, name || '', controller);
			}
			controller.refresh();
		}
		var saved = '';
		try { saved = (win && win.localStorage && win.localStorage.getItem('fb-theme')) || ''; } catch (e) { /* ignore */ }
		if (sel) {
			if (saved) { sel.value = saved; }
			applyTheme(sel.value);
			sel.addEventListener('change', function () {
				var v = sel.value;
				try { if (win && win.localStorage) { win.localStorage.setItem('fb-theme', v); } } catch (e) { /* ignore */ }
				applyTheme(v);
			});
		} else if (saved) {
			applyTheme(saved);
		}
	})();

	// "Done hiding" button leaves hide mode exactly like tapping Hide Tools again.
	var hideDone = doc.getElementById('fb-hide-done');
	if (hideDone && FB.Toolbar && typeof FB.Toolbar.dispatch === 'function') {
		hideDone.addEventListener('click', function () {
			FB.Toolbar.dispatch(controller, 'tool_hide', {});
		});
	}

	// Draggable, docked-left toolbar panel (position persisted to localStorage).
	if (FB.ToolbarDrag && typeof FB.ToolbarDrag.install === 'function') {
		FB.ToolbarDrag.install(doc, win);
	}

	// ----- Keyboard shortcuts (ports fractionbars.js keydown/keyup) ----------
	if (doc.addEventListener) {
		doc.addEventListener('keydown', function (e) {
			if (e.which === 16 || e.key === 'Shift') { FB.Utilities.shiftKeyDown = true; controller.refresh(); }
		});
		doc.addEventListener('keyup', function (e) {
			if (e.which === 16 || e.key === 'Shift') { FB.Utilities.shiftKeyDown = false; controller.refresh(); }
			if (e.ctrlKey && (e.keyCode === 80 || e.key === 'p')) { // Ctrl+P -> Properties
				e.preventDefault();
				if (FB.Toolbar.ui.openProperties) { FB.Toolbar.ui.openProperties(); }
			}
			if (e.ctrlKey && (e.keyCode === 83 || e.key === 's')) { // Ctrl+S -> Save
				e.preventDefault();
				if (actions) { actions.save(); }
			}
			if (e.ctrlKey && (e.keyCode === 72 || e.key === 'h')) { // Ctrl+H -> toggle Hide/Show controls
				e.preventDefault();
				FB.Utilities.ctrlKeyDown = !FB.Utilities.ctrlKeyDown;
				var hideBtn = doc.getElementById('tool_hide');
				var showBtn = doc.getElementById('action_show');
				var hideThem = FB.Utilities.ctrlKeyDown;
				if (hideBtn) { hideBtn.toggleAttribute('hidden', hideThem); }
				if (showBtn) { showBtn.toggleAttribute('hidden', hideThem); }
				FB.Toolbar.clearSelectionButton(controller);
				controller.refresh();
			}
			if (e.ctrlKey && (e.keyCode === 46 || e.key === 'Delete')) { // Ctrl+Del -> Delete
				controller.addUndoState();
				controller.deleteSelectedBars();
				controller.refresh();
			}
		});
	}

	// ----- Gallery -----------------------------------------------------------
	var gallery = null, galleryUi = null;
	if (FB.Gallery && typeof FB.Gallery.create === 'function') {
		var adapter = (win && win.indexedDB && typeof FB.Gallery.indexedDbAdapter === 'function')
			? FB.Gallery.indexedDbAdapter('fraction-bars')
			: FB.Gallery.memoryAdapter();
		gallery = FB.Gallery.create(adapter);
		if (galleryEl && FB.GalleryUI && typeof FB.GalleryUI.bind === 'function') {
			galleryUi = FB.GalleryUI.bind(galleryEl, gallery, controller, {
				document: doc, window: win, notify: notify,
				getState: function () { return FB.Persistence.serialize(controller.state); },
				applyState: actions ? actions.applyState : function () {}
			});
			var galleryToggle = doc.getElementById('fb-gallery-toggle');
			if (galleryToggle && galleryUi) {
				galleryToggle.addEventListener('click', function () {
					var shown = galleryUi.toggle();
					galleryToggle.setAttribute('aria-pressed', shown ? 'true' : 'false');
				});
			}
		}
	}

	// ----- External State API + postMessage bridge ---------------------------
	var api = null;
	if (FB.StateApi && typeof FB.StateApi.install === 'function') {
		api = FB.StateApi.install(controller, win || {});
		if (api && win && typeof FB.StateApi.installPostMessage === 'function') {
			// Intentionally same-origin-only by default. A host embedding this tool
			// (Canvas LTI / Hermes) should pass an explicit allowedOrigins list.
			FB.StateApi.installPostMessage(api, win, {
				allowedOrigins: (win.FB_ALLOWED_ORIGINS && win.FB_ALLOWED_ORIGINS.slice) ? win.FB_ALLOWED_ORIGINS.slice(0) : undefined
			});
		}
	}

	// Initial label/i18n/paint.
	applyI18n();
	if (actions && typeof actions.updateHideUi === 'function') { actions.updateHideUi(); }
	controller.refresh();

	var app = {
		controller: controller, renderer: renderer, gallery: gallery,
		galleryUi: galleryUi, dialogs: dialogs, actions: actions, i18n: i18n, api: api
	};
	FB.app = app;
	return app;
};

// Auto-boot in a browser once the DOM is ready.
if (typeof document !== 'undefined' && document.addEventListener) {
	document.addEventListener('DOMContentLoaded', function () {
		FB.Main.boot(document, typeof window !== 'undefined' ? window : undefined);
	}, false);
}
