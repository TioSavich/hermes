% metaphors/lakoff_nunez_inventory.pl — L&N grounding metaphors anchored to geometry concepts.
% Schema: ../schema.pl
%
% Source: Lakoff, G. & Núñez, R. (2000). Where Mathematics Comes From: How
% the Embodied Mind Brings Mathematics into Being. Basic Books.
%
% Citation atoms follow the form ln_chN_pNNN where N=chapter, NNN=page.
% Where the page could not be recovered from the NotebookLM snippet, the
% atom uses chapter only (e.g. ln_ch12) and is flagged in
% corpus/lakoff_nunez_passages.md.
%
% Charter: 2026-05-03 overnight Hermes geometry push, Wave 2 (L&N digger).
% See corpus/lakoff_nunez_existing_audit.md (Wave 1) for what NOT to
% re-extract — arithmetic 4Gs and the bare Container schema are already
% formalized elsewhere; this file originates the geometry-specific records.
%
% ConceptId convention: snake_case, named for the geometric concept the
% metaphor grounds, NOT the metaphor itself. The synthesizer reconciles
% with concept IDs proposed by the Van de Walle / N103 digger waves and
% the concept-author wave. Until those waves run, the metaphor_source/4
% clauses below will appear as `orphan_metaphor` validation errors —
% expected; see Wave 2 final report.

:- multifile metaphor_source/4, tier/4, triangulation/2.
:- discontiguous metaphor_source/4, tier/4, triangulation/2.

%!  lakoff_nunez_metaphor_witness(+ConceptId, +MetaphorName, -Witness) is semidet.
%
%   Inspectable witness for the finite loaded L&N geometry metaphor table.
%   This proves that an authored L&N metaphor row resolves to a loaded
%   concept, tier evidence, source-target mappings, and any triangulation rows.
lakoff_nunez_metaphor_witness(ConceptId, MetaphorName, Witness) :-
    witness_dict:witness_dict(geometry_lakoff_nunez_metaphor, closed_world_finite_lakoff_nunez_metaphor_table,
                              _{concept: ConceptId,
                 metaphor: MetaphorName,
                 concept_boundary: ConceptBoundary,
                 concept_evidence: ConceptEvidence,
                 mapping_witnesses: MappingWitnesses,
                 citations: Citation,
                 tier_boundary: TierBoundary,
                 tier: Tier,
                 tier_evidence: TierEvidence,
                 triangulation_evidence: TriangulationEvidence,
                 boundary: finite_lakoff_nunez_geometry_metaphor_claim_not_general_cognitive_metaphor_theory,
                 fact: metaphor_source(ConceptId,
                                       MetaphorName,
                                       Mapping,
                                       Citation) }, WitnessDict47),
    lakoff_nunez_metaphor_family(MetaphorName),
    metaphor_source(ConceptId, MetaphorName, Mapping, Citation),
    lakoff_nunez_concept_evidence(ConceptId,
                                  ConceptBoundary,
                                  ConceptEvidence),
    lakoff_nunez_mapping_witnesses(Mapping, MappingWitnesses),
    lakoff_nunez_tier_evidence(ref(metaphor, ConceptId, MetaphorName),
                               TierBoundary,
                               Tier,
                               TierEvidence),
    lakoff_nunez_triangulation_evidence(ref(metaphor,
                                            ConceptId,
                                            MetaphorName),
                                        TriangulationEvidence),
    Witness = WitnessDict47.

lakoff_nunez_metaphor_family(source_path_goal).
lakoff_nunez_metaphor_family(fictive_motion).
lakoff_nunez_metaphor_family(spaces_are_sets_of_points).
lakoff_nunez_metaphor_family(space_set_blend).
lakoff_nunez_metaphor_family(unit_circle_blend).
lakoff_nunez_metaphor_family(rotation_plane_blend).
lakoff_nunez_metaphor_family(motion_along_a_path).
lakoff_nunez_metaphor_family(bmi_projective).
lakoff_nunez_metaphor_family(bmi_circle_polygon).
lakoff_nunez_metaphor_family(bmi_via_set_blend).
lakoff_nunez_metaphor_family(container_schema).
lakoff_nunez_metaphor_family(categories_are_containers).

lakoff_nunez_concept_evidence(ConceptId,
                              loaded_geometry_concept_record,
    _{ kind: resolved_lakoff_nunez_concept,
       concept: ConceptId,
       name: Name,
       topic: Topic,
       grade_bands: GradeBands,
       fact: geom_concept(ConceptId, Name, Topic, GradeBands) }) :-
    geom_concept(ConceptId, Name, Topic, GradeBands).

lakoff_nunez_mapping_witnesses(Mapping, MappingWitnesses) :-
    maplist(lakoff_nunez_mapping_witness, Mapping, MappingWitnesses).

lakoff_nunez_mapping_witness(source_target(Source, Target),
    _{ kind: source_target_mapping,
       source: Source,
       target: Target,
       fact: source_target(Source, Target) }).

lakoff_nunez_tier_evidence(Ref, loaded_tier_record, Tier, TierEvidence) :-
    findall(_{ tier: T,
               sources: Sources,
               source_note: SourceNote,
               fact: tier(Ref, T, Sources, SourceNote) },
            tier(Ref, T, Sources, SourceNote),
            RawTierEvidence),
    sort(RawTierEvidence, TierEvidence),
    TierEvidence \== [],
    findall(T,
            ( member(Evidence, TierEvidence),
              get_dict(tier, Evidence, T)
            ),
            Tiers),
    min_list(Tiers, Tier),
    !.
lakoff_nunez_tier_evidence(_Ref, no_loaded_tier_record, 3, []).

lakoff_nunez_triangulation_evidence(Ref, TriangulationEvidence) :-
    findall(_{ agreement: Agreement,
               fact: triangulation(Ref, Agreement) },
            triangulation(Ref, Agreement),
            RawTriangulationEvidence),
    sort(RawTriangulationEvidence, TriangulationEvidence).

% ─── 1. Source-Path-Goal applied to geometry ─────────────────────────
%
% L&N Ch. 2: SPG is "the principal image schema concerned with motion."
% Applied to geometry via Talmy's fictive motion: a line is conceived
% in terms of motion tracing it. L&N Ch. 3 explicitly states the
% segment-end ↔ source/goal mapping. Originate.

metaphor_source(line_segment_as_path, source_path_goal,
    [source_target(trajector, moving_point),
     source_target(source_location, segment_endpoint_a),
     source_target(goal_location, segment_endpoint_b),
     source_target(route, line_segment_interior),
     source_target(actual_trajectory, length_of_segment),
     source_target(direction_of_motion, oriented_segment)],
    [ln_ch2_p38, ln_ch2_p39, ln_ch3]).

tier(ref(metaphor, line_segment_as_path, source_path_goal), 1,
    [source(ln, agrees)],
    "L&N Ch. 3 explicit: 'origin of motion → one end of physical segment; endpoint of motion → other end; path of motion → rest of physical segment.' Ch. 2 p. 39: 'a line is thought of in terms of motion tracing that line.'").

metaphor_source(ray_as_oriented_path, source_path_goal,
    [source_target(trajector, point),
     source_target(source_location, ray_origin),
     source_target(direction_of_motion, ray_direction),
     source_target(unbounded_route, ray_extension),
     source_target(no_goal, no_endpoint)],
    [ln_ch2_p38, ln_ch8]).

tier(ref(metaphor, ray_as_oriented_path, source_path_goal), 3,
    [source(ln, partial)],
    "L&N use 'a ray from zero extending outward indefinitely at some angle θ' (Ch. 8) as a working construction without giving the ray its own SPG mapping. Tier 3: SPG mapping for ray inferred from L&N's general SPG schema (no goal-location since the ray is unbounded), grounded in their Ch. 8 ray construction. Synthesizer should reconcile against any direct ray formalization.").

metaphor_source(curve_traced_by_moving_point, source_path_goal,
    [source_target(trajector, mathematical_point),
     source_target(continuous_motion, continuous_curve),
     source_target(component_motions, x_axis_and_y_axis_components),
     source_target(trajectory, locus_of_curve),
     source_target(parametric_time, curve_parameter)],
    [ln_ch2_p39, ln_cs1, ln_ch12]).

tier(ref(metaphor, curve_traced_by_moving_point, source_path_goal), 1,
    [source(ln, agrees)],
    "L&N Case Study 1: 'curves in space can be conceptualized as being traced by motions of points. Those motions can in turn be conceptualized as having components of motion along the x- and y-axes of the Cartesian plane.' Ch. 12: 'a line or curve is absolutely continuous, like the path traced by a moving point.'").

% ─── 2. Fictive Motion (Talmy) ───────────────────────────────────────
%
% L&N Ch. 2 p. 39 explicit: "the most important manifestation of the
% Source-Path-Goal schema in natural language." Lets static geometric
% objects be described with motion verbs. Originate.

metaphor_source(line_through_two_points, fictive_motion,
    [source_target(motion_verb, geometric_predicate),
     source_target(traveler_along_path, abstract_line),
     source_target(passing_through_location, point_on_line),
     source_target(meeting_at_location, intersection_point),
     source_target(no_temporal_extent, atemporal_geometric_relation)],
    [ln_ch2_p39, ln_ch12]).

tier(ref(metaphor, line_through_two_points, fictive_motion), 1,
    [source(ln, agrees)],
    "L&N Ch. 2 p. 39: 'In mathematics, this occurs when we think of two lines meeting at a point.' Static geometric configuration is described with the motion verb 'meet' as if the lines travelled to a meeting place.").

metaphor_source(curve_passes_through_point, fictive_motion,
    [source_target(traveler, curve_or_graph),
     source_target(landmarks_on_path, points_on_curve),
     source_target(motion_verb_passing, set_membership_relation),
     source_target(motion_verb_reaching, attained_function_value)],
    [ln_ch2_p38, ln_ch2_p39]).

tier(ref(metaphor, curve_passes_through_point, fictive_motion), 1,
    [source(ln, agrees)],
    "L&N Ch. 2 p. 38: 'Functions in the Cartesian plane are often conceptualized in terms of motion along a path—as when a function is described as going up, reaching a maximum, and going down again.' The verbs 'passes through,' 'reaches,' 'goes up' are fictive motion encoding static graph properties.").

metaphor_source(static_figure_as_dynamic_process, fictive_motion,
    [source_target(temporally_extended_process, atemporal_object),
     source_target(motion_along_shape, shape_itself),
     source_target(perfective_completion, gestalt_figure)],
    [ln_ch2, ln_ch8]).

tier(ref(metaphor, static_figure_as_dynamic_process, fictive_motion), 1,
    [source(ln, agrees)],
    "L&N Ch. 8: 'an elongated path, object, or shape can be conceptualized metaphorically as a process tracing the length of that path, object, or shape.' L&N Ch. 2: 'processes can be conceptualized as atemporal.' This is the meta-metaphor that licenses geometric language to use motion verbs at all.").

% ─── 3. Spaces-Are-Sets-of-Points (Discretization) ───────────────────
%
% L&N Ch. 12: "the central metaphor at the heart of the discretization
% program." Full source/target mapping printed in the book. Originate.

metaphor_source(space_as_set_of_points, spaces_are_sets_of_points,
    [source_target(set, n_dimensional_space),
     source_target(set_member, point_location),
     source_target(member_independence, point_inherent_to_space_NEGATED),
     source_target(member_distinctness, location_distinctness),
     source_target(relations_among_members, properties_of_space),
     source_target(set_membership, being_a_point_in_a_space),
     source_target(subset, geometric_figure)],
    [ln_ch12_p538, ln_ch12_p539]).

tier(ref(metaphor, space_as_set_of_points, spaces_are_sets_of_points), 1,
    [source(ln, agrees)],
    "L&N Ch. 12: 'A SPACE IS A SET OF POINTS. Source: A SET WITH ELEMENTS. Target: NATURALLY CONTINUOUS SPACE WITH POINT-LOCATIONS.' Reverses the natural-continuity-priority of points (in everyday cognition points are inherent to space; in this metaphor space is constituted by points). Notes: L&N flag 'the two conceptions are inconsistent' — both must be tracked.").

metaphor_source(line_as_set_of_points, spaces_are_sets_of_points,
    [source_target(set, line),
     source_target(elements, points_on_line),
     source_target(relation_among_elements, ordering_or_betweenness),
     source_target(set_constituted_by_elements, line_constituted_by_points)],
    [ln_ch12, ln_ch13]).

tier(ref(metaphor, line_as_set_of_points, spaces_are_sets_of_points), 1,
    [source(ln, agrees)],
    "L&N Ch. 12 special case 'THE LINE': 'Spaces, planes, and lines—being sets—do not exist independently of the points that constitute them. A line is a set of points with certain relations holding among the points.' L&N Ch. 13 (Dedekind): 'The metaphor that A Line Is a Set of Points is implicitly required.'").

metaphor_source(geometric_figure_as_subset, spaces_are_sets_of_points,
    [source_target(subset_of_set, region_of_space),
     source_target(elements_with_relations, points_with_geometric_relations),
     source_target(distance_function, metric),
     source_target(curvature_function, point_curvature_assignment),
     source_target(dimension_function, dimensionality_of_figure)],
    [ln_ch12]).

tier(ref(metaphor, geometric_figure_as_subset, spaces_are_sets_of_points), 1,
    [source(ln, agrees)],
    "L&N Ch. 12: 'A geometrical figure, like a circle or a triangle, is a subset of the points in a space, with certain relations among the points. There is thus nothing inherently spatial about a circle or triangle.' Curvature, distance, and dimension all become functions assigning numbers to points or n-tuples of points.").

metaphor_source(space_set_blend_for_line, space_set_blend,
    [source_target(naturally_continuous_line, set_of_point_elements),
     source_target(point_locations_inherent, members_independent_of_set),
     source_target(properties_of_line, relations_among_members),
     source_target(geometric_intuition_of_continuity, arithmetic_gaplessness)],
    [ln_ch12, ln_ch13]).

tier(ref(metaphor, space_set_blend_for_line, space_set_blend), 1,
    [source(ln, agrees)],
    "L&N Ch. 12: 'THE SPACE-SET BLEND ... SPECIAL CASE: THE LINE.' This is the full conceptual blend (not just the metaphor) that fuses naturally-continuous space with the set-of-elements view. Dedekind's continuity-as-gaplessness (Ch. 13) only makes sense inside this blend.").

% ─── 4. Unit Circle Blend (Trigonometry) ─────────────────────────────
%
% L&N Case Study 1, p. 388 onwards. Originate.

metaphor_source(unit_circle_for_trigonometry, unit_circle_blend,
    [source_target(circle_in_euclidean_plane, unit_circle),
     source_target(cartesian_plane_origin, unit_circle_center),
     source_target(radius_one, scaling_to_unit),
     source_target(point_on_circle_traced_by_motion, angle_parameter),
     source_target(arc_length_subtended, radian_measure_of_angle),
     source_target(length_of_horizontal_leg_a, cosine_of_angle),
     source_target(length_of_vertical_leg_b, sine_of_angle),
     source_target(pythagorean_constraint_x2_plus_y2_equals_1, sin2_plus_cos2_equals_1)],
    [ln_cs1_p388, ln_cs1_p393, ln_cs1_p394]).

tier(ref(metaphor, unit_circle_for_trigonometry, unit_circle_blend), 1,
    [source(ln, agrees)],
    "L&N Case Study 1 p. 388: 'a blend of two elements in two domains: a circle in the Euclidean plane blended with the Cartesian plane to yield a unit circle.' p. 393 Trigonometry Metaphor: 'length of side a → cos θ; length of side b → sin θ.' p. 394: 'a circle is conceptualized as the curve traced by a point that moves in a circle.'").

% ─── 5. Rotation-Plane Blend ─────────────────────────────────────────
%
% L&N Case Study 3, p. 426 onwards. Originate.

metaphor_source(rotation_in_plane, rotation_plane_blend,
    [source_target(physical_rotation, multiplication_by_signed_factor),
     source_target(rotation_by_180_degrees, multiplication_by_negative_one),
     source_target(rotation_by_90_degrees, multiplication_by_i),
     source_target(two_90_degree_rotations, multiplication_by_i_squared_negative_one),
     source_target(angle_of_rotation, argument_of_complex_number),
     source_target(point_position_after_rotation, complex_product),
     source_target(cartesian_plane_with_rotation_metaphor, complex_plane)],
    [ln_cs3_p426, ln_cs3_p429, ln_cs3_p430]).

tier(ref(metaphor, rotation_in_plane, rotation_plane_blend), 1,
    [source(ln, agrees)],
    "L&N Case Study 3 p. 426: 'This blend creates a new conceptual entity—the rotation plane, which is the Cartesian plane together with the metaphor characterizing multiplication by -1 as a rotation by 180°.' p. 429-430: 'Rotation by 90° → Multiplication by i (= √-1).' 'The complex plane is just the 90° rotation plane.'").

metaphor_source(geometric_rotation_as_motion, motion_along_a_path,
    [source_target(rigid_body_motion, geometric_transformation),
     source_target(rotation_center, fixed_point),
     source_target(angular_path_traced, arc_of_motion),
     source_target(motion_completed, final_position_of_figure)],
    [ln_cs1_p394, ln_cs3]).

tier(ref(metaphor, geometric_rotation_as_motion, motion_along_a_path), 3,
    [source(ln, partial)],
    "Tier 3 extension. L&N treat rotation as motion of a single point on the unit circle (CS1 p. 394) and as multiplicative transformation in the rotation plane (CS3); they do not give a Motion-Along-a-Path mapping for rigid-body rotation of an extended figure. Inferred extension: each point of a figure is itself a trajector that traces an arc; the figure rotates iff every constituent point completes the same angular path. Synthesizer: confirm against transformations-topic concept author.").

% ─── 6. Basic Metaphor of Infinity — geometric specializations ───────
%
% L&N Ch. 8: BMI is the master metaphor for actual infinity. It has
% geometric specializations.

metaphor_source(parallel_lines_meet_at_infinity, bmi_projective,
    [source_target(unending_iterative_process, sequence_of_isosceles_triangles),
     source_target(state_after_iteration_n, triangle_ABCn_with_lines_almost_parallel),
     source_target(distance_D_n_grows_unboundedly, ac_lengths_unbounded),
     source_target(angle_alpha_approaches_90, lines_approach_parallel),
     source_target(final_resultant_state_at_infinity, point_C_infinity),
     source_target(unique_completion, parallel_lines_meet_at_unique_point_at_infinity)],
    [ln_ch8_p159, ln_ch8_p160, ln_ch8_p161]).

tier(ref(metaphor, parallel_lines_meet_at_infinity, bmi_projective), 1,
    [source(ln, agrees)],
    "L&N Ch. 8: 'In projective geometry, there is an axiom that all parallel lines meet at infinity.' L&N show this is a special case of the BMI applied to an isosceles-triangle frame: 'this application of the BMI defines the same system of geometry as the basic axiom of projective geometry.' Pages estimated from chapter context; corpus file flags page-anchor uncertainty.").

metaphor_source(circle_as_polygon_limit, bmi_circle_polygon,
    [source_target(unending_iterative_process, sequence_of_regular_n_gons),
     source_target(state_after_iteration_n, n_gon_with_n_sides),
     source_target(no_metaphorical_completion_in_potential_infinity, no_circle_directly),
     source_target(potential_infinity_only, no_unique_BMI_result)],
    [ln_ch8]).

tier(ref(metaphor, circle_as_polygon_limit, bmi_circle_polygon), 3,
    [source(ln, disagrees)],
    "Tier 3 with L&N DISAGREEMENT flagged. L&N Ch. 8 Figure 8.1 explicitly use the n-gon sequence as the canonical example of *potential* infinity 'with no polygon characterizing an ultimate result.' That is, L&N do NOT directly assert 'circle as BMI completion of the polygon sequence'; they use it as the foil for what the BMI must do above and beyond. The geometrically intuitive 'circle = limit of n-gons' reading requires *adding* the BMI explicitly (the way pi was historically computed by Archimedes). This record exists so the synthesizer can reconcile the pedagogical intuition with L&N's negative example. Notes: see also OPEN_QUESTIONS.md item bmi-circle-polygon-completion.").

metaphor_source(curve_as_limit_of_curves, bmi_via_set_blend,
    [source_target(sequence_of_curves, sequence_of_sets_of_ordered_pairs),
     source_target(curve_as_set_via_space_set_metaphor, set_of_xy_coordinate_pairs),
     source_target(bmi_for_number_sequences, limit_of_each_coordinate),
     source_target(limit_set_metaphor, set_of_limits_of_sequences),
     source_target(reconstituted_geometric_curve, fictive_limit_curve)],
    [ln_ch12, ln_ch14]).

tier(ref(metaphor, curve_as_limit_of_curves, bmi_via_set_blend), 1,
    [source(ln, agrees)],
    "L&N Ch. 12 (Le trou normand bumpy-curve passage and Hilbert space-filling curve): the BMI cannot directly take the limit of a sequence of *curves* because the BMI is defined over numbers. Curves must first be metaphorically replaced by sets of ordered pairs (via Spaces-Are-Sets-of-Points), THEN the Limit-Set metaphor maps the set-limits back onto a geometric curve. This is a chained metaphor — relevant for any geometry-side talk of limit curves, fractals, space-filling curves.").

% ─── 7. Container Schema for geometric containment ───────────────────
%
% L&N Ch. 2 p. 31 introduces Container schema. Already partially
% formalized (eple/domains/embodiment/schemas.py — see
% LK_RB_Content_Extract). Extend to geometric containment.

metaphor_source(polygon_interior_as_container, container_schema,
    [source_target(interior, region_inside_polygon),
     source_target(boundary, polygon_perimeter),
     source_target(exterior, region_outside_polygon),
     source_target(in_out_excluded_middle, point_either_inside_or_outside),
     source_target(transitivity_of_containment, nested_polygon_inclusion),
     source_target(gestalt_no_part_without_whole, polygon_is_topological_whole)],
    [ln_ch2_p160, ln_ch2_p170, py_eple_schemas]).

tier(ref(metaphor, polygon_interior_as_container, container_schema), 1,
    [source(ln, agrees), source(py_eple_schemas, agrees)],
    "L&N Ch. 2 p. 160-161 introduce Container schema with Interior/Boundary/Exterior gestalt. Ch. 2 p. 170: 'The concept of containment is central to much of mathematics. Closed sets of points are conceptualized as containers, as are bounded intervals, geometric figures, and so on.' Cross-cite: LK_RB_Content_Extract/eple/domains/embodiment/schemas.py formalizes Inside/Outside predicates, in_out_incompatibility, transitivity_of_inside, totality_incompatibility for the bare schema. The polygon-interior specialization extends that runnable formalization to closed plane figures.").

triangulation(ref(metaphor, polygon_interior_as_container, container_schema),
    [source(ln, agrees), source(py_eple_schemas, agrees), source(misconceptions_measurement_pl, agrees)]).

metaphor_source(point_in_region_membership, container_schema,
    [source_target(located_object, geometric_point),
     source_target(container_interior, bounded_region),
     source_target(in_relation, point_in_region_predicate),
     source_target(boundary_separation, curve_or_polyline_boundary)],
    [ln_ch2_p170, ln_ch12_p538]).

tier(ref(metaphor, point_in_region_membership, container_schema), 1,
    [source(ln, agrees)],
    "L&N Ch. 12: 'In any naturally continuous space, there are bounded regions (conceptualized via the Container schema, as discussed in Chapter 2). The interior of such a bounded region (the container minus the boundary) is an open set containing all the spatial locations in that bounded region.' This anchors the open-set definition (interior = container minus boundary) used downstream in topology.").

metaphor_source(closed_curve_bounds_region, container_schema,
    [source_target(closed_curve, container_boundary),
     source_target(interior_of_closed_curve, container_interior),
     source_target(exterior_of_closed_curve, container_exterior),
     source_target(region_has_an_area, interior_has_measure)],
    [ln_ch14_p307, ln_ch2_p170]).

tier(ref(metaphor, closed_curve_bounds_region, container_schema), 1,
    [source(ln, agrees)],
    "L&N Ch. 14 quoting Pierpont's 'prototypical properties of a curve': 'When closed, it forms the complete boundary of a region. This region has an area.' The container-schema reading is implicit: closed curve = boundary, region = interior. L&N do not work out the area-measure mapping themselves (see measuring_stick.pl Tier 3 records).").

metaphor_source(category_of_shapes_as_container, categories_are_containers,
    [source_target(category, container_class),
     source_target(category_membership, being_inside_container),
     source_target(subcategory, sub_container),
     source_target(transitivity_of_subcategory, transitivity_of_containment),
     source_target(squares_inside_rectangles, square_subcategory_of_rectangle)],
    [ln_ch2_p164, ln_ch6_p211]).

tier(ref(metaphor, category_of_shapes_as_container, categories_are_containers), 1,
    [source(ln, agrees)],
    "L&N Ch. 2 p. 164-165 + Ch. 6 p. 211-213: Categories Are Containers maps Container-schema spatial logic onto categorical hierarchy (excluded middle, modus ponens, hypothetical syllogism, modus tollens). Notes: AUDIT FLAG — L&N distinguish 'Categories Are Containers' (the metaphor) from the bare 'Container Schema' (the source). This record uses the metaphor name, not the schema name. Synthesizer: this is the metaphor that licenses Van Hiele Level 2 inclusion claims like 'every square is a rectangle.'").

% =====================================================================
% Q-N103-C resolution (2026-05-04): N103's tracing-paper diagnostic is
% itself an instance of L&N's fictive_motion metaphor — the static
% relationship between two figures (translation/rotation/reflection/glide)
% is conceptualized as the *motion* of a tracing across the page. Cross-
% link tracing_paper_diagnostic to the fictive_motion family.
% =====================================================================

metaphor_source(tracing_paper_diagnostic, fictive_motion,
    [source_target(traveling_traced_figure, abstract_isometry),
     source_target(motion_of_paper_across_page, transformation_acting_on_plane),
     source_target(initial_position_of_tracing, pre_image),
     source_target(final_position_of_tracing, image),
     source_target(temporally_extended_trace_action, atemporal_geometric_relation)],
    [n103_ch15, n103_ch16, ln_ch2_p38]).

tier(ref(metaphor, tracing_paper_diagnostic, fictive_motion), 2,
    [source(n103, agrees), source(ln, agrees), source(synthesizer, agrees)],
    "Q-N103-C resolution 2026-05-04: triangulation between N103 (tracing-paper actions framing) and L&N (fictive_motion in Ch. 2). Tier 2 because both sources independently support the cross-link, but neither names the connection explicitly — the triangulation is the synthesizer's reading.").

triangulation(ref(metaphor, tracing_paper_diagnostic, fictive_motion),
    [ source(n103, agrees),
      source(ln, agrees),
      source(synthesizer, agrees) ]).
