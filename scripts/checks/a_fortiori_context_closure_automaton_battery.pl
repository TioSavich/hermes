% PURPOSE: State exactly which reviewed context nestings are decided by the
% loaded comparison automata, using hand-worked inputs before any certificate
% claim is made.
/** <module> A-fortiori context-closure automaton boundary
 *
 * The closure source records reviewed strict input-class inclusions. The loaded
 * gap and decimal viability automata decide different classes. Their output
 * contexts are checked here on a coinciding and a diverging input each. The
 * scale-loss row is explicit: its narrow endpoint is automaton-checked while
 * its broad endpoint has no decider, so the inclusion remains asserted.
 *
 * Run: swipl -q -l paths.pl -s scripts/checks/a_fortiori_context_closure_automaton_battery.pl -g main -t halt
 */
:- use_module(math(smr_frac_benchmark_compare), [run_gap_thinking_compare/7]).
:- use_module(math(smr_decimal_fraction_compare), [run_decimal_scale_loss_compare/7]).
:- use_module(math(decimal_action_pairs), [run_decimal_action/5]).
:- use_module(incompat(incompatibility_sets), [a_fortiori_context_nesting/4]).

main :-
    gap_contexts(GapCoinciding, GapDiverging),
    decimal_order_contexts(DecimalCoinciding, DecimalDiverging),
    decimal_operation_contexts(OperationCoinciding, OperationDiverging),
    Observed = [GapCoinciding, GapDiverging,
                DecimalCoinciding, DecimalDiverging,
                OperationCoinciding, OperationDiverging],
    closure_statuses(Observed),
    format("PASS a-fortiori automaton battery: no shipped nesting has a certified inclusion~n"),
    format("  gap inputs 1/3 vs 1/4, then 5/6 vs 7/8: ~w, ~w~n",
           [GapCoinciding, GapDiverging]),
    format("  decimal-order inputs 0.1 vs 0.2, then 0.8 vs 0.14: ~w, ~w~n",
           [DecimalCoinciding, DecimalDiverging]),
    format("  decimal-operation inputs 1.2 + 0.3, then 1.2 + 0.03: ~w, ~w~n",
           [OperationCoinciding, OperationDiverging]).
main :-
    format("FAIL a closure status or automaton boundary is inconsistent~n"),
    halt(1).

gap_contexts(Coinciding, Diverging) :-
    run_gap_thinking_compare(1, 3, 1, 4, _Result, CoincidingViability, _),
    CoincidingViability = viability(contextual_success, condition(Coinciding),
                                    validity(contextually_correct)),
    run_gap_thinking_compare(5, 6, 7, 8, _DivergingResult, DivergingViability, _),
    DivergingViability = viability(fails_in_context, condition(Diverging),
                                   expected(_), produced(_), validity(incorrect)).

decimal_order_contexts(Coinciding, Diverging) :-
    run_decimal_scale_loss_compare(1, 10, 2, 10, _Result, CoincidingViability, _),
    CoincidingViability = viability(contextual_success, condition(Coinciding),
                                    validity(contextually_correct)),
    run_decimal_scale_loss_compare(8, 10, 14, 100, _DivergingResult, DivergingViability, _),
    DivergingViability = viability(fails_in_context, condition(Diverging),
                                   expected(_), produced(_), validity(incorrect)).

decimal_operation_contexts(Coinciding, Diverging) :-
    run_decimal_action(decimal_add_unaligned_numerals,
                       decimal_pair(12, 10, 3, 10), ignored, CoincidingOutcome, _),
    outcome_viability(CoincidingOutcome,
                      viability(contextual_success, condition(Coinciding),
                                validity(contextually_correct))),
    run_decimal_action(decimal_add_unaligned_numerals,
                       decimal_pair(12, 10, 3, 100), ignored, DivergingOutcome, _),
    outcome_viability(DivergingOutcome,
                      viability(fails_in_context, condition(Diverging),
                                expected(_), produced(_), validity(incorrect))).

outcome_viability(action_outcome(_, Fields), Viability) :-
    memberchk(viability(Viability), Fields).

closure_statuses(Observed) :-
    forall(a_fortiori_context_nesting(Narrow, Broad, Status, Warrant),
           closure_status(Narrow, Broad, Status, Warrant, Observed)).

closure_status(written_numeral_order_diverges_from_decimal_value_order,
               the_numerals_carry_different_place_counts, asserted, Warrant,
               Observed) :-
    !,
    memberchk(written_numeral_order_diverges_from_decimal_value_order, Observed),
    \+ memberchk(the_numerals_carry_different_place_counts, Observed),
    format("  written-numeral subset different-place-count: asserted (~w); narrow endpoint reimplementation certified only~n",
           [Warrant]).
closure_status(gap_order_diverges_from_fraction_order,
               inverse_denominator_order_diverges_for_unequal_numerators,
               asserted, Warrant, Observed) :-
    !,
    memberchk(gap_order_diverges_from_fraction_order, Observed),
    \+ memberchk(inverse_denominator_order_diverges_for_unequal_numerators, Observed),
    format("  equal-gap subset inverse-denominator: asserted (~w); automaton probes the 974-member condition, while R1 fixes the 440-member input class~n",
           [Warrant]).
closure_status(Narrow, Broad, Status, Warrant, Observed) :-
    Status == asserted,
    \+ memberchk(Narrow, Observed),
    \+ memberchk(Broad, Observed),
    format("  ~w subset ~w: ~w (~w); no deciding automaton loaded~n",
           [Narrow, Broad, Status, Warrant]).
