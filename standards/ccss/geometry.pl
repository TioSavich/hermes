% standards/ccss/geometry.pl — CCSS K-8.G anchored to geometry concepts.
% Schema: ../schema.pl
%
% Source: CCSS Mathematics K-8 Geometry domain, retrieved via Learning
% Commons Knowledge Graph (jurisdiction: California, which adopts CCSS
% verbatim for K-8.G). All statements are Tier 1 (verbatim from official
% CCSS published text).

:- multifile standard_anchor/4, tier/4.
:- discontiguous standard_anchor/4, tier/4.

%!  ccss_geometry_standard_witness(+ConceptId, +Code, -Witness) is semidet.
%
%   Inspectable witness for one row in the closed-world finite CCSS K-8
%   geometry anchor table. This proves membership in the loaded table; it is
%   not a general standards-alignment model for open-ended curricula.
ccss_geometry_standard_witness(ConceptId, Code, Witness) :-
    ccss_geometry_standard_fact(ConceptId, Code, Statement),
    ccss_geometry_standard_tier_fact(ConceptId,
                                     Code,
                                     Tier,
                                     Sources,
                                     SourceNote),
    ccss_geometry_concept_evidence(ConceptId,
                                   ConceptBoundary,
                                   ConceptEvidence),
    maplist(ccss_geometry_source_witness, Sources, SourceWitnesses),
    Witness = _{ kind: ccss_geometry_standard_anchor,
                 scope: closed_world_finite_ccss_geometry_standard_table,
                 concept: ConceptId,
                 framework: ccss,
                 code: Code,
                 statement: Statement,
                 tier: Tier,
                 sources: Sources,
                 source_witnesses: SourceWitnesses,
                 source_note: SourceNote,
                 concept_boundary: ConceptBoundary,
                 concept_evidence: ConceptEvidence,
                 boundary: finite_ccss_geometry_anchor_table_not_general_standards_model,
                 fact: standard_anchor(ConceptId, ccss, Code, Statement) }.

ccss_geometry_standard_fact(ConceptId, Code, Statement) :-
    Clause = standard_anchor(ConceptId, ccss, Code, Statement),
    clause(Clause, true, Ref),
    clause_property(Ref, file(File)),
    sub_atom(File, _, _, _, 'standards/ccss/geometry.pl').

ccss_geometry_standard_tier_fact(ConceptId, Code, Tier, Sources, SourceNote) :-
    Clause = tier(ref(standard, ConceptId, Code), Tier, Sources, SourceNote),
    clause(Clause, true, Ref),
    clause_property(Ref, file(File)),
    sub_atom(File, _, _, _, 'standards/ccss/geometry.pl').

ccss_geometry_concept_evidence(ConceptId,
                               loaded_geometry_concept_record,
    _{ kind: resolved_ccss_geometry_standard_concept,
       concept: ConceptId,
       name: Name,
       topic: Topic,
       grade_bands: GradeBands,
       fact: geom_concept(ConceptId, Name, Topic, GradeBands) }) :-
    geom_concept(ConceptId, Name, Topic, GradeBands).

ccss_geometry_source_witness(source(Source, Agreement),
    _{ kind: source_agreement,
       source: Source,
       agreement: Agreement }).

% ── Kindergarten (K.G) ───────────────────────────────────────────────

standard_anchor(shape_recognition_2d_3d, ccss, "K.G.A.1",
    "Describe objects in the environment using names of shapes, and describe the relative positions of these objects using terms such as above, below, beside, in front of, behind, and next to.").
tier(ref(standard, shape_recognition_2d_3d, "K.G.A.1"), 1, [source(ccss, agrees)], "verbatim from CCSS").

standard_anchor(orientation_invariant_naming, ccss, "K.G.A.2",
    "Correctly name shapes regardless of their orientations or overall size.").
tier(ref(standard, orientation_invariant_naming, "K.G.A.2"), 1, [source(ccss, agrees)], "verbatim from CCSS").

standard_anchor(shape_2d_vs_3d, ccss, "K.G.A.3",
    "Identify shapes as two-dimensional (lying in a plane, ""flat"") or three-dimensional (""solid"").").
tier(ref(standard, shape_2d_vs_3d, "K.G.A.3"), 1, [source(ccss, agrees)], "verbatim from CCSS").

standard_anchor(shape_attributes_informal, ccss, "K.G.B.4",
    "Analyze and compare two- and three-dimensional shapes, in different sizes and orientations, using informal language to describe their similarities, differences, parts (e.g., number of sides and vertices/""corners"") and other attributes (e.g., having sides of equal length).").
tier(ref(standard, shape_attributes_informal, "K.G.B.4"), 1, [source(ccss, agrees)], "verbatim from CCSS").

standard_anchor(model_shapes_from_components, ccss, "K.G.B.5",
    "Model shapes in the world by building shapes from components (e.g., sticks and clay balls) and drawing shapes.").
tier(ref(standard, model_shapes_from_components, "K.G.B.5"), 1, [source(ccss, agrees)], "verbatim from CCSS").

standard_anchor(compose_shapes_into_larger, ccss, "K.G.B.6",
    "Compose simple shapes to form larger shapes. For example, ""Can you join these two triangles with full sides touching to make a rectangle?""").
tier(ref(standard, compose_shapes_into_larger, "K.G.B.6"), 1, [source(ccss, agrees)], "verbatim from CCSS").

% ── Grade 1 (1.G) ────────────────────────────────────────────────────

standard_anchor(defining_vs_nondefining_attributes, ccss, "1.G.A.1",
    "Distinguish between defining attributes (e.g., triangles are closed and three-sided) versus non-defining attributes (e.g., color, orientation, overall size); build and draw shapes to possess defining attributes.").
tier(ref(standard, defining_vs_nondefining_attributes, "1.G.A.1"), 1, [source(ccss, agrees)], "verbatim from CCSS").

standard_anchor(compose_2d_3d_shapes, ccss, "1.G.A.2",
    "Compose two-dimensional shapes (rectangles, squares, trapezoids, triangles, half-circles, and quarter-circles) or three-dimensional shapes (cubes, right rectangular prisms, right circular cones, and right circular cylinders) to create a composite shape, and compose new shapes from the composite shape.").
tier(ref(standard, compose_2d_3d_shapes, "1.G.A.2"), 1, [source(ccss, agrees)], "verbatim from CCSS").

standard_anchor(partition_into_equal_shares, ccss, "1.G.A.3",
    "Partition circles and rectangles into two and four equal shares, describe the shares using the words halves, fourths, and quarters, and use the phrases half of, fourth of, and quarter of. Describe the whole as two of, or four of the shares. Understand for these examples that decomposing into more equal shares creates smaller shares.").
tier(ref(standard, partition_into_equal_shares, "1.G.A.3"), 1, [source(ccss, agrees)], "verbatim from CCSS").

% ── Grade 2 (2.G) ────────────────────────────────────────────────────

standard_anchor(draw_shapes_with_attributes, ccss, "2.G.A.1",
    "Recognize and draw shapes having specified attributes, such as a given number of angles or a given number of equal faces. Identify triangles, quadrilaterals, pentagons, hexagons, and cubes.").
tier(ref(standard, draw_shapes_with_attributes, "2.G.A.1"), 1, [source(ccss, agrees)], "verbatim from CCSS").

standard_anchor(partition_rectangle_rows_columns, ccss, "2.G.A.2",
    "Partition a rectangle into rows and columns of same-size squares and count to find the total number of them.").
tier(ref(standard, partition_rectangle_rows_columns, "2.G.A.2"), 1, [source(ccss, agrees)], "verbatim from CCSS").

standard_anchor(partition_into_equal_shares_thirds, ccss, "2.G.A.3",
    "Partition circles and rectangles into two, three, or four equal shares, describe the shares using the words halves, thirds, half of, a third of, etc., and describe the whole as two halves, three thirds, four fourths. Recognize that equal shares of identical wholes need not have the same shape.").
tier(ref(standard, partition_into_equal_shares_thirds, "2.G.A.3"), 1, [source(ccss, agrees)], "verbatim from CCSS").

% ── Grade 3 (3.G) ────────────────────────────────────────────────────

standard_anchor(quadrilateral_hierarchy, ccss, "3.G.A.1",
    "Understand that shapes in different categories (e.g., rhombuses, rectangles, and others) may share attributes (e.g., having four sides), and that the shared attributes can define a larger category (e.g., quadrilaterals). Recognize rhombuses, rectangles, and squares as examples of quadrilaterals, and draw examples of quadrilaterals that do not belong to any of these subcategories.").
tier(ref(standard, quadrilateral_hierarchy, "3.G.A.1"), 1, [source(ccss, agrees)], "verbatim from CCSS").

standard_anchor(partition_shapes_unit_fraction_area, ccss, "3.G.A.2",
    "Partition shapes into parts with equal areas. Express the area of each part as a unit fraction of the whole. For example, partition a shape into 4 parts with equal area, and describe the area of each part as 1/4 of the area of the shape.").
tier(ref(standard, partition_shapes_unit_fraction_area, "3.G.A.2"), 1, [source(ccss, agrees)], "verbatim from CCSS").

standard_anchor(perimeter_as_boundary_traversal, ccss, "3.MD.D.8",
    "Solve real world and mathematical problems involving perimeters of polygons, including finding the perimeter given the side lengths, finding an unknown side length, and exhibiting rectangles with the same perimeter and different areas or with the same area and different perimeters.").
tier(ref(standard, perimeter_as_boundary_traversal, "3.MD.D.8"), 1, [source(ccss, agrees)], "verbatim from CCSS").

% ── Grade 4 (4.G) ────────────────────────────────────────────────────

standard_anchor(points_lines_angles, ccss, "4.G.A.1",
    "Draw points, lines, line segments, rays, angles (right, acute, obtuse), and perpendicular and parallel lines. Identify these in two-dimensional figures.").
tier(ref(standard, points_lines_angles, "4.G.A.1"), 1, [source(ccss, agrees)], "verbatim from CCSS").

standard_anchor(classify_2d_figures_by_lines_angles, ccss, "4.G.A.2",
    "Classify two-dimensional figures based on the presence or absence of parallel or perpendicular lines, or the presence or absence of angles of a specified size. Recognize right triangles as a category, and identify right triangles.").
tier(ref(standard, classify_2d_figures_by_lines_angles, "4.G.A.2"), 1, [source(ccss, agrees)], "verbatim from CCSS").

standard_anchor(line_of_symmetry, ccss, "4.G.A.3",
    "Recognize a line of symmetry for a two-dimensional figure as a line across the figure such that the figure can be folded along the line into matching parts. Identify line-symmetric figures and draw lines of symmetry.").
tier(ref(standard, line_of_symmetry, "4.G.A.3"), 1, [source(ccss, agrees)], "verbatim from CCSS").

% ── Grade 5 (5.G) ────────────────────────────────────────────────────

standard_anchor(coordinate_system_axes, ccss, "5.G.A.1",
    "Use a pair of perpendicular number lines, called axes, to define a coordinate system, with the intersection of the lines (the origin) arranged to coincide with the 0 on each line and a given point in the plane located by using an ordered pair of numbers, called its coordinates. Understand that the first number indicates how far to travel from the origin in the direction of one axis, and the second number indicates how far to travel in the direction of the second axis, with the convention that the names of the two axes and the coordinates correspond.").
tier(ref(standard, coordinate_system_axes, "5.G.A.1"), 1, [source(ccss, agrees)], "verbatim from CCSS").

standard_anchor(graph_points_first_quadrant, ccss, "5.G.A.2",
    "Represent real world and mathematical problems by graphing points in the first quadrant of the coordinate plane, and interpret coordinate values of points in the context of the situation.").
tier(ref(standard, graph_points_first_quadrant, "5.G.A.2"), 1, [source(ccss, agrees)], "verbatim from CCSS").

standard_anchor(category_of_shapes_as_container, ccss, "5.G.B.3",
    "Understand that attributes belonging to a category of two-dimensional figures also belong to all subcategories of that category. For example, all rectangles have four right angles and squares are rectangles, so all squares have four right angles.").
tier(ref(standard, category_of_shapes_as_container, "5.G.B.3"), 1, [source(ccss, agrees)], "verbatim from CCSS").

standard_anchor(shape_hierarchy_classification, ccss, "5.G.B.4",
    "Classify two-dimensional figures in a hierarchy based on properties.").
tier(ref(standard, shape_hierarchy_classification, "5.G.B.4"), 1, [source(ccss, agrees)], "verbatim from CCSS").

% ── Grade 6 (6.G) ────────────────────────────────────────────────────

standard_anchor(area_compose_decompose_polygons, ccss, "6.G.A.1",
    "Find the area of right triangles, other triangles, special quadrilaterals, and polygons by composing into rectangles or decomposing into triangles and other shapes; apply these techniques in the context of solving real-world and mathematical problems.").
tier(ref(standard, area_compose_decompose_polygons, "6.G.A.1"), 1, [source(ccss, agrees)], "verbatim from CCSS").

standard_anchor(volume_prism_fractional_edges, ccss, "6.G.A.2",
    "Find the volume of a right rectangular prism with fractional edge lengths by packing it with unit cubes of the appropriate unit fraction edge lengths, and show that the volume is the same as would be found by multiplying the edge lengths of the prism. Apply the formulas V = l w h and V = b h to find volumes of right rectangular prisms with fractional edge lengths in the context of solving real-world and mathematical problems.").
tier(ref(standard, volume_prism_fractional_edges, "6.G.A.2"), 1, [source(ccss, agrees)], "verbatim from CCSS").

standard_anchor(polygons_in_coordinate_plane, ccss, "6.G.A.3",
    "Draw polygons in the coordinate plane given coordinates for the vertices; use coordinates to find the length of a side joining points with the same first coordinate or the same second coordinate. Apply these techniques in the context of solving real-world and mathematical problems.").
tier(ref(standard, polygons_in_coordinate_plane, "6.G.A.3"), 1, [source(ccss, agrees)], "verbatim from CCSS").

standard_anchor(nets_surface_area, ccss, "6.G.A.4",
    "Represent three-dimensional figures using nets made up of rectangles and triangles, and use the nets to find the surface area of these figures. Apply these techniques in the context of solving real-world and mathematical problems.").
tier(ref(standard, nets_surface_area, "6.G.A.4"), 1, [source(ccss, agrees)], "verbatim from CCSS").

% ── Grade 7 (7.G) ────────────────────────────────────────────────────

standard_anchor(scale_drawings, ccss, "7.G.A.1",
    "Solve problems involving scale drawings of geometric figures, including computing actual lengths and areas from a scale drawing and reproducing a scale drawing at a different scale.").
tier(ref(standard, scale_drawings, "7.G.A.1"), 1, [source(ccss, agrees)], "verbatim from CCSS").

standard_anchor(construct_triangles_from_conditions, ccss, "7.G.A.2",
    "Draw (freehand, with ruler and protractor, and with technology) geometric shapes with given conditions. Focus on constructing triangles from three measures of angles or sides, noticing when the conditions determine a unique triangle, more than one triangle, or no triangle.").
tier(ref(standard, construct_triangles_from_conditions, "7.G.A.2"), 1, [source(ccss, agrees)], "verbatim from CCSS").

standard_anchor(cross_sections_of_solids, ccss, "7.G.A.3",
    "Describe the two-dimensional figures that result from slicing three-dimensional figures, as in plane sections of right rectangular prisms and right rectangular pyramids.").
tier(ref(standard, cross_sections_of_solids, "7.G.A.3"), 1, [source(ccss, agrees)], "verbatim from CCSS").

standard_anchor(circle_area_circumference, ccss, "7.G.B.4",
    "Know the formulas for the area and circumference of a circle and use them to solve problems; give an informal derivation of the relationship between the circumference and area of a circle.").
tier(ref(standard, circle_area_circumference, "7.G.B.4"), 1, [source(ccss, agrees)], "verbatim from CCSS").

standard_anchor(angle_pair_relationships, ccss, "7.G.B.5",
    "Use facts about supplementary, complementary, vertical, and adjacent angles in a multi-step problem to write and solve simple equations for an unknown angle in a figure.").
tier(ref(standard, angle_pair_relationships, "7.G.B.5"), 1, [source(ccss, agrees)], "verbatim from CCSS").

standard_anchor(area_volume_surface_area_problems, ccss, "7.G.B.6",
    "Solve real-world and mathematical problems involving area, volume and surface area of two- and three-dimensional objects composed of triangles, quadrilaterals, polygons, cubes, and right prisms.").
tier(ref(standard, area_volume_surface_area_problems, "7.G.B.6"), 1, [source(ccss, agrees)], "verbatim from CCSS").

% ── Grade 8 (8.G) ────────────────────────────────────────────────────

standard_anchor(rigid_motion_properties, ccss, "8.G.A.1",
    "Verify experimentally the properties of rotations, reflections, and translations: a) Lines are taken to lines, and line segments to line segments of the same length. b) Angles are taken to angles of the same measure. c) Parallel lines are taken to parallel lines.").
tier(ref(standard, rigid_motion_properties, "8.G.A.1"), 1, [source(ccss, agrees)], "verbatim from CCSS").

standard_anchor(congruence_via_rigid_motions, ccss, "8.G.A.2",
    "Understand that a two-dimensional figure is congruent to another if the second can be obtained from the first by a sequence of rotations, reflections, and translations; given two congruent figures, describe a sequence that exhibits the congruence between them.").
tier(ref(standard, congruence_via_rigid_motions, "8.G.A.2"), 1, [source(ccss, agrees)], "verbatim from CCSS").

standard_anchor(transformations_on_coordinates, ccss, "8.G.A.3",
    "Describe the effect of dilations, translations, rotations, and reflections on two-dimensional figures using coordinates.").
tier(ref(standard, transformations_on_coordinates, "8.G.A.3"), 1, [source(ccss, agrees)], "verbatim from CCSS").

standard_anchor(similarity_via_transformations, ccss, "8.G.A.4",
    "Understand that a two-dimensional figure is similar to another if the second can be obtained from the first by a sequence of rotations, reflections, translations, and dilations; given two similar two-dimensional figures, describe a sequence that exhibits the similarity between them.").
tier(ref(standard, similarity_via_transformations, "8.G.A.4"), 1, [source(ccss, agrees)], "verbatim from CCSS").

standard_anchor(angle_sum_parallel_transversal, ccss, "8.G.A.5",
    "Use informal arguments to establish facts about the angle sum and exterior angle of triangles, about the angles created when parallel lines are cut by a transversal, and the angle-angle criterion for similarity of triangles.").
tier(ref(standard, angle_sum_parallel_transversal, "8.G.A.5"), 1, [source(ccss, agrees)], "verbatim from CCSS").

standard_anchor(pythagorean_theorem, ccss, "8.G.B.6",
    "Explain a proof of the Pythagorean Theorem and its converse.").
tier(ref(standard, pythagorean_theorem, "8.G.B.6"), 1, [source(ccss, agrees)], "verbatim from CCSS").

standard_anchor(pythagorean_theorem, ccss, "8.G.B.7",
    "Apply the Pythagorean Theorem to determine unknown side lengths in right triangles in real-world and mathematical problems in two and three dimensions.").
tier(ref(standard, pythagorean_theorem, "8.G.B.7"), 1, [source(ccss, agrees)], "verbatim from CCSS").

standard_anchor(pythagorean_distance_coordinates, ccss, "8.G.B.8",
    "Apply the Pythagorean Theorem to find the distance between two points in a coordinate system.").
tier(ref(standard, pythagorean_distance_coordinates, "8.G.B.8"), 1, [source(ccss, agrees)], "verbatim from CCSS").

standard_anchor(volume_cone_cylinder_sphere, ccss, "8.G.C.9",
    "Know the formulas for the volumes of cones, cylinders, and spheres and use them to solve real-world and mathematical problems.").
tier(ref(standard, volume_cone_cylinder_sphere, "8.G.C.9"), 1, [source(ccss, agrees)], "verbatim from CCSS").
