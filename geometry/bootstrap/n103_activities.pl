% bootstrap/n103_activities.pl — activities from the N103 textbook chapters.
% Source: Aichele & Wolfe (2008) Geometric Structures, Pearson Prentice Hall.
% Schema: ../schema.pl

:- multifile bootstrap/6, tier/4.
:- discontiguous bootstrap/6, tier/4.

%!  n103_bootstrap_witness(+Id, -Witness) is semidet.
%
%   Inspectable witness for one bootstrap row in the closed-world finite N103
%   activity table. This proves local table membership and tier evidence; it is
%   not a general instructional-activity model.
n103_bootstrap_witness(Id, Witness) :-
    n103_bootstrap_fact(Id, Concept, Kind, Prompt, Tools, Transition),
    n103_bootstrap_tier_fact(Id, Tier, Sources, SourceNote),
    maplist(n103_source_witness, Sources, SourceWitnesses),
    Witness = _{ kind: geometry_n103_bootstrap_activity,
                 scope: closed_world_finite_n103_bootstrap_table,
                 id: Id,
                 concept: Concept,
                 kind_of_record: Kind,
                 prompt: Prompt,
                 tools: Tools,
                 transition: Transition,
                 tier: Tier,
                 sources: Sources,
                 source_witnesses: SourceWitnesses,
                 source_note: SourceNote,
                 boundary: finite_n103_bootstrap_table_not_general_activity_model,
                 fact: bootstrap(Id, Concept, Kind, Prompt, Tools, Transition) }.

n103_bootstrap_fact(Id, Concept, Kind, Prompt, Tools, Transition) :-
    Clause = bootstrap(Id, Concept, Kind, Prompt, Tools, Transition),
    clause(Clause, true, Ref),
    clause_property(Ref, file(File)),
    sub_atom(File, _, _, _, 'geometry/bootstrap/n103_activities.pl').

n103_bootstrap_tier_fact(Id, Tier, Sources, SourceNote) :-
    Clause = tier(ref(bootstrap, Id), Tier, Sources, SourceNote),
    clause(Clause, true, Ref),
    clause_property(Ref, file(File)),
    sub_atom(File, _, _, _, 'geometry/bootstrap/n103_activities.pl').

n103_source_witness(source(Source, Agreement),
    _{ kind: source_agreement,
       source: Source,
       agreement: Agreement }) :-
    !.
n103_source_witness(Source,
    _{ kind: source_reference,
       source: Source }).

% =====================================================================
% Chapter 1 — Polygons and Angle Relationships
% =====================================================================

bootstrap(n103_act_1_1_parallel_grid_triangle_sum,
    triangle_angle_sum_180,
    activity,
    "On a parallel-line grid of triangles, color all angles equal to angle A in one color, all equal to B in a second, all equal to C in a third. Notice the pattern around each vertex (each color appears twice on opposite sides of any straight line through the vertex). Argue that A+B+C = 180.",
    [parallel_line_grid, three_colored_markers],
    vH(1, 2)).

tier(ref(bootstrap, n103_act_1_1_parallel_grid_triangle_sum), 1,
     [n103_ch1],
     "N103 Activity 1.1. Visual coloring task; transitions vH 1 (visual) to vH 2 (analytic).").

bootstrap(n103_act_1_3_tearing_triangle_corners,
    triangle_angle_sum_180,
    activity,
    "Cut out a paper triangle. Tear off the three corners and rearrange them edge-to-edge. They form a straight line — visual demonstration that the angles sum to 180 degrees. Make a one-page display intended for kids' classroom.",
    [paper_triangles, glue_or_tape, colored_pencils],
    vH(1, 2)).

tier(ref(bootstrap, n103_act_1_3_tearing_triangle_corners), 1,
     [n103_ch1],
     "N103 Activity 1.3. Iconic kinesthetic move; produces classroom-ready visual artifact.").

bootstrap(n103_act_1_2_envelope_fold_triangle_sum,
    triangle_angle_sum_180,
    activity,
    "Cut out a triangle, fold the altitude from one vertex, then fold the apex down to the foot of the altitude (creating the midline). Finally fold the other two vertices into the foot. The result resembles an envelope and visually shows that all three angles together form a straight angle.",
    [paper_triangle],
    vH(1, 2)).

tier(ref(bootstrap, n103_act_1_2_envelope_fold_triangle_sum), 1,
     [n103_ch1],
     "N103 Activity 1.2. Paper-folding alternative to the tearing demonstration.").

bootstrap(n103_q_1_6_when_does_erikas_idea_work,
    polygon_angle_sum_via_triangulation,
    question,
    "Erika says: the number of triangles in a polygon is always two less than the number of sides. Sarah disagrees: she gets eight triangles when she connects each corner of an octagon to the opposite corner. Under what circumstances is the number of triangles in a polygon two less than the number of sides? Include pictures.",
    [paper, pencil],
    vH(2, 3)).

tier(ref(bootstrap, n103_q_1_6_when_does_erikas_idea_work), 1,
     [n103_ch1],
     "N103 Activity 1.6. Distinguishes fan-triangulation (n-2) from full diagonal triangulation. Surfaces the conditional structure of polygon-angle-sum reasoning.").

bootstrap(n103_q_1_13_convex_definition_choice,
    convex_polygon_n103,
    question,
    "Four ways to make sense of convexity are presented (rubber-band, kid's-crawl-space, reflex-angle, line-segment). Which would be easiest for elementary school kids to grasp? Why? Can the answer depend on individual talents?",
    [],
    none).

tier(ref(bootstrap, n103_q_1_13_convex_definition_choice), 1,
     [n103_ch1],
     "N103 Activity 1.13. Asks preservice teacher to think about pedagogical fit, not just mathematical equivalence.").

% =====================================================================
% Chapter 2 — Quadrilaterals and Their Definitions
% =====================================================================

bootstrap(n103_act_2_1_checking_quadrilateral_properties,
    n103_seven_quadrilateral_types,
    activity,
    "Given a sheet of cut-out quadrilaterals (rectangles, squares, parallelograms, rhombuses, kites, trapezoids, isosceles trapezoids), use a ruler, protractor, and paper folding to check which of six properties (P1-P6: opposite sides equal, opposite angles equal, diagonals equal, diagonals bisect each other, diagonals bisect angles, diagonal as line of symmetry) hold for each.",
    [paper_cutouts_quadrilaterals, ruler, protractor],
    vH(1, 2)).

tier(ref(bootstrap, n103_act_2_1_checking_quadrilateral_properties), 1,
     [n103_ch2],
     "N103 Activity 2.1. Property-by-property analysis — strong vH 1-to-2 transition exercise.").

bootstrap(n103_q_2_13_inclusive_or_exclusive,
    inclusive_definition,
    question,
    "Two definitions of trapezoid are commonly used: 'A quadrilateral with only one pair of parallel sides' (Webster's) versus 'A quadrilateral with at least one pair of parallel sides.' Which is inclusive, which is exclusive? Which does N103 adopt? Why does adopting one over the other matter for teaching elementary students?",
    [],
    vH(2, 3)).

tier(ref(bootstrap, n103_q_2_13_inclusive_or_exclusive), 1,
     [n103_ch2],
     "N103 Activity 2.13-2.14. The pedagogical commitment to inclusive definitions is explicit.").

bootstrap(n103_q_2_15_kite_equivalent_definitions,
    equivalent_definitions,
    question,
    "Several possible definitions of a kite are given (perpendicular diagonals; at least one pair of opposite congruent angles; at least one diagonal as line of symmetry; two separate pairs of adjacent congruent sides; one diagonal is perpendicular bisector of the other). For each, decide whether it is an equivalent definition of a kite, or whether it admits non-kite counterexamples.",
    [paper, ruler],
    vH(2, 3)).

tier(ref(bootstrap, n103_q_2_15_kite_equivalent_definitions), 1,
     [n103_ch2],
     "N103 Activity 2.15. Test of equivalent-definitions reasoning.").

bootstrap(n103_act_2_8_medial_quadrilateral_discovery,
    medial_quadrilateral,
    activity,
    "Cut out paper quadrilaterals of various types (kite, rhombus, parallelogram, isosceles trapezoid, scalene). For each, fold to find the midpoints of all four sides, then connect them. Discover that the medial quadrilateral is always a parallelogram, regardless of the starting quadrilateral. Investigate which starting shapes give medial rectangles, rhombuses, etc.",
    [paper_cutouts, ruler],
    vH(2, 3)).

tier(ref(bootstrap, n103_act_2_8_medial_quadrilateral_discovery), 1,
     [n103_ch2],
     "N103 Activity 2.8. Surprise-driven discovery of an invariant.").

% =====================================================================
% Chapter 3 — Constructions by Paper Folding
% =====================================================================

bootstrap(n103_cd_3_1_perpendicular_bisector,
    medial_quadrilateral,
    construction,
    "CD Problem (paper folding): construct the perpendicular bisector of a given segment, and describe in your own words the procedure used.",
    [paper, scissors],
    vH(2, 3)).

tier(ref(bootstrap, n103_cd_3_1_perpendicular_bisector), 1,
     [n103_ch3],
     "N103 Activity 3.1. CD = construct/describe; communication is the deliberate goal.").

bootstrap(n103_cd_3_4_equilateral_triangle_fold,
    equilateral_triangle,
    construction,
    "CD Problem: using paper folding, construct an equilateral triangle with a given segment AB as one side. Describe procedure.",
    [paper],
    vH(2, 3)).

tier(ref(bootstrap, n103_cd_3_4_equilateral_triangle_fold), 1,
     [n103_ch3],
     "N103 Activity 3.4. The 'measuring fold' is the trickiest of the three basic constructions.").

bootstrap(n103_act_3_6_circumscribing_circle,
    medial_quadrilateral,
    activity,
    "Fold the perpendicular bisectors of all three sides of a triangle. They meet at the circumcenter. Use a compass at the circumcenter to draw the circumscribed circle (which touches each vertex). Repeat for an obtuse triangle and discover when the circumcenter is inside, outside, or on the triangle.",
    [paper_triangle, compass],
    vH(2, 3)).

tier(ref(bootstrap, n103_act_3_6_circumscribing_circle), 1,
     [n103_ch3],
     "N103 Activity 3.6. Concurrence of perpendicular bisectors discovered empirically.").

bootstrap(n103_act_3_8_balance_point_centroid,
    medial_quadrilateral,
    activity,
    "Fold the three medians of a triangle. They meet at the balance point (centroid). Make a cardboard copy of the triangle, mark the centroid, poke a small hole, and verify that the triangle balances on a pencil tip there.",
    [paper_triangle, cardboard, pencil],
    vH(2, 3)).

tier(ref(bootstrap, n103_act_3_8_balance_point_centroid), 1,
     [n103_ch3],
     "N103 Activity 3.8. Names: balance point, center of gravity, centroid. Physical verification of mathematical claim.").

% =====================================================================
% Chapter 4 — Three-Dimensional Geometry
% =====================================================================

bootstrap(n103_act_4_1_envelope_tetrahedron,
    polyhedron,
    activity,
    "Take a sealed envelope. Draw both diagonals across it and cut out the part containing most of the flap. Fold and crease along marked lines. Open and fold one end into the other to form a solid figure (a tetrahedron). Count its faces, edges, and vertices.",
    [envelope, scissors],
    vH(1, 2)).

tier(ref(bootstrap, n103_act_4_1_envelope_tetrahedron), 1,
     [n103_ch4],
     "N103 Activity 4.1. Cheap-materials introduction to polyhedra.").

bootstrap(n103_act_4_8_eulers_formula_discovery,
    eulers_polyhedron_formula,
    activity,
    "For each of several polyhedra (triangular, square, pentagonal, hexagonal pyramids and prisms), count F (faces), V (vertices), E (edges) and tabulate. Compute F+V and compare to E. Notice the relationship: F+V-E = 2.",
    [polyhedron_models],
    vH(2, 3)).

tier(ref(bootstrap, n103_act_4_8_eulers_formula_discovery), 1,
     [n103_ch4],
     "N103 Activity 4.8. Pattern-recognition exercise leading to Euler's formula.").

bootstrap(n103_act_4_12_pyramid_into_cube,
    volume_of_pyramid_formula,
    activity,
    "Cut out and assemble three congruent square pyramids. Together they form a cube. Compute the area of the base and height for one pyramid, then derive: 3 * V_pyramid = V_cube = base*height, so V_pyramid = (1/3) * base * height.",
    [paper_pyramid_nets, scissors, tape],
    vH(2, 3)).

tier(ref(bootstrap, n103_act_4_12_pyramid_into_cube), 1,
     [n103_ch4],
     "N103 Activity 4.12. Concrete justification for the 1/3 factor in pyramid volume.").

bootstrap(n103_act_4_13_volume_by_filling,
    volume_of_pyramid_formula,
    activity,
    "Build hollow paper models of a prism and a pyramid with same base and height, plus a 1-cubic-inch scoop. Compute volumes by formula. Then physically fill each shape with material from a packet, scoop by scoop, to verify.",
    [paper_nets_for_prism_and_pyramid, packet_of_filler, scoop],
    vH(2, 3)).

tier(ref(bootstrap, n103_act_4_13_volume_by_filling), 1,
     [n103_ch4],
     "N103 Activity 4.13. 'What does volume really mean?' — concrete vs. formula.").

% =====================================================================
% Chapter 5 — Area
% =====================================================================

bootstrap(n103_act_5_3_cut_up_take_away,
    cut_up_area_method,
    activity,
    "Given a geoboard figure with area 6, find the area by two different methods (cut-up and take-away) and describe each procedure in writing.",
    [geoboard, dot_paper],
    vH(2, 3)).

tier(ref(bootstrap, n103_act_5_3_cut_up_take_away), 1,
     [n103_ch5],
     "N103 Activity 5.3. Multi-method demonstration is the pedagogical move.").

bootstrap(n103_act_5_5_julies_way,
    julies_way_area_method,
    activity,
    "Try Julie's method (divide a region completely into triangles, count, divide by 2) on multiple geoboard examples. Decide whether you believe Julie that the method always works. What evidence supports the method? What else could be done to be sure?",
    [geoboard, dot_paper],
    vH(2, 3)).

tier(ref(bootstrap, n103_act_5_5_julies_way), 3,
     [n103_ch5],
     "N103 Activity 5.5. N103-specific pedagogical artifact (Julie's method).").

bootstrap(n103_act_5_6_which_methods_work,
    critical_evaluation_of_methods,
    activity,
    "For each of eight different geoboard figures, mark which of five area methods (cut-up, take-away, Julie's Way, (1/2)*b*h, b*h) will work. Discuss which method is most generally applicable, which is least.",
    [geoboard, table_template],
    vH(2, 3)).

tier(ref(bootstrap, n103_act_5_6_which_methods_work), 1,
     [n103_ch5],
     "N103 Activity 5.6. Critical evaluation of methods is a Big Idea.").

% =====================================================================
% Chapter 6 — Geoboard Areas
% =====================================================================

bootstrap(n103_act_6_2_solid_tile_shapes,
    solid_tile_shape,
    activity,
    "Sort a collection of dot-paper figures into solid tile shapes vs not. For non-solid-tile-shapes, label why (not solid: holes, corner-only contact, missing tile attachment).",
    [dot_paper],
    vH(1, 2)).

tier(ref(bootstrap, n103_act_6_2_solid_tile_shapes), 3,
     [n103_ch6],
     "N103 Activity 6.2. Builds the N103-specific definitional scaffolding.").

bootstrap(n103_act_6_7_picks_formula_discovery,
    picks_formula,
    activity,
    "For several geoboard figures, calculate the area both directly (Pick's formula: I + E/2 - 1) and by another method (cut-up or take-away). Confirm Pick's formula, then explore what happens with non-simple figures.",
    [geoboard, dot_paper],
    vH(2, 3)).

tier(ref(bootstrap, n103_act_6_7_picks_formula_discovery), 1,
     [n103_ch6],
     "N103 Activity 6.7. Pattern-recognition leading to a famous theorem.").

bootstrap(n103_act_6_10_seans_idea,
    seans_idea_area_method,
    activity,
    "Test Sean's claim that area = sum of interior pegs (with edge pegs counted as 1/2 and corner pegs as 1/4). Use 'fat dot' paper to physically count partial pegs. Apply to rectangle, parallelogram, right triangle, then more complicated figures.",
    [dot_paper_with_fat_dots],
    vH(2, 3)).

tier(ref(bootstrap, n103_act_6_10_seans_idea), 3,
     [n103_ch6],
     "N103 Activity 6.10. N103-specific pedagogical artifact (Sean's idea).").

% =====================================================================
% Chapter 7 — Similarity and Slope
% =====================================================================

bootstrap(n103_act_7_8_measuring_proportionality,
    constant_of_proportionality,
    activity,
    "Given two pairs of similar figures, measure corresponding lengths in inches (first pair) and centimeters (second pair). Calculate ratios for each pair. Confirm that all corresponding-side ratios are equal (the constant of proportionality).",
    [ruler, calculator],
    vH(2, 3)).

tier(ref(bootstrap, n103_act_7_8_measuring_proportionality), 1,
     [n103_ch7],
     "N103 Activity 7.8.").

bootstrap(n103_q_7_12_wandas_sandbox,
    area_factor,
    question,
    "Wanda needs 1 ton of sand for her son's rectangular sandbox. If she doubles each side, how much sand will she need? Draw a diagram. Identify the length factor and area factor. (Volume factor for the deeper question.)",
    [],
    vH(2, 3)).

tier(ref(bootstrap, n103_q_7_12_wandas_sandbox), 1,
     [n103_ch7],
     "N103 Activity 7.12. Applied scaling-as-misconception probe.").

bootstrap(n103_act_7_14_scaling_volume,
    volume_factor,
    activity,
    "Take a unit cube. Double its dimensions. Stack unit cubes to physically build the resulting solid; count them — there are 8. Repeat with scale factor 3 (count 27). Generalize: volume factor = scale_factor^3.",
    [unit_cubes],
    vH(2, 3)).

tier(ref(bootstrap, n103_act_7_14_scaling_volume), 1,
     [n103_ch7],
     "N103 Activity 7.14.").

% =====================================================================
% Chapter 8 — Pythagorean Theorem
% =====================================================================

bootstrap(n103_act_8_1_right_triangle_of_squares,
    right_triangle_of_squares,
    activity,
    "Construct a right triangle on a geoboard. Build a square on each of the three sides. Calculate the area of each square (use any method). Notice and describe any relationship between the three areas.",
    [geoboard, dot_paper],
    vH(2, 3)).

tier(ref(bootstrap, n103_act_8_1_right_triangle_of_squares), 1,
     [n103_ch8],
     "N103 Activity 8.1. Pythagorean theorem stated visually before algebraically.").

bootstrap(n103_act_8_2_pythagorean_puzzles,
    pythagorean_theorem,
    activity,
    "Cut out two small squares (the legs' squares) into pieces along marked dotted lines. Rearrange the pieces to cover the large square (the hypotenuse's square). Draw the dissecting lines on the large square showing how you covered it.",
    [paper, scissors],
    vH(2, 3)).

tier(ref(bootstrap, n103_act_8_2_pythagorean_puzzles), 1,
     [n103_ch8],
     "N103 Activity 8.2. Tactile dissection proof of Pythagoras.").

% =====================================================================
% Chapter 9 — Geometry of Circles
% =====================================================================

bootstrap(n103_act_9_1_circumference_measure,
    circle_circumference_formula,
    activity,
    "For each of three to five round objects, measure the diameter with a ruler. Compute pi*d as the predicted circumference. Then physically measure the circumference (string-and-roll method, or rolling the object along a tabletop one full turn). Compare predicted to measured values.",
    [round_objects, ruler, string],
    vH(1, 2)).

tier(ref(bootstrap, n103_act_9_1_circumference_measure), 1,
     [n103_ch9],
     "N103 Activity 9.1. Establishes pi as a measured ratio, not an abstract symbol.").

bootstrap(n103_act_9_13_orange_surface_area,
    surface_area_of_sphere,
    activity,
    "Estimate the radius r of an orange. Draw five circles of radius r on paper. Peel the orange, breaking the skin into pieces. Cover the circles with the pieces. Discover that the orange's surface area equals about four such circles, hence 4*pi*r^2.",
    [orange, compass, ruler],
    vH(1, 2)).

tier(ref(bootstrap, n103_act_9_13_orange_surface_area), 1,
     [n103_ch9],
     "N103 Activity 9.13. Tactile derivation of sphere surface area formula.").

bootstrap(n103_act_9_7_law_of_thales,
    pi_as_irrational,
    activity,
    "Inside two circles, place three points each on the circle's edge. For each, draw lines from the point to both ends of a fixed diameter, forming an inscribed angle. Measure the inscribed angle. Discover: any inscribed angle subtending a diameter is exactly 90 degrees (the law of Thales).",
    [paper_circles, protractor],
    vH(2, 3)).

tier(ref(bootstrap, n103_act_9_7_law_of_thales), 1,
     [n103_ch9],
     "N103 Activity 9.7. Discovery via measurement.").

% =====================================================================
% Chapter 15 — Symmetry (Reflectional)
% =====================================================================

bootstrap(n103_act_15_1_fold_and_cut_heart,
    reflectional_symmetry,
    activity,
    "Fold a sheet of paper. Cut along a curve from the fold to make a heart shape. Unfold to verify line symmetry. Repeat for a butterfly, a gingerbread man. For each, identify the line of reflection.",
    [paper, scissors],
    vH(0, 1)).

tier(ref(bootstrap, n103_act_15_1_fold_and_cut_heart), 1,
     [n103_ch15, ccss_4g3],
     "N103 Activity 15.1. Iconic kindergarten/elementary symmetry activity, framed for the methods student.").

bootstrap(n103_act_15_3_orientation_test,
    orientation_same_or_opposite,
    activity,
    "For each of five pairs of figures, decide whether the two copies have the same or opposite orientation. Use tracing paper if uncertain — physically trace one and try to slide/rotate it to align with the other.",
    [tracing_paper, mira],
    vH(1, 2)).

tier(ref(bootstrap, n103_act_15_3_orientation_test), 1,
     [n103_ch15],
     "N103 Activity 15.3.").

bootstrap(n103_act_15_5_three_symmetry_lines,
    rotational_symmetry,
    activity,
    "Figure out how to fold a sheet of paper such that, no matter how you cut it, the unfolded result will have three lines of symmetry. (Hint: closely related to the six-pointed snowflake fold.)",
    [paper, scissors],
    vH(2, 3)).

tier(ref(bootstrap, n103_act_15_5_three_symmetry_lines), 1,
     [n103_ch15],
     "N103 Activity 15.5. Procedural-thinking puzzle.").

% =====================================================================
% Chapter 16 — Four Symmetries
% =====================================================================

bootstrap(n103_act_16_1_four_actions_diagnosis,
    four_kinds_principle,
    activity,
    "For each of several pairs of congruent figures, identify which of the four tracing-paper actions (translation, rotation, reflection, glide-reflection) takes one to the other. Use tracing paper or mira to check.",
    [tracing_paper, mira],
    vH(2, 3)).

tier(ref(bootstrap, n103_act_16_1_four_actions_diagnosis), 1,
     [n103_ch16],
     "N103 Activity 16.1.").

bootstrap(n103_act_16_5_combinations_of_reflections,
    combination_of_two_reflections,
    activity,
    "Reflect figure A through line L1 to get A'. Reflect A' through line L2 to get A''. (a) When L1 and L2 are parallel, what is the combined relationship between A and A''? (b) When L1 and L2 intersect? Measure distance and angle. Discover the 2d and 2*theta rules.",
    [tracing_paper, mira, protractor, ruler],
    vH(2, 3)).

tier(ref(bootstrap, n103_act_16_5_combinations_of_reflections), 1,
     [n103_ch16],
     "N103 Activity 16.5.").

bootstrap(n103_cd_16_9_find_center_of_rotation,
    point_image_segment,
    construction,
    "CD Problem: given two congruent triangles related by a rotation, use a mira (or compass + perpendicular bisectors) to find the center of rotation. Use tracing paper to verify. Describe the procedure used.",
    [mira, compass, tracing_paper],
    vH(2, 3)).

tier(ref(bootstrap, n103_cd_16_9_find_center_of_rotation), 1,
     [n103_ch16],
     "N103 Activity 16.9.").

bootstrap(n103_act_16_12_wallpaper_symmetries,
    glide_reflectional_symmetry,
    activity,
    "Given several wallpaper designs, mark all symmetries present using N103's notation: dashed lines for reflection, dots for rotation centers, arrows for translation, special dashed lines for glide-reflection. Identify which of the four symmetry types each design exhibits.",
    [wallpaper_design_handout, colored_pencils],
    vH(2, 3)).

tier(ref(bootstrap, n103_act_16_12_wallpaper_symmetries), 1,
     [n103_ch16],
     "N103 Activity 16.12.").
