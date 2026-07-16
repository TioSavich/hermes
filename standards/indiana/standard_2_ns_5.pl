/** <module> Standard 2.NS.5 — Compare three-digit numbers
 *
 * Indiana: 2.NS.5 — "Use place value understanding to compare two
 *          three-digit numbers based on meanings of the hundreds,
 *          tens, and ones digits, using >, =, and < symbols." (E)
 * CCSS:    2.NBT.A.4
 *
 * Extends K.NS.5-6 comparison to three-digit numbers using
 * place-value decomposition rather than counting.
 */

:- module(standard_2_ns_5, [
    compare_by_place_value/3,         % +A, +B, -Result
    compare_by_place_value_witness/4  % +A, +B, -Result, -Witness
]).

:- use_module(formalization(grounded_arithmetic), [
    equal_to/2,
    smaller_than/2,
    greater_than/2,
    recollection_to_integer/2,
    incur_cost/1
]).

:- use_module(standard_2_ns_2_4, [
    decompose_three_digit/4
]).

%!  compare_by_place_value(+A, +B, -Result) is det.
%
%   Compare two numbers by decomposing into hundreds, tens, ones
%   and comparing place by place (most significant first).
%   Result is one of: greater_than, less_than, equal_to.

compare_by_place_value(A, B, Result) :-
    compare_by_place_value_witness(A, B, Result, _).

%!  compare_by_place_value_witness(+A, +B, -Result, -Witness) is det.
%
%   Witness-bearing version of compare_by_place_value/3. This is the
%   closed-world finite case for supplied grounded recollections: both numbers
%   are decomposed into hundreds, tens, and ones, then compared from most
%   significant place to least significant place.

compare_by_place_value_witness(A, B, Result, Witness) :-
    incur_cost(inference),
    decompose_three_digit(A, HA, TA, OA),
    decompose_three_digit(B, HB, TB, OB),
    compare_places_witness(HA, HB, TA, TB, OA, OB, Result, PlaceWitness),
    comparison_witness(A, B, Result, HA, HB, TA, TB, OA, OB, PlaceWitness, Witness).

compare_places_witness(HA, HB, _TA, _TB, _OA, _OB, greater_than,
                       place_witness(hundreds, greater_than, HA, HB)) :-
    greater_than(HA, HB), !.
compare_places_witness(HA, HB, _TA, _TB, _OA, _OB, less_than,
                       place_witness(hundreds, less_than, HA, HB)) :-
    smaller_than(HA, HB), !.
compare_places_witness(HA, HB, TA, TB, _OA, _OB, greater_than,
                       place_witness(tens, greater_than, TA, TB)) :-
    equal_to(HA, HB), greater_than(TA, TB), !.
compare_places_witness(HA, HB, TA, TB, _OA, _OB, less_than,
                       place_witness(tens, less_than, TA, TB)) :-
    equal_to(HA, HB), smaller_than(TA, TB), !.
compare_places_witness(HA, HB, TA, TB, OA, OB, greater_than,
                       place_witness(ones, greater_than, OA, OB)) :-
    equal_to(HA, HB), equal_to(TA, TB), greater_than(OA, OB), !.
compare_places_witness(HA, HB, TA, TB, OA, OB, less_than,
                       place_witness(ones, less_than, OA, OB)) :-
    equal_to(HA, HB), equal_to(TA, TB), smaller_than(OA, OB), !.
compare_places_witness(HA, HB, TA, TB, OA, OB, equal_to,
                       place_witness(all_places, equal_to,
                                     [HA, TA, OA],
                                     [HB, TB, OB])) :-
    equal_to(HA, HB), equal_to(TA, TB), equal_to(OA, OB).

comparison_witness(A,
                   B,
                   Result,
                   HA,
                   HB,
                   TA,
                   TB,
                   OA,
                   OB,
                   PlaceWitness,
                   _{ kind: standard_2_ns_5_place_value_comparison,
                      scope: closed_world_finite_standard_2_ns_5_place_value,
                      standard: in_2_ns_5,
                      source_predicate: compare_by_place_value/3,
                      left: A,
                      right: B,
                      left_count: LeftCount,
                      right_count: RightCount,
                      left_places: _{hundreds: HAI, tens: TAI, ones: OAI},
                      right_places: _{hundreds: HBI, tens: TBI, ones: OBI},
                      result: Result,
                      deciding_place_witness: PlaceSafe,
                      projection: hundreds_tens_ones_lexicographic_comparison,
                      derivation: decompose_then_compare_most_significant_place,
                      boundary: supplied_grounded_recollections_only }) :-
    recollection_to_integer(A, LeftCount),
    recollection_to_integer(B, RightCount),
    recollection_to_integer(HA, HAI),
    recollection_to_integer(HB, HBI),
    recollection_to_integer(TA, TAI),
    recollection_to_integer(TB, TBI),
    recollection_to_integer(OA, OAI),
    recollection_to_integer(OB, OBI),
    place_witness_safe(PlaceWitness, PlaceSafe).

place_witness_safe(place_witness(Place, Relation, Left, Right),
                   _{place: Place,
                     relation: Relation,
                     left: LeftCount,
                     right: RightCount}) :-
    recollection_to_integer(Left, LeftCount),
    recollection_to_integer(Right, RightCount).
place_witness_safe(place_witness(all_places, equal_to, LeftPlaces, RightPlaces),
                   _{place: all_places,
                     relation: equal_to,
                     left: LeftCounts,
                     right: RightCounts}) :-
    maplist(recollection_to_integer, LeftPlaces, LeftCounts),
    maplist(recollection_to_integer, RightPlaces, RightCounts).
