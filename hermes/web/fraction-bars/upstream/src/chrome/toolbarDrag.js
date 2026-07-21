// src/chrome/toolbarDrag.js
//
// Makes the toolbar a draggable floating panel (docked top-left by default).
// Drag by its handle; position persists in localStorage and is clamped to the
// workspace. Pointer Events only, scripted styles only -- no eval / network /
// innerHTML, so the seal holds.

FB.ToolbarDrag = FB.ToolbarDrag || {};

FB.ToolbarDrag.install = function (doc, win) {
	if (!doc || !doc.getElementById) { return; }
	var panel = doc.getElementById('fb-toolbar');
	var handle = doc.getElementById('fb-toolbar-handle');
	var dock = doc.getElementById('fb-toolbar-dock');
	if (!panel || !handle) { return; }
	var KEY = 'fb-toolbar-pos';
	var DEFAULT = { left: 10, top: 10 };

	function workspace() { return panel.parentElement; }

	function clamp(left, top) {
		var ws = workspace();
		var wr = ws && ws.getBoundingClientRect
			? ws.getBoundingClientRect()
			: { width: (win && win.innerWidth) || 800, height: (win && win.innerHeight) || 600 };
		var maxL = Math.max(0, wr.width - panel.offsetWidth);
		var maxT = Math.max(0, wr.height - panel.offsetHeight);
		return {
			left: Math.min(Math.max(0, left), maxL),
			top: Math.min(Math.max(0, top), maxT)
		};
	}

	function setPos(left, top) {
		var c = clamp(left, top);
		panel.style.left = c.left + 'px';
		panel.style.top = c.top + 'px';
	}

	function save() {
		try {
			if (win && win.localStorage) {
				win.localStorage.setItem(KEY, JSON.stringify({
					left: parseFloat(panel.style.left) || DEFAULT.left,
					top: parseFloat(panel.style.top) || DEFAULT.top
				}));
			}
		} catch (e) { /* ignore */ }
	}

	function restore() {
		var pos = null;
		try { pos = win && win.localStorage && JSON.parse(win.localStorage.getItem(KEY)); } catch (e) { /* ignore */ }
		if (pos && isFinite(pos.left) && isFinite(pos.top)) { setPos(pos.left, pos.top); }
	}

	var dragging = false, startX = 0, startY = 0, baseL = 0, baseT = 0, pid = null;

	function down(e) {
		if (e.target === dock) { return; } // let the reset button click through
		dragging = true;
		panel.classList.add('is-dragging');
		pid = (e.pointerId !== undefined ? e.pointerId : 0);
		try { handle.setPointerCapture(pid); } catch (_) { /* ignore */ }
		startX = e.clientX; startY = e.clientY;
		var r = panel.getBoundingClientRect();
		var wr = workspace().getBoundingClientRect();
		baseL = r.left - wr.left; baseT = r.top - wr.top;
		if (e.preventDefault) { e.preventDefault(); }
	}
	function move(e) {
		if (!dragging) { return; }
		setPos(baseL + (e.clientX - startX), baseT + (e.clientY - startY));
	}
	function up() {
		if (!dragging) { return; }
		dragging = false;
		panel.classList.remove('is-dragging');
		try { handle.releasePointerCapture(pid); } catch (_) { /* ignore */ }
		save();
	}

	handle.addEventListener('pointerdown', down);
	handle.addEventListener('pointermove', move);
	handle.addEventListener('pointerup', up);
	handle.addEventListener('pointercancel', up);

	if (dock) {
		dock.addEventListener('click', function (e) {
			if (e && e.stopPropagation) { e.stopPropagation(); }
			setPos(DEFAULT.left, DEFAULT.top);
			save();
		});
	}

	if (win && win.addEventListener) {
		win.addEventListener('resize', function () {
			var l = parseFloat(panel.style.left), t = parseFloat(panel.style.top);
			if (isFinite(l) && isFinite(t)) { setPos(l, t); }
		});
	}

	restore();
};
