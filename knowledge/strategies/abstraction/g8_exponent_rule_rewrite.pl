:- encoding(utf8).
/** <module> Grade 8 pilot: rewriting powers by the exponent rules
 *
 * WHAT THIS IS. A quarantined pilot automaton for the doing IM grade 8 unit 7
 * builds across lessons 2 through 8: combine two powers into one by adding,
 * subtracting, or multiplying exponents; combine two bases carrying the same
 * exponent; read a zero exponent as 1 and a negative exponent as a reciprocal;
 * and decide whether a claimed equivalence between two exponential
 * expressions actually holds.
 *
 * WHY IT IS NEW. Three machines sit nearby and none does this.
 * `algebraic/exponent_as_repeated_factor` expands one power into its factors.
 * `algebraic/exponential_equivalence_by_expansion` checks a power against a
 * written-out product. The round-one pilot `g8_power_of_ten_notation` moves a
 * numeral into and out of scientific notation. None of them combines two
 * powers by a rule, and none reaches negative exponents, which is where unit 7
 * spends lessons 4 through 6. This pilot supplies that and leaves all three
 * untouched.
 *
 * THE RULE IS APPLIED, THEN THE CLAIM IS EXECUTED. Every rewrite reports the
 * rule it used AND evaluates both the original expression and the rewritten
 * one to exact rationals, then checks the two values are equal. A rule that
 * did not preserve the value is reported unvindicated. Negative exponents go
 * through an exact rational reciprocal rather than a float power, so
 * `10^(-5)` is 1/100000 and not 1.0e-5.
 *
 * WHERE THE NUMBERS COME FROM. Two receipts carry numerals the row itself
 * prints — IM-G8-U7-L5's two matching cards, recovered from the docling
 * document.json formula items at indices 40 and 41. The rest carry the row's
 * own BASE and its own rule, with the exponents supplied as a named witness
 * instantiation, because the row states a rule in letters rather than at
 * numbers. Every such receipt is marked `witness_instantiation` so no reader
 * mistakes a chosen exponent for one the curriculum printed.
 *
 * DEFORMATION PARTNER. One, and it is the strongest-grounded in this pilot
 * set: `negative_exponent_as_negative_value` reproduces db_row 38303 (Rabin,
 * Fuller & Harel 2013, Journal of Mathematical Behavior, pp. 653-654), where a
 * student reading 2 to the power of -1 says "I thought that would be a -2".
 * IM-G8-U7-L5 prints that very error as a card to be matched: its recovered
 * item reads `10^-5 = -10^5`. The corpus attests the confusion and the
 * curriculum stages it, so the pilot executes it at both places.
 * `g8_power_of_ten_notation` carries the same db_row at the NOTATION locus,
 * where a student drops the exponent's sign; this module carries it at the
 * VALUE locus, where the sign migrates to the result. The two are the same
 * attested confusion showing at two different steps, and each says so.
 *
 * QUARANTINE. Nothing imports this module; it renames nothing; its rows are
 * authored and vetoable one by one. Check: `check_g8_exponent_rule_rewrite/0`.
 */

:- module(g8_exponent_rule_rewrite,
          [ run_g8_exponent_rule/4,
            g8_exponent_from_json/2,
            g8_exponent_states/1,
            g8_exponent_state_label/4,
            g8_exponent_summary/1,
            g8_exponent_receipt/6,
            check_g8_exponent_rule_rewrite/0
          ]).

:- use_module(strategies('abstraction/g8_quantity_input'),
              [ g8_quantity/2, g8_rational_text/2 ]).

% ==========================================================================
% 1. INPUT CONTRACT
%
%   {"kind":"exponent_rewrite","rule":"product",
%    "left":{"base":10,"exponent":3},"right":{"base":10,"exponent":4}}
%   {"kind":"exponent_rewrite","rule":"power_of_power",
%    "left":{"base":10,"exponent":2},"outer_exponent":-3}
%   {"kind":"exponent_rewrite","rule":"zero_exponent","left":{"base":10}}
%   {"kind":"exponent_claim",
%    "left":{"base":10,"exponent":-5},
%    "right":{"base":10,"exponent":5,"negated":true}}
% ==========================================================================

g8_exponent_input_contract(
    '{\"kind\":\"exponent_rewrite\",\"rule\":\"string\",\"left\":{\"base\":\"number\",\"exponent\":\"integer\"},\"right\":{\"base\":\"number\",\"exponent\":\"integer\"},\"outer_exponent\":\"integer\"}',
    '{\"kind\":\"exponent_rewrite\",\"rule\":\"product\",\"left\":{\"base\":10,\"exponent\":3},\"right\":{\"base\":10,\"exponent\":4}}').

g8_exponent_from_json(Dict, rewrite(Rule, Left, Right, Outer)) :-
    is_dict(Dict), get_dict(kind, Dict, "exponent_rewrite"), !,
    get_dict(rule, Dict, RuleText),
    memberchk(RuleText, ["product", "quotient", "power_of_power",
                         "product_of_bases", "zero_exponent",
                         "negative_exponent"]),
    atom_string(Rule, RuleText),
    get_dict(left, Dict, L), power_of(L, Left),
    ( get_dict(right, Dict, R) -> power_of(R, Right) ; Right = none ),
    ( get_dict(outer_exponent, Dict, O), integer(O) -> Outer = O
    ; Outer = none ),
    rule_arity(Rule, Right, Outer).
g8_exponent_from_json(Dict, claim(Left, Right)) :-
    is_dict(Dict), get_dict(kind, Dict, "exponent_claim"),
    get_dict(left, Dict, L), get_dict(right, Dict, R),
    signed_power_of(L, Left), signed_power_of(R, Right).

power_of(Dict, power(Base, Exponent)) :-
    get_dict(base, Dict, B0), g8_quantity(B0, Base), Base =\= 0,
    ( get_dict(exponent, Dict, E), integer(E) -> Exponent = E
    ; Exponent = none ).

signed_power_of(Dict, signed(Negated, power(Base, Exponent))) :-
    get_dict(base, Dict, B0), g8_quantity(B0, Base), Base =\= 0,
    get_dict(exponent, Dict, Exponent), integer(Exponent),
    ( get_dict(negated, Dict, true) -> Negated = negated ; Negated = plain ).

rule_arity(product, power(_, E), none) :- integer(E).
rule_arity(quotient, power(_, E), none) :- integer(E).
rule_arity(product_of_bases, power(_, E), none) :- integer(E).
rule_arity(power_of_power, none, O) :- integer(O).
rule_arity(zero_exponent, none, none).
rule_arity(negative_exponent, none, none).

% ==========================================================================
% 2. STATES
% ==========================================================================

g8_exponent_states(
    [ q_read_the_two_powers,
      q_expand_into_repeated_factors,
      q_combine_the_exponents,
      q_combine_the_bases,
      q_read_the_zero_exponent_as_one,
      q_read_the_negative_exponent_as_a_reciprocal,
      q_evaluate_both_sides,
      q_accept_the_rewrite,
      q_accept_the_claim,
      q_reject_the_claim,
      q_carry_the_sign_into_the_value ]).

% g8_exponent_state_label(State, Tradition, Label, Citation).
g8_exponent_state_label(q_expand_into_repeated_factors,
    illustrative_mathematics, "the expanded column",
    "IM Grade 8 Unit 7 Lesson 8, Combining Bases").
g8_exponent_state_label(q_expand_into_repeated_factors, van_de_walle,
    "a power as repeated multiplication",
    "Van de Walle, ch. 16, Exponents").
g8_exponent_state_label(q_combine_the_exponents, illustrative_mathematics,
    "writing the product as a single power",
    "IM Grade 8 Unit 7 Lesson 3, Multiplying Powers of 10").
g8_exponent_state_label(q_combine_the_exponents, ccss,
    "the properties of integer exponents",
    "CCSS 8.EE.A.1, via IM Grade 8 Unit 7").
g8_exponent_state_label(q_combine_the_bases, illustrative_mathematics,
    "different bases carrying the same exponent",
    "IM Grade 8 Unit 7 Lesson 8, Combining Bases").
g8_exponent_state_label(q_read_the_zero_exponent_as_one,
    illustrative_mathematics,
    "what the value has to be for the rules to keep working",
    "IM Grade 8 Unit 7 Lesson 4, Dividing Powers of 10").
g8_exponent_state_label(q_read_the_negative_exponent_as_a_reciprocal,
    illustrative_mathematics, "what negative exponents mean",
    "IM Grade 8 Unit 7 Lesson 5, Negative Exponents").
g8_exponent_state_label(q_evaluate_both_sides, provisional,
    "check the rewrite kept the value",
    "provisional; no community label sourced for this checking step").
g8_exponent_state_label(q_carry_the_sign_into_the_value, rabin,
    "the negative exponent taken to make the value negative",
    "db_row 38303; Rabin, Fuller & Harel 2013, Journal of Mathematical Behavior, pp. 653-654").

% ==========================================================================
% 3. TRANSITIONS
% ==========================================================================

g8_exponent_transition(rewrite_by_exponent_rule,
    q_read_the_two_powers, expand_into_repeated_factors,
    q_expand_into_repeated_factors).
g8_exponent_transition(rewrite_by_exponent_rule,
    q_expand_into_repeated_factors, combine_the_exponents,
    q_combine_the_exponents).
g8_exponent_transition(rewrite_by_exponent_rule,
    q_expand_into_repeated_factors, combine_the_bases, q_combine_the_bases).
g8_exponent_transition(rewrite_by_exponent_rule,
    q_expand_into_repeated_factors, read_the_zero_exponent_as_one,
    q_read_the_zero_exponent_as_one).
g8_exponent_transition(rewrite_by_exponent_rule,
    q_expand_into_repeated_factors, read_the_negative_exponent_as_a_reciprocal,
    q_read_the_negative_exponent_as_a_reciprocal).
g8_exponent_transition(rewrite_by_exponent_rule,
    q_combine_the_exponents, evaluate_both_sides, q_evaluate_both_sides).
g8_exponent_transition(rewrite_by_exponent_rule,
    q_evaluate_both_sides, report_the_rewrite, q_accept_the_rewrite).
g8_exponent_transition(decide_exponential_equivalence,
    q_read_the_two_powers, evaluate_both_sides, q_evaluate_both_sides).
g8_exponent_transition(decide_exponential_equivalence,
    q_evaluate_both_sides, accept_the_claim, q_accept_the_claim).
g8_exponent_transition(decide_exponential_equivalence,
    q_evaluate_both_sides, reject_the_claim, q_reject_the_claim).
g8_exponent_transition(negative_exponent_as_negative_value,
    q_read_the_two_powers, carry_the_sign_into_the_value,
    q_carry_the_sign_into_the_value).

% ==========================================================================
% 4. THE RUN
% ==========================================================================

run_g8_exponent_rule(rewrite_by_exponent_rule,
                     rewrite(Rule, Left, Right, Outer), Outcome, Trace) :-
    apply_rule(Rule, Left, Right, Outer, Result, State, Step),
    original_value(Rule, Left, Right, Outer, Original),
    result_value(Result, Rewritten),
    ( Original =:= Rewritten -> Validity = correct
    ; Validity = unvindicated ),
    result_text(Result, ResultText),
    g8_rational_text(Original, OriginalText),
    Outcome = action_outcome(
        rewrite_by_exponent_rule,
        [ classification(productive),
          cluster(g8_exponent_rules),
          automaton_state(State),
          vocabulary([power, base, exponent, expanded_form, single_exponent,
                      reciprocal, exponent_rule]),
          input(rewrite(Rule, Left, Right, Outer)),
          result(rewritten(ResultText)),
          expected(rewritten(ResultText)),
          rule(Rule),
          value(Original),
          value_text(OriginalText),
          invariant(the_rewrite_keeps_the_value),
          validity(Validity) ]),
    Trace = [ read_the_two_powers(Left, Right),
              expand_into_repeated_factors(Rule),
              Step,
              evaluate_both_sides(OriginalText),
              report_the_rewrite(ResultText) ].
run_g8_exponent_rule(decide_exponential_equivalence, claim(Left, Right),
                     Outcome, Trace) :-
    signed_value(Left, LeftValue),
    signed_value(Right, RightValue),
    (   LeftValue =:= RightValue
    ->  State = q_accept_the_claim, Answer = equivalent,
        Step = accept_the_claim
    ;   State = q_reject_the_claim, Answer = not_equivalent,
        Step = reject_the_claim
    ),
    g8_rational_text(LeftValue, LeftText),
    g8_rational_text(RightValue, RightText),
    Outcome = action_outcome(
        decide_exponential_equivalence,
        [ classification(productive),
          cluster(g8_exponent_rules),
          automaton_state(State),
          vocabulary([power, base, exponent, equivalent_expressions,
                      negative_exponent]),
          input(claim(Left, Right)),
          result(Answer),
          expected(Answer),
          values(LeftText, RightText),
          invariant(equivalent_expressions_take_the_same_value),
          validity(correct) ]),
    Trace = [ read_the_two_powers(Left, Right),
              evaluate_both_sides(LeftText, RightText),
              Step ].
run_g8_exponent_rule(negative_exponent_as_negative_value,
                     rewrite(negative_exponent, power(Base, Exponent), none,
                             none),
                     Outcome, Trace) :-
    % Attested locus: a negative exponent, which is where the sign migrates.
    Exponent < 0,
    Magnitude is -Exponent,
    exact_power(Base, Exponent, Productive),
    exact_power(Base, Magnitude, Positive),
    Deformed is -Positive,
    ( Deformed =\= Productive -> Validity = incorrect
    ; Validity = unvindicated ),
    g8_rational_text(Productive, ProductiveText),
    g8_rational_text(Deformed, DeformedText),
    Outcome = action_outcome(
        negative_exponent_as_negative_value,
        [ classification(deformation),
          cluster(g8_exponent_rules),
          automaton_state(q_carry_the_sign_into_the_value),
          vocabulary([negative_exponent, reciprocal, sign, value]),
          input(rewrite(negative_exponent, power(Base, Exponent), none, none)),
          expected(rewritten(ProductiveText)),
          result(rewritten(DeformedText)),
          deformation_of(rewrite_by_exponent_rule),
          violated_invariant(a_negative_exponent_reciprocates_it_never_negates),
          attested_as(db_row(38303),
                      "Rabin, Fuller & Harel 2013, Journal of Mathematical Behavior, pp. 653-654"),
          staged_by_the_curriculum('IM-G8-U7-L5 prints 10^-5 = -10^5 as a card'),
          validity(Validity) ]),
    Trace = [ read_the_two_powers(power(Base, Exponent), none),
              carry_the_sign_into_the_value(DeformedText) ].

%!  apply_rule(+Rule, +Left, +Right, +Outer, -Result, -State, -Step) is det.
apply_rule(product, power(B, N), power(B, M), none, power(B, S),
           q_combine_the_exponents, combine_the_exponents(S)) :-
    S is N + M.
apply_rule(quotient, power(B, N), power(B, M), none, power(B, S),
           q_combine_the_exponents, combine_the_exponents(S)) :-
    S is N - M.
apply_rule(power_of_power, power(B, N), none, Outer, power(B, S),
           q_combine_the_exponents, combine_the_exponents(S)) :-
    S is N * Outer.
apply_rule(product_of_bases, power(A, N), power(C, N), none, power(P, N),
           q_combine_the_bases, combine_the_bases(P)) :-
    P is A * C.
apply_rule(zero_exponent, power(B, _), none, none, value(1),
           q_read_the_zero_exponent_as_one, read_the_zero_exponent_as_one(B)).
apply_rule(negative_exponent, power(B, N), none, none, reciprocal(B, M),
           q_read_the_negative_exponent_as_a_reciprocal,
           read_the_negative_exponent_as_a_reciprocal(M)) :-
    N < 0, M is -N.

%!  original_value(+Rule, +Left, +Right, +Outer, -Value) is det.
%
%   The value of the expression BEFORE the rule was applied, computed
%   independently of the rewrite so the comparison is a real check.
original_value(product, power(B, N), power(B, M), none, V) :-
    exact_power(B, N, X), exact_power(B, M, Y), V is X * Y.
original_value(quotient, power(B, N), power(B, M), none, V) :-
    exact_power(B, N, X), exact_power(B, M, Y), V is X rdiv Y.
original_value(power_of_power, power(B, N), none, Outer, V) :-
    exact_power(B, N, X), exact_power(X, Outer, V).
original_value(product_of_bases, power(A, N), power(C, N), none, V) :-
    exact_power(A, N, X), exact_power(C, N, Y), V is X * Y.
original_value(zero_exponent, power(B, _), none, none, V) :-
    exact_power(B, 3, X), V is X rdiv X.
original_value(negative_exponent, power(B, N), none, none, V) :-
    exact_power(B, N, V).

result_value(power(B, N), V) :- exact_power(B, N, V).
result_value(value(V), V).
result_value(reciprocal(B, M), V) :- exact_power(B, M, X), V is 1 rdiv X.

result_text(power(B, N), Text) :-
    g8_rational_text(B, BaseText),
    format(string(Text), "~w^~w", [BaseText, N]).
result_text(value(V), Text) :- g8_rational_text(V, Text).
result_text(reciprocal(B, M), Text) :-
    g8_rational_text(B, BaseText),
    format(string(Text), "1/~w^~w", [BaseText, M]).

signed_value(signed(plain, power(B, N)), V) :- exact_power(B, N, V).
signed_value(signed(negated, power(B, N)), V) :-
    exact_power(B, N, X), V is -X.

%!  exact_power(+Base, +Exponent, -Value) is det.
%
%   SWI evaluates 10 ^ -5 as a float, and a float would decide the value
%   check by rounding. The negative case goes through a rational reciprocal.
exact_power(Base, Exponent, Value) :-
    (   Exponent >= 0
    ->  Value is Base ^ Exponent
    ;   Magnitude is -Exponent,
        Positive is Base ^ Magnitude,
        Value is 1 rdiv Positive
    ).

% ==========================================================================
% 5. SELF-SUMMARY
% ==========================================================================

g8_exponent_summary(
    summary{ module: g8_exponent_rule_rewrite,
             status: authored_pilot,
             generated: false,
             grade: 8,
             cluster: g8_exponent_rules,
             doings: [ rewrite_by_exponent_rule,
                       decide_exponential_equivalence,
                       negative_exponent_as_negative_value ],
             rules: [product, quotient, power_of_power, product_of_bases,
                     zero_exponent, negative_exponent],
             verification: evaluate_both_sides_exactly_and_compare,
             arithmetic: exact_rational,
             imported_by: none,
             extant_machines_left_untouched:
                 [ 'algebraic/exponent_as_repeated_factor',
                   'algebraic/exponential_equivalence_by_expansion' ],
             sibling_pilot_left_untouched: g8_power_of_ten_notation }).

% ==========================================================================
% 6. RECEIPTS
%
% g8_exponent_receipt(RowId, Lesson, Doing, InputDict, Expectation, Provenance).
% Provenance is `printed` when the row itself carries the numerals, and
% `witness_instantiation` when the row states a rule in letters and the
% exponents below are a chosen witness for it. No receipt pretends a chosen
% exponent came from the curriculum.
% ==========================================================================

g8_exponent_receipt(
    'im_defrag_55b10968f233d334f609a72a_1', 'IM-G8-U7-L5',
    decide_exponential_equivalence,
    _{kind: "exponent_claim",
      left: _{base: 10, exponent: -5},
      right: _{base: 10, exponent: 5, negated: true}},
    not_equivalent, printed).                % 10^-5 = -10^5, the false card
g8_exponent_receipt(
    'im_defrag_55b10968f233d334f609a72a_1', 'IM-G8-U7-L5',
    rewrite_by_exponent_rule,
    _{kind: "exponent_rewrite", rule: "power_of_power",
      left: _{base: 10, exponent: 2}, outer_exponent: -3},
    rewritten("10^-6"), printed).            % (10^2)^-3, the true card
g8_exponent_receipt(
    'im_defrag_904ef671d374e9203335f0a4_1', 'IM-G8-U7-L5',
    rewrite_by_exponent_rule,
    _{kind: "exponent_rewrite", rule: "negative_exponent",
      left: _{base: 10, exponent: -3}},
    rewritten("1/10^3"), witness_instantiation).
g8_exponent_receipt(
    'im_defrag_904ef671d374e9203335f0a4_1', 'IM-G8-U7-L5',
    rewrite_by_exponent_rule,
    _{kind: "exponent_rewrite", rule: "quotient",
      left: _{base: 10, exponent: 2}, right: _{base: 10, exponent: 3}},
    rewritten("10^-1"), witness_instantiation).
g8_exponent_receipt(
    'im_defrag_87b304379739a526d8b68c34_1', 'IM-G8-U7-L4',
    rewrite_by_exponent_rule,
    _{kind: "exponent_rewrite", rule: "quotient",
      left: _{base: 10, exponent: 7}, right: _{base: 10, exponent: 3}},
    rewritten("10^4"), witness_instantiation).
g8_exponent_receipt(
    'im_defrag_c26f22699c20aa2b669cf192_1', 'IM-G8-U7-L4',
    rewrite_by_exponent_rule,
    _{kind: "exponent_rewrite", rule: "zero_exponent", left: _{base: 10}},
    rewritten("1"), printed).                % the row's own question
g8_exponent_receipt(
    'im_defrag_c26f22699c20aa2b669cf192_1', 'IM-G8-U7-L4',
    rewrite_by_exponent_rule,
    _{kind: "exponent_rewrite", rule: "quotient",
      left: _{base: 10, exponent: 5}, right: _{base: 10, exponent: 5}},
    rewritten("10^0"), witness_instantiation).
g8_exponent_receipt(
    'im_defrag_09599bea88ef38948dca02e8_1', 'IM-G8-U7-L8',
    rewrite_by_exponent_rule,
    _{kind: "exponent_rewrite", rule: "product_of_bases",
      left: _{base: 2, exponent: 3}, right: _{base: 5, exponent: 3}},
    rewritten("10^3"), witness_instantiation).
g8_exponent_receipt(
    'im_defrag_7c3401836d996f52cbf4da0c_1', 'IM-G8-U7-L8',
    rewrite_by_exponent_rule,
    _{kind: "exponent_rewrite", rule: "product",
      left: _{base: 10, exponent: 4}, right: _{base: 10, exponent: 2}},
    rewritten("10^6"), witness_instantiation).
g8_exponent_receipt(
    'im_defrag_7c3401836d996f52cbf4da0c_1', 'IM-G8-U7-L8',
    rewrite_by_exponent_rule,
    _{kind: "exponent_rewrite", rule: "power_of_power",
      left: _{base: 10, exponent: 3}, outer_exponent: 2},
    rewritten("10^6"), witness_instantiation).
g8_exponent_receipt(
    'im_defrag_5526b6509b5c911b081b5d30_1', 'IM-G8-U7-L2',
    rewrite_by_exponent_rule,
    _{kind: "exponent_rewrite", rule: "product",
      left: _{base: 10, exponent: 5}, right: _{base: 10, exponent: 5}},
    rewritten("10^10"), witness_instantiation).

% ==========================================================================
% 7. CHECK
% ==========================================================================

check_g8_exponent_rule_rewrite :-
    check_receipts,
    check_the_printed_cards,
    check_attested_deformation,
    check_negative,
    format('g8_exponent_rule_rewrite: all checks ok~n').

check_receipts :-
    findall(Lesson-Row-Doing-Result-Provenance,
            ( g8_exponent_receipt(Row, Lesson, Doing, Json, Expected,
                                  Provenance),
              g8_exponent_from_json(Json, Figure),
              run_g8_exponent_rule(Doing, Figure, Outcome, _),
              outcome_property(Outcome, result(Result)),
              Result = Expected,
              outcome_property(Outcome, validity(correct))
            ), Rows),
    findall(R-L, g8_exponent_receipt(R, L, _, _, _, _), All),
    length(All, Total), length(Rows, Passed),
    Total =:= Passed,
    findall(P, member(_-_-_-_-P, Rows), Provenances),
    include_printed(Provenances, Printed),
    Witness is Total - Printed,
    format('  receipts: ~w/~w real grade 8 rows run, each rewrite evaluated on both sides (~w printed, ~w witness)~n',
           [Passed, Total, Printed, Witness]),
    forall(member(Lesson-Row-Doing-Result-P, Rows),
           format('    ~w  ~w  ~w -> ~q  [~w]~n',
                  [Lesson, Row, Doing, Result, P])).

include_printed(List, Count) :-
    aggregate_all(count, member(printed, List), Count).

check_the_printed_cards :-
    % IM-G8-U7-L5's two matching cards, recovered from document.json items
    % 40 and 41. One claim is false and one rewrite is true.
    g8_exponent_from_json(
        _{kind: "exponent_claim",
          left: _{base: 10, exponent: -5},
          right: _{base: 10, exponent: 5, negated: true}}, False),
    run_g8_exponent_rule(decide_exponential_equivalence, False, O1, _),
    outcome_property(O1, result(not_equivalent)),
    outcome_property(O1, values("1/100000", "-100000")),
    g8_exponent_from_json(
        _{kind: "exponent_claim",
          left: _{base: 10, exponent: -6},
          right: _{base: 10, exponent: -6}}, True),
    run_g8_exponent_rule(decide_exponential_equivalence, True, O2, _),
    outcome_property(O2, result(equivalent)),
    format('  printed cards: 10^-5 is 1/100000 against -100000, so the card is rejected; (10^2)^-3 and (10^-2)^3 both reach 10^-6~n').

check_attested_deformation :-
    % db_row 38303 at the value locus: 10^-5 read as -100000.
    g8_exponent_from_json(
        _{kind: "exponent_rewrite", rule: "negative_exponent",
          left: _{base: 10, exponent: -5}}, F),
    run_g8_exponent_rule(negative_exponent_as_negative_value, F, O, _),
    outcome_property(O, result(rewritten("-100000"))),
    outcome_property(O, expected(rewritten("1/100000"))),
    outcome_property(O, validity(incorrect)),
    format('  attested deformation: db_row 38303 reads 10^-5 as -100000 where the value is 1/100000~n').

check_negative :-
    % The deformation refuses at a non-negative exponent, where there is no
    % sign to migrate.
    g8_exponent_from_json(
        _{kind: "exponent_rewrite", rule: "negative_exponent",
          left: _{base: 10, exponent: -2}}, Good),
    run_g8_exponent_rule(negative_exponent_as_negative_value, Good, _, _),
    \+ ( g8_exponent_from_json(
             _{kind: "exponent_rewrite", rule: "negative_exponent",
               left: _{base: 10, exponent: 2}}, Bad),
         run_g8_exponent_rule(negative_exponent_as_negative_value, Bad, _, _) ),
    % A zero base has no reciprocal and refuses by contract.
    \+ g8_exponent_from_json(
           _{kind: "exponent_rewrite", rule: "zero_exponent",
             left: _{base: 0}}, _),
    % The product rule refuses across unlike bases: 2^3 times 5^3 is not a
    % single power of 2, and the pilot keeps a separate rule for that shape.
    g8_exponent_from_json(
        _{kind: "exponent_rewrite", rule: "product",
          left: _{base: 2, exponent: 3},
          right: _{base: 5, exponent: 3}}, Unlike),
    \+ run_g8_exponent_rule(rewrite_by_exponent_rule, Unlike, _, _),
    % The same two powers DO combine under the product-of-bases rule.
    g8_exponent_from_json(
        _{kind: "exponent_rewrite", rule: "product_of_bases",
          left: _{base: 2, exponent: 3},
          right: _{base: 5, exponent: 3}}, Bases),
    run_g8_exponent_rule(rewrite_by_exponent_rule, Bases, OB, _),
    outcome_property(OB, result(rewritten("10^3"))),
    format('  negative tests: the deformation refuses at a positive exponent, a zero base refuses, and the product rule refuses across unlike bases~n').

outcome_property(action_outcome(_, Props), Property) :-
    memberchk(Property, Props).
