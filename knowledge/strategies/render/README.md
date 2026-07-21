# knowledge/strategies/render

Scene compilers. Each emits a render document (frames of geometric primitives,
one role atom per fill) that the browser drawer steps through. A compiler emits
geometry; it never computes a result.

## What it holds

- 21 `*_scene.pl` compilers, one per representation: `base_ten_scene`,
  `fraction_bars_scene`, `number_line_scene`, `area_model_scene`,
  `balance_scale_scene`, `geoboard_scene`, `place_value_chart_scene`,
  `notation_scene`, `coordinate_plane_scene`, `rigid_motion_scene`,
  `set_grouping_scene`, `unit_echo_scene`, and the rest.
- `render_common.pl` — shared plumbing for the compilers.
- `representation_grammar.pl` — the logical grammar for representations.
- `teacher_layer.pl` — teacher-layer composition over a render document.
- `corpus_attested_grammar.pl` with `attested_objects`, `attested_uses`,
  `attested_deformations` — the corpus-attested vocabulary.
- `parametric_*` — deformation generators (fraction errors, notation and
  partition deformations).
- `misconception_render_coverage.pl` — a coverage report over the registry.

## Contract and consumers

The document shape is fixed by `docs/render-contract-v2.md`. `hermes_worker.pl`
runs the render operations; the browser draws the documents through
`more-zeeman/render/drawer.js`, which resolves each role atom to a CSS variable
from `more-zeeman/hermes-tokens.css`.

## Boundary

A compiler draws a strategy; it does not run it. The result geometry comes from
the automata in `knowledge/strategies/math/`.
