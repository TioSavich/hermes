:- use_module(hermes(strategy_recognizer)).

:- initialization(main, main).

main :-
    observed_signatures(Signatures),
    length(Signatures, SignatureCount),
    expect_equal(114, SignatureCount, observed_signature_count),
    expect_family_counts(Signatures),
    forall(member(Operation-Kind, Signatures),
           expect_round_trips(Operation, Kind)),
    expect_reviewed_language,
    expect_episode_alignment,
    strategy_recognizer:recognize_strategies(
        "I do not know what to do next.", Empty),
    expect_equal([], Empty, honest_abstention),
    format("PASS strategy recognizers: 114/114 execution-observed signatures~n").

observed_signatures(Signatures) :-
    findall(Operation-Kind,
            strategy_recognizer:observed_strategy(
                Operation, Kind, _Actions),
            Signatures0),
    sort(Signatures0, Signatures).

expect_family_counts(Signatures) :-
    forall(member(Operation-Expected,
                  [ addition-18,
                    counting-7,
                    decimal-10,
                    division-16,
                    fraction-24,
                    geometry-2,
                    integer-1,
                    multiplication-20,
                    ratio-2,
                    subtraction-14
                  ]),
           ( include(has_operation(Operation), Signatures, Family),
             length(Family, Actual),
             expect_equal(Expected, Actual, family_count(Operation))
           )).

has_operation(Operation, Operation-_).

expect_round_trips(Operation, Kind) :-
    strategy_recognizer:observed_strategy(Operation, Kind, ExpectedActions),
    forall(member(Variant, [canonical, synonym]),
           ( strategy_recognizer:generate_strategy_variant(
                 Operation, Kind, Variant, Text),
             expect_clean_candidate(
                 Text, Operation, Kind, ExpectedActions, Variant)
           )),
    strategy_recognizer:generate_strategy_variant(
        Operation, Kind, injected_error, ErrorText),
    expect_error_candidate(
        ErrorText, Operation, Kind, ExpectedActions).

expect_clean_candidate(Text, Operation, Kind, ExpectedActions, Variant) :-
    candidate_for(Text, Operation, Kind, Candidate),
    expect_required_fields(Candidate),
    expect_equal(clean_run, Candidate.support_level,
                 clean_support(Operation, Kind, Variant)),
    expect_equal(ExpectedActions, Candidate.recovered_action_order,
                 recovered_order(Operation, Kind, Variant)),
    expect_equal([], Candidate.missing_evidence,
                 no_missing_evidence(Operation, Kind, Variant)),
    expect_equal([], Candidate.incompatible_transitions,
                 no_incompatible_transition(Operation, Kind, Variant)),
    expect_equal(accepting, Candidate.current_frontier.status,
                 accepting_frontier(Operation, Kind, Variant)).

expect_error_candidate(Text, Operation, Kind, ExpectedActions) :-
    candidate_for(Text, Operation, Kind, Candidate),
    expect_required_fields(Candidate),
    ( Candidate.support_level \== clean_run
    -> true
    ; throw(error(assertion_failed(
                injected_error_recognized_as_clean(Operation, Kind)), _))
    ),
    ( Candidate.missing_evidence \== []
    ; Candidate.incompatible_transitions \== []
    -> true
    ; throw(error(assertion_failed(
                injected_error_without_boundary(Operation, Kind)), _))
    ),
    Candidate.recovered_action_order = Recovered,
    ordered_subsequence(Recovered, ExpectedActions).

candidate_for(Text, Operation, Kind, Candidate) :-
    strategy_recognizer:recognize_strategies(Text, Candidates),
    ( member(Candidate, Candidates),
      Candidate.operation == Operation,
      Candidate.kind == Kind
    -> true
    ; throw(error(assertion_failed(
                missing_candidate(Operation, Kind, Text)), _))
    ).

expect_required_fields(Candidate) :-
    forall(member(Key,
                  [ candidate_strategy,
                    matched_spans,
                    matched_transitions,
                    current_frontier,
                    missing_evidence,
                    incompatible_transitions,
                    support_level
                  ]),
           ( get_dict(Key, Candidate, _)
           -> true
           ; throw(error(assertion_failed(missing_candidate_field(Key)), _))
           )).

ordered_subsequence([], _).
ordered_subsequence([Item|Items], Sequence) :-
    append(_, [Item|Rest], Sequence),
    ordered_subsequence(Items, Rest).

expect_reviewed_language :-
    expect_candidate(
        "I saw 8 was close to ten, split the other number, made ten, then added the leftover and used both parts.",
        addition, make_ten_split_leftover),
    expect_candidate(
        "There are 4 groups of 3. The number of groups is 4. I used repeated addition and found the total altogether.",
        multiplication, repeat_equal_groups),
    expect_candidate(
        "I made groups of 6, kept subtracting 6, counted the groups, and kept 2 left over as the remainder.",
        division, measure_groups_of_size),
    expect_candidate(
        "The whole was split into equal parts. One of the equal parts is the unit fraction and stays part of the whole.",
        fraction, unit_fraction_partition),
    expect_candidate(
        "The starting ratio has a scale factor. I multiplied both terms to make an equivalent ratio, so the ratio stays the same.",
        ratio, scale_ratio_unit).

expect_candidate(Text, Operation, Kind) :-
    candidate_for(Text, Operation, Kind, Candidate),
    ( Candidate.matched_transitions \== []
    -> true
    ; throw(error(assertion_failed(
                no_observed_transition(Operation, Kind)), _))
    ).

expect_episode_alignment :-
    Utterances = [
        "close to ten",
        "split the other number",
        "made ten",
        "added the leftover",
        "used both parts"
    ],
    forall(member(Utterance, Utterances),
           expect_not_accepting_single(
               Utterance, addition, make_ten_split_leftover)),
    strategy_recognizer:recognize_strategy_episode(Utterances, Candidates),
    ( member(Candidate, Candidates),
      Candidate.operation == addition,
      Candidate.kind == make_ten_split_leftover
    -> true
    ; throw(error(assertion_failed(
                missing_episode_candidate(
                    addition, make_ten_split_leftover)), _))
    ),
    expect_equal(clean_run, Candidate.support_level,
                 episode_clean_support),
    expect_equal(5, Candidate.ordered_action_count,
                 episode_ordered_action_count),
    expect_equal(accepting, Candidate.current_frontier.status,
                 episode_accepting_frontier),
    maplist(provenance_utterance_index,
            Candidate.ordered_step_provenance, UtteranceIndexes),
    expect_equal([0,1,2,3,4], UtteranceIndexes,
                 episode_utterance_provenance),
    reverse(Utterances, Reversed),
    expect_not_accepting_episode(
        Reversed, addition, make_ten_split_leftover).

expect_not_accepting_single(Text, Operation, Kind) :-
    strategy_recognizer:recognize_strategies(Text, Candidates),
    ( member(Candidate, Candidates),
      Candidate.operation == Operation,
      Candidate.kind == Kind,
      Candidate.current_frontier.status == accepting
    -> throw(error(assertion_failed(
                 single_utterance_reached_accepting(
                     Operation, Kind, Text)), _))
    ; true
    ).

expect_not_accepting_episode(Utterances, Operation, Kind) :-
    strategy_recognizer:recognize_strategy_episode(Utterances, Candidates),
    ( member(Candidate, Candidates),
      Candidate.operation == Operation,
      Candidate.kind == Kind,
      Candidate.current_frontier.status == accepting
    -> throw(error(assertion_failed(
                 reversed_episode_reached_accepting(
                     Operation, Kind)), _))
    ; true
    ).

provenance_utterance_index(Provenance, Index) :-
    Index = Provenance.utterance_index.

expect_equal(Expected, Actual, Label) :-
    ( Actual == Expected
    -> true
    ; throw(error(assertion_failed(
                Label-expected(Expected)-actual(Actual)), _))
    ).
