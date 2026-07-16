/** <module> Student Addition Strategy: Counting On
 *
 * This module implements the 'Counting On' strategy for addition, modeled
 * as a finite state machine. This is the first strategy children learn after
 * Counting All — instead of enumerating both addends, start at A and
 * iterate successor B times.
 *
 * Uses grounded arithmetic (add_grounded with recollections) for each
 * counting step. Each step costs one unit_count inference.
 *
 * DEVELOPMENTAL ROLE: This is the first strategy a learner synthesizes
 * from primitives. A learner with only successor can compose "iterate
 * successor B times from A" to get Counting On. It costs O(B) inferences,
 * which is cheaper than Counting All's O(A+B) but still linear — triggering
 * a crisis on multi-digit problems (38+55 costs 55 steps) that motivates
 * learning COBO or RMB.
 *
 * COUNTING EXPERIENCE: A learner that counts on through 0-100 experiences
 * every base-10 landmark (9→10, 19→20, ..., 99→100). This experiential
 * knowledge — "13 is 3 more than 10" — is what other strategies formalize
 * as mod(13, 10) = 3. The knowledge comes from counting, not from a
 * built-in function.
 *
 * The state of the automaton is represented by the term:
 * `state(StateName, CurrentValue, RemainingCount)`
 *
 * The history of execution is captured as a list of steps:
 * `step(StateName, CurrentValue, RemainingCount, Interpretation)`
 *
 */
:- module(sar_add_counting_on,
          [ run_counting_on/4
          ]).

:- use_module(library(lists)).
:- use_module(formalization(grounded_arithmetic), [incur_cost/1, successor/2,
                                     integer_to_recollection/2,
                                     recollection_to_integer/2]).
:- use_module(formalization(grounded_utils), [is_zero_grounded/1]).
:- use_module(arche_trace(sequent_engine), [s/1, comp_nec/1, exp_poss/1]).

%!      run_counting_on(+A:integer, +B:integer, -FinalSum:integer, -History:list) is det.
%
%       Executes the 'Counting On' addition strategy for A + B.
%
%       Start at A, count on B times by iterating successor. Each step
%       produces one tick through the counting DPDA (carry handled
%       automatically across place values).
%
%       @param A The first addend, the number to start counting from.
%       @param B The second addend, the number of times to count on.
%       @param FinalSum The resulting sum of A + B.
%       @param History A list of step/4 terms tracing the execution.

run_counting_on(A, B, FinalSum, History) :-
    incur_cost(inference),

    InitialState = state(q_initialize, A, B),

    format(string(InitInterp),
           'Start at ~w, count on ~w times.', [A, B]),
    InitEntry = step(q_start, A, B, InitInterp),

    run(InitialState, [InitEntry], RevHistory),
    reverse(RevHistory, History),

    (   last(History, step(_, FinalSum, _, _))
    ->  true
    ;   FinalSum = A
    ).


% --- FSM engine ---

% Accept: remaining count reached zero.
run(state(q_accept, Sum, 0), Acc, Final) :-
    incur_cost(inference),
    Entry = step(q_accept, Sum, 0, 'Counting complete.'),
    Final = [Entry | Acc].

% Recursive step.
run(CurrentState, Acc, Final) :-
    transition(CurrentState, NextState, Interp),
    CurrentState = state(Name, Val, Rem),
    Entry = step(Name, Val, Rem, Interp),
    run(NextState, [Entry | Acc], Final).


% --- Transitions ---

% q_initialize → q_count: begin counting on.
transition(state(q_initialize, Sum, Count),
           state(q_count, Sum, Count),
           'Begin counting on by ones.') :-
    incur_cost(inference),
    s(comp_nec(focus_on_counting_on)).

% q_count with remaining > 0: iterate successor.
transition(state(q_count, Sum, Count),
           state(q_count, NewSum, NewCount),
           Interp) :-
    integer_to_recollection(Count, RecCount),
    \+ is_zero_grounded(RecCount),

    % One successor step — grounded cost
    incur_cost(unit_count),
    integer_to_recollection(Sum, RecSum),
    integer_to_recollection(1, RecOne),
    grounded_arithmetic:add_grounded(RecSum, RecOne, RecNewSum),
    recollection_to_integer(RecNewSum, NewSum),

    % Decrement remaining count
    grounded_arithmetic:subtract_grounded(RecCount, RecOne, RecNewCount),
    recollection_to_integer(RecNewCount, NewCount),

    format(string(Interp), 'Count on: ~w -> ~w.', [Sum, NewSum]).

% q_count with remaining = 0: done.
transition(state(q_count, Sum, Count),
           state(q_accept, Sum, 0),
           'All counts complete. Final sum reached.') :-
    integer_to_recollection(Count, RecCount),
    is_zero_grounded(RecCount),
    incur_cost(inference).
