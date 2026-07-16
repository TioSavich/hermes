/** <module> Student Division Strategy: Conversion to Groups Other than Bases (CGOB)
 *
 * Canonical strategy key: 'CGOB'. The module name (smr_div_cbo) and the
 * exported predicate (run_cbo_div/5) retain the legacy "cbo" spelling so that
 * importers do not break; only the user-facing strategy label is CGOB. CGOB is
 * the inverse of the multiplicative CBO ("Conversion to Bases and Ones"), which
 * lives in smr_mult_cbo.pl — do not conflate the two.
 *
 * This module implements a sophisticated division strategy, sometimes called
 * "Conversion to Groups Other than Bases," modeled as a finite state machine.
 * It solves a division problem (T / S) by leveraging knowledge of a counting
 * base (e.g., 10).
 *
 * The process is as follows:
 * 1.  Decompose the total (T) into a number of bases (TB) and ones (TO).
 * 2.  Analyze the base itself: determine how many groups of size S can be
 *     made from one base, and what the remainder is. (e.g., "how many 4s in 10?").
 * 3.  Use this knowledge to quickly calculate the quotient and remainder that
 *     result from the "bases" part of the total (TB).
 * 4.  Combine the remainder from the bases with the original "ones" part (TO).
 * 5.  Process this combined final remainder to see how many more groups of
 *     size S can be made.
 * 6.  Sum the quotients from the base and remainder parts to get the final answer.
 * 7.  The strategy fails if the divisor (S) is not positive.
 *
 * The state is represented by the term:
 * `state(Name, T_Bases, T_Ones, Quotient, Remainder, S_in_Base, Rem_in_Base, Total, Divisor)`
 *
 * The history of execution is captured as a list of steps:
 * `step(Name, Quotient, Remainder, Interpretation)`
 *
 * 
 * 
 */
:- module(smr_div_cbo,
          [ run_cbo_div/5,
            run_cbo_div/6,
            % FSM Engine Interface
            setup_strategy/4,
            transition/3,
            transition/4,
            accept_state/1,
            final_interpretation/2,
            extract_result_from_history/2
          ]).

:- use_module(library(lists)).
:- use_module(strategies(fsm_engine), [run_fsm_with_base/5]).
:- use_module(formalization(grounded_arithmetic), [incur_cost/1, integer_to_recollection/2,
                                     recollection_to_integer/2, add_grounded/3,
                                     multiply_grounded/3, smaller_than/2]).
:- use_module(formalization(grounded_utils), [base_decompose_grounded/4]).
:- use_module(arche_trace(sequent_engine), [s/1, comp_nec/1, exp_poss/1]).

%!      run_cbo_div(+T:integer, +S:integer, +Base:integer, -FinalQuotient:integer, -FinalRemainder:integer) is det.
%
%       Executes the 'Conversion to Groups Other than Bases' division strategy
%       for T / S, using the specified Base.
%
%       This predicate initializes and runs a state machine that models the CBO
%       division strategy. It first checks for a positive divisor. If valid, it
%       decomposes the dividend `T` and uses knowledge about the `Base` to find
%       the quotient and remainder. It traces the entire execution.
%
%       @param T The Dividend (Total).
%       @param S The Divisor (Size of groups).
%       @param Base The numerical base to use for decomposition (e.g., 10).
%       @param FinalQuotient The quotient of the division.
%       @param FinalRemainder The remainder of the division. If S is not
%       positive, this will be the atom `'error'`.

run_cbo_div(T, S, Base, FinalQuotient, FinalRemainder) :-
    run_cbo_div(T, S, Base, FinalQuotient, FinalRemainder, _History).

%!      run_cbo_div(+T, +S, +Base, -FinalQuotient, -FinalRemainder, -History) is det.
%
%       As run_cbo_div/5, but exposes the FSM execution History so callers
%       (strategy-trace surfaces, the event log) get the actual step sequence
%       instead of discarding it.
run_cbo_div(T, S, Base, FinalQuotient, FinalRemainder, History) :-
    % Use the FSM engine to run this strategy
    setup_strategy(T, S, InitialState, Parameters),
    run_fsm_with_base(smr_div_cbo, InitialState, Parameters, Base, History),
    extract_result_from_history(History, [FinalQuotient, FinalRemainder]).

%!      setup_strategy(+T, +S, -InitialState, -Parameters) is det.
%
%       Sets up the initial state for the CBO division strategy.
setup_strategy(T, S, InitialState, Parameters) :-
    % Check if division is valid using grounded comparison
    integer_to_recollection(S, RecS),
    (   \+ grounded_utils:is_positive_grounded(RecS)
    ->  InitialState = state(q_error, 0, 0, 0, 0, 0, 0, T, S)
    ;   InitialState = state(q_init, 0, 0, 0, 0, 0, 0, T, S)
    ),
    Parameters = [T, S],

    % Emit modal signal for strategy initiation
    s(exp_poss(initiating_cbo_division_strategy)),
    incur_cost(inference).

%!      transition(+StateNum, -NextStateNum, -Action) is det.
%
%       State transitions for CBO division FSM.

transition(q_init, q_decompose, decompose_dividend) :-
    s(comp_nec(transitioning_to_decomposition)),
    incur_cost(state_change).

transition(q_decompose, q_analyze_base, analyze_base_divisibility) :-
    s(exp_poss(analyzing_base_for_group_formation)),
    incur_cost(analysis).

transition(q_analyze_base, q_process_bases, process_base_groups) :-
    s(comp_nec(processing_base_components)),
    incur_cost(computation).

transition(q_process_bases, q_combine_R, combine_remainders) :-
    s(exp_poss(combining_remainder_components)),
    incur_cost(combination).

transition(q_combine_R, q_process_R, process_final_remainder) :-
    s(comp_nec(processing_combined_remainder)),
    incur_cost(remainder_processing).

transition(q_process_R, q_accept, finalize_division) :-
    s(exp_poss(finalizing_cbo_division_result)),
    incur_cost(finalization).

transition(q_error, q_error, maintain_error) :-
    s(comp_nec(error_state_is_absorbing)),
    incur_cost(error_handling).

%!      transition(+State, +Base, -NextState, -Interpretation) is det.
%
%       Complete state transitions with full state tracking.

% From q_init, decompose T and proceed to analyze the base.
transition(state(q_init, _TB, _TO, Q, R, SiB, RiB, T, S), Base,
           state(q_decompose, NewTB, NewTO, Q, R, SiB, RiB, T, S),
           Interpretation) :-
    s(exp_poss(decomposing_dividend_into_base_components)),
    integer_to_recollection(T, RecT),
    integer_to_recollection(Base, RecBase),
    base_decompose_grounded(RecT, RecBase, RecQuotient, RecRemainder),
    recollection_to_integer(RecQuotient, NewTB),
    recollection_to_integer(RecRemainder, NewTO),
    format(atom(Interpretation), 'Initialize: ~w/~w. Decompose T: ~w Bases + ~w Ones.', [T, S, NewTB, NewTO]),
    incur_cost(decomposition).

% In q_decompose, prepare for base analysis
transition(state(q_decompose, TB, TO, Q, R, SiB, RiB, T, S), _,
           state(q_analyze_base, TB, TO, Q, R, SiB, RiB, T, S), 
           'Preparing base analysis.') :-
    s(comp_nec(preparing_base_divisibility_analysis)),
    incur_cost(preparation).

% In q_analyze_base, determine how many groups of S fit in one Base.
transition(state(q_analyze_base, TB, TO, Q, R, _, _, T, S), Base,
           state(q_process_bases, TB, TO, Q, R, SiB, RiB, T, S),
           Interpretation) :-
    s(exp_poss(calculating_base_group_capacity)),
    integer_to_recollection(Base, RecBase),
    integer_to_recollection(S, RecS),
    base_decompose_grounded(RecBase, RecS, RecSiB, RecRiB),
    recollection_to_integer(RecSiB, SiB),
    recollection_to_integer(RecRiB, RiB),
    format(atom(Interpretation), 'Analyze Base: One Base (~w) = ~w group(s) of ~w + Remainder ~w.', [Base, SiB, S, RiB]),
    incur_cost(base_analysis).

% In q_process_bases, calculate the quotient and remainder from the "bases" part of T.
transition(state(q_process_bases, TB, TO, _, _, SiB, RiB, T, S), _,
           state(q_combine_R, TB, TO, NewQ, NewR, SiB, RiB, T, S),
           Interpretation) :-
    s(comp_nec(processing_base_component_groups)),
    integer_to_recollection(TB, RecTB),
    integer_to_recollection(SiB, RecSiB),
    integer_to_recollection(RiB, RecRiB),
    multiply_grounded(RecTB, RecSiB, RecNewQ),
    recollection_to_integer(RecNewQ, NewQ),
    multiply_grounded(RecTB, RecRiB, RecNewR),
    recollection_to_integer(RecNewR, NewR),
    format(atom(Interpretation), 'Process ~w Bases: Yields ~w groups and ~w remainder.', [TB, NewQ, NewR]),
    incur_cost(base_processing).

% In q_combine_R, add the remainder from the bases to the original ones part of T.
transition(state(q_combine_R, _, TO, Q, R, SiB, RiB, T, S), _,
           state(q_process_R, _, TO, Q, NewR, SiB, RiB, T, S),
           Interpretation) :-
    s(exp_poss(combining_base_and_ones_remainders)),
    integer_to_recollection(R, RecR),
    integer_to_recollection(TO, RecTO),
    add_grounded(RecR, RecTO, RecNewR),
    recollection_to_integer(RecNewR, NewR),
    format(atom(Interpretation), 'Combine Remainders: ~w (from Bases) + ~w (from Ones) = ~w.', [R, TO, NewR]),
    incur_cost(remainder_combination).

% In q_process_R, find the quotient and remainder from the combined remainder, then accept.
transition(state(q_process_R, _, _, Q, R, _, _, T, S), _,
           state(q_accept, _, _, NewQ, NewR, _, _, T, S),
           Interpretation) :-
    s(exp_poss(finalizing_remainder_processing)),
    integer_to_recollection(R, RecR),
    integer_to_recollection(S, RecS),
    base_decompose_grounded(RecR, RecS, RecQFromR, RecNewR),
    recollection_to_integer(RecQFromR, Q_from_R),
    recollection_to_integer(RecNewR, NewR),
    integer_to_recollection(Q, RecQ),
    integer_to_recollection(Q_from_R, RecQFromR2),
    add_grounded(RecQ, RecQFromR2, RecNewQ),
    recollection_to_integer(RecNewQ, NewQ),
    format(atom(Interpretation), 'Process Remainder: Yields ~w additional group(s).', [Q_from_R]),
    incur_cost(final_processing).

transition(state(q_error, _, _, _, _, _, _, _, _), _,
           state(q_error, 0, 0, 0, 0, 0, 0, 0, 0),
           'Error: Invalid divisor.') :-
    s(comp_nec(error_state_persistence)),
    incur_cost(error_maintenance).

%!      accept_state(+State) is semidet.
%
%       Defines accepting states for the FSM.
accept_state(state(q_accept, _, _, _, _, _, _, _, _)).

%!      final_interpretation(+State, -Interpretation) is det.
%
%       Provides final interpretation of the computation.
final_interpretation(state(q_accept, _, _, Quotient, Remainder, _, _, _, _), Interpretation) :-
    format(atom(Interpretation), 'Successfully computed division: Quotient=~w, Remainder=~w via CGOB strategy', [Quotient, Remainder]).
final_interpretation(state(q_error, _, _, _, _, _, _, _, _), 'Error: CGOB division failed - invalid divisor').

%!      extract_result_from_history(+History, -Result) is det.
%
%       Extracts the final result from the execution history.
extract_result_from_history(History, [Quotient, Remainder]) :-
    last(History, LastStep),
    (LastStep = step(state(q_accept, _, _, Quotient, Remainder, _, _, _, _), _, _) ->
        true
    ;
        Quotient = error,
        Remainder = error
    ).
