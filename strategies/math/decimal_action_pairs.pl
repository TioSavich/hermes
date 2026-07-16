/** <module> Decimal action/deformation pairs
 *
 * Decimal-place action automata for the registry boundary
 * `run_action_automaton(decimal, Kind, Numeral, Scale, Outcome, Trace)`.
 *
 * Seven families are exposed:
 *
 *   - Positional decimal reading. Numeral is a non-negative integer and
 *     Scale is the power-of-ten denominator (e.g. 345/100 reads as 3 and
 *     45 hundredths). Includes the whole-number-string deformation.
 *
 *   - Decimal multiplication. The registry's Numeral slot carries a
 *     compound term `decimal_pair(N1, S1, N2, S2)` -- two operands with
 *     their power-of-ten denominators -- and Scale is the placeholder
 *     atom `ignored`. The productive trace multiplies the integer
 *     numerals, sums the fractional-place counts, and places the
 *     decimal point. The deformation `decimal_point_rule_misapplication`
 *     takes the maximum of the two place counts instead of summing them.
 *
 *   - Decimal comparison. The Numeral slot carries
 *     `decimal_pair(N1, S1, N2, S2)`. The productive action aligns both
 *     numerals to a common decimal unit before comparing. Its deformation
 *     compares the written integer strings without coordinating their scales.
 *
 *   - Decimal addition and subtraction. Both actions align the operands to a
 *     common decimal unit, delegate the inherited operation to the grounded
 *     integer kernel, and reinscribe the result at the common scale. Their
 *     deformations operate on the written numerals before scale alignment.
 *
 *   - Decimal place-unit regrouping. A count of tenths is exchanged for an
 *     equivalent count of hundredths or thousandths by iterating the nested
 *     base-ten unit relation. Its deformation changes the unit name without
 *     changing the count.
 *
 *   - Decimal division. The same `decimal_pair(N1, S1, N2, S2)` /
 *     `ignored` boundary is used. Two productive automata:
 *     `ecuadorian_decimal_long_division` (extract-030: scale both
 *     operands by a shared power of ten to clear decimals, then divide
 *     as integers) and `recalled_result_scaling` (extract-026: recall a
 *     base division fact and scale the recalled quotient by a power of
 *     ten).
 *
 * Backlog: automata-009 (decimal-multiplication and decimal-division
 * families). Evidence: extract-026 (Fluckiger), extract-030 (Gorgorio),
 * extract-031 (Graeber).
 */

:- module(decimal_action_pairs,
          [ run_decimal_action/5,
            decimal_action_cluster/2,
            decimal_action_vocabulary/2,
            productive_decimal_deformation/3,
            decimal_action_misconception_hook/3
          ]).

:- use_module(math(sar_add_decimal_columnar), [run_decimal_column_add/4]).
:- use_module(math(integer_helpers),
              [ add_ints/3,
                subtract_ints/3,
                multiply_ints/3,
                positive_integer/1
              ]).


%!  run_decimal_action(+Kind, +Numeral, +Scale, -Outcome, -Trace) is semidet.
%
%   Execute a productive or deformed decimal action. For positional
%   reading Numeral is a non-negative integer and Scale is a power of
%   ten greater than one. For decimal multiplication and division
%   Numeral is `decimal_pair(N1, S1, N2, S2)` and Scale is the
%   placeholder atom `ignored`.
run_decimal_action(positional_decimal_reading, Numeral, Scale, Outcome, Trace) :-
    decimal_components(Numeral, Scale, Whole, FractionalDigits, Places, PlaceUnit, Result),
    Outcome = action_outcome(
                  positional_decimal_reading,
                  [ classification(productive),
                    cluster(decimal_positional_notation),
                    automaton_state(decimal_place_value_coordination),
                    vocabulary([decimal_mark, whole_part, fractional_part,
                                place_value, tenths, hundredths, scale_unit]),
                    result(Result),
                    expected(Result),
                    validity(correct),
                    components(decimal_positional_components(Numeral, Scale, Whole,
                                                              FractionalDigits, Places, PlaceUnit))
                  ]),
    Trace = [ read_decimal_mark(scale(Scale)),
              split_whole_and_fractional_parts(Numeral, Scale, Whole, FractionalDigits),
              assign_fractional_place_value(FractionalDigits, places(Places), PlaceUnit),
              compose_decimal_value(Result)
            ].
run_decimal_action(decimal_whole_number_reading, Numeral, Scale, Outcome, Trace) :-
    decimal_components(Numeral, Scale, Whole, FractionalDigits, Places, PlaceUnit, Expected),
    Result = whole_number(Numeral),
    Outcome = action_outcome(
                  decimal_whole_number_reading,
                  [ classification(deformation),
                    cluster(decimal_positional_notation),
                    automaton_state(decimal_place_value_coordination),
                    vocabulary([decimal_mark, whole_number_string, fractional_part,
                                place_value, scale_unit, unit_loss]),
                    result(Result),
                    expected(Expected),
                    validity(incorrect),
                    components(decimal_whole_number_components(Numeral, Scale, Whole,
                                                               FractionalDigits, Places, PlaceUnit)),
                    deformation_of(positional_decimal_reading),
                    misconception_family(decimal_whole_number_reading)
                  ]),
    Trace = [ see_digits_as_whole_number_string(Numeral),
              ignore_decimal_mark(scale(Scale)),
              ignore_fractional_place_value(FractionalDigits, places(Places), PlaceUnit),
              name_decimal_as_whole_number(Result),
              lose_decimal_scale(expected(Expected), produced(Result))
            ].
run_decimal_action(decimal_comparison_by_aligned_units, Pair, ignored,
                   Outcome, Trace) :-
    decimal_comparison_components(Pair, Components),
    Components = decimal_comparison_components(N1, S1, N2, S2,
                                                CommonScale,
                                                Aligned1, Aligned2,
                                                Relation),
    Representation = aligned_decimal_units(
                         common_scale(CommonScale),
                         left_units(Aligned1), right_units(Aligned2)),
    Outcome = action_outcome(
                  decimal_comparison_by_aligned_units,
                  [ classification(productive),
                    cluster(decimal_magnitude_comparison),
                    automaton_state(decimal_place_value_coordination),
                    vocabulary([decimal_mark, common_decimal_unit,
                                scale_alignment, equivalent_numeral,
                                magnitude_comparison]),
                    result(Relation),
                    expected(Relation),
                    validity(correct),
                    operands(decimal_pair(N1, S1, N2, S2)),
                    components(Components),
                    representation(Representation),
                    invariant(compare_only_after_common_unit_alignment)
                  ]),
    Trace = [ identify_operand_scales(S1, S2),
              choose_common_decimal_scale(CommonScale),
              align_decimal_units(N1, S1, Aligned1),
              align_decimal_units(N2, S2, Aligned2),
              compare_aligned_decimal_units(Aligned1, Aligned2, Relation)
            ].
run_decimal_action(decimal_numeral_comparison_without_scale_alignment, Pair,
                   ignored, Outcome, Trace) :-
    decimal_comparison_components(Pair, Components),
    Components = decimal_comparison_components(N1, S1, N2, S2,
                                                _CommonScale,
                                                _Aligned1, _Aligned2,
                                                Expected),
    comparison_relation(N1, N2, Result),
    comparison_validity(Expected, Result, Validity),
    Outcome = action_outcome(
                  decimal_numeral_comparison_without_scale_alignment,
                  [ classification(deformation),
                    cluster(decimal_magnitude_comparison),
                    automaton_state(decimal_place_value_coordination),
                    vocabulary([decimal_mark, written_numeral,
                                unaligned_scale, magnitude_comparison,
                                scale_unit_loss]),
                    result(Result),
                    expected(Expected),
                    validity(Validity),
                    operands(decimal_pair(N1, S1, N2, S2)),
                    components(Components),
                    deformation_of(decimal_comparison_by_aligned_units),
                    misconception_family(
                        decimal_numeral_comparison_without_scale_alignment)
                  ]),
    Trace = [ read_written_integer_numerals(N1, N2),
              omit_decimal_scale_alignment(S1, S2),
              compare_unaligned_numerals(N1, N2, Result),
              lose_decimal_scale_relation(expected(Expected), produced(Result))
            ].
run_decimal_action(decimal_addition_by_aligned_units, Pair, ignored,
                   Outcome, Trace) :-
    aligned_decimal_operands(Pair, N1, S1, N2, S2,
                             CommonScale, Aligned1, Aligned2),
    add_ints(Aligned1, Aligned2, SumNumeral),
    decimal_components(SumNumeral, CommonScale, Whole, FractionalDigits,
                       Places, PlaceUnit, Result),
    Outcome = action_outcome(
                  decimal_addition_by_aligned_units,
                  [ classification(productive),
                    cluster(decimal_addition),
                    automaton_state(decimal_align_operate_reinscribe),
                    vocabulary([common_decimal_unit, scale_alignment,
                                grounded_integer_addition,
                                positional_reinscription]),
                    result(Result), expected(Result), validity(correct),
                    operands(decimal_pair(N1, S1, N2, S2)),
                    representation(aligned_decimal_operation(
                        common_scale(CommonScale), left_units(Aligned1),
                        right_units(Aligned2), result_units(SumNumeral))),
                    components(decimal_positional_components(
                        SumNumeral, CommonScale, Whole, FractionalDigits,
                        Places, PlaceUnit)),
                    invariant(add_only_after_common_unit_alignment),
                    elaborates(grounded_integer_addition)
                  ]),
    Trace = [ identify_operand_scales(S1, S2),
              choose_common_decimal_scale(CommonScale),
              align_decimal_units(N1, S1, Aligned1),
              align_decimal_units(N2, S2, Aligned2),
              add_grounded_aligned_units(Aligned1, Aligned2, SumNumeral),
              reinscribe_decimal_result(SumNumeral, CommonScale, Result)
            ].
run_decimal_action(decimal_add_unaligned_numerals, Pair, ignored,
                   Outcome, Trace) :-
    aligned_decimal_operands(Pair, N1, S1, N2, S2,
                             CommonScale, Aligned1, Aligned2),
    add_ints(Aligned1, Aligned2, ExpectedNumeral),
    add_ints(N1, N2, ResultNumeral),
    decimal_components(ExpectedNumeral, CommonScale, _, _, _, _, Expected),
    decimal_components(ResultNumeral, CommonScale, _, _, _, _, Result),
    decimal_result_validity(Expected, Result, Validity),
    Outcome = action_outcome(
                  decimal_add_unaligned_numerals,
                  [ classification(deformation),
                    cluster(decimal_addition),
                    automaton_state(decimal_align_operate_reinscribe),
                    vocabulary([written_numeral, unaligned_scale,
                                integer_addition, scale_unit_loss]),
                    result(Result), expected(Expected), validity(Validity),
                    operands(decimal_pair(N1, S1, N2, S2)),
                    deformation_of(decimal_addition_by_aligned_units),
                    misconception_family(decimal_add_unaligned_numerals)
                  ]),
    Trace = [ read_written_integer_numerals(N1, N2),
              omit_decimal_scale_alignment(S1, S2),
              add_unaligned_numerals(N1, N2, ResultNumeral),
              reinscribe_at_larger_scale(ResultNumeral, CommonScale, Result),
              lose_decimal_scale_relation(expected(Expected), produced(Result))
            ].
run_decimal_action(decimal_subtraction_by_aligned_units, Pair, ignored,
                   Outcome, Trace) :-
    aligned_decimal_operands(Pair, N1, S1, N2, S2,
                             CommonScale, Aligned1, Aligned2),
    subtract_ints(Aligned1, Aligned2, DifferenceNumeral),
    decimal_components(DifferenceNumeral, CommonScale, Whole,
                       FractionalDigits, Places, PlaceUnit, Result),
    Outcome = action_outcome(
                  decimal_subtraction_by_aligned_units,
                  [ classification(productive),
                    cluster(decimal_subtraction),
                    automaton_state(decimal_align_operate_reinscribe),
                    vocabulary([common_decimal_unit, scale_alignment,
                                grounded_integer_subtraction,
                                positional_reinscription]),
                    result(Result), expected(Result), validity(correct),
                    operands(decimal_pair(N1, S1, N2, S2)),
                    representation(aligned_decimal_operation(
                        common_scale(CommonScale), left_units(Aligned1),
                        right_units(Aligned2), result_units(DifferenceNumeral))),
                    components(decimal_positional_components(
                        DifferenceNumeral, CommonScale, Whole,
                        FractionalDigits, Places, PlaceUnit)),
                    invariant(subtract_only_after_common_unit_alignment),
                    elaborates(grounded_integer_subtraction)
                  ]),
    Trace = [ identify_operand_scales(S1, S2),
              choose_common_decimal_scale(CommonScale),
              align_decimal_units(N1, S1, Aligned1),
              align_decimal_units(N2, S2, Aligned2),
              subtract_grounded_aligned_units(
                  Aligned1, Aligned2, DifferenceNumeral),
              reinscribe_decimal_result(
                  DifferenceNumeral, CommonScale, Result)
            ].
run_decimal_action(decimal_subtract_unaligned_numerals, Pair, ignored,
                   Outcome, Trace) :-
    aligned_decimal_operands(Pair, N1, S1, N2, S2,
                             CommonScale, Aligned1, Aligned2),
    subtract_ints(Aligned1, Aligned2, ExpectedNumeral),
    subtract_ints(N1, N2, ResultNumeral),
    decimal_components(ExpectedNumeral, CommonScale, _, _, _, _, Expected),
    decimal_components(ResultNumeral, CommonScale, _, _, _, _, Result),
    decimal_result_validity(Expected, Result, Validity),
    Outcome = action_outcome(
                  decimal_subtract_unaligned_numerals,
                  [ classification(deformation),
                    cluster(decimal_subtraction),
                    automaton_state(decimal_align_operate_reinscribe),
                    vocabulary([written_numeral, unaligned_scale,
                                integer_subtraction, scale_unit_loss]),
                    result(Result), expected(Expected), validity(Validity),
                    operands(decimal_pair(N1, S1, N2, S2)),
                    deformation_of(decimal_subtraction_by_aligned_units),
                    misconception_family(decimal_subtract_unaligned_numerals)
                  ]),
    Trace = [ read_written_integer_numerals(N1, N2),
              omit_decimal_scale_alignment(S1, S2),
              subtract_unaligned_numerals(N1, N2, ResultNumeral),
              reinscribe_at_larger_scale(ResultNumeral, CommonScale, Result),
              lose_decimal_scale_relation(expected(Expected), produced(Result))
            ].
run_decimal_action(decimal_place_unit_regrouping, Conversion, ignored,
                   Outcome, Trace) :-
    decimal_unit_conversion_components(Conversion, Components),
    Components = decimal_unit_conversion_components(
                     Count, FromScale, ToScale, Factor, EquivalentCount),
    Result = equivalent_decimal_units(
                 EquivalentCount, unit_fraction(1, ToScale)),
    Outcome = action_outcome(
                  decimal_place_unit_regrouping,
                  [ classification(productive),
                    cluster(decimal_place_unit_equivalence),
                    automaton_state(decimal_recursive_unit_regrouping),
                    vocabulary([decimal_unit, nested_base_ten_unit,
                                regrouping_factor, equivalent_quantity,
                                tenths, hundredths, thousandths]),
                    result(Result), expected(Result), validity(correct),
                    operands(Conversion), components(Components),
                    representation(decimal_unit_chain(
                        copies(Count, unit_fraction(1, FromScale)),
                        factor(Factor),
                        copies(EquivalentCount,
                               unit_fraction(1, ToScale)))),
                    invariant(regroup_count_and_unit_together),
                    elaborates(grounded_integer_multiplication)
                  ]),
    Trace = [ identify_nested_decimal_units(FromScale, ToScale),
              derive_regrouping_factor(FromScale, ToScale, Factor),
              iterate_finer_unit(Count, Factor, EquivalentCount),
              preserve_decimal_quantity(Result)
            ].
run_decimal_action(change_decimal_place_name_without_regrouping, Conversion,
                   ignored, Outcome, Trace) :-
    decimal_unit_conversion_components(Conversion, Components),
    Components = decimal_unit_conversion_components(
                     Count, FromScale, ToScale, _Factor, EquivalentCount),
    Expected = equivalent_decimal_units(
                   EquivalentCount, unit_fraction(1, ToScale)),
    Result = equivalent_decimal_units(Count, unit_fraction(1, ToScale)),
    Outcome = action_outcome(
                  change_decimal_place_name_without_regrouping,
                  [ classification(deformation),
                    cluster(decimal_place_unit_equivalence),
                    automaton_state(decimal_recursive_unit_regrouping),
                    vocabulary([decimal_unit, place_name_change,
                                unchanged_count, scale_unit_loss]),
                    result(Result), expected(Expected), validity(incorrect),
                    operands(Conversion), components(Components),
                    deformation_of(decimal_place_unit_regrouping),
                    misconception_family(
                        change_decimal_place_name_without_regrouping)
                  ]),
    Trace = [ identify_nested_decimal_units(FromScale, ToScale),
              change_decimal_unit_name(FromScale, ToScale),
              retain_original_count(Count),
              omit_regrouping_factor(expected(Expected), produced(Result))
            ].
run_decimal_action(decimal_multiplication_rule, Pair, ignored, Outcome, Trace) :-
    decimal_multiplication_components(Pair, Components),
    Components = decimal_multiplication_components(N1, S1, N2, S2,
                                                   Places1, Places2,
                                                   ProductNumeral,
                                                   SummedPlaces, SummedScale,
                                                   WholeOut, FracOut, PlaceUnitOut),
    Result = decimal(WholeOut, fractional_digits(FracOut, SummedPlaces), PlaceUnitOut),
    Outcome = action_outcome(
                  decimal_multiplication_rule,
                  [ classification(productive),
                    cluster(decimal_multiplication),
                    automaton_state(decimal_place_value_coordination),
                    vocabulary([decimal_mark, fractional_place_count,
                                place_count_sum, integer_numeral_product,
                                decimal_point_placement, scale_unit]),
                    result(Result),
                    expected(Result),
                    validity(correct),
                    operands(decimal_pair(N1, S1, N2, S2)),
                    components(Components),
                    invariant(sum_fractional_place_counts)
                  ]),
    Trace = [ identify_operand_place_counts(Places1, Places2),
              ignore_decimal_marks_momentarily(decimal_pair(N1, S1, N2, S2)),
              multiply_integer_numerals(N1, N2, ProductNumeral),
              sum_fractional_place_counts(Places1, Places2, SummedPlaces),
              place_decimal_point(ProductNumeral, scale(SummedScale)),
              compose_decimal_product(Result)
            ].
run_decimal_action(decimal_point_rule_misapplication, Pair, ignored, Outcome, Trace) :-
    decimal_multiplication_components(Pair, Components),
    Components = decimal_multiplication_components(N1, S1, N2, S2,
                                                   Places1, Places2,
                                                   ProductNumeral,
                                                   SummedPlaces, _SummedScale,
                                                   WholeOut, FracOut, PlaceUnitOut),
    Places1 > 0,
    Places2 > 0,
    MaxPlaces is max(Places1, Places2),
    MaxPlaces < SummedPlaces,
    max_place_scale(MaxPlaces, MaxScale),
    decimal_place_unit(MaxPlaces, MaxPlaceUnit),
    MaxWhole is ProductNumeral // MaxScale,
    MaxFrac is ProductNumeral mod MaxScale,
    Expected = decimal(WholeOut, fractional_digits(FracOut, SummedPlaces), PlaceUnitOut),
    Result = decimal(MaxWhole, fractional_digits(MaxFrac, MaxPlaces), MaxPlaceUnit),
    Outcome = action_outcome(
                  decimal_point_rule_misapplication,
                  [ classification(deformation),
                    cluster(decimal_multiplication),
                    automaton_state(decimal_place_value_coordination),
                    vocabulary([decimal_mark, fractional_place_count,
                                place_count_max, integer_numeral_product,
                                decimal_point_placement, place_count_loss]),
                    result(Result),
                    expected(Expected),
                    validity(incorrect),
                    operands(decimal_pair(N1, S1, N2, S2)),
                    components(Components),
                    deformation_of(decimal_multiplication_rule),
                    misconception_family(decimal_point_rule_misapplication)
                  ]),
    Trace = [ identify_operand_place_counts(Places1, Places2),
              multiply_integer_numerals(N1, N2, ProductNumeral),
              take_max_of_place_counts_instead_of_summing(Places1, Places2, MaxPlaces),
              place_decimal_point(ProductNumeral, scale(MaxScale)),
              lose_fractional_place_count(expected(Expected), produced(Result))
            ].
run_decimal_action(ecuadorian_decimal_long_division, Pair, ignored, Outcome, Trace) :-
    decimal_division_components(Pair, Components),
    Components = decimal_division_components(N1, S1, N2, S2,
                                             Places1, Places2,
                                             MaxPlaces, SharedScale,
                                             ScaledDividend, ScaledDivisor,
                                             IntegerQuotient, IntegerRemainder),
    IntegerRemainder = 0,
    Result = decimal_quotient(IntegerQuotient, IntegerRemainder),
    Outcome = action_outcome(
                  ecuadorian_decimal_long_division,
                  [ classification(productive),
                    cluster(decimal_division),
                    automaton_state(decimal_scale_to_integer_division),
                    vocabulary([decimal_mark, fractional_place_count,
                                shared_scale_factor, scaled_operand,
                                integer_long_division, decimal_quotient]),
                    result(Result),
                    expected(Result),
                    validity(correct),
                    operands(decimal_pair(N1, S1, N2, S2)),
                    components(Components),
                    invariant(scale_both_operands_to_clear_decimals)
                  ]),
    Trace = [ identify_operand_place_counts(Places1, Places2),
              choose_maximum_place_count(MaxPlaces),
              scale_both_operands_by_shared_power_of_ten(SharedScale),
              clear_decimal_points(ScaledDividend, ScaledDivisor),
              divide_as_integers(ScaledDividend, ScaledDivisor,
                                 IntegerQuotient, IntegerRemainder),
              name_decimal_quotient(Result)
            ].
run_decimal_action(recalled_result_scaling, Pair, ignored, Outcome, Trace) :-
    recalled_result_scaling_components(Pair, Components),
    Components = recalled_result_scaling_components(N1, S1, N2, S2,
                                                    BaseDividend, BaseDivisor,
                                                    BaseQuotient, BaseQuotientScale,
                                                    ScaleFactor, ScaledQuotient),
    Result = decimal_quotient(ScaledQuotient, 0),
    Outcome = action_outcome(
                  recalled_result_scaling,
                  [ classification(productive),
                    cluster(decimal_division),
                    automaton_state(decimal_recall_and_scale),
                    vocabulary([recalled_division_fact, base_quotient,
                                place_value_scale_factor, scaled_quotient,
                                quotient_invariance_under_decimal_shift]),
                    result(Result),
                    expected(Result),
                    validity(correct),
                    operands(decimal_pair(N1, S1, N2, S2)),
                    components(Components),
                    invariant(scale_factor_passes_through_quotient)
                  ]),
    Trace = [ recall_base_division_fact(BaseDividend, BaseDivisor,
                                        decimal_value(BaseQuotient, scale(BaseQuotientScale))),
              identify_dividend_scale_factor(ScaleFactor),
              propagate_scale_factor_through_quotient(BaseQuotient, ScaleFactor, ScaledQuotient),
              name_decimal_quotient(Result)
            ].


%!  decimal_action_cluster(+Kind, -Cluster) is det.
decimal_action_cluster(positional_decimal_reading, decimal_positional_notation).
decimal_action_cluster(decimal_whole_number_reading, decimal_positional_notation).
decimal_action_cluster(decimal_comparison_by_aligned_units,
                       decimal_magnitude_comparison).
decimal_action_cluster(decimal_numeral_comparison_without_scale_alignment,
                       decimal_magnitude_comparison).
decimal_action_cluster(decimal_addition_by_aligned_units, decimal_addition).
decimal_action_cluster(decimal_add_unaligned_numerals, decimal_addition).
decimal_action_cluster(decimal_subtraction_by_aligned_units, decimal_subtraction).
decimal_action_cluster(decimal_subtract_unaligned_numerals, decimal_subtraction).
decimal_action_cluster(decimal_place_unit_regrouping,
                       decimal_place_unit_equivalence).
decimal_action_cluster(change_decimal_place_name_without_regrouping,
                       decimal_place_unit_equivalence).
decimal_action_cluster(decimal_multiplication_rule, decimal_multiplication).
decimal_action_cluster(decimal_point_rule_misapplication, decimal_multiplication).
decimal_action_cluster(ecuadorian_decimal_long_division, decimal_division).
decimal_action_cluster(recalled_result_scaling, decimal_division).


%!  decimal_action_vocabulary(+Kind, -Vocabulary) is det.
decimal_action_vocabulary(positional_decimal_reading,
                          [decimal_mark, whole_part, fractional_part,
                           place_value, tenths, hundredths, scale_unit]).
decimal_action_vocabulary(decimal_whole_number_reading,
                          [decimal_mark, whole_number_string, fractional_part,
                           place_value, scale_unit, unit_loss]).
decimal_action_vocabulary(decimal_comparison_by_aligned_units,
                          [decimal_mark, common_decimal_unit,
                           scale_alignment, equivalent_numeral,
                           magnitude_comparison]).
decimal_action_vocabulary(decimal_numeral_comparison_without_scale_alignment,
                          [decimal_mark, written_numeral, unaligned_scale,
                           magnitude_comparison, scale_unit_loss]).
decimal_action_vocabulary(decimal_addition_by_aligned_units,
                          [common_decimal_unit, scale_alignment,
                           grounded_integer_addition,
                           positional_reinscription]).
decimal_action_vocabulary(decimal_add_unaligned_numerals,
                          [written_numeral, unaligned_scale,
                           integer_addition, scale_unit_loss]).
decimal_action_vocabulary(decimal_subtraction_by_aligned_units,
                          [common_decimal_unit, scale_alignment,
                           grounded_integer_subtraction,
                           positional_reinscription]).
decimal_action_vocabulary(decimal_subtract_unaligned_numerals,
                          [written_numeral, unaligned_scale,
                           integer_subtraction, scale_unit_loss]).
decimal_action_vocabulary(decimal_place_unit_regrouping,
                          [decimal_unit, nested_base_ten_unit,
                           regrouping_factor, equivalent_quantity,
                           tenths, hundredths, thousandths]).
decimal_action_vocabulary(change_decimal_place_name_without_regrouping,
                          [decimal_unit, place_name_change,
                           unchanged_count, scale_unit_loss]).
decimal_action_vocabulary(decimal_multiplication_rule,
                          [decimal_mark, fractional_place_count,
                           place_count_sum, integer_numeral_product,
                           decimal_point_placement, scale_unit]).
decimal_action_vocabulary(decimal_point_rule_misapplication,
                          [decimal_mark, fractional_place_count,
                           place_count_max, integer_numeral_product,
                           decimal_point_placement, place_count_loss]).
decimal_action_vocabulary(ecuadorian_decimal_long_division,
                          [decimal_mark, fractional_place_count,
                           shared_scale_factor, scaled_operand,
                           integer_long_division, decimal_quotient]).
decimal_action_vocabulary(recalled_result_scaling,
                          [recalled_division_fact, base_quotient,
                           place_value_scale_factor, scaled_quotient,
                           quotient_invariance_under_decimal_shift]).


%!  productive_decimal_deformation(+ProductiveKind, +DeformationKind, -Family) is det.
productive_decimal_deformation(positional_decimal_reading,
                               decimal_whole_number_reading,
                               decimal_whole_number_reading).
productive_decimal_deformation(
    decimal_comparison_by_aligned_units,
    decimal_numeral_comparison_without_scale_alignment,
    decimal_numeral_comparison_without_scale_alignment).
productive_decimal_deformation(decimal_addition_by_aligned_units,
                               decimal_add_unaligned_numerals,
                               decimal_add_unaligned_numerals).
productive_decimal_deformation(decimal_subtraction_by_aligned_units,
                               decimal_subtract_unaligned_numerals,
                               decimal_subtract_unaligned_numerals).
productive_decimal_deformation(
    decimal_place_unit_regrouping,
    change_decimal_place_name_without_regrouping,
    change_decimal_place_name_without_regrouping).
productive_decimal_deformation(decimal_multiplication_rule,
                               decimal_point_rule_misapplication,
                               decimal_point_rule_misapplication).


%!  decimal_action_misconception_hook(+Outcome, -Family, -Hook) is semidet.
decimal_action_misconception_hook(action_outcome(Kind, Fields), Family, Hook) :-
    member(classification(deformation), Fields),
    member(misconception_family(Family), Fields),
    member(deformation_of(ProductiveKind), Fields),
    member(vocabulary(Vocabulary), Fields),
    Hook = action_misconception_hook(
               [ deformation(Kind),
                 deformation_of(ProductiveKind),
                 family(Family),
                 vocabulary(Vocabulary),
                 repair(recover_productive_action(ProductiveKind)),
                 evidence(Fields)
               ]).
decimal_action_misconception_hook(action_outcome(Kind, Fields), Family, Hook) :-
    member(classification(productive), Fields),
    productive_decimal_deformation(Kind, DeformationKind, Family),
    member(vocabulary(Vocabulary), Fields),
    Hook = action_misconception_hook(
               [ productive_action(Kind),
                 nearby_deformation(DeformationKind),
                 family(Family),
                 vocabulary(Vocabulary),
                 monitoring_focus(preserve_decimal_place_value(Kind)),
                 evidence(Fields)
               ]).


decimal_components(Numeral, Scale, Whole, FractionalDigits, Places, PlaceUnit, Result) :-
    nonnegative_integer(Numeral),
    decimal_scale(Scale, Places, PlaceUnit),
    Whole is Numeral // Scale,
    FractionalDigits is Numeral mod Scale,
    Result = decimal(Whole, fractional_digits(FractionalDigits, Places), PlaceUnit).


decimal_comparison_components(
    decimal_pair(N1, S1, N2, S2),
    decimal_comparison_components(N1, S1, N2, S2,
                                  CommonScale, Aligned1, Aligned2, Relation)) :-
    maplist(nonnegative_integer, [N1, N2]),
    decimal_scale(S1, _, _),
    decimal_scale(S2, _, _),
    CommonScale is max(S1, S2),
    Aligned1 is N1 * (CommonScale // S1),
    Aligned2 is N2 * (CommonScale // S2),
    comparison_relation(Aligned1, Aligned2, Relation).


aligned_decimal_operands(decimal_pair(N1, S1, N2, S2),
                         N1, S1, N2, S2,
                         CommonScale, Aligned1, Aligned2) :-
    maplist(nonnegative_integer, [N1, N2]),
    decimal_scale(S1, _, _),
    decimal_scale(S2, _, _),
    CommonScale is max(S1, S2),
    Aligned1 is N1 * (CommonScale // S1),
    Aligned2 is N2 * (CommonScale // S2).


decimal_unit_conversion_components(
    decimal_unit_conversion(Count, FromScale, ToScale),
    decimal_unit_conversion_components(
        Count, FromScale, ToScale, Factor, EquivalentCount)) :-
    nonnegative_integer(Count),
    decimal_scale(FromScale, _, _),
    decimal_scale(ToScale, _, _),
    ToScale > FromScale,
    ToScale mod FromScale =:= 0,
    Factor is ToScale // FromScale,
    multiply_ints(Count, Factor, EquivalentCount).


comparison_relation(A, B, less) :- A < B, !.
comparison_relation(A, B, more) :- A > B, !.
comparison_relation(_, _, equal).


comparison_validity(Expected, Expected, accidentally_correct) :- !.
comparison_validity(_, _, incorrect).


decimal_result_validity(Expected, Expected, accidentally_correct) :- !.
decimal_result_validity(_, _, incorrect).


decimal_scale(Scale, Places, PlaceUnit) :-
    integer(Scale),
    Scale > 1,
    power_of_ten_places(Scale, Places),
    decimal_place_unit(Places, PlaceUnit).


power_of_ten_places(10, 1) :-
    !.
power_of_ten_places(Scale, Places) :-
    Scale > 10,
    Scale mod 10 =:= 0,
    NextScale is Scale // 10,
    power_of_ten_places(NextScale, NextPlaces),
    Places is NextPlaces + 1.


decimal_place_unit(0, units).
decimal_place_unit(1, tenths).
decimal_place_unit(2, hundredths).
decimal_place_unit(3, thousandths).
decimal_place_unit(Places, decimal_places(Places)) :-
    Places > 3.


nonnegative_integer(N) :-
    integer(N),
    N >= 0.


% positive_integer/1 imported from math(integer_helpers).


%!  decimal_multiplication_components(+Pair, -Components) is semidet.
%
%   Decompose a decimal-multiplication operand pair into the integer
%   numerals, place counts, integer-numeral product, summed place count,
%   summed scale, and the productive whole/fractional parts of the
%   product.
decimal_multiplication_components(decimal_pair(N1, S1, N2, S2),
        decimal_multiplication_components(N1, S1, N2, S2,
                                          Places1, Places2,
                                          ProductNumeral,
                                          SummedPlaces, SummedScale,
                                          WholeOut, FracOut, PlaceUnitOut)) :-
    nonnegative_integer(N1),
    nonnegative_integer(N2),
    operand_place_count(S1, Places1),
    operand_place_count(S2, Places2),
    ProductNumeral is N1 * N2,
    SummedPlaces is Places1 + Places2,
    summed_scale(SummedPlaces, SummedScale),
    WholeOut is ProductNumeral // SummedScale,
    FracOut is ProductNumeral mod SummedScale,
    decimal_place_unit(SummedPlaces, PlaceUnitOut).


%!  decimal_division_components(+Pair, -Components) is semidet.
%
%   Decompose a decimal-division operand pair for the "scale both
%   operands by a shared power of ten" pre-processing step. Both
%   operands are scaled to the same SharedScale (the larger of the two
%   denominators), which clears the decimal mark from each.
decimal_division_components(decimal_pair(N1, S1, N2, S2),
        decimal_division_components(N1, S1, N2, S2,
                                    Places1, Places2,
                                    MaxPlaces, SharedScale,
                                    ScaledDividend, ScaledDivisor,
                                    IntegerQuotient, IntegerRemainder)) :-
    nonnegative_integer(N1),
    positive_integer(N2),
    operand_place_count(S1, Places1),
    operand_place_count(S2, Places2),
    MaxPlaces is max(Places1, Places2),
    summed_scale(MaxPlaces, SharedScale),
    S1Effective is max(S1, 1),
    S2Effective is max(S2, 1),
    ScaledDividend is N1 * (SharedScale // S1Effective),
    ScaledDivisor is N2 * (SharedScale // S2Effective),
    ScaledDivisor > 0,
    IntegerQuotient is ScaledDividend // ScaledDivisor,
    IntegerRemainder is ScaledDividend mod ScaledDivisor.


%!  recalled_result_scaling_components(+Pair, -Components) is semidet.
%
%   Decompose a recalled-base-fact division. Models extract-026
%   (Fluckiger): the learner recalls a base division fact such as
%   6 / 5 = 1.2, identifies that the actual dividend is a power-of-ten
%   multiple of the base dividend (e.g. 600 = 6 * 100), and propagates
%   the scale factor through the recalled quotient (1.2 * 100 = 120).
%
%   The pair is restricted to integer-valued operands (S1 = S2 = 1)
%   because the recall path is over base division facts; the
%   place-value scale factor lives in the dividend's trailing zeros.
recalled_result_scaling_components(
    decimal_pair(N1, S1, N2, S2),
    recalled_result_scaling_components(N1, S1, N2, S2,
                                       BaseDividend, BaseDivisor,
                                       BaseQuotient, BaseQuotientScale,
                                       ScaleFactor, ScaledQuotient)) :-
    positive_integer(N1),
    positive_integer(N2),
    S1 =:= 1,
    S2 =:= 1,
    base_scaling_factor(N1, BaseDividend, ScaleFactor),
    BaseDivisor = N2,
    base_division_fact(BaseDividend, BaseDivisor,
                       BaseQuotient, BaseQuotientScale),
    ProductTimesScale is BaseQuotient * ScaleFactor,
    0 =:= ProductTimesScale mod BaseQuotientScale,
    ScaledQuotient is ProductTimesScale // BaseQuotientScale.


operand_place_count(S, Places) :-
    ( integer(S), S =:= 1
    -> Places = 0
    ;  decimal_scale(S, Places, _)
    ).


summed_scale(0, 1) :- !.
summed_scale(Places, Scale) :-
    Places > 0,
    pow10(Places, Scale).


pow10(0, 1) :- !.
pow10(N, Result) :-
    N > 0,
    N1 is N - 1,
    pow10(N1, Sub),
    Result is Sub * 10.


max_place_scale(Places, Scale) :-
    pow10(Places, Scale).


%!  base_scaling_factor(+Numerator, -BaseDividend, -ScaleFactor) is semidet.
%
%   Given an integer-valued dividend like 600, find a shorter base
%   dividend (6) and the corresponding place-value scale factor (100).
%   Only succeeds when N has at least one trailing zero; otherwise the
%   recall path does not apply and the caller should fall through to
%   the long-division automaton.
base_scaling_factor(N, BaseDividend, ScaleFactor) :-
    integer(N),
    N > 0,
    N mod 10 =:= 0,
    drop_trailing_zeros(N, BaseDividend, ScaleFactor),
    ScaleFactor > 1.


drop_trailing_zeros(N, Base, Factor) :-
    drop_trailing_zeros_(N, 1, Base, Factor).

drop_trailing_zeros_(Current, FactorAcc, Base, Factor) :-
    Current mod 10 =:= 0,
    Current > 0,
    !,
    Next is Current // 10,
    NextFactor is FactorAcc * 10,
    drop_trailing_zeros_(Next, NextFactor, Base, Factor).
drop_trailing_zeros_(Current, FactorAcc, Current, FactorAcc).


%!  base_division_fact(+Dividend, +Divisor, -Quotient, -QuotientScale) is semidet.
%
%   Closed knowledge base of recalled base division facts. Each row is a
%   quotient expressed as Numerator/Scale (e.g. 6 / 5 = 12 / 10).
%   Extract-026 (Fluckiger) names 6 / 5 = 1.2 explicitly; the other rows
%   cover the same recall pattern for adjacent operands.
base_division_fact(6, 5, 12, 10).
base_division_fact(3, 5, 6, 10).
base_division_fact(9, 5, 18, 10).
base_division_fact(12, 5, 24, 10).
base_division_fact(4, 5, 8, 10).
base_division_fact(7, 5, 14, 10).
base_division_fact(8, 5, 16, 10).
base_division_fact(2, 5, 4, 10).
base_division_fact(1, 5, 2, 10).
base_division_fact(11, 5, 22, 10).
base_division_fact(15, 4, 375, 100).
base_division_fact(5, 4, 125, 100).
base_division_fact(3, 4, 75, 100).
base_division_fact(9, 4, 225, 100).
base_division_fact(7, 4, 175, 100).
base_division_fact(N, D, Q, 1) :-
    integer(N), integer(D), D > 0,
    Q is N // D,
    N mod D =:= 0.
