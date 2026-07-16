% concepts/pythagoras.pl — geometry concepts in the pythagoras topic.
%
% Append clauses for: geom_concept/4, geom_misconception/6,
%                     material_inference/4, tier/4 (covering all of these).
% Cross-tagging (van_hiele_marker, metaphor_source, bootstrap,
% standard_anchor) lives in the corresponding subdirs.
%
% Schema: ../schema.pl

:- multifile geom_concept/4, geom_misconception/6, material_inference/4, tier/4.
:- discontiguous geom_concept/4, geom_misconception/6, material_inference/4, tier/4,
               pythagorean_material_claim/5.

%!  pythagorean_material_claim_witness(+Id, -Witness) is semidet.
%
%   Inspectable proof object for a finite Pythagorean curriculum material row.
pythagorean_material_claim_witness(Id, Witness) :-
    pythagorean_material_claim(Id, Concept, Premise, Conclusion, Polarity),
    pythagorean_primary_tier(Concept, Tier, Sources, SourceNote, TierEvidence),
    pythagorean_related_misconception_witnesses(Concept,
                                                MisconceptionWitnesses),
    pythagorean_condition_roles(Id, Roles),
    Witness = _{ kind: geometry_pythagorean_material_inference,
                 scope: closed_world_finite_pythagorean_table,
                 id: Id,
                 concept: Concept,
                 premise: Premise,
                 conclusion: Conclusion,
                 polarity: Polarity,
                 tier: Tier,
                 sources: Sources,
                 source_note: SourceNote,
                 tier_evidence: TierEvidence,
                 boundary: finite_pythagorean_curriculum_claim_not_general_metric_geometry,
                 condition_roles: Roles,
                 related_misconception_witnesses: MisconceptionWitnesses,
                 fact: material_inference(Concept, Premise, Conclusion, Polarity) }.

pythagorean_primary_tier(Concept, Tier, Sources, SourceNote, TierEvidence) :-
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

pythagorean_related_misconception_witnesses(Concept, Witnesses) :-
    findall(Witness,
            pythagorean_misconception_witness(Concept, Witness),
            RawWitnesses),
    sort(RawWitnesses, Witnesses).

pythagorean_misconception_witness(Concept,
    _{ kind: geometry_pythagorean_misconception_support,
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

pythagorean_condition_roles(pythagorean_side_equation,
                            [ _{ kind: sufficiency_component,
                                 role: right_triangle_condition },
                              _{ kind: sufficiency_component,
                                 role: hypotenuse_identified },
                              _{ kind: sufficiency_component,
                                 role: leg_lengths_identified }
                            ]) :-
    !.
pythagorean_condition_roles(converse_pythagorean_equality_test,
                            [ _{ kind: sufficiency_component,
                                 role: largest_side_identified },
                              _{ kind: sufficiency_component,
                                 role: side_square_equality }
                            ]) :-
    !.
pythagorean_condition_roles(converse_pythagorean_inequality_test,
                            [ _{ kind: incompatibility_component,
                                 role: largest_side_identified },
                              _{ kind: incompatibility_component,
                                 role: side_square_inequality }
                            ]) :-
    !.
pythagorean_condition_roles(pythagorean_hypotenuse_application,
                            [ _{ kind: necessary_condition,
                                 role: hypotenuse_identified }
                            ]) :-
    !.
pythagorean_condition_roles(pythagorean_rejects_non_side_quantity,
                            [ _{ kind: incompatibility_component,
                                 role: theorem_relates_side_lengths_not_area_perimeter_or_volume }
                            ]) :-
    !.
pythagorean_condition_roles(constructed_right_triangle_over_visible_right_angle,
                            [ _{ kind: possibility_component,
                                 role: auxiliary_right_triangle_can_be_constructed }
                            ]) :-
    !.
pythagorean_condition_roles(special_30_60_90_over_right_triangle,
                            [ _{ kind: sufficiency_component,
                                 role: thirty_sixty_ninety_angle_structure },
                              _{ kind: sufficiency_component,
                                 role: short_leg_identified }
                            ]) :-
    !.
pythagorean_condition_roles(special_45_45_90_over_right_triangle,
                            [ _{ kind: sufficiency_component,
                                 role: forty_five_forty_five_ninety_angle_structure },
                              _{ kind: sufficiency_component,
                                 role: leg_length_identified }
                            ]) :-
    !.
pythagorean_condition_roles(_, []).

material_inference(Concept, Premise, Conclusion, Polarity) :-
    pythagorean_material_claim_witness(_Id, Witness),
    get_dict(fact, Witness, material_inference(Concept,
                                               Premise,
                                               Conclusion,
                                               Polarity)).

% =====================================================================
% N103 (Aichele & Wolfe 2008) — Chapter 8
% =====================================================================

geom_concept(pythagorean_theorem,
    "For a right triangle with legs a and b and hypotenuse c: a^2 + b^2 = c^2",
    pythagoras,
    [7,8]).

tier(ref(concept, pythagorean_theorem), 1,
     [n103_ch8, ccss_8g6, ccss_8g7],
     "N103 Chapter 8. The visual statement (areas of squares on the legs sum to the area of the square on the hypotenuse) precedes the algebraic statement.").

pythagorean_material_claim(pythagorean_side_equation,
    pythagorean_theorem,
    "triangle has legs of length a and b and hypotenuse of length c AND triangle is a right triangle",
    "a^2 + b^2 = c^2",
    entitled).

geom_concept(right_triangle_of_squares,
    "A right triangle with squares constructed on each of its three sides; visual model for the Pythagorean theorem (the area of the largest square equals the sum of the areas of the two smaller squares)",
    pythagoras,
    [6,7,8]).

tier(ref(concept, right_triangle_of_squares), 3,
     [n103_ch8],
     "N103 Activity 8.1. N103-specific framing — the geoboard-friendly visual that motivates the theorem before the algebra. Alias: 'Pythagorean square diagram'.").

geom_concept(converse_of_pythagorean_theorem,
    "If the side lengths of a triangle satisfy a^2 + b^2 = c^2, then the triangle is a right triangle",
    pythagoras,
    [7,8]).

tier(ref(concept, converse_of_pythagorean_theorem), 1,
     [n103_ch8, ccss_8g6],
     "N103 Big Idea (Chapter 8). Used as a *test* for whether a triangle is right.").

pythagorean_material_claim(converse_pythagorean_equality_test,
    converse_of_pythagorean_theorem,
    "triangle has sides of length a, b, c (with c the largest) AND a^2 + b^2 = c^2",
    "the triangle is a right triangle",
    entitled).

pythagorean_material_claim(converse_pythagorean_inequality_test,
    converse_of_pythagorean_theorem,
    "triangle has sides of length a, b, c (with c the largest) AND a^2 + b^2 != c^2",
    "the triangle is NOT a right triangle",
    entitled).

geom_concept(slant_length_on_geoboard,
    "The length of a slanted (non-axis-aligned) segment on a geoboard; can be computed by Pythagoras or by finding the area of the square built on the segment",
    pythagoras,
    [6,7,8]).

tier(ref(concept, slant_length_on_geoboard), 3,
     [n103_ch8],
     "N103 Activity 8.4. N103-specific term ('slant length').").

geom_concept(isosceles_right_triangle,
    "A right triangle with two equal legs; equivalently, half of a square cut along its diagonal",
    pythagoras,
    [6,7,8]).

tier(ref(concept, isosceles_right_triangle), 1,
     [n103_ch8],
     "N103 Activity 8.6. One of N103's 'three special triangles'.").

geom_concept(thirty_sixty_ninety_triangle,
    "A right triangle with angles 30, 60, and 90 degrees; equivalently, half of an equilateral triangle cut along an altitude",
    pythagoras,
    [7,8]).

tier(ref(concept, thirty_sixty_ninety_triangle), 1,
     [n103_ch8],
     "N103 Activity 8.6. The most important property: the hypotenuse is twice the short leg. One of N103's 'three special triangles'.").

geom_concept(equilateral_triangle,
    "A triangle with all three sides equal (equivalently, all three angles equal to 60 degrees)",
    pythagoras,
    [4,5,6,7,8]).

tier(ref(concept, equilateral_triangle), 1,
     [n103_ch1, n103_ch8],
     "N103 Activity 1.4 names; Activity 8.6 lists as one of three special triangles.").

pythagorean_material_claim(special_30_60_90_over_right_triangle,
    thirty_sixty_ninety_triangle,
    "triangle is a 30-60-90 right triangle with short leg of length s",
    "the hypotenuse has length 2s and the long leg has length s*sqrt(3)",
    entitled).

pythagorean_material_claim(special_45_45_90_over_right_triangle,
    isosceles_right_triangle,
    "triangle is a 45-45-90 right triangle with leg of length s",
    "the hypotenuse has length s*sqrt(2)",
    entitled).

% =====================================================================
% Research-corpus harvest (misconception_harvester) — appended below
% =====================================================================

:- multifile triangulation/2.
:- discontiguous triangulation/2.

% --- corpus_37755: right triangle without longest side
geom_misconception(
    right_triangle_without_longest_side,
    pythagorean_theorem,
    "Right triangle drawn or assumed without identifying the longest side as hypotenuse",
    [ "any side could be the hypotenuse",
      "the right triangle doesn't need a longest side",
      "I picked any side for c" ],
    "In a right triangle, the side opposite the right angle is the hypotenuse and is always the longest. The Pythagorean theorem applies as a² + b² = c² with c the hypotenuse — so c must be the side opposite the right angle. Identify the right angle first, then label the opposite side as c.",
    [corpus_37755]).

tier(ref(misconception, right_triangle_without_longest_side), 3,
     [corpus_37755], "single-source corpus row 37755").

% --- corpus_40244: 'Pythagorean pattern' applied to area of right triangle, not Pythagoras
geom_misconception(
    pythagorean_pattern_misapplied,
    pythagorean_theorem,
    "Misapplied 'Pythagorean pattern' — finding the area of a right triangle (or other quantity) where the theorem doesn't apply",
    [ "I used the Pythagorean pattern for the area",
      "Pythagoras gives the area of the triangle",
      "I applied a² + b² = c² to find something else" ],
    "The Pythagorean theorem relates the *side lengths* of a right triangle (specifically, the squares of the legs sum to the square of the hypotenuse). It doesn't compute area, perimeter, or any other quantity directly. Confirm that the question is about the relationship between the three sides of a right triangle before invoking it.",
    [corpus_40244]).

tier(ref(misconception, pythagorean_pattern_misapplied), 3,
     [corpus_40244], "single-source corpus row 40244").

% --- corpus_38249: trigonometry requires explicit right angle
geom_misconception(
    trig_only_with_explicit_right_angle,
    pythagorean_theorem,
    "Trigonometric reasoning believed to require a literal right angle drawn in the figure",
    [ "I can't use trig because there's no right angle",
      "you need a right triangle in the picture",
      "no right angle means no Pythagoras either" ],
    "Right triangles can be *constructed* by dropping a perpendicular (e.g., the altitude of a non-right triangle), then trigonometric and Pythagorean reasoning becomes available on the constructed pieces. Don't restrict yourself to figures where the right angle is already drawn.",
    [corpus_38249]).

tier(ref(misconception, trig_only_with_explicit_right_angle), 3,
     [corpus_38249], "single-source corpus row 38249").

% --- material inferences from harvest ---

pythagorean_material_claim(pythagorean_hypotenuse_application,
    pythagorean_theorem,
    "the longest side of a right triangle is identified as the hypotenuse",
    "the Pythagorean theorem applies as (leg1)² + (leg2)² = (hypotenuse)²",
    entitled).

pythagorean_material_claim(pythagorean_rejects_non_side_quantity,
    pythagorean_theorem,
    "I am computing area, perimeter, or volume of a right triangle",
    "the Pythagorean theorem provides the answer directly",
    incompatible).

pythagorean_material_claim(constructed_right_triangle_over_visible_right_angle,
    pythagorean_theorem,
    "the figure does not show an explicit right angle",
    "Pythagorean reasoning is unavailable in any subfigure",
    incompatible).
