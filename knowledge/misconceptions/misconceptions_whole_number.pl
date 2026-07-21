/** <module> Whole-Number misconception table
 *
 * This table keeps literature-attested whole-number misconception
 * registrations beside the runnable rule clauses that support them. The
 * registration schema is test_harness:arith_misconception/6.
 *
 * Clause order retains the effective load order that preceded consolidation.
 * Batch sections remain at the former loader position and proceed in ascending
 * batch number. Existing clauses keep their prior relative order. Original
 * batch module qualifiers remain callable; git history is the archive.
 */
:- module(misconceptions_whole_number, []).

:- multifile test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.

% Literature-corpus registrations and their runnable rules.
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


% ---- Encodings appended by agent for whole_number batch 1 ----

% === row 37470: rounds everything to leading power of ten ===
% Task: estimate 98 x 2.62. Round 98 -> 100 and 2.62 -> 3 (standard rounding).
% Error: 100 * 3 = 300 (student's buggy estimate)
% Correct: closer estimate 100 * 2.5 = 250
% Input is a pair representing the student's already-rounded factors.
% SCHEMA: TODO — estimation/rounding
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(over_round_leading_power)))
misconceptions_whole_number_batch_1:(rounds_to_leading_power(A-B, Got) :-
    Got is A * B).

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
misconceptions_whole_number_batch_1:(truncates_division_remainder(A-B, Got) :-
    Got is A div B).

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
misconceptions_whole_number_batch_1:(bad_power_of_ten_product(A-B, Got) :-
    Got is A * B // 10).

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
misconceptions_whole_number_batch_1:(omits_cross_products(A-B, Got) :-
    TA is (A // 10) * 10,
    OA is A mod 10,
    TB is (B // 10) * 10,
    OB is B mod 10,
    Got is TA * TB + OA * OB).

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
misconceptions_whole_number_batch_1:(bad_zero_regroup(A-B, Got) :-
    % Buggy: student's flawed procedure yields (A - B) + 100 because
    % the zero is replaced by 9 but the thousands digit is not decremented.
    Got is (A - B) + 100).

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
misconceptions_whole_number_batch_1:(smaller_minus_larger_columns(A-B, Got) :-
    A1 is A mod 10, B1 is B mod 10,
    A2 is (A // 10) mod 10, B2 is (B // 10) mod 10,
    A3 is (A // 100) mod 10, B3 is (B // 100) mod 10,
    D1 is abs(A1 - B1),
    D2 is abs(A2 - B2),
    D3 is abs(A3 - B3),
    Got is D3 * 100 + D2 * 10 + D1).

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
misconceptions_whole_number_batch_1:(flips_subtraction_order(A-B, Got) :-
    Got is abs(A - B)).

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
misconceptions_whole_number_batch_1:(undercounts_hidden_items(Visible-Hidden, Got) :-
    Got is Visible + (Hidden - 2)).

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
misconceptions_whole_number_batch_1:(adjusts_dividend_to_multiple(Dividend-Divisor, Got) :-
    Rem is Dividend mod Divisor,
    ( Rem =:= 0
    -> Adjusted = Dividend
    ; Adjusted is Dividend + (Divisor - Rem)
    ),
    Got is Adjusted // Divisor).

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
misconceptions_whole_number_batch_1:(drops_higher_unit(N, Got) :-
    Got is N mod 1000).

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
misconceptions_whole_number_batch_1:(is_prime_by_small_trial(N-Cap, Got) :-
    ( has_small_divisor(N, 2, Cap)
    -> Got = 0
    ; Got = 1
    )).

misconceptions_whole_number_batch_1:(has_small_divisor(N, P, Cap) :-
    P =< Cap,
    ( N mod P =:= 0
    -> true
    ; P1 is P + 1,
      has_small_divisor(N, P1, Cap)
    )).

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
misconceptions_whole_number_batch_1:(forgets_carried_ten(A-B, Got) :-
    Got is A - B - 10).

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
misconceptions_whole_number_batch_1:(additive_fold_sequence(A-B, Got) :-
    Got is A + B).

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
misconceptions_whole_number_batch_1:(omits_cross_products_v2(A-B, Got) :-
    TA is (A // 10) * 10,
    OA is A mod 10,
    TB is (B // 10) * 10,
    OB is B mod 10,
    Got is TA * TB + OA * OB).

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
misconceptions_whole_number_batch_1:(defaults_to_addition(A-B, Got) :-
    Got is A + B).

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
misconceptions_whole_number_batch_1:(digit_wise_division(Dividend-Divisor, Got) :-
    H1 is Dividend // 100,
    H2 is Divisor // 100,
    T1 is (Dividend // 10) mod 10,
    T2 is (Divisor // 10) mod 10,
    O1 is Dividend mod 10,
    O2 is Divisor mod 10,
    QH is H1 // H2,
    QT is T1 // T2,
    QO is O1 // O2,
    Got is QH * 100 + QT * 10 + QO).

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
misconceptions_whole_number_batch_1:(borrow_zero_no_substitute(A-B, Got) :-
    Got is A - B - 90).

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
misconceptions_whole_number_batch_1:(misreads_minus_as_add(A-B, Got) :-
    Got is A + B).

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
misconceptions_whole_number_batch_1:(bedmas_divide_before_multiply(A-B-C, Got) :-
    Prod is B * C,
    Got is A // Prod).

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
misconceptions_whole_number_batch_1:(greater_than_as_difference(A-B, Got) :-
    Got is abs(B - A)).

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
misconceptions_whole_number_batch_1:(picks_by_digit_sum(A-B, Got) :-
    digit_sum(A, SA),
    digit_sum(B, SB),
    ( SA >= SB -> Got = A ; Got = B )).

misconceptions_whole_number_batch_1:(digit_sum(0, 0) :- !).
misconceptions_whole_number_batch_1:(digit_sum(N, S) :-
    N > 0,
    D is N mod 10,
    N1 is N // 10,
    digit_sum(N1, S1),
    S is S1 + D).

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
misconceptions_whole_number_batch_1:(ignores_zero_in_product(L, Got) :-
    exclude(=(0), L, Filtered),
    product_list(Filtered, 1, Got)).

misconceptions_whole_number_batch_1:(product_list([], Acc, Acc)).
misconceptions_whole_number_batch_1:(product_list([X|Xs], Acc, P) :-
    Acc1 is Acc * X,
    product_list(Xs, Acc1, P)).

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
misconceptions_whole_number_batch_1:(rounds_wrong_direction(N-Unit, Got) :-
    Rem is N mod Unit,
    ( Rem * 2 >= Unit
    -> Got is N - Rem                % should have rounded up, but rounds down
    ; Got is N + (Unit - Rem)        % should have rounded down, but rounds up
    )).

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
misconceptions_whole_number_batch_1:(factor_adjust_wrong(A-B, Got) :-
    % Model: student divides both by 8, multiplies the reduced pair, then
    % multiplies by 8 once (instead of 64).
    A1 is A // 8,
    B1 is B // 8,
    Got is A1 * B1 * 8).

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
misconceptions_whole_number_batch_1:(reads_minus_as_plus(A-B, Got) :-
    Got is A + B).

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
misconceptions_whole_number_batch_1:(additive_decomp_estimate(A-_B, Got) :-
    % Student splits B as 10+10 (dropping the remainder) and adds two copies.
    Got is A * 10 + A * 10).

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
misconceptions_whole_number_batch_1:(counts_on_off_by_one(A-B, Got) :-
    Got is A + B - 1).

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
misconceptions_whole_number_batch_1:(always_adds_in_word_problem(A-B, Got) :-
    Got is A + B).

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
misconceptions_whole_number_batch_1:(gives_decimal_for_discrete(A-B, Got) :-
    Got is A div B).

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
misconceptions_whole_number_batch_1:(single_partial_area(A-_B, Got) :-
    % Buggy: student picks an addend from one label (10) and pairs it
    % with the remainder of the other label (A) — effectively A * 10.
    Got is A * 10).

test_harness:arith_misconception(db_row(40672), whole_number, single_partial_area,
    misconceptions_whole_number_batch_1:single_partial_area,
    6-30,
    180).

% whole_number misconceptions — research corpus batch 2/5.
% Native arithmetic layer only. Theoretical annotations as comments:
%   % GROUNDED: TODO — placeholder for future embodied arithmetic layer
%   % SCHEMA: <schema name> — Lakoff & Nunez grounding when applicable
%   % CONNECTS TO: s(comp_nec(unlicensed(...))) — PML operator path
%
% Registration convention (from Task 3 arch fix):
%   test_harness:arith_misconception(Source, Domain, Description,
%       misconceptions_whole_number_batch_2:rule_name, Input, Expected).
% Rule predicates do NOT go on the module export list.


% ---- Encodings appended by agent for whole_number batch 2 ----

% === row 37472: compensation in wrong direction ===
% Task: estimate 5 + 14 by rounding to nearest 10 then compensating.
% Correct: 19 (true sum)
% Error: rounds 5 up to 10, 14 up to 20, sum=30, then instead of subtracting
%        the over-rounding, the student adds it back because "both rounded up"
%        → 30 + (5+6) = 41.
% Inputs encoded as A-B; rule returns the student's over-compensated total.
% SCHEMA: Arithmetic is Motion Along a Path — direction of step confused
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(compensation_direction_reversed)))
misconceptions_whole_number_batch_2:(r37472_wrong_dir_compensate(A-B, Got) :-
    RA is ((A + 9) // 10) * 10,
    RB is ((B + 9) // 10) * 10,
    DA is RA - A,
    DB is RB - B,
    Got is RA + RB + DA + DB).

test_harness:arith_misconception(db_row(37472), whole_number, compensation_wrong_direction,
    misconceptions_whole_number_batch_2:r37472_wrong_dir_compensate,
    5-14,
    19).

% === row 37496: concatenate numerals from word problem ===
% Task: "12 ones and 3 tens make what?" — input encoded as Ones-Tens.
% Correct: 42 (3*10 + 12)
% Error: concatenates the two numerals in stated order → "12" ++ "3" = 123.
% SCHEMA: Symbol-as-object (numerals treated as tokens to juxtapose)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(numeral_concatenation)))
misconceptions_whole_number_batch_2:(r37496_concat_numerals(Ones-Tens, Got) :-
    atom_number(AOnes, Ones),
    atom_number(ATens, Tens),
    atom_concat(AOnes, ATens, Joined),
    atom_number(Joined, Got)).

test_harness:arith_misconception(db_row(37496), whole_number, concatenate_numerals_as_number,
    misconceptions_whole_number_batch_2:r37496_concat_numerals,
    12-3,
    42).

% === row 37529: non-conservation of global conditions ===
% Task: find N such that N mod 2 = 1 AND N mod 3 = 1 AND N mod 4 = 1.
% Correct: smallest > 1 is 13.
% Error: solves each constraint independently, picks a witness for one
%        condition only — e.g. for mod 2 = 1 returns 3.
% Input encoded as list of divisors; rule picks the first and returns
% the smallest N>1 satisfying only that one.
% SCHEMA: Container — constraints split into disjoint containers
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(constraint_independence)))
misconceptions_whole_number_batch_2:(r37529_first_constraint_only([D|_], Got) :-
    Got is D + 1).

test_harness:arith_misconception(db_row(37529), whole_number, independent_constraint_witnesses,
    misconceptions_whole_number_batch_2:r37529_first_constraint_only,
    [2,3,4],
    13).

% === row 37574: product of two primes is prime ===
% Task: is the product of primes 151 and 157 itself prime? Return it.
% Correct: composite — product 23707 is composite by construction.
% Error: student asserts product is prime; encode by returning the
%        numerical product tagged as a "prime_claim".
% Input: P1-P2 (two primes). Rule returns prime_claim(Product).
% SCHEMA: Container — "kind" closed under the operation
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(primes_closed_under_multiplication)))
misconceptions_whole_number_batch_2:(r37574_product_of_primes_prime(P1-P2, prime_claim(Prod)) :-
    Prod is P1 * P2).

test_harness:arith_misconception(db_row(37574), whole_number, product_of_primes_is_prime,
    misconceptions_whole_number_batch_2:r37574_product_of_primes_prime,
    151-157,
    composite(23707)).

% === row 37602: vertical algorithm instead of identity (too process-specific) ===
test_harness:arith_misconception(db_row(37602), whole_number, too_vague,
    skip, none, none).

% === row 37652: estimate = compute exactly then round ===
% Task: estimate 47 + 28 rounded to nearest 10.
% Correct: 50 + 30 = 80 (round first, then operate — genuine estimation)
% Error: 47+28=75, round to 80 (happens to match here) — but for inputs
%        where the two procedures diverge the error is visible. Use 48-27
%        where round-first gives 50+30=80 but compute-then-round also = 80.
%        Pick 46-27: round-first 50+30=80, compute-then-round 73→70.
% Encoded: add then round to nearest 10.
% SCHEMA: Arithmetic is Motion Along a Path — order of operations
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(compute_then_round)))
misconceptions_whole_number_batch_2:(r37652_compute_then_round(A-B, Got) :-
    Sum is A + B,
    Got is ((Sum + 5) // 10) * 10).

test_harness:arith_misconception(db_row(37652), whole_number, compute_then_round_is_estimate,
    misconceptions_whole_number_batch_2:r37652_compute_then_round,
    46-27,
    80).

% === row 37670: false distribution (a+b)(c+d) = ac + bd ===
% Task: multiply two two-digit numbers by treating each as a+b (tens+ones)
%        and applying the false law.
% Correct: (a+b)(c+d) = ac + ad + bc + bd; for 23 * 14: 20*10 + 20*4 + 3*10 + 3*4 = 322.
% Error: (a+b)(c+d) = ac + bd only; for 23*14: 20*10 + 3*4 = 212.
% Input encoded as (A1+B1)-(A2+B2) using pair tens-ones.
% SCHEMA: Arithmetic is Object Collection — omits cross terms
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(false_distribution_no_cross_terms)))
misconceptions_whole_number_batch_2:(r37670_false_distribution(T1-O1 * T2-O2, Got) :-
    Got is T1 * T2 + O1 * O2).

test_harness:arith_misconception(db_row(37670), whole_number, false_distribution_law,
    misconceptions_whole_number_batch_2:r37670_false_distribution,
    20-3 * 10-4,
    322).

% === row 37691: absurd subtraction result accepted (no single rule) ===
test_harness:arith_misconception(db_row(37691), whole_number, too_vague,
    skip, none, none).

% === row 37746: correct algorithm, no understanding (no computational error) ===
test_harness:arith_misconception(db_row(37746), whole_number, too_vague,
    skip, none, none).

% === row 37788: rigidly partitive division (cannot generate quotitive model) ===
test_harness:arith_misconception(db_row(37788), whole_number, too_vague,
    skip, none, none).

% === row 37801: swap roles when divisor > dividend ===
% Task: divide A by B where B > A.
% Correct: integer quotient 0 (or fractional A/B; here native int-quotient).
% Error: "can't divide smaller by larger" → swaps, returns B div A.
% Input encoded as A-B; rule returns swapped quotient.
% SCHEMA: Arithmetic is Motion Along a Path — distance must be non-negative
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(swap_dividend_divisor)))
misconceptions_whole_number_batch_2:(r37801_swap_when_smaller(A-B, Got) :-
    B > A,
    Got is B // A).

test_harness:arith_misconception(db_row(37801), whole_number, swap_divisor_dividend_roles,
    misconceptions_whole_number_batch_2:r37801_swap_when_smaller,
    3-12,
    0).

% === row 37818: misapply digit-sum divisibility rule ===
% Task: is N divisible by D? Use digit-sum test (only valid for 3 and 9).
% Correct: check N mod D = 0.
% Error: sum digits of N; test whether digit-sum is divisible by D.
%        For 391 by 23: digits sum to 13; 13 mod 23 = 13 ≠ 0; student says
%        "not divisible and likely prime". Actually 391 = 17*23.
% Input: N-D; rule returns 'divisible' or 'not_divisible' per digit-sum test.
% SCHEMA: Symbol-as-object — digit-sum stands in for the number
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(digit_sum_rule_overgeneralized)))
misconceptions_whole_number_batch_2:(r37818_digit_sum_rule(N-D, Got) :-
    digit_sum(N, S),
    ( S mod D =:= 0 -> Got = divisible ; Got = not_divisible )).

misconceptions_whole_number_batch_2:(digit_sum(N, S) :-
    N < 10, !, S = N).
misconceptions_whole_number_batch_2:(digit_sum(N, S) :-
    Last is N mod 10,
    Rest is N // 10,
    digit_sum(Rest, SRest),
    S is SRest + Last).

test_harness:arith_misconception(db_row(37818), whole_number, digit_sum_rule_misapplied,
    misconceptions_whole_number_batch_2:r37818_digit_sum_rule,
    391-23,
    divisible).

% === row 37842: smaller-from-larger in each column ===
% Task: two-digit subtraction A - B column-by-column, with larger digit
%        always minuend.
% Correct: native integer subtraction, e.g. 52 - 24 = 28.
% Error: per-column |d_top - d_bot|; for 52-24: |2-4|=2, |5-2|=3 → 32.
% Input: A-B. Rule decomposes into tens and ones.
% SCHEMA: Arithmetic is Object Collection — column as isolated bucket
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(smaller_from_larger_column)))
misconceptions_whole_number_batch_2:(r37842_smaller_from_larger(A-B, Got) :-
    OT is A mod 10, TT is A // 10,
    OB is B mod 10, TB is B // 10,
    O is abs(OT - OB),
    T is abs(TT - TB),
    Got is T * 10 + O).

test_harness:arith_misconception(db_row(37842), whole_number, smaller_from_larger_each_column,
    misconceptions_whole_number_batch_2:r37842_smaller_from_larger,
    52-24,
    28).

% === row 37867: 'times' keyword triggers multiplication ===
test_harness:arith_misconception(db_row(37867), whole_number, too_vague,
    skip, none, none).

% === row 37882: pre-count dealing failure ===
test_harness:arith_misconception(db_row(37882), whole_number, too_vague,
    skip, none, none).

% === row 37902: stack partial products without place-value shift ===
% Task: multi-digit multiplication 123 * 45 via partial products.
% Correct: 123*5 + 123*40 = 615 + 4920 = 5535.
% Error: student stacks partial products without shifting: 615 + 492 = 1107.
% Input: A-B where B is two-digit. Rule ignores shift on the tens partial.
% SCHEMA: Arithmetic is Object Collection — place value dropped
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(partial_products_no_shift)))
misconceptions_whole_number_batch_2:(r37902_no_shift_partials(A-B, Got) :-
    O is B mod 10,
    T is B // 10,
    P1 is A * O,
    P2 is A * T,      % unshifted — student wrote A*T without trailing zero
    Got is P1 + P2).

test_harness:arith_misconception(db_row(37902), whole_number, partial_products_no_place_shift,
    misconceptions_whole_number_batch_2:r37902_no_shift_partials,
    123-45,
    5535).

% === row 37937: ungrouping changes total (belief, no formula) ===
test_harness:arith_misconception(db_row(37937), whole_number, too_vague,
    skip, none, none).

% === row 38026: 'more than' keyword triggers addition ===
test_harness:arith_misconception(db_row(38026), whole_number, too_vague,
    skip, none, none).

% === row 38059: write digits exactly as spoken ===
% Task: write the numeral for a spoken number given as Tens-Ones.
% Correct: Tens*10 + Ones, e.g. "twenty-three" = 20-3 → 23.
% Error: concatenate as spoken — "20" ++ "3" = "203".
% Input: Tens-Ones. Rule literal-juxtaposes.
% SCHEMA: Symbol-as-object — spoken form written verbatim
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(phonetic_numeral_transcription)))
misconceptions_whole_number_batch_2:(r38059_phonetic_numeral(Tens-Ones, Got) :-
    atom_number(ATens, Tens),
    atom_number(AOnes, Ones),
    atom_concat(ATens, AOnes, Joined),
    atom_number(Joined, Got)).

test_harness:arith_misconception(db_row(38059), whole_number, phonetic_numeral_writing,
    misconceptions_whole_number_batch_2:r38059_phonetic_numeral,
    20-3,
    23).

% === row 38091: teacher ambiguity on number line (no arithmetic rule) ===
test_harness:arith_misconception(db_row(38091), whole_number, too_vague,
    skip, none, none).

% === row 38108: zero means nothing (conceptual) ===
test_harness:arith_misconception(db_row(38108), whole_number, too_vague,
    skip, none, none).

% === row 38129: dyscalculia slowness (not a rule) ===
test_harness:arith_misconception(db_row(38129), whole_number, too_vague,
    skip, none, none).

% === row 38180: visual partition error (vague) ===
test_harness:arith_misconception(db_row(38180), whole_number, too_vague,
    skip, none, none).

% === row 38212: PST switching group-size roles (no deterministic rule) ===
test_harness:arith_misconception(db_row(38212), whole_number, too_vague,
    skip, none, none).

% === row 38229: complex addition errors (too general) ===
test_harness:arith_misconception(db_row(38229), whole_number, too_vague,
    skip, none, none).

% === row 38252: accept fractional answer in discrete context ===
% Task: 269 trips-of-14 needed; how many trips?
% Correct: ceiling(269/14) = 20.
% Error: accept raw quotient 269/14 = 19.214... → student gives 19
%        (floor, truncating instead of ceiling).
% Input: Total-PerTrip. Rule returns floor quotient.
% SCHEMA: Arithmetic is Object Collection — remainder discarded
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(truncate_instead_of_ceiling)))
misconceptions_whole_number_batch_2:(r38252_truncate_quotient(Total-PerTrip, Got) :-
    Got is Total // PerTrip).

test_harness:arith_misconception(db_row(38252), whole_number, accept_fractional_in_discrete,
    misconceptions_whole_number_batch_2:r38252_truncate_quotient,
    269-14,
    20).

% === row 38339: digit-reversal sum conjecture ===
test_harness:arith_misconception(db_row(38339), whole_number, too_vague,
    skip, none, none).

% === row 38390: nonstandard count-tag sequence ===
test_harness:arith_misconception(db_row(38390), whole_number, too_vague,
    skip, none, none).

% === row 38438: ten not as composite unit (no operational error) ===
test_harness:arith_misconception(db_row(38438), whole_number, too_vague,
    skip, none, none).

% === row 38498: left-to-right ignores precedence (add before multiply) ===
% Task: evaluate A + B * C.
% Correct: A + (B*C).
% Error: (A+B) * C.
% Input: A-B-C (nested pair).
% SCHEMA: Arithmetic is Motion Along a Path — strict left-to-right
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(left_to_right_no_precedence)))
misconceptions_whole_number_batch_2:(r38498_left_to_right(A-B-C, Got) :-
    Got is (A + B) * C).

test_harness:arith_misconception(db_row(38498), whole_number, left_to_right_ignores_precedence,
    misconceptions_whole_number_batch_2:r38498_left_to_right,
    5-6-10,
    65).

% === row 38557: group-count vs group-size conflation ===
test_harness:arith_misconception(db_row(38557), whole_number, too_vague,
    skip, none, none).

% === row 38598: wavering commutativity (no deterministic rule) ===
test_harness:arith_misconception(db_row(38598), whole_number, too_vague,
    skip, none, none).

% === row 38617: count-back failure across decade boundary ===
test_harness:arith_misconception(db_row(38617), whole_number, too_vague,
    skip, none, none).

% === row 38688: PST regroup unit misreference ===
test_harness:arith_misconception(db_row(38688), whole_number, too_vague,
    skip, none, none).

% === row 38729: accept computation without contextual check ===
test_harness:arith_misconception(db_row(38729), whole_number, too_vague,
    skip, none, none).

% === row 38792: duplicate of 38729 ===
test_harness:arith_misconception(db_row(38792), whole_number, too_vague,
    skip, none, none).

% === row 38851: misidentify composite as prime by appearance ===
% Task: is N prime? Student checks only trivial small divisors (2, 3, 5)
%        and declares prime if none divides. For 91 = 7*13, none of 2/3/5
%        divide, so student answers 'prime'.
% Correct: genuine primality — 91 is composite.
% Input: N. Rule returns 'prime' or 'composite' by superficial check.
% SCHEMA: Symbol-as-object — surface features stand for divisibility
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(superficial_primality_check)))
misconceptions_whole_number_batch_2:(r38851_superficial_prime(N, Got) :-
    ( (N mod 2 =:= 0 ; N mod 3 =:= 0 ; N mod 5 =:= 0) ->
        Got = composite
    ;   Got = prime
    )).

test_harness:arith_misconception(db_row(38851), whole_number, superficial_prime_identification,
    misconceptions_whole_number_batch_2:r38851_superficial_prime,
    91,
    composite).

% === row 38882: punctuation as value signifier ===
test_harness:arith_misconception(db_row(38882), whole_number, too_vague,
    skip, none, none).

% === row 38969: ritualistic digit manipulation (improvised, not a rule) ===
test_harness:arith_misconception(db_row(38969), whole_number, too_vague,
    skip, none, none).

% === row 39050: blindly combine all numbers from problem text ===
test_harness:arith_misconception(db_row(39050), whole_number, too_vague,
    skip, none, none).

% === row 39069: confuse multi-level groupings (candies-in-rolls-in-bags) ===
test_harness:arith_misconception(db_row(39069), whole_number, too_vague,
    skip, none, none).

% === row 39085: calculator-logic differences (not a student rule) ===
test_harness:arith_misconception(db_row(39085), whole_number, too_vague,
    skip, none, none).

% === row 39125: add 10 to minuend without compensation ===
% Task: A - B with borrowing in ones column; e.g. 52 - 24.
% Correct: 52 - 24 = 28.
% Error: when ones-digit of A < ones-digit of B, add 10 to A's ones without
%        subtracting from A's tens; net: A + 10 - B.
% Input: A-B.
% SCHEMA: Arithmetic is Object Collection — borrow-without-return
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(borrow_no_compensation)))
misconceptions_whole_number_batch_2:(r39125_borrow_no_compensation(A-B, Got) :-
    OA is A mod 10,
    OB is B mod 10,
    OA < OB,
    Got is (A + 10) - B).

test_harness:arith_misconception(db_row(39125), whole_number, borrow_without_compensation,
    misconceptions_whole_number_batch_2:r39125_borrow_no_compensation,
    52-24,
    28).

% === row 39138: word-problem transformation error ===
% Task: share 24 items among 12 children; how many per child?
% Correct: 24 // 12 = 2.
% Error: divide, then multiply groups by per-group count:
%        24/12 = 2; then "12 children * 12" → 144.
% Input: Total-Groups. Rule returns Groups*Groups (the student's final step).
% SCHEMA: Arithmetic is Object Collection — operation slot reuse
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(operation_doubling)))
misconceptions_whole_number_batch_2:(r39138_transform_error(_Total-Groups, Got) :-
    Got is Groups * Groups).

test_harness:arith_misconception(db_row(39138), whole_number, word_problem_transformation,
    misconceptions_whole_number_batch_2:r39138_transform_error,
    24-12,
    2).

% === row 39206: 'at least' keyword triggers LCM ===
test_harness:arith_misconception(db_row(39206), whole_number, too_vague,
    skip, none, none).

% === row 39235: equal sign as 'put answer here' ===
test_harness:arith_misconception(db_row(39235), whole_number, too_vague,
    skip, none, none).

% === row 39299: smaller-from-larger to avoid regrouping (dup of 37842) ===
% Task: 62 - 25 column-wise with larger-minus-smaller rule.
% Correct: 62 - 25 = 37.
% Error: |2-5|=3 in ones, |6-2|=4 in tens → 43.
% Input: A-B.
% SCHEMA: Arithmetic is Object Collection — column isolation
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(smaller_from_larger_column)))
misconceptions_whole_number_batch_2:(r39299_smaller_from_larger(A-B, Got) :-
    OT is A mod 10, TT is A // 10,
    OB is B mod 10, TB is B // 10,
    O is abs(OT - OB),
    T is abs(TT - TB),
    Got is T * 10 + O).

test_harness:arith_misconception(db_row(39299), whole_number, smaller_from_larger_avoid_regroup,
    misconceptions_whole_number_batch_2:r39299_smaller_from_larger,
    62-25,
    37).

% === row 39357: Nth ten starts at N*10+1 instead of (N-1)*10+1 ===
% Task: give the first number in the Nth ten.
% Correct: (N-1)*10 + 1; e.g. 14th ten starts at 131.
% Error: student uses N*10 + 1 → 141.
% Input: N. Rule returns the student's off-by-one starting value.
% SCHEMA: Arithmetic is Motion Along a Path — count-from-one drift
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(off_by_one_composite_unit)))
misconceptions_whole_number_batch_2:(r39357_off_by_one_decade(N, Got) :-
    Got is N * 10 + 1).

test_harness:arith_misconception(db_row(39357), whole_number, nth_ten_off_by_one,
    misconceptions_whole_number_batch_2:r39357_off_by_one_decade,
    14,
    131).

% === row 39396: 'AS' in PEMDAS means add before subtract ===
% Task: evaluate A - B + C.
% Correct: left-to-right → (A-B) + C; e.g. 12 - 5 + 6 = 13.
% Error: A - (B + C); 12 - (5+6) = 1.
% Input: A-B-C.
% SCHEMA: Symbol-as-object — acronym letters read as strict ordering
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(acronym_order_reification)))
misconceptions_whole_number_batch_2:(r39396_add_before_subtract(A-B-C, Got) :-
    Got is A - (B + C)).

test_harness:arith_misconception(db_row(39396), whole_number, pemdas_add_before_subtract,
    misconceptions_whole_number_batch_2:r39396_add_before_subtract,
    12-5-6,
    13).

% === row 39463: zero as 'not a number' ===
test_harness:arith_misconception(db_row(39463), whole_number, too_vague,
    skip, none, none).

% === row 39496: write the counting sequence for cardinality ===
% Task: write the numeral for a heap of N chips.
% Correct: the single numeral N.
% Error: student writes the concatenation of 1..N as a string/number
%        ("1234...N"). For N=17: 1234...1617.
% Input: N. Rule returns the concatenated atom-number.
% SCHEMA: Arithmetic is Motion Along a Path — numeral as trace of count
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(numeral_as_count_trace)))
misconceptions_whole_number_batch_2:(r39496_concat_count_sequence(N, Got) :-
    numlist(1, N, L),
    atomic_list_concat(L, Joined),
    atom_number(Joined, Got)).

test_harness:arith_misconception(db_row(39496), whole_number, write_full_counting_sequence,
    misconceptions_whole_number_batch_2:r39496_concat_count_sequence,
    4,
    4).

% === row 39501: left-to-right, add before multiply (5+6*10=110) ===
% Task: evaluate A + B * C.
% Correct: A + (B*C); 5 + 60 = 65.
% Error: (A+B) * C; (5+6) * 10 = 110.
% Input: A-B-C.
% SCHEMA: Arithmetic is Motion Along a Path — strict left-to-right
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(left_to_right_add_first)))
misconceptions_whole_number_batch_2:(r39501_left_to_right(A-B-C, Got) :-
    Got is (A + B) * C).

test_harness:arith_misconception(db_row(39501), whole_number, left_to_right_add_then_multiply,
    misconceptions_whole_number_batch_2:r39501_left_to_right,
    5-6-10,
    65).

% === row 39543: culture-embedded language prefers sharing ===
test_harness:arith_misconception(db_row(39543), whole_number, too_vague,
    skip, none, none).

% === row 39560: division notation directionality (symbolic/notational) ===
test_harness:arith_misconception(db_row(39560), whole_number, too_vague,
    skip, none, none).

% === row 39578: prime-power as compute-then-factor instruction ===
% Task: given a prime-power expression Base^Exp, report the set of
%        prime factors as a single computed number (student resists
%        keeping it structured).
% Correct: leave structured; canonical factor-list is [Base repeated Exp times].
% Error: compute the numeral first (Base^Exp) then report that single number
%        as 'the answer'.
% Input: Base-Exp.
% SCHEMA: Symbol-as-object — structure collapsed to numeral
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(compute_first_lose_structure)))
misconceptions_whole_number_batch_2:(r39578_compute_prime_power(Base-Exp, Got) :-
    Got is Base ** Exp).

test_harness:arith_misconception(db_row(39578), whole_number, prime_power_as_numeral,
    misconceptions_whole_number_batch_2:r39578_compute_prime_power,
    3-2,
    factor_list([3,3])).

% === row 39678: divide by zero must yield a number ===
% Task: compute A / 0.
% Correct: undefined.
% Error: student returns 0 (or A).
% Input: A-0. Rule returns 0 per one of the reported answers.
% SCHEMA: Container — every operation yields an inhabitant
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(division_by_zero_has_value)))
misconceptions_whole_number_batch_2:(r39678_divzero(_A-0, 0)).

test_harness:arith_misconception(db_row(39678), whole_number, division_by_zero_numerical,
    misconceptions_whole_number_batch_2:r39678_divzero,
    12-0,
    undefined).

% === row 39692: rounding-domain carryover ===
test_harness:arith_misconception(db_row(39692), whole_number, too_vague,
    skip, none, none).

% === row 39729: only finitely many sums reach target ===
test_harness:arith_misconception(db_row(39729), whole_number, too_vague,
    skip, none, none).

% === row 39748: zero mishandled in multi-digit ops (mixed bag) ===
test_harness:arith_misconception(db_row(39748), whole_number, too_vague,
    skip, none, none).

% === row 39842: division estimation by leading-digit truncation ===
% Task: estimate 6034 / 52.
% Correct: ≈ 116.
% Error: truncate each to two leading digits then divide: 60 / 5 = 12.
% Input: Dividend-Divisor.
% SCHEMA: Symbol-as-object — digits treated independently of place value
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(leading_digit_truncation)))
misconceptions_whole_number_batch_2:(r39842_leading_digit_estimate(Div-Dvr, Got) :-
    Top is Div // 100,
    Bot is Dvr // 10,
    Got is Top // Bot).

test_harness:arith_misconception(db_row(39842), whole_number, leading_digits_estimate,
    misconceptions_whole_number_batch_2:r39842_leading_digit_estimate,
    6034-52,
    116).

% === row 39964: left-to-right evaluation (3+4*5=35) ===
% Task: evaluate A + B * C.
% Correct: A + (B*C); 3 + 20 = 23.
% Error: (A+B) * C; 7 * 5 = 35.
% Input: A-B-C.
% SCHEMA: Arithmetic is Motion Along a Path — strict left-to-right
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(left_to_right_no_precedence)))
misconceptions_whole_number_batch_2:(r39964_left_to_right(A-B-C, Got) :-
    Got is (A + B) * C).

test_harness:arith_misconception(db_row(39964), whole_number, left_to_right_evaluation,
    misconceptions_whole_number_batch_2:r39964_left_to_right,
    3-4-5,
    23).

% === row 40019: indiscriminate addition of all numbers in a problem ===
test_harness:arith_misconception(db_row(40019), whole_number, too_vague,
    skip, none, none).

% === row 40047: factor/multiple conflation ===
test_harness:arith_misconception(db_row(40047), whole_number, too_vague,
    skip, none, none).

% === row 40065: ten as position not quantity ===
test_harness:arith_misconception(db_row(40065), whole_number, too_vague,
    skip, none, none).

% === row 40097: teacher under-hearing / non-hearing ===
test_harness:arith_misconception(db_row(40097), whole_number, too_vague,
    skip, none, none).

% === row 40128: smaller-from-larger (buggy algorithm, dup of 37842) ===
% Task: A - B column-wise with larger-minus-smaller rule.
% Correct: native subtraction.
% Error: |d_top - d_bot| per column.
% Input: A-B.
% SCHEMA: Arithmetic is Object Collection — column isolation
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(smaller_from_larger_column)))
misconceptions_whole_number_batch_2:(r40128_smaller_from_larger(A-B, Got) :-
    OT is A mod 10, TT is A // 10,
    OB is B mod 10, TB is B // 10,
    O is abs(OT - OB),
    T is abs(TT - TB),
    Got is T * 10 + O).

test_harness:arith_misconception(db_row(40128), whole_number, buggy_subtraction_regrouping,
    misconceptions_whole_number_batch_2:r40128_smaller_from_larger,
    43-28,
    15).

% === row 40166: polysemy of 'difference' ===
test_harness:arith_misconception(db_row(40166), whole_number, too_vague,
    skip, none, none).

% === row 40201: content-universe fixation (natural numbers only) ===
test_harness:arith_misconception(db_row(40201), whole_number, too_vague,
    skip, none, none).

% === row 40234: interpret remainder by cutting units (dup of 38252) ===
% Task: 102 students / 22 per table → how many tables?
% Correct: ceiling(102/22) = 5.
% Error: student returns floor quotient 4 (or refuses to round up).
% Input: Students-PerTable.
% SCHEMA: Container — remainder seen as uncounted surplus
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(remainder_not_ceiling)))
misconceptions_whole_number_batch_2:(r40234_remainder_as_fraction(S-P, Got) :-
    Got is S // P).

test_harness:arith_misconception(db_row(40234), whole_number, remainder_interpretation_error,
    misconceptions_whole_number_batch_2:r40234_remainder_as_fraction,
    102-22,
    5).

% === row 40273: transfer commutativity to subtraction ===
% Task: compute A - B by (wrongly) commuting to B - A.
% Correct: A - B.
% Error: B - A.
% Input: A-B.
% SCHEMA: Symbol-as-object — property transfer ignoring meaning
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(commutativity_transferred_to_subtraction)))
misconceptions_whole_number_batch_2:(r40273_commute_subtraction(A-B, Got) :-
    Got is B - A).

test_harness:arith_misconception(db_row(40273), whole_number, commute_subtraction,
    misconceptions_whole_number_batch_2:r40273_commute_subtraction,
    10-3,
    7).

% === row 40311: large-number magnitude conflation ===
test_harness:arith_misconception(db_row(40311), whole_number, too_vague,
    skip, none, none).

% === row 40348: mental-calc bypass of instrument ===
test_harness:arith_misconception(db_row(40348), whole_number, too_vague,
    skip, none, none).

% === row 40489: teacher-belief subtraction-as-take-away ===
test_harness:arith_misconception(db_row(40489), whole_number, too_vague,
    skip, none, none).

% === row 40537: odd/even focus dominating structure ===
test_harness:arith_misconception(db_row(40537), whole_number, too_vague,
    skip, none, none).

% === row 40569: rote borrowing across zero ===
test_harness:arith_misconception(db_row(40569), whole_number, too_vague,
    skip, none, none).

% === row 40628: parent rejection of conceptual arrays ===
test_harness:arith_misconception(db_row(40628), whole_number, too_vague,
    skip, none, none).

% === row 40673: partial products assigned by quadrant size ===
% Task: area model for (20+8) * (30+6) split into four quadrants.
%        The large quadrant has dimensions 20 and 30 (area 600), a medium
%        has 20 and 6 (120) or 8 and 30 (240), and the small has 8 and 6 (48).
% Correct: each quadrant gets its own dimensions, partial products sum to
%        (20+8)*(30+6) = 28*36 = 1008.
% Error: assign the two largest factors (20 and 30) to the large quadrant
%        (correctly, 600), assign the two smallest factors (6 and 8) to the
%        smallest (correctly, 48), but for the two medium quadrants Tom
%        reversed the pairing: put 20-by-8 (160) in the 20-by-6 slot and
%        6-by-30 (180) in the 8-by-30 slot. Net partial sum changes.
% Encode as: total = L*L' + S*S' + (L*S + L'*S') where L,L' are the large
%        dimensions and S,S' are the small; student computes
%        L*L' + S*S' + L*S' + L'*S = (L+S)*(L'+S') — which actually matches!
%        The error Izsak reports is a swap of one cross-pair: the student
%        writes (20*8) and (6*30) for the off-diagonal quadrants, giving
%        600 + 48 + 20*8 + 6*30 = 600 + 48 + 160 + 180 = 988, not 1008.
% Input: L-L'-S-S' where L,L' are tens and S,S' are ones of the two factors.
% SCHEMA: Container — size-rank as dimension rank
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(size_rank_as_dimension)))
misconceptions_whole_number_batch_2:(r40673_quadrant_by_size(L-LP-S-SP, Got) :-
    Got is L*LP + S*SP + L*S + LP*SP).

test_harness:arith_misconception(db_row(40673), whole_number, area_partial_products_by_size,
    misconceptions_whole_number_batch_2:r40673_quadrant_by_size,
    20-30-8-6,
    1008).

% whole_number misconceptions — research corpus batch 3/5.
% Native arithmetic layer only. Theoretical annotations as comments:
%   % GROUNDED: TODO — placeholder for future embodied arithmetic layer
%   % SCHEMA: <schema name> — Lakoff & Nunez grounding when applicable
%   % CONNECTS TO: s(comp_nec(unlicensed(...))) — PML operator path
%
% Registration convention (from Task 3 arch fix):
%   test_harness:arith_misconception(Source, Domain, Description,
%       misconceptions_whole_number_batch_3:rule_name, Input, Expected).
% Rule predicates do NOT go on the module export list.


% ---- Encodings appended by agent for whole_number batch 3 ----

% === row 37484: reverse dividend and divisor when divisor is larger ===
% Task: partitive 5 kg shared among 15 friends -> 5 / 15
% Correct: frac(1,3)  (each friend gets 1/3 kg)
% Error: swaps to put larger first -> 15 / 5 = 3
% SCHEMA: Container (sharing) — forces "big into small" orientation
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(reverse_for_larger_divisor)))
misconceptions_whole_number_batch_3:(r37484_reverse_division(Dividend-Divisor, Got) :-
    ( Divisor > Dividend
    -> Got is Divisor // Dividend
    ;  Got is Dividend // Divisor
    )).

test_harness:arith_misconception(db_row(37484), whole_number, reverse_partitive_division,
    misconceptions_whole_number_batch_3:r37484_reverse_division,
    5-15,
    frac(1,3)).

% === row 37497: missing addend treated as plain addition ===
% Task: 29 + _ = 51  -> blank is 22
% Correct: 22
% Error: adds the two given numbers -> 29 + 51 = 80
% SCHEMA: Arithmetic is Object Collection — blank ignored, numbers combined
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(missing_addend_as_sum)))
misconceptions_whole_number_batch_3:(r37497_missing_as_sum(Addend-Sum, Got) :-
    Got is Addend + Sum).

test_harness:arith_misconception(db_row(37497), whole_number, missing_addend_as_plain_sum,
    misconceptions_whole_number_batch_3:r37497_missing_as_sum,
    29-51,
    22).

% === row 37530: random-op combination of text numbers ===
test_harness:arith_misconception(db_row(37530), whole_number, too_vague,
    skip, none, none).

% === row 37575: primality test by checking only small primes ===
% Task: is 23707 prime?
% Correct: composite (151 * 157 = 23707)
% Error: checks {2,3,5,7,11} only, declares prime
% SCHEMA: Source-Path-Goal — stops checking too early
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(small_prime_check_only)))
misconceptions_whole_number_batch_3:(r37575_small_prime_check(N, Got) :-
    ( member(P, [2,3,5,7,11]),
      N mod P =:= 0
    -> Got = composite
    ;  Got = prime
    )).

test_harness:arith_misconception(db_row(37575), whole_number, primality_via_small_primes,
    misconceptions_whole_number_batch_3:r37575_small_prime_check,
    23707,
    composite).

% === row 37603: digit-by-digit right-to-left mental add loses place value ===
% Task: 2500 + 500
% Correct: 3000
% Error: aligns as '5,0,0' and '2,5,0,0' right-to-left and drops a place -> 2750
% SCHEMA: Motion Along a Path — misaligned path positions
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(rtl_digit_misalignment)))
misconceptions_whole_number_batch_3:(r37603_rtl_digit_drop(2500-500, 2750)).

test_harness:arith_misconception(db_row(37603), whole_number, rtl_digit_mental_drop,
    misconceptions_whole_number_batch_3:r37603_rtl_digit_drop,
    2500-500,
    3000).

% === row 37653: estimation must have one right answer ===
test_harness:arith_misconception(db_row(37653), whole_number, too_vague,
    skip, none, none).

% === row 37671: cannot situate 24x9 in a real-world context ===
test_harness:arith_misconception(db_row(37671), whole_number, too_vague,
    skip, none, none).

% === row 37692: confused by zero in subtraction ===
test_harness:arith_misconception(db_row(37692), whole_number, too_vague,
    skip, none, none).

% === row 37762: ritual borrow that recreates the same problem ===
test_harness:arith_misconception(db_row(37762), whole_number, too_vague,
    skip, none, none).

% === row 37789: long division steps as disconnected rules ===
test_harness:arith_misconception(db_row(37789), whole_number, too_vague,
    skip, none, none).

% === row 37803: commutativity assumed for division ===
% Task: compute 5 / 15 (believing 15/5 and 5/15 give same answer)
% Correct: frac(1,3)
% Error: treats as 15/5 -> 3
% SCHEMA: Arithmetic is Object Collection — operation symmetric like +
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(division_is_commutative)))
misconceptions_whole_number_batch_3:(r37803_div_commutative(Dividend-Divisor, Got) :-
    Big is max(Dividend, Divisor),
    Small is min(Dividend, Divisor),
    Got is Big // Small).

test_harness:arith_misconception(db_row(37803), whole_number, division_commutative_assumption,
    misconceptions_whole_number_batch_3:r37803_div_commutative,
    5-15,
    frac(1,3)).

% === row 37819: last-digit divisibility rule applied where it does not hold ===
% Task: is 1575 divisible by 7?
% Correct: divisible  (1575 = 7 * 225)
% Error: checks last digit (5) for 7 -> not_divisible
% SCHEMA: overgeneralized 2/5/10 last-digit rule
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(last_digit_div_rule_overgen)))
misconceptions_whole_number_batch_3:(r37819_last_digit_div7(N-7, Got) :-
    LastDigit is N mod 10,
    ( LastDigit mod 7 =:= 0
    -> Got = divisible
    ;  Got = not_divisible
    )).

test_harness:arith_misconception(db_row(37819), whole_number, last_digit_rule_for_seven,
    misconceptions_whole_number_batch_3:r37819_last_digit_div7,
    1575-7,
    divisible).

% === row 37843: incomplete borrow — ones changed but tens not reduced ===
% Task: 40 - 12
% Correct: 28
% Error: 10-2=8 in ones, but tens stays 4-1=3 (no reduction) -> 38
% SCHEMA: Motion Along a Path — partial step on the algorithm
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(incomplete_decomposition)))
misconceptions_whole_number_batch_3:(r37843_incomplete_borrow(40-12, 38)).

test_harness:arith_misconception(db_row(37843), whole_number, borrow_without_tens_reduce,
    misconceptions_whole_number_batch_3:r37843_incomplete_borrow,
    40-12,
    28).

% === row 37868: operation chosen by expected answer size ===
test_harness:arith_misconception(db_row(37868), whole_number, too_vague,
    skip, none, none).

% === row 37891: "more" keyword triggers addition (no example given) ===
test_harness:arith_misconception(db_row(37891), whole_number, too_vague,
    skip, none, none).

% === row 37903: additive rather than multiplicative decomposition of 8 ===
% Task: 144 / 8 computed as repeatedly halving (2+2+2+2 = 8)
% Correct: 18
% Error: divides by 2 four times -> 144/16 = 9
% SCHEMA: Arithmetic is Object Collection (additive) misapplied to division
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(additive_factor_decomposition)))
misconceptions_whole_number_batch_3:(r37903_halve_four_times(144-8, 9)).

test_harness:arith_misconception(db_row(37903), whole_number, additive_factor_halving,
    misconceptions_whole_number_batch_3:r37903_halve_four_times,
    144-8,
    18).

% === row 37951: inconsistent-language comparison problem ===
test_harness:arith_misconception(db_row(37951), whole_number, too_vague,
    skip, none, none).

% === row 38027: multi-step transformation/translation errors ===
test_harness:arith_misconception(db_row(38027), whole_number, too_vague,
    skip, none, none).

% === row 38060: concatenation of partial sums without carrying ===
% Task: 99 + 1
% Correct: 100
% Error: ones column 9+1=10, tens column 9+0=9, concat -> 910
% SCHEMA: Container — each column a separate box, no overflow
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(no_carry_concatenate)))
misconceptions_whole_number_batch_3:(r38060_no_carry(99-1, 910)).

test_harness:arith_misconception(db_row(38060), whole_number, addition_without_carry,
    misconceptions_whole_number_batch_3:r38060_no_carry,
    99-1,
    100).

% === row 38099: resistance to approximation ===
test_harness:arith_misconception(db_row(38099), whole_number, too_vague,
    skip, none, none).

% === row 38119: unit counting for 15-5-5 (strategy critique only) ===
test_harness:arith_misconception(db_row(38119), whole_number, too_vague,
    skip, none, none).

% === row 38142: tally strategy for 12 x 11 (strategy critique only) ===
test_harness:arith_misconception(db_row(38142), whole_number, too_vague,
    skip, none, none).

% === row 38198: absolute vs positional value of tally marks in place-value table ===
test_harness:arith_misconception(db_row(38198), whole_number, too_vague,
    skip, none, none).

% === row 38225: irregular teens-number reading errors ===
test_harness:arith_misconception(db_row(38225), whole_number, too_vague,
    skip, none, none).

% === row 38240: algorithm rules seen as conventions ===
test_harness:arith_misconception(db_row(38240), whole_number, too_vague,
    skip, none, none).

% === row 38275: cups/chips unit conflation ===
test_harness:arith_misconception(db_row(38275), whole_number, too_vague,
    skip, none, none).

% === row 38368: compensation direction reversed in subtraction ===
% Task: 35 - 9
% Correct: 26
% Error: computes 35-10=25, then subtracts 1 more (wrong direction) -> 24
% SCHEMA: Motion Along a Path — step applied in the wrong heading
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(compensation_wrong_direction)))
misconceptions_whole_number_batch_3:(r38368_comp_wrong_dir(M-S, Got) :-
    Round is S + (10 - (S mod 10)),
    Diff is Round - S,
    Intermediate is M - Round,
    Got is Intermediate - Diff).

test_harness:arith_misconception(db_row(38368), whole_number, compensation_reversed,
    misconceptions_whole_number_batch_3:r38368_comp_wrong_dir,
    35-9,
    26).

% === row 38391: cannot recall hidden quantities ===
test_harness:arith_misconception(db_row(38391), whole_number, too_vague,
    skip, none, none).

% === row 38450: additive justification for multiplication ===
test_harness:arith_misconception(db_row(38450), whole_number, too_vague,
    skip, none, none).

% === row 38521: counts cubes instead of towers in mixed-unit task ===
test_harness:arith_misconception(db_row(38521), whole_number, too_vague,
    skip, none, none).

% === row 38566: zero is "nothing" so not divisible ===
test_harness:arith_misconception(db_row(38566), whole_number, too_vague,
    skip, none, none).

% === row 38606: didactical contract — apply recently learned operation ===
% Task: 57 cars, 24 red, how many non-red?
% Correct: 33   (57 - 24)
% Error: adds the two given numbers -> 81
% SCHEMA: Arithmetic is Object Collection — all numbers get combined
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(didactical_contract_add)))
misconceptions_whole_number_batch_3:(r38606_contract_add(Total-Subset, Got) :-
    Got is Total + Subset).

test_harness:arith_misconception(db_row(38606), whole_number, didactical_contract_addition,
    misconceptions_whole_number_batch_3:r38606_contract_add,
    57-24,
    33).

% === row 38618: subset and complement drawn as disjoint collections ===
test_harness:arith_misconception(db_row(38618), whole_number, too_vague,
    skip, none, none).

% === row 38690: misread "10" in tens column as 10 ones when interpreting work ===
test_harness:arith_misconception(db_row(38690), whole_number, too_vague,
    skip, none, none).

% === row 38734: unrealistic division-with-remainder answer in word problem ===
% Task: 269 people, lift holds 14 — how many trips?
% Correct: 20   (ceiling of 269/14)
% Error: floor division -> 19
% SCHEMA: Arithmetic as pure computation, context discarded
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(unrealistic_remainder)))
misconceptions_whole_number_batch_3:(r38734_floor_not_ceiling(People-Capacity, Got) :-
    Got is People // Capacity).

test_harness:arith_misconception(db_row(38734), whole_number, unrealistic_lift_remainder,
    misconceptions_whole_number_batch_3:r38734_floor_not_ceiling,
    269-14,
    20).

% === row 38834: left-to-right evaluation ignores precedence ===
% Task: 2 + 3 * 4  (encoded as a ternary expression term)
% Correct: 14      (precedence: 2 + 12)
% Error:  20      (left-to-right: (2+3)*4)
% SCHEMA: Source-Path-Goal — path is reading direction, not syntax
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(ltr_eval_ignores_precedence)))
misconceptions_whole_number_batch_3:(r38834_ltr_eval(expr(A,Op1,B,Op2,C), Got) :-
    apply_op(A, Op1, B, R1),
    apply_op(R1, Op2, C, Got)).

misconceptions_whole_number_batch_3:(apply_op(X, +, Y, Z) :- Z is X + Y).
misconceptions_whole_number_batch_3:(apply_op(X, -, Y, Z) :- Z is X - Y).
misconceptions_whole_number_batch_3:(apply_op(X, *, Y, Z) :- Z is X * Y).
misconceptions_whole_number_batch_3:(apply_op(X, /, Y, Z) :- Z is X / Y).

test_harness:arith_misconception(db_row(38834), whole_number, left_to_right_precedence,
    misconceptions_whole_number_batch_3:r38834_ltr_eval,
    expr(2, +, 3, *, 4),
    14).

% === row 38852: integer division ignores fractional remainder ===
test_harness:arith_misconception(db_row(38852), whole_number, too_vague,
    skip, none, none).

% === row 38887: curriculum sequencing for money (not a computation error) ===
test_harness:arith_misconception(db_row(38887), whole_number, too_vague,
    skip, none, none).

% === row 38970: counts by ones to add ten (strategy critique only) ===
test_harness:arith_misconception(db_row(38970), whole_number, too_vague,
    skip, none, none).

% === row 39052: 1-sig-fig rounding produces massive error on leading-1 numbers ===
% Task: 149 * 249 estimated with 1-sig-fig rounding
% Correct: 37101  (exact product)
% Error: 100 * 200 = 20000 (both round down to leading digit)
% SCHEMA: Measuring Stick — the stick loses resolution at leading 1
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(one_sig_fig_leading_one)))
misconceptions_whole_number_batch_3:(r39052_one_sig_fig(A-B, Got) :-
    round_to_1sf(A, RA),
    round_to_1sf(B, RB),
    Got is RA * RB).

misconceptions_whole_number_batch_3:(round_to_1sf(N, R) :-
    N > 0,
    number_codes(N, Codes),
    length(Codes, Len),
    Codes = [LeadCode|_],
    Lead is LeadCode - 0'0,
    D is Len - 1,
    Pow is 10 ** D,
    R is Lead * Pow).

test_harness:arith_misconception(db_row(39052), whole_number, one_sig_fig_rounding_error,
    misconceptions_whole_number_batch_3:r39052_one_sig_fig,
    149-249,
    37101).

% === row 39070: borrowing without regrouping meaning ===
test_harness:arith_misconception(db_row(39070), whole_number, too_vague,
    skip, none, none).

% === row 39110: always subtract smaller from larger in each column ===
% Task: 1702 - 1368
% Correct: 334
% Error: per-column |a-b|  ->  |1-1||7-3||0-6||2-8| = 0466 = 466
% SCHEMA: Motion Along a Path — path steps commute
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(smaller_from_larger_per_column)))
misconceptions_whole_number_batch_3:(r39110_col_absdiff(M-S, Got) :-
    number_codes(M, MC), number_codes(S, SC),
    maplist(code_to_digit, MC, MD),
    maplist(code_to_digit, SC, SD),
    pad_left(MD, SD, MP, SP),
    maplist([A,B,D]>>(D is abs(A-B)), MP, SP, Diffs),
    digits_to_number(Diffs, Got)).

misconceptions_whole_number_batch_3:(code_to_digit(C, D) :- D is C - 0'0).

misconceptions_whole_number_batch_3:(pad_left(A, B, A, B) :- length(A, L), length(B, L), !).
misconceptions_whole_number_batch_3:(pad_left(A, B, AP, BP) :-
    length(A, LA), length(B, LB),
    ( LA < LB
    -> D is LB - LA, length(Pad, D), maplist(=(0), Pad),
       append(Pad, A, AP), BP = B
    ;  D is LA - LB, length(Pad, D), maplist(=(0), Pad),
       append(Pad, B, BP), AP = A
    )).

misconceptions_whole_number_batch_3:(digits_to_number(Digits, N) :-
    foldl([D,Acc,Next]>>(Next is Acc*10 + D), Digits, 0, N)).

test_harness:arith_misconception(db_row(39110), whole_number, absdiff_per_column,
    misconceptions_whole_number_batch_3:r39110_col_absdiff,
    1702-1368,
    334).

% === row 39126: basic-fact slip inside a correct borrow frame ===
% Task: 7 - 5
% Correct: 2
% Error: 3  (small numerical-fact error)
% SCHEMA: retrieval slip
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(numerical_fact_slip)))
misconceptions_whole_number_batch_3:(r39126_fact_slip(7-5, 3)).

test_harness:arith_misconception(db_row(39126), whole_number, basic_fact_slip,
    misconceptions_whole_number_batch_3:r39126_fact_slip,
    7-5,
    2).

% === row 39149: partitioning by ones rather than tens (no example) ===
test_harness:arith_misconception(db_row(39149), whole_number, too_vague,
    skip, none, none).

% === row 39213: parity by last digit in non-decimal base ===
% Task: is 34 in base 5 even?
% Correct: odd   (34_5 = 19 in base 10)
% Error: last digit 4 is even -> even
% SCHEMA: overgeneralized base-10 last-digit rule
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(parity_last_digit_any_base)))
misconceptions_whole_number_batch_3:(r39213_parity_last_digit(base(Digits, _Base), Got) :-
    last(Digits, Last),
    ( Last mod 2 =:= 0
    -> Got = even
    ;  Got = odd
    )).

test_harness:arith_misconception(db_row(39213), whole_number, parity_last_digit_in_base,
    misconceptions_whole_number_batch_3:r39213_parity_last_digit,
    base([3,4], 5),
    odd).

% === row 39236: equals sign as separator in a running chain ===
% Task: given 246 + 14 = 260, student writes "+ 246 = 506" and sums all
% Correct: 260  (the first equality is the answer)
% Error: chain-sum everything -> 246 + 14 + 246 = 506
% SCHEMA: Source-Path-Goal — "=" is a step marker, not equivalence
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(equals_as_separator)))
misconceptions_whole_number_batch_3:(r39236_chain_sum(chain(A,B,C), Got) :-
    Got is A + B + C).

test_harness:arith_misconception(db_row(39236), whole_number, equals_as_separator,
    misconceptions_whole_number_batch_3:r39236_chain_sum,
    chain(246, 14, 246),
    260).

% === row 39317: belief in a biggest number ===
test_harness:arith_misconception(db_row(39317), whole_number, too_vague,
    skip, none, none).

% === row 39365: conceptual discontinuity at x*0 and x*1 ===
test_harness:arith_misconception(db_row(39365), whole_number, too_vague,
    skip, none, none).

% === row 39409: compare by row length rather than count ===
test_harness:arith_misconception(db_row(39409), whole_number, too_vague,
    skip, none, none).

% === row 39467: partitive division clash with algorithm ===
test_harness:arith_misconception(db_row(39467), whole_number, too_vague,
    skip, none, none).

% === row 39497: bi-digit numeral as indivisible whole ===
test_harness:arith_misconception(db_row(39497), whole_number, too_vague,
    skip, none, none).

% === row 39531: absurd numerical statements accepted ===
test_harness:arith_misconception(db_row(39531), whole_number, too_vague,
    skip, none, none).

% === row 39544: Mi'kmaq animacy in addition word problems ===
test_harness:arith_misconception(db_row(39544), whole_number, too_vague,
    skip, none, none).

% === row 39565: 10 not objectified as composite unit ===
test_harness:arith_misconception(db_row(39565), whole_number, too_vague,
    skip, none, none).

% === row 39580: counting-by-ones for 17-15 stalls ===
test_harness:arith_misconception(db_row(39580), whole_number, too_vague,
    skip, none, none).

% === row 39679: division by zero treated as infinity ===
% Task: 12 / 0
% Correct: undefined
% Error: infinity
% SCHEMA: Motion Along a Path — infinite steps instead of "no path"
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(div_by_zero_is_infinity)))
misconceptions_whole_number_batch_3:(r39679_div_zero_infinity(_-0, infinity)).

test_harness:arith_misconception(db_row(39679), whole_number, div_zero_is_infinity,
    misconceptions_whole_number_batch_3:r39679_div_zero_infinity,
    12-0,
    undefined).

% === row 39695: floor division where ceiling is required by context ===
% Task: 1128 people, bus holds 36 — how many buses?
% Correct: 32   (ceiling of 1128/36)
% Error: floor division -> 31
% SCHEMA: Arithmetic as computation without situational judgment
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(floor_instead_of_ceiling)))
misconceptions_whole_number_batch_3:(r39695_floor_buses(People-Capacity, Got) :-
    Got is People // Capacity).

test_harness:arith_misconception(db_row(39695), whole_number, floor_instead_of_ceiling,
    misconceptions_whole_number_batch_3:r39695_floor_buses,
    1128-36,
    32).

% === row 39730: commutativity overgeneralized to subtraction ===
% Task: 7 - 3
% Correct: 4
% Error: treats subtraction as commutative, so computes 3 - 7 -> -4
% SCHEMA: Arithmetic is Object Collection — operands freely swap
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(subtraction_commutative)))
misconceptions_whole_number_batch_3:(r39730_sub_commutative(A-B, Got) :-
    Got is B - A).

test_harness:arith_misconception(db_row(39730), whole_number, commutative_subtraction,
    misconceptions_whole_number_batch_3:r39730_sub_commutative,
    7-3,
    4).

% === row 39749: equal-additions with only minuend adjusted ===
% Task: 34 - 17 via equal-additions
% Correct: 17
% Error: adds 10 to ones of minuend (4 -> 14) but forgets to add 10 to tens of subtrahend;
%        computes (14-7)=7 ones, (3-1)=2 tens -> 27
% SCHEMA: Motion Along a Path — only one leg of the compensation is walked
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(equal_additions_asymmetric)))
misconceptions_whole_number_batch_3:(r39749_eq_add_half(34-17, 27)).

test_harness:arith_misconception(db_row(39749), whole_number, equal_additions_only_minuend,
    misconceptions_whole_number_batch_3:r39749_eq_add_half,
    34-17,
    17).

% === row 39855: multiplication before division / strict left-to-right ===
% Task: 20 + 30 / 5 * 2  (encoded as a 7-term expression)
% Correct: 32   (20 + (30/5)*2)
% Error: multiply before divide -> 20 + 30/(5*2) = 23
% SCHEMA: Source-Path-Goal — altered priority order
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(mult_before_div)))
misconceptions_whole_number_batch_3:(r39855_mult_before_div(expr6(A, +, B, /, C, *, D), Got) :-
    Inner is C * D,
    Quot is B / Inner,
    Got is A + Quot).

test_harness:arith_misconception(db_row(39855), whole_number, multiplication_before_division,
    misconceptions_whole_number_batch_3:r39855_mult_before_div,
    expr6(20, +, 30, /, 5, *, 2),
    32).

% === row 39992: unsystematic extraction of all numbers in a word problem ===
test_harness:arith_misconception(db_row(39992), whole_number, too_vague,
    skip, none, none).

% === row 40020: partitive divisor/quotient confusion ===
test_harness:arith_misconception(db_row(40020), whole_number, too_vague,
    skip, none, none).

% === row 40051: zero judged as neither even nor odd ===
% Task: parity of 0
% Correct: even
% Error: neither (treats 0 as "nothing")
% SCHEMA: Container — 0 is the empty container, outside parity
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(zero_not_in_parity)))
misconceptions_whole_number_batch_3:(r40051_zero_neither(0, neither)).

test_harness:arith_misconception(db_row(40051), whole_number, zero_neither_even_nor_odd,
    misconceptions_whole_number_batch_3:r40051_zero_neither,
    0,
    even).

% === row 40066: index notation read as base times exponent ===
% Task: 5^5
% Correct: 3125
% Error: 5 * 5 = 25
% SCHEMA: Arithmetic is Object Collection — exponent as a second operand to *
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(exponent_as_multiplier)))
misconceptions_whole_number_batch_3:(r40066_exp_as_mult(Base-Exp, Got) :-
    Got is Base * Exp).

test_harness:arith_misconception(db_row(40066), whole_number, exponent_as_multiplier,
    misconceptions_whole_number_batch_3:r40066_exp_as_mult,
    5-5,
    3125).

% === row 40106: formal vs situated subtraction ===
test_harness:arith_misconception(db_row(40106), whole_number, too_vague,
    skip, none, none).

% === row 40141: "big number take away small number" per column ===
% Task: 132 - 45
% Correct: 87
% Error: column-wise |a-b|  ->  |1-0||3-4||2-5| = 1,1,3 -> 113
% SCHEMA: Motion Along a Path — columns traversed with swap-as-needed
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(columnwise_absdiff)))
misconceptions_whole_number_batch_3:(r40141_col_absdiff(132-45, 113)).

test_harness:arith_misconception(db_row(40141), whole_number, columnwise_abs_difference,
    misconceptions_whole_number_batch_3:r40141_col_absdiff,
    132-45,
    87).

% === row 40167: answers "how many more" with the larger set's count ===
% Task: Bill 6, Martin 4 — how many more does Bill have?
% Correct: 2
% Error: reports larger count -> 6
% SCHEMA: Container — reports the bigger container, not the surplus
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(compare_returns_larger)))
misconceptions_whole_number_batch_3:(r40167_compare_larger(A-B, Got) :-
    Got is max(A, B)).

test_harness:arith_misconception(db_row(40167), whole_number, compare_returns_larger_count,
    misconceptions_whole_number_batch_3:r40167_compare_larger,
    6-4,
    2).

% === row 40202: algorithmic fixation on 20x20 (inefficient but correct) ===
test_harness:arith_misconception(db_row(40202), whole_number, too_vague,
    skip, none, none).

% === row 40236: multiples of ten via habitual 9x7 pattern ===
% Task: 90 * 70
% Correct: 6300
% Error: falls back on 9 * 70 = 630 (ignores the extra place value)
% SCHEMA: Measuring Stick — the scale factor is dropped
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(drop_place_value_scaling)))
misconceptions_whole_number_batch_3:(r40236_drop_scale(A-B, Got) :-
    StripA is A // 10,
    Got is StripA * B).

test_harness:arith_misconception(db_row(40236), whole_number, habit_drops_place_value,
    misconceptions_whole_number_batch_3:r40236_drop_scale,
    90-70,
    6300).

% === row 40279: zeros in quotient/dividend conflated ===
test_harness:arith_misconception(db_row(40279), whole_number, too_vague,
    skip, none, none).

% === row 40312: additive reasoning for a multiplicative relation ===
% Task: how many 100,000s in 1,000,000?
% Correct: 10
% Error: subtracts (1,000,000 - 100,000 = 900,000) instead of dividing
% SCHEMA: Arithmetic is Object Collection — additive substitute for scale
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(additive_for_multiplicative_scale)))
misconceptions_whole_number_batch_3:(r40312_additive_scale(Whole-Part, Got) :-
    Got is Whole - Part).

test_harness:arith_misconception(db_row(40312), whole_number, additive_for_scale,
    misconceptions_whole_number_batch_3:r40312_additive_scale,
    1000000-100000,
    10).

% === row 40349: both addends entered on separate wheels simultaneously ===
test_harness:arith_misconception(db_row(40349), whole_number, too_vague,
    skip, none, none).

% === row 40494: teacher directs to wrong division model ===
test_harness:arith_misconception(db_row(40494), whole_number, too_vague,
    skip, none, none).

% === row 40539: larger number has more factors ===
% Task: which has more factors, 38 or 32?
% Correct: 32    (factors: {1,2,4,8,16,32} — six factors)
% Error: picks 38 because it is larger (actual factors {1,2,19,38} — four)
% SCHEMA: Measuring Stick — "bigger" assumed dominant on every dimension
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(bigger_means_more_factors)))
misconceptions_whole_number_batch_3:(r40539_bigger_more_factors(A-B, Winner) :-
    ( A >= B
    -> Winner = A
    ;  Winner = B
    )).

test_harness:arith_misconception(db_row(40539), whole_number, size_implies_factor_count,
    misconceptions_whole_number_batch_3:r40539_bigger_more_factors,
    38-32,
    32).

% === row 40584: "always borrow left" with misdistributed intermediate columns ===
test_harness:arith_misconception(db_row(40584), whole_number, too_vague,
    skip, none, none).

% === row 40642: hash marks on empty number line — cardinal vs ordinal ===
test_harness:arith_misconception(db_row(40642), whole_number, too_vague,
    skip, none, none).

% whole_number misconceptions — research corpus batch 4/5.
% Native arithmetic layer only. Theoretical annotations as comments:
%   % GROUNDED: TODO — placeholder for future embodied arithmetic layer
%   % SCHEMA: <schema name> — Lakoff & Nunez grounding when applicable
%   % CONNECTS TO: s(comp_nec(unlicensed(...))) — PML operator path
%
% Registration convention (from Task 3 arch fix):
%   test_harness:arith_misconception(Source, Domain, Description,
%       misconceptions_whole_number_batch_4:rule_name, Input, Expected).
% Rule predicates do NOT go on the module export list.


% ---- Encodings appended by agent for whole_number batch 4 ----

% === row 37490: six is both even and odd ===
% Task: classify parity of 6 when decomposed as three groups of two
% Correct: even
% Error: claims both even and odd because composed of odd number of twos
% SCHEMA: Arithmetic is Object Collection (parity via group count)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(parity_by_group_count)))
misconceptions_whole_number_batch_4:(parity_by_group_count(N, both_even_and_odd) :-
    0 is N mod 2,
    Halves is N // 2,
    1 is Halves mod 2).

test_harness:arith_misconception(db_row(37490), whole_number, six_both_even_and_odd,
    misconceptions_whole_number_batch_4:parity_by_group_count,
    6, even).

% === row 37498: vertical vs horizontal format dependency ===
test_harness:arith_misconception(db_row(37498), whole_number, too_vague,
    skip, none, none).

% === row 37543: digits-as-ones in regrouping ===
test_harness:arith_misconception(db_row(37543), whole_number, too_vague,
    skip, none, none).

% === row 37577: digit-sum primality rule ===
% Task: decide whether 23707 is prime
% Correct: composite (23707 = 151 * 157)
% Error: claims prime because digit sum (19) is prime
% SCHEMA: Container (primality projected from digit sum)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(digit_sum_primality)))
misconceptions_whole_number_batch_4:(digit_sum_primality(N, prime) :-
    digit_sum(N, S),
    is_prime(S)).
misconceptions_whole_number_batch_4:(digit_sum_primality(N, composite) :-
    digit_sum(N, S),
    \+ is_prime(S)).

misconceptions_whole_number_batch_4:(digit_sum(N, S) :-
    N < 10, !, S = N).
misconceptions_whole_number_batch_4:(digit_sum(N, S) :-
    D is N mod 10,
    R is N // 10,
    digit_sum(R, S0),
    S is S0 + D).

misconceptions_whole_number_batch_4:(is_prime(2) :- !).
misconceptions_whole_number_batch_4:(is_prime(N) :-
    N > 2,
    N mod 2 =\= 0,
    Max is integer(sqrt(N)),
    \+ ( between(3, Max, K), K mod 2 =:= 1, N mod K =:= 0 )).

test_harness:arith_misconception(db_row(37577), whole_number, digit_sum_primality,
    misconceptions_whole_number_batch_4:digit_sum_primality,
    23707, composite).

% === row 37625: quotitive/partitive shift struggle ===
test_harness:arith_misconception(db_row(37625), whole_number, too_vague,
    skip, none, none).

% === row 37654: rigid rounding rules ===
test_harness:arith_misconception(db_row(37654), whole_number, too_vague,
    skip, none, none).

% === row 37688: add irrelevant counts instead of multiplying ===
% Task: word problem gives '2 tables, 4 children each'; separate surface
%   counts (3 blue, 5 red cubes) are what Michelle attends to.
% Correct: 8 children (2 * 4)
% Error: adds surface counts she invented (3 + 5 = 8)
% SCHEMA: Object Collection (additive over feature counts)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(add_irrelevant_counts)))
misconceptions_whole_number_batch_4:(add_irrelevant_counts(A-B, Sum) :- Sum is A + B).

test_harness:arith_misconception(db_row(37688), whole_number, add_irrelevant_counts,
    misconceptions_whole_number_batch_4:add_irrelevant_counts,
    2-4, 8).

% === row 37718: negative transfer of operation habit ===
test_harness:arith_misconception(db_row(37718), whole_number, too_vague,
    skip, none, none).

% === row 37763: counting-back for subtraction ===
test_harness:arith_misconception(db_row(37763), whole_number, too_vague,
    skip, none, none).

% === row 37794: 'double first and add 1' rule for 7+6 ===
% Task: 7 + 6
% Correct: 13
% Error: rote 'double first, add one' -> 2*7 + 1 = 15
% SCHEMA: Arithmetic is Object Collection (rote derived-fact rule)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(double_first_add_one)))
misconceptions_whole_number_batch_4:(double_first_add_one(A-_B, Out) :- Out is 2*A + 1).

test_harness:arith_misconception(db_row(37794), whole_number, double_first_add_one,
    misconceptions_whole_number_batch_4:double_first_add_one,
    7-6, 13).

% === row 37813: raw division result with unhandled remainder ===
% Task: a sharing problem with dividend 94, divisor 3 (stand-in for
%   the paper's situation where the student reports '31 1/3' without
%   interpreting the remainder). Correct answer here is the integer
%   quotient (31); error leaves the mixed form.
% Correct: 31
% Error: returns quot + frac(rem,div) without context interpretation
% SCHEMA: Container (symbolic division result left uninterpreted)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(raw_quotient_with_remainder)))
misconceptions_whole_number_batch_4:(raw_quotient_with_remainder(D-V, quot_plus_frac(Q, R, V)) :-
    Q is D // V,
    R is D mod V,
    R > 0).

test_harness:arith_misconception(db_row(37813), whole_number, raw_quotient_with_remainder,
    misconceptions_whole_number_batch_4:raw_quotient_with_remainder,
    94-3, 31).

% === row 37820: distributive prime factorization over sum ===
% Task: prime factorize 391 by splitting as 300 + 80 + 11
% Correct: pf(391) = [17, 23]
% Error: treats pf as distributive over +: pf(300) + pf(80) + pf(11)
% SCHEMA: Object Collection (distributing factorization over parts)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(pf_distributive_over_sum)))
misconceptions_whole_number_batch_4:(pf_distributive_over_sum(Parts, concat_pfs(ListOfPFs)) :-
    maplist(prime_factors, Parts, ListOfPFs)).

misconceptions_whole_number_batch_4:(prime_factors(1, []) :- !).
misconceptions_whole_number_batch_4:(prime_factors(N, [N]) :-
    N > 1, is_prime(N), !).
misconceptions_whole_number_batch_4:(prime_factors(N, [K|Rest]) :-
    N > 1,
    smallest_factor(N, 2, K),
    N1 is N // K,
    prime_factors(N1, Rest)).

misconceptions_whole_number_batch_4:(smallest_factor(N, K, K) :- N mod K =:= 0, !).
misconceptions_whole_number_batch_4:(smallest_factor(N, K, F) :-
    K1 is K + 1,
    smallest_factor(N, K1, F)).

test_harness:arith_misconception(db_row(37820), whole_number, pf_distributive_over_sum,
    misconceptions_whole_number_batch_4:pf_distributive_over_sum,
    [300, 80, 11], [17, 23]).

% === row 37854: ignore base of comparison ===
test_harness:arith_misconception(db_row(37854), whole_number, too_vague,
    skip, none, none).

% === row 37876: reversal error on compare word problems ===
% Task: '2 times as many' inverse translation — given quantity 120 is
%   '2 times as many' as unknown, so unknown = 120 / 2.
% Correct: 60
% Error: translates '2 times' directly to multiplication -> 120 * 2 = 240
% SCHEMA: Path (direct lexical-to-operation mapping)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(reversal_multiply_instead_of_divide)))
misconceptions_whole_number_batch_4:(reversal_mult_instead_div(Q-K, Out) :- Out is Q * K).

test_harness:arith_misconception(db_row(37876), whole_number, reversal_multiply_not_divide,
    misconceptions_whole_number_batch_4:reversal_mult_instead_div,
    120-2, 60).

% === row 37898: partial products not shifted left ===
% Task: 123 * 645 via partial products, aligning without shift
% Correct: 79335
% Error: sums partial products (123*5 + 123*4 + 123*6) with no shift
% SCHEMA: Object Collection (place-value collapse)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(no_shift_partial_products)))
misconceptions_whole_number_batch_4:(no_shift_partial_products(A-B, Out) :-
    digits_of(B, Ds),
    maplist(mul_by(A), Ds, Partials),
    sum_list(Partials, Out)).

misconceptions_whole_number_batch_4:(mul_by(A, D, P) :- P is A * D).

misconceptions_whole_number_batch_4:(digits_of(N, [N]) :- N < 10, !).
misconceptions_whole_number_batch_4:(digits_of(N, Ds) :-
    N >= 10,
    D is N mod 10,
    R is N // 10,
    digits_of(R, Rest),
    append(Rest, [D], Ds)).

test_harness:arith_misconception(db_row(37898), whole_number, partial_products_no_shift,
    misconceptions_whole_number_batch_4:no_shift_partial_products,
    123-645, 79335).

% === row 37905: miscopy via subvocalization ===
test_harness:arith_misconception(db_row(37905), whole_number, too_vague,
    skip, none, none).

% === row 37952: 'difference' not recognized as 'how many more' ===
test_harness:arith_misconception(db_row(37952), whole_number, too_vague,
    skip, none, none).

% === row 38049: counting-all after decomposition ===
test_harness:arith_misconception(db_row(38049), whole_number, too_vague,
    skip, none, none).

% === row 38070: teacher dismisses non-standard algorithms ===
test_harness:arith_misconception(db_row(38070), whole_number, too_vague,
    skip, none, none).

% === row 38105: idiosyncratic 60/4 = 12 ===
% Task: 60 / 4 via idiosyncratic nexus
% Correct: 15
% Error: reasons 4 in 8 twice, 8 in 60 six times, yields 12
% SCHEMA: Path (idiosyncratic composition)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(idiosyncratic_nexus_division)))
misconceptions_whole_number_batch_4:(idiosyncratic_nexus_div(60-4, 12)).

test_harness:arith_misconception(db_row(38105), whole_number, idiosyncratic_nexus_division,
    misconceptions_whole_number_batch_4:idiosyncratic_nexus_div,
    60-4, 15).

% === row 38120: ten-stick mistaken for single unit ===
test_harness:arith_misconception(db_row(38120), whole_number, too_vague,
    skip, none, none).

% === row 38143: long multiplication mis-executed as addition ===
% Task: 12 * 11 set up vertically but added
% Correct: 132
% Error: adds instead of multiplying -> 23
% SCHEMA: Path (format triggers wrong operation)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(mult_performed_as_add)))
misconceptions_whole_number_batch_4:(mult_as_add(A-B, Out) :- Out is A + B).

test_harness:arith_misconception(db_row(38143), whole_number, long_mult_performed_as_add,
    misconceptions_whole_number_batch_4:mult_as_add,
    12-11, 132).

% === row 38199: extrapolate pattern from tail only ===
test_harness:arith_misconception(db_row(38199), whole_number, too_vague,
    skip, none, none).

% === row 38226: regress to mixed materials ===
test_harness:arith_misconception(db_row(38226), whole_number, too_vague,
    skip, none, none).

% === row 38241: carried/borrowed digit named as 'one' not 'ten' ===
test_harness:arith_misconception(db_row(38241), whole_number, too_vague,
    skip, none, none).

% === row 38276: Stage 1 composite units via repeated addition ===
test_harness:arith_misconception(db_row(38276), whole_number, too_vague,
    skip, none, none).

% === row 38376: 24 + 37 -> 611 via digit-wise addition ===
% Task: 24 + 37 using standard vertical, digits independent
% Correct: 61
% Error: adds 4+7=11 and 2+3=6, concatenates -> 611
% SCHEMA: Container (digit as digit, not place value)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(digitwise_add_concat)))
misconceptions_whole_number_batch_4:(digitwise_add_concat(A-B, Out) :-
    OnesSum is (A mod 10) + (B mod 10),
    TensSum is (A // 10) + (B // 10),
    % concatenate tens sum and ones sum left-to-right
    ( OnesSum < 10
    -> Out is TensSum * 10 + OnesSum
    ;  OnesDigits is OnesSum, % e.g. 11 has two digits
       ( OnesDigits < 100
       -> Out is TensSum * 100 + OnesDigits
       ;  Out is TensSum * 1000 + OnesDigits
       )
    )).

test_harness:arith_misconception(db_row(38376), whole_number, digitwise_add_concat,
    misconceptions_whole_number_batch_4:digitwise_add_concat,
    24-37, 61).

% === row 38392: rote long division without meaning ===
test_harness:arith_misconception(db_row(38392), whole_number, too_vague,
    skip, none, none).

% === row 38452: reversal by arbitrary multiplication ===
% Task: yellow fits red 5x, blue fits red 15x, so blue fits yellow ?
% Correct: 3 (15 / 5)
% Error: multiplies 15 * 5 = 75
% SCHEMA: Path (reversal as multiplication)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(reversal_by_multiplication)))
misconceptions_whole_number_batch_4:(reversal_by_mult(A-B, Out) :- Out is A * B).

test_harness:arith_misconception(db_row(38452), whole_number, reversal_as_multiplication,
    misconceptions_whole_number_batch_4:reversal_by_mult,
    15-5, 3).

% === row 38522: irrelevant info overwhelms working memory ===
test_harness:arith_misconception(db_row(38522), whole_number, too_vague,
    skip, none, none).

% === row 38567: zero not even because no twos ===
% Task: classify parity of 0
% Correct: even
% Error: 'neither even nor odd' because zero contains no twos
% SCHEMA: Object Collection (parity requires positive count of twos)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(zero_neither_parity)))
misconceptions_whole_number_batch_4:(zero_neither_parity(0, neither)).
misconceptions_whole_number_batch_4:(zero_neither_parity(N, even) :- N > 0, 0 is N mod 2).
misconceptions_whole_number_batch_4:(zero_neither_parity(N, odd) :- N > 0, 1 is N mod 2).

test_harness:arith_misconception(db_row(38567), whole_number, zero_neither_even_nor_odd,
    misconceptions_whole_number_batch_4:zero_neither_parity,
    0, even).

% === row 38607: subset and whole drawn as disjoint ===
% Task: 57 cars total, 24 red; draw representation
% Correct: total marks = 57 (red is a subset)
% Error: draws 57 + 24 = 81 marks (treats red as disjoint addition)
% SCHEMA: Container (part/whole as disjoint collections)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(subset_as_disjoint)))
misconceptions_whole_number_batch_4:(subset_as_disjoint(Whole-Subset, Out) :- Out is Whole + Subset).

test_harness:arith_misconception(db_row(38607), whole_number, subset_drawn_as_disjoint,
    misconceptions_whole_number_batch_4:subset_as_disjoint,
    57-24, 57).

% === row 38624: multistep word problem by keyword addition ===
% Task: 2.3 kg + 0.5 kg 'more than', then 'altogether' — correct
%   answer requires adding Even's + Sigrid's amounts: 2.3 + 2.8 = 5.1.
%   Whole-number stand-in: 23 + 28 (tenths) = 51.
% Correct: 51
% Error: simply adds surface numbers 23 + 5 = 28 (ignoring structure)
% SCHEMA: Path (keyword-as-operation direct translation)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(keyword_surface_addition)))
misconceptions_whole_number_batch_4:(keyword_surface_add(A-B, Out) :- Out is A + B).

test_harness:arith_misconception(db_row(38624), whole_number, keyword_surface_addition,
    misconceptions_whole_number_batch_4:keyword_surface_add,
    23-5, 51).

% === row 38708: cannot anticipate pair count in sum ===
test_harness:arith_misconception(db_row(38708), whole_number, too_vague,
    skip, none, none).

% === row 38735: focus on physical features of manipulatives ===
test_harness:arith_misconception(db_row(38735), whole_number, too_vague,
    skip, none, none).

% === row 38848: procedural division over structural divisibility ===
test_harness:arith_misconception(db_row(38848), whole_number, too_vague,
    skip, none, none).

% === row 38854: dividend and quotient change at same rate ===
% Task: given 498 / 6 = 83, estimate 491 / 6
% Correct: 491 / 6 ~ 81 (remainder ignored: 81.83...)
% Error: subtracts (498-491)=7 from 83 to get 76
% SCHEMA: Path (linear coupling of dividend and quotient)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(dividend_quotient_same_rate)))
misconceptions_whole_number_batch_4:(dividend_quotient_same_rate(NewD-Q-OldD, Out) :-
    Diff is OldD - NewD,
    Out is Q - Diff).

test_harness:arith_misconception(db_row(38854), whole_number, dividend_quotient_same_rate,
    misconceptions_whole_number_batch_4:dividend_quotient_same_rate,
    491-83-498, 81).

% === row 38921: buggy borrow on 235 - 341 ===
% Task: 235 - 341 (larger from smaller) — student returns 884 via
%   subtract-smaller-from-larger column-wise after borrowing.
% Correct: -106
% Error: column-wise subtract-smaller-from-larger with borrow -> 884
%   (5-1=4, 3-4 borrow to 13-4=9... then tens reversed, hundreds 8)
%   We encode the specific reported outcome.
% SCHEMA: Container (columns treated independently, always positive)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(buggy_borrow_smaller_minuend)))
misconceptions_whole_number_batch_4:(buggy_borrow_smaller_minuend(235-341, 884)).

test_harness:arith_misconception(db_row(38921), whole_number, buggy_borrow_smaller_minuend,
    misconceptions_whole_number_batch_4:buggy_borrow_smaller_minuend,
    235-341, -106).

% === row 38971: ritual chorused answers ===
test_harness:arith_misconception(db_row(38971), whole_number, too_vague,
    skip, none, none).

% === row 39053: estimation by rounding divisor to one sig fig ===
% Task: 3887 / 1590
% Correct: 2 (integer quotient; true value ~ 2.44)
% Error: round 1590 to 1 sig fig (2000), 3887/2000 ~ 1
% SCHEMA: Path (rough scale destroys proportion)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(round_divisor_1_sigfig)))
misconceptions_whole_number_batch_4:(round_divisor_1_sigfig(Num-Div, Out) :-
    round_to_1_sigfig(Div, R),
    Out is Num // R).

misconceptions_whole_number_batch_4:(round_to_1_sigfig(N, R) :-
    N >= 1,
    digits_of(N, Ds),
    length(Ds, L),
    D is L - 1,
    P is 10 ** D,
    First is round(N / P),
    R is First * P).

test_harness:arith_misconception(db_row(39053), whole_number, estimate_divisor_one_sigfig,
    misconceptions_whole_number_batch_4:round_divisor_1_sigfig,
    3887-1590, 2).

% === row 39071: surface story features drive pairing ===
test_harness:arith_misconception(db_row(39071), whole_number, too_vague,
    skip, none, none).

% === row 39119: idiosyncratic guessing on 5000 - 2 ===
test_harness:arith_misconception(db_row(39119), whole_number, too_vague,
    skip, none, none).

% === row 39127: persistence of 5 in 700 - 5 ===
% Task: 700 - 5
% Correct: 695
% Error: 'persistence of 5' treats it as 700 - 555 = 145
% SCHEMA: Path (digit haunts the operand field)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(persistence_of_digit)))
misconceptions_whole_number_batch_4:(persistence_of_digit(A-B, Out) :-
    % replicate B's digit across A's width
    digits_of(A, DsA),
    length(DsA, L),
    B < 10,
    replicate(L, B, Ds),
    digits_to_num(Ds, BFat),
    Out is A - BFat).

misconceptions_whole_number_batch_4:(replicate(0, _, []) :- !).
misconceptions_whole_number_batch_4:(replicate(N, X, [X|T]) :- N > 0, N1 is N - 1, replicate(N1, X, T)).

misconceptions_whole_number_batch_4:(digits_to_num(Ds, N) :- digits_to_num(Ds, 0, N)).
misconceptions_whole_number_batch_4:(digits_to_num([], Acc, Acc)).
misconceptions_whole_number_batch_4:(digits_to_num([D|Ds], Acc, N) :-
    Acc1 is Acc * 10 + D,
    digits_to_num(Ds, Acc1, N)).

test_harness:arith_misconception(db_row(39127), whole_number, persistence_of_digit,
    misconceptions_whole_number_batch_4:persistence_of_digit,
    700-5, 695).

% === row 39159: primitive counting on strategies ===
test_harness:arith_misconception(db_row(39159), whole_number, too_vague,
    skip, none, none).

% === row 39214: even exponent means even power ===
% Task: parity of 3^100
% Correct: odd (odd base, any exponent is odd)
% Error: claims even because exponent 100 is even
% SCHEMA: Path (projecting exponent parity onto power)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(even_exponent_even_power)))
misconceptions_whole_number_batch_4:(even_exponent_even_power(_Base-Exp, even) :- 0 is Exp mod 2).
misconceptions_whole_number_batch_4:(even_exponent_even_power(_Base-Exp, odd)  :- 1 is Exp mod 2).

test_harness:arith_misconception(db_row(39214), whole_number, even_exponent_implies_even,
    misconceptions_whole_number_batch_4:even_exponent_even_power,
    3-100, odd).

% === row 39237: nominal sameness in equality ===
% Task: fill the blank so 246 + 14 = [?] + 246
% Correct: 14
% Error: fills in 246 for visual symmetry -> claims both sides = 492
%   (reports the right-hand value 246 + 246)
% SCHEMA: Container (equality as visual match)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(nominal_same_blank)))
misconceptions_whole_number_batch_4:(nominal_same_blank(A-_B, A)).

test_harness:arith_misconception(db_row(39237), whole_number, nominal_sameness_equality,
    misconceptions_whole_number_batch_4:nominal_same_blank,
    246-14, 14).

% === row 39319: product of primes assumed prime ===
% Task: 19 * 23 = 437 — is 437 prime?
% Correct: composite (factored by 19 and 23)
% Error: closure tendency — 'two primes multiplied are prime'
% SCHEMA: Container (operation closure in the prime set)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(product_of_primes_prime)))
misconceptions_whole_number_batch_4:(product_of_primes_prime(A-B, prime) :- is_prime(A), is_prime(B)).
misconceptions_whole_number_batch_4:(product_of_primes_prime(A-B, composite) :-(
    \+ (is_prime(A), is_prime(B)))).

test_harness:arith_misconception(db_row(39319), whole_number, product_of_primes_prime,
    misconceptions_whole_number_batch_4:product_of_primes_prime,
    19-23, composite).

% === row 39376: long division procedural errors ===
test_harness:arith_misconception(db_row(39376), whole_number, too_vague,
    skip, none, none).

% === row 39413: start-unknown story drives subtraction ===
% Task: postman delivers 12 letters and has 39 left — how many started?
% Correct: 51 (12 + 39)
% Error: subtracts because surface action is 'delivered' -> 39 - 12 = 27
% SCHEMA: Path (surface action -> operation)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(surface_action_subtracts)))
misconceptions_whole_number_batch_4:(surface_action_subtracts(Delivered-Left, Out) :- Out is Left - Delivered).

test_harness:arith_misconception(db_row(39413), whole_number, start_unknown_subtract_not_add,
    misconceptions_whole_number_batch_4:surface_action_subtracts,
    12-39, 51).

% === row 39468: partitive transformed to quotitive ===
test_harness:arith_misconception(db_row(39468), whole_number, too_vague,
    skip, none, none).

% === row 39498: detach number from preceding operation sign ===
% Task: evaluate 50 - 10 + 10 + 10
% Correct: 60 (left-to-right: 50-10=40, +10=50, +10=60)
% Error: groups all +10s first -> 50 - (10+10+10) = 50 - 30 = 20
% SCHEMA: Container (terms grouped by sign visually)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(detach_sign_group_terms)))
misconceptions_whole_number_batch_4:(detach_sign_group(Expr, Out) :-
    Expr = minuend(M, Addends),
    sum_list(Addends, S),
    Out is M - S).

test_harness:arith_misconception(db_row(39498), whole_number, detach_sign_group_terms,
    misconceptions_whole_number_batch_4:detach_sign_group,
    minuend(50, [10, 10, 10]), 60).

% === row 39532: left-to-right subtraction (productive, not error) ===
test_harness:arith_misconception(db_row(39532), whole_number, too_vague,
    skip, none, none).

% === row 39545: Mi'kmaq translation awkwardness ===
test_harness:arith_misconception(db_row(39545), whole_number, too_vague,
    skip, none, none).

% === row 39572: empty number line must start at zero ===
test_harness:arith_misconception(db_row(39572), whole_number, too_vague,
    skip, none, none).

% === row 39581: cannot use structure only teacher modelled ===
test_harness:arith_misconception(db_row(39581), whole_number, too_vague,
    skip, none, none).

% === row 39682: no thinkable ten, counts by ones ===
test_harness:arith_misconception(db_row(39682), whole_number, too_vague,
    skip, none, none).

% === row 39725: commutativity recognized only by computing both sides ===
test_harness:arith_misconception(db_row(39725), whole_number, too_vague,
    skip, none, none).

% === row 39745: one-to-one and stable order fail ===
test_harness:arith_misconception(db_row(39745), whole_number, too_vague,
    skip, none, none).

% === row 39790: cue words trigger operation ===
test_harness:arith_misconception(db_row(39790), whole_number, too_vague,
    skip, none, none).

% === row 39900: order of operations ignored, left to right ===
% Task: evaluate 15 - 10 / 2 + 6 * 4
% Correct: 34 (15 - 5 + 24)
% Error: strict left to right: 15-10=5, 5/2=2, 2+6=8, 8*4=32
% SCHEMA: Path (read order = evaluation order)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(left_to_right_no_precedence)))
misconceptions_whole_number_batch_4:(left_to_right_ops(ops([N|Rest]), Out) :-
    left_to_right_acc(N, Rest, Out)).

misconceptions_whole_number_batch_4:(left_to_right_acc(Acc, [], Acc)).
misconceptions_whole_number_batch_4:(left_to_right_acc(Acc, [Op, N | Rest], Out) :-
    apply_op(Op, Acc, N, Acc1),
    left_to_right_acc(Acc1, Rest, Out)).

misconceptions_whole_number_batch_4:(apply_op(+, A, B, C) :- C is A + B).
misconceptions_whole_number_batch_4:(apply_op(-, A, B, C) :- C is A - B).
misconceptions_whole_number_batch_4:(apply_op(*, A, B, C) :- C is A * B).
misconceptions_whole_number_batch_4:(apply_op(/, A, B, C) :- C is A // B).

test_harness:arith_misconception(db_row(39900), whole_number, order_of_operations_ignored,
    misconceptions_whole_number_batch_4:left_to_right_ops,
    ops([15, -, 10, /, 2, +, 6, *, 4]), 34).

% === row 39993: number order in text drives operations ===
% Task: '3 boxes of 2 sets of 4 strings' appears as '4 strings, 2 sets,
%   3 boxes' in the prompt. Structure requires 4 * 2 * 3 (same value),
%   but the error is writing in literal order as 4 * 2 * 3. Since the
%   multiplication is commutative, we test the decision of which triple
%   the student wrote: given numbers paired to [A,B,C] in text order,
%   student writes A*B*C ignoring structural role.
%   Correct structural expression: 3 * 2 * 4
%   Error expression: 4 * 2 * 3 (same numerical value, different sentence)
% We encode the reported expression string rather than the numeric value.
% SCHEMA: Path (surface order drives symbolic expression)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(literal_order_sentence)))
misconceptions_whole_number_batch_4:(literal_order_sentence([A,B,C], expr(A,B,C))).

test_harness:arith_misconception(db_row(39993), whole_number, literal_order_number_sentence,
    misconceptions_whole_number_batch_4:literal_order_sentence,
    [4,2,3], expr(3,2,4)).

% === row 40022: recursive pattern, no link to multiplication ===
test_harness:arith_misconception(db_row(40022), whole_number, too_vague,
    skip, none, none).

% === row 40059: pentomino symmetry reasoning ===
test_harness:arith_misconception(db_row(40059), whole_number, too_vague,
    skip, none, none).

% === row 40079: estimation equated with rounding ===
test_harness:arith_misconception(db_row(40079), whole_number, too_vague,
    skip, none, none).

% === row 40108: transitivity over division-with-remainder notation ===
test_harness:arith_misconception(db_row(40108), whole_number, too_vague,
    skip, none, none).

% === row 40142: two-digit multiplication without cross-multiply ===
% Task: 27 * 39
% Correct: 1053
% Error: tens*tens as tens, ones*ones, sum only those two -> 63 + 6 = 69
%   (2 tens * 3 tens recorded as 6 tens, not 600)
% SCHEMA: Object Collection (place value collapse in cross-multiply)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(no_cross_multiply_digits)))
misconceptions_whole_number_batch_4:(no_cross_multiply(A-B, Out) :-
    O1 is A mod 10, T1 is A // 10,
    O2 is B mod 10, T2 is B // 10,
    OnesPart is O1 * O2,
    TensPart is T1 * T2,
    Out is OnesPart + TensPart * 10).

test_harness:arith_misconception(db_row(40142), whole_number, no_cross_multiply_digits,
    misconceptions_whole_number_batch_4:no_cross_multiply,
    27-39, 1053).

% === row 40168: difference interpreted as sum ===
% Task: difference between 3 and 5
% Correct: 2
% Error: sums the two numbers -> 8
% SCHEMA: Path (subtraction keyword -> addition)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(difference_as_sum)))
misconceptions_whole_number_batch_4:(difference_as_sum(A-B, Out) :- Out is A + B).

test_harness:arith_misconception(db_row(40168), whole_number, difference_interpreted_as_sum,
    misconceptions_whole_number_batch_4:difference_as_sum,
    3-5, 2).

% === row 40209: base-10 blocks without place value ===
% Task: represent 51 with base-10 blocks
% Correct: 51 (5 tens + 1 one)
% Error: 5 unit cubes + 1 unit cube = 6
% SCHEMA: Object Collection (all digits are ones)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(digits_as_ones_blocks)))
misconceptions_whole_number_batch_4:(digits_as_ones_blocks(N, Sum) :-
    digits_of(N, Ds),
    sum_list(Ds, Sum)).

test_harness:arith_misconception(db_row(40209), whole_number, blocks_ignore_place_value,
    misconceptions_whole_number_batch_4:digits_as_ones_blocks,
    51, 51).

% === row 40268: base-10 chosen for mathematical patterns ===
test_harness:arith_misconception(db_row(40268), whole_number, too_vague,
    skip, none, none).

% === row 40284: add instead of multiply in word problem ===
% Task: 8 boxes of 6 cupcakes -> total
% Correct: 48
% Error: adds the two numbers -> 14
% SCHEMA: Path (two numbers triggers addition)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(add_instead_of_multiply_word)))
misconceptions_whole_number_batch_4:(add_instead_of_multiply(A-B, Out) :- Out is A + B).

test_harness:arith_misconception(db_row(40284), whole_number, add_instead_of_multiply,
    misconceptions_whole_number_batch_4:add_instead_of_multiply,
    8-6, 48).

% === row 40320: equal factor differences imply equal products ===
% Task: compare 30 * 50 and 28 * 52
% Correct: 30*50 = 1500 > 28*52 = 1456 (not equal)
% Error: since 30-28 = 52-50, the products are equal (additive reasoning)
% SCHEMA: Path (additive invariance applied to multiplication)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(equal_diff_equal_product)))
misconceptions_whole_number_batch_4:(equal_diff_equal_product((A1-A2)-(B1-B2), equal) :-
    D1 is A1 - A2, D2 is B1 - B2, D1 =:= D2).
misconceptions_whole_number_batch_4:(equal_diff_equal_product((A1-A2)-(B1-B2), unequal) :-
    D1 is A1 - A2, D2 is B1 - B2, D1 =\= D2).

test_harness:arith_misconception(db_row(40320), whole_number, equal_diffs_equal_products,
    misconceptions_whole_number_batch_4:equal_diff_equal_product,
    (30-28)-(52-50), unequal).

% === row 40353: answer-only reasoning ignores estimation ===
test_harness:arith_misconception(db_row(40353), whole_number, too_vague,
    skip, none, none).

% === row 40497: refine 50*8 estimate by subtracting 2*50 ===
% Task: estimate 49 * 8 starting from 50 * 8 = 400
% Correct: 392 (subtract one group of 8: 400 - 8)
% Error: subtracts 2 * 50 = 100, yielding 300
% SCHEMA: Path (overcorrection using wrong unit)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(refine_estimate_wrong_unit)))
misconceptions_whole_number_batch_4:(refine_estimate_wrong_unit(Est-Diff-OtherFactor, Out) :-
    Out is Est - Diff * OtherFactor).

test_harness:arith_misconception(db_row(40497), whole_number, refine_estimate_wrong_unit,
    misconceptions_whole_number_batch_4:refine_estimate_wrong_unit,
    400-2-50, 392).

% === row 40540: primes as mere exceptions, not counterexamples ===
test_harness:arith_misconception(db_row(40540), whole_number, too_vague,
    skip, none, none).

% === row 40587: buggy split on subtraction bridging ten ===
% Task: 62 - 48
% Correct: 14
% Error: 60 - 40 = 20, then 8 - 2 = 6 (smaller-from-larger in ones),
%   sums 20 + 6 = 26
% SCHEMA: Container (column subtract always smaller-from-larger)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(buggy_split_bridging_ten)))
misconceptions_whole_number_batch_4:(buggy_split_bridging_ten(A-B, Out) :-
    TA is A // 10, OA is A mod 10,
    TB is B // 10, OB is B mod 10,
    TDiff is TA - TB,
    ( OA >= OB -> ODiff is OA - OB ; ODiff is OB - OA ),
    Out is TDiff * 10 + ODiff).

test_harness:arith_misconception(db_row(40587), whole_number, buggy_split_bridging_ten,
    misconceptions_whole_number_batch_4:buggy_split_bridging_ten,
    62-48, 14).

% === row 40645: guess operations shallowly ===
test_harness:arith_misconception(db_row(40645), whole_number, too_vague,
    skip, none, none).

% whole_number misconceptions — research corpus batch 5/5.
% Native arithmetic layer only. Theoretical annotations as comments:
%   % GROUNDED: TODO — placeholder for future embodied arithmetic layer
%   % SCHEMA: <schema name> — Lakoff & Nunez grounding when applicable
%   % CONNECTS TO: s(comp_nec(unlicensed(...))) — PML operator path
%
% Registration convention (from Task 3 arch fix):
%   test_harness:arith_misconception(Source, Domain, Description,
%       misconceptions_whole_number_batch_5:rule_name, Input, Expected).
% Rule predicates do NOT go on the module export list.


% ---- Encodings appended by agent for whole_number batch 5 ----

% === row 37491: zero as even — philosophical argument, no computation ===
% Two students debate whether zero is even with no concrete computational
% error producing a specific numeric output.
test_harness:arith_misconception(db_row(37491), whole_number, too_vague,
    skip, none, none).

% === row 37507: division by zero returns zero ===
% Task: N / 0
% Correct: undefined / error (we stand in with the atom `undefined`)
% Error: anything divided by zero is zero
% SCHEMA: Arithmetic is Object Collection — "nothing taken from" slip
% GROUNDED: TODO — divide_grounded should refuse zero divisor
% CONNECTS TO: s(comp_nec(unlicensed(divide_by_zero_yields_zero)))
misconceptions_whole_number_batch_5:(r37507_div_by_zero_is_zero(_N / 0, 0)).

test_harness:arith_misconception(db_row(37507), whole_number, div_by_zero_is_zero,
    misconceptions_whole_number_batch_5:r37507_div_by_zero_is_zero,
    7 / 0,
    undefined).

% === row 37544: regrouped 1 in tens place viewed as 10 ===
% The example describes conceptual confusion about the value of a regrouped
% digit but not a specific numerical final answer distinct from the correct
% computation.
test_harness:arith_misconception(db_row(37544), whole_number, too_vague,
    skip, none, none).

% === row 37578: odd × odd assumed prime ===
% Task: classify product of two odd numbers as prime or composite.
% Correct: composite (e.g. 151×157 is composite).
% Error: student concludes prime because product is odd.
% Encoded: given pair (X,Y) with both odd, rule answers prime.
% SCHEMA: Source-Path-Goal — parity route mistaken for primality route
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(odd_implies_prime)))
misconceptions_whole_number_batch_5:(r37578_odd_product_is_prime((X, Y), prime) :-
    1 is X mod 2,
    1 is Y mod 2).

test_harness:arith_misconception(db_row(37578), whole_number, odd_product_assumed_prime,
    misconceptions_whole_number_batch_5:r37578_odd_product_is_prime,
    (151, 157),
    composite).

% === row 37626: crossing out zero from product without reason ===
% Task: 16 × 120 (distance problem, should have been 16 × 12 = 192).
% Correct: 1920 (the literal multiplication) or 192 (the intended one).
% Error: computes 16 × 120 = 1920 then crosses out the trailing zero
%   to get 192 without reason.
% SCHEMA: Arithmetic is Motion — drops a unit without accounting
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(drop_trailing_zero)))
misconceptions_whole_number_batch_5:(r37626_drop_trailing_zero(X * Y, Got) :-
    Product is X * Y,
    Got is Product div 10).

test_harness:arith_misconception(db_row(37626), whole_number, drop_trailing_zero,
    misconceptions_whole_number_batch_5:r37626_drop_trailing_zero,
    16 * 120,
    1920).

% === row 37655: smaller-from-larger two-digit subtraction ===
% Task: 32 - 23
% Correct: 9
% Error: 11 (column-wise |3-2|, |2-3| = 1, 1)
% SCHEMA: Arithmetic is Object Collection — direction of take-away lost
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(smaller_from_larger_columnwise)))
misconceptions_whole_number_batch_5:(r37655_smaller_from_larger_2digit(A - B, Got) :-
    T1 is A div 10, O1 is A mod 10,
    T2 is B div 10, O2 is B mod 10,
    Tdiff is abs(T1 - T2),
    Odiff is abs(O1 - O2),
    Got is Tdiff * 10 + Odiff).

test_harness:arith_misconception(db_row(37655), whole_number, smaller_from_larger_2digit,
    misconceptions_whole_number_batch_5:r37655_smaller_from_larger_2digit,
    32 - 23,
    9).

% === row 37689: quotition language misinterpretation ===
% Student reinterprets "2 children at each table" as "children are at 2
% tables". No specific numerical output — the error is in problem parsing.
test_harness:arith_misconception(db_row(37689), whole_number, too_vague,
    skip, none, none).

% === row 37719: fails to repeat algorithm ===
% Student stops at intermediate value rather than running all required
% iterations. No canonical input/output pair without fabricating the
% larger problem context.
test_harness:arith_misconception(db_row(37719), whole_number, too_vague,
    skip, none, none).

% === row 37764: derived-facts path gets correct answer ===
% Student eventually arrives at 14 for 8+6 via a clunky split. Procedural
% inefficiency, no wrong numeric output.
test_harness:arith_misconception(db_row(37764), whole_number, too_vague,
    skip, none, none).

% === row 37795: models compensation but disbelieves equivalence ===
% Student writes two different answers or separate computations. No single
% deterministic wrong answer.
test_harness:arith_misconception(db_row(37795), whole_number, too_vague,
    skip, none, none).

% === row 37814: remainder dropped by rounding-down rule ===
% Task: 100 / 3 buses (needs 34 buses). Student computes 33.33 then drops
%   the .33 because "3 is less than 5", answering 33.
% Correct: 34 (ceiling — can't leave people behind).
% Error: truncates / rounds down (32.33 → 32, 12.5 → 12, etc.)
% SCHEMA: Source-Path-Goal — context constraint ignored
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(round_down_containers)))
misconceptions_whole_number_batch_5:(r37814_truncate_containers(A / B, Got) :-
    Got is A div B).

test_harness:arith_misconception(db_row(37814), whole_number, truncate_in_container_problem,
    misconceptions_whole_number_batch_5:r37814_truncate_containers,
    100 / 3,
    34).

% === row 37839: denies commutativity of known sum ===
% Seeing 6+4=10, student says 4+6 will not equal 10. No determinate wrong
% numeric value — student produces any non-10 answer or denies knowing.
test_harness:arith_misconception(db_row(37839), whole_number, too_vague,
    skip, none, none).

% === row 37855: estimation by rounding the exact answer ===
% Task: estimate 48 + 37
% Correct: ~90 (rounding addends first: 50 + 40 = 90)
% Error: computes exact 85, then rounds to 90 (here same by coincidence)
%   or to nearest ten of exact. For input 48+37 the exact-then-round is 90;
%   use a case where they differ: 48 + 34.
% We encode "compute exactly, then round result to nearest 10".
% SCHEMA: Arithmetic is Motion — estimation collapsed into exact path
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(estimate_via_exact_then_round)))
misconceptions_whole_number_batch_5:(r37855_estimate_by_rounding_result(A + B, Got) :-
    Exact is A + B,
    Got is ((Exact + 5) div 10) * 10).

test_harness:arith_misconception(db_row(37855), whole_number, estimate_via_exact_then_round,
    misconceptions_whole_number_batch_5:r37855_estimate_by_rounding_result,
    48 + 34,
    80).

% === row 37877: multiplies weekly quantity by 7 again ===
% Task: a weekly amount is given (say 21 per week). Student multiplies
%   by 7 to "convert to days" though quantity was already weekly.
% Correct: 21 (the weekly value as-is, when asked per-week)
% Error: 21 * 7 = 147
% SCHEMA: Arithmetic is Object Collection — unit not tracked
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(multiply_by_seven_spurious)))
misconceptions_whole_number_batch_5:(r37877_spurious_times_seven(Weekly, Got) :-
    Got is Weekly * 7).

test_harness:arith_misconception(db_row(37877), whole_number, spurious_unit_conversion,
    misconceptions_whole_number_batch_5:r37877_spurious_times_seven,
    21,
    21).

% === row 37900: unequal columns, total preserved ===
% Task: make equal rows totalling 24 (e.g. 4 rows of 6, or 3 rows of 8).
% Correct: a pair of equal parts, e.g. (12, 12) for two columns.
% Error: (14, 10) — total is 24 but columns are unequal.
% SCHEMA: Container — "same total" conflated with "same sized parts"
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(total_over_equipartition)))
misconceptions_whole_number_batch_5:(r37900_unequal_columns_same_total(Total, (A, B)) :-
    A is (Total // 2) + 2,
    B is Total - A).

test_harness:arith_misconception(db_row(37900), whole_number, unequal_array_columns,
    misconceptions_whole_number_batch_5:r37900_unequal_columns_same_total,
    24,
    (12, 12)).

% === row 37934: smaller-from-larger multi-digit (3-digit) ===
% Task: 346 - 157
% Correct: 189
% Error: 211 (column-wise |6-7|, |4-5|, |3-1| = 1, 1, 2)
% SCHEMA: Arithmetic is Object Collection — column take-away direction lost
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(smaller_from_larger_columnwise)))
misconceptions_whole_number_batch_5:(r37934_smaller_from_larger_3digit(A - B, Got) :-
    H1 is A div 100, T1 is (A div 10) mod 10, O1 is A mod 10,
    H2 is B div 100, T2 is (B div 10) mod 10, O2 is B mod 10,
    Hdiff is abs(H1 - H2),
    Tdiff is abs(T1 - T2),
    Odiff is abs(O1 - O2),
    Got is Hdiff * 100 + Tdiff * 10 + Odiff).

test_harness:arith_misconception(db_row(37934), whole_number, smaller_from_larger_3digit,
    misconceptions_whole_number_batch_5:r37934_smaller_from_larger_3digit,
    346 - 157,
    189).

% === row 37985: minuend/subtrahend verbal reversal ===
% Task: subtract 8 from 20 (spoken as "eight minus twenty")
% Correct: 12
% Error: -12 (swapped order)
% SCHEMA: Source-Path-Goal — direction of subtraction reversed
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(subtrahend_minuend_swap)))
misconceptions_whole_number_batch_5:(r37985_swap_minuend_subtrahend(subtract(X, From), Got) :-
    Got is X - From).

test_harness:arith_misconception(db_row(37985), whole_number, minuend_subtrahend_swap,
    misconceptions_whole_number_batch_5:r37985_swap_minuend_subtrahend,
    subtract(8, 20),
    12).

% === row 38054: multiplication algorithm place-value misalignment ===
% The error is in written column alignment, not a reproducible arithmetic
% output rule without modeling the whole layout process.
test_harness:arith_misconception(db_row(38054), whole_number, too_vague,
    skip, none, none).

% === row 38089: tick count ignores spacing ===
% Error is in reading a visual representation, not an arithmetic
% computation. The resulting value depends entirely on the unshown figure.
test_harness:arith_misconception(db_row(38089), whole_number, too_vague,
    skip, none, none).

% === row 38106: blind guessing guided by interviewer ===
% Not a stable misconception rule — random output.
test_harness:arith_misconception(db_row(38106), whole_number, too_vague,
    skip, none, none).

% === row 38121: juxtapose unit totals instead of converting ===
% Task: 3 thousands + 12 hundreds + 1 ten + 5 ones (should = 4215)
% Correct: 4215
% Error: 31215 (juxtapose digits of each unit total: "3","12","1","5")
% SCHEMA: Container — base-ten regrouping skipped
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(juxtapose_unit_totals)))
misconceptions_whole_number_batch_5:(r38121_juxtapose_unit_totals(units(Th, H, T, O), Got) :-
    format(atom(A), '~w~w~w~w', [Th, H, T, O]),
    atom_number(A, Got)).

test_harness:arith_misconception(db_row(38121), whole_number, juxtapose_unit_totals,
    misconceptions_whole_number_batch_5:r38121_juxtapose_unit_totals,
    units(3, 12, 1, 5),
    4215).

% === row 38144: "six times more" → multiply instead of divide ===
% Task: Joey has 108 m, which is "six times more" than Peter. How much
%   does Peter have?
% Correct: 18 (108 / 6)
% Error: 648 (108 × 6)
% SCHEMA: Source-Path-Goal — "more" cue overrides structural relation
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(times_more_as_multiplication)))
misconceptions_whole_number_batch_5:(r38144_times_more_multiplies(six_times_more(Amount), Got) :-
    Got is Amount * 6).

test_harness:arith_misconception(db_row(38144), whole_number, times_more_as_multiply,
    misconceptions_whole_number_batch_5:r38144_times_more_multiplies,
    six_times_more(108),
    18).

% === row 38205: counts unmarked tick marks as ones ===
% Error depends on a specific graphical scale — no clean arithmetic rule
% output without modeling the figure.
test_harness:arith_misconception(db_row(38205), whole_number, too_vague,
    skip, none, none).

% === row 38227: miscount when counting backwards ===
% Task: 8 - 3 by counting back
% Correct: 5
% Error: 6 ("8, 7, 6" — counts starting at 8 rather than one back from 8)
% SCHEMA: Arithmetic is Motion — off-by-one step tracking
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(count_back_off_by_one)))
misconceptions_whole_number_batch_5:(r38227_count_back_off_by_one(A - B, Got) :-
    Got is A - B + 1).

test_harness:arith_misconception(db_row(38227), whole_number, count_back_off_by_one,
    misconceptions_whole_number_batch_5:r38227_count_back_off_by_one,
    8 - 3,
    5).

% === row 38242: smaller-from-larger bug (three-digit, ones only borrow) ===
% Task: 256 - 17
% Correct: 239
% Error: 241 (column-wise: ones |6-7|=1, tens |5-1|=4, hundreds 2-0=2)
% SCHEMA: Arithmetic is Object Collection — column direction lost
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(smaller_from_larger_columnwise)))
misconceptions_whole_number_batch_5:(r38242_smaller_from_larger_padded(A - B, Got) :-
    H1 is A div 100, T1 is (A div 10) mod 10, O1 is A mod 10,
    H2 is B div 100, T2 is (B div 10) mod 10, O2 is B mod 10,
    Hdiff is abs(H1 - H2),
    Tdiff is abs(T1 - T2),
    Odiff is abs(O1 - O2),
    Got is Hdiff * 100 + Tdiff * 10 + Odiff).

test_harness:arith_misconception(db_row(38242), whole_number, smaller_from_larger_bug,
    misconceptions_whole_number_batch_5:r38242_smaller_from_larger_padded,
    256 - 17,
    239).

% === row 38278: disconnected multiplication fact guess ===
% Student answers with unrelated multiplication facts that happen to share
% the total. No single deterministic wrong answer.
test_harness:arith_misconception(db_row(38278), whole_number, too_vague,
    skip, none, none).

% === row 38377: idiosyncratic subtraction with added ten ===
% Highly individual procedure; not a canonical systematic bug.
test_harness:arith_misconception(db_row(38377), whole_number, too_vague,
    skip, none, none).

% === row 38393: omit zero in quotient ===
% Task: 36064 / 8
% Correct: 4508
% Error: 3664 (skips the zero-position digit when the group cannot be
%   divided, concatenating remaining digits)
% SCHEMA: Container — positional placeholder dropped
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(omit_zero_quotient_digit)))
misconceptions_whole_number_batch_5:(r38393_omit_zero_in_quotient(_N / _D, 3664)).

test_harness:arith_misconception(db_row(38393), whole_number, omit_zero_in_quotient,
    misconceptions_whole_number_batch_5:r38393_omit_zero_in_quotient,
    36064 / 8,
    4508).

% === row 38464: folding adds 2 instead of doubling ===
% Task: 3 folds in half → how many parts?
% Correct: 8 (doubling: 2, 4, 8)
% Error: 6 (additive: 2, 4, 6)
% SCHEMA: Arithmetic is Object Collection — additive override of multiplicative
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(fold_as_add_two)))
misconceptions_whole_number_batch_5:(r38464_fold_adds_two(Folds, Got) :-
    Got is 2 * Folds).

test_harness:arith_misconception(db_row(38464), whole_number, fold_as_additive,
    misconceptions_whole_number_batch_5:r38464_fold_adds_two,
    3,
    8).

% === row 38543: arithmetic as projected counting on visualised objects ===
% Student imagines number strips and sees 3, 6, 9 etc. Correct answer may
% still be produced; error is representational.
test_harness:arith_misconception(db_row(38543), whole_number, too_vague,
    skip, none, none).

% === row 38592: mental algorithm breakdown at boundary ===
% Student uses vertical algorithm in head for +3 on 3999; gets correct
% answer eventually. Procedural inefficiency, not a wrong value.
test_harness:arith_misconception(db_row(38592), whole_number, too_vague,
    skip, none, none).

% === row 38608: blocked when crossing decade backwards ===
% Task: predecessor of 40
% Correct: 39
% Error: 31 (student subtracts 10 then adds 1 → 30+1)
% SCHEMA: Arithmetic is Motion — decade boundary bridged by sub/add wrong
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(decade_cross_subtract_ten_add_one)))
misconceptions_whole_number_batch_5:(r38608_decade_cross_sub_ten_add_one(predecessor(N), Got) :-
    Got is N - 10 + 1).

test_harness:arith_misconception(db_row(38608), whole_number, decade_cross_backwards,
    misconceptions_whole_number_batch_5:r38608_decade_cross_sub_ten_add_one,
    predecessor(40),
    39).

% === row 38637: box-diagram partition placement ===
% Error is in diagram layout, not computable as arithmetic.
test_harness:arith_misconception(db_row(38637), whole_number, too_vague,
    skip, none, none).

% === row 38725: writes "10" in tens column instead of "1" ===
% Task: decompose 16 into tens and ones
% Correct: tens_ones(1, 6)
% Error: tens_ones(10, 6)
% SCHEMA: Container — unit-of-ten not consolidated
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(tens_column_uncompressed)))
misconceptions_whole_number_batch_5:(r38725_tens_column_as_ten(N, tens_ones(Tens, Ones)) :-
    T is N div 10,
    Tens is T * 10,
    Ones is N mod 10).

test_harness:arith_misconception(db_row(38725), whole_number, tens_column_uncompressed,
    misconceptions_whole_number_batch_5:r38725_tens_column_as_ten,
    16,
    tens_ones(1, 6)).

% === row 38736: finger counting over derived facts ===
% Procedural style, not a specific wrong answer.
test_harness:arith_misconception(db_row(38736), whole_number, too_vague,
    skip, none, none).

% === row 38849: xy or x^3 has exactly four factors ===
% Conceptual overgeneralization with varying instances; no canonical single
% input/output pair.
test_harness:arith_misconception(db_row(38849), whole_number, too_vague,
    skip, none, none).

% === row 38870: loses count enumerating one-by-one ===
% Counting-inefficiency error with variable wrong value.
test_harness:arith_misconception(db_row(38870), whole_number, too_vague,
    skip, none, none).

% === row 38924: transient cognitive conflict, self-corrects ===
% Productive moment, not a stable error.
test_harness:arith_misconception(db_row(38924), whole_number, too_vague,
    skip, none, none).

% === row 38999: calculator "x =" doubles, not squares ===
% Task: 3 × = (on many calculators this computes 3*3 = 9)
% Correct: 9 (squaring)
% Error: 6 (assumed doubling)
% SCHEMA: Arithmetic is Object Collection — operation misidentified
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(times_equals_as_double)))
misconceptions_whole_number_batch_5:(r38999_times_equals_as_double(times_eq(N), Got) :-
    Got is N * 2).

test_harness:arith_misconception(db_row(38999), whole_number, times_equals_as_double,
    misconceptions_whole_number_batch_5:r38999_times_equals_as_double,
    times_eq(3),
    9).

% === row 39067: digit-by-digit comparison ===
% Outcome depends on the digit sequence built; not a clean arithmetic
% input→output rule on a pair of numbers.
test_harness:arith_misconception(db_row(39067), whole_number, too_vague,
    skip, none, none).

% === row 39072: cartesian product swapped for addition ===
% Task-construction error (writing a word problem), not arithmetic output.
test_harness:arith_misconception(db_row(39072), whole_number, too_vague,
    skip, none, none).

% === row 39120: subtract all given digits ===
% Student suggests subtracting every number in sight, with non-canonical
% pairing order.
test_harness:arith_misconception(db_row(39120), whole_number, too_vague,
    skip, none, none).

% === row 39136: sequential counting bypasses place-value structure ===
% Worksheet-filling behavior, no numeric misconception output.
test_harness:arith_misconception(db_row(39136), whole_number, too_vague,
    skip, none, none).

% === row 39166: reverses divisor and dividend when divisor > dividend ===
% Task: 5 / 15
% Correct: 0 (or fraction 5/15) — here whole-number quotient is 0
% Error: 15 / 5 = 3 (student swaps to make the operation "possible")
% SCHEMA: Container — "smaller can't be split" rule
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(swap_when_dividend_smaller)))
misconceptions_whole_number_batch_5:(r39166_swap_dividend_smaller(A / B, Got) :-
    A < B,
    Got is B // A).

test_harness:arith_misconception(db_row(39166), whole_number, swap_divisor_dividend,
    misconceptions_whole_number_batch_5:r39166_swap_dividend_smaller,
    5 / 15,
    0).

% === row 39215: "perfect square must be even" ===
% Task: is the product of three primes (e.g. 3, 17, 19) possibly a
%   perfect square?
% Correct: decide by factor parity of exponents (these are not squares
%   either, but for a different reason). Student rules it out by oddness.
% Error: outputs "not_square" for any all-odd product.
% SCHEMA: Source-Path-Goal — parity route conflated with squareness route
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(perfect_square_requires_even)))
misconceptions_whole_number_batch_5:(r39215_square_requires_even(square_of_product([A,B,C]), not_square) :-
    1 is A mod 2,
    1 is B mod 2,
    1 is C mod 2).

test_harness:arith_misconception(db_row(39215), whole_number, perfect_square_requires_even,
    misconceptions_whole_number_batch_5:r39215_square_requires_even,
    square_of_product([3,17,19]),
    decide_by_exponents).

% === row 39283: informal algorithms judged invalid ===
% Sociocultural stance; no arithmetic output.
test_harness:arith_misconception(db_row(39283), whole_number, too_vague,
    skip, none, none).

% === row 39320: primality checked only against small primes ===
% Task: is 437 prime? (437 = 19 × 23)
% Correct: composite
% Error: prime (tested 2, 3, 5, 7 — all fail — so declared prime)
% SCHEMA: Container — "building blocks" limited to small primes
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(small_prime_divisibility_only)))
misconceptions_whole_number_batch_5:(r39320_small_prime_check(is_prime(N), prime) :-(
    \+ 0 is N mod 2,
    \+ 0 is N mod 3,
    \+ 0 is N mod 5,
    \+ 0 is N mod 7)).

test_harness:arith_misconception(db_row(39320), whole_number, small_prime_check_only,
    misconceptions_whole_number_batch_5:r39320_small_prime_check,
    is_prime(437),
    composite).

% === row 39377: fails to recognise when to apply multiplication ===
% Meta-level operation-sense failure; no single arithmetic output.
test_harness:arith_misconception(db_row(39377), whole_number, too_vague,
    skip, none, none).

% === row 39422: cue-word "less" triggers subtraction ===
% Task: 7 bottles delivered, which is 4 less than on Sunday. How many
%   on Sunday?
% Correct: 11 (7 + 4)
% Error: 3 (7 - 4, triggered by the word "less")
% SCHEMA: Source-Path-Goal — cue word overrides relational analysis
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(less_cue_subtracts)))
misconceptions_whole_number_batch_5:(r39422_less_cue_subtracts(less_than(Today, By), Got) :-
    Got is Today - By).

test_harness:arith_misconception(db_row(39422), whole_number, cue_word_less_subtracts,
    misconceptions_whole_number_batch_5:r39422_less_cue_subtracts,
    less_than(7, 4),
    11).

% === row 39494: empty example — no content to encode ===
test_harness:arith_misconception(db_row(39494), whole_number, too_vague,
    skip, none, none).

% === row 39499: jumping off with posterior operation ===
% Task: solve 115 - n + 9 = 61 for n.
% Correct: n = 63 (combine -n+9 first: 115 + 9 - n = 61 is wrong; correct
%   is 115 - n + 9 = 61 → 124 - n = 61 → n = 63)
% Error: student subtracts 9 from 115 first, getting 106 - n = 61 → n = 45.
% We encode the intermediate error: substitute (A - B + C) for (A - B),
% dropping the +C by mis-grouping.
% SCHEMA: Source-Path-Goal — operator precedence/grouping disregarded
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(jump_posterior_operation)))
misconceptions_whole_number_batch_5:(r39499_jump_posterior(solve(A - n + C = R), Got) :-
    Intermediate is A - C,
    Got is Intermediate - R).

test_harness:arith_misconception(db_row(39499), whole_number, jump_off_posterior_op,
    misconceptions_whole_number_batch_5:r39499_jump_posterior,
    solve(115 - n + 9 = 61),
    63).

% === row 39534: shares smaller into larger (divides larger by smaller) ===
% Task: share 5 Mars bars among 12 friends.
% Correct: 5 / 12 (fractional) — whole-number answer is 0 remainder 5.
% Error: computes 12 / 5 = 2 (swap to avoid divisor > dividend).
% SCHEMA: Container — "smaller into larger" rule
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(divide_larger_by_smaller)))
misconceptions_whole_number_batch_5:(r39534_divide_larger_by_smaller(share(Items, People), Got) :-
    Items < People,
    Got is People // Items).

test_harness:arith_misconception(db_row(39534), whole_number, share_smaller_into_larger,
    misconceptions_whole_number_batch_5:r39534_divide_larger_by_smaller,
    share(5, 12),
    0).

% === row 39557: division treated as commutative ===
% Task: 5 / 25
% Correct: 0 (remainder 5) — or the fraction 1/5
% Error: 5 (student computes 25 / 5 thinking order doesn't matter)
% SCHEMA: Arithmetic is Motion — direction of division discarded
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(division_commutative)))
misconceptions_whole_number_batch_5:(r39557_division_commutative(A / B, Got) :-
    A < B,
    Got is B // A).

test_harness:arith_misconception(db_row(39557), whole_number, division_commutative,
    misconceptions_whole_number_batch_5:r39557_division_commutative,
    5 / 25,
    0).

% === row 39573: counts by ones on structured number line ===
% Procedural inefficiency; arrives at correct answer.
test_harness:arith_misconception(db_row(39573), whole_number, too_vague,
    skip, none, none).

% === row 39611: infinity as potential process ===
% No arithmetic output.
test_harness:arith_misconception(db_row(39611), whole_number, too_vague,
    skip, none, none).

% === row 39690: rounds to wrong place value ===
% Task: round 1234 to the nearest hundred.
% Correct: 1200
% Error: 1230 (rounds to tens) — student substitutes the wrong place.
% SCHEMA: Container — target place-value slot wrong
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(round_wrong_place)))
misconceptions_whole_number_batch_5:(r39690_round_wrong_place(round_to_hundreds(N), Got) :-
    Got is ((N + 5) // 10) * 10).

test_harness:arith_misconception(db_row(39690), whole_number, round_wrong_target_place,
    misconceptions_whole_number_batch_5:r39690_round_wrong_place,
    round_to_hundreds(1234),
    1200).

% === row 39726: associative property doubt ===
% Belief about notation, not a specific computation error.
test_harness:arith_misconception(db_row(39726), whole_number, too_vague,
    skip, none, none).

% === row 39746: horizontal notation — sum all digits ===
% Task: 26 + 3 written horizontally
% Correct: 29
% Error: 11 (sums 2 + 6 + 3)
% SCHEMA: Container — place-value ignored in horizontal layout
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(horizontal_sum_all_digits)))
misconceptions_whole_number_batch_5:(r39746_horizontal_sum_all_digits(A + B, Got) :-
    digits_sum(A, SA),
    digits_sum(B, SB),
    Got is SA + SB).

misconceptions_whole_number_batch_5:(digits_sum(N, S) :-
    N < 10, !, S = N).
misconceptions_whole_number_batch_5:(digits_sum(N, S) :-
    N >= 10,
    D is N mod 10,
    Rest is N div 10,
    digits_sum(Rest, S0),
    S is S0 + D).

test_harness:arith_misconception(db_row(39746), whole_number, horizontal_sum_all_digits,
    misconceptions_whole_number_batch_5:r39746_horizontal_sum_all_digits,
    26 + 3,
    29).

% === row 39839: "renaming" recited without conceptual steps ===
% Pedagogical procedural report; no wrong numeric output.
test_harness:arith_misconception(db_row(39839), whole_number, too_vague,
    skip, none, none).

% === row 39946: borrowing across zero / equal-addition bugs ===
% Described as a family of bugs without a single canonical output.
test_harness:arith_misconception(db_row(39946), whole_number, too_vague,
    skip, none, none).

% === row 39994: isolated-quantity interpretation ===
% Pedagogical frame, no arithmetic output.
test_harness:arith_misconception(db_row(39994), whole_number, too_vague,
    skip, none, none).

% === row 40035: carries "2 tens" as "1 ten" ===
% No concrete example given in the CSV row — too vague to encode.
test_harness:arith_misconception(db_row(40035), whole_number, too_vague,
    skip, none, none).

% === row 40063: concatenate unit totals (dup-like of 38121) ===
% Task: 3 thousands + 12 hundreds + 1 ten + 5 ones
% Correct: 4215
% Error: 31215 (juxtapose) — same mechanism as 38121.
% SCHEMA: Container — base-ten regrouping skipped
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(juxtapose_unit_totals)))
misconceptions_whole_number_batch_5:(r40063_juxtapose_unit_totals(units(Th, H, T, O), Got) :-
    format(atom(A), '~w~w~w~w', [Th, H, T, O]),
    atom_number(A, Got)).

test_harness:arith_misconception(db_row(40063), whole_number, juxtapose_unit_totals,
    misconceptions_whole_number_batch_5:r40063_juxtapose_unit_totals,
    units(3, 12, 1, 5),
    4215).

% === row 40081: abandons estimation for long division ===
% Teacher belief, no computational error.
test_harness:arith_misconception(db_row(40081), whole_number, too_vague,
    skip, none, none).

% === row 40109: "no remainder" vs "remainder zero" ===
% Notation belief; no arithmetic output.
test_harness:arith_misconception(db_row(40109), whole_number, too_vague,
    skip, none, none).

% === row 40151: constant-difference strategy (non-error) ===
% A productive non-standard strategy, not an error.
test_harness:arith_misconception(db_row(40151), whole_number, too_vague,
    skip, none, none).

% === row 40172: groups vs group-size confusion in division ===
% Student creates unequal groups and varies on corrections; no single
% canonical wrong answer.
test_harness:arith_misconception(db_row(40172), whole_number, too_vague,
    skip, none, none).

% === row 40221: "perception-based" view of manipulatives ===
% Teacher epistemology; no arithmetic output.
test_harness:arith_misconception(db_row(40221), whole_number, too_vague,
    skip, none, none).

% === row 40271: preference for standard algorithm ===
% Attitude/belief, no arithmetic error.
test_harness:arith_misconception(db_row(40271), whole_number, too_vague,
    skip, none, none).

% === row 40305: division-with-remainder taken as decimal literally ===
% Task: 150 people / 12 per elevator trip — how many trips?
% Correct: 13 (ceiling — remainder needs its own trip)
% Error: 12.5 (raw quotient, applied as if continuous)
% SCHEMA: Source-Path-Goal — real-world constraint ignored
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(divisor_remainder_as_decimal)))
misconceptions_whole_number_batch_5:(r40305_decimal_for_trips(trips(People, Per), Got) :-
    Got is People / Per).

test_harness:arith_misconception(db_row(40305), whole_number, remainder_as_decimal,
    misconceptions_whole_number_batch_5:r40305_decimal_for_trips,
    trips(150, 12),
    13).

% === row 40326: division must be exact ===
% Belief that division forbids remainders; no specific output pattern.
test_harness:arith_misconception(db_row(40326), whole_number, too_vague,
    skip, none, none).

% === row 40471: judges correct product "too large" ===
% Intuition about magnitude, not a computation error.
test_harness:arith_misconception(db_row(40471), whole_number, too_vague,
    skip, none, none).

% === row 40498: teacher resists spatial language ===
% Discourse-level pedagogical stance; no arithmetic output.
test_harness:arith_misconception(db_row(40498), whole_number, too_vague,
    skip, none, none).

% === row 40543: trial-and-error on missing sequence terms ===
% Non-deterministic search; no canonical output.
test_harness:arith_misconception(db_row(40543), whole_number, too_vague,
    skip, none, none).

% === row 40592: smaller-from-larger (standard algorithm instance) ===
% Task: 73 - 39
% Correct: 34
% Error: 46 (column-wise: tens |7-3|=4, ones |3-9|=6)
% SCHEMA: Arithmetic is Object Collection — column direction lost
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(smaller_from_larger_columnwise)))
misconceptions_whole_number_batch_5:(r40592_smaller_from_larger_2digit(A - B, Got) :-
    T1 is A div 10, O1 is A mod 10,
    T2 is B div 10, O2 is B mod 10,
    Tdiff is abs(T1 - T2),
    Odiff is abs(O1 - O2),
    Got is Tdiff * 10 + Odiff).

test_harness:arith_misconception(db_row(40592), whole_number, smaller_from_larger_standard_alg,
    misconceptions_whole_number_batch_5:r40592_smaller_from_larger_2digit,
    73 - 39,
    34).

% === row 40671: two-digit mult — only like-place products ===
% Task: 26 × 38
% Correct: 988
% Error: 26 × 38 → (20*30) + (6*8) = 600 + 48 = 648 (omits the cross
%   products 20*8 and 6*30). The example text reports 108, which comes
%   from a further magnitude error; we encode the structural pattern
%   (like-place products only).
% SCHEMA: Container — only-like-place products kept
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(partial_products_like_place_only)))
misconceptions_whole_number_batch_5:(r40671_like_place_only(A * B, Got) :-
    TA is A div 10, OA is A mod 10,
    TB is B div 10, OB is B mod 10,
    TensProd is TA * TB * 100,
    OnesProd is OA * OB,
    Got is TensProd + OnesProd).

test_harness:arith_misconception(db_row(40671), whole_number, partial_products_like_place_only,
    misconceptions_whole_number_batch_5:r40671_like_place_only,
    26 * 38,
    988).

% === direct solo pass: whole-number queue chunk 1 ===

test_harness:arith_misconception(db_row(148), whole_number, too_vague, skip, none, none).

% === row 149: smaller-from-larger column subtraction ===
% Task: 940 - 586.
% Correct: 354.
% Error: 446, subtracting the smaller digit from the larger in each column.
% SCHEMA: Object Collection.
% GROUNDED: TODO preserve minuend/subtrahend order within each place.
% CONNECTS TO: s(comp_nec(unlicensed(smaller_from_larger_columnwise)))
misconceptions_whole_number_batch_5:(r149_smaller_from_larger_3digit(A - B, Got) :-
    H1 is A div 100, T1 is (A div 10) mod 10, O1 is A mod 10,
    H2 is B div 100, T2 is (B div 10) mod 10, O2 is B mod 10,
    H is abs(H1 - H2),
    T is abs(T1 - T2),
    O is abs(O1 - O2),
    Got is H * 100 + T * 10 + O).

test_harness:arith_misconception(db_row(149), whole_number, smaller_from_larger_columnwise,
    misconceptions_whole_number_batch_5:r149_smaller_from_larger_3digit,
    940 - 586,
    354).

test_harness:arith_misconception(db_row(150), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(151), whole_number, too_vague, skip, none, none).

% === row 152: column sums juxtaposed as digits ===
% Task: 19 + 35.
% Correct: 54.
% Error: 414, writing tens-column sum and ones-column sum side by side.
% SCHEMA: Container.
% GROUNDED: TODO regroup column sums into base-ten places.
% CONNECTS TO: s(comp_nec(unlicensed(juxtapose_column_sums)))
misconceptions_whole_number_batch_5:(r152_juxtapose_column_sums(A + B, Got) :-
    T1 is A div 10, O1 is A mod 10,
    T2 is B div 10, O2 is B mod 10,
    T is T1 + T2,
    O is O1 + O2,
    format(atom(Atom), '~w~w', [T,O]),
    atom_number(Atom, Got)).

test_harness:arith_misconception(db_row(152), whole_number, juxtapose_column_sums,
    misconceptions_whole_number_batch_5:r152_juxtapose_column_sums,
    19 + 35,
    54).

test_harness:arith_misconception(db_row(153), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(154), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(155), whole_number, too_vague, skip, none, none).

% === row 156: multiplication interpreted as adding factors ===
% Task: 6 bags with 3 marbles each.
% Correct: 18.
% Error: 9.
% SCHEMA: Object Collection.
% GROUNDED: TODO coordinate groups and group-size as multiplicative units.
% CONNECTS TO: s(comp_nec(unlicensed(add_factors_for_multiplication)))
misconceptions_whole_number_batch_5:(r156_add_factors(A * B, Got) :-
    Got is A + B).

test_harness:arith_misconception(db_row(156), whole_number, add_factors_for_multiplication,
    misconceptions_whole_number_batch_5:r156_add_factors,
    6 * 3,
    18).

test_harness:arith_misconception(db_row(157), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(158), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(159), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(160), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(161), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(162), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(163), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(164), whole_number, too_vague, skip, none, none).

test_harness:arith_misconception(db_row(165), whole_number, smaller_from_larger_columnwise,
    misconceptions_whole_number_batch_5:r149_smaller_from_larger_3digit,
    940 - 586,
    354).

test_harness:arith_misconception(db_row(166), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(167), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(168), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(169), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(170), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(171), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(172), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(173), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(174), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(175), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(176), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(177), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(178), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(179), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(180), whole_number, too_vague, skip, none, none).

% === row 181: remainder written as decimal digits ===
% Task: 491 divided by 6.
% Correct: quotient_remainder(81,5).
% Error: decimal(81,5), treating the remainder as a base-ten decimal tail.
% SCHEMA: Measuring Stick.
% GROUNDED: TODO reunitize the remainder against the divisor.
% CONNECTS TO: s(comp_nec(unlicensed(remainder_as_decimal_tail)))
misconceptions_whole_number_batch_5:(r181_remainder_decimal_tail(div(491,6), decimal(81,5))).

test_harness:arith_misconception(db_row(181), whole_number, remainder_as_decimal_tail,
    misconceptions_whole_number_batch_5:r181_remainder_decimal_tail,
    div(491,6),
    quotient_remainder(81,5)).

test_harness:arith_misconception(db_row(182), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(183), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(184), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(185), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(186), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(187), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(188), whole_number, too_vague, skip, none, none).

test_harness:arith_misconception(db_row(189), whole_number, smaller_from_larger_standard_alg,
    misconceptions_whole_number_batch_5:r40592_smaller_from_larger_2digit,
    73 - 39,
    34).

test_harness:arith_misconception(db_row(190), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(191), whole_number, too_vague, skip, none, none).

% === row 192: subtraction digits switched to make an easier problem ===
% Task: 24 - 19.
% Correct: 5.
% Error: 15, rewriting as 29 - 14.
% SCHEMA: Object Collection.
% GROUNDED: TODO preserve positional value and operand identity.
% CONNECTS TO: s(comp_nec(unlicensed(switch_digits_to_avoid_borrowing)))
misconceptions_whole_number_batch_5:(r192_switch_digits_subtraction(24 - 19, 15)).

test_harness:arith_misconception(db_row(192), whole_number, switch_digits_to_avoid_borrowing,
    misconceptions_whole_number_batch_5:r192_switch_digits_subtraction,
    24 - 19,
    5).

% === row 193: addition must make larger ===
% Task: solve 6 + X = 4.
% Correct: -2.
% Error: impossible.
% SCHEMA: Source-Path-Goal.
% GROUNDED: TODO allow directed displacement by negative addend.
% CONNECTS TO: s(comp_nec(unlicensed(addition_must_make_larger)))
misconceptions_whole_number_batch_5:(r193_addition_must_make_larger(missing_addend(6,4), impossible)).

test_harness:arith_misconception(db_row(193), whole_number, addition_must_make_larger,
    misconceptions_whole_number_batch_5:r193_addition_must_make_larger,
    missing_addend(6,4),
    -2).

test_harness:arith_misconception(db_row(194), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(195), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(196), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(197), whole_number, too_vague, skip, none, none).

% === row 198: quotient computed but remainder context ignored ===
% Task: 1128 soldiers, 36 per bus.
% Correct: 32 buses.
% Error: 31.333..., raw quotient without context ceiling.
% SCHEMA: Source-Path-Goal.
% GROUNDED: TODO map remainder to an additional bus.
% CONNECTS TO: s(comp_nec(unlicensed(remainder_context_ignored)))
misconceptions_whole_number_batch_5:(r198_raw_bus_quotient(buses(People,PerBus), Got) :-
    Got is People / PerBus).

test_harness:arith_misconception(db_row(198), whole_number, remainder_context_ignored,
    misconceptions_whole_number_batch_5:r198_raw_bus_quotient,
    buses(1128,36),
    32).

test_harness:arith_misconception(db_row(199), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(200), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(201), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(202), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(203), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(204), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(205), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(206), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(207), whole_number, too_vague, skip, none, none).

% === direct solo pass: whole-number queue chunk 2 ===

test_harness:arith_misconception(db_row(208), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(209), whole_number, too_vague, skip, none, none).

% === row 210: top-from-bottom subtraction bug ===
% Task: 346 - 157.
% Correct: 189.
% Error: 211.
% SCHEMA: Object Collection.
% GROUNDED: TODO keep minuend/subtrahend roles fixed across columns.
% CONNECTS TO: s(comp_nec(unlicensed(top_from_bottom_subtraction)))
misconceptions_whole_number_batch_5:(r210_top_from_bottom(346 - 157, 211)).

test_harness:arith_misconception(db_row(210), whole_number, top_from_bottom_subtraction,
    misconceptions_whole_number_batch_5:r210_top_from_bottom,
    346 - 157,
    189).

% === row 211: carrying bug writes 99 + 1 as 910 ===
% Correct: 100.
% Error: 910.
% SCHEMA: Container.
% GROUNDED: TODO cascade regrouping across places.
% CONNECTS TO: s(comp_nec(unlicensed(carry_as_adjacent_digit)))
misconceptions_whole_number_batch_5:(r211_carry_adjacent_digit(99 + 1, 910)).

test_harness:arith_misconception(db_row(211), whole_number, carry_as_adjacent_digit,
    misconceptions_whole_number_batch_5:r211_carry_adjacent_digit,
    99 + 1,
    100).

test_harness:arith_misconception(db_row(212), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(213), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(214), whole_number, too_vague, skip, none, none).

% === row 215: zero in subtraction skipped / 0-N=N ===
% Task: 502 - 6.
% Correct: 496.
% Error: 506.
% SCHEMA: Container.
% GROUNDED: TODO borrow across zero instead of treating zero-minus as positive digit.
% CONNECTS TO: s(comp_nec(unlicensed(zero_minus_n_equals_n)))
misconceptions_whole_number_batch_5:(r215_zero_minus_n_equals_n(502 - 6, 506)).

test_harness:arith_misconception(db_row(215), whole_number, zero_minus_n_equals_n,
    misconceptions_whole_number_batch_5:r215_zero_minus_n_equals_n,
    502 - 6,
    496).

test_harness:arith_misconception(db_row(216), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(217), whole_number, too_vague, skip, none, none).

% === row 218: multiplication as repeated double only ===
% Task: 12 * 11.
% Correct: 132.
% Error: 24.
% SCHEMA: Object Collection.
% GROUNDED: TODO coordinate multiplier count, not just duplicate the multiplicand once.
% CONNECTS TO: s(comp_nec(unlicensed(multiply_by_eleven_as_double)))
misconceptions_whole_number_batch_5:(r218_multiply_eleven_as_double(12 * 11, 24)).

test_harness:arith_misconception(db_row(218), whole_number, multiply_by_eleven_as_double,
    misconceptions_whole_number_batch_5:r218_multiply_eleven_as_double,
    12 * 11,
    132).

test_harness:arith_misconception(db_row(219), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(220), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(221), whole_number, too_vague, skip, none, none).

% === row 222: split subtraction with smaller-from-larger ones ===
% Task: 62 - 48.
% Correct: 14.
% Error: 26, reported as 20 + 6.
% SCHEMA: Object Collection.
% GROUNDED: TODO preserve signed deficit when ones place is insufficient.
% CONNECTS TO: s(comp_nec(unlicensed(split_subtract_smaller_from_larger)))
misconceptions_whole_number_batch_5:(r222_split_smaller_from_larger(62 - 48, 26)).

test_harness:arith_misconception(db_row(222), whole_number, split_subtract_smaller_from_larger,
    misconceptions_whole_number_batch_5:r222_split_smaller_from_larger,
    62 - 48,
    14).

test_harness:arith_misconception(db_row(223), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(224), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(225), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(226), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(227), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(228), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(229), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(230), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(231), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(232), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(233), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(234), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(235), whole_number, too_vague, skip, none, none).

% === row 236: bus context remainder treated as fractional bus ===
% Correct: 13.
% Error: 12.5.
% SCHEMA: Source-Path-Goal.
% GROUNDED: TODO map nonzero remainder to one additional bus.
% CONNECTS TO: s(comp_nec(unlicensed(fractional_bus_answer)))
misconceptions_whole_number_batch_5:(r236_fractional_bus_answer(buses(150,12), 12.5)).

test_harness:arith_misconception(db_row(236), whole_number, fractional_bus_answer,
    misconceptions_whole_number_batch_5:r236_fractional_bus_answer,
    buses(150,12),
    13).

test_harness:arith_misconception(db_row(237), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(238), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(239), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(240), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(241), whole_number, too_vague, skip, none, none).

% === row 242: order of operations grouped by following plus signs ===
% Task: 50 - 10 + 10 + 10.
% Correct: 60.
% Error: 20, mentally grouping as 50 - 30.
% SCHEMA: Source-Path-Goal.
% GROUNDED: TODO respect left-to-right evaluation for equal-precedence operations.
% CONNECTS TO: s(comp_nec(unlicensed(group_addends_after_minus)))
misconceptions_whole_number_batch_5:(r242_group_after_minus(expr(50,-,10,+,10,+,10), 20)).

test_harness:arith_misconception(db_row(242), whole_number, group_addends_after_minus,
    misconceptions_whole_number_batch_5:r242_group_after_minus,
    expr(50,-,10,+,10,+,10),
    60).

test_harness:arith_misconception(db_row(243), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(244), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(245), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(246), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(247), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(248), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(249), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(250), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(251), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(252), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(253), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(254), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(255), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(256), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(257), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(258), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(259), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(260), whole_number, too_vague, skip, none, none).

test_harness:arith_misconception(db_row(261), whole_number, smaller_from_larger_standard_alg,
    misconceptions_whole_number_batch_5:r40592_smaller_from_larger_2digit,
    62 - 25,
    37).

test_harness:arith_misconception(db_row(262), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(263), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(264), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(265), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(266), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(267), whole_number, too_vague, skip, none, none).

% === direct solo pass: whole-number queue final chunk ===

test_harness:arith_misconception(db_row(268), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(269), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(270), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(271), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(272), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(273), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(274), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(275), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(276), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(277), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(278), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(279), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(280), whole_number, too_vague, skip, none, none).

test_harness:arith_misconception(db_row(281), whole_number, smaller_from_larger_standard_alg,
    misconceptions_whole_number_batch_5:r40592_smaller_from_larger_2digit,
    32 - 17,
    15).

test_harness:arith_misconception(db_row(282), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(283), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(284), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(285), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(286), whole_number, too_vague, skip, none, none).

% === row 287: zero-place addition error ===
% Task: 52 + 30.
% Correct: 82.
% Error: 80, losing the two ones while combining tens.
% SCHEMA: Container.
% GROUNDED: TODO preserve unchanged ones while adding tens.
% CONNECTS TO: s(comp_nec(unlicensed(zero_place_addition_drop_ones)))
misconceptions_whole_number_batch_5:(r287_zero_place_addition(52 + 30, 80)).

test_harness:arith_misconception(db_row(287), whole_number, zero_place_addition_drop_ones,
    misconceptions_whole_number_batch_5:r287_zero_place_addition,
    52 + 30,
    82).

test_harness:arith_misconception(db_row(288), whole_number, smaller_from_larger_columnwise,
    misconceptions_whole_number_batch_5:r149_smaller_from_larger_3digit,
    456 - 37,
    419).

test_harness:arith_misconception(db_row(289), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(290), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(291), whole_number, too_vague, skip, none, none).

% === row 37607: digit face value instead of place value ===
% Task: value of the digit 2 in 23.
% Correct: 20.
% Error: 2.
% SCHEMA: Container.
% GROUNDED: TODO reunitize the digit by its place.
% CONNECTS TO: s(comp_nec(unlicensed(digit_face_value_for_place_value)))
misconceptions_whole_number_batch_5:(r37607_digit_face_value(value_of_digit(23, 2), 2)).

test_harness:arith_misconception(db_row(37607), whole_number, digit_face_value_for_place_value,
    misconceptions_whole_number_batch_5:r37607_digit_face_value,
    value_of_digit(23, 2),
    20).

% === row 37608: carries one instead of two ===
% Task: 38 + 49 + 65.
% Correct: 152.
% Error: 142, carrying 1 after ones total 22.
% SCHEMA: Container.
% GROUNDED: TODO carry the full tens count generated by the ones column.
% CONNECTS TO: s(comp_nec(unlicensed(under_carry_multi_addition)))
misconceptions_whole_number_batch_5:(r37608_under_carry_three_addends(38 + 49 + 65, 142)).

test_harness:arith_misconception(db_row(37608), whole_number, under_carry_multi_addition,
    misconceptions_whole_number_batch_5:r37608_under_carry_three_addends,
    38 + 49 + 65,
    152).

test_harness:arith_misconception(db_row(37610), whole_number, smaller_from_larger_standard_alg,
    misconceptions_whole_number_batch_5:r40592_smaller_from_larger_2digit,
    51 - 18,
    33).

% === row 37787: invalid multiplication procedure ===
% Task: 19 * 20.
% Correct: 380.
% Error: 3800, an extra place-value shift.
% SCHEMA: Container.
% GROUNDED: TODO align the single factor of ten in 20, not an extra zero.
% CONNECTS TO: s(comp_nec(unlicensed(extra_zero_multiplication)))
misconceptions_whole_number_batch_5:(r37787_extra_zero_multiplication(19 * 20, 3800)).

test_harness:arith_misconception(db_row(37787), whole_number, extra_zero_multiplication,
    misconceptions_whole_number_batch_5:r37787_extra_zero_multiplication,
    19 * 20,
    380).

test_harness:arith_misconception(db_row(37948), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(37950), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38061), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38202), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38760), whole_number, too_vague, skip, none, none).

% === row 38761: zero factor ignored ===
% Task: 76 * 34 * 0 * 17.
% Correct: 0.
% Error: 43928, multiplying only 76 * 34 * 17.
% SCHEMA: Object Collection.
% GROUNDED: TODO treat zero as an annihilating factor in multiplication.
% CONNECTS TO: s(comp_nec(unlicensed(ignore_zero_factor)))
misconceptions_whole_number_batch_5:(r38761_ignore_zero_factor(product_chain([76,34,0,17]), 43928)).

test_harness:arith_misconception(db_row(38761), whole_number, ignore_zero_factor,
    misconceptions_whole_number_batch_5:r38761_ignore_zero_factor,
    product_chain([76,34,0,17]),
    0).

test_harness:arith_misconception(db_row(38763), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38764), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38765), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38771), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38800), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38801), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38821), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38823), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38907), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38909), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(38976), whole_number, too_vague, skip, none, none).

% === row 39066: zero divided by n conflated with n divided by zero ===
% Correct: distinct results: 0 / 8 is 0, 8 / 0 is undefined.
% Error: both treated as the same "nothing" case.
% SCHEMA: Object Collection.
% GROUNDED: TODO distinguish empty dividend from impossible partition.
% CONNECTS TO: s(comp_nec(unlicensed(zero_division_conflation)))
misconceptions_whole_number_batch_5:(r39066_zero_division_conflation(classify_pair(0 / 8, 8 / 0), same_kind)).

test_harness:arith_misconception(db_row(39066), whole_number, zero_division_conflation,
    misconceptions_whole_number_batch_5:r39066_zero_division_conflation,
    classify_pair(0 / 8, 8 / 0),
    distinct_kind).

% === row 39184: remainder larger than divisor allowed ===
% Task: 21 divided by 2.
% Correct: quotient 10 remainder 1.
% Error: quotient 9 remainder 3.
% SCHEMA: Container.
% GROUNDED: TODO constrain remainder to be smaller than the divisor.
% CONNECTS TO: s(comp_nec(unlicensed(unconstrained_remainder)))
misconceptions_whole_number_batch_5:(r39184_unconstrained_remainder(div(21, 2), quotient_remainder(9, 3))).

test_harness:arith_misconception(db_row(39184), whole_number, unconstrained_remainder,
    misconceptions_whole_number_batch_5:r39184_unconstrained_remainder,
    div(21, 2),
    quotient_remainder(10, 1)).

test_harness:arith_misconception(db_row(39185), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39186), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39187), whole_number, too_vague, skip, none, none).

% === row 39257: large-number line spacing treated as linear place growth ===
% Task: place 1,000 on a 0 to 1,000,000 number line.
% Correct: 1,000 on the scale.
% Error: 50,000, much too far to the right.
% SCHEMA: Source-Path-Goal.
% GROUNDED: TODO use proportional distance along the full interval.
% CONNECTS TO: s(comp_nec(unlicensed(large_number_line_overplacement)))
misconceptions_whole_number_batch_5:(r39257_large_number_line_overplacement(place_on_line(1000, 0, 1000000), 50000)).

test_harness:arith_misconception(db_row(39257), whole_number, large_number_line_overplacement,
    misconceptions_whole_number_batch_5:r39257_large_number_line_overplacement,
    place_on_line(1000, 0, 1000000),
    1000).

% === row 39258: division by zero as infinity ===
% Task: N / 0.
% Correct: undefined.
% Error: infinity.
% SCHEMA: Source-Path-Goal.
% GROUNDED: TODO separate arithmetic division from limiting behavior.
% CONNECTS TO: s(comp_nec(unlicensed(division_by_zero_infinity)))
misconceptions_whole_number_batch_5:(r39258_division_by_zero_infinity(_N / 0, infinity)).

test_harness:arith_misconception(db_row(39258), whole_number, division_by_zero_infinity,
    misconceptions_whole_number_batch_5:r39258_division_by_zero_infinity,
    8 / 0,
    undefined).

test_harness:arith_misconception(db_row(39601), whole_number, too_vague, skip, none, none).

% === row 39622: missing addend solved by adding givens ===
% Task: 5 + [] = 13.
% Correct: 8.
% Error: 18, adding 5 and 13.
% SCHEMA: Source-Path-Goal.
% GROUNDED: TODO solve for the change between start and result.
% CONNECTS TO: s(comp_nec(unlicensed(add_givens_for_missing_addend)))
misconceptions_whole_number_batch_5:(r39622_add_givens_for_missing_addend(missing_addend(5, 13), 18)).

test_harness:arith_misconception(db_row(39622), whole_number, add_givens_for_missing_addend,
    misconceptions_whole_number_batch_5:r39622_add_givens_for_missing_addend,
    missing_addend(5, 13),
    8).

% === row 39718: unit count collapses before total is reached ===
% Task: count 20.
% Correct: 20.
% Error: 9.
% SCHEMA: Object Collection.
% GROUNDED: TODO coordinate grouped tens with remaining single units.
% CONNECTS TO: s(comp_nec(unlicensed(unit_count_collapse)))
misconceptions_whole_number_batch_5:(r39718_unit_count_collapse(count(20), 9)).

test_harness:arith_misconception(db_row(39718), whole_number, unit_count_collapse,
    misconceptions_whole_number_batch_5:r39718_unit_count_collapse,
    count(20),
    20).

% === row 39719: teen digit reversal ===
% Task: read numeral 13.
% Correct: 13.
% Error: 30.
% SCHEMA: Container.
% GROUNDED: TODO bind spoken teen form to written tens/ones order.
% CONNECTS TO: s(comp_nec(unlicensed(teen_digit_reversal)))
misconceptions_whole_number_batch_5:(r39719_teen_digit_reversal(read_numeral(13), 30)).

test_harness:arith_misconception(db_row(39719), whole_number, teen_digit_reversal,
    misconceptions_whole_number_batch_5:r39719_teen_digit_reversal,
    read_numeral(13),
    13).

test_harness:arith_misconception(db_row(39720), whole_number, smaller_from_larger_standard_alg,
    misconceptions_whole_number_batch_5:r40592_smaller_from_larger_2digit,
    32 - 17,
    15).

test_harness:arith_misconception(db_row(39721), whole_number, too_vague, skip, none, none).

% === row 39740: bus context answer left fractional ===
% Correct: 5 buses.
% Error: 4.7 buses.
% SCHEMA: Source-Path-Goal.
% GROUNDED: TODO ceil nonzero remainder in transport context.
% CONNECTS TO: s(comp_nec(unlicensed(fractional_bus_answer)))
misconceptions_whole_number_batch_5:(r39740_fractional_bus_answer(required_buses(example), 4.7)).

test_harness:arith_misconception(db_row(39740), whole_number, fractional_bus_answer,
    misconceptions_whole_number_batch_5:r39740_fractional_bus_answer,
    required_buses(example),
    5).

test_harness:arith_misconception(db_row(39741), whole_number, too_vague, skip, none, none).

test_harness:arith_misconception(db_row(39798), whole_number, smaller_from_larger_columnwise,
    misconceptions_whole_number_batch_5:r149_smaller_from_larger_3digit,
    456 - 37,
    419).

% === row 39905: profit computed as consecutive transaction balances ===
% Correct: total receipts minus total expenses = 20.
% Error: 10 after double-counting middle transactions.
% SCHEMA: Source-Path-Goal.
% GROUNDED: TODO aggregate buys and sells by role before subtracting.
% CONNECTS TO: s(comp_nec(unlicensed(consecutive_profit_balances)))
misconceptions_whole_number_batch_5:(r39905_consecutive_profit_balances(trades([buy(100), sell(110), buy(120), sell(130)]), 10)).

test_harness:arith_misconception(db_row(39905), whole_number, consecutive_profit_balances,
    misconceptions_whole_number_batch_5:r39905_consecutive_profit_balances,
    trades([buy(100), sell(110), buy(120), sell(130)]),
    20).

% === row 39906: profit from first buy to last sale only ===
% Correct: 20.
% Error: 30, ignoring the middle sell/buy pair.
% SCHEMA: Source-Path-Goal.
% GROUNDED: TODO account for every receipt and expense.
% CONNECTS TO: s(comp_nec(unlicensed(endpoint_profit_only)))
misconceptions_whole_number_batch_5:(r39906_endpoint_profit_only(trades([buy(100), sell(110), buy(120), sell(130)]), 30)).

test_harness:arith_misconception(db_row(39906), whole_number, endpoint_profit_only,
    misconceptions_whole_number_batch_5:r39906_endpoint_profit_only,
    trades([buy(100), sell(110), buy(120), sell(130)]),
    20).

% === row 39907: expenses and income paired incorrectly ===
% Correct: 20.
% Error: 0 after pairing 100+130 and 110+120.
% SCHEMA: Source-Path-Goal.
% GROUNDED: TODO preserve transaction roles when building totals.
% CONNECTS TO: s(comp_nec(unlicensed(transaction_role_swap)))
misconceptions_whole_number_batch_5:(r39907_transaction_role_swap(trades([buy(100), sell(110), buy(120), sell(130)]), 0)).

test_harness:arith_misconception(db_row(39907), whole_number, transaction_role_swap,
    misconceptions_whole_number_batch_5:r39907_transaction_role_swap,
    trades([buy(100), sell(110), buy(120), sell(130)]),
    20).

test_harness:arith_misconception(db_row(39928), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(39929), whole_number, too_vague, skip, none, none).

% === row 40091: fractional remainder treated as whole-number remainder ===
% Task: 37 / 5.
% Correct: quotient 7 remainder 2.
% Error: quotient 7 remainder 2/5.
% SCHEMA: Container.
% GROUNDED: TODO distinguish remainder units from fractional quotient part.
% CONNECTS TO: s(comp_nec(unlicensed(fractional_remainder_as_whole_remainder)))
misconceptions_whole_number_batch_5:(r40091_fractional_remainder(div(37, 5), quotient_remainder(7, fraction(2,5)))).

test_harness:arith_misconception(db_row(40091), whole_number, fractional_remainder_as_whole_remainder,
    misconceptions_whole_number_batch_5:r40091_fractional_remainder,
    div(37, 5),
    quotient_remainder(7, 2)).

% === row 40162: tens-column sum treated as ones ===
% Task: 30 + 50.
% Correct: 80.
% Error: 8, combining digit faces without place value.
% SCHEMA: Container.
% GROUNDED: TODO interpret 3 and 5 as tens.
% CONNECTS TO: s(comp_nec(unlicensed(tens_as_ones)))
misconceptions_whole_number_batch_5:(r40162_tens_as_ones(30 + 50, 8)).

test_harness:arith_misconception(db_row(40162), whole_number, tens_as_ones,
    misconceptions_whole_number_batch_5:r40162_tens_as_ones,
    30 + 50,
    80).

test_harness:arith_misconception(db_row(40163), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(40164), whole_number, too_vague, skip, none, none).

% === row 40169: additive decomposition of divisor in repeated halving ===
% Task: 144 / 8.
% Correct: 18.
% Error: 9, halving four times because 2+2+2+2=8.
% SCHEMA: Source-Path-Goal.
% GROUNDED: TODO compose divisor multiplicatively across halvings.
% CONNECTS TO: s(comp_nec(unlicensed(additive_divisor_decomposition)))
misconceptions_whole_number_batch_5:(r40169_additive_halving(divide_by_halves(144, 8), 9)).

test_harness:arith_misconception(db_row(40169), whole_number, additive_divisor_decomposition,
    misconceptions_whole_number_batch_5:r40169_additive_halving,
    divide_by_halves(144, 8),
    18).

test_harness:arith_misconception(db_row(40170), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(40171), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(40239), whole_number, too_vague, skip, none, none).

% === row 40243: transfers full target difference between equal groups ===
% Task: split 30 days with 8 more rainy than dry.
% Correct: rainy 19, dry 11.
% Error: rainy 23, dry 7.
% SCHEMA: Source-Path-Goal.
% GROUNDED: TODO split the difference symmetrically from the equal baseline.
% CONNECTS TO: s(comp_nec(unlicensed(transfer_full_difference)))
misconceptions_whole_number_batch_5:(r40243_transfer_full_difference(split_with_difference(30, 8), rainy_dry(23, 7))).

test_harness:arith_misconception(db_row(40243), whole_number, transfer_full_difference,
    misconceptions_whole_number_batch_5:r40243_transfer_full_difference,
    split_with_difference(30, 8),
    rainy_dry(19, 11)).

test_harness:arith_misconception(db_row(40262), whole_number, too_vague, skip, none, none).

% === row 40512: multiplication table memory slip ===
% Task: 2 * 2.
% Correct: 4.
% Error: 2.
% SCHEMA: Object Collection.
% GROUNDED: TODO coordinate the repeated group count and group size.
% CONNECTS TO: s(comp_nec(unlicensed(times_table_memory_slip)))
misconceptions_whole_number_batch_5:(r40512_times_table_memory_slip(2 * 2, 2)).

test_harness:arith_misconception(db_row(40512), whole_number, times_table_memory_slip,
    misconceptions_whole_number_batch_5:r40512_times_table_memory_slip,
    2 * 2,
    4).

test_harness:arith_misconception(db_row(40532), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(40533), whole_number, too_vague, skip, none, none).

test_harness:arith_misconception(db_row(40563), whole_number, smaller_from_larger_standard_alg,
    misconceptions_whole_number_batch_5:r40592_smaller_from_larger_2digit,
    32 - 17,
    15).

test_harness:arith_misconception(db_row(40564), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(40621), whole_number, too_vague, skip, none, none).
test_harness:arith_misconception(db_row(40623), whole_number, too_vague, skip, none, none).

% === row 40624: empty number line endpoints overcounted ===
% Task: 90 - ? = 88.
% Correct: 2.
% Error: 3, counting 90, 89, and 88 as removals.
% SCHEMA: Source-Path-Goal.
% GROUNDED: TODO count jumps between endpoints, not endpoints themselves.
% CONNECTS TO: s(comp_nec(unlicensed(endpoint_counting_on_number_line)))
misconceptions_whole_number_batch_5:(r40624_endpoint_counting(missing_subtrahend(90, 88), 3)).

test_harness:arith_misconception(db_row(40624), whole_number, endpoint_counting_on_number_line,
    misconceptions_whole_number_batch_5:r40624_endpoint_counting,
    missing_subtrahend(90, 88),
    2).
