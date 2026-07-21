/** <module> Student Multiplication Strategy: Commutative Reasoning (Repeated Addition)
 *
 * This module implements a multiplication strategy based on repeated addition,
 * modeled as a finite state machine. The name "Commutative Reasoning" implies
 * that a student understands that `A * B` is equivalent to `B * A` and can
 * choose the more efficient path. However, this model directly implements
 * `A * B` as adding `B` to itself `A` times.
 *
 * The process is as follows:
 * 1.  Start with a total of 0.
 * 2.  Repeatedly add the number of items (`B`) to the total.
 * 3.  Use a counter, initialized to the number of groups (`A`), to track
 *     how many times to perform the addition.
 * 4.  The process stops when the counter reaches zero. The accumulated total
 *     is the final product.
 *
 * The state is represented by the term:
 * `state(Name, Groups, Items, Total, Counter)`
 *
 * The history of execution is captured as a list of steps:
 * `step(Name, Groups, Items, Total, Interpretation)`
 *
 * 
 * 
 */
:- module(smr_mult_commutative_reasoning,
          [ run_commutative_mult/4,
            % FSM Engine Interface
            setup_strategy/4, transition/3, transition/4,
            accept_state/1, final_interpretation/2, extract_result_from_history/2
          ]).

:- use_module(library(lists)).
:- use_module(strategies(fsm_engine), [run_fsm_with_base/5]).
:- use_module(formalization(grounded_arithmetic), [incur_cost/1, integer_to_recollection/2,
                                    recollection_to_integer/2, add_grounded/3,
                                    predecessor/2]).
:- use_module(formalization(grounded_utils), [is_positive_grounded/1, is_zero_grounded/1]).
:- use_module(pml(pml_operators), [s/1, 'comp_nec'/1, 'exp_poss'/1]).
:- use_module(math(cgi_base), [current_cgi_base/1]).

:- discontiguous transition/3.

%!      run_commutative_mult(+A:integer, +B:integer, -FinalTotal:integer, -History:list) is det.
%
%       Executes the 'Commutative Reasoning' (Repeated Addition) multiplication
%       strategy for A * B.
%
%       This predicate initializes and runs a state machine that models the
%       process of calculating `A * B` by adding `B` to an accumulator `A` times.
%       It traces the entire execution, providing a step-by-step history of
%       the repeated addition.
%
%       @param A The number of groups (effectively, the number of additions).
%       @param B The number of items in each group (the number being added).
%       @param FinalTotal The resulting product of A * B.
%       @param History A list of `step/5` terms that describe the state
%       machine's execution path and the interpretation of each step.

run_commutative_mult(A, B, FinalTotal, History) :-
    incur_cost(strategy_selection),
    setup_strategy(A, B, InitialState, Parameters),
    current_cgi_base(Base),
    run_fsm_with_base(smr_mult_commutative_reasoning, InitialState, Parameters, Base, History),
    extract_result_from_history(History, FinalTotal).

setup_strategy(A, B, InitialState, Parameters) :-
    % Initialize: Groups=A, Items=B, Total=0, Counter=A
    InitialState = state(q_init_calc, A, B, 0, A),
    Parameters = [A, B],
    s(exp_poss(initiating_commutative_reasoning_multiplication)),
    incur_cost(inference).

% run/3 is the main recursive loop of the state machine.
% FSM Engine transitions

transition(q_init_calc, q_loop_calc, initialize_calculation) :-
    s(comp_nec(transitioning_to_iterative_calculation)), incur_cost(state_change).

transition(q_loop_calc, q_loop_calc, add_items_iteration) :-
    s(exp_poss(continuing_repeated_addition_iteration)), incur_cost(iteration).

transition(q_loop_calc, q_accept, complete_multiplication) :-
    s(comp_nec(finalizing_commutative_multiplication)), incur_cost(completion).

% Complete state transitions
transition(state(q_init_calc, Gs, Items, _, _), _, state(q_loop_calc, Gs, Items, 0, Gs),
           'Initializing iterative calculation.') :-
    s(exp_poss(initializing_repeated_addition_phase)), incur_cost(initialization).

transition(state(q_loop_calc, Gs, Items, Total, Counter), _, state(q_loop_calc, Gs, Items, NewTotal, NewCounter), Interp) :-
    integer_to_recollection(Counter, RecCounter),
    is_positive_grounded(RecCounter),
    s(comp_nec(applying_embodied_repeated_addition)),
    integer_to_recollection(Total, RecTotal),
    integer_to_recollection(Items, RecItems),
    add_grounded(RecTotal, RecItems, RecNewTotal),
    recollection_to_integer(RecNewTotal, NewTotal),
    predecessor(RecCounter, RecNewCounter),
    recollection_to_integer(RecNewCounter, NewCounter),
    format(atom(Interp), 'Iterate: Added ~w. Total = ~w.', [Items, NewTotal]),
    incur_cost(addition_iteration).

transition(state(q_loop_calc, Gs, Items, Total, 0), _, state(q_accept, Gs, Items, Total, 0),
           'Counter reached zero. Calculation complete.') :-
    s(exp_poss(completing_repeated_addition_strategy)), incur_cost(strategy_completion).

accept_state(state(q_accept, _, _, _, _)).

final_interpretation(state(q_accept, _, _, Total, _), Interpretation) :-
    format(atom(Interpretation), 'Calculation complete. Result = ~w.', [Total]).

extract_result_from_history(History, Result) :-
    last(History, LastStep),
    (LastStep = step(state(q_accept, _, _, Total, _), _, _) ->
        Result = Total
    ;
        Result = 'error'
    ).

% transition/3 defines the logic for moving from one state to the next.

% From q_init_calc, start the iterative calculation loop.
transition(state(q_init_calc, Gs, Items, _, _), state(q_loop_calc, Gs, Items, 0, Gs),
           'Initializing iterative calculation.').

% In q_loop_calc, add the number of items to the total and decrement the counter.
transition(state(q_loop_calc, Gs, Items, Total, Counter), state(q_loop_calc, Gs, Items, NewTotal, NewCounter), Interp) :-
    integer_to_recollection(Counter, RecCounter),
    is_positive_grounded(RecCounter),
    integer_to_recollection(Total, RecTotal),
    integer_to_recollection(Items, RecItems),
    add_grounded(RecTotal, RecItems, RecNewTotal),
    recollection_to_integer(RecNewTotal, NewTotal),
    predecessor(RecCounter, RecNewCounter),
    recollection_to_integer(RecNewCounter, NewCounter),
    format(string(Interp), 'Iterate: Added ~w. Total = ~w.', [Items, NewTotal]).
% When the counter reaches zero, the calculation is complete.
transition(state(q_loop_calc, _, _, Total, 0), state(q_accept, 0, 0, Total, 0),
           'Calculation complete.').
