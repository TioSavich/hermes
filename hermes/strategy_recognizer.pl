/** <module> Controlled-language alignment over execution-observed traces
 *
 * These predicates align transcript spans with witnessed automaton
 * transitions.  A complete alignment is evidence for a candidate strategy,
 * not a diagnosis of a learner or proof that the strategy was used.  Partial
 * and mistaken work retains its current frontier and the evidence that would
 * still be needed.
 *
 * WHAT COUNTS AS EVIDENCE, AND WHY IT IS WEIGHED.  A surface reaches every
 * trace whose action language contains it, and some surfaces reach many.
 * "i got" is the authored phrase for the canonical action name_result, and
 * 42 of the 218 observed traces have a step that maps to name_result, so the
 * phrase alone once returned 26 candidates for any sentence carrying it,
 * mathematical or not.  Weighing fixes the arithmetic of that: a surface
 * carried by Reach traces supports each of them by 1/Reach, distinct
 * surfaces are weighed once each, and a one-word surface is weighed at zero
 * because ordinary English uses "round", "first" and "distance" for ordinary
 * reasons.  The sum is unshared_evidence, and a candidate is returned only
 * when it clears recognition_floor/1.
 *
 * WHAT CONFIDENCE NOW SAYS.  confidence is unshared_evidence multiplied by
 * trace_coverage (matched steps over expected steps), capped at one.  Both
 * factors are needed and neither is sufficient: coverage alone ranked by
 * automaton length whenever every candidate matched the same single span,
 * and evidence alone discards the fact that two matched steps out of three
 * leave less unsaid than two out of eight.  trace_coverage is emitted
 * separately, so the older reading stays readable beside the new one.
 *
 * WHAT THIS DOES NOT REACH.  Weighing separates candidates that share a
 * surface only by how much of each trace the surface covers; where two
 * traces of the same length share their whole matched surface set the
 * recognizer cannot separate them, and their equal unshared_evidence is the
 * honest report of that.
 */
:- module(strategy_recognizer,
          [ recognize_strategies/2,          % +Text, -Candidates
            recognize_strategy_episode/2,   % +Utterances, -Candidates
            generate_strategy_language/3,   % +Operation, +Kind, -Text
            generate_strategy_variant/4,    % +Operation, +Kind, +Variant, -Text
            observed_strategy/3             % ?Operation, ?Kind, -Actions
          ]).

:- use_module(library(error), [must_be/2]).
:- use_module(library(apply), [include/3, foldl/4]).
:- use_module(library(lists), [list_to_set/2]).
:- use_module(library(pairs), [group_pairs_by_key/2]).
:- use_module(library(porter_stem), [tokenize_atom/2]).
:- use_module(library(solution_sequences), [distinct/2]).
:- use_module(strategies(action_vocabulary_map), [action_maps/7]).
:- use_module(strategies(canonical_phrases), [canonical_phrase/2]).
:- use_module(strategies(utterance_layers), [denied_span/3, canonical_predicate/2]).
:- use_module(strategies(attested_phrases), [attested_phrase/6]).

:- include('../knowledge/strategies/transition_tables/addition.pl').
:- include('../knowledge/strategies/transition_tables/algebraic.pl').
:- include('../knowledge/strategies/transition_tables/calculus.pl').
:- include('../knowledge/strategies/transition_tables/counting.pl').
:- include('../knowledge/strategies/transition_tables/probability.pl').
:- include('../knowledge/strategies/transition_tables/decimal.pl').
:- include('../knowledge/strategies/transition_tables/division.pl').
:- include('../knowledge/strategies/transition_tables/fraction.pl').
:- include('../knowledge/strategies/transition_tables/geometry.pl').
:- include('../knowledge/strategies/transition_tables/integer.pl').
:- include('../knowledge/strategies/transition_tables/measurement.pl').
:- include('../knowledge/strategies/transition_tables/multiplication.pl').
:- include('../knowledge/strategies/transition_tables/ratio.pl').
:- include('../knowledge/strategies/transition_tables/statistics.pl').
:- include('../knowledge/strategies/transition_tables/subtraction.pl').


% Reviewed classroom-language alternatives retained from the first five
% recognizers.  Every observed action also has a controlled rendering derived
% from its authored label below; that rendering is a test fixture, not a claim
% about spontaneous classroom wording.
action_phrase(choose_addend_near_base, [close,to,ten]).
action_phrase(choose_addend_near_base, [almost,ten]).
action_phrase(choose_addend_near_base, [near,ten]).
action_phrase(split_other_addend, [split,the,other,number]).
action_phrase(split_other_addend, [broke,the,other,number,apart]).
action_phrase(split_other_addend, [decomposed,the,other,number]).
action_phrase(make_base, [made,ten]).
action_phrase(make_base, [make,ten]).
action_phrase(make_base, [got,to,ten]).
action_phrase(add_leftover_after_base, [added,the,leftover]).
action_phrase(add_leftover_after_base, [add,the,rest]).
action_phrase(add_leftover_after_base, [used,the,remaining,part]).
action_phrase(preserve_total_by_using_both_split_parts, [used,both,parts]).
action_phrase(preserve_total_by_using_both_split_parts,
              [put,the,parts,back,together]).

action_phrase(hold_group_size_as_repeated_addend, [groups,of]).
action_phrase(hold_group_size_as_repeated_addend, [in,each,group]).
action_phrase(hold_group_size_as_repeated_addend, [each,group,has]).
action_phrase(hold_number_of_groups_as_iterations, [number,of,groups]).
action_phrase(hold_number_of_groups_as_iterations, [how,many,groups]).
action_phrase(hold_number_of_groups_as_iterations, [groups,in,all]).
action_phrase(add_equal_group_repeatedly, [repeated,addition]).
action_phrase(add_equal_group_repeatedly, [added,the,same,amount,again]).
action_phrase(add_equal_group_repeatedly, [skip,counted]).
action_phrase(name_accumulated_total, [altogether]).
action_phrase(name_accumulated_total, [the,total]).

action_phrase(set_group_size, [groups,of]).
action_phrase(set_group_size, [group,size]).
action_phrase(set_group_size, [in,each,group]).
action_phrase(repeatedly_remove_group_size, [kept,subtracting]).
action_phrase(repeatedly_remove_group_size,
              [took,away,one,group,at,a,time]).
action_phrase(repeatedly_remove_group_size, [removed,groups]).
action_phrase(count_measured_groups, [counted,the,groups]).
action_phrase(count_measured_groups, [how,many,groups]).
action_phrase(count_measured_groups, [number,of,groups]).
action_phrase(preserve_leftover_as_remainder, [left,over]).
action_phrase(preserve_leftover_as_remainder, [the,remainder]).
action_phrase(name_quotient_and_remainder, [quotient,and,remainder]).
action_phrase(name_quotient_and_remainder,
              [groups,with,some,left,over]).

action_phrase(establish_referent_whole, [the,whole]).
action_phrase(establish_referent_whole, [one,whole]).
action_phrase(establish_referent_whole, [whole,amount]).
action_phrase(partition_whole_into_equal_units, [equal,parts]).
action_phrase(partition_whole_into_equal_units,
              [split,the,whole,into,equal,parts]).
action_phrase(partition_whole_into_equal_units, [same,size,pieces]).
action_phrase(select_one_partition_as_unit_fraction,
              [one,of,the,equal,parts]).
action_phrase(select_one_partition_as_unit_fraction, [one,piece,is]).
action_phrase(select_one_partition_as_unit_fraction, [unit,fraction]).
action_phrase(preserve_inside_and_iterable_status, [part,of,the,whole]).
action_phrase(preserve_inside_and_iterable_status,
              [fits,back,into,the,whole]).
action_phrase(preserve_inside_and_iterable_status, [iterate,the,part]).

action_phrase(identify_base_ratio, [the,ratio]).
action_phrase(identify_base_ratio, [for,every]).
action_phrase(identify_base_ratio, [starting,ratio]).
action_phrase(identify_scale_factor, [scale,factor]).
action_phrase(identify_scale_factor, [times,as,many]).
action_phrase(identify_scale_factor, [multiplied,both]).
action_phrase(scale_first_term_multiplicatively,
              [multiplied,the,first,term]).
action_phrase(scale_first_term_multiplicatively,
              [scaled,the,first,quantity]).
action_phrase(scale_first_term_multiplicatively, [multiplied,both]).
action_phrase(scale_second_term_multiplicatively,
              [multiplied,the,second,term]).
action_phrase(scale_second_term_multiplicatively,
              [scaled,the,second,quantity]).
action_phrase(scale_second_term_multiplicatively, [multiplied,both]).
action_phrase(compose_equivalent_ratio, [equivalent,ratio]).
action_phrase(compose_equivalent_ratio, [same,ratio]).
action_phrase(preserve_multiplicative_unit_ratio,
              [ratio,stays,the,same]).
action_phrase(preserve_multiplicative_unit_ratio, [same,rate]).
action_phrase(preserve_multiplicative_unit_ratio, [for,every]).


% A bounded synonym map supplies one controlled transfer variant per action
% when a mapped token occurs.  The authored action atom remains the canonical
% vocabulary and is always recoverable from a match.
controlled_synonym(accept, allow).
controlled_synonym(add, combine).
controlled_synonym(align, straighten).
controlled_synonym(assign, give).
controlled_synonym(calculate, compute).
controlled_synonym(choose, pick).
controlled_synonym(classify, sort).
controlled_synonym(compare, contrast).
controlled_synonym(compose, assemble).
controlled_synonym(compute, calculate).
controlled_synonym(confirm, verify).
controlled_synonym(coordinate, connect).
controlled_synonym(count, tally).
controlled_synonym(decompose, break).
controlled_synonym(determine, decide).
controlled_synonym(distribute, spread).
controlled_synonym(enumerate, list).
controlled_synonym(establish, set).
controlled_synonym(extend, continue).
controlled_synonym(form, make).
controlled_synonym(identify, find).
controlled_synonym(iterate, repeat).
controlled_synonym(locate, place).
controlled_synonym(measure, gauge).
controlled_synonym(multiply, scale).
controlled_synonym(name, call).
controlled_synonym(omit, skip).
controlled_synonym(order, arrange).
controlled_synonym(partition, split).
controlled_synonym(preserve, keep).
controlled_synonym(read, interpret).
controlled_synonym(recognize, notice).
controlled_synonym(recompose, rebuild).
controlled_synonym(regroup, bundle).
controlled_synonym(remove, withdraw).
controlled_synonym(report, state).
controlled_synonym(retrieve, recall).
controlled_synonym(reverse, switch).
controlled_synonym(scale, multiply).
controlled_synonym(select, pick).
controlled_synonym(split, break).
controlled_synonym(subtract, remove).
controlled_synonym(sum, total).
controlled_synonym(target, seek).
controlled_synonym(transfer, move).
controlled_synonym(traverse, follow).
controlled_synonym(verify, check).
controlled_synonym(write, record).


%!  observed_strategy(?Operation, ?Kind, -Actions) is nondet.
%
%   Actions are returned in the order recorded by the executed contract
%   witness.  Clause order matters here because one observed trace contains a
%   self-loop whose two authored actions cannot be reconstructed from graph
%   topology alone.
observed_strategy(Operation, Kind, Actions) :-
    observed_steps(Operation, Kind, Steps),
    maplist(step_action, Steps, Actions).

observed_steps(Operation, Kind, Steps) :-
    setof(Operation-Kind,
          Before^Action^After^
          automaton_transition(
              Operation, Kind, Before, Action, After,
              provenance(observed(contract_example))),
          Signatures),
    member(Operation-Kind, Signatures),
    findall(step(Before, Action, After),
            automaton_transition(
                Operation, Kind, Before, Action, After,
                provenance(observed(contract_example))),
            Steps),
    Steps \== [].

step_action(step(_, Action, _), Action).


%!  recognition_floor(-Floor) is det.
%
%   The least unshared evidence a candidate must carry to be returned at
%   all.  The floor is 10 / ObservedTraceCount: because a surface carried by
%   Reach traces contributes 1/Reach, one surface clears the floor exactly
%   when it fits no more than a tenth of the live observed corpus, and
%   several broader surfaces can add to as much.  On 2026-08-03 the observed
%   corpus grew from 114 to 218 traces; counting surfaces grew from a Reach
%   of 9 to 20, diluting their evidence from 1/9 to 1/20, and the constant
%   0.1 floor rejected them despite preserving the same corpus-relative
%   reach.  Computing the floor from observed_steps/3 keeps that stated
%   semantics as the corpus changes.
recognition_floor(Floor) :-
    findall(Operation-Kind,
            observed_steps(Operation, Kind, _),
            ObservedTraces),
    length(ObservedTraces, ObservedTraceCount),
    ObservedTraceCount > 0,
    Floor is 10.0 / ObservedTraceCount.


%!  surface_reach(+Surface, -Reach) is det.
%
%   Reach is how many execution-observed traces have a step whose action
%   language contains Surface.  A surface reaching many traces separates
%   none of them.  The index is built once per process on first use, from
%   the same action_surface/2 the matcher uses, so it cannot drift from what
%   actually matches.
surface_reach(Surface, Reach) :-
    build_surface_reach,
    (   surface_reach_row(Surface, Reach0)
    ->  Reach = Reach0
    ;   Reach = 1
    ).

:- dynamic surface_reach_row/2.
:- dynamic surface_reach_built/0.

build_surface_reach :-
    surface_reach_built,
    !.
build_surface_reach :-
    findall(Surface-Signature,
            ( observed_steps(Operation, Kind, Steps),
              Signature = Operation-Kind,
              member(step(_, Action, _), Steps),
              action_surface(Action, Surface)
            ),
            Pairs0),
    sort(Pairs0, Pairs),
    group_pairs_by_key(Pairs, Grouped),
    forall(member(Surface-Signatures, Grouped),
           ( length(Signatures, Reach),
             assertz(surface_reach_row(Surface, Reach))
           )),
    assertz(surface_reach_built).


%!  surface_weight(+Surface, -Weight) is det.
%
%   A surface fitting Reach traces is worth 1/Reach to each of them.  A
%   one-word surface is worth nothing: 32 single words are recognition
%   surfaces here, 17 of them fragments of an action identifier (init, emit,
%   second) and 15 cited from the literature as bare words (round, split,
%   distance), and an ordinary sentence uses those words for ordinary
%   reasons.  The match itself is still recorded, so matched_count, missing
%   evidence and the frontier are unchanged by this; only the evidence the
%   match contributes is zero.
surface_weight(Surface, Weight) :-
    (   Surface = [_]
    ->  Weight = 0.0
    ;   surface_reach(Surface, Reach),
        Weight is 1.0 / Reach
    ).


%!  weigh_surfaces(+Surfaces, -Evidence, -Count) is det.
%
%   Surfaces are sorted to distinct before weighing.  The same surface
%   matching two steps is one thing the speaker said, not two, and counting
%   it twice was how a repeated generic phrase reached partial_trace.
weigh_surfaces(Surfaces0, Evidence, Count) :-
    sort(Surfaces0, Surfaces),
    length(Surfaces, Count),
    foldl(add_surface_weight, Surfaces, 0.0, Evidence).

add_surface_weight(Surface, Evidence0, Evidence) :-
    surface_weight(Surface, Weight),
    Evidence is Evidence0 + Weight.


%!  candidate_confidence(+Evidence, +Matched, +Expected, -Coverage, -Confidence)
%
%   Confidence is the unshared evidence an utterance supplies for a trace,
%   multiplied by the share of that trace's steps the evidence reaches, and
%   capped at one.  Trace length enters only through the second factor, so a
%   short automaton no longer outranks a long one on the strength of the
%   same lone generic span.
candidate_confidence(Evidence, Matched, Expected, Coverage, Confidence) :-
    Coverage is Matched / Expected,
    Product is Evidence * Coverage,
    Confidence is min(1.0, float(Product)).


%!  recognize_strategies(+Text, -Candidates) is det.
%
%   Candidates are sorted by support level, then by decreasing unshared
%   evidence times trace coverage.  A candidate whose unshared evidence is
%   under recognition_floor/1 is not returned at all, so an empty list is an
%   abstention and not a failure.  Token offsets are zero-based and half-open
%   over the normalized token sequence.
recognize_strategies(Text, Candidates) :-
    must_be(text, Text),
    tokenize_atom(Text, RawTokens),
    maplist(normalize_token, RawTokens, Tokens),
    recognition_floor(Floor),
    findall(Candidate,
            ( observed_steps(Operation, Kind, Steps),
              strategy_candidate(Operation, Kind, Steps, Tokens, Candidate),
              Candidate.matched_count > 0,
              Candidate.unshared_evidence >= Floor
            ),
            Candidates0),
    predsort(compare_candidates, Candidates0, Candidates).

normalize_token(Token0, Token) :-
    ( atom(Token0) -> downcase_atom(Token0, Token) ; Token = Token0 ).

strategy_candidate(Operation, Kind, Steps, Tokens, Candidate) :-
    annotate_steps(Steps, Annotated),
    step_matches(Annotated, Tokens, Matches),
    length(Matches, MatchedCount),
    length(Annotated, ExpectedCount),
    maplist(match_surface, Matches, MatchSurfaces),
    weigh_surfaces(MatchSurfaces, Evidence, SurfaceCount),
    candidate_confidence(
        Evidence, MatchedCount, ExpectedCount, Coverage, Confidence),
    ordered_prefix(Annotated, Matches, PrefixMatches),
    length(PrefixMatches, PrefixCount),
    frontier(Annotated, PrefixCount, Frontier),
    missing_evidence(Annotated, Matches, Missing),
    incompatible_transitions(
        Matches, PrefixMatches, Frontier.state, Incompatible),
    support_level(ExpectedCount, MatchedCount, PrefixCount,
                  SurfaceCount, Evidence,
                  Missing, Incompatible, Support),
    maplist(match_span_dict, Matches, MatchSpanDicts0),
    predsort(compare_span_dict, MatchSpanDicts0, MatchSpanDicts),
    maplist(match_transition_dict, Matches, TransitionDicts),
    maplist(match_action, Matches, RecoveredActions),
    first_step_state(Annotated, ObservedStart),
    last_step_state(Annotated, ObservedAccepting),
    Candidate = _{
        candidate_strategy: _{operation:Operation, kind:Kind},
        operation: Operation,
        kind: Kind,
        support_level: Support,
        confidence: Confidence,
        unshared_evidence: Evidence,
        trace_coverage: Coverage,
        distinct_matched_surfaces: SurfaceCount,
        matched_count: MatchedCount,
        expected_actions: ExpectedCount,
        matched_spans: MatchSpanDicts,
        matched_transitions: TransitionDicts,
        recovered_action_order: RecoveredActions,
        current_frontier: Frontier,
        frontier: Frontier,
        missing_evidence: Missing,
        incompatible_transitions: Incompatible,
        automaton_start: ObservedStart,
        automaton_accepting: [ObservedAccepting],
        provenance: [execution_observed(contract_example),
                     controlled_action_language,
                     surface_reach_weighted]
    }.

%!  recognize_strategy_episode(+Utterances, -Candidates) is det.
%
%   Align an ordered list of utterance strings with each execution-observed
%   trace.  The frontier advances only when an utterance supplies the next
%   expected action.  Token offsets remain local to an utterance, and
%   utterance_index is zero-based.  ordered_step_provenance records which
%   utterance supplied every action that advanced the frontier.
recognize_strategy_episode(Utterances, Candidates) :-
    must_be(list, Utterances),
    maplist(must_be(text), Utterances),
    episode_tokens(Utterances, EpisodeTokens),
    length(Utterances, UtteranceCount),
    recognition_floor(Floor),
    findall(Candidate,
            ( observed_steps(Operation, Kind, Steps),
              episode_strategy_candidate(
                  Operation, Kind, Steps, EpisodeTokens, UtteranceCount,
                  Candidate),
              Candidate.matched_count > 0,
              Candidate.unshared_evidence >= Floor
            ),
            Candidates0),
    predsort(compare_episode_candidates, Candidates0, Candidates).

episode_tokens(Utterances, EpisodeTokens) :-
    episode_tokens_(Utterances, 0, EpisodeTokens).

episode_tokens_([], _, []).
episode_tokens_([Utterance|Utterances], Index,
                [utterance(Index, Tokens)|EpisodeTokens]) :-
    tokenize_atom(Utterance, RawTokens),
    maplist(normalize_token, RawTokens, Tokens),
    NextIndex is Index + 1,
    episode_tokens_(Utterances, NextIndex, EpisodeTokens).

episode_strategy_candidate(
    Operation, Kind, Steps, EpisodeTokens, UtteranceCount, Candidate) :-
    annotate_steps(Steps, Annotated),
    episode_step_matches(Annotated, EpisodeTokens, Matches),
    length(Matches, MatchedCount),
    length(Annotated, ExpectedCount),
    maplist(episode_match_surface, Matches, MatchSurfaces),
    weigh_surfaces(MatchSurfaces, Evidence, SurfaceCount),
    candidate_confidence(
        Evidence, MatchedCount, ExpectedCount, Coverage, Confidence),
    ordered_episode_prefix(Annotated, Matches, PrefixMatches),
    length(PrefixMatches, PrefixCount),
    maplist(episode_match_surface, PrefixMatches, OrderedSurfaces),
    weigh_surfaces(OrderedSurfaces, OrderedEvidence, _),
    candidate_confidence(
        OrderedEvidence, PrefixCount, ExpectedCount,
        OrderedCoverage, OrderedConfidence),
    frontier(Annotated, PrefixCount, Frontier),
    episode_missing_evidence(Annotated, Matches, Missing),
    episode_incompatible_transitions(
        Matches, PrefixMatches, Frontier.state, Incompatible),
    support_level(ExpectedCount, MatchedCount, PrefixCount,
                  SurfaceCount, Evidence,
                  Missing, Incompatible, Support),
    maplist(episode_match_span_dict, Matches, MatchSpanDicts0),
    predsort(compare_episode_span_dict, MatchSpanDicts0, MatchSpanDicts),
    maplist(episode_match_transition_dict, Matches, TransitionDicts),
    maplist(episode_match_action, Matches, RecoveredActions),
    maplist(episode_match_action, PrefixMatches, OrderedActions),
    maplist(episode_match_provenance_dict,
            PrefixMatches, OrderedStepProvenance),
    first_step_state(Annotated, ObservedStart),
    last_step_state(Annotated, ObservedAccepting),
    Candidate = _{
        candidate_strategy: _{operation:Operation, kind:Kind},
        operation: Operation,
        kind: Kind,
        recognition_unit: episode,
        utterance_count: UtteranceCount,
        support_level: Support,
        confidence: Confidence,
        ordered_confidence: OrderedConfidence,
        unshared_evidence: Evidence,
        ordered_unshared_evidence: OrderedEvidence,
        trace_coverage: Coverage,
        ordered_trace_coverage: OrderedCoverage,
        distinct_matched_surfaces: SurfaceCount,
        matched_count: MatchedCount,
        ordered_action_count: PrefixCount,
        expected_actions: ExpectedCount,
        matched_spans: MatchSpanDicts,
        matched_transitions: TransitionDicts,
        recovered_action_order: RecoveredActions,
        ordered_action_order: OrderedActions,
        ordered_step_provenance: OrderedStepProvenance,
        current_frontier: Frontier,
        frontier: Frontier,
        missing_evidence: Missing,
        incompatible_transitions: Incompatible,
        automaton_start: ObservedStart,
        automaton_accepting: [ObservedAccepting],
        provenance: [execution_observed(contract_example),
                     controlled_action_language,
                     surface_reach_weighted,
                     ordered_episode_alignment]
    }.

episode_step_matches(Annotated, EpisodeTokens, Matches) :-
    episode_step_matches_(
        Annotated, EpisodeTokens, episode_cursor(0, 0), Matches).

episode_step_matches_([], _, _, []).
episode_step_matches_(
    [expected(Index, Before, Action, After, _)|Expected],
    EpisodeTokens, Cursor, Matches) :-
    episode_action_spans(Action, EpisodeTokens, Spans),
    ( first_episode_span_at_or_after(
          Spans, Cursor, episode_span(Utterance, Start, End, Surface))
    -> Matches =
           [episode_match(Index, Before, Action, After,
                          Utterance, Start, End, Surface)|Rest],
       NextCursor = episode_cursor(Utterance, End)
    ; Spans = [episode_span(Utterance, Start, End, Surface)|_]
    -> Matches =
           [episode_match(Index, Before, Action, After,
                          Utterance, Start, End, Surface)|Rest],
       NextCursor = Cursor
    ; Matches = Rest,
      NextCursor = Cursor
    ),
    episode_step_matches_(Expected, EpisodeTokens, NextCursor, Rest).

episode_action_spans(Action, EpisodeTokens, Spans) :-
    findall(episode_span(Utterance, Start, End, Surface),
            ( member(utterance(Utterance, Tokens), EpisodeTokens),
              action_surface(Action, Surface),
              surface_span(Tokens, Surface, Start, End),
              \+ denied_span(Tokens, Start, End)
            ),
            Spans0),
    sort(Spans0, Spans).

first_episode_span_at_or_after(
    [episode_span(Utterance, Start, End, Surface)|_], Cursor,
    episode_span(Utterance, Start, End, Surface)) :-
    episode_position_at_or_after(Utterance, Start, Cursor),
    !.
first_episode_span_at_or_after([_|Spans], Cursor, Span) :-
    first_episode_span_at_or_after(Spans, Cursor, Span).

episode_position_at_or_after(
    Utterance, Start, episode_cursor(CursorUtterance, CursorToken)) :-
    ( Utterance > CursorUtterance
    ; Utterance =:= CursorUtterance,
      Start >= CursorToken
    ).

ordered_episode_prefix(Annotated, Matches, PrefixMatches) :-
    ordered_episode_prefix_(
        Annotated, Matches, episode_cursor(0, 0), PrefixMatches).

ordered_episode_prefix_([], _, _, []).
ordered_episode_prefix_(
    [expected(Index, Before, Action, After, _)|Expected],
    Matches, Cursor, PrefixMatches) :-
    ( member(episode_match(Index, Before, Action, After,
                           Utterance, Start, End, Surface),
             Matches),
      episode_position_at_or_after(Utterance, Start, Cursor)
    -> PrefixMatches =
           [episode_match(Index, Before, Action, After,
                          Utterance, Start, End, Surface)|Rest],
       ordered_episode_prefix_(
           Expected, Matches, episode_cursor(Utterance, End), Rest)
    ; PrefixMatches = []
    ).

episode_missing_evidence(Annotated, Matches, Missing) :-
    findall(_{step_index:Index, action:Action,
              transition:_{from:Before, to:After}},
            ( member(expected(Index, Before, Action, After, _), Annotated),
              \+ memberchk(
                     episode_match(Index, Before, Action, After,
                                   _, _, _, _),
                     Matches)
            ),
            Missing).

episode_incompatible_transitions(
    Matches, PrefixMatches, FrontierState, Incompatible) :-
    findall(_{step_index:Index, action:Action, from:Before, to:After,
              utterance_index:Utterance,
              token_start:Start, token_end:End,
              reason:not_reachable_from_current_frontier,
              current_frontier:FrontierState},
            ( member(episode_match(Index, Before, Action, After,
                                   Utterance, Start, End, _),
                     Matches),
              \+ memberchk(
                     episode_match(Index, Before, Action, After,
                                   Utterance, Start, End, _),
                     PrefixMatches)
            ),
            Incompatible).

episode_match_span_dict(
    episode_match(Index, _, Action, _, Utterance, Start, End, Surface),
    _{step_index:Index, action:Action, utterance_index:Utterance,
      token_start:Start, token_end:End, normalized_surface:Text,
      surface_reach:Reach, surface_weight:Weight}) :-
    atomic_list_concat(Surface, ' ', Text),
    surface_reach(Surface, Reach),
    surface_weight(Surface, Weight).

episode_match_transition_dict(
    episode_match(Index, Before, Action, After,
                  Utterance, Start, End, _),
    _{step_index:Index, action:Action, from:Before, to:After,
      utterance_index:Utterance, token_start:Start, token_end:End,
      provenance:execution_observed(contract_example)}).

episode_match_provenance_dict(
    episode_match(Index, _, Action, _, Utterance, Start, End, Surface),
    _{step_index:Index, action:Action, utterance_index:Utterance,
      token_start:Start, token_end:End, normalized_surface:Text}) :-
    atomic_list_concat(Surface, ' ', Text).

episode_match_action(
    episode_match(_, _, Action, _, _, _, _, _), Action).

compare_episode_span_dict(Order, Left, Right) :-
    compare(UtteranceOrder,
            Left.utterance_index, Right.utterance_index),
    ( UtteranceOrder \== (=)
    -> Order = UtteranceOrder
    ; compare(StartOrder, Left.token_start, Right.token_start),
      ( StartOrder \== (=)
      -> Order = StartOrder
      ; compare(IndexOrder, Left.step_index, Right.step_index),
        ( IndexOrder \== (=)
        -> Order = IndexOrder
        ; compare(Order, Left.action, Right.action)
        )
      )
    ).

compare_episode_candidates(Order, Left, Right) :-
    support_rank(Left.support_level, LeftRank),
    support_rank(Right.support_level, RightRank),
    compare(RankOrder, RightRank, LeftRank),
    ( RankOrder \== (=)
    -> Order = RankOrder
    ; OrderedLeft is Left.ordered_unshared_evidence
                     * Left.ordered_trace_coverage,
      OrderedRight is Right.ordered_unshared_evidence
                      * Right.ordered_trace_coverage,
      compare(OrderedScoreOrder, OrderedRight, OrderedLeft),
      ( OrderedScoreOrder \== (=)
      -> Order = OrderedScoreOrder
      ; compare_candidates(Order, Left, Right)
      )
    ).

annotate_steps(Steps, Annotated) :-
    findall(expected(Index, Before, Action, After, Occurrence),
            ( nth1(Index, Steps, step(Before, Action, After)),
              action_occurrence(Index, Steps, Action, Occurrence)
            ),
            Annotated).

action_occurrence(Index, Steps, Action, Occurrence) :-
    findall(Seen,
            ( nth1(SeenIndex, Steps, step(_, Seen, _)),
              SeenIndex =< Index,
              Seen == Action
            ),
            SameActions),
    length(SameActions, Occurrence).

step_matches(Annotated, Tokens, Matches) :-
    step_matches_(Annotated, Tokens, 0, Matches).

step_matches_([], _, _, []).
step_matches_(
    [expected(Index, Before, Action, After, _)|Expected],
    Tokens, Cursor, Matches) :-
    action_spans(Action, Tokens, Spans),
    ( first_span_at_or_after(Spans, Cursor, span(Start, End, Surface))
    -> Matches =
           [match(Index, Before, Action, After, Start, End, Surface)|Rest],
       NextCursor = End
    ; Spans = [span(Start, End, Surface)|_]
    -> Matches =
           [match(Index, Before, Action, After, Start, End, Surface)|Rest],
       NextCursor = Cursor
    ; Matches = Rest,
      NextCursor = Cursor
    ),
    step_matches_(Expected, Tokens, NextCursor, Rest).

first_span_at_or_after([span(Start, End, Surface)|_], Cursor,
                       span(Start, End, Surface)) :-
    Start >= Cursor,
    !.
first_span_at_or_after([_|Spans], Cursor, Span) :-
    first_span_at_or_after(Spans, Cursor, Span).

% A span inside the reach of a denial is dropped rather than counted. Before
% this guard the recognizer matched "made ten" inside "i did not make ten" and
% returned make_ten_drop_leftover at 0.2 in favour of the strategy the sentence
% denies. The denial's reach is stated in
% knowledge/strategies/utterance_layers.pl and is deliberately crude; the
% alternative in force was no reach at all.
action_spans(Action, Tokens, Spans) :-
    findall(span(Start, End, Surface),
            ( action_surface(Action, Surface),
              surface_span(Tokens, Surface, Start, End),
              \+ denied_span(Tokens, Start, End)
            ),
            Spans0),
    sort(Spans0, Spans).

action_surface(Action, Phrase) :-
    action_phrase(Action, Phrase).
% Reviewed classroom phrasings authored once per canonical action, reaching
% every local label the vocabulary map sends to that action. 24 labels carry a
% hand-written phrase of their own above; this clause covers the other 784
% without asking for 784 more authoring decisions. The map and the phrases are
% both review-pending data, so this clause is the one place a recognition
% surface depends on them, and removing it returns the recognizer to
% identifier-derived phrasing alone.
action_surface(Action, Phrase) :-
    canonical_action_of(Action, Canonical),
    canonical_phrase(Canonical, Phrase).
% Cited surfaces from the research corpus. These are what a paper calls the
% step, not what a student says, and knowledge/strategies/attested_phrases.pl
% marks them register(analyst) for that reason. Before them, literature wording
% such as "jump through ten" or "always subtracting the smaller digit" returned
% no candidates at all.
%
% The widening this clause performs, stated: attested_phrase/6 cites a phrase for
% one (family, signature, action), and action_spans/3 knows only the action, so a
% phrase cited for one signature becomes a surface for the same-named action
% wherever it occurs. 138 of the 808 labels occur in more than one signature, and
% scripts/checks/attested_phrases.py counts how many rows the widening touches
% rather than leaving it implied.
action_surface(Action, Phrase) :-
    attested_phrase(_Family, _Signature, Action, Phrase, _Source, _Attachment).
% The person-free predicates. canonical_phrase/2's forms all begin "i", so they
% read a student describing their own work and not a teacher revoicing it. A
% predicate carries no person, so the person layer reads the person and the same
% surface serves "i made ten", "you made ten" and "she made ten".
action_surface(Action, Phrase) :-
    canonical_action_of(Action, Canonical),
    canonical_predicate(Canonical, Phrase).
action_surface(Action, Phrase) :-
    action_tokens(Action, Phrase).
action_surface(Action, Phrase) :-
    action_tokens(Action, Tokens),
    synonym_tokens(Tokens, Phrase).

action_tokens(Action, Tokens) :-
    atomic_list_concat(Tokens, '_', Action).

%!  canonical_action_of(+LocalLabel, -CanonicalAction) is nondet.
%
%   A local action label reaches its canonical action through any signature
%   that uses the label. The map is per signature; a label used by several
%   signatures under one canonical action yields that action once per
%   signature, and action_surface/2 is called inside a findall that sorts, so
%   duplicates do not multiply spans.
%   distinct/2 matters here rather than being tidiness. action_maps/7 is per
%   signature, so a label used by twelve signatures -- emit and init both are --
%   would yield its canonical action twelve times and every one of that action's
%   phrases twelve times with it. The spans are sorted downstream so the answer
%   was right, and the work was multiplied by up to twelve for nothing. The one
%   label that genuinely carries two canonical actions, establish_base, still
%   yields both.
canonical_action_of(Action, Canonical) :-
    distinct(Canonical,
             action_maps(_Family, _Signature, Action, Canonical,
                         _Confidence, _Evidence, _Status)).

synonym_tokens([Token|Tokens], [Synonym|Tokens]) :-
    controlled_synonym(Token, Synonym),
    !.
synonym_tokens([Token|Tokens], [Token|Synonyms]) :-
    synonym_tokens(Tokens, Synonyms).

surface_span(Tokens, Surface, Start, End) :-
    append(Prefix, Rest, Tokens),
    append(Surface, _, Rest),
    length(Prefix, Start),
    length(Surface, Length),
    End is Start + Length.

ordered_prefix(Annotated, Matches, PrefixMatches) :-
    ordered_prefix_(Annotated, Matches, 0, PrefixMatches).

ordered_prefix_([], _, _, []).
ordered_prefix_(
    [expected(Index, Before, Action, After, _)|Expected],
    Matches, Cursor, PrefixMatches) :-
    ( member(match(Index, Before, Action, After, Start, End, Surface),
             Matches),
      Start >= Cursor
    -> PrefixMatches =
           [match(Index, Before, Action, After, Start, End, Surface)|Rest],
       ordered_prefix_(Expected, Matches, End, Rest)
    ; PrefixMatches = []
    ).

frontier(Annotated, PrefixCount, Frontier) :-
    length(Annotated, ExpectedCount),
    ( PrefixCount =:= ExpectedCount
    -> last(Annotated, expected(_, _, _, State, _)),
       Frontier = _{state:State, status:accepting, next_action:none}
    ; NextIndex is PrefixCount + 1,
      nth1(NextIndex, Annotated,
           expected(NextIndex, State, Action, _, _)),
      Frontier = _{state:State, status:open, next_action:Action}
    ).

missing_evidence(Annotated, Matches, Missing) :-
    findall(_{step_index:Index, action:Action,
              transition:_{from:Before, to:After}},
            ( member(expected(Index, Before, Action, After, _), Annotated),
              \+ memberchk(
                     match(Index, Before, Action, After, _, _, _), Matches)
            ),
            Missing).

incompatible_transitions(Matches, PrefixMatches, FrontierState, Incompatible) :-
    findall(_{step_index:Index, action:Action, from:Before, to:After,
              token_start:Start, token_end:End,
              reason:not_reachable_from_current_frontier,
              current_frontier:FrontierState},
            ( member(match(Index, Before, Action, After,
                           Start, End, _), Matches),
              \+ memberchk(
                     match(Index, Before, Action, After,
                           Start, End, _), PrefixMatches)
            ),
            Incompatible).

%!  support_level(+Expected, +Matched, +Prefix, +Surfaces, +Evidence,
%!                +Missing, +Incompatible, -Support) is det.
%
%   partial_trace is what a consumer is invited to rely on, so it states
%   three things at once: two steps of the trace were reached in the trace's
%   own order, two different surfaces did the reaching, and together they
%   carry a full step's worth of unshared evidence.  The old rule asked only
%   for two matches in any order, which one repeated generic phrase supplied
%   on its own.
support_level(Expected, Matched, Prefix, _, _, [], [], clean_run) :-
    Expected =:= Matched,
    Expected =:= Prefix,
    !.
support_level(_, _, Prefix, Surfaces, Evidence, _, _, partial_trace) :-
    Prefix >= 2,
    Surfaces >= 2,
    Evidence >= 1.0,
    !.
support_level(_, _, _, _, _, _, _, lexical_hint).

match_span_dict(
    match(Index, _, Action, _, Start, End, Surface),
    _{step_index:Index, action:Action, token_start:Start, token_end:End,
      normalized_surface:Text, surface_reach:Reach,
      surface_weight:Weight}) :-
    atomic_list_concat(Surface, ' ', Text),
    surface_reach(Surface, Reach),
    surface_weight(Surface, Weight).

match_transition_dict(
    match(Index, Before, Action, After, Start, End, _),
    _{step_index:Index, action:Action, from:Before, to:After,
      token_start:Start, token_end:End,
      provenance:execution_observed(contract_example)}).

match_action(match(_, _, Action, _, _, _, _), Action).

match_surface(match(_, _, _, _, _, _, Surface), Surface).

episode_match_surface(
    episode_match(_, _, _, _, _, _, _, Surface), Surface).

compare_span_dict(Order, Left, Right) :-
    compare(StartOrder, Left.token_start, Right.token_start),
    ( StartOrder \== (=)
    -> Order = StartOrder
    ; compare(IndexOrder, Left.step_index, Right.step_index),
      ( IndexOrder \== (=)
      -> Order = IndexOrder
      ; compare(Order, Left.action, Right.action)
      )
    ).

first_step_state([expected(_, State, _, _, _)|_], State).
last_step_state(Annotated, State) :-
    last(Annotated, expected(_, _, _, State, _)).

%!  candidate_score(+Candidate, -Score) is det.
%
%   The uncapped form of the confidence: unshared evidence times trace
%   coverage.  Ranking uses it rather than confidence so that two candidates
%   both saturating the cap still order by how much they exceed it.
candidate_score(Candidate, Score) :-
    Score is Candidate.unshared_evidence * Candidate.trace_coverage.

compare_candidates(Order, Left, Right) :-
    support_rank(Left.support_level, LeftRank),
    support_rank(Right.support_level, RightRank),
    compare(RankOrder, RightRank, LeftRank),
    ( RankOrder \== (=)
    -> Order = RankOrder
    ; candidate_score(Left, LeftScore),
      candidate_score(Right, RightScore),
      compare(ScoreOrder, RightScore, LeftScore),
      ( ScoreOrder \== (=)
      -> Order = ScoreOrder
      ; compare(MatchOrder, Right.matched_count, Left.matched_count),
        ( MatchOrder \== (=)
        -> Order = MatchOrder
        ; compare(OperationOrder, Left.operation, Right.operation),
          ( OperationOrder \== (=)
          -> Order = OperationOrder
          ; compare(Order, Left.kind, Right.kind)
          )
        )
      )
    ).

support_rank(lexical_hint, 1).
support_rank(partial_trace, 2).
support_rank(clean_run, 3).


%!  generate_strategy_language(+Operation, +Kind, -Text) is semidet.
%
%   Emit the canonical controlled rendering of an execution-observed action
%   sequence.
generate_strategy_language(Operation, Kind, Text) :-
    generate_strategy_variant(Operation, Kind, canonical, Text).


%!  generate_strategy_variant(+Operation, +Kind, +Variant, -Text) is semidet.
%
%   Supported variants are canonical, synonym, and injected_error.  No current
%   observed transition table contains a witnessed commuting diamond, so this
%   module does not manufacture reordered traces.
generate_strategy_variant(Operation, Kind, Variant, Text) :-
    observed_strategy(Operation, Kind, Actions),
    variant_phrases(Variant, Actions, Phrases),
    maplist(phrase_text, Phrases, PhraseTexts),
    atomic_list_concat(PhraseTexts, ', then ', Text).

variant_phrases(canonical, Actions, Phrases) :-
    maplist(action_tokens, Actions, Phrases).
variant_phrases(synonym, Actions, Phrases) :-
    maplist(synonym_or_canonical, Actions, Phrases).
variant_phrases(injected_error, Actions, Phrases) :-
    maplist(action_tokens, Actions, Canonical),
    length(Actions, Count),
    ErrorIndex is (Count + 1) // 2,
    replace_nth1(ErrorIndex, Canonical, [unexpected,transition], Phrases).

synonym_or_canonical(Action, Phrase) :-
    action_tokens(Action, Tokens),
    ( once(synonym_tokens(Tokens, Synonyms))
    -> Phrase = Synonyms
    ; Phrase = Tokens
    ).

replace_nth1(1, [_|Items], Replacement, [Replacement|Items]) :-
    !.
replace_nth1(Index, [Item|Items], Replacement, [Item|Replaced]) :-
    Index > 1,
    Next is Index - 1,
    replace_nth1(Next, Items, Replacement, Replaced).

phrase_text(Phrase, Text) :-
    atomic_list_concat(Phrase, ' ', Text).
