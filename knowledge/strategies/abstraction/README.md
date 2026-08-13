# abstraction

Candidate structure over the automata corpus, from the regularization
conversation of 2026-08-03
(`docs/research/2026-08-03-automata-abstraction-conversation.txt`).
Every module here is quarantined in the same sense as
`action_vocabulary_map.pl`: nothing imports it, it renames nothing, and
its rows are authored and vetoable one by one. These are pilots of a
possible reorganization, not the reorganization.

## What it holds

- `addition_action_signatures.pl` — types the 59 addition-family action
  atoms (operational step / invariant ledger / verdict), folds the 18
  transition tables into 6 automata with genuine branch points, and
  checks agreement between two validity encodings authored from the
  same reading. Check: `check_pilot/0`.
- `kernel_gate_pilot.pl` — runs three cross-domain kernels
  (complete_to_unit, iterate_to_target, partition/regroup) under genre
  gates; correct and incorrect doings are instances or single local
  mutations of the same kernel run, with execution-grounded validity and
  mutation tests against over-acceptance. Check: `check_kernel_pilot/0`.
- `refusal_genesis_sketch.pl` — loads the kernel pilot and adds three
  rows of structure: gate mutations have antecedent licenses, gate
  refusals repaired institutionally are new number systems, and the
  ladder ends where the repo already marks incommensurability. Check:
  `check_refusal_genesis/0`.
- `channel_collapse.pl` — a third reading beside productive and
  deformed, for errors with no formal antecedent (two task tokens
  collapsed in a child's articulation channel), with a discrimination
  test that separates channel errors from license errors by their
  distribution. Check: `check_channel_collapse/0`.

## The grade 8 pilots (`g8_*`)

Seven files added 2026-08-12 for the doings IM grade 8 asks for that no
registered machine enacts. The naming convention is `g8_<doing>.pl` with
a module of the same name, an exported `run_g8_<doing>/4`, a JSON-string
input contract in the house genre, a self-summary fact, and a
`check_g8_<doing>/0` that runs every receipt. Each receipt is a real
grade 8 row of `curriculum/im/generated/compiled_defragged_task_instances.pl`
and every coefficient is read off that row's own statement. Arithmetic is
exact rational throughout; floats appear only as approximations sitting
beside an exact value, and they are labelled as such. Deformation
partners appear only where this repository's research corpus attests the
error, and each names its `db_row` and its citation; where no row attests
one, the module ships without a partner and says so.

- `g8_quantity_input.pl` — the shared exact-quantity decoder and the
  rational, root, and terminating-decimal renderings. The six pilots
  below import it; nothing outside this directory does.
- `g8_linear_equation_balance.pl` — one linear equation with the unknown
  on both sides; one solution, none, or every number, verified by
  substitution into the original equation. Deformation: db_row 37558.
- `g8_linear_system_solution.pl` — two linear equations in two unknowns,
  verified by substitution into both. No attested deformation at this
  locus, so none is shipped.
- `g8_right_triangle_side.pl` — hypotenuse from legs, leg from
  hypotenuse, and the converse test, exact on the squares with roots
  named rather than evaluated. Fills the gap
  `monitoring_registry_bridge.pl` records as
  `no_drawable_registry_operation(pythagorean_theorem, ...)`.
  Deformations: db_rows 40244 and 38694.
- `g8_round_solid_volume.pl` — cylinder, cone, sphere, hemisphere, and
  prism volumes as exact rational coefficients of π, each recomputed by
  a second route. Deformation: db_row 38050.
- `g8_linear_model_from_observations.pl` — rate of change and vertical
  intercept from two observations or from a rate and a starting amount,
  verified by substituting both observations. Deformations: db_rows
  37775 and 38094.
- `g8_power_of_ten_notation.pl` — numerals as multiples of a power of
  ten, verified by rebuilding the numeral exactly. Reaches magnitudes
  the grounded 5,000 bound refuses, because it works on the exponent.
  Deformation: db_row 38303.
- `g8_root_and_number_class.pl` — exact side length from a square's
  area, square and cube roots bracketed between consecutive whole
  numbers by squaring rather than rooting, rational against irrational
  decided by search, and a rational's decimal expansion by exact long
  division. No attested deformation at this locus, so none is shipped.
- `g8_polygon_angle_and_tessellation.pl` — the interior angle of a
  regular polygon, how many copies close a vertex, whether a regular
  polygon tiles the plane, and an unknown angle from a stated whole.
  Verified against the triangulation count and the full turn. No
  attested deformation at this locus.
- `g8_two_way_table_association.pl` — completing a two-way table from
  its own totals, relative frequencies by row, by column, and over the
  whole table, and the exact difference between two rows. The engine
  reports the difference and never rules on it. No attested deformation
  at this locus.
- `g8_scatter_data_fit.pl` — an exact rational least-squares line over a
  table of paired measurements, verified by both normal equations being
  exactly zero, with the association direction and the furthest point.
  Deformation: db_row 38411.
- `g8_exponent_rule_rewrite.pl` — the product, quotient, power-of-power,
  product-of-bases, zero and negative exponent rules applied and checked
  by evaluating both sides exactly, plus a verdict on a claimed
  equivalence. Deformation: db_row 38303 at the value locus.
- `g8_plane_transformation.pl` — dilation, translation, quarter-turn
  rotation, and reflection as exact coordinate maps. Every run returns
  the image coordinates AND a scene in the coordinate-plane grapher's
  JSON genre drawing pre-image and image together; the check renders
  every scene through `hermes/web/coordinate-plane/grapher.js`. The
  deformation emits a scene too, so a teacher can draw the student's
  thinking beside the dilation. Deformation: db_row 38669.
- `g8_function_table.pl` — whether an input-output table is a function
  (with the clashing input exhibited), the linear rule fitted and
  substituted into every row, and evaluation at a further input. Reads
  tables from docling `document.json` structured items and takes
  vision-recovered tables in the same shape. No attested deformation at
  this locus.

Run one check from the repo root:

    swipl -q -l paths.pl -l knowledge/strategies/abstraction/g8_right_triangle_side.pl \
          -g g8_right_triangle_side:check_g8_right_triangle_side -t halt

The verified receipts are emitted as
`curriculum/im/generated/wave5_g8_row_machine_map.jsonl`.

## The K-7 scene-emission siblings (`k7_*`)

Five files added 2026-08-12, bringing K-7 the capability grade 8 gained the
same day: a machine whose result carries a drawing, in the coordinate-plane
grapher's own JSON genre (`hermes/web/coordinate-plane`, schema version 1),
verified by rendering through `grapher.js` under Node.

These are siblings, not replacements. Each one RUNS an existing registry
automaton through `action_automata_registry:run_action_automaton/6`, reads the
drawing off that machine's own named trace terms, and modifies nothing. No
machine, transition table, input contract, or state-vocabulary row was
touched. Nothing outside this directory imports any of them.

The gap they answer: of 1,811 usable K-7 rows in the defrag pool, 1,781 come
back from the wave-5 row map with the note "number-line jump trace is not
available for this strategy's step shape", and none carries a scene. The
existing jump extractor reads a running value out of a history's state term;
these pilots read the action trace instead, where the doing is already named.

- `k7_scene_common.pl` — the shared parts: scene dicts in the grapher's genre,
  exact rational rendering, and the render receipt itself. Computes no
  mathematics.
- `k7_number_line_hops.pl` — what runs along a line: counting on, counting all
  from zero, counting up to a target, taking a subtrahend away in chunks, and
  removing a group size until nothing is left. One segment per step, at the
  step's own height, from the value it left to the value it reached. Two
  attested deformations draw their run above the line with the machine's own
  run below it. Refuses a run past 40 hops and a run that moves nowhere.
- `k7_array_grid.pl` — what is a rectangle of unit squares: equal groups
  coordinated into a total, and an area covered by unit squares. One point per
  square, and the grid closing at one more line than rows and columns. Two
  deformations draw their own count beside the array: the two numbers laid end
  to end, and the boundary traced where the interior was asked for. Refuses
  past 240 squares.
- `k7_equal_share_bars.pl` — partitive division as one bar per group, every
  bar at the share the machine named, and the shortfall computed exactly where
  the bars do not hold the amount there was to deal. Carries the extant
  machine's per-input viability: where group count equals share size the two
  readings coincide, and the pilot says so rather than manufacturing a
  disagreement.
- `k7_fraction_number_line.pl` — two fractions combined over a common unit,
  drawn on a line partitioned into that unit, with each fraction laid off as a
  hop. The mediant deformation draws its result between the two addends with
  the sum beyond them, checked on exact rationals. Records rather than draws a
  partition past 40 ticks.

Run one check from the repo root:

    swipl -q -l paths.pl -l knowledge/strategies/abstraction/k7_array_grid.pl \
          -g k7_array_grid:check_k7_array_grid -t halt

## The question pilots (`task_pattern_pilot.pl`, `question_move_pilot.pl`)

Two generated files added 2026-08-12, from the mining of the K-8 guide
questions. Both are quarantined on the same terms as everything else here,
and both are rebuilt rather than edited: the generators are
`scripts/questions/build_task_pattern_pilot.py` and
`scripts/questions/build_question_move_pilot.py`. Each file carries a
self-summary fact, so the counts live in the data and not in this paragraph.

- `task_pattern_pilot.pl` — one row per region of input space that the
  mapped curriculum occupies, with the numerals washed out into guards in
  the idiom the kernel gates already speak, and one witness per region that
  the formal core ran to a correct verdict. The regions come from the
  wave-5 row map, which this file consumes and never rebuilds. Check:
  `check_task_pattern_pilot/0`, which evaluates every guard against its own
  witness — a region whose instance sits outside it would be a naming error.
- `question_move_pilot.pl` — states pairing a task pattern with the
  teacher's epistemic position, and the moves a question is licensed to make
  from that position. A move reaches this file only after three engine
  checks pass: the linked machine runs on the region's witness and its
  verdict agrees with the claim, every numeral in the question binds a
  parameter, and the model never overwrites a label the curriculum author
  wrote. Failures land in a runtime quarantine artifact with the failed
  check named. Check: `check_question_move_pilot/0`.

Nothing from either file serves to a reader. Serving is gated on the review
status of the evidence rows, and almost all of them are unreviewed.

## How to run the checks

From the repo root:

    swipl -q -l paths.pl -l knowledge/strategies/abstraction/<file> \
          -g <module>:<check> -t halt

## What came out of the same morning

The audit machinery this line produced is live, not quarantined:
`scripts/checks/audit_purported_validity.pl`,
`scripts/checks/sweep_coincidence.pl`,
`scripts/checks/scan_self_certifying.py`, with generated data in
`knowledge/strategies/deformation_coincidence.pl`. Findings:
`docs/research/2026-08-03-purported-validity-audit.md`. The work queue it
ordered lives in the untracked local research log,
`docs/research/internal/2026-08-03-contract-coverage-todo.md`.
