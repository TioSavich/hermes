:- encoding(utf8).
/** <module> Grade 8 draft: adding and ordering multiples of powers of ten
 *
 * WHAT THIS IS. A draft automaton for the two acts the published pilot
 * `g8_power_of_ten_notation` does not carry. That pilot multiplies and
 * divides multiples of powers of ten, where the exponents simply add or
 * subtract and no alignment is needed. The corrected grade 8 unit 7 tasks ask
 * for something else: (2.3 × 10^5) + (3.6 × 10^6) in correction 100,
 * 4 · 10^-4 + 5 · 10^-3 + 2 · 10^-2 in correction 123, "which travels faster,
 * light through diamond at 124 · 10^6 or light through ice at 2.3 · 10^8" in
 * correction 96, "which creature is least numerous" in correction 99. Adding
 * and comparing both need the SAME act the multiplying does not: bringing two
 * multiples to a shared power before the coefficients may be read against
 * each other.
 *
 * THE ALIGNMENT IS THE DOING. Every run rewrites each multiple over the
 * lowest power present, so the coefficients become whole-number-scaled and
 * comparable, and only then adds or orders. The trace names the shared power,
 * so a reader can follow what was aligned to what rather than being handed a
 * total.
 *
 * DEFORMATION PARTNER, PRINTED IN THE CURRICULUM. Correction 100 is Elena's
 * work: (2.3 × 10^5) + (3.6 × 10^6) = 5.9 × 10^6. The coefficients are added
 * and the larger power is carried along, which is exactly the act of adding
 * without aligning. The lesson prints it and asks a student to explain the
 * mistake, so the attestation is the curriculum's own. The research corpus
 * carries a neighbouring row at 40416 about failing to align decimal points
 * when adding decimals; it is a neighbour and not the same claim, and is
 * cited as such.
 *
 * EXACT THROUGHOUT. A coefficient arrives as a printed decimal and becomes an
 * exact rational at decode, so 2.3 × 10^5 + 3.6 × 10^6 is 383/100 × 10^6 and
 * not a float that nearly is.
 *
 * QUARANTINE. Nothing imports this module; it is a draft under
 * `.superpowers/sdd/g8-round2/`. Check: `check_g8_power_of_ten_alignment/0`.
 */

:- module(g8_power_of_ten_alignment,
          [ run_g8_power_of_ten_alignment/4,
            g8_alignment_from_json/2,
            g8_alignment_states/1,
            g8_alignment_state_label/4,
            g8_alignment_summary/1,
            g8_alignment_receipt/5,
            check_g8_power_of_ten_alignment/0
          ]).

:- use_module(strategies('abstraction/g8_quantity_input'),
              [ g8_quantity/2, g8_rational_text/2, g8_decimal_text/2 ]).

% ==========================================================================
% 1. INPUT CONTRACT
%
%   {"kind":"multiples_of_powers_of_ten",
%    "multiples":[{"label":"Elena's first","coefficient":2.3,"exponent":5},
%                 {"label":"Elena's second","coefficient":3.6,"exponent":6}]}
%
% A label is optional and defaults to the multiple's own written form.
% ==========================================================================

g8_alignment_input_contract(
    '{\"kind\":\"multiples_of_powers_of_ten\",\"multiples\":[{\"label\":\"string\",\"coefficient\":\"number\",\"exponent\":\"integer\"}]}',
    '{\"kind\":\"multiples_of_powers_of_ten\",\"multiples\":[{\"coefficient\":2.3,\"exponent\":5},{\"coefficient\":3.6,\"exponent\":6}]}').

g8_alignment_from_json(Dict, multiples(List)) :-
    is_dict(Dict),
    get_dict(kind, Dict, "multiples_of_powers_of_ten"),
    get_dict(multiples, Dict, Raw),
    Raw = [_, _|_],
    maplist(multiple_of, Raw, List).

multiple_of(Dict, multiple(Label, Coefficient, Exponent)) :-
    get_dict(coefficient, Dict, C0), g8_quantity(C0, Coefficient),
    get_dict(exponent, Dict, Exponent), integer(Exponent),
    (   get_dict(label, Dict, L), string(L)
    ->  Label = L
    ;   written_form(Coefficient, Exponent, Label)
    ).

% The coefficient is written as the curriculum writes it: a decimal where the
% denominator allows one, following the published pilot's own rendering.
written_form(Coefficient, Exponent, Text) :-
    g8_decimal_text(Coefficient, CoefficientText),
    format(atom(A), '~w x 10^~w', [CoefficientText, Exponent]),
    atom_string(A, Text).

% ==========================================================================
% 2. STATES
% ==========================================================================

g8_alignment_states(
    [ q_read_the_multiples,
      q_find_the_lowest_power_present,
      q_rewrite_each_multiple_over_the_shared_power,
      q_add_the_aligned_coefficients,
      q_report_the_total_as_a_multiple,
      q_place_the_multiples_in_order,
      q_name_the_larger_multiple,
      q_add_the_coefficients_and_keep_the_larger_power ]).

% g8_alignment_state_label(State, Tradition, Label, Citation).
g8_alignment_state_label(q_find_the_lowest_power_present,
    illustrative_mathematics,
    "writing both numbers as multiples of the same power of 10",
    "IM Grade 8 Unit 7 Lesson 15, Adding and Subtracting with Scientific Notation").
g8_alignment_state_label(q_rewrite_each_multiple_over_the_shared_power, ccss,
    "perform operations with numbers expressed in scientific notation",
    "CCSS 8.EE.A.4, via IM Grade 8 Unit 7 Lesson 15").
g8_alignment_state_label(q_place_the_multiples_in_order,
    illustrative_mathematics,
    "comparing quantities written as multiples of powers of 10",
    "IM Grade 8 Unit 7 Lesson 10, Multiplying by Powers of 10, the speed-of-light table").
g8_alignment_state_label(q_add_the_aligned_coefficients, van_de_walle,
    "like units are added to like units",
    "Van de Walle, ch. 11, place value and the meaning of a digit's position").
g8_alignment_state_label(q_report_the_total_as_a_multiple, provisional,
    "the total written back as one multiple of a power of ten",
    "provisional; no community label sourced for the write-back step").
g8_alignment_state_label(q_add_the_coefficients_and_keep_the_larger_power,
    illustrative_mathematics,
    "Elena's move: the coefficients added and the larger power carried along",
    "IM Grade 8 Unit 7 Lesson 15, printed in the lesson as Elena's work").

% ==========================================================================
% 3. TRANSITIONS
% ==========================================================================

g8_alignment_transition(add_multiples_of_powers_of_ten,
    q_read_the_multiples, find_the_lowest_power_present,
    q_find_the_lowest_power_present).
g8_alignment_transition(add_multiples_of_powers_of_ten,
    q_find_the_lowest_power_present, rewrite_each_multiple_over_the_shared_power,
    q_rewrite_each_multiple_over_the_shared_power).
g8_alignment_transition(add_multiples_of_powers_of_ten,
    q_rewrite_each_multiple_over_the_shared_power, add_the_aligned_coefficients,
    q_add_the_aligned_coefficients).
g8_alignment_transition(add_multiples_of_powers_of_ten,
    q_add_the_aligned_coefficients, report_the_total_as_a_multiple,
    q_report_the_total_as_a_multiple).
g8_alignment_transition(compare_multiples_of_powers_of_ten,
    q_rewrite_each_multiple_over_the_shared_power, name_the_larger_multiple,
    q_name_the_larger_multiple).
g8_alignment_transition(order_multiples_of_powers_of_ten,
    q_rewrite_each_multiple_over_the_shared_power, place_the_multiples_in_order,
    q_place_the_multiples_in_order).
g8_alignment_transition(add_the_coefficients_without_aligning_the_powers,
    q_read_the_multiples, add_the_coefficients_and_keep_the_larger_power,
    q_add_the_coefficients_and_keep_the_larger_power).

% ==========================================================================
% 4. THE RUN
% ==========================================================================

run_g8_power_of_ten_alignment(add_multiples_of_powers_of_ten, multiples(List),
                              Outcome, Trace) :-
    shared_power(List, Shared),
    aligned_coefficients(List, Shared, Aligned),
    sum_list(Aligned, Total),
    Total =\= 0,
    normalized(Total, Shared, Coefficient, Exponent),
    written_form(Coefficient, Exponent, Text),
    exact_total(List, Exact),
    Rebuilt is Coefficient * 10 ^ Exponent,
    ( Rebuilt =:= Exact -> Validity = correct ; Validity = unvindicated ),
    g8_rational_text(Exact, ExactText),
    Outcome = action_outcome(
        add_multiples_of_powers_of_ten,
        [ classification(productive),
          cluster(g8_exponents_and_scientific_notation),
          automaton_state(q_report_the_total_as_a_multiple),
          vocabulary([multiple_of_a_power_of_ten, shared_power, coefficient,
                      scientific_notation, place_value]),
          input(multiples(List)),
          result(total(Text)),
          expected(total(Text)),
          shared_power(Shared),
          exact_total(ExactText),
          invariant(the_total_rebuilds_the_sum_of_the_parts),
          validity(Validity) ]),
    Trace = [ find_the_lowest_power_present(Shared),
              rewrite_each_multiple_over_the_shared_power(Aligned),
              add_the_aligned_coefficients(Total),
              report_the_total_as_a_multiple(Text) ].
run_g8_power_of_ten_alignment(compare_multiples_of_powers_of_ten,
                              multiples([First, Second]), Outcome, Trace) :-
    First = multiple(LabelA, _, _), Second = multiple(LabelB, _, _),
    value_of(First, ValueA), value_of(Second, ValueB),
    shared_power([First, Second], Shared),
    (   ValueA > ValueB -> Larger = LabelA, Smaller = LabelB
    ;   ValueA < ValueB -> Larger = LabelB, Smaller = LabelA
    ;   Larger = neither, Smaller = neither
    ),
    ValueB =\= 0,
    Ratio is ValueA rdiv ValueB,
    g8_rational_text(Ratio, RatioText),
    Outcome = action_outcome(
        compare_multiples_of_powers_of_ten,
        [ classification(productive),
          cluster(g8_exponents_and_scientific_notation),
          automaton_state(q_name_the_larger_multiple),
          vocabulary([multiple_of_a_power_of_ten, comparison, shared_power,
                      how_many_times_larger]),
          input(multiples([First, Second])),
          result(larger(Larger, Smaller)),
          expected(larger(Larger, Smaller)),
          shared_power(Shared),
          ratio(RatioText),
          invariant(both_multiples_are_read_over_one_power),
          validity(correct) ]),
    Trace = [ rewrite_each_multiple_over_the_shared_power(Shared),
              name_the_larger_multiple(Larger, RatioText) ].
run_g8_power_of_ten_alignment(order_multiples_of_powers_of_ten,
                              multiples(List), Outcome, Trace) :-
    maplist([M, V-M]>>value_of(M, V), List, Keyed),
    keysort(Keyed, Sorted),
    findall(Label, member(_-multiple(Label, _, _), Sorted), Labels),
    Sorted = [_-Least|_],
    last(Sorted, _-Greatest),
    Least = multiple(LeastLabel, _, _),
    Greatest = multiple(GreatestLabel, _, _),
    shared_power(List, Shared),
    Outcome = action_outcome(
        order_multiples_of_powers_of_ten,
        [ classification(productive),
          cluster(g8_exponents_and_scientific_notation),
          automaton_state(q_place_the_multiples_in_order),
          vocabulary([multiple_of_a_power_of_ten, order, least, greatest]),
          input(multiples(List)),
          result(order(Labels)),
          expected(order(Labels)),
          least(LeastLabel),
          greatest(GreatestLabel),
          shared_power(Shared),
          invariant(every_multiple_is_read_over_one_power),
          validity(correct) ]),
    Trace = [ rewrite_each_multiple_over_the_shared_power(Shared),
              place_the_multiples_in_order(Labels) ].
run_g8_power_of_ten_alignment(add_the_coefficients_without_aligning_the_powers,
                              multiples(List), Outcome, Trace) :-
    % The deformation: the coefficients are added as printed and the largest
    % power is carried along.
    findall(C, member(multiple(_, C, _), List), Coefficients),
    sum_list(Coefficients, Claimed),
    findall(E, member(multiple(_, _, E), List), Exponents),
    max_list(Exponents, Largest),
    min_list(Exponents, Smallest),
    Largest =\= Smallest,
    written_form(Claimed, Largest, ClaimedText),
    run_g8_power_of_ten_alignment(add_multiples_of_powers_of_ten,
                                  multiples(List),
                                  action_outcome(_, Properties), _),
    memberchk(result(total(CorrectText)), Properties),
    Outcome = action_outcome(
        add_the_coefficients_without_aligning_the_powers,
        [ classification(deformation),
          cluster(g8_exponents_and_scientific_notation),
          automaton_state(q_add_the_coefficients_and_keep_the_larger_power),
          vocabulary([coefficient, power_of_ten, alignment]),
          input(multiples(List)),
          result(total(ClaimedText)),
          expected(total(CorrectText)),
          deforms(add_multiples_of_powers_of_ten),
          attested_by('IM Grade 8 Unit 7 Lesson 15, Elena'),
          neighbouring_corpus_row(40416),
          validity(incorrect) ]),
    Trace = [ add_the_coefficients_and_keep_the_larger_power(ClaimedText) ].

%!  shared_power(+Multiples, -Exponent) is det.
shared_power(List, Shared) :-
    findall(E, member(multiple(_, _, E), List), Exponents),
    min_list(Exponents, Shared).

aligned_coefficients([], _, []).
aligned_coefficients([multiple(_, C, E)|T], Shared, [Scaled|R]) :-
    Steps is E - Shared,
    Scaled is C * 10 ^ Steps,
    aligned_coefficients(T, Shared, R).

value_of(multiple(_, C, E), Value) :-
    (   E >= 0
    ->  Value is C * 10 ^ E
    ;   Positive is -E,
        Denominator is 10 ^ Positive,
        Value is C rdiv Denominator
    ).

exact_total(List, Total) :-
    foldl([M, Acc0, Acc]>>( value_of(M, V), Acc is Acc0 + V ), List, 0, Total).

%!  normalized(+Coefficient, +Exponent, -NewCoefficient, -NewExponent) is det.
%
%   A total of 38.3 over 10^5 is reported as 3.83 x 10^6: the coefficient is
%   brought into the range scientific notation asks for whenever exact tenfold
%   steps can do it.
normalized(Coefficient, Exponent, NewCoefficient, NewExponent) :-
    (   Coefficient >= 10
    ->  Next is Coefficient rdiv 10, Raised is Exponent + 1,
        normalized(Next, Raised, NewCoefficient, NewExponent)
    ;   Coefficient > 0, Coefficient < 1
    ->  Next is Coefficient * 10, Lowered is Exponent - 1,
        normalized(Next, Lowered, NewCoefficient, NewExponent)
    ;   NewCoefficient = Coefficient, NewExponent = Exponent
    ).

% ==========================================================================
% 5. SELF-SUMMARY
% ==========================================================================

g8_alignment_summary(
    summary{ module: g8_power_of_ten_alignment,
             status: draft_for_quarantine,
             generated: false,
             grade: 8,
             cluster: g8_exponents_and_scientific_notation,
             doings: [ add_multiples_of_powers_of_ten,
                       compare_multiples_of_powers_of_ten,
                       order_multiples_of_powers_of_ten,
                       add_the_coefficients_without_aligning_the_powers ],
             verification: [the_total_rebuilds_the_sum_of_the_parts,
                            every_multiple_is_read_over_one_power],
             arithmetic: exact_rational,
             beside: g8_power_of_ten_notation,
             deformation_partners:
                 [add_the_coefficients_without_aligning_the_powers],
             imported_by: none }).

% ==========================================================================
% 6. RECEIPTS
%
% g8_alignment_receipt(Correction, Lesson, Doing, Json, Expected).
% ==========================================================================

% correction 100, IM-G8-U7-L15: Elena's sum, done by aligning
g8_alignment_receipt(100, 'IM-G8-U7-L15', add_multiples_of_powers_of_ten,
    _{kind: "multiples_of_powers_of_ten",
      multiples: [_{coefficient: 2.3, exponent: 5},
                  _{coefficient: 3.6, exponent: 6}]},
    total("3.83 x 10^6")).
% correction 100: Elena's own answer, reproduced as the deformation
g8_alignment_receipt(100, 'IM-G8-U7-L15',
    add_the_coefficients_without_aligning_the_powers,
    _{kind: "multiples_of_powers_of_ten",
      multiples: [_{coefficient: 2.3, exponent: 5},
                  _{coefficient: 3.6, exponent: 6}]},
    total("5.9 x 10^6")).
% correction 123, IM-G8-U7-L9: 2 * 10^-1 + 4 * 10^-2
g8_alignment_receipt(123, 'IM-G8-U7-L9', add_multiples_of_powers_of_ten,
    _{kind: "multiples_of_powers_of_ten",
      multiples: [_{coefficient: 2, exponent: -1},
                  _{coefficient: 4, exponent: -2}]},
    total("2.4 x 10^-1")).
% correction 123: 2 * 10^-1 + 4 * 10^-3
g8_alignment_receipt(123, 'IM-G8-U7-L9', add_multiples_of_powers_of_ten,
    _{kind: "multiples_of_powers_of_ten",
      multiples: [_{coefficient: 2, exponent: -1},
                  _{coefficient: 4, exponent: -3}]},
    total("2.04 x 10^-1")).
% correction 123: 2 * 10^3 + 4 * 10^1
g8_alignment_receipt(123, 'IM-G8-U7-L9', add_multiples_of_powers_of_ten,
    _{kind: "multiples_of_powers_of_ten",
      multiples: [_{coefficient: 2, exponent: 3},
                  _{coefficient: 4, exponent: 1}]},
    total("2.04 x 10^3")).
% correction 123: 2 * 10^3 + 4 * 10^2
g8_alignment_receipt(123, 'IM-G8-U7-L9', add_multiples_of_powers_of_ten,
    _{kind: "multiples_of_powers_of_ten",
      multiples: [_{coefficient: 2, exponent: 3},
                  _{coefficient: 4, exponent: 2}]},
    total("2.4 x 10^3")).
% correction 123 part 2a: 4 * 10^-4 + 5 * 10^-3 + 2 * 10^-2
g8_alignment_receipt(123, 'IM-G8-U7-L9', add_multiples_of_powers_of_ten,
    _{kind: "multiples_of_powers_of_ten",
      multiples: [_{coefficient: 4, exponent: -4},
                  _{coefficient: 5, exponent: -3},
                  _{coefficient: 2, exponent: -2}]},
    total("2.54 x 10^-2")).
% correction 123 part 2b: 4 * 10^-3 + 5 * 10^-2 + 2 * 10^-1
g8_alignment_receipt(123, 'IM-G8-U7-L9', add_multiples_of_powers_of_ten,
    _{kind: "multiples_of_powers_of_ten",
      multiples: [_{coefficient: 4, exponent: -3},
                  _{coefficient: 5, exponent: -2},
                  _{coefficient: 2, exponent: -1}]},
    total("2.54 x 10^-1")).
% correction 123 part 2c: 4 * 10^6 + 5 * 10^7 + 2 * 10^8
g8_alignment_receipt(123, 'IM-G8-U7-L9', add_multiples_of_powers_of_ten,
    _{kind: "multiples_of_powers_of_ten",
      multiples: [_{coefficient: 4, exponent: 6},
                  _{coefficient: 5, exponent: 7},
                  _{coefficient: 2, exponent: 8}]},
    total("2.54 x 10^8")).
% correction 96, IM-G8-U7-L10: light through diamond against light through ice
g8_alignment_receipt(96, 'IM-G8-U7-L10', compare_multiples_of_powers_of_ten,
    _{kind: "multiples_of_powers_of_ten",
      multiples: [_{label: "diamond", coefficient: 124, exponent: 6},
                  _{label: "ice", coefficient: 2.3, exponent: 8}]},
    larger("ice", "diamond")).
% correction 96: the six materials in order of speed
g8_alignment_receipt(96, 'IM-G8-U7-L10', order_multiples_of_powers_of_ten,
    _{kind: "multiples_of_powers_of_ten",
      multiples: [_{label: "space", coefficient: 3, exponent: 8},
                  _{label: "water", coefficient: 2.25, exponent: 8},
                  _{label: "copper wire", coefficient: 2.8, exponent: 8},
                  _{label: "diamond", coefficient: 124, exponent: 6},
                  _{label: "ice", coefficient: 2.3, exponent: 8},
                  _{label: "olive oil", coefficient: 2, exponent: 8}]},
    order(["diamond", "olive oil", "water", "ice", "copper wire", "space"])).
% correction 98, IM-G8-U7-L11: 29 * 10^-7 against 6 * 10^-6
g8_alignment_receipt(98, 'IM-G8-U7-L11', compare_multiples_of_powers_of_ten,
    _{kind: "multiples_of_powers_of_ten",
      multiples: [_{label: "29 x 10^-7", coefficient: 29, exponent: -7},
                  _{label: "6 x 10^-6", coefficient: 6, exponent: -6}]},
    larger("6 x 10^-6", "29 x 10^-7")).
% correction 98: 7 * 10^-8 against 3 * 10^-9
g8_alignment_receipt(98, 'IM-G8-U7-L11', compare_multiples_of_powers_of_ten,
    _{kind: "multiples_of_powers_of_ten",
      multiples: [_{label: "7 x 10^-8", coefficient: 7, exponent: -8},
                  _{label: "3 x 10^-9", coefficient: 3, exponent: -9}]},
    larger("7 x 10^-8", "3 x 10^-9")).
% correction 99, IM-G8-U7-L14: which creature is least numerous
g8_alignment_receipt(99, 'IM-G8-U7-L14', order_multiples_of_powers_of_ten,
    _{kind: "multiples_of_powers_of_ten",
      multiples: [_{label: "humans", coefficient: 7.5, exponent: 9},
                  _{label: "cows", coefficient: 1.3, exponent: 9},
                  _{label: "sheep", coefficient: 1.75, exponent: 9},
                  _{label: "chickens", coefficient: 2.4, exponent: 10},
                  _{label: "ants", coefficient: 5, exponent: 16},
                  _{label: "blue whales", coefficient: 4.7, exponent: 3},
                  _{label: "Antarctic krill", coefficient: 7.8, exponent: 14},
                  _{label: "zooplankton", coefficient: 1, exponent: 20},
                  _{label: "bacteria", coefficient: 5, exponent: 30}]},
    order(["blue whales", "cows", "sheep", "humans", "chickens",
           "Antarctic krill", "ants", "zooplankton", "bacteria"])).
% correction 99: which creature is least massive
g8_alignment_receipt(99, 'IM-G8-U7-L14', order_multiples_of_powers_of_ten,
    _{kind: "multiples_of_powers_of_ten",
      multiples: [_{label: "humans", coefficient: 6.2, exponent: 1},
                  _{label: "cows", coefficient: 4, exponent: 2},
                  _{label: "sheep", coefficient: 6, exponent: 1},
                  _{label: "chickens", coefficient: 2, exponent: 0},
                  _{label: "ants", coefficient: 3, exponent: -6},
                  _{label: "blue whales", coefficient: 1.9, exponent: 5},
                  _{label: "Antarctic krill", coefficient: 4.86, exponent: -4},
                  _{label: "zooplankton", coefficient: 5, exponent: -8},
                  _{label: "bacteria", coefficient: 1, exponent: -12}]},
    order(["bacteria", "zooplankton", "ants", "Antarctic krill", "chickens",
           "sheep", "humans", "cows", "blue whales"])).
% correction 99: the total mass of all humans against the total mass of all
% ants, each total computed by the published pilot's multiply and compared here
g8_alignment_receipt(99, 'IM-G8-U7-L14', compare_multiples_of_powers_of_ten,
    _{kind: "multiples_of_powers_of_ten",
      multiples: [_{label: "all humans", coefficient: 4.65, exponent: 11},
                  _{label: "all ants", coefficient: 1.5, exponent: 11}]},
    larger("all humans", "all ants")).
% correction 99: all krill against all blue whales
g8_alignment_receipt(99, 'IM-G8-U7-L14', compare_multiples_of_powers_of_ten,
    _{kind: "multiples_of_powers_of_ten",
      multiples: [_{label: "all krill", coefficient: 3.7908, exponent: 11},
                  _{label: "all blue whales", coefficient: 8.93, exponent: 8}]},
    larger("all krill", "all blue whales")).

% ==========================================================================
% 7. CHECK
% ==========================================================================

check_g8_power_of_ten_alignment :-
    check_receipts,
    check_the_deformation,
    check_negative,
    format('g8_power_of_ten_alignment: all checks ok~n').

check_receipts :-
    findall(Correction-Doing-Result,
            ( g8_alignment_receipt(Correction, _, Doing, Json, Expected),
              g8_alignment_from_json(Json, Figure),
              run_g8_power_of_ten_alignment(Doing, Figure, Outcome, _),
              outcome_property(Outcome, result(Result)),
              Result = Expected
            ), Rows),
    findall(C, g8_alignment_receipt(C, _, _, _, _), All),
    length(All, Total), length(Rows, Passed),
    Total =:= Passed,
    format('  receipts: ~w/~w printed rows run~n', [Passed, Total]),
    forall(member(Correction-Doing-Result, Rows),
           format('    correction ~w  ~w -> ~q~n',
                  [Correction, Doing, Result])).

check_the_deformation :-
    % Elena's answer and the aligned answer are both computed from the same
    % two printed multiples, and they differ.
    g8_alignment_from_json(
        _{kind: "multiples_of_powers_of_ten",
          multiples: [_{coefficient: 2.3, exponent: 5},
                      _{coefficient: 3.6, exponent: 6}]}, Figure),
    run_g8_power_of_ten_alignment(add_the_coefficients_without_aligning_the_powers,
                                  Figure, Outcome, _),
    outcome_property(Outcome, result(total(Claimed))),
    outcome_property(Outcome, expected(total(Correct))),
    Claimed \== Correct,
    outcome_property(Outcome, validity(incorrect)),
    format('  deformation: correction 100 without alignment gives ~w where aligning gives ~w~n',
           [Claimed, Correct]).

check_negative :-
    % One multiple is not a sum and is refused at decode.
    \+ g8_alignment_from_json(
           _{kind: "multiples_of_powers_of_ten",
             multiples: [_{coefficient: 2.3, exponent: 5}]}, _),
    % Multiples that already share a power carry no misalignment to deform.
    g8_alignment_from_json(
        _{kind: "multiples_of_powers_of_ten",
          multiples: [_{coefficient: 2, exponent: 4},
                      _{coefficient: 3, exponent: 4}]}, Shared),
    \+ run_g8_power_of_ten_alignment(
           add_the_coefficients_without_aligning_the_powers, Shared, _, _),
    % Where the powers agree, the sum is the plain sum of the coefficients.
    run_g8_power_of_ten_alignment(add_multiples_of_powers_of_ten, Shared,
                                  Outcome, _),
    outcome_property(Outcome, result(total("5 x 10^4"))),
    format('  negative tests: a single multiple is refused; equal powers carry no deformation and add straight to 5 x 10^4~n').

outcome_property(action_outcome(_, Props), Property) :-
    memberchk(Property, Props).
