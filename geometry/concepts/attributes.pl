% concepts/attributes.pl — geometry concepts in the attributes topic.
%
% Append clauses for: geom_concept/4, geom_misconception/6,
%                     material_inference/4, tier/4 (covering all of these).
% Cross-tagging (van_hiele_marker, metaphor_source, bootstrap,
% standard_anchor) lives in the corresponding subdirs.
%
% Schema: ../schema.pl

:- multifile geom_concept/4, geom_misconception/6, material_inference/4, tier/4.
:- discontiguous geom_concept/4, geom_misconception/6, material_inference/4, tier/4,
               attribute_material_claim/5.
:- multifile triangulation/2.
:- discontiguous triangulation/2.

%!  attribute_material_claim_witness(+Id, -Witness) is semidet.
%
%   Inspectable proof object for a finite attributes material-inference row.
attribute_material_claim_witness(Id, Witness) :-
    attribute_material_claim(Id, Concept, Premise, Conclusion, Polarity),
    attribute_related_misconception_witnesses(Concept, MisconceptionWitnesses),
    attribute_condition_roles(Id, Roles),
    Witness = _{ kind: geometry_attribute_material_inference,
                 scope: closed_world_finite_geometry_attributes_table,
                 id: Id,
                 concept: Concept,
                 premise: Premise,
                 conclusion: Conclusion,
                 polarity: Polarity,
                 support_status: material_row_with_related_misconception_support,
                 boundary: finite_attribute_material_row_not_general_proof_theory,
                 condition_roles: Roles,
                 related_misconception_witnesses: MisconceptionWitnesses,
                 fact: material_inference(Concept, Premise, Conclusion, Polarity) }.

%!  attribute_material_inference_witness(+Concept, +Premise, +Conclusion,
%!                                       +Polarity, -Witness) is semidet.
%
%   Lookup witness by the legacy material_inference/4 projection.
attribute_material_inference_witness(Concept,
                                     Premise,
                                     Conclusion,
                                     Polarity,
                                     Witness) :-
    attribute_material_claim(Id, Concept, Premise, Conclusion, Polarity),
    attribute_material_claim_witness(Id, Witness).

attribute_related_misconception_witnesses(Concept, Witnesses) :-
    findall(Witness,
            attribute_misconception_witness(Concept, Witness),
            RawWitnesses),
    sort(RawWitnesses, Witnesses).

attribute_misconception_witness(Concept,
    _{ kind: geometry_attribute_misconception_support,
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

attribute_condition_roles(definition_validity,
                          [ _{ kind: necessary_condition,
                               role: every_example_satisfies_condition },
                            _{ kind: sufficient_condition,
                               role: every_shape_satisfying_condition_is_in_category }
                          ]) :-
    !.
attribute_condition_roles(_, []).

material_inference(Concept, Premise, Conclusion, Polarity) :-
    attribute_material_claim(_Id, Concept, Premise, Conclusion, Polarity).

% =====================================================================
% Concepts — attributes that distinguish or constitute shapes
% =====================================================================

geom_concept(definition_requires_necessary_and_sufficient_conditions,
    "A mathematical definition must give conditions that are both necessary (every example satisfies them) and sufficient (everything satisfying them is an example)",
    attributes,
    [4,5,6,7,8]).

geom_concept(parallelism_as_constant_distance,
    "Two lines are parallel iff they maintain a constant perpendicular distance and never meet",
    attributes,
    [4,5,6,7]).

geom_concept(equal_sides_does_not_imply_equal_angles,
    "For polygons with more than three sides, equal sides do not imply equal angles (and vice versa)",
    attributes,
    [5,6,7,8]).

geom_concept(perpendicularity_as_right_angle,
    "Two lines are perpendicular iff they meet at a right angle",
    attributes,
    [3,4,5,6,7]).

% =====================================================================
% Tier 2/3 — research-corpus harvested misconceptions
% =====================================================================

% --- corpus_39508 (multi: equal sides imply equal angles in hexagon)
geom_misconception(
    equal_sides_imply_equal_angles,
    equal_sides_does_not_imply_equal_angles,
    "Equal sides assumed to imply equal angles in a polygon (overgeneralizing from triangles)",
    [ "all sides equal means all angles equal",
      "if the hexagon has equal sides it must be regular",
      "equal sides means regular polygon" ],
    "For triangles, equal sides do imply equal angles (isosceles theorem). For polygons with four or more sides, this fails: a rhombus has all four sides equal but generally has two distinct angle measures; a non-regular hexagon can have all six sides equal yet have varying angles. Both conditions (equal sides AND equal angles) are needed for regularity.",
    [corpus_39508]).

tier(ref(misconception, equal_sides_imply_equal_angles), 3,
     [corpus_39508], "single-source corpus row 39508").

% --- corpus_38807: parallel lines 'equal length' vs 'equidistant'
geom_misconception(
    parallel_as_equal_length,
    parallelism_as_constant_distance,
    "Parallel lines characterized by equal length rather than constant distance",
    [ "parallel lines are equal in length",
      "if they're the same length they're parallel",
      "you measure parallelism by length" ],
    "Parallelism is about *direction* and *distance between* the lines, not about the length of the lines themselves. Two segments of very different lengths can be parallel; two equal-length segments can be skew or intersecting. Test parallelism by checking whether the perpendicular distance between the lines stays constant.",
    [corpus_38807]).

tier(ref(misconception, parallel_as_equal_length), 3,
     [corpus_38807], "single-source corpus row 38807").

% --- corpus_39144 (Kospentaris): visual perpendicularity assumption
geom_misconception(
    perpendicularity_assumed_from_diagram,
    perpendicularity_as_right_angle,
    "Perpendicularity assumed from visual diagram alone, without confirmation",
    [ "it looks perpendicular so it is",
      "the diagram shows them at right angles, that's enough",
      "I treated them as perpendicular because they appeared so" ],
    "Diagrams are illustrative, not authoritative. Always confirm perpendicularity by an explicit reason: marked right angle, given in the problem, or proven from other constraints. Visual right-angle-ness is unreliable, especially with hand-drawn or rotated figures.",
    [corpus_39144, corpus_38329, corpus_39760]).

tier(ref(misconception, perpendicularity_assumed_from_diagram), 2,
     [corpus_39144, corpus_38329, corpus_39760],
     "research corpus — multi-source on visual-evidence-as-proof").

triangulation(ref(misconception, perpendicularity_assumed_from_diagram),
    [ source(kospentaris_2011, agrees),
      source(corpus_38329, agrees),
      source(corpus_39760, agrees) ]).

% --- corpus_37729 / 39874 (definitions overly restrictive or wrong)
geom_misconception(
    definition_via_inessential_features,
    definition_requires_necessary_and_sufficient_conditions,
    "Definition stated via inessential features (orientation, prototype appearance, examples)",
    [ "a square is a shape with a flat top",
      "a rectangle is what you get from a piece of paper",
      "a triangle is when you draw three lines" ],
    "A mathematical definition must capture exactly the right examples and exclude all non-examples. Test the candidate definition: does it admit the wrong shapes (over-broad)? Does it exclude legitimate shapes (over-restrictive)? Refine until both cases settle correctly. Inessential features (orientation, drawing tool, color) belong nowhere in a definition.",
    [corpus_37729, corpus_39874]).

tier(ref(misconception, definition_via_inessential_features), 2,
     [corpus_37729, corpus_39874],
     "research corpus — over/under-specification of definitions").

triangulation(ref(misconception, definition_via_inessential_features),
    [ source(corpus_37729, agrees),
      source(corpus_39874, agrees) ]).

% --- corpus_38329 / 38010 / 39760: empirical-as-proof
geom_misconception(
    empirical_check_as_proof,
    definition_requires_necessary_and_sufficient_conditions,
    "Visual or empirical check accepted as a deductive proof",
    [ "I measured it and it works, so it's proven",
      "the diagram shows it, so it's true",
      "trying a few examples is enough" ],
    "A proof requires a deductive argument from definitions and prior theorems. Empirical evidence (measuring with a ruler, drawing examples) is suggestive but not a proof — the property may hold in cases you tested but fail elsewhere. Construct a chain of logical steps that doesn't depend on any specific instance.",
    [corpus_37724, corpus_38329, corpus_39760, corpus_39579]).

tier(ref(misconception, empirical_check_as_proof), 2,
     [corpus_37724, corpus_38329, corpus_39760, corpus_39579],
     "research corpus — multi-source on empirical-vs-deductive proof").

triangulation(ref(misconception, empirical_check_as_proof),
    [ source(corpus_37724, agrees),
      source(corpus_38329, agrees),
      source(corpus_39760, agrees),
      source(corpus_39579, agrees) ]).

% =====================================================================
% Material inferences
% =====================================================================

attribute_material_claim(equal_sides_not_angle_equality,
    equal_sides_does_not_imply_equal_angles,
    "polygon P has more than 3 sides AND all sides of P are equal",
    "all angles of P are equal",
    incompatible).

attribute_material_claim(definition_validity,
    definition_requires_necessary_and_sufficient_conditions,
    "every example of category C satisfies condition D AND every shape satisfying D is in C",
    "D is a valid definition of C",
    entitled).

attribute_material_claim(empirical_check_not_general_proof,
    definition_requires_necessary_and_sufficient_conditions,
    "I checked a few examples and the property held",
    "the property holds in general",
    incompatible).

attribute_material_claim(equal_length_not_parallel,
    parallelism_as_constant_distance,
    "two segments have equal length",
    "the segments are parallel",
    incompatible).

attribute_material_claim(visual_perpendicularity_not_proof,
    perpendicularity_as_right_angle,
    "two lines look perpendicular in the diagram",
    "the two lines are perpendicular",
    incompatible).
