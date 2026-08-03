:- encoding(utf8).
/** <module> Addition action signatures — typing pilot (automata regularization)
 *
 * PILOT SCOPE. The addition family only: 18 automata, 59 action atoms,
 * as recorded in knowledge/strategies/transition_tables/addition.pl
 * (read from the consolidated dump, 2026-08-03). This file is an
 * ADDITIVE LAYER. It renames nothing, moves nothing, and no existing
 * consumer needs to change. Every atom in the transition tables keeps
 * its name; this file records, beside each atom, what kind of doing it
 * is and what the doing keeps or loses.
 *
 * WHAT THE LAYER CLAIMS. Three claims, each machine-checked by
 * check_pilot/0 at the bottom of this file:
 *
 *   1. TYPING IS TOTAL AND SINGLE-VALUED. Each of the 59 atoms has
 *      exactly one action_signature/4 row (check_coverage/0).
 *   2. THE 18 TRACES ARE RUNS OF 6 MACHINES. Project each recorded
 *      atom sequence through its signatures and the typed sequence is
 *      accepted by one of six folded machines with genuine branch
 *      points and loops (check_runs/0). The transition tables are
 *      witnesses — single accepting runs — of these machines; the
 *      machines are what the tables unroll.
 *   3. THE LEDGER IS HONEST AND AGREES WITH THE CORPUS CLASSIFICATION. The invariant
 *      losses a run incurs step-by-step equal the losses its closing
 *      verdict atom announces (check_ledger/0). The ledger and the
 *      corpus classification are two encodings authored from the same
 *      reading; check_validity/0 verifies that they agree for all 18
 *      kinds — correct / correct_but_inefficient / incorrect. It does
 *      not recover the classification independently.
 *
 * WHY VERDICT ATOMS ARE NOT ACTIONS. Atoms of the form preserve_* and
 * lose_* do not do anything to a quantity; they announce the state of
 * the run's invariant ledger. They are typed verdict/1 here and the
 * folded machines treat them as a closing announcement edge. The
 * honesty check (claim 3) is what makes keeping them defensible: an
 * announcement that always matches the incurred ledger is redundant
 * data but not noise. Whether to keep announcing is a later decision;
 * nothing here forces it.
 *
 * DUAL ACCEPTANCE (commitment and entitlement). Every machine run that
 * reaches an accepting state COMPLETES: a result is asserted, a
 * commitment undertaken. A run is VINDICATED only if it completes with
 * no unrepaired loss of an answer-bearing invariant: the entitlement is
 * kept. Deformation runs complete without vindication — the student
 * finishes and asserts, and is committed to what they cannot vindicate.
 * The predicates completes/1, vindicated/1, and derived_validity/2
 * encode this. This models the commitment/entitlement distinction; it
 * does not perform assertion, and nothing here decides whether a real
 * utterance undertakes a commitment.
 *
 * LIMITS, STATED PLAINLY.
 *   - The typing rows are authored interpretation, not extraction.
 *     Each is marked authored(typing_pilot). Disagreement with a row is
 *     a veto of that row, not of the layer.
 *   - The action-type vocabulary (19 types) and operator set (6
 *     operators) are provisional until at least two more families are
 *     typed. Cross-family pressure is expected to merge some types.
 *   - Witness sequences come from the consolidated dump, not the live
 *     tree. A live-tree diff is a required step before any brief.
 *   - The columnar machine's per-column loop edge is attested by the
 *     executable kernel (counting2:run_counter), not by the one-pass
 *     table witnesses; it is marked kernel_attested and no witness
 *     exercises it.
 *   - "ten" in kind names stays as data; the schemas are base-
 *     parametric. Named examples are illustrative of classes.
 */

:- module(addition_action_signatures,
          [ action_signature/4,
            schema/2,
            folded_edge/5,
            instantiates/3,
            deformation/5,
            witness_sequence/3,
            completes/1,
            vindicated/1,
            derived_validity/2,
            operator_applicable/3,
            predicted_unattested/3,
            check_pilot/0
          ]).

% ==========================================================================
% 1. THE TYPED ACTION ALPHABET
%
% action_signature(Atom, Type, Ledger, Provenance).
%
%   Atom       - the atom exactly as it appears in the transition tables.
%   Type       - the abstract doing, from the closed type vocabulary below.
%   Ledger     - effect on the invariant ledger:
%                  none, keeps(I), loses(I), suspends(I), restores(I),
%                  announces(ListOfKeepsAndLoses)  (verdict atoms only).
%   Provenance - authored(typing_pilot) for every row: these are
%                interpretive, vetoable one by one.
%
% Type vocabulary of the pilot (19 types):
%   select/2 assign/2 decompose/2 measure/2 transform/3 transfer/2
%   combine/2 compensate/2 retrieve/2 compare/3 iterate/2 align/1
%   traverse/2 inscribe/1 emit/1 drop/1 omit/1 corrupt/2 event/1
%   plus verdict/1 for announcement atoms.
%
% Invariants of the addition family:
%   total_conservation  - the two addends' total survives rearrangement.
%   base_regrouping     - regrouped units reach the next place.
%   problem_relation    - the answer stays answerable to THIS problem.
%   elaboration(P)      - the run uses the elaborated practice P rather
%                         than the practice P elaborates. Losing it
%                         keeps the answer and loses the economy.
% ==========================================================================

% --- selection and role assignment ---------------------------------------
action_signature(choose_larger_addend_as_start,
    select(start, larger_addend), none, authored(typing_pilot)).
action_signature(reset_to_zero_instead_of_starting_from_composite,
    select(start, zero), loses(elaboration(count_on)), authored(typing_pilot)).
action_signature(hold_other_addend_as_count,
    assign(count_role, other_addend), none, authored(typing_pilot)).
action_signature(choose_addend_near_base,
    select(anchor_side, nearest_base), none, authored(typing_pilot)).
action_signature(choose_rounding_target,
    select(anchor_side, rounding_candidate), none, authored(typing_pilot)).
action_signature(order_addends,
    select(operand_order, by_magnitude), none, authored(typing_pilot)).
action_signature(identify_target_base,
    select(anchor, next_base), none, authored(typing_pilot)).
action_signature(recognize_number_combination,
    select(fact_key, from_problem), none, authored(typing_pilot)).

% --- retrieval, comparison, iteration ------------------------------------
action_signature(retrieve_stored_sum,
    retrieve(sum, fact_store), none, authored(typing_pilot)).
action_signature(recall_nearby_known_fact,
    retrieve(anchor_fact, fact_store), none, authored(typing_pilot)).
action_signature(fail_to_retrieve_stored_sum,
    event(retrieval_failure), loses(elaboration(fact_retrieval)),
    authored(typing_pilot)).
action_signature(compare_target_to_anchor,
    compare(target, anchor, difference), none, authored(typing_pilot)).
% Defective comparison: apprehends nearness, not how near. The loss of
% problem_relation is incurred one step later, by the ungrounded rule.
action_signature(notice_that_numbers_are_near_but_not_how_near,
    compare(target, anchor, nearness_only), none, authored(typing_pilot)).
action_signature(iterate_successor_ticks,
    iterate(successor, counted_addend), none, authored(typing_pilot)).
action_signature(count_all_ticks,
    iterate(successor, both_addends), none, authored(typing_pilot)).
action_signature(count_first_addend_from_zero,
    iterate(successor, first_addend), none, authored(typing_pilot)).
action_signature(count_second_addend_from_first_total,
    iterate(successor, second_addend), none, authored(typing_pilot)).
action_signature(count_distance_to_base,
    measure(distance, to_anchor), none, authored(typing_pilot)).

% --- decomposition, transfer, combination --------------------------------
action_signature(decompose_second_addend,
    decompose(second_addend, base_and_ones), none, authored(typing_pilot)).
action_signature(split_other_addend,
    decompose(other_addend, needed_and_leftover), none, authored(typing_pilot)).
action_signature(transfer_from_smaller_to_larger,
    transfer(distance, between(smaller, larger)),
    keeps(total_conservation), authored(typing_pilot)).
% One-sided: the transfer arrives with no departure. The loss belongs to
% the omission of the balancing half, typed on the next atom.
action_signature(add_compensation_to_larger,
    transfer(distance, to(larger)), none, authored(typing_pilot)).
action_signature(leave_other_addend_unchanged,
    omit(balancing_transfer), loses(total_conservation),
    authored(typing_pilot)).
action_signature(make_base,
    combine(addend_and_needed_part, anchor), none, authored(typing_pilot)).
action_signature(add_leftover_after_base,
    combine(anchor_and_leftover, total),
    keeps(total_conservation), authored(typing_pilot)).
action_signature(drop_leftover_after_making_base,
    drop(leftover), loses(total_conservation), authored(typing_pilot)).
action_signature(add_base_chunk,
    combine(start_and_base_chunk, partial), none, authored(typing_pilot)).
action_signature(add_ones_chunk,
    combine(partial_and_ones_chunk, total),
    keeps(total_conservation), authored(typing_pilot)).
action_signature(drop_ones_chunk,
    drop(ones_chunk), loses(total_conservation), authored(typing_pilot)).

% --- anchor-and-compensate -----------------------------------------------
% round_up_by SUSPENDS conservation: the run is deliberately wrong in the
% middle. adjust_back_by RESTORES it. A suspension with no restoration
% before the run closes counts as a loss. This pair is the formal heart
% of the schema: omit_compensation can only strike where something is
% suspended or kept by a balancing half.
action_signature(round_up_by,
    transform(addend, to_anchor, delta),
    suspends(total_conservation), authored(typing_pilot)).
action_signature(add_with_rounded_number,
    combine(anchor_and_other, provisional_total), none,
    authored(typing_pilot)).
action_signature(adjust_back_by,
    compensate(delta, inverse), restores(total_conservation),
    authored(typing_pilot)).
action_signature(omit_adjustment,
    omit(compensation), loses(total_conservation), authored(typing_pilot)).
action_signature(adjust_known_sum_by,
    compensate(difference, toward_target), keeps(problem_relation),
    authored(typing_pilot)).
action_signature(apply_verbal_rule_with_wrong_adjustment,
    corrupt(adjustment, ungrounded_rule), loses(problem_relation),
    authored(typing_pilot)).

% --- columnar transduction -----------------------------------------------
action_signature(align_addends_by_place_value,
    align(place_value), none, authored(typing_pilot)).
action_signature(process_columns_right_to_left,
    traverse(columns, right_to_left), none, authored(typing_pilot)).
action_signature(write_place_digits,
    inscribe(place_digit), none, authored(typing_pilot)).
action_signature(write_full_column_sums_in_place,
    inscribe(full_column_sum), none, authored(typing_pilot)).
action_signature(compute_raw_column_sums_without_regrouping,
    combine(column, sum_without_regroup), loses(base_regrouping),
    authored(typing_pilot)).
action_signature(concatenate_partial_sums,
    combine(column_sums, concatenation), none, authored(typing_pilot)).
action_signature(compose_column_sum,
    combine(column, regrouped_sum), keeps(base_regrouping),
    authored(typing_pilot)).
action_signature(compose_column_sum_without_carry,
    combine(column, sum_without_carry), none, authored(typing_pilot)).
action_signature(carry_final_column_if_needed,
    transfer(carry, next_column), none, authored(typing_pilot)).
action_signature(discard_generated_carries,
    drop(carries), loses(base_regrouping), authored(typing_pilot)).
action_signature(misread_carry_amount,
    corrupt(carry_value, misreading), loses(base_regrouping),
    authored(typing_pilot)).

% --- emission -------------------------------------------------------------
action_signature(name_last_tick_as_sum,
    emit(sum), none, authored(typing_pilot)).
action_signature(state_memorized_sum,
    emit(sum), none, authored(typing_pilot)).

% --- verdict atoms: announcements, not doings -----------------------------
action_signature(preserve_base_ten_regrouping,
    verdict(announce), announces([keeps(base_regrouping)]),
    authored(typing_pilot)).
action_signature(lose_base_ten_regrouping,
    verdict(announce), announces([loses(base_regrouping)]),
    authored(typing_pilot)).
action_signature(preserve_total_by_balanced_transfer,
    verdict(announce), announces([keeps(total_conservation)]),
    authored(typing_pilot)).
action_signature(preserve_total_by_using_both_split_parts,
    verdict(announce), announces([keeps(total_conservation)]),
    authored(typing_pilot)).
action_signature(preserve_all_decomposed_parts,
    verdict(announce), announces([keeps(total_conservation)]),
    authored(typing_pilot)).
action_signature(lose_total_conservation,
    verdict(announce), announces([loses(total_conservation)]),
    authored(typing_pilot)).
% Dropping the remainder discards part of the total: announced as a
% conservation loss, since the remainder was a part the total needed.
action_signature(lose_decomposed_remainder,
    verdict(announce), announces([loses(total_conservation)]),
    authored(typing_pilot)).
action_signature(preserve_problem_relation,
    verdict(announce), announces([keeps(problem_relation)]),
    authored(typing_pilot)).
action_signature(lose_problem_relation,
    verdict(announce), announces([loses(problem_relation)]),
    authored(typing_pilot)).
action_signature(preserve_result_but_lose_count_on_efficiency,
    verdict(announce),
    announces([keeps(result), loses(elaboration(count_on))]),
    authored(typing_pilot)).
action_signature(preserve_result_but_lose_fact_fluency,
    verdict(announce),
    announces([keeps(result), loses(elaboration(fact_retrieval))]),
    authored(typing_pilot)).

% ==========================================================================
% 2. THE SIX FOLDED MACHINES
%
% folded_edge(Schema, State, Type, NextState, Attestation).
%
% Folding the strategy/deformation families back together is what makes
% these automata in the earning sense: states with more than one
% outgoing edge are the loci where the practice can be kept or lost,
% and loops are the iterations the one-pass tables unrolled. A witness
% accepted by a machine is a run of it; the 18 tables are 18 runs of
% these 6 machines.
%
% Attestation: witness(productive), witness(deformed), witness(both),
% or kernel_attested (the executable kernel carries the edge; no table
% witness exercises it).
% ==========================================================================

schema(add_count_iteration,
       'Counting as the doing: pick a start, iterate successors, name the last tick.').
schema(add_fact_retrieval,
       'The fact economy: probe the store; on failure, fall back to counting.').
schema(add_anchor_compensate,
       'Anchor at an easier problem, then repair the difference. Conservation is suspended mid-run and must be restored.').
schema(add_regroup_anchor,
       'Rearrange the addends toward a base without ever breaking the total. Conservation is kept continuously, by balance.').
schema(add_chunk_decompose,
       'Decompose one addend into chunks and add the chunks in turn. Every part must be spent.').
schema(add_columnar,
       'Place-value transduction: align, then per column inscribe and move the regrouped unit along.').

% --- M1: count iteration --------------------------------------------------
folded_edge(add_count_iteration, q_start, select(start, _), q_count, witness(both)).
folded_edge(add_count_iteration, q_count, assign(count_role, _), q_count, witness(productive)).
folded_edge(add_count_iteration, q_count, iterate(successor, _), q_count, witness(both)).
folded_edge(add_count_iteration, q_count, emit(sum), q_done, witness(productive)).
folded_edge(add_count_iteration, q_count, verdict(_), q_done, witness(deformed)).

% --- M2: fact retrieval, with the fallback branch at q_probe --------------
folded_edge(add_fact_retrieval, q_start, select(fact_key, _), q_probe, witness(both)).
folded_edge(add_fact_retrieval, q_probe, retrieve(sum, _), q_have, witness(productive)).
folded_edge(add_fact_retrieval, q_probe, event(retrieval_failure), q_fallback, witness(deformed)).
folded_edge(add_fact_retrieval, q_have, emit(sum), q_done, witness(productive)).
folded_edge(add_fact_retrieval, q_fallback, iterate(successor, _), q_fallback, witness(deformed)).
folded_edge(add_fact_retrieval, q_fallback, verdict(_), q_done, witness(deformed)).

% --- M3: anchor and compensate --------------------------------------------
folded_edge(add_anchor_compensate, q_start, retrieve(anchor_fact, _), q_anchored, witness(both)).
folded_edge(add_anchor_compensate, q_start, select(anchor_side, _), q_anchored, witness(both)).
folded_edge(add_anchor_compensate, q_anchored, select(anchor, _), q_anchored, witness(both)).
folded_edge(add_anchor_compensate, q_anchored, compare(target, anchor, _), q_related, witness(both)).
folded_edge(add_anchor_compensate, q_anchored, transform(addend, to_anchor, _), q_transformed, witness(both)).
folded_edge(add_anchor_compensate, q_transformed, combine(_, provisional_total), q_provisional, witness(both)).
folded_edge(add_anchor_compensate, q_related, compensate(_, _), q_adjusted, witness(productive)).
folded_edge(add_anchor_compensate, q_provisional, compensate(_, _), q_adjusted, witness(productive)).
folded_edge(add_anchor_compensate, q_related, corrupt(adjustment, _), q_adjusted, witness(deformed)).
folded_edge(add_anchor_compensate, q_provisional, omit(compensation), q_unrestored, witness(deformed)).
folded_edge(add_anchor_compensate, q_adjusted, verdict(_), q_done, witness(both)).
folded_edge(add_anchor_compensate, q_unrestored, verdict(_), q_done, witness(deformed)).

% --- M4: regroup toward anchor --------------------------------------------
folded_edge(add_regroup_anchor, q_start, select(anchor_side, _), q_sided, witness(both)).
folded_edge(add_regroup_anchor, q_start, select(operand_order, _), q_sided, witness(both)).
folded_edge(add_regroup_anchor, q_sided, select(anchor, _), q_sided, witness(both)).
folded_edge(add_regroup_anchor, q_sided, decompose(_, needed_and_leftover), q_parts, witness(both)).
folded_edge(add_regroup_anchor, q_sided, measure(distance, _), q_parts, witness(both)).
folded_edge(add_regroup_anchor, q_parts, combine(_, anchor), q_at_base, witness(both)).
folded_edge(add_regroup_anchor, q_parts, transfer(_, between(_, _)), q_at_base, witness(productive)).
folded_edge(add_regroup_anchor, q_parts, transfer(_, to(_)), q_one_sided, witness(deformed)).
folded_edge(add_regroup_anchor, q_one_sided, omit(balancing_transfer), q_lossy, witness(deformed)).
folded_edge(add_regroup_anchor, q_at_base, combine(_, total), q_total, witness(productive)).
folded_edge(add_regroup_anchor, q_at_base, drop(leftover), q_lossy, witness(deformed)).
folded_edge(add_regroup_anchor, q_at_base, verdict(_), q_done, witness(productive)).
folded_edge(add_regroup_anchor, q_total, verdict(_), q_done, witness(productive)).
folded_edge(add_regroup_anchor, q_lossy, verdict(_), q_done, witness(deformed)).

% --- M5: chunk decomposition ----------------------------------------------
folded_edge(add_chunk_decompose, q_start, decompose(_, base_and_ones), q_parts, witness(both)).
folded_edge(add_chunk_decompose, q_parts, combine(_, partial), q_partial, witness(both)).
folded_edge(add_chunk_decompose, q_partial, combine(_, total), q_total, witness(productive)).
folded_edge(add_chunk_decompose, q_partial, drop(ones_chunk), q_lossy, witness(deformed)).
folded_edge(add_chunk_decompose, q_total, verdict(_), q_done, witness(productive)).
folded_edge(add_chunk_decompose, q_lossy, verdict(_), q_done, witness(deformed)).

% --- M6: columnar transduction --------------------------------------------
folded_edge(add_columnar, q_start, align(place_value), q_aligned, witness(both)).
folded_edge(add_columnar, q_aligned, traverse(columns, _), q_column, witness(both)).
folded_edge(add_columnar, q_column, corrupt(carry_value, _), q_column, witness(deformed)).
folded_edge(add_columnar, q_column, inscribe(place_digit), q_written, witness(both)).
folded_edge(add_columnar, q_written, transfer(carry, next_column), q_carried, witness(both)).
folded_edge(add_columnar, q_written, drop(carries), q_uncarried, witness(deformed)).
folded_edge(add_columnar, q_carried, combine(column, regrouped_sum), q_composed, witness(productive)).
folded_edge(add_columnar, q_uncarried, combine(column, sum_without_carry), q_composed, witness(deformed)).
% The per-column loop. The one-pass tables summarize all columns into a
% single pass; the executable kernel (counting2:run_counter) carries the
% loop. No table witness exercises this edge.
folded_edge(add_columnar, q_carried, inscribe(place_digit), q_written, kernel_attested).
% The component-blind path: columns treated as unrelated, results
% concatenated. No traversal discipline, no carry.
folded_edge(add_columnar, q_aligned, combine(column, sum_without_regroup), q_raw, witness(deformed)).
folded_edge(add_columnar, q_raw, inscribe(full_column_sum), q_raw_written, witness(deformed)).
folded_edge(add_columnar, q_raw_written, combine(column_sums, concatenation), q_composed, witness(deformed)).
folded_edge(add_columnar, q_carried, verdict(_), q_done, witness(deformed)).
folded_edge(add_columnar, q_composed, verdict(_), q_done, witness(both)).

accepting(add_count_iteration, q_done).
accepting(add_fact_retrieval, q_done).
accepting(add_anchor_compensate, q_done).
% round_then_adjust closes on the restoring compensation with no verdict
% atom; the adjusted state itself accepts.
accepting(add_anchor_compensate, q_adjusted).
accepting(add_regroup_anchor, q_done).
accepting(add_chunk_decompose, q_done).
accepting(add_columnar, q_done).

% ==========================================================================
% 3. KIND -> SCHEMA MAPPING
%
% Kind names are untouched: every consumer that keys on them
% (curriculum lesson maps, visuals, mua_relations, incompatibility
% sets) keeps working. These rows are the record of how the 18 kinds
% fall into 6 schemas.
% ==========================================================================

instantiates(addition/count_on_from_larger, add_count_iteration,
             [start(larger_addend)]).
instantiates(addition/known_fact_retrieval, add_fact_retrieval,
             [probe(direct)]).
instantiates(addition/derived_fact_adjustment, add_anchor_compensate,
             [anchor(known_fact), repair(measured_difference)]).
instantiates(addition/round_then_adjust, add_anchor_compensate,
             [anchor(base_multiple), repair(inverse_delta)]).
instantiates(addition/make_ten_split_leftover, add_regroup_anchor,
             [anchor(next_base), means(decompose_other_addend)]).
instantiates(addition/make_base_transfer, add_regroup_anchor,
             [anchor(next_base), means(balanced_transfer)]).
instantiates(addition/base_ones_chunking, add_chunk_decompose,
             [parts(base_and_ones)]).
instantiates(addition/column_addition_with_carrying, add_columnar,
             [regrouping(carried)]).

% deformation(Kind, Schema, Operator, Locus, Loses).
%
% The operator set attested in the addition family (6 operators over 10
% deformations). Each deformation is its schema plus one operator
% applied at one locus — not a separate machine.
deformation(addition/count_all_when_count_on_available,
            add_count_iteration, fallback_to_unelaborated,
            locus(start_selection), [elaboration(count_on)]).
deformation(addition/count_all_instead_of_known_fact,
            add_fact_retrieval, fallback_to_unelaborated,
            locus(retrieval), [elaboration(fact_retrieval)]).
deformation(addition/rote_derived_fact_rule_misfire,
            add_anchor_compensate, ungrounded_rule,
            locus(compensation), [problem_relation]).
deformation(addition/round_without_adjusting,
            add_anchor_compensate, omit_compensation,
            locus(restoration), [total_conservation]).
deformation(addition/unbalanced_make_base_compensation,
            add_regroup_anchor, omit_compensation,
            locus(balancing_transfer), [total_conservation]).
deformation(addition/make_ten_drop_leftover,
            add_regroup_anchor, drop_part,
            locus(leftover), [total_conservation]).
deformation(addition/dropped_ones_chunk,
            add_chunk_decompose, drop_part,
            locus(ones_chunk), [total_conservation]).
deformation(addition/drop_carry_to_next_column,
            add_columnar, drop_part,
            locus(carry), [base_regrouping]).
deformation(addition/wrong_carry_amount_to_next_column,
            add_columnar, corrupt_value,
            locus(carry), [base_regrouping]).
deformation(addition/append_column_sum_without_carrying,
            add_columnar, component_blindness,
            locus(column_relation), [base_regrouping]).

% ==========================================================================
% 4. OPERATOR APPLICABILITY AND PREDICTION
%
% Each operator has a structural precondition. Where the precondition
% holds and no deformation is recorded, the corpus is predicted
% incomplete: a bug the recognizers should be ready for before any
% student produces it. predicted_unattested/3 enumerates these.
% ==========================================================================

% omit_compensation strikes where an invariant is held by a restoring
% or balancing edge: delete that edge and the invariant falls.
operator_applicable(omit_compensation, Schema, locus(Type)) :-
    folded_edge(Schema, _, Type, _, _),
    edge_ledger(Type, restores(_)).
operator_applicable(omit_compensation, Schema, locus(Type)) :-
    folded_edge(Schema, _, Type, _, _),
    Type = transfer(_, between(_, _)).

% drop_part strikes where a decomposition or a regrouping transfer puts
% a part in inventory that a later step must spend.
operator_applicable(drop_part, Schema, locus(Type)) :-
    folded_edge(Schema, _, Type, _, _),
    ( Type = decompose(_, _) ; Type = transfer(carry, _) ).

% corrupt_value strikes wherever a held quantity is read back.
operator_applicable(corrupt_value, Schema, locus(Type)) :-
    folded_edge(Schema, _, Type, _, _),
    ( Type = transfer(_, _) ; Type = measure(_, _) ; Type = iterate(_, _) ).

% fallback_to_unelaborated strikes wherever the schema is an elaborated
% practice standing on a simpler one (the pp-sufficiency ladder).
operator_applicable(fallback_to_unelaborated, add_count_iteration, locus(start_selection)).
operator_applicable(fallback_to_unelaborated, add_fact_retrieval, locus(retrieval)).
operator_applicable(fallback_to_unelaborated, add_columnar, locus(column_fact)).

% ungrounded_rule strikes wherever a compensation or regrouping step can
% be replaced by a verbal rule detached from the relation it repairs.
operator_applicable(ungrounded_rule, add_anchor_compensate, locus(compensation)).
operator_applicable(ungrounded_rule, add_columnar, locus(carry_ritual)).

edge_ledger(Type, Ledger) :-
    action_signature(_, Type0, Ledger, _),
    subsumes_term(Type, Type0).

%!  predicted_unattested(?Schema, ?Operator, ?Locus) is nondet.
%
%   Applicable operator instances with no recorded deformation.
%   Examples the closure yields (illustrative of the class, not a
%   finished list): a miscounted distance-to-base in make_base_transfer
%   (corrupt_value at measure/2); counting every column sum instead of
%   using facts in columnar work (fallback at column_fact); a carry
%   ritual applied without ground (ungrounded_rule at carry_ritual);
%   an off-by-one tick boundary in count_on (corrupt_value at
%   iterate/2).
predicted_unattested(Schema, Operator, Locus) :-
    operator_applicable(Operator, Schema, Locus),
    \+ attested_matching(Schema, Operator, Locus).

attested_matching(Schema, Operator, _Locus) :-
    deformation(_, Schema, Operator, _, _).

% ==========================================================================
% 5. WITNESSES
%
% witness_sequence(Kind, Atoms, Provenance): the exact atom sequences of
% the transition tables, one per kind, provenance to the static source
% recorded in the tables themselves. Generated from the consolidated
% dump; regenerate against the live tree before any brief.
% ==========================================================================

% (generated block follows)
witness_sequence(addition/append_column_sum_without_carrying,
    [ align_addends_by_place_value,
      compute_raw_column_sums_without_regrouping,
      write_full_column_sums_in_place,
      concatenate_partial_sums,
      lose_base_ten_regrouping
    ],
    provenance(static('knowledge/strategies/math/sar_add_action_pairs.pl:358'))).

witness_sequence(addition/base_ones_chunking,
    [ decompose_second_addend,
      add_base_chunk,
      add_ones_chunk,
      preserve_all_decomposed_parts
    ],
    provenance(static('knowledge/strategies/math/sar_add_action_pairs.pl:214'))).

witness_sequence(addition/column_addition_with_carrying,
    [ align_addends_by_place_value,
      process_columns_right_to_left,
      write_place_digits,
      carry_final_column_if_needed,
      compose_column_sum,
      preserve_base_ten_regrouping
    ],
    provenance(static('knowledge/strategies/math/sar_add_action_pairs.pl:309'))).

witness_sequence(addition/count_all_instead_of_known_fact,
    [ recognize_number_combination,
      fail_to_retrieve_stored_sum,
      count_all_ticks,
      preserve_result_but_lose_fact_fluency
    ],
    provenance(static('knowledge/strategies/math/sar_add_action_pairs.pl:428'))).

witness_sequence(addition/count_all_when_count_on_available,
    [ reset_to_zero_instead_of_starting_from_composite,
      count_first_addend_from_zero,
      count_second_addend_from_first_total,
      preserve_result_but_lose_count_on_efficiency
    ],
    provenance(static('knowledge/strategies/math/sar_add_action_pairs.pl:90'))).

witness_sequence(addition/count_on_from_larger,
    [ choose_larger_addend_as_start,
      hold_other_addend_as_count,
      iterate_successor_ticks,
      name_last_tick_as_sum
    ],
    provenance(static('knowledge/strategies/math/sar_add_action_pairs.pl:65'))).

witness_sequence(addition/derived_fact_adjustment,
    [ recall_nearby_known_fact,
      compare_target_to_anchor,
      adjust_known_sum_by,
      preserve_problem_relation
    ],
    provenance(static('knowledge/strategies/math/sar_add_action_pairs.pl:453'))).

witness_sequence(addition/drop_carry_to_next_column,
    [ align_addends_by_place_value,
      process_columns_right_to_left,
      write_place_digits,
      discard_generated_carries,
      compose_column_sum_without_carry,
      lose_base_ten_regrouping
    ],
    provenance(static('knowledge/strategies/math/sar_add_action_pairs.pl:332'))).

witness_sequence(addition/dropped_ones_chunk,
    [ decompose_second_addend,
      add_base_chunk,
      drop_ones_chunk,
      lose_decomposed_remainder
    ],
    provenance(static('knowledge/strategies/math/sar_add_action_pairs.pl:236'))).

witness_sequence(addition/known_fact_retrieval,
    [ recognize_number_combination,
      retrieve_stored_sum,
      state_memorized_sum
    ],
    provenance(static('knowledge/strategies/math/sar_add_action_pairs.pl:409'))).

witness_sequence(addition/make_base_transfer,
    [ order_addends,
      identify_target_base,
      count_distance_to_base,
      transfer_from_smaller_to_larger,
      preserve_total_by_balanced_transfer
    ],
    provenance(static('knowledge/strategies/math/sar_add_action_pairs.pl:165'))).

witness_sequence(addition/make_ten_drop_leftover,
    [ choose_addend_near_base,
      split_other_addend,
      make_base,
      drop_leftover_after_making_base,
      lose_total_conservation
    ],
    provenance(static('knowledge/strategies/math/sar_add_action_pairs.pl:140'))).

witness_sequence(addition/make_ten_split_leftover,
    [ choose_addend_near_base,
      split_other_addend,
      make_base,
      add_leftover_after_base,
      preserve_total_by_using_both_split_parts
    ],
    provenance(static('knowledge/strategies/math/sar_add_action_pairs.pl:116'))).

witness_sequence(addition/rote_derived_fact_rule_misfire,
    [ recall_nearby_known_fact,
      notice_that_numbers_are_near_but_not_how_near,
      apply_verbal_rule_with_wrong_adjustment,
      lose_problem_relation
    ],
    provenance(static('knowledge/strategies/math/sar_add_action_pairs.pl:473'))).

witness_sequence(addition/round_then_adjust,
    [ choose_rounding_target,
      identify_target_base,
      round_up_by,
      add_with_rounded_number,
      adjust_back_by
    ],
    provenance(static('knowledge/strategies/math/sar_add_action_pairs.pl:259'))).

witness_sequence(addition/round_without_adjusting,
    [ choose_rounding_target,
      identify_target_base,
      round_up_by,
      add_with_rounded_number,
      omit_adjustment,
      lose_total_conservation
    ],
    provenance(static('knowledge/strategies/math/sar_add_action_pairs.pl:284'))).

witness_sequence(addition/unbalanced_make_base_compensation,
    [ order_addends,
      identify_target_base,
      count_distance_to_base,
      add_compensation_to_larger,
      leave_other_addend_unchanged,
      lose_total_conservation
    ],
    provenance(static('knowledge/strategies/math/sar_add_action_pairs.pl:189'))).

witness_sequence(addition/wrong_carry_amount_to_next_column,
    [ align_addends_by_place_value,
      process_columns_right_to_left,
      misread_carry_amount,
      write_place_digits,
      carry_final_column_if_needed,
      lose_base_ten_regrouping
    ],
    provenance(static('knowledge/strategies/math/sar_add_action_pairs.pl:383'))).

% ==========================================================================
% 6. RUNS, LEDGER, DUAL ACCEPTANCE
% ==========================================================================

%!  kind_schema(?Kind, ?Schema) is nondet.
kind_schema(Kind, Schema) :- instantiates(Kind, Schema, _).
kind_schema(Kind, Schema) :- deformation(Kind, Schema, _, _, _).

%!  typed_projection(+Atoms, -Types) is det.
%
%   Project an atom sequence through the signatures.
typed_projection([], []).
typed_projection([A|As], [T|Ts]) :-
    action_signature(A, T, _, _),
    typed_projection(As, Ts).

%!  accepts(+Schema, +Types) is semidet.
%
%   The typed sequence is a run of the folded machine: a path from
%   q_start to an accepting state whose edge labels subsume the types
%   in order.
accepts(Schema, Types) :-
    accepts_from(Schema, q_start, Types).

accepts_from(Schema, State, []) :-
    accepting(Schema, State).
accepts_from(Schema, State, [T|Ts]) :-
    folded_edge(Schema, State, Label, Next, _),
    subsumes_term(Label, T),
    accepts_from(Schema, Next, Ts).

%!  incurred_losses(+Atoms, -Losses) is det.
%
%   The losses a run incurs: every loses(I) on a non-verdict atom, plus
%   every suspends(I) with no later restores(I). Deduplicated.
incurred_losses(Atoms, Losses) :-
    findall(I,
            ( member(A, Atoms),
              action_signature(A, T, loses(I), _),
              T \= verdict(_)
            ),
            Direct),
    findall(I,
            ( nth0(N, Atoms, A),
              action_signature(A, _, suspends(I), _),
              \+ ( nth0(M, Atoms, B), M > N,
                   action_signature(B, _, restores(I), _) )
            ),
            Unrestored),
    append(Direct, Unrestored, All),
    sort(All, Losses).

%!  announced_losses(+Atoms, -Losses) is det.
announced_losses(Atoms, Losses) :-
    findall(I,
            ( member(A, Atoms),
              action_signature(A, verdict(_), announces(L), _),
              member(loses(I), L)
            ),
            All),
    sort(All, Losses).

%!  completes(?Kind) is nondet.
%
%   The run reaches an accepting state: a result is asserted, a
%   commitment undertaken. All 18 kinds complete.
completes(Kind) :-
    witness_sequence(Kind, Atoms, _),
    kind_schema(Kind, Schema),
    typed_projection(Atoms, Types),
    accepts(Schema, Types).

%!  vindicated(?Kind) is nondet.
%
%   The run completes and keeps every invariant it is answerable to:
%   entitlement kept. Elaboration losses do not block vindication of
%   the answer; they block vindication of the economy, recorded by
%   derived_validity/2 instead.
vindicated(Kind) :-
    completes(Kind),
    witness_sequence(Kind, Atoms, _),
    incurred_losses(Atoms, Losses),
    \+ ( member(I, Losses), answer_bearing(I) ).

answer_bearing(total_conservation).
answer_bearing(base_regrouping).
answer_bearing(problem_relation).

%!  derived_validity(?Kind, ?Validity) is nondet.
%
%   The ledger and corpus classification are two authored encodings of
%   the same reading. check_validity/0 verifies their agreement; it
%   does not recover validity independently.
derived_validity(Kind, Validity) :-
    witness_sequence(Kind, Atoms, _),
    incurred_losses(Atoms, Losses),
    (   member(I, Losses), answer_bearing(I)
    ->  Validity = incorrect
    ;   member(elaboration(_), Losses)
    ->  Validity = correct_but_inefficient
    ;   Validity = correct
    ).

% The executable layer's recorded validity, for the recovery check.
% Source: sar_add_action_pairs.pl validity/1 fields, read from the
% consolidated dump 2026-08-03.
corpus_validity(addition/count_on_from_larger, correct).
corpus_validity(addition/count_all_when_count_on_available, correct_but_inefficient).
corpus_validity(addition/make_ten_split_leftover, correct).
corpus_validity(addition/make_ten_drop_leftover, incorrect).
corpus_validity(addition/make_base_transfer, correct).
corpus_validity(addition/unbalanced_make_base_compensation, incorrect).
corpus_validity(addition/base_ones_chunking, correct).
corpus_validity(addition/dropped_ones_chunk, incorrect).
corpus_validity(addition/round_then_adjust, correct).
corpus_validity(addition/round_without_adjusting, incorrect).
corpus_validity(addition/column_addition_with_carrying, correct).
corpus_validity(addition/drop_carry_to_next_column, incorrect).
corpus_validity(addition/append_column_sum_without_carrying, incorrect).
corpus_validity(addition/wrong_carry_amount_to_next_column, incorrect).
corpus_validity(addition/known_fact_retrieval, correct).
corpus_validity(addition/count_all_instead_of_known_fact, correct_but_inefficient).
corpus_validity(addition/derived_fact_adjustment, correct).
corpus_validity(addition/rote_derived_fact_rule_misfire, incorrect).

% ==========================================================================
% 7. THE CHECKS
% ==========================================================================

check_coverage :-
    findall(A, (witness_sequence(_, Atoms, _), member(A, Atoms)), As0),
    sort(As0, Atoms),
    length(Atoms, N),
    (   N =:= 59
    ->  true
    ;   format('FAIL coverage: ~w distinct atoms, expected 59~n', [N]), fail
    ),
    forall(member(A, Atoms),
           ( findall(T, action_signature(A, T, _, _), Ts),
             (   Ts = [_]
             ->  true
             ;   format('FAIL coverage: ~w has ~w signatures~n', [A, Ts]),
                 fail
             ) )).

check_runs :-
    forall(witness_sequence(Kind, _, _),
           (   completes(Kind)
           ->  true
           ;   format('FAIL run: ~w not accepted by its machine~n', [Kind]),
               fail
           )).

check_ledger :-
    forall(witness_sequence(Kind, Atoms, _),
           ( incurred_losses(Atoms, Inc),
             announced_losses(Atoms, Ann),
             (   Inc == Ann
             ->  true
             ;   format('FAIL ledger ~w: incurred ~w, announced ~w~n',
                        [Kind, Inc, Ann]),
                 fail
             ) )).

check_validity :-
    forall(corpus_validity(Kind, V),
           (   derived_validity(Kind, V)
           ->  true
           ;   derived_validity(Kind, W),
               format('FAIL validity ~w: derived ~w, corpus ~w~n',
                      [Kind, W, V]),
               fail
           )).

check_pilot :-
    check_coverage,
    format('coverage: 59 atoms, one signature each ... ok~n'),
    check_runs,
    format('runs: 18 witnesses accepted by 6 machines ... ok~n'),
    check_ledger,
    format('ledger: announced losses = incurred losses, 18/18 ... ok~n'),
    check_validity,
    format('validity: two authored encodings agree, 18/18 ... ok~n'),
    aggregate_all(count, vindicated(_), NV),
    NV =:= 10,
    aggregate_all(count, predicted_unattested(_, _, _), NP),
    format('vindicated: ~w of 18 complete runs~n', [NV]),
    format('predicted unattested deformations: ~w~n', [NP]).
