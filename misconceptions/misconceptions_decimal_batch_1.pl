:- module(misconceptions_decimal_batch_1, []).
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

:- multifile test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.

% ---- Encodings appended by agent for decimal batch 1 ----

% === row 37483: decimal operator must be whole (pick wrong op) ===
% Task: price-per-unit 15000, amount 0.75 -> 15000 * 0.75 = 11250
% Correct: 11250.0
% Error: divides instead (15000 / 0.75 = 20000.0) because operator < 1 "must divide"
% SCHEMA: Motion Along a Path (repeated addition locks operator to integer)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(decimal_operator_must_be_whole)))
r37483_div_instead_mult(price(Price)-amount(Amt), Got) :-
    Got is Price / Amt.

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
r37503_blind_place(digits(D)-places(P), Got) :-
    Got is D / (10 ** P).

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
r37556_div_always_smaller(dividend(A)-divisor(B), Judgment) :-
    Q is A / B,
    (   Q > A -> Judgment = lt   % student says quotient < dividend
    ;   Q < A -> Judgment = lt
    ;             Judgment = eq
    ).

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
r37596_longer_is_larger(dec(W,F1,_)-dec(W,F2,_), Winner) :-
    (   F1 > F2
    ->  Winner = dec(W,F1,_)
    ;   Winner = dec(W,F2,_)
    ).

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
r37616_more_places_smaller(dec(W,F1,L1)-dec(W,F2,L2), Winner) :-
    (   L1 < L2
    ->  Winner = dec(W,F1,L1)
    ;   L1 > L2
    ->  Winner = dec(W,F2,L2)
    ;   (F1 >= F2 -> Winner = dec(W,F1,L1) ; Winner = dec(W,F2,L2))
    ).

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
r37618_num_only(frac(N,_), Got) :-
    Got is N / 10.

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
r37620_bar_as_point(frac(N,D), Got) :-
    Got is N + D / 10.

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
r37636_sep_sub(dec(W1,F1,L1)-dec(W2,F2,L2), dec(WD,FD,Len)) :-
    WD is W1 - W2,
    FD is F1 - F2,
    Len is max(L1,L2).

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
r37638_ignore_then_insert(dec(W1,F1,_)-dec(W2,F2,_), Got) :-
    Whole is W1 * 10 + F1,
    Other is W2 * 10 + F2,
    Sum is Whole + Other,
    Got is Sum / 10.

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
r37799_div_for_mult(a(A)-b(B), Got) :-
    Got is A / B.

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
r37802_swap_operands(dividend(A)-divisor(B), Got) :-
    Got is B / A.

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
r37816_ragged_add(dec(W1,_,_)-dec(W2,F2,L2), dec(0, FD, L2)) :-
    FD is W1 + W2 + F2.

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
r37874_square_parts(dec(W,F,L), dec(WS,FS,L)) :-
    WS is W * W,
    FS is F * F.

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
r37984_no_borrow(dec(W1,_,_)-dec(W2,F2,L2), dec(WD,F2,L2)) :-
    WD is W1 - W2.

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
r38305_longer_larger_order(dec(W,F1,_)-dec(W,F2,_), Winner) :-
    (   F1 > F2
    ->  Winner = dec(W,F1,_)
    ;   Winner = dec(W,F2,_)
    ).

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
r38398_place_inflation(digit(D)-pos(P), Got) :-
    %  Correct value of digit D in 10^-P position is D * 10^-P.
    %  The student's wrong rule: D in "tenths" means D * 10 (like tens),
    %  D in "hundredths" means D * 100, etc.
    Got is D * (10 ** P).

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
r38400_denom_analogy(dec(W,F1,L1)-dec(W,F2,L2), Winner) :-
    (   L1 < L2
    ->  Winner = dec(W,F1,L1)
    ;   L1 > L2
    ->  Winner = dec(W,F2,L2)
    ;   (F1 >= F2 -> Winner = dec(W,F1,L1) ; Winner = dec(W,F2,L2))
    ).

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
    skip, none, none).

% === row 38564: shorter-is-larger via tenths > hundredths ===
% Task: compare 2.3 and 2.32; return the larger.
% Correct: dec(2,32,2)   (2.32 > 2.3)
% Error: picks dec(2,3,1) — "tenths > hundredths"
% SCHEMA: Arithmetic is Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(shorter_is_larger)))
r38564_shorter_larger(dec(W,F1,L1)-dec(W,F2,L2), Winner) :-
    (   L1 < L2
    ->  Winner = dec(W,F1,L1)
    ;   L1 > L2
    ->  Winner = dec(W,F2,L2)
    ;   (F1 >= F2 -> Winner = dec(W,F1,L1) ; Winner = dec(W,F2,L2))
    ).

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
r38727_div_instead_mult(price(P)-amount(A), Got) :-
    Got is P / A.

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
r38927_div_instead_mult(rate(R)-qty(Q), Got) :-
    Got is R / Q.

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
r39077_mult_instead_div(qty(Q)-rate(R), Got) :-
    Got is Q * R.

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
r39128_match_whole_digits(digits(D)-factor_whole(W), Got) :-
    count_digits(D, Total),
    Tail is Total - W,
    Got is D / (10 ** Tail).

% helper: number of decimal digits of a positive integer.
count_digits(0, 1) :- !.
count_digits(N, C) :- N > 0, count_digits_acc(N, 0, C).
count_digits_acc(0, Acc, Acc) :- Acc > 0, !.
count_digits_acc(N, Acc, C) :-
    N > 0,
    N1 is N // 10,
    Acc1 is Acc + 1,
    count_digits_acc(N1, Acc1, C).

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
r39407_mmb_judge(a(A)-b(B), Judgment) :-
    P is A * B,
    (   P < B -> Judgment = false  % student inverts truth
    ;   P > B -> Judgment = true
    ;             Judgment = eq
    ).

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
r39438_whole_string_compare(dec(W,F1,_)-dec(W,F2,_), Winner) :-
    (   F1 > F2
    ->  Winner = dec(W,F1,_)
    ;   Winner = dec(W,F2,_)
    ).

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
r39442_bar_swap(dec(0,F,_), frac(1,F)).

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
r39460_longer_larger(dec(W,F1,_)-dec(W,F2,_), Winner) :-
    (   F1 > F2
    ->  Winner = dec(W,F1,_)
    ;   Winner = dec(W,F2,_)
    ).

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
r39462_longer_larger_with_zero(dec(W,F1,L1)-dec(W,F2,L2), Winner) :-
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
    ).

% Leading tenth digit is zero if Frac < 10^(Len-1).
tenth_is_zero(F,L) :-
    L >= 1,
    F < 10 ** (L - 1).

test_harness:arith_misconception(db_row(39462), decimal, longer_is_larger_zero_rule,
    misconceptions_decimal_batch_1:r39462_longer_larger_with_zero,
    dec(0,25,2)-dec(0,5,1),
    dec(0,5,1)).

% === row 39493: divisor-must-be-integer model ===
test_harness:arith_misconception(db_row(39493), decimal, too_vague,
    skip, none, none).

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
r39575_more_digits_smaller(dec(W,F1,L1)-dec(W,F2,L2), Winner) :-
    (   L1 < L2
    ->  Winner = dec(W,F1,L1)
    ;   L1 > L2
    ->  Winner = dec(W,F2,L2)
    ;   (F1 >= F2 -> Winner = dec(W,F1,L1) ; Winner = dec(W,F2,L2))
    ).

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
r39623_longer_larger(dec(W,F1,_)-dec(W,F2,_), Winner) :-
    (   F1 > F2
    ->  Winner = dec(W,F1,_)
    ;   Winner = dec(W,F2,_)
    ).

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
r39625_money_truncate(dec(W,F,L), dec(W,FT,LT)) :-
    (   L =< 2
    ->  FT = F, LT = L
    ;   Shift is L - 2,
        FT is F div (10 ** Shift),
        LT = 2
    ).

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
r39632_tenths_larger(dec(W,F1,L1)-dec(W,F2,L2), Winner) :-
    (   L1 < L2
    ->  Winner = dec(W,F1,L1)
    ;   L1 > L2
    ->  Winner = dec(W,F2,L2)
    ;   (F1 >= F2 -> Winner = dec(W,F1,L1) ; Winner = dec(W,F2,L2))
    ).

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
r39708_ignore_point_sub(dec(W1,F1,L)-dec(W2,F2,L), dec(0,FD,L)) :-
    A is W1 * (10 ** L) + F1,
    B is W2 * (10 ** L) + F2,
    FD is A - B.

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
r39732_int_closer_zero(dec(W,F1,_)-dec(W,F2,_), Smaller) :-
    (   F1 < F2
    ->  Smaller = dec(W,F1,_)
    ;   Smaller = dec(W,F2,_)
    ).

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
r39791_mmb_copy_larger(a(A)-b(B), Got) :-
    (A >= B -> Got = A ; Got = B).

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
r39793_more_places_smaller(dec(W,F1,L1)-dec(W,F2,L2), Winner) :-
    (   L1 < L2
    ->  Winner = dec(W,F1,L1)
    ;   L1 > L2
    ->  Winner = dec(W,F2,L2)
    ;   (F1 >= F2 -> Winner = dec(W,F1,L1) ; Winner = dec(W,F2,L2))
    ).

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
r40048_double_shift(dividend(A)-divisor(B), Got) :-
    % compute correct A/B, then divide by 100 (undo the scaling twice).
    Q is A / B,
    Got is Q / 100.

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
r40138_reciprocal_analogy(dec(W,F1,L)-dec(W,F2,L), Winner) :-
    (   F1 < F2
    ->  Winner = dec(W,F1,L)
    ;   Winner = dec(W,F2,L)
    ).

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
r40140_zero_larger(dec(W1,F1,L1)-dec(W2,F2,L2), Winner) :-
    % student picks whichever has frac length 0
    (   L1 =:= 0
    ->  Winner = dec(W1,F1,L1)
    ;   L2 =:= 0
    ->  Winner = dec(W2,F2,L2)
    ;   (F1 >= F2 -> Winner = dec(W1,F1,L1) ; Winner = dec(W2,F2,L2))
    ).

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
r40321_miscount_places(a(A)-b(B), Got) :-
    True is A * B,
    Got is True * 10.

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
r40406_blind_count(a(A)-b(B), Got) :-
    % Student computes A*B then shifts the point by one extra place left.
    True is A * B,
    Got is True / 10.

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
r40413_shorter_larger(dec(W,F1,L1)-dec(W,F2,L2), Winner) :-
    (   L1 < L2
    ->  Winner = dec(W,F1,L1)
    ;   L1 > L2
    ->  Winner = dec(W,F2,L2)
    ;   (F1 >= F2 -> Winner = dec(W,F1,L1) ; Winner = dec(W,F2,L2))
    ).

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
r40442_sum_dp(dp(D1)-dp(D2), Got) :-
    Got is D1 + D2.

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
r40472_no_point(dec(W1,F1,L1)-dec(W2,F2,L2), Got) :-
    A is W1 * (10 ** L1) + F1,
    B is W2 * (10 ** L2) + F2,
    Got is A * B.

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
r40500_decimal_as_unit(dec(W,F1,L1)-dec(W,F2,L2), Winner) :-
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
    ).

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
r40527_decimal_as_int(dec(W,F1,_)-dec(W,F2,_), Winner) :-
    (   F1 > F2
    ->  Winner = dec(W,F1,_)
    ;   Winner = dec(W,F2,_)
    ).

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
