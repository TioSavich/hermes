% schema.pl — predicate declarations and validators for the geometry KB.
%
% This is the one canonical geometry load chain for direct, standalone bridge,
% and Hermes worker use. Its explicit manifest preserves the application's
% broad geometry, CCSS, Indiana, IM, PCK, and query scope. Other files append
% clauses for the predicates declared multifile/discontiguous below.
%
% See README.md and OPEN_QUESTIONS.md in this directory for current design
% context and hand-authoring guidance.

% ── multifile + discontiguous declarations ──────────────────────────

:- multifile geom_concept/4.
:- multifile van_hiele_marker/4.
:- multifile metaphor_source/4.
:- multifile geom_misconception/6.
:- multifile material_inference/4.
:- multifile concept_relation/4.
:- multifile proof_relation/3.
:- multifile reconstructive_relation/4.
:- multifile bootstrap/6.
:- multifile construction/5.
:- multifile standard_anchor/4.
:- multifile tier/4.
:- multifile triangulation/2.
:- multifile pck_synthesis/5.
:- multifile developmental_marker/4.

% Finite closed-world tables that currently have no rows in this KB snapshot.
:- dynamic proof_relation/3.
:- dynamic reconstructive_relation/4.
:- dynamic construction/5.

:- discontiguous geom_concept/4.
:- discontiguous van_hiele_marker/4.
:- discontiguous metaphor_source/4.
:- discontiguous geom_misconception/6.
:- discontiguous material_inference/4.
:- discontiguous concept_relation/4.
:- discontiguous bootstrap/6.
:- discontiguous standard_anchor/4.
:- discontiguous tier/4.
:- discontiguous triangulation/2.
:- discontiguous pck_synthesis/5.
:- discontiguous developmental_marker/4.

% BEGIN CANONICAL GEOMETRY LOAD MANIFEST
:- ensure_loaded('concepts/angles.pl').
:- ensure_loaded('concepts/area_perimeter.pl').
:- ensure_loaded('concepts/attributes.pl').
:- ensure_loaded('concepts/classification.pl').
:- ensure_loaded('concepts/coordinate_geometry.pl').
:- ensure_loaded('concepts/cross_links.pl').
:- ensure_loaded('concepts/developmental_arcs.pl').
:- ensure_loaded('concepts/material_reasoning.pl').
:- ensure_loaded('concepts/material_strength_lifts.pl').
:- ensure_loaded('concepts/measurement.pl').
:- ensure_loaded('concepts/pythagoras.pl').
:- ensure_loaded('concepts/quadrilateral_incompatibility.pl').
:- ensure_loaded('concepts/shape_recognition.pl').
:- ensure_loaded('concepts/similarity_congruence.pl').
:- ensure_loaded('concepts/standards_anchors.pl').
:- ensure_loaded('concepts/synthesizer_anchors.pl').
:- ensure_loaded('concepts/synthesizer_triangulations.pl').
:- ensure_loaded('concepts/transformations.pl').
:- ensure_loaded('concepts/van_hiele_levels.pl').
:- ensure_loaded('concepts/volume_surface_area.pl').
:- ensure_loaded('metaphors/lakoff_nunez_inventory.pl').
:- ensure_loaded('metaphors/measuring_stick.pl').
:- ensure_loaded('van_hiele/levels.pl').
:- ensure_loaded('van_hiele/transitions.pl').
:- ensure_loaded('bootstrap/construction_activities.pl').
:- ensure_loaded('bootstrap/n103_activities.pl').
:- ensure_loaded('bootstrap/van_de_walle_activities.pl').
:- ensure_loaded('../standards/ccss/geometry.pl').
:- ensure_loaded('../standards/indiana/geometry.pl').
:- ensure_loaded('../standards/im/grade_1.pl').
:- ensure_loaded('../standards/im/grade_2.pl').
:- ensure_loaded('../standards/im/grade_3.pl').
:- ensure_loaded('../standards/im/grade_4.pl').
:- ensure_loaded('../standards/im/grade_5.pl').
:- ensure_loaded('../standards/im/grade_6.pl').
:- ensure_loaded('../standards/im/grade_7.pl').
:- ensure_loaded('../standards/im/grade_8.pl').
:- ensure_loaded('../standards/im/grade_k.pl').
:- ensure_loaded('../standards/im/lesson_anchors.pl').
:- ensure_loaded('pck/classification.pl').
:- ensure_loaded('query.pl').
% END CANONICAL GEOMETRY LOAD MANIFEST

% ── slot definitions (descriptive; enforced by validators below) ────
%
% geom_concept(Id, Name, Topic, GradeBand)
%   Id        : atom, snake_case, globally unique
%   Name      : human-readable string
%   Topic     : one of [shape_recognition, attributes, classification,
%                       angles, transformations, area_perimeter,
%                       volume_surface_area, similarity_congruence,
%                       coordinate_geometry, pythagoras]
%   GradeBand : list of integers from 0..8 (K=0)
%
% van_hiele_marker(ConceptId, Level, MarkerPhrases, Citation)
%   Level         : 0..4  (visual, analytic, abstract, deductive, rigor)
%   MarkerPhrases : list of strings — what a student at this level says
%   Citation      : atom referencing corpus/ entry, or list of atoms
%
% metaphor_source(ConceptId, MetaphorName, Mapping, Citation)
%   MetaphorName : atom from the L&N taxonomy
%   Mapping      : list of source_target(Source, Target) pairs
%
% geom_misconception(Id, ConceptId, Name, Triggers, Repair, Citation)
%   compatible with the BENNY shape used in knowledge/misconceptions/
%
% material_inference(ConceptId, Premise, Conclusion, Polarity)
%   Polarity ∈ {entitled, incompatible}
%
% concept_relation(Source, Relation, Target, Status)
%   Conceptual routing edge for card selection, neighborhood traversal,
%   authoring, and UI explanation. Relation ∈ {alias_of, manifests_as,
%   prerequisite_for, developmental_transition, misconception_surface_of,
%   repairs_with}. These are not proof-bearing entailments.
%
% proof_relation(Source, Relation, Target)
%   Proof-bearing relation. Relation ∈ {material_entails,
%   material_incompatible, supports_entitlement, defeats_entitlement}.
%
% reconstructive_relation(EventOrContent, Relation, Target, Evidence)
%   Reconstructive / Carspeckenian routing edge. Relation ∈ {identity_claim,
%   recognition_risk, action_impetus_marker, validity_horizon,
%   pragmatic_horizon, limit_node}.
%
% bootstrap(Id, ConceptId, Kind, Prompt, Tools, TargetTransition)
%   Kind             ∈ {question, activity, construction}
%   Tools            : list of atoms (manipulatives, instruments)
%   TargetTransition : vH(From, To) | consolidate(L) | none
%
% construction(Id, Name, Tools, Steps, RelatedPropositions)
%
% standard_anchor(ConceptId, Framework, Code, Statement)
%   Framework ∈ {ccss, in_indiana, im_lesson}
%
% tier(RecordRef, Level, SourceList, Notes)
%   RecordRef = ref(Predicate, Id) | ref(Predicate, Id1, Id2)
%   Level     ∈ {1, 2, 3}
%   Tier 4 records do NOT appear here — they live in OPEN_QUESTIONS.md
%
% triangulation(RecordRef, AgreementList)
%   AgreementList = [source(Name, agreement_kind) | ...]
%   agreement_kind ∈ {agrees, disagrees, partial, silent}
%
% pck_synthesis(ConceptId, KeyKidThinking, KeyTeacherMoves, DevelopmentalArc, Citation)
%   A pedagogical-content-knowledge synthesis view over a concept. Tio's
%   framing: PCK is flatter than typical math-ed accounts assume — kid-
%   explanation and teacher-explanation are points on the same continuum,
%   not two stacked layers. So a pck_synthesis record is *not* a separate
%   body of knowledge; it is a synthesis-pointer back into the existing
%   tagging layer (van_hiele_marker, metaphor_source, geom_misconception,
%   material_inference, bootstrap) plus a developmental arc.
%
%   ConceptId        : anchored to geom_concept
%   KeyKidThinking   : list of refs into the tagging layer that capture
%                      how kids reason about this concept — e.g.
%                      [ref(van_hiele, square_recognition, 0),
%                       ref(metaphor, polygon_interior_as_container,
%                           container_schema),
%                       ref(misconception, square_not_rectangle)]
%   KeyTeacherMoves  : list of ref(bootstrap, _) refs — the
%                      highest-leverage moves a teacher has
%   DevelopmentalArc : list of stage descriptors describing the arc
%                      a learner travels through this concept; can
%                      include developmental_marker/4 references where
%                      A-vs-B framings synthesize. [] if not applicable.
%   Citation         : where this synthesis comes from
%
% developmental_marker(ConceptId, FromStance, ToStance, TransitionEvidence)
%   Captures the methodological commitment that A-vs-B disputes resolve
%   as developmental achievements: when sources disagree on framing of a
%   concept, the *transition* between framings is itself the unit worth
%   modeling. Example: trapezoid_classification with FromStance =
%   exclusive(trapezoid_excludes_parallelograms) and ToStance =
%   inclusive(trapezoid_includes_parallelograms).
%
%   FromStance, ToStance : functor-tagged framings of the concept
%   TransitionEvidence   : list of marker phrases / activity outcomes
%                          / van_hiele_marker references that signal
%                          the transition has occurred

% ── validators ──────────────────────────────────────────────────────

valid_topic(shape_recognition).
valid_topic(attributes).
valid_topic(classification).
valid_topic(angles).
valid_topic(transformations).
valid_topic(area_perimeter).
valid_topic(volume_surface_area).
valid_topic(similarity_congruence).
valid_topic(coordinate_geometry).
valid_topic(pythagoras).
valid_topic(measurement).
valid_topic(developmental).
% measurement: length / volume / surface-area unit-iteration concepts
%   that don't fit area_perimeter or volume_surface_area cleanly.
% developmental: wrapper concepts for developmental_marker arcs (Q-004,
%   Q-005, Q-008, Q-N103-D resolutions). Each arc concept describes the
%   move between two valid framings of a related concept; the
%   developmental_marker/4 record attached carries the from/to stance and
%   transition evidence.

valid_van_hiele_level(L) :- integer(L), L >= 0, L =< 4.

valid_tier_level(1).
valid_tier_level(2).
valid_tier_level(3).

valid_polarity(entitled).
valid_polarity(incompatible).

valid_concept_relation(alias_of).
valid_concept_relation(manifests_as).
valid_concept_relation(prerequisite_for).
valid_concept_relation(developmental_transition).
valid_concept_relation(misconception_surface_of).
valid_concept_relation(repairs_with).
valid_concept_relation(grounded_by).
valid_concept_relation(misconception_family).
valid_concept_relation(standard_generalization).

valid_proof_relation(material_entails).
valid_proof_relation(material_incompatible).
valid_proof_relation(supports_entitlement).
valid_proof_relation(defeats_entitlement).

valid_reconstructive_relation(identity_claim).
valid_reconstructive_relation(recognition_risk).
valid_reconstructive_relation(action_impetus_marker).
valid_reconstructive_relation(validity_horizon).
valid_reconstructive_relation(pragmatic_horizon).
valid_reconstructive_relation(limit_node).

valid_bootstrap_kind(question).
valid_bootstrap_kind(activity).
valid_bootstrap_kind(construction).

valid_framework(ccss).
valid_framework(in_indiana).
valid_framework(im_lesson).

concept_exists(Id) :- geom_concept(Id, _, _, _).

validate_geom_kb :-
    findall(E, validation_error(E), Errors),
    (   Errors == []
    ->  format("geometry KB validates clean.~n", [])
    ;   length(Errors, N),
        format("geometry KB has ~w validation errors:~n", [N]),
        forall(member(E, Errors), format("  - ~w~n", [E])),
        fail
    ).

validation_error(missing_topic(Id, Topic)) :-
    geom_concept(Id, _, Topic, _),
    \+ valid_topic(Topic).

validation_error(bad_van_hiele_level(ConceptId, Level)) :-
    van_hiele_marker(ConceptId, Level, _, _),
    \+ valid_van_hiele_level(Level).

validation_error(orphan_van_hiele_marker(ConceptId)) :-
    van_hiele_marker(ConceptId, _, _, _),
    \+ concept_exists(ConceptId).

validation_error(orphan_metaphor(ConceptId)) :-
    metaphor_source(ConceptId, _, _, _),
    \+ concept_exists(ConceptId).

validation_error(orphan_misconception(MisId, ConceptId)) :-
    geom_misconception(MisId, ConceptId, _, _, _, _),
    \+ concept_exists(ConceptId).

validation_error(bad_polarity(ConceptId, P)) :-
    material_inference(ConceptId, _, _, P),
    \+ valid_polarity(P).

validation_error(bad_concept_relation(Source, Relation, Target)) :-
    concept_relation(Source, Relation, Target, _),
    \+ valid_concept_relation(Relation).

validation_error(bad_proof_relation(Source, Relation, Target)) :-
    proof_relation(Source, Relation, Target),
    \+ valid_proof_relation(Relation).

validation_error(bad_reconstructive_relation(Source, Relation, Target)) :-
    reconstructive_relation(Source, Relation, Target, _),
    \+ valid_reconstructive_relation(Relation).

validation_error(bad_bootstrap_kind(Id, K)) :-
    bootstrap(Id, _, K, _, _, _),
    \+ valid_bootstrap_kind(K).

validation_error(bad_framework(ConceptId, F)) :-
    standard_anchor(ConceptId, F, _, _),
    \+ valid_framework(F).

validation_error(bad_tier(Ref, L)) :-
    tier(Ref, L, _, _),
    \+ valid_tier_level(L).

validation_error(missing_tier(misconception, Id)) :-
    geom_misconception(Id, _, _, _, _, _),
    \+ tier(ref(misconception, Id), _, _, _).

validation_error(missing_tier(bootstrap, Id)) :-
    bootstrap(Id, _, _, _, _, _),
    \+ tier(ref(bootstrap, Id), _, _, _).

validation_error(missing_tier(metaphor, ConceptId)) :-
    metaphor_source(ConceptId, M, _, _),
    \+ tier(ref(metaphor, ConceptId, M), _, _, _).

validation_error(missing_tier(van_hiele, ConceptId, L)) :-
    van_hiele_marker(ConceptId, L, _, _),
    \+ tier(ref(van_hiele, ConceptId, L), _, _, _).

validation_error(orphan_standard_anchor(ConceptId, Framework, Code)) :-
    standard_anchor(ConceptId, Framework, Code, _),
    \+ concept_exists(ConceptId).

validation_error(orphan_pck(ConceptId)) :-
    pck_synthesis(ConceptId, _, _, _, _),
    \+ concept_exists(ConceptId).

validation_error(orphan_developmental_marker(ConceptId)) :-
    developmental_marker(ConceptId, _, _, _),
    \+ concept_exists(ConceptId).

coverage_report(report(Concepts, Misconceptions, Metaphors, VanHiele,
                       Bootstraps, Standards, Pck, DevelopmentalMarkers,
                       Tier1, Tier2, Tier3)) :-
    aggregate_all(count, geom_concept(_, _, _, _), Concepts),
    aggregate_all(count, geom_misconception(_, _, _, _, _, _), Misconceptions),
    aggregate_all(count, metaphor_source(_, _, _, _), Metaphors),
    aggregate_all(count, van_hiele_marker(_, _, _, _), VanHiele),
    aggregate_all(count, bootstrap(_, _, _, _, _, _), Bootstraps),
    aggregate_all(count, standard_anchor(_, _, _, _), Standards),
    aggregate_all(count, pck_synthesis(_, _, _, _, _), Pck),
    aggregate_all(count, developmental_marker(_, _, _, _), DevelopmentalMarkers),
    aggregate_all(count, tier(_, 1, _, _), Tier1),
    aggregate_all(count, tier(_, 2, _, _), Tier2),
    aggregate_all(count, tier(_, 3, _, _), Tier3).
