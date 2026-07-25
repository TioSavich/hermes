# Registering the 43 — the fraction schemes are extractable

Model: `claude-opus-5[1m]` (Opus 5, 1M context).
Date: 2026-07-25. Continues `2026-07-25-interruption-model-corrected.md`.

Files changed: `knowledge/strategies/math/action_automata_registry.pl` (43 rows),
the five affected transition tables plus two new ones,
`knowledge/strategies/action_vocabulary_map.pl`,
`knowledge/strategies/action_grammar.pl`,
`scripts/research/build_action_grammar.py`, this report.

## What happened

Forty-three action automata were implemented in the action-pair modules —
runner clause, `action_outcome/2`, `Trace` list — and never declared in
`action_automata_registry.pl`. `build_transition_tables.py` takes its signature
list from that registry, so it had never extracted them, and every layer above
the tables was blind to them.

They are registered. The registry holds 215 signatures where it held 172, and the
tables hold 214 automata where they held 171.

Among them, the Steffe/Olive/Hackenberg fraction schemes: `splitting`,
`solve_for_unit`, `recursive_partition`, `improper_fraction_iteration`, and the
`cross_multiplication_rule_from_pattern` / `_without_ground` pair the deontic
scorekeeper's own docstring was written around.

## The byte-equivalence proof

The existing tables had to come through untouched, and did. Every
`automaton_tuple` and `automaton_transition` fact was extracted before and after
the registration and compared:

| | before | after |
|---|---:|---:|
| automata | 171 | 214 |
| transition facts | 1503 | 1732 |
| **facts present before and absent after** | — | **0** |
| facts added | — | 272 (43 automata, 229 edges) |
| observed edges | 708 | **708** |
| signatures carrying observed edges | 69 | **69** |

Nothing pre-existing changed. And the observed set is identical, which matters
more than it looks: observed rows come only from
`knowledge/strategies/automaton_input_contracts.pl`, and registering a signature
adds no contract. So the new 43 carry static transitions and no live-probe rows,
the strategy-algebra analyzer's hard `len(observed) != 69` guard never fires,
and **the analyzer's default output is byte-identical to before the registration**
(`45aee5ec…518039cc`, unchanged since the first slice three reports ago).

Giving the 43 contracts is a separate, deliberate step. A contract carries a
`verified(...)` field, so it is a claim that the automaton was run on that input
and produced what the contract says. That is worth doing and is not worth doing
by inference.

## The alphabet held

The 43 machines brought **229 new mapping rows over 164 new labels**, and needed
**one** new canonical action: `misread_intermediate_value`, for reading a value
the computation itself produced as a different value — a misread carry, a zero
column taken as a full base. Distinguished from `misname_result`, which is about
the answer, and from the `substitute_*` family, which puts one relation in place
of another; here the rest of the procedure runs correctly on the wrong figure.

The other 163 labels fit an alphabet authored before these machines were
extractable. That is the first evidence it generalizes past the corpus it was
written on, and it is worth more than the count suggests: these are different
modules, written by a different pass, for schemes the alphabet had never seen.

Two of the new labels landed on `retain_where_change_was_due`, the deforming
retention split out two reports ago, and landed there without any prompting from
me:

- `addition/unbalanced_make_base_compensation` has `leave_other_addend_unchanged`
  at the edge where a balanced transfer obliged the second addend to give up what
  the first received.
- `multiplication/rigid_factor_order_roles` has
  `keep_multiplier_multiplicand_roles_fixed` where commuting the factors obliged
  the roles to swap.

An action invented to describe eleven rows in one corner turned out to be what
two machines from other modules needed. It is a small thing and it is the kind of
small thing that says a carving is real.

One more arrival worth naming: `fraction/iterate_only_no_reverse` has
`cannot_run_inverse_edge_to_recover_unknown`, which is `exhaust_resource` — the
ORR crisis step, a resource met at its limit rather than a step skipped. That
canonical action had exactly one member (`fail_to_retrieve_stored_sum`) since it
was coined. It has two now, and the second is in a different family and a
different failure mode.

## Every pairing is usable now

This is the largest change and the reason the slice was worth taking.

| | before | after |
|---|---:|---:|
| incompatible pairs analysable | 65 | **97** |
| pairings naming an unextracted machine | **43** | **0** |
| answerability rows | 87 | 90 |
| machines (both genres) | 189 | 232 |
| mapping rows | 787 | 1016 |
| normative arcs | 20 | 24 |
| canonical actions | 121 | 122 |

`unpaired_reference/4` is empty. Every productive/deformation pairing the
action-pair sources declare now has both of its machines extracted, so every one
of them contributes to the divergence analysis. The `sar_*` and `smr_*`
families — the largest bodies of pairing data in the repository, and the ones the
last report had to exclude as "not a sample of anything" — are in.

**And the cross-source stance audit now runs over 97 pairings instead of 65, with
the same result: no productive strategy carries a deforming step, and every
deformation carries one.** Thirty-two additional independent pairings, none of
which I consulted while assigning the 164 new labels, agree with the stance table
on first pass.

Divergence classes over the 97: 55 `substantive_break`, 19
`register_divergence`, 17 `same_register_neutral`, 6 `substantive_keep`. The
proportions barely moved, which is what a wider sample agreeing looks like.

## The five fraction schemes

| scheme | arc | parts from its deformation at | class |
|---|---|---|---|
| `splitting` | `keep_then_work_on` | step 1, `partition_into_equal_parts` against `unitize_referent` | register_divergence |
| `solve_for_unit` | `keep_then_work_on` | step 2, `assign_roles` against `iterate_unit` | register_divergence |
| `recursive_partition` | `keep_then_work_on` | step 2, `disembed_part` against `partition_into_equal_parts` | same_register_neutral |
| `improper_fraction_iteration` | `keep_then_work_on` | step 2, `disembed_part` against `iterate_unit` | register_divergence |
| `cross_multiplication_rule_from_pattern` | `unrecorded_run` | step 1, `read_operand_attribute` against `retrieve_known_fact` | register_divergence |

Four of the five share one arc, `keep_then_work_on`: the conservation is secured
early and the scheme keeps working after it. And in three of the five, the
divergence from the deformation is at the disembedding — `disembed_part` against
`iterate_unit` or against `partition_into_equal_parts`. Taking the part out while
it stays inside the whole is where these schemes part from the strategies that
look like them, which is the Steffe/Olive/Hackenberg claim, arriving as a
divergence class rather than as a citation.

`solve_for_unit` against `iterate_only_no_reverse` is the sharpest of them:
`assign_roles` against `iterate_unit` at step 2, and the deformation's fourth
edge is `exhaust_resource`. The productive scheme binds the unknown to a role
that can be both partitioned and iterated; the deformation iterates forward, has
nothing disembedded to invert, and reaches for an inverse edge that is not there.

`cross_multiplication_rule_from_pattern` is the one with no conservation record,
and it earns a look: its trace runs the rule, then dispatches to
`fraction/area_model_part_of_part` for the justification —
`justify_via_area_model_part_of_part` maps to `dispatch_to_kernel` — and binds
the two products to the whole and selected areas of the returned model. It does
the grounding work and no edge records it, which is exactly the class of gap the
answerability layer exists to name.

## The gap census grew, correctly

Conservation gaps went 44 to 48: 23 extraction gaps, 25 authoring gaps. The 43
new machines added 4 machines with no conserving or deforming step and one new
extraction gap. That is the census doing its job — a coverage increase that
brought its own backlog with it, named on arrival rather than discovered later.

## Verification

- **Byte equivalence**: 0 pre-existing transition facts changed, 272 added,
  observed set identical at 708 edges over 69 signatures.
- `scripts/checks/transition_tables.py`: builder rerun byte-identical.
- **Analyzer default path unchanged**: `45aee5ec…518039cc`, the same hash as
  before the flag existed and before the registration.
- `scripts/checks/action_vocabulary_map.py` (exit 0): 1016 mapping rows over 1016
  table triples and 802 census labels, none unmapped; 122 canonical actions, none
  unused; the stance-consistency audit clean with 9 deliberate inversions.
- `scripts/checks/action_grammar.py` (exit 0): 232 grammar rows for 232 machines;
  builder rerun byte-identical twice; the cross-source stance audit over 97
  pairings; every arc recomputed; the gap census exactly the 48.
- `run_all.sh` and the capability registry: the registry needed no regeneration,
  and the suite was running green as this was written.

Two new table files appeared, `calculus.pl` and `probability.pl`, because those
operations had zero registered signatures and now have two each. The dispatcher
already routed both; only the registry was silent.

## Honest limits

- **The 43 have no input contracts, so nothing has run them here.** Their tables
  carry static transitions extracted from the `Trace` lists. The code runs — the
  runners exist and the modules load — but this slice did not execute a single one
  of the 43 against an input. Everything downstream is an analysis of authored
  traces.
- **Twelve output type names are mine.** `product_without_commuted_roles`,
  `unrecovered_unknown_unit`, `nested_unit_fraction_of_inner_whole` and the rest
  follow the file's convention and describe what I read in the runner. A signature
  row is a contract a planner reads, so a wrong name here misleads a consumer,
  and these are the rows to check first.
- **`cross_multiplication_rule_without_ground` carries `validity(correct)`.** Its
  output type says `ungrounded_fraction_product` and not `incorrect_*`, because
  the answer is not wrong. If that reads as excusing it, the scorekeeper is the
  place that says otherwise: commitment without entitlement.
- **Four of the five fraction schemes sharing one arc may be the arc's
  coarseness.** `keep_then_work_on` covers 23 machines now. That four fraction
  schemes land in it says less than the divergence classes do.
- **None of this is wired into the application.** The tables are consumed by the
  vocabulary and grammar layers and by the analyzer's observed subset, which the
  43 do not join. The worker's dispatch is untouched.

## Result

- **43 signatures registered**; 171 automata to 214; 0 pre-existing facts changed;
  observed set identical, so the analyzer's guard and its output are untouched.
- **164 new labels needed 1 new canonical action.** The alphabet generalized, and
  two machines from other modules independently needed the deforming retention
  split out two reports ago.
- **Every pairing is analysable**: 65 to 97, unusable 43 to 0, and the
  cross-source stance audit holds over all 97.
- **The fraction schemes are extracted**, and three of the five part from their
  deformations at the disembedding.
- Next: input contracts for the 43, which is what would let them be run rather
  than only read.
