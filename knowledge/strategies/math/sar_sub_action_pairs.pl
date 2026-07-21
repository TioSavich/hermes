/** <module> Subtractive strategy/deformation action pairs
 *
 * This module extends the "actions over vocabularies" layer to subtraction.
 * It elaborates from the existing subtraction SAR automata by naming productive
 * actions and nearby deformations as executable traces.
 *
 * First subtraction slice:
 *   - take-away by base and ones;
 *   - the dropped-ones take-away deformation;
 *   - missing-addend count-up;
 *   - the endpoint-as-answer deformation;
 *   - sliding/constant difference;
 *   - the subtrahend-only slide deformation;
 *   - decomposition/exchange of one base for ones;
 *   - the borrow-without-reducing-tens deformation
 *     (incomplete borrow that leaves the tens column at full value).
 *
 * Additional decomposition deformations split out from the borrow family:
 *   - smaller-from-larger-in-column: subtract the smaller digit from the larger
 *     in each column, regardless of which is minuend and which is subtrahend.
 *   - add-instead-of-subtract-column: add digits column-by-column instead of
 *     subtracting.
 *   - borrow-across-zero-no-cascade: attempt to borrow through a zero column
 *     without cascading the borrow up to the next non-zero place.
 *   - borrow-across-zero-cascade: arbitrary-length zero-run cascade through
 *     place-value columns.
 *   - compare-by-matching-difference: match two sets one-to-one and count the
 *     unmatched surplus; its deformation reports the larger set count as the
 *     answer to "how many more?"
 */

:- module(sar_sub_action_pairs,
          [ run_subtractive_action/5,
            subtractive_action_cluster/2,
            subtractive_action_vocabulary/2,
            productive_subtractive_deformation/3,
            subtractive_action_misconception_hook/3
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
:- use_module(math(sar_sub_cbbo_take_away), [run_cbbo_ta/4]).
:- use_module(math(sar_sub_cobo_missing_addend), [run_cobo_ma/4]).
:- use_module(math(sar_sub_sliding), [run_sliding/4]).
:- use_module(math(sar_sub_decomposition), [run_decomposition/4]).
:- use_module(math(sar_sub_counting_back), [run_counting_back/4]).
:- use_module(math(integer_helpers), [add_ints/3, subtract_ints/3, multiply_ints/3]).

% DPDA kernel: tick/tock automaton with carry/borrow across ones/tens/hundreds.
% Provides the place-value implementation surface that strategic count-back
% shells (sar_sub_counting_back, sar_sub_cobo_missing_addend) operate on top of.
:- use_module(math(counting_on_back), [run_counter/3]).
:- use_module(math(cgi_base), [current_cgi_base/1]).


%!  run_subtractive_action(+Kind, +M, +S, -Outcome, -Trace) is semidet.
%
%   Execute a productive or deformed subtractive action automaton.
run_subtractive_action(take_away_base_ones, M, S, Outcome, Trace) :-
    run_cbbo_ta(M, S, ExistingResult, ExistingTrace),
    takeaway_components(M, S, Components),
    Components = takeaway_components(Base, BaseChunk, OnesChunk, AfterBaseChunk, Result),
    Outcome = action_outcome(
                  take_away_base_ones,
                  [ classification(productive),
                    cluster(subtractive_strategy_fluency),
                    automaton_state(count_back_take_away),
                    vocabulary([minuend, subtrahend, base_chunk, ones_chunk, running_difference]),
                    result(Result),
                    expected(ExistingResult),
                    validity(correct),
                    components(Components),
                    elaborates(sar_sub_cbbo_take_away:run_cbbo_ta/4),
                    evidence(existing_trace(ExistingTrace))
                  ]),
    Trace = [ decompose_subtrahend(S, base(Base), base_chunk(BaseChunk), ones_chunk(OnesChunk)),
              count_back_by_base_chunk(M, BaseChunk, AfterBaseChunk),
              count_back_by_ones(AfterBaseChunk, OnesChunk, Result),
              preserve_all_subtracted_parts(Result)
            ].
run_subtractive_action(drop_ones_after_base_takeaway, M, S, Outcome, Trace) :-
    takeaway_components(M, S, Components),
    Components = takeaway_components(Base, BaseChunk, OnesChunk, AfterBaseChunk, _CorrectResult),
    BaseChunk > 0,
    OnesChunk > 0,
    subtract_ints(M, S, Expected),
    Result = AfterBaseChunk,
    Outcome = action_outcome(
                  drop_ones_after_base_takeaway,
                  [ classification(deformation),
                    cluster(subtractive_strategy_fluency),
                    automaton_state(count_back_take_away),
                    vocabulary([minuend, subtrahend, base_chunk, ones_chunk, running_difference]),
                    result(Result),
                    expected(Expected),
                    validity(incorrect),
                    components(Components),
                    deformation_of(take_away_base_ones),
                    misconception_family(dropped_subtrahend_remainder)
                  ]),
    Trace = [ decompose_subtrahend(S, base(Base), base_chunk(BaseChunk), ones_chunk(OnesChunk)),
              count_back_by_base_chunk(M, BaseChunk, AfterBaseChunk),
              drop_ones_chunk(OnesChunk),
              lose_subtracted_remainder(expected(Expected), produced(Result))
            ].
run_subtractive_action(count_up_missing_addend, M, S, Outcome, Trace) :-
    run_cobo_ma(M, S, ExistingResult, ExistingTrace),
    count_up_components(M, S, Components),
    Components = count_up_components(Base, BaseJumps, OneJumps, Distance, Endpoint),
    Outcome = action_outcome(
                  count_up_missing_addend,
                  [ classification(productive),
                    cluster(subtractive_strategy_fluency),
                    automaton_state(missing_addend_count_up),
                    vocabulary([start_number, target_number, base_jump, one_jump, distance]),
                    result(Distance),
                    expected(ExistingResult),
                    validity(correct),
                    components(Components),
                    elaborates(sar_sub_cobo_missing_addend:run_cobo_ma/4),
                    evidence(existing_trace(ExistingTrace))
                  ]),
    Trace = [ start_at_subtrahend(S),
              target_minuend(M),
              count_up_by_bases(base(Base), BaseJumps),
              count_up_by_ones(OneJumps),
              name_distance_not_endpoint(Distance, endpoint(Endpoint))
            ].
run_subtractive_action(answer_as_endpoint_count_up, M, S, Outcome, Trace) :-
    count_up_components(M, S, Components),
    Components = count_up_components(Base, BaseJumps, OneJumps, Distance, Endpoint),
    Result = Endpoint,
    Outcome = action_outcome(
                  answer_as_endpoint_count_up,
                  [ classification(deformation),
                    cluster(subtractive_strategy_fluency),
                    automaton_state(missing_addend_count_up),
                    vocabulary([start_number, target_number, base_jump, one_jump, distance]),
                    result(Result),
                    expected(Distance),
                    validity(incorrect),
                    components(Components),
                    deformation_of(count_up_missing_addend),
                    misconception_family(endpoint_as_difference)
                  ]),
    Trace = [ start_at_subtrahend(S),
              target_minuend(M),
              count_up_by_bases(base(Base), BaseJumps),
              count_up_by_ones(OneJumps),
              name_endpoint_as_answer(Endpoint),
              lose_distance_as_count(expected(Distance), produced(Result))
            ].
run_subtractive_action(compare_by_matching_difference, A, B, Outcome, Trace) :-
    comparison_difference_components(A, B, Components),
    Components = comparison_difference_components(_A, _B, Larger, Smaller, Difference, Relation),
    Outcome = action_outcome(
                  compare_by_matching_difference,
                  [ classification(productive),
                    cluster(quantity_comparison_difference),
                    automaton_state(matching_comparison),
                    vocabulary([set_a, set_b, one_to_one_matching, unmatched_objects, difference]),
                    result(Difference),
                    expected(Difference),
                    validity(correct),
                    components(Components),
                    source(db_row(40167)),
                    source_key('JMTE_Rowland_2005_Elementary')
                  ]),
    Trace = [ identify_larger_and_smaller(set_a(A), set_b(B), Relation),
              pair_objects_one_to_one(larger_count(Larger), smaller_count(Smaller)),
              remove_matched_pairs(Smaller),
              count_unmatched_as_difference(Difference),
              name_difference_not_larger_total(Difference)
            ].
run_subtractive_action(compare_returns_larger_count, A, B, Outcome, Trace) :-
    comparison_difference_components(A, B, Components),
    Components = comparison_difference_components(_A, _B, Larger, Smaller, Difference, Relation),
    Difference > 0,
    Result = Larger,
    Outcome = action_outcome(
                  compare_returns_larger_count,
                  [ classification(deformation),
                    cluster(quantity_comparison_difference),
                    automaton_state(matching_comparison),
                    vocabulary([set_a, set_b, one_to_one_matching, unmatched_objects, difference]),
                    result(Result),
                    expected(Difference),
                    validity(incorrect),
                    components(Components),
                    deformation_of(compare_by_matching_difference),
                    misconception_family(larger_count_as_difference),
                    source(db_row(40167)),
                    source_key('JMTE_Rowland_2005_Elementary')
                  ]),
    Trace = [ identify_larger_and_smaller(set_a(A), set_b(B), Relation),
              pair_objects_one_to_one(larger_count(Larger), smaller_count(Smaller)),
              ignore_matched_pairs(Smaller),
              report_larger_count_as_difference(Result),
              lose_surplus_as_unmatched_remainder(expected(Difference), produced(Result))
            ].
run_subtractive_action(sliding_constant_difference, M, S, Outcome, Trace) :-
    run_sliding(M, S, ExistingResult, ExistingTrace),
    sliding_components(M, S, Components),
    Components = sliding_components(Base, TargetBase, K, AdjustedM, AdjustedS, Result),
    K > 0,
    Outcome = action_outcome(
                  sliding_constant_difference,
                  [ classification(productive),
                    cluster(subtractive_strategy_fluency),
                    automaton_state(constant_difference),
                    vocabulary([minuend, subtrahend, slide_amount, friendly_subtrahend, constant_difference]),
                    result(Result),
                    expected(ExistingResult),
                    validity(correct),
                    components(Components),
                    elaborates(sar_sub_sliding:run_sliding/4),
                    evidence(existing_trace(ExistingTrace))
                  ]),
    Trace = [ identify_subtrahend_target_base(S, Base, TargetBase),
              count_slide_amount(S, TargetBase, K),
              slide_both_numbers(M, S, K, AdjustedM, AdjustedS),
              subtract_adjusted_pair(AdjustedM, AdjustedS, Result),
              preserve_constant_difference(Result)
            ].
run_subtractive_action(slide_subtrahend_only, M, S, Outcome, Trace) :-
    sliding_components(M, S, Components),
    Components = sliding_components(Base, TargetBase, K, _AdjustedM, AdjustedS, _CorrectResult),
    K > 0,
    subtract_ints(M, S, Expected),
    subtract_ints(M, AdjustedS, Result),
    Outcome = action_outcome(
                  slide_subtrahend_only,
                  [ classification(deformation),
                    cluster(subtractive_strategy_fluency),
                    automaton_state(constant_difference),
                    vocabulary([minuend, subtrahend, slide_amount, friendly_subtrahend, constant_difference]),
                    result(Result),
                    expected(Expected),
                    validity(incorrect),
                    components(Components),
                    deformation_of(sliding_constant_difference),
                    misconception_family(nonconstant_difference_shift)
                  ]),
    Trace = [ identify_subtrahend_target_base(S, Base, TargetBase),
              count_slide_amount(S, TargetBase, K),
              slide_subtrahend_without_minuend(S, K, AdjustedS),
              subtract_unbalanced_pair(M, AdjustedS, Result),
              lose_constant_difference(expected(Expected), produced(Result))
            ].
run_subtractive_action(decompose_base_for_ones, M, S, Outcome, Trace) :-
    run_decomposition(M, S, ExistingResult, ExistingTrace),
    decomposition_components(M, S, Components),
    Components = decomposition_components(Base, MinuendBases, MinuendOnes,
                                          SubtrahendBases, SubtrahendOnes,
                                          BasesAfterSubtraction, BorrowedBases,
                                          ExchangedOnes, OnesAfterSubtraction,
                                          Result),
    Outcome = action_outcome(
                  decompose_base_for_ones,
                  [ classification(productive),
                    cluster(subtractive_strategy_fluency),
                    automaton_state(decompose_exchange),
                    vocabulary([base_unit, ones, exchange, borrowed_base, recomposition]),
                    result(Result),
                    expected(ExistingResult),
                    validity(correct),
                    components(Components),
                    elaborates(sar_sub_decomposition:run_decomposition/4),
                    evidence(existing_trace(ExistingTrace))
                  ]),
    Trace = [ decompose_numbers(minuend(MinuendBases, MinuendOnes),
                                subtrahend(SubtrahendBases, SubtrahendOnes)),
              subtract_base_components(MinuendBases, SubtrahendBases, BasesAfterSubtraction),
              exchange_one_base_for_ones(base(Base),
                                         from_bases(BasesAfterSubtraction),
                                         to_ones(MinuendOnes, ExchangedOnes),
                                         remaining_bases(BorrowedBases)),
              subtract_ones(ExchangedOnes, SubtrahendOnes, OnesAfterSubtraction),
              recompose_difference(BorrowedBases, OnesAfterSubtraction, Result)
            ].
run_subtractive_action(borrow_without_reducing_bases, M, S, Outcome, Trace) :-
    decomposition_components(M, S, Components),
    Components = decomposition_components(Base, MinuendBases, MinuendOnes,
                                          SubtrahendBases, SubtrahendOnes,
                                          BasesAfterSubtraction, _BorrowedBases,
                                          ExchangedOnes, OnesAfterSubtraction,
                                          _CorrectResult),
    multiply_ints(BasesAfterSubtraction, Base, RecombinedBases),
    add_ints(RecombinedBases, OnesAfterSubtraction, Result),
    subtract_ints(M, S, Expected),
    Outcome = action_outcome(
                  borrow_without_reducing_bases,
                  [ classification(deformation),
                    cluster(subtractive_strategy_fluency),
                    automaton_state(decompose_exchange),
                    vocabulary([base_unit, ones, exchange, borrowed_base, recomposition]),
                    result(Result),
                    expected(Expected),
                    validity(incorrect),
                    components(Components),
                    deformation_of(decompose_base_for_ones),
                    misconception_family(unbalanced_decomposition_exchange)
                  ]),
    Trace = [ decompose_numbers(minuend(MinuendBases, MinuendOnes),
                                subtrahend(SubtrahendBases, SubtrahendOnes)),
              subtract_base_components(MinuendBases, SubtrahendBases, BasesAfterSubtraction),
              add_base_to_ones_without_removing_base(base(Base), MinuendOnes, ExchangedOnes),
              subtract_ones(ExchangedOnes, SubtrahendOnes, OnesAfterSubtraction),
              recompose_with_unreduced_bases(BasesAfterSubtraction, OnesAfterSubtraction, Result),
              lose_exchange_conservation(expected(Expected), produced(Result))
            ].
run_subtractive_action(smaller_from_larger_in_column, M, S, Outcome, Trace) :-
    decomposition_components(M, S, Components),
    Components = decomposition_components(Base, MinuendBases, MinuendOnes,
                                          SubtrahendBases, SubtrahendOnes,
                                          _BasesAfterSubtraction, _BorrowedBases,
                                          _ExchangedOnes, _OnesAfterSubtraction,
                                          _CorrectResult),
    abs_diff_ints(MinuendOnes, SubtrahendOnes, OnesAbs),
    abs_diff_ints(MinuendBases, SubtrahendBases, BasesAbs),
    multiply_ints(BasesAbs, Base, BasesRecombined),
    add_ints(BasesRecombined, OnesAbs, Result),
    subtract_ints(M, S, Expected),
    Outcome = action_outcome(
                  smaller_from_larger_in_column,
                  [ classification(deformation),
                    cluster(subtractive_strategy_fluency),
                    automaton_state(decompose_exchange),
                    vocabulary([base_unit, ones, exchange, borrowed_base, recomposition]),
                    result(Result),
                    expected(Expected),
                    validity(incorrect),
                    components(Components),
                    deformation_of(decompose_base_for_ones),
                    misconception_family(smaller_from_larger_column)
                  ]),
    Trace = [ decompose_numbers(minuend(MinuendBases, MinuendOnes),
                                subtrahend(SubtrahendBases, SubtrahendOnes)),
              skip_borrow_procedure,
              subtract_smaller_from_larger_in_ones(MinuendOnes, SubtrahendOnes, OnesAbs),
              subtract_smaller_from_larger_in_bases(MinuendBases, SubtrahendBases, BasesAbs),
              recompose_without_role_preservation(BasesAbs, OnesAbs, Result),
              lose_minuend_subtrahend_roles(expected(Expected), produced(Result))
            ].
run_subtractive_action(add_instead_of_subtract_column, M, S, Outcome, Trace) :-
    column_decomposition(M, S, Components),
    Components = column_decomposition(Base, MinuendBases, MinuendOnes,
                                      SubtrahendBases, SubtrahendOnes),
    add_ints(MinuendOnes, SubtrahendOnes, OnesSum),
    add_ints(MinuendBases, SubtrahendBases, BasesSum),
    multiply_ints(BasesSum, Base, BasesRecombined),
    add_ints(BasesRecombined, OnesSum, Result),
    subtract_ints(M, S, Expected),
    Outcome = action_outcome(
                  add_instead_of_subtract_column,
                  [ classification(deformation),
                    cluster(subtractive_strategy_fluency),
                    automaton_state(decompose_exchange),
                    vocabulary([base_unit, ones, exchange, borrowed_base, recomposition]),
                    result(Result),
                    expected(Expected),
                    validity(incorrect),
                    components(Components),
                    deformation_of(decompose_base_for_ones),
                    misconception_family(operation_direction_reversal)
                  ]),
    Trace = [ decompose_numbers(minuend(MinuendBases, MinuendOnes),
                                subtrahend(SubtrahendBases, SubtrahendOnes)),
              add_ones_instead_of_subtracting(MinuendOnes, SubtrahendOnes, OnesSum),
              add_bases_instead_of_subtracting(MinuendBases, SubtrahendBases, BasesSum),
              recompose_as_sum(BasesSum, OnesSum, Result),
              lose_operation_direction(expected(Expected), produced(Result))
            ].
run_subtractive_action(borrow_across_zero_cascade, M, S, Outcome, Trace) :-
    zero_cascade_components(M, S, Components),
    Components = zero_cascade_components(Base, MinuendDigits, SubtrahendDigits,
                                         ZeroPositions, DonorPosition, DonorDigit, Result),
    Outcome = action_outcome(
                  borrow_across_zero_cascade,
                  [ classification(productive),
                    cluster(subtractive_strategy_fluency),
                    automaton_state(decompose_exchange),
                    vocabulary([base_unit, digit_column, zero_column, donor_column, cascade_borrow, recomposition]),
                    result(Result),
                    expected(Result),
                    validity(correct),
                    components(Components),
                    invariant(cascade_borrow_to_next_nonzero_column)
                  ]),
    Trace = [ decompose_columns(minuend_digits(MinuendDigits),
                                subtrahend_digits(SubtrahendDigits)),
              identify_zero_cascade(zero_columns(ZeroPositions),
                                    donor_column(DonorPosition, DonorDigit)),
              cascade_borrow_from_donor_column(base(Base),
                                               donor_column(DonorPosition, DonorDigit)),
              convert_zero_columns_to_nines(ZeroPositions),
              borrow_into_ones_after_cascade,
              subtract_after_zero_cascade(Result)
            ].
run_subtractive_action(borrow_across_zero_no_cascade, M, S, Outcome, Trace) :-
    zero_cascade_components(M, S, Components),
    Components = zero_cascade_components(Base, MinuendDigits, SubtrahendDigits,
                                         ZeroPositions, DonorPosition, DonorDigit, _CorrectResult),
    zero_cascade_no_cascade_result(Components, DeformedDigits, Result),
    StuckTensValue is Base - 1,
    subtract_ints(M, S, Expected),
    Outcome = action_outcome(
                  borrow_across_zero_no_cascade,
                  [ classification(deformation),
                    cluster(subtractive_strategy_fluency),
                    automaton_state(decompose_exchange),
                    vocabulary([base_unit, ones, exchange, borrowed_base, recomposition]),
                    result(Result),
                    expected(Expected),
                    validity(incorrect),
                    components(Components),
                    deformation_of(decompose_base_for_ones),
                    misconception_family(borrow_across_zero)
                  ]),
    Trace = [ decompose_columns(minuend_digits(MinuendDigits),
                                subtrahend_digits(SubtrahendDigits)),
              identify_zero_cascade(zero_columns(ZeroPositions),
                                    donor_column(DonorPosition, DonorDigit)),
              note_zero_tens_column,
              treat_zero_as_full_base(base(Base), stuck_tens(StuckTensValue)),
              skip_hundreds_decrement,
              skip_donor_decrement(position(DonorPosition), donor_digit(DonorDigit)),
              recompose_without_zero_cascade(deformed_digits(DeformedDigits), Result),
              lose_hundreds_borrow(expected(Expected), produced(Result))
            ].


%!  subtractive_action_cluster(+Kind, -Cluster) is det.
subtractive_action_cluster(take_away_base_ones, subtractive_strategy_fluency).
subtractive_action_cluster(drop_ones_after_base_takeaway, subtractive_strategy_fluency).
subtractive_action_cluster(count_up_missing_addend, subtractive_strategy_fluency).
subtractive_action_cluster(answer_as_endpoint_count_up, subtractive_strategy_fluency).
subtractive_action_cluster(compare_by_matching_difference, quantity_comparison_difference).
subtractive_action_cluster(compare_returns_larger_count, quantity_comparison_difference).
subtractive_action_cluster(sliding_constant_difference, subtractive_strategy_fluency).
subtractive_action_cluster(slide_subtrahend_only, subtractive_strategy_fluency).
subtractive_action_cluster(decompose_base_for_ones, subtractive_strategy_fluency).
subtractive_action_cluster(borrow_without_reducing_bases, subtractive_strategy_fluency).
subtractive_action_cluster(smaller_from_larger_in_column, subtractive_strategy_fluency).
subtractive_action_cluster(add_instead_of_subtract_column, subtractive_strategy_fluency).
subtractive_action_cluster(borrow_across_zero_cascade, subtractive_strategy_fluency).
subtractive_action_cluster(borrow_across_zero_no_cascade, subtractive_strategy_fluency).


%!  subtractive_action_vocabulary(+Kind, -Vocabulary) is det.
subtractive_action_vocabulary(take_away_base_ones,
                              [minuend, subtrahend, base_chunk, ones_chunk, running_difference]).
subtractive_action_vocabulary(drop_ones_after_base_takeaway,
                              [minuend, subtrahend, base_chunk, ones_chunk, running_difference]).
subtractive_action_vocabulary(count_up_missing_addend,
                              [start_number, target_number, base_jump, one_jump, distance]).
subtractive_action_vocabulary(answer_as_endpoint_count_up,
                              [start_number, target_number, base_jump, one_jump, distance]).
subtractive_action_vocabulary(compare_by_matching_difference,
                              [set_a, set_b, one_to_one_matching, unmatched_objects, difference]).
subtractive_action_vocabulary(compare_returns_larger_count,
                              [set_a, set_b, one_to_one_matching, unmatched_objects, difference]).
subtractive_action_vocabulary(sliding_constant_difference,
                              [minuend, subtrahend, slide_amount, friendly_subtrahend, constant_difference]).
subtractive_action_vocabulary(slide_subtrahend_only,
                              [minuend, subtrahend, slide_amount, friendly_subtrahend, constant_difference]).
subtractive_action_vocabulary(decompose_base_for_ones,
                              [base_unit, ones, exchange, borrowed_base, recomposition]).
subtractive_action_vocabulary(borrow_without_reducing_bases,
                              [base_unit, ones, exchange, borrowed_base, recomposition]).
subtractive_action_vocabulary(smaller_from_larger_in_column,
                              [base_unit, ones, exchange, borrowed_base, recomposition]).
subtractive_action_vocabulary(add_instead_of_subtract_column,
                              [base_unit, ones, exchange, borrowed_base, recomposition]).
subtractive_action_vocabulary(borrow_across_zero_cascade,
                              [base_unit, digit_column, zero_column, donor_column, cascade_borrow, recomposition]).
subtractive_action_vocabulary(borrow_across_zero_no_cascade,
                              [base_unit, ones, exchange, borrowed_base, recomposition]).


%!  productive_subtractive_deformation(+ProductiveKind, +DeformationKind, -MisconceptionFamily) is det.
productive_subtractive_deformation(take_away_base_ones,
                                   drop_ones_after_base_takeaway,
                                   dropped_subtrahend_remainder).
productive_subtractive_deformation(count_up_missing_addend,
                                   answer_as_endpoint_count_up,
                                   endpoint_as_difference).
productive_subtractive_deformation(compare_by_matching_difference,
                                   compare_returns_larger_count,
                                   larger_count_as_difference).
productive_subtractive_deformation(sliding_constant_difference,
                                   slide_subtrahend_only,
                                   nonconstant_difference_shift).
productive_subtractive_deformation(decompose_base_for_ones,
                                   borrow_without_reducing_bases,
                                   unbalanced_decomposition_exchange).
productive_subtractive_deformation(decompose_base_for_ones,
                                   smaller_from_larger_in_column,
                                   smaller_from_larger_column).
productive_subtractive_deformation(decompose_base_for_ones,
                                   add_instead_of_subtract_column,
                                   operation_direction_reversal).
productive_subtractive_deformation(decompose_base_for_ones,
                                   borrow_across_zero_no_cascade,
                                   borrow_across_zero).
productive_subtractive_deformation(borrow_across_zero_cascade,
                                   borrow_across_zero_no_cascade,
                                   borrow_across_zero).


%!  subtractive_action_misconception_hook(+Outcome, -Family, -Hook) is semidet.
subtractive_action_misconception_hook(action_outcome(Kind, Fields), Family, Hook) :-
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
subtractive_action_misconception_hook(action_outcome(Kind, Fields), Family, Hook) :-
    member(classification(productive), Fields),
    productive_subtractive_deformation(Kind, DeformationKind, Family),
    member(vocabulary(Vocabulary), Fields),
    Hook = action_misconception_hook(
               [ productive_action(Kind),
                 nearby_deformation(DeformationKind),
                 family(Family),
                 vocabulary(Vocabulary),
                 monitoring_focus(preserve_action_invariants(Kind)),
                 evidence(Fields)
               ]).


takeaway_components(M, S, takeaway_components(Base, BaseChunk, OnesChunk, AfterBaseChunk, Result)) :-
    current_cgi_base(Base),
    integer_to_recollection(S, RecS),
    integer_to_recollection(Base, RecBase),
    base_decompose_grounded(RecS, RecBase, RecQuotient, RecRemainder),
    multiply_grounded(RecQuotient, RecBase, RecBaseChunk),
    recollection_to_integer(RecBaseChunk, BaseChunk),
    recollection_to_integer(RecRemainder, OnesChunk),
    subtract_ints(M, BaseChunk, AfterBaseChunk),
    subtract_ints(AfterBaseChunk, OnesChunk, Result),
    incur_cost(action_takeaway_components).


count_up_components(M, S, count_up_components(Base, BaseJumps, OneJumps, Distance, M)) :-
    current_cgi_base(Base),
    integer_to_recollection(S, RecS),
    integer_to_recollection(M, RecM),
    \+ greater_than(RecS, RecM),
    count_up_base_jumps(S, M, Base, 0, [], RevBaseJumps, AfterBases, BaseDistance),
    reverse(RevBaseJumps, BaseJumps),
    count_up_one_jumps(AfterBases, M, [], RevOneJumps, OneDistance),
    reverse(RevOneJumps, OneJumps),
    add_ints(BaseDistance, OneDistance, Distance),
    incur_cost(action_count_up_components).


count_up_base_jumps(Current, Target, Base, Distance, Jumps, Jumps, Current, Distance) :-
    Next is Current + Base,
    Next > Target,
    !.
count_up_base_jumps(Current, Target, Base, Distance, Acc, Jumps, AfterBases, TotalDistance) :-
    Next is Current + Base,
    Next =< Target,
    add_ints(Distance, Base, NewDistance),
    count_up_base_jumps(Next, Target, Base, NewDistance, [Next|Acc], Jumps, AfterBases, TotalDistance).


count_up_one_jumps(Current, Current, Jumps, Jumps, 0) :- !.
count_up_one_jumps(Current, Target, Acc, Jumps, Distance) :-
    Current < Target,
    integer_to_recollection(Current, RecCurrent),
    successor(RecCurrent, RecNext),
    recollection_to_integer(RecNext, Next),
    count_up_one_jumps(Next, Target, [Next|Acc], Jumps, RemainingDistance),
    successor_count(RemainingDistance, Distance).


comparison_difference_components(A, B,
                                 comparison_difference_components(A, B, Larger, Smaller, Difference, Relation)) :-
    A >= 0,
    B >= 0,
    (   A >= B
    ->  Larger = A,
        Smaller = B,
        Relation = first_not_smaller
    ;   Larger = B,
        Smaller = A,
        Relation = second_larger
    ),
    subtract_ints(Larger, Smaller, Difference),
    incur_cost(action_comparison_difference_components).


sliding_components(M, S, sliding_components(Base, TargetBase, K, AdjustedM, AdjustedS, Result)) :-
    current_cgi_base(Base),
    next_base_target(S, Base, TargetBase),
    count_distance(S, TargetBase, K),
    add_ints(M, K, AdjustedM),
    add_ints(S, K, AdjustedS),
    subtract_ints(AdjustedM, AdjustedS, Result),
    incur_cost(action_sliding_components).


column_decomposition(M, S, column_decomposition(Base, MinuendBases, MinuendOnes,
                                                SubtrahendBases, SubtrahendOnes)) :-
    current_cgi_base(Base),
    integer_to_recollection(M, RecM),
    integer_to_recollection(S, RecS),
    integer_to_recollection(Base, RecBase),
    base_decompose_grounded(RecM, RecBase, RecMinuendBases, RecMinuendOnes),
    base_decompose_grounded(RecS, RecBase, RecSubtrahendBases, RecSubtrahendOnes),
    recollection_to_integer(RecMinuendBases, MinuendBases),
    recollection_to_integer(RecMinuendOnes, MinuendOnes),
    recollection_to_integer(RecSubtrahendBases, SubtrahendBases),
    recollection_to_integer(RecSubtrahendOnes, SubtrahendOnes),
    incur_cost(action_column_decomposition).


three_column_decomposition(M, S,
                           three_column_decomposition(Base, MinuendHundreds, MinuendTens, MinuendOnes,
                                                      SubtrahendHundreds, SubtrahendTens, SubtrahendOnes)) :-
    current_cgi_base(Base),
    integer_to_recollection(M, RecM),
    integer_to_recollection(S, RecS),
    \+ greater_than(RecS, RecM),
    integer_to_recollection(Base, RecBase),
    base_decompose_grounded(RecM, RecBase, RecMTensCount, RecMOnes),
    base_decompose_grounded(RecMTensCount, RecBase, RecMHundreds, RecMTens),
    base_decompose_grounded(RecS, RecBase, RecSTensCount, RecSOnes),
    base_decompose_grounded(RecSTensCount, RecBase, RecSHundreds, RecSTens),
    recollection_to_integer(RecMHundreds, MinuendHundreds),
    recollection_to_integer(RecMTens, MinuendTens),
    recollection_to_integer(RecMOnes, MinuendOnes),
    recollection_to_integer(RecSHundreds, SubtrahendHundreds),
    recollection_to_integer(RecSTens, SubtrahendTens),
    recollection_to_integer(RecSOnes, SubtrahendOnes),
    incur_cost(action_three_column_decomposition).


zero_cascade_components(M, S,
                        zero_cascade_components(Base, MinuendDigits, SubtrahendDigits,
                                                ZeroPositions, DonorPosition, DonorDigit, Result)) :-
    current_cgi_base(Base),
    integer_to_recollection(M, RecM),
    integer_to_recollection(S, RecS),
    \+ greater_than(RecS, RecM),
    digits_lsd(M, Base, RawMinuendDigits),
    digits_lsd(S, Base, RawSubtrahendDigits),
    length(RawMinuendDigits, ColumnCount),
    pad_digits(RawSubtrahendDigits, ColumnCount, SubtrahendDigits),
    MinuendDigits = RawMinuendDigits,
    MinuendDigits = [MinuendOnes|HigherMinuendDigits],
    SubtrahendDigits = [SubtrahendOnes|_],
    MinuendOnes < SubtrahendOnes,
    find_zero_cascade(HigherMinuendDigits, 1, [], RevZeroPositions, DonorPosition, DonorDigit),
    reverse(RevZeroPositions, ZeroPositions),
    subtract_ints(M, S, Result),
    incur_cost(action_zero_cascade_components).


find_zero_cascade([0|Rest], Position, Acc, ZeroPositions, DonorPosition, DonorDigit) :-
    NextPosition is Position + 1,
    find_zero_cascade(Rest, NextPosition, [Position|Acc], ZeroPositions, DonorPosition, DonorDigit).
find_zero_cascade([Digit|_Rest], Position, Acc, Acc, Position, Digit) :-
    Digit > 0,
    Acc \= [].


zero_cascade_no_cascade_result(
    zero_cascade_components(Base, MinuendDigits, SubtrahendDigits, ZeroPositions, _DonorPosition, _DonorDigit, _Expected),
    DeformedDigits,
    Result
) :-
    MinuendDigits = [MinuendOnes|_],
    SubtrahendDigits = [SubtrahendOnes|_],
    OnesResult is MinuendOnes + Base - SubtrahendOnes,
    length(MinuendDigits, ColumnCount),
    no_cascade_digits(0, ColumnCount, Base, MinuendDigits, SubtrahendDigits,
                      ZeroPositions, OnesResult, DeformedDigits),
    digits_to_int_lsd(DeformedDigits, Base, Result).


no_cascade_digits(Position, ColumnCount, _Base, _MinuendDigits, _SubtrahendDigits,
                  _ZeroPositions, _OnesResult, []) :-
    Position >= ColumnCount,
    !.
no_cascade_digits(Position, ColumnCount, Base, MinuendDigits, SubtrahendDigits,
                  ZeroPositions, OnesResult, [Digit|RestDigits]) :-
    Position < ColumnCount,
    nth0(Position, MinuendDigits, MinuendDigit),
    nth0(Position, SubtrahendDigits, SubtrahendDigit),
    (   Position =:= 0
    ->  Digit = OnesResult
    ;   member(Position, ZeroPositions)
    ->  Digit is (Base - 1) - SubtrahendDigit
    ;   Digit is MinuendDigit - SubtrahendDigit
    ),
    Digit >= 0,
    NextPosition is Position + 1,
    no_cascade_digits(NextPosition, ColumnCount, Base, MinuendDigits, SubtrahendDigits,
                      ZeroPositions, OnesResult, RestDigits).


digits_lsd(N, Base, [N]) :-
    N < Base,
    !.
digits_lsd(N, Base, [Ones|RestDigits]) :-
    N >= Base,
    Ones is N mod Base,
    Rest is N // Base,
    digits_lsd(Rest, Base, RestDigits).


pad_digits(Digits, TargetLength, PaddedDigits) :-
    length(Digits, CurrentLength),
    PadCount is TargetLength - CurrentLength,
    pad_digits_(PadCount, Digits, PaddedDigits).


pad_digits_(PadCount, Digits, Digits) :-
    PadCount =< 0,
    !.
pad_digits_(PadCount, Digits, PaddedDigits) :-
    PadCount > 0,
    NextPadCount is PadCount - 1,
    append(Digits, [0], NextDigits),
    pad_digits_(NextPadCount, NextDigits, PaddedDigits).


digits_to_int_lsd(Digits, Base, Result) :-
    digits_to_int_lsd_(Digits, Base, 1, 0, Result).


digits_to_int_lsd_([], _Base, _Place, Result, Result).
digits_to_int_lsd_([Digit|RestDigits], Base, Place, Acc, Result) :-
    Addend is Digit * Place,
    NextAcc is Acc + Addend,
    NextPlace is Place * Base,
    digits_to_int_lsd_(RestDigits, Base, NextPlace, NextAcc, Result).


abs_diff_ints(A, B, Diff) :-
    integer_to_recollection(A, RecA),
    integer_to_recollection(B, RecB),
    (   greater_than(RecA, RecB)
    ->  subtract_grounded(RecA, RecB, RecDiff)
    ;   subtract_grounded(RecB, RecA, RecDiff)
    ),
    recollection_to_integer(RecDiff, Diff).


decomposition_components(M, S, decomposition_components(Base, MinuendBases, MinuendOnes,
                                                        SubtrahendBases, SubtrahendOnes,
                                                        BasesAfterSubtraction, BorrowedBases,
                                                        ExchangedOnes, OnesAfterSubtraction,
                                                        Result)) :-
    current_cgi_base(Base),
    integer_to_recollection(M, RecM),
    integer_to_recollection(S, RecS),
    \+ greater_than(RecS, RecM),
    integer_to_recollection(Base, RecBase),
    base_decompose_grounded(RecM, RecBase, RecMinuendBases, RecMinuendOnes),
    base_decompose_grounded(RecS, RecBase, RecSubtrahendBases, RecSubtrahendOnes),
    greater_than(RecSubtrahendOnes, RecMinuendOnes),
    recollection_to_integer(RecMinuendBases, MinuendBases),
    recollection_to_integer(RecMinuendOnes, MinuendOnes),
    recollection_to_integer(RecSubtrahendBases, SubtrahendBases),
    recollection_to_integer(RecSubtrahendOnes, SubtrahendOnes),
    subtract_grounded(RecMinuendBases, RecSubtrahendBases, RecBasesAfterSubtraction),
    predecessor(RecBasesAfterSubtraction, RecBorrowedBases),
    add_grounded(RecMinuendOnes, RecBase, RecExchangedOnes),
    subtract_grounded(RecExchangedOnes, RecSubtrahendOnes, RecOnesAfterSubtraction),
    recollection_to_integer(RecBasesAfterSubtraction, BasesAfterSubtraction),
    recollection_to_integer(RecBorrowedBases, BorrowedBases),
    recollection_to_integer(RecExchangedOnes, ExchangedOnes),
    recollection_to_integer(RecOnesAfterSubtraction, OnesAfterSubtraction),
    multiply_ints(BorrowedBases, Base, RecombinedBases),
    add_ints(RecombinedBases, OnesAfterSubtraction, Result),
    incur_cost(action_decomposition_components).


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


successor_count(N, NextN) :-
    integer_to_recollection(N, RecN),
    successor(RecN, RecNext),
    recollection_to_integer(RecNext, NextN).


% add_ints/3, subtract_ints/3, multiply_ints/3 imported from math(integer_helpers).
