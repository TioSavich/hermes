:- module(misconceptions_whole_number_batch_5, []).
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

:- multifile test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.

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
r37507_div_by_zero_is_zero(_N / 0, 0).

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
r37578_odd_product_is_prime((X, Y), prime) :-
    1 is X mod 2,
    1 is Y mod 2.

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
r37626_drop_trailing_zero(X * Y, Got) :-
    Product is X * Y,
    Got is Product div 10.

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
r37655_smaller_from_larger_2digit(A - B, Got) :-
    T1 is A div 10, O1 is A mod 10,
    T2 is B div 10, O2 is B mod 10,
    Tdiff is abs(T1 - T2),
    Odiff is abs(O1 - O2),
    Got is Tdiff * 10 + Odiff.

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
r37814_truncate_containers(A / B, Got) :-
    Got is A div B.

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
r37855_estimate_by_rounding_result(A + B, Got) :-
    Exact is A + B,
    Got is ((Exact + 5) div 10) * 10.

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
r37877_spurious_times_seven(Weekly, Got) :-
    Got is Weekly * 7.

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
r37900_unequal_columns_same_total(Total, (A, B)) :-
    A is (Total // 2) + 2,
    B is Total - A.

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
r37934_smaller_from_larger_3digit(A - B, Got) :-
    H1 is A div 100, T1 is (A div 10) mod 10, O1 is A mod 10,
    H2 is B div 100, T2 is (B div 10) mod 10, O2 is B mod 10,
    Hdiff is abs(H1 - H2),
    Tdiff is abs(T1 - T2),
    Odiff is abs(O1 - O2),
    Got is Hdiff * 100 + Tdiff * 10 + Odiff.

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
r37985_swap_minuend_subtrahend(subtract(X, From), Got) :-
    Got is X - From.

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
r38121_juxtapose_unit_totals(units(Th, H, T, O), Got) :-
    format(atom(A), '~w~w~w~w', [Th, H, T, O]),
    atom_number(A, Got).

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
r38144_times_more_multiplies(six_times_more(Amount), Got) :-
    Got is Amount * 6.

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
r38227_count_back_off_by_one(A - B, Got) :-
    Got is A - B + 1.

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
r38242_smaller_from_larger_padded(A - B, Got) :-
    H1 is A div 100, T1 is (A div 10) mod 10, O1 is A mod 10,
    H2 is B div 100, T2 is (B div 10) mod 10, O2 is B mod 10,
    Hdiff is abs(H1 - H2),
    Tdiff is abs(T1 - T2),
    Odiff is abs(O1 - O2),
    Got is Hdiff * 100 + Tdiff * 10 + Odiff.

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
r38393_omit_zero_in_quotient(_N / _D, 3664).

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
r38464_fold_adds_two(Folds, Got) :-
    Got is 2 * Folds.

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
r38608_decade_cross_sub_ten_add_one(predecessor(N), Got) :-
    Got is N - 10 + 1.

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
r38725_tens_column_as_ten(N, tens_ones(Tens, Ones)) :-
    T is N div 10,
    Tens is T * 10,
    Ones is N mod 10.

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
r38999_times_equals_as_double(times_eq(N), Got) :-
    Got is N * 2.

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
r39166_swap_dividend_smaller(A / B, Got) :-
    A < B,
    Got is B // A.

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
r39215_square_requires_even(square_of_product([A,B,C]), not_square) :-
    1 is A mod 2,
    1 is B mod 2,
    1 is C mod 2.

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
r39320_small_prime_check(is_prime(N), prime) :-
    \+ 0 is N mod 2,
    \+ 0 is N mod 3,
    \+ 0 is N mod 5,
    \+ 0 is N mod 7.

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
r39422_less_cue_subtracts(less_than(Today, By), Got) :-
    Got is Today - By.

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
r39499_jump_posterior(solve(A - n + C = R), Got) :-
    Intermediate is A - C,
    Got is Intermediate - R.

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
r39534_divide_larger_by_smaller(share(Items, People), Got) :-
    Items < People,
    Got is People // Items.

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
r39557_division_commutative(A / B, Got) :-
    A < B,
    Got is B // A.

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
r39690_round_wrong_place(round_to_hundreds(N), Got) :-
    Got is ((N + 5) // 10) * 10.

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
r39746_horizontal_sum_all_digits(A + B, Got) :-
    digits_sum(A, SA),
    digits_sum(B, SB),
    Got is SA + SB.

digits_sum(N, S) :-
    N < 10, !, S = N.
digits_sum(N, S) :-
    N >= 10,
    D is N mod 10,
    Rest is N div 10,
    digits_sum(Rest, S0),
    S is S0 + D.

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
r40063_juxtapose_unit_totals(units(Th, H, T, O), Got) :-
    format(atom(A), '~w~w~w~w', [Th, H, T, O]),
    atom_number(A, Got).

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
r40305_decimal_for_trips(trips(People, Per), Got) :-
    Got is People / Per.

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
r40592_smaller_from_larger_2digit(A - B, Got) :-
    T1 is A div 10, O1 is A mod 10,
    T2 is B div 10, O2 is B mod 10,
    Tdiff is abs(T1 - T2),
    Odiff is abs(O1 - O2),
    Got is Tdiff * 10 + Odiff.

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
r40671_like_place_only(A * B, Got) :-
    TA is A div 10, OA is A mod 10,
    TB is B div 10, OB is B mod 10,
    TensProd is TA * TB * 100,
    OnesProd is OA * OB,
    Got is TensProd + OnesProd.

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
r149_smaller_from_larger_3digit(A - B, Got) :-
    H1 is A div 100, T1 is (A div 10) mod 10, O1 is A mod 10,
    H2 is B div 100, T2 is (B div 10) mod 10, O2 is B mod 10,
    H is abs(H1 - H2),
    T is abs(T1 - T2),
    O is abs(O1 - O2),
    Got is H * 100 + T * 10 + O.

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
r152_juxtapose_column_sums(A + B, Got) :-
    T1 is A div 10, O1 is A mod 10,
    T2 is B div 10, O2 is B mod 10,
    T is T1 + T2,
    O is O1 + O2,
    format(atom(Atom), '~w~w', [T,O]),
    atom_number(Atom, Got).

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
r156_add_factors(A * B, Got) :-
    Got is A + B.

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
r181_remainder_decimal_tail(div(491,6), decimal(81,5)).

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
r192_switch_digits_subtraction(24 - 19, 15).

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
r193_addition_must_make_larger(missing_addend(6,4), impossible).

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
r198_raw_bus_quotient(buses(People,PerBus), Got) :-
    Got is People / PerBus.

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
r210_top_from_bottom(346 - 157, 211).

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
r211_carry_adjacent_digit(99 + 1, 910).

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
r215_zero_minus_n_equals_n(502 - 6, 506).

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
r218_multiply_eleven_as_double(12 * 11, 24).

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
r222_split_smaller_from_larger(62 - 48, 26).

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
r236_fractional_bus_answer(buses(150,12), 12.5).

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
r242_group_after_minus(expr(50,-,10,+,10,+,10), 20).

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
r287_zero_place_addition(52 + 30, 80).

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
r37607_digit_face_value(value_of_digit(23, 2), 2).

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
r37608_under_carry_three_addends(38 + 49 + 65, 142).

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
r37787_extra_zero_multiplication(19 * 20, 3800).

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
r38761_ignore_zero_factor(product_chain([76,34,0,17]), 43928).

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
r39066_zero_division_conflation(classify_pair(0 / 8, 8 / 0), same_kind).

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
r39184_unconstrained_remainder(div(21, 2), quotient_remainder(9, 3)).

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
r39257_large_number_line_overplacement(place_on_line(1000, 0, 1000000), 50000).

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
r39258_division_by_zero_infinity(_N / 0, infinity).

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
r39622_add_givens_for_missing_addend(missing_addend(5, 13), 18).

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
r39718_unit_count_collapse(count(20), 9).

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
r39719_teen_digit_reversal(read_numeral(13), 30).

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
r39740_fractional_bus_answer(required_buses(example), 4.7).

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
r39905_consecutive_profit_balances(trades([buy(100), sell(110), buy(120), sell(130)]), 10).

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
r39906_endpoint_profit_only(trades([buy(100), sell(110), buy(120), sell(130)]), 30).

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
r39907_transaction_role_swap(trades([buy(100), sell(110), buy(120), sell(130)]), 0).

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
r40091_fractional_remainder(div(37, 5), quotient_remainder(7, fraction(2,5))).

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
r40162_tens_as_ones(30 + 50, 8).

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
r40169_additive_halving(divide_by_halves(144, 8), 9).

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
r40243_transfer_full_difference(split_with_difference(30, 8), rainy_dry(23, 7)).

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
r40512_times_table_memory_slip(2 * 2, 2).

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
r40624_endpoint_counting(missing_subtrahend(90, 88), 3).

test_harness:arith_misconception(db_row(40624), whole_number, endpoint_counting_on_number_line,
    misconceptions_whole_number_batch_5:r40624_endpoint_counting,
    missing_subtrahend(90, 88),
    2).
