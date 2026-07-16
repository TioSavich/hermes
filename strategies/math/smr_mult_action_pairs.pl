/** <module> Multiplicative strategy/deformation action pairs
 *
 * This module starts the multiplication side of the "actions over vocabularies"
 * layer. The central invariant is the composite unit: a group is both one
 * iterable unit and a bundle of items.
 *
 * First multiplication slice:
 *   - coordinating groups and items;
 *   - the additive-count deformation;
 *   - repeated equal groups;
 *   - the self-repeated group-size deformation;
 *   - distributive split into partial products;
 *   - the dropped-partial-product deformation;
 *   - regrouping into base-sized bundles;
 *   - the dropped-regrouping-remainder deformation;
 *   - known-product adjustment by one equal group;
 *   - the known-product-without-adjustment deformation;
 *   - commuted-factor product preservation;
 *   - rigid multiplier/multiplicand-role deformation;
 *   - sequential recomputation despite commuted-factor equivalence;
 *   - bound multiplication fact retrieval;
 *   - context-free fact-family guessing.
 */

:- module(smr_mult_action_pairs,
          [ run_multiplicative_action/5,
            multiplicative_action_cluster/2,
            multiplicative_action_vocabulary/2,
            productive_multiplicative_deformation/3,
            multiplicative_action_misconception_hook/3
          ]).

:- use_module(formalization(grounded_arithmetic),
              [ add_grounded/3,
                subtract_grounded/3,
                multiply_grounded/3,
                greater_than/2,
                smaller_than/2,
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
:- use_module(math(smr_mult_c2c), [run_c2c/4]).
:- use_module(math(smr_mult_commutative_reasoning), [run_commutative_mult/4]).
:- use_module(math(smr_mult_dr), [run_dr/4]).
:- use_module(math(smr_mult_cbo), [run_cbo_mult/5]).
:- use_module(math(cgi_base), [current_cgi_base/1]).
:- use_module(math(integer_helpers), [add_ints/3, multiply_ints/3]).


%!  run_multiplicative_action(+Kind, +N, +S, -Outcome, -Trace) is semidet.
%
%   Execute a productive or deformed multiplicative action automaton for
%   N groups of size S.
run_multiplicative_action(coordinate_groups_items, N, S, Outcome, Trace) :-
    run_c2c(N, S, ExistingResult, ExistingTrace),
    multiply_ints(N, S, Product),
    Outcome = action_outcome(
                  coordinate_groups_items,
                  [ classification(productive),
                    cluster(multiplicative_composite_units),
                    automaton_state(coordinating_two_counts),
                    vocabulary([group_count, item_count, composite_unit, total_items]),
                    result(Product),
                    expected(ExistingResult),
                    validity(correct),
                    groups(N),
                    items_per_group(S),
                    elaborates(smr_mult_c2c:run_c2c/4),
                    evidence(existing_trace(ExistingTrace))
                  ]),
    Trace = [ form_equal_groups(N, size(S)),
              coordinate_group_count_with_item_count(groups(N), items_per_group(S)),
              iterate_composite_unit(N, S, Product),
              name_total_items(Product)
            ].
run_multiplicative_action(add_counts_without_composite_unit, N, S, Outcome, Trace) :-
    multiply_ints(N, S, Expected),
    add_ints(N, S, Result),
    Outcome = action_outcome(
                  add_counts_without_composite_unit,
                  [ classification(deformation),
                    cluster(multiplicative_composite_units),
                    automaton_state(coordinating_two_counts),
                    vocabulary([group_count, item_count, composite_unit, total_items]),
                    result(Result),
                    expected(Expected),
                    validity(incorrect),
                    groups(N),
                    items_per_group(S),
                    deformation_of(coordinate_groups_items),
                    misconception_family(additive_count_for_multiplicative_structure)
                  ]),
    Trace = [ see_groups_and_items(groups(N), items_per_group(S)),
              count_groups_as_items(N),
              count_items_as_items(S),
              add_uncoordinated_counts(N, S, Result),
              lose_composite_unit(expected(Expected), produced(Result))
            ].
run_multiplicative_action(add_instead_of_multiply, N, S, Outcome, Trace) :-
    multiply_ints(N, S, Expected),
    add_ints(N, S, Result),
    Outcome = action_outcome(
                  add_instead_of_multiply,
                  [ classification(deformation),
                    cluster(multiplicative_composite_units),
                    automaton_state(substitute_addition_for_equal_group_iteration),
                    vocabulary([group_count, items_per_group, equal_groups,
                                addition, multiplication, operation_substitution,
                                composite_unit_loss]),
                    result(Result),
                    expected(Expected),
                    validity(incorrect),
                    groups(N),
                    items_per_group(S),
                    deformation_of(repeat_equal_groups),
                    misconception_family(addition_instead_of_multiplication)
                  ]),
    Trace = [ read_equal_groups(groups(N), items_per_group(S)),
              treat_group_count_and_group_size_as_addends,
              add_uncoordinated_counts(N, S, Result),
              lose_equal_group_iteration(expected(Expected), produced(Result))
            ].
run_multiplicative_action(repeat_equal_groups, N, S, Outcome, Trace) :-
    run_commutative_mult(N, S, ExistingResult, ExistingTrace),
    repeated_add_totals(S, N, Totals),
    multiply_ints(N, S, Product),
    Outcome = action_outcome(
                  repeat_equal_groups,
                  [ classification(productive),
                    cluster(multiplicative_composite_units),
                    automaton_state(repeated_addition),
                    vocabulary([equal_group, repeated_addend, iteration_count, running_product]),
                    result(Product),
                    expected(ExistingResult),
                    validity(correct),
                    groups(N),
                    items_per_group(S),
                    running_totals(Totals),
                    elaborates(smr_mult_commutative_reasoning:run_commutative_mult/4),
                    evidence(existing_trace(ExistingTrace))
                  ]),
    Trace = [ hold_group_size_as_repeated_addend(S),
              hold_number_of_groups_as_iterations(N),
              add_equal_group_repeatedly(S, N, Totals),
              name_accumulated_total(Product)
            ].
run_multiplicative_action(repeat_group_size_by_itself, N, S, Outcome, Trace) :-
    multiply_ints(N, S, Expected),
    repeated_add_totals(S, S, Totals),
    multiply_ints(S, S, Result),
    Outcome = action_outcome(
                  repeat_group_size_by_itself,
                  [ classification(deformation),
                    cluster(multiplicative_composite_units),
                    automaton_state(repeated_addition),
                    vocabulary([equal_group, repeated_addend, iteration_count, running_product]),
                    result(Result),
                    expected(Expected),
                    validity(incorrect),
                    groups(N),
                    items_per_group(S),
                    running_totals(Totals),
                    deformation_of(repeat_equal_groups),
                    misconception_family(role_confusion_repeats_size_by_itself)
                  ]),
    Trace = [ hold_group_size_as_repeated_addend(S),
              use_group_size_as_iteration_count(S),
              add_equal_group_repeatedly(S, S, Totals),
              lose_group_count_role(expected(Expected), produced(Result))
            ].
run_multiplicative_action(common_factor_intersection, A, B, Outcome, Trace) :-
    positive_integer(A),
    positive_integer(B),
    positive_divisors(A, FactorsA),
    positive_divisors(B, FactorsB),
    intersection(FactorsA, FactorsB, CommonFactors),
    last(CommonFactors, GreatestCommonFactor),
    Outcome = action_outcome(
                  common_factor_intersection,
                  [ classification(productive),
                    cluster(multiplicative_factor_multiple_search),
                    automaton_state(enumerate_divisors_then_intersect_sets),
                    vocabulary([factor, divisor, factor_pair, divisibility,
                                common_factor, intersection,
                                greatest_common_factor]),
                    input(numbers(A, B)), factors(A, FactorsA),
                    factors(B, FactorsB),
                    result(common_factors(CommonFactors,
                                          greatest(GreatestCommonFactor))),
                    expected(common_factors(CommonFactors,
                                            greatest(GreatestCommonFactor))),
                    invariant(each_common_factor_divides_both_numbers),
                    validity(correct)
                  ]),
    Trace = [ enumerate_positive_divisors(A, FactorsA),
              enumerate_positive_divisors(B, FactorsB),
              intersect_factor_sets(CommonFactors),
              select_greatest_common_factor(GreatestCommonFactor)
            ].
run_multiplicative_action(factors_of_first_number_only, A, B, Outcome, Trace) :-
    positive_integer(A),
    positive_integer(B),
    positive_divisors(A, FactorsA),
    positive_divisors(B, FactorsB),
    intersection(FactorsA, FactorsB, CommonFactors),
    FactorsA \== CommonFactors,
    last(CommonFactors, GreatestCommonFactor),
    Outcome = action_outcome(
                  factors_of_first_number_only,
                  [ classification(deformation),
                    cluster(multiplicative_factor_multiple_search),
                    automaton_state(stop_before_testing_divisors_against_second_number),
                    vocabulary([factor, divisor, common_factor, intersection,
                                one_set_only]),
                    input(numbers(A, B)),
                    result(common_factors(FactorsA)),
                    expected(common_factors(CommonFactors,
                                            greatest(GreatestCommonFactor))),
                    deformation_of(common_factor_intersection),
                    misconception_family(common_factors_from_one_number_only),
                    violated_invariant(each_common_factor_divides_both_numbers),
                    validity(incorrect)
                  ]),
    Trace = [ enumerate_positive_divisors(A, FactorsA),
              omit_divisor_search_for(B),
              omit_factor_set_intersection,
              report_first_factor_set_as_common(FactorsA)
            ].
run_multiplicative_action(common_multiple_sequence, A, B, Outcome, Trace) :-
    positive_integer(A),
    positive_integer(B),
    least_common_multiple(A, B, LCM),
    first_multiples(LCM, 5, Witnesses),
    Result = common_multiples(generator(step(LCM)), witnesses(Witnesses),
                              least(LCM)),
    Outcome = action_outcome(
                  common_multiple_sequence,
                  [ classification(productive),
                    cluster(multiplicative_factor_multiple_search),
                    automaton_state(find_least_common_multiple_then_iterate_it),
                    vocabulary([multiple, repeated_equal_group, divisibility,
                                common_multiple, least_common_multiple,
                                infinite_sequence, generator]),
                    input(numbers(A, B)), result(Result), expected(Result),
                    invariant(each_generated_value_is_divisible_by_both_numbers),
                    validity(correct)
                  ]),
    Trace = [ coordinate_multiples_of(A, B),
              locate_least_common_multiple(LCM),
              retain_lcm_as_composite_iteration_unit,
              iterate_common_multiple_generator(LCM, Witnesses)
            ].
run_multiplicative_action(add_numbers_as_common_multiple, A, B,
                          Outcome, Trace) :-
    positive_integer(A),
    positive_integer(B),
    Candidate is A + B,
    \+ divisible_by_both(Candidate, A, B),
    least_common_multiple(A, B, LCM),
    first_multiples(LCM, 5, Witnesses),
    Expected = common_multiples(generator(step(LCM)), witnesses(Witnesses),
                                least(LCM)),
    Outcome = action_outcome(
                  add_numbers_as_common_multiple,
                  [ classification(deformation),
                    cluster(multiplicative_factor_multiple_search),
                    automaton_state(add_inputs_instead_of_coordinating_multiple_sequences),
                    vocabulary([multiple, common_multiple, addition,
                                divisibility, operation_substitution]),
                    input(numbers(A, B)), result(candidate_common_multiple(Candidate)),
                    expected(Expected),
                    deformation_of(common_multiple_sequence),
                    misconception_family(sum_as_common_multiple),
                    violated_invariant(each_generated_value_is_divisible_by_both_numbers),
                    validity(incorrect)
                  ]),
    Trace = [ read_two_numbers(A, B),
              substitute_addition_for_multiple_generation,
              add_inputs(A, B, Candidate),
              omit_divisibility_check(Candidate)
            ].
run_multiplicative_action(distribute_group_size_split, N, S, Outcome, Trace) :-
    run_dr(N, S, ExistingResult, ExistingTrace),
    distributive_components(N, S, Components),
    Components = distributive_components(S1, S2, Partial1, Partial2, Product),
    Outcome = action_outcome(
                  distribute_group_size_split,
                  [ classification(productive),
                    cluster(multiplicative_composite_units),
                    automaton_state(distributive_reasoning),
                    vocabulary([group_size_split, partial_product, recomposition, conservation]),
                    result(Product),
                    expected(ExistingResult),
                    validity(correct),
                    groups(N),
                    items_per_group(S),
                    components(Components),
                    elaborates(smr_mult_dr:run_dr/4),
                    evidence(existing_trace(ExistingTrace))
                  ]),
    Trace = [ split_group_size(S, parts(S1, S2)),
              compute_partial_product(N, S1, Partial1),
              compute_partial_product(N, S2, Partial2),
              recompose_partial_products(Partial1, Partial2, Product),
              preserve_distributed_groups(Product)
            ].
run_multiplicative_action(drop_second_partial_product, N, S, Outcome, Trace) :-
    distributive_components(N, S, Components),
    Components = distributive_components(S1, S2, Partial1, Partial2, Product),
    S2 > 0,
    Result = Partial1,
    Outcome = action_outcome(
                  drop_second_partial_product,
                  [ classification(deformation),
                    cluster(multiplicative_composite_units),
                    automaton_state(distributive_reasoning),
                    vocabulary([group_size_split, partial_product, recomposition, conservation]),
                    result(Result),
                    expected(Product),
                    validity(incorrect),
                    groups(N),
                    items_per_group(S),
                    components(Components),
                    deformation_of(distribute_group_size_split),
                    misconception_family(dropped_partial_product)
                  ]),
    Trace = [ split_group_size(S, parts(S1, S2)),
              compute_partial_product(N, S1, Partial1),
              omit_partial_product(N, S2, Partial2),
              lose_distributed_part(expected(Product), produced(Result))
            ].
run_multiplicative_action(regroup_to_base_preserving_total, N, S, Outcome, Trace) :-
    current_cgi_base(Base),
    run_cbo_mult(N, S, Base, ExistingResult, ExistingTrace),
    regroup_components(N, S, Base, Components),
    Components = regroup_components(Product, BaseGroups, Leftover, FullBaseTotal),
    Outcome = action_outcome(
                  regroup_to_base_preserving_total,
                  [ classification(productive),
                    cluster(multiplicative_composite_units),
                    automaton_state(regroup_to_base),
                    vocabulary([equal_group, base_bundle, leftover, conservation]),
                    result(Product),
                    expected(ExistingResult),
                    validity(correct),
                    groups(N),
                    items_per_group(S),
                    base(Base),
                    components(Components),
                    elaborates(smr_mult_cbo:run_cbo_mult/5),
                    evidence(existing_trace(ExistingTrace))
                  ]),
    Trace = [ form_equal_groups(N, size(S)),
              regroup_total_as_base_bundles(base(Base), full_base_groups(BaseGroups), leftover(Leftover)),
              preserve_leftover_after_regrouping(Leftover),
              name_total_from_bundles_and_leftover(FullBaseTotal, Leftover, Product)
            ].
run_multiplicative_action(drop_regrouping_remainder, N, S, Outcome, Trace) :-
    current_cgi_base(Base),
    regroup_components(N, S, Base, Components),
    Components = regroup_components(Product, BaseGroups, Leftover, FullBaseTotal),
    Leftover > 0,
    Result = FullBaseTotal,
    Outcome = action_outcome(
                  drop_regrouping_remainder,
                  [ classification(deformation),
                    cluster(multiplicative_composite_units),
                    automaton_state(regroup_to_base),
                    vocabulary([equal_group, base_bundle, leftover, conservation]),
                    result(Result),
                    expected(Product),
                    validity(incorrect),
                    groups(N),
                    items_per_group(S),
                    base(Base),
                    components(Components),
                    deformation_of(regroup_to_base_preserving_total),
                    misconception_family(dropped_leftover_after_regrouping)
                  ]),
    Trace = [ form_equal_groups(N, size(S)),
              regroup_total_as_base_bundles(base(Base), full_base_groups(BaseGroups), leftover(Leftover)),
              drop_regrouping_leftover(Leftover),
              name_only_full_base_bundles(Result),
              lose_regrouping_remainder(expected(Product), produced(Result))
            ].
run_multiplicative_action(known_product_adjustment, N, S, Outcome, Trace) :-
    known_product_adjustment_components(N, S, Components),
    Components = known_product_adjustment_components(BaseGroups, GroupSize, BaseProduct, ExtraGroups, ExtraProduct, Product),
    Outcome = action_outcome(
                  known_product_adjustment,
                  [ classification(productive),
                    cluster(multiplicative_fact_adjustment),
                    automaton_state(adjusting_nearby_product),
                    vocabulary([benchmark_fact, known_product, equal_group, adjustment, product]),
                    result(Product),
                    expected(Product),
                    validity(correct),
                    groups(N),
                    items_per_group(S),
                    components(Components),
                    invariant(add_missing_equal_group)
                  ]),
    Trace = [ recall_nearby_known_product(BaseGroups, GroupSize, BaseProduct),
              identify_missing_equal_groups(N, BaseGroups, ExtraGroups),
              compute_extra_equal_group_product(ExtraGroups, GroupSize, ExtraProduct),
              adjust_known_product(BaseProduct, ExtraProduct, Product),
              preserve_equal_group_adjustment(Product)
            ].
run_multiplicative_action(known_product_without_adjustment, N, S, Outcome, Trace) :-
    known_product_adjustment_components(N, S, Components),
    Components = known_product_adjustment_components(BaseGroups, GroupSize, BaseProduct, ExtraGroups, ExtraProduct, Product),
    Result = BaseProduct,
    Outcome = action_outcome(
                  known_product_without_adjustment,
                  [ classification(deformation),
                    cluster(multiplicative_fact_adjustment),
                    automaton_state(adjusting_nearby_product),
                    vocabulary([benchmark_fact, known_product, equal_group, adjustment, product]),
                    result(Result),
                    expected(Product),
                    validity(incorrect),
                    groups(N),
                    items_per_group(S),
                    components(Components),
                    deformation_of(known_product_adjustment),
                    misconception_family(omitted_known_product_adjustment)
                  ]),
    Trace = [ recall_nearby_known_product(BaseGroups, GroupSize, BaseProduct),
              identify_missing_equal_groups(N, BaseGroups, ExtraGroups),
              omit_extra_equal_group_product(ExtraGroups, GroupSize, ExtraProduct),
              answer_with_nearby_product(Result),
              lose_equal_group_adjustment(expected(Product), produced(Result))
            ].
run_multiplicative_action(commute_factors_preserve_product, N, S, Outcome, Trace) :-
    commuted_product_components(N, S, Components),
    Components = commuted_product_components(N, S, Product, S, N, Product),
    Outcome = action_outcome(
                  commute_factors_preserve_product,
                  [ classification(productive),
                    cluster(multiplicative_factor_relations),
                    automaton_state(preserving_product_under_commutation),
                    vocabulary([factor_order, commutativity, equal_groups, product, equivalence]),
                    result(Product),
                    expected(Product),
                    validity(correct),
                    groups(N),
                    items_per_group(S),
                    components(Components),
                    invariant(product_preserved_under_factor_order)
                  ]),
    Trace = [ compare_factor_orders(original(N, S), commuted(S, N)),
              compute_original_product(N, S, Product),
              commute_factors(S, N),
              compute_commuted_product(S, N, Product),
              preserve_product_under_commutation(Product)
            ].
run_multiplicative_action(rigid_factor_order_roles, N, S, Outcome, Trace) :-
    commuted_product_components(N, S, Components),
    Components = commuted_product_components(N, S, Product, S, N, Product),
    Outcome = action_outcome(
                  rigid_factor_order_roles,
                  [ classification(deformation),
                    cluster(multiplicative_factor_relations),
                    automaton_state(preserving_product_under_commutation),
                    vocabulary([factor_order, commutativity, equal_groups, product, equivalence]),
                    result(rejected_commutation(S, N)),
                    expected(Product),
                    validity(incorrect),
                    groups(N),
                    items_per_group(S),
                    components(Components),
                    deformation_of(commute_factors_preserve_product),
                    misconception_family(fixed_multiplier_multiplicand_roles)
                  ]),
    Trace = [ compare_factor_orders(original(N, S), commuted(S, N)),
              keep_multiplier_multiplicand_roles_fixed(N, S),
              reject_commuted_factor_order(S, N),
              require_recomputation_in_original_order(Product),
              lose_factor_order_equivalence(expected(Product), produced(rejected_commutation(S, N)))
            ].
run_multiplicative_action(sequential_recompute_commuted_products, N, S, Outcome, Trace) :-
    commuted_product_components(N, S, Components),
    Components = commuted_product_components(N, S, Product, S, N, Product),
    Outcome = action_outcome(
                  sequential_recompute_commuted_products,
                  [ classification(deformation),
                    cluster(multiplicative_factor_relations),
                    automaton_state(preserving_product_under_commutation),
                    vocabulary([factor_order, commutativity, equal_groups, product, equivalence]),
                    result(recomputed_both_products(Product, Product)),
                    expected(structural_equivalence(Product)),
                    validity(incorrect),
                    groups(N),
                    items_per_group(S),
                    components(Components),
                    deformation_of(commute_factors_preserve_product),
                    misconception_family(procedural_recompute_when_commutation_available)
                  ]),
    Trace = [ compare_factor_orders(original(N, S), commuted(S, N)),
              miss_structural_commutative_equivalence,
              compute_original_product(N, S, Product),
              compute_commuted_product(S, N, Product),
              compare_final_products(Product, Product),
              lose_commutative_shortcut(expected(structural_equivalence(Product)),
                                        produced(recomputed_both_products(Product, Product)))
            ].
run_multiplicative_action(multiplication_fact_retrieval, N, S, Outcome, Trace) :-
    multiply_ints(N, S, Product),
    Outcome = action_outcome(
                  multiplication_fact_retrieval,
                  [ classification(productive),
                    cluster(multiplicative_fact_family),
                    automaton_state(retrieving_known_product),
                    vocabulary([factor_pair, known_fact, product, fact_family, referent_units]),
                    result(Product),
                    expected(Product),
                    validity(correct),
                    groups(N),
                    items_per_group(S),
                    components(fact_family_components(N, S, Product)),
                    invariant(bind_fact_to_referent_units)
                  ]),
    Trace = [ recognize_factor_pair(N, S),
              retrieve_known_multiplication_fact(N, S, Product),
              bind_product_to_factor_pair(N, S, Product),
              preserve_referent_units_for_product(Product)
            ].
run_multiplicative_action(context_free_fact_family_guess, N, S, Outcome, Trace) :-
    context_free_fact_family_components(N, S, Components),
    Components = context_free_fact_family_components(N, S, Product, AltN, AltS),
    Outcome = action_outcome(
                  context_free_fact_family_guess,
                  [ classification(deformation),
                    cluster(multiplicative_fact_family),
                    automaton_state(retrieving_known_product),
                    vocabulary([factor_pair, known_fact, product, fact_family, referent_units]),
                    result(alternate_factor_pair(AltN, AltS, Product)),
                    expected(factor_pair(N, S, Product)),
                    validity(incorrect),
                    groups(N),
                    items_per_group(S),
                    components(Components),
                    deformation_of(multiplication_fact_retrieval),
                    misconception_family(unbound_fact_family_guess)
                  ]),
    Trace = [ recognize_target_factor_pair(N, S),
              retrieve_product_without_referent_units(Product),
              substitute_alternate_factor_pair(AltN, AltS, Product),
              answer_from_context_free_fact_family(alternate_factor_pair(AltN, AltS, Product)),
              lose_referent_units(expected_factor_pair(N, S), produced_factor_pair(AltN, AltS))
            ].


%!  multiplicative_action_cluster(+Kind, -Cluster) is det.
multiplicative_action_cluster(coordinate_groups_items, multiplicative_composite_units).
multiplicative_action_cluster(add_counts_without_composite_unit, multiplicative_composite_units).
multiplicative_action_cluster(add_instead_of_multiply, multiplicative_composite_units).
multiplicative_action_cluster(repeat_equal_groups, multiplicative_composite_units).
multiplicative_action_cluster(repeat_group_size_by_itself, multiplicative_composite_units).
multiplicative_action_cluster(distribute_group_size_split, multiplicative_composite_units).
multiplicative_action_cluster(drop_second_partial_product, multiplicative_composite_units).
multiplicative_action_cluster(regroup_to_base_preserving_total, multiplicative_composite_units).
multiplicative_action_cluster(drop_regrouping_remainder, multiplicative_composite_units).
multiplicative_action_cluster(known_product_adjustment, multiplicative_fact_adjustment).
multiplicative_action_cluster(known_product_without_adjustment, multiplicative_fact_adjustment).
multiplicative_action_cluster(commute_factors_preserve_product, multiplicative_factor_relations).
multiplicative_action_cluster(rigid_factor_order_roles, multiplicative_factor_relations).
multiplicative_action_cluster(sequential_recompute_commuted_products, multiplicative_factor_relations).
multiplicative_action_cluster(multiplication_fact_retrieval, multiplicative_fact_family).
multiplicative_action_cluster(context_free_fact_family_guess, multiplicative_fact_family).
multiplicative_action_cluster(common_factor_intersection,
                              multiplicative_factor_multiple_search).
multiplicative_action_cluster(factors_of_first_number_only,
                              multiplicative_factor_multiple_search).
multiplicative_action_cluster(common_multiple_sequence,
                              multiplicative_factor_multiple_search).
multiplicative_action_cluster(add_numbers_as_common_multiple,
                              multiplicative_factor_multiple_search).


%!  multiplicative_action_vocabulary(+Kind, -Vocabulary) is det.
multiplicative_action_vocabulary(coordinate_groups_items,
                                 [group_count, item_count, composite_unit, total_items]).
multiplicative_action_vocabulary(add_counts_without_composite_unit,
                                 [group_count, item_count, composite_unit, total_items]).
multiplicative_action_vocabulary(add_instead_of_multiply,
                                 [group_count, items_per_group, equal_groups,
                                  addition, multiplication, operation_substitution,
                                  composite_unit_loss]).
multiplicative_action_vocabulary(repeat_equal_groups,
                                 [equal_group, repeated_addend, iteration_count, running_product]).
multiplicative_action_vocabulary(repeat_group_size_by_itself,
                                 [equal_group, repeated_addend, iteration_count, running_product]).
multiplicative_action_vocabulary(distribute_group_size_split,
                                 [group_size_split, partial_product, recomposition, conservation]).
multiplicative_action_vocabulary(drop_second_partial_product,
                                 [group_size_split, partial_product, recomposition, conservation]).
multiplicative_action_vocabulary(regroup_to_base_preserving_total,
                                 [equal_group, base_bundle, leftover, conservation]).
multiplicative_action_vocabulary(drop_regrouping_remainder,
                                 [equal_group, base_bundle, leftover, conservation]).
multiplicative_action_vocabulary(known_product_adjustment,
                                 [benchmark_fact, known_product, equal_group, adjustment, product]).
multiplicative_action_vocabulary(known_product_without_adjustment,
                                 [benchmark_fact, known_product, equal_group, adjustment, product]).
multiplicative_action_vocabulary(commute_factors_preserve_product,
                                 [factor_order, commutativity, equal_groups, product, equivalence]).
multiplicative_action_vocabulary(rigid_factor_order_roles,
                                 [factor_order, commutativity, equal_groups, product, equivalence]).
multiplicative_action_vocabulary(sequential_recompute_commuted_products,
                                 [factor_order, commutativity, equal_groups, product, equivalence]).
multiplicative_action_vocabulary(multiplication_fact_retrieval,
                                 [factor_pair, known_fact, product, fact_family, referent_units]).
multiplicative_action_vocabulary(context_free_fact_family_guess,
                                 [factor_pair, known_fact, product, fact_family, referent_units]).
multiplicative_action_vocabulary(common_factor_intersection,
                                 [factor, divisor, factor_pair, divisibility,
                                  common_factor, intersection,
                                  greatest_common_factor]).
multiplicative_action_vocabulary(factors_of_first_number_only,
                                 [factor, divisor, common_factor, intersection,
                                  one_set_only]).
multiplicative_action_vocabulary(common_multiple_sequence,
                                 [multiple, repeated_equal_group, divisibility,
                                  common_multiple, least_common_multiple,
                                  infinite_sequence, generator]).
multiplicative_action_vocabulary(add_numbers_as_common_multiple,
                                 [multiple, common_multiple, addition,
                                  divisibility, operation_substitution]).


%!  productive_multiplicative_deformation(+ProductiveKind, +DeformationKind, -MisconceptionFamily) is det.
productive_multiplicative_deformation(coordinate_groups_items,
                                      add_counts_without_composite_unit,
                                      additive_count_for_multiplicative_structure).
productive_multiplicative_deformation(repeat_equal_groups,
                                      add_instead_of_multiply,
                                      addition_instead_of_multiplication).
productive_multiplicative_deformation(repeat_equal_groups,
                                      repeat_group_size_by_itself,
                                      role_confusion_repeats_size_by_itself).
productive_multiplicative_deformation(distribute_group_size_split,
                                      drop_second_partial_product,
                                      dropped_partial_product).
productive_multiplicative_deformation(regroup_to_base_preserving_total,
                                      drop_regrouping_remainder,
                                      dropped_leftover_after_regrouping).
productive_multiplicative_deformation(known_product_adjustment,
                                      known_product_without_adjustment,
                                      omitted_known_product_adjustment).
productive_multiplicative_deformation(commute_factors_preserve_product,
                                      rigid_factor_order_roles,
                                      fixed_multiplier_multiplicand_roles).
productive_multiplicative_deformation(commute_factors_preserve_product,
                                      sequential_recompute_commuted_products,
                                      procedural_recompute_when_commutation_available).
productive_multiplicative_deformation(multiplication_fact_retrieval,
                                      context_free_fact_family_guess,
                                      unbound_fact_family_guess).
productive_multiplicative_deformation(common_factor_intersection,
                                      factors_of_first_number_only,
                                      common_factors_from_one_number_only).
productive_multiplicative_deformation(common_multiple_sequence,
                                      add_numbers_as_common_multiple,
                                      sum_as_common_multiple).


%!  multiplicative_action_misconception_hook(+Outcome, -Family, -Hook) is semidet.
multiplicative_action_misconception_hook(action_outcome(Kind, Fields), Family, Hook) :-
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
multiplicative_action_misconception_hook(action_outcome(Kind, Fields), Family, Hook) :-
    member(classification(productive), Fields),
    productive_multiplicative_deformation(Kind, DeformationKind, Family),
    member(vocabulary(Vocabulary), Fields),
    Hook = action_misconception_hook(
               [ productive_action(Kind),
                 nearby_deformation(DeformationKind),
                 family(Family),
                 vocabulary(Vocabulary),
                 monitoring_focus(preserve_action_invariants(Kind)),
                 evidence(Fields)
               ]).


repeated_add_totals(Addend, Repetitions, Totals) :-
    integer_to_recollection(Repetitions, RecRepetitions),
    repeated_add_totals_(Addend, RecRepetitions, 0, [], RevTotals),
    reverse(RevTotals, Totals).

repeated_add_totals_(_Addend, RecRepetitions, _Current, Totals, Totals) :-
    is_zero_grounded(RecRepetitions),
    !.
repeated_add_totals_(Addend, RecRepetitions, Current, Acc, Totals) :-
    \+ is_zero_grounded(RecRepetitions),
    add_ints(Current, Addend, Next),
    predecessor(RecRepetitions, Remaining),
    repeated_add_totals_(Addend, Remaining, Next, [Next|Acc], Totals).


distributive_components(N, S, distributive_components(S1, S2, Partial1, Partial2, Product)) :-
    current_cgi_base(Base),
    heuristic_split(S, Base, S1, S2),
    multiply_ints(N, S1, Partial1),
    multiply_ints(N, S2, Partial2),
    add_ints(Partial1, Partial2, Product),
    incur_cost(action_distributive_components).


regroup_components(N, S, Base, regroup_components(Product, BaseGroups, Leftover, FullBaseTotal)) :-
    multiply_ints(N, S, Product),
    integer_to_recollection(Product, RecProduct),
    integer_to_recollection(Base, RecBase),
    base_decompose_grounded(RecProduct, RecBase, RecBaseGroups, RecLeftover),
    multiply_grounded(RecBaseGroups, RecBase, RecFullBaseTotal),
    recollection_to_integer(RecBaseGroups, BaseGroups),
    recollection_to_integer(RecLeftover, Leftover),
    recollection_to_integer(RecFullBaseTotal, FullBaseTotal),
    incur_cost(action_regroup_components).


known_product_adjustment_components(
    N,
    S,
    known_product_adjustment_components(BaseGroups, S, BaseProduct, ExtraGroups, ExtraProduct, Product)
) :-
    S > 0,
    integer_to_recollection(N, RecN),
    integer_to_recollection(1, RecOne),
    greater_than(RecN, RecOne),
    predecessor(RecN, RecBaseGroups),
    recollection_to_integer(RecBaseGroups, BaseGroups),
    ExtraGroups = 1,
    multiply_ints(BaseGroups, S, BaseProduct),
    multiply_ints(ExtraGroups, S, ExtraProduct),
    add_ints(BaseProduct, ExtraProduct, Product),
    incur_cost(action_known_product_adjustment_components).


commuted_product_components(N, S, commuted_product_components(N, S, Product, S, N, CommutedProduct)) :-
    multiply_ints(N, S, Product),
    multiply_ints(S, N, CommutedProduct),
    Product = CommutedProduct,
    incur_cost(action_commuted_product_components).


context_free_fact_family_components(
    N,
    S,
    context_free_fact_family_components(N, S, Product, AltN, AltS)
) :-
    multiply_ints(N, S, Product),
    alternate_factor_pair(Product, N, S, AltN, AltS),
    incur_cost(action_context_free_fact_family_components).


alternate_factor_pair(Product, N, S, AltN, AltS) :-
    Product > 1,
    between(2, Product, AltN),
    0 is Product mod AltN,
    AltS is Product // AltN,
    AltS > 1,
    \+ same_factor_pair(N, S, AltN, AltS),
    !.


same_factor_pair(N, S, AltN, AltS) :-
    (N =:= AltN, S =:= AltS)
    ;
    (N =:= AltS, S =:= AltN).

positive_integer(Value) :- integer(Value), Value > 0.

positive_divisors(Value, Divisors) :-
    findall(Divisor,
            ( between(1, Value, Divisor), 0 is Value mod Divisor ),
            Divisors).

least_common_multiple(A, B, LCM) :-
    GCD is gcd(A, B),
    LCM is (A // GCD) * B.

first_multiples(Unit, Count, Multiples) :-
    findall(Multiple,
            ( between(1, Count, Index), Multiple is Unit * Index ),
            Multiples).

divisible_by_both(Value, A, B) :-
    0 is Value mod A,
    0 is Value mod B.


heuristic_split(Value, Base, S1, S2) :-
    integer_to_recollection(Value, RecValue),
    integer_to_recollection(Base, RecBase),
    (   greater_than(RecValue, RecBase)
    ->  S1 = Base,
        subtract_grounded(RecValue, RecBase, RecS2),
        recollection_to_integer(RecS2, S2)
    ;   integer_to_recollection(2, RecTwo),
        base_decompose_grounded(RecBase, RecTwo, RecHalf, RecBaseRem),
        is_zero_grounded(RecBaseRem),
        recollection_to_integer(RecHalf, HalfBase),
        integer_to_recollection(HalfBase, RecHalfBase),
        greater_than(RecValue, RecHalfBase)
    ->  S1 = HalfBase,
        subtract_grounded(RecValue, RecHalfBase, RecS2b),
        recollection_to_integer(RecS2b, S2)
    ;   integer_to_recollection(2, RecTwo2),
        greater_than(RecValue, RecTwo2)
    ->  S1 = 2,
        subtract_grounded(RecValue, RecTwo2, RecS2c),
        recollection_to_integer(RecS2c, S2)
    ;   integer_to_recollection(1, RecOne),
        greater_than(RecValue, RecOne)
    ->  S1 = 1,
        predecessor(RecValue, RecS2d),
        recollection_to_integer(RecS2d, S2)
    ;   S1 = Value, S2 = 0
    ).


% add_ints/3, multiply_ints/3 imported from math(integer_helpers).
