/** <module> Normalized literature incompatibility vocabulary
 *
 * The generated literature corpus keeps the original free-form
 * `incompatible_with` atoms as audit evidence. This module supplies the
 * controlled-vocabulary layer that makes those atoms collide into queryable
 * commitments for the deontic scorekeeper.
 *
 * Do not edit `literature_incompatibility_facts.pl` for vocabulary cleanup;
 * add or adjust mappings here instead.
 */
:- module(literature_vocabulary,
          [ canonical_commitment/2,
            commitment_map/2,
            domain_map/2,
            normalized_commitment/2,
            canonical_student_rule/2,
            lit_incompatibility/7,
            lit_incompatibility_meta/4,
            lit_incompatibility_commitment/2,
            lit_incompatibility_entitlement/2,
            literature_adjudication/2,
            literature_adjudicated_count/1,
            literature_adjudicated_fact_count/1,
            literature_mapping_stats/4,
            linked_lit_incompatibility/3,
            linked_lit_incompatibility_exact_rule/3,
            linked_lit_incompatibility_canonical_rule/3,
            linked_lit_incompatibility_count/1,
            linked_lit_incompatibility_exact_rule_count/1,
            linked_lit_incompatibility_canonical_rule_count/1
          ]).

:- use_module(misconceptions(literature_incompatibility_facts),
              [ lit_derived/9,
                lit_derived_meta/4
              ]).
:- use_module(misconceptions(literature_student_rule_map),
              [ student_rule_map/2
              ]).
:- use_module(library(yall)).
:- use_module(learner(deontic_scorekeeper), []).
:- use_module(misconceptions(test_harness), []).
:- use_module(misconceptions(misconceptions_combinatorial), []).
:- use_module(misconceptions(misconceptions_decimal), []).
:- use_module(misconceptions(misconceptions_discrete), []).
:- use_module(misconceptions(misconceptions_extended_arithmetic), []).
:- use_module(misconceptions(misconceptions_fraction), []).
:- use_module(misconceptions(misconceptions_geometry), []).
:- use_module(misconceptions(misconceptions_integer), []).
:- use_module(misconceptions(misconceptions_measurement), []).
:- use_module(misconceptions(misconceptions_percent), []).
:- use_module(misconceptions(misconceptions_ratio), []).
:- use_module(misconceptions(misconceptions_rational), []).
:- use_module(misconceptions(misconceptions_whole_number), []).

:- multifile deontic_scorekeeper:incompatible/2.
:- multifile deontic_scorekeeper:requires_entitlement_fact/1.

% The generated completion (literature_canonical_mappings.pl) contributes
% further clauses for both predicates, so they are not contiguous in source.
:- discontiguous canonical_commitment/2.
:- discontiguous commitment_map/2.


%% ----------------------------------------------------------------------
%% Canonical commitments

canonical_commitment(c_fraction_addition_common_unit,
                     "Fraction addition requires a common unit or common denominator before adding numerators.").
canonical_commitment(c_fraction_subtraction_common_unit,
                     "Fraction subtraction requires a common unit or common denominator before subtracting numerators.").
canonical_commitment(c_fraction_equivalence_multiplicative_scaling,
                     "Equivalent fractions preserve value by multiplying or dividing numerator and denominator by the same nonzero factor.").
canonical_commitment(c_fraction_denominator_inverse_unit_size,
                     "For unit fractions, a larger denominator names a smaller equal part of the same whole.").
canonical_commitment(c_fraction_magnitude_common_whole,
                     "Fraction magnitude comparisons require coordinated numerator, denominator, and common-whole reasoning.").
canonical_commitment(c_fraction_referent_whole_invariance,
                     "A fraction must be interpreted against a stable referent whole.").
canonical_commitment(c_fraction_multiplication_part_of_part,
                     "Fraction multiplication is grounded in part-of-part or denominator-product structure, not componentwise addition.").
canonical_commitment(c_fraction_division_inverse_relation,
                     "Fraction division coordinates dividend, divisor, quotient, and reciprocal or measurement meanings.").
canonical_commitment(c_equal_sharing_partition_model,
                     "Equal sharing and dealing require equal-size shares tied to the partition model.").
canonical_commitment(c_rational_density_between_any_two,
                     "Between any two distinct rational numbers there is another rational number.").
canonical_commitment(c_rational_representation_equivalence,
                     "Fractions and decimals can denote the same rational magnitude across notations.").
canonical_commitment(c_decimal_place_value_ordering,
                     "Decimal magnitude is ordered by place-value structure, not by treating the tail as a whole number.").
canonical_commitment(c_decimal_place_value_alignment,
                     "Decimal addition and subtraction align like place-value units.").
canonical_commitment(c_decimal_trailing_zero_invariance,
                     "Trailing zeros and arbitrary precision do not change a decimal value.").
canonical_commitment(c_decimal_positional_notation,
                     "The decimal point locates place-value units rather than separating two independent whole numbers.").
canonical_commitment(c_operation_effect_depends_on_operand_size,
                     "Multiplication and division effects depend on operand size relative to one.").
canonical_commitment(c_base_ten_place_value_regrouping,
                     "Base-ten positional notation and regrouping preserve the represented quantity.").
canonical_commitment(c_equality_relational_balance,
                     "Equality is a symmetric relation preserved by balanced transformations.").
canonical_commitment(c_operator_precedence_grouping,
                     "Conventional grouping and operation precedence determine expression structure.").
canonical_commitment(c_subtraction_order_difference_relation,
                     "Subtraction is order-sensitive and represents a directed difference relation.").
canonical_commitment(c_division_by_zero_undefined,
                     "Division by zero is undefined.").
canonical_commitment(c_division_structure_and_remainder,
                     "Division coordinates dividend, divisor, quotient, remainder, and problem context.").
canonical_commitment(c_multiplicative_structure_not_additive,
                     "Multiplicative structures and partial products are not reducible to additive combination.").
canonical_commitment(c_counting_cardinality_units,
                     "Counting and cardinality require one-to-one unit coordination and stable counted units.").
canonical_commitment(c_parity_definition_includes_zero,
                     "Parity and evenness are defined by divisibility by two, including zero.").
canonical_commitment(c_prime_composite_divisibility_definitions,
                     "Prime, composite, factor, and divisibility claims must satisfy their definitions.").
canonical_commitment(c_estimation_rounding_reasonableness,
                     "Estimation and rounding must preserve target place, direction, and reasonableness checks.").
canonical_commitment(c_algorithm_flexibility_and_understanding,
                     "Algorithms are justified procedures, not exclusive rote routines detached from meaning.").
canonical_commitment(c_function_as_arbitrary_correspondence,
                     "A function is an arbitrary univalent correspondence, not only a familiar formula or smooth graph.").
canonical_commitment(c_variable_as_generalized_quantity,
                     "Variables denote generalized or indeterminate quantities within a relation.").
canonical_commitment(c_rate_of_change_covariation,
                     "Rates of change and slopes coordinate covarying quantities.").
canonical_commitment(c_distributivity_expansion_structure,
                     "Distribution and expansion preserve product-over-sum structure, including cross terms.").
canonical_commitment(c_exponent_power_structure,
                     "Exponents, powers, roots, and logarithms obey their structural laws and domains.").
canonical_commitment(c_associativity_single_operation,
                     "Associativity is a property of one operation applied across grouped operands.").
canonical_commitment(c_commutativity_operation_specific,
                     "Commutativity is operation-specific and does not license arbitrary operand or sign movement.").
canonical_commitment(c_signed_term_structure,
                     "Each algebraic term carries its operation sign and structural role.").
canonical_commitment(c_deductive_proof_logical_direction,
                     "Proof, implication, converse, and conditionals require correct logical direction and warrant.").
canonical_commitment(c_definition_precision_and_arity,
                     "Definitions fix essential conditions, arity, and precise mathematical use.").
canonical_commitment(c_substitution_semantics,
                     "Substitution preserves meaning only when terms, values, and domains match.").
canonical_commitment(c_solution_set_semantics,
                     "Equations and inequalities denote solution sets, including empty, singleton, and all-real cases.").
canonical_commitment(c_like_terms_structural_combination,
                     "Only like terms or structurally compatible quantities may be combined.").
canonical_commitment(c_cancellation_requires_common_factor,
                     "Cancellation requires a common factor of the whole expression, not a matching addend or surface term.").
canonical_commitment(c_zero_product_property,
                     "The zero-product property licenses factor-level zero inferences under its conditions.").
canonical_commitment(c_equation_quantitative_relation_model,
                     "Equations model quantitative relations, not merely word order or calculation sequences.").
canonical_commitment(c_transformation_preserves_equivalence,
                     "Algebraic transformations must preserve truth, structure, and equivalence toward the goal.").
canonical_commitment(c_structural_generalization,
                     "General rules must express and preserve the structure across all intended cases.").
canonical_commitment(c_formula_domain_and_graph_consistency,
                     "Formulas and graphs must respect their intended domain, parameters, and represented quantities.").
canonical_commitment(c_graph_axes_quantity_mapping,
                     "Graph axes and coordinates map represented quantities with declared scales.").
canonical_commitment(c_multiplicative_ratio_invariance,
                     "Ratios and proportional relationships preserve multiplicative invariance or common scale factors.").
canonical_commitment(c_unit_rate_common_base,
                     "Unit-rate and intensive-quantity comparisons require a common base.").
canonical_commitment(c_percent_relative_base,
                     "Percent quantities are relative to their reference base and to one hundred percent as the whole.").
canonical_commitment(c_part_whole_relation,
                     "Part-whole and part-part relations must keep the base and roles fixed.").
canonical_commitment(c_probability_sample_space,
                     "Probability claims depend on the sample space, outcome structure, and equiprobability conditions.").
canonical_commitment(c_probability_independence,
                     "Independent trials have no memory and preserve constant probabilities across trials.").
canonical_commitment(c_probability_compound_event_structure,
                     "Compound-event probabilities require coordinated joint or conditional event structure.").
canonical_commitment(c_statistics_distribution_and_variability,
                     "Statistical inference must coordinate mean, distribution, variability, sample size, and representation.").
canonical_commitment(c_geometric_definition_and_invariance,
                     "Geometric objects and figures obey definition, invariance, and transformation constraints.").
canonical_commitment(c_angle_structure_measure,
                     "Angle measure is grounded in two-ray structure, rotation, and consistent units.").
canonical_commitment(c_measurement_dimension_and_units,
                     "Measurement formulas must preserve dimension, unit, and quantity structure.").
canonical_commitment(c_area_volume_scaling,
                     "Area and volume scale by square and cubic dimension, not linearly unless justified.").
canonical_commitment(c_calculus_limit_process_definition,
                     "Limits, continuity, convergence, derivatives, and integrals are defined by limiting processes.").
canonical_commitment(c_accumulation_rate_distinction,
                     "Accumulation and rate of change are distinct quantities linked by calculus relations.").
canonical_commitment(c_tangent_local_linear_approximation,
                     "A tangent or derivative is a local linear approximation, not a global secant or object endpoint.").
canonical_commitment(c_signed_number_order_and_operations,
                     "Signed numbers are ordered directed quantities with sign-sensitive operations.").
canonical_commitment(c_set_membership_and_operations,
                     "Set membership, union, intersection, and set-level predicates have formal conditions.").
canonical_commitment(c_combinatorial_systematic_counting,
                     "Combinatorial counts require systematic enumeration of the stipulated outcome structure.").
canonical_commitment(c_cartesian_product_structure,
                     "Cartesian products count coordinated ordered combinations across factors.").
canonical_commitment(c_model_fidelity_to_situation,
                     "A mathematical model must stay faithful to the described situation and constraints.").
canonical_commitment(c_notation_representation_equivalence,
                     "Notation and representation changes must preserve the represented mathematical object.").
canonical_commitment(c_inverse_relation_structure,
                     "Inverse relations must coordinate the original operation, direction, and quantity roles.").
canonical_commitment(c_conservation_invariance,
                     "Conservation and invariance commitments preserve the relevant total or structure under transformation.").
canonical_commitment(c_conceptual_justification_warrant,
                     "Mathematical answers require conceptual justification or warrant, not only procedural output.").
canonical_commitment(c_answer_addresses_original_question,
                     "A final answer must address the original question and interpret intermediate quantities.").
canonical_commitment(c_domain_tracking,
                     "Mathematical claims require tracking domain restrictions and intended applicability.").
canonical_commitment(c_systems_simultaneous_coordination,
                     "Systems of equations require simultaneous coordination of all constraints.").
canonical_commitment(c_vector_linear_structure,
                     "Vectors, spanning, and eigenvector claims require the relevant linear-structure conditions.").
canonical_commitment(c_periodicity_domain_structure,
                     "Periodicity claims require exact repetition over the intended domain.").
canonical_commitment(c_physics_quantity_structure,
                     "Physical quantities such as torque, force, and stochastic motion obey their modeled relations.").
canonical_commitment(c_mathematical_register_precision,
                     "Technical mathematical register and naming conventions carry precise commitments.").


%% ----------------------------------------------------------------------
%% Raw domain -> project-level corpus axis

domain_map(algebra, algebraic).
domain_map(algebraic, algebraic).
domain_map(arithmetic, whole_number).
domain_map(biology, other).
domain_map(calculus, calculus).
domain_map(chemistry, other).
domain_map(combinatorial, discrete).
domain_map(decimal, decimal).
domain_map(discrete, discrete).
domain_map(division, whole_number).
domain_map(fraction, fraction).
domain_map(general_mathematics, other).
domain_map(geometric, geometry_measurement).
domain_map(integer, integer).
domain_map(irrational, fraction).
domain_map(logic, discrete).
domain_map(measurement, geometry_measurement).
domain_map(modeling, other).
domain_map(multiplication, whole_number).
domain_map(multiplication_division, whole_number).
domain_map(multistep_procedures, other).
domain_map(number_bases, whole_number).
domain_map(number_concepts, whole_number).
domain_map(number_theory, whole_number).
domain_map(nutrition, other).
domain_map(other, other).
domain_map(pedagogical, other).
domain_map(pedagogy, other).
domain_map(percent, proportional).
domain_map(percentages, proportional).
domain_map(physics, other).
domain_map(probability, data_probability).
domain_map(problem_solving, other).
domain_map(proof, discrete).
domain_map(proportion, proportional).
domain_map(proportional, proportional).
domain_map(proportional_reasoning, proportional).
domain_map(ratio, proportional).
domain_map(ratio_proportion, proportional).
domain_map(rational, fraction).
domain_map(rational_numbers, fraction).
domain_map(real_analysis, calculus).
domain_map(real_numbers, fraction).
domain_map(statistics, data_probability).
domain_map(subtraction, whole_number).
domain_map(trigonometry, calculus).
domain_map(whole_number, whole_number).
domain_map(word_problems, other).
domain_map(Domain, other) :-
    atom(Domain),
    \+ domain_map(Domain, _Known),
    !.


%% ----------------------------------------------------------------------
%% Raw incompatible_with atom -> canonical commitment

commitment_map(Raw, c_fraction_subtraction_common_unit) :-
    atom_contains_any(Raw, [fraction_subtraction, fraction_subtract, subtract_fractions]),
    atom_contains_any(Raw, [common_denominator, common_unit]).
commitment_map(Raw, c_fraction_addition_common_unit) :-
    (   atom_contains_any(Raw, [fraction_addition, common_denominator_addition,
                                common_unit_fraction_addition,
                                common_denominator_fraction_addition,
                                fraction_comparison_requires_common_denominator])
    ;   atom_contains_all(Raw, [add, denominator, fraction])
    ).
commitment_map(Raw, c_equal_sharing_partition_model) :-
    atom_contains_any(Raw, [dealing_guarantees_equal_shares, equal_shares,
                            equal_share, sharing_partition]).
commitment_map(Raw, c_fraction_equivalence_multiplicative_scaling) :-
    (   atom_contains_all(Raw, [equivalence, fraction])
    ;   atom_contains_any(Raw, [equivalent_fraction,
                                scaling_numerator_and_denominator,
                                multiplicative_equivalence])
    ).
commitment_map(Raw, c_fraction_denominator_inverse_unit_size) :-
    (   atom_contains_all(Raw, [unit_fraction, denominator])
    ;   atom_contains_any(Raw, [inverse_relation_of_denominator,
                                inverse_relation_of_unit_fraction,
                                denominator_names_number_of_equal_partitions])
    ).
commitment_map(Raw, c_fraction_magnitude_common_whole) :-
    atom_contains_any(Raw, [fraction_magnitude, fraction_value,
                            common_whole, benchmark,
                            numerator_denominator_ratio,
                            joint_numerator_denominator_comparison,
                            fraction_as_single_relational_quantity,
                            shaded_region_denotes_the_fraction]).
commitment_map(Raw, c_fraction_referent_whole_invariance) :-
    atom_contains_any(Raw, [referent_whole, reference_whole, same_whole,
                            assigned_whole]).
commitment_map(Raw, c_fraction_multiplication_part_of_part) :-
    atom_contains_any(Raw, [fraction_multiplication, part_of_part, area_model,
                            cross_multiplication, multiply_across,
                            denominator_product]).
commitment_map(Raw, c_fraction_division_inverse_relation) :-
    atom_contains_any(Raw, [fraction_division, division_as_measurement,
                            dividing_by_one_half, reciprocal, quotitive]).
commitment_map(Raw, c_rational_density_between_any_two) :-
    atom_contains_any(Raw, [density_of_the_rationals, density_of_rational,
                            numbers_between, rational_interval]).
commitment_map(Raw, c_rational_representation_equivalence) :-
    atom_contains_any(Raw, [fractions_and_decimals, decimal_fraction,
                            rational_magnitude, shared_rational,
                            decimal_value_depends_on_both_numerator_and_denominator]).
commitment_map(Raw, c_decimal_place_value_alignment) :-
    atom_contains_any(Raw, [decimal_addition, place_value_alignment_in_addition,
                            decimal_point_alignment]).
commitment_map(Raw, c_decimal_place_value_ordering) :-
    atom_contains_any(Raw, [decimal_place_value, place_value_decimal,
                            decimal_magnitude, decimal_order,
                            alignment_in_decimal, decimal_comparison,
                            post_point, decimal_tail]).
commitment_map(Raw, c_decimal_trailing_zero_invariance) :-
    atom_contains_any(Raw, [trailing_zero, arbitrary_precision_decimal,
                            finite_decimal, decimal_zero]).
commitment_map(Raw, c_operation_effect_depends_on_operand_size) :-
    atom_contains_any(Raw, [operation_effect_depends,
                            multiplier_is_less_than_one,
                            divisor_is_less_than_one,
                            product_can_be_smaller,
                            quotient_can_be_larger,
                            scaling_by_factor_less_than_one,
                            multiplication_magnitude,
                            division_magnitude,
                            multiplication_increases,
                            division_decreases,
                            multiplication_by_factor_below_one]).
commitment_map(Raw, c_decimal_positional_notation) :-
    atom_contains_any(Raw, [decimal_point, positional, place_name]).
commitment_map(Raw, c_algorithm_flexibility_and_understanding) :-
    atom_contains_any(Raw, [standard_algorithm_exclusivity,
                            rote_fact_memorization,
                            derived_fact_rule_must_track_relation_between_addends,
                            algorithm_exclusivity,
                            exclusive_algorithm]).
commitment_map(Raw, c_base_ten_place_value_regrouping) :-
    atom_contains_any(Raw, [base_ten, place_value, regroup, carrying, borrow,
                            column, positional_notation]).
commitment_map(Raw, c_equality_relational_balance) :-
    atom_contains_any(Raw, [equals_sign, equality, equal_sign,
                            equation_balance, balance_preservation,
                            transitivity_of_the_equals_relation,
                            relational_equivalence,
                            equation_as_relational_statement]).
commitment_map(Raw, c_operator_precedence_grouping) :-
    atom_contains_any(Raw, [operator_precedence, order_of_operations,
                            left_to_right, grouping]).
commitment_map(Raw, c_subtraction_order_difference_relation) :-
    atom_contains_any(Raw, [subtraction_order, noncommutativity_of_subtraction,
                            minuend, subtrahend, take_away, difference]).
commitment_map(Raw, c_division_by_zero_undefined) :-
    atom_contains_any(Raw, [division_by_zero, zero_division]).
commitment_map(Raw, c_division_structure_and_remainder) :-
    atom_contains_any(Raw, [division, divisor, dividend, quotient, remainder]).
commitment_map(Raw, c_multiplicative_structure_not_additive) :-
    atom_contains_any(Raw, [multiplication, multiply, product, factor]),
    atom_contains_any(Raw, [additive, addition, partial_product, distribut]).
commitment_map(Raw, c_counting_cardinality_units) :-
    atom_contains_any(Raw, [count, cardinal, bijection, one_to_one,
                            stable_order, endpoint]).
commitment_map(Raw, c_parity_definition_includes_zero) :-
    atom_contains_any(Raw, [even, odd, parity]).
commitment_map(Raw, c_prime_composite_divisibility_definitions) :-
    atom_contains_any(Raw, [prime, composite, factorization, divisibility]).
commitment_map(Raw, c_estimation_rounding_reasonableness) :-
    atom_contains_any(Raw, [round, estimate, estimation, reasonableness]).
commitment_map(Raw, c_function_as_arbitrary_correspondence) :-
    atom_contains_any(Raw, [function, correspondence, input_output,
                            univalence, vertical_line]).
commitment_map(Raw, c_variable_as_generalized_quantity) :-
    atom_contains_any(Raw, [variable, unknown, indeterminate,
                            generalized_quantity, referent]).
commitment_map(Raw, c_rate_of_change_covariation) :-
    atom_contains_any(Raw, [slope, rate_of_change, covariation,
                            linear_rate, rise_over_run, constant_rate,
                            affine_linear_rule_commitment]).
commitment_map(Raw, c_distributivity_expansion_structure) :-
    atom_contains_any(Raw, [binomial, distribut, expansion,
                            linear_scaling_distribution]).
commitment_map(Raw, c_exponent_power_structure) :-
    atom_contains_any(Raw, [logarithm, exponent, power, root]).
commitment_map(Raw, c_associativity_single_operation) :-
    atom_contains_any(Raw, [associativity, associative]).
commitment_map(Raw, c_commutativity_operation_specific) :-
    atom_contains_any(Raw, [commutativity, commutative, noncommutativity]).
commitment_map(Raw, c_signed_term_structure) :-
    atom_contains_any(Raw, [preceding_operation_sign, signed_term,
                            term_carries, detach_sign]).
commitment_map(Raw, c_deductive_proof_logical_direction) :-
    atom_contains_any(Raw, [conditional, proof, prove, deductive, universal,
                            implication, converse, contrapositive,
                            logical_direction, necessary, sufficient,
                            generality_across]).
commitment_map(Raw, c_definition_precision_and_arity) :-
    atom_contains_any(Raw, [definition, defined, arity, formal_definition]).
commitment_map(Raw, c_substitution_semantics) :-
    atom_contains_any(Raw, [substitution, matching_terms]).
commitment_map(Raw, c_solution_set_semantics) :-
    atom_contains_any(Raw, [solution_set, all_reals, identity,
                            contradiction, satisfy_original_equation,
                            solution_must]).
commitment_map(Raw, c_like_terms_structural_combination) :-
    atom_contains_any(Raw, [like_term, like_terms, combining_only_like_terms]).
commitment_map(Raw, c_cancellation_requires_common_factor) :-
    atom_contains_any(Raw, [cancellation, cancelled, common_factor]).
commitment_map(Raw, c_zero_product_property) :-
    atom_contains_any(Raw, [zero_product]).
commitment_map(Raw, c_equation_quantitative_relation_model) :-
    atom_contains_any(Raw, [equation_encodes, equation_must_encode,
                            quantitative_relation,
                            representing_relationships,
                            translation_must_preserve]).
commitment_map(Raw, c_transformation_preserves_equivalence) :-
    atom_contains_any(Raw, [transformations_preserve,
                            manipulations_must_preserve, truth_value,
                            structure_preserving, structural_equivalence]).
commitment_map(Raw, c_structural_generalization) :-
    atom_contains_any(Raw, [generalization, generalisation, general_term,
                            structural_visual, general_rule]).
commitment_map(Raw, c_formula_domain_and_graph_consistency) :-
    atom_contains_any(Raw, [formula_graph, formula_holds, domain_tracking,
                            full_intended_domain, parameter,
                            graph_consistency]).
commitment_map(Raw, c_graph_axes_quantity_mapping) :-
    atom_contains_any(Raw, [graph_axes, maps_quantities_to_axes, axis,
                            coordinates]).
commitment_map(Raw, c_multiplicative_ratio_invariance) :-
    atom_contains_any(Raw, [ratio, proportion, proportional, scale, scaling,
                            multiplicative_invariance, constant_ratio,
                            multiplicative_comparison]).
commitment_map(Raw, c_unit_rate_common_base) :-
    atom_contains_any(Raw, [unit_rate, common_base, per_capita,
                            intensive_quantity]).
commitment_map(Raw, c_percent_relative_base) :-
    atom_contains_any(Raw, [percent, percentage, hundredths,
                            one_hundred_percent]).
commitment_map(Raw, c_part_whole_relation) :-
    atom_contains_any(Raw, [part_to_whole, part_whole, part_to_part]).
commitment_map(Raw, c_probability_independence) :-
    atom_contains_any(Raw, [independence, independent_trials, no_memory]).
commitment_map(Raw, c_probability_compound_event_structure) :-
    atom_contains_any(Raw, [compound_event, joint_sample_space,
                            multiplicative_rule_for_independent_events]).
commitment_map(Raw, c_probability_sample_space) :-
    atom_contains_any(Raw, [probability, sample_space, outcome,
                            equiprobable, random]).
commitment_map(Raw, c_statistics_distribution_and_variability) :-
    atom_contains_any(Raw, [mean, average, data, sampling, variability,
                            representativeness, correlation, distribution]).
commitment_map(Raw, c_angle_structure_measure) :-
    atom_contains_any(Raw, [angle, ray, rotation]).
commitment_map(Raw, c_area_volume_scaling) :-
    atom_contains_any(Raw, [area_scales, volume_scales, square_of_linear,
                            cubic, linearly]).
commitment_map(Raw, c_geometric_definition_and_invariance) :-
    atom_contains_any(Raw, [angle, triangle, circle, geometry, geometric,
                            figure]).
commitment_map(Raw, c_measurement_dimension_and_units) :-
    atom_contains_any(Raw, [area, perimeter, volume, dimension, measurement,
                            unit, units, length, time]).
commitment_map(Raw, c_accumulation_rate_distinction) :-
    atom_contains_any(Raw, [accumulation_and_rate, accumulation_vs_rate,
                            distinction_between_accumulation_and_rate]).
commitment_map(Raw, c_tangent_local_linear_approximation) :-
    atom_contains_any(Raw, [tangent, local_linear]).
commitment_map(Raw, c_calculus_limit_process_definition) :-
    atom_contains_any(Raw, [limit, epsilon, convergence, continuity,
                            derivative, integral, infinity, infinitesimal,
                            intermediate_value_theorem]).
commitment_map(Raw, c_signed_number_order_and_operations) :-
    atom_contains_any(Raw, [integer, negative, signed, sign, absolute_value,
                            number_line]).
commitment_map(Raw, c_set_membership_and_operations) :-
    atom_contains_any(Raw, [set, sets, membership, union, intersection,
                            disjunction, truth_conditions]).
commitment_map(Raw, c_combinatorial_systematic_counting) :-
    atom_contains_any(Raw, [combinatorial, permutation, combination,
                            enumeration, outcome_count]).
commitment_map(Raw, c_cartesian_product_structure) :-
    atom_contains_any(Raw, [cartesian_product, ordered_pair]).
commitment_map(Raw, c_model_fidelity_to_situation) :-
    atom_contains_any(Raw, [model, modeling, situation, context, referential,
                            fidelity]).
commitment_map(Raw, c_notation_representation_equivalence) :-
    atom_contains_any(Raw, [notation, representation, symbolic, expression]).
commitment_map(Raw, c_inverse_relation_structure) :-
    atom_contains_any(Raw, [inverse_operation, inverse_relation, inverse]).
commitment_map(Raw, c_conservation_invariance) :-
    atom_contains_any(Raw, [conservation, invariance, invariant,
                            preservation, preserved,
                            addition_compensation_opposite_change]).
commitment_map(Raw, c_conceptual_justification_warrant) :-
    atom_contains_any(Raw, [conceptual, justification, warrant, reasoning]).
commitment_map(Raw, c_answer_addresses_original_question) :-
    atom_contains_any(Raw, [answer_the_question, final_answer,
                            original_question,
                            newly_derived_quantities_must_be_interpreted]).
commitment_map(Raw, c_domain_tracking) :-
    atom_contains_any(Raw, [domain_restriction,
                            user_responsibility_for_domain_tracking,
                            intended_domain]).
commitment_map(Raw, c_systems_simultaneous_coordination) :-
    atom_contains_any(Raw, [systems_require_simultaneous,
                            simultaneous_algebraic_coordination]).
commitment_map(Raw, c_vector_linear_structure) :-
    atom_contains_any(Raw, [vector, spanning, eigenvector]).
commitment_map(Raw, c_periodicity_domain_structure) :-
    atom_contains_any(Raw, [periodic, periodicity, period_as_half_open_interval]).
commitment_map(Raw, c_physics_quantity_structure) :-
    atom_contains_any(Raw, [torque, force, stochastic, molecular, physics]).
commitment_map(Raw, c_mathematical_register_precision) :-
    atom_contains_any(Raw, [technical_register, register_conversion,
                            naming_commitment]).


%!  normalized_commitment(+RawCommitment, -CanonicalCommitment) is det.
%
%   Translate a free-form `incompatible_with` atom into the controlled
%   vocabulary. Unmapped atoms are kept visible as `uncategorized`; they do not
%   feed the deontic bridge.
normalized_commitment(RawCommitment, CanonicalCommitment) :-
    commitment_map(RawCommitment, CanonicalCommitment),
    !.
normalized_commitment(_RawCommitment, uncategorized).


%!  canonical_student_rule(+RawStudentRule, -CanonicalRule) is det.
%
%   Spelling-level canonicalization for `student_rule` atoms. Atoms in
%   `literature_student_rule_map:student_rule_map/2` land on their `sr_*`
%   canonical form; everything else passes through unchanged. The
%   pass-through default is deliberate: the tail of the distribution carries
%   nuance, and only attested spelling siblings collide here.
canonical_student_rule(RawStudentRule, CanonicalRule) :-
    (   student_rule_map(RawStudentRule, Mapped)
    ->  CanonicalRule = Mapped
    ;   CanonicalRule = RawStudentRule
    ).


%!  lit_incompatibility(?Id, ?CanonDomain, ?CanonCommitment, ?StudentRule,
%!                      ?ValidDomain, ?Orientation, ?Confidence) is nondet.
lit_incompatibility(Id, CanonDomain, CanonCommitment, StudentRule,
                    ValidDomain, Orientation, Confidence) :-
    lit_derived(Id, RawDomain, _Topic, StudentRule, ValidDomain,
                RawCommitment, Orientation, _CarspeckenScene, Confidence),
    domain_map(RawDomain, CanonDomain),
    normalized_commitment(RawCommitment, CanonCommitment).


%!  lit_incompatibility_meta(?Id, ?BibtexKey, ?Citation, ?Gloss) is nondet.
lit_incompatibility_meta(Id, BibtexKey, Citation, Gloss) :-
    lit_derived_meta(Id, BibtexKey, Citation, Gloss).


%!  lit_incompatibility_commitment(?Id, ?Commitment) is nondet.
%
%   The commitment is the student treating the documented rule as applicable in
%   the conflicting canonical context. Uncategorized tails are deliberately
%   withheld from the scorekeeper. The rule slot is canonicalized through
%   `canonical_student_rule/2`, so two attested spellings of one head rule
%   (for example `add_numerators_and_denominators` and
%   `add_numerators_and_add_denominators`) produce the same `applies_rule/2`
%   term and collide in the deontic engine. `lit_incompatibility/7` keeps the
%   raw atom for audit; only the commitment construction canonicalizes.
lit_incompatibility_commitment(Id,
                               applies_rule(CanonicalRule,
                                            in_context(CanonCommitment))) :-
    lit_incompatibility(Id, _CanonDomain, CanonCommitment, StudentRule,
                        _ValidDomain, _Orientation, _Confidence),
    CanonCommitment \== uncategorized,
    canonical_student_rule(StudentRule, CanonicalRule).


%!  lit_incompatibility_entitlement(?Id, ?Entitlement) is nondet.
lit_incompatibility_entitlement(Id, normative_commitment(CanonCommitment)) :-
    lit_incompatibility(Id, _CanonDomain, CanonCommitment, _StudentRule,
                        _ValidDomain, _Orientation, _Confidence),
    CanonCommitment \== uncategorized.


%!  literature_adjudication(?Commitment, ?Entitlement) is nondet.
literature_adjudication(Commitment, Entitlement) :-
    lit_incompatibility_commitment(Id, Commitment),
    lit_incompatibility_entitlement(Id, Entitlement).


deontic_scorekeeper:incompatible(Commitment, Entitlement) :-
    literature_adjudication(Commitment, Entitlement).


deontic_scorekeeper:requires_entitlement_fact(Commitment) :-
    lit_incompatibility_commitment(_Id, Commitment).


%!  literature_adjudicated_count(-Count) is det.
%
%   Number of distinct canonical commitment/entitlement pairs contributed by the
%   normalized literature layer.
literature_adjudicated_count(Count) :-
    findall(Commitment-Entitlement,
            literature_adjudication(Commitment, Entitlement),
            Pairs0),
    sort(Pairs0, Pairs),
    length(Pairs, Count).


%!  literature_adjudicated_fact_count(-Count) is det.
%
%   Number of individual generated facts that are mapped into the scorekeeper.
literature_adjudicated_fact_count(Count) :-
    aggregate_all(count,
                  lit_incompatibility_commitment(_Id, _Commitment),
                  Count).


%!  literature_mapping_stats(-Total, -Mapped, -Uncategorized, -PercentMapped) is det.
literature_mapping_stats(Total, Mapped, Uncategorized, PercentMapped) :-
    aggregate_all(count,
                  lit_incompatibility(_, _, _, _, _, _, _),
                  Total),
    aggregate_all(count,
                  ( lit_incompatibility(_, _, Commitment, _, _, _, _),
                    Commitment \== uncategorized
                  ),
                  Mapped),
    Uncategorized is Total - Mapped,
    (   Total =:= 0
    ->  PercentMapped = 0.0
    ;   PercentMapped is Mapped * 100.0 / Total
    ).


%!  linked_lit_incompatibility(?Id, ?MisconceptionName, ?Source) is nondet.
%
%   True when a normalized literature fact shares a source row with a runnable
%   wrong-answer arithmetic deformation in `test_harness:arith_misconception/6`.
linked_lit_incompatibility(Id, MisconceptionName, Source) :-
    lit_derived(Id, _RawDomain, _Topic, _StudentRule, _ValidDomain,
                _RawCommitment, _Orientation, _CarspeckenScene, _Confidence),
    derived_source(Id, Source),
    test_harness:arith_misconception(Source, _HarnessDomain, MisconceptionName,
                                     Rule, Input, Expected),
    Rule \== skip,
    once(rule_result(Rule, Input, Got)),
    Got \=@= Expected.


%!  linked_lit_incompatibility_exact_rule(?Id, ?MisconceptionName, ?Source) is nondet.
%
%   Stricter diagnostic: the generated StudentRule atom is identical to the
%   runnable harness misconception name.
linked_lit_incompatibility_exact_rule(Id, MisconceptionName, Source) :-
    lit_derived(Id, _RawDomain, _Topic, StudentRule, _ValidDomain,
                _RawCommitment, _Orientation, _CarspeckenScene, _Confidence),
    derived_source(Id, Source),
    test_harness:arith_misconception(Source, _HarnessDomain, MisconceptionName,
                                     Rule, Input, Expected),
    MisconceptionName == StudentRule,
    Rule \== skip,
    once(rule_result(Rule, Input, Got)),
    Got \=@= Expected.


linked_lit_incompatibility_count(Count) :-
    findall(Id-Name-Source,
            linked_lit_incompatibility(Id, Name, Source),
            Links0),
    sort(Links0, Links),
    length(Links, Count).


%!  linked_lit_incompatibility_canonical_rule(?Id, ?MisconceptionName,
%!                                            ?Source) is nondet.
%
%   Like `linked_lit_incompatibility_exact_rule/3`, but both the generated
%   StudentRule atom and the runnable harness misconception name are routed
%   through `canonical_student_rule/2` before comparison, so attested
%   spelling siblings of one head rule align where `==` misses them. The
%   shared-source-row requirement is unchanged; only name matching relaxes.
linked_lit_incompatibility_canonical_rule(Id, MisconceptionName, Source) :-
    lit_derived(Id, _RawDomain, _Topic, StudentRule, _ValidDomain,
                _RawCommitment, _Orientation, _CarspeckenScene, _Confidence),
    derived_source(Id, Source),
    test_harness:arith_misconception(Source, _HarnessDomain, MisconceptionName,
                                     Rule, Input, Expected),
    canonical_student_rule(StudentRule, CanonicalRule),
    canonical_student_rule(MisconceptionName, CanonicalRule),
    Rule \== skip,
    once(rule_result(Rule, Input, Got)),
    Got \=@= Expected.


linked_lit_incompatibility_exact_rule_count(Count) :-
    findall(Id-Name-Source,
            linked_lit_incompatibility_exact_rule(Id, Name, Source),
            Links0),
    sort(Links0, Links),
    length(Links, Count).


linked_lit_incompatibility_canonical_rule_count(Count) :-
    findall(Id-Name-Source,
            linked_lit_incompatibility_canonical_rule(Id, Name, Source),
            Links0),
    sort(Links0, Links),
    length(Links, Count).


derived_source(Id, db_row(RowId)) :-
    atom(Id),
    catch(atom_number(Id, RowId), _Error, fail).


rule_result(Module:LocalName, Input, Got) :-
    !,
    Goal =.. [LocalName, Input, Got],
    safe_call_rule(Module:Goal).
rule_result(LocalName, Input, Got) :-
    Goal =.. [LocalName, Input, Got],
    safe_call_rule(Goal).


safe_call_rule(Goal) :-
    catch(call_with_inference_limit(Goal, 100_000, Status),
          _Error,
          fail),
    Status \== inference_limit_exceeded.


atom_contains_any(Atom, Tokens) :-
    atom(Atom),
    member(Token, Tokens),
    sub_atom(Atom, _, _, _, Token),
    !.


atom_contains_all(Atom, Tokens) :-
    atom(Atom),
    forall(member(Token, Tokens),
           sub_atom(Atom, _, _, _, Token)).


%% ----------------------------------------------------------------------
%% Generated completion: 160 new commitments + exact maps for the atoms the
%% fuzzy rules above leave uncategorized. Included last so the curated exact
%% maps are consulted after the hand-written pattern rules.
:- include('literature_canonical_mappings.pl').
