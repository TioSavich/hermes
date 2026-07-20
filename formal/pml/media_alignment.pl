/** <module> Timed media segments into transcript timing evidence

An upstream audio service may propose speaker-attributed segments with
millisecond offsets. This module checks that narrow contract and turns it into
the utterance and context shapes consumed by discourse_features.pl. It does not
transcribe audio, decide whether timestamps are correct, infer pauses from
punctuation, or assign tension, uptake, trace, or PML interpretations.

The input segment dicts are strict:

  _{speaker: "Teacher", text: "Why?", start_ms: 1200, end_ms: 1800}

Segments must be in nondecreasing start-time order. Overlap is legal because
classroom speakers can overlap. Canonical utterance IDs are assigned in the
supplied order so model-generated identifiers cannot silently enter the local
evidence graph.
*/
:- module(media_alignment, [
    normalize_media_alignment/4, % normalize_media_alignment(+Segments,+Source,-Utterances,-Bundle)
    analyze_media_alignment/3    % analyze_media_alignment(+Segments,+Source,-Bundle)
]).

:- use_module(pml(discourse_features),
              [ valid_context_evidence/2,
                context_dict_evidence/3,
                analyze_transcript/3 ]).
:- use_module(pml(discourse_pragmatics), [analyze_pragmatics/3]).
:- use_module(library(lists)).

%! normalize_media_alignment(+Segments, +Source, -Utterances, -Bundle) is semidet.
%
%  Source is an attributed text label supplied by the application boundary,
%  for example `reallms_audio_alignment:model-name`. Bundle is JSON-safe and
%  can feed its utterances and context fields directly to the discourse worker
%  after a reviewer accepts or corrects the alignment.
normalize_media_alignment(Segments, Source, Utterances, Bundle) :-
    is_list(Segments),
    nonempty_text(Source),
    maplist(valid_segment_dict, Segments),
    nondecreasing_segment_starts(Segments),
    number_segments(Segments, 1, Source, Utterances, Context, UtteranceDicts,
                    TimingDicts, TranscriptLines),
    valid_context_evidence(Utterances, Context),
    alignment_transcript(TranscriptLines, Transcript),
    length(Utterances, SegmentCount),
    Bundle = _{
        provenance: "upstream_timed_segments_validated_by_prolog",
        review_status: "model_proposed_unreviewed",
        timing_source: Source,
        segment_count: SegmentCount,
        transcript: Transcript,
        utterances: UtteranceDicts,
        context: _{turn_timings: TimingDicts},
        limits: _{
            transcription: "speaker labels, words, and timestamps remain an upstream model proposal until reviewed against the recording",
            segmentation: "segment boundaries are preserved as supplied; adjacent turns are not merged",
            interpretation: "no pause significance, tension, uptake, interactional trace, or PML mode is assigned"
        }
    }.

%! analyze_media_alignment(+Segments, +Source, -Bundle) is semidet.
%
%  Compose the validated alignment with the deterministic surface and
%  pragmatic layers. This is the executable audio-to-discourse seam. The
%  nested analyses retain their own limits and do not treat model-proposed
%  timestamps as a tension state or interactional interpretation.
analyze_media_alignment(Segments, Source, Bundle) :-
    normalize_media_alignment(Segments, Source, Utterances, Alignment),
    get_dict(context, Alignment, ContextDict),
    context_dict_evidence(Utterances, ContextDict, Context),
    analyze_transcript(Utterances, Context, SurfaceAnalysis),
    analyze_pragmatics(Utterances, Context, PragmaticAnalysis),
    put_dict(_{surface_analysis: SurfaceAnalysis,
               pragmatic_analysis: PragmaticAnalysis},
             Alignment, Bundle).

alignment_transcript([], "Note: no transcribable speech found") :-
    !.
alignment_transcript(Lines, Transcript) :-
    Lines \= [],
    atomics_to_string(Lines, "\n", Transcript).

valid_segment_dict(Dict) :-
    is_dict(Dict),
    strict_dict_keys(Dict, [speaker, text, start_ms, end_ms]),
    get_dict(speaker, Dict, Speaker),
    nonempty_text(Speaker),
    get_dict(text, Dict, Text),
    nonempty_text(Text),
    get_dict(start_ms, Dict, StartMs),
    integer(StartMs),
    StartMs >= 0,
    get_dict(end_ms, Dict, EndMs),
    integer(EndMs),
    EndMs > StartMs.

strict_dict_keys(Dict, Allowed) :-
    dict_pairs(Dict, _Tag, Pairs),
    findall(Key, member(Key-_, Pairs), Keys),
    sort(Keys, SortedKeys),
    sort(Allowed, SortedAllowed),
    SortedKeys == SortedAllowed.

nondecreasing_segment_starts([]).
nondecreasing_segment_starts([_]).
nondecreasing_segment_starts([Left, Right | Rest]) :-
    get_dict(start_ms, Left, LeftStart),
    get_dict(start_ms, Right, RightStart),
    RightStart >= LeftStart,
    nondecreasing_segment_starts([Right | Rest]).

number_segments([], _Index, _Source, [], [], [], [], []).
number_segments([Segment | Segments], Index, Source,
                [utterance(Id, Speaker, Text) | Utterances],
                [turn_timing(Id, StartMs, EndMs, Source) | Context],
                [_{id: Id, speaker: Speaker, text: Text} | UtteranceDicts],
                [_{utterance_id: Id, start_ms: StartMs, end_ms: EndMs,
                   source: Source} | TimingDicts],
                [Line | TranscriptLines]) :-
    segment_id(Index, Id),
    get_dict(speaker, Segment, Speaker),
    get_dict(text, Segment, Text),
    get_dict(start_ms, Segment, StartMs),
    get_dict(end_ms, Segment, EndMs),
    format(string(Line), "~w: ~w", [Speaker, Text]),
    NextIndex is Index + 1,
    number_segments(Segments, NextIndex, Source, Utterances, Context,
                    UtteranceDicts, TimingDicts, TranscriptLines).

segment_id(Index, Id) :-
    format(string(Id), "u~|~`0t~d~4+", [Index]).

nonempty_text(Value) :-
    (   string(Value)
    ->  String = Value
    ;   atom(Value)
    ->  atom_string(Value, String)
    ),
    normalize_space(string(Normalized), String),
    Normalized \== "".
