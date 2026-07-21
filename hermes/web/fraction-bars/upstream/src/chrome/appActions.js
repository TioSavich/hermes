// src/chrome/appActions.js
//
// The DOM-facing application actions that the original fractionbars.js performed
// inline (file Save/Open with multi-file Previous/Next, Print, New/clearAll, the
// Label editor overlay, Hide/Show toolbar buttons, and the toolbar selection-
// state helpers). These were not part of the model/controller port, so they live
// here and are wired into FB.Toolbar.ui by main.js.
//
// No network, no eval, no innerHTML. Files are read with FileReader and parsed as
// data; downloads use an object URL on a transient <a>. DOM is built with
// createElement/textContent only.

FB.AppActions = FB.AppActions || {};

FB.AppActions.create = function (deps) {
	deps = deps || {};
	var doc = deps.document;
	var win = deps.window;
	var controller = deps.controller;
	var svgRoot = deps.svgRoot;
	var notify = deps.notify || function () {};
	var openFileDialog = deps.openFileDialog || function () {};
	var closeFileDialog = deps.closeFileDialog || function () {};

	var hiddenEls = [];        // elements hidden via Hide mode (for Show All)
	var fileList = [];         // FileList from a multi-file Open
	var fileIndex = 0;
	var currentFileName = null;

	function t(key) {
		return (FB.I18N && FB.I18N.t) ? FB.I18N.t(key) : key;
	}

	// ----- state apply (shared by file open and gallery load) ----------------

	function applyStateObject(obj) {
		var rebuilt = FB.Persistence.deserialize(obj);
		var s = controller.state;
		s.bars = rebuilt.bars;
		s.mats = rebuilt.mats;
		s.unitBar = rebuilt.unitBar;
		s.selectedBars = [];
		s.selectedMats = [];
		s.lastSelectedBars = [];
		s.lastSelectedMats = [];
		controller.mUndoArray.length = 0;
		controller.mRedoArray.length = 0;
		showAll();
		applyHidden(rebuilt.hidden || []);
		controller.refresh();
	}

	// ----- Save (file download) ----------------------------------------------

	function save() {
		var json;
		try {
			json = FB.Persistence.toJSON(controller.state);
		} catch (e) {
			notify(t('save_unsupported'));
			return;
		}
		var suggested = currentFileName || 'FractionBarsSave.txt';
		var name = win && win.prompt ? win.prompt('File name:', suggested) : suggested;
		if (name == null) { return; }
		try {
			var blob = new Blob([json], { type: 'text/plain;charset=utf-8' });
			var url = (win.URL || win.webkitURL).createObjectURL(blob);
			var a = doc.createElement('a');
			a.href = url;
			a.download = name;
			doc.body.appendChild(a);
			a.click();
			doc.body.removeChild(a);
			if (typeof win.setTimeout === 'function') {
				win.setTimeout(function () { (win.URL || win.webkitURL).revokeObjectURL(url); }, 0);
			}
			currentFileName = name;
		} catch (e2) {
			notify(t('save_unsupported'));
		}
	}

	// ----- Open (file dialog + multi-file navigation) ------------------------

	function open() {
		// Reset the file input so re-opening the same file fires 'change'.
		var input = doc.getElementById('fileInput');
		if (input) { try { input.value = ''; } catch (e) { /* ignore */ } }
		openFileDialog();
	}

	function setTitle(name) {
		currentFileName = name;
		var title = doc.getElementById('bar_titles');
		if (title) { title.textContent = name ? (t('bar_title') + ': ' + name) : t('bar_title'); }
		if (name) { try { doc.title = name; } catch (e) { /* ignore */ } }
	}

	function loadFileAt(i) {
		if (i < 0 || i >= fileList.length) { return; }
		fileIndex = i;
		var f = fileList[i];
		var reader = new FileReader();
		reader.onload = function (ev) {
			var obj;
			try {
				obj = FB.Persistence.parseFile(ev.target.result);
			} catch (err) {
				notify('Fraction Bars cannot open this file.\n\n' + (err && err.message ? err.message : err));
				return;
			}
			applyStateObject(obj);
			setTitle(f.name);
			updateNav();
		};
		reader.readAsText(f);
	}

	function handleFiles(list) {
		if (!list || list.length === 0) { return; }
		fileList = list;
		fileIndex = 0;
		closeFileDialog();
		loadFileAt(0);
	}

	function previous() { if (fileIndex > 0) { loadFileAt(fileIndex - 1); } }
	function next() { if (fileIndex < fileList.length - 1) { loadFileAt(fileIndex + 1); } }

	function updateNav() {
		var prev = doc.getElementById('action_previous');
		var nxt = doc.getElementById('action_next');
		var many = fileList.length > 1;
		if (prev) { prev.toggleAttribute('hidden', !(many && fileIndex > 0)); }
		if (nxt) { nxt.toggleAttribute('hidden', !(many && fileIndex < fileList.length - 1)); }
	}

	// ----- Print (vector, via @media print CSS) ------------------------------

	function print() {
		// The sealed build prints vector SVG directly: a print stylesheet hides the
		// chrome and shows only the canvas, then we ask the browser to print.
		if (win && typeof win.print === 'function') { win.print(); }
	}

	// ----- New / clearAll ----------------------------------------------------

	function clearAll() {
		var ok = win && win.confirm ? win.confirm('Start a new Fraction Bars document? Unsaved work will be lost.') : true;
		if (!ok) { return; }
		var s = controller.state;
		s.bars = [];
		s.mats = [];
		s.unitBar = null;
		s.selectedBars = [];
		s.selectedMats = [];
		s.lastSelectedBars = [];
		s.lastSelectedMats = [];
		controller.mUndoArray.length = 0;
		controller.mRedoArray.length = 0;
		fileList = [];
		fileIndex = 0;
		setTitle(null);
		showAll();
		controller.refresh();
	}

	// ----- Label editor overlay ----------------------------------------------

	var labelWired = false;
	function wireLabelInput() {
		if (labelWired) { return; }
		var input = doc.getElementById('labelInput');
		if (!input) { return; }
		labelWired = true;
		input.addEventListener('keyup', function (e) {
			if (e.which === 13 || e.key === 'Enter') {
				controller.saveLabel(input.value, FB.Utilities.USE_CURRENT_SELECTION);
				hideLabel();
				controller.refresh();
			}
		});
		input.addEventListener('blur', function () {
			// Fires after selection may have cleared; use last selection.
			controller.saveLabel(input.value, FB.Utilities.USE_LAST_SELECTION);
			hideLabel();
		});
	}

	function hideLabel() {
		var input = doc.getElementById('labelInput');
		if (input) { input.classList.remove('is-editing'); input.style.display = 'none'; }
	}

	function editLabel() {
		wireLabelInput();
		var sel = controller.state.selectedBars;
		if (sel.length !== 1) { return; }
		var b = sel[0];
		var input = doc.getElementById('labelInput');
		if (!input) { return; }
		// Map model coords -> client pixels. The canvas fills the stage and
		// letterboxes a 1000x700 viewBox (preserveAspectRatio="xMidYMid meet"),
		// so the content scale is the smaller axis ratio and the drawing is
		// centered -- account for both the uniform scale and the letterbox offset.
		var rect = svgRoot.getBoundingClientRect
			? svgRoot.getBoundingClientRect()
			: { left: 0, top: 0, width: 1000, height: 700 };
		var scale = Math.min(rect.width / 1000, rect.height / 700) || 1;
		var offX = (rect.width - 1000 * scale) / 2;
		var offY = (rect.height - 700 * scale) / 2;
		input.style.position = 'fixed';
		input.style.left = (rect.left + offX + (b.x + 5) * scale) + 'px';
		input.style.top = (rect.top + offY + (b.y + b.h - 22) * scale) + 'px';
		input.style.width = Math.max(40, (b.w - 13) * scale) + 'px';
		input.value = b.label || '';
		input.classList.add('is-editing');
		input.style.display = 'inline-block';
		if (typeof input.focus === 'function') { input.focus(); }
	}

	// ----- Hide / Show toolbar buttons ---------------------------------------

	function hideButton(id) {
		if (FB.hiddenButtonNames.indexOf(id) < 0) {
			var el = doc.getElementById(id);
			if (el) {
				el.setAttribute('hidden', '');
				FB.hiddenButtonNames.push(id);
				hiddenEls.push(el);
			}
		}
		updateHideUi();
	}

	// Reflect the hidden-tool count into the Show All button + the banner so the
	// (otherwise invisible, "locked") hide state is always legible.
	function updateHideUi() {
		var n = hiddenEls.length;
		var show = doc.getElementById('action_show');
		if (show) {
			show.classList.toggle('is-disabled', n === 0);
			show.setAttribute('aria-disabled', n === 0 ? 'true' : 'false');
			show.textContent = n > 0 ? (t('show') + ' (' + n + ')') : t('show');
		}
		var count = doc.getElementById('fb-hide-count');
		if (count) {
			count.textContent = n > 0
				? (' ' + n + (n === 1 ? ' tool hidden.' : ' tools hidden.'))
				: '';
		}
	}

	// Enter / leave hide mode: toggle the body affordance class, show the banner,
	// and swap the Hide control's label to "Done hiding" so it clearly reads as a
	// toggle the user must turn back off.
	function setHideMode(active) {
		if (doc.body) { doc.body.classList.toggle('fb-hide-active', !!active); }
		var banner = doc.getElementById('fb-hide-banner');
		if (banner) { banner.toggleAttribute('hidden', !active); }
		var hideBtn = doc.getElementById('tool_hide');
		if (hideBtn) { hideBtn.textContent = active ? t('hide_done') : t('hide'); }
		updateHideUi();
	}

	function showAll() {
		while (hiddenEls.length > 0) {
			var el = hiddenEls.pop();
			el.removeAttribute('hidden');
		}
		FB.hiddenButtonNames.length = 0;
		updateHideUi();
	}

	function applyHidden(names) {
		for (var i = 0; i < names.length; i++) {
			// The snapshot always includes the Hide/Show controls; skip those so a
			// loaded file does not permanently bury them.
			if (names[i] === 'tool_hide' || names[i] === 'action_show') { continue; }
			hideButton(names[i]);
		}
	}

	// ----- Toolbar selection-state helpers -----------------------------------

	function setToolSelected(id, on) {
		if (id === null) {
			var sel = doc.querySelectorAll('.toolBtn.toolSelected');
			for (var i = 0; i < sel.length; i++) { sel[i].classList.remove('toolSelected'); }
			return;
		}
		var el = doc.getElementById(id);
		if (el) {
			if (on) { el.classList.add('toolSelected'); }
			else { el.classList.remove('toolSelected'); }
		}
	}

	function setColorSelected(sw) {
		var sel = doc.querySelectorAll('.colorBlock.colorSelected');
		for (var i = 0; i < sel.length; i++) { sel[i].classList.remove('colorSelected'); }
		if (sw && sw.classList) { sw.classList.add('colorSelected'); }
	}

	return {
		save: save,
		open: open,
		handleFiles: handleFiles,
		previous: previous,
		next: next,
		print: print,
		clearAll: clearAll,
		editLabel: editLabel,
		hideLabel: hideLabel,
		hideButton: hideButton,
		setHideMode: setHideMode,
		updateHideUi: updateHideUi,
		showAll: showAll,
		applyState: applyStateObject,
		setToolSelected: setToolSelected,
		setColorSelected: setColorSelected
	};
};
