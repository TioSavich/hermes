/** <module> Controlled-language alignment over execution-observed traces
 *
 * These predicates align transcript spans with witnessed automaton
 * transitions.  A complete alignment is evidence for a candidate strategy,
 * not a diagnosis of a learner or proof that the strategy was used.  Partial
 * and mistaken work retains its current frontier and the evidence that would
 * still be needed.
 */
:- module(strategy_recognizer,
          [ recognize_strategies/2,          % +Text, -Candidates
            generate_strategy_language/3,   % +Operation, +Kind, -Text
            generate_strategy_variant/4,    % +Operation, +Kind, +Variant, -Text
            observed_strategy/3             % ?Operation, ?Kind, -Actions
          ]).

:- use_module(library(error), [must_be/2]).
:- use_module(library(apply), [include/3]).
:- use_module(library(lists), [list_to_set/2]).
:- use_module(library(porter_stem), [tokenize_atom/2]).

:- include('../knowledge/strategies/transition_tables/addition.pl').
:- include('../knowledge/strategies/transition_tables/algebraic.pl').
:- include('../knowledge/strategies/transition_tables/counting.pl').
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


%!  recognize_strategies(+Text, -Candidates) is det.
%
%   Candidates are sorted by support level and decreasing trace coverage.
%   Token offsets are zero-based and half-open over the normalized token
%   sequence.
recognize_strategies(Text, Candidates) :-
    must_be(text, Text),
    tokenize_atom(Text, RawTokens),
    maplist(normalize_token, RawTokens, Tokens),
    findall(Candidate,
            ( observed_steps(Operation, Kind, Steps),
              strategy_candidate(Operation, Kind, Steps, Tokens, Candidate),
              Candidate.matched_count > 0
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
    Confidence is MatchedCount / ExpectedCount,
    ordered_prefix(Annotated, Matches, PrefixMatches),
    length(PrefixMatches, PrefixCount),
    frontier(Annotated, PrefixCount, Frontier),
    missing_evidence(Annotated, Matches, Missing),
    incompatible_transitions(
        Matches, PrefixMatches, Frontier.state, Incompatible),
    support_level(ExpectedCount, MatchedCount, PrefixCount,
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
                     controlled_action_language]
    }.

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

action_spans(Action, Tokens, Spans) :-
    findall(span(Start, End, Surface),
            ( action_surface(Action, Surface),
              surface_span(Tokens, Surface, Start, End)
            ),
            Spans0),
    sort(Spans0, Spans).

action_surface(Action, Phrase) :-
    action_phrase(Action, Phrase).
action_surface(Action, Phrase) :-
    action_tokens(Action, Phrase).
action_surface(Action, Phrase) :-
    action_tokens(Action, Tokens),
    synonym_tokens(Tokens, Phrase).

action_tokens(Action, Tokens) :-
    atomic_list_concat(Tokens, '_', Action).

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

support_level(Expected, Matched, Prefix, [], [], clean_run) :-
    Expected =:= Matched,
    Expected =:= Prefix,
    !.
support_level(_, Matched, Prefix, _, _, partial_trace) :-
    ( Matched >= 2 ; Prefix >= 2 ),
    !.
support_level(_, _, _, _, _, lexical_hint).

match_span_dict(
    match(Index, _, Action, _, Start, End, Surface),
    _{step_index:Index, action:Action, token_start:Start, token_end:End,
      normalized_surface:Text}) :-
    atomic_list_concat(Surface, ' ', Text).

match_transition_dict(
    match(Index, Before, Action, After, Start, End, _),
    _{step_index:Index, action:Action, from:Before, to:After,
      token_start:Start, token_end:End,
      provenance:execution_observed(contract_example)}).

match_action(match(_, _, Action, _, _, _, _), Action).

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

compare_candidates(Order, Left, Right) :-
    support_rank(Left.support_level, LeftRank),
    support_rank(Right.support_level, RightRank),
    compare(RankOrder, RightRank, LeftRank),
    ( RankOrder \== (=)
    -> Order = RankOrder
    ; compare(ConfidenceOrder, Right.confidence, Left.confidence),
      ( ConfidenceOrder \== (=)
      -> Order = ConfidenceOrder
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
