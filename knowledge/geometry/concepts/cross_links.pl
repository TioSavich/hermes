% concepts/cross_links.pl — explicit typed cross-links between
% concepts that the matching layer wouldn't otherwise bridge.
%
% Authored 2026-05-04 evening as part of the Hermes chatbot iteration loop
% (post-overnight smoke-test review). The pattern: when concept A names a
% phenomenon and concept B owns the knowledge/misconceptions/markers/bootstraps for
% that phenomenon, an explicit typed concept_relation/4 cross-link lets
% `concepts_in_neighborhood/3` (in query.pl) bridge them, so the bot's
% matcher can pull B's tagging-layer data when the user's tokens only
% match A.
%
% Each new cross-link uses the predicate-shape:
%   concept_relation(SourceConcept, manifests_as, TargetConcept, entitled).
%
% The "manifests as" semantics: SourceConcept names a specific phenomenon
% or arc; TargetConcept owns the broader property that licenses
% misconception/marker/bootstrap records. Both concepts remain valid
% standalone records — this is augmentation, not replacement.
%
% Legacy material_inference/4 facts remain for current consumers, but these
% edges are conceptual routing edges, not proof-bearing material entailments.
%
% Schema: ../schema.pl

:- multifile concept_relation/4, material_inference/4, proof_relation/3,
             reconstructive_relation/4, tier/4.
:- discontiguous concept_relation/4, material_inference/4,
                proof_relation/3, reconstructive_relation/4, tier/4.

%!  cross_link_witness(+Source, +Relation, +Target, +Status, -Witness) is semidet.
%
%   Inspectable proof object for a finite geometry cross-link. These are
%   conceptual routing edges, not proof entailments; when a matching
%   material_inference/4 row and tier/4 source exist, the witness includes
%   that support.
cross_link_witness(Source,
                   Relation,
                   Target,
                   Status,
                   WitnessDict40) :-
    witness_dict:witness_dict(geometry_cross_link, closed_world_finite_geometry_cross_link_table,
                              _{source: Source,
                      relation: Relation,
                      target: Target,
                      status: Status,
                      support_status: SupportStatus,
                      boundary: Boundary,
                      fact: concept_relation(Source, Relation, Target, Status),
                      peer_relations: PeerRelations,
                      material_witness: MaterialWitness,
                      material_witnesses: MaterialWitnesses }, WitnessDict40),
    concept_relation(Source, Relation, Target, Status),
    cross_link_relation_peers(Source, Target, Status, PeerRelations),
    cross_link_material_support(Source,
                                Target,
                                Status,
                                PeerRelations,
                                SupportStatus,
                                Boundary,
                                MaterialWitness,
                                MaterialWitnesses).

cross_link_relation_peers(Source, Target, Status, PeerRelations) :-
    findall(R, concept_relation(Source, R, Target, Status), RawRelations),
    sort(RawRelations, PeerRelations).

cross_link_material_support(Source,
                            Target,
                            Polarity,
                            PeerRelations,
                            shared_source_target_material_support,
                            material_support_not_relation_disambiguated,
                            ambiguous,
                            MaterialWitnesses) :-
    PeerRelations = [_, _|_],
    findall(MaterialWitness,
            cross_link_material_inference_witness(Source,
                                                  _Premise,
                                                  Target,
                                                  Polarity,
                                                  MaterialWitness),
            MaterialWitnesses),
    MaterialWitnesses \== [],
    !.
cross_link_material_support(Source,
                            Target,
                            Polarity,
                            _PeerRelations,
                            tiered_material_support,
                            material_inference_has_loaded_tier_support,
                            MaterialWitness,
                            [MaterialWitness]) :-
    cross_link_material_inference_witness(Source,
                                          _Premise,
                                          Target,
                                          Polarity,
                                          MaterialWitness),
    !.
cross_link_material_support(_Source,
                            _Target,
                            _Polarity,
                            _PeerRelations,
                            routing_edge_only_no_material_row,
                            concept_relation_is_conceptual_routing_not_proof_entailment,
                            none,
                            []).

%!  cross_link_material_inference_witness(+Source, +Premise, +Target,
%!                                        +Polarity, -Witness) is semidet.
%
%   Inspectable proof object for a finite cross-link material-inference row.
cross_link_material_inference_witness(Source,
                                      Premise,
                                      Target,
                                      Polarity,
                                      WitnessDict116) :-
    witness_dict:witness_dict(geometry_cross_link_material_inference, closed_world_finite_geometry_cross_link_table,
                              _{source: Source,
                                         premise: Premise,
                                         target: Target,
                                         polarity: Polarity,
                                         tier: Tier,
                                         sources: Sources,
                                         source_note: SourceNote,
                                         fact: material_inference(Source,
                                                                  Premise,
                                                                  Target,
                                                                  Polarity) }, WitnessDict116),
    material_inference(Source, Premise, Target, Polarity),
    tier(ref(material_inference, Source, Target), Tier, Sources, SourceNote).

% ── Orientation cluster (smoke test A) ──────────────────────────────
%
% tilted_square_as_diamond is the phenomenon-named concept; the actual
% misconceptions (square_only_axis_aligned, diamond_not_recognized_as_square,
% etc.) live under orientation_invariant_naming.

concept_relation(tilted_square_as_diamond,
    manifests_as,
    orientation_invariant_naming, entitled).
material_inference(tilted_square_as_diamond,
    "manifests as misconception under",
    orientation_invariant_naming, entitled).
tier(ref(material_inference, tilted_square_as_diamond,
         orientation_invariant_naming),
     1, [source(synthesizer, agrees)],
     "Cross-link added 2026-05-04 to bridge phenomenon concept (tilted_square_as_diamond) to property concept (orientation_invariant_naming) where the misconceptions are authored. Lets concepts_in_neighborhood/3 traverse from one to the other.").

proof_relation(square_as_rectangle,
    material_entails,
    rectangle_as_parallelogram).
tier(ref(proof_relation, square_as_rectangle, rectangle_as_parallelogram),
     1, [source(vdw, agrees), source(van_hiele, agrees)],
     "Proof-bearing quadrilateral hierarchy edge: once a square is classified as a rectangle, rectangle-as-parallelogram entitlement follows in the inclusive hierarchy. Kept separate from concept_relation/4 routing edges.").

reconstructive_relation(n103_cd_3_1_perpendicular_bisector,
    action_impetus_marker,
    medial_quadrilateral,
    evidence(n103_ch3, paper_folding_construction)).
tier(ref(reconstructive_relation,
         n103_cd_3_1_perpendicular_bisector,
         medial_quadrilateral),
     1, [n103_ch3],
     "Carspeckenian/reconstructive edge: the paper-folding construction activity supplies an action impetus for recognizing medial-quadrilateral invariants.").

concept_relation(diamond_not_recognized_as_square,
    misconception_surface_of,
    orientation_invariant_naming, entitled).
material_inference(diamond_not_recognized_as_square,
    "is a misconception under",
    orientation_invariant_naming, entitled).
tier(ref(material_inference, diamond_not_recognized_as_square,
         orientation_invariant_naming),
     1, [source(synthesizer, agrees)],
     "diamond_not_recognized_as_square is a misconception name; this cross-link makes its parent concept reachable.").

concept_relation(square_only_axis_aligned,
    misconception_surface_of,
    orientation_invariant_naming, entitled).
material_inference(square_only_axis_aligned,
    "is a misconception under",
    orientation_invariant_naming, entitled).
tier(ref(material_inference, square_only_axis_aligned,
         orientation_invariant_naming),
     1, [source(synthesizer, agrees)],
     "Same pattern.").

% ── Trapezoid cluster (smoke test C) ────────────────────────────────
%
% trapezoid_classification_arc has its from/to stances as functor terms
% containing concept IDs (already accessible via concept_id_in_stance/2),
% but explicit material_inferences make the linkage robust against future
% matcher changes.

concept_relation(trapezoid_classification_arc,
    developmental_transition,
    exclusive_definition, entitled).
material_inference(trapezoid_classification_arc,
    "from-stance concept",
    exclusive_definition, entitled).
tier(ref(material_inference, trapezoid_classification_arc,
         exclusive_definition),
     2, [source(synthesizer, agrees)],
     "Arc bridges the exclusive→inclusive trapezoid transition.").

concept_relation(trapezoid_classification_arc,
    developmental_transition,
    inclusive_definition, entitled).
material_inference(trapezoid_classification_arc,
    "to-stance concept",
    inclusive_definition, entitled).
tier(ref(material_inference, trapezoid_classification_arc,
         inclusive_definition),
     2, [source(synthesizer, agrees)],
     "Arc bridges the exclusive→inclusive trapezoid transition.").

concept_relation(trapezoid_classification_arc,
    manifests_as,
    parallelogram_as_trapezoid, entitled).
material_inference(trapezoid_classification_arc,
    "manifests as misconception under",
    parallelogram_as_trapezoid, entitled).
tier(ref(material_inference, trapezoid_classification_arc,
         parallelogram_as_trapezoid),
     2, [source(synthesizer, agrees)],
     "The classic surface form of the exclusive→inclusive transition is whether 'a parallelogram is a trapezoid' is treated as entitled or incompatible.").

% ── Square classification cluster ───────────────────────────────────
%
% square_classification_arc bridges square_recognition (level 0/1 framing)
% and square_rectangle_classification (level 2 framing).

concept_relation(square_classification_arc,
    developmental_transition,
    square_recognition, entitled).
material_inference(square_classification_arc,
    "from-stance concept",
    square_recognition, entitled).
tier(ref(material_inference, square_classification_arc,
         square_recognition),
     1, [source(synthesizer, agrees)],
     "VdW level-0/1 framing of squares as a unit shape.").

concept_relation(square_classification_arc,
    developmental_transition,
    square_rectangle_classification, entitled).
material_inference(square_classification_arc,
    "to-stance concept",
    square_rectangle_classification, entitled).
tier(ref(material_inference, square_classification_arc,
         square_rectangle_classification),
     1, [source(synthesizer, agrees)],
     "vH level-2 framing of squares as included in rectangles.").

concept_relation(square_rectangle_classification,
    grounded_by,
    category_of_shapes_as_container, entitled).
material_inference(square_rectangle_classification,
    "square-as-special-rectangle class inclusion is asserted",
    category_of_shapes_as_container, entitled).
tier(ref(material_inference, square_rectangle_classification,
         category_of_shapes_as_container),
     2, [source(ln, agrees), source(synthesizer, agrees)],
     "The category-container metaphor is the L&N grounding for van Hiele level-2 class-inclusion claims such as every square is a rectangle.").

concept_relation(square_rectangle_classification,
    misconception_family,
    quadrilateral_hierarchy, entitled).
material_inference(square_rectangle_classification,
    "student reasons with square-rectangle class inclusion",
    quadrilateral_hierarchy, entitled).
tier(ref(material_inference, square_rectangle_classification,
         quadrilateral_hierarchy),
     2, [source(vdw, agrees), source(synthesizer, agrees)],
     "Quadrilateral hierarchy owns the broader shape-class misconceptions that surface around square-rectangle inclusion.").

% ── Van Hiele level-2 monitoring cluster ─────────────────────────────
%
% The level concept owns the developmental frame; the neighboring concepts
% own the concrete student markers, class-inclusion misconceptions, L&N
% category-container grounding, and grade-5 standards.

concept_relation(van_hiele_level_2_abstract,
    developmental_transition,
    square_rectangle_classification, entitled).

concept_relation(van_hiele_level_2_abstract,
    misconception_family,
    quadrilateral_hierarchy, entitled).

concept_relation(van_hiele_level_2_abstract,
    grounded_by,
    category_of_shapes_as_container, entitled).
material_inference(van_hiele_level_2_abstract,
    "class-inclusion reasoning becomes available at van Hiele level 2",
    category_of_shapes_as_container, entitled).
tier(ref(material_inference, van_hiele_level_2_abstract,
         category_of_shapes_as_container),
     2, [source(van_hiele, agrees), source(ln, agrees), source(synthesizer, agrees)],
     "Level-2 relational classification is grounded by the L&N category-container metaphor already authored as category_of_shapes_as_container.").

concept_relation(van_hiele_level_2_abstract,
    standard_generalization,
    shape_hierarchy_classification, entitled).
material_inference(van_hiele_level_2_abstract,
    "class-inclusion reasoning becomes available at van Hiele level 2",
    shape_hierarchy_classification, entitled).
tier(ref(material_inference, van_hiele_level_2_abstract,
         shape_hierarchy_classification),
     2, [source(van_hiele, agrees), source(ccss, agrees), source(synthesizer, agrees)],
     "The CCSS grade-5 shape-hierarchy standard is the K-8 standards anchor for level-2 class-inclusion reasoning.").

concept_relation(shape_attributes_informal,
    misconception_family,
    shape_identified_by_properties_not_appearance, entitled).
material_inference(shape_attributes_informal,
    "student names a shape by sides, corners, faces, and equal-length attributes across different sizes and orientations",
    shape_identified_by_properties_not_appearance, entitled).
tier(ref(material_inference, shape_attributes_informal,
         shape_identified_by_properties_not_appearance),
     2, [source(corpus_37754, agrees), source(corpus_40566, agrees), source(synthesizer, agrees)],
     "The K-level attribute-comparison cluster needs the prototype/orientation misconception family authored under shape_identified_by_properties_not_appearance.").

concept_relation(shape_attributes_informal,
    grounded_by,
    category_of_shapes_as_container, entitled).
material_inference(shape_attributes_informal,
    "student treats a shape name as a category whose members share relevant attributes",
    category_of_shapes_as_container, entitled).
tier(ref(material_inference, shape_attributes_informal,
         category_of_shapes_as_container),
     2, [source(ln, agrees), source(synthesizer, agrees)],
     "Informal shape-attribute reasoning grounds shape names as category containers before the later formal class-inclusion hierarchy.").

concept_relation(compose_2d_3d_shapes,
    prerequisite_for,
    compose_decompose_shapes, entitled).
material_inference(compose_2d_3d_shapes,
    "student composes smaller two- or three-dimensional shapes into a larger composite shape",
    compose_decompose_shapes, entitled).
tier(ref(material_inference, compose_2d_3d_shapes,
         compose_decompose_shapes),
     2, [source(ccss, agrees), source(in_indiana, agrees), source(synthesizer, agrees)],
     "Grade-1 shape composition is the standards predecessor for Indiana grade-2 compose/decompose shape prediction.").

concept_relation(compose_decompose_shapes,
    grounded_by,
    polygon_interior_as_container, entitled).
material_inference(compose_decompose_shapes,
    "student treats the recomposed figure as one whole with an interior, boundary, and exterior",
    polygon_interior_as_container, entitled).
tier(ref(material_inference, compose_decompose_shapes,
         polygon_interior_as_container),
     2, [source(ln, agrees), source(synthesizer, agrees)],
     "Composing and decomposing plane shapes depends on preserving the whole's bounded interior and boundary while rearranging parts.").

concept_relation(compose_decompose_shapes,
    misconception_family,
    area_as_array_structure, entitled).
material_inference(compose_decompose_shapes,
    "student composes or decomposes a region using parts that cover the whole with no gaps and no overlaps",
    area_as_array_structure, entitled).
tier(ref(material_inference, compose_decompose_shapes,
         area_as_array_structure),
     2, [source(corpus_39655, agrees), source(corpus_38676, agrees), source(synthesizer, agrees)],
     "The compose_decompose_shapes generated cluster flags no-gap/no-overlap whole tracking; area_as_array_structure owns the cited tiling misconception records for that commitment.").

concept_relation(coordinate_system_axes,
    standard_generalization,
    graph_points_first_quadrant, entitled).
material_inference(coordinate_system_axes,
    "student locates a point by moving from the origin along one axis and then the other axis",
    graph_points_first_quadrant, entitled).
tier(ref(material_inference, coordinate_system_axes,
         graph_points_first_quadrant),
     2, [source(ccss, agrees), source(im, agrees), source(synthesizer, agrees)],
     "The coordinate_grid_location monitoring cluster starts with the grade-5 axis convention and reaches the grade-5 graph-points application standard.").

concept_relation(coordinate_system_axes,
    grounded_by,
    curve_traced_by_moving_point, entitled).
material_inference(coordinate_system_axes,
    "student interprets coordinate changes as horizontal and vertical component motions from the origin",
    curve_traced_by_moving_point, entitled).
tier(ref(material_inference, coordinate_system_axes,
         curve_traced_by_moving_point),
     2, [source(ln, agrees), source(synthesizer, agrees)],
     "L&N's curve-traced-by-moving-point mapping explicitly decomposes motion into x-axis and y-axis components, grounding ordered-pair location.").

concept_relation(coordinate_system_axes,
    misconception_family,
    coordinate_axis_conventions, entitled).
material_inference(coordinate_system_axes,
    "student reads ordered pairs by attending to origin, scale, and axis labels",
    coordinate_axis_conventions, entitled).
tier(ref(material_inference, coordinate_system_axes,
         coordinate_axis_conventions),
     3, [source(corpus_38154, agrees), source(synthesizer, agrees)],
     "The generated coordinate-grid cluster flags coordinate or axis reversal; corpus row 38154 owns the cited axis-variable reversal misconception.").

concept_relation(partition_into_equal_shares,
    prerequisite_for,
    partition_shapes_unit_fraction_area, entitled).
material_inference(partition_into_equal_shares,
    "student partitions circles and rectangles into halves and fourths and describes the whole by those parts",
    partition_shapes_unit_fraction_area, entitled).
tier(ref(material_inference, partition_into_equal_shares,
         partition_shapes_unit_fraction_area),
     2, [source(ccss, agrees), source(in_indiana, agrees), source(im, agrees)],
     "Grade-1 equal-share partitioning is the standards predecessor for grade-3 unit-fraction area partitions.").

concept_relation(partition_into_equal_shares_thirds,
    prerequisite_for,
    partition_shapes_unit_fraction_area, entitled).
material_inference(partition_into_equal_shares_thirds,
    "student recognizes that equal shares of identical wholes need not have the same shape",
    partition_shapes_unit_fraction_area, entitled).
tier(ref(material_inference, partition_into_equal_shares_thirds,
         partition_shapes_unit_fraction_area),
     2, [source(ccss, agrees), source(in_indiana, agrees), source(im, agrees)],
     "Grade-2 equal-share partitioning extends halves and fourths to thirds and prepares the grade-3 equal-area unit-fraction standard.").

concept_relation(partition_shapes_unit_fraction_area,
    grounded_by,
    area_as_2d_unit_iteration, entitled).
material_inference(partition_shapes_unit_fraction_area,
    "student justifies equal fractional shares by comparing the area each part covers inside the whole",
    area_as_2d_unit_iteration, entitled).
tier(ref(material_inference, partition_shapes_unit_fraction_area,
         area_as_2d_unit_iteration),
     2, [source(ln, partial), source(ccss, agrees), source(synthesizer, agrees)],
     "Equal-share fractional-area reasoning uses the same 2D unit-iteration commitment as area measurement: the parts must cover equal amounts of the whole's interior.").

concept_relation(partition_shapes_unit_fraction_area,
    misconception_family,
    area_conservation_under_transformation, entitled).
material_inference(partition_shapes_unit_fraction_area,
    "student accepts that non-congruent pieces can still be equal fractional shares when their areas match",
    area_conservation_under_transformation, entitled).
tier(ref(material_inference, partition_shapes_unit_fraction_area,
         area_conservation_under_transformation),
     2, [source(corpus_39141, agrees), source(corpus_38605, agrees), source(synthesizer, agrees)],
     "The equal_shares_fraction_geometry cluster flags the congruence-vs-equal-area deformation; area_conservation_under_transformation owns the existing cited misconception family.").

concept_relation(similar_figures,
    grounded_by,
    similarity_as_uniform_scaling, entitled).
material_inference(similar_figures,
    "student identifies figures as similar",
    similarity_as_uniform_scaling, entitled).
tier(ref(material_inference, similar_figures,
         similarity_as_uniform_scaling),
     3, [source(synthesizer, agrees)],
     "The similarity_as_uniform_scaling anchor supplies the metaphor support for similar_figures.").

concept_relation(similar_figures,
    standard_generalization,
    similarity_via_transformations, entitled).
material_inference(similar_figures,
    "student reasons that figures are similar",
    similarity_via_transformations, entitled).
tier(ref(material_inference, similar_figures,
         similarity_via_transformations),
     2, [source(ccss, agrees), source(im, agrees)],
     "The standards root anchors grade-8 similarity through transformations; similar_figures is the misconception-owning concept.").

concept_relation(scale_drawings,
    misconception_family,
    similar_figures, entitled).
material_inference(scale_drawings,
    "student solves scale-drawing problems by preserving a scale factor",
    similar_figures, entitled).
tier(ref(material_inference, scale_drawings,
         similar_figures),
     2, [source(ccss, agrees), source(im, agrees), source(synthesizer, agrees)],
     "Scale drawings rely on the same multiplicative similarity commitments that own the additive-difference and visual-similarity misconception records.").

concept_relation(scale_drawings,
    grounded_by,
    similarity_as_uniform_scaling, entitled).
material_inference(scale_drawings,
    "student interprets a scale drawing as uniformly rescaling all corresponding lengths",
    similarity_as_uniform_scaling, entitled).
tier(ref(material_inference, scale_drawings,
         similarity_as_uniform_scaling),
     2, [source(ln, partial), source(ccss, agrees), source(im, agrees)],
     "The L&N measuring-stick extension for uniform scaling grounds the scale-factor commitments in grade-7 scale drawings.").

concept_relation(area_as_2d_unit_iteration,
    standard_generalization,
    partition_rectangle_rows_columns, entitled).
material_inference(area_as_2d_unit_iteration,
    "student measures area by iterating congruent unit squares across a region",
    partition_rectangle_rows_columns, entitled).
tier(ref(material_inference, area_as_2d_unit_iteration,
         partition_rectangle_rows_columns),
     2, [source(ccss, agrees), source(in_indiana, agrees), source(synthesizer, agrees)],
     "Area-as-unit-square iteration is the geometry monitoring parent for the grade-2 row-and-column rectangle partition standard anchors.").

concept_relation(area_as_2d_unit_iteration,
    misconception_family,
    area_as_array_structure, entitled).
material_inference(area_as_2d_unit_iteration,
    "student compresses square-unit tiling into rows, columns, and multiplication",
    area_as_array_structure, entitled).
tier(ref(material_inference, area_as_2d_unit_iteration,
         area_as_array_structure),
     2, [source(synthesizer, agrees), source(misconceptions_measurement_pl, agrees)],
     "The area array concept owns the no-gaps/no-overlaps tiling misconception records needed by the area_tiling_unit_iteration monitoring cluster.").

concept_relation(perimeter_as_boundary_traversal,
    grounded_by,
    length_measurement_as_unit_iteration, entitled).
material_inference(perimeter_as_boundary_traversal,
    "student measures the distance around a polygon by iterating linear units along every side",
    length_measurement_as_unit_iteration, entitled).
tier(ref(material_inference, perimeter_as_boundary_traversal,
         length_measurement_as_unit_iteration),
     2, [source(ln, partial), source(synthesizer, agrees)],
     "Perimeter is the boundary-length specialization of length measurement as unit iteration; the length concept owns the L&N measuring-stick metaphor record.").

concept_relation(points_lines_segments,
    prerequisite_for,
    points_lines_angles, entitled).
material_inference(points_lines_segments,
    "student identifies and draws points, lines, and segments before introducing rays and angles",
    points_lines_angles, entitled).
tier(ref(material_inference, points_lines_segments,
         points_lines_angles),
     2, [source(in_indiana, agrees), source(ccss, agrees), source(im, agrees)],
     "Indiana grade-3 point/line/segment vocabulary is the standards predecessor for the grade-4 points-lines-angles bundle used in IM-G4-U7.").

concept_relation(points_lines_angles,
    misconception_family,
    angle_measure_invariant_under_arm_length, entitled).
material_inference(points_lines_angles,
    "student identifies and measures angles by the opening between rays rather than drawn arm length",
    angle_measure_invariant_under_arm_length, entitled).
tier(ref(material_inference, points_lines_angles,
         angle_measure_invariant_under_arm_length),
     2, [source(fischbein_1999, agrees), source(ferrini_mundy_2007, agrees), source(synthesizer, agrees)],
     "The grade-4 angles bundle owns the instructional surface; angle_measure_invariant_under_arm_length owns the cited ray-length misconception records.").

concept_relation(points_lines_angles,
    grounded_by,
    geometric_rotation_as_motion, entitled).
material_inference(points_lines_angles,
    "student treats angle measure as a turn from one ray toward another around a shared vertex",
    geometric_rotation_as_motion, entitled).
tier(ref(material_inference, points_lines_angles,
         geometric_rotation_as_motion),
     3, [source(ln, partial), source(synthesizer, agrees)],
     "The lines_angles_precision monitoring cluster needs the L&N motion-along-a-path grounding for angle measure as turn; geometric_rotation_as_motion owns that Tier 3 metaphor record.").

concept_relation(circle_area_circumference,
    standard_generalization,
    triangles_circles_radius_diameter, entitled).
material_inference(circle_area_circumference,
    "student coordinates radius, diameter, circumference, and circle area",
    triangles_circles_radius_diameter, entitled).
tier(ref(material_inference, circle_area_circumference,
         triangles_circles_radius_diameter),
     2, [source(in_indiana, agrees), source(synthesizer, agrees)],
     "Circle area and circumference reasoning presupposes the grade-5 Indiana radius-diameter relationship already authored under triangles_circles_radius_diameter.").

concept_relation(circle_area_circumference,
    grounded_by,
    circle_circumference_formula, entitled).
material_inference(circle_area_circumference,
    "student informally derives circumference by iterating a unit along the circle boundary",
    circle_circumference_formula, entitled).
tier(ref(material_inference, circle_area_circumference,
         circle_circumference_formula),
     2, [source(n103_ch9, agrees), source(synthesizer, agrees)],
     "The N103 string-and-roll circumference activity supplies the measuring-stick metaphor support for the circle_measurement monitoring cluster.").

concept_relation(circle_area_circumference,
    misconception_family,
    area_as_interior_coverage, entitled).
material_inference(circle_area_circumference,
    "student compares circles by the two-dimensional region enclosed by the boundary",
    area_as_interior_coverage, entitled).
tier(ref(material_inference, circle_area_circumference,
         area_as_interior_coverage),
     2, [source(misconceptions_measurement_pl, agrees), source(synthesizer, agrees)],
     "The area-as-interior-coverage concept owns the diameter-as-area misconception used by circle measurement monitoring.").

concept_relation(volume_as_3d_unit_iteration,
    standard_generalization,
    volume_prism_fractional_edges, entitled).
material_inference(volume_as_3d_unit_iteration,
    "student fills a prism by iterating unit cubes or unit-fraction cubes",
    volume_prism_fractional_edges, entitled).
tier(ref(material_inference, volume_as_3d_unit_iteration,
         volume_prism_fractional_edges),
     2, [source(ccss, agrees), source(in_indiana, agrees), source(im, agrees)],
     "Volume-as-cubic-unit iteration is the monitoring parent for the grade-6 prism-volume standards already authored under volume_prism_fractional_edges.").

concept_relation(volume_as_3d_unit_iteration,
    grounded_by,
    volume_of_prism_formula, entitled).
material_inference(volume_as_3d_unit_iteration,
    "student compresses stacked unit-cube layers into base area times height",
    volume_of_prism_formula, entitled).
tier(ref(material_inference, volume_as_3d_unit_iteration,
         volume_of_prism_formula),
     2, [source(n103_ch4, agrees), source(synthesizer, agrees)],
     "The N103 stacked-block prism formula supplies the measuring-stick metaphor support for the volume_packing_layers monitoring cluster.").

concept_relation(volume_as_3d_unit_iteration,
    misconception_family,
    volume_as_filling_3d_space, entitled).
material_inference(volume_as_3d_unit_iteration,
    "student measures volume by counting cubic units filling the interior of a solid",
    volume_as_filling_3d_space, entitled).
tier(ref(material_inference, volume_as_3d_unit_iteration,
         volume_as_filling_3d_space),
     2, [source(misconceptions_measurement_pl, agrees), source(synthesizer, agrees)],
     "The volume-as-filling concept owns the visible-faces misconception records needed by the volume_packing_layers monitoring cluster.").

concept_relation(nets_surface_area,
    standard_generalization,
    area_volume_surface_area_problems, entitled).
material_inference(nets_surface_area,
    "student decomposes a solid into faces and sums their areas",
    area_volume_surface_area_problems, entitled).
tier(ref(material_inference, nets_surface_area,
         area_volume_surface_area_problems),
     2, [source(ccss, agrees), source(im, agrees), source(synthesizer, agrees)],
     "Nets for surface area are the grade-6 entry point for the grade-7 composite area, volume, and surface-area problem standard.").

concept_relation(nets_surface_area,
    grounded_by,
    surface_area_of_sphere, entitled).
material_inference(nets_surface_area,
    "student treats the surface of a three-dimensional object as a two-dimensional region to cover",
    surface_area_of_sphere, entitled).
tier(ref(material_inference, nets_surface_area,
         surface_area_of_sphere),
     2, [source(n103_ch9, agrees), source(synthesizer, agrees)],
     "The sphere surface-area record owns the measuring-stick schema for covering a 3D boundary with 2D units; nets use the same surface-coverage commitment with polygonal faces.").

concept_relation(nets_surface_area,
    misconception_family,
    surface_area_of_sphere, entitled).
material_inference(nets_surface_area,
    "student decides whether the task asks for all exterior faces or only a named side surface",
    lateral_vs_total_surface_confusion, entitled).
tier(ref(material_inference, nets_surface_area,
         lateral_vs_total_surface_confusion),
     3, [source(corpus_38052, agrees), source(synthesizer, agrees)],
     "The lateral-vs-total misconception is authored under surface_area_of_sphere because the harvested row is not net-specific; the same missing-total-surface commitment is needed for surface_area_nets monitoring.").

concept_relation(pythagorean_theorem,
    standard_generalization,
    pythagorean_distance_coordinates, entitled).
material_inference(pythagorean_theorem,
    "student constructs or reads a right triangle between coordinate points",
    pythagorean_distance_coordinates, entitled).
tier(ref(material_inference, pythagorean_theorem,
         pythagorean_distance_coordinates),
     2, [source(ccss, agrees), source(im, agrees), source(synthesizer, agrees)],
     "The grade-8 coordinate-distance standard is the coordinate-plane specialization of Pythagorean side-length reasoning.").

concept_relation(pythagorean_theorem,
    grounded_by,
    number_physical_segment_blend_for_irrationals, entitled).
material_inference(pythagorean_theorem,
    "student interprets the hypotenuse as a segment whose length is a number",
    number_physical_segment_blend_for_irrationals, entitled).
tier(ref(material_inference, pythagorean_theorem,
         number_physical_segment_blend_for_irrationals),
     2, [source(ln, agrees), source(synthesizer, agrees)],
     "L&N's number/physical-segment blend explicitly uses the unit-leg right triangle whose hypotenuse has length sqrt(2), grounding Pythagorean distance as segment length.").

concept_relation(line_of_symmetry,
    grounded_by,
    tracing_paper_diagnostic, entitled).
material_inference(line_of_symmetry,
    "student tests whether a line maps a figure to itself under reflection",
    tracing_paper_diagnostic, entitled).
tier(ref(material_inference, line_of_symmetry,
         tracing_paper_diagnostic),
     2, [source(n103, agrees), source(ln, partial)],
     "The tracing-paper diagnostic supplies the fictive-motion metaphor support for line-of-symmetry reasoning.").
