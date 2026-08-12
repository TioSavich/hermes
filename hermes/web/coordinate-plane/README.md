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
  `xLabel`, and `yLabel`. Omitted bounds are derived from the supplied points
  and lines, include zero, and are rounded to readable tick intervals.
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
