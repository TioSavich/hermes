/** <module> Standard 1.CA.1 — Addition/subtraction fluency within 20
 *
 * Indiana: 1.CA.1 — "Demonstrate fluency with addition facts and the
 *          corresponding subtraction facts within 20. Use strategies
 *          such as counting on; making ten; decomposing a number
 *          leading to a 10; using the relationship between addition
 *          and subtraction; and creating equivalent but easier or
 *          known sums." (E)
 * CCSS:    1.OA.C.6 — "Add and subtract within 20, demonstrating
 *                      fluency for addition and subtraction within 10."
 *
 * VPV MAPPING:
 *   V  (target vocabulary): addition/subtraction facts within 20,
 *      "makes ten", "doubles", "near doubles", "fact family"
 *   P  (practices): counting-on; making ten (8+6 = 8+2+4 = 10+4 = 14);
 *      decomposing to ten (13-4 = 13-3-1 = 10-1 = 9);
 *      fact families (8+4=12 → 12-8=4); doubles/near-doubles
 *   V' (metavocabulary): "what strategy did you use?", "is there
 *      a faster way?", "how does knowing 8+2=10 help with 8+6?"
 *
 * CONNECTION TO EXISTING AUTOMATA:
 *   This standard names the strategies that the prolog/Prolog/math/
 *   automata formalize at a more general level:
 *   - counting_on → sar_add_counting_on.pl
 *   - making_ten  → related to sar_add_rmb.pl (round-make-base)
 *   - decomposing → sar_sub_decomposition.pl
 *   - fact_family → sar_sub_cobo_missing_addend.pl
 *
 * BRANDOM CONNECTION: The transition from "I can add 8+6" (by
 *   counting all) to "I can add 8+6 by making ten" is a genuine
 *   algorithmic elaboration. The making-ten strategy deploys the
 *   place-value vocabulary (K.NS.7, 1.NS.2) within the addition
 *   practice. The learner who makes ten is using a STRONGER
 *   vocabulary than one who counts all — they see 8+6 as
 *   8+(2+4) = (8+2)+4 = 10+4 = 14. Each rewrite step is a
 *   material inference licensed by the practices mastered so far.
 *
 * CRISIS CONNECTION: The efficiency gap drives strategy adoption:
 *   - counting_all: O(A+B) — adequate for small numbers
 *   - counting_on: O(B) — halves the work
 *   - making_ten: O(1) plus decomposition — near-constant for facts
 *   When counting_on is too slow (8+6 = 14 steps from 0), the
 *   system enters crisis and must find a better strategy.
 *
 * BOUNDARIES:
 *   - This is the closed-world finite 1.CA.1 strategy case for supplied
 *     grounded recollections. Each strategy records the finite grounded
 *     arithmetic operations that justify the result.
 *   - The Indiana classroom surface is addition and subtraction facts within
 *     20. The checker can compute finite recollection results outside that
 *     range, but witnesses mark whether the result is inside the 1.CA.1 bound.
 *   - Strategy selection, ORR crisis routing, and fluency timing are conceptual
 *     dependencies here. This module records strategy proofs; it does not
 *     execute the ORR cycle or model elapsed time.
 */

:- module(standard_1_ca_1, [
    add_counting_on/3,     % +A, +B, -Sum
    add_counting_on_witness/4, % +A, +B, -Sum, -Witness
    add_making_ten/3,      % +A, +B, -Sum
    add_making_ten_witness/4, % +A, +B, -Sum, -Witness
    sub_decompose_to_ten/3,% +Minuend, +Subtrahend, -Difference
    sub_decompose_to_ten_witness/4, % +Minuend, +Subtrahend, -Difference, -Witness
    fact_family/4,         % +A, +B, -Sum, -Facts
    fact_family_witness/5, % +A, +B, -Sum, -Facts, -Witness
    add_doubles_near/3,    % +A, +B, -Sum
    add_doubles_near_witness/4 % +A, +B, -Sum, -Witness
]).

:- use_module(formalization(grounded_arithmetic), [
    zero/1,
    successor/2,
    predecessor/2,
    equal_to/2,
    add_grounded/3,
    subtract_grounded/3,
    integer_to_recollection/2,
    recollection_to_integer/2,
    incur_cost/1
]).

% ============================================================
% Strategy 1: Counting on (from K.NS.1, deployed for addition)
% ============================================================

%!  add_counting_on(+A, +B, -Sum) is det.
%
%   Add A + B by counting on B times from A.
%   Cost: O(B) successor operations.
%   This is K.NS.1's count_on_from applied to addition.

add_counting_on(A, B, Sum) :-
    add_counting_on_witness(A, B, Sum, _).

%!  add_counting_on_witness(+A, +B, -Sum, -Witness) is det.
%
%   Witness-bearing counting-on strategy. The proof records each successor
%   step from the first addend while the second addend is counted down.

add_counting_on_witness(A, B, Sum, Witness) :-
    incur_cost(inference),
    count_on_trace_(A, B, Sum, Trace),
    counting_on_witness(A, B, Sum, Trace, Witness).

count_on_trace_(Current, Remaining, Sum, [Step|Rest]) :-
    count_on_step_(Current, Remaining, Step, NextCurrent, NextRemaining, Done),
    (   Done = done
    ->  Sum = Current,
        Rest = []
    ;   count_on_trace_(NextCurrent, NextRemaining, Sum, Rest)
    ).

count_on_step_(Current, Remaining, Step, _NextCurrent, _NextRemaining, done) :-
    zero(Zero),
    equal_to(Remaining, Zero), !,
    recollection_to_integer(Current, CurrentCount),
    Step = _{ kind: standard_1_ca_1_counting_on_terminal,
              current: Current,
              current_count: CurrentCount,
              remaining: Remaining,
              remaining_count: 0 }.
count_on_step_(Current, Remaining, Step, Next, NewRemaining, more) :-
    successor(Current, Next),
    predecessor(Remaining, NewRemaining),
    recollection_to_integer(Current, CurrentCount),
    recollection_to_integer(Remaining, RemainingCount),
    recollection_to_integer(Next, NextCount),
    recollection_to_integer(NewRemaining, NewRemainingCount),
    Step = _{ kind: standard_1_ca_1_counting_on_step,
              current: Current,
              current_count: CurrentCount,
              remaining: Remaining,
              remaining_count: RemainingCount,
              next: Next,
              next_count: NextCount,
              new_remaining: NewRemaining,
              new_remaining_count: NewRemainingCount }.


% ============================================================
% Strategy 2: Making ten (8+6 = 8+2+4 = 10+4 = 14)
% ============================================================

%!  add_making_ten(+A, +B, -Sum) is semidet.
%
%   Add A + B by first completing A to 10, then adding the rest.
%   Requires: A < 10, A + B >= 10.
%
%   Steps:
%   1. Find complement: need = 10 - A
%   2. Split B: B = need + rest
%   3. Sum = 10 + rest
%
%   This deploys K.CA.3 (complement to 10) and K.NS.7 (place value)
%   within the addition practice.

add_making_ten(A, B, Sum) :-
    add_making_ten_witness(A, B, Sum, _).

%!  add_making_ten_witness(+A, +B, -Sum, -Witness) is semidet.
%
%   Witness-bearing making-ten strategy. The proof records the complement
%   needed to complete ten, the rest of the second addend, and the final
%   grounded addition of ten plus the rest.

add_making_ten_witness(A, B, Sum, Witness) :-
    incur_cost(inference),
    integer_to_recollection(10, Ten),
    subtract_grounded(Ten, A, Need),
    subtract_grounded(B, Need, Rest),
    add_grounded(Ten, Rest, Sum),
    making_ten_witness(A, B, Sum, Ten, Need, Rest, Witness).


% ============================================================
% Strategy 3: Decompose to ten (13-4 = 13-3-1 = 10-1 = 9)
% ============================================================

%!  sub_decompose_to_ten(+Minuend, +Subtrahend, -Difference) is semidet.
%
%   Subtract by first subtracting down to 10, then subtracting
%   the rest. Useful when Minuend > 10 > Minuend - Subtrahend.
%
%   Steps:
%   1. Find how far Minuend is above 10: above = Minuend - 10
%   2. Split Subtrahend: Subtrahend = above + rest
%   3. Difference = 10 - rest

sub_decompose_to_ten(Minuend, Subtrahend, Difference) :-
    sub_decompose_to_ten_witness(Minuend, Subtrahend, Difference, _).

%!  sub_decompose_to_ten_witness(+Minuend, +Subtrahend, -Difference, -Witness) is semidet.
%
%   Witness-bearing decompose-to-ten subtraction. The proof records how far the
%   minuend is above ten, the remaining part of the subtrahend, and the final
%   subtraction from ten.

sub_decompose_to_ten_witness(Minuend, Subtrahend, Difference, Witness) :-
    incur_cost(inference),
    integer_to_recollection(10, Ten),
    subtract_grounded(Minuend, Ten, Above),
    subtract_grounded(Subtrahend, Above, Rest),
    subtract_grounded(Ten, Rest, Difference),
    decompose_to_ten_witness(Minuend,
                             Subtrahend,
                             Difference,
                             Ten,
                             Above,
                             Rest,
                             Witness).


% ============================================================
% Strategy 4: Fact families (relationship between add/sub)
% ============================================================

%!  fact_family(+A, +B, -Sum, -Facts) is det.
%
%   Given two addends, produce the complete fact family:
%   A+B=Sum, B+A=Sum, Sum-A=B, Sum-B=A
%
%   This models the "relationship between addition and subtraction"
%   strategy: knowing 8+4=12 means knowing 12-8=4.

fact_family(A, B, Sum, Facts) :-
    fact_family_witness(A, B, Sum, Facts, _).

%!  fact_family_witness(+A, +B, -Sum, -Facts, -Witness) is det.
%
%   Witness-bearing fact-family strategy. The proof records the grounded sum
%   and the four inverse addition/subtraction facts projected from it.

fact_family_witness(A, B, Sum, Facts, Witness) :-
    incur_cost(inference),
    add_grounded(A, B, Sum),
    Facts = [
        add(A, B, Sum),
        add(B, A, Sum),
        sub(Sum, A, B),
        sub(Sum, B, A)
    ],
    fact_family_witness_(A, B, Sum, Facts, Witness).


% ============================================================
% Strategy 5: Doubles and near-doubles
% ============================================================

%!  add_doubles_near(+A, +B, -Sum) is det.
%
%   Add using doubles/near-doubles strategy:
%   If A = B: Sum = A + A (double)
%   If |A - B| = 1: use the double of the smaller, add 1
%
%   Falls back to counting-on if not a doubles case.

add_doubles_near(A, B, Sum) :-
    add_doubles_near_witness(A, B, Sum, _).

%!  add_doubles_near_witness(+A, +B, -Sum, -Witness) is det.
%
%   Witness-bearing doubles/near-doubles strategy. The witness records which
%   strategy branch was used and delegates to counting-on when no doubles
%   relation applies.

add_doubles_near_witness(A, B, Sum, Witness) :-
    incur_cost(inference),
    integer_to_recollection(1, One),
    doubles_case(A, B, One, Sum, StrategyCase, Evidence),
    doubles_near_witness(A, B, Sum, StrategyCase, Evidence, Witness).

doubles_case(A, B, _One, Sum, doubles, Evidence) :-
    equal_to(A, B), !,
    add_grounded(A, A, Sum),
    recollection_to_integer(A, ACount),
    recollection_to_integer(Sum, SumCount),
    Evidence = _{ kind: standard_1_ca_1_doubles_case,
                  relation: equal_to(A, B),
                  double_of_count: ACount,
                  sum_count: SumCount }.
doubles_case(A, B, One, Sum, near_double_b_one_more, Evidence) :-
    subtract_grounded(B, A, Diff),
    equal_to(Diff, One), !,
    add_grounded(A, A, Double),
    successor(Double, Sum),
    near_double_evidence(A, B, Diff, Double, Sum, Evidence).
doubles_case(A, B, One, Sum, near_double_a_one_more, Evidence) :-
    subtract_grounded(A, B, Diff),
    equal_to(Diff, One), !,
    add_grounded(B, B, Double),
    successor(Double, Sum),
    near_double_evidence(B, A, Diff, Double, Sum, Evidence).
doubles_case(A, B, _One, Sum, fallback_counting_on, Evidence) :-
    add_counting_on_witness(A, B, Sum, CountingWitness),
    Evidence = _{ kind: standard_1_ca_1_doubles_fallback,
                  reason: not_double_or_near_double,
                  counting_on_witness: CountingWitness }.

near_double_evidence(Smaller, Larger, Diff, Double, Sum, Evidence) :-
    recollection_to_integer(Smaller, SmallerCount),
    recollection_to_integer(Larger, LargerCount),
    recollection_to_integer(Diff, DiffCount),
    recollection_to_integer(Double, DoubleCount),
    recollection_to_integer(Sum, SumCount),
    Evidence = _{ kind: standard_1_ca_1_near_double_case,
                  smaller: Smaller,
                  smaller_count: SmallerCount,
                  larger: Larger,
                  larger_count: LargerCount,
                  difference_count: DiffCount,
                  double: Double,
                  double_count: DoubleCount,
                  sum_count: SumCount,
                  derivation: double_smaller_add_one }.

counting_on_witness(A,
                    B,
                    Sum,
                    Trace,
                    WitnessDict320) :-
    witness_dict:witness_dict(standard_1_ca_1_counting_on, closed_world_finite_standard_1_ca_1_within_20,
                              _{standard: in_1_ca_1,
                       source_predicate: add_counting_on/3,
                       addends: _{a: A, b: B, a_count: ACount, b_count: BCount},
                       sum: Sum,
                       sum_count: SumCount,
                       trace: Trace,
                       trace_length: TraceLength,
                       step_count: StepCount,
                       derivation: repeated_successor_from_first_addend,
                       boundary: supplied_grounded_recollections_within_strategy_fact_range,
                       bound_status: BoundStatus }, WitnessDict320),
    recollection_to_integer(A, ACount),
    recollection_to_integer(B, BCount),
    recollection_to_integer(Sum, SumCount),
    length(Trace, TraceLength),
    StepCount is TraceLength - 1,
    strategy_bound_status(ACount, BCount, SumCount, BoundStatus).

making_ten_witness(A,
                   B,
                   Sum,
                   Ten,
                   Need,
                   Rest,
                   WitnessDict346) :-
    witness_dict:witness_dict(standard_1_ca_1_making_ten, closed_world_finite_standard_1_ca_1_within_20,
                              _{standard: in_1_ca_1,
                      source_predicate: add_making_ten/3,
                      addends: _{a: A, b: B, a_count: ACount, b_count: BCount},
                      sum: Sum,
                      sum_count: SumCount,
                      ten: Ten,
                      ten_count: 10,
                      need: Need,
                      need_count: NeedCount,
                      rest: Rest,
                      rest_count: RestCount,
                      steps: [subtract_grounded(Ten, A, Need),
                              subtract_grounded(B, Need, Rest),
                              add_grounded(Ten, Rest, Sum)],
                      derivation: split_second_addend_to_complete_ten,
                      boundary: supplied_grounded_recollections_within_strategy_fact_range,
                      bound_status: BoundStatus }, WitnessDict346),
    recollection_to_integer(A, ACount),
    recollection_to_integer(B, BCount),
    recollection_to_integer(Sum, SumCount),
    recollection_to_integer(Need, NeedCount),
    recollection_to_integer(Rest, RestCount),
    strategy_bound_status(ACount, BCount, SumCount, BoundStatus).

decompose_to_ten_witness(Minuend,
                         Subtrahend,
                         Difference,
                         Ten,
                         Above,
                         Rest,
                         WitnessDict378) :-
    witness_dict:witness_dict(standard_1_ca_1_sub_decompose_to_ten, closed_world_finite_standard_1_ca_1_within_20,
                              _{standard: in_1_ca_1,
                            source_predicate: sub_decompose_to_ten/3,
                            minuend: Minuend,
                            minuend_count: MinuendCount,
                            subtrahend: Subtrahend,
                            subtrahend_count: SubtrahendCount,
                            difference: Difference,
                            difference_count: DifferenceCount,
                            ten: Ten,
                            ten_count: 10,
                            above_ten: Above,
                            above_ten_count: AboveCount,
                            rest: Rest,
                            rest_count: RestCount,
                            steps: [subtract_grounded(Minuend, Ten, Above),
                                    subtract_grounded(Subtrahend, Above, Rest),
                                    subtract_grounded(Ten, Rest, Difference)],
                            derivation: split_subtrahend_to_land_on_ten,
                            boundary: supplied_grounded_recollections_within_strategy_fact_range,
                            bound_status: BoundStatus }, WitnessDict378),
    recollection_to_integer(Minuend, MinuendCount),
    recollection_to_integer(Subtrahend, SubtrahendCount),
    recollection_to_integer(Difference, DifferenceCount),
    recollection_to_integer(Above, AboveCount),
    recollection_to_integer(Rest, RestCount),
    strategy_bound_status(SubtrahendCount, DifferenceCount, MinuendCount, BoundStatus).

fact_family_witness_(A,
                     B,
                     Sum,
                     Facts,
                     WitnessDict411) :-
    witness_dict:witness_dict(standard_1_ca_1_fact_family, closed_world_finite_standard_1_ca_1_within_20,
                              _{standard: in_1_ca_1,
                        source_predicate: fact_family/4,
                        addends: _{a: A, b: B, a_count: ACount, b_count: BCount},
                        sum: Sum,
                        sum_count: SumCount,
                        facts: Facts,
                        facts_count: FactsCount,
                        derivation: project_inverse_addition_subtraction_facts,
                        boundary: supplied_grounded_recollections_within_strategy_fact_range,
                        bound_status: BoundStatus }, WitnessDict411),
    recollection_to_integer(A, ACount),
    recollection_to_integer(B, BCount),
    recollection_to_integer(Sum, SumCount),
    length(Facts, FactsCount),
    strategy_bound_status(ACount, BCount, SumCount, BoundStatus).

doubles_near_witness(A,
                     B,
                     Sum,
                     StrategyCase,
                     Evidence,
                     Witness) :-
    witness_dict:witness_dict(standard_1_ca_1_doubles_near, closed_world_finite_standard_1_ca_1_within_20,
                              _{standard: in_1_ca_1,
                  source_predicate: add_doubles_near/3,
                  addends: _{a: A, b: B, a_count: ACount, b_count: BCount},
                  sum: Sum,
                  sum_count: SumCount,
                  strategy_case: StrategyCase,
                  evidence: Evidence,
                  derivation: double_near_double_or_counting_on_fallback,
                  boundary: supplied_grounded_recollections_within_strategy_fact_range,
                  bound_status: BoundStatus }, WitnessDict439),
    recollection_to_integer(A, ACount),
    recollection_to_integer(B, BCount),
    recollection_to_integer(Sum, SumCount),
    strategy_bound_status(ACount, BCount, SumCount, BoundStatus),
    Witness0 = WitnessDict439,
    add_doubles_fallback_projection(StrategyCase, Evidence, Witness0, Witness).

add_doubles_fallback_projection(fallback_counting_on, Evidence, Witness0, Witness) :-
    get_dict(counting_on_witness, Evidence, CountingWitness),
    Witness = Witness0.put(fallback_witness, CountingWitness).
add_doubles_fallback_projection(StrategyCase, _Evidence, Witness, Witness) :-
    StrategyCase \= fallback_counting_on.

strategy_bound_status(A, B, Result, within_indiana_1_ca_1_bound) :-
    A >= 0,
    B >= 0,
    Result >= 0,
    Result =< 20,
    !.
strategy_bound_status(A, B, Result, outside_indiana_1_ca_1_bound(A, B, Result)).
