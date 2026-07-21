/** <module> Student Subtraction Strategy: Decomposition (Standard Algorithm)
 *
 * This module implements the standard "decomposition" or "borrowing"
 * algorithm for subtraction, modeled as a finite state machine.
 *
 * The process is as follows:
 * 1. Decompose both the minuend (M) and subtrahend (S) into tens and ones.
 * 2. Subtract the tens components.
 * 3. Check if the ones component of M is sufficient to subtract the ones
 *    component of S.
 * 4. If not, "borrow" or "decompose" a ten from M's tens component, adding
 *    it to M's ones component. This is the key step of the algorithm.
 * 5. Subtract the ones components.
 * 6. Recombine the resulting tens and ones to get the final answer.
 * 7. The strategy fails if S > M.
 *
 * The state is represented by the term:
 * `state(StateName, Result_Tens, Result_Ones, Subtrahend_Tens, Subtrahend_Ones)`
 *
 * The history of execution is captured as a list of steps:
 * `step(StateName, Result_Tens, Result_Ones, Interpretation)`
 *
 * 
 * 
 */
:- module(sar_sub_decomposition,
          [ run_decomposition/4
          ]).

:- use_module(library(lists)).
:- use_module(formalization(grounded_arithmetic), [greater_than/2, integer_to_recollection/2,
                                  recollection_to_integer/2, subtract_grounded/3,
                                  add_grounded/3, multiply_grounded/3]).
:- use_module(formalization(grounded_utils), [base_decompose_grounded/4, base_recompose_grounded/4]).
:- use_module(pml(pml_operators), [s/1, 'comp_nec'/1, 'exp_poss'/1]).
:- use_module(math(cgi_base), [current_cgi_base/1]).

%!      run_decomposition(+M:integer, +S:integer, -FinalResult:integer, -History:list) is det.
%
%       Executes the 'Decomposition' (borrowing) subtraction strategy for M - S.
%
%       This predicate initializes and runs a state machine that models the
%       standard schoolbook subtraction algorithm. It first checks if the
%       subtraction is possible (M >= S). If so, it decomposes both numbers
%       and performs the subtraction column by column, handling borrowing
%       when necessary. It traces the entire execution.
%
%       @param M The Minuend, the number to subtract from.
%       @param S The Subtrahend, the number to subtract.
%       @param FinalResult The resulting difference (M - S). If S > M, this
%       will be the atom `'error'`.
%       @param History A list of `step/4` terms that describe the state
%       machine's execution path and the interpretation of each step.

run_decomposition(M, S, FinalResult, History) :-
    % Convert inputs to recollection structures
    integer_to_recollection(M, M_Rec),
    integer_to_recollection(S, S_Rec),
    
    current_cgi_base(Base),
    integer_to_recollection(Base, Base_Rec),
    
    % Emit modal signal: entering decomposition arithmetic context (compressive necessity)
    s(comp_nec(checking_subtraction_validity)),
    
    (greater_than(S_Rec, M_Rec) ->
        History = [step(q_error, 0, 0, 'Error: Subtrahend > Minuend.')],
        FinalResult = 'error'
    ;
        % Decompose both M and S into tens and ones using grounded operations
        s(exp_poss(decomposing_numbers_into_base_components)),
        
        base_decompose_grounded(S_Rec, Base_Rec, S_T_Rec, S_O_Rec),
        base_decompose_grounded(M_Rec, Base_Rec, M_T_Rec, M_O_Rec),
        
        % Convert back to integers for state representation (keeping interface compatible)
        recollection_to_integer(S_T_Rec, S_T),
        recollection_to_integer(S_O_Rec, S_O),
        recollection_to_integer(M_T_Rec, M_T),
        recollection_to_integer(M_O_Rec, M_O),

        InitialState = state(q_init, M_T_Rec, M_O_Rec, S_T_Rec, S_O_Rec),

        format(string(InitialInterpretation), 'Inputs: M=~w, S=~w. Decompose M (~wT+~wO) and S (~wT+~wO).', [M, S, M_T, M_O, S_T, S_O]),
        InitialHistoryEntry = step(q_start, M_T, M_O, InitialInterpretation),

        run(InitialState, Base_Rec, [InitialHistoryEntry], ReversedHistory),
        reverse(ReversedHistory, History),

        (last(History, step(q_accept, RT, RO, _)) ->
            % Recompose result using grounded arithmetic
            integer_to_recollection(RT, RT_Rec),
            integer_to_recollection(RO, RO_Rec),
            base_recompose_grounded(RT_Rec, RO_Rec, Base_Rec, FinalResult_Rec),
            recollection_to_integer(FinalResult_Rec, FinalResult)
        ;
            FinalResult = 'computation_error'
        )
    ).

% run/4 is the main recursive loop of the state machine.
run(state(q_accept, R_T_Rec, R_O_Rec, _, _), Base_Rec, AccHistory, FinalHistory) :-
    base_recompose_grounded(R_T_Rec, R_O_Rec, Base_Rec, Result_Rec),
    recollection_to_integer(Result_Rec, Result),
    recollection_to_integer(R_T_Rec, R_T),
    recollection_to_integer(R_O_Rec, R_O),
    format(string(Interpretation), 'Accept. Final Result: ~w.', [Result]),
    HistoryEntry = step(q_accept, R_T, R_O, Interpretation),
    FinalHistory = [HistoryEntry | AccHistory].

run(CurrentState, Base_Rec, AccHistory, FinalHistory) :-
    transition(CurrentState, Base_Rec, NextState, Interpretation),
    CurrentState = state(Name, R_T_Rec, R_O_Rec, _, _),
    recollection_to_integer(R_T_Rec, R_T),
    recollection_to_integer(R_O_Rec, R_O),
    HistoryEntry = step(Name, R_T, R_O, Interpretation),
    run(NextState, Base_Rec, [HistoryEntry | AccHistory], FinalHistory).

% transition/4 defines the logic for moving from one state to the next.

% From q_init, proceed to subtract the tens column.
transition(state(q_init, R_T_Rec, R_O_Rec, S_T_Rec, S_O_Rec), _Base_Rec, state(q_sub_bases, R_T_Rec, R_O_Rec, S_T_Rec, S_O_Rec),
           'Proceed to subtract bases.').

% In q_sub_bases, subtract the tens and move to check the ones column.
transition(state(q_sub_bases, R_T_Rec, R_O_Rec, S_T_Rec, S_O_Rec), _Base_Rec, state(q_check_ones, New_R_T_Rec, R_O_Rec, S_T_Rec, S_O_Rec), Interpretation) :-
    subtract_grounded(R_T_Rec, S_T_Rec, New_R_T_Rec),
    recollection_to_integer(R_T_Rec, R_T),
    recollection_to_integer(S_T_Rec, S_T),
    recollection_to_integer(New_R_T_Rec, New_R_T),
    s(comp_nec(subtracting_base_components)),
    format(string(Interpretation), 'Subtract Bases: ~wT - ~wT = ~wT.', [R_T, S_T, New_R_T]).

% In q_check_ones, determine if borrowing is needed.
transition(state(q_check_ones, R_T_Rec, R_O_Rec, S_T_Rec, S_O_Rec), _Base_Rec, state(q_sub_ones, R_T_Rec, R_O_Rec, S_T_Rec, S_O_Rec), Interpretation) :-
    \+ greater_than(S_O_Rec, R_O_Rec), % R_O >= S_O in grounded terms
    recollection_to_integer(R_O_Rec, R_O),
    recollection_to_integer(S_O_Rec, S_O),
    s(exp_poss(sufficient_ones_for_subtraction)),
    format(string(Interpretation), 'Sufficient Ones (~w >= ~w). Proceed.', [R_O, S_O]).

transition(state(q_check_ones, R_T_Rec, R_O_Rec, S_T_Rec, S_O_Rec), _Base_Rec, state(q_decompose, R_T_Rec, R_O_Rec, S_T_Rec, S_O_Rec), Interpretation) :-
    greater_than(S_O_Rec, R_O_Rec), % R_O < S_O in grounded terms
    recollection_to_integer(R_O_Rec, R_O),
    recollection_to_integer(S_O_Rec, S_O),
    s(comp_nec(need_decomposition_for_subtraction)),
    format(string(Interpretation), 'Insufficient Ones (~w < ~w). Need decomposition.', [R_O, S_O]).

% In q_decompose, perform the "borrow" from the tens column.
transition(state(q_decompose, R_T_Rec, R_O_Rec, S_T_Rec, S_O_Rec), Base_Rec, state(q_sub_ones, New_R_T_Rec, New_R_O_Rec, S_T_Rec, S_O_Rec), Interpretation) :-
    integer_to_recollection(1, One_Rec),
    subtract_grounded(R_T_Rec, One_Rec, New_R_T_Rec), % R_T > 0 is implicit in successful subtraction
    add_grounded(R_O_Rec, Base_Rec, New_R_O_Rec),
    recollection_to_integer(New_R_T_Rec, New_R_T),
    recollection_to_integer(New_R_O_Rec, New_R_O),
    s(exp_poss(decomposing_ten_into_ones)),
    format(string(Interpretation), 'Decomposed 1 Ten. New state: ~wT, ~wO.', [New_R_T, New_R_O]).

% In q_sub_ones, subtract the ones column and transition to the final accept state.
transition(state(q_sub_ones, R_T_Rec, R_O_Rec, S_T_Rec, S_O_Rec), _Base_Rec, state(q_accept, R_T_Rec, New_R_O_Rec, S_T_Rec, S_O_Rec), Interpretation) :-
    subtract_grounded(R_O_Rec, S_O_Rec, New_R_O_Rec),
    recollection_to_integer(R_O_Rec, R_O),
    recollection_to_integer(S_O_Rec, S_O),
    recollection_to_integer(New_R_O_Rec, New_R_O),
    s(comp_nec(subtracting_ones_components)),
    format(string(Interpretation), 'Subtract Ones: ~wO - ~wO = ~wO.', [R_O, S_O, New_R_O]).
