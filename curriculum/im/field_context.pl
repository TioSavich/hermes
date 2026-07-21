/** <module> Lesson-scoped field context bundles
 *
 * A bounded integration surface for Hermes and teacher-facing tools.  The
 * module does not own standards, automata, misconceptions, literature facts, or
 * proof-path and incompatibility-breadth measures; it gathers the existing surfaces for one lesson
 * into a single JSON-safe dict with explicit provenance and coverage flags.
 */
:- module(field_context,
          [ field_context_dict/2,
            field_connectivity_audit_dict/1
          ]).

:- use_module(im_lessons(lesson_monitoring)).
:- use_module(strategies(inferential_strength)).
:- use_module(misconceptions(literature_vocabulary)).
:- use_module(misconceptions(literature_incompatibility_facts),
              [ lit_derived/9
              ]).
:- use_module(misconceptions(test_harness), []).
:- use_module(library(apply)).
:- use_module(library(lists)).
:- use_module(library(solution_sequences), [distinct/2]).


%!  field_context_dict(+LessonCode, -Dict) is semidet.
%
%   Dict is a lesson-scoped, JSON-safe context bundle.  The predicate is
%   intentionally bounded by LessonCode; broad global connectivity reports
%   belong in offline coverage jobs, not the live Hermes worker path.
field_context_dict(Code, Dict) :-
    lesson_monitoring:monitoring_chart_export(
        Code,
        monitoring_chart_export(Code,
                                Lesson,
                                Standards0,
                                Strategies0,
                                Misconceptions0,
                                PMLFacts,
                                Clusters0)
    ),
    lesson_dict(Lesson, LessonDict),
    map_sort(standard_dict, Standards0, Standards),
    map_sort(strategy_dict, Strategies0, Strategies),
    map_sort(misconception_dict, Misconceptions0, Misconceptions),
    field_context_clusters(Code, Clusters0, ClusterTerms),
    map_sort(cluster_dict, ClusterTerms, Clusters),
    coverage_dicts(PMLFacts, Coverage),
    coverage_status(Coverage, CoverageStatus),
    inferential_strength_dict(Code, InferentialStrength),
    literature_summary_dict(Literature),
    lesson_literature_dict(Misconceptions, LessonLiterature),
    lesson_readiness_dict(Code, Readiness),
    field_brief_dict(Code, LessonDict, Readiness, InferentialStrength,
                     LessonLiterature, Brief),
    term_text(Code, CodeText),
    Dict0 = _{
        lesson_code: CodeText,
        lesson: LessonDict,
        coverage_status: CoverageStatus,
        field_brief: Brief,
        readiness: Readiness,
        coverage: Coverage,
        standards: Standards,
        strategies: Strategies,
        misconceptions: Misconceptions,
        lesson_literature: LessonLiterature,
        literature: Literature,
        inferential_strength: InferentialStrength,
        monitoring_clusters: Clusters
    },
    (   lesson_monitoring:lesson_guide_context_dict(Code, GuideContext)
    ->  Dict = Dict0.put(GuideContext)
    ;   Dict = Dict0
    ).


field_brief_dict(Code, Lesson, Readiness, InferentialStrength,
                 LessonLiterature, Brief) :-
    get_dict(status, Readiness, Status),
    get_dict(next_actions, Readiness, NextActions),
    get_dict(missing, Readiness, Missing),
    get_dict(counts, Readiness, Counts),
    get_dict(proof_paths, InferentialStrength, ProofPaths),
    get_dict(citation_count, LessonLiterature, CitationCount),
    get_dict(title, Lesson, Title),
    field_brief_status(Status, BriefStatus, Label),
    field_brief_primary_action(Status, Missing, NextActions, PrimaryAction),
    field_brief_evidence_points(Status, Missing, Counts, ProofPaths,
                                CitationCount, EvidencePoints),
    term_text(Code, CodeText),
    format(string(Headline), "~w: ~w", [CodeText, Title]),
    Brief = _{
        status: BriefStatus,
        label: Label,
        headline: Headline,
        primary_action: PrimaryAction,
        evidence_points: EvidencePoints
    }.


field_brief_status("fully_connected", "ready_exemplar", "Ready to inspect") :-
    !.
field_brief_status("under_attached", "under_attached", "Under attached") :-
    !.
field_brief_status(_, "repair_candidate", "Needs repair").


field_brief_primary_action("fully_connected", _Missing, _NextActions,
                           "Inspect this lesson as a field exemplar.") :-
    !.
field_brief_primary_action(_Status, Missing, _NextActions, Action) :-
    primary_repair_action(Missing, Action),
    !.
field_brief_primary_action(_Status, _Missing, [Action|_Rest], Action) :-
    !.
field_brief_primary_action(_, _, _, "Inspect the raw context and add the first missing field link.").


primary_repair_action(Missing, "Attach at least one standards anchor.") :-
    memberchk("standards", Missing),
    !.
primary_repair_action(Missing, "Attach a lesson-level CCSS standard or document why only unit-level alignment is available.") :-
    memberchk("ccss", Missing),
    !.
primary_repair_action(Missing, "Add explicit strategy automata evidence from the lesson text.") :-
    (   memberchk("strategies", Missing)
    ;   memberchk("strategy_automata", Missing)
    ),
    !.
primary_repair_action(Missing, "Add explicit misconception or deformation evidence with citation.") :-
    memberchk("misconceptions", Missing),
    !.
primary_repair_action(Missing, "Link at least one misconception to normalized literature or a runnable source row.") :-
    memberchk("literature_links", Missing),
    !.
primary_repair_action(Missing, "Map linked literature to at least one canonical incompatibility commitment.") :-
    memberchk("canonical_literature_commitments", Missing),
    !.
primary_repair_action(Missing, "Pair at least one strategy with one misconception so incompatibility breadth can be computed.") :-
    memberchk("inferential_strength", Missing),
    !.
primary_repair_action(Missing, "Attach a monitoring cluster with productive core and deformation.") :-
    (   memberchk("monitoring_clusters", Missing)
    ;   memberchk("deformations", Missing)
    ).


field_brief_evidence_points("fully_connected", _Missing, Counts, ProofPaths,
                            CitationCount,
                            ["All field graph dimensions are connected.",
                             CountsText,
                             ProofText]) :-
    !,
    format(string(CountsText),
           "Automata: ~w; misconceptions: ~w; canonical literature: ~w; deformations: ~w; citations: ~w.",
           [Counts.strategy_automata,
            Counts.misconceptions,
            Counts.canonical_literature_commitments,
            Counts.deformations,
            CitationCount]),
    format(string(ProofText),
           "Bounded proof paths: ~w.",
           [ProofPaths]).
field_brief_evidence_points(_Status, Missing, Counts, _ProofPaths,
                            CitationCount,
                            [MissingText, CountsText]) :-
    atomic_list_concat(Missing, ', ', MissingAtom),
    atom_string(MissingAtom, MissingList),
    format(string(MissingText), "Missing: ~w", [MissingList]),
    format(string(CountsText),
           "Connected now: standards ~w, CCSS ~w, monitoring clusters ~w, deformations ~w, citations ~w.",
           [Counts.standards,
            Counts.ccss,
            Counts.monitoring_clusters,
            Counts.deformations,
            CitationCount]).


:- dynamic lesson_readiness_inputs_cache/5.

lesson_readiness_inputs(Codes,
                        StrategyPairs,
                        MisconceptionPairs,
                        ClusterPairs,
                        LiteratureLinkPairs) :-
    lesson_readiness_inputs_cache(Codes,
                                  StrategyPairs,
                                  MisconceptionPairs,
                                  ClusterPairs,
                                  LiteratureLinkPairs),
    !.
lesson_readiness_inputs(Codes,
                        StrategyPairs,
                        MisconceptionPairs,
                        ClusterPairs,
                        LiteratureLinkPairs) :-
    findall(EncodedCode,
            lesson_monitoring:encoded_lesson(EncodedCode, _Concept, _Title, _Grade, _Unit, _Lesson),
            Codes0),
    sort(Codes0, Codes),
    audit_strategy_pairs(StrategyPairs),
    audit_misconception_pairs(MisconceptionPairs),
    audit_cluster_pairs(Codes, ClusterPairs),
    audit_literature_link_pairs(LiteratureLinkPairs),
    assertz(lesson_readiness_inputs_cache(Codes,
                                          StrategyPairs,
                                          MisconceptionPairs,
                                          ClusterPairs,
                                          LiteratureLinkPairs)).


lesson_readiness_dict(Code, Readiness) :-
    lesson_readiness_inputs(_Codes,
                            StrategyPairs,
                            MisconceptionPairs,
                            ClusterPairs,
                            LiteratureLinkPairs),
    lesson_connectivity_row(StrategyPairs,
                            MisconceptionPairs,
                            ClusterPairs,
                            LiteratureLinkPairs,
                            Code,
                            Row),
    !,
    readiness_dict_from_row(Row, Readiness).
lesson_readiness_dict(_, _{
    status: "unknown",
    coverage_status: "unknown",
    missing: [],
    next_actions: [],
    counts: _{}
}).


field_context_clusters(Code, DirectClusters, Clusters) :-
    findall(Cluster,
            fallback_cluster_for_lesson(Code, DirectClusters, Cluster),
            FallbackClusters0),
    sort(FallbackClusters0, FallbackClusters),
    append(DirectClusters, FallbackClusters, Combined),
    sort(Combined, Clusters).


fallback_cluster_for_lesson(Code, DirectClusters, chart_cluster(Source, ClusterId, Info)) :-
    lesson_monitoring:lesson_unit_anchor(Code, UnitAnchor),
    lesson_monitoring:monitoring_cluster_source(Source, RelativePath),
    lesson_monitoring:monitoring_cluster_dict(RelativePath, Cluster),
    lesson_monitoring:dict_value(Cluster, im_anchors, Anchors),
    lesson_monitoring:cluster_anchor_matches(Code, UnitAnchor, Anchors),
    lesson_monitoring:dict_value(Cluster, id, ClusterId),
    lesson_monitoring:cluster_info(Cluster, Info0),
    \+ memberchk(chart_cluster(Source, ClusterId, Info0), DirectClusters),
    Info = [evidence_level(unit_cluster_fallback)|Info0].


readiness_dict_from_row(Row, _{
    status: Status,
    coverage_status: CoverageStatus,
    missing: Missing,
    next_actions: NextActions,
    counts: Counts,
    has_standards: HasStandards,
    has_ccss: HasCCSS,
    has_strategies: HasStrategies,
    has_strategy_automata: HasStrategyAutomata,
    has_misconceptions: HasMisconceptions,
    has_literature_links: HasLiteratureLinks,
    has_canonical_literature_commitments: HasCanonicalLiteratureCommitments,
    has_inferential_strength: HasInferentialStrength,
    has_monitoring_clusters: HasMonitoringClusters,
    has_deformations: HasDeformations
}) :-
    get_dict(status, Row, Status),
    get_dict(coverage_status, Row, CoverageStatus),
    get_dict(missing, Row, Missing),
    get_dict(next_actions, Row, NextActions),
    get_dict(counts, Row, Counts),
    get_dict(has_standards, Row, HasStandards),
    get_dict(has_ccss, Row, HasCCSS),
    get_dict(has_strategies, Row, HasStrategies),
    get_dict(has_strategy_automata, Row, HasStrategyAutomata),
    get_dict(has_misconceptions, Row, HasMisconceptions),
    get_dict(has_literature_links, Row, HasLiteratureLinks),
    get_dict(has_canonical_literature_commitments, Row, HasCanonicalLiteratureCommitments),
    get_dict(has_inferential_strength, Row, HasInferentialStrength),
    get_dict(has_monitoring_clusters, Row, HasMonitoringClusters),
    get_dict(has_deformations, Row, HasDeformations).


%!  field_connectivity_audit_dict(-Dict) is det.
%
%   Dict summarizes cross-layer wiring across encoded lessons. This is a
%   coverage/audit surface, not a claim that every lesson is fully ready for
%   field use.
:- dynamic field_connectivity_audit_cache/1.

%   Memoized: the audit walks ~1300 lessons and computes real per-lesson
%   standard counts (lesson_standard/4 must be queried bound, ~tens of ms each),
%   so the full pass takes ~1 minute. The KB is static at runtime, so the result
%   is cached on the persistent worker and returned instantly thereafter.
field_connectivity_audit_dict(Dict) :-
    field_connectivity_audit_cache(Dict),
    !.
field_connectivity_audit_dict(Dict) :-
    field_connectivity_audit_compute(Dict),
    assertz(field_connectivity_audit_cache(Dict)).

field_connectivity_audit_compute(_{
    summary: Summary,
    dimensions: Dimensions,
    action_priorities: ActionPriorities,
    connected_examples: ConnectedExamples,
    lessons: Rows,
    review_lessons: ReviewRows
}) :-
    findall(Code,
            lesson_monitoring:encoded_lesson(Code, _Concept, _Title, _Grade, _Unit, _Lesson),
            Codes0),
    sort(Codes0, Codes),
    audit_strategy_pairs(StrategyPairs),
    audit_misconception_pairs(MisconceptionPairs),
    audit_cluster_pairs(Codes, ClusterPairs),
    audit_literature_link_pairs(LiteratureLinkPairs),
    maplist(lesson_connectivity_row(StrategyPairs,
                                    MisconceptionPairs,
                                    ClusterPairs,
                                    LiteratureLinkPairs),
            Codes,
            Rows),
    audit_summary(Rows, Summary),
    audit_dimensions(Rows, Dimensions),
    audit_action_priorities(Rows, ActionPriorities),
    include(connected_lesson_row, Rows, ConnectedExamples),
    include(review_lesson_row, Rows, ReviewRows0),
    take_n(25, ReviewRows0, ReviewRows).


lesson_connectivity_row(StrategyPairs,
                        MisconceptionPairs,
                        ClusterPairs,
                        LiteratureLinkPairs,
                        Code,
                        Row) :-
    lesson_monitoring:encoded_lesson(Code, ConceptId, Title, grade(Grade), unit(Unit), lesson(LessonNumber)),
    items_for_code(Code, StrategyPairs, Strategies),
    items_for_code(Code, MisconceptionPairs, Misconceptions),
    items_for_code(Code, ClusterPairs, Clusters),
    audit_standard_counts(Code, Grade, StandardCount, CCSSCount),
    length(Strategies, StrategyCount),
    strategy_automata_count(Strategies, StrategyAutomataCount),
    length(Misconceptions, MisconceptionCount),
    literature_link_count(Misconceptions, LiteratureLinkPairs, LiteratureLinkCount),
    canonical_literature_commitment_count(Misconceptions,
                                          LiteratureLinkPairs,
                                          CanonicalLiteratureCommitmentCount),
    length(Clusters, ClusterCount),
    deformation_count(Clusters, DeformationCount),
    audit_coverage_status(StrategyCount, MisconceptionCount, ClusterCount, CoverageStatus),
    audit_inferential_strength_candidate_count(StrategyCount, MisconceptionCount, InferentialStrengthCandidates),
    bool_count(StandardCount, HasStandards),
    bool_count(CCSSCount, HasCCSS),
    bool_count(StrategyCount, HasStrategies),
    bool_count(StrategyAutomataCount, HasStrategyAutomata),
    bool_count(MisconceptionCount, HasMisconceptions),
    bool_count(LiteratureLinkCount, HasLiteratureLinks),
    bool_count(CanonicalLiteratureCommitmentCount, HasCanonicalLiteratureCommitments),
    bool_count(InferentialStrengthCandidates, HasInferentialStrength),
    bool_count(ClusterCount, HasMonitoringClusters),
    bool_count(DeformationCount, HasDeformations),
    missing_dimensions(_{
        standards: StandardCount,
        ccss: CCSSCount,
        strategies: StrategyCount,
        strategy_automata: StrategyAutomataCount,
        misconceptions: MisconceptionCount,
        literature_links: LiteratureLinkCount,
        canonical_literature_commitments: CanonicalLiteratureCommitmentCount,
        inferential_strength: InferentialStrengthCandidates,
        monitoring_clusters: ClusterCount,
        deformations: DeformationCount
    }, Missing),
    row_status(CoverageStatus, Missing, Status),
    next_actions(Missing, NextActions),
    term_text(Code, CodeText),
    term_text(ConceptId, ConceptText),
    term_text(Title, TitleText),
    Row = _{
        lesson_code: CodeText,
        concept_id: ConceptText,
        title: TitleText,
        grade: Grade,
        unit: Unit,
        lesson_number: LessonNumber,
        status: Status,
        coverage_status: CoverageStatus,
        has_standards: HasStandards,
        has_ccss: HasCCSS,
        has_strategies: HasStrategies,
        has_strategy_automata: HasStrategyAutomata,
        has_misconceptions: HasMisconceptions,
        has_literature_links: HasLiteratureLinks,
        has_canonical_literature_commitments: HasCanonicalLiteratureCommitments,
        has_inferential_strength: HasInferentialStrength,
        has_monitoring_clusters: HasMonitoringClusters,
        has_deformations: HasDeformations,
        counts: _{
            standards: StandardCount,
            ccss: CCSSCount,
            strategies: StrategyCount,
            strategy_automata: StrategyAutomataCount,
            misconceptions: MisconceptionCount,
            literature_links: LiteratureLinkCount,
            canonical_literature_commitments: CanonicalLiteratureCommitmentCount,
            inferential_strength_candidates: InferentialStrengthCandidates,
            monitoring_clusters: ClusterCount,
            deformations: DeformationCount
        },
        missing: Missing,
        next_actions: NextActions
    }.


% Real per-lesson standard counts. StandardCount is distinct real standards
% (im_lesson anchors excluded); CCSSCount is distinct ccss-framework standards.
audit_standard_counts(Code, _Grade, StandardCount, CCSSCount) :-
    real_lesson_standards(Code, Pairs),
    length(Pairs, StandardCount),
    findall(StandardCode, member(ccss-StandardCode, Pairs), CCSSCodes),
    length(CCSSCodes, CCSSCount).


%!  real_lesson_standards(+Code, -SortedPairs) is det.
%
%   Distinct real (non-im_lesson) standards for a lesson, as Framework-Code
%   pairs. lesson_standard/4 CANNOT be used here: its im_lesson clauses
%   backtrack over duplicated im_lesson/6 facts and emit tens of thousands of
%   redundant rows per lesson (~210ms each), which made both the single-lesson
%   readiness check and the 1300-lesson audit pathologically slow. This reads
%   the underlying sources once — explicit facts plus a single im_lesson
%   concept's loaded_standard_anchor entries, de-duplicated — at ~1ms/lesson.
real_lesson_standards(Code, Sorted) :-
    findall(Framework-StandardCode,
            real_lesson_standard_src(Code, Framework, StandardCode),
            Raw),
    sort(Raw, Sorted).

real_lesson_standard_src(Code, Framework, StandardCode) :-
    lesson_monitoring:explicit_lesson_standard(Code, Framework, StandardCode, _Statement),
    Framework \== im_lesson.
real_lesson_standard_src(Code, Framework, StandardCode) :-
    once(lesson_monitoring:im_lesson(Code, ConceptId, _, _, _, _)),
    distinct(Framework-StandardCode,
             ( lesson_monitoring:loaded_standard_anchor(ConceptId, Framework, StandardCode, _Statement),
               Framework \== im_lesson )).


% The audit's strategy/misconception presence counts the EXPLICIT,
% text-evidenced attachments only. Enumerating lesson_strategy/4 with an
% unbound Code (which would also pull in cluster fallback) is O(lessons ×
% clusters) and hangs the audit over ~1300 lessons, so cluster-attached
% content is reflected through the separate monitoring_clusters dimension and
% coverage_status = "unit_cluster_fallback" instead.
audit_strategy_pairs(Pairs) :-
    findall(Code-strategy(Operation, Kind, Info),
            lesson_monitoring:explicit_lesson_strategy(Code, Operation, Kind, Info),
            Pairs0),
    sort(Pairs0, Pairs).


% Memoized: enumerating explicit_lesson_misconception/4 over the whole corpus
% takes ~5.5s and is recomputed on EVERY field_context call (lesson readiness)
% as well as the audit. The facts are static at runtime, so the persistent
% worker computes the set once — cutting ~5s off every lesson-open after the
% first.
:- dynamic audit_misconception_pairs_cache/1.

audit_misconception_pairs(Pairs) :-
    audit_misconception_pairs_cache(Pairs),
    !.
audit_misconception_pairs(Pairs) :-
    findall(Code-misconception(Operation, Name, Info),
            lesson_monitoring:explicit_lesson_misconception(Code, Operation, Name, Info),
            Pairs0),
    sort(Pairs0, Pairs),
    assertz(audit_misconception_pairs_cache(Pairs)).


audit_cluster_pairs(Codes, ClusterPairs) :-
    findall(Code-UnitAnchor,
            ( member(Code, Codes),
              lesson_monitoring:lesson_unit_anchor(Code, UnitAnchor)
            ),
            LessonAnchors),
    findall(Code-chart_cluster(Source, ClusterId, Info),
            ( lesson_monitoring:monitoring_cluster_source(Source, RelativePath),
              lesson_monitoring:monitoring_cluster_dict(RelativePath, Cluster),
              lesson_monitoring:dict_value(Cluster, im_anchors, Anchors),
              member(Code-UnitAnchor, LessonAnchors),
              lesson_monitoring:cluster_anchor_matches(Code, UnitAnchor, Anchors),
              lesson_monitoring:dict_value(Cluster, id, ClusterId),
              lesson_monitoring:cluster_info(Cluster, Info)
            ),
            ClusterPairs0),
    sort(ClusterPairs0, ClusterPairs).


audit_literature_link_pairs(Pairs) :-
    findall(Name-Id,
            ( lit_derived(Id, _RawDomain, _Topic, _StudentRule, _ValidDomain,
                          _RawCommitment, _Orientation, _CarspeckenScene, _Confidence),
              atom(Id),
              catch(atom_number(Id, RowId), _Error, fail),
              test_harness:arith_misconception(db_row(RowId),
                                               _HarnessDomain,
                                               Name,
                                               Rule,
                                               _Input,
                                               _Expected),
              Rule \== skip
            ),
            Pairs0),
    sort(Pairs0, Pairs).


items_for_code(Code, Pairs, Items) :-
    findall(Item,
            member(Code-Item, Pairs),
            Items).


ccss_count(Standards, Count) :-
    findall(Code,
            member(standard(ccss, Code, _Statement), Standards),
            Codes0),
    sort(Codes0, Codes),
    length(Codes, Count).


strategy_automata_count(Strategies, Count) :-
    findall(Ref,
            ( member(strategy(_Operation, _Kind, Info), Strategies),
              member(automaton_ref(Ref), Info)
            ),
            Refs0),
    sort(Refs0, Refs),
    length(Refs, Count).


literature_link_count(Misconceptions, LiteratureLinkPairs, Count) :-
    findall(Id-Name,
            ( member(misconception(_Operation, Name, _Info), Misconceptions),
              member(Name-Id, LiteratureLinkPairs)
            ),
            Links0),
    sort(Links0, Links),
    length(Links, Count).


canonical_literature_commitment_count(Misconceptions, LiteratureLinkPairs, Count) :-
    findall(Commitment,
            ( member(misconception(_Operation, Name, _Info), Misconceptions),
              member(Name-Id, LiteratureLinkPairs),
              literature_vocabulary:lit_incompatibility(Id, _CanonDomain,
                                                         Commitment,
                                                         _StudentRule,
                                                         _ValidDomain,
                                                         _Orientation,
                                                         _Confidence),
              Commitment \== uncategorized
            ),
            Commitments0),
    sort(Commitments0, Commitments),
    length(Commitments, Count).


deformation_count(Clusters, Count) :-
    findall(Deformation,
            ( member(chart_cluster(_Source, _ClusterId, Info), Clusters),
              member(deformation(Deformation), Info),
              term_text(Deformation, DeformationText),
              DeformationText \== "",
              Deformation \== none
            ),
            Deformations0),
    sort(Deformations0, Deformations),
    length(Deformations, Count).


audit_coverage_status(StrategyCount, MisconceptionCount, _ClusterCount, "usable") :-
    (   StrategyCount > 0
    ;   MisconceptionCount > 0
    ),
    !.
audit_coverage_status(_StrategyCount, _MisconceptionCount, ClusterCount, "unit_cluster_fallback") :-
    ClusterCount > 0,
    !.
audit_coverage_status(_, _, _, "under_attached").


audit_inferential_strength_candidate_count(StrategyCount, MisconceptionCount, CandidateCount) :-
    StrategyCount > 0,
    MisconceptionCount > 0,
    !,
    CandidateCount is StrategyCount * MisconceptionCount.
audit_inferential_strength_candidate_count(_, _, 0).


bool_count(Count, true) :-
    Count > 0,
    !.
bool_count(_, false).


missing_dimensions(Counts, Missing) :-
    findall(KeyText,
            ( missing_dimension(Key, Counts),
              atom_string(Key, KeyText)
            ),
            Missing).


missing_dimension(standards, Counts) :-
    Counts.standards =:= 0.
missing_dimension(ccss, Counts) :-
    Counts.ccss =:= 0.
missing_dimension(strategies, Counts) :-
    Counts.strategies =:= 0.
missing_dimension(strategy_automata, Counts) :-
    Counts.strategy_automata =:= 0.
missing_dimension(misconceptions, Counts) :-
    Counts.misconceptions =:= 0.
missing_dimension(literature_links, Counts) :-
    Counts.literature_links =:= 0.
missing_dimension(canonical_literature_commitments, Counts) :-
    Counts.canonical_literature_commitments =:= 0.
missing_dimension(inferential_strength, Counts) :-
    Counts.inferential_strength =:= 0.
missing_dimension(monitoring_clusters, Counts) :-
    Counts.monitoring_clusters =:= 0.
missing_dimension(deformations, Counts) :-
    Counts.deformations =:= 0.


row_status("under_attached", _Missing, "under_attached") :-
    !.
row_status(_CoverageStatus, [], "fully_connected") :-
    !.
row_status(_, _, "review").


next_actions(Missing, Actions) :-
    findall(Action,
            next_action_for_missing(Missing, Action),
            Actions0),
    sort(Actions0, Actions).


next_action_for_missing(Missing, "Attach at least one standards anchor.") :-
    memberchk("standards", Missing).
next_action_for_missing(Missing, "Attach a lesson-level CCSS standard or document why only unit-level alignment is available.") :-
    memberchk("ccss", Missing).
next_action_for_missing(Missing, "Add explicit strategy automata evidence from the lesson text.") :-
    (   memberchk("strategies", Missing)
    ;   memberchk("strategy_automata", Missing)
    ).
next_action_for_missing(Missing, "Add explicit misconception or deformation evidence with citation.") :-
    memberchk("misconceptions", Missing).
next_action_for_missing(Missing, "Link at least one misconception to normalized literature or a runnable source row.") :-
    memberchk("literature_links", Missing).
next_action_for_missing(Missing, "Map linked literature to at least one canonical incompatibility commitment.") :-
    memberchk("canonical_literature_commitments", Missing),
    \+ memberchk("literature_links", Missing).
next_action_for_missing(Missing, "Pair at least one strategy with one misconception so incompatibility breadth can be computed.") :-
    memberchk("inferential_strength", Missing).
next_action_for_missing(Missing, "Attach a monitoring cluster with productive core and deformation.") :-
    (   memberchk("monitoring_clusters", Missing)
    ;   memberchk("deformations", Missing)
    ).


audit_summary(Rows, _{
    total_lessons: Total,
    usable_lessons: Usable,
    fully_connected_lessons: FullyConnected,
    review_lessons: Review,
    under_attached_lessons: UnderAttached,
    lessons_with_standards: WithStandards,
    lessons_with_ccss: WithCCSS,
    lessons_with_strategies: WithStrategies,
    lessons_with_strategy_automata: WithStrategyAutomata,
    lessons_with_misconceptions: WithMisconceptions,
    lessons_with_literature_links: WithLiteratureLinks,
    lessons_with_canonical_literature_commitments: WithCanonicalLiteratureCommitments,
    lessons_with_inferential_strength: WithInferentialStrength,
    lessons_with_monitoring_clusters: WithMonitoringClusters,
    lessons_with_deformations: WithDeformations
}) :-
    length(Rows, Total),
    count_row_status(Rows, "fully_connected", FullyConnected),
    count_row_status(Rows, "review", Review),
    count_row_status(Rows, "under_attached", UnderAttached),
    count_coverage_status(Rows, "usable", Usable),
    count_bool_field(Rows, has_standards, WithStandards),
    count_bool_field(Rows, has_ccss, WithCCSS),
    count_bool_field(Rows, has_strategies, WithStrategies),
    count_bool_field(Rows, has_strategy_automata, WithStrategyAutomata),
    count_bool_field(Rows, has_misconceptions, WithMisconceptions),
    count_bool_field(Rows, has_literature_links, WithLiteratureLinks),
    count_bool_field(Rows, has_canonical_literature_commitments, WithCanonicalLiteratureCommitments),
    count_bool_field(Rows, has_inferential_strength, WithInferentialStrength),
    count_bool_field(Rows, has_monitoring_clusters, WithMonitoringClusters),
    count_bool_field(Rows, has_deformations, WithDeformations).


audit_dimensions(Rows, Dimensions) :-
    findall(Dimension,
            dimension_dict(Rows, Dimension),
            Dimensions).


dimension_spec("standards", "Standards", has_standards).
dimension_spec("ccss", "CCSS anchors", has_ccss).
dimension_spec("strategies", "Strategy rows", has_strategies).
dimension_spec("strategy_automata", "Strategy automata", has_strategy_automata).
dimension_spec("misconceptions", "Misconception rows", has_misconceptions).
dimension_spec("literature_links", "Literature links", has_literature_links).
dimension_spec("canonical_literature_commitments", "Canonical literature", has_canonical_literature_commitments).
dimension_spec("inferential_strength", "Inferential strength", has_inferential_strength).
dimension_spec("monitoring_clusters", "Monitoring clusters", has_monitoring_clusters).
dimension_spec("deformations", "Deformations", has_deformations).


dimension_dict(Rows, _{
    key: Key,
    label: Label,
    connected: Connected,
    missing: Missing
}) :-
    dimension_spec(Key, Label, Field),
    length(Rows, Total),
    count_bool_field(Rows, Field, Connected),
    Missing is Total - Connected.


audit_action_priorities(Rows, Priorities) :-
    findall(Action,
            ( member(Row, Rows),
              get_dict(next_actions, Row, Actions),
              member(Action, Actions)
            ),
            Actions0),
    sort(Actions0, Actions),
    findall(Count-Action-ExampleLessons,
            ( member(Action, Actions),
              action_priority_counts(Action, Rows, Count, ExampleLessons)
            ),
            PriorityTerms0),
    predsort(compare_action_priority, PriorityTerms0, PriorityTerms),
    maplist(action_priority_dict, PriorityTerms, Priorities).


action_priority_counts(Action, Rows, Count, ExampleLessons) :-
    findall(Code,
            ( member(Row, Rows),
              get_dict(next_actions, Row, Actions),
              member(Action, Actions),
              get_dict(lesson_code, Row, Code)
            ),
            Codes0),
    sort(Codes0, Codes),
    length(Codes, Count),
    take_n(5, Codes, ExampleLessons).


compare_action_priority(<, CountA-_ActionA-_, CountB-_ActionB-_) :-
    CountA > CountB,
    !.
compare_action_priority(>, CountA-_ActionA-_, CountB-_ActionB-_) :-
    CountA < CountB,
    !.
compare_action_priority(Order, _CountA-ActionA-_, _CountB-ActionB-_) :-
    compare(Order, ActionA, ActionB).


action_priority_dict(Count-Action-ExampleLessons, _{
    action: Action,
    count: Count,
    example_lessons: ExampleLessons
}).


count_bool_field(Rows, Field, Count) :-
    include(row_bool_field(Field), Rows, Matches),
    length(Matches, Count).


row_bool_field(Field, Row) :-
    get_dict(Field, Row, true).


count_row_status(Rows, Status, Count) :-
    include(row_status_is(Status), Rows, Matches),
    length(Matches, Count).


row_status_is(Status, Row) :-
    get_dict(status, Row, Status).


count_coverage_status(Rows, Status, Count) :-
    include(row_coverage_status_is(Status), Rows, Matches),
    length(Matches, Count).


row_coverage_status_is(Status, Row) :-
    get_dict(coverage_status, Row, Status).


review_lesson_row(Row) :-
    get_dict(status, Row, Status),
    Status \== "fully_connected".


connected_lesson_row(Row) :-
    get_dict(status, Row, "fully_connected").


take_n(_, [], []) :-
    !.
take_n(N, _List, []) :-
    N =< 0,
    !.
take_n(N, [Head|Tail], [Head|Rest]) :-
    N1 is N - 1,
    take_n(N1, Tail, Rest).


map_sort(Predicate, Terms, Dicts) :-
    Goal =.. [Predicate],
    maplist(Goal, Terms, Dicts0),
    sort(Dicts0, Dicts).


lesson_dict(lesson(ConceptId, Title, grade(Grade), unit(Unit), lesson(LessonNumber)),
            _{
                concept_id: ConceptText,
                title: TitleText,
                grade: Grade,
                unit: Unit,
                lesson_number: LessonNumber
            }) :-
    term_text(ConceptId, ConceptText),
    term_text(Title, TitleText).


standard_dict(standard(Framework, Code, Statement),
              _{
                  framework: FrameworkText,
                  code: CodeText,
                  statement: StatementText,
                  evidence_level: EvidenceLevel
              }) :-
    term_text(Framework, FrameworkText),
    term_text(Code, CodeText),
    term_text(Statement, StatementText),
    standard_evidence_level(Framework, EvidenceLevel).

standard_evidence_level(im_lesson, "lesson_anchor") :- !.
standard_evidence_level(_, "standard_anchor").


strategy_dict(strategy(Operation, Kind, Info),
              _{
                  operation: OperationText,
                  kind: KindText,
                  provenance: ProvenanceText,
                  evidence_level: EvidenceLevel,
                  source: SourceText,
                  cluster: ClusterText,
                  automata: AutomataTexts,
                  vocabulary: VocabularyTexts,
                  commitment_made: CommitmentText,
                  entitlement_granted: EntitlementText
              }) :-
    term_text(Operation, OperationText),
    term_text(Kind, KindText),
    provenance_text(Info, ProvenanceText),
    evidence_level(Info, EvidenceLevel),
    source_text(Info, SourceText),
    info_text(Info, cluster, ClusterText),
    info_term_texts(Info, automaton_ref, AutomataTexts),
    info_list_texts(Info, vocabulary, VocabularyTexts),
    info_text(Info, commitment_made, CommitmentText),
    info_text(Info, entitlement_granted, EntitlementText).


% misconception_dict/2 reads a misconception's commitment_made / entitlement_lacked
% / incompatibility from its registry Info list (info_text/3). These are static
% per-misconception facts describing the misconception's structure in deontic
% vocabulary. They are not produced by the live deontic scorekeeper
% (formal/learner/deontic_scorekeeper.pl, exposed by hermes_worker.pl as the
% deontic_scorecard / deontic_consequences / deontic_up_level ops): this path
% runs no consequence propagation and no incompatible/2 closure.
misconception_dict(misconception(Operation, Name, Info),
                   _{
                       operation: OperationText,
                       name: NameText,
                       provenance: ProvenanceText,
                       evidence_level: EvidenceLevel,
                       source: SourceText,
                       citation: CitationText,
                       commitment_made: CommitmentText,
                       entitlement_lacked: EntitlementText,
                       incompatibility: IncompatibilityText,
                       discovered_incompatibility_sets: DiscoveredSets,
                       literature_links: LiteratureLinks
                   }) :-
    term_text(Operation, OperationText),
    term_text(Name, NameText),
    provenance_text(Info, ProvenanceText),
    evidence_level(Info, EvidenceLevel),
    source_text(Info, SourceText),
    citation_text(Info, CitationText),
    info_text(Info, commitment_made, CommitmentText),
    info_text(Info, entitlement_lacked, EntitlementText),
    info_text(Info, incompatibility, IncompatibilityText),
    discovered_set_texts(Info, DiscoveredSets),
    literature_links(Name, LiteratureLinks).


cluster_dict(chart_cluster(Source, ClusterId, Info),
             _{
                 source: SourceText,
                 id: ClusterIdText,
                 evidence_level: EvidenceLevel,
                 title: TitleText,
                 productive_core: ProductiveCoreText,
                 deformation: DeformationText,
                 assessing_questions: AssessingQuestions,
                 advancing_questions: AdvancingQuestions,
                 standards: Standards,
                 im_anchors: IMAnchors
             }) :-
    term_text(Source, SourceText),
    term_text(ClusterId, ClusterIdText),
    cluster_evidence_level(Info, EvidenceLevel),
    info_text(Info, title, TitleText),
    info_text(Info, productive_core, ProductiveCoreText),
    info_text(Info, deformation, DeformationText),
    info_list_texts(Info, assessing_questions, AssessingQuestions),
    info_list_texts(Info, advancing_questions, AdvancingQuestions),
    info_list_texts(Info, standards, Standards),
    info_list_texts(Info, im_anchors, IMAnchors).


cluster_evidence_level(Info, EvidenceLevel) :-
    info_value(Info, evidence_level, Value),
    !,
    term_text(Value, EvidenceLevel).
cluster_evidence_level(_, "cluster").


coverage_dicts(PMLFacts, Coverage) :-
    findall(_{status: StatusText, evidence_level: "coverage"},
            ( member(coverage(Status), PMLFacts),
              term_text(Status, StatusText)
            ),
            Coverage0),
    sort(Coverage0, Coverage).

coverage_status(Coverage, "under_attached") :-
    member(Row, Coverage),
    get_dict(status, Row, Status),
    sub_string(Status, 0, _, _, "under_attached"),
    !.
coverage_status(Coverage, "usable") :-
    Coverage \== [],
    !.
coverage_status(_, "unknown").


inferential_strength_dict(Code, Dict) :-
    inferential_strength:lesson_inferential_strength_for(Code, Report),
    !,
    inferential_strength_report_dict(Report, Dict).
inferential_strength_dict(_, _{
    proof_paths: 0,
    strategy_incompatibilities: 0,
    strategy_incompatibilities_kind: "breadth_tally",
    misconception_incompatibilities: 0,
    misconception_incompatibilities_kind: "breadth_tally",
    incompatibility_note: "Counts include both binary clashes and the singleton sets wrapping them; treat as an upper bound, not distinct A-vs-B pairs.",
    per_operation: []
}).

inferential_strength_report_dict(
        report(paths(ProofPaths),
               strategy_incompatibility(StrategyIncompatibilities),
               misconception_incompatibility(MisconceptionIncompatibilities),
               per_operation(OpPowers),
               _PerStrategy,
               _PerMisconception),
        _{
            proof_paths: ProofPaths,
            strategy_incompatibilities: StrategyIncompatibilities,
            strategy_incompatibilities_kind: "breadth_tally",
            misconception_incompatibilities: MisconceptionIncompatibilities,
            misconception_incompatibilities_kind: "breadth_tally",
            incompatibility_note: "Counts include both binary clashes and the singleton sets wrapping them; treat as an upper bound, not distinct A-vs-B pairs.",
            per_operation: OperationDicts
        }) :-
    !,
    maplist(operation_power_dict, OpPowers, OperationDicts).
inferential_strength_report_dict(_, _{
    proof_paths: 0,
    strategy_incompatibilities: 0,
    strategy_incompatibilities_kind: "breadth_tally",
    misconception_incompatibilities: 0,
    misconception_incompatibilities_kind: "breadth_tally",
    incompatibility_note: "Counts include both binary clashes and the singleton sets wrapping them; treat as an upper bound, not distinct A-vs-B pairs.",
    per_operation: []
}).

operation_power_dict(Operation-region_paths(ProofPaths, Cells, SumDistinctCosts),
                     _{
                         operation: OperationText,
                         proof_paths: ProofPaths,
                         cells: Cells,
                         distinct_costs: SumDistinctCosts
                     }) :-
    term_text(Operation, OperationText).


:- dynamic literature_summary_cache/1.

literature_summary_dict(Dict) :-
    literature_summary_cache(Dict),
    !.
literature_summary_dict(Dict) :-
    literature_summary_uncached(Dict),
    assertz(literature_summary_cache(Dict)).


literature_summary_uncached(_{
    scope: "corpus_global",
    total_facts: Total,
    mapped_facts: Mapped,
    uncategorized_facts: Uncategorized,
    percent_mapped: PercentMapped,
    canonical_commitment_count: CanonicalCommitmentCount,
    top_commitments: TopCommitments,
    adjudicated_pairs: AdjudicatedPairs,
    adjudicated_fact_count: AdjudicatedFacts,
    linked_runnable_rows: LinkedRows,
    exact_runnable_rule_rows: ExactRows
}) :-
    literature_vocabulary:literature_mapping_stats(Total,
                                                   Mapped,
                                                   Uncategorized,
                                                   PercentMapped),
    aggregate_all(count,
                  literature_vocabulary:canonical_commitment(_, _),
                  CanonicalCommitmentCount),
    top_canonical_commitment_dicts(5, TopCommitments),
    literature_vocabulary:literature_adjudicated_count(AdjudicatedPairs),
    literature_vocabulary:literature_adjudicated_fact_count(AdjudicatedFacts),
    literature_vocabulary:linked_lit_incompatibility_count(LinkedRows),
    literature_vocabulary:linked_lit_incompatibility_exact_rule_count(ExactRows).


lesson_literature_dict(Misconceptions, _{
    scope: "this_lesson",
    citation_count: CitationCount,
    citations: Citations,
    linked_runnable_rows: LinkedRunnableRows,
    link_count: LinkCount,
    links: Links,
    canonical_commitments: CanonicalCommitments
}) :-
    findall(Citation,
            ( member(Misconception, Misconceptions),
              get_dict(citation, Misconception, Citation),
              Citation \== ""
            ),
            Citations0),
    sort(Citations0, Citations),
    length(Citations, CitationCount),
    findall(Link,
            ( member(Misconception, Misconceptions),
              get_dict(literature_links, Misconception, MisLinks),
              member(Link, MisLinks)
            ),
            Links0),
    sort(Links0, Links),
    length(Links, LinkCount),
    link_canonical_commitment_dicts(Links, CanonicalCommitments),
    findall(Source,
            ( member(Link, Links),
              get_dict(source, Link, Source),
              Source \== ""
            ),
            Sources0),
    sort(Sources0, Sources),
    length(Sources, LinkedRunnableRows).


literature_links(Name, Links) :-
    findall(Link,
            ( literature_vocabulary:linked_lit_incompatibility(Id, Name, Source),
              term_text(Id, IdText),
              term_text(Source, SourceText),
              literature_link_dict(Id, IdText, SourceText, Link)
            ),
            Links0),
    sort(Links0, Links).


literature_link_dict(Id, IdText, SourceText, _{
    id: IdText,
    source: SourceText,
    match: "shared_runnable_source",
    canonical_commitment: CanonicalText,
    canonical_commitment_label: LabelText,
    domain: DomainText,
    valid_domain: ValidDomainText,
    orientation: OrientationText,
    confidence: ConfidenceText,
    citation: CitationText,
    gloss: GlossText
}) :-
    literature_vocabulary:lit_incompatibility(Id, Domain, CanonicalCommitment,
                                              _StudentRule, ValidDomain,
                                              Orientation, Confidence),
    literature_vocabulary:lit_incompatibility_meta(Id, _BibtexKey,
                                                   Citation, Gloss),
    canonical_commitment_label(CanonicalCommitment, Label),
    term_text(CanonicalCommitment, CanonicalText),
    term_text(Label, LabelText),
    term_text(Domain, DomainText),
    term_text(ValidDomain, ValidDomainText),
    term_text(Orientation, OrientationText),
    term_text(Confidence, ConfidenceText),
    term_text(Citation, CitationText),
    term_text(Gloss, GlossText).


canonical_commitment_label(uncategorized, "Uncategorized generated commitment") :-
    !.
canonical_commitment_label(CanonicalCommitment, Label) :-
    literature_vocabulary:canonical_commitment(CanonicalCommitment, Label),
    !.
canonical_commitment_label(_, "").


top_canonical_commitment_dicts(Limit, TopDicts) :-
    findall(NegCount-Commitment-Label,
            ( literature_vocabulary:canonical_commitment(Commitment, Label),
              aggregate_all(count,
                            literature_vocabulary:lit_incompatibility(
                                _Id, _Domain, Commitment, _StudentRule,
                                _ValidDomain, _Orientation, _Confidence
                            ),
                            Count),
              Count > 0,
              NegCount is -Count
            ),
            Pairs0),
    sort(Pairs0, Pairs),
    take_n(Limit, Pairs, TopPairs),
    maplist(canonical_count_pair_dict, TopPairs, TopDicts).


link_canonical_commitment_dicts(Links, CanonicalCommitments) :-
    findall(Commitment-Label,
            ( member(Link, Links),
              get_dict(canonical_commitment, Link, Commitment),
              get_dict(canonical_commitment_label, Link, Label),
              Commitment \== ""
            ),
            Pairs0),
    sort(Pairs0, Pairs),
    findall(Dict,
            ( member(Commitment-Label, Pairs),
              aggregate_all(count,
                            member(Commitment-Label, Pairs0),
                            Count),
              canonical_commitment_summary_dict(Commitment, Label, Count, Dict)
            ),
            CanonicalCommitments).


canonical_count_pair_dict(NegCount-Commitment-Label, Dict) :-
    Count is -NegCount,
    term_text(Commitment, CommitmentText),
    term_text(Label, LabelText),
    canonical_commitment_summary_dict(CommitmentText, LabelText, Count, Dict).


canonical_commitment_summary_dict(CommitmentText, LabelText, Count, _{
    id: CommitmentText,
    label: LabelText,
    count: Count
}).


provenance_text(Info, Text) :-
    info_text(Info, provenance, Text0),
    ( Text0 == "" -> Text = "unspecified" ; Text = Text0 ).

evidence_level(Info, "explicit") :-
    info_value(Info, provenance, text_evidenced),
    !.
evidence_level(Info, Text) :-
    info_value(Info, provenance, Provenance),
    !,
    term_text(Provenance, Text).
evidence_level(Info, "cluster") :-
    member(source(cluster(_, _)), Info),
    !.
evidence_level(_, "unspecified").

source_text(Info, Text) :-
    info_text(Info, source, Text0),
    ( Text0 == "" -> Text = "explicit" ; Text = Text0 ).

citation_text(Info, Text) :-
    member(citation(Key, Note), Info),
    !,
    term_text(Key, KeyText),
    term_text(Note, NoteText),
    format(string(Text), "~s: ~s", [KeyText, NoteText]).
citation_text(Info, Text) :-
    member(citation(Citation), Info),
    !,
    term_text(Citation, Text).
citation_text(_, "").

discovered_set_texts(Info, Texts) :-
    findall(Text,
            ( member(incompatibility_set(discovered, Set), Info),
              term_text(Set, Text)
            ),
            Texts0),
    sort(Texts0, Texts).

info_text(Info, Functor, Text) :-
    info_value(Info, Functor, Value),
    !,
    term_text(Value, Text).
info_text(_, _, "").

info_list_texts(Info, Functor, Texts) :-
    info_value(Info, Functor, Values),
    is_list(Values),
    !,
    maplist(term_text, Values, Texts).
info_list_texts(_, _, []).

info_term_texts(Info, Functor, Texts) :-
    findall(Text,
            ( member(Term, Info),
              compound(Term),
              functor(Term, Functor, 1),
              arg(1, Term, Value),
              term_text(Value, Text)
            ),
            Texts0),
    sort(Texts0, Texts).

info_value(Info, Functor, Value) :-
    member(Term, Info),
    compound(Term),
    functor(Term, Functor, 1),
    arg(1, Term, Value),
    !.

term_text(Value, Text) :-
    string(Value),
    !,
    Text = Value.
term_text(Value, Text) :-
    atom(Value),
    !,
    atom_string(Value, Text).
term_text(Value, Text) :-
    number(Value),
    !,
    number_string(Value, Text).
% The deontic commitment terms that flow into a misconception's
% commitment_made / entitlement_lacked / incompatibility slots are compound
% Prolog terms (built in knowledge/misconceptions/misconception_registry.pl and
% curriculum/im/lesson_monitoring.pl). Without the clause below a term such as
% documented_batch_misconception(name, db_row(39498), note, op) reaches the
% field-context JSON, and the markdown export, as a raw Prolog term. The gloss
% mirrors the English produced by console.html glossTerm, so the worker output
% is teacher-legible before any frontend runs and the markdown and HTML
% surfaces agree. It sits ahead of the term_string/3 catch-all so a recognised
% commitment term is glossed; every other compound still falls through to the
% raw term below.
term_text(Value, Text) :-
    compound(Value),
    functor(Value, Name, Arity),
    commitment_gloss_functor(Name, Arity),
    !,
    gloss_commitment(Value, Text).
term_text(Value, Text) :-
    term_string(Value, Text, [quoted(false), numbervars(true)]).

% commitment_gloss_functor(?Name, ?Arity) names the commitment-shaped functors
% that appear as commitment_made / entitlement_lacked / incompatibility values.
% strategy/2, deformed_action/3 and the geometry_* terms surface in the
% default-loaded system; result_of/3, documented_batch_misconception/4,
% expected_result/3 and expected_mathematical_control/3 surface once the corpus
% misconception rows are loaded (the db_row(...) cases).
commitment_gloss_functor(strategy, 2).
commitment_gloss_functor(deformed_action, 3).
commitment_gloss_functor(result_of, 3).
commitment_gloss_functor(documented_batch_misconception, 4).
commitment_gloss_functor(expected_mathematical_control, 3).
commitment_gloss_functor(expected_result, 3).
commitment_gloss_functor(geometry_misconception, 1).
commitment_gloss_functor(geometry_concept, 1).
commitment_gloss_functor(commitment_entitlement_gap, 1).

% gloss_commitment(+Term, -Text) mirrors console.html glossTerm. The named
% cases keep the same English; any other compound becomes
% "<functor words>(<glossed args>)". Identifiers are spelled out (underscores
% become spaces) so the result carries no underscores and is a fixed point of
% glossTerm, which keeps the HTML re-render identical to the markdown export.
gloss_commitment(strategy(Operation, Kind), Text) :-
    !,
    gloss_words(Kind, KindText),
    gloss_words(Operation, OperationText),
    format(string(Text), "the \"~w\" strategy (~w)", [KindText, OperationText]).
gloss_commitment(deformed_action(Productive, Deformation, Family), Text) :-
    !,
    gloss_words(Productive, ProductiveText),
    gloss_words(Deformation, DeformationText),
    (   Family == Deformation
    ->  format(string(Text),
               "the \"~w\" strategy deformed into \"~w\"",
               [ProductiveText, DeformationText])
    ;   gloss_words(Family, FamilyText),
        format(string(Text),
               "the \"~w\" strategy deformed into \"~w\" (~w)",
               [ProductiveText, DeformationText, FamilyText])
    ).
gloss_commitment(result_of(Name, Source, Value), Text) :-
    !,
    gloss_words(Name, NameText),
    gloss_commitment(Source, SourceText),
    gloss_commitment(Value, ValueText),
    format(string(Text),
           "the \"~w\" rule on ~w yields ~w",
           [NameText, SourceText, ValueText]).
gloss_commitment(misconception(Name), Text) :-
    !,
    gloss_words(Name, NameText),
    format(string(Text), "the \"~w\" misconception", [NameText]).
gloss_commitment(db_row(Id), Text) :-
    !,
    gloss_commitment(Id, IdText),
    format(string(Text), "corpus row ~w", [IdText]).
gloss_commitment(Value, Text) :-
    compound(Value),
    Value \= [_|_],
    !,
    Value =.. [Functor|Args],
    gloss_words(Functor, FunctorText),
    maplist(gloss_commitment, Args, ArgTexts),
    atomic_list_concat(ArgTexts, ", ", ArgsText),
    format(string(Text), "~w(~w)", [FunctorText, ArgsText]).
gloss_commitment(Value, Text) :-
    number(Value),
    !,
    number_string(Value, Text).
gloss_commitment(Value, Text) :-
    gloss_words(Value, Text).

% gloss_words(+Value, -Text) mirrors console.html glossAtom: render the value
% as text, then spell out an identifier by turning underscores into spaces.
gloss_words(Value, Text) :-
    term_text(Value, Raw),
    split_string(Raw, "_", "", Parts),
    atomic_list_concat(Parts, " ", Joined),
    normalize_space(string(Text), Joined).
