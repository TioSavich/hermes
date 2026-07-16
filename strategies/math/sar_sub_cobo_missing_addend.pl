/** <module> Student Subtraction Strategy: Counting On By Bases and Ones (Missing Addend)
 *
 * This module implements the 'Counting On by Bases and then Ones' (COBO)
 * strategy for subtraction, framed as a "missing addend" problem. It is
 * modeled as a finite state machine. It solves `M - S` by figuring out
 * what number needs to be added to `S` to reach `M`.
 *
 * The process is as follows:
 * 1. Start at the subtrahend (S). The goal is to reach the minuend (M).
 * 2. Count up from S by adding bases (tens) as many times as possible without
 *    exceeding M. The amount added is tracked as `Distance`.
 * 3. Once adding another base would overshoot M, switch to counting up by ones.
 * 4. Continue counting up by ones until M is reached.
 * 5. The total `Distance` accumulated is the result of the subtraction.
 * 6. The strategy fails if S > M.
 *
 * The state of the automaton is represented by the term:
 * `state(Name, CurrentValue, Distance, Target)`
 *
 * The history of execution is captured as a list of steps:
 * `step(Name, CurrentValue, Distance, Interpretation)`
 *
 * 
 * 
 */
:- module(sar_sub_cobo_missing_addend,
          [ run_cobo_ma/4,
            % FSM Engine Interface
            setup_strategy/4, transition/3, transition/4,
            accept_state/1, final_interpretation/2, extract_result_from_history/2
          ]).

:- use_module(library(lists)).
:- use_module(strategies(fsm_engine), [run_fsm_with_base/5]).
:- use_module(formalization(grounded_arithmetic), [incur_cost/1,
                                     integer_to_recollection/2,
                                     recollection_to_integer/2,
                                     add_grounded/3,
                                     successor/2]).
:- use_module(arche_trace(sequent_engine), [s/1, comp_nec/1, exp_poss/1]).
:- use_module(math(cgi_base), [current_cgi_base/1]).

:- discontiguous transition/4.

%!      run_cobo_ma(+M:integer, +S:integer, -FinalResult:integer, -History:list) is det.
%
%       Executes the 'Counting On by Bases and Ones' (Missing Addend) subtraction
%       strategy for M - S.
%
%       This predicate initializes and runs a state machine that models the
%       COBO "missing addend" strategy. It first checks if the subtraction is
%       possible (M >= S). If so, it finds the difference by counting up from
%       S to M, first by tens and then by ones. The total amount counted up
%       is the result. It traces the entire execution.
%
%       @param M The Minuend, the target number to count up to.
%       @param S The Subtrahend, the number to start counting from.
%       @param FinalResult The resulting difference (M - S). If S > M, this
%       will be the atom `'error'`.
%       @param History A list of `step/4` terms that describe the state
%       machine's execution path and the interpretation of each step.

run_cobo_ma(M, S, FinalResult, History) :-
    incur_cost(strategy_selection),
    setup_strategy(M, S, InitialState, Parameters),
    current_cgi_base(Base),
    run_fsm_with_base(sar_sub_cobo_missing_addend, InitialState, Parameters, Base, History),
    extract_result_from_history(History, FinalResult).

setup_strategy(M, S, InitialState, Parameters) :-
    (S > M ->
        InitialState = state(q_error, 0, 0, 0)
    ;
        InitialState = state(q_init, S, 0, M)
    ),
    Parameters = [M, S],
    s(exp_poss(initiating_cobo_missing_addend_subtraction)),
    incur_cost(inference).

% FSM Engine Interface

transition(q_init, q_add_bases, add_bases) :-
    s(comp_nec(transitioning_to_base_addition)), incur_cost(state_change).

transition(q_add_bases, q_add_bases, count_on_base) :-
    s(exp_poss(continuing_base_addition_iteration)), incur_cost(iteration).

transition(q_add_bases, q_add_ones, switch_to_ones) :-
    s(comp_nec(completing_base_addition_phase)), incur_cost(phase_transition).

transition(q_add_ones, q_add_ones, count_on_one) :-
    s(exp_poss(continuing_ones_addition_iteration)), incur_cost(iteration).

transition(q_add_ones, q_accept, reach_target) :-
    s(comp_nec(finalizing_missing_addend_computation)), incur_cost(completion).

% Complete state transitions
transition(state(q_init, CV, Dist, T), _, state(q_add_bases, CV, Dist, T), 
           'Proceed to add bases.') :-
    s(exp_poss(initiating_base_addition_phase)), incur_cost(initialization).

transition(state(q_add_bases, CV, Dist, T), Base, state(q_add_bases, NewCV, NewDist, T), Interp) :-
    CV + Base =< T,
    s(comp_nec(applying_embodied_base_addition)),
    integer_to_recollection(CV, RecCV),
    integer_to_recollection(Base, RecBase),
    grounded_arithmetic:add_grounded(RecCV, RecBase, RecNewCV),
    recollection_to_integer(RecNewCV, NewCV),
    integer_to_recollection(Dist, RecDist),
    grounded_arithmetic:add_grounded(RecDist, RecBase, RecNewDist),
    recollection_to_integer(RecNewDist, NewDist),
    format(atom(Interp), 'Count on by base (+~w). New Value=~w.', [Base, NewCV]),
    incur_cost(base_addition).

transition(state(q_add_bases, CV, Dist, T), Base, state(q_add_ones, CV, Dist, T),
           'Next base overshoots target. Switching to ones.') :-
    CV + Base > T,
    s(exp_poss(transitioning_from_bases_to_ones)), incur_cost(phase_completion).

transition(state(q_add_ones, CV, Dist, T), _, state(q_add_ones, NewCV, NewDist, T), Interp) :-
    CV < T,
    s(comp_nec(applying_embodied_ones_addition)),
    integer_to_recollection(CV, RecCV),
    grounded_arithmetic:successor(RecCV, RecNewCV),
    recollection_to_integer(RecNewCV, NewCV),
    integer_to_recollection(Dist, RecDist),
    grounded_arithmetic:successor(RecDist, RecNewDist),
    recollection_to_integer(RecNewDist, NewDist),
    format(atom(Interp), 'Count on by one (+1). New Value=~w.', [NewCV]),
    incur_cost(ones_addition).

transition(state(q_add_ones, T, Dist, T), _, state(q_accept, T, Dist, T),
           'Target reached.') :-
    s(exp_poss(completing_cobo_missing_addend_strategy)), incur_cost(strategy_completion).

transition(state(q_error, _, _, _), _, state(q_error, 0, 0, 0),
           'Error: Subtrahend > Minuend.') :-
    s(comp_nec(error_state_persistence)), incur_cost(error_maintenance).

accept_state(state(q_accept, _, _, _)).

final_interpretation(state(q_accept, _, Dist, _), Interpretation) :-
    format(atom(Interpretation), 'Target reached. Result (Distance) = ~w.', [Dist]).
final_interpretation(state(q_error, _, _, _), 'Error: Subtrahend > Minuend.').

extract_result_from_history(History, Result) :-
    last(History, LastStep),
    (LastStep = step(state(q_accept, _, Dist, _), _, _) ->
        Result = Dist
    ; LastStep = step(state(q_error, _, _, _), _, _) ->
        Result = 'error'
    ;
        Result = 'error'
    ).

% transition/4 defines the logic for moving from one state to the next.
