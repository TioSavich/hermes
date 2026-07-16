/** <module> Jason's Partitive Fractional Schemes
 *
 * This module implements a computational model of Jason's partitive
 * fractional schemes, as described in cognitive science literature on
 * mathematical development. It models how a student might conceptualize
 * and operate on fractions by partitioning, disembedding, and iterating units.
 *
 * The core data structure is a `unit(Value, History)` term, which tracks
 * both a rational numerical value and its operational history.
 *
 * The module defines two main strategic state machines:
 * 1.  **Partitive Fractional Scheme (PFS)**: Models the process of finding
 *     a simple fraction (e.g., 3/7) of a whole.
 * 2.  **Fractional Composition Scheme (FCS)**: Models the more complex process
 *     of finding a fraction of a fraction (e.g., 3/4 of 1/4), which involves
 *     a "metamorphic accommodation" where the result of one operation becomes
 *     the input for the next.
 *
 * The primary entry point for demonstration is `run_tests/0`.
 *
 * 
 * 
 */
:- module(jason_fsm, [run_tests/0, debug_run_fcs/0, run_pfs/5, run_fcs/5]).
% library(rat) is optional: rational (rdiv) arithmetic is built into SWI-Prolog
% without it. Load it when present; stay silent when absent so the warning does
% not read as a missing dependency.
:- (   catch(use_module(library(rat)), _, true) ).
:- use_module(formalization(grounded_arithmetic), [integer_to_recollection/2,
                                    recollection_to_integer/2,
                                    multiply_grounded/3, divide_grounded/3]).
:- use_module(formalization(grounded_utils), [is_positive_grounded/1]).

% =============================================================================
% I. Cognitive Material Representation (ContinuousUnit)
% =============================================================================
%
% We represent a ContinuousUnit as a compound term: unit(Value, History).
% - Value: A rational number (e.g., 1, 3 rdiv 7).
% - History: A string representing the operational history.

% =============================================================================
% II. Iterative Core: Explicitly Nested Number Sequence (ENS) Operations
% =============================================================================

% ens_partition(+UnitIn, +N, -PartitionedWhole)
% Divides a continuous unit into N equal parts.
ens_partition(unit(Value, History), N, PartitionedWhole) :-
    integer_to_recollection(N, RecN),
    is_positive_grounded(RecN),
    integer_to_recollection(Value, RecValue),
    divide_grounded(RecValue, RecN, RecNewValue),
    recollection_to_integer(RecNewValue, NewValue),
    format(string(NewHistory), '1/~w part of (~w)', [N, History]),
    length(PartitionedWhole, N),
    maplist(=(unit(NewValue, NewHistory)), PartitionedWhole).

% ens_disembed(+PartitionedWhole, -UnitFraction)
% Isolates a single unit part from the partitioned whole.
ens_disembed([UnitFraction | _], UnitFraction) :- !.
ens_disembed([], _) :- throw(error(cannot_disembed_from_empty_list, _)).

% ens_iterate(+UnitIn, +M, -ResultUnit)
% Repeats a unit M times.
ens_iterate(unit(Value, History), M, unit(NewValue, NewHistory)) :-
    integer_to_recollection(Value, RecValue),
    integer_to_recollection(M, RecM),
    multiply_grounded(RecValue, RecM, RecNewValue),
    recollection_to_integer(RecNewValue, NewValue),
    format(string(NewHistory), '~w iterations of [~w]', [M, History]).

% =============================================================================
% III. Strategic Shell: The Partitive Fractional Scheme (PFS)
% =============================================================================

%!      run_pfs(+Whole:unit, +Numerator:integer, +Denominator:integer, -Result:unit, -Trace:list) is det.
%
%       Executes the Partitive Fractional Scheme to calculate `Num/Den` of `Whole`.
%
%       This state machine models the cognitive process of:
%       1. Partitioning the `Whole` into `Denominator` equal parts.
%       2. Disembedding one of those parts (the unit fraction).
%       3. Iterating the unit fraction `Numerator` times.
%
%       @param Whole The initial `unit/2` term to be operated on.
%       @param Numerator The numerator of the fraction.
%       @param Denominator The denominator of the fraction.
%       @param Result The final `unit/2` term representing the result.
%       @param Trace A list of strings describing the cognitive steps taken.
run_pfs(Whole, Num, Den, Result, Trace) :-
    % Initialize V (variables) in a dict
    V0 = v{whole: Whole, n: Den, m: Num},
    ( Whole = unit(WholeVal, _) -> true ; WholeVal = Whole ),
    format(string(Log0), 'PFS Initialized: Find ~w/~w of ~w', [Num, Den, WholeVal]),

    % Start the state machine loop with an accumulator for logs
    pfs_loop(q_start, V0, Result, [Log0], Trace).

% pfs_loop/5 uses Acc as accumulator and Trace as final output
pfs_loop(q_accept, V, Result, Acc, TraceOut) :-
    ( get_dict(result, V, Result) -> true ; Result = V ),
    reverse(Acc, RevAcc),
    append(RevAcc, ["PFS Complete."], TraceOut).
pfs_loop(CurrentState, V_in, Result, Acc, TraceOut) :-
    pfs_transition(CurrentState, V_in, NextState, V_out, Log),
    pfs_loop(NextState, V_out, Result, [Log|Acc], TraceOut).

% pfs_transition(+State, +V_in, -NextState, -V_out, -Log)
% Defines the state transitions (delta function)
pfs_transition(q_start, V, q_partition, V, "Transition to partition state") :- !.

pfs_transition(q_partition, V_in, q_disembed, V_out, Log) :-
    format(string(Log), '[State: q_partition] Action: Partitioning Whole into ~w parts.', [V_in.n]),
    ens_partition(V_in.whole, V_in.n, Partitioned),
    V_out = V_in.put(partitioned_whole, Partitioned),
    !.

pfs_transition(q_disembed, V_in, q_iterate, V_out, Log) :-
    ens_disembed(V_in.partitioned_whole, UnitFraction),
    ( UnitFraction = unit(UVal, _) -> true ; UVal = UnitFraction ),
    format(string(Log), '[State: q_disembed] Action: Disembedded Unit Fraction (~w).', [UVal]),
    V_out = V_in.put(unit_fraction, UnitFraction),
    !.

pfs_transition(q_iterate, V_in, q_accept, V_out, Log) :-
    format(string(Log), '[State: q_iterate] Action: Iterating Unit Fraction ~w times.', [V_in.m]),
    ens_iterate(V_in.unit_fraction, V_in.m, Result),
    V_out = V_in.put(result, Result),
    !.

% =============================================================================
% IV. Strategic Shell: The Fractional Composition Scheme (FCS)
% =============================================================================

%!      run_fcs(+Whole:unit, +OuterFrac:pair, +InnerFrac:pair, -Result:unit, -Trace:list) is det.
%
%       Executes the Fractional Composition Scheme to calculate a fraction of a fraction.
%       It solves `(A/B) of (C/D)` of `Whole`.
%
%       This state machine models a more advanced cognitive process involving
%       "metamorphic accommodation," where the result of one fractional operation
%       becomes the new "whole" for the next fractional operation. It achieves
%       this by calling `run_pfs/5` as a subroutine.
%
%       @param Whole The initial `unit/2` term.
%       @param OuterFrac A pair `A-B` for the outer fraction.
%       @param InnerFrac A pair `C-D` for the inner fraction.
%       @param Result The final `unit/2` term.
%       @param Trace A nested list describing the cognitive steps, including the
%       trace of the inner `run_pfs/5` calls.
run_fcs(Whole, A-B, C-D, Result, Trace) :-
    % Compose two PFS computations: inner then outer.
    format(string(Log0), 'FCS Initialized: Find ~w/~w of ~w/~w of whole', [A,B,C,D]),
    (   catch(run_pfs(Whole, C, D, IntermediateResult, InnerTrace), E, (format('Error computing inner PFS: ~w~n',[E]), fail))
    ->  true
    ;   fail
    ),
    format(string(AccLog), '-> Intermediate Result: ~w', [IntermediateResult]),
    (   catch(run_pfs(IntermediateResult, A, B, FinalResult, OuterTrace), E2, (format('Error computing outer PFS: ~w~n',[E2]), fail))
    ->  true
    ;   fail
    ),
    Result = FinalResult,
    Trace = [log(q_start, Log0, []), log(q_inner_PFS, AccLog, InnerTrace), log(q_accommodate, '[accommodate]', []), log(q_outer_PFS, 'outer computation', OuterTrace), log(q_accept, 'FCS Complete.', [])].

% =============================================================================
% V. Demonstration and Testing
% =============================================================================

%!      run_tests is det.
%
%       The main demonstration predicate for this module.
%
%       It runs two tests:
%       1. A test of the basic Partitive Fractional Scheme (PFS).
%       2. A test of the more complex Fractional Composition Scheme (FCS),
%          which demonstrates recursive partitioning.
%
%       It prints detailed execution traces for both tests to the console.
run_tests :-
    writeln('=== JASON AUTOMATON MODEL TESTING ==='),

    % Define the initial Whole
    TheWhole = unit(1, "Reference Unit"),

    % --- Test 1: Partitive Fractional Scheme (PFS) ---
    writeln('\n' + '============================================================'),
    writeln('TEST 1: Construct 3/7 of the Whole (PFS)'),
    writeln('============================================================'),
    run_pfs(TheWhole, 3, 7, ResultPFS, TracePFS),
    writeln('\nExecution Trace (Cognitive Choreography):'),
    print_pfs_trace(TracePFS),
    format('~nRESULT (PFS): ~w~n', [ResultPFS]),

    % --- Test 2: Fractional Composition Scheme (FCS) ---
    writeln('\n' + '============================================================'),
    writeln('TEST 2: Construct 3/4 of 1/4 of the Whole (FCS)'),
    writeln('Modeling Metamorphic Accommodation (Recursive Partitioning)'),
    writeln('============================================================'),
    run_fcs(TheWhole, 3-4, 1-4, ResultFCS, TraceFCS),
    writeln('\nExecution Trace (Cognitive Choreography):'),
    print_fcs_trace(TraceFCS, ""),
    format('~nRESULT (FCS): ~w~n', [ResultFCS]).

% Helper to print the flat trace from PFS
print_pfs_trace(Trace) :-
    forall(member(Line, Trace), writeln(Line)).

% Helper to print the potentially nested trace from FCS
print_fcs_trace([], _).
print_fcs_trace([log(State, Action, NestedTrace)|Rest], Indent) :-
    format('~wState: ~w, Action: ~w~n', [Indent, State, Action]),
    ( NestedTrace \= [] ->
        format('~w  [Begin Nested PFS Execution]~n', [Indent]),
        atom_concat(Indent, '    ', NewIndent),
        % Since PFS trace is flat list of strings
        forall(member(Line, NestedTrace), format('~w~w~n', [NewIndent, Line])),
        format('~w  [End Nested PFS Execution]~n', [Indent])
    ; true
    ),
    print_fcs_trace(Rest, Indent).

%! debug_run_fcs is det.
%  Debug helper: run a representative FCS calculation and print canonical result and trace.
debug_run_fcs :-
    TheWhole = unit(1, "Reference Unit"),
    V0 = v{whole: TheWhole, a:3, b:4, c:1, d:4},
    format('Debug: V0=~w~n', [V0]),
    ( fcs_transition(q_start, V0, NS1, _V1, Log1, NT1) -> format('q_start -> ~w ; Log=~w NT=~w~n', [NS1, Log1, NT1]) ; writeln('q_start failed') ),
    ( fcs_transition(q_inner_PFS, V0, NS2, V2, Log2, NT2) -> (format('q_inner_PFS -> ~w ; Log=~w NT=~w~n', [NS2, Log2, NT2]), ( get_dict(intermediate_result, V2, IR) -> format('V2.intermediate_result=~w~n',[IR]) ; writeln('V2 has no intermediate_result') )) ; writeln('q_inner_PFS failed') ),
    ( fcs_transition(q_accommodate, V0, NS3, _V3, Log3, NT3) -> format('q_accommodate -> ~w ; Log=~w NT=~w~n', [NS3, Log3, NT3]) ; writeln('q_accommodate failed') ),
    ( fcs_transition(q_outer_PFS, V0, NS4, V4, Log4, NT4) -> (format('q_outer_PFS -> ~w ; Log=~w NT=~w~n', [NS4, Log4, NT4]), ( get_dict(final_result, V4, FR) -> format('V4.final_result=~w~n',[FR]) ; writeln('V4 has no final_result') )) ; writeln('q_outer_PFS failed') ).
