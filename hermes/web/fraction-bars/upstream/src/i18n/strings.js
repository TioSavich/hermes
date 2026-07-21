// src/i18n/strings.js
//
// String table for Fraction Bars. The English ('eng') entries are transcribed
// verbatim from the original `lang_eng.css` content-map (the `.c_*:before {
// content: "..." }` rules the old app injected via stylesheet). The Turkish
// ('tur') entries are transcribed from the inline Turkish `alert(...)` strings
// found in the original `FractionBarsCanvas.js` and `Bar.js`.
//
// FB.I18N.set(lang) selects the active language ('eng' | 'tur'); FB.I18N.t(key)
// returns the active string for a key (falling back to English, then the key
// itself). No DOM, no network, no eval.

FB.I18N = FB.I18N || {};

(function () {
	// English: transcribed from lang_eng.css (.c_*:before content values).
	var eng = {
		// toolbar labels
		bar: 'Bar',
		mat: 'Mat',
		copy: 'Copy',
		repeat: 'Repeat',
		iterate: 'Iterate',
		join: 'Join',
		delete: 'Delete',
		parts: 'Parts',
		pieces: 'Line',
		b_apart: 'Break Apart',
		pullout: 'Pull Out Parts',
		c_parts: 'Clear Parts',
		set_unit: 'Set Unit Bar',
		measure: 'Measure',
		make: 'Make',
		label: 'Label',
		undo: 'Undo',
		redo: 'Redo',
		save: 'Save',
		open: 'Open',
		'new': 'New',
		print: 'Print',
		properties: 'Properties',
		hide: 'Hide Tools',
		show: 'Show All',
		hide_done: 'Done hiding',
		previous: 'Previous',
		next: 'Next',

		// titles / headings
		bar_title: 'Fraction Bar',

		// dialog: splits
		dialog_splits: 'Partition part of bar',
		vertical: 'Vertical',
		horizontal: 'Horizontal',
		number_part: 'Number of parts:',
		part_whole: 'Partition whole bar',
		part_part: 'Partition part of bar',

		// dialog: properties
		dialog_properties: 'Partition part of bar',
		iterations: 'Iterations',
		dont_create: "Don't Create New Bar",
		create_new: 'Create New Bar',
		two_way: 'Two way Iterate',
		one_way: 'Only one way Iterate',
		splits: 'Splits (Parts)',
		vert_horiz: 'Vertical or Horizontal Split',
		only_vert: 'Only vertical split',
		lang: 'Language',
		lang_tur: 'Turkish',
		lang_eng: 'English',
		color: 'Background Color',

		// dialog: iterate
		dialog_iterate: 'Iterate',
		number_iterations: 'Number of iterations:',

		// dialog: make
		number_whole: 'Write Fraction:',

		// dialog: file
		choose_file: 'Choose a File',
		open_file: 'Use the button below to choose a FractionBars file to open.',

		// alerts (English originals from FractionBarsCanvas.js / Bar.js)
		split_alert: 'Please select a bar to partition.',
		select_bar_to_partition: 'Please select a bar to partition.',
		select_one_to_iterate: 'Please select exactly one bar to iterate.',
		select_one_to_make: 'Please select exactly one bar to make new bar.',
		select_two_to_join: 'Please select exactly two bars (and no mats) before attempting to Join.',
		measure_no_unit: 'Set a unit bar first: select a bar, then tap "Set Unit Bar".',
		join_dimension_mismatch: 'To Join, bars must have a matching dimension in height or width.',
		repeat_no_unit: 'Tried to Repeat when no repeatUnit was set.',
		save_unsupported: 'This browser does not support saving. \nHTML5 support is needed. \n\nFor best results use the most recent Firefox, \nChrome, Safari, or Internet Explorer browser.'
	};

	// Turkish: transcribed from the inline alert() strings in the original.
	var tur = {
		// alerts
		split_alert: 'Lütfen ayrıştırılacak bir kesir şeridi seçiniz.',
		select_bar_to_partition: 'Lütfen ayrıştırılacak bir kesir şeridi seçiniz.',
		select_one_to_iterate: 'Lütfen yineleme işlemi yapabilmek için bir kesir şeridi seçiniz.',
		select_one_to_make: 'Lütfen yeni bir şerit yapabilmek için bir kesir şeridi seçiniz.',
		select_two_to_join: 'Birleştirme işlemi yapabilmek için lütfen iki kesir şeridi seçiniz.',
		measure_no_unit: 'Önce bir birim kesir şeridi ayarlayın: bir şerit seçin, sonra "Birim Şerit Ayarla" düğmesine basın.',
		save_unsupported: 'Bu tarayıcı kaydetmeyi desteklememektedir. Tarayıcının \nHTML5 destekli olması gereklidir. \n\nEn iyi sonuç için lütfen Firefox, \nChrome, Safari ya da Internet Explorer tarayıcılarından birini kullanınız.'
	};

	var tables = { eng: eng, tur: tur };
	var current = 'eng';

	FB.I18N.set = function (lang) {
		// Accept BCP-47-ish values too ('en', 'en-US', 'tr', 'tr-TR').
		var l = (lang == null ? '' : String(lang)).toLowerCase();
		if (l === 'eng' || l.indexOf('en') === 0) {
			current = 'eng';
		} else if (l === 'tur' || l.indexOf('tr') === 0) {
			current = 'tur';
		} else if (tables[l]) {
			current = l;
		}
		return current;
	};

	FB.I18N.get = function () { return current; };

	FB.I18N.t = function (key) {
		var table = tables[current] || eng;
		if (Object.prototype.hasOwnProperty.call(table, key)) {
			return table[key];
		}
		if (Object.prototype.hasOwnProperty.call(eng, key)) {
			return eng[key];
		}
		return key;
	};

	// Apply the active language to the DOM: every element carrying a data-i18n
	// attribute gets its textContent set from t(key). Keys without an authentic
	// translation in the active table fall back to English (see t()), so the UI
	// stays usable; supply lang_tur UI strings in `tur` above to fully localize.
	FB.I18N.apply = function (doc) {
		if (!doc || !doc.querySelectorAll) { return; }
		var nodes = doc.querySelectorAll('[data-i18n]');
		for (var i = 0; i < nodes.length; i++) {
			var key = nodes[i].getAttribute('data-i18n');
			if (key) { nodes[i].textContent = FB.I18N.t(key); }
		}
	};
})();
