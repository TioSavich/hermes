/** <module> Student Addition Strategy: Counting On by Bases and Ones (COBO)
 *
 * This module implements the 'Counting On by Bases and then Ones' (COBO)
 * strategy for multi-digit addition, modeled as a finite state machine.
 * This strategy involves decomposing one number (B) into its base-10
 * components and then incrementally counting on from the other number (A).
 *
 * The process is as follows:
 * 1. Decompose B into a number of 'bases' (tens) and 'ones'.
 * 2. Starting with A, count on by ten for each base.
 * 3. After all bases are added, count on by one for each one.
 *
 * The state of the automaton is represented by the term:
 * `state(StateName, Sum, BaseCounter, OneCounter)`
 *
 * The history of execution is captured as a list of steps:
 * `step(StateName, CurrentSum, BaseCounter, OneCounter, Interpretation)`
 *
 * 
 * 
 */
:- module(sar_add_cobo,
          [ run_cobo/4
          ]).

:- use_module(library(lists)).
:- use_module(formalization(grounded_arithmetic)).
:- use_module(formalization(grounded_utils)).
:- use_module(pml(pml_operators), [s/1, 'comp_nec'/1, 'exp_poss'/1]).

%!      run_cobo(+A:integer, +B:integer, -FinalSum:integer, -History:list) is det.
%
%       Executes the 'Counting On by Bases and Ones' (COBO) addition strategy for A + B.
%
%       This predicate initializes the state machine and runs it until it
%       reaches the accept state. It traces the execution, providing a
%       step-by-step history of how the sum was computed by first counting
%       on by tens, and then by ones.
%
%       @param A The first addend, the number to start counting from.
%       @param B The second addend, which is decomposed into bases and ones.
%       @param FinalSum The resulting sum of A and B.
%       @param History A list of `step/5` terms that describe the state
%       machine's execution path and the interpretation of each step.

run_cobo(A, B, FinalSum, History) :-
    % Emit cognitive cost for the overall strategy setup
    incur_cost(inference),
    
    % Convert inputs to recollection format for grounded arithmetic
    integer_to_recollection(A, _RecA),
    integer_to_recollection(B, RecB),
    
    % Decompose B into base-10 components without using arithmetic
    decompose_base10(RecB, RecBases, RecOnes),
    
    % Convert back to integers for compatibility with existing state machine
    recollection_to_integer(RecBases, BaseCounter),
    recollection_to_integer(RecOnes, OneCounter),

    InitialState = state(q_initialize, A, BaseCounter, OneCounter),

    % Record the start and the interpretation of the initialization.
    format(string(InitialInterpretation), 'Initialize Sum to ~w. Decompose ~w into ~w Bases, ~w Ones.', [A, B, BaseCounter, OneCounter]),
    InitialHistoryEntry = step(q_start, A, BaseCounter, OneCounter, InitialInterpretation),

    % Run the state machine.
    run(InitialState, [InitialHistoryEntry], ReversedHistory),

    % Reverse the history for correct chronological order.
    reverse(ReversedHistory, History),

    % Extract the final sum from the last history entry.
    (last(History, step(_, FinalSum, _, _, _)) -> true ; FinalSum = A).


% run/3 is the main recursive loop of the state machine.
% It drives the state transitions until the accept state is reached.

% Base case: Stop when the machine reaches the 'q_accept' state.
run(state(q_accept, Sum, BC, OC), AccHistory, FinalHistory) :-
    incur_cost(inference),
    Interpretation = 'All ones added. Accept.',
    HistoryEntry = step(q_accept, Sum, BC, OC, Interpretation),
    FinalHistory = [HistoryEntry | AccHistory].

% Recursive step: Perform one transition and continue.
run(CurrentState, AccHistory, FinalHistory) :-
    once(transition(CurrentState, NextState, Interpretation)),
    CurrentState = state(Name, Sum, BC, OC),
    HistoryEntry = step(Name, Sum, BC, OC, Interpretation),
    run(NextState, [HistoryEntry | AccHistory], FinalHistory).

% transition/3 defines the logic for moving from one state to the next.

% From q_initialize, always transition to q_add_bases to start counting.
transition(state(q_initialize, Sum, BaseCounter, OneCounter), state(q_add_bases, Sum, BaseCounter, OneCounter), Interpretation) :-
    incur_cost(inference),
    % Emit modal signal: entering focused counting mode (compressive necessity)
    incur_cost(modal_shift),
    s(comp_nec(focus_on_bases)),
    Interpretation = 'Begin counting on by bases.'.

% Loop in q_add_bases, counting on by one base (10) at a time.
transition(state(q_add_bases, Sum, BaseCounter, OneCounter), state(q_add_bases, NewSum, NewBaseCounter, OneCounter), Interpretation) :-
    % Check if BaseCounter > 0 using grounded comparison
    integer_to_recollection(BaseCounter, RecBaseCounter),
    \+ is_zero_grounded(RecBaseCounter),
    
    % Add 10 to Sum using grounded arithmetic
    incur_cost(slide_step),
    integer_to_recollection(Sum, RecSum),
    integer_to_recollection(10, RecTen),
    add_grounded(RecSum, RecTen, RecNewSum),
    recollection_to_integer(RecNewSum, NewSum),
    
    % Subtract 1 from BaseCounter using grounded arithmetic
    incur_cost(unit_count),
    integer_to_recollection(1, RecOne),
    subtract_grounded(RecBaseCounter, RecOne, RecNewBaseCounter),
    recollection_to_integer(RecNewBaseCounter, NewBaseCounter),
    
    format(string(Interpretation), 'Count on by base: ~w -> ~w.', [Sum, NewSum]).

% When all bases are added, transition from q_add_bases to q_add_ones.
transition(state(q_add_bases, Sum, BaseCounter, OneCounter), state(q_add_ones, Sum, BaseCounter, OneCounter), Interpretation) :-
    integer_to_recollection(BaseCounter, RecBaseCounter),
    is_zero_grounded(RecBaseCounter),
    incur_cost(inference),
    % Emit modal signal: transitioning to more fine-grained counting (expansive possibility)
    incur_cost(modal_shift),
    s(exp_poss(shift_to_ones)),
    Interpretation = 'All bases added. Transition to adding ones.'.

% Loop in q_add_ones, counting on by one at a time.
transition(state(q_add_ones, Sum, BaseCounter, OneCounter), state(q_add_ones, NewSum, BaseCounter, NewOneCounter), Interpretation) :-
    % Check if OneCounter > 0 using grounded comparison
    integer_to_recollection(OneCounter, RecOneCounter),
    \+ is_zero_grounded(RecOneCounter),
    
    % Add 1 to Sum using grounded arithmetic
    incur_cost(unit_count),
    integer_to_recollection(Sum, RecSum),
    integer_to_recollection(1, RecOne),
    add_grounded(RecSum, RecOne, RecNewSum),
    recollection_to_integer(RecNewSum, NewSum),
    
    % Subtract 1 from OneCounter using grounded arithmetic
    subtract_grounded(RecOneCounter, RecOne, RecNewOneCounter),
    recollection_to_integer(RecNewOneCounter, NewOneCounter),
    
    format(string(Interpretation), 'Count on by one: ~w -> ~w.', [Sum, NewSum]).

% When all ones are added, transition from q_add_ones to the final accept state.
transition(state(q_add_ones, Sum, BaseCounter, OneCounter), state(q_accept, Sum, BaseCounter, OneCounter), Interpretation) :-
    integer_to_recollection(OneCounter, RecOneCounter),
    is_zero_grounded(RecOneCounter),
    incur_cost(inference),
    Interpretation = 'All ones added. Final sum reached.'.
