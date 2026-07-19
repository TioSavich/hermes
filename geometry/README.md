# geometry

The geometry knowledge base: concepts, van Hiele levels, conceptual metaphors,
bootstrap activities, and standards anchors.

## How it loads

`geometry_bridge.pl` is the portable loader; it resolves the repository root
through `paths.pl` rather than a hardcoded path, then consults `schema.pl`.
`schema.pl` owns the canonical load chain: it declares the KB predicates
(`geom_concept/4`, `van_hiele_marker/4`, `metaphor_source/4`,
`geom_misconception/6`, `material_inference/4`, and the rest), then loads the
concept, metaphor, van Hiele, bootstrap, and PCK files plus the cross-repo
standards, and finally `query.pl`, the high-level query surface. These three
top-level files load into `user`; they carry no `:- module` declaration.

## What it holds

- `concepts/` — 20 per-topic tables (angles, area/perimeter, classification,
  transformations, similarity/congruence, coordinate geometry, and more).
- `van_hiele/` — level descriptors (`levels.pl`) and between-level transitions.
- `metaphors/` — the Lakoff & Núñez metaphor inventory and the measuring-stick
  source.
- `bootstrap/` — construction, Van de Walle, and N103 activity facts.
- `pck/` — pedagogical-content-knowledge synthesis.
- `corpus/` — IM teacher-guide markdown (no Prolog). Attribution and per-grade
  scope are in `corpus/ATTRIBUTION.md` and `corpus/im_teacher_guides/grade6/README.md`.

## Consumers and boundary

`hermes_worker.pl` consults `schema.pl`; `lessons/im/lesson_monitoring.pl`,
`crosswalk/families/cw_grounding_metaphor.pl`, and the app's geometry route read
the KB. Witnesses build through `witness_dict:witness_dict/4`. van Hiele markers
cover levels 0 through 4; some declared tables hold no rows in this snapshot; a
witness proves membership in the loaded table, not general standards alignment.
