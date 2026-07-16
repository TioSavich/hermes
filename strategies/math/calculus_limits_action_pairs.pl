/** <module> Calculus limits action/deformation pairs (automata-011)
 *
 * Axis decision (CODEX_BACKLOG.md automata-011): one axis, two sub-families,
 * unified under the operation name `calculus_limits`. Limits of functions
 * (x -> a) and convergence of sequences (n -> infinity) share the
 * epsilon/tail-bound semantic structure and the "what the expression
 * approaches under a parameter going to a target" judgment. Surface
 * vocabulary differs (function values vs. sequence terms); the underlying
 * inferential shape is shared. The sub-family is encoded in each outcome's
 * Fields as `subfamily(function_limit)` or `subfamily(sequence_convergence)`.
 *
 * Productive automata registered here:
 *
 *   - `direct_substitution` (function_limit)
 *       For lim x -> A of f(x) where f is continuous at A, substitute A
 *       and compute. Source: extract-033 Hardy 2009 (`direct_substitution`).
 *       Kernel coupling: routes the post-substitution arithmetic through
 *       `grounded_arithmetic:integer_to_recollection/2`, so the trace
 *       records the value as a recollection alongside the integer result.
 *
 *   - `factor_cancel_substitute` (function_limit)
 *       For lim x -> A of (P(x) / Q(x)) where both P(A) = 0 and Q(A) = 0
 *       (the 0/0 case), factor (x - A) out of numerator and denominator
 *       by synthetic division, then substitute A into the reduced quotient.
 *       Source: extract-033 Hardy 2009 (`factor_cancel_substitute`).
 *       Kernel coupling: the reduced-quotient evaluation routes through
 *       `integer_to_recollection/2`; the trace records both the symbolic
 *       cancel step and the grounded evaluation.
 *
 *   - `bounded_numerator_over_diverging_denominator` (sequence_convergence)
 *       For a sequence term a_n = N(n) / D(n) where |N(n)| <= B (bounded
 *       above by some constant B) and D(n) is unbounded (diverges to
 *       infinity as n -> infinity), conclude lim a_n = 0. Source:
 *       extract-003 Alcock 2005 (`size_comparison_convergence_to_zero`,
 *       `epsilon_n_tail_plus_finite_initial_segment_bound`). Kernel
 *       coupling: symbolic only -- limits are not in Robinson Q, so the
 *       trace records the epsilon-bound reasoning structurally and the
 *       outcome carries `elaborates(epsilon_n_tail_bound)` as a
 *       deferred-grounding marker.
 *
 * Productive/deformation pair (rule-misfire shape):
 *
 *   - `factor_cancel_substitute` (productive) paired with
 *   - `factor_cancel_without_common_factor` (deformation)
 *       The deformation applies the cancel-then-substitute pattern when
 *       no common factor (x - A) exists. The student has the syntactic
 *       routine but not its precondition (both P(A) = 0 and Q(A) = 0).
 *       Source: extract-033 Hardy 2009 (article notes factoring attempts
 *       frustrated students when no common factors were available).
 *       Kernel coupling: connected to the productive's kernel through
 *       `deformation_of(factor_cancel_substitute)`. Same primitives, but
 *       applied where the precondition fails.
 *
 * Registry boundary: `run_calculus_action(+Kind, +Expression, +Target,
 * -Outcome, -Trace)`. `Expression` is one of:
 *
 *   - `polynomial(Coeffs)` -- list `[c0, c1, c2, ...]` representing the
 *     polynomial `c0 + c1*x + c2*x^2 + ...`. Integer coefficients.
 *   - `rational_expression(NumPoly, DenPoly)` -- both polynomials in the
 *     above form.
 *   - `sequence_term(bounded(BoundExpression, BoundValue),
 *     diverging(DivergingExpression))` -- a sequence term recorded as a
 *     pair of a bounded numerator (with its bound) and a diverging
 *     denominator. The expressions are symbolic atoms (e.g.
 *     `cosine_of_n_x`, `linear_in_n`); the bound is an integer.
 *
 * `Target` is one of:
 *
 *   - `limit_at(A)` -- A is an integer, the value x approaches.
 *   - `as_n_to_infinity` -- the sequence parameter target.
 *
 * Out of scope for this skeleton: limits at infinity for general
 * functions (only n -> infinity for sequences), multivariate limits,
 * derivatives, integrals.
 */

:- module(calculus_limits_action_pairs,
          [ run_calculus_action/5,
            calculus_action_cluster/2,
            calculus_action_vocabulary/2,
            productive_calculus_deformation/3,
            calculus_action_misconception_hook/3
          ]).

:- use_module(formalization(grounded_arithmetic),
              [ integer_to_recollection/2
              ]).


%!  run_calculus_action(+Kind, +Expression, +Target, -Outcome, -Trace) is semidet.
%
%   Execute a productive or deformed calculus-limits action automaton.
%   Expression is a compound carrying the function or sequence structure;
%   Target is the value/parameter being approached. See the module header
%   for the encoding of `Expression` and `Target`.
run_calculus_action(direct_substitution, polynomial(Coeffs), limit_at(A), Outcome, Trace) :-
    is_list(Coeffs),
    Coeffs \= [],
    integer(A),
    all_integers(Coeffs),
    evaluate_polynomial(Coeffs, A, Value),
    ground_signed_value(Value, RecValue),
    Result = limit_value(Value),
    Outcome = action_outcome(
                  direct_substitution,
                  [ classification(productive),
                    subfamily(function_limit),
                    cluster(calculus_limit_continuous_evaluation),
                    automaton_state(limit_at_continuous_point),
                    vocabulary([continuous_function, limit_point,
                                substitution, function_value,
                                polynomial, evaluation_at_a_point]),
                    result(Result),
                    expected(Result),
                    validity(correct),
                    target(limit_at(A)),
                    expression(polynomial(Coeffs)),
                    elaborates(grounded_arithmetic:integer_to_recollection/2),
                    evidence(grounded_value(RecValue))
                  ]),
    Trace = [ identify_limit_target(limit_at(A)),
              recognize_polynomial_is_continuous(polynomial(Coeffs)),
              substitute_target_into_polynomial(polynomial(Coeffs), A),
              evaluate_polynomial_at_point(Coeffs, A, Value),
              kernel_trace([ground_value_as_recollection(Value, RecValue)]),
              name_value_as_limit(Result)
            ].
run_calculus_action(factor_cancel_substitute,
                    rational_expression(NumPoly, DenPoly),
                    limit_at(A), Outcome, Trace) :-
    is_list(NumPoly), NumPoly \= [],
    is_list(DenPoly), DenPoly \= [],
    integer(A),
    all_integers(NumPoly),
    all_integers(DenPoly),
    evaluate_polynomial(NumPoly, A, NumValueAtA),
    evaluate_polynomial(DenPoly, A, DenValueAtA),
    NumValueAtA =:= 0,
    DenValueAtA =:= 0,
    synthetic_divide(NumPoly, A, NumQuotient, 0),
    synthetic_divide(DenPoly, A, DenQuotient, 0),
    evaluate_polynomial(NumQuotient, A, NumReducedValue),
    evaluate_polynomial(DenQuotient, A, DenReducedValue),
    DenReducedValue =\= 0,
    reduced_value(NumReducedValue, DenReducedValue, Value),
    ground_signed_value(NumReducedValue, RecNum),
    ground_signed_value(DenReducedValue, RecDen),
    Result = limit_value(Value),
    Outcome = action_outcome(
                  factor_cancel_substitute,
                  [ classification(productive),
                    subfamily(function_limit),
                    cluster(calculus_limit_removable_discontinuity),
                    automaton_state(limit_at_removable_singularity),
                    vocabulary([removable_discontinuity, common_factor,
                                cancel, reduced_expression,
                                substitution, function_value]),
                    result(Result),
                    expected(Result),
                    validity(correct),
                    target(limit_at(A)),
                    expression(rational_expression(NumPoly, DenPoly)),
                    reduced_expression(rational_expression(NumQuotient, DenQuotient)),
                    elaborates(grounded_arithmetic:integer_to_recollection/2),
                    evidence(grounded_reduced_value(RecNum, RecDen))
                  ]),
    Trace = [ identify_limit_target(limit_at(A)),
              substitute_target_into_expression(rational_expression(NumPoly, DenPoly), A),
              detect_zero_over_zero(NumValueAtA, DenValueAtA),
              factor_common_factor_x_minus_a(A,
                                             from(rational_expression(NumPoly, DenPoly)),
                                             to(rational_expression(NumQuotient, DenQuotient))),
              substitute_target_into_reduced(rational_expression(NumQuotient, DenQuotient), A),
              evaluate_reduced_at_point(NumReducedValue, DenReducedValue),
              kernel_trace([ground_value_as_recollection(NumReducedValue, RecNum),
                            ground_value_as_recollection(DenReducedValue, RecDen)]),
              name_value_as_limit(Result)
            ].
run_calculus_action(factor_cancel_without_common_factor,
                    rational_expression(NumPoly, DenPoly),
                    limit_at(A), Outcome, Trace) :-
    is_list(NumPoly), NumPoly \= [],
    is_list(DenPoly), DenPoly \= [],
    integer(A),
    all_integers(NumPoly),
    all_integers(DenPoly),
    evaluate_polynomial(NumPoly, A, NumValueAtA),
    evaluate_polynomial(DenPoly, A, DenValueAtA),
    \+ (NumValueAtA =:= 0, DenValueAtA =:= 0),
    Expected = misfire_no_common_factor(A,
                                        numerator_value(NumValueAtA),
                                        denominator_value(DenValueAtA)),
    StudentResult = misfire_result(applied_cancel_routine_without_precondition,
                                   numerator_evaluation(NumValueAtA),
                                   denominator_evaluation(DenValueAtA)),
    Outcome = action_outcome(
                  factor_cancel_without_common_factor,
                  [ classification(deformation),
                    subfamily(function_limit),
                    cluster(calculus_limit_removable_discontinuity),
                    automaton_state(limit_at_removable_singularity),
                    vocabulary([common_factor, cancel, rule_misfire,
                                missing_precondition, syntactic_routine,
                                function_value]),
                    result(StudentResult),
                    expected(Expected),
                    validity(incorrect),
                    target(limit_at(A)),
                    expression(rational_expression(NumPoly, DenPoly)),
                    deformation_of(factor_cancel_substitute),
                    misconception_family(rule_misfire_cancel_without_common_factor)
                  ]),
    Trace = [ identify_limit_target(limit_at(A)),
              substitute_target_into_expression(rational_expression(NumPoly, DenPoly), A),
              fail_to_detect_zero_over_zero(NumValueAtA, DenValueAtA),
              apply_cancel_routine_anyway,
              produce_misfire_result(StudentResult),
              lose_precondition_check(expected(Expected), produced(StudentResult))
            ].
run_calculus_action(bounded_numerator_over_diverging_denominator,
                    sequence_term(bounded(NumExpression, BoundValue),
                                  diverging(DenExpression)),
                    as_n_to_infinity, Outcome, Trace) :-
    atom(NumExpression),
    atom(DenExpression),
    integer(BoundValue),
    BoundValue > 0,
    Result = limit_value(0),
    Outcome = action_outcome(
                  bounded_numerator_over_diverging_denominator,
                  [ classification(productive),
                    subfamily(sequence_convergence),
                    cluster(calculus_sequence_squeeze_to_zero),
                    automaton_state(sequence_tail_bound),
                    vocabulary([bounded_numerator, diverging_denominator,
                                epsilon, tail_bound, finite_initial_segment,
                                squeeze_to_zero, convergence_to_zero]),
                    result(Result),
                    expected(Result),
                    validity(correct),
                    target(as_n_to_infinity),
                    expression(sequence_term(bounded(NumExpression, BoundValue),
                                             diverging(DenExpression))),
                    elaborates(epsilon_n_tail_bound),
                    evidence(deferred_grounding(limits_not_in_robinson_q))
                  ]),
    Trace = [ identify_limit_target(as_n_to_infinity),
              identify_bound_on_numerator(NumExpression, BoundValue),
              identify_diverging_denominator(DenExpression),
              for_any_epsilon_choose_N_so_tail_is_within_epsilon(BoundValue),
              bound_tail_by_constant_over_diverging_term(BoundValue, DenExpression),
              conclude_limit_is_zero(Result)
            ].


%!  calculus_action_cluster(+Kind, -Cluster) is det.
calculus_action_cluster(direct_substitution, calculus_limit_continuous_evaluation).
calculus_action_cluster(factor_cancel_substitute, calculus_limit_removable_discontinuity).
calculus_action_cluster(factor_cancel_without_common_factor,
                        calculus_limit_removable_discontinuity).
calculus_action_cluster(bounded_numerator_over_diverging_denominator,
                        calculus_sequence_squeeze_to_zero).


%!  calculus_action_vocabulary(+Kind, -Vocabulary) is det.
calculus_action_vocabulary(direct_substitution,
                           [continuous_function, limit_point,
                            substitution, function_value,
                            polynomial, evaluation_at_a_point]).
calculus_action_vocabulary(factor_cancel_substitute,
                           [removable_discontinuity, common_factor,
                            cancel, reduced_expression,
                            substitution, function_value]).
calculus_action_vocabulary(factor_cancel_without_common_factor,
                           [common_factor, cancel, rule_misfire,
                            missing_precondition, syntactic_routine,
                            function_value]).
calculus_action_vocabulary(bounded_numerator_over_diverging_denominator,
                           [bounded_numerator, diverging_denominator,
                            epsilon, tail_bound, finite_initial_segment,
                            squeeze_to_zero, convergence_to_zero]).


%!  productive_calculus_deformation(+ProductiveKind, +DeformationKind, -Family) is det.
productive_calculus_deformation(factor_cancel_substitute,
                                factor_cancel_without_common_factor,
                                rule_misfire_cancel_without_common_factor).


%!  calculus_action_misconception_hook(+Outcome, -Family, -Hook) is semidet.
calculus_action_misconception_hook(action_outcome(Kind, Fields), Family, Hook) :-
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
calculus_action_misconception_hook(action_outcome(Kind, Fields), Family, Hook) :-
    member(classification(productive), Fields),
    productive_calculus_deformation(Kind, DeformationKind, Family),
    member(vocabulary(Vocabulary), Fields),
    Hook = action_misconception_hook(
               [ productive_action(Kind),
                 nearby_deformation(DeformationKind),
                 family(Family),
                 vocabulary(Vocabulary),
                 monitoring_focus(check_common_factor_precondition(Kind)),
                 evidence(Fields)
               ]).


% --- Helpers ---

%!  all_integers(+List) is semidet.
all_integers([]).
all_integers([H|T]) :- integer(H), all_integers(T).


%!  reduced_value(+Num, +Den, -Value) is det.
%
%   Form the value of Num/Den after the common-factor cancellation. When the
%   division is exact, the result is an integer; otherwise the rational
%   `Num rdiv Den` is preserved (still grounded through the recollections
%   of Num and Den separately by the caller).
reduced_value(Num, Den, Value) :-
    Den =\= 0,
    (   0 =:= Num mod Den
    ->  Value is Num div Den
    ;   Value = Num rdiv Den
    ).


%!  ground_signed_value(+Integer, -GroundedTerm) is det.
%
%   Ground an integer value through `integer_to_recollection/2`. Because
%   the recollection representation is defined only for non-negative
%   integers, negative values are routed through their absolute value and
%   wrapped in `signed(negative, Rec)` to keep the trace honest about the
%   detour.
ground_signed_value(N, recollection(History)) :-
    integer(N),
    N >= 0, !,
    integer_to_recollection(N, recollection(History)).
ground_signed_value(N, signed(negative, Rec)) :-
    integer(N),
    N < 0,
    Abs is abs(N),
    integer_to_recollection(Abs, Rec).


%!  evaluate_polynomial(+Coeffs, +X, -Value) is det.
%
%   Evaluate `c0 + c1*x + c2*x^2 + ...` at X using Horner-like accumulation
%   over the coefficient list `[c0, c1, c2, ...]`.
evaluate_polynomial(Coeffs, X, Value) :-
    evaluate_polynomial_(Coeffs, X, 0, 1, Value).

evaluate_polynomial_([], _, Acc, _, Acc).
evaluate_polynomial_([C|Rest], X, Acc, XPower, Value) :-
    NewAcc is Acc + C * XPower,
    NewXPower is XPower * X,
    evaluate_polynomial_(Rest, X, NewAcc, NewXPower, Value).


%!  synthetic_divide(+Coeffs, +A, -QuotientCoeffs, -Remainder) is det.
%
%   Synthetic division of the polynomial `Coeffs` (in ascending-degree
%   list form `[c0, c1, ..., cN]`) by `(x - A)`. Returns the quotient
%   coefficients (ascending degree) and the integer remainder. Implemented
%   in descending-degree form because that matches the usual layout, then
%   the result is converted back to ascending form for the API surface.
synthetic_divide(Coeffs, A, QuotientCoeffs, Remainder) :-
    reverse(Coeffs, Descending),
    Descending = [Leading|Rest],
    synthetic_step(Rest, A, Leading, [Leading], ReverseRow),
    ReverseRow = [Remainder|DescendingQuotientReversed],
    reverse(DescendingQuotientReversed, DescendingQuotient),
    reverse(DescendingQuotient, QuotientCoeffs).

synthetic_step([], _, _, Acc, Acc).
synthetic_step([Next|Rest], A, Prev, Acc, Result) :-
    NewTerm is Next + A * Prev,
    synthetic_step(Rest, A, NewTerm, [NewTerm|Acc], Result).
