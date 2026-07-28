% PURPOSE: State exactly which reviewed context nestings are decided by the
% loaded comparison automata, using hand-worked inputs before any certificate
% claim is made.
/** <module> A-fortiori context-closure automaton boundary
 *
 * The closure source records two strict input-class inclusions.  They concern
 * divisor magnitude and decimal-expansion periodicity.  The loaded gap and
 * decimal viability automata decide different classes: their output contexts
 * are checked here on a coinciding and a diverging input each.  The check then
 * proves that neither endpoint of a shipped closure nesting is emitted by
 * those automata.  Consequently this battery does not upgrade either asserted
 * warrant to an automaton certificate.
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
    format("PASS a-fortiori automaton battery: no shipped nesting is automaton-certified~n"),
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
           ( Status == asserted,
             \+ memberchk(Narrow, Observed),
             \+ memberchk(Broad, Observed),
             format("  ~w subset ~w: ~w (~w); no deciding automaton loaded~n",
                    [Narrow, Broad, Status, Warrant])
           )).
