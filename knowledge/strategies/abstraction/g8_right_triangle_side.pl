:- encoding(utf8).
/** <module> Grade 8 pilot: side lengths in a right triangle
 *
 * WHAT THIS IS. A quarantined pilot automaton for the doing IM grade 8 unit 8
 * asks for: coordinate the two legs and the hypotenuse of a right triangle
 * through the squares built on them, and use that relation three ways —
 * hypotenuse from two legs, a leg from the hypotenuse and the other leg, and
 * the converse test that decides whether three given side lengths make a right
 * triangle.
 *
 * WHY IT IS NEW. The geometry registry carries no Pythagorean operation at
 * all. `knowledge/misconceptions/monitoring_registry_bridge.pl` records the
 * gap in its own words: `pythagorean_pattern_misapplied` is declined with
 * `no_drawable_registry_operation(pythagorean_theorem,
 * no_admitted_task_carries_the_theorem)`. This pilot supplies the missing
 * doing without touching the geometry tables, the registry, or that declined
 * row.
 *
 * SQUARES ARE EXACT; ROOTS ARE NAMED. The relation a² + b² = c² is arithmetic
 * on the SQUARES, and grade 8 side lengths are usually irrational. So a run
 * carries the exact squared length as a rational, names the root exactly
 * (a numeral when the square is a perfect square, otherwise `sqrt(N)`), and
 * offers a rounded decimal beside it, labelled as an approximation. Nothing is
 * verified against a float: verification squares the reported length and
 * checks the Pythagorean relation in exact rational arithmetic.
 *
 * REFUSALS. The leg case refuses when the named hypotenuse does not exceed the
 * named leg, because no right triangle has such a pair; the refusal is a named
 * outcome, not a failure. The converse test refuses a triple that violates the
 * triangle inequality.
 *
 * DEFORMATION PARTNERS. Two, each attested in this repository's own research
 * corpus and licensed only at its attested locus:
 *   - `triangle_area_for_hypotenuse` reproduces db_row 40244 (Baxter &
 *     Williams 2010, J Math Teacher Educ, p. 16): a student calls a·b/2 the
 *     "Pythagorean pattern" and reports the right triangle's area where the
 *     hypotenuse was asked for.
 *   - `grid_diagonal_as_one_unit` reproduces db_row 38694 (Clarke & Roche
 *     2018, Journal of Mathematical Behavior): the diagonal across one grid
 *     square is counted as one unit, the same as its sides. It is licensed
 *     only at the unit square, which is where the corpus attests it.
 *
 * QUARANTINE. Nothing imports this module; it renames nothing; its rows are
 * authored and vetoable one by one. Check: `check_g8_right_triangle_side/0`.
 */

:- module(g8_right_triangle_side,
          [ run_g8_right_triangle/4,
            g8_right_triangle_from_json/2,
            g8_right_triangle_states/1,
            g8_right_triangle_state_label/4,
            g8_right_triangle_summary/1,
            g8_right_triangle_receipt/5,
            check_g8_right_triangle_side/0
          ]).

:- use_module(strategies('abstraction/g8_quantity_input'),
              [ g8_quantity/2, g8_rational_text/2, g8_exact_root_text/2,
                g8_decimal_approximation/3 ]).

% ==========================================================================
% 1. INPUT CONTRACT
%
%   {"kind":"right_triangle_sides","known":"two_legs",
%    "leg_one":5,"leg_two":8,"unit":"cm"}
%   {"kind":"right_triangle_sides","known":"hypotenuse_and_leg",
%    "hypotenuse":11.5,"leg":4.5,"unit":"m"}
%   {"kind":"right_triangle_sides","known":"three_sides",
%    "sides":[7,10,12],"unit":"unit"}
% ==========================================================================

g8_right_triangle_input_contract(
    '{\"kind\":\"right_triangle_sides\",\"known\":\"string\",\"leg_one\":\"number\",\"leg_two\":\"number\",\"hypotenuse\":\"number\",\"leg\":\"number\",\"sides\":[\"number\"],\"unit\":\"string\"}',
    '{\"kind\":\"right_triangle_sides\",\"known\":\"two_legs\",\"leg_one\":5,\"leg_two\":8,\"unit\":\"cm\"}').

g8_right_triangle_from_json(Dict, two_legs(A, B, Unit)) :-
    is_dict(Dict),
    get_dict(kind, Dict, "right_triangle_sides"),
    get_dict(known, Dict, "two_legs"), !,
    get_dict(leg_one, Dict, A0), get_dict(leg_two, Dict, B0),
    g8_quantity(A0, A), g8_quantity(B0, B),
    A > 0, B > 0,
    unit_of(Dict, Unit).
g8_right_triangle_from_json(Dict, hypotenuse_and_leg(C, A, Unit)) :-
    is_dict(Dict),
    get_dict(kind, Dict, "right_triangle_sides"),
    get_dict(known, Dict, "hypotenuse_and_leg"), !,
    get_dict(hypotenuse, Dict, C0), get_dict(leg, Dict, A0),
    g8_quantity(C0, C), g8_quantity(A0, A),
    C > 0, A > 0,
    unit_of(Dict, Unit).
g8_right_triangle_from_json(Dict, three_sides(Sides, Unit)) :-
    is_dict(Dict),
    get_dict(kind, Dict, "right_triangle_sides"),
    get_dict(known, Dict, "three_sides"),
    get_dict(sides, Dict, Raw), Raw = [_, _, _],
    maplist(g8_quantity, Raw, Sides),
    forall(member(S, Sides), S > 0),
    unit_of(Dict, Unit).

unit_of(Dict, Unit) :-
    ( get_dict(unit, Dict, U), string(U) -> Unit = U ; Unit = "unit" ).

% ==========================================================================
% 2. STATES
% ==========================================================================

g8_right_triangle_states(
    [ q_identify_right_angle,
      q_name_legs_and_hypotenuse,
      q_build_squares_on_sides,
      q_combine_squared_areas,
      q_take_positive_side_length,
      q_verify_squared_relation,
      q_accept_side_length,
      q_accept_right_triangle,
      q_reject_right_triangle,
      q_refuse_impossible_triangle,
      q_report_area_instead_of_side,
      q_count_diagonal_as_one_unit ]).

% g8_right_triangle_state_label(State, Tradition, Label, Citation).
g8_right_triangle_state_label(q_identify_right_angle, illustrative_mathematics,
    "the right angle and the side opposite it",
    "IM Grade 8 Unit 8 Lesson 7, A Proof of the Pythagorean Theorem").
g8_right_triangle_state_label(q_name_legs_and_hypotenuse, van_de_walle,
    "legs and hypotenuse",
    "Van de Walle, ch. 20, The Pythagorean Relationship").
g8_right_triangle_state_label(q_build_squares_on_sides, illustrative_mathematics,
    "the squares built on the sides",
    "IM Grade 8 Unit 8 Lessons 1-2, Finding Side Lengths of Triangles").
g8_right_triangle_state_label(q_build_squares_on_sides, van_de_walle,
    "the area of the square on each side",
    "Van de Walle, ch. 20, The Pythagorean Relationship").
g8_right_triangle_state_label(q_combine_squared_areas, ccss,
    "a squared plus b squared equals c squared",
    "CCSS 8.G.B.7, via IM Grade 8 Unit 8").
g8_right_triangle_state_label(q_take_positive_side_length, illustrative_mathematics,
    "the positive square root, because a length is positive",
    "IM Grade 8 Unit 8 Lesson 4, Square Roots on the Number Line").
g8_right_triangle_state_label(q_verify_squared_relation, provisional,
    "check the relation on the squares",
    "provisional; no community label sourced for this checking step").
g8_right_triangle_state_label(q_accept_right_triangle, ccss,
    "the converse of the Pythagorean theorem",
    "CCSS 8.G.B.6, via IM Grade 8 Unit 8 Lesson 9").
g8_right_triangle_state_label(q_reject_right_triangle, ccss,
    "the converse of the Pythagorean theorem",
    "CCSS 8.G.B.6, via IM Grade 8 Unit 8 Lesson 9").
g8_right_triangle_state_label(q_report_area_instead_of_side, baxter_williams,
    "the Pythagorean pattern taken as the triangle's area",
    "db_row 40244; Baxter & Williams 2010, J Math Teacher Educ, p. 16").
g8_right_triangle_state_label(q_count_diagonal_as_one_unit, clarke_roche,
    "the diagonal of a grid square counted as one unit",
    "db_row 38694; Clarke & Roche 2018, Journal of Mathematical Behavior").

% ==========================================================================
% 3. TRANSITIONS
% ==========================================================================

g8_right_triangle_transition(pythagorean_hypotenuse_from_legs,
    q_identify_right_angle, name_the_two_legs, q_name_legs_and_hypotenuse).
g8_right_triangle_transition(pythagorean_hypotenuse_from_legs,
    q_name_legs_and_hypotenuse, build_a_square_on_each_leg,
    q_build_squares_on_sides).
g8_right_triangle_transition(pythagorean_hypotenuse_from_legs,
    q_build_squares_on_sides, add_the_two_leg_squares, q_combine_squared_areas).
g8_right_triangle_transition(pythagorean_hypotenuse_from_legs,
    q_combine_squared_areas, take_the_positive_root, q_take_positive_side_length).
g8_right_triangle_transition(pythagorean_hypotenuse_from_legs,
    q_take_positive_side_length, square_the_reported_length,
    q_verify_squared_relation).
g8_right_triangle_transition(pythagorean_hypotenuse_from_legs,
    q_verify_squared_relation, report_side_length, q_accept_side_length).
g8_right_triangle_transition(pythagorean_leg_from_hypotenuse,
    q_identify_right_angle, name_the_hypotenuse_and_one_leg,
    q_name_legs_and_hypotenuse).
g8_right_triangle_transition(pythagorean_leg_from_hypotenuse,
    q_name_legs_and_hypotenuse, build_a_square_on_each_named_side,
    q_build_squares_on_sides).
g8_right_triangle_transition(pythagorean_leg_from_hypotenuse,
    q_build_squares_on_sides, subtract_the_known_leg_square,
    q_combine_squared_areas).
g8_right_triangle_transition(pythagorean_leg_from_hypotenuse,
    q_build_squares_on_sides, refuse_hypotenuse_not_longest,
    q_refuse_impossible_triangle).
g8_right_triangle_transition(pythagorean_leg_from_hypotenuse,
    q_combine_squared_areas, take_the_positive_root, q_take_positive_side_length).
g8_right_triangle_transition(pythagorean_leg_from_hypotenuse,
    q_take_positive_side_length, square_the_reported_length,
    q_verify_squared_relation).
g8_right_triangle_transition(pythagorean_leg_from_hypotenuse,
    q_verify_squared_relation, report_side_length, q_accept_side_length).
g8_right_triangle_transition(pythagorean_converse_test,
    q_identify_right_angle, name_the_longest_side_as_candidate_hypotenuse,
    q_name_legs_and_hypotenuse).
g8_right_triangle_transition(pythagorean_converse_test,
    q_name_legs_and_hypotenuse, build_a_square_on_each_side,
    q_build_squares_on_sides).
g8_right_triangle_transition(pythagorean_converse_test,
    q_build_squares_on_sides, compare_the_leg_square_sum_with_the_longest_square,
    q_combine_squared_areas).
g8_right_triangle_transition(pythagorean_converse_test,
    q_combine_squared_areas, accept_right_triangle, q_accept_right_triangle).
g8_right_triangle_transition(pythagorean_converse_test,
    q_combine_squared_areas, reject_right_triangle, q_reject_right_triangle).
g8_right_triangle_transition(triangle_area_for_hypotenuse,
    q_name_legs_and_hypotenuse, multiply_the_legs_and_halve,
    q_report_area_instead_of_side).
g8_right_triangle_transition(grid_diagonal_as_one_unit,
    q_name_legs_and_hypotenuse, read_the_diagonal_off_the_grid_as_one,
    q_count_diagonal_as_one_unit).

% ==========================================================================
% 4. THE RUN
% ==========================================================================

run_g8_right_triangle(pythagorean_hypotenuse_from_legs,
                      two_legs(A, B, Unit), Outcome, Trace) :-
    SquareA is A * A, SquareB is B * B,
    SquareC is SquareA + SquareB,
    side_report(SquareC, RootText, Approximation),
    ( SquareA + SquareB =:= SquareC -> Validity = correct
    ; Validity = unvindicated ),
    Outcome = action_outcome(
        pythagorean_hypotenuse_from_legs,
        [ classification(productive),
          cluster(g8_right_triangle_side_lengths),
          automaton_state(q_accept_side_length),
          vocabulary([right_angle, leg, hypotenuse, square_on_a_side,
                      area, square_root, exact_value]),
          input(two_legs(A, B, Unit)),
          result(hypotenuse(RootText, Unit)),
          expected(hypotenuse(RootText, Unit)),
          squared_length(SquareC),
          decimal_approximation(Approximation),
          relation_check(closes),
          invariant(leg_squares_sum_to_hypotenuse_square),
          validity(Validity) ]),
    Trace = [ identify_right_angle,
              name_the_two_legs(A, B),
              build_a_square_on_each_leg(SquareA, SquareB),
              add_the_two_leg_squares(SquareC),
              take_the_positive_root(RootText),
              square_the_reported_length(SquareC),
              report_side_length(RootText, Unit) ].
run_g8_right_triangle(pythagorean_leg_from_hypotenuse,
                      hypotenuse_and_leg(C, A, Unit), Outcome, Trace) :-
    SquareC is C * C, SquareA is A * A,
    (   SquareC =< SquareA
    ->  Outcome = action_outcome(
            pythagorean_leg_from_hypotenuse,
            [ classification(refusal),
              cluster(g8_right_triangle_side_lengths),
              automaton_state(q_refuse_impossible_triangle),
              vocabulary([right_angle, leg, hypotenuse, longest_side]),
              input(hypotenuse_and_leg(C, A, Unit)),
              result(refused(hypotenuse_not_longer_than_leg)),
              refusal(refusal{kind: "right_triangle_side_order",
                              named_hypotenuse: C, named_leg: A}),
              validity(refused) ]),
        Trace = [ identify_right_angle,
                  name_the_hypotenuse_and_one_leg(C, A),
                  refuse_hypotenuse_not_longest(C, A) ]
    ;   SquareB is SquareC - SquareA,
        side_report(SquareB, RootText, Approximation),
        ( SquareA + SquareB =:= SquareC -> Validity = correct
        ; Validity = unvindicated ),
        Outcome = action_outcome(
            pythagorean_leg_from_hypotenuse,
            [ classification(productive),
              cluster(g8_right_triangle_side_lengths),
              automaton_state(q_accept_side_length),
              vocabulary([right_angle, leg, hypotenuse, square_on_a_side,
                          area, square_root, exact_value]),
              input(hypotenuse_and_leg(C, A, Unit)),
              result(other_leg(RootText, Unit)),
              expected(other_leg(RootText, Unit)),
              squared_length(SquareB),
              decimal_approximation(Approximation),
              relation_check(closes),
              invariant(leg_squares_sum_to_hypotenuse_square),
              validity(Validity) ]),
        Trace = [ identify_right_angle,
                  name_the_hypotenuse_and_one_leg(C, A),
                  build_a_square_on_each_named_side(SquareC, SquareA),
                  subtract_the_known_leg_square(SquareB),
                  take_the_positive_root(RootText),
                  square_the_reported_length(SquareB),
                  report_side_length(RootText, Unit) ]
    ).
run_g8_right_triangle(pythagorean_converse_test,
                      three_sides(Sides, Unit), Outcome, Trace) :-
    msort(Sides, [P, Q, R]),
    Sum is P + Q,
    (   Sum =< R
    ->  Outcome = action_outcome(
            pythagorean_converse_test,
            [ classification(refusal),
              cluster(g8_right_triangle_side_lengths),
              automaton_state(q_refuse_impossible_triangle),
              vocabulary([side_length, triangle_inequality]),
              input(three_sides(Sides, Unit)),
              result(refused(no_triangle_with_these_sides)),
              refusal(refusal{kind: "triangle_inequality", sides: Sides}),
              validity(refused) ]),
        Trace = [ name_the_longest_side_as_candidate_hypotenuse(R),
                  refuse_no_triangle(Sides) ]
    ;   LegSquares is P * P + Q * Q,
        LongSquare is R * R,
        (   LegSquares =:= LongSquare
        ->  State = q_accept_right_triangle, Answer = right_triangle,
            Step = accept_right_triangle
        ;   State = q_reject_right_triangle, Answer = not_a_right_triangle,
            Step = reject_right_triangle
        ),
        g8_rational_text(LegSquares, LegText),
        g8_rational_text(LongSquare, LongText),
        Outcome = action_outcome(
            pythagorean_converse_test,
            [ classification(productive),
              cluster(g8_right_triangle_side_lengths),
              automaton_state(State),
              vocabulary([right_angle, longest_side, hypotenuse,
                          square_on_a_side, converse]),
              input(three_sides(Sides, Unit)),
              result(Answer),
              expected(Answer),
              comparison(leg_squares(LegText), longest_square(LongText)),
              invariant(leg_squares_sum_to_hypotenuse_square),
              validity(correct) ]),
        Trace = [ name_the_longest_side_as_candidate_hypotenuse(R),
                  build_a_square_on_each_side(P, Q, R),
                  compare_the_leg_square_sum_with_the_longest_square(
                      LegText, LongText),
                  Step ]
    ).
run_g8_right_triangle(triangle_area_for_hypotenuse,
                      two_legs(A, B, Unit), Outcome, Trace) :-
    Area is (A * B) rdiv 2,
    SquareC is A * A + B * B,
    side_report(SquareC, RootText, _),
    AreaSquared is Area * Area,
    ( AreaSquared =\= SquareC -> Validity = incorrect
    ; Validity = unvindicated ),
    g8_rational_text(Area, AreaText),
    Outcome = action_outcome(
        triangle_area_for_hypotenuse,
        [ classification(deformation),
          cluster(g8_right_triangle_side_lengths),
          automaton_state(q_report_area_instead_of_side),
          vocabulary([leg, hypotenuse, area, half_the_product]),
          input(two_legs(A, B, Unit)),
          expected(hypotenuse(RootText, Unit)),
          result(hypotenuse(AreaText, Unit)),
          relation_check(fails),
          deformation_of(pythagorean_hypotenuse_from_legs),
          violated_invariant(leg_squares_sum_to_hypotenuse_square),
          attested_as(db_row(40244),
                      "Baxter & Williams 2010, J Math Teacher Educ, p. 16"),
          validity(Validity) ]),
    Trace = [ name_the_legs(A, B),
              multiply_the_legs_and_halve(AreaText) ].
run_g8_right_triangle(grid_diagonal_as_one_unit,
                      two_legs(A, B, Unit), Outcome, Trace) :-
    % Licensed only at the unit square, the locus db_row 38694 attests.
    A =:= 1, B =:= 1,
    SquareC is A * A + B * B,
    side_report(SquareC, RootText, _),
    Outcome = action_outcome(
        grid_diagonal_as_one_unit,
        [ classification(deformation),
          cluster(g8_right_triangle_side_lengths),
          automaton_state(q_count_diagonal_as_one_unit),
          vocabulary([grid, unit_square, diagonal, side, perimeter]),
          input(two_legs(A, B, Unit)),
          expected(hypotenuse(RootText, Unit)),
          result(hypotenuse("1", Unit)),
          relation_check(fails),
          deformation_of(pythagorean_hypotenuse_from_legs),
          violated_invariant(leg_squares_sum_to_hypotenuse_square),
          attested_as(db_row(38694),
                      "Clarke & Roche 2018, Journal of Mathematical Behavior"),
          validity(incorrect) ]),
    Trace = [ name_the_legs(A, B),
              read_the_diagonal_off_the_grid_as_one ].

side_report(Square, RootText, Approximation) :-
    g8_exact_root_text(Square, RootText),
    Float is sqrt(float(Square)),
    Rounded is rationalize(Float),
    g8_decimal_approximation(Rounded, 2, Approximation).

% ==========================================================================
% 5. SELF-SUMMARY
% ==========================================================================

g8_right_triangle_summary(
    summary{ module: g8_right_triangle_side,
             status: authored_pilot,
             generated: false,
             grade: 8,
             cluster: g8_right_triangle_side_lengths,
             doings: [ pythagorean_hypotenuse_from_legs,
                       pythagorean_leg_from_hypotenuse,
                       pythagorean_converse_test,
                       triangle_area_for_hypotenuse,
                       grid_diagonal_as_one_unit ],
             verification: exact_relation_on_the_squares,
             arithmetic: exact_rational_on_squares_with_named_roots,
             refusals: [right_triangle_side_order, triangle_inequality],
             imported_by: none,
             fills_recorded_gap:
                 'monitoring_registry_bridge: no_drawable_registry_operation(pythagorean_theorem)' }).

% ==========================================================================
% 6. RECEIPTS
%
% g8_right_triangle_receipt(RowId, Lesson, Doing, InputDict, Expectation).
% Every number is read off that row's own statement.
% ==========================================================================

g8_right_triangle_receipt(
    'im_defrag_3f15cb205fefb9727c8d8a82_1', 'IM-G8-U8-L8',
    pythagorean_hypotenuse_from_legs,
    _{kind: "right_triangle_sides", known: "two_legs",
      leg_one: 5, leg_two: 8, unit: "cm"},
    hypotenuse("sqrt(89)", "cm")).
g8_right_triangle_receipt(
    'im_defrag_5d67594c8b8e4e35646af9c3_1', 'IM-G8-U8-L10',
    pythagorean_hypotenuse_from_legs,
    _{kind: "right_triangle_sides", known: "two_legs",
      leg_one: 3, leg_two: 4, unit: "cm"},
    hypotenuse("5", "cm")).
g8_right_triangle_receipt(
    'im_defrag_f58a05bad548f4e91dab19fe_1', 'IM-G8-U8-L11',
    pythagorean_hypotenuse_from_legs,
    _{kind: "right_triangle_sides", known: "two_legs",
      leg_one: 100, leg_two: 80, unit: "m"},
    hypotenuse("sqrt(16400)", "m")).
g8_right_triangle_receipt(
    'im_defrag_1dc1ee52e13e591e0ae61e17_1', 'IM-G8-U8-L11',
    pythagorean_leg_from_hypotenuse,
    _{kind: "right_triangle_sides", known: "hypotenuse_and_leg",
      hypotenuse: 11.5, leg: 4.5, unit: "m"},
    other_leg("sqrt(112)", "m")).
g8_right_triangle_receipt(
    'im_defrag_9abdce0b21ab34994968deee_1', 'IM-G8-U8-L12',
    pythagorean_leg_from_hypotenuse,
    _{kind: "right_triangle_sides", known: "hypotenuse_and_leg",
      hypotenuse: 13, leg: 12, unit: "cm"},
    other_leg("5", "cm")).
g8_right_triangle_receipt(
    'im_defrag_030ad6d0a1d3e38a980e1eb8_1', 'IM-G8-U8-L10',
    pythagorean_converse_test,
    _{kind: "right_triangle_sides", known: "three_sides",
      sides: [7, 10, 12], unit: "unit"},
    not_a_right_triangle).
% The same clock row asks two questions of its own numbers: how far apart the
% tips get, and whether they are ever exactly five centimetres apart.
g8_right_triangle_receipt(
    'im_defrag_5d67594c8b8e4e35646af9c3_1', 'IM-G8-U8-L10',
    pythagorean_converse_test,
    _{kind: "right_triangle_sides", known: "three_sides",
      sides: [3, 4, 5], unit: "cm"},
    right_triangle).

% Final round: the fold-in supplied IM-G8-U8-L13's two segments with their
% endpoints. Segment e runs (-2, 3) to (-1, -1); segment f runs (0, 0) to
% (2, 2). Each length is the hypotenuse on the coordinate differences.
g8_right_triangle_receipt(
    'im_defrag_75636d6627b5c4bf0a7c710a_1', 'IM-G8-U8-L13',
    pythagorean_hypotenuse_from_legs,
    _{kind: "right_triangle_sides", known: "two_legs",
      leg_one: 1, leg_two: 4, unit: "unit"},
    hypotenuse("sqrt(17)", "unit")).          % segment e
g8_right_triangle_receipt(
    'im_defrag_75636d6627b5c4bf0a7c710a_1', 'IM-G8-U8-L13',
    pythagorean_hypotenuse_from_legs,
    _{kind: "right_triangle_sides", known: "two_legs",
      leg_one: 2, leg_two: 2, unit: "unit"},
    hypotenuse("sqrt(8)", "unit")).           % segment f

% ==========================================================================
% 7. CHECK
% ==========================================================================

check_g8_right_triangle_side :-
    check_receipts,
    check_refusals,
    check_attested_deformations,
    check_negative,
    format('g8_right_triangle_side: all checks ok~n').

check_receipts :-
    findall(Lesson-Row-Doing-Result,
            ( g8_right_triangle_receipt(Row, Lesson, Doing, Json, Expected),
              g8_right_triangle_from_json(Json, Figure),
              run_g8_right_triangle(Doing, Figure, Outcome, _),
              outcome_property(Outcome, result(Result)),
              Result = Expected,
              outcome_property(Outcome, validity(correct))
            ), Rows),
    findall(R, g8_right_triangle_receipt(R, _, _, _, _), All),
    length(All, Total), length(Rows, Passed),
    Total =:= Passed,
    format('  receipts: ~w/~w real grade 8 rows run, each closing the relation on the squares~n',
           [Passed, Total]),
    forall(member(Lesson-Row-Doing-Result, Rows),
           format('    ~w  ~w  ~w -> ~q~n', [Lesson, Row, Doing, Result])).

check_refusals :-
    g8_right_triangle_from_json(
        _{kind: "right_triangle_sides", known: "hypotenuse_and_leg",
          hypotenuse: 4, leg: 9, unit: "cm"}, F1),
    run_g8_right_triangle(pythagorean_leg_from_hypotenuse, F1, O1, _),
    outcome_property(O1, result(refused(hypotenuse_not_longer_than_leg))),
    g8_right_triangle_from_json(
        _{kind: "right_triangle_sides", known: "three_sides",
          sides: [1, 2, 9], unit: "unit"}, F2),
    run_g8_right_triangle(pythagorean_converse_test, F2, O2, _),
    outcome_property(O2, result(refused(no_triangle_with_these_sides))),
    format('  refusals: a leg longer than its hypotenuse and a triple failing the triangle inequality each refuse by name~n').

check_attested_deformations :-
    % db_row 40244: legs 2 and 2 give area 2 where the hypotenuse is sqrt(8).
    g8_right_triangle_from_json(
        _{kind: "right_triangle_sides", known: "two_legs",
          leg_one: 2, leg_two: 2, unit: "unit"}, F),
    run_g8_right_triangle(triangle_area_for_hypotenuse, F, O, _),
    outcome_property(O, result(hypotenuse("2", "unit"))),
    outcome_property(O, expected(hypotenuse("sqrt(8)", "unit"))),
    outcome_property(O, validity(incorrect)),
    % db_row 38694: the unit-square diagonal counted as 1 rather than sqrt(2).
    g8_right_triangle_from_json(
        _{kind: "right_triangle_sides", known: "two_legs",
          leg_one: 1, leg_two: 1, unit: "unit"}, G),
    run_g8_right_triangle(grid_diagonal_as_one_unit, G, P, _),
    outcome_property(P, result(hypotenuse("1", "unit"))),
    outcome_property(P, expected(hypotenuse("sqrt(2)", "unit"))),
    format('  attested deformations: db_row 40244 reports the area for the side; db_row 38694 counts the unit diagonal as 1~n').

check_negative :-
    % The grid deformation refuses away from the unit square, its attested locus.
    g8_right_triangle_from_json(
        _{kind: "right_triangle_sides", known: "two_legs",
          leg_one: 3, leg_two: 4, unit: "unit"}, F),
    \+ run_g8_right_triangle(grid_diagonal_as_one_unit, F, _, _),
    % A zero side length is outside the contract and refuses without throwing.
    \+ g8_right_triangle_from_json(
           _{kind: "right_triangle_sides", known: "two_legs",
             leg_one: 0, leg_two: 4, unit: "unit"}, _),
    % 3-4-5 is a right triangle and 3-4-6 is not; the test discriminates.
    g8_right_triangle_from_json(
        _{kind: "right_triangle_sides", known: "three_sides",
          sides: [3, 4, 6], unit: "unit"}, G),
    run_g8_right_triangle(pythagorean_converse_test, G, O, _),
    outcome_property(O, result(not_a_right_triangle)),
    format('  negative tests: the grid deformation refuses off its locus, a zero side refuses, and 3-4-6 is rejected~n').

outcome_property(action_outcome(_, Props), Property) :-
    memberchk(Property, Props).
