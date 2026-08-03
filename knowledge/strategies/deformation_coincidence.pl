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
 * THIS input and requires them to differ. The corpus carries per-input validity for contextual and accidental coincidence. The relabeled kinds below now report zero purport violations across every normalizable swept input.
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

coincidence_profile(addition, append_column_sum_without_carrying, deformation, ran(405), coincide(45), rate_pct(11), purport_violations(0), sample_coincide(some(1,9)), sample_separate(some(1,19)), sample_violation(none)).
coincidence_profile(addition, base_ones_chunking, productive, ran(900), coincide(900), rate_pct(100), purport_violations(0), sample_coincide(some(1,1)), sample_separate(none), sample_violation(none)).
coincidence_profile(addition, column_addition_with_carrying, productive, ran(900), coincide(900), rate_pct(100), purport_violations(0), sample_coincide(some(1,1)), sample_separate(none), sample_violation(none)).
coincidence_profile(addition, count_all_instead_of_known_fact, deformation, ran(190), coincide(190), rate_pct(100), purport_violations(0), sample_coincide(some(1,1)), sample_separate(none), sample_violation(none)).
coincidence_profile(addition, count_all_when_count_on_available, deformation, ran(900), coincide(900), rate_pct(100), purport_violations(0), sample_coincide(some(1,1)), sample_separate(none), sample_violation(none)).
coincidence_profile(addition, count_on_from_larger, productive, ran(900), coincide(900), rate_pct(100), purport_violations(0), sample_coincide(some(1,1)), sample_separate(none), sample_violation(none)).
coincidence_profile(addition, derived_fact_adjustment, productive, ran(168), coincide(168), rate_pct(100), purport_violations(0), sample_coincide(some(1,2)), sample_separate(none), sample_violation(none)).
coincidence_profile(addition, drop_carry_to_next_column, deformation, ran(405), coincide(0), rate_pct(0), purport_violations(0), sample_coincide(none), sample_separate(some(1,9)), sample_violation(none)).
coincidence_profile(addition, dropped_ones_chunk, deformation, ran(900), coincide(90), rate_pct(10), purport_violations(0), sample_coincide(some(1,10)), sample_separate(some(1,1)), sample_violation(none)).
coincidence_profile(addition, known_fact_retrieval, productive, ran(190), coincide(190), rate_pct(100), purport_violations(0), sample_coincide(some(1,1)), sample_separate(none), sample_violation(none)).
coincidence_profile(addition, make_ten_drop_leftover, deformation, ran(603), coincide(45), rate_pct(7), purport_violations(0), sample_coincide(some(1,9)), sample_separate(some(2,9)), sample_violation(none)).
coincidence_profile(addition, make_ten_split_leftover, productive, ran(603), coincide(603), rate_pct(100), purport_violations(0), sample_coincide(some(1,9)), sample_separate(none), sample_violation(none)).
coincidence_profile(addition, rote_derived_fact_rule_misfire, deformation, ran(110), coincide(0), rate_pct(0), purport_violations(0), sample_coincide(none), sample_separate(some(1,3)), sample_violation(none)).
coincidence_profile(addition, round_then_adjust, productive, ran(900), coincide(900), rate_pct(100), purport_violations(0), sample_coincide(some(1,1)), sample_separate(none), sample_violation(none)).
coincidence_profile(addition, round_without_adjusting, deformation, ran(900), coincide(9), rate_pct(1), purport_violations(0), sample_coincide(some(10,10)), sample_separate(some(1,1)), sample_violation(none)).
coincidence_profile(addition, unbalanced_make_base_compensation, deformation, ran(720), coincide(117), rate_pct(16), purport_violations(0), sample_coincide(some(1,10)), sample_separate(some(1,9)), sample_violation(none)).
coincidence_profile(addition, wrong_carry_amount_to_next_column, deformation, ran(360), coincide(0), rate_pct(0), purport_violations(0), sample_coincide(none), sample_separate(some(1,19)), sample_violation(none)).
coincidence_profile(counting, compare_cardinalities_one_to_one, productive, ran(1215), coincide(1215), rate_pct(100), purport_violations(0), sample_coincide(some(counts(2,1),extents(1,1))), sample_separate(none), sample_violation(none)).
coincidence_profile(counting, place_value_comparison, productive, ran(36), coincide(36), rate_pct(100), purport_violations(0), sample_coincide(some(counts(2,1),base(10))), sample_separate(none), sample_violation(none)).
coincidence_profile(counting, spatial_extent_as_cardinality, deformation, ran(756), coincide(0), rate_pct(0), purport_violations(0), sample_coincide(none), sample_separate(some(counts(1,1),extents(2,1))), sample_violation(none)).
coincidence_profile(decimal, decimal_add_unaligned_numerals, deformation, ran(6400), coincide(3200), rate_pct(50), purport_violations(0), sample_coincide(some(decimal_pair(1,10,1,10),ignored)), sample_separate(some(decimal_pair(1,10,1,100),ignored)), sample_violation(none)).
coincidence_profile(decimal, decimal_addition_by_aligned_units, productive, ran(6400), coincide(6400), rate_pct(100), purport_violations(0), sample_coincide(some(decimal_pair(1,10,1,10),ignored)), sample_separate(none), sample_violation(none)).
coincidence_profile(decimal, decimal_comparison_by_aligned_units, productive, ran(6400), coincide(6400), rate_pct(100), purport_violations(0), sample_coincide(some(decimal_pair(1,10,1,10),ignored)), sample_separate(none), sample_violation(none)).
coincidence_profile(decimal, decimal_fraction_place_value_comparison, productive, ran(6400), coincide(6400), rate_pct(100), purport_violations(0), sample_coincide(some(decimal_pair(1,10,1,10),ignored)), sample_separate(none), sample_violation(none)).
coincidence_profile(decimal, decimal_multiplication_rule, productive, ran(6400), coincide(6400), rate_pct(100), purport_violations(0), sample_coincide(some(decimal_pair(1,10,1,10),ignored)), sample_separate(none), sample_violation(none)).
coincidence_profile(decimal, decimal_numeral_comparison_without_scale_alignment, deformation, ran(6400), coincide(4880), rate_pct(76), purport_violations(0), sample_coincide(some(decimal_pair(1,10,1,10),ignored)), sample_separate(some(decimal_pair(1,10,1,100),ignored)), sample_violation(none)).
coincidence_profile(decimal, decimal_scale_loss_comparison, deformation, ran(6400), coincide(4880), rate_pct(76), purport_violations(0), sample_coincide(some(decimal_pair(1,10,1,10),ignored)), sample_separate(some(decimal_pair(1,10,1,100),ignored)), sample_violation(none)).
coincidence_profile(decimal, decimal_subtract_unaligned_numerals, deformation, ran(2524), coincide(1640), rate_pct(64), purport_violations(0), sample_coincide(some(decimal_pair(1,10,1,10),ignored)), sample_separate(some(decimal_pair(1,10,1,100),ignored)), sample_violation(none)).
coincidence_profile(decimal, decimal_subtraction_by_aligned_units, productive, ran(3244), coincide(3244), rate_pct(100), purport_violations(0), sample_coincide(some(decimal_pair(1,10,1,10),ignored)), sample_separate(none), sample_violation(none)).
coincidence_profile(division, divide_larger_by_smaller, deformation, ran(720), coincide(654), rate_pct(90), purport_violations(0), sample_coincide(some(1,1)), sample_separate(some(1,2)), sample_violation(none)).
coincidence_profile(division, fair_share_equal_groups, productive, ran(184), coincide(184), rate_pct(100), purport_violations(0), sample_coincide(some(1,1)), sample_separate(none), sample_violation(none)).
coincidence_profile(division, inverse_fact_decomposition, productive, ran(720), coincide(720), rate_pct(100), purport_violations(0), sample_coincide(some(1,1)), sample_separate(none), sample_violation(none)).
coincidence_profile(division, measure_groups_of_size, productive, ran(720), coincide(720), rate_pct(100), purport_violations(0), sample_coincide(some(1,1)), sample_separate(none), sample_violation(none)).
coincidence_profile(division, missing_factor_known_product_search, productive, ran(184), coincide(184), rate_pct(100), purport_violations(0), sample_coincide(some(1,1)), sample_separate(none), sample_violation(none)).
coincidence_profile(division, missing_factor_repeated_addition, productive, ran(184), coincide(184), rate_pct(100), purport_violations(0), sample_coincide(some(1,1)), sample_separate(none), sample_violation(none)).
coincidence_profile(division, name_group_count_as_share_size, deformation, ran(184), coincide(7), rate_pct(3), purport_violations(0), sample_coincide(some(1,1)), sample_separate(some(2,1)), sample_violation(none)).
coincidence_profile(division, name_reached_total_as_quotient, deformation, ran(184), coincide(60), rate_pct(32), purport_violations(0), sample_coincide(some(1,1)), sample_separate(some(2,2)), sample_violation(none)).
coincidence_profile(division, partial_quotient_chunking, productive, ran(720), coincide(720), rate_pct(100), purport_violations(0), sample_coincide(some(1,1)), sample_separate(none), sample_violation(none)).
coincidence_profile(division, share_into_divisor_groups, deformation, ran(536), coincide(0), rate_pct(0), purport_violations(0), sample_coincide(none), sample_separate(some(1,2)), sample_violation(none)).
coincidence_profile(division, stop_after_first_partial_quotient, deformation, ran(612), coincide(192), rate_pct(31), purport_violations(0), sample_coincide(some(3,2)), sample_separate(some(3,1)), sample_violation(none)).
coincidence_profile(division, stop_after_one_known_fact, deformation, ran(612), coincide(192), rate_pct(31), purport_violations(0), sample_coincide(some(3,2)), sample_separate(some(3,1)), sample_violation(none)).
coincidence_profile(division, stop_at_nearby_product_in_search, deformation, ran(172), coincide(0), rate_pct(0), purport_violations(0), sample_coincide(none), sample_separate(some(2,1)), sample_violation(none)).
coincidence_profile(fraction, add_numerator_denominator_comparison, deformation, ran(1764), coincide(828), rate_pct(46), purport_violations(0), sample_coincide(some(fraction_pair(1,2,1,2),unit(whole))), sample_separate(some(fraction_pair(1,2,1,3),unit(whole))), sample_violation(none)).
coincidence_profile(fraction, add_numerator_denominator_sum, deformation, ran(1764), coincide(0), rate_pct(0), purport_violations(0), sample_coincide(none), sample_separate(some(fraction_addend_pair(frac(1,2),frac(1,2)),unit(whole))), sample_violation(none)).
coincidence_profile(fraction, area_model_fraction_comparison, productive, ran(1764), coincide(1764), rate_pct(100), purport_violations(0), sample_coincide(some(fraction_pair(1,2,1,2),unit(whole))), sample_separate(none), sample_violation(none)).
coincidence_profile(fraction, area_model_part_of_part, productive, ran(1764), coincide(1764), rate_pct(100), purport_violations(0), sample_coincide(some(fraction_pair(1,2,1,2),unit(whole))), sample_separate(none), sample_violation(none)).
coincidence_profile(fraction, area_model_unequal_partition_piece_count, deformation, ran(1764), coincide(1248), rate_pct(70), purport_violations(0), sample_coincide(some(fraction_pair(1,2,1,2),unit(whole))), sample_separate(some(fraction_pair(1,2,1,3),unit(whole))), sample_violation(none)).
coincidence_profile(fraction, benchmark_fraction_comparison, productive, ran(1764), coincide(1764), rate_pct(100), purport_violations(0), sample_coincide(some(fraction_pair(1,2,1,2),unit(whole))), sample_separate(none), sample_violation(none)).
coincidence_profile(fraction, co_denominator_count_on_from_larger, productive, ran(252), coincide(252), rate_pct(100), purport_violations(0), sample_coincide(some(fraction_pair(1,2,1,2),unit(whole))), sample_separate(none), sample_violation(none)).
coincidence_profile(fraction, co_denominator_make_base_transfer, productive, ran(42), coincide(42), rate_pct(100), purport_violations(0), sample_coincide(some(fraction_pair(4,2,6,2),unit(whole))), sample_separate(none), sample_violation(none)).
coincidence_profile(fraction, common_denominator_fraction_addition, productive, ran(1764), coincide(1764), rate_pct(100), purport_violations(0), sample_coincide(some(fraction_addend_pair(frac(1,2),frac(1,2)),unit(whole))), sample_separate(none), sample_violation(none)).
coincidence_profile(fraction, common_denominator_fraction_subtraction, productive, ran(925), coincide(925), rate_pct(100), purport_violations(0), sample_coincide(some(fraction_minuend_subtrahend(frac(1,2),frac(1,2)),unit(whole))), sample_separate(none), sample_violation(none)).
coincidence_profile(fraction, common_unit_fraction_comparison, productive, ran(1764), coincide(1764), rate_pct(100), purport_violations(0), sample_coincide(some(fraction_pair(1,2,1,2),unit(whole))), sample_separate(none), sample_violation(none)).
coincidence_profile(fraction, cross_multiplication_rule_from_pattern, productive, ran(1764), coincide(1764), rate_pct(100), purport_violations(0), sample_coincide(some(fraction_pair(1,2,1,2),unit(whole))), sample_separate(none), sample_violation(none)).
coincidence_profile(fraction, cross_multiplication_rule_without_ground, deformation, ran(1764), coincide(1764), rate_pct(100), purport_violations(0), sample_coincide(some(fraction_pair(1,2,1,2),unit(whole))), sample_separate(none), sample_violation(none)).
coincidence_profile(fraction, gap_thinking_fraction_comparison, deformation, ran(1764), coincide(1164), rate_pct(65), purport_violations(0), sample_coincide(some(fraction_pair(1,2,1,2),unit(whole))), sample_separate(some(fraction_pair(1,2,2,3),unit(whole))), sample_violation(none)).
coincidence_profile(fraction, number_line_count_marks_not_intervals, deformation, ran(1764), coincide(1640), rate_pct(92), purport_violations(0), sample_coincide(some(fraction_pair(1,2,1,2),unit(whole))), sample_separate(some(fraction_pair(1,2,2,3),unit(whole))), sample_violation(none)).
coincidence_profile(fraction, number_line_fraction_comparison, productive, ran(1764), coincide(1764), rate_pct(100), purport_violations(0), sample_coincide(some(fraction_pair(1,2,1,2),unit(whole))), sample_separate(none), sample_violation(none)).
coincidence_profile(fraction, set_model_fraction_comparison, productive, ran(1764), coincide(1764), rate_pct(100), purport_violations(0), sample_coincide(some(fraction_pair(1,2,1,2),unit(whole))), sample_separate(none), sample_violation(none)).
coincidence_profile(fraction, set_model_subset_size_focus, deformation, ran(1764), coincide(1248), rate_pct(70), purport_violations(0), sample_coincide(some(fraction_pair(1,2,1,2),unit(whole))), sample_separate(some(fraction_pair(1,2,1,3),unit(whole))), sample_violation(none)).
coincidence_profile(multiplication, add_counts_without_composite_unit, deformation, ran(400), coincide(1), rate_pct(0), purport_violations(0), sample_coincide(some(2,2)), sample_separate(some(1,1)), sample_violation(none)).
coincidence_profile(multiplication, add_instead_of_multiply, deformation, ran(400), coincide(1), rate_pct(0), purport_violations(0), sample_coincide(some(2,2)), sample_separate(some(1,1)), sample_violation(none)).
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
coincidence_profile(multiplication, repeat_group_size_by_itself, deformation, ran(400), coincide(20), rate_pct(5), purport_violations(0), sample_coincide(some(1,1)), sample_separate(some(1,2)), sample_violation(none)).
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
no_return_within(subtraction, sliding_constant_difference, input(1, 17)).
no_return_within(subtraction, take_away_base_ones, input(1, 14)).

unswept(algebraic, balance_preserving_linear_solution, no_normalizable_grid_runs).
unswept(algebraic, contextual_linear_equation_construction, no_normalizable_grid_runs).
unswept(algebraic, distributive_expression_rewrite, no_normalizable_grid_runs).
unswept(algebraic, drop_distributed_term, no_normalizable_grid_runs).
unswept(algebraic, equation_truth_by_substitution, no_normalizable_grid_runs).
unswept(algebraic, exponent_as_multiplier, no_normalizable_grid_runs).
unswept(algebraic, exponent_as_repeated_factor, no_normalizable_grid_runs).
unswept(algebraic, exponential_equivalence_by_expansion, no_normalizable_grid_runs).
unswept(algebraic, guess_and_check_rule, no_normalizable_grid_runs).
unswept(algebraic, linear_pattern_contextual_rule, no_normalizable_grid_runs).
unswept(algebraic, one_sided_equation_operation, no_normalizable_grid_runs).
unswept(algebraic, operational_equals_left_value, no_normalizable_grid_runs).
unswept(algebraic, programming_expression_evaluation, no_normalizable_grid_runs).
unswept(algebraic, symbolic_expression_construction, no_normalizable_grid_runs).
unswept(calculus, factor_cancel_substitute, no_normalizable_grid_runs).
unswept(calculus, factor_cancel_without_common_factor, no_normalizable_grid_runs).
unswept(counting, compare_ones_digits_only, no_normalizable_grid_runs).
unswept(counting, enumerate_collection_one_to_one, no_normalizable_grid_runs).
unswept(counting, inscribe_cardinality, no_normalizable_grid_runs).
unswept(counting, omit_highest_place_regrouping, no_normalizable_grid_runs).
unswept(counting, recursive_place_value_inscription, no_normalizable_grid_runs).
unswept(decimal, change_decimal_place_name_without_regrouping, no_normalizable_grid_runs).
unswept(decimal, decimal_place_unit_regrouping, no_normalizable_grid_runs).
unswept(decimal, decimal_point_rule_misapplication, no_normalizable_grid_runs).
unswept(decimal, decimal_whole_number_reading, no_normalizable_grid_runs).
unswept(decimal, ecuadorian_decimal_long_division, no_normalizable_grid_runs).
unswept(decimal, positional_decimal_reading, no_normalizable_grid_runs).
unswept(decimal, recalled_result_scaling, no_normalizable_grid_runs).
unswept(division, long_division, no_normalizable_grid_runs).
unswept(division, reject_known_product_match, no_normalizable_grid_runs).
unswept(division, sum_dividend_and_divisor, no_normalizable_grid_runs).
unswept(fraction, clear_inner_referent, no_normalizable_grid_runs).
unswept(fraction, improper_fraction_chain_loss, no_normalizable_grid_runs).
unswept(fraction, improper_fraction_iteration, no_normalizable_grid_runs).
unswept(fraction, iterate_given_overshoot, no_normalizable_grid_runs).
unswept(fraction, iterate_only_no_reverse, no_normalizable_grid_runs).
unswept(fraction, measurement_division, no_normalizable_grid_runs).
unswept(fraction, recursive_partition, no_normalizable_grid_runs).
unswept(fraction, reversible_measurement_division, no_normalizable_grid_runs).
unswept(fraction, solve_for_unit, no_normalizable_grid_runs).
unswept(fraction, splitting, no_normalizable_grid_runs).
unswept(fraction, unit_fraction_iteration, no_normalizable_grid_runs).
unswept(fraction, unit_fraction_partition, no_normalizable_grid_runs).
unswept(fraction, whole_number_grab, no_normalizable_grid_runs).
unswept(geometry, angle_additive_composition, no_normalizable_grid_runs).
unswept(geometry, angle_as_ray_length, no_normalizable_grid_runs).
unswept(geometry, angle_turn_measurement, no_normalizable_grid_runs).
unswept(geometry, area_as_perimeter_count, no_normalizable_grid_runs).
unswept(geometry, area_preserving_polygon_decomposition, no_normalizable_grid_runs).
unswept(geometry, area_unit_covering, no_normalizable_grid_runs).
unswept(geometry, area_unit_scale_selection, no_normalizable_grid_runs).
unswept(geometry, axis_aligned_coordinate_distance, no_normalizable_grid_runs).
unswept(geometry, choose_first_area_unit_without_scale, no_normalizable_grid_runs).
unswept(geometry, compare_solid_volume_by_cube_count, no_normalizable_grid_runs).
unswept(geometry, compare_solid_volume_by_visible_extent, no_normalizable_grid_runs).
unswept(geometry, composite_prism_volume_sum, no_normalizable_grid_runs).
unswept(geometry, count_overlapping_area_tiles, no_normalizable_grid_runs).
unswept(geometry, decomposition_with_gap_or_overlap, no_normalizable_grid_runs).
unswept(geometry, dimensional_measure_unit_coordination, no_normalizable_grid_runs).
unswept(geometry, directed_difference_as_coordinate_distance, no_normalizable_grid_runs).
unswept(geometry, divide_volume_by_one_dimension, no_normalizable_grid_runs).
unswept(geometry, ignore_perimeter_rectangle_constraint, no_normalizable_grid_runs).
unswept(geometry, ignore_symmetry_multiplicity, no_normalizable_grid_runs).
unswept(geometry, linear_unit_for_area_or_volume, no_normalizable_grid_runs).
unswept(geometry, omit_half_in_triangle_area, no_normalizable_grid_runs).
unswept(geometry, omit_unlabeled_boundary_side, no_normalizable_grid_runs).
unswept(geometry, ordered_pair_coordinate_plot, no_normalizable_grid_runs).
unswept(geometry, orientation_bound_shape_classification, no_normalizable_grid_runs).
unswept(geometry, parallelogram_area_base_height, no_normalizable_grid_runs).
unswept(geometry, perimeter_two_sides_only, no_normalizable_grid_runs).
unswept(geometry, perimeter_uses_area_formula, no_normalizable_grid_runs).
unswept(geometry, polygon_perimeter_boundary_accumulation, no_normalizable_grid_runs).
unswept(geometry, polyhedron_surface_area_from_net, no_normalizable_grid_runs).
unswept(geometry, rectangle_area_perimeter_constraint_search, no_normalizable_grid_runs).
unswept(geometry, rectangle_area_unit_iteration, no_normalizable_grid_runs).
unswept(geometry, rectangle_factor_pair_search, no_normalizable_grid_runs).
unswept(geometry, rectangle_missing_side_from_area, no_normalizable_grid_runs).
unswept(geometry, rectangle_missing_side_from_perimeter, no_normalizable_grid_runs).
unswept(geometry, rectangle_perimeter_boundary_traversal, no_normalizable_grid_runs).
unswept(geometry, rectangle_perimeter_side_pair_search, no_normalizable_grid_runs).
unswept(geometry, rectangular_prism_missing_dimension_from_volume, no_normalizable_grid_runs).
unswept(geometry, rectangular_prism_volume_layer_iteration, no_normalizable_grid_runs).
unswept(geometry, rigid_shape_composition, no_normalizable_grid_runs).
unswept(geometry, shape_classification_by_defining_attributes, no_normalizable_grid_runs).
unswept(geometry, slanted_side_as_parallelogram_height, no_normalizable_grid_runs).
unswept(geometry, subtract_side_from_area, no_normalizable_grid_runs).
unswept(geometry, sum_overlapping_prism_volumes, no_normalizable_grid_runs).
unswept(geometry, symmetry_constrained_side_reconstruction, no_normalizable_grid_runs).
unswept(geometry, triangle_area_half_base_height, no_normalizable_grid_runs).
unswept(geometry, visible_faces_only_surface_area, no_normalizable_grid_runs).
unswept(integer, drop_sign_use_magnitude_sum, no_normalizable_grid_runs).
unswept(integer, inequality_as_boundary_point, no_normalizable_grid_runs).
unswept(integer, inequality_solution_set_representation, no_normalizable_grid_runs).
unswept(integer, order_by_magnitude_ignore_sign, no_normalizable_grid_runs).
unswept(integer, signed_addition_with_sign_relation, no_normalizable_grid_runs).
unswept(integer, signed_number_location_and_order, no_normalizable_grid_runs).
unswept(measurement, change_unit_label_without_scaling, no_normalizable_grid_runs).
unswept(measurement, count_marks_not_intervals, no_normalizable_grid_runs).
unswept(measurement, drop_unit_from_measured_quantity_change, no_normalizable_grid_runs).
unswept(measurement, linear_unit_iteration, no_normalizable_grid_runs).
unswept(measurement, liquid_volume_count_marks_not_intervals, no_normalizable_grid_runs).
unswept(measurement, liquid_volume_scale_reading, no_normalizable_grid_runs).
unswept(measurement, unit_conversion_by_iteration, no_normalizable_grid_runs).
unswept(measurement, unit_preserving_measured_quantity_change, no_normalizable_grid_runs).
unswept(multiplication, add_numbers_as_common_multiple, no_normalizable_grid_runs).
unswept(multiplication, common_factor_intersection, no_normalizable_grid_runs).
unswept(multiplication, common_multiple_sequence, no_normalizable_grid_runs).
unswept(multiplication, context_free_fact_family_guess, no_normalizable_grid_runs).
unswept(multiplication, factors_of_first_number_only, no_normalizable_grid_runs).
unswept(multiplication, rigid_factor_order_roles, no_normalizable_grid_runs).
unswept(multiplication, sequential_recompute_commuted_products, no_normalizable_grid_runs).
unswept(probability, equiprobable_endpoint_counting, no_normalizable_grid_runs).
unswept(probability, terminal_tree_endpoint_probability_sum, no_normalizable_grid_runs).
unswept(ratio, additive_extension_of_ratio, no_normalizable_grid_runs).
unswept(ratio, construct_referent_ratio_diagram, no_normalizable_grid_runs).
unswept(ratio, reverse_ratio_referent_order, no_normalizable_grid_runs).
unswept(ratio, scale_ratio_unit, no_normalizable_grid_runs).
unswept(statistics, box_plot_from_five_number_summary, no_normalizable_grid_runs).
unswept(statistics, categorical_frequency_bar_representation, no_normalizable_grid_runs).
unswept(statistics, distribution_summary_selection, no_normalizable_grid_runs).
unswept(statistics, dot_plot_frequency_representation, no_normalizable_grid_runs).
unswept(statistics, five_number_summary_and_iqr, no_normalizable_grid_runs).
unswept(statistics, histogram_equal_interval_representation, no_normalizable_grid_runs).
unswept(statistics, mean_absolute_deviation, no_normalizable_grid_runs).
unswept(statistics, mean_as_balance_point, no_normalizable_grid_runs).
unswept(statistics, mean_as_fair_share, no_normalizable_grid_runs).
unswept(statistics, mean_deviation_without_absolute_value, no_normalizable_grid_runs).
unswept(statistics, median_as_ordered_middle, no_normalizable_grid_runs).
unswept(statistics, mode_as_maximal_frequency, no_normalizable_grid_runs).
unswept(statistics, question_without_variability, no_normalizable_grid_runs).
unswept(statistics, statistical_question_variability_classification, no_normalizable_grid_runs).
unswept(subtraction, borrow_across_zero_cascade, no_normalizable_grid_runs).
unswept(subtraction, borrow_across_zero_no_cascade, no_normalizable_grid_runs).
