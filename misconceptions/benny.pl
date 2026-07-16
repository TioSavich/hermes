/** <module> Benny's Rule Deformations (Erlwanger 1973)
 *
 * Benny is a 6th-grader in Erlwanger's case study who passed an Individually
 * Prescribed Instruction (IPI) program with high marks while holding a
 * systematic, hidden set of rule deformations. Several are modeled in this
 * file; two are described in detail in this header (Rule 1 and Rule 2), the
 * rest at their definitions below:
 *
 *   Rule 1 (fraction → decimal):
 *     N/D → add N+D to get a single numeral, then place a decimal point
 *     "somewhere" (consistently before the last digit). So 2/10, 5/10, 4/11
 *     and 11/4 all yield the same two-digit numeral with the same decimal-point
 *     location.
 *
 *   Rule 2 (fraction equivalence):
 *     N1/D1 ~ N2/D2  iff  N1+D1 = N2+D2. So 5/10 ~ 4/11 (both sum to 15).
 *
 * Both rules share a deformation: a content-carrying operation (division in
 * Rule 1, multiplication in Rule 2) is replaced by addition. Same pattern,
 * two locations. This is the payoff of modeling Benny as an FSM structurally
 * parallel to the coordinated automaton: the deformation becomes visible as
 * a specific *substitution* in the elaboration chain.
 *
 * PML tags in the history mark two distinct failure modes:
 *   - content_replacement: the arithmetic is valid (addition succeeds and
 *     passes is_recollection) but the step is licensed as the wrong content
 *     (sum where division should be; sum where multiplication should be).
 *   - symbol_manipulation_no_arithmetic: the step does no arithmetic at all
 *     and operates on numerals-as-symbols (the decimal-point placement in
 *     Rule 1). No is_recollection gate because there is no arithmetic result
 *     to license.
 *
 * References:
 *   Erlwanger (1973), Benny's Conception of Rules and Answers in IPI Mathematics.
 *   Leatham (2014), research_corpus/pdfs/JMB/JMB_Leatham_2014_Case.pdf.
 *   Byers & Erlwanger (1984), research_corpus/pdfs/ESM/ESM_Byers_1984_Content.pdf.
 */
:- module(misconceptions_benny, []).

:- multifile test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.

:- multifile test_harness:arith_trace_profile/4.
:- discontiguous test_harness:arith_trace_profile/4.
:- dynamic test_harness:arith_trace_profile/4.

:- use_module(library(lists)).
:- use_module(formalization(robinson_q), [is_recollection/2]).
:- use_module(formalization(grounded_arithmetic),
              [ integer_to_recollection/2, recollection_to_integer/2,
                add_grounded/3, equal_to/2, integer_to_digit_list/2,
                incur_cost/1 ]).

% =============================================================
% Rule 1: fraction → decimal via sum-and-place
% =============================================================

%! benny_rule1_fraction_to_decimal(+Frac:frac(N,D), -DigitList:list) is det.
%
%  Runs Benny's Rule 1 as a 4-state FSM:
%
%    q_init                → license N, D via is_recollection.
%    q_sum_num_den         → Sum = N + D via add_grounded.
%                            PML tag: unlicensed(content_replacement(
%                                       division_by_addition)).
%                            Note: the sum itself passes is_recollection —
%                            it is a validly-constructed number. What is
%                            unlicensed is the *interpretation* of the sum
%                            as N ÷ D. Correct arithmetic pressed into the
%                            wrong content.
%    q_place_decimal_heuristic
%                          → convert Sum to a digit list; insert
%                            `decimal_point` before the last digit.
%                            PML tag: unlicensed(symbol_manipulation_no_arithmetic).
%                            Note: no is_recollection gate because no
%                            arithmetic result is produced. This step
%                            operates on numerals-as-symbols — the pure
%                            symbol-pushing failure mode.
%    q_emit                → return the digit list.
%
%  Examples (all four distinct-input cases collapse to three distinct outputs):
%    frac(2, 10)  → [1, decimal_point, 2]   % sum = 12
%    frac(5, 10)  → [1, decimal_point, 5]   % sum = 15
%    frac(4, 11)  → [1, decimal_point, 5]   % sum = 15  (collision with 5/10)
%    frac(11, 4)  → [1, decimal_point, 5]   % sum = 15  (collision; order-insensitive)
%    frac(3,  2)  → [decimal_point, 5]      % sum =  5  (documented "3/2 = .5")
benny_rule1_fraction_to_decimal(frac(N, D), DigitList) :-
    incur_cost(strategy_selection),
    % q_init
    once(is_recollection(N, _)),
    once(is_recollection(D, _)),
    % q_sum_num_den — add_grounded gives a real recollection; sum is licensed.
    % The PML tag marks the INTERPRETATION as unlicensed, not the arithmetic.
    integer_to_recollection(N, NRec),
    integer_to_recollection(D, DRec),
    add_grounded(NRec, DRec, SumRec),
    recollection_to_integer(SumRec, Sum),
    once(is_recollection(Sum, _)),
    % q_place_decimal_heuristic — pure symbol manipulation, no arithmetic.
    % No is_recollection gate here: no arithmetic result to license.
    place_decimal_before_last(Sum, DigitList).

%! place_decimal_before_last(+N:integer, -Digits:list) is det.
%
%  Insert `decimal_point` before the last digit of N's decimal representation.
%  Benny's placement heuristic.
%
%  Examples:
%    12 → [1, decimal_point, 2]
%    15 → [1, decimal_point, 5]
%     5 → [decimal_point, 5]
%   105 → [1, 0, decimal_point, 5]
place_decimal_before_last(N, Digits) :-
    integer_to_digit_list(N, Raw),
    append(Prefix, [Last], Raw),
    ( Prefix == []
    -> Digits = [decimal_point, Last]
    ;  append(Prefix, [decimal_point, Last], Digits)
    ).

% =============================================================
% Rule 2: fraction equivalence via additive comparison
% =============================================================

%! benny_rule2_additive_equivalence(+Pair:frac-frac, -Result:atom) is det.
%
%  Runs Benny's Rule 2 as a 5-state FSM whose shape is structurally identical
%  to `smr_frac_equiv_cross_mult:run_cross_mult_equiv/6` but with addition
%  substituted for multiplication at the two cross-product slots.
%
%    q_init          → license all four inputs.
%    q_sum_frac_1    → S1 = N1 + D1 via add_grounded.
%                      PML tag: unlicensed(content_replacement(
%                                 multiplication_by_addition)).
%    q_sum_frac_2    → S2 = N2 + D2 via add_grounded.
%                      Same PML tag.
%    q_compare       → equal_to(S1_rec, S2_rec). Structurally identical to
%                      the correct automaton's compare step — the intact
%                      piece of the elaboration chain.
%    q_emit          → set Result.
%
%  Result ∈ {equivalent, not_equivalent}.
benny_rule2_additive_equivalence(frac(N1, D1)-frac(N2, D2), Result) :-
    incur_cost(strategy_selection),
    % q_init
    once(is_recollection(N1, _)),
    once(is_recollection(D1, _)),
    once(is_recollection(N2, _)),
    once(is_recollection(D2, _)),
    % q_sum_frac_1 — arithmetic valid; interpretation (standing in for N1*D2) is not.
    integer_to_recollection(N1, N1Rec),
    integer_to_recollection(D1, D1Rec),
    add_grounded(N1Rec, D1Rec, S1Rec),
    recollection_to_integer(S1Rec, S1),
    once(is_recollection(S1, _)),
    % q_sum_frac_2
    integer_to_recollection(N2, N2Rec),
    integer_to_recollection(D2, D2Rec),
    add_grounded(N2Rec, D2Rec, S2Rec),
    recollection_to_integer(S2Rec, S2),
    once(is_recollection(S2, _)),
    % q_compare — grounded equality. (This piece is intact; Benny's rule
    % shares this exact step with the correct cross-mult automaton.)
    ( equal_to(S1Rec, S2Rec)
    -> Result = equivalent
    ;  Result = not_equivalent
    ).

% =============================================================
% Rule 6: procedural equivalence via surface-form identity
% =============================================================

%! benny_rule6_procedural_equivalence(+Pair:frac-frac, -Result:atom) is det.
%
%  Models a deformation of the equivalence judgment itself: two fractions
%  count as "the same" only when they are written with identical numerals.
%  Value-equivalence is replaced by surface-form identity. No arithmetic
%  operation runs at any step — there is no add_grounded; q_init only
%  licenses the inputs and q_compare_surface compares terms. This is the
%  purest case of the symbol_manipulation_no_arithmetic failure mode.
%
%    q_init            → license all four inputs via is_recollection.
%    q_compare_surface → compare the two fracs as Prolog terms (==).
%                        PML tag: unlicensed(symbol_manipulation_no_arithmetic).
%                        No is_recollection gate on a result: there is no
%                        arithmetic result, only a term comparison on
%                        numerals-as-symbols.
%    q_emit            → Result = identical when the terms are syntactically
%                        equal, otherwise distinct.
%
%  Result ∈ {identical, distinct}. This is categorically the wrong KIND of
%  answer to a value-equivalence question: it never produces the
%  equivalent/not_equivalent vocabulary the correct cross-mult automaton
%  uses, so it registers as wrong_answer against every value-equivalence
%  expectation, including cases where its direction happens to coincide
%  with the truth.
%
%  Examples:
%    frac(1,2)-frac(2,4) → distinct      (correct: equivalent — false negative)
%    frac(3,4)-frac(3,4) → identical     (correct: equivalent — direction
%                                          coincides, vocabulary does not)
benny_rule6_procedural_equivalence(frac(N1, D1)-frac(N2, D2), Result) :-
    incur_cost(strategy_selection),
    % q_init
    once(is_recollection(N1, _)),
    once(is_recollection(D1, _)),
    once(is_recollection(N2, _)),
    once(is_recollection(D2, _)),
    % q_compare_surface — pure symbol comparison, no arithmetic.
    % PML tag: unlicensed(symbol_manipulation_no_arithmetic).
    ( frac(N1, D1) == frac(N2, D2)
    -> Result = identical
    ;  Result = distinct
    ).

% =============================================================
% Registration with the test harness
% =============================================================
%
% Expected values are the answers the CORRECT coordinated automata produce:
%   - smr_div_long:run_long_division/5 for Rule 1.
%   - smr_frac_equiv_cross_mult:run_cross_mult_equiv/6 for Rule 2.
% Benny's rules are called via module-qualified RuleName so the harness
% reaches into this module directly without exports.

% --- Rule 1 registrations (fraction → decimal) ---
% Benny gives   [1, decimal_point, 2]   ; correct is [0, decimal_point, 2].  wrong_answer.
test_harness:arith_misconception(erlwanger_1973, fraction, benny_rule1_2_over_10,
    misconceptions_benny:benny_rule1_fraction_to_decimal,
    frac(2, 10),
    [0, decimal_point, 2]).
% Benny gives   [1, decimal_point, 5]   ; correct is [0, decimal_point, 5].  wrong_answer.
test_harness:arith_misconception(erlwanger_1973, fraction, benny_rule1_5_over_10,
    misconceptions_benny:benny_rule1_fraction_to_decimal,
    frac(5, 10),
    [0, decimal_point, 5]).
% Benny gives   [1, decimal_point, 5]   ; correct is [0, decimal_point, 3, 6, 3, 6] (truncated).
test_harness:arith_misconception(erlwanger_1973, fraction, benny_rule1_4_over_11,
    misconceptions_benny:benny_rule1_fraction_to_decimal,
    frac(4, 11),
    [0, decimal_point, 3, 6, 3, 6]).
% Benny gives   [1, decimal_point, 5]   ; correct is [0, 2, decimal_point, 7, 5].
% Documented "order-insensitive" collision: 11/4 and 4/11 yield the same
% Benny-output because addition is commutative. Correct answers differ.
test_harness:arith_misconception(erlwanger_1973, fraction, benny_rule1_11_over_4,
    misconceptions_benny:benny_rule1_fraction_to_decimal,
    frac(11, 4),
    [0, 2, decimal_point, 7, 5]).
% Benny gives   [decimal_point, 5]      ; correct is [1, decimal_point, 5].
% The documented "3/2 = .5" case from Erlwanger.
test_harness:arith_misconception(erlwanger_1973, fraction, benny_rule1_3_over_2,
    misconceptions_benny:benny_rule1_fraction_to_decimal,
    frac(3, 2),
    [1, decimal_point, 5]).

% --- Rule 3 registration (reciprocal-pair collision) ---
% Benny's additive collapse is order-insensitive: N+D = D+N, so a fraction
% and its reciprocal produce the same numeral. Rule 1 already shows the
% order-insensitivity for 4/11 and 11/4 (both sum to 15). This case adds
% the reciprocal pair 2/3 and 3/2: both sum to 5 and collapse to
% [decimal_point, 5]. The 3/2 side is registered just above as
% benny_rule1_3_over_2; together they show Benny cannot distinguish 2/3
% from 3/2. No new FSM — this reuses benny_rule1_fraction_to_decimal; the
% rule3_ name groups the collision case, it does not name a separate
% mechanism.
%
% Benny gives [decimal_point, 5] ; correct is 0.666... ->
% [0, decimal_point, 6, 6, 6, 6] (truncated, paralleling the 4/11 row). wrong_answer.
test_harness:arith_misconception(erlwanger_1973, fraction, benny_rule3_2_over_3,
    misconceptions_benny:benny_rule1_fraction_to_decimal,
    frac(2, 3),
    [0, decimal_point, 6, 6, 6, 6]).

% =============================================================
% Rule 4: decimal addition via digit-string + point-reattach
% =============================================================
%
% Byers & Erlwanger (1984, pp. 272-273) transcript:
%   "2 + 3, that's 5. If I did 2 + .3, that will give me a decimal;
%    that will be .5."
%   "2 + 3/10 will give me 2 3/10."
% Same addends, different outputs depending on notational regime.
% Benny's procedure on the decimal regime: strip the decimal point,
% sum the digit-strings as if they were integers, then heuristically
% reattach a decimal point if either input had one.
%
% This is the *third* instance of content-op-replaced-by-syntactic-op
% in Benny's documented deformations. Rule 1 replaced division with
% addition-and-point-placement; Rule 2 replaced multiplication with
% addition. Rule 4 replaces place-value-aligned column addition with
% flat digit-string addition and a symbolic point-reattachment.
% Three instances is no longer anecdote — it's a consistent deformation
% mode: content-carrying arithmetic pressed into the wrong content,
% then garnished with a symbolic move that has no arithmetic content
% at all.

%! benny_rule4_strip_decimal_add(+Input:term, -Got:list) is det.
%
%  Runs Benny's Rule 4 as a deliberately shallow 4-state FSM:
%
%    q_init                     → license A and B via is_recollection.
%    q_strip_decimal_points     → extract digits of A (ignoring any
%                                 decimal point); same for B. Record
%                                 both as digit-lists.
%                                 PML tag: unlicensed(
%                                   symbol_manipulation_no_arithmetic).
%                                 Stripping the decimal point is pure
%                                 symbol manipulation — place-value is
%                                 discarded at this step, before any
%                                 arithmetic runs.
%    q_add_as_integers          → sum the digit-lists as if they were
%                                 integers, via add_grounded.
%                                 PML tag: unlicensed(
%                                   content_replacement(place_value_stripped)).
%                                 The arithmetic is valid — the sum
%                                 passes is_recollection — but it is
%                                 pressed into the wrong content:
%                                 addition of positional digits treated
%                                 as place-valueless.
%    q_reattach_decimal_heuristic
%                               → if either input had a decimal point,
%                                 prepend a `decimal_point` atom to the
%                                 sum's digit list.
%                                 PML tag: unlicensed(
%                                   symbol_manipulation_no_arithmetic).
%                                 No is_recollection gate — point
%                                 reattachment produces no arithmetic
%                                 result; it operates on numerals as
%                                 symbols.
%    q_emit                     → return the flat digit list.
%
%  Input: `A-B` where A and B are integers or floats.
%  Output: a flat digit list (Benny's answer as a numeral-string).
%
%  Examples:
%    benny_rule4_strip_decimal_add(2-0.3, Got).
%      → Got = [decimal_point, 5]          (correct is [2, decimal_point, 3])
%    benny_rule4_strip_decimal_add(1-0.5, Got).
%      → Got = [decimal_point, 6]          (correct is [1, decimal_point, 5])
%    benny_rule4_strip_decimal_add(2-3, Got).
%      → Got = [5]                         (no point in either input → no
%                                           point in output; correct is [5].
%                                           This is a well_formed dedup.)
%    benny_rule4_strip_decimal_add(0.7-0.5, Got).
%      → Got = [decimal_point, 1, 2]       (both inputs had points; sum is
%                                           7+5=12; point prepended.
%                                           Correct is [1, decimal_point, 2].
%                                           Not a coincidence — same digits,
%                                           different placement.)
benny_rule4_strip_decimal_add(A-B, Got) :-
    incur_cost(strategy_selection),
    % q_init — license both inputs by routing their integer projections
    % through is_recollection. For floats, the integer projection is the
    % digit-string's integer interpretation (see digits_of_numeral/2).
    digits_of_numeral(A, DigitsA, HadPointA),
    digits_of_numeral(B, DigitsB, HadPointB),
    digits_to_integer_local(DigitsA, IntA),
    digits_to_integer_local(DigitsB, IntB),
    once(is_recollection(IntA, _)),
    once(is_recollection(IntB, _)),
    % q_strip_decimal_points — already done by digits_of_numeral; the
    % HadPoint flags carry the only trace of the stripped notation.
    % PML tag: unlicensed(symbol_manipulation_no_arithmetic).
    %
    % q_add_as_integers — sum the digit-strings as integers.
    % PML tag: unlicensed(content_replacement(place_value_stripped)).
    integer_to_recollection(IntA, RecA),
    integer_to_recollection(IntB, RecB),
    add_grounded(RecA, RecB, SumRec),
    recollection_to_integer(SumRec, Sum),
    once(is_recollection(Sum, _)),
    integer_to_digit_list(Sum, SumDigits),
    % q_reattach_decimal_heuristic — no arithmetic; pure symbol move.
    % PML tag: unlicensed(symbol_manipulation_no_arithmetic).
    ( ( HadPointA == true ; HadPointB == true )
    -> Got = [decimal_point | SumDigits]
    ;  Got = SumDigits
    ).

% --- Helpers for Rule 4 ---------------------------------------------------

% digits_of_numeral(+Num, -Digits, -HadPoint)
% Extract Num's digits as a flat list, ignoring any decimal point.
% HadPoint = true if Num's surface form has a `.`.
digits_of_numeral(N, Digits, false) :-
    integer(N), !,
    integer_to_digit_list(N, Digits).
digits_of_numeral(N, Digits, true) :-
    float(N), !,
    format(atom(A), '~w', [N]),
    atom_chars(A, Chars),
    exclude(=('.'), Chars, DigitChars),
    maplist(char_to_digit_local, DigitChars, Digits).

char_to_digit_local(C, D) :- char_code(C, Code), D is Code - 0'0, D >= 0, D =< 9.

% digits_to_integer_local(+Ds, -N)
% Treat a digit list as an integer (high-to-low, left-to-right).
% E.g. [2] → 2; [3] → 3; [0,3] → 3; [1,5] → 15.
digits_to_integer_local([], 0).
digits_to_integer_local([D|Ds], N) :-
    digits_to_integer_local_(Ds, D, N).
digits_to_integer_local_([], Acc, Acc).
digits_to_integer_local_([D|Rest], Acc, N) :-
    Acc1 is Acc * 10 + D,
    digits_to_integer_local_(Rest, Acc1, N).

% --- Rule 2 registrations (fraction equivalence) ---
% Benny: 5+10=15, 4+11=15 → equivalent. Correct: 55 ≠ 40 → not_equivalent. wrong_answer.
test_harness:arith_misconception(erlwanger_1973, fraction, benny_rule2_5_10_vs_4_11,
    misconceptions_benny:benny_rule2_additive_equivalence,
    frac(5, 10)-frac(4, 11),
    not_equivalent).
% Benny: 1+2=3, 2+4=6 → not_equivalent. Correct: 4 = 4 → equivalent. wrong_answer.
test_harness:arith_misconception(erlwanger_1973, fraction, benny_rule2_1_2_vs_2_4,
    misconceptions_benny:benny_rule2_additive_equivalence,
    frac(1, 2)-frac(2, 4),
    equivalent).
% Benny: 2+3=5, 3+4=7 → not_equivalent. Correct: 8 ≠ 9 → not_equivalent.
% Dedup coincidence: Benny's addition happens to agree with the correct answer.
% Classification: well_formed (same answer, different reasoning).
test_harness:arith_misconception(erlwanger_1973, fraction, benny_rule2_2_3_vs_3_4_coincidence,
    misconceptions_benny:benny_rule2_additive_equivalence,
    frac(2, 3)-frac(3, 4),
    not_equivalent).
test_harness:arith_trace_profile(
    misconceptions_benny:benny_rule2_additive_equivalence,
    frac(2, 3)-frac(3, 4),
    [add_numerators, add_denominators, compare_sums],
    [cross_multiply, compare_products]).

% --- Rule 6 registrations (procedural / surface-form equivalence) ---
% Expected values are the CORRECT value-equivalence answers. Rule 6 returns
% identical/distinct, never equivalent/not_equivalent, so it differs from
% every expectation here — it answers the wrong KIND of question (surface
% identity, not value). Both rows therefore classify wrong_answer; there is
% no well_formed dedup possible for this rule.
%
% Benny: 1/2 and 2/4 are written differently -> distinct. Correct: 1/2 = 2/4
% in value -> equivalent. The headline false negative. wrong_answer.
test_harness:arith_misconception(erlwanger_1973, fraction, benny_rule6_1_2_vs_2_4,
    misconceptions_benny:benny_rule6_procedural_equivalence,
    frac(1, 2)-frac(2, 4),
    equivalent).
% Benny: 3/4 and 3/4 are written identically -> identical. Correct: equivalent.
% Exercises the identical branch. Benny's direction coincides with the truth
% here, but the answer is still the wrong KIND (surface verdict, not value
% verdict), so it classifies wrong_answer. wrong_answer.
test_harness:arith_misconception(erlwanger_1973, fraction, benny_rule6_3_4_vs_3_4,
    misconceptions_benny:benny_rule6_procedural_equivalence,
    frac(3, 4)-frac(3, 4),
    equivalent).

% --- Rule 4 registrations (decimal addition) ---
% Expected values are the CORRECT answers as flat digit lists for harness
% comparison. Correct coordinated decimal-addition produces a counting2
% stack; the flat-list expectation here is the projection that the Benny
% FSM operates on, making the dedup coincidence (2+3 case) legible.
%
% Benny gives [decimal_point, 5] ; correct flat projection is
% [2, decimal_point, 3]. wrong_answer.
test_harness:arith_misconception(erlwanger_1973, decimal, benny_rule4_2_plus_0_3,
    misconceptions_benny:benny_rule4_strip_decimal_add,
    2-0.3,
    [2, decimal_point, 3]).
% Benny gives [decimal_point, 6] ; correct flat projection is
% [1, decimal_point, 5]. wrong_answer.
test_harness:arith_misconception(erlwanger_1973, decimal, benny_rule4_1_plus_0_5,
    misconceptions_benny:benny_rule4_strip_decimal_add,
    1-0.5,
    [1, decimal_point, 5]).
% Benny gives [5] ; correct is [5]. No point in inputs → no point
% reattached. Dedup coincidence — the integer-addition case where Benny's
% deformation is inert because there is no place-value to strip.
% Classification: well_formed.
test_harness:arith_misconception(erlwanger_1973, decimal, benny_rule4_2_plus_3_dedup,
    misconceptions_benny:benny_rule4_strip_decimal_add,
    2-3,
    [5]).
% Benny gives [decimal_point, 1, 2] ; correct flat projection is
% [1, decimal_point, 2]. Same digits, wrong placement — the point-
% reattachment heuristic drops the decimal to the leftmost slot
% regardless of where place-value alignment would put it. wrong_answer.
test_harness:arith_misconception(erlwanger_1973, decimal, benny_rule4_0_7_plus_0_5,
    misconceptions_benny:benny_rule4_strip_decimal_add,
    0.7-0.5,
    [1, decimal_point, 2]).
