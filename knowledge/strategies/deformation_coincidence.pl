:- encoding(utf8).
/** <module> Deformation coincidence data — where broken clocks are right
 *
 * Generated 2026-08-03 by scripts/checks/sweep_coincidence.pl (grids
 * documented there), against the live action-pair modules. Regenerate
 * rather than edit; the generator and its grids are the provenance.
 *
 * WHAT A ROW SAYS. coincidence_profile/10 records, for one contracted
 * kind: how many grid inputs ran to a normalizable result (ran), on
 * how many the computed result equals the independently computed true
 * answer (coincide), the rate, and how many inputs carry a per-input
 * purport violation — an outcome whose validity field misdescribes
 * that input (a deformation labelled incorrect while its result is
 * right THERE, or the reverse).
 *
 * THE DIAGNOSTIC READING (the point of the file). A deformation's
 * coincidence set is where diagnosis is unsafe: a student can land on
 * those inputs while reasoning correctly, and a recognizer that
 * charges the misconception there manufactures one. Recognizers must
 * separate before they charge:
 * scripts/checks/audit_purported_validity.pl exports the grid-searching
 * separating_example/4 and input-specific deformation_separates_on/4.
 * The runtime guard runs the suspected deformation beside the truth on
 * THIS input and requires them to differ. The corpus already carries the right per-input pattern in
 * gap_thinking_fraction_comparison (contextually_correct — zero
 * violations over 1470 swept inputs) and
 * divide_larger_by_smaller/decimal *accidentally_correct* rows; the
 * kinds with nonzero purport_violations below are the ones still
 * claiming input-independent incorrectness and should adopt that
 * pattern (see the todo doc of this date).
 *
 * MARGINAL NOTES FROM THE SWEEP.
 *   - multiplication/add_instead_of_multiply coincides on exactly one
 *     swept input: 2+2 = 2*2. The famous fixed point, measured.
 *   - fraction/cross_multiplication_rule_without_ground coincides on
 *     100% of 1764 inputs while classified deformation with
 *     validity(correct): the ungrounded-but-reliable rule. Per the
 *     owner ruling of 2026-08-03 it stays a deformation — what it
 *     loses is entitlement, not the answer — and the sweep confirms
 *     the answer never separates, so it can never be detected from
 *     answers alone. Detection must read the trace (no grounding
 *     step), not the result.
 *   - count_all_* coincide on 100% and already carry
 *     correct_but_inefficient: labels and sweep agree.
 *
 * NONTERMINATION. no_return_within/3 records kinds whose process had
 * to be killed on a small in-shape input (120 s, crash-isolated
 * per-kind runs). Not distinguished from pathological slowness; either
 * way the input is inside the declared contract shape and the kind
 * needs a guard or a refusal result. These are defects to fix, not
 * data to keep.
 *
 * Boundary (quarantine): nothing imports this module; recognizers and
 * tables are read-only with respect to it. Adopting the per-input
 * relabels or the diagnosis guard into a recognizer is a formal-core
 * change needing its own reviewed slice.
 */
:- module(deformation_coincidence,
          [ coincidence_profile/10,
            no_return_within/3,
            unswept/3
          ]).

coincidence_profile(addition, append_column_sum_without_carrying, deformation, ran(405), coincide(45), rate_pct(11), purport_violations(45), sample_coincide(some(1,9)), sample_separate(some(1,19)), sample_violation(some(1,9,claimed_incorrect_but_right))).
coincidence_profile(addition, base_ones_chunking, productive, ran(900), coincide(900), rate_pct(100), purport_violations(0), sample_coincide(some(1,1)), sample_separate(none), sample_violation(none)).
coincidence_profile(addition, column_addition_with_carrying, productive, ran(900), coincide(900), rate_pct(100), purport_violations(0), sample_coincide(some(1,1)), sample_separate(none), sample_violation(none)).
coincidence_profile(addition, count_all_instead_of_known_fact, deformation, ran(190), coincide(190), rate_pct(100), purport_violations(0), sample_coincide(some(1,1)), sample_separate(none), sample_violation(none)).
coincidence_profile(addition, count_all_when_count_on_available, deformation, ran(900), coincide(900), rate_pct(100), purport_violations(0), sample_coincide(some(1,1)), sample_separate(none), sample_violation(none)).
coincidence_profile(addition, count_on_from_larger, productive, ran(900), coincide(900), rate_pct(100), purport_violations(0), sample_coincide(some(1,1)), sample_separate(none), sample_violation(none)).
coincidence_profile(addition, derived_fact_adjustment, productive, ran(168), coincide(168), rate_pct(100), purport_violations(0), sample_coincide(some(1,2)), sample_separate(none), sample_violation(none)).
coincidence_profile(addition, drop_carry_to_next_column, deformation, ran(405), coincide(0), rate_pct(0), purport_violations(0), sample_coincide(none), sample_separate(some(1,9)), sample_violation(none)).
coincidence_profile(addition, dropped_ones_chunk, deformation, ran(900), coincide(90), rate_pct(10), purport_violations(90), sample_coincide(some(1,10)), sample_separate(some(1,1)), sample_violation(some(1,10,claimed_incorrect_but_right))).
coincidence_profile(addition, known_fact_retrieval, productive, ran(190), coincide(190), rate_pct(100), purport_violations(0), sample_coincide(some(1,1)), sample_separate(none), sample_violation(none)).
coincidence_profile(addition, make_ten_drop_leftover, deformation, ran(603), coincide(45), rate_pct(7), purport_violations(45), sample_coincide(some(1,9)), sample_separate(some(2,9)), sample_violation(some(1,9,claimed_incorrect_but_right))).
coincidence_profile(addition, make_ten_split_leftover, productive, ran(603), coincide(603), rate_pct(100), purport_violations(0), sample_coincide(some(1,9)), sample_separate(none), sample_violation(none)).
coincidence_profile(addition, rote_derived_fact_rule_misfire, deformation, ran(110), coincide(0), rate_pct(0), purport_violations(0), sample_coincide(none), sample_separate(some(1,3)), sample_violation(none)).
coincidence_profile(addition, round_then_adjust, productive, ran(900), coincide(900), rate_pct(100), purport_violations(0), sample_coincide(some(1,1)), sample_separate(none), sample_violation(none)).
coincidence_profile(addition, round_without_adjusting, deformation, ran(900), coincide(9), rate_pct(1), purport_violations(9), sample_coincide(some(10,10)), sample_separate(some(1,1)), sample_violation(some(10,10,claimed_incorrect_but_right))).
coincidence_profile(addition, unbalanced_make_base_compensation, deformation, ran(720), coincide(117), rate_pct(16), purport_violations(117), sample_coincide(some(1,10)), sample_separate(some(1,9)), sample_violation(some(1,10,claimed_incorrect_but_right))).
coincidence_profile(addition, wrong_carry_amount_to_next_column, deformation, ran(360), coincide(0), rate_pct(0), purport_violations(0), sample_coincide(none), sample_separate(some(1,19)), sample_violation(none)).
coincidence_profile(decimal, decimal_comparison_by_aligned_units, productive, ran(88), coincide(88), rate_pct(100), purport_violations(0), sample_coincide(some(decimal_pair(1,10,1,10),ignored)), sample_separate(none), sample_violation(none)).
coincidence_profile(decimal, decimal_fraction_place_value_comparison, productive, ran(6312), coincide(6312), rate_pct(100), purport_violations(0), sample_coincide(some(decimal_pair(1,10,2,10),ignored)), sample_separate(none), sample_violation(none)).
coincidence_profile(decimal, decimal_numeral_comparison_without_scale_alignment, deformation, ran(160), coincide(80), rate_pct(50), purport_violations(0), sample_coincide(some(decimal_pair(1,10,1,10),ignored)), sample_separate(some(decimal_pair(1,10,1,100),ignored)), sample_violation(none)).
coincidence_profile(decimal, decimal_scale_loss_comparison, deformation, ran(6240), coincide(4800), rate_pct(76), purport_violations(0), sample_coincide(some(decimal_pair(1,10,2,10),ignored)), sample_separate(some(decimal_pair(1,10,2,100),ignored)), sample_violation(none)).
coincidence_profile(division, divide_larger_by_smaller, deformation, ran(720), coincide(654), rate_pct(90), purport_violations(0), sample_coincide(some(1,1)), sample_separate(some(1,2)), sample_violation(none)).
coincidence_profile(division, fair_share_equal_groups, productive, ran(184), coincide(184), rate_pct(100), purport_violations(0), sample_coincide(some(1,1)), sample_separate(none), sample_violation(none)).
coincidence_profile(division, inverse_fact_decomposition, productive, ran(720), coincide(720), rate_pct(100), purport_violations(0), sample_coincide(some(1,1)), sample_separate(none), sample_violation(none)).
coincidence_profile(division, measure_groups_of_size, productive, ran(720), coincide(720), rate_pct(100), purport_violations(0), sample_coincide(some(1,1)), sample_separate(none), sample_violation(none)).
coincidence_profile(division, missing_factor_known_product_search, productive, ran(184), coincide(184), rate_pct(100), purport_violations(0), sample_coincide(some(1,1)), sample_separate(none), sample_violation(none)).
coincidence_profile(division, missing_factor_repeated_addition, productive, ran(184), coincide(184), rate_pct(100), purport_violations(0), sample_coincide(some(1,1)), sample_separate(none), sample_violation(none)).
coincidence_profile(division, name_group_count_as_share_size, deformation, ran(184), coincide(7), rate_pct(3), purport_violations(7), sample_coincide(some(1,1)), sample_separate(some(2,1)), sample_violation(some(1,1,claimed_incorrect_but_right))).
coincidence_profile(division, name_reached_total_as_quotient, deformation, ran(184), coincide(60), rate_pct(32), purport_violations(60), sample_coincide(some(1,1)), sample_separate(some(2,2)), sample_violation(some(1,1,claimed_incorrect_but_right))).
coincidence_profile(division, partial_quotient_chunking, productive, ran(720), coincide(720), rate_pct(100), purport_violations(0), sample_coincide(some(1,1)), sample_separate(none), sample_violation(none)).
coincidence_profile(division, share_into_divisor_groups, deformation, ran(536), coincide(0), rate_pct(0), purport_violations(0), sample_coincide(none), sample_separate(some(1,2)), sample_violation(none)).
coincidence_profile(division, stop_after_first_partial_quotient, deformation, ran(612), coincide(192), rate_pct(31), purport_violations(192), sample_coincide(some(3,2)), sample_separate(some(3,1)), sample_violation(some(3,2,claimed_incorrect_but_right))).
coincidence_profile(division, stop_after_one_known_fact, deformation, ran(612), coincide(192), rate_pct(31), purport_violations(192), sample_coincide(some(3,2)), sample_separate(some(3,1)), sample_violation(some(3,2,claimed_incorrect_but_right))).
coincidence_profile(division, stop_at_nearby_product_in_search, deformation, ran(172), coincide(0), rate_pct(0), purport_violations(0), sample_coincide(none), sample_separate(some(2,1)), sample_violation(none)).
coincidence_profile(fraction, add_numerator_denominator_comparison, deformation, ran(1582), coincide(786), rate_pct(49), purport_violations(786), sample_coincide(some(fraction_pair(1,2,2,2),unit(whole))), sample_separate(some(fraction_pair(1,2,1,3),unit(whole))), sample_violation(some(fraction_pair(1,2,2,2),unit(whole),claimed_incorrect_but_right))).
coincidence_profile(fraction, add_numerator_denominator_sum, deformation, ran(1764), coincide(0), rate_pct(0), purport_violations(0), sample_coincide(none), sample_separate(some(fraction_addend_pair(frac(1,2),frac(1,2)),unit(whole))), sample_violation(none)).
coincidence_profile(fraction, area_model_fraction_comparison, productive, ran(1678), coincide(1678), rate_pct(100), purport_violations(0), sample_coincide(some(fraction_pair(1,2,1,3),unit(whole))), sample_separate(none), sample_violation(none)).
coincidence_profile(fraction, area_model_part_of_part, productive, ran(1764), coincide(1764), rate_pct(100), purport_violations(0), sample_coincide(some(fraction_pair(1,2,1,2),unit(whole))), sample_separate(none), sample_violation(none)).
coincidence_profile(fraction, area_model_unequal_partition_piece_count, deformation, ran(1470), coincide(1206), rate_pct(82), purport_violations(1206), sample_coincide(some(fraction_pair(1,2,2,2),unit(whole))), sample_separate(some(fraction_pair(1,2,2,4),unit(whole))), sample_violation(some(fraction_pair(1,2,2,2),unit(whole),claimed_incorrect_but_right))).
coincidence_profile(fraction, benchmark_fraction_comparison, productive, ran(1678), coincide(1678), rate_pct(100), purport_violations(0), sample_coincide(some(fraction_pair(1,2,1,3),unit(whole))), sample_separate(none), sample_violation(none)).
coincidence_profile(fraction, common_denominator_fraction_addition, productive, ran(1764), coincide(1764), rate_pct(100), purport_violations(0), sample_coincide(some(fraction_addend_pair(frac(1,2),frac(1,2)),unit(whole))), sample_separate(none), sample_violation(none)).
coincidence_profile(fraction, common_denominator_fraction_subtraction, productive, ran(925), coincide(925), rate_pct(100), purport_violations(0), sample_coincide(some(fraction_minuend_subtrahend(frac(1,2),frac(1,2)),unit(whole))), sample_separate(none), sample_violation(none)).
coincidence_profile(fraction, common_unit_fraction_comparison, productive, ran(1678), coincide(1678), rate_pct(100), purport_violations(0), sample_coincide(some(fraction_pair(1,2,1,3),unit(whole))), sample_separate(none), sample_violation(none)).
coincidence_profile(fraction, cross_multiplication_rule_from_pattern, productive, ran(1764), coincide(1764), rate_pct(100), purport_violations(0), sample_coincide(some(fraction_pair(1,2,1,2),unit(whole))), sample_separate(none), sample_violation(none)).
coincidence_profile(fraction, cross_multiplication_rule_without_ground, deformation, ran(1764), coincide(1764), rate_pct(100), purport_violations(0), sample_coincide(some(fraction_pair(1,2,1,2),unit(whole))), sample_separate(none), sample_violation(none)).
coincidence_profile(fraction, gap_thinking_fraction_comparison, deformation, ran(1470), coincide(1102), rate_pct(74), purport_violations(0), sample_coincide(some(fraction_pair(1,2,1,3),unit(whole))), sample_separate(some(fraction_pair(1,2,2,4),unit(whole))), sample_violation(none)).
coincidence_profile(fraction, number_line_count_marks_not_intervals, deformation, ran(1678), coincide(1598), rate_pct(95), purport_violations(1598), sample_coincide(some(fraction_pair(1,2,1,3),unit(whole))), sample_separate(some(fraction_pair(1,2,2,4),unit(whole))), sample_violation(some(fraction_pair(1,2,1,3),unit(whole),claimed_incorrect_but_right))).
coincidence_profile(fraction, number_line_fraction_comparison, productive, ran(1678), coincide(1678), rate_pct(100), purport_violations(0), sample_coincide(some(fraction_pair(1,2,1,3),unit(whole))), sample_separate(none), sample_violation(none)).
coincidence_profile(fraction, set_model_fraction_comparison, productive, ran(1678), coincide(1678), rate_pct(100), purport_violations(0), sample_coincide(some(fraction_pair(1,2,1,3),unit(whole))), sample_separate(none), sample_violation(none)).
coincidence_profile(fraction, set_model_subset_size_focus, deformation, ran(1470), coincide(1206), rate_pct(82), purport_violations(1206), sample_coincide(some(fraction_pair(1,2,2,2),unit(whole))), sample_separate(some(fraction_pair(1,2,2,4),unit(whole))), sample_violation(some(fraction_pair(1,2,2,2),unit(whole),claimed_incorrect_but_right))).
coincidence_profile(multiplication, add_counts_without_composite_unit, deformation, ran(400), coincide(1), rate_pct(0), purport_violations(1), sample_coincide(some(2,2)), sample_separate(some(1,1)), sample_violation(some(2,2,claimed_incorrect_but_right))).
coincidence_profile(multiplication, add_instead_of_multiply, deformation, ran(400), coincide(1), rate_pct(0), purport_violations(1), sample_coincide(some(2,2)), sample_separate(some(1,1)), sample_violation(some(2,2,claimed_incorrect_but_right))).
coincidence_profile(multiplication, commute_factors_preserve_product, productive, ran(400), coincide(400), rate_pct(100), purport_violations(0), sample_coincide(some(1,1)), sample_separate(none), sample_violation(none)).
coincidence_profile(multiplication, coordinate_groups_items, productive, ran(400), coincide(400), rate_pct(100), purport_violations(0), sample_coincide(some(1,1)), sample_separate(none), sample_violation(none)).
coincidence_profile(multiplication, distribute_group_size_split, productive, ran(400), coincide(400), rate_pct(100), purport_violations(0), sample_coincide(some(1,1)), sample_separate(none), sample_violation(none)).
coincidence_profile(multiplication, drop_regrouping_remainder, deformation, ran(292), coincide(0), rate_pct(0), purport_violations(0), sample_coincide(none), sample_separate(some(1,1)), sample_violation(none)).
coincidence_profile(multiplication, drop_second_partial_product, deformation, ran(380), coincide(0), rate_pct(0), purport_violations(0), sample_coincide(none), sample_separate(some(1,2)), sample_violation(none)).
coincidence_profile(multiplication, known_product_adjustment, productive, ran(380), coincide(380), rate_pct(100), purport_violations(0), sample_coincide(some(2,1)), sample_separate(none), sample_violation(none)).
coincidence_profile(multiplication, known_product_without_adjustment, deformation, ran(380), coincide(0), rate_pct(0), purport_violations(0), sample_coincide(none), sample_separate(some(2,1)), sample_violation(none)).
coincidence_profile(multiplication, multiplication_fact_retrieval, productive, ran(400), coincide(400), rate_pct(100), purport_violations(0), sample_coincide(some(1,1)), sample_separate(none), sample_violation(none)).
coincidence_profile(multiplication, regroup_to_base_preserving_total, productive, ran(191), coincide(191), rate_pct(100), purport_violations(0), sample_coincide(some(1,1)), sample_separate(none), sample_violation(none)).
coincidence_profile(multiplication, repeat_equal_groups, productive, ran(400), coincide(400), rate_pct(100), purport_violations(0), sample_coincide(some(1,1)), sample_separate(none), sample_violation(none)).
coincidence_profile(multiplication, repeat_group_size_by_itself, deformation, ran(400), coincide(20), rate_pct(5), purport_violations(20), sample_coincide(some(1,1)), sample_separate(some(1,2)), sample_violation(some(1,1,claimed_incorrect_but_right))).
coincidence_profile(subtraction, add_instead_of_subtract_column, deformation, ran(465), coincide(0), rate_pct(0), purport_violations(0), sample_coincide(none), sample_separate(some(1,1)), sample_violation(none)).
coincidence_profile(subtraction, answer_as_endpoint_count_up, deformation, ran(465), coincide(0), rate_pct(0), purport_violations(0), sample_coincide(none), sample_separate(some(1,1)), sample_violation(none)).
coincidence_profile(subtraction, borrow_without_reducing_bases, deformation, ran(162), coincide(0), rate_pct(0), purport_violations(0), sample_coincide(none), sample_separate(some(10,1)), sample_violation(none)).
coincidence_profile(subtraction, compare_by_matching_difference, productive, ran(900), coincide(900), rate_pct(100), purport_violations(0), sample_coincide(some(1,1)), sample_separate(none), sample_violation(none)).
coincidence_profile(subtraction, compare_returns_larger_count, deformation, ran(870), coincide(0), rate_pct(0), purport_violations(0), sample_coincide(none), sample_separate(some(1,2)), sample_violation(none)).
coincidence_profile(subtraction, decompose_base_for_ones, productive, ran(162), coincide(162), rate_pct(100), purport_violations(0), sample_coincide(some(10,1)), sample_separate(none), sample_violation(none)).
coincidence_profile(subtraction, drop_ones_after_base_takeaway, deformation, ran(198), coincide(0), rate_pct(0), purport_violations(0), sample_coincide(none), sample_separate(some(11,11)), sample_violation(none)).
coincidence_profile(subtraction, slide_subtrahend_only, deformation, ran(297), coincide(0), rate_pct(0), purport_violations(0), sample_coincide(none), sample_separate(some(10,1)), sample_violation(none)).
coincidence_profile(subtraction, smaller_from_larger_in_column, deformation, ran(162), coincide(0), rate_pct(0), purport_violations(0), sample_coincide(none), sample_separate(some(10,1)), sample_violation(none)).

no_return_within(addition, make_base_transfer, input(1, 3)).
no_return_within(subtraction, count_up_missing_addend, input(1, 13)).
no_return_within(subtraction, take_away_base_ones, input(1, 14)).
no_return_within(subtraction, sliding_constant_difference, input(1, 17)).

% Hand-patched from the 2026-08-03 review: the grid input above kills or hangs the isolated process.
unswept(addition, make_base_transfer, grid_input_no_return(input(1, 3))).
unswept(calculus, factor_cancel_substitute, no_truth_adapter_or_result_shape).
unswept(calculus, factor_cancel_without_common_factor, no_truth_adapter_or_result_shape).
unswept(counting, compare_cardinalities_one_to_one, no_truth_adapter_or_result_shape).
unswept(counting, compare_ones_digits_only, no_truth_adapter_or_result_shape).
unswept(counting, enumerate_collection_one_to_one, no_truth_adapter_or_result_shape).
unswept(counting, inscribe_cardinality, no_truth_adapter_or_result_shape).
unswept(counting, omit_highest_place_regrouping, no_truth_adapter_or_result_shape).
unswept(counting, place_value_comparison, no_truth_adapter_or_result_shape).
unswept(counting, recursive_place_value_inscription, no_truth_adapter_or_result_shape).
unswept(counting, spatial_extent_as_cardinality, no_truth_adapter_or_result_shape).
unswept(decimal, decimal_add_unaligned_numerals, no_truth_adapter_or_result_shape).
unswept(decimal, decimal_addition_by_aligned_units, no_truth_adapter_or_result_shape).
unswept(decimal, decimal_multiplication_rule, no_truth_adapter_or_result_shape).
unswept(decimal, decimal_point_rule_misapplication, no_truth_adapter_or_result_shape).
unswept(decimal, decimal_subtract_unaligned_numerals, no_truth_adapter_or_result_shape).
unswept(decimal, decimal_subtraction_by_aligned_units, no_truth_adapter_or_result_shape).
unswept(division, long_division, no_truth_adapter_or_result_shape).
unswept(division, reject_known_product_match, no_truth_adapter_or_result_shape).
unswept(division, sum_dividend_and_divisor, no_truth_adapter_or_result_shape).
unswept(fraction, clear_inner_referent, no_truth_adapter_or_result_shape).
unswept(fraction, improper_fraction_chain_loss, no_truth_adapter_or_result_shape).
unswept(fraction, improper_fraction_iteration, no_truth_adapter_or_result_shape).
unswept(fraction, iterate_given_overshoot, no_truth_adapter_or_result_shape).
unswept(fraction, iterate_only_no_reverse, no_truth_adapter_or_result_shape).
unswept(fraction, measurement_division, no_truth_adapter_or_result_shape).
unswept(fraction, recursive_partition, no_truth_adapter_or_result_shape).
unswept(fraction, reversible_measurement_division, no_truth_adapter_or_result_shape).
unswept(fraction, solve_for_unit, no_truth_adapter_or_result_shape).
unswept(fraction, splitting, no_truth_adapter_or_result_shape).
unswept(fraction, unit_fraction_iteration, no_truth_adapter_or_result_shape).
unswept(fraction, unit_fraction_partition, no_truth_adapter_or_result_shape).
unswept(fraction, whole_number_grab, no_truth_adapter_or_result_shape).
unswept(geometry, area_as_perimeter_count, no_truth_adapter_or_result_shape).
unswept(geometry, rectangle_area_unit_iteration, no_truth_adapter_or_result_shape).
unswept(integer, signed_addition_with_sign_relation, no_truth_adapter_or_result_shape).
unswept(multiplication, add_numbers_as_common_multiple, no_truth_adapter_or_result_shape).
unswept(multiplication, common_factor_intersection, no_truth_adapter_or_result_shape).
unswept(multiplication, common_multiple_sequence, no_truth_adapter_or_result_shape).
unswept(multiplication, context_free_fact_family_guess, no_truth_adapter_or_result_shape).
unswept(multiplication, factors_of_first_number_only, no_truth_adapter_or_result_shape).
unswept(multiplication, rigid_factor_order_roles, no_truth_adapter_or_result_shape).
unswept(multiplication, sequential_recompute_commuted_products, no_truth_adapter_or_result_shape).
unswept(probability, equiprobable_endpoint_counting, no_truth_adapter_or_result_shape).
unswept(probability, terminal_tree_endpoint_probability_sum, no_truth_adapter_or_result_shape).
unswept(ratio, additive_extension_of_ratio, no_truth_adapter_or_result_shape).
unswept(ratio, scale_ratio_unit, no_truth_adapter_or_result_shape).
unswept(subtraction, borrow_across_zero_cascade, no_truth_adapter_or_result_shape).
unswept(subtraction, borrow_across_zero_no_cascade, no_truth_adapter_or_result_shape).
