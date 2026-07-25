:- module(review_queue,
          [ review_queue_dict/3,
            review_decide_dict/6
          ]).

/** <module> Human review queue for generated lesson and corpus proposals

The proposal files remain inputs.  A verdict appends one record to
data/research/review_decisions.jsonl and changes no knowledge or curriculum
file.  Promotion from that log is a separate operation.
*/

:- use_module(library(apply)).
:- use_module(library(http/json)).
:- use_module(library(lists)).
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


review_source(lesson_pairings).
review_source(corpus_bindings).

review_verdict(accept).
review_verdict(reject).
review_verdict(unsure).

review_file('data/research/grade78_pairing_proposals.jsonl').
review_file('data/research/corpus_binding_proposals.json').
review_file('data/research/review_decisions.jsonl').
review_file('curriculum/im/generated/field_context_cache.json').


%!  review_queue_dict(+Source, +Offset, -Dict) is semidet.
%
%   Return one ranked, undecided item and progress through the current source.
%   Offset is applied to the ranked undecided queue, which lets a reviewer move
%   past an item without recording a verdict.
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
%   Append a first verdict for an existing item.  Shown is the structured text
%   the page received for that item; keeping it in the log preserves what the
%   reviewer judged if a proposal file changes later.
review_decide_dict(Source, ItemId, Verdict, Note, Shown, Dict) :-
    review_source(Source),
    review_verdict(Verdict),
    string(ItemId),
    string(Note),
    is_dict(Shown),
    get_dict(identity, Shown, ItemId),
    get_dict(source, Shown, ShownSource),
    atom_string(Source, ShownSource),
    review_source_items(Source, Items),
    item_with_identity(Items, ItemId, _),
    with_mutex(review_decision_log,
               append_review_decision(Source, ItemId, Verdict, Note,
                                      Shown, Items, Dict)).


append_review_decision(Source, ItemId, Verdict, Note, Shown, Items, Dict) :-
    decided_ids(Source, Items, BeforeIds),
    \+ memberchk(ItemId, BeforeIds),
    get_time(Now),
    format_time(string(Timestamp), '%FT%T%z', Now),
    atom_string(Source, SourceText),
    atom_string(Verdict, VerdictText),
    Record = _{
        schema_version: 1,
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


review_source_items(lesson_pairings, Items) :-
    read_jsonl_file('data/research/grade78_pairing_proposals.jsonl', Rows),
    read_json_file('curriculum/im/generated/field_context_cache.json',
                   ContextData),
    get_dict(field_contexts, ContextData, Contexts),
    maplist(lesson_row_items(Contexts), Rows, Nested),
    append(Nested, Keyed),
    keysort(Keyed, Ranked),
    pairs_values(Ranked, Items).
review_source_items(corpus_bindings, Items) :-
    read_json_file('data/research/corpus_binding_proposals.json', Data),
    get_dict(proposals, Data, Proposals),
    numbered(Proposals, Numbered),
    maplist(corpus_review_item, Numbered, Keyed),
    keysort(Keyed, Ranked),
    pairs_values(Ranked, Items).


lesson_row_items(Contexts, Row, KeyedItems) :-
    get_dict(lesson, Row, Lesson),
    standards_for_lesson(Contexts, Lesson, Standards),
    get_dict(pairings, Row, Pairings),
    family_disagreement(Pairings, FamilyDisagreement),
    (   Pairings == []
    ->  get_dict(gap, Row, Gap),
        Gap \== "",
        lesson_gap_item(Row, Standards, Gap, Item),
        KeyedItems = [0-Lesson-0-Item]
    ;   numbered(Pairings, Numbered),
        maplist(lesson_pairing_item(Row, Standards, FamilyDisagreement),
                Numbered, PairItems),
        KeyedItems = PairItems
    ).


lesson_gap_item(Row, Standards, Gap, Item) :-
    get_dict(lesson, Row, Lesson),
    get_dict(title, Row, Title),
    get_dict(unit, Row, Unit),
    get_dict(topics, Row, Topics),
    format(string(Identity), 'lesson_gap:~s', [Lesson]),
    Item = _{
        source: "lesson_pairings",
        identity: Identity,
        item_type: "authoring_gap",
        lesson: Lesson,
        title: Title,
        unit: Unit,
        standards: Standards,
        topics: Topics,
        gap: Gap,
        machine: null,
        machine_steps: null,
        was_candidate: false,
        family_disagreement: false,
        ranking_tier: 0,
        ranking_reason: "No pairing was proposed; this item asks whether the stated authoring gap is accurate."
    }.


lesson_pairing_item(Row, Standards, FamilyDisagreement,
                    PairIndex-Pairing, Rank-Lesson-PairIndex-Item) :-
    get_dict(lesson, Row, Lesson),
    get_dict(title, Row, Title),
    get_dict(unit, Row, Unit),
    get_dict(topics, Row, Topics),
    get_dict(gap, Row, Gap),
    get_dict(machine, Pairing, Machine),
    get_dict(reason, Pairing, Reason),
    get_dict(confidence, Pairing, Confidence),
    get_dict(was_candidate, Pairing, WasCandidate),
    machine_review_dict(Machine, MachineSteps),
    lesson_pairing_rank(WasCandidate, FamilyDisagreement, Rank, RankReason),
    format(string(Identity), 'lesson_pairing:~s:~s', [Lesson, Machine]),
    Item = _{
        source: "lesson_pairings",
        identity: Identity,
        item_type: "lesson_pairing",
        lesson: Lesson,
        title: Title,
        unit: Unit,
        standards: Standards,
        topics: Topics,
        gap: Gap,
        machine: Machine,
        machine_steps: MachineSteps,
        reason: Reason,
        confidence: Confidence,
        was_candidate: WasCandidate,
        family_disagreement: FamilyDisagreement,
        ranking_tier: Rank,
        ranking_reason: RankReason
    }.


lesson_pairing_rank(false, _, 1,
        "The index did not retain this machine in the lesson's pruned candidate set.") :-
    !.
lesson_pairing_rank(_, true, 2,
        "This lesson's proposals span machine families, so the family assignment needs review.") :-
    !.
lesson_pairing_rank(_, _, 3,
        "This proposal was inside the pruned candidate set and stays within one machine family.").


corpus_review_item(Index-Proposal, Rank-Index-Item) :-
    get_dict(row_id, Proposal, RowId),
    get_dict(family, Proposal, Family),
    get_dict(signature, Proposal, Signature),
    get_dict(bibtex_key, Proposal, Citation),
    get_dict(evidence, Proposal, Evidence),
    get_dict(excerpt, Proposal, Excerpt),
    get_dict(confidence, Proposal, Confidence),
    get_dict(score, Proposal, Score),
    get_dict(runner_up_score, Proposal, RunnerUpScore),
    get_dict(domain, Proposal, Domain),
    get_dict(kind, Proposal, Kind),
    get_dict(operation, Proposal, Operation),
    get_dict(role, Proposal, Role),
    get_dict(row_type, Proposal, RowType),
    format(string(Machine), '~s/~s', [Family, Signature]),
    machine_review_dict(Machine, MachineSteps),
    corpus_rank(Citation, Confidence, Score, RunnerUpScore,
                Rank, RankReason, CitationStatus, CitationNote),
    format(string(Identity), 'corpus_binding:~d:~s', [RowId, Machine]),
    Item = _{
        source: "corpus_bindings",
        identity: Identity,
        item_type: "corpus_binding",
        row_id: RowId,
        row_type: RowType,
        domain: Domain,
        operation: Operation,
        kind: Kind,
        role: Role,
        family: Family,
        signature: Signature,
        machine: Machine,
        machine_steps: MachineSteps,
        evidence: Evidence,
        excerpt: Excerpt,
        citation: Citation,
        citation_status: CitationStatus,
        citation_note: CitationNote,
        confidence: Confidence,
        score: Score,
        runner_up_score: RunnerUpScore,
        ranking_tier: Rank,
        ranking_reason: RankReason
    }.


corpus_rank("unattributed", _, _, _, 0,
        "No source was recorded, so the evidence wording carries the full warrant for this proposal.",
        "no_recorded_source",
        "No recorded source. Judge this binding from the evidence wording and excerpt alone.") :-
    !.
corpus_rank(_, _, Score, RunnerUpScore, 1,
        "The proposed signature tied the runner-up score.",
        "recorded_key", "") :-
    Score =:= RunnerUpScore,
    !.
corpus_rank(_, "tentative", _, _, 2,
        "The generator marked this binding tentative.",
        "recorded_key", "") :-
    !.
corpus_rank(_, _, _, _, 3,
        "The generator assigned this binding its strongest confidence.",
        "recorded_key", "").


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


family_disagreement(Pairings, Disagreement) :-
    findall(Family,
            ( member(Pairing, Pairings),
              get_dict(machine, Pairing, Machine),
              split_string(Machine, "/", "", [Family|_])
            ),
            Families0),
    sort(Families0, Families),
    length(Families, Count),
    ( Count > 1 -> Disagreement = true ; Disagreement = false ).


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

pairs_values([], []).
pairs_values([_-Value|Pairs], [Value|Values]) :-
    pairs_values(Pairs, Values).
