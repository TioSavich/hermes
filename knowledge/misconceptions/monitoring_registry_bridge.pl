/** <module> Monitoring-name to misconception-registry bridge
 *
 * The geometry monitoring lane and the misconception registry are two authored
 * vocabularies for some of the same mathematical doings.  Neither vocabulary
 * is renamed here.  This table records a relation between them so a later
 * lesson consumer can preserve both names and reach the registry operation.
 * No current lesson predicate loads this module.
 *
 * A row requires two witnesses.  identification_witness/4 names a live
 * registry entry whose source states the same doing as the monitoring name.
 * render_witness/4 names the existing register exemplar, a denoting spec, and
 * the scene compiler that draws it.  The row is admitted only when most entries
 * under the registry operation concern the object that exemplar draws, which is
 * the curation rule used for the render-coverage register.
 *
 * The additional identification requirement is stricter than task 226's
 * object-level projection.  In particular, right_triangle_without_longest_side
 * stays out: its exact registry operation is right_triangles, while the live
 * triangles entries do not state the hypotenuse error.  The decline facts below
 * keep that and every other refusal beside the admitted rows.
 */

:- module(monitoring_registry_bridge,
          [ monitoring_registry_bridge/4,
            monitoring_registry_bridge_declined/2
          ]).

% monitoring_registry_bridge(
%     MonitoringName,
%     RegistryOperation,
%     identification_witness(RegistryName, DbRow, BibtexKey, SharedDoing),
%     render_witness(Representation, ExemplarTask, DenotingSpec, Compiler)).

monitoring_registry_bridge(
    angle_size_by_arm_length,
    angles,
    identification_witness(batch_row_39105, db_row(39105),
                           'ESM_Fischbein_1999_Intuitions',
                           angle_judged_by_drawn_arm_length),
    render_witness(angle_circular, angle_measure(45), angle(45),
                   angle_circular_render_json)).

monitoring_registry_bridge(
    area_counted_as_perimeter,
    area,
    identification_witness(area_as_perimeter_count, db_row(37528),
                           'JRME_Cai_1995_Cognitive',
                           boundary_units_substituted_for_interior_area_units),
    render_witness(polyform_tiling, area_by_tiling(region(4, 3), 4*3),
                   tile_area(cols(4), rows(3)),
                   polyform_tiling_render_json)).

%  area_formula_inverted was admitted in the first pass on db_row(37528) and
%  the review removed it: that row's source states a counting act — boundary
%  units counted in place of interior units — which is the doing its sibling
%  area_counted_as_perimeter already carries. The monitoring lane's own
%  definition here is a formula act, 2(L+W) written in place of L*W, and no
%  registry source states that act: 37565 is the walls definitional
%  confusion, 40362 a generic area-perimeter conflation, 39621 the perimeter
%  formula's own inversion. A witness borrowed across two named-distinct
%  doings fails this table's standard, so the name moves to the declines.
%  Its lesson set (15 K-5 lessons) stays reachable through
%  tiling_with_gaps_or_overlaps and triangle_area_no_halving, so no measured
%  number moves.

monitoring_registry_bridge(
    axis_variable_reversal,
    distance_time_graphs,
    identification_witness(batch_row_38154, db_row(38154),
                           'ZDM_Moschkovich_2018_Using',
                           distance_and_time_axes_reversed),
    render_witness(coordinate_plane, linear_graph(2, 0), plot_line(2, 0),
                   coordinate_plane_render_json)).

monitoring_registry_bridge(
    compensating_dimensions_preserve_perimeter,
    perimeter,
    identification_witness(same_change_same_perimeter, db_row(38063),
                           'ZDM_Dooren_2015_Inhibitory',
                           reciprocal_dimension_changes_assumed_to_preserve_perimeter),
    render_witness(geoboard, geoboard_polygon([0-0, 3-0, 0-4]),
                   stretch_polygon([0-0, 3-0, 0-4]), geoboard_render_json)).

monitoring_registry_bridge(
    diagonal_grid_segment_unit,
    perimeter,
    identification_witness(diagonal_as_unit, db_row(38694),
                           'JMB_Clarke_2018_Using',
                           grid_diagonal_counted_as_one_linear_unit),
    render_witness(geoboard, geoboard_polygon([0-0, 3-0, 0-4]),
                   stretch_polygon([0-0, 3-0, 0-4]), geoboard_render_json)).

monitoring_registry_bridge(
    line_not_its_own_symmetry_axis,
    line_symmetry,
    identification_witness(batch_row_39628, db_row(39628),
                           'MERJ_Leikin_2000_Learning',
                           line_not_recognized_as_its_own_symmetry_axis),
    render_witness(rigid_motion,
                   isometry_image([0-0, 3-0, 0-2], reflection(y)),
                   reflect([0-0, 3-0, 0-2], mirror_y),
                   rigid_motion_render_json)).

monitoring_registry_bridge(
    perimeter_formula_inverted,
    area_and_perimeter,
    identification_witness(area_as_perimeter, db_row(39621),
                           'MERJ_Sullivan_1992_Problem',
                           area_value_substituted_for_perimeter),
    render_witness(geoboard, geoboard_polygon([0-0, 4-0, 4-3, 0-3]),
                   stretch_polygon([0-0, 4-0, 4-3, 0-3]),
                   geoboard_render_json)).

monitoring_registry_bridge(
    perimeter_incomplete_traversal,
    perimeter,
    identification_witness(perimeter_two_sides_only, db_row(40254),
                           'JMTE_Steele_2001_Interfacing',
                           only_length_and_width_added_for_perimeter),
    render_witness(geoboard, geoboard_polygon([0-0, 3-0, 0-4]),
                   stretch_polygon([0-0, 3-0, 0-4]), geoboard_render_json)).

monitoring_registry_bridge(
    ribbon_uses_volume_or_faces,
    perimeter,
    identification_witness(too_vague, db_row(40443),
                           'IJSME_Almeida_2016_Strategies',
                           ribbon_amount_related_to_faces_or_volume_instead_of_boundary_length),
    render_witness(geoboard, geoboard_polygon([0-0, 3-0, 0-4]),
                   stretch_polygon([0-0, 3-0, 0-4]), geoboard_render_json)).

monitoring_registry_bridge(
    shape_refused_in_nonstandard_orientation,
    triangles,
    identification_witness(batch_row_38891, db_row(38891),
                           'ESM_Bishop_nodate_What',
                           valid_triangle_refused_due_to_orientation),
    render_witness(geoboard, geoboard_polygon([1-0, 4-1, 2-3]),
                   stretch_polygon([1-0, 4-1, 2-3]), geoboard_render_json)).

monitoring_registry_bridge(
    symmetry_axis_over_split,
    line_symmetry,
    identification_witness(batch_row_39626, db_row(39626),
                           'MERJ_Leikin_2000_Learning',
                           equal_split_treated_as_reflective_symmetry),
    render_witness(rigid_motion,
                   isometry_image([0-0, 3-0, 0-2], reflection(y)),
                   reflect([0-0, 3-0, 0-2], mirror_y),
                   rigid_motion_render_json)).

monitoring_registry_bridge(
    tiling_with_gaps_or_overlaps,
    area_measurement,
    identification_witness(too_vague, db_row(38676),
                           'JMB_Clements_2018_Evaluation',
                           area_cover_drawn_with_gaps_or_overlaps),
    render_witness(polyform_tiling, area_by_tiling(region(4, 3), 4*3),
                   tile_area(cols(4), rows(3)),
                   polyform_tiling_render_json)).

monitoring_registry_bridge(
    triangle_area_no_halving,
    area,
    identification_witness(triangle_area_no_half, db_row(40261),
                           'JMTE_Inoue_2011_Zen',
                           triangle_area_computed_as_base_times_height),
    render_witness(polyform_tiling, area_by_tiling(region(4, 3), 4*3),
                   tile_area(cols(4), rows(3)),
                   polyform_tiling_render_json)).

monitoring_registry_bridge(
    volume_by_counting_visible_faces,
    volume,
    identification_witness(face_count_for_volume, db_row(39524),
                           'ESM_Stacey_2001_Effect_a',
                           visible_exterior_faces_counted_as_volume),
    render_witness(solid_net, solid_volume(3, 4, 5), unit_cube_stack(3, 4, 5),
                   solid_net_render_json)).

% Each decline names the failed witness.  These are part of the table's
% register: absence alone would not record why a proposed relation was refused.

monitoring_registry_bridge_declined(
    angles_scale_with_sides_in_similar,
    no_drawable_registry_operation(similar_triangles,
                                   rigid_motion_refuses_dilation)).
monitoring_registry_bridge_declined(
    area_formula_inverted,
    no_source_states_the_doing(area,
                               formula_substitution_act_unstated_in_registry)).
monitoring_registry_bridge_declined(
    area_equality_requires_congruence,
    format_needs_two_figures(area_conservation,
                             single_region_tiling_cannot_witness_equivalence)).
monitoring_registry_bridge_declined(
    area_only_for_measurable_polygons,
    no_drawable_registry_operation(definition_of_area,
                                   curved_or_irregular_area_not_carried)).
monitoring_registry_bridge_declined(
    cylinder_cone_prototype_image,
    format_refuses_object('3d_geometry', cylinders_and_cones_not_supported)).
monitoring_registry_bridge_declined(
    definitional_under_or_over_specification,
    not_a_doing(definitions_requirements_are_not_a_drawable_task)).
monitoring_registry_bridge_declined(
    diameter_treated_as_area,
    no_drawable_registry_operation(area_vs_perimeter,
                                   circle_area_comparison_not_carried)).
monitoring_registry_bridge_declined(
    diamond_not_recognized_as_square,
    no_matching_drawable_operation(squares,
                                   triangles_entries_do_not_state_square_classification)).
monitoring_registry_bridge_declined(
    lateral_vs_total_surface_confusion,
    format_refuses_object(surface_area_of_a_cylinder,
                          curved_surface_not_supported_by_solid_net)).
monitoring_registry_bridge_declined(
    parallelogram_trapezoid_confusion,
    class_relation_not_drawn(quadrilaterals,
                             one_polygon_cannot_settle_inclusive_classification)).
monitoring_registry_bridge_declined(
    pythagorean_pattern_misapplied,
    no_drawable_registry_operation(pythagorean_theorem,
                                   no_admitted_task_carries_the_theorem)).
monitoring_registry_bridge_declined(
    right_triangle_without_longest_side,
    identification_witness_missing(right_triangles,
                                   triangles_entries_do_not_state_hypotenuse_error)).
monitoring_registry_bridge_declined(
    side_from_area_by_halving,
    no_drawable_registry_operation(area_of_a_square,
                                   inverse_square_area_task_not_carried)).
monitoring_registry_bridge_declined(
    similarity_by_area_comparison,
    format_refuses_object(similarity_and_congruency, dilation_not_admitted)).
monitoring_registry_bridge_declined(
    similarity_via_additive_difference,
    format_refuses_object(similarity, dilation_not_admitted)).
monitoring_registry_bridge_declined(
    similarity_via_equal_angles_for_quadrilaterals,
    identification_witness_missing(similarity,
                                   equal_angles_for_quadrilaterals_not_registered)).
monitoring_registry_bridge_declined(
    specific_drawing_taken_for_general,
    not_a_doing(general_claim_licensing_is_not_a_drawable_task)).
monitoring_registry_bridge_declined(
    supporting_example_treated_as_proof,
    not_a_doing(example_based_justification_is_not_a_drawable_task)).
monitoring_registry_bridge_declined(
    tetrahedron_called_triangle,
    format_refuses_object(shapes, tetrahedron_not_supported_by_solid_net)).
monitoring_registry_bridge_declined(
    trig_only_with_explicit_right_angle,
    no_drawable_registry_operation(trigonometry,
                                   constructed_perpendicular_not_carried)).
monitoring_registry_bridge_declined(
    unequal_parts_counted_as_equal_fractions,
    no_matching_drawable_operation(unit_fractions,
                                   equipartition_ops_are_not_in_a_drawable_lane)).
monitoring_registry_bridge_declined(
    visual_similarity_without_proportionality_check,
    format_refuses_object(similarity, dilation_not_admitted)).
monitoring_registry_bridge_declined(
    volume_confused_with_area_or_edges,
    no_drawable_registry_operation(area_and_volume_concepts,
                                   dimension_comparison_not_carried)).
