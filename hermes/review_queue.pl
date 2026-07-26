:- module(review_queue,
          [ review_queue_dict/3,
            review_decide_dict/6
          ]).

/** <module> Answerable review queues for generated research proposals

The lesson proposals are grouped into one recognition-set decision per IM
unit.  Corpus proposals are grouped into one anchor decision per signature
after mechanical triage.  A verdict appends one record to
data/research/review_decisions.jsonl and changes no knowledge or curriculum
file.  Promotion from that log is a separate operation.
*/

:- use_module(library(apply)).
:- use_module(library(http/json)).
:- use_module(library(lists)).
:- use_module(library(pairs)).
:- use_module(library(readutil)).

:- use_module(index(index_query), []).

:- dynamic repo_root/1.

:- prolog_load_context(directory, HermesDirectory),
   directory_file_path(HermesDirectory, '..', Root0),
   absolute_file_name(Root0, Root,
                      [ file_type(directory),
                        access(read)
                      ]),
   asserta(repo_root(Root)).


review_source(unit_recognition_set).
review_source(signature_anchor).

review_file('data/research/grade78_pairing_proposals.jsonl').
review_file('data/research/corpus_binding_proposals.json').
review_file('data/research/corpus_binding_diagnostics.json').
review_file('data/research/review_decisions.jsonl').
review_file('curriculum/im/generated/field_context_cache.json').


%!  review_queue_dict(+Source, +Offset, -Dict) is semidet.
%
%   Return one ranked, undecided aggregate decision.  Offset is applied to the
%   ranked undecided queue, which lets a reviewer move without recording.
review_queue_dict(Source, Offset, Dict) :-
    review_source(Source),
    integer(Offset),
    Offset >= 0,
    review_source_items(Source, Items),
    decided_ids(Source, Items, DecidedIds),
    exclude(item_is_decided(DecidedIds), Items, Undecided),
    length(Items, Total),
    length(DecidedIds, Decided),
    length(Undecided, Remaining),
    (   nth0(Offset, Undecided, Item)
    ->  HasItem = true
    ;   Item = null,
        HasItem = false
    ),
    atom_string(Source, SourceText),
    Dict = review_queue{
        source: SourceText,
        offset: Offset,
        has_item: HasItem,
        item: Item,
        progress: _{
            decided: Decided,
            total: Total,
            remaining: Remaining
        }
    }.


%!  review_decide_dict(+Source, +ItemId, +Verdict, +Note, +Shown, -Dict) is semidet.
%
%   Append a first verdict for an existing aggregate decision.  Shown preserves
%   the evidence and structured amendment or exception fields submitted by the
%   page.  Promotion remains a separate operation.
review_decide_dict(Source, ItemId, Verdict, Note, Shown, Dict) :-
    review_source(Source),
    string(ItemId),
    string(Note),
    is_dict(Shown),
    get_dict(identity, Shown, ItemId),
    get_dict(source, Shown, ShownSource),
    atom_string(Source, ShownSource),
    review_source_items(Source, Items),
    item_with_identity(Items, ItemId, Item),
    valid_review_verdict(Source, Verdict, Item, Shown),
    with_mutex(review_decision_log,
               append_review_decision(Source, ItemId, Verdict, Note,
                                      Shown, Items, Dict)).


valid_review_verdict(unit_recognition_set, Verdict, _, Shown) :-
    memberchk(Verdict, ['accept-set', 'reject-set', amend]),
    valid_unit_decision_detail(Verdict, Shown).
valid_review_verdict(signature_anchor, none, _, _).
valid_review_verdict(signature_anchor, Verdict, Item, _) :-
    atom_string(Verdict, VerdictText),
    get_dict(candidates, Item, Candidates),
    member(Candidate, Candidates),
    get_dict(anchor_verdict, Candidate, VerdictText),
    !.

valid_unit_decision_detail(Verdict, Shown) :-
    (   get_dict(decision_detail, Shown, Detail)
    ->  is_dict(Detail),
        get_dict(drop_machines, Detail, Drops),
        is_list(Drops),
        maplist(string, Drops),
        get_dict(add_machines, Detail, Adds),
        is_list(Adds),
        maplist(string, Adds),
        get_dict(lesson_exceptions, Detail, Exceptions),
        string(Exceptions),
        (   Verdict == amend
        ->  ( Drops \== [] ; Adds \== [] )
        ;   Drops == [],
            Adds == []
        )
    ;   Verdict \== amend
    ).


append_review_decision(Source, ItemId, Verdict, Note, Shown, Items, Dict) :-
    decided_ids(Source, Items, BeforeIds),
    \+ memberchk(ItemId, BeforeIds),
    get_time(Now),
    format_time(string(Timestamp), '%FT%T%z', Now),
    atom_string(Source, SourceText),
    atom_string(Verdict, VerdictText),
    Record = _{
        schema_version: 2,
        source: SourceText,
        item_id: ItemId,
        verdict: VerdictText,
        note: Note,
        decided_at: Timestamp,
        reviewer_text: Shown
    },
    repo_file('data/research/review_decisions.jsonl', DecisionsPath),
    setup_call_cleanup(
        open(DecisionsPath, append, Stream, [encoding(utf8)]),
        ( json_write_dict(Stream, Record, [width(0)]),
          nl(Stream),
          flush_output(Stream)
        ),
        close(Stream)),
    decided_ids(Source, Items, AfterIds),
    length(Items, Total),
    length(AfterIds, Decided),
    Remaining is Total - Decided,
    Dict = review_decision{
        recorded: true,
        source: SourceText,
        item_id: ItemId,
        verdict: VerdictText,
        progress: _{
            decided: Decided,
            total: Total,
            remaining: Remaining
        }
    }.


review_source_items(unit_recognition_set, Items) :-
    read_jsonl_file('data/research/grade78_pairing_proposals.jsonl', Rows),
    read_json_file('curriculum/im/generated/field_context_cache.json',
                   ContextData),
    get_dict(field_contexts, ContextData, Contexts),
    findall(UnitId-Row,
            ( member(Row, Rows),
              get_dict(lesson, Row, Lesson),
              lesson_unit_id(Lesson, UnitId)
            ),
            UnitRows0),
    keysort(UnitRows0, UnitRows),
    group_pairs_by_key(UnitRows, Grouped),
    maplist(unit_recognition_item(Contexts), Grouped, Keyed),
    keysort(Keyed, Ranked),
    pairs_values(Ranked, Items).
review_source_items(signature_anchor, Items) :-
    read_json_file('data/research/corpus_binding_proposals.json', Data),
    get_dict(proposals, Data, Proposals),
    read_json_file('data/research/corpus_binding_diagnostics.json',
                   DiagnosticData),
    get_dict(diagnostics, DiagnosticData, Diagnostics),
    maplist(proposal_with_diagnostic(Diagnostics), Proposals, Joined),
    include(signature_has_clean_candidate, Joined, Reviewable),
    findall(Machine-Entry,
            ( member(Entry, Reviewable),
              get_dict(proposal, Entry, Proposal),
              proposal_machine(Proposal, Machine)
            ),
            MachineRows0),
    keysort(MachineRows0, MachineRows),
    group_pairs_by_key(MachineRows, Grouped),
    maplist(signature_anchor_item, Grouped, Keyed),
    keysort(Keyed, Ranked),
    pairs_values(Ranked, Items).


lesson_unit_id(Lesson, UnitId) :-
    split_string(Lesson, "-", "", [Program, Grade, Unit, _Lesson]),
    atomics_to_string([Program, Grade, Unit], "-", UnitId).


unit_recognition_item(Contexts, UnitId-Rows,
                      UnitId-Item) :-
    maplist(unit_lesson_dict(Contexts), Rows, Lessons),
    findall(Machine-Motivation,
            ( member(Row, Rows),
              get_dict(pairings, Row, Pairings),
              member(Pairing, Pairings),
              get_dict(machine, Pairing, Machine),
              pairing_motivation(Row, Pairing, Motivation)
            ),
            MachineMotivations0),
    keysort(MachineMotivations0, MachineMotivations),
    group_pairs_by_key(MachineMotivations, GroupedMachines),
    maplist(unit_machine_dict, GroupedMachines, Machines),
    findall(Gap,
            ( member(Lesson, Lessons),
              get_dict(gap, Lesson, Gap),
              Gap \== ""
            ),
            Gaps),
    format(string(Identity), 'unit_recognition_set:~s', [UnitId]),
    Item = _{
        source: "unit_recognition_set",
        identity: Identity,
        item_type: "unit_recognition_set",
        unit: UnitId,
        question: "When Hermes reads student work from this unit, should these machines be in the set it tries first?",
        lessons: Lessons,
        proposed_machines: Machines,
        stated_gaps: Gaps,
        ranking_tier: 0,
        ranking_reason: "One recognition-set decision covers this unit; lesson-level exceptions stay with the unit decision."
    }.


unit_lesson_dict(Contexts, Row, LessonDict) :-
    get_dict(lesson, Row, Lesson),
    get_dict(title, Row, Title),
    get_dict(topics, Row, Topics),
    get_dict(gap, Row, Gap),
    get_dict(candidates_offered, Row, CandidatesOffered),
    get_dict(machines_surviving, Row, MachinesSurviving),
    standards_for_lesson(Contexts, Lesson, Standards),
    LessonDict = _{
        lesson: Lesson,
        title: Title,
        topics: Topics,
        standards: Standards,
        gap: Gap,
        candidates_offered: CandidatesOffered,
        machines_surviving: MachinesSurviving
    }.


pairing_motivation(Row, Pairing, Motivation) :-
    get_dict(lesson, Row, Lesson),
    get_dict(title, Row, Title),
    get_dict(reason, Pairing, Reason),
    get_dict(confidence, Pairing, Confidence),
    get_dict(was_candidate, Pairing, WasCandidate),
    Motivation = _{
        lesson: Lesson,
        title: Title,
        reason: Reason,
        confidence: Confidence,
        was_candidate: WasCandidate
    }.


unit_machine_dict(Machine-Motivations,
                  _{machine: Machine,
                    machine_steps: MachineSteps,
                    motivated_by: Motivations}) :-
    machine_review_dict(Machine, MachineSteps).


proposal_with_diagnostic(Diagnostics, Proposal,
                         _{proposal: Proposal, diagnostic: Diagnostic}) :-
    proposal_candidate_identity(Proposal, Identity),
    member(Diagnostic, Diagnostics),
    get_dict(identity, Diagnostic, Identity),
    !.

signature_has_clean_candidate(Entry) :-
    get_dict(diagnostic, Entry, Diagnostic),
    get_dict(signature_has_clean_candidate, Diagnostic, true).

proposal_machine(Proposal, Machine) :-
    get_dict(family, Proposal, Family),
    get_dict(signature, Proposal, Signature),
    format(string(Machine), '~s/~s', [Family, Signature]).

proposal_candidate_identity(Proposal, Identity) :-
    get_dict(row_type, Proposal, RowType),
    get_dict(row_id, Proposal, RowId),
    proposal_machine(Proposal, Machine),
    format(string(Identity), 'corpus_candidate:~s:~d:~s',
           [RowType, RowId, Machine]).


signature_anchor_item(Machine-Entries, RankKey-Item) :-
    machine_review_dict(Machine, MachineSteps),
    numbered(Entries, Numbered),
    maplist(corpus_candidate, Numbered, CandidatePairs),
    keysort(CandidatePairs, RankedCandidates),
    pairs_values(RankedCandidates, Candidates),
    signature_rank(Candidates, Rank, RankReason, ScoreBand),
    format(string(Identity), 'signature_anchor:~s', [Machine]),
    RankKey = Rank-Machine,
    Item = _{
        source: "signature_anchor",
        identity: Identity,
        item_type: "signature_anchor",
        machine: Machine,
        machine_steps: MachineSteps,
        question: "Is any candidate row an instance of this machine's run?",
        candidates: Candidates,
        none_is_first_class: true,
        score_band: ScoreBand,
        ranking_tier: Rank,
        ranking_reason: RankReason
    }.


corpus_candidate(Index-Entry, RankKey-Candidate) :-
    get_dict(proposal, Entry, Proposal),
    get_dict(diagnostic, Entry, Diagnostic),
    get_dict(row_id, Proposal, RowId),
    get_dict(row_type, Proposal, RowType),
    get_dict(bibtex_key, Proposal, Citation),
    get_dict(evidence, Proposal, Evidence),
    get_dict(excerpt, Proposal, Excerpt),
    get_dict(confidence, Proposal, Confidence),
    get_dict(score, Proposal, Score),
    get_dict(runner_up_score, Proposal, RunnerUpScore),
    get_dict(domain, Proposal, Domain),
    get_dict(role, Proposal, Role),
    get_dict(defects, Diagnostic, Defects),
    get_dict(reviewable, Diagnostic, Reviewable),
    score_band(Score, ScoreBand),
    proposal_candidate_identity(Proposal, CandidateIdentity),
    format(string(AnchorVerdict), 'anchor:~s:~d', [RowType, RowId]),
    NegScore is -Score,
    RankKey = NegScore-Index,
    citation_status(Citation, CitationStatus, CitationNote),
    Candidate = _{
        identity: CandidateIdentity,
        anchor_verdict: AnchorVerdict,
        row_id: RowId,
        row_type: RowType,
        domain: Domain,
        role: Role,
        evidence: Evidence,
        excerpt: Excerpt,
        citation: Citation,
        citation_status: CitationStatus,
        citation_note: CitationNote,
        confidence: Confidence,
        score: Score,
        score_band: ScoreBand,
        runner_up_score: RunnerUpScore,
        defects: Defects,
        mechanically_clear: Reviewable
    }.


signature_rank(Candidates, 0,
        "One or more candidates were displaced by a higher-scoring already-bound signature.",
        BestBand) :-
    candidates_have_defect(Candidates, "displacement"),
    best_candidate_band(Candidates, BestBand),
    !.
signature_rank(Candidates, 1,
        "One or more candidates have a tied score or reuse a row proposed for another signature.",
        BestBand) :-
    ( candidates_have_defect(Candidates, "score_tie")
    ; candidates_have_defect(Candidates, "fan_surplus")
    ),
    best_candidate_band(Candidates, BestBand),
    !.
signature_rank(Candidates, 2,
        "The best mechanically clear candidate is in the low sampled score band.",
        "low_sampled_band") :-
    best_clear_score(Candidates, Score),
    Score =< 3.5,
    !.
signature_rank(Candidates, 3,
        "The best mechanically clear candidate falls between the sampled score bands.",
        "between_sampled_bands") :-
    best_clear_score(Candidates, Score),
    Score < 4.5,
    !.
signature_rank(_, 4,
        "The best mechanically clear candidate is in the strong sampled score band.",
        "strong_sampled_band").

candidates_have_defect(Candidates, Kind) :-
    member(Candidate, Candidates),
    get_dict(defects, Candidate, Defects),
    member(Defect, Defects),
    get_dict(kind, Defect, Kind).

best_candidate_band(Candidates, Band) :-
    best_clear_score(Candidates, Score),
    score_band(Score, Band).

best_clear_score(Candidates, Score) :-
    findall(CandidateScore,
            ( member(Candidate, Candidates),
              get_dict(mechanically_clear, Candidate, true),
              get_dict(score, Candidate, CandidateScore)
            ),
            Scores),
    max_list(Scores, Score).

score_band(Score, "strong_sampled_band") :-
    Score >= 4.5,
    !.
score_band(Score, "low_sampled_band") :-
    Score =< 3.5,
    !.
score_band(_, "between_sampled_bands").


citation_status("unattributed", "no_recorded_source",
        "No source is recorded for this corpus row.") :-
    !.
citation_status(_, "recorded_key", "").


machine_review_dict(Machine, Dict) :-
    split_string(Machine, "/", "", [FamilyText, SignatureText]),
    atom_string(Family, FamilyText),
    atom_string(Signature, SignatureText),
    index_query:window_of(Family/Signature,
                          window(Arc, Shell, Core, Closure, Other)),
    Dict = _{
        family: FamilyText,
        signature: SignatureText,
        arc: Arc,
        shell: Shell,
        core: Core,
        closure: Closure,
        other: Other
    }.


standards_for_lesson(Contexts, Lesson, Standards) :-
    atom_string(Key, Lesson),
    get_dict(Key, Contexts, Context),
    (   get_dict(standards, Context, Standards0)
    ->  sort(Standards0, Standards)
    ;   Standards = []
    ).


decided_ids(Source, Items, DecidedIds) :-
    read_decisions(Decisions),
    findall(ItemId,
            ( member(Decision, Decisions),
              get_dict(source, Decision, LoggedSource),
              atom_string(Source, LoggedSource),
              get_dict(item_id, Decision, ItemId),
              item_with_identity(Items, ItemId, _)
            ),
            Ids0),
    sort(Ids0, DecidedIds).

item_is_decided(DecidedIds, Item) :-
    get_dict(identity, Item, Identity),
    memberchk(Identity, DecidedIds).

item_with_identity([Item|_], Identity, Item) :-
    get_dict(identity, Item, Identity),
    !.
item_with_identity([_|Items], Identity, Item) :-
    item_with_identity(Items, Identity, Item).


read_decisions(Decisions) :-
    repo_file('data/research/review_decisions.jsonl', Path),
    (   exists_file(Path)
    ->  read_jsonl_path(Path, Decisions)
    ;   Decisions = []
    ).

read_json_file(Relative, Dict) :-
    repo_file(Relative, Path),
    setup_call_cleanup(
        open(Path, read, Stream, [encoding(utf8)]),
        json_read_dict(Stream, Dict),
        close(Stream)).

read_jsonl_file(Relative, Rows) :-
    repo_file(Relative, Path),
    read_jsonl_path(Path, Rows).

read_jsonl_path(Path, Rows) :-
    setup_call_cleanup(
        open(Path, read, Stream, [encoding(utf8)]),
        read_jsonl_stream(Stream, Rows),
        close(Stream)).

read_jsonl_stream(Stream, Rows) :-
    read_line_to_string(Stream, Line),
    (   Line == end_of_file
    ->  Rows = []
    ;   normalize_space(string(Trimmed), Line),
        (   Trimmed == ""
        ->  Rows = Rest
        ;   atom_json_dict(Trimmed, Row, []),
            Rows = [Row|Rest]
        ),
        read_jsonl_stream(Stream, Rest)
    ).


repo_file(Relative, Path) :-
    repo_root(Root),
    directory_file_path(Root, Relative, Path).

numbered(List, Numbered) :-
    numbered(List, 0, Numbered).

numbered([], _, []).
numbered([Item|Items], Index, [Index-Item|Numbered]) :-
    Next is Index + 1,
    numbered(Items, Next, Numbered).
