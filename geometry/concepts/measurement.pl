% concepts/measurement.pl — geometry concepts in the measurement topic.
%
% The measurement topic atom was added to valid_topic/1 in schema.pl on
% 2026-05-03 to give length / volume / surface-area unit-iteration
% concepts a clean home (rather than overloading area_perimeter).
%
% Records here include both Q-007-migrated concepts (originally placed
% in classification.pl by the VdW digger under charter restriction) and
% concepts migrated from synthesizer_anchors.pl + standards_anchors.pl
% whose proper topic was always measurement but had no place to land.
%
% Schema: ../schema.pl

:- multifile geom_concept/4, geom_misconception/6, material_inference/4, tier/4.
:- discontiguous geom_concept/4, geom_misconception/6, material_inference/4, tier/4.

%!  measurement_concept_witness(+ConceptId, -Witness) is semidet.
%
%   Inspectable witness for one concept row in the closed-world finite
%   measurement concept table.
measurement_concept_witness(ConceptId, Witness) :-
    measurement_concept_fact(ConceptId, Name, Topic, GradeBands),
    measurement_concept_tier_fact(ConceptId,
                                  Tier,
                                  Sources,
                                  SourceNote),
    maplist(measurement_source_witness, Sources, SourceWitnesses),
    Witness = _{ kind: geometry_measurement_concept,
                 scope: closed_world_finite_measurement_concept_table,
                 concept: ConceptId,
                 name: Name,
                 topic: Topic,
                 grade_bands: GradeBands,
                 tier: Tier,
                 sources: Sources,
                 source_witnesses: SourceWitnesses,
                 source_note: SourceNote,
                 boundary: finite_measurement_concept_table_not_general_measurement_theory,
                 fact: geom_concept(ConceptId, Name, Topic, GradeBands) }.

measurement_concept_fact(ConceptId, Name, Topic, GradeBands) :-
    Clause = geom_concept(ConceptId, Name, Topic, GradeBands),
    clause(Clause, true, Ref),
    clause_property(Ref, file(File)),
    sub_atom(File, _, _, _, 'geometry/concepts/measurement.pl').

measurement_concept_tier_fact(ConceptId, Tier, Sources, SourceNote) :-
    Clause = tier(ref(concept, ConceptId), Tier, Sources, SourceNote),
    clause(Clause, true, Ref),
    clause_property(Ref, file(File)),
    sub_atom(File, _, _, _, 'geometry/concepts/measurement.pl').

%!  measurement_misconception_witness(+Id, -Witness) is semidet.
%
%   Inspectable witness for one misconception row in the closed-world finite
%   measurement misconception table.
measurement_misconception_witness(Id, Witness) :-
    measurement_misconception_fact(Id,
                                   Concept,
                                   Name,
                                   Triggers,
                                   Repair,
                                   Citation),
    measurement_misconception_tier_fact(Id,
                                        Tier,
                                        Sources,
                                        SourceNote),
    maplist(measurement_source_witness, Sources, SourceWitnesses),
    Witness = _{ kind: geometry_measurement_misconception,
                 scope: closed_world_finite_measurement_misconception_table,
                 id: Id,
                 concept: Concept,
                 name: Name,
                 triggers: Triggers,
                 repair: Repair,
                 citation: Citation,
                 tier: Tier,
                 sources: Sources,
                 source_witnesses: SourceWitnesses,
                 source_note: SourceNote,
                 boundary: finite_measurement_misconception_table_not_general_diagnostic_model,
                 fact: geom_misconception(Id,
                                          Concept,
                                          Name,
                                          Triggers,
                                          Repair,
                                          Citation) }.

measurement_misconception_fact(Id, Concept, Name, Triggers, Repair, Citation) :-
    Clause = geom_misconception(Id, Concept, Name, Triggers, Repair, Citation),
    clause(Clause, true, Ref),
    clause_property(Ref, file(File)),
    sub_atom(File, _, _, _, 'geometry/concepts/measurement.pl').

measurement_misconception_tier_fact(Id, Tier, Sources, SourceNote) :-
    Clause = tier(ref(misconception, Id), Tier, Sources, SourceNote),
    clause(Clause, true, Ref),
    clause_property(Ref, file(File)),
    sub_atom(File, _, _, _, 'geometry/concepts/measurement.pl').

measurement_source_witness(source(Source, Agreement),
    _{ kind: source_agreement,
       source: Source,
       agreement: Agreement }) :-
    !.
measurement_source_witness(Source,
    _{ kind: source_reference,
       source: Source }).

% =====================================================================
% Migrated from classification.pl 2026-05-04 (Q-007 resolution)
% Source: VdW Ch. 19 pp. 486, 490.
% =====================================================================

geom_concept(ruler_units_vs_marks,
    "A ruler measures the spaces between marks (units), not the marks themselves",
    measurement,
    [1,2,3,4]).

tier(ref(concept, ruler_units_vs_marks), 1, [source(vdw, agrees)],
    "VdW Ch. 19 p. 486, 490. Migrated from classification.pl 2026-05-04 (Q-007); topic = measurement (added to valid_topic 2026-05-03).").

geom_misconception(
    ruler_counts_marks_not_spaces,
    ruler_units_vs_marks,
    "Ruler reading errors: counting marks instead of spaces, or starting at 1 instead of 0",
    [ "I counted the lines on the ruler",
      "the ruler started at 1 so I read 1",
      "I lined up with the end of the ruler not the zero mark" ],
    "Have students construct handmade rulers, with numbers initially written in the center of each unit to make it clear that numbers count the spaces between marks. Use the 'broken ruler' assessment: hand students a ruler missing its first two units. Note who says it cannot be used (mark-counting) and who matches whole units meaningfully starting wherever the object lies (space-counting).",
    [vdw_ch19_p486, vdw_ch19_p490]).

tier(ref(misconception, ruler_counts_marks_not_spaces), 1, [source(vdw, agrees)],
    "VdW Ch. 19 pp. 486, 490 names the misconception cluster and the broken-ruler diagnostic. Migrated from classification.pl 2026-05-04 (Q-007).").

% =====================================================================
% Migrated from synthesizer_anchors.pl 2026-05-04 (Q-007 resolution)
% Source: L&N + synthesizer.
% =====================================================================

geom_concept(length_measurement_as_unit_iteration,
    "Length measurement as iterated end-to-end placement of a unit segment (the ruler postulate)",
    measurement,
    [1,2,3,4,5,6,7,8]).

tier(ref(concept, length_measurement_as_unit_iteration), 3,
    [source(ln, partial), source(synthesizer, agrees)],
    "L&N's measuring-stick schema for arithmetic, inverted to geometric measurement. Tier 3 mirrors metaphor record. Likely upgraded to Tier 2 once Van de Walle direct treatment is cross-referenced. Migrated from synthesizer_anchors.pl 2026-05-04 (Q-007); topic refined from area_perimeter to measurement.").

% =====================================================================
% Migrated from standards_anchors.pl 2026-05-04 (Q-007 resolution)
% Source: Indiana 6.GM.1.
% =====================================================================

geom_concept(measurement_unit_conversion,
    "Converting between Customary and metric measurement systems given conversion factors; applying conversions in real-world problems",
    measurement,
    [6]).
tier(ref(concept, measurement_unit_conversion), 2,
    [source(in_indiana, agrees), source(synthesizer, agrees)],
    "6.GM.1 anchor — Indiana-specific measurement-conversion standard. Migrated from standards_anchors.pl 2026-05-04 (Q-007); topic refined from area_perimeter to measurement now that the topic atom exists.").
