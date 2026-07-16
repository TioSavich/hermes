/** <module> Student Subtraction Strategy: Counting Back
 *
 * This module implements the 'Counting Back' strategy for subtraction,
 * modeled as a finite state machine. This is the foundational subtraction
 * strategy — start at the minuend M and iterate predecessor S times.
 *
 * Each step is a single predecessor (tock) through the counting mechanism,
 * with borrow/carry handled across place values.
 *
 * The state of the automaton is represented by the term:
 * `state(StateName, CurrentValue, RemainingCount)`
 *
 * The history of execution is captured as a list of steps:
 * `step(StateName, CurrentValue, RemainingCount, Interpretation)`
 *
 */
:- module(sar_sub_counting_back,
          [ run_counting_back/4
          ]).

:- use_module(library(lists)).
:- use_module(formalization(grounded_arithmetic), [incur_cost/1, predecessor/2,
                                     integer_to_recollection/2,
                                     recollection_to_integer/2]).
:- use_module(formalization(grounded_utils), [is_zero_grounded/1]).
:- use_module(arche_trace(sequent_engine), [s/1, comp_nec/1, exp_poss/1]).

%!      run_counting_back(+M:integer, +S:integer, -FinalResult:integer, -History:list) is det.
%
%       Executes the 'Counting Back' subtraction strategy for M - S.
%
%       Start at M, count back S times by iterating predecessor.
%       Fails if S > M (cannot count below zero in natural numbers).
%
%       @param M The minuend, the number to start counting back from.
%       @param S The subtrahend, the number of times to count back.
%       @param FinalResult The resulting difference M - S.
%       @param History A list of step/4 terms tracing the execution.

run_counting_back(M, S, FinalResult, History) :-
    incur_cost(inference),

    % Check if subtraction is valid (M >= S)
    integer_to_recollection(M, RecM),
    integer_to_recollection(S, RecS),
    (   grounded_arithmetic:smaller_than(RecM, RecS)
    ->  % Error: can't subtract more than we have
        History = [step(q_error, M, S, 'Cannot subtract: subtrahend exceeds minuend.')],
        FinalResult = error
    ;   InitialState = state(q_initialize, M, S),
        format(string(InitInterp),
               'Start at ~w, count back ~w times.', [M, S]),
        InitEntry = step(q_start, M, S, InitInterp),
        run(InitialState, [InitEntry], RevHistory),
        reverse(RevHistory, History),
        (   last(History, step(_, FinalResult, _, _))
        ->  true
        ;   FinalResult = M
        )
    ).


% --- FSM engine ---

% Accept: remaining count reached zero.
run(state(q_accept, Val, 0), Acc, Final) :-
    incur_cost(inference),
    Entry = step(q_accept, Val, 0, 'Counting back complete.'),
    Final = [Entry | Acc].

% Recursive step.
run(CurrentState, Acc, Final) :-
    transition(CurrentState, NextState, Interp),
    CurrentState = state(Name, Val, Rem),
    Entry = step(Name, Val, Rem, Interp),
    run(NextState, [Entry | Acc], Final).


% --- Transitions ---

% q_initialize → q_count: begin counting back.
transition(state(q_initialize, Val, Count),
           state(q_count, Val, Count),
           'Begin counting back by ones.') :-
    incur_cost(inference),
    s(comp_nec(focus_on_counting_back)).

% q_count with remaining > 0: iterate predecessor.
transition(state(q_count, Val, Count),
           state(q_count, NewVal, NewCount),
           Interp) :-
    integer_to_recollection(Count, RecCount),
    \+ is_zero_grounded(RecCount),

    % One predecessor step — grounded cost
    incur_cost(unit_count),
    integer_to_recollection(Val, RecVal),
    integer_to_recollection(1, RecOne),
    grounded_arithmetic:subtract_grounded(RecVal, RecOne, RecNewVal),
    recollection_to_integer(RecNewVal, NewVal),

    % Decrement remaining count
    grounded_arithmetic:subtract_grounded(RecCount, RecOne, RecNewCount),
    recollection_to_integer(RecNewCount, NewCount),

    format(string(Interp), 'Count back: ~w -> ~w.', [Val, NewVal]).

% q_count with remaining = 0: done.
transition(state(q_count, Val, Count),
           state(q_accept, Val, 0),
           'All counts complete. Final difference reached.') :-
    integer_to_recollection(Count, RecCount),
    is_zero_grounded(RecCount),
    incur_cost(inference).
