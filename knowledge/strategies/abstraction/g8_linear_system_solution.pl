:- encoding(utf8).
/** <module> Grade 8 pilot: solving a system of two linear equations
 *
 * WHAT THIS IS. A quarantined pilot automaton for the doing IM grade 8 unit 4
 * asks for from lesson 12 onward: read two linear relations in two unknowns,
 * combine them so one unknown drops out, recover the other, and say whether
 * the pair meets once, never, or everywhere.
 *
 * WHY IT IS NEW. Nothing in the registry takes two equations at once. The
 * closest extant machines take a single equation
 * (`algebraic/balance_preserving_linear_solution`) or a single relation
 * (`ratio/inscribe_proportional_equation`); a system is a different doing,
 * and the three-way answer — one solution, none, infinitely many — has no
 * single-equation analogue. The pilot leaves both machines untouched.
 *
 * VERIFICATION IS SUBSTITUTION INTO BOTH EQUATIONS. A solution pair is
 * reported correct only when it satisfies BOTH original equations in exact
 * rational arithmetic. A pair that closes one and misses the other is reported
 * unvindicated, which is the discipline a graph-read intersection does not
 * supply on its own. `no_solution` and `infinitely_many` carry their own
 * witnesses: the parallel case shows one test pair that satisfies the first
 * equation and fails the second; the coincident case shows two distinct pairs
 * that satisfy both.
 *
 * NO DEFORMATION PARTNER. This repository's research corpus carries no row
 * that attests a systems-specific student error at this locus; the nearby
 * rows are about slope, about the equals sign, and about single equations,
 * and each of those already has its partner elsewhere. Rather than invent one
 * for symmetry, this pilot ships with none and says so.
 *
 * QUARANTINE. Nothing imports this module; it renames nothing; its rows are
 * authored and vetoable one by one.
 * Check: `check_g8_linear_system_solution/0`.
 */

:- module(g8_linear_system_solution,
          [ run_g8_linear_system/4,
            g8_linear_system_from_json/2,
            g8_linear_system_states/1,
            g8_linear_system_state_label/4,
            g8_linear_system_summary/1,
            g8_linear_system_receipt/4,
            check_g8_linear_system_solution/0
          ]).

:- use_module(strategies('abstraction/g8_quantity_input'),
              [ g8_quantity/2, g8_rational_text/2 ]).

% ==========================================================================
% 1. INPUT CONTRACT
%
% Each equation arrives in the standard form a·x + b·y = c:
%
%   {"kind":"linear_system_two_unknowns","unknowns":["x","y"],
%    "equations":[{"a":1,"b":1,"c":5},{"a":1,"b":1,"c":7}]}
% ==========================================================================

g8_linear_system_input_contract(
    '{\"kind\":\"linear_system_two_unknowns\",\"unknowns\":[\"string\"],\"equations\":[{\"a\":\"number\",\"b\":\"number\",\"c\":\"number\"}]}',
    '{\"kind\":\"linear_system_two_unknowns\",\"unknowns\":[\"x\",\"y\"],\"equations\":[{\"a\":1,\"b\":1,\"c\":5},{\"a\":1,\"b\":1,\"c\":7}]}').

g8_linear_system_from_json(Dict, system(U1, U2, row(A1, B1, C1), row(A2, B2, C2))) :-
    is_dict(Dict),
    get_dict(kind, Dict, "linear_system_two_unknowns"),
    get_dict(unknowns, Dict, [U1, U2]),
    string(U1), string(U2), U1 \== U2,
    get_dict(equations, Dict, [First, Second]),
    equation_row(First, A1, B1, C1),
    equation_row(Second, A2, B2, C2),
    \+ ( A1 =:= 0, B1 =:= 0 ),
    \+ ( A2 =:= 0, B2 =:= 0 ).

equation_row(Dict, A, B, C) :-
    get_dict(a, Dict, A0), get_dict(b, Dict, B0), get_dict(c, Dict, C0),
    g8_quantity(A0, A), g8_quantity(B0, B), g8_quantity(C0, C).

% ==========================================================================
% 2. STATES
% ==========================================================================

g8_linear_system_states(
    [ q_read_both_relations,
      q_align_one_unknown,
      q_eliminate_one_unknown,
      q_solve_the_remaining_unknown,
      q_substitute_back_for_the_other,
      q_verify_in_both_equations,
      q_accept_one_pair,
      q_accept_no_pair,
      q_accept_every_pair_on_the_line ]).

% g8_linear_system_state_label(State, Tradition, Label, Citation).
g8_linear_system_state_label(q_read_both_relations, illustrative_mathematics,
    "two constraints on the same pair of quantities",
    "IM Grade 8 Unit 4 Lesson 10, On or Off the Line?").
g8_linear_system_state_label(q_eliminate_one_unknown, illustrative_mathematics,
    "adding or subtracting the equations to remove one variable",
    "IM Grade 8 Unit 4 Lesson 15, Solving Systems by Elimination").
g8_linear_system_state_label(q_substitute_back_for_the_other,
    illustrative_mathematics,
    "substituting the known value into either equation",
    "IM Grade 8 Unit 4 Lesson 14, Solving More Systems").
g8_linear_system_state_label(q_verify_in_both_equations, provisional,
    "check the pair in both equations",
    "provisional; no community label sourced for this checking step").
g8_linear_system_state_label(q_accept_one_pair, illustrative_mathematics,
    "the point where the two lines meet",
    "IM Grade 8 Unit 4 Lesson 12, Systems of Equations").
g8_linear_system_state_label(q_accept_no_pair, illustrative_mathematics,
    "parallel lines never meet, so the system has no solution",
    "IM Grade 8 Unit 4 Lesson 13, Solving Systems of Equations").
g8_linear_system_state_label(q_accept_every_pair_on_the_line,
    illustrative_mathematics,
    "the same line twice, so every point on it is a solution",
    "IM Grade 8 Unit 4 Lesson 13, Solving Systems of Equations").

% ==========================================================================
% 3. TRANSITIONS
% ==========================================================================

g8_linear_system_transition(elimination_with_substitution_back,
    q_read_both_relations, scale_to_align_one_unknown, q_align_one_unknown).
g8_linear_system_transition(elimination_with_substitution_back,
    q_align_one_unknown, subtract_to_remove_the_aligned_unknown,
    q_eliminate_one_unknown).
g8_linear_system_transition(elimination_with_substitution_back,
    q_eliminate_one_unknown, solve_the_remaining_unknown,
    q_solve_the_remaining_unknown).
g8_linear_system_transition(elimination_with_substitution_back,
    q_solve_the_remaining_unknown, substitute_back_for_the_other,
    q_substitute_back_for_the_other).
g8_linear_system_transition(elimination_with_substitution_back,
    q_substitute_back_for_the_other, substitute_into_both_originals,
    q_verify_in_both_equations).
g8_linear_system_transition(elimination_with_substitution_back,
    q_verify_in_both_equations, report_one_pair, q_accept_one_pair).
g8_linear_system_transition(elimination_with_substitution_back,
    q_eliminate_one_unknown, find_no_pair_satisfies, q_accept_no_pair).
g8_linear_system_transition(elimination_with_substitution_back,
    q_eliminate_one_unknown, find_the_same_line_twice,
    q_accept_every_pair_on_the_line).

% ==========================================================================
% 4. THE RUN
% ==========================================================================

run_g8_linear_system(elimination_with_substitution_back,
                     system(U1, U2, row(A1, B1, C1), row(A2, B2, C2)),
                     Outcome, Trace) :-
    Determinant is A1 * B2 - A2 * B1,
    (   Determinant =\= 0
    ->  X is (C1 * B2 - C2 * B1) rdiv Determinant,
        Y is (A1 * C2 - A2 * C1) rdiv Determinant,
        satisfies(row(A1, B1, C1), X, Y, First),
        satisfies(row(A2, B2, C2), X, Y, Second),
        ( First == closes, Second == closes -> Validity = correct
        ; Validity = unvindicated ),
        g8_rational_text(X, XText), g8_rational_text(Y, YText),
        Outcome = action_outcome(
            elimination_with_substitution_back,
            [ classification(productive),
              cluster(g8_systems_of_linear_equations),
              automaton_state(q_accept_one_pair),
              vocabulary([system_of_equations, two_unknowns, elimination,
                          substitution, intersection, solution_pair]),
              input(system(U1, U2, row(A1, B1, C1), row(A2, B2, C2))),
              result(one_pair(U1-XText, U2-YText)),
              expected(one_pair(U1-XText, U2-YText)),
              pair(X, Y),
              substitution([first-First, second-Second]),
              invariant(the_pair_satisfies_both_equations),
              validity(Validity) ]),
        Trace = [ read_both_relations(U1, U2),
                  scale_to_align_one_unknown(Determinant),
                  subtract_to_remove_the_aligned_unknown(U2),
                  solve_the_remaining_unknown(U1, XText),
                  substitute_back_for_the_other(U2, YText),
                  substitute_into_both_originals(First, Second),
                  report_one_pair(XText, YText) ]
    ;   proportional_rows(row(A1, B1, C1), row(A2, B2, C2))
    ->  every_pair_witnesses(row(A1, B1, C1), row(A2, B2, C2), Witnesses,
                             Validity),
        Outcome = action_outcome(
            elimination_with_substitution_back,
            [ classification(productive),
              cluster(g8_systems_of_linear_equations),
              automaton_state(q_accept_every_pair_on_the_line),
              vocabulary([system_of_equations, same_line, infinitely_many,
                          equivalent_equations]),
              input(system(U1, U2, row(A1, B1, C1), row(A2, B2, C2))),
              result(every_pair_on_the_line),
              expected(every_pair_on_the_line),
              witnesses(Witnesses),
              invariant(the_pair_satisfies_both_equations),
              validity(Validity) ]),
        Trace = [ read_both_relations(U1, U2),
                  find_the_same_line_twice(Witnesses) ]
    ;   no_pair_witness(row(A1, B1, C1), row(A2, B2, C2), Witness, Validity),
        Outcome = action_outcome(
            elimination_with_substitution_back,
            [ classification(productive),
              cluster(g8_systems_of_linear_equations),
              automaton_state(q_accept_no_pair),
              vocabulary([system_of_equations, parallel_lines, no_solution,
                          contradiction]),
              input(system(U1, U2, row(A1, B1, C1), row(A2, B2, C2))),
              result(no_pair),
              expected(no_pair),
              witnesses([Witness]),
              invariant(the_pair_satisfies_both_equations),
              validity(Validity) ]),
        Trace = [ read_both_relations(U1, U2),
                  find_no_pair_satisfies(Witness) ]
    ).

satisfies(row(A, B, C), X, Y, Verdict) :-
    Value is A * X + B * Y,
    ( Value =:= C -> Verdict = closes ; Verdict = fails ).

proportional_rows(row(A1, B1, C1), row(A2, B2, C2)) :-
    A1 * B2 =:= A2 * B1,
    A1 * C2 =:= A2 * C1,
    B1 * C2 =:= B2 * C1.

% Two distinct points on the shared line, each checked in both equations.
every_pair_witnesses(First, Second, [point(X1, Y1)-A1-B1,
                                     point(X2, Y2)-A2-B2], Validity) :-
    point_on_row(First, 0, X1, Y1),
    point_on_row(First, 1, X2, Y2),
    satisfies(First, X1, Y1, A1), satisfies(Second, X1, Y1, B1),
    satisfies(First, X2, Y2, A2), satisfies(Second, X2, Y2, B2),
    (   A1 == closes, B1 == closes, A2 == closes, B2 == closes,
        \+ ( X1 =:= X2, Y1 =:= Y2 )
    ->  Validity = correct
    ;   Validity = unvindicated
    ).

% One point on the first line, checked against the second, which must miss.
no_pair_witness(First, Second, point(X, Y)-OnFirst-OnSecond, Validity) :-
    point_on_row(First, 0, X, Y),
    satisfies(First, X, Y, OnFirst),
    satisfies(Second, X, Y, OnSecond),
    ( OnFirst == closes, OnSecond == fails -> Validity = correct
    ; Validity = unvindicated ).

point_on_row(row(A, B, C), Free, X, Y) :-
    (   B =\= 0
    ->  X = Free, Y is (C - A * Free) rdiv B
    ;   Y = Free, X is C rdiv A
    ).

% ==========================================================================
% 5. SELF-SUMMARY
% ==========================================================================

g8_linear_system_summary(
    summary{ module: g8_linear_system_solution,
             status: authored_pilot,
             generated: false,
             grade: 8,
             cluster: g8_systems_of_linear_equations,
             doings: [ elimination_with_substitution_back ],
             answers: [one_pair, no_pair, every_pair_on_the_line],
             verification: substitute_into_both_original_equations,
             arithmetic: exact_rational,
             deformation_partners: none_attested_at_this_locus,
             imported_by: none,
             extant_machines_left_untouched:
                 [ 'algebraic/balance_preserving_linear_solution',
                   'ratio/inscribe_proportional_equation' ] }).

% ==========================================================================
% 6. RECEIPTS
% ==========================================================================

g8_linear_system_receipt(
    'im_defrag_e8a54b1c40db860982e51a78_1', 'IM-G8-U4-L14',
    % y = 2x and x = -y + 6, written as 2x - y = 0 and x + y = 6.
    _{kind: "linear_system_two_unknowns", unknowns: ["x", "y"],
      equations: [_{a: 2, b: -1, c: 0}, _{a: 1, b: 1, c: 6}]},
    one_pair("x"-"2", "y"-"4")).
g8_linear_system_receipt(
    'im_defrag_19c16167c17f00c6c2ada63d_1', 'IM-G8-U4-L14',
    % x + y = 5 and x + y = 7.
    _{kind: "linear_system_two_unknowns", unknowns: ["x", "y"],
      equations: [_{a: 1, b: 1, c: 5}, _{a: 1, b: 1, c: 7}]},
    no_pair).
g8_linear_system_receipt(
    'im_defrag_6a6926ca8aa4bfd0f264a2d7_1', 'IM-G8-U4-L10',
    % $2 in quarters and dimes, 17 coins: 25q + 10d = 200 and q + d = 17.
    _{kind: "linear_system_two_unknowns", unknowns: ["quarters", "dimes"],
      equations: [_{a: 25, b: 10, c: 200}, _{a: 1, b: 1, c: 17}]},
    one_pair("quarters"-"2", "dimes"-"15")).
g8_linear_system_receipt(
    'im_defrag_92a4d29f9984ff15f3d8f461_1', 'IM-G8-U4-L10',
    % $3 in quarters and dimes, 12 coins: 25q + 10d = 300 and q + d = 12.
    _{kind: "linear_system_two_unknowns", unknowns: ["quarters", "dimes"],
      equations: [_{a: 25, b: 10, c: 300}, _{a: 1, b: 1, c: 12}]},
    one_pair("quarters"-"12", "dimes"-"0")).
g8_linear_system_receipt(
    'im_defrag_9b1b73ff0e1443234be73a0a_1', 'IM-G8-U4-L16',
    % Bracelets at $1 and shirts at $10: 100 items sold for $307.
    _{kind: "linear_system_two_unknowns", unknowns: ["bracelets", "shirts"],
      equations: [_{a: 1, b: 1, c: 100}, _{a: 1, b: 10, c: 307}]},
    one_pair("bracelets"-"77", "shirts"-"23")).
% The same row carries four problems; two of them are systems in its own
% numbers, so the row id appears twice.
g8_linear_system_receipt(
    'im_defrag_9b1b73ff0e1443234be73a0a_1', 'IM-G8-U4-L16',
    % Two friends 7 miles apart closing at 0.2 and 0.15 miles per minute:
    % d = 0.2t and 7 - d = 0.15t.
    _{kind: "linear_system_two_unknowns", unknowns: ["miles", "minutes"],
      equations: [_{a: 1, b: -0.2, c: 0}, _{a: 1, b: 0.15, c: 7}]},
    one_pair("miles"-"4", "minutes"-"20")).
g8_linear_system_receipt(
    'im_defrag_6ab51e24d203345b3fafb444_1', 'IM-G8-U4-L9',
    % $5 for the first hour plus $8 for each additional hour against
    % $15 plus $6: pay = 8h - 3 and pay = 6h + 9.
    _{kind: "linear_system_two_unknowns", unknowns: ["pay", "hours"],
      equations: [_{a: 1, b: -8, c: -3}, _{a: 1, b: -6, c: 9}]},
    one_pair("pay"-"45", "hours"-"6")).
g8_linear_system_receipt(
    'im_defrag_3c598775622b6607dfc85dd8_1', 'IM-G8-U3-L13',
    % Avocados at $1 and pineapples at $2: 6 avocados and 3 pineapples
    % against a $12 budget for the same 9 items.
    _{kind: "linear_system_two_unknowns",
      unknowns: ["avocados", "pineapples"],
      equations: [_{a: 1, b: 1, c: 9}, _{a: 1, b: 2, c: 12}]},
    one_pair("avocados"-"6", "pineapples"-"3")).

% Final round: the widened vision fold-in supplied IM-G8-U4-L13's three
% systems, which the markdown had left as "Here are three systems of
% equations" with no systems in it. Written in standard form.
g8_linear_system_receipt(
    'im_defrag_952726ea3b05d0711bb18186_1', 'IM-G8-U4-L13',
    _{kind: "linear_system_two_unknowns", unknowns: ["x", "y"],
      equations: [_{a: 3, b: -1, c: -5}, _{a: -2, b: -1, c: -20}]},
    one_pair("x"-"3", "y"-"14")).            % y = 3x + 5, y = -2x + 20
g8_linear_system_receipt(
    'im_defrag_952726ea3b05d0711bb18186_1', 'IM-G8-U4-L13',
    _{kind: "linear_system_two_unknowns", unknowns: ["x", "y"],
      equations: [_{a: 2, b: -1, c: 10}, _{a: 4, b: -1, c: 1}]},
    one_pair("x"-"-9/2", "y"-"-19")).        % y = 2x - 10, y = 4x - 1
g8_linear_system_receipt(
    'im_defrag_952726ea3b05d0711bb18186_1', 'IM-G8-U4-L13',
    _{kind: "linear_system_two_unknowns", unknowns: ["x", "y"],
      equations: [_{a: 0.5, b: -1, c: -12}, _{a: 2, b: -1, c: -27}]},
    one_pair("x"-"-10", "y"-"7")).           % y = 0.5x + 12, y = 2x + 27

% ==========================================================================
% 7. CHECK
% ==========================================================================

check_g8_linear_system_solution :-
    check_receipts,
    check_degenerate_branches,
    check_negative,
    format('g8_linear_system_solution: all checks ok~n').

check_receipts :-
    findall(Lesson-Row-Result,
            ( g8_linear_system_receipt(Row, Lesson, Json, Expected),
              g8_linear_system_from_json(Json, System),
              run_g8_linear_system(elimination_with_substitution_back,
                                   System, Outcome, _),
              outcome_property(Outcome, result(Result)),
              Result = Expected,
              outcome_property(Outcome, validity(correct))
            ), Rows),
    findall(R-L, g8_linear_system_receipt(R, L, _, _), All),
    length(All, Total), length(Rows, Passed),
    Total =:= Passed,
    format('  receipts: ~w/~w real grade 8 rows solved, each pair substituted into both equations~n',
           [Passed, Total]),
    forall(member(Lesson-Row-Result, Rows),
           format('    ~w  ~w  ~q~n', [Lesson, Row, Result])).

check_degenerate_branches :-
    % x + y = 5 against x + y = 7: parallel, with a witness that closes the
    % first equation and misses the second.
    g8_linear_system_from_json(
        _{kind: "linear_system_two_unknowns", unknowns: ["x", "y"],
          equations: [_{a: 1, b: 1, c: 5}, _{a: 1, b: 1, c: 7}]}, S1),
    run_g8_linear_system(elimination_with_substitution_back, S1, O1, _),
    outcome_property(O1, result(no_pair)),
    outcome_property(O1, witnesses([point(0, 5)-closes-fails])),
    % x + y = 5 against 2x + 2y = 10: the same line twice, with two distinct
    % points that both close in both equations.
    g8_linear_system_from_json(
        _{kind: "linear_system_two_unknowns", unknowns: ["x", "y"],
          equations: [_{a: 1, b: 1, c: 5}, _{a: 2, b: 2, c: 10}]}, S2),
    run_g8_linear_system(elimination_with_substitution_back, S2, O2, _),
    outcome_property(O2, result(every_pair_on_the_line)),
    outcome_property(O2, witnesses([point(0, 5)-closes-closes,
                                    point(1, 4)-closes-closes])),
    format('  degenerate branches: the parallel pair and the coincident pair each carry executed witnesses~n').

check_negative :-
    % An equation with no unknowns at all is outside the contract.
    \+ g8_linear_system_from_json(
           _{kind: "linear_system_two_unknowns", unknowns: ["x", "y"],
             equations: [_{a: 0, b: 0, c: 5}, _{a: 1, b: 1, c: 7}]}, _),
    % A repeated unknown name is refused rather than silently accepted.
    \+ g8_linear_system_from_json(
           _{kind: "linear_system_two_unknowns", unknowns: ["x", "x"],
             equations: [_{a: 1, b: 1, c: 5}, _{a: 1, b: 2, c: 7}]}, _),
    % A pair that closes one equation and misses the other is never reported
    % as the solution: the quarters-and-dimes pair (5, 12) satisfies the coin
    % count and misses the value.
    g8_linear_system_from_json(
        _{kind: "linear_system_two_unknowns",
          unknowns: ["quarters", "dimes"],
          equations: [_{a: 25, b: 10, c: 200}, _{a: 1, b: 1, c: 17}]}, S),
    run_g8_linear_system(elimination_with_substitution_back, S, O, _),
    outcome_property(O, pair(Q, D)),
    \+ ( Q =:= 5, D =:= 12 ),
    format('  negative tests: a degenerate equation and a repeated unknown refuse; a pair closing only one equation is never reported~n').

outcome_property(action_outcome(_, Props), Property) :-
    memberchk(Property, Props).
