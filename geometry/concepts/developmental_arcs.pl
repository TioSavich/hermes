% concepts/developmental_arcs.pl — geom_concept/4 + developmental_marker/4
% records that capture A-vs-B framings as developmental achievements.
%
% Tio's methodological commitment (memory:
% feedback_synthesis_as_developmental_achievement.md, 2026-05-01):
% "Many of the open questions ask 'is a better or is b better?' but
% indicate the possibility of 'c' where 'c' is a developmental marker.
% Generally, it's best to think about the synthesis of 'a' and 'b' as
% a developmental achievement."
%
% Each arc here resolves one or more OPEN_QUESTIONS Tier-4 questions:
%   square_classification_arc       — Q-004
%   triangle_angle_sum_arc          — Q-005
%   trapezoid_classification_arc    — Q-008 / Q-MH-A / Q-N103-F
%   reflectional_symmetry_arc       — Q-N103-D
%
% Topic atom = developmental (added to valid_topic 2026-05-03). Each arc
% concept has a paired developmental_marker/4 capturing FromStance,
% ToStance, and TransitionEvidence; a Tier 1 tier/4 anchored by Tio's
% explicit methodological commitment; and where applicable a
% material_inference/4 linking the arc concept to the source concepts.
% The source concepts themselves are preserved intact — these arcs are
% additive, not replacement.
%
% Schema: ../schema.pl

:- multifile geom_concept/4, geom_misconception/6, material_inference/4, tier/4.
:- discontiguous geom_concept/4, geom_misconception/6, material_inference/4, tier/4.
:- multifile developmental_marker/4.
:- discontiguous developmental_marker/4.

%!  developmental_arc_witness(+ArcId, -Witness) is semidet.
%
%   Inspectable proof object for a finite developmental arc. The witness ties
%   the concept record, tier source, developmental marker, and material claim
%   together without treating the arc as a universal learning law.
developmental_arc_witness(ArcId,
    _{ kind: developmental_arc,
       scope: closed_world_finite_developmental_arc_table,
       id: ArcId,
       description: Description,
       topic: Topic,
       grades: Grades,
       tier: Tier,
       sources: Sources,
       source_note: SourceNote,
       boundary: finite_developmental_arc_not_universal_learning_law,
       concept_fact: geom_concept(ArcId, Description, Topic, Grades),
       marker_witness: MarkerWitness,
       material_witness: MaterialWitness }) :-
    geom_concept(ArcId, Description, Topic, Grades),
    tier(ref(concept, ArcId), Tier, Sources, SourceNote),
    developmental_marker_witness(ArcId, MarkerWitness),
    developmental_arc_material_witness(ArcId, MaterialWitness).

developmental_marker_witness(ArcId,
    _{ kind: developmental_marker,
       scope: closed_world_finite_developmental_arc_table,
       id: ArcId,
       from_stance: FromStance,
       to_stance: ToStance,
       evidence: Evidence,
       evidence_witnesses: EvidenceWitnesses,
       fact: developmental_marker(ArcId, FromStance, ToStance, Evidence) }) :-
    developmental_marker(ArcId, FromStance, ToStance, Evidence),
    maplist(developmental_evidence_witness, Evidence, EvidenceWitnesses).

developmental_evidence_witness(marker_ref(van_hiele, Concept, Level),
                               _{ kind: van_hiele_marker_reference,
                                  concept: Concept,
                                  level: Level }) :-
    !.
developmental_evidence_witness(concept_ref(Concept),
                               _{ kind: concept_reference,
                                  id: Concept }) :-
    !.
developmental_evidence_witness(activity_ref(Activity),
                               _{ kind: activity_reference,
                                  id: Activity }) :-
    !.
developmental_evidence_witness(Text,
                               _{ kind: marker_phrase,
                                  text: Text }).

%!  developmental_arc_material_witness(+ArcId, -Witness) is semidet.
%
%   Inspectable proof object for the finite material-inference claim attached
%   to a developmental arc.
developmental_arc_material_witness(ArcId,
    _{ kind: developmental_arc_material_inference,
       scope: closed_world_finite_developmental_arc_table,
       id: ArcId,
       premise: Premise,
       conclusion: Conclusion,
       polarity: Polarity,
       fact: material_inference(ArcId, Premise, Conclusion, Polarity) }) :-
    material_inference(ArcId, Premise, Conclusion, Polarity).

% =====================================================================
% Q-004 — square_classification_arc
% Source concepts: square_recognition (VdW level-0/1) and
%                  square_rectangle_classification (VH level-2)
% =====================================================================

geom_concept(square_classification_arc,
    "Developmental arc from square-as-unit-shape (single-shape identity unfolding via VdW level-0/1 property analysis) to square-as-special-rectangle (van Hiele level-2 class inclusion). Captures the methodological commitment that the *transition* between these two valid framings is itself the unit worth modeling.",
    developmental,
    [0,1,2,3,4,5,6,7,8]).

tier(ref(concept, square_classification_arc), 1,
    [source(tio_methodology, agrees), source(synthesizer, agrees)],
    "Q-004 resolution 2026-05-04. Tier 1 because anchored by Tio's explicit methodological commitment that A-vs-B disputes resolve as developmental achievements. Source concepts (square_recognition, square_rectangle_classification) preserved intact; this arc is additive.").

developmental_marker(square_classification_arc,
    single_shape_identity_unfolding(square_recognition),
    class_inclusion_relation(square_rectangle_classification),
    [ "a square is a special rectangle"
    , "every square is a rectangle"
    , "all squares are rectangles but not all rectangles are squares"
    , "a square is a rectangle that happens to have all four sides equal"
    , marker_ref(van_hiele, square_rectangle_classification, 2)
    , marker_ref(van_hiele, square_recognition, 2)
    , concept_ref(quadrilateral_hierarchy)
    ]).

material_inference(square_classification_arc,
    "student demonstrates level-2 utterances such as 'every square is a rectangle' or eliminates redundant defining properties",
    "student has crossed the from-stance to-stance transition described by this arc; both source concepts (square_recognition, square_rectangle_classification) now apply",
    entitled).

% =====================================================================
% Q-005 — triangle_angle_sum_arc
% Source concepts: triangle_angle_sum (VdW level-2 conjecture) and
%                  triangle_angle_sum_180 (formal level-3 theorem)
% =====================================================================

geom_concept(triangle_angle_sum_arc,
    "Developmental arc from triangle angle sum as a level-2 conjecture (observed regularity from cut-and-arrange or inductive trials, VdW Activity 20.17) to triangle angle sum as a level-3 formal theorem (proved statement, N103 Ch. 1). Captures the move from 'I tried lots of triangles' to 'for any triangle, the sum is 180'.",
    developmental,
    [4,5,6,7,8]).

tier(ref(concept, triangle_angle_sum_arc), 1,
    [source(tio_methodology, agrees), source(synthesizer, agrees)],
    "Q-005 resolution 2026-05-04. Tier 1 anchored by Tio's methodological commitment. Source concepts (triangle_angle_sum, triangle_angle_sum_180) preserved intact.").

developmental_marker(triangle_angle_sum_arc,
    conjecture_form_level_2(triangle_angle_sum),
    formal_theorem_level_3(triangle_angle_sum_180),
    [ "I tried lots of triangles and they all add to 180"
    , "the angles of a triangle add up to a straight line — I checked"
    , "for any triangle, the sum is 180 degrees"
    , "I can prove the angle-sum is 180 from the parallel-line construction"
    , "the proof uses corresponding and alternate-interior angles"
    , marker_ref(van_hiele, triangle_angle_sum, 2)
    , marker_ref(van_hiele, informal_deduction_with_parallels, 2)
    , concept_ref(diagonals_of_rectangles_proof)
    ]).

material_inference(triangle_angle_sum_arc,
    "student moves from inductive trials (cut-and-arrange, measurement of many triangles) to a deductive argument from parallel-line theorems",
    "student has crossed the conjecture-to-theorem transition; both source concepts now describe the student's situation correctly at their respective levels",
    entitled).

% =====================================================================
% Q-008 / Q-MH-A / Q-N103-F — trapezoid_classification_arc
% Captures the exclusive→inclusive transition for trapezoid definition.
% Three open questions collapse into this single developmental arc.
% =====================================================================

geom_concept(trapezoid_classification_arc,
    "Developmental arc from exclusive trapezoid definition ('exactly one pair of parallel sides', excludes parallelograms) to inclusive trapezoid definition ('at least one pair of parallel sides', includes parallelograms). N103 frames this transition as a developmental milestone preservice teachers must learn to support.",
    developmental,
    [3,4,5,6,7,8]).

tier(ref(concept, trapezoid_classification_arc), 1,
    [source(tio_methodology, agrees), source(n103, agrees), source(synthesizer, agrees)],
    "Q-008 / Q-MH-A / Q-N103-F resolution 2026-05-04. Tier 1 anchored by Tio's methodological commitment plus N103's direct framing of the exclusive→inclusive shift as a developmental milestone (Activity 2.13). Source concepts (exclusive_definition, inclusive_definition, trapezoid_inclusive, parallelogram_as_trapezoid, exclusive_to_inclusive_transition) preserved intact.").

developmental_marker(trapezoid_classification_arc,
    exclusive(trapezoid_excludes_parallelograms),
    inclusive(trapezoid_includes_parallelograms),
    [ "a trapezoid has exactly one pair of parallel sides"
    , "a parallelogram is not a trapezoid"
    , "a trapezoid has at least one pair of parallel sides"
    , "every parallelogram is a trapezoid"
    , "all parallelograms are trapezoids, but not all trapezoids are parallelograms"
    , activity_ref(n103_act_2_13)
    , marker_ref(van_hiele, square_rectangle_classification, 2)
    , concept_ref(parallelogram_as_trapezoid)
    , concept_ref(exclusive_to_inclusive_transition)
    , concept_ref(quadrilateral_hierarchy)
    ]).

material_inference(trapezoid_classification_arc,
    "student begins by treating trapezoid and parallelogram as disjoint classes (exclusive stance) and shifts to recognizing parallelograms as a sub-class of trapezoids (inclusive stance)",
    "student has crossed the exclusive→inclusive transition; the inclusive material_inference (parallelogram_as_trapezoid, entitled) now applies fully, while the exclusive incompatible inference is recognized as level-relative rather than universal",
    entitled).

% =====================================================================
% Q-N103-D — reflectional_symmetry_arc
% From informal observable language ("one-sided" / "two-sided" figure)
% to formal mathematical term ("line-symmetric" / "non-line-symmetric").
% =====================================================================

geom_concept(reflectional_symmetry_arc,
    "Developmental arc from N103's informal observable language ('one-sided figure' / 'two-sided figure', tied to whether a figure has the same orientation as its reflection) to the formal mathematical terminology ('line-symmetric' / 'non-line-symmetric', anchored to a line of symmetry). N103 introduces the informal terms first as observable distinctions, then reveals the equivalence with the formal terms.",
    developmental,
    [2,3,4,5,6,7,8]).

tier(ref(concept, reflectional_symmetry_arc), 1,
    [source(tio_methodology, agrees), source(n103, agrees), source(synthesizer, agrees)],
    "Q-N103-D resolution 2026-05-04. Tier 1 anchored by Tio's methodological commitment plus N103's pedagogical move (Ch. 15) of introducing informal terms before the formal terms. Source concepts (one_sided_figure, two_sided_figure, reflectional_symmetry, line_of_symmetry) preserved intact.").

developmental_marker(reflectional_symmetry_arc,
    informal_observable_language(one_sided_two_sided),
    formal_mathematical_term(line_symmetric_non_line_symmetric),
    [ "this figure has the same orientation as its reflection — it's one-sided"
    , "this figure has opposite orientation from its reflection — it's two-sided"
    , "the one-sided figures are exactly the ones with a line of symmetry"
    , "two-sided means there is no line of reflection that takes the figure to itself"
    , "we call these line-symmetric / non-line-symmetric in the formal terminology"
    , activity_ref(n103_ch15)
    , concept_ref(reflectional_symmetry)
    , concept_ref(line_of_symmetry)
    , concept_ref(orientation_same_or_opposite)
    ]).

material_inference(reflectional_symmetry_arc,
    "student moves from describing figures using N103's observable language (one-sided / two-sided) to using the formal terms (line-symmetric / non-line-symmetric) and recognizing the equivalence",
    "student has crossed the informal-to-formal terminology transition for reflectional symmetry; both vocabularies now apply, with the equivalence understood",
    entitled).
