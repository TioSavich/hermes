:- module(misconceptions_integer_batch_1, []).
% integer misconceptions — direct solo batch 1.
% Native arithmetic layer only.

:- multifile test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.

test_harness:arith_misconception(db_row(37590), integer, too_vague, skip, none, none).

% === row 37591: greatest and least chosen by absolute value ===
% Correct: greatest is 7, least is -8.
% Error: greatest is -8, least is 1.
% SCHEMA: Measuring Stick.
% GROUNDED: TODO order by directed value, not absolute magnitude.
% CONNECTS TO: s(comp_nec(unlicensed(integer_order_by_absolute_value)))
r37591_order_by_absolute_value(extremes([-8,-4,-2,1,5,7]), extremes(greatest(-8), least(1))).

test_harness:arith_misconception(db_row(37591), integer, integer_order_by_absolute_value,
    misconceptions_integer_batch_1:r37591_order_by_absolute_value,
    extremes([-8,-4,-2,1,5,7]),
    extremes(greatest(7), least(-8))).

% === row 37592: negative comparison ignores direction ===
% Task: compare -7 and -2.
% Correct: -2 is greater.
% Error: -7 is greater because 7 > 2.
% SCHEMA: Measuring Stick.
% GROUNDED: TODO compare positions on directed number line.
% CONNECTS TO: s(comp_nec(unlicensed(negative_compare_by_magnitude)))
r37592_negative_compare_by_magnitude(compare(-7, -2), greater(-7)).

test_harness:arith_misconception(db_row(37592), integer, negative_compare_by_magnitude,
    misconceptions_integer_batch_1:r37592_negative_compare_by_magnitude,
    compare(-7, -2),
    greater(-2)).

% === row 37593: larger absolute negative considered greater ===
% Task: compare -6 and -2.
% Correct: -2 is greater.
% Error: -6 is greater.
% SCHEMA: Measuring Stick.
% GROUNDED: TODO invert absolute-magnitude ordering left of zero.
% CONNECTS TO: s(comp_nec(unlicensed(larger_absolute_negative_is_greater)))
r37593_larger_absolute_negative_greater(compare(-6, -2), greater(-6)).

test_harness:arith_misconception(db_row(37593), integer, larger_absolute_negative_is_greater,
    misconceptions_integer_batch_1:r37593_larger_absolute_negative_greater,
    compare(-6, -2),
    greater(-2)).

% === row 37594: unary minus interpreted as incomplete subtraction ===
% Task: value of -5.
% Correct: -5.
% Error: 0, reading it as 5 - 5.
% SCHEMA: Source-Path-Goal.
% GROUNDED: TODO distinguish unary sign from binary subtraction.
% CONNECTS TO: s(comp_nec(unlicensed(unary_minus_as_subtraction)))
r37594_unary_minus_as_subtraction(value(-5), 0).

test_harness:arith_misconception(db_row(37594), integer, unary_minus_as_subtraction,
    misconceptions_integer_batch_1:r37594_unary_minus_as_subtraction,
    value(-5),
    -5).

test_harness:arith_misconception(db_row(37595), integer, too_vague, skip, none, none).

% === row 37708: negative numbers rejected as numbers ===
% Correct: -1 is a number.
% Error: not a number because it cannot be counted as objects.
% SCHEMA: Object Collection.
% GROUNDED: TODO allow directed quantities beyond cardinal collections.
% CONNECTS TO: s(comp_nec(unlicensed(negative_not_number)))
r37708_negative_not_number(number_status(-1), not_number).

test_harness:arith_misconception(db_row(37708), integer, negative_not_number,
    misconceptions_integer_batch_1:r37708_negative_not_number,
    number_status(-1),
    number).

% === row 37709: cannot subtract more than available ===
% Task: 3 - 5.
% Correct: -2.
% Error: 0.
% SCHEMA: Object Collection.
% GROUNDED: TODO extend subtraction from removal to directed difference.
% CONNECTS TO: s(comp_nec(unlicensed(subtraction_floor_at_zero)))
r37709_subtraction_floor_at_zero(3 - 5, 0).

test_harness:arith_misconception(db_row(37709), integer, subtraction_floor_at_zero,
    misconceptions_integer_batch_1:r37709_subtraction_floor_at_zero,
    3 - 5,
    -2).

% === row 37710: addition must make larger ===
% Task: solve 6 + c = 4.
% Correct: -2.
% Error: impossible.
% SCHEMA: Source-Path-Goal.
% GROUNDED: TODO allow negative addend as leftward displacement.
% CONNECTS TO: s(comp_nec(unlicensed(addition_must_increase)))
r37710_addition_must_increase(missing_addend(6, 4), impossible).

test_harness:arith_misconception(db_row(37710), integer, addition_must_increase,
    misconceptions_integer_batch_1:r37710_addition_must_increase,
    missing_addend(6, 4),
    -2).

test_harness:arith_misconception(db_row(37727), integer, too_vague, skip, none, none).

% === row 37883: open addition sentence declared impossible ===
% Task: 6 + [] = 4.
% Correct: -2.
% Error: no solution.
% SCHEMA: Source-Path-Goal.
% GROUNDED: TODO permit negative change values.
% CONNECTS TO: s(comp_nec(unlicensed(open_addition_no_negative_solution)))
r37883_open_addition_no_negative_solution(missing_addend(6, 4), no_solution).

test_harness:arith_misconception(db_row(37883), integer, open_addition_no_negative_solution,
    misconceptions_integer_batch_1:r37883_open_addition_no_negative_solution,
    missing_addend(6, 4),
    -2).

% === row 37884: negative result judged impossible by absolute order ===
% Task: solve -2 - [] = -8.
% Correct: 6.
% Error: no answer.
% SCHEMA: Source-Path-Goal.
% GROUNDED: TODO reason over directed positions, not absolute magnitude.
% CONNECTS TO: s(comp_nec(unlicensed(negative_subtraction_no_solution)))
r37884_negative_subtraction_no_solution(missing_subtrahend(-2, -8), no_answer).

test_harness:arith_misconception(db_row(37884), integer, negative_subtraction_no_solution,
    misconceptions_integer_batch_1:r37884_negative_subtraction_no_solution,
    missing_subtrahend(-2, -8),
    6).

test_harness:arith_misconception(db_row(37894), integer, too_vague, skip, none, none).

% === row 38011: number-line origin set to one ===
% Correct: origin is 0.
% Error: origin is 1.
% SCHEMA: Measuring Stick.
% GROUNDED: TODO distinguish count start from coordinate origin.
% CONNECTS TO: s(comp_nec(unlicensed(number_line_origin_one)))
r38011_number_line_origin_one(number_line_origin, 1).

test_harness:arith_misconception(db_row(38011), integer, number_line_origin_one,
    misconceptions_integer_batch_1:r38011_number_line_origin_one,
    number_line_origin,
    0).

% === row 38012: negative integers ordered by absolute value ===
% Task: compare -5 and -4.
% Correct: -5 > -4 is false.
% Error: true.
% SCHEMA: Measuring Stick.
% GROUNDED: TODO compare directed positions left of zero.
% CONNECTS TO: s(comp_nec(unlicensed(negative_order_by_absolute_value)))
r38012_negative_order_by_absolute_value(greater_than(-5, -4), true).

test_harness:arith_misconception(db_row(38012), integer, negative_order_by_absolute_value,
    misconceptions_integer_batch_1:r38012_negative_order_by_absolute_value,
    greater_than(-5, -4),
    false).

test_harness:arith_misconception(db_row(38042), integer, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38109), integer, too_vague, skip, none, none).

% === row 38244: change amount confused with endpoint ===
% Task: start at +24 and decrease by 33.
% Correct endpoint: -9.
% Error: -33.
% SCHEMA: Source-Path-Goal.
% GROUNDED: TODO compose start position with directed change.
% CONNECTS TO: s(comp_nec(unlicensed(change_amount_as_endpoint)))
r38244_change_amount_as_endpoint(elevation_after(24, decrease(33)), -33).

test_harness:arith_misconception(db_row(38244), integer, change_amount_as_endpoint,
    misconceptions_integer_batch_1:r38244_change_amount_as_endpoint,
    elevation_after(24, decrease(33)),
    -9).

% === row 38302: multiplication sign chosen from larger absolute factor ===
% Task: (+7) * (-5).
% Correct: -35.
% Error: +35 because 7 > 5.
% SCHEMA: Object Collection.
% GROUNDED: TODO determine product sign from factor signs, not absolute size.
% CONNECTS TO: s(comp_nec(unlicensed(product_sign_from_larger_factor)))
r38302_product_sign_from_larger_factor(7 * -5, 35).

test_harness:arith_misconception(db_row(38302), integer, product_sign_from_larger_factor,
    misconceptions_integer_batch_1:r38302_product_sign_from_larger_factor,
    7 * -5,
    -35).

% === row 38500: double minus rejected as impossible syntax ===
% Task: evaluate 4 - (-1).
% Correct: 5.
% Error: impossible.
% SCHEMA: Source-Path-Goal.
% GROUNDED: TODO distinguish subtraction operation from signed operand.
% CONNECTS TO: s(comp_nec(unlicensed(double_minus_impossible)))
r38500_double_minus_impossible(4 - -1, impossible).

test_harness:arith_misconception(db_row(38500), integer, double_minus_impossible,
    misconceptions_integer_batch_1:r38500_double_minus_impossible,
    4 - -1,
    5).

% === row 38534: prime definition ignores boundary cases ===
% Correct: 1 is not prime.
% Error: 1 is included by a too-broad divisor definition.
% SCHEMA: Container.
% GROUNDED: TODO test boundary non-examples against definition.
% CONNECTS TO: s(comp_nec(unlicensed(prime_definition_includes_one)))
r38534_prime_definition_includes_one(prime_status(1), prime).

test_harness:arith_misconception(db_row(38534), integer, prime_definition_includes_one,
    misconceptions_integer_batch_1:r38534_prime_definition_includes_one,
    prime_status(1),
    not_prime).

test_harness:arith_misconception(db_row(38682), integer, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38683), integer, too_vague, skip, none, none).

% === row 38684: minus sign appended as label ===
% Task: 3 - 8.
% Correct: -5.
% Error: label(min,5), treating minus as an attached word.
% SCHEMA: Source-Path-Goal.
% GROUNDED: TODO represent negative value as directed quantity.
% CONNECTS TO: s(comp_nec(unlicensed(minus_as_label)))
r38684_minus_as_label(3 - 8, label(min, 5)).

test_harness:arith_misconception(db_row(38684), integer, minus_as_label,
    misconceptions_integer_batch_1:r38684_minus_as_label,
    3 - 8,
    -5).

test_harness:arith_misconception(db_row(38714), integer, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38715), integer, too_vague, skip, none, none).

% === row 38863: addition cannot produce a smaller result ===
% Task: 5 + [] = 3.
% Correct: -2.
% Error: no way.
% SCHEMA: Source-Path-Goal.
% GROUNDED: TODO use negative addend for leftward movement.
% CONNECTS TO: s(comp_nec(unlicensed(addition_cannot_decrease)))
r38863_addition_cannot_decrease(missing_addend(5, 3), no_way).

test_harness:arith_misconception(db_row(38863), integer, addition_cannot_decrease,
    misconceptions_integer_batch_1:r38863_addition_cannot_decrease,
    missing_addend(5, 3),
    -2).

test_harness:arith_misconception(db_row(38864), integer, too_vague, skip, none, none).

% === row 38865: negative numbers rejected as real numbers ===
% Correct: negative integers are numbers.
% Error: not numbers because they cannot be counted as cubes.
% SCHEMA: Object Collection.
% GROUNDED: TODO extend number beyond countable object collections.
% CONNECTS TO: s(comp_nec(unlicensed(negative_not_number)))
r38865_negative_not_number(number_status(-1), not_number).

test_harness:arith_misconception(db_row(38865), integer, negative_not_number,
    misconceptions_integer_batch_1:r38865_negative_not_number,
    number_status(-1),
    number).

% === row 38866: adding a negative treated as impossible ===
% Task: 6 + -2.
% Correct: 4.
% Error: impossible.
% SCHEMA: Source-Path-Goal.
% GROUNDED: TODO allow signed addend as directed change.
% CONNECTS TO: s(comp_nec(unlicensed(cannot_add_negative)))
r38866_cannot_add_negative(6 + -2, impossible).

test_harness:arith_misconception(db_row(38866), integer, cannot_add_negative,
    misconceptions_integer_batch_1:r38866_cannot_add_negative,
    6 + -2,
    4).

test_harness:arith_misconception(db_row(38900), integer, too_vague, skip, none, none).

% === row 38908: take-away model floors subtraction at impossibility ===
% Task: 3 - 8.
% Correct: -5.
% Error: impossible.
% SCHEMA: Object Collection.
% GROUNDED: TODO extend subtraction beyond removing available objects.
% CONNECTS TO: s(comp_nec(unlicensed(takeaway_model_blocks_negative_result)))
r38908_takeaway_blocks_negative(3 - 8, impossible).

test_harness:arith_misconception(db_row(38908), integer, takeaway_model_blocks_negative_result,
    misconceptions_integer_batch_1:r38908_takeaway_blocks_negative,
    3 - 8,
    -5).

% === row 38947: integer subtraction by absolute difference ===
% Task: +6 - +8.
% Correct: -2.
% Error: 2.
% SCHEMA: Measuring Stick.
% GROUNDED: TODO preserve operand order and direction.
% CONNECTS TO: s(comp_nec(unlicensed(integer_subtraction_absolute_difference)))
r38947_integer_subtraction_absolute_difference(6 - 8, 2).

test_harness:arith_misconception(db_row(38947), integer, integer_subtraction_absolute_difference,
    misconceptions_integer_batch_1:r38947_integer_subtraction_absolute_difference,
    6 - 8,
    -2).

% === row 38975: subtracting larger from smaller considered impossible ===
% Task: 3 - 4.
% Correct: -1.
% Error: impossible.
% SCHEMA: Object Collection.
% GROUNDED: TODO allow directed result below zero.
% CONNECTS TO: s(comp_nec(unlicensed(subtract_larger_impossible)))
r38975_subtract_larger_impossible(3 - 4, impossible).

test_harness:arith_misconception(db_row(38975), integer, subtract_larger_impossible,
    misconceptions_integer_batch_1:r38975_subtract_larger_impossible,
    3 - 4,
    -1).

% === row 39097: greatest integer less than -6 not found ===
% Task: greatest integer satisfying a < -6.
% Correct: -7.
% Error: no answer.
% SCHEMA: Measuring Stick.
% GROUNDED: TODO order negatives by directed number-line position.
% CONNECTS TO: s(comp_nec(unlicensed(negative_bound_order_failure)))
r39097_negative_bound_order_failure(greatest_integer_less_than(-6), no_answer).

test_harness:arith_misconception(db_row(39097), integer, negative_bound_order_failure,
    misconceptions_integer_batch_1:r39097_negative_bound_order_failure,
    greatest_integer_less_than(-6),
    -7).

% === row 39100: Euclidean division mistaken for prime factorization ===
% Correct: 7 is prime.
% Error: records 7 = 2*3 + 1 as if factorization work.
% SCHEMA: Object Collection.
% GROUNDED: TODO distinguish division with remainder from factorization.
% CONNECTS TO: s(comp_nec(unlicensed(euclidean_division_as_factorization)))
r39100_euclidean_division_as_factorization(factorization(7), division_remainder(2,3,1)).

test_harness:arith_misconception(db_row(39100), integer, euclidean_division_as_factorization,
    misconceptions_integer_batch_1:r39100_euclidean_division_as_factorization,
    factorization(7),
    prime).

% === row 39101: coprime definition uses LCM instead of GCD ===
% Correct: gcd(p,q) = 1.
% Error: lcm(p,q) = 1.
% SCHEMA: Container.
% GROUNDED: TODO choose common divisor structure, not common multiple.
% CONNECTS TO: s(comp_nec(unlicensed(coprime_by_lcm_one)))
r39101_coprime_by_lcm_one(coprime_definition(p, q), lcm(p, q, 1)).

test_harness:arith_misconception(db_row(39101), integer, coprime_by_lcm_one,
    misconceptions_integer_batch_1:r39101_coprime_by_lcm_one,
    coprime_definition(p, q),
    gcd(p, q, 1)).

test_harness:arith_misconception(db_row(39121), integer, too_vague, skip, none, none).

% === row 39171: cue word fewer triggers subtraction in start-unknown problem ===
% Task: this week 12000 fans, 1800 fewer than last week.
% Correct last week: 13800.
% Error: 10200.
% SCHEMA: Source-Path-Goal.
% GROUNDED: TODO reverse operation from relation and unknown position.
% CONNECTS TO: s(comp_nec(unlicensed(cue_word_fewer_subtracts)))
r39171_cue_word_fewer_subtracts(last_week_fans(this_week(12000), fewer_than_last(1800)), 10200).

test_harness:arith_misconception(db_row(39171), integer, cue_word_fewer_subtracts,
    misconceptions_integer_batch_1:r39171_cue_word_fewer_subtracts,
    last_week_fans(this_week(12000), fewer_than_last(1800)),
    13800).

% === row 39240: prime divisibility rule applied to composite ===
% Task: infer 4 | p from 4 | p^2.
% Correct: false in general.
% Error: true.
% SCHEMA: Container.
% GROUNDED: TODO restrict prime-divisibility lemma to primes.
% CONNECTS TO: s(comp_nec(unlicensed(composite_divisibility_as_prime_rule)))
r39240_composite_divisibility_as_prime_rule(infer_divides_base(divides(4, p_squared)), true).

test_harness:arith_misconception(db_row(39240), integer, composite_divisibility_as_prime_rule,
    misconceptions_integer_batch_1:r39240_composite_divisibility_as_prime_rule,
    infer_divides_base(divides(4, p_squared)),
    false).

% === row 39366: subtract negative collapsed to subtract positive ===
% Task: 5 - (-2).
% Correct: 7.
% Error: 3.
% SCHEMA: Source-Path-Goal.
% GROUNDED: TODO compose operation and signed operand.
% CONNECTS TO: s(comp_nec(unlicensed(drop_negative_in_subtraction)))
r39366_drop_negative_in_subtraction(5 - -2, 3).

test_harness:arith_misconception(db_row(39366), integer, drop_negative_in_subtraction,
    misconceptions_integer_batch_1:r39366_drop_negative_in_subtraction,
    5 - -2,
    7).

test_harness:arith_misconception(db_row(39502), integer, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39503), integer, too_vague, skip, none, none).

% === row 39517: subtracting a negative handled like adding a negative ===
% Task: -7 - (-2).
% Correct: -5.
% Error: -9.
% SCHEMA: Source-Path-Goal.
% GROUNDED: TODO distinguish adding a negative from subtracting a negative.
% CONNECTS TO: s(comp_nec(unlicensed(subtract_negative_as_add_negative)))
r39517_subtract_negative_as_add_negative(-7 - -2, -9).

test_harness:arith_misconception(db_row(39517), integer, subtract_negative_as_add_negative,
    misconceptions_integer_batch_1:r39517_subtract_negative_as_add_negative,
    -7 - -2,
    -5).

test_harness:arith_misconception(db_row(39709), integer, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39737), integer, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39775), integer, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39968), integer, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39969), integer, too_vague, skip, none, none).

% === row 39974: equal opposite displacements not composed to zero ===
% Correct: equal opposite pulls yield zero displacement.
% Error: qualitative physical deformation instead of displacement balance.
% SCHEMA: Source-Path-Goal.
% GROUNDED: TODO compose opposite vectors by cancellation.
% CONNECTS TO: s(comp_nec(unlicensed(opposites_not_cancelled)))
r39974_opposites_not_cancelled(equal_opposite_pulls, break_apart).

test_harness:arith_misconception(db_row(39974), integer, opposites_not_cancelled,
    misconceptions_integer_batch_1:r39974_opposites_not_cancelled,
    equal_opposite_pulls,
    zero_displacement).

test_harness:arith_misconception(db_row(39975), integer, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39976), integer, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(40317), integer, too_vague, skip, none, none).

% === row 40382: negative sign affixed to whole-number subtraction result ===
% Task: 20 + 10 + (-6).
% Correct: 24.
% Error: -24.
% SCHEMA: Source-Path-Goal.
% GROUNDED: TODO treat -6 as a directed addend, not a sign for final result.
% CONNECTS TO: s(comp_nec(unlicensed(negative_sign_affixed_to_result)))
r40382_negative_sign_affixed_to_result(20 + 10 + -6, -24).

test_harness:arith_misconception(db_row(40382), integer, negative_sign_affixed_to_result,
    misconceptions_integer_batch_1:r40382_negative_sign_affixed_to_result,
    20 + 10 + -6,
    24).

% === row 40387: negative base sign dropped under exponent ===
% Task: (-5)^3.
% Correct: -125.
% Error: 125.
% SCHEMA: Object Collection.
% GROUNDED: TODO include signed base in repeated multiplication.
% CONNECTS TO: s(comp_nec(unlicensed(drop_negative_base_sign)))
r40387_drop_negative_base_sign(power(-5, 3), 125).

test_harness:arith_misconception(db_row(40387), integer, drop_negative_base_sign,
    misconceptions_integer_batch_1:r40387_drop_negative_base_sign,
    power(-5, 3),
    -125).

% === row 40403: negative subtraction arithmetic error ===
% Task: -2 - 3.
% Correct: -5.
% Error: -6.
% SCHEMA: Source-Path-Goal.
% GROUNDED: TODO move three units left from -2.
% CONNECTS TO: s(comp_nec(unlicensed(negative_subtraction_count_error)))
r40403_negative_subtraction_count_error(-2 - 3, -6).

test_harness:arith_misconception(db_row(40403), integer, negative_subtraction_count_error,
    misconceptions_integer_batch_1:r40403_negative_subtraction_count_error,
    -2 - 3,
    -5).

% === row 40484: two minuses make a plus overapplied ===
% Task: -2 - 3.
% Correct: -5.
% Error: +5.
% SCHEMA: Source-Path-Goal.
% GROUNDED: TODO apply sign rules by operation type, not chant.
% CONNECTS TO: s(comp_nec(unlicensed(two_minuses_make_plus_overapplied)))
r40484_two_minuses_make_plus_overapplied(-2 - 3, 5).

test_harness:arith_misconception(db_row(40484), integer, two_minuses_make_plus_overapplied,
    misconceptions_integer_batch_1:r40484_two_minuses_make_plus_overapplied,
    -2 - 3,
    -5).

% === row 40501: zero treated as smallest integer ===
% Correct: integers have no least element.
% Error: 0.
% SCHEMA: Measuring Stick.
% GROUNDED: TODO extend the number line indefinitely below zero.
% CONNECTS TO: s(comp_nec(unlicensed(zero_as_smallest_integer)))
r40501_zero_as_smallest_integer(smallest_integer, 0).

test_harness:arith_misconception(db_row(40501), integer, zero_as_smallest_integer,
    misconceptions_integer_batch_1:r40501_zero_as_smallest_integer,
    smallest_integer,
    no_smallest_integer).
