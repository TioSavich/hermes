/** <module> Queries over the machine index and its exclusions
 *
 * `corpus_window.pl` and `relevance_negation.pl` are generated fact files with
 * no module of their own, in the manner of the other generated knowledge in this
 * tree.  This module loads them and names the questions callers ask, so that the
 * index is reachable from the running application rather than only from its
 * checks.
 *
 * The negation direction is the one worth naming.  `machines_for_topic/3` does
 * not rank machines by relevance; it removes the machines an exclusion rule
 * accounts for and hands back both what survived and why the rest did not.  A
 * caller can therefore report the subtraction it performed, which is the whole
 * reason the exclusions were generated as data carrying their evidence.
 */
:- module(index_query,
          [ window_of/2,               % ?Machine, -Row
            window_legend/2,           % ?Action, -Legend
            machine_arc/2,             % ?Machine, ?Arc
            machines_for_topic/3,      % +Topic, -Machines, -Excluded
            topic_subtraction/2,       % +Topic, -Counts
            topic_subtraction_dict/2,  % +Topic, -Dict
            signature_anchors_dict/3,  % +Family, +Signature, -Dict
            task_span_lesson_dict/2,   % +Lesson, -Dict
            task_span_backlog_dict/1,  % -Dict
            metaphor_coverage_dict/2,  % +Metaphor, -Dict
            coverage_backlog_dict/1,   % -Dict
            standards_progression_candidates_dict/2, % +Code, -Dict
            index_topic/1              % ?Topic
          ]).

:- use_module(library(apply), [include/3, maplist/3]).
:- use_module(library(lists), [member/2, append/3]).

:- ensure_loaded(index('corpus_window')).
:- ensure_loaded(index('relevance_negation')).
:- use_module(index(standards_progression_overlay),
              [ standards_progression_candidates_dict/2 ]).
:- use_module(index(admitted_review_proposals), []).
:- use_module(index(task_span_absence_registry), []).
:- use_module(index(coverage_absence_registry), []).

%!  window_of(?Machine, -Row) is nondet.
%
%   Machine is `Family/Signature`.  Row is `window(Arc, Shell, Core, Closure,
%   Other)` — the index row, with the fourth list retained.  Callers that want
%   only the three named groups can ignore Other, but it is never dropped here
%   because the machines that have one are the machines that call another machine.
window_of(Family/Signature, window(Arc, Shell, Core, Closure, Other)) :-
    window_row(Family, Signature, Arc, Shell, Core, Closure, Other).

%!  window_legend(?Action, -Legend) is nondet.
%
%   Legend is `legend(Genre, Register, Stance)` for one canonical action.
window_legend(Action, legend(Genre, Register, Stance)) :-
    window_legend_action(Action, Genre, Register, Stance).

%!  machine_arc(?Machine, ?Arc) is nondet.
machine_arc(Family/Signature, Arc) :-
    window_row(Family, Signature, Arc, _, _, _, _).

%!  index_topic(?Topic) is nondet.
%
%   The topics the exclusion rules can key on.  A query outside this set
%   subtracts nothing, which `machines_for_topic/3` reports rather than hides.
index_topic(Topic) :-
    known_topic(Topic).

%!  machines_for_topic(+Topic, -Machines, -Excluded) is det.
%
%   Machines survived topic subtraction.  Excluded is a list of
%   `excluded(Machine, Reason)` where Reason is the ground evidence term the
%   generated file recorded, so the caller can say why a machine is absent.
%
%   Both lists are returned because a subtraction that cannot show its work is
%   indistinguishable from a guess.
machines_for_topic(Topic, Machines, Excluded) :-
    surviving_slices(Topic, Survivors, Dropped),
    findall(Family/Signature,
            member(slice(family, machine(Family, Signature)), Survivors),
            Machines0),
    sort(Machines0, Machines),
    findall(excluded(Family/Signature, Reason),
            member(excluded(family, machine(Family, Signature), Reason), Dropped),
            Excluded0),
    sort(Excluded0, Excluded).

%!  topic_subtraction(+Topic, -Counts) is det.
%
%   Counts is `subtraction(Surviving, Excluded, Total)` over machines.  Reported
%   as counts because the value of the index is how much it removes, and that is
%   a number rather than a claim.
topic_subtraction(Topic, subtraction(Surviving, Gone, Total)) :-
    machines_for_topic(Topic, Machines, Excluded),
    length(Machines, Surviving),
    length(Excluded, Gone),
    Total is Surviving + Gone.

%!  topic_subtraction_dict(+Topic, -Dict) is semidet.
%
%   The dispatch surface.  Fails for a topic no exclusion rule keys on, so a
%   caller learns that its query subtracted nothing instead of receiving an
%   untouched corpus that reads as a result.
%
%   `excluded_sample` carries a few reasons rather than all of them: the full
%   list runs to the hundreds and the point of returning any is that a caller can
%   show the kind of evidence behind the subtraction.
topic_subtraction_dict(Topic, Dict) :-
    atom(Topic),
    index_topic(Topic),
    machines_for_topic(Topic, Machines, Excluded),
    length(Machines, Surviving),
    length(Excluded, Gone),
    Total is Surviving + Gone,
    maplist(machine_atom, Machines, Names),
    length(Sample, 5),
    (   append(Sample, _, Excluded)
    ->  true
    ;   Sample = Excluded
    ),
    maplist(exclusion_pair, Sample, Reasons),
    Dict = index_subtraction{
        topic: Topic,
        surviving: Surviving,
        excluded: Gone,
        total: Total,
        machines: Names,
        excluded_sample: Reasons
    }.

machine_atom(Family/Signature, Name) :-
    format(atom(Name), '~w/~w', [Family, Signature]).

exclusion_pair(excluded(Machine, Reason), pair{machine: Name, reason: Text}) :-
    machine_atom(Machine, Name),
    format(atom(Text), '~w', [Reason]).


%!  signature_anchors_dict(+Family, +Signature, -Dict) is semidet.
%
%   Return corpus rows admitted as signature anchors by the retired review
%   queue's deterministic strong-band rule. Held proposals do not enter this
%   serving result; they remain queryable in admitted_review_proposals.pl.
signature_anchors_dict(Family, Signature, Dict) :-
    atom(Family), atom(Signature),
    findall(Row,
            ( admitted_review_proposals:admitted_signature_anchor(
                  RowFamily, RowSignature, RowType, RowId, Role,
                  evidence(Evidence),
                  anchor(source_file(Source), source_sha256(SourceSha),
                         diagnostic_file(Diagnostics),
                         diagnostic_sha256(DiagnosticSha), score(Score),
                         score_band(Band), citation(Citation), excerpt(Excerpt)),
                  testimony(scoring(Scorer), triage(Triage), Date), Receipt),
              ( Family == all ; Family == RowFamily ),
              ( Signature == all ; Signature == RowSignature ),
              atom_string(RowFamily, FamilyText),
              atom_string(RowSignature, SignatureText),
              atom_string(RowType, RowTypeText),
              atom_string(Role, RoleText),
              atom_string(Citation, CitationText),
              atom_string(Band, BandText),
              term_string(Date, DateText, [quoted(false)]),
              term_string(Receipt, ReceiptText, [quoted(false)]),
              Row = _{family: FamilyText, signature: SignatureText,
                      corpus_row: _{type: RowTypeText, id: RowId},
                      role: RoleText, evidence: Evidence,
                      score: Score, score_band: BandText,
                      citation: CitationText, excerpt: Excerpt,
                      anchor: _{source: Source, source_sha256: SourceSha,
                                diagnostics: Diagnostics,
                                diagnostics_sha256: DiagnosticSha},
                      testimony: _{scoring: Scorer, triage: Triage,
                                   date: DateText, receipt: ReceiptText}}
            ),
            Rows),
    Rows = [_|_],
    length(Rows, Count),
    Dict = signature_anchors{
        filters: _{family: Family, signature: Signature},
        count: Count,
        admission: mechanical_strong_band,
        rows: Rows
    }.


%!  task_span_lesson_dict(+Lesson, -Dict) is semidet.
%
%   Return one lesson's task-span rollup and every recorded reason count.
%   Fails when Lesson has no rollup row; an empty reasons list is a valid
%   account of a lesson whose rollup carries no reason rows.
task_span_lesson_dict(Lesson, Dict) :-
    atom(Lesson),
    task_span_absence_registry:lesson_task_span_rollup(
        Lesson, Grade, Spans, Resolved, Readiness, PrimaryBlocker),
    findall(_{reason: Reason, count: Count},
            task_span_absence_registry:lesson_task_span_reason_count(
                Lesson, Reason, Count),
            Reasons),
    Dict = task_span_lesson{
        lesson: Lesson,
        grade: Grade,
        spans: Spans,
        resolved: Resolved,
        readiness: Readiness,
        primary_blocker: PrimaryBlocker,
        reasons: Reasons
    }.


%!  task_span_backlog_dict(-Dict) is semidet.
%
%   Return the ranked task-span reason queue and the lessons one parser away
%   from task evidence. Fails when the generated queue is empty.
task_span_backlog_dict(Dict) :-
    findall(_{rank: Rank, reason: Reason, lesson_count: LessonCount},
            task_span_absence_registry:task_span_reason_queue(
                Rank, Reason, LessonCount),
            ReasonQueue),
    ReasonQueue = [_|_],
    findall(_{lesson: Lesson, reason: Reason, span_count: SpanCount},
            task_span_absence_registry:lesson_one_parser_away(
                Lesson, Reason, SpanCount),
            OneParserAway),
    Dict = task_span_backlog{
        reason_queue: ReasonQueue,
        one_parser_away: OneParserAway
    }.


%!  metaphor_coverage_dict(+Metaphor, -Dict) is semidet.
%
%   Return the renderer receipt for Metaphor. Status and each evidence term
%   are rendered as text so the dispatch result remains a JSON value. Fails
%   when the generated registry carries no renderer receipt for Metaphor.
metaphor_coverage_dict(Metaphor, Dict) :-
    atom(Metaphor),
    coverage_absence_registry:coverage_receipt(
        metaphor(Metaphor), renderer, Status, Evidence),
    term_string(Status, StatusText, [quoted(false)]),
    maplist(index_term_string, Evidence, EvidenceText),
    Dict = metaphor_coverage{
        metaphor: Metaphor,
        status: StatusText,
        evidence: EvidenceText
    }.


%!  coverage_backlog_dict(-Dict) is semidet.
%
%   Return every metaphor without a renderer and counts of the two lesson
%   receipt gaps. Fails when no metaphor renderer gap remains.
coverage_backlog_dict(Dict) :-
    findall(_{metaphor: Metaphor, status: StatusText},
            ( coverage_absence_registry:metaphor_without_renderer(
                  Metaphor, Status),
              term_string(Status, StatusText, [quoted(false)])
            ),
            MetaphorsWithoutRenderer),
    MetaphorsWithoutRenderer = [_|_],
    findall(Lesson,
            coverage_absence_registry:lesson_without_standard_anchor(
                Lesson, _StandardStatus),
            LessonsWithoutStandardAnchor),
    length(LessonsWithoutStandardAnchor, StandardAnchorCount),
    findall(Lesson,
            coverage_absence_registry:lesson_without_structured_negative(
                Lesson, _NegativeStatus),
            LessonsWithoutStructuredNegative),
    length(LessonsWithoutStructuredNegative, StructuredNegativeCount),
    Dict = coverage_backlog{
        metaphors_without_renderer: MetaphorsWithoutRenderer,
        lessons_without_standard_anchor: StandardAnchorCount,
        lessons_without_structured_negative: StructuredNegativeCount
    }.

index_term_string(Term, Text) :-
    term_string(Term, Text, [quoted(false)]).
