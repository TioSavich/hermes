:- encoding(utf8).
/** <module> Grade 8 draft: writing a decimal back as a fraction
 *
 * WHAT THIS IS. A draft automaton for the direction the published pilot
 * `g8_root_and_number_class` does not run. That pilot turns a fraction into
 * its decimal, and it does it well: 2/11 comes back as 0.(18) with the repeat
 * marked. Grade 8 unit 8 spends two lessons going the other way, and the
 * round-two corrections recovered both: correction 135 asks students to show
 * that 0.2, 0.333 and -1.000001 are rational by writing each as a fraction,
 * and correction 138 hands them Noah's cards for 0.4̄85 = 481/990 and asks
 * them to use his method on 0.1̄86 and 0.7̄88.
 *
 * NOAH'S METHOD IS THE TRANSITION TABLE. Multiply by ten as many times as the
 * prefix is long, multiply again by ten as many times as the repeating block
 * is long, subtract the one from the other so the tails cancel, and divide.
 * Each of those is a named state, so the run shows the subtraction that makes
 * the repeating tail disappear rather than reporting a fraction.
 *
 * WHY THE REPEAT MUST BE DECLARED. A printed "0.333" is 333/1000 and a
 * printed 0.3̄ is 1/3, and no amount of looking at the digits decides which
 * one a page meant. The contract therefore takes the repeating block as its
 * own field: a terminating decimal and a repeating one are different inputs,
 * not the same input read two ways. Correction 135 prints 0.333 with no bar,
 * and this module answers 333/1000 for it.
 *
 * DEFORMATION PARTNER. `digits_before_over_digits_after` builds the fraction
 * from the numeral's two halves — the digits left of the point over the
 * digits right of it. The research corpus attests exactly this shape at row
 * 37613 (a student uses the digit before the decimal as the numerator and the
 * digit after as the denominator). It is offered as a deformation of the
 * doing, not as a diagnosis of any student.
 *
 * QUARANTINE. Nothing imports this module; it is a draft under
 * `.superpowers/sdd/g8-round2/`. Check: `check_g8_decimal_fraction_form/0`.
 */

:- module(g8_decimal_fraction_form,
          [ run_g8_decimal_fraction/4,
            g8_decimal_fraction_from_json/2,
            g8_decimal_fraction_states/1,
            g8_decimal_fraction_state_label/4,
            g8_decimal_fraction_summary/1,
            g8_decimal_fraction_receipt/5,
            check_g8_decimal_fraction_form/0
          ]).

:- use_module(strategies('abstraction/g8_quantity_input'),
              [ g8_rational_text/2 ]).

% ==========================================================================
% 1. INPUT CONTRACT
%
%   {"kind":"terminating_decimal","numeral":"-1.000001"}
%   {"kind":"repeating_decimal","sign":"+","whole":"0","prefix":"4",
%    "block":"85"}
%   {"kind":"rational_expansion","n":2,"d":11,"places":4}
%
% A numeral arrives as a STRING so its written digits survive: "0.2" and
% "0.20" are one quantity and two numerals, and a float would lose the
% difference before the automaton could report it.
% ==========================================================================

g8_decimal_fraction_input_contract(
    '{\"kind\":\"terminating_decimal\",\"numeral\":\"string\"}',
    '{\"kind\":\"terminating_decimal\",\"numeral\":\"0.2\"}').

g8_decimal_fraction_from_json(Dict, terminating(Text, Sign, Whole, Fraction)) :-
    is_dict(Dict),
    get_dict(kind, Dict, "terminating_decimal"), !,
    get_dict(numeral, Dict, Text), string(Text),
    split_numeral(Text, Sign, Whole, Fraction),
    Fraction \== "".
g8_decimal_fraction_from_json(Dict, repeating(Sign, Whole, Prefix, Block)) :-
    is_dict(Dict),
    get_dict(kind, Dict, "repeating_decimal"), !,
    ( get_dict(sign, Dict, "-") -> Sign = -1 ; Sign = 1 ),
    ( get_dict(whole, Dict, W), string(W) -> Whole = W ; Whole = "0" ),
    ( get_dict(prefix, Dict, P), string(P) -> Prefix = P ; Prefix = "" ),
    get_dict(block, Dict, Block), string(Block), Block \== "",
    string_of_digits(Whole), string_of_digits(Prefix),
    string_of_digits(Block).
g8_decimal_fraction_from_json(Dict, expansion(N, D, Places)) :-
    is_dict(Dict),
    get_dict(kind, Dict, "rational_expansion"),
    get_dict(n, Dict, N), integer(N),
    get_dict(d, Dict, D), integer(D), D > 0,
    ( get_dict(places, Dict, Places), integer(Places), Places > 0
    -> true ; Places = 6 ).

split_numeral(Text, Sign, Whole, Fraction) :-
    (   string_concat("-", Rest, Text)
    ->  Sign = -1, Body = Rest
    ;   Sign = 1, Body = Text
    ),
    split_string(Body, ".", "", [Whole, Fraction]),
    string_of_digits(Whole), string_of_digits(Fraction).

string_of_digits(S) :-
    string_codes(S, Codes),
    forall(member(C, Codes), ( C >= 0'0, C =< 0'9 )).

% ==========================================================================
% 2. STATES
% ==========================================================================

g8_decimal_fraction_states(
    [ q_read_the_numeral,
      q_count_the_places_after_the_point,
      q_write_the_digits_over_that_power_of_ten,
      q_reduce_to_lowest_terms,
      q_report_the_fraction,
      q_shift_past_the_prefix,
      q_shift_past_one_repeating_block,
      q_subtract_so_the_tails_cancel,
      q_divide_by_the_difference_of_the_shifts,
      q_carry_the_long_division_one_place_further,
      q_report_the_repeating_block,
      q_read_the_two_halves_of_the_numeral_as_a_fraction ]).

% g8_decimal_fraction_state_label(State, Tradition, Label, Citation).
g8_decimal_fraction_state_label(q_count_the_places_after_the_point,
    illustrative_mathematics,
    "a decimal names a number of tenths, hundredths, or thousandths",
    "IM Grade 8 Unit 8 Lesson 16, Rational and Irrational Numbers").
g8_decimal_fraction_state_label(q_write_the_digits_over_that_power_of_ten, ccss,
    "know that numbers that are not rational are called irrational, and convert a decimal expansion into a rational number",
    "CCSS 8.NS.A.1, via IM Grade 8 Unit 8 Lesson 16").
g8_decimal_fraction_state_label(q_subtract_so_the_tails_cancel,
    illustrative_mathematics,
    "Noah's method: two shifts of the same number, subtracted so the repeating tail cancels",
    "IM Grade 8 Unit 8 Lesson 17, Infinite Decimal Expansions, the printed card sort").
g8_decimal_fraction_state_label(q_carry_the_long_division_one_place_further,
    illustrative_mathematics,
    "finding the next decimal place by continuing the long division",
    "IM Grade 8 Unit 8 Lesson 16, Activity 16.4, the zooming number lines").
g8_decimal_fraction_state_label(q_reduce_to_lowest_terms, provisional,
    "the fraction written with no common factor left",
    "provisional; no community label sourced for the reducing step").
g8_decimal_fraction_state_label(
    q_read_the_two_halves_of_the_numeral_as_a_fraction, research_corpus,
    "the digits before the point over the digits after it",
    "research corpus row 37613, a student uses the digit before the decimal as the numerator and the digit after as the denominator").

% ==========================================================================
% 3. TRANSITIONS
% ==========================================================================

g8_decimal_fraction_transition(fraction_form_of_a_terminating_decimal,
    q_read_the_numeral, count_the_places_after_the_point,
    q_count_the_places_after_the_point).
g8_decimal_fraction_transition(fraction_form_of_a_terminating_decimal,
    q_count_the_places_after_the_point, write_the_digits_over_that_power_of_ten,
    q_write_the_digits_over_that_power_of_ten).
g8_decimal_fraction_transition(fraction_form_of_a_terminating_decimal,
    q_write_the_digits_over_that_power_of_ten, reduce_to_lowest_terms,
    q_reduce_to_lowest_terms).
g8_decimal_fraction_transition(fraction_form_of_a_terminating_decimal,
    q_reduce_to_lowest_terms, report_the_fraction, q_report_the_fraction).
g8_decimal_fraction_transition(fraction_form_of_a_repeating_decimal,
    q_read_the_numeral, shift_past_the_prefix, q_shift_past_the_prefix).
g8_decimal_fraction_transition(fraction_form_of_a_repeating_decimal,
    q_shift_past_the_prefix, shift_past_one_repeating_block,
    q_shift_past_one_repeating_block).
g8_decimal_fraction_transition(fraction_form_of_a_repeating_decimal,
    q_shift_past_one_repeating_block, subtract_so_the_tails_cancel,
    q_subtract_so_the_tails_cancel).
g8_decimal_fraction_transition(fraction_form_of_a_repeating_decimal,
    q_subtract_so_the_tails_cancel, divide_by_the_difference_of_the_shifts,
    q_divide_by_the_difference_of_the_shifts).
g8_decimal_fraction_transition(fraction_form_of_a_repeating_decimal,
    q_divide_by_the_difference_of_the_shifts, reduce_to_lowest_terms,
    q_reduce_to_lowest_terms).
g8_decimal_fraction_transition(digits_of_a_repeating_expansion,
    q_read_the_numeral, carry_the_long_division_one_place_further,
    q_carry_the_long_division_one_place_further).
g8_decimal_fraction_transition(digits_of_a_repeating_expansion,
    q_carry_the_long_division_one_place_further, report_the_repeating_block,
    q_report_the_repeating_block).
g8_decimal_fraction_transition(digits_before_over_digits_after,
    q_read_the_numeral, read_the_two_halves_of_the_numeral_as_a_fraction,
    q_read_the_two_halves_of_the_numeral_as_a_fraction).

% ==========================================================================
% 4. THE RUN
% ==========================================================================

run_g8_decimal_fraction(fraction_form_of_a_terminating_decimal,
                        terminating(Text, Sign, Whole, Fraction), Outcome,
                        Trace) :-
    string_length(Fraction, Places),
    number_string(WholePart, Whole),
    number_string(FractionPart, Fraction),
    Scale is 10 ^ Places,
    Numerator is Sign * (WholePart * Scale + FractionPart),
    Value is Numerator rdiv Scale,
    N is numerator(Value), D is denominator(Value),
    format(atom(A), '~w/~w', [N, D]), atom_string(A, FractionText),
    % substitution receipt: the fraction divided out returns the numeral's own
    % exact value
    Rebuilt is N rdiv D,
    ( Rebuilt =:= Value -> Validity = correct ; Validity = unvindicated ),
    Outcome = action_outcome(
        fraction_form_of_a_terminating_decimal,
        [ classification(productive),
          cluster(g8_roots_and_number_class),
          automaton_state(q_report_the_fraction),
          vocabulary([rational_number, decimal, fraction, place_value,
                      lowest_terms]),
          input(terminating(Text, Sign, Whole, Fraction)),
          result(fraction(FractionText)),
          expected(fraction(FractionText)),
          places(Places),
          over_a_power_of_ten(Numerator/Scale),
          invariant(the_fraction_divides_back_to_the_numeral),
          validity(Validity) ]),
    Trace = [ count_the_places_after_the_point(Places),
              write_the_digits_over_that_power_of_ten(Numerator, Scale),
              reduce_to_lowest_terms(N, D),
              report_the_fraction(FractionText) ].
run_g8_decimal_fraction(fraction_form_of_a_repeating_decimal,
                        repeating(Sign, Whole, Prefix, Block), Outcome, Trace) :-
    string_length(Prefix, PrefixLength),
    string_length(Block, BlockLength),
    number_string(WholePart, Whole),
    string_concat(Prefix, Block, PrefixAndBlock),
    ( PrefixAndBlock == "" -> Long = 0 ; number_string(Long, PrefixAndBlock) ),
    ( Prefix == "" -> Short = 0 ; number_string(Short, Prefix) ),
    ShortShift is 10 ^ PrefixLength,
    LongShift is 10 ^ (PrefixLength + BlockLength),
    % ten to the prefix length, and again to the block length: the two shifts
    % whose difference cancels the repeating tail
    Difference is LongShift - ShortShift,
    Numerator is Sign * ( WholePart * Difference + Long - Short ),
    Value is Numerator rdiv Difference,
    N is numerator(Value), D is denominator(Value),
    format(atom(A), '~w/~w', [N, D]), atom_string(A, FractionText),
    Outcome = action_outcome(
        fraction_form_of_a_repeating_decimal,
        [ classification(productive),
          cluster(g8_roots_and_number_class),
          automaton_state(q_report_the_fraction),
          vocabulary([rational_number, repeating_decimal, fraction,
                      infinite_decimal_expansion, lowest_terms]),
          input(repeating(Sign, Whole, Prefix, Block)),
          result(fraction(FractionText)),
          expected(fraction(FractionText)),
          shifts(ShortShift, LongShift),
          before_reducing(Numerator/Difference),
          invariant(the_two_shifts_differ_by_a_whole_number),
          validity(correct) ]),
    Trace = [ shift_past_the_prefix(ShortShift),
              shift_past_one_repeating_block(LongShift),
              subtract_so_the_tails_cancel(Numerator, Difference),
              divide_by_the_difference_of_the_shifts(Difference),
              report_the_fraction(FractionText) ].
run_g8_decimal_fraction(digits_of_a_repeating_expansion, expansion(N, D, Places),
                        Outcome, Trace) :-
    Whole is N // D,
    Remainder0 is N mod D,
    long_division(Remainder0, D, Places, Digits),
    repeating_block(Remainder0, D, Block),
    atomic_list_concat(Digits, DigitAtoms),
    atom_string(DigitAtoms, DigitText),
    atomic_list_concat(Block, BlockAtoms),
    atom_string(BlockAtoms, BlockText),
    format(atom(E), '~w.(~w)', [Whole, BlockText]), atom_string(E, Expansion),
    Value is N rdiv D,
    g8_rational_text(Value, ValueText),
    Outcome = action_outcome(
        digits_of_a_repeating_expansion,
        [ classification(productive),
          cluster(g8_roots_and_number_class),
          automaton_state(q_report_the_repeating_block),
          vocabulary([long_division, decimal_place, repeating_block,
                      rational_number]),
          input(expansion(N, D, Places)),
          result(digits(DigitText, Expansion)),
          expected(digits(DigitText, Expansion)),
          exact_value(ValueText),
          invariant(each_place_comes_from_the_previous_remainder),
          validity(correct) ]),
    Trace = [ carry_the_long_division_one_place_further(Digits),
              report_the_repeating_block(BlockText) ].
run_g8_decimal_fraction(digits_before_over_digits_after,
                        terminating(Text, Sign, Whole, Fraction), Outcome,
                        Trace) :-
    % The deformation: the numeral's two halves read straight off as a
    % numerator and a denominator.
    number_string(WholePart, Whole),
    number_string(FractionPart, Fraction),
    FractionPart =\= 0,
    Claimed is Sign * (WholePart rdiv FractionPart),
    g8_rational_text(Claimed, ClaimedText),
    run_g8_decimal_fraction(fraction_form_of_a_terminating_decimal,
                            terminating(Text, Sign, Whole, Fraction),
                            action_outcome(_, Properties), _),
    memberchk(result(fraction(CorrectText)), Properties),
    format(atom(A), '~w/~w', [WholePart, FractionPart]),
    atom_string(A, ReadText),
    Outcome = action_outcome(
        digits_before_over_digits_after,
        [ classification(deformation),
          cluster(g8_roots_and_number_class),
          automaton_state(q_read_the_two_halves_of_the_numeral_as_a_fraction),
          vocabulary([decimal, numerator, denominator, place_value]),
          input(terminating(Text, Sign, Whole, Fraction)),
          result(fraction(ReadText)),
          expected(fraction(CorrectText)),
          claimed_value(ClaimedText),
          deforms(fraction_form_of_a_terminating_decimal),
          attested_by('research corpus row 37613'),
          validity(incorrect) ]),
    Trace = [ read_the_two_halves_of_the_numeral_as_a_fraction(ReadText) ].

%!  long_division(+Remainder, +Divisor, +Places, -Digits) is det.
long_division(_, _, 0, []) :- !.
long_division(Remainder, Divisor, Places, [Digit|Rest]) :-
    Scaled is Remainder * 10,
    Digit is Scaled // Divisor,
    Next is Scaled mod Divisor,
    Left is Places - 1,
    long_division(Next, Divisor, Left, Rest).

%!  repeating_block(+Remainder, +Divisor, -Block) is det.
%
%   The digits between the first repeat of a remainder. A remainder that
%   returns to zero has no repeating block and yields the digit 0.
repeating_block(Remainder, Divisor, Block) :-
    block_from(Remainder, Divisor, [], [], Block).

block_from(0, _, _, _, [0]) :- !.
block_from(Remainder, Divisor, Visited, Digits, Block) :-
    (   nth0(Index, Visited, Remainder)
    ->  length(Digits, Length),
        Start is Length - Index - 1,
        length(Prefix, Start),
        append(Prefix, Block, Digits)
    ;   Scaled is Remainder * 10,
        Digit is Scaled // Divisor,
        Next is Scaled mod Divisor,
        append(Digits, [Digit], MoreDigits),
        block_from(Next, Divisor, [Remainder|Visited], MoreDigits, Block)
    ).

% ==========================================================================
% 5. SELF-SUMMARY
% ==========================================================================

g8_decimal_fraction_summary(
    summary{ module: g8_decimal_fraction_form,
             status: draft_for_quarantine,
             generated: false,
             grade: 8,
             cluster: g8_roots_and_number_class,
             doings: [ fraction_form_of_a_terminating_decimal,
                       fraction_form_of_a_repeating_decimal,
                       digits_of_a_repeating_expansion,
                       digits_before_over_digits_after ],
             verification: [the_fraction_divides_back_to_the_numeral,
                            the_two_shifts_differ_by_a_whole_number],
             arithmetic: exact_rational,
             beside: g8_root_and_number_class,
             deformation_partners: [digits_before_over_digits_after],
             imported_by: none }).

% ==========================================================================
% 6. RECEIPTS
%
% g8_decimal_fraction_receipt(Correction, Lesson, Doing, Json, Expected).
% ==========================================================================

% correction 135, IM-G8-U8-L16: show 0.2 is rational
g8_decimal_fraction_receipt(135, 'IM-G8-U8-L16',
    fraction_form_of_a_terminating_decimal,
    _{kind: "terminating_decimal", numeral: "0.2"}, fraction("1/5")).
% correction 135: show 0.333 is rational. The numeral carries no bar, so it
% is three thousandths of a thousand and not one third.
g8_decimal_fraction_receipt(135, 'IM-G8-U8-L16',
    fraction_form_of_a_terminating_decimal,
    _{kind: "terminating_decimal", numeral: "0.333"},
    fraction("333/1000")).
% correction 135: show -1.000001 is rational
g8_decimal_fraction_receipt(135, 'IM-G8-U8-L16',
    fraction_form_of_a_terminating_decimal,
    _{kind: "terminating_decimal", numeral: "-1.000001"},
    fraction("-1000001/1000000")).
% correction 138, IM-G8-U8-L17: Noah's own card, 0.4 with 85 repeating
g8_decimal_fraction_receipt(138, 'IM-G8-U8-L17',
    fraction_form_of_a_repeating_decimal,
    _{kind: "repeating_decimal", whole: "0", prefix: "4", block: "85"},
    fraction("481/990")).
% correction 138 part a: 0.1 with 86 repeating
g8_decimal_fraction_receipt(138, 'IM-G8-U8-L17',
    fraction_form_of_a_repeating_decimal,
    _{kind: "repeating_decimal", whole: "0", prefix: "1", block: "86"},
    fraction("37/198")).
% correction 138 part b: 0.7 with 88 repeating
g8_decimal_fraction_receipt(138, 'IM-G8-U8-L17',
    fraction_form_of_a_repeating_decimal,
    _{kind: "repeating_decimal", whole: "0", prefix: "7", block: "88"},
    % 781/990 before reducing; 781 and 990 share the factor 11.
    fraction("71/90")).
% correction 137, IM-G8-U8-L16: the first four decimal places of 2/11 by long
% division, the task's own zooming sequence
g8_decimal_fraction_receipt(137, 'IM-G8-U8-L16', digits_of_a_repeating_expansion,
    _{kind: "rational_expansion", n: 2, d: 11, places: 4},
    digits("1818", "0.(18)")).
% correction 136, IM-G8-U8-L16: 3/8, whose expansion stops
g8_decimal_fraction_receipt(136, 'IM-G8-U8-L16', digits_of_a_repeating_expansion,
    _{kind: "rational_expansion", n: 3, d: 8, places: 4},
    digits("3750", "0.(0)")).
% correction 135 read through the deformation: the numeral's two halves
g8_decimal_fraction_receipt(135, 'IM-G8-U8-L16', digits_before_over_digits_after,
    _{kind: "terminating_decimal", numeral: "0.2"}, fraction("0/2")).
g8_decimal_fraction_receipt(135, 'IM-G8-U8-L16', digits_before_over_digits_after,
    _{kind: "terminating_decimal", numeral: "0.333"}, fraction("0/333")).
g8_decimal_fraction_receipt(135, 'IM-G8-U8-L16', digits_before_over_digits_after,
    _{kind: "terminating_decimal", numeral: "-1.000001"}, fraction("1/1")).

% ==========================================================================
% 7. CHECK
% ==========================================================================

check_g8_decimal_fraction_form :-
    check_receipts,
    check_the_round_trip,
    check_negative,
    format('g8_decimal_fraction_form: all checks ok~n').

check_receipts :-
    findall(Correction-Doing-Result,
            ( g8_decimal_fraction_receipt(Correction, _, Doing, Json, Expected),
              g8_decimal_fraction_from_json(Json, Figure),
              run_g8_decimal_fraction(Doing, Figure, Outcome, _),
              outcome_property(Outcome, result(Result)),
              Result = Expected
            ), Rows),
    findall(C, g8_decimal_fraction_receipt(C, _, _, _, _), All),
    length(All, Total), length(Rows, Passed),
    Total =:= Passed,
    format('  receipts: ~w/~w printed numerals run~n', [Passed, Total]),
    forall(member(Correction-Doing-Result, Rows),
           format('    correction ~w  ~w -> ~q~n',
                  [Correction, Doing, Result])).

check_the_round_trip :-
    % 481/990 is Noah's printed answer. Its long division returns the digits
    % the card started from: 4 then 85 repeating.
    g8_decimal_fraction_from_json(
        _{kind: "rational_expansion", n: 481, d: 990, places: 7}, Expansion),
    run_g8_decimal_fraction(digits_of_a_repeating_expansion, Expansion,
                            Outcome, _),
    outcome_property(Outcome, result(digits("4858585", _))),
    format('  round trip: 481/990 divides out to 0.4858585, the digits Noah started from~n').

check_negative :-
    % A numeral with no point is not a decimal to convert.
    \+ g8_decimal_fraction_from_json(
           _{kind: "terminating_decimal", numeral: "12"}, _),
    % An empty repeating block is refused: nothing repeats.
    \+ g8_decimal_fraction_from_json(
           _{kind: "repeating_decimal", whole: "0", prefix: "4", block: ""}, _),
    % A whole number with zero after the point has no deformation to report,
    % because the two halves cannot be read as a fraction at all.
    g8_decimal_fraction_from_json(
        _{kind: "terminating_decimal", numeral: "3.0"}, Whole),
    \+ run_g8_decimal_fraction(digits_before_over_digits_after, Whole, _, _),
    format('  negative tests: a numeral with no point and an empty repeating block refuse at decode; 3.0 carries no two-halves reading~n').

outcome_property(action_outcome(_, Props), Property) :-
    memberchk(Property, Props).
