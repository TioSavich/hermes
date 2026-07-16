/** <module> Standard 1.CA.3 — Addition within 100 using place value
 *
 * Indiana: 1.CA.3 — "Using number sense and place value strategies,
 *          add within 100, including adding a two-digit number and a
 *          one-digit number, and adding a two-digit number and a
 *          multiple of 10." (E)
 * CCSS:    1.NBT.C.4 — "Add within 100, including adding a two-digit
 *                       number and a one-digit number..."
 *
 * VPV MAPPING:
 *   V  (target vocabulary): multi-digit addition results, "regroup",
 *      "carry", place-value addition language
 *   P  (practices): add ones to ones then combine with tens;
 *      add a multiple of ten by incrementing the tens digit;
 *      regroup when ones exceed 9 (carry)
 *   V' (metavocabulary): "add the ones first", "add the tens",
 *      "do I need to regroup?", "10 ones make a new ten"
 *
 * CONNECTION TO EXISTING AUTOMATA:
 *   This standard is where the existing addition strategy automata
 *   begin to apply:
 *   - sar_add_counting_on.pl  — O(B) counting
 *   - sar_add_cobo.pl         — COBO (count on bases + ones)
 *   - sar_add_rmb.pl          — Round to Make Base
 *   - sar_add_chunking.pl     — Chunking by place value
 *
 *   The progression from 1.CA.1 to 1.CA.3 IS the crisis that
 *   drives strategy elaboration: counting-on 38+55 costs 55
 *   successor operations. Place-value strategies reduce this.
 *
 * BRANDOM CONNECTION: Place-value addition is a paradigm case of
 *   algorithmic elaboration. The practice of decomposing addends
 *   into tens and ones, adding each place separately, and
 *   regrouping TRANSFORMS the addition vocabulary from "count on"
 *   to "add by place." The stronger vocabulary (place-value
 *   addition) makes visible the structure that counting hides.
 *
 * BOUNDARIES:
 *   - This is the closed-world finite 1.CA.3 place-value addition case for
 *     supplied grounded recollections. It proves addition by decomposing both
 *     addends into tens and ones, adding like places, and either composing
 *     directly or regrouping ten ones into one additional ten.
 *   - The Indiana classroom surface is addition within 100. The checker can
 *     compute finite recollection sums outside that range, but witnesses mark
 *     whether the result is inside the 1.CA.3 bound.
 *   - Strategy cost comparisons with counting-on automata are conceptual
 *     dependencies here; this module records the place-value proof and does
 *     not execute those automata.
 */

:- module(standard_1_ca_3, [
    add_by_place_value/3,    % +A, +B, -Sum
    add_by_place_value_witness/4, % +A, +B, -Sum, -Witness
    add_two_digit_one_digit/3, % +TwoDigit, +OneDigit, -Sum
    add_two_digit_one_digit_witness/4, % +TwoDigit, +OneDigit, -Sum, -Witness
    add_two_digit_mult_ten/3,  % +TwoDigit, +MultTen, -Sum
    add_two_digit_mult_ten_witness/4 % +TwoDigit, +MultTen, -Sum, -Witness
]).

:- use_module(formalization(grounded_arithmetic), [
    zero/1,
    equal_to/2,
    smaller_than/2,
    add_grounded/3,
    subtract_grounded/3,
    integer_to_recollection/2,
    recollection_to_integer/2,
    incur_cost/1
]).

:- use_module(standard_1_ns_2, [
    decompose_two_digit_witness/4,
    compose_two_digit_witness/4
]).

% ============================================================
% General place-value addition
% ============================================================

%!  add_by_place_value(+A, +B, -Sum) is det.
%
%   Add two numbers using place-value decomposition:
%   1. Decompose both into tens and ones
%   2. Add ones to ones
%   3. Add tens to tens
%   4. Handle regrouping if ones sum ≥ 10
%   5. Compose the result
%
%   This is the general strategy that subsumes the two
%   special cases below.

add_by_place_value(A, B, Sum) :-
    add_by_place_value_witness(A, B, Sum, _).

%!  add_by_place_value_witness(+A, +B, -Sum, -Witness) is det.
%
%   Witness-bearing place-value addition. The proof exposes the 1.NS.2
%   decomposition of both addends, the place-wise sums, and the regrouping
%   branch used before recomposition.

add_by_place_value_witness(A, B, Sum, Witness) :-
    incur_cost(inference),
    decompose_two_digit_witness(A, TensA, OnesA, DecompositionA),
    decompose_two_digit_witness(B, TensB, OnesB, DecompositionB),
    add_grounded(OnesA, OnesB, OnesSum),
    add_grounded(TensA, TensB, TensSum),
    integer_to_recollection(10, TenRec),
    addition_regroup_case(OnesSum,
                          TensSum,
                          TenRec,
                          FinalTens,
                          FinalOnes,
                          RegroupCase,
                          RegroupEvidence),
    compose_two_digit_witness(FinalTens, FinalOnes, Sum, CompositionWitness),
    addition_witness(add_by_place_value/3,
                     A,
                     B,
                     Sum,
                     TensA,
                     OnesA,
                     TensB,
                     OnesB,
                     OnesSum,
                     TensSum,
                     FinalTens,
                     FinalOnes,
                     RegroupCase,
                     RegroupEvidence,
                     DecompositionA,
                     DecompositionB,
                     CompositionWitness,
                     Witness).


% ============================================================
% Special case: two-digit + one-digit
% ============================================================

%!  add_two_digit_one_digit(+TwoDigit, +OneDigit, -Sum) is det.
%
%   Add a two-digit number and a one-digit number.
%   Only the ones place is affected (with possible regrouping).

add_two_digit_one_digit(TwoDigit, OneDigit, Sum) :-
    add_two_digit_one_digit_witness(TwoDigit, OneDigit, Sum, _).

%!  add_two_digit_one_digit_witness(+TwoDigit, +OneDigit, -Sum, -Witness) is det.
%
%   Wrapper witness for the 1.CA.3 two-digit plus one-digit public surface.
%   The base proof is the same place-value addition witness, with this public
%   source predicate recorded for callers.

add_two_digit_one_digit_witness(TwoDigit, OneDigit, Sum, Witness) :-
    add_by_place_value_witness(TwoDigit, OneDigit, Sum, BaseWitness),
    wrapper_witness(add_two_digit_one_digit/3,
                    two_digit_plus_one_digit,
                    TwoDigit,
                    OneDigit,
                    Sum,
                    BaseWitness,
                    Witness).


% ============================================================
% Special case: two-digit + multiple of ten
% ============================================================

%!  add_two_digit_mult_ten(+TwoDigit, +MultTen, -Sum) is det.
%
%   Add a two-digit number and a multiple of 10.
%   Only the tens place is affected (no regrouping possible
%   within two-digit range).

add_two_digit_mult_ten(TwoDigit, MultTen, Sum) :-
    add_two_digit_mult_ten_witness(TwoDigit, MultTen, Sum, _).

%!  add_two_digit_mult_ten_witness(+TwoDigit, +MultTen, -Sum, -Witness) is det.
%
%   Wrapper witness for the 1.CA.3 two-digit plus multiple-of-ten public
%   surface. The base proof is the same place-value addition witness.

add_two_digit_mult_ten_witness(TwoDigit, MultTen, Sum, Witness) :-
    add_by_place_value_witness(TwoDigit, MultTen, Sum, BaseWitness),
    wrapper_witness(add_two_digit_mult_ten/3,
                    two_digit_plus_multiple_of_ten,
                    TwoDigit,
                    MultTen,
                    Sum,
                    BaseWitness,
                    Witness).

addition_regroup_case(OnesSum,
                      TensSum,
                      TenRec,
                      TensSum,
                      OnesSum,
                      no_regroup,
                      _{ kind: standard_1_ca_3_no_regroup,
                         relation: smaller_than(OnesSum, TenRec),
                         reason: ones_sum_is_less_than_one_ten }) :-
    smaller_than(OnesSum, TenRec), !.
addition_regroup_case(OnesSum,
                      TensSum,
                      TenRec,
                      NewTens,
                      NewOnes,
                      regroup,
                      RegroupEvidence) :-
    subtract_grounded(OnesSum, TenRec, NewOnes),
    integer_to_recollection(1, One),
    add_grounded(TensSum, One, NewTens),
    recollection_to_integer(OnesSum, OnesSumCount),
    recollection_to_integer(TensSum, TensSumCount),
    recollection_to_integer(NewOnes, NewOnesCount),
    recollection_to_integer(NewTens, NewTensCount),
    RegroupEvidence = _{ kind: standard_1_ca_3_regroup,
                         relation: not_smaller_than(OnesSum, TenRec),
                         ones_sum_count: OnesSumCount,
                         tens_sum_count: TensSumCount,
                         carry_unit_count: 1,
                         new_ones: NewOnes,
                         new_ones_count: NewOnesCount,
                         new_tens: NewTens,
                         new_tens_count: NewTensCount,
                         derivation: trade_ten_ones_for_one_ten }.

addition_witness(Predicate,
                 A,
                 B,
                 Sum,
                 TensA,
                 OnesA,
                 TensB,
                 OnesB,
                 OnesSum,
                 TensSum,
                 FinalTens,
                 FinalOnes,
                 RegroupCase,
                 RegroupEvidence,
                 DecompositionA,
                 DecompositionB,
                 CompositionWitness,
                 _{ kind: standard_1_ca_3_place_value_addition,
                    scope: closed_world_finite_standard_1_ca_3_addition_within_100,
                    standard: in_1_ca_3,
                    source_predicate: Predicate,
                    addends: _{a: A, b: B, a_count: ACount, b_count: BCount},
                    sum: Sum,
                    sum_count: SumCount,
                    tens_a: TensA,
                    ones_a: OnesA,
                    tens_b: TensB,
                    ones_b: OnesB,
                    addend_place_counts: _{a: _{tens: TensACount, ones: OnesACount},
                                            b: _{tens: TensBCount, ones: OnesBCount}},
                    ones_sum: OnesSum,
                    ones_sum_count: OnesSumCount,
                    tens_sum: TensSum,
                    tens_sum_count: TensSumCount,
                    final_tens: FinalTens,
                    final_tens_count: FinalTensCount,
                    final_ones: FinalOnes,
                    final_ones_count: FinalOnesCount,
                    regroup_case: RegroupCase,
                    regroup: RegroupEvidence,
                    derivation: decompose_add_places_then_regroup_if_needed,
                    projection: place_value_addition,
                    boundary: supplied_grounded_recollections_with_finite_place_value_decomposition,
                    bound_status: BoundStatus,
                    decomposition_a: DecompositionA,
                    decomposition_b: DecompositionB,
                    composition_witness: CompositionWitness }) :-
    recollection_to_integer(A, ACount),
    recollection_to_integer(B, BCount),
    recollection_to_integer(Sum, SumCount),
    recollection_to_integer(TensA, TensACount),
    recollection_to_integer(OnesA, OnesACount),
    recollection_to_integer(TensB, TensBCount),
    recollection_to_integer(OnesB, OnesBCount),
    recollection_to_integer(OnesSum, OnesSumCount),
    recollection_to_integer(TensSum, TensSumCount),
    recollection_to_integer(FinalTens, FinalTensCount),
    recollection_to_integer(FinalOnes, FinalOnesCount),
    addition_bound_status(ACount, BCount, SumCount, BoundStatus).

wrapper_witness(Predicate,
                Surface,
                A,
                B,
                Sum,
                BaseWitness,
                _{ kind: standard_1_ca_3_public_surface,
                   scope: closed_world_finite_standard_1_ca_3_addition_within_100,
                   standard: in_1_ca_3,
                   source_predicate: Predicate,
                   surface: Surface,
                   addends: _{a: A, b: B, a_count: ACount, b_count: BCount},
                   sum: Sum,
                   sum_count: SumCount,
                   derivation: delegate_to_place_value_addition,
                   boundary: supplied_grounded_recollections_with_finite_place_value_decomposition,
                   bound_status: BoundStatus,
                   base_witness: BaseWitness }) :-
    recollection_to_integer(A, ACount),
    recollection_to_integer(B, BCount),
    recollection_to_integer(Sum, SumCount),
    addition_bound_status(ACount, BCount, SumCount, BoundStatus).

addition_bound_status(A, B, Sum, within_indiana_1_ca_3_bound) :-
    A >= 0,
    B >= 0,
    Sum =< 100,
    !.
addition_bound_status(A, B, Sum, outside_indiana_1_ca_3_bound(A, B, Sum)).
