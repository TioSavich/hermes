/** <module> Semantic/pragmatic context for hermeneutic-calculator strategies
 *
 * This module is the user-facing bridge from the older strategy names exposed
 * by `hermeneutic_calculator.pl` to the DB-backed action-topology annotation
 * export produced by `materialize_action_semantic_pragmatic_annotations.py`.
 */

:- module(action_semantic_context,
          [ operation_symbol/2,
            strategy_action_kind/3,
            action_topology_context/3,
            semantic_pragmatic_context/3,
            strategy_action_context/3,
            strategy_context_summary/3,
            strategy_context_summaries/3,
            grounding_gap_queue/1,
            top_grounding_gaps/2
          ]).

:- use_module(library(http/json)).

:- dynamic default_annotation_report_path/1.
:- dynamic default_calculator_context_report_path/1.
:- dynamic cached_annotation_report/1.
:- dynamic cached_calculator_context_report/1.

:- prolog_load_context(directory, ThisDir),
   file_directory_name(ThisDir, RepoRoot),
   directory_file_path(
       RepoRoot,
       'data/research_assets/research/2026-05-21-action-semantic-pragmatic-annotations.json',
       ReportPath
   ),
   assertz(default_annotation_report_path(ReportPath)),
   directory_file_path(
       RepoRoot,
       'data/research_assets/research/2026-05-21-action-topology-calculator-context.json',
       ContextPath
   ),
   assertz(default_calculator_context_report_path(ContextPath)).


%!  operation_symbol(+External, -Operation) is semidet.
%
%   Normalize calculator operation tokens to action-registry operations.
operation_symbol(External, Operation) :-
    normalize_atom(External, Atom),
    operation_symbol_atom(Atom, Operation).

operation_symbol_atom(+, addition).
operation_symbol_atom(add, addition).
operation_symbol_atom(addition, addition).
operation_symbol_atom(-, subtraction).
operation_symbol_atom(subtract, subtraction).
operation_symbol_atom(subtraction, subtraction).
operation_symbol_atom(*, multiplication).
operation_symbol_atom(multiply, multiplication).
operation_symbol_atom(multiplication, multiplication).
operation_symbol_atom(/, division).
operation_symbol_atom(divide, division).
operation_symbol_atom(division, division).


%!  strategy_action_kind(+Operation, +Strategy, -Kind) is semidet.
%
%   Map names from `hermeneutic_calculator:list_strategies/2` to the nearest
%   productive action-automata kind. The registry remains the automaton source
%   of truth; this is only the legacy UI name bridge.
strategy_action_kind(addition, 'COBO', count_on_from_larger).
strategy_action_kind(addition, 'Counting On', count_on_from_larger).
strategy_action_kind(addition, 'Chunking', base_ones_chunking).
strategy_action_kind(addition, 'RMB', make_base_transfer).
strategy_action_kind(addition, 'Rounding', round_then_adjust).

strategy_action_kind(subtraction, 'COBO (Missing Addend)', count_up_missing_addend).
strategy_action_kind(subtraction, 'CBBO (Take Away)', take_away_base_ones).
strategy_action_kind(subtraction, 'Decomposition', decompose_base_for_ones).
strategy_action_kind(subtraction, 'Rounding', sliding_constant_difference).
strategy_action_kind(subtraction, 'Sub Rounding', sliding_constant_difference).
strategy_action_kind(subtraction, 'Sliding', sliding_constant_difference).
strategy_action_kind(subtraction, 'Chunking A', take_away_base_ones).
strategy_action_kind(subtraction, 'Chunking B', count_up_missing_addend).
strategy_action_kind(subtraction, 'Chunking C', decompose_base_for_ones).

strategy_action_kind(multiplication, 'C2C', coordinate_groups_items).
strategy_action_kind(multiplication, 'CBO', repeat_equal_groups).
strategy_action_kind(multiplication, 'Commutative Reasoning', commute_factors_preserve_product).
strategy_action_kind(multiplication, 'DR', distribute_group_size_split).

strategy_action_kind(division, 'CGOB', measure_groups_of_size).
strategy_action_kind(division, 'Dealing by Ones', fair_share_equal_groups).
strategy_action_kind(division, 'IDP', inverse_fact_decomposition).
strategy_action_kind(division, 'UCR', missing_factor_repeated_addition).


%!  action_topology_context(+Operation, +Kind, -Context) is semidet.
%
%   Look up a registry kind in the compact calculator-context export, which
%   combines semantic annotations with deformation neighbors, trace deltas, and
%   grounding summaries.
action_topology_context(Operation0, Kind0, Context) :-
    normalize_atom(Operation0, Operation),
    normalize_atom(Kind0, Kind),
    calculator_context_report(Report),
    get_dict(contexts, Report, Rows),
    member(Row, Rows),
    row_operation_kind(Row, Operation, Kind),
    row_topology_context(Row, Context).


%!  semantic_pragmatic_context(+Operation, +Kind, -Context) is semidet.
%
%   Look up a registry kind in the latest DB-backed semantic/pragmatic export.
semantic_pragmatic_context(Operation0, Kind0, Context) :-
    normalize_atom(Operation0, Operation),
    normalize_atom(Kind0, Kind),
    annotation_report(Report),
    annotation_run_id(Report, RunId),
    get_dict(annotation_rows, Report, Rows),
    member(Row, Rows),
    row_operation_kind(Row, Operation, Kind),
    row_context(Row, RunId, Context).


%!  strategy_action_context(+Op, +Strategy, -Context) is semidet.
%
%   Resolve a hermeneutic-calculator strategy to the semantic/pragmatic
%   context for its productive action automaton.
strategy_action_context(Op0, Strategy0, Context) :-
    operation_symbol(Op0, Operation),
    normalize_atom(Strategy0, Strategy),
    strategy_action_kind(Operation, Strategy, Kind),
    action_topology_context(Operation, Kind, TopologyContext),
    !,
    Context = TopologyContext.put(_{strategy: Strategy}).
strategy_action_context(Op0, Strategy0, Context) :-
    operation_symbol(Op0, Operation),
    normalize_atom(Strategy0, Strategy),
    strategy_action_kind(Operation, Strategy, Kind),
    semantic_pragmatic_context(Operation, Kind, BaseContext),
    Context = BaseContext.put(_{strategy: Strategy}).


%!  strategy_context_summary(+Op, +Strategy, -Summary) is det.
%
%   Compact per-strategy topology for `/api/strategies`. The old API keeps
%   returning plain strategy names; this summary rides alongside it.
strategy_context_summary(Op, Strategy0, Summary) :-
    normalize_atom(Strategy0, Strategy),
    (   strategy_action_context(Op, Strategy, Context)
    ->  get_dict(deformations, Context, Deformations),
        length(Deformations, DeformationCount),
        grounded_deformation_count(Deformations, GroundedCount),
        Summary = _{
            strategy: Strategy,
            available: true,
            operation: Context.operation,
            kind: Context.kind,
            automaton_ref: Context.automaton_ref,
            semantic_label: Context.semantic_label,
            requires_entitlement: Context.requires_entitlement,
            deformation_count: DeformationCount,
            grounded_deformation_count: GroundedCount,
            top_deformations: Deformations
        }
    ;   Summary = _{strategy: Strategy, available: false}
    ).


%!  strategy_context_summaries(+Op, +Strategies, -Summaries) is det.
strategy_context_summaries(Op, Strategies, Summaries) :-
    maplist(strategy_context_summary(Op), Strategies, Summaries).


%!  grounding_gap_queue(-Gaps) is det.
%
%   Ranked deformation neighbors that still need direct/adjacent NotebookLM
%   evidence samples. The queue is generated by the calculator-context export
%   and normalized here for Prolog and HTTP consumers.
grounding_gap_queue(Gaps) :-
    calculator_context_report(Report),
    get_dict(grounding_gap_queue, Report, Gaps0),
    maplist(normalize_grounding_gap, Gaps0, Gaps).


%!  top_grounding_gaps(+Limit, -Gaps) is det.
%
%   Prefix of the ranked grounding-gap queue.
top_grounding_gaps(Limit, Gaps) :-
    integer(Limit),
    Limit >= 0,
    grounding_gap_queue(All),
    take_n(Limit, All, Gaps).


annotation_report(Report) :-
    cached_annotation_report(Report),
    !.
annotation_report(Report) :-
    default_annotation_report_path(Path),
    exists_file(Path),
    setup_call_cleanup(
        open(Path, read, In),
        json_read_dict(In, Report),
        close(In)
    ),
    asserta(cached_annotation_report(Report)).


calculator_context_report(Report) :-
    cached_calculator_context_report(Report),
    !.
calculator_context_report(Report) :-
    default_calculator_context_report_path(Path),
    exists_file(Path),
    setup_call_cleanup(
        open(Path, read, In),
        json_read_dict(In, Report),
        close(In)
    ),
    asserta(cached_calculator_context_report(Report)).


annotation_run_id(Report, RunId) :-
    get_dict(summary, Report, Summary),
    get_dict(apply_result, Summary, ApplyResult),
    is_dict(ApplyResult),
    get_dict(run_id, ApplyResult, RunId),
    !.
annotation_run_id(_, none).


row_operation_kind(Row, Operation, Kind) :-
    get_dict(operation, Row, RowOperation0),
    get_dict(kind, Row, RowKind0),
    normalize_atom(RowOperation0, RowOperation),
    normalize_atom(RowKind0, RowKind),
    RowOperation == Operation,
    RowKind == Kind.


row_context(Row, RunId, Context) :-
    get_dict(operation, Row, Operation0),
    get_dict(kind, Row, Kind0),
    get_dict(automaton_ref, Row, AutomatonRef0),
    get_dict(cluster, Row, Cluster0),
    get_dict(semantic_label, Row, SemanticLabel0),
    get_dict(practice_count, Row, PracticeCount),
    get_dict(practices, Row, Practices0),
    get_dict(grounding_metaphors, Row, Groundings0),
    get_dict(vocabulary_terms, Row, Terms0),
    get_dict(requires_entitlement, Row, RequiresEntitlement),
    normalize_atom(Operation0, Operation),
    normalize_atom(Kind0, Kind),
    normalize_atom(AutomatonRef0, AutomatonRef),
    normalize_atom(Cluster0, Cluster),
    normalize_atom(SemanticLabel0, SemanticLabel),
    maplist(normalize_practice, Practices0, Practices),
    maplist(normalize_atom, Groundings0, Groundings),
    maplist(normalize_atom, Terms0, Terms),
    Context = _{
        operation: Operation,
        kind: Kind,
        automaton_ref: AutomatonRef,
        cluster: Cluster,
        semantic_label: SemanticLabel,
        practice_count: PracticeCount,
        practices: Practices,
        grounding_metaphors: Groundings,
        vocabulary_terms: Terms,
        requires_entitlement: RequiresEntitlement,
        annotation_run_id: RunId,
        source: action_semantic_pragmatic_export
    }.


row_topology_context(Row, Context) :-
    get_dict(annotation_run_id, Row, RunId),
    row_context(Row, RunId, BaseContext),
    get_dict(deformations, Row, Deformations0),
    maplist(normalize_deformation, Deformations0, Deformations),
    get_dict(source_runs, Row, SourceRuns),
    Context = BaseContext.put(_{
        source: action_topology_calculator_context_export,
        semantic_source: action_semantic_pragmatic_export,
        source_runs: SourceRuns,
        deformations: Deformations
    }).


normalize_deformation(Deformation0, Deformation) :-
    get_dict(deformation_kind, Deformation0, DeformationKind0),
    get_dict(deformation_automaton_ref, Deformation0, AutomatonRef0),
    get_dict(family, Deformation0, Family0),
    get_dict(delta_type, Deformation0, DeltaType0),
    get_dict(delta_tags, Deformation0, DeltaTags0),
    get_dict(result_relation, Deformation0, ResultRelation0),
    get_dict(validity_shift, Deformation0, ValidityShift0),
    get_dict(divergence_summary, Deformation0, DivergenceSummary),
    get_dict(productive_binding_count, Deformation0, ProductiveBindingCount),
    get_dict(deformation_binding_count, Deformation0, DeformationBindingCount),
    get_dict(binding_total, Deformation0, BindingTotal),
    get_dict(semantic_label, Deformation0, SemanticLabel0),
    get_dict(requires_entitlement, Deformation0, RequiresEntitlement),
    get_dict(grounding_evidence, Deformation0, Grounding0),
    get_dict(evidence_summary, Deformation0, EvidenceSummary0),
    normalize_atom(DeformationKind0, DeformationKind),
    normalize_atom(AutomatonRef0, AutomatonRef),
    normalize_atom(Family0, Family),
    normalize_atom(DeltaType0, DeltaType),
    normalize_atom(DeltaTags0, DeltaTags),
    normalize_atom(ResultRelation0, ResultRelation),
    normalize_atom(ValidityShift0, ValidityShift),
    normalize_atom(SemanticLabel0, SemanticLabel),
    normalize_atom(EvidenceSummary0, EvidenceSummary),
    normalize_grounding_summary(Grounding0, Grounding),
    Deformation = _{
        deformation_kind: DeformationKind,
        deformation_automaton_ref: AutomatonRef,
        family: Family,
        delta_type: DeltaType,
        delta_tags: DeltaTags,
        result_relation: ResultRelation,
        validity_shift: ValidityShift,
        divergence_summary: DivergenceSummary,
        productive_binding_count: ProductiveBindingCount,
        deformation_binding_count: DeformationBindingCount,
        binding_total: BindingTotal,
        semantic_label: SemanticLabel,
        requires_entitlement: RequiresEntitlement,
        evidence_summary: EvidenceSummary,
        grounding_evidence: Grounding
    }.


normalize_grounding_gap(Gap0, Gap) :-
    get_dict(operation, Gap0, Operation0),
    get_dict(productive_kind, Gap0, ProductiveKind0),
    get_dict(deformation_kind, Gap0, DeformationKind0),
    get_dict(productive_automaton_ref, Gap0, ProductiveAutomatonRef0),
    get_dict(deformation_automaton_ref, Gap0, DeformationAutomatonRef0),
    get_dict(family, Gap0, Family0),
    get_dict(delta_type, Gap0, DeltaType0),
    get_dict(delta_tags, Gap0, DeltaTags0),
    get_dict(binding_total, Gap0, BindingTotal),
    get_dict(productive_binding_count, Gap0, ProductiveBindingCount),
    get_dict(deformation_binding_count, Gap0, DeformationBindingCount),
    get_dict(divergence_summary, Gap0, DivergenceSummary),
    get_dict(evidence_samples_needed, Gap0, EvidenceSamplesNeeded),
    get_dict(notebooklm_query, Gap0, Query0),
    normalize_atom(Operation0, Operation),
    normalize_atom(ProductiveKind0, ProductiveKind),
    normalize_atom(DeformationKind0, DeformationKind),
    normalize_atom(ProductiveAutomatonRef0, ProductiveAutomatonRef),
    normalize_atom(DeformationAutomatonRef0, DeformationAutomatonRef),
    normalize_atom(Family0, Family),
    normalize_atom(DeltaType0, DeltaType),
    normalize_atom(DeltaTags0, DeltaTags),
    normalize_atom(Query0, Query),
    Gap = _{
        operation: Operation,
        productive_kind: ProductiveKind,
        deformation_kind: DeformationKind,
        productive_automaton_ref: ProductiveAutomatonRef,
        deformation_automaton_ref: DeformationAutomatonRef,
        family: Family,
        delta_type: DeltaType,
        delta_tags: DeltaTags,
        binding_total: BindingTotal,
        productive_binding_count: ProductiveBindingCount,
        deformation_binding_count: DeformationBindingCount,
        divergence_summary: DivergenceSummary,
        evidence_samples_needed: EvidenceSamplesNeeded,
        notebooklm_query: Query
    }.


normalize_grounding_summary(Grounding0, Grounding) :-
    get_dict(direct, Grounding0, Direct),
    get_dict(adjacent, Grounding0, Adjacent),
    get_dict(rollup, Grounding0, Rollup),
    get_dict(rebuttal, Grounding0, Rebuttal),
    get_dict(notebooks, Grounding0, Notebooks0),
    get_dict(evidence_notebooks, Grounding0, EvidenceNotebooks0),
    get_dict(rollup_notebooks, Grounding0, RollupNotebooks0),
    get_dict(search_notebooks, Grounding0, SearchNotebooks0),
    get_dict(top_patterns, Grounding0, TopPatterns),
    get_dict(binding_rollup_total, Grounding0, BindingRollupTotal),
    (   get_dict(evidence_samples, Grounding0, Samples0)
    ->  maplist(normalize_evidence_sample, Samples0, Samples)
    ;   Samples = []
    ),
    (   get_dict(search_samples, Grounding0, SearchSamples0)
    ->  maplist(normalize_evidence_sample, SearchSamples0, SearchSamples)
    ;   SearchSamples = []
    ),
    maplist(normalize_atom, Notebooks0, Notebooks),
    maplist(normalize_atom, EvidenceNotebooks0, EvidenceNotebooks),
    maplist(normalize_atom, RollupNotebooks0, RollupNotebooks),
    maplist(normalize_atom, SearchNotebooks0, SearchNotebooks),
    Grounding = _{
        direct: Direct,
        adjacent: Adjacent,
        rollup: Rollup,
        rebuttal: Rebuttal,
        notebooks: Notebooks,
        evidence_notebooks: EvidenceNotebooks,
        rollup_notebooks: RollupNotebooks,
        search_notebooks: SearchNotebooks,
        top_patterns: TopPatterns,
        evidence_samples: Samples,
        search_samples: SearchSamples,
        binding_rollup_total: BindingRollupTotal
    }.


normalize_evidence_sample(Sample0, Sample) :-
    get_dict(quality, Sample0, Quality0),
    get_dict(notebook_title, Sample0, NotebookTitle0),
    get_dict(source_id, Sample0, SourceId0),
    get_dict(citation_number, Sample0, CitationNumber0),
    get_dict(source_title, Sample0, SourceTitle0),
    get_dict(source_authors, Sample0, SourceAuthors0),
    get_dict(source_location, Sample0, SourceLocation0),
    get_dict(support_pattern, Sample0, SupportPattern0),
    get_dict(support_summary, Sample0, SupportSummary0),
    normalize_atom(Quality0, Quality),
    normalize_atom(NotebookTitle0, NotebookTitle),
    normalize_atom(SourceId0, SourceId),
    normalize_atom(CitationNumber0, CitationNumber),
    normalize_atom(SourceTitle0, SourceTitle),
    normalize_atom(SourceAuthors0, SourceAuthors),
    normalize_atom(SourceLocation0, SourceLocation),
    normalize_atom(SupportPattern0, SupportPattern),
    normalize_atom(SupportSummary0, SupportSummary),
    Sample = _{
        quality: Quality,
        notebook_title: NotebookTitle,
        source_id: SourceId,
        citation_number: CitationNumber,
        source_title: SourceTitle,
        source_authors: SourceAuthors,
        source_location: SourceLocation,
        support_pattern: SupportPattern,
        support_summary: SupportSummary
    }.


grounded_deformation_count(Deformations, Count) :-
    include(has_grounding_evidence, Deformations, Grounded),
    length(Grounded, Count).


has_grounding_evidence(Deformation) :-
    get_dict(grounding_evidence, Deformation, Grounding),
    (   get_dict(direct, Grounding, Direct),
        Direct > 0
    ;   get_dict(adjacent, Grounding, Adjacent),
        Adjacent > 0
    ;   get_dict(rollup, Grounding, Rollup),
        Rollup > 0
    ).


normalize_practice(Practice0, Practice) :-
    get_dict(practice, Practice0, PracticeName0),
    get_dict(description, Practice0, Description),
    normalize_atom(PracticeName0, PracticeName),
    Practice = _{practice: PracticeName, description: Description}.


normalize_atom(Value, Atom) :-
    atom(Value),
    !,
    Atom = Value.
normalize_atom(Value, Atom) :-
    string(Value),
    !,
    atom_string(Atom, Value).


take_n(0, _, []) :-
    !.
take_n(_, [], []) :-
    !.
take_n(N, [X|Xs], [X|Ys]) :-
    N > 0,
    N1 is N - 1,
    take_n(N1, Xs, Ys).
