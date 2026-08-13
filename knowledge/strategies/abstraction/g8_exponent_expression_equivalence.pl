:- encoding(utf8).
/** <module> Grade 8 draft: deciding whether two exponent expressions say the same thing
 *
 * WHAT THIS IS. A draft automaton for the demand that runs through most of
 * the corrected grade 8 unit 7 tasks: here is an expression and here is a
 * list of others, decide which say the same thing. The published pilot
 * `g8_exponent_rule_rewrite` applies ONE rule to ONE pair of powers and hands
 * back a rewritten single power. It cannot take `(5^3)^-3`, `5^-6/5^3` and
 * `5^-4 · 5^-5` and sort them against `5^-9`, because nothing in it composes
 * a rule with a rule or compares two results.
 *
 * WHAT IT ADDS. Three doings the published pilot does not carry:
 *   - `value_of_a_power` answers "what is the value of 3^4" and "write 2^-6
 *     as a fraction" — the demand of corrections 90 and 116, which no rewrite
 *     rule answers because no rule is being applied.
 *   - `single_power_of_an_expression` walks a whole expression tree and
 *     returns one power when every leaf shares a base.
 *   - `decide_equivalence_of_two_expressions` compares two trees by exact
 *     rational value, so 8^0, 8^3 · 8^-3, 10^0 and 11^0 all land together and
 *     0 does not.
 *
 * FOUR DEFORMATION PARTNERS, ALL PRINTED IN THE CURRICULUM. Grade 8 unit 7
 * hands its errors to named students, and the corrections recovered four:
 *   - Diego writes 2^3 · 2^2 = 2^(3·2) (correction 118) — the exponents
 *     multiplied where the rule adds them.
 *   - Andre writes 7^4/7^-3 = 7^(4-3) (correction 118) — the divisor's
 *     exponent subtracted without its sign.
 *   - Diego writes 6^4 · 8^3 = 48^7 (correction 121) — the bases multiplied
 *     and the exponents added, where the rule for a product of bases needs
 *     one shared exponent.
 *   - Elena writes 5^4 + 5^5 = 5^9 (correction 120) — a SUM read through the
 *     product rule.
 * Each is a transition this automaton can take, so the trace names which act
 * was substituted for which, rather than reporting a wrong number.
 *
 * A NAMED LIMIT. Correction 117 also prints Diego's list about x^4, whose
 * base is a letter. This module takes numeric bases only, refuses a symbolic
 * one at decode, and does not pretend otherwise. A symbolic-base extension is
 * a separate demand, recorded in the round-two report.
 *
 * QUARANTINE. Nothing imports this module; it is a draft under
 * `.superpowers/sdd/g8-round2/`. Check:
 * `check_g8_exponent_expression_equivalence/0`.
 */

:- module(g8_exponent_expression_equivalence,
          [ run_g8_exponent_expression/4,
            g8_exponent_expression_from_json/2,
            g8_exponent_expression_states/1,
            g8_exponent_expression_state_label/4,
            g8_exponent_expression_summary/1,
            g8_exponent_expression_receipt/5,
            check_g8_exponent_expression_equivalence/0
          ]).

:- use_module(strategies('abstraction/g8_quantity_input'),
              [ g8_quantity/2, g8_rational_text/2 ]).

% ==========================================================================
% 1. INPUT CONTRACT
%
%   {"kind":"exponent_expression",
%    "expression":{"op":"power","base":3,"exponent":4}}
%   {"kind":"exponent_expression",
%    "expression":{"op":"product",
%                  "factors":[{"op":"power","base":2,"exponent":3},
%                             {"op":"power","base":2,"exponent":2}]}}
%   {"kind":"exponent_expression_pair",
%    "left":{...}, "right":{...}}
%
% Node kinds: power, product, quotient, power_of_power, sum, number. A base
% must be a number; a written letter is refused at decode.
% ==========================================================================

g8_exponent_expression_input_contract(
    '{\"kind\":\"exponent_expression\",\"expression\":\"node\"}',
    '{\"kind\":\"exponent_expression\",\"expression\":{\"op\":\"power\",\"base\":3,\"exponent\":4}}').

g8_exponent_expression_from_json(Dict, expression(Node)) :-
    is_dict(Dict),
    get_dict(kind, Dict, "exponent_expression"), !,
    get_dict(expression, Dict, Raw),
    exponent_node(Raw, Node).
g8_exponent_expression_from_json(Dict, pair(Left, Right)) :-
    is_dict(Dict),
    get_dict(kind, Dict, "exponent_expression_pair"),
    get_dict(left, Dict, L), get_dict(right, Dict, R),
    exponent_node(L, Left), exponent_node(R, Right).

exponent_node(Dict, power(Base, Exponent)) :-
    get_dict(op, Dict, "power"), !,
    get_dict(base, Dict, B0), g8_quantity(B0, Base), Base =\= 0,
    get_dict(exponent, Dict, Exponent), integer(Exponent).
exponent_node(Dict, number(Value)) :-
    get_dict(op, Dict, "number"), !,
    get_dict(value, Dict, V0), g8_quantity(V0, Value).
exponent_node(Dict, product(Nodes)) :-
    get_dict(op, Dict, "product"), !,
    get_dict(factors, Dict, Raw), Raw = [_, _|_],
    maplist(exponent_node, Raw, Nodes).
exponent_node(Dict, sum(Nodes)) :-
    get_dict(op, Dict, "sum"), !,
    get_dict(terms, Dict, Raw), Raw = [_, _|_],
    maplist(exponent_node, Raw, Nodes).
exponent_node(Dict, quotient(Dividend, Divisor)) :-
    get_dict(op, Dict, "quotient"), !,
    get_dict(dividend, Dict, D), exponent_node(D, Dividend),
    get_dict(divisor, Dict, V), exponent_node(V, Divisor).
exponent_node(Dict, power_of_power(Inner, Outer)) :-
    get_dict(op, Dict, "power_of_power"),
    get_dict(base, Dict, B), exponent_node(B, Inner),
    get_dict(exponent, Dict, Outer), integer(Outer).

% ==========================================================================
% 2. STATES
% ==========================================================================

g8_exponent_expression_states(
    [ q_read_the_expression,
      q_repeat_the_base_as_the_exponent_counts,
      q_report_the_value,
      q_gather_one_base_through_the_tree,
      q_report_a_single_power,
      q_refuse_a_mixed_base_expression,
      q_compare_two_values,
      q_accept_equivalence,
      q_reject_equivalence,
      q_multiply_the_exponents_of_a_product,
      q_subtract_the_divisor_exponent_without_its_sign,
      q_multiply_the_bases_and_add_the_exponents,
      q_read_a_sum_through_the_product_rule ]).

% g8_exponent_expression_state_label(State, Tradition, Label, Citation).
g8_exponent_expression_state_label(q_repeat_the_base_as_the_exponent_counts,
    illustrative_mathematics,
    "an exponent counts how many times the base is a factor",
    "IM Grade 8 Unit 7 Lesson 1, Exponent Review").
g8_exponent_expression_state_label(q_report_the_value, illustrative_mathematics,
    "writing a power with a negative exponent as a fraction",
    "IM Grade 8 Unit 7 Lesson 6, What about Other Bases?").
g8_exponent_expression_state_label(q_gather_one_base_through_the_tree,
    illustrative_mathematics,
    "rewriting an expression as a single power of the base",
    "IM Grade 8 Unit 7 Lesson 7, Practice with Rational Bases").
g8_exponent_expression_state_label(q_gather_one_base_through_the_tree, ccss,
    "apply the properties of integer exponents to generate equivalent expressions",
    "CCSS 8.EE.A.1, via IM Grade 8 Unit 7 Lesson 7").
g8_exponent_expression_state_label(q_compare_two_values, provisional,
    "deciding two written expressions have the same value",
    "provisional; no community label sourced for the comparison step").
g8_exponent_expression_state_label(q_multiply_the_exponents_of_a_product,
    illustrative_mathematics,
    "Diego's move: the exponents multiplied where the rule adds them",
    "IM Grade 8 Unit 7 Lesson 6, printed in the lesson as Diego's work").
g8_exponent_expression_state_label(
    q_subtract_the_divisor_exponent_without_its_sign,
    illustrative_mathematics,
    "Andre's move: the divisor's exponent subtracted without its sign",
    "IM Grade 8 Unit 7 Lesson 6, printed in the lesson as Andre's work").
g8_exponent_expression_state_label(q_multiply_the_bases_and_add_the_exponents,
    illustrative_mathematics,
    "Diego's move: bases multiplied and exponents added together",
    "IM Grade 8 Unit 7 Lesson 7, printed in the lesson as Diego's work").
g8_exponent_expression_state_label(q_read_a_sum_through_the_product_rule,
    illustrative_mathematics,
    "Elena's move: a sum of powers read through the product rule",
    "IM Grade 8 Unit 7 Lesson 7, the false equation 5^4 + 5^5 = 5^9").

% ==========================================================================
% 3. TRANSITIONS
% ==========================================================================

g8_exponent_expression_transition(value_of_a_power,
    q_read_the_expression, repeat_the_base_as_the_exponent_counts,
    q_repeat_the_base_as_the_exponent_counts).
g8_exponent_expression_transition(value_of_a_power,
    q_repeat_the_base_as_the_exponent_counts, report_the_value,
    q_report_the_value).
g8_exponent_expression_transition(single_power_of_an_expression,
    q_read_the_expression, gather_one_base_through_the_tree,
    q_gather_one_base_through_the_tree).
g8_exponent_expression_transition(single_power_of_an_expression,
    q_gather_one_base_through_the_tree, report_a_single_power,
    q_report_a_single_power).
g8_exponent_expression_transition(single_power_of_an_expression,
    q_gather_one_base_through_the_tree, refuse_a_mixed_base_expression,
    q_refuse_a_mixed_base_expression).
g8_exponent_expression_transition(decide_equivalence_of_two_expressions,
    q_read_the_expression, compare_two_values, q_compare_two_values).
g8_exponent_expression_transition(decide_equivalence_of_two_expressions,
    q_compare_two_values, accept_equivalence, q_accept_equivalence).
g8_exponent_expression_transition(decide_equivalence_of_two_expressions,
    q_compare_two_values, reject_equivalence, q_reject_equivalence).
g8_exponent_expression_transition(multiply_the_exponents_in_a_product,
    q_read_the_expression, multiply_the_exponents_of_a_product,
    q_multiply_the_exponents_of_a_product).
g8_exponent_expression_transition(subtract_the_exponent_without_its_sign,
    q_read_the_expression, subtract_the_divisor_exponent_without_its_sign,
    q_subtract_the_divisor_exponent_without_its_sign).
g8_exponent_expression_transition(multiply_the_bases_and_add_the_exponents,
    q_read_the_expression, multiply_the_bases_and_add_the_exponents,
    q_multiply_the_bases_and_add_the_exponents).
g8_exponent_expression_transition(add_the_exponents_of_a_sum,
    q_read_the_expression, read_a_sum_through_the_product_rule,
    q_read_a_sum_through_the_product_rule).

% ==========================================================================
% 4. THE RUN
% ==========================================================================

run_g8_exponent_expression(value_of_a_power, expression(Node), Outcome,
                           Trace) :-
    exact_value(Node, Value),
    g8_rational_text(Value, Text),
    Outcome = action_outcome(
        value_of_a_power,
        [ classification(productive),
          cluster(g8_exponent_rules),
          automaton_state(q_report_the_value),
          vocabulary([base, exponent, power, value, fraction]),
          input(expression(Node)),
          result(value(Text)),
          expected(value(Text)),
          exact(Value),
          invariant(the_exponent_counts_the_factors),
          validity(correct) ]),
    Trace = [ repeat_the_base_as_the_exponent_counts(Node),
              report_the_value(Text) ].
run_g8_exponent_expression(single_power_of_an_expression, expression(Node),
                           Outcome, Trace) :-
    (   single_power(Node, Base, Exponent)
    ->  exact_value(Node, Value),
        power_value(Base, Exponent, Rebuilt),
        ( Rebuilt =:= Value -> Validity = correct ; Validity = unvindicated ),
        g8_rational_text(Base, BaseText),
        format(atom(A), '~w^~w', [BaseText, Exponent]),
        atom_string(A, Text),
        Outcome = action_outcome(
            single_power_of_an_expression,
            [ classification(productive),
              cluster(g8_exponent_rules),
              automaton_state(q_report_a_single_power),
              vocabulary([base, exponent, single_power, equivalent_expression]),
              input(expression(Node)),
              result(single_power(Text)),
              expected(single_power(Text)),
              exact(Value),
              invariant(the_single_power_rebuilds_the_value),
              validity(Validity) ]),
        Trace = [ gather_one_base_through_the_tree(BaseText),
                  report_a_single_power(Text) ]
    ;   Outcome = action_outcome(
            single_power_of_an_expression,
            [ classification(refusal),
              cluster(g8_exponent_rules),
              automaton_state(q_refuse_a_mixed_base_expression),
              vocabulary([base, exponent, single_power]),
              input(expression(Node)),
              result(refused(no_single_base_runs_through_the_expression)),
              refusal(refusal{kind: "no_shared_base"}),
              validity(refused) ]),
        Trace = [ refuse_a_mixed_base_expression ]
    ).
run_g8_exponent_expression(decide_equivalence_of_two_expressions,
                           pair(Left, Right), Outcome, Trace) :-
    exact_value(Left, LeftValue),
    exact_value(Right, RightValue),
    g8_rational_text(LeftValue, LeftText),
    g8_rational_text(RightValue, RightText),
    (   LeftValue =:= RightValue
    ->  State = q_accept_equivalence, Answer = equivalent,
        Step = accept_equivalence(LeftText)
    ;   State = q_reject_equivalence,
        Answer = not_equivalent(LeftText, RightText),
        Step = reject_equivalence(LeftText, RightText)
    ),
    Outcome = action_outcome(
        decide_equivalence_of_two_expressions,
        [ classification(productive),
          cluster(g8_exponent_rules),
          automaton_state(State),
          vocabulary([equivalent_expression, value, base, exponent]),
          input(pair(Left, Right)),
          result(Answer),
          expected(Answer),
          left_value(LeftText),
          right_value(RightText),
          invariant(two_expressions_agree_exactly_or_they_do_not),
          validity(correct) ]),
    Trace = [ compare_two_values(LeftText, RightText), Step ].

% ---- the four printed deformations ----------------------------------------

run_g8_exponent_expression(multiply_the_exponents_in_a_product,
                           expression(product([power(B, E1), power(B, E2)])),
                           Outcome, Trace) :-
    Deformed is E1 * E2,
    Correct is E1 + E2,
    Deformed =\= Correct,
    g8_rational_text(B, BaseText),
    Outcome = action_outcome(
        multiply_the_exponents_in_a_product,
        [ classification(deformation),
          cluster(g8_exponent_rules),
          automaton_state(q_multiply_the_exponents_of_a_product),
          vocabulary([product, exponent, rule]),
          input(expression(product([power(B, E1), power(B, E2)]))),
          result(single_power_claimed(BaseText, Deformed)),
          expected(single_power_claimed(BaseText, Correct)),
          deforms(single_power_of_an_expression),
          attested_by('IM Grade 8 Unit 7 Lesson 6, Diego'),
          validity(incorrect) ]),
    Trace = [ multiply_the_exponents_of_a_product(E1, E2, Deformed) ].
run_g8_exponent_expression(subtract_the_exponent_without_its_sign,
                           expression(quotient(power(B, E1), power(B, E2))),
                           Outcome, Trace) :-
    E2 < 0,
    Deformed is E1 + E2,       % "4 - 3", the sign of the divisor dropped
    Correct is E1 - E2,
    g8_rational_text(B, BaseText),
    Outcome = action_outcome(
        subtract_the_exponent_without_its_sign,
        [ classification(deformation),
          cluster(g8_exponent_rules),
          automaton_state(q_subtract_the_divisor_exponent_without_its_sign),
          vocabulary([quotient, exponent, negative_exponent, rule]),
          input(expression(quotient(power(B, E1), power(B, E2)))),
          result(single_power_claimed(BaseText, Deformed)),
          expected(single_power_claimed(BaseText, Correct)),
          deforms(single_power_of_an_expression),
          attested_by('IM Grade 8 Unit 7 Lesson 6, Andre'),
          validity(incorrect) ]),
    Trace = [ subtract_the_divisor_exponent_without_its_sign(E1, E2,
                                                             Deformed) ].
run_g8_exponent_expression(multiply_the_bases_and_add_the_exponents,
                           expression(product([power(B1, E1), power(B2, E2)])),
                           Outcome, Trace) :-
    B1 =\= B2,
    ClaimedBase is B1 * B2,
    ClaimedExponent is E1 + E2,
    g8_rational_text(ClaimedBase, ClaimedText),
    exact_value(product([power(B1, E1), power(B2, E2)]), TrueValue),
    power_value(ClaimedBase, ClaimedExponent, ClaimedValue),
    ClaimedValue =\= TrueValue,
    g8_rational_text(TrueValue, TrueText),
    g8_rational_text(ClaimedValue, ClaimedValueText),
    Outcome = action_outcome(
        multiply_the_bases_and_add_the_exponents,
        [ classification(deformation),
          cluster(g8_exponent_rules),
          automaton_state(q_multiply_the_bases_and_add_the_exponents),
          vocabulary([product_of_bases, exponent, shared_exponent, rule]),
          input(expression(product([power(B1, E1), power(B2, E2)]))),
          result(single_power_claimed(ClaimedText, ClaimedExponent)),
          expected(value(TrueText)),
          claimed_value(ClaimedValueText),
          deforms(decide_equivalence_of_two_expressions),
          attested_by('IM Grade 8 Unit 7 Lesson 7, Diego'),
          validity(incorrect) ]),
    Trace = [ multiply_the_bases_and_add_the_exponents(ClaimedText,
                                                       ClaimedExponent) ].
run_g8_exponent_expression(add_the_exponents_of_a_sum,
                           expression(sum([power(B, E1), power(B, E2)])),
                           Outcome, Trace) :-
    Claimed is E1 + E2,
    exact_value(sum([power(B, E1), power(B, E2)]), TrueValue),
    power_value(B, Claimed, ClaimedValue),
    ClaimedValue =\= TrueValue,
    g8_rational_text(B, BaseText),
    g8_rational_text(TrueValue, TrueText),
    Outcome = action_outcome(
        add_the_exponents_of_a_sum,
        [ classification(deformation),
          cluster(g8_exponent_rules),
          automaton_state(q_read_a_sum_through_the_product_rule),
          vocabulary([sum, product, exponent, rule]),
          input(expression(sum([power(B, E1), power(B, E2)]))),
          result(single_power_claimed(BaseText, Claimed)),
          expected(value(TrueText)),
          deforms(value_of_a_power),
          attested_by('IM Grade 8 Unit 7 Lesson 7, Elena'),
          validity(incorrect) ]),
    Trace = [ read_a_sum_through_the_product_rule(BaseText, Claimed) ].

%!  exact_value(+Node, -Rational) is semidet.
%
%   Exact rational arithmetic throughout. A negative exponent is a reciprocal
%   of a positive power rather than a float.
exact_value(number(V), V).
exact_value(power(Base, Exponent), Value) :-
    power_value(Base, Exponent, Value).
exact_value(product(Nodes), Value) :-
    foldl([N, Acc0, Acc]>>( exact_value(N, V), Acc is Acc0 * V ), Nodes, 1,
          Value).
exact_value(sum(Nodes), Value) :-
    foldl([N, Acc0, Acc]>>( exact_value(N, V), Acc is Acc0 + V ), Nodes, 0,
          Value).
exact_value(quotient(Dividend, Divisor), Value) :-
    exact_value(Dividend, A), exact_value(Divisor, B), B =\= 0,
    Value is A rdiv B.
exact_value(power_of_power(Inner, Outer), Value) :-
    exact_value(Inner, Base),
    power_value(Base, Outer, Value).

power_value(Base, Exponent, Value) :-
    Base =\= 0,
    (   Exponent >= 0
    ->  Value is Base ^ Exponent
    ;   Positive is -Exponent,
        Denominator is Base ^ Positive,
        Value is 1 rdiv Denominator
    ).

%!  single_power(+Node, -Base, -Exponent) is semidet.
%
%   One base gathered through the tree. A sum is refused: nothing in the
%   exponent rules turns a sum of powers into a power.
single_power(power(Base, Exponent), Base, Exponent).
single_power(product([A, B]), Base, Exponent) :-
    single_power(A, Base, E1), single_power(B, Base, E2),
    Exponent is E1 + E2.
single_power(quotient(A, B), Base, Exponent) :-
    single_power(A, Base, E1), single_power(B, Base, E2),
    Exponent is E1 - E2.
single_power(power_of_power(Inner, Outer), Base, Exponent) :-
    single_power(Inner, Base, E1),
    Exponent is E1 * Outer.

% ==========================================================================
% 5. SELF-SUMMARY
% ==========================================================================

g8_exponent_expression_summary(
    summary{ module: g8_exponent_expression_equivalence,
             status: draft_for_quarantine,
             generated: false,
             grade: 8,
             cluster: g8_exponent_rules,
             doings: [ value_of_a_power,
                       single_power_of_an_expression,
                       decide_equivalence_of_two_expressions,
                       multiply_the_exponents_in_a_product,
                       subtract_the_exponent_without_its_sign,
                       multiply_the_bases_and_add_the_exponents,
                       add_the_exponents_of_a_sum ],
             verification: [the_single_power_rebuilds_the_value,
                            two_expressions_agree_exactly_or_they_do_not],
             arithmetic: exact_rational,
             beside: g8_exponent_rule_rewrite,
             deformation_partners: [multiply_the_exponents_in_a_product,
                                    subtract_the_exponent_without_its_sign,
                                    multiply_the_bases_and_add_the_exponents,
                                    add_the_exponents_of_a_sum],
             refuses: symbolic_bases,
             imported_by: none }).

% ==========================================================================
% 6. RECEIPTS
%
% g8_exponent_expression_receipt(Correction, Lesson, Doing, Json, Expected).
% ==========================================================================

% correction 90, IM-G8-U7-L1: "What is the value of 3^4?"
g8_exponent_expression_receipt(90, 'IM-G8-U7-L1', value_of_a_power,
    _{kind: "exponent_expression",
      expression: _{op: "power", base: 3, exponent: 4}},
    value("81")).
% correction 116, IM-G8-U7-L6: write 2^-6 as a fraction
g8_exponent_expression_receipt(116, 'IM-G8-U7-L6', value_of_a_power,
    _{kind: "exponent_expression",
      expression: _{op: "power", base: 2, exponent: -6}},
    value("1/64")).
% correction 116: write 1/32 as a power of 2, checked by value
g8_exponent_expression_receipt(116, 'IM-G8-U7-L6', value_of_a_power,
    _{kind: "exponent_expression",
      expression: _{op: "power", base: 2, exponent: -5}},
    value("1/32")).
% correction 116: the value of 2^0
g8_exponent_expression_receipt(116, 'IM-G8-U7-L6', value_of_a_power,
    _{kind: "exponent_expression",
      expression: _{op: "power", base: 2, exponent: 0}},
    value("1")).
% correction 116: 5^-3 as a fraction
g8_exponent_expression_receipt(116, 'IM-G8-U7-L6', value_of_a_power,
    _{kind: "exponent_expression",
      expression: _{op: "power", base: 5, exponent: -3}},
    value("1/125")).
% correction 116: 3^-4 as a fraction
g8_exponent_expression_receipt(116, 'IM-G8-U7-L6', value_of_a_power,
    _{kind: "exponent_expression",
      expression: _{op: "power", base: 3, exponent: -4}},
    value("1/81")).
% correction 94, IM-G8-U7-L3: expressions with the same value as 10^6
g8_exponent_expression_receipt(94, 'IM-G8-U7-L3', value_of_a_power,
    _{kind: "exponent_expression",
      expression: _{op: "power", base: 10, exponent: 6}},
    value("1000000")).
% correction 94: 10 * 10^5 is one of the printed forms of 10^6
g8_exponent_expression_receipt(94, 'IM-G8-U7-L3',
    decide_equivalence_of_two_expressions,
    _{kind: "exponent_expression_pair",
      left: _{op: "product",
              factors: [_{op: "power", base: 10, exponent: 1},
                        _{op: "power", base: 10, exponent: 5}]},
      right: _{op: "power", base: 10, exponent: 6}},
    equivalent).
% correction 117, IM-G8-U7-L6: (5^3)^-3 against Lin's 5^-9
g8_exponent_expression_receipt(117, 'IM-G8-U7-L6',
    decide_equivalence_of_two_expressions,
    _{kind: "exponent_expression_pair",
      left: _{op: "power_of_power",
              base: _{op: "power", base: 5, exponent: 3}, exponent: -3},
      right: _{op: "power", base: 5, exponent: -9}},
    equivalent).
% correction 117: 5^-6/5^3 against 5^-9
g8_exponent_expression_receipt(117, 'IM-G8-U7-L6',
    decide_equivalence_of_two_expressions,
    _{kind: "exponent_expression_pair",
      left: _{op: "quotient",
              dividend: _{op: "power", base: 5, exponent: -6},
              divisor: _{op: "power", base: 5, exponent: 3}},
      right: _{op: "power", base: 5, exponent: -9}},
    equivalent).
% correction 117: (5^3)^-2 against 5^-9, one of the ones that does not match
g8_exponent_expression_receipt(117, 'IM-G8-U7-L6',
    decide_equivalence_of_two_expressions,
    _{kind: "exponent_expression_pair",
      left: _{op: "power_of_power",
              base: _{op: "power", base: 5, exponent: 3}, exponent: -2},
      right: _{op: "power", base: 5, exponent: -9}},
    not_equivalent("1/15625", "1/1953125")).
% correction 117: 5^-4/5^-5 against 5^-9, the other mismatch
g8_exponent_expression_receipt(117, 'IM-G8-U7-L6',
    decide_equivalence_of_two_expressions,
    _{kind: "exponent_expression_pair",
      left: _{op: "quotient",
              dividend: _{op: "power", base: 5, exponent: -4},
              divisor: _{op: "power", base: 5, exponent: -5}},
      right: _{op: "power", base: 5, exponent: -9}},
    not_equivalent("5", "1/1953125")).
% correction 117: Elena's list, 8^3 * 8^-3 against 8^0
g8_exponent_expression_receipt(117, 'IM-G8-U7-L6',
    decide_equivalence_of_two_expressions,
    _{kind: "exponent_expression_pair",
      left: _{op: "product",
              factors: [_{op: "power", base: 8, exponent: 3},
                        _{op: "power", base: 8, exponent: -3}]},
      right: _{op: "power", base: 8, exponent: 0}},
    equivalent).
% correction 117: Elena's list, 11^0 against 8^0
g8_exponent_expression_receipt(117, 'IM-G8-U7-L6',
    decide_equivalence_of_two_expressions,
    _{kind: "exponent_expression_pair",
      left: _{op: "power", base: 11, exponent: 0},
      right: _{op: "power", base: 8, exponent: 0}},
    equivalent).
% correction 117: Elena's list, the printed 0 against 8^0
g8_exponent_expression_receipt(117, 'IM-G8-U7-L6',
    decide_equivalence_of_two_expressions,
    _{kind: "exponent_expression_pair",
      left: _{op: "number", value: 0},
      right: _{op: "power", base: 8, exponent: 0}},
    not_equivalent("0", "1")).
% correction 117: Noah's list, (3^5)^2 against 3^10
g8_exponent_expression_receipt(117, 'IM-G8-U7-L6',
    single_power_of_an_expression,
    _{kind: "exponent_expression",
      expression: _{op: "power_of_power",
                    base: _{op: "power", base: 3, exponent: 5}, exponent: 2}},
    single_power("3^10")).
% correction 117: Noah's list, 3^20/3^2, which is not 3^10
g8_exponent_expression_receipt(117, 'IM-G8-U7-L6',
    single_power_of_an_expression,
    _{kind: "exponent_expression",
      expression: _{op: "quotient",
                    dividend: _{op: "power", base: 3, exponent: 20},
                    divisor: _{op: "power", base: 3, exponent: 2}}},
    single_power("3^18")).
% correction 119, IM-G8-U7-L7: (6^2)^4 as a single power
g8_exponent_expression_receipt(119, 'IM-G8-U7-L7',
    single_power_of_an_expression,
    _{kind: "exponent_expression",
      expression: _{op: "power_of_power",
                    base: _{op: "power", base: 6, exponent: 2}, exponent: 4}},
    single_power("6^8")).
% correction 119: 4^5/4^-8 as a single power
g8_exponent_expression_receipt(119, 'IM-G8-U7-L7',
    single_power_of_an_expression,
    _{kind: "exponent_expression",
      expression: _{op: "quotient",
                    dividend: _{op: "power", base: 4, exponent: 5},
                    divisor: _{op: "power", base: 4, exponent: -8}}},
    single_power("4^13")).
% correction 120, IM-G8-U7-L7: (1/3)^2 * (1/3)^4 = (1/3)^6, marked true
g8_exponent_expression_receipt(120, 'IM-G8-U7-L7',
    decide_equivalence_of_two_expressions,
    _{kind: "exponent_expression_pair",
      left: _{op: "product",
              factors: [_{op: "power", base: _{n: 1, d: 3}, exponent: 2},
                        _{op: "power", base: _{n: 1, d: 3}, exponent: 4}]},
      right: _{op: "power", base: _{n: 1, d: 3}, exponent: 6}},
    equivalent).
% correction 120: 5^4 + 5^5 = 5^9, marked false
g8_exponent_expression_receipt(120, 'IM-G8-U7-L7',
    decide_equivalence_of_two_expressions,
    _{kind: "exponent_expression_pair",
      left: _{op: "sum",
              terms: [_{op: "power", base: 5, exponent: 4},
                      _{op: "power", base: 5, exponent: 5}]},
      right: _{op: "power", base: 5, exponent: 9}},
    not_equivalent("3750", "1953125")).
% correction 120: (1/2)^4 * 10^3 = 5^7, marked false
g8_exponent_expression_receipt(120, 'IM-G8-U7-L7',
    decide_equivalence_of_two_expressions,
    _{kind: "exponent_expression_pair",
      left: _{op: "product",
              factors: [_{op: "power", base: _{n: 1, d: 2}, exponent: 4},
                        _{op: "power", base: 10, exponent: 3}]},
      right: _{op: "power", base: 5, exponent: 7}},
    not_equivalent("125/2", "78125")).
% correction 120: 3^2 * 5^2 = 15^2, marked true
g8_exponent_expression_receipt(120, 'IM-G8-U7-L7',
    decide_equivalence_of_two_expressions,
    _{kind: "exponent_expression_pair",
      left: _{op: "product",
              factors: [_{op: "power", base: 3, exponent: 2},
                        _{op: "power", base: 5, exponent: 2}]},
      right: _{op: "power", base: 15, exponent: 2}},
    equivalent).
% correction 122, IM-G8-U7-L8: 12^7 * 4^7 against (12 * 4)^7
g8_exponent_expression_receipt(122, 'IM-G8-U7-L8',
    decide_equivalence_of_two_expressions,
    _{kind: "exponent_expression_pair",
      left: _{op: "product",
              factors: [_{op: "power", base: 12, exponent: 7},
                        _{op: "power", base: 4, exponent: 7}]},
      right: _{op: "power", base: 48, exponent: 7}},
    equivalent).
% correction 122: 12 * 4^7 against (12 * 4)^7
g8_exponent_expression_receipt(122, 'IM-G8-U7-L8',
    decide_equivalence_of_two_expressions,
    _{kind: "exponent_expression_pair",
      left: _{op: "product",
              factors: [_{op: "number", value: 12},
                        _{op: "power", base: 4, exponent: 7}]},
      right: _{op: "power", base: 48, exponent: 7}},
    not_equivalent("196608", "587068342272")).
% correction 121, IM-G8-U7-L7: 9^3/9^9 as a single power
g8_exponent_expression_receipt(121, 'IM-G8-U7-L7',
    single_power_of_an_expression,
    _{kind: "exponent_expression",
      expression: _{op: "quotient",
                    dividend: _{op: "power", base: 9, exponent: 3},
                    divisor: _{op: "power", base: 9, exponent: 9}}},
    single_power("9^-6")).
% correction 121: 14^-3 * 14^12 as a single power
g8_exponent_expression_receipt(121, 'IM-G8-U7-L7',
    single_power_of_an_expression,
    _{kind: "exponent_expression",
      expression: _{op: "product",
                    factors: [_{op: "power", base: 14, exponent: -3},
                              _{op: "power", base: 14, exponent: 12}]}},
    single_power("14^9")).
% correction 115, IM-G8-U7-L5: (10^2)^-3 = (10^-2)^3, marked true
g8_exponent_expression_receipt(115, 'IM-G8-U7-L5',
    decide_equivalence_of_two_expressions,
    _{kind: "exponent_expression_pair",
      left: _{op: "power_of_power",
              base: _{op: "power", base: 10, exponent: 2}, exponent: -3},
      right: _{op: "power_of_power",
               base: _{op: "power", base: 10, exponent: -2}, exponent: 3}},
    equivalent).
% correction 115: 10^3/10^14 = 10^-11, marked true
g8_exponent_expression_receipt(115, 'IM-G8-U7-L5',
    decide_equivalence_of_two_expressions,
    _{kind: "exponent_expression_pair",
      left: _{op: "quotient",
              dividend: _{op: "power", base: 10, exponent: 3},
              divisor: _{op: "power", base: 10, exponent: 14}},
      right: _{op: "power", base: 10, exponent: -11}},
    equivalent).

% ---- the printed deformations ---------------------------------------------

% correction 118, IM-G8-U7-L6: Diego writes 2^3 * 2^2 = 2^6
g8_exponent_expression_receipt(118, 'IM-G8-U7-L6',
    multiply_the_exponents_in_a_product,
    _{kind: "exponent_expression",
      expression: _{op: "product",
                    factors: [_{op: "power", base: 2, exponent: 3},
                              _{op: "power", base: 2, exponent: 2}]}},
    single_power_claimed("2", 6)).
% correction 118: Andre writes 7^4/7^-3 = 7^1
g8_exponent_expression_receipt(118, 'IM-G8-U7-L6',
    subtract_the_exponent_without_its_sign,
    _{kind: "exponent_expression",
      expression: _{op: "quotient",
                    dividend: _{op: "power", base: 7, exponent: 4},
                    divisor: _{op: "power", base: 7, exponent: -3}}},
    single_power_claimed("7", 1)).
% correction 121, IM-G8-U7-L7: Diego writes 6^4 * 8^3 = 48^7
g8_exponent_expression_receipt(121, 'IM-G8-U7-L7',
    multiply_the_bases_and_add_the_exponents,
    _{kind: "exponent_expression",
      expression: _{op: "product",
                    factors: [_{op: "power", base: 6, exponent: 4},
                              _{op: "power", base: 8, exponent: 3}]}},
    single_power_claimed("48", 7)).
% correction 120, IM-G8-U7-L7: Elena writes 5^4 + 5^5 = 5^9
g8_exponent_expression_receipt(120, 'IM-G8-U7-L7',
    add_the_exponents_of_a_sum,
    _{kind: "exponent_expression",
      expression: _{op: "sum",
                    terms: [_{op: "power", base: 5, exponent: 4},
                            _{op: "power", base: 5, exponent: 5}]}},
    single_power_claimed("5", 9)).

% ==========================================================================
% 7. CHECK
% ==========================================================================

check_g8_exponent_expression_equivalence :-
    check_receipts,
    check_the_deformations_disagree_with_the_rules,
    check_negative,
    format('g8_exponent_expression_equivalence: all checks ok~n').

check_receipts :-
    findall(Correction-Doing-Result,
            ( g8_exponent_expression_receipt(Correction, _, Doing, Json,
                                             Expected),
              g8_exponent_expression_from_json(Json, Figure),
              run_g8_exponent_expression(Doing, Figure, Outcome, _),
              outcome_property(Outcome, result(Result)),
              Result = Expected
            ), Rows),
    findall(C, g8_exponent_expression_receipt(C, _, _, _, _), All),
    length(All, Total), length(Rows, Passed),
    Total =:= Passed,
    format('  receipts: ~w/~w printed expressions run~n', [Passed, Total]),
    forall(member(Correction-Doing-Result, Rows),
           format('    correction ~w  ~w -> ~q~n',
                  [Correction, Doing, Result])).

check_the_deformations_disagree_with_the_rules :-
    % Every deformation row must differ from what the rules give, or it is
    % not a deformation.
    forall(( g8_exponent_expression_receipt(_, _, Doing, Json, _),
             memberchk(Doing, [multiply_the_exponents_in_a_product,
                               subtract_the_exponent_without_its_sign,
                               multiply_the_bases_and_add_the_exponents,
                               add_the_exponents_of_a_sum]) ),
           ( g8_exponent_expression_from_json(Json, Figure),
             run_g8_exponent_expression(Doing, Figure, Outcome, _),
             outcome_property(Outcome, result(Claimed)),
             outcome_property(Outcome, expected(Correct)),
             Claimed \= Correct,
             outcome_property(Outcome, validity(incorrect)) )),
    format('  deformations: four printed student moves, each differing from the rule it replaces~n').

check_negative :-
    % A symbolic base is refused at decode: correction 117's x^4 list.
    \+ g8_exponent_expression_from_json(
           _{kind: "exponent_expression",
             expression: _{op: "power", base: "x", exponent: 4}}, _),
    % A sum of powers has a value but no single power.
    g8_exponent_expression_from_json(
        _{kind: "exponent_expression",
          expression: _{op: "sum",
                        terms: [_{op: "power", base: 5, exponent: 4},
                                _{op: "power", base: 5, exponent: 5}]}}, Sum),
    run_g8_exponent_expression(single_power_of_an_expression, Sum, Outcome, _),
    outcome_property(Outcome,
                     result(refused(no_single_base_runs_through_the_expression))),
    % A product of unlike bases has no single power either.
    g8_exponent_expression_from_json(
        _{kind: "exponent_expression",
          expression: _{op: "product",
                        factors: [_{op: "power", base: 6, exponent: 4},
                                  _{op: "power", base: 8, exponent: 3}]}}, Mixed),
    run_g8_exponent_expression(single_power_of_an_expression, Mixed, Second, _),
    outcome_property(Second, validity(refused)),
    format('  negative tests: a letter base is refused at decode; a sum and a product of unlike bases carry a value but no single power~n').

outcome_property(action_outcome(_, Props), Property) :-
    memberchk(Property, Props).
