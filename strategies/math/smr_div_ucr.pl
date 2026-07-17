/** <module> Student Division Strategy: Using Commutative Reasoning (Repeated Addition)
 *
 * This module implements a division strategy based on the concept of
 * commutative reasoning, modeled as a finite state machine using the FSM engine.
 * It solves a partitive division problem (E items into G groups) by reframing it as a
 * missing factor multiplication problem: `? * G = E`.
 *
 * @author Assistant
 * @license MIT
 */

:- module(smr_div_ucr,
          [ run_ucr/4,
            % FSM Engine Interface
            transition/4,
            accept_state/1, 
            final_interpretation/2, 
            extract_result_from_history/2
          ]).

:- use_module(library(lists)).
:- use_module(strategies(fsm_engine), [run_fsm_with_base/5]).
:- use_module(formalization(grounded_arithmetic), [incur_cost/1, integer_to_recollection/2,
                                    recollection_to_integer/2, add_grounded/3,
                                    successor/2, smaller_than/2, greater_than/2]).
:- use_module(pml(pml_operators), [s/1, 'comp_nec'/1, 'exp_poss'/1]).

%!      run_ucr(+E:integer, +G:integer, -FinalQuotient:integer, -History:list) is det.
%
%       Executes the 'Using Commutative Reasoning' division strategy for E / G.
%
%       This predicate initializes and runs a state machine that models the
%       process of solving a division problem by finding the missing factor
%       through repeated addition. It traces the entire execution, providing
%       a step-by-step history of how the quotient is built up.
%
%       @param E The Dividend (Total number of items).
%       @param G The Divisor (Number of groups).
%       @param FinalQuotient The result of the division (items per group).
%       @param History A list of `step/4` terms that describe the state
%       machine's execution path and the interpretation of each step.

run_ucr(E, G, FinalQuotient, History) :-
    InitialState = state(q_start, 0, 0, E, G),
    Parameters = [E, G],
    ModalCosts = [
        s(initiating_commutative_reasoning_division),
        s(comp_nec(systematic_repeated_addition_for_division)),
        s(exp_poss(finding_missing_factor_through_iteration))
    ],
    incur_cost(ModalCosts),
    
    run_fsm_with_base(smr_div_ucr, InitialState, Parameters, _, History),
    extract_result_from_history(History, FinalQuotient).

% transition/4 defines the FSM engine transitions with modal logic integration.

% From q_start, identify the problem parameters.
transition(state(q_start, T, Q, E, G), [E, G], state(q_initialize, T, Q, E, G), Interp) :-
    s(identifying_division_problem_parameters),
    Interp = 'Identify total items and number of groups.',
    incur_cost(state_change).

% From q_initialize, begin the iterative process.
transition(state(q_initialize, T, Q, E, G), [E, G], state(q_iterate, T, Q, E, G), Interp) :-
    s(comp_nec(initializing_systematic_distribution_process)),
    Interp = 'Initialize distribution total and count per group.',
    incur_cost(initialization).

% In q_iterate, perform one round of distribution (repeated addition).
transition(state(q_iterate, T, Q, E, G), [E, G], state(q_check, NewT, NewQ, E, G), Interp) :-
    integer_to_recollection(T, RecT),
    integer_to_recollection(G, RecG),
    add_grounded(RecT, RecG, RecNewT),
    recollection_to_integer(RecNewT, NewT),
    integer_to_recollection(Q, RecQ),
    successor(RecQ, RecNewQ),
    recollection_to_integer(RecNewQ, NewQ),
    s(comp_nec(executing_repeated_addition_step)),
    format(string(Interp), 'Distribute round ~w. Total distributed: ~w.', [NewQ, NewT]),
    incur_cost(iteration).

% In q_check, compare the accumulated total to the target total.
transition(state(q_check, T, Q, E, G), [E, G], state(q_iterate, T, Q, E, G), Interp) :-
    integer_to_recollection(T, RecT),
    integer_to_recollection(E, RecE),
    smaller_than(RecT, RecE),
    s(comp_nec(checking_progress_against_target)),
    format(string(Interp), 'Check: T (~w) < E (~w); continue distributing.', [T, E]),
    incur_cost(comparison).
    
transition(state(q_check, E, Q, E, G), [E, G], state(q_accept, E, Q, E, G), Interp) :-
    s(exp_poss(target_total_reached_successfully)),
    format(string(Interp), 'Check: T (~w) == E (~w); total reached.', [E, E]),
    incur_cost(completion).
    
transition(state(q_check, T, _, E, G), [E, G], state(q_error, T, 0, E, G), Interp) :-
    integer_to_recollection(T, RecT),
    integer_to_recollection(E, RecE),
    greater_than(RecT, RecE),
    format(string(Interp), 'Error: Accumulated total (~w) exceeded E (~w).', [T, E]).

% Accept state predicate for FSM engine
accept_state(state(q_accept, _, _, _, _)).

% Final interpretation predicate
final_interpretation(state(q_accept, _, Q, E, G), Interpretation) :-
    format(string(Interpretation), 'Division complete. ~w / ~w = ~w through repeated addition.', [E, G, Q]).

% Extract result from FSM engine history
extract_result_from_history(History, FinalQuotient) :-
    last(History, step(state(q_accept, _, Q, _, _), [], _)),
    FinalQuotient = Q.
