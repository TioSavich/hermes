:- module(misconceptions_discrete_batch_1, []).
% discrete mathematics misconceptions — direct solo batch 1.
% Native symbolic layer only.

:- multifile test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.

% === row 37642: converse of a conditional assumed valid ===
% Rule: number below implies letter above.
% Correct: seeing a letter above does not force a number below.
% Error: a number is required below the tape.
% SCHEMA: Source-Path-Goal.
% GROUNDED: TODO distinguish implication direction from biconditional.
% CONNECTS TO: s(comp_nec(unlicensed(converse_of_conditional)))
r37642_converse_of_conditional(card(letter_above), number_required_below).

test_harness:arith_misconception(db_row(37642), discrete, converse_of_conditional,
    misconceptions_discrete_batch_1:r37642_converse_of_conditional,
    card(letter_above),
    number_not_required_below).

test_harness:arith_misconception(db_row(37643), discrete, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(37644), discrete, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(37890), discrete, too_vague, skip, none, none).

% === row 38114: subset criterion used for infinite cardinality ===
% Task: compare naturals and square numbers.
% Correct: same cardinality.
% Error: squares are fewer because they are a proper subset.
% SCHEMA: Container.
% GROUNDED: TODO use bijection for infinite sets, not finite part-whole size.
% CONNECTS TO: s(comp_nec(unlicensed(finite_subset_rule_for_infinite_sets)))
r38114_finite_subset_rule(compare_cardinality(naturals, squares), fewer_squares).

test_harness:arith_misconception(db_row(38114), discrete, finite_subset_rule_for_infinite_sets,
    misconceptions_discrete_batch_1:r38114_finite_subset_rule,
    compare_cardinality(naturals, squares),
    same_cardinality).

test_harness:arith_misconception(db_row(38201), discrete, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38320), discrete, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38506), discrete, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38507), discrete, too_vague, skip, none, none).

% === row 38825: infinite process treated like finite endpoint ===
% Correct: union of finite power sets contains finite subsets only.
% Error: writes a final P(X_infinity) object by analogy with finite cases.
% SCHEMA: Source-Path-Goal.
% GROUNDED: TODO encapsulate infinite union by its quantified membership condition.
% CONNECTS TO: s(comp_nec(unlicensed(finite_endpoint_for_infinite_process)))
r38825_finite_endpoint_for_infinite_process(infinite_union_power_sets, p(x_infinity)).

test_harness:arith_misconception(db_row(38825), discrete, finite_endpoint_for_infinite_process,
    misconceptions_discrete_batch_1:r38825_finite_endpoint_for_infinite_process,
    infinite_union_power_sets,
    finite_subsets_only).

% === row 38827: infinite element allowed in union of finite sets ===
% Correct: N is not an element of the union of power sets of finite prefixes.
% Error: N is treated as an element of the union.
% SCHEMA: Container.
% GROUNDED: TODO check membership in some finite-stage power set.
% CONNECTS TO: s(comp_nec(unlicensed(infinite_member_in_finite_stage_union)))
r38827_infinite_member_in_finite_union(member(naturals, union_finite_power_sets), true).

test_harness:arith_misconception(db_row(38827), discrete, infinite_member_in_finite_stage_union,
    misconceptions_discrete_batch_1:r38827_infinite_member_in_finite_union,
    member(naturals, union_finite_power_sets),
    false).

test_harness:arith_misconception(db_row(38889), discrete, too_vague, skip, none, none).

% === row 38982: disjunction false if one component is false ===
% Task: 15 is even or 15 is odd.
% Correct: true.
% Error: false because "15 is even" is false.
% SCHEMA: Container.
% GROUNDED: TODO evaluate inclusive disjunction at the whole-statement level.
% CONNECTS TO: s(comp_nec(unlicensed(disjunction_requires_both_parts_true)))
r38982_disjunction_requires_both_parts_true(or(even(15), odd(15)), false).

test_harness:arith_misconception(db_row(38982), discrete, disjunction_requires_both_parts_true,
    misconceptions_discrete_batch_1:r38982_disjunction_requires_both_parts_true,
    or(even(15), odd(15)),
    true).

% === row 38983: true disjunction rejected as pragmatically extraneous ===
% Correct: total order disjunction is true.
% Error: false because equality seems unnecessary when x \= y.
% SCHEMA: Container.
% GROUNDED: TODO separate formal truth from conversational informativeness.
% CONNECTS TO: s(comp_nec(unlicensed(pragmatic_rejection_of_true_disjunction)))
r38983_pragmatic_rejection(order_disjunction(real_x, real_y), false).

test_harness:arith_misconception(db_row(38983), discrete, pragmatic_rejection_of_true_disjunction,
    misconceptions_discrete_batch_1:r38983_pragmatic_rejection,
    order_disjunction(real_x, real_y),
    true).

% === row 38985: inclusive or interpreted exclusively ===
% Correct: true or true is true.
% Error: false when both components hold.
% SCHEMA: Container.
% GROUNDED: TODO use inclusive mathematical disjunction.
% CONNECTS TO: s(comp_nec(unlicensed(exclusive_or_for_inclusive_or)))
r38985_exclusive_or_for_inclusive_or(or(true, true), false).

test_harness:arith_misconception(db_row(38985), discrete, exclusive_or_for_inclusive_or,
    misconceptions_discrete_batch_1:r38985_exclusive_or_for_inclusive_or,
    or(true, true),
    true).

% === row 39044: arbitrary collections rejected as sets ===
% Correct: arbitrary well-defined collections can be sets.
% Error: a set must have an explicit common property.
% SCHEMA: Container.
% GROUNDED: TODO distinguish membership definition from shared attribute.
% CONNECTS TO: s(comp_nec(unlicensed(common_property_required_for_set)))
r39044_common_property_required(collection([apple, 7, blue]), not_set).

test_harness:arith_misconception(db_row(39044), discrete, common_property_required_for_set,
    misconceptions_discrete_batch_1:r39044_common_property_required,
    collection([apple, 7, blue]),
    set).

% === row 39045: singleton rejected as set ===
% Correct: one element can form a set.
% Error: at least two elements required.
% SCHEMA: Container.
% GROUNDED: TODO allow cardinality one containers.
% CONNECTS TO: s(comp_nec(unlicensed(singleton_not_set)))
r39045_singleton_not_set(set_candidate([a]), not_set).

test_harness:arith_misconception(db_row(39045), discrete, singleton_not_set,
    misconceptions_discrete_batch_1:r39045_singleton_not_set,
    set_candidate([a]),
    set).

% === row 39046: empty set rejected as set ===
% Correct: a collection with no elements can be a set.
% Error: no elements means not a set.
% SCHEMA: Container.
% GROUNDED: TODO allow empty container as a mathematical object.
% CONNECTS TO: s(comp_nec(unlicensed(empty_set_not_set)))
r39046_empty_set_not_set(set_candidate([]), not_set).

test_harness:arith_misconception(db_row(39046), discrete, empty_set_not_set,
    misconceptions_discrete_batch_1:r39046_empty_set_not_set,
    set_candidate([]),
    set).

% === row 39047: set equality by cardinality ===
% Correct: sets with different elements are not equal.
% Error: equal because they have the same number of elements.
% SCHEMA: Container.
% GROUNDED: TODO compare extensional membership, not just size.
% CONNECTS TO: s(comp_nec(unlicensed(set_equality_by_cardinality)))
r39047_set_equality_by_cardinality(compare_sets([1,2], [3,4]), equal).

test_harness:arith_misconception(db_row(39047), discrete, set_equality_by_cardinality,
    misconceptions_discrete_batch_1:r39047_set_equality_by_cardinality,
    compare_sets([1,2], [3,4]),
    not_equal).

% === row 39048: repeated set elements counted repeatedly ===
% Task: cardinality of {4,4,4,...}.
% Correct: 1.
% Error: infinity.
% SCHEMA: Container.
% GROUNDED: TODO collapse identical set elements.
% CONNECTS TO: s(comp_nec(unlicensed(repeated_elements_counted_in_set)))
r39048_repeated_elements_counted(cardinality(repeated_set(4)), infinity).

test_harness:arith_misconception(db_row(39048), discrete, repeated_elements_counted_in_set,
    misconceptions_discrete_batch_1:r39048_repeated_elements_counted,
    cardinality(repeated_set(4)),
    1).

test_harness:arith_misconception(db_row(39092), discrete, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39093), discrete, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39094), discrete, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39096), discrete, too_vague, skip, none, none).

% === row 39109: finite part-whole intuition applied to infinite sets ===
% Task: compare naturals and even naturals.
% Correct: same cardinality.
% Error: naturals are bigger because evens are a subset.
% SCHEMA: Container.
% GROUNDED: TODO use bijection n -> 2n for countable sets.
% CONNECTS TO: s(comp_nec(unlicensed(part_whole_rule_for_infinite_sets)))
r39109_part_whole_infinite(compare_cardinality(naturals, evens), naturals_bigger).

test_harness:arith_misconception(db_row(39109), discrete, part_whole_rule_for_infinite_sets,
    misconceptions_discrete_batch_1:r39109_part_whole_infinite,
    compare_cardinality(naturals, evens),
    same_cardinality).

% === row 39657: conditional negated as inverse conditional ===
% Task: negate "if it rains, I take an umbrella."
% Correct: it rains and I do not take an umbrella.
% Error: if it does not rain, I do not take an umbrella.
% SCHEMA: Source-Path-Goal.
% GROUNDED: TODO negate implication as antecedent plus negated consequent.
% CONNECTS TO: s(comp_nec(unlicensed(negate_conditional_as_inverse)))
r39657_negate_conditional_as_inverse(negate(if(rains, umbrella)), if(not(rains), not(umbrella))).

test_harness:arith_misconception(db_row(39657), discrete, negate_conditional_as_inverse,
    misconceptions_discrete_batch_1:r39657_negate_conditional_as_inverse,
    negate(if(rains, umbrella)),
    and(rains, not(umbrella))).

% === row 39658: De Morgan connective left unchanged ===
% Task: negate A and B.
% Correct: not A or not B.
% Error: not A and not B.
% SCHEMA: Container.
% GROUNDED: TODO flip connective when distributing negation.
% CONNECTS TO: s(comp_nec(unlicensed(demorgan_connective_unchanged)))
r39658_demorgan_connective_unchanged(negate(and(dogs_bark, convoy_passes)),
    and(not(dogs_bark), not(convoy_passes))).

test_harness:arith_misconception(db_row(39658), discrete, demorgan_connective_unchanged,
    misconceptions_discrete_batch_1:r39658_demorgan_connective_unchanged,
    negate(and(dogs_bark, convoy_passes)),
    or(not(dogs_bark), not(convoy_passes))).

test_harness:arith_misconception(db_row(39659), discrete, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39780), discrete, too_vague, skip, none, none).

% === row 39851: induction proposition treated as expression value ===
% Correct: P(1) denotes the proposition that the expression is divisible by 9.
% Error: P(1) is treated as the numeric expression value 9.
% SCHEMA: Container.
% GROUNDED: TODO keep proposition wrapper distinct from expression value.
% CONNECTS TO: s(comp_nec(unlicensed(proposition_as_expression_value)))
r39851_proposition_as_expression_value(induction_base(p(1)), expression_value(9)).

test_harness:arith_misconception(db_row(39851), discrete, proposition_as_expression_value,
    misconceptions_discrete_batch_1:r39851_proposition_as_expression_value,
    induction_base(p(1)),
    proposition_true).

test_harness:arith_misconception(db_row(39913), discrete, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39914), discrete, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39970), discrete, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39971), discrete, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39972), discrete, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39973), discrete, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(40509), discrete, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(40511), discrete, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(40614), discrete, too_vague, skip, none, none).
