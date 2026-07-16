% van_hiele/transitions.pl — transition activities between levels.
% Schema: ../schema.pl

:- multifile bootstrap/6, tier/4, material_inference/4.
:- discontiguous bootstrap/6, tier/4, material_inference/4, van_hiele_material_claim/5.

% =============================================================================
% Records contributed by the Van Hiele Dissertation digger (2026-05-03).
% Source: Fuys-VanHieleModel-1988.pdf (NotebookLM "Geometry and Pedagogy" nb).
% Backing corpus: ../corpus/van_hiele_dissertation_excerpts.md
%
% These records encode van Hiele's original FIVE PHASES of learning between
% levels, plus diagnostic prompts that detect a level transition (the
% language-switch criterion), plus the "didactic gap" / language-barrier
% commitment encoded as material_inference/4.
%
% Phase numbering (van Hiele's own): (1) Information, (2) Guided Orientation,
% (3) Explicitation, (4) Free Orientation, (5) Integration. Each phase is
% defined IN GENERAL — van Hiele's claim is that the phase structure is the
% same across every level transition. Records below capture both the general
% phase descriptors and the worked example (level-0 → level-1 area-of-
% parallelograms in the Fuys 1988 monograph, p. 13).
% =============================================================================

% ─────────────────────────────────────────────────────────────────────────────
% Section A — General phase descriptors (TargetTransition = vH(any,next))
%
% These records describe the phase as a structural pattern. The synthesizer
% may choose to instantiate them per-level; here we name them with a generic
% transition tag that the synthesizer can specialize.
% ─────────────────────────────────────────────────────────────────────────────

bootstrap(vh_phase_information_general, geometric_language, activity,
    "Acquaint the student with the working domain. Show examples and non-examples of the target concept; let the student handle, manipulate, and informally describe them. No rules yet, no formal vocabulary required.",
    [examples_set, non_examples_set, manipulatives],
    vH(0, 1)).
tier(ref(bootstrap, vh_phase_information_general), 1,
     [van_hiele_dissertation_corpus],
     "Direct van Hiele 1959/1984 p.7 (via Fuys 1988 p.7): Phase 1 description.").

bootstrap(vh_phase_guided_orientation_general, geometric_language, activity,
    "Have the student perform tasks that traverse different relations of the network being formed. Folding, measuring, looking for symmetry, comparing and sorting. The teacher chooses the tasks so the relations of the next level become tractable.",
    [paper_for_folding, ruler, geoboard, mira, sortable_shape_set],
    vH(0, 1)).
tier(ref(bootstrap, vh_phase_guided_orientation_general), 1,
     [van_hiele_dissertation_corpus],
     "Direct van Hiele 1959/1984 p.7 (via Fuys 1988 p.7): Phase 2 description.").

bootstrap(vh_phase_explicitation_general, geometric_language, activity,
    "Make the student conscious of the relations they have been using; ask them to express the relations in words; introduce the technical language that accompanies the subject matter. THIS is the phase where vocabulary substitutes informal language with formal terminology, and where the language-switch begins to be observable.",
    [class_discussion, vocabulary_anchor_chart, written_explanation],
    vH(0, 1)).
tier(ref(bootstrap, vh_phase_explicitation_general), 1,
     [van_hiele_dissertation_corpus],
     "Direct van Hiele 1959/1984 p.7 (via Fuys 1988 p.7): Phase 3 description. This is the locus of van Hiele's 'language' criterion.").

bootstrap(vh_phase_free_orientation_general, geometric_language, activity,
    "Give the student more complex, multi-step tasks where they must find their own way through the network of relations. Apply known properties of one shape class to investigate a new shape class (e.g., apply rhombus properties to kites). Multiple solution paths.",
    [extension_problems, novel_shape_set, open_ended_investigation],
    vH(0, 1)).
tier(ref(bootstrap, vh_phase_free_orientation_general), 1,
     [van_hiele_dissertation_corpus],
     "Direct van Hiele 1959/1984 p.7 (via Fuys 1988 p.7): Phase 4 description.").

bootstrap(vh_phase_integration_general, geometric_language, activity,
    "Have the student summarize what they have learned and reflect on their own actions. Produce an overview of the newly formed network of relations: a family tree, a property chart, a summary statement. The student now sees the network as an object.",
    [summary_writing, family_tree_diagram, concept_map],
    vH(0, 1)).
tier(ref(bootstrap, vh_phase_integration_general), 1,
     [van_hiele_dissertation_corpus],
     "Direct van Hiele 1959/1984 p.7 (via Fuys 1988 p.7): Phase 5 description.").

% ─────────────────────────────────────────────────────────────────────────────
% Section B — Worked examples Fuys 1988 attaches to the phase theory
% (Module 3, area of parallelograms, level-0 → level-1 transition)
% ─────────────────────────────────────────────────────────────────────────────

bootstrap(vh_area_parallelogram_information, area_of_parallelogram, activity,
    "Open with informal work on area of parallelograms — ask students to compare which parallelogram-shaped region is bigger, count squares on a grid, cover with manipulatives. No formula; no formal definition of 'base' or 'height' yet.",
    [grid_paper, parallelogram_cutouts, square_tiles],
    vH(0, 1)).
tier(ref(bootstrap, vh_area_parallelogram_information), 1,
     [van_hiele_dissertation_corpus],
     "Fuys 1988 p.13 — worked example of Phase 1 in Module 3.").

bootstrap(vh_area_parallelogram_guided_orientation, area_of_parallelogram, activity,
    "Guide the student to discover a procedure for finding the area of a parallelogram. Cut, slide, rearrange into a rectangle. The teacher steers; the discovery is structured.",
    [scissors, parallelogram_cutouts, grid_paper],
    vH(0, 1)).
tier(ref(bootstrap, vh_area_parallelogram_guided_orientation), 1,
     [van_hiele_dissertation_corpus],
     "Fuys 1988 p.13 — Phase 2 worked example.").

bootstrap(vh_area_parallelogram_explicitation, area_of_parallelogram, activity,
    "Have the student express the area-finding procedure in words, introducing the technical terms 'base' and 'height'. The student names what they have been doing.",
    [class_discussion, written_procedure, vocabulary_card_base_height],
    vH(0, 1)).
tier(ref(bootstrap, vh_area_parallelogram_explicitation), 1,
     [van_hiele_dissertation_corpus],
     "Fuys 1988 p.13 — Phase 3 worked example. The introduction of 'base' and 'height' is itself the language-switch event.").

bootstrap(vh_area_parallelogram_free_orientation, area_of_parallelogram, activity,
    "Present a variety of problems embodying the just-learned area concept — irregular parallelograms, parallelograms in unusual orientations, parallelograms whose base or height isn't horizontally or vertically aligned. The student must find their own path.",
    [varied_parallelogram_problems, grid_paper],
    vH(0, 1)).
tier(ref(bootstrap, vh_area_parallelogram_free_orientation), 1,
     [van_hiele_dissertation_corpus],
     "Fuys 1988 p.13 — Phase 4 worked example.").

bootstrap(vh_area_parallelogram_integration, area_of_parallelogram, activity,
    "Have the student summarize area rules in a 'family tree' that connects rectangle, parallelogram, triangle, and trapezoid area formulas. Now the student sees the area-rules-network as a single object.",
    [family_tree_diagram, summary_writing],
    vH(0, 1)).
tier(ref(bootstrap, vh_area_parallelogram_integration), 1,
     [van_hiele_dissertation_corpus],
     "Fuys 1988 p.13 — Phase 5 worked example.").

% ─────────────────────────────────────────────────────────────────────────────
% Section C — Diagnostic prompts (Kind = question) for level detection
%
% These are the listening-grammar bridge: a question whose answer-shape
% lets you classify the student's current level. Drawn from van Hiele's
% own canonical examples and the Fuys 1988 clinical-interview script.
% ─────────────────────────────────────────────────────────────────────────────

bootstrap(vh_q_square_is_rectangle, square_rectangle_classification, question,
    "Show the student a square and a rectangle. Ask: 'Is a square a rectangle? Why or why not?' Level-0 answer: 'no, they look different.' Level-1 answer: 'I'm not sure, they have different properties' (a square has all sides equal, a rectangle doesn't have to). Level-2 answer: 'Yes, every square is a rectangle because a square has all the properties of a rectangle and more.'",
    [square_cutout, rectangle_cutout],
    vH(1, 2)).
tier(ref(bootstrap, vh_q_square_is_rectangle), 1,
     [van_hiele_dissertation_corpus],
     "Direct van Hiele paper #2 p.245 — square/rectangle is THE canonical level discriminator. Fuys clinical (p. ~75) shows Samantha's level-2 utterance.").

bootstrap(vh_q_rhombus_is_parallelogram, square_rectangle_classification, question,
    "Show the student a rhombus and a parallelogram. Ask: 'Is a rhombus a parallelogram?' Level-0 answer: 'no, the rhombus is a completely different thing.' Level-1 answer: 'I can list the properties of each.' Level-2 answer: 'Yes — a rhombus has all the properties of a parallelogram plus all sides equal.'",
    [rhombus_cutout, parallelogram_cutout],
    vH(0, 1)).
tier(ref(bootstrap, vh_q_rhombus_is_parallelogram), 1,
     [van_hiele_dissertation_corpus],
     "Direct van Hiele paper #2 p.245: 'At this level [0], the rhombus is not a parallelogram; the rhombus seems to him a completely different thing.'").

bootstrap(vh_q_describe_this_shape, polygon_recognition, question,
    "Hand the student a shape (square, rectangle, rhombus, parallelogram) and ask: 'Tell me about this shape.' Level-0 markers: appearance words (fat, long, pointy, slanty), comparisons to familiar objects (looks like a box). Level-1 markers: property lists (4 right angles, opposite sides parallel, diagonals bisect). Level-2 markers: definitional reasoning, property elimination, class inclusion.",
    [shape_cutout_set],
    vH(0, 2)).
tier(ref(bootstrap, vh_q_describe_this_shape), 1,
     [van_hiele_dissertation_corpus],
     "Fuys 1988 clinical-interview prompt; tracks van Hiele's level-0/1/2 distinction (paper #2 p.245, paper #7 pp.77-78).").

bootstrap(vh_q_minimum_properties_to_define, square_rectangle_classification, question,
    "Give the student a long list of properties for a square and ask: 'Which of these properties do you actually need to define a square? Which ones follow from others?' Level-1 answer: lists all properties without seeing redundancy. Level-2 answer: eliminates redundant properties by deduction (e.g., Murielle: 'all sides equal means opposite sides equal, so we don't need that').",
    [property_list_handout],
    vH(1, 2)).
tier(ref(bootstrap, vh_q_minimum_properties_to_define), 1,
     [van_hiele_dissertation_corpus],
     "Fuys 1988 clinical-interview prompt — Murielle's elimination utterance is the textbook level-2 marker.").

bootstrap(vh_q_prove_angle_sum_180, informal_deduction_with_parallels, question,
    "Ask the student to explain why the angles of a triangle sum to 180 degrees. Level-1 answer: 'I measured a bunch of triangles and they all came out close to 180.' Level-2 answer: 'I draw a parallel line through one vertex and use saws and ladders — corresponding angles are equal because of parallelism, and I see that the three angles around the vertex make a straight line.'",
    [paper, ruler, protractor, parallel_line_construction_tool],
    vH(1, 2)).
tier(ref(bootstrap, vh_q_prove_angle_sum_180), 1,
     [van_hiele_dissertation_corpus],
     "Direct van Hiele paper #7 pp.71-72: 'The children discovered by reasoning that the angles of a triangle sum up to 180 degrees... The logical relations were put into a logical pattern, using the implication arrow.'").

bootstrap(vh_q_what_is_a_definition_for, formal_deduction, question,
    "Ask the student: 'Why do we need definitions in geometry? What's the point of an axiom?' Level-2 answer: students use definitions but cannot articulate WHY they are indispensable. Level-3 answer: students articulate that axioms are starting points, definitions fix the meaning of terms, and theorems follow by logical ordering.",
    [class_discussion],
    vH(2, 3)).
tier(ref(bootstrap, vh_q_what_is_a_definition_for), 1,
     [van_hiele_dissertation_corpus],
     "Direct van Hiele paper #2 p.250: at level 3, students understand 'why axioms and definitions are indispensable'.").

bootstrap(vh_q_compare_geometries, axiom_system_comparison, question,
    "Present the student with two different axiom systems for geometry (e.g., Euclidean and one non-Euclidean variant) and ask: 'What are the consequences of changing this one axiom?' Level-3 answer: works deductively within one system but does not compare systems. Level-4 answer: compares systems, identifies which propositions survive the change and which fail.",
    [axiom_system_handout_pair],
    vH(3, 4)).
tier(ref(bootstrap, vh_q_compare_geometries), 1,
     [van_hiele_dissertation_corpus],
     "Direct van Hiele paper #8 p.192: only level-4 students 'can compare different theories... seek out missing axioms in other geometries'.").

%!  van_hiele_bootstrap_witness(?Id, -Witness) is nondet.
%
%   Inspectable proof object for a finite Van Hiele transition activity record.
%   The scope is the loaded transition table and its tier/source annotations.
van_hiele_bootstrap_witness(Id,
    _{ kind: van_hiele_transition_activity,
       scope: closed_world_finite_van_hiele_transition_table,
       id: Id,
       concept: Concept,
       kind_of_record: Kind,
       description: Description,
       materials: Materials,
       transition: Transition,
       support_status: SupportStatus,
       tier: Tier,
       sources: Sources,
       source_note: SourceNote,
       fact: bootstrap(Id, Concept, Kind, Description, Materials, Transition) }) :-
    bootstrap(Id, Concept, Kind, Description, Materials, Transition),
    van_hiele_tier_support(ref(bootstrap, Id),
                           SupportStatus,
                           Tier,
                           Sources,
                           SourceNote,
                           _Boundary).

%!  van_hiele_material_inference_witness(+Concept, +Premise, +Conclusion,
%!                                       +Polarity, -Witness) is semidet.
%
%   Inspectable proof object for the finite Van Hiele material-inference table.
van_hiele_material_inference_witness(Concept,
                                     Premise,
                                     Conclusion,
                                     Polarity,
                                     Witness) :-
    van_hiele_material_claim(Id, Concept, Premise, Conclusion, Polarity),
    van_hiele_tier_support(ref(material_inference, Concept, Id),
                           SupportStatus,
                           Tier,
                           Sources,
                           SourceNote,
                           Boundary),
    Witness = _{ kind: van_hiele_material_inference,
                 scope: closed_world_finite_van_hiele_transition_table,
                 claim_id: Id,
                 concept: Concept,
                 premise: Premise,
                 conclusion: Conclusion,
                 polarity: Polarity,
                 support_status: SupportStatus,
                 tier: Tier,
                 sources: Sources,
                 source_note: SourceNote,
                 boundary: Boundary,
                 fact: material_inference(Concept,
                                          Premise,
                                          Conclusion,
                                          Polarity) }.

%!  van_hiele_material_inference_by_id_witness(+Id, -Witness) is semidet.
%
%   Thin query surface for callers that know the stable finite claim id.
van_hiele_material_inference_by_id_witness(Id, Witness) :-
    van_hiele_material_claim(Id, Concept, Premise, Conclusion, Polarity),
    van_hiele_material_inference_witness(Concept,
                                        Premise,
                                        Conclusion,
                                        Polarity,
                                        Witness).

van_hiele_tier_support(Ref,
                       tiered_source_support,
                       Tier,
                       Sources,
                       SourceNote,
                       tier_record_found) :-
    tier(Ref, Tier, Sources, SourceNote),
    !.
van_hiele_tier_support(_Ref,
                       closed_world_unanchored_tier4_claim,
                       4,
                       [],
                       "No tier/4 source record is loaded for this finite Van Hiele material claim.",
                       no_tier_record_in_loaded_geometry_schema).

material_inference(Concept, Premise, Conclusion, Polarity) :-
    van_hiele_material_claim(_Id, Concept, Premise, Conclusion, Polarity).

% ─────────────────────────────────────────────────────────────────────────────
% Section D — The didactic-gap commitment as material_inference/4
%
% Van Hiele's central pedagogical claim: most secondary teaching speaks the
% language of a higher level than students inhabit; this PRODUCES failure
% (rather than failure being a result of student incapacity). Captured here
% as material inferences with `incompatible` polarity for the level-mismatch
% pattern — a teacher's language at level N+2 is incompatible with student
% understanding at level N.
%
% Note: ConceptId = `geometric_language` (a meta-concept this digger proposes
% the synthesizer add). If the synthesizer prefers to attach these to a
% `pedagogy` topic instead, that's a Wave 3 canonicalization decision.
% ─────────────────────────────────────────────────────────────────────────────

van_hiele_material_claim(didactic_gap_produces_memorization,
    geometric_language,
    "Teacher speaks at a level higher than the student's current level",
    "Student cannot understand and falls back to memorization or imitation",
    entitled).
tier(ref(material_inference, geometric_language, didactic_gap_produces_memorization), 1,
     [van_hiele_dissertation_corpus],
     "Direct van Hiele claim, Fuys 1988 p.7: 'many failures in teaching geometry result from a language barrier — the teacher using the language of a higher level than is understood by the student.' Captured as entitled inference because this IS van Hiele's diagnostic claim, not a forbidden incompatibility.").

van_hiele_material_claim(level_relativity_of_correctness,
    geometric_language,
    "A relation is correct at level N",
    "The same relation is correct at level N+1",
    incompatible).
tier(ref(material_inference, geometric_language, level_relativity_of_correctness), 1,
     [van_hiele_dissertation_corpus],
     "Direct van Hiele 1959/1984 p.246: 'A relation which is correct at one level can reveal itself to be incorrect at another' — e.g., at level 0 the relation 'square is NOT a rectangle' is correct (within the level-0 frame); at level 2 it is incorrect.").

van_hiele_material_claim(definitions_require_level_2,
    geometric_language,
    "Teacher presents geometric definitions to a student at level 1",
    "Student grasps the definition as a logical specification",
    incompatible).
tier(ref(material_inference, geometric_language, definitions_require_level_2), 1,
     [van_hiele_dissertation_corpus],
     "Direct van Hiele paper #7 pp.77-78: 'The pupils are not yet capable of differentiating [properties] into definitions and propositions. Logical relations are not yet a fit study-object for pupils who are at the first level of thinking.'").

van_hiele_material_claim(appropriate_phases_support_level_transition,
    geometric_language,
    "Student is at level 0",
    "Student can be brought to level 1 by appropriate instructional phases (information, guided orientation, explicitation, free orientation, integration)",
    entitled).
% Q-001 resolution (2026-05-04): the strong universal-phase-theory claim
% is demoted to Tier 4. Per Tio's split: keep the five vh_phase_*_general
% bootstrap activities at Tier 1 because they are useful pedagogical tools
% regardless of universality; drop the strong "all transitions go through
% these five phases" tier record (it now lives in OPEN_QUESTIONS.md as a
% genuinely-open theoretical question). The material_inference/4 record
% above is preserved as a discoverable claim, but no tier/4 anchors it,
% so it sits at Tier 4 in the schema's intended sense.
