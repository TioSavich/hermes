/** <module> Division strategy/deformation action pairs
 *
 * This module extends the "actions over vocabularies" layer to division.
 * The main division distinction is whether the divisor is coordinated as a
 * group size to be measured off or as a number of groups for fair sharing.
 *
 * First division slice:
 *   - measuring groups of a given size;
 *   - the share-into-divisor-groups deformation;
 *   - fair sharing into equal groups;
 *   - the group-count-as-share-size deformation;
 *   - missing-factor repeated addition;
 *   - the reached-total-as-quotient deformation;
 *   - inverse-fact decomposition;
 *   - the stop-after-one-known-fact deformation;
 *   - partial-quotient chunking;
 *   - the first-partial-quotient stopping deformation;
 *   - exact known-product missing-factor search;
 *   - stopping at a nearby product in that search;
 *   - rejecting a contextualized known-product match;
 *   - coordinated long division (elaborates the `smr_div_long` FSM);
 *   - Benny's Rule 1 collapse, which replaces the coordinated
 *     divide/multiply/subtract loop with a single dividend+divisor sum
 *     (Erlwanger 1973; reviewed in Leatham and Winiecke 2014).
 *
 * Long division is the paradigm case of an *algorithmically elaborated*
 * ability (Brandom, Between Saying and Doing): the complex ability is
 * specified by a control structure over primitive abilities (single-digit
 * multiply for quotient-digit estimation, subtract-with-borrow for the
 * partial dividend). The productive automaton wraps the coordinated FSM in
 * `smr_div_long`; the deformation is the surface-syntactic collapse the FSM
 * docstring names as its companion.
 */

:- module(smr_div_action_pairs,
          [ run_division_action/5,
            division_action_cluster/2,
            division_action_vocabulary/2,
            productive_division_deformation/3,
            division_action_misconception_hook/3
          ]).

:- use_module(formalization(grounded_arithmetic),
              [ add_grounded/3,
                subtract_grounded/3,
                multiply_grounded/3,
                greater_than/2,
                smaller_than/2,
                successor/2,
                integer_to_recollection/2,
                recollection_to_integer/2,
                incur_cost/1
              ]).
:- use_module(formalization(grounded_utils),
              [ base_decompose_grounded/4,
                is_zero_grounded/1
              ]).
:- use_module(math(smr_div_cbo), [run_cbo_div/5]).
:- use_module(math(smr_div_dealing_by_ones), [run_dealing_by_ones/4]).
:- use_module(math(smr_div_ucr), [run_ucr/4]).
:- use_module(math(smr_div_idp), [run_idp/5]).
:- use_module(math(smr_div_long), [run_long_division_string/5]).
:- use_module(math(cgi_base), [current_cgi_base/1]).
:- use_module(math(integer_helpers), [add_ints/3, subtract_ints/3, multiply_ints/3]).


%!  run_division_action(+Kind, +Total, +Divisor, -Outcome, -Trace) is semidet.
%
%   Execute a productive or deformed division action automaton.
run_division_action(measure_groups_of_size, Total, GroupSize, Outcome, Trace) :-
    current_cgi_base(Base),
    run_cbo_div(Total, GroupSize, Base, ExistingQuotient, ExistingRemainder),
    division_components(Total, GroupSize, Components),
    Components = division_components(GroupSize, Quotient, Remainder),
    measurement_remainders(Total, GroupSize, Remainders),
    Outcome = action_outcome(
                  measure_groups_of_size,
                  [ classification(productive),
                    cluster(division_grouping_structures),
                    automaton_state(measurement_grouping),
                    vocabulary([total, group_size, measured_group, quotient, remainder]),
                    result(quotient_remainder(Quotient, Remainder)),
                    expected(quotient_remainder(ExistingQuotient, ExistingRemainder)),
                    validity(correct),
                    components(Components),
                    elaborates(smr_div_cbo:run_cbo_div/5)
                  ]),
    Trace = [ set_group_size(GroupSize),
              repeatedly_remove_group_size(Total, GroupSize, Remainders),
              count_measured_groups(Quotient),
              preserve_leftover_as_remainder(Remainder),
              name_quotient_and_remainder(Quotient, Remainder)
            ].
run_division_action(share_into_divisor_groups, Total, Divisor, Outcome, Trace) :-
    division_components(Total, Divisor, Components),
    Components = division_components(Divisor, Quotient, Remainder),
    Remainder > 0,
    run_dealing_by_ones(Total, Divisor, SharedResult, ExistingTrace),
    Outcome = action_outcome(
                  share_into_divisor_groups,
                  [ classification(deformation),
                    cluster(division_grouping_structures),
                    automaton_state(measurement_grouping),
                    vocabulary([total, group_size, measured_group, quotient, remainder]),
                    result(SharedResult),
                    expected(quotient_remainder(Quotient, Remainder)),
                    validity(incorrect),
                    components(Components),
                    deformation_of(measure_groups_of_size),
                    misconception_family(divisor_as_number_of_groups),
                    evidence(existing_trace(ExistingTrace))
                  ]),
    Trace = [ set_group_size(Divisor),
              reinterpret_divisor_as_number_of_groups(Divisor),
              deal_total_into_groups(Total, Divisor),
              name_items_in_first_group_as_number_of_groups(SharedResult),
              lose_measurement_remainder(expected(quotient_remainder(Quotient, Remainder)),
                                         produced(SharedResult))
            ].
run_division_action(fair_share_equal_groups, Total, GroupCount, Outcome, Trace) :-
    run_dealing_by_ones(Total, GroupCount, ExistingResult, ExistingTrace),
    division_components(Total, GroupCount, Components),
    Components = division_components(GroupCount, ShareSize, 0),
    sharing_rounds(ShareSize, GroupCount, Rounds),
    Outcome = action_outcome(
                  fair_share_equal_groups,
                  [ classification(productive),
                    cluster(division_grouping_structures),
                    automaton_state(partitive_fair_share),
                    vocabulary([total, number_of_groups, share_size, dealing_round, equality]),
                    result(ShareSize),
                    expected(ExistingResult),
                    validity(correct),
                    components(Components),
                    elaborates(smr_div_dealing_by_ones:run_dealing_by_ones/4),
                    evidence(existing_trace(ExistingTrace))
                  ]),
    Trace = [ set_number_of_groups(GroupCount),
              deal_one_to_each_group_by_rounds(Rounds),
              preserve_equal_shares(GroupCount, ShareSize),
              name_items_per_group(ShareSize)
            ].
run_division_action(name_group_count_as_share_size, Total, GroupCount, Outcome, Trace) :-
    division_components(Total, GroupCount, Components),
    Components = division_components(GroupCount, ShareSize, 0),
    Result = GroupCount,
    Outcome = action_outcome(
                  name_group_count_as_share_size,
                  [ classification(deformation),
                    cluster(division_grouping_structures),
                    automaton_state(partitive_fair_share),
                    vocabulary([total, number_of_groups, share_size, dealing_round, equality]),
                    result(Result),
                    expected(ShareSize),
                    validity(incorrect),
                    components(Components),
                    deformation_of(fair_share_equal_groups),
                    misconception_family(group_count_as_share_size)
                  ]),
    Trace = [ set_number_of_groups(GroupCount),
              confuse_number_of_groups_with_share_size(GroupCount),
              name_group_count_as_answer(Result),
              lose_items_per_group(expected(ShareSize), produced(Result))
            ].
run_division_action(missing_factor_repeated_addition, Total, Factor, Outcome, Trace) :-
    run_ucr(Total, Factor, ExistingResult, ExistingTrace),
    division_components(Total, Factor, Components),
    Components = division_components(Factor, Quotient, 0),
    repeated_multiple_totals(Factor, Quotient, Totals),
    Outcome = action_outcome(
                  missing_factor_repeated_addition,
                  [ classification(productive),
                    cluster(division_grouping_structures),
                    automaton_state(missing_factor_iteration),
                    vocabulary([total, factor, repeated_multiple, iteration_count, quotient]),
                    result(Quotient),
                    expected(ExistingResult),
                    validity(correct),
                    components(Components),
                    repeated_totals(Totals),
                    elaborates(smr_div_ucr:run_ucr/4),
                    evidence(existing_trace(ExistingTrace))
                  ]),
    Trace = [ set_factor(Factor),
              count_by_factor_until_total(Factor, Totals),
              name_iteration_count_as_quotient(Quotient),
              preserve_missing_factor_relation(Factor, Quotient, Total)
            ].
run_division_action(name_reached_total_as_quotient, Total, Factor, Outcome, Trace) :-
    division_components(Total, Factor, Components),
    Components = division_components(Factor, Quotient, 0),
    repeated_multiple_totals(Factor, Quotient, Totals),
    Result = Total,
    Outcome = action_outcome(
                  name_reached_total_as_quotient,
                  [ classification(deformation),
                    cluster(division_grouping_structures),
                    automaton_state(missing_factor_iteration),
                    vocabulary([total, factor, repeated_multiple, iteration_count, quotient]),
                    result(Result),
                    expected(Quotient),
                    validity(incorrect),
                    components(Components),
                    repeated_totals(Totals),
                    deformation_of(missing_factor_repeated_addition),
                    misconception_family(total_as_missing_factor)
                  ]),
    Trace = [ set_factor(Factor),
              count_by_factor_until_total(Factor, Totals),
              name_reached_total_as_answer(Total),
              lose_iteration_count(expected(Quotient), produced(Result))
            ].
run_division_action(inverse_fact_decomposition, Total, Divisor, Outcome, Trace) :-
    known_division_kb(Divisor, KB),
    run_idp(Total, Divisor, KB, ExistingQuotient, ExistingRemainder),
    inverse_fact_components(Total, Divisor, KB, Components),
    Components = inverse_fact_components(Steps, Quotient, Remainder),
    Outcome = action_outcome(
                  inverse_fact_decomposition,
                  [ classification(productive),
                    cluster(division_grouping_structures),
                    automaton_state(inverse_fact_decomposition),
                    vocabulary([known_multiple, partial_quotient, remaining_total, recomposition]),
                    result(quotient_remainder(Quotient, Remainder)),
                    expected(quotient_remainder(ExistingQuotient, ExistingRemainder)),
                    validity(correct),
                    components(Components),
                    knowledge_base(KB),
                    elaborates(smr_div_idp:run_idp/5)
                  ]),
    Trace = [ load_known_multiples(Divisor, KB),
              apply_known_multiple_facts(Steps),
              accumulate_partial_quotients(Quotient),
              name_fact_decomposition_result(Quotient, Remainder)
            ].
run_division_action(stop_after_one_known_fact, Total, Divisor, Outcome, Trace) :-
    known_division_kb(Divisor, KB),
    inverse_fact_components(Total, Divisor, KB, Components),
    Components = inverse_fact_components([FirstStep|_Rest], Quotient, Remainder),
    FirstStep = known_fact(Multiple, Factor, RemainingAfterFirst, QuotientAfterFirst),
    RemainingAfterFirst > 0,
    Result = quotient_remainder(QuotientAfterFirst, RemainingAfterFirst),
    Expected = quotient_remainder(Quotient, Remainder),
    Outcome = action_outcome(
                  stop_after_one_known_fact,
                  [ classification(deformation),
                    cluster(division_grouping_structures),
                    automaton_state(inverse_fact_decomposition),
                    vocabulary([known_multiple, partial_quotient, remaining_total, recomposition]),
                    result(Result),
                    expected(Expected),
                    validity(incorrect),
                    components(Components),
                    knowledge_base(KB),
                    deformation_of(inverse_fact_decomposition),
                    misconception_family(stops_after_single_inverse_fact)
                  ]),
    Trace = [ load_known_multiples(Divisor, KB),
              apply_first_known_multiple_only(Multiple, Factor),
              stop_with_remaining_total(RemainingAfterFirst),
              name_partial_quotient_and_remainder(Result),
              lose_iterative_fact_decomposition(expected(Expected), produced(Result))
            ].
run_division_action(partial_quotient_chunking, Total, Divisor, Outcome, Trace) :-
    division_components(Total, Divisor, division_components(Divisor, ExpectedQuotient, ExpectedRemainder)),
    partial_quotient_components(Total, Divisor, Components),
    Components = partial_quotient_components(Steps, Quotient, Remainder),
    Outcome = action_outcome(
                  partial_quotient_chunking,
                  [ classification(productive),
                    cluster(division_partial_quotients),
                    automaton_state(partial_quotient_chunking),
                    vocabulary([partial_multiple, partial_quotient, remaining_total, quotient_recomposition]),
                    result(quotient_remainder(Quotient, Remainder)),
                    expected(quotient_remainder(ExpectedQuotient, ExpectedRemainder)),
                    validity(correct),
                    components(Components),
                    divisor(Divisor)
                  ]),
    Trace = [ set_divisor_as_chunk_unit(Divisor),
              choose_partial_quotient_multiples(Steps),
              subtract_partial_multiples(Steps),
              accumulate_partial_quotients(Quotient),
              name_partial_quotient_result(Quotient, Remainder)
            ].
run_division_action(stop_after_first_partial_quotient, Total, Divisor, Outcome, Trace) :-
    partial_quotient_components(Total, Divisor, Components),
    Components = partial_quotient_components([FirstStep|_Rest], Quotient, Remainder),
    FirstStep = partial_quotient_step(Multiple, PartialQuotient, RemainingAfterFirst, QuotientAfterFirst),
    RemainingAfterFirst > 0,
    Result = quotient_remainder(QuotientAfterFirst, RemainingAfterFirst),
    Expected = quotient_remainder(Quotient, Remainder),
    Outcome = action_outcome(
                  stop_after_first_partial_quotient,
                  [ classification(deformation),
                    cluster(division_partial_quotients),
                    automaton_state(partial_quotient_chunking),
                    vocabulary([partial_multiple, partial_quotient, remaining_total, quotient_recomposition]),
                    result(Result),
                    expected(Expected),
                    validity(incorrect),
                    components(Components),
                    divisor(Divisor),
                    deformation_of(partial_quotient_chunking),
                    misconception_family(stops_after_first_partial_quotient)
                  ]),
    Trace = [ set_divisor_as_chunk_unit(Divisor),
              choose_first_partial_multiple(Multiple, PartialQuotient),
              subtract_first_partial_multiple(RemainingAfterFirst),
              stop_before_recomposing_remaining_total(RemainingAfterFirst),
              name_incomplete_partial_quotient(Result),
              lose_partial_quotient_recomposition(expected(Expected), produced(Result))
            ].
run_division_action(missing_factor_known_product_search, Total, Divisor, Outcome, Trace) :-
    known_product_search_components(Total, Divisor, Components),
    Components = known_product_search_components(Trials, Quotient, 0),
    Outcome = action_outcome(
                  missing_factor_known_product_search,
                  [ classification(productive),
                    cluster(division_missing_factor_relations),
                    automaton_state(known_product_search),
                    vocabulary([dividend, divisor, candidate_factor, product_trial, missing_factor, quotient]),
                    result(Quotient),
                    expected(Quotient),
                    validity(correct),
                    components(Components),
                    divisor(Divisor),
                    invariant(match_dividend_as_product)
                  ]),
    Trace = [ set_division_as_missing_factor(Total, Divisor),
              test_candidate_products(Trials),
              locate_matching_product(Divisor, Quotient, Total),
              name_missing_factor_as_quotient(Quotient)
            ].
run_division_action(stop_at_nearby_product_in_search, Total, Divisor, Outcome, Trace) :-
    known_product_search_components(Total, Divisor, Components),
    Components = known_product_search_components(Trials, Quotient, 0),
    last_low_product_trial(Trials, product_trial(NearFactor, NearProduct, low)),
    subtract_ints(Total, NearProduct, Remaining),
    Remaining > 0,
    Result = quotient_remainder(NearFactor, Remaining),
    Outcome = action_outcome(
                  stop_at_nearby_product_in_search,
                  [ classification(deformation),
                    cluster(division_missing_factor_relations),
                    automaton_state(known_product_search),
                    vocabulary([dividend, divisor, candidate_factor, product_trial, missing_factor, quotient]),
                    result(Result),
                    expected(Quotient),
                    validity(incorrect),
                    components(Components),
                    divisor(Divisor),
                    deformation_of(missing_factor_known_product_search),
                    misconception_family(stops_at_nearby_missing_factor_product)
                  ]),
    Trace = [ set_division_as_missing_factor(Total, Divisor),
              test_candidate_products_until_nearby(Trials, product_trial(NearFactor, NearProduct, low)),
              stop_before_matching_product(Total, NearProduct, Remaining),
              name_nearby_factor_and_remainder(Result),
              lose_exact_missing_factor(expected(Quotient), produced(Result))
            ].
run_division_action(reject_known_product_match, Total, Divisor, Outcome, Trace) :-
    known_product_search_components(Total, Divisor, Components),
    Components = known_product_search_components(Trials, Quotient, 0),
    Outcome = action_outcome(
                  reject_known_product_match,
                  [ classification(deformation),
                    cluster(division_missing_factor_relations),
                    automaton_state(known_product_search),
                    vocabulary([dividend, divisor, candidate_factor, product_trial, missing_factor, quotient]),
                    result(rejected_known_product(Divisor, Quotient, Total)),
                    expected(Quotient),
                    validity(incorrect),
                    components(Components),
                    divisor(Divisor),
                    deformation_of(missing_factor_known_product_search),
                    misconception_family(rejects_contextualized_known_product)
                  ]),
    Trace = [ set_division_as_missing_factor(Total, Divisor),
              test_candidate_products(Trials),
              locate_matching_product(Divisor, Quotient, Total),
              reject_product_match_as_not_contextualized(Divisor, Quotient, Total),
              lose_known_product_context(expected(Quotient),
                                         produced(rejected_known_product(Divisor, Quotient, Total)))
            ].
run_division_action(long_division, Total, Divisor, Outcome, Trace) :-
    % Productive: elaborate the coordinated long-division FSM. The FSM
    % coordinates primitive abilities (trial multiplication for the
    % quotient digit, subtract-with-borrow for the partial dividend) by
    % place value; it continues past the decimal point when the integer
    % stage leaves a nonzero partial (so 96/4 -> "24", 150/8 -> "18.75").
    run_long_division_string(Total, Divisor, QuotientString, Remainder, FsmHistory),
    division_components(Total, Divisor, division_components(Divisor, IntQuotient, IntRemainder)),
    Result = long_division_result(QuotientString, Remainder),
    Outcome = action_outcome(
                  long_division,
                  [ classification(productive),
                    cluster(division_long_division),
                    automaton_state(coordinated_long_division),
                    vocabulary([dividend, divisor, partial_dividend, quotient_digit,
                                bring_down, place_value_column]),
                    result(Result),
                    expected(Result),
                    validity(correct),
                    operands(dividend_divisor(Total, Divisor)),
                    components(division_components(Divisor, IntQuotient, IntRemainder)),
                    elaborates(smr_div_long:run_long_division_string/5),
                    invariant(coordinate_primitive_abilities_by_place_value),
                    evidence(existing_trace(FsmHistory))
                  ]),
    Trace = [ set_dividend_and_divisor(Total, Divisor),
              bring_down_dividend_digits_left_to_right,
              estimate_each_quotient_digit_by_trial_multiplication,
              subtract_partial_product_with_borrow_then_bring_down,
              emit_each_quotient_digit_at_its_place_value_column,
              name_quotient_and_remainder(Result)
            ].
run_division_action(sum_dividend_and_divisor, Total, Divisor, Outcome, Trace) :-
    % Deformation (Benny's Rule 1, Erlwanger 1973): collapse the coordinated
    % divide/multiply/subtract loop into a single addition of the two
    % numerals. The arithmetic (the sum) is valid; what is unlicensed is
    % reading that sum as Total / Divisor -- correct arithmetic pressed into
    % the wrong content. Matches the FSM docstring's named companion.
    % Provenance note: Erlwanger documents this rule for fraction-to-decimal
    % conversion; here only its division-by-addition core is transplanted onto
    % whole-number long division. This models the bare sum (96/4 -> 100) and
    % omits Benny's heuristic decimal-point placement, per that scope.
    division_components(Total, Divisor, division_components(Divisor, IntQuotient, IntRemainder)),
    add_ints(Total, Divisor, Sum),
    Result = digit_sum_numeral(Sum),
    Expected = quotient_remainder(IntQuotient, IntRemainder),
    Outcome = action_outcome(
                  sum_dividend_and_divisor,
                  [ classification(deformation),
                    cluster(division_long_division),
                    automaton_state(coordinated_long_division),
                    vocabulary([dividend, divisor, partial_dividend, quotient_digit,
                                bring_down, place_value_column]),
                    result(Result),
                    expected(Expected),
                    validity(incorrect),
                    operands(dividend_divisor(Total, Divisor)),
                    components(division_components(Divisor, IntQuotient, IntRemainder)),
                    deformation_of(long_division),
                    misconception_family(division_replaced_by_digit_sum)
                  ]),
    Trace = [ read_dividend_and_divisor_as_numerals(Total, Divisor),
              replace_coordinated_division_with_a_single_addition(Total, Divisor, Sum),
              collapse_the_bring_down_and_borrow_loop_to_one_step,
              name_digit_sum_as_answer(Result),
              lose_quotient_recomposition(expected(Expected), produced(Result))
            ].


%!  division_action_cluster(+Kind, -Cluster) is det.
division_action_cluster(measure_groups_of_size, division_grouping_structures).
division_action_cluster(share_into_divisor_groups, division_grouping_structures).
division_action_cluster(fair_share_equal_groups, division_grouping_structures).
division_action_cluster(name_group_count_as_share_size, division_grouping_structures).
division_action_cluster(missing_factor_repeated_addition, division_grouping_structures).
division_action_cluster(name_reached_total_as_quotient, division_grouping_structures).
division_action_cluster(inverse_fact_decomposition, division_grouping_structures).
division_action_cluster(stop_after_one_known_fact, division_grouping_structures).
division_action_cluster(partial_quotient_chunking, division_partial_quotients).
division_action_cluster(stop_after_first_partial_quotient, division_partial_quotients).
division_action_cluster(missing_factor_known_product_search, division_missing_factor_relations).
division_action_cluster(stop_at_nearby_product_in_search, division_missing_factor_relations).
division_action_cluster(reject_known_product_match, division_missing_factor_relations).
division_action_cluster(long_division, division_long_division).
division_action_cluster(sum_dividend_and_divisor, division_long_division).


%!  division_action_vocabulary(+Kind, -Vocabulary) is det.
division_action_vocabulary(measure_groups_of_size,
                           [total, group_size, measured_group, quotient, remainder]).
division_action_vocabulary(share_into_divisor_groups,
                           [total, group_size, measured_group, quotient, remainder]).
division_action_vocabulary(fair_share_equal_groups,
                           [total, number_of_groups, share_size, dealing_round, equality]).
division_action_vocabulary(name_group_count_as_share_size,
                           [total, number_of_groups, share_size, dealing_round, equality]).
division_action_vocabulary(missing_factor_repeated_addition,
                           [total, factor, repeated_multiple, iteration_count, quotient]).
division_action_vocabulary(name_reached_total_as_quotient,
                           [total, factor, repeated_multiple, iteration_count, quotient]).
division_action_vocabulary(inverse_fact_decomposition,
                           [known_multiple, partial_quotient, remaining_total, recomposition]).
division_action_vocabulary(stop_after_one_known_fact,
                           [known_multiple, partial_quotient, remaining_total, recomposition]).
division_action_vocabulary(partial_quotient_chunking,
                           [partial_multiple, partial_quotient, remaining_total, quotient_recomposition]).
division_action_vocabulary(stop_after_first_partial_quotient,
                           [partial_multiple, partial_quotient, remaining_total, quotient_recomposition]).
division_action_vocabulary(missing_factor_known_product_search,
                           [dividend, divisor, candidate_factor, product_trial, missing_factor, quotient]).
division_action_vocabulary(stop_at_nearby_product_in_search,
                           [dividend, divisor, candidate_factor, product_trial, missing_factor, quotient]).
division_action_vocabulary(reject_known_product_match,
                           [dividend, divisor, candidate_factor, product_trial, missing_factor, quotient]).
division_action_vocabulary(long_division,
                           [dividend, divisor, partial_dividend, quotient_digit, bring_down, place_value_column]).
division_action_vocabulary(sum_dividend_and_divisor,
                           [dividend, divisor, partial_dividend, quotient_digit, bring_down, place_value_column]).


%!  productive_division_deformation(+ProductiveKind, +DeformationKind, -MisconceptionFamily) is det.
productive_division_deformation(measure_groups_of_size,
                                share_into_divisor_groups,
                                divisor_as_number_of_groups).
productive_division_deformation(fair_share_equal_groups,
                                name_group_count_as_share_size,
                                group_count_as_share_size).
productive_division_deformation(missing_factor_repeated_addition,
                                name_reached_total_as_quotient,
                                total_as_missing_factor).
productive_division_deformation(inverse_fact_decomposition,
                                stop_after_one_known_fact,
                                stops_after_single_inverse_fact).
productive_division_deformation(partial_quotient_chunking,
                                stop_after_first_partial_quotient,
                                stops_after_first_partial_quotient).
productive_division_deformation(missing_factor_known_product_search,
                                stop_at_nearby_product_in_search,
                                stops_at_nearby_missing_factor_product).
productive_division_deformation(missing_factor_known_product_search,
                                reject_known_product_match,
                                rejects_contextualized_known_product).
productive_division_deformation(long_division,
                                sum_dividend_and_divisor,
                                division_replaced_by_digit_sum).


%!  division_action_misconception_hook(+Outcome, -Family, -Hook) is semidet.
division_action_misconception_hook(action_outcome(Kind, Fields), Family, Hook) :-
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
division_action_misconception_hook(action_outcome(Kind, Fields), Family, Hook) :-
    member(classification(productive), Fields),
    productive_division_deformation(Kind, DeformationKind, Family),
    member(vocabulary(Vocabulary), Fields),
    Hook = action_misconception_hook(
               [ productive_action(Kind),
                 nearby_deformation(DeformationKind),
                 family(Family),
                 vocabulary(Vocabulary),
                 monitoring_focus(preserve_action_invariants(Kind)),
                 evidence(Fields)
               ]).


division_components(Total, Divisor, division_components(Divisor, Quotient, Remainder)) :-
    positive_int(Divisor),
    integer_to_recollection(Total, RecTotal),
    integer_to_recollection(Divisor, RecDivisor),
    base_decompose_grounded(RecTotal, RecDivisor, RecQuotient, RecRemainder),
    recollection_to_integer(RecQuotient, Quotient),
    recollection_to_integer(RecRemainder, Remainder),
    incur_cost(action_division_components).


measurement_remainders(Total, GroupSize, Remainders) :-
    integer_to_recollection(Total, RecTotal),
    integer_to_recollection(GroupSize, RecGroupSize),
    measurement_remainders_(RecTotal, RecGroupSize, [], RevRemainders),
    reverse(RevRemainders, Remainders).

measurement_remainders_(Current, GroupSize, Acc, Remainders) :-
    smaller_than(Current, GroupSize),
    !,
    Remainders = Acc.
measurement_remainders_(Current, GroupSize, Acc, Remainders) :-
    subtract_grounded(Current, GroupSize, Next),
    recollection_to_integer(Next, NextInt),
    measurement_remainders_(Next, GroupSize, [NextInt|Acc], Remainders).


sharing_rounds(ShareSize, GroupCount, Rounds) :-
    sharing_rounds_(1, ShareSize, GroupCount, [], RevRounds),
    reverse(RevRounds, Rounds).

sharing_rounds_(Round, ShareSize, _GroupCount, Rounds, Rounds) :-
    Round > ShareSize,
    !.
sharing_rounds_(Round, ShareSize, GroupCount, Acc, Rounds) :-
    Round =< ShareSize,
    NextRound is Round + 1,
    sharing_rounds_(NextRound, ShareSize, GroupCount,
                    [deal_round(Round, groups(GroupCount))|Acc], Rounds).


repeated_multiple_totals(Factor, Quotient, Totals) :-
    repeated_multiple_totals_(Factor, Quotient, 0, [], RevTotals),
    reverse(RevTotals, Totals).

repeated_multiple_totals_(_Factor, 0, _Current, Totals, Totals) :- !.
repeated_multiple_totals_(Factor, Remaining, Current, Acc, Totals) :-
    Remaining > 0,
    add_ints(Current, Factor, Next),
    NextRemaining is Remaining - 1,
    repeated_multiple_totals_(Factor, NextRemaining, Next, [Next|Acc], Totals).


known_division_kb(Divisor, KB) :-
    findall(Multiple-Factor,
            ( member(Factor, [10,5,2,1]),
              multiply_ints(Divisor, Factor, Multiple)
            ),
            KB).


inverse_fact_components(Total, Divisor, KB, inverse_fact_components(Steps, Quotient, Remainder)) :-
    inverse_fact_steps(Total, Divisor, KB, 0, [], RevSteps, Quotient, Remainder),
    reverse(RevSteps, Steps),
    incur_cost(action_inverse_fact_components).


inverse_fact_steps(Remaining, Divisor, _KB, Quotient, Steps, Steps, Quotient, Remaining) :-
    integer_to_recollection(Remaining, RecRemaining),
    integer_to_recollection(Divisor, RecDivisor),
    smaller_than(RecRemaining, RecDivisor),
    !.
inverse_fact_steps(Remaining, Divisor, KB, QuotientSoFar, Acc, Steps, Quotient, Remainder) :-
    find_best_fact(KB, Remaining, Multiple, Factor),
    subtract_ints(Remaining, Multiple, NewRemaining),
    add_ints(QuotientSoFar, Factor, NewQuotient),
    Step = known_fact(Multiple, Factor, NewRemaining, NewQuotient),
    inverse_fact_steps(NewRemaining, Divisor, KB, NewQuotient, [Step|Acc], Steps, Quotient, Remainder).


find_best_fact([Multiple-Factor | _], Remaining, Multiple, Factor) :-
    integer_to_recollection(Multiple, RecMultiple),
    integer_to_recollection(Remaining, RecRemaining),
    \+ greater_than(RecMultiple, RecRemaining),
    !.
find_best_fact([_ | Rest], Remaining, Multiple, Factor) :-
    find_best_fact(Rest, Remaining, Multiple, Factor).


partial_quotient_components(Total, Divisor, partial_quotient_components(Steps, Quotient, Remainder)) :-
    known_division_kb(Divisor, KB),
    inverse_fact_components(Total, Divisor, KB, inverse_fact_components(KnownSteps, Quotient, Remainder)),
    maplist(partial_quotient_step_from_known, KnownSteps, Steps),
    incur_cost(action_partial_quotient_components).


partial_quotient_step_from_known(
    known_fact(Multiple, PartialQuotient, RemainingAfter, QuotientSoFar),
    partial_quotient_step(Multiple, PartialQuotient, RemainingAfter, QuotientSoFar)
).


known_product_search_components(Total, Divisor, known_product_search_components(Trials, Quotient, Remainder)) :-
    division_components(Total, Divisor, division_components(Divisor, Quotient, Remainder)),
    Remainder =:= 0,
    known_product_candidate_factors(Quotient, CandidateFactors),
    known_product_trials(Divisor, Total, CandidateFactors, Trials),
    member(product_trial(Quotient, Total, match), Trials),
    incur_cost(action_known_product_search_components).


known_product_candidate_factors(Quotient, CandidateFactors) :-
    benchmark_factor(Quotient, Benchmark),
    Mid is Benchmark + 5,
    findall(Candidate,
            ( member(Candidate, [Benchmark, Mid, Quotient]),
              Candidate > 0,
              Candidate =< Quotient
            ),
            RawCandidates),
    sort(RawCandidates, CandidateFactors).


benchmark_factor(Quotient, 10) :-
    Quotient > 10,
    !.
benchmark_factor(Quotient, 5) :-
    Quotient > 5,
    !.
benchmark_factor(Quotient, 2) :-
    Quotient > 2,
    !.
benchmark_factor(_Quotient, 1).


known_product_trials(_Divisor, _Total, [], []).
known_product_trials(Divisor, Total, [Factor|Rest], [product_trial(Factor, Product, Relation)|Trials]) :-
    multiply_ints(Divisor, Factor, Product),
    product_relation(Product, Total, Relation),
    known_product_trials(Divisor, Total, Rest, Trials).


product_relation(Product, Total, match) :-
    Product =:= Total,
    !.
product_relation(Product, Total, low) :-
    Product < Total,
    !.
product_relation(_Product, _Total, high).


last_low_product_trial(Trials, LowTrial) :-
    findall(Trial,
            member(Trial, Trials),
            LowTrials),
    include(low_product_trial, LowTrials, LowOnly),
    last(LowOnly, LowTrial).


low_product_trial(product_trial(_Factor, _Product, low)).


positive_int(N) :-
    integer_to_recollection(N, RecN),
    \+ is_zero_grounded(RecN).


% add_ints/3, subtract_ints/3, multiply_ints/3 imported from math(integer_helpers).
