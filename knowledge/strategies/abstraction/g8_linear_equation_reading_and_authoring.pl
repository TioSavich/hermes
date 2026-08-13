:- encoding(utf8).
/** <module> Grade 8 draft: what an equation says about its line, and writing one to order
 *
 * WHAT THIS IS. A draft automaton for the demands in grade 8 units 3 and 4
 * that are about the FORM of a linear equation rather than about solving it.
 * The published pilots solve: `g8_linear_equation_balance` finds the value,
 * `g8_linear_system_solution` finds the pair. Neither answers correction 87
 * ("select all the coordinates that represent a point on the graph of
 * x - 9y = 12"), correction 65 ("select all the equations whose graphs have
 * the same y-intercept as y = 3x - 8"), or correction 44 ("complete each
 * equation so that it is true for all values of x").
 *
 * THREE READINGS AND ONE AUTHORING. Testing a point, reading the intercepts,
 * and comparing two lines are readings: they ask what an equation already
 * says. Completing a blank so the equation is true for every value or for no
 * value runs the other way — it asks a student to WRITE an equation with a
 * named solution set, and the automaton solves for the blank rather than for
 * the unknown. Grade 8 unit 4 lesson 7 is built on that reversal, and nothing
 * published performs it.
 *
 * HOW THE BLANK IS SOLVED. The side carrying the blank is read twice: once
 * for how much of the unknown it holds, once for how much of the blank. That
 * gives the side as A·x + B + C·(blank), and matching it against the known
 * side A'·x + B' determines the blank exactly when C is not zero. A blank
 * that must carry the unknown itself, as in correction 44's
 * (15x - 10)/5 = ___ - 2, comes back as a linear expression rather than a
 * number, which is what the printed answer 3x is.
 *
 * TRUE FOR NO VALUES IS A FAMILY, NOT AN ANSWER. Any completion sharing the
 * identity's coefficient of the unknown and differing in its constant makes
 * the equation false everywhere. The run reports one witness AND names the
 * family, because a task that says "write the other side so this is true for
 * no values" has infinitely many right answers and a machine that returns one
 * without saying so would be misreporting.
 *
 * NO DEFORMATION PARTNER. The corrected pool prints no student work at this
 * locus: corrections 43, 44, 65, 66 and 87 all state the demand without a
 * wrong answer beside it, and the research corpus rows on intercepts describe
 * dropping the intercept in a MODEL (row 38094), which the published linear
 * model pilot already carries as `drop_the_vertical_intercept`. Shipping
 * without a partner is the honest choice.
 *
 * QUARANTINE. Nothing imports this module; it is a draft under
 * `.superpowers/sdd/g8-round2/`. Check:
 * `check_g8_linear_equation_reading_and_authoring/0`.
 */

:- module(g8_linear_equation_reading_and_authoring,
          [ run_g8_line_reading/4,
            g8_line_reading_from_json/2,
            g8_line_reading_states/1,
            g8_line_reading_state_label/4,
            g8_line_reading_summary/1,
            g8_line_reading_receipt/5,
            check_g8_linear_equation_reading_and_authoring/0
          ]).

:- use_module(strategies('abstraction/g8_quantity_input'),
              [ g8_quantity/2, g8_rational_text/2 ]).

% ==========================================================================
% 1. INPUT CONTRACT
%
%   {"kind":"point_against_line",
%    "line":{"form":"standard","a":1,"b":-9,"c":12},
%    "point":{"x":3,"y":-1},"label":"C"}
%   {"kind":"line_form","line":{"form":"slope_intercept","slope":3,
%                               "intercept":-8},"name":"y = 3x - 8"}
%   {"kind":"equation_completion","unknown":"x","target":"every_value",
%    "known":{"op":"sum","terms":[{"op":"product",
%              "factors":[{"op":"number","value":3},{"op":"unknown"}]},
%             {"op":"number","value":6}]},
%    "blank_side":{"op":"product","factors":[{"op":"number","value":3},
%              {"op":"sum","terms":[{"op":"unknown"},{"op":"blank"}]}]}}
%
% A line arrives in either printed form. Standard form is a·x + b·y = c;
% slope-intercept is y = m·x + k, which decodes to -m·x + y = k so one run
% serves both.
% ==========================================================================

g8_line_reading_input_contract(
    '{\"kind\":\"point_against_line\",\"line\":{\"form\":\"string\",\"a\":\"number\",\"b\":\"number\",\"c\":\"number\",\"slope\":\"number\",\"intercept\":\"number\"},\"point\":{\"x\":\"number\",\"y\":\"number\"},\"label\":\"string\"}',
    '{\"kind\":\"point_against_line\",\"line\":{\"form\":\"standard\",\"a\":1,\"b\":-9,\"c\":12},\"point\":{\"x\":3,\"y\":-1},\"label\":\"C\"}').

g8_line_reading_from_json(Dict, point_test(Line, X, Y, Label)) :-
    is_dict(Dict),
    get_dict(kind, Dict, "point_against_line"), !,
    get_dict(line, Dict, L), line_of(L, Line),
    get_dict(point, Dict, P),
    get_dict(x, P, X0), get_dict(y, P, Y0),
    g8_quantity(X0, X), g8_quantity(Y0, Y),
    ( get_dict(label, Dict, Lb), string(Lb) -> Label = Lb ; Label = "the point" ).
g8_line_reading_from_json(Dict, line_form(Line, Name)) :-
    is_dict(Dict),
    get_dict(kind, Dict, "line_form"), !,
    get_dict(line, Dict, L), line_of(L, Line),
    ( get_dict(name, Dict, N), string(N) -> Name = N ; Name = "the line" ).
g8_line_reading_from_json(Dict, completion(Unknown, Target, Known, Blank)) :-
    is_dict(Dict),
    get_dict(kind, Dict, "equation_completion"),
    get_dict(unknown, Dict, U0),
    ( string(U0) -> Unknown = U0 ; atom_string(U0, Unknown) ),
    get_dict(target, Dict, TargetText),
    memberchk(TargetText, ["every_value", "no_value"]),
    atom_string(Target, TargetText),
    get_dict(known, Dict, K), node_of(K, Known),
    get_dict(blank_side, Dict, B), node_of(B, Blank),
    holds_one_blank(Blank).

line_of(Dict, line(A, B, C)) :-
    get_dict(form, Dict, "standard"), !,
    get_dict(a, Dict, A0), get_dict(b, Dict, B0), get_dict(c, Dict, C0),
    g8_quantity(A0, A), g8_quantity(B0, B), g8_quantity(C0, C),
    \+ ( A =:= 0, B =:= 0 ).
line_of(Dict, line(A, 1, K)) :-
    get_dict(form, Dict, "slope_intercept"),
    get_dict(slope, Dict, M0), g8_quantity(M0, M),
    get_dict(intercept, Dict, K0), g8_quantity(K0, K),
    A is -M.

node_of(Dict, number(V)) :-
    get_dict(op, Dict, "number"), !,
    get_dict(value, Dict, V0), g8_quantity(V0, V).
node_of(Dict, unknown) :- get_dict(op, Dict, "unknown"), !.
node_of(Dict, blank) :- get_dict(op, Dict, "blank"), !.
node_of(Dict, sum(Nodes)) :-
    get_dict(op, Dict, "sum"), !,
    get_dict(terms, Dict, Raw), Raw = [_, _|_],
    maplist(node_of, Raw, Nodes).
node_of(Dict, product(Nodes)) :-
    get_dict(op, Dict, "product"), !,
    get_dict(factors, Dict, Raw), Raw = [_, _|_],
    maplist(node_of, Raw, Nodes).
node_of(Dict, quotient(Node, Divisor)) :-
    get_dict(op, Dict, "quotient"),
    get_dict(dividend, Dict, D), node_of(D, Node),
    get_dict(divisor, Dict, V0), g8_quantity(V0, Divisor), Divisor =\= 0.

holds_one_blank(Node) :- blank_count(Node, 1).

blank_count(blank, 1) :- !.
blank_count(number(_), 0) :- !.
blank_count(unknown, 0) :- !.
blank_count(sum(Nodes), Count) :- !,
    foldl([N, A0, A]>>( blank_count(N, C), A is A0 + C ), Nodes, 0, Count).
blank_count(product(Nodes), Count) :- !,
    foldl([N, A0, A]>>( blank_count(N, C), A is A0 + C ), Nodes, 0, Count).
blank_count(quotient(Node, _), Count) :- blank_count(Node, Count).

% ==========================================================================
% 2. STATES
% ==========================================================================

g8_line_reading_states(
    [ q_read_the_equation,
      q_substitute_the_pair_into_the_equation,
      q_report_the_point_is_on_the_line,
      q_report_the_point_is_off_the_line,
      q_set_the_first_coordinate_to_zero,
      q_set_the_second_coordinate_to_zero,
      q_report_the_intercepts,
      q_read_the_side_for_the_unknown_and_for_the_blank,
      q_match_the_two_sides_term_by_term,
      q_report_the_completion_for_every_value,
      q_report_a_witness_and_the_family_for_no_value,
      q_refuse_a_blank_that_cancels ]).

% g8_line_reading_state_label(State, Tradition, Label, Citation).
g8_line_reading_state_label(q_substitute_the_pair_into_the_equation,
    illustrative_mathematics,
    "a point is on the graph when its coordinates make the equation true",
    "IM Grade 8 Unit 3 Lesson 13, More Solutions to Linear Equations").
g8_line_reading_state_label(q_substitute_the_pair_into_the_equation, ccss,
    "understand that solutions to an equation in two variables are the points on its graph",
    "CCSS 8.EE.C.8.a, via IM Grade 8 Unit 3 Lesson 13").
g8_line_reading_state_label(q_set_the_first_coordinate_to_zero,
    illustrative_mathematics,
    "the vertical intercept, where the line meets the y-axis",
    "IM Grade 8 Unit 3 Lesson 8, Translating to y = mx + b").
g8_line_reading_state_label(q_read_the_side_for_the_unknown_and_for_the_blank,
    illustrative_mathematics,
    "writing the other side so the equation is true for all values",
    "IM Grade 8 Unit 4 Lesson 7, All, Some, or No Solutions").
g8_line_reading_state_label(q_report_a_witness_and_the_family_for_no_value,
    illustrative_mathematics,
    "an equation true for no values keeps the terms with the unknown and changes a constant",
    "IM Grade 8 Unit 4 Lesson 7, All, Some, or No Solutions").
g8_line_reading_state_label(q_refuse_a_blank_that_cancels, provisional,
    "the blank does not reach the equation",
    "provisional; no community label sourced for this refusal").

% ==========================================================================
% 3. TRANSITIONS
% ==========================================================================

g8_line_reading_transition(test_a_point_against_a_line,
    q_read_the_equation, substitute_the_pair_into_the_equation,
    q_substitute_the_pair_into_the_equation).
g8_line_reading_transition(test_a_point_against_a_line,
    q_substitute_the_pair_into_the_equation, report_the_point_is_on_the_line,
    q_report_the_point_is_on_the_line).
g8_line_reading_transition(test_a_point_against_a_line,
    q_substitute_the_pair_into_the_equation, report_the_point_is_off_the_line,
    q_report_the_point_is_off_the_line).
g8_line_reading_transition(intercepts_of_a_line,
    q_read_the_equation, set_the_first_coordinate_to_zero,
    q_set_the_first_coordinate_to_zero).
g8_line_reading_transition(intercepts_of_a_line,
    q_set_the_first_coordinate_to_zero, set_the_second_coordinate_to_zero,
    q_set_the_second_coordinate_to_zero).
g8_line_reading_transition(intercepts_of_a_line,
    q_set_the_second_coordinate_to_zero, report_the_intercepts,
    q_report_the_intercepts).
g8_line_reading_transition(complete_the_equation,
    q_read_the_equation, read_the_side_for_the_unknown_and_for_the_blank,
    q_read_the_side_for_the_unknown_and_for_the_blank).
g8_line_reading_transition(complete_the_equation,
    q_read_the_side_for_the_unknown_and_for_the_blank,
    match_the_two_sides_term_by_term, q_match_the_two_sides_term_by_term).
g8_line_reading_transition(complete_the_equation,
    q_match_the_two_sides_term_by_term, report_the_completion_for_every_value,
    q_report_the_completion_for_every_value).
g8_line_reading_transition(complete_the_equation,
    q_match_the_two_sides_term_by_term,
    report_a_witness_and_the_family_for_no_value,
    q_report_a_witness_and_the_family_for_no_value).
g8_line_reading_transition(complete_the_equation,
    q_read_the_side_for_the_unknown_and_for_the_blank, refuse_a_blank_that_cancels,
    q_refuse_a_blank_that_cancels).

% ==========================================================================
% 4. THE RUN
% ==========================================================================

run_g8_line_reading(test_a_point_against_a_line, point_test(line(A, B, C), X, Y,
                                                            Label),
                    Outcome, Trace) :-
    Left is A * X + B * Y,
    g8_rational_text(Left, LeftText), g8_rational_text(C, RightText),
    (   Left =:= C
    ->  State = q_report_the_point_is_on_the_line,
        Answer = on_the_line(Label),
        Step = report_the_point_is_on_the_line(LeftText)
    ;   State = q_report_the_point_is_off_the_line,
        Answer = off_the_line(Label, LeftText, RightText),
        Step = report_the_point_is_off_the_line(LeftText, RightText)
    ),
    Outcome = action_outcome(
        test_a_point_against_a_line,
        [ classification(productive),
          cluster(g8_linear_relationships_and_slope),
          automaton_state(State),
          vocabulary([solution, coordinate_pair, graph_of_an_equation,
                      substitution]),
          input(point_test(line(A, B, C), X, Y, Label)),
          result(Answer),
          expected(Answer),
          substitution(LeftText = RightText),
          invariant(the_pair_is_put_back_into_the_equation),
          validity(correct) ]),
    Trace = [ substitute_the_pair_into_the_equation(X, Y), Step ].
run_g8_line_reading(intercepts_of_a_line, line_form(line(A, B, C), Name),
                    Outcome, Trace) :-
    (   B =\= 0
    ->  Vertical is C rdiv B, g8_rational_text(Vertical, VerticalText),
        VerticalReport = at(VerticalText)
    ;   VerticalReport = none_the_line_is_vertical
    ),
    (   A =\= 0
    ->  Horizontal is C rdiv A, g8_rational_text(Horizontal, HorizontalText),
        HorizontalReport = at(HorizontalText)
    ;   HorizontalReport = none_the_line_is_horizontal
    ),
    (   B =\= 0
    ->  Slope is -A rdiv B, g8_rational_text(Slope, SlopeText),
        SlopeReport = SlopeText
    ;   SlopeReport = "undefined"
    ),
    Outcome = action_outcome(
        intercepts_of_a_line,
        [ classification(productive),
          cluster(g8_linear_relationships_and_slope),
          automaton_state(q_report_the_intercepts),
          vocabulary([vertical_intercept, horizontal_intercept, slope,
                      graph_of_an_equation]),
          input(line_form(line(A, B, C), Name)),
          result(intercepts(Name, vertical(VerticalReport),
                            horizontal(HorizontalReport))),
          expected(intercepts(Name, vertical(VerticalReport),
                              horizontal(HorizontalReport))),
          slope(SlopeReport),
          invariant(each_intercept_comes_from_setting_the_other_coordinate_to_zero),
          validity(correct) ]),
    Trace = [ set_the_first_coordinate_to_zero(VerticalReport),
              set_the_second_coordinate_to_zero(HorizontalReport),
              report_the_intercepts(Name) ].
run_g8_line_reading(complete_the_equation,
                    completion(Unknown, Target, Known, Blank), Outcome, Trace) :-
    linear_form(Known, KnownA, KnownB),
    blank_form(Blank, SideA, SideB, BlankCoefficient, BlankUnknownWeight),
    (   BlankCoefficient =:= 0
    ->  Outcome = action_outcome(
            complete_the_equation,
            [ classification(refusal),
              cluster(g8_one_variable_linear_equations),
              automaton_state(q_refuse_a_blank_that_cancels),
              vocabulary([blank, equivalent_expression]),
              input(completion(Unknown, Target, Known, Blank)),
              result(refused(the_blank_does_not_reach_the_equation)),
              refusal(refusal{kind: "blank_cancels"}),
              validity(refused) ]),
        Trace = [ refuse_a_blank_that_cancels ]
    ;   % the blank as u * unknown + v
        U is (KnownA - SideA) rdiv (BlankCoefficient * BlankUnknownWeight),
        V is (KnownB - SideB) rdiv BlankCoefficient,
        completion_text(U, V, Unknown, EveryText),
        (   Target == every_value
        ->  % substitution receipt: rebuild the side with the completion in it
            Rebuilt is SideA + BlankCoefficient * BlankUnknownWeight * U,
            RebuiltConstant is SideB + BlankCoefficient * V,
            (   Rebuilt =:= KnownA, RebuiltConstant =:= KnownB
            ->  Validity = correct ; Validity = unvindicated ),
            State = q_report_the_completion_for_every_value,
            Answer = completion_for_every_value(EveryText),
            Step = report_the_completion_for_every_value(EveryText)
        ;   Witness is V + 1,
            completion_text(U, Witness, Unknown, WitnessText),
            Validity = correct,
            State = q_report_a_witness_and_the_family_for_no_value,
            Answer = completion_for_no_value(WitnessText,
                                             any_constant_other_than(V)),
            Step = report_a_witness_and_the_family_for_no_value(WitnessText)
        ),
        Outcome = action_outcome(
            complete_the_equation,
            [ classification(productive),
              cluster(g8_one_variable_linear_equations),
              automaton_state(State),
              vocabulary([blank, true_for_all_values, true_for_no_values,
                          equivalent_expression, solution_set]),
              input(completion(Unknown, Target, Known, Blank)),
              result(Answer),
              expected(Answer),
              identity_completion(EveryText),
              invariant(the_completion_is_substituted_back_into_the_side),
              validity(Validity) ]),
        Trace = [ read_the_side_for_the_unknown_and_for_the_blank(SideA, SideB,
                                                                  BlankCoefficient),
                  match_the_two_sides_term_by_term(KnownA, KnownB),
                  Step ]
    ).

completion_text(U, V, Unknown, Text) :-
    (   U =:= 0
    ->  g8_rational_text(V, Body), Text = Body
    ;   g8_rational_text(U, UText), g8_rational_text(V, VText),
        (   V =:= 0
        ->  format(atom(A), '~w~w', [UText, Unknown])
        ;   V > 0
        ->  format(atom(A), '~w~w + ~w', [UText, Unknown, VText])
        ;   Positive is -V, g8_rational_text(Positive, PText),
            format(atom(A), '~w~w - ~w', [UText, Unknown, PText])
        ),
        atom_string(A, Text)
    ).

%!  linear_form(+Node, -Coefficient, -Constant) is semidet.
linear_form(number(V), 0, V).
linear_form(unknown, 1, 0).
linear_form(sum(Nodes), A, B) :-
    foldl([N, A0-B0, A1-B1]>>( linear_form(N, Ai, Bi),
                               A1 is A0 + Ai, B1 is B0 + Bi ),
          Nodes, 0-0, A-B).
linear_form(product(Nodes), A, B) :-
    foldl([N, A0-B0, A1-B1]>>( linear_form(N, Ai, Bi),
                               ( A0 =:= 0 -> true ; Ai =:= 0 ),
                               A1 is A0 * Bi + Ai * B0,
                               B1 is B0 * Bi ),
          Nodes, 0-1, A-B).
linear_form(quotient(Node, D), A, B) :-
    linear_form(Node, A0, B0),
    A is A0 rdiv D, B is B0 rdiv D.

%!  blank_form(+Node, -Coefficient, -Constant, -BlankCoefficient, -Weight)
%
%   The side read twice: what it holds of the unknown and the constant when
%   the blank is zero, and how much of the blank reaches the total. Weight is
%   1 throughout: a blank multiplied by a number carries the unknown at the
%   same rate it carries its own constant part.
blank_form(Node, A, B, BlankCoefficient, 1) :-
    substitute_blank(Node, number(0), Zeroed),
    linear_form(Zeroed, A, B),
    substitute_blank(Node, number(1), Oned),
    linear_form(Oned, _, BOne),
    BlankCoefficient is BOne - B.

substitute_blank(blank, With, With) :- !.
substitute_blank(number(V), _, number(V)) :- !.
substitute_blank(unknown, _, unknown) :- !.
substitute_blank(sum(Nodes), With, sum(Out)) :- !,
    maplist([N, O]>>substitute_blank(N, With, O), Nodes, Out).
substitute_blank(product(Nodes), With, product(Out)) :- !,
    maplist([N, O]>>substitute_blank(N, With, O), Nodes, Out).
substitute_blank(quotient(Node, D), With, quotient(Out, D)) :-
    substitute_blank(Node, With, Out).

% ==========================================================================
% 5. SELF-SUMMARY
% ==========================================================================

g8_line_reading_summary(
    summary{ module: g8_linear_equation_reading_and_authoring,
             status: draft_for_quarantine,
             generated: false,
             grade: 8,
             cluster: g8_linear_relationships_and_slope,
             doings: [ test_a_point_against_a_line,
                       intercepts_of_a_line,
                       complete_the_equation ],
             verification: [the_pair_is_put_back_into_the_equation,
                            the_completion_is_substituted_back_into_the_side],
             arithmetic: exact_rational,
             beside: [g8_linear_equation_balance, g8_linear_system_solution],
             deformation_partners: none_attested_at_this_locus,
             imported_by: none }).

% ==========================================================================
% 6. RECEIPTS
%
% g8_line_reading_receipt(Correction, Lesson, Doing, Json, Expected).
% ==========================================================================

% correction 87, IM-G8-U3-L13: the five candidates against x - 9y = 12
g8_line_reading_receipt(87, 'IM-G8-U3-L13', test_a_point_against_a_line,
    _{kind: "point_against_line",
      line: _{form: "standard", a: 1, b: -9, c: 12},
      point: _{x: 12, y: 0}, label: "A"},
    on_the_line("A")).
g8_line_reading_receipt(87, 'IM-G8-U3-L13', test_a_point_against_a_line,
    _{kind: "point_against_line",
      line: _{form: "standard", a: 1, b: -9, c: 12},
      point: _{x: 0, y: 12}, label: "B"},
    off_the_line("B", "-108", "12")).
g8_line_reading_receipt(87, 'IM-G8-U3-L13', test_a_point_against_a_line,
    _{kind: "point_against_line",
      line: _{form: "standard", a: 1, b: -9, c: 12},
      point: _{x: 3, y: -1}, label: "C"},
    on_the_line("C")).
g8_line_reading_receipt(87, 'IM-G8-U3-L13', test_a_point_against_a_line,
    _{kind: "point_against_line",
      line: _{form: "standard", a: 1, b: -9, c: 12},
      point: _{x: 0, y: _{n: -4, d: 3}}, label: "D"},
    on_the_line("D")).
g8_line_reading_receipt(87, 'IM-G8-U3-L13', test_a_point_against_a_line,
    _{kind: "point_against_line",
      line: _{form: "standard", a: 1, b: -9, c: 12},
      point: _{x: -3, y: 1}, label: "E"},
    off_the_line("E", "-12", "12")).
% correction 70, IM-G8-U4-L12: the intersection checked against both equations
g8_line_reading_receipt(70, 'IM-G8-U4-L12', test_a_point_against_a_line,
    _{kind: "point_against_line",
      line: _{form: "slope_intercept", slope: -2.4, intercept: 4.8},
      point: _{x: 0.75, y: 3}, label: "Han's line at the crossing"},
    on_the_line("Han's line at the crossing")).
g8_line_reading_receipt(70, 'IM-G8-U4-L12', test_a_point_against_a_line,
    _{kind: "point_against_line",
      line: _{form: "slope_intercept", slope: 3.2, intercept: 0.6},
      point: _{x: 0.75, y: 3}, label: "Jada's line at the crossing"},
    on_the_line("Jada's line at the crossing")).
% correction 65, IM-G8-U3-L8: the six candidates against the y-intercept of
% y = 3x - 8
g8_line_reading_receipt(65, 'IM-G8-U3-L8', intercepts_of_a_line,
    _{kind: "line_form",
      line: _{form: "slope_intercept", slope: 3, intercept: -8},
      name: "y = 3x - 8"},
    intercepts("y = 3x - 8", vertical(at("-8")), horizontal(at("8/3")))).
g8_line_reading_receipt(65, 'IM-G8-U3-L8', intercepts_of_a_line,
    _{kind: "line_form",
      line: _{form: "slope_intercept", slope: 4, intercept: -8},
      name: "A. y = 4x - 8"},
    intercepts("A. y = 4x - 8", vertical(at("-8")), horizontal(at("2")))).
g8_line_reading_receipt(65, 'IM-G8-U3-L8', intercepts_of_a_line,
    _{kind: "line_form",
      line: _{form: "slope_intercept", slope: 3, intercept: -9},
      name: "B. y = 3x - 9"},
    intercepts("B. y = 3x - 9", vertical(at("-9")), horizontal(at("3")))).
g8_line_reading_receipt(65, 'IM-G8-U3-L8', intercepts_of_a_line,
    _{kind: "line_form",
      line: _{form: "slope_intercept", slope: 5, intercept: -8},
      name: "D. y = -8 + 5x"},
    intercepts("D. y = -8 + 5x", vertical(at("-8")), horizontal(at("8/5")))).
g8_line_reading_receipt(65, 'IM-G8-U3-L8', intercepts_of_a_line,
    _{kind: "line_form",
      line: _{form: "slope_intercept", slope: -3, intercept: 8},
      name: "F. y = 8 - 3x"},
    intercepts("F. y = 8 - 3x", vertical(at("8")), horizontal(at("8/3")))).
% correction 84, IM-G8-U3-L12: the two lines with one intercept each
g8_line_reading_receipt(84, 'IM-G8-U3-L12', intercepts_of_a_line,
    _{kind: "line_form", line: _{form: "standard", a: 1, b: 0, c: -2},
      name: "x = -2"},
    intercepts("x = -2", vertical(none_the_line_is_vertical),
               horizontal(at("-2")))).
g8_line_reading_receipt(84, 'IM-G8-U3-L12', intercepts_of_a_line,
    _{kind: "line_form", line: _{form: "standard", a: 0, b: 1, c: 5},
      name: "y = 5"},
    intercepts("y = 5", vertical(at("5")),
               horizontal(none_the_line_is_horizontal))).
% correction 66, IM-G8-U3-L8: y = 2x against y = 2x - 7
g8_line_reading_receipt(66, 'IM-G8-U3-L8', intercepts_of_a_line,
    _{kind: "line_form",
      line: _{form: "slope_intercept", slope: 2, intercept: 0},
      name: "y = 2x"},
    intercepts("y = 2x", vertical(at("0")), horizontal(at("0")))).
g8_line_reading_receipt(66, 'IM-G8-U3-L8', intercepts_of_a_line,
    _{kind: "line_form",
      line: _{form: "slope_intercept", slope: 2, intercept: -7},
      name: "y = 2x - 7"},
    intercepts("y = 2x - 7", vertical(at("-7")), horizontal(at("7/2")))).
% correction 43, IM-G8-U4-L7: 6(u - 2) + 2 = ___, true for all values of u
g8_line_reading_receipt(43, 'IM-G8-U4-L7', complete_the_equation,
    _{kind: "equation_completion", unknown: "u", target: "every_value",
      known: _{op: "sum",
               terms: [_{op: "product",
                         factors: [_{op: "number", value: 6},
                                   _{op: "sum",
                                     terms: [_{op: "unknown"},
                                             _{op: "number", value: -2}]}]},
                       _{op: "number", value: 2}]},
      blank_side: _{op: "blank"}},
    completion_for_every_value("6u - 10")).
% correction 43: the same equation completed so it is true for no values
g8_line_reading_receipt(43, 'IM-G8-U4-L7', complete_the_equation,
    _{kind: "equation_completion", unknown: "u", target: "no_value",
      known: _{op: "sum",
               terms: [_{op: "product",
                         factors: [_{op: "number", value: 6},
                                   _{op: "sum",
                                     terms: [_{op: "unknown"},
                                             _{op: "number", value: -2}]}]},
                       _{op: "number", value: 2}]},
      blank_side: _{op: "blank"}},
    completion_for_no_value("6u - 9", any_constant_other_than(-10))).
% correction 44a, IM-G8-U4-L7: 3x + 6 = 3(x + ___), true for all values
g8_line_reading_receipt(44, 'IM-G8-U4-L7', complete_the_equation,
    _{kind: "equation_completion", unknown: "x", target: "every_value",
      known: _{op: "sum",
               terms: [_{op: "product",
                         factors: [_{op: "number", value: 3},
                                   _{op: "unknown"}]},
                       _{op: "number", value: 6}]},
      blank_side: _{op: "product",
                    factors: [_{op: "number", value: 3},
                              _{op: "sum", terms: [_{op: "unknown"},
                                                   _{op: "blank"}]}]}},
    completion_for_every_value("2")).
% correction 44a again, true for no values
g8_line_reading_receipt(44, 'IM-G8-U4-L7', complete_the_equation,
    _{kind: "equation_completion", unknown: "x", target: "no_value",
      known: _{op: "sum",
               terms: [_{op: "product",
                         factors: [_{op: "number", value: 3},
                                   _{op: "unknown"}]},
                       _{op: "number", value: 6}]},
      blank_side: _{op: "product",
                    factors: [_{op: "number", value: 3},
                              _{op: "sum", terms: [_{op: "unknown"},
                                                   _{op: "blank"}]}]}},
    completion_for_no_value("3", any_constant_other_than(2))).
% correction 44b: x - 2 = -(___ - x), true for all values
g8_line_reading_receipt(44, 'IM-G8-U4-L7', complete_the_equation,
    _{kind: "equation_completion", unknown: "x", target: "every_value",
      known: _{op: "sum", terms: [_{op: "unknown"},
                                  _{op: "number", value: -2}]},
      blank_side: _{op: "product",
                    factors: [_{op: "number", value: -1},
                              _{op: "sum",
                                terms: [_{op: "blank"},
                                        _{op: "product",
                                          factors: [_{op: "number", value: -1},
                                                    _{op: "unknown"}]}]}]}},
    completion_for_every_value("2")).
% correction 44c: (15x - 10)/5 = ___ - 2, true for all values. The blank is
% an expression, not a number, and comes back as 3x.
g8_line_reading_receipt(44, 'IM-G8-U4-L7', complete_the_equation,
    _{kind: "equation_completion", unknown: "x", target: "every_value",
      known: _{op: "quotient",
               dividend: _{op: "sum",
                           terms: [_{op: "product",
                                     factors: [_{op: "number", value: 15},
                                               _{op: "unknown"}]},
                                   _{op: "number", value: -10}]},
               divisor: 5},
      blank_side: _{op: "sum", terms: [_{op: "blank"},
                                       _{op: "number", value: -2}]}},
    completion_for_every_value("3x")).

% ==========================================================================
% 7. CHECK
% ==========================================================================

check_g8_linear_equation_reading_and_authoring :-
    check_receipts,
    check_the_intercept_selection,
    check_the_completions_hold,
    check_negative,
    format('g8_linear_equation_reading_and_authoring: all checks ok~n').

check_receipts :-
    findall(Correction-Doing-Result,
            ( g8_line_reading_receipt(Correction, _, Doing, Json, Expected),
              g8_line_reading_from_json(Json, Figure),
              run_g8_line_reading(Doing, Figure, Outcome, _),
              outcome_property(Outcome, result(Result)),
              Result = Expected
            ), Rows),
    findall(C, g8_line_reading_receipt(C, _, _, _, _), All),
    length(All, Total), length(Rows, Passed),
    Total =:= Passed,
    format('  receipts: ~w/~w printed rows run~n', [Passed, Total]),
    forall(member(Correction-Doing-Result, Rows),
           format('    correction ~w  ~w -> ~q~n',
                  [Correction, Doing, Result])).

check_the_intercept_selection :-
    % Correction 65 asks which of six equations share the y-intercept of
    % y = 3x - 8. Running all six and keeping the ones that answer -8 gives
    % A, D and E, which is the printed solution.
    findall(Name,
            ( member(Name-Line,
                     ["A"-_{form: "slope_intercept", slope: 4, intercept: -8},
                      "B"-_{form: "slope_intercept", slope: 3, intercept: -9},
                      "C"-_{form: "slope_intercept", slope: 3, intercept: 8},
                      "D"-_{form: "slope_intercept", slope: 5, intercept: -8},
                      "E"-_{form: "slope_intercept", slope: 2, intercept: -8},
                      "F"-_{form: "slope_intercept", slope: -3, intercept: 8}]),
              g8_line_reading_from_json(
                  _{kind: "line_form", line: Line, name: Name}, Figure),
              run_g8_line_reading(intercepts_of_a_line, Figure, Outcome, _),
              outcome_property(Outcome, result(intercepts(_, vertical(at("-8")),
                                                          _)))
            ), Selected),
    Selected == ["A", "D", "E"],
    format('  correction 65: A, D and E share the vertical intercept -8, which is the printed solution~n').

check_the_completions_hold :-
    % 3x + 6 = 3(x + 2) is true for every value: the balance pilot's verdict
    % on the completed equation would be every_number, and the two sides read
    % here as the same coefficient and the same constant.
    g8_line_reading_from_json(
        _{kind: "equation_completion", unknown: "x", target: "every_value",
          known: _{op: "sum",
                   terms: [_{op: "product",
                             factors: [_{op: "number", value: 3},
                                       _{op: "unknown"}]},
                           _{op: "number", value: 6}]},
          blank_side: _{op: "product",
                        factors: [_{op: "number", value: 3},
                                  _{op: "sum", terms: [_{op: "unknown"},
                                                       _{op: "blank"}]}]}},
        Figure),
    run_g8_line_reading(complete_the_equation, Figure, Outcome, _),
    outcome_property(Outcome, validity(correct)),
    format('  the completion 2 substituted back into 3(x + _) returns 3x + 6, the known side~n').

check_negative :-
    % A blank appearing twice is refused at decode: this module solves for one
    % blank and says so.
    \+ g8_line_reading_from_json(
           _{kind: "equation_completion", unknown: "x", target: "every_value",
             known: _{op: "unknown"},
             blank_side: _{op: "sum", terms: [_{op: "blank"},
                                              _{op: "blank"}]}}, _),
    % A blank multiplied by zero never reaches the equation, and the run
    % refuses rather than dividing by zero.
    g8_line_reading_from_json(
        _{kind: "equation_completion", unknown: "x", target: "every_value",
          known: _{op: "unknown"},
          blank_side: _{op: "sum",
                        terms: [_{op: "unknown"},
                                _{op: "product",
                                  factors: [_{op: "number", value: 0},
                                            _{op: "blank"}]}]}}, Cancels),
    run_g8_line_reading(complete_the_equation, Cancels, Outcome, _),
    outcome_property(Outcome, result(refused(the_blank_does_not_reach_the_equation))),
    % A line with both coefficients zero is not a line.
    \+ g8_line_reading_from_json(
           _{kind: "line_form", line: _{form: "standard", a: 0, b: 0, c: 1},
             name: "not a line"}, _),
    format('  negative tests: two blanks and a cancelled blank refuse; a zero-by-zero standard form is not a line~n').

outcome_property(action_outcome(_, Props), Property) :-
    memberchk(Property, Props).
