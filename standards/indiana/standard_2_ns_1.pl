/** <module> Standard 2.NS.1 — Count by 1s, 2s, 5s, 10s, 100s to 1000
 *
 * Indiana: 2.NS.1 — "Count by ones, twos, fives, tens, and hundreds
 *          up to at least 1,000 from any given number." (E)
 * CCSS:    2.NBT.A.2 — "Count within 1000; skip-count by 5s, 10s,
 *                       and 100s."
 *
 * Extends 1.NS.1 with counting by 2s and 100s.
 * All skip-counting predicates reuse the same add-and-iterate pattern.
 */

:- module(standard_2_ns_1, [
    count_by_twos/3,       % +From, +To, -Trace
    count_by_twos_witness/4, % +From, +To, -Trace, -Witness
    count_by_hundreds/3,   % +From, +To, -Trace
    count_by_hundreds_witness/4 % +From, +To, -Trace, -Witness
]).

:- use_module(formalization(grounded_arithmetic), [
    equal_to/2,
    smaller_than/2,
    add_grounded/3,
    integer_to_recollection/2,
    recollection_to_integer/2,
    incur_cost/1
]).

%!  count_by_twos(+From, +To, -Trace) is semidet.
count_by_twos(From, To, Trace) :-
    count_by_twos_witness(From, To, Trace, _).

%!  count_by_twos_witness(+From, +To, -Trace, -Witness) is semidet.
%
%   Witness-bearing version of count_by_twos/3. This is the closed-world
%   finite case for exact reachability by repeated two-step grounded addition
%   over supplied recollection inputs.
count_by_twos_witness(From, To, Trace, Witness) :-
    incur_cost(inference),
    integer_to_recollection(2, Two),
    skip_count_(From, To, Two, [state(From, start)], RevTrace),
    reverse(RevTrace, Trace),
    skip_count_witness(count_by_twos,
                       count_by_twos/3,
                       From,
                       To,
                       Two,
                       2,
                       Trace,
                       Witness).

%!  count_by_hundreds(+From, +To, -Trace) is semidet.
count_by_hundreds(From, To, Trace) :-
    count_by_hundreds_witness(From, To, Trace, _).

%!  count_by_hundreds_witness(+From, +To, -Trace, -Witness) is semidet.
%
%   Witness-bearing version of count_by_hundreds/3. This is the closed-world
%   finite case for exact reachability by repeated hundred-step grounded
%   addition over supplied recollection inputs.
count_by_hundreds_witness(From, To, Trace, Witness) :-
    incur_cost(inference),
    integer_to_recollection(100, Hundred),
    skip_count_(From, To, Hundred, [state(From, start)], RevTrace),
    reverse(RevTrace, Trace),
    skip_count_witness(count_by_hundreds,
                       count_by_hundreds/3,
                       From,
                       To,
                       Hundred,
                       100,
                       Trace,
                       Witness).

%% Generic skip-counting engine
skip_count_(Current, Target, _Step, Acc, Acc) :-
    equal_to(Current, Target), !.
skip_count_(Current, Target, Step, Acc, Trace) :-
    smaller_than(Current, Target),
    add_grounded(Current, Step, Next),
    skip_count_(Next, Target, Step, [state(Next, skip_step)|Acc], Trace).

skip_count_witness(Operation,
                   Predicate,
                   From,
                   To,
                   Step,
                   StepValue,
                   Trace,
                   _{ kind: standard_2_ns_1_skip_count_trace,
                      scope: closed_world_finite_standard_2_ns_1_skip_counting,
                      standard: in_2_ns_1,
                      operation: Operation,
                      source_predicate: Predicate,
                      from: From,
                      to: To,
                      from_count: FromCount,
                      to_count: ToCount,
                      step: Step,
                      step_value: StepValue,
                      projection: repeated_grounded_addition,
                      derivation: exact_skip_count_reachability,
                      boundary: supplied_recollection_inputs_only,
                      trace: Trace,
                      trace_length: TraceLength,
                      state_counts: StateCounts }) :-
    recollection_to_integer(From, FromCount),
    recollection_to_integer(To, ToCount),
    length(Trace, TraceLength),
    maplist(trace_state_count, Trace, StateCounts).

trace_state_count(state(Recollection, Transition),
                  state_count(Count, Transition)) :-
    recollection_to_integer(Recollection, Count).
