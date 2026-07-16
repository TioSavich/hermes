/** <module> Probability action/deformation pairs
 *
 * First probability-domain seed, grounded in extract-016
 * (`ESM_Chernoff_2011_From`). The productive action treats an interrupted
 * game tree as weighted terminal branches: sum each terminal branch
 * probability by winner, then allocate the stake proportionally. The paired
 * deformation keeps the same terminal endpoints but counts them as if every
 * endpoint were equiprobable.
 */

:- module(probability_action_pairs,
          [ run_probability_action/5,
            probability_action_cluster/2,
            probability_action_vocabulary/2,
            productive_probability_deformation/3,
            probability_action_misconception_hook/3
          ]).

:- use_module(library(lists), [memberchk/2]).


%!  run_probability_action(+Kind, +Paths, +Stake, -Outcome, -Trace) is semidet.
%
%   Execute a probability tree action. Paths is a non-empty list of
%   `terminal(Winner, probability(Numerator, Denominator), EventPath)` terms.
%   Stake is `stake(Number)`.
run_probability_action(terminal_tree_endpoint_probability_sum,
                       Paths,
                       StakeTerm,
                       Outcome,
                       Trace) :-
    valid_terminal_paths(Paths),
    stake_value(StakeTerm, Stake),
    terminal_winners(Paths, Winners),
    weighted_terminal_split(Paths, WeightedSplit),
    stake_allocation(WeightedSplit, Stake, Allocation),
    Outcome = action_outcome(
                  terminal_tree_endpoint_probability_sum,
                  [ classification(productive),
                    cluster(probability_weighted_terminal_tree),
                    automaton_state(sum_weighted_terminal_branch_probabilities),
                    vocabulary([tree_diagram, terminal_branch,
                                terminal_endpoint, stopping_condition,
                                branch_probability, disjoint_outcomes,
                                probability_sum, stake_split,
                                non_equiprobable_terminal_paths]),
                    terminal_winners(Winners),
                    result(stake_split(WeightedSplit)),
                    expected(stake_split(WeightedSplit)),
                    stake_allocation(Allocation),
                    validity(correct),
                    source(extract_review('extract-016-ESM_Chernoff_2011_From'))
                  ]),
    Trace = [ read_terminal_paths(Paths),
              identify_terminal_winners(Winners),
              sum_terminal_probabilities(WeightedSplit),
              allocate_stake(StakeTerm, Allocation)
            ].
run_probability_action(equiprobable_endpoint_counting,
                       Paths,
                       StakeTerm,
                       Outcome,
                       Trace) :-
    valid_terminal_paths(Paths),
    stake_value(StakeTerm, Stake),
    terminal_winners(Paths, Winners),
    weighted_terminal_split(Paths, WeightedSplit),
    endpoint_count_split(Paths, CountSplit, EndpointCounts),
    CountSplit \=@= WeightedSplit,
    stake_allocation(CountSplit, Stake, CountAllocation),
    stake_allocation(WeightedSplit, Stake, ExpectedAllocation),
    Outcome = action_outcome(
                  equiprobable_endpoint_counting,
                  [ classification(deformation),
                    cluster(probability_weighted_terminal_tree),
                    automaton_state(count_terminal_endpoints_as_equiprobable),
                    vocabulary([terminal_endpoint, endpoint_count,
                                equiprobable_endpoint_counting,
                                equal_likelihood_assumption,
                                sample_set, stake_split,
                                lost_branch_probability]),
                    terminal_winners(Winners),
                    endpoint_counts(EndpointCounts),
                    result(stake_split(CountSplit)),
                    expected(stake_split(WeightedSplit)),
                    stake_allocation(CountAllocation),
                    expected_stake_allocation(ExpectedAllocation),
                    validity(incorrect),
                    deformation_of(terminal_tree_endpoint_probability_sum),
                    misconception_family(equiprobability_bias_over_terminal_paths),
                    source(db_row(38939))
                  ]),
    Trace = [ read_terminal_paths(Paths),
              identify_terminal_winners(Winners),
              count_terminal_endpoints(EndpointCounts),
              treat_endpoints_as_equiprobable(CountSplit),
              compare_with_weighted_terminal_sum(WeightedSplit)
            ].


%!  probability_action_cluster(+Kind, -Cluster) is det.
probability_action_cluster(terminal_tree_endpoint_probability_sum,
                           probability_weighted_terminal_tree).
probability_action_cluster(equiprobable_endpoint_counting,
                           probability_weighted_terminal_tree).


%!  probability_action_vocabulary(+Kind, -Vocabulary) is det.
probability_action_vocabulary(terminal_tree_endpoint_probability_sum,
                              [tree_diagram, terminal_branch,
                               terminal_endpoint, stopping_condition,
                               branch_probability, disjoint_outcomes,
                               probability_sum, stake_split,
                               non_equiprobable_terminal_paths]).
probability_action_vocabulary(equiprobable_endpoint_counting,
                              [terminal_endpoint, endpoint_count,
                               equiprobable_endpoint_counting,
                               equal_likelihood_assumption,
                               sample_set, stake_split,
                               lost_branch_probability]).


%!  productive_probability_deformation(+ProductiveKind, +DeformationKind,
%!                                      -Family) is det.
productive_probability_deformation(terminal_tree_endpoint_probability_sum,
                                   equiprobable_endpoint_counting,
                                   equiprobability_bias_over_terminal_paths).


%!  probability_action_misconception_hook(+Outcome, -Family, -Hook) is semidet.
probability_action_misconception_hook(action_outcome(Kind, Fields), Family, Hook) :-
    member(classification(deformation), Fields),
    member(misconception_family(Family), Fields),
    member(deformation_of(ProductiveKind), Fields),
    member(vocabulary(Vocabulary), Fields),
    Hook = action_misconception_hook(
               [ deformation(Kind),
                 deformation_of(ProductiveKind),
                 family(Family),
                 vocabulary(Vocabulary),
                 repair(recover_productive_action(ProductiveKind)),
                 evidence(Fields)
               ]).
probability_action_misconception_hook(action_outcome(Kind, Fields), Family, Hook) :-
    member(classification(productive), Fields),
    productive_probability_deformation(Kind, DeformationKind, Family),
    member(vocabulary(Vocabulary), Fields),
    Hook = action_misconception_hook(
               [ productive_action(Kind),
                 nearby_deformation(DeformationKind),
                 family(Family),
                 vocabulary(Vocabulary),
                 monitoring_focus(preserve_terminal_branch_weights(Kind)),
                 evidence(Fields)
               ]).


valid_terminal_paths([Path|Rest]) :-
    valid_terminal_path(Path),
    valid_terminal_path_tail(Rest).


valid_terminal_path_tail([]).
valid_terminal_path_tail([Path|Rest]) :-
    valid_terminal_path(Path),
    valid_terminal_path_tail(Rest).


valid_terminal_path(terminal(Winner, probability(Numerator, Denominator), Events)) :-
    atom(Winner),
    integer(Numerator),
    integer(Denominator),
    Numerator > 0,
    Denominator > 0,
    is_list(Events).


stake_value(stake(Stake), Stake) :-
    number(Stake),
    Stake > 0.


terminal_winners(Paths, Winners) :-
    terminal_winners(Paths, [], Reversed),
    reverse(Reversed, Winners).


terminal_winners([], Winners, Winners).
terminal_winners([terminal(Winner, _Probability, _Events)|Rest], Seen, Winners) :-
    (   memberchk(Winner, Seen)
    ->  Next = Seen
    ;   Next = [Winner|Seen]
    ),
    terminal_winners(Rest, Next, Winners).


weighted_terminal_split(Paths, Split) :-
    terminal_winners(Paths, Winners),
    findall(Winner-Rational,
            ( member(Winner, Winners),
              sum_winner_probability(Paths, Winner, Rational)
            ),
            Split).


sum_winner_probability(Paths, Winner, Rational) :-
    sum_winner_probability(Paths, Winner, rational(0, 1), Rational).


sum_winner_probability([], _Winner, Rational, Rational).
sum_winner_probability([terminal(Winner, probability(Numerator, Denominator), _Events)|Rest],
                       TargetWinner,
                       Acc,
                       Rational) :-
    (   Winner == TargetWinner
    ->  add_rational(Acc, rational(Numerator, Denominator), Next)
    ;   Next = Acc
    ),
    sum_winner_probability(Rest, TargetWinner, Next, Rational).


endpoint_count_split(Paths, Split, Counts) :-
    terminal_winners(Paths, Winners),
    length(Paths, Total),
    Total > 0,
    findall(Winner-Count,
            ( member(Winner, Winners),
              count_winner_endpoints(Paths, Winner, Count)
            ),
            Counts),
    findall(Winner-Rational,
            ( member(Winner-Count, Counts),
              reduce_rational(Count, Total, Rational)
            ),
            Split).


count_winner_endpoints(Paths, Winner, Count) :-
    count_winner_endpoints(Paths, Winner, 0, Count).


count_winner_endpoints([], _Winner, Count, Count).
count_winner_endpoints([terminal(Winner, _Probability, _Events)|Rest],
                       TargetWinner,
                       Acc,
                       Count) :-
    (   Winner == TargetWinner
    ->  Next is Acc + 1
    ;   Next = Acc
    ),
    count_winner_endpoints(Rest, TargetWinner, Next, Count).


stake_allocation([], _Stake, []).
stake_allocation([Winner-rational(Numerator, Denominator)|Rest],
                 Stake,
                 [Winner-francs(Share)|Allocations]) :-
    Share0 is Stake * Numerator / Denominator,
    Share is round(Share0 * 100) / 100,
    stake_allocation(Rest, Stake, Allocations).


add_rational(rational(LeftNumerator, LeftDenominator),
             rational(RightNumerator, RightDenominator),
             Rational) :-
    Numerator is LeftNumerator * RightDenominator
                 + RightNumerator * LeftDenominator,
    Denominator is LeftDenominator * RightDenominator,
    reduce_rational(Numerator, Denominator, Rational).


reduce_rational(0, _Denominator, rational(0, 1)) :- !.
reduce_rational(Numerator, Denominator, rational(ReducedNumerator, ReducedDenominator)) :-
    Denominator > 0,
    Divisor is gcd(abs(Numerator), Denominator),
    ReducedNumerator is Numerator // Divisor,
    ReducedDenominator is Denominator // Divisor.
