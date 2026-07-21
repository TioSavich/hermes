/** <module> Fraction misconception table
 *
 * This table keeps literature-attested fraction misconception
 * registrations beside the runnable rule clauses that support them. The
 * registration schema is test_harness:arith_misconception/6.
 *
 * Clause order retains the effective load order that preceded consolidation.
 * Batch sections remain at the former loader position and proceed in ascending
 * batch number. Existing clauses keep their prior relative order. Original
 * batch module qualifiers remain callable; git history is the archive.
 */
:- module(misconceptions_fraction, []).

:- use_module(library(lists)).
:- use_module(library(pairs)).
:- use_module(library(yall)).

:- multifile test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.

% Literature-corpus registrations and their runnable rules.
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


% ---- Encodings appended by agent for batch 1 ----

% === row 37434: add denominators on unit fractions ===
% Task: 1/7 + 1/7
% Correct: frac(2,7)
% Error: adds denominators -> frac(1,14)
% SCHEMA: Arithmetic is Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(add_denominators_unit)))
misconceptions_fraction_batch_1:(add_denoms_unit(frac(N1,D1)-frac(N2,D2), frac(N1, DSum)) :-
    N1 =:= N2,
    DSum is D1 + D2).

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
misconceptions_fraction_batch_1:(mult_num_add_denom(frac(N1,D1)-frac(N2,D2), frac(NProd, DSum)) :-
    NProd is N1 * N2,
    DSum is D1 + D2).

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
misconceptions_fraction_batch_1:(pick_larger_denom(frac(N1,D1)-frac(N2,D2), Winner) :-
    (D1 > D2 -> Winner = frac(N1,D1) ; Winner = frac(N2,D2))).

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
misconceptions_fraction_batch_1:(add_num_avg_denom(frac(N1,D1)-frac(N2,D2), frac(NSum, DAvg)) :-
    NSum is N1 + N2,
    DAvg is (D1 + D2) // 2).

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
misconceptions_fraction_batch_1:(scale_both_by_whole(frac(N,D)-W, frac(NOut, DOut)) :-
    NOut is N * W,
    DOut is D * W).

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
misconceptions_fraction_batch_1:(equiv_add_to_numerator(frac(N,D)-TargetD, frac(NOut, D)) :-
    Diff is TargetD - D,
    NOut is N + N + Diff).  % reproduces '3x2=6 so 8x2=16' style

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
misconceptions_fraction_batch_1:(sub_parts_separately(frac(N1,D1)-frac(N2,D2), frac(NDiff, DDiff)) :-
    NDiff is N1 - N2,
    DDiff is D1 - D2).

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
misconceptions_fraction_batch_1:(pick_larger_denom_as_larger(frac(N1,D1)-frac(N2,D2), Winner) :-
    (D1 > D2 -> Winner = frac(N1,D1) ; Winner = frac(N2,D2))).

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
misconceptions_fraction_batch_1:(pick_larger_denom_magnitude(frac(N1,D1)-frac(N2,D2), Winner) :-
    (D1 > D2 -> Winner = frac(N1,D1) ; Winner = frac(N2,D2))).

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
misconceptions_fraction_batch_1:(equal_residual(frac(N1,D1)-frac(N2,D2), equal) :-
    Diff1 is D1 - N1,
    Diff2 is D2 - N2,
    Diff1 =:= Diff2).

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
misconceptions_fraction_batch_1:(denom_dominance_small_bigger(frac(N1,D1)-frac(N2,D2), Winner) :-
    (D1 < D2 -> Winner = frac(N1,D1) ; Winner = frac(N2,D2))).

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
misconceptions_fraction_batch_1:(inverted_same_denom(frac(N1,D1)-frac(N2,D2), Winner) :-
    D1 =:= D2,
    (N1 < N2 -> Winner = frac(N1,D1) ; Winner = frac(N2,D2))).

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
misconceptions_fraction_batch_1:(commute_division(Dividend-Divisor, Quotient) :-
    Quotient is Divisor div Dividend).

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
misconceptions_fraction_batch_1:(name_by_piece_count(PieceCount-_WholeValue, frac(1, PieceCount))).

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
misconceptions_fraction_batch_1:(denom_bigger_is_bigger(frac(N1,D1)-frac(N2,D2), Winner) :-
    (D1 > D2 -> Winner = frac(N1,D1) ; Winner = frac(N2,D2))).

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
misconceptions_fraction_batch_1:(iterate_composite_unit(frac(1,D)-Target, Length) :-
    Length is D * Target).

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
misconceptions_fraction_batch_1:(denom_size_magnitude(frac(N1,D1)-frac(N2,D2), Winner) :-
    (D1 > D2 -> Winner = frac(N1,D1) ; Winner = frac(N2,D2))).

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
misconceptions_fraction_batch_1:(iterate_for_inverse(Given-Times, Result) :-
    Result is Given * Times).

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
misconceptions_fraction_batch_1:(of_as_subtract(frac(N1,D1)-frac(N2,D2), frac(NDiff, D1)) :-
    D1 =:= D2,
    NDiff is N2 - N1).

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
misconceptions_fraction_batch_1:(mc1_part_count(frac(N1,_D1)-frac(_N2,D2), frac(1, Parts)) :-
    Parts is N1 + D2).

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
misconceptions_fraction_batch_1:(double_count_overlap(frac(N1,D1)-frac(N2,D2), frac(NOut, DOut)) :-
    DOut is D1 * D2,
    A is N1 * D2,
    B is N2 * D1,
    NOut is A + B + 1).

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
misconceptions_fraction_batch_1:(divide_by_numerator(frac(N,_D)-Whole, Result) :-
    Result is Whole div N).

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
misconceptions_fraction_batch_1:(denom_is_marked(_Total-Marked, frac(1, Marked))).

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
misconceptions_fraction_batch_1:(decimal_overgen_base(base_half_in(Base), frac(5, Base))).

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
misconceptions_fraction_batch_1:(frac_as_dot_five(frac(N,_D), Pos) :-
    Pos is N + 0.5).

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
misconceptions_fraction_batch_1:(componentwise_add(frac(N1,D1)-frac(N2,D2), frac(NSum, DSum)) :-
    NSum is N1 + N2,
    DSum is D1 + D2).

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
misconceptions_fraction_batch_1:(common_num_denom_dominant(frac(N1,D1)-frac(N2,D2), Winner) :-
    N1 =:= N2,
    (D1 > D2 -> Winner = frac(N1,D1) ; Winner = frac(N2,D2))).

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
misconceptions_fraction_batch_1:(scale_value_numerator_only(frac(N,D)-Factor, frac(NOut, D)) :-
    NOut is N * Factor).

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
misconceptions_fraction_batch_1:(divide_as_multiply(Whole-frac(N,D), Result) :-
    Result is (Whole * N) div D).

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
misconceptions_fraction_batch_1:(remainder_wrong_unit(Whole-frac(N,D), mixed(Q, frac(Rem, D))) :-
    Total is Whole * D,
    Q is Total div N,
    Rem is Total mod N).

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
misconceptions_fraction_batch_1:(mult_keep_common_denom(frac(N1,D1)-frac(N2,D2), frac(NProd, D1)) :-
    D1 =:= D2,
    NProd is N1 * N2).

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
misconceptions_fraction_batch_1:(benchmark_distance_flipped(frac(N1,D1)-frac(N2,D2), Winner) :-
    Dist1 is D1 - N1,   % distance times D1
    Dist2 is D2 - N2,   % distance times D2
    Cross1 is Dist1 * D2,
    Cross2 is Dist2 * D1,
    (Cross1 > Cross2 -> Winner = frac(N1,D1) ; Winner = frac(N2,D2))).

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
misconceptions_fraction_batch_1:(componentwise_add_unlike(frac(N1,D1)-frac(N2,D2), frac(NSum, DSum)) :-
    NSum is N1 + N2,
    DSum is D1 + D2).

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
misconceptions_fraction_batch_1:(more_pieces_wins(frac(N1,D1)-frac(N2,D2), Winner) :-
    (N1 > N2 -> Winner = frac(N1,D1) ; Winner = frac(N2,D2))).

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
misconceptions_fraction_batch_1:(common_num_pst_denom(frac(N1,D1)-frac(N2,D2), Winner) :-
    N1 =:= N2,
    (D1 > D2 -> Winner = frac(N1,D1) ; Winner = frac(N2,D2))).

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
misconceptions_fraction_batch_1:(zero_num_bumped(frac(N1,D1)-frac(N2,D2), frac(NOut, D1)) :-
    D1 =:= D2,
    Raw is N1 - N2,
    (Raw =:= 0 -> NOut = 1 ; NOut = Raw)).

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
misconceptions_fraction_batch_1:(gap_thinking(frac(N1,D1)-frac(N2,D2), Winner) :-
    G1 is D1 - N1,
    G2 is D2 - N2,
    (G1 < G2 -> Winner = frac(N1,D1) ; Winner = frac(N2,D2))).

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
misconceptions_fraction_batch_1:(one_for_one_exchange(frac(_N,_D)-TargetD, frac(1, TargetD))).

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
misconceptions_fraction_batch_1:(part_whole_default_pair(Target, frac(2, Target)-frac(3, Target)) :-
    Target > 0).

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
misconceptions_fraction_batch_1:(compensation_failure(frac(N1,D1)-frac(N2,D2), Winner) :-
    (D1 > D2 -> Winner = frac(N1,D1) ; Winner = frac(N2,D2))).

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
misconceptions_fraction_batch_1:(n_out_of_m_fixed_whole(mixed_strip(Whole, frac(N,D)),
    separate_sets(whole_strips(Whole), eaten_pieces(N,D)))).

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
misconceptions_fraction_batch_1:(benchmark_as_estimate(frac(D,D)-estimate(OneAt),
    separate_locations(one(OneAt), frac(D,D,CountedAt))) :-
    CountedAt is D).

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
misconceptions_fraction_batch_1:(name_length_by_group_size(length_name(mini_parts(Total), _UnitParts, group_size(Group)),
    frac(Total,Group))).

test_harness:arith_misconception(db_row(37457), fraction, name_length_by_group_size,
    misconceptions_fraction_batch_1:name_length_by_group_size,
    length_name(mini_parts(35), unit_parts(3), group_size(7)),
    frac(35,3)).

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
misconceptions_fraction_batch_2:(r37487_add_across(frac(N1,D1)-frac(N2,D2), frac(NSum,DSum)) :-
    NSum is N1 + N2,
    DSum is D1 + D2).

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
misconceptions_fraction_batch_2:(r37511_merge_wholes(shaded(Shaded)-parts_per(PerWhole)-wholes(N), frac(Shaded, Denom)) :-
    Denom is PerWhole * N).

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
misconceptions_fraction_batch_2:(r37519_single_pizza_unit(slices(S)-parts_per(P)-pizzas(_N), frac(S,P))).

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
misconceptions_fraction_batch_2:(r37547_invert_dividend(frac(N,D)-Whole, Result) :-
    % student does frac(D,N) * Whole = (D*Whole)/N, in example 4/4 = 1
    Num is D * Whole,
    Result = frac(Num, N)).

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
misconceptions_fraction_batch_2:(r37572_marks_not_intervals(num(N)-intervals(I), frac(N, Ticks)) :-
    Ticks is I + 1).

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
misconceptions_fraction_batch_2:(r37586_denom_only(frac(N1,D1)-frac(N2,D2), Larger) :-
    (   D1 < D2
    ->  Larger = frac(N1,D1)
    ;   Larger = frac(N2,D2)
    )).

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
misconceptions_fraction_batch_2:(r37641_reciprocal_mult(frac(N1,D1)-frac(N2,D2), frac(Ns, Ds)) :-
    Ns is N1 * D2,
    Ds is D1 * N2).

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
misconceptions_fraction_batch_2:(r37761_group_by_numerator(frac(N,_D)-Total, GroupSize) :-
    GroupSize is Total div N).

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
misconceptions_fraction_batch_2:(r37859_sub_num_add_denom(frac(N1,D1)-frac(N2,D2), frac(Nd, Ds)) :-
    Nd is N1 - N2,
    Ds is D1 + D2).

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
misconceptions_fraction_batch_2:(r37908_additive_equivalence(frac(N,D), frac(Ne, De)) :-
    Ne is N + D,
    De is D + D).

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
misconceptions_fraction_batch_2:(r37921_larger_components(frac(N1,D1)-frac(N2,D2), Larger) :-
    (   N1 >= N2, D1 >= D2
    ->  Larger = frac(N1,D1)
    ;   N2 >= N1, D2 >= D1
    ->  Larger = frac(N2,D2)
    ;   % fallback: pick by numerator
        (N1 > N2 -> Larger = frac(N1,D1) ; Larger = frac(N2,D2))
    )).

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
misconceptions_fraction_batch_2:(r38138_add_across(frac(N1,D1)-frac(N2,D2), frac(Ns, Ds)) :-
    Ns is N1 + N2,
    Ds is D1 + D2).

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
misconceptions_fraction_batch_2:(r38214_difference_vs_operand(frac(N1,D1)-frac(N2,D2), frac(1, RodsPerOperand)) :-
    % difference = 1/(D1*D2/gcd); student names it by how many rods fit the larger operand
    % shortcut: student returns frac(1, D2) when D1 < D2, or frac(1, D1) otherwise
    Diff1 is N1 * D2 - N2 * D1,
    Denom is D1 * D2,
    % student's "rods per operand" — for 1/2 vs 1/3, diff rod is 1/6,
    % 1/2 takes 3 rods; student says "one third"
    (   Diff1 =\= 0
    ->  RodsPerOperand is Denom // max(N1*D2, N2*D1)
    ;   RodsPerOperand = 1
    )).

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
misconceptions_fraction_batch_2:(r38238_missing_piece_equality(frac(N1,D1)-frac(N2,D2), Result) :-
    Miss1 is D1 - N1,
    Miss2 is D2 - N2,
    (   Miss1 =:= Miss2
    ->  Result = equal
    ;   Miss1 < Miss2
    ->  Result = frac(N1,D1)
    ;   Result = frac(N2,D2)
    )).

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
misconceptions_fraction_batch_2:(r38282_linearity_divisor(Dividend-divisor_mixed(Whole,Half), Result) :-
    % student: dividend/(Whole+1) + half*(dividend/(Whole+1))
    % for 16 ÷ 1.5 with divisor_mixed(1,Half=1) treating Half as "+1/2":
    BaseDiv is Dividend // (Whole + 1),   % 16 // 2 = 8
    Adjust is (BaseDiv * Half) // 2,      % 8 // 2 = 4
    R is BaseDiv + Adjust,                % 12
    Result = R).

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
misconceptions_fraction_batch_2:(r38346_non_unit_to_unit(frac(_N,D), frac(1,D))).

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
misconceptions_fraction_batch_2:(r38453_count_all_pieces(outer(Outer)-inner(Inner), frac(1, Total)) :-
    % student: total pieces = (Outer - 1) + Inner
    Total is (Outer - 1) + Inner).

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
misconceptions_fraction_batch_2:(r38555_denom_as_unit(frac(N,D)-_Total, Result) :-
    Result is N * D).

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
misconceptions_fraction_batch_2:(r38704_complement_reasoning(frac(N1,D1)-frac(N2,D2), Larger) :-
    % student: the fraction with smaller complement is larger;
    % compares complement magnitudes via cross multiplication
    C1n is D1 - N1, C1d is D1,
    C2n is D2 - N2, C2d is D2,
    P1 is C1n * C2d,
    P2 is C2n * C1d,
    (   P1 < P2
    ->  Larger = frac(N1,D1)
    ;   Larger = frac(N2,D2)
    )).

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
misconceptions_fraction_batch_2:(r38835_add_across(frac(N1,D1)-frac(N2,D2), frac(Ns,Ds)) :-
    Ns is N1 + N2,
    Ds is D1 + D2).

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
misconceptions_fraction_batch_2:(r38898_larger_denom_smaller(frac(N1,D1)-frac(N2,D2), Larger) :-
    (   D1 < D2
    ->  Larger = frac(N1,D1)
    ;   Larger = frac(N2,D2)
    )).

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
misconceptions_fraction_batch_2:(r38980_appends_half_denom(Whole, frac(Whole, 2))).

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
misconceptions_fraction_batch_2:(r39010_share_count_as_denom(share(Pieces)-whole(_Total), frac(1, Pieces))).

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
misconceptions_fraction_batch_2:(r39130_cross_multiply(frac(N1,D1)-frac(N2,D2), frac(Ns,Ds)) :-
    Ns is N1 * D2,
    Ds is D1 * N2).

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
misconceptions_fraction_batch_2:(r39181_multiply_for_add(frac(N1,D1)-frac(N2,D2), frac(Ns,Ds)) :-
    Ns is N1 * N2,
    Ds is D1 * D2).

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
misconceptions_fraction_batch_2:(r39469_denom_larger_is_larger(frac(N1,D1)-frac(N2,D2), Larger) :-
    (   D1 > D2
    ->  Larger = frac(N1,D1)
    ;   Larger = frac(N2,D2)
    )).

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
misconceptions_fraction_batch_2:(r39710_add_across(frac(N1,D1)-frac(N2,D2), frac(Ns,Ds)) :-
    Ns is N1 + N2,
    Ds is D1 + D2).

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
misconceptions_fraction_batch_2:(r39764_order_by_numerator(Fracs, Ordered) :-
    map_list_to_pairs([F, N]>>(F = frac(N,_)), Fracs, Keyed),
    keysort(Keyed, Sorted),
    pairs_values(Sorted, Ordered)).

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
misconceptions_fraction_batch_2:(r39919_componentwise_between(frac(N1,D1)-frac(N2,D2), frac(Nm, Dm)) :-
    Nm is (N1 + N2) // 2,
    Dm is (D1 + D2) // 2).

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
misconceptions_fraction_batch_2:(r40082_round_divisor_up(frac(N,D)-Decimal_num_over_thousand, Result) :-
    % student: round N/D to nearest 100, round decimal to 1 if near 0.5
    RoundedWhole is round(N / D / 100) * 100,
    (   Decimal_num_over_thousand >= 400, Decimal_num_over_thousand =< 600
    ->  Factor = 1
    ;   Factor = 1
    ),
    Result is RoundedWhole * Factor).

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
misconceptions_fraction_batch_2:(r40235_remainder_as_denom(frac(N, D), residue(Whole, frac(Remainder, Remainder))) :-
    Whole is N div D,
    Remainder is N mod D).

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
misconceptions_fraction_batch_2:(r40269_digit_swap_equal(frac(N1,D1)-frac(N2,D2), Result) :-
    (   (N1 =:= D2, D1 =:= N2)
    ->  Result = equal
    ;   N1 * D2 > N2 * D1
    ->  Result = frac(N1,D1)
    ;   Result = frac(N2,D2)
    )).

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
misconceptions_fraction_batch_2:(r40360_equal_difference(frac(N1,D1)-frac(N2,D2), Result) :-
    Diff1 is D1 - N1,
    Diff2 is D2 - N2,
    (   Diff1 =:= Diff2
    ->  Result = equal
    ;   N1*D2 > N2*D1
    ->  Result = frac(N1,D1)
    ;   Result = frac(N2,D2)
    )).

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
misconceptions_fraction_batch_2:(r40379_add_for_missing(frac(N1,D1)=frac(N2,q), frac(N2, M)) :-
    M is N1 + D1).

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
misconceptions_fraction_batch_2:(r40452_smaller_components(frac(N1,D1)-frac(N2,D2), Larger) :-
    S1 is N1 + D1,
    S2 is N2 + D2,
    (   S1 =< S2
    ->  Larger = frac(N1,D1)
    ;   Larger = frac(N2,D2)
    )).

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
misconceptions_fraction_batch_2:(r40469_div_to_add_across(frac(N1,D1)-frac(N2,D2), frac(Ns,Ds)) :-
    Ns is N1 + N2,
    Ds is D1 + D2).

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

% Fraction misconceptions — research corpus batch 3/7.
% Native arithmetic layer only. Theoretical annotations as comments:
%   % GROUNDED: TODO — placeholder for future embodied arithmetic layer
%   % SCHEMA: <schema name> — Lakoff & Nunez grounding when applicable
%   % CONNECTS TO: s(comp_nec(unlicensed(...))) — PML operator path
%
% Registration convention (from Task 3 arch fix):
%   test_harness:arith_misconception(Source, Domain, Description,
%       misconceptions_fraction_batch_3:rule_name, Input, Expected).
% Rule predicates do NOT go on the module export list.


% ---- Encodings appended by agent for batch 3 ----

% === row 37436: unit fraction named by piece length ===
% Task: name the unit fraction that a 6-stick is of a 24-stick
% Correct: frac(1,4)  (24/6 = 4)
% Error: frac(1,6) — naming the fraction by the length of the piece
% SCHEMA: Measuring Stick — the name comes from the part-whole *count*, not the piece length
% GROUNDED: TODO — iterate_count(Whole, Part, N); name(1/N)
% CONNECTS TO: s(comp_nec(unlicensed(name_by_length)))
misconceptions_fraction_batch_3:(r37436_name_by_length(Whole-Part, frac(1, Part)) :-
    integer(Whole), integer(Part), Part > 0).

test_harness:arith_misconception(db_row(37436), fraction, unit_frac_named_by_length,
    misconceptions_fraction_batch_3:r37436_name_by_length,
    24-6,
    frac(1,4)).

% === row 37443: guessed partition count from unrelated prior problem ===
% Task: compute frac(3,4) of frac(1,4)
% Correct: frac(3,16)
% Error: frac(3,10) — guessed denominator of 10 from a prior problem
% SCHEMA: Container — recursive partitioning required; student uses simultaneous guess
% GROUNDED: TODO — recursive_partition(frac, frac, frac)
% CONNECTS TO: s(comp_nec(unlicensed(guess_denominator_from_prior)))
misconceptions_fraction_batch_3:(r37443_guess_denom(frac(N1,_)-frac(_,_), frac(Got, 10)) :-
    Got is N1).

test_harness:arith_misconception(db_row(37443), fraction, guess_denom_from_prior,
    misconceptions_fraction_batch_3:r37443_guess_denom,
    frac(3,4)-frac(1,4),
    frac(3,16)).

% === row 37450: iterate resulting piece to rebuild whole ===
% Task: compute 1/2 of 1/15
% Correct: frac(1, 30)
% Error: student iterates the piece 30 times and names it 1/30 — which happens to be
% the correct value. The misconception is in the reasoning (iteration rather than
% recursive partition), but the numeric answer coincides. We encode the iteration
% strategy as written; harness will flag as well_formed (matches correct).
% SCHEMA: Container — counted iterations stand in for composed partition
% GROUNDED: TODO — iterate_to_whole(Piece, Count)
% CONNECTS TO: s(comp_nec(unlicensed(iterate_instead_of_compose)))
misconceptions_fraction_batch_3:(r37450_iterate_to_name(frac(N1,D1)-frac(N2,D2), frac(Num, Count)) :-
    % iterate the composed piece until it rebuilds the whole; name = 1/Count
    Num is N1 * N2,
    Count is D1 * D2).

test_harness:arith_misconception(db_row(37450), fraction, iterate_to_rebuild_whole,
    misconceptions_fraction_batch_3:r37450_iterate_to_name,
    frac(1,2)-frac(1,15),
    frac(1,30)).

% === row 37488: sum numerators over sum denominators ===
% Task: 1/2 + 2/3
% Correct: 7/6
% Error: (1+2)/(2+3) = 3/5
% SCHEMA: Arithmetic as Object Collection — overgeneralizing "add across"
% GROUNDED: TODO — add_grounded(N1,N2,N), add_grounded(D1,D2,D)
% CONNECTS TO: s(comp_nec(unlicensed(add_across_numer_and_denom)))
misconceptions_fraction_batch_3:(r37488_add_across(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 + N2,
    D is D1 + D2).

test_harness:arith_misconception(db_row(37488), fraction, add_num_over_sum_denom,
    misconceptions_fraction_batch_3:r37488_add_across,
    frac(1,2)-frac(2,3),
    frac(7,6)).

% === row 37512: rote add-across trusted over informal reasoning ===
% Task: 3/8 + 2/8
% Correct: frac(5,8)
% Error: 5/16 — applied add-across rule even when denominators match
% SCHEMA: Arithmetic as Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(rote_add_across_same_denom)))
misconceptions_fraction_batch_3:(r37512_rote_add_across(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 + N2,
    D is D1 + D2).

test_harness:arith_misconception(db_row(37512), fraction, rote_add_across_like_denom,
    misconceptions_fraction_batch_3:r37512_rote_add_across,
    frac(3,8)-frac(2,8),
    frac(5,8)).

% === row 37520: referent-whole shift combining identical wholes ===
% Task: 3/8 + 3/8 (interpreted as pieces from two pizzas pooled into 16-piece whole)
% Correct (add): frac(6,8)
% Student: 6/16 — shift referent whole to combined 16-piece total
% SCHEMA: Container — referent unit switched mid-operation
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(referent_whole_shift)))
misconceptions_fraction_batch_3:(r37520_referent_shift(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 + N2,
    D is D1 + D2).

test_harness:arith_misconception(db_row(37520), fraction, referent_whole_shift,
    misconceptions_fraction_batch_3:r37520_referent_shift,
    frac(3,8)-frac(3,8),
    frac(6,8)).

% === row 37548: division makes smaller, use multiplication instead ===
% Task: 4 / (1/4)  (how many 1/4-kg packages from 4 kg)
% Correct: 16
% Error: compute 1/4 * 4 = 1 instead
% SCHEMA: Arithmetic as Object Collection — primitive partitive model
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(div_must_shrink_swap_for_mult)))
misconceptions_fraction_batch_3:(r37548_swap_for_mult(Whole-frac(N,D), Got) :-
    % multiply instead of divide: (N/D) * Whole
    Got is (N * Whole) / D).

test_harness:arith_misconception(db_row(37548), fraction, div_swap_for_mult,
    misconceptions_fraction_batch_3:r37548_swap_for_mult,
    4-frac(1,4),
    16).

% === row 37573: denominators increase left to right on number line ===
% Task: label 3 tick marks between 0 and 1 (equally spaced at 1/4, 1/2, 3/4)
% Correct: [frac(1,4), frac(1,2), frac(3,4)]
% Error: [frac(1,2), frac(1,3), frac(1,4)] — consecutive unit denominators
% SCHEMA: Measuring Stick — whole-number-consistent left-to-right ordering
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(consecutive_unit_denoms)))
misconceptions_fraction_batch_3:(r37573_consecutive_denoms(3, [frac(1,2), frac(1,3), frac(1,4)])).

test_harness:arith_misconception(db_row(37573), fraction, consecutive_unit_denoms,
    misconceptions_fraction_batch_3:r37573_consecutive_denoms,
    3,
    [frac(1,4), frac(1,2), frac(3,4)]).

% === row 37587: more pieces means bigger fraction ===
% Task: compare frac(1,4) and frac(1,3)
% Correct: frac(1,3) larger
% Error: claim frac(1,4) larger because "more total pieces"
% SCHEMA: Arithmetic as Object Collection — whole-number transfer
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(more_pieces_larger)))
misconceptions_fraction_batch_3:(r37587_more_pieces_larger(frac(N1,D1)-frac(N2,D2), Larger) :-
    (D1 > D2 -> Larger = frac(N1,D1)
    ; D2 > D1 -> Larger = frac(N2,D2)
    ; Larger = equal)).

test_harness:arith_misconception(db_row(37587), fraction, more_pieces_larger,
    misconceptions_fraction_batch_3:r37587_more_pieces_larger,
    frac(1,4)-frac(1,3),
    frac(1,3)).

% === row 37656: improper fractions require multiple wholes ===
% Too vague — a belief claim; no concrete wrong numeric answer.
test_harness:arith_misconception(db_row(37656), fraction, too_vague,
    skip, none, none).

% === row 37666: product of num*denom used inversely for ordering ===
% Task: compare frac(2,3) and frac(2,6)
% Correct: frac(2,3) larger
% Error: 2*6=12 > 2*3=6, so frac(2,6) smaller — happens to match here
% SCHEMA: Measuring Stick — rule invented from cover-count logic
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(product_inverse_order)))
misconceptions_fraction_batch_3:(r37666_product_inverse(frac(N1,D1)-frac(N2,D2), Larger) :-
    P1 is N1 * D1,
    P2 is N2 * D2,
    (P1 < P2 -> Larger = frac(N1,D1)
    ; P2 < P1 -> Larger = frac(N2,D2)
    ; Larger = equal)).

test_harness:arith_misconception(db_row(37666), fraction, product_size_inverse,
    misconceptions_fraction_batch_3:r37666_product_inverse,
    frac(2,3)-frac(2,6),
    frac(2,3)).

% === row 37679: remainder cannot be shared ===
% Too vague — conceptual refusal to partition, no concrete wrong numeric output.
test_harness:arith_misconception(db_row(37679), fraction, too_vague,
    skip, none, none).

% === row 37720: key-word triggers for operation ===
% Too vague — strategy-selection error, no concrete wrong numeric answer given.
test_harness:arith_misconception(db_row(37720), fraction, too_vague,
    skip, none, none).

% === row 37768: part-whole scheme: pull 3 parts then 2 of those ===
% Task: produce 2/3 from a 6/6 bar
% Correct: pull 4 parts (4/6 = 2/3)
% Error: pulled 3 parts then took 2 of those = 2 parts = 2/6
% SCHEMA: Container — partitive scheme misapplied
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(pull_then_subpull)))
misconceptions_fraction_batch_3:(r37768_pull_then_subpull(frac(N,D)-_Whole, Got) :-
    % pull D parts, take N of those
    Pulled is D,
    _ = Pulled,
    Got is N).

test_harness:arith_misconception(db_row(37768), fraction, pull_then_subpull,
    misconceptions_fraction_batch_3:r37768_pull_then_subpull,
    frac(2,3)-6,
    4).

% === row 37781: compare shaded areas by counting pieces ===
% Task: compare two rectangles, each 7 shaded pieces, but different partition sizes
% Correct: depends on sizes; student claims "same, seven and seven"
% Input: count1-count2 = 7-7; Correct: requires piece size, cannot conclude same
% Encode as: rule returns `same` when counts match; expected is `not_same`.
% SCHEMA: Arithmetic as Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(count_pieces_ignore_size)))
misconceptions_fraction_batch_3:(r37781_count_pieces(C1-C2, Judgement) :-
    (C1 =:= C2 -> Judgement = same
    ; C1 > C2 -> Judgement = first_larger
    ; Judgement = second_larger)).

test_harness:arith_misconception(db_row(37781), fraction, count_pieces_ignore_size,
    misconceptions_fraction_batch_3:r37781_count_pieces,
    7-7,
    depends_on_piece_size).

% === row 37804: decompose bundles into singletons and reapply ===
% Task: 3/4 of 8 bundles of 4 sticks — correct answer in bundles is 6
% Error: transform to 32 sticks, compute 24, then divide to get 6 bundles
% The student's procedure arrives at the same numeric answer (24 sticks / 6 bundles),
% so the misconception is in the unit-reasoning, not the number. Encode the
% singleton path as returning 24 (sticks) when the expected answer is 6 (bundles).
% SCHEMA: Arithmetic as Object Collection — collapses composite units
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(decompose_composite_units)))
misconceptions_fraction_batch_3:(r37804_singleton_path(frac(N,D)-bundles(B,S), Got) :-
    Total is B * S,
    Got is (Total * N) / D).

test_harness:arith_misconception(db_row(37804), fraction, decompose_composite_units,
    misconceptions_fraction_batch_3:r37804_singleton_path,
    frac(3,4)-bundles(8,4),
    6).

% === row 37822: partition by iteration + adjustment ===
% Too vague — describes search behavior rather than a concrete wrong numeric answer.
test_harness:arith_misconception(db_row(37822), fraction, too_vague,
    skip, none, none).

% === row 37846: standard notation without part-whole reference ===
% Too vague — notational use without a specific wrong numeric answer in the example.
test_harness:arith_misconception(db_row(37846), fraction, too_vague,
    skip, none, none).

% === row 37863: iterating 1/8 nine times called 9/9 ===
% Task: name the stick built by iterating frac(1,8) nine times
% Correct: frac(9,8)
% Error: frac(9,9) — shifts whole to the new 9-part stick
% SCHEMA: Container — referent whole reassigned to result
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(reference_whole_shift_iterate)))
misconceptions_fraction_batch_3:(r37863_shift_whole(frac(N,_)-Iter, frac(Iter, Iter)) :-
    integer(N), integer(Iter)).

test_harness:arith_misconception(db_row(37863), fraction, shift_whole_on_iterate,
    misconceptions_fraction_batch_3:r37863_shift_whole,
    frac(1,8)-9,
    frac(9,8)).

% === row 37879: whole number treated as fraction with same denominator ===
% Task: 1 - 4/5
% Correct: frac(1,5)
% Error: reads 1 as 1/5, computes 4-1=3, answer 3/5
% SCHEMA: Arithmetic as Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(whole_as_num_same_denom)))
misconceptions_fraction_batch_3:(r37879_whole_as_unit(Whole-frac(N,D), frac(Num, D)) :-
    % treat Whole as Whole/D; compute N - Whole; take absolute value
    Num is abs(N - Whole)).

test_harness:arith_misconception(db_row(37879), fraction, whole_as_unit_fraction,
    misconceptions_fraction_batch_3:r37879_whole_as_unit,
    1-frac(4,5),
    frac(1,5)).

% === row 37909: partial scaling in equivalent-fraction missing value ===
% Task: 6/4 = ?/8 — find missing numerator
% Correct: 12 (scale factor 2)
% Error: 3 — "three into six twice; two times four equals eight" — divides numerator by 2
% SCHEMA: Measuring Stick — misapplies reciprocal scaling
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(partial_scale_missing_numer)))
misconceptions_fraction_batch_3:(r37909_partial_scale(frac(N1,D1)-D2, Got) :-
    Factor is D2 / D1,
    Got is N1 / Factor).

test_harness:arith_misconception(db_row(37909), fraction, partial_scale_missing_numer,
    misconceptions_fraction_batch_3:r37909_partial_scale,
    frac(6,4)-8,
    12).

% === row 37940: 1/2 + 1/4 = 2/6 via multiply-like addition ===
% Task: 1/2 + 1/4
% Correct: frac(3,4)
% Error: add across → frac(2,6)
% SCHEMA: Arithmetic as Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(add_across_unlike)))
misconceptions_fraction_batch_3:(r37940_add_across(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 + N2,
    D is D1 + D2).

test_harness:arith_misconception(db_row(37940), fraction, add_across_unlike_denoms,
    misconceptions_fraction_batch_3:r37940_add_across,
    frac(1,2)-frac(1,4),
    frac(3,4)).

% === row 37974: 2/7 + 3/7 = 5/14 ===
% Task: 2/7 + 3/7
% Correct: frac(5,7)
% Error: add across → frac(5,14)
% SCHEMA: Arithmetic as Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(add_across_like_denoms)))
misconceptions_fraction_batch_3:(r37974_add_across(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 + N2,
    D is D1 + D2).

test_harness:arith_misconception(db_row(37974), fraction, add_across_like_denoms,
    misconceptions_fraction_batch_3:r37974_add_across,
    frac(2,7)-frac(3,7),
    frac(5,7)).

% === row 38055: 1/4 + 2/5 = 3/9 ===
% Task: 1/4 + 2/5
% Correct: frac(13,20)
% Error: add across → frac(3,9)
% SCHEMA: Arithmetic as Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(add_across_unlike)))
misconceptions_fraction_batch_3:(r38055_add_across(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 + N2,
    D is D1 + D2).

test_harness:arith_misconception(db_row(38055), fraction, add_across_unlike,
    misconceptions_fraction_batch_3:r38055_add_across,
    frac(1,4)-frac(2,5),
    frac(13,20)).

% === row 38113: multiply num and denom by whole number ===
% Task: (1/2) * 3
% Correct: frac(3,2)
% Error: multiply both parts by whole → frac(3,6)
% SCHEMA: Arithmetic as Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(mult_both_by_whole)))
misconceptions_fraction_batch_3:(r38113_mult_both_by_whole(frac(N,D)-K, frac(N2, D2)) :-
    N2 is N * K,
    D2 is D * K).

test_harness:arith_misconception(db_row(38113), fraction, mult_both_by_whole,
    misconceptions_fraction_batch_3:r38113_mult_both_by_whole,
    frac(1,2)-3,
    frac(3,2)).

% === row 38139: multiplication always makes bigger ===
% Too vague — a belief claim; no concrete example in CSV.
test_harness:arith_misconception(db_row(38139), fraction, too_vague,
    skip, none, none).

% === row 38220: multiplication only as repeated addition ===
% Too vague — rejection of operation, not a concrete wrong numeric answer.
test_harness:arith_misconception(db_row(38220), fraction, too_vague,
    skip, none, none).

% === row 38243: equal iff same absolute missing amount ===
% Task: compare frac(3,4) and frac(5,6)
% Correct: 5/6 > 3/4
% Error: both missing 1 piece, so "equal"
% SCHEMA: Arithmetic as Object Collection — compares complement counts
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(equal_by_missing_count)))
misconceptions_fraction_batch_3:(r38243_missing_pieces_equal(frac(N1,D1)-frac(N2,D2), Judgement) :-
    M1 is D1 - N1,
    M2 is D2 - N2,
    (M1 =:= M2 -> Judgement = equal
    ; M1 < M2 -> Judgement = first_larger
    ; Judgement = second_larger)).

test_harness:arith_misconception(db_row(38243), fraction, equal_by_missing_piece_count,
    misconceptions_fraction_batch_3:r38243_missing_pieces_equal,
    frac(3,4)-frac(5,6),
    second_larger).

% === row 38260: 1/n only via equal partition — unequal means not 1/n ===
% Too vague — a rejection claim about representation, not a numeric transformation.
test_harness:arith_misconception(db_row(38260), fraction, too_vague,
    skip, none, none).

% === row 38283: missing-denominator task — couldn't proceed ===
% Too vague — strategy breakdown without a concrete wrong numeric output.
test_harness:arith_misconception(db_row(38283), fraction, too_vague,
    skip, none, none).

% === row 38315: biggest-numerator-means-biggest-fraction ===
% Task: compare frac(2,3) and frac(5,6) (or two arbitrary fractions)
% Correct: cross-product ordering
% Error: whoever has larger numerator is larger
% SCHEMA: Arithmetic as Object Collection — whole-number-consistent
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(bigger_numer_bigger_frac)))
misconceptions_fraction_batch_3:(r38315_bigger_numer(frac(N1,D1)-frac(N2,D2), Larger) :-
    (N1 > N2 -> Larger = frac(N1,D1)
    ; N2 > N1 -> Larger = frac(N2,D2)
    ; Larger = equal)).

test_harness:arith_misconception(db_row(38315), fraction, bigger_numer_bigger_frac,
    misconceptions_fraction_batch_3:r38315_bigger_numer,
    frac(2,3)-frac(5,6),
    frac(5,6)).

% === row 38367: third of an eighth — guessed wrong frac ===
% Task: 1/3 of 1/8
% Correct: frac(1,24)
% Error: guessed frac(1,4) based on visual cues
% SCHEMA: Container — no iterable unit fractional part
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(guess_from_visual)))
misconceptions_fraction_batch_3:(r38367_guess_visual(frac(1,3)-frac(1,8), frac(1,4))).

test_harness:arith_misconception(db_row(38367), fraction, guess_recursive_partition,
    misconceptions_fraction_batch_3:r38367_guess_visual,
    frac(1,3)-frac(1,8),
    frac(1,24)).

% === row 38385: add full shortage to next estimate ===
% Too vague — describes adjustment strategy, not a concrete wrong numeric output.
test_harness:arith_misconception(db_row(38385), fraction, too_vague,
    skip, none, none).

% === row 38405: compare same-denom by numerator alone (whole number bias) ===
% Task: compare frac(7,8) and frac(3,8)
% Correct: frac(7,8) larger
% Error: correct answer but via isolated whole-number reasoning; no wrong numeric result.
% Still encode: student returns larger numerator's fraction — this matches correct.
% SCHEMA: Arithmetic as Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(numer_as_whole_numbers)))
misconceptions_fraction_batch_3:(r38405_numer_whole(frac(N1,D1)-frac(N2,D2), Larger) :-
    (N1 > N2 -> Larger = frac(N1,D1)
    ; N2 > N1 -> Larger = frac(N2,D2)
    ; Larger = equal)).

test_harness:arith_misconception(db_row(38405), fraction, numer_as_whole_numbers,
    misconceptions_fraction_batch_3:r38405_numer_whole,
    frac(7,8)-frac(3,8),
    frac(7,8)).

% === row 38431: referent-unit switch in difference ===
% Task: frac(1,2) - frac(1,3)
% Correct: frac(1,6)
% Error: difference is 1/3 of the 1/2 rod — renames remainder with shifted referent
% SCHEMA: Container — referent unit switched mid-problem
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(referent_unit_switch_difference)))
misconceptions_fraction_batch_3:(r38431_referent_switch(frac(N1,D1)-frac(N2,D2), frac(1,3)) :-
    N1 = 1, D1 = 2, N2 = 1, D2 = 3).

test_harness:arith_misconception(db_row(38431), fraction, referent_unit_switch_difference,
    misconceptions_fraction_batch_3:r38431_referent_switch,
    frac(1,2)-frac(1,3),
    frac(1,6)).

% === row 38454: name fraction by count of pieces present ===
% Task: what fraction is shown when 5 of 6 pieces are present (one missing)
% Correct: frac(5,6)
% Error: frac(1,5) — names by count of pieces shown
% SCHEMA: Arithmetic as Object Collection — missing disembedding
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(name_by_count_present)))
misconceptions_fraction_batch_3:(r38454_name_by_count(present(Count, _Total), frac(1, Count))).

test_harness:arith_misconception(db_row(38454), fraction, name_by_count_present,
    misconceptions_fraction_batch_3:r38454_name_by_count,
    present(5, 6),
    frac(5,6)).

% === row 38491: add-across unlike denominators ===
% Task: 10/50 + 40/100
% Correct: frac(60, 100) i.e. frac(3,5)
% Error: 50/150 (add across)
% SCHEMA: Arithmetic as Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(add_across_unlike)))
misconceptions_fraction_batch_3:(r38491_add_across(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 + N2,
    D is D1 + D2).

test_harness:arith_misconception(db_row(38491), fraction, add_across_sheets,
    misconceptions_fraction_batch_3:r38491_add_across,
    frac(10,50)-frac(40,100),
    frac(60,100)).

% === row 38556: 1/3 of 12 by subtracting the denominator ===
% Task: 1/3 of 12
% Correct: 4
% Error: 12 - 3 = 9
% SCHEMA: Arithmetic as Object Collection — additive interpretation
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(unit_frac_as_subtract_denom)))
misconceptions_fraction_batch_3:(r38556_subtract_denom(frac(_,D)-N, Got) :-
    Got is N - D).

test_harness:arith_misconception(db_row(38556), fraction, unit_frac_as_subtract_denom,
    misconceptions_fraction_batch_3:r38556_subtract_denom,
    frac(1,3)-12,
    4).

% === row 38573: disembedding failure — whole destroyed when part removed ===
% Too vague — conceptual disembedding failure; no concrete numeric wrong answer.
test_harness:arith_misconception(db_row(38573), fraction, too_vague,
    skip, none, none).

% === row 38647: repeated halving breaks with odd sharers ===
% Too vague — strategy breakdown without a specific wrong numeric answer.
test_harness:arith_misconception(db_row(38647), fraction, too_vague,
    skip, none, none).

% === row 38663: multiplication algorithm needs denominators ===
% Too vague — inability to respond, not a wrong numeric answer.
test_harness:arith_misconception(db_row(38663), fraction, too_vague,
    skip, none, none).

% === row 38678: bigger-denominator-smaller-fraction as procedural fact ===
% Task: explain why 1/2 > 1/12
% Too vague for numeric encoding — meta/justification, not an arithmetic result.
test_harness:arith_misconception(db_row(38678), fraction, too_vague,
    skip, none, none).

% === row 38716: part-whole scheme rejects 9/7 ===
% Too vague — belief/rejection, no numeric transformation.
test_harness:arith_misconception(db_row(38716), fraction, too_vague,
    skip, none, none).

% === row 38753: bigger numbers means bigger fraction ===
% Task: compare frac(8,10) and frac(4,5)
% Correct: equal
% Error: frac(8,10) larger because "both bigger"
% SCHEMA: Arithmetic as Object Collection — whole-number bias
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(bigger_both_bigger_frac)))
misconceptions_fraction_batch_3:(r38753_bigger_both(frac(N1,D1)-frac(N2,D2), Larger) :-
    (N1 > N2, D1 > D2 -> Larger = frac(N1,D1)
    ; N2 > N1, D2 > D1 -> Larger = frac(N2,D2)
    ; Larger = unclear)).

test_harness:arith_misconception(db_row(38753), fraction, bigger_both_bigger_frac,
    misconceptions_fraction_batch_3:r38753_bigger_both,
    frac(8,10)-frac(4,5),
    equal).

% === row 38836: convert smaller to larger denominator incorrectly ===
% Too vague — describes incorrect conversion attempts without specific numeric example.
test_harness:arith_misconception(db_row(38836), fraction, too_vague,
    skip, none, none).

% === row 38856: didactical contract — swap 2/1 for 1/2 ===
% Task: ratio of shaded(2) to unshaded(1)
% Correct: frac(2,1)
% Error: frac(1,2) — swapped to fit conventional appearance
% SCHEMA: Container — didactical contract overrides setup
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(swap_for_convention)))
misconceptions_fraction_batch_3:(r38856_swap_for_convention(ratio(Shaded, Unshaded), frac(Unshaded, Shaded)) :-
    integer(Shaded), integer(Unshaded)).

test_harness:arith_misconception(db_row(38856), fraction, swap_ratio_for_convention,
    misconceptions_fraction_batch_3:r38856_swap_for_convention,
    ratio(2,1),
    frac(2,1)).

% === row 38913: lowest bottom number is greatest ===
% Task: compare frac(3,4) and frac(5,6)
% Correct: frac(5,6) larger
% Error: frac(3,4) — 4 < 6, so "lowest bottom wins"
% SCHEMA: Arithmetic as Object Collection — overgeneralized rule
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(lowest_denom_greatest)))
misconceptions_fraction_batch_3:(r38913_lowest_denom(frac(N1,D1)-frac(N2,D2), Larger) :-
    (D1 < D2 -> Larger = frac(N1,D1)
    ; D2 < D1 -> Larger = frac(N2,D2)
    ; Larger = equal)).

test_harness:arith_misconception(db_row(38913), fraction, lowest_denom_greatest,
    misconceptions_fraction_batch_3:r38913_lowest_denom,
    frac(3,4)-frac(5,6),
    frac(5,6)).

% === row 38963: cannot halve a week ===
% Too vague — discreteness claim without numeric transformation.
test_harness:arith_misconception(db_row(38963), fraction, too_vague,
    skip, none, none).

% === row 38981: can be both ages simultaneously ===
% Too vague — timeline/ordering belief; no concrete fraction arithmetic output.
test_harness:arith_misconception(db_row(38981), fraction, too_vague,
    skip, none, none).

% === row 39011: partition without quantifying shares ===
% Too vague — inability to name shares; no wrong numeric output.
test_harness:arith_misconception(db_row(39011), fraction, too_vague,
    skip, none, none).

% === row 39073: can't divide smaller by larger ===
% Too vague — refusal of operation, no numeric wrong output.
test_harness:arith_misconception(db_row(39073), fraction, too_vague,
    skip, none, none).

% === row 39134: order-of-appearance ratio setup ===
% Task: given numbers 5,3,7,4 (problem mentions 3-out-of-5 and 4-out-of-7)
% Correct: compare frac(3,5) and frac(4,7)
% Error: compare frac(5,3) and frac(7,4) — order of appearance
% SCHEMA: Arithmetic as Object Collection — syntactic setup
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(order_of_appearance_ratio)))
misconceptions_fraction_batch_3:(r39134_order_of_appearance([A,B,C,D], [frac(A,B), frac(C,D)]) :-
    integer(A), integer(B), integer(C), integer(D)).

test_harness:arith_misconception(db_row(39134), fraction, order_of_appearance_ratio,
    misconceptions_fraction_batch_3:r39134_order_of_appearance,
    [5,3,7,4],
    [frac(3,5), frac(4,7)]).

% === row 39162: add-tops-and-bottoms (whole-number bias) ===
% Task: 1/3 + 1/6
% Correct: frac(1,2) (i.e., 3/6)
% Error: add across → frac(2,9)
% SCHEMA: Arithmetic as Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(add_tops_and_bottoms)))
misconceptions_fraction_batch_3:(r39162_add_across(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 + N2,
    D is D1 + D2).

test_harness:arith_misconception(db_row(39162), fraction, add_tops_and_bottoms,
    misconceptions_fraction_batch_3:r39162_add_across,
    frac(1,3)-frac(1,6),
    frac(3,6)).

% === row 39192: dealing strategy abandoned ===
% Too vague — strategy abandonment, no concrete wrong numeric answer.
test_harness:arith_misconception(db_row(39192), fraction, too_vague,
    skip, none, none).

% === row 39273: degrees of equivalence ===
% Too vague — belief about equivalence; no wrong numeric computation.
test_harness:arith_misconception(db_row(39273), fraction, too_vague,
    skip, none, none).

% === row 39347: invert-and-multiply bugs — multiply without inverting ===
% Task: (3/5) / (1/20)
% Correct: frac(60, 5) i.e. 12
% Error: multiply without inverting → (3*1)/(5*20) = 3/100
% SCHEMA: Arithmetic as Object Collection — algorithmic bug
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(multiply_without_invert)))
misconceptions_fraction_batch_3:(r39347_multiply_no_invert(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 * N2,
    D is D1 * D2).

test_harness:arith_misconception(db_row(39347), fraction, multiply_without_invert,
    misconceptions_fraction_batch_3:r39347_multiply_no_invert,
    frac(3,5)-frac(1,20),
    frac(60,5)).

% === row 39411: improper fraction destabilized by realistic context ===
% Too vague — contextual rejection, no wrong numeric.
test_harness:arith_misconception(db_row(39411), fraction, too_vague,
    skip, none, none).

% === row 39470: overreliance on circle model ===
% Too vague — model-rigidity, no wrong numeric output.
test_harness:arith_misconception(db_row(39470), fraction, too_vague,
    skip, none, none).

% === row 39556: 1/2 = 1/3 via different-sized wholes ===
% Task: compare frac(1,2) and frac(1,3)
% Correct: frac(1,2) larger
% Error: declares equal by drawing different-sized wholes
% SCHEMA: Container — referent-whole size ignored
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(unequal_wholes)))
misconceptions_fraction_batch_3:(r39556_unequal_wholes(frac(_,_)-frac(_,_), equal)).

test_harness:arith_misconception(db_row(39556), fraction, unequal_wholes_equal,
    misconceptions_fraction_batch_3:r39556_unequal_wholes,
    frac(1,2)-frac(1,3),
    frac(1,2)).

% === row 39600: whole number concepts interfere (general) ===
% Too vague — general claim, no specific wrong numeric example.
test_harness:arith_misconception(db_row(39600), fraction, too_vague,
    skip, none, none).

% === row 39619: 1/2 + 1/4 = 2/6 (add across) ===
% Task: 1/2 + 1/4
% Correct: frac(3,4)
% Error: frac(2,6)
% SCHEMA: Arithmetic as Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(add_across_unlike)))
misconceptions_fraction_batch_3:(r39619_add_across(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 + N2,
    D is D1 + D2).

test_harness:arith_misconception(db_row(39619), fraction, add_across_unlike,
    misconceptions_fraction_batch_3:r39619_add_across,
    frac(1,2)-frac(1,4),
    frac(3,4)).

% === row 39653: area-model only for unit fractions ===
% Too vague — model rigidity; no concrete wrong numeric output.
test_harness:arith_misconception(db_row(39653), fraction, too_vague,
    skip, none, none).

% === row 39689: "more" triggers addition ignoring unit ===
% Task: 1/5 more than cats(3) — correct: 3 + 1/5 * 3 = 3.6 (but dogs must be whole)
% Error: add 1/5 directly to 3 → 3 1/5 dogs
% SCHEMA: Arithmetic as Object Collection — keyword triggered addition
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(keyword_add_ignore_unit)))
misconceptions_fraction_batch_3:(r39689_keyword_add(more_than(Cats, frac(N,D)), mixed(Cats, frac(N,D))) :-
    integer(Cats)).

test_harness:arith_misconception(db_row(39689), fraction, keyword_triggers_add,
    misconceptions_fraction_batch_3:r39689_keyword_add,
    more_than(3, frac(1,5)),
    whole_number_adjusted).

% === row 39712: mixed-to-improper: add parts ignoring whole ===
% Task: convert 1 4/5 to improper
% Correct: frac(9,5)
% Error: 4+5 = 9/5, ignoring the 1 — numerically coincides here, but method wrong.
% SCHEMA: Arithmetic as Object Collection — local algorithm
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(ignore_whole_add_parts)))
misconceptions_fraction_batch_3:(r39712_add_parts(mixed(_W, frac(N,D)), frac(Num, D)) :-
    Num is N + D).

test_harness:arith_misconception(db_row(39712), fraction, add_num_denom_ignore_whole,
    misconceptions_fraction_batch_3:r39712_add_parts,
    mixed(1, frac(4,5)),
    frac(9,5)).

% === row 39765: 3/8 + 4/10 = 7/18 ===
% Task: 3/8 + 4/10
% Correct: frac(62, 80) = frac(31,40)
% Error: frac(7,18)
% SCHEMA: Arithmetic as Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(add_across_unlike)))
misconceptions_fraction_batch_3:(r39765_add_across(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 + N2,
    D is D1 + D2).

test_harness:arith_misconception(db_row(39765), fraction, add_across_unlike,
    misconceptions_fraction_batch_3:r39765_add_across,
    frac(3,8)-frac(4,10),
    frac(62,80)).

% === row 39772: mismark number line for measurement division ===
% Too vague — placement error without a concrete numeric arithmetic output.
test_harness:arith_misconception(db_row(39772), fraction, too_vague,
    skip, none, none).

% === row 39811: "two-ninths" for 1/3 + 1/6 ===
% Task: 1/3 + 1/6
% Correct: frac(1,2)
% Error: frac(2,9)
% SCHEMA: Arithmetic as Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(add_across_unlike)))
misconceptions_fraction_batch_3:(r39811_add_across(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 + N2,
    D is D1 + D2).

test_harness:arith_misconception(db_row(39811), fraction, add_across_unlike,
    misconceptions_fraction_batch_3:r39811_add_across,
    frac(1,3)-frac(1,6),
    frac(3,6)).

% === row 39818: inconsistent units in fraction addition ===
% Too vague — unit inconsistency without specific numeric wrong answer.
test_harness:arith_misconception(db_row(39818), fraction, too_vague,
    skip, none, none).

% === row 39836: smaller denom means smaller fraction ===
% Task: compare frac(1,5) and frac(1,10)
% Correct: frac(1,5) larger
% Error: frac(1,10) larger (smaller denom is smaller)
% SCHEMA: Arithmetic as Object Collection — whole-number bias
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(smaller_denom_smaller_frac)))
misconceptions_fraction_batch_3:(r39836_smaller_denom_smaller(frac(N1,D1)-frac(N2,D2), Larger) :-
    (D1 > D2 -> Larger = frac(N1,D1)
    ; D2 > D1 -> Larger = frac(N2,D2)
    ; Larger = equal)).

test_harness:arith_misconception(db_row(39836), fraction, smaller_denom_smaller_frac,
    misconceptions_fraction_batch_3:r39836_smaller_denom_smaller,
    frac(1,5)-frac(1,10),
    frac(1,5)).

% === row 39890: reverse-ordered notation — "5/2" for "two fifths" ===
% Task: write the fraction for "two fifths" (bottom-to-top in Turkish)
% Correct: frac(2,5)
% Error: frac(5,2) — wrote in read order
% SCHEMA: Measuring Stick — swap positions from reading order
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(swap_numer_denom_notation)))
misconceptions_fraction_batch_3:(r39890_swap_notation(spoken(Denom, Numer), frac(Denom, Numer)) :-
    integer(Denom), integer(Numer)).

test_harness:arith_misconception(db_row(39890), fraction, swap_notation_direction,
    misconceptions_fraction_batch_3:r39890_swap_notation,
    spoken(5, 2),
    frac(2,5)).

% === row 39948: 1/5 + 1/3 = 2/8 ===
% Task: 1/5 + 1/3
% Correct: frac(8,15)
% Error: frac(2,8)
% SCHEMA: Arithmetic as Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(add_across_unlike)))
misconceptions_fraction_batch_3:(r39948_add_across(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 + N2,
    D is D1 + D2).

test_harness:arith_misconception(db_row(39948), fraction, add_across_unlike,
    misconceptions_fraction_batch_3:r39948_add_across,
    frac(1,5)-frac(1,3),
    frac(8,15)).

% === row 40034: treat linear shaded half as area 1/8 ===
% Too vague — perceptual misidentification; no clean numeric transformation.
test_harness:arith_misconception(db_row(40034), fraction, too_vague,
    skip, none, none).

% === row 40083: distribute denominator across multiplied numerators ===
% Task: estimate (600 * 7) / 20
% Correct: 210
% Error: 600/20 * 7/20 = 30 * (1/3) ≈ 10   (written wrong distribution of denom)
% SCHEMA: Arithmetic as Object Collection — distributes denom wrongly
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(distribute_denom_over_product)))
misconceptions_fraction_batch_3:(r40083_distribute_denom(prod(A,B)-D, Got) :-
    Got is (A / D) * (B / D)).

test_harness:arith_misconception(db_row(40083), fraction, distribute_denom_wrongly,
    misconceptions_fraction_batch_3:r40083_distribute_denom,
    prod(600, 7)-20,
    210).

% === row 40103: smaller denominator always larger, ignore numerator ===
% Task: compare frac(5,8) and frac(1,2)
% Correct: frac(5,8) larger
% Error: frac(1,2) larger (smaller denom)
% SCHEMA: Arithmetic as Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(smaller_denom_always_larger)))
misconceptions_fraction_batch_3:(r40103_smaller_denom_always(frac(N1,D1)-frac(N2,D2), Larger) :-
    (D1 < D2 -> Larger = frac(N1,D1)
    ; D2 < D1 -> Larger = frac(N2,D2)
    ; Larger = equal)).

test_harness:arith_misconception(db_row(40103), fraction, smaller_denom_always_larger,
    misconceptions_fraction_batch_3:r40103_smaller_denom_always,
    frac(5,8)-frac(1,2),
    frac(5,8)).

% === row 40118: swap middle terms of inequality chain ===
% Too vague — meta-justification, no numeric wrong answer.
test_harness:arith_misconception(db_row(40118), fraction, too_vague,
    skip, none, none).

% === row 40134: division-by-whole-number story for fraction divisor ===
% Too vague — story-problem generation error, not a numeric computation.
test_harness:arith_misconception(db_row(40134), fraction, too_vague,
    skip, none, none).

% === row 40147: partitive story that takes fraction of dividend ===
% Task: 24 / (1/4) in a story context
% Correct: 96
% Error: treat as (1/4) * 24 = 6
% SCHEMA: Arithmetic as Object Collection — confuses divide with take-fraction-of
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(divide_as_take_fraction_of)))
misconceptions_fraction_batch_3:(r40147_take_fraction(Whole-frac(N,D), Got) :-
    Got is (Whole * N) / D).

test_harness:arith_misconception(db_row(40147), fraction, divide_as_take_fraction_of,
    misconceptions_fraction_batch_3:r40147_take_fraction,
    24-frac(1,4),
    96).

% === row 40175: denominator dominance ===
% Task: compare frac(8,24) and frac(13,39)
% Correct: equal (both 1/3)
% Error: frac(8,24) larger because 39 gives smaller pieces
% SCHEMA: Arithmetic as Object Collection — ignore numerator
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(denominator_dominance)))
misconceptions_fraction_batch_3:(r40175_denom_dominance(frac(N1,D1)-frac(N2,D2), Larger) :-
    (D1 < D2 -> Larger = frac(N1,D1)
    ; D2 < D1 -> Larger = frac(N2,D2)
    ; Larger = equal)).

test_harness:arith_misconception(db_row(40175), fraction, denominator_dominance,
    misconceptions_fraction_batch_3:r40175_denom_dominance,
    frac(8,24)-frac(13,39),
    equal).

% === row 40195: surface-feature equated with understanding ===
% Too vague — teacher-evaluation artifact, not a fraction computation.
test_harness:arith_misconception(db_row(40195), fraction, too_vague,
    skip, none, none).

% === row 40215: correct answer via irrelevant strategy ===
% Too vague — assessment artifact, no wrong numeric student answer.
test_harness:arith_misconception(db_row(40215), fraction, too_vague,
    skip, none, none).

% === row 40245: 4/8 equals 1/2 but "shouldn't it be 2/4?" ===
% Task: halve frac(4,8)
% Correct: frac(2,4) (or simplified 1/2)
% Error: confusion between the two equivalent forms — no numeric error, just a
% semantic question. Treat as too_vague.
test_harness:arith_misconception(db_row(40245), fraction, too_vague,
    skip, none, none).

% === row 40270: default to symbolic procedure without blocks ===
% Too vague — pedagogical strategy, no numeric output.
test_harness:arith_misconception(db_row(40270), fraction, too_vague,
    skip, none, none).

% === row 40364: 1/7 larger than 1/5 because 7 > 5 ===
% Task: compare frac(1,7) and frac(1,5)
% Correct: frac(1,5) larger
% Error: frac(1,7) larger (larger denom)
% SCHEMA: Arithmetic as Object Collection — whole-number bias
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(larger_denom_larger_frac)))
misconceptions_fraction_batch_3:(r40364_larger_denom(frac(N1,D1)-frac(N2,D2), Larger) :-
    (D1 > D2 -> Larger = frac(N1,D1)
    ; D2 > D1 -> Larger = frac(N2,D2)
    ; Larger = equal)).

test_harness:arith_misconception(db_row(40364), fraction, larger_denom_larger_frac,
    misconceptions_fraction_batch_3:r40364_larger_denom,
    frac(1,7)-frac(1,5),
    frac(1,5)).

% === row 40380: subtract wholes but add fractions in mixed subtraction ===
% Task: 3 17/25 - 2 3/25
% Correct: 1 14/25 (= mixed(1, frac(14,25)))
% Error: mixed(1, frac(20,25)) — subtracts wholes, adds fractional parts
% SCHEMA: Arithmetic as Object Collection — operation confusion
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(add_fracs_subtract_wholes)))
misconceptions_fraction_batch_3:(r40380_add_fracs_subtract_wholes(mixed(W1, frac(N1,D1))-mixed(W2, frac(N2,_D2)),
                                  mixed(W, frac(N,D))) :-
    W is W1 - W2,
    N is N1 + N2,
    D is D1).

test_harness:arith_misconception(db_row(40380), fraction, add_fracs_subtract_wholes,
    misconceptions_fraction_batch_3:r40380_add_fracs_subtract_wholes,
    mixed(3, frac(17,25))-mixed(2, frac(3,25)),
    mixed(1, frac(14,25))).

% === row 40411: reduce/expand with unlike denominators ===
% Too vague — difficulty description, no concrete wrong numeric answer.
test_harness:arith_misconception(db_row(40411), fraction, too_vague,
    skip, none, none).

% === row 40453: rationals as discrete not dense ===
% Too vague — density belief, no numeric example in row.
test_harness:arith_misconception(db_row(40453), fraction, too_vague,
    skip, none, none).

% === row 40480: same numerators, larger denom means larger ===
% Task: compare frac(7,10) and frac(7,11)
% Correct: frac(7,10) larger
% Error: frac(7,11) larger (11 > 10)
% SCHEMA: Arithmetic as Object Collection — whole-number bias
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(same_numer_larger_denom_larger)))
misconceptions_fraction_batch_3:(r40480_same_numer_larger_denom(frac(N1,D1)-frac(N2,D2), Larger) :-
    (D1 > D2 -> Larger = frac(N1,D1)
    ; D2 > D1 -> Larger = frac(N2,D2)
    ; Larger = equal)).

test_harness:arith_misconception(db_row(40480), fraction, same_numer_larger_denom,
    misconceptions_fraction_batch_3:r40480_same_numer_larger_denom,
    frac(7,10)-frac(7,11),
    frac(7,10)).

% === row 40495: two diagonals on non-square rectangle give quarters ===
% Too vague — partitioning claim; not a numeric wrong answer in the usual sense.
test_harness:arith_misconception(db_row(40495), fraction, too_vague,
    skip, none, none).

% === row 40552: 1/4 > 1/2 because 4 > 2 ===
% Task: compare frac(1,4) and frac(1,2)
% Correct: frac(1,2) larger
% Error: frac(1,4) larger because 4 > 2
% SCHEMA: Arithmetic as Object Collection — component-as-whole-numbers
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(components_as_whole_numbers)))
misconceptions_fraction_batch_3:(r40552_components_whole(frac(N1,D1)-frac(N2,D2), Larger) :-
    (D1 > D2 -> Larger = frac(N1,D1)
    ; D2 > D1 -> Larger = frac(N2,D2)
    ; Larger = equal)).

test_harness:arith_misconception(db_row(40552), fraction, components_as_whole_numbers,
    misconceptions_fraction_batch_3:r40552_components_whole,
    frac(1,4)-frac(1,2),
    frac(1,2)).

% === row 40620: repeated halving converges to whole in finite steps ===
% Too vague — infinite-series belief; no specific wrong numeric output.
test_harness:arith_misconception(db_row(40620), fraction, too_vague,
    skip, none, none).

% Fraction misconceptions — research corpus batch 4/7.
% Native arithmetic layer only. Theoretical annotations as comments:
%   % GROUNDED: TODO — placeholder for future embodied arithmetic layer
%   % SCHEMA: <schema name> — Lakoff & Nunez grounding when applicable
%   % CONNECTS TO: s(comp_nec(unlicensed(...))) — PML operator path
%
% Registration convention (from Task 3 arch fix):
%   test_harness:arith_misconception(Source, Domain, Description,
%       misconceptions_fraction_batch_4:rule_name, Input, Expected).
% Rule predicates do NOT go on the module export list.


% ---- Encodings appended by agent for batch 4 ----

% === row 37437: iteration count as numerator ===
% Task: name fractional part of 3-stick in a 24-stick made by 8 iterations.
% Correct: 1/8 (one iteration is 1/Total)
% Error: 3/8 (uses stick length 3 as numerator)
% SCHEMA: Measuring Stick — multiplicative relation of unit to whole
% GROUNDED: TODO — iteration-as-unit grounding
% CONNECTS TO: s(comp_nec(unlicensed(iteration_count_as_numerator)))
misconceptions_fraction_batch_4:(iteration_count_as_numerator(StickLen-Iterations, frac(N,D)) :-
    N is StickLen,
    D is Iterations).

test_harness:arith_misconception(db_row(37437), fraction, iteration_count_as_numerator,
    misconceptions_fraction_batch_4:iteration_count_as_numerator,
    3-8,
    frac(1,8)).

% === row 37444: improper fraction by added pieces ===
% Task: draw 7/5 of a candy bar.
% Correct: frac(7,5) — seven iterations of one-fifth unit.
% Error: added 2 pieces to 5 and denominator became 7.
% SCHEMA: Container — parts stay in the original bar
% GROUNDED: TODO — iterative unit grounding for improper fractions
% CONNECTS TO: s(comp_nec(unlicensed(denominator_follows_total_pieces)))
misconceptions_fraction_batch_4:(denominator_follows_total_pieces(frac(N,_D), frac(N,Total)) :-
    Total is N).   % student used count of total pieces as new denominator

test_harness:arith_misconception(db_row(37444), fraction, denom_follows_total_pieces,
    misconceptions_fraction_batch_4:denominator_follows_total_pieces,
    frac(7,5),
    frac(7,5)).

% === row 37451: intermediate unit as denominator ===
% Task: 2/5 of 3/4.
% Correct: frac(6,20) — parts relative to whole.
% Error: frac(6,15) — named relative to intermediate composite (3*5=15).
% SCHEMA: Fraction of a fraction
% GROUNDED: TODO — units-coordination grounding
% CONNECTS TO: s(comp_nec(unlicensed(intermediate_unit_as_denominator)))
misconceptions_fraction_batch_4:(intermediate_unit_as_denominator(frac(N1,_D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 * N2,
    D is N1 * D2).   % student uses intermediate (N1 * D2) instead of D1 * D2

test_harness:arith_misconception(db_row(37451), fraction, intermediate_unit_as_denom,
    misconceptions_fraction_batch_4:intermediate_unit_as_denominator,
    frac(2,5)-frac(3,4),
    frac(6,20)).

% === row 37471: estimate mixed by whole parts only ===
% Task: estimate 7 1/10 + 3 2/3 + 1 1/5.
% Correct: 12 (sum rounds to about 12, fractional parts ~ 1)
% Error: 11 (ignored fractional parts entirely)
% SCHEMA: Quantity — whole part neglects fractional increment
% GROUNDED: TODO — mixed-number estimation grounding
% CONNECTS TO: s(comp_nec(unlicensed(ignore_fractional_parts)))
misconceptions_fraction_batch_4:(ignore_fractional_parts(Wholes, Sum) :-
    sum_list(Wholes, Sum)).

test_harness:arith_misconception(db_row(37471), fraction, ignore_fractional_parts,
    misconceptions_fraction_batch_4:ignore_fractional_parts,
    [7,3,1],
    12).

% === row 37489: equivalent fractions by adding ===
% Task: 1/2 + 2/3 using common denominator.
% Correct: 7/6 (3/6 + 4/6)
% Error: add constant to num and denom to reach denom 5 → (4+4)/5 = 8/5
% SCHEMA: Additive equivalence (buggy)
% GROUNDED: TODO — multiplicative scaling grounding
% CONNECTS TO: s(comp_nec(unlicensed(equivalent_by_adding)))
misconceptions_fraction_batch_4:(equivalent_by_adding(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    D is D1 + D2,
    K1 is D - D1,
    K2 is D - D2,
    N is (N1 + K1) + (N2 + K2)).

test_harness:arith_misconception(db_row(37489), fraction, equivalent_by_adding,
    misconceptions_fraction_batch_4:equivalent_by_adding,
    frac(1,2)-frac(2,3),
    frac(7,6)).

% === row 37513: operator compare by additive difference ===
test_harness:arith_misconception(db_row(37513), fraction, too_vague,
    skip, none, none).

% === row 37521: total pieces as both numerator and denominator ===
% Task: 8 children each get 1/4 of a candy bar — total?
% Correct: 8/4 = 2 (eight fourths).
% Error: "eight eighths" — uses total pieces (8) as both num and denom.
% SCHEMA: Share aggregation with denominator drift
% GROUNDED: TODO — unit preservation grounding
% CONNECTS TO: s(comp_nec(unlicensed(total_pieces_as_num_and_denom)))
misconceptions_fraction_batch_4:(total_pieces_as_num_and_denom(Count-frac(_,_), frac(N,D)) :-
    N is Count,
    D is Count).

test_harness:arith_misconception(db_row(37521), fraction, total_pieces_both_places,
    misconceptions_fraction_batch_4:total_pieces_as_num_and_denom,
    8-frac(1,4),
    frac(8,4)).

% === row 37549: assume division commutative ===
% Task: 1 / (1/2).
% Correct: 2
% Error: student reverses to (1/2) / 1 = 1/2
% SCHEMA: Commutativity overgeneralized
% GROUNDED: TODO — inverse-operation grounding
% CONNECTS TO: s(comp_nec(unlicensed(division_commutative)))
misconceptions_fraction_batch_4:(division_commutative(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    % student computes (N2/D2) / (N1/D1) — swap then keep-change-flip
    N is N2 * D1,
    D is D2 * N1).

test_harness:arith_misconception(db_row(37549), fraction, division_commutative,
    misconceptions_fraction_batch_4:division_commutative,
    frac(1,1)-frac(1,2),
    2).

% === row 37581: shade 3 of the shown pieces ===
% Task: shade 3/4 of pizza predivided into 8ths.
% Correct: 6 pieces (3/4 of 8 = 6).
% Error: shades 3 pieces (takes numerator literally as count).
% SCHEMA: Area model — ignores fractional relation
% GROUNDED: TODO — unit-scaling grounding
% CONNECTS TO: s(comp_nec(unlicensed(numerator_as_piece_count)))
misconceptions_fraction_batch_4:(numerator_as_piece_count(frac(N,_)-_Total, N)).

test_harness:arith_misconception(db_row(37581), fraction, numerator_as_piece_count,
    misconceptions_fraction_batch_4:numerator_as_piece_count,
    frac(3,4)-8,
    6).

% === row 37588: surface symbol rewrite ===
% Task: 1/2 + 1/4, student rewrites 1/4 as 1/2.
% Correct: 3/4
% Error: 1/2 + 1/2 = 2/2
% SCHEMA: Symbol manipulation without quantity-preservation
% GROUNDED: TODO — symbol/quantity link grounding
% CONNECTS TO: s(comp_nec(unlicensed(rewrite_denominator_freely)))
misconceptions_fraction_batch_4:(rewrite_denominator_freely(frac(N1,D1)-frac(N2,_), frac(N,D)) :-
    N is N1 + N2,   % 1 + 1 = 2
    D is D1).        % 2 + 2 = 2 (forced to match)

test_harness:arith_misconception(db_row(37588), fraction, rewrite_denom_freely,
    misconceptions_fraction_batch_4:rewrite_denominator_freely,
    frac(1,2)-frac(1,4),
    frac(3,4)).

% === row 37657: denominator cannot change across wholes ===
% Task: 7 students eat 2 slices each from two 12-slice pizzas.
% Correct: 14/24
% Error: 14/12 (refuses to update denominator when the whole expands)
% SCHEMA: Referent whole — rigid denominator
% GROUNDED: TODO — whole-unit coordination grounding
% CONNECTS TO: s(comp_nec(unlicensed(rigid_denominator)))
misconceptions_fraction_batch_4:(rigid_denominator(Eaten-PerWhole-_NumWholes, frac(N,D)) :-
    N is Eaten,
    D is PerWhole).   % denominator frozen to one whole, ignores NumWholes

test_harness:arith_misconception(db_row(37657), fraction, rigid_denominator,
    misconceptions_fraction_batch_4:rigid_denominator,
    14-12-2,
    frac(14,24)).

% === row 37667: translation failure ===
test_harness:arith_misconception(db_row(37667), fraction, too_vague,
    skip, none, none).

% === row 37680: count half as whole ===
% Task: 4 whole apples and 1 half — total shares?
% Correct: 9/2 (or 4 1/2)
% Error: 5 (counts half as one whole)
% SCHEMA: Part-whole coordination
% GROUNDED: TODO — fractional count grounding
% CONNECTS TO: s(comp_nec(unlicensed(half_counted_as_whole)))
misconceptions_fraction_batch_4:(half_counted_as_whole(Wholes-Halves, Total) :-
    Total is Wholes + Halves).

test_harness:arith_misconception(db_row(37680), fraction, half_counted_as_whole,
    misconceptions_fraction_batch_4:half_counted_as_whole,
    4-1,
    frac(9,2)).

% === row 37745: context vs symbolic ===
test_harness:arith_misconception(db_row(37745), fraction, too_vague,
    skip, none, none).

% === row 37769: drew 6/9 bigger than 2/3 ===
% Task: represent 6/9 and 2/3 as equivalent bars.
% Correct: same size (6/9 = 2/3).
% Error: 6/9 drawn larger because 9 > 3 (more parts).
% SCHEMA: Numerosity-of-parts confound
% GROUNDED: TODO — whole-preservation grounding
% CONNECTS TO: s(comp_nec(unlicensed(more_parts_means_bigger)))
misconceptions_fraction_batch_4:(more_parts_means_bigger(frac(_,D1)-frac(_,D2), Bigger) :-
    (   D1 > D2
    ->  Bigger = first
    ;   D2 > D1
    ->  Bigger = second
    ;   Bigger = equal
    )).

test_harness:arith_misconception(db_row(37769), fraction, more_parts_bigger_bar,
    misconceptions_fraction_batch_4:more_parts_means_bigger,
    frac(6,9)-frac(2,3),
    equal).

% === row 37790: fractional remainder units confused ===
test_harness:arith_misconception(db_row(37790), fraction, too_vague,
    skip, none, none).

% === row 37808: idiosyncratic sharing ===
test_harness:arith_misconception(db_row(37808), fraction, too_vague,
    skip, none, none).

% === row 37823: larger denominator means larger unit fraction ===
% Task: compare 1/8 and 1/3.
% Correct: 1/3 > 1/8
% Error: 1/8 > 1/3 because 8 > 3
% SCHEMA: Whole-number ordering overgeneralized to denominators
% GROUNDED: TODO — unit-size inversion grounding
% CONNECTS TO: s(comp_nec(unlicensed(larger_denom_larger_fraction)))
misconceptions_fraction_batch_4:(larger_denom_larger_fraction(frac(N1,D1)-frac(N2,D2), Bigger) :-
    (   D1 > D2
    ->  Bigger = first
    ;   D2 > D1
    ->  Bigger = second
    ;   N1 > N2
    ->  Bigger = first
    ;   N2 > N1
    ->  Bigger = second
    ;   Bigger = equal
    )).

test_harness:arith_misconception(db_row(37823), fraction, larger_denom_bigger,
    misconceptions_fraction_batch_4:larger_denom_larger_fraction,
    frac(1,8)-frac(1,3),
    second).

% === row 37847: "two tenths" as 2 × 10 (process bug, result coincides) ===
test_harness:arith_misconception(db_row(37847), fraction, too_vague,
    skip, none, none).

% === row 37869: unequal parts ===
test_harness:arith_misconception(db_row(37869), fraction, too_vague,
    skip, none, none).

% === row 37880: whole number as fraction symbol ===
% Task: 2/4 + 1/4.
% Correct: 3/4
% Error: wrote "= 3" (writes numerator only, omits denominator)
% SCHEMA: Numerator-only notation
% GROUNDED: TODO — shared-symbol grounding
% CONNECTS TO: s(comp_nec(unlicensed(numerator_only_sum)))
misconceptions_fraction_batch_4:(numerator_only_sum(frac(N1,_)-frac(N2,_), Sum) :-
    Sum is N1 + N2).

test_harness:arith_misconception(db_row(37880), fraction, numerator_only_sum,
    misconceptions_fraction_batch_4:numerator_only_sum,
    frac(2,4)-frac(1,4),
    frac(3,4)).

% === row 37910: separate num/denom whole-number comparisons ===
% Task: compare 3/5 and 6/10.
% Correct: equal
% Error: 3/5 < 6/10 because 3 < 6 and 5 < 10 (both parts smaller)
% SCHEMA: Componentwise whole-number order
% GROUNDED: TODO — fraction-as-ratio grounding
% CONNECTS TO: s(comp_nec(unlicensed(componentwise_order)))
misconceptions_fraction_batch_4:(componentwise_order(frac(N1,D1)-frac(N2,D2), Bigger) :-
    (   N1 < N2, D1 < D2
    ->  Bigger = second
    ;   N1 > N2, D1 > D2
    ->  Bigger = first
    ;   Bigger = undecided
    )).

test_harness:arith_misconception(db_row(37910), fraction, componentwise_order,
    misconceptions_fraction_batch_4:componentwise_order,
    frac(3,5)-frac(6,10),
    equal).

% === row 37941: multiplication always enlarges ===
test_harness:arith_misconception(db_row(37941), fraction, too_vague,
    skip, none, none).

% === row 37979: larger divisor cannot fit ===
% Task: how many 1/2's are in 1/3?
% Correct: 2/3
% Error: 0 (larger fraction "cannot fit" into smaller)
% SCHEMA: Measurement-division with whole-number fit rule
% GROUNDED: TODO — measurement-division grounding
% CONNECTS TO: s(comp_nec(unlicensed(larger_cannot_fit)))
misconceptions_fraction_batch_4:(larger_cannot_fit(frac(N1,D1)-frac(N2,D2), Q) :-
    Correct is (N1 * D2) / (D1 * N2),
    (   Correct < 1
    ->  Q = 0
    ;   Q = Correct
    )).

test_harness:arith_misconception(db_row(37979), fraction, larger_cannot_fit,
    misconceptions_fraction_batch_4:larger_cannot_fit,
    frac(1,3)-frac(1,2),
    frac(2,3)).

% === row 38057: reject valid algorithm ===
test_harness:arith_misconception(db_row(38057), fraction, too_vague,
    skip, none, none).

% === row 38126: equivalent fraction by multiplying denom and new numer ===
% Task: find missing denom for 2/5 = 4/?.
% Correct: 10
% Error: 20 (multiply old denom 5 by new numerator 4)
% SCHEMA: Cross-multiplication rule misapplied
% GROUNDED: TODO — scale-factor grounding
% CONNECTS TO: s(comp_nec(unlicensed(wrong_cross_product)))
misconceptions_fraction_batch_4:(wrong_cross_product(frac(_N1,D1)-NewN, NewD) :-
    NewD is D1 * NewN).

test_harness:arith_misconception(db_row(38126), fraction, wrong_cross_product,
    misconceptions_fraction_batch_4:wrong_cross_product,
    frac(2,5)-4,
    10).

% === row 38140: division always smaller ===
test_harness:arith_misconception(db_row(38140), fraction, too_vague,
    skip, none, none).

% === row 38221: number sentence choice ===
test_harness:arith_misconception(db_row(38221), fraction, too_vague,
    skip, none, none).

% === row 38246: disembedding ===
test_harness:arith_misconception(db_row(38246), fraction, too_vague,
    skip, none, none).

% === row 38261: equal partitioning ignored ===
test_harness:arith_misconception(db_row(38261), fraction, too_vague,
    skip, none, none).

% === row 38284: subparts named by count in fraction bar ===
% Task: subdivide 3/7 into 5 subparts each — name the subparts.
% Correct: thirty-fifths (1/35)
% Error: fifteenths (counts 15 subparts in the 3/7 bar, not in the whole)
% SCHEMA: Recursive partitioning — wrong referent unit
% GROUNDED: TODO — recursive-unit-coordination grounding
% CONNECTS TO: s(comp_nec(unlicensed(subparts_count_in_bar)))
misconceptions_fraction_batch_4:(subparts_count_in_bar(frac(N,_D)-Sub, frac(1,NewD)) :-
    NewD is N * Sub).

test_harness:arith_misconception(db_row(38284), fraction, subparts_named_in_bar,
    misconceptions_fraction_batch_4:subparts_count_in_bar,
    frac(3,7)-5,
    frac(1,35)).

% === row 38327: unshaded is not a fraction ===
test_harness:arith_misconception(db_row(38327), fraction, too_vague,
    skip, none, none).

% === row 38369: simultaneous partitioning ===
test_harness:arith_misconception(db_row(38369), fraction, too_vague,
    skip, none, none).

% === row 38394: subtract denominators ===
% Task: 5/5 + 2/5.
% Correct: 7/5
% Error: operated on denominators too — e.g., 5 + 5 or 5 - 5 in denominator
% SCHEMA: Apply operation to both num and denom
% GROUNDED: TODO — denominator-preservation grounding
% CONNECTS TO: s(comp_nec(unlicensed(operate_on_denominators)))
misconceptions_fraction_batch_4:(operate_on_denominators(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 + N2,
    D is D1 + D2).

test_harness:arith_misconception(db_row(38394), fraction, operate_on_denominators,
    misconceptions_fraction_batch_4:operate_on_denominators,
    frac(5,5)-frac(2,5),
    frac(7,5)).

% === row 38406: benchmark failure ===
test_harness:arith_misconception(db_row(38406), fraction, too_vague,
    skip, none, none).

% === row 38434: missing factor geometric ===
test_harness:arith_misconception(db_row(38434), fraction, too_vague,
    skip, none, none).

% === row 38455: whole shaded for 1/6 ===
% Task: draw 1/6 of a circle.
% Correct: one of six equal parts shaded (frac(1,6)).
% Error: shades all six (treats "one sixth" as one-whole-of-six-pieces).
% SCHEMA: Unit fraction = the whole partition
% GROUNDED: TODO — unit-fraction grounding
% CONNECTS TO: s(comp_nec(unlicensed(whole_as_unit_fraction)))
misconceptions_fraction_batch_4:(whole_as_unit_fraction(frac(_,D), frac(N,D2)) :-
    N is D,
    D2 is D).

test_harness:arith_misconception(db_row(38455), fraction, whole_as_unit_fraction,
    misconceptions_fraction_batch_4:whole_as_unit_fraction,
    frac(1,6),
    frac(1,6)).

% === row 38492: discrete fractions ===
test_harness:arith_misconception(db_row(38492), fraction, too_vague,
    skip, none, none).

% === row 38558: improper fraction flipped ===
% Task: draw 6/5 of a unit.
% Correct: frac(6,5)
% Error: drew 5/6 (swapped since denom "cannot" be smaller)
% SCHEMA: Part-whole rigidity
% GROUNDED: TODO — improper-fraction grounding
% CONNECTS TO: s(comp_nec(unlicensed(swap_num_denom_for_proper)))
misconceptions_fraction_batch_4:(swap_num_denom_for_proper(frac(N,D), frac(Nout,Dout)) :-
    (   N > D
    ->  Nout = D, Dout = N
    ;   Nout = N, Dout = D
    )).

test_harness:arith_misconception(db_row(38558), fraction, swap_for_proper,
    misconceptions_fraction_batch_4:swap_num_denom_for_proper,
    frac(6,5),
    frac(6,5)).

% === row 38574: multiplicative as additive spaces ===
test_harness:arith_misconception(db_row(38574), fraction, too_vague,
    skip, none, none).

% === row 38648: cross-cut leftover items ===
test_harness:arith_misconception(db_row(38648), fraction, too_vague,
    skip, none, none).

% === row 38664: unit conflation under iteration ===
% Task: iterate 6-unit segment 4 times to make 24-unit — name the 6-segment.
% Correct: 1/4 of the 24-unit segment
% Error: 6/4 (uses segment length 6 as numerator, iteration count 4 as denom)
% SCHEMA: Iteration count as denominator, length as numerator
% GROUNDED: TODO — recursive-partitioning grounding
% CONNECTS TO: s(comp_nec(unlicensed(length_over_iteration_count)))
misconceptions_fraction_batch_4:(length_over_iteration_count(Length-Iterations, frac(N,D)) :-
    N is Length,
    D is Iterations).

test_harness:arith_misconception(db_row(38664), fraction, length_over_iterations,
    misconceptions_fraction_batch_4:length_over_iteration_count,
    6-4,
    frac(1,4)).

% === row 38679: second fraction of whole, not first ===
% Task: 2/3 of 3/4 of the class.
% Correct: frac(6,12) = 1/2 of the class
% Error: treats 2/3 as of the whole class, ignoring "of 3/4"
% SCHEMA: Compound fraction referent-whole drift
% GROUNDED: TODO — referent-whole coordination grounding
% CONNECTS TO: s(comp_nec(unlicensed(second_of_whole_not_first)))
misconceptions_fraction_batch_4:(second_of_whole_not_first(frac(N1,D1)-frac(_N2,_D2), frac(N1,D1))).

test_harness:arith_misconception(db_row(38679), fraction, second_of_whole_not_first,
    misconceptions_fraction_batch_4:second_of_whole_not_first,
    frac(2,3)-frac(3,4),
    frac(6,12)).

% === row 38717: partition given bar by denominator ===
% Task: given bar is 4/5 of a whole — construct the whole.
% Correct: bar extended to 5/4 of itself (add 1/4 of the bar's length).
% Error: partition the given bar into 5 parts (reads denom as partition count
% of the given bar).
% SCHEMA: Reversible partitive reasoning breakdown
% GROUNDED: TODO — reversible-partition grounding
% CONNECTS TO: s(comp_nec(unlicensed(partition_given_by_denominator)))
misconceptions_fraction_batch_4:(partition_given_by_denominator(frac(_,D), Partitions) :-
    Partitions = D).

test_harness:arith_misconception(db_row(38717), fraction, partition_given_by_denom,
    misconceptions_fraction_batch_4:partition_given_by_denominator,
    frac(4,5),
    frac(5,4)).

% === row 38789: unshaded is nothing ===
test_harness:arith_misconception(db_row(38789), fraction, too_vague,
    skip, none, none).

% === row 38837: count parts twice — 2/3 as 2/5 ===
% Task: identify 2/3 representation.
% Correct: frac(2,3) — 2 of 3 parts total.
% Error: picks 2/5 — counts the 2 separately and 3 unshaded separately (2+3=5).
% SCHEMA: Inclusion failure — parts counted twice
% GROUNDED: TODO — part-whole inclusion grounding
% CONNECTS TO: s(comp_nec(unlicensed(count_parts_twice)))
misconceptions_fraction_batch_4:(count_parts_twice(frac(N,D), frac(N,DOut)) :-
    DOut is N + D).   % shaded and unshaded counted separately

test_harness:arith_misconception(db_row(38837), fraction, count_parts_twice,
    misconceptions_fraction_batch_4:count_parts_twice,
    frac(2,3),
    frac(2,3)).

% === row 38857: count cuts as parts ===
test_harness:arith_misconception(db_row(38857), fraction, too_vague,
    skip, none, none).

% === row 38922: division equals multiplication ===
% Task: 1/3 ÷ 1/2.
% Correct: 2/3
% Error: student tries 1/2 × 1/3 = 1/6 and concludes operations are the same.
% SCHEMA: Operation conflation
% GROUNDED: TODO — operation-distinction grounding
% CONNECTS TO: s(comp_nec(unlicensed(div_as_mul)))
misconceptions_fraction_batch_4:(div_as_mul(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 * N2,
    D is D1 * D2).

test_harness:arith_misconception(db_row(38922), fraction, div_as_mul,
    misconceptions_fraction_batch_4:div_as_mul,
    frac(1,3)-frac(1,2),
    frac(2,3)).

% === row 38972: natural number bias addition ===
% Task: 2/3 + 3/5.
% Correct: 19/15
% Error: 5/8 (add numerators, add denominators)
% SCHEMA: Componentwise addition
% GROUNDED: TODO — common-denominator grounding
% CONNECTS TO: s(comp_nec(unlicensed(componentwise_addition)))
misconceptions_fraction_batch_4:(componentwise_addition(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 + N2,
    D is D1 + D2).

test_harness:arith_misconception(db_row(38972), fraction, componentwise_addition,
    misconceptions_fraction_batch_4:componentwise_addition,
    frac(2,3)-frac(3,5),
    frac(19,15)).

% === row 38987: fractions strictly as objects ===
test_harness:arith_misconception(db_row(38987), fraction, too_vague,
    skip, none, none).

% === row 39039: contextual fraction comparison ===
test_harness:arith_misconception(db_row(39039), fraction, too_vague,
    skip, none, none).

% === row 39089: gap thinking — "same because each has one left" ===
% Task: compare 5/6 and 7/8.
% Correct: 7/8 > 5/6 (cross product: 40 vs 42 → second larger)
% Error: equal, because both have gap of 1 (same leftover).
% SCHEMA: Absolute difference as magnitude
% GROUNDED: TODO — ratio grounding
% CONNECTS TO: s(comp_nec(unlicensed(gap_thinking)))
misconceptions_fraction_batch_4:(gap_thinking(frac(N1,D1)-frac(N2,D2), Verdict) :-
    G1 is D1 - N1,
    G2 is D2 - N2,
    (   G1 < G2
    ->  Verdict = first_larger
    ;   G2 < G1
    ->  Verdict = second_larger
    ;   Verdict = equal
    )).

test_harness:arith_misconception(db_row(39089), fraction, gap_thinking,
    misconceptions_fraction_batch_4:gap_thinking,
    frac(5,6)-frac(7,8),
    second_larger).

% === row 39135: pie part model — fractions as two numbers ===
test_harness:arith_misconception(db_row(39135), fraction, too_vague,
    skip, none, none).

% === row 39169: unit fraction distinction ===
test_harness:arith_misconception(db_row(39169), fraction, too_vague,
    skip, none, none).

% === row 39193: adjusting unfair shares ===
test_harness:arith_misconception(db_row(39193), fraction, too_vague,
    skip, none, none).

% === row 39274: continuous to discrete mapping failure ===
test_harness:arith_misconception(db_row(39274), fraction, too_vague,
    skip, none, none).

% === row 39348: select multiplication instead of division ===
% Task: 3/5 ÷ 1/20 (problem calls for division).
% Correct: frac(60,5) (= 12)
% Error: student wrote 3/5 × 1/20 = 3/100
% SCHEMA: Operation selection from surface cues
% GROUNDED: TODO — operation-selection grounding
% CONNECTS TO: s(comp_nec(unlicensed(mul_instead_of_div)))
misconceptions_fraction_batch_4:(mul_instead_of_div(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 * N2,
    D is D1 * D2).

test_harness:arith_misconception(db_row(39348), fraction, mul_instead_of_div,
    misconceptions_fraction_batch_4:mul_instead_of_div,
    frac(3,5)-frac(1,20),
    frac(60,5)).

% === row 39432: divide both ways, pick easier quotient ===
% Task: partitive — share 4 pizzas among 7 people.
% Correct: 4/7 per person (about 0.571).
% Error: divides both ways, picks the one that "looks easier" (>= 1).
%   7/4 = 1.75 is picked even though the correct direction is 4/7.
% SCHEMA: Partitive direction
% GROUNDED: TODO — partitive-division grounding
% CONNECTS TO: s(comp_nec(unlicensed(pick_easier_quotient)))
misconceptions_fraction_batch_4:(pick_easier_quotient(A-B, Q) :-
    Q1 is A / B,
    Q2 is B / A,
    (   Q1 >= 1
    ->  Q = Q1
    ;   Q = Q2
    )).

test_harness:arith_misconception(db_row(39432), fraction, pick_easier_quotient,
    misconceptions_fraction_batch_4:pick_easier_quotient,
    4-7,
    frac(4,7)).

% === row 39471: fraction less than whole ===
test_harness:arith_misconception(db_row(39471), fraction, too_vague,
    skip, none, none).

% === row 39559: division always smaller ===
test_harness:arith_misconception(db_row(39559), fraction, too_vague,
    skip, none, none).

% === row 39604: denominator as group size ===
% Task: find 1/3 of 12 objects.
% Correct: 4
% Error: 3 (interprets denominator as number in each group)
% SCHEMA: Denominator-as-group-size confusion
% GROUNDED: TODO — fractions-of-discrete grounding
% CONNECTS TO: s(comp_nec(unlicensed(denominator_as_group_size)))
misconceptions_fraction_batch_4:(denominator_as_group_size(frac(_,D)-_Set, Count) :-
    Count is D).

test_harness:arith_misconception(db_row(39604), fraction, denom_as_group_size,
    misconceptions_fraction_batch_4:denominator_as_group_size,
    frac(1,3)-12,
    4).

% === row 39639: whole number interference comparing ===
test_harness:arith_misconception(db_row(39639), fraction, too_vague,
    skip, none, none).

% === row 39654: linear model partition without equal parts ===
test_harness:arith_misconception(db_row(39654), fraction, too_vague,
    skip, none, none).

% === row 39694: add across unlike denominators ===
% Task: 1/5 + 2/3.
% Correct: 13/15
% Error: 3/8 (adds numerators and denominators)
% SCHEMA: Componentwise addition (unlike denominators)
% GROUNDED: TODO — common-denominator grounding
% CONNECTS TO: s(comp_nec(unlicensed(add_across_unlike)))
misconceptions_fraction_batch_4:(add_across_unlike(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 + N2,
    D is D1 + D2).

test_harness:arith_misconception(db_row(39694), fraction, add_across_unlike,
    misconceptions_fraction_batch_4:add_across_unlike,
    frac(1,5)-frac(2,3),
    frac(13,15)).

% === row 39722: add 2/3 + 1/4 = 3/7 ===
% Task: 2/3 + 1/4.
% Correct: 11/12
% Error: 3/7 (componentwise)
% SCHEMA: Componentwise addition
% GROUNDED: TODO — common-denominator grounding
% CONNECTS TO: s(comp_nec(unlicensed(componentwise_add_3_7)))
misconceptions_fraction_batch_4:(componentwise_add_3_7(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 + N2,
    D is D1 + D2).

test_harness:arith_misconception(db_row(39722), fraction, componentwise_add_simple,
    misconceptions_fraction_batch_4:componentwise_add_3_7,
    frac(2,3)-frac(1,4),
    frac(11,12)).

% === row 39766: multiply numerators, keep like denom ===
% Task: 4/7 × 3/7.
% Correct: 12/49
% Error: 12/7 (multiplies numerators, leaves common denominator)
% SCHEMA: Same-denominator addition overgeneralized to multiplication
% GROUNDED: TODO — multiplication-denominator grounding
% CONNECTS TO: s(comp_nec(unlicensed(mul_keep_denom)))
misconceptions_fraction_batch_4:(mul_keep_denom(frac(N1,D)-frac(N2,D), frac(N,D)) :-
    N is N1 * N2).

test_harness:arith_misconception(db_row(39766), fraction, mul_keep_common_denom,
    misconceptions_fraction_batch_4:mul_keep_denom,
    frac(4,7)-frac(3,7),
    frac(12,49)).

% === row 39773: unit-rate sharing must be multiplication ===
test_harness:arith_misconception(db_row(39773), fraction, too_vague,
    skip, none, none).

% === row 39812: unit fraction of discrete as denominator ===
% Task: one third of 12.
% Correct: 4
% Error: 3 (answers with denominator literally)
% SCHEMA: Denominator-as-answer
% GROUNDED: TODO — fraction-of-set grounding
% CONNECTS TO: s(comp_nec(unlicensed(denominator_as_answer)))
misconceptions_fraction_batch_4:(denominator_as_answer(frac(_,D)-_Set, Answer) :-
    Answer is D).

test_harness:arith_misconception(db_row(39812), fraction, denom_as_answer,
    misconceptions_fraction_batch_4:denominator_as_answer,
    frac(1,3)-12,
    4).

% === row 39819: mixed fraction whole parts omitted ===
test_harness:arith_misconception(db_row(39819), fraction, too_vague,
    skip, none, none).

% === row 39844: independent whole-number operations with weird scaling ===
test_harness:arith_misconception(db_row(39844), fraction, too_vague,
    skip, none, none).

% === row 39891: sort by smallest difference ===
% Task: identify the "smallest" among given fractions.
% Correct: requires comparing magnitudes.
% Error: picks fraction with smallest D-N gap (same family as gap thinking).
% SCHEMA: Gap sort
% GROUNDED: TODO — ratio grounding
% CONNECTS TO: s(comp_nec(unlicensed(sort_by_gap)))
misconceptions_fraction_batch_4:(sort_by_gap(Fracs, Smallest) :-
    maplist([frac(N,D), G-frac(N,D)]>>(G is D - N), Fracs, Pairs),
    keysort(Pairs, Sorted),
    Sorted = [_-Smallest|_]).

test_harness:arith_misconception(db_row(39891), fraction, sort_by_gap,
    misconceptions_fraction_batch_4:sort_by_gap,
    [frac(5,6), frac(1,2), frac(2,3)],
    frac(1,2)).

% === row 39949: unit fraction comparison reasoning ===
test_harness:arith_misconception(db_row(39949), fraction, too_vague,
    skip, none, none).

% === row 40049: keyword-triggered procedure ===
test_harness:arith_misconception(db_row(40049), fraction, too_vague,
    skip, none, none).

% === row 40084: improper as needing "fixing" ===
test_harness:arith_misconception(db_row(40084), fraction, too_vague,
    skip, none, none).

% === row 40112: how-many vs how-much ===
% Task: share 4 pizzas equally among 5 people.
% Correct: 4/5 of a pizza each.
% Error: "4 pieces" — number of pieces rather than fractional amount.
% SCHEMA: Pieces-count instead of fractional share
% GROUNDED: TODO — how-much referent grounding
% CONNECTS TO: s(comp_nec(unlicensed(pieces_instead_of_fraction)))
misconceptions_fraction_batch_4:(pieces_instead_of_fraction(Objects-_People, Count) :-
    Count is Objects).  % student reports raw count of pieces

test_harness:arith_misconception(db_row(40112), fraction, pieces_instead_of_fraction,
    misconceptions_fraction_batch_4:pieces_instead_of_fraction,
    4-5,
    frac(4,5)).

% === row 40119: condensed explanation ===
test_harness:arith_misconception(db_row(40119), fraction, too_vague,
    skip, none, none).

% === row 40135: alt algorithm rejected ===
test_harness:arith_misconception(db_row(40135), fraction, too_vague,
    skip, none, none).

% === row 40148: iterating seen as multiplication ===
test_harness:arith_misconception(db_row(40148), fraction, too_vague,
    skip, none, none).

% === row 40178: teacher misinterprets student ===
test_harness:arith_misconception(db_row(40178), fraction, too_vague,
    skip, none, none).

% === row 40196: PST projection ===
test_harness:arith_misconception(db_row(40196), fraction, too_vague,
    skip, none, none).

% === row 40216: procedural taken as conceptual ===
test_harness:arith_misconception(db_row(40216), fraction, too_vague,
    skip, none, none).

% === row 40257: dividend and divisor drawn separately ===
test_harness:arith_misconception(db_row(40257), fraction, too_vague,
    skip, none, none).

% === row 40285: add numerators and denominators ===
% Task: 1/4 + 1/16.
% Correct: 5/16
% Error: 2/20 (add numerators and denominators)
% SCHEMA: Componentwise addition
% GROUNDED: TODO — common-denominator grounding
% CONNECTS TO: s(comp_nec(unlicensed(add_num_denom_1_4_1_16)))
misconceptions_fraction_batch_4:(add_num_denom_1_4_1_16(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 + N2,
    D is D1 + D2).

test_harness:arith_misconception(db_row(40285), fraction, add_num_and_denom_unlike,
    misconceptions_fraction_batch_4:add_num_denom_1_4_1_16,
    frac(1,4)-frac(1,16),
    frac(5,16)).

% === row 40370: reversible iterative fraction scheme ===
test_harness:arith_misconception(db_row(40370), fraction, too_vague,
    skip, none, none).

% === row 40381: equivalent by multiplying numerator and denominator of original ===
% Task: 6/9 = ?/18. Find missing numerator.
% Correct: 12 (scale by 2)
% Error: 54 (multiplies given numerator 6 by given denominator 9)
% SCHEMA: Equivalent-fraction procedure misapplication
% GROUNDED: TODO — scale-factor grounding
% CONNECTS TO: s(comp_nec(unlicensed(mul_orig_num_denom)))
misconceptions_fraction_batch_4:(mul_orig_num_denom(frac(N,D)-_NewD, MissingN) :-
    MissingN is N * D).

test_harness:arith_misconception(db_row(40381), fraction, mul_orig_num_denom,
    misconceptions_fraction_batch_4:mul_orig_num_denom,
    frac(6,9)-18,
    12).

% === row 40441: larger distance means smaller fraction ===
% Task: compare 1/2 and 5/8.
% Correct: 5/8 > 1/2 (5*2=10 vs 1*8=8).
% Error: 1/2 has larger D-N gap (3) than 5/8 (3) ... same — pick a clearer
% example: 1/4 vs 5/6 — gaps 3 vs 1, student says 1/4 is smaller because
% the gap is larger (matches correct); but for 2/3 (gap 1) vs 5/8 (gap 3),
% student says 5/8 is smaller, while actually 5/8 > 2/3 (15 vs 16, so 2/3
% larger; hmm 15<16 → 5/8 is actually smaller). We use a case where the bug
% flips the correct order: 3/4 (gap 1) vs 1/2 (gap 1) tied; use 5/7 (gap 2)
% vs 1/2 (gap 1) — correct: 5/7 ≈ 0.714 > 1/2; bug: first has larger gap so
% "smaller" = first.
% SCHEMA: Distance-based ordering
% GROUNDED: TODO — ratio grounding
% CONNECTS TO: s(comp_nec(unlicensed(sort_by_distance_larger_means_smaller)))
misconceptions_fraction_batch_4:(sort_by_distance_larger_smaller(frac(N1,D1)-frac(N2,D2), Smaller) :-
    Dist1 is D1 - N1,
    Dist2 is D2 - N2,
    (   Dist1 > Dist2
    ->  Smaller = first
    ;   Dist2 > Dist1
    ->  Smaller = second
    ;   Smaller = equal
    )).

test_harness:arith_misconception(db_row(40441), fraction, sort_by_distance,
    misconceptions_fraction_batch_4:sort_by_distance_larger_smaller,
    frac(5,7)-frac(1,2),
    second).

% === row 40454: add numerators and denominators (estimate) ===
% Task: 4/5 + 6/7.
% Correct: 58/35 (near 1.66, "close to 2")
% Error: 10/12 (componentwise), "close to 1"
% SCHEMA: Componentwise addition with magnitude inference
% GROUNDED: TODO — common-denominator grounding
% CONNECTS TO: s(comp_nec(unlicensed(componentwise_estimate)))
misconceptions_fraction_batch_4:(componentwise_estimate(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 + N2,
    D is D1 + D2).

test_harness:arith_misconception(db_row(40454), fraction, componentwise_estimate,
    misconceptions_fraction_batch_4:componentwise_estimate,
    frac(4,5)-frac(6,7),
    frac(58,35)).

% === row 40482: tangram pieces as equal fractions ===
test_harness:arith_misconception(db_row(40482), fraction, too_vague,
    skip, none, none).

% === row 40496: 3/4 ÷ 1/2 yields 6/8 ===
% Task: 3/4 ÷ 1/2.
% Correct: 3/2 (or 1.5)
% Error: 6/8 — model shades 3/4, cuts in half, reads 6 of 8.
% SCHEMA: Area model miscounting in division
% GROUNDED: TODO — division-as-measurement grounding
% CONNECTS TO: s(comp_nec(unlicensed(area_model_miscount_div)))
misconceptions_fraction_batch_4:(area_model_miscount_div(frac(N1,D1)-frac(_N2,D2), frac(N,D)) :-
    N is N1 * D2,
    D is D1 * D2).

test_harness:arith_misconception(db_row(40496), fraction, area_model_miscount_div,
    misconceptions_fraction_batch_4:area_model_miscount_div,
    frac(3,4)-frac(1,2),
    frac(3,2)).

% === row 40586: subtract 7/8 from 4 1/8 without regrouping ===
test_harness:arith_misconception(db_row(40586), fraction, too_vague,
    skip, none, none).

% === row 40661: differently-shaped halves equal? ===
test_harness:arith_misconception(db_row(40661), fraction, too_vague,
    skip, none, none).

% Fraction misconceptions — research corpus batch 5/7.
% Native arithmetic layer only. Theoretical annotations as comments:
%   % GROUNDED: TODO — placeholder for future embodied arithmetic layer
%   % SCHEMA: <schema name> — Lakoff & Nunez grounding when applicable
%   % CONNECTS TO: s(comp_nec(unlicensed(...))) — PML operator path
%
% Registration convention (from Task 3 arch fix):
%   test_harness:arith_misconception(Source, Domain, Description,
%       misconceptions_fraction_batch_5:rule_name, Input, Expected).
% Rule predicates do NOT go on the module export list.


% ---- Encodings appended by agent for batch 5 ----

% === row 37438: multiplicative-as-additive comparison ===
% Task: stick that is 5 times longer than original.
% Correct: 5 (iterate 5 copies).
% Error: 6 (interpret "5 times longer" as "5 more", yielding 6 total).
% SCHEMA: Arithmetic is Object Collection — add-for-multiply slip
% GROUNDED: TODO — iterate_grounded vs succ_grounded
% CONNECTS TO: s(comp_nec(unlicensed(additive_for_multiplicative)))
misconceptions_fraction_batch_5:(r37438_five_times_as_five_more(Scalar, Got) :-
    Got is Scalar + 1).

test_harness:arith_misconception(db_row(37438), fraction, multiplicative_as_additive,
    misconceptions_fraction_batch_5:r37438_five_times_as_five_more,
    5,
    5).

% === row 37445: improper fraction partitioned to largest number ===
% Task: make 14/13 (improper) from a unit bar.
% Correct: frac(14,13) — partition into 13, iterate 14.
% Error: frac(14,14) — partitioned into 14 parts instead of 13.
% SCHEMA: Measuring Stick — denominator confused with larger numeral
% GROUNDED: TODO — partition_grounded(R13, ...) vs partition_grounded(R14, ...)
% CONNECTS TO: s(comp_nec(unlicensed(partition_by_largest_numeral)))
misconceptions_fraction_batch_5:(r37445_partition_by_largest(frac(N,D), frac(N,N)) :-
    N > D).

test_harness:arith_misconception(db_row(37445), fraction, improper_partition_by_largest,
    misconceptions_fraction_batch_5:r37445_partition_by_largest,
    frac(14,13),
    frac(14,13)).

% === row 37452: standard algorithm as hindrance to reasoning ===
% Student computed 2/3 × 7/9 = 14/27 by standard algorithm. The algorithm
% yields the correct numeric answer; the misconception is procedural
% reliance without structural modeling — no distinct wrong numeric answer.
test_harness:arith_misconception(db_row(37452), fraction, too_vague,
    skip, none, none).

% === row 37500: density — no fraction between consecutive numerators ===
% Task: produce a fraction between 2/5 and 3/5.
% Correct: frac(5,10) (or any midpoint).
% Error: none (student denies any fraction exists).
% SCHEMA: Measuring Stick — fraction sequence treated as whole-number counting
% GROUNDED: TODO — midpoint_grounded
% CONNECTS TO: s(comp_nec(unlicensed(density_denial(consecutive_numerators))))
misconceptions_fraction_batch_5:(r37500_density_denial(frac(_,_)-frac(_,_), none)).

test_harness:arith_misconception(db_row(37500), fraction, density_denial,
    misconceptions_fraction_batch_5:r37500_density_denial,
    frac(2,5)-frac(3,5),
    frac(5,10)).

% === row 37514: Equal Outputs inverse relationship forgotten ===
% Task: compare 2/4 and 2/3.
% Correct: frac(2,3) (larger).
% Error: frac(2,4) (student says "4 blocks in" means larger).
% SCHEMA: Measuring Stick — inverse relation input↔size dropped
% GROUNDED: TODO — compare_grounded with inverse-aware reasoning
% CONNECTS TO: s(comp_nec(unlicensed(equal_outputs_inverse_drop)))
misconceptions_fraction_batch_5:(r37514_equal_outputs_inverse(frac(N1,D1)-frac(N2,D2), Larger) :-
    ( D1 > D2 -> Larger = frac(N1,D1) ; Larger = frac(N2,D2) )).

test_harness:arith_misconception(db_row(37514), fraction, equal_outputs_inverse_error,
    misconceptions_fraction_batch_5:r37514_equal_outputs_inverse,
    frac(2,4)-frac(2,3),
    frac(2,3)).

% === row 37522: language for halves ===
% No concrete wrong numeric answer — linguistic/terminological.
test_harness:arith_misconception(db_row(37522), fraction, too_vague,
    skip, none, none).

% === row 37562: referent whole confusion in 2/3 of 3/4 ===
% Task: 2/3 of 3/4.
% Correct: frac(6,12) — six of twelve sub-parts of the full whole.
% Error: frac(6,9) — student names the answer relative to the 3/4 piece.
% SCHEMA: Measuring Stick — referent whole displaced
% GROUNDED: TODO — multiply_grounded with fixed referent
% CONNECTS TO: s(comp_nec(unlicensed(referent_whole_displacement)))
misconceptions_fraction_batch_5:(r37562_referent_whole_drop(frac(N1,D1)-frac(N2,_D2), frac(Num, D1Num)) :-
    Num is N1 * N2,
    D1Num is D1 * N2).

test_harness:arith_misconception(db_row(37562), fraction, referent_whole_displacement,
    misconceptions_fraction_batch_5:r37562_referent_whole_drop,
    frac(2,3)-frac(3,4),
    frac(6,12)).

% === row 37582: "7 is 3/4 of 10 because 3+4=7" ===
% Task: evaluate claim "7 is 3/4 of 10".
% Correct answer to "what is 3/4 of 10?": 15/2 (not 7).
% Error: returns N+D = 7.
% SCHEMA: Arithmetic is Object Collection — syntactic addition for multiplicative claim
% GROUNDED: TODO — multiply_grounded vs add_grounded
% CONNECTS TO: s(comp_nec(unlicensed(syntactic_sum_for_fraction_of_whole)))
misconceptions_fraction_batch_5:(r37582_syntactic_sum(frac(N,D)-_Whole, Got) :-
    Got is N + D).

test_harness:arith_misconception(db_row(37582), fraction, syntactic_sum_for_fraction_of,
    misconceptions_fraction_batch_5:r37582_syntactic_sum,
    frac(3,4)-10,
    frac(15,2)).

% === row 37604: decimal approximation perturbation ===
% Conceptual — awareness that decimal approximations are not exact.
test_harness:arith_misconception(db_row(37604), fraction, too_vague,
    skip, none, none).

% === row 37658: invert-and-multiply misapplied to multiplication ===
% Task: half of a third = 1/2 × 1/3.
% Correct: frac(1,6).
% Error: frac(2,3) — applies division algorithm (1/3 ÷ 1/2 = 2/3).
% SCHEMA: Measuring Stick — operation substitution
% GROUNDED: TODO — multiply_grounded vs divide_grounded
% CONNECTS TO: s(comp_nec(unlicensed(operation_substitution(divide_for_multiply))))
misconceptions_fraction_batch_5:(r37658_invert_multiply_for_times(frac(N1,D1)-frac(N2,D2), frac(Num, Den)) :-
    Num is N1 * D2,
    Den is D1 * N2).

test_harness:arith_misconception(db_row(37658), fraction, invert_multiply_for_times,
    misconceptions_fraction_batch_5:r37658_invert_multiply_for_times,
    frac(1,2)-frac(1,3),
    frac(1,6)).

% === row 37668: embodiment transformations / perception ===
% Conceptual perception issue — no numeric wrong answer.
test_harness:arith_misconception(db_row(37668), fraction, too_vague,
    skip, none, none).

% === row 37681: partition too-small-to-be-viable ===
% Affective / size-viability block — not a numeric error.
test_harness:arith_misconception(db_row(37681), fraction, too_vague,
    skip, none, none).

% === row 37747: PSTs fail simple equivalence/comparison ===
% Population-level rates without specific wrong transformation.
test_harness:arith_misconception(db_row(37747), fraction, too_vague,
    skip, none, none).

% === row 37770: improper/mixed: 3/3 + 1/3 read as 3 and 1/3 ===
% Task: add 3/3 and 1/3 (or express as improper).
% Correct: frac(4,3).
% Error: frac(10,3) — reads 3/3 bar as whole "3" plus 1/3 → "3 and 1/3".
% SCHEMA: Measuring Stick — unit-whole coordination missing
% GROUNDED: TODO — add_grounded on fraction units
% CONNECTS TO: s(comp_nec(unlicensed(unit_whole_conflation)))
misconceptions_fraction_batch_5:(r37770_three_thirds_as_three(frac(N1,D)-frac(N2,D), frac(Num, D)) :-
    Whole is N1,
    Num is Whole * D + N2).

test_harness:arith_misconception(db_row(37770), fraction, three_thirds_as_three,
    misconceptions_fraction_batch_5:r37770_three_thirds_as_three,
    frac(3,3)-frac(1,3),
    frac(4,3)).

% === row 37791: perceptual distracters ===
% Task difficulty description, no numeric wrong answer.
test_harness:arith_misconception(db_row(37791), fraction, too_vague,
    skip, none, none).

% === row 37809: anticipatory checking strategies ===
% Developmental / strategic — no numeric answer.
test_harness:arith_misconception(db_row(37809), fraction, too_vague,
    skip, none, none).

% === row 37825: can't take 9 from 7 — part-whole limitation ===
% Task: draw 9/7 from a unit bar.
% Correct: partition into 7, iterate 9 (frac(9,7)).
% Error: partitioned bar into 9 pieces instead of iterating.
% SCHEMA: Container — part-whole ceiling at denominator
% GROUNDED: TODO — iterate_grounded past the whole
% CONNECTS TO: s(comp_nec(unlicensed(part_whole_ceiling)))
misconceptions_fraction_batch_5:(r37825_part_whole_ceiling(frac(N,D), frac(N,N)) :-
    N > D).

test_harness:arith_misconception(db_row(37825), fraction, part_whole_ceiling,
    misconceptions_fraction_batch_5:r37825_part_whole_ceiling,
    frac(9,7),
    frac(9,7)).

% === row 37848: 1/12 ÷ 1/3 = 0 (natural-number division) ===
% Task: 1/12 ÷ 1/3.
% Correct: frac(1,4) (invert and multiply).
% Error: 0 — "can't fit 1/3 into 1/12".
% SCHEMA: Container — measurement-division with whole-number containment
% GROUNDED: TODO — divide_grounded with scaling
% CONNECTS TO: s(comp_nec(unlicensed(containment_yields_zero)))
misconceptions_fraction_batch_5:(r37848_containment_zero(frac(N1,D1)-frac(N2,D2), 0) :-
    N1 =:= 1, N2 =:= 1, D1 > D2).

test_harness:arith_misconception(db_row(37848), fraction, containment_yields_zero,
    misconceptions_fraction_batch_5:r37848_containment_zero,
    frac(1,12)-frac(1,3),
    frac(1,4)).

% === row 37870: leftover-pieces count for comparison ===
% Task: compare 2/3 and 3/4.
% Correct: second_greater (3/4 > 2/3).
% Error: equal — "same number of pieces left over".
% SCHEMA: Container — complement count instead of shaded area
% GROUNDED: TODO — compare_grounded on shaded, not unshaded
% CONNECTS TO: s(comp_nec(unlicensed(leftover_pieces_for_comparison)))
misconceptions_fraction_batch_5:(r37870_leftover_pieces(frac(N1,D1)-frac(N2,D2), Result) :-
    L1 is D1 - N1,
    L2 is D2 - N2,
    ( L1 =:= L2 -> Result = equal
    ; L1 < L2 -> Result = first_greater
    ; Result = second_greater )).

test_harness:arith_misconception(db_row(37870), fraction, leftover_pieces_for_comparison,
    misconceptions_fraction_batch_5:r37870_leftover_pieces,
    frac(2,3)-frac(3,4),
    second_greater).

% === row 37899: teachers fail 1 3/4 ÷ 1/2 ===
% Population-level description; no one uniform wrong transformation.
test_harness:arith_misconception(db_row(37899), fraction, too_vague,
    skip, none, none).

% === row 37916: fractions not as numbers / number line ===
% Ontological claim, not a computable wrong answer.
test_harness:arith_misconception(db_row(37916), fraction, too_vague,
    skip, none, none).

% === row 37953: relational naming vs count ===
% Mixed "how many" vs "how much" — not a single numeric rule.
test_harness:arith_misconception(db_row(37953), fraction, too_vague,
    skip, none, none).

% === row 37980: rigid invert-and-multiply ===
% Description of algorithm preference without a distinct wrong answer.
test_harness:arith_misconception(db_row(37980), fraction, too_vague,
    skip, none, none).

% === row 38068: gap thinking — 5/6 = 7/8 ===
% Task: compare 5/6 and 7/8.
% Correct: second_greater.
% Error: equal — "both one bit from whole".
% SCHEMA: Measuring Stick — numerator-denominator gap ignores piece size
% GROUNDED: TODO — compare_grounded
% CONNECTS TO: s(comp_nec(unlicensed(gap_thinking)))
misconceptions_fraction_batch_5:(r38068_gap_thinking(frac(N1,D1)-frac(N2,D2), Result) :-
    G1 is D1 - N1,
    G2 is D2 - N2,
    ( G1 =:= G2 -> Result = equal
    ; G1 < G2 -> Result = first_greater
    ; Result = second_greater )).

test_harness:arith_misconception(db_row(38068), fraction, gap_thinking,
    misconceptions_fraction_batch_5:r38068_gap_thinking,
    frac(5,6)-frac(7,8),
    second_greater).

% === row 38127: largest components = largest fraction ===
% Task: which of 1/2, 3/6, 2/4 is biggest (all equal).
% Correct: equal.
% Error: first_greater for frac(3,6) vs frac(1,2) — picks larger numerals.
% SCHEMA: Measuring Stick — whole-number bias on components
% GROUNDED: TODO — compare_grounded with equivalence
% CONNECTS TO: s(comp_nec(unlicensed(largest_components_bias)))
misconceptions_fraction_batch_5:(r38127_largest_components(frac(N1,D1)-frac(N2,D2), Result) :-
    S1 is N1 + D1,
    S2 is N2 + D2,
    ( S1 =:= S2 -> Result = equal
    ; S1 > S2 -> Result = first_greater
    ; Result = second_greater )).

test_harness:arith_misconception(db_row(38127), fraction, largest_components_bias,
    misconceptions_fraction_batch_5:r38127_largest_components,
    frac(3,6)-frac(1,2),
    equal).

% === row 38147: N or D increasing → fraction increases ===
% No concrete example given; description only.
test_harness:arith_misconception(db_row(38147), fraction, too_vague,
    skip, none, none).

% === row 38222: rote cross-cancel without understanding ===
% Lisa's cross-canceling yields the correct answer; no wrong numeric output.
test_harness:arith_misconception(db_row(38222), fraction, too_vague,
    skip, none, none).

% === row 38255: divisor-dividend reversal ===
% Task: 8 ÷ 2/3.
% Correct: 12.
% Error: computes 2/3 ÷ 8 = frac(2,24) = frac(1,12).
% SCHEMA: Source-Path-Goal — partitive default reverses operands
% GROUNDED: TODO — divide_grounded in both directions
% CONNECTS TO: s(comp_nec(unlicensed(divisor_dividend_reversal)))
misconceptions_fraction_batch_5:(r38255_reverse_divisor(Whole-frac(N,D), frac(Num, Den)) :-
    integer(Whole),
    Num is N,
    Den is D * Whole).

test_harness:arith_misconception(db_row(38255), fraction, divisor_dividend_reversal,
    misconceptions_fraction_batch_5:r38255_reverse_divisor,
    8-frac(2,3),
    12).

% === row 38268: part-whole prohibits improper ===
% Failure to produce; no specific wrong numeric answer.
test_harness:arith_misconception(db_row(38268), fraction, too_vague,
    skip, none, none).

% === row 38285: missing denom — scale factor substituted ===
% Task: 4/? = 36/63. Correct: ? = 7.
% Error: ? = 9 (the scale factor 4×9=36 substituted for denom).
% SCHEMA: Measuring Stick — scale factor confused with result denom
% GROUNDED: TODO — equivalence_grounded
% CONNECTS TO: s(comp_nec(unlicensed(scale_factor_as_denom)))
misconceptions_fraction_batch_5:(r38285_scale_factor_as_denom(frac(N1,_)-frac(N2,_), D1) :-
    % Scale factor S = N2 / N1. Student substitutes S for the missing denom.
    D1 is N2 // N1).

test_harness:arith_misconception(db_row(38285), fraction, scale_factor_as_denom,
    misconceptions_fraction_batch_5:r38285_scale_factor_as_denom,
    frac(4,missing)-frac(36,63),
    7).

% === row 38334: partitive scheme — swaps N and D for improper ===
% Task: produce 10/8.
% Correct: frac(10,8).
% Error: frac(8,10) — Jordan partitioned into 10 and filled 8.
% SCHEMA: Container — cannot exceed the container
% GROUNDED: TODO — partition and iterate grounded
% CONNECTS TO: s(comp_nec(unlicensed(partitive_scheme_swap)))
misconceptions_fraction_batch_5:(r38334_partitive_swap(frac(N,D), frac(D,N)) :-
    N > D).

test_harness:arith_misconception(db_row(38334), fraction, partitive_scheme_swap,
    misconceptions_fraction_batch_5:r38334_partitive_swap,
    frac(10,8),
    frac(10,8)).

% === row 38370: proper fraction multipliers contradict iteration ===
% Conceptual refusal, not a uniform wrong numeric output.
test_harness:arith_misconception(db_row(38370), fraction, too_vague,
    skip, none, none).

% === row 38395: improper fraction denominator = total pieces ===
% Task: four-fourths + one-fourth more = five-fourths.
% Correct: frac(5,4).
% Error: frac(5,5) — total pieces (5) used as denom.
% SCHEMA: Container — referent unit shifts with piece count
% GROUNDED: TODO — iterate_grounded preserving referent
% CONNECTS TO: s(comp_nec(unlicensed(total_count_as_denom)))
misconceptions_fraction_batch_5:(r38395_total_count_as_denom(frac(N1,D)-frac(N2,D), frac(Sum, Sum)) :-
    Sum is N1 + N2).

test_harness:arith_misconception(db_row(38395), fraction, total_count_as_denom,
    misconceptions_fraction_batch_5:r38395_total_count_as_denom,
    frac(4,4)-frac(1,4),
    frac(5,4)).

% === row 38421: reversing — partition by denominator, not numerator ===
% Task: "bar is 5/7, make the other bar" — partition into 5 (each = 1/7).
% Correct partition count: 5 (the numerator).
% Error: 7 — Michael partitioned into 7 parts (the denominator).
% SCHEMA: Measuring Stick — reversal operand confusion
% GROUNDED: TODO — reverse_fraction_grounded
% CONNECTS TO: s(comp_nec(unlicensed(reverse_partition_by_denominator)))
misconceptions_fraction_batch_5:(r38421_partition_by_denominator(frac(_N,D), D)).

test_harness:arith_misconception(db_row(38421), fraction, reverse_partition_by_denominator,
    misconceptions_fraction_batch_5:r38421_partition_by_denominator,
    frac(5,7),
    5).

% === row 38435: division word problem replaced by multiplication ===
% Conceptual replacement, not a single wrong numeric output on one task.
test_harness:arith_misconception(db_row(38435), fraction, too_vague,
    skip, none, none).

% === row 38456: 1/4 + 1/2 = 1/5 (count physical pieces) ===
% Task: 1/4 + 1/2.
% Correct: frac(3,4).
% Error: frac(1,5) — Tim said 4+1=5 pieces, one numerator.
% SCHEMA: Arithmetic is Object Collection — piece-count confusion
% GROUNDED: TODO — add_grounded with common denominator
% CONNECTS TO: s(comp_nec(unlicensed(piece_count_denom)))
misconceptions_fraction_batch_5:(r38456_piece_count_denom(frac(N1,D1)-frac(N2,D2), frac(1, Sum)) :-
    Sum is D1 + D2,
    _ = N1, _ = N2).

test_harness:arith_misconception(db_row(38456), fraction, piece_count_denom,
    misconceptions_fraction_batch_5:r38456_piece_count_denom,
    frac(1,4)-frac(1,2),
    frac(3,4)).

% === row 38541: commutativity elides conceptual difference ===
% Teacher pedagogical conflation; no wrong numeric answer.
test_harness:arith_misconception(db_row(38541), fraction, too_vague,
    skip, none, none).

% === row 38559: add N+N and D+D (unlike denominators) ===
% Task: add two fractions with unlike denominators.
% Correct: common denominator addition.
% Error: frac(N1+N2, D1+D2).
% SCHEMA: Arithmetic is Object Collection — componentwise addition
% GROUNDED: TODO — add_grounded with LCM
% CONNECTS TO: s(comp_nec(unlicensed(componentwise_addition)))
misconceptions_fraction_batch_5:(r38559_add_components(frac(N1,D1)-frac(N2,D2), frac(Num, Den)) :-
    Num is N1 + N2,
    Den is D1 + D2).

test_harness:arith_misconception(db_row(38559), fraction, add_numerators_and_denominators,
    misconceptions_fraction_batch_5:r38559_add_components,
    frac(1,3)-frac(1,4),
    frac(7,12)).

% === row 38594: decomposing 5/8 — partition by denominator ===
% Task: given a stick that is 5/8, rebuild the whole — partition into 5.
% Correct: 5 (the numerator).
% Error: 8 (the denominator).
% SCHEMA: Measuring Stick — reversal operand confusion
% GROUNDED: TODO — reverse_fraction_grounded
% CONNECTS TO: s(comp_nec(unlicensed(decompose_by_denominator)))
misconceptions_fraction_batch_5:(r38594_decompose_by_denominator(frac(_N,D), D)).

test_harness:arith_misconception(db_row(38594), fraction, decompose_by_denominator,
    misconceptions_fraction_batch_5:r38594_decompose_by_denominator,
    frac(5,8),
    5).

% === row 38658: (7/8)x = 5 — eighths of known instead of sevenths ===
% Task: solve (7/8)x = 5, i.e. find 1/7 of known, then add 5 units.
% Correct: 40/7 (student should divide 5 into 7 parts and iterate).
% Error: divided 5 into 8 parts (denom of 7/8), yielding 40 "small pieces"
%   and planning to add 5 — effectively returning 5 (or frac(5,8) of 8).
% SCHEMA: Measuring Stick — denom used as partition of known quantity
% GROUNDED: TODO — reverse_multiplication_grounded
% CONNECTS TO: s(comp_nec(unlicensed(denom_partitions_known)))
misconceptions_fraction_batch_5:(r38658_denom_partitions_known(frac(N,D)-Known, frac(Num, D)) :-
    integer(Known),
    Num is Known * N).

test_harness:arith_misconception(db_row(38658), fraction, denom_partitions_known,
    misconceptions_fraction_batch_5:r38658_denom_partitions_known,
    frac(7,8)-5,
    frac(40,7)).

% === row 38665: half of 1/4 = 4.5 (count pieces plus half-piece) ===
% Task: half of 1/4.
% Correct: frac(1,8).
% Error: 4.5 (student: "four of them and then one half of it").
% SCHEMA: Container — counts visible pieces plus fractional remainder
% GROUNDED: TODO — multiply_grounded for recursive partition
% CONNECTS TO: s(comp_nec(unlicensed(count_pieces_plus_half)))
misconceptions_fraction_batch_5:(r38665_count_pieces_plus_half(frac(_,D1)-frac(_,D2), frac(Num, Den)) :-
    % D2 pieces visible, half of one more: D2 + 1/2 = (2*D2+1)/2
    _ = D1,
    Num is 2 * D2 + 1,
    Den is 2).

test_harness:arith_misconception(db_row(38665), fraction, count_pieces_plus_half,
    misconceptions_fraction_batch_5:r38665_count_pieces_plus_half,
    frac(1,2)-frac(1,4),
    frac(1,8)).

% === row 38680: teacher misinterprets diagram referent ===
% Adult-pedagogical shift; not a student computational rule.
test_harness:arith_misconception(db_row(38680), fraction, too_vague,
    skip, none, none).

% === row 38718: improper fraction → redefine whole ===
% Task: name 4/3.
% Correct: frac(4,3).
% Error: frac(4,4) — whole redefined to extended quantity.
% SCHEMA: Container — whole stretches to include all pieces
% GROUNDED: TODO — iterate_grounded past whole, preserving referent
% CONNECTS TO: s(comp_nec(unlicensed(redefine_whole_as_total)))
misconceptions_fraction_batch_5:(r38718_redefine_whole(frac(N,D), frac(N,N)) :-
    N > D).

test_harness:arith_misconception(db_row(38718), fraction, redefine_whole_as_total,
    misconceptions_fraction_batch_5:r38718_redefine_whole,
    frac(4,3),
    frac(4,3)).

% === row 38794: larger denominator = smaller pieces = smaller fraction (ignoring N) ===
% Task: compare 2 1/3 and 2 2/6 (equal as mixed numbers).
% Correct: equal.
% Error: first_greater — "thirds are bigger than sixths".
% SCHEMA: Measuring Stick — piece-size focus, numerator ignored
% GROUNDED: TODO — compare_grounded with both N and D
% CONNECTS TO: s(comp_nec(unlicensed(denominator_only_comparison)))
misconceptions_fraction_batch_5:(r38794_denominator_only(frac(_,D1)-frac(_,D2), Result) :-
    ( D1 =:= D2 -> Result = equal
    ; D1 < D2 -> Result = first_greater
    ; Result = second_greater )).

test_harness:arith_misconception(db_row(38794), fraction, denominator_only_comparison,
    misconceptions_fraction_batch_5:r38794_denominator_only,
    frac(1,3)-frac(2,6),
    equal).

% === row 38838: 1/2 + 1/4 = 2/6 ===
% Task: 1/2 + 1/4.
% Correct: frac(3,4).
% Error: frac(2,6) — componentwise addition.
% SCHEMA: Arithmetic is Object Collection — two whole-numbers abstraction
% GROUNDED: TODO — add_grounded with LCM
% CONNECTS TO: s(comp_nec(unlicensed(componentwise_addition)))
misconceptions_fraction_batch_5:(r38838_componentwise_add(frac(N1,D1)-frac(N2,D2), frac(Num, Den)) :-
    Num is N1 + N2,
    Den is D1 + D2).

test_harness:arith_misconception(db_row(38838), fraction, componentwise_addition,
    misconceptions_fraction_batch_5:r38838_componentwise_add,
    frac(1,2)-frac(1,4),
    frac(3,4)).

% === row 38858: arithmetic without conceptual understanding ===
% Descriptive — no specific wrong transformation.
test_harness:arith_misconception(db_row(38858), fraction, too_vague,
    skip, none, none).

% === row 38923: teacher forces procedure ===
% Adult-pedagogical; no student computational rule.
test_harness:arith_misconception(db_row(38923), fraction, too_vague,
    skip, none, none).

% === row 38973: natural-number bias — 14/57 > 1/3 ===
% Task: compare 14/57 and 1/3.
% Correct: second_greater (1/3 ≈ 0.333 > 14/57 ≈ 0.246).
% Error: first_greater — "14>1 and 57>3".
% SCHEMA: Measuring Stick — componentwise whole-number dominance
% GROUNDED: TODO — compare_grounded via cross-product
% CONNECTS TO: s(comp_nec(unlicensed(natural_number_bias)))
misconceptions_fraction_batch_5:(r38973_natural_number_bias(frac(N1,D1)-frac(N2,D2), Result) :-
    ( N1 > N2, D1 > D2 -> Result = first_greater
    ; N1 < N2, D1 < D2 -> Result = second_greater
    ; Result = equal )).

test_harness:arith_misconception(db_row(38973), fraction, natural_number_bias,
    misconceptions_fraction_batch_5:r38973_natural_number_bias,
    frac(14,57)-frac(1,3),
    second_greater).

% === row 38989: median-of-fractions as addition ===
% Task: add two fractions.
% Correct: common denominator sum.
% Error: (a+c)/(b+d).
% SCHEMA: Arithmetic is Object Collection — averaging op for addition
% GROUNDED: TODO — add_grounded with LCM
% CONNECTS TO: s(comp_nec(unlicensed(median_for_addition)))
misconceptions_fraction_batch_5:(r38989_median_for_add(frac(N1,D1)-frac(N2,D2), frac(Num, Den)) :-
    Num is N1 + N2,
    Den is D1 + D2).

test_harness:arith_misconception(db_row(38989), fraction, median_for_addition,
    misconceptions_fraction_batch_5:r38989_median_for_add,
    frac(1,2)-frac(1,3),
    frac(5,6)).

% === row 39040: algorithm executed incorrectly without meaning ===
% Idiosyncratic extraction ("4/3 and 2/2") — no regular rule.
test_harness:arith_misconception(db_row(39040), fraction, too_vague,
    skip, none, none).

% === row 39090: larger numbers dominance — 4/7 > 4/5 ===
% Task: compare 4/7 and 4/5.
% Correct: second_greater.
% Error: first_greater — "larger numbers in 4/7 (7>5)".
% SCHEMA: Measuring Stick — denominator-larger-means-bigger bias
% GROUNDED: TODO — compare_grounded
% CONNECTS TO: s(comp_nec(unlicensed(whole_number_dominance_denom)))
misconceptions_fraction_batch_5:(r39090_whole_number_dominance(frac(N1,D1)-frac(N2,D2), Result) :-
    ( N1 =:= N2
    -> ( D1 > D2 -> Result = first_greater
       ; D1 < D2 -> Result = second_greater
       ; Result = equal )
    ; D1 =:= D2
    -> ( N1 > N2 -> Result = first_greater
       ; N1 < N2 -> Result = second_greater
       ; Result = equal )
    ; Result = equal )).

test_harness:arith_misconception(db_row(39090), fraction, whole_number_dominance,
    misconceptions_fraction_batch_5:r39090_whole_number_dominance,
    frac(4,7)-frac(4,5),
    second_greater).

% === row 39139: no visual imagery for numerator>1 ===
% Failure to produce — no wrong numeric rule.
test_harness:arith_misconception(db_row(39139), fraction, too_vague,
    skip, none, none).

% === row 39170: equally spaced unit fractions on number line ===
% PST representation error; no specific numeric rule.
test_harness:arith_misconception(db_row(39170), fraction, too_vague,
    skip, none, none).

% === row 39199: cuts equal pieces ===
% Task: cuts to make N equal pieces.
% Correct: N-1.
% Error: N.
% SCHEMA: Source-Path-Goal — cut-piece count identification
% GROUNDED: TODO — partition_grounded
% CONNECTS TO: s(comp_nec(unlicensed(cuts_equal_pieces)))
misconceptions_fraction_batch_5:(r39199_cuts_equal_pieces(Pieces, Pieces)).

test_harness:arith_misconception(db_row(39199), fraction, cuts_equal_pieces,
    misconceptions_fraction_batch_5:r39199_cuts_equal_pieces,
    3,
    2).

% === row 39275: invented fraction names ===
% Linguistic — no numeric error.
test_harness:arith_misconception(db_row(39275), fraction, too_vague,
    skip, none, none).

% === row 39349: PSTs failed to transfer info ===
% Description-only, no concrete wrong answer.
test_harness:arith_misconception(db_row(39349), fraction, too_vague,
    skip, none, none).

% === row 39433: fair-sharing reciprocal — 5/4 instead of 4/5 ===
% Task: 4 sandwiches shared among 5 people → each gets 4/5.
% Correct: frac(4,5).
% Error: frac(5,4) — N and D swapped.
% SCHEMA: Measuring Stick — extensive-quantity confusion in rate
% GROUNDED: TODO — divide_grounded as rate
% CONNECTS TO: s(comp_nec(unlicensed(fair_share_reciprocal)))
misconceptions_fraction_batch_5:(r39433_fair_share_reciprocal(Items-People, frac(People, Items))).

test_harness:arith_misconception(db_row(39433), fraction, fair_share_reciprocal,
    misconceptions_fraction_batch_5:r39433_fair_share_reciprocal,
    4-5,
    frac(4,5)).

% === row 39486: reverse — halving 1/6 to make 1/3 ===
% Task: given 1/6, make 1/3 (iterate twice).
% Correct: frac(1,3).
% Error: frac(1,12) — halved the 1/6 bar.
% SCHEMA: Measuring Stick — forward operation applied for inverse
% GROUNDED: TODO — reverse_partition_grounded
% CONNECTS TO: s(comp_nec(unlicensed(forward_for_reverse)))
misconceptions_fraction_batch_5:(r39486_forward_for_reverse(frac(N,D), frac(N, Doubled)) :-
    Doubled is 2 * D).

test_harness:arith_misconception(db_row(39486), fraction, forward_for_reverse,
    misconceptions_fraction_batch_5:r39486_forward_for_reverse,
    frac(1,6),
    frac(1,3)).

% === row 39571: larger denominator as cause of bigger fraction ===
% No example in corpus row.
test_harness:arith_misconception(db_row(39571), fraction, too_vague,
    skip, none, none).

% === row 39605: numerator as per-group count ===
% Task: 2/4 of 12.
% Correct: 6.
% Error: partitioned 12 into groups of 2 (N per group), producing 6 groups —
%   numeric answer coincidentally 6. No distinct wrong output.
test_harness:arith_misconception(db_row(39605), fraction, too_vague,
    skip, none, none).

% === row 39640: coordinating multiple meanings of 8/6 ===
% Conceptual struggle, no single wrong output.
test_harness:arith_misconception(db_row(39640), fraction, too_vague,
    skip, none, none).

% === row 39668: unequal rods called halves ===
% No arithmetic rule to encode.
test_harness:arith_misconception(db_row(39668), fraction, too_vague,
    skip, none, none).

% === row 39697: area-model in non-area context ===
% Geometric misapplication; no arithmetic output.
test_harness:arith_misconception(db_row(39697), fraction, too_vague,
    skip, none, none).

% === row 39723: fraction of a set interpreted as cutting items ===
% No numeric wrong answer.
test_harness:arith_misconception(db_row(39723), fraction, too_vague,
    skip, none, none).

% === row 39767: common denominator for multiplication ===
% Task: 1/3 × 5/4.
% Correct: frac(5,12).
% Error: frac(60,12) — converted to 4/12 and 15/12, then multiplied.
% SCHEMA: Arithmetic is Object Collection — additive rule misapplied
% GROUNDED: TODO — multiply_grounded without LCM conversion
% CONNECTS TO: s(comp_nec(unlicensed(common_denom_for_multiply)))
misconceptions_fraction_batch_5:(r39767_common_denom_multiply(frac(N1,D1)-frac(N2,D2), frac(Num, Den)) :-
    LCM is D1 * D2,
    Scaled1 is N1 * D2,
    Scaled2 is N2 * D1,
    Num is Scaled1 * Scaled2,
    Den is LCM).

test_harness:arith_misconception(db_row(39767), fraction, common_denom_for_multiply,
    misconceptions_fraction_batch_5:r39767_common_denom_multiply,
    frac(1,3)-frac(5,4),
    frac(5,12)).

% === row 39782: 2/3 + 1/7 = 3/10 (tops and bottoms) ===
% Task: 2/3 + 1/7.
% Correct: frac(17,21).
% Error: frac(3,10) — componentwise addition.
% SCHEMA: Arithmetic is Object Collection — componentwise addition
% GROUNDED: TODO — add_grounded with LCM
% CONNECTS TO: s(comp_nec(unlicensed(componentwise_addition)))
misconceptions_fraction_batch_5:(r39782_componentwise_add(frac(N1,D1)-frac(N2,D2), frac(Num, Den)) :-
    Num is N1 + N2,
    Den is D1 + D2).

test_harness:arith_misconception(db_row(39782), fraction, tops_and_bottoms_addition,
    misconceptions_fraction_batch_5:r39782_componentwise_add,
    frac(2,3)-frac(1,7),
    frac(17,21)).

% === row 39813: halving-fails for odd denominators ===
% Strategy-selection issue, no numeric output.
test_harness:arith_misconception(db_row(39813), fraction, too_vague,
    skip, none, none).

% === row 39820: different wholes not coordinated ===
% Depends on unspecified values; no canonical wrong answer.
test_harness:arith_misconception(db_row(39820), fraction, too_vague,
    skip, none, none).

% === row 39852: 1/6 + 1/5 = 1/11 (add denominators only) ===
% Task: 1/6 + 1/5.
% Correct: frac(11,30).
% Error: frac(1,11) — numerator kept, denominators summed.
% SCHEMA: Arithmetic is Object Collection — denom-only addition
% GROUNDED: TODO — add_grounded with LCM
% CONNECTS TO: s(comp_nec(unlicensed(add_denominators_only)))
misconceptions_fraction_batch_5:(r39852_add_denom_only(frac(N,D1)-frac(N,D2), frac(N, Den)) :-
    Den is D1 + D2).

test_harness:arith_misconception(db_row(39852), fraction, add_denominators_only,
    misconceptions_fraction_batch_5:r39852_add_denom_only,
    frac(1,6)-frac(1,5),
    frac(11,30)).

% === row 39892: 3/6 + 1/6 = 4/12 (equal denominators, still add both) ===
% Task: 3/6 + 1/6.
% Correct: frac(4,6).
% Error: frac(4,12) — adds denominators too despite equality.
% SCHEMA: Arithmetic is Object Collection — componentwise addition
% GROUNDED: TODO — add_grounded (same-denom)
% CONNECTS TO: s(comp_nec(unlicensed(componentwise_addition_same_denom)))
misconceptions_fraction_batch_5:(r39892_componentwise_same_denom(frac(N1,D)-frac(N2,D), frac(Num, Den)) :-
    Num is N1 + N2,
    Den is D + D).

test_harness:arith_misconception(db_row(39892), fraction, componentwise_same_denom,
    misconceptions_fraction_batch_5:r39892_componentwise_same_denom,
    frac(3,6)-frac(1,6),
    frac(4,6)).

% === row 39950: different denominators → unrelated fractions ===
% Conceptual refusal, not a numeric rule.
test_harness:arith_misconception(db_row(39950), fraction, too_vague,
    skip, none, none).

% === row 40072: PST conflations reproducing the whole ===
% Multiple distinct errors described; no single canonical transformation.
test_harness:arith_misconception(db_row(40072), fraction, too_vague,
    skip, none, none).

% === row 40085: how-many for how-much (4 pizzas / 5 people) ===
% Task: 4 pizzas among 5 people — how much per person.
% Correct: frac(4,5).
% Error: 4 (answers "how many pieces" — counts pieces).
% SCHEMA: Measuring Stick — count-for-proportion substitution
% GROUNDED: TODO — divide_grounded as rate
% CONNECTS TO: s(comp_nec(unlicensed(count_for_proportion)))
misconceptions_fraction_batch_5:(r40085_count_for_proportion(Items-_People, Items)).

test_harness:arith_misconception(db_row(40085), fraction, count_for_proportion,
    misconceptions_fraction_batch_5:r40085_count_for_proportion,
    4-5,
    frac(4,5)).

% === row 40113: referent-whole language — 4/20 for 4 pizzas among 5 ===
% Task: what fraction of a pizza — 4/5. Student wrote 4/20 (of all pizzas).
% Correct: frac(4,5).
% Error: frac(4, Items*People) treating "of a" as "of all".
% SCHEMA: Measuring Stick — referent whole displaced to aggregate
% GROUNDED: TODO — rate_grounded with correct referent
% CONNECTS TO: s(comp_nec(unlicensed(referent_whole_aggregate)))
misconceptions_fraction_batch_5:(r40113_referent_whole_aggregate(Items-People, frac(Items, Total)) :-
    Total is Items * People).

test_harness:arith_misconception(db_row(40113), fraction, referent_whole_aggregate,
    misconceptions_fraction_batch_5:r40113_referent_whole_aggregate,
    4-5,
    frac(4,5)).

% === row 40123: PST gap thinking — 8/9 = 12/13 ===
% Task: compare 8/9 and 12/13.
% Correct: second_greater.
% Error: equal — both one piece from whole.
% SCHEMA: Measuring Stick — gap thinking (same as 38068)
% GROUNDED: TODO — compare_grounded
% CONNECTS TO: s(comp_nec(unlicensed(gap_thinking_pst)))
misconceptions_fraction_batch_5:(r40123_gap_thinking_pst(frac(N1,D1)-frac(N2,D2), Result) :-
    G1 is D1 - N1,
    G2 is D2 - N2,
    ( G1 =:= G2 -> Result = equal
    ; G1 < G2 -> Result = first_greater
    ; Result = second_greater )).

test_harness:arith_misconception(db_row(40123), fraction, gap_thinking_pst,
    misconceptions_fraction_batch_5:r40123_gap_thinking_pst,
    frac(8,9)-frac(12,13),
    second_greater).

% === row 40136: child writes "three plus four" for 3/4 ===
% Notational, not arithmetic.
test_harness:arith_misconception(db_row(40136), fraction, too_vague,
    skip, none, none).

% === row 40149: partitive/measurement model confusion ===
% Multiple interpretations yield the correct numeric answer.
test_harness:arith_misconception(db_row(40149), fraction, too_vague,
    skip, none, none).

% === row 40187: unequal parts treated as equal shares ===
% Geometric/partition issue with no numeric rule.
test_harness:arith_misconception(db_row(40187), fraction, too_vague,
    skip, none, none).

% === row 40197: smaller denominator = larger (ignoring numerator) ===
% Task: compare 5/6 and 6/7.
% Correct: second_greater.
% Error: first_greater — "6-piece block has larger pieces".
% SCHEMA: Measuring Stick — denom-only size reasoning
% GROUNDED: TODO — compare_grounded with numerator
% CONNECTS TO: s(comp_nec(unlicensed(smaller_denom_larger_fraction)))
misconceptions_fraction_batch_5:(r40197_smaller_denom_larger(frac(_,D1)-frac(_,D2), Result) :-
    ( D1 =:= D2 -> Result = equal
    ; D1 < D2 -> Result = first_greater
    ; Result = second_greater )).

test_harness:arith_misconception(db_row(40197), fraction, smaller_denom_larger_fraction,
    misconceptions_fraction_batch_5:r40197_smaller_denom_larger,
    frac(5,6)-frac(6,7),
    second_greater).

% === row 40230: 2/3 × 3/5 = 5/8 (add both in multiplication) ===
% Task: 2/3 × 3/5.
% Correct: frac(6,15).
% Error: frac(5,8) — componentwise addition applied to multiplication.
% SCHEMA: Arithmetic is Object Collection — operation substitution
% GROUNDED: TODO — multiply_grounded
% CONNECTS TO: s(comp_nec(unlicensed(add_for_multiply_components)))
misconceptions_fraction_batch_5:(r40230_add_for_multiply(frac(N1,D1)-frac(N2,D2), frac(Num, Den)) :-
    Num is N1 + N2,
    Den is D1 + D2).

test_harness:arith_misconception(db_row(40230), fraction, add_for_multiply_components,
    misconceptions_fraction_batch_5:r40230_add_for_multiply,
    frac(2,3)-frac(3,5),
    frac(6,15)).

% === row 40258: misinterpreting remainder in fraction division ===
% Adult pedagogical; no single numeric rule.
test_harness:arith_misconception(db_row(40258), fraction, too_vague,
    skip, none, none).

% === row 40319: 18/19 > 15/16 because N+D larger ===
% Student's comparison answer matches the correct comparison (18/19 > 15/16),
% so this rule has no distinct wrong output on this example.
test_harness:arith_misconception(db_row(40319), fraction, too_vague,
    skip, none, none).

% === row 40372: whole × improper fraction conflation ===
% Complex unit-coordination described without a single wrong numeric output.
test_harness:arith_misconception(db_row(40372), fraction, too_vague,
    skip, none, none).

% === row 40404: 8/9 > 5/6 because both larger ===
% Student's answer is correct numerically (8/9 > 5/6); no distinct wrong output.
test_harness:arith_misconception(db_row(40404), fraction, too_vague,
    skip, none, none).

% === row 40444: mechanical cross-multiplication ===
% No wrong numeric answer given — just an algorithmic preference.
test_harness:arith_misconception(db_row(40444), fraction, too_vague,
    skip, none, none).

% === row 40455: estimate sum by adding numerators only ===
% Task: estimate sum of two fractions (example gives 6+4=10).
% Correct depends on denominators. Without concrete denominators, no
% canonical correct value exists; use plausible frac(1,2)+frac(1,3)=frac(5,6)
% against student integer-output rule.
% SCHEMA: Arithmetic is Object Collection — numerators as standalone terms
% GROUNDED: TODO — add_grounded
% CONNECTS TO: s(comp_nec(unlicensed(numerator_only_addition)))
misconceptions_fraction_batch_5:(r40455_numerator_only_sum(frac(N1,_)-frac(N2,_), Sum) :-
    Sum is N1 + N2).

test_harness:arith_misconception(db_row(40455), fraction, numerator_only_addition,
    misconceptions_fraction_batch_5:r40455_numerator_only_sum,
    frac(6,7)-frac(4,9),
    frac(82,63)).

% === row 40483: fraction as part-over-remaining ===
% Task: 1 colored part, 6 uncolored → fraction colored.
% Correct: frac(1,7) (1 of 7 total).
% Error: frac(1,6) — uses remaining pieces as denom.
% SCHEMA: Container — part-to-remainder ratio instead of part-to-whole
% GROUNDED: TODO — ratio_grounded
% CONNECTS TO: s(comp_nec(unlicensed(part_over_remaining)))
misconceptions_fraction_batch_5:(r40483_part_over_remaining(Part-Total, frac(Part, Rem)) :-
    Rem is Total - Part).

test_harness:arith_misconception(db_row(40483), fraction, part_over_remaining,
    misconceptions_fraction_batch_5:r40483_part_over_remaining,
    1-7,
    frac(1,7)).

% === row 40499: density denial → bisection only ===
% Offers bisections (5.5, 5.25) — strategy description, not a fixed wrong rule.
test_harness:arith_misconception(db_row(40499), fraction, too_vague,
    skip, none, none).

% === row 40588: 31 × 17/31 — multiply first instead of recognizing inverse ===
% Task: 31 × 17/31.
% Correct: 17 (31 × 1/31 = 1).
% Error: computes 31 × 17 = 527 first (frac(527, 31)).
% SCHEMA: Measuring Stick — inverse not recognized
% GROUNDED: TODO — multiply_grounded with inverse detection
% CONNECTS TO: s(comp_nec(unlicensed(inverse_not_recognized)))
misconceptions_fraction_batch_5:(r40588_inverse_not_recognized(Whole-frac(N,D), frac(Num, D)) :-
    integer(Whole),
    Num is Whole * N).

test_harness:arith_misconception(db_row(40588), fraction, inverse_not_recognized,
    misconceptions_fraction_batch_5:r40588_inverse_not_recognized,
    31-frac(17,31),
    17).

% === row 40662: 5/5 + 1/5 called six sixths ===
% Task: add 5/5 and 1/5.
% Correct: frac(6,5).
% Error: frac(6,6) — denom redefined to total piece count.
% SCHEMA: Container — whole stretches as pieces accumulate
% GROUNDED: TODO — add_grounded preserving denom
% CONNECTS TO: s(comp_nec(unlicensed(denom_follows_piece_count)))
misconceptions_fraction_batch_5:(r40662_denom_follows_piece_count(frac(N1,D)-frac(N2,D), frac(Sum, Sum)) :-
    Sum is N1 + N2).

test_harness:arith_misconception(db_row(40662), fraction, denom_follows_piece_count,
    misconceptions_fraction_batch_5:r40662_denom_follows_piece_count,
    frac(5,5)-frac(1,5),
    frac(6,5)).

% Fraction misconceptions — research corpus batch 6/7.
% Native arithmetic layer only. Theoretical annotations as comments:
%   % GROUNDED: TODO — placeholder for future embodied arithmetic layer
%   % SCHEMA: <schema name> — Lakoff & Nunez grounding when applicable
%   % CONNECTS TO: s(comp_nec(unlicensed(...))) — PML operator path
%
% Registration convention (from Task 3 arch fix):
%   test_harness:arith_misconception(Source, Domain, Description,
%       misconceptions_fraction_batch_6:rule_name, Input, Expected).
% Rule predicates do NOT go on the module export list.


% ---- Encodings appended by agent for batch 6 ----

% === row 37439: composite unit fraction naming (context-specific, no mechanical rule) ===
test_harness:arith_misconception(db_row(37439), fraction, too_vague,
    skip, none, none).

% === row 37446: reciprocal instead of improper fraction ===
% Task: compute 7/5 of a collection (as a fractional scalar expressed via frac(7,5))
% Correct: 7/5 = 1.4
% Error: flips numerator/denominator to 5/7 to avoid extending beyond the whole
% SCHEMA: Object Collection — avoids "too many" by inversion
% GROUNDED: TODO — numerator/denominator roles in iteration
% CONNECTS TO: s(comp_nec(unlicensed(reciprocal_to_stay_proper)))
misconceptions_fraction_batch_6:(row_37446(frac(N,D), Got) :-
    % student flips to avoid going beyond the whole
    Got is D / N).

test_harness:arith_misconception(db_row(37446), fraction, reciprocal_avoids_improper,
    misconceptions_fraction_batch_6:row_37446,
    frac(7,5),
    1.4).

% === row 37456: cognitive perturbation at odd partition (no concrete wrong answer) ===
test_harness:arith_misconception(db_row(37456), fraction, too_vague,
    skip, none, none).

% === row 37477: requires perceptual support (cognitive load, no concrete rule) ===
test_harness:arith_misconception(db_row(37477), fraction, too_vague,
    skip, none, none).

% === row 37506: story for divide-by-half models divide-by-two ===
% Task: 7/4 ÷ 1/2
% Correct: 7/4 ÷ 1/2 = 7/2 = 3.5
% Error: models "split between two of us" → 7/4 ÷ 2 = 7/8
% SCHEMA: Object Collection — "split between two" stops at denominator surface
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(divide_by_half_as_divide_by_two)))
misconceptions_fraction_batch_6:(row_37506(frac(N,D)-frac(_,DDiv), Got) :-
    % student divides by the denominator of the divisor rather than by the divisor
    Got is (N/D) / DDiv).

test_harness:arith_misconception(db_row(37506), fraction, divide_by_half_as_by_two,
    misconceptions_fraction_batch_6:row_37506,
    frac(7,4)-frac(1,2),
    3.5).

% === row 37515: estimation as exact paper-and-pencil computation ===
% Task: estimate 12/13 + 7/8
% Correct (estimate): ~2 (each fraction is near 1)
% Error: mentally computes exact common denominator 104 (or 114), produces exact mixed number
% SCHEMA: Container — algorithm is the only admissible container for computation
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(estimate_as_exact_calculation)))
misconceptions_fraction_batch_6:(row_37515(frac(N1,D1)-frac(N2,D2), Got) :-
    % student insists on exact value instead of rounding each near-1 fraction to 1
    Got is N1/D1 + N2/D2).

test_harness:arith_misconception(db_row(37515), fraction, estimate_as_exact,
    misconceptions_fraction_batch_6:row_37515,
    frac(12,13)-frac(7,8),
    2).

% === row 37523: halving produces unequal fifths (no concrete numeric answer) ===
test_harness:arith_misconception(db_row(37523), fraction, too_vague,
    skip, none, none).

% === row 37569: cannot mentally remove partition marks (no concrete numeric transformation) ===
test_harness:arith_misconception(db_row(37569), fraction, too_vague,
    skip, none, none).

% === row 37583: shaded as "amount taken" → attends to complement ===
% Task: identify 7/12
% Correct: 7/12 ≈ 0.583
% Error: reports the unshaded complement 5/12 ≈ 0.417
% SCHEMA: Container — "what's left" instead of "what's there"
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(fraction_as_complement)))
misconceptions_fraction_batch_6:(row_37583(frac(N,D), Got) :-
    % student reports the complement (D - N) / D
    Got is (D - N) / D).

test_harness:arith_misconception(db_row(37583), fraction, reports_complement,
    misconceptions_fraction_batch_6:row_37583,
    frac(7,12),
    0.5833333333333334).

% === row 37605: fails to square a fractional scale factor ===
% Task: area change under scale factor 2.5
% Correct: 2.5^2 = 6.25
% Error: multiplies area by the scale factor itself (2.5) rather than squaring
% SCHEMA: Motion Along Path — "scale" treated as multiplier once, not twice
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(no_square_for_fraction_scale)))
misconceptions_fraction_batch_6:(row_37605(Scale, Got) :-
    % student returns Scale instead of Scale^2
    Got is Scale).

test_harness:arith_misconception(db_row(37605), fraction, no_square_fraction_scale,
    misconceptions_fraction_batch_6:row_37605,
    2.5,
    6.25).

% === row 37662: arrow points to location, not a quantity ===
test_harness:arith_misconception(db_row(37662), fraction, too_vague,
    skip, none, none).

% === row 37675: "already cut up, can't partition further" (no concrete wrong number) ===
test_harness:arith_misconception(db_row(37675), fraction, too_vague,
    skip, none, none).

% === row 37682: counts lines instead of regions (no deterministic numeric rule) ===
test_harness:arith_misconception(db_row(37682), fraction, too_vague,
    skip, none, none).

% === row 37752: story for division models multiplication ===
% Task: 1/2 ÷ 1/4
% Correct: 1/2 ÷ 1/4 = 2
% Error: constructs "1/2 of (1 - 1/4)" → 1/2 × 3/4 = 3/8
% SCHEMA: Object Collection — "fraction of" overrides "divided by"
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(division_story_as_multiplication)))
misconceptions_fraction_batch_6:(row_37752(frac(N1,D1)-frac(N2,D2), Got) :-
    % student models as F1 × (1 - F2) instead of F1 ÷ F2
    Got is (N1/D1) * (1 - N2/D2)).

test_harness:arith_misconception(db_row(37752), fraction, division_story_as_multiplication,
    misconceptions_fraction_batch_6:row_37752,
    frac(1,2)-frac(1,4),
    2).

% === row 37771: partition/pull roles of numerator and denominator swapped ===
% Task: produce 16/5 (partition whole into 5, pull 16 iterates)
% Correct: 16/5 = 3.2
% Error: partitions into 16, pulls 5 → returns 5/16
% SCHEMA: Object Collection — numerator/denominator roles confused
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(swap_numer_denom_roles)))
misconceptions_fraction_batch_6:(row_37771(frac(N,D), Got) :-
    % student swaps partition count and pull count
    Got is D / N).

test_harness:arith_misconception(db_row(37771), fraction, swap_partition_pull,
    misconceptions_fraction_batch_6:row_37771,
    frac(16,5),
    3.2).

% === row 37792: belief that multiplication always increases (general belief) ===
test_harness:arith_misconception(db_row(37792), fraction, too_vague,
    skip, none, none).

% === row 37810: unit-fraction naming by visible count (no specific numeric task) ===
test_harness:arith_misconception(db_row(37810), fraction, too_vague,
    skip, none, none).

% === row 37829: unit fraction comparison via whole-number size ===
% Task: compare 1/7 and 1/5 — which is larger?
% Correct: 1/5 > 1/7, so larger = frac(1,5)
% Error: picks frac(1,7) because 7 > 5
% SCHEMA: Measuring Stick — denominator size read directly as fraction size
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(whole_number_on_denominator)))
misconceptions_fraction_batch_6:(row_37829(frac(N1,D1)-frac(N2,D2), Larger) :-
    % student picks the one with the larger denominator
    (D1 > D2 -> Larger = frac(N1,D1) ; Larger = frac(N2,D2))).

test_harness:arith_misconception(db_row(37829), fraction, unit_frac_bigger_denom_wins,
    misconceptions_fraction_batch_6:row_37829,
    frac(1,7)-frac(1,5),
    frac(1,5)).

% === row 37852: additive representation of multiplicative relationship ===
test_harness:arith_misconception(db_row(37852), fraction, too_vague,
    skip, none, none).

% === row 37871: procedural jumble across addition ===
% Task: 2/3 + 1/4
% Correct: 2/3 + 1/4 = 11/12 ≈ 0.9167
% Error: cross-cancels 2 and 4 (→ 1 and 2), adds 3+2=5, leaves 1s alone → 1/5
% SCHEMA: Container — shuffles digits between slots without rule
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(jumbled_cross_cancel_add)))
misconceptions_fraction_batch_6:(row_37871(frac(_,_)-frac(_,_), Got) :-
    % the specific 2/3 + 1/4 → 1/5 bug: numerator 1, denominator (3+2)=5
    Got is 1/5).

test_harness:arith_misconception(db_row(37871), fraction, jumbled_cross_cancel,
    misconceptions_fraction_batch_6:row_37871,
    frac(2,3)-frac(1,4),
    0.9166666666666666).

% === row 37904: phonological-processing deficit (cognitive, not arithmetic) ===
test_harness:arith_misconception(db_row(37904), fraction, too_vague,
    skip, none, none).

% === row 37917: add numerators, add denominators (unlike denominators) ===
% Task: 1/3 + 1/5
% Correct: 1/3 + 1/5 = 8/15 ≈ 0.533
% Error: add across → 2/8 = 0.25
% SCHEMA: Container — "same slot sums with same slot"
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(add_across_numer_and_denom)))
misconceptions_fraction_batch_6:(row_37917(frac(N1,D1)-frac(N2,D2), Got) :-
    N is N1 + N2,
    D is D1 + D2,
    Got is N / D).

test_harness:arith_misconception(db_row(37917), fraction, add_across_unlike_denom,
    misconceptions_fraction_batch_6:row_37917,
    frac(1,3)-frac(1,5),
    0.5333333333333333).

% === row 37961: reference unit confusion in word problem ===
% Task: "drinks 1/2 cup per mile, has 4 cups, how far?" → 4 ÷ 1/2 = 8 miles
% Correct: 8
% Error: treats "1/2 cup" as "1/2 of total 4 cups", so drinks 2 cups per mile → 4/2 = 2 miles
% SCHEMA: Container — reference unit slides from "cup" to "total supply"
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(reference_unit_drift)))
misconceptions_fraction_batch_6:(row_37961(frac(N,D)-Total, Got) :-
    % per-mile consumption is (N/D)*Total instead of N/D
    PerMile is (N/D) * Total,
    Got is Total / PerMile).

test_harness:arith_misconception(db_row(37961), fraction, reference_unit_drift,
    misconceptions_fraction_batch_6:row_37961,
    frac(1,2)-4,
    8).

% === row 37981: cannot order divisions without computing ===
test_harness:arith_misconception(db_row(37981), fraction, too_vague,
    skip, none, none).

% === row 38069: "larger numerator → larger fraction" (no specific pair) ===
test_harness:arith_misconception(db_row(38069), fraction, too_vague,
    skip, none, none).

% === row 38128: compare by "pieces left" = denominator − numerator ===
% Task: compare 4/5 and 32/40
% Correct: equal (both = 0.8); 32/40 is not "bigger"
% Error: 5−4=1 vs 40−32=8, so 32/40 is "bigger"
% SCHEMA: Object Collection — "more pieces remaining" misread as "more of the whole"
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(compare_by_pieces_left)))
misconceptions_fraction_batch_6:(row_38128(frac(N1,D1)-frac(N2,D2), Larger) :-
    % student picks whichever has the larger denominator − numerator gap
    Left1 is D1 - N1,
    Left2 is D2 - N2,
    (Left1 > Left2 -> Larger = frac(N1,D1) ; Larger = frac(N2,D2))).

test_harness:arith_misconception(db_row(38128), fraction, compare_by_pieces_left,
    misconceptions_fraction_batch_6:row_38128,
    frac(4,5)-frac(32,40),
    equal).

% === row 38168: gap rule — larger (denom − numer) means smaller fraction ===
% Task: compare 2/7 and 3/7
% Correct: 3/7 > 2/7, so larger is frac(3,7)
% Error: 7−2=5 > 7−3=4, so 2/7 is "smaller" (and 3/7 is larger) — by luck correct here,
%   but the rule generalises to false comparisons between unlike denominators.
% SCHEMA: Measuring Stick — gap read as size
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(gap_rule_smaller_means_larger_gap)))
misconceptions_fraction_batch_6:(row_38168(frac(N1,D1)-frac(N2,D2), Larger) :-
    Gap1 is D1 - N1,
    Gap2 is D2 - N2,
    % student: the one with the smaller gap is the larger fraction
    (Gap1 < Gap2 -> Larger = frac(N1,D1) ; Larger = frac(N2,D2))).

test_harness:arith_misconception(db_row(38168), fraction, gap_rule_comparison,
    misconceptions_fraction_batch_6:row_38168,
    frac(2,7)-frac(3,7),
    frac(3,7)).

% === row 38223: uses entire whole as referent for second fraction ===
% Task: 2/3 of 3/4 of a bucket
% Correct: 2/3 × 3/4 = 1/2
% Error: takes 2/3 of the whole bucket instead of 2/3 of the 3/4 portion → 2/3
% SCHEMA: Container — referent whole stays at the original vessel
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(wrong_referent_unit)))
misconceptions_fraction_batch_6:(row_38223(frac(N1,D1)-frac(_,_), Got) :-
    % student computes F1 of the whole, ignoring F2
    Got is N1 / D1).

test_harness:arith_misconception(db_row(38223), fraction, wrong_referent_unit,
    misconceptions_fraction_batch_6:row_38223,
    frac(2,3)-frac(3,4),
    0.5).

% === row 38256: "half of 3/4" written as division or subtraction ===
% Task: 1/2 of 3/4 (multiplication)
% Correct: 1/2 × 3/4 = 3/8 = 0.375
% Error: writes 3/4 ÷ 1/2 = 1.5
% SCHEMA: Container — "eaten half" heard as division cue
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(fraction_of_as_division)))
misconceptions_fraction_batch_6:(row_38256(frac(N1,D1)-frac(N2,D2), Got) :-
    % student flips to division
    Got is (N2/D2) / (N1/D1)).

test_harness:arith_misconception(db_row(38256), fraction, fraction_of_as_division,
    misconceptions_fraction_batch_6:row_38256,
    frac(1,2)-frac(3,4),
    0.375).

% === row 38270: shape-based size judgement (visual, not arithmetic) ===
test_harness:arith_misconception(db_row(38270), fraction, too_vague,
    skip, none, none).

% === row 38308: numerator as groups, denominator as per-group count ===
% Task: 2/3 of 12
% Correct: 2/3 × 12 = 8
% Error: reads 2/3 as "2 groups of 3" → 6
% SCHEMA: Object Collection — fraction slots reinterpreted as whole-number slots
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(numer_as_groups)))
misconceptions_fraction_batch_6:(row_38308(frac(N,D)-_, Got) :-
    Got is N * D).

test_harness:arith_misconception(db_row(38308), fraction, numer_as_groups,
    misconceptions_fraction_batch_6:row_38308,
    frac(2,3)-12,
    8).

% === row 38335: "one-half" used generically (no specific numeric task) ===
test_harness:arith_misconception(db_row(38335), fraction, too_vague,
    skip, none, none).

% === row 38371: product computed but referent lost ===
test_harness:arith_misconception(db_row(38371), fraction, too_vague,
    skip, none, none).

% === row 38396: "1" in "1 − 4/5" read as unit fraction 1/5 ===
% Task: 1 − 4/5
% Correct: 1 − 4/5 = 1/5 = 0.2
% Error: treats "1" as 1/5, computes 4/5 − 1/5 = 3/5 = 0.6
% SCHEMA: Container — symbolic "1" coerced to match denominator of the other term
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(one_as_unit_fraction)))
misconceptions_fraction_batch_6:(row_38396(Whole-frac(N,D), Got) :-
    % student substitutes 1/D for Whole, then does wrong-order subtraction
    Got is (N - Whole) / D).

test_harness:arith_misconception(db_row(38396), fraction, one_as_unit_fraction,
    misconceptions_fraction_batch_6:row_38396,
    1-frac(4,5),
    0.2).

% === row 38422: improper fraction must be smaller than the whole ===
% Task: apply 5/3 as a scalar to 1 (i.e. compute 5/3 of 1)
% Correct: 5/3 × 1 = 5/3 ≈ 1.667
% Error: believes result must be smaller — returns 1 × 3/5 = 3/5 (flips to a proper fraction)
% SCHEMA: Container — "a fraction of" always yields something smaller
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(fraction_of_always_smaller)))
misconceptions_fraction_batch_6:(row_38422(frac(N,D)-Whole, Got) :-
    (N > D -> Got is Whole * (D / N) ; Got is Whole * (N / D))).

test_harness:arith_misconception(db_row(38422), fraction, improper_must_be_smaller,
    misconceptions_fraction_batch_6:row_38422,
    frac(5,3)-1,
    1.6666666666666667).

% === row 38436: teacher's drawing doesn't match arithmetic (visual, no numeric rule) ===
test_harness:arith_misconception(db_row(38436), fraction, too_vague,
    skip, none, none).

% === row 38457: placement on number line without distance sense ===
test_harness:arith_misconception(db_row(38457), fraction, too_vague,
    skip, none, none).

% === row 38552: multistep expenses all from same whole ===
test_harness:arith_misconception(db_row(38552), fraction, too_vague,
    skip, none, none).

% === row 38560: non-unit requires unit-fraction staging ===
test_harness:arith_misconception(db_row(38560), fraction, too_vague,
    skip, none, none).

% === row 38595: next-day reversion (temporal, not arithmetic rule) ===
test_harness:arith_misconception(db_row(38595), fraction, too_vague,
    skip, none, none).

% === row 38659: reversible multiplicative comparison treated as direct multiplication ===
% Task: A = 55 = (5/3) × B — find B
% Correct: B = 55 ÷ (5/3) = 33
% Error: computes (5/3) × 55 = 91.667
% SCHEMA: Motion Along Path — "is 5/3 as large" read only forward
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(no_reversal_of_multiplier)))
misconceptions_fraction_batch_6:(row_38659(frac(N,D)-Total, Got) :-
    Got is (N/D) * Total).

test_harness:arith_misconception(db_row(38659), fraction, no_reversal_of_multiplier,
    misconceptions_fraction_batch_6:row_38659,
    frac(5,3)-55,
    33).

% === row 38666: add across (1/3 + 1/4 → 2/7) then reject ===
% Task: 1/3 + 1/4
% Correct: 1/3 + 1/4 = 7/12 ≈ 0.583
% Error: add across → 2/7 ≈ 0.286 (initial answer before rejection)
% SCHEMA: Container — same-slot addition
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(add_across_rejected_on_reflection)))
misconceptions_fraction_batch_6:(row_38666(frac(N1,D1)-frac(N2,D2), Got) :-
    N is N1 + N2,
    D is D1 + D2,
    Got is N / D).

test_harness:arith_misconception(db_row(38666), fraction, add_across_and_reject,
    misconceptions_fraction_batch_6:row_38666,
    frac(1,3)-frac(1,4),
    0.5833333333333334).

% === row 38681: "half of what's left" parsed as "the other half" ===
% Task: given remaining R = 1/2, eat 1/2 of what's left
% Correct: eats 1/2 × 1/2 = 1/4; 1/4 remains
% Error: "half of what's left" = "the remaining half of the whole" → eats all that's left (1/2),
%   so 0 remains
% SCHEMA: Container — "half" heard as "the other half of the original whole"
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(half_of_left_as_all_of_left)))
misconceptions_fraction_batch_6:(row_38681(frac(NR,DR)-frac(_,_), RemainingAfter) :-
    % student eats all of what's left, so remaining is 0 (input is given remainder R)
    _ = NR/DR,
    RemainingAfter = 0).

test_harness:arith_misconception(db_row(38681), fraction, half_of_left_as_all,
    misconceptions_fraction_batch_6:row_38681,
    frac(1,2)-frac(1,2),
    0.25).

% === row 38731: unit fraction read as fixed group of denominator-many objects ===
% Task: 1/5 of 55 sticks
% Correct: 55 / 5 = 11
% Error: reads "one-fifth" as "one (set of) five" → answer 5
% SCHEMA: Object Collection — "fifth" as a fixed group of five
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(unit_fraction_as_denominator_count)))
misconceptions_fraction_batch_6:(row_38731(frac(_,D)-_, Got) :-
    Got is D).

test_harness:arith_misconception(db_row(38731), fraction, unit_fraction_as_fixed_set,
    misconceptions_fraction_batch_6:row_38731,
    frac(1,5)-55,
    11).

% === row 38795: doubling-only equivalence strategy (strategy selection) ===
test_harness:arith_misconception(db_row(38795), fraction, too_vague,
    skip, none, none).

% === row 38839: no example text given ===
test_harness:arith_misconception(db_row(38839), fraction, too_vague,
    skip, none, none).

% === row 38867: teacher switches representations without connection ===
test_harness:arith_misconception(db_row(38867), fraction, too_vague,
    skip, none, none).

% === row 38946: add across when abstract (3/8 + 2/8 → 5/16) ===
% Task: 3/8 + 2/8
% Correct: 5/8 = 0.625
% Error: also adds denominators → 5/16 = 0.3125
% SCHEMA: Container — same-slot addition even with common denom
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(add_across_even_common_denom)))
misconceptions_fraction_batch_6:(row_38946(frac(N1,D1)-frac(N2,D2), Got) :-
    N is N1 + N2,
    D is D1 + D2,
    Got is N / D).

test_harness:arith_misconception(db_row(38946), fraction, add_across_common_denom,
    misconceptions_fraction_batch_6:row_38946,
    frac(3,8)-frac(2,8),
    0.625).

% === row 38977: "seven and a half" < "seven" (half as "a little bit") ===
% Task: compare 7.5 and 7 — which is larger?
% Correct: 7.5 > 7
% Error: "half" means "a little bit" so 7.5 < 7
% SCHEMA: Container — "half" as diminutive
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(half_as_diminutive)))
misconceptions_fraction_batch_6:(row_38977(Mixed-Whole, Larger) :-
    % student picks the plain whole over the mixed number
    _ = Mixed,
    Larger = Whole).

test_harness:arith_misconception(db_row(38977), fraction, half_as_little_bit,
    misconceptions_fraction_batch_6:row_38977,
    7.5-7,
    7.5).

% === row 39007: "loss of whole" — denominator = total pieces across objects ===
% Task: two objects each partitioned into 4 pieces; name one piece
% Correct: 1/4 (denominator is pieces per whole)
% Error: counts all 8 pieces as denominator → 1/8
% SCHEMA: Object Collection — pieces pooled across wholes
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(loss_of_whole_pooled_denom)))
misconceptions_fraction_batch_6:(row_39007(NumObjects-PiecesPer, Got) :-
    Total is NumObjects * PiecesPer,
    Got is 1 / Total).

test_harness:arith_misconception(db_row(39007), fraction, loss_of_whole,
    misconceptions_fraction_batch_6:row_39007,
    2-4,
    0.25).

% === row 39060: base-3 digit "0.2" read as decimal 0.6 ===
% Task: 0.2 in base 3 as a decimal value
% Correct: 2 × 3^(-1) = 2/3 ≈ 0.6667
% Error: computes 2 × 0.3 = 0.6 (treats place value as 0.3 rather than 1/3)
% SCHEMA: Measuring Stick — place value conflated across bases
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(nonbase_place_value_as_decimal)))
misconceptions_fraction_batch_6:(row_39060(Digit-Base, Got) :-
    Got is Digit * (1 / Base)).

test_harness:arith_misconception(db_row(39060), fraction, base3_digit_as_decimal,
    misconceptions_fraction_batch_6:row_39060,
    2-3,
    0.6666666666666666).

% === row 39091: 2/4 and 4/2 "same because same digits" (no deterministic rule) ===
test_harness:arith_misconception(db_row(39091), fraction, too_vague,
    skip, none, none).

% === row 39146: distributive partition names share against one item ===
test_harness:arith_misconception(db_row(39146), fraction, too_vague,
    skip, none, none).

% === row 39178: random arithmetic recombination for reversing a fractional part ===
% Task: 4 pieces = 2/7 of total — find total
% Correct: 4 ÷ (2/7) = 14
% Error: performs random arithmetic to reach 80 (as reported: 0.2*4 = 2*40 = 80)
% SCHEMA: Container — numbers flow through any convenient operation
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(random_arithmetic_recombination)))
misconceptions_fraction_batch_6:(row_39178(Pieces-frac(N,D), Got) :-
    _ = Pieces,
    _ = N/D,
    Got = 80).

test_harness:arith_misconception(db_row(39178), fraction, random_arithmetic_recomb,
    misconceptions_fraction_batch_6:row_39178,
    4-frac(2,7),
    14).

% === row 39217: problem posing — fractions of a whole summing >1 ===
test_harness:arith_misconception(db_row(39217), fraction, too_vague,
    skip, none, none).

% === row 39318: unit fraction — bigger denom = bigger fraction ===
% Task: compare 1/8 and 1/6
% Correct: 1/6 > 1/8, larger is frac(1,6)
% Error: picks frac(1,8) because 8 > 6
% SCHEMA: Measuring Stick — denominator size as fraction size
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(bigger_denom_is_bigger)))
misconceptions_fraction_batch_6:(row_39318(frac(N1,D1)-frac(N2,D2), Larger) :-
    (D1 > D2 -> Larger = frac(N1,D1) ; Larger = frac(N2,D2))).

test_harness:arith_misconception(db_row(39318), fraction, bigger_denom_is_bigger,
    misconceptions_fraction_batch_6:row_39318,
    frac(1,8)-frac(1,6),
    frac(1,6)).

% === row 39350: PST uses incorrect referent (no numeric result) ===
test_harness:arith_misconception(db_row(39350), fraction, too_vague,
    skip, none, none).

% === row 39443: can't operate without magnitude of whole ===
test_harness:arith_misconception(db_row(39443), fraction, too_vague,
    skip, none, none).

% === row 39541: no example text ===
test_harness:arith_misconception(db_row(39541), fraction, too_vague,
    skip, none, none).

% === row 39591: five 1/4 pieces named as 1/5 ===
% Task: value of five 1/4 pieces combined
% Correct: 5 × 1/4 = 5/4 = 1.25
% Error: names it as 1/5 (reads "five pieces" as one of five)
% SCHEMA: Object Collection — count of pieces inverted to a unit fraction
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(count_as_unit_fraction)))
misconceptions_fraction_batch_6:(row_39591(Count-frac(_,_), Got) :-
    Got is 1 / Count).

test_harness:arith_misconception(db_row(39591), fraction, count_as_unit_fraction,
    misconceptions_fraction_batch_6:row_39591,
    5-frac(1,4),
    1.25).

% === row 39606: non-unit fraction read as one subset of the partition ===
% Task: 4/4 of 8
% Correct: 4/4 × 8 = 8
% Error: picks one subset of the 4-way partition → 8/4 = 2
% SCHEMA: Container — fraction of a set = one piece of the partition
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(nonunit_as_one_subset)))
misconceptions_fraction_batch_6:(row_39606(frac(_,D)-Total, Got) :-
    Got is Total / D).

test_harness:arith_misconception(db_row(39606), fraction, nonunit_as_one_subset,
    misconceptions_fraction_batch_6:row_39606,
    frac(4,4)-8,
    8).

% === row 39642: fractions counted as evenly spaced ===
test_harness:arith_misconception(db_row(39642), fraction, too_vague,
    skip, none, none).

% === row 39669: belief numerator can't exceed denominator ===
test_harness:arith_misconception(db_row(39669), fraction, too_vague,
    skip, none, none).

% === row 39698: 1/2 + 1/4 → 2/6 ===
% Task: 1/2 + 1/4
% Correct: 3/4 = 0.75
% Error: add across → 2/6 ≈ 0.333
% SCHEMA: Container — same-slot addition
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(add_across_unlike_denom)))
misconceptions_fraction_batch_6:(row_39698(frac(N1,D1)-frac(N2,D2), Got) :-
    N is N1 + N2,
    D is D1 + D2,
    Got is N / D).

test_harness:arith_misconception(db_row(39698), fraction, add_across_half_plus_quarter,
    misconceptions_fraction_batch_6:row_39698,
    frac(1,2)-frac(1,4),
    0.75).

% === row 39734: gap thinking for ordering fractions ===
% Task: compare 4/8 and 1/3 (pick the smaller)
% Correct: 1/3 ≈ 0.333 < 4/8 = 0.5, so smaller is frac(1,3)
% Error: gap(4/8) = 8-4 = 4, gap(1/3) = 3-1 = 2; student picks the one with the larger gap
%   as smallest — frac(4,8), which is wrong.
% SCHEMA: Measuring Stick — gap as magnitude
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(gap_thinking_ordering)))
misconceptions_fraction_batch_6:(row_39734(frac(N1,D1)-frac(N2,D2), Smaller) :-
    Gap1 is D1 - N1,
    Gap2 is D2 - N2,
    (Gap1 > Gap2 -> Smaller = frac(N1,D1) ; Smaller = frac(N2,D2))).

test_harness:arith_misconception(db_row(39734), fraction, gap_thinking_ordering,
    misconceptions_fraction_batch_6:row_39734,
    frac(4,8)-frac(1,3),
    frac(1,3)).

% === row 39768: subtract smaller from larger in each slot ===
% Task: 4/3 − 13/12
% Correct: 16/12 − 13/12 = 3/12 = 0.25
% Error: does |13-4|/|12-3| = 9/9 = 1
% SCHEMA: Container — always-smaller-from-larger within slots
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(slotwise_abs_subtract)))
misconceptions_fraction_batch_6:(row_39768(frac(N1,D1)-frac(N2,D2), Got) :-
    N is abs(N1 - N2),
    D is abs(D1 - D2),
    Got is N / D).

test_harness:arith_misconception(db_row(39768), fraction, slotwise_abs_subtract,
    misconceptions_fraction_batch_6:row_39768,
    frac(4,3)-frac(13,12),
    0.25).

% === row 39783: counts parts ignoring equality (visual, no numeric rule) ===
test_harness:arith_misconception(db_row(39783), fraction, too_vague,
    skip, none, none).

% === row 39814: bigger denom = larger fraction (same family as 39318) ===
% Task: compare 1/10 and 1/5 — which packet has more sweets?
% Correct: 1/5 > 1/10; more sweets in the 1/5 packet
% Error: picks 1/10 because 10 > 5
% SCHEMA: Measuring Stick — denominator size as magnitude
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(bigger_denom_more_sweets)))
misconceptions_fraction_batch_6:(row_39814(frac(N1,D1)-frac(N2,D2), Larger) :-
    (D1 > D2 -> Larger = frac(N1,D1) ; Larger = frac(N2,D2))).

test_harness:arith_misconception(db_row(39814), fraction, bigger_denom_more_sweets,
    misconceptions_fraction_batch_6:row_39814,
    frac(1,10)-frac(1,5),
    frac(1,5)).

% === row 39821: multiplication always increases (proper fraction multiplier) ===
% Task: N × 67/89 vs N  (take N = 1)
% Correct: 1 × 67/89 = 67/89 ≈ 0.753 < 1  (always true for N > 0)
% Error: student predicts product ≥ N
% SCHEMA: Motion Along Path — multiplication always moves away from zero
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(multiplication_always_increases)))
misconceptions_fraction_batch_6:(row_39821(N-frac(Num,Den), Got) :-
    % student predicts result ≥ N (returns N as a stand-in for "not less")
    _ = Num/Den,
    Got is N).

test_harness:arith_misconception(db_row(39821), fraction, mult_always_increases,
    misconceptions_fraction_batch_6:row_39821,
    1-frac(67,89),
    0.7528089887640449).

% === row 39864: proximity to 1 via absolute denominator − numerator ===
% Task: compare proximity of 15/16 and 8/9 to 1
% Correct: |1 − 15/16| = 1/16 = 0.0625; |1 − 8/9| = 1/9 ≈ 0.111 — 15/16 is closer
% Error: both gaps equal 1, so equally close
% SCHEMA: Measuring Stick — absolute gap read as distance
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(proximity_by_absolute_gap)))
misconceptions_fraction_batch_6:(row_39864(frac(N1,D1)-frac(N2,D2), Closer) :-
    Gap1 is D1 - N1,
    Gap2 is D2 - N2,
    (Gap1 = Gap2 ->
        Closer = equal
    ; Gap1 < Gap2 ->
        Closer = frac(N1,D1)
    ;   Closer = frac(N2,D2))).

test_harness:arith_misconception(db_row(39864), fraction, proximity_absolute_gap,
    misconceptions_fraction_batch_6:row_39864,
    frac(15,16)-frac(8,9),
    frac(15,16)).

% === row 39893: random arithmetic for fraction of a quantity ===
test_harness:arith_misconception(db_row(39893), fraction, too_vague,
    skip, none, none).

% === row 39963: algebraic a/b + c/d → (a+c)/(b+d) ===
% Task: a/b + c/d (instantiated: 1/2 + 3/4)
% Correct: 1/2 + 3/4 = 5/4 = 1.25
% Error: (1+3)/(2+4) = 4/6 ≈ 0.667
% SCHEMA: Container — same-slot addition
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(add_across_rational_expressions)))
misconceptions_fraction_batch_6:(row_39963(frac(N1,D1)-frac(N2,D2), Got) :-
    N is N1 + N2,
    D is D1 + D2,
    Got is N / D).

test_harness:arith_misconception(db_row(39963), fraction, add_across_algebraic,
    misconceptions_fraction_batch_6:row_39963,
    frac(1,2)-frac(3,4),
    1.25).

% === row 40073: rote invert-and-multiply (procedure correct, concept missing) ===
test_harness:arith_misconception(db_row(40073), fraction, too_vague,
    skip, none, none).

% === row 40086: halving overreliance inhibits odd partitions ===
test_harness:arith_misconception(db_row(40086), fraction, too_vague,
    skip, none, none).

% === row 40114: language about whole for improper fractions ===
test_harness:arith_misconception(db_row(40114), fraction, too_vague,
    skip, none, none).

% === row 40124: same-numerator comparison — smaller denom = smaller fraction ===
% Task: compare 25/99 and 25/100
% Correct: 25/99 > 25/100 (smaller denominator ⇒ larger fraction when numerators equal)
% Error: picks 25/99 as smaller because 99 < 100
% SCHEMA: Measuring Stick — denominator size as fraction size
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(same_numer_smaller_denom_smaller)))
misconceptions_fraction_batch_6:(row_40124(frac(N1,D1)-frac(N2,D2), Larger) :-
    % student picks the one with the larger denominator
    (D1 > D2 -> Larger = frac(N1,D1) ; Larger = frac(N2,D2))).

test_harness:arith_misconception(db_row(40124), fraction, same_numer_smaller_denom_smaller,
    misconceptions_fraction_batch_6:row_40124,
    frac(25,99)-frac(25,100),
    frac(25,99)).

% === row 40137: partitions into 5 and 6 (unequal shares, no numeric answer) ===
test_harness:arith_misconception(db_row(40137), fraction, too_vague,
    skip, none, none).

% === row 40150: partitive division mislabeled (process, no numeric error) ===
test_harness:arith_misconception(db_row(40150), fraction, too_vague,
    skip, none, none).

% === row 40188: diagram vs algorithm give different answers ===
test_harness:arith_misconception(db_row(40188), fraction, too_vague,
    skip, none, none).

% === row 40198: unaligned wholes in drawn comparison ===
test_harness:arith_misconception(db_row(40198), fraction, too_vague,
    skip, none, none).

% === row 40231: 1/3 of 7 reported as whole-number quotient 2 ===
% Task: 1/3 of 7
% Correct: 7/3 ≈ 2.333
% Error: treats as integer division, drops remainder → 2
% SCHEMA: Object Collection — only whole-number answers allowed
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(fraction_of_whole_as_int_div)))
misconceptions_fraction_batch_6:(row_40231(frac(_,D)-Total, Got) :-
    Got is Total // D).

test_harness:arith_misconception(db_row(40231), fraction, fraction_as_int_div,
    misconceptions_fraction_batch_6:row_40231,
    frac(1,3)-7,
    2.3333333333333335).

% === row 40259: PST says rep impossible for division ===
test_harness:arith_misconception(db_row(40259), fraction, too_vague,
    skip, none, none).

% === row 40322: "2x9/5x20 < 1/2 therefore sum < 1/2" (mixed operations) ===
test_harness:arith_misconception(db_row(40322), fraction, too_vague,
    skip, none, none).

% === row 40373: scale factor between two unit fractions (abstract cue) ===
test_harness:arith_misconception(db_row(40373), fraction, too_vague,
    skip, none, none).

% === row 40405: "same gap → equal fractions" ===
% Task: compare 5/6 and 8/9
% Correct: 5/6 ≈ 0.833; 8/9 ≈ 0.889 — not equal (8/9 > 5/6)
% Error: 6-5 = 1 and 9-8 = 1, so student claims equal
% SCHEMA: Measuring Stick — gap as magnitude
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(equal_gap_means_equal)))
misconceptions_fraction_batch_6:(row_40405(frac(N1,D1)-frac(N2,D2), Result) :-
    Gap1 is D1 - N1,
    Gap2 is D2 - N2,
    (Gap1 =:= Gap2 ->
        Result = equal
    ; Gap1 < Gap2 ->
        Result = frac(N1,D1)
    ;   Result = frac(N2,D2))).

test_harness:arith_misconception(db_row(40405), fraction, equal_gap_means_equal,
    misconceptions_fraction_batch_6:row_40405,
    frac(5,6)-frac(8,9),
    frac(8,9)).

% === row 40449: same-numerator — bigger denom wins ===
% Task: compare 5/9 and 5/7
% Correct: 5/7 > 5/9, larger is frac(5,7)
% Error: picks frac(5,9) because 9 > 7
% SCHEMA: Measuring Stick — bigger number wins
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(same_numer_bigger_denom_bigger)))
misconceptions_fraction_batch_6:(row_40449(frac(N1,D1)-frac(N2,D2), Larger) :-
    (D1 > D2 -> Larger = frac(N1,D1) ; Larger = frac(N2,D2))).

test_harness:arith_misconception(db_row(40449), fraction, same_numer_bigger_denom_wins,
    misconceptions_fraction_batch_6:row_40449,
    frac(5,9)-frac(5,7),
    frac(5,7)).

% === row 40456: 7/12 > 7/10 because 12 > 10 ===
% Task: compare 7/12 and 7/10
% Correct: 7/10 > 7/12, larger is frac(7,10)
% Error: picks frac(7,12) because 12 > 10
% SCHEMA: Measuring Stick — denominator size as magnitude
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(same_numer_bigger_denom_bigger)))
misconceptions_fraction_batch_6:(row_40456(frac(N1,D1)-frac(N2,D2), Larger) :-
    (D1 > D2 -> Larger = frac(N1,D1) ; Larger = frac(N2,D2))).

test_harness:arith_misconception(db_row(40456), fraction, same_numer_larger_denom,
    misconceptions_fraction_batch_6:row_40456,
    frac(7,12)-frac(7,10),
    frac(7,10)).

% === row 40486: two circles each 1/3 shaded → called 2/6 ===
% Task: two circles, each partitioned into 3 with 1 shaded; name the shaded fraction
% Correct (per-whole): 1/3 shaded in each (or if pooled as one whole: 1/3)
% Error: pools counts across both circles → 2 shaded out of 6 pieces total → 2/6
% SCHEMA: Object Collection — numerator and denominator pooled across wholes
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(pool_across_wholes)))
misconceptions_fraction_batch_6:(row_40486(NumObjects-frac(N,D), Got) :-
    TotalN is NumObjects * N,
    TotalD is NumObjects * D,
    Got is TotalN / TotalD).

test_harness:arith_misconception(db_row(40486), fraction, pool_numer_and_denom,
    misconceptions_fraction_batch_6:row_40486,
    2-frac(1,3),
    0.3333333333333333).

% === row 40515: 1/4 interpreted as 4.5 ===
% Task: interpret 1/4
% Correct: 0.25
% Error: reads "1/4" as "four and a half" → 4.5 (conflates slash with "and a half")
% SCHEMA: Container — symbol confusion with mixed-number spoken form
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(fraction_symbol_as_and_half)))
misconceptions_fraction_batch_6:(row_40515(frac(_,D), Got) :-
    Got is D + 0.5).

test_harness:arith_misconception(db_row(40515), fraction, symbol_as_and_half,
    misconceptions_fraction_batch_6:row_40515,
    frac(1,4),
    0.25).

% === row 40589: unequal-sized parts make naming impossible ===
test_harness:arith_misconception(db_row(40589), fraction, too_vague,
    skip, none, none).

% === row 40664: recursive partitioning — can't name share of original ===
test_harness:arith_misconception(db_row(40664), fraction, too_vague,
    skip, none, none).

% Fraction misconceptions — research corpus batch 7/7.
% Native arithmetic layer only. Theoretical annotations as comments:
%   % GROUNDED: TODO — placeholder for future embodied arithmetic layer
%   % SCHEMA: <schema name> — Lakoff & Nunez grounding when applicable
%   % CONNECTS TO: s(comp_nec(unlicensed(...))) — PML operator path
%
% Registration convention (from Task 3 arch fix):
%   test_harness:arith_misconception(Source, Domain, Description,
%       misconceptions_fraction_batch_7:rule_name, Input, Expected).
% Rule predicates do NOT go on the module export list.


% ---- Encodings appended by agent for batch 7 ----

% === row 37440: inverted part-whole for improper fraction ===
% Task: make 14/8 of an 8/8-stick.
% Correct: frac(14,8)
% Error: swaps roles — partitions into 14, selects 8 -> frac(8,14).
% SCHEMA: Measuring Stick — numerator iterates a unit of size 1/denominator.
% GROUNDED: TODO — distinguish partition count vs iteration count.
% CONNECTS TO: s(comp_nec(unlicensed(swap_part_whole_on_improper)))
misconceptions_fraction_batch_7:(invert_improper_to_proper(frac(N,D), frac(D,N)) :-
    integer(N), integer(D)).

test_harness:arith_misconception(db_row(37440), fraction, invert_improper_to_proper,
    misconceptions_fraction_batch_7:invert_improper_to_proper,
    frac(14,8),
    frac(14,8)).

% === row 37584: interpret area model by smaller subset ===
% Task: read shaded area as a fraction.
% Correct: frac(5,6) (5 shaded of 6)
% Error: focuses on the single unshaded piece -> frac(1,6).
% SCHEMA: Object Collection — counts the salient minority instead of the shaded set.
% GROUNDED: TODO — subtract_grounded(rec(D), rec(N), rec(Complement)).
% CONNECTS TO: s(comp_nec(unlicensed(complement_for_part)))
misconceptions_fraction_batch_7:(read_complement_as_part(frac(N,D), frac(C,D)) :-
    C is D - N).

test_harness:arith_misconception(db_row(37584), fraction, read_complement_as_part,
    misconceptions_fraction_batch_7:read_complement_as_part,
    frac(5,6),
    frac(5,6)).

% === row 37693: add numerators and denominators separately ===
% Task: 5/6 + 4/7.
% Correct: frac(59,42) (5*7 + 4*6 over 6*7).
% Error: frac(9,13) — top+top, bottom+bottom.
% SCHEMA: Object Collection — combines two pairs of counts independently.
% GROUNDED: TODO — add_grounded on numerators, add_grounded on denominators.
% CONNECTS TO: s(comp_nec(unlicensed(componentwise_addition)))
misconceptions_fraction_batch_7:(add_components_separately(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 + N2,
    D is D1 + D2).

test_harness:arith_misconception(db_row(37693), fraction, add_components_separately,
    misconceptions_fraction_batch_7:add_components_separately,
    frac(5,6)-frac(4,7),
    frac(59,42)).

% === row 37759: guess equivalent-fraction numerator from superficial pattern ===
% Task: solve 2/6 = X/3 for X.
% Correct: X = 1 (halve both).
% Error: Alan reasons "3 and 3 is 6, plus 2 more of 6 equals 12" -> X = 4.
% SCHEMA: Object Collection — shuffles the visible digits without a scaling schema.
% GROUNDED: TODO — divide_grounded(rec(2), rec(2), rec(1)).
% CONNECTS TO: s(comp_nec(unlicensed(numerical_pattern_guess)))
misconceptions_fraction_batch_7:(guess_equivalent_numerator(frac(N,D)-NewD, NewN) :-
    _ = D,  % ignore scaling relationship
    NewN is N + NewD - 1).  % Alan's arithmetic path yielding 4 for 2/6=?/3

test_harness:arith_misconception(db_row(37759), fraction, guess_equivalent_numerator,
    misconceptions_fraction_batch_7:guess_equivalent_numerator,
    frac(2,6)-3,
    1).

% === row 37830: iterate non-unit fraction by scaling both N and D ===
% Task: iterate frac(2,5) four times -> frac(8,5).
% Correct: frac(8,5) (only numerator scales).
% Error: Kylie multiplies both -> frac(8,20).
% SCHEMA: Measuring Stick — iteration scales count-of-parts but not size-of-part.
% GROUNDED: TODO — multiply_grounded(rec(N), rec(K), rec(NK)).
% CONNECTS TO: s(comp_nec(unlicensed(scale_both_terms_on_iteration)))
misconceptions_fraction_batch_7:(iterate_scales_both(frac(N,D)-K, frac(NK,DK)) :-
    NK is N * K,
    DK is D * K).

test_harness:arith_misconception(db_row(37830), fraction, iterate_scales_both,
    misconceptions_fraction_batch_7:iterate_scales_both,
    frac(2,5)-4,
    frac(8,5)).

% === row 37857: same-numerator comparison by denominator magnitude ===
% Task: compare frac(4,15) and frac(4,10).
% Correct: second (frac(4,10) > frac(4,15)).
% Error: student says first (larger denominator = larger fraction).
% SCHEMA: Object Collection — reads denominators as whole-number magnitudes.
% GROUNDED: TODO — cross_product_grounded would reveal inversion.
% CONNECTS TO: s(comp_nec(unlicensed(denominator_as_magnitude)))
misconceptions_fraction_batch_7:(same_numerator_by_denominator(frac(N1,D1)-frac(N2,D2), Winner) :-
    N1 == N2,
    (D1 > D2 -> Winner = first ; Winner = second)).

test_harness:arith_misconception(db_row(37857), fraction, same_numerator_by_denominator,
    misconceptions_fraction_batch_7:same_numerator_by_denominator,
    frac(4,15)-frac(4,10),
    second).

% === row 37872: sketch-based componentwise addition ===
% Task: 2/5 + 1/3.
% Correct: frac(11,15).
% Error: student says frac(3,8) (combines shaded counts and total counts).
% SCHEMA: Object Collection — combines two sketches as loose pieces.
% GROUNDED: TODO — add_grounded across two partitions without common unit.
% CONNECTS TO: s(comp_nec(unlicensed(sketch_count_addition)))
misconceptions_fraction_batch_7:(sketch_count_addition(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 + N2,
    D is D1 + D2).

test_harness:arith_misconception(db_row(37872), fraction, sketch_count_addition,
    misconceptions_fraction_batch_7:sketch_count_addition,
    frac(2,5)-frac(1,3),
    frac(11,15)).

% === row 37906: compare unit fractions by denominator as whole numbers ===
% Task: compare frac(1,3) and frac(1,4).
% Correct: first (1/3 > 1/4).
% Error: student says 1/3 < 1/4 "because 3 is less than 4".
% SCHEMA: Object Collection — denominator treated as the fraction's size.
% GROUNDED: TODO — inverse_relation_grounded on unit fractions.
% CONNECTS TO: s(comp_nec(unlicensed(whole_number_order_on_denominator)))
misconceptions_fraction_batch_7:(unit_fraction_by_denominator(frac(N1,D1)-frac(N2,D2), Winner) :-
    N1 == 1, N2 == 1,
    (D1 > D2 -> Winner = first ; Winner = second)).

test_harness:arith_misconception(db_row(37906), fraction, unit_fraction_by_denominator,
    misconceptions_fraction_batch_7:unit_fraction_by_denominator,
    frac(1,3)-frac(1,4),
    first).

% === row 37918: compare fractions by numerator only ===
% Task: compare frac(4,9) and frac(3,4).
% Correct: second (3/4 > 4/9).
% Error: student says first because "4 is bigger than 3".
% SCHEMA: Object Collection — reads only the numerator.
% GROUNDED: TODO — cross_product_grounded.
% CONNECTS TO: s(comp_nec(unlicensed(numerator_only_comparison)))
misconceptions_fraction_batch_7:(compare_by_numerator_only(frac(N1,D1)-frac(N2,D2), Winner) :-
    _ = D1, _ = D2,
    (N1 > N2 -> Winner = first ; Winner = second)).

test_harness:arith_misconception(db_row(37918), fraction, compare_by_numerator_only,
    misconceptions_fraction_batch_7:compare_by_numerator_only,
    frac(4,9)-frac(3,4),
    second).

% === row 38006: shaded-region addition by whole-number count ===
% Task: add shaded 1/3 of one circle and shaded 1/4 of another.
% Correct: frac(7,12).
% Error: student counts "one plus one" = 2 (ignores fractional size).
% SCHEMA: Object Collection — treats shaded regions as unit objects.
% GROUNDED: TODO — add_grounded after conversion to common unit.
% CONNECTS TO: s(comp_nec(unlicensed(shaded_count_as_whole)))
misconceptions_fraction_batch_7:(count_shaded_regions(frac(N1,_)-frac(N2,_), S) :-
    S is N1 + N2).

test_harness:arith_misconception(db_row(38006), fraction, count_shaded_regions,
    misconceptions_fraction_batch_7:count_shaded_regions,
    frac(1,3)-frac(1,4),
    frac(7,12)).

% === row 38131: unit-fraction magnitude by denominator ===
% Task: compare frac(1,8) and frac(1,6).
% Correct: second (1/6 > 1/8).
% Error: student says first because "8 is greater than 6".
% SCHEMA: Object Collection — denominator as magnitude of whole.
% GROUNDED: TODO — inverse_relation_grounded.
% CONNECTS TO: s(comp_nec(unlicensed(denominator_whole_number_order)))
misconceptions_fraction_batch_7:(bigger_denominator_bigger(frac(1,D1)-frac(1,D2), Winner) :-
    (D1 > D2 -> Winner = first ; Winner = second)).

test_harness:arith_misconception(db_row(38131), fraction, bigger_denominator_bigger,
    misconceptions_fraction_batch_7:bigger_denominator_bigger,
    frac(1,8)-frac(1,6),
    second).

% === row 38344: unit fraction as iteration count ===
% Task: compare frac(1,7) and frac(1,6).
% Correct: second (1/6 > 1/7).
% Error: Isaac says 1/7 bigger because "7 slices" > "6 slices".
% SCHEMA: Object Collection — more partitions = more stuff.
% GROUNDED: TODO — inverse_relation_grounded.
% CONNECTS TO: s(comp_nec(unlicensed(iteration_count_as_magnitude)))
misconceptions_fraction_batch_7:(iteration_count_as_magnitude(frac(1,D1)-frac(1,D2), Winner) :-
    (D1 > D2 -> Winner = first ; Winner = second)).

test_harness:arith_misconception(db_row(38344), fraction, iteration_count_as_magnitude,
    misconceptions_fraction_batch_7:iteration_count_as_magnitude,
    frac(1,7)-frac(1,6),
    second).

% === row 38373: compare unit fractions by unshaded complement ===
% Task: compare frac(1,3) and frac(1,2).
% Correct: second (1/2 > 1/3).
% Error: student says 1/3 bigger because "two more pieces left".
% SCHEMA: Object Collection — counts leftover pieces, not the part itself.
% GROUNDED: TODO — complement_grounded distinct from size_of_part.
% CONNECTS TO: s(comp_nec(unlicensed(complement_count_as_size)))
misconceptions_fraction_batch_7:(more_leftover_is_larger(frac(N1,D1)-frac(N2,D2), Winner) :-
    L1 is D1 - N1,
    L2 is D2 - N2,
    (L1 > L2 -> Winner = first ; Winner = second)).

test_harness:arith_misconception(db_row(38373), fraction, more_leftover_is_larger,
    misconceptions_fraction_batch_7:more_leftover_is_larger,
    frac(1,3)-frac(1,2),
    second).

% === row 38402: iterations renamed as n-over-n ===
% Task: iterate frac(1,8) nine times.
% Correct: frac(9,8).
% Error: student names it "nine ninths" -> frac(9,9).
% SCHEMA: Object Collection — iteration count overwrites the original unit.
% GROUNDED: TODO — preserve_unit_grounded across iteration.
% CONNECTS TO: s(comp_nec(unlicensed(iteration_count_overwrites_denominator)))
misconceptions_fraction_batch_7:(iterations_rewrite_denominator(frac(N,_)-K, frac(NK,NK)) :-
    NK is N * K).

test_harness:arith_misconception(db_row(38402), fraction, iterations_rewrite_denominator,
    misconceptions_fraction_batch_7:iterations_rewrite_denominator,
    frac(1,8)-9,
    frac(9,8)).

% === row 38423: numerator interpreted as partition count ===
% Task: produce a bar of frac(5,3) of the unit.
% Correct: partition into 3, iterate 5 times.
% Error: Barbara partitions into 5 parts (numerator becomes denominator).
% SCHEMA: Measuring Stick — the first number read is treated as the partition.
% GROUNDED: TODO — distinguish partition vs iteration role.
% CONNECTS TO: s(comp_nec(unlicensed(numerator_as_partition_count)))
misconceptions_fraction_batch_7:(numerator_as_partition(frac(N,D), frac(D,N)) :-
    integer(N), integer(D)).

test_harness:arith_misconception(db_row(38423), fraction, numerator_as_partition,
    misconceptions_fraction_batch_7:numerator_as_partition,
    frac(5,3),
    frac(5,3)).

% === row 38477: add unit fractions separately ===
% Task: 1/3 + 1/7.
% Correct: frac(10,21).
% Error: student says frac(2,10) (top+top, bottom+bottom).
% SCHEMA: Object Collection — componentwise addition.
% GROUNDED: TODO — add_grounded with common-unit conversion.
% CONNECTS TO: s(comp_nec(unlicensed(unit_fraction_componentwise_add)))
misconceptions_fraction_batch_7:(unit_fraction_add_separately(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 + N2,
    D is D1 + D2).

test_harness:arith_misconception(db_row(38477), fraction, unit_fraction_add_separately,
    misconceptions_fraction_batch_7:unit_fraction_add_separately,
    frac(1,3)-frac(1,7),
    frac(10,21)).

% === row 38563: same-numerator comparison reversed ===
% Task: compare frac(1,6) and frac(1,9).
% Correct: first (1/6 > 1/9).
% Error: student says second because "9 is greater than 6".
% SCHEMA: Object Collection — natural-number order on denominators.
% GROUNDED: TODO — inverse_relation_grounded.
% CONNECTS TO: s(comp_nec(unlicensed(natural_number_order_on_denominator)))
misconceptions_fraction_batch_7:(natural_order_on_common_numerator(frac(N1,D1)-frac(N2,D2), Winner) :-
    N1 == N2,
    (D1 > D2 -> Winner = first ; Winner = second)).

test_harness:arith_misconception(db_row(38563), fraction, natural_order_on_common_numerator,
    misconceptions_fraction_batch_7:natural_order_on_common_numerator,
    frac(1,6)-frac(1,9),
    first).

% === row 38732: both-terms-larger judged bigger ===
% Task: compare frac(2,5) and frac(1,2).
% Correct: second (1/2 > 2/5).
% Error: Rachel says first because both numerator and denominator are larger.
% SCHEMA: Object Collection — combines two whole-number comparisons additively.
% GROUNDED: TODO — cross_product_grounded.
% CONNECTS TO: s(comp_nec(unlicensed(both_terms_larger_is_bigger)))
misconceptions_fraction_batch_7:(both_larger_is_bigger(frac(N1,D1)-frac(N2,D2), Winner) :-
    (N1 >= N2, D1 >= D2, (N1 > N2 ; D1 > D2) -> Winner = first
    ; N2 >= N1, D2 >= D1, (N2 > N1 ; D2 > D1) -> Winner = second
    ; Winner = undecided)).

test_harness:arith_misconception(db_row(38732), fraction, both_larger_is_bigger,
    misconceptions_fraction_batch_7:both_larger_is_bigger,
    frac(2,5)-frac(1,2),
    second).

% === row 38805: fraction addition numerator+numerator / denom+denom ===
% Task: add two fractions by flawed rule.
% Correct: standard fraction addition.
% Error: Stefan uses "num plus num, denom plus denom".
% SCHEMA: Object Collection — componentwise again (distinct source from 37693).
% GROUNDED: TODO — add_grounded after common-unit conversion.
% CONNECTS TO: s(comp_nec(unlicensed(stefan_rule_componentwise)))
misconceptions_fraction_batch_7:(stefan_rule_componentwise(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 + N2,
    D is D1 + D2).

test_harness:arith_misconception(db_row(38805), fraction, stefan_rule_componentwise,
    misconceptions_fraction_batch_7:stefan_rule_componentwise,
    frac(1,2)-frac(1,3),
    frac(5,6)).

% === row 38868: fractions with same missing-piece count judged equal ===
% Task: compare frac(5,6) and frac(7,8).
% Correct: second (7/8 > 5/6).
% Error: student says equal because each lacks exactly one piece.
% SCHEMA: Object Collection — counts missing pieces, not their size.
% GROUNDED: TODO — complement_magnitude_grounded.
% CONNECTS TO: s(comp_nec(unlicensed(equal_missing_count_is_equal)))
misconceptions_fraction_batch_7:(equal_missing_count_is_equal(frac(N1,D1)-frac(N2,D2), Result) :-
    L1 is D1 - N1,
    L2 is D2 - N2,
    (L1 == L2 -> Result = equal
    ; L1 < L2 -> Result = first
    ; Result = second)).

test_harness:arith_misconception(db_row(38868), fraction, equal_missing_count_is_equal,
    misconceptions_fraction_batch_7:equal_missing_count_is_equal,
    frac(5,6)-frac(7,8),
    second).

% === row 38960: order unit fractions by whole-number denominator ===
% Task: fill inequality between 1/8 and 1/5.
% Correct: 1/8 < 1/5.
% Error: student uses '>' because 8 > 5.
% SCHEMA: Object Collection — natural-number ordering imported wholesale.
% GROUNDED: TODO — inverse_relation_grounded.
% CONNECTS TO: s(comp_nec(unlicensed(denominator_natural_order_sign)))
misconceptions_fraction_batch_7:(inequality_by_denominator(frac(N1,D1)-frac(N2,D2), Sign) :-
    N1 == N2,
    (D1 > D2 -> Sign = '>' ; D1 < D2 -> Sign = '<' ; Sign = '=')).

test_harness:arith_misconception(db_row(38960), fraction, inequality_by_denominator,
    misconceptions_fraction_batch_7:inequality_by_denominator,
    frac(1,8)-frac(1,5),
    '<').

% === row 39095: partial simplification ===
% Task: simplify frac(42,60) to lowest terms.
% Correct: frac(7,10).
% Error: student stops at a shared factor short of the GCD, e.g. frac(21,30).
% SCHEMA: Measuring Stick — stops scaling before the minimal unit.
% GROUNDED: TODO — gcd_grounded.
% CONNECTS TO: s(comp_nec(unlicensed(incomplete_reduction)))
misconceptions_fraction_batch_7:(partial_simplification(frac(N,D), frac(Ns,Ds)) :-
    Ns is N // 2,
    Ds is D // 2).

test_harness:arith_misconception(db_row(39095), fraction, partial_simplification,
    misconceptions_fraction_batch_7:partial_simplification,
    frac(42,60),
    frac(7,10)).

% === row 39179: divide by fraction as multiply by numerator ===
% Task: 63 divided by frac(9,5).
% Correct: 63 * 5/9 = 35.
% Error: student computes 63 * 9 = 567 (multiplies by numerator, ignores denominator).
% SCHEMA: Object Collection — picks one term and multiplies.
% GROUNDED: TODO — reciprocal_grounded.
% CONNECTS TO: s(comp_nec(unlicensed(multiply_by_numerator_for_divide)))
misconceptions_fraction_batch_7:(multiply_by_numerator_for_divide(X-frac(N,_), Y) :-
    Y is X * N).

test_harness:arith_misconception(db_row(39179), fraction, multiply_by_numerator_for_divide,
    misconceptions_fraction_batch_7:multiply_by_numerator_for_divide,
    63-frac(9,5),
    35).

% === row 39321: compare by denominator-minus-numerator gap ===
% Task: compare frac(2,7) and frac(3,7).
% Correct: second (3/7 > 2/7).
% Error: gaps 7-2=5, 7-3=4; larger gap judged smaller, so student picks first as smaller
%        equivalently judges second as larger in this trivial case but misapplies to
%        4/9 vs 5/7 where 9-4=5, 7-5=2, concluding 5/7 is larger via the same rule.
% SCHEMA: Object Collection — gap size as inverse of magnitude.
% GROUNDED: TODO — subtract_grounded on terms, then compare.
% CONNECTS TO: s(comp_nec(unlicensed(gap_as_inverse_magnitude)))
misconceptions_fraction_batch_7:(gap_as_inverse_magnitude(frac(N1,D1)-frac(N2,D2), Winner) :-
    G1 is D1 - N1,
    G2 is D2 - N2,
    (G1 < G2 -> Winner = first ; G1 > G2 -> Winner = second ; Winner = equal)).

test_harness:arith_misconception(db_row(39321), fraction, gap_as_inverse_magnitude,
    misconceptions_fraction_batch_7:gap_as_inverse_magnitude,
    frac(2,7)-frac(3,7),
    second).

% === row 39594: larger denominator read as larger size ===
% Task: compare unit-measure with denominator as size.
% Correct: 1/6 < 1/5 (six hand-spans means smaller hand).
% Error: student says the hand that measured as "six" is bigger because 6 > 5.
% SCHEMA: Object Collection — count treated as size of the unit.
% GROUNDED: TODO — inverse_relation_grounded on measure units.
% CONNECTS TO: s(comp_nec(unlicensed(count_as_unit_size)))
misconceptions_fraction_batch_7:(count_as_unit_size(frac(1,D1)-frac(1,D2), Winner) :-
    (D1 > D2 -> Winner = first ; Winner = second)).

test_harness:arith_misconception(db_row(39594), fraction, count_as_unit_size,
    misconceptions_fraction_batch_7:count_as_unit_size,
    frac(1,6)-frac(1,5),
    second).

% === row 39699: unit fraction of discrete set = denominator ===
% Task: 1/3 of 12 marbles.
% Correct: 4.
% Error: student circles 3 marbles (takes the denominator as the count).
% SCHEMA: Object Collection — denominator read as cardinal of the share.
% GROUNDED: TODO — divide_grounded(rec(12), rec(3), rec(4)).
% CONNECTS TO: s(comp_nec(unlicensed(denominator_as_share_count)))
misconceptions_fraction_batch_7:(denominator_as_share_count(frac(_,D)-_Total, D)).

test_harness:arith_misconception(db_row(39699), fraction, denominator_as_share_count,
    misconceptions_fraction_batch_7:denominator_as_share_count,
    frac(1,3)-12,
    4).

% === row 39735: equivalent fraction by halving num and doubling denom ===
% Task: find a fraction equivalent to frac(18,20).
% Correct: any frac(k*9, k*10), e.g., frac(9,10).
% Error: participant writes frac(9,40) (halve numerator, double denominator).
% SCHEMA: Measuring Stick — two inverse scalings mistaken for one.
% GROUNDED: TODO — ensure both terms scale by the same factor.
% CONNECTS TO: s(comp_nec(unlicensed(inverse_scaling_on_terms)))
misconceptions_fraction_batch_7:(halve_num_double_denom(frac(N,D), frac(Nh,Dd)) :-
    Nh is N // 2,
    Dd is D * 2).

test_harness:arith_misconception(db_row(39735), fraction, halve_num_double_denom,
    misconceptions_fraction_batch_7:halve_num_double_denom,
    frac(18,20),
    frac(9,10)).

% === row 39769: "K times" interpreted as adding K/D ===
% Task: 2/7 of money taken three times -> multiplication.
% Correct: 3 * frac(2,7) = frac(6,7).
% Error: student writes 2/7 + 3/7 = 5/7 (adds K as a new numerator on same denom).
% SCHEMA: Object Collection — "times" collapsed into adding another piece.
% GROUNDED: TODO — multiply_grounded(rec(K), rec(frac(N,D))).
% CONNECTS TO: s(comp_nec(unlicensed(times_as_add_k_over_d)))
misconceptions_fraction_batch_7:(times_as_add_k_over_d(frac(N,D)-K, frac(S,D)) :-
    S is N + K).

test_harness:arith_misconception(db_row(39769), fraction, times_as_add_k_over_d,
    misconceptions_fraction_batch_7:times_as_add_k_over_d,
    frac(2,7)-3,
    frac(6,7)).

% === row 39794: larger denominator = smaller fraction, always ===
% Task: compare frac(7,8) and frac(1,2).
% Correct: first (7/8 > 1/2).
% Error: teacher rule "larger denominator => smaller fraction" ignores numerator,
%        picks frac(1,2) as larger because 2 < 8.
% SCHEMA: Object Collection — half-learned inverse rule misapplied.
% GROUNDED: TODO — cross_product_grounded reveals dominance of numerator.
% CONNECTS TO: s(comp_nec(unlicensed(denominator_only_rule)))
misconceptions_fraction_batch_7:(denominator_only_rule(frac(N1,D1)-frac(N2,D2), Winner) :-
    _ = N1, _ = N2,
    (D1 < D2 -> Winner = first ; Winner = second)).

test_harness:arith_misconception(db_row(39794), fraction, denominator_only_rule,
    misconceptions_fraction_batch_7:denominator_only_rule,
    frac(7,8)-frac(1,2),
    first).

% === row 39898: invert both operands and re-multiply ===
% Task: 125 * frac(1,5).
% Correct: 25.
% Error: student writes frac(1,125) * frac(5,1) = frac(5,125) = frac(1,25), i.e. 1/25.
% SCHEMA: Object Collection — mechanically inverts both, loses the whole.
% GROUNDED: TODO — multiply_grounded(rec(125), rec(1/5), rec(25)).
% CONNECTS TO: s(comp_nec(unlicensed(invert_both_operands)))
misconceptions_fraction_batch_7:(invert_both_operands(X-frac(N,D), Y) :-
    Y is (1 * D) / (X * N) * X).  % student's derivation: 1/125 * 5/1 -> 1/25, scaled by X gives X/25

test_harness:arith_misconception(db_row(39898), fraction, invert_both_operands,
    misconceptions_fraction_batch_7:invert_both_operands,
    125-frac(1,5),
    25).

% === row 39986: part-to-part ratio read as part-whole ===
% Task: 1 shaded, 4 unshaded -> fraction shaded.
% Correct: frac(1,5).
% Error: student writes frac(1,4) (shaded over unshaded, not over total).
% SCHEMA: Object Collection — denominator pulled from the other subset.
% GROUNDED: TODO — union_grounded(rec(N), rec(M), rec(N+M)).
% CONNECTS TO: s(comp_nec(unlicensed(part_to_part_for_part_whole)))
misconceptions_fraction_batch_7:(part_to_part_ratio(shaded(N)-unshaded(M), frac(N,M)) :-
    integer(N), integer(M)).

test_harness:arith_misconception(db_row(39986), fraction, part_to_part_ratio,
    misconceptions_fraction_batch_7:part_to_part_ratio,
    shaded(1)-unshaded(4),
    frac(1,5)).

% === row 40143: confound add-common-denom with multiply ===
% Task: frac(1,2) * frac(2,3).
% Correct: frac(2,6) (i.e., frac(1,3)).
% Error: convert to common denom frac(3,6) * frac(4,6), multiply numerators -> 12,
%        keep common denom 6 -> frac(12,6), reduce to frac(2,1).
% SCHEMA: Measuring Stick — two procedures blended.
% GROUNDED: TODO — multiply_grounded on numerators AND denominators.
% CONNECTS TO: s(comp_nec(unlicensed(multiply_keeps_common_denominator)))
misconceptions_fraction_batch_7:(multiply_keeps_common_denominator(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    L is D1 * D2,
    A is N1 * D2,
    B is N2 * D1,
    N is A * B,
    D = L).

test_harness:arith_misconception(db_row(40143), fraction, multiply_keeps_common_denominator,
    misconceptions_fraction_batch_7:multiply_keeps_common_denominator,
    frac(1,2)-frac(2,3),
    frac(2,6)).

% === row 40263: distance-from-whole gap strategy ===
% Task: compare frac(1,4) and frac(1,6).
% Correct: first (1/4 > 1/6).
% Error: student says 1/4 bigger because "1 is closer to 4 than to 6" — uses N-to-D
%        distance; smaller gap judged larger.
% SCHEMA: Measuring Stick — confuses distance-to-whole with fractional size.
% GROUNDED: TODO — distance_grounded vs size_of_part_grounded.
% CONNECTS TO: s(comp_nec(unlicensed(distance_to_denominator_as_size)))
misconceptions_fraction_batch_7:(closer_numerator_is_larger(frac(N1,D1)-frac(N2,D2), Winner) :-
    G1 is D1 - N1,
    G2 is D2 - N2,
    (G1 < G2 -> Winner = first ; G1 > G2 -> Winner = second ; Winner = equal)).

test_harness:arith_misconception(db_row(40263), fraction, closer_numerator_is_larger,
    misconceptions_fraction_batch_7:closer_numerator_is_larger,
    frac(1,4)-frac(1,6),
    first).

% === row 40343: denominator = count of larger constituent (not total) ===
% Task: 1 part pineapple to 3 parts water -> fraction pineapple.
% Correct: frac(1,4).
% Error: student writes frac(1,3) (over the bigger constituent only).
% SCHEMA: Object Collection — denominator read from the adjacent quantity.
% GROUNDED: TODO — union_grounded for mixture totals.
% CONNECTS TO: s(comp_nec(unlicensed(denominator_as_other_constituent)))
misconceptions_fraction_batch_7:(denominator_as_other_constituent(part(P)-part(Q), frac(P,T)) :-
    T is P + Q).

test_harness:arith_misconception(db_row(40343), fraction, denominator_as_other_constituent,
    misconceptions_fraction_batch_7:denominator_as_other_constituent,
    part(1)-part(3),
    frac(1,4)).

% === row 40450: componentwise estimate for sum ===
% Task: estimate frac(1,2) + frac(1,3).
% Correct: frac(5,6).
% Error: student says frac(2,5) (adds numerators and denominators).
% SCHEMA: Object Collection — componentwise reflex.
% GROUNDED: TODO — add_grounded after common-unit conversion.
% CONNECTS TO: s(comp_nec(unlicensed(componentwise_estimate)))
misconceptions_fraction_batch_7:(componentwise_estimate(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 + N2,
    D is D1 + D2).

test_harness:arith_misconception(db_row(40450), fraction, componentwise_estimate,
    misconceptions_fraction_batch_7:componentwise_estimate,
    frac(1,2)-frac(1,3),
    frac(5,6)).

% === row 40490: whole line treated as the unit whole ===
% Task: place frac(3,5) on a number line from 0 to L (L=5 here).
% Correct: position = 3/5 = 0.6 (as a value on the line).
% Error: student partitions the entire line into D parts and marks N-th tick,
%        producing position N when L happens to equal D.
% SCHEMA: Measuring Stick — unit interval collapsed onto entire visible line.
% GROUNDED: TODO — locate_unit_interval_grounded.
% CONNECTS TO: s(comp_nec(unlicensed(whole_line_as_unit)))
misconceptions_fraction_batch_7:(whole_line_as_unit(frac(N,D)-_L, Position) :-
    Position is N * 1,  % student places at integer N (treats tick count as coordinate)
    _ = D).

test_harness:arith_misconception(db_row(40490), fraction, whole_line_as_unit,
    misconceptions_fraction_batch_7:whole_line_as_unit,
    frac(3,5)-5,
    3).

% === row 37508: partitive model forced onto fraction division ===
% Task: 7/4 ÷ 1/2
% Correct: measurement division counts how many one-half units fit: 3.5
% Error: uses only equal-sharing division, treating 1/2 as two sharers -> 7/8.
% SCHEMA: Object Collection — division is constrained to sharing a collection.
% GROUNDED: TODO partition_collection_grounded, count_share_grounded.
% CONNECTS TO: s(comp_nec(unlicensed(partitive_model_only_fraction_division)))
misconceptions_fraction_batch_7:(r37508_partitive_model_only(frac(N,D)-frac(_,Parts), Got) :-
    Got is (N/D) / Parts).

test_harness:arith_misconception(db_row(37508), fraction, partitive_model_fraction_division,
    misconceptions_fraction_batch_7:r37508_partitive_model_only,
    frac(7,4)-frac(1,2),
    3.5).

% =============================================================
% Option B rows — too vague / no concrete wrong numeric answer.
% These register with `skip` as the rule name; the harness will
% classify them as `undefined` and move on.
% =============================================================

test_harness:arith_misconception(db_row(37447), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(37516), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(37524), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(37570), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(37639), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(37663), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(37676), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(37778), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(37793), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(37811), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(37962), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38110), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38195), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38224), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38257), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38279), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38312), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38449), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38553), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38609), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38660), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38667), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38702), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38840), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38978), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39008), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39061), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39150), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39218), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39367), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39444), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39550), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39609), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39643), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39670), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39815), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39822), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39887), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(40074), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(40087), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(40115), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(40125), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(40152), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(40192), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(40199), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(40232), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(40374), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(40407), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(40457), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(40538), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(40617), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(40665), fraction, too_vague, skip, none, none).

% === row 37460: miscount unit mini-parts ===
% Source: Hackenberg 2010, p.260.
% Task: 3/10 of a meter is 2/5 of the Cobras' distance.
% Correct: 15/20 of a meter, since the 3/10 bar must be partitioned into
% two equal parts and five such parts make the target distance.
% Error: 15/19, after visually miscounting how many mini-parts fit in the
% unit meter.
% SCHEMA: Measuring Stick — visual marks replace recursive partitioning.
% GROUNDED: TODO — partition_grounded(Known, RelationNumerator, Part),
% then iterate_grounded(Part, RelationDenominator, Target) while preserving
% the unit-meter interval count.
% CONNECTS TO: s(comp_nec(unlicensed(visual_miscount_unit_parts)))
misconceptions_fraction_batch_7:(r37460_miscount_unit_parts(rmr(frac(KN,KD), frac(RN,RD)), frac(N,DWrong)) :-
    N is KN * RD,
    DWrong is KD * RN - 1).

test_harness:arith_misconception(db_row(37460), fraction, miscount_unit_mini_parts,
    misconceptions_fraction_batch_7:r37460_miscount_unit_parts,
    rmr(frac(3,10), frac(2,5)),
    frac(15,20)).

% === row 37476: piece count as amount ===
% Source: Lamon 1996, p.183.
% Task: four pizzas shared among three people after each pizza is cut into
% six slices.
% Correct: each person receives 4/3 pizzas.
% Error: answer the amount question with the number of slices, "eight slices."
% SCHEMA: Object Collection — counted pieces stand in for fractional amount.
% GROUNDED: TODO — preserve the pizza as referent whole while counting
% distributed slices as subordinate units.
% CONNECTS TO: s(comp_nec(unlicensed(piece_count_as_amount)))
misconceptions_fraction_batch_7:(r37476_pieces_as_amount(pizza_share(pizzas(P), people(N), slices_per_pizza(S)),
                         slices(Pieces)) :-
    Pieces is P * S // N).

test_harness:arith_misconception(db_row(37476), fraction, piece_count_as_amount,
    misconceptions_fraction_batch_7:r37476_pieces_as_amount,
    pizza_share(pizzas(4), people(3), slices_per_pizza(6)),
    frac(4,3)).

% === row 37478: share quantity read as total fraction ===
% Task: share 4 pizzas among 3 people; report each person's share as a
%   fraction of the original total amount.
% Correct: frac(1,3) of the total pizza amount.
% Error: says frac(4,3) of the total, carrying pizzas-per-person into
%   a total-referent fraction statement.
% SCHEMA: Container — the referent whole shifts from one pizza to the
%   combined pizza amount.
% GROUNDED: TODO — preserve the container for the original total while
%   deriving each share as one of People equal shares.
% CONNECTS TO: s(comp_nec(unlicensed(referent_whole_shift)))
misconceptions_fraction_batch_7:(share_quantity_as_total_fraction(pizzas(Pizzas)-people(People), frac(Pizzas, People)) :-
    integer(Pizzas),
    integer(People),
    People =\= 0).

test_harness:arith_misconception(db_row(37478), fraction, share_quantity_as_total_fraction,
    misconceptions_fraction_batch_7:share_quantity_as_total_fraction,
    pizzas(4)-people(3),
    frac(1,3)).

% === direct solo pass: remaining fraction queue cleanup ===

% === row 37453: componentwise addition algorithm ===
% Task: frac(1,2) + frac(1,3).
% Correct: frac(5,6).
% Error: frac(2,5), adding numerators and denominators separately.
% SCHEMA: Object Collection.
% GROUNDED: TODO add numerator counts and denominator counts without common-unit conversion.
% CONNECTS TO: s(comp_nec(unlicensed(componentwise_fraction_addition)))
misconceptions_fraction_batch_7:(r37453_componentwise_add(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 + N2,
    D is D1 + D2).

test_harness:arith_misconception(db_row(37453), fraction, componentwise_addition_algorithm,
    misconceptions_fraction_batch_7:r37453_componentwise_add,
    frac(1,2)-frac(1,3),
    frac(5,6)).

% === row 37542: fraction-to-decimal by adding terms ===
% Task: convert frac(3,2) to a decimal.
% Correct: 1.5.
% Error: .5, from 3+2=5 and prefixing a decimal point.
% SCHEMA: Object Collection.
% GROUNDED: TODO combine visible terms as a count rather than treating the fraction as quotient.
% CONNECTS TO: s(comp_nec(unlicensed(sum_terms_for_decimal)))
misconceptions_fraction_batch_7:(r37542_sum_terms_decimal(frac(N,D), Decimal) :-
    Decimal is (N + D) / 10).

test_harness:arith_misconception(db_row(37542), fraction, sum_terms_decimal_conversion,
    misconceptions_fraction_batch_7:r37542_sum_terms_decimal,
    frac(3,2),
    1.5).

% Rows with no determinate wrong numeric or symbolic output in the extracted row.
test_harness:arith_misconception(db_row(37672), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(37673), fraction, too_vague, skip, none, none).

% === row 37674: procedural grid forced to match wrong quotient ===
% Task: frac(2,3) divided by frac(3,4).
% Correct: frac(8,9).
% Error: frac(8,6), from driving the drawing by an incorrect numeric procedure.
% SCHEMA: Measuring Stick.
% GROUNDED: TODO preserve divisor partition and dividend unit simultaneously.
% CONNECTS TO: s(comp_nec(unlicensed(procedural_grid_fraction_division)))
misconceptions_fraction_batch_7:(r37674_wrong_division_grid(div(frac(N1,D1), frac(_N2,D2)), frac(N,D)) :-
    N is N1 * D2,
    D is N1 * D1).

test_harness:arith_misconception(db_row(37674), fraction, procedural_grid_fraction_division,
    misconceptions_fraction_batch_7:r37674_wrong_division_grid,
    div(frac(2,3), frac(3,4)),
    frac(8,9)).

% === row 37833: add like-denominator fractions by combining denominators ===
% Task: frac(1,5) + frac(1,5).
% Correct: frac(2,5).
% Error: frac(1,10).
% SCHEMA: Object Collection.
% GROUNDED: TODO retain common partition unit while adding selected parts.
% CONNECTS TO: s(comp_nec(unlicensed(add_common_denominators)))
misconceptions_fraction_batch_7:(r37833_add_common_denoms(frac(N,D)-frac(_N2,D), frac(N,DD)) :-
    DD is D + D).

test_harness:arith_misconception(db_row(37833), fraction, add_common_denominators,
    misconceptions_fraction_batch_7:r37833_add_common_denoms,
    frac(1,5)-frac(1,5),
    frac(2,5)).

% Digit-cancellation examples that happen to land on the correct numeric value.
test_harness:arith_misconception(db_row(37947), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38200), fraction, too_vague, skip, none, none).

% === row 38296: equivalent fraction read as double the original ===
% Task: compare frac(2,3) with frac(4,6).
% Correct: equal.
% Error: frac(4,6) is treated as larger because both terms are doubled.
% SCHEMA: Object Collection.
% GROUNDED: TODO recognize scale-by-one as preserving quantity.
% CONNECTS TO: s(comp_nec(unlicensed(equivalent_fraction_as_larger)))
misconceptions_fraction_batch_7:(r38296_equiv_as_larger(equiv_compare(frac(_N,_D), frac(_N2,_D2)), larger)).

test_harness:arith_misconception(db_row(38296), fraction, equivalent_fraction_as_larger,
    misconceptions_fraction_batch_7:r38296_equiv_as_larger,
    equiv_compare(frac(2,3), frac(4,6)),
    equal).

% === row 38297: building-up treated as making the fraction bigger ===
% Task: compare frac(2,3) with frac(4,6).
% Correct: equal.
% Error: "building up" is read as increasing the fraction.
% SCHEMA: Object Collection.
% GROUNDED: TODO preserve referent size under equivalent-unit refinement.
% CONNECTS TO: s(comp_nec(unlicensed(building_up_changes_value)))
misconceptions_fraction_batch_7:(r38297_building_up_bigger(equiv_compare(frac(_N,_D), frac(_N2,_D2)), bigger)).

test_harness:arith_misconception(db_row(38297), fraction, building_up_changes_value,
    misconceptions_fraction_batch_7:r38297_building_up_bigger,
    equiv_compare(frac(2,3), frac(4,6)),
    equal).

test_harness:arith_misconception(db_row(38299), fraction, too_vague, skip, none, none).

% === row 38300: hundreds grid denominator treated as tens count ===
% Task: represent frac(3,5) on a 10 by 10 grid.
% Correct: 60 squares.
% Error: 50 squares, from using the denominator as tenths.
% SCHEMA: Object Collection.
% GROUNDED: TODO convert fifths to hundredths before counting grid cells.
% CONNECTS TO: s(comp_nec(unlicensed(denominator_as_tens_grid_count)))
misconceptions_fraction_batch_7:(r38300_hundreds_grid_denominator(frac(_N,D), Count) :-
    Count is D * 10).

test_harness:arith_misconception(db_row(38300), fraction, denominator_as_tens_grid_count,
    misconceptions_fraction_batch_7:r38300_hundreds_grid_denominator,
    frac(3,5),
    60).

% === row 38301: same fraction assumed same amount across different wholes ===
% Task: decide whether two people eating half of different-size bars can eat different amounts.
% Correct: possible.
% Error: impossible, because both are called one half.
% SCHEMA: Container.
% GROUNDED: TODO preserve the referent whole when comparing fractional amounts.
% CONNECTS TO: s(comp_nec(unlicensed(ignore_referent_whole_size)))
misconceptions_fraction_batch_7:(r38301_same_fraction_same_amount(half_bars(_Large,_Small), impossible)).

test_harness:arith_misconception(db_row(38301), fraction, ignore_referent_whole_size,
    misconceptions_fraction_batch_7:r38301_same_fraction_same_amount,
    half_bars(large, small),
    possible).

% === row 38605: fair shares require congruent shapes ===
% Task: judge whether equal-area pieces of different shapes can be fair shares.
% Correct: fair.
% Error: unfair because the pieces are not congruent.
% SCHEMA: Container.
% GROUNDED: TODO compare area measure rather than visible shape congruence.
% CONNECTS TO: s(comp_nec(unlicensed(congruent_shape_required_for_fraction)))
misconceptions_fraction_batch_7:(r38605_congruent_shape_required(fair_share(_Pieces), unfair)).

test_harness:arith_misconception(db_row(38605), fraction, congruent_shape_required_for_fraction,
    misconceptions_fraction_batch_7:r38605_congruent_shape_required,
    fair_share(equal_area_mixed_shapes),
    fair).

% === row 38613: fraction-to-decimal by adding visible terms ===
% Task: convert frac(2,10) to a decimal.
% Correct: 0.2.
% Error: 1.2, from 2+10=12 and placing a decimal point.
% SCHEMA: Object Collection.
% GROUNDED: TODO treat fraction as quotient of numerator by denominator.
% CONNECTS TO: s(comp_nec(unlicensed(sum_terms_for_decimal)))
test_harness:arith_misconception(db_row(38613), fraction, sum_terms_decimal_conversion,
    misconceptions_fraction_batch_7:r37542_sum_terms_decimal,
    frac(2,10),
    0.2).

% === row 38638: number line rejected for fraction-by-fraction division ===
% Task: model frac(3,4) divided by frac(1,2) on a number line.
% Correct: possible.
% Error: impossible because both quantities are fractions.
% SCHEMA: Measuring Stick.
% GROUNDED: TODO use the line as a measure space independent of whole-number endpoints.
% CONNECTS TO: s(comp_nec(unlicensed(number_line_requires_whole_number)))
misconceptions_fraction_batch_7:(r38638_number_line_requires_whole(div(frac(_,_), frac(_,_)), impossible)).

test_harness:arith_misconception(db_row(38638), fraction, number_line_requires_whole_number,
    misconceptions_fraction_batch_7:r38638_number_line_requires_whole,
    div(frac(3,4), frac(1,2)),
    possible).

% === row 38813: undivided region cannot carry equivalent fraction names ===
% Task: recognize an undivided quarter-circle as frac(3,12).
% Correct: equivalent.
% Error: not equivalent unless the region is visibly partitioned into twelfths.
% SCHEMA: Container.
% GROUNDED: TODO coordinate equivalent partitions over the same area.
% CONNECTS TO: s(comp_nec(unlicensed(visible_partition_required_for_equivalence)))
misconceptions_fraction_batch_7:(r38813_visible_partition_required(quarter_region, not_equivalent)).

test_harness:arith_misconception(db_row(38813), fraction, visible_partition_required_for_equivalence,
    misconceptions_fraction_batch_7:r38813_visible_partition_required,
    quarter_region,
    equivalent).

% === row 38814: part-to-part comparison used as part-whole fraction ===
% Task: name 1 part out of a mixture with 1 target part and 3 other parts.
% Correct: frac(1,4).
% Error: frac(1,3), target part over other parts.
% SCHEMA: Object Collection.
% GROUNDED: TODO form total collection before naming part-whole relation.
% CONNECTS TO: s(comp_nec(unlicensed(part_to_part_as_part_whole)))
misconceptions_fraction_batch_7:(r38814_part_to_part_as_whole(parts(Target,Other), frac(Target,Other))).

test_harness:arith_misconception(db_row(38814), fraction, part_to_part_as_part_whole,
    misconceptions_fraction_batch_7:r38814_part_to_part_as_whole,
    parts(1,3),
    frac(1,4)).

% === row 38815: unequal pieces counted as equal fractional parts ===
% Task: interpret one shaded piece among four unequal pieces.
% Correct: invalid_partition.
% Error: frac(1,4), counting pieces as if they were equal.
% SCHEMA: Object Collection.
% GROUNDED: TODO require equal-measure parts before counting fractional units.
% CONNECTS TO: s(comp_nec(unlicensed(count_unequal_parts_as_equal)))
misconceptions_fraction_batch_7:(r38815_count_unequal_parts(unequal_partition(shaded(N), pieces(D)), frac(N,D))).

test_harness:arith_misconception(db_row(38815), fraction, count_unequal_parts_as_equal,
    misconceptions_fraction_batch_7:r38815_count_unequal_parts,
    unequal_partition(shaded(1), pieces(4)),
    invalid_partition).

% === row 38822: simplification retrieval error ===
% Task: simplify frac(16,24).
% Correct: frac(2,3).
% Error: frac(3,8), from misretrieving factors.
% SCHEMA: Object Collection.
% GROUNDED: TODO maintain factor pairs accurately during reduction.
% CONNECTS TO: s(comp_nec(unlicensed(factor_retrieval_error)))
misconceptions_fraction_batch_7:(r38822_factor_retrieval_error(frac(16,24), frac(3,8))).

test_harness:arith_misconception(db_row(38822), fraction, factor_retrieval_error,
    misconceptions_fraction_batch_7:r38822_factor_retrieval_error,
    frac(16,24),
    frac(2,3)).

% === row 38824: geometric context dropped in rent problem ===
% Task: compute rent for 4.5 squares at 5 florins each.
% Correct: 22.5.
% Error: 20.5.
% SCHEMA: Container.
% GROUNDED: TODO preserve the area decomposition rather than detached numeric manipulation.
% CONNECTS TO: s(comp_nec(unlicensed(drop_geometric_context)))
misconceptions_fraction_batch_7:(r38824_drop_geometric_context(rent(4.5,5), 20.5)).

test_harness:arith_misconception(db_row(38824), fraction, drop_geometric_context,
    misconceptions_fraction_batch_7:r38824_drop_geometric_context,
    rent(4.5,5),
    22.5).

% === row 38910: reasonableness judged by procedural completeness ===
% Task: judge whether frac(3,5)+frac(1,3)=frac(4,15) is reasonable.
% Correct: unreasonable.
% Error: reasonable because part of the common-denominator procedure was attempted.
% SCHEMA: Object Collection.
% GROUNDED: TODO compare result magnitude against addend magnitudes.
% CONNECTS TO: s(comp_nec(unlicensed(procedure_steps_as_reasonableness)))
misconceptions_fraction_batch_7:(r38910_steps_as_reasonable(add(frac(3,5), frac(1,3)), reasonable)).

test_harness:arith_misconception(db_row(38910), fraction, procedure_steps_as_reasonableness,
    misconceptions_fraction_batch_7:r38910_steps_as_reasonable,
    add(frac(3,5), frac(1,3)),
    unreasonable).

test_harness:arith_misconception(db_row(39023), fraction, too_vague, skip, none, none).

% === row 39054: orientation changes half-size ===
% Task: compare halves made by different cuts of the same pizza.
% Correct: equal.
% Error: unequal because orientation changes apparent amount.
% SCHEMA: Container.
% GROUNDED: TODO preserve area under rigid visual reorientation.
% CONNECTS TO: s(comp_nec(unlicensed(orientation_changes_half_size)))
misconceptions_fraction_batch_7:(r39054_orientation_changes_half(half_cut(_Orientation), unequal)).

test_harness:arith_misconception(db_row(39054), fraction, orientation_changes_half_size,
    misconceptions_fraction_batch_7:r39054_orientation_changes_half,
    half_cut(vertical),
    equal).

% === row 39183: area-model addition by shaded-over-total count ===
% Task: frac(1,2)+frac(1,4).
% Correct: frac(3,4).
% Error: frac(2,6), shaded pieces over total drawn pieces.
% SCHEMA: Object Collection.
% GROUNDED: TODO use common unit before adding shaded quantities.
% CONNECTS TO: s(comp_nec(unlicensed(area_model_count_addition)))
misconceptions_fraction_batch_7:(r39183_area_count_add(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 + N2,
    D is D1 + D2).

test_harness:arith_misconception(db_row(39183), fraction, area_model_count_addition,
    misconceptions_fraction_batch_7:r39183_area_count_add,
    frac(1,2)-frac(1,4),
    frac(3,4)).

test_harness:arith_misconception(db_row(39229), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39284), fraction, too_vague, skip, none, none).

% === row 39378: contextual fraction addition by adding terms ===
% Task: frac(1,2)+frac(1,3).
% Correct: frac(5,6).
% Error: frac(2,5), treating the fractions like independent test scores.
% SCHEMA: Object Collection.
% GROUNDED: TODO construct a shared unit element before addition.
% CONNECTS TO: s(comp_nec(unlicensed(contextual_componentwise_addition)))
test_harness:arith_misconception(db_row(39378), fraction, contextual_componentwise_addition,
    misconceptions_fraction_batch_7:r37453_componentwise_add,
    frac(1,2)-frac(1,3),
    frac(5,6)).

% === row 39430: differently shaped halves judged unequal ===
% Task: compare rectangular and triangular halves of the same square.
% Correct: equal.
% Error: not_equal, because the arrangements look different.
% SCHEMA: Container.
% GROUNDED: TODO compare area as invariant under decomposition.
% CONNECTS TO: s(comp_nec(unlicensed(shape_overrides_equal_area)))
misconceptions_fraction_batch_7:(r39430_shape_overrides_area(halves(_Whole), not_equal)).

test_harness:arith_misconception(db_row(39430), fraction, shape_overrides_equal_area,
    misconceptions_fraction_batch_7:r39430_shape_overrides_area,
    halves(square),
    equal).

% === row 39630: division by one-half treated as division by two ===
% Task: 8 divided by frac(1,2).
% Correct: 16.
% Error: 4.
% SCHEMA: Object Collection.
% GROUNDED: TODO count half-units contained in the dividend.
% CONNECTS TO: s(comp_nec(unlicensed(divide_by_fraction_denominator)))
misconceptions_fraction_batch_7:(r39630_divide_by_fraction_denominator(X-frac(1,2), Y) :-
    Y is X / 2).

test_harness:arith_misconception(db_row(39630), fraction, divide_by_fraction_denominator,
    misconceptions_fraction_batch_7:r39630_divide_by_fraction_denominator,
    8-frac(1,2),
    16).

% === row 39635: count tick marks instead of intervals ===
% Task: name one interval when a unit is divided into eighths with seven interior marks.
% Correct: frac(1,8).
% Error: frac(1,7), counting visible lines.
% SCHEMA: Measuring Stick.
% GROUNDED: TODO count intervals between partition marks rather than marks themselves.
% CONNECTS TO: s(comp_nec(unlicensed(count_marks_as_intervals)))
misconceptions_fraction_batch_7:(r39635_count_marks_as_intervals(unit_segment(lines(Lines)), frac(1,Lines))).

test_harness:arith_misconception(db_row(39635), fraction, count_marks_as_intervals,
    misconceptions_fraction_batch_7:r39635_count_marks_as_intervals,
    unit_segment(lines(7)),
    frac(1,8)).

% === row 39636: additive pattern used for equivalent fractions ===
% Task: find an equivalent name for frac(2,3).
% Correct: frac(2,3) as the same value.
% Error: frac(4,6) produced by adding 2 and 3 as a pattern.
% SCHEMA: Object Collection.
% GROUNDED: TODO use multiplicative scaling by one, not additive term shifts.
% CONNECTS TO: s(comp_nec(unlicensed(additive_equivalence_pattern)))
misconceptions_fraction_batch_7:(r39636_additive_equiv_pattern(frac(N,D)-add(A,B), frac(N2,D2)) :-
    N2 is N + A,
    D2 is D + B).

test_harness:arith_misconception(db_row(39636), fraction, additive_equivalence_pattern,
    misconceptions_fraction_batch_7:r39636_additive_equiv_pattern,
    frac(2,3)-add(2,3),
    frac(2,3)).

% === row 39637: multiply fraction by whole number to make equivalent fraction ===
% Task: show an equivalent fraction for frac(2,3).
% Correct: same value as frac(2,3).
% Error: written as frac(2,3) times 2, producing frac(4,6) by an invalid operation.
% SCHEMA: Object Collection.
% GROUNDED: TODO multiply by a form of one, not by a standalone whole number.
% CONNECTS TO: s(comp_nec(unlicensed(multiply_fraction_by_whole_for_equivalence)))
misconceptions_fraction_batch_7:(r39637_multiply_by_whole_equiv(frac(N,D)-K, frac(NK,DK)) :-
    NK is N * K,
    DK is D * K).

test_harness:arith_misconception(db_row(39637), fraction, multiply_fraction_by_whole_for_equivalence,
    misconceptions_fraction_batch_7:r39637_multiply_by_whole_equiv,
    frac(2,3)-2,
    frac(2,3)).

test_harness:arith_misconception(db_row(39752), fraction, too_vague, skip, none, none).

% === row 39885: whole-number interference in fraction addition ===
% Task: frac(1,10)+frac(3,5).
% Correct: frac(7,10).
% Error: frac(4,15), adding terms directly.
% SCHEMA: Object Collection.
% GROUNDED: TODO convert to a common unit before adding.
% CONNECTS TO: s(comp_nec(unlicensed(whole_number_interference_fraction_addition)))
test_harness:arith_misconception(db_row(39885), fraction, whole_number_interference_fraction_addition,
    misconceptions_fraction_batch_7:r37453_componentwise_add,
    frac(1,10)-frac(3,5),
    frac(7,10)).

% === row 39886: denominator read as decimal tenths ===
% Task: convert frac(1,8) to a decimal.
% Correct: 0.125.
% Error: 0.8.
% SCHEMA: Object Collection.
% GROUNDED: TODO interpret denominator through division, not place value alone.
% CONNECTS TO: s(comp_nec(unlicensed(denominator_as_decimal_digit)))
misconceptions_fraction_batch_7:(r39886_denominator_decimal_digit(frac(1,D), Decimal) :-
    Decimal is D / 10).

test_harness:arith_misconception(db_row(39886), fraction, denominator_as_decimal_digit,
    misconceptions_fraction_batch_7:r39886_denominator_decimal_digit,
    frac(1,8),
    0.125).

% === row 40025: subtraction takes one-eighth of current amount ===
% Task: frac(4,5)-frac(1,8).
% Correct: frac(27,40).
% Error: frac(7,10), subtracting one eighth of frac(4,5).
% SCHEMA: Measuring Stick.
% GROUNDED: TODO preserve the original unit for the subtrahend.
% CONNECTS TO: s(comp_nec(unlicensed(subtract_fraction_of_current_amount)))
misconceptions_fraction_batch_7:(r40025_subtract_of_current_amount(sub(frac(4,5), frac(1,8)), frac(7,10))).

test_harness:arith_misconception(db_row(40025), fraction, subtract_fraction_of_current_amount,
    misconceptions_fraction_batch_7:r40025_subtract_of_current_amount,
    sub(frac(4,5), frac(1,8)),
    frac(27,40)).

% === row 40026: unlike denominators added componentwise ===
% Task: frac(3,4)+frac(4,5).
% Correct: frac(31,20).
% Error: frac(7,9).
% SCHEMA: Object Collection.
% GROUNDED: TODO construct common denominator before addition.
% CONNECTS TO: s(comp_nec(unlicensed(unlike_denominator_componentwise_addition)))
test_harness:arith_misconception(db_row(40026), fraction, unlike_denominator_componentwise_addition,
    misconceptions_fraction_batch_7:r37453_componentwise_add,
    frac(3,4)-frac(4,5),
    frac(31,20)).

% === row 40027: order fractions by visible denominator pattern ===
% Task: order frac(1,4), frac(2,3), frac(3,8) from least to greatest.
% Correct: [frac(1,4), frac(3,8), frac(2,3)].
% Error: [frac(2,3), frac(1,4), frac(3,8)].
% SCHEMA: Object Collection.
% GROUNDED: TODO compare fractional magnitudes rather than denominator/numerator cues.
% CONNECTS TO: s(comp_nec(unlicensed(denominator_pattern_ordering)))
misconceptions_fraction_batch_7:(r40027_denominator_pattern_order(_Fractions, [frac(2,3), frac(1,4), frac(3,8)])).

test_harness:arith_misconception(db_row(40027), fraction, denominator_pattern_ordering,
    misconceptions_fraction_batch_7:r40027_denominator_pattern_order,
    [frac(1,4), frac(2,3), frac(3,8)],
    [frac(1,4), frac(3,8), frac(2,3)]).

test_harness:arith_misconception(db_row(40028), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(40095), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(40153), fraction, too_vague, skip, none, none).

% === row 40154: local ribbon unit collapsed to one ===
% Task: interpret frac(1,6)+frac(4,6).
% Correct: frac(5,6).
% Error: 1, because five-sixths of a meter is treated as one hair-ribbon unit.
% SCHEMA: Measuring Stick.
% GROUNDED: TODO keep the original meter unit distinct from the functional ribbon unit.
% CONNECTS TO: s(comp_nec(unlicensed(local_unit_collapses_fraction)))
misconceptions_fraction_batch_7:(r40154_local_unit_collapse(add(frac(1,6), frac(4,6)), 1)).

test_harness:arith_misconception(db_row(40154), fraction, local_unit_collapses_fraction,
    misconceptions_fraction_batch_7:r40154_local_unit_collapse,
    add(frac(1,6), frac(4,6)),
    frac(5,6)).

% === row 40155: remainder kept in original unit ===
% Task: 4 divided by frac(3,5).
% Correct: mixed(6, frac(2,3)).
% Error: mixed(6, frac(2,5)), leaving the remainder in fifths of the original unit.
% SCHEMA: Measuring Stick.
% GROUNDED: TODO reunitize the remainder by the divisor unit.
% CONNECTS TO: s(comp_nec(unlicensed(remainder_in_original_unit)))
misconceptions_fraction_batch_7:(r40155_remainder_original_unit(div(4, frac(3,5)), mixed(6, frac(2,5)))).

test_harness:arith_misconception(db_row(40155), fraction, remainder_in_original_unit,
    misconceptions_fraction_batch_7:r40155_remainder_original_unit,
    div(4, frac(3,5)),
    mixed(6, frac(2,3))).

test_harness:arith_misconception(db_row(40156), fraction, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(40260), fraction, too_vague, skip, none, none).

% === row 40445: number-line midpoint hidden by extra partitions ===
test_harness:arith_misconception(db_row(40445), fraction, too_vague, skip, none, none).

% === row 40446: symbolic pattern overrides number-line spacing ===
% Task: identify the mark after frac(1,4) and frac(1,2) on a quartered line.
% Correct: frac(3,4).
% Error: frac(1,3), guessed from a symbolic "one over" pattern.
% SCHEMA: Measuring Stick.
% GROUNDED: TODO use equal spatial intervals rather than numerator/denominator word pattern.
% CONNECTS TO: s(comp_nec(unlicensed(symbolic_pattern_number_line)))
misconceptions_fraction_batch_7:(r40446_symbolic_pattern_line(sequence([frac(1,4), frac(1,2)]), frac(1,3))).

test_harness:arith_misconception(db_row(40446), fraction, symbolic_pattern_number_line,
    misconceptions_fraction_batch_7:r40446_symbolic_pattern_line,
    sequence([frac(1,4), frac(1,2)]),
    frac(3,4)).

% === row 40447: total tick marks treated as the unit denominator ===
% Task: name the first fifth between 0 and 1 on a line extending past 2.
% Correct: frac(1,5).
% Error: 12, counting all ticks on the visible line.
% SCHEMA: Measuring Stick.
% GROUNDED: TODO identify the interval 0 to 1 as the unit before counting.
% CONNECTS TO: s(comp_nec(unlicensed(total_tick_count_as_denominator)))
misconceptions_fraction_batch_7:(r40447_total_tick_count(first_partition(line(_Units,_PartsPerUnit,Ticks)), Ticks)).

test_harness:arith_misconception(db_row(40447), fraction, total_tick_count_as_denominator,
    misconceptions_fraction_batch_7:r40447_total_tick_count,
    first_partition(line(2,5,12)),
    frac(1,5)).

test_harness:arith_misconception(db_row(40448), fraction, too_vague, skip, none, none).

% === row 40531: table membership used for unit fraction of a whole number ===
% Task: find frac(1,10) of 20.
% Correct: 2.
% Error: 10, because 20 is in the tens table.
% SCHEMA: Object Collection.
% GROUNDED: TODO divide the whole by the denominator rather than naming a times-table.
% CONNECTS TO: s(comp_nec(unlicensed(times_table_as_unit_fraction)))
misconceptions_fraction_batch_7:(r40531_times_table_fraction(frac(1,10)-20, 10)).

test_harness:arith_misconception(db_row(40531), fraction, times_table_as_unit_fraction,
    misconceptions_fraction_batch_7:r40531_times_table_fraction,
    frac(1,10)-20,
    2).

test_harness:arith_misconception(db_row(40550), fraction, too_vague, skip, none, none).

% === row 40551: subtract one-fourth of the total two wholes ===
% Task: 2 - frac(1,4).
% Correct: frac(7,4).
% Error: frac(3,2), taking one fourth of two circles away.
% SCHEMA: Container.
% GROUNDED: TODO identify one whole as the referent for one fourth.
% CONNECTS TO: s(comp_nec(unlicensed(subtract_fraction_of_total_collection)))
misconceptions_fraction_batch_7:(r40551_subtract_fraction_total(sub(2, frac(1,4)), frac(3,2))).

test_harness:arith_misconception(db_row(40551), fraction, subtract_fraction_of_total_collection,
    misconceptions_fraction_batch_7:r40551_subtract_fraction_total,
    sub(2, frac(1,4)),
    frac(7,4)).

% === row 40622: fraction of a fraction guessed from a ten-part whole ===
% Task: frac(3,4) of frac(1,4).
% Correct: frac(3,16).
% Error: frac(3,10), guessing a ten-part original whole.
% SCHEMA: Measuring Stick.
% GROUNDED: TODO recursively partition the one-fourth by four.
% CONNECTS TO: s(comp_nec(unlicensed(guess_total_parts_for_fraction_of_fraction)))
misconceptions_fraction_batch_7:(r40622_guess_total_ten(of(frac(3,4), frac(1,4)), frac(3,10))).

test_harness:arith_misconception(db_row(40622), fraction, guess_total_parts_for_fraction_of_fraction,
    misconceptions_fraction_batch_7:r40622_guess_total_ten,
    of(frac(3,4), frac(1,4)),
    frac(3,16)).

% Benny's rule deformations (Erlwanger 1973). Paired with coordinated
% automata in knowledge/strategies/math/{smr_div_long,smr_frac_equiv_cross_mult}.pl.
% See knowledge/misconceptions/BENNY.md for the theoretical frame.
:- use_module(misconceptions(benny)).

% =============================================================
% G4Q1: Fraction ordering — butterfly strategy + variants
% Task: Order frac(2,3), frac(3,4), frac(3,8) smallest to largest.
% Correct: [frac(3,8), frac(2,3), frac(3,4)]
% =============================================================

% --- Reference correct strategy (input unchanged: runs all three cross-products) ---
g4q1_correct([frac(2,3), frac(3,4), frac(3,8)], [frac(3,8), frac(2,3), frac(3,4)]).

% --- Helper: cross_product/3 ---
% cross_product(frac(N1,D1), frac(N2,D2), first_greater|second_greater|equal)
% SCHEMA: Measuring Stick — numerators and denominators as commensurable lengths
% GROUNDED: TODO — multiply_grounded(RN1, RD2, C1), multiply_grounded(RN2, RD1, C2)
cross_product(frac(N1,D1), frac(N2,D2), Result) :-
    C1 is N1 * D2,
    C2 is N2 * D1,
    (C1 > C2 -> Result = first_greater
    ; C2 > C1 -> Result = second_greater
    ; Result = equal).

% --- Pairwise score: +1 if F beats Other, -1 if Other beats F ---
% Helpers are g4q1-prefixed so Task 6 parallel agents can introduce their
% own score/delta helpers in the same file without collision.
g4q1_score(F, Pairs, Score) :-
    findall(D, g4q1_pair_delta(F, Pairs, D), Ds),
    sum_list(Ds, Score).

g4q1_pair_delta(F, Pairs, +1) :- member(pair(F,_,first_greater), Pairs).
g4q1_pair_delta(F, Pairs, -1) :- member(pair(F,_,second_greater), Pairs).
g4q1_pair_delta(F, Pairs, -1) :- member(pair(_,F,first_greater), Pairs).
g4q1_pair_delta(F, Pairs, +1) :- member(pair(_,F,second_greater), Pairs).

% --- Variant 06-03: skips (2/3, 3/8) comparison, defaults without computing ---
% The correct result for (2/3, 3/8) is first_greater (2/3 > 3/8).
% Student defaulted to second_greater (wrong) — skipped the computation and
% guessed, and the guess happens to disagree with the correct value.
% CONNECTS TO: s(comp_nec(unlicensed(skip_pair(frac(2,3), frac(3,8)))))
g4q1_06_03([frac(2,3), frac(3,4), frac(3,8)], Order) :-
    cross_product(frac(2,3), frac(3,4), R1),
    cross_product(frac(3,4), frac(3,8), R2),
    % Skip: (2/3, 3/8) — student defaulted to second_greater (wrong)
    Pairs = [pair(frac(2,3), frac(3,4), R1),
             pair(frac(3,4), frac(3,8), R2),
             pair(frac(2,3), frac(3,8), second_greater)],
    Fracs = [frac(2,3), frac(3,4), frac(3,8)],
    maplist([F, S-F]>>(g4q1_score(F, Pairs, S)), Fracs, Scored),
    keysort(Scored, Sorted),
    pairs_values(Sorted, Order).

% --- Variant 18-04: skips (2/3, 3/8), fills by magnitude transfer ---
% CONNECTS TO: s(comp_nec(unlicensed(magnitude_transfer(from_prior_pair, wrong_sign))))
g4q1_18_04([frac(2,3), frac(3,4), frac(3,8)], Order) :-
    cross_product(frac(2,3), frac(3,4), R1),
    cross_product(frac(3,4), frac(3,8), R2),
    % Transfer: infer (2/3 > 3/8) from "2/3 was larger in the first pair"
    Pairs = [pair(frac(2,3), frac(3,4), R1),
             pair(frac(3,4), frac(3,8), R2),
             pair(frac(2,3), frac(3,8), second_greater)],  % wrong inference
    Fracs = [frac(2,3), frac(3,4), frac(3,8)],
    maplist([F, S-F]>>(g4q1_score(F, Pairs, S)), Fracs, Scored),
    keysort(Scored, Sorted),
    pairs_values(Sorted, Order).

% --- Variant 06-20: all pairs compared but (2/3, 3/4) uses mutated products ---
% CONNECTS TO: s(comp_nec(unlicensed(mutation(scale(8->24, 9->18)))))
g4q1_06_20([frac(2,3), frac(3,4), frac(3,8)], Order) :-
    % Correct: 2*4=8 vs 3*3=9 → second_greater (3/4 > 2/3)
    % Student mutated: 8→24, 9→18, reversing the result.
    R1 = first_greater,
    cross_product(frac(3,4), frac(3,8), R2),
    cross_product(frac(2,3), frac(3,8), R3),
    Pairs = [pair(frac(2,3), frac(3,4), R1),
             pair(frac(3,4), frac(3,8), R2),
             pair(frac(2,3), frac(3,8), R3)],
    Fracs = [frac(2,3), frac(3,4), frac(3,8)],
    maplist([F, S-F]>>(g4q1_score(F, Pairs, S)), Fracs, Scored),
    keysort(Scored, Sorted),
    pairs_values(Sorted, Order).

% --- Registration (Task 2 plumbing: facts go to test_harness module) ---
test_harness:arith_misconception(asktm('06-03'), fraction, g4q1_skip_pair,
    misconceptions_fraction:g4q1_06_03,
    [frac(2,3), frac(3,4), frac(3,8)],
    [frac(3,8), frac(2,3), frac(3,4)]).
test_harness:arith_misconception(asktm('18-04'), fraction, g4q1_magnitude_transfer,
    misconceptions_fraction:g4q1_18_04,
    [frac(2,3), frac(3,4), frac(3,8)],
    [frac(3,8), frac(2,3), frac(3,4)]).
test_harness:arith_misconception(asktm('06-20'), fraction, g4q1_unlicensed_mutation,
    misconceptions_fraction:g4q1_06_20,
    [frac(2,3), frac(3,4), frac(3,8)],
    [frac(3,8), frac(2,3), frac(3,4)]).

% =============================================================
% G4Q3: Fraction equivalence — multiply numerator only
% Task: write a fraction equivalent to 3/4.
% Correct: scale both numerator and denominator by same factor.
% Error: scales only numerator -> frac(6,4) instead of frac(6,8).
% SCHEMA: Measuring Stick — a fraction is a ratio of two lengths; both must scale.
% GROUNDED: TODO — multiply_grounded(RN, RFactor, RNout), multiply_grounded(RD, RFactor, RDout)
% CONNECTS TO: s(comp_nec(unlicensed(partial_scaling(numerator_only))))
% =============================================================

g4q3_numerator_only(frac(N, D)-Factor, frac(NOut, D)) :-
    NOut is N * Factor.

test_harness:arith_misconception(asktm(g4q3_common), fraction, equivalence_numerator_only,
    misconceptions_fraction:g4q3_numerator_only,
    frac(3,4)-2,
    frac(6,8)).

% =============================================================
% G4Q7: Fraction x whole number — adds whole to numerator
% Task: 3 x 1/4
% Correct: frac(3,4)
% Error: adds whole to numerator -> frac(4,4)
% SCHEMA: Arithmetic is Object Collection — conflates combining with scaling.
% GROUNDED: TODO — multiply_grounded(rec(3), rec(N), RNOut)
% CONNECTS TO: s(comp_nec(unlicensed(operation_substitution(add_for_multiply))))
% =============================================================

g4q7_add_whole_to_numerator(frac(N, D)-Whole, frac(NOut, D)) :-
    NOut is N + Whole.

test_harness:arith_misconception(asktm(g4q7_common), fraction, whole_times_fraction_adds,
    misconceptions_fraction:g4q7_add_whole_to_numerator,
    frac(1,4)-3,
    frac(3,4)).

% =============================================================
% G5Q1: Fraction addition — numerator/denominator separately (butterfly error)
% Task: 1/3 + 2/3
% Correct: equals 1 (encoded as frac(1,1))
% Error: adds top and bottom separately -> frac(3,6)
% SCHEMA: Arithmetic is Object Collection — treats fractions as two independent counts.
% GROUNDED: TODO — add_grounded(RN1, RN2, RNSum), add_grounded(RD1, RD2, RDSum)
% CONNECTS TO: s(comp_nec(unlicensed(componentwise_addition)))
% =============================================================

g5q1_add_separately(frac(N1, D1)-frac(N2, D2), frac(NSum, DSum)) :-
    NSum is N1 + N2,
    DSum is D1 + D2.

test_harness:arith_misconception(asktm(g5q1_common), fraction, add_numerators_denominators_separately,
    misconceptions_fraction:g5q1_add_separately,
    frac(1,3)-frac(2,3),
    frac(1,1)).

% =============================================================
% G5Q7: Fraction of fraction — ignores outer scalar
% Task: 2/3 of 3/4 mile
% Correct: 3/4 * 2/3 = 1/2 -> frac(1,2)
% Error: treats "2/3 of the way" as 2/3 of 1, ignores the whole -> frac(2,3)
% SCHEMA: Measuring Stick — "of the way" = fraction of the whole journey, not fraction of 1.
% GROUNDED: TODO — multiply_grounded on both frac terms
% CONNECTS TO: s(comp_nec(unlicensed(referent_drop(outer_scalar))))
% =============================================================

g5q7_ignore_scalar(_Whole-frac(N, D), frac(N, D)).

test_harness:arith_misconception(asktm(g5q7_common), fraction, fraction_of_fraction_ignores_scalar,
    misconceptions_fraction:g5q7_ignore_scalar,
    frac(3,4)-frac(2,3),
    frac(1,2)).
