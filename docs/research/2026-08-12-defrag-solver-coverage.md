# Defragged-task solver coverage: 1,808 of 1,811 usable rows run to a verified correct trace

Date: 2026-08-12. Question (Tio's): "I'm not totally convinced we have
clean prolog algorithms/automata for actually solving all those
things." This measurement answers for the defragged IM task corpus.

## Method

Every usable row of
`curriculum/im/generated/compiled_defragged_task_instances.pl` (1,811 =
547 already_complete + 1,261 recovered + 3 recovered_with_referent) was
mapped to one registered strategy machine and run through
`hermes_encyclopedia:strategy_trace_dict/3` in an isolated headless
SWI-Prolog process with a 3-second per-row limit. The outcome recorded
is the machine's own `validity` verdict on the row's own numbers.
Nothing was mocked; refusals and errors were tallied, never dropped.
Runner and per-row TSV: session scratchpad (`bulk_audit.pl`,
`bulk_audit_rows.tsv`); the mapping table is reproduced below.

One machine per operation family was chosen (magnitude-safe where the
family offers several): add → column_addition_with_carrying, subtract →
take_away_base_ones, multiply → multiplication_fact_retrieval, divide →
long_division, fraction add/subtract → the common_denominator machines
(frac(N,D), whole(W), mixed(W,N,D) all normalized to n/d), and one
machine per tail label (place_value_comparison,
rectangular_prism_volume_layer_iteration, positional_decimal_reading,
recursive_partition, rectangle_perimeter_boundary_traversal,
rectangle_missing_side_from_perimeter, rectangle_missing_side_from_area,
decimal_addition_by_aligned_units, decimal_comparison_by_aligned_units,
unit_conversion_by_iteration, rectangle_factor_pair_search).
compare_rectangle_areas ran as a composition of two
rectangle_area_unit_iteration traces.

## Result

| Outcome | Rows |
|---|---|
| validity = correct, single machine | 1,806 |
| correct via alternate machine (multiply(600,500) → known_product_adjustment) | 1 |
| correct via composition (compare_rectangle_areas, both parts correct) | 1 |
| refused by every probed machine (magnitude) | 3 |

**1,808 / 1,811 = 99.8%.** The three refusals are
subtract(400000, 99999), subtract(423450, 42345), and
multiply(1500, 30000): every probed machine refuses these by input
contract rather than grinding — the grounded-enactment refusal line
(see the enactment-seam finding) reached at six-digit magnitudes.
Refusal here is fast and explicit, not a hang.

Row counts by family, all-correct unless noted: add 661, divide 386,
subtract 366 (2 refused), multiply 331 (1 alternate), add_fractions 24,
subtract_fractions 18, compare_numerals_by_place_value 4,
unit_cube_volume 3, decimal_value 3, unit_fraction 2,
rectangle_perimeter 2, rectangle_missing_side_from_perimeter 2,
construct_rectangle_with_area 2, decimal_add 2, and one each of
rectangle_missing_side_from_area, decimal_compare, convert_measurement,
rectangle_side_lengths_for_area, compare_rectangle_areas.

## Two harness facts learned on the way

1. **Input genre is JSON-string, not atom.** Kind-tagged machine inputs
   (`kind`, `unit`, `scope` values) must arrive as strings
   ("count_pair"), the wire genre the shared decoder standardizes on;
   atom-genre callers get a contract refusal. 61 initial false
   refusals in this audit were this harness fault, proven by rerun.
2. **A served-worker guard gap.** Through the MCP-served worker,
   borrow_across_zero_cascade on 920000−142571 ran past 120 s and the
   worker became unavailable; the same call headless refuses in
   milliseconds. The serving path evidently reaches the machine by a
   route that bypasses the fast contract refusal. Defect noted for the
   worker lane; not fixed in this measurement.

## What this does and does not claim

It claims: for 99.8% of the usable defragged tasks, a registered,
trace-verified machine enacts the labeled operation on that row's own
numbers and certifies its own result correct.

It does not claim the machine answers each statement's full demand.
The label is an authored classification: a row labeled
unit_fraction(2,3) whose statement asks students to justify Han's
equal-sharing argument has a running partition machine, but choosing
the machine that matches the statement's demand — and writing the
referent-bearing facts that connect statement to machine — is
representation authorship, the exact seat the NL→Prolog training
direction assigns to the model. Multi-expression statements
contribute one row per expression; correctness is per expression.
Blocked rows (312 layout, 23 missing-visual) and the grade-8 lessons
(guides exist, no task rows) sit outside this measurement.
