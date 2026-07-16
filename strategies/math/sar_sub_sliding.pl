/** <module> Student Subtraction Strategy: Sliding (Constant Difference)
 *
 * This module implements the "sliding" or "constant difference" strategy for
 * subtraction (M - S), modeled as a finite state machine.
 *
 * The core idea of this strategy is that the difference between two numbers
 * remains the same if both numbers are shifted by the same amount. The
 * strategy simplifies the problem `M - S` by transforming it into
 * `(M + K) - (S + K)`, where `K` is chosen to make `S + K` a "friendly"
 * number (a multiple of 10).
 *
 * The process is as follows:
 * 1. Determine the amount `K` needed to "slide" the subtrahend (S) up to the
 *    next multiple of 10.
 * 2. Add `K` to both the minuend (M) and the subtrahend (S) to get the new
 *    numbers, `M_adj` and `S_adj`.
 * 3. Perform the simplified subtraction `M_adj - S_adj`.
 * 4. The strategy fails if S > M.
 *
 * The state is represented by the term:
 * `state(Name, K, M_adj, S_adj, TargetBase, TempCounter, M, S)`
 *
 * The history of execution is captured as a list of steps:
 * `step(Name, K, M_adj, S_adj, Interpretation)`
 *
 * 
 * 
 */
:- module(sar_sub_sliding,
          [ run_sliding/4,
            % FSM Engine Interface
            setup_strategy/4, transition/3, transition/4,
            accept_state/1, final_interpretation/2, extract_result_from_history/2
          ]).

:- use_module(library(lists)).
:- use_module(strategies(fsm_engine), [run_fsm_with_base/5]).
:- use_module(formalization(grounded_arithmetic), [integer_to_recollection/2, recollection_to_integer/2,
                                  successor/2, predecessor/2,
                                  add_grounded/3, subtract_grounded/3, multiply_grounded/3,
                                  greater_than/2, smaller_than/2, equal_to/2,
                                  incur_cost/1]).
:- use_module(formalization(grounded_utils), [base_decompose_grounded/4, base_recompose_grounded/4,
                             is_zero_grounded/1, is_positive_grounded/1]).
:- use_module(arche_trace(sequent_engine), [s/1, comp_nec/1, exp_poss/1]).
:- use_module(math(cgi_base), [current_cgi_base/1]).

:- discontiguous transition/4.

%!      run_sliding(+M:integer, +S:integer, -FinalResult:integer, -History:list) is det.
%
%       Executes the 'Sliding' (Constant Difference) subtraction strategy for M - S.
%
%       This predicate initializes and runs a state machine that models the
%       sliding strategy. It first checks if the subtraction is possible (M >= S).
%       If so, it calculates the amount `K` to slide both numbers, performs the
%       adjustment, and then executes the final, simpler subtraction. It
%       traces the entire execution.
%
%       @param M The Minuend.
%       @param S The Subtrahend.
%       @param FinalResult The resulting difference (M - S). If S > M, this
%       will be the atom `'error'`.
%       @param History A list of `step/5` terms that describe the state
%       machine's execution path and the interpretation of each step.

run_sliding(M, S, FinalResult, History) :-
    incur_cost(strategy_selection),
    setup_strategy(M, S, InitialState, Parameters),
    current_cgi_base(Base),
    run_fsm_with_base(sar_sub_sliding, InitialState, Parameters, Base, History),
    extract_result_from_history(History, FinalResult).

setup_strategy(M, S, InitialState, Parameters) :-
    current_cgi_base(Base),
    integer_to_recollection(S, RecS),
    integer_to_recollection(M, RecM),
    integer_to_recollection(Base, RecBase),
    (greater_than(RecS, RecM) ->
        InitialState = state(q_error, 0, 0, 0, 0, 0, 0, 0)
    ;
        (   \+ is_zero_grounded(RecS),
            base_decompose_grounded(RecS, RecBase, RecBases, RecRem),
            \+ is_zero_grounded(RecRem)
        ->  successor(RecBases, RecBasesPlus1),
            multiply_grounded(RecBasesPlus1, RecBase, RecTB),
            recollection_to_integer(RecTB, TB)
        ;   TB = S
        ),
        InitialState = state(q_init_K, 0, 0, 0, TB, S, M, S)
    ),
    Parameters = [M, S],
    s(exp_poss(initiating_sliding_subtraction_strategy)),
    incur_cost(inference).

% FSM Engine transitions

transition(q_init_K, q_loop_K, initialize_k_calculation) :-
    s(comp_nec(transitioning_to_k_computation)), incur_cost(state_change).

transition(q_loop_K, q_loop_K, count_up_to_base) :-
    s(exp_poss(continuing_k_calculation_iteration)), incur_cost(iteration).

transition(q_loop_K, q_adjust, apply_sliding_adjustment) :-
    s(comp_nec(completing_k_calculation_phase)), incur_cost(phase_transition).

transition(q_adjust, q_accept, perform_simplified_subtraction) :-
    s(exp_poss(finalizing_sliding_computation)), incur_cost(completion).

% Complete state transitions
transition(state(q_init_K, _, _, _, TB, _, M, S), _, state(q_loop_K, 0, 0, 0, TB, S, M, S), Interp) :-
    s(exp_poss(initializing_k_calculation_phase)),
    format(atom(Interp), 'Initializing K calculation: Counting from ~w to ~w.', [S, TB]),
    incur_cost(initialization).

transition(state(q_loop_K, K, M_adj, S_adj, TB, TC, M, S), _, state(q_loop_K, NewK, M_adj, S_adj, TB, NewTC, M, S), Interp) :-
    integer_to_recollection(TC, RecTC),
    integer_to_recollection(TB, RecTB),
    smaller_than(RecTC, RecTB),
    s(comp_nec(applying_embodied_counting_increment)),
    integer_to_recollection(K, RecK),
    successor(RecTC, RecNewTC),
    recollection_to_integer(RecNewTC, NewTC),
    successor(RecK, RecNewK),
    recollection_to_integer(RecNewK, NewK),
    format(atom(Interp), 'Counting Up: ~w, K=~w', [NewTC, NewK]),
    incur_cost(k_calculation).

transition(state(q_loop_K, K, _, _, TB, TC, M, S), _, state(q_adjust, K, 0, 0, TB, TC, M, S), Interp) :-
    integer_to_recollection(TC, RecTC),
    integer_to_recollection(TB, RecTB),
    \+ smaller_than(RecTC, RecTB),
    s(exp_poss(transitioning_to_adjustment_phase)),
    format(atom(Interp), 'K needed to reach base is ~w.', [K]),
    incur_cost(phase_completion).

transition(state(q_adjust, K, _, _, _, _, M, S), _, state(q_accept, K, M_adj, S_adj, 0, 0, 0, 0), Interp) :-
    s(comp_nec(applying_sliding_transformation)),
    integer_to_recollection(M, RecM),
    integer_to_recollection(S, RecS),
    integer_to_recollection(K, RecK),
    add_grounded(RecM, RecK, RecM_adj),
    recollection_to_integer(RecM_adj, M_adj),
    add_grounded(RecS, RecK, RecS_adj),
    recollection_to_integer(RecS_adj, S_adj),
    format(atom(Interp), 'Slide both numbers: M+K=~w, S+K=~w.', [M_adj, S_adj]),
    incur_cost(adjustment).

transition(state(q_error, _, _, _, _, _, _, _), _, state(q_error, 0, 0, 0, 0, 0, 0, 0),
           'Error: Subtrahend > Minuend.') :-
    s(comp_nec(error_state_persistence)), incur_cost(error_maintenance).

accept_state(state(q_accept, _, _, _, _, _, _, _)).

final_interpretation(state(q_accept, _, M_adj, S_adj, _, _, _, _), Interpretation) :-
    integer_to_recollection(M_adj, RecM_adj),
    integer_to_recollection(S_adj, RecS_adj),
    subtract_grounded(RecM_adj, RecS_adj, RecResult),
    recollection_to_integer(RecResult, Result),
    format(atom(Interpretation), 'Perform Subtraction: ~w - ~w = ~w.', [M_adj, S_adj, Result]).
final_interpretation(state(q_error, _, _, _, _, _, _, _), 'Error: Subtrahend > Minuend.').

extract_result_from_history(History, Result) :-
    last(History, LastStep),
    (LastStep = step(state(q_accept, _, M_adj, S_adj, _, _, _, _), _, _) ->
        integer_to_recollection(M_adj, RecM_adj),
        integer_to_recollection(S_adj, RecS_adj),
        subtract_grounded(RecM_adj, RecS_adj, RecResult),
        recollection_to_integer(RecResult, Result)
    ; LastStep = step(state(q_error, _, _, _, _, _, _, _), _, _) ->
        Result = 'error'
    ;
        Result = 'error'
    ).

% transition/4 defines the logic for moving from one state to the next.
