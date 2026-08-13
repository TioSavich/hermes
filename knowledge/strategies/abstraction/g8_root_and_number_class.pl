:- encoding(utf8).
/** <module> Grade 8 pilot: square roots, cube roots, and what kind of number
 *
 * WHAT THIS IS. A quarantined pilot automaton for the doing IM grade 8 unit 8
 * asks for in its first half: given the area of a square, name its side length
 * exactly; given a root, say which two consecutive whole numbers it lies
 * between; decide whether a number is rational or irrational and say why; and
 * write a rational number's decimal representation.
 *
 * WHY IT IS NEW. No registered machine takes a root. `decimal/
 * positional_decimal_reading` reads a numeral by its places and the fraction
 * machines compare and combine fractions, but nothing squares a candidate
 * to bracket a root, and nothing decides rational from irrational. The
 * round-one pilot `g8_right_triangle_side` names roots exactly as a by-product
 * of the Pythagorean relation; this pilot makes the root itself the doing and
 * adds the bracketing, classification, and decimal work unit 8 builds around
 * it. It leaves that pilot and every registered machine untouched.
 *
 * BRACKETING IS SQUARING, NOT ROOTING. To say that the side of a 30-square-unit
 * square lies between 5 and 6, the automaton squares 5 and squares 6 and checks
 * that 30 sits between them. No square root is ever taken numerically, so no
 * float decides a boundary. The same holds for cube roots.
 *
 * IRRATIONALITY IS DECIDED, NOT ASSERTED. A whole number's square root is
 * rational exactly when the number is a perfect square, and this pilot decides
 * that by search-and-square rather than by table. When it reports irrational it
 * reports the two perfect squares the number falls between as its witness. When
 * it reports rational it exhibits the numerator and denominator and multiplies
 * them back.
 *
 * DECIMALS TERMINATE OR REPEAT. A rational's decimal representation is
 * computed by long division on exact integers, and a repeating block is found
 * by remembering remainders. Nothing is rounded, so 1/3 comes back as 0.(3)
 * rather than as a truncation.
 *
 * NO DEFORMATION PARTNER. The research corpus's nearest rows are about
 * Pythagorean misuse (db_row 40244), grid diagonals (db_row 38694), and
 * negative exponents (db_row 38303) — each already carries its partner in
 * another g8 pilot. Nothing in the corpus attests a root-bracketing or
 * rational-classification error, so this pilot ships without one rather than
 * inventing a twin for symmetry.
 *
 * QUARANTINE. Nothing imports this module; it renames nothing; its rows are
 * authored and vetoable one by one. Check: `check_g8_root_and_number_class/0`.
 */

:- module(g8_root_and_number_class,
          [ run_g8_root/4,
            g8_root_from_json/2,
            g8_root_states/1,
            g8_root_state_label/4,
            g8_root_summary/1,
            g8_root_receipt/5,
            check_g8_root_and_number_class/0
          ]).

:- use_module(strategies('abstraction/g8_quantity_input'),
              [ g8_quantity/2, g8_rational_text/2, g8_integer_square_root/2,
                g8_exact_root_text/2 ]).

% ==========================================================================
% 1. INPUT CONTRACT
%
%   {"kind":"square_area","area":30,"unit":"square units"}
%   {"kind":"root_bracket","radicand":52,"degree":2}
%   {"kind":"root_bracket","radicand":80,"degree":3}
%   {"kind":"number_class","numeral":"-3.4"}
%   {"kind":"rational_decimal","n":5,"d":8}
%   {"kind":"value_between","low":6,"high":8}
% ==========================================================================

g8_root_input_contract(
    '{\"kind\":\"square_area\",\"area\":\"number\",\"unit\":\"string\"}',
    '{\"kind\":\"square_area\",\"area\":30,\"unit\":\"square units\"}').

g8_root_from_json(Dict, square_area(Area, Unit)) :-
    is_dict(Dict), get_dict(kind, Dict, "square_area"), !,
    get_dict(area, Dict, A0), g8_quantity(A0, Area), Area > 0,
    ( get_dict(unit, Dict, U), string(U) -> Unit = U ; Unit = "square units" ).
g8_root_from_json(Dict, root_bracket(Radicand, Degree)) :-
    is_dict(Dict), get_dict(kind, Dict, "root_bracket"), !,
    get_dict(radicand, Dict, R0), get_dict(degree, Dict, Degree),
    memberchk(Degree, [2, 3]),
    g8_quantity(R0, Radicand),
    ( Degree =:= 2 -> Radicand >= 0 ; true ).
g8_root_from_json(Dict, number_class(Text, Value)) :-
    is_dict(Dict), get_dict(kind, Dict, "number_class"), !,
    get_dict(numeral, Dict, Text), string(Text),
    number_string(Number, Text), g8_quantity(Number, Value).
g8_root_from_json(Dict, rational_decimal(N, D)) :-
    is_dict(Dict), get_dict(kind, Dict, "rational_decimal"), !,
    get_dict(n, Dict, N0), get_dict(d, Dict, D0),
    integer(N0), integer(D0), D0 =\= 0, N = N0, D = D0.
g8_root_from_json(Dict, value_between(Low, High)) :-
    is_dict(Dict), get_dict(kind, Dict, "value_between"),
    get_dict(low, Dict, L0), get_dict(high, Dict, H0),
    g8_quantity(L0, Low), g8_quantity(H0, High), Low < High.

% ==========================================================================
% 2. STATES
% ==========================================================================

g8_root_states(
    [ q_read_the_area,
      q_name_the_side_as_a_root,
      q_search_for_a_whole_number_root,
      q_square_the_candidate_bounds,
      q_place_between_consecutive_whole_numbers,
      q_accept_exact_side_length,
      q_decide_perfect_power,
      q_exhibit_numerator_and_denominator,
      q_accept_rational,
      q_accept_irrational,
      q_divide_for_the_decimal,
      q_find_the_repeating_block ]).

% g8_root_state_label(State, Tradition, Label, Citation).
g8_root_state_label(q_name_the_side_as_a_root, illustrative_mathematics,
    "the exact side length of a square with that area",
    "IM Grade 8 Unit 8 Lesson 3, Rational and Irrational Numbers").
g8_root_state_label(q_name_the_side_as_a_root, van_de_walle,
    "the square root of the area",
    "Van de Walle, ch. 20, Square Roots").
g8_root_state_label(q_square_the_candidate_bounds, illustrative_mathematics,
    "squaring to see which whole numbers it falls between",
    "IM Grade 8 Unit 8 Lesson 6, Estimating Square Roots").
g8_root_state_label(q_place_between_consecutive_whole_numbers, ccss,
    "approximate irrational numbers by rational numbers",
    "CCSS 8.NS.A.2, via IM Grade 8 Unit 8 Lesson 6").
g8_root_state_label(q_decide_perfect_power, illustrative_mathematics,
    "a perfect square has a whole-number side",
    "IM Grade 8 Unit 8 Lesson 2, Side Lengths and Areas").
g8_root_state_label(q_accept_rational, ccss,
    "a number that can be written as a fraction of two integers",
    "CCSS 8.NS.A.1, via IM Grade 8 Unit 8 Lesson 4").
g8_root_state_label(q_accept_irrational, illustrative_mathematics,
    "a number that is not a fraction of two integers",
    "IM Grade 8 Unit 8 Lesson 4, Square Roots on the Number Line").
g8_root_state_label(q_divide_for_the_decimal, ccss,
    "the decimal expansion repeats eventually",
    "CCSS 8.NS.A.1, via IM Grade 8 Unit 8 Lesson 16").
g8_root_state_label(q_find_the_repeating_block, provisional,
    "the block of digits that repeats",
    "provisional; no community label sourced for this step").

% ==========================================================================
% 3. TRANSITIONS
% ==========================================================================

g8_root_transition(exact_side_length_from_square_area,
    q_read_the_area, name_the_side_as_a_root, q_name_the_side_as_a_root).
g8_root_transition(exact_side_length_from_square_area,
    q_name_the_side_as_a_root, search_for_a_whole_number_root,
    q_search_for_a_whole_number_root).
g8_root_transition(exact_side_length_from_square_area,
    q_search_for_a_whole_number_root, report_exact_side_length,
    q_accept_exact_side_length).
g8_root_transition(bracket_root_between_whole_numbers,
    q_read_the_area, square_the_candidate_bounds, q_square_the_candidate_bounds).
g8_root_transition(bracket_root_between_whole_numbers,
    q_square_the_candidate_bounds, place_between_consecutive_whole_numbers,
    q_place_between_consecutive_whole_numbers).
g8_root_transition(classify_number_as_rational_or_irrational,
    q_read_the_area, decide_perfect_power, q_decide_perfect_power).
g8_root_transition(classify_number_as_rational_or_irrational,
    q_decide_perfect_power, exhibit_numerator_and_denominator,
    q_exhibit_numerator_and_denominator).
g8_root_transition(classify_number_as_rational_or_irrational,
    q_exhibit_numerator_and_denominator, accept_rational, q_accept_rational).
g8_root_transition(classify_number_as_rational_or_irrational,
    q_decide_perfect_power, accept_irrational, q_accept_irrational).
g8_root_transition(decimal_representation_of_a_rational,
    q_read_the_area, divide_for_the_decimal, q_divide_for_the_decimal).
g8_root_transition(decimal_representation_of_a_rational,
    q_divide_for_the_decimal, find_the_repeating_block,
    q_find_the_repeating_block).
g8_root_transition(squares_between_two_whole_numbers,
    q_read_the_area, square_the_candidate_bounds, q_square_the_candidate_bounds).

% ==========================================================================
% 4. THE RUN
% ==========================================================================

run_g8_root(exact_side_length_from_square_area, square_area(Area, Unit),
            Outcome, Trace) :-
    g8_exact_root_text(Area, SideText),
    (   integer(Area), g8_integer_square_root(Area, Side)
    ->  Kind = whole_number_side, Squared is Side * Side
    ;   Kind = irrational_side, Squared = Area
    ),
    ( Squared =:= Area -> Validity = correct ; Validity = unvindicated ),
    Outcome = action_outcome(
        exact_side_length_from_square_area,
        [ classification(productive),
          cluster(g8_roots_and_number_class),
          automaton_state(q_accept_exact_side_length),
          vocabulary([square, area, side_length, square_root, exact_value,
                      perfect_square]),
          input(square_area(Area, Unit)),
          result(side_length(SideText)),
          expected(side_length(SideText)),
          side_kind(Kind),
          squared_back(Squared),
          invariant(the_side_squared_is_the_area),
          validity(Validity) ]),
    Trace = [ read_the_area(Area, Unit),
              name_the_side_as_a_root(SideText),
              search_for_a_whole_number_root(Kind),
              report_exact_side_length(SideText) ].
run_g8_root(bracket_root_between_whole_numbers, root_bracket(Radicand, Degree),
            Outcome, Trace) :-
    bracket(Radicand, Degree, Low, High, Exact),
    power(Low, Degree, LowPower),
    power(High, Degree, HighPower),
    (   Exact == exact
    ->  ( LowPower =:= Radicand -> Validity = correct
        ; Validity = unvindicated ),
        Answer = exact_whole_number(Low)
    ;   ( LowPower < Radicand, Radicand < HighPower, High =:= Low + 1
        -> Validity = correct ; Validity = unvindicated ),
        Answer = between(Low, High)
    ),
    Outcome = action_outcome(
        bracket_root_between_whole_numbers,
        [ classification(productive),
          cluster(g8_roots_and_number_class),
          automaton_state(q_place_between_consecutive_whole_numbers),
          vocabulary([square_root, cube_root, consecutive_whole_numbers,
                      estimate, perfect_square, perfect_cube]),
          input(root_bracket(Radicand, Degree)),
          result(Answer),
          expected(Answer),
          bounds(LowPower, HighPower),
          invariant(the_bounds_squared_straddle_the_radicand),
          validity(Validity) ]),
    Trace = [ read_the_radicand(Radicand, Degree),
              square_the_candidate_bounds(LowPower, HighPower),
              place_between_consecutive_whole_numbers(Answer) ].
run_g8_root(squares_between_two_whole_numbers, value_between(Low, High),
            Outcome, Trace) :-
    LowSquare is Low * Low,
    HighSquare is High * High,
    ( LowSquare < HighSquare -> Validity = correct ; Validity = unvindicated ),
    Outcome = action_outcome(
        squares_between_two_whole_numbers,
        [ classification(productive),
          cluster(g8_roots_and_number_class),
          automaton_state(q_square_the_candidate_bounds),
          vocabulary([square_root, between, bounds, squaring]),
          input(value_between(Low, High)),
          result(radicand_window(LowSquare, HighSquare)),
          expected(radicand_window(LowSquare, HighSquare)),
          invariant(the_bounds_squared_straddle_the_radicand),
          validity(Validity) ]),
    Trace = [ read_the_bounds(Low, High),
              square_the_candidate_bounds(LowSquare, HighSquare),
              report_the_radicand_window(LowSquare, HighSquare) ].
run_g8_root(classify_number_as_rational_or_irrational, number_class(Text, Value),
            Outcome, Trace) :-
    N is numerator(Value), D is denominator(Value),
    Rebuilt is N rdiv D,
    ( Rebuilt =:= Value -> Validity = correct ; Validity = unvindicated ),
    format(string(Witness), "~w/~w", [N, D]),
    Outcome = action_outcome(
        classify_number_as_rational_or_irrational,
        [ classification(productive),
          cluster(g8_roots_and_number_class),
          automaton_state(q_accept_rational),
          vocabulary([rational_number, irrational_number, numerator,
                      denominator, integer]),
          input(number_class(Text, Value)),
          result(rational(Witness)),
          expected(rational(Witness)),
          rebuilt(Rebuilt),
          invariant(a_rational_exhibits_its_fraction),
          validity(Validity) ]),
    Trace = [ read_the_numeral(Text),
              exhibit_numerator_and_denominator(N, D),
              accept_rational(Witness) ].
run_g8_root(classify_root_as_rational_or_irrational, root_bracket(Radicand, 2),
            Outcome, Trace) :-
    integer(Radicand), Radicand >= 0,
    (   g8_integer_square_root(Radicand, Root)
    ->  State = q_accept_rational,
        format(string(Witness), "~w/1", [Root]),
        Answer = rational(Witness),
        Step = accept_rational(Witness),
        Validity = correct
    ;   bracket(Radicand, 2, Low, High, _),
        LowSquare is Low * Low, HighSquare is High * High,
        State = q_accept_irrational,
        Answer = irrational(between_perfect_squares(LowSquare, HighSquare)),
        Step = accept_irrational(LowSquare, HighSquare),
        ( LowSquare < Radicand, Radicand < HighSquare
        -> Validity = correct ; Validity = unvindicated )
    ),
    Outcome = action_outcome(
        classify_root_as_rational_or_irrational,
        [ classification(productive),
          cluster(g8_roots_and_number_class),
          automaton_state(State),
          vocabulary([square_root, perfect_square, rational_number,
                      irrational_number]),
          input(root_bracket(Radicand, 2)),
          result(Answer),
          expected(Answer),
          invariant(a_root_is_rational_exactly_at_a_perfect_square),
          validity(Validity) ]),
    Trace = [ read_the_radicand(Radicand, 2),
              decide_perfect_power(Radicand),
              Step ].
run_g8_root(decimal_representation_of_a_rational, rational_decimal(N, D),
            Outcome, Trace) :-
    decimal_expansion(N, D, Text, Kind),
    Rebuilt is N rdiv D,
    Value is N rdiv D,
    ( Rebuilt =:= Value -> Validity = correct ; Validity = unvindicated ),
    Outcome = action_outcome(
        decimal_representation_of_a_rational,
        [ classification(productive),
          cluster(g8_roots_and_number_class),
          automaton_state(q_find_the_repeating_block),
          vocabulary([rational_number, decimal_representation, terminating,
                      repeating, long_division]),
          input(rational_decimal(N, D)),
          result(decimal(Text)),
          expected(decimal(Text)),
          expansion_kind(Kind),
          invariant(the_expansion_terminates_or_repeats),
          validity(Validity) ]),
    Trace = [ read_the_fraction(N, D),
              divide_for_the_decimal(Text),
              find_the_repeating_block(Kind) ].

%!  bracket(+Radicand, +Degree, -Low, -High, -Exact) is det.
%
%   The two consecutive whole numbers the root falls between, found by
%   raising candidates to the power. No root is ever taken numerically.
bracket(Radicand, Degree, Low, High, Exact) :-
    bracket_(0, Radicand, Degree, Low, High, Exact).

bracket_(N, Radicand, Degree, Low, High, Exact) :-
    power(N, Degree, P),
    (   P =:= Radicand
    ->  Low = N, High = N, Exact = exact
    ;   P > Radicand
    ->  Low is N - 1, High = N, Exact = strict
    ;   Next is N + 1,
        bracket_(Next, Radicand, Degree, Low, High, Exact)
    ).

power(N, 2, P) :- !, P is N * N.
power(N, 3, P) :- P is N * N * N.

%!  decimal_expansion(+N, +D, -Text, -Kind) is det.
%
%   Long division on exact integers. A remainder seen twice closes the
%   repeating block, so nothing is truncated or rounded.
decimal_expansion(N, D, Text, Kind) :-
    Sign is sign(N) * sign(D),
    A is abs(N), B is abs(D),
    Whole is A // B,
    Remainder is A mod B,
    (   Remainder =:= 0
    ->  Kind = terminating, Digits = "", Repeat = ""
    ;   long_divide(Remainder, B, [], Digits0, Repeat0),
        Digits = Digits0, Repeat = Repeat0,
        ( Repeat == "" -> Kind = terminating ; Kind = repeating )
    ),
    ( Sign < 0 -> Lead = "-" ; Lead = "" ),
    (   Digits == "", Repeat == ""
    ->  format(string(Text), "~w~w", [Lead, Whole])
    ;   Repeat == ""
    ->  format(string(Text), "~w~w.~w", [Lead, Whole, Digits])
    ;   format(string(Text), "~w~w.~w(~w)", [Lead, Whole, Digits, Repeat])
    ).

long_divide(Remainder, D, Seen, Digits, Repeat) :-
    long_divide_(Remainder, D, Seen, [], Digits, Repeat).

long_divide_(0, _, _, Acc, Digits, "") :- !,
    string_codes(Digits, Acc).
long_divide_(Remainder, D, Seen, Acc, Digits, Repeat) :-
    (   memberchk(Remainder-Position, Seen)
    ->  length(Acc, Length),
        Take is Position,
        Drop is Length - Position,
        length(Prefix, Take), append(Prefix, Cycle, Acc),
        string_codes(Digits, Prefix),
        length(Cycle, Drop),
        string_codes(Repeat, Cycle)
    ;   length(Acc, Position),
        Scaled is Remainder * 10,
        Digit is Scaled // D,
        Next is Scaled mod D,
        Code is Digit + 0'0,
        append(Acc, [Code], Acc1),
        long_divide_(Next, D, [Remainder-Position|Seen], Acc1, Digits, Repeat)
    ).

% ==========================================================================
% 5. SELF-SUMMARY
% ==========================================================================

g8_root_summary(
    summary{ module: g8_root_and_number_class,
             status: authored_pilot,
             generated: false,
             grade: 8,
             cluster: g8_roots_and_number_class,
             doings: [ exact_side_length_from_square_area,
                       bracket_root_between_whole_numbers,
                       squares_between_two_whole_numbers,
                       classify_number_as_rational_or_irrational,
                       classify_root_as_rational_or_irrational,
                       decimal_representation_of_a_rational ],
             verification: squaring_and_rebuilding_never_rooting,
             arithmetic: exact_rational_and_integer,
             deformation_partners: none_attested_at_this_locus,
             imported_by: none,
             extant_machines_left_untouched:
                 [ 'decimal/positional_decimal_reading' ] }).

% ==========================================================================
% 6. RECEIPTS
% ==========================================================================

g8_root_receipt(
    'im_defrag_ed49b622d9fdc7d161f218e8_1', 'IM-G8-U8-L3',
    exact_side_length_from_square_area,
    _{kind: "square_area", area: 100, unit: "square units"},
    side_length("10")).
g8_root_receipt(
    'im_defrag_ed49b622d9fdc7d161f218e8_1', 'IM-G8-U8-L3',
    exact_side_length_from_square_area,
    _{kind: "square_area", area: 95, unit: "square units"},
    side_length("sqrt(95)")).
g8_root_receipt(
    'im_defrag_ed49b622d9fdc7d161f218e8_1', 'IM-G8-U8-L3',
    exact_side_length_from_square_area,
    _{kind: "square_area", area: 36, unit: "square units"},
    side_length("6")).
g8_root_receipt(
    'im_defrag_ed49b622d9fdc7d161f218e8_1', 'IM-G8-U8-L3',
    exact_side_length_from_square_area,
    _{kind: "square_area", area: 30, unit: "square units"},
    side_length("sqrt(30)")).
g8_root_receipt(
    'im_defrag_ed49b622d9fdc7d161f218e8_1', 'IM-G8-U8-L3',
    bracket_root_between_whole_numbers,
    _{kind: "root_bracket", radicand: 95, degree: 2},
    between(9, 10)).
g8_root_receipt(
    'im_defrag_ed49b622d9fdc7d161f218e8_1', 'IM-G8-U8-L3',
    bracket_root_between_whole_numbers,
    _{kind: "root_bracket", radicand: 30, degree: 2},
    between(5, 6)).
g8_root_receipt(
    'im_defrag_de3818a3b055ad594f564834_1', 'IM-G8-U8-L2',
    % "a side length greater than 5 but less than 6" is an area window.
    squares_between_two_whole_numbers,
    _{kind: "value_between", low: 5, high: 6},
    radicand_window(25, 36)).
g8_root_receipt(
    'im_defrag_f6d10b87eb7627fd903ff73c_1', 'IM-G8-U8-L2',
    % Mai's estimate: an area between 70 and 80 has a side between 8 and 9.
    bracket_root_between_whole_numbers,
    _{kind: "root_bracket", radicand: 70, degree: 2},
    between(8, 9)).
g8_root_receipt(
    'im_defrag_f6d10b87eb7627fd903ff73c_1', 'IM-G8-U8-L2',
    bracket_root_between_whole_numbers,
    _{kind: "root_bracket", radicand: 80, degree: 2},
    between(8, 9)).
g8_root_receipt(
    'im_defrag_156ea4ae04dc56f743906c3d_1', 'IM-G8-U8-L6',
    % "greater than 6 and less than 8" is a radicand window of 36 to 64.
    squares_between_two_whole_numbers,
    _{kind: "value_between", low: 6, high: 8},
    radicand_window(36, 64)).
g8_root_receipt(
    'im_defrag_85edeb641252608948d2289d_1', 'IM-G8-U8-L16',
    classify_number_as_rational_or_irrational,
    _{kind: "number_class", numeral: "-3.4"},
    rational("-17/5")).
g8_root_receipt(
    'im_defrag_9475b9f5d9008b9758f21f59_1', 'IM-G8-U8-L3',
    % The side-and-area table: area 1, 4, 9, 16 against sides 0.5 to 3.5.
    exact_side_length_from_square_area,
    _{kind: "square_area", area: 16, unit: "square units"},
    side_length("4")).
g8_root_receipt(
    'im_defrag_9475b9f5d9008b9758f21f59_1', 'IM-G8-U8-L3',
    exact_side_length_from_square_area,
    _{kind: "square_area", area: 9, unit: "square units"},
    side_length("3")).
g8_root_receipt(
    'im_defrag_965909670b5bed500e89cb2f_1', 'IM-G8-U8-L16',
    decimal_representation_of_a_rational,
    _{kind: "rational_decimal", n: 1, d: 3},
    decimal("0.(3)")).
g8_root_receipt(
    'im_defrag_965909670b5bed500e89cb2f_1', 'IM-G8-U8-L16',
    decimal_representation_of_a_rational,
    _{kind: "rational_decimal", n: 5, d: 8},
    decimal("0.625")).

% Final round: the fold-in supplied IM-G8-U8-L15's three cube-root
% equations, printed in the figure as x^3 = 5, y^3 = 27, z^3 = 700.
g8_root_receipt(
    'im_defrag_2b394054d96217cd5a5c1413_1', 'IM-G8-U8-L15',
    bracket_root_between_whole_numbers,
    _{kind: "root_bracket", radicand: 5, degree: 3}, between(1, 2)).
g8_root_receipt(
    'im_defrag_2b394054d96217cd5a5c1413_1', 'IM-G8-U8-L15',
    bracket_root_between_whole_numbers,
    _{kind: "root_bracket", radicand: 27, degree: 3}, exact_whole_number(3)).
g8_root_receipt(
    'im_defrag_2b394054d96217cd5a5c1413_1', 'IM-G8-U8-L15',
    bracket_root_between_whole_numbers,
    _{kind: "root_bracket", radicand: 700, degree: 3}, between(8, 9)).

% ==========================================================================
% 7. CHECK
% ==========================================================================

check_g8_root_and_number_class :-
    check_receipts,
    check_irrationality_decided,
    check_cube_roots,
    check_negative,
    format('g8_root_and_number_class: all checks ok~n').

check_receipts :-
    findall(Lesson-Row-Doing-Result,
            ( g8_root_receipt(Row, Lesson, Doing, Json, Expected),
              g8_root_from_json(Json, Figure),
              run_g8_root(Doing, Figure, Outcome, _),
              outcome_property(Outcome, result(Result)),
              Result = Expected,
              outcome_property(Outcome, validity(correct))
            ), Rows),
    findall(R-L, g8_root_receipt(R, L, _, _, _), All),
    length(All, Total), length(Rows, Passed),
    Total =:= Passed,
    format('  receipts: ~w/~w real grade 8 rows run, each verified by squaring or rebuilding~n',
           [Passed, Total]),
    forall(member(Lesson-Row-Doing-Result, Rows),
           format('    ~w  ~w  ~w -> ~q~n', [Lesson, Row, Doing, Result])).

check_irrationality_decided :-
    % 36 is a perfect square, so its root is rational and exhibits 6/1.
    g8_root_from_json(_{kind: "root_bracket", radicand: 36, degree: 2}, A),
    run_g8_root(classify_root_as_rational_or_irrational, A, OA, _),
    outcome_property(OA, result(rational("6/1"))),
    % 30 is not, and the verdict carries the two perfect squares as witness.
    g8_root_from_json(_{kind: "root_bracket", radicand: 30, degree: 2}, B),
    run_g8_root(classify_root_as_rational_or_irrational, B, OB, _),
    outcome_property(OB, result(irrational(between_perfect_squares(25, 36)))),
    outcome_property(OB, validity(correct)),
    format('  irrationality: 36 gives a rational root exhibiting 6/1; 30 gives an irrational root witnessed between 25 and 36~n').

check_cube_roots :-
    % IM-G8-U8-L15 asks which integers a cube root lies between.
    g8_root_from_json(_{kind: "root_bracket", radicand: 80, degree: 3}, A),
    run_g8_root(bracket_root_between_whole_numbers, A, OA, _),
    outcome_property(OA, result(between(4, 5))),
    outcome_property(OA, bounds(64, 125)),
    g8_root_from_json(_{kind: "root_bracket", radicand: 27, degree: 3}, B),
    run_g8_root(bracket_root_between_whole_numbers, B, OB, _),
    outcome_property(OB, result(exact_whole_number(3))),
    format('  cube roots: 80 lands between 4 and 5 with bounds 64 and 125; 27 lands exactly on 3~n').

check_negative :-
    % A zero area has no square to name and refuses by contract.
    \+ g8_root_from_json(_{kind: "square_area", area: 0}, _),
    % A degree the pilot does not carry refuses rather than guessing.
    \+ g8_root_from_json(_{kind: "root_bracket", radicand: 16, degree: 4}, _),
    % A repeating expansion is never reported as terminating: 1/7 repeats
    % with a six-digit block, and the block is exact.
    g8_root_from_json(_{kind: "rational_decimal", n: 1, d: 7}, F),
    run_g8_root(decimal_representation_of_a_rational, F, O, _),
    outcome_property(O, result(decimal("0.(142857)"))),
    outcome_property(O, expansion_kind(repeating)),
    format('  negative tests: a zero area and a fourth root refuse; 1/7 comes back as 0.(142857), never truncated~n').

outcome_property(action_outcome(_, Props), Property) :-
    memberchk(Property, Props).
