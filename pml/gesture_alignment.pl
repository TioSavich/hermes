/** <module> Timestamped physical gesture observations into discourse context

An upstream video model or human observer may supply a gesture interval without
knowing which utterance should carry it. This module compares that interval to
validated turn timings. Every positive temporal overlap remains visible as a
candidate. A gesture_event/5 context term is compiled only when one utterance
has the unique greatest overlap. Equal best overlaps and observations outside
all timed turns remain unassigned.

This module validates and aligns attributed observations. It does not inspect
video, establish that a gesture occurred, resolve an unresolved target, or
infer deixis, uptake, tension, trace, or PML by itself.
*/
:- module(gesture_alignment, [
    align_gesture_observations/4
    % align_gesture_observations(+Utterances,+Context,+ObservationDicts,-Bundle)
]).

:- use_module(pml(discourse_features),
              [ valid_context_evidence/2,
                analyze_transcript/3 ]).
:- use_module(library(lists)).

%! align_gesture_observations(+Utterances, +Context, +ObservationDicts,
%!                            -Bundle) is semidet.
align_gesture_observations(Utterances, Context, ObservationDicts, Bundle) :-
    is_list(Utterances),
    is_list(Context),
    is_list(ObservationDicts),
    valid_context_evidence(Utterances, Context),
    number_observations(
        ObservationDicts, Context, 1, Observations, NormalizedObservations),
    maplist(align_one_observation(Utterances, Context),
            Observations, CandidateLists, CompiledLists, Assignments),
    append(CandidateLists, Candidates),
    append(CompiledLists, CompiledGestures),
    maplist(candidate_dict, Candidates, CandidateDicts),
    maplist(compiled_gesture_dict, CompiledGestures, CompiledGestureDicts),
    append(Context, CompiledGestures, CombinedContext),
    sort(CombinedContext, EnhancedContext),
    valid_context_evidence(Utterances, EnhancedContext),
    analyze_transcript(Utterances, EnhancedContext, SurfaceAnalysis),
    length(Observations, ObservationCount),
    length(Candidates, CandidateCount),
    length(CompiledGestures, CompiledCount),
    Bundle = _{
        provenance: "attributed_gesture_intervals_aligned_by_prolog",
        observation_count: ObservationCount,
        candidate_count: CandidateCount,
        compiled_gesture_count: CompiledCount,
        observations: NormalizedObservations,
        candidates: CandidateDicts,
        assignments: Assignments,
        gesture_context: _{gestures: CompiledGestureDicts},
        surface_analysis: SurfaceAnalysis,
        limits: _{
            observation: "gesture kind, interval, target, source, and confidence remain supplied evidence",
            alignment: "only positive interval overlap is considered; equal best overlaps remain ambiguous",
            target: "unresolved stays unresolved; declared targets are checked against supplied referents",
            interpretation: "no physical event, deictic reference, uptake, tension, trace, or PML reading is established by temporal alignment alone"
        }
    }.

number_observations([], _Context, _Index, [], []).
number_observations([Dict | Dicts], Context, Index,
                    [Observation | Observations],
                    [Normalized | NormalizedObservations]) :-
    observation_dict_term(Dict, Context, Index, Observation, Normalized),
    NextIndex is Index + 1,
    number_observations(Dicts, Context, NextIndex,
                        Observations, NormalizedObservations).

observation_dict_term(
    Dict, Context, Index,
    gesture_observation(Id, Kind, StartMs, EndMs,
                        Target, Source, Confidence),
    _{id: Id, kind: Kind, start_ms: StartMs, end_ms: EndMs,
      target: Target, source: Source, confidence: Confidence}) :-
    is_dict(Dict),
    strict_dict_keys(
        Dict, [kind, start_ms, end_ms, target, source, confidence]),
    get_dict(kind, Dict, JSONKind),
    enum_value(JSONKind,
               [pointing, head_movement, inscription_action,
                repositioning, object_handling, gesture_unspecified],
               Kind),
    get_dict(start_ms, Dict, StartMs),
    integer(StartMs),
    StartMs >= 0,
    get_dict(end_ms, Dict, EndMs),
    integer(EndMs),
    EndMs > StartMs,
    get_dict(target, Dict, JSONTarget),
    observation_target(JSONTarget, Context, Target),
    get_dict(source, Dict, Source),
    nonempty_text(Source),
    get_dict(confidence, Dict, JSONConfidence),
    enum_value(JSONConfidence, [exact, high, medium, low], Confidence),
    format(string(Id), "g~|~`0t~d~4+", [Index]).

align_one_observation(Utterances, Context, Observation,
                      Candidates, Compiled, Assignment) :-
    findall(Candidate,
            gesture_overlap_candidate(
                Utterances, Context, Observation, Candidate),
            Candidates),
    observation_assignment(Observation, Candidates, Compiled, Assignment).

gesture_overlap_candidate(
    Utterances, Context,
    gesture_observation(ObservationId, Kind, GestureStart, GestureEnd,
                        Target, ObservationSource, Confidence),
    gesture_alignment_candidate(
        ObservationId, UtteranceId, Kind, Target,
        overlap_ms(OverlapMs), turn_timing(TimingSource),
        ObservationSource, Confidence)) :-
    member(utterance(UtteranceId, _Speaker, _Text), Utterances),
    memberchk(turn_timing(
                  UtteranceId, TurnStart, TurnEnd, TimingSource), Context),
    interval_overlap_ms(
        GestureStart, GestureEnd, TurnStart, TurnEnd, OverlapMs),
    OverlapMs > 0.

interval_overlap_ms(LeftStart, LeftEnd, RightStart, RightEnd, OverlapMs) :-
    Start is max(LeftStart, RightStart),
    End is min(LeftEnd, RightEnd),
    OverlapMs is max(0, End - Start).

observation_assignment(
    gesture_observation(ObservationId, _Kind, _Start, _End,
                        _Target, _Source, _Confidence),
    [], [],
    _{observation_id: ObservationId,
      status: no_temporal_overlap}) :-
    !.
observation_assignment(Observation, Candidates, Compiled, Assignment) :-
    maximum_overlap_candidates(Candidates, MaximumOverlap, BestCandidates),
    (   BestCandidates = [
            gesture_alignment_candidate(
                ObservationId, UtteranceId, Kind, Target,
                overlap_ms(MaximumOverlap), _Timing,
                Source, Confidence)]
    ->  Compiled = [gesture_event(
                        UtteranceId, Kind, Target, Source, Confidence)],
        Assignment = _{observation_id: ObservationId,
                       status: unique_best_overlap,
                       utterance_id: UtteranceId,
                       overlap_ms: MaximumOverlap}
    ;   Observation = gesture_observation(
                          ObservationId, _Kind, _Start, _End,
                          _Target, _Source, _Confidence),
        findall(UtteranceId,
                member(gesture_alignment_candidate(
                           _ObservationId, UtteranceId, _CandidateKind,
                           _CandidateTarget, overlap_ms(MaximumOverlap),
                           _CandidateTiming, _CandidateSource,
                           _CandidateConfidence),
                       BestCandidates),
                UtteranceIds),
        Compiled = [],
        Assignment = _{observation_id: ObservationId,
                       status: ambiguous_best_overlap,
                       overlap_ms: MaximumOverlap,
                       utterance_ids: UtteranceIds}
    ).

maximum_overlap_candidates(Candidates, Maximum, Best) :-
    findall(Overlap,
            member(gesture_alignment_candidate(
                       _ObservationId, _UtteranceId, _Kind, _Target,
                       overlap_ms(Overlap), _Timing, _Source, _Confidence),
                   Candidates),
            Overlaps),
    max_list(Overlaps, Maximum),
    include(candidate_has_overlap(Maximum), Candidates, Best).

candidate_has_overlap(
    Maximum,
    gesture_alignment_candidate(
        _ObservationId, _UtteranceId, _Kind, _Target,
        overlap_ms(Maximum), _Timing, _Source, _Confidence)).

candidate_dict(
    gesture_alignment_candidate(
        ObservationId, UtteranceId, Kind, Target,
        overlap_ms(OverlapMs), turn_timing(TimingSource),
        ObservationSource, Confidence),
    _{observation_id: ObservationId, utterance_id: UtteranceId,
      kind: Kind, target: Target, overlap_ms: OverlapMs,
      timing_source: TimingSource, observation_source: ObservationSource,
      confidence: Confidence, status: temporal_overlap_candidate}).

compiled_gesture_dict(
    gesture_event(UtteranceId, Kind, Target, Source, Confidence),
    _{utterance_id: UtteranceId, kind: Kind, target: Target,
      source: Source, confidence: Confidence}).

observation_target("unresolved", _Context, unresolved) :-
    !.
observation_target(unresolved, _Context, unresolved) :-
    !.
observation_target(JSONTarget, Context, Target) :-
    member(referent(Target, _Kind, _Label), Context),
    same_identifier(JSONTarget, Target),
    !.

same_identifier(Left, Right) :-
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

enum_value(JSONValue, Allowed, Value) :-
    (   string(JSONValue)
    ->  atom_string(Value, JSONValue)
    ;   atom(JSONValue)
    ->  Value = JSONValue
    ),
    memberchk(Value, Allowed).

strict_dict_keys(Dict, Allowed) :-
    dict_pairs(Dict, _Tag, Pairs),
    findall(Key, member(Key-_, Pairs), Keys),
    sort(Keys, SortedKeys),
    sort(Allowed, SortedAllowed),
    SortedKeys == SortedAllowed.

nonempty_text(Value) :-
    identifier_string(Value, String),
    normalize_space(string(Normalized), String),
    Normalized \== "".
