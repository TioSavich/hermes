/** <module> Provenance-bearing adjudication of interactional trace proposals

Deterministic transcript evidence does not become an interactional trace event
by itself. This module validates an explicit proposal that cites stable evidence
candidate IDs, records an attributed reviewer decision, and compiles only
accepted proposals to `trace_event/4` terms. A reviewer may be a human or a
named model-based review; the provenance must say which. The module does not
assign a PML operator or validity mode.

Terms:

  trace_proposal(Id, TraceEvent, EvidenceCandidateIds,
                 proposal_meta(Proposer, Source, CreatedAt))

  adjudication(ProposalId, Status,
               adjudication_meta(Reviewer, Source, ReviewedAt, Rationale))

Status is `accepted`, `rejected`, or `deferred`. A missing ledger entry is
reported as `unreviewed` but is never compiled.
*/
:- module(trace_adjudication, [
    valid_trace_proposal/3,       % valid_trace_proposal(+Utterances, +Candidates, +Proposal)
    valid_trace_proposals/3,      % valid_trace_proposals(+Utterances, +Candidates, +Proposals)
    valid_adjudication/2,         % valid_adjudication(+Proposals, +Entry)
    valid_adjudication_ledger/2,  % valid_adjudication_ledger(+Proposals, +Ledger)
    proposal_status/3,            % proposal_status(+Proposal, +Ledger, -Status)
    compile_adjudicated_trace/5,  % compile_adjudicated_trace(+Utterances,+Candidates,+Proposals,+Ledger,-Event)
    adjudication_summary/5,       % adjudication_summary(+Utterances,+Candidates,+Proposals,+Ledger,-Dict)
    adjudication_dict_terms/3,    % adjudication_dict_terms(+JSONDict,-Proposals,-Ledger)
    adjudication_markdown/2       % adjudication_markdown(+Summary,-Markdown)
]).

:- use_module(pml(interactional_trace),
              [ valid_trace_event/1,
                trace_event_dict/2 ]).
:- use_module(library(error)).
:- use_module(library(http/json)).
:- use_module(library(lists)).

%! valid_trace_proposal(+Utterances, +Candidates, +Proposal) is semidet.
valid_trace_proposal(
    Utterances,
    Candidates,
    trace_proposal(ProposalId, Event, EvidenceIds,
                   proposal_meta(Proposer, Source, CreatedAt))) :-
    valid_evidence_candidates(Utterances, Candidates),
    nonempty_text(ProposalId),
    valid_trace_event(Event),
    Event = trace_event(_EventId, EventSpan, _Codes, _Meta),
    valid_utterance_span(Utterances, EventSpan),
    is_list(EvidenceIds),
    EvidenceIds \= [],
    sort(EvidenceIds, UniqueEvidenceIds),
    same_length(EvidenceIds, UniqueEvidenceIds),
    forall(member(EvidenceId, EvidenceIds),
           cited_candidate_within_event(
               Utterances, Candidates, EvidenceId, EventSpan)),
    nonempty_text(Proposer),
    nonempty_text(Source),
    nonempty_text(CreatedAt),
    !.

%! valid_trace_proposals(+Utterances, +Candidates, +Proposals) is semidet.
valid_trace_proposals(Utterances, Candidates, Proposals) :-
    is_list(Proposals),
    maplist(valid_trace_proposal(Utterances, Candidates), Proposals),
    findall(Id,
            member(trace_proposal(Id, _Event, _Evidence, _Meta), Proposals),
            Ids),
    sort(Ids, UniqueIds),
    same_length(Ids, UniqueIds),
    !.

%! valid_adjudication(+Proposals, +Entry) is semidet.
valid_adjudication(
    Proposals,
    adjudication(ProposalId, Status,
                 adjudication_meta(Reviewer, Source, ReviewedAt, Rationale))) :-
    memberchk(trace_proposal(ProposalId, _Event, _Evidence, _Meta), Proposals),
    adjudication_status(Status),
    nonempty_text(Reviewer),
    nonempty_text(Source),
    nonempty_text(ReviewedAt),
    nonempty_text(Rationale),
    !.

adjudication_status(accepted).
adjudication_status(rejected).
adjudication_status(deferred).

%! valid_adjudication_ledger(+Proposals, +Ledger) is semidet.
%
%  Ledgers may be partial. Proposals without an entry remain `unreviewed`.
valid_adjudication_ledger(Proposals, Ledger) :-
    is_list(Ledger),
    maplist(valid_adjudication(Proposals), Ledger),
    findall(Id,
            member(adjudication(Id, _Status, _Meta), Ledger),
            Ids),
    sort(Ids, UniqueIds),
    same_length(Ids, UniqueIds),
    !.

%! proposal_status(+Proposal, +Ledger, -Status) is det.
proposal_status(trace_proposal(Id, _Event, _Evidence, _Meta), Ledger, Status) :-
    (   memberchk(adjudication(Id, ReviewedStatus, _ReviewMeta), Ledger)
    ->  Status = ReviewedStatus
    ;   Status = unreviewed
    ).

%! compile_adjudicated_trace(+Utterances, +Candidates, +Proposals, +Ledger, -Event) is nondet.
compile_adjudicated_trace(Utterances, Candidates, Proposals, Ledger, Event) :-
    valid_trace_proposals(Utterances, Candidates, Proposals),
    valid_adjudication_ledger(Proposals, Ledger),
    member(trace_proposal(ProposalId, Event, _EvidenceIds, _ProposalMeta),
           Proposals),
    memberchk(adjudication(ProposalId, accepted, _AdjudicationMeta), Ledger).

%! adjudication_summary(+Utterances, +Candidates, +Proposals, +Ledger, -Dict) is det.
adjudication_summary(Utterances, Candidates, Proposals, Ledger, Summary) :-
    valid_trace_proposals(Utterances, Candidates, Proposals),
    valid_adjudication_ledger(Proposals, Ledger),
    maplist(proposal_row(Ledger), Proposals, ProposalRows),
    findall(Status,
            ( member(Proposal, Proposals),
              proposal_status(Proposal, Ledger, Status)
            ),
            Statuses),
    status_counts(Statuses, StatusCounts),
    findall(Event,
            compile_adjudicated_trace(
                Utterances, Candidates, Proposals, Ledger, Event),
            Events),
    maplist(trace_event_dict, Events, EventDicts),
    referenced_evidence_ids(Proposals, ReferencedIds),
    findall(CandidateDict,
            ( member(Id, ReferencedIds),
              member(Candidate, Candidates),
              Candidate = evidence_candidate(Id, _Layer, _Span, _Payload),
              evidence_candidate_dict(Candidate, CandidateDict)
            ),
            ReferencedEvidence),
    length(Proposals, ProposalCount),
    length(Ledger, AdjudicationCount),
    length(EventDicts, CompiledCount),
    Summary = _{
        provenance: "explicit_reviewer_adjudication_ledger_over_deterministic_candidates",
        proposal_count: ProposalCount,
        adjudication_count: AdjudicationCount,
        status_counts: StatusCounts,
        compiled_trace_count: CompiledCount,
        proposals: ProposalRows,
        referenced_evidence: ReferencedEvidence,
        compiled_trace_events: EventDicts,
        limits: _{
            automation: "evidence candidates do not promote themselves",
            review: "only an explicit accepted adjudication compiles",
            pml: "no PML operator or S/O/N mode is assigned"
        }
    },
    !.

valid_evidence_candidates(Utterances, Candidates) :-
    is_list(Candidates),
    maplist(valid_evidence_candidate(Utterances), Candidates),
    findall(Id,
            member(evidence_candidate(Id, _Layer, _Span, _Payload),
                   Candidates),
            Ids),
    sort(Ids, UniqueIds),
    same_length(Ids, UniqueIds),
    !.

valid_evidence_candidate(
    Utterances,
    evidence_candidate(Id, Layer, Span, Payload)) :-
    nonempty_text(Id),
    evidence_layer(Layer),
    valid_utterance_span(Utterances, Span),
    ground(Payload),
    acyclic_term(Payload).

evidence_layer(pragmatic_atom).
evidence_layer(pragmatic_relation).

cited_candidate_within_event(
    Utterances, Candidates, EvidenceId, EventSpan) :-
    memberchk(evidence_candidate(EvidenceId, _Layer, CandidateSpan, _Payload),
              Candidates),
    span_contains(Utterances, EventSpan, CandidateSpan).

valid_utterance_span(Utterances, span(From, To)) :-
    utterance_index(Utterances, From, FromIndex),
    utterance_index(Utterances, To, ToIndex),
    FromIndex =< ToIndex.

span_contains(Utterances, span(OuterFrom, OuterTo),
              span(InnerFrom, InnerTo)) :-
    utterance_index(Utterances, OuterFrom, OuterFromIndex),
    utterance_index(Utterances, OuterTo, OuterToIndex),
    utterance_index(Utterances, InnerFrom, InnerFromIndex),
    utterance_index(Utterances, InnerTo, InnerToIndex),
    OuterFromIndex =< InnerFromIndex,
    InnerToIndex =< OuterToIndex.

utterance_index(Utterances, Id, Index) :-
    nth1(Index, Utterances, utterance(ActualId, _Speaker, _Text)),
    same_text_identifier(Id, ActualId),
    !.

same_text_identifier(Left, Right) :-
    identifier_string(Left, LeftString),
    identifier_string(Right, RightString),
    string_lower(LeftString, LeftLower),
    string_lower(RightString, RightLower),
    LeftLower == RightLower.

identifier_string(Value, String) :-
    (   string(Value)
    ->  String = Value
    ;   atom(Value)
    ->  atom_string(Value, String)
    ).

proposal_row(Ledger,
             trace_proposal(Id, Event, EvidenceIds,
                            proposal_meta(Proposer, Source, CreatedAt)),
             Row) :-
    trace_event_dict(Event, EventDict),
    proposal_status(
        trace_proposal(Id, Event, EvidenceIds,
                       proposal_meta(Proposer, Source, CreatedAt)),
        Ledger,
        Status),
    adjudication_row(Id, Ledger, AdjudicationDict),
    Row = _{id: Id, status: Status, trace_event: EventDict,
            evidence_candidate_ids: EvidenceIds,
            proposal_meta: _{proposer: Proposer, source: Source,
                             created_at: CreatedAt},
            adjudication: AdjudicationDict}.

adjudication_row(Id, Ledger, Dict) :-
    (   memberchk(
            adjudication(
                Id, Status,
                adjudication_meta(Reviewer, Source, ReviewedAt, Rationale)),
            Ledger)
    ->  Dict = _{status: Status, reviewer: Reviewer, source: Source,
                 reviewed_at: ReviewedAt, rationale: Rationale}
    ;   Dict = null
    ).

evidence_candidate_dict(
    evidence_candidate(Id, Layer, span(From, To), Payload),
    _{candidate_id: Id, layer: Layer,
      span: _{from: From, to: To}, payload: PayloadString}) :-
    term_string(Payload, PayloadString, [quoted(true), numbervars(true)]).

referenced_evidence_ids(Proposals, Ids) :-
    findall(Id,
            ( member(trace_proposal(_ProposalId, _Event, EvidenceIds, _Meta),
                     Proposals),
              member(Id, EvidenceIds)
            ),
            RawIds),
    sort(RawIds, Ids).

status_counts(Statuses, Counts) :-
    findall(_{status: Status, count: Count},
            ( member(Status, [accepted, rejected, deferred, unreviewed]),
              include(==(Status), Statuses, Matching),
              length(Matching, Count)
            ),
            Counts).

%! adjudication_dict_terms(+JSONDict, -Proposals, -Ledger) is semidet.
adjudication_dict_terms(Dict, Proposals, Ledger) :-
    is_dict(Dict),
    dict_keys_exact(Dict, [adjudications, proposals]),
    get_dict(proposals, Dict, ProposalDicts),
    is_list(ProposalDicts),
    maplist(proposal_dict_term, ProposalDicts, Proposals),
    get_dict(adjudications, Dict, AdjudicationDicts),
    is_list(AdjudicationDicts),
    maplist(adjudication_dict_term, AdjudicationDicts, Ledger).

proposal_dict_term(
    Dict,
    trace_proposal(
        ProposalId, Event, EvidenceIds,
        proposal_meta(Proposer, Source, CreatedAt))) :-
    is_dict(Dict),
    dict_keys_exact(
        Dict,
        [created_at, evidence_candidate_ids, id, proposer, source,
         trace_event]),
    json_identifier(Dict.id, ProposalId),
    trace_event_dict_term(Dict.trace_event, Event),
    is_list(Dict.evidence_candidate_ids),
    maplist(json_candidate_id, Dict.evidence_candidate_ids, EvidenceIds),
    json_identifier(Dict.proposer, Proposer),
    json_text(Dict.source, Source),
    json_text(Dict.created_at, CreatedAt).

trace_event_dict_term(
    Dict,
    trace_event(Id, span(From, To), Codes,
                trace_meta(Actor, Certifier, Condition))) :-
    is_dict(Dict),
    dict_keys_exact(
        Dict,
        [actor, certifier, codes, condition, from, id, to]),
    json_identifier(Dict.id, Id),
    json_identifier(Dict.from, From),
    json_identifier(Dict.to, To),
    is_list(Dict.codes),
    maplist(json_trace_code, Dict.codes, Codes),
    json_identifier(Dict.actor, Actor),
    json_certifier(Dict.certifier, Certifier),
    json_condition(Dict.condition, Condition).

json_trace_code(Value, Code) :-
    json_identifier(Value, Code),
    memberchk(Code,
              [opening, closure_bid, uptake, non_uptake, reopening,
               conditional_reopening, settlement]).

json_certifier(null, none) :-
    !.
json_certifier(Dict, authority(Actor)) :-
    is_dict(Dict),
    dict_keys_exact(Dict, [actor, kind]),
    json_identifier(Dict.kind, authority),
    json_identifier(Dict.actor, Actor).
json_certifier(Dict, convergence(Actors)) :-
    is_dict(Dict),
    dict_keys_exact(Dict, [actors, kind]),
    json_identifier(Dict.kind, convergence),
    is_list(Dict.actors),
    maplist(json_identifier, Dict.actors, Actors).

json_condition(null, none) :-
    !.
json_condition(Dict, required_if(Condition)) :-
    is_dict(Dict),
    dict_keys_exact(Dict, [kind, value]),
    json_identifier(Dict.kind, required_if),
    json_identifier(Dict.value, Condition).

adjudication_dict_term(
    Dict,
    adjudication(
        ProposalId, Status,
        adjudication_meta(Reviewer, Source, ReviewedAt, Rationale))) :-
    is_dict(Dict),
    dict_keys_exact(
        Dict,
        [proposal_id, rationale, reviewed_at, reviewer, source, status]),
    json_identifier(Dict.proposal_id, ProposalId),
    json_identifier(Dict.status, Status),
    adjudication_status(Status),
    json_identifier(Dict.reviewer, Reviewer),
    json_text(Dict.source, Source),
    json_text(Dict.reviewed_at, ReviewedAt),
    json_text(Dict.rationale, Rationale).

json_candidate_id(Value, Id) :-
    string(Value),
    Value \== "",
    Id = Value.

json_identifier(Value, Atom) :-
    (   string(Value)
    ->  Value \== "",
        atom_string(Atom, Value)
    ;   atom(Value)
    ->  Value \== '',
        Atom = Value
    ).

json_text(Value, Text) :-
    (   string(Value)
    ->  Value \== "",
        Text = Value
    ;   atom(Value)
    ->  Value \== '',
        Text = Value
    ).

dict_keys_exact(Dict, AllowedKeys) :-
    dict_pairs(Dict, _Tag, Pairs),
    findall(Key, member(Key-_Value, Pairs), Keys),
    sort(Keys, SortedKeys),
    sort(AllowedKeys, SortedAllowed),
    SortedKeys == SortedAllowed.

%! adjudication_markdown(+Summary, -Markdown) is det.
adjudication_markdown(Summary, Markdown) :-
    with_output_to(string(Markdown), write_adjudication_markdown(Summary)).

write_adjudication_markdown(Summary) :-
    format("# TalkMoves trace adjudication ledger~n~n", []),
    format("Register: **reviewer-attributed adjudication, not validation.**~n~n", []),
    format("Proposals: ~d. Adjudications: ~d. Compiled trace events: ~d.~n~n",
           [Summary.proposal_count, Summary.adjudication_count,
            Summary.compiled_trace_count]),
    format("## Status inventory~n~n", []),
    format("| status | count |~n| --- | ---: |~n", []),
    forall(member(StatusRow, Summary.status_counts),
           format("| `~w` | ~d |~n",
                  [StatusRow.status, StatusRow.count])),
    nl,
    format("## Trace proposals~n~n", []),
    format("| proposal | status | span | codes | evidence | reviewer |~n", []),
    format("| --- | --- | --- | --- | ---: | --- |~n", []),
    forall(member(Proposal, Summary.proposals),
           write_proposal_markdown_row(Proposal)),
    nl,
    format("## Referenced deterministic evidence~n~n", []),
    format("| candidate id | layer | span | payload |~n", []),
    format("| --- | --- | --- | --- |~n", []),
    forall(member(Evidence, Summary.referenced_evidence),
           write_evidence_markdown_row(Evidence)),
    nl,
    format("## Compiled trace events~n~n", []),
    forall(member(Event, Summary.compiled_trace_events),
           ( compact_json(Event, EventJSON),
             format("- `~s`~n", [EventJSON]) )),
    ( Summary.compiled_trace_events == [] -> format("- none~n", []) ; true ),
    nl,
    format("## Limits~n~n", []),
    format("- ~s~n", [Summary.limits.automation]),
    format("- ~s~n", [Summary.limits.review]),
    format("- ~s~n", [Summary.limits.pml]).

write_proposal_markdown_row(Proposal) :-
    length(Proposal.evidence_candidate_ids, EvidenceCount),
    reviewer_label(Proposal.adjudication, Reviewer),
    format("| `~w` | `~w` | `~w`-`~w` | `~w` | ~d | `~w` |~n",
           [Proposal.id, Proposal.status,
            Proposal.trace_event.span.from, Proposal.trace_event.span.to,
            Proposal.trace_event.codes, EvidenceCount, Reviewer]).

reviewer_label(null, unreviewed) :-
    !.
reviewer_label(Adjudication, Reviewer) :-
    Reviewer = Adjudication.reviewer.

write_evidence_markdown_row(Evidence) :-
    markdown_cell(Evidence.payload, Payload),
    format("| `~s` | `~w` | `~w`-`~w` | `~s` |~n",
           [Evidence.candidate_id, Evidence.layer,
            Evidence.span.from, Evidence.span.to, Payload]).

compact_json(Dict, String) :-
    with_output_to(string(String),
                   json_write_dict(current_output, Dict, [width(0)])).

markdown_cell(Input, Output) :-
    split_string(Input, "|\n\r", "", Parts),
    atomics_to_string(Parts, " ", Output).

nonempty_text(Value) :-
    (   string(Value)
    ->  Value \== ""
    ;   atom(Value)
    ->  Value \== ''
    ).
