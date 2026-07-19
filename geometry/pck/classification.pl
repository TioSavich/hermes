% pck/classification.pl — pck_synthesis/5 records covering preservice-
% teacher pedagogical-content-knowledge gaps in classification topic.
%
% Q-MH-B resolution (2026-05-04): rather than extending geom_misconception/6
% with a `population` slot or harvesting PST rows as student misconceptions,
% Tio confirmed that pck_synthesis/5 (added to the schema 2026-05-03) is
% the right slot. PCK syntheses are *synthesis-pointers* back into the
% existing tagging layer — they don't stand alone. This reflects Tio's
% flatter framing of PCK (memory: user_pck_flatter_framing.md): kid-
% explanation and teacher-explanation are points on the same continuum,
% not two stacked layers.
%
% Each record anchors to an existing geom_concept, points to refs in the
% tagging layer (van_hiele_marker, geom_misconception, metaphor_source,
% material_inference) that capture how kids think about this concept,
% lists the highest-leverage teacher moves (bootstrap activities), and
% references the developmental_marker arcs from concepts/developmental_arcs.pl
% where applicable.
%
% Citations: research_corpus rows describing preservice or in-service
% teachers (rather than student misconceptions). The harvester earlier
% flagged 5-10 such rows for potential PCK harvesting.
%
% Schema: ../schema.pl

:- multifile pck_synthesis/5.
:- discontiguous pck_synthesis/5.

%!  pck_synthesis_witness(+ConceptId, -Witness) is semidet.
%
%   Inspectable witness for the finite loaded PCK synthesis registry. A
%   witness exists only when every synthesis pointer resolves in the loaded
%   geometry KB; it is not a general model of teacher knowledge.
pck_synthesis_witness(ConceptId, Witness) :-
    witness_dict:witness_dict(geometry_pck_synthesis, closed_world_finite_pck_synthesis_registry,
                              _{concept: ConceptId,
                 concept_boundary: ConceptBoundary,
                 concept_evidence: ConceptEvidence,
                 key_kid_thinking_refs: KeyKidThinking,
                 teacher_move_refs: KeyTeacherMoves,
                 developmental_refs: DevelopmentalRefs,
                 citations: Citations,
                 resolved_references: ResolvedReferences,
                 boundary: finite_pck_synthesis_pointer_not_general_teacher_knowledge_model,
                 fact: pck_synthesis(ConceptId,
                                     KeyKidThinking,
                                     KeyTeacherMoves,
                                     DevelopmentalRefs,
                                     Citations) }, WitnessDict43),
    pck_synthesis(ConceptId,
                  KeyKidThinking,
                  KeyTeacherMoves,
                  DevelopmentalRefs,
                  Citations),
    pck_concept_witness(ConceptId, ConceptBoundary, ConceptEvidence),
    append([KeyKidThinking, KeyTeacherMoves, DevelopmentalRefs], Refs),
    maplist(pck_reference_witness, Refs, ResolvedReferences),
    Witness = WitnessDict43.

pck_concept_witness(ConceptId, loaded_geometry_concept_record,
    _{ kind: resolved_pck_concept,
       concept: ConceptId,
       name: Name,
       topic: Topic,
       grade_bands: GradeBands,
       tier_boundary: TierBoundary,
       tier_evidence: TierEvidence,
       fact: geom_concept(ConceptId, Name, Topic, GradeBands) }) :-
    geom_concept(ConceptId, Name, Topic, GradeBands),
    pck_tier_evidence(ref(concept, ConceptId), TierBoundary, TierEvidence).

pck_reference_witness(ref(misconception, Id),
    _{ kind: resolved_pck_reference,
       ref: ref(misconception, Id),
       status: loaded_misconception_record,
       concept: ConceptId,
       name: Name,
       triggers: Triggers,
       repair: Repair,
       citations: Citation,
       tier_boundary: TierBoundary,
       tier_evidence: TierEvidence,
       triangulation_evidence: TriangulationEvidence,
       fact: geom_misconception(Id, ConceptId, Name, Triggers, Repair, Citation) }) :-
    geom_misconception(Id, ConceptId, Name, Triggers, Repair, Citation),
    pck_tier_evidence(ref(misconception, Id), TierBoundary, TierEvidence),
    pck_triangulation_evidence(ref(misconception, Id), TriangulationEvidence).

pck_reference_witness(ref(metaphor, ConceptId, Metaphor),
    _{ kind: resolved_pck_reference,
       ref: ref(metaphor, ConceptId, Metaphor),
       status: loaded_metaphor_record,
       concept: ConceptId,
       metaphor: Metaphor,
       mapping: Mapping,
       citations: Citation,
       tier_boundary: TierBoundary,
       tier_evidence: TierEvidence,
       triangulation_evidence: TriangulationEvidence,
       fact: metaphor_source(ConceptId, Metaphor, Mapping, Citation) }) :-
    metaphor_source(ConceptId, Metaphor, Mapping, Citation),
    pck_tier_evidence(ref(metaphor, ConceptId, Metaphor),
                      TierBoundary,
                      TierEvidence),
    pck_triangulation_evidence(ref(metaphor, ConceptId, Metaphor),
                               TriangulationEvidence).

pck_reference_witness(ref(van_hiele, ConceptId, Level),
    _{ kind: resolved_pck_reference,
       ref: ref(van_hiele, ConceptId, Level),
       status: loaded_van_hiele_marker_record,
       concept: ConceptId,
       level: Level,
       marker_phrases: MarkerPhrases,
       citations: Citation,
       tier_boundary: TierBoundary,
       tier_evidence: TierEvidence,
       triangulation_evidence: TriangulationEvidence,
       fact: van_hiele_marker(ConceptId, Level, MarkerPhrases, Citation) }) :-
    van_hiele_marker(ConceptId, Level, MarkerPhrases, Citation),
    pck_tier_evidence(ref(van_hiele, ConceptId, Level),
                      TierBoundary,
                      TierEvidence),
    pck_triangulation_evidence(ref(van_hiele, ConceptId, Level),
                               TriangulationEvidence).

pck_reference_witness(ref(bootstrap, Id),
    _{ kind: resolved_pck_reference,
       ref: ref(bootstrap, Id),
       status: loaded_bootstrap_record,
       concept: ConceptId,
       activity_kind: ActivityKind,
       prompt: Prompt,
       tools: Tools,
       target_transition: TargetTransition,
       tier_boundary: TierBoundary,
       tier_evidence: TierEvidence,
       fact: bootstrap(Id,
                       ConceptId,
                       ActivityKind,
                       Prompt,
                       Tools,
                       TargetTransition) }) :-
    bootstrap(Id, ConceptId, ActivityKind, Prompt, Tools, TargetTransition),
    pck_tier_evidence(ref(bootstrap, Id), TierBoundary, TierEvidence).

pck_reference_witness(ref(developmental, ArcId),
    _{ kind: resolved_pck_reference,
       ref: ref(developmental, ArcId),
       status: loaded_developmental_marker_record,
       arc: ArcId,
       from_stance: FromStance,
       to_stance: ToStance,
       evidence: Evidence,
       fact: developmental_marker(ArcId, FromStance, ToStance, Evidence) }) :-
    developmental_marker(ArcId, FromStance, ToStance, Evidence).

pck_reference_witness(ref(material_inference, ConceptId, ClaimId),
    _{ kind: resolved_pck_reference,
       ref: ref(material_inference, ConceptId, ClaimId),
       status: loaded_material_inference_tier_record,
       concept: ConceptId,
       claim_id: ClaimId,
       boundary: finite_level_relative_material_claim,
       tier_boundary: TierBoundary,
       tier_evidence: TierEvidence,
       material_rows: MaterialRows }) :-
    pck_tier_evidence(ref(material_inference, ConceptId, ClaimId),
                      TierBoundary,
                      TierEvidence),
    findall(_{ premise: Premise,
               conclusion: Conclusion,
               polarity: Polarity,
               fact: material_inference(ConceptId,
                                        Premise,
                                        Conclusion,
                                        Polarity) },
            material_inference(ConceptId, Premise, Conclusion, Polarity),
            RawMaterialRows),
    sort(RawMaterialRows, MaterialRows),
    MaterialRows \== [].

pck_tier_evidence(Ref, loaded_tier_record, TierEvidence) :-
    findall(_{ tier: Tier,
               sources: Sources,
               source_note: SourceNote,
               fact: tier(Ref, Tier, Sources, SourceNote) },
            tier(Ref, Tier, Sources, SourceNote),
            RawTierEvidence),
    sort(RawTierEvidence, TierEvidence),
    TierEvidence \== [],
    !.
pck_tier_evidence(_Ref, no_loaded_tier_record, []).

pck_triangulation_evidence(Ref, TriangulationEvidence) :-
    findall(_{ agreement: Agreement,
               fact: triangulation(Ref, Agreement) },
            triangulation(Ref, Agreement),
            RawTriangulationEvidence),
    sort(RawTriangulationEvidence, TriangulationEvidence).

% =====================================================================
% PCK-1 — quadrilateral_hierarchy: PSTs hold restricted concept images
% =====================================================================

pck_synthesis(quadrilateral_hierarchy,
    [ ref(misconception, parallelogram_trapezoid_confusion),
      ref(misconception, square_not_rectangle),
      ref(misconception, rect_not_parallelogram_partitional),
      ref(metaphor, category_of_shapes_as_container, categories_are_containers),
      ref(van_hiele, square_rectangle_classification, 0),
      ref(van_hiele, square_rectangle_classification, 1),
      ref(van_hiele, square_rectangle_classification, 2)
    ],
    [ ref(bootstrap, vdw_act_20_15_true_or_false),
      ref(bootstrap, vdw_sports_teams_metaphor),
      ref(bootstrap, vdw_act_20_10_mystery_definition),
      ref(bootstrap, vdw_act_20_03_minimal_defining_lists)
    ],
    [ ref(developmental, square_classification_arc),
      ref(developmental, trapezoid_classification_arc)
    ],
    [corpus_pst_quadrilateral_hierarchy, ng_2012, fuentes_ma_2018, pickreign_2007]).

% =====================================================================
% PCK-2 — square_rectangle_classification: PSTs cannot model class inclusion
% =====================================================================

pck_synthesis(square_rectangle_classification,
    [ ref(misconception, square_not_rectangle),
      ref(misconception, square_not_rhombus),
      ref(van_hiele, square_rectangle_classification, 0),
      ref(van_hiele, square_rectangle_classification, 1),
      ref(van_hiele, square_rectangle_classification, 2),
      ref(van_hiele, square_recognition, 2),
      ref(metaphor, category_of_shapes_as_container, categories_are_containers)
    ],
    [ ref(bootstrap, vh_q_square_is_rectangle),
      ref(bootstrap, vh_q_minimum_properties_to_define),
      ref(bootstrap, vdw_sports_teams_metaphor),
      ref(bootstrap, vdw_act_20_15_true_or_false)
    ],
    [ ref(developmental, square_classification_arc) ],
    [corpus_pst_class_inclusion, hourigan_odonoghue_2013, walcott_mohr_kastberg_2009]).

% =====================================================================
% PCK-3 — orientation_invariant_naming: PSTs treat tilted shapes as different shapes
% =====================================================================

pck_synthesis(orientation_invariant_naming,
    [ ref(misconception, square_only_axis_aligned),
      ref(misconception, triangle_only_horizontal_base),
      ref(misconception, triangle_upside_down),
      ref(van_hiele, tilted_square_as_diamond, 0),
      ref(van_hiele, triangle_recognition, 0)
    ],
    [ ref(bootstrap, vdw_act_20_01_shape_sorts),
      ref(bootstrap, vdw_act_20_04_shape_show_and_hunt),
      ref(bootstrap, vdw_act_20_11_triangle_sort)
    ],
    [],
    [corpus_pst_prototype_concept_image, fischbein_1999, watson_2010]).

% =====================================================================
% PCK-4 — definition_requires_necessary_and_sufficient_conditions:
% PSTs offer over-restrictive or over-broad definitions
% =====================================================================

pck_synthesis(definition_requires_necessary_and_sufficient_conditions,
    [ ref(misconception, definition_via_inessential_features),
      ref(misconception, definitional_under_or_over_specification),
      ref(misconception, empirical_check_as_proof),
      ref(misconception, supporting_example_treated_as_proof),
      ref(van_hiele, minimal_defining_list, 2)
    ],
    [ ref(bootstrap, vdw_act_20_03_minimal_defining_lists),
      ref(bootstrap, vdw_act_20_10_mystery_definition),
      ref(bootstrap, vdw_act_20_05_whats_my_shape)
    ],
    [],
    [corpus_pst_definitions, ma_1999, fuentes_ma_2018]).

% =====================================================================
% PCK-5 — exclusive_to_inclusive_transition: PSTs default to exclusive
% definitions and don't model the developmental shift
% =====================================================================

pck_synthesis(exclusive_to_inclusive_transition,
    [ ref(misconception, parallelogram_trapezoid_confusion),
      ref(material_inference, parallelogram_as_trapezoid, exclusive_stance),
      ref(van_hiele, square_rectangle_classification, 2)
    ],
    [ ref(bootstrap, vh_q_rhombus_is_parallelogram),
      ref(bootstrap, vdw_sports_teams_metaphor)
    ],
    [ ref(developmental, trapezoid_classification_arc),
      ref(developmental, square_classification_arc)
    ],
    [corpus_pst_inclusive_definitions, n103_ch2, walcott_mohr_kastberg_2009]).
