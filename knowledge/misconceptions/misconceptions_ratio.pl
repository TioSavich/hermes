/** <module> Ratio misconception table
 *
 * This table holds literature-attested ratio misconception registrations
 * and their evidence predicates. Registrations use
 * test_harness:arith_misconception/6 with the schema
 * arith_misconception(Source, Domain, Description, Rule, Input, Expected).
 *
 * Rows retain source order: existing non-batch rows first, followed by batch
 * rows in ascending batch number. Provenance stays with each row; git history
 * is the archive.
 */
:- module(misconceptions_ratio, []).

:- multifile test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.

test_harness:arith_misconception(db_row(37606), ratio, too_vague, skip, none, none).

% === row 37647: sample volume changes taste strength ===
% Correct: samples from the same mixture have the same taste strength.
% Error: larger and smaller samples are treated as different strengths.
% SCHEMA: Container.
% GROUNDED: TODO preserve intensive quantity under sampling.
% CONNECTS TO: s(comp_nec(unlicensed(sample_size_changes_intensive_quantity)))
misconceptions_ratio_batch_1:r37647_sample_size_changes_taste(samples_same_mixture(7, 4), different_strengths).

test_harness:arith_misconception(db_row(37647), ratio, sample_size_changes_intensive_quantity,
    misconceptions_ratio_batch_1:r37647_sample_size_changes_taste,
    samples_same_mixture(7, 4),
    same_strength).

test_harness:arith_misconception(db_row(37648), ratio, too_vague, skip, none, none).

% === row 37649: numerical data overrules mixture invariance ===
% Correct: same mixture samples taste the same.
% Error: after dividing available numbers, concludes not same.
% SCHEMA: Container.
% GROUNDED: TODO distinguish sampled amount from mixture concentration.
% CONNECTS TO: s(comp_nec(unlicensed(numerical_overrides_intensive_invariance)))
misconceptions_ratio_batch_1:r37649_numerical_overrides_invariance(samples_same_mixture_with_amounts, not_same).

test_harness:arith_misconception(db_row(37649), ratio, numerical_overrides_intensive_invariance,
    misconceptions_ratio_batch_1:r37649_numerical_overrides_invariance,
    samples_same_mixture_with_amounts,
    same).

test_harness:arith_misconception(db_row(37715), ratio, too_vague, skip, none, none).

% === row 37831: additive comparison instead of 2:1 ratio ===
% Task: compare 42 steps to 21 steps.
% Correct: ratio 2.
% Error: additive difference 21.
% SCHEMA: Measuring Stick.
% GROUNDED: TODO coordinate multiplicative comparison rather than displacement.
% CONNECTS TO: s(comp_nec(unlicensed(additive_difference_for_ratio)))
misconceptions_ratio_batch_1:r37831_additive_difference_for_ratio(compare_steps(42, 21), additive_difference(21)).

test_harness:arith_misconception(db_row(37831), ratio, additive_difference_for_ratio,
    misconceptions_ratio_batch_1:r37831_additive_difference_for_ratio,
    compare_steps(42, 21),
    ratio(2)).

test_harness:arith_misconception(db_row(37895), ratio, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(37954), ratio, too_vague, skip, none, none).

% === row 37991: equal additive difference treated as equivalent ratio ===
% Task: compare 6:4 with 8:6.
% Correct: not equivalent.
% Error: equivalent because both terms differ by 2.
% SCHEMA: Source-Path-Goal.
% GROUNDED: TODO compare multiplicative scale, not additive gap.
% CONNECTS TO: s(comp_nec(unlicensed(additive_gap_as_ratio_equivalence)))
misconceptions_ratio_batch_1:r37991_additive_gap_equivalence(compare_ratios(ratio(6,4), ratio(8,6)), equivalent).

test_harness:arith_misconception(db_row(37991), ratio, additive_gap_as_ratio_equivalence,
    misconceptions_ratio_batch_1:r37991_additive_gap_equivalence,
    compare_ratios(ratio(6,4), ratio(8,6)),
    not_equivalent).

test_harness:arith_misconception(db_row(38048), ratio, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38183), ratio, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38321), ratio, too_vague, skip, none, none).

% === row 38487: subtracts known group from target total ===
% Task: 5 kids per teacher; 25 kids.
% Correct: 5 teachers.
% Error: 20, crossing out 5 kids from 25.
% SCHEMA: Object Collection.
% GROUNDED: TODO coordinate two sequences, kids and teachers.
% CONNECTS TO: s(comp_nec(unlicensed(subtract_unit_group_for_ratio)))
misconceptions_ratio_batch_1:r38487_subtract_unit_group_for_ratio(teachers_needed(25, kids_per_teacher(5)), 20).

test_harness:arith_misconception(db_row(38487), ratio, subtract_unit_group_for_ratio,
    misconceptions_ratio_batch_1:r38487_subtract_unit_group_for_ratio,
    teachers_needed(25, kids_per_teacher(5)),
    5).

% === row 38488: additive extension of ratio ===
% Task: 5 blues go with 3 reds; 10 blues go with how many reds?
% Correct: 6.
% Error: 8, adding 5 to both quantities.
% SCHEMA: Source-Path-Goal.
% GROUNDED: TODO scale both quantities by the same factor.
% CONNECTS TO: s(comp_nec(unlicensed(additive_ratio_extension)))
misconceptions_ratio_batch_1:r38488_additive_ratio_extension(missing_ratio_term(ratio(5,3), first_to(10)), 8).

test_harness:arith_misconception(db_row(38488), ratio, additive_ratio_extension,
    misconceptions_ratio_batch_1:r38488_additive_ratio_extension,
    missing_ratio_term(ratio(5,3), first_to(10)),
    6).

test_harness:arith_misconception(db_row(38489), ratio, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38501), ratio, too_vague, skip, none, none).

% === row 38502: ratio rounds added as same-denominator fractions ===
% Task: combine scores 6/25 and 8/25 across two rounds.
% Correct: 14/50, or 28%.
% Error: 14/25, or 56%.
% SCHEMA: Container.
% GROUNDED: TODO combine both successful cases and total opportunities.
% CONNECTS TO: s(comp_nec(unlicensed(add_ratio_parts_keep_one_whole)))
misconceptions_ratio_batch_1:r38502_add_ratio_parts_keep_one_whole(combine_scores(score(6,25), score(8,25)), frac(14,25)).

test_harness:arith_misconception(db_row(38502), ratio, add_ratio_parts_keep_one_whole,
    misconceptions_ratio_batch_1:r38502_add_ratio_parts_keep_one_whole,
    combine_scores(score(6,25), score(8,25)),
    frac(14,50)).

test_harness:arith_misconception(db_row(38542), ratio, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38772), ratio, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38943), ratio, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39133), ratio, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39163), ratio, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39380), ratio, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39466), ratio, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39535), ratio, too_vague, skip, none, none).

% === row 39638: equal additive difference means same mixture ===
% Task: compare 3:5 with 4:6.
% Correct: different concentrations.
% Error: same, because both differences are 2.
% SCHEMA: Container.
% GROUNDED: TODO compare ratios rather than additive gaps.
% CONNECTS TO: s(comp_nec(unlicensed(additive_gap_as_same_flavour)))
misconceptions_ratio_batch_1:r39638_additive_gap_same_flavour(compare_mixtures(ratio(3,5), ratio(4,6)), same).

test_harness:arith_misconception(db_row(39638), ratio, additive_gap_as_same_flavour,
    misconceptions_ratio_batch_1:r39638_additive_gap_same_flavour,
    compare_mixtures(ratio(3,5), ratio(4,6)),
    different).

% === row 39701: first component alone determines mixture strength ===
% Task: compare orange strength of 3:5 with 2:3.
% Correct: 3:5 is weaker as an orange fraction.
% Error: stronger, because 3 > 2.
% SCHEMA: Container.
% GROUNDED: TODO compare part-whole ratios, not one component alone.
% CONNECTS TO: s(comp_nec(unlicensed(first_component_only_ratio_compare)))
misconceptions_ratio_batch_1:r39701_first_component_only_compare(compare_mixtures(ratio(3,5), ratio(2,3)), stronger).

test_harness:arith_misconception(db_row(39701), ratio, first_component_only_ratio_compare,
    misconceptions_ratio_batch_1:r39701_first_component_only_compare,
    compare_mixtures(ratio(3,5), ratio(2,3)),
    weaker).

% === row 39714: impossible decimal ratio accepted physically ===
% Correct: a face-to-hand ratio of 0.1 is implausible in the given context.
% Error: accepts it as possible because the decimal calculation produced it.
% SCHEMA: Measuring Stick.
% GROUNDED: TODO validate numerical ratio against contextual magnitude.
% CONNECTS TO: s(comp_nec(unlicensed(context_ignored_for_ratio)))
misconceptions_ratio_batch_1:r39714_context_ignored_for_ratio(face_to_hand_ratio(0.1), possible).

test_harness:arith_misconception(db_row(39714), ratio, context_ignored_for_ratio,
    misconceptions_ratio_batch_1:r39714_context_ignored_for_ratio,
    face_to_hand_ratio(0.1),
    implausible).

test_harness:arith_misconception(db_row(40052), ratio, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(40053), ratio, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(40093), ratio, too_vague, skip, none, none).
