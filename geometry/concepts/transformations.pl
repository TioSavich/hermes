% concepts/transformations.pl — geometry concepts in the transformations topic.
%
% Append clauses for: geom_concept/4, geom_misconception/6,
%                     material_inference/4, tier/4 (covering all of these).
% Cross-tagging (van_hiele_marker, metaphor_source, bootstrap,
% standard_anchor) lives in the corresponding subdirs.
%
% Schema: ../schema.pl

:- multifile geom_concept/4, geom_misconception/6, material_inference/4, tier/4.
:- discontiguous geom_concept/4, geom_misconception/6, material_inference/4, tier/4,
               transformation_material_claim/5.

%!  transformation_material_claim_witness(+Id, -Witness) is semidet.
%
%   Inspectable proof object for a finite transformation-geometry material row.
transformation_material_claim_witness(Id, Witness) :-
    transformation_material_claim(Id, Concept, Premise, Conclusion, Polarity),
    transformation_concept_tier_evidence(Concept,
                                         ConceptTierBoundary,
                                         ConceptTierEvidence),
    transformation_related_misconception_witnesses(Concept,
                                                   MisconceptionWitnesses),
    transformation_condition_roles(Id, Roles),
    Witness = _{ kind: geometry_transformation_material_inference,
                 scope: closed_world_finite_transformation_table,
                 id: Id,
                 concept: Concept,
                 premise: Premise,
                 conclusion: Conclusion,
                 polarity: Polarity,
                 concept_tier_boundary: ConceptTierBoundary,
                 concept_tier_evidence: ConceptTierEvidence,
                 boundary: finite_transformation_curriculum_claim_not_general_plane_isometry_theory,
                 condition_roles: Roles,
                 related_misconception_witnesses: MisconceptionWitnesses,
                 fact: material_inference(Concept, Premise, Conclusion, Polarity) }.

transformation_concept_tier_evidence(Concept,
                                     loaded_concept_tier_record,
                                     TierEvidence) :-
    findall(_{ tier: Tier,
               sources: Sources,
               source_note: SourceNote },
            tier(ref(concept, Concept), Tier, Sources, SourceNote),
            TierEvidence),
    TierEvidence \== [],
    !.
transformation_concept_tier_evidence(_Concept,
                                     no_concept_tier_record_in_loaded_geometry_schema,
                                     []).

transformation_related_misconception_witnesses(Concept, Witnesses) :-
    findall(Witness,
            transformation_misconception_witness(Concept, Witness),
            RawWitnesses),
    sort(RawWitnesses, Witnesses).

transformation_misconception_witness(Concept,
    _{ kind: geometry_transformation_misconception_support,
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
    transformation_triangulation_evidence(Id, TriangulationEvidence),
    tier(ref(misconception, Id), Tier, Sources, SourceNote).

transformation_triangulation_evidence(Id, Evidence) :-
    findall(_{ record: ref(misconception, Id),
               agreement: Agreement },
            triangulation(ref(misconception, Id), Agreement),
            RawEvidence),
    sort(RawEvidence, Evidence).

transformation_condition_roles(translation_pointwise_mapping,
                               [ _{ kind: sufficiency_component,
                                    role: vector_applied_to_every_point },
                                 _{ kind: invariance_component,
                                    role: orientation_preserved }
                               ]) :-
    !.
transformation_condition_roles(translation_anchor_lock_rejection,
                               [ _{ kind: incompatibility_component,
                                    role: vector_is_rule_not_anchor_leash },
                                 _{ kind: necessary_condition_missing,
                                    role: uniform_pointwise_application }
                               ]) :-
    !.
transformation_condition_roles(whole_plane_translation_rejection,
                               [ _{ kind: incompatibility_component,
                                    role: translation_is_plane_function_not_object_only_motion },
                                 _{ kind: scope_component,
                                    role: every_point_of_plane_has_image }
                               ]) :-
    !.
transformation_condition_roles(reflection_distance_over_correspondence,
                               [ _{ kind: sufficiency_component,
                                    role: image_on_perpendicular_to_mirror_line },
                                 _{ kind: sufficiency_component,
                                    role: equal_distance_opposite_side }
                               ]) :-
    !.
transformation_condition_roles(reflection_orientation_rejection,
                               [ _{ kind: incompatibility_component,
                                    role: mirror_line_controls_orientation },
                                 _{ kind: invariance_component,
                                    role: perpendicular_distance_preserved_not_axis_orientation }
                               ]) :-
    !.
transformation_condition_roles(line_symmetry_congruent_halves_rejection,
                               [ _{ kind: incompatibility_component,
                                    role: congruent_halves_do_not_imply_reflection_symmetry },
                                 _{ kind: necessary_condition_missing,
                                    role: reflection_maps_figure_to_itself }
                               ]) :-
    !.
transformation_condition_roles(reflection_rotation_distinction,
                               [ _{ kind: incompatibility_component,
                                    role: out_of_plane_flip_is_not_plane_rotation },
                                 _{ kind: distinction_component,
                                    role: reflection_and_rotation_are_distinct_plane_motions }
                               ]) :-
    !.
transformation_condition_roles(point_image_rotation_center_diagnostic,
                               [ _{ kind: sufficiency_component,
                                    role: matched_point_image_pairs },
                                 _{ kind: diagnostic_component,
                                    role: perpendicular_bisectors_concur_at_rotation_center }
                               ]) :-
    !.
transformation_condition_roles(point_image_glide_line_diagnostic,
                               [ _{ kind: sufficiency_component,
                                    role: matched_point_image_pairs },
                                 _{ kind: diagnostic_component,
                                    role: midpoints_collinear_on_glide_reflection_line }
                               ]) :-
    !.
transformation_condition_roles(parallel_reflections_compose_translation,
                               [ _{ kind: sufficiency_component,
                                    role: two_parallel_reflection_lines },
                                 _{ kind: composition_component,
                                    role: translation_distance_twice_line_separation }
                               ]) :-
    !.
transformation_condition_roles(intersecting_reflections_compose_rotation,
                               [ _{ kind: sufficiency_component,
                                    role: two_intersecting_reflection_lines },
                                 _{ kind: composition_component,
                                    role: rotation_angle_twice_intersection_angle }
                               ]) :-
    !.
transformation_condition_roles(_, []).

material_inference(Concept, Premise, Conclusion, Polarity) :-
    transformation_material_claim_witness(_Id, Witness),
    get_dict(fact, Witness, material_inference(Concept,
                                               Premise,
                                               Conclusion,
                                               Polarity)).

% =====================================================================
% N103 (Aichele & Wolfe 2008) — Chapters 15, 16
% =====================================================================

geom_concept(four_kinds_principle,
    "There are exactly four kinds of plane symmetry (reflectional, translational, rotational, glide-reflectional), corresponding to the four kinds of tracing-paper actions (flip, slide, turn, slide-flip)",
    transformations,
    [6,7,8]).

tier(ref(concept, four_kinds_principle), 1,
     [n103_ch16],
     "N103 Chapter 16 names this as the central principle of the chapter; reinforced in Activity 16.11. N103-specific framing.").

geom_concept(translation,
    "A rigid motion that slides every point of a figure by the same distance in the same direction; described by a translation vector",
    transformations,
    [4,5,6,7,8]).

tier(ref(concept, translation), 1,
     [n103_ch16, ccss_8g1, ccss_8g2, ccss_8g3],
     "N103 Activity 16.1. Standard transformation. N103 alias: 'slide'.").

geom_concept(reflection,
    "A rigid motion that flips a figure over a line (the reflection line); modeled by mira or paper folding",
    transformations,
    [3,4,5,6,7,8]).

tier(ref(concept, reflection), 1,
     [n103_ch15, n103_ch16, ccss_8g1, ccss_8g2, ccss_8g3],
     "N103 Chapters 15-16. Standard. N103 alias: 'flip'.").

geom_concept(rotation,
    "A rigid motion that turns a figure about a fixed point (center of rotation) by a given angle",
    transformations,
    [4,5,6,7,8]).

tier(ref(concept, rotation), 1,
     [n103_ch16, ccss_8g1, ccss_8g2, ccss_8g3],
     "N103 Activity 16.1. Standard. N103 alias: 'turn'.").

geom_concept(glide_reflection,
    "A rigid motion combining a translation and a reflection along the translation line; the glide-reflection line is both the slide direction and the reflection axis",
    transformations,
    [6,7,8]).

tier(ref(concept, glide_reflection), 1,
     [n103_ch16],
     "N103 Activity 16.1, 16.7, 16.10. N103 aliases: 'slide-flip', 'glide-flip'.").

geom_concept(reflectional_symmetry,
    "A figure has reflectional symmetry if there exists a line such that the figure folds onto itself across that line",
    transformations,
    [2,3,4,5,6,7,8]).

tier(ref(concept, reflectional_symmetry), 1,
     [n103_ch15, ccss_4g3],
     "N103 Chapter 15. N103 collapses three labels: 'fold-and-cut shape = line-symmetric figure = one-sided figure'. Bilateral symmetry = exactly one line of symmetry.").

geom_concept(translational_symmetry,
    "A figure has translational symmetry if it can be slid (in some direction by some distance) and lines up with itself",
    transformations,
    [5,6,7,8]).

tier(ref(concept, translational_symmetry), 1,
     [n103_ch16],
     "N103 Activity 16.2. Borders, friezes, wallpaper.").

geom_concept(rotational_symmetry,
    "A figure has rotational symmetry of order n if it can be rotated by 360/n degrees and lines up with itself",
    transformations,
    [4,5,6,7,8]).

tier(ref(concept, rotational_symmetry), 1,
     [n103_ch16, ccss_4g3],
     "N103 Activity 16.2.").

geom_concept(half_turn_symmetry,
    "Order-2 rotational symmetry — the figure lines up after a 180-degree rotation",
    transformations,
    [4,5,6,7,8]).

tier(ref(concept, half_turn_symmetry), 1,
     [n103_ch16],
     "N103 Activity 16.2: 'Order-2 rotational symmetry is also called half-turn symmetry.'").

geom_concept(glide_reflectional_symmetry,
    "A figure has glide-reflectional symmetry if there exists a line such that flipping over that line and then sliding along it produces the figure",
    transformations,
    [6,7,8]).

tier(ref(concept, glide_reflectional_symmetry), 1,
     [n103_ch16],
     "N103 Activity 16.2.").

geom_concept(orientation_same_or_opposite,
    "Two copies of a figure have the same orientation if a tracing of one can slide and rotate (without flipping) to align with the other; otherwise opposite",
    transformations,
    [4,5,6,7,8]).

tier(ref(concept, orientation_same_or_opposite), 1,
     [n103_ch15, n103_ch16],
     "N103 Activity 15.3 introduces; Activity 16.6 turns it into the diagnostic for which-of-four-actions applies.").

geom_concept(one_sided_figure,
    "A figure that has the same orientation as its reflection — equivalently, a figure with reflectional symmetry",
    transformations,
    [4,5,6,7]).

tier(ref(concept, one_sided_figure), 3,
     [n103_ch15],
     "N103 Activity 15.3. N103-specific terminology, ultimately collapsed by N103 with 'fold-and-cut figure' and 'line-symmetric figure'.").

geom_concept(two_sided_figure,
    "A figure with orientation opposite to its reflection — equivalently, a figure without reflectional symmetry",
    transformations,
    [4,5,6,7]).

tier(ref(concept, two_sided_figure), 3,
     [n103_ch15],
     "N103 Activity 15.3. N103-specific terminology.").

geom_concept(point_image_segment,
    "The line segment connecting a point on the original figure to its image under a transformation",
    transformations,
    [6,7,8]).

tier(ref(concept, point_image_segment), 1,
     [n103_ch16],
     "N103 Activity 16.7 introduces this as the diagnostic tool for finding the center of rotation or the glide-reflection line.").

transformation_material_claim(point_image_rotation_center_diagnostic,
    point_image_segment,
    "two figures are related by a rotation AND point-image segments are drawn for several point pairs",
    "the perpendicular bisectors of those segments are concurrent at the center of rotation",
    entitled).

transformation_material_claim(point_image_glide_line_diagnostic,
    point_image_segment,
    "two figures are related by a glide-reflection AND point-image segments are drawn",
    "the midpoints of those segments are collinear and lie on the glide-reflection line",
    entitled).

geom_concept(mira_or_reflecta,
    "A transparent plastic mirror used to physically model reflections; lets a learner see both an original and its reflection through the same line",
    transformations,
    [3,4,5,6,7,8]).

tier(ref(concept, mira_or_reflecta), 3,
     [n103_ch15, n103_ch16],
     "N103-specific physical tool. Brand-name pedagogy. Alias: 'reflecta'.").

geom_concept(tracing_paper_diagnostic,
    "Use of tracing paper as the substrate for testing whether two figures are related by translation, rotation, reflection, or glide-reflection",
    transformations,
    [3,4,5,6,7,8]).

tier(ref(concept, tracing_paper_diagnostic), 3,
     [n103_ch15, n103_ch16],
     "N103-specific methodology. The chapter title 'tracing-paper actions' is N103's framing.").

geom_concept(combination_of_two_reflections,
    "Two reflections compose to either a translation (parallel reflection lines) or a rotation (intersecting reflection lines)",
    transformations,
    [7,8]).

tier(ref(concept, combination_of_two_reflections), 1,
     [n103_ch16],
     "N103 Activity 16.5. Parallel lines distance d apart give translation by 2d; intersecting at angle theta give rotation by 2*theta.").

transformation_material_claim(parallel_reflections_compose_translation,
    combination_of_two_reflections,
    "figure F is reflected over parallel lines L1 then L2 separated by distance d",
    "the result is a translation of F by 2d perpendicular to the lines",
    entitled).

transformation_material_claim(intersecting_reflections_compose_rotation,
    combination_of_two_reflections,
    "figure F is reflected over intersecting lines L1 then L2 meeting at angle theta",
    "the result is a rotation of F by 2*theta about the intersection point",
    entitled).

geom_misconception(
    rotation_confused_with_glide_reflection,
    glide_reflection,
    "Two figures with opposite orientation assumed to be related by reflection rather than glide-reflection",
    [ "they look flipped so they are reflections",
      "this must be a reflection",
      "I can find the reflection line" ],
    "Reflections leave figures with opposite orientation, but so do glide-reflections. Test by finding a single reflection line: place mira or trace+flip. If no single line works, it's a glide-reflection. Use point-image segments to locate the glide-reflection line.",
    [n103_ch16]).

tier(ref(misconception, rotation_confused_with_glide_reflection), 1,
     [n103_ch16],
     "N103 Activity 16.6 explicitly designs around this confusion.").

% =====================================================================
% Research-corpus harvest (misconception_harvester) — appended below
% =====================================================================

:- multifile triangulation/2.
:- discontiguous triangulation/2.

% --- additional concept anchors for the harvest ---

geom_concept(translation_acts_on_whole_plane,
    "A translation acts on every point of the plane simultaneously, not just on a single object",
    transformations,
    [6,7,8]).

geom_concept(reflection_preserves_perpendicular_distance,
    "Reflection sends a point P to the point on the other side of the line at the same perpendicular distance",
    transformations,
    [5,6,7,8]).

geom_concept(line_of_symmetry,
    "A line of symmetry maps a figure to itself under reflection across that line",
    transformations,
    [3,4,5,6]).

geom_concept(reflection_distinct_from_rotation,
    "Reflections and rotations are distinct rigid motions in the plane — a reflection cannot be achieved by an in-plane rotation alone",
    transformations,
    [6,7,8]).

% --- corpus_38386 (Yanik & Flores 2009): vector treated as line of reflection
geom_misconception(
    translation_vector_as_reflection_line,
    translation,
    "Translation vector treated as a line of reflection",
    [ "I reflected the shape over the vector",
      "the vector is the mirror line",
      "the image is on the other side of the arrow" ],
    "A translation vector specifies *direction and distance* — every point of the figure moves the same way along that vector. There's no flipping involved. To translate, slide each vertex by the vector and connect; orientation is preserved.",
    [corpus_38386, yanik_flores_2009]).

tier(ref(misconception, translation_vector_as_reflection_line), 3,
     [corpus_38386], "single-source corpus row 38386").

% --- corpus_38387: static endpoint relationship
geom_misconception(
    translation_static_endpoint_relationship,
    translation,
    "Translation vector treated as a static link between endpoint and image",
    [ "if I move the vector's tail, the pre-image moves too",
      "the image is glued to the tip of the vector",
      "moving the arrow changes where the shape was" ],
    "The translation vector specifies a rule (move every point by this much in this direction), not a leash. Once you apply the translation, the pre-image stays where it is and the image is at the new location. Moving or redrawing the vector doesn't move the original figure.",
    [corpus_38387]).

tier(ref(misconception, translation_static_endpoint_relationship), 3,
     [corpus_38387], "single-source corpus row 38387").

% --- corpus_38388: domain of translation as single object
geom_misconception(
    translation_acts_only_on_object,
    translation_acts_on_whole_plane,
    "Translation conceived as acting only on the figure, not on the entire plane",
    [ "by me translating, not everything in the world moves; just me translated",
      "the translation only moves the shape",
      "if everything moves, nothing moves" ],
    "A translation is a function on the whole plane — it sends each point to a new point. Whether you draw a single figure or many doesn't affect the rule itself. The reason the rule is interesting is that it acts uniformly on every point.",
    [corpus_38388]).

tier(ref(misconception, translation_acts_only_on_object), 3,
     [corpus_38388], "single-source corpus row 38388").

% --- corpus_38389: zero vector means no translation
geom_misconception(
    zero_vector_means_no_translation,
    translation,
    "Zero vector treated as 'no translation occurred at all'",
    [ "if the vector is zero there's no translation",
      "you need a real arrow for there to be a translation",
      "no movement means no transformation" ],
    "The zero translation is a legitimate translation — it's the identity transformation, sending every point to itself. The set of translations forms a group, and zero is its identity element. Conceptually distinct from 'no transformation' (which isn't a thing in this system).",
    [corpus_38389]).

tier(ref(misconception, zero_vector_means_no_translation), 3,
     [corpus_38389], "single-source corpus row 38389").

% --- corpus_39172 (Bell 1993): orientation-locked images of reflection
geom_misconception(
    reflection_preserves_orientation_axis,
    reflection,
    "Reflection assumed to preserve horizontal/vertical axis of objects",
    [ "horizontal lines must reflect to horizontal lines",
      "vertical objects always have vertical images",
      "the orientation can't change in a reflection" ],
    "Reflection across a non-axis-aligned line can change horizontal lines into non-horizontal lines (and vice versa). The mirror line itself determines the new orientations — only the perpendicular-distance and on-which-side-of-the-line properties are preserved. Demonstrate with reflection across a 45-degree line.",
    [corpus_39172]).

tier(ref(misconception, reflection_preserves_orientation_axis), 3,
     [corpus_39172], "single-source corpus row 39172 (Bell 1993)").

% --- corpus_39173: linguistic-opposite reflection
geom_misconception(
    reflection_by_linguistic_opposites,
    reflection,
    "Reflection determined by mapping linguistic opposites (left to right, up to down)",
    [ "this points up so the reflection points down",
      "left becomes right",
      "I just flipped it the opposite way" ],
    "Reflection is a specific geometric mapping: for each point, draw the perpendicular to the mirror line and place the image on the other side at the same distance. The 'opposite' words (left/right, up/down) only happen to match for special mirror lines (the y-axis, the x-axis); they fail for oblique mirror lines.",
    [corpus_39173, bell_1993]).

tier(ref(misconception, reflection_by_linguistic_opposites), 3,
     [corpus_39173], "single-source corpus row 39173 (Bell 1993)").

% --- corpus_39174: reflection as moving mirror
geom_misconception(
    reflection_as_moving_mirror,
    reflection,
    "Reflection imagined as physically moving a mirror along a line",
    [ "the mirror can be at different positions",
      "there are several correct images",
      "I moved the mirror down to get a different reflection" ],
    "The mirror line is fixed once specified. The reflection across a given line is unique — every point has exactly one image. Moving the mirror means defining a different reflection, with a different image. There aren't multiple valid images for a single reflection.",
    [corpus_39174]).

tier(ref(misconception, reflection_as_moving_mirror), 3,
     [corpus_39174], "single-source corpus row 39174").

% --- corpus_39175 / 39626 / 39797: line of symmetry over-generalized
geom_misconception(
    symmetry_axis_over_split,
    line_of_symmetry,
    "Any line that splits a figure into two equal halves treated as a line of symmetry",
    [ "this line splits the figure equally so it's a line of symmetry",
      "the diagonal of the rectangle is a line of symmetry",
      "if both halves are the same it's symmetric" ],
    "A line of symmetry must map the figure *to itself under reflection*. Equal-halves split is necessary but not sufficient: the two halves must also be mirror images. The diagonal of a non-square rectangle splits it into two congruent triangles, but they aren't mirror images across that diagonal — fold the rectangle and check whether the halves coincide.",
    [corpus_39175, corpus_39626, corpus_39797]).

tier(ref(misconception, symmetry_axis_over_split), 2,
     [corpus_39175, corpus_39626, corpus_39797],
     "research corpus — multi-source on equal-halves vs reflection-symmetry conflation").

triangulation(ref(misconception, symmetry_axis_over_split),
    [ source(bell_1993, agrees),
      source(leikin_berman_zaslavsky_2000, agrees),
      source(nissen_1994, agrees) ]).

% --- corpus_39627: oblique mirror line, distorted image
geom_misconception(
    oblique_mirror_distorted_image,
    reflection_preserves_perpendicular_distance,
    "Mirror image distorted when the line of symmetry is oblique",
    [ "I made the other half congruent",
      "I drew a similar shape on the other side",
      "with a slanted mirror it's hard to be exact" ],
    "Reflection preserves perpendicular distance to the mirror line for every point. With an oblique mirror, drop perpendiculars from each pre-image vertex to the mirror line and place each image vertex at the same perpendicular distance on the other side. 'Congruent' alone is not enough — the placement must satisfy the perpendicular-distance rule.",
    [corpus_39627]).

tier(ref(misconception, oblique_mirror_distorted_image), 3,
     [corpus_39627], "single-source corpus row 39627").

% --- corpus_39628: a line is its own line of symmetry
geom_misconception(
    line_not_its_own_symmetry_axis,
    line_of_symmetry,
    "A straight line refused as a symmetry axis of itself",
    [ "a line can't be its own symmetry axis",
      "a symmetry axis has to divide the figure into two parts",
      "you need separate halves for symmetry" ],
    "A line maps to itself under reflection across itself — every point on the line is fixed, so the figure (the line) is preserved. By definition that makes the line a symmetry axis of itself. Restricting symmetry axes to dividing-into-two-pieces lines misses the trivial cases.",
    [corpus_39628]).

tier(ref(misconception, line_not_its_own_symmetry_axis), 3,
     [corpus_39628], "single-source corpus row 39628").

% --- corpus_40528: stamp flipped out of plane (reflection vs rotation)
geom_misconception(
    flip_out_of_plane_for_reflection,
    reflection_distinct_from_rotation,
    "Reflection achieved by physically flipping the figure out of the plane",
    [ "you flip the stamp over to get the reflection",
      "you turn the shape over",
      "reflection means flipping it upside down" ],
    "In 2D plane geometry, transformations stay in the plane — reflections and rotations are both in-plane operations. A reflection produces a 'mirror' image; an in-plane rotation produces a turned (but not mirrored) image. They're different transformations and produce different orientations. The 'flip out of plane' is a 3D move, not part of plane-isometry vocabulary.",
    [corpus_40528]).

tier(ref(misconception, flip_out_of_plane_for_reflection), 3,
     [corpus_40528], "single-source corpus row 40528 (Ryan & Williams)").

% --- material inferences from the harvest ---

transformation_material_claim(translation_pointwise_mapping,
    translation,
    "translation by vector v is applied to figure F",
    "every point P of F maps to P + v",
    entitled).

transformation_material_claim(reflection_distance_over_correspondence,
    reflection_preserves_perpendicular_distance,
    "point P is reflected across line L",
    "the image P' lies on the perpendicular from P to L, on the opposite side, at equal distance",
    entitled).

transformation_material_claim(translation_anchor_lock_rejection,
    translation,
    "translation vector v has been drawn from point A to point B",
    "the pre-image is locked to point A and translates only when A moves",
    incompatible).

transformation_material_claim(whole_plane_translation_rejection,
    translation_acts_on_whole_plane,
    "translation T is applied",
    "T moves only the figure under consideration; the rest of the plane stays put",
    incompatible).

transformation_material_claim(reflection_orientation_rejection,
    reflection,
    "reflection across line L sends figure F to figure F'",
    "F' must have the same axis-orientation as F (horizontals stay horizontal, verticals stay vertical)",
    incompatible).

transformation_material_claim(line_symmetry_congruent_halves_rejection,
    line_of_symmetry,
    "line L splits figure F into two congruent parts",
    "L is a line of symmetry of F",
    incompatible).

transformation_material_claim(reflection_rotation_distinction,
    reflection_distinct_from_rotation,
    "two figures can be made to coincide by flipping one out of the plane",
    "the two figures are related by a 2D rotation",
    incompatible).
