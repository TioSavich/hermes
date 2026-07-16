/** <module> Deterministic pragmatic atoms and candidate relations

This module sits between transcript surface features and interactional/PML
coding. It makes explicit stance, reason, challenge, convention, requirement,
and conditional constructions queryable. The results remain candidates. They
do not deposit commitments or entitlements, establish uptake or settlement,
assign a trace code, infer tension, or choose a PML operator or mode.

Input utterances use `utterance(Id, Speaker, Text)`. Optional context is the
validated flat evidence list accepted by `discourse_features:analyze_transcript/3`.
*/
:- module(discourse_pragmatics, [
    pragmatic_atom/2,       % pragmatic_atom(+Text, -Atom)
    pragmatic_relation/2,   % pragmatic_relation(+Utterances, -Relation)
    pragmatic_relation/3,   % pragmatic_relation(+Utterances, +Context, -Relation)
    pragmatic_evidence_candidates/2, % pragmatic_evidence_candidates(+Utterances, -Candidates)
    pragmatic_evidence_candidates/3, % pragmatic_evidence_candidates(+Utterances, +Context, -Candidates)
    analyze_pragmatics/2,   % analyze_pragmatics(+Utterances, -Analysis)
    analyze_pragmatics/3    % analyze_pragmatics(+Utterances, +Context, -Analysis)
]).

:- use_module(pml(discourse_features),
              [ valid_context_evidence/2,
                utterance_tokens/2 ]).
:- use_module(library(error)).
:- use_module(library(lists)).
:- use_module(library(pcre)).

%! pragmatic_atom(+Text, -Atom) is nondet.
%
%  Atom forms are lexical or bounded-construction evidence. `exact` describes
%  the surface match, not the interactional interpretation.
pragmatic_atom(Text,
               pragmatic_atom(explicit_agreement, Marker,
                               count(Count), exact)) :-
    utterance_tokens(Text, Tokens),
    agreement_marker(Tokens, Marker, Pattern),
    sequence_count(Pattern, Tokens, Count),
    Count > 0.
pragmatic_atom(Text,
               pragmatic_atom(explicit_disagreement, Marker,
                               count(Count), Confidence)) :-
    utterance_tokens(Text, Tokens),
    disagreement_marker(Tokens, Marker, Pattern, Confidence),
    sequence_count(Pattern, Tokens, Count),
    Count > 0.
pragmatic_atom(Text,
               pragmatic_atom(negative_response, initial_no,
                               count(Count), context_dependent)) :-
    utterance_tokens(Text, [no | Rest]),
    token_count(no, [no | Rest], Count),
    Count > 0.
pragmatic_atom(Text,
               pragmatic_atom(contrast, Marker,
                               count(Count), context_dependent)) :-
    utterance_tokens(Text, Tokens),
    contrast_marker(Tokens, Marker, Pattern),
    sequence_count(Pattern, Tokens, Count),
    Count > 0.
pragmatic_atom(Text,
               pragmatic_atom(reason_marker, because,
                               count(Count), exact)) :-
    utterance_tokens(Text, Tokens),
    token_count(because, Tokens, Count),
    Count > 0.
pragmatic_atom(Text,
               pragmatic_atom(conclusion_marker, so,
                               count(Count), context_dependent)) :-
    utterance_tokens(Text, Tokens),
    token_count(so, Tokens, Count),
    Count > 0.
pragmatic_atom(Text,
               pragmatic_atom(request_for_reasons, Marker,
                               count(Count), exact)) :-
    utterance_tokens(Text, Tokens),
    reason_request_marker(Tokens, Marker, Pattern),
    sequence_count(Pattern, Tokens, Count),
    Count > 0.
pragmatic_atom(Text,
               pragmatic_atom(conditional_marker, if,
                               count(Count), exact)) :-
    utterance_tokens(Text, Tokens),
    token_count(if, Tokens, Count),
    Count > 0.
pragmatic_atom(Text,
               pragmatic_atom(requirement_marker, Marker,
                               count(Count), Confidence)) :-
    utterance_tokens(Text, Tokens),
    requirement_marker(Tokens, Marker, Pattern, Confidence),
    sequence_count(Pattern, Tokens, Count),
    Count > 0.
pragmatic_atom(Text,
               pragmatic_atom(convention_marker, Marker,
                               count(Count), Confidence)) :-
    utterance_tokens(Text, Tokens),
    convention_marker(Marker, Pattern, Confidence),
    sequence_count(Pattern, Tokens, Count),
    Count > 0.

agreement_marker(Tokens, i_agree_with, [i, agree, with]) :-
    contains_sequence([i, agree, with], Tokens),
    !.
agreement_marker(Tokens, i_agree, [i, agree]) :-
    contains_sequence([i, agree], Tokens),
    \+ contains_sequence([i, agree, with], Tokens).
agreement_marker(_Tokens, that_is_true, [that, is, true]).
agreement_marker(_Tokens, thats_true, ['that\'s', true]).

disagreement_marker(Tokens, i_disagree_with,
                    [i, disagree, with], exact) :-
    contains_sequence([i, disagree, with], Tokens),
    !.
disagreement_marker(Tokens, i_disagree,
                    [i, disagree], exact) :-
    contains_sequence([i, disagree], Tokens),
    \+ contains_sequence([i, disagree, with], Tokens).

contrast_marker(Tokens, right_but, [right, but]) :-
    contains_sequence([right, but], Tokens),
    !.
contrast_marker([but | _], initial_but, [but]).

reason_request_marker(_Tokens, how_do_you_know,
                      [how, do, you, know]).
reason_request_marker(_Tokens, how_do_we_know,
                      [how, do, we, know]).
reason_request_marker(_Tokens, what_does_that_mean,
                      [what, does, that, mean]).
reason_request_marker([explain | _], explain, [explain]).
reason_request_marker(Tokens, explain, [explain]) :-
    contains_sequence([explain], Tokens),
    requirement_marker(Tokens, _Marker, _Pattern, _Confidence).
reason_request_marker([prove | _], prove, [prove]).
reason_request_marker(Tokens, prove, [prove]) :-
    contains_sequence([prove], Tokens),
    requirement_marker(Tokens, _Marker, _Pattern, _Confidence).

requirement_marker(Tokens, i_want_you_to,
                   [i, want, you, to], exact) :-
    contains_sequence([i, want, you, to], Tokens),
    !.
requirement_marker(Tokens, you_need_to,
                   [you, need, to], exact) :-
    contains_sequence([you, need, to], Tokens),
    !.
requirement_marker(Tokens, you_have_to,
                   [you, have, to], exact) :-
    contains_sequence([you, have, to], Tokens),
    !.
requirement_marker(Tokens, must, [must], exact) :-
    contains_sequence([must], Tokens).
requirement_marker(Tokens, should, [should], context_dependent) :-
    contains_sequence([should], Tokens).

convention_marker(conventionally, [conventionally], exact).
convention_marker(common_way, [common, way], context_dependent).
convention_marker(mathematicians_do_it,
                  [mathematicians, do, it], context_dependent).

%! pragmatic_relation(+Utterances, -Relation) is nondet.
pragmatic_relation(Utterances, Relation) :-
    pragmatic_relation(Utterances, [], Relation).

%! pragmatic_relation(+Utterances, +Context, -Relation) is nondet.
pragmatic_relation(Utterances, Context,
                   named_stance_candidate(
                       CurrentId, Stance, TargetSpeaker, AntecedentId,
                       Marker, speaker_alias(Source), high,
                       interpretation_not_assigned)) :-
    nth1(CurrentIndex, Utterances,
         utterance(CurrentId, _CurrentSpeaker, CurrentText)),
    CurrentIndex > 1,
    named_stance_target(CurrentText, Context, Stance,
                        TargetSpeaker, AliasTokens, Marker, Source),
    prefix_before(CurrentIndex, Utterances, Prior),
    most_recent_speaker_utterance(Prior, TargetSpeaker, AntecedentId),
    AliasTokens \= [].
pragmatic_relation(Utterances, Context,
                   adjacent_stance_candidate(
                       CurrentId, Stance, PriorId, Marker,
                       explicit_surface, medium,
                       interpretation_not_assigned)) :-
    adjacent_utterances(
        Utterances,
        utterance(PriorId, PriorSpeaker, _PriorText),
        utterance(CurrentId, CurrentSpeaker, CurrentText)),
    PriorSpeaker \== CurrentSpeaker,
    utterance_stance(CurrentText, Stance, Marker),
    \+ named_stance_target(CurrentText, Context, _NamedStance,
                           _TargetSpeaker, _AliasTokens,
                           _NamedMarker, _Source).
pragmatic_relation(Utterances, _Context,
                   adjacent_negative_response_candidate(
                       CurrentId, PriorId, initial_no,
                       explicit_surface, medium,
                       interpretation_not_assigned)) :-
    adjacent_utterances(
        Utterances,
        utterance(PriorId, PriorSpeaker, _PriorText),
        utterance(CurrentId, CurrentSpeaker, CurrentText)),
    PriorSpeaker \== CurrentSpeaker,
    pragmatic_atom(CurrentText,
                   pragmatic_atom(negative_response, initial_no,
                                   _Count, context_dependent)).
pragmatic_relation(Utterances, _Context,
                   reason_for_candidate(
                       CurrentId, PriorId, because,
                       adjacent_response, medium,
                       interpretation_not_assigned)) :-
    adjacent_utterances(
        Utterances,
        utterance(PriorId, PriorSpeaker, _PriorText),
        utterance(CurrentId, CurrentSpeaker, CurrentText)),
    PriorSpeaker \== CurrentSpeaker,
    utterance_tokens(CurrentText, [because | _]).
pragmatic_relation(Utterances, _Context,
                   intra_utterance_reason_candidate(
                       Id, conclusion(Conclusion), reason(Reason),
                       because, exact,
                       interpretation_not_assigned)) :-
    member(utterance(Id, _Speaker, Text), Utterances),
    because_spans(Text, Conclusion, Reason).
pragmatic_relation(Utterances, _Context,
                   conditional_requirement_candidate(
                       Id, condition(Condition), required_action(Action),
                       requirement_marker(Marker), high,
                       interpretation_not_assigned)) :-
    member(utterance(Id, _Speaker, Text), Utterances),
    conditional_requirement(Text, Condition, Action, Marker).
pragmatic_relation(Utterances, Context,
                   conditional_component_candidate(
                       Id, Component, Target, MarkerKey,
                       supplied_reference_link(Source), Confidence,
                       interpretation_not_assigned)) :-
    member(utterance(Id, _Speaker, Text), Utterances),
    conditional_requirement(Text, Condition, Action, _RequirementMarker),
    member(reference_link(Id, Marker0, Target, Source, Confidence), Context),
    marker_tokens(Marker0, MarkerKey, MarkerTokens),
    conditional_component_tokens(Component, Condition, Action, ComponentTokens),
    contains_sequence(MarkerTokens, ComponentTokens).
pragmatic_relation(Utterances, Context,
                   normative_scope_candidate(
                       Id, convention, Target, MarkerKey,
                       supplied_reference_link(Source), Confidence,
                       interpretation_not_assigned)) :-
    member(utterance(Id, _Speaker, Text), Utterances),
    pragmatic_atom(Text,
                   pragmatic_atom(convention_marker, _ConventionMarker,
                                   _Count, _ConventionConfidence)),
    member(reference_link(Id, Marker0, Target, Source, Confidence), Context),
    marker_tokens(Marker0, MarkerKey, MarkerTokens),
    utterance_tokens(Text, Tokens),
    contains_sequence(MarkerTokens, Tokens).

utterance_stance(Text, agreement, Marker) :-
    pragmatic_atom(Text,
                   pragmatic_atom(explicit_agreement, Marker,
                                   _Count, _Confidence)).
utterance_stance(Text, disagreement, Marker) :-
    pragmatic_atom(Text,
                   pragmatic_atom(explicit_disagreement, Marker,
                                   _Count, _Confidence)).

named_stance_target(Text, Context, Stance, Speaker,
                    AliasTokens, Marker, Source) :-
    member(speaker_alias(Speaker, Alias, Source), Context),
    utterance_tokens(Alias, AliasTokens),
    stance_prefix(Stance, Prefix, Marker),
    append(Prefix, AliasTokens, Pattern),
    utterance_tokens(Text, Tokens),
    contains_sequence(Pattern, Tokens).

stance_prefix(agreement, [i, agree, with], i_agree_with).
stance_prefix(disagreement, [i, disagree, with], i_disagree_with).

because_spans(Text, Conclusion, Reason) :-
    text_string(Text, String),
    Pattern = "(?i)^\\s*(?<conclusion>.+?)\\s+because\\s+(?<reason>.+?)\\s*$",
    re_matchsub(Pattern, String, Match, []),
    normalized_capture(Match.conclusion, Conclusion),
    normalized_capture(Match.reason, Reason),
    Conclusion \== "",
    Reason \== "".

conditional_requirement(Text, Condition, Action, Marker) :-
    text_string(Text, String),
    Pattern = "(?i)^\\s*if\\s+(?<condition>.+?)(?:,|;|\\bthen\\b)\\s*(?<action>.+?)\\s*$",
    re_matchsub(Pattern, String, Match, []),
    normalized_capture(Match.condition, Condition),
    normalized_capture(Match.action, Action),
    Condition \== "",
    Action \== "",
    utterance_tokens(Action, ActionTokens),
    requirement_marker(ActionTokens, Marker, _MarkerTokens, _Confidence).

conditional_component_tokens(condition, Condition, _Action, Tokens) :-
    utterance_tokens(Condition, Tokens).
conditional_component_tokens(required_action, _Condition, Action, Tokens) :-
    utterance_tokens(Action, Tokens).

normalized_capture(Capture, Normalized) :-
    normalize_space(string(Normalized), Capture).

marker_tokens(Marker0, MarkerKey, Tokens) :-
    utterance_tokens(Marker0, Tokens),
    Tokens \= [],
    atomic_list_concat(Tokens, '_', MarkerKey).

%! pragmatic_evidence_candidates(+Utterances, -Candidates) is det.
pragmatic_evidence_candidates(Utterances, Candidates) :-
    pragmatic_evidence_candidates(Utterances, [], Candidates).

%! pragmatic_evidence_candidates(+Utterances, +Context, -Candidates) is det.
%
%  Candidate IDs are SHA-1 identifiers over the layer, utterance scope, and
%  canonical Prolog payload. The ID changes when any of those change and is
%  stable across report regeneration for the same term.
pragmatic_evidence_candidates(Utterances, Context, Candidates) :-
    findall(
        evidence_candidate(CandidateId, pragmatic_atom,
                           span(Id, Id), Atom),
        ( member(utterance(Id, _Speaker, Text), Utterances),
          pragmatic_atom(Text, Atom),
          stable_candidate_id(
              pragmatic_atom, span(Id, Id), Atom, CandidateId)
        ),
        RawAtomCandidates),
    findall(
        evidence_candidate(CandidateId, pragmatic_relation,
                           Scope, Relation),
        ( pragmatic_relation(Utterances, Context, Relation),
          pragmatic_relation_scope(Relation, Scope),
          stable_candidate_id(
              pragmatic_relation, Scope, Relation, CandidateId)
        ),
        RawRelationCandidates),
    append(RawAtomCandidates, RawRelationCandidates, RawCandidates),
    sort(RawCandidates, Candidates).

stable_candidate_id(Layer, Scope, Payload, CandidateId) :-
    variant_sha1(candidate(Layer, Scope, Payload), Hash),
    format(string(CandidateId), "~w:~w", [Layer, Hash]).

pragmatic_relation_scope(
    named_stance_candidate(CurrentId, _Stance, _Speaker, AntecedentId,
                           _Marker, _Basis, _Confidence, _Interpretation),
    span(AntecedentId, CurrentId)).
pragmatic_relation_scope(
    adjacent_stance_candidate(CurrentId, _Stance, PriorId, _Marker,
                              _Basis, _Confidence, _Interpretation),
    span(PriorId, CurrentId)).
pragmatic_relation_scope(
    adjacent_negative_response_candidate(CurrentId, PriorId, _Marker,
                                         _Basis, _Confidence,
                                         _Interpretation),
    span(PriorId, CurrentId)).
pragmatic_relation_scope(
    reason_for_candidate(CurrentId, PriorId, _Marker,
                         _Basis, _Confidence, _Interpretation),
    span(PriorId, CurrentId)).
pragmatic_relation_scope(
    intra_utterance_reason_candidate(
        Id, _Conclusion, _Reason, _Marker, _Confidence, _Interpretation),
    span(Id, Id)).
pragmatic_relation_scope(
    conditional_requirement_candidate(
        Id, _Condition, _Action, _Marker, _Confidence, _Interpretation),
    span(Id, Id)).
pragmatic_relation_scope(
    conditional_component_candidate(
        Id, _Component, _Target, _Marker,
        _Basis, _Confidence, _Interpretation),
    span(Id, Id)).
pragmatic_relation_scope(
    normative_scope_candidate(
        Id, _Norm, _Target, _Marker, _Basis, _Confidence, _Interpretation),
    span(Id, Id)).

%! analyze_pragmatics(+Utterances, -Analysis) is det.
analyze_pragmatics(Utterances, Analysis) :-
    analyze_pragmatics(Utterances, [], Analysis).

%! analyze_pragmatics(+Utterances, +Context, -Analysis) is det.
analyze_pragmatics(Utterances, Context, Analysis) :-
    must_be(list, Utterances),
    must_be(list, Context),
    valid_context_evidence(Utterances, Context),
    maplist(pragmatic_utterance_dict, Utterances, UtteranceDicts),
    findall(Relation,
            pragmatic_relation(Utterances, Context, Relation),
            RawRelations),
    sort(RawRelations, Relations),
    maplist(pragmatic_relation_candidate_dict, Relations, RelationDicts),
    pragmatic_evidence_candidates(Utterances, Context, EvidenceCandidates),
    pragmatic_atom_counts(UtteranceDicts, AtomCounts),
    pragmatic_relation_counts(RelationDicts, RelationCounts),
    length(Utterances, UtteranceCount),
    count_utterance_atoms(UtteranceDicts, AtomCount),
    length(RelationDicts, RelationCount),
    length(EvidenceCandidates, EvidenceCandidateCount),
    Analysis = _{
        provenance: "deterministic_prolog_pragmatic_candidates",
        utterance_count: UtteranceCount,
        atom_count: AtomCount,
        relation_count: RelationCount,
        evidence_candidate_count: EvidenceCandidateCount,
        atom_counts: AtomCounts,
        relation_counts: RelationCounts,
        utterances: UtteranceDicts,
        relations: RelationDicts,
        limits: _{
            commitments: "no commitment or entitlement is deposited",
            interaction: "no uptake, agreement success, challenge success, settlement, or reopening is inferred",
            trace: "no interactional trace code is assigned",
            pml: "no PML operator or S/O/N mode is assigned",
            semantics: "bounded lexical and construction candidates only; no general semantic parse"
        }
    }.

pragmatic_utterance_dict(utterance(Id, Speaker, Text), Dict) :-
    findall(Atom, pragmatic_atom(Text, Atom), RawAtoms),
    sort(RawAtoms, Atoms),
    maplist(pragmatic_atom_candidate_dict(Id), Atoms, AtomDicts),
    text_string(Text, String),
    Dict = _{id: Id, speaker: Speaker, text: String, atoms: AtomDicts}.

pragmatic_atom_candidate_dict(
    UtteranceId,
    pragmatic_atom(Type, Marker, count(Count), Confidence),
    Dict) :-
    Atom = pragmatic_atom(Type, Marker, count(Count), Confidence),
    stable_candidate_id(
        pragmatic_atom, span(UtteranceId, UtteranceId), Atom, CandidateId),
    Dict = _{candidate_id: CandidateId,
      kind: pragmatic_atom, subtype: Type, marker: Marker,
      count: Count, confidence: Confidence,
      commitment_inference: not_assigned,
      interaction_inference: not_assigned,
      trace_inference: not_assigned,
      pml_inference: not_assigned}.

pragmatic_relation_candidate_dict(Relation, Dict) :-
    pragmatic_relation_dict(Relation, BaseDict),
    pragmatic_relation_scope(Relation, Scope),
    stable_candidate_id(pragmatic_relation, Scope, Relation, CandidateId),
    put_dict(candidate_id, BaseDict, CandidateId, Dict).

pragmatic_relation_dict(
    named_stance_candidate(Id, Stance, Speaker, AntecedentId,
                           Marker, speaker_alias(Source), Confidence,
                           interpretation_not_assigned),
    _{kind: named_stance_candidate, utterance_id: Id,
      stance: Stance, target_speaker: Speaker,
      target_utterance_id: AntecedentId, marker: Marker,
      basis: speaker_alias, evidence_source: Source,
      confidence: Confidence, interpretation: not_assigned}).
pragmatic_relation_dict(
    adjacent_stance_candidate(Id, Stance, PriorId, Marker,
                              Basis, Confidence,
                              interpretation_not_assigned),
    _{kind: adjacent_stance_candidate, utterance_id: Id,
      stance: Stance, target_utterance_id: PriorId, marker: Marker,
      basis: Basis, confidence: Confidence,
      interpretation: not_assigned}).
pragmatic_relation_dict(
    adjacent_negative_response_candidate(
        Id, PriorId, Marker, Basis, Confidence,
        interpretation_not_assigned),
    _{kind: adjacent_negative_response_candidate, utterance_id: Id,
      target_utterance_id: PriorId, marker: Marker,
      basis: Basis, confidence: Confidence,
      interaction_role: not_assigned,
      interpretation: not_assigned}).
pragmatic_relation_dict(
    reason_for_candidate(Id, PriorId, Marker, Basis, Confidence,
                         interpretation_not_assigned),
    _{kind: reason_for_candidate, utterance_id: Id,
      target_utterance_id: PriorId, marker: Marker,
      basis: Basis, confidence: Confidence,
      interpretation: not_assigned}).
pragmatic_relation_dict(
    intra_utterance_reason_candidate(
        Id, conclusion(Conclusion), reason(Reason), Marker,
        Confidence, interpretation_not_assigned),
    _{kind: intra_utterance_reason_candidate, utterance_id: Id,
      conclusion: Conclusion, reason: Reason, marker: Marker,
      confidence: Confidence, interpretation: not_assigned}).
pragmatic_relation_dict(
    conditional_requirement_candidate(
        Id, condition(Condition), required_action(Action),
        requirement_marker(Marker), Confidence,
        interpretation_not_assigned),
    _{kind: conditional_requirement_candidate, utterance_id: Id,
      condition: Condition, required_action: Action,
      requirement_marker: Marker, confidence: Confidence,
      interpretation: not_assigned}).
pragmatic_relation_dict(
    conditional_component_candidate(
        Id, Component, Target, Marker,
        supplied_reference_link(Source), Confidence,
        interpretation_not_assigned),
    _{kind: conditional_component_candidate, utterance_id: Id,
      component: Component, target: Target, marker: Marker,
      basis: supplied_reference_link, evidence_source: Source,
      confidence: Confidence, interpretation: not_assigned}).
pragmatic_relation_dict(
    normative_scope_candidate(
        Id, Norm, Target, Marker,
        supplied_reference_link(Source), Confidence,
        interpretation_not_assigned),
    _{kind: normative_scope_candidate, utterance_id: Id,
      normative_cue: Norm, target: Target, marker: Marker,
      basis: supplied_reference_link, evidence_source: Source,
      confidence: Confidence, interpretation: not_assigned}).

pragmatic_atom_counts(Utterances, Counts) :-
    findall(Type,
            ( member(Utterance, Utterances),
              member(Atom, Utterance.atoms),
              Type = Atom.subtype
            ),
            Types),
    counted_values(Types, Counts).

pragmatic_relation_counts(Relations, Counts) :-
    findall(Kind,
            ( member(Relation, Relations),
              Kind = Relation.kind
            ),
            Kinds),
    counted_values(Kinds, Counts).

count_utterance_atoms(Utterances, Count) :-
    findall(Atom,
            ( member(Utterance, Utterances),
              member(Atom, Utterance.atoms)
            ),
            Atoms),
    length(Atoms, Count).

counted_values(Values, Counts) :-
    msort(Values, Sorted),
    clumped(Sorted, Clumped),
    findall(_{kind: Kind, count: Count},
            member(Kind-Count, Clumped),
            Counts).

prefix_before(Index, Utterances, Prefix) :-
    PrefixLength is Index - 1,
    length(Prefix, PrefixLength),
    append(Prefix, _Rest, Utterances).

most_recent_speaker_utterance(Prior, Speaker, Id) :-
    reverse(Prior, Reversed),
    member(utterance(Id, Speaker, _Text), Reversed),
    !.

adjacent_utterances([A, B | _], A, B).
adjacent_utterances([_ | Rest], A, B) :-
    adjacent_utterances(Rest, A, B).

contains_sequence(Pattern, Tokens) :-
    append(_Before, Rest, Tokens),
    append(Pattern, _After, Rest),
    !.

sequence_count(Pattern, Tokens, Count) :-
    findall(1,
            ( append(_Before, Rest, Tokens),
              append(Pattern, _After, Rest)
            ),
            Matches),
    length(Matches, Count).

token_count(Token, Tokens, Count) :-
    include(==(Token), Tokens, Matches),
    length(Matches, Count).

text_string(Text, String) :-
    (   string(Text)
    ->  String = Text
    ;   atom(Text)
    ->  atom_string(Text, String)
    ;   type_error(text, Text)
    ).
