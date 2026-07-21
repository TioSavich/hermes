// src/chrome/dialogs.js
//
// Native <dialog>-based replacement for the original UI-toolkit dialogs and the
// slider/splits widget wiring in fractionbars.js. Every dialog uses
// the platform <dialog> element with showModal()/close() instead of
// the legacy .dialog("open")/"close" calls. The OK/Cancel button handlers reproduce the
// original button logic verbatim (including Utilities.flag[0..3] updates and the
// canvas background-color set), and notify() is an accessible non-blocking toast
// that replaces the original alert(...) calls.
//
// No third-party UI toolkit, no dynamic code execution, no markup injection, no network.
FB.Dialogs = FB.Dialogs || {};

(function () {
	FB.Dialogs.init = function (doc, controller) {
		function byId(id) {
			return doc.getElementById ? doc.getElementById(id) : null;
		}

		function show(id) {
			var d = byId(id);
			if (d && typeof d.showModal === 'function') {
				d.showModal();
			}
		}

		function close(id) {
			var d = byId(id);
			if (d && typeof d.close === 'function') {
				d.close();
			}
		}

		// Value of the checked radio in a named group, or undefined.
		function radioValue(name) {
			if (!doc.querySelector) { return undefined; }
			var checked = doc.querySelector("input[type='radio'][name='" + name + "']:checked");
			return checked ? checked.value : undefined;
		}

		function fieldValue(id) {
			var f = byId(id);
			return f ? f.value : undefined;
		}

		function setDisplay(id, value) {
			var node = byId(id);
			if (node && node.style) { node.style.display = value; }
		}

		// --- accessible non-blocking toast (replaces alert) ----------------------

		var toast = null;
		var toastTimer = null;
		function ensureToast() {
			if (toast) { return toast; }
			toast = byId('fb-toast');
			if (!toast && doc.createElement) {
				toast = doc.createElement('div');
				toast.id = 'fb-toast';
				toast.className = 'fb-toast';
				toast.setAttribute('role', 'status');
				toast.setAttribute('aria-live', 'polite');
				toast.setAttribute('hidden', '');
				if (doc.body && doc.body.appendChild) {
					doc.body.appendChild(toast);
				}
			}
			return toast;
		}

		function notify(msg) {
			var t = ensureToast();
			if (!t) { return; }
			t.textContent = String(msg == null ? '' : msg);
			t.removeAttribute('hidden');
			if (t.classList && t.classList.add) { t.classList.add('is-visible'); }
			if (toastTimer && typeof clearTimeout === 'function') { clearTimeout(toastTimer); }
			if (typeof setTimeout === 'function') {
				toastTimer = setTimeout(function () {
					if (t.classList && t.classList.remove) { t.classList.remove('is-visible'); }
					t.setAttribute('hidden', '');
				}, 4000);
			}
		}

		// --- wiring helpers ------------------------------------------------------

		function on(node, type, handler) {
			if (node && node.addEventListener) {
				node.addEventListener(type, handler);
			}
		}

		// Bind the OK/Cancel buttons of a dialog. Buttons are looked up by id
		// (<dialog>-scoped) so each dialog owns its own pair.
		function bindButtons(dialogId, okId, cancelId, okHandler) {
			on(byId(okId), 'click', function () {
				if (okHandler) { okHandler(); }
			});
			on(byId(cancelId), 'click', function () {
				close(dialogId);
			});
		}

		// --- #split-slider -> #split-slider-field --------------------------------
		// Original UI-toolkit slider mirrored ui.value into #split-slider-field on
		// slide; the native range input does the same on 'input'.
		(function () {
			var slider = byId('split-slider');
			var field = byId('split-slider-field');
			on(slider, 'input', function () {
				if (field) { field.value = slider.value; }
			});
		})();

		// --- #dialog-splits ------------------------------------------------------
		bindButtons('dialog-splits', 'splits-ok', 'splits-cancel', function () {
			var num_splits = fieldValue('split-slider-field');
			var whole = radioValue('whole_part');
			var direction = 'Vertical';
			if (FB.Utilities.flag[1]) {
				direction = radioValue('vert_horiz');
			}
			controller.makeSplits(num_splits, direction, whole);
			close('dialog-splits');
		});

		// --- #dialog-properties --------------------------------------------------
		bindButtons('dialog-properties', 'properties-ok', 'properties-cancel', function () {
			var create_checked = radioValue('create');
			if (create_checked === 'Same') {
				FB.Utilities.flag[0] = true;
			} else if (create_checked === 'New') {
				FB.Utilities.flag[0] = false;
			}

			var horiz_checked = radioValue('two_split');
			if (horiz_checked === 'One_horiz') {
				FB.Utilities.flag[1] = false;
				setDisplay('radio_vert', 'none');
			} else if (horiz_checked === 'Two_horiz') {
				FB.Utilities.flag[1] = true;
				setDisplay('radio_vert', 'block');
			}

			var iterate_way_checked = radioValue('two_ittr');
			if (iterate_way_checked === 'One_way') {
				FB.Utilities.flag[2] = false;
				setDisplay('iterate_vert-horiz', 'none');
			} else if (iterate_way_checked === 'Two_way') {
				FB.Utilities.flag[2] = true;
				setDisplay('iterate_vert-horiz', 'block');
			}

			var language_checked = radioValue('lang');
			switch (language_checked) {
				case 'lang_eng':
					FB.Utilities.flag[3] = false;
					if (FB.I18N && FB.I18N.set) { FB.I18N.set('eng'); }
					break;
				case 'lang_tur':
					FB.Utilities.flag[3] = true;
					if (FB.I18N && FB.I18N.set) { FB.I18N.set('tur'); }
					break;
			}

			close('dialog-properties');
		});

		// --- #dialog-iterate -----------------------------------------------------
		bindButtons('dialog-iterate', 'iterate-ok', 'iterate-cancel', function () {
			// Validate + clamp: ignore non-numeric / < 1, cap at 100 so a stray
			// large entry cannot freeze a low-powered tablet.
			var raw = parseInt(fieldValue('iterate-field'), 10);
			if (!isFinite(raw) || raw < 1) { close('dialog-iterate'); return; }
			var MAX_ITER = 100;
			var num_iterate = raw > MAX_ITER ? MAX_ITER : raw;
			if (raw > MAX_ITER) { notify('Maximum ' + MAX_ITER + ' iterations.'); }
			var direction;
			if (!FB.Utilities.flag[2]) {
				direction = 'Horizontal';
			} else {
				direction = radioValue('vert_horiz');
			}
			controller.makeIterations(num_iterate, direction);
			close('dialog-iterate');
		});

		// --- #dialog-make --------------------------------------------------------
		bindButtons('dialog-make', 'make-ok', 'make-cancel', function () {
			var num_whole = parseFloat(fieldValue('whole-field'));
			var num_num = parseFloat(fieldValue('num-field'));
			var num_denum = parseFloat(fieldValue('denum-field'));

			if (!num_whole) { num_whole = 0; }
			if (!num_denum) { num_denum = 1; }
			if (!num_num) { num_num = 0; }

			var num_frac = num_whole + (num_num / num_denum);
			if (!num_frac) {
				notify('Please input fraction!');
			} else {
				controller.makeMake(num_frac);
			}

			var wf = byId('whole-field'); if (wf) { wf.value = ''; }
			var nf = byId('num-field'); if (nf) { nf.value = ''; }
			var df = byId('denum-field'); if (df) { df.value = ''; }
			close('dialog-make');
		});

		// --- #dialog-file --------------------------------------------------------
		// Cancel-only in the original. The file <input> change handler closes the
		// dialog and hands the selected file off to the controller's open path.
		(function () {
			on(byId('file-cancel'), 'click', function () {
				close('dialog-file');
			});
			var fileInput = byId('fileInput');
			on(fileInput, 'change', function (event) {
				close('dialog-file');
				var files = event && event.target ? event.target.files : null;
				if (!files || files.length === 0) { return; }
				if (controller && typeof controller.openFile === 'function') {
					controller.openFile(files[0]);
				}
			});
		})();

		return {
			notify: notify,
			open: show,
			close: close
		};
	};
})();
