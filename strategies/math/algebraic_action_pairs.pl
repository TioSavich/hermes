/** <module> Algebraic action/deformation pairs (automata-012)
 *
 * Axis decision (CODEX_BACKLOG.md automata-012, first iteration): the
 * algebraic axis enters with one productive automaton drawn from the
 * round-2 review batch's first algebraic motivation. The scope decision
 * for this first batch is:
 *
 *   In scope:  treat an algebraic expression with a variable assignment
 *              as a program to execute -- walk the expression tree,
 *              substitute variable values, and combine sub-results via
 *              grounded arithmetic primitives.
 *   Out of scope: general simplification, factoring, exponent laws beyond
 *                 repeated-factor expansion, symbolic solution beyond
 *                 one-unknown linear equations, and equation systems.
 *                 Expression evaluation is integer-valued; contextual equation
 *                 construction may retain rational coefficients without
 *                 solving them.
 *
 * Productive automaton registered here:
 *
 *   - `programming_expression_evaluation`
 *       Given an algebraic expression in the term shape documented
 *       below and an assignment of variable bindings, evaluate the
 *       expression as a program. Walk the expression tree, substitute
 *       variable references against the assignment, and combine via
 *       the grounded-arithmetic kernel. Source: extract-032 Gray 1999
 *       (`programming_expression_evaluation`) -- the article frames
 *       expression evaluation as treating the algebraic expression as
 *       a procedure to execute, distinct from manipulating it as a
 *       symbolic object.
 *
 * Expression term shape. Expressions are nested compound terms:
 *
 *   - `int(N)`        -- an integer literal (N is a non-negative integer).
 *   - `var(Name)`     -- a reference to a variable named `Name` (atom).
 *   - `add(L, R)`     -- the sum of two sub-expressions.
 *   - `mult(L, R)`    -- the product of two sub-expressions.
 *
 * Assignment shape. Assignment is a list of bindings of the form
 * `var(Name) = int(N)`. The empty list is the empty assignment.
 *
 * Kernel coupling. The `programming_expression_evaluation` walk routes
 * `add(L, R)` through `grounded_arithmetic:add_grounded/3` and
 * `mult(L, R)` through `grounded_arithmetic:multiply_grounded/3`.
 * Integer literals are grounded via `integer_to_recollection/2` and
 * lifted back through `recollection_to_integer/2` at sub-result
 * boundaries so the host trace can carry integer-valued snapshots.
 * Each kernel call (the grounded add or multiply, and the lift in/out
 * of recollections) is logged into the `kernel_trace` field of the
 * outcome.
 *
 * Deferred-grounding fallback. If a sub-expression operator is
 * encountered that has no kernel primitive in this first iteration
 * (for example a `power(_, _)` node), the trace records a
 * `not_yet_grounded(Operator)` marker, falls back to native `is/2`
 * arithmetic for that sub-expression, and the outcome carries
 * `evidence(deferred_grounding(Operator))` so consumers know the
 * value is not kernel-grounded. The first iteration only uses
 * `add/2` and `mult/2`; the fallback exists to keep the module
 * extensible without rewriting the trace shape.
 *
 * Pattern-generalization extension. `linear_pattern_contextual_rule`
 * models Lannin 2005-style contextual linear rules: first value plus an
 * accumulated constant change. Its paired deformation,
 * `guess_and_check_rule`, applies a locally fitted symbolic rule to a
 * changed context without preserving the contextual rate and initial-value
 * relation.
 *
 * Equation extensions. `contextual_linear_equation_construction` preserves
 * quantity roles while inscribing Ax+B=C. `equation_truth_by_substitution`
 * evaluates both expressions under one assignment. The balance action consumes
 * `balance_solve_witness/4` for finite one-unknown nonnegative-integer cases.
 * Its paired deformation changes one side only; the equation-truth deformation
 * stops after computing the left expression.
 * Symbolic extensions preserve declared variables during expression
 * construction, expand one factor over a binary sum, and elaborate a
 * nonnegative whole-number exponent into repeated factors. Structural
 * exponential equivalence is certified only when those expanded forms match
 * exactly; it does not claim a general computer-algebra normalizer.
 */

:- module(algebraic_action_pairs,
          [ run_algebraic_action/5,
            algebraic_action_cluster/2,
            algebraic_action_vocabulary/2,
            productive_algebraic_deformation/3,
            algebraic_action_misconception_hook/3
          ]).

:- use_module(formalization(grounded_arithmetic),
              [ add_grounded/3,
                multiply_grounded/3,
                integer_to_recollection/2,
                recollection_to_integer/2
              ]).
:- use_module(render(balance_scale_scene),
              [ balance_solve_witness/4,
                balance_render_json/2,
                balance_compare_json/2
              ]).


%!  run_algebraic_action(+Kind, +Expression, +Assignment, -Outcome, -Trace) is semidet.
%
%   Execute a productive algebraic action automaton. Expression is an
%   algebraic expression in the term shape documented in the module
%   header; Assignment is a list of `var(Name) = int(N)` bindings.
run_algebraic_action(programming_expression_evaluation, Expression, Assignment,
                     Outcome, Trace) :-
    valid_expression(Expression),
    valid_assignment(Assignment),
    evaluate_expression(Expression, Assignment, Value, EvalSteps, KernelSteps),
    integer(Value),
    Outcome = action_outcome(
                  programming_expression_evaluation,
                  [ classification(productive),
                    cluster(algebraic_expression_evaluation_as_program),
                    automaton_state(walking_expression_tree),
                    vocabulary([algebraic_expression, variable_assignment,
                                variable_substitution, expression_tree,
                                sub_expression, evaluate_as_program,
                                procedural_evaluation, integer_value]),
                    result(value(Value)),
                    expected(value(Value)),
                    validity(correct),
                    expression(Expression),
                    assignment(Assignment),
                    elaborates([formalization:grounded_arithmetic:add_grounded/3,
                                formalization:grounded_arithmetic:multiply_grounded/3,
                                formalization:grounded_arithmetic:integer_to_recollection/2]),
                    kernel_trace(KernelSteps),
                    evidence(grounded_evaluation(Value))
                  ]),
    Trace = [ identify_expression(Expression),
              identify_assignment(Assignment),
              walk_expression_tree(EvalSteps),
              kernel_trace(KernelSteps),
              report_value(value(Value))
            ].
run_algebraic_action(contextual_linear_equation_construction,
                     linear_context(Unknown, Coefficient, Offset, Total,
                                    ReferentRoles),
                     equation_form(ax_plus_b_equals_c), Outcome, Trace) :-
    atom(Unknown),
    maplist(number, [Coefficient, Offset, Total]),
    Coefficient =\= 0,
    valid_referent_roles(ReferentRoles),
    Equation = equation(
                   add(mult(number(Coefficient), var(Unknown)), number(Offset)),
                   equals,
                   number(Total)),
    Outcome = action_outcome(
                  contextual_linear_equation_construction,
                  [ classification(productive),
                    cluster(algebraic_context_to_equation_relation),
                    automaton_state(assign_quantity_roles_then_inscribe_relation),
                    vocabulary([context, unknown_quantity, variable,
                                coefficient, constant, total, referent_role,
                                equation, equality_relation, representation]),
                    input(linear_context(Unknown, Coefficient, Offset, Total,
                                         ReferentRoles)),
                    result(Equation),
                    expected(Equation),
                    invariant(each_symbol_retains_contextual_quantity_role),
                    validity(correct)
                  ]),
    Trace = [ identify_unknown_quantity(Unknown),
              assign_referent_roles(ReferentRoles),
              coordinate_repeated_unknown(Coefficient, Unknown),
              coordinate_constant_offset(Offset),
              relate_expression_to_total(Total),
              inscribe_equation(Equation)
            ].
run_algebraic_action(equation_truth_by_substitution,
                     equation(LeftExpression, RightExpression), Assignment,
                     Outcome, Trace) :-
    valid_expression(LeftExpression),
    valid_expression(RightExpression),
    valid_assignment(Assignment),
    evaluate_expression(LeftExpression, Assignment, LeftValue,
                        LeftSteps, LeftKernel),
    evaluate_expression(RightExpression, Assignment, RightValue,
                        RightSteps, RightKernel),
    equality_truth(LeftValue, RightValue, Truth),
    append(LeftKernel, RightKernel, KernelSteps),
    Outcome = action_outcome(
                  equation_truth_by_substitution,
                  [ classification(productive),
                    cluster(algebraic_equation_truth_and_solution),
                    automaton_state(substitute_then_compare_both_expressions),
                    vocabulary([equation, variable_assignment, substitution,
                                left_expression, right_expression, equality,
                                true_equation, false_equation, solution]),
                    input(equation(LeftExpression, RightExpression)),
                    assignment(Assignment),
                    evaluated_sides(LeftValue, RightValue),
                    result(truth_value(Truth)),
                    expected(truth_value(Truth)),
                    kernel_trace(KernelSteps),
                    invariant(both_sides_use_same_variable_assignment),
                    validity(correct)
                  ]),
    Trace = [ substitute_assignment_into_both_sides(Assignment),
              evaluate_left_expression(LeftSteps, LeftValue),
              evaluate_right_expression(RightSteps, RightValue),
              compare_values_for_equality(LeftValue, RightValue, Truth)
            ].
run_algebraic_action(operational_equals_left_value,
                     equation(LeftExpression, RightExpression), Assignment,
                     Outcome, Trace) :-
    valid_expression(LeftExpression),
    valid_expression(RightExpression),
    valid_assignment(Assignment),
    evaluate_expression(LeftExpression, Assignment, LeftValue,
                        LeftSteps, LeftKernel),
    evaluate_expression(RightExpression, Assignment, RightValue,
                        _RightSteps, _RightKernel),
    equality_truth(LeftValue, RightValue, Truth),
    Outcome = action_outcome(
                  operational_equals_left_value,
                  [ classification(deformation),
                    cluster(algebraic_equation_truth_and_solution),
                    automaton_state(compute_left_expression_and_stop_at_equals),
                    vocabulary([equation, operational_equals, left_to_right,
                                compute_answer, ignored_right_expression]),
                    input(equation(LeftExpression, RightExpression)),
                    assignment(Assignment),
                    result(value(LeftValue)),
                    expected(truth_value(Truth)),
                    kernel_trace(LeftKernel),
                    deformation_of(equation_truth_by_substitution),
                    misconception_family(operational_equals_left_value),
                    violated_invariant(both_sides_use_same_variable_assignment),
                    validity(incorrect)
                  ]),
    Trace = [ substitute_assignment_into_left_side(Assignment),
              evaluate_left_expression(LeftSteps, LeftValue),
              treat_equals_as_answer_signal,
              ignore_right_expression(RightExpression, RightValue)
            ].
run_algebraic_action(balance_preserving_linear_solution,
                     linear_equation(A, B, C),
                     solution_domain(nonnegative_integer), Outcome, Trace) :-
    balance_solve_witness(A, B, C, Witness),
    balance_render_json(solve_linear(A, B, C), Scene),
    successful_balance_scene(Scene),
    get_dict(solution, Witness, Solution),
    get_dict(steps, Witness, Steps),
    Outcome = action_outcome(
                  balance_preserving_linear_solution,
                  [ classification(productive),
                    cluster(algebraic_equation_as_balanced_relation),
                    automaton_state(apply_same_operation_to_both_sides),
                    vocabulary([equation, equality_relation, unknown,
                                balance, both_sides, inverse_operation,
                                equivalent_equation, solution,
                                substitution_check]),
                    input(linear_equation(A, B, C)),
                    result(value(Solution)),
                    expected(value(Solution)),
                    witness(Witness),
                    representation(Scene),
                    invariant(each_transformation_preserves_equality),
                    validity(correct)
                  ]),
    Trace = [ read_equation_as_relation(A, B, C),
              apply_balance_preserving_steps(Steps),
              isolate_unknown(Solution),
              verify_by_substitution(A, B, C, Solution)
            ].
run_algebraic_action(one_sided_equation_operation,
                     linear_equation(A, B, C),
                     solution_domain(nonnegative_integer), Outcome, Trace) :-
    balance_solve_witness(A, B, C, Witness),
    B > 0,
    balance_compare_json(solve_linear(A, B, C), Scene),
    successful_balance_scene(Scene),
    get_dict(solution, Witness, Expected),
    Wrong is C rdiv A,
    Wrong =\= Expected,
    Outcome = action_outcome(
                  one_sided_equation_operation,
                  [ classification(deformation),
                    cluster(algebraic_equation_as_balanced_relation),
                    automaton_state(remove_constant_from_expression_side_only),
                    vocabulary([equation, operational_equals, one_sided_move,
                                balance_lost, unknown, solution]),
                    input(linear_equation(A, B, C)),
                    result(value(Wrong)),
                    expected(value(Expected)),
                    representation(Scene),
                    deformation_of(balance_preserving_linear_solution),
                    misconception_family(one_sided_equation_operation),
                    violated_invariant(each_transformation_preserves_equality),
                    validity(incorrect)
                  ]),
    Trace = [ read_equals_as_instruction,
              remove_constant_from_left_side_only(B),
              leave_right_side_unchanged(C),
              divide_remaining_expression_by(A),
              report_unbalanced_value(Wrong)
            ].
run_algebraic_action(symbolic_expression_construction,
                     quantity_relation(Operator, Left, Right, ReferentRoles),
                     variable_scope(DeclaredVariables), Outcome, Trace) :-
    memberchk(Operator, [add, mult]),
    valid_expression(Left),
    valid_expression(Right),
    valid_referent_roles(ReferentRoles),
    is_list(DeclaredVariables),
    expression_variable_names(Left, LeftNames),
    expression_variable_names(Right, RightNames),
    append(LeftNames, RightNames, Names0),
    sort(Names0, Names),
    forall(member(Name, Names), memberchk(Name, DeclaredVariables)),
    Expression =.. [Operator, Left, Right],
    Outcome = action_outcome(
                  symbolic_expression_construction,
                  [ classification(productive),
                    cluster(algebraic_symbolic_expression_construction),
                    automaton_state(coordinate_quantity_roles_with_operation_tree),
                    vocabulary([algebraic_expression, variable, coefficient,
                                operation, quantity_role, expression_tree,
                                notation, representation]),
                    input(quantity_relation(Operator, Left, Right,
                                            ReferentRoles)),
                    variable_scope(DeclaredVariables),
                    result(Expression),
                    expected(Expression),
                    invariant(operation_and_referent_roles_preserved),
                    validity(correct)
                  ]),
    Trace = [ identify_quantity_roles(ReferentRoles),
              declare_variables(DeclaredVariables),
              select_operation(Operator),
              preserve_operand_structure(Left, Right),
              inscribe_expression(Expression)
            ].
run_algebraic_action(distributive_expression_rewrite,
                     mult(Factor, add(Left, Right)),
                     rewrite_direction(expand), Outcome, Trace) :-
    maplist(valid_expression, [Factor, Left, Right]),
    Expanded = add(mult(Factor, Left), mult(Factor, Right)),
    Outcome = action_outcome(
                  distributive_expression_rewrite,
                  [ classification(productive),
                    cluster(algebraic_equivalent_expression_rewrite),
                    automaton_state(distribute_factor_to_each_addend),
                    vocabulary([equivalent_expression, distributive_property,
                                factor, addend, area_as_product, area_as_sum,
                                expand, rewrite, equality_preservation]),
                    input(mult(Factor, add(Left, Right))),
                    result(Expanded),
                    expected(Expanded),
                    representation(expression_equivalence(
                                       product_of_sum(mult(Factor,
                                                           add(Left, Right))),
                                       sum_of_products(Expanded))),
                    invariant(every_addend_receives_the_common_factor),
                    validity(correct)
                  ]),
    Trace = [ identify_common_factor(Factor),
              identify_addends([Left, Right]),
              distribute_factor(Factor, Left, mult(Factor, Left)),
              distribute_factor(Factor, Right, mult(Factor, Right)),
              join_partial_products(Expanded)
            ].
run_algebraic_action(drop_distributed_term,
                     mult(Factor, add(Left, Right)),
                     rewrite_direction(expand), Outcome, Trace) :-
    maplist(valid_expression, [Factor, Left, Right]),
    Expected = add(mult(Factor, Left), mult(Factor, Right)),
    Result = mult(Factor, Left),
    Outcome = action_outcome(
                  drop_distributed_term,
                  [ classification(deformation),
                    cluster(algebraic_equivalent_expression_rewrite),
                    automaton_state(distribute_to_first_addend_then_stop),
                    vocabulary([distributive_property, dropped_term,
                                partial_expansion, equality_loss]),
                    input(mult(Factor, add(Left, Right))),
                    result(Result),
                    expected(Expected),
                    deformation_of(distributive_expression_rewrite),
                    misconception_family(dropped_term_in_symbolic_distribution),
                    violated_invariant(every_addend_receives_the_common_factor),
                    validity(incorrect)
                  ]),
    Trace = [ identify_common_factor(Factor),
              distribute_factor(Factor, Left, Result),
              stop_before_second_addend(Right),
              lose_equivalent_expression(Expected, Result)
            ].
run_algebraic_action(exponent_as_repeated_factor,
                     power(Base, Exponent), notation(expanded_product),
                     Outcome, Trace) :-
    valid_expression(Base),
    integer(Exponent), Exponent >= 0,
    expanded_power(Base, Exponent, Expanded),
    Outcome = action_outcome(
                  exponent_as_repeated_factor,
                  [ classification(productive),
                    cluster(algebraic_exponent_as_iterated_multiplication),
                    automaton_state(iterate_base_as_factor_exponent_times),
                    vocabulary([base, exponent, power, repeated_factor,
                                multiplication, expanded_form,
                                exponential_notation]),
                    input(power(Base, Exponent)),
                    result(Expanded),
                    expected(Expanded),
                    iterations(Exponent),
                    invariant(exponent_counts_copies_of_base_as_factors),
                    validity(correct)
                  ]),
    Trace = [ establish_base(Base), establish_exponent(Exponent),
              iterate_base_factor(Exponent, Base),
              inscribe_expanded_product(Expanded)
            ].
run_algebraic_action(exponent_as_multiplier,
                     power(Base, Exponent), notation(expanded_product),
                     Outcome, Trace) :-
    valid_expression(Base),
    integer(Exponent), Exponent >= 2,
    expanded_power(Base, Exponent, Expected),
    Result = mult(Base, int(Exponent)),
    Outcome = action_outcome(
                  exponent_as_multiplier,
                  [ classification(deformation),
                    cluster(algebraic_exponent_as_iterated_multiplication),
                    automaton_state(multiply_base_by_written_exponent),
                    vocabulary([base, exponent, exponent_as_multiplier,
                                repeated_factor_lost, notation_confusion]),
                    input(power(Base, Exponent)),
                    result(Result),
                    expected(Expected),
                    deformation_of(exponent_as_repeated_factor),
                    misconception_family(exponent_as_multiplier),
                    violated_invariant(exponent_counts_copies_of_base_as_factors),
                    validity(incorrect)
                  ]),
    Trace = [ read_exponent_as_second_factor(Exponent),
              multiply_base_by_exponent(Base, Exponent, Result),
              omit_repeated_factor_iteration(Expected)
            ].
run_algebraic_action(exponential_equivalence_by_expansion,
                     expression_pair(Left, Right),
                     method(repeated_factor_expansion), Outcome, Trace) :-
    valid_expression(Left),
    valid_expression(Right),
    expand_all_powers(Left, ExpandedLeft),
    expand_all_powers(Right, ExpandedRight),
    ExpandedLeft == ExpandedRight,
    Outcome = action_outcome(
                  exponential_equivalence_by_expansion,
                  [ classification(productive),
                    cluster(algebraic_exponential_expression_equivalence),
                    automaton_state(compare_canonical_repeated_factor_forms),
                    vocabulary([equivalent_expression, exponent, power,
                                repeated_factor, expanded_form,
                                structural_equivalence]),
                    input(expression_pair(Left, Right)),
                    expanded_forms(ExpandedLeft, ExpandedRight),
                    result(equivalent),
                    expected(equivalent),
                    invariant(equivalence_witnessed_by_same_factor_structure),
                    validity(correct)
                  ]),
    Trace = [ expand_left_powers(Left, ExpandedLeft),
              expand_right_powers(Right, ExpandedRight),
              compare_factor_structures,
              certify_equivalent
            ].
run_algebraic_action(linear_pattern_contextual_rule, Pattern, Context,
                     Outcome, Trace) :-
    contextual_linear_pattern(Pattern, First, Change, Row,
                              Increments, AccumulatedChange, Value),
    Outcome = action_outcome(
                  linear_pattern_contextual_rule,
                  [ classification(productive),
                    cluster(algebraic_linear_pattern_generalization),
                    automaton_state(accumulate_constant_change_from_initial_value),
                    vocabulary([linear_pattern, first_value, row_number,
                                constant_rate_of_change, accumulated_change,
                                explicit_rule, contextual_generalization,
                                initial_value, far_term_prediction]),
                    result(value(Value)),
                    expected(value(Value)),
                    validity(correct),
                    pattern(Pattern),
                    context(Context),
                    components(linear_pattern_components(First, Change, Row,
                                                         Increments,
                                                         AccumulatedChange)),
                    source(extract_review('extract-300-MTL_Lannin_2005_Generalization'))
                  ]),
    Trace = [ identify_initial_value(First),
              identify_constant_change(Change),
              count_increments_from_first_row(Row, Increments),
              compute_accumulated_change(Change, Increments, AccumulatedChange),
              add_initial_value(First, AccumulatedChange, Value),
              preserve_contextual_linear_relation(Context)
            ].
run_algebraic_action(guess_and_check_rule, Pattern, EmpiricalRule,
                     Outcome, Trace) :-
    contextual_linear_pattern(Pattern, _First, _Change, Row,
                              _Increments, _AccumulatedChange, Expected),
    EmpiricalRule = empirical_rule(multiplier(Multiplier),
                                   constant(Constant),
                                   checked_rows(CheckedRows)),
    integer(Multiplier),
    integer(Constant),
    is_list(CheckedRows),
    Result is Multiplier * Row + Constant,
    Result =\= Expected,
    Outcome = action_outcome(
                  guess_and_check_rule,
                  [ classification(deformation),
                    cluster(algebraic_linear_pattern_generalization),
                    automaton_state(transfer_locally_fit_rule_without_context),
                    vocabulary([guess_and_check, empirical_validation,
                                local_fit, checked_rows, formula_fitting,
                                missing_contextual_relation,
                                rate_of_change_loss]),
                    result(value(Result)),
                    expected(value(Expected)),
                    validity(incorrect),
                    pattern(Pattern),
                    empirical_rule(EmpiricalRule),
                    checked_rows(CheckedRows),
                    deformation_of(linear_pattern_contextual_rule),
                    misconception_family(empirical_rule_without_contextual_generalization),
                    source(corpus_row(40643))
                  ]),
    Trace = [ read_empirical_rule(EmpiricalRule),
              apply_empirical_rule(Multiplier, Row, Constant, Result),
              compare_with_contextual_rule(Expected),
              lose_contextual_linear_relation(expected(Expected), produced(Result))
            ].


%!  algebraic_action_cluster(+Kind, -Cluster) is det.
algebraic_action_cluster(programming_expression_evaluation,
                         algebraic_expression_evaluation_as_program).
algebraic_action_cluster(contextual_linear_equation_construction,
                         algebraic_context_to_equation_relation).
algebraic_action_cluster(equation_truth_by_substitution,
                         algebraic_equation_truth_and_solution).
algebraic_action_cluster(operational_equals_left_value,
                         algebraic_equation_truth_and_solution).
algebraic_action_cluster(balance_preserving_linear_solution,
                         algebraic_equation_as_balanced_relation).
algebraic_action_cluster(one_sided_equation_operation,
                         algebraic_equation_as_balanced_relation).
algebraic_action_cluster(symbolic_expression_construction,
                         algebraic_symbolic_expression_construction).
algebraic_action_cluster(distributive_expression_rewrite,
                         algebraic_equivalent_expression_rewrite).
algebraic_action_cluster(drop_distributed_term,
                         algebraic_equivalent_expression_rewrite).
algebraic_action_cluster(exponent_as_repeated_factor,
                         algebraic_exponent_as_iterated_multiplication).
algebraic_action_cluster(exponent_as_multiplier,
                         algebraic_exponent_as_iterated_multiplication).
algebraic_action_cluster(exponential_equivalence_by_expansion,
                         algebraic_exponential_expression_equivalence).
algebraic_action_cluster(linear_pattern_contextual_rule,
                         algebraic_linear_pattern_generalization).
algebraic_action_cluster(guess_and_check_rule,
                         algebraic_linear_pattern_generalization).


%!  algebraic_action_vocabulary(+Kind, -Vocabulary) is det.
algebraic_action_vocabulary(programming_expression_evaluation,
                            [algebraic_expression, variable_assignment,
                             variable_substitution, expression_tree,
                             sub_expression, evaluate_as_program,
                             procedural_evaluation, integer_value]).
algebraic_action_vocabulary(contextual_linear_equation_construction,
                            [context, unknown_quantity, variable, coefficient,
                             constant, total, referent_role, equation,
                             equality_relation, representation]).
algebraic_action_vocabulary(equation_truth_by_substitution,
                            [equation, variable_assignment, substitution,
                             left_expression, right_expression, equality,
                             true_equation, false_equation, solution]).
algebraic_action_vocabulary(operational_equals_left_value,
                            [equation, operational_equals, left_to_right,
                             compute_answer, ignored_right_expression]).
algebraic_action_vocabulary(balance_preserving_linear_solution,
                            [equation, equality_relation, unknown, balance,
                             both_sides, inverse_operation, equivalent_equation,
                             solution, substitution_check]).
algebraic_action_vocabulary(one_sided_equation_operation,
                            [equation, operational_equals, one_sided_move,
                             balance_lost, unknown, solution]).
algebraic_action_vocabulary(symbolic_expression_construction,
                            [algebraic_expression, variable, coefficient,
                             operation, quantity_role, expression_tree,
                             notation, representation]).
algebraic_action_vocabulary(distributive_expression_rewrite,
                            [equivalent_expression, distributive_property,
                             factor, addend, area_as_product, area_as_sum,
                             expand, rewrite, equality_preservation]).
algebraic_action_vocabulary(drop_distributed_term,
                            [distributive_property, dropped_term,
                             partial_expansion, equality_loss]).
algebraic_action_vocabulary(exponent_as_repeated_factor,
                            [base, exponent, power, repeated_factor,
                             multiplication, expanded_form,
                             exponential_notation]).
algebraic_action_vocabulary(exponent_as_multiplier,
                            [base, exponent, exponent_as_multiplier,
                             repeated_factor_lost, notation_confusion]).
algebraic_action_vocabulary(exponential_equivalence_by_expansion,
                            [equivalent_expression, exponent, power,
                             repeated_factor, expanded_form,
                             structural_equivalence]).
algebraic_action_vocabulary(linear_pattern_contextual_rule,
                            [linear_pattern, first_value, row_number,
                             constant_rate_of_change, accumulated_change,
                             explicit_rule, contextual_generalization,
                             initial_value, far_term_prediction]).
algebraic_action_vocabulary(guess_and_check_rule,
                            [guess_and_check, empirical_validation,
                             local_fit, checked_rows, formula_fitting,
                             missing_contextual_relation,
                             rate_of_change_loss]).


%!  productive_algebraic_deformation(+ProductiveKind, +DeformationKind, -Family) is semidet.
productive_algebraic_deformation(linear_pattern_contextual_rule,
                                 guess_and_check_rule,
                                 empirical_rule_without_contextual_generalization).
productive_algebraic_deformation(balance_preserving_linear_solution,
                                 one_sided_equation_operation,
                                 one_sided_equation_operation).
productive_algebraic_deformation(equation_truth_by_substitution,
                                 operational_equals_left_value,
                                 operational_equals_left_value).
productive_algebraic_deformation(distributive_expression_rewrite,
                                 drop_distributed_term,
                                 dropped_term_in_symbolic_distribution).
productive_algebraic_deformation(exponent_as_repeated_factor,
                                 exponent_as_multiplier,
                                 exponent_as_multiplier).


%!  algebraic_action_misconception_hook(+Outcome, -Family, -Hook) is semidet.
%
%   Productive-only routing. The hook surfaces the kind, the cluster,
%   and the evaluated value so monitoring code can attribute the
%   evaluation to the algebraic axis without inspecting the kind.
algebraic_action_misconception_hook(action_outcome(Kind, Fields), Family, Hook) :-
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
algebraic_action_misconception_hook(action_outcome(Kind, Fields), Family, Hook) :-
    member(classification(productive), Fields),
    productive_algebraic_deformation(Kind, DeformationKind, Family),
    member(vocabulary(Vocabulary), Fields),
    algebraic_monitoring_focus(Kind, Focus),
    Hook = action_misconception_hook(
               [ productive_action(Kind),
                 nearby_deformation(DeformationKind),
                 family(Family),
                 vocabulary(Vocabulary),
                 monitoring_focus(Focus),
                 evidence(Fields)
               ]).
algebraic_action_misconception_hook(action_outcome(Kind, Fields), Family, Hook) :-
    member(classification(productive), Fields),
    member(cluster(Cluster), Fields),
    member(vocabulary(Vocabulary), Fields),
    member(result(Result), Fields),
    algebraic_monitoring_focus(Kind, Focus),
    Family = algebraic_axis(Cluster),
    Hook = action_misconception_hook(
               [ productive_algebraic(Kind),
                 cluster(Cluster),
                 result(Result),
                 vocabulary(Vocabulary),
                 monitoring_focus(Focus),
                 evidence(Fields)
               ]).

algebraic_monitoring_focus(programming_expression_evaluation,
                           execute_expression_as_program(
                               programming_expression_evaluation)).
algebraic_monitoring_focus(contextual_linear_equation_construction,
                           preserve_contextual_quantity_roles).
algebraic_monitoring_focus(equation_truth_by_substitution,
                           compare_both_sides_under_same_assignment).
algebraic_monitoring_focus(balance_preserving_linear_solution,
                           preserve_equality_during_each_transformation).
algebraic_monitoring_focus(symbolic_expression_construction,
                           preserve_operation_and_referent_roles).
algebraic_monitoring_focus(distributive_expression_rewrite,
                           distribute_common_factor_to_every_addend).
algebraic_monitoring_focus(exponent_as_repeated_factor,
                           preserve_exponent_as_factor_iteration_count).
algebraic_monitoring_focus(exponential_equivalence_by_expansion,
                           compare_expanded_factor_structures).
algebraic_monitoring_focus(linear_pattern_contextual_rule,
                           preserve_contextual_linear_relation(
                               linear_pattern_contextual_rule)).


contextual_linear_pattern(linear_pattern(first(First), change(Change), row(Row)),
                          First,
                          Change,
                          Row,
                          Increments,
                          AccumulatedChange,
                          Value) :-
    integer(First),
    integer(Change),
    integer(Row),
    Row > 0,
    Increments is Row - 1,
    AccumulatedChange is Change * Increments,
    Value is First + AccumulatedChange.

valid_referent_roles(Roles) :-
    is_list(Roles),
    Roles = [_|_],
    forall(member(Role, Roles), nonvar(Role)).

successful_balance_scene(Scene) :-
    is_dict(Scene),
    \+ get_dict(error, Scene, _),
    get_dict(frames, Scene, Frames),
    Frames = [_|_].

equality_truth(Left, Right, true) :- Left =:= Right, !.
equality_truth(_Left, _Right, false).


% --- Expression helpers ---

%!  valid_expression(+Expression) is semidet.
%
%   Accept integer literals, variable references, and binary `add` and
%   `mult` nodes whose operands are themselves valid. Unknown operator
%   nodes (e.g. `power/2`) are accepted here so the deferred-grounding
%   fallback in `evaluate_expression/5` can record them honestly.
valid_expression(int(N)) :- integer(N), !.
valid_expression(var(Name)) :- atom(Name), !.
valid_expression(add(L, R)) :-
    valid_expression(L),
    valid_expression(R), !.
valid_expression(mult(L, R)) :-
    valid_expression(L),
    valid_expression(R), !.
valid_expression(power(Base, Exponent)) :-
    valid_expression(Base),
    integer(Exponent),
    Exponent >= 0, !.
valid_expression(Term) :-
    compound(Term),
    Term =.. [_Op, L, R],
    valid_expression(L),
    valid_expression(R).

expression_variable_names(int(_), []).
expression_variable_names(var(Name), [Name]).
expression_variable_names(power(Base, _Exponent), Names) :-
    expression_variable_names(Base, Names), !.
expression_variable_names(Term, Names) :-
    compound(Term),
    Term =.. [_Operator, Left, Right],
    expression_variable_names(Left, LeftNames),
    expression_variable_names(Right, RightNames),
    append(LeftNames, RightNames, Names).

expanded_power(_Base, 0, int(1)) :- !.
expanded_power(Base, 1, Base) :- !.
expanded_power(Base, Exponent, mult(Base, Rest)) :-
    Exponent > 1,
    Next is Exponent - 1,
    expanded_power(Base, Next, Rest).

expand_all_powers(int(N), int(N)).
expand_all_powers(var(Name), var(Name)).
expand_all_powers(power(Base, Exponent), Expanded) :-
    integer(Exponent), Exponent >= 0,
    expand_all_powers(Base, ExpandedBase),
    expanded_power(ExpandedBase, Exponent, Expanded),
    !.
expand_all_powers(Term, Expanded) :-
    compound(Term),
    Term =.. [Operator, Left, Right],
    expand_all_powers(Left, ExpandedLeft),
    expand_all_powers(Right, ExpandedRight),
    Expanded =.. [Operator, ExpandedLeft, ExpandedRight].


%!  valid_assignment(+Assignment) is semidet.
%
%   Accept a list of `var(Name) = int(N)` bindings.
valid_assignment([]).
valid_assignment([var(Name) = int(N)|Rest]) :-
    atom(Name),
    integer(N),
    valid_assignment(Rest).


%!  evaluate_expression(+Expression, +Assignment, -Value, -EvalSteps, -KernelSteps) is semidet.
%
%   Walk the expression tree, substituting variables and combining
%   sub-values via the grounded-arithmetic kernel. EvalSteps records
%   the symbolic walk (substitutions and combinations); KernelSteps
%   records every kernel-level operation (grounding integers,
%   `add_grounded`, `multiply_grounded`).
evaluate_expression(int(N), _Assignment, N,
                    [literal(int(N), N)],
                    [ground_integer(N, RecN)]) :-
    integer(N),
    N >= 0, !,
    integer_to_recollection(N, RecN).
evaluate_expression(int(N), _Assignment, N,
                    [literal(int(N), N)],
                    [native_integer(N, not_yet_grounded(negative_literal))]) :-
    integer(N),
    N < 0.
evaluate_expression(var(Name), Assignment, Value,
                    [substitute(var(Name), Value)],
                    KernelSteps) :-
    atom(Name),
    member(var(Name) = int(Value), Assignment),
    integer(Value),
    (   Value >= 0
    ->  integer_to_recollection(Value, RecValue),
        KernelSteps = [ground_integer(Value, RecValue)]
    ;   KernelSteps = [native_integer(Value, not_yet_grounded(negative_substitution))]
    ).
evaluate_expression(add(L, R), Assignment, Value,
                    [combine(add, LValue, RValue, Value)|SubSteps],
                    KernelSteps) :-
    evaluate_expression(L, Assignment, LValue, LSteps, LKernel),
    evaluate_expression(R, Assignment, RValue, RSteps, RKernel),
    append(LSteps, RSteps, SubSteps),
    grounded_add(LValue, RValue, Value, CombineKernel),
    append([LKernel, RKernel, CombineKernel], KernelSteps).
evaluate_expression(mult(L, R), Assignment, Value,
                    [combine(mult, LValue, RValue, Value)|SubSteps],
                    KernelSteps) :-
    evaluate_expression(L, Assignment, LValue, LSteps, LKernel),
    evaluate_expression(R, Assignment, RValue, RSteps, RKernel),
    append(LSteps, RSteps, SubSteps),
    grounded_mult(LValue, RValue, Value, CombineKernel),
    append([LKernel, RKernel, CombineKernel], KernelSteps).
evaluate_expression(Term, Assignment, Value,
                    [combine(Operator, LValue, RValue, Value),
                     not_yet_grounded(Operator)|SubSteps],
                    KernelSteps) :-
    compound(Term),
    Term =.. [Operator, L, R],
    \+ memberchk(Operator, [add, mult]),
    evaluate_expression(L, Assignment, LValue, LSteps, LKernel),
    evaluate_expression(R, Assignment, RValue, RSteps, RKernel),
    append(LSteps, RSteps, SubSteps),
    fallback_combine(Operator, LValue, RValue, Value, FallbackKernel),
    append([LKernel, RKernel, FallbackKernel], KernelSteps).


%!  grounded_add(+L, +R, -Sum, -KernelSteps) is det.
%
%   Route addition through `grounded_arithmetic:add_grounded/3` when
%   both operands are non-negative integers (the recollection
%   representation's domain). For negative operands the fallback uses
%   native `is/2` arithmetic and the kernel trace records that the
%   sub-result was not grounded.
grounded_add(L, R, Sum, KernelSteps) :-
    L >= 0,
    R >= 0, !,
    integer_to_recollection(L, RecL),
    integer_to_recollection(R, RecR),
    add_grounded(RecL, RecR, RecSum),
    recollection_to_integer(RecSum, Sum),
    KernelSteps = [add_grounded(RecL, RecR, RecSum),
                   recollection_to_integer(RecSum, Sum)].
grounded_add(L, R, Sum, KernelSteps) :-
    Sum is L + R,
    KernelSteps = [native_add(L, R, Sum, not_yet_grounded(negative_operand))].


%!  grounded_mult(+L, +R, -Product, -KernelSteps) is det.
%
%   Route multiplication through `grounded_arithmetic:multiply_grounded/3`
%   when both operands are non-negative integers. For negative operands
%   the fallback uses native `is/2` arithmetic and the kernel trace
%   records that the sub-result was not grounded.
grounded_mult(L, R, Product, KernelSteps) :-
    L >= 0,
    R >= 0, !,
    integer_to_recollection(L, RecL),
    integer_to_recollection(R, RecR),
    multiply_grounded(RecL, RecR, RecProduct),
    recollection_to_integer(RecProduct, Product),
    KernelSteps = [multiply_grounded(RecL, RecR, RecProduct),
                   recollection_to_integer(RecProduct, Product)].
grounded_mult(L, R, Product, KernelSteps) :-
    Product is L * R,
    KernelSteps = [native_mult(L, R, Product, not_yet_grounded(negative_operand))].


%!  fallback_combine(+Operator, +L, +R, -Value, -KernelSteps) is det.
%
%   For any operator outside `add` / `mult`, fall back to native `is/2`
%   evaluation while marking the kernel trace honestly as
%   `not_yet_grounded(Operator)`.
fallback_combine(Operator, L, R, Value, KernelSteps) :-
    NativeTerm =.. [Operator, L, R],
    Value is NativeTerm,
    KernelSteps = [native_combine(Operator, L, R, Value,
                                  not_yet_grounded(Operator))].
