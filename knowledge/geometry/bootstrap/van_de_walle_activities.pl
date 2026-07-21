% bootstrap/van_de_walle_activities.pl — named instructional activities from Van de Walle.
% Schema: ../schema.pl
%
% Source: Van de Walle, Karp, Bay-Williams, Elementary and Middle School
% Mathematics: Teaching Developmentally (9th ed.), Chapters 19 and 20.
% Pulled via NotebookLM 2026-05-03 (digger: van_de_walle).
% Backing corpus: ../corpus/van_de_walle_excerpts.md

:- multifile bootstrap/6, tier/4.
:- discontiguous bootstrap/6, tier/4.

%!  van_de_walle_bootstrap_witness(+Id, -Witness) is semidet.
%
%   Inspectable witness for one bootstrap row in the closed-world finite
%   Van de Walle activity table. This proves local table membership and tier
%   evidence; it is not a general instructional-activity model.
van_de_walle_bootstrap_witness(Id, Witness) :-
    witness_dict:witness_dict(geometry_van_de_walle_bootstrap_activity, closed_world_finite_van_de_walle_bootstrap_table,
                              _{id: Id,
                 concept: Concept,
                 kind_of_record: Kind,
                 prompt: Prompt,
                 tools: Tools,
                 transition: Transition,
                 tier: Tier,
                 sources: Sources,
                 source_witnesses: SourceWitnesses,
                 source_note: SourceNote,
                 boundary: finite_van_de_walle_bootstrap_table_not_general_activity_model,
                 fact: bootstrap(Id, Concept, Kind, Prompt, Tools, Transition) }, WitnessDict21),
    van_de_walle_bootstrap_fact(Id, Concept, Kind, Prompt, Tools, Transition),
    van_de_walle_bootstrap_tier_fact(Id, Tier, Sources, SourceNote),
    maplist(van_de_walle_source_witness, Sources, SourceWitnesses),
    Witness = WitnessDict21.

van_de_walle_bootstrap_fact(Id, Concept, Kind, Prompt, Tools, Transition) :-
    Clause = bootstrap(Id, Concept, Kind, Prompt, Tools, Transition),
    clause(Clause, true, Ref),
    clause_property(Ref, file(File)),
    sub_atom(File, _, _, _, 'knowledge/geometry/bootstrap/van_de_walle_activities.pl').

van_de_walle_bootstrap_tier_fact(Id, Tier, Sources, SourceNote) :-
    Clause = tier(ref(bootstrap, Id), Tier, Sources, SourceNote),
    clause(Clause, true, Ref),
    clause_property(Ref, file(File)),
    sub_atom(File, _, _, _, 'knowledge/geometry/bootstrap/van_de_walle_activities.pl').

van_de_walle_source_witness(source(Source, Agreement),
    _{ kind: source_agreement,
       source: Source,
       agreement: Agreement }) :-
    !.
van_de_walle_source_witness(Source,
    _{ kind: source_reference,
       source: Source }).

% ── Chapter 20 — Geometric Thinking and Geometric Concepts ───────────

bootstrap(vdw_act_20_01_shape_sorts,
    square_recognition,
    activity,
    "Each student selects a shape from a collection and describes interesting things about it. Students randomly select two shapes to compare for similarities and differences. As a group, choose a target shape and find all other shapes that follow the same rule (e.g., shapes with both curved and straight sides). Finish with a 'secret sort' where one student sorts by a hidden rule and the others guess it.",
    [assorted_2d_shape_cutouts],
    consolidate(0)).
tier(ref(bootstrap, vdw_act_20_01_shape_sorts), 1, [source(vdw, agrees)],
    "VdW Activity 20.1, p. 515-516. Canonical level-0 activity.").

bootstrap(vdw_act_20_02_property_lists_for_quadrilaterals,
    quadrilateral_classification,
    activity,
    "Assign each group a specific quadrilateral (parallelogram, rhombus, rectangle, or square). Students list every property they can find that applies to ALL shapes in their category, organized under headings: Sides, Angles, Diagonals, and Symmetries. Groups share to build a class list.",
    [shape_handouts, index_cards, mirrors, tracing_paper],
    vH(0, 1)).
tier(ref(bootstrap, vdw_act_20_02_property_lists_for_quadrilaterals), 1, [source(vdw, agrees)],
    "VdW Activity 20.2, p. 516. The level-0-to-level-1 bridge: shifts attention from individual shapes to property lists for whole classes.").

bootstrap(vdw_act_20_03_minimal_defining_lists,
    minimal_defining_list,
    activity,
    "Sequel to Activity 20.2. Once property lists are built, students find 'minimal defining lists' (MDLs) — subsets of the properties that are both DEFINING (any shape with all the listed properties must be that shape) and MINIMAL (removing any one property breaks definingness). Students test proposed lists by searching for counterexamples. Challenge: find more than one MDL per shape.",
    [property_lists_from_act_20_02],
    vH(1, 2)).
tier(ref(bootstrap, vdw_act_20_03_minimal_defining_lists), 1, [source(vdw, agrees)],
    "VdW Activity 20.3, p. 517. The level-1-to-level-2 bridge: introduces if-then reasoning, counterexamples, and the nature of definitions.").

bootstrap(vdw_act_20_04_shape_show_and_hunt,
    triangle_recognition,
    activity,
    "Tape a large target shape on the floor. Students name it and identify its attributes. They then hunt for items around the classroom or school that share that shape, take photos, and justify how each item is like the target shape.",
    [masking_tape, real_world_objects, digital_camera, shape_cutouts],
    consolidate(0)).
tier(ref(bootstrap, vdw_act_20_04_shape_show_and_hunt), 1, [source(vdw, agrees)],
    "VdW Activity 20.4, p. 519. Level-0 visual matching with embodied / environmental anchoring.").

bootstrap(vdw_act_20_05_whats_my_shape,
    quadrilateral_classification,
    question,
    "A leader hides a 'secret shape' in a folder. Other students ask only yes/no questions about properties to eliminate choices from a reference set until they can identify the secret shape.",
    [double_set_of_2d_shapes, file_folder],
    vH(0, 1)).
tier(ref(bootstrap, vdw_act_20_05_whats_my_shape), 1, [source(vdw, agrees)],
    "VdW Activity 20.5, p. 520. Forces level-1 property questions ('does it have four right angles?') instead of level-0 appearance questions.").

bootstrap(vdw_act_20_06_tangram_puzzles,
    polygon_recognition,
    activity,
    "Students use the seven tangram pieces to compose larger figures, learning how shapes combine to form other shapes.",
    [tangram_pieces, tangram_activity_page, virtual_tangram_applet],
    vH(0, 1)).
tier(ref(bootstrap, vdw_act_20_06_tangram_puzzles), 1, [source(vdw, agrees)],
    "VdW Activity 20.6, p. 521. Composition / decomposition of plane figures.").

bootstrap(vdw_act_20_07_mosaic_puzzle,
    polygon_recognition,
    activity,
    "Students use the seven-piece Mosaic Puzzle (containing five distinct angles) to compose and decompose shapes. They use what they know about shape properties to argue which combinations work.",
    [mosaic_puzzle_pieces, mosaic_puzzle_questions_activity_page],
    vH(0, 1)).
tier(ref(bootstrap, vdw_act_20_07_mosaic_puzzle), 1, [source(vdw, agrees)],
    "VdW Activity 20.7, p. 521.").

bootstrap(vdw_act_20_08_geoboard_copy,
    polygon_recognition,
    activity,
    "Students copy designs projected on a screen onto their own geoboards, beginning with simple one-band designs and progressing to complex composite shapes. Discussion focuses on properties such as parallel lines and symmetry.",
    [geoboards, geoboard_design_cards],
    vH(0, 1)).
tier(ref(bootstrap, vdw_act_20_08_geoboard_copy), 1, [source(vdw, agrees)],
    "VdW Activity 20.8, p. 522. Representation of shapes; bridge from physical to mental shape image.").

bootstrap(vdw_act_20_09_decomposing_on_the_geoboard,
    polygon_recognition,
    activity,
    "Students copy a large shape onto their geoboard, then decompose it into a specified number of smaller shapes (either congruent to each other or all of the same type).",
    [geoboards, decomposing_shapes_activity_page],
    vH(0, 1)).
tier(ref(bootstrap, vdw_act_20_09_decomposing_on_the_geoboard), 1, [source(vdw, agrees)],
    "VdW Activity 20.9, p. 523.").

bootstrap(vdw_act_20_10_mystery_definition,
    quadrilateral_classification,
    activity,
    "Students see three sets of shapes: those that fit a mystery definition, those that do not, and a mixed set. They formulate a definition consistent with the first two sets, then test it on the mixed set, justifying each choice.",
    [mystery_definition_activity_page],
    consolidate(1)).
tier(ref(bootstrap, vdw_act_20_10_mystery_definition), 1, [source(vdw, agrees)],
    "VdW Activity 20.10, p. 525. Forces level-1 property identification through positive and negative examples.").

bootstrap(vdw_act_20_11_triangle_sort,
    triangle_recognition,
    activity,
    "Teams sort a diverse collection of triangles into three discrete groups so that no triangle overlaps categories. They then find a second, entirely different criterion for sorting them into three groups (e.g., by angle then by side).",
    [assorted_triangles_activity_page],
    consolidate(1)).
tier(ref(bootstrap, vdw_act_20_11_triangle_sort), 1, [source(vdw, agrees)],
    "VdW Activity 20.11, p. 526. Defining-property analysis at level 1.").

bootstrap(vdw_act_20_12_diagonals_of_quadrilaterals,
    quadrilateral_classification,
    activity,
    "Students use card-stock strips joined by brass fasteners to explore how diagonal length, intersection point, and intersection angle determine the resulting quadrilateral. They determine which combinations produce parallelograms, rectangles, and rhombuses.",
    [card_stock_diagonal_strips, brass_fasteners, dot_paper_1cm],
    vH(1, 2)).
tier(ref(bootstrap, vdw_act_20_12_diagonals_of_quadrilaterals), 1, [source(vdw, agrees)],
    "VdW Activity 20.12, p. 527. Relationship between diagonal properties and shape class — level-1-to-2 bridge.").

bootstrap(vdw_act_20_13_constructing_three_dimensional_shapes,
    cube_class,
    activity,
    "Students build 3-D skeletal structures (cubes, prisms, pyramids) and discuss the rigidity of triangular components and the resulting surface area implications.",
    [coffee_stirrers_with_twist_ties, plastic_straws, rolled_newspaper_rods, masking_tape],
    vH(1, 2)).
tier(ref(bootstrap, vdw_act_20_13_constructing_three_dimensional_shapes), 1, [source(vdw, agrees)],
    "VdW Activity 20.13, p. 528. 3-D analysis at level 1-to-2.").

bootstrap(vdw_act_20_14_discovering_pi,
    polygon_recognition,
    activity,
    "Students measure the circumference and diameter of various circular objects, record both, then divide circumference by diameter to discover that the ratio is constant (pi).",
    [circular_objects, string, trundle_wheel, ruler],
    vH(1, 2)).
tier(ref(bootstrap, vdw_act_20_14_discovering_pi), 1, [source(vdw, agrees)],
    "VdW Activity 20.14, p. 528-529. Discovery of pi as an invariant ratio.").

bootstrap(vdw_act_20_15_true_or_false,
    quadrilateral_classification,
    question,
    "Students evaluate statements of the form 'If it is a ___, then it is also a ___' or 'All ___ are ___' and present arguments to support their evaluations.",
    [true_false_statements_activity_page],
    consolidate(2)).
tier(ref(bootstrap, vdw_act_20_15_true_or_false), 1, [source(vdw, agrees)],
    "VdW Activity 20.15, p. 530. Pure level-2 informal-deduction practice.").

bootstrap(vdw_act_20_16_pythagorean_relationship,
    triangle_recognition,
    activity,
    "Students draw right triangles, build squares on each leg and the hypotenuse, calculate the area of each square, and search for the mathematical relationship among the three areas.",
    [grid_paper_half_cm],
    vH(1, 2)).
tier(ref(bootstrap, vdw_act_20_16_pythagorean_relationship), 1, [source(vdw, agrees)],
    "VdW Activity 20.16, p. 530. Relationship-discovery at level 2.").

bootstrap(vdw_act_20_17_angle_sum_in_a_triangle,
    triangle_angle_sum,
    activity,
    "Students label the three angles of three congruent cut-out triangles, then arrange the triangles adjacently along a straight line so that the three angles meet at a point. They observe that the three angles together form a straight line and conjecture that the angle sum is 180 degrees.",
    [three_congruent_cutout_triangles],
    consolidate(2)).
tier(ref(bootstrap, vdw_act_20_17_angle_sum_in_a_triangle), 1, [source(vdw, agrees)],
    "VdW Activity 20.17, p. 531. Conjecture-and-informal-proof at level 2.").

bootstrap(vdw_act_20_18_triangle_midsegments,
    triangle_recognition,
    activity,
    "Using dynamic geometry software, students draw a triangle and a segment joining the midpoints of two sides. They measure lengths and angles, then drag the vertices to test conjectures about how the midsegment relates to the third side.",
    [dynamic_geometry_program],
    consolidate(2)).
tier(ref(bootstrap, vdw_act_20_18_triangle_midsegments), 1, [source(vdw, agrees)],
    "VdW Activity 20.18, p. 532.").

bootstrap(vdw_act_20_19_pattern_block_mirror_symmetry,
    reflectional_symmetry,
    activity,
    "Students explore line symmetry by placing a mirror perpendicular to a pattern-block design or picture, so that the reflection completes a symmetrical shape.",
    [pattern_blocks, mirrors],
    vH(0, 1)).
tier(ref(bootstrap, vdw_act_20_19_pattern_block_mirror_symmetry), 1, [source(vdw, agrees)],
    "VdW Activity 20.19, p. 533. Symmetry by reflection — embodied level-0/1 activity. Re-keyed from polygon_recognition (Q-006 resolution 2026-05-04).").

bootstrap(vdw_act_20_20_dot_grid_line_symmetry,
    line_of_symmetry,
    activity,
    "Students draw a line through dots on a grid (horizontal, vertical, or diagonal). They create a design entirely on one side touching the line, then construct its mirror image on the other side. They check the result with a mirror.",
    [dot_paper_1cm, dot_paper_isometric, mirror],
    consolidate(1)).
tier(ref(bootstrap, vdw_act_20_20_dot_grid_line_symmetry), 1, [source(vdw, agrees)],
    "VdW Activity 20.20, p. 533. Line-symmetry construction at level 1. Re-keyed from polygon_recognition (Q-006 resolution 2026-05-04).").

bootstrap(vdw_act_20_21_motion_man,
    rigid_motion_properties,
    activity,
    "Students use a two-sided figure ('Motion Man') to practice slides (translations), flips (reflections), and turns (rotations). The teacher displays two copies side by side, and students determine the combination of rigid motions that takes the first to match the second.",
    [two_sided_motion_man_copies],
    consolidate(1)).
tier(ref(bootstrap, vdw_act_20_21_motion_man), 1, [source(vdw, agrees)],
    "VdW Activity 20.21, p. 535-536. Rigid-motion vocabulary at level 1. Re-keyed from polygon_recognition (Q-006 resolution 2026-05-04).").

bootstrap(vdw_act_20_22_are_they_congruent,
    congruence_by_superposition,
    activity,
    "Students examine triangles drawn on a coordinate grid, find a matching congruent pair, and prove congruence by stating the rigid transformations needed to map one to the other.",
    [coordinate_grid_paper],
    vH(1, 2)).
tier(ref(bootstrap, vdw_act_20_22_are_they_congruent), 1, [source(vdw, agrees)],
    "VdW Activity 20.22, p. 536. Transformation-based congruence proof. Re-keyed from polygon_recognition (Q-006 resolution 2026-05-04).").

bootstrap(vdw_act_20_23_pentomino_positions,
    rotation,
    activity,
    "Students determine how many distinct grid positions each of the 12 pentomino pieces admits. Two positions count as the same if one can be obtained from the other without reflection or rotation.",
    [pentomino_pieces_12, grid_paper_2cm],
    vH(1, 2)).
tier(ref(bootstrap, vdw_act_20_23_pentomino_positions), 1, [source(vdw, agrees)],
    "VdW Activity 20.23, p. 538. Spatial-symmetry counting. Re-keyed from polygon_recognition (Q-006 resolution 2026-05-04); equivalence under reflection AND rotation.").

bootstrap(vdw_act_20_24_hidden_positions,
    polygon_recognition,
    activity,
    "Students use a coordinate grid to play a positional guessing game (e.g., 'Three in a Row' on grid intersections), developing readiness for coordinate geometry.",
    [coordinate_grid],
    vH(0, 1)).
tier(ref(bootstrap, vdw_act_20_24_hidden_positions), 3, [source(vdw, partial)],
    "VdW Activity 20.24, p. 538-539. Description partly inferred from main text and Appendix D — Tier 3 because the activity-box text was elided in NotebookLM's chunking.").

bootstrap(vdw_act_20_25_paths,
    polygon_recognition,
    activity,
    "Students draw different paths between two points on a grid, moving only toward the target (e.g., right or up). They write directions for each path, compare their lengths, and find paths with the greatest and fewest number of turns.",
    [grid_paper_2cm, colored_crayons],
    vH(0, 1)).
tier(ref(bootstrap, vdw_act_20_25_paths), 1, [source(vdw, agrees)],
    "VdW Activity 20.25, p. 540. Coordinate-readiness through directed paths.").

bootstrap(vdw_act_20_26_coordinate_slides,
    translation,
    activity,
    "Students plot points to make a shape, then add 6 to the x-coordinates to create a translated shape. They explore diagonal sliding by altering both x and y coordinates.",
    [grid_paper_1cm],
    vH(1, 2)).
tier(ref(bootstrap, vdw_act_20_26_coordinate_slides), 1, [source(vdw, agrees)],
    "VdW Activity 20.26, p. 540-541. Coordinate translations. Re-keyed from polygon_recognition (Q-006 resolution 2026-05-04).").

bootstrap(vdw_act_20_27_coordinate_reflections,
    reflection,
    activity,
    "Students draw a shape in the first quadrant, then reflect it across the y-axis and across the x-axis into other quadrants. They write the coordinates of all four images and observe the relationships among them.",
    [coordinate_grid_paper],
    vH(1, 2)).
tier(ref(bootstrap, vdw_act_20_27_coordinate_reflections), 1, [source(vdw, agrees)],
    "VdW Activity 20.27, p. 541. Coordinate reflections. Re-keyed from polygon_recognition (Q-006 resolution 2026-05-04).").

bootstrap(vdw_act_20_28_coordinate_dilations,
    similarity_as_uniform_scaling,
    activity,
    "Students create a shape, multiply each coordinate by 2 to plot a dilated shape, then by 1/2 to plot a third. They draw lines from the origin through corresponding vertices to observe the dilation pattern.",
    [coordinate_grid_paper],
    vH(1, 2)).
tier(ref(bootstrap, vdw_act_20_28_coordinate_dilations), 1, [source(vdw, agrees)],
    "VdW Activity 20.28, p. 542. Coordinate dilations from the origin. Re-keyed from polygon_recognition (Q-006 resolution 2026-05-04).").

bootstrap(vdw_act_20_29_finding_distance_with_pythagoras,
    triangle_recognition,
    activity,
    "Students use the Pythagorean theorem to find the distance between two points given by coordinates, computing length without drawing the segment.",
    [coordinate_grid],
    consolidate(2)).
tier(ref(bootstrap, vdw_act_20_29_finding_distance_with_pythagoras), 3, [source(vdw, partial)],
    "VdW Activity 20.29, p. 543. Description partly inferred from main text and Appendix D.").

bootstrap(vdw_act_20_30_can_you_remember,
    polygon_recognition,
    question,
    "Display a simple sketch for 5 seconds. Students try to reproduce it from visual memory. Show again so students can refine. Discuss which attributes helped them remember each shape.",
    [sketches_of_figures],
    vH(0, 1)).
tier(ref(bootstrap, vdw_act_20_30_can_you_remember), 1, [source(vdw, agrees)],
    "VdW Activity 20.30, p. 544. Visual-memory and attribute-attention.").

bootstrap(vdw_act_20_31_pentominoes,
    polygon_recognition,
    activity,
    "Students try to find every distinct pentomino — every shape formed by joining five squares edge-to-edge. Flips and rotations do not count as new shapes. (There are 12.)",
    [five_square_tiles, grid_paper_1cm],
    vH(1, 2)).
tier(ref(bootstrap, vdw_act_20_31_pentominoes), 1, [source(vdw, agrees)],
    "VdW Activity 20.31, p. 544. Spatial-visualization through enumeration.").

bootstrap(vdw_act_20_32_face_matching,
    cube_class,
    activity,
    "Given a 'Find a Shape' card showing 2-D faces, students find the corresponding 3-D solid (or vice versa). Single-face cards may be turned up one at a time as clues to identify the solid.",
    [face_matching_cards, three_d_solids],
    consolidate(1)).
tier(ref(bootstrap, vdw_act_20_32_face_matching), 1, [source(vdw, agrees)],
    "VdW Activity 20.32, p. 545. 2-D to 3-D shape correspondence.").

bootstrap(vdw_act_20_33_building_views,
    cube_class,
    activity,
    "Version 1: students build a 3-D structure from a plan and draw its elevation views (front, back, left, right). Version 2: students are given the elevations, build the structure, and draw its top-view plan.",
    [grid_paper_1cm, one_inch_blocks],
    vH(1, 2)).
tier(ref(bootstrap, vdw_act_20_33_building_views), 1, [source(vdw, agrees)],
    "VdW Activity 20.33, p. 545-546. Multi-view representation of 3-D shapes.").

bootstrap(vdw_act_20_34_three_dimensional_drawings,
    cube_class,
    activity,
    "Version 1: given a 3-D isometric drawing, students build the structure with blocks and draw a top-view plan. Version 2: given four elevations and a building plan, students construct the structure and draw the isometric view.",
    [isometric_grid_paper, isometric_dot_paper, blocks],
    vH(1, 2)).
tier(ref(bootstrap, vdw_act_20_34_three_dimensional_drawings), 1, [source(vdw, agrees)],
    "VdW Activity 20.34, p. 546. Isometric and orthographic views.").

bootstrap(vdw_act_20_35_search_for_platonic_solids,
    cube_class,
    activity,
    "Using regular polygons, students attempt to find every fully regular solid — one whose every face is the same regular polygon and whose every vertex meets the same number of faces. (There are five.)",
    [paper_equilateral_triangles, paper_squares, paper_regular_pentagons, paper_regular_hexagons, polydron_or_geofix_set],
    consolidate(2)).
tier(ref(bootstrap, vdw_act_20_35_search_for_platonic_solids), 1, [source(vdw, agrees)],
    "VdW Activity 20.35, p. 547. Discovery of the five Platonic solids.").

% ── Cross-level transition activities (curated by VdW pedagogy) ──────

bootstrap(vdw_sports_teams_metaphor,
    quadrilateral_hierarchy,
    question,
    "When students refuse a square as a rectangle (or refuse a parallelogram as a trapezoid), tell them: 'A student can be on two different sports teams. A square is an example of a quadrilateral that belongs to two other teams — it's a rectangle AND a rhombus AND a parallelogram.' Then walk through the property checks.",
    [],
    vH(1, 2)).
tier(ref(bootstrap, vdw_sports_teams_metaphor), 1, [source(vdw, agrees)],
    "VdW p. 524. The canonical inclusive-classification repair metaphor.").

% ── Chapter 19 — Measurement Concepts (geometry-adjacent) ────────────

bootstrap(vdw_act_19_16_using_physical_models_of_area_units,
    polygon_recognition,
    activity,
    "Before introducing area formulas, students cover surfaces of two-dimensional shapes with physical units (color tiles, index cards, sheets of newspaper, two-color counters, base-ten blocks). Eventually move to standard square units. Students measure desktops, books, bulletin boards, masking-tape regions on the floor.",
    [color_tiles, index_cards, newspaper_sheets, base_ten_blocks, masking_tape],
    consolidate(0)).
tier(ref(bootstrap, vdw_act_19_16_using_physical_models_of_area_units), 1, [source(vdw, agrees)],
    "VdW Activity 19.16, p. 496. Repair for the linear-vs-square-units misconception.").

bootstrap(vdw_act_19_19_fixed_areas_fixed_perimeters,
    polygon_recognition,
    activity,
    "Contrast activity to disentangle area and perimeter. In one phase students build many different rectangles with a fixed area and observe that the perimeter varies. In the next phase they build shapes with a fixed perimeter and observe that the area varies.",
    [color_tiles, grid_paper_1cm],
    consolidate(1)).
tier(ref(bootstrap, vdw_act_19_19_fixed_areas_fixed_perimeters), 1, [source(vdw, agrees)],
    "VdW Activity 19.19, p. 494-495. Repair for area-perimeter confusion.").

bootstrap(vdw_doorway_height_visualization,
    polygon_recognition,
    question,
    "When students confuse the height of a parallelogram or triangle with the slanted side, ask: 'If this figure slid into a room on the chosen base, what's the shortest doorway it could pass through without tipping?' That doorway height IS the perpendicular height to the base.",
    [],
    consolidate(1)).
tier(ref(bootstrap, vdw_doorway_height_visualization), 1, [source(vdw, agrees)],
    "VdW p. 497. Embodied repair for the height-vs-slanted-side misconception.").

bootstrap(vdw_broken_ruler_assessment,
    polygon_recognition,
    question,
    "Performance assessment of ruler understanding: give students a 'broken' ruler with the first two units missing. Ask them to measure an object. Note who says it is impossible because there is no zero, vs. who matches and counts whole units meaningfully starting wherever the object lies on the ruler.",
    [broken_ruler],
    consolidate(0)).
tier(ref(bootstrap, vdw_broken_ruler_assessment), 1, [source(vdw, agrees)],
    "VdW p. 490. Diagnostic assessment of the count-the-marks-vs-spaces misconception.").

bootstrap(vdw_angle_overlay_comparison,
    polygon_recognition,
    activity,
    "To repair the misconception that angle size depends on ray length: trace one angle on transparency or tracing paper and place it directly over another to compare. Be sure to compare angles whose rays differ in length so that students see the spread of the rays is what determines size, not the rays themselves.",
    [tracing_paper, transparency, ruler, prepared_angle_pairs],
    consolidate(1)).
tier(ref(bootstrap, vdw_angle_overlay_comparison), 1, [source(vdw, agrees)],
    "VdW p. 505. Repair for the angle-as-ray-length misconception.").
