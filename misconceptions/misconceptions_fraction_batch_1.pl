:- module(misconceptions_fraction_batch_1, []).
% Fraction misconceptions — research corpus batch 1/7.
% Native arithmetic layer only. Theoretical annotations as comments:
%   % GROUNDED: TODO — placeholder for future embodied arithmetic layer
%   % SCHEMA: <schema name> — Lakoff & Nunez grounding when applicable
%   % CONNECTS TO: s(comp_nec(unlicensed(...))) — PML operator path
%
% Registration convention (from Task 3 arch fix):
%   test_harness:arith_misconception(Source, Domain, Description,
%       misconceptions_fraction_batch_1:rule_name, Input, Expected).
% Rule predicates do NOT go on the module export list.

:- multifile test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.

% ---- Encodings appended by agent for batch 1 ----

% === row 37434: add denominators on unit fractions ===
% Task: 1/7 + 1/7
% Correct: frac(2,7)
% Error: adds denominators -> frac(1,14)
% SCHEMA: Arithmetic is Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(add_denominators_unit)))
add_denoms_unit(frac(N1,D1)-frac(N2,D2), frac(N1, DSum)) :-
    N1 =:= N2,
    DSum is D1 + D2.

test_harness:arith_misconception(db_row(37434), fraction, add_denominators_unit_fractions,
    misconceptions_fraction_batch_1:add_denoms_unit,
    frac(1,7)-frac(1,7),
    frac(2,7)).

% === row 37441: names fraction as parts-of-total without simplifying ===
test_harness:arith_misconception(db_row(37441), fraction, too_vague,
    skip, none, none).

% === row 37448: arbitrary partition without anticipation ===
test_harness:arith_misconception(db_row(37448), fraction, too_vague,
    skip, none, none).

% === row 37458: cognitive depletion on improper fractions ===
test_harness:arith_misconception(db_row(37458), fraction, too_vague,
    skip, none, none).

% === row 37486: multiply numerators, add denominators ===
% Task: 1/2 + 2/3
% Correct: frac(7,6) (or 7/6)
% Error: multiplies numerators, adds denominators -> frac(2,5)
% SCHEMA: Arithmetic is Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(mult_num_add_denom)))
mult_num_add_denom(frac(N1,D1)-frac(N2,D2), frac(NProd, DSum)) :-
    NProd is N1 * N2,
    DSum is D1 + D2.

test_harness:arith_misconception(db_row(37486), fraction, mult_num_add_denom,
    misconceptions_fraction_batch_1:mult_num_add_denom,
    frac(1,2)-frac(2,3),
    frac(7,6)).

% === row 37510: larger denominator = larger unit fraction ===
% Task: compare 1/6 and 1/8, return the larger
% Correct: frac(1,6)
% Error: picks the one with larger denominator -> frac(1,8)
% SCHEMA: Arithmetic is Motion Along a Path (whole-number dominance)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(whole_num_denom_compare)))
pick_larger_denom(frac(N1,D1)-frac(N2,D2), Winner) :-
    (D1 > D2 -> Winner = frac(N1,D1) ; Winner = frac(N2,D2)).

test_harness:arith_misconception(db_row(37510), fraction, larger_denom_larger_fraction,
    misconceptions_fraction_batch_1:pick_larger_denom,
    frac(1,6)-frac(1,8),
    frac(1,6)).

% === row 37517: add numerators, average denominators ===
% Task: 12/13 + 7/8
% Correct: frac(187,104)
% Error: add numerators, average denominators -> frac(19,25) (approximately)
%   (13 * 2 = 26, 8 * 3 = 24 as common multiples; (26+24)/2 = 25)
% Simplified mechanical version: average the two given denominators.
% SCHEMA: Arithmetic is Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(add_num_avg_denom)))
add_num_avg_denom(frac(N1,D1)-frac(N2,D2), frac(NSum, DAvg)) :-
    NSum is N1 + N2,
    DAvg is (D1 + D2) // 2.

test_harness:arith_misconception(db_row(37517), fraction, add_num_average_denom,
    misconceptions_fraction_batch_1:add_num_avg_denom,
    frac(12,13)-frac(7,8),
    frac(187,104)).

% === row 37525: multiply whole by both numerator and denominator ===
% Task: 6 * 4/7
% Correct: frac(24,7)
% Error: multiplies whole by both parts -> frac(24,42)
% SCHEMA: Arithmetic is Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(scale_both_parts)))
scale_both_by_whole(frac(N,D)-W, frac(NOut, DOut)) :-
    NOut is N * W,
    DOut is D * W.

test_harness:arith_misconception(db_row(37525), fraction, whole_times_num_and_denom,
    misconceptions_fraction_batch_1:scale_both_by_whole,
    frac(4,7)-6,
    frac(24,7)).

% === row 37571: equivalent fraction via additive doubling ===
% Task: find equivalent to 5/3 in twelfths
% Correct: frac(20,12)
% Error: adds same quantity to top and bottom (3+3=6, 5+3=8)... actually
%   student reasoned "3 x 2 = 6 so 8 x 2 = 16" yielding frac(16,3) — they
%   fixed the numerator path and left the denominator unchanged.
% Encoded: takes numerator path (double added to get numerator) but keeps
%   the original denominator, then the student reports frac(NewN, OldD).
% SCHEMA: Measuring Stick (partial scaling)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(partial_scaling_numerator)))
equiv_add_to_numerator(frac(N,D)-TargetD, frac(NOut, D)) :-
    Diff is TargetD - D,
    NOut is N + N + Diff.  % reproduces '3x2=6 so 8x2=16' style

test_harness:arith_misconception(db_row(37571), fraction, equiv_additive_misapplication,
    misconceptions_fraction_batch_1:equiv_add_to_numerator,
    frac(5,3)-12,
    frac(20,12)).

% === row 37585: drawing 1/2 without shading ===
test_harness:arith_misconception(db_row(37585), fraction, too_vague,
    skip, none, none).

% === row 37640: subtract numerators and denominators separately ===
% Task: 12/31 - 5/8
% Correct: frac(61,248)
% Error: subtract both parts separately -> frac(7,23)
% SCHEMA: Arithmetic is Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(subtract_parts_separately)))
sub_parts_separately(frac(N1,D1)-frac(N2,D2), frac(NDiff, DDiff)) :-
    NDiff is N1 - N2,
    DDiff is D1 - D2.

test_harness:arith_misconception(db_row(37640), fraction, subtract_num_denom_separately,
    misconceptions_fraction_batch_1:sub_parts_separately,
    frac(12,31)-frac(5,8),
    frac(61,248)).

% === row 37664: 1/5 < 1/9 because 5 < 9 ===
% Task: compare 1/5 and 1/9, return larger
% Correct: frac(1,5)
% Error: picks smaller-denom as smaller, larger-denom as larger -> frac(1,9)
% SCHEMA: whole-number dominance over fraction symbols
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(whole_num_denom_compare)))
pick_larger_denom_as_larger(frac(N1,D1)-frac(N2,D2), Winner) :-
    (D1 > D2 -> Winner = frac(N1,D1) ; Winner = frac(N2,D2)).

test_harness:arith_misconception(db_row(37664), fraction, smaller_denom_smaller_fraction,
    misconceptions_fraction_batch_1:pick_larger_denom_as_larger,
    frac(1,5)-frac(1,9),
    frac(1,5)).

% === row 37677: fraction-of-fraction ignoring remainder ===
test_harness:arith_misconception(db_row(37677), fraction, too_vague,
    skip, none, none).

% === row 37694: misjudge reference benchmark ===
test_harness:arith_misconception(db_row(37694), fraction, too_vague,
    skip, none, none).

% === row 37760: 1/8 > 1/4 because 8 > 4 ===
% Task: compare 1/4 and 1/8, return larger
% Correct: frac(1,4)
% Error: picks larger-denom as larger -> frac(1,8)
% SCHEMA: whole-number dominance
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(denom_magnitude_direct)))
pick_larger_denom_magnitude(frac(N1,D1)-frac(N2,D2), Winner) :-
    (D1 > D2 -> Winner = frac(N1,D1) ; Winner = frac(N2,D2)).

test_harness:arith_misconception(db_row(37760), fraction, denom_is_magnitude,
    misconceptions_fraction_batch_1:pick_larger_denom_magnitude,
    frac(1,4)-frac(1,8),
    frac(1,4)).

% === row 37779: same fraction different wholes ===
test_harness:arith_misconception(db_row(37779), fraction, too_vague,
    skip, none, none).

% === row 37797: PST confuses mult/div representations ===
test_harness:arith_misconception(db_row(37797), fraction, too_vague,
    skip, none, none).

% === row 37812: fraction by piece-count guessing ===
test_harness:arith_misconception(db_row(37812), fraction, too_vague,
    skip, none, none).

% === row 37832: abstract task unreachable ===
test_harness:arith_misconception(db_row(37832), fraction, too_vague,
    skip, none, none).

% === row 37858: equal by absolute residual ===
% Task: compare 4/5 and 11/12 (both one piece from whole)
% Correct: frac(11,12) (larger)
% Error: treats them as equal because D-N is same -> returns equal
% Encoded: returns first fraction as the answer when residuals match.
% SCHEMA: Arithmetic is Object Collection (absolute gap)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(equal_residual_strategy)))
equal_residual(frac(N1,D1)-frac(N2,D2), equal) :-
    Diff1 is D1 - N1,
    Diff2 is D2 - N2,
    Diff1 =:= Diff2.

test_harness:arith_misconception(db_row(37858), fraction, equal_absolute_residual,
    misconceptions_fraction_batch_1:equal_residual,
    frac(4,5)-frac(11,12),
    frac(11,12)).

% === row 37873: denominator dominance ignoring numerator ===
% Task: compare 2/5 and 3/7, return larger
% Correct: frac(3,7) (3/7 > 2/5 since 21>10 with common denom 35: 14 vs 15)
% Error: picks smaller-denom as larger -> frac(2,5)
% SCHEMA: whole-number dominance
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(denom_only_compare)))
denom_dominance_small_bigger(frac(N1,D1)-frac(N2,D2), Winner) :-
    (D1 < D2 -> Winner = frac(N1,D1) ; Winner = frac(N2,D2)).

test_harness:arith_misconception(db_row(37873), fraction, denom_dominance_ignore_num,
    misconceptions_fraction_batch_1:denom_dominance_small_bigger,
    frac(2,5)-frac(3,7),
    frac(3,7)).

% === row 37907: inverted compare at common denom ===
% Task: compare 9/13 and 4/13, return larger
% Correct: frac(9,13)
% Error: inverts - says fewer pieces = larger because each piece is bigger
%        -> returns frac(4,13)
% SCHEMA: Measuring Stick (inverted)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(inverted_same_denom)))
inverted_same_denom(frac(N1,D1)-frac(N2,D2), Winner) :-
    D1 =:= D2,
    (N1 < N2 -> Winner = frac(N1,D1) ; Winner = frac(N2,D2)).

test_harness:arith_misconception(db_row(37907), fraction, inverted_same_denom_order,
    misconceptions_fraction_batch_1:inverted_same_denom,
    frac(9,13)-frac(4,13),
    frac(9,13)).

% === row 37919: reference whole size ignored ===
test_harness:arith_misconception(db_row(37919), fraction, too_vague,
    skip, none, none).

% === row 37963: divide by 2 vs by 1/2 confusion ===
test_harness:arith_misconception(db_row(37963), fraction, too_vague,
    skip, none, none).

% === row 38013: treat numerals as whole numbers (generic) ===
test_harness:arith_misconception(db_row(38013), fraction, too_vague,
    skip, none, none).

% === row 38111: division is commutative ===
% Task: 5 / 15
% Correct: frac(1,3) (i.e. 5/15)
% Error: swaps to 15/5 = 3
% SCHEMA: Arithmetic is Motion Along a Path (ignoring direction)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(commute_division)))
commute_division(Dividend-Divisor, Quotient) :-
    Quotient is Divisor div Dividend.

test_harness:arith_misconception(db_row(38111), fraction, commute_division,
    misconceptions_fraction_batch_1:commute_division,
    5-15,
    frac(1,3)).

% === row 38132: visual surface mapping ===
test_harness:arith_misconception(db_row(38132), fraction, too_vague,
    skip, none, none).

% === row 38213: fraction from pieces ignoring whole-value ===
% Task: a red rod where 4 reds make a train that equals 2 wholes
%   represented as pair PieceCount-WholeValue (4-2). A single red rod
%   represents 2/4 = 1/2 of the whole.
% Correct: frac(1,2)
% Error: names it 1/PieceCount -> frac(1,4)
% SCHEMA: Arithmetic is Object Collection (ignores whole value)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(ignore_whole_value)))
name_by_piece_count(PieceCount-_WholeValue, frac(1, PieceCount)).

test_harness:arith_misconception(db_row(38213), fraction, name_ignores_whole_value,
    misconceptions_fraction_batch_1:name_by_piece_count,
    4-2,
    frac(1,2)).

% === row 38237: PST hesitation on equivalent-numerator ===
test_harness:arith_misconception(db_row(38237), fraction, too_vague,
    skip, none, none).

% === row 38258: PST drawing measurement division ===
test_harness:arith_misconception(db_row(38258), fraction, too_vague,
    skip, none, none).

% === row 38281: continuous equipartition ===
test_harness:arith_misconception(db_row(38281), fraction, too_vague,
    skip, none, none).

% === row 38313: bigger denominator = bigger fraction (general) ===
% Task: compare 5/7 and 1/7, return larger
% Correct: frac(5,7)
% Error: student's rule is "bigger denominator means bigger fraction", but
%   in this example denominators are equal — with equal denominators they
%   default to "bigger numerator = bigger fraction" which happens to match.
% Since the theorem-in-action as stated centers on denominator, encode as
%   "pick the one with the larger denominator" for a task with differing
%   denominators. Using compare(2/5, 1/10): correct frac(2,5), student
%   says frac(1,10) because 10 > 5.
% SCHEMA: whole-number dominance
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(denom_size_theorem)))
denom_bigger_is_bigger(frac(N1,D1)-frac(N2,D2), Winner) :-
    (D1 > D2 -> Winner = frac(N1,D1) ; Winner = frac(N2,D2)).

test_harness:arith_misconception(db_row(38313), fraction, bigger_denom_bigger_frac,
    misconceptions_fraction_batch_1:denom_bigger_is_bigger,
    frac(2,5)-frac(1,10),
    frac(2,5)).

% === row 38345: iterating composite unit instead of unit ===
% Task: given 1 rod = 1/7, show 2/7
% Correct: two 1-rods (length 2 in rod-units)
% Error: iterated 2-rod seven times (length 14 in rod-units)
% Encode as: input UnitFraction-TargetNumerator ; output length-in-rods.
% SCHEMA: Arithmetic is Motion Along a Path (misapplied iterator)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(iterate_composite)))
iterate_composite_unit(frac(1,D)-Target, Length) :-
    Length is D * Target.

test_harness:arith_misconception(db_row(38345), fraction, iterate_composite_not_unit,
    misconceptions_fraction_batch_1:iterate_composite_unit,
    frac(1,7)-2,
    2).

% === row 38374: 1/3 > 1/2 because 3 > 2 ===
% Task: compare 1/2 and 1/3, return larger
% Correct: frac(1,2)
% Error: picks larger-denom -> frac(1,3)
% SCHEMA: whole-number dominance
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(denom_size_magnitude)))
denom_size_magnitude(frac(N1,D1)-frac(N2,D2), Winner) :-
    (D1 > D2 -> Winner = frac(N1,D1) ; Winner = frac(N2,D2)).

test_harness:arith_misconception(db_row(38374), fraction, unit_fraction_denom_dominance,
    misconceptions_fraction_batch_1:denom_size_magnitude,
    frac(1,2)-frac(1,3),
    frac(1,2)).

% === row 38403: iterate instead of partition for inverse ===
% Task: find the original stick when the given stick is 5 times as long
% Correct: Given / 5
% Error: iterates -> Given * 5
% Represent given stick length as numeric length paired with multiplier.
% SCHEMA: Arithmetic is Motion Along a Path (wrong inverse)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(iterate_for_split)))
iterate_for_inverse(Given-Times, Result) :-
    Result is Given * Times.

test_harness:arith_misconception(db_row(38403), fraction, iterate_when_split_needed,
    misconceptions_fraction_batch_1:iterate_for_inverse,
    10-5,
    2).

% === row 38424: fraction-of as subtraction ===
% Task: 1/3 of 2/3
% Correct: frac(2,9)
% Error: treats 'of' as subtraction -> 2/3 - 1/3 = 1/3
% SCHEMA: Arithmetic is Object Collection (wrong operator)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(of_as_subtract)))
of_as_subtract(frac(N1,D1)-frac(N2,D2), frac(NDiff, D1)) :-
    D1 =:= D2,
    NDiff is N2 - N1.

test_harness:arith_misconception(db_row(38424), fraction, of_as_subtraction,
    misconceptions_fraction_batch_1:of_as_subtract,
    frac(1,3)-frac(2,3),
    frac(2,9)).

% === row 38451: drew whole instead of 1/7 ===
test_harness:arith_misconception(db_row(38451), fraction, too_vague,
    skip, none, none).

% === row 38478: cut-off-excess partitioning ===
test_harness:arith_misconception(db_row(38478), fraction, too_vague,
    skip, none, none).

% === row 38554: PST tracking whole values ===
test_harness:arith_misconception(db_row(38554), fraction, too_vague,
    skip, none, none).

% === row 38571: MC1 adds by counting parts ===
% Task: 1/2 + 1/4
% Correct: frac(3,4)
% Error: numerator-of-result is num_parts from each denominator sum:
%   1 'part' + 4 'parts' = 5 parts -> claimed 'one fifth' = frac(1,5).
% SCHEMA: Arithmetic is Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(mc1_part_count)))
mc1_part_count(frac(N1,_D1)-frac(_N2,D2), frac(1, Parts)) :-
    Parts is N1 + D2.

test_harness:arith_misconception(db_row(38571), fraction, mc1_add_by_part_count,
    misconceptions_fraction_batch_1:mc1_part_count,
    frac(1,2)-frac(1,4),
    frac(3,4)).

% === row 38645: indivisible whole for remainders ===
test_harness:arith_misconception(db_row(38645), fraction, too_vague,
    skip, none, none).

% === row 38661: distributive partitioning failure ===
test_harness:arith_misconception(db_row(38661), fraction, too_vague,
    skip, none, none).

% === row 38668: double-count overlap in fraction addition ===
% Task: 1/4 + 1/3 using common partition of 12
% Correct: frac(7,12)
% Error: double counts overlap -> frac(8,12)
% Specifically: 3 (for 1/4) + 4 (for 1/3) + 1 (overlap) = 8 twelfths.
% SCHEMA: Arithmetic is Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(double_count_overlap)))
double_count_overlap(frac(N1,D1)-frac(N2,D2), frac(NOut, DOut)) :-
    DOut is D1 * D2,
    A is N1 * D2,
    B is N2 * D1,
    NOut is A + B + 1.

test_harness:arith_misconception(db_row(38668), fraction, overlap_double_counted,
    misconceptions_fraction_batch_1:double_count_overlap,
    frac(1,4)-frac(1,3),
    frac(7,12)).

% === row 38703: can't name equivalent fraction ===
test_harness:arith_misconception(db_row(38703), fraction, too_vague,
    skip, none, none).

% === row 38733: divide by numerator (whole-number rule) ===
% Task: 2/3 of 6
% Correct: 4
% Error: "twos into the number" -> 6 / 2 = 3
% SCHEMA: Arithmetic is Motion Along a Path (wrong divisor)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(divide_by_numerator)))
divide_by_numerator(frac(N,_D)-Whole, Result) :-
    Result is Whole div N.

test_harness:arith_misconception(db_row(38733), fraction, divide_by_numerator,
    misconceptions_fraction_batch_1:divide_by_numerator,
    frac(2,3)-6,
    4).

% === row 38806: confusion of fraction with area-count ===
% Task: area model of a rectangle with Total squares and Marked squares.
%   Represent input as Total-Marked (e.g. 12-4 means 4 of 12 squares shaded).
% Correct: frac(4,12)
% Error: writes frac(1, Marked) -> frac(1,4)
% SCHEMA: symbol confusion
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(denom_is_marked_count)))
denom_is_marked(_Total-Marked, frac(1, Marked)).

test_harness:arith_misconception(db_row(38806), fraction, denom_equals_marked_count,
    misconceptions_fraction_batch_1:denom_is_marked,
    12-4,
    frac(4,12)).

% === row 38841: no-no congruency reasoning ===
test_harness:arith_misconception(db_row(38841), fraction, too_vague,
    skip, none, none).

% === row 38869: PST believes add/mult need different pictures ===
test_harness:arith_misconception(db_row(38869), fraction, too_vague,
    skip, none, none).

% === row 38961: cardinal-number overemphasis ===
test_harness:arith_misconception(db_row(38961), fraction, too_vague,
    skip, none, none).

% === row 38979: crossing out numeral to show half ===
test_harness:arith_misconception(db_row(38979), fraction, too_vague,
    skip, none, none).

% === row 39009: unequal visual partition ===
test_harness:arith_misconception(db_row(39009), fraction, too_vague,
    skip, none, none).

% === row 39062: decimal 0.5 generalized across bases ===
% Task: write 1/2 in base 3 and interpret
% Correct: in base 3, 1/2 is not terminating; commonly represented 0.111...
%   For this encoding we take the Expected as frac(1,2).
% Error: writes 0.5 and interprets as 5 * 1/3 = frac(5,3).
% Represent input as atom base_half_in(3); output as fraction.
% SCHEMA: symbol overgeneralization
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(decimal_overgen)))
decimal_overgen_base(base_half_in(Base), frac(5, Base)).

test_harness:arith_misconception(db_row(39062), fraction, decimal_point_five_across_bases,
    misconceptions_fraction_batch_1:decimal_overgen_base,
    base_half_in(3),
    frac(1,2)).

% === row 39129: conservation of value under splitting ===
test_harness:arith_misconception(db_row(39129), fraction, too_vague,
    skip, none, none).

% === row 39151: procedural rule from analogy ===
test_harness:arith_misconception(db_row(39151), fraction, too_vague,
    skip, none, none).

% === row 39180: mult rule unlinked from diagram ===
test_harness:arith_misconception(db_row(39180), fraction, too_vague,
    skip, none, none).

% === row 39267: number line after-the-fact ===
test_harness:arith_misconception(db_row(39267), fraction, too_vague,
    skip, none, none).

% === row 39339: exact algorithm when estimating ===
test_harness:arith_misconception(db_row(39339), fraction, too_vague,
    skip, none, none).

% === row 39368: counting tick marks on number line ===
test_harness:arith_misconception(db_row(39368), fraction, too_vague,
    skip, none, none).

% === row 39465: fraction as decimal on number line ===
% Task: place 3/5 on a number line from 0 to 5
% Correct: position 3/5 = 0.6
% Error: places at 3.5 (numerator.denominator as decimal) or at 3 and 3/5.
% Encode the '3.5' variant: treats frac(N,D) positionally as N + 1/2.
% Input: frac on line_0_to_5 pair; output: position as float.
% SCHEMA: symbol confusion (fraction read as decimal)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(fraction_as_decimal_point_five)))
frac_as_dot_five(frac(N,_D), Pos) :-
    Pos is N + 0.5.

test_harness:arith_misconception(db_row(39465), fraction, place_frac_as_decimal_point_five,
    misconceptions_fraction_batch_1:frac_as_dot_five,
    frac(3,5),
    0.6).

% === row 39554: componentwise addition (generic) ===
% Task: add 1/3 + 1/4 componentwise
% Correct: frac(7,12)
% Error: frac(2,7)
% SCHEMA: Arithmetic is Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(componentwise_add)))
componentwise_add(frac(N1,D1)-frac(N2,D2), frac(NSum, DSum)) :-
    NSum is N1 + N2,
    DSum is D1 + D2.

test_harness:arith_misconception(db_row(39554), fraction, componentwise_add_fractions,
    misconceptions_fraction_batch_1:componentwise_add,
    frac(1,3)-frac(1,4),
    frac(7,12)).

% === row 39595: part as physical piece ===
test_harness:arith_misconception(db_row(39595), fraction, too_vague,
    skip, none, none).

% === row 39616: cognitive block ===
test_harness:arith_misconception(db_row(39616), fraction, too_vague,
    skip, none, none).

% === row 39649: rote procedural application ===
test_harness:arith_misconception(db_row(39649), fraction, too_vague,
    skip, none, none).

% === row 39671: transfer proportional relation to wrong whole ===
test_harness:arith_misconception(db_row(39671), fraction, too_vague,
    skip, none, none).

% === row 39700: number line vs ribbon ===
test_harness:arith_misconception(db_row(39700), fraction, too_vague,
    skip, none, none).

% === row 39736: common numerator, larger denom = larger ===
% Task: compare 3/11 and 3/17, return larger
% Correct: frac(3,11)
% Error: picks larger-denom -> frac(3,17)
% SCHEMA: whole-number dominance
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(denom_size_common_num)))
common_num_denom_dominant(frac(N1,D1)-frac(N2,D2), Winner) :-
    N1 =:= N2,
    (D1 > D2 -> Winner = frac(N1,D1) ; Winner = frac(N2,D2)).

test_harness:arith_misconception(db_row(39736), fraction, common_num_denom_dominates,
    misconceptions_fraction_batch_1:common_num_denom_dominant,
    frac(3,11)-frac(3,17),
    frac(3,11)).

% === row 39770: invert-and-multiply without meaning ===
test_harness:arith_misconception(db_row(39770), fraction, too_vague,
    skip, none, none).

% === row 39795: scaling changes value ===
% Task: scale 1/2 by factor 2 (multiply num & denom by 2)
% Correct: frac(2,4) (equivalent, same value as 1/2)
% Error: claims the fraction is doubled in value -> frac(2,2) (= 1).
% Input: frac-Factor; Expected: equivalent frac(2,4).
% Encode student's claim: doubles numerator, keeps denominator the same
%   (so value equals Factor * original).
% SCHEMA: Arithmetic is Object Collection (over-scaling)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(scaling_changes_value)))
scale_value_numerator_only(frac(N,D)-Factor, frac(NOut, D)) :-
    NOut is N * Factor.

test_harness:arith_misconception(db_row(39795), fraction, scale_as_doubling_value,
    misconceptions_fraction_batch_1:scale_value_numerator_only,
    frac(1,2)-2,
    frac(2,4)).

% === row 39816: daily-life logic error ===
test_harness:arith_misconception(db_row(39816), fraction, too_vague,
    skip, none, none).

% === row 39823: multiplying fractions decreases ===
test_harness:arith_misconception(db_row(39823), fraction, too_vague,
    skip, none, none).

% === row 39888: mixed fraction area model misread ===
test_harness:arith_misconception(db_row(39888), fraction, too_vague,
    skip, none, none).

% === row 39899: division becomes multiplication ===
% Task: 125 / (1/5)
% Correct: 625
% Error: computes 1/5 * 125 = 25
% SCHEMA: operation substitution
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(divide_as_multiply)))
divide_as_multiply(Whole-frac(N,D), Result) :-
    Result is (Whole * N) div D.

test_harness:arith_misconception(db_row(39899), fraction, divide_by_unit_fraction_as_multiply,
    misconceptions_fraction_batch_1:divide_as_multiply,
    125-frac(1,5),
    625).

% === row 40005: remainder read against wrong unit ===
% Task: 10 / (3/4)
% Correct: frac(40,3) (or mixed 13 1/3)
% Error: says 13 1/4 — treats the leftover 1/4 yard as being 1/4 of the
%   whole, not 1/3 of the divisor.
% Encode: output is mixed(Quotient, frac(Leftover, OriginalDenom)) where
%   Leftover is the fabric remainder expressed in original units.
% SCHEMA: referent confusion on remainder
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(remainder_wrong_unit)))
remainder_wrong_unit(Whole-frac(N,D), mixed(Q, frac(Rem, D))) :-
    Total is Whole * D,
    Q is Total div N,
    Rem is Total mod N.

test_harness:arith_misconception(db_row(40005), fraction, remainder_against_original_unit,
    misconceptions_fraction_batch_1:remainder_wrong_unit,
    10-frac(3,4),
    mixed(13, frac(1,3))).

% === row 40075: PSTs keep common denom in multiplication ===
% Task: 2/15 * 7/15
% Correct: frac(14,225)
% Error: multiplies numerators, keeps denom -> frac(14,15)
% SCHEMA: Arithmetic is Object Collection (misapplied common denom)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(common_denom_in_mult)))
mult_keep_common_denom(frac(N1,D1)-frac(N2,D2), frac(NProd, D1)) :-
    D1 =:= D2,
    NProd is N1 * N2.

test_harness:arith_misconception(db_row(40075), fraction, mult_keep_common_denom,
    misconceptions_fraction_batch_1:mult_keep_common_denom,
    frac(2,15)-frac(7,15),
    frac(14,225)).

% === row 40099: unequal distribution ===
test_harness:arith_misconception(db_row(40099), fraction, too_vague,
    skip, none, none).

% === row 40116: PST division drawings ===
test_harness:arith_misconception(db_row(40116), fraction, too_vague,
    skip, none, none).

% === row 40126: benchmark strategy reversed for >1 ===
% Task: compare 8/9 and 12/13 via benchmark 1
% Correct: frac(12,13) larger (since 12/13 ≈ 0.923 > 8/9 ≈ 0.889)
% Error: since distance to 1 is 1/9 for 8/9 and 1/13 for 12/13 and 1/9>1/13,
%   student concludes 8/9 is larger — inverted because BOTH are under 1.
% Wait — both are under 1 here; the PST error in the source pertains to
%   fractions greater than benchmark. For the under-1 case encoded here,
%   the student rule 'closer to 1 means smaller distance means larger'
%   happens to be valid. We instead encode the error as 'bigger distance
%   means bigger fraction' — student picks the one with bigger distance
%   from benchmark 1 as larger. That matches the PST reasoning in-text:
%   they said 8/9 > 12/13 because '1/9 > 1/13' (bigger distance -> bigger).
% SCHEMA: benchmark polarity confusion
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(benchmark_distance_flipped)))
benchmark_distance_flipped(frac(N1,D1)-frac(N2,D2), Winner) :-
    Dist1 is D1 - N1,   % distance times D1
    Dist2 is D2 - N2,   % distance times D2
    Cross1 is Dist1 * D2,
    Cross2 is Dist2 * D1,
    (Cross1 > Cross2 -> Winner = frac(N1,D1) ; Winner = frac(N2,D2)).

test_harness:arith_misconception(db_row(40126), fraction, benchmark_distance_flipped,
    misconceptions_fraction_batch_1:benchmark_distance_flipped,
    frac(8,9)-frac(12,13),
    frac(12,13)).

% === row 40144: 1/3 + 1/2 = 2/5 ===
% Task: 1/3 + 1/2
% Correct: frac(5,6)
% Error: componentwise -> frac(2,5)
% SCHEMA: Arithmetic is Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(componentwise_add)))
componentwise_add_unlike(frac(N1,D1)-frac(N2,D2), frac(NSum, DSum)) :-
    NSum is N1 + N2,
    DSum is D1 + D2.

test_harness:arith_misconception(db_row(40144), fraction, componentwise_add_unlike,
    misconceptions_fraction_batch_1:componentwise_add_unlike,
    frac(1,3)-frac(1,2),
    frac(5,6)).

% === row 40165: fraction between by componentwise-between ===
test_harness:arith_misconception(db_row(40165), fraction, too_vague,
    skip, none, none).

% === row 40193: referent unit ambiguity ===
test_harness:arith_misconception(db_row(40193), fraction, too_vague,
    skip, none, none).

% === row 40200: more pieces shaded = larger fraction ===
% Task: compare 7/8 and 6/7, return larger
% Correct: frac(7,8) (49/56 vs 48/56)
% Error: picks the one with more shaded pieces (numerator) -> frac(7,8)
% Note: in this example the student's rule happens to give the correct
%   answer. Encode the rule faithfully; classifier will mark as
%   well_formed for this particular input (a dedup flag by design).
% SCHEMA: Arithmetic is Object Collection (raw count)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(more_pieces_wins)))
more_pieces_wins(frac(N1,D1)-frac(N2,D2), Winner) :-
    (N1 > N2 -> Winner = frac(N1,D1) ; Winner = frac(N2,D2)).

test_harness:arith_misconception(db_row(40200), fraction, more_pieces_wins,
    misconceptions_fraction_batch_1:more_pieces_wins,
    frac(7,8)-frac(6,7),
    frac(7,8)).

% === row 40233: word problem language confusion ===
test_harness:arith_misconception(db_row(40233), fraction, too_vague,
    skip, none, none).

% === row 40264: common numerator, larger denom bigger (PST) ===
% Task: compare 6/14 and 6/15, return larger
% Correct: frac(6,14)
% Error: picks larger-denom -> frac(6,15)
% SCHEMA: whole-number dominance
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(denom_size_pst)))
common_num_pst_denom(frac(N1,D1)-frac(N2,D2), Winner) :-
    N1 =:= N2,
    (D1 > D2 -> Winner = frac(N1,D1) ; Winner = frac(N2,D2)).

test_harness:arith_misconception(db_row(40264), fraction, common_num_pst_denom_dominates,
    misconceptions_fraction_batch_1:common_num_pst_denom,
    frac(6,14)-frac(6,15),
    frac(6,14)).

% === row 40356: arbitrary mapping into numerator/denominator ===
test_harness:arith_misconception(db_row(40356), fraction, too_vague,
    skip, none, none).

% === row 40378: subtraction to non-zero ===
% Task: 4/5 - 4/5
% Correct: frac(0,5)
% Error: either returns 5 (subtracting denom from denom of answer) or
%   returns frac(1,5) (confused on zero numerator). Encode the frac(1,5)
%   variant: treats 0 in numerator as 1 because 'fractions need a top'.
% SCHEMA: Arithmetic is Object Collection (zero avoidance)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(zero_numerator_bumped)))
zero_num_bumped(frac(N1,D1)-frac(N2,D2), frac(NOut, D1)) :-
    D1 =:= D2,
    Raw is N1 - N2,
    (Raw =:= 0 -> NOut = 1 ; NOut = Raw).

test_harness:arith_misconception(db_row(40378), fraction, zero_numerator_bumped,
    misconceptions_fraction_batch_1:zero_num_bumped,
    frac(4,5)-frac(4,5),
    frac(0,5)).

% === row 40409: parts priced don't sum to 1 ===
test_harness:arith_misconception(db_row(40409), fraction, too_vague,
    skip, none, none).

% === row 40451: gap thinking ===
% Task: compare 3/5 and 5/8, return larger
% Correct: frac(5,8) (25/40 vs 24/40)
% Error: picks the one with smaller |D-N| -> frac(3,5) (gap 2 < gap 3)
% SCHEMA: Arithmetic is Object Collection (gap heuristic)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(gap_thinking)))
gap_thinking(frac(N1,D1)-frac(N2,D2), Winner) :-
    G1 is D1 - N1,
    G2 is D2 - N2,
    (G1 < G2 -> Winner = frac(N1,D1) ; Winner = frac(N2,D2)).

test_harness:arith_misconception(db_row(40451), fraction, smaller_gap_larger_fraction,
    misconceptions_fraction_batch_1:gap_thinking,
    frac(3,5)-frac(5,8),
    frac(5,8)).

% === row 40465: one-for-one manipulative exchange ===
% Task: replace 1/2 with a single equivalent piece
% Correct: frac(8, 16) (8 sixteenths) or any equivalent
% Error: replaces with 1/16 (a single piece regardless of value)
% Input: frac-TargetDenom; Expected: equivalent fraction at TargetDenom.
% SCHEMA: manipulative equivalence by count, not value
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(one_for_one_exchange)))
one_for_one_exchange(frac(_N,_D)-TargetD, frac(1, TargetD)).

test_harness:arith_misconception(db_row(40465), fraction, exchange_one_for_one,
    misconceptions_fraction_batch_1:one_for_one_exchange,
    frac(1,2)-16,
    frac(8,16)).

% === row 40491: pairs that sum to 5 given as pairs summing to 1 ===
% Task: find pairs of fractions that sum to a target whole number Target
% Correct: for Target=5, any pair like frac(5,1)+frac(0,1) or
%   frac(7,2)+frac(3,2); we take frac(5,1) paired with frac(0,1).
% Error: defaults to part-whole and provides a pair summing to 1, e.g.
%   frac(2,5)+frac(3,5) for Target=5.
% SCHEMA: part-whole default overrides target
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(part_whole_default_to_one)))
part_whole_default_pair(Target, frac(2, Target)-frac(3, Target)) :-
    Target > 0.

test_harness:arith_misconception(db_row(40491), fraction, part_whole_default_pair_sums_one,
    misconceptions_fraction_batch_1:part_whole_default_pair,
    5,
    frac(5,1)-frac(0,1)).

% === row 40545: circle diagram taken literally ===
test_harness:arith_misconception(db_row(40545), fraction, too_vague,
    skip, none, none).

% === row 40618: equal-sharing seen as division not fraction ===
test_harness:arith_misconception(db_row(40618), fraction, too_vague,
    skip, none, none).

% === row 40674: compensation logic failure (1/6 > 1/3) ===
% Task: compare 1/3 and 1/6, return larger
% Correct: frac(1,3)
% Error: picks larger-denom -> frac(1,6)
% SCHEMA: compensation logic failure
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(compensation_failure)))
compensation_failure(frac(N1,D1)-frac(N2,D2), Winner) :-
    (D1 > D2 -> Winner = frac(N1,D1) ; Winner = frac(N2,D2)).

test_harness:arith_misconception(db_row(40674), fraction, compensation_logic_failure,
    misconceptions_fraction_batch_1:compensation_failure,
    frac(1,3)-frac(1,6),
    frac(1,3)).

% === row 37454: n-out-of-m loses fixed whole ===
% Task: represent mixed number 1 4/10 with fraction strips.
% Correct: one whole strip plus 4/10 of a same-sized strip.
% Error: treats the fractional strip as a candy set with 4 disjoint pieces eaten.
% SCHEMA: Container - whole-strip referent not held fixed across strips
% GROUNDED: TODO - preserve same-length whole while partitioning tenths.
% CONNECTS TO: s(comp_nec(unlicensed(n_out_of_m_fixed_whole)))
n_out_of_m_fixed_whole(mixed_strip(Whole, frac(N,D)),
    separate_sets(whole_strips(Whole), eaten_pieces(N,D))).

test_harness:arith_misconception(db_row(37454), fraction, n_out_of_m_fixed_whole,
    misconceptions_fraction_batch_1:n_out_of_m_fixed_whole,
    mixed_strip(1, frac(4,10)),
    fixed_whole_strips(whole_strips(1), shaded_parts(4,10))).

% === row 37455: benchmark treated as estimate ===
% Task: place 1 and 12/12 on a number line with fixed benchmarks.
% Correct: 1 and 12/12 occupy the same location.
% Error: treats 1 as an estimated benchmark, then locates 12/12 by counting ticks.
% SCHEMA: Measuring Stick - iterated tick count overrides fixed unit interval
% GROUNDED: TODO - iterate equal subintervals from a fixed benchmark.
% CONNECTS TO: s(comp_nec(unlicensed(benchmark_as_estimate)))
benchmark_as_estimate(frac(D,D)-estimate(OneAt),
    separate_locations(one(OneAt), frac(D,D,CountedAt))) :-
    CountedAt is D.

test_harness:arith_misconception(db_row(37455), fraction, benchmark_as_estimate,
    misconceptions_fraction_batch_1:benchmark_as_estimate,
    frac(12,12)-estimate(1),
    same_location(one, frac(12,12), 1)).

% === row 37457: length named by grouped mini-parts ===
% Task: name the length of 35 mini-parts when each unit bar has 3 mini-parts.
% Correct: 35/3 = 11 and 2/3 unit bars.
% Error: names the length as 35/7 after grouping mini-parts into 7-mini-part bars.
% SCHEMA: Measuring Stick - intermediate group size becomes the unit denominator
% GROUNDED: TODO - keep unit-bar partition count as the denominator.
% CONNECTS TO: s(comp_nec(unlicensed(group_size_as_unit_denominator)))
name_length_by_group_size(length_name(mini_parts(Total), _UnitParts, group_size(Group)),
    frac(Total,Group)).

test_harness:arith_misconception(db_row(37457), fraction, name_length_by_group_size,
    misconceptions_fraction_batch_1:name_length_by_group_size,
    length_name(mini_parts(35), unit_parts(3), group_size(7)),
    frac(35,3)).
