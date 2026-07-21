# Curriculum pipeline sources

These files preserve the generators and reviewed inputs behind the checked-in
curriculum caches. They are source material for inspection and reuse; vendoring
does not make every earlier generation route fit the Hermes directory layout.

## Regenerations that run in this checkout

The IM coverage inventory is self-contained. It reads the vendored ratchet and
the loaded Hermes lesson stack:

```sh
python3 scripts/research/build_im_coverage.py
```

The teacher-facing grade 6-8 vision digest is self-contained from the vendored
harvest snapshot when its Hermes output path is supplied:

```sh
python3 scripts/curriculum/build_digest.py \
  curriculum/im/generated/vision_lesson_digest.pl
```

## Inputs this checkout does not carry

- `compile_action_mappings.py` retains its source checkout paths. It expects
  `geometry/corpus/im_teacher_guides/`,
  `geometry/corpus/im_scope_and_sequence/`, `lessons/im/`, and the prior
  `math(action_automata_registry)` path layout. Hermes stores the related files
  under different paths and does not carry the full teacher-guide corpus, so
  the compiled action-mapping and task-instance caches do not regenerate here
  without an explicit adaptation of the vendored script.
- `ingest_vision.py` can parse the vendored
  `vision_harvest/im_g6g7_vision_harvest.json` and `registry_vocab.json`, but it
  reads a historical `lessons/im/generated/compiled_action_mappings.pl` with
  `git show` and writes `lessons/im/grade_6_vision.pl`,
  `lessons/im/grade_7_vision.pl`, and `action_mapping_rules.json`. Those lesson
  paths do not exist in Hermes, so neither its dry run nor its apply route is a
  self-contained Hermes regeneration.
- `mini_atlas.pl` reads the vendored `basis_set.json`, but it imports
  `learner(task_transition)`, which this checkout does not carry. Its literal
  output is also `learner/atlas/basis_transitions.pl`; the checked-in Hermes
  cache is `formal/learner/atlas/basis_transitions.pl`.
- `build_lesson_evidence.py` needs
  `data/learningcommons/derived/im_k8_spine.json`,
  `im_ccss_action_catalog.json`,
  `im_productive_deformation_catalog.json`, the `lessons/im/generated/`
  mapping and task caches, and
  `scripts/bigred/iteration15/work/atlas/atlas_landscape.jsonl`. This checkout
  carries none of those paths. Refreshing its standards catalog also needs
  `data/learningcommons/nodes.jsonl`.
- The vendored vision harvests are snapshots. Re-running the vision extraction
  requires the original Illustrative Mathematics grade 6-8 unit teacher-guide
  PDFs, including files named like `Grade6-1-Unit-teacher-guide-.pdf`, and the
  vision-run machinery that produced the JSON. The source PDFs and vision runs
  are not carried here.

Vendored 2026-07-21 from `/Users/tio/Documents/GitHub/umedcta-formalization`.

The vision-harvest JSON inputs record, inside their `subpdf` provenance
values, the source-checkout paths that held the PDFs when the harvest
ran. Those values are historical data and stay byte-identical; they are
not a machinery dependency on that checkout.

`formal/learner/task_transition.pl` is restored: it was pruned as
consumerless before `mini_atlas.pl` was vendored, and the vendored
atlas builder imports it.
