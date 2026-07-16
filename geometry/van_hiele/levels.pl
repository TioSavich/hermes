% van_hiele/levels.pl — canonical level descriptors with kid-talk markers.
% Schema: ../schema.pl

:- multifile van_hiele_marker/4, tier/4, triangulation/2.
:- discontiguous van_hiele_marker/4, tier/4, triangulation/2.

%!  van_hiele_marker_witness(+ConceptId, +Level, -Witness) is semidet.
%
%   Inspectable witness for one marker row in the closed-world finite Van Hiele
%   marker table authored in this file. This proves table membership and local
%   tier evidence; it is not a general developmental diagnosis for a student.
van_hiele_marker_witness(ConceptId, Level, Witness) :-
    van_hiele_marker_fact(ConceptId, Level, MarkerPhrases, Citation),
    van_hiele_marker_tier_fact(ConceptId,
                               Level,
                               Tier,
                               Sources,
                               SourceNote),
    maplist(van_hiele_marker_source_witness, Sources, SourceWitnesses),
    van_hiele_marker_triangulation_evidence(ConceptId,
                                            Level,
                                            TriangulationBoundary,
                                            TriangulationEvidence),
    Witness = _{ kind: geometry_van_hiele_marker,
                 scope: closed_world_finite_van_hiele_levels_marker_table,
                 concept: ConceptId,
                 level: Level,
                 marker_phrases: MarkerPhrases,
                 citation: Citation,
                 tier: Tier,
                 sources: Sources,
                 source_witnesses: SourceWitnesses,
                 source_note: SourceNote,
                 triangulation_boundary: TriangulationBoundary,
                 triangulation_evidence: TriangulationEvidence,
                 boundary: finite_van_hiele_marker_table_not_general_developmental_diagnosis,
                 fact: van_hiele_marker(ConceptId,
                                        Level,
                                        MarkerPhrases,
                                        Citation) }.

van_hiele_marker_fact(ConceptId, Level, MarkerPhrases, Citation) :-
    Clause = van_hiele_marker(ConceptId, Level, MarkerPhrases, Citation),
    clause(Clause, true, Ref),
    clause_property(Ref, file(File)),
    sub_atom(File, _, _, _, 'geometry/van_hiele/levels.pl').

van_hiele_marker_tier_fact(ConceptId, Level, Tier, Sources, SourceNote) :-
    Clause = tier(ref(van_hiele, ConceptId, Level), Tier, Sources, SourceNote),
    clause(Clause, true, Ref),
    clause_property(Ref, file(File)),
    sub_atom(File, _, _, _, 'geometry/van_hiele/levels.pl').

van_hiele_marker_source_witness(source(Source, Agreement),
    _{ kind: source_agreement,
       source: Source,
       agreement: Agreement }) :-
    !.
van_hiele_marker_source_witness(Source,
    _{ kind: source_reference,
       source: Source }).

van_hiele_marker_triangulation_evidence(ConceptId,
                                        Level,
                                        loaded_triangulation_record,
                                        Evidence) :-
    findall(_{ agreement: Agreement,
               fact: triangulation(ref(van_hiele, ConceptId, Level),
                                   Agreement) },
            ( Clause = triangulation(ref(van_hiele, ConceptId, Level),
                                     Agreement),
              clause(Clause, true, Ref),
              clause_property(Ref, file(File)),
              sub_atom(File, _, _, _, 'geometry/van_hiele/levels.pl')
            ),
            RawEvidence),
    sort(RawEvidence, Evidence),
    Evidence \== [],
    !.
van_hiele_marker_triangulation_evidence(_ConceptId,
                                        _Level,
                                        no_loaded_triangulation_record,
                                        []).

% =============================================================================
% Records contributed by the Van Hiele Dissertation digger (2026-05-03)
% Source: Fuys-VanHieleModel-1988.pdf (NotebookLM "Geometry and Pedagogy" nb).
% Backing corpus: ../corpus/van_hiele_dissertation_excerpts.md
%
% Concept IDs are proposals; the synthesizer canonicalizes. The Van de Walle
% digger may also contribute van_hiele_marker/4 records under the same concept
% IDs — that's expected; multifile/discontiguous handles it.
% =============================================================================

% ── square / rectangle classification — the canonical van Hiele example ─────
%
% This is the example van Hiele himself uses repeatedly: how a level-0 child
% sees a rhombus / rectangle / square / parallelogram as separate things, and
% how class inclusion only emerges at level 2 once definitions come into play.

van_hiele_marker(square_rectangle_classification, 0,
    [ "the rhombus is not a parallelogram"
    , "the rhombus is a completely different thing from a parallelogram"
    , "rectangle seems different to me than a square"
    , "looks fat, looks like boxes"
    , "longer than a square"
    , "slanted on sides, a rectangle is not slanted"
    , "looks like a [familiar shape name]"
    ],
    [vh_paper2_p245, vh_fuys_clinical_pat]).
tier(ref(van_hiele, square_rectangle_classification, 0), 2,
     [van_hiele_dissertation_corpus],
     "Q-002 resolution 2026-05-04: demoted from Tier 1 to Tier 2 because kid-talk MarkerPhrases are derived from Fuys/Geddes/Tischler 1988 *replication* clinical interviews (US 6th and 9th graders), not from Pierre van Hiele's or Dina van Hiele-Geldof's original 1957 Dutch transcripts. Level descriptors van Hiele's, kid-talk Fuys 1988 replication. Direct van Hiele assertion (paper #2 p. 245).").

triangulation(ref(van_hiele, square_rectangle_classification, 0),
    [ source(van_hiele_paper2, agrees),
      source(fuys_1988_clinical, agrees) ]).

van_hiele_marker(square_rectangle_classification, 1,
    [ "a rectangle has four right angles"
    , "the diagonals of a rectangle are equal"
    , "the opposite sides of a rectangle are equal"
    , "if it has four right angles it is a rectangle even if drawn badly"
    , "squares have 4 even sides, the sides are equal, squares have right angles, they have parallel lines"
    , "a square has all the properties I just listed but it isn't necessarily a rectangle"
    ],
    [vh_paper2_p245, vh_paper7_p77, vh_fuys_clinical_adam]).
tier(ref(van_hiele, square_rectangle_classification, 1), 2,
     [van_hiele_dissertation_corpus],
     "Q-002 resolution 2026-05-04: demoted from Tier 1 to Tier 2; level descriptors van Hiele's, kid-talk Fuys 1988 replication. Direct van Hiele: 'figures are holders of their properties' (paper #2 p. 245); class inclusion not yet operative at level 1.").

triangulation(ref(van_hiele, square_rectangle_classification, 1),
    [ source(van_hiele_paper2, agrees),
      source(van_hiele_paper7, agrees),
      source(fuys_1988_clinical, agrees) ]).

van_hiele_marker(square_rectangle_classification, 2,
    [ "all squares are rectangles because they have all the properties of a rectangle"
    , "the square is recognized as being a rectangle because at this level definitions come into play"
    , "if it has four sides it has four angles so we don't need both properties"
    , "all sides equal means opposite sides are equal so we don't need that"
    , "one property precedes another property"
    ],
    [vh_paper2_p245, vh_fuys_clinical_samantha, vh_fuys_clinical_murielle]).
tier(ref(van_hiele, square_rectangle_classification, 2), 2,
     [van_hiele_dissertation_corpus],
     "Q-002 resolution 2026-05-04: demoted from Tier 1 to Tier 2; level descriptors van Hiele's, kid-talk Fuys 1988 replication (Samantha, Murielle utterances). Direct van Hiele: at level 2 'definitions of figures come into play' and properties are ordered (paper #2 p. 245).").

triangulation(ref(van_hiele, square_rectangle_classification, 2),
    [ source(van_hiele_paper2, agrees),
      source(fuys_1988_clinical, agrees) ]).

% ── general visual recognition (level-0 across all topics) ──────────────────

van_hiele_marker(polygon_recognition, 0,
    [ "a child recognizes a rectangle by its form"
    , "the problems are purely visual, there are no rules"
    , "I can reproduce these figures on a geoboard but I sort them by how they look"
    , "I sort by pointyness"
    , "this one looks like a box"
    ],
    [vh_paper2_p245, vh_paper5_p2, vh_fuys_clinical_pat]).
tier(ref(van_hiele, polygon_recognition, 0), 2,
     [van_hiele_dissertation_corpus],
     "Q-002 resolution 2026-05-04: demoted from Tier 1 to Tier 2; level descriptors van Hiele's, kid-talk Fuys 1988 replication (Pat). Direct van Hiele: the level-0 child reasons 'from the structure', purely visually, 'there are no rules' (paper #5 p. 2).").

triangulation(ref(van_hiele, polygon_recognition, 0),
    [ source(van_hiele_paper2, agrees),
      source(van_hiele_paper5, agrees),
      source(fuys_1988_clinical, agrees) ]).

van_hiele_marker(polygon_recognition, 1,
    [ "a figure is recognized by its properties"
    , "the figure is the totality of its geometric properties"
    , "I can name the properties of a rhomb"
    , "an isosceles triangle is half a rhomb"
    , "this shape has 4 sides, 4 angles, sides are parallel"
    ],
    [vh_paper2_p245, vh_paper7_p77, vh_fuys_clinical_arthur]).
tier(ref(van_hiele, polygon_recognition, 1), 2,
     [van_hiele_dissertation_corpus],
     "Q-002 resolution 2026-05-04: demoted from Tier 1 to Tier 2; level descriptors van Hiele's, kid-talk Fuys 1988 replication (Arthur). Direct van Hiele: 'a geometric shape is still interpreted as the totality of its geometric properties' (paper #7 pp. 77-78).").

triangulation(ref(van_hiele, polygon_recognition, 1),
    [ source(van_hiele_paper2, agrees),
      source(van_hiele_paper7, agrees),
      source(fuys_1988_clinical, agrees) ]).

% ── informal deduction (level 2 across topics — saws, ladders, angle sums) ──

van_hiele_marker(informal_deduction_with_parallels, 2,
    [ "the angles of a triangle sum to 180 degrees because of the parallel-line argument"
    , "I can put the relations into a logical pattern using the implication arrow"
    , "from parallelism of lines I conclude equality of angles"
    , "A = B by a saw. E = F by a ladder."
    , "angle a = angle c by a ladder and angle b = angle c by a saw, so angle a = angle b"
    , "I can use congruence to prove a property of the whole figure"
    ],
    [vh_paper7_p71, vh_paper6_p42, vh_fuys_clinical_alice, vh_fuys_clinical_david]).
tier(ref(van_hiele, informal_deduction_with_parallels, 2), 2,
     [van_hiele_dissertation_corpus],
     "Q-002 resolution 2026-05-04: demoted from Tier 1 to Tier 2; level descriptors van Hiele's, kid-talk Fuys 1988 replication (Alice, David). Direct van Hiele: at level 2 a pupil can 'apply operatively relations known to him between figures known to him' (paper #6 p. 42); 'logical relations were put into a logical pattern, using the implication arrow' (paper #7 pp. 71-72).").

triangulation(ref(van_hiele, informal_deduction_with_parallels, 2),
    [ source(van_hiele_paper6, agrees),
      source(van_hiele_paper7, agrees),
      source(fuys_1988_clinical, agrees) ]).

% ── meta-deduction (level 3 — converse, axiom, necessary/sufficient) ────────

van_hiele_marker(formal_deduction, 3,
    [ "thinking is concerned with the meaning of deduction"
    , "I think about the converse of a theorem"
    , "I think about axioms"
    , "I distinguish necessary from sufficient conditions"
    , "I understand what is meant by logical ordering"
    , "I know why axioms and definitions are indispensable"
    , "I can order a new domain logically (e.g., the cylinder)"
    ],
    [vh_paper2_p245, vh_paper2_p250]).
tier(ref(van_hiele, formal_deduction, 3), 1,
     [van_hiele_dissertation_corpus],
     "Direct van Hiele: 'At the Third Level, thinking is concerned with the meaning of deduction, with the converse of a theorem, with axiom, with necessary and sufficient conditions' (paper #2 p. 245); fuller statement on p. 250.").

% ── rigor / comparing axiom systems (level 4) ───────────────────────────────

van_hiele_marker(axiom_system_comparison, 4,
    [ "figures are defined only by symbols bound by relations"
    , "I no longer ask: what are points, lines, surfaces?"
    , "I compare different deductive theories"
    , "I seek out missing axioms in non-Euclidean geometries"
    , "I can establish the foundation of a new theory and build a deductive system on it"
    ],
    [vh_paper2_p248, vh_paper7_p80, vh_paper8_p192]).
tier(ref(van_hiele, axiom_system_comparison, 4), 1,
     [van_hiele_dissertation_corpus],
     "Direct van Hiele: 'Systems of axioms belong to the fourth level... figures are defined only by symbols bound by relations' (paper #2 pp. 248-249).").

% ── the language property — recorded as a markers-cluster on a meta concept ─
%
% Van Hiele's own emphatic claim: each level has its own language; relations
% true at one level can be false at another. Modeled here as marker phrases
% that distinguish "speaking about geometry" at each level for the meta-
% concept `geometric_language`. The synthesizer may choose to fold this into
% misconceptions, material_inferences, or keep it as a meta-marker.

van_hiele_marker(geometric_language, 0,
    [ "I describe shapes by appearance: pointy, slanty, fat, long, short"
    , "side means a vertical segment to me"
    , "boxes, looks like, kind of like"
    ],
    [vh_1959_p246, vh_fuys_clinical_pat]).
tier(ref(van_hiele, geometric_language, 0), 2,
     [van_hiele_dissertation_corpus],
     "Q-002 resolution 2026-05-04: demoted from Tier 1 to Tier 2; level descriptor van Hiele's, kid-talk Fuys 1988 replication (Pat). Van Hiele 1959/1984 p.246: 'each level has its own linguistic symbols and its own system of relations'.").

triangulation(ref(van_hiele, geometric_language, 0),
    [ source(van_hiele_1959, agrees),
      source(fuys_1988_clinical, agrees) ]).

van_hiele_marker(geometric_language, 1,
    [ "I name properties (right angle, parallel, equal sides, diagonal)"
    , "I list properties of a class of figures"
    , "I do not yet differentiate definitions from propositions"
    ],
    [vh_paper7_p77, vh_1959_p246]).
tier(ref(van_hiele, geometric_language, 1), 1,
     [van_hiele_dissertation_corpus],
     "Van Hiele paper #7 pp. 77-78: technical language emerges but logical relations are not yet a 'fit study-object'.").

van_hiele_marker(geometric_language, 2,
    [ "I use the implication arrow"
    , "I deduce one property from another"
    , "I use definitions to classify (square IS a rectangle)"
    , "I use 'because' for ordered geometric reasoning"
    ],
    [vh_paper2_p245, vh_paper3_p8, vh_paper7_p71]).
tier(ref(van_hiele, geometric_language, 2), 1,
     [van_hiele_dissertation_corpus],
     "Van Hiele paper #3 p.8: at level 2 reasoning shows 'intrinsic planning, fullfilling the laws of formal logic'.").

van_hiele_marker(geometric_language, 3,
    [ "I talk about converse, axiom, necessary, sufficient"
    , "I use the meta-language of theorem-ordering"
    , "I argue why an axiom is indispensable"
    ],
    [vh_paper2_p250]).
tier(ref(van_hiele, geometric_language, 3), 1,
     [van_hiele_dissertation_corpus],
     "Van Hiele paper #2 p.250: aim of instruction is 'to understand what is meant by logical ordering'.").

van_hiele_marker(geometric_language, 4,
    [ "I talk about systems of propositions, not about lines and points"
    , "I talk about the structure of an axiom system"
    , "I compare deductive systems"
    ],
    [vh_paper2_p248, vh_paper7_p80]).
tier(ref(van_hiele, geometric_language, 4), 1,
     [van_hiele_dissertation_corpus],
     "Van Hiele paper #2 pp.248-249: at level 4 the subject-matter is 'the system of propositions itself'.").

% =============================================================================
% Q-N103-B resolution (2026-05-04): convexity-test pluralism IS the
% developmental insight — each of N103's four tests is tagged to its native
% van Hiele level. The synthesizer ratifies N103's choice not to canonicalize
% by reading the four tests as a level progression.
% =============================================================================

van_hiele_marker(rubber_band_convexity_test, 0,
    [ "I stretch the rubber band around the shape and look"
    , "the rubber band makes the shape look pointy or rounded"
    , "if the rubber band lifts off, it's not convex"
    , "it just looks dented"
    ],
    [n103_ch1_act_1_13]).
tier(ref(van_hiele, rubber_band_convexity_test, 0), 2,
    [source(synthesizer, agrees), source(n103, agrees)],
    "Q-N103-B resolution 2026-05-04: the rubber-band test is a level-0 visual test — the rubber band makes the convexity property *look* directly. Tier 2 because the test is N103's, the level assignment is the synthesizer's.").

van_hiele_marker(kids_crawl_space_convexity_test, 1,
    [ "if you roll the shape on the floor there's a gap"
    , "a tiny kid could crawl underneath the bend"
    , "the shape doesn't sit flat on every side"
    , "I can describe where the gap shows up"
    ],
    [n103_ch1_act_1_13]).
tier(ref(van_hiele, kids_crawl_space_convexity_test, 1), 2,
    [source(synthesizer, agrees), source(n103, agrees)],
    "Q-N103-B resolution 2026-05-04: the crawl-space test is level-1 — the student articulates the property using a physical/embodied metaphor (gap under the figure when rolled). Tier 2 because the test is N103's (Aaron Taylor), the level assignment is the synthesizer's.").

van_hiele_marker(reflex_angle_convexity_test, 2,
    [ "if any interior angle is more than 180 degrees, it's not convex"
    , "I check each vertex to see if the angle is reflex"
    , "the reflex angle means the polygon turns back on itself"
    , "convex means no angle pokes inward"
    ],
    [n103_ch1_act_1_13]).
tier(ref(van_hiele, reflex_angle_convexity_test, 2), 2,
    [source(synthesizer, agrees), source(n103, agrees)],
    "Q-N103-B resolution 2026-05-04: the reflex-angle test is level-2 — the student uses angle classification (reflex vs non-reflex) as a deductive criterion. Tier 2 because the test is N103's, the level assignment is the synthesizer's.").

van_hiele_marker(line_segment_convexity_test, 3,
    [ "for any two points inside the figure, the segment between them stays inside"
    , "a shape is convex iff every line segment with endpoints in the figure is contained in the figure"
    , "I can prove this is the definition used in advanced mathematics texts"
    , "this is the canonical definition of convexity"
    ],
    [n103_ch1_act_1_13]).
tier(ref(van_hiele, line_segment_convexity_test, 3), 2,
    [source(synthesizer, agrees), source(n103, agrees)],
    "Q-N103-B resolution 2026-05-04: the line-segment test is level-3 — the student articulates the formal universally-quantified definition used in real analysis and convex geometry. Tier 2 because the test is N103's, the level assignment is the synthesizer's.").

% =============================================================================
% Records contributed by the Van de Walle digger (2026-05-03)
% Source: Elementary_and_Middle_School_Mathematics.pdf (NotebookLM nb 6c9f6d7a).
% Backing corpus: ../corpus/van_de_walle_excerpts.md
%
% Concept IDs are proposals; the synthesizer canonicalizes against the
% Van Hiele dissertation digger's IDs. Where they diverge, that's a
% Tier 4 conflict for OPEN_QUESTIONS.md.
% =============================================================================

% ── Level 0: Visualization ───────────────────────────────────────────

van_hiele_marker(square_recognition, 0,
    [ "it looks like a square"
    , "I put these together because they are all pointy"
    , "looks like a rocket"
    , "curvy"
    ],
    vdw_ch20_p514).
tier(ref(van_hiele, square_recognition, 0), 1, [source(vdw, agrees)],
    "Direct VdW quote of level-0 student speech, Ch. 20 p. 514-515. The canonical 'it looks like a square' and 'pointy' sort phrase.").

van_hiele_marker(triangle_recognition, 0,
    [ "it looks like a triangle"
    , "this triangle is upside down"
    ],
    vdw_ch20_p519).
tier(ref(van_hiele, triangle_recognition, 0), 1, [source(vdw, agrees)],
    "Level-0 marker tied to the triangle-upside-down misconception (VdW p. 519). 'Upside down' is itself a level-0 cue (canonical-orientation reasoning).").

van_hiele_marker(tilted_square_as_diamond, 0,
    [ "that's a diamond, not a square"
    , "it's a diamond because it's tipped"
    ],
    vdw_ch20_p514).
tier(ref(van_hiele, tilted_square_as_diamond, 0), 1, [source(vdw, agrees)],
    "VdW: a level-0 thinker may see a tilted square 'and believe it is a diamond (not a mathematical term for a shape) and no longer a square' (p. 514).").

van_hiele_marker(three_d_shape_recognition, 0,
    [ "it looks like a box"
    , "it looks like a ball"
    , "it's a can"
    ],
    vdw_ch20_p521).
tier(ref(van_hiele, three_d_shape_recognition, 0), 3, [source(vdw, partial)],
    "VdW Activity 20.1 adapted for 3-D solids (p. 521). Marker phrases paraphrase VdW's 3-D classification description; flagged Tier 3 because the kid-talk wording is paraphrase rather than direct quote.").

% ── Level 1: Analysis ────────────────────────────────────────────────

van_hiele_marker(square_recognition, 1,
    [ "all squares have four equal sides"
    , "all squares have four right angles"
    , "this is a square because it has four equal sides and four square corners"
    ],
    vdw_ch20_p516).
tier(ref(van_hiele, square_recognition, 1), 1, [source(vdw, agrees)],
    "VdW Ch. 20 p. 515-516 describes level-1 thinkers listing properties of all squares as a class. Marker phrases follow Activity 20.2's templating.").

van_hiele_marker(rectangle_class, 1,
    [ "all rectangles have four sides"
    , "rectangles have opposite sides parallel"
    , "rectangles have opposite sides the same length"
    , "rectangles have four right angles"
    , "rectangles have congruent diagonals"
    ],
    vdw_ch20_p515).
tier(ref(van_hiele, rectangle_class, 1), 1, [source(vdw, agrees)],
    "Direct VdW: 'four sides, opposite sides parallel, opposite sides same length, four right angles, congruent diagonals, etc.' (p. 515).").

van_hiele_marker(cube_class, 1,
    [ "all cubes have six congruent faces"
    , "each face of a cube is a square"
    ],
    vdw_ch20_p515).
tier(ref(van_hiele, cube_class, 1), 1, [source(vdw, agrees)],
    "Direct VdW quote: 'All cubes have six congruent faces, and each of those faces is a square' (p. 515).").

van_hiele_marker(three_d_shape_recognition, 1,
    [ "these shapes have square corners sort of like rectangles"
    , "these look like boxes"
    , "all the boxes have square sides"
    , "all the boxes have rectangular sides"
    ],
    vdw_ch20_p521).
tier(ref(van_hiele, three_d_shape_recognition, 1), 1, [source(vdw, agrees)],
    "Direct VdW quotes from the level-1 3-D classification description, p. 521.").

van_hiele_marker(quadrilateral_classification, 1,
    [ "this quadrilateral has two pairs of parallel sides"
    , "all four sides are the same length"
    , "the diagonals are the same length"
    ],
    vdw_ch20_p516).
tier(ref(van_hiele, quadrilateral_classification, 1), 3, [source(vdw, partial)],
    "Level-1 'lists all properties' described p. 515-516 (Activity 20.2). Marker phrases generalized from Activity 20.2's chart-headings (Sides, Angles, Diagonals, Symmetries); paraphrase, hence Tier 3.").

% ── Level 2: Informal Deduction ──────────────────────────────────────

van_hiele_marker(quadrilateral_classification, 2,
    [ "if all four angles are right angles, the shape must be a rectangle"
    , "if it is a square, all angles are right angles"
    , "if it is a square, it must be a rectangle"
    , "if a quadrilateral has these properties, then it must be a square"
    , "rectangles are parallelograms with a right angle"
    ],
    vdw_ch20_p517).
tier(ref(van_hiele, quadrilateral_classification, 2), 1, [source(vdw, agrees)],
    "Direct VdW quotes of level-2 if-then reasoning, p. 516-517. The signature characteristic of level 2.").

van_hiele_marker(minimal_defining_list, 2,
    [ "if a shape has these two properties it must be a square"
    , "any shape with all the properties on the MDL must be that shape"
    , "if any single property is removed from the list, it is no longer defining"
    ],
    vdw_ch20_p517).
tier(ref(van_hiele, minimal_defining_list, 2), 1, [source(vdw, agrees)],
    "VdW Activity 20.3 'Minimal Defining Lists' p. 517 — language pattern of level-2 students authoring definitions.").

van_hiele_marker(square_recognition, 2,
    [ "a square is a special rectangle"
    , "a square is a special rhombus"
    , "every square is a rectangle"
    ],
    vdw_ch20_p523).
tier(ref(van_hiele, square_recognition, 2), 1, [source(vdw, agrees)],
    "VdW p. 523-524 inclusive-classification position: 'a square is a rectangle and a rhombus.' Marker phrases are kid-talk paraphrases of the stated relationships.").

van_hiele_marker(triangle_angle_sum, 2,
    [ "the three angles of a triangle add up to a straight line"
    , "the angles always add up to 180 degrees"
    ],
    vdw_ch20_p531).
tier(ref(van_hiele, triangle_angle_sum, 2), 1, [source(vdw, agrees)],
    "VdW Activity 20.17 'Angle Sum in a Triangle' p. 531 — kid-conjecturing language at level 2.").

% ── Level 3: Deduction ───────────────────────────────────────────────

van_hiele_marker(diagonals_of_rectangles_proof, 3,
    [ "we need to prove this from a deductive argument"
    , "knowing it is true is not the same as knowing why"
    ],
    vdw_ch20_p517).
tier(ref(van_hiele, diagonals_of_rectangles_proof, 3), 3,
    [source(vdw, partial)],
    "VdW Ch. 20 p. 517 paraphrased: a level-3 student 'has an appreciation of the need to prove this from a series of deductive arguments.' VdW gives no direct kid-talk; marker phrases are paraphrase. Flag for synthesizer.").

% ── Level 4: Rigor ───────────────────────────────────────────────────
%
% VdW notes level 4 is 'generally the level of a college mathematics
% major' (p. 517). Out of K-8 scope. No marker authored from VdW.
