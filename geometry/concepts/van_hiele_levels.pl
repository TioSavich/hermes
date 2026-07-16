% concepts/van_hiele_levels.pl — first-class concept records for the five
% van Hiele levels themselves.
%
% Authored 2026-05-04 evening as part of the chatbot iteration loop. Live
% testing showed that questions like "What does van Hiele level 1 look
% like?" returned generic probing responses because the levels are
% properties attached to other concepts (via van_hiele_marker/4), not
% concepts themselves. Adding these geom_concept records gives the
% matching layer something to anchor when a user asks about levels
% directly. Each concept's description is dense enough that a chatbot
% pulling it as a card gets a substantive answer — but the underlying
% van_hiele_marker/4 records remain the source of truth for level-tagged
% kid-talk markers attached to specific topical concepts.
%
% Schema: ../schema.pl
% Source: van Hiele's own writing (Fuys 1988 translation), Van de Walle
%         Ch. 20 summary, Crowley 1987's NCTM-style exposition.

:- multifile geom_concept/4, tier/4, material_inference/4.
:- discontiguous geom_concept/4, tier/4, material_inference/4,
               van_hiele_level_material_claim/6.

%!  van_hiele_level_material_claim_witness(+Id, -Witness) is semidet.
%
%   Inspectable proof object for finite Van Hiele level anchor rows.
van_hiele_level_material_claim_witness(Id, Witness) :-
    van_hiele_level_material_claim(Id,
                                   LevelConcept,
                                   Level,
                                   Premise,
                                   Target,
                                   Polarity),
    tier(ref(concept, LevelConcept), LevelTier, LevelSources, LevelSourceNote),
    tier(ref(material_inference, LevelConcept, Target),
         InferenceTier,
         InferenceSources,
         InferenceSourceNote),
    van_hiele_level_marker_witnesses(Target, Level, MarkerWitnesses),
    van_hiele_level_marker_boundary(MarkerWitnesses, MarkerBoundary),
    van_hiele_level_condition_roles(Id, Roles),
    Witness = _{ kind: geometry_van_hiele_level_material_inference,
                 scope: closed_world_finite_van_hiele_level_anchor_table,
                 id: Id,
                 level_concept: LevelConcept,
                 level: Level,
                 premise: Premise,
                 target: Target,
                 polarity: Polarity,
                 level_tier: LevelTier,
                 level_sources: LevelSources,
                 level_source_note: LevelSourceNote,
                 inference_tier: InferenceTier,
                 inference_sources: InferenceSources,
                 inference_source_note: InferenceSourceNote,
                 boundary: finite_van_hiele_level_anchor_not_general_developmental_diagnosis,
                 marker_boundary: MarkerBoundary,
                 condition_roles: Roles,
                 target_marker_witnesses: MarkerWitnesses,
                 fact: material_inference(LevelConcept, Premise, Target, Polarity) }.

van_hiele_level_marker_witnesses(Target, Level, Witnesses) :-
    findall(Witness,
            van_hiele_level_marker_witness(Target, Level, Witness),
            RawWitnesses),
    sort(RawWitnesses, Witnesses).

van_hiele_level_marker_witness(Target,
                               Level,
                               _{ kind: van_hiele_level_marker_support,
                                  target: Target,
                                  level: Level,
                                  marker_phrases: MarkerPhrases,
                                  citation: Citation,
                                  tier: Tier,
                                  sources: Sources,
                                  source_note: SourceNote,
                                  fact: van_hiele_marker(Target,
                                                        Level,
                                                        MarkerPhrases,
                                                        Citation) }) :-
    van_hiele_marker(Target, Level, MarkerPhrases, Citation),
    tier(ref(van_hiele, Target, Level), Tier, Sources, SourceNote).

van_hiele_level_marker_boundary([], no_loaded_marker_for_target_at_level) :-
    !.
van_hiele_level_marker_boundary(_, loaded_marker_support_for_target_at_level).

van_hiele_level_condition_roles(level_0_square_rectangle_example,
                                [ _{ kind: example_anchor,
                                     role: level_0_visual_recognition_example }
                                ]) :-
    !.
van_hiele_level_condition_roles(level_1_square_rectangle_example,
                                [ _{ kind: example_anchor,
                                     role: level_1_property_listing_example }
                                ]) :-
    !.
van_hiele_level_condition_roles(level_2_square_rectangle_example,
                                [ _{ kind: example_anchor,
                                     role: level_2_relational_class_inclusion_example }
                                ]) :-
    !.
van_hiele_level_condition_roles(level_2_quadrilateral_hierarchy_example,
                                [ _{ kind: example_anchor,
                                     role: level_2_quadrilateral_hierarchy_example }
                                ]) :-
    !.
van_hiele_level_condition_roles(_, []).

material_inference(LevelConcept, Premise, Target, Polarity) :-
    van_hiele_level_material_claim_witness(_Id, Witness),
    get_dict(fact, Witness, material_inference(LevelConcept,
                                               Premise,
                                               Target,
                                               Polarity)).

% ── Level 0: Visual / Recognition ─────────────────────────────────────

geom_concept(van_hiele_level_0_visual,
    "Van Hiele Level 0 (Visual / Recognition): students recognize shapes by their overall appearance — 'it looks like a door' / 'it's a square because it looks like one'. Properties of the shape are not separated from the shape itself; a tilted square is treated as a different shape (a 'diamond'). Students at this level can name shapes they have seen but cannot reliably reason from properties.",
    developmental,
    [0,1,2,3]).
tier(ref(concept, van_hiele_level_0_visual),
     1, [source(vh_diss, agrees), source(vdw, agrees)],
     "Direct van Hiele assertion; broadly anchored across math-ed literature.").

% ── Level 1: Analytic / Descriptive ───────────────────────────────────

geom_concept(van_hiele_level_1_analytic,
    "Van Hiele Level 1 (Analytic / Descriptive): students start to identify shapes by their parts and properties — 'a rectangle has four right angles' / 'all squares have four equal sides'. Students can list properties but treat them as independent observations: a square has 4 right angles AND 4 equal sides AND parallel sides, but they don't yet see one property as implying another. They cannot yet build subclass relationships ('a square is a special rectangle'). Tilted squares are still often refused as squares because property-listing hasn't fully overridden visual-pattern recognition.",
    developmental,
    [2,3,4,5]).
tier(ref(concept, van_hiele_level_1_analytic),
     1, [source(vh_diss, agrees), source(vdw, agrees)],
     "Direct van Hiele assertion.").

% ── Level 2: Abstract / Relational / Informal Deduction ──────────────

geom_concept(van_hiele_level_2_abstract,
    "Van Hiele Level 2 (Abstract / Relational / Informal Deduction): students grasp relationships between properties — 'if it has four right angles it's a rectangle even if drawn badly' — and between shape classes — 'a square is a special rectangle because it has all the rectangle properties plus equal sides'. Class inclusion now works: every square IS a rectangle. Students can construct minimal definitions ('a rectangle is a parallelogram with one right angle') and follow informal proofs but cannot yet construct formal ones. This is the level most secondary geometry curricula assume — and where many students arrive without the level-1 foundation.",
    developmental,
    [4,5,6,7]).
tier(ref(concept, van_hiele_level_2_abstract),
     1, [source(vh_diss, agrees), source(vdw, agrees)],
     "Direct van Hiele assertion.").

% ── Level 3: Formal Deduction ─────────────────────────────────────────

geom_concept(van_hiele_level_3_deductive,
    "Van Hiele Level 3 (Formal Deduction): students can construct (not just follow) formal proofs from axioms and theorems. They understand the role of definitions, axioms, theorems, and proof, and can work meaningfully within an axiomatic system. This is the goal of high-school geometry; students who reach it can prove triangle congruence theorems, parallel-line angle relationships, etc. — and understand WHY those proofs are valid.",
    developmental,
    [7,8]).
tier(ref(concept, van_hiele_level_3_deductive),
     1, [source(vh_diss, agrees), source(vdw, agrees)],
     "Direct van Hiele assertion.").

% ── Level 4: Rigor ────────────────────────────────────────────────────

geom_concept(van_hiele_level_4_rigor,
    "Van Hiele Level 4 (Rigor): students can compare different axiomatic systems (Euclidean vs non-Euclidean geometries) and reason about geometry as a formal mathematical structure independent of any particular interpretation. This level is rarely seen before college mathematics and is the appropriate target for math majors and preservice teachers reflecting on the foundations of their discipline.",
    developmental,
    [8]).
tier(ref(concept, van_hiele_level_4_rigor),
     1, [source(vh_diss, agrees), source(vdw, agrees)],
     "Direct van Hiele assertion.").

% ── Cross-links so the matching layer can pull marker examples ───────
%
% When a user asks "what does level N look like?", matching_concepts will
% rank van_hiele_level_N_X highly, but the actual *examples* of student
% talk at that level live in van_hiele_marker/4 records attached to
% topical concepts (square_rectangle_classification, polygon_recognition,
% etc.). These cross-links let concepts_in_neighborhood/3 pull both.

van_hiele_level_material_claim(level_0_square_rectangle_example,
    van_hiele_level_0_visual,
    0,
    "is exemplified by",
    square_rectangle_classification, entitled).
van_hiele_level_material_claim(level_1_square_rectangle_example,
    van_hiele_level_1_analytic,
    1,
    "is exemplified by",
    square_rectangle_classification, entitled).
van_hiele_level_material_claim(level_2_square_rectangle_example,
    van_hiele_level_2_abstract,
    2,
    "is exemplified by",
    square_rectangle_classification, entitled).
van_hiele_level_material_claim(level_2_quadrilateral_hierarchy_example,
    van_hiele_level_2_abstract,
    2,
    "is exemplified by",
    quadrilateral_hierarchy, entitled).

tier(ref(material_inference, van_hiele_level_0_visual,
         square_rectangle_classification),
     1, [source(synthesizer, agrees)],
     "The square/rectangle development is the canonical illustration van Hiele used; cross-link surfaces concrete examples when a user asks about a level.").
tier(ref(material_inference, van_hiele_level_1_analytic,
         square_rectangle_classification),
     1, [source(synthesizer, agrees)], "Same.").
tier(ref(material_inference, van_hiele_level_2_abstract,
         square_rectangle_classification),
     1, [source(synthesizer, agrees)], "Same.").
tier(ref(material_inference, van_hiele_level_2_abstract,
         quadrilateral_hierarchy),
     1, [source(synthesizer, agrees)],
     "Quadrilateral hierarchy is the level-2 inclusion-relation example par excellence.").
