// src/chrome/splitsWidget.js
//
// SVG port of the original canvas-based SplitsWidget (splitswidget.js).
// The original drew, into a 2D canvas context, a filled background rect in
// `this.color` and then N stroked rects (red stroke "#FF3333") laid out across
// the width (vertical splits) or down the height (horizontal splits).
//
// Here we rebuild the SVG tree deterministically on refresh() using
// createElementNS only (no innerHTML). Each cell is a single <rect> that
// carries the fill color and the red stroke, so N splits => N <rect> elements.
FB.SplitsWidget = FB.SplitsWidget || {};

(function () {
	var SVGNS = 'http://www.w3.org/2000/svg';

	FB.SplitsWidget.create = function (svgEl, doc) {
		var vertical = true;
		var numSplits = 2;
		var color = 'yellow';

		function num(attr, fallback) {
			var v = parseFloat(svgEl.getAttribute(attr));
			return isFinite(v) && v > 0 ? v : fallback;
		}

		function rect(x, y, w, h) {
			var r = doc.createElementNS(SVGNS, 'rect');
			r.setAttribute('x', x);
			r.setAttribute('y', y);
			r.setAttribute('width', w);
			r.setAttribute('height', h);
			r.setAttribute('fill', color);
			r.setAttribute('stroke', '#FF3333');
			r.setAttribute('stroke-width', 1);
			return r;
		}

		var widget = {
			setVertical: function (b) {
				vertical = !!b;
				return widget;
			},
			setNumSplits: function (n) {
				var v = parseInt(n, 10);
				if (isFinite(v) && v >= 1) {
					numSplits = v;
				}
				return widget;
			},
			setColor: function (c) {
				if (c) {
					color = c;
				}
				return widget;
			},
			refresh: function () {
				svgEl.replaceChildren();
				var width = num('width', 100);
				var height = num('height', 100);
				var i;
				if (vertical) {
					var cw = width / numSplits;
					for (i = 0; i < numSplits; i++) {
						svgEl.appendChild(rect(i * cw, 0, cw, height));
					}
				} else {
					var ch = height / numSplits;
					for (i = 0; i < numSplits; i++) {
						svgEl.appendChild(rect(0, i * ch, width, ch));
					}
				}
				return widget;
			}
		};

		return widget;
	};
})();
