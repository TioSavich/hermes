:- encoding(utf8).
/** <module> Authored metaphor-operation and seam rows
 *
 * This registry records authored, reviewable rows about which grounding
 * metaphor operates in an action machine and where that metaphor's reach ends
 * inside the represented content. It does not claim that metaphors cause
 * learning, and it makes no genesis claim beyond the literature cited in each
 * row. Metaphor atoms come from
 * formal/formalization/grounding_metaphors*.pl and cited literature.
 *
 * Seam kinds are local descriptive terms. The fourth argument of
 * metaphor_seam/5 must use one of these four forms:
 *
 *   - `seam_kind(vanishing_point)`: the retiring metaphor has no source-domain referent
 *     for the named target content.
 *   - `seam_kind(repair_point)`: the target inference remains arithmetically valid, the
 *     retiring metaphor is recorded as breaking there, and a cited succeeding
 *     metaphor supplies the grounding used by this formalism.
 *   - `stops_before/1`: the operating metaphor supports the reach named in
 *     the third argument but does not supply the named next inference.
 *   - `stops_at/1`: the operating metaphor reaches the named boundary but
 *     does not license crossing it.
 *
 * Every row states its evidence as data so a reader can reject one row without
 * accepting or rejecting the registry as a whole.
 */

:- module(metaphor_seam_registry,
          [ metaphor_operating/3,
            metaphor_seam/5
          ]).

:- discontiguous metaphor_operating/3.
:- discontiguous metaphor_seam/5.


metaphor_operating(
    integer/signed_subtraction_as_additive_inverse,
    arithmetic_is_motion_along_a_path,
    evidence(
        source('formal/formalization/grounding_metaphors.pl'),
        mapping(moving_toward_origin, subtraction),
        curriculum('Illustrative Mathematics Grade 7 Unit 5 Lesson 5',
                   addend_arrows_then_additive_inverse_generalization),
        citation('Lakoff and Nunez 2000, Where Mathematics Comes From, ch. 3'))).

metaphor_operating(
    integer/swap_subtraction_operands_to_preserve_nonnegative_result,
    arithmetic_is_measuring_stick,
    evidence(
        source('formal/formalization/grounding_metaphors.pl'),
        mapping(taking_shorter_segment_from_longer, subtraction),
        break(negative_numbers),
        curriculum('Illustrative Mathematics Grade 7 Unit 5 Lesson 6',
                   smaller_from_larger_prior_understanding),
        citation('Lakoff and Nunez 2000, Where Mathematics Comes From, ch. 3'))).

metaphor_operating(
    integer/conflate_signed_difference_with_distance,
    arithmetic_is_measuring_stick,
    evidence(
        source('formal/formalization/grounding_metaphors.pl'),
        mapping(physical_segments, numbers),
        curriculum('Illustrative Mathematics Grade 7 Unit 5 Lesson 7',
                   difference_can_be_signed_distance_cannot),
        citation('Lakoff and Nunez 2000, Where Mathematics Comes From, ch. 3'))).

metaphor_operating(
    integer/signed_multiplication_by_sign_rule,
    multiplication_by_minus_one_is_rotation_by_180_degrees,
    evidence(
        source('formal/formalization/grounding_metaphors.pl'),
        mapping(composition_of_two_180_degree_rotations,
                multiplication_of_two_negatives_yielding_positive),
        curriculum('Illustrative Mathematics Grade 7 Unit 5 Lessons 8-10',
                   pattern_continuation_across_zero),
        citation('Lakoff and Nunez 2000, Where Mathematics Comes From, ch. 3'))).

metaphor_operating(
    integer/reverse_signed_multiplication_sign_rule,
    multiplication_by_minus_one_is_rotation_by_180_degrees,
    evidence(
        source('formal/formalization/grounding_metaphors.pl'),
        deforms(composition_of_two_180_degree_rotations_to_identity,
                reversed_sign_relation),
        curriculum('Illustrative Mathematics Grade 7 Unit 5 Lesson 10, Making Mistakes',
                   reversed_sign_examples),
        citation('Lakoff and Nunez 2000, Where Mathematics Comes From, ch. 3'))).

metaphor_operating(
    integer/signed_division_by_sign_rule,
    multiplication_by_minus_one_is_rotation_by_180_degrees,
    evidence(
        source('formal/formalization/grounding_metaphors.pl'),
        inherited_through(unknown_factor_multiplication_equation),
        curriculum('Illustrative Mathematics Grade 7 Unit 5 Lesson 11',
                   quotient_sign_pattern_matches_product_sign_pattern),
        citation('Lakoff and Nunez 2000, Where Mathematics Comes From, ch. 3'))).

metaphor_operating(
    integer/reverse_signed_division_sign_rule,
    multiplication_by_minus_one_is_rotation_by_180_degrees,
    evidence(
        source('formal/formalization/grounding_metaphors.pl'),
        deforms(unknown_factor_inheritance, reversed_sign_relation),
        curriculum('Illustrative Mathematics Grade 7 Unit 5 Lessons 10-11',
                   multiplication_error_transferred_across_explicit_sign_pattern_equivalence),
        citation('Lakoff and Nunez 2000, Where Mathematics Comes From, ch. 3'))).


metaphor_seam(
    integer/signed_quantity,
    arithmetic_is_measuring_stick,
    arithmetic_is_motion_along_a_path,
    seam_kind(vanishing_point),
    basis(
        break(negative_numbers),
        reason('A physical length cannot be shorter than no segment, while a path can carry point-locations on either side of zero.'),
        source('formal/formalization/grounding_metaphors.pl'),
        citation('Lakoff and Nunez 2000, Where Mathematics Comes From, ch. 3'))).

metaphor_seam(
    integer/product_of_two_negatives,
    arithmetic_is_motion_along_a_path,
    multiplication_by_minus_one_is_rotation_by_180_degrees,
    seam_kind(repair_point),
    basis(
        break(product_of_two_negatives),
        reason('Iterated motion has no negative repetition, while two half-turns compose to the identity orientation.'),
        source('formal/formalization/grounding_metaphors.pl'),
        citation('Lakoff and Nunez 2000, Where Mathematics Comes From, ch. 3'))).

% RATIO lane rows.
metaphor_operating(ratio/scale_ratio_unit,
                   arithmetic_is_measuring_stick,
                   evidence('grounding_metaphors.pl already maps arithmetic_is_measuring_stick to p_scale_ratio_unit')).
metaphor_seam(ratio/scale_ratio_unit,
              arithmetic_is_measuring_stick,
              supports(multiplicative_scaling_of_length_pair),
              stops_before(figure_area_requires_factor_squared),
              evidence('Grade 7 schema class 1 keeps figure and area scaling outside the ratio-pair machine')).

metaphor_operating(ratio/additive_extension_of_ratio,
                   arithmetic_is_motion_along_a_path,
                   evidence('The deformation transports one absolute increment across both ratio terms')).
metaphor_seam(ratio/additive_extension_of_ratio,
              arithmetic_is_motion_along_a_path,
              supports(equal_additive_displacements),
              stops_before(multiplicative_ratio_invariance),
              evidence('Noelting 1980; research corpus row 39354')).

metaphor_operating(ratio/compute_unit_rate_from_ratio_pair,
                   arithmetic_is_measuring_stick,
                   evidence('The machine measures one quantity in units of the ordered reference quantity')).
metaphor_seam(ratio/compute_unit_rate_from_ratio_pair,
              arithmetic_is_measuring_stick,
              supports(normalization_to_one_reference_quantity),
              stops_before(rate_direction_without_quantity_roles),
              evidence('Christou and Philippou 2002; research corpus row 38316')).

metaphor_operating(ratio/divide_larger_by_smaller_for_unit_rate,
                   arithmetic_is_measuring_stick,
                   evidence('The quotient operation remains measurement-shaped even when magnitude order replaces quantity roles')).
metaphor_seam(ratio/divide_larger_by_smaller_for_unit_rate,
              arithmetic_is_measuring_stick,
              supports(forming_a_quotient),
              stops_before(determining_which_quantity_is_per_one),
              evidence('Christou and Philippou 2002; research corpus row 38316')).

metaphor_operating(ratio/test_relation_for_proportionality,
                   arithmetic_is_measuring_stick,
                   evidence('The kernel compares each pair through a common quotient')).
metaphor_seam(ratio/test_relation_for_proportionality,
              arithmetic_is_measuring_stick,
              supports(pairwise_measurement_by_a_common_rate),
              stops_before(relation_license_without_quantifying_over_pairs),
              evidence('Arican 2018; research corpus row 40430')).

metaphor_operating(ratio/inscribe_proportional_equation,
                   fundamental_metonymy_of_algebra,
                   evidence('grounding_metaphors_extended.pl names the role-individual metonymy used by x and y')).
metaphor_seam(ratio/inscribe_proportional_equation,
              fundamental_metonymy_of_algebra,
              supports(variable_roles_and_substitution_in_y_equals_kx),
              stops_before(covariational_practice),
              evidence('The machine binds one known pair and one target; it does not model coordinated variation')).

% GEOSTAT lane rows.
% Metaphor ids are drawn only from grounding_metaphors.pl and
% grounding_metaphors_extended.pl.


metaphor_operating(
    geometry/circle_circumference_diameter_co_measurement,
    arithmetic_is_measuring_stick,
    evidence([source(formal_formalization_grounding_metaphors),
              curriculum('IM-G7-U3-L3'),
              doing(coordinate_two_linear_measures_through_pi)])).
metaphor_seam(
    geometry/circle_circumference_diameter_co_measurement,
    arithmetic_is_measuring_stick,
    reaches(coordinating_diameter_and_circumference),
    stops_before(establishing_exact_or_irrational_pi),
    evidence(curriculum_names_pi_as_a_little_more_than_three)).

metaphor_operating(
    geometry/use_diameter_as_radius_in_circumference,
    arithmetic_is_measuring_stick,
    evidence([source(formal_formalization_grounding_metaphors),
              curriculum('IM-G7-U3-L10'),
              doing(misassign_measure_role_before_scaling)])).
metaphor_seam(
    geometry/use_diameter_as_radius_in_circumference,
    arithmetic_is_measuring_stick,
    reaches(comparing_circle_linear_measures),
    stops_at(diameter_radius_role_distinction),
    evidence(the_stick_scale_does_not_select_the_measure_role)).

metaphor_operating(
    geometry/triangle_three_measure_determination,
    arithmetic_is_object_construction,
    evidence([source(formal_formalization_grounding_metaphors),
              curriculum('IM-G7-U7-L6-to-L10'),
              doing(fit_sides_and_angles_into_a_closed_triangle)])).
metaphor_seam(
    geometry/triangle_three_measure_determination,
    arithmetic_is_object_construction,
    reaches(testing_whether_parts_close),
    stops_before(proving_congruence_and_similarity_criteria),
    evidence(curriculum_uses_construction_without_requiring_rule_names)).

metaphor_operating(
    geometry/angle_relation_unknown_measure,
    arithmetic_is_motion_along_a_path,
    evidence([source(formal_formalization_grounding_metaphors),
              curriculum('IM-G7-U7-L4'),
              doing(compose_turns_at_a_shared_vertex)])).
metaphor_seam(
    geometry/angle_relation_unknown_measure,
    arithmetic_is_motion_along_a_path,
    reaches(composing_angle_turns),
    stops_at(ray_length_as_angle_measure),
    evidence(existing_pair(geometry/angle_as_ray_length))).

metaphor_operating(
    statistics/estimate_probability_from_observed_frequency,
    basic_metaphor_of_infinity,
    evidence([source(formal_formalization_grounding_metaphors_extended),
              citation(lakoff_nunez_chapter_8),
              curriculum('IM-G7-U8-L4'),
              doing(read_finite_repetition_toward_a_long_run_value)])).
metaphor_seam(
    statistics/estimate_probability_from_observed_frequency,
    basic_metaphor_of_infinity,
    reaches(organizing_repetition_as_a_long_run_process),
    stops_before(turning_a_finite_record_into_the_limit),
    evidence(curriculum_calls_the_result_an_estimate)).

metaphor_operating(
    statistics/finite_frequency_as_exact_probability,
    basic_metaphor_of_infinity,
    evidence([source(formal_formalization_grounding_metaphors_extended),
              citation(lakoff_nunez_chapter_8),
              curriculum('IM-G7-U8-L4'),
              doing(promote_finite_process_to_final_resultant_state)])).
metaphor_seam(
    statistics/finite_frequency_as_exact_probability,
    basic_metaphor_of_infinity,
    reaches(organizing_repeated_trials),
    stops_at(finite_frequency_claimed_as_exact_probability),
    evidence(curriculum_denies_exact_match_guarantee)).

metaphor_operating(
    statistics/sample_population_distribution_judgment,
    arithmetic_is_object_collection,
    evidence([source(formal_formalization_grounding_metaphors),
              curriculum('IM-G7-U8-L13'),
              doing(compare_counted_sample_and_population_distributions)])).
metaphor_seam(
    statistics/sample_population_distribution_judgment,
    arithmetic_is_object_collection,
    reaches(collecting_and_summarizing_observations),
    stops_before(inheriting_population_distribution_from_any_subset),
    evidence(curriculum_requires_shape_center_and_spread_comparison)).

% ALGEBRAIC lane rows.
metaphor_operating(algebraic/translate_diagram_to_equation,
                   arithmetic_is_object_construction,
                   evidence(tape_parts_are_composed_as_one_total,
                            citation('Lakoff and Nunez 2000, basic metaphor of arithmetic as object construction; IM Grade 7 Unit 6 Lessons 2-3'))).
metaphor_operating(algebraic/translate_diagram_to_equation,
                   balance_preservation_schema,
                   evidence(hanger_sides_name_equal_quantities,
                            citation('formal/formalization/grounding_metaphors.pl:145-148; IM Grade 7 Unit 6 Lesson 7'))).
metaphor_operating(algebraic/split_repeated_diagram_variable,
                   fundamental_metonymy_of_algebra,
                   evidence(variable_label_stands_for_one_quantity_role,
                            citation('Lakoff and Nunez 2000, chapter 3; formal/formalization/grounding_metaphors_extended.pl'))).
metaphor_operating(algebraic/percent_change_composition,
                   arithmetic_is_object_construction,
                   evidence(percent_is_a_part_relative_to_a_named_whole,
                            citation('Lakoff and Nunez 2000, arithmetic as object construction; IM Grade 7 Unit 4'))).
metaphor_operating(algebraic/combine_signed_like_terms,
                   fundamental_metonymy_of_algebra,
                   evidence(shared_variable_names_a_shared_number_role,
                            citation('Lakoff and Nunez 2000, chapter 3; IM Grade 7 Unit 6 Lessons 20-21'))).
metaphor_operating(algebraic/combine_unlike_terms,
                   fundamental_metonymy_of_algebra,
                   evidence(deformation_crosses_the_variable_role_boundary,
                            citation('Lakoff and Nunez 2000, chapter 3; IM Grade 7 Unit 6 Lesson 20'))).

metaphor_seam(algebraic/translate_diagram_to_equation,
              arithmetic_is_object_construction,
              balance_preservation_schema,
              seam_kind(vanishing_point),
              basis([object_construction_coordinates_tape_parts_and_whole,
                     hanger_equality_requires_a_symmetric_relation_not_supplied_by_part_assembly,
                     citation('formal/formalization/grounding_metaphors.pl:145-148')])).

% No further seam is claimed inside percent multiplier composition or the
% same-variable scope of the signed like-term machines.
