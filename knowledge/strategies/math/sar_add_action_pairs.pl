/** <module> Additive strategy/deformation action pairs
 *
 * This module starts the "actions over vocabularies" layer for monitoring
 * work. It does not replace the existing SAR automata. Instead, it elaborates
 * from them by naming productive actions and nearby deformations as executable
 * state traces.
 *
 * First slice:
 *   - counting on from the larger addend;
 *   - the count-all efficiency deformation;
 *   - making ten with a split leftover;
 *   - the dropped-leftover deformation;
 *   - rearranging to make a base;
 *   - the unbalanced-compensation deformation;
 *   - chunking by base and ones;
 *   - the dropped-ones-chunk deformation;
 *   - rounding then adjusting;
 *   - the rounding-without-adjusting deformation;
 *   - column addition with carrying;
 *   - omitted-carry, appended-partial-sums, and wrong-carry deformations;
 *   - known and derived addition facts;
 *   - counting fallback and rote derived-fact deformations.
 */

:- module(sar_add_action_pairs,
          [ run_additive_action/5,
            action_cluster/2,
            action_vocabulary/2,
            productive_deformation/3,
            action_misconception_hook/3
          ]).

:- use_module(formalization(grounded_arithmetic),
              [ add_grounded/3,
                subtract_grounded/3,
                multiply_grounded/3,
                smaller_than/2,
                greater_than/2,
                successor/2,
                predecessor/2,
                integer_to_recollection/2,
                recollection_to_integer/2,
                incur_cost/1
              ]).
:- use_module(formalization(grounded_utils),
              [ base_decompose_grounded/4,
                is_zero_grounded/1
              ]).
:- use_module(math(sar_add_rmb), [run_rmb/4]).
:- use_module(math(sar_add_chunking), [run_chunking/4]).
:- use_module(math(sar_add_counting_on), [run_counting_on/4]).
:- use_module(math(sar_add_rounding), [run_rounding/4]).
:- use_module(math(integer_helpers), [add_ints/3, subtract_ints/3]).

% DPDA kernel: forward-only tick automaton with carry across ones/tens/hundreds.
% Provides the place-value implementation surface that strategic count-on
% shells (sar_add_counting_on, sar_add_cobo) operate on top of.
:- use_module(math(counting2), [run_counter/2]).
:- use_module(math(cgi_base), [current_cgi_base/1]).


%!  run_additive_action(+Kind, +A, +B, -Outcome, -Trace) is semidet.
%
%   Execute a productive or deformed additive action automaton.
run_additive_action(count_on_from_larger, A, B, Outcome, Trace) :-
    larger_smaller(A, B, Start, Count),
    run_counting_on(Start, Count, ExistingResult, ExistingTrace),
    count_on_values(Start, Count, TickValues),
    add_ints(A, B, Expected),
    Outcome = action_outcome(
                  count_on_from_larger,
                  [ classification(productive),
                    cluster(additive_strategy_fluency),
                    automaton_state(count_on),
                    vocabulary([start_number, counted_addend, successor_tick, cardinal_sum]),
                    result(ExistingResult),
                    expected(Expected),
                    validity(correct),
                    start_number(Start),
                    counted_addend(Count),
                    tick_values(TickValues),
                    elaborates(sar_add_counting_on:run_counting_on/4),
                    evidence(existing_trace(ExistingTrace))
                  ]),
    Trace = [ choose_larger_addend_as_start(Start),
              hold_other_addend_as_count(Count),
              iterate_successor_ticks(TickValues),
              name_last_tick_as_sum(ExistingResult)
            ].
run_additive_action(count_all_when_count_on_available, A, B, Outcome, Trace) :-
    larger_smaller(A, B, Start, Count),
    add_ints(A, B, Result),
    count_on_values(0, A, FirstAddendTicks),
    count_on_values(A, B, AllTicks),
    append(FirstAddendTicks, AllTicks, CountAllTicks),
    Outcome = action_outcome(
                  count_all_when_count_on_available,
                  [ classification(deformation),
                    cluster(additive_strategy_fluency),
                    automaton_state(count_on),
                    vocabulary([counted_collection, successor_tick, cardinal_sum, composite_start]),
                    result(Result),
                    expected(Result),
                    validity(correct_but_inefficient),
                    missed_start_number(Start),
                    counted_addend(Count),
                    tick_values(CountAllTicks),
                    deformation_of(count_on_from_larger),
                    misconception_family(count_all_when_count_on_available)
                  ]),
    Trace = [ reset_to_zero_instead_of_starting_from_composite(Start),
              count_first_addend_from_zero(A, FirstAddendTicks),
              count_second_addend_from_first_total(B, AllTicks),
              preserve_result_but_lose_count_on_efficiency(Result)
            ].
run_additive_action(make_ten_split_leftover, A, B, Outcome, Trace) :-
    make_base_components(A, B, Components),
    Components = make_base_components(Larger, Smaller, Base, TargetBase, K, _LargerMadeBase, SmallerRemainder),
    K > 0,
    add_ints(TargetBase, SmallerRemainder, Result),
    add_ints(A, B, Expected),
    Outcome = action_outcome(
                  make_ten_split_leftover,
                  [ classification(productive),
                    cluster(additive_strategy_fluency),
                    automaton_state(make_ten),
                    vocabulary([addend, ten, split, needed_part, leftover, conservation]),
                    result(Result),
                    expected(Expected),
                    validity(correct),
                    components(Components),
                    elaborates(sar_add_rmb:run_rmb/4)
                  ]),
    Trace = [ choose_addend_near_base(Larger, Base, TargetBase),
              split_other_addend(Smaller, needed_part(K), leftover(SmallerRemainder)),
              make_base(TargetBase),
              add_leftover_after_base(SmallerRemainder, Result),
              preserve_total_by_using_both_split_parts(Result)
            ].
run_additive_action(make_ten_drop_leftover, A, B, Outcome, Trace) :-
    make_base_components(A, B, Components),
    Components = make_base_components(Larger, Smaller, Base, TargetBase, K, _LargerMadeBase, SmallerRemainder),
    K > 0,
    Result = TargetBase,
    add_ints(A, B, Expected),
    Outcome = action_outcome(
                  make_ten_drop_leftover,
                  [ classification(deformation),
                    cluster(additive_strategy_fluency),
                    automaton_state(make_ten),
                    vocabulary([addend, ten, split, needed_part, leftover, conservation]),
                    result(Result),
                    expected(Expected),
                    validity(incorrect),
                    components(Components),
                    deformation_of(make_ten_split_leftover),
                    misconception_family(dropped_leftover_after_make_ten)
                  ]),
    Trace = [ choose_addend_near_base(Larger, Base, TargetBase),
              split_other_addend(Smaller, needed_part(K), leftover(SmallerRemainder)),
              make_base(TargetBase),
              drop_leftover_after_making_base(SmallerRemainder),
              lose_total_conservation(expected(Expected), produced(Result))
            ].
run_additive_action(make_base_transfer, A, B, Outcome, Trace) :-
    run_rmb(A, B, ExistingResult, ExistingTrace),
    make_base_components(A, B, Components),
    Components = make_base_components(Larger, Smaller, Base, TargetBase, K, LargerMadeBase, SmallerRemainder),
    add_ints(LargerMadeBase, SmallerRemainder, Result),
    Outcome = action_outcome(
                  make_base_transfer,
                  [ classification(productive),
                    cluster(additive_strategy_fluency),
                    automaton_state(make_ten),
                    vocabulary([addend, base, distance_to_base, transfer, remainder, conservation]),
                    result(Result),
                    expected(ExistingResult),
                    validity(correct),
                    components(Components),
                    elaborates(sar_add_rmb:run_rmb/4),
                    evidence(existing_trace(ExistingTrace))
                  ]),
    Trace = [ order_addends(larger(Larger), smaller(Smaller)),
              identify_target_base(Larger, Base, TargetBase),
              count_distance_to_base(Larger, TargetBase, K),
              transfer_from_smaller_to_larger(K, Smaller, SmallerRemainder),
              preserve_total_by_balanced_transfer(LargerMadeBase, SmallerRemainder, Result)
            ].
run_additive_action(unbalanced_make_base_compensation, A, B, Outcome, Trace) :-
    make_base_components(A, B, Components),
    Components = make_base_components(Larger, Smaller, Base, TargetBase, K, LargerMadeBase, _SmallerRemainder),
    add_ints(A, B, Expected),
    add_ints(LargerMadeBase, Smaller, Result),
    Outcome = action_outcome(
                  unbalanced_make_base_compensation,
                  [ classification(deformation),
                    cluster(additive_strategy_fluency),
                    automaton_state(compensation),
                    vocabulary([addend, base, distance_to_base, compensation, conservation]),
                    result(Result),
                    expected(Expected),
                    validity(incorrect),
                    components(Components),
                    deformation_of(make_base_transfer),
                    misconception_family(compensation_without_conservation)
                  ]),
    Trace = [ order_addends(larger(Larger), smaller(Smaller)),
              identify_target_base(Larger, Base, TargetBase),
              count_distance_to_base(Larger, TargetBase, K),
              add_compensation_to_larger(K, Larger, LargerMadeBase),
              leave_other_addend_unchanged(Smaller),
              lose_total_conservation(expected(Expected), produced(Result))
            ].
run_additive_action(base_ones_chunking, A, B, Outcome, Trace) :-
    run_chunking(A, B, ExistingResult, ExistingTrace),
    chunk_components(A, B, Components),
    Components = chunk_components(Base, BaseChunk, OnesChunk, AfterBaseChunk, Result),
    Outcome = action_outcome(
                  base_ones_chunking,
                  [ classification(productive),
                    cluster(additive_strategy_fluency),
                    automaton_state(decompose_recompose),
                    vocabulary([addend, base_chunk, ones_chunk, running_sum, remainder]),
                    result(Result),
                    expected(ExistingResult),
                    validity(correct),
                    components(Components),
                    elaborates(sar_add_chunking:run_chunking/4),
                    evidence(existing_trace(ExistingTrace))
                  ]),
    Trace = [ decompose_second_addend(B, base(Base), base_chunk(BaseChunk), ones_chunk(OnesChunk)),
              add_base_chunk(A, BaseChunk, AfterBaseChunk),
              add_ones_chunk(AfterBaseChunk, OnesChunk, Result),
              preserve_all_decomposed_parts(Result)
            ].
run_additive_action(dropped_ones_chunk, A, B, Outcome, Trace) :-
    chunk_components(A, B, Components),
    Components = chunk_components(Base, BaseChunk, OnesChunk, AfterBaseChunk, _CorrectResult),
    add_ints(A, B, Expected),
    Result = AfterBaseChunk,
    Outcome = action_outcome(
                  dropped_ones_chunk,
                  [ classification(deformation),
                    cluster(additive_strategy_fluency),
                    automaton_state(decompose_recompose),
                    vocabulary([addend, base_chunk, ones_chunk, running_sum, remainder]),
                    result(Result),
                    expected(Expected),
                    validity(incorrect),
                    components(Components),
                    deformation_of(base_ones_chunking),
                    misconception_family(dropped_remainder_chunk)
                  ]),
    Trace = [ decompose_second_addend(B, base(Base), base_chunk(BaseChunk), ones_chunk(OnesChunk)),
              add_base_chunk(A, BaseChunk, AfterBaseChunk),
              drop_ones_chunk(OnesChunk),
              lose_decomposed_remainder(expected(Expected), produced(Result))
            ].
run_additive_action(round_then_adjust, A, B, Outcome, Trace) :-
    run_rounding(A, B, ExistingResult, ExistingTrace),
    rounding_components(A, B, Components),
    Components = rounding_components(Target, Other, Base, TargetBase, K, RoundedSum, Result),
    add_ints(A, B, Expected),
    Outcome = action_outcome(
                  round_then_adjust,
                  [ classification(productive),
                    cluster(additive_strategy_fluency),
                    automaton_state(compensation),
                    vocabulary([rounding_target, base, adjustment, temporary_sum, conservation]),
                    result(Result),
                    expected(Expected),
                    validity(correct),
                    components(Components),
                    elaborates(sar_add_rounding:run_rounding/4),
                    evidence(existing_trace(ExistingTrace)),
                    existing_result(ExistingResult)
                  ]),
    Trace = [ choose_rounding_target(Target, Other),
              identify_target_base(Target, Base, TargetBase),
              round_up_by(Target, K, TargetBase),
              add_with_rounded_number(TargetBase, Other, RoundedSum),
              adjust_back_by(K, RoundedSum, Result)
            ].
run_additive_action(round_without_adjusting, A, B, Outcome, Trace) :-
    rounding_components(A, B, Components),
    Components = rounding_components(Target, Other, Base, TargetBase, K, RoundedSum, _Result),
    add_ints(A, B, Expected),
    Result = RoundedSum,
    Outcome = action_outcome(
                  round_without_adjusting,
                  [ classification(deformation),
                    cluster(additive_strategy_fluency),
                    automaton_state(compensation),
                    vocabulary([rounding_target, base, adjustment, temporary_sum, conservation]),
                    result(Result),
                    expected(Expected),
                    validity(incorrect),
                    components(Components),
                    deformation_of(round_then_adjust),
                    misconception_family(rounding_without_compensation)
                  ]),
    Trace = [ choose_rounding_target(Target, Other),
              identify_target_base(Target, Base, TargetBase),
              round_up_by(Target, K, TargetBase),
              add_with_rounded_number(TargetBase, Other, RoundedSum),
              omit_adjustment(K),
              lose_total_conservation(expected(Expected), produced(Result))
            ].
run_additive_action(column_addition_with_carrying, A, B, Outcome, Trace) :-
    column_addition_components(A, B, Components),
    Components = column_addition_components(Base, Columns, PlaceDigits, FinalCarry, Result),
    add_ints(A, B, Expected),
    Outcome = action_outcome(
                  column_addition_with_carrying,
                  [ classification(productive),
                    cluster(additive_column_algorithm),
                    automaton_state(column_addition),
                    vocabulary([vertical_alignment, place_value_column, ones_digit,
                                carry, regroup_ten_ones, next_column, base_ten_conservation]),
                    result(Result),
                    expected(Expected),
                    validity(correct),
                    components(Components)
                  ]),
    Trace = [ align_addends_by_place_value(A, B, base(Base)),
              process_columns_right_to_left(Columns),
              write_place_digits(PlaceDigits),
              carry_final_column_if_needed(FinalCarry),
              compose_column_sum(PlaceDigits, FinalCarry, Result),
              preserve_base_ten_regrouping(Result)
            ].
run_additive_action(drop_carry_to_next_column, A, B, Outcome, Trace) :-
    dropped_carry_components(A, B, Components),
    Components = dropped_carry_components(Base, Columns, PlaceDigits, DroppedCarries, Result),
    DroppedCarries \= [],
    add_ints(A, B, Expected),
    Outcome = action_outcome(
                  drop_carry_to_next_column,
                  [ classification(deformation),
                    cluster(additive_column_algorithm),
                    automaton_state(column_addition),
                    vocabulary([vertical_alignment, place_value_column, carry,
                                regroup_ten_ones, next_column, base_ten_conservation]),
                    result(Result),
                    expected(Expected),
                    validity(incorrect),
                    components(Components),
                    deformation_of(column_addition_with_carrying),
                    misconception_family(omitted_carry_to_next_column)
                  ]),
    Trace = [ align_addends_by_place_value(A, B, base(Base)),
              process_columns_right_to_left(Columns),
              write_place_digits(PlaceDigits),
              discard_generated_carries(DroppedCarries),
              compose_column_sum_without_carry(DroppedCarries, Result),
              lose_base_ten_regrouping(expected(Expected), produced(Result))
            ].
run_additive_action(append_column_sum_without_carrying, A, B, Outcome, Trace) :-
    appended_column_sum_components(A, B, Components),
    Components = appended_column_sum_components(Base, ColumnSums, Result),
    has_multi_digit_column_sum(ColumnSums),
    add_ints(A, B, Expected),
    Outcome = action_outcome(
                  append_column_sum_without_carrying,
                  [ classification(deformation),
                    cluster(additive_column_algorithm),
                    automaton_state(column_addition),
                    vocabulary([vertical_alignment, place_value_column, column_sum,
                                carry, regroup_ten_ones, concatenation_error]),
                    result(Result),
                    expected(Expected),
                    validity(incorrect),
                    components(Components),
                    deformation_of(column_addition_with_carrying),
                    misconception_family(append_partial_sums_without_carrying)
                  ]),
    Trace = [ align_addends_by_place_value(A, B, base(Base)),
              compute_raw_column_sums_without_regrouping(ColumnSums),
              write_full_column_sums_in_place(ColumnSums),
              concatenate_partial_sums(Result),
              lose_base_ten_regrouping(expected(Expected), produced(Result))
            ].
run_additive_action(wrong_carry_amount_to_next_column, A, B, Outcome, Trace) :-
    wrong_carry_components(A, B, Components),
    Components = wrong_carry_components(Base, Columns, PlaceDigits, CarryAdjustments, FinalCarry, Result),
    CarryAdjustments \= [],
    add_ints(A, B, Expected),
    Outcome = action_outcome(
                  wrong_carry_amount_to_next_column,
                  [ classification(deformation),
                    cluster(additive_column_algorithm),
                    automaton_state(column_addition),
                    vocabulary([vertical_alignment, place_value_column, carry,
                                regroup_ten_ones, carry_amount, base_ten_conservation]),
                    result(Result),
                    expected(Expected),
                    validity(incorrect),
                    components(Components),
                    deformation_of(column_addition_with_carrying),
                    misconception_family(incorrect_carry_amount)
                  ]),
    Trace = [ align_addends_by_place_value(A, B, base(Base)),
              process_columns_right_to_left(Columns),
              misread_carry_amount(CarryAdjustments),
              write_place_digits(PlaceDigits),
              carry_final_column_if_needed(FinalCarry),
              lose_base_ten_regrouping(expected(Expected), produced(Result))
            ].
run_additive_action(known_fact_retrieval, A, B, Outcome, Trace) :-
    known_fact_components(A, B, Components),
    Components = known_fact_components(A, B, Result),
    Outcome = action_outcome(
                  known_fact_retrieval,
                  [ classification(productive),
                    cluster(additive_fact_fluency),
                    automaton_state(known_fact),
                    vocabulary([number_combination, known_fact, stored_sum,
                                fact_retrieval, automaticity]),
                    result(Result),
                    expected(Result),
                    validity(correct),
                    components(Components)
                  ]),
    Trace = [ recognize_number_combination(A, B),
              retrieve_stored_sum(known_fact(A, B, Result)),
              state_memorized_sum(Result)
            ].
run_additive_action(count_all_instead_of_known_fact, A, B, Outcome, Trace) :-
    known_fact_components(A, B, Components),
    Components = known_fact_components(A, B, Result),
    count_on_values(0, A, FirstAddendTicks),
    count_on_values(A, B, AllTicks),
    append(FirstAddendTicks, AllTicks, CountAllTicks),
    Outcome = action_outcome(
                  count_all_instead_of_known_fact,
                  [ classification(deformation),
                    cluster(additive_fact_fluency),
                    automaton_state(known_fact),
                    vocabulary([number_combination, known_fact, stored_sum,
                                counting_all, working_memory_load]),
                    result(Result),
                    expected(Result),
                    validity(correct_but_inefficient),
                    components(Components),
                    deformation_of(known_fact_retrieval),
                    misconception_family(procedural_count_when_fact_available)
                  ]),
    Trace = [ recognize_number_combination(A, B),
              fail_to_retrieve_stored_sum(known_fact(A, B, Result)),
              count_all_ticks(CountAllTicks),
              preserve_result_but_lose_fact_fluency(Result)
            ].
run_additive_action(derived_fact_adjustment, A, B, Outcome, Trace) :-
    derived_fact_components(A, B, Components),
    Components = derived_fact_components(Anchor, KnownSum, Difference, Result),
    Outcome = action_outcome(
                  derived_fact_adjustment,
                  [ classification(productive),
                    cluster(additive_fact_fluency),
                    automaton_state(derived_fact),
                    vocabulary([nearby_known_fact, anchor_fact, relation_between_problems,
                                adjustment, derived_sum]),
                    result(Result),
                    expected(Result),
                    validity(correct),
                    components(Components)
                  ]),
    Trace = [ recall_nearby_known_fact(Anchor, KnownSum),
              compare_target_to_anchor(A, B, difference(Difference)),
              adjust_known_sum_by(Difference, KnownSum, Result),
              preserve_problem_relation(Result)
            ].
run_additive_action(rote_derived_fact_rule_misfire, A, B, Outcome, Trace) :-
    rote_derived_fact_components(A, B, Components),
    Components = rote_derived_fact_components(Anchor, KnownSum, CorrectDifference, AppliedDifference, Result),
    add_ints(A, B, Expected),
    Outcome = action_outcome(
                  rote_derived_fact_rule_misfire,
                  [ classification(deformation),
                    cluster(additive_fact_fluency),
                    automaton_state(derived_fact),
                    vocabulary([nearby_known_fact, anchor_fact, verbal_rule,
                                adjustment, relation_between_problems]),
                    result(Result),
                    expected(Expected),
                    validity(incorrect),
                    components(Components),
                    deformation_of(derived_fact_adjustment),
                    misconception_family(rote_derived_fact_rule_misfire)
                  ]),
    Trace = [ recall_nearby_known_fact(Anchor, KnownSum),
              notice_that_numbers_are_near_but_not_how_near(correct_difference(CorrectDifference)),
              apply_verbal_rule_with_wrong_adjustment(AppliedDifference),
              lose_problem_relation(expected(Expected), produced(Result))
            ].


%!  action_cluster(+Kind, -Cluster) is det.
action_cluster(count_on_from_larger, additive_strategy_fluency).
action_cluster(count_all_when_count_on_available, additive_strategy_fluency).
action_cluster(make_ten_split_leftover, additive_strategy_fluency).
action_cluster(make_ten_drop_leftover, additive_strategy_fluency).
action_cluster(make_base_transfer, additive_strategy_fluency).
action_cluster(unbalanced_make_base_compensation, additive_strategy_fluency).
action_cluster(base_ones_chunking, additive_strategy_fluency).
action_cluster(dropped_ones_chunk, additive_strategy_fluency).
action_cluster(round_then_adjust, additive_strategy_fluency).
action_cluster(round_without_adjusting, additive_strategy_fluency).
action_cluster(column_addition_with_carrying, additive_column_algorithm).
action_cluster(drop_carry_to_next_column, additive_column_algorithm).
action_cluster(append_column_sum_without_carrying, additive_column_algorithm).
action_cluster(wrong_carry_amount_to_next_column, additive_column_algorithm).
action_cluster(known_fact_retrieval, additive_fact_fluency).
action_cluster(count_all_instead_of_known_fact, additive_fact_fluency).
action_cluster(derived_fact_adjustment, additive_fact_fluency).
action_cluster(rote_derived_fact_rule_misfire, additive_fact_fluency).


%!  action_vocabulary(+Kind, -Vocabulary) is det.
action_vocabulary(count_on_from_larger,
                  [start_number, counted_addend, successor_tick, cardinal_sum]).
action_vocabulary(count_all_when_count_on_available,
                  [counted_collection, successor_tick, cardinal_sum, composite_start]).
action_vocabulary(make_ten_split_leftover,
                  [addend, ten, split, needed_part, leftover, conservation]).
action_vocabulary(make_ten_drop_leftover,
                  [addend, ten, split, needed_part, leftover, conservation]).
action_vocabulary(make_base_transfer,
                  [addend, base, distance_to_base, transfer, remainder, conservation]).
action_vocabulary(unbalanced_make_base_compensation,
                  [addend, base, distance_to_base, compensation, conservation]).
action_vocabulary(base_ones_chunking,
                  [addend, base_chunk, ones_chunk, running_sum, remainder]).
action_vocabulary(dropped_ones_chunk,
                  [addend, base_chunk, ones_chunk, running_sum, remainder]).
action_vocabulary(round_then_adjust,
                  [rounding_target, base, adjustment, temporary_sum, conservation]).
action_vocabulary(round_without_adjusting,
                  [rounding_target, base, adjustment, temporary_sum, conservation]).
action_vocabulary(column_addition_with_carrying,
                  [vertical_alignment, place_value_column, ones_digit, carry,
                   regroup_ten_ones, next_column, base_ten_conservation]).
action_vocabulary(drop_carry_to_next_column,
                  [vertical_alignment, place_value_column, carry, regroup_ten_ones,
                   next_column, base_ten_conservation]).
action_vocabulary(append_column_sum_without_carrying,
                  [vertical_alignment, place_value_column, column_sum, carry,
                   regroup_ten_ones, concatenation_error]).
action_vocabulary(wrong_carry_amount_to_next_column,
                  [vertical_alignment, place_value_column, carry, regroup_ten_ones,
                   carry_amount, base_ten_conservation]).
action_vocabulary(known_fact_retrieval,
                  [number_combination, known_fact, stored_sum,
                   fact_retrieval, automaticity]).
action_vocabulary(count_all_instead_of_known_fact,
                  [number_combination, known_fact, stored_sum,
                   counting_all, working_memory_load]).
action_vocabulary(derived_fact_adjustment,
                  [nearby_known_fact, anchor_fact, relation_between_problems,
                   adjustment, derived_sum]).
action_vocabulary(rote_derived_fact_rule_misfire,
                  [nearby_known_fact, anchor_fact, verbal_rule,
                   adjustment, relation_between_problems]).


%!  productive_deformation(+ProductiveKind, +DeformationKind, -MisconceptionFamily) is det.
productive_deformation(count_on_from_larger,
                       count_all_when_count_on_available,
                       count_all_when_count_on_available).
productive_deformation(make_ten_split_leftover,
                       make_ten_drop_leftover,
                       dropped_leftover_after_make_ten).
productive_deformation(make_base_transfer,
                       unbalanced_make_base_compensation,
                       compensation_without_conservation).
productive_deformation(base_ones_chunking,
                       dropped_ones_chunk,
                       dropped_remainder_chunk).
productive_deformation(round_then_adjust,
                       round_without_adjusting,
                       rounding_without_compensation).
productive_deformation(column_addition_with_carrying,
                       drop_carry_to_next_column,
                       omitted_carry_to_next_column).
productive_deformation(column_addition_with_carrying,
                       append_column_sum_without_carrying,
                       append_partial_sums_without_carrying).
productive_deformation(column_addition_with_carrying,
                       wrong_carry_amount_to_next_column,
                       incorrect_carry_amount).
productive_deformation(known_fact_retrieval,
                       count_all_instead_of_known_fact,
                       procedural_count_when_fact_available).
productive_deformation(derived_fact_adjustment,
                       rote_derived_fact_rule_misfire,
                       rote_derived_fact_rule_misfire).


%!  action_misconception_hook(+Outcome, -Family, -Hook) is semidet.
action_misconception_hook(action_outcome(Kind, Fields), Family, Hook) :-
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
action_misconception_hook(action_outcome(Kind, Fields), Family, Hook) :-
    member(classification(productive), Fields),
    productive_deformation(Kind, DeformationKind, Family),
    member(vocabulary(Vocabulary), Fields),
    Hook = action_misconception_hook(
               [ productive_action(Kind),
                 nearby_deformation(DeformationKind),
                 family(Family),
                 vocabulary(Vocabulary),
                 monitoring_focus(preserve_action_invariants(Kind)),
                 evidence(Fields)
               ]).


make_base_components(A, B, make_base_components(Larger, Smaller, Base, TargetBase, K, LargerMadeBase, SmallerRemainder)) :-
    larger_smaller(A, B, Larger, Smaller),
    current_cgi_base(Base),
    next_base_target(Larger, Base, TargetBase),
    count_distance(Larger, TargetBase, K),
    add_ints(Larger, K, LargerMadeBase),
    subtract_ints(Smaller, K, SmallerRemainder),
    incur_cost(action_make_base_components).


rounding_components(A, B, rounding_components(Target, Other, Base, TargetBase, K, RoundedSum, Result)) :-
    current_cgi_base(Base),
    rounding_target(A, B, Base, Target, Other),
    next_base_target(Target, Base, TargetBase),
    count_distance(Target, TargetBase, K),
    add_ints(TargetBase, Other, RoundedSum),
    subtract_ints(RoundedSum, K, Result),
    incur_cost(action_rounding_components).


rounding_target(A, B, Base, A, B) :-
    integer_to_recollection(A, RecA),
    integer_to_recollection(B, RecB),
    integer_to_recollection(Base, RecBase),
    base_decompose_grounded(RecA, RecBase, _ABases, ARemainder),
    base_decompose_grounded(RecB, RecBase, _BBases, BRemainder),
    \+ smaller_than(ARemainder, BRemainder),
    !.
rounding_target(A, B, _Base, B, A).


larger_smaller(A, B, A, B) :-
    integer_to_recollection(A, RecA),
    integer_to_recollection(B, RecB),
    greater_than(RecA, RecB),
    !.
larger_smaller(A, B, B, A).


next_base_target(N, Base, TargetBase) :-
    integer_to_recollection(N, RecN),
    integer_to_recollection(Base, RecBase),
    base_decompose_grounded(RecN, RecBase, RecBases, RecRemainder),
    (   is_zero_grounded(RecRemainder),
        \+ is_zero_grounded(RecN)
    ->  TargetBase = N
    ;   successor(RecBases, RecBasesPlusOne),
        multiply_grounded(RecBasesPlusOne, RecBase, RecTarget),
        recollection_to_integer(RecTarget, TargetBase)
    ).


count_distance(Start, Target, Distance) :-
    integer_to_recollection(Start, RecStart),
    integer_to_recollection(Target, RecTarget),
    count_distance_(RecStart, RecTarget, recollection([]), RecDistance),
    recollection_to_integer(RecDistance, Distance).

count_distance_(Current, Target, Distance, Distance) :-
    \+ smaller_than(Current, Target),
    !.
count_distance_(Current, Target, Acc, Distance) :-
    smaller_than(Current, Target),
    successor(Current, Next),
    successor(Acc, NextAcc),
    count_distance_(Next, Target, NextAcc, Distance).


count_on_values(Start, Count, Values) :-
    integer_to_recollection(Start, RecStart),
    integer_to_recollection(Count, RecCount),
    count_on_values_(RecStart, RecCount, [], RevValues),
    reverse(RevValues, Values).

count_on_values_(_Current, RecCount, Values, Values) :-
    is_zero_grounded(RecCount),
    !.
count_on_values_(Current, RecCount, Acc, Values) :-
    \+ is_zero_grounded(RecCount),
    successor(Current, Next),
    recollection_to_integer(Next, NextInt),
    predecessor(RecCount, Remaining),
    count_on_values_(Next, Remaining, [NextInt|Acc], Values).


chunk_components(A, B, chunk_components(Base, BaseChunk, OnesChunk, AfterBaseChunk, Result)) :-
    current_cgi_base(Base),
    integer_to_recollection(B, RecB),
    integer_to_recollection(Base, RecBase),
    base_decompose_grounded(RecB, RecBase, RecQuotient, RecRemainder),
    multiply_grounded(RecQuotient, RecBase, RecBaseChunk),
    recollection_to_integer(RecBaseChunk, BaseChunk),
    recollection_to_integer(RecRemainder, OnesChunk),
    add_ints(A, BaseChunk, AfterBaseChunk),
    add_ints(AfterBaseChunk, OnesChunk, Result),
    incur_cost(action_chunk_components).


column_addition_components(A, B, column_addition_components(Base, Columns, PlaceDigits, FinalCarry, Result)) :-
    current_cgi_base(Base),
    max_digit_length(A, B, MaxLength, ADigits, BDigits),
    build_carrying_columns(0, MaxLength, ADigits, BDigits, Base, 0, Columns, Digits, FinalCarry),
    place_digits(Digits, 0, PlaceDigits),
    compose_lsd_digits(Digits, Base, FinalCarry, Result),
    incur_cost(action_column_addition_with_carrying).


dropped_carry_components(A, B, dropped_carry_components(Base, Columns, PlaceDigits, DroppedCarries, Result)) :-
    current_cgi_base(Base),
    max_digit_length(A, B, MaxLength, ADigits, BDigits),
    build_dropped_carry_columns(0, MaxLength, ADigits, BDigits, Base, Columns, Digits, DroppedCarries),
    place_digits(Digits, 0, PlaceDigits),
    compose_lsd_digits(Digits, Base, 0, Result),
    incur_cost(action_drop_carry_to_next_column).


appended_column_sum_components(A, B, appended_column_sum_components(Base, ColumnSums, Result)) :-
    current_cgi_base(Base),
    max_digit_length(A, B, MaxLength, ADigits, BDigits),
    build_raw_column_sums(0, MaxLength, ADigits, BDigits, ColumnSums),
    concatenate_column_sums(ColumnSums, Result),
    incur_cost(action_append_column_sum_without_carrying).


wrong_carry_components(A, B, wrong_carry_components(Base, Columns, PlaceDigits, CarryAdjustments, FinalCarry, Result)) :-
    current_cgi_base(Base),
    max_digit_length(A, B, MaxLength, ADigits, BDigits),
    build_wrong_carry_columns(0, MaxLength, ADigits, BDigits, Base, 0, false,
                              Columns, Digits, CarryAdjustments, FinalCarry),
    place_digits(Digits, 0, PlaceDigits),
    compose_lsd_digits(Digits, Base, FinalCarry, Result),
    incur_cost(action_wrong_carry_amount_to_next_column).


known_fact_components(A, B, known_fact_components(A, B, Result)) :-
    A >= 0,
    B >= 0,
    add_ints(A, B, Result),
    Result =< 20,
    incur_cost(action_known_fact_retrieval).


derived_fact_components(A, B, derived_fact_components(double(Smaller), KnownSum, Difference, Result)) :-
    near_double_components(A, B, Smaller, Difference),
    add_ints(Smaller, Smaller, KnownSum),
    add_ints(KnownSum, Difference, Result),
    incur_cost(action_derived_fact_adjustment).


rote_derived_fact_components(A, B, rote_derived_fact_components(double(Smaller), KnownSum, Difference, AppliedDifference, Result)) :-
    near_double_components(A, B, Smaller, Difference),
    Difference > 1,
    AppliedDifference = 1,
    add_ints(Smaller, Smaller, KnownSum),
    add_ints(KnownSum, AppliedDifference, Result),
    incur_cost(action_rote_derived_fact_rule_misfire).


near_double_components(A, B, Smaller, Difference) :-
    larger_smaller(A, B, Larger, Smaller),
    count_distance(Smaller, Larger, Difference),
    Difference > 0,
    Difference =< 3.


max_digit_length(A, B, MaxLength, ADigits, BDigits) :-
    digits_lsd(A, ADigits),
    digits_lsd(B, BDigits),
    length(ADigits, ALength),
    length(BDigits, BLength),
    MaxLength is max(ALength, BLength).


build_carrying_columns(Index, MaxLength, _ADigits, _BDigits, _Base, Carry, [], [], Carry) :-
    Index >= MaxLength,
    !.
build_carrying_columns(Index, MaxLength, ADigits, BDigits, Base, CarryIn,
                       [column(Place, ADigit, BDigit, CarryIn, RawSum, WrittenDigit, CarryOut)|Columns],
                       [WrittenDigit|Digits],
                       FinalCarry) :-
    Index < MaxLength,
    place_label(Index, Place),
    digit_at(ADigits, Index, ADigit),
    digit_at(BDigits, Index, BDigit),
    RawSum is ADigit + BDigit + CarryIn,
    WrittenDigit is RawSum mod Base,
    CarryOut is RawSum // Base,
    NextIndex is Index + 1,
    build_carrying_columns(NextIndex, MaxLength, ADigits, BDigits, Base, CarryOut,
                           Columns, Digits, FinalCarry).


build_dropped_carry_columns(Index, MaxLength, _ADigits, _BDigits, _Base, [], [], []) :-
    Index >= MaxLength,
    !.
build_dropped_carry_columns(Index, MaxLength, ADigits, BDigits, Base,
                            [column(Place, ADigit, BDigit, 0, RawSum, WrittenDigit, CarryOut)|Columns],
                            [WrittenDigit|Digits],
                            DroppedCarries) :-
    Index < MaxLength,
    place_label(Index, Place),
    digit_at(ADigits, Index, ADigit),
    digit_at(BDigits, Index, BDigit),
    RawSum is ADigit + BDigit,
    WrittenDigit is RawSum mod Base,
    CarryOut is RawSum // Base,
    NextIndex is Index + 1,
    build_dropped_carry_columns(NextIndex, MaxLength, ADigits, BDigits, Base,
                                Columns, Digits, RestDroppedCarries),
    (   CarryOut > 0
    ->  DroppedCarries = [dropped_carry(Place, CarryOut)|RestDroppedCarries]
    ;   DroppedCarries = RestDroppedCarries
    ).


build_raw_column_sums(Index, MaxLength, _ADigits, _BDigits, []) :-
    Index >= MaxLength,
    !.
build_raw_column_sums(Index, MaxLength, ADigits, BDigits,
                      [column_sum(Place, ADigit, BDigit, RawSum)|ColumnSums]) :-
    Index < MaxLength,
    place_label(Index, Place),
    digit_at(ADigits, Index, ADigit),
    digit_at(BDigits, Index, BDigit),
    RawSum is ADigit + BDigit,
    NextIndex is Index + 1,
    build_raw_column_sums(NextIndex, MaxLength, ADigits, BDigits, ColumnSums).


build_wrong_carry_columns(Index, MaxLength, _ADigits, _BDigits, _Base, Carry, _WrongUsed,
                          [], [], [], Carry) :-
    Index >= MaxLength,
    !.
build_wrong_carry_columns(Index, MaxLength, ADigits, BDigits, Base, CarryIn, WrongUsed,
                          [column(Place, ADigit, BDigit, CarryIn, RawSum, WrittenDigit, CarryOut)|Columns],
                          [WrittenDigit|Digits],
                          CarryAdjustments,
                          FinalCarry) :-
    Index < MaxLength,
    place_label(Index, Place),
    digit_at(ADigits, Index, ADigit),
    digit_at(BDigits, Index, BDigit),
    RawSum is ADigit + BDigit + CarryIn,
    WrittenDigit is RawSum mod Base,
    CarryOut is RawSum // Base,
    NextIndex is Index + 1,
    (   CarryOut > 0,
        NextIndex < MaxLength,
        WrongUsed == false
    ->  WrongCarry is CarryOut + 1,
        NextCarry = WrongCarry,
        NextWrongUsed = true,
        CarryAdjustments = [wrong_carry_to_next_column(Place, correct(CarryOut), used(WrongCarry))|RestAdjustments]
    ;   NextCarry = CarryOut,
        NextWrongUsed = WrongUsed,
        CarryAdjustments = RestAdjustments
    ),
    build_wrong_carry_columns(NextIndex, MaxLength, ADigits, BDigits, Base, NextCarry, NextWrongUsed,
                              Columns, Digits, RestAdjustments, FinalCarry).


digits_lsd(N, [Digit|Rest]) :-
    integer(N),
    N >= 0,
    Digit is N mod 10,
    Quotient is N // 10,
    (   Quotient =:= 0
    ->  Rest = []
    ;   digits_lsd(Quotient, Rest)
    ).


digit_at(Digits, Index, Digit) :-
    nth0(Index, Digits, Digit),
    !.
digit_at(_Digits, _Index, 0).


place_digits([], _Index, []).
place_digits([Digit|Digits], Index, [place_digit(Place, Digit)|PlaceDigits]) :-
    place_label(Index, Place),
    NextIndex is Index + 1,
    place_digits(Digits, NextIndex, PlaceDigits).


place_label(0, ones) :- !.
place_label(1, tens) :- !.
place_label(2, hundreds) :- !.
place_label(3, thousands) :- !.
place_label(Index, place(Index)).


compose_lsd_digits(Digits, Base, FinalCarry, Result) :-
    compose_lsd_digits_(Digits, Base, 1, 0, FinalCarry, Result).

compose_lsd_digits_([], _Base, Multiplier, Acc, FinalCarry, Result) :-
    Result is Acc + FinalCarry * Multiplier.
compose_lsd_digits_([Digit|Digits], Base, Multiplier, Acc, FinalCarry, Result) :-
    NextAcc is Acc + Digit * Multiplier,
    NextMultiplier is Multiplier * Base,
    compose_lsd_digits_(Digits, Base, NextMultiplier, NextAcc, FinalCarry, Result).


has_multi_digit_column_sum([column_sum(_Place, _ADigit, _BDigit, RawSum)|_ColumnSums]) :-
    RawSum >= 10,
    !.
has_multi_digit_column_sum([_ColumnSum|ColumnSums]) :-
    has_multi_digit_column_sum(ColumnSums).


concatenate_column_sums(ColumnSums, Result) :-
    reverse(ColumnSums, MostSignificantFirst),
    column_sum_codes(MostSignificantFirst, Codes),
    number_codes(Result, Codes).

column_sum_codes([], []).
column_sum_codes([column_sum(_Place, _ADigit, _BDigit, RawSum)|ColumnSums], Codes) :-
    number_codes(RawSum, RawCodes),
    column_sum_codes(ColumnSums, RestCodes),
    append(RawCodes, RestCodes, Codes).


% add_ints/3 and subtract_ints/3 imported from math(integer_helpers).
