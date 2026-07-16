% concepts/synthesizer_triangulations.pl — Wave 3 synthesizer Tier 2 promotions
% Schema: ../schema.pl
%
% Purpose: where two or more Wave-2 diggers independently anchored content
% to the same concept ID, this file records that triangulation as a
% Tier 2 ratification of the *concept*. The original Tier 1 records
% (van_hiele_marker/4 from the VH digger, bootstrap/6 from VdW or N103,
% geom_misconception/6 from the harvester, etc.) are not modified —
% this file *adds* a tier(ref(concept, ID), 2, ...) plus a triangulation/2
% wherever the cross-source agreement is clean.
%
% Selection criterion: at least two of {van_hiele_dissertation,
% van_de_walle, n103, misconception_harvester, lakoff_nunez,
% standards_mapper} attach to the same concept. The synthesizer
% does not introduce new claims here — only ratifies existing ones.
%
% Output cap: aiming for ~30 promotions; only the cleanest cases.

:- multifile tier/4, triangulation/2.
:- discontiguous tier/4, triangulation/2.

%!  synthesizer_concept_triangulation_witness(+ConceptId, -Witness) is semidet.
%
%   Inspectable witness for the finite cross-source concept triangulations
%   authored in this file.
synthesizer_concept_triangulation_witness(ConceptId, Witness) :-
    synthesizer_triangulation_tier_fact(ConceptId, Tier, Sources, Note),
    synthesizer_triangulation_concept_evidence(ConceptId,
                                               ConceptBoundary,
                                               ConceptEvidence),
    maplist(synthesizer_source_witness, Sources, SourceWitnesses),
    synthesizer_triangulation_evidence(ConceptId,
                                       TriangulationBoundary,
                                       TriangulationEvidence),
    Witness = _{ kind: geometry_synthesizer_concept_triangulation,
                 scope: closed_world_finite_synthesizer_triangulation_table,
                 concept: ConceptId,
                 tier: Tier,
                 sources: Sources,
                 source_witnesses: SourceWitnesses,
                 source_note: Note,
                 concept_boundary: ConceptBoundary,
                 concept_evidence: ConceptEvidence,
                 triangulation_boundary: TriangulationBoundary,
                 triangulation_evidence: TriangulationEvidence,
                 boundary: finite_cross_source_triangulation_claim_not_general_literature_model,
                 fact: tier(ref(concept, ConceptId), Tier, Sources, Note) }.

synthesizer_triangulation_tier_fact(ConceptId, Tier, Sources, Note) :-
    Clause = tier(ref(concept, ConceptId), Tier, Sources, Note),
    clause(Clause, true, Ref),
    clause_property(Ref, file(File)),
    sub_atom(File, _, _, _, 'geometry/concepts/synthesizer_triangulations.pl').

synthesizer_triangulation_concept_evidence(ConceptId,
                                           loaded_geometry_concept_record,
    _{ kind: resolved_synthesizer_triangulation_concept,
       concept: ConceptId,
       name: Name,
       topic: Topic,
       grade_bands: GradeBands,
       fact: geom_concept(ConceptId, Name, Topic, GradeBands) }) :-
    geom_concept(ConceptId, Name, Topic, GradeBands).

synthesizer_source_witness(source(Source, Agreement),
    _{ kind: source_agreement,
       source: Source,
       agreement: Agreement }).

synthesizer_triangulation_evidence(ConceptId,
                                   loaded_triangulation_record,
                                   Evidence) :-
    findall(_{ agreement: Agreement,
               fact: triangulation(ref(concept, ConceptId), Agreement) },
            ( Clause = triangulation(ref(concept, ConceptId), Agreement),
              clause(Clause, true, Ref),
              clause_property(Ref, file(File)),
              sub_atom(File,
                       _,
                       _,
                       _,
                       'geometry/concepts/synthesizer_triangulations.pl')
            ),
            RawEvidence),
    sort(RawEvidence, Evidence),
    Evidence \== [],
    !.
synthesizer_triangulation_evidence(_ConceptId,
                                   no_loaded_triangulation_record,
                                   []).

% =====================================================================
% Group 1 — Van Hiele dissertation × Van de Walle agreements
% =====================================================================

% square_rectangle_classification — VH and VdW both anchor levels 0/1/2
% (Van de Walle's `square_recognition` is the parallel ID; see Q-004).
tier(ref(concept, square_rectangle_classification), 2,
    [source(vh_diss, agrees), source(vdw, agrees), source(misconception_harvester, agrees)],
    "Triangulated by Wave 3 synthesizer. VH dissertation digger anchors levels 0/1/2 markers; VdW digger anchors level-2 inclusive-classification markers; misconception harvester ports BENNY rect-not-parallelogram families to this lineage. The most-anchored concept in the KB.").
triangulation(ref(concept, square_rectangle_classification),
    [source(vh_diss, agrees), source(vdw, agrees), source(misconception_harvester, agrees)]).

% polygon_recognition — VH levels 0/1, VdW Activity 20.x bootstraps + standards
tier(ref(concept, polygon_recognition), 2,
    [source(vh_diss, agrees), source(vdw, agrees)],
    "Triangulated. VH dissertation digger: levels 0 and 1 markers (paper #2, #5, #7; Fuys clinicals). VdW digger: 23 Activity 20.x bootstraps anchored here. Catch-all risk noted in Q-006 but cross-source attestation is strong.").
triangulation(ref(concept, polygon_recognition),
    [source(vh_diss, agrees), source(vdw, agrees)]).

% quadrilateral_classification — VdW vH markers L1/L2 + 5 VdW bootstraps + VH digger paper
tier(ref(concept, quadrilateral_classification), 2,
    [source(vdw, agrees), source(vh_diss, agrees)],
    "Triangulated. VdW Activity 20.2 + Activity 20.10 + level-1/2 markers; VH dissertation paper #2 p. 245 'definitions of figures come into play.'").
triangulation(ref(concept, quadrilateral_classification),
    [source(vdw, agrees), source(vh_diss, agrees)]).

% cube_class — VdW level-1 marker + 5 bootstraps from VdW; some N103 cross-talk on polyhedra
tier(ref(concept, cube_class), 2,
    [source(vdw, agrees), source(n103, partial)],
    "Triangulated. VdW p. 515 explicit kid-talk + 5 bootstrap activities; N103 Ch. 4 polyhedron treatment uses cube as canonical class member (partial agreement — N103 doesn't directly assert the level-1 'class with shared properties' move).").

% formal_deduction — VH level 3 + VdW Activity 20.15 'True or False' bootstrap
tier(ref(concept, formal_deduction), 2,
    [source(vh_diss, agrees), source(vdw, agrees)],
    "Triangulated. VH dissertation paper #2 p. 245 / p. 250 explicit. VdW Activity 20.15 anchors deductive reasoning bootstrap here. Cross-source agreement on the level-3 cognitive claim.").

% informal_deduction_with_parallels — VH level-2 + VdW saw/ladder activities
tier(ref(concept, informal_deduction_with_parallels), 2,
    [source(vh_diss, agrees), source(vdw, agrees)],
    "Triangulated. VH dissertation paper #6 p. 42 + paper #7 pp. 71-72; VdW Ch. 20 saw/ladder paragraph + Activity 20.17 angle-sum.").
triangulation(ref(concept, informal_deduction_with_parallels),
    [source(vh_diss, agrees), source(vdw, agrees)]).

% =====================================================================
% Group 2 — VdW × N103 × misconception harvester convergences
% =====================================================================

% pythagorean_theorem — VdW Act 20.16 + N103 Ch. 8 + 3 misconceptions from harvester
tier(ref(concept, pythagorean_theorem), 2,
    [source(vdw, agrees), source(n103, agrees), source(misconception_harvester, agrees)],
    "Triangulated. VdW Activity 20.16 'Pythagorean Relationship' + N103 Activities 8.1/8.2 + 3 research-corpus misconceptions. Strong multi-source anchor.").
triangulation(ref(concept, pythagorean_theorem),
    [source(vdw, agrees), source(n103, agrees), source(misconception_harvester, agrees)]).

% triangle_angle_sum_180 — N103 (3 bootstraps in Ch. 1) + concept.angles record + harvester misconceptions
tier(ref(concept, triangle_angle_sum_180), 2,
    [source(n103, agrees), source(misconception_harvester, agrees)],
    "Triangulated. N103 Activities 1.1, 1.2, 1.3 (parallel-grid, envelope-fold, tearing-corners) all converge on this concept. Misconception harvester: triangle_angle_sum_depends_on_size attests the same concept from research corpus. Q-005 asks whether this and the level-2 conjecture-form `triangle_angle_sum` should merge; both records remain valid as level-2 conjecture vs level-3 formal statement.").

% circle_circumference_formula — N103 Activity 9.1 + measuring_stick metaphor anchor
tier(ref(concept, circle_circumference_formula), 2,
    [source(n103, agrees), source(ln, partial)],
    "Triangulated. N103 Activity 9.1 'Discovering Pi' (string-around-object). Measuring-stick metaphor record (metaphors/measuring_stick.pl) anchors here as the 1D unit-iteration applied to a curved boundary.").

% area_unit_is_a_square — N103 + L&N partial + measurement misconceptions
tier(ref(concept, area_unit_is_a_square), 2,
    [source(n103, agrees), source(ln, partial), source(misconceptions_measurement_pl, agrees)],
    "Triangulated. N103 Ch. 5 introduction + measuring_stick metaphor (L&N partial) + 2 measurement misconceptions. Already had triangulation/2 in measuring_stick.pl; this concept-level tier ratifies it.").

% volume_of_pyramid_formula — N103 Act 4.13 + 4.12 + measuring_stick metaphor
tier(ref(concept, volume_of_pyramid_formula), 2,
    [source(n103, agrees), source(ln, partial)],
    "Triangulated. N103 Activities 4.12 + 4.13 + measuring-stick metaphor record. The 1/3 factor emerges via fluid-displacement scoop-counting in N103.").

% volume_of_prism_formula — N103 Act 4.5 + measuring_stick metaphor
tier(ref(concept, volume_of_prism_formula), 2,
    [source(n103, agrees), source(ln, partial)],
    "Triangulated. N103 Activity 4.5 'Making Sense of Volume' + measuring-stick metaphor record. Layer-by-layer block stacking on geoboard base.").

% surface_area_of_sphere — N103 Act 9.13 + measuring_stick + harvester (lateral_vs_total)
tier(ref(concept, surface_area_of_sphere), 2,
    [source(n103, agrees), source(ln, partial), source(misconception_harvester, partial)],
    "Triangulated. N103 Activity 9.13 (orange-peel) + measuring-stick metaphor + harvester references via `lateral_vs_total_surface_confusion`. The harvester partial-attestation is because the misconception isn't sphere-specific (flagged in harvest log).").

% picks_formula — N103 Act 6.7 + measuring_stick metaphor
tier(ref(concept, picks_formula), 2,
    [source(n103, agrees), source(ln, partial)],
    "Triangulated. N103 Ch. 6 Activity 6.7 + measuring-stick metaphor (digger interpretation). Tier 3 in metaphor file but the concept itself has two-source attestation.").

% =====================================================================
% Group 3 — standards-anchored concepts triangulating with concept records
% =====================================================================

% quadrilateral_hierarchy — CCSS 3.G.A.1 + Indiana + classification.pl + misc + N103 inclusive
tier(ref(concept, quadrilateral_hierarchy), 2,
    [source(ccss, agrees), source(in_indiana, agrees), source(misconception_harvester, agrees), source(n103, agrees)],
    "Quadruple-source triangulation. CCSS 3.G.A.1 verbatim, Indiana standard parallel, classification.pl Tier 1 anchor, 4 misconceptions, N103 Ch. 2 inclusive-definitions framing. The richest concept anchor in the KB.").
triangulation(ref(concept, quadrilateral_hierarchy),
    [source(ccss, agrees), source(in_indiana, agrees), source(misconception_harvester, agrees), source(n103, agrees)]).

% rectangle_as_parallelogram — classification.pl + 3 BENNY misconceptions
tier(ref(concept, rectangle_as_parallelogram), 2,
    [source(classification_concepts, agrees), source(misconception_harvester, agrees)],
    "Triangulated. classification.pl Tier 1 concept anchor + 3 ported BENNY misconceptions (rect_not_parallelogram_partitional, parallelogram_is_rectangle, rectangle_not_parallelogram_disjoint). One of the densest misconception clusters.").

% square_as_rhombus — classification.pl + 2 BENNY misconceptions
tier(ref(concept, square_as_rhombus), 2,
    [source(classification_concepts, agrees), source(misconception_harvester, agrees)],
    "Triangulated. classification.pl + ported BENNY square_not_rhombus and parallelogram_is_rhombus.").

% parallelogram_as_quadrilateral — classification.pl + 2 BENNY misconceptions
tier(ref(concept, parallelogram_as_quadrilateral), 2,
    [source(classification_concepts, agrees), source(misconception_harvester, agrees)],
    "Triangulated. classification.pl + ported BENNY quadrilateral_is_parallelogram and parallelogram_not_quadrilateral.").

% =====================================================================
% Group 4 — measurement / area-perimeter cluster (high misconception density)
% =====================================================================

% area_as_array_structure — area_perimeter.pl + 4 misconceptions including BENNY ports
tier(ref(concept, area_as_array_structure), 2,
    [source(area_perimeter_concepts, agrees), source(misconception_harvester, agrees)],
    "Triangulated. area_perimeter.pl concept anchor + 4 misconceptions (area_formula_inverted BENNY port + research-corpus rows). Q-MH-C asks whether this belongs in attributes.pl instead — flagged but not resolved.").

% area_as_interior_coverage — area_perimeter.pl + 3 BENNY misconceptions
tier(ref(concept, area_as_interior_coverage), 2,
    [source(area_perimeter_concepts, agrees), source(misconception_harvester, agrees)],
    "Triangulated. Container × Measuring-Stick hybrid concept (per L&N audit). Anchors area_counted_as_perimeter BENNY port + research-corpus area-vs-boundary confusions.").

% perimeter_as_boundary_traversal — concept anchor + 5 misconceptions
tier(ref(concept, perimeter_as_boundary_traversal), 2,
    [source(area_perimeter_concepts, agrees), source(misconception_harvester, agrees)],
    "Triangulated. Concept anchor + 5 misconceptions including 2 BENNY ports (perimeter_incomplete_traversal, perimeter_formula_inverted) + harvester research rows.").

% =====================================================================
% Group 5 — transformations cluster
% =====================================================================

% reflection — transformations.pl + 3 misconceptions (research-corpus harvest)
tier(ref(concept, reflection), 2,
    [source(transformations_concepts, agrees), source(misconception_harvester, agrees)],
    "Triangulated. N103 Ch. 15 transformations + research-corpus misconceptions cluster (oblique_mirror_distorted_image, reflection_by_linguistic_opposites, reflection_as_moving_mirror).").

% translation — transformations.pl + 3 research-corpus misconceptions
tier(ref(concept, translation), 2,
    [source(transformations_concepts, agrees), source(misconception_harvester, agrees)],
    "Triangulated. transformations.pl concept + 3 harvester misconceptions (translation_static_endpoint_relationship, translation_acts_only_on_object, zero_vector_means_no_translation).").

% line_of_symmetry — transformations.pl + 2 misconceptions
tier(ref(concept, line_of_symmetry), 2,
    [source(transformations_concepts, agrees), source(misconception_harvester, agrees)],
    "Triangulated. line_of_symmetry concept + harvester rectangle_diagonals_as_symmetry_axes + line_not_its_own_symmetry_axis.").

% =====================================================================
% Group 6 — similarity / coordinate / shape-recognition triangulations
% =====================================================================

% similar_figures — concept + 5 research-corpus misconceptions
tier(ref(concept, similar_figures), 2,
    [source(similarity_concepts, agrees), source(misconception_harvester, agrees)],
    "Triangulated. similarity_congruence.pl + 5 misconceptions (similarity_via_additive_difference Tier 2 from harvester + 4 single-source).").

% slope_as_ratio_of_change — concept + 3 misconceptions
tier(ref(concept, slope_as_ratio_of_change), 2,
    [source(coordinate_concepts, agrees), source(misconception_harvester, agrees)],
    "Triangulated. coordinate_geometry.pl + 3 harvester rows (steepness_as_height_only, slope_increases_along_hill, slope_without_horizontal_reference).").

% shape_identified_by_properties_not_appearance — concept + 4 misconceptions
tier(ref(concept, shape_identified_by_properties_not_appearance), 2,
    [source(shape_recognition_concepts, agrees), source(misconception_harvester, agrees)],
    "Triangulated. concept anchor + 4 misconceptions (specific_drawing_taken_for_general, shape_refused_in_nonstandard_orientation, etc.). Anchors the level-1 'figure as totality of properties' move to its negation patterns.").

% orientation_invariant_naming — concept + 2 misconceptions (CCSS K.G.A.2 also relevant)
tier(ref(concept, orientation_invariant_naming), 2,
    [source(classification_concepts, agrees), source(misconception_harvester, agrees), source(ccss, partial)],
    "Triangulated. concept + 2 misconceptions + CCSS K.G.A.2 statement (which uses 'shape_naming_orientation_invariant' as its anchor — same phenomenon, different ID; see coverage gap notes).").

% =====================================================================
% Group 7 — area / volume scaling
% =====================================================================

% area_scales_quadratically — concept + 2 misconceptions
tier(ref(concept, area_scales_quadratically), 2,
    [source(area_perimeter_concepts, agrees), source(misconception_harvester, agrees)],
    "Triangulated. concept + linear_scaling_assumed_for_area (Tier 2 harvester, 5 papers) + area_unit_conversion_linear.").

% volume_scales_cubically — concept + 2 misconceptions
tier(ref(concept, volume_scales_cubically), 2,
    [source(volume_concepts, agrees), source(misconception_harvester, agrees)],
    "Triangulated. concept + volume_conversion_with_linear_factor + volume_scaled_linearly.").

% volume_as_filling_3d_space — concept + 2 misconceptions
tier(ref(concept, volume_as_filling_3d_space), 2,
    [source(volume_concepts, agrees), source(misconception_harvester, agrees)],
    "Triangulated. concept + volume_confused_with_area_or_edges + volume_by_counting_visible_faces (Tier 2 harvester, 4 papers).").
