# Render document contract, version 2

Hermes scene compilers return render documents. The browser and the offline
gallery exporter pass the same documents to `more-zeeman/render/drawer.js`.
The drawer serializes the supplied geometry and does not compute mathematical
results.

## Render document

A render document is a JSON object with these fields:

- `kind` is a string that identifies the worker operation or document family.
- `request` is an object or string containing the normalized request.
- `result` is an object, string, or number containing the computed result.
- `frames` is an array of frame objects.
- `canvas` is an optional object with width and height information.
- `productive` and `deformation` are optional nested render document parts.
- `tuple`, `grounding`, and `teacher` are optional audience-specific metadata.

An operation that cannot supply drawable output returns an error document with
an `error` string and either no frames or an annotation-only frame naming what
went unsourced — the fallback never fakes a picture, so the document may still
carry one frame the drawer can draw. Scalar worker operations do not use
`/api/render`.

## Frame

Each frame has a positive integer `step`, a string `verb`, and a `scene` object.
The scene has a drawer-supported `format`, the integer `version` value `2`, and
the primitives required by that format. Captions and other descriptive fields
may accompany the required fields.

The supported formats are `fraction-bars`, `number-line`, `area-model`,
`base-ten-columns`, `place-value-chart`, `set-grouping`, `balance-scale`,
`hybridization-model`, `notation`, `coordinate-plane`, `rigid-motion`,
`polyform-tiling`, `angle-circular`, `data-display`, `solid-net`, and
`geoboard`.

## Compatibility

The drawer continues to accept version 1 documents from the shipped
hybridization, place-value, parametric-deformation, and legacy notation
compilers, plus the fraction-cliff exporter (`export_fraction_cliff.py`,
which emits version-1 fraction-bars scenes from Python). New scene compiler
output uses version 2. The HTTP boundary validates that both versions remain
drawable and rejects scalar or malformed results.

## Offline regeneration

`hermes.app.rendering` validates documents and invokes
`more-zeeman/render/node-adapter.js`. The adapter provides the supported fake
DOM, resolves Hermes color tokens, loads the same drawer used by shipped pages,
and serializes frames and filmstrips. Node.js is required only when a contributor
regenerates or checks tracked galleries.
