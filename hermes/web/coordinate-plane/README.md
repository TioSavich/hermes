# Coordinate-plane grapher

This directory contains a presentational JSON-to-SVG renderer for Cartesian
planes, bar charts, and dot plots. It draws the values in a specification. It
does not infer a relationship, fit a line, summarize a distribution, or call a
Hermes strategy machine.

Open `index.html` through the Hermes app or another static file server. The
demo embeds the four files in `samples/`, so its first render also works from a
local file URL. `grapher.js` has no package, CDN, or network dependency.

## Common schema

Every specification is one JSON object with these fields:

| Field | Required | Meaning |
|---|---:|---|
| `version` | yes | Schema version. The current value is `1`. |
| `id` | yes | Stable identifier used in SVG metadata and accessible element ids. |
| `kind` | yes | `coordinate-plane`, `bar-chart`, or `dot-plot`. |
| `title` | yes | Accessible SVG title. |
| `description` | no | Accessible description of the supplied marks. |
| `canvas` | no | `{ "width": 640, "height": 420 }`; width is 320..1600 and height is 240..1200. |

The object is suitable for a future trace field such as `scene`: it is plain
JSON, versioned, and contains only the data and display instructions needed by
the renderer. No machine wiring is part of this directory.

## Coordinate-plane schema

Set `kind` to `coordinate-plane`.

- `axes` is optional. It accepts `xMin`, `xMax`, `yMin`, `yMax`, `tickStep`,
  `xLabel`, `yLabel`, `show`, and `aspect`. Omitted bounds are derived from the
  supplied points and lines, include zero, and are rounded to readable tick
  intervals.
- `axes.show` is `true` by default. Set it to `false` for a drawing surface:
  no frame, no gridlines, no axis lines, no tick labels, and no axis labels.
  The points and lines land where they would have landed with the apparatus
  drawn, so a figure whose measurements are printed on it — a trapezoid with
  its angles marked, say — no longer arrives dressed as a graph.
- `axes.aspect` is `"stretch"` by default: each axis is fitted to the plot
  rectangle on its own, which suits a function graph and distorts a figure.
  Set it to `"equal"` to give one unit the same number of pixels both ways.
  The domain then grows on whichever axis has room — it is never cropped — so
  a square draws square and a length read off the picture means the same thing
  whichever way it runs. Supplied bounds are a floor under this setting, not an
  exact frame.

Both fields belong to the coordinate-plane renderer. The bar-chart and dot-plot
renderers accept them in a specification and do not act on them.

A rendered SVG carries `data-axes-shown="false"` or `data-aspect="equal"` only
when the specification asked for it, so a scene that says nothing about either
renders exactly the bytes it rendered before.
- `points` is an array of `{ "x": number, "y": number, "label": string?,
  "color": string? }` objects.
- `lines` is an array. Each line has an optional `label` and `color`, plus one
  of these shapes:

```json
{"type": "slope-intercept", "slope": 2, "intercept": -1}
{"type": "through-points", "points": [{"x": -2, "y": 1}, {"x": 3, "y": 4}]}
{"type": "segment", "from": {"x": -1, "y": -2}, "to": {"x": 2, "y": -2}}
```

Slope-intercept and through-points lines extend to the plot boundary. A segment
ends at its supplied endpoints. The renderer supports negative and positive
bounds in both directions.

## Bar-chart schema

Set `kind` to `bar-chart` and provide a non-empty `categories` array. Each row
has `label`, a nonnegative numeric `value`, and an optional `color`.

```json
{
  "version": 1,
  "id": "example-bars",
  "kind": "bar-chart",
  "title": "Example counts",
  "categories": [
    {"label": "A", "value": 4},
    {"label": "B", "value": 7}
  ]
}
```

`axes` may provide `xLabel`, `yLabel`, `yMin`, `yMax`, and `tickStep`.

## Dot-plot schema

Set `kind` to `dot-plot` and provide a non-empty numeric `values` array. Equal
values stack in input-count order.

```json
{
  "version": 1,
  "id": "example-dots",
  "kind": "dot-plot",
  "title": "Example values",
  "axes": {"xLabel": "Value", "tickStep": 1},
  "values": [1, 2, 2, 3]
}
```

`axes` may provide `xLabel`, `xMin`, `xMax`, and `tickStep`.

## Renderer API

In a browser:

```js
HermesGrapher.renderInto(document.getElementById("stage"), spec);
```

In Node:

```js
const { renderSpec, validateSpec } = require("./grapher.js");
validateSpec(spec);
const svg = renderSpec(spec);
```

For a valid specification, repeated `renderSpec(spec)` calls return the same
SVG bytes.
