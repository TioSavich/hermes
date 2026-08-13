/*
 * grapher.js - deterministic JSON-to-SVG renderer for coordinate planes,
 * bar charts, and dot plots. It computes presentation geometry only.
 *
 * Browser: window.HermesGrapher.renderInto(element, spec)
 * Node:    const { renderSpec, validateSpec } = require('./grapher.js')
 */
(function (root, factory) {
  'use strict';
  var api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  if (root) root.HermesGrapher = api;
}(typeof globalThis !== 'undefined' ? globalThis : this, function () {
  'use strict';

  var DEFAULT_WIDTH = 640;
  var DEFAULT_HEIGHT = 420;
  // 'stretch' fills the plot rectangle on each axis separately, which is what a
  // function graph wants. 'equal' gives one unit the same pixels both ways,
  // which is what a figure wants: a square draws square, and a length measured
  // off the picture means the same thing whichever way it runs.
  var ASPECTS = ['stretch', 'equal'];
  var COLORS = {
    paper: '#fffdf7',
    ink: '#1b1810',
    muted: '#665f4f',
    grid: '#d8cfbd',
    accent: '#2f7d6e',
    secondary: '#3f7f89',
    gold: '#a97c24',
    point: '#b5563f'
  };

  function fail(message) {
    throw new TypeError('Hermes grapher spec: ' + message);
  }

  function isObject(value) {
    return value !== null && typeof value === 'object' && !Array.isArray(value);
  }

  function isFiniteNumber(value) {
    return typeof value === 'number' && Number.isFinite(value);
  }

  function requireNumber(value, path) {
    if (!isFiniteNumber(value)) fail(path + ' must be a finite number');
  }

  function requireText(value, path) {
    if (typeof value !== 'string' || value.trim() === '') {
      fail(path + ' must be a non-empty string');
    }
  }

  function validatePoint(point, path) {
    if (!isObject(point)) fail(path + ' must be an object');
    requireNumber(point.x, path + '.x');
    requireNumber(point.y, path + '.y');
    if (point.label !== undefined) requireText(point.label, path + '.label');
    if (point.color !== undefined) requireText(point.color, path + '.color');
  }

  function validateCanvas(canvas) {
    if (canvas === undefined) return;
    if (!isObject(canvas)) fail('canvas must be an object');
    if (canvas.width !== undefined) {
      requireNumber(canvas.width, 'canvas.width');
      if (canvas.width < 320 || canvas.width > 1600) fail('canvas.width must be 320..1600');
    }
    if (canvas.height !== undefined) {
      requireNumber(canvas.height, 'canvas.height');
      if (canvas.height < 240 || canvas.height > 1200) fail('canvas.height must be 240..1200');
    }
  }

  function validateAxes(axes) {
    if (axes === undefined) return;
    if (!isObject(axes)) fail('axes must be an object');
    ['xMin', 'xMax', 'yMin', 'yMax', 'tickStep'].forEach(function (key) {
      if (axes[key] !== undefined) requireNumber(axes[key], 'axes.' + key);
    });
    if (axes.xMin !== undefined && axes.xMax !== undefined && axes.xMin >= axes.xMax) {
      fail('axes.xMin must be less than axes.xMax');
    }
    if (axes.yMin !== undefined && axes.yMax !== undefined && axes.yMin >= axes.yMax) {
      fail('axes.yMin must be less than axes.yMax');
    }
    if (axes.tickStep !== undefined && axes.tickStep <= 0) fail('axes.tickStep must be positive');
    ['xLabel', 'yLabel'].forEach(function (key) {
      if (axes[key] !== undefined) requireText(axes[key], 'axes.' + key);
    });
    if (axes.show !== undefined && typeof axes.show !== 'boolean') {
      fail('axes.show must be true or false');
    }
    if (axes.aspect !== undefined && ASPECTS.indexOf(axes.aspect) < 0) {
      fail("axes.aspect must be 'stretch' or 'equal'");
    }
  }

  function validateCoordinateSpec(spec) {
    validateAxes(spec.axes);
    var points = spec.points === undefined ? [] : spec.points;
    var lines = spec.lines === undefined ? [] : spec.lines;
    if (!Array.isArray(points)) fail('points must be an array');
    if (!Array.isArray(lines)) fail('lines must be an array');
    points.forEach(function (point, index) { validatePoint(point, 'points[' + index + ']'); });
    lines.forEach(function (line, index) {
      var path = 'lines[' + index + ']';
      if (!isObject(line)) fail(path + ' must be an object');
      if (['slope-intercept', 'through-points', 'segment'].indexOf(line.type) < 0) {
        fail(path + '.type is not supported');
      }
      if (line.type === 'slope-intercept') {
        requireNumber(line.slope, path + '.slope');
        requireNumber(line.intercept, path + '.intercept');
      } else if (line.type === 'through-points') {
        if (!Array.isArray(line.points) || line.points.length !== 2) {
          fail(path + '.points must contain exactly two points');
        }
        validatePoint(line.points[0], path + '.points[0]');
        validatePoint(line.points[1], path + '.points[1]');
        if (line.points[0].x === line.points[1].x && line.points[0].y === line.points[1].y) {
          fail(path + '.points must be distinct');
        }
      } else {
        validatePoint(line.from, path + '.from');
        validatePoint(line.to, path + '.to');
      }
      if (line.label !== undefined) requireText(line.label, path + '.label');
      if (line.color !== undefined) requireText(line.color, path + '.color');
    });
    if (points.length === 0 && lines.length === 0) fail('coordinate-plane needs a point or line');
  }

  function validateBarSpec(spec) {
    if (!Array.isArray(spec.categories) || spec.categories.length === 0) {
      fail('bar-chart categories must be a non-empty array');
    }
    spec.categories.forEach(function (category, index) {
      var path = 'categories[' + index + ']';
      if (!isObject(category)) fail(path + ' must be an object');
      requireText(category.label, path + '.label');
      requireNumber(category.value, path + '.value');
      if (category.value < 0) fail(path + '.value must be nonnegative');
      if (category.color !== undefined) requireText(category.color, path + '.color');
    });
    validateAxes(spec.axes);
  }

  function validateDotSpec(spec) {
    if (!Array.isArray(spec.values) || spec.values.length === 0) {
      fail('dot-plot values must be a non-empty array');
    }
    spec.values.forEach(function (value, index) { requireNumber(value, 'values[' + index + ']'); });
    validateAxes(spec.axes);
  }

  function validateSpec(spec) {
    if (!isObject(spec)) fail('root must be an object');
    if (spec.version !== 1) fail('version must be 1');
    requireText(spec.id, 'id');
    requireText(spec.title, 'title');
    if (spec.description !== undefined) requireText(spec.description, 'description');
    validateCanvas(spec.canvas);
    if (spec.kind === 'coordinate-plane') validateCoordinateSpec(spec);
    else if (spec.kind === 'bar-chart') validateBarSpec(spec);
    else if (spec.kind === 'dot-plot') validateDotSpec(spec);
    else fail('kind must be coordinate-plane, bar-chart, or dot-plot');
    return spec;
  }

  function escapeText(value) {
    return String(value).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  }

  function escapeAttr(value) {
    return escapeText(value).replace(/"/g, '&quot;').replace(/'/g, '&#39;');
  }

  function safeId(value) {
    return String(value).toLowerCase().replace(/[^a-z0-9_-]+/g, '-').replace(/^-+|-+$/g, '') || 'graph';
  }

  function number(value) {
    var rounded = Math.round(value * 1000000) / 1000000;
    if (Object.is(rounded, -0)) rounded = 0;
    return String(rounded);
  }

  function labelNumber(value) {
    var rounded = Math.round(value * 1000000) / 1000000;
    if (Object.is(rounded, -0)) rounded = 0;
    return Number.isInteger(rounded) ? String(rounded) : String(rounded).replace(/0+$/, '').replace(/\.$/, '');
  }

  function attrs(values) {
    return Object.keys(values).filter(function (key) {
      return values[key] !== undefined && values[key] !== null;
    }).map(function (key) {
      return ' ' + key + '="' + escapeAttr(values[key]) + '"';
    }).join('');
  }

  function tag(name, values, content) {
    return '<' + name + attrs(values || {}) + '>' + (content || '') + '</' + name + '>';
  }

  function emptyTag(name, values) {
    return '<' + name + attrs(values || {}) + '></' + name + '>';
  }

  function niceStep(span, targetTicks) {
    if (!(span > 0)) return 1;
    var rough = span / (targetTicks || 8);
    var power = Math.pow(10, Math.floor(Math.log10(rough)));
    var fraction = rough / power;
    var nice = fraction <= 1 ? 1 : fraction <= 2 ? 2 : fraction <= 5 ? 5 : 10;
    return nice * power;
  }

  function niceBounds(minimum, maximum, step, includeZero) {
    var min = minimum;
    var max = maximum;
    if (!isFiniteNumber(min) || !isFiniteNumber(max)) { min = -5; max = 5; }
    if (includeZero) { min = Math.min(min, 0); max = Math.max(max, 0); }
    if (min === max) {
      var delta = Math.abs(min) > 1 ? Math.abs(min) * 0.2 : 1;
      min -= delta;
      max += delta;
    }
    var resolvedStep = step || niceStep(max - min, 8);
    var padding = resolvedStep * 0.5;
    return {
      min: Math.floor((min - padding) / resolvedStep) * resolvedStep,
      max: Math.ceil((max + padding) / resolvedStep) * resolvedStep,
      step: resolvedStep
    };
  }

  function tickValues(min, max, step) {
    var values = [];
    var first = Math.ceil((min - step * 1e-9) / step) * step;
    var limit = 1000;
    for (var index = 0, value = first; value <= max + step * 1e-9 && index < limit; index += 1, value = first + (index * step)) {
      values.push(Math.round(value * 1000000000) / 1000000000);
    }
    return values;
  }

  function pointValues(spec) {
    var values = (spec.points || []).map(function (point) { return { x: point.x, y: point.y }; });
    (spec.lines || []).forEach(function (line) {
      if (line.type === 'through-points') values = values.concat(line.points);
      else if (line.type === 'segment') values.push(line.from, line.to);
    });
    return values;
  }

  function coordinateDomain(spec) {
    var axes = spec.axes || {};
    var values = pointValues(spec);
    var xs = values.map(function (point) { return point.x; });
    var ys = values.map(function (point) { return point.y; });
    var hasSlope = (spec.lines || []).some(function (line) { return line.type === 'slope-intercept'; });
    if (xs.length === 0) xs = [-5, 5];
    var rawXMin = axes.xMin !== undefined ? axes.xMin : Math.min.apply(null, xs);
    var rawXMax = axes.xMax !== undefined ? axes.xMax : Math.max.apply(null, xs);
    var xStep = axes.tickStep || niceStep(rawXMax - rawXMin, 8);
    if (rawXMax <= rawXMin) {
      if (axes.xMin !== undefined && axes.xMax === undefined) rawXMax = rawXMin + xStep;
      else if (axes.xMax !== undefined && axes.xMin === undefined) rawXMin = rawXMax - xStep;
      else { rawXMin -= xStep; rawXMax += xStep; }
    }
    var x = niceBounds(
      rawXMin,
      rawXMax,
      xStep,
      true
    );
    if (axes.xMin !== undefined) x.min = axes.xMin;
    if (axes.xMax !== undefined) x.max = axes.xMax;
    if (hasSlope) {
      (spec.lines || []).forEach(function (line) {
        if (line.type === 'slope-intercept') {
          ys.push(line.slope * x.min + line.intercept, line.slope * x.max + line.intercept);
        }
      });
    }
    if (ys.length === 0) ys = [-5, 5];
    var rawYMin = axes.yMin !== undefined ? axes.yMin : Math.min.apply(null, ys);
    var rawYMax = axes.yMax !== undefined ? axes.yMax : Math.max.apply(null, ys);
    var yStep = axes.tickStep || niceStep(rawYMax - rawYMin, 8);
    if (rawYMax <= rawYMin) {
      if (axes.yMin !== undefined && axes.yMax === undefined) rawYMax = rawYMin + yStep;
      else if (axes.yMax !== undefined && axes.yMin === undefined) rawYMin = rawYMax - yStep;
      else { rawYMin -= yStep; rawYMax += yStep; }
    }
    var y = niceBounds(
      rawYMin,
      rawYMax,
      yStep,
      true
    );
    if (axes.yMin !== undefined) y.min = axes.yMin;
    if (axes.yMax !== undefined) y.max = axes.yMax;
    return { xMin: x.min, xMax: x.max, yMin: y.min, yMax: y.max, xStep: x.step, yStep: y.step };
  }

  // Whether the coordinate apparatus is drawn at all: frame, gridlines, tick
  // labels, axis lines, axis labels. With it off the same spec becomes a plain
  // drawing surface, and the marks land exactly where they would have landed.
  function axesShown(spec) {
    return !(spec.axes && spec.axes.show === false);
  }

  function equalAspect(spec) {
    return !!(spec.axes && spec.axes.aspect === 'equal');
  }

  // Grow the domain, never crop it, until one unit spans the same pixels on
  // both axes. The axis with room to spare is the one that grows, about its own
  // centre, so everything the caller asked to show stays inside the plot.
  function equalizeDomain(domain, plot) {
    var xSpan = domain.xMax - domain.xMin;
    var ySpan = domain.yMax - domain.yMin;
    if (!(xSpan > 0) || !(ySpan > 0) || !(plot.width > 0) || !(plot.height > 0)) return domain;
    var scale = Math.min(plot.width / xSpan, plot.height / ySpan);
    var halfX = plot.width / (2 * scale);
    var halfY = plot.height / (2 * scale);
    var centerX = (domain.xMin + domain.xMax) / 2;
    var centerY = (domain.yMin + domain.yMax) / 2;
    return {
      xMin: centerX - halfX, xMax: centerX + halfX,
      yMin: centerY - halfY, yMax: centerY + halfY,
      xStep: domain.xStep, yStep: domain.yStep
    };
  }

  function maps(domain, plot) {
    return {
      x: function (value) { return plot.left + ((value - domain.xMin) / (domain.xMax - domain.xMin)) * plot.width; },
      y: function (value) { return plot.top + ((domain.yMax - value) / (domain.yMax - domain.yMin)) * plot.height; }
    };
  }

  function inRange(value, min, max) {
    return value >= min - 1e-8 && value <= max + 1e-8;
  }

  function dedupePoints(points) {
    var seen = {};
    return points.filter(function (point) {
      var key = number(point.x) + ',' + number(point.y);
      if (seen[key]) return false;
      seen[key] = true;
      return true;
    });
  }

  function clipInfiniteLine(line, domain) {
    var x1;
    var y1;
    var x2;
    var y2;
    if (line.type === 'slope-intercept') {
      x1 = 0; y1 = line.intercept; x2 = 1; y2 = line.slope + line.intercept;
    } else {
      x1 = line.points[0].x; y1 = line.points[0].y;
      x2 = line.points[1].x; y2 = line.points[1].y;
    }
    var dx = x2 - x1;
    var dy = y2 - y1;
    var hits = [];
    if (dx !== 0) {
      [domain.xMin, domain.xMax].forEach(function (x) {
        var y = y1 + ((x - x1) / dx) * dy;
        if (inRange(y, domain.yMin, domain.yMax)) hits.push({ x: x, y: y });
      });
    }
    if (dy !== 0) {
      [domain.yMin, domain.yMax].forEach(function (y) {
        var x = x1 + ((y - y1) / dy) * dx;
        if (inRange(x, domain.xMin, domain.xMax)) hits.push({ x: x, y: y });
      });
    }
    hits = dedupePoints(hits);
    if (hits.length < 2) return null;
    var best = [hits[0], hits[1]];
    var distance = -1;
    hits.forEach(function (a) {
      hits.forEach(function (b) {
        var d = Math.pow(a.x - b.x, 2) + Math.pow(a.y - b.y, 2);
        if (d > distance) { distance = d; best = [a, b]; }
      });
    });
    return best;
  }

  function baseSvg(spec, content, description) {
    var width = (spec.canvas && spec.canvas.width) || DEFAULT_WIDTH;
    var height = (spec.canvas && spec.canvas.height) || DEFAULT_HEIGHT;
    var id = safeId(spec.id);
    var titleId = id + '-title';
    var descId = id + '-desc';
    return '<svg' + attrs({
      xmlns: 'http://www.w3.org/2000/svg',
      viewBox: '0 0 ' + number(width) + ' ' + number(height),
      role: 'img',
      'aria-labelledby': titleId + ' ' + descId,
      'data-hermes-renderer': 'grapher-v1',
      'data-hermes-kind': spec.kind,
      'data-spec-id': spec.id,
      // Present only when the caller asked for something other than the
      // default, so a scene that says nothing renders exactly as before.
      'data-axes-shown': (spec.kind === 'coordinate-plane' && !axesShown(spec)) ? 'false' : undefined,
      'data-aspect': (spec.kind === 'coordinate-plane' && equalAspect(spec)) ? 'equal' : undefined
    }) + '>' +
      tag('title', { id: titleId }, escapeText(spec.title)) +
      tag('desc', { id: descId }, escapeText(description || spec.description || spec.title)) +
      emptyTag('rect', { width: width, height: height, fill: COLORS.paper, class: 'graph-background' }) +
      content + '</svg>';
  }

  function textNode(x, y, content, options) {
    var opts = options || {};
    return tag('text', {
      x: number(x), y: number(y),
      fill: opts.fill || COLORS.ink,
      'font-family': opts.family || 'system-ui, sans-serif',
      'font-size': opts.size || 12,
      'font-weight': opts.weight,
      'text-anchor': opts.anchor || 'middle',
      'dominant-baseline': opts.baseline,
      transform: opts.transform,
      class: opts.className
    }, escapeText(content));
  }

  function renderCoordinate(spec) {
    var width = (spec.canvas && spec.canvas.width) || DEFAULT_WIDTH;
    var height = (spec.canvas && spec.canvas.height) || DEFAULT_HEIGHT;
    var plot = { left: 64, top: 42, width: width - 96, height: height - 96 };
    var domain = coordinateDomain(spec);
    if (equalAspect(spec)) domain = equalizeDomain(domain, plot);
    var map = maps(domain, plot);
    var out = [];
    if (axesShown(spec)) {
      out.push(emptyTag('rect', {
        x: plot.left, y: plot.top, width: plot.width, height: plot.height,
        fill: 'none', stroke: COLORS.ink, 'stroke-width': 1, class: 'plot-frame'
      }));
      tickValues(domain.xMin, domain.xMax, domain.xStep).forEach(function (value) {
        var x = map.x(value);
        out.push(emptyTag('line', { x1: number(x), y1: plot.top, x2: number(x), y2: plot.top + plot.height, stroke: COLORS.grid, 'stroke-width': 0.8, class: 'gridline gridline-x', 'data-value': labelNumber(value) }));
        out.push(textNode(x, plot.top + plot.height + 19, labelNumber(value), { size: 11, fill: COLORS.muted, className: 'tick-label tick-label-x' }));
      });
      tickValues(domain.yMin, domain.yMax, domain.yStep).forEach(function (value) {
        var y = map.y(value);
        out.push(emptyTag('line', { x1: plot.left, y1: number(y), x2: plot.left + plot.width, y2: number(y), stroke: COLORS.grid, 'stroke-width': 0.8, class: 'gridline gridline-y', 'data-value': labelNumber(value) }));
        out.push(textNode(plot.left - 10, y, labelNumber(value), { size: 11, fill: COLORS.muted, anchor: 'end', baseline: 'central', className: 'tick-label tick-label-y' }));
      });
      var axisY = inRange(0, domain.yMin, domain.yMax) ? map.y(0) : map.y(domain.yMin);
      var axisX = inRange(0, domain.xMin, domain.xMax) ? map.x(0) : map.x(domain.xMin);
      out.push(emptyTag('line', { x1: plot.left, y1: number(axisY), x2: plot.left + plot.width, y2: number(axisY), stroke: COLORS.ink, 'stroke-width': 1.7, class: 'axis axis-x' }));
      out.push(emptyTag('line', { x1: number(axisX), y1: plot.top, x2: number(axisX), y2: plot.top + plot.height, stroke: COLORS.ink, 'stroke-width': 1.7, class: 'axis axis-y' }));
      if (spec.axes && spec.axes.xLabel) out.push(textNode(plot.left + plot.width, height - 12, spec.axes.xLabel, { size: 12, anchor: 'end', weight: 600, className: 'axis-label axis-label-x' }));
      if (spec.axes && spec.axes.yLabel) out.push(textNode(16, plot.top, spec.axes.yLabel, { size: 12, anchor: 'start', weight: 600, className: 'axis-label axis-label-y' }));
    }
    (spec.lines || []).forEach(function (line, index) {
      var endpoints = line.type === 'segment' ? [line.from, line.to] : clipInfiniteLine(line, domain);
      if (!endpoints) return;
      var x1 = map.x(endpoints[0].x);
      var y1 = map.y(endpoints[0].y);
      var x2 = map.x(endpoints[1].x);
      var y2 = map.y(endpoints[1].y);
      out.push(emptyTag('line', {
        x1: number(x1), y1: number(y1), x2: number(x2), y2: number(y2),
        stroke: line.color || (index % 2 ? COLORS.secondary : COLORS.accent),
        'stroke-width': line.type === 'segment' ? 3 : 2.4,
        'stroke-linecap': 'round',
        class: 'data-line data-line-' + line.type,
        'data-line-type': line.type,
        'data-label': line.label
      }));
      if (line.label) out.push(textNode((x1 + x2) / 2 + 6, (y1 + y2) / 2 - 10, line.label, { size: 12, fill: line.color || COLORS.accent, anchor: 'start', weight: 600, className: 'line-label' }));
    });
    (spec.points || []).forEach(function (point) {
      var x = map.x(point.x);
      var y = map.y(point.y);
      out.push(emptyTag('circle', { cx: number(x), cy: number(y), r: 5.5, fill: point.color || COLORS.point, stroke: COLORS.ink, 'stroke-width': 1, class: 'data-point', 'data-x': number(point.x), 'data-y': number(point.y), 'data-label': point.label }));
      if (point.label) out.push(textNode(x + 9, y - 10, point.label, { size: 12, fill: COLORS.ink, anchor: 'start', weight: 600, className: 'point-label' }));
    });
    return baseSvg(spec, out.join(''), 'Cartesian coordinate plane. ' + (spec.description || spec.title));
  }

  function renderBar(spec) {
    var width = (spec.canvas && spec.canvas.width) || DEFAULT_WIDTH;
    var height = (spec.canvas && spec.canvas.height) || DEFAULT_HEIGHT;
    var plot = { left: 70, top: 42, width: width - 102, height: height - 116 };
    var axes = spec.axes || {};
    var values = spec.categories.map(function (category) { return category.value; });
    var requestedMax = axes.yMax !== undefined ? axes.yMax : Math.max.apply(null, values);
    var yBounds = niceBounds(axes.yMin !== undefined ? axes.yMin : 0, requestedMax, axes.tickStep, true);
    if (axes.yMin !== undefined) yBounds.min = axes.yMin;
    if (axes.yMax !== undefined) yBounds.max = axes.yMax;
    if (yBounds.max <= yBounds.min) fail('bar-chart y-axis range must be positive');
    var y = function (value) { return plot.top + ((yBounds.max - value) / (yBounds.max - yBounds.min)) * plot.height; };
    var baseline = y(0);
    var slot = plot.width / spec.categories.length;
    var barWidth = Math.min(72, slot * 0.66);
    var out = [];
    tickValues(yBounds.min, yBounds.max, yBounds.step).forEach(function (value) {
      var py = y(value);
      out.push(emptyTag('line', { x1: plot.left, y1: number(py), x2: plot.left + plot.width, y2: number(py), stroke: COLORS.grid, 'stroke-width': 0.8, class: 'gridline gridline-y', 'data-value': labelNumber(value) }));
      out.push(textNode(plot.left - 10, py, labelNumber(value), { size: 11, fill: COLORS.muted, anchor: 'end', baseline: 'central', className: 'tick-label tick-label-y' }));
    });
    out.push(emptyTag('line', { x1: plot.left, y1: plot.top, x2: plot.left, y2: baseline, stroke: COLORS.ink, 'stroke-width': 1.7, class: 'axis axis-y' }));
    out.push(emptyTag('line', { x1: plot.left, y1: number(baseline), x2: plot.left + plot.width, y2: number(baseline), stroke: COLORS.ink, 'stroke-width': 1.7, class: 'axis axis-x' }));
    spec.categories.forEach(function (category, index) {
      var cx = plot.left + slot * (index + 0.5);
      var top = y(category.value);
      var barHeight = Math.max(0, baseline - top);
      out.push(emptyTag('rect', { x: number(cx - barWidth / 2), y: number(top), width: number(barWidth), height: number(barHeight), fill: category.color || (index % 2 ? COLORS.secondary : COLORS.accent), stroke: COLORS.ink, 'stroke-width': 1, class: 'data-bar', 'data-label': category.label, 'data-value': number(category.value) }));
      out.push(textNode(cx, top - 9, labelNumber(category.value), { size: 12, weight: 600, className: 'bar-value' }));
      out.push(textNode(cx, baseline + 20, category.label, { size: 11, fill: COLORS.muted, className: 'category-label' }));
    });
    if (axes.xLabel) out.push(textNode(plot.left + plot.width / 2, height - 13, axes.xLabel, { size: 12, weight: 600, className: 'axis-label axis-label-x' }));
    if (axes.yLabel) out.push(textNode(18, plot.top + plot.height / 2, axes.yLabel, { size: 12, weight: 600, transform: 'rotate(-90 18 ' + number(plot.top + plot.height / 2) + ')', className: 'axis-label axis-label-y' }));
    return baseSvg(spec, out.join(''), 'Bar chart. ' + (spec.description || spec.title));
  }

  function renderDot(spec) {
    var width = (spec.canvas && spec.canvas.width) || DEFAULT_WIDTH;
    var height = (spec.canvas && spec.canvas.height) || DEFAULT_HEIGHT;
    var plot = { left: 70, top: 44, width: width - 104, height: height - 112 };
    var axes = spec.axes || {};
    var minValue = Math.min.apply(null, spec.values);
    var maxValue = Math.max.apply(null, spec.values);
    var bounds = niceBounds(axes.xMin !== undefined ? axes.xMin : minValue, axes.xMax !== undefined ? axes.xMax : maxValue, axes.tickStep, false);
    if (axes.xMin !== undefined) bounds.min = axes.xMin;
    if (axes.xMax !== undefined) bounds.max = axes.xMax;
    var x = function (value) { return plot.left + ((value - bounds.min) / (bounds.max - bounds.min)) * plot.width; };
    var baseline = plot.top + plot.height;
    var counts = {};
    spec.values.forEach(function (value) {
      var key = number(value);
      counts[key] = (counts[key] || 0) + 1;
    });
    var out = [];
    out.push(emptyTag('line', { x1: plot.left, y1: baseline, x2: plot.left + plot.width, y2: baseline, stroke: COLORS.ink, 'stroke-width': 1.7, class: 'axis axis-x' }));
    tickValues(bounds.min, bounds.max, bounds.step).forEach(function (value) {
      var px = x(value);
      out.push(emptyTag('line', { x1: number(px), y1: baseline - 5, x2: number(px), y2: baseline + 5, stroke: COLORS.ink, 'stroke-width': 1, class: 'tick tick-x', 'data-value': labelNumber(value) }));
      out.push(textNode(px, baseline + 20, labelNumber(value), { size: 11, fill: COLORS.muted, className: 'tick-label tick-label-x' }));
    });
    Object.keys(counts).map(Number).sort(function (a, b) { return a - b; }).forEach(function (value) {
      for (var stack = 0; stack < counts[number(value)]; stack += 1) {
        out.push(emptyTag('circle', { cx: number(x(value)), cy: number(baseline - 13 - stack * 19), r: 7, fill: COLORS.gold, stroke: COLORS.ink, 'stroke-width': 1, class: 'data-dot', 'data-value': number(value), 'data-stack': stack + 1 }));
      }
    });
    if (axes.xLabel) out.push(textNode(plot.left + plot.width / 2, height - 12, axes.xLabel, { size: 12, weight: 600, className: 'axis-label axis-label-x' }));
    return baseSvg(spec, out.join(''), 'Dot plot with ' + spec.values.length + ' values. ' + (spec.description || spec.title));
  }

  function renderSpec(spec) {
    validateSpec(spec);
    if (spec.kind === 'coordinate-plane') return renderCoordinate(spec);
    if (spec.kind === 'bar-chart') return renderBar(spec);
    return renderDot(spec);
  }

  function renderInto(target, spec) {
    if (!target || typeof target.innerHTML !== 'string') fail('render target must be an element');
    var svg = renderSpec(spec);
    target.innerHTML = svg;
    return svg;
  }

  return {
    renderSpec: renderSpec,
    renderInto: renderInto,
    validateSpec: validateSpec
  };
}));
