/** <module> Standards 2.NS.2 + 2.NS.4 — Three-digit place value
 *
 * Indiana: 2.NS.2 — "Read and write whole numbers up to 1,000. Use
 *          words, models, standard form, and expanded form." (E)
 *          2.NS.4 — "Define and model a 'hundred' as a group of ten
 *          tens. Model place value concepts of three-digit numbers." (E)
 * CCSS:    2.NBT.A.1 — "Understand that the three digits of a three-
 *                       digit number represent amounts of hundreds,
 *                       tens, and ones."
 *
 * Extends 1.NS.2 from two digits to three digits.
 *
 * BRANDOM CONNECTION: "Hundred as a group of ten tens" is recursive
 *   place-value composition — the same grouping practice applied at
 *   a higher level. The vocabulary "3 hundreds, 4 tens, 7 ones" is
 *   stronger than "three hundred forty-seven" because it exposes the
 *   internal structure needed for multi-digit computation.
 */

:- module(standard_2_ns_2_4, [
    decompose_three_digit/4, % +Number, -Hundreds, -Tens, -Ones
    decompose_three_digit_witness/5, % +Number, -Hundreds, -Tens, -Ones, -Witness
    compose_three_digit/4,   % +Hundreds, +Tens, +Ones, -Number
    compose_three_digit_witness/5, % +Hundreds, +Tens, +Ones, -Number, -Witness
    expanded_form/2,         % +Number, -ExpandedTerms
    expanded_form_witness/3, % +Number, -ExpandedTerms, -Witness
    describe_three_digit/2,  % +Number, -Description
    describe_three_digit_witness/3 % +Number, -Description, -Witness
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

:- use_module(formalization(grounded_utils), [predecessor_rec/2]).
:- use_module(standard_1_ns_2, [
    decompose_two_digit/3,
    compose_two_digit/3
]).

%!  decompose_three_digit(+Number, -Hundreds, -Tens, -Ones) is det.
%
%   Decompose a number (0-999) into hundreds, tens, and ones.
%   All outputs are recollection structures.

decompose_three_digit(Number, Hundreds, Tens, Ones) :-
    decompose_three_digit_witness(Number, Hundreds, Tens, Ones, _).

%!  decompose_three_digit_witness(+Number, -Hundreds, -Tens, -Ones, -Witness) is det.
%
%   Witness-bearing version of decompose_three_digit/4. This is the
%   closed-world finite case for supplied grounded recollections: complete
%   hundreds are counted by repeated subtraction, then the remaining
%   two-digit value is delegated to the loaded 1.NS.2 decomposition.

decompose_three_digit_witness(Number, Hundreds, Tens, Ones, Witness) :-
    incur_cost(inference),
    integer_to_recollection(100, HundredUnit),
    count_units_(Number, HundredUnit, Hundreds, Remainder),
    decompose_two_digit(Remainder, Tens, Ones),
    decompose_witness(Number,
                      Hundreds,
                      Tens,
                      Ones,
                      Remainder,
                      HundredUnit,
                      Witness).

%% Count how many complete units fit
count_units_(Number, Unit, Count, Remainder) :-
    zero(Zero),
    count_units_acc_(Number, Unit, Zero, Count, Remainder).

count_units_acc_(Number, Unit, Acc, Acc, Number) :-
    smaller_than(Number, Unit), !.
count_units_acc_(Number, _Unit, Acc, Acc, Number) :-
    zero(Zero), equal_to(Number, Zero), !.
count_units_acc_(Number, Unit, Acc, Count, Remainder) :-
    subtract_grounded(Number, Unit, Rest),
    successor_rec(Acc, NextAcc),
    count_units_acc_(Rest, Unit, NextAcc, Count, Remainder).

successor_rec(recollection(H), recollection([tally|H])).
% predecessor_rec/2 imported from formalization(grounded_utils).

%!  compose_three_digit(+Hundreds, +Tens, +Ones, -Number) is det.
compose_three_digit(Hundreds, Tens, Ones, Number) :-
    compose_three_digit_witness(Hundreds, Tens, Ones, Number, _).

%!  compose_three_digit_witness(+Hundreds, +Tens, +Ones, -Number, -Witness) is det.
%
%   Witness-bearing version of compose_three_digit/4. The proof multiplies
%   the hundreds count by the constructed hundred unit, delegates tens/ones
%   composition to 1.NS.2, and then adds the two grounded values.
compose_three_digit_witness(Hundreds, Tens, Ones, Number, Witness) :-
    incur_cost(inference),
    integer_to_recollection(100, HundredUnit),
    multiply_units_(Hundreds, HundredUnit, HundredsValue),
    compose_two_digit(Tens, Ones, TensOnesValue),
    add_grounded(HundredsValue, TensOnesValue, Number),
    compose_witness(Hundreds,
                    Tens,
                    Ones,
                    Number,
                    HundredUnit,
                    HundredsValue,
                    TensOnesValue,
                    Witness).

multiply_units_(Count, _Unit, Zero) :-
    zero(Zero), equal_to(Count, Zero), !.
multiply_units_(Count, Unit, Result) :-
    predecessor_rec(Count, PrevCount),
    multiply_units_(PrevCount, Unit, Partial),
    add_grounded(Partial, Unit, Result).

%!  expanded_form(+Number, -ExpandedTerms) is det.
%
%   Return the expanded form as a list of terms.
%   Example: expanded_form(347) → [hundreds(3), tens(4), ones(7)]

expanded_form(Number, ExpandedTerms) :-
    expanded_form_witness(Number, ExpandedTerms, _).

%!  expanded_form_witness(+Number, -ExpandedTerms, -Witness) is det.
expanded_form_witness(Number, ExpandedTerms, Witness) :-
    decompose_three_digit_witness(Number, H, T, O, DecompositionWitness),
    recollection_to_integer(H, HI),
    recollection_to_integer(T, TI),
    recollection_to_integer(O, OI),
    ExpandedTerms = [hundreds(HI), tens(TI), ones(OI)],
    projection_witness(expanded_form,
                       expanded_form/2,
                       Number,
                       ExpandedTerms,
                       DecompositionWitness,
                       Witness).

%!  describe_three_digit(+Number, -Description) is det.
describe_three_digit(Number, place_value(HI, TI, OI)) :-
    describe_three_digit_witness(Number, place_value(HI, TI, OI), _).

%!  describe_three_digit_witness(+Number, -Description, -Witness) is det.
describe_three_digit_witness(Number, place_value(HI, TI, OI), Witness) :-
    decompose_three_digit_witness(Number, H, T, O, DecompositionWitness),
    recollection_to_integer(H, HI),
    recollection_to_integer(T, TI),
    recollection_to_integer(O, OI),
    projection_witness(place_value_description,
                       describe_three_digit/2,
                       Number,
                       place_value(HI, TI, OI),
                       DecompositionWitness,
                       Witness).

decompose_witness(Number,
                  Hundreds,
                  Tens,
                  Ones,
                  Remainder,
                  HundredUnit,
                  _{ kind: standard_2_ns_2_4_decomposition,
                     scope: closed_world_finite_standard_2_ns_2_4_place_value,
                     standard: in_2_ns_2_4,
                     source_predicate: decompose_three_digit/4,
                     number: Number,
                     number_count: NumberCount,
                     hundreds: Hundreds,
                     tens: Tens,
                     ones: Ones,
                     place_counts: _{hundreds: HI, tens: TI, ones: OI},
                     hundred_unit_count: HundredUnitCount,
                     remainder_after_hundreds: Remainder,
                     remainder_count: RemainderCount,
                     derivation: count_hundreds_then_decompose_remainder,
                     projection: hundreds_tens_ones_place_value,
                     boundary: supplied_grounded_recollection_up_to_1000,
                     bound_status: BoundStatus,
                     subproofs: [hundreds_by_repeated_subtraction,
                                 tens_ones_by_standard_1_ns_2] }) :-
    recollection_to_integer(Number, NumberCount),
    recollection_to_integer(Hundreds, HI),
    recollection_to_integer(Tens, TI),
    recollection_to_integer(Ones, OI),
    recollection_to_integer(HundredUnit, HundredUnitCount),
    recollection_to_integer(Remainder, RemainderCount),
    place_value_bound_status(NumberCount, BoundStatus).

compose_witness(Hundreds,
                Tens,
                Ones,
                Number,
                HundredUnit,
                HundredsValue,
                TensOnesValue,
                _{ kind: standard_2_ns_2_4_composition,
                   scope: closed_world_finite_standard_2_ns_2_4_place_value,
                   standard: in_2_ns_2_4,
                   source_predicate: compose_three_digit/4,
                   hundreds: Hundreds,
                   tens: Tens,
                   ones: Ones,
                   number: Number,
                   number_count: NumberCount,
                   place_counts: _{hundreds: HI, tens: TI, ones: OI},
                   hundred_unit_count: HundredUnitCount,
                   hundreds_value_count: HundredsValueCount,
                   tens_ones_value_count: TensOnesValueCount,
                   derivation: multiply_hundreds_then_compose_tens_ones,
                   projection: hundreds_tens_ones_place_value,
                   boundary: supplied_grounded_recollection_up_to_1000,
                   bound_status: BoundStatus,
                   subproofs: [hundreds_value_by_repeated_addition,
                               tens_ones_by_standard_1_ns_2,
                               grounded_addition_of_place_values] }) :-
    recollection_to_integer(Hundreds, HI),
    recollection_to_integer(Tens, TI),
    recollection_to_integer(Ones, OI),
    recollection_to_integer(Number, NumberCount),
    recollection_to_integer(HundredUnit, HundredUnitCount),
    recollection_to_integer(HundredsValue, HundredsValueCount),
    recollection_to_integer(TensOnesValue, TensOnesValueCount),
    place_value_bound_status(NumberCount, BoundStatus).

projection_witness(Projection,
                   Predicate,
                   Number,
                   Output,
                   DecompositionWitness,
                   _{ kind: standard_2_ns_2_4_projection,
                      scope: closed_world_finite_standard_2_ns_2_4_place_value,
                      standard: in_2_ns_2_4,
                      source_predicate: Predicate,
                      number: Number,
                      number_count: NumberCount,
                      output: Output,
                      projection: Projection,
                      derivation: project_from_three_digit_decomposition,
                      boundary: supplied_grounded_recollection_up_to_1000,
                      decomposition_witness: DecompositionWitness }) :-
    recollection_to_integer(Number, NumberCount).

place_value_bound_status(Count, within_indiana_2_ns_2_4_bound) :-
    Count =< 1000, !.
place_value_bound_status(Count, outside_indiana_2_ns_2_4_bound(Count)).
