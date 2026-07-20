/** <module> Deterministic TalkMoves packet adapter and review surface

This module reads the saved TalkMoves request-packet transcript lines without
consulting answer keys or assigning trace/PML codes. It adapts rows of the form

  U0047 S06: No, what I was saying before ...

to discourse_features:utterance/3 terms, identifies reviewable next-turn
vocative alias candidates, and builds JSON-safe evidence reviews. Alias
candidates are never promoted to speaker_alias/3 context evidence here; a
reviewer must supply confirmed aliases through the context dict channel.
*/
:- module(talkmoves_adapter, [
    load_talkmoves_packet/2,       % load_talkmoves_packet(+Path, -Utterances)
    talkmoves_utterance_slice/4,   % talkmoves_utterance_slice(+All, +From, +To, -Slice)
    talkmoves_alias_candidate/2,   % talkmoves_alias_candidate(+Utterances, -Candidate)
    talkmoves_packet_review/3,     % talkmoves_packet_review(+Path, +ContextDict, -Review)
    talkmoves_review/4,            % talkmoves_review(+Source, +Utterances, +ContextDict, -Review)
    review_markdown/2,             % review_markdown(+Review, -Markdown)
    write_review_markdown_file/2   % write_review_markdown_file(+Path, +Review)
]).

:- use_module(pml(discourse_features)).
:- use_module(pml(discourse_pragmatics)).
:- use_module(library(error)).
:- use_module(library(http/json)).
:- use_module(library(lists)).
:- use_module(library(pcre)).
:- use_module(library(readutil)).

%! load_talkmoves_packet(+Path, -Utterances) is det.
load_talkmoves_packet(Path, Utterances) :-
    text_path(Path, PathAtom),
    read_file_to_string(PathAtom, PacketText, []),
    split_string(PacketText, "\n", "\r", Lines),
    findall(Utterance,
            ( member(Line, Lines),
              packet_utterance_line(Line, Utterance)
            ),
            Utterances),
    Utterances \= [],
    findall(Id, member(utterance(Id, _Speaker, _Text), Utterances), Ids),
    sort(Ids, UniqueIds),
    same_length(Ids, UniqueIds).

packet_utterance_line(Line, utterance(Id, Speaker, Text)) :-
    Pattern = "^\\s*(?<id>[Uu][0-9]+)\\s+(?<speaker>[Ss][0-9]+):\\s*(?<text>.*)$",
    re_matchsub(Pattern, Line, Match, []),
    get_dict(id, Match, IdString),
    get_dict(speaker, Match, SpeakerString),
    get_dict(text, Match, Text),
    lowercase_atom(IdString, Id),
    lowercase_atom(SpeakerString, Speaker).

%! talkmoves_utterance_slice(+All, +From, +To, -Slice) is semidet.
talkmoves_utterance_slice(Utterances, From, To, Slice) :-
    nth1(FromIndex, Utterances, utterance(From, _FromSpeaker, _FromText)),
    nth1(ToIndex, Utterances, utterance(To, _ToSpeaker, _ToText)),
    FromIndex =< ToIndex,
    !,
    Length is ToIndex - FromIndex + 1,
    PrefixLength is FromIndex - 1,
    length(Prefix, PrefixLength),
    append(Prefix, Rest, Utterances),
    length(Slice, Length),
    append(Slice, _Tail, Rest).

%! talkmoves_alias_candidate(+Utterances, -Candidate) is nondet.
%
%  A candidate requires a name-shaped direct address and a change of speaker in
%  the immediately following transcript row. It remains medium-confidence
%  review evidence because interruptions and transcription boundaries can make
%  the next speaker differ from the person addressed.
talkmoves_alias_candidate(
    Utterances,
    alias_candidate(ResponseSpeaker, Alias,
                    next_turn_vocative, medium,
                    evidence(AddressId, ResponseId, Surface))) :-
    adjacent_utterances(
        Utterances,
        utterance(AddressId, AddressSpeaker, AddressText),
        utterance(ResponseId, ResponseSpeaker, _ResponseText)),
    AddressSpeaker \== ResponseSpeaker,
    vocative_name(AddressText, Alias, Surface).

vocative_name(Text, Alias, Surface) :-
    (   vocative_match(
            "^\\s*(?<name>[A-Z][A-Za-z'’-]+)\\s*,", Text, NameString)
    ->  true
    ;   vocative_match(
            "^\\s*(?<name>[A-Z][A-Za-z'’-]+)\\s+you\\b", Text, NameString)
    ->  true
    ;   vocative_match(
            "^\\s*(?<name>[A-Z][A-Za-z'’-]+)\\s*[?.!]\\s*$", Text, NameString)
    ),
    lowercase_atom(NameString, Alias),
    \+ vocative_stopword(Alias),
    Surface = NameString.

vocative_match(Pattern, Text, NameString) :-
    re_matchsub(Pattern, Text, Match, []),
    get_dict(name, Match, NameString).

vocative_stopword(okay).
vocative_stopword(ok).
vocative_stopword(well).
vocative_stopword(so).
vocative_stopword(now).
vocative_stopword(what).
vocative_stopword(who).
vocative_stopword(why).
vocative_stopword(how).
vocative_stopword(where).
vocative_stopword(when).
vocative_stopword(no).
vocative_stopword(yes).
vocative_stopword(right).
vocative_stopword(all).
vocative_stopword(hold).
vocative_stopword(because).
vocative_stopword(and).
vocative_stopword(but).
vocative_stopword(then).
vocative_stopword(if).
vocative_stopword(suppose).
vocative_stopword(still).
vocative_stopword(really).
vocative_stopword(look).
vocative_stopword(yeah).
vocative_stopword(hey).
vocative_stopword(thank).
vocative_stopword(parts).
vocative_stopword(fifteenths).
vocative_stopword(see).
vocative_stopword(are).
vocative_stopword(is).
vocative_stopword(was).
vocative_stopword(were).
vocative_stopword(do).
vocative_stopword(does).
vocative_stopword(did).
vocative_stopword(can).
vocative_stopword(could).
vocative_stopword(would).
vocative_stopword(should).
vocative_stopword(will).
vocative_stopword(have).
vocative_stopword(has).
vocative_stopword(had).
vocative_stopword(here).
vocative_stopword(there).
vocative_stopword(this).
vocative_stopword(that).
vocative_stopword(these).
vocative_stopword(those).
vocative_stopword(maybe).
vocative_stopword(one).
vocative_stopword(two).
vocative_stopword(three).
vocative_stopword(four).
vocative_stopword(five).
vocative_stopword(six).
vocative_stopword(seven).
vocative_stopword(eight).
vocative_stopword(nine).
vocative_stopword(ten).

%! talkmoves_packet_review(+Path, +ContextDict, -Review) is det.
talkmoves_packet_review(Path, ContextDict, Review) :-
    load_talkmoves_packet(Path, Utterances),
    talkmoves_review(Path, Utterances, ContextDict, Review).

%! talkmoves_review(+Source, +Utterances, +ContextDict, -Review) is det.
talkmoves_review(Source, Utterances, ContextDict, Review) :-
    discourse_features:context_dict_evidence(
        Utterances, ContextDict, ContextEvidence),
    discourse_features:analyze_transcript(
        Utterances, ContextEvidence, Analysis),
    discourse_pragmatics:analyze_pragmatics(
        Utterances, ContextEvidence, Pragmatics),
    findall(Candidate,
            talkmoves_alias_candidate(Utterances, Candidate),
            RawCandidates),
    sort(RawCandidates, Candidates),
    maplist(alias_candidate_dict(ContextEvidence),
            Candidates, CandidateDicts),
    feature_kind_counts(Analysis, FeatureCounts),
    relation_kind_counts(Analysis, RelationCounts),
    length(Utterances, UtteranceCount),
    length(Candidates, AliasCandidateCount),
    text_string(Source, SourceString),
    Review = _{
        provenance: "deterministic_talkmoves_packet_adapter",
        source: SourceString,
        utterance_count: UtteranceCount,
        alias_candidate_count: AliasCandidateCount,
        alias_candidates: CandidateDicts,
        feature_counts: FeatureCounts,
        relation_counts: RelationCounts,
        analysis: Analysis,
        pragmatics: Pragmatics,
        limits: _{
            aliases: "next-turn vocative candidates only; not confirmed identities",
            timing: "no wait duration without transcript annotation or supplied context metadata",
            interpretation: "no trace code, PML operator, mode, uptake, non-uptake, or tension state assigned"
        }
    }.

alias_candidate_dict(
    ContextEvidence,
    alias_candidate(Speaker, Alias, Basis, Confidence,
                    evidence(AddressId, ResponseId, Surface)),
    _{speaker: Speaker, alias: Alias, basis: Basis,
      confidence: Confidence, address_utterance_id: AddressId,
      response_utterance_id: ResponseId, surface: Surface,
      status: Status, context_source: ContextSource}) :-
    alias_candidate_status(
        ContextEvidence, Speaker, Alias, Status, ContextSource).

alias_candidate_status(ContextEvidence, Speaker, Alias,
                       confirmed_by_context, Source) :-
    memberchk(speaker_alias(Speaker, AliasText, Source), ContextEvidence),
    lowercase_atom(AliasText, Alias),
    !.
alias_candidate_status(_ContextEvidence, _Speaker, _Alias,
                       review_required, null).

feature_kind_counts(Analysis, Counts) :-
    findall(Kind,
            ( member(Utterance, Analysis.utterances),
              member(Feature, Utterance.features),
              get_dict(kind, Feature, Kind)
            ),
            Kinds),
    counted_values(Kinds, Counts).

relation_kind_counts(Analysis, Counts) :-
    findall(Kind,
            ( member(Relation, Analysis.relations),
              get_dict(kind, Relation, Kind)
            ),
            Kinds),
    counted_values(Kinds, Counts).

counted_values(Values, Counts) :-
    msort(Values, Sorted),
    clumped(Sorted, Clumped),
    findall(_{kind: Kind, count: Count},
            member(Kind-Count, Clumped),
            Counts).

%! review_markdown(+Review, -Markdown) is det.
review_markdown(Review, Markdown) :-
    with_output_to(string(Markdown), write_review_markdown(Review)).

write_review_markdown(Review) :-
    format("# TalkMoves deterministic discourse review~n~n", []),
    format("Register: **generated evidence review, not a validation result.**~n~n", []),
    format("Source: `~s`~n~n", [Review.source]),
    format("Utterances: ~d. Alias candidates: ~d.~n~n",
           [Review.utterance_count, Review.alias_candidate_count]),
    format("This report records surface and supplied-context evidence. It does not assign tension, uptake, trace codes, PML operators, or modes.~n~n", []),
    write_count_table("Feature inventory", Review.feature_counts),
    write_count_table("Relation inventory", Review.relation_counts),
    write_count_table("Pragmatic atom inventory",
                      Review.pragmatics.atom_counts),
    write_count_table("Pragmatic relation inventory",
                      Review.pragmatics.relation_counts),
    write_alias_table(Review.alias_candidates),
    write_selected_feature_table(Review.analysis.utterances),
    write_selected_relation_table(Review.analysis.relations),
    write_pragmatic_atom_table(Review.pragmatics.utterances),
    write_pragmatic_relation_table(Review.pragmatics.relations),
    format("## Limits~n~n", []),
    format("- ~s~n", [Review.limits.aliases]),
    format("- ~s~n", [Review.limits.timing]),
    format("- ~s~n", [Review.limits.interpretation]).

write_count_table(Title, Counts) :-
    format("## ~s~n~n", [Title]),
    format("| kind | count |~n| --- | ---: |~n", []),
    forall(member(Row, Counts),
           format("| `~w` | ~d |~n", [Row.kind, Row.count])),
    nl.

write_alias_table(Aliases) :-
    format("## Vocative alias candidates~n~n", []),
    format("| speaker | alias | address → response | confidence | status |~n", []),
    format("| --- | --- | --- | --- | --- |~n", []),
    forall(member(Row, Aliases),
           format("| `~w` | `~w` | `~w` → `~w` | `~w` | `~w` |~n",
                  [Row.speaker, Row.alias, Row.address_utterance_id,
                   Row.response_utterance_id, Row.confidence, Row.status])),
    nl.

write_selected_feature_table(Utterances) :-
    format("## Selected utterance evidence~n~n", []),
    format("| utterance | speaker | evidence | text |~n", []),
    format("| --- | --- | --- | --- |~n", []),
    forall(( member(Utterance, Utterances),
             member(Feature, Utterance.features),
             selected_feature_kind(Feature.kind) ),
           write_feature_row(Utterance, Feature)),
    nl.

selected_feature_kind(hesitation).
selected_feature_kind(hesitation_cluster).
selected_feature_kind(pause).
selected_feature_kind(response_gap).
selected_feature_kind(cutoff_or_interruption).
selected_feature_kind(gesture).
selected_feature_kind(feature_placing_candidate).
selected_feature_kind(nonreferential_pronoun_candidate).
selected_feature_kind(nominal_anaphor).

write_feature_row(Utterance, Feature) :-
    compact_json(Feature, FeatureText0),
    markdown_cell(FeatureText0, FeatureText),
    abbreviated_text(Utterance.text, Text0),
    markdown_cell(Text0, Text),
    format("| `~w` | `~w` | `~s` | ~s |~n",
           [Utterance.id, Utterance.speaker, FeatureText, Text]).

write_selected_relation_table(Relations) :-
    format("## Selected relations~n~n", []),
    format("| kind | relation |~n| --- | --- |~n", []),
    forall(( member(Relation, Relations),
             selected_relation_kind(Relation.kind) ),
           write_relation_row(Relation)),
    nl.

selected_relation_kind(anaphora_candidate).
selected_relation_kind(anaphoric_chain_candidate).
selected_relation_kind(nominal_anaphora_candidate).
selected_relation_kind(deictic_gesture_candidate).
selected_relation_kind(reference_candidate).
selected_relation_kind(temporal_relation).
selected_relation_kind(tension_relevant_evidence).
selected_relation_kind(tension_relevant_configuration).

write_pragmatic_atom_table(Utterances) :-
    format("## Selected pragmatic atoms~n~n", []),
    format("| utterance | speaker | candidate atom | text |~n", []),
    format("| --- | --- | --- | --- |~n", []),
    forall(( member(Utterance, Utterances),
             member(Atom, Utterance.atoms),
             selected_pragmatic_atom(Atom.subtype) ),
           write_pragmatic_atom_row(Utterance, Atom)),
    nl.

selected_pragmatic_atom(explicit_agreement).
selected_pragmatic_atom(explicit_disagreement).
selected_pragmatic_atom(negative_response).
selected_pragmatic_atom(contrast).
selected_pragmatic_atom(reason_marker).
selected_pragmatic_atom(request_for_reasons).
selected_pragmatic_atom(requirement_marker).
selected_pragmatic_atom(convention_marker).

write_pragmatic_atom_row(Utterance, Atom) :-
    compact_json(Atom, AtomText0),
    markdown_cell(AtomText0, AtomText),
    abbreviated_text(Utterance.text, Text0),
    markdown_cell(Text0, Text),
    format("| `~w` | `~w` | `~s` | ~s |~n",
           [Utterance.id, Utterance.speaker, AtomText, Text]).

write_pragmatic_relation_table(Relations) :-
    format("## Pragmatic candidate relations~n~n", []),
    format("| kind | candidate relation |~n| --- | --- |~n", []),
    forall(member(Relation, Relations),
           write_pragmatic_relation_row(Relation)),
    nl.

write_pragmatic_relation_row(Relation) :-
    compact_json(Relation, RelationText0),
    markdown_cell(RelationText0, RelationText),
    format("| `~w` | `~s` |~n", [Relation.kind, RelationText]).

write_relation_row(Relation) :-
    compact_json(Relation, RelationText0),
    markdown_cell(RelationText0, RelationText),
    format("| `~w` | `~s` |~n", [Relation.kind, RelationText]).

compact_json(Dict, String) :-
    with_output_to(string(String),
                   json_write_dict(current_output, Dict, [width(0)])).

abbreviated_text(Text, Abbreviated) :-
    string_length(Text, Length),
    (   Length =< 160
    ->  Abbreviated = Text
    ;   sub_string(Text, 0, 157, _After, Prefix),
        string_concat(Prefix, "...", Abbreviated)
    ).

markdown_cell(Input, Output) :-
    split_string(Input, "|\n\r", "", Parts),
    atomics_to_string(Parts, " ", Output).

%! write_review_markdown_file(+Path, +Review) is det.
write_review_markdown_file(Path, Review) :-
    text_path(Path, PathAtom),
    review_markdown(Review, Markdown),
    setup_call_cleanup(
        open(PathAtom, write, Stream, [encoding(utf8)]),
        format(Stream, "~s", [Markdown]),
        close(Stream)).

adjacent_utterances([A, B | _], A, B).
adjacent_utterances([_ | Rest], A, B) :-
    adjacent_utterances(Rest, A, B).

lowercase_atom(String, Atom) :-
    string_lower(String, Lower),
    atom_string(Atom, Lower).

text_path(Path, Atom) :-
    (   atom(Path)
    ->  Atom = Path
    ;   string(Path)
    ->  atom_string(Atom, Path)
    ;   type_error(text, Path)
    ).

text_string(Text, String) :-
    (   string(Text)
    ->  String = Text
    ;   atom(Text)
    ->  atom_string(Text, String)
    ;   type_error(text, Text)
    ).
