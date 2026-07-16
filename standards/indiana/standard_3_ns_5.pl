/** <module> Standard 3.NS.5 — Compare fractions
 *
 * Indiana: 3.NS.5 — "Compare two fractions with the same numerator
 *          or the same denominator by reasoning about their size
 *          based on the same whole." (E)
 * CCSS:    3.NF.A.3d
 *
 * Two comparison strategies:
 *   1. Same denominator: larger numerator = larger fraction
 *      (more pieces of the same size)
 *   2. Same numerator: larger denominator = SMALLER fraction
 *      (same number of pieces, but each piece is smaller)
 *
 * BRANDOM CONNECTION: Same-numerator comparison introduces a
 *   non-obvious inference: MORE parts means SMALLER pieces.
 *   This is counter-intuitive for children accustomed to
 *   whole-number reasoning where "more" always means "bigger."
 *   The incompatibility between whole-number and fraction
 *   reasoning at this exact point is one of the documented
 *   fraction crisis symptoms.
 */

:- module(standard_3_ns_5, [
    compare_fractions/3,        % +FracA, +FracB, -Result
    compare_fractions_witness/4 % +FracA, +FracB, -Result, -Witness
]).

:- use_module(formalization(grounded_arithmetic), [
    equal_to/2,
    smaller_than/2,
    greater_than/2,
    recollection_to_integer/2,
    incur_cost/1
]).

%!  compare_fractions(+FracA, +FracB, -Result) is semidet.
%
%   Compare two fractions. Requires same numerator OR same
%   denominator (per Grade 3 standard). Fails otherwise.
%
%   Same denominator: compare numerators directly.
%   Same numerator: INVERT denominator comparison
%   (larger denominator = smaller fraction).

compare_fractions(fraction(NA, DA), fraction(NB, DB), Result) :-
    incur_cost(inference),
    compare_fractions_witness(fraction(NA, DA), fraction(NB, DB), Result, _).

%!  compare_fractions_witness(+FracA, +FracB, -Result, -Witness) is semidet.
%
%   Witness-bearing version of compare_fractions/3. This is the closed-world
%   finite case for Grade 3 fraction comparisons with either a shared
%   denominator or a shared numerator. Different numerator and denominator
%   pairs are outside this finite rule surface and fail here.
compare_fractions_witness(fraction(NA, DA), fraction(NB, DB), Result, Witness) :-
    (   equal_to(DA, DB)
    ->  compare_same_den_witness(NA, NB, Result, RuleWitness),
        Rule = same_denominator
    ;   equal_to(NA, NB)
    ->  compare_same_num_witness(DA, DB, Result, RuleWitness),
        Rule = same_numerator
    ;   fail
    ),
    fraction_comparison_witness(fraction(NA, DA),
                                fraction(NB, DB),
                                Result,
                                Rule,
                                RuleWitness,
                                Witness).

compare_same_den_witness(NA, NB, greater_than,
                         rule_witness(numerator_order, greater_than, NA, NB)) :-
    greater_than(NA, NB), !.
compare_same_den_witness(NA, NB, less_than,
                         rule_witness(numerator_order, less_than, NA, NB)) :-
    smaller_than(NA, NB), !.
compare_same_den_witness(NA, NB, equal_to,
                         rule_witness(numerator_order, equal_to, NA, NB)) :-
    equal_to(NA, NB).

%% INVERTED: larger denominator means smaller fraction
compare_same_num_witness(DA, DB, less_than,
                         rule_witness(denominator_order_inverted,
                                      greater_than,
                                      DA,
                                      DB)) :-
    greater_than(DA, DB), !.
compare_same_num_witness(DA, DB, greater_than,
                         rule_witness(denominator_order_inverted,
                                      less_than,
                                      DA,
                                      DB)) :-
    smaller_than(DA, DB), !.
compare_same_num_witness(DA, DB, equal_to,
                         rule_witness(denominator_order_inverted,
                                      equal_to,
                                      DA,
                                      DB)) :-
    equal_to(DA, DB).

fraction_comparison_witness(fraction(NA, DA),
                            fraction(NB, DB),
                            Result,
                            Rule,
                            RuleWitness,
                            _{ kind: standard_3_ns_5_fraction_comparison,
                               scope: closed_world_finite_standard_3_ns_5_fraction_comparison,
                               standard: in_3_ns_5,
                               source_predicate: compare_fractions/3,
                               left: fraction(NA, DA),
                               right: fraction(NB, DB),
                               left_pair: fraction(NAI, DAI),
                               right_pair: fraction(NBI, DBI),
                               result: Result,
                               rule: Rule,
                               rule_witness: RuleSafe,
                               derivation: grade3_same_part_comparison_rule,
                               boundary: same_numerator_or_same_denominator_only,
                               incompatibility_witness: IncompatibilityWitness }) :-
    recollection_to_integer(NA, NAI),
    recollection_to_integer(DA, DAI),
    recollection_to_integer(NB, NBI),
    recollection_to_integer(DB, DBI),
    rule_witness_safe(RuleWitness, RuleSafe),
    fraction_rule_incompatibility(Rule, IncompatibilityWitness).

rule_witness_safe(rule_witness(Projection, Relation, Left, Right),
                  _{ projection: Projection,
                     relation: Relation,
                     left: LeftInt,
                     right: RightInt }) :-
    recollection_to_integer(Left, LeftInt),
    recollection_to_integer(Right, RightInt).

fraction_rule_incompatibility(same_numerator,
                              _{ kind: fraction_order_incompatibility,
                                 source: same_numerator_fraction_ordering,
                                 incompatible_with: whole_number_denominator_ordering,
                                 reason: larger_denominator_means_smaller_unit_fraction_piece }).
fraction_rule_incompatibility(same_denominator,
                              _{ kind: fraction_order_incompatibility,
                                 source: same_denominator_fraction_ordering,
                                 incompatible_with: numerator_count_ignored,
                                 reason: same_sized_parts_are_ordered_by_numerator_count }).
