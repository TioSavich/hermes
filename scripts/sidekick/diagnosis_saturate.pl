% Referent saturation for the mistake-location adjudication arm.
%
% The model compiles a word problem into facts; this file derives every value
% those facts determine and answers which student step asserts a number the
% problem does not license. The model represents and binds; nothing here asks
% it to judge.
%
% Facts arrive as one Program list, so items stay independent across a run:
%   quantity(Name, Value, Kind)        Value is a number or the atom unknown
%   conversion(FromKind, ToKind, Factor, Span)   shape shared with quantity_claim
%   relation(Name, Recipe, Span)       Recipe in {convert/2, scale/2, sum/1,
%                                                   difference/2, quotient/2}
%   asks(result, Name)
%   discrete_kinds(Kinds)              optional integrality guard
%
% Extracted from the design probe at
% .superpowers/sdd/design/probes/probe_ignatius.pl, whose scenarios this file
% still satisfies. The probe consults quantity_claim for a separate
% text-arithmetic channel; this file carries the referent channel alone.

:- use_module(library(lists)).

:- dynamic derived/3.

close_enough(A, B) :- abs(A - B) < 0.000001.

kind_of(Program, Name, Kind) :- member(quantity(Name, _, Kind), Program), !.

derived_value(N, V) :- derived(N, V, _).

seed(Program) :-
    retractall(derived(_, _, _)),
    forall(( member(quantity(N, V, _), Program), number(V) ),
           assertz(derived(N, V, given))).

saturate(Program) :-
    (   determinable(Program, N, V, How),
        \+ derived(N, _, _)
    ->  assertz(derived(N, V, How)),
        saturate(Program)
    ;   true
    ).

% ---- forward readings, also used to recompute for the contradiction check
determinable(Program, N, V, convert(Span)) :-
    member(relation(N, convert(Src, ToKind), Span), Program),
    derived(Src, SV, _),
    kind_of(Program, Src, FromKind),
    member(conversion(FromKind, ToKind, F, _), Program),
    V is SV * F.
determinable(Program, N, V, scale(Span)) :-
    member(relation(N, scale(SName, Src), Span), Program),
    derived(SName, S, _),
    derived(Src, SV, _),
    V is S * SV.
determinable(Program, N, V, sum(Span)) :-
    member(relation(N, sum(Parts), Span), Program),
    maplist(derived_value, Parts, Vs),
    sum_list(Vs, V).
determinable(Program, N, V, difference(Span)) :-
    member(relation(N, difference(Minuend, Subtrahend), Span), Program),
    derived(Minuend, MinuendValue, _),
    derived(Subtrahend, SubtrahendValue, _),
    V is MinuendValue - SubtrahendValue.
determinable(Program, N, V, quotient(Span)) :-
    member(relation(N, quotient(Dividend, Divisor), Span), Program),
    derived(Dividend, DividendValue, _),
    derived(Divisor, DivisorValue, _),
    DivisorValue =\= 0,
    V is DividendValue / DivisorValue.

% ---- inverse readings: solve the one unknown a relation leaves
determinable(Program, Src, V, invert_convert(Span)) :-
    member(relation(N, convert(Src, ToKind), Span), Program),
    \+ derived(Src, _, _),
    derived(N, NV, _),
    kind_of(Program, Src, FromKind),
    member(conversion(FromKind, ToKind, F, _), Program),
    F =\= 0,
    V is NV / F.
determinable(Program, Src, V, invert_scale(Span)) :-
    member(relation(N, scale(SName, Src), Span), Program),
    \+ derived(Src, _, _),
    derived(N, NV, _),
    derived(SName, S, _),
    S =\= 0,
    V is NV / S.
determinable(Program, Part, V, invert_sum(Span)) :-
    member(relation(N, sum(Parts), Span), Program),
    derived(N, NV, _),
    select(Part, Parts, Others),
    \+ derived(Part, _, _),
    maplist(derived_value, Others, Vs),
    sum_list(Vs, S),
    V is NV - S.
determinable(Program, Minuend, V, invert_difference_minuend(Span)) :-
    member(relation(N, difference(Minuend, Subtrahend), Span), Program),
    \+ derived(Minuend, _, _),
    derived(N, DifferenceValue, _),
    derived(Subtrahend, SubtrahendValue, _),
    V is DifferenceValue + SubtrahendValue.
determinable(Program, Subtrahend, V, invert_difference_subtrahend(Span)) :-
    member(relation(N, difference(Minuend, Subtrahend), Span), Program),
    \+ derived(Subtrahend, _, _),
    derived(N, DifferenceValue, _),
    derived(Minuend, MinuendValue, _),
    V is MinuendValue - DifferenceValue.
determinable(Program, Dividend, V, invert_quotient_dividend(Span)) :-
    member(relation(N, quotient(Dividend, Divisor), Span), Program),
    \+ derived(Dividend, _, _),
    derived(N, QuotientValue, _),
    derived(Divisor, DivisorValue, _),
    V is QuotientValue * DivisorValue.
determinable(Program, Divisor, V, invert_quotient_divisor(Span)) :-
    member(relation(N, quotient(Dividend, Divisor), Span), Program),
    \+ derived(Divisor, _, _),
    derived(N, QuotientValue, _),
    QuotientValue =\= 0,
    derived(Dividend, DividendValue, _),
    V is DividendValue / QuotientValue.

contradicted(Program, N, V1, V2) :-
    derived(N, V1, _),
    determinable(Program, N, V2, _),
    \+ close_enough(V1, V2).

count_violation(Program, N, V) :-
    member(discrete_kinds(Ds), Program),
    derived(N, V, _),
    kind_of(Program, N, K),
    memberchk(K, Ds),
    RV is round(V),
    \+ close_enough(V, RV).

% ---- the walk over the student's bindings: b(Step, Referent, Value)
first_mismatch(Bindings, Step, K, A, D) :-
    member(b(Step, K, A), Bindings),
    K \== unresolved,
    derived(K, D, _),
    \+ close_enough(A, D),
    !.

final_binding(Program, Bindings, Step, V) :-
    member(asks(result, Asked), Program),
    member(b(Step, Asked, V), Bindings),
    \+ ( member(b(Later, Asked, _), Bindings), Later > Step ),
    !.

% ---- the adjudication order fixed by section 3 of the design.
% Answers answer(Step, Reason). Step 0 is an abstention, and every abstention
% carries the reason it abstained.
adjudicate(Program, Bindings, Answer, Reason) :-
    (   Program == []
    ->  Answer = 0, Reason = compile_malformed
    ;   contradicted(Program, N, _, _)
    ->  Answer = 0, Reason = compile_contradictory(N)
    ;   count_violation(Program, N, V)
    ->  Answer = 0, Reason = integrality_violation(N, V)
    ;   first_mismatch(Bindings, Step, K, A, D)
    ->  Answer = Step, Reason = mismatch(K, asserted(A), derived(D))
    ;   final_binding(Program, Bindings, _, FV),
        member(asks(result, Asked), Program),
        derived(Asked, DV, _)
    ->  (   close_enough(FV, DV)
        ->  Answer = 0, Reason = agree_with_derived
        ;   Answer = 0, Reason = disagree_unlocalized
        )
    ;   Answer = 0, Reason = underdetermined
    ).

% Entry point used by the runner: facts asserted as p/1, bindings as q/1.
:- dynamic p/1.
:- dynamic q/1.

run :-
    findall(F, p(F), Program),
    findall(B, q(B), Bindings),
    seed(Program),
    saturate(Program),
    adjudicate(Program, Bindings, Answer, Reason),
    format("ANSWER ~w~n", [Answer]),
    format("REASON ~w~n", [Reason]),
    forall(derived(N, V, _), format("DERIVED ~w=~w~n", [N, V])).
