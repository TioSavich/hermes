/** <module> Standard 2.CA.2 — Add/subtract within 1000 (place value)
 *
 * Indiana: 2.CA.2 — "Using number sense and place value strategies,
 *          add and subtract within 1,000, including composing and
 *          decomposing tens and hundreds."
 * CCSS:    2.NBT.B.7 — "Add and subtract within 1000, using concrete
 *                       models or drawings and strategies based on
 *                       place value..."
 *
 * VPV MAPPING:
 *   V  (target vocabulary): multi-digit sums/differences, "regroup",
 *      "compose a ten/hundred", "decompose a ten/hundred"
 *   P  (practices): place-value addition with cascading regrouping;
 *      place-value subtraction with borrowing; decomposing
 *      hundreds into tens when borrowing
 *   V' (metavocabulary): "add the ones, add the tens, add the
 *      hundreds", "do I need to regroup?", "I need to break apart
 *      a hundred into ten tens"
 *
 * CONNECTION TO EXISTING AUTOMATA:
 *   This standard is the home of the strategy automata in
 *   prolog/Prolog/math/:
 *
 *   Addition strategies:
 *   - sar_add_counting_on.pl  — counting on (O(B), base case)
 *   - sar_add_cobo.pl         — COBO: add bases, then ones
 *   - sar_add_rmb.pl          — Round to Make Base: round up, adjust
 *   - sar_add_chunking.pl     — Chunk by place value, add in parts
 *   - sar_add_rounding.pl     — Round both, adjust
 *
 *   Subtraction strategies:
 *   - sar_sub_counting_back.pl      — count back (O(B))
 *   - sar_sub_decomposition.pl      — decompose subtrahend
 *   - sar_sub_cobo_missing_addend.pl — COBO: missing addend
 *   - sar_sub_chunking_a/b/c.pl     — chunk by place value
 *   - sar_sub_sliding.pl            — slide both numbers
 *   - sar_sub_cbbo_take_away.pl     — count back bases/ones
 *
 *   The standard describes what children DO; the automata formalize
 *   the specific strategies as FSMs with cost tracking.
 *
 * BRANDOM CONNECTION: The transition from two-digit to three-digit
 *   arithmetic is where algorithmic elaboration becomes recursive.
 *   The same decompose-add-regroup pattern applies at hundreds,
 *   tens, and ones — the practice is the same, applied at different
 *   levels. This recursive application of a practice is what
 *   Brandom calls "algorithmic decomposition": the complex
 *   practice (three-digit addition) decomposes into applications
 *   of a simpler practice (single-place addition + regrouping).
 *
 * BOUNDARIES:
 *   - This is the closed-world finite 2.CA.2 operation case for supplied
 *     grounded recollections. It proves addition and subtraction by decomposing
 *     both inputs into hundreds, tens, and ones, applying grounded arithmetic
 *     place by place, and recording each regroup or borrow used by the finite
 *     proof.
 *   - The Indiana classroom surface is add/subtract within 1,000. The checker
 *     can execute finite grounded recollection operations outside that range,
 *     but witnesses mark whether the result is inside the 2.CA.2 bound.
 *   - Strategy automata are conceptual anchors here; this module records the
 *     closed-world finite arithmetic proof rather than executing each FSM.
 */

:- module(standard_2_ca_2, [
    add_three_digit/3,     % +A, +B, -Sum
    add_three_digit_witness/4, % +A, +B, -Sum, -Witness
    sub_three_digit/3,     % +A, +B, -Difference
    sub_three_digit_witness/4, % +A, +B, -Difference, -Witness
    add_cobo_style/3,      % +A, +B, -Sum (COBO strategy)
    add_cobo_style_witness/4, % +A, +B, -Sum, -Witness
    sub_decompose_style/3, % +A, +B, -Difference (decomposition)
    sub_decompose_style_witness/4 % +A, +B, -Difference, -Witness
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
:- use_module(standard_2_ns_2_4, [
    decompose_three_digit_witness/5,
    compose_three_digit_witness/5
]).

% ============================================================
% Place-value addition within 1000
% ============================================================

%!  add_three_digit(+A, +B, -Sum) is det.
%
%   Add two numbers using three-place decomposition with
%   cascading regrouping (ones→tens→hundreds).

add_three_digit(A, B, Sum) :-
    add_three_digit_witness(A, B, Sum, _).

%!  add_three_digit_witness(+A, +B, -Sum, -Witness) is det.
%
%   Witness-bearing place-value addition. The proof exposes both input
%   decompositions, ones/tens regroup decisions, the final place counts, and
%   the 2.NS.2/2.NS.4 composition witness for the result.
add_three_digit_witness(A, B, Sum, Witness) :-
    incur_cost(inference),
    decompose_three_digit_witness(A, HA, TA, OA, DecompositionA),
    decompose_three_digit_witness(B, HB, TB, OB, DecompositionB),
    integer_to_recollection(10, Ten),
    add_grounded(OA, OB, OnesSum),
    regroup_witness(OnesSum, Ten, FinalOnes, OnesCarry, OnesRegroup),
    add_grounded(TA, TB, TensPartial),
    add_grounded(TensPartial, OnesCarry, TensSum),
    regroup_witness(TensSum, Ten, FinalTens, TensCarry, TensRegroup),
    add_grounded(HA, HB, HundredsPartial),
    add_grounded(HundredsPartial, TensCarry, FinalHundreds),
    compose_three_digit_witness(FinalHundreds, FinalTens, FinalOnes, Sum, CompositionWitness),
    addition_witness(A, B, Sum,
                     DecompositionA, DecompositionB,
                     OnesSum, TensPartial, TensSum, HundredsPartial,
                     FinalHundreds, FinalTens, FinalOnes,
                     OnesRegroup, TensRegroup, CompositionWitness,
                     Witness).

regroup_witness(Value, Limit, Remainder, Carry, Witness) :-
    (   smaller_than(Value, Limit)
    ->  Remainder = Value,
        zero(Carry),
        RegroupCase = no_regroup,
        Derivation = value_less_than_base
    ;   equal_to(Value, Limit)
    ->  zero(Remainder),
        integer_to_recollection(1, Carry),
        RegroupCase = exact_base_regroup,
        Derivation = value_equals_base
    ;   subtract_grounded(Value, Limit, Remainder),
        integer_to_recollection(1, Carry),
        RegroupCase = regroup,
        Derivation = subtract_base_and_carry_one
    ),
    regroup_decision_witness(Value, Limit, Remainder, Carry,
                             RegroupCase, Derivation, Witness).


% ============================================================
% Place-value subtraction within 1000
% ============================================================

%!  sub_three_digit(+A, +B, -Difference) is semidet.
%
%   Subtract B from A using place-value decomposition with
%   borrowing (decomposing a ten into ones, a hundred into tens).
%   Handles cascade borrowing: if ones needs to borrow but tens
%   is 0, borrows from hundreds first to populate tens.

sub_three_digit(A, B, Difference) :-
    sub_three_digit_witness(A, B, Difference, _).

%!  sub_three_digit_witness(+A, +B, -Difference, -Witness) is semidet.
%
%   Witness-bearing place-value subtraction. The witness records the finite
%   borrow decisions used to make each place subtraction executable, including
%   cascade borrowing from hundreds when the tens place is initially zero.
sub_three_digit_witness(A, B, Difference, Witness) :-
    incur_cost(inference),
    decompose_three_digit_witness(A, HA, TA, OA, DecompositionA),
    decompose_three_digit_witness(B, HB, TB, OB, DecompositionB),
    integer_to_recollection(10, Ten),
    zero(Zero),
    ones_borrow_witness(HA, TA, OA, OB, Ten, Zero,
                        HA1, TA2, OA2, OnesBorrow),
    subtract_grounded(OA2, OB, FinalOnes),
    tens_borrow_witness(HA1, TA2, TB, Ten,
                        HA2, FinalTens, TensBorrow),
    subtract_grounded(HA2, HB, FinalHundreds),
    compose_three_digit_witness(FinalHundreds, FinalTens, FinalOnes, Difference, CompositionWitness),
    subtraction_witness(A, B, Difference,
                        DecompositionA, DecompositionB,
                        OnesBorrow, TensBorrow,
                        FinalHundreds, FinalTens, FinalOnes,
                        CompositionWitness,
                        Witness).

% predecessor_rec/2 imported from formalization(grounded_utils).


% ============================================================
% COBO-style addition (bases first, then ones)
% ============================================================

%!  add_cobo_style(+A, +B, -Sum) is det.
%
%   Add using COBO (Count On Bases and Ones) strategy:
%   1. Add the hundreds of B to A
%   2. Add the tens of B
%   3. Add the ones of B
%   This matches the pattern in sar_add_cobo.pl.

add_cobo_style(A, B, Sum) :-
    add_cobo_style_witness(A, B, Sum, _).

%!  add_cobo_style_witness(+A, +B, -Sum, -Witness) is det.
%
%   Witness-bearing COBO addition. The finite proof decomposes the second
%   addend and then records the three repeated-addition phases: hundreds, tens,
%   and ones.
add_cobo_style_witness(A, B, Sum, Witness) :-
    incur_cost(inference),
    decompose_three_digit_witness(B, HB, TB, OB, DecompositionB),
    integer_to_recollection(100, Hundred),
    multiply_and_add_witness(A, HB, Hundred, hundreds, Step1, HundredStep),
    integer_to_recollection(10, Ten),
    multiply_and_add_witness(Step1, TB, Ten, tens, Step2, TenStep),
    integer_to_recollection(1, One),
    multiply_and_add_witness(Step2, OB, One, ones, Sum, OneStep),
    cobo_witness(A, B, Sum, DecompositionB,
                 [HundredStep, TenStep, OneStep], Witness).

multiply_and_add_(Base, Count, Unit, Result) :-
    zero(Zero),
    (   equal_to(Count, Zero)
    ->  Result = Base
    ;   add_grounded(Base, Unit, Next),
        predecessor_rec(Count, NewCount),
        multiply_and_add_(Next, NewCount, Unit, Result)
    ).


% ============================================================
% Decomposition-style subtraction
% ============================================================

%!  sub_decompose_style(+A, +B, -Difference) is det.
%
%   Subtract using decomposition: break subtrahend into parts
%   and subtract each part separately.
%   This matches sar_sub_decomposition.pl pattern.

sub_decompose_style(A, B, Difference) :-
    sub_decompose_style_witness(A, B, Difference, _).

%!  sub_decompose_style_witness(+A, +B, -Difference, -Witness) is det.
%
%   Witness-bearing decomposition subtraction. The finite proof decomposes the
%   subtrahend and then records the three repeated-subtraction phases:
%   hundreds, tens, and ones.
sub_decompose_style_witness(A, B, Difference, Witness) :-
    incur_cost(inference),
    decompose_three_digit_witness(B, HB, TB, OB, DecompositionB),
    integer_to_recollection(100, Hundred),
    subtract_units_witness(A, HB, Hundred, hundreds, Step1, HundredStep),
    integer_to_recollection(10, Ten),
    subtract_units_witness(Step1, TB, Ten, tens, Step2, TenStep),
    integer_to_recollection(1, One),
    subtract_units_witness(Step2, OB, One, ones, Difference, OneStep),
    decompose_subtraction_witness(A, B, Difference, DecompositionB,
                                  [HundredStep, TenStep, OneStep],
                                  Witness).

subtract_units_(Base, Count, Unit, Result) :-
    zero(Zero),
    (   equal_to(Count, Zero)
    ->  Result = Base
    ;   subtract_grounded(Base, Unit, Next),
        predecessor_rec(Count, NewCount),
        subtract_units_(Next, NewCount, Unit, Result)
    ).

multiply_and_add_witness(Base, Count, Unit, Place, Result,
                         _{ kind: standard_2_ca_2_cobo_step,
                            place: Place,
                            start: Base,
                            start_count: BaseCount,
                            unit: Unit,
                            unit_count: UnitCount,
                            repetitions: Count,
                            repetitions_count: CountValue,
                            result: Result,
                            result_count: ResultCount,
                            derivation: repeated_grounded_addition }) :-
    multiply_and_add_(Base, Count, Unit, Result),
    recollection_to_integer(Base, BaseCount),
    recollection_to_integer(Unit, UnitCount),
    recollection_to_integer(Count, CountValue),
    recollection_to_integer(Result, ResultCount).

subtract_units_witness(Base, Count, Unit, Place, Result,
                       _{ kind: standard_2_ca_2_decomposition_subtraction_step,
                          place: Place,
                          start: Base,
                          start_count: BaseCount,
                          unit: Unit,
                          unit_count: UnitCount,
                          repetitions: Count,
                          repetitions_count: CountValue,
                          result: Result,
                          result_count: ResultCount,
                          derivation: repeated_grounded_subtraction }) :-
    subtract_units_(Base, Count, Unit, Result),
    recollection_to_integer(Base, BaseCount),
    recollection_to_integer(Unit, UnitCount),
    recollection_to_integer(Count, CountValue),
    recollection_to_integer(Result, ResultCount).

ones_borrow_witness(HA, TA, OA, OB, Ten, Zero,
                    HA1, TA2, OA2, Witness) :-
    (   smaller_than(OA, OB)
    ->  (   equal_to(TA, Zero)
        ->  predecessor_rec(HA, HA1),
            add_grounded(TA, Ten, TA1),
            predecessor_rec(TA1, TA2),
            add_grounded(OA, Ten, OA2),
            Case = cascade_borrow_from_hundreds,
            IntermediateTens = TA1,
            Derivation = decompose_hundred_then_decompose_ten_for_ones
        ;   HA1 = HA,
            predecessor_rec(TA, TA2),
            add_grounded(OA, Ten, OA2),
            IntermediateTens = TA,
            Case = borrow_from_tens,
            Derivation = decompose_ten_for_ones
        )
    ;   HA1 = HA,
        TA2 = TA,
        OA2 = OA,
        IntermediateTens = TA,
        Case = no_borrow,
        Derivation = ones_place_already_sufficient
    ),
    borrow_witness(ones, Case, Derivation,
                   HA, TA, OA, OB, HA1, IntermediateTens, TA2, OA2,
                   Witness).

tens_borrow_witness(HA1, TA2, TB, Ten,
                    HA2, FinalTens, Witness) :-
    (   smaller_than(TA2, TB)
    ->  predecessor_rec(HA1, HA2),
        add_grounded(TA2, Ten, TA3),
        subtract_grounded(TA3, TB, FinalTens),
        Case = borrow_from_hundreds,
        BorrowedTens = TA3,
        Derivation = decompose_hundred_for_tens
    ;   subtract_grounded(TA2, TB, FinalTens),
        HA2 = HA1,
        BorrowedTens = TA2,
        Case = no_borrow,
        Derivation = tens_place_already_sufficient
    ),
    borrow_witness(tens, Case, Derivation,
                   HA1, TA2, TA2, TB, HA2, BorrowedTens, FinalTens, FinalTens,
                   Witness).

regroup_decision_witness(Value, Limit, Remainder, Carry,
                         Case, Derivation,
                         _{ kind: standard_2_ca_2_regroup_decision,
                            case: Case,
                            value: Value,
                            value_count: ValueCount,
                            base: Limit,
                            base_count: LimitCount,
                            remainder: Remainder,
                            remainder_count: RemainderCount,
                            carry: Carry,
                            carry_count: CarryCount,
                            derivation: Derivation }) :-
    recollection_to_integer(Value, ValueCount),
    recollection_to_integer(Limit, LimitCount),
    recollection_to_integer(Remainder, RemainderCount),
    recollection_to_integer(Carry, CarryCount).

borrow_witness(Place, Case, Derivation,
               HundredsBefore, PlaceBefore, AvailableBefore, Required,
               HundredsAfter, IntermediatePlace, PlaceAfter, AvailableAfter,
               _{ kind: standard_2_ca_2_borrow_decision,
                  place: Place,
                  case: Case,
                  hundreds_before: HundredsBefore,
                  hundreds_before_count: HundredsBeforeCount,
                  place_before: PlaceBefore,
                  place_before_count: PlaceBeforeCount,
                  available_before: AvailableBefore,
                  available_before_count: AvailableBeforeCount,
                  required: Required,
                  required_count: RequiredCount,
                  hundreds_after: HundredsAfter,
                  hundreds_after_count: HundredsAfterCount,
                  intermediate_place: IntermediatePlace,
                  intermediate_place_count: IntermediatePlaceCount,
                  place_after: PlaceAfter,
                  place_after_count: PlaceAfterCount,
                  available_after: AvailableAfter,
                  available_after_count: AvailableAfterCount,
                  derivation: Derivation }) :-
    recollection_to_integer(HundredsBefore, HundredsBeforeCount),
    recollection_to_integer(PlaceBefore, PlaceBeforeCount),
    recollection_to_integer(AvailableBefore, AvailableBeforeCount),
    recollection_to_integer(Required, RequiredCount),
    recollection_to_integer(HundredsAfter, HundredsAfterCount),
    recollection_to_integer(IntermediatePlace, IntermediatePlaceCount),
    recollection_to_integer(PlaceAfter, PlaceAfterCount),
    recollection_to_integer(AvailableAfter, AvailableAfterCount).

addition_witness(A, B, Sum,
                 DecompositionA, DecompositionB,
                 OnesSum, TensPartial, TensSum, HundredsPartial,
                 FinalHundreds, FinalTens, FinalOnes,
                 OnesRegroup, TensRegroup, CompositionWitness,
                 _{ kind: standard_2_ca_2_place_value_addition,
                    scope: closed_world_finite_standard_2_ca_2_operations_within_1000,
                    standard: in_2_ca_2,
                    source_predicate: add_three_digit/3,
                    operation: addition,
                    addends: _{a: A, b: B, a_count: ACount, b_count: BCount},
                    sum: Sum,
                    sum_count: SumCount,
                    decomposition_a: DecompositionA,
                    decomposition_b: DecompositionB,
                    ones_sum: OnesSum,
                    ones_sum_count: OnesSumCount,
                    ones_regroup: OnesRegroup,
                    tens_partial_sum: TensPartial,
                    tens_partial_sum_count: TensPartialCount,
                    tens_sum_with_ones_carry: TensSum,
                    tens_sum_count: TensSumCount,
                    tens_regroup: TensRegroup,
                    hundreds_partial_sum: HundredsPartial,
                    hundreds_partial_sum_count: HundredsPartialCount,
                    final_place_counts: _{hundreds: FinalHundredsCount,
                                          tens: FinalTensCount,
                                          ones: FinalOnesCount},
                    composition_witness: CompositionWitness,
                    derivation: decompose_addends_add_places_regroup_then_compose,
                    boundary: supplied_grounded_recollections_with_finite_three_place_decomposition,
                    bound_status: BoundStatus }) :-
    recollection_to_integer(A, ACount),
    recollection_to_integer(B, BCount),
    recollection_to_integer(Sum, SumCount),
    recollection_to_integer(OnesSum, OnesSumCount),
    recollection_to_integer(TensPartial, TensPartialCount),
    recollection_to_integer(TensSum, TensSumCount),
    recollection_to_integer(HundredsPartial, HundredsPartialCount),
    recollection_to_integer(FinalHundreds, FinalHundredsCount),
    recollection_to_integer(FinalTens, FinalTensCount),
    recollection_to_integer(FinalOnes, FinalOnesCount),
    operation_bound_status(SumCount, BoundStatus).

subtraction_witness(A, B, Difference,
                    DecompositionA, DecompositionB,
                    OnesBorrow, TensBorrow,
                    FinalHundreds, FinalTens, FinalOnes,
                    CompositionWitness,
                    _{ kind: standard_2_ca_2_place_value_subtraction,
                       scope: closed_world_finite_standard_2_ca_2_operations_within_1000,
                       standard: in_2_ca_2,
                       source_predicate: sub_three_digit/3,
                       operation: subtraction,
                       minuend: A,
                       minuend_count: ACount,
                       subtrahend: B,
                       subtrahend_count: BCount,
                       difference: Difference,
                       difference_count: DifferenceCount,
                       decomposition_minuend: DecompositionA,
                       decomposition_subtrahend: DecompositionB,
                       ones_borrow: OnesBorrow,
                       tens_borrow: TensBorrow,
                       final_place_counts: _{hundreds: FinalHundredsCount,
                                             tens: FinalTensCount,
                                             ones: FinalOnesCount},
                       composition_witness: CompositionWitness,
                       derivation: decompose_borrow_subtract_places_then_compose,
                       boundary: supplied_grounded_recollections_with_finite_three_place_decomposition,
                       bound_status: BoundStatus }) :-
    recollection_to_integer(A, ACount),
    recollection_to_integer(B, BCount),
    recollection_to_integer(Difference, DifferenceCount),
    recollection_to_integer(FinalHundreds, FinalHundredsCount),
    recollection_to_integer(FinalTens, FinalTensCount),
    recollection_to_integer(FinalOnes, FinalOnesCount),
    operation_bound_status(DifferenceCount, BoundStatus).

cobo_witness(A, B, Sum, DecompositionB, Steps,
             _{ kind: standard_2_ca_2_cobo_addition,
                scope: closed_world_finite_standard_2_ca_2_operations_within_1000,
                standard: in_2_ca_2,
                source_predicate: add_cobo_style/3,
                addends: _{a: A, b: B, a_count: ACount, b_count: BCount},
                sum: Sum,
                sum_count: SumCount,
                second_addend_decomposition: DecompositionB,
                steps: Steps,
                derivation: add_hundreds_then_tens_then_ones,
                boundary: supplied_second_addend_finitely_decomposed_into_hundreds_tens_ones,
                bound_status: BoundStatus }) :-
    recollection_to_integer(A, ACount),
    recollection_to_integer(B, BCount),
    recollection_to_integer(Sum, SumCount),
    operation_bound_status(SumCount, BoundStatus).

decompose_subtraction_witness(A, B, Difference, DecompositionB, Steps,
                              _{ kind: standard_2_ca_2_decomposition_subtraction,
                                 scope: closed_world_finite_standard_2_ca_2_operations_within_1000,
                                 standard: in_2_ca_2,
                                 source_predicate: sub_decompose_style/3,
                                 minuend: A,
                                 minuend_count: ACount,
                                 subtrahend: B,
                                 subtrahend_count: BCount,
                                 difference: Difference,
                                 difference_count: DifferenceCount,
                                 subtrahend_decomposition: DecompositionB,
                                 steps: Steps,
                                 derivation: subtract_hundreds_then_tens_then_ones,
                                 boundary: supplied_subtrahend_finitely_decomposed_into_hundreds_tens_ones,
                                 bound_status: BoundStatus }) :-
    recollection_to_integer(A, ACount),
    recollection_to_integer(B, BCount),
    recollection_to_integer(Difference, DifferenceCount),
    operation_bound_status(DifferenceCount, BoundStatus).

operation_bound_status(Count, within_indiana_2_ca_2_bound) :-
    Count =< 1000, !.
operation_bound_status(Count, outside_indiana_2_ca_2_bound(Count)).
