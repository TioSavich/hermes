/** <module> Registry for executable action automata
 *
 * A thin unifying surface over operation-specific action-pair modules.
 * This is the bridge clustering and monitoring-chart code should call before
 * it knows whether an action came from addition, subtraction, multiplication,
 * division, or a non-whole-number domain.
 */

:- module(action_automata_registry,
          [ run_action_automaton/6,
            action_automaton_cluster/3,
            action_automaton_vocabulary/3,
            action_automaton_signature/4,
            action_automaton_pair/4,
            action_automaton_hook/4
          ]).

:- use_module(math(sar_add_action_pairs)).
:- use_module(math(sar_sub_action_pairs)).
:- use_module(math(smr_mult_action_pairs)).
:- use_module(math(smr_div_action_pairs)).
:- use_module(math(fraction_action_pairs)).
:- use_module(math(decimal_action_pairs)).
:- use_module(math(integer_action_pairs)).
:- use_module(math(ratio_action_pairs)).
:- use_module(math(diagnostic_validation_action_pairs)).
:- use_module(math(calculus_limits_action_pairs)).
:- use_module(math(algebraic_action_pairs)).
:- use_module(math(probability_action_pairs)).
:- use_module(math(geometry_action_pairs)).
:- use_module(math(statistics_action_pairs)).
:- use_module(math(measurement_action_pairs)).
:- use_module(math(counting_action_pairs)).
:- use_module(standards(indiana/standard_k_ns_1), []).
:- use_module(standards(indiana/standard_k_ns_2), []).
:- use_module(standards(indiana/standard_k_ns_3), []).
:- use_module(standards(indiana/standard_k_ns_4), []).
:- use_module(standards(indiana/standard_k_ns_5_6), []).
:- use_module(standards(indiana/standard_k_ns_7), []).
:- use_module(standards(indiana/standard_k_ca_1_3), []).
:- use_module(standards(indiana/standard_1_ns_1), []).
:- use_module(standards(indiana/standard_1_ns_2), []).
:- use_module(standards(indiana/standard_1_ca_1), []).
:- use_module(standards(indiana/standard_1_ca_3), []).
:- use_module(standards(indiana/standard_2_ns_1), []).
:- use_module(standards(indiana/standard_2_ns_2_4), []).
:- use_module(standards(indiana/standard_2_ns_3), []).
:- use_module(standards(indiana/standard_2_ns_5), []).
:- use_module(standards(indiana/standard_2_ca_2), []).
:- use_module(standards(indiana/standard_3_ns_2), []).
:- use_module(standards(indiana/standard_3_ns_5), []).
:- use_module(standards(indiana/standard_3_ca_3_4), []).
:- use_module(standards(indiana/standard_3_ca_5), []).


%!  run_action_automaton(+Operation, +Kind, +Left, +Right, -Outcome, -Trace) is semidet.
%
%   Execute a whole-number action automaton. Operation selects the vocabulary
%   family; Left and Right are interpreted by that family.
run_action_automaton(addition, Kind, A, B, Outcome, Trace) :-
    run_additive_action(Kind, A, B, Outcome, Trace).
run_action_automaton(subtraction, Kind, M, S, Outcome, Trace) :-
    run_subtractive_action(Kind, M, S, Outcome, Trace).
run_action_automaton(multiplication, Kind, N, S, Outcome, Trace) :-
    run_multiplicative_action(Kind, N, S, Outcome, Trace).
run_action_automaton(division, Kind, Total, Divisor, Outcome, Trace) :-
    run_division_action(Kind, Total, Divisor, Outcome, Trace).
run_action_automaton(fraction, Kind, Count, Base, Outcome, Trace) :-
    run_fraction_action(Kind, Count, Base, Outcome, Trace).
run_action_automaton(decimal, Kind, Numeral, Scale, Outcome, Trace) :-
    run_decimal_action(Kind, Numeral, Scale, Outcome, Trace).
run_action_automaton(integer, Kind, A, B, Outcome, Trace) :-
    run_integer_action(Kind, A, B, Outcome, Trace).
run_action_automaton(ratio, Kind, A, B, Outcome, Trace) :-
    run_ratio_action(Kind, A, B, Outcome, Trace).
run_action_automaton(diagnostic, Kind, Proposed, Reference, Outcome, Trace) :-
    run_diagnostic_action(Kind, Proposed, Reference, Outcome, Trace).
run_action_automaton(calculus, Kind, Expression, Target, Outcome, Trace) :-
    run_calculus_action(Kind, Expression, Target, Outcome, Trace).
run_action_automaton(algebraic, Kind, Expression, Assignment, Outcome, Trace) :-
    run_algebraic_action(Kind, Expression, Assignment, Outcome, Trace).
run_action_automaton(probability, Kind, Paths, Stake, Outcome, Trace) :-
    run_probability_action(Kind, Paths, Stake, Outcome, Trace).
run_action_automaton(geometry, Kind, Left, Right, Outcome, Trace) :-
    run_geometry_action(Kind, Left, Right, Outcome, Trace).
run_action_automaton(statistics, Kind, Data, Context, Outcome, Trace) :-
    run_statistics_action(Kind, Data, Context, Outcome, Trace).
run_action_automaton(measurement, Kind, Measure, Unit, Outcome, Trace) :-
    run_measurement_action(Kind, Measure, Unit, Outcome, Trace).
run_action_automaton(counting, Kind, Count, Context, Outcome, Trace) :-
    run_counting_action(Kind, Count, Context, Outcome, Trace).


%!  action_automaton_cluster(+Operation, +Kind, -Cluster) is semidet.
action_automaton_cluster(addition, Kind, Cluster) :-
    action_cluster(Kind, Cluster).
action_automaton_cluster(subtraction, Kind, Cluster) :-
    subtractive_action_cluster(Kind, Cluster).
action_automaton_cluster(multiplication, Kind, Cluster) :-
    multiplicative_action_cluster(Kind, Cluster).
action_automaton_cluster(division, Kind, Cluster) :-
    division_action_cluster(Kind, Cluster).
action_automaton_cluster(fraction, Kind, Cluster) :-
    fraction_action_cluster(Kind, Cluster).
action_automaton_cluster(decimal, Kind, Cluster) :-
    decimal_action_cluster(Kind, Cluster).
action_automaton_cluster(integer, Kind, Cluster) :-
    integer_action_cluster(Kind, Cluster).
action_automaton_cluster(ratio, Kind, Cluster) :-
    ratio_action_cluster(Kind, Cluster).
action_automaton_cluster(diagnostic, Kind, Cluster) :-
    diagnostic_action_cluster(Kind, Cluster).
action_automaton_cluster(calculus, Kind, Cluster) :-
    calculus_action_cluster(Kind, Cluster).
action_automaton_cluster(algebraic, Kind, Cluster) :-
    algebraic_action_cluster(Kind, Cluster).
action_automaton_cluster(probability, Kind, Cluster) :-
    probability_action_cluster(Kind, Cluster).
action_automaton_cluster(geometry, Kind, Cluster) :-
    geometry_action_cluster(Kind, Cluster).
action_automaton_cluster(statistics, Kind, Cluster) :-
    statistics_action_cluster(Kind, Cluster).
action_automaton_cluster(measurement, Kind, Cluster) :-
    measurement_action_cluster(Kind, Cluster).
action_automaton_cluster(counting, Kind, Cluster) :-
    counting_action_cluster(Kind, Cluster).


%!  action_automaton_vocabulary(+Operation, +Kind, -Vocabulary) is semidet.
action_automaton_vocabulary(addition, Kind, Vocabulary) :-
    action_vocabulary(Kind, Vocabulary).
action_automaton_vocabulary(subtraction, Kind, Vocabulary) :-
    subtractive_action_vocabulary(Kind, Vocabulary).
action_automaton_vocabulary(multiplication, Kind, Vocabulary) :-
    multiplicative_action_vocabulary(Kind, Vocabulary).
action_automaton_vocabulary(division, Kind, Vocabulary) :-
    division_action_vocabulary(Kind, Vocabulary).
action_automaton_vocabulary(fraction, Kind, Vocabulary) :-
    fraction_action_vocabulary(Kind, Vocabulary).
action_automaton_vocabulary(decimal, Kind, Vocabulary) :-
    decimal_action_vocabulary(Kind, Vocabulary).
action_automaton_vocabulary(integer, Kind, Vocabulary) :-
    integer_action_vocabulary(Kind, Vocabulary).
action_automaton_vocabulary(ratio, Kind, Vocabulary) :-
    ratio_action_vocabulary(Kind, Vocabulary).
action_automaton_vocabulary(diagnostic, Kind, Vocabulary) :-
    diagnostic_action_vocabulary(Kind, Vocabulary).
action_automaton_vocabulary(calculus, Kind, Vocabulary) :-
    calculus_action_vocabulary(Kind, Vocabulary).
action_automaton_vocabulary(algebraic, Kind, Vocabulary) :-
    algebraic_action_vocabulary(Kind, Vocabulary).
action_automaton_vocabulary(probability, Kind, Vocabulary) :-
    probability_action_vocabulary(Kind, Vocabulary).
action_automaton_vocabulary(geometry, Kind, Vocabulary) :-
    geometry_action_vocabulary(Kind, Vocabulary).
action_automaton_vocabulary(statistics, Kind, Vocabulary) :-
    statistics_action_vocabulary(Kind, Vocabulary).
action_automaton_vocabulary(measurement, Kind, Vocabulary) :-
    measurement_action_vocabulary(Kind, Vocabulary).
action_automaton_vocabulary(counting, Kind, Vocabulary) :-
    counting_action_vocabulary(Kind, Vocabulary).


%!  action_automaton_signature(+Operation, +Kind, -Input, -Output) is semidet.
%
%   Machine-readable invocation contracts for the newer cross-domain actions.
%   These are schemas, not concrete lesson instances: they tell a planner what
%   information must be recovered from a task before run_action_automaton/6 can
%   execute without pretending the curriculum source supplied that information.
action_automaton_signature(fraction, number_line_fraction_comparison,
                           inputs(two_nonnegative_fractions, unit_interval),
                           fraction_order_relation).
action_automaton_signature(fraction,
                           number_line_count_marks_not_intervals,
                           inputs(two_nonnegative_fractions, unit_interval),
                           incorrect_fraction_order_relation).
action_automaton_signature(decimal, positional_decimal_reading,
                           inputs(integer_numeral, positive_power_of_ten_scale),
                           decimal_value).
action_automaton_signature(decimal, decimal_whole_number_reading,
                           inputs(integer_numeral, positive_power_of_ten_scale),
                           whole_number_value).
action_automaton_signature(decimal, decimal_comparison_by_aligned_units,
                           inputs(decimal_pair, ignored),
                           decimal_magnitude_relation).
action_automaton_signature(
    decimal, decimal_numeral_comparison_without_scale_alignment,
    inputs(decimal_pair, ignored), decimal_magnitude_relation).
action_automaton_signature(decimal, decimal_addition_by_aligned_units,
                           inputs(decimal_pair, ignored), decimal_sum).
action_automaton_signature(decimal, decimal_add_unaligned_numerals,
                           inputs(decimal_pair, ignored), decimal_sum).
action_automaton_signature(decimal, decimal_subtraction_by_aligned_units,
                           inputs(decimal_pair, ignored), decimal_difference).
action_automaton_signature(decimal, decimal_subtract_unaligned_numerals,
                           inputs(decimal_pair, ignored), decimal_difference).
action_automaton_signature(decimal, decimal_place_unit_regrouping,
                           inputs(decimal_unit_conversion, ignored),
                           equivalent_decimal_units).
action_automaton_signature(
    decimal, change_decimal_place_name_without_regrouping,
    inputs(decimal_unit_conversion, ignored), equivalent_decimal_units).
action_automaton_signature(decimal, decimal_multiplication_rule,
                           inputs(decimal_pair, ignored), decimal_product).
action_automaton_signature(decimal, decimal_point_rule_misapplication,
                           inputs(decimal_pair, ignored), decimal_product).
action_automaton_signature(decimal, ecuadorian_decimal_long_division,
                           inputs(decimal_pair, ignored), decimal_quotient).
action_automaton_signature(decimal, recalled_result_scaling,
                           inputs(scaled_division_pair, recalled_quotient),
                           scaled_quotient).
action_automaton_signature(multiplication, common_factor_intersection,
                           inputs(two_positive_integers, ignored),
                           common_factors_and_greatest_common_factor).
action_automaton_signature(multiplication, factors_of_first_number_only,
                           inputs(two_positive_integers, ignored),
                           first_number_factors_as_common_factors).
action_automaton_signature(multiplication, common_multiple_sequence,
                           inputs(two_positive_integers, ignored),
                           generated_common_multiples_and_lcm).
action_automaton_signature(multiplication, add_numbers_as_common_multiple,
                           inputs(two_positive_integers, ignored),
                           sum_as_candidate_common_multiple).
action_automaton_signature(integer, signed_addition_with_sign_relation,
                           inputs(signed_integer, signed_integer), signed_sum).
action_automaton_signature(integer, drop_sign_use_magnitude_sum,
                           inputs(signed_integer, signed_integer), unsigned_sum).
action_automaton_signature(integer, signed_number_location_and_order,
                           inputs(nonempty_signed_integer_list, number_line),
                           ordered_signed_values).
action_automaton_signature(integer, order_by_magnitude_ignore_sign,
                           inputs(nonempty_signed_integer_list, number_line),
                           magnitude_ordered_values).
action_automaton_signature(integer, inequality_solution_set_representation,
                           inputs(one_variable_integer_inequality, number_line),
                           inequality_solution_ray).
action_automaton_signature(integer, inequality_as_boundary_point,
                           inputs(one_variable_integer_inequality, number_line),
                           boundary_as_single_solution).
action_automaton_signature(ratio, scale_ratio_unit,
                           inputs(ratio_pair_with_scale_factor, ignored),
                           equivalent_ratio_pair).
action_automaton_signature(ratio, additive_extension_of_ratio,
                           inputs(ratio_pair_with_scale_factor, ignored),
                           non_equivalent_ratio_pair).
action_automaton_signature(ratio, construct_referent_ratio_diagram,
                           inputs(two_named_positive_collections, ratio_diagram),
                           ordered_referent_ratio_statement).
action_automaton_signature(ratio, reverse_ratio_referent_order,
                           inputs(two_named_unequal_positive_collections,
                                  ratio_diagram),
                           referent_reversed_ratio_statement).
action_automaton_signature(algebraic, programming_expression_evaluation,
                           inputs(expression_tree, variable_bindings), value).
action_automaton_signature(algebraic,
                           contextual_linear_equation_construction,
                           inputs(linear_context_with_referent_roles,
                                  linear_equation_form),
                           contextual_linear_equation).
action_automaton_signature(algebraic, equation_truth_by_substitution,
                           inputs(equation_expression_pair,
                                  variable_bindings),
                           equation_truth_value).
action_automaton_signature(algebraic, operational_equals_left_value,
                           inputs(equation_expression_pair,
                                  variable_bindings),
                           left_expression_value_as_answer).
action_automaton_signature(algebraic,
                           balance_preserving_linear_solution,
                           inputs(one_unknown_integer_linear_equation,
                                  nonnegative_integer_solution_domain),
                           unknown_value).
action_automaton_signature(algebraic, one_sided_equation_operation,
                           inputs(one_unknown_integer_linear_equation,
                                  nonnegative_integer_solution_domain),
                           unbalanced_candidate_value).
action_automaton_signature(algebraic, symbolic_expression_construction,
                           inputs(quantity_relation_with_referent_roles,
                                  declared_variable_scope),
                           algebraic_expression_tree).
action_automaton_signature(algebraic, distributive_expression_rewrite,
                           inputs(product_of_sum_expression,
                                  expansion_direction),
                           equivalent_sum_of_products).
action_automaton_signature(algebraic, drop_distributed_term,
                           inputs(product_of_sum_expression,
                                  expansion_direction),
                           incomplete_symbolic_expansion).
action_automaton_signature(algebraic, exponent_as_repeated_factor,
                           inputs(nonnegative_whole_number_power,
                                  expanded_product_notation),
                           repeated_factor_expression).
action_automaton_signature(algebraic, exponent_as_multiplier,
                           inputs(nonnegative_whole_number_power,
                                  expanded_product_notation),
                           base_times_exponent_expression).
action_automaton_signature(algebraic,
                           exponential_equivalence_by_expansion,
                           inputs(exponential_expression_pair,
                                  repeated_factor_expansion_method),
                           equivalence_verdict).
action_automaton_signature(algebraic, linear_pattern_contextual_rule,
                           inputs(linear_pattern, context), value).
action_automaton_signature(algebraic, guess_and_check_rule,
                           inputs(linear_pattern, context), guessed_value).
action_automaton_signature(geometry, rectangle_area_unit_iteration,
                           inputs(positive_integer_rows, positive_integer_columns),
                           square_units).
action_automaton_signature(geometry, area_as_perimeter_count,
                           inputs(bounded_positive_integer_rows,
                                  bounded_positive_integer_columns),
                           boundary_units_as_area).
action_automaton_signature(geometry, area_unit_covering,
                           inputs(distinct_nonnegative_grid_cells,
                                  measurement_unit), covered_square_units).
action_automaton_signature(geometry, count_overlapping_area_tiles,
                           inputs(grid_cell_placements_with_duplicates,
                                  measurement_unit), double_counted_square_units).
action_automaton_signature(geometry, area_unit_scale_selection,
                           inputs(classified_area_referent_extent,
                                  candidate_square_units_with_scale_profiles),
                           suitable_square_unit).
action_automaton_signature(geometry, choose_first_area_unit_without_scale,
                           inputs(classified_area_referent_extent,
                                  candidate_square_units_with_scale_profiles),
                           unsuitable_square_unit).
action_automaton_signature(geometry,
                           rectangle_perimeter_boundary_traversal,
                           inputs(rectangle_dimensions, measurement_unit),
                           perimeter_length).
action_automaton_signature(geometry, perimeter_two_sides_only,
                           inputs(rectangle_dimensions, measurement_unit),
                           incomplete_perimeter_length).
action_automaton_signature(geometry, perimeter_uses_area_formula,
                           inputs(rectangle_dimensions, measurement_unit),
                           area_value_as_perimeter_length).
action_automaton_signature(geometry,
                           polygon_perimeter_boundary_accumulation,
                           inputs(ordered_polygon_side_lengths,
                                  measurement_unit),
                           complete_polygon_perimeter_length).
action_automaton_signature(geometry, omit_unlabeled_boundary_side,
                           inputs(ordered_polygon_side_lengths,
                                  measurement_unit),
                           incomplete_polygon_perimeter_length).
action_automaton_signature(geometry,
                           symmetry_constrained_side_reconstruction,
                           inputs(side_equivalence_orbits,
                                  total_polygon_perimeter),
                           unknown_side_length).
action_automaton_signature(geometry, ignore_symmetry_multiplicity,
                           inputs(side_equivalence_orbits,
                                  total_polygon_perimeter),
                           incorrect_unknown_side_length).
action_automaton_signature(geometry, rectangle_perimeter_side_pair_search,
                           inputs(even_positive_perimeter, side_scope),
                           rectangle_side_pairs).
action_automaton_signature(geometry, rectangle_missing_side_from_perimeter,
                           inputs(even_positive_perimeter, known_side_length),
                           missing_side_length).
action_automaton_signature(geometry, rectangle_factor_pair_search,
                           inputs(positive_integer_area, factor_scope),
                           rectangle_factor_pairs).
action_automaton_signature(geometry,
                           rectangle_area_perimeter_constraint_search,
                           inputs(positive_integer_area_and_even_perimeter,
                                  exhaustive_constraint_scope),
                           constrained_rectangle_side_pairs).
action_automaton_signature(geometry,
                           ignore_perimeter_rectangle_constraint,
                           inputs(positive_integer_area_and_even_perimeter,
                                  exhaustive_constraint_scope),
                           area_pairs_without_perimeter_filter).
action_automaton_signature(geometry, rectangle_missing_side_from_area,
                           inputs(positive_integer_area, known_side_length),
                           missing_side_length).
action_automaton_signature(geometry, subtract_side_from_area,
                           inputs(positive_integer_area, known_side_length),
                           additive_remainder_as_side_length).
action_automaton_signature(geometry, rectangular_prism_volume_layer_iteration,
                           inputs(rectangular_base, positive_integer_height),
                           cubic_units).
action_automaton_signature(geometry,
                           rectangular_prism_missing_dimension_from_volume,
                           inputs(positive_integer_volume,
                                  two_known_base_dimensions),
                           missing_prism_dimension).
action_automaton_signature(geometry, divide_volume_by_one_dimension,
                           inputs(positive_integer_volume,
                                  two_known_base_dimensions),
                           partial_quotient_as_prism_dimension).
action_automaton_signature(geometry, composite_prism_volume_sum,
                           inputs(certified_disjoint_rectangular_prisms,
                                  measurement_unit), composite_volume).
action_automaton_signature(geometry, sum_overlapping_prism_volumes,
                           inputs(overlapping_rectangular_prisms_with_overlap,
                                  measurement_unit), double_counted_volume).
action_automaton_signature(geometry, compare_solid_volume_by_cube_count,
                           inputs(two_solid_cube_counts,
                                  two_visible_extent_measures),
                           solid_volume_relation).
action_automaton_signature(geometry, compare_solid_volume_by_visible_extent,
                           inputs(two_solid_cube_counts,
                                  two_visible_extent_measures),
                           visible_extent_relation_as_volume).
action_automaton_signature(geometry, ordered_pair_coordinate_plot,
                           inputs(list_of_ordered_pairs, cartesian_axes),
                           plotted_points).
action_automaton_signature(geometry, axis_aligned_coordinate_distance,
                           inputs(two_axis_aligned_integer_points,
                                  measurement_unit),
                           nonnegative_coordinate_distance).
action_automaton_signature(geometry,
                           directed_difference_as_coordinate_distance,
                           inputs(two_axis_aligned_integer_points,
                                  measurement_unit),
                           signed_change_as_distance).
action_automaton_signature(geometry, area_preserving_polygon_decomposition,
                           inputs(lattice_polygon,
                                  certified_polygon_partition),
                           conserved_polygon_area).
action_automaton_signature(geometry, decomposition_with_gap_or_overlap,
                           inputs(lattice_polygon,
                                  unchecked_polygon_decomposition),
                           nonconserved_piece_area_sum).
action_automaton_signature(geometry, parallelogram_area_base_height,
                           inputs(parallelogram_dimensions,
                                  measurement_unit), parallelogram_area).
action_automaton_signature(geometry,
                           slanted_side_as_parallelogram_height,
                           inputs(parallelogram_dimensions,
                                  measurement_unit), incorrect_parallelogram_area).
action_automaton_signature(geometry, triangle_area_half_base_height,
                           inputs(triangle_base_and_perpendicular_height,
                                  measurement_unit), triangle_area).
action_automaton_signature(geometry, omit_half_in_triangle_area,
                           inputs(triangle_base_and_perpendicular_height,
                                  measurement_unit), parallelogram_area_as_triangle_area).
action_automaton_signature(geometry, polyhedron_surface_area_from_net,
                           inputs(supported_solid_with_all_face_areas,
                                  measurement_unit), surface_area).
action_automaton_signature(geometry, visible_faces_only_surface_area,
                           inputs(supported_solid_with_all_face_areas,
                                  measurement_unit), partial_surface_area).
action_automaton_signature(geometry,
                           dimensional_measure_unit_coordination,
                           inputs(dimension_and_measure, base_measurement_unit),
                           dimensioned_quantity).
action_automaton_signature(geometry, linear_unit_for_area_or_volume,
                           inputs(higher_dimension_and_measure,
                                  base_measurement_unit),
                           higher_dimensional_quantity_with_linear_unit).
action_automaton_signature(geometry,
                           shape_classification_by_defining_attributes,
                           inputs(shape_with_observed_attributes,
                                  quarter_turn_orientation),
                           shape_categories).
action_automaton_signature(geometry, orientation_bound_shape_classification,
                           inputs(shape_with_observed_attributes,
                                  nonzero_quarter_turn_orientation),
                           rejected_shape_name).
action_automaton_signature(geometry, angle_turn_measurement,
                           inputs(whole_number_degrees, degree_unit),
                           angle_measure).
action_automaton_signature(geometry, angle_as_ray_length,
                           inputs(whole_number_degrees, degree_unit),
                           angle_magnitude_misread).
action_automaton_signature(geometry, angle_additive_composition,
                           inputs(list_of_angle_parts, whole_angle_measure),
                           angle_measure).
action_automaton_signature(geometry, rigid_shape_composition,
                           inputs(bounded_lattice_region, placed_rigid_parts),
                           composed_region).
action_automaton_signature(statistics, categorical_frequency_bar_representation,
                           inputs(category_frequency_pairs, bar_chart_display),
                           frequency_representation).
action_automaton_signature(statistics, dot_plot_frequency_representation,
                           inputs(measurement_values, dot_plot_display), dot_plot).
action_automaton_signature(statistics,
                           statistical_question_variability_classification,
                           inputs(question_with_anticipated_variability,
                                  named_population),
                           statistical_question).
action_automaton_signature(statistics, question_without_variability,
                           inputs(question_with_anticipated_variability,
                                  named_population),
                           nonstatistical_question_misclassification).
action_automaton_signature(statistics, histogram_equal_interval_representation,
                           inputs(nonnegative_integer_measurements,
                                  positive_integer_bin_width), histogram).
action_automaton_signature(statistics, mean_as_fair_share,
                           inputs(data_set, measurement_unit), rational_mean).
action_automaton_signature(statistics, mean_as_balance_point,
                           inputs(data_set, measurement_unit),
                           mean_with_balanced_signed_deviations).
action_automaton_signature(statistics, mean_absolute_deviation,
                           inputs(data_set, measurement_unit), rational_mad).
action_automaton_signature(statistics, mean_deviation_without_absolute_value,
                           inputs(data_set, measurement_unit),
                           cancelled_signed_deviation).
action_automaton_signature(statistics, median_as_ordered_middle,
                           inputs(data_set, measurement_unit), median_value).
action_automaton_signature(statistics, mode_as_maximal_frequency,
                           inputs(data_set, measurement_unit), modes).
action_automaton_signature(statistics, five_number_summary_and_iqr,
                           inputs(data_set_with_at_least_two_values,
                                  measurement_unit),
                           five_number_summary_and_iqr).
action_automaton_signature(statistics, box_plot_from_five_number_summary,
                           inputs(data_set_with_at_least_two_values,
                                  box_plot_display), box_plot).
action_automaton_signature(statistics, distribution_summary_selection,
                           inputs(data_set, declared_distribution_profile),
                           center_and_spread_pair).
action_automaton_signature(measurement, linear_unit_iteration,
                           inputs(interval_count_and_subdivision, measurement_unit),
                           measured_length).
action_automaton_signature(measurement, count_marks_not_intervals,
                           inputs(interval_count_and_subdivision, measurement_unit),
                           overcounted_length).
action_automaton_signature(measurement, liquid_volume_scale_reading,
                           inputs(volume_interval_count_and_subdivision,
                                  liquid_volume_unit), liquid_volume).
action_automaton_signature(measurement,
                           liquid_volume_count_marks_not_intervals,
                           inputs(volume_interval_count_and_subdivision,
                                  liquid_volume_unit), overcounted_liquid_volume).
action_automaton_signature(measurement, unit_conversion_by_iteration,
                           inputs(quantity_in_larger_unit,
                                  smaller_unit_and_integer_conversion_factor),
                           equivalent_quantity_in_smaller_unit).
action_automaton_signature(measurement, change_unit_label_without_scaling,
                           inputs(quantity_in_larger_unit,
                                  smaller_unit_and_integer_conversion_factor),
                           unchanged_numeral_with_smaller_unit_label).
action_automaton_signature(
    measurement, unit_preserving_measured_quantity_change,
    inputs(measured_addition_or_subtraction, ignored),
    unit_bearing_quantity).
action_automaton_signature(
    measurement, drop_unit_from_measured_quantity_change,
    inputs(measured_addition_or_subtraction, ignored), bare_numeral).
action_automaton_signature(counting, enumerate_collection_one_to_one,
                           inputs(collection_size_up_to_ten, inscription_base),
                           cardinality_with_numeral).
action_automaton_signature(counting, inscribe_cardinality,
                           inputs(cardinality_up_to_ten, inscription_base),
                           positional_numeral).
action_automaton_signature(counting, recursive_place_value_inscription,
                           inputs(nonnegative_cardinality, inscription_base),
                           positional_numeral_with_recursive_unit_tree).
action_automaton_signature(counting, omit_highest_place_regrouping,
                           inputs(cardinality_at_least_one_base_cycle,
                                  inscription_base),
                           deformed_cardinality_without_high_place_regrouping).
action_automaton_signature(counting, place_value_comparison,
                           inputs(two_nonnegative_cardinalities,
                                  common_inscription_base),
                           cardinality_relation_by_highest_differing_place).
action_automaton_signature(counting, compare_ones_digits_only,
                           inputs(two_nonnegative_cardinalities,
                                  common_inscription_base),
                           incorrect_relation_from_ones_digits).
action_automaton_signature(counting, compare_cardinalities_one_to_one,
                           inputs(two_collection_counts, two_spatial_extents),
                           cardinality_relation).
action_automaton_signature(counting, spatial_extent_as_cardinality,
                           inputs(two_collection_counts, two_spatial_extents),
                           incorrect_extent_relation).


%!  action_automaton_pair(+Operation, +ProductiveKind, +DeformationKind, -Family) is semidet.
action_automaton_pair(addition, ProductiveKind, DeformationKind, Family) :-
    productive_deformation(ProductiveKind, DeformationKind, Family).
action_automaton_pair(subtraction, ProductiveKind, DeformationKind, Family) :-
    productive_subtractive_deformation(ProductiveKind, DeformationKind, Family).
action_automaton_pair(multiplication, ProductiveKind, DeformationKind, Family) :-
    productive_multiplicative_deformation(ProductiveKind, DeformationKind, Family).
action_automaton_pair(division, ProductiveKind, DeformationKind, Family) :-
    productive_division_deformation(ProductiveKind, DeformationKind, Family).
action_automaton_pair(fraction, ProductiveKind, DeformationKind, Family) :-
    productive_fraction_deformation(ProductiveKind, DeformationKind, Family).
action_automaton_pair(decimal, ProductiveKind, DeformationKind, Family) :-
    productive_decimal_deformation(ProductiveKind, DeformationKind, Family).
action_automaton_pair(integer, ProductiveKind, DeformationKind, Family) :-
    productive_integer_deformation(ProductiveKind, DeformationKind, Family).
action_automaton_pair(ratio, ProductiveKind, DeformationKind, Family) :-
    productive_ratio_deformation(ProductiveKind, DeformationKind, Family).
action_automaton_pair(diagnostic, ProductiveKind, DeformationKind, Family) :-
    productive_diagnostic_deformation(ProductiveKind, DeformationKind, Family).
action_automaton_pair(calculus, ProductiveKind, DeformationKind, Family) :-
    productive_calculus_deformation(ProductiveKind, DeformationKind, Family).
action_automaton_pair(algebraic, ProductiveKind, DeformationKind, Family) :-
    productive_algebraic_deformation(ProductiveKind, DeformationKind, Family).
action_automaton_pair(probability, ProductiveKind, DeformationKind, Family) :-
    productive_probability_deformation(ProductiveKind, DeformationKind, Family).
action_automaton_pair(geometry, ProductiveKind, DeformationKind, Family) :-
    productive_geometry_deformation(ProductiveKind, DeformationKind, Family).
action_automaton_pair(statistics, ProductiveKind, DeformationKind, Family) :-
    productive_statistics_deformation(ProductiveKind, DeformationKind, Family).
action_automaton_pair(measurement, ProductiveKind, DeformationKind, Family) :-
    productive_measurement_deformation(ProductiveKind, DeformationKind, Family).
action_automaton_pair(counting, ProductiveKind, DeformationKind, Family) :-
    productive_counting_deformation(ProductiveKind, DeformationKind, Family).


%!  action_automaton_hook(+Operation, +Outcome, -Family, -Hook) is semidet.
action_automaton_hook(addition, Outcome, Family, Hook) :-
    action_misconception_hook(Outcome, Family, Hook).
action_automaton_hook(subtraction, Outcome, Family, Hook) :-
    subtractive_action_misconception_hook(Outcome, Family, Hook).
action_automaton_hook(multiplication, Outcome, Family, Hook) :-
    multiplicative_action_misconception_hook(Outcome, Family, Hook).
action_automaton_hook(division, Outcome, Family, Hook) :-
    division_action_misconception_hook(Outcome, Family, Hook).
action_automaton_hook(fraction, Outcome, Family, Hook) :-
    fraction_action_misconception_hook(Outcome, Family, Hook).
action_automaton_hook(decimal, Outcome, Family, Hook) :-
    decimal_action_misconception_hook(Outcome, Family, Hook).
action_automaton_hook(integer, Outcome, Family, Hook) :-
    integer_action_misconception_hook(Outcome, Family, Hook).
action_automaton_hook(ratio, Outcome, Family, Hook) :-
    ratio_action_misconception_hook(Outcome, Family, Hook).
action_automaton_hook(diagnostic, Outcome, Family, Hook) :-
    diagnostic_action_misconception_hook(Outcome, Family, Hook).
action_automaton_hook(calculus, Outcome, Family, Hook) :-
    calculus_action_misconception_hook(Outcome, Family, Hook).
action_automaton_hook(algebraic, Outcome, Family, Hook) :-
    algebraic_action_misconception_hook(Outcome, Family, Hook).
action_automaton_hook(probability, Outcome, Family, Hook) :-
    probability_action_misconception_hook(Outcome, Family, Hook).
action_automaton_hook(geometry, Outcome, Family, Hook) :-
    geometry_action_misconception_hook(Outcome, Family, Hook).
action_automaton_hook(statistics, Outcome, Family, Hook) :-
    statistics_action_misconception_hook(Outcome, Family, Hook).
action_automaton_hook(measurement, Outcome, Family, Hook) :-
    measurement_action_misconception_hook(Outcome, Family, Hook).
action_automaton_hook(counting, Outcome, Family, Hook) :-
    counting_action_misconception_hook(Outcome, Family, Hook).
