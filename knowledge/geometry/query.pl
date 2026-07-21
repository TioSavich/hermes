% query.pl — high-level query predicates over the geometry KB.
%
% Loaded last by the canonical knowledge/geometry/schema.pl chain. Standalone bridge and
% Hermes worker loads both delegate to that manifest. Hermes reaches these
% predicates through hermes_worker.pl dispatch_geometry/4 and the persistent
% Prolog subprocess bridge in hermes/app/worker.py.
%
% Design context: README.md and OPEN_QUESTIONS.md in this directory.
% Schema: schema.pl

% ── helpers ──────────────────────────────────────────────────────────

% string_contains_ci(+Haystack, +Needle) — case-insensitive substring
string_contains_ci(Haystack, Needle) :-
    string_lower(Haystack, HL),
    string_lower(Needle, NL),
    sub_string(HL, _, _, _, NL).

string_lower(In, Out) :-
    (   string(In) -> string_to_atom(In, A) ; In = A ),
    downcase_atom(A, AL),
    atom_string(AL, Out).

% to_string(+Term, -String) — normalize atom/string/number to string
to_string(X, S) :-
    (   string(X) -> S = X
    ;   atom(X)   -> atom_string(X, S)
    ;   number(X) -> number_string(X, S)
    ).

% tokens_in_atom(+Term, -Tokens) — extract non-trivial word tokens as strings
tokens_in_atom(Term, Tokens) :-
    to_string(Term, S),
    string_lower(S, SL),
    split_string(SL, " _-,.;:?!()[]\"'", " _-,.;:?!()[]\"'", Parts),
    include([P]>>(string_length(P, L), L >= 3), Parts, Tokens).

% normalize_tokens(+InTokens, -StringTokens) — accept atoms or strings
normalize_tokens(In, Out) :-
    maplist([T, S]>>(to_string(T, S0), string_lower(S0, S)), In, Out).

% concept_id_in_stance(+Stance, -ConceptId) — pull a concept ID out
% of a developmental_marker stance term, if the stance embeds one.
concept_id_in_stance(Stance, ConceptId) :-
    compound(Stance),
    Stance =.. [_Functor | Args],
    member(ConceptId, Args),
    atom(ConceptId),
    geom_concept(ConceptId, _, _, _),
    !.

% gradeband_overlaps(+QueryBands, +ConceptBands)
gradeband_overlaps(any, _) :- !.
gradeband_overlaps([], _) :- !.
gradeband_overlaps(QB, CB) :-
    is_list(QB),
    is_list(CB),
    member(G, QB),
    member(G, CB),
    !.

% tier_of(+RecordRef, -Level) — pick the highest available tier for a record
tier_of(Ref, Level) :-
    findall(L, tier(Ref, L, _, _), Levels),
    Levels \= [],
    !,
    min_list(Levels, Level).
tier_of(_, 3).  % records lacking tier are treated as Tier 3 by default

% tier_max_default(?Max) — default tier ceiling for queries (1+2)
tier_max_default(2).

% ── 1. Concept lookup by tokens with grade-band filter ───────────────
%
% matching_concepts(+Tokens, +GradeBand, -Concepts)
%   Tokens    : list of atoms or strings (lowercased word stems)
%   GradeBand : list of integers (e.g. [1,2,3]) | any | []
%   Concepts  : list of concept(Id, Name, Topic, Score), sorted by Score desc

matching_concepts(Tokens, GradeBand, Concepts) :-
    matching_concepts(Tokens, GradeBand, 2, Concepts).

matching_concepts(Tokens, GradeBand, MaxTier, Concepts) :-
    normalize_tokens(Tokens, NTokens),
    findall(concept(Id, Name, Topic, Score),
            ( geom_concept(Id, Name, Topic, Bands),
              gradeband_overlaps(GradeBand, Bands),
              tier_for_concept(Id, T),
              T =< MaxTier,
              score_concept(NTokens, Id, Name, Topic, Score),
              Score > 0
            ),
            Unsorted),
    sort_by_score(Unsorted, Concepts).

tier_for_concept(Id, T) :-
    current_predicate(synthesizer_concept_triangulation_witness/2),
    synthesizer_concept_triangulation_witness(Id, Witness),
    get_dict(tier, Witness, T),
    !.
tier_for_concept(Id, T) :-
    current_predicate(measurement_concept_witness/2),
    measurement_concept_witness(Id, Witness),
    get_dict(tier, Witness, T),
    !.
tier_for_concept(Id, T) :-
    (   tier(ref(concept, Id), L, _, _) -> T = L ; T = 2 ).

score_concept(Tokens, Id, Name, Topic, Score) :-
    tokens_in_atom(Id, IdToks),
    tokens_in_atom(Name, NameToks),
    tokens_in_atom(Topic, TopicToks),
    aggregate_all(count, (member(Tk, Tokens), member(Tk, IdToks)), IdHits),
    aggregate_all(count, (member(Tk, Tokens), member(Tk, NameToks)), NameHits),
    aggregate_all(count, (member(Tk, Tokens), member(Tk, TopicToks)), TopicHits),
    Score is IdHits * 5 + NameHits * 4 + TopicHits * 2.

sort_by_score(Unsorted, Sorted) :-
    map_list_to_pairs([concept(_,_,_,S), NegScore]>>(NegScore is -S),
                      Unsorted, Pairs),
    keysort(Pairs, KSorted),
    pairs_values(KSorted, Sorted).

% Friendlier form when caller has a list of token atoms already.

% ── 2. Misconception trigger matching ────────────────────────────────
%
% applicable_misconceptions(+UserText, +ConceptIds, -Misconceptions)
%   UserText   : the normalized utterance (atom or string)
%   ConceptIds : list of concept IDs to scope, or `any` for unscoped
%   Misconceptions : list of misconception(Id, ConceptId, Name,
%                                          MatchedTrigger, Repair, Tier)

applicable_misconceptions(UserText, ConceptIds, Miscs) :-
    applicable_misconceptions(UserText, ConceptIds, 3, Miscs).

applicable_misconceptions(UserText, ConceptIds, MaxTier, Miscs) :-
    (   atom(UserText) -> atom_string(UserText, UT) ; UT = UserText ),
    findall(misconception(Id, Cid, Name, MatchedTrigger, Repair, Tier),
            ( misconception_projection(Id,
                                       Cid,
                                       Name,
                                       Triggers,
                                       Repair,
                                       _Cite,
                                       Tier),
              concept_in_scope(Cid, ConceptIds),
              Tier =< MaxTier,
              member(Trigger, Triggers),
              ( atom(Trigger) -> atom_string(Trigger, T) ; T = Trigger ),
              string_contains_ci(UT, T),
              MatchedTrigger = T
            ),
            Miscs).

concept_in_scope(_, any) :- !.
concept_in_scope(_, []) :- !.
concept_in_scope(Cid, Cids) :- is_list(Cids), member(Cid, Cids).

% linked_misconceptions(+ConceptIds, +MaxTier, -Misconceptions)
%   Sister to applicable_misconceptions: returns all misconceptions linked
%   to any of the given concept IDs, regardless of whether a trigger
%   matches user text. Useful as fallback or for lesson-planning where
%   we want every misconception associated with a concept.
%   ConceptIds : list of atoms or `any` (returns all in KB)
linked_misconceptions(ConceptIds, MaxTier, Miscs) :-
    findall(misconception(Id, Cid, Name, none, Repair, Tier),
            ( misconception_projection(Id,
                                       Cid,
                                       Name,
                                       _Triggers,
                                       Repair,
                                       _Cite,
                                       Tier),
              concept_in_scope(Cid, ConceptIds),
              Tier =< MaxTier
            ),
            Miscs).

% concepts_in_neighborhood(+ConceptIds, +Depth, -Neighborhood)
%   Expand a list of concept IDs to include concepts reachable via:
%     - concept_relation (typed conceptual routing edges; preferred)
%     - material_inference (legacy fallback for older concept cross-links)
%     - developmental_marker (input is the arc, OR input is referenced in
%       a from/to stance of some arc)
%   Depth = 0 returns the input list unchanged. Depth = 1 includes
%   immediate neighbors. Higher depths are not implemented yet (BFS would
%   need a visited set; for the chatbot's needs, depth 1 is enough).
%
%   This is the bridge predicate that handles cases like
%   `tilted_square_as_diamond` (a phenomenon concept) being linked to
%   `orientation_invariant_naming` (the property concept that owns the
%   misconceptions) via an explicit concept_relation/4 cross-link.
concepts_in_neighborhood(Cs, 0, Cs) :- !.
concepts_in_neighborhood(Cs, _, Out) :-
    findall(N, ( member(C, Cs), neighbor_concept(C, N) ), Neighbors),
    append(Cs, Neighbors, Combined),
    sort(Combined, Out).

% neighbor_concept(+Concept, -Neighbor) — concepts within one hop
neighbor_concept(C, N) :-
    typed_neighbor_concept(C, N, _).
neighbor_concept(C, N) :-
    material_inference(C, _, Conclusion, _),
    atom(Conclusion),
    geom_concept(Conclusion, _, _, _),
    N = Conclusion.
neighbor_concept(C, N) :-
    material_inference(N, _, Conclusion, _),
    atom(Conclusion), Conclusion = C,
    geom_concept(N, _, _, _).
neighbor_concept(C, N) :-
    developmental_marker(C, From, To, _),
    ( concept_id_in_stance(From, N) ; concept_id_in_stance(To, N) ).
neighbor_concept(C, ArcId) :-
    developmental_marker(ArcId, From, To, _),
    ( concept_id_in_stance(From, C) ; concept_id_in_stance(To, C) ).

% typed_neighbor_concept(+Concept, -Neighbor, -Relation)
%   Typed conceptual routing edge. This is not proof-bearing entailment;
%   proof-bearing material commitments belong in proof_relation/3.
typed_neighbor_concept(C, N, Relation) :-
    concept_relation(C, Relation, N, _),
    atom(N),
    geom_concept(N, _, _, _).
typed_neighbor_concept(C, N, Relation) :-
    concept_relation(N, Relation, C, _),
    atom(N),
    geom_concept(N, _, _, _).

% ── 3. Van Hiele markers for a concept ───────────────────────────────
%
% vh_markers_for(+ConceptId, +LevelOpt, -Markers)
%   LevelOpt : 0..4 | any
%   Markers  : list of marker(Level, Phrases, Citation, Tier)

vh_markers_for(ConceptId, LevelOpt, Markers) :-
    vh_markers_for(ConceptId, LevelOpt, 2, Markers).

vh_markers_for(ConceptId, LevelOpt, MaxTier, Markers) :-
    findall(marker(Level, Phrases, Citation, Tier),
            ( van_hiele_marker(ConceptId, Level, Phrases, Citation),
              level_match(LevelOpt, Level),
              tier_of(ref(van_hiele, ConceptId, Level), Tier),
              Tier =< MaxTier
            ),
            Markers).

level_match(any, _) :- !.
level_match(Level, Level).

% ── 4. Bootstrap activities/questions ────────────────────────────────
%
% bootstraps_for(+ConceptId, +TargetTransition, +Kind, -Bootstraps)

bootstraps_for(ConceptId, Transition, Kind, Bootstraps) :-
    bootstraps_for(ConceptId, Transition, Kind, 2, Bootstraps).

bootstraps_for(ConceptId, Transition, Kind, MaxTier, Bootstraps) :-
    findall(bs(Id, K, Prompt, Tools, Citation, Tier),
            ( bootstrap_projection(Id,
                                   ConceptId,
                                   K,
                                   Prompt,
                                   Tools,
                                   T,
                                   Tier,
                                   Citation),
              kind_match(Kind, K),
              transition_match(Transition, T),
              Tier =< MaxTier
            ),
            Bootstraps).

kind_match(any, _) :- !.
kind_match(K, K).

transition_match(any, _) :- !.
transition_match(T, T) :- !.

find_citation_for_bootstrap(Id, Citation) :-
    tier(ref(bootstrap, Id), _, Sources, _),
    !,
    Citation = Sources.
find_citation_for_bootstrap(_, []).

bootstrap_projection(Id, ConceptId, Kind, Prompt, Tools, Transition, Tier, Citation) :-
    current_predicate(n103_bootstrap_witness/2),
    n103_bootstrap_witness(Id, Witness),
    get_dict(fact, Witness,
             bootstrap(Id, ConceptId, Kind, Prompt, Tools, Transition)),
    get_dict(tier, Witness, Tier),
    get_dict(sources, Witness, Citation).
bootstrap_projection(Id, ConceptId, Kind, Prompt, Tools, Transition, Tier, Citation) :-
    current_predicate(van_de_walle_bootstrap_witness/2),
    van_de_walle_bootstrap_witness(Id, Witness),
    get_dict(fact, Witness,
             bootstrap(Id, ConceptId, Kind, Prompt, Tools, Transition)),
    get_dict(tier, Witness, Tier),
    get_dict(sources, Witness, Citation).
bootstrap_projection(Id, ConceptId, Kind, Prompt, Tools, Transition, Tier, Citation) :-
    bootstrap(Id, ConceptId, Kind, Prompt, Tools, Transition),
    \+ ( current_predicate(n103_bootstrap_witness/2),
         n103_bootstrap_witness(Id, _)
       ),
    \+ ( current_predicate(van_de_walle_bootstrap_witness/2),
         van_de_walle_bootstrap_witness(Id, _)
       ),
    tier_of(ref(bootstrap, Id), Tier),
    find_citation_for_bootstrap(Id, Citation).

% ── 5. Developmental arc lookup ──────────────────────────────────────
%
% developmental_arc_for(+ConceptOrArcId, -Arc)
%   Arc = arc(ArcConceptId, FromStance, ToStance, TransitionEvidence)
%       | none
%
% Tries: (a) the input IS an arc concept ID, or (b) the input is referenced
% inside a from/to stance.

developmental_arc_for(Id, arc(Id, From, To, Evidence)) :-
    developmental_marker(Id, From, To, Evidence),
    !.
developmental_arc_for(Id, arc(ArcId, From, To, Evidence)) :-
    developmental_marker(ArcId, From, To, Evidence),
    ( concept_id_in_stance(From, Id) ; concept_id_in_stance(To, Id) ),
    !.
developmental_arc_for(_, none).

% ── 6. PCK synthesis for a concept ───────────────────────────────────
%
% pck_synthesis_for(+ConceptId, -Synthesis)

pck_synthesis_for(ConceptId, pck(KKT, KTM, DA, Citation)) :-
    pck_synthesis_witness(ConceptId, Witness),
    get_dict(fact, Witness, pck_synthesis(ConceptId, KKT, KTM, DA, Citation)),
    !.
% Raw fallback: the witness path can fail (e.g. a referenced ref shape the
% witness does not yet handle) where the underlying fact is perfectly sound.
% Mirror the bootstrap/standard projections, which keep a raw fallback, so a
% witness gap degrades to the plain synthesis rather than silently to `none`.
pck_synthesis_for(ConceptId, pck(KKT, KTM, DA, Citation)) :-
    pck_synthesis(ConceptId, KKT, KTM, DA, Citation),
    !.
pck_synthesis_for(_, none).

% ── 7. Standards-anchored bundle (the lesson-planning hub) ──────────
%
% standards_bundle_for(+Framework, +Code, -Bundle)

standards_bundle_for(Framework, Code, Bundle) :-
    standards_bundle_for(Framework, Code, 2, Bundle).

standards_bundle_for(Framework, Code, MaxTier, Bundle) :-
    (   standard_anchor(ConceptId, Framework, Code, Statement)
    *-> geom_concept(ConceptId, Name, Topic, Bands),
        applicable_misconceptions("", [ConceptId], MaxTier, Miscs),
        % swap: misconceptions filter by trigger; here we want all linked
        all_misconceptions_for(ConceptId, MaxTier, AllMiscs),
        vh_markers_for(ConceptId, any, MaxTier, Markers),
        bootstraps_for(ConceptId, any, any, MaxTier, Bs),
        developmental_arc_for(ConceptId, Arc),
        pck_synthesis_for(ConceptId, Pck),
        Bundle = bundle(ConceptId,
                        concept(ConceptId, Name, Topic, Bands),
                        Statement,
                        AllMiscs,
                        Markers,
                        Bs,
                        Arc,
                        Pck)
    ;   Bundle = not_found
    ),
    % silence unused-singleton warning above
    ignore(Miscs = _).

all_misconceptions_for(ConceptId, MaxTier, Miscs) :-
    findall(misconception(Id, ConceptId, Name, all, Repair, Tier),
            ( misconception_projection(Id,
                                       ConceptId,
                                       Name,
                                       _Triggers,
                                       Repair,
                                       _Cite,
                                       Tier),
              Tier =< MaxTier
            ),
            Miscs).

misconception_projection(Id, Concept, Name, Triggers, Repair, Citation, Tier) :-
    current_predicate(measurement_misconception_witness/2),
    measurement_misconception_witness(Id, Witness),
    get_dict(fact, Witness,
             geom_misconception(Id, Concept, Name, Triggers, Repair, Citation)),
    get_dict(tier, Witness, Tier).
misconception_projection(Id, Concept, Name, Triggers, Repair, Citation, Tier) :-
    geom_misconception(Id, Concept, Name, Triggers, Repair, Citation),
    \+ ( current_predicate(measurement_misconception_witness/2),
         measurement_misconception_witness(Id, _)
       ),
    tier_of(ref(misconception, Id), Tier).

% ── 8. Concept monitoring bundle ────────────────────────────────────
%
% concept_monitoring_bundle(+ConceptId, -Bundle)
%   Bundle = geometry_monitoring_bundle(ConceptId, Concept,
%                                       RelatedConcepts, Standards,
%                                       Misconceptions, Metaphors,
%                                       VanHieleMarkers, DevelopmentalArcs)
%
% Unlike standards_bundle_for/3, this starts from a concept and follows typed
% concept_relation/4 edges once. This is the geometry-side monitoring surface:
% a caller can ask what standards, misconceptions, metaphors, and van Hiele
% markers are attached to the concept or its explicitly linked support concepts.

concept_monitoring_bundle(ConceptId, Bundle) :-
    concept_monitoring_bundle(ConceptId, 3, Bundle).

concept_monitoring_bundle(ConceptId, MaxTier,
                          geometry_monitoring_bundle(ConceptId,
                                                     Concept,
                                                     Related,
                                                     Standards,
                                                     Misconceptions,
                                                     Metaphors,
                                                     Markers,
                                                     Arcs)) :-
    geom_concept(ConceptId, Name, Topic, Bands),
    Concept = concept(ConceptId, Name, Topic, Bands),
    concepts_in_neighborhood([ConceptId], 1, ConceptIds),
    related_concepts_for(ConceptId, Related),
    standards_for_concepts(ConceptIds, MaxTier, Standards),
    linked_misconceptions(ConceptIds, MaxTier, Misconceptions),
    metaphors_for_concepts(ConceptIds, MaxTier, Metaphors),
    vh_markers_for_concepts(ConceptIds, MaxTier, Markers),
    developmental_arcs_for_concepts(ConceptIds, Arcs).

related_concepts_for(ConceptId, Related) :-
    findall(related_concept(RelatedConcept, Relation),
            typed_neighbor_concept(ConceptId, RelatedConcept, Relation),
            Raw),
    sort(Raw, Related).

standards_for_concepts(ConceptIds, MaxTier, Standards) :-
    findall(standard(ConceptId, Framework, Code, Statement, Tier),
            ( member(ConceptId, ConceptIds),
              standard_projection(ConceptId,
                                  Framework,
                                  Code,
                                  Statement,
                                  Tier),
              Tier =< MaxTier
            ),
            Raw),
    sort(Raw, Standards).

standard_projection(ConceptId, ccss, Code, Statement, Tier) :-
    current_predicate(ccss_geometry_standard_witness/3),
    ccss_geometry_standard_witness(ConceptId, Code, Witness),
    get_dict(fact, Witness,
             standard_anchor(ConceptId, ccss, Code, Statement)),
    get_dict(tier, Witness, Tier).
standard_projection(ConceptId, in_indiana, Code, Statement, Tier) :-
    current_predicate(indiana_geometry_standard_witness/3),
    indiana_geometry_standard_witness(ConceptId, Code, Witness),
    get_dict(fact, Witness,
             standard_anchor(ConceptId, in_indiana, Code, Statement)),
    get_dict(tier, Witness, Tier).
standard_projection(ConceptId, im_lesson, Code, Statement, Tier) :-
    current_predicate(im_grade8_lesson_standard_witness/3),
    im_grade8_lesson_standard_witness(ConceptId, Code, Witness),
    get_dict(fact, Witness,
             standard_anchor(ConceptId, im_lesson, Code, Statement)),
    get_dict(tier, Witness, Tier).
standard_projection(ConceptId, im_lesson, Code, Statement, Tier) :-
    current_predicate(im_grade7_lesson_standard_witness/3),
    im_grade7_lesson_standard_witness(ConceptId, Code, Witness),
    get_dict(fact, Witness,
             standard_anchor(ConceptId, im_lesson, Code, Statement)),
    get_dict(tier, Witness, Tier).
standard_projection(ConceptId, im_lesson, Code, Statement, Tier) :-
    current_predicate(im_grade6_lesson_standard_witness/3),
    im_grade6_lesson_standard_witness(ConceptId, Code, Witness),
    get_dict(fact, Witness,
             standard_anchor(ConceptId, im_lesson, Code, Statement)),
    get_dict(tier, Witness, Tier).
standard_projection(ConceptId, Framework, Code, Statement, Tier) :-
    current_predicate(im_grade5_standard_anchor_witness/4),
    im_grade5_standard_anchor_witness(ConceptId, Framework, Code, Witness),
    get_dict(fact, Witness,
             standard_anchor(ConceptId, Framework, Code, Statement)),
    get_dict(tier, Witness, Tier).
standard_projection(ConceptId, Framework, Code, Statement, Tier) :-
    standard_anchor(ConceptId, Framework, Code, Statement),
    \+ ( Framework == ccss,
         current_predicate(ccss_geometry_standard_witness/3),
         ccss_geometry_standard_witness(ConceptId, Code, _)
       ),
    \+ ( Framework == in_indiana,
         current_predicate(indiana_geometry_standard_witness/3),
         indiana_geometry_standard_witness(ConceptId, Code, _)
       ),
    \+ ( Framework == im_lesson,
         current_predicate(im_grade8_lesson_standard_witness/3),
         im_grade8_lesson_standard_witness(ConceptId, Code, _)
       ),
    \+ ( Framework == im_lesson,
         current_predicate(im_grade7_lesson_standard_witness/3),
         im_grade7_lesson_standard_witness(ConceptId, Code, _)
       ),
    \+ ( Framework == im_lesson,
         current_predicate(im_grade6_lesson_standard_witness/3),
         im_grade6_lesson_standard_witness(ConceptId, Code, _)
       ),
    \+ ( current_predicate(im_grade5_standard_anchor_witness/4),
         im_grade5_standard_anchor_witness(ConceptId, Framework, Code, _)
       ),
    tier_of(ref(standard, ConceptId, Code), Tier).

metaphors_for_concepts(ConceptIds, MaxTier, Metaphors) :-
    findall(metaphor(ConceptId, MetaphorName, Mapping, Citation, Tier),
            ( member(ConceptId, ConceptIds),
              metaphor_projection(ConceptId,
                                  MetaphorName,
                                  Mapping,
                                  Citation,
                                  Tier),
              Tier =< MaxTier
            ),
            Raw),
    sort(Raw, Metaphors).

metaphor_projection(ConceptId, MetaphorName, Mapping, Citation, Tier) :-
    current_predicate(measuring_stick_metaphor_witness/3),
    measuring_stick_metaphor_witness(ConceptId, MetaphorName, Witness),
    get_dict(fact, Witness,
             metaphor_source(ConceptId, MetaphorName, Mapping, Citation)),
    get_dict(tier, Witness, Tier).
metaphor_projection(ConceptId, MetaphorName, Mapping, Citation, Tier) :-
    current_predicate(lakoff_nunez_metaphor_witness/3),
    lakoff_nunez_metaphor_witness(ConceptId, MetaphorName, Witness),
    get_dict(fact, Witness,
             metaphor_source(ConceptId, MetaphorName, Mapping, Citation)),
    get_dict(tier, Witness, Tier).
metaphor_projection(ConceptId, MetaphorName, Mapping, Citation, Tier) :-
    metaphor_source(ConceptId, MetaphorName, Mapping, Citation),
    \+ ( current_predicate(measuring_stick_metaphor_witness/3),
         measuring_stick_metaphor_witness(ConceptId, MetaphorName, _)
       ),
    \+ ( current_predicate(lakoff_nunez_metaphor_witness/3),
         lakoff_nunez_metaphor_witness(ConceptId, MetaphorName, _)
       ),
    tier_of(ref(metaphor, ConceptId, MetaphorName), Tier).

vh_markers_for_concepts(ConceptIds, MaxTier, Markers) :-
    findall(marker(ConceptId, Level, Phrases, Citation, Tier),
            ( member(ConceptId, ConceptIds),
              van_hiele_marker_projection(ConceptId,
                                          Level,
                                          Phrases,
                                          Citation,
                                          Tier),
              Tier =< MaxTier
            ),
            Raw),
    sort(Raw, Markers).

van_hiele_marker_projection(ConceptId, Level, Phrases, Citation, Tier) :-
    current_predicate(van_hiele_marker_witness/3),
    van_hiele_marker_witness(ConceptId, Level, Witness),
    get_dict(fact, Witness,
             van_hiele_marker(ConceptId, Level, Phrases, Citation)),
    get_dict(tier, Witness, Tier).
van_hiele_marker_projection(ConceptId, Level, Phrases, Citation, Tier) :-
    van_hiele_marker(ConceptId, Level, Phrases, Citation),
    \+ ( current_predicate(van_hiele_marker_witness/3),
         van_hiele_marker_witness(ConceptId, Level, _)
       ),
    tier_of(ref(van_hiele, ConceptId, Level), Tier).

developmental_arcs_for_concepts(ConceptIds, Arcs) :-
    findall(arc(ConceptId, Arc),
            ( member(ConceptId, ConceptIds),
              developmental_arc_for(ConceptId, Arc),
              Arc \= none
            ),
            Raw),
    sort(Raw, Arcs).
