:- module(misconceptions_whole_number_batch_2, []).
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

:- multifile test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.

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
r37472_wrong_dir_compensate(A-B, Got) :-
    RA is ((A + 9) // 10) * 10,
    RB is ((B + 9) // 10) * 10,
    DA is RA - A,
    DB is RB - B,
    Got is RA + RB + DA + DB.

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
r37496_concat_numerals(Ones-Tens, Got) :-
    atom_number(AOnes, Ones),
    atom_number(ATens, Tens),
    atom_concat(AOnes, ATens, Joined),
    atom_number(Joined, Got).

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
r37529_first_constraint_only([D|_], Got) :-
    Got is D + 1.

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
r37574_product_of_primes_prime(P1-P2, prime_claim(Prod)) :-
    Prod is P1 * P2.

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
r37652_compute_then_round(A-B, Got) :-
    Sum is A + B,
    Got is ((Sum + 5) // 10) * 10.

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
r37670_false_distribution(T1-O1 * T2-O2, Got) :-
    Got is T1 * T2 + O1 * O2.

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
r37801_swap_when_smaller(A-B, Got) :-
    B > A,
    Got is B // A.

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
r37818_digit_sum_rule(N-D, Got) :-
    digit_sum(N, S),
    ( S mod D =:= 0 -> Got = divisible ; Got = not_divisible ).

digit_sum(N, S) :-
    N < 10, !, S = N.
digit_sum(N, S) :-
    Last is N mod 10,
    Rest is N // 10,
    digit_sum(Rest, SRest),
    S is SRest + Last.

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
r37842_smaller_from_larger(A-B, Got) :-
    OT is A mod 10, TT is A // 10,
    OB is B mod 10, TB is B // 10,
    O is abs(OT - OB),
    T is abs(TT - TB),
    Got is T * 10 + O.

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
r37902_no_shift_partials(A-B, Got) :-
    O is B mod 10,
    T is B // 10,
    P1 is A * O,
    P2 is A * T,      % unshifted — student wrote A*T without trailing zero
    Got is P1 + P2.

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
r38059_phonetic_numeral(Tens-Ones, Got) :-
    atom_number(ATens, Tens),
    atom_number(AOnes, Ones),
    atom_concat(ATens, AOnes, Joined),
    atom_number(Joined, Got).

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
r38252_truncate_quotient(Total-PerTrip, Got) :-
    Got is Total // PerTrip.

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
r38498_left_to_right(A-B-C, Got) :-
    Got is (A + B) * C.

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
r38851_superficial_prime(N, Got) :-
    ( (N mod 2 =:= 0 ; N mod 3 =:= 0 ; N mod 5 =:= 0) ->
        Got = composite
    ;   Got = prime
    ).

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
r39125_borrow_no_compensation(A-B, Got) :-
    OA is A mod 10,
    OB is B mod 10,
    OA < OB,
    Got is (A + 10) - B.

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
r39138_transform_error(_Total-Groups, Got) :-
    Got is Groups * Groups.

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
r39299_smaller_from_larger(A-B, Got) :-
    OT is A mod 10, TT is A // 10,
    OB is B mod 10, TB is B // 10,
    O is abs(OT - OB),
    T is abs(TT - TB),
    Got is T * 10 + O.

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
r39357_off_by_one_decade(N, Got) :-
    Got is N * 10 + 1.

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
r39396_add_before_subtract(A-B-C, Got) :-
    Got is A - (B + C).

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
r39496_concat_count_sequence(N, Got) :-
    numlist(1, N, L),
    atomic_list_concat(L, Joined),
    atom_number(Joined, Got).

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
r39501_left_to_right(A-B-C, Got) :-
    Got is (A + B) * C.

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
r39578_compute_prime_power(Base-Exp, Got) :-
    Got is Base ** Exp.

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
r39678_divzero(_A-0, 0).

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
r39842_leading_digit_estimate(Div-Dvr, Got) :-
    Top is Div // 100,
    Bot is Dvr // 10,
    Got is Top // Bot.

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
r39964_left_to_right(A-B-C, Got) :-
    Got is (A + B) * C.

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
r40128_smaller_from_larger(A-B, Got) :-
    OT is A mod 10, TT is A // 10,
    OB is B mod 10, TB is B // 10,
    O is abs(OT - OB),
    T is abs(TT - TB),
    Got is T * 10 + O.

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
r40234_remainder_as_fraction(S-P, Got) :-
    Got is S // P.

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
r40273_commute_subtraction(A-B, Got) :-
    Got is B - A.

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
r40673_quadrant_by_size(L-LP-S-SP, Got) :-
    Got is L*LP + S*SP + L*S + LP*SP.

test_harness:arith_misconception(db_row(40673), whole_number, area_partial_products_by_size,
    misconceptions_whole_number_batch_2:r40673_quadrant_by_size,
    20-30-8-6,
    1008).
