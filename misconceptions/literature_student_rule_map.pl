/** <module> StudentRule spelling-level canonicalization map
 *
 * The generated literature corpus keeps free-form `student_rule` atoms as
 * audit evidence. Most of those atoms are singletons on purpose; the tail
 * carries nuance that a bulk merge would destroy. A small head of the
 * distribution, though, is the same rule spelled several ways, and those
 * spellings fail to collide in the deontic scorekeeper because
 * `applies_rule/2` terms are built from the raw atom.
 *
 * This module holds the curated spelling-level map: raw `student_rule` atom
 * to an `sr_*` canonical form. Scope discipline, per
 * docs/proposals/2026-06-29-implicit-commitment-join.md:
 *
 *   - Only spelling-level and head-cluster siblings are mapped. Two atoms
 *     merge when their rule text states the same claim (checked against the
 *     `lit_derived_meta/4` glosses where the atom alone is ambiguous).
 *   - Opposite claims, domain-qualified variants, conjoined rules, and
 *     procedural cousins stay distinct even when a lexical neighborhood
 *     groups them. Examples deliberately left out:
 *     `larger_denominator_means_smaller_fraction` (opposite claim),
 *     `multiplication_makes_bigger_division_makes_smaller_with_decimals`
 *     (domain-qualified), `add_numerator_and_denominator` (gloss says
 *     numerator plus denominator as one sum: "3/4 of 10 is 7"),
 *     `distribute_function_over_addition` (generalized beyond exponents).
 *   - Semantic merges across clusters (for example `sr_quotient_smaller_
 *     than_dividend` into `sr_division_always_makes_smaller`) wait for
 *     source-grounded adjudication (M2). The clusters here stay narrower
 *     than a semantic reading would allow.
 *
 * Candidate clusters came from the M1 lexical neighborhood proposer
 * (misconceptions/literature_derivation/neighborhoods/neighborhoods.json);
 * membership below was re-adjudicated by hand against the fact glosses, so
 * this map is narrower than the M1 neighborhoods. One member
 * (`more_decimal_digits_means_smaller`) sits in a different M1 neighborhood
 * (sr_0008) than its spelling siblings; its rule text places it here.
 *
 * Every raw atom in this map occurs in the `student_rule` slot of
 * `lit_derived/9` in literature_incompatibility_facts.pl. Canonical atoms
 * carry the `sr_` prefix, which no raw `student_rule` atom uses, so a
 * canonicalized rule is distinguishable from a pass-through at a glance.
 *
 * Consumed by `literature_vocabulary:canonical_student_rule/2`. Unmapped
 * atoms pass through unchanged there; this module never sees them.
 */
:- module(literature_student_rule_map,
          [ student_rule_map/2,
            student_rule_map_size/2
          ]).

%!  student_rule_map(?RawStudentRule, ?CanonicalRule) is nondet.
%
%   RawStudentRule is an attested `student_rule` atom from `lit_derived/9`;
%   CanonicalRule is its `sr_*` canonical form. The relation is functional
%   in the first argument (each raw atom maps to exactly one canonical).

%% sr_add_numerators_and_denominators
%% Add the numerators together and the denominators together as if the
%% fraction were two independent columns (the "mediant" error).
student_rule_map(add_numerators_and_denominators,
                 sr_add_numerators_and_denominators).
student_rule_map(add_numerators_and_add_denominators,
                 sr_add_numerators_and_denominators).
student_rule_map(add_numerators_and_denominators_separately,
                 sr_add_numerators_and_denominators).
student_rule_map(add_numerators_and_denominators_componentwise,
                 sr_add_numerators_and_denominators).
student_rule_map(add_numerators_and_denominators_straight_across,
                 sr_add_numerators_and_denominators).
student_rule_map(add_numerators_add_denominators,
                 sr_add_numerators_and_denominators).

%% sr_larger_denominator_means_larger_fraction
%% Only the larger-means-larger spelling family; the opposite claim and the
%% both-components variant in the same M1 neighborhood stay distinct.
student_rule_map(larger_denominator_means_larger_fraction,
                 sr_larger_denominator_means_larger_fraction).
student_rule_map(bigger_denominator_bigger_fraction,
                 sr_larger_denominator_means_larger_fraction).
student_rule_map(larger_denominator_is_larger_fraction,
                 sr_larger_denominator_means_larger_fraction).
student_rule_map(larger_denominator_larger_fraction,
                 sr_larger_denominator_means_larger_fraction).

%% sr_multiplication_makes_bigger_division_makes_smaller
%% The conjoined operation-effect rule, five spellings.
student_rule_map(multiplication_increases_division_decreases,
                 sr_multiplication_makes_bigger_division_makes_smaller).
student_rule_map(multiplication_makes_bigger_division_makes_smaller,
                 sr_multiplication_makes_bigger_division_makes_smaller).
student_rule_map(multiplication_enlarges_division_shrinks,
                 sr_multiplication_makes_bigger_division_makes_smaller).
student_rule_map(multiply_enlarges_divide_shrinks,
                 sr_multiplication_makes_bigger_division_makes_smaller).
student_rule_map(multiply_make_bigger_divide_make_smaller,
                 sr_multiplication_makes_bigger_division_makes_smaller).

%% sr_multiplication_always_makes_bigger
%% The multiplication-only overgeneralization. Kept apart from the conjoined
%% rule above; `multiplication_and_addition_always_increase` stays distinct.
student_rule_map(multiplication_always_increases,
                 sr_multiplication_always_makes_bigger).
student_rule_map(multiplication_always_makes_bigger,
                 sr_multiplication_always_makes_bigger).
student_rule_map(multiplication_makes_bigger,
                 sr_multiplication_always_makes_bigger).
student_rule_map(multiplication_always_increases_magnitude,
                 sr_multiplication_always_makes_bigger).
student_rule_map(multiplication_always_enlarges,
                 sr_multiplication_always_makes_bigger).
student_rule_map(multiplication_always_makes_larger,
                 sr_multiplication_always_makes_bigger).
student_rule_map(multiplying_always_enlarges,
                 sr_multiplication_always_makes_bigger).

%% sr_division_always_makes_smaller
%% The division-only overgeneralization. Procedural cousins
%% (`always_divide_larger_by_smaller`) and the quotient-expectation cluster
%% below stay distinct pending M2.
student_rule_map(division_always_makes_smaller,
                 sr_division_always_makes_smaller).
student_rule_map(division_makes_smaller,
                 sr_division_always_makes_smaller).
student_rule_map(division_always_decreases_magnitude,
                 sr_division_always_makes_smaller).
student_rule_map(division_decreases_result,
                 sr_division_always_makes_smaller).

%% sr_subtract_smaller_digit_from_larger_per_column
%% The columnwise subtraction bug. All glosses state per-column behavior,
%% including the unqualified `subtract_smaller_digit_from_larger` ("in each
%% column ... regardless of position"). The whole-number-level
%% `subtract_smaller_from_larger` (no digit/column qualifier) stays distinct.
student_rule_map(subtract_smaller_digit_from_larger_per_column,
                 sr_subtract_smaller_digit_from_larger_per_column).
student_rule_map(subtract_smaller_from_larger_per_column,
                 sr_subtract_smaller_digit_from_larger_per_column).
student_rule_map(subtract_smaller_digit_from_larger,
                 sr_subtract_smaller_digit_from_larger_per_column).
student_rule_map(subtract_smaller_digit_from_larger_in_column,
                 sr_subtract_smaller_digit_from_larger_per_column).
student_rule_map(smaller_from_larger_per_column,
                 sr_subtract_smaller_digit_from_larger_per_column).
student_rule_map(subtract_smaller_digit_from_larger_in_each_column,
                 sr_subtract_smaller_digit_from_larger_per_column).
student_rule_map(subtract_smaller_digit_from_larger_within_column,
                 sr_subtract_smaller_digit_from_larger_per_column).
student_rule_map(subtract_smaller_from_larger_within_column,
                 sr_subtract_smaller_digit_from_larger_per_column).

%% sr_longer_decimal_is_larger
%% `longer_is_larger` glosses as decimal ordering ("judge the decimal with
%% more digits to be the greater number"); the conjoined
%% `longer_decimals_are_bigger_and_multiplication_increases` stays distinct.
student_rule_map(longer_decimal_is_larger,
                 sr_longer_decimal_is_larger).
student_rule_map(longer_decimal_is_larger_by_digit_count,
                 sr_longer_decimal_is_larger).
student_rule_map(longer_is_larger,
                 sr_longer_decimal_is_larger).

%% sr_shorter_decimal_is_larger
student_rule_map(shorter_decimal_is_larger,
                 sr_shorter_decimal_is_larger).
student_rule_map(shorter_is_larger,
                 sr_shorter_decimal_is_larger).

%% sr_more_digits_means_larger_decimal
%% The more-digits-means-LARGER family only. The opposite family is
%% sr_more_decimal_places_means_smaller below; the disjunctive
%% `more_digits_or_larger_digits_means_larger_decimal` stays distinct.
student_rule_map(more_digits_means_larger_decimal,
                 sr_more_digits_means_larger_decimal).
student_rule_map(more_digits_after_point_means_larger,
                 sr_more_digits_means_larger_decimal).
student_rule_map(more_digits_means_greater,
                 sr_more_digits_means_larger_decimal).
student_rule_map(more_digits_means_larger,
                 sr_more_digits_means_larger_decimal).
student_rule_map(more_digits_makes_bigger,
                 sr_more_digits_means_larger_decimal).

%% sr_more_decimal_places_means_smaller
%% The more-digits-means-SMALLER family (denominator-size reasoning carried
%% onto decimals). Kept apart from the larger-family above.
student_rule_map(more_decimal_places_means_smaller,
                 sr_more_decimal_places_means_smaller).
student_rule_map(more_digits_means_smaller,
                 sr_more_decimal_places_means_smaller).
student_rule_map(more_decimal_digits_means_smaller,
                 sr_more_decimal_places_means_smaller).

%% sr_evaluate_strictly_left_to_right
student_rule_map(evaluate_strictly_left_to_right,
                 sr_evaluate_strictly_left_to_right).
student_rule_map(evaluate_expression_strictly_left_to_right,
                 sr_evaluate_strictly_left_to_right).
student_rule_map(evaluate_strictly_left_to_right_ignoring_precedence,
                 sr_evaluate_strictly_left_to_right).
student_rule_map(evaluate_strictly_left_to_right_like_reading,
                 sr_evaluate_strictly_left_to_right).

%% sr_equals_sign_means_compute_the_answer
student_rule_map(equals_sign_means_compute_the_answer,
                 sr_equals_sign_means_compute_the_answer).
student_rule_map(equal_sign_means_compute_the_result,
                 sr_equals_sign_means_compute_the_answer).
student_rule_map(equal_sign_signals_compute_the_answer,
                 sr_equals_sign_means_compute_the_answer).
student_rule_map(equals_sign_signals_compute_answer,
                 sr_equals_sign_means_compute_the_answer).
student_rule_map(equals_signals_compute_an_answer,
                 sr_equals_sign_means_compute_the_answer).

%% sr_divisor_must_be_whole_number
student_rule_map(divisor_must_be_whole_number,
                 sr_divisor_must_be_whole_number).
student_rule_map(divisor_must_be_a_whole_number,
                 sr_divisor_must_be_whole_number).

%% sr_equal_numerator_denominator_gap_means_equal_fractions
student_rule_map(equal_numerator_denominator_gap_means_equal,
                 sr_equal_numerator_denominator_gap_means_equal_fractions).
student_rule_map(equal_numerator_denominator_gap_means_equal_fractions,
                 sr_equal_numerator_denominator_gap_means_equal_fractions).
student_rule_map(fractions_equal_when_numerator_denominator_gap_equal,
                 sr_equal_numerator_denominator_gap_means_equal_fractions).

%% sr_fraction_as_two_independent_whole_numbers
%% All five glosses state the same reading ("read a fraction as two separate
%% whole numbers rather than one quantity").
student_rule_map(fraction_as_two_independent_whole_numbers,
                 sr_fraction_as_two_independent_whole_numbers).
student_rule_map(fraction_is_pair_of_independent_integers,
                 sr_fraction_as_two_independent_whole_numbers).
student_rule_map(fraction_is_two_whole_numbers,
                 sr_fraction_as_two_independent_whole_numbers).
student_rule_map(read_fraction_as_two_independent_whole_numbers,
                 sr_fraction_as_two_independent_whole_numbers).
student_rule_map(treat_numerator_and_denominator_as_independent_numbers,
                 sr_fraction_as_two_independent_whole_numbers).

%% sr_average_of_subgroup_averages
%% Unweighted averaging of subgroup means; glosses state one rule.
student_rule_map(average_of_subgroup_averages,
                 sr_average_of_subgroup_averages).
student_rule_map(average_of_subgroup_means,
                 sr_average_of_subgroup_averages).
student_rule_map(average_subgroup_averages_unweighted,
                 sr_average_of_subgroup_averages).
student_rule_map(average_subgroup_means_directly,
                 sr_average_of_subgroup_averages).

%% sr_distribute_exponent_over_sum
%% The exponent spellings only; `distribute_function_over_addition`
%% generalizes past exponents and stays distinct.
student_rule_map(distribute_exponent_linearly_over_a_sum,
                 sr_distribute_exponent_over_sum).
student_rule_map(distribute_exponent_linearly_over_sum,
                 sr_distribute_exponent_over_sum).
student_rule_map(distribute_exponent_over_addition,
                 sr_distribute_exponent_over_sum).
student_rule_map(distribute_exponent_over_sum,
                 sr_distribute_exponent_over_sum).

%% sr_quotient_smaller_than_dividend
%% Expectation about the quotient. Glosses read close to
%% sr_division_always_makes_smaller; folding the two together is a semantic
%% call reserved for M2, so the cluster stays separate.
student_rule_map(quotient_smaller_than_dividend,
                 sr_quotient_smaller_than_dividend).
student_rule_map(division_always_yields_quotient_smaller_than_dividend,
                 sr_quotient_smaller_than_dividend).
student_rule_map(quotient_must_be_less_than_dividend,
                 sr_quotient_smaller_than_dividend).


%!  student_rule_map_size(-MappedAtoms, -CanonicalForms) is det.
%
%   MappedAtoms is the number of raw atoms in the map; CanonicalForms is the
%   number of distinct `sr_*` targets.
student_rule_map_size(MappedAtoms, CanonicalForms) :-
    findall(Raw-Canon, student_rule_map(Raw, Canon), Pairs),
    length(Pairs, MappedAtoms),
    findall(Canon, member(_-Canon, Pairs), Canons0),
    sort(Canons0, Canons),
    length(Canons, CanonicalForms).
