/** <module> Execution-verified JSON inputs for action automata
 *
 * Each row is admitted after the Hermes worker's strategy_trace seam returns
 * ok:true for its concrete JSON example.  The registry signature remains the
 * broad type declaration; these facts record runnable JSON at the boundary.
 */
:- module(automaton_input_contracts,
          [ automaton_input_contract/5,
            automaton_observed_input_contract/3
          ]).

automaton_input_contract(addition, base_ones_chunking, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":47,\"b\":28}', verified(strategy_trace_ok)).
automaton_input_contract(addition, column_addition_with_carrying, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":47,\"b\":28}', verified(strategy_trace_ok)).
automaton_input_contract(addition, count_all_instead_of_known_fact, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":12,\"b\":3}', verified(strategy_trace_ok)).
automaton_input_contract(addition, count_all_when_count_on_available, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":47,\"b\":28}', verified(strategy_trace_ok)).
automaton_input_contract(addition, count_on_from_larger, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":47,\"b\":28}', verified(strategy_trace_ok)).
automaton_input_contract(addition, known_fact_retrieval, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":12,\"b\":3}', verified(strategy_trace_ok)).
automaton_input_contract(addition, make_base_transfer, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":47,\"b\":28}', verified(strategy_trace_ok)).
automaton_input_contract(addition, make_ten_drop_leftover, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":47,\"b\":28}', verified(strategy_trace_ok)).
automaton_input_contract(addition, make_ten_split_leftover, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":47,\"b\":28}', verified(strategy_trace_ok)).
automaton_input_contract(addition, round_then_adjust, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":47,\"b\":28}', verified(strategy_trace_ok)).
automaton_input_contract(addition, round_without_adjusting, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":47,\"b\":28}', verified(strategy_trace_ok)).
automaton_input_contract(decimal, decimal_add_unaligned_numerals, '{\"kind\":\"decimal_pair\",\"left\":{\"numeral\":\"integer\",\"scale\":\"positive_integer\"},\"right\":{\"numeral\":\"integer\",\"scale\":\"positive_integer\"}}', '{\"kind\":\"decimal_pair\",\"left\":{\"numeral\":25,\"scale\":10},\"right\":{\"numeral\":3,\"scale\":10}}', verified(strategy_trace_ok)).
automaton_input_contract(decimal, decimal_addition_by_aligned_units, '{\"kind\":\"decimal_pair\",\"left\":{\"numeral\":\"integer\",\"scale\":\"positive_integer\"},\"right\":{\"numeral\":\"integer\",\"scale\":\"positive_integer\"}}', '{\"kind\":\"decimal_pair\",\"left\":{\"numeral\":25,\"scale\":10},\"right\":{\"numeral\":3,\"scale\":10}}', verified(strategy_trace_ok)).
automaton_input_contract(decimal, decimal_comparison_by_aligned_units, '{\"kind\":\"decimal_pair\",\"left\":{\"numeral\":\"integer\",\"scale\":\"positive_integer\"},\"right\":{\"numeral\":\"integer\",\"scale\":\"positive_integer\"}}', '{\"kind\":\"decimal_pair\",\"left\":{\"numeral\":25,\"scale\":10},\"right\":{\"numeral\":3,\"scale\":10}}', verified(strategy_trace_ok)).
automaton_input_contract(decimal, decimal_fraction_place_value_comparison, '{\"kind\":\"decimal_pair\",\"left\":{\"numeral\":\"integer\",\"scale\":\"positive_integer\"},\"right\":{\"numeral\":\"integer\",\"scale\":\"positive_integer\"}}', '{\"kind\":\"decimal_pair\",\"left\":{\"numeral\":25,\"scale\":10},\"right\":{\"numeral\":3,\"scale\":10}}', verified(strategy_trace_ok)).
automaton_input_contract(decimal, decimal_multiplication_rule, '{\"kind\":\"decimal_pair\",\"left\":{\"numeral\":\"integer\",\"scale\":\"positive_integer\"},\"right\":{\"numeral\":\"integer\",\"scale\":\"positive_integer\"}}', '{\"kind\":\"decimal_pair\",\"left\":{\"numeral\":25,\"scale\":10},\"right\":{\"numeral\":3,\"scale\":10}}', verified(strategy_trace_ok)).
automaton_input_contract(decimal, decimal_numeral_comparison_without_scale_alignment, '{\"kind\":\"decimal_pair\",\"left\":{\"numeral\":\"integer\",\"scale\":\"positive_integer\"},\"right\":{\"numeral\":\"integer\",\"scale\":\"positive_integer\"}}', '{\"kind\":\"decimal_pair\",\"left\":{\"numeral\":25,\"scale\":10},\"right\":{\"numeral\":3,\"scale\":10}}', verified(strategy_trace_ok)).
automaton_input_contract(decimal, decimal_point_rule_misapplication, '{\"kind\":\"decimal_pair\",\"left\":{\"numeral\":\"integer\",\"scale\":\"positive_integer\"},\"right\":{\"numeral\":\"integer\",\"scale\":\"positive_integer\"}}', '{\"kind\":\"decimal_pair\",\"left\":{\"numeral\":25,\"scale\":10},\"right\":{\"numeral\":3,\"scale\":10}}', verified(strategy_trace_ok)).
automaton_input_contract(decimal, decimal_scale_loss_comparison, '{\"kind\":\"decimal_pair\",\"left\":{\"numeral\":\"integer\",\"scale\":\"positive_integer\"},\"right\":{\"numeral\":\"integer\",\"scale\":\"positive_integer\"}}', '{\"kind\":\"decimal_pair\",\"left\":{\"numeral\":25,\"scale\":10},\"right\":{\"numeral\":3,\"scale\":10}}', verified(strategy_trace_ok)).
automaton_input_contract(decimal, decimal_subtract_unaligned_numerals, '{\"kind\":\"decimal_pair\",\"left\":{\"numeral\":\"integer\",\"scale\":\"positive_integer\"},\"right\":{\"numeral\":\"integer\",\"scale\":\"positive_integer\"}}', '{\"kind\":\"decimal_pair\",\"left\":{\"numeral\":25,\"scale\":10},\"right\":{\"numeral\":3,\"scale\":10}}', verified(strategy_trace_ok)).
automaton_input_contract(decimal, decimal_subtraction_by_aligned_units, '{\"kind\":\"decimal_pair\",\"left\":{\"numeral\":\"integer\",\"scale\":\"positive_integer\"},\"right\":{\"numeral\":\"integer\",\"scale\":\"positive_integer\"}}', '{\"kind\":\"decimal_pair\",\"left\":{\"numeral\":25,\"scale\":10},\"right\":{\"numeral\":3,\"scale\":10}}', verified(strategy_trace_ok)).
automaton_input_contract(division, fair_share_equal_groups, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":12,\"b\":3}', verified(strategy_trace_ok)).
automaton_input_contract(division, divide_larger_by_smaller, '{\"a\":\"positive_integer\",\"b\":\"positive_integer\"}', '{\"a\":15,\"b\":100}', verified(strategy_trace_ok)).
automaton_input_contract(division, long_division, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":47,\"b\":28}', verified(strategy_trace_ok)).
automaton_input_contract(division, measure_groups_of_size, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":47,\"b\":28}', verified(strategy_trace_ok)).
automaton_input_contract(division, missing_factor_repeated_addition, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":12,\"b\":3}', verified(strategy_trace_ok)).
automaton_input_contract(division, name_group_count_as_share_size, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":12,\"b\":3}', verified(strategy_trace_ok)).
automaton_input_contract(division, name_reached_total_as_quotient, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":12,\"b\":3}', verified(strategy_trace_ok)).
automaton_input_contract(division, partial_quotient_chunking, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":47,\"b\":28}', verified(strategy_trace_ok)).
automaton_input_contract(division, share_into_divisor_groups, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":47,\"b\":28}', verified(strategy_trace_ok)).
automaton_input_contract(division, stop_after_first_partial_quotient, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":47,\"b\":28}', verified(strategy_trace_ok)).
automaton_input_contract(fraction, add_numerator_denominator_comparison, '{\"kind\":\"fraction_pair\",\"left\":{\"n\":\"integer\",\"d\":\"positive_integer\"},\"right\":{\"n\":\"integer\",\"d\":\"positive_integer\"}}', '{\"kind\":\"fraction_pair\",\"left\":{\"n\":3,\"d\":4},\"right\":{\"n\":2,\"d\":3}}', verified(strategy_trace_ok)).
automaton_input_contract(fraction, area_model_fraction_comparison, '{\"kind\":\"fraction_pair\",\"left\":{\"n\":\"integer\",\"d\":\"positive_integer\"},\"right\":{\"n\":\"integer\",\"d\":\"positive_integer\"}}', '{\"kind\":\"fraction_pair\",\"left\":{\"n\":3,\"d\":4},\"right\":{\"n\":2,\"d\":3}}', verified(strategy_trace_ok)).
automaton_input_contract(fraction, area_model_part_of_part, '{\"kind\":\"fraction_pair\",\"left\":{\"n\":\"integer\",\"d\":\"positive_integer\"},\"right\":{\"n\":\"integer\",\"d\":\"positive_integer\"}}', '{\"kind\":\"fraction_pair\",\"left\":{\"n\":3,\"d\":4},\"right\":{\"n\":2,\"d\":3}}', verified(strategy_trace_ok)).
automaton_input_contract(fraction, area_model_unequal_partition_piece_count, '{\"kind\":\"fraction_pair\",\"left\":{\"n\":\"integer\",\"d\":\"positive_integer\"},\"right\":{\"n\":\"integer\",\"d\":\"positive_integer\"}}', '{\"kind\":\"fraction_pair\",\"left\":{\"n\":3,\"d\":4},\"right\":{\"n\":2,\"d\":3}}', verified(strategy_trace_ok)).
automaton_input_contract(fraction, benchmark_fraction_comparison, '{\"kind\":\"fraction_pair\",\"left\":{\"n\":\"integer\",\"d\":\"positive_integer\"},\"right\":{\"n\":\"integer\",\"d\":\"positive_integer\"}}', '{\"kind\":\"fraction_pair\",\"left\":{\"n\":3,\"d\":4},\"right\":{\"n\":2,\"d\":3}}', verified(strategy_trace_ok)).
automaton_input_contract(fraction, common_unit_fraction_comparison, '{\"kind\":\"fraction_pair\",\"left\":{\"n\":\"integer\",\"d\":\"positive_integer\"},\"right\":{\"n\":\"integer\",\"d\":\"positive_integer\"}}', '{\"kind\":\"fraction_pair\",\"left\":{\"n\":3,\"d\":4},\"right\":{\"n\":2,\"d\":3}}', verified(strategy_trace_ok)).
automaton_input_contract(fraction, gap_thinking_fraction_comparison, '{\"kind\":\"fraction_pair\",\"left\":{\"n\":\"integer\",\"d\":\"positive_integer\"},\"right\":{\"n\":\"integer\",\"d\":\"positive_integer\"}}', '{\"kind\":\"fraction_pair\",\"left\":{\"n\":3,\"d\":4},\"right\":{\"n\":2,\"d\":3}}', verified(strategy_trace_ok)).
automaton_input_contract(fraction, improper_fraction_chain_loss, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":47,\"b\":28}', verified(strategy_trace_ok)).
automaton_input_contract(fraction, measurement_division, '{\"kind\":\"fraction_pair\",\"left\":{\"n\":\"integer\",\"d\":\"positive_integer\"},\"right\":{\"n\":\"integer\",\"d\":\"positive_integer\"}}', '{\"kind\":\"fraction_pair\",\"left\":{\"n\":3,\"d\":4},\"right\":{\"n\":2,\"d\":3}}', verified(strategy_trace_ok)).
automaton_input_contract(fraction, number_line_count_marks_not_intervals, '{\"kind\":\"fraction_pair\",\"left\":{\"n\":\"integer\",\"d\":\"positive_integer\"},\"right\":{\"n\":\"integer\",\"d\":\"positive_integer\"}}', '{\"kind\":\"fraction_pair\",\"left\":{\"n\":3,\"d\":4},\"right\":{\"n\":2,\"d\":3}}', verified(strategy_trace_ok)).
automaton_input_contract(fraction, number_line_fraction_comparison, '{\"kind\":\"fraction_pair\",\"left\":{\"n\":\"integer\",\"d\":\"positive_integer\"},\"right\":{\"n\":\"integer\",\"d\":\"positive_integer\"}}', '{\"kind\":\"fraction_pair\",\"left\":{\"n\":3,\"d\":4},\"right\":{\"n\":2,\"d\":3}}', verified(strategy_trace_ok)).
automaton_input_contract(fraction, reversible_measurement_division, '{\"kind\":\"fraction_pair\",\"left\":{\"n\":\"integer\",\"d\":\"positive_integer\"},\"right\":{\"n\":\"integer\",\"d\":\"positive_integer\"}}', '{\"kind\":\"fraction_pair\",\"left\":{\"n\":3,\"d\":4},\"right\":{\"n\":2,\"d\":3}}', verified(strategy_trace_ok)).
automaton_input_contract(fraction, set_model_fraction_comparison, '{\"kind\":\"fraction_pair\",\"left\":{\"n\":\"integer\",\"d\":\"positive_integer\"},\"right\":{\"n\":\"integer\",\"d\":\"positive_integer\"}}', '{\"kind\":\"fraction_pair\",\"left\":{\"n\":3,\"d\":4},\"right\":{\"n\":2,\"d\":3}}', verified(strategy_trace_ok)).
automaton_input_contract(fraction, set_model_subset_size_focus, '{\"kind\":\"fraction_pair\",\"left\":{\"n\":\"integer\",\"d\":\"positive_integer\"},\"right\":{\"n\":\"integer\",\"d\":\"positive_integer\"}}', '{\"kind\":\"fraction_pair\",\"left\":{\"n\":3,\"d\":4},\"right\":{\"n\":2,\"d\":3}}', verified(strategy_trace_ok)).
automaton_input_contract(fraction, unit_fraction_iteration, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":47,\"b\":28}', verified(strategy_trace_ok)).
automaton_input_contract(fraction, unit_fraction_partition, '{\"a\":\"integer\",\"b\":\"positive_integer\"}', '{\"a\":1,\"b\":4}', verified(strategy_trace_ok)).
automaton_input_contract(geometry, area_as_perimeter_count, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":47,\"b\":28}', verified(strategy_trace_ok)).
automaton_input_contract(geometry, rectangle_area_unit_iteration, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":47,\"b\":28}', verified(strategy_trace_ok)).
automaton_input_contract(integer, signed_addition_with_sign_relation, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":47,\"b\":28}', verified(strategy_trace_ok)).
automaton_input_contract(multiplication, add_numbers_as_common_multiple, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":47,\"b\":28}', verified(strategy_trace_ok)).
automaton_input_contract(multiplication, common_factor_intersection, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":47,\"b\":28}', verified(strategy_trace_ok)).
automaton_input_contract(multiplication, common_multiple_sequence, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":47,\"b\":28}', verified(strategy_trace_ok)).
automaton_input_contract(multiplication, commute_factors_preserve_product, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":47,\"b\":28}', verified(strategy_trace_ok)).
automaton_input_contract(multiplication, coordinate_groups_items, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":47,\"b\":28}', verified(strategy_trace_ok)).
automaton_input_contract(multiplication, distribute_group_size_split, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":47,\"b\":28}', verified(strategy_trace_ok)).
automaton_input_contract(multiplication, factors_of_first_number_only, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":47,\"b\":28}', verified(strategy_trace_ok)).
automaton_input_contract(multiplication, multiplication_fact_retrieval, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":47,\"b\":28}', verified(strategy_trace_ok)).
automaton_input_contract(multiplication, regroup_to_base_preserving_total, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":12,\"b\":3}', verified(strategy_trace_ok)).
automaton_input_contract(multiplication, repeat_equal_groups, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":47,\"b\":28}', verified(strategy_trace_ok)).
automaton_input_contract(multiplication, repeat_group_size_by_itself, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":47,\"b\":28}', verified(strategy_trace_ok)).
automaton_input_contract(ratio, additive_extension_of_ratio, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":47,\"b\":28}', verified(strategy_trace_ok)).
automaton_input_contract(ratio, scale_ratio_unit, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":47,\"b\":28}', verified(strategy_trace_ok)).
automaton_input_contract(subtraction, add_instead_of_subtract_column, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":47,\"b\":28}', verified(strategy_trace_ok)).
automaton_input_contract(subtraction, answer_as_endpoint_count_up, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":47,\"b\":28}', verified(strategy_trace_ok)).
automaton_input_contract(subtraction, compare_by_matching_difference, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":47,\"b\":28}', verified(strategy_trace_ok)).
automaton_input_contract(subtraction, count_up_missing_addend, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":47,\"b\":28}', verified(strategy_trace_ok)).
automaton_input_contract(subtraction, decompose_base_for_ones, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":47,\"b\":28}', verified(strategy_trace_ok)).
automaton_input_contract(subtraction, smaller_from_larger_in_column, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":47,\"b\":28}', verified(strategy_trace_ok)).
automaton_input_contract(subtraction, take_away_base_ones, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":47,\"b\":28}', verified(strategy_trace_ok)).

automaton_input_contract(addition, append_column_sum_without_carrying, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":47,\"b\":28}', verified(strategy_trace_ok)).
automaton_input_contract(addition, derived_fact_adjustment, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":8,\"b\":6}', verified(strategy_trace_ok)).
automaton_input_contract(addition, drop_carry_to_next_column, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":47,\"b\":28}', verified(strategy_trace_ok)).
automaton_input_contract(addition, dropped_ones_chunk, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":47,\"b\":28}', verified(strategy_trace_ok)).
automaton_input_contract(addition, rote_derived_fact_rule_misfire, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":8,\"b\":6}', verified(strategy_trace_ok)).
automaton_input_contract(addition, unbalanced_make_base_compensation, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":47,\"b\":28}', verified(strategy_trace_ok)).
automaton_input_contract(addition, wrong_carry_amount_to_next_column, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":47,\"b\":28}', verified(strategy_trace_ok)).
automaton_input_contract(subtraction, borrow_across_zero_cascade, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":102,\"b\":7}', verified(strategy_trace_ok)).
automaton_input_contract(subtraction, borrow_across_zero_no_cascade, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":102,\"b\":7}', verified(strategy_trace_ok)).
automaton_input_contract(subtraction, borrow_without_reducing_bases, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":53,\"b\":27}', verified(strategy_trace_ok)).
automaton_input_contract(subtraction, compare_returns_larger_count, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":9,\"b\":5}', verified(strategy_trace_ok)).
automaton_input_contract(subtraction, drop_ones_after_base_takeaway, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":53,\"b\":27}', verified(strategy_trace_ok)).
automaton_input_contract(subtraction, slide_subtrahend_only, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":53,\"b\":27}', verified(strategy_trace_ok)).
automaton_input_contract(subtraction, sliding_constant_difference, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":53,\"b\":27}', verified(strategy_trace_ok)).
automaton_input_contract(multiplication, add_counts_without_composite_unit, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":7,\"b\":8}', verified(strategy_trace_ok)).
automaton_input_contract(multiplication, add_instead_of_multiply, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":7,\"b\":8}', verified(strategy_trace_ok)).
automaton_input_contract(multiplication, context_free_fact_family_guess, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":7,\"b\":8}', verified(strategy_trace_ok)).
automaton_input_contract(multiplication, drop_regrouping_remainder, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":7,\"b\":8}', verified(strategy_trace_ok)).
automaton_input_contract(multiplication, drop_second_partial_product, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":7,\"b\":8}', verified(strategy_trace_ok)).
automaton_input_contract(multiplication, known_product_adjustment, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":7,\"b\":8}', verified(strategy_trace_ok)).
automaton_input_contract(multiplication, known_product_without_adjustment, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":7,\"b\":8}', verified(strategy_trace_ok)).
automaton_input_contract(multiplication, rigid_factor_order_roles, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":7,\"b\":8}', verified(strategy_trace_ok)).
automaton_input_contract(multiplication, sequential_recompute_commuted_products, '{\"a\":\"integer\",\"b\":\"integer\"}', '{\"a\":7,\"b\":8}', verified(strategy_trace_ok)).
automaton_input_contract(division, inverse_fact_decomposition, '{\"a\":\"integer\",\"b\":\"positive_integer\"}', '{\"a\":47,\"b\":3}', verified(strategy_trace_ok)).
automaton_input_contract(division, missing_factor_known_product_search, '{\"a\":\"integer\",\"b\":\"positive_integer\"}', '{\"a\":48,\"b\":6}', verified(strategy_trace_ok)).
automaton_input_contract(division, reject_known_product_match, '{\"a\":\"integer\",\"b\":\"positive_integer\"}', '{\"a\":48,\"b\":6}', verified(strategy_trace_ok)).
automaton_input_contract(division, stop_after_one_known_fact, '{\"a\":\"integer\",\"b\":\"positive_integer\"}', '{\"a\":47,\"b\":3}', verified(strategy_trace_ok)).
automaton_input_contract(division, stop_at_nearby_product_in_search, '{\"a\":\"integer\",\"b\":\"positive_integer\"}', '{\"a\":48,\"b\":6}', verified(strategy_trace_ok)).
automaton_input_contract(division, sum_dividend_and_divisor, '{\"a\":\"integer\",\"b\":\"positive_integer\"}', '{\"a\":96,\"b\":4}', verified(strategy_trace_ok)).
automaton_input_contract(fraction, clear_inner_referent, '{\"a\":\"positive_integer\",\"b\":\"positive_integer\"}', '{\"a\":3,\"b\":4}', verified(strategy_trace_ok)).
automaton_input_contract(fraction, cross_multiplication_rule_from_pattern, '{\"kind\":\"fraction_pair\",\"left\":{\"n\":\"integer\",\"d\":\"positive_integer\"},\"right\":{\"n\":\"integer\",\"d\":\"positive_integer\"}}', '{\"kind\":\"fraction_pair\",\"left\":{\"n\":3,\"d\":4},\"right\":{\"n\":2,\"d\":5}}', verified(strategy_trace_ok)).
automaton_input_contract(fraction, cross_multiplication_rule_without_ground, '{\"kind\":\"fraction_pair\",\"left\":{\"n\":\"integer\",\"d\":\"positive_integer\"},\"right\":{\"n\":\"integer\",\"d\":\"positive_integer\"}}', '{\"kind\":\"fraction_pair\",\"left\":{\"n\":3,\"d\":4},\"right\":{\"n\":2,\"d\":5}}', verified(strategy_trace_ok)).
automaton_input_contract(fraction, improper_fraction_iteration, '{\"a\":\"positive_integer\",\"b\":\"positive_integer\"}', '{\"a\":7,\"b\":4}', verified(strategy_trace_ok)).
automaton_input_contract(fraction, iterate_given_overshoot, '{\"a\":\"positive_integer\",\"b\":\"positive_integer\"}', '{\"a\":7,\"b\":4}', verified(strategy_trace_ok)).
automaton_input_contract(fraction, iterate_only_no_reverse, '{\"kind\":\"fraction_solve\",\"coefficient\":{\"n\":\"positive_integer\",\"d\":\"positive_integer\"},\"total\":\"positive_integer\"}', '{\"kind\":\"fraction_solve\",\"coefficient\":{\"n\":2,\"d\":3},\"total\":12}', verified(strategy_trace_ok)).
automaton_input_contract(fraction, recursive_partition, '{\"a\":\"positive_integer\",\"b\":\"positive_integer\"}', '{\"a\":3,\"b\":4}', verified(strategy_trace_ok)).
automaton_input_contract(fraction, solve_for_unit, '{\"kind\":\"fraction_solve\",\"coefficient\":{\"n\":\"positive_integer\",\"d\":\"positive_integer\"},\"total\":\"positive_integer\"}', '{\"kind\":\"fraction_solve\",\"coefficient\":{\"n\":2,\"d\":3},\"total\":12}', verified(strategy_trace_ok)).
automaton_input_contract(fraction, splitting, '{\"a\":\"integer\",\"b\":\"positive_integer\"}', '{\"a\":1,\"b\":4}', verified(strategy_trace_ok)).
automaton_input_contract(fraction, whole_number_grab, '{\"a\":\"positive_integer\",\"b\":\"positive_integer\"}', '{\"a\":3,\"b\":4}', verified(strategy_trace_ok)).
automaton_input_contract(calculus, factor_cancel_substitute, '{\"kind\":\"rational_limit\",\"numerator\":{\"coefficients\":[\"integer\"]},\"denominator\":{\"coefficients\":[\"integer\"]},\"at\":\"integer\"}', '{\"kind\":\"rational_limit\",\"numerator\":{\"coefficients\":[-2,1,1]},\"denominator\":{\"coefficients\":[-1,1]},\"at\":1}', verified(strategy_trace_ok)).
automaton_input_contract(calculus, factor_cancel_without_common_factor, '{\"kind\":\"rational_limit\",\"numerator\":{\"coefficients\":[\"integer\"]},\"denominator\":{\"coefficients\":[\"integer\"]},\"at\":\"integer\"}', '{\"kind\":\"rational_limit\",\"numerator\":{\"coefficients\":[1,1]},\"denominator\":{\"coefficients\":[2,1]},\"at\":1}', verified(strategy_trace_ok)).
automaton_input_contract(probability, equiprobable_endpoint_counting, '{\"kind\":\"terminal_path_tree\",\"paths\":[{\"winner\":\"atom\",\"probability\":{\"n\":\"positive_integer\",\"d\":\"positive_integer\"},\"events\":[\"atom\"]}],\"stake\":\"positive_number\"}', '{\"kind\":\"terminal_path_tree\",\"paths\":[{\"winner\":\"alice\",\"probability\":{\"n\":1,\"d\":2},\"events\":[\"alice_wins_first\"]},{\"winner\":\"bob\",\"probability\":{\"n\":1,\"d\":4},\"events\":[\"alice_wins_then_bob\",\"bob_wins\"]},{\"winner\":\"bob\",\"probability\":{\"n\":1,\"d\":4},\"events\":[\"bob_wins_then_bob\",\"bob_wins\"]}],\"stake\":60}', verified(strategy_trace_ok)).
automaton_input_contract(probability, terminal_tree_endpoint_probability_sum, '{\"kind\":\"terminal_path_tree\",\"paths\":[{\"winner\":\"atom\",\"probability\":{\"n\":\"positive_integer\",\"d\":\"positive_integer\"},\"events\":[\"atom\"]}],\"stake\":\"positive_number\"}', '{\"kind\":\"terminal_path_tree\",\"paths\":[{\"winner\":\"alice\",\"probability\":{\"n\":1,\"d\":2},\"events\":[\"alice_wins_first\"]},{\"winner\":\"bob\",\"probability\":{\"n\":1,\"d\":4},\"events\":[\"alice_wins_then_bob\",\"bob_wins\"]},{\"winner\":\"bob\",\"probability\":{\"n\":1,\"d\":4},\"events\":[\"bob_wins_then_bob\",\"bob_wins\"]}],\"stake\":60}', verified(strategy_trace_ok)).

% Fraction operands arrive as printed.  The published shape below is the
% fraction/fraction case ({"n","d"} per side, nonnegativity enforced by
% the machine's valid_fraction guard).  The runtime decoder also accepts
% {"whole","n","d"} (a mixed number) and {"whole"} (a whole number) per
% side; the checker's one-example-per-kind grammar has no union form, so
% those shapes are documented here and witnessed in the task-192 report
% rather than declared.  Subtraction's kind string names the
% minuend/subtrahend compound that keeps the two directions from ever
% routing into each other's machine.
automaton_input_contract(fraction, common_denominator_fraction_addition, '{\"kind\":\"fraction_addend_pair\",\"left\":{\"n\":\"integer\",\"d\":\"positive_integer\"},\"right\":{\"n\":\"integer\",\"d\":\"positive_integer\"}}', '{\"kind\":\"fraction_addend_pair\",\"left\":{\"n\":3,\"d\":4},\"right\":{\"n\":7,\"d\":8}}', verified(strategy_trace_ok)).
automaton_input_contract(fraction, common_denominator_fraction_subtraction, '{\"kind\":\"fraction_minuend_subtrahend\",\"left\":{\"n\":\"integer\",\"d\":\"positive_integer\"},\"right\":{\"n\":\"integer\",\"d\":\"positive_integer\"}}', '{\"kind\":\"fraction_minuend_subtrahend\",\"left\":{\"n\":2,\"d\":3},\"right\":{\"n\":1,\"d\":6}}', verified(strategy_trace_ok)).
automaton_input_contract(fraction, add_numerator_denominator_sum, '{\"kind\":\"fraction_addend_pair\",\"left\":{\"n\":\"integer\",\"d\":\"positive_integer\"},\"right\":{\"n\":\"integer\",\"d\":\"positive_integer\"}}', '{\"kind\":\"fraction_addend_pair\",\"left\":{\"n\":3,\"d\":4},\"right\":{\"n\":7,\"d\":8}}', verified(strategy_trace_ok)).

% A marked contract has a live strategy_trace witness represented in the
% generated transition table. It does not change the public contract shape.
automaton_observed_input_contract(fraction, unit_fraction_partition,
                                  strategy_trace_ok).
