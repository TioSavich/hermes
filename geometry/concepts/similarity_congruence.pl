% concepts/similarity_congruence.pl — geometry concepts in the similarity_congruence topic.
%
% Append clauses for: geom_concept/4, geom_misconception/6,
%                     material_inference/4, tier/4 (covering all of these).
% Cross-tagging (van_hiele_marker, metaphor_source, bootstrap,
% standard_anchor) lives in the corresponding subdirs.
%
% Schema: ../schema.pl

:- multifile geom_concept/4, geom_misconception/6, material_inference/4, tier/4.
:- discontiguous geom_concept/4, geom_misconception/6, material_inference/4, tier/4,
               similarity_material_claim/5.

%!  similarity_material_claim_witness(+Id, -Witness) is semidet.
%
%   Inspectable proof object for a finite similarity/congruence material row.
similarity_material_claim_witness(Id, Witness) :-
    similarity_material_claim(Id, Concept, Premise, Conclusion, Polarity),
    similarity_primary_tier(Concept, Tier, Sources, SourceNote, TierEvidence),
    similarity_related_misconception_witnesses(Concept, MisconceptionWitnesses),
    similarity_condition_roles(Id, Roles),
    Witness = _{ kind: geometry_similarity_material_inference,
                 scope: closed_world_finite_similarity_congruence_table,
                 id: Id,
                 concept: Concept,
                 premise: Premise,
                 conclusion: Conclusion,
                 polarity: Polarity,
                 tier: Tier,
                 sources: Sources,
                 source_note: SourceNote,
                 tier_evidence: TierEvidence,
                 boundary: finite_similarity_claim_not_general_polygon_similarity_theory,
                 condition_roles: Roles,
                 related_misconception_witnesses: MisconceptionWitnesses,
                 fact: material_inference(Concept, Premise, Conclusion, Polarity) }.

similarity_primary_tier(Concept, Tier, Sources, SourceNote, TierEvidence) :-
    findall(tier_entry(CandidateTier,
                       CandidateSources,
                       CandidateSourceNote),
            tier(ref(concept, Concept),
                 CandidateTier,
                 CandidateSources,
                 CandidateSourceNote),
            RawEntries),
    sort(RawEntries, SortedEntries),
    SortedEntries = [tier_entry(Tier, Sources, SourceNote)|_],
    findall(_{ tier: EntryTier,
               sources: EntrySources,
               source_note: EntrySourceNote },
            member(tier_entry(EntryTier, EntrySources, EntrySourceNote),
                   SortedEntries),
            TierEvidence).

similarity_related_misconception_witnesses(Concept, Witnesses) :-
    findall(Witness,
            similarity_misconception_witness(Concept, Witness),
            RawWitnesses),
    sort(RawWitnesses, Witnesses).

similarity_misconception_witness(Concept,
    _{ kind: geometry_similarity_misconception_support,
       id: Id,
       concept: Concept,
       name: Name,
       tier: Tier,
       sources: Sources,
       source_note: SourceNote,
       fact: geom_misconception(Id, Concept, Name, Triggers, Repair, Citation),
       triggers: Triggers,
       repair: Repair,
       citation: Citation }) :-
    geom_misconception(Id, Concept, Name, Triggers, Repair, Citation),
    tier(ref(misconception, Id), Tier, Sources, SourceNote).

similarity_condition_roles(similarity_definition,
                           [ _{ kind: sufficiency_component,
                                role: corresponding_angles_equal },
                             _{ kind: sufficiency_component,
                                role: corresponding_sides_proportional }
                           ]) :-
    !.
similarity_condition_roles(_, []).

material_inference(Concept, Premise, Conclusion, Polarity) :-
    similarity_material_claim_witness(_Id, Witness),
    get_dict(fact, Witness, material_inference(Concept,
                                               Premise,
                                               Conclusion,
                                               Polarity)).

% =====================================================================
% N103 (Aichele & Wolfe 2008) — Chapter 7 Similarity, Chapter 11 Congruence
% =====================================================================

geom_concept(similar_figures,
    "Two figures are similar if they have the same shape (corresponding angles equal AND corresponding sides proportional)",
    similarity_congruence,
    [6,7,8]).

tier(ref(concept, similar_figures), 1,
     [n103_ch7, ccss_8g4, ccss_7g1],
     "N103 Activity 7.6 introduces with cats and dogs as a 'same shape, different size' visual.").

similarity_material_claim(similarity_definition,
    similar_figures,
    "two figures have all corresponding angles equal AND all corresponding sides proportional",
    "the figures are similar",
    entitled).

geom_concept(constant_of_proportionality,
    "The fixed ratio between corresponding lengths in similar figures; multiplying any side of the first by this ratio gives the corresponding side of the second",
    similarity_congruence,
    [6,7,8]).

tier(ref(concept, constant_of_proportionality), 1,
     [n103_ch7, ccss_7rp1, ccss_7rp2],
     "N103 Activity 7.6. Aliases (used interchangeably by N103): scale factor, length factor.").

geom_concept(scale_factor,
    "The number that multiplies each linear dimension of an original figure to produce a similar (scaled) figure",
    similarity_congruence,
    [6,7,8]).

tier(ref(concept, scale_factor), 1,
     [n103_ch7, ccss_7g1],
     "N103 Activity 7.10. Used interchangeably with 'length factor' and 'constant of proportionality'.").

geom_concept(length_factor,
    "Synonym for scale factor — the multiplier on linear dimensions when scaling",
    similarity_congruence,
    [6,7,8]).

tier(ref(concept, length_factor), 3,
     [n103_ch7],
     "N103-specific synonym; Activity 7.10 introduces 'sometimes called the length factor' as a way of preparing students for the area-factor and volume-factor extensions.").

geom_concept(area_factor,
    "The multiplier on area when a figure is scaled; equals the square of the scale factor",
    similarity_congruence,
    [7,8]).

tier(ref(concept, area_factor), 1,
     [n103_ch7, ccss_7g1, ccss_8g4],
     "N103 Activity 7.11. The relationship area_factor = (scale_factor)^2 is a Big Idea.").

similarity_material_claim(area_scales_quadratically_under_similarity,
    area_factor,
    "the linear dimensions of figure F are multiplied by k",
    "the area of F is multiplied by k^2",
    entitled).

geom_concept(volume_factor,
    "The multiplier on volume when a 3D figure is scaled; equals the cube of the scale factor",
    similarity_congruence,
    [7,8]).

tier(ref(concept, volume_factor), 1,
     [n103_ch7, ccss_8g9],
     "N103 Activity 7.14.").

similarity_material_claim(volume_scales_cubically_under_similarity,
    volume_factor,
    "the linear dimensions of solid S are multiplied by k",
    "the volume of S is multiplied by k^3",
    entitled).

geom_concept(aaa_similarity_for_triangles,
    "Two triangles are similar if and only if their corresponding angles are equal",
    similarity_congruence,
    [7,8]).

tier(ref(concept, aaa_similarity_for_triangles), 1,
     [n103_ch7, ccss_8g5],
     "N103 Activity 7.9. Triangle-only — N103 explicitly notes this fails for quadrilaterals (e.g., long rectangle vs. square have equal angles but are not similar).").

geom_concept(sss_similarity_for_triangles,
    "Two triangles are similar if and only if their corresponding sides are proportional",
    similarity_congruence,
    [7,8]).

tier(ref(concept, sss_similarity_for_triangles), 1,
     [n103_ch7],
     "N103 Activity 7.9. Triangle-only.").

geom_concept(triangle_congruence_conditions,
    "Conditions sufficient to establish that two triangles are congruent: SSS, SAS, ASA, SSA (ambiguous case)",
    similarity_congruence,
    [7,8]).

tier(ref(concept, triangle_congruence_conditions), 1,
     [n103_ch10, n103_ch11, ccss_8g],
     "N103 Chapter 10-11. The SSA case is explicitly flagged as ambiguous.").

geom_concept(cpct,
    "Corresponding Parts of Congruent Triangles — once two triangles are established as congruent, every pair of corresponding parts (sides, angles) is equal",
    similarity_congruence,
    [7,8]).

tier(ref(concept, cpct), 1,
     [n103_ch11],
     "N103 Activity 11.1: 'Congruence Conditions for Triangles and CPCT.' N103 names this directly.").

geom_concept(midline_of_triangle,
    "A segment joining the midpoints of two sides of a triangle; always parallel to the third side and half its length",
    similarity_congruence,
    [7,8]).

tier(ref(concept, midline_of_triangle), 1,
     [n103_ch7],
     "N103 Activity 7.9. Used as a similarity example — midline produces a smaller similar triangle.").

geom_concept(slope,
    "Slope of a line or segment = rise / run; the ratio of vertical change to horizontal change",
    similarity_congruence,
    [6,7,8]).

tier(ref(concept, slope), 1,
     [n103_ch7, ccss_8ee5, ccss_8ee6],
     "N103 Activity 7.1. Visual interpretation on geoboard precedes the algebra-class formula.").

geom_concept(parallel_lines_equal_slope,
    "Two non-vertical lines are parallel if and only if their slopes are equal",
    similarity_congruence,
    [7,8]).

tier(ref(concept, parallel_lines_equal_slope), 1,
     [n103_ch7, ccss_8ee6],
     "N103 Activity 7.2.").

geom_concept(perpendicular_lines_negative_reciprocal_slopes,
    "Two non-vertical lines are perpendicular if and only if the product of their slopes is -1",
    similarity_congruence,
    [7,8]).

tier(ref(concept, perpendicular_lines_negative_reciprocal_slopes), 1,
     [n103_ch7],
     "N103 Activity 7.2. Discovered by students from geoboard examples before the rule is stated.").

similarity_material_claim(equal_slope_entails_parallel_lines,
    parallel_lines_equal_slope,
    "two non-vertical lines have the same slope",
    "the lines are parallel",
    entitled).

similarity_material_claim(negative_reciprocal_slopes_entail_perpendicular_lines,
    perpendicular_lines_negative_reciprocal_slopes,
    "two non-vertical lines have slopes m1 and m2 with m1 * m2 = -1",
    "the lines are perpendicular",
    entitled).

geom_misconception(
    similarity_via_equal_angles_for_quadrilaterals,
    similar_figures,
    "Equal angles assumed to be sufficient for similarity in any polygon (overgeneralizing AAA from triangles)",
    [ "these two rectangles have all right angles so they are similar",
      "if the angles are equal the shapes are similar",
      "I just check the angles to see similarity" ],
    "Equal angles guarantee similarity ONLY for triangles. For quadrilaterals and other polygons, you must also check that corresponding sides are proportional. Counterexample: a long rectangle and a square both have four right angles but are not similar.",
    [n103_ch7]).

tier(ref(misconception, similarity_via_equal_angles_for_quadrilaterals), 1,
     [n103_ch7],
     "N103 Activity 7.9 designs around this exact overgeneralization.").

geom_misconception(
    scaling_assumed_linear_for_area,
    area_factor,
    "Doubling linear dimensions assumed to double area (rather than quadruple it)",
    [ "if I make the side twice as long the area is twice as big",
      "scaling by 3 makes the area 3 times bigger",
      "the area scales the same as the length" ],
    "Area scales as the SQUARE of the linear factor: doubling linear → 4x area, tripling linear → 9x area. N103 has students physically scale rectangles on dot paper to see this.",
    [n103_ch7]).

tier(ref(misconception, scaling_assumed_linear_for_area), 1,
     [n103_ch7],
     "N103 Activity 7.11-7.13 design around this misconception. Triangulates with research-corpus 'linear_scaling_assumed_for_area' in area_perimeter.pl.").

geom_misconception(
    scaling_assumed_quadratic_for_volume,
    volume_factor,
    "Doubling linear dimensions assumed to scale volume as the square (rather than the cube)",
    [ "doubling each side multiplies volume by 4",
      "the volume goes up by the square of the scaling",
      "I used scale^2 for the volume" ],
    "Volume scales as the CUBE of the linear factor: doubling linear → 8x volume, tripling linear → 27x volume. N103 Activity 7.14 has students stack unit cubes to see why.",
    [n103_ch7]).

tier(ref(misconception, scaling_assumed_quadratic_for_volume), 1,
     [n103_ch7],
     "N103 Activity 7.14 explicitly designs around this.").

% =====================================================================
% Research-corpus harvest (misconception_harvester) — appended below
% =====================================================================

:- multifile triangulation/2.
:- discontiguous triangulation/2.

% --- corpus_37756 (Mayberry 1983): angle measures scale with sides
geom_misconception(
    angles_scale_with_sides_in_similar,
    similar_figures,
    "Angle measures assumed to scale proportionally with side lengths in similar figures",
    [ "if A's sides are half of B's then A's angles are half of B's",
      "small triangles have small angles",
      "scaling sides scales angles" ],
    "Similar figures have *equal* corresponding angles, not proportional ones. Only the side lengths (and the perimeter, area, etc.) scale; angles are invariant under similarity. Demonstrate by tracing one triangle, scaling it, and comparing angle measurements with a protractor.",
    [corpus_37756, mayberry_1983]).

tier(ref(misconception, angles_scale_with_sides_in_similar), 3,
     [corpus_37756], "single-source corpus row 37756 (Mayberry 1983)").

% --- corpus_39230 (Manouchehri & Goodman 2000): visual-similarity-by-shape
geom_misconception(
    visual_similarity_without_proportionality_check,
    similar_figures,
    "Two visually similar shapes assumed similar without verifying proportional sides",
    [ "they look alike so they're similar",
      "same shape, different size",
      "you can tell by looking" ],
    "Similarity is a precise condition: corresponding angles equal AND corresponding sides proportional with the same ratio. Two rectangles can both 'look like rectangles' but not be similar (a 3x5 and a 2x10 are both rectangles but not similar). Compute side ratios and compare.",
    [corpus_39230]).

tier(ref(misconception, visual_similarity_without_proportionality_check), 3,
     [corpus_39230], "single-source corpus row 39230").

% --- corpus_39516 (Winsløw et al. 2013): additive instead of multiplicative
geom_misconception(
    similarity_via_additive_difference,
    similar_figures,
    "Similarity judged by adding a constant to each side rather than multiplying",
    [ "I added 2 to each side, so they're similar",
      "you make them bigger by adding the same amount",
      "the difference between sides is the same" ],
    "Similarity requires *multiplying* each side by the same factor (not adding the same constant). A 3x5 rectangle scaled to similar should have side ratio preserved: e.g. 6x10 (k=2) is similar; 5x7 (added 2) is not — its sides have ratio 5:7, not 3:5. Compute ratios, not differences.",
    [corpus_39516, corpus_38034]).

tier(ref(misconception, similarity_via_additive_difference), 2,
     [corpus_39516, corpus_38034],
     "research corpus — multi-source on additive/multiplicative confusion").

triangulation(ref(misconception, similarity_via_additive_difference),
    [ source(winslow_matheron_2013, agrees),
      source(corpus_38034, agrees) ]).

% --- corpus_40296 (Ekawati et al. 2015): visual estimation by area
geom_misconception(
    similarity_by_area_comparison,
    similar_figures,
    "Similarity judged by comparing total areas rather than corresponding side ratios",
    [ "if the areas are in the same ratio they're similar",
      "I compared the total sizes",
      "look at how much space they take up" ],
    "Two figures can have proportional areas without being similar (e.g., a 4x9 rectangle has area 36, a 6x6 square has area 36 but they aren't similar). Similarity requires *side-by-side* proportionality, not just area proportionality. Compute corresponding side ratios for each pair of corresponding sides.",
    [corpus_40296]).

tier(ref(misconception, similarity_by_area_comparison), 3,
     [corpus_40296], "single-source corpus row 40296").

% --- material inferences from harvest ---

similarity_material_claim(visual_similarity_not_mathematical_similarity,
    similar_figures,
    "two figures have visually similar shapes (look alike)",
    "the figures are similar in the mathematical sense",
    incompatible).

similarity_material_claim(additive_side_change_not_similarity,
    similar_figures,
    "you obtain figure F2 by adding a constant to each side of F1",
    "F1 and F2 are similar",
    incompatible).

similarity_material_claim(angle_measures_do_not_scale_with_side_factor,
    similar_figures,
    "two triangles A and B are similar with side scale factor k",
    "the corresponding angles of A are k times the corresponding angles of B",
    incompatible).
