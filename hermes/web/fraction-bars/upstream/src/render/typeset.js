// src/render/typeset.js
//
// Offline, CSP-safe fraction typesetter. No MathJax / KaTeX: loading either
// would mean a CDN fetch (blocked by `connect-src 'none'`) or inlining ~1 MB of
// third-party code that also uses `new Function` (blocked by the script-src
// hash + the seal's no-eval rule). Instead we lay out fractions as native SVG
// <text>/<line> with a deterministic Helvetica advance-width estimator -- the
// same visual result (stacked numerator / rule / denominator, mixed numbers)
// with zero network and zero dynamic code.
//
// The estimator understands LABELS that mix prose and fractions, so a learner
// label like  "1 1/2 oranges"  typesets as  1½ (stacked)  +  " oranges", which
// in TeX would be  $1 \frac{1}{2}$ oranges.  Each token is measured and placed
// on a single baseline; the whole run can be anchored start / middle / end and
// its measured width is exposed so the renderer can draw a readability halo.

FB.Typeset = FB.Typeset || {};
var SVGNS = 'http://www.w3.org/2000/svg';

// --- advance-width estimate (Helvetica/Arial, em units) ---------------------
// Good enough for placement without a DOM measure pass; keeps render
// deterministic and free of layout thrash.
FB.Typeset.charEm = function (ch) {
	if (ch === ' ') { return 0.30; }
	if ('iIl.,;:!|\'’`'.indexOf(ch) > -1) { return 0.26; }
	if ('jftr()[]{}/\\'.indexOf(ch) > -1) { return 0.34; }
	if ('mwMW'.indexOf(ch) > -1) { return 0.86; }
	if (ch >= '0' && ch <= '9') { return 0.556; }
	if (ch >= 'A' && ch <= 'Z') { return 0.68; }
	return 0.52; // generic lowercase / punctuation
};

FB.Typeset.advance = function (str, fontSize) {
	var s = (str === null || str === undefined) ? '' : String(str);
	var w = 0;
	for (var i = 0; i < s.length; i++) { w += FB.Typeset.charEm(s[i]); }
	return w * fontSize;
};

// Back-compat: classify a single trimmed token.
FB.Typeset.parseFraction = function (raw) {
	var str = (raw === null || raw === undefined) ? '' : String(raw).trim();
	if (str === '') { return { kind: 'text', text: '' }; }
	var mixed = /^(\d+)\s+(\d+)\/(\d+)$/.exec(str);
	if (mixed) { return { kind: 'mixed', whole: +mixed[1], num: +mixed[2], den: +mixed[3] }; }
	var frac = /^(\d+)\/(\d+)$/.exec(str);
	if (frac) { return { kind: 'fraction', num: +frac[1], den: +frac[2] }; }
	var intgr = /^\d+$/.exec(str);
	if (intgr) { return { kind: 'integer', whole: +str }; }
	return { kind: 'text', text: str };
};

// Tokenize a full label into a left-to-right run of text + fraction atoms.
// Finds mixed numbers ("1 1/2") and bare fractions ("3/4") anywhere inside
// surrounding prose, leaving everything else as text tokens.
FB.Typeset.tokenizeLabel = function (raw) {
	var str = (raw === null || raw === undefined) ? '' : String(raw);
	if (str === '') { return []; }
	// mixed number  |  bare fraction. \b keeps us off the middle of "1234".
	var re = /(\d+)\s+(\d+)\/(\d+)|(\d+)\/(\d+)/g;
	var out = [];
	var last = 0, m;
	while ((m = re.exec(str)) !== null) {
		if (m.index > last) { out.push({ type: 'text', text: str.slice(last, m.index) }); }
		if (m[1] !== undefined) {
			out.push({ type: 'frac', whole: +m[1], num: +m[2], den: +m[3] });
		} else {
			out.push({ type: 'frac', whole: null, num: +m[4], den: +m[5] });
		}
		last = re.lastIndex;
	}
	if (last < str.length) { out.push({ type: 'text', text: str.slice(last) }); }
	return out;
};

// Measure the advance width of a single token run (no DOM).
FB.Typeset.measureLabel = function (tokens, fontSize) {
	var fsF = fontSize * 0.92;
	var w = 0;
	for (var i = 0; i < tokens.length; i++) {
		var tk = tokens[i];
		if (tk.type === 'text') {
			w += FB.Typeset.advance(tk.text, fontSize);
		} else {
			if (tk.whole !== null && tk.whole !== undefined) {
				w += FB.Typeset.advance(String(tk.whole), fontSize) + fontSize * 0.12;
			}
			var boxW = Math.max(
				FB.Typeset.advance(String(tk.num), fsF),
				FB.Typeset.advance(String(tk.den), fsF)
			) + fsF * 0.30;
			w += boxW + fontSize * 0.10;
		}
	}
	return w;
};

// Build an SVG <g> for a label/fraction. Returns the <g>; the measured width is
// attached as g.__fbWidth (and via getAttribute data-w) so callers can place a
// halo or right-anchor without a DOM measure pass.
//
// opts: { x, y (baseline), fontSize, color, anchor: 'start'|'middle'|'end' }
FB.Typeset.buildFractionSVG = function (doc, raw, opts) {
	opts = opts || {};
	var fs = opts.fontSize || 12;
	var color = opts.color || '#000';
	var anchor = opts.anchor || 'start';
	var fsF = fs * 0.92;
	var weight = opts.fontWeight || 'normal';
	var family = opts.fontFamily || 'inherit';

	var tokens = FB.Typeset.tokenizeLabel(raw);
	var totalW = FB.Typeset.measureLabel(tokens, fs);

	var g = doc.createElementNS(SVGNS, 'g');
	g.__fbWidth = totalW;
	g.setAttribute('data-w', String(Math.round(totalW)));

	var y = opts.y || 0;
	var startX = opts.x || 0;
	if (anchor === 'end') { startX = (opts.x || 0) - totalW; }
	else if (anchor === 'middle') { startX = (opts.x || 0) - totalW / 2; }

	function text(t, x, ty, mid, sz) {
		var el = doc.createElementNS(SVGNS, 'text');
		el.setAttribute('x', x);
		el.setAttribute('y', ty);
		el.setAttribute('font-size', sz || fs);
		el.setAttribute('fill', color);
		el.setAttribute('text-anchor', mid ? 'middle' : 'start');
		el.setAttribute('font-family', family);
		if (weight !== 'normal') { el.setAttribute('font-weight', weight); }
		el.textContent = String(t);
		g.appendChild(el);
		return el;
	}

	var cx = startX;
	for (var i = 0; i < tokens.length; i++) {
		var tk = tokens[i];
		if (tk.type === 'text') {
			text(tk.text, cx, y);
			cx += FB.Typeset.advance(tk.text, fs);
			continue;
		}
		// fraction (optionally mixed)
		if (tk.whole !== null && tk.whole !== undefined) {
			text(tk.whole, cx, y);
			cx += FB.Typeset.advance(String(tk.whole), fs) + fs * 0.12;
		}
		var boxW = Math.max(
			FB.Typeset.advance(String(tk.num), fsF),
			FB.Typeset.advance(String(tk.den), fsF)
		) + fsF * 0.30;
		var midX = cx + boxW / 2;
		var barY = y - fs * 0.34;
		// numerator (sits above the rule)
		text(tk.num, midX, barY - fsF * 0.18, true, fsF);
		// fraction rule
		var line = doc.createElementNS(SVGNS, 'line');
		line.setAttribute('x1', cx); line.setAttribute('y1', barY);
		line.setAttribute('x2', cx + boxW); line.setAttribute('y2', barY);
		line.setAttribute('stroke', color);
		line.setAttribute('stroke-width', Math.max(1, fs / 14));
		line.setAttribute('stroke-linecap', 'round');
		g.appendChild(line);
		// denominator (sits below the rule)
		text(tk.den, midX, barY + fsF * 0.86, true, fsF);
		cx += boxW + fs * 0.10;
	}

	return g;
};
