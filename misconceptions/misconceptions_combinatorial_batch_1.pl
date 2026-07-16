:- module(misconceptions_combinatorial_batch_1, []).
% combinatorial misconceptions — direct solo batch 1.
% Native arithmetic layer only.

:- multifile test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.

% === row 37461: Cartesian product treated as one-to-one matching ===
% Task: 3 shirts and 4 pairs of pants.
% Correct: 12 outfits.
% Error: 3, matching one shirt to one pants item.
% SCHEMA: Object Collection.
% GROUNDED: TODO form all cross-pairs, not a single correspondence.
% CONNECTS TO: s(comp_nec(unlicensed(cartesian_product_as_one_to_one)))
r37461_cartesian_product_one_to_one(outfits(3, 4), 3).

test_harness:arith_misconception(db_row(37461), combinatorial, cartesian_product_as_one_to_one,
    misconceptions_combinatorial_batch_1:r37461_cartesian_product_one_to_one,
    outfits(3, 4),
    12).

% === row 37463: three-way product reduced to two-way product ===
% Task: 3 bags, 4 choices each.
% Correct: 64.
% Error: 16, using only 4 * 4.
% SCHEMA: Object Collection.
% GROUNDED: TODO coordinate all three choice positions.
% CONNECTS TO: s(comp_nec(unlicensed(drop_dimension_in_cartesian_product)))
r37463_drop_dimension(three_bag_choices(4, 4, 4), 16).

test_harness:arith_misconception(db_row(37463), combinatorial, drop_dimension_in_cartesian_product,
    misconceptions_combinatorial_batch_1:r37463_drop_dimension,
    three_bag_choices(4, 4, 4),
    64).

test_harness:arith_misconception(db_row(38007), combinatorial, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38016), combinatorial, too_vague, skip, none, none).

% === row 38219: repeated outcome overcounted in at-least case ===
% Task: 4-letter passwords with at least three Es.
% Correct: 101.
% Error: 104, counting EEEE once for each selected triple of positions.
% SCHEMA: Object Collection.
% GROUNDED: TODO quotient overlapping case decompositions to unique outcomes.
% CONNECTS TO: s(comp_nec(unlicensed(overlap_overcount_combinatorics)))
r38219_overlap_overcount(at_least_three_es(length(4), alphabet(26)), 104).

test_harness:arith_misconception(db_row(38219), combinatorial, overlap_overcount_combinatorics,
    misconceptions_combinatorial_batch_1:r38219_overlap_overcount,
    at_least_three_es(length(4), alphabet(26)),
    101).

test_harness:arith_misconception(db_row(38319), combinatorial, too_vague, skip, none, none).

% === row 38336: three-dimensional product counted as two-dimensional ===
% Task: three bags of four candies each.
% Correct: 64.
% Error: 16.
% SCHEMA: Object Collection.
% GROUNDED: TODO preserve all three composite units.
% CONNECTS TO: s(comp_nec(unlicensed(two_dimensional_for_three_dimensional_product)))
r38336_two_dimensional_product(three_bag_choices(4, 4, 4), 16).

test_harness:arith_misconception(db_row(38336), combinatorial, two_dimensional_for_three_dimensional_product,
    misconceptions_combinatorial_batch_1:r38336_two_dimensional_product,
    three_bag_choices(4, 4, 4),
    64).

% === row 38338: blind combination of given numbers ===
% Task: coin outcomes and die outcomes.
% Correct: 12.
% Error: 36.
% SCHEMA: Object Collection.
% GROUNDED: TODO multiply the independent outcome counts once each.
% CONNECTS TO: s(comp_nec(unlicensed(blind_combine_numbers)))
r38338_blind_combine_numbers(coin_die(2, 6), 36).

test_harness:arith_misconception(db_row(38338), combinatorial, blind_combine_numbers,
    misconceptions_combinatorial_batch_1:r38338_blind_combine_numbers,
    coin_die(2, 6),
    12).

% === row 38471: empty set categorized as one-item choice ===
% Correct: plain pizza has zero toppings.
% Error: grouped with one-topping pizzas.
% SCHEMA: Container.
% GROUNDED: TODO represent zero choices as its own cardinality class.
% CONNECTS TO: s(comp_nec(unlicensed(empty_set_as_singleton)))
r38471_empty_set_as_singleton(classify_pizza(plain), one_topping).

test_harness:arith_misconception(db_row(38471), combinatorial, empty_set_as_singleton,
    misconceptions_combinatorial_batch_1:r38471_empty_set_as_singleton,
    classify_pizza(plain),
    zero_toppings).

test_harness:arith_misconception(db_row(38472), combinatorial, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38473), combinatorial, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38517), combinatorial, too_vague, skip, none, none).

% === row 38518: new row and new column counted independently ===
% Task: extend 7 by 7 array to 8 by 8.
% Correct new outcomes: 15.
% Error: 16, counting the intersection twice.
% SCHEMA: Object Collection.
% GROUNDED: TODO identify shared intersection when adding row and column.
% CONNECTS TO: s(comp_nec(unlicensed(double_count_new_intersection)))
r38518_double_count_new_intersection(extend_square_array(7, 8), 16).

test_harness:arith_misconception(db_row(38518), combinatorial, double_count_new_intersection,
    misconceptions_combinatorial_batch_1:r38518_double_count_new_intersection,
    extend_square_array(7, 8),
    15).

test_harness:arith_misconception(db_row(38705), combinatorial, too_vague, skip, none, none).

% === row 38706: arrangements with replacement treated as combinations ===
% Task: two-stripe flags from 15 colors, with color order/roles.
% Correct: 225.
% Error: 120, using 15 + 14 + ... + 1.
% SCHEMA: Object Collection.
% GROUNDED: TODO allow each color in each role after prior pairings.
% CONNECTS TO: s(comp_nec(unlicensed(arrangement_as_combination_sum)))
r38706_arrangement_as_combination_sum(two_stripe_flags(15), 120).

test_harness:arith_misconception(db_row(38706), combinatorial, arrangement_as_combination_sum,
    misconceptions_combinatorial_batch_1:r38706_arrangement_as_combination_sum,
    two_stripe_flags(15),
    225).

% === row 38707: decreasing sum evaluated by squaring first term ===
% Task: evaluate 15 + 14 + ... + 1.
% Correct: 120.
% Error: 225.
% SCHEMA: Object Collection.
% GROUNDED: TODO sum the decreasing sequence, not square the start.
% CONNECTS TO: s(comp_nec(unlicensed(square_initial_term_for_sum)))
r38707_square_initial_term_for_sum(decreasing_sum_from(15), 225).

test_harness:arith_misconception(db_row(38707), combinatorial, square_initial_term_for_sum,
    misconceptions_combinatorial_batch_1:r38707_square_initial_term_for_sum,
    decreasing_sum_from(15),
    120).

% === row 38817: complement symmetry for combinations missed ===
% Task: compare committees of 2 and 6 from 8.
% Correct: same number.
% Error: more committees of 2.
% SCHEMA: Object Collection.
% GROUNDED: TODO pair each chosen subset with its complement.
% CONNECTS TO: s(comp_nec(unlicensed(combination_complement_symmetry_missed)))
r38817_complement_symmetry_missed(compare_committees(8, 2, 6), more_two_person).

test_harness:arith_misconception(db_row(38817), combinatorial, combination_complement_symmetry_missed,
    misconceptions_combinatorial_batch_1:r38817_complement_symmetry_missed,
    compare_committees(8, 2, 6),
    same_count).

test_harness:arith_misconception(db_row(38844), combinatorial, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39451), combinatorial, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39452), combinatorial, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39453), combinatorial, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39827), combinatorial, too_vague, skip, none, none).

% === row 39967: binomial coefficient read as fraction ===
% Task: choose 2 from 8.
% Correct: 28.
% Error: 8/2.
% SCHEMA: Container.
% GROUNDED: TODO interpret choose notation as a count of subsets.
% CONNECTS TO: s(comp_nec(unlicensed(choose_notation_as_fraction)))
r39967_choose_notation_as_fraction(choose(8, 2), frac(8, 2)).

test_harness:arith_misconception(db_row(39967), combinatorial, choose_notation_as_fraction,
    misconceptions_combinatorial_batch_1:r39967_choose_notation_as_fraction,
    choose(8, 2),
    28).

test_harness:arith_misconception(db_row(40237), combinatorial, too_vague, skip, none, none).
