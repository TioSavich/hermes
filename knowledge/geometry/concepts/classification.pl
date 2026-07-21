% concepts/classification.pl — geometry concepts in the classification topic.
%
% Append clauses for: geom_concept/4, geom_misconception/6,
%                     material_inference/4, tier/4 (covering all of these).
% Cross-tagging (van_hiele_marker, metaphor_source, bootstrap,
% standard_anchor) lives in the corresponding subdirs.
%
% Schema: ../schema.pl

:- multifile geom_concept/4, geom_misconception/6, material_inference/4, tier/4.
:- discontiguous geom_concept/4, geom_misconception/6, material_inference/4, tier/4,
               classification_material_claim/5.
:- multifile triangulation/2.
:- discontiguous triangulation/2.

%!  classification_material_claim_witness(+Id, -Witness) is semidet.
%
%   Inspectable proof object for a finite classification material row.
classification_material_claim_witness(Id, Witness) :-
    witness_dict:witness_dict(geometry_classification_material_inference, closed_world_finite_classification_table,
                              _{id: Id,
                 concept: Concept,
                 premise: Premise,
                 conclusion: Conclusion,
                 polarity: Polarity,
                 concept_tier_boundary: ConceptTierBoundary,
                 concept_tier_evidence: ConceptTierEvidence,
                 boundary: finite_classification_curriculum_claim_not_general_taxonomy_theory,
                 condition_roles: Roles,
                 related_misconception_witnesses: MisconceptionWitnesses,
                 fact: material_inference(Concept, Premise, Conclusion, Polarity) }, WitnessDict27),
    classification_material_claim(Id, Concept, Premise, Conclusion, Polarity),
    classification_concept_tier_evidence(Concept,
                                         ConceptTierBoundary,
                                         ConceptTierEvidence),
    classification_related_misconception_witnesses(Concept,
                                                   MisconceptionWitnesses),
    classification_condition_roles(Id, Roles),
    Witness = WitnessDict27.

classification_concept_tier_evidence(Concept,
                                     loaded_concept_tier_record,
                                     TierEvidence) :-
    findall(_{ tier: Tier,
               sources: Sources,
               source_note: SourceNote },
            tier(ref(concept, Concept), Tier, Sources, SourceNote),
            RawTierEvidence),
    sort(RawTierEvidence, TierEvidence),
    TierEvidence \== [],
    !.
classification_concept_tier_evidence(_Concept,
                                     no_concept_tier_record_in_loaded_geometry_schema,
                                     []).

classification_related_misconception_witnesses(Concept, Witnesses) :-
    findall(Witness,
            classification_misconception_witness(Concept, Witness),
            RawWitnesses),
    sort(RawWitnesses, Witnesses).

classification_misconception_witness(Concept,
    _{ kind: geometry_classification_misconception_support,
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
    classification_triangulation_evidence(Id, TriangulationEvidence),
    tier(ref(misconception, Id), Tier, Sources, SourceNote).

classification_triangulation_evidence(Id, Evidence) :-
    findall(_{ record: ref(misconception, Id),
               agreement: Agreement },
            triangulation(ref(misconception, Id), Agreement),
            RawEvidence),
    sort(RawEvidence, Evidence).

classification_condition_roles(square_to_rectangle,
                               [ _{ kind: sufficiency_component,
                                    role: four_right_angles },
                                 _{ kind: specialization_component,
                                    role: equal_sides_add_square_constraint }
                               ]) :-
    !.
classification_condition_roles(square_to_rhombus,
                               [ _{ kind: sufficiency_component,
                                    role: four_equal_sides },
                                 _{ kind: specialization_component,
                                    role: right_angles_add_square_constraint }
                               ]) :-
    !.
classification_condition_roles(rectangle_to_parallelogram,
                               [ _{ kind: sufficiency_component,
                                    role: two_pairs_parallel_sides },
                                 _{ kind: specialization_component,
                                    role: right_angles_add_rectangle_constraint }
                               ]) :-
    !.
classification_condition_roles(rhombus_to_parallelogram,
                               [ _{ kind: sufficiency_component,
                                    role: four_equal_sides },
                                 _{ kind: implied_property,
                                    role: opposite_sides_parallel }
                               ]) :-
    !.
classification_condition_roles(parallelogram_to_quadrilateral,
                               [ _{ kind: sufficiency_component,
                                    role: two_pairs_parallel_sides },
                                 _{ kind: broader_category_component,
                                    role: four_sided_closed_polygon }
                               ]) :-
    !.
classification_condition_roles(square_rectangle_full_property_variant,
                               [ _{ kind: sufficiency_component,
                                    role: four_right_angles },
                                 _{ kind: sufficiency_component,
                                    role: opposite_sides_parallel },
                                 _{ kind: nonexclusion_component,
                                    role: all_sides_equal_does_not_cancel_rectangle_membership }
                               ]) :-
    !.
classification_condition_roles(rectangle_rejects_not_parallelogram,
                               [ _{ kind: incompatibility_component,
                                    role: right_angles_do_not_cancel_parallelogram_membership },
                                 _{ kind: hierarchy_component,
                                    role: rectangle_is_special_parallelogram }
                               ]) :-
    !.
classification_condition_roles(square_rejects_not_rectangle,
                               [ _{ kind: incompatibility_component,
                                    role: name_difference_does_not_cancel_class_membership },
                                 _{ kind: hierarchy_component,
                                    role: square_is_special_rectangle }
                               ]) :-
    !.
classification_condition_roles(square_rejects_not_rhombus,
                               [ _{ kind: incompatibility_component,
                                    role: prototype_tilt_does_not_determine_rhombus_membership },
                                 _{ kind: hierarchy_component,
                                    role: square_is_special_rhombus }
                               ]) :-
    !.
classification_condition_roles(rhombus_rejects_not_parallelogram,
                               [ _{ kind: incompatibility_component,
                                    role: visual_prototype_does_not_cancel_parallel_side_properties },
                                 _{ kind: hierarchy_component,
                                    role: rhombus_is_special_parallelogram }
                               ]) :-
    !.
classification_condition_roles(parallelogram_rejects_quadrilateral_converse,
                               [ _{ kind: incompatibility_component,
                                    role: quadrilateral_membership_does_not_entail_parallel_sides },
                                 _{ kind: converse_error,
                                    role: broader_category_to_special_case_not_licensed }
                               ]) :-
    !.
classification_condition_roles(parallelogram_rejects_not_quadrilateral,
                               [ _{ kind: incompatibility_component,
                                    role: special_name_does_not_cancel_broader_category },
                                 _{ kind: hierarchy_component,
                                    role: parallelogram_is_quadrilateral }
                               ]) :-
    !.
classification_condition_roles(equivalent_definitions_over_biconditional,
                               [ _{ kind: sufficiency_component,
                                    role: same_extension_of_shapes },
                                 _{ kind: definition_component,
                                    role: biconditional_membership_test }
                               ]) :-
    !.
classification_condition_roles(inclusive_over_exclusive,
                               [ _{ kind: stance_component,
                                    role: inclusive_definitions_in_use },
                                 _{ kind: hierarchy_component,
                                    role: specific_shape_keeps_general_names }
                               ]) :-
    !.
classification_condition_roles(exclusive_transition_rejects_square_only,
                               [ _{ kind: incompatibility_component,
                                    role: square_only_stance_conflicts_with_property_hierarchy },
                                 _{ kind: developmental_boundary,
                                    role: exclusive_to_inclusive_transition }
                               ]) :-
    !.
classification_condition_roles(medial_quadrilateral_midpoint_parallelogram,
                               [ _{ kind: sufficiency_component,
                                    role: consecutive_side_midpoints_joined },
                                 _{ kind: classification_component,
                                    role: resulting_medial_quadrilateral_is_parallelogram }
                               ]) :-
    !.
classification_condition_roles(parallelogram_to_trapezoid,
                               [ _{ kind: stance_component,
                                    role: inclusive_trapezoid_definition },
                                 _{ kind: sufficiency_component,
                                    role: at_least_one_pair_parallel_sides }
                               ]) :-
    !.
classification_condition_roles(parallelogram_trapezoid_exclusive_rejection,
                               [ _{ kind: incompatibility_component,
                                    role: exclusive_trapezoid_disjointness_conflicts_with_inclusive_stance },
                                 _{ kind: scope_component,
                                    role: level_relative_exclusive_definition }
                               ]) :-
    !.
classification_condition_roles(kite_class_over_quadrilateral,
                               [ _{ kind: sufficiency_component,
                                    role: convex_quadrilateral },
                                 _{ kind: sufficiency_component,
                                    role: two_opposing_pairs_congruent_adjacent_sides }
                               ]) :-
    !.
classification_condition_roles(quadrilateral_hierarchy_property_list,
                               [ _{ kind: sufficiency_component,
                                    role: property_list_for_category_satisfied },
                                 _{ kind: nonexclusion_component,
                                    role: more_specific_subcategory_does_not_cancel_membership }
                               ]) :-
    !.
classification_condition_roles(quadrilateral_hierarchy_rejects_name_cancellation,
                               [ _{ kind: incompatibility_component,
                                    role: more_specific_name_does_not_cancel_general_names },
                                 _{ kind: hierarchy_component,
                                    role: inclusive_quadrilateral_hierarchy }
                               ]) :-
    !.
classification_condition_roles(_, []).

material_inference(Concept, Premise, Conclusion, Polarity) :-
    classification_material_claim_witness(_Id, Witness),
    get_dict(fact, Witness, material_inference(Concept,
                                               Premise,
                                               Conclusion,
                                               Polarity)).

% =====================================================================
% Concepts — quadrilateral hierarchy (Van Hiele level 2/3 territory)
% =====================================================================

geom_concept(quadrilateral_hierarchy,
    "Inclusive (hierarchical) classification of quadrilaterals",
    classification,
    [3,4,5,6,7,8]).

geom_concept(square_as_rectangle,
    "A square is a special rectangle (all four sides equal)",
    classification,
    [3,4,5,6]).

geom_concept(square_as_rhombus,
    "A square is a special rhombus (all four angles right)",
    classification,
    [4,5,6,7]).

geom_concept(rectangle_as_parallelogram,
    "A rectangle is a special parallelogram (with right angles)",
    classification,
    [4,5,6,7]).

geom_concept(rhombus_as_parallelogram,
    "A rhombus is a special parallelogram (with congruent sides)",
    classification,
    [4,5,6,7]).

geom_concept(parallelogram_as_quadrilateral,
    "A parallelogram is a quadrilateral (any four-sided polygon)",
    classification,
    [3,4,5,6]).

geom_concept(orientation_invariant_naming,
    "A shape's name is determined by its properties, not its orientation on the page",
    classification,
    [1,2,3,4,5]).

% =====================================================================
% Tier 1 — ported BENNY records (misconceptions_geometric_batch_1/2.pl)
% =====================================================================
% These ports preserve the original db_row triggers and lift the BENNY
% taxonomic assertion (Shape→Target, holds|fails) into a misconception
% with explicit triggers/repair drawn from the source description.

% --- benny_38040: rectangle is not a parallelogram (partitional concept image)
geom_misconception(
    rect_not_parallelogram_partitional,
    rectangle_as_parallelogram,
    "Rectangle excluded from parallelograms (partitional concept image)",
    [ "rectangles aren't parallelograms",
      "a parallelogram is the slanted one",
      "they look different so they aren't related" ],
    "Compare definitions side by side. A parallelogram is any quadrilateral with two pairs of parallel sides. Check the rectangle: opposite sides are parallel. Therefore every rectangle satisfies the parallelogram definition. The rectangle adds the right-angle constraint on top of being a parallelogram.",
    [benny_38040, ng_2012, dicky_ng_2012_quadrilaterals]).

tier(ref(misconception, rect_not_parallelogram_partitional), 1,
     [benny_38040, corpus_38040], "ported from BENNY batch_1; corpus row 38040 (Ng 2012)").

% --- benny_38447: parallelogram is a type of rectangle (overclaim)
geom_misconception(
    parallelogram_is_rectangle,
    rectangle_as_parallelogram,
    "Parallelogram and rectangle conflated (calling parallelograms rectangles)",
    [ "a parallelogram is a rectangle",
      "they are both rectangles",
      "this is a slanted rectangle" ],
    "The inclusion runs the other way. Every rectangle is a parallelogram (it has two pairs of parallel sides), but not every parallelogram is a rectangle (a parallelogram with no right angles is not a rectangle). Check angles: rectangles have four 90-degree angles; parallelograms in general do not.",
    [benny_38447, walcott_mohr_kastberg_2009]).

tier(ref(misconception, parallelogram_is_rectangle), 1,
     [benny_38447, corpus_38447], "ported from BENNY batch_1; corpus row 38447").

% --- benny_38448: rectangles and parallelograms as disjoint classes
geom_misconception(
    rectangle_not_parallelogram_disjoint,
    rectangle_as_parallelogram,
    "Rectangles and parallelograms held as disjoint classes",
    [ "one is a parallelogram, one is a rectangle",
      "they have different names so they are different shapes",
      "rectangles aren't parallelograms because rectangles are rectangles" ],
    "Names mark special cases inside a hierarchy, not separate buckets. A rectangle is a parallelogram with the extra property that all angles are right. The two names co-apply: the same shape can answer to both.",
    [benny_38448, walcott_mohr_kastberg_2009]).

tier(ref(misconception, rectangle_not_parallelogram_disjoint), 1,
     [benny_38448, corpus_38448], "ported from BENNY batch_2; corpus row 38448").

% --- benny_39875: every quadrilateral is a parallelogram (overclaim)
geom_misconception(
    quadrilateral_is_parallelogram,
    parallelogram_as_quadrilateral,
    "Every quadrilateral assumed to be a parallelogram",
    [ "isn't every quadrilateral a parallelogram?",
      "four sides means parallelogram",
      "all four-sided shapes are parallelograms" ],
    "Quadrilateral is the broader category — any closed four-sided polygon counts, including trapezoids, kites, and irregular four-sided shapes that have no parallel sides at all. Parallelogram requires two pairs of parallel sides, which most quadrilaterals do not have.",
    [benny_39875, joglar_prieto_2014]).

tier(ref(misconception, quadrilateral_is_parallelogram), 1,
     [benny_39875, corpus_39875], "ported from BENNY batch_1; corpus row 39875").

% --- benny_40228: parallelogram not recognized as a quadrilateral
geom_misconception(
    parallelogram_not_quadrilateral,
    parallelogram_as_quadrilateral,
    "Quadrilateral definition restricted to right-angled shapes",
    [ "quadrilaterals have four right angles",
      "if it's slanted it's not a quadrilateral",
      "parallelograms aren't quadrilaterals" ],
    "Quadrilateral means any four-sided closed polygon — that's the only constraint. The angles can be anything as long as they sum to 360 degrees. Parallelograms, trapezoids, and irregular four-sided shapes are all quadrilaterals.",
    [benny_40228, fuentes_ma_2018]).

tier(ref(misconception, parallelogram_not_quadrilateral), 1,
     [benny_40228, corpus_40228], "ported from BENNY batch_1; corpus row 40228").

% --- benny_40352: square is not a rhombus (underclaim)
geom_misconception(
    square_not_rhombus,
    square_as_rhombus,
    "Square refused as a rhombus",
    [ "a square is not a rhombus",
      "rhombuses are tilted, squares aren't",
      "they're different shapes" ],
    "A rhombus is a quadrilateral with four equal sides. A square has four equal sides plus four right angles — the right angles are an additional constraint, not a contradiction. Every square satisfies the rhombus definition; it's a rhombus that happens to also be a rectangle.",
    [benny_40352, lin_2005]).

tier(ref(misconception, square_not_rhombus), 1,
     [benny_40352, corpus_40352], "ported from BENNY batch_1; corpus row 40352").

% --- benny_38448 / 39901 / 40229 / 40536: square is not a rectangle (underclaim)
% Four BENNY rows attest the same underlying misconception. We collapse to one
% record and triangulate.
geom_misconception(
    square_not_rectangle,
    square_as_rectangle,
    "Square refused as a rectangle (separate-name fallacy)",
    [ "a square is not a rectangle",
      "a rectangle has a different length and breadth",
      "they have different names so they're different",
      "squares and rectangles look different" ],
    "Rectangle means: four-sided polygon with four right angles. A square has four right angles. Therefore every square is a rectangle. The square adds the constraint that all four sides are equal — this constraint is *additional*, not contradictory. The two names co-apply: a square is the special rectangle whose sides are all equal.",
    [benny_39901, benny_40229, benny_40536, hourigan_odonoghue_2013, fuentes_ma_2018, watson_2010]).

tier(ref(misconception, square_not_rectangle), 1,
     [benny_39901, benny_40229, benny_40536, corpus_39901, corpus_40229, corpus_40536],
     "ported from BENNY batches 1+2; collapses three corpus rows attesting the same misconception").

triangulation(ref(misconception, square_not_rectangle),
    [ source(hourigan_odonoghue_2013, agrees),
      source(fuentes_ma_2018, agrees),
      source(watson_2010, agrees) ]).

% --- benny_39107: rhombus not recognized as parallelogram (Fischbein figural concept)
geom_misconception(
    rhombus_not_parallelogram,
    rhombus_as_parallelogram,
    "Rhombus refused as a parallelogram (visual prototype rejection)",
    [ "a rhombus isn't a parallelogram",
      "parallelograms are slanted, rhombuses are diamond-shaped",
      "if it's a diamond it's not a parallelogram" ],
    "Parallelogram requires two pairs of parallel sides. A rhombus has two pairs of parallel sides (and additionally has all four sides equal). So every rhombus is a parallelogram. Visual prototypes (the canonical 'slanted' parallelogram) make this hard to see — return to the property test.",
    [benny_39107, fischbein_1999]).

tier(ref(misconception, rhombus_not_parallelogram), 1,
     [benny_39107, corpus_39107], "ported from BENNY batch_2; corpus row 39107 (Fischbein)").

% --- benny_40351: parallelogram identified as rhombus (overclaim)
geom_misconception(
    parallelogram_is_rhombus,
    square_as_rhombus,
    "Parallelogram misidentified as rhombus (any slanted four-sided shape called rhombus)",
    [ "this parallelogram is a rhombus",
      "all parallelograms are rhombuses",
      "if it's slanted with four sides it's a rhombus" ],
    "Rhombus requires four equal sides. A general parallelogram has only opposite sides equal — adjacent sides can differ. So a parallelogram is a rhombus only when all four sides happen to be equal. The reverse inclusion (rhombus ⇒ parallelogram) does hold; the forward direction does not.",
    [benny_40351, lin_2005]).

tier(ref(misconception, parallelogram_is_rhombus), 1,
     [benny_40351, corpus_40351], "ported from BENNY batch_2; corpus row 40351").

% =====================================================================
% Material inferences — the commitments these misconceptions violate
% =====================================================================

% Entitled inferences — what the hierarchy actually licenses.
classification_material_claim(square_to_rectangle,
    square_as_rectangle,
    "shape S has four right angles AND four equal sides",
    "S is a rectangle (and additionally a square)",
    entitled).

classification_material_claim(square_to_rhombus,
    square_as_rhombus,
    "shape S has four equal sides AND four right angles",
    "S is a rhombus (and additionally a square)",
    entitled).

classification_material_claim(rectangle_to_parallelogram,
    rectangle_as_parallelogram,
    "shape S has two pairs of parallel sides AND four right angles",
    "S is a parallelogram (and additionally a rectangle)",
    entitled).

classification_material_claim(rhombus_to_parallelogram,
    rhombus_as_parallelogram,
    "shape S has four equal sides",
    "S has two pairs of parallel sides — S is a parallelogram",
    entitled).

classification_material_claim(parallelogram_to_quadrilateral,
    parallelogram_as_quadrilateral,
    "shape S has two pairs of parallel sides",
    "S has four sides — S is a quadrilateral",
    entitled).

% Incompatible inferences — the bad commitments inside each misconception.
classification_material_claim(rectangle_rejects_not_parallelogram,
    rectangle_as_parallelogram,
    "shape S is a rectangle",
    "S is NOT a parallelogram (because rectangles and parallelograms are separate classes)",
    incompatible).

classification_material_claim(square_rejects_not_rectangle,
    square_as_rectangle,
    "shape S is a square",
    "S is NOT a rectangle (because the names are different)",
    incompatible).

classification_material_claim(square_rejects_not_rhombus,
    square_as_rhombus,
    "shape S is a square",
    "S is NOT a rhombus (because squares aren't tilted)",
    incompatible).

classification_material_claim(rhombus_rejects_not_parallelogram,
    rhombus_as_parallelogram,
    "shape S is a rhombus",
    "S is NOT a parallelogram (rhombus is the diamond, parallelogram is the slanted)",
    incompatible).

classification_material_claim(parallelogram_rejects_quadrilateral_converse,
    parallelogram_as_quadrilateral,
    "shape S has four sides and is closed",
    "S is a parallelogram (every quadrilateral is a parallelogram)",
    incompatible).

classification_material_claim(parallelogram_rejects_not_quadrilateral,
    parallelogram_as_quadrilateral,
    "shape S is a parallelogram",
    "S is NOT a quadrilateral (parallelograms are special, not generic four-sided)",
    incompatible).

% =====================================================================
% Tier 2 — research-corpus harvested misconceptions
% =====================================================================

% --- corpus_38040: partitional vs hierarchical concept image (Ng 2012, but also
% triangulated by Mayberry 1983 / Pickreign 2007 etc. via repeated theme).
% Already covered above (collapsed with rect_not_parallelogram_partitional).

% --- corpus_39873/38067/37754: square / triangle prototype with horizontal base
geom_concept(prototype_orientation_dependence,
    "Recognition of a shape collapses when shown in non-prototypical orientation",
    classification,
    [0,1,2,3,4,5]).

geom_misconception(
    square_only_axis_aligned,
    orientation_invariant_naming,
    "Tilted square (diamond) refused as a square",
    [ "that's a diamond, not a square",
      "squares have flat sides on the bottom",
      "if it's tilted it can't be a square" ],
    "The properties define the shape, not the page-orientation. Rotate the figure: count sides (four), check side lengths (equal), check angles (right). All four properties are invariant under rotation. The 'diamond' is a square at 45 degrees.",
    [corpus_37754, corpus_40566, fischbein_1999]).

tier(ref(misconception, square_only_axis_aligned), 2,
     [corpus_37754, corpus_40566, corpus_38891],
     "research corpus — multiple papers attest orientation-prototype rejection").

triangulation(ref(misconception, square_only_axis_aligned),
    [ source(corpus_37754, agrees),
      source(corpus_40566, agrees),
      source(corpus_38891, agrees) ]).

geom_misconception(
    triangle_only_horizontal_base,
    orientation_invariant_naming,
    "Triangle restricted to prototypical isosceles or equilateral with horizontal base",
    [ "that's not a triangle, it's pointing up",
      "triangles have a flat bottom",
      "obtuse triangles aren't triangles" ],
    "Triangle means three straight sides forming a closed figure — orientation, side lengths, and angle types are not part of the definition. Practice with rotated, scalene, obtuse, and very thin triangles to break the prototype.",
    [corpus_38067, corpus_39873]).

tier(ref(misconception, triangle_only_horizontal_base), 2,
     [corpus_38067, corpus_39873, corpus_38891],
     "research corpus — children restrict triangle definition to prototype").

triangulation(ref(misconception, triangle_only_horizontal_base),
    [ source(corpus_38067, agrees),
      source(corpus_39873, agrees),
      source(corpus_38891, agrees) ]).

% --- corpus_39098: parallelogram and trapezoid confusion
geom_misconception(
    parallelogram_trapezoid_confusion,
    quadrilateral_hierarchy,
    "Parallelogram and trapezoid definitions and visuals confused",
    [ "this trapezoid is a parallelogram",
      "parallelograms and trapezoids are the same",
      "any four-sided slanted shape is a parallelogram or trapezoid" ],
    "The parallel-sides property distinguishes them. A parallelogram has *two* pairs of parallel sides. A trapezoid (in the exclusive U.S. definition) has exactly *one* pair, and (in the inclusive definition) has *at least* one pair. Show side pairs explicitly and check parallelism.",
    [corpus_39098]).

tier(ref(misconception, parallelogram_trapezoid_confusion), 3,
     [corpus_39098], "single-source corpus row 39098").

% --- corpus_38067 / 39828: cylinder/cone restricted to prototype
geom_misconception(
    cylinder_cone_prototype_image,
    quadrilateral_hierarchy,
    "Cylinders and cones restricted to vertical-axis prototypes",
    [ "that's not a cylinder, it's lying down",
      "cones have to point up",
      "if the base isn't on the bottom it's not a cone" ],
    "Cylinder and cone are defined by surfaces of revolution / by their cross-sections, not by orientation. A cylinder lying on its side is still a cylinder. Tip the figure and re-check the cross-section.",
    [corpus_39828]).

tier(ref(misconception, cylinder_cone_prototype_image), 3,
     [corpus_39828], "single-source corpus row 39828").

% --- corpus_37729: overly restrictive or overly broad definitions
geom_misconception(
    definitional_under_or_over_specification,
    quadrilateral_hierarchy,
    "Student definitions are overly restrictive, overly broad, or procedural",
    [ "a square is a shape with four sides",
      "a rectangle is what you get from a piece of paper",
      "a triangle is when you draw three lines" ],
    "A definition needs *necessary and sufficient* conditions. Test the candidate definition against borderline cases: does it admit non-examples, or exclude legitimate examples? Refine until both cases settle correctly.",
    [corpus_37729]).

tier(ref(misconception, definitional_under_or_over_specification), 3,
     [corpus_37729], "single-source corpus row 37729").

% =====================================================================
% N103 (Aichele & Wolfe 2008) — added by N103 digger
% =====================================================================

% N103 names exactly seven types of quadrilaterals across Chapter 2:
% squares, rhombuses, rectangles, parallelograms, kites, trapezoids,
% isosceles trapezoids. The text walks preservice teachers through
% inclusive vs exclusive definitions and the *equivalent definitions*
% phenomenon as load-bearing pedagogical content.

geom_concept(n103_seven_quadrilateral_types,
    "N103's working set of seven quadrilateral types: square, rhombus, rectangle, parallelogram, kite, trapezoid, isosceles trapezoid",
    classification,
    [3,4,5,6,7,8]).

tier(ref(concept, n103_seven_quadrilateral_types), 3,
     [n103_ch2],
     "N103 fixes the inventory at seven; this is N103's pedagogical scope choice. Other texts include other shapes (e.g., dart). Alias: 'seven types of quadrilaterals' (Aichele and Wolfe 2008, Chapter 2).").

geom_concept(inclusive_definition,
    "A definition that admits special cases (e.g., 'a trapezoid has at least one pair of parallel sides' admits parallelograms as special trapezoids)",
    classification,
    [4,5,6,7,8]).

tier(ref(concept, inclusive_definition), 1,
     [n103_ch2, van_de_walle, ccss_5g3, ccss_5g4],
     "N103 names this directly and dedicates Activity 2.13 to it. Triangulates with Van de Walle and CCSS 5.G.3-4.").

geom_concept(exclusive_definition,
    "A definition that rules out special cases (e.g., 'a trapezoid has only one pair of parallel sides' excludes parallelograms)",
    classification,
    [4,5,6,7,8]).

tier(ref(concept, exclusive_definition), 1,
     [n103_ch2],
     "N103 names this directly. The Webster's-style 'only one pair' trapezoid definition is the canonical example.").

geom_concept(equivalent_definitions,
    "Two different-looking definitions that pick out the same set of shapes",
    classification,
    [5,6,7,8]).

tier(ref(concept, equivalent_definitions), 1,
     [n103_ch2],
     "N103 Activity 2.15: 'A kite is a quadrilateral with at least one pair of congruent opposite angles' versus 'A kite has perpendicular diagonals' — N103 makes equivalence-checking a teaching task.").

% N103-specific framing: N103 says explicitly that children think *exclusively*
% before thinking *inclusively*, and frames the exclusive→inclusive transition
% as a developmental milestone for the preservice teacher to support.

geom_concept(exclusive_to_inclusive_transition,
    "Developmental progression from exclusive (looks-like) classification to inclusive (property-based) classification",
    classification,
    [3,4,5,6,7]).

tier(ref(concept, exclusive_to_inclusive_transition), 1,
     [n103_ch2],
     "N103 frames this as a developmental shift teachers should support, not just a fact about definitions. 'Children think in terms of exclusive definitions.' (Activity 2.13)").

% N103 trapezoid stance: inclusive (≥1 pair parallel sides). Aligns with VdW.
% This is in tension with Webster's-style exclusive definitions, which N103
% flags but does not adopt.

geom_concept(trapezoid_inclusive,
    "Trapezoid: a quadrilateral with at least one pair of parallel sides (inclusive definition adopted by N103)",
    classification,
    [3,4,5,6,7,8]).

tier(ref(concept, trapezoid_inclusive), 2,
     [n103_ch2, van_de_walle, ccss_5g3],
     "N103 explicitly adopts the inclusive definition while flagging that some sources (Webster's) use the exclusive form. Triangulates with Van de Walle and CCSS.").

% Misconception unique to N103's framing: students confuse "supporting example"
% with "proof," failing to recognize that universal claims need either an
% argument or exhaustive checking.

geom_misconception(
    supporting_example_treated_as_proof,
    quadrilateral_hierarchy,
    "Treating a supporting example as proof of a universal claim",
    [ "I checked one example and it worked",
      "all triangles must work that way",
      "see, this rectangle's diagonals are equal so all parallelograms have equal diagonals" ],
    "A supporting example provides evidence but does not prove a universal statement. A counterexample disproves; only exhaustive checking or an argument from definitions proves. N103 makes this an explicit move (Activity 2.7): try to find a counterexample before believing the claim.",
    [n103_ch2]).

tier(ref(misconception, supporting_example_treated_as_proof), 1,
     [n103_ch2],
     "N103 Activity 2.7 explicitly names this — 'If we checked the preceding statement about parallelograms on just the first example, we would have incorrectly believed that the statement was true.'").

classification_material_claim(equivalent_definitions_over_biconditional,
    equivalent_definitions,
    "Two definitions D1 and D2 admit exactly the same set of shapes",
    "D1 and D2 are equivalent definitions",
    entitled).

classification_material_claim(inclusive_over_exclusive,
    exclusive_to_inclusive_transition,
    "shape S is a square AND the student is using inclusive definitions",
    "S is also a rectangle, also a parallelogram, also a quadrilateral",
    entitled).

classification_material_claim(exclusive_transition_rejects_square_only,
    exclusive_to_inclusive_transition,
    "shape S is a square AND the student is using exclusive definitions",
    "S is a square (only) — using property-based hierarchical reasoning is incompatible with the exclusive stance",
    incompatible).

% N103 introduces the *medial quadrilateral* (Activity 2.8) — also called the
% inscribed quadrilateral — formed by joining midpoints of consecutive sides.
% A discovery: the medial quadrilateral of any quadrilateral is always a
% parallelogram.

geom_concept(medial_quadrilateral,
    "The quadrilateral formed by joining the midpoints of consecutive sides of a quadrilateral; also called the inscribed quadrilateral",
    classification,
    [6,7,8]).

tier(ref(concept, medial_quadrilateral), 1,
     [n103_ch2],
     "N103 Activity 2.8. The discovery that medial quadrilaterals are always parallelograms is a Big Idea in N103.").

classification_material_claim(medial_quadrilateral_midpoint_parallelogram,
    medial_quadrilateral,
    "Q is any quadrilateral, M is the quadrilateral joining midpoints of consecutive sides",
    "M is a parallelogram",
    entitled).

% =====================================================================
% Van de Walle digger contributions (2026-05-03)
% Source: Van de Walle, Karp, Bay-Williams, Elementary and Middle School
% Mathematics, 9th ed., Ch. 20, pp. 523-524.
% Backing corpus: ../corpus/van_de_walle_excerpts.md
% =====================================================================

% VdW's Table 20.2 inventory adds two shapes the existing concept set
% does not yet name: kite and (separate) isosceles trapezoid. The
% trapezoid_inclusive concept is already authored by N103; below we
% add VdW-specific tier annotation.

geom_concept(kite_class,
    "Kite: a convex quadrilateral with two opposing pairs of congruent adjacent sides",
    classification,
    [3,4,5,6,7,8]).

tier(ref(concept, kite_class), 1, [source(vdw, agrees)],
    "VdW Ch. 20 Table 20.2 (p. 523): 'Kite: Two opposing pairs of congruent adjacent sides.'").

geom_concept(isosceles_trapezoid_class,
    "Isosceles trapezoid: a trapezoid with a pair of opposite sides congruent",
    classification,
    [4,5,6,7,8]).

tier(ref(concept, isosceles_trapezoid_class), 1, [source(vdw, agrees)],
    "VdW Ch. 20 Table 20.2 (p. 523): 'Isosceles: A pair of opposite sides is congruent' — listed as a sub-class of trapezoid.").

% VdW's stated quadrilateral hierarchy commitments — anchor with citation.

tier(ref(concept, square_as_rectangle), 1, [source(vdw, agrees)],
    "VdW Ch. 20 p. 523 directly: 'a square is a rectangle and a rhombus.' Stated as part of the inclusive classification position.").

tier(ref(concept, square_as_rhombus), 1, [source(vdw, agrees)],
    "VdW Ch. 20 p. 523 directly: 'a square is a rectangle and a rhombus.'").

tier(ref(concept, rectangle_as_parallelogram), 1, [source(vdw, agrees)],
    "VdW Ch. 20 Table 20.2 p. 523: 'Rectangle: Parallelogram with a right angle.'").

tier(ref(concept, rhombus_as_parallelogram), 1, [source(vdw, agrees)],
    "VdW Ch. 20 Table 20.2 p. 523: 'Rhombus: Parallelogram with all sides congruent.'").

tier(ref(concept, parallelogram_as_quadrilateral), 1, [source(vdw, agrees)],
    "VdW Ch. 20 p. 523: parallelograms appear as a sub-class of trapezoids and convex quadrilaterals in Table 20.2.").

tier(ref(concept, quadrilateral_hierarchy), 1, [source(vdw, agrees)],
    "VdW Ch. 20 pp. 523-524: 'In the classification of quadrilaterals and parallelograms, some subsets overlap.' Inclusive hierarchy position is stated and exemplified.").

% Parallelogram-is-a-trapezoid: inclusive definition (VdW's stance) with
% acknowledgment of the exclusive alternative.

geom_concept(parallelogram_as_trapezoid,
    "A parallelogram is a special trapezoid (under the inclusive 'at least one pair of parallel sides' definition)",
    classification,
    [4,5,6,7,8]).

tier(ref(concept, parallelogram_as_trapezoid), 1, [source(vdw, agrees)],
    "VdW Ch. 20 p. 523: 'All parallelograms are trapezoids, but not all trapezoids are parallelograms.' Footnote acknowledges some curricula (and Webster's-style definitions) use the exclusive form.").

% Material inferences — VdW's stated entitlements and their incompatibilities.

classification_material_claim(parallelogram_to_trapezoid,
    parallelogram_as_trapezoid,
    "shape S has two pairs of parallel sides",
    "S has at least one pair of parallel sides — S is a trapezoid (inclusive definition)",
    entitled).

classification_material_claim(parallelogram_trapezoid_exclusive_rejection,
    parallelogram_as_trapezoid,
    "shape S is a parallelogram",
    "S is NOT a trapezoid (under the exclusive 'only one pair of parallel sides' definition)",
    incompatible).

% Q-008 / Q-MH-A / Q-N103-F resolution 2026-05-04: demote this incompatible
% inference to Tier 3. The exclusive stance is valid only as a developmental
% waypoint, not a strict universal incompatibility. See trapezoid_classification_arc
% in concepts/developmental_arcs.pl for the developmental_marker/4 capturing the
% exclusive→inclusive transition. Within the exclusive stance the inference holds;
% within the inclusive stance (VdW, N103, CCSS canonical) it does not.
tier(ref(material_inference, parallelogram_as_trapezoid, exclusive_stance), 3,
    [source(vdw, partial), source(synthesizer, agrees)],
    "Tier 3 (Q-008 resolution 2026-05-04): valid only within the exclusive stance; see trapezoid_classification_arc developmental_marker. The exclusive→inclusive transition is the unit, not the choice between framings.").

classification_material_claim(kite_class_over_quadrilateral,
    kite_class,
    "shape S is a convex quadrilateral with two opposing pairs of congruent adjacent sides",
    "S is a kite",
    entitled).

classification_material_claim(square_rectangle_full_property_variant,
    square_as_rectangle,
    "shape S has four right angles AND opposite sides parallel AND opposite sides equal",
    "S is a rectangle (regardless of whether all four sides happen to be equal)",
    entitled).

classification_material_claim(quadrilateral_hierarchy_property_list,
    quadrilateral_hierarchy,
    "shape S satisfies the property list for category C",
    "S belongs to C, even if S also belongs to a more-specific subcategory of C",
    entitled).

classification_material_claim(quadrilateral_hierarchy_rejects_name_cancellation,
    quadrilateral_hierarchy,
    "shape S has a more-specific name (e.g., square)",
    "S's more-general names (rectangle, rhombus, parallelogram, trapezoid, quadrilateral) no longer apply",
    incompatible).

% =====================================================================
% Van de Walle: misconceptions named explicitly in Ch. 20 + 19
% =====================================================================

% Tilted-square-as-diamond — VdW level-0 hallmark (p. 514).
% Note: existing record `square_only_axis_aligned` covers this; below we
% add VdW-citation tier.

tier(ref(misconception, square_only_axis_aligned), 1, [source(vdw, agrees)],
    "VdW p. 514 explicitly: 'A level 0 thinker, for example, may see a square with sides that are not horizontal or vertical (it appears tilted) and believe it is a diamond (not a mathematical term for a shape) and no longer a square.' This refines the existing Tier 2 research-corpus tier annotation.").

% Triangle-upside-down (VdW p. 519) — register as VdW-specific misconception
% under the existing prototype-orientation-dependence concept.

geom_misconception(
    triangle_upside_down,
    prototype_orientation_dependence,
    "Triangle in non-canonical orientation called 'upside down'",
    [ "this triangle is upside down",
      "triangles point up, not down",
      "that's not really a triangle, it's flipped" ],
    "Triangles can be drawn in any orientation. The definition is three straight sides forming a closed figure — the apex doesn't have to be on top. Show triangles in many orientations: vertex at the bottom, vertex on the side, scalene triangles where no orientation is canonical. Vary side lengths and angle types so no single 'right' look dominates.",
    [vdw_ch20_p519]).

tier(ref(misconception, triangle_upside_down), 1, [source(vdw, agrees)],
    "VdW Ch. 20 p. 519 directly: 'If students say a triangle is upside down, it may be because they have rarely seen triangles illustrated differently.'").

% Squares-aren't-rectangles / class-inclusion confusion — already covered
% by `square_not_rectangle`. Add VdW-citation tier.

tier(ref(misconception, square_not_rectangle), 1, [source(vdw, agrees)],
    "VdW Ch. 20 pp. 523-524 explicitly: 'They may quite correctly list all the properties of a square, a rhombus, and a rectangle and still might classify a square as a nonrhombus or a nonrectangle.' Refines the existing BENNY tier.").

% =====================================================================
% Q-007 resolution (2026-05-04): five measurement-related concepts that
% had been parked here by the VdW digger have been migrated to their
% proper topic files:
%   - area_perimeter_distinction   → concepts/area_perimeter.pl
%   - area_as_surface_coverage     → concepts/area_perimeter.pl
%   - angle_size_attribute         → concepts/angles.pl
%   - height_vs_slanted_side       → concepts/angles.pl
%   - ruler_units_vs_marks         → concepts/measurement.pl (new)
% Their associated geom_misconception/6 and material_inference/4 records
% travelled with each concept. Tier records reference ConceptId only and
% remain valid post-move.
% =====================================================================

% =====================================================================
% Concept-ID anchors required by Van de Walle digger's van_hiele_marker/4
% and bootstrap/6 records. These would more naturally live in
% concepts/shape_recognition.pl (square_recognition, triangle_recognition,
% three_d_shape_recognition) and concepts/attributes.pl
% (quadrilateral_classification), but the digger is restricted to
% concepts/classification.pl. The synthesizer should move these to
% appropriate topic files.
% =====================================================================

geom_concept(square_recognition,
    "Recognizing and naming squares — visual recognition (level 0), property-listing (level 1), and class-inclusion (level 2)",
    shape_recognition,
    [0,1,2,3,4,5]).
tier(ref(concept, square_recognition), 1, [source(vdw, agrees)],
    "VdW Ch. 20. Concept proposed by VdW digger as the anchor for the canonical square-development arc across all five van Hiele levels. Proposed topic: shape_recognition.").

geom_concept(triangle_recognition,
    "Recognizing and naming triangles, including non-prototypical orientations and varied side/angle types",
    shape_recognition,
    [0,1,2,3,4,5]).
tier(ref(concept, triangle_recognition), 1, [source(vdw, agrees)],
    "VdW Ch. 20 p. 519. Includes the upside-down-triangle misconception. Proposed topic: shape_recognition.").

geom_concept(tilted_square_as_diamond,
    "Recognition that a square retains its identity under rotation; the 'diamond' label is informal, not mathematical",
    shape_recognition,
    [0,1,2,3]).
tier(ref(concept, tilted_square_as_diamond), 1, [source(vdw, agrees)],
    "VdW Ch. 20 p. 514. Proposed topic: shape_recognition.").

geom_concept(three_d_shape_recognition,
    "Recognizing and naming 3-D solids — sorting at level 0 by appearance, classifying at level 1 by face/edge properties",
    shape_recognition,
    [0,1,2,3,4,5,6]).
tier(ref(concept, three_d_shape_recognition), 1, [source(vdw, agrees)],
    "VdW Ch. 20 p. 521. Proposed topic: shape_recognition.").

geom_concept(rectangle_class,
    "The class of all rectangles, characterized by property lists at level 1 (parallelogram with a right angle; opposite sides parallel and equal; congruent diagonals)",
    classification,
    [1,2,3,4,5,6,7]).
tier(ref(concept, rectangle_class), 1, [source(vdw, agrees)],
    "VdW Ch. 20 p. 515. Class-of-shapes anchor for level-1 analysis of rectangles.").

geom_concept(cube_class,
    "The class of all cubes, characterized at level 1 by six congruent square faces and at level 2 by relationships between faces, edges, and vertices",
    classification,
    [1,2,3,4,5,6,7]).
tier(ref(concept, cube_class), 1, [source(vdw, agrees)],
    "VdW Ch. 20 p. 515. Class-of-shapes anchor for level-1 analysis of cubes.").

geom_concept(quadrilateral_classification,
    "Classifying quadrilaterals by properties (level 1), by relations among properties (level 2), and by definitions (level 3); the inclusive hierarchy view",
    classification,
    [3,4,5,6,7,8]).
tier(ref(concept, quadrilateral_classification), 1, [source(vdw, agrees)],
    "VdW Ch. 20 pp. 516-524. The level-1-to-3 work that organizes Activities 20.2, 20.3, 20.10, 20.12, 20.15.").

geom_concept(minimal_defining_list,
    "A minimal defining list (MDL) for a shape: a subset of its properties that is both DEFINING (any shape with all listed properties must be that shape) and MINIMAL (removing any property breaks definingness)",
    classification,
    [4,5,6,7,8]).
tier(ref(concept, minimal_defining_list), 1, [source(vdw, agrees)],
    "VdW Ch. 20 p. 517 (Activity 20.3). Anchor concept for level-2 work on definitions.").

geom_concept(triangle_angle_sum,
    "The triangle angle-sum theorem: the three angles of any triangle sum to 180 degrees (a straight line)",
    angles,
    [4,5,6,7,8]).
tier(ref(concept, triangle_angle_sum), 1, [source(vdw, agrees)],
    "VdW Activity 20.17 p. 531. Note: also exists as triangle_angle_sum_180 in concepts/angles.pl; synthesizer should reconcile (likely alias).").

geom_concept(diagonals_of_rectangles_proof,
    "Proving via deductive argument that the diagonals of a rectangle bisect each other — a level-3 understanding above level-2 awareness of the property",
    classification,
    [6,7,8]).
tier(ref(concept, diagonals_of_rectangles_proof), 1, [source(vdw, agrees)],
    "VdW Ch. 20 p. 517 names this as the canonical level-3 concept: 'a student operating at level 3 ... has an appreciation of the need to prove this from a series of deductive arguments.'").

geom_concept(polygon_recognition,
    "Recognizing and naming general polygons across all van Hiele levels — visual recognition (0), property-listing (1), if-then reasoning about properties (2), formal deduction (3), comparing axiomatic systems (4)",
    shape_recognition,
    [0,1,2,3,4,5,6,7,8]).
tier(ref(concept, polygon_recognition), 2,
    [source(vdw, agrees), source(van_hiele, agrees)],
    "Concept also referenced by the Van Hiele dissertation digger's level-0/1 markers in van_hiele/levels.pl. VdW digger uses it as a generic anchor for plane-figure activities. Synthesizer should canonicalize against the VH digger's preferred form.").

geom_concept(square_rectangle_classification,
    "The classification relationship between squares and rectangles — the canonical van Hiele example used to illustrate level-by-level thinking",
    classification,
    [3,4,5,6,7,8]).
tier(ref(concept, square_rectangle_classification), 2,
    [source(van_hiele, agrees), source(vdw, agrees)],
    "Anchor referenced by Van Hiele dissertation digger's level 0/1/2 markers in van_hiele/levels.pl. Triangulates with VdW p. 523-524.").

geom_concept(geometric_language,
    "Meta-concept: each van Hiele level has its own language — relations true at one level may be false at another",
    classification,
    [0,1,2,3,4,5,6,7,8]).
tier(ref(concept, geometric_language), 3, [source(van_hiele, agrees)],
    "Anchor referenced by Van Hiele dissertation digger's geometric_language markers across all five levels. Tier 3 because VdW does not name this meta-concept directly; van Hiele 1959 does.").

geom_concept(informal_deduction_with_parallels,
    "Level-2 reasoning that uses parallel-line theorems (the 'saw' and 'ladder' patterns) to deduce angle relationships — e.g., proving the triangle angle-sum theorem informally",
    angles,
    [5,6,7,8]).
tier(ref(concept, informal_deduction_with_parallels), 3, [source(van_hiele, agrees)],
    "Anchor referenced by Van Hiele dissertation digger's level-2 marker. Triangulates with VdW Activity 20.17 (Angle Sum in a Triangle, p. 531) but VH digger's framing is more specific.").

geom_concept(formal_deduction,
    "Level-3 reasoning about meta-properties of proofs: converse, axiom, necessary and sufficient conditions, logical ordering of theorems",
    classification,
    [7,8]).
tier(ref(concept, formal_deduction), 3, [source(van_hiele, agrees)],
    "Anchor referenced by Van Hiele dissertation digger's level-3 marker. VdW p. 517 mentions this in passing but VH dissertation develops it.").

geom_concept(axiom_system_comparison,
    "Level-4 reasoning about axiomatic systems themselves — comparing different axiom systems, identifying missing axioms in non-Euclidean geometries",
    classification,
    [8]).
tier(ref(concept, axiom_system_comparison), 3, [source(van_hiele, agrees)],
    "Anchor referenced by Van Hiele dissertation digger's level-4 marker. Out of K-8 scope; included for schema completeness.").
