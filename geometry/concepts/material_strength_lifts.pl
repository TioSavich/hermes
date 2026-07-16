% concepts/material_strength_lifts.pl
%
% Lift selected flat material_inference/4 records into incompatibility-style
% strength profiles. A stronger term rejects a superset of the weaker term's
% "hard no" restrictions. This makes selected KB commitments queryable as an
% order relation rather than only representational prose.

:- multifile material_inference/4.
:- discontiguous material_inference/4.
:- discontiguous strength_rejects/3.
:- discontiguous strength_restriction/3.

% ── Domain declarations ─────────────────────────────────────────────

strength_term(quadrilateral_class, Term) :-
    quad_shape(Term).

strength_term(classification_stance, exclusive_definition).
strength_term(classification_stance, inclusive_definition).
strength_term(classification_stance, square_recognition).
strength_term(classification_stance, square_rectangle_classification).

strength_term(measurement_dimension, length_quantity).
strength_term(measurement_dimension, area_quantity).
strength_term(measurement_dimension, volume_quantity).

strength_term(coordinate_slope_reasoning, height_only_slope_reading).
strength_term(coordinate_slope_reasoning, slope_ratio_reasoning).
strength_term(coordinate_slope_reasoning, local_position_slope_reading).
strength_term(coordinate_slope_reasoning, line_slope_invariance).
strength_term(coordinate_slope_reasoning, parallel_slope_relation).
strength_term(coordinate_slope_reasoning, perpendicular_slope_relation).

strength_term(pythagorean_reasoning, formula_pattern_reading).
strength_term(pythagorean_reasoning, right_triangle_side_relation).
strength_term(pythagorean_reasoning, hypotenuse_application).
strength_term(pythagorean_reasoning, constructed_right_triangle_reasoning).
strength_term(pythagorean_reasoning, converse_right_triangle_test).
strength_term(pythagorean_reasoning, special_45_45_90_ratio).
strength_term(pythagorean_reasoning, special_30_60_90_ratio).

strength_term(transformation_reasoning, point_mapping_reading).
strength_term(transformation_reasoning, translation_vector_mapping).
strength_term(transformation_reasoning, whole_plane_translation).
strength_term(transformation_reasoning, reflection_correspondence).
strength_term(transformation_reasoning, reflection_distance_correspondence).
strength_term(transformation_reasoning, plane_reflection_distinction).
strength_term(transformation_reasoning, congruent_halves_reading).
strength_term(transformation_reasoning, line_symmetry_reflection_test).
strength_term(transformation_reasoning, point_image_segment_pairing).
strength_term(transformation_reasoning, rotation_center_diagnostic).
strength_term(transformation_reasoning, glide_reflection_line_diagnostic).
strength_term(transformation_reasoning, reflection_composition_reading).
strength_term(transformation_reasoning, parallel_reflections_translation).
strength_term(transformation_reasoning, intersecting_reflections_rotation).

strength_term(angle_reasoning, one_ray_angle_reading).
strength_term(angle_reasoning, ray_pair_angle_structure).
strength_term(angle_reasoning, arm_length_angle_measure_invariance).
strength_term(angle_reasoning, parallel_transversal_angle_relation).
strength_term(angle_reasoning, inductive_triangle_sum_conjecture).
strength_term(angle_reasoning, triangle_angle_sum_theorem).
strength_term(angle_reasoning, polygon_angle_sum_triangulation).

strength_term(similarity_reasoning, visual_shape_similarity_reading).
strength_term(similarity_reasoning, side_change_similarity_reading).
strength_term(similarity_reasoning, mathematical_similarity_criterion).
strength_term(similarity_reasoning, triangle_similarity_angle_preservation).

strength_term(definition_reasoning, visual_category_reading).
strength_term(definition_reasoning, physical_drawing_reading).
strength_term(definition_reasoning, empirical_generalization_reading).
strength_term(definition_reasoning, definition_candidate_reading).
strength_term(definition_reasoning, property_based_classification).
strength_term(definition_reasoning, formal_object_definition).
strength_term(definition_reasoning, triangle_definition_closure).
strength_term(definition_reasoning, necessary_sufficient_definition).
strength_term(definition_reasoning, equivalent_definition_extension).

strength_term(measurement_formula_reasoning, area_counting_reading).
strength_term(measurement_formula_reasoning, rectangle_boundary_reading).
strength_term(measurement_formula_reasoning, polyhedron_counting_reading).
strength_term(measurement_formula_reasoning, area_interior_coverage_formula).
strength_term(measurement_formula_reasoning, rectangle_perimeter_formula).
strength_term(measurement_formula_reasoning, area_array_formula).
strength_term(measurement_formula_reasoning, area_perimeter_independence_reasoning).
strength_term(measurement_formula_reasoning, area_conservation_invariant).
strength_term(measurement_formula_reasoning, pick_lattice_area_formula).
strength_term(measurement_formula_reasoning, prism_stack_volume_formula).
strength_term(measurement_formula_reasoning, pyramid_volume_formula).
strength_term(measurement_formula_reasoning, euler_polyhedron_invariant).

strength_term(attribute_spatial_reasoning, side_only_polygon_reading).
strength_term(attribute_spatial_reasoning, regular_polygon_angle_reasoning).
strength_term(attribute_spatial_reasoning, length_equality_parallel_reading).
strength_term(attribute_spatial_reasoning, parallel_relation_reasoning).
strength_term(attribute_spatial_reasoning, visual_perpendicular_reading).
strength_term(attribute_spatial_reasoning, perpendicular_right_angle_relation).
strength_term(attribute_spatial_reasoning, oblique_axis_drawing_reading).
strength_term(attribute_spatial_reasoning, orthogonal_3d_axis_reasoning).
strength_term(attribute_spatial_reasoning, bottom_face_base_reading).
strength_term(attribute_spatial_reasoning, structural_base_reasoning).
strength_term(attribute_spatial_reasoning, polygon_shape_reading).
strength_term(attribute_spatial_reasoning, convexity_reflex_angle_test).
strength_term(attribute_spatial_reasoning, convexity_line_segment_test).

% ── Hard-no restrictions ────────────────────────────────────────────

strength_rejects(quadrilateral_class, Term, Restriction) :-
    quad_rejects(Term, Restriction).

strength_restriction(classification_stance, disjoint_class_buckets,
    "A more specific shape name cancels the more general class names.").
strength_restriction(classification_stance, orientation_bound_identity,
    "A shape's class changes when the same figure is rotated.").
strength_restriction(classification_stance, single_shape_identity_only,
    "A shape can belong to exactly one named shape class.").
strength_restriction(classification_stance, no_class_inclusion,
    "Shape classes cannot include proper subclasses.").
strength_restriction(classification_stance, prototype_exclusion,
    "Non-prototypical appearances are excluded from the class.").

strength_rejects(classification_stance, inclusive_definition, disjoint_class_buckets).
strength_rejects(classification_stance, inclusive_definition, single_shape_identity_only).
strength_rejects(classification_stance, inclusive_definition, no_class_inclusion).
strength_rejects(classification_stance, inclusive_definition, prototype_exclusion).

strength_rejects(classification_stance, square_rectangle_classification, orientation_bound_identity).
strength_rejects(classification_stance, square_rectangle_classification, single_shape_identity_only).
strength_rejects(classification_stance, square_rectangle_classification, no_class_inclusion).
strength_rejects(classification_stance, square_rectangle_classification, prototype_exclusion).

strength_restriction(measurement_dimension, count_without_dimension,
    "A bare count is treated as a measurement without dimensional units.").
strength_restriction(measurement_dimension, linear_units_for_area,
    "A two-dimensional quantity is reported in linear units.").
strength_restriction(measurement_dimension, boundary_count_as_area,
    "Area is measured by counting only boundary units.").
strength_restriction(measurement_dimension, linear_scaling_for_area,
    "Area is assumed to scale linearly with side length.").
strength_restriction(measurement_dimension, square_units_for_volume,
    "A three-dimensional quantity is reported in square units.").
strength_restriction(measurement_dimension, surface_measure_as_volume,
    "Volume is treated as surface coverage rather than filling.").
strength_restriction(measurement_dimension, quadratic_scaling_for_volume,
    "Volume is assumed to scale quadratically rather than cubically.").

strength_rejects(measurement_dimension, length_quantity, count_without_dimension).

strength_rejects(measurement_dimension, area_quantity, count_without_dimension).
strength_rejects(measurement_dimension, area_quantity, linear_units_for_area).
strength_rejects(measurement_dimension, area_quantity, boundary_count_as_area).
strength_rejects(measurement_dimension, area_quantity, linear_scaling_for_area).

strength_rejects(measurement_dimension, volume_quantity, count_without_dimension).
strength_rejects(measurement_dimension, volume_quantity, linear_units_for_area).
strength_rejects(measurement_dimension, volume_quantity, boundary_count_as_area).
strength_rejects(measurement_dimension, volume_quantity, linear_scaling_for_area).
strength_rejects(measurement_dimension, volume_quantity, square_units_for_volume).
strength_rejects(measurement_dimension, volume_quantity, surface_measure_as_volume).
strength_rejects(measurement_dimension, volume_quantity, quadratic_scaling_for_volume).

strength_restriction(coordinate_slope_reasoning, rise_only_slope,
    "Slope is determined by vertical change alone.").
strength_restriction(coordinate_slope_reasoning, angle_only_slope,
    "Slope is treated as the visual slant or angle without horizontal run.").
strength_restriction(coordinate_slope_reasoning, run_irrelevant_slope,
    "Horizontal change is ignored when comparing slopes.").
strength_restriction(coordinate_slope_reasoning, point_position_changes_slope,
    "A higher point on the same straight line has a different slope.").
strength_restriction(coordinate_slope_reasoning, local_steepness_varies_on_straight_line,
    "A straight line has locally steeper and less steep sections.").
strength_restriction(coordinate_slope_reasoning, same_slope_lines_intersect,
    "Distinct non-vertical lines with the same slope can intersect.").
strength_restriction(coordinate_slope_reasoning, intercept_difference_needed_for_parallelism,
    "Equal slope is not enough for parallelism unless a separate intercept condition is checked.").
strength_restriction(coordinate_slope_reasoning, perpendicular_slopes_equal,
    "Perpendicular non-vertical lines have equal slopes.").
strength_restriction(coordinate_slope_reasoning, negative_reciprocal_not_needed,
    "Perpendicular slope reasoning does not require the negative reciprocal relation.").
strength_restriction(coordinate_slope_reasoning, sign_ignored_for_perpendicular_slopes,
    "The opposite signs of negative reciprocal slopes are ignored.").

strength_rejects(coordinate_slope_reasoning, slope_ratio_reasoning, rise_only_slope).
strength_rejects(coordinate_slope_reasoning, slope_ratio_reasoning, angle_only_slope).
strength_rejects(coordinate_slope_reasoning, slope_ratio_reasoning, run_irrelevant_slope).

strength_rejects(coordinate_slope_reasoning, local_position_slope_reading, rise_only_slope).
strength_rejects(coordinate_slope_reasoning, local_position_slope_reading, angle_only_slope).
strength_rejects(coordinate_slope_reasoning, local_position_slope_reading, run_irrelevant_slope).

strength_rejects(coordinate_slope_reasoning, line_slope_invariance, rise_only_slope).
strength_rejects(coordinate_slope_reasoning, line_slope_invariance, angle_only_slope).
strength_rejects(coordinate_slope_reasoning, line_slope_invariance, run_irrelevant_slope).
strength_rejects(coordinate_slope_reasoning, line_slope_invariance, point_position_changes_slope).
strength_rejects(coordinate_slope_reasoning, line_slope_invariance, local_steepness_varies_on_straight_line).

strength_rejects(coordinate_slope_reasoning, parallel_slope_relation, rise_only_slope).
strength_rejects(coordinate_slope_reasoning, parallel_slope_relation, angle_only_slope).
strength_rejects(coordinate_slope_reasoning, parallel_slope_relation, run_irrelevant_slope).
strength_rejects(coordinate_slope_reasoning, parallel_slope_relation, point_position_changes_slope).
strength_rejects(coordinate_slope_reasoning, parallel_slope_relation, local_steepness_varies_on_straight_line).
strength_rejects(coordinate_slope_reasoning, parallel_slope_relation, same_slope_lines_intersect).
strength_rejects(coordinate_slope_reasoning, parallel_slope_relation, intercept_difference_needed_for_parallelism).

strength_rejects(coordinate_slope_reasoning, perpendicular_slope_relation, rise_only_slope).
strength_rejects(coordinate_slope_reasoning, perpendicular_slope_relation, angle_only_slope).
strength_rejects(coordinate_slope_reasoning, perpendicular_slope_relation, run_irrelevant_slope).
strength_rejects(coordinate_slope_reasoning, perpendicular_slope_relation, point_position_changes_slope).
strength_rejects(coordinate_slope_reasoning, perpendicular_slope_relation, local_steepness_varies_on_straight_line).
strength_rejects(coordinate_slope_reasoning, perpendicular_slope_relation, perpendicular_slopes_equal).
strength_rejects(coordinate_slope_reasoning, perpendicular_slope_relation, negative_reciprocal_not_needed).
strength_rejects(coordinate_slope_reasoning, perpendicular_slope_relation, sign_ignored_for_perpendicular_slopes).

strength_restriction(pythagorean_reasoning, theorem_as_arbitrary_formula,
    "a^2 + b^2 = c^2 is used as a pattern without a right-triangle condition.").
strength_restriction(pythagorean_reasoning, non_side_quantity_from_pythagoras,
    "The Pythagorean theorem is used to compute area, perimeter, or volume directly.").
strength_restriction(pythagorean_reasoning, hypotenuse_not_identified,
    "The side opposite the right angle is not identified before using c.").
strength_restriction(pythagorean_reasoning, any_side_used_as_c,
    "Any side of the triangle is allowed to serve as c.").
strength_restriction(pythagorean_reasoning, longest_side_not_hypotenuse,
    "The longest side of a right triangle is not treated as the hypotenuse.").
strength_restriction(pythagorean_reasoning, visible_right_angle_required,
    "Pythagorean reasoning is rejected unless a right angle is explicitly drawn.").
strength_restriction(pythagorean_reasoning, auxiliary_right_triangle_disallowed,
    "A useful right triangle may not be constructed inside a larger figure.").
strength_restriction(pythagorean_reasoning, converse_denied,
    "The Pythagorean relationship is treated as theorem-only, not a converse test.").
strength_restriction(pythagorean_reasoning, equation_not_sufficient_for_rightness,
    "Satisfying a^2 + b^2 = c^2 is not accepted as sufficient for a right triangle.").
strength_restriction(pythagorean_reasoning, inequality_still_right_triangle,
    "A triangle with a^2 + b^2 != c^2 may still be classified as right.").
strength_restriction(pythagorean_reasoning, special_angle_ignored,
    "The special angle structure of a right triangle is ignored.").
strength_restriction(pythagorean_reasoning, arbitrary_right_triangle_ratios,
    "All right triangles are assumed to have the same side ratios.").
strength_restriction(pythagorean_reasoning, equal_legs_not_used,
    "The equal legs in a 45-45-90 triangle are not used.").
strength_restriction(pythagorean_reasoning, square_diagonal_relation_ignored,
    "The 45-45-90 triangle is not connected to the diagonal of a square.").
strength_restriction(pythagorean_reasoning, short_leg_not_identified,
    "The short leg in a 30-60-90 triangle is not identified.").
strength_restriction(pythagorean_reasoning, equilateral_half_relation_ignored,
    "The 30-60-90 triangle is not connected to half of an equilateral triangle.").

strength_rejects(pythagorean_reasoning, right_triangle_side_relation, theorem_as_arbitrary_formula).
strength_rejects(pythagorean_reasoning, right_triangle_side_relation, non_side_quantity_from_pythagoras).
strength_rejects(pythagorean_reasoning, right_triangle_side_relation, hypotenuse_not_identified).
strength_rejects(pythagorean_reasoning, right_triangle_side_relation, any_side_used_as_c).

strength_rejects(pythagorean_reasoning, hypotenuse_application, theorem_as_arbitrary_formula).
strength_rejects(pythagorean_reasoning, hypotenuse_application, non_side_quantity_from_pythagoras).
strength_rejects(pythagorean_reasoning, hypotenuse_application, hypotenuse_not_identified).
strength_rejects(pythagorean_reasoning, hypotenuse_application, any_side_used_as_c).
strength_rejects(pythagorean_reasoning, hypotenuse_application, longest_side_not_hypotenuse).

strength_rejects(pythagorean_reasoning, constructed_right_triangle_reasoning, theorem_as_arbitrary_formula).
strength_rejects(pythagorean_reasoning, constructed_right_triangle_reasoning, non_side_quantity_from_pythagoras).
strength_rejects(pythagorean_reasoning, constructed_right_triangle_reasoning, hypotenuse_not_identified).
strength_rejects(pythagorean_reasoning, constructed_right_triangle_reasoning, any_side_used_as_c).
strength_rejects(pythagorean_reasoning, constructed_right_triangle_reasoning, visible_right_angle_required).
strength_rejects(pythagorean_reasoning, constructed_right_triangle_reasoning, auxiliary_right_triangle_disallowed).

strength_rejects(pythagorean_reasoning, converse_right_triangle_test, theorem_as_arbitrary_formula).
strength_rejects(pythagorean_reasoning, converse_right_triangle_test, non_side_quantity_from_pythagoras).
strength_rejects(pythagorean_reasoning, converse_right_triangle_test, hypotenuse_not_identified).
strength_rejects(pythagorean_reasoning, converse_right_triangle_test, any_side_used_as_c).
strength_rejects(pythagorean_reasoning, converse_right_triangle_test, converse_denied).
strength_rejects(pythagorean_reasoning, converse_right_triangle_test, equation_not_sufficient_for_rightness).
strength_rejects(pythagorean_reasoning, converse_right_triangle_test, inequality_still_right_triangle).

strength_rejects(pythagorean_reasoning, special_45_45_90_ratio, theorem_as_arbitrary_formula).
strength_rejects(pythagorean_reasoning, special_45_45_90_ratio, non_side_quantity_from_pythagoras).
strength_rejects(pythagorean_reasoning, special_45_45_90_ratio, hypotenuse_not_identified).
strength_rejects(pythagorean_reasoning, special_45_45_90_ratio, any_side_used_as_c).
strength_rejects(pythagorean_reasoning, special_45_45_90_ratio, special_angle_ignored).
strength_rejects(pythagorean_reasoning, special_45_45_90_ratio, arbitrary_right_triangle_ratios).
strength_rejects(pythagorean_reasoning, special_45_45_90_ratio, equal_legs_not_used).
strength_rejects(pythagorean_reasoning, special_45_45_90_ratio, square_diagonal_relation_ignored).

strength_rejects(pythagorean_reasoning, special_30_60_90_ratio, theorem_as_arbitrary_formula).
strength_rejects(pythagorean_reasoning, special_30_60_90_ratio, non_side_quantity_from_pythagoras).
strength_rejects(pythagorean_reasoning, special_30_60_90_ratio, hypotenuse_not_identified).
strength_rejects(pythagorean_reasoning, special_30_60_90_ratio, any_side_used_as_c).
strength_rejects(pythagorean_reasoning, special_30_60_90_ratio, special_angle_ignored).
strength_rejects(pythagorean_reasoning, special_30_60_90_ratio, arbitrary_right_triangle_ratios).
strength_rejects(pythagorean_reasoning, special_30_60_90_ratio, short_leg_not_identified).
strength_rejects(pythagorean_reasoning, special_30_60_90_ratio, equilateral_half_relation_ignored).

strength_restriction(transformation_reasoning, anchor_locked_translation,
    "A translation vector is treated as attached to one movable anchor point.").
strength_restriction(transformation_reasoning, transformation_not_point_mapping,
    "A transformation is not treated as a point-to-image mapping.").
strength_restriction(transformation_reasoning, vector_not_applied_to_every_point,
    "A translation is not applied uniformly to every point of the figure.").
strength_restriction(transformation_reasoning, figure_only_transformation,
    "A transformation moves only the named figure rather than acting on the plane.").
strength_restriction(transformation_reasoning, rest_plane_fixed,
    "The rest of the plane is assumed to stay fixed under a transformation.").
strength_restriction(transformation_reasoning, same_axis_orientation_under_reflection,
    "A reflection is required to keep horizontal/vertical axis orientation unchanged.").
strength_restriction(transformation_reasoning, image_not_on_perpendicular,
    "A reflected image point need not lie on the perpendicular through the mirror line.").
strength_restriction(transformation_reasoning, unequal_distance_from_mirror,
    "A reflected point and its image may be at unequal distances from the mirror line.").
strength_restriction(transformation_reasoning, same_side_as_preimage,
    "A reflected image point may remain on the same side of the mirror line as the preimage.").
strength_restriction(transformation_reasoning, out_of_plane_flip_as_plane_rotation,
    "Flipping a figure out of the plane is treated as a 2D rotation.").
strength_restriction(transformation_reasoning, reflection_rotation_collapsed,
    "Reflection and rotation are treated as the same plane transformation.").
strength_restriction(transformation_reasoning, congruent_parts_sufficient_for_symmetry,
    "Splitting a figure into two congruent parts is sufficient for line symmetry.").
strength_restriction(transformation_reasoning, figure_not_partitioned_for_symmetry,
    "Line-symmetry reasoning is attempted without a candidate partition of the figure.").
strength_restriction(transformation_reasoning, halves_not_mirror_images,
    "The two halves of a symmetric figure need not be mirror images across the line.").
strength_restriction(transformation_reasoning, no_single_reflection_line,
    "A line of symmetry need not define a reflection carrying the figure to itself.").
strength_restriction(transformation_reasoning, point_image_segments_arbitrary,
    "Point-image segments are treated as arbitrary connecting segments.").
strength_restriction(transformation_reasoning, point_image_pairs_not_matched,
    "Point-image diagnostic reasoning is attempted without matched preimage/image point pairs.").
strength_restriction(transformation_reasoning, perpendicular_bisectors_not_used,
    "The perpendicular bisectors of point-image segments are not used to locate a rotation center.").
strength_restriction(transformation_reasoning, rotation_center_not_concurrent,
    "Point-image perpendicular bisectors need not concur at the rotation center.").
strength_restriction(transformation_reasoning, midpoints_not_collinear,
    "Midpoints of glide-reflection point-image segments need not be collinear.").
strength_restriction(transformation_reasoning, glide_line_not_from_midpoints,
    "The glide-reflection line is not determined from point-image segment midpoints.").
strength_restriction(transformation_reasoning, composition_result_not_translation,
    "Two reflections across parallel lines are not recognized as a translation.").
strength_restriction(transformation_reasoning, two_reflections_not_composed,
    "Two-reflection composition is not treated as a single resulting transformation.").
strength_restriction(transformation_reasoning, parallel_line_distance_not_doubled,
    "The translation distance from parallel reflections is not twice the line separation.").
strength_restriction(transformation_reasoning, translation_not_perpendicular_to_lines,
    "The translation from parallel reflections is not perpendicular to the reflection lines.").
strength_restriction(transformation_reasoning, composition_result_not_rotation,
    "Two reflections across intersecting lines are not recognized as a rotation.").
strength_restriction(transformation_reasoning, intersecting_angle_not_doubled,
    "The rotation angle from intersecting reflections is not twice the angle between the lines.").
strength_restriction(transformation_reasoning, rotation_center_not_intersection,
    "The rotation center from intersecting reflections is not the intersection point.").

strength_rejects(transformation_reasoning, point_mapping_reading, transformation_not_point_mapping).

strength_rejects(transformation_reasoning, translation_vector_mapping, transformation_not_point_mapping).
strength_rejects(transformation_reasoning, translation_vector_mapping, anchor_locked_translation).
strength_rejects(transformation_reasoning, translation_vector_mapping, vector_not_applied_to_every_point).

strength_rejects(transformation_reasoning, whole_plane_translation, transformation_not_point_mapping).
strength_rejects(transformation_reasoning, whole_plane_translation, anchor_locked_translation).
strength_rejects(transformation_reasoning, whole_plane_translation, vector_not_applied_to_every_point).
strength_rejects(transformation_reasoning, whole_plane_translation, figure_only_transformation).
strength_rejects(transformation_reasoning, whole_plane_translation, rest_plane_fixed).

strength_rejects(transformation_reasoning, reflection_correspondence, transformation_not_point_mapping).
strength_rejects(transformation_reasoning, reflection_correspondence, same_axis_orientation_under_reflection).

strength_rejects(transformation_reasoning, reflection_distance_correspondence, transformation_not_point_mapping).
strength_rejects(transformation_reasoning, reflection_distance_correspondence, same_axis_orientation_under_reflection).
strength_rejects(transformation_reasoning, reflection_distance_correspondence, image_not_on_perpendicular).
strength_rejects(transformation_reasoning, reflection_distance_correspondence, unequal_distance_from_mirror).
strength_rejects(transformation_reasoning, reflection_distance_correspondence, same_side_as_preimage).

strength_rejects(transformation_reasoning, plane_reflection_distinction, transformation_not_point_mapping).
strength_rejects(transformation_reasoning, plane_reflection_distinction, out_of_plane_flip_as_plane_rotation).
strength_rejects(transformation_reasoning, plane_reflection_distinction, reflection_rotation_collapsed).

strength_rejects(transformation_reasoning, congruent_halves_reading, figure_not_partitioned_for_symmetry).

strength_rejects(transformation_reasoning, line_symmetry_reflection_test, figure_not_partitioned_for_symmetry).
strength_rejects(transformation_reasoning, line_symmetry_reflection_test, congruent_parts_sufficient_for_symmetry).
strength_rejects(transformation_reasoning, line_symmetry_reflection_test, halves_not_mirror_images).
strength_rejects(transformation_reasoning, line_symmetry_reflection_test, no_single_reflection_line).

strength_rejects(transformation_reasoning, point_image_segment_pairing, point_image_pairs_not_matched).

strength_rejects(transformation_reasoning, rotation_center_diagnostic, point_image_pairs_not_matched).
strength_rejects(transformation_reasoning, rotation_center_diagnostic, point_image_segments_arbitrary).
strength_rejects(transformation_reasoning, rotation_center_diagnostic, perpendicular_bisectors_not_used).
strength_rejects(transformation_reasoning, rotation_center_diagnostic, rotation_center_not_concurrent).

strength_rejects(transformation_reasoning, glide_reflection_line_diagnostic, point_image_pairs_not_matched).
strength_rejects(transformation_reasoning, glide_reflection_line_diagnostic, point_image_segments_arbitrary).
strength_rejects(transformation_reasoning, glide_reflection_line_diagnostic, midpoints_not_collinear).
strength_rejects(transformation_reasoning, glide_reflection_line_diagnostic, glide_line_not_from_midpoints).

strength_rejects(transformation_reasoning, reflection_composition_reading, two_reflections_not_composed).

strength_rejects(transformation_reasoning, parallel_reflections_translation, two_reflections_not_composed).
strength_rejects(transformation_reasoning, parallel_reflections_translation, composition_result_not_translation).
strength_rejects(transformation_reasoning, parallel_reflections_translation, parallel_line_distance_not_doubled).
strength_rejects(transformation_reasoning, parallel_reflections_translation, translation_not_perpendicular_to_lines).

strength_rejects(transformation_reasoning, intersecting_reflections_rotation, two_reflections_not_composed).
strength_rejects(transformation_reasoning, intersecting_reflections_rotation, composition_result_not_rotation).
strength_rejects(transformation_reasoning, intersecting_reflections_rotation, intersecting_angle_not_doubled).
strength_rejects(transformation_reasoning, intersecting_reflections_rotation, rotation_center_not_intersection).

strength_restriction(angle_reasoning, one_ray_sufficient_for_angle,
    "A single ray is treated as enough to specify an angle.").
strength_restriction(angle_reasoning, arm_length_changes_angle_measure,
    "Longer drawn arms are treated as increasing angle measure.").
strength_restriction(angle_reasoning, unequal_arm_lengths_break_angle_congruence,
    "Angles with equal measure are not treated as congruent when their arms are drawn at different lengths.").
strength_restriction(angle_reasoning, nonparallel_corresponding_angles_equal,
    "Corresponding angles are assumed equal without parallel cut lines.").
strength_restriction(angle_reasoning, parallel_condition_ignored_for_transversal,
    "The parallel-line condition is ignored in transversal angle reasoning.").
strength_restriction(angle_reasoning, triangle_size_changes_angle_sum,
    "A larger triangle is assumed to have a larger interior angle sum.").
strength_restriction(angle_reasoning, every_polygon_has_180_degrees,
    "The 180-degree triangle angle sum is applied to every polygon.").
strength_restriction(angle_reasoning, inductive_trials_sufficient_for_theorem,
    "Repeated measured examples are treated as a proof of the triangle angle-sum theorem.").
strength_restriction(angle_reasoning, fan_triangulation_not_required,
    "A polygon angle-sum argument does not require a fan triangulation or equivalent decomposition.").
strength_restriction(angle_reasoning, polygon_triangles_equal_side_count,
    "An n-gon is treated as decomposing into n interior-sum triangles.").
strength_restriction(angle_reasoning, center_triangulation_angles_counted,
    "Central decomposition angles that are not polygon interior angles are counted in the polygon sum.").

strength_rejects(angle_reasoning, ray_pair_angle_structure, one_ray_sufficient_for_angle).

strength_rejects(angle_reasoning, arm_length_angle_measure_invariance, one_ray_sufficient_for_angle).
strength_rejects(angle_reasoning, arm_length_angle_measure_invariance, arm_length_changes_angle_measure).
strength_rejects(angle_reasoning, arm_length_angle_measure_invariance, unequal_arm_lengths_break_angle_congruence).

strength_rejects(angle_reasoning, parallel_transversal_angle_relation, one_ray_sufficient_for_angle).
strength_rejects(angle_reasoning, parallel_transversal_angle_relation, arm_length_changes_angle_measure).
strength_rejects(angle_reasoning, parallel_transversal_angle_relation, unequal_arm_lengths_break_angle_congruence).
strength_rejects(angle_reasoning, parallel_transversal_angle_relation, nonparallel_corresponding_angles_equal).
strength_rejects(angle_reasoning, parallel_transversal_angle_relation, parallel_condition_ignored_for_transversal).

strength_rejects(angle_reasoning, inductive_triangle_sum_conjecture, one_ray_sufficient_for_angle).
strength_rejects(angle_reasoning, inductive_triangle_sum_conjecture, arm_length_changes_angle_measure).
strength_rejects(angle_reasoning, inductive_triangle_sum_conjecture, unequal_arm_lengths_break_angle_congruence).
strength_rejects(angle_reasoning, inductive_triangle_sum_conjecture, triangle_size_changes_angle_sum).
strength_rejects(angle_reasoning, inductive_triangle_sum_conjecture, every_polygon_has_180_degrees).

strength_rejects(angle_reasoning, triangle_angle_sum_theorem, one_ray_sufficient_for_angle).
strength_rejects(angle_reasoning, triangle_angle_sum_theorem, arm_length_changes_angle_measure).
strength_rejects(angle_reasoning, triangle_angle_sum_theorem, unequal_arm_lengths_break_angle_congruence).
strength_rejects(angle_reasoning, triangle_angle_sum_theorem, triangle_size_changes_angle_sum).
strength_rejects(angle_reasoning, triangle_angle_sum_theorem, every_polygon_has_180_degrees).
strength_rejects(angle_reasoning, triangle_angle_sum_theorem, inductive_trials_sufficient_for_theorem).

strength_rejects(angle_reasoning, polygon_angle_sum_triangulation, one_ray_sufficient_for_angle).
strength_rejects(angle_reasoning, polygon_angle_sum_triangulation, arm_length_changes_angle_measure).
strength_rejects(angle_reasoning, polygon_angle_sum_triangulation, unequal_arm_lengths_break_angle_congruence).
strength_rejects(angle_reasoning, polygon_angle_sum_triangulation, triangle_size_changes_angle_sum).
strength_rejects(angle_reasoning, polygon_angle_sum_triangulation, every_polygon_has_180_degrees).
strength_rejects(angle_reasoning, polygon_angle_sum_triangulation, inductive_trials_sufficient_for_theorem).
strength_rejects(angle_reasoning, polygon_angle_sum_triangulation, fan_triangulation_not_required).
strength_rejects(angle_reasoning, polygon_angle_sum_triangulation, polygon_triangles_equal_side_count).
strength_rejects(angle_reasoning, polygon_angle_sum_triangulation, center_triangulation_angles_counted).

strength_restriction(similarity_reasoning, visual_appearance_sufficient,
    "Figures that look alike are treated as mathematically similar.").
strength_restriction(similarity_reasoning, additive_side_change_preserves_similarity,
    "Adding the same amount to each side is treated as preserving shape.").
strength_restriction(similarity_reasoning, corresponding_side_ratios_not_checked,
    "Corresponding side ratios are not checked when judging similarity.").
strength_restriction(similarity_reasoning, area_ratio_sufficient_for_similarity,
    "Area comparison alone is treated as enough to establish similarity.").
strength_restriction(similarity_reasoning, angles_scale_with_side_factor,
    "Corresponding angles are multiplied by the side scale factor.").
strength_restriction(similarity_reasoning, angle_measure_changes_under_scaling,
    "A dilation changes angle measures.").

strength_rejects(similarity_reasoning, side_change_similarity_reading, visual_appearance_sufficient).

strength_rejects(similarity_reasoning, mathematical_similarity_criterion, visual_appearance_sufficient).
strength_rejects(similarity_reasoning, mathematical_similarity_criterion, additive_side_change_preserves_similarity).
strength_rejects(similarity_reasoning, mathematical_similarity_criterion, corresponding_side_ratios_not_checked).
strength_rejects(similarity_reasoning, mathematical_similarity_criterion, area_ratio_sufficient_for_similarity).

strength_rejects(similarity_reasoning, triangle_similarity_angle_preservation, visual_appearance_sufficient).
strength_rejects(similarity_reasoning, triangle_similarity_angle_preservation, additive_side_change_preserves_similarity).
strength_rejects(similarity_reasoning, triangle_similarity_angle_preservation, corresponding_side_ratios_not_checked).
strength_rejects(similarity_reasoning, triangle_similarity_angle_preservation, area_ratio_sufficient_for_similarity).
strength_rejects(similarity_reasoning, triangle_similarity_angle_preservation, angles_scale_with_side_factor).
strength_rejects(similarity_reasoning, triangle_similarity_angle_preservation, angle_measure_changes_under_scaling).

strength_restriction(definition_reasoning, category_membership_not_at_issue,
    "A category judgment is made without treating category membership as a property question.").
strength_restriction(definition_reasoning, drawing_object_not_at_issue,
    "A drawn object is discussed without separating physical mark from mathematical object.").
strength_restriction(definition_reasoning, universal_claim_not_at_issue,
    "A universal claim is made without treating it as a claim requiring general warrant.").
strength_restriction(definition_reasoning, definition_not_at_issue,
    "A definition candidate is used without testing its scope.").
strength_restriction(definition_reasoning, prototype_appearance_decides_category,
    "A shape's visual prototype or orientation decides category membership.").
strength_restriction(definition_reasoning, nonprototypical_orientation_excludes_category,
    "A non-prototypical orientation excludes a shape from its category.").
strength_restriction(definition_reasoning, property_test_ignored_for_category,
    "A category property test is ignored.").
strength_restriction(definition_reasoning, physical_mark_properties_enter_definition,
    "Thickness or other physical drawing properties enter the mathematical definition.").
strength_restriction(definition_reasoning, roundness_sufficient_for_circle,
    "Roundness and no straight pieces are treated as sufficient for circlehood.").
strength_restriction(definition_reasoning, open_or_curved_triangle_allowed,
    "A triangle may be open or have non-straight sides.").
strength_restriction(definition_reasoning, empirical_examples_prove_universal,
    "Checking a few examples is treated as proof of a general claim.").
strength_restriction(definition_reasoning, necessary_condition_only_definition,
    "A merely necessary condition is treated as a valid definition.").
strength_restriction(definition_reasoning, sufficient_condition_only_definition,
    "A merely sufficient condition is treated as a valid definition.").
strength_restriction(definition_reasoning, extension_mismatch_allows_equivalence,
    "Two definitions with different extensions are treated as equivalent.").

strength_rejects(definition_reasoning, visual_category_reading, category_membership_not_at_issue).

strength_rejects(definition_reasoning, physical_drawing_reading, drawing_object_not_at_issue).

strength_rejects(definition_reasoning, empirical_generalization_reading, universal_claim_not_at_issue).

strength_rejects(definition_reasoning, definition_candidate_reading, definition_not_at_issue).

strength_rejects(definition_reasoning, property_based_classification, category_membership_not_at_issue).
strength_rejects(definition_reasoning, property_based_classification, prototype_appearance_decides_category).
strength_rejects(definition_reasoning, property_based_classification, nonprototypical_orientation_excludes_category).
strength_rejects(definition_reasoning, property_based_classification, property_test_ignored_for_category).

strength_rejects(definition_reasoning, formal_object_definition, drawing_object_not_at_issue).
strength_rejects(definition_reasoning, formal_object_definition, physical_mark_properties_enter_definition).

strength_rejects(definition_reasoning, triangle_definition_closure, category_membership_not_at_issue).
strength_rejects(definition_reasoning, triangle_definition_closure, prototype_appearance_decides_category).
strength_rejects(definition_reasoning, triangle_definition_closure, nonprototypical_orientation_excludes_category).
strength_rejects(definition_reasoning, triangle_definition_closure, property_test_ignored_for_category).
strength_rejects(definition_reasoning, triangle_definition_closure, open_or_curved_triangle_allowed).

strength_rejects(definition_reasoning, necessary_sufficient_definition, definition_not_at_issue).
strength_rejects(definition_reasoning, necessary_sufficient_definition, universal_claim_not_at_issue).
strength_rejects(definition_reasoning, necessary_sufficient_definition, empirical_examples_prove_universal).
strength_rejects(definition_reasoning, necessary_sufficient_definition, necessary_condition_only_definition).
strength_rejects(definition_reasoning, necessary_sufficient_definition, sufficient_condition_only_definition).

strength_rejects(definition_reasoning, equivalent_definition_extension, definition_not_at_issue).
strength_rejects(definition_reasoning, equivalent_definition_extension, universal_claim_not_at_issue).
strength_rejects(definition_reasoning, equivalent_definition_extension, empirical_examples_prove_universal).
strength_rejects(definition_reasoning, equivalent_definition_extension, necessary_condition_only_definition).
strength_rejects(definition_reasoning, equivalent_definition_extension, sufficient_condition_only_definition).
strength_rejects(definition_reasoning, equivalent_definition_extension, extension_mismatch_allows_equivalence).

strength_restriction(measurement_formula_reasoning, area_counting_not_at_issue,
    "Area measurement is attempted without a unit-coverage question.").
strength_restriction(measurement_formula_reasoning, rectangle_boundary_not_at_issue,
    "Rectangle boundary measurement is attempted without a complete boundary question.").
strength_restriction(measurement_formula_reasoning, polyhedron_counting_not_at_issue,
    "Polyhedron structure is counted without an invariant relation among faces, vertices, and edges.").
strength_restriction(measurement_formula_reasoning, gaps_or_overlaps_allowed,
    "Unit coverage may contain gaps or overlaps.").
strength_restriction(measurement_formula_reasoning, boundary_count_as_area_measure,
    "Boundary units alone are treated as area.").
strength_restriction(measurement_formula_reasoning, single_length_width_sum_as_perimeter,
    "Adding length and width once is treated as rectangle perimeter.").
strength_restriction(measurement_formula_reasoning, only_one_pair_of_sides_counted,
    "Only one pair of rectangle sides is counted for perimeter.").
strength_restriction(measurement_formula_reasoning, area_not_structured_by_rows_columns,
    "Rectangle area is not structured as rows by columns.").
strength_restriction(measurement_formula_reasoning, area_order_implies_perimeter_order,
    "Greater area is assumed to imply greater perimeter.").
strength_restriction(measurement_formula_reasoning, noncongruence_precludes_equal_area,
    "Non-congruent regions are assumed unable to have equal area.").
strength_restriction(measurement_formula_reasoning, transformation_changes_area_without_reason,
    "A transformation changes area without a relevant area-changing operation.").
strength_restriction(measurement_formula_reasoning, pick_formula_on_non_simple_figure,
    "Pick's formula is applied to a self-intersecting or multi-band figure.").
strength_restriction(measurement_formula_reasoning, boundary_pegs_counted_as_whole_area_units,
    "Boundary lattice points are counted as whole area units.").
strength_restriction(measurement_formula_reasoning, base_area_not_layered_by_height,
    "A prism's base area is not treated as a layer repeated by height.").
strength_restriction(measurement_formula_reasoning, cubic_units_not_required,
    "A volume formula is reported without cubic units.").
strength_restriction(measurement_formula_reasoning, pyramid_same_as_prism,
    "A pyramid with base area B and height h is treated as having volume B*h.").
strength_restriction(measurement_formula_reasoning, pyramid_one_third_factor_ignored,
    "The one-third factor in pyramid volume is ignored.").
strength_restriction(measurement_formula_reasoning, nonconvex_polyhedron_uses_euler_two,
    "Euler's F+V-E=2 invariant is applied without the convex-polyhedron condition.").
strength_restriction(measurement_formula_reasoning, face_vertex_edge_relation_unchecked,
    "Faces, vertices, and edges are counted without checking F+V-E.").

strength_rejects(measurement_formula_reasoning, area_counting_reading, area_counting_not_at_issue).

strength_rejects(measurement_formula_reasoning, rectangle_boundary_reading, rectangle_boundary_not_at_issue).

strength_rejects(measurement_formula_reasoning, polyhedron_counting_reading, polyhedron_counting_not_at_issue).

strength_rejects(measurement_formula_reasoning, area_interior_coverage_formula, area_counting_not_at_issue).
strength_rejects(measurement_formula_reasoning, area_interior_coverage_formula, gaps_or_overlaps_allowed).
strength_rejects(measurement_formula_reasoning, area_interior_coverage_formula, boundary_count_as_area_measure).

strength_rejects(measurement_formula_reasoning, rectangle_perimeter_formula, rectangle_boundary_not_at_issue).
strength_rejects(measurement_formula_reasoning, rectangle_perimeter_formula, single_length_width_sum_as_perimeter).
strength_rejects(measurement_formula_reasoning, rectangle_perimeter_formula, only_one_pair_of_sides_counted).

strength_rejects(measurement_formula_reasoning, area_array_formula, area_counting_not_at_issue).
strength_rejects(measurement_formula_reasoning, area_array_formula, gaps_or_overlaps_allowed).
strength_rejects(measurement_formula_reasoning, area_array_formula, boundary_count_as_area_measure).
strength_rejects(measurement_formula_reasoning, area_array_formula, area_not_structured_by_rows_columns).

strength_rejects(measurement_formula_reasoning, area_perimeter_independence_reasoning, area_counting_not_at_issue).
strength_rejects(measurement_formula_reasoning, area_perimeter_independence_reasoning, gaps_or_overlaps_allowed).
strength_rejects(measurement_formula_reasoning, area_perimeter_independence_reasoning, boundary_count_as_area_measure).
strength_rejects(measurement_formula_reasoning, area_perimeter_independence_reasoning, area_order_implies_perimeter_order).

strength_rejects(measurement_formula_reasoning, area_conservation_invariant, area_counting_not_at_issue).
strength_rejects(measurement_formula_reasoning, area_conservation_invariant, gaps_or_overlaps_allowed).
strength_rejects(measurement_formula_reasoning, area_conservation_invariant, boundary_count_as_area_measure).
strength_rejects(measurement_formula_reasoning, area_conservation_invariant, noncongruence_precludes_equal_area).
strength_rejects(measurement_formula_reasoning, area_conservation_invariant, transformation_changes_area_without_reason).

strength_rejects(measurement_formula_reasoning, pick_lattice_area_formula, area_counting_not_at_issue).
strength_rejects(measurement_formula_reasoning, pick_lattice_area_formula, gaps_or_overlaps_allowed).
strength_rejects(measurement_formula_reasoning, pick_lattice_area_formula, boundary_count_as_area_measure).
strength_rejects(measurement_formula_reasoning, pick_lattice_area_formula, pick_formula_on_non_simple_figure).
strength_rejects(measurement_formula_reasoning, pick_lattice_area_formula, boundary_pegs_counted_as_whole_area_units).

strength_rejects(measurement_formula_reasoning, prism_stack_volume_formula, area_counting_not_at_issue).
strength_rejects(measurement_formula_reasoning, prism_stack_volume_formula, gaps_or_overlaps_allowed).
strength_rejects(measurement_formula_reasoning, prism_stack_volume_formula, boundary_count_as_area_measure).
strength_rejects(measurement_formula_reasoning, prism_stack_volume_formula, area_not_structured_by_rows_columns).
strength_rejects(measurement_formula_reasoning, prism_stack_volume_formula, base_area_not_layered_by_height).
strength_rejects(measurement_formula_reasoning, prism_stack_volume_formula, cubic_units_not_required).

strength_rejects(measurement_formula_reasoning, pyramid_volume_formula, area_counting_not_at_issue).
strength_rejects(measurement_formula_reasoning, pyramid_volume_formula, gaps_or_overlaps_allowed).
strength_rejects(measurement_formula_reasoning, pyramid_volume_formula, boundary_count_as_area_measure).
strength_rejects(measurement_formula_reasoning, pyramid_volume_formula, area_not_structured_by_rows_columns).
strength_rejects(measurement_formula_reasoning, pyramid_volume_formula, base_area_not_layered_by_height).
strength_rejects(measurement_formula_reasoning, pyramid_volume_formula, cubic_units_not_required).
strength_rejects(measurement_formula_reasoning, pyramid_volume_formula, pyramid_same_as_prism).
strength_rejects(measurement_formula_reasoning, pyramid_volume_formula, pyramid_one_third_factor_ignored).

strength_rejects(measurement_formula_reasoning, euler_polyhedron_invariant, polyhedron_counting_not_at_issue).
strength_rejects(measurement_formula_reasoning, euler_polyhedron_invariant, nonconvex_polyhedron_uses_euler_two).
strength_rejects(measurement_formula_reasoning, euler_polyhedron_invariant, face_vertex_edge_relation_unchecked).

strength_restriction(attribute_spatial_reasoning, side_equality_not_at_issue,
    "Side equality is discussed without checking angle structure.").
strength_restriction(attribute_spatial_reasoning, equal_sides_force_equal_angles,
    "Equal side lengths are treated as forcing equal angles in any polygon.").
strength_restriction(attribute_spatial_reasoning, segment_length_not_at_issue,
    "Segment length comparison is made without a parallelism relation.").
strength_restriction(attribute_spatial_reasoning, equal_length_segments_force_parallel,
    "Equal segment length is treated as sufficient for parallelism.").
strength_restriction(attribute_spatial_reasoning, diagram_appearance_not_at_issue,
    "A diagram appearance judgment is made without checking the defining relation.").
strength_restriction(attribute_spatial_reasoning, visual_right_angle_sufficient,
    "Looking perpendicular in a diagram is treated as sufficient for perpendicularity.").
strength_restriction(attribute_spatial_reasoning, oblique_axis_not_at_issue,
    "An oblique drawn axis is read without preserving 3D-axis structure.").
strength_restriction(attribute_spatial_reasoning, oblique_axis_is_negative_direction,
    "An oblique third axis is treated as the negative direction of another axis.").
strength_restriction(attribute_spatial_reasoning, bottom_face_not_at_issue,
    "A base judgment is made from whichever face is visually at the bottom.").
strength_restriction(attribute_spatial_reasoning, base_changes_under_reorientation,
    "The base of a solid changes when the solid is reoriented.").
strength_restriction(attribute_spatial_reasoning, convexity_not_at_issue,
    "Convexity is discussed without checking an equivalent convexity test.").
strength_restriction(attribute_spatial_reasoning, reflex_angle_ignored_for_convexity,
    "A polygon with a reflex angle is treated as convex.").
strength_restriction(attribute_spatial_reasoning, interior_segment_test_ignored,
    "The line-segment-inside test is ignored for convexity.").

strength_rejects(attribute_spatial_reasoning, side_only_polygon_reading, side_equality_not_at_issue).

strength_rejects(attribute_spatial_reasoning, regular_polygon_angle_reasoning, side_equality_not_at_issue).
strength_rejects(attribute_spatial_reasoning, regular_polygon_angle_reasoning, equal_sides_force_equal_angles).

strength_rejects(attribute_spatial_reasoning, length_equality_parallel_reading, segment_length_not_at_issue).

strength_rejects(attribute_spatial_reasoning, parallel_relation_reasoning, segment_length_not_at_issue).
strength_rejects(attribute_spatial_reasoning, parallel_relation_reasoning, equal_length_segments_force_parallel).

strength_rejects(attribute_spatial_reasoning, visual_perpendicular_reading, diagram_appearance_not_at_issue).

strength_rejects(attribute_spatial_reasoning, perpendicular_right_angle_relation, diagram_appearance_not_at_issue).
strength_rejects(attribute_spatial_reasoning, perpendicular_right_angle_relation, visual_right_angle_sufficient).

strength_rejects(attribute_spatial_reasoning, oblique_axis_drawing_reading, oblique_axis_not_at_issue).

strength_rejects(attribute_spatial_reasoning, orthogonal_3d_axis_reasoning, oblique_axis_not_at_issue).
strength_rejects(attribute_spatial_reasoning, orthogonal_3d_axis_reasoning, oblique_axis_is_negative_direction).

strength_rejects(attribute_spatial_reasoning, bottom_face_base_reading, bottom_face_not_at_issue).

strength_rejects(attribute_spatial_reasoning, structural_base_reasoning, bottom_face_not_at_issue).
strength_rejects(attribute_spatial_reasoning, structural_base_reasoning, base_changes_under_reorientation).

strength_rejects(attribute_spatial_reasoning, polygon_shape_reading, convexity_not_at_issue).

strength_rejects(attribute_spatial_reasoning, convexity_reflex_angle_test, convexity_not_at_issue).
strength_rejects(attribute_spatial_reasoning, convexity_reflex_angle_test, reflex_angle_ignored_for_convexity).

strength_rejects(attribute_spatial_reasoning, convexity_line_segment_test, convexity_not_at_issue).
strength_rejects(attribute_spatial_reasoning, convexity_line_segment_test, interior_segment_test_ignored).

strength_rejections(Domain, Term, Restrictions) :-
    strength_term(Domain, Term),
    findall(R, strength_rejects(Domain, Term, R), Raw),
    sort(Raw, Restrictions).

strength_value(Domain, Term, Strength) :-
    strength_rejections(Domain, Term, Restrictions),
    length(Restrictions, Strength).

stronger_than(Domain, Stronger, Weaker) :-
    strength_term(Domain, Stronger),
    strength_term(Domain, Weaker),
    Stronger \== Weaker,
    forall(strength_rejects(Domain, Weaker, R),
           strength_rejects(Domain, Stronger, R)),
    once((strength_rejects(Domain, Stronger, Extra),
          \+ strength_rejects(Domain, Weaker, Extra))).

strength_profile(Domain, Term,
    profile(Domain, Term, strength(Strength), rejects(Restrictions))) :-
    strength_value(Domain, Term, Strength),
    strength_rejections(Domain, Term, Restrictions).

strength_inference(Domain, Stronger, Weaker,
    inference(Domain, Stronger, Weaker, entitled, Detail)) :-
    strength_inference_witness(Domain,
                               Stronger,
                               Weaker,
                               inference(Domain, Stronger, Weaker, entitled, Detail),
                               _).
strength_inference(Domain, Stronger, Weaker,
    inference(Domain, Stronger, Weaker, not_entitled, Detail)) :-
    strength_inference_witness(Domain,
                               Stronger,
                               Weaker,
                               inference(Domain, Stronger, Weaker, not_entitled, Detail),
                               _).

strength_inference_witness(Domain,
                           Stronger,
                           Weaker,
                           inference(Domain, Stronger, Weaker, entitled, Detail),
                           _{ kind: material_strength_inference,
                              scope: closed_world_finite_material_strength_table,
                              status: entitled,
                              domain: Domain,
                              stronger: Stronger,
                              weaker: Weaker,
                              reason: all_weaker_rejections_preserved,
                              required_rejections: WeakerRestrictions,
                              proving_rejections: StrongerRestrictions,
                              extra_rejections: Extra,
                              stronger_profile: StrongerProfile,
                              weaker_profile: WeakerProfile }) :-
    stronger_than(Domain, Stronger, Weaker),
    strength_profile(Domain, Stronger, StrongerProfile),
    strength_profile(Domain, Weaker, WeakerProfile),
    StrongerProfile = profile(_, _, _, rejects(StrongerRestrictions)),
    WeakerProfile = profile(_, _, _, rejects(WeakerRestrictions)),
    findall(R,
            ( member(R, StrongerRestrictions),
              \+ memberchk(R, WeakerRestrictions)
            ),
            RawExtra),
    sort(RawExtra, Extra),
    Detail = detail(
        stronger(StrongerProfile),
        weaker(WeakerProfile),
        because(Stronger, rejects_everything_rejected_by(Weaker))
    ),
    !.
strength_inference_witness(Domain,
                           Stronger,
                           Weaker,
                           inference(Domain, Stronger, Weaker, not_entitled, Detail),
                           _{ kind: material_strength_inference,
                              scope: closed_world_finite_material_strength_table,
                              status: not_entitled,
                              domain: Domain,
                              stronger_candidate: Stronger,
                              weaker_candidate: Weaker,
                              reason: missing_required_rejections,
                              required_rejections: WeakerRestrictions,
                              proving_rejections: StrongerRestrictions,
                              missing_rejections: Missing,
                              stronger_profile: StrongerProfile,
                              weaker_profile: WeakerProfile }) :-
    strength_term(Domain, Stronger),
    strength_term(Domain, Weaker),
    strength_profile(Domain, Stronger, StrongerProfile),
    strength_profile(Domain, Weaker, WeakerProfile),
    StrongerProfile = profile(_, _, _, rejects(StrongerRestrictions)),
    WeakerProfile = profile(_, _, _, rejects(WeakerRestrictions)),
    findall(R,
            ( member(R, WeakerRestrictions),
              \+ memberchk(R, StrongerRestrictions)
            ),
            RawMissing),
    sort(RawMissing, Missing),
    Detail = detail(
        stronger_candidate(StrongerProfile),
        weaker_candidate(WeakerProfile),
        missing_rejections(Missing)
    ).

% ── Flat material inferences lifted into strength order ─────────────

flat_strength_lift(square_to_rectangle,
    square_as_rectangle,
    "shape S has four right angles AND four equal sides",
    "S is a rectangle (and additionally a square)",
    entitled,
    quadrilateral_class,
    square,
    rectangle,
    "Square rejects every rectangle-level incompatibility plus equal-side restrictions.").

flat_strength_lift(square_to_rhombus,
    square_as_rhombus,
    "shape S has four equal sides AND four right angles",
    "S is a rhombus (and additionally a square)",
    entitled,
    quadrilateral_class,
    square,
    rhombus,
    "Square rejects every rhombus-level incompatibility plus right-angle restrictions.").

flat_strength_lift(rectangle_to_parallelogram,
    rectangle_as_parallelogram,
    "shape S has two pairs of parallel sides AND four right angles",
    "S is a parallelogram (and additionally a rectangle)",
    entitled,
    quadrilateral_class,
    rectangle,
    parallelogram,
    "Rectangle rejects the parallelogram restrictions plus no-right-angle cases.").

flat_strength_lift(rhombus_to_parallelogram,
    rhombus_as_parallelogram,
    "shape S has four equal sides",
    "S has two pairs of parallel sides — S is a parallelogram",
    entitled,
    quadrilateral_class,
    rhombus,
    parallelogram,
    "Rhombus rejects the parallelogram restrictions plus adjacent-side inequality.").

flat_strength_lift(parallelogram_to_quadrilateral,
    parallelogram_as_quadrilateral,
    "shape S has two pairs of parallel sides",
    "S has four sides — S is a quadrilateral",
    entitled,
    quadrilateral_class,
    parallelogram,
    quadrilateral,
    "Parallelogram rules out non-parallel-opposite-side cases; quadrilateral does not.").

flat_strength_lift(parallelogram_to_trapezoid,
    parallelogram_as_trapezoid,
    "shape S has two pairs of parallel sides",
    "S has at least one pair of parallel sides — S is a trapezoid (inclusive definition)",
    entitled,
    quadrilateral_class,
    parallelogram,
    trapezoid,
    "Under the inclusive trapezoid definition, two parallel pairs rejects at least what one pair rejects.").

flat_strength_lift(quadrilateral_hierarchy_property_list,
    quadrilateral_hierarchy,
    "shape S satisfies the property list for category C",
    "S belongs to C, even if S also belongs to a more-specific subcategory of C",
    entitled,
    classification_stance,
    inclusive_definition,
    exclusive_definition,
    "Property-list hierarchy rejects exclusive name-cancels-category reasoning.").

flat_strength_lift(quadrilateral_hierarchy_rejects_name_cancellation,
    quadrilateral_hierarchy,
    "shape S has a more-specific name (e.g., square)",
    "S's more-general names (rectangle, rhombus, parallelogram, trapezoid, quadrilateral) no longer apply",
    incompatible,
    classification_stance,
    inclusive_definition,
    exclusive_definition,
    "Inclusive classification rejects the claim that a more-specific name cancels general class membership.").

flat_strength_lift(rectangle_rejects_not_parallelogram,
    rectangle_as_parallelogram,
    "shape S is a rectangle",
    "S is NOT a parallelogram (because rectangles and parallelograms are separate classes)",
    incompatible,
    quadrilateral_class,
    rectangle,
    parallelogram,
    "Rectangle rejects the no-parallelogram reading by satisfying all parallelogram restrictions plus right angles.").

flat_strength_lift(square_rejects_not_rectangle,
    square_as_rectangle,
    "shape S is a square",
    "S is NOT a rectangle (because the names are different)",
    incompatible,
    quadrilateral_class,
    square,
    rectangle,
    "Square rejects the name-difference cancellation of rectangle membership.").

flat_strength_lift(square_rejects_not_rhombus,
    square_as_rhombus,
    "shape S is a square",
    "S is NOT a rhombus (because squares aren't tilted)",
    incompatible,
    quadrilateral_class,
    square,
    rhombus,
    "Square rejects prototype-tilt cancellation of rhombus membership.").

flat_strength_lift(rhombus_rejects_not_parallelogram,
    rhombus_as_parallelogram,
    "shape S is a rhombus",
    "S is NOT a parallelogram (rhombus is the diamond, parallelogram is the slanted)",
    incompatible,
    quadrilateral_class,
    rhombus,
    parallelogram,
    "Rhombus rejects treating rhombus and parallelogram as disjoint visual prototypes.").

flat_strength_lift(parallelogram_rejects_quadrilateral_converse,
    parallelogram_as_quadrilateral,
    "shape S has four sides and is closed",
    "S is a parallelogram (every quadrilateral is a parallelogram)",
    incompatible,
    quadrilateral_class,
    parallelogram,
    quadrilateral,
    "Parallelogram is stronger than quadrilateral; the converse from quadrilateral to parallelogram is not entitled.").

flat_strength_lift(parallelogram_rejects_not_quadrilateral,
    parallelogram_as_quadrilateral,
    "shape S is a parallelogram",
    "S is NOT a quadrilateral (parallelograms are special, not generic four-sided)",
    incompatible,
    quadrilateral_class,
    parallelogram,
    quadrilateral,
    "Parallelogram rejects the special-name-cancels-quadrilateral reading.").

flat_strength_lift(parallelogram_trapezoid_exclusive_rejection,
    parallelogram_as_trapezoid,
    "shape S is a parallelogram",
    "S is NOT a trapezoid (under the exclusive 'only one pair of parallel sides' definition)",
    incompatible,
    classification_stance,
    inclusive_definition,
    exclusive_definition,
    "Inclusive trapezoid classification rejects the exclusive disjoint-class reading.").

flat_strength_lift(exclusive_transition_rejects_square_only,
    exclusive_to_inclusive_transition,
    "shape S is a square AND the student is using exclusive definitions",
    "S is a square (only) — using property-based hierarchical reasoning is incompatible with the exclusive stance",
    incompatible,
    classification_stance,
    inclusive_definition,
    exclusive_definition,
    "The inclusive transition rejects square-only classification when hierarchy is in play.").

flat_strength_lift(square_rectangle_full_property_variant,
    square_as_rectangle,
    "shape S has four right angles AND opposite sides parallel AND opposite sides equal",
    "S is a rectangle (regardless of whether all four sides happen to be equal)",
    entitled,
    quadrilateral_class,
    square,
    rectangle,
    "The full property variant still places square above rectangle in the strength order.").

flat_strength_lift(kite_class_over_quadrilateral,
    kite_class,
    "shape S is a convex quadrilateral with two opposing pairs of congruent adjacent sides",
    "S is a kite",
    entitled,
    quadrilateral_class,
    kite,
    quadrilateral,
    "Kite classification adds adjacent-side congruence restrictions to quadrilateral membership.").

flat_strength_lift(inclusive_over_exclusive,
    exclusive_to_inclusive_transition,
    "shape S is a square AND the student is using inclusive definitions",
    "S is also a rectangle, also a parallelogram, also a quadrilateral",
    entitled,
    classification_stance,
    inclusive_definition,
    exclusive_definition,
    "Inclusive definition rejects disjoint buckets and name-cancels-class reasoning.").

flat_strength_lift(square_classification_transition,
    square_classification_arc,
    "student demonstrates level-2 utterances such as 'every square is a rectangle' or eliminates redundant defining properties",
    "student has crossed the from-stance to-stance transition described by this arc; both source concepts (square_recognition, square_rectangle_classification) now apply",
    entitled,
    classification_stance,
    square_rectangle_classification,
    square_recognition,
    "Square-rectangle classification rejects orientation-bound and single-class identity.").

flat_strength_lift(area_over_length,
    area_scales_quadratically,
    "linear dimensions of region R are multiplied by k",
    "the area of R is multiplied by k squared",
    entitled,
    measurement_dimension,
    area_quantity,
    length_quantity,
    "Area rejects linear-unit and linear-scaling readings that length does not.").

flat_strength_lift(volume_over_area,
    volume_scales_cubically,
    "linear dimensions of solid S scale by factor k",
    "the volume of S scales by k^3",
    entitled,
    measurement_dimension,
    volume_quantity,
    area_quantity,
    "Volume rejects all area-level dimensional confusions plus surface and quadratic-volume confusions.").

flat_strength_lift(area_factor_over_length_factor,
    area_factor,
    "the linear dimensions of figure F are multiplied by k",
    "the area of F is multiplied by k^2",
    entitled,
    measurement_dimension,
    area_quantity,
    length_quantity,
    "Area-factor reasoning rejects linear-unit and linear-scaling readings that length-factor reasoning permits.").

flat_strength_lift(volume_factor_over_area_factor,
    volume_factor,
    "the linear dimensions of solid S are multiplied by k",
    "the volume of S is multiplied by k^3",
    entitled,
    measurement_dimension,
    volume_quantity,
    area_quantity,
    "Volume-factor reasoning rejects every area-factor dimensional confusion plus surface and quadratic-volume readings.").

flat_strength_lift(surface_context_over_boundary_context,
    length_area_volume_dimension_distinction,
    "the application is about covering a surface (paint, sod, fertilizer)",
    "the relevant quantity is area (2D)",
    entitled,
    measurement_dimension,
    area_quantity,
    length_quantity,
    "Surface-coverage contexts require area restrictions that are stronger than boundary-length contexts.").

flat_strength_lift(filling_context_over_surface_context,
    length_area_volume_dimension_distinction,
    "the application is about filling a space (water, popcorn, sand) or weight",
    "the relevant quantity is volume (3D)",
    entitled,
    measurement_dimension,
    volume_quantity,
    area_quantity,
    "Filling contexts require volume restrictions that include and exceed surface-coverage restrictions.").

flat_strength_lift(area_boundary_count_rejection,
    area_as_interior_coverage,
    "I counted the unit squares lying ON the boundary of R",
    "I have measured the area of R",
    incompatible,
    measurement_dimension,
    area_quantity,
    length_quantity,
    "Area rejects boundary-only counting; length-level reasoning does not yet rule that out.").

flat_strength_lift(area_linear_unit_rejection,
    area_unit_is_a_square,
    "the calculated area is N",
    "the units are linear (cm, m), not square (cm², m²)",
    incompatible,
    measurement_dimension,
    area_quantity,
    length_quantity,
    "Area rejects linear units; length quantities do not.").

flat_strength_lift(area_linear_scaling_rejection,
    area_scales_quadratically,
    "linear dimension is multiplied by k",
    "the area is multiplied by k (linearly)",
    incompatible,
    measurement_dimension,
    area_quantity,
    length_quantity,
    "Area rejects linear scaling; length quantities scale linearly.").

flat_strength_lift(volume_visible_faces_rejection,
    volume_as_filling_3d_space,
    "I have counted only the visible faces or external squares of a solid",
    "I have measured the volume of the solid",
    incompatible,
    measurement_dimension,
    volume_quantity,
    area_quantity,
    "Volume rejects surface-only measurement; area reasoning has not yet ruled out surface coverage.").

flat_strength_lift(volume_linear_or_area_scaling_rejection,
    volume_scales_cubically,
    "linear dimension is multiplied by k",
    "the volume is multiplied by k or k squared",
    incompatible,
    measurement_dimension,
    volume_quantity,
    area_quantity,
    "Volume rejects both linear and quadratic scaling readings; area only reaches the quadratic level.").

flat_strength_lift(slope_ratio_over_height_only,
    slope_as_ratio_of_change,
    "two points (x1,y1) and (x2,y2) lie on a non-vertical line",
    "the slope of the line is (y2-y1)/(x2-x1)",
    entitled,
    coordinate_slope_reasoning,
    slope_ratio_reasoning,
    height_only_slope_reading,
    "Rise-over-run reasoning rejects height-only and angle-only slope readings.").

flat_strength_lift(slope_ratio_rejects_run_irrelevance,
    slope_as_ratio_of_change,
    "the height (rise) of a ramp is greater",
    "the slope is greater regardless of the run",
    incompatible,
    coordinate_slope_reasoning,
    slope_ratio_reasoning,
    height_only_slope_reading,
    "Slope as a ratio rejects comparing ramps by rise while ignoring run.").

flat_strength_lift(slope_invariance_over_ratio,
    slope_invariant_along_a_line,
    "line L is straight",
    "the slope of L is the same between any pair of points on L",
    entitled,
    coordinate_slope_reasoning,
    line_slope_invariance,
    slope_ratio_reasoning,
    "Line-level invariance keeps the ratio restrictions and rejects local variation along a straight line.").

flat_strength_lift(slope_invariance_rejects_local_position,
    slope_invariant_along_a_line,
    "I am at a higher point on a straight ramp",
    "the local slope is steeper than at a lower point",
    incompatible,
    coordinate_slope_reasoning,
    line_slope_invariance,
    local_position_slope_reading,
    "Straight-line slope invariance rejects the higher-point-means-steeper reading.").

flat_strength_lift(parallel_slope_over_invariance,
    parallel_lines_equal_slope,
    "two non-vertical lines have the same slope",
    "the lines are parallel",
    entitled,
    coordinate_slope_reasoning,
    parallel_slope_relation,
    line_slope_invariance,
    "Parallel-line slope reasoning adds cross-line equality restrictions to line-level invariance.").

flat_strength_lift(perpendicular_slope_over_invariance,
    perpendicular_lines_negative_reciprocal_slopes,
    "two non-vertical lines have slopes m1 and m2 with m1 * m2 = -1",
    "the lines are perpendicular",
    entitled,
    coordinate_slope_reasoning,
    perpendicular_slope_relation,
    line_slope_invariance,
    "Perpendicular-line slope reasoning adds negative-reciprocal restrictions to line-level invariance.").

flat_strength_lift(pythagorean_side_equation,
    pythagorean_theorem,
    "triangle has legs of length a and b and hypotenuse of length c AND triangle is a right triangle",
    "a^2 + b^2 = c^2",
    entitled,
    pythagorean_reasoning,
    right_triangle_side_relation,
    formula_pattern_reading,
    "Right-triangle side reasoning rejects using the equation as an arbitrary formula pattern.").

flat_strength_lift(pythagorean_hypotenuse_application,
    pythagorean_theorem,
    "the longest side of a right triangle is identified as the hypotenuse",
    "the Pythagorean theorem applies as (leg1)² + (leg2)² = (hypotenuse)²",
    entitled,
    pythagorean_reasoning,
    hypotenuse_application,
    right_triangle_side_relation,
    "Hypotenuse application adds the longest-side/opposite-right-angle constraint to the side relation.").

flat_strength_lift(pythagorean_rejects_non_side_quantity,
    pythagorean_theorem,
    "I am computing area, perimeter, or volume of a right triangle",
    "the Pythagorean theorem provides the answer directly",
    incompatible,
    pythagorean_reasoning,
    right_triangle_side_relation,
    formula_pattern_reading,
    "The theorem concerns side lengths, not area, perimeter, or volume directly.").

flat_strength_lift(constructed_right_triangle_over_visible_right_angle,
    pythagorean_theorem,
    "the figure does not show an explicit right angle",
    "Pythagorean reasoning is unavailable in any subfigure",
    incompatible,
    pythagorean_reasoning,
    constructed_right_triangle_reasoning,
    right_triangle_side_relation,
    "Constructed-right-triangle reasoning rejects the demand that the right angle already be visible.").

flat_strength_lift(converse_pythagorean_equality_test,
    converse_of_pythagorean_theorem,
    "triangle has sides of length a, b, c (with c the largest) AND a^2 + b^2 = c^2",
    "the triangle is a right triangle",
    entitled,
    pythagorean_reasoning,
    converse_right_triangle_test,
    right_triangle_side_relation,
    "The converse adds classification power: the side equation is sufficient for rightness.").

flat_strength_lift(converse_pythagorean_inequality_test,
    converse_of_pythagorean_theorem,
    "triangle has sides of length a, b, c (with c the largest) AND a^2 + b^2 != c^2",
    "the triangle is NOT a right triangle",
    entitled,
    pythagorean_reasoning,
    converse_right_triangle_test,
    right_triangle_side_relation,
    "The converse also rejects classifying non-Pythagorean side triples as right triangles.").

flat_strength_lift(special_30_60_90_over_right_triangle,
    thirty_sixty_ninety_triangle,
    "triangle is a 30-60-90 right triangle with short leg of length s",
    "the hypotenuse has length 2s and the long leg has length s*sqrt(3)",
    entitled,
    pythagorean_reasoning,
    special_30_60_90_ratio,
    right_triangle_side_relation,
    "A 30-60-90 triangle adds angle-specific ratio restrictions beyond generic right-triangle side reasoning.").

flat_strength_lift(special_45_45_90_over_right_triangle,
    isosceles_right_triangle,
    "triangle is a 45-45-90 right triangle with leg of length s",
    "the hypotenuse has length s*sqrt(2)",
    entitled,
    pythagorean_reasoning,
    special_45_45_90_ratio,
    right_triangle_side_relation,
    "A 45-45-90 triangle adds equal-leg and square-diagonal restrictions beyond generic right-triangle side reasoning.").

flat_strength_lift(translation_pointwise_mapping,
    translation,
    "translation by vector v is applied to figure F",
    "every point P of F maps to P + v",
    entitled,
    transformation_reasoning,
    translation_vector_mapping,
    point_mapping_reading,
    "Translation-vector reasoning rejects anchor-locked or nonuniform point movement.").

flat_strength_lift(translation_anchor_lock_rejection,
    translation,
    "translation vector v has been drawn from point A to point B",
    "the pre-image is locked to point A and translates only when A moves",
    incompatible,
    transformation_reasoning,
    translation_vector_mapping,
    point_mapping_reading,
    "A translation vector applies uniformly; it is not locked to a particular anchor point.").

flat_strength_lift(whole_plane_translation_rejection,
    translation_acts_on_whole_plane,
    "translation T is applied",
    "T moves only the figure under consideration; the rest of the plane stays put",
    incompatible,
    transformation_reasoning,
    whole_plane_translation,
    translation_vector_mapping,
    "Whole-plane translation adds the global action constraint to pointwise vector mapping.").

flat_strength_lift(reflection_distance_over_correspondence,
    reflection_preserves_perpendicular_distance,
    "point P is reflected across line L",
    "the image P' lies on the perpendicular from P to L, on the opposite side, at equal distance",
    entitled,
    transformation_reasoning,
    reflection_distance_correspondence,
    reflection_correspondence,
    "Reflection-distance reasoning adds perpendicularity, opposite-side, and equal-distance restrictions.").

flat_strength_lift(reflection_orientation_rejection,
    reflection,
    "reflection across line L sends figure F to figure F'",
    "F' must have the same axis-orientation as F (horizontals stay horizontal, verticals stay vertical)",
    incompatible,
    transformation_reasoning,
    reflection_correspondence,
    point_mapping_reading,
    "Reflection correspondence rejects the same-axis-orientation reading.").

flat_strength_lift(line_symmetry_congruent_halves_rejection,
    line_of_symmetry,
    "line L splits figure F into two congruent parts",
    "L is a line of symmetry of F",
    incompatible,
    transformation_reasoning,
    line_symmetry_reflection_test,
    congruent_halves_reading,
    "Line symmetry requires a reflection mapping, not merely two congruent parts.").

flat_strength_lift(reflection_rotation_distinction,
    reflection_distinct_from_rotation,
    "two figures can be made to coincide by flipping one out of the plane",
    "the two figures are related by a 2D rotation",
    incompatible,
    transformation_reasoning,
    plane_reflection_distinction,
    point_mapping_reading,
    "Plane-transformation reasoning rejects treating an out-of-plane flip as a 2D rotation.").

flat_strength_lift(point_image_rotation_center_diagnostic,
    point_image_segment,
    "two figures are related by a rotation AND point-image segments are drawn for several point pairs",
    "the perpendicular bisectors of those segments are concurrent at the center of rotation",
    entitled,
    transformation_reasoning,
    rotation_center_diagnostic,
    point_image_segment_pairing,
    "Rotation diagnostics add perpendicular-bisector concurrence to point-image segment pairing.").

flat_strength_lift(point_image_glide_line_diagnostic,
    point_image_segment,
    "two figures are related by a glide-reflection AND point-image segments are drawn",
    "the midpoints of those segments are collinear and lie on the glide-reflection line",
    entitled,
    transformation_reasoning,
    glide_reflection_line_diagnostic,
    point_image_segment_pairing,
    "Glide-reflection diagnostics add midpoint collinearity to point-image segment pairing.").

flat_strength_lift(parallel_reflections_compose_translation,
    combination_of_two_reflections,
    "figure F is reflected over parallel lines L1 then L2 separated by distance d",
    "the result is a translation of F by 2d perpendicular to the lines",
    entitled,
    transformation_reasoning,
    parallel_reflections_translation,
    reflection_composition_reading,
    "Parallel-reflection composition rejects non-translation and non-doubled-distance readings.").

flat_strength_lift(intersecting_reflections_compose_rotation,
    combination_of_two_reflections,
    "figure F is reflected over intersecting lines L1 then L2 meeting at angle theta",
    "the result is a rotation of F by 2*theta about the intersection point",
    entitled,
    transformation_reasoning,
    intersecting_reflections_rotation,
    reflection_composition_reading,
    "Intersecting-reflection composition rejects non-rotation and non-doubled-angle readings.").

flat_strength_lift(angle_requires_two_rays,
    angle_as_two_rays_from_vertex,
    "I have only one ray drawn",
    "I have specified an angle",
    incompatible,
    angle_reasoning,
    ray_pair_angle_structure,
    one_ray_angle_reading,
    "Angle structure rejects the one-ray reading.").

flat_strength_lift(angle_measure_congruence_invariance,
    angle_measure_invariant_under_arm_length,
    "two angles share the same measure",
    "the angles are congruent regardless of arm length differences",
    entitled,
    angle_reasoning,
    arm_length_angle_measure_invariance,
    ray_pair_angle_structure,
    "Angle-measure invariance adds the rejection of arm-length based congruence judgments.").

flat_strength_lift(angle_measure_rejects_longer_arms,
    angle_measure_invariant_under_arm_length,
    "angle A has longer drawn arms than angle B",
    "angle A has greater measure than angle B",
    incompatible,
    angle_reasoning,
    arm_length_angle_measure_invariance,
    ray_pair_angle_structure,
    "Angle measure rejects the longer-arms-means-larger-angle reading.").

flat_strength_lift(corresponding_angles_require_parallel_lines,
    corresponding_angles,
    "two lines are cut by a transversal and the cut lines are not parallel",
    "the corresponding angles are equal in measure",
    incompatible,
    angle_reasoning,
    parallel_transversal_angle_relation,
    arm_length_angle_measure_invariance,
    "Corresponding-angle reasoning adds the parallel-line condition to angle-measure invariance.").

flat_strength_lift(triangle_sum_rejects_size_dependence,
    triangle_angle_sum_180,
    "triangle T is larger than triangle S",
    "the interior angle sum of T is greater than that of S",
    incompatible,
    angle_reasoning,
    triangle_angle_sum_theorem,
    arm_length_angle_measure_invariance,
    "Triangle angle-sum reasoning rejects size-dependent angle sums.").

flat_strength_lift(triangle_sum_conjecture_to_theorem,
    triangle_angle_sum_arc,
    "student moves from inductive trials (cut-and-arrange, measurement of many triangles) to a deductive argument from parallel-line theorems",
    "student has crossed the conjecture-to-theorem transition; both source concepts now describe the student's situation correctly at their respective levels",
    entitled,
    angle_reasoning,
    triangle_angle_sum_theorem,
    inductive_triangle_sum_conjecture,
    "The theorem-level stance rejects treating repeated measured examples as proof.").

flat_strength_lift(polygon_sum_over_triangle_sum,
    polygon_angle_sum_via_triangulation,
    "polygon P has n sides AND P is fan-triangulated from one vertex",
    "P is divided into (n-2) triangles AND the angle sum of P is (n-2)*180",
    entitled,
    angle_reasoning,
    polygon_angle_sum_triangulation,
    triangle_angle_sum_theorem,
    "Polygon angle-sum reasoning adds fan-triangulation and n-minus-2 restrictions to the triangle angle-sum theorem.").

flat_strength_lift(similarity_full_criterion_over_visual,
    similar_figures,
    "two figures have all corresponding angles equal AND all corresponding sides proportional",
    "the figures are similar",
    entitled,
    similarity_reasoning,
    mathematical_similarity_criterion,
    visual_shape_similarity_reading,
    "Mathematical similarity rejects visual resemblance without angle and side-ratio checks.").

flat_strength_lift(similarity_rejects_visual_only,
    similar_figures,
    "two figures have visually similar shapes (look alike)",
    "the figures are similar in the mathematical sense",
    incompatible,
    similarity_reasoning,
    mathematical_similarity_criterion,
    visual_shape_similarity_reading,
    "Similarity requires corresponding angle equality and side proportionality, not appearance alone.").

flat_strength_lift(similarity_rejects_additive_side_growth,
    similar_figures,
    "you obtain figure F2 by adding a constant to each side of F1",
    "F1 and F2 are similar",
    incompatible,
    similarity_reasoning,
    mathematical_similarity_criterion,
    side_change_similarity_reading,
    "Similarity rejects additive side changes because ratios, not differences, preserve shape.").

flat_strength_lift(similarity_preserves_angles_under_scaling,
    similar_figures,
    "two triangles A and B are similar with side scale factor k",
    "the corresponding angles of A are k times the corresponding angles of B",
    incompatible,
    similarity_reasoning,
    triangle_similarity_angle_preservation,
    mathematical_similarity_criterion,
    "Triangle similarity adds explicit angle-preservation under scaling.").

flat_strength_lift(property_classification_over_visual,
    shape_identified_by_properties_not_appearance,
    "shape S satisfies the property test for category C in any orientation",
    "S is in category C",
    entitled,
    definition_reasoning,
    property_based_classification,
    visual_category_reading,
    "Property-based classification rejects prototype and orientation-bound category judgments.").

flat_strength_lift(property_classification_rejects_orientation,
    shape_identified_by_properties_not_appearance,
    "shape S is shown in a non-prototypical orientation",
    "S is not in its category",
    incompatible,
    definition_reasoning,
    property_based_classification,
    visual_category_reading,
    "A non-prototypical orientation does not cancel a satisfied category property test.").

flat_strength_lift(formal_object_over_physical_drawing,
    formal_vs_physical_geometric_object,
    "the geometric object I drew has measurable thickness",
    "the geometric object itself has thickness in its mathematical definition",
    incompatible,
    definition_reasoning,
    formal_object_definition,
    physical_drawing_reading,
    "Formal-object reasoning rejects importing physical drawing thickness into the mathematical object.").

flat_strength_lift(circle_definition_rejects_roundness_only,
    circle_definition,
    "the curve is round and has no straight pieces",
    "the curve is a circle",
    incompatible,
    definition_reasoning,
    necessary_sufficient_definition,
    definition_candidate_reading,
    "A circle definition needs necessary and sufficient structure, not roundness alone.").

flat_strength_lift(triangle_definition_over_visual_category,
    triangle_definition,
    "the figure has three straight sides and is closed",
    "the figure is a triangle",
    entitled,
    definition_reasoning,
    triangle_definition_closure,
    visual_category_reading,
    "Triangle definition adds closedness and straight-sidedness to category recognition.").

flat_strength_lift(definition_requires_biconditional,
    definition_requires_necessary_and_sufficient_conditions,
    "every example of category C satisfies condition D AND every shape satisfying D is in C",
    "D is a valid definition of C",
    entitled,
    definition_reasoning,
    necessary_sufficient_definition,
    definition_candidate_reading,
    "Definition validation rejects merely necessary or merely sufficient conditions.").

flat_strength_lift(definition_rejects_empirical_examples,
    definition_requires_necessary_and_sufficient_conditions,
    "I checked a few examples and the property held",
    "the property holds in general",
    incompatible,
    definition_reasoning,
    necessary_sufficient_definition,
    empirical_generalization_reading,
    "Necessary-and-sufficient definition work rejects empirical examples as proof of a universal claim.").

flat_strength_lift(equivalent_definitions_over_biconditional,
    equivalent_definitions,
    "Two definitions D1 and D2 admit exactly the same set of shapes",
    "D1 and D2 are equivalent definitions",
    entitled,
    definition_reasoning,
    equivalent_definition_extension,
    necessary_sufficient_definition,
    "Equivalent definitions add extension equality to necessary-and-sufficient definition reasoning.").

flat_strength_lift(area_coverage_formula,
    area_as_interior_coverage,
    "region R has been completely covered by N unit squares, no gaps, no overlaps",
    "the area of R is N square units",
    entitled,
    measurement_formula_reasoning,
    area_interior_coverage_formula,
    area_counting_reading,
    "Area coverage rejects gaps, overlaps, and boundary-only counting.").

flat_strength_lift(rectangle_perimeter_formula,
    perimeter_as_boundary_traversal,
    "rectangle has length L and width W",
    "the perimeter is 2(L+W) linear units",
    entitled,
    measurement_formula_reasoning,
    rectangle_perimeter_formula,
    rectangle_boundary_reading,
    "Rectangle perimeter formula rejects counting only one length-width pair.").

flat_strength_lift(rectangle_area_array_formula,
    area_as_array_structure,
    "rectangle has length L and width W",
    "the area is L*W square units",
    entitled,
    measurement_formula_reasoning,
    area_array_formula,
    area_interior_coverage_formula,
    "Rectangle area as L*W adds row-column array structure to interior coverage.").

flat_strength_lift(rectangle_perimeter_rejects_single_pair,
    perimeter_as_boundary_traversal,
    "I added the length and the width once",
    "I have measured the perimeter of the rectangle",
    incompatible,
    measurement_formula_reasoning,
    rectangle_perimeter_formula,
    rectangle_boundary_reading,
    "Perimeter traversal rejects measuring only one length-width pair.").

flat_strength_lift(area_perimeter_independence_rejection,
    area_perimeter_independence,
    "shape A has greater area than shape B",
    "shape A has greater perimeter than shape B",
    incompatible,
    measurement_formula_reasoning,
    area_perimeter_independence_reasoning,
    area_interior_coverage_formula,
    "Area-perimeter independence rejects ordering perimeter directly from area.").

flat_strength_lift(area_conservation_rejects_noncongruence,
    area_conservation_under_transformation,
    "two regions are non-congruent",
    "the two regions cannot have equal area",
    incompatible,
    measurement_formula_reasoning,
    area_conservation_invariant,
    area_interior_coverage_formula,
    "Area conservation rejects treating non-congruence as enough to preclude equal area.").

flat_strength_lift(pick_formula_lattice_area,
    picks_formula,
    "lattice polygon P is simple (non-self-intersecting) AND has I interior pegs and E edge pegs",
    "the area of P equals I + E/2 - 1",
    entitled,
    measurement_formula_reasoning,
    pick_lattice_area_formula,
    area_interior_coverage_formula,
    "Pick's formula adds simple-lattice boundary/interior peg restrictions to area coverage.").

flat_strength_lift(pick_formula_rejects_non_simple_figures,
    picks_formula,
    "the figure is made with multiple rubber bands OR the rubber band crosses itself",
    "Pick's formula gives the area",
    incompatible,
    measurement_formula_reasoning,
    pick_lattice_area_formula,
    area_interior_coverage_formula,
    "Pick's formula rejects self-intersecting or multiple-band figures.").

flat_strength_lift(prism_volume_over_area_array,
    volume_of_prism_formula,
    "prism has base of area B and height h",
    "the volume is B * h cubic units",
    entitled,
    measurement_formula_reasoning,
    prism_stack_volume_formula,
    area_array_formula,
    "Prism volume adds layered base-area-by-height and cubic-unit restrictions to area-array reasoning.").

flat_strength_lift(pyramid_volume_over_prism_stack,
    volume_of_pyramid_formula,
    "pyramid has base of area B and height h",
    "the volume is (1/3) * B * h cubic units",
    entitled,
    measurement_formula_reasoning,
    pyramid_volume_formula,
    prism_stack_volume_formula,
    "Pyramid volume adds the one-third factor to prism-style base-area-by-height reasoning.").

flat_strength_lift(euler_polyhedron_invariant,
    eulers_polyhedron_formula,
    "polyhedron P is convex AND has F faces, V vertices, E edges",
    "F + V - E = 2",
    entitled,
    measurement_formula_reasoning,
    euler_polyhedron_invariant,
    polyhedron_counting_reading,
    "Euler's formula adds convex-polyhedron and F+V-E invariant restrictions to face/vertex/edge counting.").

flat_strength_lift(equal_sides_do_not_force_equal_angles,
    equal_sides_does_not_imply_equal_angles,
    "polygon P has more than 3 sides AND all sides of P are equal",
    "all angles of P are equal",
    incompatible,
    attribute_spatial_reasoning,
    regular_polygon_angle_reasoning,
    side_only_polygon_reading,
    "Regularity reasoning rejects inferring equal angles from equal sides alone in polygons with more than three sides.").

flat_strength_lift(parallelism_rejects_equal_length_only,
    parallelism_as_constant_distance,
    "two segments have equal length",
    "the segments are parallel",
    incompatible,
    attribute_spatial_reasoning,
    parallel_relation_reasoning,
    length_equality_parallel_reading,
    "Parallelism rejects treating equal length as a parallel-line condition.").

flat_strength_lift(perpendicularity_rejects_visual_only,
    perpendicularity_as_right_angle,
    "two lines look perpendicular in the diagram",
    "the two lines are perpendicular",
    incompatible,
    attribute_spatial_reasoning,
    perpendicular_right_angle_relation,
    visual_perpendicular_reading,
    "Perpendicularity requires a right-angle relation, not diagram appearance alone.").

flat_strength_lift(oblique_3d_axis_rejection,
    coordinate_axes_3d_orthogonal,
    "the third axis on a 2D drawing of a 3D system is drawn obliquely",
    "the third axis represents the negative direction of one of the other two axes",
    incompatible,
    attribute_spatial_reasoning,
    orthogonal_3d_axis_reasoning,
    oblique_axis_drawing_reading,
    "3D coordinate-axis reasoning rejects reading oblique projection as a negative 2D direction.").

flat_strength_lift(base_orientation_rejection,
    base_is_geometric_property_not_orientation,
    "the solid is reoriented so that a different face touches the ground",
    "the base of the solid changes",
    incompatible,
    attribute_spatial_reasoning,
    structural_base_reasoning,
    bottom_face_base_reading,
    "A solid's base is structural, not whichever face is visually at the bottom.").

flat_strength_lift(convexity_reflex_angle_test,
    convex_polygon_n103,
    "polygon P has at least one reflex angle (greater than 180 degrees)",
    "P is non-convex",
    entitled,
    attribute_spatial_reasoning,
    convexity_reflex_angle_test,
    polygon_shape_reading,
    "The reflex-angle convexity test rejects ignoring reflex angles.").

flat_strength_lift(convexity_line_segment_test,
    convex_polygon_n103,
    "every line segment with endpoints inside P lies entirely inside P",
    "P is convex",
    entitled,
    attribute_spatial_reasoning,
    convexity_line_segment_test,
    polygon_shape_reading,
    "The line-segment convexity test rejects judging convexity without the interior-segment condition.").

validated_strength_lift(Id,
    lift(Id, SourceConcept, Premise, Conclusion, Polarity, Domain, Stronger, Weaker, SourceNote, StrengthInference)) :-
    validated_strength_lift_witness(Id,
                                    lift(Id,
                                         SourceConcept,
                                         Premise,
                                         Conclusion,
                                         Polarity,
                                         Domain,
                                         Stronger,
                                         Weaker,
                                         SourceNote,
                                         StrengthInference),
                                    _).

validated_strength_lift_witness(Id,
    lift(Id, SourceConcept, Premise, Conclusion, Polarity, Domain, Stronger, Weaker, SourceNote, StrengthInference),
    _{ kind: validated_strength_lift,
       scope: closed_world_finite_material_strength_table,
       id: Id,
       source_concept: SourceConcept,
       premise: Premise,
       conclusion: Conclusion,
       polarity: Polarity,
       domain: Domain,
       stronger: Stronger,
       weaker: Weaker,
       source_note: SourceNote,
       source_material_inference_witness: SourceWitness,
       strength_inference_witness: StrengthWitness }) :-
    flat_strength_lift(Id, SourceConcept, Premise, Conclusion, Polarity, Domain, Stronger, Weaker, SourceNote),
    source_material_inference_witness(SourceConcept, Premise, Conclusion, Polarity, SourceWitness),
    strength_inference_witness(Domain, Stronger, Weaker, StrengthInference, StrengthWitness).

source_material_inference_witness(SourceConcept,
                                  Premise,
                                  Conclusion,
                                  Polarity,
                                  _{ kind: source_material_inference,
                                     scope: closed_world_finite_geometry_kb,
                                     source_concept: SourceConcept,
                                     premise: Premise,
                                     conclusion: Conclusion,
                                     polarity: Polarity,
                                     fact: material_inference(SourceConcept,
                                                              Premise,
                                                              Conclusion,
                                                              Polarity) }) :-
    material_inference(SourceConcept, Premise, Conclusion, Polarity).

strength_lift_examples(Examples) :-
    findall(Example, validated_strength_lift_witness(_, Example, _), Examples).

% ── SWI-Prolog report/check helpers ────────────────────────────────

strength_domains(Domains) :-
    setof(Domain, Term^strength_term(Domain, Term), Domains),
    !.
strength_domains([]).

strength_terms(Domain, Terms) :-
    setof(Term, strength_term(Domain, Term), Terms),
    !.
strength_terms(_, []).

known_strength_restriction(quadrilateral_class, Restriction) :-
    quad_restriction(Restriction, _),
    !.
known_strength_restriction(Domain, Restriction) :-
    strength_restriction(Domain, Restriction, _).

strength_order_edge(Domain,
    edge(Stronger, Weaker, strength(StrongerStrength, WeakerStrength), extra_rejections(Extra))) :-
    stronger_than(Domain, Stronger, Weaker),
    strength_value(Domain, Stronger, StrongerStrength),
    strength_value(Domain, Weaker, WeakerStrength),
    findall(R,
            ( strength_rejects(Domain, Stronger, R),
              \+ strength_rejects(Domain, Weaker, R)
            ),
            RawExtra),
    sort(RawExtra, Extra).

strength_domain_report(Domain,
    domain(Domain, terms(TermProfiles), order(OrderEdges))) :-
    strength_terms(Domain, Terms),
    findall(Profile,
            ( member(Term, Terms),
              strength_profile(Domain, Term, Profile)
            ),
            TermProfiles),
    findall(Edge, strength_order_edge(Domain, Edge), RawEdges),
    sort(RawEdges, OrderEdges).

strength_report(report(domains(DomainReports), lifts(total(Total), valid(Valid)), errors(Errors))) :-
    strength_domains(Domains),
    findall(DomainReport,
            ( member(Domain, Domains),
              strength_domain_report(Domain, DomainReport)
            ),
            DomainReports),
    aggregate_all(count, flat_strength_lift(_, _, _, _, _, _, _, _, _), Total),
    aggregate_all(count, validated_strength_lift(_, _), Valid),
    strength_consistency_errors(Errors).

strength_consistency_errors(Errors) :-
    findall(Error, strength_consistency_error(Error), Raw),
    sort(Raw, Errors).

strength_consistency_error(missing_source_material_inference(Id, SourceConcept, Premise, Conclusion, Polarity)) :-
    flat_strength_lift(Id, SourceConcept, Premise, Conclusion, Polarity, _, _, _, _),
    \+ material_inference(SourceConcept, Premise, Conclusion, Polarity).

strength_consistency_error(invalid_lift_order(Id, Domain, Stronger, Weaker)) :-
    flat_strength_lift(Id, _, _, _, _, Domain, Stronger, Weaker, _),
    \+ stronger_than(Domain, Stronger, Weaker).

strength_consistency_error(unknown_restriction(Domain, Term, Restriction)) :-
    strength_rejects(Domain, Term, Restriction),
    \+ known_strength_restriction(Domain, Restriction).

strength_consistency_error(strength_cycle(Domain, A, B)) :-
    stronger_than(Domain, A, B),
    stronger_than(Domain, B, A).

explicit_strength_lift_covers_witness(SourceConcept,
                                      Premise,
                                      Conclusion,
                                      Polarity,
                                      _{ kind: explicit_strength_lift_cover,
                                         scope: closed_world_finite_material_strength_table,
                                         source_concept: SourceConcept,
                                         premise: Premise,
                                         conclusion: Conclusion,
                                         polarity: Polarity,
                                         lift_id: Id,
                                         lift_witness: LiftWitness }) :-
    validated_strength_lift_witness(Id,
                                    lift(Id,
                                         SourceConcept,
                                         Premise,
                                         Conclusion,
                                         Polarity,
                                         _Domain,
                                         _Stronger,
                                         _Weaker,
                                         _SourceNote,
                                         _StrengthInference),
                                    LiftWitness).

structural_strength_lift_covers_witness(quadrilateral_hierarchy,
                                        shape(_, Stronger),
                                        shape(_, Weaker),
                                        entitled,
                                        _{ kind: structural_strength_lift_cover,
                                           scope: closed_world_finite_material_strength_table,
                                           source_concept: quadrilateral_hierarchy,
                                           premise: shape(_, Stronger),
                                           conclusion: shape(_, Weaker),
                                           polarity: entitled,
                                           source: quadrilateral_restriction_table,
                                           strength_inference_witness: StrengthWitness }) :-
    strength_inference_witness(quadrilateral_class,
                               Stronger,
                               Weaker,
                               _StrengthInference,
                               StrengthWitness).
structural_strength_lift_covers_witness(quadrilateral_hierarchy,
                                        shape(_, Stronger),
                                        neg(shape(_, Weaker)),
                                        incompatible,
                                        _{ kind: structural_strength_lift_cover,
                                           scope: closed_world_finite_material_strength_table,
                                           source_concept: quadrilateral_hierarchy,
                                           premise: shape(_, Stronger),
                                           conclusion: neg(shape(_, Weaker)),
                                           polarity: incompatible,
                                           source: quadrilateral_restriction_table,
                                           strength_inference_witness: StrengthWitness }) :-
    strength_inference_witness(quadrilateral_class,
                               Stronger,
                               Weaker,
                               _StrengthInference,
                               StrengthWitness).
structural_strength_lift_covers_witness(quadrilateral_incompatibility,
                                        shape(_, Shape),
                                        restriction(_, Restriction),
                                        incompatible,
                                        _{ kind: structural_strength_lift_cover,
                                           scope: closed_world_finite_material_strength_table,
                                           source_concept: quadrilateral_incompatibility,
                                           premise: shape(_, Shape),
                                           conclusion: restriction(_, Restriction),
                                           polarity: incompatible,
                                           source: quadrilateral_restriction_table,
                                           rejected_restriction_witness: RestrictionWitness }) :-
    strength_rejects(quadrilateral_class, Shape, Restriction),
    RestrictionWitness = _{ kind: structural_quadrilateral_restriction,
                            shape: Shape,
                            restriction: Restriction,
                            fact: strength_rejects(quadrilateral_class,
                                                   Shape,
                                                   Restriction) }.

strength_lift_covers(SourceConcept, Premise, Conclusion, Polarity) :-
    strength_lift_covers_witness(SourceConcept, Premise, Conclusion, Polarity, _).

strength_lift_covers_witness(SourceConcept, Premise, Conclusion, Polarity, Witness) :-
    explicit_strength_lift_covers_witness(SourceConcept, Premise, Conclusion, Polarity, Witness).
strength_lift_covers_witness(SourceConcept, Premise, Conclusion, Polarity, Witness) :-
    structural_strength_lift_covers_witness(SourceConcept, Premise, Conclusion, Polarity, Witness).

strength_lift_coverage(coverage(material_inferences(TotalFacts), flat_lifts(FlatLifts), valid_lifts(ValidLifts), structural_lifts(StructuralLifts), unlifted(UnliftedFacts))) :-
    strength_lift_coverage_witness(
        coverage(material_inferences(TotalFacts),
                 flat_lifts(FlatLifts),
                 valid_lifts(ValidLifts),
                 structural_lifts(StructuralLifts),
                 unlifted(UnliftedFacts)),
        _).

strength_lift_coverage_witness(
    coverage(material_inferences(TotalFacts), flat_lifts(FlatLifts), valid_lifts(ValidLifts), structural_lifts(StructuralLifts), unlifted(UnliftedFacts)),
    _{ kind: strength_lift_coverage,
       scope: closed_world_finite_material_strength_table,
       counts: _{ total_material_inferences: TotalFacts,
                  flat_lifts: FlatLifts,
                  valid_lifts: ValidLifts,
                  structural_lifts: StructuralLifts,
                  unlifted_material_inferences: UnliftedFacts },
       valid_lift_witnesses: ValidLiftWitnesses,
       structural_lift_witnesses: StructuralLiftWitnesses,
       unlifted_witnesses: UnliftedWitnesses }) :-
    findall(material_inference(Concept, Premise, Conclusion, Polarity),
            ( material_inference(Concept, Premise, Conclusion, Polarity),
              Concept \== material_strength_lift
            ),
            MaterialFacts),
    length(MaterialFacts, TotalFacts),
    findall(Id, flat_strength_lift(Id, _, _, _, _, _, _, _, _), FlatIds),
    length(FlatIds, FlatLifts),
    findall(Witness,
            validated_strength_lift_witness(_Id, _Lift, Witness),
            ValidLiftWitnesses),
    length(ValidLiftWitnesses, ValidLifts),
    findall(Witness,
            ( material_inference(Concept, Premise, Conclusion, Polarity),
              structural_strength_lift_covers_witness(Concept,
                                                      Premise,
                                                      Conclusion,
                                                      Polarity,
                                                      Witness)
            ),
            StructuralLiftWitnesses),
    length(StructuralLiftWitnesses, StructuralLifts),
    findall(Witness,
            ( member(material_inference(Concept, Premise, Conclusion, Polarity), MaterialFacts),
              \+ strength_lift_covers_witness(Concept, Premise, Conclusion, Polarity, _),
              Witness = _{ kind: unlifted_material_inference,
                           scope: closed_world_finite_material_strength_table,
                           source_concept: Concept,
                           premise: Premise,
                           conclusion: Conclusion,
                           polarity: Polarity,
                           fact: material_inference(Concept,
                                                    Premise,
                                                    Conclusion,
                                                    Polarity) }
            ),
            UnliftedWitnesses),
    length(UnliftedWitnesses, UnliftedFacts).

strength_gap_summary(Summary) :-
    findall(SourceConcept,
            ( material_inference(SourceConcept, Premise, Conclusion, Polarity),
              SourceConcept \== material_strength_lift,
              \+ strength_lift_covers(SourceConcept, Premise, Conclusion, Polarity)
            ),
            RawConcepts),
    sort(RawConcepts, Concepts),
    findall(SourceConcept-Count,
            ( member(SourceConcept, Concepts),
              aggregate_all(count,
                  ( material_inference(SourceConcept, Premise, Conclusion, Polarity),
                    \+ strength_lift_covers(SourceConcept, Premise, Conclusion, Polarity)
                  ),
                  Count)
            ),
            Summary).

% Make the lifted hierarchy visible to generic material_inference/4 consumers.
material_inference(material_strength_lift,
    term(Domain, Stronger),
    term(Domain, Weaker),
    entitled) :-
    stronger_than(Domain, Stronger, Weaker).
