% concepts/angles.pl — geometry concepts in the angles topic.
%
% Append clauses for: geom_concept/4, geom_misconception/6,
%                     material_inference/4, tier/4 (covering all of these).
% Cross-tagging (van_hiele_marker, metaphor_source, bootstrap,
% standard_anchor) lives in the corresponding subdirs.
%
% Schema: ../schema.pl

:- multifile geom_concept/4, geom_misconception/6, material_inference/4, tier/4.
:- discontiguous geom_concept/4, geom_misconception/6, material_inference/4, tier/4,
               angle_material_claim/5.

%!  angle_material_claim_witness(+Id, -Witness) is semidet.
%
%   Inspectable proof object for a finite angle-geometry material row.
angle_material_claim_witness(Id, Witness) :-
    witness_dict:witness_dict(geometry_angle_material_inference, closed_world_finite_angle_table,
                              _{id: Id,
                 concept: Concept,
                 premise: Premise,
                 conclusion: Conclusion,
                 polarity: Polarity,
                 concept_tier_boundary: ConceptTierBoundary,
                 concept_tier_evidence: ConceptTierEvidence,
                 boundary: finite_angle_curriculum_claim_not_general_euclidean_geometry,
                 condition_roles: Roles,
                 related_misconception_witnesses: MisconceptionWitnesses,
                 fact: material_inference(Concept, Premise, Conclusion, Polarity) }, WitnessDict24),
    angle_material_claim(Id, Concept, Premise, Conclusion, Polarity),
    angle_concept_tier_evidence(Concept,
                                ConceptTierBoundary,
                                ConceptTierEvidence),
    angle_related_misconception_witnesses(Concept, MisconceptionWitnesses),
    angle_condition_roles(Id, Roles),
    Witness = WitnessDict24.

angle_concept_tier_evidence(Concept,
                            loaded_concept_tier_record,
                            TierEvidence) :-
    findall(_{ tier: Tier,
               sources: Sources,
               source_note: SourceNote },
            tier(ref(concept, Concept), Tier, Sources, SourceNote),
            TierEvidence),
    TierEvidence \== [],
    !.
angle_concept_tier_evidence(_Concept,
                            no_concept_tier_record_in_loaded_geometry_schema,
                            []).

angle_related_misconception_witnesses(Concept, Witnesses) :-
    findall(Witness,
            angle_misconception_witness(Concept, Witness),
            RawWitnesses),
    sort(RawWitnesses, Witnesses).

angle_misconception_witness(Concept,
    _{ kind: geometry_angle_misconception_support,
       id: Id,
       concept: Concept,
       name: Name,
       tier: Tier,
       sources: Sources,
       source_note: SourceNote,
       fact: geom_misconception(Id, Concept, Name, Triggers, Repair, Citation),
       triggers: Triggers,
       repair: Repair,
       citation: Citation,
       triangulation_evidence: TriangulationEvidence }) :-
    geom_misconception(Id, Concept, Name, Triggers, Repair, Citation),
    angle_triangulation_evidence(Id, TriangulationEvidence),
    tier(ref(misconception, Id), Tier, Sources, SourceNote).

angle_triangulation_evidence(Id, Evidence) :-
    findall(_{ record: ref(misconception, Id),
               agreement: Agreement },
            triangulation(ref(misconception, Id), Agreement),
            RawEvidence),
    sort(RawEvidence, Evidence).

angle_condition_roles(polygon_sum_over_triangle_sum,
                      [ _{ kind: sufficiency_component,
                           role: fan_triangulation_from_one_vertex },
                        _{ kind: sufficiency_component,
                           role: n_minus_two_triangle_count }
                      ]) :-
    !.
angle_condition_roles(convexity_reflex_angle_test,
                      [ _{ kind: sufficiency_component,
                           role: reflex_angle_present },
                        _{ kind: classification_component,
                           role: non_convex_polygon }
                      ]) :-
    !.
angle_condition_roles(convexity_line_segment_test,
                      [ _{ kind: sufficiency_component,
                           role: all_interior_endpoint_segments_remain_inside },
                        _{ kind: classification_component,
                           role: convex_polygon }
                      ]) :-
    !.
angle_condition_roles(angle_measure_congruence_invariance,
                      [ _{ kind: sufficiency_component,
                           role: equal_angle_measure },
                        _{ kind: invariance_component,
                           role: arm_length_does_not_change_congruence }
                      ]) :-
    !.
angle_condition_roles(angle_measure_rejects_longer_arms,
                      [ _{ kind: incompatibility_component,
                           role: arm_length_does_not_determine_angle_measure }
                      ]) :-
    !.
angle_condition_roles(angle_requires_two_rays,
                      [ _{ kind: incompatibility_component,
                           role: one_ray_is_not_an_angle },
                        _{ kind: necessary_condition,
                           role: two_rays_share_vertex }
                      ]) :-
    !.
angle_condition_roles(triangle_sum_rejects_size_dependence,
                      [ _{ kind: incompatibility_component,
                           role: triangle_angle_sum_invariant_under_size }
                      ]) :-
    !.
angle_condition_roles(corresponding_angles_require_parallel_lines,
                      [ _{ kind: incompatibility_component,
                           role: equality_theorem_requires_parallel_lines },
                        _{ kind: distinction_component,
                           role: positional_angle_definition_not_measure_equality }
                      ]) :-
    !.
angle_condition_roles(_, []).

material_inference(Concept, Premise, Conclusion, Polarity) :-
    angle_material_claim_witness(_Id, Witness),
    get_dict(fact, Witness, material_inference(Concept,
                                               Premise,
                                               Conclusion,
                                               Polarity)).

% =====================================================================
% N103 (Aichele & Wolfe 2008) — Chapter 1 angle concepts
% =====================================================================

geom_concept(triangle_angle_sum_180,
    "The angles of any triangle sum to 180 degrees",
    angles,
    [4,5,6,7,8]).

tier(ref(concept, triangle_angle_sum_180), 1,
     [n103_ch1, ccss_8g5],
     "N103 gives three concrete justifications before the formula: parallel-line grid, envelope fold, and tearing-and-rearranging. Anchor for vH level 2/3 transition.").

geom_concept(polygon_angle_sum_via_triangulation,
    "The angle sum of a polygon equals the number of triangles in its fan triangulation times 180; for an n-gon, (n-2)*180",
    angles,
    [5,6,7,8]).

tier(ref(concept, polygon_angle_sum_via_triangulation), 1,
     [n103_ch1, ccss_8g5],
     "N103 Activity 1.4-1.5 derives this from fan-triangulation. Activity 1.6 (Erika's Idea) makes the (n-2) pattern explicit.").

angle_material_claim(polygon_sum_over_triangle_sum,
    polygon_angle_sum_via_triangulation,
    "polygon P has n sides AND P is fan-triangulated from one vertex",
    "P is divided into (n-2) triangles AND the angle sum of P is (n-2)*180",
    entitled).

geom_concept(four_kinds_of_related_angles,
    "Four canonical relationships among angles formed by lines: corresponding, alternate interior, vertical, supplementary",
    angles,
    [6,7,8]).

tier(ref(concept, four_kinds_of_related_angles), 1,
     [n103_ch1, ccss_8g5],
     "N103 Activity 1.9. The pedagogical move is to use these four as a closed inventory of reasons in justification.").

geom_concept(corresponding_angles,
    "When a transversal cuts two parallel lines, corresponding angles are equal",
    angles,
    [6,7,8]).

tier(ref(concept, corresponding_angles), 1,
     [n103_ch1],
     "N103 Activity 1.9. Sometimes called the F property.").

geom_concept(alternate_interior_angles,
    "When a transversal cuts two parallel lines, alternate interior angles are equal",
    angles,
    [6,7,8]).

tier(ref(concept, alternate_interior_angles), 1,
     [n103_ch1],
     "N103 Activity 1.9. Sometimes called the Z property; N103 names this informal label.").

geom_concept(vertical_angles_equal,
    "When two lines cross, vertical angles (across the vertex from each other) are equal",
    angles,
    [4,5,6,7,8]).

tier(ref(concept, vertical_angles_equal), 1,
     [n103_ch1, ccss_7g5, ccss_8g5],
     "N103 Activity 1.9.").

geom_concept(supplementary_angles,
    "Two angles are supplementary if they add to 180 degrees",
    angles,
    [4,5,6,7,8]).

tier(ref(concept, supplementary_angles), 1,
     [n103_ch1, ccss_7g5],
     "N103 Activity 1.9; named via the side-by-side configuration when two lines cross.").

geom_concept(reflex_angle,
    "An angle greater than 180 degrees",
    angles,
    [5,6,7,8]).

tier(ref(concept, reflex_angle), 1,
     [n103_ch1],
     "N103 Activity 1.13: An angle that is more than 180 degrees is called a reflex angle. Used in the Angle Test for convexity.").

geom_concept(convex_polygon_n103,
    "A polygon with no reflex angles inside; equivalently, every line segment with endpoints inside the figure stays inside",
    attributes,
    [3,4,5,6,7,8]).

tier(ref(concept, convex_polygon_n103), 1,
     [n103_ch1, ccss_5g3],
     "N103 Activity 1.13 explicitly presents four equivalent definitions: rubber-band, kid's-crawl-space, reflex-angle, and line-segment tests. The pluralism is the pedagogical point.").

geom_concept(rubber_band_convexity_test,
    "A figure is convex iff a rubber band stretched around it touches the edge all the way around",
    attributes,
    [3,4,5,6]).

tier(ref(concept, rubber_band_convexity_test), 3,
     [n103_ch1],
     "N103 Activity 1.13. N103-specific intuitive test, useful for younger learners. Alias: rubber band test. Tier 3 because it is an N103 pedagogical device, not a standard textbook concept.").

geom_concept(kids_crawl_space_convexity_test,
    "A polygon is non-convex if, when rolled along the floor, there is space for a tiny child to crawl under it",
    attributes,
    [3,4,5,6]).

tier(ref(concept, kids_crawl_space_convexity_test), 3,
     [n103_ch1],
     "N103 Activity 1.13. Attributed by name to Aaron Taylor, a former student. N103-idiosyncratic; alternative pedagogical device. Alias: crawl space test.").

geom_concept(line_segment_convexity_test,
    "A shape is convex iff every line segment with endpoints inside the figure stays entirely inside the figure",
    attributes,
    [6,7,8]).

tier(ref(concept, line_segment_convexity_test), 1,
     [n103_ch1],
     "N103 Activity 1.13: This idea is the basis for the most common definition of convexity given in advanced mathematics texts.").

geom_concept(reflex_angle_convexity_test,
    "A polygon is convex iff none of its interior angles is a reflex angle (greater than 180 degrees); equivalently, every interior angle is less than 180 degrees",
    attributes,
    [5,6,7,8]).

tier(ref(concept, reflex_angle_convexity_test), 1,
     [n103_ch1],
     "N103 Activity 1.13: the third of N103's four equivalent convexity tests. Added 2026-05-04 (Q-N103-B resolution) to give the test a concept anchor for the level-2 van_hiele_marker.").

angle_material_claim(convexity_reflex_angle_test,
    convex_polygon_n103,
    "polygon P has at least one reflex angle (greater than 180 degrees)",
    "P is non-convex",
    entitled).

angle_material_claim(convexity_line_segment_test,
    convex_polygon_n103,
    "every line segment with endpoints inside P lies entirely inside P",
    "P is convex",
    entitled).

geom_misconception(
    angle_sum_treated_as_universal_constant,
    triangle_angle_sum_180,
    "Treating 180 degrees as the angle sum of any closed figure (not just triangles)",
    [ "all shapes' angles add to 180",
      "this quadrilateral has 180 degrees of angles",
      "polygons have 180 degrees" ],
    "180 is the angle sum of a *triangle*. For an n-gon it is (n-2) times 180. Have the student fan-triangulate the polygon and count the triangles.",
    [n103_ch1]).

tier(ref(misconception, angle_sum_treated_as_universal_constant), 1,
     [n103_ch1],
     "Implied by Activity 1.4-1.6 setup; the activity is designed to lift students past this assumption.").

geom_misconception(
    erikas_idea_only_works_under_conditions,
    polygon_angle_sum_via_triangulation,
    "Counting triangles from a single vertex (n-2) confused with counting all possible triangulations",
    [ "I get eight triangles in an octagon, not six",
      "if you connect each corner to the opposite corner you get more triangles",
      "the formula doesn't match what I drew" ],
    "The (n-2) count refers to a fan triangulation from one vertex. Drawing all diagonals between non-adjacent vertices gives more triangles. Both counts are valid; only the fan-triangulation count satisfies (n-2). Compare side-by-side.",
    [n103_ch1]).

tier(ref(misconception, erikas_idea_only_works_under_conditions), 3,
     [n103_ch1],
     "N103 Activity 1.6 ('When Does Erika's Idea Work?') makes this an explicit student dialogue. Alias: fan-triangulation vs. all-diagonals confusion.").

% =====================================================================
% Research-corpus harvest (misconception_harvester) — appended below
% =====================================================================

:- multifile triangulation/2.
:- discontiguous triangulation/2.

% --- additional concept anchors needed by the harvest ---

geom_concept(angle_as_two_rays_from_vertex,
    "An angle is the figure formed by two rays sharing a common vertex",
    angles,
    [3,4,5,6]).

geom_concept(angle_measure_as_rotation,
    "Angle measure quantifies the amount of rotation between two rays",
    angles,
    [4,5,6,7,8]).

geom_concept(angle_measure_invariant_under_arm_length,
    "The measure of an angle does not depend on the length of its drawn arms",
    angles,
    [4,5,6]).

% --- corpus_39105 (Fischbein 1999) — angle size judged by arm length
geom_misconception(
    angle_size_by_arm_length,
    angle_measure_invariant_under_arm_length,
    "Angle size judged by the length of the drawn arms",
    [ "this angle is bigger because the lines are longer",
      "the longer rays make a bigger angle",
      "I measured the arms to compare angles" ],
    "Angle measure is the rotation between rays, not the length of the rays. Two angles drawn with very different arm lengths can be congruent. Demonstrate by extending or shortening the arms of a fixed angle — its measure does not change.",
    [corpus_39105, corpus_40267, fischbein_1999]).

tier(ref(misconception, angle_size_by_arm_length), 2,
     [corpus_39105, corpus_40267],
     "research corpus — Fischbein 1999 + Ferrini-Mundy 2007").

triangulation(ref(misconception, angle_size_by_arm_length),
    [ source(fischbein_1999, agrees),
      source(ferrini_mundy_2007, agrees) ]).

% --- corpus_38239 (Fyhn 2006) — angle as having only one ray
geom_misconception(
    angle_as_single_ray,
    angle_as_two_rays_from_vertex,
    "Angle conceptualized as a single ray (the second reference line missing)",
    [ "the angle from the wall to me",
      "this is the angle of the rope",
      "you measure the angle from one line" ],
    "An angle requires two rays sharing a vertex; the measure is between them. When describing an angle, name both rays explicitly. In a pendulum example, the angle is between the rope at rest (vertical) and the rope at the moment in question — two distinct rays.",
    [corpus_38239]).

tier(ref(misconception, angle_as_single_ray), 3,
     [corpus_38239], "single-source corpus row 38239 (Fyhn 2006)").

% --- corpus_40350 (Lin 2005) — angle as width or area between sides
geom_misconception(
    angle_as_static_region,
    angle_measure_as_rotation,
    "Angle defined as the width or area between two sides (static, region-based)",
    [ "the angle is the space between the sides",
      "the angle is how wide the corner is",
      "you measure the area inside the angle" ],
    "An angle is a measure of rotation, not a region. Two angles with different arm lengths can enclose very different-looking 'spaces' yet be the same angle. Move from a region image to a rotation image: imagine one ray fixed and the other rotating away from it.",
    [corpus_40350, corpus_40267]).

tier(ref(misconception, angle_as_static_region), 3,
     [corpus_40350, corpus_40267], "corpus rows 40350 + 40267").

% --- corpus_38217 / 38330 — interior vs exterior angle (turtle geometry)
geom_misconception(
    interior_exterior_angle_confusion,
    angle_measure_as_rotation,
    "Interior angle of a polygon confused with the exterior angle of turn",
    [ "the turtle turns the interior angle",
      "180 divided by 3 is 60, that's the angle",
      "the turn matches the inside angle" ],
    "When tracing a polygon, the *exterior* angle is the angle of turn (supplementary to the interior angle). For a regular triangle: interior is 60 degrees, exterior turn is 120 degrees (so the turtle turns 120, not 60). Walk the perimeter and turn at each vertex to feel the distinction.",
    [corpus_38217, corpus_38330]).

tier(ref(misconception, interior_exterior_angle_confusion), 2,
     [corpus_38217, corpus_38330],
     "research corpus — Granados 2000 + Clements 2000").

triangulation(ref(misconception, interior_exterior_angle_confusion),
    [ source(granados_2000, agrees),
      source(clements_2000, agrees) ]).

% --- corpus_37875 — triangle angle sum depends on size
geom_misconception(
    triangle_angle_sum_depends_on_size,
    triangle_angle_sum_180,
    "Triangle angle sum believed to depend on shape or size",
    [ "bigger triangles have bigger angle sums",
      "the angles add up to more than 180 in a large triangle",
      "the sum changes when you scale the triangle" ],
    "Every triangle in Euclidean geometry has interior angles summing to exactly 180 degrees, regardless of size or shape. Demonstrate by tearing the corners of a paper triangle and arranging them along a straight line. Triangle similarity preserves angle measures — scaling sides changes lengths, not angles.",
    [corpus_37875]).

tier(ref(misconception, triangle_angle_sum_depends_on_size), 3,
     [corpus_37875], "single-source corpus row 37875").

% --- corpus_39212 — corresponding angles assumed only-when-parallel
geom_misconception(
    corresponding_angles_only_parallel,
    corresponding_angles,
    "Corresponding/alternate angles assumed to exist only when lines are parallel",
    [ "you can only mark corresponding angles when the lines are parallel",
      "if the lines aren't parallel there are no alternate angles",
      "alternate angle theorem doesn't apply unless parallel" ],
    "Corresponding and alternate angles are *defined* by their position relative to the transversal — they exist whenever a line crosses two other lines. The *theorem* that corresponding angles are equal applies only when the cut lines are parallel. Definition vs theorem: don't conflate them.",
    [corpus_39212]).

tier(ref(misconception, corresponding_angles_only_parallel), 3,
     [corpus_39212], "single-source corpus row 39212").

% --- corpus_37650 — interior angle sum of hexagon = 6*180
geom_misconception(
    hexagon_angle_sum_six_triangles,
    polygon_angle_sum_via_triangulation,
    "Hexagon interior angle sum computed as 6 × 180 (counting all six visual triangles around a center)",
    [ "6 times 180 will give us the angles inside the hexagon",
      "the hexagon has six triangles so the sum is 1080",
      "I multiplied 180 by the number of triangles" ],
    "Decomposing a hexagon into six triangles around a central point gives 6 × 180 = 1080, but that double-counts the 360 degrees at the central vertex which isn't part of the hexagon's interior angles. The actual interior sum is (n-2) × 180 = 4 × 180 = 720 for a hexagon. Use a fan triangulation from a single vertex instead.",
    [corpus_37650]).

tier(ref(misconception, hexagon_angle_sum_six_triangles), 3,
     [corpus_37650], "single-source corpus row 37650").

% --- corpus_39401 — rotation as movement, not as measured angle
geom_misconception(
    rotation_as_one_arm_movement,
    angle_measure_as_rotation,
    "Rotation represented with only the moving arm shown (no fixed reference)",
    [ "the rotation is the movement of the wheel",
      "I turned, the angle is the turn",
      "rotation only needs one line" ],
    "Rotation is measured between two rays: the initial position and the final position, sharing the vertex (center of rotation). Always draw both — without a fixed reference there's no angle to measure.",
    [corpus_39401]).

tier(ref(misconception, rotation_as_one_arm_movement), 3,
     [corpus_39401], "single-source corpus row 39401 (Mitchelmore & White)").

% --- material inferences from the harvest ---

angle_material_claim(angle_measure_congruence_invariance,
    angle_measure_invariant_under_arm_length,
    "two angles share the same measure",
    "the angles are congruent regardless of arm length differences",
    entitled).

angle_material_claim(angle_measure_rejects_longer_arms,
    angle_measure_invariant_under_arm_length,
    "angle A has longer drawn arms than angle B",
    "angle A has greater measure than angle B",
    incompatible).

angle_material_claim(angle_requires_two_rays,
    angle_as_two_rays_from_vertex,
    "I have only one ray drawn",
    "I have specified an angle",
    incompatible).

angle_material_claim(triangle_sum_rejects_size_dependence,
    triangle_angle_sum_180,
    "triangle T is larger than triangle S",
    "the interior angle sum of T is greater than that of S",
    incompatible).

angle_material_claim(corresponding_angles_require_parallel_lines,
    corresponding_angles,
    "two lines are cut by a transversal and the cut lines are not parallel",
    "the corresponding angles are equal in measure",
    incompatible).

% =====================================================================
% Migrated from classification.pl 2026-05-04 (Q-007 resolution)
% Source: VdW Ch. 19. Originally parked in classification.pl by the VdW
% digger because of charter restriction.
% =====================================================================

geom_concept(angle_size_attribute,
    "Angle size is determined by the spread of the rays around the vertex, not by the length of the rays",
    angles,
    [4,5,6,7]).

tier(ref(concept, angle_size_attribute), 1, [source(vdw, agrees)],
    "VdW Ch. 19 p. 505 names this directly. Migrated from classification.pl 2026-05-04 (Q-007).").

geom_misconception(
    angle_as_ray_length,
    angle_size_attribute,
    "Angle size judged by ray length rather than ray spread",
    [ "this angle is bigger because the lines are longer",
      "the angle gets smaller when I shorten the rays",
      "wider arms means a wider angle" ],
    "Angles are formed by two rays that extend from a vertex; the rays have no inherent length. The attribute being measured is the rotation between them. Compare two angles directly by tracing one and overlaying it on the other; deliberately use angle pairs whose ray lengths differ to break the length-conflation.",
    [vdw_ch19_p505]).

tier(ref(misconception, angle_as_ray_length), 1, [source(vdw, agrees)],
    "VdW Ch. 19 p. 505 names this misconception explicitly and credits Munier, Devichi & Merle (2008). Migrated from classification.pl 2026-05-04 (Q-007).").

geom_concept(height_vs_slanted_side,
    "Height of a parallelogram, triangle, or trapezoid is the perpendicular distance from base to opposite vertex (or side), not the length of a slanted edge",
    angles,
    [4,5,6,7]).

tier(ref(concept, height_vs_slanted_side), 1, [source(vdw, agrees)],
    "VdW Ch. 19 p. 496-497. Migrated from classification.pl 2026-05-04 (Q-007). Topic = angles per Tio's resolution: height is fundamentally about the perpendicular (right-angle) relationship between base and altitude, even though it is invoked in service of area computation.").

geom_misconception(
    height_confused_with_slanted_side,
    height_vs_slanted_side,
    "Height of a slanted-side figure measured along the slanted side rather than perpendicular to the base",
    [ "the height is this slanted side",
      "I measured the slanted edge for height",
      "but length and width are the same as side lengths" ],
    "Imagine the figure sliding into a room on the chosen base. The height is the height of the shortest doorway it could pass through without tipping — the perpendicular distance to the base. Either side could serve as base; the height changes correspondingly.",
    [vdw_ch19_p497]).

tier(ref(misconception, height_confused_with_slanted_side), 1, [source(vdw, agrees)],
    "VdW Ch. 19 p. 496-497 names the misconception and the doorway repair. Migrated from classification.pl 2026-05-04 (Q-007).").
