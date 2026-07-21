:- module(misconceptions_whole_number_batch_4, []).
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

:- multifile test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.

% ---- Encodings appended by agent for whole_number batch 4 ----

% === row 37490: six is both even and odd ===
% Task: classify parity of 6 when decomposed as three groups of two
% Correct: even
% Error: claims both even and odd because composed of odd number of twos
% SCHEMA: Arithmetic is Object Collection (parity via group count)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(parity_by_group_count)))
parity_by_group_count(N, both_even_and_odd) :-
    0 is N mod 2,
    Halves is N // 2,
    1 is Halves mod 2.

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
digit_sum_primality(N, prime) :-
    digit_sum(N, S),
    is_prime(S).
digit_sum_primality(N, composite) :-
    digit_sum(N, S),
    \+ is_prime(S).

digit_sum(N, S) :-
    N < 10, !, S = N.
digit_sum(N, S) :-
    D is N mod 10,
    R is N // 10,
    digit_sum(R, S0),
    S is S0 + D.

is_prime(2) :- !.
is_prime(N) :-
    N > 2,
    N mod 2 =\= 0,
    Max is integer(sqrt(N)),
    \+ ( between(3, Max, K), K mod 2 =:= 1, N mod K =:= 0 ).

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
add_irrelevant_counts(A-B, Sum) :- Sum is A + B.

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
double_first_add_one(A-_B, Out) :- Out is 2*A + 1.

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
raw_quotient_with_remainder(D-V, quot_plus_frac(Q, R, V)) :-
    Q is D // V,
    R is D mod V,
    R > 0.

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
pf_distributive_over_sum(Parts, concat_pfs(ListOfPFs)) :-
    maplist(prime_factors, Parts, ListOfPFs).

prime_factors(1, []) :- !.
prime_factors(N, [N]) :-
    N > 1, is_prime(N), !.
prime_factors(N, [K|Rest]) :-
    N > 1,
    smallest_factor(N, 2, K),
    N1 is N // K,
    prime_factors(N1, Rest).

smallest_factor(N, K, K) :- N mod K =:= 0, !.
smallest_factor(N, K, F) :-
    K1 is K + 1,
    smallest_factor(N, K1, F).

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
reversal_mult_instead_div(Q-K, Out) :- Out is Q * K.

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
no_shift_partial_products(A-B, Out) :-
    digits_of(B, Ds),
    maplist(mul_by(A), Ds, Partials),
    sum_list(Partials, Out).

mul_by(A, D, P) :- P is A * D.

digits_of(N, [N]) :- N < 10, !.
digits_of(N, Ds) :-
    N >= 10,
    D is N mod 10,
    R is N // 10,
    digits_of(R, Rest),
    append(Rest, [D], Ds).

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
idiosyncratic_nexus_div(60-4, 12).

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
mult_as_add(A-B, Out) :- Out is A + B.

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
digitwise_add_concat(A-B, Out) :-
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
    ).

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
reversal_by_mult(A-B, Out) :- Out is A * B.

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
zero_neither_parity(0, neither).
zero_neither_parity(N, even) :- N > 0, 0 is N mod 2.
zero_neither_parity(N, odd) :- N > 0, 1 is N mod 2.

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
subset_as_disjoint(Whole-Subset, Out) :- Out is Whole + Subset.

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
keyword_surface_add(A-B, Out) :- Out is A + B.

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
dividend_quotient_same_rate(NewD-Q-OldD, Out) :-
    Diff is OldD - NewD,
    Out is Q - Diff.

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
buggy_borrow_smaller_minuend(235-341, 884).

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
round_divisor_1_sigfig(Num-Div, Out) :-
    round_to_1_sigfig(Div, R),
    Out is Num // R.

round_to_1_sigfig(N, R) :-
    N >= 1,
    digits_of(N, Ds),
    length(Ds, L),
    D is L - 1,
    P is 10 ** D,
    First is round(N / P),
    R is First * P.

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
persistence_of_digit(A-B, Out) :-
    % replicate B's digit across A's width
    digits_of(A, DsA),
    length(DsA, L),
    B < 10,
    replicate(L, B, Ds),
    digits_to_num(Ds, BFat),
    Out is A - BFat.

replicate(0, _, []) :- !.
replicate(N, X, [X|T]) :- N > 0, N1 is N - 1, replicate(N1, X, T).

digits_to_num(Ds, N) :- digits_to_num(Ds, 0, N).
digits_to_num([], Acc, Acc).
digits_to_num([D|Ds], Acc, N) :-
    Acc1 is Acc * 10 + D,
    digits_to_num(Ds, Acc1, N).

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
even_exponent_even_power(_Base-Exp, even) :- 0 is Exp mod 2.
even_exponent_even_power(_Base-Exp, odd)  :- 1 is Exp mod 2.

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
nominal_same_blank(A-_B, A).

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
product_of_primes_prime(A-B, prime) :- is_prime(A), is_prime(B).
product_of_primes_prime(A-B, composite) :-
    \+ (is_prime(A), is_prime(B)).

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
surface_action_subtracts(Delivered-Left, Out) :- Out is Left - Delivered.

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
detach_sign_group(Expr, Out) :-
    Expr = minuend(M, Addends),
    sum_list(Addends, S),
    Out is M - S.

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
left_to_right_ops(ops([N|Rest]), Out) :-
    left_to_right_acc(N, Rest, Out).

left_to_right_acc(Acc, [], Acc).
left_to_right_acc(Acc, [Op, N | Rest], Out) :-
    apply_op(Op, Acc, N, Acc1),
    left_to_right_acc(Acc1, Rest, Out).

apply_op(+, A, B, C) :- C is A + B.
apply_op(-, A, B, C) :- C is A - B.
apply_op(*, A, B, C) :- C is A * B.
apply_op(/, A, B, C) :- C is A // B.

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
literal_order_sentence([A,B,C], expr(A,B,C)).

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
no_cross_multiply(A-B, Out) :-
    O1 is A mod 10, T1 is A // 10,
    O2 is B mod 10, T2 is B // 10,
    OnesPart is O1 * O2,
    TensPart is T1 * T2,
    Out is OnesPart + TensPart * 10.

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
difference_as_sum(A-B, Out) :- Out is A + B.

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
digits_as_ones_blocks(N, Sum) :-
    digits_of(N, Ds),
    sum_list(Ds, Sum).

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
add_instead_of_multiply(A-B, Out) :- Out is A + B.

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
equal_diff_equal_product((A1-A2)-(B1-B2), equal) :-
    D1 is A1 - A2, D2 is B1 - B2, D1 =:= D2.
equal_diff_equal_product((A1-A2)-(B1-B2), unequal) :-
    D1 is A1 - A2, D2 is B1 - B2, D1 =\= D2.

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
refine_estimate_wrong_unit(Est-Diff-OtherFactor, Out) :-
    Out is Est - Diff * OtherFactor.

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
buggy_split_bridging_ten(A-B, Out) :-
    TA is A // 10, OA is A mod 10,
    TB is B // 10, OB is B mod 10,
    TDiff is TA - TB,
    ( OA >= OB -> ODiff is OA - OB ; ODiff is OB - OA ),
    Out is TDiff * 10 + ODiff.

test_harness:arith_misconception(db_row(40587), whole_number, buggy_split_bridging_ten,
    misconceptions_whole_number_batch_4:buggy_split_bridging_ten,
    62-48, 14).

% === row 40645: guess operations shallowly ===
test_harness:arith_misconception(db_row(40645), whole_number, too_vague,
    skip, none, none).
