/** <module> Standard 2.NS.3 — Odd and even
 *
 * Indiana: 2.NS.3 — "Determine whether a group of objects (up to 20)
 *          has an odd or even number of members."
 * CCSS:    2.OA.C.3
 *
 * BRANDOM CONNECTION: Odd/even is the first classification that
 *   partitions ALL numbers into two exhaustive, exclusive categories.
 *   It introduces a new incompatibility: a number is odd XOR even,
 *   never both. This is a structural property discovered through
 *   the pairing practice (try to pair objects; leftover = odd).
 */

:- module(standard_2_ns_3, [
    is_even/1,         % +Number
    is_odd/1,          % +Number
    classify_parity/2, % +Number, -Result
    parity_witness/3   % +Number, ?Result, -Witness
]).

:- use_module(formalization(grounded_arithmetic), [
    zero/1,
    equal_to/2,
    predecessor/2,
    recollection_to_integer/2,
    incur_cost/1
]).

%!  is_even(+Number) is semidet.
%   True if Number (recollection) has an even number of tallies.
%   Determined by removing tallies two at a time.
is_even(Number) :-
    incur_cost(inference),
    parity_witness(Number, even, _).

%!  is_odd(+Number) is semidet.
is_odd(Number) :-
    incur_cost(inference),
    parity_witness(Number, odd, _).

%!  classify_parity(+Number, -Result) is det.
classify_parity(Number, Result) :-
    parity_witness(Number, Result, _).

%!  parity_witness(+Number, ?Result, -Witness) is semidet.
%
%   Prove the parity classification by repeatedly removing two tallies until
%   the remaining recollection is zero or one. This is the closed-world finite
%   case for supplied grounded recollections; the Indiana standard names
%   groups up to 20, while the automaton can still execute on any finite
%   recollection provided by grounded_arithmetic.
parity_witness(Number, Result,
               WitnessDict53) :-
    witness_dict:witness_dict(standard_2_ns_3_parity, closed_world_finite_pairing_over_supplied_recollection,
                              _{standard: in_2_ns_3,
                  source_predicate: classify_parity/2,
                  number: Number,
                  count: Count,
                  result: Result,
                  incompatible_with: Incompatible,
                  derivation: remove_two_tallies_until_remainder,
                  trace: Trace,
                  trace_length: TraceLength,
                  standard_bound: up_to_20_objects,
                  bound_status: BoundStatus }, WitnessDict53),
    parity_trace(Number, Result, Trace),
    recollection_to_integer(Number, Count),
    length(Trace, TraceLength),
    opposite_parity(Result, Incompatible),
    bound_status(Count, BoundStatus).

parity_trace(Number, Result, Trace) :-
    parity_trace_(Number, [], RevTrace, Result),
    reverse(RevTrace, Trace).

%% Remove two at a time; if zero remains, even; if one remains, odd.
parity_trace_(N, Acc, [remainder(0, even)|Acc], even) :-
    zero(Z), equal_to(N, Z), !.
parity_trace_(N, Acc, [remainder(1, odd)|Acc], odd) :-
    predecessor(N, N1),
    zero(Z), equal_to(N1, Z), !.
parity_trace_(N, Acc, Trace, Result) :-
    recollection_to_integer(N, Before),
    predecessor(N, N1),
    predecessor(N1, N2),
    recollection_to_integer(N2, After),
    parity_trace_(N2, [paired_two(Before, After)|Acc], Trace, Result).

opposite_parity(even, odd).
opposite_parity(odd, even).

bound_status(Count, within_indiana_2_ns_3_bound) :-
    Count =< 20, !.
bound_status(Count, outside_indiana_2_ns_3_bound(Count)).
