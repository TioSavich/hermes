:- encoding(utf8).
/** <module> Grade 8 draft: bringing a printed equation into two-sided normal form
 *
 * WHAT THIS IS. A draft automaton for the step that stands between the
 * corrected grade 8 unit 4 tasks and the atom that already solves them. The
 * published pilot `g8_linear_equation_balance` takes an equation already
 * written as a·x + b = c·x + d. Almost nothing in unit 4 is printed that way:
 * the round-two corrections recovered `8(x - 3) + 7 = 2x(4 - 17)`,
 * `-(5/6)(8 + 5b) = 75 + (5/3)b`, `(12 + 6x)/3 = (5 - 9)/2`, and twenty-odd
 * more with parentheses, fraction bars, and like terms on both sides. This
 * module performs exactly the missing act — distribute, collect, divide
 * through — and hands the four numbers to the published atom.
 *
 * WHY IT IS ITS OWN AUTOMATON AND NOT A PARSER. The input is an expression
 * TREE, not a string. Reading `-(5/6)(8 + 5b)` off a page is the extraction
 * lane's work and is already done elsewhere; the doing this module names is
 * the algebra a student performs after reading, and each act in it is a named
 * state with its own transition. A student who distributes 8 over x but not
 * over -3 has taken one of these transitions and refused the other; the trace
 * shows which.
 *
 * WHAT IT HANDS OFF. `normalize_to_two_sided_form` returns the JSON dict the
 * published pilot's own contract accepts, so the receipts below run BOTH
 * modules: this one to normalize, `g8_linear_equation_balance` to solve. The
 * solution and its classification (one value, no value, every value) come
 * from the published atom, never from here.
 *
 * DEFORMATION PARTNER. `distribute_over_the_first_term_only` is the printed
 * error shape of the parentheses cue: the multiplier reaches the first
 * summand and stops. The research corpus attests the cue itself at row 38084
 * (students associate the visual cue of parentheses with the distributive
 * procedure and apply it where it does not belong); the failure to carry the
 * multiplier across every summand is the same cue read as a local rather
 * than a global instruction. The partner is offered as a deformation, not as
 * a diagnosis of any student.
 *
 * QUARANTINE. Nothing imports this module. It is a draft under
 * `.superpowers/sdd/g8-round2/`, not a tracked automaton; it renames nothing
 * and its rows are vetoable one by one.
 * Check: `check_g8_linear_expression_normalizer/0`.
 */

:- module(g8_linear_expression_normalizer,
          [ run_g8_normalizer/4,
            g8_normalizer_from_json/2,
            g8_normalizer_states/1,
            g8_normalizer_state_label/4,
            g8_normalizer_summary/1,
            g8_normalizer_receipt/5,
            check_g8_linear_expression_normalizer/0
          ]).

:- use_module(strategies('abstraction/g8_quantity_input'),
              [ g8_quantity/2, g8_rational_text/2 ]).
:- use_module(strategies('abstraction/g8_linear_equation_balance'),
              [ run_g8_linear_equation/4, g8_linear_equation_from_json/2 ]).

% ==========================================================================
% 1. INPUT CONTRACT
%
%   {"kind":"printed_linear_equation","unknown":"x",
%    "left":{"op":"sum","terms":[
%              {"op":"product","factors":[{"op":"number","value":8},
%                 {"op":"sum","terms":[{"op":"unknown"},
%                                      {"op":"number","value":-3}]}]},
%              {"op":"number","value":7}]},
%    "right":{"op":"product","factors":[
%              {"op":"product","factors":[{"op":"number","value":2},
%                                         {"op":"unknown"}]},
%              {"op":"sum","terms":[{"op":"number","value":4},
%                                   {"op":"number","value":-17}]}]}}
%
% Five node kinds and no more: number, unknown, sum, product, quotient. A
% quotient's divisor must be a number — an unknown in a denominator is not a
% linear equation and is refused by name rather than mishandled.
% ==========================================================================

g8_normalizer_input_contract(
    '{\"kind\":\"printed_linear_equation\",\"unknown\":\"string\",\"left\":\"node\",\"right\":\"node\"}',
    '{\"kind\":\"printed_linear_equation\",\"unknown\":\"x\",\"left\":{\"op\":\"number\",\"value\":5},\"right\":{\"op\":\"unknown\"}}').

g8_normalizer_from_json(Dict, printed(Unknown, Left, Right)) :-
    is_dict(Dict),
    get_dict(kind, Dict, "printed_linear_equation"),
    get_dict(unknown, Dict, Unknown0),
    ( string(Unknown0) -> Unknown = Unknown0 ; atom_string(Unknown0, Unknown) ),
    get_dict(left, Dict, L), get_dict(right, Dict, R),
    node_of(L, Left), node_of(R, Right).

node_of(Dict, number(V)) :-
    get_dict(op, Dict, "number"), !,
    get_dict(value, Dict, V0), g8_quantity(V0, V).
node_of(Dict, unknown) :-
    get_dict(op, Dict, "unknown"), !.
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

% ==========================================================================
% 2. STATES
% ==========================================================================

g8_normalizer_states(
    [ q_read_the_printed_equation,
      q_carry_the_multiplier_across_every_summand,
      q_divide_every_summand_by_the_divisor,
      q_collect_the_unknown_terms,
      q_collect_the_constant_terms,
      q_report_two_sided_normal_form,
      q_refuse_a_nonlinear_expression,
      q_stop_the_multiplier_at_the_first_summand ]).

% g8_normalizer_state_label(State, Tradition, Label, Citation).
g8_normalizer_state_label(q_carry_the_multiplier_across_every_summand,
    illustrative_mathematics,
    "using the distributive property to write an equivalent expression",
    "IM Grade 8 Unit 4 Lesson 4, Solving Equations with Parentheses").
g8_normalizer_state_label(q_carry_the_multiplier_across_every_summand, ccss,
    "apply properties of operations to generate equivalent expressions",
    "CCSS 8.EE.C.7.b, via IM Grade 8 Unit 4 Lesson 4").
g8_normalizer_state_label(q_collect_the_unknown_terms,
    illustrative_mathematics,
    "collecting like terms",
    "IM Grade 8 Unit 4 Lesson 5, Strategic Solving").
g8_normalizer_state_label(q_divide_every_summand_by_the_divisor,
    illustrative_mathematics,
    "a fraction bar over a sum divides each part of the sum",
    "IM Grade 8 Unit 4 Lesson 4, Activity 4.3, the (12 + 6x)/3 row").
g8_normalizer_state_label(q_report_two_sided_normal_form, provisional,
    "the equation written as a coefficient and a constant on each side",
    "provisional; the shape is the published balance pilot's own input contract").
g8_normalizer_state_label(q_refuse_a_nonlinear_expression, provisional,
    "the unknown appears where a linear equation cannot carry it",
    "provisional; no community label sourced for this refusal").
g8_normalizer_state_label(q_stop_the_multiplier_at_the_first_summand,
    research_corpus,
    "the parentheses cue read as a local instruction",
    "research corpus row 38084, Students associate the visual cue of parentheses directly with the distributive procedure").

% ==========================================================================
% 3. TRANSITIONS
% ==========================================================================

g8_normalizer_transition(normalize_to_two_sided_form,
    q_read_the_printed_equation, carry_the_multiplier_across_every_summand,
    q_carry_the_multiplier_across_every_summand).
g8_normalizer_transition(normalize_to_two_sided_form,
    q_carry_the_multiplier_across_every_summand,
    divide_every_summand_by_the_divisor,
    q_divide_every_summand_by_the_divisor).
g8_normalizer_transition(normalize_to_two_sided_form,
    q_divide_every_summand_by_the_divisor, collect_the_unknown_terms,
    q_collect_the_unknown_terms).
g8_normalizer_transition(normalize_to_two_sided_form,
    q_collect_the_unknown_terms, collect_the_constant_terms,
    q_collect_the_constant_terms).
g8_normalizer_transition(normalize_to_two_sided_form,
    q_collect_the_constant_terms, report_two_sided_normal_form,
    q_report_two_sided_normal_form).
g8_normalizer_transition(normalize_to_two_sided_form,
    q_carry_the_multiplier_across_every_summand, refuse_a_nonlinear_expression,
    q_refuse_a_nonlinear_expression).
g8_normalizer_transition(normalize_and_solve,
    q_report_two_sided_normal_form, hand_the_four_numbers_to_the_balance_atom,
    q_report_two_sided_normal_form).
g8_normalizer_transition(distribute_over_the_first_term_only,
    q_read_the_printed_equation, stop_the_multiplier_at_the_first_summand,
    q_stop_the_multiplier_at_the_first_summand).

% ==========================================================================
% 4. THE RUN
% ==========================================================================

run_g8_normalizer(normalize_to_two_sided_form, printed(Unknown, Left, Right),
                  Outcome, Trace) :-
    (   linear_form(Left, A, B), linear_form(Right, C, D)
    ->  g8_rational_text(A, AT), g8_rational_text(B, BT),
        g8_rational_text(C, CT), g8_rational_text(D, DT),
        Json = _{kind: "linear_equation_two_sided", unknown: Unknown,
                 left: _{coefficient: A, constant: B},
                 right: _{coefficient: C, constant: D}},
        Outcome = action_outcome(
            normalize_to_two_sided_form,
            [ classification(productive),
              cluster(g8_one_variable_linear_equations),
              automaton_state(q_report_two_sided_normal_form),
              vocabulary([distributive_property, like_terms, coefficient,
                          constant, equivalent_expression]),
              input(printed(Unknown, Left, Right)),
              result(two_sided_form(AT, BT, CT, DT)),
              expected(two_sided_form(AT, BT, CT, DT)),
              handoff(Json),
              invariant(every_summand_meets_every_multiplier),
              validity(correct) ]),
        Trace = [ carry_the_multiplier_across_every_summand,
                  divide_every_summand_by_the_divisor,
                  collect_the_unknown_terms(AT, CT),
                  collect_the_constant_terms(BT, DT),
                  report_two_sided_normal_form(AT, BT, CT, DT) ]
    ;   Outcome = action_outcome(
            normalize_to_two_sided_form,
            [ classification(refusal),
              cluster(g8_one_variable_linear_equations),
              automaton_state(q_refuse_a_nonlinear_expression),
              vocabulary([linear_equation, unknown, degree]),
              input(printed(Unknown, Left, Right)),
              result(refused(not_linear_in_the_unknown)),
              refusal(refusal{kind: "not_linear_in_the_unknown",
                              unknown: Unknown}),
              validity(refused) ]),
        Trace = [ refuse_a_nonlinear_expression(Unknown) ]
    ).
run_g8_normalizer(normalize_and_solve, printed(Unknown, Left, Right),
                  Outcome, Trace) :-
    run_g8_normalizer(normalize_to_two_sided_form,
                      printed(Unknown, Left, Right),
                      action_outcome(_, Properties), _),
    memberchk(handoff(Json), Properties),
    memberchk(result(two_sided_form(AT, BT, CT, DT)), Properties),
    % The published atom decodes its own JSON and returns its own verdict.
    g8_linear_equation_from_json(Json, Equation),
    run_g8_linear_equation(balance_preserving_two_sided_solution, Equation,
                           action_outcome(_, BalanceProperties), _),
    memberchk(result(Verdict), BalanceProperties),
    memberchk(validity(Validity), BalanceProperties),
    Outcome = action_outcome(
        normalize_and_solve,
        [ classification(productive),
          cluster(g8_one_variable_linear_equations),
          automaton_state(q_report_two_sided_normal_form),
          vocabulary([distributive_property, like_terms, balanced_moves,
                      solution_set]),
          input(printed(Unknown, Left, Right)),
          result(Verdict),
          expected(Verdict),
          normal_form(two_sided_form(AT, BT, CT, DT)),
          answered_by(g8_linear_equation_balance),
          invariant(the_published_atom_decides_the_solution_set),
          validity(Validity) ]),
    Trace = [ report_two_sided_normal_form(AT, BT, CT, DT),
              hand_the_four_numbers_to_the_balance_atom(Verdict) ].
run_g8_normalizer(distribute_over_the_first_term_only,
                  printed(Unknown, Left, Right), Outcome, Trace) :-
    % The deformation: the multiplier reaches the first summand and stops.
    ( truncated_form(Left, A, B) -> true ; linear_form(Left, A, B) ),
    ( truncated_form(Right, C, D) -> true ; linear_form(Right, C, D) ),
    linear_form(Left, A1, B1), linear_form(Right, C1, D1),
    \+ ( A =:= A1, B =:= B1, C =:= C1, D =:= D1 ),
    g8_rational_text(A, AT), g8_rational_text(B, BT),
    g8_rational_text(C, CT), g8_rational_text(D, DT),
    g8_rational_text(A1, AT1), g8_rational_text(B1, BT1),
    g8_rational_text(C1, CT1), g8_rational_text(D1, DT1),
    Outcome = action_outcome(
        distribute_over_the_first_term_only,
        [ classification(deformation),
          cluster(g8_one_variable_linear_equations),
          automaton_state(q_stop_the_multiplier_at_the_first_summand),
          vocabulary([distributive_property, parentheses, summand]),
          input(printed(Unknown, Left, Right)),
          result(two_sided_form(AT, BT, CT, DT)),
          expected(two_sided_form(AT1, BT1, CT1, DT1)),
          deforms(normalize_to_two_sided_form),
          attested_by('research corpus row 38084'),
          validity(incorrect) ]),
    Trace = [ stop_the_multiplier_at_the_first_summand(AT, BT, CT, DT) ].

%!  linear_form(+Node, -Coefficient, -Constant) is semidet.
%
%   Every summand meets every multiplier. Exact rational arithmetic
%   throughout; a product of two unknown-carrying factors fails rather than
%   silently dropping a degree.
linear_form(number(V), 0, V).
linear_form(unknown, 1, 0).
linear_form(sum(Nodes), A, B) :-
    foldl(add_linear, Nodes, 0-0, A-B).
linear_form(product(Nodes), A, B) :-
    foldl(multiply_linear, Nodes, 0-1, A-B).
linear_form(quotient(Node, Divisor), A, B) :-
    linear_form(Node, A0, B0),
    A is A0 rdiv Divisor,
    B is B0 rdiv Divisor.

add_linear(Node, A0-B0, A-B) :-
    linear_form(Node, A1, B1),
    A is A0 + A1, B is B0 + B1.

multiply_linear(Node, A0-B0, A-B) :-
    linear_form(Node, A1, B1),
    ( A0 =:= 0 -> true ; A1 =:= 0 ),   % never two unknown-carrying factors
    A is A0 * B1 + A1 * B0,
    B is B0 * B1.

%!  truncated_form(+Node, -Coefficient, -Constant) is semidet.
%
%   The same walk with one act withheld: where a numeric multiplier meets a
%   sum, only the sum's first summand is multiplied.
truncated_form(sum(Nodes), A, B) :-
    foldl(add_truncated, Nodes, 0-0, A-B).
truncated_form(product([number(K), sum([First|Rest])]), A, B) :-
    linear_form(First, A1, B1),
    foldl(add_linear, Rest, 0-0, A2-B2),
    A is K * A1 + A2,
    B is K * B1 + B2.
truncated_form(quotient(Node, Divisor), A, B) :-
    truncated_form(Node, A0, B0),
    A is A0 rdiv Divisor, B is B0 rdiv Divisor.

add_truncated(Node, A0-B0, A-B) :-
    ( truncated_form(Node, A1, B1) -> true ; linear_form(Node, A1, B1) ),
    A is A0 + A1, B is B0 + B1.

% ==========================================================================
% 5. SELF-SUMMARY
% ==========================================================================

g8_normalizer_summary(
    summary{ module: g8_linear_expression_normalizer,
             status: draft_for_quarantine,
             generated: false,
             grade: 8,
             cluster: g8_one_variable_linear_equations,
             doings: [ normalize_to_two_sided_form,
                       normalize_and_solve,
                       distribute_over_the_first_term_only ],
             verification: [every_summand_meets_every_multiplier,
                            the_published_atom_decides_the_solution_set],
             arithmetic: exact_rational,
             hands_off_to: g8_linear_equation_balance,
             deformation_partners: [distribute_over_the_first_term_only],
             imported_by: none,
             answers: 'the printed grade 8 unit 4 equations, which the published balance atom cannot decode' }).

% ==========================================================================
% 6. RECEIPTS
%
% g8_normalizer_receipt(Correction, Lesson, Doing, Json, Expected).
% Every Json below is the expression tree of an equation PRINTED in a
% round-two verified correction. Corrections 37, 38, 40, 41, 42, 43, 45, 46
% and 75 supply them; the count per correction is in the report.
% ==========================================================================

% correction 37, IM-G8-U4-L4: (12 + 6x)/3 = (5 - 9)/2
g8_normalizer_receipt(37, 'IM-G8-U4-L4', normalize_and_solve,
    _{kind: "printed_linear_equation", unknown: "x",
      left: _{op: "quotient",
              dividend: _{op: "sum",
                          terms: [_{op: "number", value: 12},
                                  _{op: "product",
                                    factors: [_{op: "number", value: 6},
                                              _{op: "unknown"}]}]},
              divisor: 3},
      right: _{op: "quotient",
               dividend: _{op: "sum",
                           terms: [_{op: "number", value: 5},
                                   _{op: "number", value: -9}]},
               divisor: 2}},
    one_solution("x", "-3")).
% correction 37, IM-G8-U4-L4: x - 4 = (1/3)(6x - 54)
g8_normalizer_receipt(37, 'IM-G8-U4-L4', normalize_and_solve,
    _{kind: "printed_linear_equation", unknown: "x",
      left: _{op: "sum", terms: [_{op: "unknown"},
                                 _{op: "number", value: -4}]},
      right: _{op: "product",
               factors: [_{op: "number", value: _{n: 1, d: 3}},
                         _{op: "sum",
                           terms: [_{op: "product",
                                     factors: [_{op: "number", value: 6},
                                               _{op: "unknown"}]},
                                   _{op: "number", value: -54}]}]}},
    one_solution("x", "14")).
% correction 37, IM-G8-U4-L4: -(3x - 12) = 9x - 4
g8_normalizer_receipt(37, 'IM-G8-U4-L4', normalize_and_solve,
    _{kind: "printed_linear_equation", unknown: "x",
      left: _{op: "product",
              factors: [_{op: "number", value: -1},
                        _{op: "sum",
                          terms: [_{op: "product",
                                    factors: [_{op: "number", value: 3},
                                              _{op: "unknown"}]},
                                  _{op: "number", value: -12}]}]},
      right: _{op: "sum",
               terms: [_{op: "product",
                         factors: [_{op: "number", value: 9},
                                   _{op: "unknown"}]},
                       _{op: "number", value: -4}]}},
    one_solution("x", "4/3")).
% correction 38, IM-G8-U4-L4: 8(x - 3) + 7 = 2x(4 - 17)
g8_normalizer_receipt(38, 'IM-G8-U4-L4', normalize_and_solve,
    _{kind: "printed_linear_equation", unknown: "x",
      left: _{op: "sum",
              terms: [_{op: "product",
                        factors: [_{op: "number", value: 8},
                                  _{op: "sum",
                                    terms: [_{op: "unknown"},
                                            _{op: "number", value: -3}]}]},
                      _{op: "number", value: 7}]},
      right: _{op: "product",
               factors: [_{op: "product",
                           factors: [_{op: "number", value: 2},
                                     _{op: "unknown"}]},
                         _{op: "sum",
                           terms: [_{op: "number", value: 4},
                                   _{op: "number", value: -17}]}]}},
    one_solution("x", "1/2")).
% correction 40, IM-G8-U4-L5: (1/2)(7x - 6) = 6x - 10
g8_normalizer_receipt(40, 'IM-G8-U4-L5', normalize_and_solve,
    _{kind: "printed_linear_equation", unknown: "x",
      left: _{op: "product",
              factors: [_{op: "number", value: _{n: 1, d: 2}},
                        _{op: "sum",
                          terms: [_{op: "product",
                                    factors: [_{op: "number", value: 7},
                                              _{op: "unknown"}]},
                                  _{op: "number", value: -6}]}]},
      right: _{op: "sum",
               terms: [_{op: "product",
                         factors: [_{op: "number", value: 6},
                                   _{op: "unknown"}]},
                       _{op: "number", value: -10}]}},
    one_solution("x", "14/5")).
% correction 41, IM-G8-U4-L6: -(1/2)(-8 + 5x) = -20
g8_normalizer_receipt(41, 'IM-G8-U4-L6', normalize_and_solve,
    _{kind: "printed_linear_equation", unknown: "x",
      left: _{op: "product",
              factors: [_{op: "number", value: _{n: -1, d: 2}},
                        _{op: "sum",
                          terms: [_{op: "number", value: -8},
                                  _{op: "product",
                                    factors: [_{op: "number", value: 5},
                                              _{op: "unknown"}]}]}]},
      right: _{op: "number", value: -20}},
    one_solution("x", "48/5")).
% correction 42, IM-G8-U4-L6 card A: -(5/6)(8 + 5b) = 75 + (5/3)b
g8_normalizer_receipt(42, 'IM-G8-U4-L6', normalize_and_solve,
    _{kind: "printed_linear_equation", unknown: "b",
      left: _{op: "product",
              factors: [_{op: "number", value: _{n: -5, d: 6}},
                        _{op: "sum",
                          terms: [_{op: "number", value: 8},
                                  _{op: "product",
                                    factors: [_{op: "number", value: 5},
                                              _{op: "unknown"}]}]}]},
      right: _{op: "sum",
               terms: [_{op: "number", value: 75},
                       _{op: "product",
                         factors: [_{op: "number", value: _{n: 5, d: 3}},
                                   _{op: "unknown"}]}]}},
    one_solution("b", "-14")).
% correction 42, IM-G8-U4-L6 card D: 2(4k + 3) - 13 = 2(18 - k) - 13
g8_normalizer_receipt(42, 'IM-G8-U4-L6', normalize_and_solve,
    _{kind: "printed_linear_equation", unknown: "k",
      left: _{op: "sum",
              terms: [_{op: "product",
                        factors: [_{op: "number", value: 2},
                                  _{op: "sum",
                                    terms: [_{op: "product",
                                              factors: [_{op: "number", value: 4},
                                                        _{op: "unknown"}]},
                                            _{op: "number", value: 3}]}]},
                      _{op: "number", value: -13}]},
      right: _{op: "sum",
               terms: [_{op: "product",
                         factors: [_{op: "number", value: 2},
                                   _{op: "sum",
                                     terms: [_{op: "number", value: 18},
                                             _{op: "product",
                                               factors: [_{op: "number", value: -1},
                                                         _{op: "unknown"}]}]}]},
                       _{op: "number", value: -13}]}},
    one_solution("k", "3")).
% correction 42, IM-G8-U4-L6 card F: 3(c - 1) + 2(3c + 1) = -(3c + 1)
g8_normalizer_receipt(42, 'IM-G8-U4-L6', normalize_and_solve,
    _{kind: "printed_linear_equation", unknown: "c",
      left: _{op: "sum",
              terms: [_{op: "product",
                        factors: [_{op: "number", value: 3},
                                  _{op: "sum",
                                    terms: [_{op: "unknown"},
                                            _{op: "number", value: -1}]}]},
                      _{op: "product",
                        factors: [_{op: "number", value: 2},
                                  _{op: "sum",
                                    terms: [_{op: "product",
                                              factors: [_{op: "number", value: 3},
                                                        _{op: "unknown"}]},
                                            _{op: "number", value: 1}]}]}]},
      right: _{op: "product",
               factors: [_{op: "number", value: -1},
                         _{op: "sum",
                           terms: [_{op: "product",
                                     factors: [_{op: "number", value: 3},
                                               _{op: "unknown"}]},
                                   _{op: "number", value: 1}]}]}},
    one_solution("c", "0")).
% correction 43, IM-G8-U4-L7: 2t + 6 = 2(t + 3), true for every value
g8_normalizer_receipt(43, 'IM-G8-U4-L7', normalize_and_solve,
    _{kind: "printed_linear_equation", unknown: "t",
      left: _{op: "sum",
              terms: [_{op: "product",
                        factors: [_{op: "number", value: 2},
                                  _{op: "unknown"}]},
                      _{op: "number", value: 6}]},
      right: _{op: "product",
               factors: [_{op: "number", value: 2},
                         _{op: "sum",
                           terms: [_{op: "unknown"},
                                   _{op: "number", value: 3}]}]}},
    every_number("t")).
% correction 43, IM-G8-U4-L7: 3(n + 1) = 3n + 1, true for no value
g8_normalizer_receipt(43, 'IM-G8-U4-L7', normalize_and_solve,
    _{kind: "printed_linear_equation", unknown: "n",
      left: _{op: "product",
              factors: [_{op: "number", value: 3},
                        _{op: "sum", terms: [_{op: "unknown"},
                                             _{op: "number", value: 1}]}]},
      right: _{op: "sum",
               terms: [_{op: "product",
                         factors: [_{op: "number", value: 3},
                                   _{op: "unknown"}]},
                       _{op: "number", value: 1}]}},
    no_solution("n")).
% correction 43, IM-G8-U4-L7: (1/4)(20d + 4) = 5d, true for no value
g8_normalizer_receipt(43, 'IM-G8-U4-L7', normalize_and_solve,
    _{kind: "printed_linear_equation", unknown: "d",
      left: _{op: "product",
              factors: [_{op: "number", value: _{n: 1, d: 4}},
                        _{op: "sum",
                          terms: [_{op: "product",
                                    factors: [_{op: "number", value: 20},
                                              _{op: "unknown"}]},
                                  _{op: "number", value: 4}]}]},
      right: _{op: "product",
               factors: [_{op: "number", value: 5}, _{op: "unknown"}]}},
    no_solution("d")).
% correction 43, IM-G8-U4-L7: y * -6 * -3 = 2 * y * 9, true for every value
g8_normalizer_receipt(43, 'IM-G8-U4-L7', normalize_and_solve,
    _{kind: "printed_linear_equation", unknown: "y",
      left: _{op: "product",
              factors: [_{op: "unknown"}, _{op: "number", value: -6},
                        _{op: "number", value: -3}]},
      right: _{op: "product",
               factors: [_{op: "number", value: 2}, _{op: "unknown"},
                         _{op: "number", value: 9}]}},
    every_number("y")).
% correction 46, IM-G8-U4-L8: 12x + 6(4x + 3) = 3(2(6x + 4) - 2)
g8_normalizer_receipt(46, 'IM-G8-U4-L8', normalize_and_solve,
    _{kind: "printed_linear_equation", unknown: "x",
      left: _{op: "sum",
              terms: [_{op: "product",
                        factors: [_{op: "number", value: 12},
                                  _{op: "unknown"}]},
                      _{op: "product",
                        factors: [_{op: "number", value: 6},
                                  _{op: "sum",
                                    terms: [_{op: "product",
                                              factors: [_{op: "number", value: 4},
                                                        _{op: "unknown"}]},
                                            _{op: "number", value: 3}]}]}]},
      right: _{op: "product",
               factors: [_{op: "number", value: 3},
                         _{op: "sum",
                           terms: [_{op: "product",
                                     factors: [_{op: "number", value: 2},
                                               _{op: "sum",
                                                 terms: [_{op: "product",
                                                           factors: [_{op: "number", value: 6},
                                                                     _{op: "unknown"}]},
                                                         _{op: "number", value: 4}]}]},
                                   _{op: "number", value: -2}]}]}},
    every_number("x")).
% correction 75, IM-G8-U4-L3: 14a = 2(a - 3), the equation Noah and Lin share
g8_normalizer_receipt(75, 'IM-G8-U4-L3', normalize_and_solve,
    _{kind: "printed_linear_equation", unknown: "a",
      left: _{op: "product",
              factors: [_{op: "number", value: 14}, _{op: "unknown"}]},
      right: _{op: "product",
               factors: [_{op: "number", value: 2},
                         _{op: "sum", terms: [_{op: "unknown"},
                                              _{op: "number", value: -3}]}]}},
    one_solution("a", "-1/2")).
% correction 75, IM-G8-U4-L3: 15 - 10x = 5(x + 9), Elena's equation
g8_normalizer_receipt(75, 'IM-G8-U4-L3', normalize_and_solve,
    _{kind: "printed_linear_equation", unknown: "x",
      left: _{op: "sum",
              terms: [_{op: "number", value: 15},
                      _{op: "product",
                        factors: [_{op: "number", value: -10},
                                  _{op: "unknown"}]}]},
      right: _{op: "product",
               factors: [_{op: "number", value: 5},
                         _{op: "sum", terms: [_{op: "unknown"},
                                              _{op: "number", value: 9}]}]}},
    one_solution("x", "-2")).
% correction 75, IM-G8-U4-L3: 3x - 8 = 4(x + 5), Diego's equation
g8_normalizer_receipt(75, 'IM-G8-U4-L3', normalize_and_solve,
    _{kind: "printed_linear_equation", unknown: "x",
      left: _{op: "sum",
              terms: [_{op: "product",
                        factors: [_{op: "number", value: 3},
                                  _{op: "unknown"}]},
                      _{op: "number", value: -8}]},
      right: _{op: "product",
               factors: [_{op: "number", value: 4},
                         _{op: "sum", terms: [_{op: "unknown"},
                                              _{op: "number", value: 5}]}]}},
    one_solution("x", "-28")).
% correction 45, IM-G8-U4-L8, the three cards this lesson asks students to
% sort. The run decides which card carries which solution set.
g8_normalizer_receipt(45, 'IM-G8-U4-L8', normalize_and_solve,
    _{kind: "printed_linear_equation", unknown: "x",
      left: _{op: "sum",
              terms: [_{op: "product",
                        factors: [_{op: "number", value: 12},
                                  _{op: "sum", terms: [_{op: "unknown"},
                                                       _{op: "number", value: -3}]}]},
                      _{op: "number", value: 18}]},
      right: _{op: "product",
               factors: [_{op: "number", value: 6},
                         _{op: "sum",
                           terms: [_{op: "product",
                                     factors: [_{op: "number", value: 2},
                                               _{op: "unknown"}]},
                                   _{op: "number", value: -3}]}]}},
    every_number("x")).
g8_normalizer_receipt(45, 'IM-G8-U4-L8', normalize_and_solve,
    _{kind: "printed_linear_equation", unknown: "x",
      left: _{op: "sum",
              terms: [_{op: "product",
                        factors: [_{op: "number", value: 12},
                                  _{op: "sum", terms: [_{op: "unknown"},
                                                       _{op: "number", value: -3}]}]},
                      _{op: "number", value: 18}]},
      right: _{op: "product",
               factors: [_{op: "number", value: 4},
                         _{op: "sum",
                           terms: [_{op: "product",
                                     factors: [_{op: "number", value: 3},
                                               _{op: "unknown"}]},
                                   _{op: "number", value: -3}]}]}},
    no_solution("x")).
g8_normalizer_receipt(45, 'IM-G8-U4-L8', normalize_and_solve,
    _{kind: "printed_linear_equation", unknown: "x",
      left: _{op: "sum",
              terms: [_{op: "product",
                        factors: [_{op: "number", value: 12},
                                  _{op: "sum", terms: [_{op: "unknown"},
                                                       _{op: "number", value: -3}]}]},
                      _{op: "number", value: 18}]},
      right: _{op: "product",
               factors: [_{op: "number", value: 4},
                         _{op: "sum",
                           terms: [_{op: "product",
                                     factors: [_{op: "number", value: 2},
                                               _{op: "unknown"}]},
                                   _{op: "number", value: -3}]}]}},
    one_solution("x", "3/2")).

% ==========================================================================
% 7. CHECK
% ==========================================================================

check_g8_linear_expression_normalizer :-
    check_receipts,
    check_the_deformation,
    check_negative,
    format('g8_linear_expression_normalizer: all checks ok~n').

check_receipts :-
    findall(Correction-Lesson-Result,
            ( g8_normalizer_receipt(Correction, Lesson, Doing, Json, Expected),
              g8_normalizer_from_json(Json, Printed),
              run_g8_normalizer(Doing, Printed, Outcome, _),
              outcome_property(Outcome, result(Result)),
              Result = Expected
            ), Rows),
    findall(C, g8_normalizer_receipt(C, _, _, _, _), All),
    length(All, Total), length(Rows, Passed),
    Total =:= Passed,
    format('  receipts: ~w/~w printed equations normalized and solved~n',
           [Passed, Total]),
    forall(member(Correction-Lesson-Result, Rows),
           format('    correction ~w  ~w -> ~q~n', [Correction, Lesson, Result])).

check_the_deformation :-
    % 8(x - 3) + 7 = 2x(4 - 17): the multiplier stopped at x leaves 8x + 7 on
    % the left, so the deformation reports a different equation from the one
    % the distributive property gives.
    g8_normalizer_receipt(38, _, _, Json, _),
    g8_normalizer_from_json(Json, Printed),
    run_g8_normalizer(distribute_over_the_first_term_only, Printed, Outcome, _),
    outcome_property(Outcome, result(two_sided_form(A, B, C, D))),
    outcome_property(Outcome, expected(two_sided_form(A1, B1, C1, D1))),
    outcome_property(Outcome, validity(incorrect)),
    format('  deformation: correction 38 read as ~w x + ~w = ~w x + ~w where distributing gives ~w x + ~w = ~w x + ~w~n',
           [A, B, C, D, A1, B1, C1, D1]).

check_negative :-
    % An unknown in a denominator is not a linear equation and is refused.
    \+ g8_normalizer_from_json(
           _{kind: "printed_linear_equation", unknown: "x",
             left: _{op: "quotient", dividend: _{op: "number", value: 1},
                     divisor: 0},
             right: _{op: "unknown"}}, _),
    % Two unknown-carrying factors are refused rather than flattened.
    g8_normalizer_from_json(
        _{kind: "printed_linear_equation", unknown: "x",
          left: _{op: "product", factors: [_{op: "unknown"}, _{op: "unknown"}]},
          right: _{op: "number", value: 9}}, Squared),
    run_g8_normalizer(normalize_to_two_sided_form, Squared, Outcome, _),
    outcome_property(Outcome, result(refused(not_linear_in_the_unknown))),
    % A row with nothing to distribute has no deformation to report.
    g8_normalizer_from_json(
        _{kind: "printed_linear_equation", unknown: "x",
          left: _{op: "sum", terms: [_{op: "unknown"},
                                     _{op: "number", value: 1}]},
          right: _{op: "number", value: 4}}, Plain),
    \+ run_g8_normalizer(distribute_over_the_first_term_only, Plain, _, _),
    format('  negative tests: a zero divisor is refused at decode, x times x refuses as nonlinear, and an equation without parentheses carries no deformation~n').

outcome_property(action_outcome(_, Props), Property) :-
    memberchk(Property, Props).
