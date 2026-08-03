# Contract coverage and purport-audit todo — scoped 2026-08-03

Companion to the audit run of this date. New machinery:
`scripts/checks/audit_purported_validity.pl` (two-layer purport audit;
exports the grid-searching `separating_example/4` and input-specific
`deformation_separates_on/4`), `scripts/checks/sweep_coincidence.pl`
(coincidence sweep; crash-isolated per kind),
`scripts/checks/scan_self_certifying.py` (static scan for
`expected(Result)` sharing the result variable), and the generated data
in `knowledge/strategies/deformation_coincidence.pl`. State after the
decoder slice: Layer 1 covers all 219 contracted kinds with no broken
purports or failed runs. Layer 2 has 221 executable outcomes: 76 pass
independent truth checks, 119 have no truth adapter, and 26 have an
unnormalized result shape; no incorrect-kind example coincides with its
independent truth. All 219 contracts return `ok:true` with nonempty
steps through the worker's `strategy_trace` seam.

The ordering below is by harm, not by size.

## 1. Closed: non-returning small in-shape inputs

Closed 2026-08-03: admissibility guards in the addition and subtraction action-pair modules make all four recorded inputs fail cleanly while preserving the existing admissible contract traces. The 219-contract live seam regression passes after those guards.

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

## 3. Closed: registered kinds without input contracts

Closed 2026-08-03: the additive tagged decoder expansion constructs the structured operand families, and 88 family-shaped contracts close the remainder left by the prior seven-contract slice. The live checker reports `contracts=219 registered-signatures=219 remaining-gap=0 verified-live=219`.

## 4. Truth adapters and result shapes still missing

From the audit's honest remainder, 119 executable outcomes have no
independent truth adapter and 26 result shapes are not yet normalizable.
The structured geometry, statistics, algebraic, measurement, integer,
ratio, and decimal-conversion contracts enter these buckets without
claiming independent truth coverage. Each needs an adapter or an
explicit recorded decision that its correctness is not a computable
comparison.

## 5. Self-certifying expected fields

64 kinds carry `expected(Result)` sharing the result's variable
(scan_self_certifying.py): their validity(correct) cannot fail at
runtime. The arithmetic families among them are now covered by the
audit's layer 2; the remainder falls with section 4's adapters. Where
an expected value is computable inside the module, computing it
independently of the result is the durable fix.

The scan's 64 self-certifying rows and 72 independent-variable rows are
complementary regex buckets, not competing totals. Both are syntactic
classifications of source spellings.
