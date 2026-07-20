% formal/tools/carving/synthesizer.pl
%
% The carving synthesizer.
%
% Start with a fact list (bounded by operation and max input). For each
% fact, search for a primitive-action derivation. When found, replace the
% bare fact with one or more clauses whose head IS the fact and whose body
% IS the proof. Multiple proofs per fact = the strategy taxonomy for that
% fact. Facts that resist carving are the structural residue.
%
% Brandomian read: the head is a commitment, the body is the entitlement.
% Carving is the move from implicit-being (bare assertion) to
% explicit-knowing (inferentially articulated assertion).
%
% Base-parametric throughout. Tested at base 10 and base 5.

:- module(carving_synthesizer, [
    init/3,
    carve_round/2,
    carve_to_fixpoint/2,
    residue/1,
    proofs_of/2,
    all_carved/1,
    find_proofs/3,
    known_fact/4,
    bare/1,
    carved/2,
    fact_components/5,
    is_correct/4
]).

:- use_module(library(lists)).
:- use_module(library(aggregate)).
:- use_module(library(pairs)).

:- dynamic(bare/1).
:- dynamic(carved/2).
:- dynamic(known_fact/4).

:- multifile(prove/3).
:- discontiguous(prove/3).

% Utility (defined early to satisfy export ordering).
fact_components(fact(Op, X, Y, Z), Op, X, Y, Z).

% ----- Initialization -----

% init(+Op, +MaxN, +FactMode)
%   FactMode = correct | mixed
%   correct: only bare facts where Z is the true result of Op(X,Y)
%   mixed:   correct facts PLUS plausibly-wrong facts (for rationalization)
init(Op, MaxN, FactMode) :-
    retractall(bare(_)),
    retractall(carved(_, _)),
    retractall(known_fact(_, _, _, _)),
    generate_facts(Op, MaxN, FactMode).

generate_facts(add, MaxN, correct) :-
    forall(
        ( between(0, MaxN, X),
          between(0, MaxN, Y),
          Z is X + Y,
          Z =< 200 ),
        assertz(bare(fact(add, X, Y, Z)))
    ).
generate_facts(add, MaxN, mixed) :-
    generate_facts(add, MaxN, correct),
    forall(
        ( between(0, MaxN, X),
          between(0, MaxN, Y),
          plausible_wrong_answer(add, X, Y, Z),
          Z >= 0, Z =< 200,
          \+ bare(fact(add, X, Y, Z)) ),
        assertz(bare(fact(add, X, Y, Z)))
    ).

% Subtraction over naturals: 0 =< Y =< X =< MaxN, Z = X - Y.
generate_facts(sub, MaxN, correct) :-
    forall(
        ( between(0, MaxN, X),
          between(0, X, Y),
          Z is X - Y ),
        assertz(bare(fact(sub, X, Y, Z)))
    ).
generate_facts(sub, MaxN, mixed) :-
    generate_facts(sub, MaxN, correct),
    forall(
        ( between(0, MaxN, X),
          between(0, X, Y),
          plausible_wrong_answer(sub, X, Y, Z),
          Z >= 0, Z =< MaxN,
          \+ bare(fact(sub, X, Y, Z)) ),
        assertz(bare(fact(sub, X, Y, Z)))
    ).

% Multiplication: factors in 0..MaxN, product capped (Z =< 200 by default
% but we cap at MaxN*MaxN to stay inside the small-number space).
generate_facts(mult, MaxN, correct) :-
    Cap is MaxN * MaxN,
    forall(
        ( between(0, MaxN, X),
          between(0, MaxN, Y),
          Z is X * Y,
          Z =< Cap ),
        assertz(bare(fact(mult, X, Y, Z)))
    ).
generate_facts(mult, MaxN, mixed) :-
    generate_facts(mult, MaxN, correct),
    Cap is MaxN * MaxN,
    forall(
        ( between(0, MaxN, X),
          between(0, MaxN, Y),
          plausible_wrong_answer(mult, X, Y, Z),
          Z >= 0, Z =< Cap,
          \+ bare(fact(mult, X, Y, Z)) ),
        assertz(bare(fact(mult, X, Y, Z)))
    ).

% Exact division: T in 0..MaxN, S in 1..MaxN, T mod S =:= 0, Q = T/S.
generate_facts(div, MaxN, correct) :-
    forall(
        ( between(0, MaxN, T),
          between(1, MaxN, S),
          0 =:= T mod S,
          Q is T // S ),
        assertz(bare(fact(div, T, S, Q)))
    ).
generate_facts(div, MaxN, mixed) :-
    generate_facts(div, MaxN, correct),
    forall(
        ( between(0, MaxN, T),
          between(1, MaxN, S),
          plausible_wrong_answer(div, T, S, Q),
          Q >= 0, Q =< MaxN,
          \+ bare(fact(div, T, S, Q)) ),
        assertz(bare(fact(div, T, S, Q)))
    ).

% Fraction construction: numerators 1..NMax, denominators 1..DMax.
% MaxN parameter is the maximum denominator. For mode=correct the
% numerator envelope is 1..2 with N =< D (the project's "1/1..1/10
% plus 2/2..2/10" envelope). For mode=improper we extend up to
% N =< 2*D so we get 3/2, 5/3, 5/4, 7/4, 7/5, ... (the three-level
% unit-coordination envelope per Hackenberg/Steffe). For mode=mixed
% the rationalizations attach to the same heads.
generate_facts(frac, MaxN, correct) :-
    DMax = MaxN,
    NMax = 2,
    forall(
        ( between(1, NMax, N),
          between(N, DMax, D) ),
        assertz(bare(fact(frac, N, D, fraction(N, D))))
    ).
generate_facts(frac, MaxN, improper) :-
    DMax = MaxN,
    forall(
        ( between(2, DMax, D),
          NMax is 2 * D,
          between(1, NMax, N) ),
        assertz(bare(fact(frac, N, D, fraction(N, D))))
    ).
generate_facts(frac, MaxN, mixed) :-
    generate_facts(frac, MaxN, correct),
    true.
generate_facts(frac, MaxN, mixed_improper) :-
    generate_facts(frac, MaxN, improper),
    true.

% Fraction-of-fraction (e.g. 1/2 of 1/3). Fact shape carries the two
% operand fractions in slots X and Y and the product in Z.
% X = fraction(A, B), Y = fraction(C, D), Z = fraction(A*C, B*D).
% Denominators in 2..MaxN; numerators in 1..MaxN (we DO allow N > D
% in either operand so the area-model has to handle improper
% sub-products too).
generate_facts(frac_of, MaxN, correct) :-
    forall(
        ( between(2, MaxN, B),
          between(2, MaxN, D),
          between(1, B, A),         % proper or unit numerators for op1
          between(1, D, C) ),       % proper or unit numerators for op2
        ( P is A * C, Q is B * D,
          assertz(bare(fact(frac_of, fraction(A, B), fraction(C, D),
                            fraction(P, Q)))) )
    ).
generate_facts(frac_of, MaxN, mixed) :-
    generate_facts(frac_of, MaxN, correct),
    true.

% plausible_wrong_answer/4: enumerate the wrong answers that correspond
% to known misconception patterns. Used for FactMode=mixed.
plausible_wrong_answer(add, X, Y, Z) :-
    Z is X + Y - 1.        % off-by-one count-on
plausible_wrong_answer(add, X, Y, Z) :-
    X >= 10, Y >= 10,      % missed-carry pattern (base 10 specific here;
    OnesX is X mod 10,     % the rationalization rule itself is base-parametric)
    OnesY is Y mod 10,
    OnesX + OnesY >= 10,
    FlawedOnes is (OnesX + OnesY) mod 10,
    FlawedTens is (X div 10) + (Y div 10),
    Z is FlawedTens * 10 + FlawedOnes.
plausible_wrong_answer(add, X, Y, Z) :-
    X >= 1, Y >= 1,        % digit concatenation
    number_codes(Y, CY),
    length(CY, NumDigitsY),
    Mult is 10 ^ NumDigitsY,
    Z is X * Mult + Y,
    Z =< 200.
plausible_wrong_answer(add, X, Y, Z) :-
    L is max(X, Y),        % round-without-adjust (substitute, forget to correct)
    M is min(X, Y),
    M >= 1,
    K is (10 - (L mod 10)) mod 10,
    K > 0, K =< 5,
    NextBase is L + K,
    Z is NextBase + M,
    Z =\= X + Y,
    Z =< 200.

% ----- Subtraction misconceptions -----
% Pattern: minuend-subtrahend column reversal — for each column, subtract
% the smaller digit from the larger, regardless of which is minuend/subtrahend.
plausible_wrong_answer(sub, X, Y, Z) :-
    X >= 10, Y >= 1,
    OnesX is X mod 10, TensX is X div 10,
    OnesY is Y mod 10, TensY is Y div 10,
    OnesY > OnesX,                       % the "wrong-way-borrow" trigger
    FlawedOnes is OnesY - OnesX,
    TensY =< TensX,
    FlawedTens is TensX - TensY,
    Z is FlawedTens * 10 + FlawedOnes,
    Z >= 0, Z \== X - Y.
% Off-by-one count-back: Z = X - Y + 1 (counted Y-1 successors instead of Y).
plausible_wrong_answer(sub, X, Y, Z) :-
    Y >= 1,
    Z is X - Y + 1,
    Z >= 0, Z =< X.
% Forgotten-to-borrow on the ones column (clamp ones at zero, keep tens).
plausible_wrong_answer(sub, X, Y, Z) :-
    X >= 10, Y >= 1,
    OnesX is X mod 10, TensX is X div 10,
    OnesY is Y mod 10, TensY is Y div 10,
    OnesY > OnesX,
    TensY =< TensX,
    FlawedOnes = 0,
    FlawedTens is TensX - TensY,
    Z is FlawedTens * 10 + FlawedOnes,
    Z >= 0, Z \== X - Y.

% ----- Multiplication misconceptions -----
% Additive-for-multiplicative: kid treats * as +.
plausible_wrong_answer(mult, X, Y, Z) :-
    X >= 1, Y >= 1,
    Z is X + Y,
    Z \== X * Y, Z >= 0.
% Times-zero-is-the-number polysemy: kid treats 0 as identity.
plausible_wrong_answer(mult, X, 0, X) :- X >= 1.
plausible_wrong_answer(mult, 0, Y, Y) :- Y >= 1.
% Multiply digits separately (base 10 only) — multiply ones digits and
% tens digits independently, recombine.
plausible_wrong_answer(mult, X, Y, Z) :-
    X >= 10, Y >= 10,
    OnesX is X mod 10, TensX is X div 10,
    OnesY is Y mod 10, TensY is Y div 10,
    FlawedOnes is (OnesX * OnesY) mod 10,
    FlawedTens is TensX * TensY,
    Z is FlawedTens * 10 + FlawedOnes,
    Z \== X * Y, Z >= 0.

% ----- Division misconceptions -----
% Divide-larger-by-smaller-always: kid interprets T/S as max/min.
plausible_wrong_answer(div, T, S, Q) :-
    S >= 1,
    Hi is max(T, S),
    Lo is min(T, S),
    Lo >= 1,
    0 =:= Hi mod Lo,
    Q is Hi // Lo,
    Q \== T // S,
    Q >= 0.
% Subtract-instead-of-divide: kid replaces / with -.
plausible_wrong_answer(div, T, S, Q) :-
    S >= 1, T >= S,
    Q is T - S,
    Q \== T // S, Q >= 0.

% ----- Carving rounds -----

% carve_round(+Config, -NewlyCarved)
% One pass over all bare facts. For each, try to find proofs. If proofs
% exist, retract the bare fact and assert each proof as a clause.
carve_round(Config, NewlyCarved) :-
    findall(
        Fact-Proofs,
        ( bare(Fact),
          find_proofs(Fact, Config, Proofs),
          Proofs \= [] ),
        Pairs
    ),
    install_proofs(Pairs),
    pairs_keys(Pairs, NewlyCarved).

install_proofs([]).
install_proofs([Fact-Proofs | T]) :-
    retractall(bare(Fact)),
    fact_components(Fact, Op, X, Y, Z),
    % Memoize ONLY correct facts; wrong facts don't enter the recollection store.
    ( is_correct(Op, X, Y, Z)
    -> ( known_fact(Op, X, Y, Z) -> true ; assertz(known_fact(Op, X, Y, Z)) )
    ;  true ),
    forall(member(P, Proofs), assertz(carved(Fact, P))),
    install_proofs(T).

% is_correct/4 — whether Op(X, Y) = Z is the true result (used both for
% memoization gating and for CSV correctness labelling). For frac, Z is
% the symbolic fraction(N, D) term and the bare-fact generator already
% guarantees correctness of the construction relation.
is_correct(add,  X, Y, Z) :- Z =:= X + Y.
is_correct(sub,  X, Y, Z) :- Y =< X, Z =:= X - Y.
is_correct(mult, X, Y, Z) :- Z =:= X * Y.
is_correct(div,  T, S, Q) :- S >= 1, 0 =:= T mod S, Q =:= T // S.
is_correct(frac, N, D, fraction(N, D)) :- N >= 0, D >= 1.
is_correct(frac_of, fraction(A, B), fraction(C, D), fraction(P, Q)) :-
    B >= 1, D >= 1, P =:= A * C, Q =:= B * D.

% find_proofs(+Fact, +Config, -UniqueProofs)
find_proofs(Fact, Config, Proofs) :-
    findall(P, prove(Fact, Config, P), Raw),
    list_to_set(Raw, Proofs).

% ----- Fixpoint loop -----

carve_to_fixpoint(Config, Stats) :-
    carve_to_fixpoint_(Config, 0, 0, Stats).

carve_to_fixpoint_(Config, N, TotalCarved, Stats) :-
    MaxR = Config.max_rounds,
    ( N >= MaxR
    -> finalize_stats(N, TotalCarved, Stats)
    ;  carve_round(Config, Newly),
       length(Newly, K),
       format('  round ~w: carved ~w facts~n', [N, K]),
       ( K =:= 0
       -> finalize_stats(N, TotalCarved, Stats)
       ;  N1 is N + 1,
          TC1 is TotalCarved + K,
          carve_to_fixpoint_(Config, N1, TC1, Stats) )
    ).

finalize_stats(N, TotalCarved, Stats) :-
    aggregate_all(count, bare(_), ResidueCount),
    aggregate_all(count, carved(_, _), ClauseCount),
    Stats = stats{
        rounds: N,
        total_carved: TotalCarved,
        residue_count: ResidueCount,
        clause_count: ClauseCount
    }.

% ----- Inspection -----

residue(R) :- findall(F, bare(F), R).

proofs_of(Fact, Proofs) :-
    findall(P, carved(Fact, P), Proofs).

all_carved(All) :-
    findall(F-P, carved(F, P), All).
