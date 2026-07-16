:- module(misconceptions_rational_batch_1, []).
% rational-number misconceptions — direct solo batch 1.
% Native arithmetic/symbolic layer only.

:- multifile test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.

test_harness:arith_misconception(db_row(37495), rational, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(37501), rational, too_vague, skip, none, none).

% Natural-number/additive schemas applied to rational magnitude.
r37579_missing_piece_compare(compare(frac(2,3), frac(3,4)), equal).
r37580_fraction_digits_as_decimal(decimal_for_fraction(frac(1,8)), 0.8).
r37645_decimal_fraction_not_equivalent(equivalent(frac(3,6), decimal(0.50)), false).
r37942_operation_outcome_blocks_solution(solve(div(6, x) = 14), impossible).
r37943_unknown_must_be_natural(solve(6 * x = 11), no_natural_solution).
r37944_bigger_denominator_bigger(compare(frac(1,5), frac(1,7)), greater(frac(1,7))).
r37945_no_decimal_between(count_between(0.005, 0.006), 0).
r37978_eighth_as_point_eight(decimal_for_fraction(frac(1,8)), 0.8).
r37996_mult_equation_no_fraction_solution(solve(8 * x = 3), no_solution).
r38020_long_repeating_assumed_irrational(number_status(frac(1,7)), irrational).
r38065_decimal_interval_discrete(count_between(1.2, 1.3), finite(0)).
r38079_same_numerator_bigger_denominator(compare(frac(2,5), frac(2,7)), greater(frac(2,7))).
r38092_no_decimal_between(count_between(0.3, 0.4), 0).
r38145_no_decimal_between(count_between(5.31, 5.32), 0).
r38148_multiplication_always_exceeds_factor(greater_than(product(0.71,3), 3), true).
r38152_repeating_nines_less_than_one(compare(decimal_repeating(0,9), 1), less_than).
r38167_reverse_quotative_division(grain_pounds(money(0.50), price_per_pound(1.68)), 3.36).
r38189_rational_interval_discrete(count_between(rational_a, rational_b), 0).
r38190_immediate_successor_exists(successor(decimal(0.5)), exists_but_unknown).
r38265_repeating_nines_less_than_one(compare(decimal_repeating(0,9), 1), less_than).
r38298_forms_unrelated(equivalent_forms(frac(1,2), decimal(0.5), percent(50)), unrelated).
r38384_next_rational_exists(next_after(rational_point), exists).
r38443_multiplication_makes_bigger(scale_effect(0.5), bigger).
r38533_repeating_decimal_only_approx(equivalent(decimal_repeating(0,3), frac(1,3)), approximate).
r38535_noninteger_means_prime(prime_status(pi), prime).
r38561_addition_must_increase(statement_can_be_true(3 + 12*z < 3), false).
r38562_decimal_interval_discrete(count_between(0.005, 0.006), 0).
r38751_next_rational_exists(next_after(rational_point), exists).
r38877_not_whole_means_irrational(number_status(frac(1,2)), irrational).
r38878_rational_irrational_same_cardinality(compare_cardinality(rationals, irrationals), same_cardinality).
r38925_benny_fraction_decimal_collapse(values(frac(3,2), frac(2,3)), values(0.5, 0.5)).
r39030_representation_relative_answer(add(2, decimal(0.3)), 0.5).
r39104_division_makes_smaller_operation_choice(cost(0.75, litres, price_per_litre(5)), divide).
r39111_repeating_decimal_tends_to_fraction(equivalent(decimal_repeating(0,3), frac(1,3)), tends_to).
r39158_division_unrelated_to_fraction(equivalent(division(3,4), frac(3,4)), unrelated).
r39228_reference_unit_ignored(remaining_after_eating(half_cake, quarter_of_remaining), frac(1,4)).
r39231_repeating_decimals_nearly_one(add(decimal_repeating(0,3), decimal_repeating(0,6)), nearly(1)).
r39241_fallacious_sqrt4_irrational(number_status(sqrt(4)), irrational).
r39261_number_between_repeating_and_fraction(exists_between(frac(1,3), decimal_repeating(0,3)), true).
r39279_division_can_increase_false(statement_can_be_true(5 / x > 5), false).
r39310_shape_feature_equivalence(compare_representations(frac(1,2), frac(3,5)), equal).
r39364_longer_decimal_bigger(compare(0.021, 0.87), greater(0.021)).
r39382_decimal_as_whole_number(compare(0.34, 0.8), greater(0.34)).
r39383_decimal_point_after_digit_sum(5 + 0.3, 0.8).
r39479_only_one_between_fractions(count_between(frac(3,8), frac(5,8)), 1).
r39480_tail_digits_compare(compare(0.65, 0.8), greater(0.65)).
r39481_fraction_multiplier_assumed_smaller(less_than(product(50, frac(3,2)), 50), true).
r39504_rationals_finite(cardinality(rationals_between_0_and_1), finite).
r39505_all_infinities_equal(compare_cardinality(rationals, irrationals), same_cardinality).
r39506_consecutive_irrationals_exist(consecutive(irrational_a, irrational_b), true).
r39514_finite_between_fractions(count_between(frac(3,5), frac(4,5)), finite).
r39758_base_parts_converted_separately(base_five_to_decimal(12.34), 7.19).
r39837_one_third_as_three_percent(percent_for_fraction(frac(1,3)), 3).
r39857_one_and_half_as_one_fifth(decimal_or_fraction_for(one_and_half), frac(1,5)).
r40161_i_as_irrational(number_status(i), irrational).
r40218_exact_fraction_forced_decimal(solution(3*x = 2), 0.6).
r40429_decimal_quotient_guess(5 / 2, 3).
r40541_fraction_display_irrrational(number_status(frac(23,43)), irrational).
r40542_cycle_length_as_required_test(rationality_test(frac(23,43)), need_42_digits).
r40553_no_decimal_between(count_between(1.2, 1.3), 0).

test_harness:arith_misconception(db_row(37579), rational, missing_piece_compare,
    misconceptions_rational_batch_1:r37579_missing_piece_compare,
    compare(frac(2,3), frac(3,4)), greater(frac(3,4))).
test_harness:arith_misconception(db_row(37580), rational, fraction_digits_as_decimal,
    misconceptions_rational_batch_1:r37580_fraction_digits_as_decimal,
    decimal_for_fraction(frac(1,8)), 0.125).
test_harness:arith_misconception(db_row(37614), rational, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(37645), rational, decimal_fraction_not_equivalent,
    misconceptions_rational_batch_1:r37645_decimal_fraction_not_equivalent,
    equivalent(frac(3,6), decimal(0.50)), true).
test_harness:arith_misconception(db_row(37784), rational, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(37785), rational, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(37931), rational, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(37942), rational, operation_outcome_blocks_solution,
    misconceptions_rational_batch_1:r37942_operation_outcome_blocks_solution,
    solve(div(6, x) = 14), frac(3,7)).
test_harness:arith_misconception(db_row(37943), rational, unknown_must_be_natural,
    misconceptions_rational_batch_1:r37943_unknown_must_be_natural,
    solve(6 * x = 11), frac(11,6)).
test_harness:arith_misconception(db_row(37944), rational, bigger_denominator_bigger,
    misconceptions_rational_batch_1:r37944_bigger_denominator_bigger,
    compare(frac(1,5), frac(1,7)), greater(frac(1,5))).
test_harness:arith_misconception(db_row(37945), rational, rational_interval_discrete,
    misconceptions_rational_batch_1:r37945_no_decimal_between,
    count_between(0.005, 0.006), infinite).
test_harness:arith_misconception(db_row(37978), rational, eighth_as_point_eight,
    misconceptions_rational_batch_1:r37978_eighth_as_point_eight,
    decimal_for_fraction(frac(1,8)), 0.125).
test_harness:arith_misconception(db_row(37996), rational, mult_equation_no_fraction_solution,
    misconceptions_rational_batch_1:r37996_mult_equation_no_fraction_solution,
    solve(8 * x = 3), frac(3,8)).
test_harness:arith_misconception(db_row(38020), rational, long_repeating_assumed_irrational,
    misconceptions_rational_batch_1:r38020_long_repeating_assumed_irrational,
    number_status(frac(1,7)), rational).
test_harness:arith_misconception(db_row(38065), rational, rational_interval_discrete,
    misconceptions_rational_batch_1:r38065_decimal_interval_discrete,
    count_between(1.2, 1.3), infinite).
test_harness:arith_misconception(db_row(38066), rational, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38079), rational, same_numerator_bigger_denominator,
    misconceptions_rational_batch_1:r38079_same_numerator_bigger_denominator,
    compare(frac(2,5), frac(2,7)), greater(frac(2,5))).
test_harness:arith_misconception(db_row(38092), rational, rational_interval_discrete,
    misconceptions_rational_batch_1:r38092_no_decimal_between,
    count_between(0.3, 0.4), infinite).
test_harness:arith_misconception(db_row(38145), rational, rational_interval_discrete,
    misconceptions_rational_batch_1:r38145_no_decimal_between,
    count_between(5.31, 5.32), infinite).
test_harness:arith_misconception(db_row(38148), rational, multiplication_always_exceeds_factor,
    misconceptions_rational_batch_1:r38148_multiplication_always_exceeds_factor,
    greater_than(product(0.71,3), 3), false).
test_harness:arith_misconception(db_row(38152), rational, repeating_decimal_less_than_one,
    misconceptions_rational_batch_1:r38152_repeating_nines_less_than_one,
    compare(decimal_repeating(0,9), 1), equal).
test_harness:arith_misconception(db_row(38167), rational, reverse_quotative_division,
    misconceptions_rational_batch_1:r38167_reverse_quotative_division,
    grain_pounds(money(0.50), price_per_pound(1.68)), 0.2976190476190476).
test_harness:arith_misconception(db_row(38189), rational, rational_interval_discrete,
    misconceptions_rational_batch_1:r38189_rational_interval_discrete,
    count_between(rational_a, rational_b), infinite).
test_harness:arith_misconception(db_row(38190), rational, immediate_successor_exists,
    misconceptions_rational_batch_1:r38190_immediate_successor_exists,
    successor(decimal(0.5)), no_immediate_successor).
test_harness:arith_misconception(db_row(38192), rational, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38265), rational, repeating_decimal_less_than_one,
    misconceptions_rational_batch_1:r38265_repeating_nines_less_than_one,
    compare(decimal_repeating(0,9), 1), equal).
test_harness:arith_misconception(db_row(38298), rational, forms_unrelated,
    misconceptions_rational_batch_1:r38298_forms_unrelated,
    equivalent_forms(frac(1,2), decimal(0.5), percent(50)), equal).
test_harness:arith_misconception(db_row(38331), rational, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38347), rational, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38384), rational, next_rational_exists,
    misconceptions_rational_batch_1:r38384_next_rational_exists,
    next_after(rational_point), no_next).
test_harness:arith_misconception(db_row(38443), rational, multiplication_makes_bigger,
    misconceptions_rational_batch_1:r38443_multiplication_makes_bigger,
    scale_effect(0.5), smaller).
test_harness:arith_misconception(db_row(38533), rational, repeating_decimal_only_approx,
    misconceptions_rational_batch_1:r38533_repeating_decimal_only_approx,
    equivalent(decimal_repeating(0,3), frac(1,3)), equal).
test_harness:arith_misconception(db_row(38535), rational, noninteger_means_prime,
    misconceptions_rational_batch_1:r38535_noninteger_means_prime,
    prime_status(pi), not_prime).
test_harness:arith_misconception(db_row(38561), rational, addition_must_increase,
    misconceptions_rational_batch_1:r38561_addition_must_increase,
    statement_can_be_true(3 + 12*z < 3), true).
test_harness:arith_misconception(db_row(38562), rational, rational_interval_discrete,
    misconceptions_rational_batch_1:r38562_decimal_interval_discrete,
    count_between(0.005, 0.006), infinite).
test_harness:arith_misconception(db_row(38722), rational, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38751), rational, next_rational_exists,
    misconceptions_rational_batch_1:r38751_next_rational_exists,
    next_after(rational_point), no_next).
test_harness:arith_misconception(db_row(38770), rational, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38877), rational, not_whole_means_irrational,
    misconceptions_rational_batch_1:r38877_not_whole_means_irrational,
    number_status(frac(1,2)), rational).
test_harness:arith_misconception(db_row(38878), rational, rational_irrational_same_cardinality,
    misconceptions_rational_batch_1:r38878_rational_irrational_same_cardinality,
    compare_cardinality(rationals, irrationals), irrationals_larger).
test_harness:arith_misconception(db_row(38925), rational, benny_fraction_decimal_collapse,
    misconceptions_rational_batch_1:r38925_benny_fraction_decimal_collapse,
    values(frac(3,2), frac(2,3)), values(1.5, 0.6666666666666666)).
test_harness:arith_misconception(db_row(38956), rational, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38974), rational, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39030), rational, representation_relative_answer,
    misconceptions_rational_batch_1:r39030_representation_relative_answer,
    add(2, decimal(0.3)), 2.3).
test_harness:arith_misconception(db_row(39104), rational, division_makes_smaller_operation_choice,
    misconceptions_rational_batch_1:r39104_division_makes_smaller_operation_choice,
    cost(0.75, litres, price_per_litre(5)), multiply).
test_harness:arith_misconception(db_row(39111), rational, repeating_decimal_tends_to_fraction,
    misconceptions_rational_batch_1:r39111_repeating_decimal_tends_to_fraction,
    equivalent(decimal_repeating(0,3), frac(1,3)), equal).
test_harness:arith_misconception(db_row(39156), rational, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39157), rational, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39158), rational, division_unrelated_to_fraction,
    misconceptions_rational_batch_1:r39158_division_unrelated_to_fraction,
    equivalent(division(3,4), frac(3,4)), equal).
test_harness:arith_misconception(db_row(39226), rational, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39227), rational, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39228), rational, reference_unit_ignored,
    misconceptions_rational_batch_1:r39228_reference_unit_ignored,
    remaining_after_eating(half_cake, quarter_of_remaining), frac(3,8)).
test_harness:arith_misconception(db_row(39231), rational, repeating_decimals_nearly_one,
    misconceptions_rational_batch_1:r39231_repeating_decimals_nearly_one,
    add(decimal_repeating(0,3), decimal_repeating(0,6)), 1).
test_harness:arith_misconception(db_row(39241), rational, fallacious_sqrt4_irrational,
    misconceptions_rational_batch_1:r39241_fallacious_sqrt4_irrational,
    number_status(sqrt(4)), rational).
test_harness:arith_misconception(db_row(39251), rational, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39261), rational, number_between_repeating_and_fraction,
    misconceptions_rational_batch_1:r39261_number_between_repeating_and_fraction,
    exists_between(frac(1,3), decimal_repeating(0,3)), false).
test_harness:arith_misconception(db_row(39279), rational, division_can_increase_false,
    misconceptions_rational_batch_1:r39279_division_can_increase_false,
    statement_can_be_true(5 / x > 5), true).
test_harness:arith_misconception(db_row(39310), rational, shape_feature_equivalence,
    misconceptions_rational_batch_1:r39310_shape_feature_equivalence,
    compare_representations(frac(1,2), frac(3,5)), not_equal).
test_harness:arith_misconception(db_row(39311), rational, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39364), rational, longer_decimal_bigger,
    misconceptions_rational_batch_1:r39364_longer_decimal_bigger,
    compare(0.021, 0.87), greater(0.87)).
test_harness:arith_misconception(db_row(39381), rational, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39382), rational, decimal_as_whole_number,
    misconceptions_rational_batch_1:r39382_decimal_as_whole_number,
    compare(0.34, 0.8), greater(0.8)).
test_harness:arith_misconception(db_row(39383), rational, decimal_point_after_digit_sum,
    misconceptions_rational_batch_1:r39383_decimal_point_after_digit_sum,
    5 + 0.3, 5.3).
test_harness:arith_misconception(db_row(39479), rational, rational_interval_discrete,
    misconceptions_rational_batch_1:r39479_only_one_between_fractions,
    count_between(frac(3,8), frac(5,8)), infinite).
test_harness:arith_misconception(db_row(39480), rational, tail_digits_compare,
    misconceptions_rational_batch_1:r39480_tail_digits_compare,
    compare(0.65, 0.8), greater(0.8)).
test_harness:arith_misconception(db_row(39481), rational, fraction_multiplier_assumed_smaller,
    misconceptions_rational_batch_1:r39481_fraction_multiplier_assumed_smaller,
    less_than(product(50, frac(3,2)), 50), false).
test_harness:arith_misconception(db_row(39504), rational, rationals_finite,
    misconceptions_rational_batch_1:r39504_rationals_finite,
    cardinality(rationals_between_0_and_1), countably_infinite).
test_harness:arith_misconception(db_row(39505), rational, all_infinities_equal,
    misconceptions_rational_batch_1:r39505_all_infinities_equal,
    compare_cardinality(rationals, irrationals), irrationals_larger).
test_harness:arith_misconception(db_row(39506), rational, consecutive_irrationals_exist,
    misconceptions_rational_batch_1:r39506_consecutive_irrationals_exist,
    consecutive(irrational_a, irrational_b), false).
test_harness:arith_misconception(db_row(39514), rational, finite_between_fractions,
    misconceptions_rational_batch_1:r39514_finite_between_fractions,
    count_between(frac(3,5), frac(4,5)), infinite).
test_harness:arith_misconception(db_row(39648), rational, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39683), rational, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39758), rational, base_parts_converted_separately,
    misconceptions_rational_batch_1:r39758_base_parts_converted_separately,
    base_five_to_decimal(12.34), 7.76).
test_harness:arith_misconception(db_row(39837), rational, one_third_as_three_percent,
    misconceptions_rational_batch_1:r39837_one_third_as_three_percent,
    percent_for_fraction(frac(1,3)), 33.333333333333336).
test_harness:arith_misconception(db_row(39857), rational, one_and_half_as_one_fifth,
    misconceptions_rational_batch_1:r39857_one_and_half_as_one_fifth,
    decimal_or_fraction_for(one_and_half), 1.5).
test_harness:arith_misconception(db_row(39865), rational, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39895), rational, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(40158), rational, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(40160), rational, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(40161), rational, i_as_irrational,
    misconceptions_rational_batch_1:r40161_i_as_irrational,
    number_status(i), imaginary_not_real).
test_harness:arith_misconception(db_row(40218), rational, exact_fraction_forced_decimal,
    misconceptions_rational_batch_1:r40218_exact_fraction_forced_decimal,
    solution(3*x = 2), frac(2,3)).
test_harness:arith_misconception(db_row(40274), rational, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(40429), rational, decimal_quotient_guess,
    misconceptions_rational_batch_1:r40429_decimal_quotient_guess,
    5 / 2, 2.5).
test_harness:arith_misconception(db_row(40541), rational, fraction_display_irrational,
    misconceptions_rational_batch_1:r40541_fraction_display_irrrational,
    number_status(frac(23,43)), rational).
test_harness:arith_misconception(db_row(40542), rational, cycle_length_as_required_test,
    misconceptions_rational_batch_1:r40542_cycle_length_as_required_test,
    rationality_test(frac(23,43)), rational_by_fraction_form).
test_harness:arith_misconception(db_row(40553), rational, rational_interval_discrete,
    misconceptions_rational_batch_1:r40553_no_decimal_between,
    count_between(1.2, 1.3), infinite).
test_harness:arith_misconception(db_row(40554), rational, too_vague, skip, none, none).
