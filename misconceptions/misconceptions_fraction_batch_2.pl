:- module(misconceptions_fraction_batch_2, []).
% Fraction misconceptions — research corpus batch 2/7.
% Native arithmetic layer only. Theoretical annotations as comments:
%   % GROUNDED: TODO — placeholder for future embodied arithmetic layer
%   % SCHEMA: <schema name> — Lakoff & Nunez grounding when applicable
%   % CONNECTS TO: s(comp_nec(unlicensed(...))) — PML operator path
%
% Registration convention (from Task 3 arch fix):
%   test_harness:arith_misconception(Source, Domain, Description,
%       misconceptions_fraction_batch_2:rule_name, Input, Expected).
% Rule predicates do NOT go on the module export list.

:- multifile test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.

% ---- Encodings appended by agent for batch 2 ----

% === row 37435: perturbation on improper fraction ===
test_harness:arith_misconception(db_row(37435), fraction, too_vague,
    skip, none, none).

% === row 37442: perturbation on commensurate unit fractions ===
test_harness:arith_misconception(db_row(37442), fraction, too_vague,
    skip, none, none).

% === row 37449: struggle to interpret improper as valid ===
test_harness:arith_misconception(db_row(37449), fraction, too_vague,
    skip, none, none).

% === row 37459: reliance on figurative material ===
test_harness:arith_misconception(db_row(37459), fraction, too_vague,
    skip, none, none).

% === row 37487: add numerators and denominators separately ===
% Task: 1/2 + 2/3
% Correct: frac(7,6)  (common denominator)
% Error: frac(3,5) by (1+2)/(2+3)
% SCHEMA: Arithmetic is Object Collection — two counts, added independently
% GROUNDED: TODO — add_grounded(RN1,RN2,RNSum), add_grounded(RD1,RD2,RDSum)
% CONNECTS TO: s(comp_nec(unlicensed(componentwise_addition)))
r37487_add_across(frac(N1,D1)-frac(N2,D2), frac(NSum,DSum)) :-
    NSum is N1 + N2,
    DSum is D1 + D2.

test_harness:arith_misconception(db_row(37487), fraction, add_across_numer_denom,
    misconceptions_fraction_batch_2:r37487_add_across,
    frac(1,2)-frac(2,3),
    frac(7,6)).

% === row 37511: count all parts across two wholes as single unit ===
% Task: two circles each divided in fourths, 5 parts shaded total
% Correct: frac(5,4)  (unit is one circle)
% Error: frac(5,8) — collapses both circles into one 8-part whole
% SCHEMA: Container — the student merged two containers into one
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(unit_collapse(merge_wholes))))
r37511_merge_wholes(shaded(Shaded)-parts_per(PerWhole)-wholes(N), frac(Shaded, Denom)) :-
    Denom is PerWhole * N.

test_harness:arith_misconception(db_row(37511), fraction, merge_wholes_as_unit,
    misconceptions_fraction_batch_2:r37511_merge_wholes,
    shaded(5)-parts_per(4)-wholes(2),
    frac(5,4)).

% === row 37519: teacher insists single-pizza unit, 14/24 becomes 14/12 ===
% Task: fraction of 14 slices across 2 pizzas each 12-part
% Correct: frac(14,24) with "2 pizzas" as whole
% Error: frac(14,12) — forces improper by fixing single-pizza unit
% SCHEMA: Container — referent whole rigidly fixed to one container
% CONNECTS TO: s(comp_nec(unlicensed(referent_whole_fixed)))
r37519_single_pizza_unit(slices(S)-parts_per(P)-pizzas(_N), frac(S,P)).

test_harness:arith_misconception(db_row(37519), fraction, referent_whole_single_pizza,
    misconceptions_fraction_batch_2:r37519_single_pizza_unit,
    slices(14)-parts_per(12)-pizzas(2),
    frac(14,24)).

% === row 37547: invert dividend instead of divisor ===
% Task: 1/4 ÷ 4
% Correct: frac(1,16)
% Error: 1/4 × 4 = 1 — inverted the dividend (or skipped inversion)
% SCHEMA: Arithmetic is Object Collection
% CONNECTS TO: s(comp_nec(unlicensed(invert_dividend)))
r37547_invert_dividend(frac(N,D)-Whole, Result) :-
    % student does frac(D,N) * Whole = (D*Whole)/N, in example 4/4 = 1
    Num is D * Whole,
    Result = frac(Num, N).

test_harness:arith_misconception(db_row(37547), fraction, invert_dividend_not_divisor,
    misconceptions_fraction_batch_2:r37547_invert_dividend,
    frac(1,4)-4,
    frac(1,16)).

% === row 37572: count tick marks instead of intervals ===
% Task: locate 2/4 on a number line from 0 to 1 with 5 ticks (4 intervals)
% Correct: frac(2,4)  with denominator = interval count (4)
% Error: frac(2,5) — uses tick count (5) as denominator
% SCHEMA: Measuring Stick — marks vs. intervals
% CONNECTS TO: s(comp_nec(unlicensed(count_marks_not_intervals)))
r37572_marks_not_intervals(num(N)-intervals(I), frac(N, Ticks)) :-
    Ticks is I + 1.

test_harness:arith_misconception(db_row(37572), fraction, count_marks_not_intervals,
    misconceptions_fraction_batch_2:r37572_marks_not_intervals,
    num(2)-intervals(4),
    frac(2,4)).

% === row 37586: compare using denominator inverse only ===
% Task: compare 1/2 and 4/5, return the larger
% Correct: frac(4,5)
% Error: frac(1,2) — "halves are larger than fifths" ignores numerator
% SCHEMA: Measuring Stick — size-of-piece override
% CONNECTS TO: s(comp_nec(unlicensed(denominator_only_compare)))
r37586_denom_only(frac(N1,D1)-frac(N2,D2), Larger) :-
    (   D1 < D2
    ->  Larger = frac(N1,D1)
    ;   Larger = frac(N2,D2)
    ).

test_harness:arith_misconception(db_row(37586), fraction, denominator_only_compare,
    misconceptions_fraction_batch_2:r37586_denom_only,
    frac(1,2)-frac(4,5),
    frac(4,5)).

% === row 37641: reciprocate when multiplying ===
% Task: 2/3 × 3/4
% Correct: frac(6,12) = 1/2
% Error: 2/3 × 4/3 = frac(8,9) — used reciprocal of second
% SCHEMA: Algorithmic confusion — division procedure imported to multiplication
% CONNECTS TO: s(comp_nec(unlicensed(algorithm_substitution(reciprocal_for_multiply))))
r37641_reciprocal_mult(frac(N1,D1)-frac(N2,D2), frac(Ns, Ds)) :-
    Ns is N1 * D2,
    Ds is D1 * N2.

test_harness:arith_misconception(db_row(37641), fraction, reciprocal_on_multiply,
    misconceptions_fraction_batch_2:r37641_reciprocal_mult,
    frac(2,3)-frac(3,4),
    frac(6,12)).

% === row 37665: linguistic interference more vs greater ===
test_harness:arith_misconception(db_row(37665), fraction, too_vague,
    skip, none, none).

% === row 37678: ambiguous representation of remainder ===
test_harness:arith_misconception(db_row(37678), fraction, too_vague,
    skip, none, none).

% === row 37695: sum of proper fractions always <1 ===
test_harness:arith_misconception(db_row(37695), fraction, too_vague,
    skip, none, none).

% === row 37761: partition by numerator not denominator ===
% Task: 3/5 of 10
% Correct: 6  (first /5 then ×3)
% Error: 3 groups of 3 = 9, remainder 1 — partitions by numerator
% SCHEMA: Object Collection — numerator treated as group count
% CONNECTS TO: s(comp_nec(unlicensed(partition_by_numerator)))
r37761_group_by_numerator(frac(N,_D)-Total, GroupSize) :-
    GroupSize is Total div N.

test_harness:arith_misconception(db_row(37761), fraction, partition_by_numerator,
    misconceptions_fraction_batch_2:r37761_group_by_numerator,
    frac(3,5)-10,
    6).

% === row 37780: perceptual width comparison ===
test_harness:arith_misconception(db_row(37780), fraction, too_vague,
    skip, none, none).

% === row 37798: visualizing invert-and-multiply ===
test_harness:arith_misconception(db_row(37798), fraction, too_vague,
    skip, none, none).

% === row 37821: fraction as arrangement of parts ===
test_harness:arith_misconception(db_row(37821), fraction, too_vague,
    skip, none, none).

% === row 37845: count parts ignoring unequal sizes ===
% Task: 1 shaded of 5 unequal parts; what fraction is shaded?
% Correct: frac(1,5) is not well-defined for unequal parts;
%          correct answer requires area ratio — we encode the recognition
%          that "unequal parts" makes fraction naming invalid.
test_harness:arith_misconception(db_row(37845), fraction, too_vague,
    skip, none, none).

% === row 37859: 11/12 - 4/6 computed as 7/18 ===
% Task: 11/12 - 4/6
% Correct: frac(3,12) = 1/4
% Error: frac(7,18) — subtract numerators, add denominators
% SCHEMA: Object Collection
% CONNECTS TO: s(comp_nec(unlicensed(componentwise_subtract_add_denom)))
r37859_sub_num_add_denom(frac(N1,D1)-frac(N2,D2), frac(Nd, Ds)) :-
    Nd is N1 - N2,
    Ds is D1 + D2.

test_harness:arith_misconception(db_row(37859), fraction, sub_numer_add_denom,
    misconceptions_fraction_batch_2:r37859_sub_num_add_denom,
    frac(11,12)-frac(4,6),
    frac(3,12)).

% === row 37878: numerator/denom as wholes/parts-each ===
test_harness:arith_misconception(db_row(37878), fraction, too_vague,
    skip, none, none).

% === row 37908: equivalence by adding constant to both ===
% Task: is 3/4 equal to 7/8? (Student claim: yes, by 3+4=7, 4+4=8)
% Correct: frac(6,8) is equivalent to 3/4, not frac(7,8)
% Error: student produced frac(7,8) as equivalent
% SCHEMA: Object Collection — add same amount to both
% CONNECTS TO: s(comp_nec(unlicensed(additive_equivalence)))
r37908_additive_equivalence(frac(N,D), frac(Ne, De)) :-
    Ne is N + D,
    De is D + D.

test_harness:arith_misconception(db_row(37908), fraction, additive_equivalence,
    misconceptions_fraction_batch_2:r37908_additive_equivalence,
    frac(3,4),
    frac(6,8)).

% === row 37921: pick fraction with larger natural components ===
% Task: compare 5/6 and 8/19, return larger
% Correct: frac(5,6)
% Error: frac(8,19) because 8>5 and 19>6
% SCHEMA: natural number bias
% CONNECTS TO: s(comp_nec(unlicensed(natural_number_bias)))
r37921_larger_components(frac(N1,D1)-frac(N2,D2), Larger) :-
    (   N1 >= N2, D1 >= D2
    ->  Larger = frac(N1,D1)
    ;   N2 >= N1, D2 >= D1
    ->  Larger = frac(N2,D2)
    ;   % fallback: pick by numerator
        (N1 > N2 -> Larger = frac(N1,D1) ; Larger = frac(N2,D2))
    ).

test_harness:arith_misconception(db_row(37921), fraction, natural_number_bias_larger,
    misconceptions_fraction_batch_2:r37921_larger_components,
    frac(5,6)-frac(8,19),
    frac(5,6)).

% === row 37971: relational vs absolute naming of share ===
test_harness:arith_misconception(db_row(37971), fraction, too_vague,
    skip, none, none).

% === row 38041: diagrams become too complex ===
test_harness:arith_misconception(db_row(38041), fraction, too_vague,
    skip, none, none).

% === row 38112: smaller cannot be divided by larger ===
test_harness:arith_misconception(db_row(38112), fraction, too_vague,
    skip, none, none).

% === row 38138: add numerators and denominators (whole-number transfer) ===
% Task: 1/3 + 1/6
% Correct: frac(3,6) = 1/2
% Error: frac(2,9)
% SCHEMA: Object Collection
% CONNECTS TO: s(comp_nec(unlicensed(componentwise_addition)))
r38138_add_across(frac(N1,D1)-frac(N2,D2), frac(Ns, Ds)) :-
    Ns is N1 + N2,
    Ds is D1 + D2.

test_harness:arith_misconception(db_row(38138), fraction, add_across_from_whole_number,
    misconceptions_fraction_batch_2:r38138_add_across,
    frac(1,3)-frac(1,6),
    frac(3,6)).

% === row 38214: name difference relative to one operand ===
% Task: difference between 1/2 and 1/3 (in red-rod units where 1/2 = 3 rods)
% Correct: frac(1,6)  (relative to the whole)
% Error: frac(1,3) — names rod relative to 1/2 (took 3 to make 1/2)
% SCHEMA: Measuring Stick — referent drift to operand
% CONNECTS TO: s(comp_nec(unlicensed(referent_drift(to_operand))))
r38214_difference_vs_operand(frac(N1,D1)-frac(N2,D2), frac(1, RodsPerOperand)) :-
    % difference = 1/(D1*D2/gcd); student names it by how many rods fit the larger operand
    % shortcut: student returns frac(1, D2) when D1 < D2, or frac(1, D1) otherwise
    Diff1 is N1 * D2 - N2 * D1,
    Denom is D1 * D2,
    % student's "rods per operand" — for 1/2 vs 1/3, diff rod is 1/6,
    % 1/2 takes 3 rods; student says "one third"
    (   Diff1 =\= 0
    ->  RodsPerOperand is Denom // max(N1*D2, N2*D1)
    ;   RodsPerOperand = 1
    ).

test_harness:arith_misconception(db_row(38214), fraction, difference_named_by_operand,
    misconceptions_fraction_batch_2:r38214_difference_vs_operand,
    frac(1,2)-frac(1,3),
    frac(1,6)).

% === row 38238: 7/8 equal to 8/9 because one piece missing ===
% Task: compare 7/8 and 8/9 (both "one away from a whole")
% Correct: frac(8,9) > frac(7,8)
% Error: student says equal because each is missing one piece
% SCHEMA: Object Collection — focus on missing-piece count
% CONNECTS TO: s(comp_nec(unlicensed(missing_piece_equality)))
r38238_missing_piece_equality(frac(N1,D1)-frac(N2,D2), Result) :-
    Miss1 is D1 - N1,
    Miss2 is D2 - N2,
    (   Miss1 =:= Miss2
    ->  Result = equal
    ;   Miss1 < Miss2
    ->  Result = frac(N1,D1)
    ;   Result = frac(N2,D2)
    ).

test_harness:arith_misconception(db_row(38238), fraction, missing_piece_equality,
    misconceptions_fraction_batch_2:r38238_missing_piece_equality,
    frac(7,8)-frac(8,9),
    frac(8,9)).

% === row 38259: procedural common-denominator drawing ===
test_harness:arith_misconception(db_row(38259), fraction, too_vague,
    skip, none, none).

% === row 38282: linearity for mixed-number divisor ===
% Task: 16 ÷ 1.5 ≈ how many?
% Correct: ~10.666...  (encoded as frac(32,3) = 10 2/3)
% Error: 16÷2 = 8, plus half of 8 = 12 — linearity assumption
% SCHEMA: Measuring Stick — linear interpolation on divisor
% CONNECTS TO: s(comp_nec(unlicensed(linear_interpolate_divisor)))
r38282_linearity_divisor(Dividend-divisor_mixed(Whole,Half), Result) :-
    % student: dividend/(Whole+1) + half*(dividend/(Whole+1))
    % for 16 ÷ 1.5 with divisor_mixed(1,Half=1) treating Half as "+1/2":
    BaseDiv is Dividend // (Whole + 1),   % 16 // 2 = 8
    Adjust is (BaseDiv * Half) // 2,      % 8 // 2 = 4
    R is BaseDiv + Adjust,                % 12
    Result = R.

test_harness:arith_misconception(db_row(38282), fraction, linearity_on_divisor,
    misconceptions_fraction_batch_2:r38282_linearity_divisor,
    16-divisor_mixed(1,1),
    frac(32,3)).

% === row 38314: part as missing piece to complete standard whole ===
test_harness:arith_misconception(db_row(38314), fraction, too_vague,
    skip, none, none).

% === row 38346: interpret non-unit fraction as unit fraction ===
% Task: imagine 3/5 of a candy bar
% Correct: frac(3,5)
% Error: frac(1,5) or frac(1,3) — pulls a unit fraction
% SCHEMA: unit fractional scheme only — no iteration
% CONNECTS TO: s(comp_nec(unlicensed(non_unit_to_unit_collapse)))
r38346_non_unit_to_unit(frac(_N,D), frac(1,D)).

test_harness:arith_misconception(db_row(38346), fraction, non_unit_to_unit,
    misconceptions_fraction_batch_2:r38346_non_unit_to_unit,
    frac(3,5),
    frac(3,5)).

% === row 38375: ignores own model falls back on rule ===
test_harness:arith_misconception(db_row(38375), fraction, too_vague,
    skip, none, none).

% === row 38404: fraction cannot exceed parts per whole ===
test_harness:arith_misconception(db_row(38404), fraction, too_vague,
    skip, none, none).

% === row 38425: cannot name 2/15 in nested partitioning ===
test_harness:arith_misconception(db_row(38425), fraction, too_vague,
    skip, none, none).

% === row 38453: count unequal pieces as equal partition ===
% Task: partition into 4, then subdivide one of those into 3 → 6 pieces total, unequal
% Correct: frac(1,12) for a small piece (1/4 × 1/3)
% Error: frac(1,6) — counts all pieces as denominator
% SCHEMA: Object Collection — equipartitioning ignored
% CONNECTS TO: s(comp_nec(unlicensed(unequal_as_equal_parts)))
r38453_count_all_pieces(outer(Outer)-inner(Inner), frac(1, Total)) :-
    % student: total pieces = (Outer - 1) + Inner
    Total is (Outer - 1) + Inner.

test_harness:arith_misconception(db_row(38453), fraction, unequal_as_equal_parts,
    misconceptions_fraction_batch_2:r38453_count_all_pieces,
    outer(4)-inner(3),
    frac(1,12)).

% === row 38479: trial-and-error halving of collection ===
test_harness:arith_misconception(db_row(38479), fraction, too_vague,
    skip, none, none).

% === row 38555: fraction of discrete whole as multiplication ===
% Task: 1/3 of 18
% Correct: 6
% Error: 3 — interpreted 1/3 as "one three", so one group of three
% SCHEMA: Object Collection — denominator as iterating unit
% CONNECTS TO: s(comp_nec(unlicensed(denom_as_iterating_unit)))
r38555_denom_as_unit(frac(N,D)-_Total, Result) :-
    Result is N * D.

test_harness:arith_misconception(db_row(38555), fraction, denominator_as_iterating_unit,
    misconceptions_fraction_batch_2:r38555_denom_as_unit,
    frac(1,3)-18,
    6).

% === row 38572: fail to exhaust whole when partitioning ===
test_harness:arith_misconception(db_row(38572), fraction, too_vague,
    skip, none, none).

% === row 38646: arbitrary naming as half ===
test_harness:arith_misconception(db_row(38646), fraction, too_vague,
    skip, none, none).

% === row 38662: mental multiplication tracking failure ===
test_harness:arith_misconception(db_row(38662), fraction, too_vague,
    skip, none, none).

% === row 38671: rote multiplication without justification ===
test_harness:arith_misconception(db_row(38671), fraction, too_vague,
    skip, none, none).

% === row 38704: compare by complement size ===
% Task: compare 3/4 and 2/3, which is larger?
% Correct: frac(3,4)
% Error: reasons via complements — 1/3 > 1/4 so "2/3 is less missing" → picks 2/3
% Wait: student says 3/4 > 2/3 because 1/3 > 1/4 "makes 2/3 farther from whole"
% Actually student's erroneous claim: 3/4 > 2/3 BY comparing complements incorrectly.
% Here the mistake is using complement magnitude as if it flipped comparison.
% Correct answer IS 3/4 > 2/3. So the student's conclusion is correct by luck;
% the error is in reasoning about equivalents. Encode comparison via complement rule.
% SCHEMA: Measuring Stick — referent drift to complement
% CONNECTS TO: s(comp_nec(unlicensed(complement_magnitude_reasoning)))
r38704_complement_reasoning(frac(N1,D1)-frac(N2,D2), Larger) :-
    % student: the fraction with smaller complement is larger;
    % compares complement magnitudes via cross multiplication
    C1n is D1 - N1, C1d is D1,
    C2n is D2 - N2, C2d is D2,
    P1 is C1n * C2d,
    P2 is C2n * C1d,
    (   P1 < P2
    ->  Larger = frac(N1,D1)
    ;   Larger = frac(N2,D2)
    ).

test_harness:arith_misconception(db_row(38704), fraction, complement_magnitude_compare,
    misconceptions_fraction_batch_2:r38704_complement_reasoning,
    frac(3,4)-frac(2,3),
    frac(3,4)).

% === row 38752: procedural equivalence without meaning ===
test_harness:arith_misconception(db_row(38752), fraction, too_vague,
    skip, none, none).

% === row 38835: add straight across numerators and denominators ===
% Task: 1/4 + 1/6
% Correct: frac(5,12)
% Error: frac(2,10) by (1+1)/(4+6)
% CONNECTS TO: s(comp_nec(unlicensed(componentwise_addition)))
r38835_add_across(frac(N1,D1)-frac(N2,D2), frac(Ns,Ds)) :-
    Ns is N1 + N2,
    Ds is D1 + D2.

test_harness:arith_misconception(db_row(38835), fraction, add_across_whole_number,
    misconceptions_fraction_batch_2:r38835_add_across,
    frac(1,4)-frac(1,6),
    frac(5,12)).

% === row 38842: iterate unit fraction from proper fraction ===
test_harness:arith_misconception(db_row(38842), fraction, too_vague,
    skip, none, none).

% === row 38898: larger denominator = smaller fraction (close to one) ===
% Task: compare 99/100 and 15/16
% Correct: frac(99,100)  (closer to 1)
% Error: frac(15,16) — reasons "more parts = smaller pieces" ignoring numerator closeness
% SCHEMA: Measuring Stick — piece-size rule misapplied
% CONNECTS TO: s(comp_nec(unlicensed(denominator_only_compare)))
r38898_larger_denom_smaller(frac(N1,D1)-frac(N2,D2), Larger) :-
    (   D1 < D2
    ->  Larger = frac(N1,D1)
    ;   Larger = frac(N2,D2)
    ).

test_harness:arith_misconception(db_row(38898), fraction, denom_only_close_to_one,
    misconceptions_fraction_batch_2:r38898_larger_denom_smaller,
    frac(99,100)-frac(15,16),
    frac(99,100)).

% === row 38962: incomplete subdivision by young children ===
test_harness:arith_misconception(db_row(38962), fraction, too_vague,
    skip, none, none).

% === row 38980: write 7/2 for "seven and a half" ===
% Task: write "seven and a half"
% Correct: mixed(7, frac(1,2)) or frac(15,2)
% Error: frac(7,2) — appends /2 to any whole when hearing "half"
% SCHEMA: notation overgeneralization
% CONNECTS TO: s(comp_nec(unlicensed(notation_half_appends_2)))
r38980_appends_half_denom(Whole, frac(Whole, 2)).

test_harness:arith_misconception(db_row(38980), fraction, appends_half_as_denom,
    misconceptions_fraction_batch_2:r38980_appends_half_denom,
    7,
    frac(15,2)).

% === row 39010: confuse share count with share fraction ===
% Task: 8-part pizza, 4 pieces per share, what fraction is one share?
% Correct: frac(4,8) = 1/2
% Error: frac(1,4) — uses share-piece count as denominator
% SCHEMA: Object Collection — share count misread as partition denom
% CONNECTS TO: s(comp_nec(unlicensed(share_count_as_denominator)))
r39010_share_count_as_denom(share(Pieces)-whole(_Total), frac(1, Pieces)).

test_harness:arith_misconception(db_row(39010), fraction, share_count_as_denom,
    misconceptions_fraction_batch_2:r39010_share_count_as_denom,
    share(4)-whole(8),
    frac(4,8)).

% === row 39063: fraction value changes with base ===
test_harness:arith_misconception(db_row(39063), fraction, too_vague,
    skip, none, none).

% === row 39130: cross-multiply instead of straight multiply ===
% Task: 2/3 × 3/4
% Correct: frac(6,12)
% Error: frac(8,9) by cross-products (2*4)/(3*3)
% SCHEMA: algorithm confusion proportion vs product
% CONNECTS TO: s(comp_nec(unlicensed(cross_multiply_for_multiply)))
r39130_cross_multiply(frac(N1,D1)-frac(N2,D2), frac(Ns,Ds)) :-
    Ns is N1 * D2,
    Ds is D1 * N2.

test_harness:arith_misconception(db_row(39130), fraction, cross_multiply_misapplied,
    misconceptions_fraction_batch_2:r39130_cross_multiply,
    frac(2,3)-frac(3,4),
    frac(6,12)).

% === row 39152: swap dimensions in area model ===
test_harness:arith_misconception(db_row(39152), fraction, too_vague,
    skip, none, none).

% === row 39181: add with common-denominator multiplication rule ===
% Task: 1/4 + 1/6
% Correct: frac(5,12)  (common denominator sum)
% Error: frac(1,18) — applied multiplication rule "both up and across" → 1*1 / 4*6
% (Also reported 2/10; here we encode the multiplication-transfer variant.)
% SCHEMA: algorithm confusion add vs multiply
% CONNECTS TO: s(comp_nec(unlicensed(multiply_for_add)))
r39181_multiply_for_add(frac(N1,D1)-frac(N2,D2), frac(Ns,Ds)) :-
    Ns is N1 * N2,
    Ds is D1 * D2.

test_harness:arith_misconception(db_row(39181), fraction, multiply_rule_on_add,
    misconceptions_fraction_batch_2:r39181_multiply_for_add,
    frac(1,4)-frac(1,6),
    frac(5,12)).

% === row 39268: KFC mnemonic without understanding ===
test_harness:arith_misconception(db_row(39268), fraction, too_vague,
    skip, none, none).

% === row 39343: situational transfer failure ===
test_harness:arith_misconception(db_row(39343), fraction, too_vague,
    skip, none, none).

% === row 39410: prefer integer/discrete schemes ===
test_harness:arith_misconception(db_row(39410), fraction, too_vague,
    skip, none, none).

% === row 39469: larger denominator = larger fraction ===
% Task: compare 1/3 and 1/5
% Correct: frac(1,3)
% Error: frac(1,5) — "5 is bigger than 3"
% SCHEMA: whole-number bias
% CONNECTS TO: s(comp_nec(unlicensed(denom_larger_is_larger)))
r39469_denom_larger_is_larger(frac(N1,D1)-frac(N2,D2), Larger) :-
    (   D1 > D2
    ->  Larger = frac(N1,D1)
    ;   Larger = frac(N2,D2)
    ).

test_harness:arith_misconception(db_row(39469), fraction, denom_larger_is_larger,
    misconceptions_fraction_batch_2:r39469_denom_larger_is_larger,
    frac(1,3)-frac(1,5),
    frac(1,3)).

% === row 39555: invert-and-multiply without concept ===
test_harness:arith_misconception(db_row(39555), fraction, too_vague,
    skip, none, none).

% === row 39596: unidirectional iteration ===
test_harness:arith_misconception(db_row(39596), fraction, too_vague,
    skip, none, none).

% === row 39617: retrospective visual counting ===
test_harness:arith_misconception(db_row(39617), fraction, too_vague,
    skip, none, none).

% === row 39650: rigid on cancelling common factors ===
test_harness:arith_misconception(db_row(39650), fraction, too_vague,
    skip, none, none).

% === row 39684: procedural view of addition ===
test_harness:arith_misconception(db_row(39684), fraction, too_vague,
    skip, none, none).

% === row 39710: add across for 2/3 + 5/6 ===
% Task: 2/3 + 5/6
% Correct: frac(9,6) = 3/2
% Error: frac(7,9)
% CONNECTS TO: s(comp_nec(unlicensed(componentwise_addition)))
r39710_add_across(frac(N1,D1)-frac(N2,D2), frac(Ns,Ds)) :-
    Ns is N1 + N2,
    Ds is D1 + D2.

test_harness:arith_misconception(db_row(39710), fraction, add_across_unlike,
    misconceptions_fraction_batch_2:r39710_add_across,
    frac(2,3)-frac(5,6),
    frac(9,6)).

% === row 39764: order fractions by numerator only ===
% Task: order [13/12, 4/3, 7/6] smallest to largest
% Correct: [frac(7,6), frac(4,3), frac(13,12)] since 7/6 ≈ 1.167, 4/3 ≈ 1.333, 13/12 ≈ 1.083
% Actually correct ascending: 13/12 < 7/6 < 4/3  (1.083 < 1.167 < 1.333)
% Error: [frac(4,3), frac(7,6), frac(13,12)] — numerators 4 < 7 < 13 so reversed
% SCHEMA: natural number bias — numerator only
% CONNECTS TO: s(comp_nec(unlicensed(order_by_numerator)))
r39764_order_by_numerator(Fracs, Ordered) :-
    map_list_to_pairs([F, N]>>(F = frac(N,_)), Fracs, Keyed),
    keysort(Keyed, Sorted),
    pairs_values(Sorted, Ordered).

test_harness:arith_misconception(db_row(39764), fraction, order_by_numerator,
    misconceptions_fraction_batch_2:r39764_order_by_numerator,
    [frac(13,12), frac(4,3), frac(7,6)],
    [frac(13,12), frac(7,6), frac(4,3)]).

% === row 39771: reject fraction division as division ===
test_harness:arith_misconception(db_row(39771), fraction, too_vague,
    skip, none, none).

% === row 39802: difficulty with fraction estimation ===
test_harness:arith_misconception(db_row(39802), fraction, too_vague,
    skip, none, none).

% === row 39817: poses problem with other operation ===
test_harness:arith_misconception(db_row(39817), fraction, too_vague,
    skip, none, none).

% === row 39835: reads fraction as two separate wholes ===
test_harness:arith_misconception(db_row(39835), fraction, too_vague,
    skip, none, none).

% === row 39889: area-model on number line ===
test_harness:arith_misconception(db_row(39889), fraction, too_vague,
    skip, none, none).

% === row 39919: pick midway numerator and denominator ===
% Task: find a fraction between 1/2 and 3/4
% Correct: any fraction in (1/2, 3/4), e.g. frac(5,8)
% Error: frac(2,3) by picking a value between each component
% SCHEMA: componentwise order
% CONNECTS TO: s(comp_nec(unlicensed(componentwise_between)))
r39919_componentwise_between(frac(N1,D1)-frac(N2,D2), frac(Nm, Dm)) :-
    Nm is (N1 + N2) // 2,
    Dm is (D1 + D2) // 2.

test_harness:arith_misconception(db_row(39919), fraction, componentwise_between,
    misconceptions_fraction_batch_2:r39919_componentwise_between,
    frac(1,2)-frac(3,4),
    frac(5,8)).

% === row 40017: misread informal division reasoning as wrong ===
test_harness:arith_misconception(db_row(40017), fraction, too_vague,
    skip, none, none).

% === row 40082: rounding that doubles the product ===
% Task: estimate 534 7/9 * 0.495
% Correct: roughly 264 (about half of 534)
% Error: 500 — rounded 534 7/9 to 500 and 0.495 to 1, wildly overshoots
% SCHEMA: rounding without reasonableness check
% CONNECTS TO: s(comp_nec(unlicensed(round_both_up_wildly)))
r40082_round_divisor_up(frac(N,D)-Decimal_num_over_thousand, Result) :-
    % student: round N/D to nearest 100, round decimal to 1 if near 0.5
    RoundedWhole is round(N / D / 100) * 100,
    (   Decimal_num_over_thousand >= 400, Decimal_num_over_thousand =< 600
    ->  Factor = 1
    ;   Factor = 1
    ),
    Result is RoundedWhole * Factor.

test_harness:arith_misconception(db_row(40082), fraction, unreasonable_rounding,
    misconceptions_fraction_batch_2:r40082_round_divisor_up,
    frac(4813,9)-495,
    264).

% === row 40102: model change using equality of fractions ===
test_harness:arith_misconception(db_row(40102), fraction, too_vague,
    skip, none, none).

% === row 40117: PST rote invert-and-multiply ===
test_harness:arith_misconception(db_row(40117), fraction, too_vague,
    skip, none, none).

% === row 40129: repeated halving sharing ===
test_harness:arith_misconception(db_row(40129), fraction, too_vague,
    skip, none, none).

% === row 40145: wrong word problem for division ===
test_harness:arith_misconception(db_row(40145), fraction, too_vague,
    skip, none, none).

% === row 40174: inflexible common-denominator algorithm ===
test_harness:arith_misconception(db_row(40174), fraction, too_vague,
    skip, none, none).

% === row 40194: accept procedure as understanding ===
test_harness:arith_misconception(db_row(40194), fraction, too_vague,
    skip, none, none).

% === row 40214: accept nodding as learning ===
test_harness:arith_misconception(db_row(40214), fraction, too_vague,
    skip, none, none).

% === row 40235: partition remainder by wrong denominator ===
% Task: make 37/10 — build 3 ten-sticks for 30, need 7 more tenths
% Correct: split next stick into 10ths, take 7
% Error: splits next stick into 7ths — confuses "7 more" with denominator 7
% SCHEMA: partitive unit fractional scheme
% CONNECTS TO: s(comp_nec(unlicensed(remainder_count_as_denom)))
r40235_remainder_as_denom(frac(N, D), residue(Whole, frac(Remainder, Remainder))) :-
    Whole is N div D,
    Remainder is N mod D.

test_harness:arith_misconception(db_row(40235), fraction, remainder_count_as_denom,
    misconceptions_fraction_batch_2:r40235_remainder_as_denom,
    frac(37,10),
    residue(3, frac(7,10))).

% === row 40269: 8/5 equal to 5/8 (digit-swap insensitivity) ===
% Task: compare 8/5 and 5/8, pick larger
% Correct: frac(8,5)
% Error: treats them as equal
% SCHEMA: missing fraction magnitude sense
% CONNECTS TO: s(comp_nec(unlicensed(digit_swap_equal)))
r40269_digit_swap_equal(frac(N1,D1)-frac(N2,D2), Result) :-
    (   (N1 =:= D2, D1 =:= N2)
    ->  Result = equal
    ;   N1 * D2 > N2 * D1
    ->  Result = frac(N1,D1)
    ;   Result = frac(N2,D2)
    ).

test_harness:arith_misconception(db_row(40269), fraction, digit_swap_equal,
    misconceptions_fraction_batch_2:r40269_digit_swap_equal,
    frac(8,5)-frac(5,8),
    frac(8,5)).

% === row 40360: same numerator-denominator difference = equal ===
% Task: compare 30/31 and 36/37
% Correct: frac(36,37)  (closer to 1: cross 30*37=1110 vs 36*31=1116)
% Error: claim equal since 37-36 = 31-30 = 1
% SCHEMA: componentwise difference
% CONNECTS TO: s(comp_nec(unlicensed(equal_difference_equal_fraction)))
r40360_equal_difference(frac(N1,D1)-frac(N2,D2), Result) :-
    Diff1 is D1 - N1,
    Diff2 is D2 - N2,
    (   Diff1 =:= Diff2
    ->  Result = equal
    ;   N1*D2 > N2*D1
    ->  Result = frac(N1,D1)
    ;   Result = frac(N2,D2)
    ).

test_harness:arith_misconception(db_row(40360), fraction, equal_numer_denom_difference,
    misconceptions_fraction_batch_2:r40360_equal_difference,
    frac(30,31)-frac(36,37),
    frac(36,37)).

% === row 40379: add numerator and denominator to find missing ===
% Task: 9/12 = 3/?
% Correct: frac(3,4)  (scale factor 1/3)
% Error: 21 — added 9+12
% SCHEMA: Object Collection additive equivalence
% CONNECTS TO: s(comp_nec(unlicensed(add_num_denom_for_missing)))
r40379_add_for_missing(frac(N1,D1)=frac(N2,q), frac(N2, M)) :-
    M is N1 + D1.

test_harness:arith_misconception(db_row(40379), fraction, add_num_denom_missing,
    misconceptions_fraction_batch_2:r40379_add_for_missing,
    frac(9,12)=frac(3,q),
    frac(3,4)).

% === row 40410: fraction as operator ===
test_harness:arith_misconception(db_row(40410), fraction, too_vague,
    skip, none, none).

% === row 40452: smaller components = larger fraction ===
% Task: compare 1/2 and 3/8, pick larger
% Correct: frac(1,2)
% Error: smaller-numbers bias picks frac(1,2) correctly here,
% but the pattern is "fraction with smaller natural components" — encode
% via comparing sum of components.
% SCHEMA: inverted natural-number bias
% CONNECTS TO: s(comp_nec(unlicensed(smaller_components_larger)))
r40452_smaller_components(frac(N1,D1)-frac(N2,D2), Larger) :-
    S1 is N1 + D1,
    S2 is N2 + D2,
    (   S1 =< S2
    ->  Larger = frac(N1,D1)
    ;   Larger = frac(N2,D2)
    ).

test_harness:arith_misconception(db_row(40452), fraction, smaller_components_larger,
    misconceptions_fraction_batch_2:r40452_smaller_components,
    frac(1,2)-frac(3,8),
    frac(1,2)).

% === row 40469: convert division to addition then add across ===
% Task: 2/3 ÷ 1/7 (illustrative; original text gives 4 9/14 result)
% Correct: frac(14,3)
% Error: student says "change to addition": 2/3 + 1/7 then adds numerators and denoms
% SCHEMA: operation substitution + componentwise
% CONNECTS TO: s(comp_nec(unlicensed(div_to_add_then_across)))
r40469_div_to_add_across(frac(N1,D1)-frac(N2,D2), frac(Ns,Ds)) :-
    Ns is N1 + N2,
    Ds is D1 + D2.

test_harness:arith_misconception(db_row(40469), fraction, div_to_add_then_across,
    misconceptions_fraction_batch_2:r40469_div_to_add_across,
    frac(2,3)-frac(1,7),
    frac(14,3)).

% === row 40492: convert to percent treat as whole ===
test_harness:arith_misconception(db_row(40492), fraction, too_vague,
    skip, none, none).

% === row 40548: remainder named with varying unit referents ===
test_harness:arith_misconception(db_row(40548), fraction, too_vague,
    skip, none, none).

% === row 40619: measure-and-divide bypass of fraction ===
test_harness:arith_misconception(db_row(40619), fraction, too_vague,
    skip, none, none).
