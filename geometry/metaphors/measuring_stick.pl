% metaphors/measuring_stick.pl — the measuring-stick metaphor specifically.
% Schema: ../schema.pl
%
% Source: Lakoff, G. & Núñez, R. (2000). Where Mathematics Comes From,
% Chapter 3 (the Measuring Stick metaphor; the Number/Physical Segment
% blend; the genesis of irrational numbers).
%
% Charter: 2026-05-03 overnight Hermes geometry push, Wave 2 (L&N digger).
% The arithmetic side of the Measuring Stick metaphor is already documented
% in LK_RB_Synthesis_Project/Metaphor_Knowledge_Base.md §3 and in
% September_UMEDCA/HC_Tex_Files/lakoff_Brandom_CGI_Synthesis.{tex,pdf}.
% This file extends to GEOMETRIC measurement.
%
% Container vs. Measuring Stick distinction (Wave 1 audit flag): preserve.
%   - Container schema = interior/boundary topology (point inside polygon)
%   - Measuring Stick  = laying unit segments end-to-end along a length
% They co-occur in area/perimeter problems but are different schemas.
% This file holds Measuring-Stick-only content.

:- multifile metaphor_source/4, tier/4, triangulation/2.
:- discontiguous metaphor_source/4, tier/4, triangulation/2.

%!  measuring_stick_metaphor_witness(+ConceptId, +MetaphorName, -Witness) is semidet.
%
%   Inspectable witness for the finite loaded measuring-stick metaphor table.
%   This proves that an authored measuring-stick row resolves to a loaded
%   concept, tier evidence, source-target mappings, and any triangulation rows.
measuring_stick_metaphor_witness(ConceptId, MetaphorName, Witness) :-
    measuring_stick_metaphor_family(MetaphorName),
    metaphor_source(ConceptId, MetaphorName, Mapping, Citation),
    measuring_stick_concept_evidence(ConceptId,
                                     ConceptBoundary,
                                     ConceptEvidence),
    measuring_stick_mapping_witnesses(Mapping, MappingWitnesses),
    measuring_stick_tier_evidence(ref(metaphor, ConceptId, MetaphorName),
                                  TierBoundary,
                                  Tier,
                                  TierEvidence),
    measuring_stick_triangulation_evidence(ref(metaphor,
                                               ConceptId,
                                               MetaphorName),
                                           TriangulationEvidence),
    Witness = _{ kind: geometry_measuring_stick_metaphor,
                 scope: closed_world_finite_measuring_stick_metaphor_table,
                 concept: ConceptId,
                 metaphor: MetaphorName,
                 concept_boundary: ConceptBoundary,
                 concept_evidence: ConceptEvidence,
                 mapping_witnesses: MappingWitnesses,
                 citations: Citation,
                 tier_boundary: TierBoundary,
                 tier: Tier,
                 tier_evidence: TierEvidence,
                 triangulation_evidence: TriangulationEvidence,
                 boundary: finite_measuring_stick_metaphor_claim_not_general_cognitive_metaphor_theory,
                 fact: metaphor_source(ConceptId,
                                       MetaphorName,
                                       Mapping,
                                       Citation) }.

measuring_stick_metaphor_family(measuring_stick_metaphor).
measuring_stick_metaphor_family(measuring_stick_schema).
measuring_stick_metaphor_family(number_physical_segment_blend).

measuring_stick_concept_evidence(ConceptId,
                                 loaded_geometry_concept_record,
    _{ kind: resolved_measuring_stick_concept,
       concept: ConceptId,
       name: Name,
       topic: Topic,
       grade_bands: GradeBands,
       fact: geom_concept(ConceptId, Name, Topic, GradeBands) }) :-
    geom_concept(ConceptId, Name, Topic, GradeBands).

measuring_stick_mapping_witnesses(Mapping, MappingWitnesses) :-
    maplist(measuring_stick_mapping_witness, Mapping, MappingWitnesses).

measuring_stick_mapping_witness(source_target(Source, Target),
    _{ kind: source_target_mapping,
       source: Source,
       target: Target,
       fact: source_target(Source, Target) }).

measuring_stick_tier_evidence(Ref, loaded_tier_record, Tier, TierEvidence) :-
    findall(_{ tier: T,
               sources: Sources,
               source_note: SourceNote,
               fact: tier(Ref, T, Sources, SourceNote) },
            tier(Ref, T, Sources, SourceNote),
            RawTierEvidence),
    sort(RawTierEvidence, TierEvidence),
    TierEvidence \== [],
    findall(T,
            ( member(Evidence, TierEvidence),
              get_dict(tier, Evidence, T)
            ),
            Tiers),
    min_list(Tiers, Tier),
    !.
measuring_stick_tier_evidence(_Ref, no_loaded_tier_record, 3, []).

measuring_stick_triangulation_evidence(Ref, TriangulationEvidence) :-
    findall(_{ agreement: Agreement,
               fact: triangulation(Ref, Agreement) },
            triangulation(Ref, Agreement),
            RawTriangulationEvidence),
    sort(RawTriangulationEvidence, TriangulationEvidence).

% ─── Tier 1: the L&N Measuring Stick metaphor as L&N state it ────────
%
% Quoted source/target mapping from Ch. 3.

metaphor_source(numbers_as_physical_segments, measuring_stick_metaphor,
    [source_target(physical_segments_of_unit_lengths, numbers),
     source_target(basic_physical_segment, one),
     source_target(length_of_segment, size_of_number),
     source_target(longer, greater),
     source_target(shorter, less),
     source_target(acts_of_segment_placement, arithmetic_operations),
     source_target(end_to_end_placement, addition),
     source_target(removal_of_shorter_segment, subtraction),
     source_target(lack_of_any_physical_segment, zero),
     source_target(fitting_together_iterated, multiplication),
     source_target(dividing_up_iterated, division)],
    [ln_ch3_p68, ln_ch3_p69]).

tier(ref(metaphor, numbers_as_physical_segments, measuring_stick_metaphor), 1,
    [source(ln, agrees)],
    "L&N Ch. 3: 'THE MEASURING STICK METAPHOR. Source Domain: THE USE OF A MEASURING STICK. Target Domain: ARITHMETIC.' Full mapping printed in the book. Pages estimated from Ch. 3 ordering; corpus file flags page-anchor uncertainty.").

metaphor_source(number_physical_segment_blend_for_irrationals, number_physical_segment_blend,
    [source_target(unidimensional_continuous_segment, line_segment_of_euclidean_geometry),
     source_target(blend_assumption, every_segment_corresponds_to_a_number),
     source_target(pythagorean_hypotenuse_with_unit_legs, segment_of_length_root_2),
     source_target(blend_entailment, sqrt_2_must_exist_as_a_number),
     source_target(genesis_of_irrationals, real_numbers_beyond_the_rationals)],
    [ln_ch3_p70, ln_ch3_p71]).

tier(ref(metaphor, number_physical_segment_blend_for_irrationals, number_physical_segment_blend), 1,
    [source(ln, agrees)],
    "L&N Ch. 3: 'Given a fixed unit length, it follows that for every physical segment there is a number ... if, according to the Number/Physical Segment blend, there must exist a number corresponding to the length of every physical segment, then and only then must √2 exist as a number! It was the measuring stick metaphor and the Number/Physical Segment blend that gave birth to the irrational numbers.'").

% ─── Tier 3: geometric specializations not directly asserted by L&N ──
%
% L&N say nothing explicit about ruler postulate, congruence-by-
% superposition, similarity-as-scaling, area-as-2D-stick, or volume-as-
% 3D-stick. (Verified by direct query; transcript: see
% corpus/lakoff_nunez_passages.md §7.) Those are pedagogically central
% in K-8 geometry, so we record them as Tier 3 extensions inferred from
% the L&N Ch. 3 mapping. Synthesizer should reconcile against Van de
% Walle / N103 source diggers, who likely have direct treatment.

metaphor_source(length_measurement_as_unit_iteration, measuring_stick_metaphor,
    [source_target(unit_length_segment, ruler_unit),
     source_target(end_to_end_placement, ruler_postulate_iteration),
     source_target(count_of_unit_placements, length_in_units),
     source_target(remainder_segment, sub_unit_residual),
     source_target(continuous_segment_being_measured, length_to_be_assigned)],
    [ln_ch3_p68, ln_ch3_p69]).

tier(ref(metaphor, length_measurement_as_unit_iteration, measuring_stick_metaphor), 3,
    [source(ln, partial)],
    "Tier 3 extension. L&N state the metaphor for arithmetic (segment-as-number) but do not name 'the ruler postulate' or 'unit iteration along a length to be measured.' This Prolog clause inverts L&N's directionality: instead of physical-segment → number, we read unit-segment-laid-N-times → number-N-as-length-measure. Geometrically standard; cite L&N for the underlying schema and the synthesizer + Van de Walle digger for the K-8 ruler-postulate framing.").

metaphor_source(congruence_by_superposition, measuring_stick_schema,
    [source_target(physical_segment_a, figure_a),
     source_target(physical_segment_b, figure_b),
     source_target(end_to_end_match_after_translation, congruence_relation),
     source_target(rigid_motion_preserves_length, superposition_preserves_congruence)],
    [ln_ch3_p70, ln_ch5_p110]).

tier(ref(metaphor, congruence_by_superposition, measuring_stick_schema), 3,
    [source(ln, silent)],
    "Tier 3 extension. L&N do not discuss congruence directly (verified — see corpus passages §7). Inferred extension: the measuring-stick schema (laying one segment alongside another to compare lengths) is the cognitive ground for Euclid's superposition method, where two figures are 'the same' when one can be physically slid onto the other. L&N Ch. 5 cite Euclid's axiomatic method but not superposition cognitively. Synthesizer: confirm against Van de Walle / N103.").

metaphor_source(similarity_as_uniform_scaling, measuring_stick_schema,
    [source_target(unit_segment_in_one_figure, scaled_unit_in_similar_figure),
     source_target(uniform_lengthening_of_all_segments, scale_factor_k),
     source_target(preservation_of_ratios, shape_preserved_under_scaling),
     source_target(angles_unchanged_by_uniform_scaling, similar_figure_has_same_angles)],
    [ln_ch3_p68]).

tier(ref(metaphor, similarity_as_uniform_scaling, measuring_stick_schema), 3,
    [source(ln, silent)],
    "Tier 3 extension. L&N are silent on geometric similarity (verified). Inferred: similarity is the measuring-stick metaphor with a uniformly rescaled unit — every segment in figure B is k times the corresponding segment in figure A, where k is the scale factor. Notes: this also underwrites the Trigonometry Metaphor's invariance-of-ratios in CS1 — sin/cos depend only on the angle because similar right triangles preserve the leg/hypotenuse ratio.").

metaphor_source(area_as_2d_unit_iteration, measuring_stick_schema,
    [source_target(unit_square, basic_2d_measuring_unit),
     source_target(tiling_a_region_with_unit_squares, area_measurement),
     source_target(count_of_unit_squares_filling_interior, area_in_square_units),
     source_target(partial_unit_squares_along_boundary, area_remainder)],
    [ln_ch11_p243, ln_ch14_p307]).

tier(ref(metaphor, area_as_2d_unit_iteration, measuring_stick_schema), 3,
    [source(ln, partial)],
    "Tier 3 extension. L&N mention area only in passing — Ch. 14 (Pierpont): 'When closed, [a curve] forms the complete boundary of a region. This region has an area.' Ch. 11 integral-as-sum-of-rectangles uses unit-rectangle area implicitly. They do NOT formalize area-as-unit-square-iteration as its own metaphor. Inferred extension: 1D measuring stick generalizes to 2D by tiling. NOTES — this is the Container × Measuring Stick co-occurrence the Wave 1 audit flagged. Container provides the interior/boundary topology of the region; Measuring Stick provides the unit-iteration counting. Two distinct schemas, both required for 'area = N square units inside the polygon.'").

metaphor_source(volume_as_3d_unit_iteration, measuring_stick_schema,
    [source_target(unit_cube, basic_3d_measuring_unit),
     source_target(filling_a_solid_with_unit_cubes, volume_measurement),
     source_target(count_of_unit_cubes_filling_interior, volume_in_cubic_units),
     source_target(partial_unit_cubes_along_surface, volume_remainder)],
    [ln_ch12_p270]).

tier(ref(metaphor, volume_as_3d_unit_iteration, measuring_stick_schema), 3,
    [source(ln, silent)],
    "Tier 3 extension. L&N's only direct mention of volume is the Piaget/Inhelder shrinking-ball experiment (Ch. 12 p. 270) — children attribute volume to points. They do NOT formalize volume-as-unit-cube-iteration. Inferred extension by analogy: 1D stick → 2D square → 3D cube. As with area, this requires Container schema (the solid's boundary surface) plus Measuring Stick (cube unit iteration). Synthesizer: this is exactly where Van de Walle is likely to provide direct treatment.").

triangulation(ref(metaphor, area_as_2d_unit_iteration, measuring_stick_schema),
    [source(ln, partial), source(misconceptions_measurement_pl, agrees), source(synthesizer, pending)]).

triangulation(ref(metaphor, volume_as_3d_unit_iteration, measuring_stick_schema),
    [source(ln, silent), source(synthesizer, pending)]).

% =====================================================================
% N103 (Aichele & Wolfe 2008) — applications of the measuring-stick metaphor
% =====================================================================
%
% This block captures where N103 *applies* the measuring-stick schema in
% K-8 pedagogy, complementing the L&N digger's account of where L&N
% *introduce* the schema.

metaphor_source(circle_circumference_formula, measuring_stick_schema,
    [source_target(repeated_unit_along_curve, linear_measurement),
     source_target(string_along_boundary_then_straightened, circumference_value),
     source_target(rolling_object_one_full_turn, circumference_via_traversal)],
    n103_ch9).

tier(ref(metaphor, circle_circumference_formula, measuring_stick_schema), 1,
    [n103_ch9],
    "N103 Activity 9.1 explicitly: 'Run a string around the object and then measure the string,' or 'roll the object along a tabletop for one turn.' The string is the flexible measuring stick applied to a curved boundary. N103 derives pi as the measured ratio circumference/diameter from this iteration.").

metaphor_source(area_unit_is_a_square, measuring_stick_schema,
    [source_target(unit_square_on_geoboard, basic_2d_measuring_unit),
     source_target(counting_pegs_or_squares_inside_region, area_measurement),
     source_target(geoboard_dot_paper_grid, scaffolded_iteration_substrate)],
    n103_ch5).

tier(ref(metaphor, area_unit_is_a_square, measuring_stick_schema), 1,
    [n103_ch5],
    "N103 Chapter 5 introduction: 'a square with unit length on all sides has 1 square unit of area.' The geoboard is N103's central measuring-stick substrate for area in 2D — 'horizontal or vertical distance between two adjoining pegs is one unit of length.'").

metaphor_source(volume_of_prism_formula, measuring_stick_schema,
    [source_target(unit_cube_block, basic_3d_measuring_unit),
     source_target(stacking_blocks_layer_by_layer_on_geoboard_base, volume_via_repeated_layers),
     source_target(layer_count_times_layer_count, base_x_height_factor_structure)],
    n103_ch4).

tier(ref(metaphor, volume_of_prism_formula, measuring_stick_schema), 1,
    [n103_ch4],
    "N103 Activity 4.5 ('Making Sense of Volume') has students literally stack unit blocks on top of geoboard shapes and count. The 'layer 1 has B blocks, layer 2 has B blocks, ..., total = B*h' derivation is the measuring-stick schema in 3D plus a multiplicative composition.").

metaphor_source(volume_of_pyramid_formula, measuring_stick_schema,
    [source_target(one_cubic_inch_scoop_of_filler, unit_of_volume),
     source_target(scoop_count_to_fill_hollow_pyramid_or_prism, volume_value),
     source_target(comparison_of_scoop_counts_for_same_base_and_height, the_one_third_factor)],
    n103_ch4).

tier(ref(metaphor, volume_of_pyramid_formula, measuring_stick_schema), 1,
    [n103_ch4],
    "N103 Activity 4.13 ('What Does Volume Really Mean?') has students physically fill a hollow pyramid with packet material using a 1-cubic-inch scoop, counting scoops. Compares to the prism with same base and height. The 1/3 emerges from the ratio of scoop counts. This is the measuring-stick metaphor as fluid-displacement variant.").

metaphor_source(picks_formula, measuring_stick_schema,
    [source_target(interior_lattice_peg, full_unit_of_area_information),
     source_target(boundary_lattice_peg, half_unit_of_area_information),
     source_target(closing_offset_minus_one, vertex_correction)],
    n103_ch6).

tier(ref(metaphor, picks_formula, measuring_stick_schema), 3,
    [n103_ch6],
    "N103 Chapter 6 doesn't explicitly call Pick's formula a measuring-stick application, but the structure is recognizably the schema: each peg counts toward area as a discrete unit (with edge pegs contributing half). Tier 3 because the connection is interpretive on the digger's part. Alias possibility: 'pegs as fractional area units.'").

metaphor_source(surface_area_of_sphere, measuring_stick_schema,
    [source_target(equal_radius_circle, unit_of_spherical_surface_area),
     source_target(orange_peel_pieces_covering_circles, iterative_2d_coverage),
     source_target(four_circles_covered, surface_area_in_circle_units)],
    n103_ch9).

tier(ref(metaphor, surface_area_of_sphere, measuring_stick_schema), 1,
    [n103_ch9],
    "N103 Activity 9.13: peel an orange, cover four r-radius circles with the peel pieces. Discovery that 4*pi*r^2 = surface area of sphere of radius r emerges from the measuring-stick schema applied with a non-square 2D unit (the disk).").

metaphor_source(slant_length_on_geoboard, measuring_stick_schema,
    [source_target(string_around_geoboard_figure, perimeter_estimate),
     source_target(string_compared_to_geoboard_edge_units, decimal_perimeter_value),
     source_target(square_on_segment_via_pythagoras, slant_length_calculation)],
    n103_ch8).

tier(ref(metaphor, slant_length_on_geoboard, measuring_stick_schema), 1,
    [n103_ch8],
    "N103 Activity 8.3 ('Estimating Perimeters on a Geoboard'): 'Loop the end on an edge peg and wind the string around the figure. Pinch the string to mark how much string is needed to encircle the figure completely. Now put the loop around a corner peg on the geoboard, and wrap the string around the outside pegs.' The string IS the flexible measuring stick.").

triangulation(ref(metaphor, area_unit_is_a_square, measuring_stick_schema),
    [source(ln, partial), source(n103, agrees), source(misconceptions_measurement_pl, agrees)]).

triangulation(ref(metaphor, volume_of_prism_formula, measuring_stick_schema),
    [source(ln, silent), source(n103, agrees)]).
