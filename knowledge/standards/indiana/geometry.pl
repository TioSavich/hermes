% knowledge/standards/indiana/geometry.pl — Indiana state geometry standards anchored to geometry concepts.
% Schema: ../schema.pl
%
% Source: Indiana Academic Standards for Mathematics (2014/2020 revision),
% retrieved via Learning Commons Knowledge Graph (jurisdiction: Indiana).
% Indiana K-5 uses the .G. domain (Geometry); grades 6-8 use .GM.
% (Geometry & Measurement). Note: in Indiana, codes like K.G.2, 2.G.5,
% 3.G.4, 5.G.2-5 belong to the Social Studies framework, not Mathematics;
% only the Mathematics geometry standards appear below.

:- multifile standard_anchor/4, tier/4.
:- discontiguous standard_anchor/4, tier/4.

%!  indiana_geometry_standard_witness(+ConceptId, +Code, -Witness) is semidet.
%
%   Inspectable witness for one row in the closed-world finite Indiana
%   mathematics geometry anchor table. This proves membership in the loaded
%   table; it is not a general standards-alignment model for open-ended
%   curricula.
indiana_geometry_standard_witness(ConceptId, Code, Witness) :-
    witness_dict:witness_dict(indiana_geometry_standard_anchor, closed_world_finite_indiana_geometry_standard_table,
                              _{concept: ConceptId,
                 framework: in_indiana,
                 code: Code,
                 statement: Statement,
                 tier: Tier,
                 sources: Sources,
                 source_witnesses: SourceWitnesses,
                 source_note: SourceNote,
                 concept_boundary: ConceptBoundary,
                 concept_evidence: ConceptEvidence,
                 boundary: finite_indiana_geometry_anchor_table_not_general_standards_model,
                 fact: standard_anchor(ConceptId, in_indiana, Code, Statement) }, WitnessDict31),
    indiana_geometry_standard_fact(ConceptId, Code, Statement),
    indiana_geometry_standard_tier_fact(ConceptId,
                                        Code,
                                        Tier,
                                        Sources,
                                        SourceNote),
    indiana_geometry_concept_evidence(ConceptId,
                                      ConceptBoundary,
                                      ConceptEvidence),
    maplist(indiana_geometry_source_witness, Sources, SourceWitnesses),
    Witness = WitnessDict31.

indiana_geometry_standard_fact(ConceptId, Code, Statement) :-
    Clause = standard_anchor(ConceptId, in_indiana, Code, Statement),
    clause(Clause, true, Ref),
    clause_property(Ref, file(File)),
    sub_atom(File, _, _, _, 'knowledge/standards/indiana/geometry.pl').

indiana_geometry_standard_tier_fact(ConceptId, Code, Tier, Sources, SourceNote) :-
    Clause = tier(ref(standard, ConceptId, Code), Tier, Sources, SourceNote),
    clause(Clause, true, Ref),
    clause_property(Ref, file(File)),
    sub_atom(File, _, _, _, 'knowledge/standards/indiana/geometry.pl').

indiana_geometry_concept_evidence(ConceptId,
                                  loaded_geometry_concept_record,
    _{ kind: resolved_indiana_geometry_standard_concept,
       concept: ConceptId,
       name: Name,
       topic: Topic,
       grade_bands: GradeBands,
       fact: geom_concept(ConceptId, Name, Topic, GradeBands) }) :-
    geom_concept(ConceptId, Name, Topic, GradeBands).

indiana_geometry_source_witness(source(Source, Agreement),
    _{ kind: source_agreement,
       source: Source,
       agreement: Agreement }).

% ── Kindergarten ─────────────────────────────────────────────────────

standard_anchor(shape_attributes_informal, in_indiana, "K.G.1",
    "Compare two- and three-dimensional shapes in different sizes and orientations, using informal language to describe their similarities, differences, parts (e.g., number of sides and vertices/""corners""), and other attributes (e.g., having sides of equal length).").
tier(ref(standard, shape_attributes_informal, "K.G.1"), 1, [source(in_indiana, agrees)], "verbatim from Indiana Academic Standards for Mathematics").

% ── Grade 1 ──────────────────────────────────────────────────────────

standard_anchor(defining_vs_nondefining_attributes, in_indiana, "1.G.1",
    "Distinguish between defining attributes of two- and three-dimensional shapes (e.g., triangles are closed and three-sided) versus non-defining attributes (e.g., color, orientation, overall size). Create and draw two-dimensional shapes with defining attributes.").
tier(ref(standard, defining_vs_nondefining_attributes, "1.G.1"), 1, [source(in_indiana, agrees)], "verbatim from Indiana Academic Standards for Mathematics").

standard_anchor(compose_2d_3d_shapes, in_indiana, "1.G.2",
    "Use two-dimensional shapes (e.g., rectangles, squares, trapezoids, triangles, half-circles, quarter-circles) or three-dimensional shapes (e.g., cubes, right rectangular prisms, right circular cones, and right circular cylinders) to create a composite shape, and compose new shapes from the composite shape. [In grade 1, students do not need to learn formal names such as ""right rectangular prism.""]").
tier(ref(standard, compose_2d_3d_shapes, "1.G.2"), 1, [source(in_indiana, agrees)], "verbatim from Indiana Academic Standards for Mathematics").

standard_anchor(partition_into_equal_shares, in_indiana, "1.G.3",
    "Partition circles and rectangles into two and four equal parts; describe the parts using the words halves, fourths, and quarters; and use the phrases half of, fourth of, and quarter of. Describe the whole as two of, or four of, the parts. Understand for partitioning circles and rectangles into two and four equal parts that decomposing into equal parts creates smaller parts.").
tier(ref(standard, partition_into_equal_shares, "1.G.3"), 1, [source(in_indiana, agrees)], "verbatim from Indiana Academic Standards for Mathematics").

% ── Grade 2 ──────────────────────────────────────────────────────────

standard_anchor(draw_shapes_with_attributes, in_indiana, "2.G.1",
    "Identify, describe, and classify two- and three-dimensional shapes (i.e., triangle, square, rectangle, cube, right rectangular prism) according to the number and shape of faces and the number of sides and/or vertices. Draw two-dimensional shapes.").
tier(ref(standard, draw_shapes_with_attributes, "2.G.1"), 1, [source(in_indiana, agrees)], "verbatim from Indiana Academic Standards for Mathematics").

standard_anchor(compose_decompose_shapes, in_indiana, "2.G.2",
    "Investigate and predict the result of composing and decomposing two- and three-dimensional shapes.").
tier(ref(standard, compose_decompose_shapes, "2.G.2"), 1, [source(in_indiana, agrees)], "verbatim from Indiana Academic Standards for Mathematics").

standard_anchor(partition_rectangle_rows_columns, in_indiana, "2.G.3",
    "Partition a rectangle into rows and columns of same-size (unit) squares and count to find the total number of same-size squares.").
tier(ref(standard, partition_rectangle_rows_columns, "2.G.3"), 1, [source(in_indiana, agrees)], "verbatim from Indiana Academic Standards for Mathematics").

standard_anchor(partition_into_equal_shares_thirds, in_indiana, "2.G.4",
    "Partition circles and rectangles into two, three, or four equal parts; describe the shares using the words halves, thirds, half of, a third of, etc.; and describe the whole as two halves, three thirds, or four fourths.").
tier(ref(standard, partition_into_equal_shares_thirds, "2.G.4"), 1, [source(in_indiana, agrees)], "verbatim from Indiana Academic Standards for Mathematics").

% ── Grade 3 ──────────────────────────────────────────────────────────

standard_anchor(quadrilateral_hierarchy, in_indiana, "3.G.1",
    "Define, identify, and classify four-sided shapes such as rhombuses, rectangles, and squares as quadrilaterals. Identify and draw examples and non-examples of quadrilaterals.").
tier(ref(standard, quadrilateral_hierarchy, "3.G.1"), 1, [source(in_indiana, agrees)], "verbatim from Indiana Academic Standards for Mathematics").

standard_anchor(points_lines_segments, in_indiana, "3.G.2",
    "Identify, describe, and draw points, lines, and line segments using appropriate tools (e.g., ruler, straightedge, and technology), and use these terms when describing two-dimensional shapes.").
tier(ref(standard, points_lines_segments, "3.G.2"), 1, [source(in_indiana, agrees)], "verbatim from Indiana Academic Standards for Mathematics").

standard_anchor(partition_shapes_unit_fraction_area, in_indiana, "3.G.3",
    "Partition shapes into parts with equal areas. Express the area of each part as a unit fraction of the whole (i.e., 1/2, 1/3, 1/4, 1/6, 1/8).").
tier(ref(standard, partition_shapes_unit_fraction_area, "3.G.3"), 1, [source(in_indiana, agrees)], "verbatim from Indiana Academic Standards for Mathematics").

standard_anchor(perimeter_as_boundary_traversal, in_indiana, "3.M.7",
    "Find perimeters of polygons given the side lengths or given an unknown side length.").
tier(ref(standard, perimeter_as_boundary_traversal, "3.M.7"), 1, [source(in_indiana, agrees)], "verbatim from Indiana Academic Standards for Mathematics").

% ── Grade 4 ──────────────────────────────────────────────────────────

standard_anchor(parallelogram_rhombus_trapezoid, in_indiana, "4.G.1",
    "Identify, describe, and draw parallelograms, rhombuses, and trapezoids using appropriate tools (e.g., ruler, straightedge, and technology).").
tier(ref(standard, parallelogram_rhombus_trapezoid, "4.G.1"), 1, [source(in_indiana, agrees)], "verbatim from Indiana Academic Standards for Mathematics").

standard_anchor(points_lines_angles, in_indiana, "4.G.2",
    "Identify, describe, and draw rays, angles (right, acute, obtuse), and perpendicular and parallel lines using appropriate tools (e.g., ruler, straightedge, and technology). Identify these in two-dimensional figures.").
tier(ref(standard, points_lines_angles, "4.G.2"), 1, [source(in_indiana, agrees)], "verbatim from Indiana Academic Standards for Mathematics").

standard_anchor(classify_2d_figures_by_lines_angles, in_indiana, "4.G.3",
    "Classify triangles and quadrilaterals based on the presence or absence of parallel or perpendicular lines, or right, acute, or obtuse angles.").
tier(ref(standard, classify_2d_figures_by_lines_angles, "4.G.3"), 1, [source(in_indiana, agrees)], "verbatim from Indiana Academic Standards for Mathematics").

% ── Grade 5 ──────────────────────────────────────────────────────────

standard_anchor(triangles_circles_radius_diameter, in_indiana, "5.G.1",
    "Identify, describe, and draw triangles (right, acute, obtuse) and circles using appropriate tools (e.g., ruler or straightedge, compass, and technology). Define and model the relationship between radius and diameter.").
tier(ref(standard, triangles_circles_radius_diameter, "5.G.1"), 1, [source(in_indiana, agrees)], "verbatim from Indiana Academic Standards for Mathematics").

% ── Grade 6 (GM = Geometry & Measurement) ────────────────────────────

standard_anchor(measurement_unit_conversion, in_indiana, "6.GM.1",
    "Convert between measurement systems (Customary to metric and metric to Customary) given the conversion factors, and use these conversions in solving real-world problems.").
tier(ref(standard, measurement_unit_conversion, "6.GM.1"), 1, [source(in_indiana, agrees)], "verbatim from Indiana Academic Standards for Mathematics").

standard_anchor(polygon_angle_sum_via_triangulation, in_indiana, "6.GM.2",
    "Apply the sums of interior angles of triangles and quadrilaterals to solve real-world and mathematical problems.").
tier(ref(standard, polygon_angle_sum_via_triangulation, "6.GM.2"), 1, [source(in_indiana, agrees)], "verbatim from Indiana Academic Standards for Mathematics").

standard_anchor(area_compose_decompose_polygons, in_indiana, "6.GM.3",
    "Find the area of complex shapes composed of polygons by composing or decomposing into simple shapes; apply this technique to solve real-world and other mathematical problems.").
tier(ref(standard, area_compose_decompose_polygons, "6.GM.3"), 1, [source(in_indiana, agrees)], "verbatim from Indiana Academic Standards for Mathematics").

standard_anchor(volume_prism_fractional_edges, in_indiana, "6.GM.4",
    "Find the volume of a right rectangular prism with fractional edge lengths using unit cubes of the appropriate unit fraction edge lengths (e.g., using technology or concrete materials) and show that the volume is the same as would be found by multiplying the edge lengths of the prism. Apply the formulas V = lwh and V = Bh to find volumes of right rectangular prisms with fractional edge lengths to solve real-world and other mathematical problems.").
tier(ref(standard, volume_prism_fractional_edges, "6.GM.4"), 1, [source(in_indiana, agrees)], "verbatim from Indiana Academic Standards for Mathematics").

% ── Grade 7 (GM = Geometry & Measurement) ────────────────────────────

standard_anchor(scale_drawings, in_indiana, "7.GM.1",
    "Solve real-world and other mathematical problems involving scale drawings of geometric figures, including computing actual lengths and areas from a scale drawing. Create a scale drawing by using proportional reasoning.").
tier(ref(standard, scale_drawings, "7.GM.1"), 1, [source(in_indiana, agrees)], "verbatim from Indiana Academic Standards for Mathematics").

standard_anchor(circle_area_circumference, in_indiana, "7.GM.2",
    "Understand the formulas for area and circumference of a circle and use them to solve real-world and other mathematical problems; give an informal derivation of the relationship between circumference and area of a circle.").
tier(ref(standard, circle_area_circumference, "7.GM.2"), 1, [source(in_indiana, agrees)], "verbatim from Indiana Academic Standards for Mathematics").

standard_anchor(volume_cylinders_prisms, in_indiana, "7.GM.3",
    "Solve real-world and other mathematical problems involving volume of cylinders and three-dimensional objects composed of right rectangular prisms.").
tier(ref(standard, volume_cylinders_prisms, "7.GM.3"), 1, [source(in_indiana, agrees)], "verbatim from Indiana Academic Standards for Mathematics").

% ── Grade 8 (GM = Geometry & Measurement) ────────────────────────────

standard_anchor(transformations_on_coordinates, in_indiana, "8.GM.1",
    "Explore dilations, translations, rotations, and reflections on two-dimensional figures in the coordinate plane.").
tier(ref(standard, transformations_on_coordinates, "8.GM.1"), 1, [source(in_indiana, agrees)], "verbatim from Indiana Academic Standards for Mathematics").

standard_anchor(volume_cone_cylinder_sphere, in_indiana, "8.GM.2",
    "Solve real-world and other mathematical problems involving volume of cones, spheres, and pyramids and surface area of spheres.").
tier(ref(standard, volume_cone_cylinder_sphere, "8.GM.2"), 1, [source(in_indiana, agrees)], "verbatim from Indiana Academic Standards for Mathematics").

standard_anchor(pythagorean_theorem, in_indiana, "8.GM.3",
    "Apply the Pythagorean Theorem to determine unknown side lengths in right triangles in real-world and other mathematical problems in two dimensions.").
tier(ref(standard, pythagorean_theorem, "8.GM.3"), 1, [source(in_indiana, agrees)], "verbatim from Indiana Academic Standards for Mathematics").
