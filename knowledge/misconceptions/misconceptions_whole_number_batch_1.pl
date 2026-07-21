:- module(misconceptions_whole_number_batch_1, []).
% whole_number misconceptions — research corpus batch 1/5.
% Native arithmetic layer only. Theoretical annotations as comments:
%   % GROUNDED: TODO — placeholder for future embodied arithmetic layer
%   % SCHEMA: <schema name> — Lakoff & Nunez grounding when applicable
%   % CONNECTS TO: s(comp_nec(unlicensed(...))) — PML operator path
%
% Registration convention (from Task 3 arch fix):
%   test_harness:arith_misconception(Source, Domain, Description,
%       misconceptions_whole_number_batch_1:rule_name, Input, Expected).
% Rule predicates do NOT go on the module export list.
%
% Rule semantics: each rule encodes the buggy student procedure and returns
% the student's wrong answer. The 6th registration argument is the correct
% answer. The test harness compares them — they should differ.

:- multifile test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.

% ---- Encodings appended by agent for whole_number batch 1 ----

% === row 37470: rounds everything to leading power of ten ===
% Task: estimate 98 x 2.62. Round 98 -> 100 and 2.62 -> 3 (standard rounding).
% Error: 100 * 3 = 300 (student's buggy estimate)
% Correct: closer estimate 100 * 2.5 = 250
% Input is a pair representing the student's already-rounded factors.
% SCHEMA: TODO — estimation/rounding
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(over_round_leading_power)))
rounds_to_leading_power(A-B, Got) :-
    Got is A * B.

test_harness:arith_misconception(db_row(37470), whole_number, round_to_leading_power,
    misconceptions_whole_number_batch_1:rounds_to_leading_power,
    100-3,
    250).

% === row 37492: zero claimed exempt from even/odd ===
test_harness:arith_misconception(db_row(37492), whole_number, too_vague,
    skip, none, none).

% === row 37527: truncate decimal remainder, ignore real-world context ===
% Task: 296 / 24 buses; student gets 12.3 and drops the .3.
% Error: 12 (floor)
% Correct: 13 (ceiling — need enough buses)
% SCHEMA: TODO — division with remainder interpretation
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(truncate_remainder)))
truncates_division_remainder(A-B, Got) :-
    Got is A div B.

test_harness:arith_misconception(db_row(37527), whole_number, truncate_bus_remainder,
    misconceptions_whole_number_batch_1:truncates_division_remainder,
    296-24,
    13).

% === row 37546: 100 x 100 = 1000 (PST power-of-ten error) ===
% Task: 100 * 100
% Error: 1000 (concatenates 1 with 3 zeros instead of 4)
% Correct: 10000
% SCHEMA: TODO — powers of ten
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(bad_power_of_ten)))
bad_power_of_ten_product(A-B, Got) :-
    Got is A * B // 10.

test_harness:arith_misconception(db_row(37546), whole_number, bad_power_of_ten,
    misconceptions_whole_number_batch_1:bad_power_of_ten_product,
    100-100,
    10000).

% === row 37589: multiplies tens*tens and ones*ones, omits cross products ===
% Task: 23 * 23
% Error: 20*20 + 3*3 = 400 + 9 = 409
% Correct: 529
% SCHEMA: TODO — distributivity
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(missing_cross_products)))
omits_cross_products(A-B, Got) :-
    TA is (A // 10) * 10,
    OA is A mod 10,
    TB is (B // 10) * 10,
    OB is B mod 10,
    Got is TA * TB + OA * OB.

test_harness:arith_misconception(db_row(37589), whole_number, omit_cross_products,
    misconceptions_whole_number_batch_1:omits_cross_products,
    23-23,
    529).

% === row 37635: buggy regrouping across zeros (zero->9 without cascade) ===
% Task: 3004 - 286
% Error: student replaces the 0 in minuend with 9 without properly
% decrementing the thousands digit. A common result from this bug is
% 2818 (applying zero->9 inconsistently). Here we model a specific
% buggy transformation: student's 0->9 substitution ignores the
% ten-thousands borrow, over-subtracting by 100.
% Correct: 2718
% SCHEMA: TODO — regrouping
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(bad_zero_regroup)))
bad_zero_regroup(A-B, Got) :-
    % Buggy: student's flawed procedure yields (A - B) + 100 because
    % the zero is replaced by 9 but the thousands digit is not decremented.
    Got is (A - B) + 100.

test_harness:arith_misconception(db_row(37635), whole_number, bad_zero_regroup,
    misconceptions_whole_number_batch_1:bad_zero_regroup,
    3004-286,
    2718).

% === row 37669: subtracts smaller-from-larger digit in each column ===
% Task: 703 - 245
% Error: 542 (absolute digitwise difference per column)
% Correct: 458
% SCHEMA: TODO — column subtraction
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(smaller_from_larger)))
smaller_minus_larger_columns(A-B, Got) :-
    A1 is A mod 10, B1 is B mod 10,
    A2 is (A // 10) mod 10, B2 is (B // 10) mod 10,
    A3 is (A // 100) mod 10, B3 is (B // 100) mod 10,
    D1 is abs(A1 - B1),
    D2 is abs(A2 - B2),
    D3 is abs(A3 - B3),
    Got is D3 * 100 + D2 * 10 + D1.

test_harness:arith_misconception(db_row(37669), whole_number, smaller_minus_larger,
    misconceptions_whole_number_batch_1:smaller_minus_larger_columns,
    703-245,
    458).

% === row 37690: linguistic cue "times" -> multiply (no numeric error) ===
test_harness:arith_misconception(db_row(37690), whole_number, too_vague,
    skip, none, none).

% === row 37726: example-as-proof (no numeric error) ===
test_harness:arith_misconception(db_row(37726), whole_number, too_vague,
    skip, none, none).

% === row 37783: invents contextual excuses for fractional remainder ===
test_harness:arith_misconception(db_row(37783), whole_number, too_vague,
    skip, none, none).

% === row 37796: wrong-order subtraction from addition family ===
% Task: given 5+4=9, write subtraction; student writes 4-5=1.
% Error: student treats 4-5 as |4-5| = 1 (smaller-from-larger swap).
% Correct value for 4-5 would be -1.
% SCHEMA: TODO — inverse relation
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(flip_subtraction_order)))
flips_subtraction_order(A-B, Got) :-
    Got is abs(A - B).

test_harness:arith_misconception(db_row(37796), whole_number, flip_subtraction_order,
    misconceptions_whole_number_batch_1:flips_subtraction_order,
    4-5,
    -1).

% === row 37817: divisibility by trial division not prime factorization ===
test_harness:arith_misconception(db_row(37817), whole_number, too_vague,
    skip, none, none).

% === row 37840: "tenty" for thirty (invented number word) ===
test_harness:arith_misconception(db_row(37840), whole_number, too_vague,
    skip, none, none).

% === row 37856: counting required after dealing ===
test_harness:arith_misconception(db_row(37856), whole_number, too_vague,
    skip, none, none).

% === row 37881: lose track of hidden items while counting on ===
% Task: 4 visible + 7 hidden pigs.
% Error: undercount — e.g. 9 (loses track of ~2 of the hidden ones).
% Correct: 11
% SCHEMA: TODO — keeping-track/counting-on
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(lose_track_hidden)))
undercounts_hidden_items(Visible-Hidden, Got) :-
    Got is Visible + (Hidden - 2).

test_harness:arith_misconception(db_row(37881), whole_number, undercount_hidden,
    misconceptions_whole_number_batch_1:undercounts_hidden_items,
    4-7,
    11).

% === row 37901: adjusts dividend to multiple, ignoring remainder ===
% Task: 23 candles, 3 per row -> how many full rows?
% Error: student redraws as 24/8=3 (adjusts to a divisible pair,
% collapses remainder).
% We model: student rounds dividend up to next multiple of divisor and divides.
% For 23 / 3: 24 / 3 = 8 rows (student ignores that one row would be short).
% Correct: 7 (full rows with remainder 2 left over).
% SCHEMA: TODO — division with remainder
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(adjust_dividend_to_multiple)))
adjusts_dividend_to_multiple(Dividend-Divisor, Got) :-
    Rem is Dividend mod Divisor,
    ( Rem =:= 0
    -> Adjusted = Dividend
    ; Adjusted is Dividend + (Divisor - Rem)
    ),
    Got is Adjusted // Divisor.

test_harness:arith_misconception(db_row(37901), whole_number, adjust_dividend_for_division,
    misconceptions_whole_number_batch_1:adjusts_dividend_to_multiple,
    23-3,
    7).

% === row 37935: teen numbers force counting, not make-a-ten ===
test_harness:arith_misconception(db_row(37935), whole_number, too_vague,
    skip, none, none).

% === row 37998: numerosity vs convex hull visual cue ===
test_harness:arith_misconception(db_row(37998), whole_number, too_vague,
    skip, none, none).

% === row 38058: decade transition "ten-teen", "10-one" ===
test_harness:arith_misconception(db_row(38058), whole_number, too_vague,
    skip, none, none).

% === row 38090: empty number line spatial violation ===
test_harness:arith_misconception(db_row(38090), whole_number, too_vague,
    skip, none, none).

% === row 38107: number line bars as concrete objects ===
test_harness:arith_misconception(db_row(38107), whole_number, too_vague,
    skip, none, none).

% === row 38122: drops thousands unit in place-value decomposition ===
% Task: represent 2615 without thousand-bundles; student drops thousand-digit.
% Error: reports 615 (6 hundreds 1 ten 5 ones only).
% Correct: 2615 (as 26 hundreds 1 ten 5 ones).
% SCHEMA: TODO — place value
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(drop_higher_unit)))
drops_higher_unit(N, Got) :-
    Got is N mod 1000.

test_harness:arith_misconception(db_row(38122), whole_number, drop_higher_unit,
    misconceptions_whole_number_batch_1:drops_higher_unit,
    2615,
    2615).

% === row 38166: primes are small (premature trial-division cap) ===
% Task: is 391 prime? Student tries 2,3,5,7, finds none divide, declares prime.
% Error: 1 (meaning: student says "prime")
% Correct: 0 (meaning: composite — 391 = 17 * 23)
% Input: N-Cap where Cap is the highest prime student bothers to try.
% SCHEMA: TODO — prime recognition
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(primes_are_small)))
is_prime_by_small_trial(N-Cap, Got) :-
    ( has_small_divisor(N, 2, Cap)
    -> Got = 0
    ; Got = 1
    ).

has_small_divisor(N, P, Cap) :-
    P =< Cap,
    ( N mod P =:= 0
    -> true
    ; P1 is P + 1,
      has_small_divisor(N, P1, Cap)
    ).

test_harness:arith_misconception(db_row(38166), whole_number, primes_are_small,
    misconceptions_whole_number_batch_1:is_prime_by_small_trial,
    391-7,
    0).

% === row 38211: confuses associative with commutative property ===
test_harness:arith_misconception(db_row(38211), whole_number, too_vague,
    skip, none, none).

% === row 38228: forgets the leftover ten after borrowing ===
% Task: 31 - 6. Child converts 2 tens into 10+10 units, subtracts 6, forgets
% the extra ten.
% Error: 15 (10 + 5, after losing one of the two tens)
% Correct: 25
% SCHEMA: TODO — regrouping / place value
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(forget_carried_ten)))
forgets_carried_ten(A-B, Got) :-
    Got is A - B - 10.

test_harness:arith_misconception(db_row(38228), whole_number, forget_carried_ten,
    misconceptions_whole_number_batch_1:forgets_carried_ten,
    31-6,
    25).

% === row 38247: conflates levels of units ===
test_harness:arith_misconception(db_row(38247), whole_number, too_vague,
    skip, none, none).

% === row 38280: conflates intermediate and overall units ===
test_harness:arith_misconception(db_row(38280), whole_number, too_vague,
    skip, none, none).

% === row 38378: multi-digit multiplication without place value ===
% Text reports she arrives at 324 (which is the correct answer for 81 * 4)
% via a digit-by-digit procedure. No concrete wrong numeric output.
test_harness:arith_misconception(db_row(38378), whole_number, too_vague,
    skip, none, none).

% === row 38437: idiosyncratic large-number imagery ===
test_harness:arith_misconception(db_row(38437), whole_number, too_vague,
    skip, none, none).

% === row 38465: additive row-extension instead of multiplicative fold ===
% Task: 6 regions folded into 3 each -> how many regions?
% Error: 6 + 3 = 9 (student imagines adding another row of 3)
% Correct: 6 * 3 = 18
% SCHEMA: TODO — multiplication as repeated grouping
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(additive_fold_sequence)))
additive_fold_sequence(A-B, Got) :-
    Got is A + B.

test_harness:arith_misconception(db_row(38465), whole_number, additive_fold_sequence,
    misconceptions_whole_number_batch_1:additive_fold_sequence,
    6-3,
    18).

% === row 38544: abstract symbols read as pictures ===
test_harness:arith_misconception(db_row(38544), whole_number, too_vague,
    skip, none, none).

% === row 38596: (tens*tens) + (ones*ones), miss cross products ===
% Task: 16 * 25
% Error: 10*20 + 6*5 = 200 + 30 = 230
% Correct: 400
% SCHEMA: TODO — distributivity
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(missing_cross_products)))
omits_cross_products_v2(A-B, Got) :-
    TA is (A // 10) * 10,
    OA is A mod 10,
    TB is (B // 10) * 10,
    OB is B mod 10,
    Got is TA * TB + OA * OB.

test_harness:arith_misconception(db_row(38596), whole_number, omit_cross_products_v2,
    misconceptions_whole_number_batch_1:omits_cross_products_v2,
    16-25,
    400).

% === row 38616: defaults to recently taught operation (add) ===
% Task: 57 cars total, 24 red; how many non-red?
% Error: 57 + 24 = 81 (student adds because that's the recently-taught op)
% Correct: 57 - 24 = 33
% SCHEMA: TODO — word-problem operation choice
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(default_to_addition)))
defaults_to_addition(A-B, Got) :-
    Got is A + B.

test_harness:arith_misconception(db_row(38616), whole_number, default_to_addition,
    misconceptions_whole_number_batch_1:defaults_to_addition,
    57-24,
    33).

% === row 38644: 1 cannot be a repeating decimal ===
test_harness:arith_misconception(db_row(38644), whole_number, too_vague,
    skip, none, none).

% === row 38726: formal vs informal meaning of number ===
test_harness:arith_misconception(db_row(38726), whole_number, too_vague,
    skip, none, none).

% === row 38739: explains rule only by example ===
test_harness:arith_misconception(db_row(38739), whole_number, too_vague,
    skip, none, none).

% === row 38850: prime decomposition not abstracted as object ===
test_harness:arith_misconception(db_row(38850), whole_number, too_vague,
    skip, none, none).

% === row 38871: cannot represent multiplication via array ===
test_harness:arith_misconception(db_row(38871), whole_number, too_vague,
    skip, none, none).

% === row 38958: digit-wise division (wrong distributivity) ===
% Task: 346 / 123
% Error: 300/100=3, 40/20=2, 6/3=2 -> concatenated 322
% Correct: 2 (whole-number quotient; remainder 100)
% SCHEMA: TODO — distributivity
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(digit_wise_division)))
digit_wise_division(Dividend-Divisor, Got) :-
    H1 is Dividend // 100,
    H2 is Divisor // 100,
    T1 is (Dividend // 10) mod 10,
    T2 is (Divisor // 10) mod 10,
    O1 is Dividend mod 10,
    O2 is Divisor mod 10,
    QH is H1 // H2,
    QT is T1 // T2,
    QO is O1 // O2,
    Got is QH * 100 + QT * 10 + QO.

test_harness:arith_misconception(db_row(38958), whole_number, digit_wise_division,
    misconceptions_whole_number_batch_1:digit_wise_division,
    346-123,
    2).

% === row 39001: additive trial-and-error for factors ===
test_harness:arith_misconception(db_row(39001), whole_number, too_vague,
    skip, none, none).

% === row 39068: place-value words as writing order ===
test_harness:arith_misconception(db_row(39068), whole_number, too_vague,
    skip, none, none).

% === row 39079: confuses "divided by" with "divided into" ===
test_harness:arith_misconception(db_row(39079), whole_number, too_vague,
    skip, none, none).

% === row 39124: borrows from zero without substituting 9 ===
% Task: 402 - 6. Student decrements the 4 but leaves the middle 0 as 0,
% then borrows 10 into the ones.
% Error: 306 (loses the 90 that should come from the zero-becomes-9 step)
% Correct: 396
% SCHEMA: TODO — regrouping across zero
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(zero_no_substitute)))
borrow_zero_no_substitute(A-B, Got) :-
    Got is A - B - 90.

test_harness:arith_misconception(db_row(39124), whole_number, zero_no_substitute,
    misconceptions_whole_number_batch_1:borrow_zero_no_substitute,
    402-6,
    396).

% === row 39137: misreads 'minus' as 'minutes', adds instead ===
% Task: 56 - 40
% Error: 96 (reads as "56 minutes forty" and adds)
% Correct: 16
% SCHEMA: TODO — reading errors
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(minus_misread_as_minutes)))
misreads_minus_as_add(A-B, Got) :-
    Got is A + B.

test_harness:arith_misconception(db_row(39137), whole_number, minus_misread_as_add,
    misconceptions_whole_number_batch_1:misreads_minus_as_add,
    56-40,
    16).

% === row 39182: judges takeaway easier than missing-addend ===
test_harness:arith_misconception(db_row(39182), whole_number, too_vague,
    skip, none, none).

% === row 39216: reverts to concrete example instead of abstracting ===
test_harness:arith_misconception(db_row(39216), whole_number, too_vague,
    skip, none, none).

% === row 39298: rejects valid partial-differences strategy ===
test_harness:arith_misconception(db_row(39298), whole_number, too_vague,
    skip, none, none).

% === row 39342: counts as ritual without 1-1 correspondence ===
test_harness:arith_misconception(db_row(39342), whole_number, too_vague,
    skip, none, none).

% === row 39395: BEDMAS strict hierarchy: divide before multiply ===
% Task: 200 / 2 * 50
% Error: 2 (compute 2*50=100 first, then 200/100)
% Correct: 5000 (left-to-right)
% SCHEMA: TODO — order of operations
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(bedmas_strict_order)))
bedmas_divide_before_multiply(A-B-C, Got) :-
    Prod is B * C,
    Got is A // Prod.

test_harness:arith_misconception(db_row(39395), whole_number, bedmas_strict_order,
    misconceptions_whole_number_batch_1:bedmas_divide_before_multiply,
    200-2-50,
    5000).

% === row 39424: "greater than x by y" -> x - y (pseudo-analytical) ===
% Task: "Which number is greater than 4 by 7?"
% Error: 3 (student computes 7 - 4 as difference)
% Correct: 11 (4 + 7)
% Input: A-B with meaning "greater than A by B"
% SCHEMA: TODO — word problem semantics
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(greater_than_as_difference)))
greater_than_as_difference(A-B, Got) :-
    Got is abs(B - A).

test_harness:arith_misconception(db_row(39424), whole_number, greater_than_as_difference,
    misconceptions_whole_number_batch_1:greater_than_as_difference,
    4-7,
    11).

% === row 39495: picks "larger" by digit face values ===
% Task: which is bigger, 298 or 511?
% Error: 298 (because digits 2,9,8 look bigger than 5,1,1)
% Correct: 511
% We model: the student picks the number with the larger digit sum.
% SCHEMA: TODO — place value
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(digit_sum_magnitude)))
picks_by_digit_sum(A-B, Got) :-
    digit_sum(A, SA),
    digit_sum(B, SB),
    ( SA >= SB -> Got = A ; Got = B ).

digit_sum(0, 0) :- !.
digit_sum(N, S) :-
    N > 0,
    D is N mod 10,
    N1 is N // 10,
    digit_sum(N1, S1),
    S is S1 + D.

test_harness:arith_misconception(db_row(39495), whole_number, digit_sum_magnitude,
    misconceptions_whole_number_batch_1:picks_by_digit_sum,
    298-511,
    511).

% === row 39500: random operator choice on surface cue ===
test_harness:arith_misconception(db_row(39500), whole_number, too_vague,
    skip, none, none).

% === row 39540: mental overload on many large addends ===
test_harness:arith_misconception(db_row(39540), whole_number, too_vague,
    skip, none, none).

% === row 39558: smaller / larger "can't be done" (no numeric output) ===
test_harness:arith_misconception(db_row(39558), whole_number, too_vague,
    skip, none, none).

% === row 39574: discrete vs continuous number lines (no numeric error) ===
test_harness:arith_misconception(db_row(39574), whole_number, too_vague,
    skip, none, none).

% === row 39646: ignores zero in a product ===
% Task: 76 * 34 * 0 * 17
% Error: 43928 (student drops the zero and multiplies the rest)
% Correct: 0
% Input is the list of factors.
% SCHEMA: TODO — multiplication by zero
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(ignore_zero_in_product)))
ignores_zero_in_product(L, Got) :-
    exclude(=(0), L, Filtered),
    product_list(Filtered, 1, Got).

product_list([], Acc, Acc).
product_list([X|Xs], Acc, P) :-
    Acc1 is Acc * X,
    product_list(Xs, Acc1, P).

test_harness:arith_misconception(db_row(39646), whole_number, ignore_zero_in_product,
    misconceptions_whole_number_batch_1:ignores_zero_in_product,
    [76,34,0,17],
    0).

% === row 39691: rounds in the wrong direction ===
% Task: round 306 to nearest ten.
% Error: 300 (rounds down when it should round up)
% Correct: 310
% Input: N-Unit (the number, and the rounding unit).
% SCHEMA: TODO — rounding
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(round_wrong_direction)))
rounds_wrong_direction(N-Unit, Got) :-
    Rem is N mod Unit,
    ( Rem * 2 >= Unit
    -> Got is N - Rem                % should have rounded up, but rounds down
    ; Got is N + (Unit - Rem)        % should have rounded down, but rounds up
    ).

test_harness:arith_misconception(db_row(39691), whole_number, round_wrong_direction,
    misconceptions_whole_number_batch_1:rounds_wrong_direction,
    306-10,
    310).

% === row 39727: extracts common factor, misadjusts remainder ===
% Task: 32 * 24. Student pulls factor of 8 out of both -> 4 * 3 = 12, then
% multiplies by 8 instead of 64.
% Error: 96 (12 * 8)
% Correct: 768
% SCHEMA: TODO — factorization
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(factor_adjust_wrong)))
factor_adjust_wrong(A-B, Got) :-
    % Model: student divides both by 8, multiplies the reduced pair, then
    % multiplies by 8 once (instead of 64).
    A1 is A // 8,
    B1 is B // 8,
    Got is A1 * B1 * 8.

test_harness:arith_misconception(db_row(39727), whole_number, factor_adjust_wrong,
    misconceptions_whole_number_batch_1:factor_adjust_wrong,
    32-24,
    768).

% === row 39747: subtraction-as-addition (counts all) ===
% Task: 6 - 4
% Error: 10 (student counts all balls together)
% Correct: 2
% SCHEMA: TODO — operation meaning
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(minus_as_plus)))
reads_minus_as_plus(A-B, Got) :-
    Got is A + B.

test_harness:arith_misconception(db_row(39747), whole_number, minus_as_plus,
    misconceptions_whole_number_batch_1:reads_minus_as_plus,
    6-4,
    2).

% === row 39841: decomposes additively in multiplicative estimation ===
% Task: 98 * 26
% Error: 98 * 10 + 98 * 10 = 1960 (replaces 26 with 10+10 instead of 20+6)
% Correct: 2548
% SCHEMA: TODO — estimation / distributivity
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(additive_decomp_estimate)))
additive_decomp_estimate(A-_B, Got) :-
    % Student splits B as 10+10 (dropping the remainder) and adds two copies.
    Got is A * 10 + A * 10.

test_harness:arith_misconception(db_row(39841), whole_number, additive_decomp_estimate,
    misconceptions_whole_number_batch_1:additive_decomp_estimate,
    98-26,
    2548).

% === row 39947: fact-table slips (unsystematic) ===
test_harness:arith_misconception(db_row(39947), whole_number, too_vague,
    skip, none, none).

% === row 40018: counting sequence skipping ===
test_harness:arith_misconception(db_row(40018), whole_number, too_vague,
    skip, none, none).

% === row 40044: off-by-one in counting on ===
% Task: 8 + 5 via counting on
% Error: 12 (off-by-one, either undercounts stops or overcounts)
% Correct: 13
% SCHEMA: TODO — counting-on
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(count_on_off_by_one)))
counts_on_off_by_one(A-B, Got) :-
    Got is A + B - 1.

test_harness:arith_misconception(db_row(40044), whole_number, count_on_off_by_one,
    misconceptions_whole_number_batch_1:counts_on_off_by_one,
    8-5,
    13).

% === row 40064: manipulatives without written conversion ===
test_harness:arith_misconception(db_row(40064), whole_number, too_vague,
    skip, none, none).

% === row 40096: teacher over-hears student ===
test_harness:arith_misconception(db_row(40096), whole_number, too_vague,
    skip, none, none).

% === row 40127: loses double count in counting on ===
test_harness:arith_misconception(db_row(40127), whole_number, too_vague,
    skip, none, none).

% === row 40159: single example as proof ===
test_harness:arith_misconception(db_row(40159), whole_number, too_vague,
    skip, none, none).

% === row 40179: division by zero reworded as 0 / 2 ===
test_harness:arith_misconception(db_row(40179), whole_number, too_vague,
    skip, none, none).

% === row 40222: procedural justification in long division ===
test_harness:arith_misconception(db_row(40222), whole_number, too_vague,
    skip, none, none).

% === row 40272: adds two numbers regardless of semantic action ===
% Task: any pair from a story problem that actually requires subtraction.
% Example input 8-3 (takeaway context); student just adds.
% Error: 11 (8 + 3)
% Correct: 5
% SCHEMA: TODO — word-problem default
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(always_add_in_word_problem)))
always_adds_in_word_problem(A-B, Got) :-
    Got is A + B.

test_harness:arith_misconception(db_row(40272), whole_number, always_add_in_word_problem,
    misconceptions_whole_number_batch_1:always_adds_in_word_problem,
    8-3,
    5).

% === row 40310: adjacent comparison only on number-line scales ===
test_harness:arith_misconception(db_row(40310), whole_number, too_vague,
    skip, none, none).

% === row 40327: x / 0 = 0 (pseudo-deductive) ===
test_harness:arith_misconception(db_row(40327), whole_number, too_vague,
    skip, none, none).

% === row 40473: decimal answer for discrete objects ===
% Task: 296 / 24 buses; student gives 12.3.
% Error: we model the floor as the student's final practical answer (12).
% Correct: 13 (ceiling).
% Same underlying error as 37527 but distinct citation.
% SCHEMA: TODO — division with discrete interpretation
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(decimal_for_discrete)))
gives_decimal_for_discrete(A-B, Got) :-
    Got is A div B.

test_harness:arith_misconception(db_row(40473), whole_number, decimal_for_discrete,
    misconceptions_whole_number_batch_1:gives_decimal_for_discrete,
    296-24,
    13).

% === row 40535: multiplication always increases magnitude ===
test_harness:arith_misconception(db_row(40535), whole_number, too_vague,
    skip, none, none).

% === row 40568: base-10 adjust for base-8 (no concrete wrong numeric) ===
% Text: student's wrong procedure happens to land on the correct base-8
% answer (41). No clear wrong numeric output in the example.
test_harness:arith_misconception(db_row(40568), whole_number, too_vague,
    skip, none, none).

% === row 40608: empty number line interpretation ambiguity ===
test_harness:arith_misconception(db_row(40608), whole_number, too_vague,
    skip, none, none).

% === row 40672: uses one addend from labels, ignores dimensions ===
% Task: area of a 6-by-30 sub-region using labels 10+10+10 and 10+10+6.
% Error: 60 (student picks 10 * 6 from one corner of the labels).
% Correct: 180 (6 * 30).
% SCHEMA: TODO — area model / distributivity
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(single_partial_area)))
single_partial_area(A-_B, Got) :-
    % Buggy: student picks an addend from one label (10) and pairs it
    % with the remainder of the other label (A) — effectively A * 10.
    Got is A * 10.

test_harness:arith_misconception(db_row(40672), whole_number, single_partial_area,
    misconceptions_whole_number_batch_1:single_partial_area,
    6-30,
    180).
