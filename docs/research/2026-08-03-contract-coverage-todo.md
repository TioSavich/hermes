# Contract coverage and purport-audit todo — scoped 2026-08-03

Companion to the audit run of this date. New machinery:
`scripts/checks/audit_purported_validity.pl` (two-layer purport audit;
exports the grid-searching `separating_example/4` and input-specific
`deformation_separates_on/4`), `scripts/checks/sweep_coincidence.pl`
(coincidence sweep; crash-isolated per kind),
`scripts/checks/scan_self_certifying.py` (static scan for
`expected(Result)` sharing the result variable), and the generated data
in `knowledge/strategies/deformation_coincidence.pl`. State as of this
date: Layer 1 covers all 124 contracted kinds. Layer 2 has 125
executable rows because `counting/recursive_place_value_inscription`
contributes two identical solutions: 74 pass the independent truth
check, 25 have no adapter, and 26 have an unnormalized result shape.
About 50 unique contracted kinds remain unchecked by Layer 2. The five
deformation contracts that initially failed to witness their own bug
carry separating examples, re-verified through the worker's
strategy_trace seam (all 124 rows ok:true with nonempty steps).

The ordering below is by harm, not by size.

## 1. Defects: kinds that do not return on small in-shape inputs

Recorded as `no_return_within/3` in deformation_coincidence.pl. Each
was killed at 120 s in a crash-isolated process, on an input inside its
declared contract shape:

- `addition/make_base_transfer` on (1, 3) — also aborts the process
  outright in an unbounded run (C-stack), which would take the worker
  down with it.
- `subtraction/count_up_missing_addend` on (1, 13)
- `subtraction/take_away_base_ones` on (1, 14)
- `subtraction/sliding_constant_difference` on (1, 17)

All four sit where the second operand exceeds the first or the first is
tiny. Each needs either a guard that FAILS cleanly (the registry
boundary is semidet; failure is the contract) or an explicit refusal
result, plus a contract-shape note recording the admissible domain.
This is the highest-priority slice: a student input can currently hang
or kill the worker.

## 2. Fixed points: per-input validity for coincident deformations

The sweep measured, for every contracted deformation with a truth
adapter, the inputs on which the deformation's result equals the true
answer. Where that set is nonempty and the kind still claims
input-independent `validity(incorrect)`, every coincident input is a
purport violation and a diagnosis hazard — the broken clock is right
there, and a recognizer that charges the misconception on such an input
manufactures one.

The corpus already has the correct pattern in three places:
`gap_thinking_fraction_comparison` (contextually_correct; zero
violations over 1470 swept inputs), `divide_larger_by_smaller`, and the
two decimal comparison deformations (accidentally_correct; zero
violations). The task is to extend that pattern to the kinds below
(violations = swept inputs where the incorrect label meets a correct
result; rates in deformation_coincidence.pl):

| kind | violations / ran |
|---|---|
| fraction/number_line_count_marks_not_intervals | 1598 / 1678 |
| fraction/area_model_unequal_partition_piece_count | 1206 / 1470 |
| fraction/set_model_subset_size_focus | 1206 / 1470 |
| fraction/add_numerator_denominator_comparison | 786 / 1582 |
| division/stop_after_first_partial_quotient | 192 / 612 |
| division/stop_after_one_known_fact | 192 / 612 |
| addition/unbalanced_make_base_compensation | 117 / 720 |
| addition/dropped_ones_chunk | 90 / 900 |
| division/name_reached_total_as_quotient | 60 / 184 |
| addition/append_column_sum_without_carrying | 45 / 405 |
| addition/make_ten_drop_leftover | 45 / 603 |
| multiplication/repeat_group_size_by_itself | 20 / 400 |
| addition/round_without_adjusting | 9 / 900 |
| division/name_group_count_as_share_size | 7 / 184 |
| multiplication/add_instead_of_multiply | 1 / 400 (the input is 2, 2) |
| multiplication/add_counts_without_composite_unit | 1 / 400 |

Diagnosis rule that should ride with the relabel: a recognizer may
charge one of these kinds on input I only if the deformation separates
from the truth on I. `deformation_separates_on/4` is the input-specific
runtime check; `separating_example/4` searches a fixed grid for contract
candidates. Until the relabel lands, the coincidence rates above ARE the false-
accusation exposure per kind.

Ruling recorded (owner, 2026-08-03): a deformation whose answers are
ALWAYS right is a relabel candidate. No deformation that purports
`incorrect` has a 100% coincidence row. The sweep has three 100% rows:
the two `count_all_*` kinds already carry `correct_but_inefficient`, and
`fraction/cross_multiplication_rule_without_ground` carries
`validity(correct)`. The fraction kind stays a deformation because what
it loses is grounding, not answers. Answer-based detection is
impossible for it, so its recognizer must read the trace for the missing
grounding step.

## 3. Coverage gap: 95 registered kinds with no input contract

Per family, with the input-shape work each needs. A contract needs: a
JSON shape, one worked example, seam verification, and — for
deformations — a SEPARATING example (an input where the bug shows).
Adding a separation check to scripts/checks/automaton_input_contracts.py
once truth adapters exist would make non-witnessing examples
impossible to reintroduce.

- geometry (44): the large one. Shapes needed for rectangles (L, W),
  prisms (L, W, H), angle compositions, coordinate pairs, polygon
  side lists, symmetry specs. Suggest one shape vocabulary authored
  first, then contracts in batches of ~10 by subfamily (area/perimeter,
  volume, angles, coordinates, classification).
- statistics (14): data-list shape (list of numbers) plus summary kind;
  truth adapters are cheap here (mean, median, MAD are one-liners).
- algebraic (14): expression/assignment shapes; truth via evaluation.
- measurement (8): quantity-with-unit shape; four kinds pair with the
  count_marks family already swept in fraction.
- decimal (6), integer (5), fraction (2: the co_denominator dispatch
  kinds — route through the addition contracts they delegate to),
  ratio (2).

## 4. Truth adapters and result shapes still missing

From the audit's honest remainder: 25 executable rows have no
independent truth adapter, including the four multiplication tasks now
explicitly excluded from the product adapter; 26 result shapes are not
yet normalizable. These are 51 rows but about 50 unique contracted kinds
because `recursive_place_value_inscription` contributes two identical
solutions. Before the product-adapter repair these buckets were reported
as 21 without an adapter and 30 not normalizable; the four tasks were in
the wrong bucket. Each needs an adapter or an
explicit recorded decision that its correctness is not a computable
comparison. 49 contracted kinds were unsweepable for these reasons
(`unswept/3` rows).

## 5. Self-certifying expected fields

61 kinds carry `expected(Result)` sharing the result's variable
(scan_self_certifying.py): their validity(correct) cannot fail at
runtime. The arithmetic families among them are now covered by the
audit's layer 2; the remainder falls with section 4's adapters. Where
an expected value is computable inside the module, computing it
independently of the result is the durable fix.

The scan's 61 self-certifying rows and 71 independent-variable rows are
complementary regex buckets, not competing totals. Both are syntactic
classifications of source spellings.
