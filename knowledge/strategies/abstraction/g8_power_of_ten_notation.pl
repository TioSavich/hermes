:- encoding(utf8).
/** <module> Grade 8 pilot: numerals as multiples of a power of ten
 *
 * WHAT THIS IS. A quarantined pilot automaton for the doing IM grade 8 unit 7
 * asks for from lesson 9 onward: rewrite a numeral as a multiple of a power of
 * ten, decide whether a given multiple is in scientific notation, put a
 * multiple back into ordinary decimal form, and multiply or divide two
 * multiples by combining their coefficients and adding or subtracting their
 * exponents.
 *
 * WHY IT IS NEW. `algebraic/exponent_as_repeated_factor` expands a power into
 * its factors, and `decimal/positional_decimal_reading` reads a numeral by its
 * places; neither writes a numeral as coefficient times a power of ten, and
 * neither reaches negative exponents. The magnitudes are also outside what the
 * grounded whole-number machines can enact: the 5,000 magnitude bound in
 * `hermes/encyclopedia.pl` refuses 300,000,000 before any strategy runs, and
 * the geometry volume machine returns a run failure on the 10,000-kilometre
 * cube of unit 7 lesson 3. This pilot works on the exponent instead of on a
 * tally, so those magnitudes cost nothing. It leaves every extant machine and
 * the magnitude bound untouched.
 *
 * VERIFICATION IS RECONSTRUCTION. Every rewrite reconstructs the original
 * numeral from its own coefficient and exponent in exact rational arithmetic
 * and reports whether the reconstruction is identical. Nothing is checked
 * against a float, so 0.0000000000003 and 300,000,000 are handled by the same
 * exact route.
 *
 * DEFORMATION PARTNER. One, attested in this repository's research corpus and
 * rendered at the notation locus: `write_the_exponent_without_its_sign`
 * follows db_row 38303 (Rabin, Fuller & Harel 2013, Journal of Mathematical
 * Behavior, pp. 653-654), where a student cannot accept that a negative
 * exponent yields a fractional value and expects a negative or alternating
 * result instead. The corpus attests the confusion about what a negative
 * exponent MEANS; this pilot renders it where a grade 8 task makes it
 * executable, in writing the notation, and is licensed only for numerals
 * below one, where the exponent is negative.
 *
 * QUARANTINE. Nothing imports this module; it renames nothing; its rows are
 * authored and vetoable one by one. Check: `check_g8_power_of_ten_notation/0`.
 */

:- module(g8_power_of_ten_notation,
          [ run_g8_power_of_ten/4,
            g8_power_of_ten_from_json/2,
            g8_power_of_ten_states/1,
            g8_power_of_ten_state_label/4,
            g8_power_of_ten_summary/1,
            g8_power_of_ten_receipt/5,
            check_g8_power_of_ten_notation/0
          ]).

:- use_module(strategies('abstraction/g8_quantity_input'),
              [ g8_quantity/2, g8_decimal_text/2 ]).

% ==========================================================================
% 1. INPUT CONTRACT
%
%   {"kind":"power_of_ten_numeral","numeral":"0.000000123"}
%   {"kind":"power_of_ten_multiple","coefficient":4.82,"exponent":4}
%   {"kind":"power_of_ten_product","left":{"coefficient":3,"exponent":8},
%    "right":{"coefficient":2,"exponent":-3},"operation":"multiply"}
%
% A numeral arrives as a STRING so its written form survives: "0.00034" and
% "0.000340" are the same quantity but not the same numeral, and a float would
% lose the difference before the automaton could refuse it.
% ==========================================================================

g8_power_of_ten_input_contract(
    '{\"kind\":\"power_of_ten_numeral\",\"numeral\":\"string\"}',
    '{\"kind\":\"power_of_ten_numeral\",\"numeral\":\"0.000000123\"}').

g8_power_of_ten_from_json(Dict, numeral(Text, Value)) :-
    is_dict(Dict),
    get_dict(kind, Dict, "power_of_ten_numeral"), !,
    get_dict(numeral, Dict, Text),
    string(Text),
    exact_numeral(Text, Value),
    Value =\= 0.
g8_power_of_ten_from_json(Dict, multiple(Coefficient, Exponent)) :-
    is_dict(Dict),
    get_dict(kind, Dict, "power_of_ten_multiple"), !,
    get_dict(coefficient, Dict, C0), get_dict(exponent, Dict, Exponent),
    integer(Exponent),
    g8_quantity(C0, Coefficient),
    Coefficient =\= 0.
g8_power_of_ten_from_json(Dict, product(Operation, multiple(C1, E1),
                                        multiple(C2, E2))) :-
    is_dict(Dict),
    get_dict(kind, Dict, "power_of_ten_product"),
    get_dict(operation, Dict, OperationText),
    memberchk(OperationText, ["multiply", "divide"]),
    atom_string(Operation, OperationText),
    get_dict(left, Dict, Left), get_dict(right, Dict, Right),
    get_dict(coefficient, Left, L0), get_dict(exponent, Left, E1),
    get_dict(coefficient, Right, R0), get_dict(exponent, Right, E2),
    integer(E1), integer(E2),
    g8_quantity(L0, C1), g8_quantity(R0, C2),
    C1 =\= 0, C2 =\= 0.

%!  exact_numeral(+Text, -Rational) is semidet.
%
%   Read a written decimal numeral as an exact rational by its own digits.
%   No float appears, so 0.0000000000003 is exact rather than nearly right.
exact_numeral(Text, Rational) :-
    split_string(Text, ",", "", Parts),
    atomic_list_concat(Parts, Joined0),
    atom_string(Joined0, Joined),
    (   split_string(Joined, ".", "", [Whole, Fraction]), Fraction \== ""
    ->  string_length(Fraction, Places),
        number_string(WholePart, Whole),
        number_string(FractionPart, Fraction),
        Scale is 10 ^ Places,
        Magnitude is abs(WholePart) * Scale + FractionPart,
        ( sub_string(Whole, 0, _, _, "-")
        -> Rational is -(Magnitude rdiv Scale)
        ;  Rational is Magnitude rdiv Scale )
    ;   number_string(Rational, Joined),
        integer(Rational)
    ).

% ==========================================================================
% 2. STATES
% ==========================================================================

g8_power_of_ten_states(
    [ q_read_the_numeral,
      q_locate_the_leading_nonzero_digit,
      q_count_the_place_shifts,
      q_write_the_coefficient_between_one_and_ten,
      q_write_the_power_of_ten,
      q_verify_by_reconstruction,
      q_accept_scientific_notation,
      q_reject_scientific_notation,
      q_combine_coefficients,
      q_add_or_subtract_exponents,
      q_write_the_exponent_without_its_sign ]).

% g8_power_of_ten_state_label(State, Tradition, Label, Citation).
g8_power_of_ten_state_label(q_locate_the_leading_nonzero_digit,
    illustrative_mathematics,
    "the first digit that is not zero",
    "IM Grade 8 Unit 7 Lesson 11, Multiplying and Dividing by Powers of 10").
g8_power_of_ten_state_label(q_count_the_place_shifts, illustrative_mathematics,
    "how many places the digits move",
    "IM Grade 8 Unit 7 Lesson 10, Multiplying and Dividing Numbers").
g8_power_of_ten_state_label(q_write_the_coefficient_between_one_and_ten,
    illustrative_mathematics,
    "a number at least 1 and less than 10",
    "IM Grade 8 Unit 7 Lesson 13, Definition of Scientific Notation").
g8_power_of_ten_state_label(q_write_the_coefficient_between_one_and_ten,
    van_de_walle,
    "the significand in scientific notation",
    "Van de Walle, ch. 16, Very Large and Very Small Numbers").
g8_power_of_ten_state_label(q_write_the_power_of_ten, ccss,
    "a single digit times an integer power of 10",
    "CCSS 8.EE.A.3, via IM Grade 8 Unit 7").
g8_power_of_ten_state_label(q_verify_by_reconstruction, provisional,
    "rebuild the numeral from the notation",
    "provisional; no community label sourced for this checking step").
g8_power_of_ten_state_label(q_add_or_subtract_exponents,
    illustrative_mathematics,
    "adding exponents when multiplying powers of 10",
    "IM Grade 8 Unit 7 Lesson 4, Dividing Powers of 10").
g8_power_of_ten_state_label(q_write_the_exponent_without_its_sign, rabin,
    "the negative exponent not accepted as a fractional value",
    "db_row 38303; Rabin, Fuller & Harel 2013, Journal of Mathematical Behavior, pp. 653-654").

% ==========================================================================
% 3. TRANSITIONS
% ==========================================================================

g8_power_of_ten_transition(numeral_as_multiple_of_a_power_of_ten,
    q_read_the_numeral, find_the_leading_nonzero_digit,
    q_locate_the_leading_nonzero_digit).
g8_power_of_ten_transition(numeral_as_multiple_of_a_power_of_ten,
    q_locate_the_leading_nonzero_digit, count_the_places_to_the_ones_place,
    q_count_the_place_shifts).
g8_power_of_ten_transition(numeral_as_multiple_of_a_power_of_ten,
    q_count_the_place_shifts, write_the_coefficient,
    q_write_the_coefficient_between_one_and_ten).
g8_power_of_ten_transition(numeral_as_multiple_of_a_power_of_ten,
    q_write_the_coefficient_between_one_and_ten, write_the_power_of_ten,
    q_write_the_power_of_ten).
g8_power_of_ten_transition(numeral_as_multiple_of_a_power_of_ten,
    q_write_the_power_of_ten, rebuild_the_numeral, q_verify_by_reconstruction).
g8_power_of_ten_transition(numeral_as_multiple_of_a_power_of_ten,
    q_verify_by_reconstruction, report_scientific_notation,
    q_accept_scientific_notation).
g8_power_of_ten_transition(test_multiple_for_scientific_notation,
    q_read_the_numeral, compare_the_coefficient_with_one_and_ten,
    q_write_the_coefficient_between_one_and_ten).
g8_power_of_ten_transition(test_multiple_for_scientific_notation,
    q_write_the_coefficient_between_one_and_ten, accept_scientific_notation,
    q_accept_scientific_notation).
g8_power_of_ten_transition(test_multiple_for_scientific_notation,
    q_write_the_coefficient_between_one_and_ten, reject_scientific_notation,
    q_reject_scientific_notation).
g8_power_of_ten_transition(combine_multiples_of_powers_of_ten,
    q_read_the_numeral, multiply_or_divide_the_coefficients,
    q_combine_coefficients).
g8_power_of_ten_transition(combine_multiples_of_powers_of_ten,
    q_combine_coefficients, add_or_subtract_the_exponents,
    q_add_or_subtract_exponents).
g8_power_of_ten_transition(combine_multiples_of_powers_of_ten,
    q_add_or_subtract_exponents, rebuild_the_numeral,
    q_verify_by_reconstruction).
g8_power_of_ten_transition(write_the_exponent_without_its_sign,
    q_count_the_place_shifts, drop_the_minus_sign,
    q_write_the_exponent_without_its_sign).

% ==========================================================================
% 4. THE RUN
% ==========================================================================

run_g8_power_of_ten(numeral_as_multiple_of_a_power_of_ten,
                    numeral(Text, Value), Outcome, Trace) :-
    normalise(Value, Coefficient, Exponent),
    ten_power(Exponent, Power), Rebuilt is Coefficient * Power,
    ( Rebuilt =:= Value -> Reconstruction = identical
    ; Reconstruction = differs ),
    ( Reconstruction == identical -> Validity = correct
    ; Validity = unvindicated ),
    g8_decimal_text(Coefficient, CoefficientText),
    notation_text(Coefficient, Exponent, Notation),
    Outcome = action_outcome(
        numeral_as_multiple_of_a_power_of_ten,
        [ classification(productive),
          cluster(g8_exponents_and_scientific_notation),
          automaton_state(q_accept_scientific_notation),
          vocabulary([numeral, place_value, power_of_ten, exponent,
                      coefficient, scientific_notation]),
          input(numeral(Text, Value)),
          result(scientific_notation(Notation)),
          expected(scientific_notation(Notation)),
          coefficient(CoefficientText),
          exponent(Exponent),
          reconstruction(Reconstruction),
          invariant(the_notation_rebuilds_the_numeral),
          validity(Validity) ]),
    Trace = [ read_the_numeral(Text),
              find_the_leading_nonzero_digit,
              count_the_places_to_the_ones_place(Exponent),
              write_the_coefficient(CoefficientText),
              write_the_power_of_ten(Exponent),
              rebuild_the_numeral(Reconstruction),
              report_scientific_notation(Notation) ].
run_g8_power_of_ten(test_multiple_for_scientific_notation,
                    multiple(Coefficient, Exponent), Outcome, Trace) :-
    Magnitude is abs(Coefficient),
    (   Magnitude >= 1, Magnitude < 10
    ->  State = q_accept_scientific_notation, Answer = in_scientific_notation,
        Step = accept_scientific_notation,
        notation_text(Coefficient, Exponent, Rewritten)
    ;   State = q_reject_scientific_notation,
        Answer = not_in_scientific_notation,
        Step = reject_scientific_notation,
        ten_power(Exponent, Power), Value is Coefficient * Power,
        normalise(Value, NewCoefficient, NewExponent),
        notation_text(NewCoefficient, NewExponent, Rewritten)
    ),
    Outcome = action_outcome(
        test_multiple_for_scientific_notation,
        [ classification(productive),
          cluster(g8_exponents_and_scientific_notation),
          automaton_state(State),
          vocabulary([coefficient, power_of_ten, exponent,
                      scientific_notation]),
          input(multiple(Coefficient, Exponent)),
          result(Answer),
          expected(Answer),
          rewritten(Rewritten),
          invariant(the_coefficient_is_at_least_one_and_below_ten),
          validity(correct) ]),
    Trace = [ compare_the_coefficient_with_one_and_ten(Coefficient),
              Step,
              report_scientific_notation(Rewritten) ].
run_g8_power_of_ten(combine_multiples_of_powers_of_ten,
                    product(Operation, multiple(C1, E1), multiple(C2, E2)),
                    Outcome, Trace) :-
    ( Operation == multiply
    -> Coefficient0 is C1 * C2, Exponent0 is E1 + E2
    ;  Coefficient0 is C1 rdiv C2, Exponent0 is E1 - E2 ),
    ten_power(Exponent0, Power0), Value is Coefficient0 * Power0,
    normalise(Value, Coefficient, Exponent),
    ten_power(Exponent, Power), Rebuilt is Coefficient * Power,
    ( Rebuilt =:= Value -> Reconstruction = identical
    ; Reconstruction = differs ),
    ( Reconstruction == identical -> Validity = correct
    ; Validity = unvindicated ),
    notation_text(Coefficient, Exponent, Notation),
    Outcome = action_outcome(
        combine_multiples_of_powers_of_ten,
        [ classification(productive),
          cluster(g8_exponents_and_scientific_notation),
          automaton_state(q_add_or_subtract_exponents),
          vocabulary([coefficient, power_of_ten, exponent, product, quotient,
                      scientific_notation]),
          input(product(Operation, multiple(C1, E1), multiple(C2, E2))),
          result(scientific_notation(Notation)),
          expected(scientific_notation(Notation)),
          exponent(Exponent),
          reconstruction(Reconstruction),
          invariant(the_notation_rebuilds_the_numeral),
          validity(Validity) ]),
    Trace = [ multiply_or_divide_the_coefficients(Operation, Coefficient0),
              add_or_subtract_the_exponents(Exponent0),
              rebuild_the_numeral(Reconstruction),
              report_scientific_notation(Notation) ].
run_g8_power_of_ten(write_the_exponent_without_its_sign,
                    numeral(Text, Value), Outcome, Trace) :-
    % Attested locus: a numeral below one, where the exponent is negative.
    abs(Value) < 1,
    normalise(Value, Coefficient, Exponent),
    Exponent < 0,
    Deformed is -Exponent,
    notation_text(Coefficient, Exponent, Productive),
    notation_text(Coefficient, Deformed, DeformedNotation),
    ten_power(Deformed, DeformedPower), Rebuilt is Coefficient * DeformedPower,
    ( Rebuilt =\= Value -> Validity = incorrect ; Validity = unvindicated ),
    Outcome = action_outcome(
        write_the_exponent_without_its_sign,
        [ classification(deformation),
          cluster(g8_exponents_and_scientific_notation),
          automaton_state(q_write_the_exponent_without_its_sign),
          vocabulary([negative_exponent, power_of_ten, coefficient,
                      scientific_notation]),
          input(numeral(Text, Value)),
          expected(scientific_notation(Productive)),
          result(scientific_notation(DeformedNotation)),
          reconstruction(differs),
          deformation_of(numeral_as_multiple_of_a_power_of_ten),
          violated_invariant(the_notation_rebuilds_the_numeral),
          attested_as(db_row(38303),
                      "Rabin, Fuller & Harel 2013, Journal of Mathematical Behavior, pp. 653-654"),
          validity(Validity) ]),
    Trace = [ read_the_numeral(Text),
              count_the_places_to_the_ones_place(Exponent),
              drop_the_minus_sign(Deformed) ].

%!  normalise(+Value, -Coefficient, -Exponent) is det.
%
%   Shift the value by whole powers of ten until its magnitude lies in
%   [1, 10). Exact throughout: the shift multiplies or divides by 10.
normalise(Value, Coefficient, Exponent) :-
    normalise_(Value, 0, Coefficient, Exponent).

normalise_(Value, Shift, Coefficient, Exponent) :-
    Magnitude is abs(Value),
    (   Magnitude >= 10
    ->  Next is Value rdiv 10, Deeper is Shift + 1,
        normalise_(Next, Deeper, Coefficient, Exponent)
    ;   Magnitude < 1
    ->  Next is Value * 10, Deeper is Shift - 1,
        normalise_(Next, Deeper, Coefficient, Exponent)
    ;   Coefficient = Value, Exponent = Shift
    ).

%!  ten_power(+Exponent, -Power) is det.
%
%   An EXACT power of ten. SWI evaluates 10 ^ -13 as a float, and a float
%   would decide the reconstruction check by rounding; the negative case
%   therefore goes through a rational reciprocal instead.
ten_power(Exponent, Power) :-
    (   Exponent >= 0
    ->  Power is 10 ^ Exponent
    ;   Magnitude is -Exponent,
        Power is 1 rdiv (10 ^ Magnitude)
    ).

notation_text(Coefficient, Exponent, Text) :-
    g8_decimal_text(Coefficient, CoefficientText),
    format(string(Text), "~w x 10^~w", [CoefficientText, Exponent]).

% ==========================================================================
% 5. SELF-SUMMARY
% ==========================================================================

g8_power_of_ten_summary(
    summary{ module: g8_power_of_ten_notation,
             status: authored_pilot,
             generated: false,
             grade: 8,
             cluster: g8_exponents_and_scientific_notation,
             doings: [ numeral_as_multiple_of_a_power_of_ten,
                       test_multiple_for_scientific_notation,
                       combine_multiples_of_powers_of_ten,
                       write_the_exponent_without_its_sign ],
             verification: rebuild_the_numeral_from_its_own_notation,
             arithmetic: exact_rational,
             magnitude_bound: none_needed_the_exponent_carries_the_size,
             imported_by: none,
             extant_machines_left_untouched:
                 [ 'algebraic/exponent_as_repeated_factor',
                   'decimal/positional_decimal_reading' ] }).

% ==========================================================================
% 6. RECEIPTS
% ==========================================================================

g8_power_of_ten_receipt(
    'im_defrag_de2361d67e3d069782820ab5_1', 'IM-G8-U7-L9',
    numeral_as_multiple_of_a_power_of_ten,
    _{kind: "power_of_ten_numeral", numeral: "0.000000123"},
    scientific_notation("1.23 x 10^-7")).
g8_power_of_ten_receipt(
    'im_defrag_de2361d67e3d069782820ab5_1', 'IM-G8-U7-L9',
    numeral_as_multiple_of_a_power_of_ten,
    _{kind: "power_of_ten_numeral", numeral: "123000000"},
    scientific_notation("1.23 x 10^8")).
g8_power_of_ten_receipt(
    'im_defrag_00395cb3f7caf95af823a74f_1', 'IM-G8-U7-L11',
    numeral_as_multiple_of_a_power_of_ten,
    _{kind: "power_of_ten_numeral", numeral: "0.00034"},
    scientific_notation("3.4 x 10^-4")).
g8_power_of_ten_receipt(
    'im_defrag_aaffae33b837517c05f98292_1', 'IM-G8-U7-L11',
    numeral_as_multiple_of_a_power_of_ten,
    _{kind: "power_of_ten_numeral", numeral: "0.0000000000003"},
    scientific_notation("3 x 10^-13")).
g8_power_of_ten_receipt(
    'im_defrag_ae85b187bdae0b9ebc9c93b8_1', 'IM-G8-U7-L13',
    numeral_as_multiple_of_a_power_of_ten,
    _{kind: "power_of_ten_numeral", numeral: "300000000"},
    scientific_notation("3 x 10^8")).
g8_power_of_ten_receipt(
    'im_defrag_ae85b187bdae0b9ebc9c93b8_1', 'IM-G8-U7-L13',
    numeral_as_multiple_of_a_power_of_ten,
    _{kind: "power_of_ten_numeral", numeral: "280000000"},
    scientific_notation("2.8 x 10^8")).
g8_power_of_ten_receipt(
    'im_defrag_1557bd8afec1b193797737c0_1', 'IM-G8-U7-L13',
    numeral_as_multiple_of_a_power_of_ten,
    _{kind: "power_of_ten_numeral", numeral: "48,200"},
    scientific_notation("4.82 x 10^4")).
g8_power_of_ten_receipt(
    'im_defrag_1557bd8afec1b193797737c0_1', 'IM-G8-U7-L13',
    numeral_as_multiple_of_a_power_of_ten,
    _{kind: "power_of_ten_numeral", numeral: "0.00099"},
    scientific_notation("9.9 x 10^-4")).
g8_power_of_ten_receipt(
    'im_defrag_3b82ceedfb7a28535eff28d4_1', 'IM-G8-U7-L3',
    numeral_as_multiple_of_a_power_of_ten,
    _{kind: "power_of_ten_numeral", numeral: "10000"},
    scientific_notation("1 x 10^4")).
g8_power_of_ten_receipt(
    'im_defrag_3b82ceedfb7a28535eff28d4_1', 'IM-G8-U7-L3',
    % The same row's giant cube: 10,000 km on each side, so 10^12 cubic km.
    combine_multiples_of_powers_of_ten,
    _{kind: "power_of_ten_product", operation: "multiply",
      left: _{coefficient: 1, exponent: 8},
      right: _{coefficient: 1, exponent: 4}},
    scientific_notation("1 x 10^12")).
g8_power_of_ten_receipt(
    'im_defrag_6f77bf357e9b82f4d33b9ab1_1', 'IM-G8-U7-L16',
    numeral_as_multiple_of_a_power_of_ten,
    _{kind: "power_of_ten_numeral", numeral: "1000000000000"},
    scientific_notation("1 x 10^12")).

% Final round: the fold-in supplied IM-G8-U7-L10's number line, running
% from 0 to 10^7, and the row's own first number to place on it.
g8_power_of_ten_receipt(
    'im_defrag_e999385944a6b6c2d2bfc76c_1', 'IM-G8-U7-L10',
    numeral_as_multiple_of_a_power_of_ten,
    _{kind: "power_of_ten_numeral", numeral: "4,000,000"},
    scientific_notation("4 x 10^6")).
g8_power_of_ten_receipt(
    'im_defrag_e999385944a6b6c2d2bfc76c_1', 'IM-G8-U7-L10',
    numeral_as_multiple_of_a_power_of_ten,
    _{kind: "power_of_ten_numeral", numeral: "10000000"},
    scientific_notation("1 x 10^7")).

% ==========================================================================
% 7. CHECK
% ==========================================================================

check_g8_power_of_ten_notation :-
    check_receipts,
    check_scientific_notation_test,
    check_attested_deformation,
    check_negative,
    format('g8_power_of_ten_notation: all checks ok~n').

check_receipts :-
    findall(Lesson-Row-Result,
            ( g8_power_of_ten_receipt(Row, Lesson, Doing, Json, Expected),
              g8_power_of_ten_from_json(Json, Figure),
              run_g8_power_of_ten(Doing, Figure, Outcome, _),
              outcome_property(Outcome, result(Result)),
              Result = Expected,
              outcome_property(Outcome, reconstruction(identical)),
              outcome_property(Outcome, validity(correct))
            ), Rows),
    findall(R-L, g8_power_of_ten_receipt(R, L, _, _, _), All),
    length(All, Total), length(Rows, Passed),
    Total =:= Passed,
    format('  receipts: ~w/~w real grade 8 rows rewritten, each rebuilding its own numeral exactly~n',
           [Passed, Total]),
    forall(member(Lesson-Row-Result, Rows),
           format('    ~w  ~w  ~q~n', [Lesson, Row, Result])).

check_scientific_notation_test :-
    % IM-G8-U7-L13 section(4) asks which numbers are in scientific notation.
    g8_power_of_ten_from_json(
        _{kind: "power_of_ten_multiple", coefficient: 4.82, exponent: 4}, M1),
    run_g8_power_of_ten(test_multiple_for_scientific_notation, M1, O1, _),
    outcome_property(O1, result(in_scientific_notation)),
    g8_power_of_ten_from_json(
        _{kind: "power_of_ten_multiple", coefficient: 48.2, exponent: 3}, M2),
    run_g8_power_of_ten(test_multiple_for_scientific_notation, M2, O2, _),
    outcome_property(O2, result(not_in_scientific_notation)),
    outcome_property(O2, rewritten("4.82 x 10^4")),
    format('  notation test: 4.82 x 10^4 is admitted and 48.2 x 10^3 is rejected and rewritten to the same value~n').

check_attested_deformation :-
    % db_row 38303 at the notation locus: 0.00034 written with exponent 4.
    g8_power_of_ten_from_json(
        _{kind: "power_of_ten_numeral", numeral: "0.00034"}, N),
    run_g8_power_of_ten(write_the_exponent_without_its_sign, N, O, _),
    outcome_property(O, result(scientific_notation("3.4 x 10^4"))),
    outcome_property(O, expected(scientific_notation("3.4 x 10^-4"))),
    outcome_property(O, validity(incorrect)),
    format('  attested deformation: db_row 38303 writes 0.00034 with exponent 4 rather than -4~n').

check_negative :-
    % The sign-dropping deformation refuses at or above one, where the
    % exponent is not negative and there is no sign to drop.
    g8_power_of_ten_from_json(
        _{kind: "power_of_ten_numeral", numeral: "48200"}, N),
    \+ run_g8_power_of_ten(write_the_exponent_without_its_sign, N, _, _),
    % Zero has no leading non-zero digit; the contract refuses it.
    \+ g8_power_of_ten_from_json(
           _{kind: "power_of_ten_numeral", numeral: "0"}, _),
    % A magnitude far above the grounded 5,000 bound still rebuilds exactly.
    g8_power_of_ten_from_json(
        _{kind: "power_of_ten_numeral", numeral: "300000000"}, Big),
    run_g8_power_of_ten(numeral_as_multiple_of_a_power_of_ten, Big, OB, _),
    outcome_property(OB, reconstruction(identical)),
    format('  negative tests: the sign-dropping deformation refuses at or above one, zero refuses, and 300,000,000 rebuilds exactly~n').

outcome_property(action_outcome(_, Props), Property) :-
    memberchk(Property, Props).
