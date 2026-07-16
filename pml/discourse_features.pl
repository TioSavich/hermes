/** <module> Deterministic transcript features and candidate relations

    This module extracts surface evidence that can support later discourse and
    PML analysis. It does not assign a PML mode or operator, infer emotional
    tension, measure unrecorded wait time, or resolve anaphora.

    Input transcripts use:

      utterance(Id, Speaker, Text)

    Optional supplied context uses a flat evidence list. Supported terms are
    documented by valid_context_evidence/2. Timing, alias, gesture, and
    reference metadata remain attributed evidence; this module does not claim
    that an upstream audio or video model is correct.

    utterance_feature/2 exposes queryable feature terms. transcript_relation/2
    exposes bounded candidate relations across utterances. analyze_transcript/2
    returns the same evidence as a JSON-safe dict for application boundaries.
*/
:- module(discourse_features, [
    utterance_feature/2,    % utterance_feature(+Text, -Feature)
    transcript_relation/2, % transcript_relation(+Utterances, -Relation)
    transcript_relation/3, % transcript_relation(+Utterances, +Context, -Relation)
    analyze_transcript/2,  % analyze_transcript(+Utterances, -AnalysisDict)
    analyze_transcript/3,  % analyze_transcript(+Utterances, +Context, -AnalysisDict)
    valid_context_evidence/2, % valid_context_evidence(+Utterances, +Context)
    context_dict_evidence/3, % context_dict_evidence(+Utterances, +Dict, -Context)
    utterance_tokens/2       % utterance_tokens(+Text, -LowercaseTokens)
]).

:- use_module(library(pcre)).
:- use_module(library(lists)).
:- use_module(library(error)).

%! utterance_feature(+Text, -Feature) is nondet.
%
%  Surface features remain evidence rather than interpretations. Counts matter:
%  repeated filled pauses and restarts are preserved rather than collapsed.
utterance_feature(Text, hesitation(filled_pause, Marker, count(Count), exact)) :-
    text_tokens(Text, Tokens),
    filled_pause(Marker),
    token_count(Marker, Tokens, Count),
    Count > 0.
utterance_feature(Text, hesitation(discourse_filler, you_know,
                                    count(Count), context_dependent)) :-
    text_tokens(Text, Tokens),
    hesitation_marker_sequence(Tokens, Markers),
    token_count(you_know, Markers, Count),
    Count > 0.
utterance_feature(Text,
                  hesitation_cluster(Markers, count(Count), surface_order)) :-
    text_tokens(Text, Tokens),
    hesitation_marker_sequence(Tokens, Markers),
    length(Markers, Count),
    Count >= 2.
utterance_feature(Text, repair_marker(i_mean, count(Count),
                                      context_dependent)) :-
    text_tokens(Text, Tokens),
    sequence_count([i, mean], Tokens, Count),
    Count > 0.
utterance_feature(Text, restart(repeated_token(Token), count(Count), candidate)) :-
    text_tokens(Text, Tokens),
    adjacent_repeat_counts(Tokens, Counts),
    member(Token-Count, Counts).
utterance_feature(Text, pause(explicit_annotation, Duration, Surface, exact)) :-
    text_string(Text, String),
    pause_annotation_surface(String, Surface),
    annotation_duration(Surface, Duration).
utterance_feature(Text, pause(possible_punctuation, duration_unknown,
                              ellipsis, count(Count))) :-
    text_string(Text, String),
    ellipsis_count(String, Count),
    Count > 0.
utterance_feature(Text, cutoff_or_interruption(double_hyphen, count(Count),
                                               candidate)) :-
    text_string(Text, String),
    regex_match_count("--+", String, Count),
    Count > 0.
utterance_feature(Text,
                  response_gap(explicit_no_verbal_response,
                               Surface, transcript_only)) :-
    text_string(Text, String),
    no_verbal_response_surface(String, Surface).
utterance_feature(Text, deixis(Type, Token, count(Count))) :-
    text_tokens(Text, Tokens),
    deictic_token(Token, Type),
    deixis_occurrence_count(Token, Tokens, Count),
    Count > 0.
utterance_feature(Text, anaphor(Type, Marker, count(Count), candidate)) :-
    text_tokens(Text, Tokens),
    anaphor_pattern(Marker, Type, Pattern),
    anaphor_occurrence_count(Marker, Pattern, Tokens, Count),
    Count > 0.
utterance_feature(
    Text,
    nominal_anaphor(demonstrative, Marker, Head,
                     count(Count), bounded_math_lexicon)) :-
    text_tokens(Text, Tokens),
    demonstrative_nominal(Tokens, Marker, Head, Count).
utterance_feature(Text, gesture(Kind, Surface, target_unresolved, exact)) :-
    text_string(Text, String),
    gesture_annotation_surface(String, Surface),
    gesture_kind(Surface, Kind).
utterance_feature(Text, gesture(verbal_pointing, Marker,
                                target_unresolved, context_dependent)) :-
    text_tokens(Text, Tokens),
    verbal_gesture_pattern(Marker, Pattern),
    contains_sequence(Pattern, Tokens).
utterance_feature(Text, feature_placing_candidate(existential_there,
                                                  Surface,
                                                  context_dependent)) :-
    text_tokens(Text, Tokens),
    existential_there_surface(Tokens, Surface).
utterance_feature(Text, feature_placing_candidate(ambient_it,
                                                  Surface,
                                                  bounded_lexicon)) :-
    text_tokens(Text, Tokens),
    ambient_it_surface(Tokens, Surface).
utterance_feature(Text, nonreferential_pronoun_candidate(expletive_it,
                                                         Surface,
                                                         bounded_syntax)) :-
    text_tokens(Text, Tokens),
    expletive_it_surface(Tokens, Surface).
utterance_feature(Text, feature_placing_candidate(locative_property,
                                                  Surface,
                                                  bounded_lexicon)) :-
    text_tokens(Text, Tokens),
    locative_property_surface(Tokens, Surface).

%! transcript_relation(+Utterances, -Relation) is nondet.
%
%  Relations are deliberately candidates. Named-speaker links use the most
%  recent prior utterance by that speaker. An unanchored pronoun remains an
%  utterance feature: adjacency alone does not nominate an antecedent.
transcript_relation(Utterances,
                    anaphora_candidate(CurrentId, Marker, AntecedentId,
                                       named_speaker_reference, medium)) :-
    nth1(CurrentIndex, Utterances,
         utterance(CurrentId, _CurrentSpeaker, CurrentText)),
    CurrentIndex > 1,
    prefix_before(CurrentIndex, Utterances, Prior),
    setof(Speaker,
          PriorId^PriorText^
              member(utterance(PriorId, Speaker, PriorText), Prior),
          PriorSpeakers),
    member(AntecedentSpeaker, PriorSpeakers),
    speaker_reference(CurrentText, AntecedentSpeaker, Marker),
    most_recent_speaker_utterance(Prior, AntecedentSpeaker, AntecedentId).
transcript_relation(
    Utterances,
    nominal_anaphora_candidate(
        CurrentId, Marker, Head, AntecedentId,
        exact_head_recurrence(
            turn_distance(Distance),
            prior_head_mentions(PriorMentionCount),
            window(12)),
        Confidence, unresolved)) :-
    nth1(CurrentIndex, Utterances,
         utterance(CurrentId, _CurrentSpeaker, CurrentText)),
    CurrentIndex > 1,
    utterance_feature(
        CurrentText,
        nominal_anaphor(demonstrative, Marker, Head,
                         _Count, bounded_math_lexicon)),
    prefix_before(CurrentIndex, Utterances, Prior),
    recent_prior_window(Prior, 12, Window),
    findall(PriorId,
            ( member(utterance(PriorId, _Speaker, PriorText), Window),
              once(nominal_head_mention(PriorText, Head))
            ),
            RawPriorIds),
    list_to_set(RawPriorIds, PriorIds),
    PriorIds \= [],
    last(PriorIds, AntecedentId),
    length(PriorIds, PriorMentionCount),
    nominal_link_confidence(PriorMentionCount, Confidence),
    nth1(AntecedentIndex, Utterances,
         utterance(AntecedentId, _AntecedentSpeaker, _AntecedentText)),
    Distance is CurrentIndex - AntecedentIndex.
transcript_relation(Utterances,
                    deictic_gesture_candidate(Id, Token, GestureSurface,
                                              same_utterance, medium)) :-
    member(utterance(Id, _Speaker, Text), Utterances),
    utterance_feature(Text, deixis(Type, Token, _Count)),
    spatial_deixis(Type),
    utterance_feature(Text, gesture(pointing, GestureSurface,
                                    target_unresolved, _Confidence)).
transcript_relation(Utterances,
                    tension_relevant_evidence(
                        utterance(Id),
                        hesitation(Marker, count(Count)),
                        surface_text,
                        interpretation_not_assigned)) :-
    member(utterance(Id, _Speaker, Text), Utterances),
    utterance_feature(Text,
                      hesitation(_Subtype, Marker, count(Count), _Confidence)).
transcript_relation(Utterances,
                    tension_relevant_evidence(
                        utterance(Id),
                        hesitation_cluster(Markers, count(Count)),
                        surface_text,
                        interpretation_not_assigned)) :-
    member(utterance(Id, _Speaker, Text), Utterances),
    utterance_feature(Text,
                      hesitation_cluster(Markers, count(Count), surface_order)).

%! transcript_relation(+Utterances, +ContextEvidence, -Relation) is nondet.
%
%  Extend the surface-only relations with explicitly supplied timing, speaker
%  alias, gesture-target, and reference-link evidence. No context term is
%  generated from text by this predicate.
transcript_relation(Utterances, _ContextEvidence, Relation) :-
    transcript_relation(Utterances, Relation).
transcript_relation(Utterances, ContextEvidence, Relation) :-
    context_relation(Utterances, ContextEvidence, Relation).

%! analyze_transcript(+Utterances, -AnalysisDict) is det.
analyze_transcript(Utterances, Analysis) :-
    analyze_transcript(Utterances, [], Analysis).

%! analyze_transcript(+Utterances, +ContextEvidence, -AnalysisDict) is det.
analyze_transcript(Utterances, ContextEvidence, Analysis) :-
    must_be(list, Utterances),
    maplist(valid_utterance, Utterances),
    valid_context_evidence(Utterances, ContextEvidence),
    maplist(utterance_analysis_dict, Utterances, UtteranceDicts),
    findall(Relation,
            transcript_relation(Utterances, ContextEvidence, Relation),
            RawRelations),
    sort(RawRelations, Relations),
    maplist(relation_dict, Relations, RelationDicts),
    maplist(context_evidence_dict, ContextEvidence, ContextDicts),
    length(Utterances, UtteranceCount),
    length(ContextEvidence, ContextEvidenceCount),
    Analysis = _{
        provenance: "deterministic_prolog_surface_features",
        utterance_count: UtteranceCount,
        utterances: UtteranceDicts,
        context_evidence_count: ContextEvidenceCount,
        context_evidence: ContextDicts,
        relations: RelationDicts,
        limits: _{
            tension: "surface cues only; no tension state inferred",
            wait_time: "only transcript annotations or supplied timing metadata are measured; punctuation has unknown duration",
            anaphora: "supplied links, named speakers, and bounded exact-head nominal candidates only; no automatic referent resolution",
            gesture: "transcript annotations or supplied gesture metadata only; no unreported gesture inferred"
        }
    }.

valid_utterance(utterance(Id, Speaker, Text)) :-
    ground(Id),
    ground(Speaker),
    text_string(Text, _).

%! valid_context_evidence(+Utterances, +ContextEvidence) is semidet.
%
%  Supported evidence terms:
%
%    * speaker_alias(Speaker, Alias, Source)
%    * turn_timing(UtteranceId, StartMs, EndMs, Source)
%    * pause_event(FromId, ToId, DurationMs, Source)
%    * referent(Id, Kind, Label)
%    * gesture_event(UtteranceId, Kind, Target, Source, Confidence)
%    * reference_link(UtteranceId, Marker, Target, Source, Confidence)
%
%  Sources are retained as supplied provenance labels. A resolved gesture or
%  reference target must name a declared referent. `unresolved` is legal only
%  for gesture targets.
valid_context_evidence(Utterances, ContextEvidence) :-
    must_be(list, ContextEvidence),
    maplist(valid_context_term(Utterances, ContextEvidence), ContextEvidence),
    sort(ContextEvidence, UniqueEvidence),
    same_length(ContextEvidence, UniqueEvidence),
    findall(Id,
            member(turn_timing(Id, _Start, _End, _Source), ContextEvidence),
            TimingIds),
    sort(TimingIds, UniqueTimingIds),
    same_length(TimingIds, UniqueTimingIds),
    findall(Id,
            member(referent(Id, _Kind, _Label), ContextEvidence),
            ReferentIds),
    sort(ReferentIds, UniqueReferentIds),
    same_length(ReferentIds, UniqueReferentIds),
    unambiguous_aliases(ContextEvidence).

%! context_dict_evidence(+Utterances, +ContextDict, -ContextEvidence) is semidet.
%
%  Convert the Hermes/sidecar JSON dict shape into the canonical evidence-term
%  list, then apply valid_context_evidence/2. Unknown keys are rejected so a
%  misspelled timing or reference field cannot silently disappear.
context_dict_evidence(Utterances, ContextDict, ContextEvidence) :-
    is_dict(ContextDict),
    context_dict_keys(
        ContextDict,
        [speaker_aliases, turn_timings, pause_events,
         referents, gestures, reference_links]),
    context_list_field(speaker_aliases, ContextDict, AliasDicts),
    context_list_field(turn_timings, ContextDict, TimingDicts),
    context_list_field(pause_events, ContextDict, PauseDicts),
    context_list_field(referents, ContextDict, ReferentDicts),
    context_list_field(gestures, ContextDict, GestureDicts),
    context_list_field(reference_links, ContextDict, ReferenceDicts),
    maplist(context_speaker_alias_term(Utterances), AliasDicts, Aliases),
    maplist(context_turn_timing_term(Utterances), TimingDicts, Timings),
    maplist(context_pause_event_term(Utterances), PauseDicts, Pauses),
    maplist(context_referent_term, ReferentDicts, Referents),
    maplist(context_gesture_event_term(Utterances), GestureDicts, Gestures),
    maplist(context_reference_link_term(Utterances),
            ReferenceDicts, References),
    append([Aliases, Timings, Pauses, Referents, Gestures, References],
           ContextEvidence),
    valid_context_evidence(Utterances, ContextEvidence).

context_list_field(Key, Dict, Values) :-
    (   get_dict(Key, Dict, Raw),
        Raw \== null
    ->  is_list(Raw),
        Values = Raw
    ;   Values = []
    ).

context_speaker_alias_term(
    Utterances, Dict, speaker_alias(Speaker, Alias, Source)) :-
    is_dict(Dict),
    context_dict_keys(Dict, [speaker, alias, source]),
    get_dict(speaker, Dict, JSONSpeaker),
    context_speaker_id(Utterances, JSONSpeaker, Speaker),
    get_dict(alias, Dict, Alias),
    context_text_value(Alias),
    get_dict(source, Dict, Source),
    context_text_value(Source).

context_turn_timing_term(
    Utterances, Dict, turn_timing(Id, StartMs, EndMs, Source)) :-
    is_dict(Dict),
    context_dict_keys(Dict, [utterance_id, start_ms, end_ms, source]),
    get_dict(utterance_id, Dict, JSONId),
    context_utterance_id(Utterances, JSONId, Id),
    get_dict(start_ms, Dict, StartMs),
    integer(StartMs),
    get_dict(end_ms, Dict, EndMs),
    integer(EndMs),
    get_dict(source, Dict, Source),
    context_text_value(Source).

context_pause_event_term(
    Utterances, Dict, pause_event(From, To, DurationMs, Source)) :-
    is_dict(Dict),
    context_dict_keys(Dict, [from, to, duration_ms, source]),
    get_dict(from, Dict, JSONFrom),
    context_utterance_id(Utterances, JSONFrom, From),
    get_dict(to, Dict, JSONTo),
    context_utterance_id(Utterances, JSONTo, To),
    get_dict(duration_ms, Dict, DurationMs),
    integer(DurationMs),
    get_dict(source, Dict, Source),
    context_text_value(Source).

context_referent_term(Dict, referent(Id, Kind, Label)) :-
    is_dict(Dict),
    context_dict_keys(Dict, [id, kind, label]),
    get_dict(id, Dict, Id),
    atomic(Id),
    get_dict(kind, Dict, JSONKind),
    context_enum(JSONKind,
                 [representation, inscription, material, person,
                  location, proposition, utterance, other],
                 Kind),
    get_dict(label, Dict, Label),
    context_text_value(Label).

context_gesture_event_term(
    Utterances, Dict,
    gesture_event(Id, Kind, Target, Source, Confidence)) :-
    is_dict(Dict),
    context_dict_keys(
        Dict, [utterance_id, kind, target, source, confidence]),
    get_dict(utterance_id, Dict, JSONId),
    context_utterance_id(Utterances, JSONId, Id),
    get_dict(kind, Dict, JSONKind),
    context_enum(JSONKind,
                 [pointing, head_movement, inscription_action,
                  repositioning, object_handling, gesture_unspecified],
                 Kind),
    get_dict(target, Dict, JSONTarget),
    context_target(JSONTarget, Target),
    get_dict(source, Dict, Source),
    context_text_value(Source),
    get_dict(confidence, Dict, JSONConfidence),
    context_enum(JSONConfidence, [exact, high, medium, low], Confidence).

context_reference_link_term(
    Utterances, Dict,
    reference_link(Id, Marker, Target, Source, Confidence)) :-
    is_dict(Dict),
    context_dict_keys(
        Dict, [utterance_id, marker, target, source, confidence]),
    get_dict(utterance_id, Dict, JSONId),
    context_utterance_id(Utterances, JSONId, Id),
    get_dict(marker, Dict, Marker),
    context_text_value(Marker),
    get_dict(target, Dict, Target),
    atomic(Target),
    get_dict(source, Dict, Source),
    context_text_value(Source),
    get_dict(confidence, Dict, JSONConfidence),
    context_enum(JSONConfidence, [exact, high, medium, low], Confidence).

context_enum(JSONValue, Allowed, Value) :-
    (   string(JSONValue)
    ->  atom_string(Value, JSONValue)
    ;   atom(JSONValue)
    ->  Value = JSONValue
    ),
    memberchk(Value, Allowed).

context_dict_keys(Dict, AllowedKeys) :-
    dict_pairs(Dict, _Tag, Pairs),
    findall(Key, member(Key-_Value, Pairs), Keys),
    sort(Keys, SortedKeys),
    sort(AllowedKeys, SortedAllowed),
    forall(member(Key, SortedKeys), memberchk(Key, SortedAllowed)).

context_target("unresolved", unresolved) :-
    !.
context_target(unresolved, unresolved) :-
    !.
context_target(Target, Target) :-
    atomic(Target).

context_text_value(Value) :-
    string(Value),
    !.
context_text_value(Value) :-
    atom(Value).

context_utterance_id(Utterances, JSONId, Id) :-
    member(utterance(Id, _Speaker, _Text), Utterances),
    same_text_identifier(JSONId, Id),
    !.

context_speaker_id(Utterances, JSONSpeaker, Speaker) :-
    member(utterance(_Id, Speaker, _Text), Utterances),
    same_text_identifier(JSONSpeaker, Speaker),
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

unambiguous_aliases(ContextEvidence) :-
    \+ ( member(speaker_alias(Speaker, Alias, _Source), ContextEvidence),
         member(speaker_alias(OtherSpeaker, Alias, _OtherSource), ContextEvidence),
         Speaker \== OtherSpeaker
       ).

valid_context_term(Utterances, _Context,
                   speaker_alias(Speaker, Alias, Source)) :-
    !,
    utterance_speaker(Utterances, Speaker),
    nonempty_text(Alias),
    nonempty_text(Source).
valid_context_term(Utterances, _Context,
                   turn_timing(Id, StartMs, EndMs, Source)) :-
    !,
    utterance_id(Utterances, Id),
    nonnegative_integer(StartMs),
    nonnegative_integer(EndMs),
    EndMs >= StartMs,
    nonempty_text(Source).
valid_context_term(Utterances, _Context,
                   pause_event(FromId, ToId, DurationMs, Source)) :-
    !,
    utterance_precedes(Utterances, FromId, ToId),
    nonnegative_integer(DurationMs),
    nonempty_text(Source).
valid_context_term(_Utterances, _Context, referent(Id, Kind, Label)) :-
    !,
    ground(Id),
    referent_kind(Kind),
    nonempty_text(Label).
valid_context_term(Utterances, Context,
                   gesture_event(Id, Kind, Target, Source, Confidence)) :-
    !,
    utterance_id(Utterances, Id),
    gesture_event_kind(Kind),
    known_or_unresolved_target(Target, Context),
    nonempty_text(Source),
    evidence_confidence(Confidence).
valid_context_term(Utterances, Context,
                   reference_link(Id, Marker, Target, Source, Confidence)) :-
    !,
    utterance_id(Utterances, Id),
    nonempty_text(Marker),
    known_target(Target, Context),
    nonempty_text(Source),
    evidence_confidence(Confidence).

utterance_id(Utterances, Id) :-
    memberchk(utterance(Id, _Speaker, _Text), Utterances).

utterance_speaker(Utterances, Speaker) :-
    memberchk(utterance(_Id, Speaker, _Text), Utterances).

utterance_precedes(Utterances, FromId, ToId) :-
    nth1(FromIndex, Utterances, utterance(FromId, _FromSpeaker, _FromText)),
    nth1(ToIndex, Utterances, utterance(ToId, _ToSpeaker, _ToText)),
    FromIndex < ToIndex.

nonnegative_integer(Value) :-
    integer(Value),
    Value >= 0.

nonempty_text(Value) :-
    text_string(Value, String),
    String \== "".

known_or_unresolved_target(unresolved, _Context) :-
    !.
known_or_unresolved_target(Target, Context) :-
    known_target(Target, Context).

known_target(Target, Context) :-
    memberchk(referent(Target, _Kind, _Label), Context).

referent_kind(Kind) :-
    memberchk(Kind, [representation, inscription, material, person,
                     location, proposition, utterance, other]).

gesture_event_kind(Kind) :-
    memberchk(Kind, [pointing, head_movement, inscription_action,
                     repositioning, object_handling, gesture_unspecified]).

evidence_confidence(Confidence) :-
    memberchk(Confidence, [exact, high, medium, low]).

context_relation(Utterances, Context,
                 anaphora_candidate(CurrentId, Marker, AntecedentId,
                                    speaker_alias(Source), medium)) :-
    nth1(CurrentIndex, Utterances,
         utterance(CurrentId, _CurrentSpeaker, CurrentText)),
    CurrentIndex > 1,
    prefix_before(CurrentIndex, Utterances, Prior),
    member(speaker_alias(AntecedentSpeaker, Alias, Source), Context),
    speaker_reference(CurrentText, Alias, Marker),
    most_recent_speaker_utterance(Prior, AntecedentSpeaker, AntecedentId).
context_relation(Utterances, Context,
                 temporal_relation(FromId, ToId, Kind,
                                   duration_ms(DurationMs),
                                   turn_timing,
                                   [FromSource, ToSource])) :-
    adjacent_utterances(Utterances,
                        utterance(FromId, _FromSpeaker, _FromText),
                        utterance(ToId, _ToSpeaker, _ToText)),
    memberchk(turn_timing(FromId, _FromStart, FromEnd, FromSource), Context),
    memberchk(turn_timing(ToId, ToStart, _ToEnd, ToSource), Context),
    timing_relation(FromEnd, ToStart, Kind, DurationMs).
context_relation(_Utterances, Context,
                 temporal_relation(FromId, ToId, pause,
                                   duration_ms(DurationMs),
                                   supplied_pause_event,
                                   [Source])) :-
    member(pause_event(FromId, ToId, DurationMs, Source), Context).
context_relation(Utterances, Context,
                 deictic_gesture_candidate_supplied(
                     Id, Token, Kind, Target,
                     GestureSource, ReferenceSource, Confidence)) :-
    member(gesture_event(
               Id, Kind, Target, GestureSource, GestureConfidence), Context),
    member(reference_link(
               Id, Marker0, Target, ReferenceSource, ReferenceConfidence),
           Context),
    memberchk(utterance(Id, _Speaker, Text), Utterances),
    marker_pattern(Marker0, _MarkerKey, MarkerTokens),
    text_tokens(Text, Tokens),
    contains_sequence(MarkerTokens, Tokens),
    member(Token, MarkerTokens),
    deictic_token(Token, Type),
    spatial_deixis(Type),
    utterance_feature(Text, deixis(Type, Token, _Count)),
    weaker_confidence(GestureConfidence, ReferenceConfidence, Confidence).
context_relation(Utterances, Context,
                 reference_candidate(Id, Marker, Target,
                                     supplied_link, Source, Confidence)) :-
    member(reference_link(Id, Marker0, Target, Source, Confidence), Context),
    memberchk(utterance(Id, _Speaker, Text), Utterances),
    marker_pattern(Marker0, Marker, MarkerTokens),
    text_tokens(Text, Tokens),
    contains_sequence(MarkerTokens, Tokens).
context_relation(Utterances, Context,
                 anaphoric_chain_candidate(
                     CurrentId, Marker, Target, AnchorId,
                     AnchorSource, AnchorConfidence,
                     most_recent_explicit_anchor, low)) :-
    nth1(CurrentIndex, Utterances,
         utterance(CurrentId, _CurrentSpeaker, CurrentText)),
    CurrentIndex > 1,
    utterance_feature(CurrentText,
                      anaphor(Type, Marker, _Count, candidate)),
    \+ supplied_marker_link(CurrentId, Marker, Context),
    prefix_before(CurrentIndex, Utterances, Prior),
    most_recent_compatible_anchor(
        Prior, Context, Type, Marker, Target, AnchorId,
        AnchorSource, AnchorConfidence).
context_relation(Utterances, Context,
                 tension_relevant_evidence(
                     between(FromId, ToId),
                     wait_time(duration_ms(DurationMs)),
                     timing_evidence(Basis, Sources),
                     interpretation_not_assigned)) :-
    context_relation(Utterances, Context,
                     temporal_relation(FromId, ToId, pause,
                                       duration_ms(DurationMs), Basis, Sources)),
    DurationMs > 0.
context_relation(Utterances, Context,
                 tension_relevant_configuration(
                     response(ToId),
                     preceding_wait(FromId, duration_ms(DurationMs)),
                     hesitation_cluster(Markers, count(Count)),
                     timing_evidence(Basis, Sources),
                     interpretation_not_assigned)) :-
    context_relation(
        Utterances, Context,
        tension_relevant_evidence(
            between(FromId, ToId), wait_time(duration_ms(DurationMs)),
            timing_evidence(Basis, Sources),
            interpretation_not_assigned)),
    memberchk(utterance(ToId, _Speaker, Text), Utterances),
    utterance_feature(
        Text, hesitation_cluster(Markers, count(Count), surface_order)).

timing_relation(FromEnd, ToStart, pause, DurationMs) :-
    ToStart >= FromEnd,
    DurationMs is ToStart - FromEnd.
timing_relation(FromEnd, ToStart, overlap, DurationMs) :-
    ToStart < FromEnd,
    DurationMs is FromEnd - ToStart.

marker_pattern(Marker0, Marker, MarkerTokens) :-
    text_tokens(Marker0, MarkerTokens),
    MarkerTokens \= [],
    atomic_list_concat(MarkerTokens, '_', Marker).

supplied_marker_link(Id, Marker, Context) :-
    member(reference_link(Id, Marker0, _Target, _Source, _Confidence), Context),
    marker_pattern(Marker0, MarkerKey, MarkerTokens),
    ( Marker == MarkerKey
    ; memberchk(Marker, MarkerTokens)
    ).

most_recent_compatible_anchor(Prior, Context, AnaphorType, Marker,
                              Target, AnchorId,
                              Source, Confidence) :-
    reverse(Prior, Reversed),
    nth1(Distance, Reversed, utterance(AnchorId, _Speaker, _Text)),
    Distance =< 2,
    findall(anchor(CandidateTarget, CandidateSource, CandidateConfidence),
            ( explicit_reference_anchor(
                  Context, AnchorId, CandidateTarget,
                  CandidateSource, CandidateConfidence),
              anaphor_target_compatible(
                  AnaphorType, Marker, CandidateTarget, Context)
            ),
            Anchors),
    Anchors \= [],
    !,
    sort(Anchors, UniqueAnchors),
    UniqueAnchors = [anchor(Target, Source, Confidence)].

explicit_reference_anchor(Context, Id, Target, Source, Confidence) :-
    member(reference_link(Id, _Marker, Target, Source, Confidence), Context).
explicit_reference_anchor(Context, Id, Target, Source, Confidence) :-
    member(gesture_event(Id, _Kind, Target, Source, Confidence), Context),
    Target \== unresolved,
    \+ memberchk(reference_link(Id, _Marker, Target,
                                _ReferenceSource, _ReferenceConfidence),
                 Context).

anaphor_target_compatible(pronominal, it, Target, Context) :-
    memberchk(referent(Target, Kind, _Label), Context),
    Kind \== person.
anaphor_target_compatible(pronominal, Marker, Target, Context) :-
    memberchk(Marker, [he, she]),
    memberchk(referent(Target, person, _Label), Context).
anaphor_target_compatible(pronominal, Marker, Target, Context) :-
    memberchk(Marker, [they, them]),
    memberchk(referent(Target, person, _Label), Context).
anaphor_target_compatible(demonstrative_ambiguous, _Marker,
                          Target, Context) :-
    memberchk(referent(Target, Kind, _Label), Context),
    Kind \== person.
anaphor_target_compatible(comparative, _Marker, Target, Context) :-
    memberchk(referent(Target, Kind, _Label), Context),
    Kind \== person.
anaphor_target_compatible(one_anaphora_candidate, _Marker, Target, Context) :-
    memberchk(referent(Target, Kind, _Label), Context),
    Kind \== person.

weaker_confidence(Left, Right, Weaker) :-
    confidence_rank(Left, LeftRank),
    confidence_rank(Right, RightRank),
    MinimumRank is min(LeftRank, RightRank),
    confidence_rank(Weaker, MinimumRank).

confidence_rank(low, 1).
confidence_rank(medium, 2).
confidence_rank(high, 3).
confidence_rank(exact, 4).

utterance_analysis_dict(utterance(Id, Speaker, Text), Dict) :-
    findall(Feature, utterance_feature(Text, Feature), RawFeatures),
    sort(RawFeatures, Features),
    maplist(feature_dict, Features, FeatureDicts),
    text_string(Text, String),
    Dict = _{id: Id, speaker: Speaker, text: String, features: FeatureDicts}.

feature_dict(hesitation(Subtype, Marker, count(Count), Confidence),
             _{kind: hesitation, subtype: Subtype, marker: Marker,
               count: Count, confidence: Confidence,
               tension_inference: not_assigned}).
feature_dict(hesitation_cluster(Markers, count(Count), Confidence),
             _{kind: hesitation_cluster, markers: Markers,
               count: Count, confidence: Confidence,
               tension_inference: not_assigned}).
feature_dict(repair_marker(Marker, count(Count), Confidence),
             _{kind: repair_marker, marker: Marker, count: Count,
               confidence: Confidence}).
feature_dict(restart(repeated_token(Token), count(Count), Confidence),
             _{kind: restart, token: Token, count: Count,
               confidence: Confidence,
               tension_inference: not_assigned}).
feature_dict(pause(Subtype, duration_unknown, Marker, count(Count)),
             _{kind: pause, subtype: Subtype, duration: null,
               marker: Marker, count: Count, confidence: possible,
               tension_inference: not_assigned}) :-
    !.
feature_dict(pause(Subtype, Duration, Surface, Confidence), Dict) :-
    duration_json(Duration, DurationJson),
    Dict = _{kind: pause, subtype: Subtype, duration: DurationJson,
             surface: Surface, confidence: Confidence,
             tension_inference: not_assigned}.
feature_dict(cutoff_or_interruption(Marker, count(Count), Confidence),
             _{kind: cutoff_or_interruption, marker: Marker, count: Count,
               confidence: Confidence, tension_inference: not_assigned}).
feature_dict(response_gap(Subtype, Surface, Confidence),
             _{kind: response_gap, subtype: Subtype, surface: Surface,
               duration: null, confidence: Confidence,
               uptake_inference: not_assigned,
               tension_inference: not_assigned}).
feature_dict(deixis(Type, Token, count(Count)),
             _{kind: deixis, subtype: Type, token: Token, count: Count}).
feature_dict(anaphor(Type, Marker, count(Count), Confidence),
             _{kind: anaphor, subtype: Type, marker: Marker, count: Count,
               confidence: Confidence, resolution: unresolved}).
feature_dict(nominal_anaphor(Type, Marker, Head, count(Count), Basis),
             _{kind: nominal_anaphor, subtype: Type, marker: Marker,
               head: Head, count: Count, basis: Basis,
               resolution: unresolved}).
feature_dict(gesture(Kind, Surface, Target, Confidence), Dict) :-
    gesture_target_json(Target, TargetJson),
    Dict = _{kind: gesture, subtype: Kind, surface: Surface,
             target: TargetJson, confidence: Confidence}.
feature_dict(feature_placing_candidate(Type, Surface, Confidence),
             _{kind: feature_placing_candidate, subtype: Type,
               surface: Surface, confidence: Confidence}).
feature_dict(nonreferential_pronoun_candidate(Type, Surface, Confidence),
             _{kind: nonreferential_pronoun_candidate, subtype: Type,
               surface: Surface, confidence: Confidence}).

duration_json(duration_ms(Milliseconds),
              _{milliseconds: Milliseconds, source: explicit_annotation}).
duration_json(duration_unknown, null).

gesture_target_json(target_unresolved, unresolved) :-
    !.
gesture_target_json(Target, Target).

relation_dict(anaphora_candidate(From, Marker, To,
                                 speaker_alias(Source), Confidence),
              _{kind: anaphora_candidate, from: From, to: To,
                marker: Marker, basis: speaker_alias,
                evidence_source: Source, confidence: Confidence,
                resolution: unresolved}) :-
    !.
relation_dict(anaphora_candidate(From, Marker, To, Basis, Confidence),
              _{kind: anaphora_candidate, from: From, to: To,
                marker: Marker, basis: Basis, confidence: Confidence,
                resolution: unresolved}).
relation_dict(
    nominal_anaphora_candidate(
        From, Marker, Head, To,
        exact_head_recurrence(
            turn_distance(Distance), prior_head_mentions(PriorCount),
            window(Window)),
        Confidence, unresolved),
    _{kind: nominal_anaphora_candidate,
      from: From, to: To, marker: Marker, head: Head,
      basis: exact_head_recurrence, turn_distance: Distance,
      prior_head_mentions: PriorCount, search_window: Window,
      confidence: Confidence, resolution: unresolved}).
relation_dict(deictic_gesture_candidate(Id, Token, Surface, Basis, Confidence),
              _{kind: deictic_gesture_candidate, utterance_id: Id,
                token: Token, gesture_surface: Surface, basis: Basis,
                confidence: Confidence, target: unresolved}).
relation_dict(deictic_gesture_candidate_supplied(
                  Id, Token, GestureKind, Target,
                  GestureSource, ReferenceSource, Confidence),
              _{kind: deictic_gesture_candidate, utterance_id: Id,
                token: Token, gesture_kind: GestureKind,
                basis: supplied_gesture_and_reference_link,
                gesture_source: GestureSource,
                reference_source: ReferenceSource,
                confidence: Confidence, target: Target}).
relation_dict(reference_candidate(Id, Marker, Target, Basis, Source, Confidence),
              _{kind: reference_candidate, utterance_id: Id,
                marker: Marker, target: Target, basis: Basis,
                evidence_source: Source, confidence: Confidence,
                resolution: supplied_candidate}).
relation_dict(anaphoric_chain_candidate(
                  CurrentId, Marker, Target, AnchorId,
                  AnchorSource, AnchorConfidence, Basis, Confidence),
              _{kind: anaphoric_chain_candidate,
                from: CurrentId, marker: Marker,
                candidate_target: Target, anchor_utterance_id: AnchorId,
                anchor_source: AnchorSource,
                anchor_confidence: AnchorConfidence,
                basis: Basis, confidence: Confidence,
                resolution: unresolved}).
relation_dict(temporal_relation(From, To, TemporalKind,
                                duration_ms(DurationMs), Basis, Sources),
              _{kind: temporal_relation, from: From, to: To,
                temporal_kind: TemporalKind, duration_ms: DurationMs,
                basis: Basis, evidence_sources: Sources,
                tension_inference: not_assigned}).
relation_dict(tension_relevant_evidence(
                  utterance(Id), hesitation(Marker, count(Count)),
                  Basis, interpretation_not_assigned),
              _{kind: tension_relevant_evidence,
                scope: _{utterance_id: Id},
                cue: _{kind: hesitation, marker: Marker, count: Count},
                basis: Basis, tension_inference: not_assigned}).
relation_dict(tension_relevant_evidence(
                  utterance(Id), hesitation_cluster(Markers, count(Count)),
                  Basis, interpretation_not_assigned),
              _{kind: tension_relevant_evidence,
                scope: _{utterance_id: Id},
                cue: _{kind: hesitation_cluster,
                       markers: Markers, count: Count},
                basis: Basis, tension_inference: not_assigned}).
relation_dict(tension_relevant_evidence(
                  between(From, To), wait_time(duration_ms(DurationMs)),
                  timing_evidence(Basis, Sources),
                  interpretation_not_assigned),
              _{kind: tension_relevant_evidence,
                scope: _{from: From, to: To},
                cue: _{kind: wait_time, duration_ms: DurationMs},
                basis: Basis, evidence_sources: Sources,
                tension_inference: not_assigned}).
relation_dict(tension_relevant_configuration(
                  response(To),
                  preceding_wait(From, duration_ms(DurationMs)),
                  hesitation_cluster(Markers, count(Count)),
                  timing_evidence(Basis, Sources),
                  interpretation_not_assigned),
              _{kind: tension_relevant_configuration,
                scope: _{preceding_utterance_id: From,
                         response_utterance_id: To},
                cues: [_{kind: wait_time, duration_ms: DurationMs},
                       _{kind: hesitation_cluster,
                         markers: Markers, count: Count}],
                basis: Basis, evidence_sources: Sources,
                tension_inference: not_assigned}).

context_evidence_dict(speaker_alias(Speaker, Alias, Source),
                      _{kind: speaker_alias, speaker: Speaker,
                        alias: Alias, source: Source}).
context_evidence_dict(turn_timing(Id, StartMs, EndMs, Source),
                      _{kind: turn_timing, utterance_id: Id,
                        start_ms: StartMs, end_ms: EndMs, source: Source}).
context_evidence_dict(pause_event(From, To, DurationMs, Source),
                      _{kind: pause_event, from: From, to: To,
                        duration_ms: DurationMs, source: Source}).
context_evidence_dict(referent(Id, Kind, Label),
                      _{kind: referent, referent_id: Id,
                        referent_kind: Kind, label: Label}).
context_evidence_dict(gesture_event(Id, Kind, Target, Source, Confidence),
                      _{kind: gesture_event, utterance_id: Id,
                        gesture_kind: Kind, target: Target,
                        source: Source, confidence: Confidence}).
context_evidence_dict(reference_link(Id, Marker, Target, Source, Confidence),
                      _{kind: reference_link, utterance_id: Id,
                        marker: Marker, target: Target,
                        source: Source, confidence: Confidence}).

filled_pause(uh).
filled_pause(um).
filled_pause(umm).
filled_pause(uhm).
filled_pause(erm).
filled_pause(er).
filled_pause(hmm).

hesitation_marker_sequence(Tokens, Markers) :-
    hesitation_marker_sequence(Tokens, [], Markers).

hesitation_marker_sequence([], _SeenReversed, []).
hesitation_marker_sequence([you, know | Tokens], SeenReversed, Markers) :-
    !,
    (   semantic_you_know_prefix(SeenReversed)
    ->  Markers = RestMarkers
    ;   Markers = [you_know | RestMarkers]
    ),
    hesitation_marker_sequence(
        Tokens, [know, you | SeenReversed], RestMarkers).
hesitation_marker_sequence([Token | Tokens], SeenReversed,
                           [Token | Markers]) :-
    filled_pause(Token),
    !,
    hesitation_marker_sequence(Tokens, [Token | SeenReversed], Markers).
hesitation_marker_sequence([Token | Tokens], SeenReversed, Markers) :-
    hesitation_marker_sequence(Tokens, [Token | SeenReversed], Markers).

semantic_you_know_prefix([Previous | _]) :-
    memberchk(Previous, [how, what, why, do, does, did,
                         would, could, can, should]).

deictic_token(i, personal_first_singular).
deictic_token(me, personal_first_singular).
deictic_token(we, personal_first_plural).
deictic_token(us, personal_first_plural).
deictic_token(you, personal_second).
deictic_token(here, spatial_proximal).
deictic_token(there, spatial_distal).
deictic_token(this, demonstrative_proximal).
deictic_token(these, demonstrative_proximal).
deictic_token(that, demonstrative_distal).
deictic_token(those, demonstrative_distal).
deictic_token(now, temporal_present).
deictic_token(then, temporal_distal).
deictic_token(today, temporal_present).
deictic_token(yesterday, temporal_distal).

spatial_deixis(spatial_proximal).
spatial_deixis(spatial_distal).
spatial_deixis(demonstrative_proximal).
spatial_deixis(demonstrative_distal).

anaphor_pattern(it, pronominal, [it]).
anaphor_pattern(he, pronominal, [he]).
anaphor_pattern(she, pronominal, [she]).
anaphor_pattern(they, pronominal, [they]).
anaphor_pattern(them, pronominal, [them]).
anaphor_pattern(this, demonstrative_ambiguous, [this]).
anaphor_pattern(that, demonstrative_ambiguous, [that]).
anaphor_pattern(these, demonstrative_ambiguous, [these]).
anaphor_pattern(those, demonstrative_ambiguous, [those]).
anaphor_pattern(the_same, comparative, [the, same]).
anaphor_pattern(another_one, one_anaphora_candidate, [another, one]).

demonstrative_nominal(Tokens, Marker, Head, Count) :-
    findall(OccurrenceMarker-OccurrenceHead,
            demonstrative_nominal_occurrence(
                Tokens, OccurrenceMarker, OccurrenceHead),
            RawOccurrences),
    msort(RawOccurrences, SortedOccurrences),
    clumped(SortedOccurrences, Counts),
    member((Marker-Head)-Count, Counts).

demonstrative_nominal_occurrence(Tokens, Marker, Head) :-
    append(_Prefix, [Determiner, SurfaceHead | Rest], Tokens),
    memberchk(Determiner, [this, that, these, those]),
    nominal_head_form(SurfaceHead, Head),
    nominal_head_position_ok(SurfaceHead, Rest),
    atomic_list_concat([Determiner, SurfaceHead], '_', Marker).

% Avoid treating the first noun in a bounded compound as its head. Missing a
% candidate is preferable to calling "this area model" an anaphor headed by
% `area`. The lexicon remains intentionally small and inspectable.
nominal_head_position_ok(whole, [entire | _]) :-
    !,
    fail.
nominal_head_position_ok(_SurfaceHead, [Next | _]) :-
    nominal_head_form(Next, _NextHead),
    !,
    fail.
nominal_head_position_ok(_SurfaceHead, _Rest).

nominal_head_mention(Text, Head) :-
    text_tokens(Text, Tokens),
    member(SurfaceHead, Tokens),
    nominal_head_form(SurfaceHead, Head).

nominal_head_form(answer, answer).
nominal_head_form(answers, answer).
nominal_head_form(array, array).
nominal_head_form(arrays, array).
nominal_head_form(area, area).
nominal_head_form(areas, area).
nominal_head_form(column, column).
nominal_head_form(columns, column).
nominal_head_form(denominator, denominator).
nominal_head_form(denominators, denominator).
nominal_head_form(diagram, diagram).
nominal_head_form(diagrams, diagram).
nominal_head_form(equation, equation).
nominal_head_form(equations, equation).
nominal_head_form(fraction, fraction).
nominal_head_form(fractions, fraction).
nominal_head_form(group, group).
nominal_head_form(groups, group).
nominal_head_form(line, line).
nominal_head_form(lines, line).
nominal_head_form(model, model).
nominal_head_form(models, model).
nominal_head_form(number, number).
nominal_head_form(numbers, number).
nominal_head_form(numerator, numerator).
nominal_head_form(numerators, numerator).
nominal_head_form(part, part).
nominal_head_form(parts, part).
nominal_head_form(pattern, pattern).
nominal_head_form(patterns, pattern).
nominal_head_form(piece, piece).
nominal_head_form(pieces, piece).
nominal_head_form(problem, problem).
nominal_head_form(problems, problem).
nominal_head_form(rectangle, rectangle).
nominal_head_form(rectangles, rectangle).
nominal_head_form(representation, representation).
nominal_head_form(representations, representation).
nominal_head_form(row, row).
nominal_head_form(rows, row).
nominal_head_form(rule, rule).
nominal_head_form(rules, rule).
nominal_head_form(shape, shape).
nominal_head_form(shapes, shape).
nominal_head_form(solution, solution).
nominal_head_form(solutions, solution).
nominal_head_form(strategy, strategy).
nominal_head_form(strategies, strategy).
nominal_head_form(unit, unit).
nominal_head_form(units, unit).
nominal_head_form(way, way).
nominal_head_form(ways, way).
nominal_head_form(whole, whole).
nominal_head_form(wholes, whole).

recent_prior_window(Prior, Limit, Window) :-
    length(Prior, Length),
    (   Length =< Limit
    ->  Window = Prior
    ;   Drop is Length - Limit,
        length(Dropped, Drop),
        append(Dropped, Window, Prior)
    ).

nominal_link_confidence(1, medium) :-
    !.
nominal_link_confidence(Count, low) :-
    Count > 1.

deixis_occurrence_count(that, Tokens, Count) :-
    !,
    filtered_token_count(that, demonstrative_that_occurrence, Tokens, Count).
deixis_occurrence_count(there, Tokens, Count) :-
    !,
    filtered_token_count(there, locative_there_occurrence, Tokens, Count).
deixis_occurrence_count(Token, Tokens, Count) :-
    token_count(Token, Tokens, Count).

anaphor_occurrence_count(that, [that], Tokens, Count) :-
    !,
    filtered_token_count(that, demonstrative_that_occurrence, Tokens, Count).
anaphor_occurrence_count(it, [it], Tokens, Count) :-
    !,
    filtered_token_count(it, referential_it_candidate, Tokens, Count).
anaphor_occurrence_count(_Marker, Pattern, Tokens, Count) :-
    sequence_count(Pattern, Tokens, Count).

filtered_token_count(Token, Filter, Tokens, Count) :-
    findall(1,
            ( append(Prefix, [Token | Suffix], Tokens),
              call(Filter, Prefix, Suffix)
            ),
            Matches),
    length(Matches, Count).

demonstrative_that_occurrence(Prefix, Suffix) :-
    \+ prefix_ends_complement_taking_verb(Prefix),
    \+ relative_clause_that(Prefix, Suffix).

prefix_ends_complement_taking_verb(Prefix) :-
    reverse(Prefix, Reversed),
    skip_complement_bridge_tokens(Reversed, [Verb | _]),
    memberchk(Verb, [think, thinks, thought, say, says, said,
                     know, knows, knew, believe, believes, believed,
                     guess, guesses, guessed, mean, means, meant,
                     see, sees, saw,
                     prove, proves, proved,
                     notice, notices, noticed, suppose, supposes, supposed]).

skip_complement_bridge_tokens([Token | Rest], Remaining) :-
    memberchk(Token, [here, there, now, clearly, already, just]),
    !,
    skip_complement_bridge_tokens(Rest, Remaining).
skip_complement_bridge_tokens(Remaining, Remaining).

relative_clause_that(Prefix, [Auxiliary | _]) :-
    relative_clause_prefix(Prefix),
    memberchk(Auxiliary, [is, are, was, were, has, have, had,
                          can, could, would, should, will]).
relative_clause_that(Prefix, [Subject | _]) :-
    relative_clause_prefix(Prefix),
    memberchk(Subject, [i, you, we, they, he, she, it,
                        'you\'re', 'we\'re', 'they\'re',
                        'he\'s', 'she\'s', 'it\'s']).
relative_clause_that(Prefix, Suffix) :-
    Suffix \= [],
    last(Prefix, Noun),
    memberchk(Noun, [claim, fact, idea, explanation, reason]).

relative_clause_prefix(Prefix) :-
    last(Prefix, Antecedent),
    \+ memberchk(Antecedent,
                  [well, okay, ok, so, but, and, yes, no,
                   right, now, then]).

locative_there_occurrence(_Prefix, [Next | _]) :-
    \+ memberchk(Next, [is, are, was, were]).
locative_there_occurrence(_Prefix, []).

referential_it_candidate(_Prefix, Suffix) :-
    \+ ambient_it_suffix(Suffix),
    \+ expletive_it_suffix(Suffix).

ambient_it_suffix([is, Feature | _]) :-
    ambient_feature(Feature).

expletive_it_suffix([takes, to | _]).

verbal_gesture_pattern(pointing, [pointing]).
verbal_gesture_pattern(points_to, [points, to]).
verbal_gesture_pattern(point_to, [point, to]).
verbal_gesture_pattern(refers_to, [refers, to]).
verbal_gesture_pattern(gesture_to, [gesture, to]).

existential_there_surface(Tokens, there_is) :-
    contains_sequence([there, is], Tokens).
existential_there_surface(Tokens, there_are) :-
    contains_sequence([there, are], Tokens).
existential_there_surface(Tokens, there_was) :-
    contains_sequence([there, was], Tokens).
existential_there_surface(Tokens, there_were) :-
    contains_sequence([there, were], Tokens).

ambient_it_surface(Tokens, Surface) :-
    ambient_feature(Feature),
    ( contains_sequence([it, is, Feature], Tokens),
      atomic_list_concat([it, is, Feature], '_', Surface)
    ; contains_sequence(['it''s', Feature], Tokens),
      atomic_list_concat([its, Feature], '_', Surface)
    ).

expletive_it_surface(Tokens, it_takes_to) :-
    contains_sequence([it, takes, to], Tokens).

ambient_feature(raining).
ambient_feature(snowing).
ambient_feature(cold).
ambient_feature(hot).
ambient_feature(dark).
ambient_feature(late).

locative_property_surface(Tokens, Surface) :-
    locative_property(Property),
    member(Location, [here, there]),
    contains_sequence([Property, Location], Tokens),
    atomic_list_concat([Property, at, Location], '_', Surface).

locative_property(equal).
locative_property(bigger).
locative_property(smaller).
locative_property(longer).
locative_property(shorter).
locative_property(shaded).
locative_property(open).
locative_property(closed).
locative_property(red).
locative_property(blue).

pause_annotation_surface(String, Surface) :-
    Pattern = "(?<surface>\\[[^\\]]*(?:pause|silence|wait)[^\\]]*\\]|\\([^\\)]*(?:pause|silence|wait)[^\\)]*\\))",
    regex_surfaces(Pattern, String, Surfaces),
    member(Surface, Surfaces).

annotation_duration(Surface, duration_ms(Milliseconds)) :-
    Pattern = "(?<value>[0-9]+(?:\\.[0-9]+)?)\\s*(?<unit>milliseconds?|ms|seconds?|secs?|s)",
    re_matchsub(Pattern, Surface, Match, [caseless(true)]),
    get_dict(value, Match, ValueString),
    get_dict(unit, Match, UnitString),
    number_string(Value, ValueString),
    duration_milliseconds(UnitString, Value, Milliseconds),
    !.
annotation_duration(_Surface, duration_unknown).

duration_milliseconds(UnitString, Value, Milliseconds) :-
    string_lower(UnitString, Unit),
    ( sub_string(Unit, 0, 1, _, "m") ->
        Milliseconds is round(Value)
    ;   Milliseconds is round(Value * 1000)
    ).

ellipsis_count(String, Count) :-
    regex_match_count("(?:\\.\\s*\\.\\s*\\.|…)", String, Count).

no_verbal_response_surface(String, Surface) :-
    Pattern = "(?<surface>\\[[^\\]]*(?:no\\s+(?:verbal\\s+)?response|no\\s+one\\s+responds)[^\\]]*\\]|\\([^\\)]*(?:no\\s+(?:verbal\\s+)?response|no\\s+one\\s+responds)[^\\)]*\\))",
    regex_surfaces(Pattern, String, Surfaces),
    member(Surface, Surfaces).

gesture_annotation_surface(String, Surface) :-
    Pattern = "(?<surface>\\[[^\\]]*(?:gesture|point|refer|indicat|hold|draw|nod|shake|walk)[^\\]]*\\]|\\([^\\)]*(?:gesture|point|refer|indicat|hold|draw|nod|shake|walk)[^\\)]*\\))",
    regex_surfaces(Pattern, String, Surfaces),
    member(Surface, Surfaces).

gesture_kind(Surface, pointing) :-
    string_lower(Surface, Lower),
    contains_any_substring(Lower, ["point", "refer", "indicat"]),
    !.
gesture_kind(Surface, head_movement) :-
    string_lower(Surface, Lower),
    contains_any_substring(Lower, ["nod", "shake"]),
    !.
gesture_kind(Surface, inscription_action) :-
    string_lower(Surface, Lower),
    contains_any_substring(Lower, ["draw", "write"]),
    !.
gesture_kind(Surface, repositioning) :-
    string_lower(Surface, Lower),
    contains_any_substring(Lower, ["walk", "move"]),
    !.
gesture_kind(Surface, object_handling) :-
    string_lower(Surface, Lower),
    sub_string(Lower, _, _, _, "hold"),
    !.
gesture_kind(_Surface, gesture_unspecified).

speaker_reference(Text, Speaker, Marker) :-
    speaker_token(Speaker, Marker),
    text_tokens(Text, Tokens),
    memberchk(Marker, Tokens),
    member(ReferenceCue, [said, says, think, thinks, thought,
                          mean, means, meant, did, agree, agrees,
                          agreed, disagree, disagrees, disagreed,
                          idea, thinking, claim]),
    memberchk(ReferenceCue, Tokens).

speaker_token(Speaker, Token) :-
    text_tokens(Speaker, [Token | _]).

most_recent_speaker_utterance(Prior, Speaker, Id) :-
    reverse(Prior, Reversed),
    member(utterance(Id, Speaker, _Text), Reversed),
    !.

prefix_before(Index, List, Prefix) :-
    PrefixLength is Index - 1,
    length(Prefix, PrefixLength),
    append(Prefix, _Suffix, List).

adjacent_utterances([A, B | _], A, B).
adjacent_utterances([_ | Rest], A, B) :-
    adjacent_utterances(Rest, A, B).

adjacent_repeat_counts(Tokens, Counts) :-
    findall(Token,
            ( append(_, [Token, Token | _], Tokens),
              \+ restart_stop_token(Token)
            ),
            Repeats),
    sort(Repeats, Unique),
    findall(Token-Count,
            ( member(Token, Unique), token_count(Token, Repeats, Count) ),
            Counts).

restart_stop_token(very).
restart_stop_token(had).
restart_stop_token(that).

contains_sequence(Pattern, Tokens) :-
    append(_, Rest, Tokens),
    append(Pattern, _, Rest),
    !.

sequence_count(Pattern, Tokens, Count) :-
    findall(1,
            ( append(_, Rest, Tokens), append(Pattern, _, Rest) ),
            Matches),
    length(Matches, Count).

token_count(Token, Tokens, Count) :-
    include(==(Token), Tokens, Matches),
    length(Matches, Count).

text_tokens(Text, Tokens) :-
    text_string(Text, String),
    string_lower(String, Lower),
    split_string(Lower,
                 " \t\n\r,.;:!?()[]{}<>\"“”/\\|—–…",
                 " \t\n\r",
                 TokenStrings),
    exclude(==(""), TokenStrings, NonEmpty),
    maplist(atom_string, Tokens, NonEmpty).

%! utterance_tokens(+Text, -LowercaseTokens) is det.
%
%  Public tokenizer shared by the bounded pragmatic layer. Tokens preserve
%  contractions as single lowercase atoms; this is a lexical surface, not a
%  syntactic parse.
utterance_tokens(Text, Tokens) :-
    text_tokens(Text, Tokens).

text_string(Text, String) :-
    ( string(Text) -> String = Text
    ; atom(Text) -> atom_string(Text, String)
    ).

regex_match_count(Pattern, String, Count) :-
    regex_surfaces(Pattern, String, Surfaces),
    length(Surfaces, Count).

regex_surfaces(Pattern, String, Surfaces) :-
    re_foldl(collect_match_surface, Pattern, String, [], Reversed,
             [caseless(true)]),
    reverse(Reversed, Surfaces).

collect_match_surface(Match, Acc, [Surface | Acc]) :-
    get_dict(0, Match, Surface).

contains_any_substring(String, [Needle | _]) :-
    sub_string(String, _, _, _, Needle),
    !.
contains_any_substring(String, [_ | Needles]) :-
    contains_any_substring(String, Needles).
