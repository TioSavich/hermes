/** <module> Student Multiplication Strategy: Distributive Reasoning (DR)
 *
 * This module implements a multiplication strategy based on the distributive
 * property of multiplication over addition, modeled as a finite state machine.
 * It solves `N * S` by breaking `S` into two easier parts (`S1` and `S2`).
 *
 * The process is as follows:
 * 1.  Split the group size `S` into two smaller, more manageable parts,
 *     `S1` and `S2`, using a simple heuristic. For example, 7 might be
 *     split into 2 + 5.
 * 2.  Calculate the first partial product, `P1 = N * S1`, using repeated addition.
 * 3.  Calculate the second partial product, `P2 = N * S2`, also using repeated addition.
 * 4.  Sum the two partial products to get the final answer: `Total = P1 + P2`.
 *     This demonstrates the distributive property: `N * (S1 + S2) = (N * S1) + (N * S2)`.
 *
 * The state is represented by the term:
 * `state(Name, S1, S2, P1, P2, Total, Counter, N_Groups, S_Size)`
 *
 * The history of execution is captured as a list of steps:
 * `step(Name, S1, S2, P1, P2, Total, Interpretation)`
 *
 * 
 * 
 */
:- module(smr_mult_dr,
          [ run_dr/4,
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
                                     recollection_to_integer/2, successor/2,
                                     predecessor/2, add_grounded/3,
                                     subtract_grounded/3, greater_than/2,
                                     smaller_than/2]).
:- use_module(formalization(grounded_utils), [base_decompose_grounded/4,
                                is_zero_grounded/1, is_positive_grounded/1]).
:- use_module(arche_trace(sequent_engine), [s/1, comp_nec/1, exp_poss/1]).
:- use_module(math(cgi_base), [current_cgi_base/1]).

%!      run_dr(+N:integer, +S:integer, -FinalTotal:integer, -History:list) is det.
%
%       Executes the 'Distributive Reasoning' multiplication strategy for N * S.
%
%       This predicate initializes and runs a state machine that models the DR
%       strategy. It heuristically splits the multiplier `S` into two parts,
%       calculates the partial product for each part via repeated addition, and
%       then sums the partial products. It traces the entire execution.
%
%       @param N The number of groups.
%       @param S The size of each group (this is the number that will be split).
%       @param FinalTotal The resulting product of N * S.
%       @param History A list of `step/7` terms that describe the state
%       machine's execution path and the interpretation of each step.

run_dr(N, S, FinalTotal, History) :-
    % Use the FSM engine to run this strategy
    setup_strategy(N, S, InitialState, Parameters),
    current_cgi_base(Base),
    run_fsm_with_base(smr_mult_dr, InitialState, Parameters, Base, History),
    extract_result_from_history(History, FinalTotal).

%!      setup_strategy(+N, +S, -InitialState, -Parameters) is det.
%
%       Sets up the initial state for the distributive reasoning strategy.
setup_strategy(N, S, InitialState, Parameters) :-
    InitialState = state(q_init, 0, 0, 0, 0, 0, 0, N, S),
    Parameters = [N, S],
    
    % Emit modal signal for strategy initiation
    s(exp_poss(initiating_distributive_reasoning_strategy)),
    incur_cost(inference).

%!      transition(+StateNum, -NextStateNum, -Action) is det.
%
%       State transitions for distributive reasoning multiplication FSM.

transition(q_init, q_split, split_multiplicand) :-
    s(comp_nec(transitioning_to_split_phase)),
    incur_cost(state_change).

transition(q_split, q_init_P1, prepare_first_partial) :-
    s(exp_poss(preparing_first_partial_product)),
    incur_cost(preparation).

transition(q_init_P1, q_loop_P1, begin_first_calculation) :-
    s(comp_nec(beginning_first_repeated_addition)),
    incur_cost(initialization).

transition(q_loop_P1, q_init_P2, prepare_second_partial) :-
    s(exp_poss(transitioning_to_second_partial)),
    incur_cost(transition).

transition(q_loop_P1, q_sum, skip_to_sum) :-
    s(exp_poss(skipping_second_partial_when_unnecessary)),
    incur_cost(optimization).

transition(q_init_P2, q_loop_P2, begin_second_calculation) :-
    s(comp_nec(beginning_second_repeated_addition)),
    incur_cost(initialization).

transition(q_loop_P2, q_sum, proceed_to_sum) :-
    s(exp_poss(completing_second_partial_calculation)),
    incur_cost(completion).

transition(q_sum, q_accept, finalize_result) :-
    s(exp_poss(finalizing_distributive_multiplication)),
    incur_cost(finalization).

%!      transition(+State, +Base, -NextState, -Interpretation) is det.
%
%       Complete state transitions with full state tracking.

% From q_init, proceed to split the group size S.
transition(state(q_init, _, _, _, _, _, _, N, S), _,
           state(q_split, 0, 0, 0, 0, 0, 0, N, S), 
           Interpretation) :-
    s(exp_poss(initializing_distributive_reasoning)),
    format(atom(Interpretation), 'Inputs: ~w x ~w.', [N, S]),
    incur_cost(initialization).

% In q_split, split S into two parts, S1 and S2, using a heuristic.
transition(state(q_split, _, _, P1, P2, T, C, N, S), Base,
           state(q_init_P1, S1, S2, P1, P2, T, C, N, S),
           Interpretation) :-
    s(exp_poss(applying_distributive_splitting_heuristic)),
    heuristic_split(S, Base, S1, S2),
    integer_to_recollection(S2, RecS2),
    (   is_positive_grounded(RecS2)
    ->  format(atom(Interpretation), 'Split S (~w) into ~w + ~w.', [S, S1, S2]),
        incur_cost(complex_splitting)
    ;
        format(atom(Interpretation), 'S (~w) is easy. No split needed.', [S]),
        incur_cost(simple_case)
    ).

% In q_init_P1, prepare to calculate the first partial product (N * S1).
transition(state(q_init_P1, S1, S2, _, P2, T, _, N, S), _,
           state(q_loop_P1, S1, S2, 0, P2, T, N, N, S), 
           Interpretation) :-
    s(comp_nec(preparing_first_partial_product_calculation)),
    format(atom(Interpretation), 'Initializing calculation of P1 (~w x ~w).', [N, S1]),
    incur_cost(partial_initialization).

% In q_loop_P1, calculate P1 using repeated addition.
transition(state(q_loop_P1, S1, S2, P1, P2, T, C, N, S), _,
           state(q_loop_P1, S1, S2, NewP1, P2, T, NewC, N, S),
           Interpretation) :-
    integer_to_recollection(C, RecC),
    is_positive_grounded(RecC),
    s(comp_nec(continuing_first_repeated_addition)),
    integer_to_recollection(P1, RecP1),
    integer_to_recollection(S1, RecS1),
    add_grounded(RecP1, RecS1, RecNewP1),
    recollection_to_integer(RecNewP1, NewP1),
    predecessor(RecC, RecNewC),
    recollection_to_integer(RecNewC, NewC),
    format(atom(Interpretation), 'Iterate P1: Added ~w. P1 = ~w.', [S1, NewP1]),
    incur_cost(addition_step).

% After P1 is calculated, decide whether to calculate P2 or just sum.
transition(state(q_loop_P1, S1, 0, P1, _, _, 0, N, S), _,
           state(q_sum, S1, 0, P1, 0, 0, 0, N, S), 
           Interpretation) :-
    s(exp_poss(completing_first_partial_without_second)),
    format(atom(Interpretation), 'P1 complete. P1 = ~w.', [P1]),
    incur_cost(completion).

transition(state(q_loop_P1, S1, S2, P1, _, _, 0, N, S), _,
           state(q_init_P2, S1, S2, P1, 0, 0, 0, N, S),
           Interpretation) :-
    integer_to_recollection(S2, RecS2b),
    is_positive_grounded(RecS2b),
    s(exp_poss(transitioning_to_second_partial_calculation)),
    format(atom(Interpretation), 'P1 complete. P1 = ~w.', [P1]),
    incur_cost(transition).

% In q_init_P2, prepare to calculate the second partial product (N * S2).
transition(state(q_init_P2, S1, S2, P1, _, T, _, N, S), _,
           state(q_loop_P2, S1, S2, P1, 0, T, N, N, S), 
           Interpretation) :-
    s(comp_nec(preparing_second_partial_product_calculation)),
    format(atom(Interpretation), 'Initializing calculation of P2 (~w x ~w).', [N, S2]),
    incur_cost(partial_initialization).

% In q_loop_P2, calculate P2 using repeated addition.
transition(state(q_loop_P2, S1, S2, P1, P2, T, C, N, S), _,
           state(q_loop_P2, S1, S2, P1, NewP2, T, NewC, N, S),
           Interpretation) :-
    integer_to_recollection(C, RecC2),
    is_positive_grounded(RecC2),
    s(comp_nec(continuing_second_repeated_addition)),
    integer_to_recollection(P2, RecP2),
    integer_to_recollection(S2, RecS2c),
    add_grounded(RecP2, RecS2c, RecNewP2),
    recollection_to_integer(RecNewP2, NewP2),
    predecessor(RecC2, RecNewC2),
    recollection_to_integer(RecNewC2, NewC),
    format(atom(Interpretation), 'Iterate P2: Added ~w. P2 = ~w.', [S2, NewP2]),
    incur_cost(addition_step).

transition(state(q_loop_P2, S1, S2, P1, P2, _, 0, N, S), _,
           state(q_sum, S1, S2, P1, P2, 0, 0, N, S), 
           Interpretation) :-
    s(exp_poss(completing_second_partial_calculation)),
    format(atom(Interpretation), 'P2 complete. P2 = ~w.', [P2]),
    incur_cost(completion).

% In q_sum, add the partial products to get the final total.
transition(state(q_sum, _, _, P1, P2, _, _, N, S), _,
           state(q_accept, 0, 0, P1, P2, Total, 0, N, S),
           'Summing partials.') :-
    s(exp_poss(executing_final_distributive_sum)),
    integer_to_recollection(P1, RecP1f),
    integer_to_recollection(P2, RecP2f),
    add_grounded(RecP1f, RecP2f, RecTotal),
    recollection_to_integer(RecTotal, Total),
    incur_cost(final_addition).

%!      accept_state(+State) is semidet.
%
%       Defines accepting states for the FSM.
accept_state(state(q_accept, _, _, _, _, _, _, _, _)).

%!      final_interpretation(+State, -Interpretation) is det.
%
%       Provides final interpretation of the computation.
final_interpretation(state(q_accept, _, _, P1, P2, Total, _, _, _), Interpretation) :-
    format(atom(Interpretation), 'Successfully computed product: ~w via distributive reasoning (~w + ~w)', [Total, P1, P2]).

%!      extract_result_from_history(+History, -Result) is det.
%
%       Extracts the final result from the execution history.
%!      extract_result_from_history(+History, -Result) is det.
%
%       Extracts the final result from the execution history.
extract_result_from_history(History, Result) :-
    last(History, LastStep),
    (LastStep = step(state(q_accept, _, _, _, _, Result, _, _, _), _, _) ->
        true
    ;
        Result = 'error'
    ).

% heuristic_split/4 is a helper to split a number S into two parts, S1 and S2.
% It uses a simple set of rules to find an "easy" part to split off.
heuristic_split(Value, Base, S1, S2) :-
    integer_to_recollection(Value, RecValue),
    integer_to_recollection(Base, RecBase),
    (   greater_than(RecValue, RecBase)
    ->  S1 = Base,
        subtract_grounded(RecValue, RecBase, RecS2),
        recollection_to_integer(RecS2, S2)
    ;   % Check if Base is even: Base mod 2 =:= 0
        integer_to_recollection(2, RecTwo),
        base_decompose_grounded(RecBase, RecTwo, RecHalf, RecBaseRem),
        is_zero_grounded(RecBaseRem),
        recollection_to_integer(RecHalf, HalfBase),
        integer_to_recollection(HalfBase, RecHalfBase),
        greater_than(RecValue, RecHalfBase)
    ->  S1 = HalfBase,
        subtract_grounded(RecValue, RecHalfBase, RecS2b),
        recollection_to_integer(RecS2b, S2)
    ;   integer_to_recollection(2, RecTwo2),
        greater_than(RecValue, RecTwo2)
    ->  S1 = 2,
        subtract_grounded(RecValue, RecTwo2, RecS2c),
        recollection_to_integer(RecS2c, S2)
    ;   integer_to_recollection(1, RecOne),
        greater_than(RecValue, RecOne)
    ->  S1 = 1,
        predecessor(RecValue, RecS2d),
        recollection_to_integer(RecS2d, S2)
    ;   S1 = Value, S2 = 0
    ).
