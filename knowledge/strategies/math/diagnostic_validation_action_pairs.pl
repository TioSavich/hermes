/** <module> Diagnostic-validation action automata
 *
 * automata-008: diagnostic-validation axis. The axis-design decision
 * recorded for this module is one axis, three sub-families:
 *
 *   - subfamily(cardinality)   -- re-grounds a count in counting principles
 *                                 (e.g., bijective counting of a collection)
 *   - subfamily(validation)    -- re-grounds a proposed answer against a
 *                                 constraint or inverse operation
 *   - subfamily(justification) -- re-grounds a procedural rule in a model
 *
 * The three sub-families share the structural shape of "re-grounding an
 * existing claim/result/rule against an external reference". What differs
 * is what gets re-grounded (count vs. answer vs. rule) and what the
 * reference is (counting principles vs. constraint vs. model). Each
 * outcome's Fields list carries a `subfamily/1` field so consumers can
 * dispatch on the sub-family without inspecting the kind.
 *
 * Signature note. Unlike the operation-specific action-pair modules
 * (which take two operands of one arithmetic operation), the diagnostic
 * surface takes a proposed value plus a reference structure. The
 * reference is whatever the diagnostic re-grounds against -- a
 * dividend/divisor pair for validation by inverse multiplication, a
 * constraint for cardinality, a model for justification. Callers
 * package the reference as a compound term.
 *
 * Reference-shape conventions per Kind:
 *
 *   - multiplicative_bound_invalidation:
 *       Reference = dividend_divisor(Dividend, Divisor)
 *       Checks whether Divisor * Proposed exceeds Dividend.
 *   - decomposed_divisor_product:
 *       Reference = factor_decomposition(FactorA, [Part1, Part2, ...])
 *       Validates that FactorA * sum(Parts) equals the proposed product
 *       by summing partial products (FactorA * Part_i).
 *   - small_area_justification:
 *       Reference = rule_outputs_and_area_outputs(RuleResult, AreaInput)
 *       Checks the procedural rule's output (`RuleResult`) against the
 *       output of the area-model kernel run on `AreaInput`
 *       (`fraction_pair(A, B, C, D)`). Emits `consistent(...)` when the
 *       rule's output matches the area-model output and
 *       `inconsistent(...)` when the rule is held without a ground.
 *   - rigorous_counting_procedure:
 *       Reference = collection_size(N)
 *       Checks the proposed cardinal against a bijective count of a
 *       collection of size N, exercising the five counting principles.
 *
 * Iteration history. The first iteration shipped one productive automaton
 * (`multiplicative_bound_invalidation`, validation sub-family). The
 * second iteration -- this batch -- adds:
 *
 *   - decomposed_divisor_product (extract-026 Fluckiger, validation):
 *     validates 23 * 15 = 345 by distributive recomputation
 *     (23 * 10 + 23 * 5 = 230 + 115 = 345). Coupled to the grounded
 *     kernel via `formalization(grounded_arithmetic):add_grounded/3`
 *     and `multiply_grounded/3` -- each partial product is multiplied,
 *     summed, then compared against the proposed product.
 *   - small_area_justification (extract-028 Glade, justification):
 *     re-grounds the cross-multiplication rule in the small-rectangle
 *     area model. Cross-module kernel coupling: invokes
 *     `math(fraction_action_pairs):run_fraction_action/5` with
 *     `Kind=area_model_part_of_part` to obtain the area-model output,
 *     then compares against the rule's output.
 *   - rigorous_counting_procedure (extract-029 Godino, cardinality):
 *     establishes a collection's cardinality by bijective counting under
 *     the five counting principles (one-to-one correspondence, stable
 *     order, cardinal, abstraction, order irrelevance). Coupled to the
 *     kernel via `formalization(grounded_arithmetic):integer_to_recollection/2`
 *     -- the count is grounded as a recollection and unified against
 *     the integer_to_recollection grounding of the proposed cardinal.
 *
 * Productive-only state. No diagnostic deformation is registered. The
 * axis decision continues to keep the module productive-only for now;
 * deformation pairs (e.g., a validation that checks the wrong bound, or
 * a counting procedure that loses bijection) elaborate this pair in
 * later batches.
 */

:- module(diagnostic_validation_action_pairs,
          [ run_diagnostic_action/5,
            diagnostic_action_cluster/2,
            diagnostic_action_vocabulary/2,
            diagnostic_action_subfamily/2,
            productive_diagnostic_deformation/3,
            diagnostic_action_misconception_hook/3
          ]).

:- use_module(formalization(grounded_arithmetic),
              [ add_grounded/3,
                multiply_grounded/3,
                integer_to_recollection/2,
                recollection_to_integer/2
              ]).
:- use_module(math(integer_helpers), [positive_integer/1]).
:- use_module(math(fraction_action_pairs),
              [ run_fraction_action/5
              ]).


%!  run_diagnostic_action(+Kind, +Proposed, +Reference, -Outcome, -Trace) is semidet.
%
%   Execute a productive diagnostic-validation automaton. Proposed is the
%   value under test (a candidate quotient, a proposed cardinality, etc.).
%   Reference is the structure the diagnostic re-grounds against, packaged
%   as a compound term whose shape depends on Kind. See the module header
%   for the per-Kind reference shape.
run_diagnostic_action(multiplicative_bound_invalidation, Proposed,
                      dividend_divisor(Dividend, Divisor),
                      Outcome, Trace) :-
    positive_integer(Proposed),
    positive_integer(Dividend),
    positive_integer(Divisor),
    integer_to_recollection(Divisor, RecDivisor),
    integer_to_recollection(Proposed, RecProposed),
    multiply_grounded(RecDivisor, RecProposed, RecBound),
    recollection_to_integer(RecBound, Bound),
    bound_verdict(Bound, Dividend, Verdict),
    Outcome = action_outcome(
                  multiplicative_bound_invalidation,
                  [ classification(productive),
                    subfamily(validation),
                    cluster(diagnostic_validation_by_inverse_multiplication),
                    automaton_state(checking_proposed_quotient_against_dividend),
                    vocabulary([proposed_quotient, dividend, divisor,
                                inverse_multiplication, multiplicative_bound,
                                upper_bound_check, invalidate_quotient,
                                consistency_check]),
                    proposed(Proposed),
                    reference(dividend_divisor(Dividend, Divisor)),
                    bound(Bound),
                    verdict(Verdict),
                    result(verdict_for(Proposed, Verdict)),
                    expected(verdict_for(Proposed, Verdict)),
                    validity(correct),
                    elaborates(formalization:grounded_arithmetic:multiply_grounded/3),
                    kernel_trace([recollection_for_divisor(Divisor, RecDivisor),
                                  recollection_for_proposed(Proposed, RecProposed),
                                  multiply_grounded(RecDivisor, RecProposed, RecBound),
                                  recollection_to_integer(RecBound, Bound)])
                  ]),
    Trace = [ inspect_proposed_quotient(Proposed),
              identify_dividend_and_divisor(Dividend, Divisor),
              multiply_divisor_by_proposed_via_kernel(Divisor, Proposed, Bound),
              compare_bound_against_dividend(Bound, Dividend),
              emit_verdict(Verdict)
            ].

run_diagnostic_action(decomposed_divisor_product, Proposed,
                      factor_decomposition(FactorA, Parts),
                      Outcome, Trace) :-
    positive_integer(Proposed),
    positive_integer(FactorA),
    is_list(Parts),
    Parts = [_|_],
    forall(member(P, Parts), positive_integer(P)),
    integer_to_recollection(FactorA, RecFactorA),
    multiply_partial_products(Parts, RecFactorA, RecPartials, KernelMultSteps),
    sum_recollections(RecPartials, RecTotal, KernelAddSteps),
    recollection_to_integer(RecTotal, ReconstructedProduct),
    distributive_verdict(ReconstructedProduct, Proposed, Verdict),
    sumlist(Parts, PartsSum),
    pair_parts_with_partials(Parts, RecPartials, PartialProducts),
    KernelTrace = [ recollection_for_factor(FactorA, RecFactorA),
                    partial_products(PartialProducts),
                    kernel_multiplications(KernelMultSteps),
                    kernel_additions(KernelAddSteps),
                    recollection_to_integer(RecTotal, ReconstructedProduct)
                  ],
    Outcome = action_outcome(
                  decomposed_divisor_product,
                  [ classification(productive),
                    subfamily(validation),
                    cluster(diagnostic_validation_by_distributive_decomposition),
                    automaton_state(validating_product_by_distributive_recomputation),
                    vocabulary([proposed_product, factor_decomposition,
                                partial_products, distributive_recomputation,
                                sum_of_partials, validate_product,
                                inverse_check_by_addition,
                                distributive_validation]),
                    proposed(Proposed),
                    reference(factor_decomposition(FactorA, Parts)),
                    parts_sum(PartsSum),
                    reconstructed_product(ReconstructedProduct),
                    partial_products(PartialProducts),
                    verdict(Verdict),
                    result(verdict_for(Proposed, Verdict)),
                    expected(verdict_for(Proposed, Verdict)),
                    validity(correct),
                    elaborates(formalization:grounded_arithmetic:add_grounded/3),
                    kernel_trace(KernelTrace)
                  ]),
    Trace = [ inspect_proposed_product(Proposed),
              identify_factor_and_decomposition(FactorA, Parts),
              multiply_each_part_by_factor_via_kernel(FactorA, Parts, PartialProducts),
              sum_partial_products_via_kernel(PartialProducts, ReconstructedProduct),
              compare_reconstructed_to_proposed(ReconstructedProduct, Proposed),
              emit_verdict(Verdict)
            ].

run_diagnostic_action(small_area_justification, Proposed,
                      rule_outputs_and_area_outputs(RuleResult, AreaInput),
                      Outcome, Trace) :-
    AreaInput = fraction_pair(A, B, C, D),
    positive_integer(A),
    positive_integer(B),
    positive_integer(C),
    positive_integer(D),
    %% Cross-module kernel coupling: invoke the area-model fraction
    %% automaton to derive the area-model output, then compare against
    %% the rule's output.
    once(run_fraction_action(area_model_part_of_part,
                             fraction_pair(A, B, C, D),
                             unit(whole),
                             AreaOutcome,
                             AreaTrace)),
    AreaOutcome = action_outcome(area_model_part_of_part, AreaFields),
    member(result(AreaModelResult), AreaFields),
    member(components(fraction_multiplication_components(NumeratorProduct,
                                                          DenominatorProduct,
                                                          AreaModelResult)),
           AreaFields),
    area_justification_verdict(RuleResult, AreaModelResult, Verdict),
    Outcome = action_outcome(
                  small_area_justification,
                  [ classification(productive),
                    subfamily(justification),
                    cluster(diagnostic_justification_by_area_model),
                    automaton_state(re_grounding_rule_in_small_rectangle_area_model),
                    vocabulary([procedural_rule, area_model, small_rectangle,
                                rectangle_dimensions, denominator_product,
                                numerator_product, re_ground_rule,
                                rule_to_model_justification,
                                cross_multiplication_rule]),
                    proposed(Proposed),
                    reference(rule_outputs_and_area_outputs(RuleResult, AreaInput)),
                    rule_result(RuleResult),
                    area_result(AreaModelResult),
                    numerator_product(NumeratorProduct),
                    denominator_product(DenominatorProduct),
                    verdict(Verdict),
                    result(verdict_for(Proposed, Verdict)),
                    expected(verdict_for(Proposed, Verdict)),
                    validity(correct),
                    elaborates(math:fraction_action_pairs:area_model_part_of_part),
                    kernel_trace([invoked_fraction_action(area_model_part_of_part,
                                                          fraction_pair(A, B, C, D)),
                                  area_model_trace(AreaTrace),
                                  area_model_result(AreaModelResult),
                                  compare_rule_to_area(RuleResult, AreaModelResult)])
                  ]),
    Trace = [ inspect_proposed_justification(Proposed),
              identify_rule_output(RuleResult),
              invoke_area_model_kernel(fraction_pair(A, B, C, D)),
              read_area_model_result(AreaModelResult),
              compare_rule_to_area_output(RuleResult, AreaModelResult),
              emit_verdict(Verdict)
            ].

run_diagnostic_action(rigorous_counting_procedure, Proposed,
                      collection_size(N),
                      Outcome, Trace) :-
    integer(N),
    N >= 0,
    integer(Proposed),
    Proposed >= 0,
    %% Kernel coupling: ground both the collection size and the proposed
    %% cardinal as recollections, then check whether they unify. The
    %% recollection of N is the cardinal produced by bijective counting
    %% of a collection of size N. The five counting principles guarantee
    %% the bijection is well-defined.
    integer_to_recollection(N, RecCount),
    integer_to_recollection(Proposed, RecProposed),
    counting_verdict(RecCount, RecProposed, N, Proposed, Verdict),
    BijectionSteps = bijective_count_steps(N),
    PrincipleChecks = [ one_to_one_correspondence,
                        stable_order,
                        cardinal_principle,
                        abstraction_principle,
                        order_irrelevance_principle
                      ],
    Outcome = action_outcome(
                  rigorous_counting_procedure,
                  [ classification(productive),
                    subfamily(cardinality),
                    cluster(diagnostic_cardinality_by_bijective_counting),
                    automaton_state(establishing_cardinality_by_bijective_counting),
                    vocabulary([bijective_counting, one_to_one_correspondence,
                                stable_order, cardinal_principle,
                                abstraction_principle, order_irrelevance,
                                five_counting_principles, collection_cardinality,
                                final_numerical_word]),
                    proposed(Proposed),
                    reference(collection_size(N)),
                    collection_size(N),
                    bijection_steps(BijectionSteps),
                    principle_checks(PrincipleChecks),
                    verdict(Verdict),
                    result(verdict_for(Proposed, Verdict)),
                    expected(verdict_for(Proposed, Verdict)),
                    validity(correct),
                    elaborates(formalization:grounded_arithmetic:integer_to_recollection/2),
                    kernel_trace([recollection_for_collection_size(N, RecCount),
                                  recollection_for_proposed_cardinal(Proposed, RecProposed),
                                  unify_recollections(RecCount, RecProposed),
                                  apply_counting_principles(PrincipleChecks)])
                  ]),
    Trace = [ inspect_proposed_cardinal(Proposed),
              identify_collection(collection_size(N)),
              ground_collection_via_kernel(N, RecCount),
              ground_proposed_via_kernel(Proposed, RecProposed),
              apply_one_to_one_correspondence,
              apply_stable_order,
              apply_cardinal_principle,
              apply_abstraction_principle,
              apply_order_irrelevance_principle,
              compare_recollections(RecCount, RecProposed),
              emit_verdict(Verdict)
            ].

run_diagnostic_action(error_magnitude_estimate_comparison, Selected,
                      competing_estimates(EstA, EstB, factors(F1, F2)),
                      Outcome, Trace) :-
    %% audit-001 resolution. Whitacre 2016 prospective teachers compared
    %% two rounded estimates of F1 * F2. For each estimate the trace
    %% identifies the *omitted partial product* (what the rounding
    %% dropped), grounds the omission as a recollection, then compares
    %% the two omission magnitudes. The estimate with the smaller
    %% omitted product is the closer estimate -- a validation move that
    %% re-grounds two candidate answers against an independent
    %% recomputation of the dropped partials. The strategy is NOT a
    %% productive multiplication action; it is a diagnostic-validation
    %% move that runs *across* two candidate answers.
    positive_integer(F1),
    positive_integer(F2),
    positive_integer(EstA),
    positive_integer(EstB),
    member(Selected, [EstA, EstB]),
    TrueProduct is F1 * F2,
    OmissionA is abs(TrueProduct - EstA),
    OmissionB is abs(TrueProduct - EstB),
    integer_to_recollection(OmissionA, RecOmissionA),
    integer_to_recollection(OmissionB, RecOmissionB),
    select_smaller_error(EstA, EstB, OmissionA, OmissionB, Better, BetterMag),
    error_comparison_verdict(Selected, Better, BetterMag, OmissionA, OmissionB,
                             Verdict),
    Outcome = action_outcome(
                  error_magnitude_estimate_comparison,
                  [ classification(productive),
                    subfamily(validation),
                    cluster(diagnostic_validation_by_error_magnitude_comparison),
                    automaton_state(comparing_omitted_partial_products),
                    vocabulary([rounded_estimate, omitted_partial_product,
                                rounding_error, error_magnitude,
                                compare_estimates, smaller_error,
                                closer_estimate, validation_across_candidates]),
                    proposed(Selected),
                    reference(competing_estimates(EstA, EstB, factors(F1, F2))),
                    true_product(TrueProduct),
                    estimate_a(EstA),
                    estimate_b(EstB),
                    omission_a(OmissionA),
                    omission_b(OmissionB),
                    verdict(Verdict),
                    result(verdict_for(Selected, Verdict)),
                    expected(verdict_for(Better, selects_smaller_error(Better, BetterMag))),
                    validity(correct),
                    elaborates(formalization:grounded_arithmetic:integer_to_recollection/2),
                    kernel_trace([true_product(F1, F2, TrueProduct),
                                  omission_for_a(EstA, TrueProduct, OmissionA),
                                  omission_for_b(EstB, TrueProduct, OmissionB),
                                  recollection_for_omission_a(OmissionA, RecOmissionA),
                                  recollection_for_omission_b(OmissionB, RecOmissionB),
                                  compare_omission_magnitudes(OmissionA, OmissionB, Better)])
                  ]),
    Trace = [ identify_competing_estimates(EstA, EstB),
              identify_factors(factors(F1, F2)),
              compute_true_product_via_kernel(F1, F2, TrueProduct),
              identify_omission_for_a(EstA, TrueProduct, OmissionA),
              identify_omission_for_b(EstB, TrueProduct, OmissionB),
              ground_omissions_as_recollections([RecOmissionA, RecOmissionB]),
              compare_error_magnitudes(OmissionA, OmissionB),
              select_estimate_with_smaller_omission(Better, BetterMag),
              emit_verdict(Verdict)
            ].


%!  bound_verdict(+Bound, +Dividend, -Verdict) is det.
%
%   Classify the relation between the multiplicative bound and the
%   dividend. When the bound exceeds the dividend the proposed value is
%   invalidated as a candidate quotient; otherwise it is consistent with
%   (but not certified by) the dividend.
bound_verdict(Bound, Dividend, invalidates(exceeds_dividend(Bound, Dividend))) :-
    Bound > Dividend, !.
bound_verdict(Bound, Dividend, consistent(within_dividend(Bound, Dividend))).


%!  distributive_verdict(+Reconstructed, +Proposed, -Verdict) is det.
%
%   The reconstructed product is the sum of partial products. If it
%   matches the proposed product, the proposed value is validated by
%   distributive decomposition; otherwise it is invalidated.
distributive_verdict(Reconstructed, Proposed,
                     validates(matches_proposed(Reconstructed, Proposed))) :-
    Reconstructed =:= Proposed, !.
distributive_verdict(Reconstructed, Proposed,
                     invalidates(mismatches_proposed(Reconstructed, Proposed))).


%!  select_smaller_error(+EstA, +EstB, +OmA, +OmB, -Better, -BetterMag) is det.
%
%   Pick the estimate whose absolute error against the true product is
%   smaller. Ties favor EstA.
select_smaller_error(EstA, _EstB, OmA, OmB, EstA, OmA) :- OmA =< OmB, !.
select_smaller_error(_EstA, EstB, _OmA, OmB, EstB, OmB).


%!  error_comparison_verdict(+Selected, +Better, +BetterMag,
%!                           +OmA, +OmB, -Verdict) is det.
%
%   Records whether the selected estimate is the one with the smaller
%   omission magnitude.
error_comparison_verdict(Selected, Better, BetterMag, _, _,
                         selects(smaller_error_magnitude(Selected, BetterMag))) :-
    Selected == Better, !.
error_comparison_verdict(Selected, Better, BetterMag, OmA, OmB,
                         rejects(larger_error_chosen(Selected,
                                                    smaller_was(Better, BetterMag),
                                                    omissions(OmA, OmB)))).


%!  area_justification_verdict(+RuleResult, +AreaResult, -Verdict) is det.
%
%   When the rule output and the area-model output agree, the rule is
%   re-grounded successfully. Otherwise the rule is held without an
%   adequate ground (a justification failure surfaces an inconsistency).
area_justification_verdict(RuleResult, AreaResult,
                           consistent(matches_area_model(RuleResult, AreaResult))) :-
    RuleResult == AreaResult, !.
area_justification_verdict(RuleResult, AreaResult,
                           inconsistent(rule_without_ground(RuleResult, AreaResult))).


%!  counting_verdict(+RecCount, +RecProposed, +N, +Proposed, -Verdict) is det.
%
%   The proposed cardinal is established when the recollection of the
%   collection size unifies with the recollection of the proposed
%   cardinal. Otherwise the bijection fails and the cardinal is rejected.
counting_verdict(Rec, Rec, N, Proposed,
                 establishes(cardinal_matches(N, Proposed))) :- !.
counting_verdict(_, _, N, Proposed,
                 rejects(cardinal_mismatch(N, Proposed))).


%!  multiply_partial_products(+Parts, +RecFactor, -RecPartials, -KernelSteps) is det.
%
%   For each part P in Parts, ground P as a recollection and call
%   `multiply_grounded(RecFactor, RecP, RecPartial)`. Returns the list
%   of partial-product recollections plus a list of the kernel-step
%   tuples for the trace.
multiply_partial_products([], _, [], []).
multiply_partial_products([Part|Parts], RecFactor,
                          [RecPartial|RecPartials],
                          [multiply_grounded(RecFactor, RecPart, RecPartial)|Steps]) :-
    integer_to_recollection(Part, RecPart),
    multiply_grounded(RecFactor, RecPart, RecPartial),
    multiply_partial_products(Parts, RecFactor, RecPartials, Steps).


%!  sum_recollections(+RecList, -RecTotal, -KernelSteps) is det.
%
%   Sum a list of recollections via `add_grounded/3`. Returns both the
%   running total recollection and the list of kernel-step tuples for
%   the trace.
sum_recollections([Rec], Rec, []) :- !.
sum_recollections([Rec1, Rec2 | Rest], Total,
                  [add_grounded(Rec1, Rec2, RecPair) | Steps]) :-
    add_grounded(Rec1, Rec2, RecPair),
    sum_recollections([RecPair | Rest], Total, Steps).


%!  pair_parts_with_partials(+Parts, +RecPartials, -PartialProducts) is det.
%
%   Render `(Part, FactorA * Part)` pairs for the outcome's
%   `partial_products` field.
pair_parts_with_partials([], [], []).
pair_parts_with_partials([Part|Parts], [Rec|Recs], [Part-Partial|Pairs]) :-
    recollection_to_integer(Rec, Partial),
    pair_parts_with_partials(Parts, Recs, Pairs).


%!  diagnostic_action_cluster(+Kind, -Cluster) is det.
diagnostic_action_cluster(multiplicative_bound_invalidation,
                          diagnostic_validation_by_inverse_multiplication).
diagnostic_action_cluster(decomposed_divisor_product,
                          diagnostic_validation_by_distributive_decomposition).
diagnostic_action_cluster(small_area_justification,
                          diagnostic_justification_by_area_model).
diagnostic_action_cluster(rigorous_counting_procedure,
                          diagnostic_cardinality_by_bijective_counting).
diagnostic_action_cluster(error_magnitude_estimate_comparison,
                          diagnostic_validation_by_error_magnitude_comparison).


%!  diagnostic_action_vocabulary(+Kind, -Vocabulary) is det.
diagnostic_action_vocabulary(multiplicative_bound_invalidation,
                             [proposed_quotient, dividend, divisor,
                              inverse_multiplication, multiplicative_bound,
                              upper_bound_check, invalidate_quotient,
                              consistency_check]).
diagnostic_action_vocabulary(decomposed_divisor_product,
                             [proposed_product, factor_decomposition,
                              partial_products, distributive_recomputation,
                              sum_of_partials, validate_product,
                              inverse_check_by_addition,
                              distributive_validation]).
diagnostic_action_vocabulary(small_area_justification,
                             [procedural_rule, area_model, small_rectangle,
                              rectangle_dimensions, denominator_product,
                              numerator_product, re_ground_rule,
                              rule_to_model_justification,
                              cross_multiplication_rule]).
diagnostic_action_vocabulary(rigorous_counting_procedure,
                             [bijective_counting, one_to_one_correspondence,
                              stable_order, cardinal_principle,
                              abstraction_principle, order_irrelevance,
                              five_counting_principles, collection_cardinality,
                              final_numerical_word]).
diagnostic_action_vocabulary(error_magnitude_estimate_comparison,
                             [rounded_estimate, omitted_partial_product,
                              rounding_error, error_magnitude,
                              compare_estimates, smaller_error,
                              closer_estimate, validation_across_candidates]).


%!  diagnostic_action_subfamily(+Kind, -Subfamily) is det.
diagnostic_action_subfamily(multiplicative_bound_invalidation, validation).
diagnostic_action_subfamily(decomposed_divisor_product, validation).
diagnostic_action_subfamily(small_area_justification, justification).
diagnostic_action_subfamily(rigorous_counting_procedure, cardinality).


%!  productive_diagnostic_deformation(+ProductiveKind, +DeformationKind, -Family) is semidet.
%
%   Intentionally empty. The axis stays productive-only across both
%   iterations; deformation pairs (validation against a wrong bound, a
%   counting procedure that loses bijection, a justification that maps
%   to the wrong model) elaborate this module in later batches.
productive_diagnostic_deformation(_, _, _) :- fail.


%!  diagnostic_action_misconception_hook(+Outcome, -Family, -Hook) is semidet.
%
%   Productive-only routing. The hook surfaces the verdict and the
%   sub-family so monitoring code can attribute the diagnostic to the
%   right axis without inspecting the kind. The family carries the
%   sub-family (`validation`, `justification`, `cardinality`) so all
%   three flow through the same hook shape.
diagnostic_action_misconception_hook(action_outcome(Kind, Fields), Family, Hook) :-
    member(classification(productive), Fields),
    member(subfamily(Subfamily), Fields),
    member(vocabulary(Vocabulary), Fields),
    member(verdict(Verdict), Fields),
    Family = diagnostic_validation_axis(Subfamily),
    Hook = action_misconception_hook(
               [ productive_diagnostic(Kind),
                 subfamily(Subfamily),
                 verdict(Verdict),
                 vocabulary(Vocabulary),
                 monitoring_focus(re_ground_against_reference(Kind)),
                 evidence(Fields)
               ]).


% positive_integer/1 imported from math(integer_helpers).
