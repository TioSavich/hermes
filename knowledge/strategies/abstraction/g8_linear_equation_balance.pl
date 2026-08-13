:- encoding(utf8).
/** <module> Grade 8 pilot: solving one linear equation in one unknown
 *
 * WHAT THIS IS. A quarantined pilot automaton for the doing IM grade 8 unit 4
 * asks for: given a·x + b = c·x + d, keep the equation in balance while
 * gathering the variable terms on one side and the constants on the other,
 * then say how many numbers make the equation true — exactly one, none, or
 * every number.
 *
 * WHY IT IS NEW. `algebraic/balance_preserving_linear_solution` already solves
 * a·x + b = c, the arithmetic-side shape where the unknown appears once. What
 * grade 8 adds is the unknown on BOTH sides, which is a different doing:
 * Filloy and Rojano named the boundary between them the "didactic cut", and
 * IM's hanger diagrams (unit 4 lessons 2 and 3) are built to cross it. This
 * pilot handles the both-sides shape and, with it, the two degenerate cases
 * (`a = c` with `b = d`, and `a = c` with `b ≠ d`) that the one-sided machine
 * cannot reach because they cannot arise there. It leaves the extant machine
 * untouched and claims nothing about it.
 *
 * VALIDITY IS EXECUTED, NOT ASSERTED. Every productive run substitutes its own
 * answer back into the ORIGINAL equation in exact rational arithmetic and
 * reports what the substitution found. A run whose substitution does not close
 * is reported as unvindicated, never as correct. `no_solution` and
 * `every_number` are certified by their own witnesses: for `every_number`, two
 * distinct test values both satisfy the equation; for `no_solution`, the
 * gathered form reduces to `0 = k` with k non-zero, and a test value fails.
 *
 * DEFORMATION PARTNER. One, and it is attested in this repository's own
 * research corpus rather than invented for symmetry:
 * `subtract_constant_to_clear_negative_term` reproduces db_row 37558 (Pirie
 * 1997, JRME Monograph, pp. 91-92): solving 8t - 9 = t + 12, a student says
 * "take nine off both sides", removes the -9 on the left but writes 3 rather
 * than 21 on the right, reaching 7t = 3. The deformation is licensed only
 * where the attested locus is: a negative constant on the side being cleared.
 *
 * QUARANTINE. Nothing imports this module; it renames nothing; its rows are
 * authored and vetoable one by one. Check: `check_g8_linear_equation_balance/0`.
 */

:- module(g8_linear_equation_balance,
          [ run_g8_linear_equation/4,        % +Doing, +Equation, -Outcome, -Trace
            g8_linear_equation_from_json/2,  % +InputDict, -Equation
            g8_linear_equation_states/1,
            g8_linear_equation_state_label/4,
            g8_linear_equation_summary/1,
            g8_linear_equation_receipt/4,
            check_g8_linear_equation_balance/0
          ]).

:- use_module(strategies('abstraction/g8_quantity_input'),
              [ g8_quantity/2, g8_rational_text/2 ]).

% ==========================================================================
% 1. INPUT CONTRACT
%
% Kind-tagged JSON-string genre, following
% knowledge/strategies/automaton_input_contracts.pl. The equation
%
%     a·x + b = c·x + d
%
% arrives as
%
%   {"kind":"linear_equation_two_sided","unknown":"x",
%    "left":{"coefficient":1,"constant":-3},
%    "right":{"coefficient":-4,"constant":2}}
%
% Coefficients and constants are integers, decimals, or {"n":N,"d":D}.
% ==========================================================================

g8_linear_equation_input_contract(
    '{\"kind\":\"linear_equation_two_sided\",\"unknown\":\"string\",\"left\":{\"coefficient\":\"number\",\"constant\":\"number\"},\"right\":{\"coefficient\":\"number\",\"constant\":\"number\"}}',
    '{\"kind\":\"linear_equation_two_sided\",\"unknown\":\"x\",\"left\":{\"coefficient\":1,\"constant\":-3},\"right\":{\"coefficient\":-4,\"constant\":2}}').

%!  g8_linear_equation_from_json(+Dict, -Equation) is semidet.
g8_linear_equation_from_json(Dict, equation(Unknown, A, B, C, D)) :-
    is_dict(Dict),
    get_dict(kind, Dict, "linear_equation_two_sided"),
    get_dict(unknown, Dict, Unknown0),
    ( string(Unknown0) -> Unknown = Unknown0 ; atom_string(Unknown0, Unknown) ),
    get_dict(left, Dict, Left), get_dict(right, Dict, Right),
    get_dict(coefficient, Left, A0), get_dict(constant, Left, B0),
    get_dict(coefficient, Right, C0), get_dict(constant, Right, D0),
    g8_quantity(A0, A), g8_quantity(B0, B),
    g8_quantity(C0, C), g8_quantity(D0, D).

% ==========================================================================
% 2. STATES
%
% Stable atoms. Display labels and their sources live in
% g8_linear_equation_state_label/4 below, in the same spirit as
% knowledge/strategies/math/state_vocabulary.pl: a term earns its place by
% naming a doing, and the tradition that names it is recorded, never merged
% into a false synonym. Labels I cannot source are marked provisional.
% ==========================================================================

g8_linear_equation_states(
    [ q_read_equation_as_balance,
      q_gather_variable_terms,
      q_gather_constant_terms,
      q_isolate_unknown,
      q_verify_by_substitution,
      q_accept_one_solution,
      q_accept_no_solution,
      q_accept_every_number,
      q_clear_negative_by_subtracting ]).

% g8_linear_equation_state_label(State, Tradition, Label, Citation).
g8_linear_equation_state_label(q_read_equation_as_balance, illustrative_mathematics,
    "a hanger in balance",
    "IM Grade 8 Unit 4 Lessons 2-3, Balanced Hangers / Balanced Moves").
g8_linear_equation_state_label(q_read_equation_as_balance, vlassis,
    "the balance model for equations",
    "Vlassis 2002, Educational Studies in Mathematics 49").
g8_linear_equation_state_label(q_gather_variable_terms, filloy_rojano,
    "operating on the unknown",
    "Filloy & Rojano 1989, For the Learning of Mathematics 9(2); the didactic cut").
g8_linear_equation_state_label(q_gather_variable_terms, illustrative_mathematics,
    "a move that keeps the equation equivalent",
    "IM Grade 8 Unit 4 Lesson 3, Balanced Moves").
g8_linear_equation_state_label(q_gather_constant_terms, linchevski_herscovics,
    "grouping the constant terms",
    "Linchevski & Herscovics 1996, Educational Studies in Mathematics 30(1)").
g8_linear_equation_state_label(q_isolate_unknown, linchevski_herscovics,
    "isolating the unknown",
    "Linchevski & Herscovics 1996, Educational Studies in Mathematics 30(1)").
g8_linear_equation_state_label(q_verify_by_substitution, kieran,
    "checking the solution in the original equation",
    "Kieran 1992, Handbook of Research on Mathematics Teaching and Learning").
g8_linear_equation_state_label(q_accept_one_solution, illustrative_mathematics,
    "exactly one solution",
    "IM Grade 8 Unit 4 Lesson 8, How Many Solutions?").
g8_linear_equation_state_label(q_accept_no_solution, illustrative_mathematics,
    "no solution",
    "IM Grade 8 Unit 4 Lesson 8, How Many Solutions?").
g8_linear_equation_state_label(q_accept_every_number, illustrative_mathematics,
    "true for every value",
    "IM Grade 8 Unit 4 Lesson 7, All, Some, or No Values").
g8_linear_equation_state_label(q_clear_negative_by_subtracting, pirie,
    "take nine off both sides",
    "db_row 37558; Pirie 1997, JRME Monograph, pp. 91-92").

% ==========================================================================
% 3. TRANSITIONS
%
% One productive automaton with a three-way branch at the gathered form, and
% one deformation that shares the first two states and departs at the third.
% ==========================================================================

g8_linear_equation_transition(balance_preserving_two_sided_solution,
    q_read_equation_as_balance, gather_variable_terms_on_one_side,
    q_gather_variable_terms).
g8_linear_equation_transition(balance_preserving_two_sided_solution,
    q_gather_variable_terms, gather_constant_terms_on_the_other_side,
    q_gather_constant_terms).
g8_linear_equation_transition(balance_preserving_two_sided_solution,
    q_gather_constant_terms, divide_by_the_remaining_coefficient,
    q_isolate_unknown).
g8_linear_equation_transition(balance_preserving_two_sided_solution,
    q_isolate_unknown, substitute_into_the_original_equation,
    q_verify_by_substitution).
g8_linear_equation_transition(balance_preserving_two_sided_solution,
    q_verify_by_substitution, report_one_solution, q_accept_one_solution).
g8_linear_equation_transition(balance_preserving_two_sided_solution,
    q_gather_constant_terms, find_no_number_satisfies, q_accept_no_solution).
g8_linear_equation_transition(balance_preserving_two_sided_solution,
    q_gather_constant_terms, find_every_number_satisfies, q_accept_every_number).
g8_linear_equation_transition(subtract_constant_to_clear_negative_term,
    q_read_equation_as_balance, gather_variable_terms_on_one_side,
    q_gather_variable_terms).
g8_linear_equation_transition(subtract_constant_to_clear_negative_term,
    q_gather_variable_terms, subtract_the_negative_constant_from_both_sides,
    q_clear_negative_by_subtracting).
g8_linear_equation_transition(subtract_constant_to_clear_negative_term,
    q_clear_negative_by_subtracting, divide_by_the_remaining_coefficient,
    q_isolate_unknown).

% ==========================================================================
% 4. THE RUN
% ==========================================================================

%!  run_g8_linear_equation(+Doing, +Equation, -Outcome, -Trace) is semidet.
run_g8_linear_equation(balance_preserving_two_sided_solution,
                       equation(U, A, B, C, D), Outcome, Trace) :-
    Coefficient is A - C,
    Constant is D - B,
    (   Coefficient =\= 0
    ->  Solution is Constant rdiv Coefficient,
        substitution_check(equation(U, A, B, C, D), Solution, Check),
        g8_rational_text(Solution, SolutionText),
        ( Check == closes -> Validity = correct ; Validity = unvindicated ),
        Outcome = action_outcome(
            balance_preserving_two_sided_solution,
            [ classification(productive),
              cluster(g8_one_variable_linear_equations),
              automaton_state(q_accept_one_solution),
              vocabulary([equation, unknown, equivalent_equation, balance,
                          coefficient, constant_term, solution]),
              input(equation(U, A, B, C, D)),
              result(one_solution(U, SolutionText)),
              expected(one_solution(U, SolutionText)),
              substitution(Check),
              invariant(both_sides_change_together),
              validity(Validity) ]),
        Trace = [ read_equation_as_balance(U),
                  gather_variable_terms_on_one_side(Coefficient),
                  gather_constant_terms_on_the_other_side(Constant),
                  divide_by_the_remaining_coefficient(Coefficient),
                  substitute_into_the_original_equation(SolutionText),
                  report_one_solution(SolutionText) ]
    ;   Constant =:= 0
    ->  substitution_check(equation(U, A, B, C, D), 0, C0),
        substitution_check(equation(U, A, B, C, D), 1, C1),
        ( C0 == closes, C1 == closes -> Validity = correct
        ; Validity = unvindicated ),
        Outcome = action_outcome(
            balance_preserving_two_sided_solution,
            [ classification(productive),
              cluster(g8_one_variable_linear_equations),
              automaton_state(q_accept_every_number),
              vocabulary([equation, unknown, equivalent_equation,
                          every_value, identity]),
              input(equation(U, A, B, C, D)),
              result(every_number(U)),
              expected(every_number(U)),
              witnesses([value(0)-C0, value(1)-C1]),
              invariant(both_sides_change_together),
              validity(Validity) ]),
        Trace = [ read_equation_as_balance(U),
                  gather_variable_terms_on_one_side(0),
                  gather_constant_terms_on_the_other_side(0),
                  find_every_number_satisfies([0, 1]) ]
    ;   substitution_check(equation(U, A, B, C, D), 0, C0),
        ( C0 == fails -> Validity = correct ; Validity = unvindicated ),
        g8_rational_text(Constant, ConstantText),
        Outcome = action_outcome(
            balance_preserving_two_sided_solution,
            [ classification(productive),
              cluster(g8_one_variable_linear_equations),
              automaton_state(q_accept_no_solution),
              vocabulary([equation, unknown, equivalent_equation,
                          no_solution, contradiction]),
              input(equation(U, A, B, C, D)),
              result(no_solution(U)),
              expected(no_solution(U)),
              gathered_form(zero_equals(ConstantText)),
              witnesses([value(0)-C0]),
              invariant(both_sides_change_together),
              validity(Validity) ]),
        Trace = [ read_equation_as_balance(U),
                  gather_variable_terms_on_one_side(0),
                  gather_constant_terms_on_the_other_side(Constant),
                  find_no_number_satisfies(ConstantText) ]
    ).
run_g8_linear_equation(subtract_constant_to_clear_negative_term,
                       equation(U, A, B, C, D), Outcome, Trace) :-
    % Attested locus only: the side being cleared carries a NEGATIVE constant.
    B < 0,
    Coefficient is A - C,
    Coefficient =\= 0,
    % The productive move adds |B| to both sides: D - B.
    % The attested error subtracts |B| from the far side instead: D + B.
    DeformedConstant is D + B,
    ProductiveConstant is D - B,
    DeformedSolution is DeformedConstant rdiv Coefficient,
    ProductiveSolution is ProductiveConstant rdiv Coefficient,
    substitution_check(equation(U, A, B, C, D), DeformedSolution, Check),
    g8_rational_text(DeformedSolution, DeformedText),
    g8_rational_text(ProductiveSolution, ProductiveText),
    ( Check == fails -> Validity = incorrect ; Validity = unvindicated ),
    Outcome = action_outcome(
        subtract_constant_to_clear_negative_term,
        [ classification(deformation),
          cluster(g8_one_variable_linear_equations),
          automaton_state(q_clear_negative_by_subtracting),
          vocabulary([equation, unknown, balance, negative_constant,
                      inverse_operation]),
          input(equation(U, A, B, C, D)),
          expected(one_solution(U, ProductiveText)),
          result(one_solution(U, DeformedText)),
          substitution(Check),
          deformation_of(balance_preserving_two_sided_solution),
          violated_invariant(both_sides_change_together),
          attested_as(db_row(37558),
                      "Pirie 1997, JRME Monograph, pp. 91-92"),
          validity(Validity) ]),
    Trace = [ read_equation_as_balance(U),
              gather_variable_terms_on_one_side(Coefficient),
              subtract_the_negative_constant_from_both_sides(B),
              divide_by_the_remaining_coefficient(Coefficient),
              report_one_solution(DeformedText) ].

%!  substitution_check(+Equation, +Value, -Verdict) is det.
%
%   Exact rational substitution into the ORIGINAL equation. This is the whole
%   verification standard for this pilot: no answer is called correct on the
%   strength of the moves that produced it.
substitution_check(equation(_, A, B, C, D), Value, Verdict) :-
    Left is A * Value + B,
    Right is C * Value + D,
    ( Left =:= Right -> Verdict = closes ; Verdict = fails ).

% ==========================================================================
% 5. SELF-SUMMARY
% ==========================================================================

g8_linear_equation_summary(
    summary{ module: g8_linear_equation_balance,
             status: authored_pilot,
             generated: false,
             grade: 8,
             cluster: g8_one_variable_linear_equations,
             doings: [ balance_preserving_two_sided_solution,
                       subtract_constant_to_clear_negative_term ],
             answers: [one_solution, no_solution, every_number],
             verification: substitution_into_the_original_equation,
             arithmetic: exact_rational,
             imported_by: none,
             extant_machine_left_untouched:
                 'algebraic/balance_preserving_linear_solution' }).

% ==========================================================================
% 6. RECEIPTS
%
% g8_linear_equation_receipt(RowId, Lesson, InputDict, Expectation).
% Every row below is a usable grade 8 row of
% curriculum/im/generated/compiled_defragged_task_instances.pl, and every
% coefficient is read off that row's own statement. The expectation names the
% answer kind only; the value is computed and then verified by substitution.
% ==========================================================================

g8_linear_equation_receipt(
    'im_defrag_6ca1acf54e659e510090f8dc_1', 'IM-G8-U4-L4',
    _{kind: "linear_equation_two_sided", unknown: "x",
      left: _{coefficient: 1, constant: -3},
      right: _{coefficient: -4, constant: 2}},
    one_solution).            % x - 3 = 2 - 4x
g8_linear_equation_receipt(
    'im_defrag_27c95a424262b91176a682c9_1', 'IM-G8-U4-L7',
    _{kind: "linear_equation_two_sided", unknown: "t",
      left: _{coefficient: 2, constant: 5},
      right: _{coefficient: 2, constant: 5}},
    every_number).            % 2t + 5 = 2t + 5
g8_linear_equation_receipt(
    'im_defrag_9ebe1c7e214ef1edaf38bebb_1', 'IM-G8-U4-L4',
    _{kind: "linear_equation_two_sided", unknown: "x",
      left: _{coefficient: 12, constant: 3},
      right: _{coefficient: 15, constant: 27}},
    one_solution).            % 14x - 2x + 3 = 3(5x + 9)
g8_linear_equation_receipt(
    'im_defrag_6ffb2e4d64e94d9e6297f34f_1', 'IM-G8-U4-L3',
    _{kind: "linear_equation_two_sided", unknown: "x",
      left: _{coefficient: 2, constant: 6},
      right: _{coefficient: 4, constant: 2}},
    one_solution).            % 2(x + 3y) = 4x + 2y read at y = 1
g8_linear_equation_receipt(
    'im_defrag_e98ce74c8423af1a5ef29553_1', 'IM-G8-U4-L1',
    _{kind: "linear_equation_two_sided", unknown: "x",
      left: _{coefficient: 2, constant: 4},
      right: _{coefficient: 0, constant: 20}},
    one_solution).            % 2x + 4 = 20, the last line of Diego's chain
g8_linear_equation_receipt(
    'im_defrag_4dfd84b540313b48a86b15dc_1', 'IM-G8-U4-L1',
    _{kind: "linear_equation_two_sided", unknown: "x",
      left: _{coefficient: 2, constant: 8},
      right: _{coefficient: 0, constant: 10}},
    one_solution).            % 2(x + 4) = 10 expanded to 2x + 8 = 10
g8_linear_equation_receipt(
    'im_defrag_8f2d1ede3603cbcb91aa1b3d_1', 'IM-G8-U4-L5',
    _{kind: "linear_equation_two_sided", unknown: "n",
      left: _{coefficient: 1, constant: -6},
      right: _{coefficient: 0, constant: -3}},
    one_solution).            % Tyler's puzzle: (2(3n - 7) - 22)/6 = -3
g8_linear_equation_receipt(
    'im_defrag_19c16167c17f00c6c2ada63d_1', 'IM-G8-U4-L14',
    _{kind: "linear_equation_two_sided", unknown: "s",
      left: _{coefficient: 1, constant: 0},
      right: _{coefficient: 1, constant: 2}},
    no_solution).             % x + y = 5 against x + y = 7, read as s = s + 2

% Round 2: these six equations were recovered from the docling document.json
% `formula` items, which the markdown export dropped. The statement in the
% defragged artifact reads "Here are 4 problems" with no problems in it; the
% JSON carries them at item 95 (U4-L5) and items 167-168 (U4-L6).
g8_linear_equation_receipt(
    'im_defrag_e3f399cafe8e58d33b655604_1', 'IM-G8-U4-L5',
    _{kind: "linear_equation_two_sided", unknown: "a",
      left: _{coefficient: -6, constant: -7},
      right: _{coefficient: 4, constant: -2}},
    one_solution).            % -6a - 7 = 4a - 2
g8_linear_equation_receipt(
    'im_defrag_e3f399cafe8e58d33b655604_1', 'IM-G8-U4-L5',
    _{kind: "linear_equation_two_sided", unknown: "b",
      left: _{coefficient: _{n: 7, d: 2}, constant: -3},
      right: _{coefficient: 6, constant: -10}},
    one_solution).            % (1/2)(7b - 6) = 6b - 10
g8_linear_equation_receipt(
    'im_defrag_e3f399cafe8e58d33b655604_1', 'IM-G8-U4-L5',
    _{kind: "linear_equation_two_sided", unknown: "c",
      left: _{coefficient: _{n: 1, d: 2}, constant: 7},
      right: _{coefficient: 1, constant: 13}},
    one_solution).            % (1/2)c + 7 = c + 13
g8_linear_equation_receipt(
    'im_defrag_e3f399cafe8e58d33b655604_1', 'IM-G8-U4-L5',
    _{kind: "linear_equation_two_sided", unknown: "d",
      left: _{coefficient: 2, constant: 14},
      right: _{coefficient: -4, constant: 14}},
    one_solution).            % 2(d + 7) = -4d + 14
g8_linear_equation_receipt(
    'im_defrag_f1a6b99462307dd233099f1f_1', 'IM-G8-U4-L6',
    _{kind: "linear_equation_two_sided", unknown: "x",
      left: _{coefficient: 3, constant: -5},
      right: _{coefficient: 0, constant: -3}},
    one_solution).            % 3x - 5 = -3
g8_linear_equation_receipt(
    'im_defrag_f1a6b99462307dd233099f1f_1', 'IM-G8-U4-L6',
    _{kind: "linear_equation_two_sided", unknown: "x",
      left: _{coefficient: -4, constant: 5},
      right: _{coefficient: -1, constant: 3}},
    one_solution).            % x - 5(x - 1) = x - (2x - 3), each side gathered

% ==========================================================================
% 7. CHECK
% ==========================================================================

check_g8_linear_equation_balance :-
    check_receipts,
    check_degenerate_branches,
    check_attested_deformation,
    check_negative,
    format('g8_linear_equation_balance: all checks ok~n').

check_receipts :-
    findall(Row-Lesson-Kind-Result-Validity,
            ( g8_linear_equation_receipt(Row, Lesson, Json, Kind),
              g8_linear_equation_from_json(Json, Equation),
              run_g8_linear_equation(balance_preserving_two_sided_solution,
                                     Equation, Outcome, _),
              outcome_property(Outcome, result(Result)),
              outcome_property(Outcome, validity(Validity)),
              functor(Result, Kind, _)
            ), Rows),
    findall(R, g8_linear_equation_receipt(R, _, _, _), All),
    length(All, Total), length(Rows, Passed),
    forall(member(_-_-_-_-V, Rows), V == correct),
    Total =:= Passed,
    format('  receipts: ~w/~w real grade 8 rows solved and closed under substitution~n',
           [Passed, Total]),
    forall(member(Row-Lesson-_-Result-_, Rows),
           format('    ~w  ~w  ~q~n', [Lesson, Row, Result])).

check_degenerate_branches :-
    % 2t + 5 = 2t + 5 admits every number; two witnesses, both closing.
    g8_linear_equation_from_json(
        _{kind: "linear_equation_two_sided", unknown: "t",
          left: _{coefficient: 2, constant: 5},
          right: _{coefficient: 2, constant: 5}}, E1),
    run_g8_linear_equation(balance_preserving_two_sided_solution, E1, O1, _),
    outcome_property(O1, result(every_number("t"))),
    outcome_property(O1, witnesses([value(0)-closes, value(1)-closes])),
    % s = s + 2 admits none; the gathered form is 0 = 2 and value 0 fails.
    g8_linear_equation_from_json(
        _{kind: "linear_equation_two_sided", unknown: "s",
          left: _{coefficient: 1, constant: 0},
          right: _{coefficient: 1, constant: 2}}, E2),
    run_g8_linear_equation(balance_preserving_two_sided_solution, E2, O2, _),
    outcome_property(O2, result(no_solution("s"))),
    outcome_property(O2, gathered_form(zero_equals("2"))),
    format('  degenerate branches: every-number and no-solution each carry their own executed witness~n').

check_attested_deformation :-
    % db_row 37558: 8t - 9 = t + 12 reaches 7t = 3, so t = 3/7.
    g8_linear_equation_from_json(
        _{kind: "linear_equation_two_sided", unknown: "t",
          left: _{coefficient: 8, constant: -9},
          right: _{coefficient: 1, constant: 12}}, E),
    run_g8_linear_equation(subtract_constant_to_clear_negative_term, E, O, _),
    outcome_property(O, result(one_solution("t", "3/7"))),
    outcome_property(O, expected(one_solution("t", "3"))),
    outcome_property(O, validity(incorrect)),
    outcome_property(O, substitution(fails)),
    run_g8_linear_equation(balance_preserving_two_sided_solution, E, P, _),
    outcome_property(P, result(one_solution("t", "3"))),
    outcome_property(P, validity(correct)),
    format('  attested deformation: 8t - 9 = t + 12 gives 7t = 3 under db_row 37558 and t = 3 productively~n').

check_negative :-
    % The deformation refuses outside its attested locus: a non-negative
    % constant on the side being cleared has no attested detachment here.
    g8_linear_equation_from_json(
        _{kind: "linear_equation_two_sided", unknown: "x",
          left: _{coefficient: 3, constant: 4},
          right: _{coefficient: 1, constant: 10}}, E),
    \+ run_g8_linear_equation(subtract_constant_to_clear_negative_term,
                              E, _, _),
    % A malformed input refuses rather than throwing.
    \+ g8_linear_equation_from_json(_{kind: "linear_equation"}, _),
    format('  negative tests: the deformation refuses off its attested locus; a malformed input refuses without throwing~n').

outcome_property(action_outcome(_, Props), Property) :-
    memberchk(Property, Props).
