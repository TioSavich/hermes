/** <module> Ratio / proportional reasoning action/deformation pairs
 *
 * The registry boundary retains the legacy integer A:B calls and also takes
 * structured operands for proportional-reasoning tasks:
 *
 *   - ratio_pair(A, B), scale_factor(Factor);
 *   - ratio_pair(A, B), unit_rate(second_per_first|first_per_second);
 *   - ratio_pairs([ratio_pair(X1,Y1), ...]), proportionality_test;
 *   - ratio_pair(X, Y), solve_at_x(TargetX).
 *
 * Ratio terms may be positive rational expressions. Known equation pairs
 * must be positive; a target first quantity may also be zero. These
 * contracts keep quantity order explicit instead of relying on operand
 * magnitude.
 *
 * Machine formulae, in the kernel/gate idiom:
 *   scale_ratio_unit -- gate: a positive integer ratio pair and scale
 *     factor; shell: bind the factor and compose the new pair; kernel: scale
 *     both terms by the same factor.
 *   additive_extension_of_ratio -- gate: a positive integer ratio pair and
 *     scale factor; shell: bind the factor and compose the new pair; kernel:
 *     scale both terms by the same factor; mutation: carry the first-term increment to the second term.
 *   compute_unit_rate_from_ratio_pair -- gate: ordered positive ratio pair
 *     plus requested per-one referent; shell: bind quantity roles and name
 *     the rate; kernel: normalize the reference quantity to one by division.
 *   divide_larger_by_smaller_for_unit_rate -- gate: ordered positive ratio pair
 *     plus requested per-one referent; shell: bind quantity roles and name the
 *     rate; kernel: normalize the reference quantity to one by division; mutation: replace quantity roles with magnitude order.
 *   test_relation_for_proportionality -- gate: at least two positive ratio
 *     pairs; shell: accept or give a witness-bearing refusal; kernel: compare
 *     each pair's quotient with one candidate constant.
 *   inscribe_proportional_equation -- gate: a positive known pair and
 *     a nonnegative target first quantity; shell: write y=kx and substitute
 *     the target; kernel: compute k and scale the target by k.
 *
 * The proportional-equation machine enacts setting up and using the constant
 * of proportionality. It does not claim to enact covariational practice.
 * The proportionality test is a relation-license judgment, not an extension
 * of the operand gate.
 *
 * Result-producing deformation guards are explicit. The unit-rate
 * deformation requires Reported =\= Expected. The additive-extension
 * deformation requires AdditiveDenominator =\= ScaledDenominator. Thus an
 * accepted deformed run cannot coincide with its independently computed
 * answer on the admitted input.
 */

:- module(ratio_action_pairs,
          [ run_ratio_action/5,
            run_ratio_scale/6,
            ratio_action_cluster/2,
            ratio_action_vocabulary/2,
            productive_ratio_deformation/3,
            ratio_action_misconception_hook/3
          ]).

:- use_module(math(integer_helpers), [positive_integer/1]).
:- use_module(render(ratio_diagram_scene), [ratio_diagram_render_json/2]).


%!  run_ratio_action(+Kind, +A, +B, -Outcome, -Trace) is semidet.
%
%   Execute a productive or deformed proportional-reasoning step. Structured
%   operand clauses precede the legacy A:B doubling clauses.
run_ratio_action(scale_ratio_unit, ratio_pair(A, B), scale_factor(Factor),
                 Outcome, Trace) :-
    run_ratio_scale(scale_ratio_unit, A, B, Factor, Outcome, Trace).
run_ratio_action(additive_extension_of_ratio,
                 ratio_pair(A, B), scale_factor(Factor), Outcome, Trace) :-
    run_ratio_scale(additive_extension_of_ratio,
                    A, B, Factor, Outcome, Trace).
run_ratio_action(additive_extension_of_ratio,
                 ratio_pair(A, B), ratio_pair(C, D), Outcome, Trace) :-
    positive_ratio_value(A, NormalA),
    positive_ratio_value(B, NormalB),
    positive_ratio_value(C, NormalC),
    positive_ratio_value(D, NormalD),
    Factor is NormalC rdiv NormalA,
    integer(Factor),
    Factor > 1,
    run_ratio_scale(additive_extension_of_ratio,
                    NormalA, NormalB, Factor, RawOutcome, Trace),
    RawOutcome = action_outcome(additive_extension_of_ratio, RawFields),
    member(result(ratio_pair(NormalC, NormalD)), RawFields),
    replace_deformation_parent(RawFields, Fields),
    Outcome = action_outcome(additive_extension_of_ratio, Fields).
run_ratio_action(scale_ratio_unit, A, B, Outcome, Trace) :-
    run_ratio_scale(scale_ratio_unit, A, B, 2, Outcome, Trace).
run_ratio_action(additive_extension_of_ratio, A, B, Outcome, Trace) :-
    run_ratio_scale(additive_extension_of_ratio, A, B, 2, Outcome, Trace).
run_ratio_action(compute_unit_rate_from_ratio_pair,
                 ratio_pair(First, Second), unit_rate(Direction),
                 Outcome, Trace) :-
    unit_rate_components(First, Second, Direction, Components),
    Components = unit_rate_components(NormalFirst, NormalSecond,
                                      ReferenceRole, Reference,
                                      ComparedRole, Compared, Rate),
    Result = unit_rate(Direction, Rate),
    Outcome = action_outcome(
                  compute_unit_rate_from_ratio_pair,
                  [ classification(productive),
                    cluster(proportional_unit_rate_normalization),
                    automaton_state(q_unit_rate_normalization),
                    vocabulary([ratio_pair, unit_rate, per_one,
                                quantity_order, reference_quantity,
                                compared_quantity, quotient]),
                    input(ratio_pair(First, Second)),
                    normalized_input(ratio_pair(NormalFirst, NormalSecond)),
                    result(Result),
                    expected(Result),
                    invariant(rate_direction_tracks_quantity_roles),
                    validity(correct),
                    components(Components)
                  ]),
    Trace = [ identify_ratio_pair(ratio_pair(NormalFirst, NormalSecond)),
              select_per_one_referent(ReferenceRole, Reference),
              select_compared_quantity(ComparedRole, Compared),
              divide_compared_by_reference(Compared, Reference, Rate),
              inscribe_unit_rate(Direction, Rate),
              preserve_rate_quantity_order(Direction)
            ].
run_ratio_action(divide_larger_by_smaller_for_unit_rate,
                 ratio_pair(First, Second), unit_rate(Direction),
                 Outcome, Trace) :-
    unit_rate_components(First, Second, Direction, Components),
    Components = unit_rate_components(NormalFirst, NormalSecond,
                                      _ReferenceRole, _Reference,
                                      _ComparedRole, _Compared, Expected),
    magnitude_ordered_ratio_terms(NormalFirst, NormalSecond, Larger, Smaller),
    Reported is Larger rdiv Smaller,
    Reported =\= Expected,
    Result = unit_rate(Direction, Reported),
    ExpectedResult = unit_rate(Direction, Expected),
    Outcome = action_outcome(
                  divide_larger_by_smaller_for_unit_rate,
                  [ classification(deformation),
                    cluster(proportional_unit_rate_normalization),
                    automaton_state(q_unit_rate_direction_ignored),
                    vocabulary([ratio_pair, unit_rate, per_one,
                                quantity_order, magnitude_order,
                                reversed_rate, ratio_loss]),
                    input(ratio_pair(First, Second)),
                    normalized_input(ratio_pair(NormalFirst, NormalSecond)),
                    result(Result),
                    expected(ExpectedResult),
                    validity(incorrect),
                    components(Components),
                    deformation_of(compute_unit_rate_from_ratio_pair),
                    misconception_family(rate_direction_replaced_by_magnitude_order),
                    violated_invariant(rate_direction_tracks_quantity_roles)
                  ]),
    Trace = [ identify_ratio_pair(ratio_pair(NormalFirst, NormalSecond)),
              ignore_requested_rate_direction(Direction),
              order_ratio_terms_by_magnitude(Larger, Smaller),
              divide_larger_term_by_smaller_term(Larger, Smaller, Reported),
              inscribe_unit_rate(Direction, Reported),
              lose_rate_quantity_order(expected(Expected), produced(Reported))
            ].
run_ratio_action(test_relation_for_proportionality,
                 ratio_pairs(RawPairs), proportionality_test,
                 Outcome, Trace) :-
    normalize_ratio_pairs(RawPairs, Pairs),
    Pairs = [BasePair|_],
    candidate_constant(BasePair, Constant),
    \+ first_ratio_mismatch(Pairs, Constant, _),
    Result = proportional(constant_of_proportionality(Constant)),
    Outcome = action_outcome(
                  test_relation_for_proportionality,
                  [ classification(productive),
                    cluster(proportional_relation_classification),
                    automaton_state(q_proportional_relation_test),
                    vocabulary([ratio_pair, ratio_table,
                                constant_of_proportionality,
                                relation_license, proportional,
                                justified_refusal]),
                    input(ratio_pairs(RawPairs)),
                    normalized_input(ratio_pairs(Pairs)),
                    result(Result),
                    expected(Result),
                    decision(accept_relation_license),
                    validity(correct)
                  ]),
    Trace = [ identify_relation_pairs(Pairs),
              establish_candidate_constant(BasePair, Constant),
              compare_each_pair_to_constant(Pairs, Constant),
              accept_proportional_relation(Constant),
              inscribe_relation_classification(Result)
            ].
run_ratio_action(test_relation_for_proportionality,
                 ratio_pairs(RawPairs), proportionality_test,
                 Outcome, Trace) :-
    normalize_ratio_pairs(RawPairs, Pairs),
    Pairs = [BasePair|_],
    candidate_constant(BasePair, Constant),
    first_ratio_mismatch(Pairs, Constant, Witness),
    Result = refused(non_constant_ratio, Witness),
    Outcome = action_outcome(
                  test_relation_for_proportionality,
                  [ classification(productive),
                    cluster(proportional_relation_classification),
                    automaton_state(q_proportional_relation_test),
                    vocabulary([ratio_pair, ratio_table,
                                constant_of_proportionality,
                                relation_license, proportional,
                                justified_refusal]),
                    input(ratio_pairs(RawPairs)),
                    normalized_input(ratio_pairs(Pairs)),
                    result(Result),
                    expected(Result),
                    decision(refuse_relation_license),
                    validity(correct)
                  ]),
    Trace = [ identify_relation_pairs(Pairs),
              establish_candidate_constant(BasePair, Constant),
              compare_each_pair_to_constant(Pairs, Constant),
              refuse_nonproportional_relation(Witness),
              inscribe_relation_classification(Result)
            ].
run_ratio_action(inscribe_proportional_equation,
                 ratio_pair(X, Y), solve_at_x(TargetX), Outcome, Trace) :-
    positive_ratio_value(X, NormalX),
    positive_ratio_value(Y, NormalY),
    nonnegative_ratio_value(TargetX, NormalTargetX),
    Constant is NormalY rdiv NormalX,
    TargetY is Constant * NormalTargetX,
    Equation = equation(y, equals, times(Constant, x)),
    Result = proportional_equation(Equation,
                                   value_pair(NormalTargetX, TargetY)),
    Outcome = action_outcome(
                  inscribe_proportional_equation,
                  [ classification(productive),
                    cluster(proportional_equation_construction),
                    automaton_state(q_proportional_equation_setup_and_use),
                    vocabulary([ratio_pair, constant_of_proportionality,
                                variable_role, proportional_equation,
                                substitution, multiplicative_scaling]),
                    input(ratio_pair(X, Y)),
                    normalized_input(ratio_pair(NormalX, NormalY)),
                    target_first_quantity(NormalTargetX),
                    result(Result),
                    expected(Result),
                    boundary(does_not_enact_covariational_practice),
                    validity(correct)
                  ]),
    Trace = [ identify_ratio_pair(ratio_pair(NormalX, NormalY)),
              compute_constant_of_proportionality(NormalX, NormalY, Constant),
              bind_proportional_variable_roles(first_quantity(x),
                                               second_quantity(y)),
              inscribe_y_equals_kx(Constant, Equation),
              substitute_target_first_quantity(NormalTargetX),
              scale_target_by_constant(NormalTargetX, Constant, TargetY),
              inscribe_proportional_value(NormalTargetX, TargetY)
            ].
run_ratio_action(construct_referent_ratio_diagram,
                 referent(FirstLabel, FirstCount),
                 referent(SecondLabel, SecondCount), Outcome, Trace) :-
    ratio_referent_components(FirstLabel, FirstCount,
                              SecondLabel, SecondCount, Scene),
    Result = ratio_statement(FirstLabel, FirstCount,
                             SecondLabel, SecondCount),
    Outcome = action_outcome(
                  construct_referent_ratio_diagram,
                  [ classification(productive),
                    cluster(proportional_ratio_referent_coordination),
                    automaton_state(coordinate_ordered_referents_and_counts),
                    vocabulary([ratio, ratio_language, ratio_diagram,
                                first_referent, second_referent,
                                ordered_pair, for_every, tape_diagram]),
                    input(referents(FirstLabel, SecondLabel)),
                    counts(FirstCount, SecondCount), result(Result),
                    expected(Result), representation(Scene),
                    invariant(ratio_order_tracks_named_referents),
                    validity(correct)
                  ]),
    Trace = [ establish_first_referent(FirstLabel, FirstCount),
              establish_second_referent(SecondLabel, SecondCount),
              coordinate_referent_counts,
              construct_ratio_diagram(FirstCount, SecondCount),
              inscribe_ordered_ratio(FirstLabel-SecondLabel,
                                     FirstCount-SecondCount)
            ].
run_ratio_action(reverse_ratio_referent_order,
                 referent(FirstLabel, FirstCount),
                 referent(SecondLabel, SecondCount), Outcome, Trace) :-
    ratio_referent_components(FirstLabel, FirstCount,
                              SecondLabel, SecondCount, Scene),
    FirstCount =\= SecondCount,
    Expected = ratio_statement(FirstLabel, FirstCount,
                               SecondLabel, SecondCount),
    Result = ratio_statement(FirstLabel, SecondCount,
                             SecondLabel, FirstCount),
    Outcome = action_outcome(
                  reverse_ratio_referent_order,
                  [ classification(deformation),
                    cluster(proportional_ratio_referent_coordination),
                    automaton_state(read_ratio_terms_against_reversed_referents),
                    vocabulary([ratio, ratio_language, ratio_diagram,
                                referent_order, reversed_terms, ratio_loss]),
                    input(referents(FirstLabel, SecondLabel)),
                    counts(FirstCount, SecondCount), result(Result),
                    expected(Expected), representation(Scene),
                    deformation_of(construct_referent_ratio_diagram),
                    misconception_family(reversed_ratio_referent_order),
                    violated_invariant(ratio_order_tracks_named_referents),
                    validity(incorrect)
                  ]),
    Trace = [ establish_counts_without_order(FirstCount, SecondCount),
              reverse_term_referent_alignment,
              inscribe_reversed_ratio(FirstLabel-SecondLabel,
                                      SecondCount-FirstCount),
              lose_ordered_referent_relation
            ].


%!  run_ratio_scale(+Kind, +A, +B, +Factor, -Outcome, -Trace) is semidet.
%
%   General scaling form. The registry's legacy run_ratio_action/5 surface is
%   the Factor=2 instance; curriculum task compilers can retain the factor.
run_ratio_scale(scale_ratio_unit, A, B, Factor, Outcome, Trace) :-
    ratio_components(A, B, Factor, Components),
    Components = ratio_components(ScaleFactor, ScaledNumerator,
                                  ScaledDenominator, _Increment, _AdditiveDenominator),
    Result = ratio_pair(ScaledNumerator, ScaledDenominator),
    Outcome = action_outcome(
                  scale_ratio_unit,
                  [ classification(productive),
                    cluster(proportional_ratio_unit_coordination),
                    automaton_state(equivalent_ratio_scaling),
                    vocabulary([ratio_pair, unit_ratio, scale_factor,
                                multiplicative_scaling, equivalent_ratio,
                                first_term, second_term]),
                    result(Result),
                    expected(Result),
                    validity(correct),
                    components(Components)
                  ]),
    Trace = [ identify_base_ratio(ratio_pair(A, B)),
              identify_scale_factor(ScaleFactor),
              scale_first_term_multiplicatively(A, ScaleFactor, ScaledNumerator),
              scale_second_term_multiplicatively(B, ScaleFactor, ScaledDenominator),
              compose_equivalent_ratio(Result),
              preserve_multiplicative_unit_ratio(Result)
            ].
run_ratio_scale(additive_extension_of_ratio, A, B, Factor, Outcome, Trace) :-
    ratio_components(A, B, Factor, Components),
    Components = ratio_components(ScaleFactor, ScaledNumerator,
                                  ScaledDenominator, Increment, AdditiveDenominator),
    Expected = ratio_pair(ScaledNumerator, ScaledDenominator),
    Result = ratio_pair(ScaledNumerator, AdditiveDenominator),
    AdditiveDenominator =\= ScaledDenominator,
    Outcome = action_outcome(
                  additive_extension_of_ratio,
                  [ classification(deformation),
                    cluster(proportional_ratio_unit_coordination),
                    automaton_state(equivalent_ratio_scaling),
                    vocabulary([ratio_pair, unit_ratio,
                                additive_comparison, first_term_increment,
                                second_term_increment, ratio_loss]),
                    result(Result),
                    expected(Expected),
                    validity(incorrect),
                    components(Components),
                    deformation_of(scale_ratio_unit),
                    misconception_family(additive_comparison_in_proportion)
                  ]),
    Trace = [ identify_base_ratio(ratio_pair(A, B)),
              compute_first_term_increment(A, ScaleFactor, ScaledNumerator, Increment),
              add_first_term_increment_to_second_term(B, Increment, AdditiveDenominator),
              compose_additive_pair(Result),
              lose_multiplicative_unit_ratio(expected(Expected), produced(Result))
            ].


%!  ratio_action_cluster(+Kind, -Cluster) is det.
ratio_action_cluster(scale_ratio_unit, proportional_ratio_unit_coordination).
ratio_action_cluster(additive_extension_of_ratio, proportional_ratio_unit_coordination).
ratio_action_cluster(compute_unit_rate_from_ratio_pair,
                     proportional_unit_rate_normalization).
ratio_action_cluster(divide_larger_by_smaller_for_unit_rate,
                     proportional_unit_rate_normalization).
ratio_action_cluster(test_relation_for_proportionality,
                     proportional_relation_classification).
ratio_action_cluster(inscribe_proportional_equation,
                     proportional_equation_construction).
ratio_action_cluster(construct_referent_ratio_diagram,
                     proportional_ratio_referent_coordination).
ratio_action_cluster(reverse_ratio_referent_order,
                     proportional_ratio_referent_coordination).


%!  ratio_action_vocabulary(+Kind, -Vocabulary) is det.
ratio_action_vocabulary(scale_ratio_unit,
                        [ratio_pair, unit_ratio, scale_factor,
                         multiplicative_scaling, equivalent_ratio,
                         first_term, second_term]).
ratio_action_vocabulary(additive_extension_of_ratio,
                        [ratio_pair, unit_ratio,
                         additive_comparison, first_term_increment,
                         second_term_increment, ratio_loss]).
ratio_action_vocabulary(compute_unit_rate_from_ratio_pair,
                        [ratio_pair, unit_rate, per_one,
                         quantity_order, reference_quantity,
                         compared_quantity, quotient]).
ratio_action_vocabulary(divide_larger_by_smaller_for_unit_rate,
                        [ratio_pair, unit_rate, per_one,
                         quantity_order, magnitude_order,
                         reversed_rate, ratio_loss]).
ratio_action_vocabulary(test_relation_for_proportionality,
                        [ratio_pair, ratio_table,
                         constant_of_proportionality,
                         relation_license, proportional,
                         justified_refusal]).
ratio_action_vocabulary(inscribe_proportional_equation,
                        [ratio_pair, constant_of_proportionality,
                         variable_role, proportional_equation,
                         substitution, multiplicative_scaling]).
ratio_action_vocabulary(construct_referent_ratio_diagram,
                        [ratio, ratio_language, ratio_diagram,
                         first_referent, second_referent,
                         ordered_pair, for_every, tape_diagram]).
ratio_action_vocabulary(reverse_ratio_referent_order,
                        [ratio, ratio_language, ratio_diagram,
                         referent_order, reversed_terms, ratio_loss]).


%!  productive_ratio_deformation(+ProductiveKind, +DeformationKind, -Family) is det.
productive_ratio_deformation(scale_ratio_unit,
                             additive_extension_of_ratio,
                             additive_comparison_in_proportion).
productive_ratio_deformation(compute_unit_rate_from_ratio_pair,
                             divide_larger_by_smaller_for_unit_rate,
                             rate_direction_replaced_by_magnitude_order).
productive_ratio_deformation(test_relation_for_proportionality,
                             additive_extension_of_ratio,
                             additive_comparison_in_proportion).
productive_ratio_deformation(construct_referent_ratio_diagram,
                             reverse_ratio_referent_order,
                             reversed_ratio_referent_order).


%!  ratio_action_misconception_hook(+Outcome, -Family, -Hook) is semidet.
ratio_action_misconception_hook(action_outcome(Kind, Fields), Family, Hook) :-
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
ratio_action_misconception_hook(action_outcome(Kind, Fields), Family, Hook) :-
    member(classification(productive), Fields),
    productive_ratio_deformation(Kind, DeformationKind, Family),
    member(vocabulary(Vocabulary), Fields),
    ratio_monitoring_focus(Kind, Focus),
    Hook = action_misconception_hook(
               [ productive_action(Kind),
                 nearby_deformation(DeformationKind),
                 family(Family),
                 vocabulary(Vocabulary),
                 monitoring_focus(Focus),
                 evidence(Fields)
               ]).


ratio_components(A, B, ScaleFactor,
                 ratio_components(ScaleFactor, ScaledNumerator,
                                  ScaledDenominator, Increment, AdditiveDenominator)) :-
    positive_integer(A),
    positive_integer(B),
    positive_integer(ScaleFactor),
    ScaleFactor > 1,
    ScaledNumerator is A * ScaleFactor,
    ScaledDenominator is B * ScaleFactor,
    Increment is ScaledNumerator - A,
    AdditiveDenominator is B + Increment.

replace_deformation_parent([], []).
replace_deformation_parent([deformation_of(scale_ratio_unit)|Fields],
                           [deformation_of(test_relation_for_proportionality)|Fields]) :-
    !.
replace_deformation_parent([Field|Fields], [Field|Reframed]) :-
    replace_deformation_parent(Fields, Reframed).

unit_rate_components(First, Second, Direction,
                     unit_rate_components(NormalFirst, NormalSecond,
                                          ReferenceRole, Reference,
                                          ComparedRole, Compared, Rate)) :-
    positive_ratio_value(First, NormalFirst),
    positive_ratio_value(Second, NormalSecond),
    unit_rate_roles(Direction, NormalFirst, NormalSecond,
                    ReferenceRole, Reference, ComparedRole, Compared),
    Rate is Compared rdiv Reference.

unit_rate_roles(second_per_first, First, Second,
                first_quantity, First, second_quantity, Second).
unit_rate_roles(first_per_second, First, Second,
                second_quantity, Second, first_quantity, First).

magnitude_ordered_ratio_terms(First, Second, Larger, Smaller) :-
    (   First >= Second
    ->  Larger = First, Smaller = Second
    ;   Larger = Second, Smaller = First
    ).

normalize_ratio_pairs([First, Second|RawRest],
                      [NormalFirst, NormalSecond|NormalRest]) :-
    normalize_ratio_pair(First, NormalFirst),
    normalize_ratio_pair(Second, NormalSecond),
    normalize_ratio_pair_rest(RawRest, NormalRest).

normalize_ratio_pair_rest([], []).
normalize_ratio_pair_rest([Pair|Pairs], [NormalPair|NormalPairs]) :-
    normalize_ratio_pair(Pair, NormalPair),
    normalize_ratio_pair_rest(Pairs, NormalPairs).

normalize_ratio_pair(ratio_pair(X, Y), ratio_pair(NormalX, NormalY)) :-
    positive_ratio_value(X, NormalX),
    positive_ratio_value(Y, NormalY).

candidate_constant(ratio_pair(X, Y), Constant) :-
    Constant is Y rdiv X.

first_ratio_mismatch([ratio_pair(X, Y)|_], Constant,
                     witness(ratio_pair(X, Y),
                             expected_constant(Constant),
                             observed_constant(Observed))) :-
    Observed is Y rdiv X,
    Observed =\= Constant,
    !.
first_ratio_mismatch([_|Pairs], Constant, Witness) :-
    first_ratio_mismatch(Pairs, Constant, Witness).

positive_ratio_value(Expression, Value) :-
    catch(Value is Expression, _, fail),
    rational(Value),
    Value > 0.

nonnegative_ratio_value(Expression, Value) :-
    catch(Value is Expression, _, fail),
    rational(Value),
    Value >= 0.

ratio_referent_components(FirstLabel, FirstCount,
                          SecondLabel, SecondCount, Scene) :-
    atom(FirstLabel), atom(SecondLabel), FirstLabel \== SecondLabel,
    positive_integer(FirstCount), positive_integer(SecondCount),
    ratio_diagram_render_json(
        ratio(FirstLabel, FirstCount, SecondLabel, SecondCount), Scene),
    Scene.frames = [_|_].

ratio_monitoring_focus(scale_ratio_unit,
                       preserve_multiplicative_unit_ratio(scale_ratio_unit)).
ratio_monitoring_focus(compute_unit_rate_from_ratio_pair,
                       preserve_rate_quantity_order(
                           compute_unit_rate_from_ratio_pair)).
ratio_monitoring_focus(test_relation_for_proportionality,
                       preserve_multiplicative_relation_license(
                           test_relation_for_proportionality)).
ratio_monitoring_focus(construct_referent_ratio_diagram,
                       preserve_ordered_ratio_referents(
                           construct_referent_ratio_diagram)).


% positive_integer/1 imported from math(integer_helpers).
