/** <module> Cost-aware program synthesis with structural (base-parametric) cost
 *
 * Humans invent arithmetic strategies to avoid cognitive work. The successor
 * function is expensive for inputs like 45 - 27, so people invent shortcuts
 * that exploit base-alignment. Misconceptions are programs that look equally
 * cheap by the same heuristic but mis-execute a compensation step.
 *
 * This synthesizer:
 *   1. Generates candidate programs over a small primitive set.
 *   2. Computes the cognitive cost of each candidate on each input.
 *   3. For a target input/output set, finds:
 *        - PRODUCTIVE candidates: cheapest programs producing the correct output
 *        - DEFORMATION candidates: programs at cost <= productive's cost that
 *          produce a consistent wrong output across the examples
 *
 * Structural cost: cost depends only on residues modulo the working base and
 * on absolute cognitive constants. Base 10, base 12, base 5, base 7 use the
 * same cost function with the base parameter swapped. By the naturality
 * proposition (Proposition 1 in ALGEBRAIC.tex), the cost-minimal program
 * shape is preserved under base shift. Strategic invariance is therefore a
 * theorem of this cost model, not an empirical question.
 */

:- module(synth_lazy, [
    discover/5,            % +Examples, +MaxDepth, +Base, -Productive, -Deformations
    run_program/5,         % +Program, +Inputs, +Base, -Output, -Cost
    print_program/1,
    print_program_with_cost/2,
    target/3               % ?TargetName, ?Base, ?Examples
]).

:- use_module(library(lists)).


% =============================================================================
% PRIMITIVES
% =============================================================================
%
% Minimal primitive set focused on base-alignment strategies. The working
% base is supplied at execution time as a configuration parameter, not as
% an argument to each primitive — this matches how a learner reasons
% (they know what base they're working in; it's ambient, not per-operation).

primitive(iter_succ,             2).
primitive(iter_pred,             2).
primitive(delta_to_next_base,    1).
primitive(delta_from_prev_base,  1).

call_prim(iter_succ, [Start, Count], _Base, End) :-
    integer(Start), integer(Count), Count >= 0,
    End is Start + Count.
call_prim(iter_pred, [Start, Count], _Base, End) :-
    integer(Start), integer(Count), Count >= 0, Start >= Count,
    End is Start - Count.
call_prim(delta_to_next_base, [X], Base, D) :-
    integer(X), integer(Base), Base >= 2, X >= 0,
    R is X mod Base,
    ( R =:= 0 -> D = 0 ; D is Base - R ).
call_prim(delta_from_prev_base, [X], Base, D) :-
    integer(X), integer(Base), Base >= 2, X >= 0,
    D is X mod Base.


% =============================================================================
% COST MODEL — STRUCTURAL
% =============================================================================
%
% Per-step cost depends only on:
%   (a) the primitive's structural type,
%   (b) residues of arguments modulo the working base, and
%   (c) absolute cognitive constants (here: a subitization bound K=3).
%
% No clause mentions a base-specific numeric literal. The cost is
% therefore natural in the base under the re-encoding functor that
% preserves residue classes.

prim_cost(delta_to_next_base,    _, _, 1).
prim_cost(delta_from_prev_base,  _, _, 1).
prim_cost(iter_succ, [Start, Count], Base, Cost) :-
    iter_cost(Start, Count, Base, Cost).
prim_cost(iter_pred, [Start, Count], Base, Cost) :-
    iter_cost(Start, Count, Base, Cost).

% iter_cost: cost of executing an iterating primitive.
%   - Count is a non-zero multiple of Base   -> 1   ("count by [Base]s")
%   - Count is subitizable (<= 3)            -> 1   (trivial count)
%   - Start is base-aligned and Count < Base -> 1   (known compound fact)
%   - otherwise                              -> Count
iter_cost(_Start, Count, Base, 1) :-
    integer(Count), integer(Base),
    Count > 0, Count mod Base =:= 0, !.
iter_cost(_Start, Count, _Base, 1) :-
    integer(Count), Count >= 0, Count =< 3, !.
iter_cost(Start, Count, Base, 1) :-
    integer(Start), integer(Count), integer(Base),
    Start mod Base =:= 0, Count >= 0, Count < Base, !.
iter_cost(_Start, Count, _Base, Count) :-
    integer(Count), Count >= 0.


% =============================================================================
% EXECUTION
% =============================================================================

run_program(prog(Steps), Inputs, Base, Output, TotalCost) :-
    execute(Steps, Inputs, Base, [], 0, Vars, TotalCost),
    last(Vars, Output).

execute([], _, _, Vars, Cost, Vars, Cost).
execute([step(Op, ArgRefs)|Rest], Inputs, Base, Vars, CostAcc, FinalVars, FinalCost) :-
    resolve_args(ArgRefs, Inputs, Vars, Args),
    call_prim(Op, Args, Base, NewVal),
    prim_cost(Op, Args, Base, StepCost),
    Cost1 is CostAcc + StepCost,
    append(Vars, [NewVal], Vars1),
    execute(Rest, Inputs, Base, Vars1, Cost1, FinalVars, FinalCost).

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

generate_program(MaxDepth, NumInputs, prog(Steps)) :-
    between(1, MaxDepth, D),
    length(Steps, D),
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

arg_ref(input(I), _, NumInputs) :- between(1, NumInputs, I).
arg_ref(var(I), PrevSteps, _)   :- PrevSteps >= 1, between(1, PrevSteps, I).


% =============================================================================
% BEHAVIOR PROFILE
% =============================================================================

behavior(Program, Examples, Base, OutputTuple, TotalCost) :-
    behavior_(Examples, Program, Base, [], OutputTupleR, 0, TotalCost),
    reverse(OutputTupleR, OutputTuple).

behavior_([], _, _, Outs, Outs, Cost, Cost).
behavior_([io(Inputs, _)|Rest], Program, Base, OutsAcc, FinalOuts, CostAcc, FinalCost) :-
    ( catch(run_program(Program, Inputs, Base, Out, RunCost), _, fail)
    -> Cost1 is CostAcc + RunCost,
       behavior_(Rest, Program, Base, [Out|OutsAcc], FinalOuts, Cost1, FinalCost)
    ;  fail
    ).


% =============================================================================
% DISCOVERY
% =============================================================================

discover(Examples, MaxDepth, Base, Productive, Deformations) :-
    Examples = [io(Inputs, _)|_],
    length(Inputs, NumInputs),
    expected_tuple(Examples, Expected),
    nb_setval(synth_min_cost,   1000000),
    nb_setval(synth_productive, []),
    nb_setval(synth_deforms,    []),
    forall(
        ( generate_program(MaxDepth, NumInputs, P),
          behavior(P, Examples, Base, OutTuple, Cost) ),
        process_candidate(P, OutTuple, Cost, Expected)
    ),
    nb_getval(synth_min_cost,   MinCost),
    nb_getval(synth_productive, ProgsRaw),
    nb_getval(synth_deforms,    DeformsRaw),
    sort(ProgsRaw, ProgsSorted),
    findall(MinCost-P, member(P, ProgsSorted), Productive),
    ( ProgsSorted = [FirstProd|_], uses_shortcut(FirstProd)
    -> include(deform_under_cost(MinCost), DeformsRaw, KeptDeforms),
       group_by_tuple(KeptDeforms, Deformations)
    ;  Deformations = []
    ).

deform_under_cost(MaxCost, _-C-_) :- C =< MaxCost.

process_candidate(P, Expected, Cost, Expected) :- !,
    nb_getval(synth_min_cost, CurMin),
    ( Cost < CurMin
    -> nb_setval(synth_min_cost, Cost),
       nb_setval(synth_productive, [P]),
       nb_getval(synth_deforms, OldDeforms),
       include(deform_under_cost(Cost), OldDeforms, NewDeforms),
       nb_setval(synth_deforms, NewDeforms)
    ; Cost =:= CurMin
    -> nb_getval(synth_productive, Ps),
       nb_setval(synth_productive, [P|Ps])
    ; true
    ).
process_candidate(P, OutTuple, Cost, _Expected) :-
    nb_getval(synth_min_cost, CurMin),
    Cost =< CurMin,
    uses_shortcut(P),
    !,
    nb_getval(synth_deforms, Ds),
    nb_setval(synth_deforms, [OutTuple-Cost-P|Ds]).
process_candidate(_, _, _, _).

uses_shortcut(prog(Steps)) :-
    member(step(Op, _), Steps),
    shortcut_op(Op), !.

shortcut_op(delta_to_next_base).
shortcut_op(delta_from_prev_base).

expected_tuple([], []).
expected_tuple([io(_, E)|Rest], [E|Es]) :- expected_tuple(Rest, Es).

group_by_tuple(Raw, Grouped) :-
    findall(Tuple, member(Tuple-_-_, Raw), TuplesRaw),
    list_to_set(TuplesRaw, Tuples),
    findall(Tuple-MinCost-Programs,
            ( member(Tuple, Tuples),
              findall(C-P, member(Tuple-C-P, Raw), CPs),
              sort(CPs, [MinCost-_|_]),
              findall(P, member(MinCost-P, CPs), Programs) ),
            Grouped0),
    sort(Grouped0, Grouped).


% =============================================================================
% PRETTY PRINTING
% =============================================================================

print_program(prog(Steps)) :-
    print_steps(Steps, 1).

print_program_with_cost(Program, Cost) :-
    format("  [cost=~w]~n", [Cost]),
    print_program(Program).

print_steps([], _).
print_steps([step(Op, ArgRefs)|Rest], Index) :-
    format("    var(~w) <- ~w(", [Index, Op]),
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
% Each target carries an explicit working base. Structurally matched targets
% across bases share the same delta-to-base profile on the subtrahend
% (e.g., subtract_near_base_b10 has δ_10(subtrahend) ∈ {3, 2} and
% subtract_near_base_b12 has δ_12(subtrahend) ∈ {3, 2}). The synthesizer
% should discover the same canonical program shape modulo the base
% parameter.

% Base 10 make-base subtraction (the original prototype target).
target(subtract_near_base_b10, 10, [
    io([45, 27], 18),     % δ_10(27) = 3
    io([52, 28], 24),     % δ_10(28) = 2
    io([34, 17], 17)      % δ_10(17) = 3
]).

% Base 12 structurally-matched target. Each subtrahend has the same δ_b
% value as the base-10 version (3, 2, 3). The numerals differ; the
% structural relation to the base does not.
target(subtract_near_base_b12, 12, [
    io([60, 33], 27),     % δ_12(33) = 3   (33 mod 12 = 9, next mult = 36)
    io([72, 46], 26),     % δ_12(46) = 2   (46 mod 12 = 10, next mult = 48)
    io([48, 21], 27)      % δ_12(21) = 3   (21 mod 12 = 9, next mult = 24)
]).

% Base 5 structurally-matched target. Subtrahends with δ_5 ∈ {3, 2, 3}.
target(subtract_near_base_b5, 5, [
    io([28, 17], 11),     % δ_5(17) = 3   (17 mod 5 = 2, next mult = 20)
    io([23, 13], 10),     % δ_5(13) = 2   (13 mod 5 = 3, next mult = 15)
    io([16, 12], 4)       % δ_5(12) = 3   (12 mod 5 = 2, next mult = 15)
]).

% Base 7 structurally-matched target. Subtrahends with δ_7 ∈ {3, 2, 3}.
target(subtract_near_base_b7, 7, [
    io([28, 18], 10),     % δ_7(18) = 3   (18 mod 7 = 4, next mult = 21)
    io([33, 19], 14),     % δ_7(19) = 2   (19 mod 7 = 5, next mult = 21)
    io([20, 11], 9)       % δ_7(11) = 3   (11 mod 7 = 4, next mult = 14)
]).

% -----------------------------------------------------------------------------
% Addition make-base targets. The CGI strategy "make ten" generalizes to
% "make next base": chunk the first addend up to the nearest multiple of the
% base, then add the residual portion of the second addend.
%
% Expected program shape (4 steps):
%   D  = delta_to_next_base(input(1))
%   V2 = iter_succ(input(1), D)        % chunk first addend up to base
%   V3 = iter_pred(input(2), D)        % shrink second addend by same amount
%   V4 = iter_succ(V2, V3)             % add the residual
%
% Expected deformation (wrong direction compensation):
%   D  = delta_to_next_base(input(1))
%   V2 = iter_succ(input(1), D)
%   V3 = iter_succ(input(2), D)        % WRONG: should be pred, not succ
%   V4 = iter_succ(V2, V3)
%
% Same δ_b profile on the first addend across bases: (3, 2, 3).

target(add_near_base_b10, 10, [
    io([47, 5], 52),      % δ_10(47) = 3
    io([18, 4], 22),      % δ_10(18) = 2
    io([67, 6], 73)       % δ_10(67) = 3
]).

target(add_near_base_b12, 12, [
    io([57, 5], 62),      % δ_12(57) = 3   (57 mod 12 = 9, next mult = 60)
    io([22, 4], 26),      % δ_12(22) = 2   (22 mod 12 = 10, next mult = 24)
    io([45, 6], 51)       % δ_12(45) = 3   (45 mod 12 = 9, next mult = 48)
]).

target(add_near_base_b5, 5, [
    io([12, 4], 16),      % δ_5(12) = 3    (12 mod 5 = 2, next mult = 15)
    io([13, 4], 17),      % δ_5(13) = 2    (13 mod 5 = 3, next mult = 15)
    io([17, 4], 21)       % δ_5(17) = 3    (17 mod 5 = 2, next mult = 20)
]).

target(add_near_base_b7, 7, [
    io([18, 4], 22),      % δ_7(18) = 3    (18 mod 7 = 4, next mult = 21)
    io([19, 4], 23),      % δ_7(19) = 2    (19 mod 7 = 5, next mult = 21)
    io([11, 5], 16)       % δ_7(11) = 3    (11 mod 7 = 4, next mult = 14)
]).
