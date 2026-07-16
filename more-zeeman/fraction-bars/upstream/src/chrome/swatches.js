// src/chrome/swatches.js
//
// Per-theme quick-fill swatch palettes. The 8 quick swatches in the toolbar
// drive the current fill color (read off each swatch's data-color by
// FB.Toolbar). Each skin gets its own on-brand palette: Classic keeps the
// original eight, Bubblegum gets candy colors, etc. Applied by setting both the
// swatch's data-color (so picking uses the themed color) and its background
// (scripted style -- CSP-safe, same mechanism the app already uses for the
// canvas background swatches). No eval, no innerHTML.

FB.Swatches = FB.Swatches || (function () {
	var palettes = {
		// Classic -- the original eight (kept verbatim).
		'':       ['#FFFF66', '#ACBEFF', '#E6E6E6', '#FFFFFF', '#CCFF66', '#FFCC66', '#DD99FF', '#FF92DA'],
		// Hermes -- parchment / gold / rust / teal scholarly palette.
		'hermes': ['#F0D68A', '#E0B84C', '#C96F43', '#6FA3AD', '#E7D9BB', '#B8915A', '#A8B79A', '#D98C6A'],
		// Crimson (IU) -- cream + crimson family, a couple of muted neutrals.
		'iu':     ['#FBE9E9', '#F2C9C9', '#DE9A9A', '#C56A6A', '#F6EFDF', '#EADCC2', '#CBB07A', '#BBD2C6'],
		// Chalkboard -- bright chalk pastels that pop on the dark board.
		'chalk':  ['#F6D04D', '#FF9A7A', '#8FD6C4', '#9EC5FF', '#F4A9D4', '#C9B3FF', '#F3EFE6', '#B6E08A'],
		// Bubblegum -- candy pinks, purples, and pastels.
		'candy':  ['#FFD1E8', '#FF8FC4', '#FF5CA8', '#C9B3FF', '#A8E6FF', '#B6F5C9', '#FFF2A8', '#FFC1A8']
	};

	// Recolor the 8 quick swatches for `theme` and keep the active selection on
	// the same slot (re-pointing the controller's current fill to the themed hue).
	function apply(doc, theme, controller) {
		if (!doc || !doc.getElementById) { return; }
		var pal = palettes[theme] || palettes[''];
		var selIndex = 0;
		for (var i = 0; i < 8; i++) {
			var el = doc.getElementById('setColor' + (i + 1));
			if (!el) { continue; }
			if (el.classList && el.classList.contains('colorSelected')) { selIndex = i; }
			el.setAttribute('data-color', pal[i]);
			el.style.backgroundColor = pal[i];
		}
		if (controller && typeof controller.setFillColor === 'function') {
			controller.setFillColor(pal[selIndex] || pal[0]);
		}
	}

	return { palettes: palettes, apply: apply };
})();
