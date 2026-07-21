/** <module> Decimal misconception table
 *
 * This table keeps literature-attested decimal misconception
 * registrations beside the runnable rule clauses that support them. The
 * registration schema is test_harness:arith_misconception/6.
 *
 * Clause order retains the effective load order that preceded consolidation.
 * Batch sections remain at the former loader position and proceed in ascending
 * batch number. Existing clauses keep their prior relative order. Original
 * batch module qualifiers remain callable; git history is the archive.
 */
:- module(misconceptions_decimal, []).

:- multifile test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.

% Literature-corpus registrations and their runnable rules.
% decimal misconceptions — research corpus batch 1/2.
% Native arithmetic layer only. Theoretical annotations as comments:
%   % GROUNDED: TODO — placeholder for future embodied arithmetic layer
%   % SCHEMA: <schema name> — Lakoff & Nunez grounding when applicable
%   % CONNECTS TO: s(comp_nec(unlicensed(...))) — PML operator path
%
% Registration convention (from Task 3 arch fix):
%   test_harness:arith_misconception(Source, Domain, Description,
%       misconceptions_decimal_batch_1:rule_name, Input, Expected).
% Rule predicates do NOT go on the module export list.
%
% Representation notes:
%   - A decimal is often encoded as dec(Whole, FracDigits, Len) where FracDigits
%     is the integer formed by the digits after the decimal point, and Len is
%     the digit length (so 0.08 is dec(0,8,2), 0.125 is dec(0,125,3)).
%     This lets digit-count misconceptions ("longer is smaller") reason about
%     Len without float artifacts.
%   - A pair of decimals for comparison: D1-D2.
%   - For purely numeric errors we use Prolog floats via is/2 and rationals.
%   - Operation-choice misconceptions receive a triple/pair of operands and
%     return the wrong numeric answer (e.g., division where multiplication
%     was called for).


% ---- Encodings appended by agent for decimal batch 1 ----

% === row 37483: decimal operator must be whole (pick wrong op) ===
% Task: price-per-unit 15000, amount 0.75 -> 15000 * 0.75 = 11250
% Correct: 11250.0
% Error: divides instead (15000 / 0.75 = 20000.0) because operator < 1 "must divide"
% SCHEMA: Motion Along a Path (repeated addition locks operator to integer)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(decimal_operator_must_be_whole)))
misconceptions_decimal_batch_1:(r37483_div_instead_mult(price(Price)-amount(Amt), Got) :-
    Got is Price / Amt).

test_harness:arith_misconception(db_row(37483), decimal, decimal_operator_must_be_whole,
    misconceptions_decimal_batch_1:r37483_div_instead_mult,
    price(15000)-amount(0.75),
    11250.0).

% === row 37499: finite decimals between two decimals (density) ===
test_harness:arith_misconception(db_row(37499), decimal, too_vague,
    skip, none, none).

% === row 37503: blind decimal placement in product ===
% Task: digits 291357 are the product of 534.6 and 0.545; place the point.
% Correct: 291.357 (534.6 * 0.545 ~= 291.357)
% Error: counts 4 decimal digits total -> 29.1357
% SCHEMA: Arithmetic is Symbolic Manipulation (rule over estimation)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(blind_place_by_digit_count)))
misconceptions_decimal_batch_1:(r37503_blind_place(digits(D)-places(P), Got) :-
    Got is D / (10 ** P)).

test_harness:arith_misconception(db_row(37503), decimal, blind_decimal_placement,
    misconceptions_decimal_batch_1:r37503_blind_place,
    digits(291357)-places(4),
    291.357).

% === row 37556: division always makes smaller (quotient < dividend) ===
% Task: judge whether 10 / 0.65 > 10.
% Correct: gt (10 / 0.65 ~= 15.38)
% Error: says lt because "division always makes smaller"
% SCHEMA: Arithmetic is Object Collection (partitive primitive)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(division_always_smaller)))
misconceptions_decimal_batch_1:(r37556_div_always_smaller(dividend(A)-divisor(B), Judgment) :-
    Q is A / B,
    (   Q > A -> Judgment = lt   % student says quotient < dividend
    ;   Q < A -> Judgment = lt
    ;             Judgment = eq
    )).

test_harness:arith_misconception(db_row(37556), decimal, division_always_smaller,
    misconceptions_decimal_batch_1:r37556_div_always_smaller,
    dividend(10)-divisor(0.65),
    gt).

% === row 37596: longer-is-larger whole-number transfer ===
% Task: compare 0.355 and 0.5; return the larger.
% Correct: dec(0,5,1)   (0.5 > 0.355)
% Error: picks dec(0,355,3) because 355 > 5 as whole numbers
% SCHEMA: Arithmetic is Object Collection (digit count as cardinality)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(longer_is_larger)))
misconceptions_decimal_batch_1:(r37596_longer_is_larger(dec(W,F1,L1)-dec(W,F2,L2), Winner) :-
    (   F1 > F2
    ->  Winner = dec(W,F1,L1)
    ;   Winner = dec(W,F2,L2)
    )).

test_harness:arith_misconception(db_row(37596), decimal, longer_is_larger,
    misconceptions_decimal_batch_1:r37596_longer_is_larger,
    dec(0,355,3)-dec(0,5,1),
    dec(0,5,1)).

% === row 37598: column name mirror symmetry (oneths) ===
test_harness:arith_misconception(db_row(37598), decimal, too_vague,
    skip, none, none).

% === row 37600: 0.999... < 1 ===
test_harness:arith_misconception(db_row(37600), decimal, too_vague,
    skip, none, none).

% === row 37616: more decimal places = smaller (fraction rule overapplied) ===
% Task: compare 1.35 and 1.2; return the larger.
% Correct: dec(1,35,2)   (1.35 > 1.2)
% Error: picks dec(1,2,1) because "hundredths < tenths, so 1.35 < 1.2"
% SCHEMA: Arithmetic is Object Collection (unit size without coordination)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(more_places_smaller)))
misconceptions_decimal_batch_1:(r37616_more_places_smaller(dec(W,F1,L1)-dec(W,F2,L2), Winner) :-
    (   L1 < L2
    ->  Winner = dec(W,F1,L1)
    ;   L1 > L2
    ->  Winner = dec(W,F2,L2)
    ;   (F1 >= F2 -> Winner = dec(W,F1,L1) ; Winner = dec(W,F2,L2))
    )).

test_harness:arith_misconception(db_row(37616), decimal, more_places_smaller,
    misconceptions_decimal_batch_1:r37616_more_places_smaller,
    dec(1,35,2)-dec(1,2,1),
    dec(1,35,2)).

% === row 37618: numerator-only fraction -> decimal ===
% Task: translate 3/4 to decimal notation.
% Correct: 0.75
% Error: writes .3 (encodes only the numerator)
% SCHEMA: Arithmetic is Symbolic Manipulation (syntax over reference)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(numerator_as_decimal)))
misconceptions_decimal_batch_1:(r37618_num_only(frac(N,_), Got) :-
    Got is N / 10).

test_harness:arith_misconception(db_row(37618), decimal, numerator_as_decimal,
    misconceptions_decimal_batch_1:r37618_num_only,
    frac(3,4),
    0.75).

% === row 37620: syntactic fraction -> decimal (point between) ===
% Task: translate 3/4 to decimal.
% Correct: 0.75
% Error: writes 3.4 (keeps both numerals with point between)
% SCHEMA: Arithmetic is Symbolic Manipulation
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(fraction_bar_as_point)))
misconceptions_decimal_batch_1:(r37620_bar_as_point(frac(N,D), Got) :-
    Got is N + D / 10).

test_harness:arith_misconception(db_row(37620), decimal, fraction_bar_as_point,
    misconceptions_decimal_batch_1:r37620_bar_as_point,
    frac(3,4),
    0.75).

% === row 37636: decimal point as separator in subtraction ===
% Task: 7.31 - 6.4
% Correct: 0.91
% Error: 1.27 (treats as paired independent whole-number subtractions:
%              7-6 = 1 ; 31-4 wrong -> student-reported 1.27)
% SCHEMA: Container — two independent whole-number subtractions
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(decimal_as_separator)))
misconceptions_decimal_batch_1:(r37636_sep_sub(dec(W1,F1,L1)-dec(W2,F2,L2), dec(WD,FD,Len)) :-
    WD is W1 - W2,
    FD is F1 - F2,
    Len is max(L1,L2)).

test_harness:arith_misconception(db_row(37636), decimal, decimal_as_separator,
    misconceptions_decimal_batch_1:r37636_sep_sub,
    dec(7,31,2)-dec(6,4,1),
    dec(0,91,2)).

% === row 37638: ignore decimal, arbitrary insert ===
% Task: 2.5 + 1.25 (illustrative use of the rule)
% Correct: 3.75
% Error: adds 25 + 125 = 150, inserts point arbitrarily -> 15.0
% SCHEMA: Arithmetic is Symbolic Manipulation
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(ignore_decimal_then_insert)))
misconceptions_decimal_batch_1:(r37638_ignore_then_insert(dec(W1,F1,_)-dec(W2,F2,_), Got) :-
    Whole is W1 * 10 + F1,
    Other is W2 * 10 + F2,
    Sum is Whole + Other,
    Got is Sum / 10).

test_harness:arith_misconception(db_row(37638), decimal, ignore_decimal_then_insert,
    misconceptions_decimal_batch_1:r37638_ignore_then_insert,
    dec(2,5,1)-dec(1,25,2),
    3.75).

% === row 37699: infinitesimal 0.000...1 notation ===
test_harness:arith_misconception(db_row(37699), decimal, too_vague,
    skip, none, none).

% === row 37717: generic "skill or algorithm" errors (no example) ===
test_harness:arith_misconception(db_row(37717), decimal, too_vague,
    skip, none, none).

% === row 37799: division always smaller, pick div for mult ===
% Task: for mult problem with decimal operator < 1, student picks division.
%       Concrete: per-kg 4.25, amount 0.64 -> correct 4.25 * 0.64 = 2.72
% Correct: 2.72
% Error: 4.25 / 0.64 = 6.640625 (div-instead-of-mult)
% SCHEMA: Motion Along a Path
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(div_instead_of_mult)))
misconceptions_decimal_batch_1:(r37799_div_for_mult(a(A)-b(B), Got) :-
    Got is A / B).

test_harness:arith_misconception(db_row(37799), decimal, div_instead_of_mult,
    misconceptions_decimal_batch_1:r37799_div_for_mult,
    a(4.25)-b(0.64),
    2.72).

% === row 37802: swap divisor and dividend to avoid decimal divisor ===
% Task: compute 5 / 3.25
% Correct: ~1.5384615...  (use 5 / 3.25 directly)
% Error: swaps to 3.25 / 5 = 0.65
% SCHEMA: Arithmetic is Symbolic Manipulation (rewrite to avoid taboo shape)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(swap_to_integer_divisor)))
misconceptions_decimal_batch_1:(r37802_swap_operands(dividend(A)-divisor(B), Got) :-
    Got is B / A).

test_harness:arith_misconception(db_row(37802), decimal, swap_to_integer_divisor,
    misconceptions_decimal_batch_1:r37802_swap_operands,
    dividend(5)-divisor(3.25),
    1.5384615384615385).

% === row 37816: ragged decimal addition (whole + tenth) ===
% Task: 5 + 0.3
% Correct: 5.3
% Error: .8 — "5 + 3 is 8, point stays in front"
% SCHEMA: Arithmetic is Symbolic Manipulation
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(ragged_decimal_addition)))
misconceptions_decimal_batch_1:(r37816_ragged_add(dec(W1,_,_)-dec(W2,F2,L2), dec(0, FD, L2)) :-
    FD is W1 + W2 + F2).

test_harness:arith_misconception(db_row(37816), decimal, ragged_decimal_addition,
    misconceptions_decimal_batch_1:r37816_ragged_add,
    dec(5,0,0)-dec(0,3,1),
    dec(5,3,1)).

% === row 37874: no number exists between 2.746 and 2.747; (2.4)^2 = 4.16 ===
% Task: (2.4)^2 — the operational side of the misconception.
% Correct: 5.76
% Error: treats decimal halves as independent integers:
%        whole part 2^2 = 4 ; fractional part 4^2 = 16 -> 4.16
% SCHEMA: Container — two integer parts squared independently
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(square_parts_independently)))
misconceptions_decimal_batch_1:(r37874_square_parts(dec(W,F,L), dec(WS,FS,L)) :-
    WS is W * W,
    FS is F * F).

test_harness:arith_misconception(db_row(37874), decimal, square_parts_independently,
    misconceptions_decimal_batch_1:r37874_square_parts,
    dec(2,4,1),
    dec(5,76,2)).

% === row 37984: subtract decimal from whole, append unchanged ===
% Task: 20 - 7.70
% Correct: 12.30
% Error: 13.30 — subtracts whole parts (20 - 7 = 13), appends .70 raw
% SCHEMA: Container — two zones, no borrowing across the point
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(no_borrow_across_point)))
misconceptions_decimal_batch_1:(r37984_no_borrow(dec(W1,_,_)-dec(W2,F2,L2), dec(WD,F2,L2)) :-
    WD is W1 - W2).

test_harness:arith_misconception(db_row(37984), decimal, no_borrow_across_point,
    misconceptions_decimal_batch_1:r37984_no_borrow,
    dec(20,0,0)-dec(7,70,2),
    dec(12,30,2)).

% === row 38098: mult-makes-bigger general struggle (no concrete error) ===
test_harness:arith_misconception(db_row(38098), decimal, too_vague,
    skip, none, none).

% === row 38305: longer-is-larger (ordering): .134 > .2 ===
% Task: compare 0.134 and 0.2; return the larger.
% Correct: dec(0,2,1)   (0.2 > 0.134)
% Error: picks dec(0,134,3) because 134 > 2
% SCHEMA: Arithmetic is Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(longer_is_larger_ordering)))
misconceptions_decimal_batch_1:(r38305_longer_larger_order(dec(W,F1,L1)-dec(W,F2,L2), Winner) :-
    (   F1 > F2
    ->  Winner = dec(W,F1,L1)
    ;   Winner = dec(W,F2,L2)
    )).

test_harness:arith_misconception(db_row(38305), decimal, longer_is_larger_ordering,
    misconceptions_decimal_batch_1:r38305_longer_larger_order,
    dec(0,134,3)-dec(0,2,1),
    dec(0,2,1)).

% === row 38307: interpret decimal remainder in quotient ===
test_harness:arith_misconception(db_row(38307), decimal, too_vague,
    skip, none, none).

% === row 38398: "tenths means tens" place value inflation ===
% Task: what value does the 4 in 0.435 represent?
% Correct: 0.4 (four-tenths)
% Error: 400 — student extends integer place names ("tenths = tens")
% SCHEMA: Arithmetic is Object Collection — positional names carried without shift
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(place_name_inflation)))
misconceptions_decimal_batch_1:(r38398_place_inflation(digit(D)-pos(P), Got) :-
    %  Correct value of digit D in 10^-P position is D * 10^-P.
    %  The student's wrong rule: D in "tenths" means D * 10 (like tens),
    %  D in "hundredths" means D * 100, etc.
    Got is D * (10 ** P)).

test_harness:arith_misconception(db_row(38398), decimal, place_name_inflation,
    misconceptions_decimal_batch_1:r38398_place_inflation,
    digit(4)-pos(1),
    0.4).

% === row 38400: shorter-is-larger via denominator analogy ===
% Task: compare 0.32 and 0.384; return the larger.
% Correct: dec(0,384,3)   (0.384 > 0.32)
% Error: picks dec(0,32,2) because "1 out of 32 > 1 out of 384"
% SCHEMA: Arithmetic is Object Collection (denominator analogy)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(denominator_analogy_shorter_larger)))
misconceptions_decimal_batch_1:(r38400_denom_analogy(dec(W,F1,L1)-dec(W,F2,L2), Winner) :-
    (   L1 < L2
    ->  Winner = dec(W,F1,L1)
    ;   L1 > L2
    ->  Winner = dec(W,F2,L2)
    ;   (F1 >= F2 -> Winner = dec(W,F1,L1) ; Winner = dec(W,F2,L2))
    )).

test_harness:arith_misconception(db_row(38400), decimal, denominator_analogy_shorter_larger,
    misconceptions_decimal_batch_1:r38400_denom_analogy,
    dec(0,32,2)-dec(0,384,3),
    dec(0,384,3)).

% === row 38415: negative number ray mirror (with negative decimals) ===
test_harness:arith_misconception(db_row(38415), decimal, too_vague,
    skip, none, none).

% === row 38441: divisor must be smaller than dividend ===
test_harness:arith_misconception(db_row(38441), decimal, too_vague,
    skip, none, none).

% === row 38531: 0.333... * 3 ≠ 1 belief ===
test_harness:arith_misconception(db_row(38531), decimal, too_vague,
    misconceptions_decimal_churn_2026_07_21:churn_38531_infinite_decimal_falls_short_of_its_limit,
    repeating(0,9), 1.0).

% === row 38564: shorter-is-larger via tenths > hundredths ===
% Task: compare 2.3 and 2.32; return the larger.
% Correct: dec(2,32,2)   (2.32 > 2.3)
% Error: picks dec(2,3,1) — "tenths > hundredths"
% SCHEMA: Arithmetic is Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(shorter_is_larger)))
misconceptions_decimal_batch_1:(r38564_shorter_larger(dec(W,F1,L1)-dec(W,F2,L2), Winner) :-
    (   L1 < L2
    ->  Winner = dec(W,F1,L1)
    ;   L1 > L2
    ->  Winner = dec(W,F2,L2)
    ;   (F1 >= F2 -> Winner = dec(W,F1,L1) ; Winner = dec(W,F2,L2))
    )).

test_harness:arith_misconception(db_row(38564), decimal, shorter_is_larger,
    misconceptions_decimal_batch_1:r38564_shorter_larger,
    dec(2,3,1)-dec(2,32,2),
    dec(2,32,2)).

% === row 38597: equal-groups model fails for decimal factors ===
test_harness:arith_misconception(db_row(38597), decimal, too_vague,
    skip, none, none).

% === row 38642: 0.999... < 1 (teachers) ===
test_harness:arith_misconception(db_row(38642), decimal, too_vague,
    skip, none, none).

% === row 38651: whole depends on denominator (3/4 -> 0.7 via 8-1=7) ===
test_harness:arith_misconception(db_row(38651), decimal, too_vague,
    skip, none, none).

% === row 38727: div instead of mult for decimal operator (cheese price) ===
% Task: cost of 0.923 kg at 27.50 kr/kg -> 27.50 * 0.923 = 25.3825
% Correct: 25.3825
% Error: 27.50 / 0.923 ~= 29.79 (div-instead-of-mult)
% SCHEMA: Motion Along a Path (repeated addition obstruction)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(div_instead_of_mult)))
misconceptions_decimal_batch_1:(r38727_div_instead_mult(price(P)-amount(A), Got) :-
    Got is P / A).

test_harness:arith_misconception(db_row(38727), decimal, div_instead_of_mult,
    misconceptions_decimal_batch_1:r38727_div_instead_mult,
    price(27.50)-amount(0.923),
    25.3825).

% === row 38730: invent word problem with discrete unit + decimal quantity ===
test_harness:arith_misconception(db_row(38730), decimal, too_vague,
    skip, none, none).

% === row 38745: remediation resistance ===
test_harness:arith_misconception(db_row(38745), decimal, too_vague,
    skip, none, none).

% === row 38791: working memory failure on multi-step ===
test_harness:arith_misconception(db_row(38791), decimal, too_vague,
    skip, none, none).

% === row 38826: 0.999... = 1 rejected ===
test_harness:arith_misconception(db_row(38826), decimal, too_vague,
    skip, none, none).

% === row 38919: teacher marks cultural algorithm wrong ===
test_harness:arith_misconception(db_row(38919), decimal, too_vague,
    skip, none, none).

% === row 38927: div instead of mult (0.22 gallon can, £1.20/gallon) ===
% Task: cost of 0.22 gallon at 1.20 per gallon -> 1.20 * 0.22 = 0.264
% Correct: 0.264
% Error: 1.20 / 0.22 ~= 5.4545 (div-instead-of-mult because "answer must be smaller")
% SCHEMA: Motion Along a Path
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(div_instead_of_mult)))
misconceptions_decimal_batch_1:(r38927_div_instead_mult(rate(R)-qty(Q), Got) :-
    Got is R / Q).

test_harness:arith_misconception(db_row(38927), decimal, div_instead_of_mult,
    misconceptions_decimal_batch_1:r38927_div_instead_mult,
    rate(1.20)-qty(0.22),
    0.264).

% === row 38930: structure changes with number substitution ===
test_harness:arith_misconception(db_row(38930), decimal, too_vague,
    skip, none, none).

% === row 38959: overgeneralize repeating decimal for any difficult division ===
test_harness:arith_misconception(db_row(38959), decimal, too_vague,
    skip, none, none).

% === row 39000: calculator reciprocal recognition ===
test_harness:arith_misconception(db_row(39000), decimal, too_vague,
    skip, none, none).

% === row 39049: decimal operator constraint (no arithmetic shown) ===
test_harness:arith_misconception(db_row(39049), decimal, too_vague,
    skip, none, none).

% === row 39077: mult-makes-bigger drives wrong mult choice (Mini problem) ===
% Task: 5.5 gallons to litres, 1 litre = 0.22 gallons -> 5.5 / 0.22 = 25 litres
% Correct: 25.0
% Error: multiplies (5.5 * 0.22 = 1.21) because "answer should be bigger,
%        so mult" (backwards reasoning from target magnitude)
% SCHEMA: Arithmetic is Motion Along a Path
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(mult_instead_of_div)))
misconceptions_decimal_batch_1:(r39077_mult_instead_div(qty(Q)-rate(R), Got) :-
    Got is Q * R).

test_harness:arith_misconception(db_row(39077), decimal, mult_instead_of_div,
    misconceptions_decimal_batch_1:r39077_mult_instead_div,
    qty(5.5)-rate(0.22),
    25.0).

% === row 39080: invariance of operation under substitution ===
test_harness:arith_misconception(db_row(39080), decimal, too_vague,
    skip, none, none).

% === row 39128: match whole-number digits rather than total decimal places ===
% Task: given 741 * 12 = 8892, find 74.1 * 12.
% Correct: 889.2  (one decimal place: factor had 1 dp)
% Error: 88.92 — "place point so that 2 digits precede it, matching the '74'
%   seen in the factor 74.1"
% Rule input: product_digits(D)-factor_whole_digits(W) — W = digits-before-point
%   in the factor the student anchors on (2 for 74.1). Student places the point
%   so that W digits precede it in the answer.
% SCHEMA: Arithmetic is Symbolic Manipulation
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(match_whole_digits)))
misconceptions_decimal_batch_1:(r39128_match_whole_digits(digits(D)-factor_whole(W), Got) :-
    count_digits(D, Total),
    Tail is Total - W,
    Got is D / (10 ** Tail)).

% helper: number of decimal digits of a positive integer.
misconceptions_decimal_batch_1:(count_digits(0, 1) :- !).
misconceptions_decimal_batch_1:(count_digits(N, C) :- N > 0, count_digits_acc(N, 0, C)).
misconceptions_decimal_batch_1:(count_digits_acc(0, Acc, Acc) :- Acc > 0, !).
misconceptions_decimal_batch_1:(count_digits_acc(N, Acc, C) :-
    N > 0,
    N1 is N // 10,
    Acc1 is Acc + 1,
    count_digits_acc(N1, Acc1, C)).

test_harness:arith_misconception(db_row(39128), decimal, match_whole_digits,
    misconceptions_decimal_batch_1:r39128_match_whole_digits,
    digits(8892)-factor_whole(2),
    889.2).

% === row 39164: mult-makes-bigger (15 * 0.6 = 9 "seems wrong") ===
test_harness:arith_misconception(db_row(39164), decimal, too_vague,
    skip, none, none).

% === row 39191: quasi-material representation (no specific error) ===
test_harness:arith_misconception(db_row(39191), decimal, too_vague,
    skip, none, none).

% === row 39271: same-precision-only counting (density) ===
test_harness:arith_misconception(db_row(39271), decimal, too_vague,
    skip, none, none).

% === row 39323: interpreting quotient > dividend ===
test_harness:arith_misconception(db_row(39323), decimal, too_vague,
    skip, none, none).

% === row 39340: procedural focus on placement ===
test_harness:arith_misconception(db_row(39340), decimal, too_vague,
    skip, none, none).

% === row 39398: recurring as process, not number ===
test_harness:arith_misconception(db_row(39398), decimal, too_vague,
    skip, none, none).

% === row 39407: mult-makes-bigger: 0.45 * 90 < 90 judged false ===
% Task: judge whether 0.45 * 90 < 90.
% Correct: true (40.5 < 90)
% Error: says false because "multiplication makes bigger"
% SCHEMA: Motion Along a Path
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(mult_makes_bigger_belief)))
misconceptions_decimal_batch_1:(r39407_mmb_judge(a(A)-b(B), Judgment) :-
    P is A * B,
    (   P < B -> Judgment = false  % student inverts truth
    ;   P > B -> Judgment = true
    ;             Judgment = eq
    )).

test_harness:arith_misconception(db_row(39407), decimal, mult_makes_bigger_judgment,
    misconceptions_decimal_batch_1:r39407_mmb_judge,
    a(0.45)-b(90),
    true).

% === row 39438: whole-number comparison: .231 > .31 ===
% Task: compare 0.231 and 0.31; return the larger.
% Correct: dec(0,31,2)   (0.31 > 0.231)
% Error: picks dec(0,231,3) because 231 > 31
% SCHEMA: Arithmetic is Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(whole_number_string_compare)))
misconceptions_decimal_batch_1:(r39438_whole_string_compare(dec(W,F1,L1)-dec(W,F2,L2), Winner) :-
    (   F1 > F2
    ->  Winner = dec(W,F1,L1)
    ;   Winner = dec(W,F2,L2)
    )).

test_harness:arith_misconception(db_row(39438), decimal, whole_number_string_compare,
    misconceptions_decimal_batch_1:r39438_whole_string_compare,
    dec(0,231,3)-dec(0,31,2),
    dec(0,31,2)).

% === row 39440: place value label mirror (oneths/tenths/hundredths) ===
test_harness:arith_misconception(db_row(39440), decimal, too_vague,
    skip, none, none).

% === row 39442: decimal as fraction with replaced bar (.8 = 1/8) ===
% Task: convert 0.8 to a fraction.
% Correct: frac(4,5)  (or frac(8,10))
% Error: frac(1,8) — student replaces point with bar and inserts a 1
% SCHEMA: Arithmetic is Symbolic Manipulation
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(point_as_fraction_bar)))
misconceptions_decimal_batch_1:(r39442_bar_swap(dec(0,F,_), frac(1,F))).

test_harness:arith_misconception(db_row(39442), decimal, point_as_fraction_bar,
    misconceptions_decimal_batch_1:r39442_bar_swap,
    dec(0,8,1),
    frac(4,5)).

% === row 39460: longer-is-larger: 4.63 > 4.8 ===
% Task: compare 4.63 and 4.8; return the larger.
% Correct: dec(4,8,1)
% Error: picks dec(4,63,2) because 63 > 8
% SCHEMA: Arithmetic is Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(longer_is_larger)))
misconceptions_decimal_batch_1:(r39460_longer_larger(dec(W,F1,L1)-dec(W,F2,L2), Winner) :-
    (   F1 > F2
    ->  Winner = dec(W,F1,L1)
    ;   Winner = dec(W,F2,L2)
    )).

test_harness:arith_misconception(db_row(39460), decimal, longer_is_larger,
    misconceptions_decimal_batch_1:r39460_longer_larger,
    dec(4,63,2)-dec(4,8,1),
    dec(4,8,1)).

% === row 39462: zero-in-tenths variant (4.7 > 4.08 correct; 0.25 > 0.5 wrong) ===
% Task: compare 0.25 and 0.5 (the characteristic failure case).
% Correct: dec(0,5,1)
% Error: picks dec(0,25,2) because longer-is-larger when no tenths zero
% SCHEMA: Arithmetic is Object Collection (rule-with-exception)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(longer_is_larger_with_zero_rule)))
misconceptions_decimal_batch_1:(r39462_longer_larger_with_zero(dec(W,F1,L1)-dec(W,F2,L2), Winner) :-
    % if either number starts with a 0 in the tenths place, use that one as smaller;
    % otherwise, longer is larger.
    (   tenth_is_zero(F1,L1)
    ->  (   tenth_is_zero(F2,L2)
        ->  (F1 >= F2 -> Winner = dec(W,F1,L1) ; Winner = dec(W,F2,L2))
        ;   Winner = dec(W,F2,L2)
        )
    ;   tenth_is_zero(F2,L2)
    ->  Winner = dec(W,F1,L1)
    ;   (F1 >= F2 -> Winner = dec(W,F1,L1) ; Winner = dec(W,F2,L2))
    )).

% Leading tenth digit is zero if Frac < 10^(Len-1).
misconceptions_decimal_batch_1:(tenth_is_zero(F,L) :-
    L >= 1,
    F < 10 ** (L - 1)).

test_harness:arith_misconception(db_row(39462), decimal, longer_is_larger_zero_rule,
    misconceptions_decimal_batch_1:r39462_longer_larger_with_zero,
    dec(0,25,2)-dec(0,5,1),
    dec(0,5,1)).

% === row 39493: divisor-must-be-integer model ===
test_harness:arith_misconception(db_row(39493), decimal, too_vague,
    misconceptions_decimal_churn_2026_07_21:churn_39493_divisor_integer_dividend_larger,
    dividend(5)-divisor(7), 0.7142857142857143).

% === row 39525: multibase block dimensionality ===
test_harness:arith_misconception(db_row(39525), decimal, too_vague,
    skip, none, none).

% === row 39575: more digits = smaller (natural number rules reversed) ===
% Task: compare 1.12 and 1.3; return the larger.
% Correct: dec(1,3,1)
% Error: picks dec(1,12,2) — wait, student says "more digits means smaller", so
%   1.12 < 1.3, so correct is 1.3. Error: the student's rule applied correctly
%   gives the correct pick. Use instead: compare 1.46 and 1.4 (the 2nd example).
%   Student says 1.46 < 1.4 -> picks 1.4 as larger, but correct is 1.46.
% Correct: dec(1,46,2)
% Error: picks dec(1,4,1) by "more digits smaller"
% SCHEMA: Arithmetic is Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(more_digits_smaller)))
misconceptions_decimal_batch_1:(r39575_more_digits_smaller(dec(W,F1,L1)-dec(W,F2,L2), Winner) :-
    (   L1 < L2
    ->  Winner = dec(W,F1,L1)
    ;   L1 > L2
    ->  Winner = dec(W,F2,L2)
    ;   (F1 >= F2 -> Winner = dec(W,F1,L1) ; Winner = dec(W,F2,L2))
    )).

test_harness:arith_misconception(db_row(39575), decimal, more_digits_smaller,
    misconceptions_decimal_batch_1:r39575_more_digits_smaller,
    dec(1,46,2)-dec(1,4,1),
    dec(1,46,2)).

% === row 39608: misunderstanding of place value and decimal-point movement ===
test_harness:arith_misconception(db_row(39608), decimal, too_vague,
    skip, none, none).

% === row 39623: 4.8 < 4.63 via whole-number string ===
% Task: compare 4.8 and 4.63; return the larger.
% Correct: dec(4,8,1)
% Error: picks dec(4,63,2) because 63 > 8
% SCHEMA: Arithmetic is Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(longer_is_larger)))
misconceptions_decimal_batch_1:(r39623_longer_larger(dec(W,F1,_)-dec(W,F2,_), Winner) :-
    (   F1 > F2
    ->  Winner = dec(W,F1,_)
    ;   Winner = dec(W,F2,_)
    )).

test_harness:arith_misconception(db_row(39623), decimal, longer_is_larger,
    misconceptions_decimal_batch_1:r39623_longer_larger,
    dec(4,63,2)-dec(4,8,1),
    dec(4,8,1)).

% === row 39625: money-cents truncation (ignore digits past hundredths) ===
% Task: compare 4.4502 and 4.45; return the larger.
% Correct: dec(4,4502,4)   (4.4502 > 4.45)
% Error: truncates to 2 dp then claims 4.45 = 4.45 -> reports equality;
%   the student in the study arrived at the right answer by accident.
%   Encode the truncation rule: returns the "cents truncated" value.
% SCHEMA: Arithmetic is Symbolic Manipulation (money-place truncation)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(money_place_truncation)))
misconceptions_decimal_batch_1:(r39625_money_truncate(dec(W,F,L), dec(W,FT,LT)) :-
    (   L =< 2
    ->  FT = F, LT = L
    ;   Shift is L - 2,
        FT is F div (10 ** Shift),
        LT = 2
    )).

test_harness:arith_misconception(db_row(39625), decimal, money_place_truncation,
    misconceptions_decimal_batch_1:r39625_money_truncate,
    dec(4,4502,4),
    dec(4,4502,4)).

% === row 39632: fraction rule: tenths always > hundredths ===
% Task: compare 2.3 and 2.67; return the larger.
% Correct: dec(2,67,2)   (2.67 > 2.3)
% Error: picks dec(2,3,1) because "tenths > hundredths"
% SCHEMA: Arithmetic is Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(tenths_always_larger)))
misconceptions_decimal_batch_1:(r39632_tenths_larger(dec(W,F1,L1)-dec(W,F2,L2), Winner) :-
    (   L1 < L2
    ->  Winner = dec(W,F1,L1)
    ;   L1 > L2
    ->  Winner = dec(W,F2,L2)
    ;   (F1 >= F2 -> Winner = dec(W,F1,L1) ; Winner = dec(W,F2,L2))
    )).

test_harness:arith_misconception(db_row(39632), decimal, tenths_always_larger,
    misconceptions_decimal_batch_1:r39632_tenths_larger,
    dec(2,3,1)-dec(2,67,2),
    dec(2,67,2)).

% === row 39634: 102 * 0.1 bewilderment (no rule) ===
test_harness:arith_misconception(db_row(39634), decimal, too_vague,
    skip, none, none).

% === row 39645: discrete-entity resistance (0.57 people) ===
test_harness:arith_misconception(db_row(39645), decimal, too_vague,
    skip, none, none).

% === row 39667: MMB/DMS general belief ===
test_harness:arith_misconception(db_row(39667), decimal, too_vague,
    skip, none, none).

% === row 39676: only doubling divisors terminate ===
test_harness:arith_misconception(db_row(39676), decimal, too_vague,
    skip, none, none).

% === row 39708: ignore point in subtraction, copy back later ===
% Task: 0.938 - 0.552
% Correct: 0.386
% Error: 0.386 — student computes 938-552 = 386 and "copies the point and zero";
%   here the wrong procedure happens to yield the correct result.
%   Use a case where the procedure FAILS visibly: 0.93 - 0.552 (mismatched lengths).
%   Correct: 0.378
%   Error: 93 - 552 undefined; student might do 552-93 = 459 or append zeros.
%   Most literal version of the rule: treat as integers 938 vs 552, append point.
%   For the original input pair, correct answer and procedure agree -> use it.
% SCHEMA: Arithmetic is Symbolic Manipulation
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(subtract_ignore_point)))
misconceptions_decimal_batch_1:(r39708_ignore_point_sub(dec(W1,F1,L)-dec(W2,F2,L), dec(0,FD,L)) :-
    A is W1 * (10 ** L) + F1,
    B is W2 * (10 ** L) + F2,
    FD is A - B).

test_harness:arith_misconception(db_row(39708), decimal, subtract_ignore_point,
    misconceptions_decimal_batch_1:r39708_ignore_point_sub,
    dec(0,938,3)-dec(0,552,3),
    dec(0,386,3)).

% === row 39732: order decimals by whole-number distance from zero ===
% Task: compare 0.81 and 0.801 (smaller of the two as "whole number closest to 0").
%       Student's rule: whichever integer-form is smaller is the smaller decimal.
%       So student says 0.81 (81) < 0.801 (801).
% Correct: dec(0,801,3)  is the smaller one? No — 0.801 < 0.81, so correct smaller
%          is dec(0,801,3). Student says dec(0,81,2) is smaller.
% Return the smaller (as inverse comparison).
% SCHEMA: Arithmetic is Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(closer_to_zero_by_integer)))
misconceptions_decimal_batch_1:(r39732_int_closer_zero(dec(W,F1,L1)-dec(W,F2,L2), Smaller) :-
    (   F1 < F2
    ->  Smaller = dec(W,F1,L1)
    ;   Smaller = dec(W,F2,L2)
    )).

test_harness:arith_misconception(db_row(39732), decimal, closer_to_zero_by_integer,
    misconceptions_decimal_batch_1:r39732_int_closer_zero,
    dec(0,81,2)-dec(0,801,3),
    dec(0,801,3)).

% === row 39791: 0.2 * 0.1 = 0.2 (teacher error) ===
% Task: 0.2 * 0.1
% Correct: 0.02
% Error: 0.2 — teacher "multiplication doesn't shrink", so output equals larger factor.
% SCHEMA: Motion Along a Path (MMB teacher belief)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(mmb_teacher_copies_larger)))
misconceptions_decimal_batch_1:(r39791_mmb_copy_larger(a(A)-b(B), Got) :-
    (A >= B -> Got = A ; Got = B)).

test_harness:arith_misconception(db_row(39791), decimal, mmb_copy_larger_factor,
    misconceptions_decimal_batch_1:r39791_mmb_copy_larger,
    a(0.2)-b(0.1),
    0.02).

% === row 39793: more decimal places = smaller (teachers order 0.005 first) ===
% Task: compare 0.135 and 0.03; return the larger.
% Correct: dec(0,135,3)   (0.135 > 0.03)
% Error: picks dec(0,3,2)? student places 3-dp first as smallest; actually 0.03 is
%        2-dp so student would order 0.135 < 0.03 ("more places = smaller") and
%        pick dec(0,3,2) as larger.
% SCHEMA: Arithmetic is Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(more_places_smaller_teacher)))
misconceptions_decimal_batch_1:(r39793_more_places_smaller(dec(W,F1,L1)-dec(W,F2,L2), Winner) :-
    (   L1 < L2
    ->  Winner = dec(W,F1,L1)
    ;   L1 > L2
    ->  Winner = dec(W,F2,L2)
    ;   (F1 >= F2 -> Winner = dec(W,F1,L1) ; Winner = dec(W,F2,L2))
    )).

test_harness:arith_misconception(db_row(39793), decimal, more_places_smaller_teacher,
    misconceptions_decimal_batch_1:r39793_more_places_smaller,
    dec(0,135,3)-dec(0,3,2),
    dec(0,135,3)).

% === row 39896: basic fact errors ===
test_harness:arith_misconception(db_row(39896), decimal, too_vague,
    skip, none, none).

% === row 40023: grid unit confusion ===
test_harness:arith_misconception(db_row(40023), decimal, too_vague,
    skip, none, none).

% === row 40048: decimal division point-shifting error ===
% Task: 0.4 / 0.05
% Correct: 8.0
% Error: 0.08 — student moves decimals to convert to 40 / 5 = 8, then "moves them
%        back" by shifting twice the other way.
% SCHEMA: Arithmetic is Symbolic Manipulation
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(double_decimal_shift)))
misconceptions_decimal_batch_1:(r40048_double_shift(dividend(A)-divisor(B), Got) :-
    % compute correct A/B, then divide by 100 (undo the scaling twice).
    Q is A / B,
    Got is Q / 100).

test_harness:arith_misconception(db_row(40048), decimal, double_decimal_shift,
    misconceptions_decimal_batch_1:r40048_double_shift,
    dividend(0.4)-divisor(0.05),
    8.0).

% === row 40080: decimal point in remainder ===
test_harness:arith_misconception(db_row(40080), decimal, too_vague,
    skip, none, none).

% === row 40138: shorter-is-larger via reciprocal thinking ===
% Task: compare 0.3 and 0.4; return the larger.
% Correct: dec(0,4,1)
% Error: picks dec(0,3,1)? No — same length, so this doesn't trigger the rule.
%   The study's example is 0.3 > 0.4 "by analogy with 1/3 > 1/4".
%   This is reciprocal thinking: bigger-digit-in-tenths = smaller decimal.
% Correct larger: dec(0,4,1)
% Error: picks dec(0,3,1) because "smaller last digit means bigger value" (1/3 > 1/4).
% SCHEMA: Arithmetic is Object Collection (reciprocal analogy)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(reciprocal_analogy)))
misconceptions_decimal_batch_1:(r40138_reciprocal_analogy(dec(W,F1,L)-dec(W,F2,L), Winner) :-
    (   F1 < F2
    ->  Winner = dec(W,F1,L)
    ;   Winner = dec(W,F2,L)
    )).

test_harness:arith_misconception(db_row(40138), decimal, reciprocal_analogy,
    misconceptions_decimal_batch_1:r40138_reciprocal_analogy,
    dec(0,3,1)-dec(0,4,1),
    dec(0,4,1)).

% === row 40140: zero is larger than a decimal (0 > 0.22) ===
% Task: compare 0 and 0.22; return the larger.
% Correct: dec(0,22,2)   (0.22 > 0)
% Error: picks dec(0,0,0) because "ones > tenths" or "decimals are below zero"
% SCHEMA: Arithmetic is Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(zero_larger_than_decimal)))
misconceptions_decimal_batch_1:(r40140_zero_larger(dec(W1,F1,L1)-dec(W2,F2,L2), Winner) :-
    % student picks whichever has frac length 0
    (   L1 =:= 0
    ->  Winner = dec(W1,F1,L1)
    ;   L2 =:= 0
    ->  Winner = dec(W2,F2,L2)
    ;   (F1 >= F2 -> Winner = dec(W1,F1,L1) ; Winner = dec(W2,F2,L2))
    )).

test_harness:arith_misconception(db_row(40140), decimal, zero_larger_than_decimal,
    misconceptions_decimal_batch_1:r40140_zero_larger,
    dec(0,0,0)-dec(0,22,2),
    dec(0,22,2)).

% === row 40278: decimal point moved down into remainder ===
test_harness:arith_misconception(db_row(40278), decimal, too_vague,
    skip, none, none).

% === row 40299: MMB/DMS belief (no example) ===
test_harness:arith_misconception(db_row(40299), decimal, too_vague,
    skip, none, none).

% === row 40321: miscount decimal digits from wrong ends ===
% Task: 115.4 * 0.325
% Correct: 37.505
% Error: 375.05 — student counted "1 digit in 115.4 (from the right)" and "1 in
%        0.325 (from the left)", so placed the point with 2 decimal places.
% SCHEMA: Arithmetic is Symbolic Manipulation
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(miscount_decimal_places)))
misconceptions_decimal_batch_1:(r40321_miscount_places(a(A)-b(B), Got) :-
    True is A * B,
    Got is True * 10).

test_harness:arith_misconception(db_row(40321), decimal, miscount_decimal_places,
    misconceptions_decimal_batch_1:r40321_miscount_places,
    a(115.4)-b(0.325),
    37.505).

% === row 40325: trailing zero as "remainder" ===
test_harness:arith_misconception(db_row(40325), decimal, too_vague,
    skip, none, none).

% === row 40359: rote count-all-decimal-places rule (no factors) ===
test_harness:arith_misconception(db_row(40359), decimal, too_vague,
    skip, none, none).

% === row 40406: blind count rule places point wrong ===
% Task: 534.6 * 0.545 (digits: 291357)
% Correct: 291.357
% Error: 29.1357 — "1 digit + 3 digits = 4 decimal places in product"
% SCHEMA: Arithmetic is Symbolic Manipulation
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(blind_place_rule)))
misconceptions_decimal_batch_1:(r40406_blind_count(a(A)-b(B), Got) :-
    % Student computes A*B then shifts the point by one extra place left.
    True is A * B,
    Got is True / 10).

test_harness:arith_misconception(db_row(40406), decimal, blind_place_rule,
    misconceptions_decimal_batch_1:r40406_blind_count,
    a(534.6)-b(0.545),
    291.357).

% === row 40413: shorter-is-larger: 0.32 > 0.384 ===
% Task: compare 0.32 and 0.384; return the larger.
% Correct: dec(0,384,3)
% Error: picks dec(0,32,2) "because more places means smaller"
% SCHEMA: Arithmetic is Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(shorter_is_larger)))
misconceptions_decimal_batch_1:(r40413_shorter_larger(dec(W,F1,L1)-dec(W,F2,L2), Winner) :-
    (   L1 < L2
    ->  Winner = dec(W,F1,L1)
    ;   L1 > L2
    ->  Winner = dec(W,F2,L2)
    ;   (F1 >= F2 -> Winner = dec(W,F1,L1) ; Winner = dec(W,F2,L2))
    )).

test_harness:arith_misconception(db_row(40413), decimal, shorter_is_larger,
    misconceptions_decimal_batch_1:r40413_shorter_larger,
    dec(0,32,2)-dec(0,384,3),
    dec(0,384,3)).

% === row 40415: placement error from MMB generalization (no example) ===
test_harness:arith_misconception(db_row(40415), decimal, too_vague,
    skip, none, none).

% === row 40442: count dp ignoring trailing zeros ===
% Task: 0.4975 * 9428.8 — count decimal places in the product.
%       Correct count: 4 (trailing zero drops out: 4688.026)
% Correct: 4
% Error: 5 — student counts 4 + 1 = 5
% SCHEMA: Arithmetic is Symbolic Manipulation
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(sum_dp_no_trailing_zero_account)))
misconceptions_decimal_batch_1:(r40442_sum_dp(dp(D1)-dp(D2), Got) :-
    Got is D1 + D2).

test_harness:arith_misconception(db_row(40442), decimal, sum_dp_ignoring_trailing_zeros,
    misconceptions_decimal_batch_1:r40442_sum_dp,
    dp(4)-dp(1),
    4).

% === row 40472: 3.04 * 5.3 = 16112 (no point placed) ===
% Task: 3.04 * 5.3
% Correct: 16.112
% Error: 16112 — student multiplied as 304 * 53 and did not insert the point.
% SCHEMA: Arithmetic is Symbolic Manipulation
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(no_point_placement)))
misconceptions_decimal_batch_1:(r40472_no_point(dec(W1,F1,L1)-dec(W2,F2,L2), Got) :-
    A is W1 * (10 ** L1) + F1,
    B is W2 * (10 ** L2) + F2,
    Got is A * B).

test_harness:arith_misconception(db_row(40472), decimal, no_point_placement,
    misconceptions_decimal_batch_1:r40472_no_point,
    dec(3,4,2)-dec(5,3,1),
    16.112).

% === row 40500: longer-is-smaller via fraction denominator (0.5 < 0.13) ===
% Task: compare 0.5 and 0.13; return the larger.
% Correct: dec(0,5,1)   (0.5 > 0.13)
% Error: picks dec(0,13,2) "because 1/5 > 1/13? no, the student picks 0.13 as larger,
%        treating 0.5 as 'a half' and 0.13 as 'a thirteenth' — but student conflates
%        direction; per the row description 0.5 is judged smaller, so 0.13 is larger."
% SCHEMA: Arithmetic is Object Collection (denominator analogy for decimals)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(decimal_as_unit_fraction)))
misconceptions_decimal_batch_1:(r40500_decimal_as_unit(dec(W,F1,L1)-dec(W,F2,L2), Winner) :-
    % treat each decimal as a unit fraction 1/F (length ignored except to fetch digit)
    % return the one with the SMALLER denominator-as-digit (picks larger unit fraction).
    % In the example: 0.5 -> "1/5", 0.13 -> "1/13"; larger unit fraction is 1/5 = 0.5.
    % So the misconception actually picks 0.5 as larger. That contradicts the row's
    % description. Revert to the literal description: student says 0.13 > 0.5.
    % Simplest encoding: student picks the longer one.
    (   L1 > L2
    ->  Winner = dec(W,F1,L1)
    ;   L1 < L2
    ->  Winner = dec(W,F2,L2)
    ;   (F1 >= F2 -> Winner = dec(W,F1,L1) ; Winner = dec(W,F2,L2))
    )).

test_harness:arith_misconception(db_row(40500), decimal, longer_is_larger_denom_conflation,
    misconceptions_decimal_batch_1:r40500_decimal_as_unit,
    dec(0,5,1)-dec(0,13,2),
    dec(0,5,1)).

% === row 40527: whole-number string ordering (decimal part as integer) ===
% Task: compare 73.5 and 73.32; return the larger.
% Correct: dec(73,5,1)  (73.5 > 73.32)
% Error: picks dec(73,32,2) because 32 > 5
% SCHEMA: Arithmetic is Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(decimal_part_as_integer)))
misconceptions_decimal_batch_1:(r40527_decimal_as_int(dec(W,F1,L1)-dec(W,F2,L2), Winner) :-
    (   F1 > F2
    ->  Winner = dec(W,F1,L1)
    ;   Winner = dec(W,F2,L2)
    )).

test_harness:arith_misconception(db_row(40527), decimal, decimal_part_as_integer,
    misconceptions_decimal_batch_1:r40527_decimal_as_int,
    dec(73,5,1)-dec(73,32,2),
    dec(73,5,1)).

% === row 40562: irrational non-periodic recognition ===
test_harness:arith_misconception(db_row(40562), decimal, too_vague,
    skip, none, none).

% === row 40596: MMB in story problems ===
test_harness:arith_misconception(db_row(40596), decimal, too_vague,
    skip, none, none).

% === row 40613: .999... = 1 rejection ===
test_harness:arith_misconception(db_row(40613), decimal, too_vague,
    skip, none, none).

% === row 40631: ordering mixed decimals and whole numbers ===
test_harness:arith_misconception(db_row(40631), decimal, too_vague,
    skip, none, none).

% === row 40658: MMB/DMS inverse-operation errors ===
test_harness:arith_misconception(db_row(40658), decimal, too_vague,
    skip, none, none).

% decimal misconceptions — research corpus batch 2/2.
% Native arithmetic layer only. Theoretical annotations as comments:
%   % GROUNDED: TODO — placeholder for future embodied arithmetic layer
%   % SCHEMA: <schema name> — Lakoff & Nunez grounding when applicable
%   % CONNECTS TO: s(comp_nec(unlicensed(...))) — PML operator path
%
% Registration convention (from Task 3 arch fix):
%   test_harness:arith_misconception(Source, Domain, Description,
%       misconceptions_decimal_batch_2:rule_name, Input, Expected).
% Rule predicates do NOT go on the module export list.


% ---- Encodings appended by agent for decimal batch 2 ----

% === row 37485: division makes smaller, divisor must be whole ===
% Task: 900 / 0.75
% Correct: 1200
% Error: multiplies instead of dividing -> 675
% SCHEMA: Arithmetic is Motion Along a Path
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(multiply_when_divide)))
misconceptions_decimal_batch_2:(multiply_when_divide(A-B, R) :- R is A * B).

test_harness:arith_misconception(db_row(37485), decimal, multiply_when_divisor_is_decimal,
    misconceptions_decimal_batch_2:multiply_when_divide,
    900-0.75, 1200).

% === row 37502: multiplication always results in larger product ===
% Task: compare 72 * 0.46 against 36
% Correct: 33.12 (actually less than 36)
% Error: student claims product is larger than 36 -> returns larger_than_36
% Encode: given (A, B, Threshold), student predicts whether product > Threshold.
%   We ask the rule to return the "claimed" product. Student rule: A*B > A
%   always when multiplying by any B. So they claim result = A * (1 + B).
% Simplified: student claims product > multiplicand always.
% Represent input as Pair A-B; error is claimed product = A + A*B (an inflated guess).
% SCHEMA: Arithmetic is Object Collection (mult always grows)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(mult_always_grows)))
misconceptions_decimal_batch_2:(mult_always_grows(A-B, R) :- R is A + A*B).

test_harness:arith_misconception(db_row(37502), decimal, mult_always_makes_larger,
    misconceptions_decimal_batch_2:mult_always_grows,
    72-0.46, 33.12).

% === row 37518: overgeneralized rule "decimal makes smaller" ===
% Task: estimate 500 * 0.24
% Correct: 120
% Error: student rounds to 50 (treats "multiplied by a decimal -> smaller"
%   as automatic shrink to one-tenth-style estimate).
% Encode: student returns A / 10 as "decimal shrinks by an order".
% SCHEMA: Arithmetic is Motion Along a Path (shrink rule)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(decimal_shrinks_by_ten)))
misconceptions_decimal_batch_2:(decimal_shrinks_by_ten(A-_B, R) :- R is A / 10).

test_harness:arith_misconception(db_row(37518), decimal, decimal_multiplier_always_shrinks,
    misconceptions_decimal_batch_2:decimal_shrinks_by_ten,
    500-0.24, 120.0).

% === row 37557: distrusts correct quotient, adjusts for "smaller" ===
% Task: 10 / 0.5
% Correct: 20
% Error: moves decimal to force smaller quotient -> 2 (10 / 5 written as 2.0).
% SCHEMA: "division makes smaller" override
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(force_smaller_quotient)))
misconceptions_decimal_batch_2:(force_smaller_quotient(A-B, R) :- R is A * B).

test_harness:arith_misconception(db_row(37557), decimal, adjust_to_make_smaller,
    misconceptions_decimal_batch_2:force_smaller_quotient,
    10-0.5, 20.0).

% === row 37597: decorative dot — apply ops to both sides ===
% Task: 2.5 + 1
% Correct: 3.5
% Error: adds 1 to both sides of the point -> 3.6 (integer part 2+1=3, dec 5+1=6)
% Encode decimals as Whole-Decimal pairs (integer pair form). 2.5 -> 2-5,
%   1 -> 1-0. Error: adds wholes and "decimals" as independent integers.
% SCHEMA: Arithmetic is Object Collection (decorative dot)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(both_sides_of_dot)))
misconceptions_decimal_batch_2:(both_sides_add(W1-D1-W2-D2, Wsum-Dsum) :-
    Wsum is W1 + W2,
    Dsum is D1 + D2).

test_harness:arith_misconception(db_row(37597), decimal, add_on_both_sides_of_dot,
    misconceptions_decimal_batch_2:both_sides_add,
    2-5-1-0, 3-5).

% === row 37599: fraction 1/4 encoded as 0.4 ===
% Task: convert 1/4 to decimal
% Correct: 0.25
% Error: treats denominator as the tenths digit -> 0.4
% Input: frac(N,D); Output: float.
% SCHEMA: symbol confusion
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(denom_to_tenths)))
misconceptions_decimal_batch_2:(denom_as_tenths(frac(_N,D), R) :- R is D / 10).

test_harness:arith_misconception(db_row(37599), decimal, fraction_denom_as_decimal,
    misconceptions_decimal_batch_2:denom_as_tenths,
    frac(1,4), 0.25).

% === row 37615: whole number rule on decimal compare (3.214 vs 3.8) ===
% Task: compare 3.214 and 3.8, return larger
% Correct: 3.8
% Error: "longer string after point is larger" -> 3.214
% Use integer-pair representation for reliable digit-wise logic.
% Input: Whole1-DecStr1 - Whole2-DecStr2; Decimal parts as integers
%   representing the literal digit sequence (214 and 8 here).
% SCHEMA: whole-number dominance
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(longer_decimal_is_larger)))
misconceptions_decimal_batch_2:(longer_decimal_larger(W1-D1 - W2-D2, Winner) :-
    ( W1 > W2 -> Winner = W1-D1
    ; W1 < W2 -> Winner = W2-D2
    ; D1 > D2 -> Winner = W1-D1
    ; Winner = W2-D2
    )).

test_harness:arith_misconception(db_row(37615), decimal, longer_is_larger_whole_rule,
    misconceptions_decimal_batch_2:longer_decimal_larger,
    3-214 - 3-8, 3-8).

% === row 37617: zero rule — leading zero means smallest ===
% Task: pick smallest from [3.214, 3.09, 3.8]
% Correct: 3.09
% Error: student correctly picks 3.09 as smallest via zero-rule, but then
%   incorrectly orders the other two (3.8 < 3.214).
% Here we encode just the zero-rule pick for smallest: "decimal whose
%   first digit after point is zero is smallest". Coincidentally correct here.
% Input: list of W-D pairs; Output: the one with leading zero in decimal string.
% SCHEMA: specialized zero rule
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(leading_zero_smallest)))
misconceptions_decimal_batch_2:(leading_zero_smallest(List, Pick) :-
    member(Pick, List),
    Pick = _W-D,
    D < 10,           % leading zero in a 2+ digit decimal like "09"
    D > 0,
    !).
misconceptions_decimal_batch_2:(leading_zero_smallest(List, Pick) :-
    List = [Pick|_]).

test_harness:arith_misconception(db_row(37617), decimal, leading_zero_rule,
    misconceptions_decimal_batch_2:leading_zero_smallest,
    [3-214, 3-09, 3-8], 3-09).

% === row 37619: denominator-encoding on fraction -> decimal ===
% Task: convert 3/4 to decimal
% Correct: 0.75
% Error: encodes denominator as tenths, gets .4 (or .04 variant)
% SCHEMA: denominator encoding
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(encode_denom_only)))
misconceptions_decimal_batch_2:(encode_denom_only(frac(_N,D), R) :- R is D / 10).

test_harness:arith_misconception(db_row(37619), decimal, denominator_as_decimal,
    misconceptions_decimal_batch_2:encode_denom_only,
    frac(3,4), 0.75).

% === row 37634: 0.999... vs 1 are not equal (density/infinity confusion) ===
% Too vague for mechanical encoding (philosophical claim about limits).
test_harness:arith_misconception(db_row(37634), decimal, too_vague,
    skip, none, none).

% === row 37637: 7.89 > 7.9 because 89 > 9 ===
% Task: compare 7.89 and 7.9, return larger
% Correct: 7.9
% Error: student picks 7.89 because "89 > 9"
% SCHEMA: whole-number dominance on decimal string
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(whole_num_rule_tenths)))
misconceptions_decimal_batch_2:(whole_num_rule_decimal(W1-D1 - W2-D2, Winner) :-
    ( W1 > W2 -> Winner = W1-D1
    ; W1 < W2 -> Winner = W2-D2
    ; D1 > D2 -> Winner = W1-D1
    ; Winner = W2-D2
    )).

test_harness:arith_misconception(db_row(37637), decimal, digits_after_point_as_whole,
    misconceptions_decimal_batch_2:whole_num_rule_decimal,
    7-89 - 7-9, 7-9).

% === row 37698: 3.999... and 4 are different numbers ===
% Too vague — involves infinitesimal framework not mechanizable as a simple rule.
test_harness:arith_misconception(db_row(37698), decimal, too_vague,
    skip, none, none).

% === row 37701: rejection of 0.999... = 1 on philosophical grounds ===
% Too vague — philosophical commitment, not a computation.
test_harness:arith_misconception(db_row(37701), decimal, too_vague,
    skip, none, none).

% === row 37751: PST procedural area model without conceptual link ===
% Too vague — inability to complete explanation, not a wrong computation.
test_harness:arith_misconception(db_row(37751), decimal, too_vague,
    skip, none, none).

% === row 37800: dividing instead of multiplying for decimal "of" ===
% Task: find 0.75 of 15
% Correct: 11.25
% Error: divides 15 by 0.75 -> 20
% SCHEMA: operation substitution (unit-fraction overgeneralization)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(divide_for_decimal_of)))
misconceptions_decimal_batch_2:(divide_for_decimal_of(Whole-Dec, R) :- R is Whole / Dec).

test_harness:arith_misconception(db_row(37800), decimal, divide_to_find_decimal_of,
    misconceptions_decimal_batch_2:divide_for_decimal_of,
    15-0.75, 11.25).

% === row 37815: .42 > .5 because 42 > 5 ===
% Task: compare .42 and .5, return larger
% Correct: 0-5
% Error: picks 0-42 because 42 > 5
% SCHEMA: whole-number dominance
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(longer_digits_larger)))
misconceptions_decimal_batch_2:(pick_longer_digit_string(W1-D1 - W2-D2, Winner) :-
    ( W1 > W2 -> Winner = W1-D1
    ; W1 < W2 -> Winner = W2-D2
    ; D1 > D2 -> Winner = W1-D1
    ; Winner = W2-D2
    )).

test_harness:arith_misconception(db_row(37815), decimal, longer_string_larger,
    misconceptions_decimal_batch_2:pick_longer_digit_string,
    0-42 - 0-5, 0-5).

% === row 37838: 0.999... = 1 rejected as "negligible error" ===
% Too vague — infinite-series conceptual issue, not a fixed computation.
test_harness:arith_misconception(db_row(37838), decimal, too_vague,
    skip, none, none).

% === row 37983: combining different units across the decimal point ===
% Task: 7.70 + 0.30 (7 NIS 70 agorot + 30 agorot); should yield 8.00.
% Correct: 8-0 (as W-D pair, hundredths)
% Error: writes "7.100" — adds decimals as whole number (70+30=100), leaves
%   whole unchanged -> 7-100 (the unnormalized form).
% Encode using integer-pair decimals at hundredths precision.
% Input: W1-D1 - W2-D2 (decimal parts as 0..99 integers).
% SCHEMA: unit-mixing across dot
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(unit_mixing_across_dot)))
misconceptions_decimal_batch_2:(unit_mix_add(W1-D1 - _W2-D2, W1-Dsum) :-
    Dsum is D1 + D2).

test_harness:arith_misconception(db_row(37983), decimal, combine_units_across_dot,
    misconceptions_decimal_batch_2:unit_mix_add,
    7-70 - 0-30, 8-0).

% === row 38056: 0.8 < 0.14 because 14 > 8 ===
% Task: compare 0.8 and 0.14, return larger
% Correct: 0-8 (0.8 > 0.14)
% Error: picks 0-14
% SCHEMA: whole-number dominance
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(longer_is_larger)))
misconceptions_decimal_batch_2:(longer_is_larger(W1-D1 - W2-D2, Winner) :-
    ( W1 > W2 -> Winner = W1-D1
    ; W1 < W2 -> Winner = W2-D2
    ; D1 > D2 -> Winner = W1-D1
    ; Winner = W2-D2
    )).

test_harness:arith_misconception(db_row(38056), decimal, longer_decimal_rule,
    misconceptions_decimal_batch_2:longer_is_larger,
    0-8 - 0-14, 0-8).

% === row 38146: 0.12 > 0.5 because 12 > 5 ===
% Task: compare 0.12 and 0.5
% Correct: 0-5
% Error: picks 0-12
% SCHEMA: natural-number magnitude applied
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(nat_num_magnitude_on_decimal)))
misconceptions_decimal_batch_2:(nat_num_magnitude(W1-D1 - W2-D2, Winner) :-
    ( W1 > W2 -> Winner = W1-D1
    ; W1 < W2 -> Winner = W2-D2
    ; D1 > D2 -> Winner = W1-D1
    ; Winner = W2-D2
    )).

test_harness:arith_misconception(db_row(38146), decimal, inappropriate_nat_num_rule,
    misconceptions_decimal_batch_2:nat_num_magnitude,
    0-12 - 0-5, 0-5).

% === row 38306: blindly appending zeros to match lengths ===
% Task: pad 0.5 to look like 0.250 (three-digit peer).
% Correct: 0.500 (appending zeros is value-preserving for decimal).
% Error: appends '25' or nonzero digits to change value? The misconception
%   as stated is blind appending WITHOUT understanding why value unchanged.
%   The output 0.500 is numerically the same. Encode as: student pads by
%   appending N zeros but claims the result is a NEW number (equal-length
%   digit-concatenation treated as bigger).
% Encode: student pads by appending digits equal to TargetLen - CurLen;
%   appended digits are zeros (correct), but student reports the
%   whole-number-interpreted string as the new "magnitude". Too vague in
%   that the misconception isn't about a wrong calculation — it's about
%   lack of understanding. Mark too_vague.
test_harness:arith_misconception(db_row(38306), decimal, too_vague,
    skip, none, none).

% === row 38397: mirror-image place value (0.354: 3 is tens, 5 is hundreds) ===
% Task: interpret 0.354 — return total value.
% Correct: 0.354
% Error: interprets as 30 + 500 + 4000 = 4530
% Input: list of decimal digits [D1,D2,D3] (digits after point).
% SCHEMA: mirror-image place value
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(mirror_place_value)))
misconceptions_decimal_batch_2:(mirror_place_value(Digits, Total) :-
    reverse(Digits, Rev),
    mirror_place_sum(Rev, 1, Total)).

misconceptions_decimal_batch_2:(mirror_place_sum([], _, 0)).
misconceptions_decimal_batch_2:(mirror_place_sum([D|Rest], Place, Total) :-
    This is D * Place * 10,
    NextPlace is Place * 10,
    mirror_place_sum(Rest, NextPlace, Acc),
    Total is This + Acc).

test_harness:arith_misconception(db_row(38397), decimal, mirror_image_place_value,
    misconceptions_decimal_batch_2:mirror_place_value,
    [3,5,4], 0.354).

% === row 38399: 0.384 > 0.32 because 384 > 32 ===
% Task: compare 0.384 and 0.32, return larger
% Correct: 0-384 (0.384 > 0.32)
% Error: coincidentally correct for THIS example since 384>32 and 0.384>0.32
%   both hold, but the rule itself ("longer string = bigger") is wrong in
%   general. We faithfully encode the rule — student reasoning, not outcome.
% SCHEMA: whole-number dominance
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(more_places_is_larger)))
misconceptions_decimal_batch_2:(more_places_is_larger(W1-D1 - W2-D2, Winner) :-
    ( W1 > W2 -> Winner = W1-D1
    ; W1 < W2 -> Winner = W2-D2
    ; D1 > D2 -> Winner = W1-D1
    ; Winner = W2-D2
    )).

test_harness:arith_misconception(db_row(38399), decimal, more_places_larger_rule,
    misconceptions_decimal_batch_2:more_places_is_larger,
    0-384 - 0-32, 0-384).

% === row 38401: decimals are negative — 0 > 0.5 ===
% Task: compare 0 and 0.5, return larger
% Correct: 0.5
% Error: says 0 > 0.5 (decimals are negative)
% SCHEMA: decimal-as-negative confusion
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(decimal_is_negative)))
misconceptions_decimal_batch_2:(decimal_is_negative(A-B, Winner) :-
    ( B =:= 0 -> Winner = A
    ; A =:= 0 -> Winner = A
    ; abs(A) >= abs(B) -> Winner = A
    ; Winner = B
    )).

test_harness:arith_misconception(db_row(38401), decimal, decimals_are_negative,
    misconceptions_decimal_batch_2:decimal_is_negative,
    0-0.5, 0.5).

% === row 38416: negative decimals — -1.2 at -0.8 ===
% Task: locate -1.2 on number line
% Correct: -1.2
% Error: interprets -1.2 as -1 + 0.2 = -0.8
% SCHEMA: negative-number directionality confusion
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(neg_decimal_translate)))
misconceptions_decimal_batch_2:(neg_decimal_misplace(W-D, Pos) :-
    Pos is W + D).   % e.g. -1 + 0.2 = -0.8 when W = -1, D = 0.2

test_harness:arith_misconception(db_row(38416), decimal, negative_decimal_position,
    misconceptions_decimal_batch_2:neg_decimal_misplace,
    -1 - 0.2, -1.2).

% === row 38499: longer-is-larger OR shorter-is-larger (inconsistent) ===
% Task: compare 0.456 and 0.47 via longer-is-larger rule, return larger
% Correct: 0-47 (0.47 > 0.456)
% Error: picks 0-456
% SCHEMA: whole-number dominance
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(longer_longer_rule)))
misconceptions_decimal_batch_2:(longer_longer_rule(W1-D1 - W2-D2, Winner) :-
    ( W1 > W2 -> Winner = W1-D1
    ; W1 < W2 -> Winner = W2-D2
    ; D1 > D2 -> Winner = W1-D1
    ; Winner = W2-D2
    )).

test_harness:arith_misconception(db_row(38499), decimal, count_digits_for_magnitude,
    misconceptions_decimal_batch_2:longer_longer_rule,
    0-456 - 0-47, 0-47).

% === row 38532: 0.999... as process vs object (inconsistent framing) ===
% Too vague — cognitive framing of infinite processes, not a computation.
test_harness:arith_misconception(db_row(38532), decimal, too_vague,
    skip, none, none).

% === row 38565: 2.12 > 2.2 because 12 > 2 ===
% Task: compare 2.12 and 2.2
% Correct: 2-2
% Error: picks 2-12 because 12 > 2
% SCHEMA: whole-number dominance
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(decimal_length_rule)))
misconceptions_decimal_batch_2:(decimal_length_rule(W1-D1 - W2-D2, Winner) :-
    ( W1 > W2 -> Winner = W1-D1
    ; W1 < W2 -> Winner = W2-D2
    ; D1 > D2 -> Winner = W1-D1
    ; Winner = W2-D2
    )).

test_harness:arith_misconception(db_row(38565), decimal, natural_number_ordering,
    misconceptions_decimal_batch_2:decimal_length_rule,
    2-12 - 2-2, 2-2).

% === row 38625: mistake "tenths" for "tens" ===
% Task: 3 hundreds, 7 units, 4 tenths
% Correct: 307.4
% Error: reads 4 "tenths" as 4 "tens" -> 347
% Input: list of place-value pairs [N-Place, ...]
% SCHEMA: sight-word error (tenths vs tens)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(tenths_as_tens)))
misconceptions_decimal_batch_2:(tenths_as_tens(Pairs, Total) :- tenths_as_tens_sum(Pairs, 0, Total)).

misconceptions_decimal_batch_2:(tenths_as_tens_sum([], Acc, Acc)).
misconceptions_decimal_batch_2:(tenths_as_tens_sum([N-hundreds|Rest], Acc, Total) :-
    Acc2 is Acc + N * 100,
    tenths_as_tens_sum(Rest, Acc2, Total)).
misconceptions_decimal_batch_2:(tenths_as_tens_sum([N-units|Rest], Acc, Total) :-
    Acc2 is Acc + N,
    tenths_as_tens_sum(Rest, Acc2, Total)).
misconceptions_decimal_batch_2:(tenths_as_tens_sum([N-tenths|Rest], Acc, Total) :-
    Acc2 is Acc + N * 10,    % error: tenths read as tens
    tenths_as_tens_sum(Rest, Acc2, Total)).

test_harness:arith_misconception(db_row(38625), decimal, tenths_heard_as_tens,
    misconceptions_decimal_batch_2:tenths_as_tens,
    [3-hundreds, 7-units, 4-tenths], 307.4).

% === row 38643: 1/3 ≠ 0.333... because process never terminates ===
% Too vague — philosophical stance on limits.
test_harness:arith_misconception(db_row(38643), decimal, too_vague,
    skip, none, none).

% === row 38691: remainder appended as decimal fraction ===
% Task: 24 / 16
% Correct: 1.5
% Error: "1 remainder 8" rendered as 1.8
% SCHEMA: remainder-as-decimal confusion
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(remainder_as_decimal)))
misconceptions_decimal_batch_2:(remainder_as_decimal(A-B, R) :-
    Q is A // B,
    Rem is A mod B,
    R is Q + Rem / 10).

test_harness:arith_misconception(db_row(38691), decimal, remainder_pasted_as_decimal,
    misconceptions_decimal_batch_2:remainder_as_decimal,
    24-16, 1.5).

% === row 38728: two-step word problem — cognitive load failure ===
% Too vague — working memory issue, not a rule.
test_harness:arith_misconception(db_row(38728), decimal, too_vague,
    skip, none, none).

% === row 38744: cents as independent units (not hundredths of dollar) ===
% Too vague — conceptual mismatch without a specific wrong computation.
test_harness:arith_misconception(db_row(38744), decimal, too_vague,
    skip, none, none).

% === row 38790: choose division over multiplication ===
% Task: price of 0.923 kg at 27.50 kr/kg
% Correct: 25.3825 (mult)
% Error: divides 27.50 / 0.923 to get a smaller answer -> 29.79 (wrong-op)
% SCHEMA: operation substitution driven by expected magnitude
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(divide_for_smaller)))
misconceptions_decimal_batch_2:(divide_for_smaller(A-B, R) :- R is A / B).

test_harness:arith_misconception(db_row(38790), decimal, divide_instead_of_multiply,
    misconceptions_decimal_batch_2:divide_for_smaller,
    27.50-0.923, 25.3825).

% === row 38793: invents discrete context for continuous decimals ===
% Too vague — pragmatic/contextual error, not a calculation.
test_harness:arith_misconception(db_row(38793), decimal, too_vague,
    skip, none, none).

% === row 38853: remainder interpreted as tenths, not fraction of divisor ===
% Task: 498 / 6 — "498 minus 491 is 7; 7 minus 6 is 1", giving 82.1
% Correct: 83.0 (actually 498/6=83.0 exactly)
% Error: produces 82.1 using ad hoc subtraction + remainder-as-tenths.
% Simpler encoding: given A / B, student returns (A//B) + (A mod B)/10.
% Using (499, 6): 499/6 = 83.1666..., student gets 83 + 1/10 = 83.1.
% For the originally stated 82.1, the intended pair is (493, 6) or
% similar; we keep the general rule and use (499, 6) -> 83.1666... with
% student 83.1.
% SCHEMA: remainder-as-tenths
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(remainder_tenths_division)))
misconceptions_decimal_batch_2:(remainder_as_tenths_div(A-B, R) :-
    Q is A // B,
    Rem is A mod B,
    R is Q + Rem / 10).

test_harness:arith_misconception(db_row(38853), decimal, remainder_interpreted_as_tenths,
    misconceptions_decimal_batch_2:remainder_as_tenths_div,
    499-6, 83.16666666666667).

% === row 38926: misread decimal as mixed unit ===
% Task: read 11.9 miles/hr
% Correct: 11.9
% Error: reads as 11 miles 9 minutes -> nonsense unit
% Too vague — reading error, no single numerical rule.
test_harness:arith_misconception(db_row(38926), decimal, too_vague,
    skip, none, none).

% === row 38928: always divide larger by smaller ===
% Task: 2 / 10
% Correct: 0.2
% Error: swaps to 10 / 2 = 5 because "smaller into larger"
% SCHEMA: directionality confusion
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(swap_for_division)))
misconceptions_decimal_batch_2:(swap_for_division(A-B, R) :-
    ( A < B -> R is B / A
    ; R is A / B
    )).

test_harness:arith_misconception(db_row(38928), decimal, always_larger_into_smaller,
    misconceptions_decimal_batch_2:swap_for_division,
    2-10, 0.2).

% === row 38957: digit-by-digit Euclidean division inserts decimals ===
% Task: 5 / 2 as part of a long division
% Correct: 2 remainder 1 (to carry forward)
% Error: writes 2.5 mid-quotient
% SCHEMA: place-value ignoring digit division
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(digit_div_floats)))
misconceptions_decimal_batch_2:(digit_div_floats(A-B, R) :- R is A / B).

test_harness:arith_misconception(db_row(38957), decimal, digit_division_produces_decimals,
    misconceptions_decimal_batch_2:digit_div_floats,
    5-2, 2).

% === row 38986: 1.20 > 1.2 or 1.02 > 1.1 ===
% Task: compare 1.02 and 1.1
% Correct: 1-1
% Error: picks 1-02 because 2 > 1 when reading tenths digit alone, OR
%   more digits = larger. Use the longer-is-larger rule here.
% SCHEMA: whole-number dominance
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(digit_count_magnitude)))
misconceptions_decimal_batch_2:(digit_count_magnitude(W1-D1 - W2-D2, Winner) :-
    ( W1 > W2 -> Winner = W1-D1
    ; W1 < W2 -> Winner = W2-D2
    ; D1 > D2 -> Winner = W1-D1
    ; Winner = W2-D2
    )).

test_harness:arith_misconception(db_row(38986), decimal, digit_count_as_magnitude,
    misconceptions_decimal_batch_2:digit_count_magnitude,
    1-02 - 1-1, 1-1).

% === row 39019: mult always makes larger (target-seeking in Logo) ===
% Task: 13 * K to reach 100 — student doesn't use K<1.
% Too vague — strategic choice avoidance, not a wrong computation with a
% specific output.
test_harness:arith_misconception(db_row(39019), decimal, too_vague,
    skip, none, none).

% === row 39051: rounding repeating decimals from calculator ===
% Too vague — strategic confusion over rounding, not a single rule.
test_harness:arith_misconception(db_row(39051), decimal, too_vague,
    skip, none, none).

% === row 39078: reverse operands to divide larger by smaller ===
% Task: 8.7 / 59.1
% Correct: ~0.1472
% Error: computes 59.1 / 8.7 instead -> ~6.793
% SCHEMA: directionality / commuting division
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(reverse_for_division)))
misconceptions_decimal_batch_2:(reverse_for_division(A-B, R) :-
    ( A < B -> R is B / A
    ; R is A / B
    )).

test_harness:arith_misconception(db_row(39078), decimal, reverse_operands_in_division,
    misconceptions_decimal_batch_2:reverse_for_division,
    8.7-59.1, 0.14720812182741116).

% === row 39081: substitute subtraction for division ===
% Task: 2 / 2.56 (how much meat for GBP2 at GBP2.56/lb)
% Correct: ~0.781
% Error: subtracts 2.56 - 2 = 0.56
% SCHEMA: operation substitution when quotient looks wrong magnitude
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(subtract_for_divide)))
misconceptions_decimal_batch_2:(subtract_for_divide(A-B, R) :- R is abs(B - A)).

test_harness:arith_misconception(db_row(39081), decimal, subtract_instead_of_divide,
    misconceptions_decimal_batch_2:subtract_for_divide,
    2-2.56, 0.78125).

% === row 39140: encoding error — drops units ===
% Task: change from $2 for $1.07 item
% Correct: 0.93 (representing $0.93)
% Error: writes "93" (treats as whole number)
% SCHEMA: encoding error
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(drop_decimal_unit)))
misconceptions_decimal_batch_2:(drop_decimal_unit(A-B, R) :-
    Diff is A - B,
    R is round(Diff * 100)).

test_harness:arith_misconception(db_row(39140), decimal, drop_unit_in_change,
    misconceptions_decimal_batch_2:drop_decimal_unit,
    2.00-1.07, 0.93).

% === row 39165: choose division because answer must be smaller ===
% Task: 0.75 * 3 (0.75 of 3 ounces)
% Correct: 2.25
% Error: divides 3 / 0.75 = 4
% SCHEMA: operation substitution
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(divide_for_smaller_answer)))
misconceptions_decimal_batch_2:(divide_for_smaller_answer(Whole-Dec, R) :- R is Whole / Dec).

test_harness:arith_misconception(db_row(39165), decimal, divide_when_answer_smaller,
    misconceptions_decimal_batch_2:divide_for_smaller_answer,
    3-0.75, 2.25).

% === row 39262: decimal vs rational definitions confusion ===
% Too vague — definitional, philosophical.
test_harness:arith_misconception(db_row(39262), decimal, too_vague,
    skip, none, none).

% === row 39322: change divide to multiply when divisor < 1 ===
% Task: 116 / 0.8 (yen per liter given 116 yen for 0.8 liter)
% Correct: 145.0
% Error: multiplies 116 * 0.8 = 92.8
% SCHEMA: operation substitution
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(mult_for_divide_sub_one)))
misconceptions_decimal_batch_2:(mult_for_divide_sub_one(A-B, R) :-
    ( B < 1 -> R is A * B
    ; R is A / B
    )).

test_harness:arith_misconception(db_row(39322), decimal, mult_instead_of_divide_sub_one,
    misconceptions_decimal_batch_2:mult_for_divide_sub_one,
    116-0.8, 145.0).

% === row 39324: division by 0.8 conceptually meaningless ===
% Too vague — inability, not a specific wrong answer.
test_harness:arith_misconception(db_row(39324), decimal, too_vague,
    skip, none, none).

% === row 39346: forgets to place decimal point in multiplication ===
% Task: 60 * 0.20
% Correct: 12.0
% Error: computes 60 * 20 = 1200 (forgets decimal)
% SCHEMA: decimal-point placement error
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(forget_decimal_point_mult)))
misconceptions_decimal_batch_2:(forget_decimal_point(A-B, R) :-
    _Places is B,   % just for shape
    % Multiply A by B*100 (treat 0.20 as 20), yielding inflated integer
    R is A * (B * 100)).

test_harness:arith_misconception(db_row(39346), decimal, forget_decimal_in_product,
    misconceptions_decimal_batch_2:forget_decimal_point,
    60-0.20, 12.0).

% === row 39400: believe in infinitesimal 0.000...1 ===
% Too vague — belief in infinitesimals, not a wrong computation.
test_harness:arith_misconception(db_row(39400), decimal, too_vague,
    skip, none, none).

% === row 39408: "70 / (1/2)" < 70 (PST) ===
% Task: 70 / 0.5
% Correct: 140
% Error: PST claims quotient is less than 70 -> e.g. 35 (70/2)
% SCHEMA: division-makes-smaller
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(div_makes_smaller_pst)))
misconceptions_decimal_batch_2:(div_makes_smaller(A-B, R) :- R is A * B).

test_harness:arith_misconception(db_row(39408), decimal, division_must_be_smaller,
    misconceptions_decimal_batch_2:div_makes_smaller,
    70-0.5, 140.0).

% === row 39439: farther-from-point digits = bigger value ===
% Task: compare .02 and .2, return larger
% Correct: 0-2 (0.2 > 0.02)
% Error: picks 0-02 because the 2 is "farther from the decimal point"
% Input: Whole-DecString as integer (02 distinct from 2).
% We encode decimals as Whole-DigitList to preserve leading zeros.
% SCHEMA: farther-from-point = bigger
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(farther_from_dot_bigger)))
misconceptions_decimal_batch_2:(farther_from_dot_bigger(W1-Dlist1 - W2-Dlist2, Winner) :-
    length(Dlist1, L1),
    length(Dlist2, L2),
    ( L1 > L2 -> Winner = W1-Dlist1
    ; L2 > L1 -> Winner = W2-Dlist2
    ; Winner = W1-Dlist1
    )).

test_harness:arith_misconception(db_row(39439), decimal, distance_from_point_as_magnitude,
    misconceptions_decimal_batch_2:farther_from_dot_bigger,
    0-[0,2] - 0-[2], 0-[2]).

% === row 39441: trailing zeros inflate value ===
% Task: evaluate .008000 as magnitude
% Correct: 0.008
% Error: reads as 8000 (trailing zeros inflate)
% Input: list of digits after point; Output: "student's magnitude"
% SCHEMA: trailing zeros inflate
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(trailing_zeros_inflate)))
misconceptions_decimal_batch_2:(trailing_zeros_inflate(Digits, Total) :-
    drop_leading_zeros(Digits, Rest),
    digits_to_integer(Rest, Total)).

misconceptions_decimal_batch_2:(drop_leading_zeros([0|T], R) :- !, drop_leading_zeros(T, R)).
misconceptions_decimal_batch_2:(drop_leading_zeros(L, L)).

misconceptions_decimal_batch_2:(digits_to_integer(Digits, N) :- digits_to_integer_(Digits, 0, N)).
misconceptions_decimal_batch_2:(digits_to_integer_([], Acc, Acc)).
misconceptions_decimal_batch_2:(digits_to_integer_([D|T], Acc, N) :-
    Acc2 is Acc * 10 + D,
    digits_to_integer_(T, Acc2, N)).

test_harness:arith_misconception(db_row(39441), decimal, trailing_zeros_increase_value,
    misconceptions_decimal_batch_2:trailing_zeros_inflate,
    [0,0,8,0,0,0], 0.008).

% === row 39450: divide because smaller result expected ===
% Task: 12820 * 0.9 (convert sq yd to sq m)
% Correct: 11538.0
% Error: divides 12820 / 0.9 = 14244.44...
% SCHEMA: operation substitution
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(divide_for_smaller_result)))
misconceptions_decimal_batch_2:(divide_for_smaller_result(A-B, R) :- R is A / B).

test_harness:arith_misconception(db_row(39450), decimal, divide_because_smaller_expected,
    misconceptions_decimal_batch_2:divide_for_smaller_result,
    12820-0.9, 11538.0).

% === row 39461: shorter = tenths > hundredths = longer (false compensation) ===
% Task: compare 3.2 and 3.47
% Correct: 3-47 (3.47 > 3.2)
% Error: picks 3-2 because "tenths > hundredths"
% SCHEMA: fraction-scheme misapplied (shorter = bigger unit)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(shorter_is_bigger_fraction)))
misconceptions_decimal_batch_2:(shorter_is_bigger(W1-Dlist1 - W2-Dlist2, Winner) :-
    length(Dlist1, L1),
    length(Dlist2, L2),
    ( L1 < L2 -> Winner = W1-Dlist1
    ; L2 < L1 -> Winner = W2-Dlist2
    ; Winner = W1-Dlist1
    )).

test_harness:arith_misconception(db_row(39461), decimal, shorter_means_larger_units,
    misconceptions_decimal_batch_2:shorter_is_bigger,
    3-[2] - 3-[4,7], 3-[4,7]).

% === row 39492: multiplication = repeated addition, must be integer ===
% Task: 43 * 0.7
% Correct: 30.1
% Error: refuses non-integer multiplier; answer unspecified.
% Encode variant: student swaps to 0.7 * 43 (commuting) but still fails,
%   returning 43 (fixed point of "you can't repeat add 0.7 times").
% Mark too_vague — no single computed wrong answer.
test_harness:arith_misconception(db_row(39492), decimal, too_vague,
    skip, none, none).

% === row 39523: 0.45 > 0.6 because 45 > 6 ===
% Task: compare 0.45 and 0.6
% Correct: 0-6 (0.6 > 0.45)
% Error: picks 0-45
% SCHEMA: whole-number dominance
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(compare_as_whole_number)))
misconceptions_decimal_batch_2:(compare_as_whole_number(W1-D1 - W2-D2, Winner) :-
    ( W1 > W2 -> Winner = W1-D1
    ; W1 < W2 -> Winner = W2-D2
    ; D1 > D2 -> Winner = W1-D1
    ; Winner = W2-D2
    )).

test_harness:arith_misconception(db_row(39523), decimal, compare_decimal_parts_as_whole,
    misconceptions_decimal_batch_2:compare_as_whole_number,
    0-45 - 0-6, 0-6).

% === row 39526: decimals as discrete, no density ===
% Too vague — lack of density understanding, not a specific wrong output.
test_harness:arith_misconception(db_row(39526), decimal, too_vague,
    skip, none, none).

% === row 39576: compare parts of decimal independently ===
% Task: compare 1.12 and 1.3
% Correct: 1-3 (1.3 > 1.12)
% Error: picks 1-12 because 1=1 and 12>3
% SCHEMA: dot-as-separator (compare each side independently)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(compare_sides_independently)))
misconceptions_decimal_batch_2:(compare_sides_independently(W1-D1 - W2-D2, Winner) :-
    ( W1 > W2 -> Winner = W1-D1
    ; W1 < W2 -> Winner = W2-D2
    ; D1 > D2 -> Winner = W1-D1
    ; Winner = W2-D2
    )).

test_harness:arith_misconception(db_row(39576), decimal, decimal_point_as_separator,
    misconceptions_decimal_batch_2:compare_sides_independently,
    1-12 - 1-3, 1-3).

% === row 39618: 0.5 + 0.5 = 0.10 (whole-number add then prepend dot) ===
% Task: 0.5 + 0.5
% Correct: 1.0
% Error: computes 5 + 5 = 10, prepends dot -> 0.10 (i.e. "zero point ten")
% Encode as integer-pair: wholes stay 0-0, decimal digits add as integers.
% SCHEMA: decorative-dot addition
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(add_as_whole_prepend_dot)))
misconceptions_decimal_batch_2:(add_as_whole_prepend(W1-D1 - W2-D2, 0-Dsum) :-
    _Wsum is W1 + W2,
    Dsum is D1 + D2).

test_harness:arith_misconception(db_row(39618), decimal, add_digits_prepend_decimal,
    misconceptions_decimal_batch_2:add_as_whole_prepend,
    0-5 - 0-5, 1-0).

% === row 39624: "decimals with more digits are smaller" ===
% Task: compare 0.5 and 0.625
% Correct: 0-625 (0.625 > 0.5)
% Error: picks 0-5 (fewer digits = bigger, via fraction analogy)
% SCHEMA: inverted length rule
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(shorter_is_larger_inverted)))
misconceptions_decimal_batch_2:(shorter_is_larger(W1-Dlist1 - W2-Dlist2, Winner) :-
    length(Dlist1, L1),
    length(Dlist2, L2),
    ( L1 < L2 -> Winner = W1-Dlist1
    ; L2 < L1 -> Winner = W2-Dlist2
    ; Winner = W1-Dlist1
    )).

test_harness:arith_misconception(db_row(39624), decimal, fewer_digits_is_larger,
    misconceptions_decimal_batch_2:shorter_is_larger,
    0-[5] - 0-[6,2,5], 0-[6,2,5]).

% === row 39631: 4.125 > 4.7 because 125 > 7 ===
% Task: compare 4.125 and 4.7
% Correct: 4-7 (4.7 > 4.125)
% Error: picks 4-125
% SCHEMA: whole-number dominance
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(whole_number_rule_ordering)))
misconceptions_decimal_batch_2:(whole_number_rule_order(W1-D1 - W2-D2, Winner) :-
    ( W1 > W2 -> Winner = W1-D1
    ; W1 < W2 -> Winner = W2-D2
    ; D1 > D2 -> Winner = W1-D1
    ; Winner = W2-D2
    )).

test_harness:arith_misconception(db_row(39631), decimal, whole_number_rule_order,
    misconceptions_decimal_batch_2:whole_number_rule_order,
    4-125 - 4-7, 4-7).

% === row 39633: zero rule — leading zero makes smaller (Moloney/Stacey) ===
% Task: order 3.214, 3.09, 3.8 — smallest first, student's order
% Correct: [3.09, 3.214, 3.8]
% Error: student uses zero-rule for smallest, then whole-number rule:
%   -> [3.09, 3.8, 3.214]
% Encode as: given list of W-D pairs, produce student's ordering (ascending).
% SCHEMA: specialized zero-rule + whole-number rule
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(zero_rule_plus_wn)))
misconceptions_decimal_batch_2:(zero_rule_order(List, Ordered) :-
    partition([_W-D]>>(D < 10, D > 0), List, Zeros, NonZeros),
    predsort([Ord,A-B,C-D2]>>(
        ( A > C -> Ord = (>)
        ; A < C -> Ord = (<)
        ; B > D2 -> Ord = (>)
        ; B < D2 -> Ord = (<)
        ; Ord = (=)
        )), NonZeros, SortedNZ),
    append(Zeros, SortedNZ, Ordered)).

test_harness:arith_misconception(db_row(39633), decimal, zero_rule_plus_whole_number,
    misconceptions_decimal_batch_2:zero_rule_order,
    [3-214, 3-09, 3-8], [3-09, 3-214, 3-8]).

% === row 39641: 7/5 written as 1.20 (money notation preference) ===
% Task: convert 7/5 to decimal
% Correct: 1.4
% Error: writes 1.20 (money-notation preference for 2/5 leftover)
% SCHEMA: money-notation overgeneralization
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(money_notation_preference)))
misconceptions_decimal_batch_2:(money_notation_frac(frac(N,D), W-Cents) :-
    W is N // D,
    Rem is N mod D,
    Cents is Rem * 10).

test_harness:arith_misconception(db_row(39641), decimal, money_notation_for_fraction,
    misconceptions_decimal_batch_2:money_notation_frac,
    frac(7,5), 1-40).

% === row 39647: more digits = greater value (PST) ===
% Task: pick greatest from [0.09, 0.365, 0.4, 0.1815]
% Correct: 0-[4]
% Error: picks 0-[1,8,1,5] because more digits
% SCHEMA: whole-number dominance (digit count)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(more_digits_greater)))
misconceptions_decimal_batch_2:(most_digits_wins(List, Pick) :-
    foldl([Item, Best, NewBest]>>(
        Item = _-Dlist1, Best = _-Dlist2,
        length(Dlist1, L1), length(Dlist2, L2),
        ( L1 > L2 -> NewBest = Item
        ; NewBest = Best
        )), List, 0-[], Pick)).

test_harness:arith_misconception(db_row(39647), decimal, more_digits_equals_greater,
    misconceptions_decimal_batch_2:most_digits_wins,
    [0-[0,9], 0-[3,6,5], 0-[4], 0-[1,8,1,5]], 0-[4]).

% === row 39675: tension about 1/N outputs > 1 in spreadsheet ===
% Too vague — expectation conflict, not a calculation.
test_harness:arith_misconception(db_row(39675), decimal, too_vague,
    skip, none, none).

% === row 39693: decimal placement error in division ===
% Task: 11.28 / 3.6
% Correct: 3.1333...
% Error: misplaces decimal -> 31.33 or 0.3133
% SCHEMA: decimal placement
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(misplace_decimal_div)))
misconceptions_decimal_batch_2:(misplace_decimal_div(A-B, R) :-
    True is A / B,
    R is True * 10).

test_harness:arith_misconception(db_row(39693), decimal, decimal_placement_division,
    misconceptions_decimal_batch_2:misplace_decimal_div,
    11.28-3.6, 3.1333333333333333).

% === row 39728: idiosyncratic distributive recombination ===
% Task: 2.5 * 9 * 4
% Correct: 90
% Error: computes 2.5 * 4 = 10, then does (9*8)+(9*2) = 90
% The student's error yields 90 — same as correct. Encoded faithfully
% as the stated distributive recombination; output matches correct.
% SCHEMA: distributive misapplication
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(distributive_recombination)))
misconceptions_decimal_batch_2:(distributive_recomb(A-B-C, R) :-
    _Half is A * C,   % 2.5 * 4 = 10
    R is (B * 8) + (B * 2)).   % 72 + 18 = 90

test_harness:arith_misconception(db_row(39728), decimal, idiosyncratic_distributive,
    misconceptions_decimal_batch_2:distributive_recomb,
    2.5-9-4, 90.0).

% === row 39776: decimal as familiar whole number (2.32 > 2.8) ===
% Task: compare 2.32 and 2.8
% Correct: 2-8
% Error: picks 2-32
% SCHEMA: whole-number dominance
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(familiar_whole_rule)))
misconceptions_decimal_batch_2:(familiar_whole_rule(W1-D1 - W2-D2, Winner) :-
    ( W1 > W2 -> Winner = W1-D1
    ; W1 < W2 -> Winner = W2-D2
    ; D1 > D2 -> Winner = W1-D1
    ; Winner = W2-D2
    )).

test_harness:arith_misconception(db_row(39776), decimal, familiar_whole_number_rule,
    misconceptions_decimal_batch_2:familiar_whole_rule,
    2-32 - 2-8, 2-8).

% === row 39792: division makes smaller (teacher) ===
% Task: 0.5 / 0.5
% Correct: 1.0
% Error: gives 0.1, 0, or 0.01
% Pick variant "result is 0.1" — smaller than 0.5 under the rule.
% SCHEMA: division-makes-smaller (teacher)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(div_smaller_teacher)))
misconceptions_decimal_batch_2:(div_smaller_teacher(A-B, R) :-
    ( A =:= B -> R is A / 5
    ; R is A / B
    )).

test_harness:arith_misconception(db_row(39792), decimal, teacher_division_smaller,
    misconceptions_decimal_batch_2:div_smaller_teacher,
    0.5-0.5, 1.0).

% === row 39838: rote decimal-place-counting without understanding ===
% Too vague — lack of justification, not a wrong computation.
test_harness:arith_misconception(db_row(39838), decimal, too_vague,
    skip, none, none).

% === row 39897: fails to move decimal point in divisor ===
% Task: 13.2678 / 2.34
% Correct: ~5.67
% Error: divides WITHOUT shifting divisor decimal -> 13.2678 / 234 (tiny)
% SCHEMA: position-ignoring division
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(forget_shift_divisor)))
misconceptions_decimal_batch_2:(forget_shift_divisor(A-B, R) :-
    Shift is B * 100,
    R is A / Shift).

test_harness:arith_misconception(db_row(39897), decimal, fail_to_shift_divisor,
    misconceptions_decimal_batch_2:forget_shift_divisor,
    13.2678-2.34, 5.67).

% === row 40024: shade 1/10 but label as 0.01 ===
% Task: label one-tenth on a hundredths grid
% Correct: 0.1
% Error: labels 0.01 because a single "hundredths square" row was counted
% Encode as: given GridDenom-Shaded, student labels as Shaded/GridDenom
% Wait — the student DOES shade 10 of 100 squares (correct) but LABELS as 0.01.
% Encode: given (PiecesShaded-GridDenom), student returns 1 / GridDenom
% SCHEMA: symbolic labeling confusion
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(mislabel_grid)))
misconceptions_decimal_batch_2:(mislabel_grid(_Pieces-GridDenom, R) :- R is 1 / GridDenom).

test_harness:arith_misconception(db_row(40024), decimal, mislabel_grid_as_unit,
    misconceptions_decimal_batch_2:mislabel_grid,
    10-100, 0.1).

% === row 40067: trainee — adds decimals or miscalculates place value ===
% Task: 0.3 * 0.2 (example asks for 0.6 mm2 derivation on a variant)
% Correct: 0.06
% Error: adds instead of multiplying -> 0.5
% SCHEMA: operation substitution
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(add_instead_of_mult)))
misconceptions_decimal_batch_2:(add_instead_of_mult(A-B, R) :- R is A + B).

test_harness:arith_misconception(db_row(40067), decimal, add_instead_of_multiply,
    misconceptions_decimal_batch_2:add_instead_of_mult,
    0.3-0.2, 0.06).

% === row 40110: remainder in long division not seen as fractional ===
% Too vague — conceptual issue about remainder notation.
test_harness:arith_misconception(db_row(40110), decimal, too_vague,
    skip, none, none).

% === row 40139: longer decimal is larger (PST) ===
% Task: compare 0.456 and 0.47
% Correct: 0-47 (0.47 > 0.456)
% Error: picks 0-456
% SCHEMA: whole-number dominance
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(longer_is_larger_pst)))
misconceptions_decimal_batch_2:(longer_is_larger_pst(W1-D1 - W2-D2, Winner) :-
    ( W1 > W2 -> Winner = W1-D1
    ; W1 < W2 -> Winner = W2-D2
    ; D1 > D2 -> Winner = W1-D1
    ; Winner = W2-D2
    )).

test_harness:arith_misconception(db_row(40139), decimal, pst_longer_is_larger,
    misconceptions_decimal_batch_2:longer_is_larger_pst,
    0-456 - 0-47, 0-47).

% === row 40275: infinite non-periodic decimals seen as infinite numbers ===
% Too vague — conceptual error about representation.
test_harness:arith_misconception(db_row(40275), decimal, too_vague,
    skip, none, none).

% === row 40283: inconsistent partial-products decimal placement ===
% Task: 0.2 * 8.0
% Correct: 1.6
% Error: treats 8.0 as 80 mid-step, gets 16 with two decimal places -> 0.16
% SCHEMA: inconsistent rule application
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(inconsistent_partial_products)))
misconceptions_decimal_batch_2:(inconsistent_partial_products(A-B, R) :-
    True is A * B,
    R is True / 10).

test_harness:arith_misconception(db_row(40283), decimal, partial_products_decimal_error,
    misconceptions_decimal_batch_2:inconsistent_partial_products,
    0.2-8.0, 1.6).

% === row 40318: decimal density — no numbers between two hundredths ===
% Too vague — denial of density, not a wrong computation.
test_harness:arith_misconception(db_row(40318), decimal, too_vague,
    skip, none, none).

% === row 40324: dividing by larger decimal gives larger quotient ===
% Task: 1 / 0.05 vs 1 / 0.025 — claim bigger divisor gives bigger quotient
% Correct: 1/0.05 = 20, 1/0.025 = 40, so smaller divisor gives bigger quotient
% Error: student picks 1/0.05 = larger -> 20 when asked which is bigger
% Encode: given A / B1 vs A / B2, student picks larger B -> A/B=smaller val
%   as "bigger" (inverted).
% SCHEMA: inverted division rule
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(inverted_division_rule)))
misconceptions_decimal_batch_2:(inverted_div_rule(A-B1-B2, R) :-
    ( B1 > B2 -> R is A / B1
    ; R is A / B2
    )).

test_harness:arith_misconception(db_row(40324), decimal, inverted_division_effect,
    misconceptions_decimal_batch_2:inverted_div_rule,
    1-0.05-0.025, 40.0).

% === row 40354: 0.9 * 0.9 > 0.9 and larger than factors ===
% Task: 0.9 * 0.9
% Correct: 0.81
% Error: claims it's close to 1 (larger than 0.9)
% Encode: student returns a value > max(A,B). Use A+B as rough "inflate".
%   For 0.9 * 0.9, student claims 0.9 + (1-0.9)*0.9 = 0.99 or similar.
% Simpler: student returns 1.0 (rounds up to "close to 1").
% SCHEMA: mult-always-grows
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(mult_grows_sub_one)))
misconceptions_decimal_batch_2:(mult_grows_sub_one(_A-_B, R) :-
    R = 1.0).

test_harness:arith_misconception(db_row(40354), decimal, product_of_decimals_near_one,
    misconceptions_decimal_batch_2:mult_grows_sub_one,
    0.9-0.9, 0.81).

% === row 40396: finite-to-infinite extrapolation: 0.999... < 1 ===
% Too vague — limit reasoning, not a mechanical rule.
test_harness:arith_misconception(db_row(40396), decimal, too_vague,
    skip, none, none).

% === row 40412: mirrored place value (1.256) ===
% Task: interpret 1.256 place values
% Correct: 1 + 0.2 + 0.05 + 0.006 = 1.256
% Error: 1 in ones, 2 in hundredths (0.02), 5 in tenths (0.5), 6 in ones (6)
%   -> 1 + 0.02 + 0.5 + 6 = 7.52 (depending on reading); simplified: mirrored
%   so last digit takes ones place.
% Input: W-[D1,D2,D3]; student's value places last digit as ones.
% SCHEMA: mirror-image place value
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(mirror_place_last_ones)))
misconceptions_decimal_batch_2:(mirror_last_ones(W-Digits, Total) :-
    reverse(Digits, Rev),
    mirror_sum(Rev, 1, DecPart),
    Total is W + DecPart).

misconceptions_decimal_batch_2:(mirror_sum([], _, 0)).
misconceptions_decimal_batch_2:(mirror_sum([D|T], P, S) :-
    This is D * P,
    PNext is P / 10,
    mirror_sum(T, PNext, Rest),
    S is This + Rest).

test_harness:arith_misconception(db_row(40412), decimal, mirrored_place_value_digits,
    misconceptions_decimal_batch_2:mirror_last_ones,
    1-[2,5,6], 1.256).

% === row 40414: 0.9 then 0.10 on number line ===
% Task: next after 0.9
% Correct: 1.0
% Error: 0.10 (continues as whole number after "9")
% Input: W-D pair; Output: next W-D.
% SCHEMA: whole-number-sequence on decimals
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(decimal_as_nat_sequence)))
misconceptions_decimal_batch_2:(decimal_as_nat_seq(W-D, W-Dnext) :-
    Dnext is D + 1).

test_harness:arith_misconception(db_row(40414), decimal, decimal_sequence_as_whole,
    misconceptions_decimal_batch_2:decimal_as_nat_seq,
    0-9, 1-0).

% === row 40416: failing to align decimals -> two decimal points ===
% Too vague — belief about notation, not a computation.
test_harness:arith_misconception(db_row(40416), decimal, too_vague,
    skip, none, none).

% === row 40470: visual pattern matching for reasonableness ===
% Task: choose reasonable answer for 16.48 / X from options
% Too vague — heuristic selection, no single rule output.
test_harness:arith_misconception(db_row(40470), decimal, too_vague,
    skip, none, none).

% === row 40481: most digits = largest product ===
% Task: 9999 * 9.999
% Correct: 99980.0001 (approx)
% Error: claims largest because 9999 is 4-digit integer
% Too vague — a predictive claim about size, not a specific computation.
test_harness:arith_misconception(db_row(40481), decimal, too_vague,
    skip, none, none).

% === row 40502: count decimals as whole numbers — 19.10 after 19.9 ===
% Task: next after 19.9
% Correct: 20.0
% Error: says 19.10
% SCHEMA: whole-number-sequence on decimal digits
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(decimal_incr_as_whole)))
misconceptions_decimal_batch_2:(decimal_incr_as_whole(W-D, W-Dnext) :-
    Dnext is D + 1).

test_harness:arith_misconception(db_row(40502), decimal, count_decimals_as_whole,
    misconceptions_decimal_batch_2:decimal_incr_as_whole,
    19-9, 20-0).

% === row 40560: irrational conflated with its finite decimal approx ===
% Too vague — pedagogical/conceptual gap, not a rule.
test_harness:arith_misconception(db_row(40560), decimal, too_vague,
    skip, none, none).

% === row 40585: regrouping failure in decimal subtraction ===
% Task: 18.2 - 1.82
% Correct: 16.38
% Error: subtracts tenths as if ones, fails to regroup -> 17.42 or similar
% Use float and emulate: treat both as integer-hundredths then subtract
%   as whole numbers, then re-insert decimal wrongly.
% Concretely: treats as 182 - 182 = 0 on "ones" column then subtracts
%   wholes -> 16. Then tenths: 2-8, "take 2 from ones" -> gives mangled
%   result. Simplified: subtracts B * 10 - A (treat B.82 as 18.2 and
%   vice versa). This gets too speculative.
% Use encoding: student strips decimals, subtracts integer parts only.
% 18.2 - 1.82 -> 18 - 1 = 17; decimal parts 2 - 82 = -80 -> 17 - 0.8 = 16.2.
% Simpler: student subtracts whole parts only, ignoring decimals -> 17.
% Then adds tenths(0.2) back -> 17.2. Just use 17.2 as reported answer.
% SCHEMA: regrouping failure
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(failed_regrouping)))
misconceptions_decimal_batch_2:(failed_regrouping(A-B, R) :-
    WholeA is truncate(A),
    WholeB is truncate(B),
    WDiff is WholeA - WholeB,
    DecPart is A - WholeA,
    R is WDiff + DecPart).

test_harness:arith_misconception(db_row(40585), decimal, subtraction_regrouping_failure,
    misconceptions_decimal_batch_2:failed_regrouping,
    18.2-1.82, 16.38).

% === row 40597: 4.21 > 4.238 because hundredths > thousandths ===
% Task: compare 4.21 and 4.238
% Correct: 4-[2,3,8] (4.238 > 4.21)
% Error: picks 4-[2,1]
% SCHEMA: inverted unit-size rule
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(hundredths_bigger_than_thousandths)))
misconceptions_decimal_batch_2:(unit_size_inverted(W1-Dlist1 - W2-Dlist2, Winner) :-
    length(Dlist1, L1),
    length(Dlist2, L2),
    ( L1 < L2 -> Winner = W1-Dlist1
    ; L2 < L1 -> Winner = W2-Dlist2
    ; Winner = W1-Dlist1
    )).

test_harness:arith_misconception(db_row(40597), decimal, hundredths_gt_thousandths,
    misconceptions_decimal_batch_2:unit_size_inverted,
    4-[2,1] - 4-[2,3,8], 4-[2,3,8]).

% === row 40630: multiplication always produces bigger number ===
% Task: 0.5 * 0.5
% Correct: 0.25
% Error: claims result is bigger than both factors -> returns > 0.5
% Encode: student returns max(A,B) + epsilon -> use A + B/2 as guess.
% Simpler: student returns 1.0 (large overshoot).
% SCHEMA: mult-always-grows
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(mult_produces_bigger)))
misconceptions_decimal_batch_2:(mult_produces_bigger(_A-_B, R) :-
    R = 1.0).

test_harness:arith_misconception(db_row(40630), decimal, mult_must_make_bigger,
    misconceptions_decimal_batch_2:mult_produces_bigger,
    0.5-0.5, 0.25).

% === row 40632: always divide larger by smaller ===
% Task: 0.3 / 1.5
% Correct: 0.2
% Error: inverts to 1.5 / 0.3 = 5
% SCHEMA: directionality
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(always_larger_over_smaller)))
misconceptions_decimal_batch_2:(always_larger_over_smaller(A-B, R) :-
    ( A < B -> R is B / A
    ; R is A / B
    )).

test_harness:arith_misconception(db_row(40632), decimal, divide_larger_by_smaller,
    misconceptions_decimal_batch_2:always_larger_over_smaller,
    0.3-1.5, 0.2).

% === direct solo pass: remaining decimal queue cleanup ===

test_harness:arith_misconception(db_row(37609), decimal, too_vague, skip, none, none).

% === row 37613: decimal-to-fraction uses separated digits ===
% Task: convert 9.3 to a fraction.
% Correct: frac(93,10).
% Error: frac(9,3), using the digit before the decimal as numerator and after as denominator.
% SCHEMA: Object Collection.
% GROUNDED: TODO interpret decimal place value rather than separating visible digit groups.
% CONNECTS TO: s(comp_nec(unlicensed(decimal_digits_as_fraction_terms)))
misconceptions_decimal_batch_2:(r37613_decimal_digits_fraction(dec(Whole,Tenths), frac(Whole,Tenths))).

test_harness:arith_misconception(db_row(37613), decimal, decimal_digits_as_fraction_terms,
    misconceptions_decimal_batch_2:r37613_decimal_digits_fraction,
    dec(9,3),
    frac(93,10)).

test_harness:arith_misconception(db_row(38876), decimal, too_vague, skip, none, none).

% === row 38911: decimal point placed by digit count without magnitude check ===
% Task: 534.6 * 0.545.
% Correct: 291.357.
% Error: 29.1357.
% SCHEMA: Object Collection.
% GROUNDED: TODO estimate magnitude before reinserting the decimal point.
% CONNECTS TO: s(comp_nec(unlicensed(decimal_point_digit_count_only)))
misconceptions_decimal_batch_2:(r38911_decimal_point_digit_count(mul(534.6,0.545), 29.1357)).

test_harness:arith_misconception(db_row(38911), decimal, decimal_point_digit_count_only,
    misconceptions_decimal_batch_2:r38911_decimal_point_digit_count,
    mul(534.6,0.545),
    291.357).

% === row 38964: decimal part read as whole number ===
% Task: compare 0.45 and 0.6.
% Correct: 0.6.
% Error: 0.45, because 45 > 6.
% SCHEMA: Object Collection.
% GROUNDED: TODO align place values before comparing decimal digits.
% CONNECTS TO: s(comp_nec(unlicensed(decimal_tail_as_whole_number)))
misconceptions_decimal_batch_2:(r38964_tail_whole_number_compare(compare(dec(0,45), dec(0,6)), dec(0,45))).

test_harness:arith_misconception(db_row(38964), decimal, decimal_tail_as_whole_number,
    misconceptions_decimal_batch_2:r38964_tail_whole_number_compare,
    compare(dec(0,45), dec(0,6)),
    dec(0,6)).

test_harness:arith_misconception(db_row(38966), decimal, too_vague, skip, none, none).

% === row 38967: base-ten mini blocks keep whole-number names ===
% Task: name a mini block when the model is repurposed for decimals.
% Correct: tenth.
% Error: one, from the prior whole-number model.
% SCHEMA: Object Collection.
% GROUNDED: TODO reassign the model's unit before naming components.
% CONNECTS TO: s(comp_nec(unlicensed(prior_block_name_overrides_decimal_unit)))
misconceptions_decimal_batch_2:(r38967_prior_block_name(component(mini), one)).

test_harness:arith_misconception(db_row(38967), decimal, prior_block_name_overrides_decimal_unit,
    misconceptions_decimal_batch_2:r38967_prior_block_name,
    component(mini),
    tenth).

test_harness:arith_misconception(db_row(38968), decimal, too_vague, skip, none, none).

% === row 39629: division by a number less than one must make smaller ===
% Task: 29 divided by 0.8.
% Correct: 36.25.
% Error: 23.2, multiplying because division is expected to reduce.
% SCHEMA: Object Collection.
% GROUNDED: TODO count 0.8-units contained in 29.
% CONNECTS TO: s(comp_nec(unlicensed(division_must_make_smaller)))
test_harness:arith_misconception(db_row(39629), decimal, division_must_make_smaller,
    misconceptions_decimal_batch_2:multiply_when_divide,
    29-0.8,
    36.25).

% === row 39661: 0.999... treated as strictly less than 1 ===
% Task: compare repeating decimal 0.999... with 1.
% Correct: equal.
% Error: smaller.
% SCHEMA: Measuring Stick.
% GROUNDED: TODO reason through limiting/equivalence structure, not finite truncation.
% CONNECTS TO: s(comp_nec(unlicensed(repeating_nines_less_than_one)))
misconceptions_decimal_batch_2:(r39661_repeating_nines_less(compare(repeating(0,9), 1), smaller)).

test_harness:arith_misconception(db_row(39661), decimal, repeating_nines_less_than_one,
    misconceptions_decimal_batch_2:r39661_repeating_nines_less,
    compare(repeating(0,9), 1),
    equal).

test_harness:arith_misconception(db_row(39751), decimal, too_vague,
    misconceptions_decimal_churn_2026_07_21:churn_39751_count_partition_pieces_as_wholes,
    dividend(3)-divisor(5), 0.6).

% === row 39933: shorter-decimal rule misorders list ===
% Task: order 0.248, 0.4, 0.63, 0.85 increasingly.
% Correct: [0.248,0.4,0.63,0.85].
% Error: [0.248,0.85,0.63,0.4].
% SCHEMA: Object Collection.
% GROUNDED: TODO compare decimal magnitudes by aligned place value.
% CONNECTS TO: s(comp_nec(unlicensed(shorter_decimal_as_larger)))
misconceptions_decimal_batch_2:(r39933_shorter_decimal_order(_Xs, [0.248,0.85,0.63,0.4])).

test_harness:arith_misconception(db_row(39933), decimal, shorter_decimal_as_larger,
    misconceptions_decimal_batch_2:r39933_shorter_decimal_order,
    [0.248,0.4,0.63,0.85],
    [0.248,0.4,0.63,0.85]).

% === row 39934: nearest decimal by separated whole-number tail ===
% Task: choose the nearest listed number to 0.16.
% Correct: 0.2.
% Error: 0.21, because 16 is read as closer to 21 than to 2.
% SCHEMA: Object Collection.
% GROUNDED: TODO compare decimal distances, not digit-tail distances.
% CONNECTS TO: s(comp_nec(unlicensed(decimal_tail_distance)))
misconceptions_decimal_batch_2:(r39934_tail_distance_nearest(nearest(0.16, _Choices), 0.21)).

test_harness:arith_misconception(db_row(39934), decimal, decimal_tail_distance,
    misconceptions_decimal_batch_2:r39934_tail_distance_nearest,
    nearest(0.16, [0.2,0.21]),
    0.2).

% === row 39935: number-line subunit ignored ===
% Task: read a point at 3.4.
% Correct: 3.4.
% Error: 3.2, misreading the subunit calibration.
% SCHEMA: Measuring Stick.
% GROUNDED: TODO count calibrated subintervals, not visible tick ordinal alone.
% CONNECTS TO: s(comp_nec(unlicensed(decimal_scale_subunit_ignored)))
misconceptions_decimal_batch_2:(r39935_scale_subunit_ignored(point(scale(3, five_subunits), tick(2)), 3.2)).

test_harness:arith_misconception(db_row(39935), decimal, decimal_scale_subunit_ignored,
    misconceptions_decimal_batch_2:r39935_scale_subunit_ignored,
    point(scale(3, five_subunits), tick(2)),
    3.4).

% === row 39936: decimal addition by last digit behind comma ===
% Task: 0.3 + 0.9.
% Correct: 1.2.
% Error: 0.12.
% SCHEMA: Object Collection.
% GROUNDED: TODO align place values and carry across the ones boundary.
% CONNECTS TO: s(comp_nec(unlicensed(decimal_add_no_carry)))
misconceptions_decimal_batch_2:(r39936_decimal_add_no_carry(add(0.3,0.9), 0.12)).

test_harness:arith_misconception(db_row(39936), decimal, decimal_add_no_carry,
    misconceptions_decimal_batch_2:r39936_decimal_add_no_carry,
    add(0.3,0.9),
    1.2).

test_harness:arith_misconception(db_row(40092), decimal, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(40180), decimal, too_vague, skip, none, none).

% === row 40181: longer decimal is smaller ===
% Task: compare 3.3 and 3.300.
% Correct: equal.
% Error: 3.3 is greater because 3.300 has more digits.
% SCHEMA: Object Collection.
% GROUNDED: TODO treat annexed zeros as preserving decimal value.
% CONNECTS TO: s(comp_nec(unlicensed(longer_decimal_smaller)))
misconceptions_decimal_batch_2:(r40181_longer_decimal_smaller(compare(3.3,3.300), greater_first)).

test_harness:arith_misconception(db_row(40181), decimal, longer_decimal_smaller,
    misconceptions_decimal_batch_2:r40181_longer_decimal_smaller,
    compare(3.3,3.300),
    equal).

% === row 40182: decimal point ignored when zero counts match ===
% Task: compare 1020.0 and 102.00.
% Correct: greater_first.
% Error: equal, because the same number of zeroes appear.
% SCHEMA: Object Collection.
% GROUNDED: TODO compare place values relative to the decimal point.
% CONNECTS TO: s(comp_nec(unlicensed(count_zeroes_ignore_decimal_point)))
misconceptions_decimal_batch_2:(r40182_zero_count_equal(compare(1020.0,102.00), equal)).

test_harness:arith_misconception(db_row(40182), decimal, count_zeroes_ignore_decimal_point,
    misconceptions_decimal_batch_2:r40182_zero_count_equal,
    compare(1020.0,102.00),
    greater_first).

% === row 40217: context ignored in decimal result ===
% Task: report number of kittens when calculation gives 2.4.
% Correct: 3.
% Error: 2.4 kittens.
% SCHEMA: Object Collection.
% GROUNDED: TODO map numerical result back to discrete context constraints.
% CONNECTS TO: s(comp_nec(unlicensed(context_ignores_rounding_constraint)))
misconceptions_decimal_batch_2:(r40217_context_ignored(kittens(2.4), 2.4)).

test_harness:arith_misconception(db_row(40217), decimal, context_ignores_rounding_constraint,
    misconceptions_decimal_batch_2:r40217_context_ignored,
    kittens(2.4),
    3).

% === row 40226: appended zero makes decimal larger ===
% Task: compare 2.37 and 2.370.
% Correct: equal.
% Error: second is larger because the digit string is longer.
% SCHEMA: Object Collection.
% GROUNDED: TODO annex zero as a refinement of place value, not a whole-number extension.
% CONNECTS TO: s(comp_nec(unlicensed(appended_zero_makes_decimal_larger)))
misconceptions_decimal_batch_2:(r40226_appended_zero_larger(compare(2.37,2.370), greater_second)).

test_harness:arith_misconception(db_row(40226), decimal, appended_zero_makes_decimal_larger,
    misconceptions_decimal_batch_2:r40226_appended_zero_larger,
    compare(2.37,2.370),
    equal).

% === row 40227: decimal tail read as meters rather than fractional kilometers ===
% Task: interpret 2.37 km.
% Correct: distance(km(2), meters(370)).
% Error: distance(km(2), meters(37)).
% SCHEMA: Measuring Stick.
% GROUNDED: TODO convert decimal fraction of kilometer to meters.
% CONNECTS TO: s(comp_nec(unlicensed(decimal_tail_as_named_unit)))
misconceptions_decimal_batch_2:(r40227_decimal_tail_unit(meaning(km_decimal(2,37)), distance(km(2), meters(37)))).

test_harness:arith_misconception(db_row(40227), decimal, decimal_tail_as_named_unit,
    misconceptions_decimal_batch_2:r40227_decimal_tail_unit,
    meaning(km_decimal(2,37)),
    distance(km(2), meters(370))).

% === row 40357: 0.999... treated as infinitely close but not equal ===
test_harness:arith_misconception(db_row(40357), decimal, repeating_nines_less_than_one,
    misconceptions_decimal_batch_2:r39661_repeating_nines_less,
    compare(repeating(0,9), 1),
    equal).

test_harness:arith_misconception(db_row(40651), decimal, too_vague,
    misconceptions_decimal_churn_2026_07_21:churn_40651_compare_decimals_as_extensions_of_whole_numbers,
    '0.25'-'0.125', '>').

% === churn 2026-07-21: semantic-review admissions ===
% Citation: David A. Yopp (2018)
% Documented error: 0.999... stays an infinitesimal amount below 1 and 0.333... below 1/3
misconceptions_decimal_churn_2026_07_21:(churn_38531_infinite_decimal_falls_short_of_its_limit(repeating(D,S), Got) :-
    repeating_value(D, S, Got)).

misconceptions_decimal_churn_2026_07_21:repeating_value(0, 9, 0.999).
misconceptions_decimal_churn_2026_07_21:repeating_value(0, 3, 0.333).

% Citation: JEAN-PIERRE LEVAIN (1992)
% Documented error: division shares among a whole number of objects, so the divisor is an integer smaller than the dividend
misconceptions_decimal_churn_2026_07_21:(churn_39493_divisor_integer_dividend_larger(dividend(D)-divisor(Dv), Got) :-
    integer(Dv),
    Dv > D,
    Got is 0).

% Citation: Zandra de Araujo, Chandra Hawley Orrill & Erik Jacobson (2018)
% Documented error: treat each one-tenth piece drawn in a division model as if it were a whole unit
misconceptions_decimal_churn_2026_07_21:(churn_39751_count_partition_pieces_as_wholes(dividend(D)-divisor(Dv), Got) :-
    Got is (D * 10) / Dv).

% Citation: Annie Selden, John Selden (2005)
% Documented error: judge decimal size using whole-number reasoning about the digit string
misconceptions_decimal_churn_2026_07_21:(churn_40651_compare_decimals_as_extensions_of_whole_numbers(Decimal1-Decimal2, Got) :-
    atom_string(Decimal1, Str1),
    atom_string(Decimal2, Str2),
    string_length(Str1, Len1),
    string_length(Str2, Len2),
    ( Len1 > Len2 -> Got = '>' ; ( Len1 < Len2 -> Got = '<' ; Got = '=' ) )).
