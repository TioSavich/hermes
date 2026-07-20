/** <module> Program synthesis from arithmetic primitives
 *
 * Generator-driven synthesis: enumerate compositions of named primitives
 * (successor, predecessor, max, min, iter_succ, iter_pred) under a fixed
 * sequential-composition grammar, check each candidate against input/output
 * examples, return the first program whose behavior matches.
 *
 * No oracle. No teacher lookup. The search is pure iterative deepening
 * over composition depth.
 */

:- module(synth, [
    synthesize/3,         % +Examples, +MaxDepth, -Program
    synthesize_all/4,     % +Examples, +Depth, +MaxN, -Programs
    run_program/3,        % +Program, +Inputs, -Output
    print_program/1,      % +Program
    target/2              % ?TargetName, ?Examples
]).


% =============================================================================
% PRIMITIVES
% =============================================================================
%
% primitive(Name, InputArity) declares each primitive's signature.
% call_prim(Name, InputArgs, Output) defines its semantics.
%
% All primitives are deterministic value-producers (no tests, no branching).
% This keeps the grammar straight-line sequential — the simplest interesting
% case. Conditionals come later.

primitive(succ,       1).
primitive(pred,       1).
primitive(max,        2).
primitive(min,        2).
primitive(iter_succ,  2).
primitive(iter_pred,  2).

call_prim(succ, [X], Y) :-
    integer(X), Y is X + 1.

call_prim(pred, [X], Y) :-
    integer(X), X >= 1, Y is X - 1.

call_prim(max, [X, Y], M) :-
    integer(X), integer(Y), M is max(X, Y).

call_prim(min, [X, Y], M) :-
    integer(X), integer(Y), M is min(X, Y).

call_prim(iter_succ, [Start, Count], End) :-
    integer(Start), integer(Count), Count >= 0,
    End is Start + Count.

call_prim(iter_pred, [Start, Count], End) :-
    integer(Start), integer(Count), Count >= 0, Start >= Count,
    End is Start - Count.


% =============================================================================
% PROGRAM EXECUTION
% =============================================================================
%
% A program is prog(Steps) where Steps is a list of step(Op, ArgRefs).
% Each step's output becomes available as var(N) where N is the step's
% 1-indexed position. The program's output is the result of the last step.
%
% ArgRefs:  input(I) refers to the I-th program input;
%           var(I)   refers to step I's output (only valid if I < current step).

run_program(prog(Steps), Inputs, Output) :-
    execute(Steps, Inputs, [], Vars),
    last(Vars, Output).

execute([], _, Vars, Vars).
execute([step(Op, ArgRefs)|Rest], Inputs, Vars, FinalVars) :-
    resolve_args(ArgRefs, Inputs, Vars, Args),
    call_prim(Op, Args, NewVal),
    append(Vars, [NewVal], Vars1),
    execute(Rest, Inputs, Vars1, FinalVars).

resolve_args([], _, _, []).
resolve_args([input(I)|Rest], Inputs, Vars, [V|VRest]) :-
    nth1(I, Inputs, V),
    resolve_args(Rest, Inputs, Vars, VRest).
resolve_args([var(I)|Rest], Inputs, Vars, [V|VRest]) :-
    nth1(I, Vars, V),
    resolve_args(Rest, Inputs, Vars, VRest).


% =============================================================================
% GENERATOR
% =============================================================================
%
% generate_program(+Depth, +NumInputs, -Program) backtracks through every
% well-formed program of exactly Depth steps over NumInputs inputs.

generate_program(Depth, NumInputs, prog(Steps)) :-
    Depth >= 1,
    length(Steps, Depth),
    generate_steps(Steps, 0, NumInputs).

generate_steps([], _, _).
generate_steps([step(Op, Args)|Rest], PrevSteps, NumInputs) :-
    primitive(Op, Arity),
    length(Args, Arity),
    generate_args(Args, PrevSteps, NumInputs),
    Next is PrevSteps + 1,
    generate_steps(Rest, Next, NumInputs).

generate_args([], _, _).
generate_args([A|Rest], PrevSteps, NumInputs) :-
    arg_ref(A, PrevSteps, NumInputs),
    generate_args(Rest, PrevSteps, NumInputs).

arg_ref(input(I), _, NumInputs) :-
    between(1, NumInputs, I).
arg_ref(var(I), PrevSteps, _) :-
    PrevSteps >= 1,
    between(1, PrevSteps, I).


% =============================================================================
% TARGET MATCHING
% =============================================================================

matches_target(Program, Examples) :-
    forall(member(io(Inputs, Expected), Examples),
           ( catch(run_program(Program, Inputs, Actual), _, fail),
             Actual == Expected )).


% =============================================================================
% SYNTHESIS — iterative deepening
% =============================================================================

synthesize(Examples, MaxDepth, Program) :-
    Examples = [io(Inputs, _)|_],
    length(Inputs, NumInputs),
    between(1, MaxDepth, Depth),
    generate_program(Depth, NumInputs, Program),
    matches_target(Program, Examples), !.

synthesize_all(Examples, Depth, MaxN, Programs) :-
    Examples = [io(Inputs, _)|_],
    length(Inputs, NumInputs),
    findnsols(MaxN, Program,
              ( generate_program(Depth, NumInputs, Program),
                matches_target(Program, Examples) ),
              Programs), !.
synthesize_all(_, _, _, []).


% =============================================================================
% PRETTY PRINTING
% =============================================================================

print_program(prog(Steps)) :-
    print_steps(Steps, 1).

print_steps([], _).
print_steps([step(Op, ArgRefs)|Rest], Index) :-
    format("  var(~w) <- ~w(", [Index, Op]),
    print_args(ArgRefs),
    format(")~n"),
    Index1 is Index + 1,
    print_steps(Rest, Index1).

print_args([]).
print_args([A]) :- print_arg(A).
print_args([A1, A2|Rest]) :- print_arg(A1), format(", "), print_args([A2|Rest]).

print_arg(input(I)) :- format("input(~w)", [I]).
print_arg(var(I))   :- format("var(~w)",   [I]).


% =============================================================================
% TARGETS
% =============================================================================
%
% Each target is a list of io(Inputs, Output) pairs that constrain the search.
% Inputs is a list of integers, Output is the expected scalar result.

target(count_on_from_larger, [
    io([5, 3], 8),
    io([3, 5], 8),
    io([7, 2], 9),
    io([2, 7], 9),
    io([10, 4], 14)
]).

target(count_up_missing_addend, [
    io([10, 3], 7),
    io([8, 2], 6),
    io([15, 5], 10),
    io([20, 7], 13)
]).

target(take_away, [
    io([10, 3], 7),
    io([8, 2], 6),
    io([15, 5], 10)
]).

% A trivially-deformed target: "drop the smaller addend" — instead of summing,
% just return the larger. This is what an over-simplified count-on would do
% if it confused "iterate by counter" with "return start". Pure conjecture
% as an undocumented deformation; included to see if the search finds it.
target(drop_smaller_addend, [
    io([5, 3], 5),
    io([3, 5], 5),
    io([7, 2], 7)
]).
