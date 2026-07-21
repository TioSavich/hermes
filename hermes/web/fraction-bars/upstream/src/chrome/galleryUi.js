// src/chrome/galleryUi.js
//
// Minimal UI for the in-browser (IndexedDB) saved-work gallery (FB.Gallery). It
// renders a "save to browser" field plus a list of saved documents with Load,
// Duplicate, and Delete. This is the modern, no-file save/load surface; portable
// file Save/Open remain available in the toolbar.
//
// DOM is built with createElement/textContent only (no innerHTML, no network).

FB.GalleryUI = FB.GalleryUI || {};

FB.GalleryUI.bind = function (panelEl, gallery, controller, opts) {
	opts = opts || {};
	var doc = opts.document || (panelEl && panelEl.ownerDocument);
	var win = opts.window;
	var notify = opts.notify || function () {};
	var getState = opts.getState || function () { return FB.Persistence.serialize(controller.state); };
	var applyState = opts.applyState || function () {};
	if (!panelEl || !doc) { return null; }

	function now() {
		return (win && win.Date) ? win.Date.now() : 0;
	}

	function el(tag, opts2) {
		var node = doc.createElement(tag);
		if (opts2 && opts2.text != null) { node.textContent = opts2.text; }
		if (opts2 && opts2.cls) { node.className = opts2.cls; }
		return node;
	}

	function button(label, cls, onClick) {
		var b = el('button', { text: label, cls: cls || 'fb-btn' });
		b.type = 'button';
		b.addEventListener('click', onClick);
		return b;
	}

	var listEl = null;

	function refreshList() {
		gallery.list().then(function (entries) {
			if (!listEl) { return; }
			listEl.replaceChildren();
			entries.sort(function (a, b) { return (b.updatedAt || 0) - (a.updatedAt || 0); });
			if (entries.length === 0) {
				listEl.appendChild(el('li', { text: 'No saved work yet.', cls: 'fb-gallery-empty' }));
				return;
			}
			for (var i = 0; i < entries.length; i++) {
				(function (name) {
					var li = el('li', { cls: 'fb-gallery-item' });
					li.appendChild(el('span', { text: name, cls: 'fb-gallery-name' }));
					li.appendChild(button('Load', 'fb-btn fb-btn-sm', function () {
						gallery.load(name).then(function (obj) {
							if (obj) { applyState(obj); notify('Loaded "' + name + '".'); }
						});
					}));
					li.appendChild(button('Duplicate', 'fb-btn fb-btn-sm', function () {
						gallery.duplicate(name, name + ' copy', now()).then(refreshList);
					}));
					li.appendChild(button('Delete', 'fb-btn fb-btn-sm', function () {
						var ok = win && win.confirm ? win.confirm('Delete "' + name + '"?') : true;
						if (ok) { gallery.remove(name).then(refreshList); }
					}));
					listEl.appendChild(li);
				})(entries[i].name);
			}
		});
	}

	function buildPanel() {
		panelEl.replaceChildren();
		panelEl.appendChild(el('h2', { text: 'Saved Work', cls: 'fb-gallery-title' }));

		var saveRow = el('div', { cls: 'fb-gallery-saverow' });
		var nameInput = el('input');
		nameInput.type = 'text';
		nameInput.placeholder = 'Name this work';
		nameInput.className = 'fb-gallery-input';
		saveRow.appendChild(nameInput);
		saveRow.appendChild(button('Save to browser', 'fb-btn', function () {
			var name = (nameInput.value || '').trim();
			if (!name) { notify('Please name this work first.'); return; }
			gallery.save(name, getState(), now()).then(function () {
				nameInput.value = '';
				notify('Saved "' + name + '" in this browser.');
				refreshList();
			});
		}));
		panelEl.appendChild(saveRow);

		listEl = el('ul', { cls: 'fb-gallery-list' });
		panelEl.appendChild(listEl);
		refreshList();
	}

	buildPanel();

	return {
		toggle: function () {
			var hidden = panelEl.hasAttribute('hidden');
			if (hidden) { panelEl.removeAttribute('hidden'); refreshList(); }
			else { panelEl.setAttribute('hidden', ''); }
			return !hidden;
		},
		refresh: refreshList
	};
};
