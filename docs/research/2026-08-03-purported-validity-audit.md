# Audit: purported vs computed validity across the action automata

Date: 2026-08-03. Run against a staged copy of the live tree (knowledge/,
formal/, paths.pl, scripts/checks), SWI-Prolog 9.0.4, in a Cowork
container. Two empty stub modules were created to satisfy load paths the
slice omits (`curriculum/im/docling_figures_interpreted.pl`,
`hermes/encyclopedia.pl`); neither is exercised by the audit. Reproduce
on the full tree with:

    swipl -q -l paths.pl -l scripts/checks/audit_purported_validity.pl \
          -g audit_purported_validity:audit -t halt

The audit has two layers plus a static companion scan. Layer 1 runs
every kind that has an execution-verified input contract
(automaton_input_contracts.pl, 124 kinds) on its own contract example
and holds the outcome's validity claim against its own result/expected
pair. Layer 2 computes ground truth independently — plain arithmetic
over the contract inputs, never read from the outcome — and holds
kinds against that. The companion scan
(scan_self_certifying.py) finds outcomes whose expected field shares
the result's variable in the source, which makes layer 1 pass by
construction and layer 2 the only check that can catch them.

## Results

Status boundary: the 4 Layer-1 purport breaks and 5 nonseparating
contract examples below are findings from the first audit run. They
were repaired the same day. The live audit now reports zero in both
categories.

Layer 1: 124 of 124 contracted kinds mapped and executed. 120 hold.
0 fail to run on their own verified example. 4 break their purport,
and all 4 break it the same way: a deformation classified
validity(incorrect) whose contract example yields result == expected.

Layer 2: among kinds the truth adapters cover, 0 are wrong while
purporting correct. 5 deformations are right while purporting
incorrect — their own contract example produces the true answer, so
the example does not witness the bug the automaton exists to model.
The audit searched a small input grid and found a separating example
for every one:

| kind | contract example yields | separating example |
|---|---|---|
| division/stop_after_first_partial_quotient | qr(1,19), true for 47÷28 | a=96, b=4 |
| fraction/add_numerator_denominator_comparison | greater_than, true for 3/4 vs 2/3 | 2/3 vs 3/8 |
| fraction/area_model_unequal_partition_piece_count | greater_than, true | 2/3 vs 3/8 |
| fraction/set_model_subset_size_focus | greater_than, true | 2/3 vs 3/8 |
| decimal/decimal_scale_loss_comparison | greater_than, true | 0.3 vs 0.25 |

These five are the corpus's own separation problem: a deformation whose
contract example coincides with correct behavior cannot be
distinguished, on that example, from the strategy it deforms. The
proposed repair is a second contract row per deformation — a
separating example — and the audit generates candidates mechanically.

Static scan: 61 kinds carry a self-certifying expected field
(`result(Result), ..., expected(Result)` — same variable). Their
validity(correct) cannot fail at runtime no matter what the
computation does. By file: fraction 15, decimal 9, geometry 5,
statistics 4, counting 4, algebraic 4, addition 4, multiplication 4,
calculus 3, division 2, subtraction 2, integer 2, ratio 2,
measurement 1. Layer 2 now covers the arithmetic families among
these; the rest are exactly the truth-adapter work list below.

Coverage gap: 95 of 219 registered kinds have no input contract at
all and so cannot be audited automatically yet — geometry 44,
statistics 14, algebraic 14, measurement 8, decimal 6, integer 5,
fraction 2, ratio 2.

## Honest remainder

21 contracted kinds have no independent truth adapter yet (probability
allocations, calculus limits, fraction solve/iterate schemes, the
counting inscription kinds); 30 result shapes are not yet normalizable
(solved_unknown terms, allocation lists, rendered scenes). Each needs
either a truth adapter or an explicit decision that its correctness is
not a computable comparison — and that decision, where taken, should
be recorded on the kind rather than left as silence.

The three-way separation the audit relies on — the claim in the
outcome, the execution of the automaton, the truth computed beside
both — is the same separation the kernel/gate pilots enforce between
trace, ledger, and task. An automaton that carries its own expected
value is testimony; the audit is cross-examination.
