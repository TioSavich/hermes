/** <module> Standard K.NS.7 — Place value: ten as a group of ten ones
 *
 * Indiana: K.NS.7 — "Define and model a 'ten' as a group of ten ones.
 *          Model equivalent forms of whole numbers from 10 to 20 as
 *          groups of tens and ones using objects and drawings." (E)
 * CCSS:    K.NBT.A.1 — "Compose and decompose numbers from 11 to 19
 *                       into ten ones and some further ones."
 *
 * VPV MAPPING:
 *   V  (target vocabulary): "ten", "ones", "a ten and ___ ones",
 *      place-value decomposition language (e.g., "14 is one ten and
 *      four ones")
 *   P  (practices): grouping ten objects into a unit ("making a ten");
 *      decomposing a teen number into a ten-group and leftover ones;
 *      composing a teen number from a ten-group and ones
 *   V' (metavocabulary): "group them by tens", "how many tens?",
 *      "how many ones left over?", "make a ten"
 *
 * LEARNING COMPONENTS: No direct LearningCommons decomposition for
 *   K.NBT.A.1. The standard itself is the component.
 *
 * BRANDOM CONNECTION: Place value is the first genuine algorithmic
 *   elaboration beyond counting. The vocabulary "one ten and four
 *   ones" is STRONGER than "fourteen" — it makes explicit the
 *   internal structure. The practice of grouping (P) transforms
 *   the flat counting vocabulary into the structured place-value
 *   vocabulary. This is PP-sufficiency: mastering the grouping
 *   practice deploys the place-value vocabulary.
 *
 *   This connects to the DPDA carry mechanism in counting2.pl:
 *   when the ones place overflows (9→10), a carry event produces
 *   a new place. K.NS.7 is where the learner discovers that this
 *   carry event has MEANING — it creates a "ten."
 *
 * BOUNDARIES:
 *   - This is the closed-world finite one-ten-group case. It models the
 *     kindergarten place-value surface where a supplied finite recollection is
 *     checked against a single group of ten ones plus leftover ones.
 *   - "Grouping" is represented by grounded subtraction of ten from a finite
 *     recollection, not by physical manipulation of objects or drawings.
 *   - The Indiana K.NS.7 classroom range is 10 through 20. Compatibility
 *     predicates still preserve existing under-ten behavior as zero tens and
 *     all ones; witnesses mark whether the supplied value is inside the
 *     K.NS.7 range.
 *   - The connection to `strategies/math/counting2.pl` carry events is a
 *     documented conceptual dependency. This read-only checker records the
 *     place-value proof; it does not execute the reflection mechanism.
 */

:- module(standard_k_ns_7, [
    make_ten/2,            % +Ones, -TenGroup
    make_ten_witness/3,    % +Ones, -TenGroup, -Witness
    decompose_teen/3,      % +Number, -Tens, -Ones
    decompose_teen_witness/4, % +Number, -Tens, -Ones, -Witness
    compose_teen/3,        % +Tens, +Ones, -Number
    compose_teen_witness/4, % +Tens, +Ones, -Number, -Witness
    describe_place_value/2, % +Number, -Description
    describe_place_value_witness/3 % +Number, -Description, -Witness
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

% ============================================================
% Making a ten: group ten ones into a unit
% ============================================================

%!  make_ten(+Ones, -TenGroup) is semidet.
%
%   Given a list of at least 10 tally items, group the first
%   10 into a ten_group and return the remainder.
%   TenGroup = ten_group(TenRec, RemainderRec)
%   where TenRec is recollection of 10 tallies and
%   RemainderRec is whatever is left.
%
%   Fails if fewer than 10 items available.

make_ten(Ones, TenGroup) :-
    make_ten_witness(Ones, TenGroup, _).

%!  make_ten_witness(+Ones, -TenGroup, -Witness) is semidet.
%
%   Prove that the supplied finite recollection contains one group of ten ones.
%   The witness records whether the supplied value is exactly ten or more than
%   ten and exposes the grounded subtraction/equality used.
make_ten_witness(Ones, ten_group(TenRec, RemainderRec), Witness) :-
    incur_cost(inference),
    integer_to_recollection(10, TenRec),
    make_ten_case(Ones, TenRec, RemainderRec, GroupingCase, Relation),
    recollection_to_integer(Ones, OnesValue),
    recollection_to_integer(RemainderRec, RemainderValue),
    range_status_for_value(OnesValue, RangeStatus),
    Witness = _{ kind: standard_k_ns_7_make_ten,
                 scope: closed_world_finite_one_ten_group,
                 standard: in_k_ns_7,
                 source_predicate: make_ten/2,
                 ones: Ones,
                 ones_value: OnesValue,
                 ten_group: ten_group(TenRec, RemainderRec),
                 ten_value: 10,
                 remainder: RemainderRec,
                 remainder_value: RemainderValue,
                 grouping_case: GroupingCase,
                 range_status: RangeStatus,
                 relation: Relation,
                 derivation: ground_one_group_of_ten_and_remainder,
                 boundary: supplied_finite_recollection_checked_against_one_ten_group }.


% ============================================================
% Decompose: teen number → tens and ones
% ============================================================

%!  decompose_teen(+Number, -TensCount, -OnesCount) is semidet.
%
%   Decompose a number (10-20) into its tens and ones.
%   TensCount is the number of complete tens (0 or 1 for 10-20).
%   OnesCount is the remainder.
%
%   Example: decompose_teen(14) → TensCount=1, OnesCount=4
%   (where counts are recollection structures)
%
%   This models "14 is one ten and four ones."

decompose_teen(Number, TensCount, OnesCount) :-
    decompose_teen_witness(Number, TensCount, OnesCount, _).

%!  decompose_teen_witness(+Number, -TensCount, -OnesCount, -Witness) is semidet.
%
%   Decompose a supplied finite recollection into the K.NS.7 one-ten-group
%   place-value form. Under-ten values are retained as compatibility behavior
%   and recorded as zero tens plus all ones.
decompose_teen_witness(Number, TensCount, OnesCount, Witness) :-
    incur_cost(inference),
    integer_to_recollection(10, Ten),
    decompose_case(Number,
                   Ten,
                   TensCount,
                   OnesCount,
                   DecompositionCase,
                   Relation,
                   TenGroupWitness),
    recollection_to_integer(Number, NumberValue),
    recollection_to_integer(TensCount, TensValue),
    recollection_to_integer(OnesCount, OnesValue),
    range_status_for_value(NumberValue, RangeStatus),
    Witness = _{ kind: standard_k_ns_7_decompose_place_value,
                 scope: closed_world_finite_one_ten_group,
                 standard: in_k_ns_7,
                 source_predicate: decompose_teen/3,
                 number: Number,
                 number_value: NumberValue,
                 tens: TensCount,
                 tens_value: TensValue,
                 ones: OnesCount,
                 ones_value: OnesValue,
                 decomposition_case: DecompositionCase,
                 range_status: RangeStatus,
                 relation: Relation,
                 derivation: one_ten_group_plus_leftover_ones,
                 boundary: k_ns_7_one_ten_group_projection_for_supplied_recollection,
                 ten_group_witness: TenGroupWitness }.


% ============================================================
% Compose: tens and ones → teen number
% ============================================================

%!  compose_teen(+TensCount, +OnesCount, -Number) is det.
%
%   Compose a number from tens-count and ones-count.
%   TensCount should be 0 or 1 (for numbers 0-20).
%
%   Example: compose_teen(1, 4) → 14

compose_teen(TensCount, OnesCount, Number) :-
    compose_teen_witness(TensCount, OnesCount, Number, _).

%!  compose_teen_witness(+TensCount, +OnesCount, -Number, -Witness) is det.
%
%   Compose the K.NS.7 one-ten-group representation back into a finite
%   recollection. In this kindergarten surface, `TensCount` is interpreted as
%   zero tens versus one ten group, preserving the previous public behavior.
compose_teen_witness(TensCount, OnesCount, Number, Witness) :-
    incur_cost(inference),
    integer_to_recollection(10, Ten),
    zero(Zero),
    compose_case(TensCount,
                 OnesCount,
                 Ten,
                 Zero,
                 Number,
                 CompositionCase,
                 Relation),
    recollection_to_integer(TensCount, TensValue),
    recollection_to_integer(OnesCount, OnesValue),
    recollection_to_integer(Number, NumberValue),
    range_status_for_value(NumberValue, RangeStatus),
    Witness = _{ kind: standard_k_ns_7_compose_place_value,
                 scope: closed_world_finite_one_ten_group,
                 standard: in_k_ns_7,
                 source_predicate: compose_teen/3,
                 tens: TensCount,
                 tens_value: TensValue,
                 ones: OnesCount,
                 ones_value: OnesValue,
                 number: Number,
                 number_value: NumberValue,
                 composition_case: CompositionCase,
                 range_status: RangeStatus,
                 relation: Relation,
                 derivation: compose_zero_or_one_ten_group_with_ones,
                 boundary: k_ns_7_interprets_nonzero_tens_as_one_ten_group }.


% ============================================================
% Description: produce place-value description
% ============================================================

%!  describe_place_value(+Number, -Description) is semidet.
%
%   Produce a structured description of the place-value
%   decomposition. Returns a term of the form:
%     place_value(TensInt, OnesInt)
%
%   Example: describe_place_value(rec(14)) → place_value(1, 4)

describe_place_value(Number, Description) :-
    describe_place_value_witness(Number, Description, _).

%!  describe_place_value_witness(+Number, -Description, -Witness) is semidet.
%
%   Produce the readable `place_value(Tens, Ones)` description together with
%   the decomposition proof that justifies it.
describe_place_value_witness(Number, place_value(TensInt, OnesInt), Witness) :-
    decompose_teen_witness(Number, TensCount, OnesCount, DecomposeWitness),
    recollection_to_integer(TensCount, TensInt),
    recollection_to_integer(OnesCount, OnesInt),
    recollection_to_integer(Number, NumberValue),
    get_dict(range_status, DecomposeWitness, RangeStatus),
    Witness = _{ kind: standard_k_ns_7_place_value_description,
                 scope: closed_world_finite_one_ten_group,
                 standard: in_k_ns_7,
                 source_predicate: describe_place_value/2,
                 number: Number,
                 number_value: NumberValue,
                 description: place_value(TensInt, OnesInt),
                 tens_value: TensInt,
                 ones_value: OnesInt,
                 range_status: RangeStatus,
                 derivation: decompose_then_render_tens_and_ones,
                 boundary: readable_projection_of_k_ns_7_one_ten_group_decomposition,
                 decompose_witness: DecomposeWitness }.

make_ten_case(Ones, TenRec, RemainderRec, more_than_ten, smaller_than(TenRec, Ones)) :-
    smaller_than(TenRec, Ones),
    subtract_grounded(Ones, TenRec, RemainderRec).
make_ten_case(Ones, TenRec, RemainderRec, exactly_ten, equal_to(Ones, TenRec)) :-
    equal_to(Ones, TenRec),
    zero(RemainderRec).

decompose_case(Number,
               Ten,
               TensCount,
               OnesCount,
               zero_tens,
               smaller_than(Number, Ten),
               _{ kind: standard_k_ns_7_no_ten_group,
                  scope: closed_world_finite_under_ten_recollection,
                  number: Number,
                  ten: Ten,
                  derivation: supplied_number_is_less_than_one_ten }) :-
    smaller_than(Number, Ten),
    zero(TensCount),
    OnesCount = Number.
decompose_case(Number,
               _Ten,
               TensCount,
               OnesCount,
               one_ten_group,
               make_ten(Number, ten_group(TenRec, OnesCount)),
               TenGroupWitness) :-
    make_ten_witness(Number, ten_group(TenRec, OnesCount), TenGroupWitness),
    integer_to_recollection(1, TensCount).

compose_case(TensCount,
             OnesCount,
             _Ten,
             Zero,
             OnesCount,
             zero_tens,
             equal_to(TensCount, Zero)) :-
    equal_to(TensCount, Zero).
compose_case(TensCount,
             OnesCount,
             Ten,
             Zero,
             Number,
             one_ten_group_plus_ones,
             add_grounded(Ten, OnesCount, Number)) :-
    \+ equal_to(TensCount, Zero),
    add_grounded(Ten, OnesCount, Number).

range_status_for_value(Value, within_k_ns_7_range) :-
    Value >= 10,
    Value =< 20,
    !.
range_status_for_value(Value, under_k_ns_7_range) :-
    Value < 10,
    !.
range_status_for_value(_Value, beyond_k_ns_7_range).
