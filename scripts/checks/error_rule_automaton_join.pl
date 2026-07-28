% PURPOSE: Proves the coded gap-thinking hyperedge and the gap-thinking automaton name the same
% divergence class, by running the automaton and looking the atom it returns up in the break set.
/** <module> The join between a coded error rule and the automaton that computes its domain
 *
 * `smr_frac_benchmark_compare:gap_viability/3` decides, per input pair, whether
 * gap order coincides with fraction order or diverges from it. The research
 * corpus's coded gap rules carry that same divergence class as the third element
 * of their incompatibility triple. The two were written apart, so a shared name
 * is the only thing holding them together, and a shared name is exactly what
 * drifts.
 *
 * This check runs the automaton on a coinciding pair and on a diverging pair,
 * takes the condition atom the automaton returns for the diverging case, and
 * requires that atom to appear as the context element of a coded error-rule
 * break. It fails if the automaton stops returning that atom, if the generated
 * breaks stop carrying it, or if either side is renamed without the other.
 *
 * Decimal error rows are not coded yet.  Their contexts therefore have no
 * generated break to join to.  The lower half of this check instead asserts
 * named coinciding and diverging inputs for every new decimal context, including
 * both action rules that share the operation context.
 *
 * Run: swipl -q -l paths.pl -s scripts/checks/error_rule_automaton_join.pl -g main -t halt
 */
:- use_module(math(smr_frac_benchmark_compare), [run_gap_thinking_compare/7]).
:- use_module(math(smr_decimal_fraction_compare),
              [run_decimal_scale_loss_compare/7]).
:- use_module(math(decimal_action_pairs), [run_decimal_action/5]).
:- use_module(incompat(defeasible_inference), [error_rule_break/2, error_rule_source/2]).
% member/2 and memberchk/2 are autoloaded; importing library(lists) here clashes
% with the utils module paths.pl already puts on the user import list.

main :-
    coinciding_case(Coinciding),
    diverging_case(Diverging),
    join_holds(Diverging, Breaks),
    decimal_order_contexts(DecimalOrderCoinciding, DecimalOrderDiverging),
    decimal_operation_contexts(DecimalOperationCoinciding,
                               DecimalOperationDiverging),
    length(Breaks, Count),
    format("PASS gap automaton and coded rules share a divergence class~n"),
    format("  coinciding input returns ~w~n", [Coinciding]),
    format("  diverging input returns ~w~n", [Diverging]),
    format("  coded error-rule breaks carrying o(context(~w)): ~w~n", [Diverging, Count]),
    forall(member(BreakId, Breaks), report_break(BreakId)),
    format("PASS decimal contexts return on named inputs (no decimal rows are coded)~n"),
    format("  written-numeral order: ~w / ~w~n",
           [DecimalOrderCoinciding, DecimalOrderDiverging]),
    format("  unaligned decimal operation: ~w / ~w~n",
           [DecimalOperationCoinciding, DecimalOperationDiverging]).
main :-
    format("FAIL the gap automaton and the coded gap rules no longer name one divergence class~n"),
    halt(1).

%!  coinciding_case(-Condition) is semidet.
%
%   1/3 against 1/4: gaps 2 and 3, and 1/3 is the larger fraction, so the gap
%   ordering returns what the sanctioned comparison returns.
coinciding_case(Condition) :-
    run_gap_thinking_compare(1, 3, 1, 4, _Result, Viability, _History),
    Viability = viability(contextual_success, condition(Condition), validity(contextually_correct)).

%!  diverging_case(-Condition) is semidet.
%
%   5/6 against 7/8: equal gaps, so the gap ordering calls them equivalent while
%   the sanctioned comparison does not.
diverging_case(Condition) :-
    run_gap_thinking_compare(5, 6, 7, 8, _Result, Viability, _History),
    Viability = viability(fails_in_context, condition(Condition),
                          expected(_), produced(_), validity(incorrect)).

%!  decimal_order_contexts(-Coinciding, -Diverging) is semidet.
%
%   0.1 against 0.2 has a matching written-numeral and value order.  0.8
%   against 0.14 reverses the two orders: 8 < 14 as written numerals while
%   8/10 > 14/100 as decimal values.  Both decimal comparison deformations
%   return the divergence condition.
decimal_order_contexts(Coinciding, Diverging) :-
    run_decimal_scale_loss_compare(1, 10, 2, 10, _CoincidingResult,
                                   CoincidingViability, _CoincidingHistory),
    CoincidingViability = viability(
        contextual_success,
        condition(Coinciding),
        validity(contextually_correct)),
    run_decimal_scale_loss_compare(8, 10, 14, 100, _DivergingResult,
                                   DivergingViability, _DivergingHistory),
    DivergingViability = viability(
        fails_in_context,
        condition(Diverging), expected(_), produced(_), validity(incorrect)),
    run_decimal_action(decimal_numeral_comparison_without_scale_alignment,
                       decimal_pair(8, 10, 14, 100), ignored, Outcome, _Trace),
    outcome_viability(Outcome,
                      viability(fails_in_context, condition(Diverging),
                                expected(_), produced(_), validity(incorrect))).

%!  decimal_operation_contexts(-Coinciding, -Diverging) is semidet.
%
%   With 1.2 and 0.3 both written in tenths, raw numeral addition agrees with
%   aligned-unit addition.  With 1.2 and 0.03, it does not.  The same latter
%   input also makes raw numeral subtraction diverge, so the context is shared
%   by two distinct operation rules rather than minted for one deformation.
decimal_operation_contexts(Coinciding, Diverging) :-
    run_decimal_action(decimal_add_unaligned_numerals,
                       decimal_pair(12, 10, 3, 10), ignored, CoincidingOutcome, _),
    outcome_viability(CoincidingOutcome,
                      viability(contextual_success, condition(Coinciding),
                                validity(contextually_correct))),
    run_decimal_action(decimal_add_unaligned_numerals,
                       decimal_pair(12, 10, 3, 100), ignored, AddDivergingOutcome, _),
    outcome_viability(AddDivergingOutcome,
                      viability(fails_in_context, condition(Diverging),
                                expected(_), produced(_), validity(incorrect))),
    run_decimal_action(decimal_subtract_unaligned_numerals,
                       decimal_pair(12, 10, 3, 100), ignored,
                       SubtractDivergingOutcome, _),
    outcome_viability(SubtractDivergingOutcome,
                      viability(fails_in_context, condition(Diverging),
                                expected(_), produced(_), validity(incorrect))).

outcome_viability(action_outcome(_, Fields), Viability) :-
    memberchk(viability(Viability), Fields).

join_holds(Condition, Breaks) :-
    findall(BreakId,
            ( error_rule_break(BreakId, Conditions),
              memberchk(o(context(Condition)), Conditions)
            ),
            Breaks0),
    sort(Breaks0, Breaks),
    Breaks = [_|_].

report_break(BreakId) :-
    ( error_rule_source(BreakId, Rows) -> true ; Rows = [] ),
    format("    ~w (error_instances ~w)~n", [BreakId, Rows]).
