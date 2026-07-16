% concepts/shape_recognition.pl — geometry concepts in the shape_recognition topic.
%
% Append clauses for: geom_concept/4, geom_misconception/6,
%                     material_inference/4, tier/4 (covering all of these).
% Cross-tagging (van_hiele_marker, metaphor_source, bootstrap,
% standard_anchor) lives in the corresponding subdirs.
%
% Schema: ../schema.pl

:- multifile geom_concept/4, geom_misconception/6, material_inference/4, tier/4.
:- discontiguous geom_concept/4, geom_misconception/6, material_inference/4, tier/4,
               shape_recognition_material_claim/5.
:- multifile triangulation/2.
:- discontiguous triangulation/2.

%!  shape_recognition_material_claim_witness(+Id, -Witness) is semidet.
%
%   Inspectable proof object for a finite shape-recognition material row.
shape_recognition_material_claim_witness(Id, Witness) :-
    shape_recognition_material_claim(Id, Concept, Premise, Conclusion, Polarity),
    shape_recognition_concept_tier_evidence(Concept,
                                            ConceptTierBoundary,
                                            ConceptTierEvidence),
    shape_recognition_related_misconception_witnesses(
        Concept,
        MisconceptionWitnesses
    ),
    shape_recognition_condition_roles(Id, Roles),
    Witness = _{ kind: geometry_shape_recognition_material_inference,
                 scope: closed_world_finite_shape_recognition_table,
                 id: Id,
                 concept: Concept,
                 premise: Premise,
                 conclusion: Conclusion,
                 polarity: Polarity,
                 concept_tier_boundary: ConceptTierBoundary,
                 concept_tier_evidence: ConceptTierEvidence,
                 boundary: finite_shape_recognition_curriculum_claim_not_general_visual_classifier,
                 condition_roles: Roles,
                 related_misconception_witnesses: MisconceptionWitnesses,
                 fact: material_inference(Concept, Premise, Conclusion, Polarity) }.

shape_recognition_concept_tier_evidence(Concept,
                                        loaded_concept_tier_record,
                                        TierEvidence) :-
    findall(_{ tier: Tier,
               sources: Sources,
               source_note: SourceNote },
            tier(ref(concept, Concept), Tier, Sources, SourceNote),
            TierEvidence),
    TierEvidence \== [],
    !.
shape_recognition_concept_tier_evidence(_Concept,
                                        no_concept_tier_record_in_loaded_geometry_schema,
                                        []).

shape_recognition_related_misconception_witnesses(Concept, Witnesses) :-
    findall(Witness,
            shape_recognition_misconception_witness(Concept, Witness),
            RawWitnesses),
    sort(RawWitnesses, Witnesses).

shape_recognition_misconception_witness(Concept,
    _{ kind: geometry_shape_recognition_misconception_support,
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

shape_recognition_condition_roles(property_classification_over_visual,
                                  [ _{ kind: sufficiency_component,
                                       role: property_test_satisfied },
                                    _{ kind: invariance_component,
                                       role: orientation_does_not_change_category }
                                  ]) :-
    !.
shape_recognition_condition_roles(property_classification_rejects_orientation,
                                  [ _{ kind: incompatibility_component,
                                       role: orientation_is_not_a_defining_property },
                                    _{ kind: invariance_component,
                                       role: category_properties_survive_rotation }
                                  ]) :-
    !.
shape_recognition_condition_roles(circle_definition_rejects_roundness_only,
                                  [ _{ kind: necessary_condition_missing,
                                       role: fixed_distance_from_center },
                                    _{ kind: insufficiency_component,
                                       role: visual_roundness_only }
                                  ]) :-
    !.
shape_recognition_condition_roles(formal_object_over_physical_drawing,
                                  [ _{ kind: incompatibility_component,
                                       role: physical_drawing_properties_do_not_enter_formal_object_definition }
                                  ]) :-
    !.
shape_recognition_condition_roles(triangle_definition_over_visual_category,
                                  [ _{ kind: sufficiency_component,
                                       role: three_straight_sides },
                                    _{ kind: sufficiency_component,
                                       role: closed_figure }
                                  ]) :-
    !.
shape_recognition_condition_roles(_, []).

material_inference(Concept, Premise, Conclusion, Polarity) :-
    shape_recognition_material_claim_witness(_Id, Witness),
    get_dict(fact, Witness, material_inference(Concept,
                                               Premise,
                                               Conclusion,
                                               Polarity)).

% =====================================================================
% Concepts (Van Hiele level 0/1 territory — visual recognition)
% =====================================================================

geom_concept(shape_identified_by_properties_not_appearance,
    "A shape is identified by its mathematical properties (number of sides, parallelism, angles), not by its visual prototype",
    shape_recognition,
    [0,1,2,3,4,5]).

geom_concept(circle_definition,
    "A circle is the set of all points equidistant from a center; not merely a 'round' visual shape",
    shape_recognition,
    [3,4,5,6,7]).

geom_concept(triangle_definition,
    "A triangle is a closed figure with three straight sides; orientation, side lengths, and angle types are not part of the definition",
    shape_recognition,
    [1,2,3,4,5]).

geom_concept(formal_vs_physical_geometric_object,
    "Geometric points, lines, and circles are abstract objects with idealized properties (no width, no thickness, perfect precision); their physical drawings are approximations",
    shape_recognition,
    [4,5,6,7,8]).

% =====================================================================
% Tier 2/3 — research-corpus harvested misconceptions
% =====================================================================

% --- corpus_38067 / 39873 (children restrict triangle to prototype, horizontal base)
geom_misconception(
    triangle_only_prototype,
    triangle_definition,
    "Triangle restricted to prototypical shape (isosceles or equilateral with horizontal base)",
    [ "this isn't a triangle, it's pointing the wrong way",
      "triangles have a flat side on the bottom",
      "scalene triangles aren't really triangles" ],
    "Triangle = three straight sides forming a closed figure. Orientation, leg lengths, and angle types (acute, right, obtuse) are all free. Practice with rotated, scalene, and obtuse examples; let the property test (count sides, check closure) settle the question.",
    [corpus_38067, corpus_39873, corpus_38891]).

tier(ref(misconception, triangle_only_prototype), 2,
     [corpus_38067, corpus_39873, corpus_38891],
     "research corpus — multi-source on prototype restriction for triangles").

triangulation(ref(misconception, triangle_only_prototype),
    [ source(corpus_38067, agrees),
      source(corpus_39873, agrees),
      source(corpus_38891, agrees) ]).

% --- corpus_37754 / 40566: square in non-standard orientation
geom_misconception(
    diamond_not_recognized_as_square,
    shape_identified_by_properties_not_appearance,
    "Tilted square (diamond) refused as a square",
    [ "that's a diamond, not a square",
      "if it's tilted it's not a square",
      "squares have flat tops and bottoms" ],
    "Rotate the figure mentally. Count sides (four), measure side lengths (equal), check angles (right). All four are invariant under rotation. The 'diamond' shape is a square at 45 degrees.",
    [corpus_37754, corpus_40566]).

tier(ref(misconception, diamond_not_recognized_as_square), 2,
     [corpus_37754, corpus_40566],
     "research corpus — orientation-prototype rejection of tilted square").

triangulation(ref(misconception, diamond_not_recognized_as_square),
    [ source(corpus_37754, agrees),
      source(corpus_40566, agrees) ]).

% --- corpus_38891: shape refused in non-standard orientation
geom_misconception(
    shape_refused_in_nonstandard_orientation,
    shape_identified_by_properties_not_appearance,
    "Geometric shape refused outright when shown in non-standard orientation",
    [ "this isn't a triangle the way it's shown",
      "you can't call it that when it's tilted",
      "shapes have to be in their normal position" ],
    "The defining properties of a shape are invariant under rotation, reflection, and translation. Always check the *properties*, not the orientation: number of sides, parallelism, angle measures. Practice with shapes shown at many angles to break the orientation-locked prototype.",
    [corpus_38891]).

tier(ref(misconception, shape_refused_in_nonstandard_orientation), 3,
     [corpus_38891], "single-source corpus row 38891").

% --- corpus_38802 / 38803 / 38804 / 40205: phenomenological circle definitions
geom_misconception(
    circle_as_round_thing_only,
    circle_definition,
    "Circle defined by visual roundness or by physical templates rather than by equidistance from center",
    [ "circles are round things",
      "a circle is a shape like the moon",
      "you have to use a tracer to make a real circle" ],
    "A circle is mathematically defined as the set of all points at a fixed distance (the radius) from a fixed point (the center). Roundness alone isn't enough — an oval is round but not a circle. The radius constraint is what makes a curve a circle. The compass construction enacts the definition: keep the radius fixed.",
    [corpus_38802, corpus_38803, corpus_38804, corpus_40205]).

tier(ref(misconception, circle_as_round_thing_only), 2,
     [corpus_38802, corpus_38803, corpus_38804, corpus_40205],
     "research corpus — multi-source on phenomenological circle definitions").

triangulation(ref(misconception, circle_as_round_thing_only),
    [ source(corpus_38802, agrees),
      source(corpus_38803, agrees),
      source(corpus_38804, agrees),
      source(corpus_40205, agrees) ]).

% --- corpus_37611 / 38191: idealized vs physical geometric objects
geom_misconception(
    geometric_object_must_be_physical,
    formal_vs_physical_geometric_object,
    "Abstract geometric objects (points, lines) refused as 'real' if they have no physical width or substance",
    [ "if a dot has no size, then it isn't anything",
      "lines have to have some thickness",
      "points are dots with width" ],
    "Geometric points, lines, and circles are *abstract* objects defined by properties — points have location but no extent, lines have length but no width. Physical drawings are approximations whose imperfections we agree to ignore. The mathematics works on the idealized object, not the drawing.",
    [corpus_37611, corpus_38191]).

tier(ref(misconception, geometric_object_must_be_physical), 2,
     [corpus_37611, corpus_38191],
     "research corpus — multi-source on physical-idealization confusion").

triangulation(ref(misconception, geometric_object_must_be_physical),
    [ source(corpus_37611, agrees),
      source(corpus_38191, agrees) ]).

% --- corpus_38912: tetrahedron called triangle (2D/3D conflation)
geom_misconception(
    tetrahedron_called_triangle,
    shape_identified_by_properties_not_appearance,
    "Three-dimensional solid (tetrahedron) called by two-dimensional name (triangle)",
    [ "the tetrahedron is a triangle with four sides",
      "this 3D shape is a triangle",
      "I see triangles so it's a triangle" ],
    "A triangle is a 2D shape (three sides, lying in a plane). A tetrahedron is a 3D solid bounded by four triangular faces. The word 'side' shifts meaning between dimensions: in 2D it means edge; in 3D it means face. Use 'face' for 3D bounding pieces.",
    [corpus_38912]).

tier(ref(misconception, tetrahedron_called_triangle), 3,
     [corpus_38912], "single-source corpus row 38912").

% --- corpus_38892: general triangle vs specific drawn one
geom_misconception(
    specific_drawing_taken_for_general,
    shape_identified_by_properties_not_appearance,
    "Specific drawn instance of a shape conflated with the general concept",
    [ "this triangle has these specific angles, so all triangles do",
      "in the diagram it's right-angled, so the shape is right-angled",
      "I see what's drawn, so that's the shape" ],
    "A drawn diagram represents a *general* concept, not just a specific case — the diagram is one realization. Avoid relying on incidental features (the particular orientation, the particular side lengths) when stating properties of 'the shape'. Test reasoning across multiple instantiations.",
    [corpus_38892, corpus_39144]).

tier(ref(misconception, specific_drawing_taken_for_general), 3,
     [corpus_38892, corpus_39144], "two-source").

% =====================================================================
% Material inferences
% =====================================================================

shape_recognition_material_claim(property_classification_over_visual,
    shape_identified_by_properties_not_appearance,
    "shape S satisfies the property test for category C in any orientation",
    "S is in category C",
    entitled).

shape_recognition_material_claim(property_classification_rejects_orientation,
    shape_identified_by_properties_not_appearance,
    "shape S is shown in a non-prototypical orientation",
    "S is not in its category",
    incompatible).

shape_recognition_material_claim(circle_definition_rejects_roundness_only,
    circle_definition,
    "the curve is round and has no straight pieces",
    "the curve is a circle",
    incompatible).

shape_recognition_material_claim(formal_object_over_physical_drawing,
    formal_vs_physical_geometric_object,
    "the geometric object I drew has measurable thickness",
    "the geometric object itself has thickness in its mathematical definition",
    incompatible).

shape_recognition_material_claim(triangle_definition_over_visual_category,
    triangle_definition,
    "the figure has three straight sides and is closed",
    "the figure is a triangle",
    entitled).
