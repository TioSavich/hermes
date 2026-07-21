/** <module> Student Multiplication Strategy: Conversion to Bases and Ones (CBO)
 *
 * This module implements a multiplication strategy based on the physical act
 * of creating groups and then re-grouping (converting) them into a standard
 * base, like 10. It's modeled as a finite state machine.
 *
 * The process is as follows:
 * 1.  Start with `N` groups, each containing `S` items.
 * 2.  Systematically take items from one "source" group and redistribute them
 *     one-by-one into other "target" groups.
 * 3.  The goal of the redistribution is to fill the target groups until they
 *     contain `Base` items (e.g., 10).
 * 4.  This process continues until the source group is empty.
 * 5.  The final total is calculated by summing the items in all the rearranged
 *     groups. This demonstrates the principle of conservation of number, as the
 *     total remains `N * S` despite the redistribution.
 *
 * The state is represented by the term:
 * `state(Name, Groups, SourceIndex, TargetIndex)`
 *
 * The history of execution is captured as a list of steps:
 * `step(Name, Groups, Interpretation)`
 *
 * 
 * 
 */
:- module(smr_mult_cbo,
          [ run_cbo_mult/5
          ]).

:- use_module(library(lists)).
:- use_module(formalization(grounded_arithmetic), [greater_than/2, equal_to/2, smaller_than/2,
                                  integer_to_recollection/2, recollection_to_integer/2,
                                  add_grounded/3, subtract_grounded/3, successor/2,
                                  zero/1, incur_cost/1]).
:- use_module(pml(pml_operators), [s/1, 'comp_nec'/1, 'exp_poss'/1]).

%!      run_cbo_mult(+N:integer, +S:integer, +Base:integer, -FinalTotal:integer, -History:list) is det.
%
%       Executes the 'Conversion to Bases and Ones' multiplication strategy
%       for N * S, using a target Base for re-grouping.
%
%       This predicate initializes and runs a state machine that models the
%       conceptual process of redistribution. It creates `N` groups of `S` items
%       and then shuffles items between them to form groups of size `Base`.
%       The final total demonstrates that the quantity is conserved.
%
%       @param N The number of initial groups.
%       @param S The size of each initial group.
%       @param Base The target size for the re-grouping.
%       @param FinalTotal The resulting product (N * S).
%       @param History A list of `step/3` terms that describe the state
%       machine's execution path and the interpretation of each step.

run_cbo_mult(N, S, Base, FinalTotal, History) :-
    % Convert inputs to recollection structures
    integer_to_recollection(N, N_Rec),
    integer_to_recollection(S, _S_Rec),
    integer_to_recollection(Base, Base_Rec),
    integer_to_recollection(0, Zero_Rec),
    
    % Emit modal signal: entering multiplication via grouping context (expansive possibility)
    s(exp_poss(creating_groups_for_multiplication)),
    
    (greater_than(N_Rec, Zero_Rec) ->
        create_groups_grounded(N, S, Groups),
        predecessor_grounded(N, SourceIdx)
    ;
        Groups = [],
        SourceIdx = -1
    ),
    
    InitialState = state(q_init, Groups, SourceIdx, Zero_Rec),

    run(InitialState, Base_Rec, [], ReversedHistory),
    reverse(ReversedHistory, History),

    (last(History, step(q_accept, FinalGroups, _)),
     calculate_total_grounded(FinalGroups, FinalTotal) -> true ; FinalTotal = 'error').

% Helper to create N groups of S items each using grounded operations
create_groups_grounded(N, S, Groups) :-
    integer_to_recollection(N, N_Rec),
    integer_to_recollection(S, S_Rec),
    create_groups_helper(N_Rec, S_Rec, [], Groups).

create_groups_helper(N_Rec, S_Rec, Acc, Groups) :-
    (zero(N_Rec) ->
        Groups = Acc
    ;
        recollection_to_integer(S_Rec, S),
        grounded_arithmetic:predecessor(N_Rec, N_Pred),
        create_groups_helper(N_Pred, S_Rec, [S|Acc], Groups)
    ).

% Helper to get predecessor in grounded arithmetic
predecessor_grounded(N, Pred) :-
    integer_to_recollection(N, N_Rec),
    integer_to_recollection(1, One_Rec),
    subtract_grounded(N_Rec, One_Rec, Pred_Rec),
    recollection_to_integer(Pred_Rec, Pred).

% run/4 is the main recursive loop of the state machine.
run(state(q_accept, Gs, _, _), _Base_Rec, Acc, FinalHistory) :-
    calculate_total_grounded(Gs, Total),
    format(string(Interpretation), 'Final Tally. Total = ~w.', [Total]),
    HistoryEntry = step(q_accept, Gs, Interpretation),
    FinalHistory = [HistoryEntry | Acc].

run(CurrentState, Base_Rec, Acc, FinalHistory) :-
    transition(CurrentState, Base_Rec, NextState, Interpretation),
    CurrentState = state(Name, Gs, _, _),
    HistoryEntry = step(Name, Gs, Interpretation),
    run(NextState, Base_Rec, [HistoryEntry | Acc], FinalHistory).

% transition/4 defines the logic for moving from one state to the next.

% From q_init, select a source group to begin redistribution.
transition(state(q_init, Gs, SourceIdx, TI), _, state(q_select_source, Gs, SourceIdx, TI), 'Initialized groups.').

% From q_select_source, confirm the source and begin the transfer process.
transition(state(q_select_source, Gs, SourceIdx, TI), _, state(q_init_transfer, Gs, SourceIdx, TI), Interp) :-
    (SourceIdx \== -1 ->
        integer_to_recollection(SourceIdx, RecSourceIdx),
        successor(RecSourceIdx, RecSI1),
        recollection_to_integer(RecSI1, SI1),
        format(string(Interp), 'Selected Group ~w as the source.', [SI1])
    ;
        Interp = 'No groups to process.'
    ),
    s(comp_nec(selecting_source_group_for_redistribution)).

% From q_init_transfer, start the main redistribution loop.
transition(state(q_init_transfer, Gs, SI, _), _, state(q_loop_transfer, Gs, SI, Zero_Rec),
           'Starting redistribution loop.') :-
    integer_to_recollection(0, Zero_Rec),
    s(exp_poss(beginning_redistribution_process)).

% In q_loop_transfer, move one item from the source group to a target group.
transition(state(q_loop_transfer, Gs, SI, TI_Rec), Base_Rec, state(q_loop_transfer, NewGs, SI, NewTI_Rec), Interp) :-
    % Convert TI_Rec to integer for list operations (maintaining compatibility)
    recollection_to_integer(TI_Rec, TI),
    
    % Conditions for transfer: source has items, target is not full.
    nth0(SI, Gs, SourceItems), 
    integer_to_recollection(SourceItems, SourceItems_Rec),
    integer_to_recollection(0, Zero_Rec),
    \+ equal_to(SourceItems_Rec, Zero_Rec), % SourceItems > 0
    
    length(Gs, N), 
    integer_to_recollection(N, N_Rec),
    smaller_than(TI_Rec, N_Rec), % TI < N
    
    (   integer_to_recollection(TI, RecTI_cmp),
        integer_to_recollection(SI, RecSI_cmp),
        \+ equal_to(RecTI_cmp, RecSI_cmp) ->
        nth0(TI, Gs, TargetItems),
        integer_to_recollection(TargetItems, TargetItems_Rec),
        smaller_than(TargetItems_Rec, Base_Rec), % TargetItems < Base
        
        % Perform transfer of one item using grounded arithmetic.
        integer_to_recollection(1, One_Rec),
        subtract_grounded(SourceItems_Rec, One_Rec, NewSourceItems_Rec),
        add_grounded(TargetItems_Rec, One_Rec, NewTargetItems_Rec),
        
        recollection_to_integer(NewSourceItems_Rec, NewSourceItems),
        recollection_to_integer(NewTargetItems_Rec, NewTargetItems),
        
        update_list(Gs, SI, NewSourceItems, Gs_mid),
        update_list(Gs_mid, TI, NewTargetItems, NewGs),
        
        % Check if target is now full, if so, advance target index.
        (equal_to(NewTargetItems_Rec, Base_Rec) -> 
            grounded_arithmetic:successor(TI_Rec, NewTI_Rec)
        ; 
            NewTI_Rec = TI_Rec
        ),
        
        integer_to_recollection(TI, RecTI_disp),
        successor(RecTI_disp, RecTI_Display),
        recollection_to_integer(RecTI_Display, TI_Display),
        integer_to_recollection(SI, RecSI_disp),
        successor(RecSI_disp, RecSI_Display),
        recollection_to_integer(RecSI_Display, SI_Display),
        format(string(Interp), 'Transferred 1 from ~w to ~w.', [SI_Display, TI_Display]),
        s(exp_poss(transferring_item_between_groups))
    ;
        % Skip transferring to the source index itself.
        grounded_arithmetic:successor(TI_Rec, NewTI_Rec), 
        NewGs = Gs, 
        Interp = 'Skipping source index.'
    ).

% Exit the loop when the source is empty or all targets have been considered.
transition(state(q_loop_transfer, Gs, SI, TI_Rec), _, state(q_finalize, Gs, SI, TI_Rec), 'Redistribution complete.') :-
    recollection_to_integer(TI_Rec, TI),
    (   (nth0(SI, Gs, 0))  % Source is empty
    ;   (length(Gs, N),  % All targets considered
         integer_to_recollection(TI, RecTI_exit),
         integer_to_recollection(N, RecN_exit),
         \+ smaller_than(RecTI_exit, RecN_exit))
    ),
    s(comp_nec(redistribution_process_complete)).

% From q_finalize, move to the accept state.
transition(state(q_finalize, Gs, SI, TI), _, state(q_accept, Gs, SI, TI), 'Finalizing.').

% update_list/4 is a helper to non-destructively update a list element at an index.
update_list(List, Index, NewVal, NewList) :-
    nth0(Index, List, _, Rest),
    nth0(Index, NewList, NewVal, Rest).

% calculate_total_grounded/2 is a helper to sum the elements using grounded arithmetic.
calculate_total_grounded([], 0).
calculate_total_grounded([H|T], Total) :-
    calculate_total_grounded(T, RestTotal),
    integer_to_recollection(H, H_Rec),
    integer_to_recollection(RestTotal, RestTotal_Rec),
    add_grounded(H_Rec, RestTotal_Rec, Total_Rec),
    recollection_to_integer(Total_Rec, Total),
    incur_cost(unit_count). % Cognitive cost for each addition
