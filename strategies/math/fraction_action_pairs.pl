/** <module> Fraction action/deformation pairs
 *
 * Minimal action-automata facade over `divaded_fractional_units.pl`.
 * The domain skeleton exposes fraction unit construction through the same
 * registry surface as the whole-number action automata.
 *
 * Fraction multiplication (automata-010, evidence: extract-028 Glade 2017)
 * extends this surface with three productive area-model automata plus a
 * productive/deformation pair distinguishing two ways of executing the
 * same cross-multiplication rule:
 *
 *   - `area_model_part_of_part` partitions a unit square along each
 *     denominator and reads (a/b) * (c/d) off the highlighted sub-rectangle.
 *   - `unit_fraction_denominator_product_rule` grounds the (a*c)/(b*d)
 *     pattern in unit-fraction logic: 1/b * 1/d = 1/(b*d), then iterate
 *     that unit fraction a*c times.
 *   - `cross_multiplication_rule_from_pattern` (productive) and
 *     `cross_multiplication_rule_without_ground` (deformation) form a pair
 *     where the numeric result agrees but the inferential structure differs.
 *     The productive trace cites the area-model justification; the deformation
 *     applies the multiply-across pattern with no ground. Both produce the
 *     correct value fraction(A*C, B*D); the disagreement is structural, not
 *     numeric. This is a new kind of deformation in the registry: a
 *     procedurally-correct but inferentially-hollow rule application,
 *     classified as `deformation` with `validity(correct)`.
 *
 * Registry boundary: multiplication needs two fraction operands. We pass the
 * compound `fraction_pair(A,B,C,D)` as the `Count` slot and `unit(whole)` as
 * the `Base` slot. The unit/whole atom carries the referent-whole role; the
 * fraction-pair compound carries the operand structure. The unit-fraction
 * predicates retain their (Count, Base) integer signature.
 */

:- module(fraction_action_pairs,
          [ run_fraction_action/5,
            fraction_action_cluster/2,
            fraction_action_vocabulary/2,
            productive_fraction_deformation/3,
            fraction_action_misconception_hook/3
          ]).

:- use_module(formalization(grounded_arithmetic),
              [ integer_to_recollection/2
              ]).
:- use_module(math(divaded_fractional_units),
              [ partitive_fraction/5,
                iterative_fraction/6,
                fractional_connected_sequence/6,
                improper_fraction_chain_loss/6,
                unit_fraction_of_unit_fraction/6,
                measurement_divide_fractions/7,
                division_by_recovered_generator/7,
                rec_to_int/2
              ]).
:- use_module(math(fraction_partitioning),
              [ run_partition/5,
                disembedded/3,
                run_recursive_partition/5
              ]).
:- use_module(math(fraction_iterating),
              [ run_iterate/4,
                partition_iterate_inverse/2,
                solve_for_unit/5
              ]).
:- use_module(math(fraction_cgi_dispatch),
              [ fraction_cgi_addition/5
              ]).
:- use_module(math(smr_frac_equiv_cross_mult),
              [ run_cross_mult_equiv/6
              ]).
:- use_module(math(smr_frac_nl_compare),
              [ run_number_line_compare/6,
                run_count_marks_compare/6
              ]).

% Text-grounded PFS kernel (Steffe-Hackenberg). Sits alongside the live
% N101 PFS in divaded_fractional_units as the citable manuscript form.
% Models the same conceptual object (partitive fractional scheme) at two
% registers — the manuscript reference and the live operational form.
:- use_module(math(integer_helpers), [positive_integer/1]).
:- use_module(math(jason),
              [ partitive_fractional_scheme/4
              ]).


%!  run_fraction_action(+Kind, +Count, +Base, -Outcome, -Trace) is semidet.
%
%   Execute a productive or deformed fraction-unit action automaton. For the
%   unit-fraction kinds (partition, iteration, whole-number grab), Count and
%   Base are integers. For the multiplication and division kinds
%   (`measurement_division`, `reversible_measurement_division`), Count is the
%   compound `fraction_pair(A,B,C,D)` -- dividend A/B, divisor C/D for the
%   division kinds -- and Base is `unit(whole)`.
run_fraction_action(unit_fraction_partition, Count, Base, Outcome, Trace) :-
    Count =:= 1,
    positive_integer(Base),
    rec(Count, RecCount),
    rec(Base, RecBase),
    partitive_fraction(RecCount, RecBase, unit(whole), FractionState, KernelTrace),
    Result = fraction(Count, Base),
    Outcome = action_outcome(
                  unit_fraction_partition,
                  [ classification(productive),
                    cluster(fraction_unit_referent_operations),
                    automaton_state(fraction_referent_unit),
                    vocabulary([referent_whole, equal_partition, denominator,
                                unit_fraction, inside_part, iterable_unit]),
                    result(Result),
                    expected(Result),
                    validity(correct),
                    components(unit_fraction_partition_components(unit(whole), Base, Result)),
                    elaborates(divaded_fractional_units:partitive_fraction/5),
                    evidence(FractionState)
                  ]),
    Trace = [ establish_referent_whole(unit(whole)),
              partition_whole_into_equal_units(Base),
              select_one_partition_as_unit_fraction(Result),
              preserve_inside_and_iterable_status(Result),
              kernel_trace(KernelTrace)
            ].
run_fraction_action(unit_fraction_iteration, Count, Base, Outcome, Trace) :-
    positive_integer(Count),
    positive_integer(Base),
    rec(Count, RecCount),
    rec(Base, RecBase),
    iterative_fraction(RecCount, RecBase, unit(whole), available_prior, FractionState, KernelTrace),
    fraction_relation(Count, Base, Relation),
    Result = fraction(Count, Base),
    Outcome = action_outcome(
                  unit_fraction_iteration,
                  [ classification(productive),
                    cluster(fraction_unit_referent_operations),
                    automaton_state(fraction_referent_unit),
                    vocabulary([referent_whole, unit_fraction, iteration_count,
                                denominator, completion_marker, beyond_whole]),
                    result(Result),
                    expected(Result),
                    validity(correct),
                    components(unit_fraction_iteration_components(unit(whole), Count, Base, Relation)),
                    elaborates(divaded_fractional_units:iterative_fraction/6),
                    evidence(FractionState)
                  ]),
    Trace = [ establish_referent_whole(unit(whole)),
              recover_unit_fraction(fraction(1, Base)),
              iterate_unit_fraction(Count, fraction(1, Base), Result),
              coordinate_iteration_with_completion_marker(fraction(Base, Base), Relation),
              kernel_trace(KernelTrace)
            ].
run_fraction_action(whole_number_grab, Count, Base, Outcome, Trace) :-
    positive_integer(Count),
    positive_integer(Base),
    rec(Count, RecCount),
    rec(Base, RecBase),
    iterative_fraction(RecCount, RecBase, unit(whole), available_prior, FractionState, _KernelTrace),
    Result = whole_number(Count),
    Expected = fraction(Count, Base),
    Outcome = action_outcome(
                  whole_number_grab,
                  [ classification(deformation),
                    cluster(fraction_unit_referent_operations),
                    automaton_state(fraction_referent_unit),
                    vocabulary([referent_whole, unit_fraction, iteration_count,
                                denominator, whole_number_count, unit_loss]),
                    result(Result),
                    expected(Expected),
                    validity(incorrect),
                    components(whole_number_grab_components(unit(whole), Count, Base)),
                    deformation_of(unit_fraction_iteration),
                    misconception_family(whole_number_grab),
                    evidence(FractionState)
                  ]),
    Trace = [ establish_referent_whole(unit(whole)),
              notice_visible_iteration_count(Count),
              ignore_unit_fraction_denominator(Base),
              name_count_as_whole_number(Result),
              lose_referent_unit(expected(Expected), produced(Result))
            ].

% -----------------------------------------------------------------------------
% Band 2 — splitting (productive) / iterate-given overshoot (deformation)
%
% Splitting packages the two primitive automata (fraction_partitioning,
% fraction_iterating) as one action: partition the whole into Base equal parts
% and iterate the unit Base times back to the whole, *recognizing* the two as
% mutual inverses (1/Base * Base = 1). That recognition — not the two moves on
% their own — is the productive content, grounded in L&N's Object-Construction
% entailment "split then refit returns the unit" (grounds_inference in
% formalization/grounding_metaphors.pl). The recovered whole opens the
% improper-fraction band. The deformation iterates the part forward without the
% inverse recognition and overshoots, never recovering the whole.
% -----------------------------------------------------------------------------
run_fraction_action(splitting, Count, Base, Outcome, Trace) :-
    Count =:= 1,
    positive_integer(Base),
    rec(Base, RecBase),
    run_partition(unit(whole), RecBase, UnitPart, Parts, PartHist),
    disembedded(UnitPart, unit(whole), RecBase),
    run_iterate(UnitPart, RecBase, Units, IterHist),
    partition_iterate_inverse(unit(whole), RecBase),
    length(Units, Base),
    Result = whole_recovered(unit(whole)),
    Outcome = action_outcome(
                  splitting,
                  [ classification(productive),
                    cluster(fraction_reversibility_splitting),
                    automaton_state(whole_recovered),
                    vocabulary([referent_whole, equal_partition, unit_fraction,
                                iterate, mutual_inverse, multiplicative_inverse,
                                whole_recovered, reversible_coordination]),
                    result(Result),
                    expected(Result),
                    validity(correct),
                    components(splitting_components(unit(whole), Base, fraction(1, Base))),
                    justification(multiplicative_inverse_1_over_n_times_n_is_1),
                    grounded_by(grounds_inference(arithmetic_is_object_construction,
                                                  multiplicative_inverse_1_over_n_times_n_is_1,
                                                  partition_then_iterate_returns_unit)),
                    opens(improper_fraction_iteration),
                    elaborates(fraction_iterating:partition_iterate_inverse/2),
                    evidence(partition_parts(Parts))
                  ]),
    Trace = [ partition_whole_into_equal_units(Base),
              disembed_unit_fraction(fraction(1, Base)),
              iterate_unit_fraction_back_to_whole(Base, fraction(1, Base)),
              recognize_partition_iterate_as_mutual_inverse(fraction(1, Base), Base),
              recover_whole(whole_recovered),
              open_improper_fraction_domain,
              partition_trace(PartHist),
              iterate_trace(IterHist)
            ].
run_fraction_action(iterate_given_overshoot, Count, Base, Outcome, Trace) :-
    positive_integer(Count),
    positive_integer(Base),
    Count > Base,
    rec(Count, RecCount),
    rec(Base, RecBase),
    iterative_fraction(RecCount, RecBase, unit(whole), available_prior, FractionState, _KT),
    Result = overshot(fraction(Count, Base)),
    Expected = whole_recovered(unit(whole)),
    Outcome = action_outcome(
                  iterate_given_overshoot,
                  [ classification(deformation),
                    cluster(fraction_reversibility_splitting),
                    automaton_state(overshot),
                    vocabulary([referent_whole, unit_fraction, iterate_forward,
                                no_inverse_recognition, overshoot, whole_not_recovered]),
                    result(Result),
                    expected(Expected),
                    validity(incorrect),
                    components(iterate_given_overshoot_components(unit(whole), Count, Base)),
                    deformation_of(splitting),
                    misconception_family(no_splitting_iterate_overshoot),
                    evidence(FractionState)
                  ]),
    Trace = [ establish_referent_whole(unit(whole)),
              iterate_given_part_forward(Count, fraction(1, Base)),
              fail_to_recognize_partition_iterate_inverse,
              overshoot_without_recovering_whole(Result, expected(Expected))
            ].

% -----------------------------------------------------------------------------
% Band 3 — improper-fraction iteration (productive) / chain loss (deformation)
%
% Opened by splitting. The productive automaton iterates the unit fraction past
% the whole while holding D/D as the fixed referent (the freed iterative scheme,
% Stage-3 units coordination), naming N/D with N > D as a number in its own
% right. No new metaphor is needed (L&N: Motion-Along-a-Path grounds m/n the
% same whether m < n or m > n). The deformation iterates past the whole but
% loses the referent chain and resets N/D to N/N.
% -----------------------------------------------------------------------------
run_fraction_action(improper_fraction_iteration, Count, Base, Outcome, Trace) :-
    positive_integer(Count),
    positive_integer(Base),
    Count > Base,
    rec(Count, RecCount),
    rec(Base, RecBase),
    fractional_connected_sequence(RecCount, RecBase, unit(whole), mc3, SeqState, KTrace),
    Result = fraction(Count, Base),
    Outcome = action_outcome(
                  improper_fraction_iteration,
                  [ classification(productive),
                    cluster(fraction_improper_number),
                    automaton_state(freed_iterative_sequence),
                    vocabulary([referent_whole, unit_fraction, iterate_past_whole,
                                fixed_referent, freed_iterative, improper_fraction,
                                completion_marker]),
                    result(Result),
                    expected(Result),
                    validity(correct),
                    components(improper_fraction_components(unit(whole), Count, Base)),
                    requires(splitting),
                    elaborates(divaded_fractional_units:fractional_connected_sequence/6),
                    evidence(SeqState)
                  ]),
    Trace = [ establish_referent_whole(unit(whole)),
              recover_unit_fraction(fraction(1, Base)),
              iterate_unit_past_whole_keeping_referent(Count, Base),
              hold_completion_marker(fraction(Base, Base)),
              name_improper_fraction_as_number(Result),
              kernel_trace(KTrace)
            ].
run_fraction_action(improper_fraction_chain_loss, Count, Base, Outcome, Trace) :-
    positive_integer(Count),
    positive_integer(Base),
    Count > Base,
    rec(Count, RecCount),
    rec(Base, RecBase),
    improper_fraction_chain_loss(RecCount, RecBase, unit(whole), mc2, LossState, KTrace),
    Result = reset_fraction(fraction(Count, Count)),
    Expected = fraction(Count, Base),
    Outcome = action_outcome(
                  improper_fraction_chain_loss,
                  [ classification(deformation),
                    cluster(fraction_improper_number),
                    automaton_state(referent_chain_lost),
                    vocabulary([referent_whole, unit_fraction, iterate_past_whole,
                                lose_referent_chain, reset_whole, improper_fraction_reset]),
                    result(Result),
                    expected(Expected),
                    validity(incorrect),
                    components(improper_chain_loss_components(unit(whole), Count, Base)),
                    deformation_of(improper_fraction_iteration),
                    misconception_family(improper_fraction_reset),
                    evidence(LossState)
                  ]),
    Trace = [ establish_referent_whole(unit(whole)),
              iterate_unit_past_whole(Count, Base),
              lose_original_referent_whole_chain,
              reset_completion_norm(Count),
              rename_result_to_new_whole(Result, expected(Expected)),
              kernel_trace(KTrace)
            ].
% -----------------------------------------------------------------------------
% Band 4 — recursive partition (productive) / clear inner referent (deformation)
%
% Fraction of a fraction, built by applying the partitioning automaton to its
% own output: partition the whole into OuterBase, disembed one part, partition
% THAT part into InnerBase. The composite unit is 1/(OuterBase*InnerBase) of the
% original whole. The recursion — partitioning a part rather than a fresh whole
% — is the content (L&N: nested partition of a unit object). The deformation
% partitions the part but names the result relative to the inner whole (the
% outer part), losing the original referent: 1/InnerBase instead of the product.
% This complements the existing area-model fraction-multiplication pairs with a
% primitive-composed account.
% -----------------------------------------------------------------------------
run_fraction_action(recursive_partition, OuterBase, InnerBase, Outcome, Trace) :-
    positive_integer(OuterBase),
    positive_integer(InnerBase),
    rec(OuterBase, RecOuter),
    rec(InnerBase, RecInner),
    run_recursive_partition(unit(whole), RecOuter, RecInner, InnerPart, RPHist),
    CompositeBase is OuterBase * InnerBase,
    unit_fraction_of_unit_fraction(RecInner, RecOuter, unit(whole), mc3, UFState, _UFTrace),
    Result = fraction(1, CompositeBase),
    Outcome = action_outcome(
                  recursive_partition,
                  [ classification(productive),
                    cluster(fraction_recursive_partition),
                    automaton_state(part_of_part),
                    vocabulary([referent_whole, unit_fraction, partition_a_part,
                                nested_partition, composite_unit, unit_of_unit,
                                recursion_as_content]),
                    result(Result),
                    expected(Result),
                    validity(correct),
                    components(recursive_partition_components(OuterBase, InnerBase, CompositeBase)),
                    justification(nested_partition_of_unit_object),
                    grounded_by(grounds_inference(arithmetic_is_object_construction,
                                                  fraction_multiplication_as_part_of_part,
                                                  nested_partition_of_unit_object)),
                    elaborates(divaded_fractional_units:unit_fraction_of_unit_fraction/6),
                    evidence(part(InnerPart, UFState))
                  ]),
    Trace = [ partition_whole_into_equal_units(OuterBase),
              disembed_unit_fraction(fraction(1, OuterBase)),
              partition_that_part_again(InnerBase),
              name_part_of_part_relative_to_whole(Result),
              recognize_composite_base_as_product(OuterBase, InnerBase, CompositeBase),
              recursive_partition_trace(RPHist)
            ].
run_fraction_action(clear_inner_referent, OuterBase, InnerBase, Outcome, Trace) :-
    positive_integer(OuterBase),
    positive_integer(InnerBase),
    rec(OuterBase, RecOuter),
    rec(InnerBase, RecInner),
    run_recursive_partition(unit(whole), RecOuter, RecInner, InnerPart, _RPHist),
    CompositeBase is OuterBase * InnerBase,
    Result = fraction(1, InnerBase),
    Expected = fraction(1, CompositeBase),
    Outcome = action_outcome(
                  clear_inner_referent,
                  [ classification(deformation),
                    cluster(fraction_recursive_partition),
                    automaton_state(inner_referent),
                    vocabulary([unit_fraction, partition_a_part, nested_partition,
                                name_relative_to_inner_whole, lose_outer_referent]),
                    result(Result),
                    expected(Expected),
                    validity(incorrect),
                    components(clear_inner_referent_components(OuterBase, InnerBase, CompositeBase)),
                    deformation_of(recursive_partition),
                    misconception_family(referent_to_inner_whole_not_original),
                    evidence(part(InnerPart))
                  ]),
    Trace = [ partition_whole_into_equal_units(OuterBase),
              partition_that_part_again(InnerBase),
              name_inner_part_relative_to_outer_part(Result),
              fail_to_relate_inner_part_to_original_whole(expected(Expected)),
              lose_outer_referent
            ].
% -----------------------------------------------------------------------------
% Band 5 — fractions to algebra: solve for an unknown unit (productive) /
% iteration without reversibility (MC1 deformation)
%
% The fraction->algebra bridge (Hackenberg & Lee 2015; Hackenberg 2013; Viegut
% et al. 2024): conceiving a fraction as a number and reasoning with a
% quantitative unknown share the same units-structuring. The productive move is
% the splitting inverse applied to an UNKNOWN: to solve (P/Q)*x = Total, treat x
% as a partitionable/iterable quantity — partition Total into P parts (recover
% one q-th of x), iterate Q times (recover x = (Q/P)*Total). The whole-number
% case n*x = Total (Q=1) is the single-partition Sticker Problem (7x=28 -> x=4);
% the fractional case (Sub Problem, 4/5 p = 3) is partition-by-numerator then
% iterate-by-denominator. The MC1 deformation can iterate forward (build a total
% from a unit) but cannot run the inverse edge — partitioning is "consumed in
% activity" and yields no disembedded, re-iterable unit — so the unknown is
% never recovered. (Complements reorg_domains/fraction_algebra.pl, which models
% the distinct two-unknowns relational cliff s = (P/Q) f.)
%
% Registry signature: Count = solve(P, Q); Base = Total (a positive integer).
% NOT the splitting-group/Q+ isomorphism (not in the source); the operational
% partition<->iterate inverse on an unknown is the defensible construct.
% -----------------------------------------------------------------------------
run_fraction_action(solve_for_unit, solve(P, Q), Total, Outcome, Trace) :-
    positive_integer(P),
    positive_integer(Q),
    positive_integer(Total),
    rec(P, RecP),
    rec(Q, RecQ),
    solve_for_unit(RecP, RecQ, total(Total), UnknownUnits, SolveHist),
    Result = solved_unknown(coefficient(fraction(P, Q)),
                            total(Total),
                            reciprocal_operator(fraction(Q, P))),
    Outcome = action_outcome(
                  solve_for_unit,
                  [ classification(productive),
                    cluster(fraction_algebra_reversible),
                    automaton_state(unknown_recovered),
                    vocabulary([quantitative_unknown, iterable_unknown_unit,
                                partition_as_inverse_of_iterate, reversible_reasoning,
                                solve_for_unknown, reciprocal_operator]),
                    result(Result),
                    expected(Result),
                    validity(correct),
                    components(solve_for_unit_components(P, Q, Total)),
                    justification(splitting_inverse_applied_to_unknown),
                    requires(splitting),
                    elaborates(fraction_iterating:solve_for_unit/5),
                    evidence(solved_units(UnknownUnits))
                  ]),
    Trace = [ read_equation(times(fraction(P, Q), unknown(x)) = Total),
              treat_unknown_as_iterable_partitionable_quantity,
              partition_total_into_numerator_parts(Total, P),
              iterate_recovered_part_by_denominator(Q),
              recover_unknown(times(fraction(Q, P), Total)),
              recognize_partition_undoes_iteration_on_the_unknown,
              solve_trace(SolveHist)
            ].
run_fraction_action(iterate_only_no_reverse, solve(P, Q), Total, Outcome, Trace) :-
    positive_integer(P),
    positive_integer(Q),
    positive_integer(Total),
    Result = unknown_unrecovered,
    Expected = solved_unknown(coefficient(fraction(P, Q)),
                              total(Total),
                              reciprocal_operator(fraction(Q, P))),
    Outcome = action_outcome(
                  iterate_only_no_reverse,
                  [ classification(deformation),
                    cluster(fraction_algebra_reversible),
                    automaton_state(iteration_without_reversibility),
                    vocabulary([unknown_as_fixed, iterate_forward_only,
                                partition_consumed_in_activity, no_disembedded_unit,
                                cannot_solve_for_unknown]),
                    result(Result),
                    expected(Expected),
                    validity(incorrect),
                    components(iterate_only_no_reverse_components(P, Q, Total)),
                    deformation_of(solve_for_unit),
                    misconception_family(mc1_no_reversibility)
                  ]),
    Trace = [ read_equation(times(fraction(P, Q), unknown(x)) = Total),
              iterate_forward_only_build_total_from_a_unit,
              partitioning_consumed_in_activity_no_disembedded_part,
              cannot_run_inverse_edge_to_recover_unknown,
              fail_to_solve(expected(Expected))
            ].
run_fraction_action(number_line_fraction_comparison,
                    fraction_pair(A, B, C, D), unit(whole),
                    Outcome, Trace) :-
    run_number_line_compare(A, B, C, D, Result, Trace),
    Outcome = action_outcome(
                  number_line_fraction_comparison,
                  [ classification(productive),
                    cluster(fraction_number_line_comparison),
                    automaton_state(q_compare_positions),
                    vocabulary([q_identify_unit, q_partition_interval,
                                q_mark_off_lengths, q_locate_endpoint,
                                q_measure_with_unit_fraction,
                                q_compare_positions]),
                    input(fraction_pair(A, B, C, D)),
                    result(Result),
                    expected(Result),
                    validity(correct),
                    components(number_line_comparison_components(
                                   fraction(A, B), fraction(C, D))),
                    justification(compare_point_locations_by_distance_from_origin),
                    grounded_by(metaphor_mapping(
                                    arithmetic_is_motion_along_a_path,
                                    distance_from_origin, magnitude)),
                    elaborates(smr_frac_nl_compare:run_number_line_compare/6)
                  ]).
run_fraction_action(number_line_count_marks_not_intervals,
                    fraction_pair(A, B, C, D), unit(whole),
                    Outcome, Trace) :-
    run_number_line_compare(A, B, C, D, Expected, _ProductiveTrace),
    run_count_marks_compare(A, B, C, D, Result, Trace),
    Outcome = action_outcome(
                  number_line_count_marks_not_intervals,
                  [ classification(deformation),
                    cluster(fraction_number_line_comparison),
                    automaton_state(q_count_marks_not_intervals),
                    vocabulary([q_identify_unit, q_partition_interval,
                                q_count_marks_not_intervals,
                                q_locate_endpoint, q_compare_positions]),
                    input(fraction_pair(A, B, C, D)),
                    result(Result),
                    expected(Expected),
                    validity(incorrect),
                    components(number_line_comparison_components(
                                   fraction(A, B), fraction(C, D))),
                    deformation_of(number_line_fraction_comparison),
                    misconception_family(count_marks_not_intervals),
                    violated_invariant(interval_count_not_mark_count),
                    elaborates(smr_frac_nl_compare:run_count_marks_compare/6)
                  ]).
run_fraction_action(area_model_part_of_part, fraction_pair(A, B, C, D), unit(whole), Outcome, Trace) :-
    multiplication_components(A, B, C, D, Components),
    Components = fraction_multiplication_components(NumeratorProduct,
                                                    DenominatorProduct,
                                                    Result),
    Outcome = action_outcome(
                  area_model_part_of_part,
                  [ classification(productive),
                    cluster(fraction_area_model_multiplication),
                    automaton_state(fraction_area_model),
                    vocabulary([referent_whole, unit_square, rectangle_model,
                                vertical_partition, horizontal_partition,
                                small_rectangle, denominator_product,
                                numerator_product, part_of_part]),
                    result(Result),
                    expected(Result),
                    validity(correct),
                    components(Components),
                    justification(area_model),
                    elaborates(divaded_fractional_units:nonunit_fraction_of_nonunit_fraction/8)
                  ]),
    Trace = [ establish_referent_whole(unit(whole)),
              partition_unit_square_vertically(B),
              select_first_fraction_strip(fraction(A, B)),
              partition_each_strip_horizontally(D),
              select_part_of_part_in_strip(fraction(C, D)),
              count_small_rectangles_in_whole(DenominatorProduct),
              count_small_rectangles_selected(NumeratorProduct),
              read_off_part_of_part(Result)
            ].
run_fraction_action(unit_fraction_denominator_product_rule, fraction_pair(A, B, C, D), unit(whole), Outcome, Trace) :-
    multiplication_components(A, B, C, D, Components),
    Components = fraction_multiplication_components(NumeratorProduct,
                                                    DenominatorProduct,
                                                    Result),
    UnitFraction = fraction(1, DenominatorProduct),
    rec(1, _RecOne),
    rec(B, RecB),
    iterative_fraction(RecB, RecB, unit(whole), available_prior, _WholeState, _WholeTrace),
    Outcome = action_outcome(
                  unit_fraction_denominator_product_rule,
                  [ classification(productive),
                    cluster(fraction_area_model_multiplication),
                    automaton_state(fraction_area_model),
                    vocabulary([referent_whole, unit_fraction,
                                denominator_product, numerator_product,
                                unit_of_unit_coordination, iterate_unit_fraction,
                                nested_partition]),
                    result(Result),
                    expected(Result),
                    validity(correct),
                    components(Components),
                    justification(unit_fraction_iteration),
                    elaborates(divaded_fractional_units:unit_fraction_of_unit_fraction/6)
                  ]),
    Trace = [ establish_referent_whole(unit(whole)),
              recover_unit_fraction(fraction(1, B)),
              partition_unit_fraction_into_d_parts(B, D),
              identify_nested_unit_fraction(UnitFraction),
              compute_denominator_product(B, D, DenominatorProduct),
              compute_numerator_product(A, C, NumeratorProduct),
              iterate_nested_unit_fraction(NumeratorProduct, UnitFraction, Result),
              connect_to_unit_fraction_iteration_kernel(UnitFraction)
            ].
run_fraction_action(cross_multiplication_rule_from_pattern, fraction_pair(A, B, C, D), unit(whole), Outcome, Trace) :-
    multiplication_components(A, B, C, D, Components),
    Components = fraction_multiplication_components(NumeratorProduct,
                                                    DenominatorProduct,
                                                    Result),
    Outcome = action_outcome(
                  cross_multiplication_rule_from_pattern,
                  [ classification(productive),
                    cluster(fraction_area_model_multiplication),
                    automaton_state(fraction_cross_multiplication_rule),
                    vocabulary([referent_whole, cross_multiplication,
                                multiply_numerators, multiply_denominators,
                                small_area_justification, rule_ground,
                                area_model_re_grounding]),
                    result(Result),
                    expected(Result),
                    validity(correct),
                    components(Components),
                    justification(area_model),
                    elaborates(divaded_fractional_units:nonunit_fraction_of_nonunit_fraction/8)
                  ]),
    Trace = [ identify_rule_pattern(multiply_numerators_multiply_denominators),
              apply_cross_multiplication_pattern(fraction(A, B), fraction(C, D)),
              compute_numerator_product(A, C, NumeratorProduct),
              compute_denominator_product(B, D, DenominatorProduct),
              propose_result(Result),
              justify_via_area_model_part_of_part(Result),
              identify_denominator_product_as_whole_rectangle_area(DenominatorProduct),
              identify_numerator_product_as_selected_area(NumeratorProduct)
            ].
run_fraction_action(cross_multiplication_rule_without_ground, fraction_pair(A, B, C, D), unit(whole), Outcome, Trace) :-
    multiplication_components(A, B, C, D, Components),
    Components = fraction_multiplication_components(NumeratorProduct,
                                                    DenominatorProduct,
                                                    Result),
    Outcome = action_outcome(
                  cross_multiplication_rule_without_ground,
                  [ classification(deformation),
                    cluster(fraction_area_model_multiplication),
                    automaton_state(fraction_cross_multiplication_rule),
                    vocabulary([cross_multiplication,
                                multiply_numerators, multiply_denominators,
                                rule_without_ground, procedural_pattern_recall,
                                no_area_model_justification]),
                    result(Result),
                    expected(Result),
                    validity(correct),
                    components(Components),
                    deformation_of(cross_multiplication_rule_from_pattern),
                    misconception_family(rule_without_grounding)
                  ]),
    Trace = [ recall_rule_pattern(multiply_numerators_multiply_denominators),
              apply_cross_multiplication_pattern(fraction(A, B), fraction(C, D)),
              compute_numerator_product(A, C, NumeratorProduct),
              compute_denominator_product(B, D, DenominatorProduct),
              produce_result_without_area_model_ground(Result),
              skip_area_model_justification(Result)
            ].

% -----------------------------------------------------------------------------
% Co-denominator fraction addition routed through CGI numerator dispatch
%
% Same-denominator fraction addition reuses the whole-number CGI machinery
% at the numerator level. Dispatch is in `fraction_cgi_dispatch`; here we
% register the cross-product (CGI Kind × productive/deformation) as
% fraction Kinds that the registry can address.
%
% Empirical motivation: at base 10 (the operative base of CGI), 3/10 + 7/10
% triggers count_on_from_larger over numerators 3 and 7; 7/10 + 8/10
% triggers make_ten_split_leftover over numerators 7 and 8. The
% Hackenberg-Norton three-level units-coordination is carried in the
% Trace as an annotation alongside the kernel CGI trace.
%
% Registry signature: Count = fraction_pair(A, D, B, D), Base = unit(whole).
% Same-denominator constraint enforced inside fraction_cgi_addition.

run_fraction_action(co_denominator_count_on_from_larger,
                    fraction_pair(A, D, B, D), unit(whole),
                    Outcome, Trace) :-
    fraction_cgi_addition(count_on_from_larger,
                          fraction(A, D), fraction(B, D),
                          CGIOutcome, Annotation),
    Outcome = action_outcome(
                  co_denominator_count_on_from_larger,
                  [ classification(productive),
                    cluster(co_denominator_cgi_dispatch),
                    automaton_state(fraction_co_denominator_cgi),
                    vocabulary([same_denominator, numerator_count_on,
                                three_level_units_coordination,
                                referent_whole, unit_fraction]),
                    expected(CGIOutcome),
                    validity(correct),
                    elaborates(fraction_cgi_dispatch:fraction_cgi_addition/5),
                    cgi_kind(count_on_from_larger),
                    cgi_outcome(CGIOutcome),
                    annotation(Annotation)
                  ]),
    Trace = [ confirm_same_denominator(D),
              hold_referent_whole_at(fraction(D, D)),
              hold_unit_fraction_at(fraction(1, D)),
              dispatch_to_cgi(count_on_from_larger, numerators(A, B)),
              cgi_kernel_outcome(CGIOutcome),
              attach_three_level_units_coordination(Annotation)
            ].

run_fraction_action(co_denominator_make_ten_split_leftover,
                    fraction_pair(A, D, B, D), unit(whole),
                    Outcome, Trace) :-
    fraction_cgi_addition(make_ten_split_leftover,
                          fraction(A, D), fraction(B, D),
                          CGIOutcome, Annotation),
    Outcome = action_outcome(
                  co_denominator_make_ten_split_leftover,
                  [ classification(productive),
                    cluster(co_denominator_cgi_dispatch),
                    automaton_state(fraction_co_denominator_cgi),
                    vocabulary([same_denominator, numerator_make_ten,
                                split_leftover, three_level_units_coordination,
                                referent_whole, unit_fraction]),
                    expected(CGIOutcome),
                    validity(correct),
                    elaborates(fraction_cgi_dispatch:fraction_cgi_addition/5),
                    cgi_kind(make_ten_split_leftover),
                    cgi_outcome(CGIOutcome),
                    annotation(Annotation)
                  ]),
    Trace = [ confirm_same_denominator(D),
              hold_referent_whole_at(fraction(D, D)),
              hold_unit_fraction_at(fraction(1, D)),
              dispatch_to_cgi(make_ten_split_leftover, numerators(A, B)),
              cgi_kernel_outcome(CGIOutcome),
              attach_three_level_units_coordination(Annotation)
            ].

run_fraction_action(co_denominator_make_base_transfer,
                    fraction_pair(A, D, B, D), unit(whole),
                    Outcome, Trace) :-
    fraction_cgi_addition(make_base_transfer,
                          fraction(A, D), fraction(B, D),
                          CGIOutcome, Annotation),
    Outcome = action_outcome(
                  co_denominator_make_base_transfer,
                  [ classification(productive),
                    cluster(co_denominator_cgi_dispatch),
                    automaton_state(fraction_co_denominator_cgi),
                    vocabulary([same_denominator, numerator_make_base,
                                transfer_units, three_level_units_coordination,
                                referent_whole, unit_fraction]),
                    expected(CGIOutcome),
                    validity(correct),
                    elaborates(fraction_cgi_dispatch:fraction_cgi_addition/5),
                    cgi_kind(make_base_transfer),
                    cgi_outcome(CGIOutcome),
                    annotation(Annotation)
                  ]),
    Trace = [ confirm_same_denominator(D),
              hold_referent_whole_at(fraction(D, D)),
              hold_unit_fraction_at(fraction(1, D)),
              dispatch_to_cgi(make_base_transfer, numerators(A, B)),
              cgi_kernel_outcome(CGIOutcome),
              attach_three_level_units_coordination(Annotation)
            ].
run_fraction_action(measurement_division, fraction_pair(A, B, C, D), unit(whole), Outcome, Trace) :-
    % Fraction division, measurement meaning: how many copies of the divisor
    % (group size) C/D fit in the dividend (total) A/B? Elaborates N101's
    % co-measure-then-count engine; a leftover is named as a fraction of the
    % group size. Strategy-only: no canonical deformation is registered for
    % this Kind.
    rec(A, RA), rec(B, RB), rec(C, RC), rec(D, RD),
    measurement_divide_fractions(RA, RB, RC, RD, mc3, State, KernelTrace),
    State = fraction_division_state(measurement_division, Fields),
    memberchk(quotient_whole_count(RecWhole), Fields),
    memberchk(quotient_remainder_fraction(fraction(RecRemN, RecRemD)), Fields),
    rec_to_int(RecWhole, Whole),
    rec_to_int(RecRemN, RemN),
    rec_to_int(RecRemD, RemD),
    Result = fraction_division_quotient(fraction(A, B), fraction(C, D),
                                        whole_groups(Whole),
                                        remainder(fraction(RemN, RemD))),
    Outcome = action_outcome(
                  measurement_division,
                  [ classification(productive),
                    cluster(fraction_measurement_division),
                    automaton_state(fraction_measurement_division),
                    vocabulary([dividend_fraction, divisor_fraction,
                                shared_measurement_unit, measured_total,
                                measured_group_size, group_size_count,
                                quotient_remainder]),
                    result(Result),
                    expected(Result),
                    validity(correct),
                    components(State),
                    elaborates(divaded_fractional_units:measurement_divide_fractions/7),
                    evidence(existing_trace(KernelTrace))
                  ]),
    Trace = [ establish_dividend_and_divisor(fraction(A, B), fraction(C, D)),
              co_measure_both_with_a_shared_fractional_unit,
              count_how_many_group_sizes_fit(Whole),
              name_leftover_as_a_fraction_of_the_group_size(fraction(RemN, RemD)),
              name_quotient_and_remainder(Result)
            ].
run_fraction_action(reversible_measurement_division, fraction_pair(A, B, C, D), unit(whole), Outcome, Trace) :-
    % Fraction division by Tzur's reversible-generator route: recover the unit
    % generator of the divisor C/D, measure the total in that generator scale,
    % and read the quotient as total-ticks over group-ticks. This is the closest
    % productive backing for "an algorithm to divide fractions" -- it is NOT the
    % literal invert-and-multiply, which has no automaton anywhere in the repo
    % (it exists only as the premature_invert_and_multiply misconception risk).
    % Strategy-only: no canonical deformation is registered for this Kind.
    rec(A, RA), rec(B, RB), rec(C, RC), rec(D, RD),
    division_by_recovered_generator(RA, RB, RC, RD, mc3, State, KernelTrace),
    State = fraction_division_state(reversible_measurement_division, Fields),
    memberchk(quotient_fraction(fraction(RecQN, RecQD)), Fields),
    rec_to_int(RecQN, QN),
    rec_to_int(RecQD, QD),
    Result = fraction_division_quotient(fraction(A, B), fraction(C, D),
                                        quotient(fraction(QN, QD))),
    Outcome = action_outcome(
                  reversible_measurement_division,
                  [ classification(productive),
                    cluster(fraction_reversible_measurement_division),
                    automaton_state(fraction_reversible_measurement_division),
                    vocabulary([dividend_fraction, divisor_fraction,
                                recovered_generator, generator_scale,
                                measured_total, group_size_in_generator_units,
                                quotient_fraction]),
                    result(Result),
                    expected(Result),
                    validity(correct),
                    components(State),
                    elaborates(divaded_fractional_units:division_by_recovered_generator/7),
                    evidence(existing_trace(KernelTrace))
                  ]),
    Trace = [ establish_dividend_and_divisor(fraction(A, B), fraction(C, D)),
              recover_the_unit_generator_of_the_divisor,
              measure_the_total_in_generator_scale,
              form_one_group_from_the_generator_units,
              read_quotient_as_total_ticks_over_group_ticks(fraction(QN, QD))
            ].


%!  fraction_action_cluster(+Kind, -Cluster) is det.
fraction_action_cluster(unit_fraction_partition, fraction_unit_referent_operations).
fraction_action_cluster(unit_fraction_iteration, fraction_unit_referent_operations).
fraction_action_cluster(whole_number_grab, fraction_unit_referent_operations).
fraction_action_cluster(area_model_part_of_part, fraction_area_model_multiplication).
fraction_action_cluster(unit_fraction_denominator_product_rule, fraction_area_model_multiplication).
fraction_action_cluster(cross_multiplication_rule_from_pattern, fraction_area_model_multiplication).
fraction_action_cluster(cross_multiplication_rule_without_ground, fraction_area_model_multiplication).
fraction_action_cluster(co_denominator_count_on_from_larger, co_denominator_cgi_dispatch).
fraction_action_cluster(co_denominator_make_ten_split_leftover, co_denominator_cgi_dispatch).
fraction_action_cluster(co_denominator_make_base_transfer, co_denominator_cgi_dispatch).
fraction_action_cluster(splitting, fraction_reversibility_splitting).
fraction_action_cluster(iterate_given_overshoot, fraction_reversibility_splitting).
fraction_action_cluster(improper_fraction_iteration, fraction_improper_number).
fraction_action_cluster(improper_fraction_chain_loss, fraction_improper_number).
fraction_action_cluster(recursive_partition, fraction_recursive_partition).
fraction_action_cluster(clear_inner_referent, fraction_recursive_partition).
fraction_action_cluster(solve_for_unit, fraction_algebra_reversible).
fraction_action_cluster(iterate_only_no_reverse, fraction_algebra_reversible).
fraction_action_cluster(number_line_fraction_comparison,
                        fraction_number_line_comparison).
fraction_action_cluster(number_line_count_marks_not_intervals,
                        fraction_number_line_comparison).
fraction_action_cluster(measurement_division, fraction_measurement_division).
fraction_action_cluster(reversible_measurement_division, fraction_reversible_measurement_division).


%!  fraction_action_vocabulary(+Kind, -Vocabulary) is det.
fraction_action_vocabulary(unit_fraction_partition,
                           [referent_whole, equal_partition, denominator,
                            unit_fraction, inside_part, iterable_unit]).
fraction_action_vocabulary(unit_fraction_iteration,
                           [referent_whole, unit_fraction, iteration_count,
                            denominator, completion_marker, beyond_whole]).
fraction_action_vocabulary(whole_number_grab,
                           [referent_whole, unit_fraction, iteration_count,
                            denominator, whole_number_count, unit_loss]).
fraction_action_vocabulary(area_model_part_of_part,
                           [referent_whole, unit_square, rectangle_model,
                            vertical_partition, horizontal_partition,
                            small_rectangle, denominator_product,
                            numerator_product, part_of_part]).
fraction_action_vocabulary(unit_fraction_denominator_product_rule,
                           [referent_whole, unit_fraction,
                            denominator_product, numerator_product,
                            unit_of_unit_coordination, iterate_unit_fraction,
                            nested_partition]).
fraction_action_vocabulary(cross_multiplication_rule_from_pattern,
                           [referent_whole, cross_multiplication,
                            multiply_numerators, multiply_denominators,
                            small_area_justification, rule_ground,
                            area_model_re_grounding]).
fraction_action_vocabulary(cross_multiplication_rule_without_ground,
                           [cross_multiplication,
                            multiply_numerators, multiply_denominators,
                            rule_without_ground, procedural_pattern_recall,
                            no_area_model_justification]).
fraction_action_vocabulary(co_denominator_count_on_from_larger,
                           [same_denominator, numerator_count_on,
                            three_level_units_coordination,
                            referent_whole, unit_fraction]).
fraction_action_vocabulary(co_denominator_make_ten_split_leftover,
                           [same_denominator, numerator_make_ten,
                            split_leftover, three_level_units_coordination,
                            referent_whole, unit_fraction]).
fraction_action_vocabulary(co_denominator_make_base_transfer,
                           [same_denominator, numerator_make_base,
                            transfer_units, three_level_units_coordination,
                            referent_whole, unit_fraction]).
fraction_action_vocabulary(splitting,
                           [referent_whole, equal_partition, unit_fraction,
                            iterate, mutual_inverse, multiplicative_inverse,
                            whole_recovered, reversible_coordination]).
fraction_action_vocabulary(iterate_given_overshoot,
                           [referent_whole, unit_fraction, iterate_forward,
                            no_inverse_recognition, overshoot, whole_not_recovered]).
fraction_action_vocabulary(improper_fraction_iteration,
                           [referent_whole, unit_fraction, iterate_past_whole,
                            fixed_referent, freed_iterative, improper_fraction,
                            completion_marker]).
fraction_action_vocabulary(improper_fraction_chain_loss,
                           [referent_whole, unit_fraction, iterate_past_whole,
                            lose_referent_chain, reset_whole, improper_fraction_reset]).
fraction_action_vocabulary(recursive_partition,
                           [referent_whole, unit_fraction, partition_a_part,
                            nested_partition, composite_unit, unit_of_unit,
                            recursion_as_content]).
fraction_action_vocabulary(clear_inner_referent,
                           [unit_fraction, partition_a_part, nested_partition,
                            name_relative_to_inner_whole, lose_outer_referent]).
fraction_action_vocabulary(solve_for_unit,
                           [quantitative_unknown, iterable_unknown_unit,
                            partition_as_inverse_of_iterate, reversible_reasoning,
                            solve_for_unknown, reciprocal_operator]).
fraction_action_vocabulary(iterate_only_no_reverse,
                           [unknown_as_fixed, iterate_forward_only,
                            partition_consumed_in_activity, no_disembedded_unit,
                            cannot_solve_for_unknown]).
fraction_action_vocabulary(number_line_fraction_comparison,
                           [q_identify_unit, q_partition_interval,
                            q_mark_off_lengths, q_locate_endpoint,
                            q_measure_with_unit_fraction,
                            q_compare_positions]).
fraction_action_vocabulary(number_line_count_marks_not_intervals,
                           [q_identify_unit, q_partition_interval,
                            q_count_marks_not_intervals, q_locate_endpoint,
                            q_compare_positions]).
fraction_action_vocabulary(measurement_division,
                           [dividend_fraction, divisor_fraction, shared_measurement_unit,
                            measured_total, measured_group_size, group_size_count,
                            quotient_remainder]).
fraction_action_vocabulary(reversible_measurement_division,
                           [dividend_fraction, divisor_fraction, recovered_generator,
                            generator_scale, measured_total, group_size_in_generator_units,
                            quotient_fraction]).


%!  productive_fraction_deformation(+ProductiveKind, +DeformationKind, -Family) is det.
productive_fraction_deformation(unit_fraction_iteration,
                                whole_number_grab,
                                whole_number_grab).
productive_fraction_deformation(cross_multiplication_rule_from_pattern,
                                cross_multiplication_rule_without_ground,
                                rule_without_grounding).
productive_fraction_deformation(splitting,
                                iterate_given_overshoot,
                                no_splitting_iterate_overshoot).
productive_fraction_deformation(improper_fraction_iteration,
                                improper_fraction_chain_loss,
                                improper_fraction_reset).
productive_fraction_deformation(recursive_partition,
                                clear_inner_referent,
                                referent_to_inner_whole_not_original).
productive_fraction_deformation(solve_for_unit,
                                iterate_only_no_reverse,
                                mc1_no_reversibility).
productive_fraction_deformation(number_line_fraction_comparison,
                                number_line_count_marks_not_intervals,
                                count_marks_not_intervals).


%!  fraction_action_misconception_hook(+Outcome, -Family, -Hook) is semidet.
fraction_action_misconception_hook(action_outcome(Kind, Fields), Family, Hook) :-
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
fraction_action_misconception_hook(action_outcome(Kind, Fields), Family, Hook) :-
    member(classification(productive), Fields),
    productive_fraction_deformation(Kind, DeformationKind, Family),
    member(vocabulary(Vocabulary), Fields),
    Hook = action_misconception_hook(
               [ productive_action(Kind),
                 nearby_deformation(DeformationKind),
                 family(Family),
                 vocabulary(Vocabulary),
                 monitoring_focus(preserve_fraction_unit_referent(Kind)),
                 evidence(Fields)
               ]).


rec(N, Rec) :-
    integer_to_recollection(N, Rec).


% positive_integer/1 imported from math(integer_helpers).


fraction_relation(Count, Base, within_whole) :-
    Count < Base,
    !.
fraction_relation(Count, Base, completes_whole) :-
    Count =:= Base,
    !.
fraction_relation(Count, Base, extends_beyond_whole) :-
    Count > Base.


%!  multiplication_components(+A, +B, +C, +D, -Components) is semidet.
%
%   Compute numerator product, denominator product, and the resulting
%   fraction for (A/B) * (C/D). All four operands must be positive integers;
%   numerator does not have to be less than denominator (improper fractions
%   are admissible).
multiplication_components(A, B, C, D, Components) :-
    positive_integer(A),
    positive_integer(B),
    positive_integer(C),
    positive_integer(D),
    NumeratorProduct is A * C,
    DenominatorProduct is B * D,
    Result = fraction(NumeratorProduct, DenominatorProduct),
    Components = fraction_multiplication_components(NumeratorProduct,
                                                    DenominatorProduct,
                                                    Result).
