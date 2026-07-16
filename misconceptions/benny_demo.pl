/** <module> Benny vs Correct: Side-by-Side Demonstration
 *
 * Runs both Benny's rule deformations and their correct coordinated
 * counterparts on the same inputs, printing history side by side.
 * Purpose: make the algorithmic-elaboration contrast legible — a shallow
 * four-state FSM vs a fifteen-state coordinated automaton with
 * multiplication and subtraction sub-invocations.
 *
 * Invocation:
 *   swipl -l paths.pl -l misconceptions/benny_demo.pl -g run_demo -t halt
 */
:- module(misconceptions_benny_demo, [run_demo/0, benny_demo_dict/1]).

:- use_module(library(lists)).
:- use_module(misconceptions(benny), []).
:- use_module(strategies(math/smr_div_long),
              [run_long_division/5, run_long_division_string/5]).
:- use_module(strategies(math/counting2), [render_stack_decimal/2]).
:- use_module(strategies(math/smr_frac_equiv_cross_mult), [run_cross_mult_equiv/6]).
:- use_module(strategies(math/sar_add_decimal_columnar),
              [run_decimal_column_add/4]).

run_demo :-
    section('Benny vs Correct: Long Division (3/4)'),
    demo_division(3, 4),
    nl,
    section('Benny vs Correct: Long Division (5/10)'),
    demo_division(5, 10),
    nl,
    section('Benny vs Correct: Fraction Equivalence (5/10 ~ 4/11?)'),
    demo_equivalence(5, 10, 4, 11),
    nl,
    section('Benny vs Correct: Fraction Equivalence (1/2 ~ 2/4?)'),
    demo_equivalence(1, 2, 2, 4),
    nl,
    section('Benny vs Correct: Fraction Equivalence (2/3 ~ 3/4?) — dedup coincidence'),
    demo_equivalence(2, 3, 3, 4),
    nl,
    section('Benny vs Correct: Decimal Addition (2 + 0.3)'),
    demo_decimal_add(2, 0.3),
    nl,
    section('Benny vs Correct: Decimal Addition (0.7 + 0.5)'),
    demo_decimal_add(0.7, 0.5),
    nl,
    section('Benny vs Correct: Decimal Addition (2 + 3) — dedup coincidence'),
    demo_decimal_add(2, 3).

section(Title) :-
    format('~n=== ~w ===~n', [Title]).

% --- Division demo --------------------------------------------------------

demo_division(N, D) :-
    format('CORRECT:~n', []),
    format('  run_long_division(~w, ~w, Stack, R, History).~n', [N, D]),
    run_long_division(N, D, CorrectStack, CorrectR, CorrectHist),
    render_stack_decimal(CorrectStack, CorrectStr),
    length(CorrectHist, NCorrect),
    format('  -> Stack = ~w  ->  "~w"  (R = ~w, ~w transitions)~n',
           [CorrectStack, CorrectStr, CorrectR, NCorrect]),
    correct_state_names(CorrectHist, CorrectStates),
    format('  History (states): ~w~n', [CorrectStates]),

    format('~nBENNY (Rule 1):~n', []),
    format('  benny_rule1_fraction_to_decimal(frac(~w, ~w), Q).~n', [N, D]),
    misconceptions_benny:benny_rule1_fraction_to_decimal(frac(N, D), BennyQ),
    format('  -> Q = ~w   (flat digit list; no place-value grounding)~n', [BennyQ]),
    format('  Elided sub-states:~n', []),
    format('    q_bring_down_digit, q_estimate_quotient_digit~n', []),
    format('    q_subtract_with_borrow, q_continue_decimal~n', []),
    format('  Elided sub-automata:~n', []),
    format('    smr_mult_commutative_reasoning  (estimation trials)~n', []),
    format('    sar_sub_decomposition           (partial-dividend borrow)~n', []),
    format('  PML tags:~n', []),
    format('    q_sum_num_den         : unlicensed(content_replacement(division_by_addition))~n', []),
    format('    q_place_decimal_heuristic : unlicensed(symbol_manipulation_no_arithmetic)~n', []),
    format('  Compression: ~w correct states -> 4 Benny states~n', [NCorrect]),
    format('~nContrast:~n', []),
    format('  Correct quotient is place-value-grounded via counting2.pl''s PDA stack structure.~n', []),
    format('  Benny''s quotient is a flat symbol list; the decimal point is syntactic, not structural.~n', []),
    ( CorrectStr == BennyQ
    -> format('  NOTE: Benny coincides with correct on this input (dedup).~n', [])
    ;  format('  Classification: wrong_answer (Benny ~w vs correct "~w").~n',
              [BennyQ, CorrectStr])
    ).

correct_state_names(Hist, Names) :-
    findall(Name, member(hist(Name, _), Hist), Names).

% --- Equivalence demo -----------------------------------------------------

demo_equivalence(N1, D1, N2, D2) :-
    format('CORRECT:~n', []),
    format('  run_cross_mult_equiv(~w, ~w, ~w, ~w, R, H).~n', [N1, D1, N2, D2]),
    run_cross_mult_equiv(N1, D1, N2, D2, CorrectR, CorrectHist),
    correct_state_names(CorrectHist, CorrectStates),
    format('  -> R = ~w~n', [CorrectR]),
    format('  States: ~w~n', [CorrectStates]),
    ( member(hist(q_multiply_cross_1, cross(_, _, P1, _)), CorrectHist),
      member(hist(q_multiply_cross_2, cross(_, _, P2, _)), CorrectHist)
    -> format('  Cross products: ~w*~w = ~w ; ~w*~w = ~w~n', [N1, D2, P1, N2, D1, P2])
    ;  true
    ),

    format('~nBENNY (Rule 2):~n', []),
    format('  benny_rule2_additive_equivalence(frac(~w,~w)-frac(~w,~w), R).~n',
           [N1, D1, N2, D2]),
    misconceptions_benny:benny_rule2_additive_equivalence(
        frac(N1, D1)-frac(N2, D2), BennyR),
    S1 is N1 + D1, S2 is N2 + D2,
    format('  -> R = ~w~n', [BennyR]),
    format('  Benny sums: ~w+~w = ~w ; ~w+~w = ~w~n', [N1, D1, S1, N2, D2, S2]),
    format('  Elided sub-automata:~n', []),
    format('    smr_mult_commutative_reasoning  (x 2 — both cross products)~n', []),
    format('  PML tag (both sum steps):~n', []),
    format('    unlicensed(content_replacement(multiplication_by_addition))~n', []),
    format('  Intact step: q_compare (grounded equal_to/2 on sums)~n', []),
    ( CorrectR == BennyR
    -> format('  NOTE: Benny coincides with correct on this input (dedup — well_formed).~n', [])
    ;  format('  Classification: wrong_answer (Benny ~w vs correct ~w).~n', [BennyR, CorrectR])
    ).

% --- Decimal addition demo (Rule 4) ---------------------------------------

demo_decimal_add(A, B) :-
    format('CORRECT:~n', []),
    format('  run_decimal_column_add(~w, ~w, Stack, History).~n', [A, B]),
    run_decimal_column_add(A, B, CorrectStack, CorrectHist),
    render_stack_decimal(CorrectStack, CorrectStr),
    length(CorrectHist, NCorrect),
    format('  -> Stack = ~w~n', [CorrectStack]),
    format('            -> "~w"  (~w transitions)~n', [CorrectStr, NCorrect]),
    correct_state_names(CorrectHist, CorrectStates),
    format('  History (states): ~w~n', [CorrectStates]),

    format('~nBENNY (Rule 4):~n', []),
    format('  benny_rule4_strip_decimal_add(~w-~w, Got).~n', [A, B]),
    misconceptions_benny:benny_rule4_strip_decimal_add(A-B, BennyGot),
    format('  -> Got = ~w   (flat digit list; decimal point reattached heuristically)~n',
           [BennyGot]),
    format('  Elided sub-abilities:~n', []),
    format('    q_align_decimal_points   (place-value alignment)~n', []),
    format('    q_add_column + q_carry_up (per-column add with carry)~n', []),
    format('  PML tags on Benny''s transitions:~n', []),
    format('    q_strip_decimal_points       : unlicensed(symbol_manipulation_no_arithmetic)~n', []),
    format('    q_add_as_integers            : unlicensed(content_replacement(place_value_stripped))~n', []),
    format('    q_reattach_decimal_heuristic : unlicensed(symbol_manipulation_no_arithmetic)~n', []),
    format('  Compression: ~w correct states -> 4 Benny states~n', [NCorrect]),
    format('~nContrast:~n', []),
    format('  Correct sum is place-value-grounded via counting2.pl''s stack structure;~n', []),
    format('    column additions land in ones / tenths / hundredths slots by position.~n', []),
    format('  Benny''s sum is a flat digit-string with a single decimal-point atom~n', []),
    format('    heuristically prepended if either input carried a point.~n', []),
    ( benny_output_matches_correct(BennyGot, CorrectStr)
    -> format('  NOTE: Benny coincides with correct on this input (dedup — well_formed).~n', [])
    ;  format('  Classification: wrong_answer (Benny ~w vs correct "~w").~n',
              [BennyGot, CorrectStr])
    ).

% Benny's flat digit-list coincides with the correct rendered string when
% their digit sequences match (treating `decimal_point` as `.`).
benny_output_matches_correct(BennyDigits, CorrectStr) :-
    benny_digits_to_string(BennyDigits, BennyStr),
    BennyStr == CorrectStr.

benny_digits_to_string(Digits, String) :-
    maplist(benny_digit_char, Digits, Chars),
    string_chars(String, Chars).

benny_digit_char(decimal_point, '.') :- !.
benny_digit_char(D, C) :- integer(D), D >= 0, D =< 9, atom_number(A, D), atom_chars(A, [C]).

% --- Structured form for the JSON-RPC worker + console encyclopedia ----------
%
% benny_demo_dict(-Dict) is det. The same side-by-side content run_demo/0 prints
% to stdout, returned as a JSON-ready nested dict instead. Each comparison runs
% the correct coordinated automaton and Benny's deformed rule on shared inputs
% and reports the divergence. Reuses the module-local helpers
% (correct_state_names/2, benny_digits_to_string/2, benny_output_matches_correct/2)
% and the imported run_* + misconceptions_benny:* predicates.
benny_demo_dict(_{
    title: "Benny vs Correct - rule deformations, side by side",
    blurb: "Benny's deformed rules (a shallow four-state FSM) run beside their correct coordinated counterparts on the same inputs. Where Benny coincides with the correct answer it is a well-formed dedup; otherwise it is a wrong answer.",
    comparisons: Comparisons
}) :-
    findall(C, demo_comparison(C), Comparisons).

% once/1 guards each input to exactly one comparison: some correct automata
% (e.g. the decimal columnar adder on integer inputs) leave a choicepoint, which
% would otherwise duplicate a row in the findall.
demo_comparison(C) :-
    member(N-D, [3-4, 5-10]),
    once(division_comparison(N, D, C)).
demo_comparison(C) :-
    member(eq(N1, D1, N2, D2), [eq(5, 10, 4, 11), eq(1, 2, 2, 4), eq(2, 3, 3, 4)]),
    once(equivalence_comparison(N1, D1, N2, D2, C)).
demo_comparison(C) :-
    member(A-B, [2-0.3, 0.7-0.5, 2-3]),
    once(decimal_add_comparison(A, B, C)).

division_comparison(N, D, _{
    kind: "long_division", title: Title, expression: Expr,
    correct: _{ result: CorrectStr, remainder: CorrectR,
                transitions: NCorrect, states: CorrectStates },
    benny: _{ rule: "rule1_fraction_to_decimal", output: BennyStr,
              states: [q_sum_num_den, q_place_decimal_heuristic, q_emit_digits, q_done],
              pml_tags: [
                "q_sum_num_den: unlicensed(content_replacement(division_by_addition))",
                "q_place_decimal_heuristic: unlicensed(symbol_manipulation_no_arithmetic)" ] },
    classification: Class,
    contrast: "Correct quotient is place-value-grounded via counting2's stack; Benny's is a flat symbol list whose decimal point is syntactic, not structural."
}) :-
    format(string(Title), "Long Division (~w/~w)", [N, D]),
    format(string(Expr), "~w / ~w", [N, D]),
    run_long_division(N, D, CorrectStack, CorrectR, CorrectHist),
    render_stack_decimal(CorrectStack, CorrectStr),
    length(CorrectHist, NCorrect),
    correct_state_names(CorrectHist, CorrectStates),
    misconceptions_benny:benny_rule1_fraction_to_decimal(frac(N, D), BennyQ),
    benny_digits_to_string(BennyQ, BennyStr),
    ( BennyStr == CorrectStr -> Class = "coincides_dedup" ; Class = "wrong_answer" ).

equivalence_comparison(N1, D1, N2, D2, _{
    kind: "fraction_equivalence", title: Title, expression: Expr,
    correct: _{ result: CorrectRStr, states: CorrectStates, cross_products: CrossStr },
    benny: _{ rule: "rule2_additive_equivalence", result: BennyRStr, sums: SumsStr,
              pml_tags: ["unlicensed(content_replacement(multiplication_by_addition))"] },
    classification: Class
}) :-
    format(string(Title), "Fraction Equivalence (~w/~w ~~ ~w/~w?)", [N1, D1, N2, D2]),
    format(string(Expr), "~w/~w ~~ ~w/~w", [N1, D1, N2, D2]),
    run_cross_mult_equiv(N1, D1, N2, D2, CorrectR, CorrectHist),
    atom_string(CorrectR, CorrectRStr),
    correct_state_names(CorrectHist, CorrectStates),
    ( member(hist(q_multiply_cross_1, cross(_, _, P1, _)), CorrectHist),
      member(hist(q_multiply_cross_2, cross(_, _, P2, _)), CorrectHist)
    -> format(string(CrossStr), "~w*~w = ~w ; ~w*~w = ~w", [N1, D2, P1, N2, D1, P2])
    ;  CrossStr = "" ),
    misconceptions_benny:benny_rule2_additive_equivalence(frac(N1, D1)-frac(N2, D2), BennyR),
    atom_string(BennyR, BennyRStr),
    S1 is N1 + D1, S2 is N2 + D2,
    format(string(SumsStr), "~w+~w = ~w ; ~w+~w = ~w", [N1, D1, S1, N2, D2, S2]),
    ( CorrectR == BennyR -> Class = "coincides_dedup" ; Class = "wrong_answer" ).

decimal_add_comparison(A, B, _{
    kind: "decimal_addition", title: Title, expression: Expr,
    correct: _{ result: CorrectStr, transitions: NCorrect, states: CorrectStates },
    benny: _{ rule: "rule4_strip_decimal_add", output: BennyStr,
              pml_tags: [
                "q_strip_decimal_points: unlicensed(symbol_manipulation_no_arithmetic)",
                "q_add_as_integers: unlicensed(content_replacement(place_value_stripped))",
                "q_reattach_decimal_heuristic: unlicensed(symbol_manipulation_no_arithmetic)" ] },
    classification: Class
}) :-
    format(string(Title), "Decimal Addition (~w + ~w)", [A, B]),
    format(string(Expr), "~w + ~w", [A, B]),
    run_decimal_column_add(A, B, CorrectStack, CorrectHist),
    render_stack_decimal(CorrectStack, CorrectStr),
    length(CorrectHist, NCorrect),
    correct_state_names(CorrectHist, CorrectStates),
    misconceptions_benny:benny_rule4_strip_decimal_add(A-B, BennyGot),
    benny_digits_to_string(BennyGot, BennyStr),
    ( benny_output_matches_correct(BennyGot, CorrectStr)
    -> Class = "coincides_dedup" ; Class = "wrong_answer" ).
