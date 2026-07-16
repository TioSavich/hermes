:- module(misconceptions_whole_number_batch_3, []).
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

:- multifile test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.

% ---- Encodings appended by agent for whole_number batch 3 ----

% === row 37484: reverse dividend and divisor when divisor is larger ===
% Task: partitive 5 kg shared among 15 friends -> 5 / 15
% Correct: frac(1,3)  (each friend gets 1/3 kg)
% Error: swaps to put larger first -> 15 / 5 = 3
% SCHEMA: Container (sharing) — forces "big into small" orientation
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(reverse_for_larger_divisor)))
r37484_reverse_division(Dividend-Divisor, Got) :-
    ( Divisor > Dividend
    -> Got is Divisor // Dividend
    ;  Got is Dividend // Divisor
    ).

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
r37497_missing_as_sum(Addend-Sum, Got) :-
    Got is Addend + Sum.

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
r37575_small_prime_check(N, Got) :-
    ( member(P, [2,3,5,7,11]),
      N mod P =:= 0
    -> Got = composite
    ;  Got = prime
    ).

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
r37603_rtl_digit_drop(2500-500, 2750).

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
r37803_div_commutative(Dividend-Divisor, Got) :-
    Big is max(Dividend, Divisor),
    Small is min(Dividend, Divisor),
    Got is Big // Small.

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
r37819_last_digit_div7(N-7, Got) :-
    LastDigit is N mod 10,
    ( LastDigit mod 7 =:= 0
    -> Got = divisible
    ;  Got = not_divisible
    ).

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
r37843_incomplete_borrow(40-12, 38).

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
r37903_halve_four_times(144-8, 9).

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
r38060_no_carry(99-1, 910).

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
r38368_comp_wrong_dir(M-S, Got) :-
    Round is S + (10 - (S mod 10)),
    Diff is Round - S,
    Intermediate is M - Round,
    Got is Intermediate - Diff.

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
r38606_contract_add(Total-Subset, Got) :-
    Got is Total + Subset.

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
r38734_floor_not_ceiling(People-Capacity, Got) :-
    Got is People // Capacity.

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
r38834_ltr_eval(expr(A,Op1,B,Op2,C), Got) :-
    apply_op(A, Op1, B, R1),
    apply_op(R1, Op2, C, Got).

apply_op(X, +, Y, Z) :- Z is X + Y.
apply_op(X, -, Y, Z) :- Z is X - Y.
apply_op(X, *, Y, Z) :- Z is X * Y.
apply_op(X, /, Y, Z) :- Z is X / Y.

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
r39052_one_sig_fig(A-B, Got) :-
    round_to_1sf(A, RA),
    round_to_1sf(B, RB),
    Got is RA * RB.

round_to_1sf(N, R) :-
    N > 0,
    number_codes(N, Codes),
    length(Codes, Len),
    Codes = [LeadCode|_],
    Lead is LeadCode - 0'0,
    D is Len - 1,
    Pow is 10 ** D,
    R is Lead * Pow.

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
r39110_col_absdiff(M-S, Got) :-
    number_codes(M, MC), number_codes(S, SC),
    maplist(code_to_digit, MC, MD),
    maplist(code_to_digit, SC, SD),
    pad_left(MD, SD, MP, SP),
    maplist([A,B,D]>>(D is abs(A-B)), MP, SP, Diffs),
    digits_to_number(Diffs, Got).

code_to_digit(C, D) :- D is C - 0'0.

pad_left(A, B, A, B) :- length(A, L), length(B, L), !.
pad_left(A, B, AP, BP) :-
    length(A, LA), length(B, LB),
    ( LA < LB
    -> D is LB - LA, length(Pad, D), maplist(=(0), Pad),
       append(Pad, A, AP), BP = B
    ;  D is LA - LB, length(Pad, D), maplist(=(0), Pad),
       append(Pad, B, BP), AP = A
    ).

digits_to_number(Digits, N) :-
    foldl([D,Acc,Next]>>(Next is Acc*10 + D), Digits, 0, N).

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
r39126_fact_slip(7-5, 3).

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
r39213_parity_last_digit(base(Digits, _Base), Got) :-
    last(Digits, Last),
    ( Last mod 2 =:= 0
    -> Got = even
    ;  Got = odd
    ).

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
r39236_chain_sum(chain(A,B,C), Got) :-
    Got is A + B + C.

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
r39679_div_zero_infinity(_-0, infinity).

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
r39695_floor_buses(People-Capacity, Got) :-
    Got is People // Capacity.

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
r39730_sub_commutative(A-B, Got) :-
    Got is B - A.

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
r39749_eq_add_half(34-17, 27).

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
r39855_mult_before_div(expr6(A, +, B, /, C, *, D), Got) :-
    Inner is C * D,
    Quot is B / Inner,
    Got is A + Quot.

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
r40051_zero_neither(0, neither).

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
r40066_exp_as_mult(Base-Exp, Got) :-
    Got is Base * Exp.

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
r40141_col_absdiff(132-45, 113).

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
r40167_compare_larger(A-B, Got) :-
    Got is max(A, B).

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
r40236_drop_scale(A-B, Got) :-
    StripA is A // 10,
    Got is StripA * B.

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
r40312_additive_scale(Whole-Part, Got) :-
    Got is Whole - Part.

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
r40539_bigger_more_factors(A-B, Winner) :-
    ( A >= B
    -> Winner = A
    ;  Winner = B
    ).

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
