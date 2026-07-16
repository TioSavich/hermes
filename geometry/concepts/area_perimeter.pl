% concepts/area_perimeter.pl — geometry concepts in the area_perimeter topic.
%
% Append clauses for: geom_concept/4, geom_misconception/6,
%                     material_inference/4, tier/4 (covering all of these).
% Cross-tagging (van_hiele_marker, metaphor_source, bootstrap,
% standard_anchor) lives in the corresponding subdirs.
%
% Schema: ../schema.pl

:- multifile geom_concept/4, geom_misconception/6, material_inference/4, tier/4.
:- discontiguous geom_concept/4, geom_misconception/6, material_inference/4, tier/4,
               area_perimeter_material_claim/5.
:- multifile triangulation/2.
:- discontiguous triangulation/2.

%!  area_perimeter_material_claim_witness(+Id, -Witness) is semidet.
%
%   Inspectable proof object for a finite area/perimeter material row.
area_perimeter_material_claim_witness(Id, Witness) :-
    area_perimeter_material_claim(Id, Concept, Premise, Conclusion, Polarity),
    area_perimeter_concept_tier_evidence(Concept,
                                         ConceptTierBoundary,
                                         ConceptTierEvidence),
    area_perimeter_related_misconception_witnesses(Concept,
                                                   MisconceptionWitnesses),
    area_perimeter_condition_roles(Id, Roles),
    Witness = _{ kind: geometry_area_perimeter_material_inference,
                 scope: closed_world_finite_area_perimeter_table,
                 id: Id,
                 concept: Concept,
                 premise: Premise,
                 conclusion: Conclusion,
                 polarity: Polarity,
                 concept_tier_boundary: ConceptTierBoundary,
                 concept_tier_evidence: ConceptTierEvidence,
                 boundary: finite_area_perimeter_curriculum_claim_not_general_measure_theory,
                 condition_roles: Roles,
                 related_misconception_witnesses: MisconceptionWitnesses,
                 fact: material_inference(Concept, Premise, Conclusion, Polarity) }.

area_perimeter_concept_tier_evidence(Concept,
                                     loaded_concept_tier_record,
                                     TierEvidence) :-
    findall(_{ tier: Tier,
               sources: Sources,
               source_note: SourceNote },
            tier(ref(concept, Concept), Tier, Sources, SourceNote),
            TierEvidence),
    TierEvidence \== [],
    !.
area_perimeter_concept_tier_evidence(_Concept,
                                     no_concept_tier_record_in_loaded_geometry_schema,
                                     []).

area_perimeter_related_misconception_witnesses(Concept, Witnesses) :-
    findall(Witness,
            area_perimeter_misconception_witness(Concept, Witness),
            RawWitnesses),
    sort(RawWitnesses, Witnesses).

area_perimeter_misconception_witness(Concept,
    _{ kind: geometry_area_perimeter_misconception_support,
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
    area_perimeter_triangulation_evidence(Id, TriangulationEvidence),
    tier(ref(misconception, Id), Tier, Sources, SourceNote).

area_perimeter_triangulation_evidence(Id, Evidence) :-
    findall(_{ record: ref(misconception, Id),
               agreement: Agreement },
            triangulation(ref(misconception, Id), Agreement),
            RawEvidence),
    sort(RawEvidence, Evidence).

area_perimeter_condition_roles(area_complete_unit_cover,
                               [ _{ kind: sufficiency_component,
                                    role: complete_interior_unit_square_cover },
                                 _{ kind: necessary_condition,
                                    role: no_gaps_no_overlaps },
                                 _{ kind: unit_component,
                                    role: square_units }
                               ]) :-
    !.
area_perimeter_condition_roles(rectangle_perimeter_full_boundary,
                               [ _{ kind: sufficiency_component,
                                    role: length_and_width_known },
                                 _{ kind: necessary_condition,
                                    role: all_four_boundary_sides_traversed }
                               ]) :-
    !.
area_perimeter_condition_roles(rectangle_area_array,
                               [ _{ kind: sufficiency_component,
                                    role: rectangular_row_column_array },
                                 _{ kind: unit_component,
                                    role: length_times_width_counts_unit_squares }
                               ]) :-
    !.
area_perimeter_condition_roles(quadratic_area_scaling,
                               [ _{ kind: invariance_component,
                                    role: two_independent_linear_dimensions_scaled },
                                 _{ kind: sufficiency_component,
                                    role: area_factor_is_k_squared }
                               ]) :-
    !.
area_perimeter_condition_roles(area_perimeter_order_rejection,
                               [ _{ kind: incompatibility_component,
                                    role: area_order_does_not_determine_perimeter_order },
                                 _{ kind: distinction_component,
                                    role: two_dimensional_measure_not_one_dimensional_boundary_length }
                               ]) :-
    !.
area_perimeter_condition_roles(boundary_count_not_area,
                               [ _{ kind: incompatibility_component,
                                    role: boundary_units_do_not_cover_interior },
                                 _{ kind: necessary_condition_missing,
                                    role: complete_interior_coverage }
                               ]) :-
    !.
area_perimeter_condition_roles(rectangle_perimeter_requires_all_sides,
                               [ _{ kind: incompatibility_component,
                                    role: length_plus_width_counts_only_two_sides },
                                 _{ kind: necessary_condition_missing,
                                    role: full_boundary_traversal }
                               ]) :-
    !.
area_perimeter_condition_roles(area_requires_square_units,
                               [ _{ kind: incompatibility_component,
                                    role: area_measure_requires_square_units },
                                 _{ kind: distinction_component,
                                    role: linear_units_name_length_not_area }
                               ]) :-
    !.
area_perimeter_condition_roles(area_scaling_rejects_linear,
                               [ _{ kind: incompatibility_component,
                                    role: area_scales_quadratically_not_linearly }
                               ]) :-
    !.
area_perimeter_condition_roles(equal_area_possible_without_congruence,
                               [ _{ kind: incompatibility_component,
                                    role: congruence_is_not_necessary_for_equal_area },
                                 _{ kind: conservation_component,
                                    role: cut_and_rearrange_preserves_area }
                               ]) :-
    !.
area_perimeter_condition_roles(unit_fraction_requires_equal_area_parts,
                               [ _{ kind: sufficiency_component,
                                    role: equal_area_partition_of_same_whole },
                                 _{ kind: classification_component,
                                    role: selected_part_is_one_over_n }
                               ]) :-
    !.
area_perimeter_condition_roles(unequal_parts_not_unit_fractions,
                               [ _{ kind: incompatibility_component,
                                    role: piece_count_without_equal_areas_is_insufficient },
                                 _{ kind: necessary_condition_missing,
                                    role: equal_area_parts }
                               ]) :-
    !.
area_perimeter_condition_roles(method_result_not_scope_proof,
                               [ _{ kind: incompatibility_component,
                                    role: correct_output_does_not_prove_method_scope },
                                 _{ kind: necessary_condition_missing,
                                    role: problem_type_conditions_for_method }
                               ]) :-
    !.
area_perimeter_condition_roles(picks_formula_simple_lattice_polygon,
                               [ _{ kind: sufficiency_component,
                                    role: simple_closed_lattice_polygon },
                                 _{ kind: sufficiency_component,
                                    role: interior_and_boundary_lattice_point_counts }
                               ]) :-
    !.
area_perimeter_condition_roles(picks_formula_rejects_crossed_or_multi_band,
                               [ _{ kind: incompatibility_component,
                                    role: crossed_or_multiple_boundary_curves_violate_simple_polygon_condition }
                               ]) :-
    !.
area_perimeter_condition_roles(_, []).

material_inference(Concept, Premise, Conclusion, Polarity) :-
    area_perimeter_material_claim_witness(_Id, Witness),
    get_dict(fact, Witness, material_inference(Concept,
                                               Premise,
                                               Conclusion,
                                               Polarity)).

% =====================================================================
% Concepts
% =====================================================================

geom_concept(area_as_interior_coverage,
    "Area is the count of unit squares needed to cover the interior of a 2D region",
    area_perimeter,
    [2,3,4,5,6]).

geom_concept(perimeter_as_boundary_traversal,
    "Perimeter is the total length traveled along the boundary of a 2D region",
    area_perimeter,
    [2,3,4,5,6]).

geom_concept(area_perimeter_independence,
    "Area and perimeter are independently varying attributes of a shape",
    area_perimeter,
    [4,5,6,7]).

geom_concept(area_unit_is_a_square,
    "The standard unit of area is a unit square; areas are measured in square units",
    area_perimeter,
    [3,4,5,6]).

geom_concept(area_as_array_structure,
    "Area of a rectangle equals length × width because the unit squares form a row × column array",
    area_perimeter,
    [3,4,5,6]).

geom_concept(area_conservation_under_transformation,
    "Cutting and rearranging a region preserves its area",
    area_perimeter,
    [4,5,6,7]).

geom_concept(area_scales_quadratically,
    "When linear dimensions scale by k, area scales by k squared",
    area_perimeter,
    [6,7,8]).

% =====================================================================
% Tier 1 — ported BENNY records (misconceptions_measurement.pl archetypes)
% =====================================================================
% The measurement file holds five archetypal area/perimeter misconceptions
% with explicit container-schema annotations. Port each as Tier 1.

% --- benny_area_counted_as_perimeter
geom_misconception(
    area_counted_as_perimeter,
    area_as_interior_coverage,
    "Area computed by counting boundary units instead of interior coverage",
    [ "I counted around the edge to get the area",
      "the area is how many squares fit on the outside",
      "you go around the shape to find area" ],
    "Area asks how many unit squares cover the inside, not how many lie on the boundary. Demonstrate with a 4x3 grid: counting interior squares gives 12 (the area); counting the boundary squares gives 14 — that's the perimeter, a different question. Use the In(unit, interior) vs On(unit, boundary) container-schema distinction.",
    [benny_area_counted_as_perimeter, corpus_37528, corpus_37627, corpus_38635, corpus_40654]).

tier(ref(misconception, area_counted_as_perimeter), 1,
     [benny_area_counted_as_perimeter, corpus_37528, corpus_37627, corpus_40654],
     "ported from misconceptions_measurement.pl; multiple corpus rows attest").

triangulation(ref(misconception, area_counted_as_perimeter),
    [ source(corpus_37528, agrees),
      source(corpus_37627, agrees),
      source(corpus_38635, agrees),
      source(corpus_40654, agrees) ]).

% --- benny_perimeter_incomplete_traversal
geom_misconception(
    perimeter_incomplete_traversal,
    perimeter_as_boundary_traversal,
    "Perimeter computed as L + W only (just two sides)",
    [ "the perimeter is length plus width",
      "I added the two sides to get the perimeter",
      "perimeter is just one length and one width" ],
    "Perimeter is the full distance around — every side must be traversed. For a rectangle that's L + W + L + W = 2(L+W), not L + W. Trace the boundary with your finger and count: four edges, not two.",
    [benny_perimeter_incomplete_traversal, corpus_40254]).

tier(ref(misconception, perimeter_incomplete_traversal), 1,
     [benny_perimeter_incomplete_traversal, corpus_40254],
     "ported from misconceptions_measurement.pl; corpus row 40254 (Steele 2001) corroborates").

% --- benny_area_formula_inverted
geom_misconception(
    area_formula_inverted,
    area_as_array_structure,
    "Area formula 2(L+W) used in place of L*W",
    [ "the area is two times length plus width",
      "I used 2(L+W) for the area",
      "you add the sides and double" ],
    "2(L+W) is the perimeter formula. Area is L * W because the unit squares fill an array of L columns and W rows, giving L*W squares total. The two formulas have different shapes (sum-then-double vs product) because they answer different questions.",
    [benny_area_formula_inverted, corpus_37565, corpus_37621, corpus_39621, corpus_40362]).

tier(ref(misconception, area_formula_inverted), 1,
     [benny_area_formula_inverted, corpus_37565, corpus_39621, corpus_40362],
     "ported from misconceptions_measurement.pl; multi-source").

triangulation(ref(misconception, area_formula_inverted),
    [ source(pesek_kirshner_2000, agrees),
      source(sullivan_clarke_1992, agrees),
      source(huang_2017, agrees) ]).

% --- benny_perimeter_formula_inverted
geom_misconception(
    perimeter_formula_inverted,
    perimeter_as_boundary_traversal,
    "Perimeter computed using L*W (the area formula)",
    [ "I multiplied length and width to get the perimeter",
      "the perimeter is L times W",
      "the perimeter of a 5x4 rectangle is 20" ],
    "L*W gives the area (square units inside). Perimeter sums the edge lengths: 2(L+W). Show the units: a 5x4 rectangle has area 20 *square* units and perimeter 18 *linear* units. The unit type itself disambiguates which question is being asked.",
    [benny_perimeter_formula_inverted, corpus_39621, corpus_40362]).

tier(ref(misconception, perimeter_formula_inverted), 1,
     [benny_perimeter_formula_inverted, corpus_39621, corpus_40362],
     "ported from misconceptions_measurement.pl").

% =====================================================================
% Tier 2/3 — research-corpus harvested misconceptions
% =====================================================================

% --- corpus_38130 / 38159 / 39142 / 38081 / 37897: more-area-implies-more-perimeter intuition
geom_misconception(
    more_area_more_perimeter_intuition,
    area_perimeter_independence,
    "Larger area assumed to imply larger perimeter ('more A, more B' rule)",
    [ "this shape has bigger area so it has bigger perimeter",
      "if the area went up the perimeter went up too",
      "longer sides means bigger area" ],
    "Area and perimeter vary independently. Counter-example: a 4x4 square has area 16 and perimeter 16; a 1x16 rectangle has area 16 (same) and perimeter 34 (much greater). Show explicit pairs where area is fixed and perimeter changes (or vice versa) to break the linkage.",
    [corpus_38130, corpus_38159, corpus_39142, corpus_38081, corpus_37897, corpus_40157]).

tier(ref(misconception, more_area_more_perimeter_intuition), 2,
     [corpus_38130, corpus_38159, corpus_39142, corpus_38081, corpus_37897, corpus_40157],
     "research corpus — six independent papers on this 'more A, more B' intuition").

triangulation(ref(misconception, more_area_more_perimeter_intuition),
    [ source(babai_nattiv_stavy_2016, agrees),
      source(verschaffel_lehtinen_2016, agrees),
      source(kospentaris_2011, agrees),
      source(attridge_inglis_2015, agrees),
      source(howe_1999, agrees),
      source(even_1999, agrees) ]).

% --- corpus_38063: same-A-same-B perimeter (compensating dimensions)
geom_misconception(
    compensating_dimensions_preserve_perimeter,
    perimeter_as_boundary_traversal,
    "Reciprocal +k%/-k% on opposite sides assumed to preserve perimeter",
    [ "if I shrink one side and stretch the other the perimeter stays the same",
      "the changes cancel out so perimeter is unchanged",
      "20% off one direction and 20% on the other balances" ],
    "Percent changes don't simply cancel because they're computed on different bases. Concrete check: a 10x10 square (perimeter 40) becomes 8x12 after -20%/+20% — perimeter is 2(8+12) = 40 (here it does cancel because the bases are equal). But for a 10x20 rectangle (perimeter 60), -20% on the 20 and +20% on the 10 gives 12x16, perimeter 56. Whether the changes cancel depends on the starting dimensions; don't assume they do.",
    [corpus_38063]).

tier(ref(misconception, compensating_dimensions_preserve_perimeter), 3,
     [corpus_38063], "single-source corpus row 38063 (Van Dooren & Inglis)").

% --- corpus_38050 / 39012 / 39585: linear scaling assumed to scale area linearly
geom_misconception(
    linear_scaling_assumed_for_area,
    area_scales_quadratically,
    "Doubling linear dimension assumed to double area",
    [ "doubling the radius doubles the area",
      "if I make the side twice as long the area is twice as big",
      "scaling by 3 makes the area 3 times bigger" ],
    "Area scales as the square of the linear factor. A circle with radius doubled has area 4× the original (because A = π r² and (2r)² = 4r²). For a square with side doubled, the area also goes up 4×. Build a small table: linear factor 1, 2, 3, 4 → area factor 1, 4, 9, 16.",
    [corpus_38050, corpus_39585, corpus_38583, corpus_39012, corpus_39796]).

tier(ref(misconception, linear_scaling_assumed_for_area), 2,
     [corpus_38050, corpus_39585, corpus_38583, corpus_39012, corpus_39796],
     "research corpus — multi-source on linear-vs-quadratic scaling").

triangulation(ref(misconception, linear_scaling_assumed_for_area),
    [ source(kittel_beckmann_2005, agrees),
      source(wickstrom_fulton_2017, agrees),
      source(dolores_perrin_glorian_or_other, silent) ]).

% --- corpus_38993: 100 sq cm = 1 sq m (unit conversion)
geom_misconception(
    area_unit_conversion_linear,
    area_scales_quadratically,
    "Area conversion uses linear factor (1 sq m = 100 sq cm error)",
    [ "100 cm in a meter so 100 sq cm in a sq m",
      "if it's 1000 in linear it's 1000 in area",
      "I convert area the same way as length" ],
    "Area conversion squares the linear factor. 1 m = 100 cm, so 1 m² = (100 cm)² = 10,000 cm². The unit itself is two-dimensional, so the conversion factor is two-dimensional too. Draw a 100x100 grid inside a 1m square if helpful.",
    [corpus_38993]).

tier(ref(misconception, area_unit_conversion_linear), 3,
     [corpus_38993], "single-source corpus row 38993 (Baturo & Nason)").

% --- corpus_38992: area written in linear units
geom_misconception(
    area_in_linear_units,
    area_unit_is_a_square,
    "Calculated area written with linear units (cm) instead of square units (cm²)",
    [ "the area is 128 cm",
      "the area of the rectangle is 20 m",
      "I forgot the square on the unit" ],
    "Area is measured in *square* units because each unit is a 1x1 square. When you compute area, the unit must reflect that: 128 cm² is 128 unit squares of side 1 cm. Writing 128 cm describes a length, not an area. Always check unit dimensionality.",
    [corpus_38992]).

tier(ref(misconception, area_in_linear_units), 3,
     [corpus_38992], "single-source corpus row 38992").

% --- corpus_38995: area only exists when measured (or only for polygons)
geom_misconception(
    area_only_for_measurable_polygons,
    area_as_interior_coverage,
    "Area believed to only exist for measurable polygonal shapes",
    [ "this shape doesn't have an area, it's not a polygon",
      "you can't measure that, it has no area",
      "area is a property of squares and rectangles" ],
    "Every closed bounded 2D region has an area, including irregular and curved shapes. The fact that exact measurement may require approximation (counting partial squares, calculus, etc.) doesn't mean the area doesn't exist. Show area as a property first, measurement as a separate question.",
    [corpus_38995]).

tier(ref(misconception, area_only_for_measurable_polygons), 3,
     [corpus_38995], "single-source corpus row 38995").

% --- corpus_39141: area equivalence requires congruence
geom_misconception(
    area_equality_requires_congruence,
    area_conservation_under_transformation,
    "Two non-congruent shapes assumed to have unequal area",
    [ "they have different shapes so they can't have the same area",
      "if they're not congruent the areas can't match",
      "unequal-looking shapes have unequal areas" ],
    "Cutting and rearranging a shape preserves area but changes its appearance. A 4x6 rectangle and a 3x8 rectangle both have area 24. A square and a different-shaped polygon can have the same area too. Demonstrate with cut-and-rearrange tasks (parallelogram → rectangle).",
    [corpus_39141, corpus_39106, corpus_39004, corpus_39143]).

tier(ref(misconception, area_equality_requires_congruence), 2,
     [corpus_39141, corpus_39106, corpus_39004, corpus_39143],
     "research corpus — multi-source on area-conservation/congruence conflation").

triangulation(ref(misconception, area_equality_requires_congruence),
    [ source(kospentaris_2011, agrees),
      source(fischbein_1999, agrees),
      source(douady_perrin_glorian_1989, agrees) ]).

% --- corpus_37845 / 38453 / 37955: unequal parts counted as equal shares
geom_misconception(
    unequal_parts_counted_as_equal_fractions,
    partition_shapes_unit_fraction_area,
    "Unequal area parts counted as if they were equal fractional shares",
    [ "there are four parts so each part is a fourth",
      "two shaded pieces out of five means two fifths even if the pieces are different sizes",
      "I counted shaded pieces and total pieces without checking equal areas" ],
    "A fractional area name depends on equal-area parts of the same whole, not just the number of drawn pieces. First identify the whole, then check that every named part has the same area before counting parts.",
    [corpus_37845, corpus_38453, corpus_37955]).

tier(ref(misconception, unequal_parts_counted_as_equal_fractions), 3,
     [corpus_37845, corpus_38453, corpus_37955],
     "research corpus rows on unequal area parts counted or treated as equal fractional shares").

triangulation(ref(misconception, unequal_parts_counted_as_equal_fractions),
    [ source(saxe_2005, agrees),
      source(olive_2006, agrees),
      source(confrey_2015, agrees) ]).

% --- corpus_38694: diagonal grid segment counted as 1 unit
geom_misconception(
    diagonal_grid_segment_unit,
    perimeter_as_boundary_traversal,
    "Diagonal of a grid square treated as length 1 (instead of √2)",
    [ "the diagonal is also 1 unit",
      "every line in the grid is the same length",
      "a slanted segment counts as one" ],
    "On a unit grid, horizontal and vertical segments have length 1 but a diagonal across a unit square has length √2 (≈ 1.41) by the Pythagorean theorem. When measuring perimeter on a grid, count diagonal pieces with their actual length, not as integer steps.",
    [corpus_38694]).

tier(ref(misconception, diagonal_grid_segment_unit), 3,
     [corpus_38694], "single-source corpus row 38694 (Clarke & Roche)").

% --- corpus_38996 / 40176 / 40261: triangle area = base * height (forgot 1/2)
geom_misconception(
    triangle_area_no_halving,
    area_as_array_structure,
    "Triangle area computed as base × height (without the 1/2)",
    [ "area of a triangle is base times height",
      "I multiplied base and height to get the area",
      "for the area I just used b*h" ],
    "A triangle is exactly half of a parallelogram with the same base and height — cut a parallelogram along a diagonal and you get two congruent triangles. So area_triangle = (1/2) * base * height. Demonstrate the cut-and-pair construction so the 1/2 is grounded, not memorized.",
    [corpus_38996, corpus_40176, corpus_40261]).

tier(ref(misconception, triangle_area_no_halving), 2,
     [corpus_38996, corpus_40176, corpus_40261],
     "research corpus — multi-source").

triangulation(ref(misconception, triangle_area_no_halving),
    [ source(baturo_nason_1996, agrees),
      source(arbaugh_lannin_2006, agrees),
      source(inoue_2011, agrees) ]).

% --- corpus_40241: side length from area by halving (instead of square root)
geom_misconception(
    side_from_area_by_halving,
    area_as_array_structure,
    "Side length of square computed by area / 2 (overgeneralizing the special case A=4 → s=2)",
    [ "the area is 9 so the side is 4.5",
      "you divide the area by 2 to get the side",
      "if the area is 16 the side is 8" ],
    "For a square, area = side². So side = √area, not area/2. The error overgeneralizes the special coincidence at area = 4 (where 4/2 = 2 = √4). Test with area = 9: the side must satisfy s² = 9, so s = 3, not 4.5.",
    [corpus_40241]).

tier(ref(misconception, side_from_area_by_halving), 3,
     [corpus_40241], "single-source corpus row 40241").

% --- corpus_38582 / 38583 / 38675: confusing area and length (PSTs)
geom_misconception(
    area_measured_with_ruler,
    area_unit_is_a_square,
    "Area measured by linear distance (ruler used to find area)",
    [ "I used a ruler to find the area",
      "the area of this square is 9 (giving the side length)",
      "I measured the length to get the area" ],
    "Length is one-dimensional and uses linear units; area is two-dimensional and uses square units. To find area you need to count or compute how many *square* units cover the region. A ruler alone gives you length; you then need to combine two lengths multiplicatively (or count squares) to get area.",
    [corpus_38675, corpus_38582, corpus_37566]).

tier(ref(misconception, area_measured_with_ruler), 2,
     [corpus_38675, corpus_38582, corpus_37566],
     "research corpus — multi-source on length/area conflation").

triangulation(ref(misconception, area_measured_with_ruler),
    [ source(clements_sarama_2018, agrees),
      source(wickstrom_fulton_2017, agrees),
      source(pesek_kirshner_2000, agrees) ]).

% --- corpus_39655 / 38676 / 38677: gaps and overlaps when tiling
geom_misconception(
    tiling_with_gaps_or_overlaps,
    area_as_array_structure,
    "Tiling a region with non-uniform units, gaps, or overlaps",
    [ "I drew tiles but they don't quite fit",
      "some squares are bigger than others",
      "I left gaps and that's okay" ],
    "Area measurement requires complete coverage by congruent units, with no gaps and no overlaps. If your tiling has gaps you've undercounted; if it has overlaps you've overcounted. Use a regular grid (or the row-and-column array of a rectangle) to see why uniform spacing is essential.",
    [corpus_39655, corpus_38676, corpus_38677]).

tier(ref(misconception, tiling_with_gaps_or_overlaps), 2,
     [corpus_39655, corpus_38676, corpus_38677],
     "research corpus — multi-source on tiling structure").

triangulation(ref(misconception, tiling_with_gaps_or_overlaps),
    [ source(hong_choi_2018, agrees),
      source(clements_sarama_2018, agrees) ]).

% --- corpus_40443: ribbon length related to faces or volume (not perimeter)
geom_misconception(
    ribbon_uses_volume_or_faces,
    perimeter_as_boundary_traversal,
    "Length of ribbon to wrap a box associated with face count or volume",
    [ "the cube has six faces so it needs more ribbon",
      "the bigger volume needs more ribbon",
      "more sides means more ribbon" ],
    "Ribbon length is a 1D quantity — total length around the wrapped path. It's not determined by face count (a 2D feature) or volume (a 3D feature). Identify the actual path the ribbon traces and add up its segment lengths.",
    [corpus_40443]).

tier(ref(misconception, ribbon_uses_volume_or_faces), 3,
     [corpus_40443], "single-source corpus row 40443").

% --- corpus_40010: pizza diameter as quantity (not area)
geom_misconception(
    diameter_treated_as_area,
    area_as_interior_coverage,
    "Pizza/circle quantity assessed by diameter or circumference instead of area",
    [ "this pizza is 40 so I get more for my money",
      "the bigger pizza number means more food",
      "I compare circles by their diameter" ],
    "The amount of pizza is its area, which scales as π r². Doubling the diameter quadruples the area, not doubles it. A 16-inch pizza has roughly 1.78× the area of a 12-inch pizza, even though it's only 1.33× the diameter. Always compare two-dimensional quantities by area, not by linear measure.",
    [corpus_40010]).

tier(ref(misconception, diameter_treated_as_area), 3,
     [corpus_40010], "single-source corpus row 40010 (Jankvist & Niss)").

% =====================================================================
% Material inferences
% =====================================================================

area_perimeter_material_claim(area_complete_unit_cover,
    area_as_interior_coverage,
    "region R has been completely covered by N unit squares, no gaps, no overlaps",
    "the area of R is N square units",
    entitled).

area_perimeter_material_claim(rectangle_perimeter_full_boundary,
    perimeter_as_boundary_traversal,
    "rectangle has length L and width W",
    "the perimeter is 2(L+W) linear units",
    entitled).

area_perimeter_material_claim(rectangle_area_array,
    area_as_array_structure,
    "rectangle has length L and width W",
    "the area is L*W square units",
    entitled).

area_perimeter_material_claim(quadratic_area_scaling,
    area_scales_quadratically,
    "linear dimensions of region R are multiplied by k",
    "the area of R is multiplied by k squared",
    entitled).

area_perimeter_material_claim(area_perimeter_order_rejection,
    area_perimeter_independence,
    "shape A has greater area than shape B",
    "shape A has greater perimeter than shape B",
    incompatible).

area_perimeter_material_claim(boundary_count_not_area,
    area_as_interior_coverage,
    "I counted the unit squares lying ON the boundary of R",
    "I have measured the area of R",
    incompatible).

area_perimeter_material_claim(rectangle_perimeter_requires_all_sides,
    perimeter_as_boundary_traversal,
    "I added the length and the width once",
    "I have measured the perimeter of the rectangle",
    incompatible).

area_perimeter_material_claim(area_requires_square_units,
    area_unit_is_a_square,
    "the calculated area is N",
    "the units are linear (cm, m), not square (cm², m²)",
    incompatible).

area_perimeter_material_claim(area_scaling_rejects_linear,
    area_scales_quadratically,
    "linear dimension is multiplied by k",
    "the area is multiplied by k (linearly)",
    incompatible).

area_perimeter_material_claim(equal_area_possible_without_congruence,
    area_conservation_under_transformation,
    "two regions are non-congruent",
    "the two regions cannot have equal area",
    incompatible).

area_perimeter_material_claim(unit_fraction_requires_equal_area_parts,
    partition_shapes_unit_fraction_area,
    "a shape is partitioned into N equal-area parts and one part is selected",
    "the selected part has area 1/N of the whole",
    entitled).

area_perimeter_material_claim(unequal_parts_not_unit_fractions,
    partition_shapes_unit_fraction_area,
    "a shape is split into N parts with unequal areas",
    "each part can be named 1/N of the whole by counting pieces",
    incompatible).

% =====================================================================
% N103 (Aichele & Wolfe 2008) — Chapters 5, 6, 9 area methods
% =====================================================================

% N103 names five area methods explicitly. Three are standard (cut-up,
% take-away, b*h), two are N103-specific (Julie's Way, Sean's Idea —
% both attributed by name to former students).

geom_concept(cut_up_area_method,
    "Method: cut a region into smaller parts whose areas are easy to figure out, then sum",
    area_perimeter,
    [3,4,5,6,7,8]).

tier(ref(concept, cut_up_area_method), 1,
     [n103_ch5],
     "N103 Activity 5.3 names this method explicitly. Standard.").

geom_concept(take_away_area_method,
    "Method: find the area of an enclosing simple region, then subtract the area of the part outside the target",
    area_perimeter,
    [4,5,6,7,8]).

tier(ref(concept, take_away_area_method), 1,
     [n103_ch5],
     "N103 Activity 5.3 names this method explicitly.").

geom_concept(julies_way_area_method,
    "Method: divide a region completely into small (half-unit) triangles, count them, divide by 2 — gives area",
    area_perimeter,
    [4,5,6,7,8]).

tier(ref(concept, julies_way_area_method), 3,
     [n103_ch5],
     "N103 Activity 5.5. ATTRIBUTED to a student named Julie. N103 explicitly says: 'Neither method [Julie's Way and Sean's idea] is widely known; neither appears in any other geometry text.' This is N103-idiosyncratic. Alias: 'triangle method'.").

geom_concept(seans_idea_area_method,
    "Method: count interior pegs (full = 1, edge = 1/2, corner = 1/4) — gives area",
    area_perimeter,
    [5,6,7,8]).

tier(ref(concept, seans_idea_area_method), 3,
     [n103_ch6],
     "N103 Activity 6.10. ATTRIBUTED to a student named Sean. N103-specific naming. Alias: 'fat-dot method'.").

geom_concept(critical_evaluation_of_methods,
    "Knowing when, where, and why a method works (not just how to apply it); awareness of method's scope",
    area_perimeter,
    [4,5,6,7,8]).

tier(ref(concept, critical_evaluation_of_methods), 1,
     [n103_ch5],
     "N103 frames this as a Big Idea (Activity 5.6). Distinct from standard concept inventories — this is a meta-cognitive teaching commitment.").

area_perimeter_material_claim(method_result_not_scope_proof,
    critical_evaluation_of_methods,
    "method M was applied to problem P and gave answer A",
    "method M is appropriate for problems of P's type, AND A is reliable",
    incompatible).

% N103 introduces Pick's theorem in Chapter 6, after extensive discovery work.

geom_concept(picks_formula,
    "For a simple closed lattice polygon: Area = I + E/2 - 1, where I = interior lattice points and E = boundary lattice points",
    area_perimeter,
    [6,7,8]).

tier(ref(concept, picks_formula), 1,
     [n103_ch6],
     "N103 Activity 6.7 introduces Pick's formula by name; attribution to Georg Alexander Pick (1899). The chapter spends multiple activities on discovery before the formula is stated.").

area_perimeter_material_claim(picks_formula_simple_lattice_polygon,
    picks_formula,
    "lattice polygon P is simple (non-self-intersecting) AND has I interior pegs and E edge pegs",
    "the area of P equals I + E/2 - 1",
    entitled).

area_perimeter_material_claim(picks_formula_rejects_crossed_or_multi_band,
    picks_formula,
    "the figure is made with multiple rubber bands OR the rubber band crosses itself",
    "Pick's formula gives the area",
    incompatible).

geom_concept(skew_geoboard_figure,
    "A geoboard figure each of whose edges touches exactly two pegs (one at each end), no edge pegs along the way",
    area_perimeter,
    [5,6,7,8]).

tier(ref(concept, skew_geoboard_figure), 3,
     [n103_ch6],
     "N103 Activity 6.1, 6.8. N103-specific terminology. Alias: 'skew' (e.g., 'skew quadrilateral', 'skew hexagon').").

geom_concept(tile_shape,
    "A 2D shape made by putting together unit square tiles edge-to-edge",
    area_perimeter,
    [3,4,5,6,7]).

tier(ref(concept, tile_shape), 3,
     [n103_ch6],
     "N103 Activity 6.2. N103-specific terminology distinct from 'polyomino', though Activity 6.6 connects them. Alias: 'polyomino' (used by N103 itself in Activity 6.6).").

geom_concept(solid_tile_shape,
    "A tile shape where (a) tiles touch along entire sides only, (b) every tile is attached by at least one full side, (c) there are no holes",
    area_perimeter,
    [4,5,6,7]).

tier(ref(concept, solid_tile_shape), 3,
     [n103_ch6],
     "N103 Activity 6.2. N103 uses this as a constraint to make Pick's-formula explorations clean.").

geom_concept(skinny_tile_shape,
    "A tile shape with no interior pegs — equivalently, a tile shape that is one tile wide",
    area_perimeter,
    [4,5,6,7]).

tier(ref(concept, skinny_tile_shape), 3,
     [n103_ch6],
     "N103 Activity 6.2. N103-specific. Edge-peg/area relation discovered first on these.").

% Circle area/perimeter from Ch 9

geom_concept(circle_area_formula,
    "Area of a circle = pi * r^2",
    area_perimeter,
    [6,7,8]).

tier(ref(concept, circle_area_formula), 1,
     [n103_ch9, ccss_7g4],
     "N103 Activity 9.2-9.3. Triangulates with CCSS 7.G.B.4.").

geom_concept(circle_circumference_formula,
    "Circumference of a circle = 2*pi*r = pi*d",
    area_perimeter,
    [6,7,8]).

tier(ref(concept, circle_circumference_formula), 1,
     [n103_ch9, ccss_7g4],
     "N103 Activity 9.1; N103 derives experimentally by string-and-roll measurement.").

geom_concept(sector_area,
    "Area of a sector = (central_angle / 360) * full circle area",
    area_perimeter,
    [7,8]).

tier(ref(concept, sector_area), 1,
     [n103_ch9],
     "N103 Activity 9.3. N103 frames sectors as 'fractional parts of a whole circle'.").

geom_concept(arc_length,
    "Length of arc = (central_angle / 360) * circumference",
    area_perimeter,
    [7,8]).

tier(ref(concept, arc_length), 1,
     [n103_ch9],
     "N103 Activity 9.3.").

geom_concept(pi_as_irrational,
    "Pi is an irrational number — its decimal expansion is non-terminating and non-repeating",
    area_perimeter,
    [6,7,8]).

tier(ref(concept, pi_as_irrational), 1,
     [n103_ch9],
     "N103 Chapter 9 introduction explicitly cites Lambert's 1767 proof of irrationality. Treat pi as 'a number we marvel at,' not just '3.14'.").

geom_concept(annulus,
    "Ring-shaped region between two concentric circles",
    area_perimeter,
    [7,8]).

tier(ref(concept, annulus), 3,
     [n103_ch9],
     "N103 Activity 9.14: 'A ringlike shape such as that shown is called an annulus.' Standard term but N103 explicitly names it.").

% =====================================================================
% Migrated from classification.pl 2026-05-04 (Q-007 resolution)
% Source: VdW Ch. 19. Originally parked in classification.pl by the VdW
% digger because of charter restriction. Topic atom = area_perimeter.
% =====================================================================

geom_concept(area_perimeter_distinction,
    "Area and perimeter are different attributes; area measures surface coverage and perimeter measures distance around the boundary",
    area_perimeter,
    [3,4,5,6]).

tier(ref(concept, area_perimeter_distinction), 1, [source(vdw, agrees)],
    "VdW Ch. 19 p. 494: 'Area and perimeter are a continual source of confusion for students.' Migrated from classification.pl 2026-05-04 (Q-007).").

geom_misconception(
    area_perimeter_confusion,
    area_perimeter_distinction,
    "Area and perimeter conflated or computed identically",
    [ "the area and perimeter are the same",
      "I'll multiply the sides to get the perimeter",
      "perimeter is how big it is",
      "I added the sides to get the area" ],
    "Contrast directly: build many rectangles with a fixed area and watch the perimeter change (Fixed Areas activity). Then build shapes with a fixed perimeter and watch the area change. Verbal hint: 'rim' is in 'perimeter' — perimeter is the rim, the boundary.",
    [vdw_ch19_p494]).

tier(ref(misconception, area_perimeter_confusion), 1, [source(vdw, agrees)],
    "VdW Ch. 19 p. 494 names this directly. Repair via Activity 19.19 contrasts. Migrated from classification.pl 2026-05-04 (Q-007).").

geom_concept(area_as_surface_coverage,
    "Area is a measure of two-dimensional surface coverage, not a length-times-length computation",
    area_perimeter,
    [3,4,5,6]).

tier(ref(concept, area_as_surface_coverage), 1, [source(vdw, agrees)],
    "VdW Ch. 19 p. 496. Migrated from classification.pl 2026-05-04 (Q-007).").

geom_misconception(
    no_sides_no_area,
    area_as_surface_coverage,
    "Shape with no straight sides assumed to have no area",
    [ "this shape has no sides so it has no area",
      "I can't find the area, there's nothing to multiply",
      "circles don't have area because they have no length and width" ],
    "Area is the measure of surface enclosed by the boundary; it does not require straight sides or a length-times-width. Tile the surface with a unit (squares, color tiles, even non-square units) and count. The number of units that cover it IS the area.",
    [vdw_ch19_p496]).

tier(ref(misconception, no_sides_no_area), 1, [source(vdw, agrees)],
    "VdW Ch. 19 p. 496 names this consequence of formula-first instruction explicitly, citing Zacharos (2006). Migrated from classification.pl 2026-05-04 (Q-007).").
