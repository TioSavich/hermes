/** <module> Student Multiplication Strategy: Coordinating Two Counts (C2C)
 *
 * This module implements a foundational multiplication strategy, "Coordinating
 * Two Counts" (C2C), modeled as a finite state machine. This strategy
 * represents a direct modeling approach where a student literally counts every
 * single item across all groups.
 *
 * The cognitive process involves two simultaneous counting acts:
 * 1.  Tracking the number of items counted within the current group.
 * 2.  Tracking which group is currently being counted.
 *
 * This is a direct simulation of `N * S` where the total is found by
 * counting `1` for each item, `S` times for each of the `N` groups.
 *
 * The state is represented by the term:
 * `state(Name, GroupsDone, ItemInGroup, Total, NumGroups, GroupSize)`
 *
 * The history of execution is captured as a list of steps:
 * `step(Name, GroupsDone, ItemInGroup, Total, Interpretation)`
 *
 * 
 * 
 */
:- module(smr_mult_c2c,
          [ run_c2c/4,
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
:- use_module(formalization(grounded_arithmetic), [incur_cost/1,
                                     integer_to_recollection/2,
                                     recollection_to_integer/2,
                                     add_grounded/3,
                                     successor/2]).
:- use_module(arche_trace(sequent_engine), [s/1, comp_nec/1, exp_poss/1]).
:- use_module(math(cgi_base), [current_cgi_base/1]).

%!      run_c2c(+N:integer, +S:integer, -FinalTotal:integer, -History:list) is det.
%
%       Executes the 'Coordinating Two Counts' multiplication strategy for N * S.
%
%       This predicate initializes and runs a state machine that models the
%       C2C strategy. It simulates a student counting every item, one by one,
%       across all `N` groups of size `S`. It traces the entire execution,
%       providing a step-by-step history of the two coordinated counts.
%
%       @param N The number of groups.
%       @param S The size of each group (number of items).
%       @param FinalTotal The resulting product of N * S.
%       @param History A list of `step/5` terms that describe the state
%       machine's execution path and the interpretation of each step.

%!      run_c2c(+N:integer, +S:integer, -FinalTotal:integer, -History:list) is det.
%
%       Executes the 'Coordinating Two Counts' multiplication strategy for N * S
%       using the FSM engine with modal logic integration.
run_c2c(N, S, FinalTotal, History) :-
    % Emit cognitive cost for strategy initiation
    incur_cost(strategy_selection),
    
    % Use the FSM engine to run this strategy
    setup_strategy(N, S, InitialState, Parameters),
    current_cgi_base(Base),
    run_fsm_with_base(smr_mult_c2c, InitialState, Parameters, Base, History),
    extract_result_from_history(History, FinalTotal).

%!      setup_strategy(+N, +S, -InitialState, -Parameters) is det.
%
%       Sets up the initial state for the C2C multiplication strategy.
setup_strategy(N, S, InitialState, Parameters) :-
    % Initialize state: GroupsDone=0, ItemInGroup=0, Total=0, NumGroups=N, GroupSize=S
    InitialState = state(q_init, 0, 0, 0, N, S),
    Parameters = [N, S],
    
    % Emit modal signal for strategy initiation
    s(exp_poss(initiating_coordinating_two_counts_multiplication)),
    incur_cost(inference).

%!      transition(+StateNum, -NextStateNum, -Action) is det.
%
%       State transitions for C2C multiplication FSM.

transition(q_init, q_check_G, initialize_counters) :-
    s(comp_nec(transitioning_to_group_checking)),
    incur_cost(state_change).

transition(q_check_G, q_count_items, start_group_counting) :-
    s(exp_poss(initiating_item_counting_in_group)),
    incur_cost(group_initiation).

transition(q_check_G, q_accept, complete_all_groups) :-
    s(comp_nec(finalizing_multiplication_computation)),
    incur_cost(completion).

transition(q_count_items, q_count_items, count_next_item) :-
    s(exp_poss(continuing_item_enumeration)),
    incur_cost(counting).

transition(q_count_items, q_next_group, finish_current_group) :-
    s(comp_nec(completing_group_counting_phase)),
    incur_cost(group_completion).

transition(q_next_group, q_check_G, advance_to_next_group) :-
    s(exp_poss(progressing_to_subsequent_group)),
    incur_cost(group_transition).

%!      transition(+State, +Base, -NextState, -Interpretation) is det.
%
%       Complete state transitions with full state tracking and modal integration.

% From q_init, proceed to check the group counter.
transition(state(q_init, G, I, T, N, S), _,
           state(q_check_G, G, I, T, N, S), 
           Interpretation) :-
    s(exp_poss(initializing_group_and_item_counters)),
    format(atom(Interpretation), 'Inputs: ~w groups of ~w. Initialize counters.', [N, S]),
    incur_cost(initialization).

% In q_check_G, decide whether to count another group or finish.
transition(state(q_check_G, G, I, T, N, S), _,
           state(q_count_items, G, I, T, N, S), 
           Interpretation) :-
    G < N,
    s(comp_nec(verifying_group_counting_continuation)),
    integer_to_recollection(G, RecG),
    grounded_arithmetic:successor(RecG, RecG1),
    recollection_to_integer(RecG1, G1),
    format(atom(Interpretation), 'G < N. Starting Group ~w.', [G1]),
    incur_cost(group_check).

transition(state(q_check_G, N, _, T, N, S), _,
           state(q_accept, N, 0, T, N, S), 
           'G = N. All groups counted.') :-
    s(exp_poss(completing_all_group_enumeration)),
    incur_cost(completion_check).

% In q_count_items, count one item and increment the total. Loop until the group is full.
transition(state(q_count_items, G, I, T, N, S), _,
           state(q_count_items, G, NewI, NewT, N, S), 
           Interpretation) :-
    I < S,
    s(comp_nec(applying_embodied_counting_increment)),
    integer_to_recollection(I, RecI),
    grounded_arithmetic:successor(RecI, RecNewI),
    recollection_to_integer(RecNewI, NewI),
    integer_to_recollection(T, RecT),
    grounded_arithmetic:successor(RecT, RecNewT),
    recollection_to_integer(RecNewT, NewT),
    integer_to_recollection(G, RecG),
    grounded_arithmetic:successor(RecG, RecG1),
    recollection_to_integer(RecG1, G1),
    format(atom(Interpretation), 'Count: ~w. (Item ~w in Group ~w).', [NewT, NewI, G1]),
    incur_cost(item_counting).

% When the current group is fully counted, move to the next group.
transition(state(q_count_items, G, S, T, N, S), _,
           state(q_next_group, G, S, T, N, S), 
           Interpretation) :-
    s(exp_poss(concluding_current_group_enumeration)),
    integer_to_recollection(G, RecG),
    grounded_arithmetic:successor(RecG, RecG1),
    recollection_to_integer(RecG1, G1),
    format(atom(Interpretation), 'Group ~w finished.', [G1]),
    incur_cost(group_finalization).

% In q_next_group, increment the group counter and reset the item counter, then loop back.
transition(state(q_next_group, G, _, T, N, S), _,
           state(q_check_G, NewG, 0, T, N, S), 
           'Increment G. Reset I.') :-
    s(comp_nec(transitioning_to_subsequent_group_state)),
    integer_to_recollection(G, RecG),
    grounded_arithmetic:successor(RecG, RecNewG),
    recollection_to_integer(RecNewG, NewG),
    incur_cost(group_increment).

%!      accept_state(+State) is semidet.
%
%       Defines the accept states for the FSM.
accept_state(state(q_accept, _, _, _, _, _)).

%!      final_interpretation(+State, -Interpretation) is det.
%
%       Provides final interpretation of the computation.
final_interpretation(state(q_accept, _, _, T, _, _), Interpretation) :-
    format(atom(Interpretation), 'All groups counted. Result = ~w.', [T]).

%!      extract_result_from_history(+History, -Result) is det.
%
%       Extracts the final result from the execution history.
extract_result_from_history(History, Result) :-
    last(History, LastStep),
    (LastStep = step(state(q_accept, _, _, T, _, _), _, _) ->
        Result = T
    ;
        Result = 'error'
    ).
