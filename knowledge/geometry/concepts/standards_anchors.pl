% concepts/standards_anchors.pl — Wave 3.5 standards-reconciliation concept declarations.
% Schema: ../schema.pl
%
% Purpose: resolve the 84 dangling standard_anchor records flagged by the
% orphan_standard_anchor/3 validator (added 2026-05-03). The standards mapper
% (Wave 1) and the concept diggers (Wave 2 — VdW, N103, L&N, vH dissertation,
% misconception harvester) used disjoint ID conventions: standards-mapper IDs
% name pedagogical units at the grain of a standard's intended concept, while
% the diggers' IDs name finer-grained mathematical objects.
%
% Resolution per Tio's directive (2026-05-03 evening):
%   - direct/near-match standards re-anchored in knowledge/standards/*.pl (rule 1 / 2)
%   - genuine pedagogical-unit gaps declared here as new geom_concept/4
%     records (rule 3) so standards point at canonical concepts directly,
%     without is_an_alias_of indirection.
%
% Tier: all Tier 2 — anchored by the framework (CCSS / Indiana / IM) on one
% side and the synthesizer's judgment on the other that the pedagogical unit
% is real and not redundant with the existing finer-grained concepts.

:- multifile geom_concept/4, tier/4.
:- discontiguous geom_concept/4, tier/4.

% =====================================================================
% Kindergarten concepts (the K.G domain is broad informal recognition)
% =====================================================================

geom_concept(shape_recognition_2d_3d,
    "Recognizing and naming 2D and 3D shapes in the everyday environment using shape names and relative-position vocabulary",
    shape_recognition,
    [0]).
tier(ref(concept, shape_recognition_2d_3d), 2,
    [source(ccss, agrees), source(im, agrees), source(synthesizer, agrees)],
    "K.G.A.1 / IM-GK-U2 anchor — the K-level synthesis of polygon_recognition + three_d_shape_recognition + relative-position vocabulary.").

geom_concept(shape_2d_vs_3d,
    "Distinguishing two-dimensional (flat, lying in a plane) from three-dimensional (solid) shapes",
    shape_recognition,
    [0]).
tier(ref(concept, shape_2d_vs_3d), 2,
    [source(ccss, agrees), source(synthesizer, agrees)],
    "K.G.A.3 anchor — the dimensional distinction at the recognition level.").

geom_concept(shape_attributes_informal,
    "Comparing and analyzing 2D and 3D shapes using informal language about parts (sides, vertices, faces) and other attributes (equal-length sides)",
    attributes,
    [0,1]).
tier(ref(concept, shape_attributes_informal), 2,
    [source(ccss, agrees), source(in_indiana, agrees), source(im, agrees), source(synthesizer, agrees)],
    "K.G.B.4 / K.G.1 / IM-GK-U6 anchor — informal attribute language at the K level, prerequisite to defining_vs_nondefining_attributes.").

geom_concept(model_shapes_from_components,
    "Modeling shapes by building them from physical components (sticks, clay) and by drawing",
    shape_recognition,
    [0]).
tier(ref(concept, model_shapes_from_components), 2,
    [source(ccss, agrees), source(synthesizer, agrees)],
    "K.G.B.5 anchor — the constructive side of shape recognition; pedagogical unit that bootstrap activities target.").

geom_concept(compose_shapes_into_larger,
    "Composing simple shapes to form larger composite shapes (e.g., joining two triangles to make a rectangle)",
    shape_recognition,
    [0,1]).
tier(ref(concept, compose_shapes_into_larger), 2,
    [source(ccss, agrees), source(synthesizer, agrees)],
    "K.G.B.6 anchor — composition at K is informal; refined to compose_2d_3d_shapes at grade 1.").

% =====================================================================
% Grade 1 concepts
% =====================================================================

geom_concept(defining_vs_nondefining_attributes,
    "Distinguishing defining attributes (necessary for being a kind of shape, e.g., closed and three-sided for triangles) from non-defining attributes (color, orientation, overall size)",
    attributes,
    [1]).
tier(ref(concept, defining_vs_nondefining_attributes), 2,
    [source(ccss, agrees), source(in_indiana, agrees), source(im, agrees), source(synthesizer, agrees)],
    "1.G.A.1 / 1.G.1 / IM-G1-U3 anchor — the standards-side analog of definition_requires_necessary_and_sufficient_conditions, but at the grade-1 informal level.").

geom_concept(compose_2d_3d_shapes,
    "Composing 2D shapes (rectangles, squares, trapezoids, triangles, half-circles, quarter-circles) or 3D shapes (cubes, prisms, cones, cylinders) into composite shapes, and composing new shapes from the composite",
    shape_recognition,
    [1]).
tier(ref(concept, compose_2d_3d_shapes), 2,
    [source(ccss, agrees), source(in_indiana, agrees), source(synthesizer, agrees)],
    "1.G.A.2 / 1.G.2 anchor — grade-1 composition with named 2D and 3D parts.").

geom_concept(partition_into_equal_shares,
    "Partitioning circles and rectangles into two and four equal shares; using the words halves, fourths, quarters; understanding that more equal shares means smaller shares",
    area_perimeter,
    [1]).
tier(ref(concept, partition_into_equal_shares), 2,
    [source(ccss, agrees), source(in_indiana, agrees), source(im, agrees), source(synthesizer, agrees)],
    "1.G.A.3 / 1.G.3 / IM-G1-U7 anchor — the grade-1 fraction-prefiguration concept; precursor to partition_into_equal_shares_thirds and partition_shapes_unit_fraction_area.").

% =====================================================================
% Grade 2 concepts
% =====================================================================

geom_concept(draw_shapes_with_attributes,
    "Recognizing, drawing, and identifying shapes (triangles, quadrilaterals, pentagons, hexagons, cubes) by specified attributes such as numbers of angles, equal faces, sides, or vertices",
    shape_recognition,
    [2]).
tier(ref(concept, draw_shapes_with_attributes), 2,
    [source(ccss, agrees), source(in_indiana, agrees), source(im, agrees), source(synthesizer, agrees)],
    "2.G.A.1 / 2.G.1 / IM-G2-U3 anchor — grade-2 attribute-driven drawing and identification.").

geom_concept(compose_decompose_shapes,
    "Composing and decomposing 2D and 3D shapes; predicting the result of compositions and decompositions",
    shape_recognition,
    [2]).
tier(ref(concept, compose_decompose_shapes), 2,
    [source(in_indiana, agrees), source(synthesizer, agrees)],
    "2.G.2 anchor — Indiana-specific grade-2 composition/decomposition; CCSS treats this implicitly within 2.G.A.1.").

geom_concept(partition_rectangle_rows_columns,
    "Partitioning a rectangle into rows and columns of same-size unit squares and counting the total — the prefiguration of multiplication and area-as-array-structure",
    area_perimeter,
    [2,3]).
tier(ref(concept, partition_rectangle_rows_columns), 2,
    [source(ccss, agrees), source(in_indiana, agrees), source(synthesizer, agrees)],
    "2.G.A.2 / 2.G.3 anchor — directly prefigures area_as_array_structure (which is grade 3).").

geom_concept(partition_into_equal_shares_thirds,
    "Partitioning circles and rectangles into two, three, or four equal shares; using halves, thirds, fourths; recognizing that equal shares of identical wholes need not have the same shape",
    area_perimeter,
    [2]).
tier(ref(concept, partition_into_equal_shares_thirds), 2,
    [source(ccss, agrees), source(in_indiana, agrees), source(im, agrees), source(synthesizer, agrees)],
    "2.G.A.3 / 2.G.4 / IM-G2-U7 anchor — extends grade-1 partition_into_equal_shares to thirds and shape-independence-of-share-equality.").

% =====================================================================
% Grade 3 concepts
% =====================================================================

geom_concept(partition_shapes_unit_fraction_area,
    "Partitioning shapes into parts with equal areas and expressing the area of each part as a unit fraction of the whole",
    area_perimeter,
    [3]).
tier(ref(concept, partition_shapes_unit_fraction_area), 2,
    [source(ccss, agrees), source(in_indiana, agrees), source(synthesizer, agrees)],
    "3.G.A.2 / 3.G.3 anchor — fraction-as-area at grade 3, the formal successor of partition_into_equal_shares.").

geom_concept(points_lines_segments,
    "Identifying, describing, and drawing points, lines, and line segments using rulers, straightedges, and technology",
    shape_recognition,
    [3]).
tier(ref(concept, points_lines_segments), 2,
    [source(in_indiana, agrees), source(synthesizer, agrees)],
    "3.G.2 anchor — Indiana grade-3 vocabulary subset of CCSS 4.G.A.1; the points/lines/segments preliminary to angles.").

% =====================================================================
% Grade 4 concepts
% =====================================================================

geom_concept(points_lines_angles,
    "Drawing and identifying points, lines, line segments, rays, angles (right, acute, obtuse), and perpendicular and parallel lines in 2D figures",
    angles,
    [4]).
tier(ref(concept, points_lines_angles), 2,
    [source(ccss, agrees), source(in_indiana, agrees), source(im, agrees), source(synthesizer, agrees)],
    "4.G.A.1 / 4.G.2 / IM-G4-U7 anchor — the grade-4 geometric vocabulary bundle.").

geom_concept(classify_2d_figures_by_lines_angles,
    "Classifying 2D figures based on the presence or absence of parallel or perpendicular lines, or angles of a specified size; identifying right triangles as a category",
    classification,
    [4]).
tier(ref(concept, classify_2d_figures_by_lines_angles), 2,
    [source(ccss, agrees), source(in_indiana, agrees), source(synthesizer, agrees)],
    "4.G.A.2 / 4.G.3 anchor — grade-4 classification driven by line and angle relations; precursor to van Hiele level-2 hierarchical classification at grade 5.").

geom_concept(parallelogram_rhombus_trapezoid,
    "Identifying, describing, and drawing parallelograms, rhombuses, and trapezoids using rulers, straightedges, and technology",
    classification,
    [4]).
tier(ref(concept, parallelogram_rhombus_trapezoid), 2,
    [source(in_indiana, agrees), source(synthesizer, agrees)],
    "4.G.1 anchor — Indiana grade-4 named-quadrilateral set; cross-references rectangle_class, parallelogram_as_quadrilateral, rhombus_as_parallelogram, trapezoid_inclusive.").

% =====================================================================
% Grade 5 concepts
% =====================================================================

geom_concept(triangles_circles_radius_diameter,
    "Identifying, describing, and drawing triangles (right, acute, obtuse) and circles using straightedge and compass; defining the radius-diameter relationship",
    shape_recognition,
    [5]).
tier(ref(concept, triangles_circles_radius_diameter), 2,
    [source(in_indiana, agrees), source(synthesizer, agrees)],
    "5.G.1 anchor — Indiana grade-5 triangle-and-circle vocabulary.").

geom_concept(coordinate_system_axes,
    "Defining a coordinate system as a pair of perpendicular number lines (axes) intersecting at the origin; locating points by ordered pairs",
    coordinate_geometry,
    [5]).
tier(ref(concept, coordinate_system_axes), 2,
    [source(ccss, agrees), source(synthesizer, agrees)],
    "5.G.A.1 anchor — the grade-5 introduction of the coordinate plane; precursor to graph_points_first_quadrant.").

geom_concept(graph_points_first_quadrant,
    "Graphing points in the first quadrant of the coordinate plane and interpreting coordinate values in real-world and mathematical contexts",
    coordinate_geometry,
    [5]).
tier(ref(concept, graph_points_first_quadrant), 2,
    [source(ccss, agrees), source(im, agrees), source(synthesizer, agrees)],
    "5.G.A.2 / IM-G5-U7 anchor — the grade-5 graphing-points application of coordinate_system_axes.").

geom_concept(shape_hierarchy_classification,
    "Classifying 2D figures in a hierarchy based on properties — the grade-5 inclusive-classification standard, encompassing the quadrilateral hierarchy and beyond",
    classification,
    [5]).
tier(ref(concept, shape_hierarchy_classification), 2,
    [source(ccss, agrees), source(im, agrees), source(synthesizer, agrees)],
    "5.G.B.4 / IM-G5-U2 anchor — generalizes quadrilateral_hierarchy to all 2D figures; the standard-side parent of the van Hiele level-2 inclusion concept cluster.").

% =====================================================================
% Grade 6 concepts
% =====================================================================

geom_concept(area_compose_decompose_polygons,
    "Finding areas of triangles, special quadrilaterals, and other polygons by composing into rectangles or decomposing into triangles and other shapes",
    area_perimeter,
    [6]).
tier(ref(concept, area_compose_decompose_polygons), 2,
    [source(ccss, agrees), source(in_indiana, agrees), source(im, agrees), source(synthesizer, agrees)],
    "6.G.A.1 / 6.GM.3 / IM-G3-U1 / IM-G6-U1 anchor — the grade-6 compose/decompose method for polygon area; cross-references cut_up_area_method, take_away_area_method, area_conservation_under_transformation.").

geom_concept(volume_prism_fractional_edges,
    "Finding the volume of a right rectangular prism with fractional edge lengths by packing with unit-fraction unit cubes; applying V = lwh and V = Bh",
    volume_surface_area,
    [6]).
tier(ref(concept, volume_prism_fractional_edges), 2,
    [source(ccss, agrees), source(in_indiana, agrees), source(im, agrees), source(synthesizer, agrees)],
    "6.G.A.2 / 6.GM.4 / IM-G6-U4 anchor — fractional-edge specialization of volume_of_prism_formula; ties to volume_as_3d_unit_iteration.").

geom_concept(polygons_in_coordinate_plane,
    "Drawing polygons in the coordinate plane given vertex coordinates; using coordinates to find side lengths of axis-aligned segments",
    coordinate_geometry,
    [6]).
tier(ref(concept, polygons_in_coordinate_plane), 2,
    [source(ccss, agrees), source(im, agrees), source(synthesizer, agrees)],
    "6.G.A.3 / IM-G6-U7 anchor — coordinate-plane polygon work; precursor to pythagorean_distance_coordinates at grade 8.").

geom_concept(nets_surface_area,
    "Representing 3D figures using nets made of rectangles and triangles; using nets to find surface area",
    volume_surface_area,
    [6]).
tier(ref(concept, nets_surface_area), 2,
    [source(ccss, agrees), source(synthesizer, agrees)],
    "6.G.A.4 anchor — the net-and-surface-area concept; the entry point to surface area before grade 7's combined-solids work.").

% measurement_unit_conversion migrated to concepts/measurement.pl on
% 2026-05-04 as part of Q-007 resolution. The new measurement topic
% atom is its proper home; the old "no measurement topic" comment is
% obsolete after the 2026-05-03 schema extension.

% =====================================================================
% Grade 7 concepts
% =====================================================================

geom_concept(scale_drawings,
    "Solving problems involving scale drawings: computing actual lengths and areas from a scale drawing, and reproducing a drawing at a different scale",
    similarity_congruence,
    [7]).
tier(ref(concept, scale_drawings), 2,
    [source(ccss, agrees), source(in_indiana, agrees), source(im, agrees), source(synthesizer, agrees)],
    "7.G.A.1 / 7.GM.1 / IM-G7-U1 anchor — scale drawings; cross-references scale_factor, similar_figures, similarity_as_uniform_scaling.").

geom_concept(construct_triangles_from_conditions,
    "Drawing triangles from given conditions on three measures of angles or sides; noticing whether conditions determine a unique triangle, more than one, or no triangle",
    similarity_congruence,
    [7]).
tier(ref(concept, construct_triangles_from_conditions), 2,
    [source(ccss, agrees), source(synthesizer, agrees)],
    "7.G.A.2 anchor — the SSS/SAS/ASA/SSA exploration as construction; cross-references triangle_congruence_conditions.").

geom_concept(cross_sections_of_solids,
    "Describing the 2D figures that result from slicing 3D figures, especially right rectangular prisms and pyramids",
    volume_surface_area,
    [7]).
tier(ref(concept, cross_sections_of_solids), 2,
    [source(ccss, agrees), source(synthesizer, agrees)],
    "7.G.A.3 anchor — plane sections of solids; the 3D-to-2D slicing reasoning.").

geom_concept(circle_area_circumference,
    "Knowing and applying the formulas for area and circumference of a circle, and giving an informal derivation of the relationship between them",
    area_perimeter,
    [7]).
tier(ref(concept, circle_area_circumference), 2,
    [source(ccss, agrees), source(in_indiana, agrees), source(im, agrees), source(synthesizer, agrees)],
    "7.G.B.4 / 7.GM.2 / IM-G7-U3 anchor — the standards-side combined unit; cross-references circle_area_formula, circle_circumference_formula, pi_as_irrational.").

geom_concept(angle_pair_relationships,
    "Using facts about supplementary, complementary, vertical, and adjacent angles to write and solve equations for unknown angles",
    angles,
    [7]).
tier(ref(concept, angle_pair_relationships), 2,
    [source(ccss, agrees), source(im, agrees), source(synthesizer, agrees)],
    "7.G.B.5 / IM-G7-U7 anchor — supplementary/complementary/vertical/adjacent angle problem-solving; cross-references supplementary_angles, vertical_angles_equal, four_kinds_of_related_angles.").

geom_concept(area_volume_surface_area_problems,
    "Solving real-world and mathematical problems involving area, volume, and surface area of 2D and 3D objects composed of triangles, quadrilaterals, polygons, cubes, and right prisms",
    volume_surface_area,
    [7]).
tier(ref(concept, area_volume_surface_area_problems), 2,
    [source(ccss, agrees), source(synthesizer, agrees)],
    "7.G.B.6 anchor — composite-solid problem-solving at grade 7; the integrative standard tying area_compose_decompose_polygons to volume work.").

geom_concept(volume_cylinders_prisms,
    "Solving real-world and mathematical problems involving the volume of cylinders and 3D objects composed of right rectangular prisms",
    volume_surface_area,
    [7]).
tier(ref(concept, volume_cylinders_prisms), 2,
    [source(in_indiana, agrees), source(synthesizer, agrees)],
    "7.GM.3 anchor — Indiana-specific cylinder-and-prism volume; cross-references volume_of_cylinder, volume_of_prism_formula.").

% =====================================================================
% Grade 8 concepts
% =====================================================================

geom_concept(rigid_motion_properties,
    "Verifying experimentally the properties of rotations, reflections, and translations: lines to lines, segments to congruent segments, angles to congruent angles, parallels to parallels",
    transformations,
    [8]).
tier(ref(concept, rigid_motion_properties), 2,
    [source(ccss, agrees), source(im, agrees), source(synthesizer, agrees)],
    "8.G.A.1 / IM-G8-U1 anchor — the grade-8 properties bundle for rigid motions; cross-references translation, reflection, rotation.").

geom_concept(congruence_via_rigid_motions,
    "Understanding that two figures are congruent iff one can be obtained from the other by a sequence of rotations, reflections, and translations; describing such a sequence for given congruent figures",
    similarity_congruence,
    [8]).
tier(ref(concept, congruence_via_rigid_motions), 2,
    [source(ccss, agrees), source(synthesizer, agrees)],
    "8.G.A.2 anchor — the transformational definition of congruence; modern successor to congruence_by_superposition.").

geom_concept(transformations_on_coordinates,
    "Describing the effect of dilations, translations, rotations, and reflections on 2D figures using coordinates",
    transformations,
    [8]).
tier(ref(concept, transformations_on_coordinates), 2,
    [source(ccss, agrees), source(in_indiana, agrees), source(synthesizer, agrees)],
    "8.G.A.3 / 8.GM.1 anchor — coordinate-side description of transformations.").

geom_concept(similarity_via_transformations,
    "Understanding that two figures are similar iff one can be obtained from the other by a sequence of rotations, reflections, translations, and dilations; describing such a sequence for given similar figures",
    similarity_congruence,
    [8]).
tier(ref(concept, similarity_via_transformations), 2,
    [source(ccss, agrees), source(im, agrees), source(synthesizer, agrees)],
    "8.G.A.4 / IM-G8-U2 anchor — the transformational definition of similarity; cross-references similar_figures, similarity_as_uniform_scaling, scale_factor.").

geom_concept(angle_sum_parallel_transversal,
    "Establishing informally the angle sum and exterior angle of triangles; the angles formed when parallel lines are cut by a transversal; and the AA criterion for similarity of triangles",
    angles,
    [8]).
tier(ref(concept, angle_sum_parallel_transversal), 2,
    [source(ccss, agrees), source(synthesizer, agrees)],
    "8.G.A.5 anchor — the parallel-and-transversal angle bundle plus AA similarity; cross-references triangle_angle_sum_180, alternate_interior_angles, corresponding_angles, aaa_similarity_for_triangles.").

geom_concept(pythagorean_distance_coordinates,
    "Applying the Pythagorean Theorem to find the distance between two points in a coordinate system",
    coordinate_geometry,
    [8]).
tier(ref(concept, pythagorean_distance_coordinates), 2,
    [source(ccss, agrees), source(synthesizer, agrees)],
    "8.G.B.8 anchor — the distance-formula reading of pythagorean_theorem in coordinate geometry.").

geom_concept(volume_cone_cylinder_sphere,
    "Knowing and applying the formulas for volumes of cones, cylinders, and spheres in real-world and mathematical problems",
    volume_surface_area,
    [8]).
tier(ref(concept, volume_cone_cylinder_sphere), 2,
    [source(ccss, agrees), source(in_indiana, agrees), source(im, agrees), source(synthesizer, agrees)],
    "8.G.C.9 / 8.GM.2 / IM-G8-U5 anchor — the grade-8 volume-formulas bundle; cross-references volume_of_cone, volume_of_cylinder, volume_of_sphere_formula.").
