:- module(misconceptions_percent_batch_1, []).
% percent misconceptions — direct solo batch 1.
% Native arithmetic layer only.

:- multifile test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.

% === row 37659: total percent not anchored at 100 ===
% Task: percent representing the total.
% Correct: 100.
% Error: 200, choosing a large number as "more total."
% SCHEMA: Container.
% GROUNDED: TODO bind percent whole to a fixed base of 100.
% CONNECTS TO: s(comp_nec(unlicensed(percent_total_not_100)))
r37659_percent_total_not_100(total_percent, 200).

test_harness:arith_misconception(db_row(37659), percent, percent_total_not_100,
    misconceptions_percent_batch_1:r37659_percent_total_not_100,
    total_percent,
    100).

test_harness:arith_misconception(db_row(37660), percent, too_vague, skip, none, none).

% === row 37661: reversed percent-of equation ===
% Task: 21% of 400.
% Correct: 84.
% Error: solves 21% * n = 400, giving about 1904.76.
% SCHEMA: Source-Path-Goal.
% GROUNDED: TODO preserve base/part roles in percent equation.
% CONNECTS TO: s(comp_nec(unlicensed(reverse_percent_equation)))
r37661_reverse_percent_equation(percent_of(21, 400), Got) :-
    Got is 400 / (21 / 100).

test_harness:arith_misconception(db_row(37661), percent, reverse_percent_equation,
    misconceptions_percent_batch_1:r37661_reverse_percent_equation,
    percent_of(21, 400),
    84).

test_harness:arith_misconception(db_row(38014), percent, too_vague, skip, none, none).

% === row 38015: percent discount treated as currency amount ===
% Task: 40% discount on 89.
% Correct final price: 53.4.
% Error: 49, subtracting 40 as an absolute amount.
% SCHEMA: Measuring Stick.
% GROUNDED: TODO convert percent to a proportion of the base amount.
% CONNECTS TO: s(comp_nec(unlicensed(percent_as_absolute_amount)))
r38015_percent_as_absolute_amount(final_price(89, 40), 49).

test_harness:arith_misconception(db_row(38015), percent, percent_as_absolute_amount,
    misconceptions_percent_batch_1:r38015_percent_as_absolute_amount,
    final_price(89, 40),
    53.4).

test_harness:arith_misconception(db_row(38051), percent, too_vague, skip, none, none).

% === row 38149: sequential percent increases added on original base ===
% Task: 1000 increased by 20%, then 20% again.
% Correct: 1440.
% Error: 1400, adding 20% + 20% on the original base.
% SCHEMA: Source-Path-Goal.
% GROUNDED: TODO update the base after each percentage change.
% CONNECTS TO: s(comp_nec(unlicensed(add_percent_rates_on_original_base)))
r38149_add_rates_original_base(compound_increase(1000, [20,20]), 1400).

test_harness:arith_misconception(db_row(38149), percent, add_percent_rates_on_original_base,
    misconceptions_percent_batch_1:r38149_add_rates_original_base,
    compound_increase(1000, [20,20]),
    1440).

% === row 38155: part-to-part ratio used for percent shaded ===
% Task: 6 shaded, 2 unshaded.
% Correct: 75%.
% Error: about 33.33%, using unshaded/shaded.
% SCHEMA: Container.
% GROUNDED: TODO take part over whole, not part over complementary part.
% CONNECTS TO: s(comp_nec(unlicensed(part_to_part_as_percent)))
r38155_part_to_part_percent(shaded_unshaded(6, 2), Got) :-
    Got is 100 * 2 / 6.

test_harness:arith_misconception(db_row(38155), percent, part_to_part_as_percent,
    misconceptions_percent_batch_1:r38155_part_to_part_percent,
    shaded_unshaded(6, 2),
    75).

test_harness:arith_misconception(db_row(38267), percent, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38808), percent, too_vague, skip, none, none).

% === row 38809: container size halves the percent ===
% Task: smaller jar from the same 60% fruit mixture.
% Correct: 60.
% Error: 30, halving the percent with the jar size.
% SCHEMA: Container.
% GROUNDED: TODO keep intensive composition invariant under scaling.
% CONNECTS TO: s(comp_nec(unlicensed(scale_percent_with_container)))
r38809_scale_percent_with_container(same_mixture_percent(60, half_size), 30).

test_harness:arith_misconception(db_row(38809), percent, scale_percent_with_container,
    misconceptions_percent_batch_1:r38809_scale_percent_with_container,
    same_mixture_percent(60, half_size),
    60).

% === row 38810: percent subtracted as grams ===
% Task: 60% of 450 grams.
% Correct: 270.
% Error: 390, calculating 450 - 60.
% SCHEMA: Measuring Stick.
% GROUNDED: TODO interpret the percent as a ratio before applying to mass.
% CONNECTS TO: s(comp_nec(unlicensed(percent_as_subtracted_units)))
r38810_percent_as_subtracted_units(fruit_grams(450, 60), 390).

test_harness:arith_misconception(db_row(38810), percent, percent_as_subtracted_units,
    misconceptions_percent_batch_1:r38810_percent_as_subtracted_units,
    fruit_grams(450, 60),
    270).

% === row 38811: percent extra equated with same percent discount ===
% Task: discount equivalent to 25% extra free.
% Correct: 20%.
% Error: 25%.
% SCHEMA: Source-Path-Goal.
% GROUNDED: TODO recompute percent from the enlarged base.
% CONNECTS TO: s(comp_nec(unlicensed(same_percent_after_base_change)))
r38811_same_percent_after_base_change(equivalent_discount_for_extra(25), 25).

test_harness:arith_misconception(db_row(38811), percent, same_percent_after_base_change,
    misconceptions_percent_batch_1:r38811_same_percent_after_base_change,
    equivalent_discount_for_extra(25),
    20).

% === row 39341: percent estimate order-of-magnitude error ===
% Task: estimate 30% of 54215.
% Correct: about 16264.5.
% Error: 2000.
% SCHEMA: Measuring Stick.
% GROUNDED: TODO preserve order of magnitude when estimating.
% CONNECTS TO: s(comp_nec(unlicensed(percent_estimate_order_error)))
r39341_percent_estimate_order_error(percent_of(30, 54215), 2000).

test_harness:arith_misconception(db_row(39341), percent, percent_estimate_order_error,
    misconceptions_percent_batch_1:r39341_percent_estimate_order_error,
    percent_of(30, 54215),
    16264.5).

% === row 39374: discount found by dividing by percent number ===
% Task: 20% discount on 69.
% Correct discount amount: 13.8.
% Error: 3.45, calculating 69 / 20.
% SCHEMA: Measuring Stick.
% GROUNDED: TODO convert percent to decimal multiplier, not divisor.
% CONNECTS TO: s(comp_nec(unlicensed(divide_by_percent_number)))
r39374_divide_by_percent_number(discount_amount(69, 20), Got) :-
    Got is 69 / 20.

test_harness:arith_misconception(db_row(39374), percent, divide_by_percent_number,
    misconceptions_percent_batch_1:r39374_divide_by_percent_number,
    discount_amount(69, 20),
    13.8).

% === row 39375: percent value subtracted as dollars ===
% Task: final price after 20% discount on 69.
% Correct: 55.2.
% Error: 49.
% SCHEMA: Measuring Stick.
% GROUNDED: TODO subtract the computed percentage amount, not the percent numeral.
% CONNECTS TO: s(comp_nec(unlicensed(percent_as_absolute_amount)))
r39375_percent_as_absolute_amount(final_price(69, 20), 49).

test_harness:arith_misconception(db_row(39375), percent, percent_as_absolute_amount,
    misconceptions_percent_batch_1:r39375_percent_as_absolute_amount,
    final_price(69, 20),
    55.2).

% === row 39533: percent discount interpreted as dollars ===
% Task: 12% discount on 68.
% Correct: 59.84.
% Error: 56.
% SCHEMA: Measuring Stick.
% GROUNDED: TODO apply 12/100 of the base, not 12 units.
% CONNECTS TO: s(comp_nec(unlicensed(percent_as_absolute_amount)))
r39533_percent_discount_as_dollars(final_price(68, 12), 56).

test_harness:arith_misconception(db_row(39533), percent, percent_as_absolute_amount,
    misconceptions_percent_batch_1:r39533_percent_discount_as_dollars,
    final_price(68, 12),
    59.84).

test_harness:arith_misconception(db_row(39703), percent, too_vague, skip, none, none).

% === row 39756: decrease percent taken from final amount ===
% Task: 25% decrease from 30.
% Correct decrease amount: 7.5.
% Error: 6, taking 25% of 24.
% SCHEMA: Source-Path-Goal.
% GROUNDED: TODO use the initial base for percentage decrease.
% CONNECTS TO: s(comp_nec(unlicensed(final_base_for_decrease)))
r39756_final_base_for_decrease(decrease_amount(30, 25), 6).

test_harness:arith_misconception(db_row(39756), percent, final_base_for_decrease,
    misconceptions_percent_batch_1:r39756_final_base_for_decrease,
    decrease_amount(30, 25),
    7.5).

% === row 39843: find-percent confused with find-part ===
% Task: 15 is what percent of 33?
% Correct: about 45.45%.
% Error: 4.5, calculating 0.15 * 30.
% SCHEMA: Source-Path-Goal.
% GROUNDED: TODO divide part by whole to form the percent.
% CONNECTS TO: s(comp_nec(unlicensed(find_percent_as_find_part)))
r39843_find_percent_as_find_part(percent_question(15, 33), 4.5).

test_harness:arith_misconception(db_row(39843), percent, find_percent_as_find_part,
    misconceptions_percent_batch_1:r39843_find_percent_as_find_part,
    percent_question(15, 33),
    45.45454545454545).

test_harness:arith_misconception(db_row(39902), percent, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39930), percent, too_vague, skip, none, none).

% === row 39931: compound increases calculated on original base ===
% Task: 200 increased by 9.5%, then by 5.9%.
% Correct: 231.921.
% Error: 230.8, adding both percentage amounts from the original base.
% SCHEMA: Source-Path-Goal.
% GROUNDED: TODO update the base between percentage increases.
% CONNECTS TO: s(comp_nec(unlicensed(original_base_compound_increase)))
r39931_original_base_compound_increase(compound_increase(200, [9.5,5.9]), 230.8).

test_harness:arith_misconception(db_row(39931), percent, original_base_compound_increase,
    misconceptions_percent_batch_1:r39931_original_base_compound_increase,
    compound_increase(200, [9.5,5.9]),
    231.921).

% === row 39932: inflation rate equals purchasing-power loss ===
% Task: purchasing-power decrease from 5.9% inflation.
% Correct: about 5.6%.
% Error: 5.9%.
% SCHEMA: Source-Path-Goal.
% GROUNDED: TODO compute reciprocal change in purchasing power.
% CONNECTS TO: s(comp_nec(unlicensed(rate_equals_reciprocal_loss)))
r39932_rate_equals_reciprocal_loss(purchasing_power_loss(5.9), 5.9).

test_harness:arith_misconception(db_row(39932), percent, rate_equals_reciprocal_loss,
    misconceptions_percent_batch_1:r39932_rate_equals_reciprocal_loss,
    purchasing_power_loss(5.9),
    5.571293673276671).

% === row 39956: markup percent treated as find-percent problem ===
% Task: 55% markup on 90.
% Correct markup amount: 49.5.
% Error: 61.11, calculating 55 / 90 * 100.
% SCHEMA: Source-Path-Goal.
% GROUNDED: TODO apply rate to base instead of forming part/base percent.
% CONNECTS TO: s(comp_nec(unlicensed(markup_as_find_percent)))
r39956_markup_as_find_percent(markup_amount(90, 55), Got) :-
    Got is 55 / 90 * 100.

test_harness:arith_misconception(db_row(39956), percent, markup_as_find_percent,
    misconceptions_percent_batch_1:r39956_markup_as_find_percent,
    markup_amount(90, 55),
    49.5).

% === row 39957: discount treated as increase ===
% Task: 15% discount on 50.
% Correct final price: 42.5.
% Error: 57.5, adding the discount amount.
% SCHEMA: Source-Path-Goal.
% GROUNDED: TODO preserve direction of the percentage change.
% CONNECTS TO: s(comp_nec(unlicensed(discount_as_increase)))
r39957_discount_as_increase(final_price_after_discount(50, 15), 57.5).

test_harness:arith_misconception(db_row(39957), percent, discount_as_increase,
    misconceptions_percent_batch_1:r39957_discount_as_increase,
    final_price_after_discount(50, 15),
    42.5).

% === row 39958: 120% increase amount used as final price ===
% Task: 120% increase on 1.25.
% Correct final price: 2.75.
% Error: 1.50, computing only the increase amount.
% SCHEMA: Source-Path-Goal.
% GROUNDED: TODO add the increase amount to the original base.
% CONNECTS TO: s(comp_nec(unlicensed(increase_amount_as_final_price)))
r39958_increase_amount_as_final_price(final_price_after_increase(1.25, 120), 1.50).

test_harness:arith_misconception(db_row(39958), percent, increase_amount_as_final_price,
    misconceptions_percent_batch_1:r39958_increase_amount_as_final_price,
    final_price_after_increase(1.25, 120),
    2.75).

test_harness:arith_misconception(db_row(39959), percent, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(40076), percent, too_vague, skip, none, none).

% === row 40240: numerator used directly as percent ===
% Task: 50 / 150 as a percent.
% Correct: about 33.33%.
% Error: 50%.
% SCHEMA: Measuring Stick.
% GROUNDED: TODO divide numerator by denominator before scaling by 100.
% CONNECTS TO: s(comp_nec(unlicensed(numerator_as_percent)))
r40240_numerator_as_percent(percent_from_fraction(50, 150), 50).

test_harness:arith_misconception(db_row(40240), percent, numerator_as_percent,
    misconceptions_percent_batch_1:r40240_numerator_as_percent,
    percent_from_fraction(50, 150),
    33.333333333333336).

% === row 40323: percent of whole by dividing by percent numeral ===
% Task: 48% of 300.
% Correct: 144.
% Error: 6, calculating 300 / 50.
% SCHEMA: Measuring Stick.
% GROUNDED: TODO use percent as a multiplier near one-half.
% CONNECTS TO: s(comp_nec(unlicensed(divide_by_percent_number)))
r40323_divide_by_percent_number(percent_of(48, 300), 6).

test_harness:arith_misconception(db_row(40323), percent, divide_by_percent_number,
    misconceptions_percent_batch_1:r40323_divide_by_percent_number,
    percent_of(48, 300),
    144).

% === row 40384: decimal-to-percent shortcut inverted ===
% Task: convert 0.07 to percent.
% Correct: 7.
% Error: 0.0007.
% SCHEMA: Measuring Stick.
% GROUNDED: TODO multiply by 100, not divide by 100.
% CONNECTS TO: s(comp_nec(unlicensed(decimal_percent_inverted)))
r40384_decimal_percent_inverted(decimal_to_percent(0.07), 0.0007).

test_harness:arith_misconception(db_row(40384), percent, decimal_percent_inverted,
    misconceptions_percent_batch_1:r40384_decimal_percent_inverted,
    decimal_to_percent(0.07),
    7).

% === row 40385: decimal not shifted after fraction division ===
% Task: convert 91/50 to percent.
% Correct: 182.
% Error: 1.82.
% SCHEMA: Measuring Stick.
% GROUNDED: TODO scale the decimal quotient by 100 for percent.
% CONNECTS TO: s(comp_nec(unlicensed(decimal_not_shifted_to_percent)))
r40385_decimal_not_shifted_to_percent(fraction_to_percent(91, 50), 1.82).

test_harness:arith_misconception(db_row(40385), percent, decimal_not_shifted_to_percent,
    misconceptions_percent_batch_1:r40385_decimal_not_shifted_to_percent,
    fraction_to_percent(91, 50),
    182).

% === row 40544: 9 percent as 0.9 ===
% Task: 9% of 100.
% Correct: 9.
% Error: 90.
% SCHEMA: Measuring Stick.
% GROUNDED: TODO map single-digit percent to hundredths, not tenths.
% CONNECTS TO: s(comp_nec(unlicensed(single_digit_percent_as_tenths)))
r40544_single_digit_percent_as_tenths(percent_of(9, 100), 90).

test_harness:arith_misconception(db_row(40544), percent, single_digit_percent_as_tenths,
    misconceptions_percent_batch_1:r40544_single_digit_percent_as_tenths,
    percent_of(9, 100),
    9).
