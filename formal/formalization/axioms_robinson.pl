% ===================================================================
% Robinson Arithmetic (Q) Axioms and Arithmetic Grounding
% ===================================================================
%
% These axioms establish the connection between the Hermeneutic
% Calculator's grounded arithmetic and Robinson's axiom system Q.
% The claim is not that this system proves incompleteness — it is
% that children's arithmetic strategies, taken seriously, generate
% machinery rich enough to raise the question.
%
% is_recollection/2 is the ontological core: a number exists only
% if there is a constructive history (an anaphoric recollection)
% demonstrating how it was built from counting. "Numerals are
% pronouns" — they refer back to the act of counting that
% produced them.
%
% Interpretive correspondence: this material participates in what
% might be read as a Scene One horizon (objective, monological,
% verifiable by any subject). Robinson's axioms are the kind of
% claim that admits of multiple access — anyone can check Q1-Q7.
% ===================================================================

% --- Ontological Core: is_recollection/2 ---

robinson_pack_enabled :-
    axiom_pack_enabled(robinson).

history_for_nonnegative_integer(0, [axiom(zero)]).
history_for_nonnegative_integer(N, [succ(Prev)|PrevHistory]) :-
    integer(N),
    N > 0,
    Prev is N - 1,
    history_for_nonnegative_integer(Prev, PrevHistory).

% Base case: 0 is axiomatically a number.
is_recollection(0, [axiom(zero)]) :-
    robinson_pack_enabled.

% Support for explicit recollection structures from grounded_arithmetic
is_recollection(recollection(History), [explicit_recollection(History)]) :-
    robinson_pack_enabled,
    is_list(History),
    maplist(=(tally), History).

% Recursive case for positive integers
is_recollection(N, History) :-
    robinson_pack_enabled,
    integer(N),
    N > 0,
    history_for_nonnegative_integer(N, History).

% Case for negative integers
is_recollection(N, [integer_extension(negative, Abs)|AbsHistory]) :-
    robinson_pack_enabled,
    integer(N),
    N < 0,
    Abs is abs(N),
    history_for_nonnegative_integer(Abs, AbsHistory).

% Case for rational numbers
is_recollection(N rdiv D, [history(rational, from(N, D))]) :-
    robinson_pack_enabled,
    integer(D), D > 0,
    integer(N),
    is_recollection(D, _),
    is_recollection(N, _).

% --- Rational Arithmetic Helpers ---
gcd(A, 0, A) :- A \= 0, !.
gcd(A, B, G) :- B \= 0, R is A mod B, gcd(B, R, G).

normalize(N, N) :- integer(N), !.
normalize(N rdiv D, R) :-
    (D =:= 1 -> R = N ;
        G is abs(gcd(N, D)),
        SN is N // G,
        SD is D // G,
        (SD =:= 1 -> R = SN ; R = SN rdiv SD)
    ), !.

perform_arith(+, A, B, C) :- C is A + B.
perform_arith(-, A, B, C) :- C is A - B.
perform_arith(*, A, B, C) :- C is A * B.

rational_parts(N, N, 1) :-
    integer(N),
    !.
rational_parts(N rdiv D, N, D).

rational_arith(*, N1, D1, N2, D2, N_res rdiv D_res) :-
    N_res is N1 * N2,
    D_res is D1 * D2.
rational_arith(Op, N1, D1, N2, D2, N_res rdiv D_res) :-
    memberchk(Op, [+, -]),
    D_res is D1 * D2,
    N1_scaled is N1 * D2,
    N2_scaled is N2 * D1,
    perform_arith(Op, N1_scaled, N2_scaled, N_res).

arith_op(A, B, Op, C) :-
    memberchk(Op, [+, -, *]),
    normalize(A, NA), normalize(B, NB),
    (integer(NA), integer(NB) ->
        perform_arith(Op, NA, NB, C_raw)
    ;
        rational_parts(NA, N1, D1),
        rational_parts(NB, N2, D2),
        rational_arith(Op, N1, D1, N2, D2, C_raw)
    ),
    normalize(C_raw, C).

% --- Robinson Witnesses ---

recollection_history(N, History) :-
    once(is_recollection(N, History)).

successor_step(X, SX, successor(X, SX)) :-
    integer(X),
    arith_op(X, 1, +, SX).

arithmetic_witness(plus(A, B, C),
                   _{kind: arithmetic_computation,
                     operation: plus,
                     left: A,
                     right: B,
                     value: C,
                     left_history: AHistory,
                     right_history: BHistory,
                     computation: add(A, B, C)}) :-
    recollection_history(A, AHistory),
    recollection_history(B, BHistory),
    arith_op(A, B, +, C),
    recollection_history(C, _).
arithmetic_witness(minus(A, B, C),
                   _{kind: arithmetic_computation,
                     operation: minus,
                     left: A,
                     right: B,
                     value: C,
                     left_history: AHistory,
                     right_history: BHistory,
                     computation: subtract(A, B, C)}) :-
    recollection_history(A, AHistory),
    recollection_history(B, BHistory),
    arith_op(A, B, -, C),
    recollection_history(C, _).
arithmetic_witness(mult(A, B, C),
                   _{kind: arithmetic_computation,
                     operation: mult,
                     left: A,
                     right: B,
                     value: C,
                     left_history: AHistory,
                     right_history: BHistory,
                     computation: multiply(A, B, C)}) :-
    recollection_history(A, AHistory),
    recollection_history(B, BHistory),
    arith_op(A, B, *, C),
    recollection_history(C, _).

robinson_axiom_witness(q1_successor_not_zero,
                       o(eq(succ(X), 0)),
                       _{kind: robinson_axiom,
                         axiom: q1_successor_not_zero,
                         forbidden: o(eq(succ(X), 0)),
                         reason: zero_is_not_a_successor,
                         x: X,
                         x_history: XHistory}) :-
    robinson_pack_enabled,
    integer(X),
    X >= 0,
    recollection_history(X, XHistory).
robinson_axiom_witness(q2_successor_injective,
                       [o(eq(succ(X), succ(Y)))] => [o(eq(X, Y))],
                       _{kind: robinson_axiom,
                         axiom: q2_successor_injective,
                         assumption: o(eq(succ(X), succ(Y))),
                         conclusion: o(eq(X, Y)),
                         x: X,
                         y: Y,
                         x_history: XHistory,
                         y_history: YHistory,
                         proof: successor_equality_cancels_to_predecessor_equality}) :-
    robinson_pack_enabled,
    recollection_history(X, XHistory),
    recollection_history(Y, YHistory).
robinson_axiom_witness(q3_zero_or_successor,
                       o(eq(0, 0)),
                       _{kind: robinson_axiom,
                         axiom: q3_zero_or_successor,
                         case: zero,
                         conclusion: o(eq(0, 0)),
                         x_history: XHistory}) :-
    robinson_pack_enabled,
    recollection_history(0, XHistory).
robinson_axiom_witness(q3_zero_or_successor,
                       o(eq(X, succ(Y))),
                       _{kind: robinson_axiom,
                         axiom: q3_zero_or_successor,
                         case: successor,
                         conclusion: o(eq(X, succ(Y))),
                         x: X,
                         predecessor: Y,
                         x_history: XHistory,
                         predecessor_history: YHistory,
                         step: Step}) :-
    robinson_pack_enabled,
    integer(X),
    X > 0,
    Y is X - 1,
    recollection_history(X, XHistory),
    recollection_history(Y, YHistory),
    successor_step(Y, X, Step).
robinson_axiom_witness(q4_add_zero,
                       o(eq(plus(X, 0), X)),
                       _{kind: robinson_axiom,
                         axiom: q4_add_zero,
                         conclusion: o(eq(plus(X, 0), X)),
                         x: X,
                         x_history: XHistory,
                         computation: add(X, 0, X)}) :-
    robinson_pack_enabled,
    recollection_history(X, XHistory),
    arith_op(X, 0, +, X).
robinson_axiom_witness(q5_add_successor,
                       o(eq(plus(X, succ(Y)), succ(plus(X, Y)))),
                       _{kind: robinson_axiom,
                         axiom: q5_add_successor,
                         conclusion: o(eq(plus(X, succ(Y)), succ(plus(X, Y)))),
                         x: X,
                         y: Y,
                         left_value: LeftValue,
                         right_value: RightValue,
                         steps: [sum(X, Y, Sum), successor(Y, SY),
                                 add_successor(X, SY, LeftValue),
                                 successor(Sum, RightValue)],
                         x_history: XHistory,
                         y_history: YHistory}) :-
    robinson_pack_enabled,
    recollection_history(X, XHistory),
    recollection_history(Y, YHistory),
    integer(X),
    integer(Y),
    arith_op(X, Y, +, Sum),
    successor_step(Y, SY, _),
    arith_op(X, SY, +, LeftValue),
    successor_step(Sum, RightValue, _),
    LeftValue =:= RightValue.
robinson_axiom_witness(q6_mult_zero,
                       o(eq(mult(X, 0), 0)),
                       _{kind: robinson_axiom,
                         axiom: q6_mult_zero,
                         conclusion: o(eq(mult(X, 0), 0)),
                         x: X,
                         x_history: XHistory,
                         computation: multiply(X, 0, 0)}) :-
    robinson_pack_enabled,
    recollection_history(X, XHistory),
    arith_op(X, 0, *, 0).
robinson_axiom_witness(q7_mult_successor,
                       o(eq(mult(X, succ(Y)), plus(mult(X, Y), X))),
                       _{kind: robinson_axiom,
                         axiom: q7_mult_successor,
                         conclusion: o(eq(mult(X, succ(Y)), plus(mult(X, Y), X))),
                         x: X,
                         y: Y,
                         left_value: LeftValue,
                         right_value: RightValue,
                         steps: [product(X, Y, Product), successor(Y, SY),
                                 multiply_successor(X, SY, LeftValue),
                                 add_product_and_x(Product, X, RightValue)],
                         x_history: XHistory,
                         y_history: YHistory}) :-
    robinson_pack_enabled,
    recollection_history(X, XHistory),
    recollection_history(Y, YHistory),
    integer(X),
    integer(Y),
    arith_op(X, Y, *, Product),
    successor_step(Y, SY, _),
    arith_op(X, SY, *, LeftValue),
    arith_op(Product, X, +, RightValue),
    LeftValue =:= RightValue.

robinson_incoherence_witness([o(eq(succ(X), 0))], Witness) :-
    robinson_axiom_witness(q1_successor_not_zero, o(eq(succ(X), 0)), Witness).
robinson_incoherence_witness(Context,
                             _{kind: domain_blocked_subtraction,
                               source: robinson_arithmetic,
                               domain: n,
                               context: Context,
                               blocked: n(minus(A, B, _)),
                               left_value: NA,
                               right_value: NB,
                               reason: natural_numbers_do_not_contain_negative_differences}) :-
    robinson_pack_enabled,
    member(n(minus(A, B, _)), Context),
    current_domain(n),
    recollection_history(A, _),
    recollection_history(B, _),
    normalize(A, NA),
    normalize(B, NB),
    NA < NB.

axiom_incoherence_witness(Context, Witness) :-
    robinson_incoherence_witness(Context, Witness).

% --- Arithmetic Grounding Rules ---

proves_impl(_ => [o(eq(A,B))], _) :-
    robinson_pack_enabled,
    once(is_recollection(A, _)), once(is_recollection(B, _)),
    normalize(A, NA), normalize(B, NB),
    NA == NB.

proves_impl(_ => [o(plus(A,B,C))], _) :-
    robinson_pack_enabled,
    arithmetic_witness(plus(A, B, C), _).

proves_impl(_ => [o(minus(A,B,C))], _) :-
    robinson_pack_enabled,
    current_domain(D), once(is_recollection(A, _)), once(is_recollection(B, _)),
    arith_op(A, B, -, C),
    normalize(C, NC),
    ((D=n, NC >= 0) ; member(D, [z, q])),
    once(is_recollection(C, _)).

proves_impl([n(plus(A,B,C))] => [n(plus(B,A,C))], _) :-
    robinson_pack_enabled.

proves_impl(_ => [o(mult(A,B,C))], _) :-
    robinson_pack_enabled,
    arithmetic_witness(mult(A, B, C), _).

proves_impl([n(mult(A,B,C))] => [n(mult(B,A,C))], _) :-
    robinson_pack_enabled.

% Successor grounding
proves_impl(_ => [o(eq(succ(X), SX))], _) :-
    robinson_pack_enabled,
    once(is_recollection(X, _)), integer(X),
    SX is X + 1,
    once(is_recollection(SX, _)).

% --- Robinson Axioms Q1-Q7 ---

% Q1: S(x) != 0
is_incoherent([o(eq(succ(X), 0))]) :-
    robinson_incoherence_witness([o(eq(succ(X), 0))], _).

% Q2: S(x) = S(y) -> x = y (injective)
proves_impl([o(eq(succ(X), succ(Y)))] => [o(eq(X, Y))], _) :-
    robinson_axiom_witness(
        q2_successor_injective,
        [o(eq(succ(X), succ(Y)))] => [o(eq(X, Y))],
        _
    ).

% Q3: x = 0 v exists y (x = S(y))
proves_impl(_ => [o(eq(X, 0))], _) :-
    robinson_axiom_witness(q3_zero_or_successor, o(eq(X, 0)), _).
proves_impl(_ => [o(eq(X, succ(Y)))], _) :-
    robinson_axiom_witness(q3_zero_or_successor, o(eq(X, succ(Y))), _).

% Q4: x + 0 = x
proves_impl(_ => [o(eq(plus(X, 0), X))], _) :-
    robinson_axiom_witness(q4_add_zero, o(eq(plus(X, 0), X)), _).

% Q5: x + S(y) = S(x + y)
proves_impl(_ => [o(eq(plus(X, succ(Y)), succ(plus(X, Y))))], _) :-
    robinson_axiom_witness(
        q5_add_successor,
        o(eq(plus(X, succ(Y)), succ(plus(X, Y)))),
        _
    ).

% Q6: x * 0 = 0
proves_impl(_ => [o(eq(mult(X, 0), 0))], _) :-
    robinson_axiom_witness(q6_mult_zero, o(eq(mult(X, 0), 0)), _).

% Q7: x * S(y) = (x * y) + x
proves_impl(_ => [o(eq(mult(X, succ(Y)), plus(mult(X, Y), X)))], _) :-
    robinson_axiom_witness(
        q7_mult_successor,
        o(eq(mult(X, succ(Y)), plus(mult(X, Y), X))),
        _
    ).

% --- Arithmetic Incoherence ---
is_incoherent(X) :-
    robinson_incoherence_witness(X, _),
    !.
