:- module(elaboration_detector, [
    compute_elaborations/2
]).

:- use_module(library(lists)).

%!  compute_elaborations(+StrategyPatterns:list, -Elaborations:list) is det.
%
%   StrategyPatterns is a list of Name-Patterns key-value pairs (Patterns is
%   a sorted set of pat_* atoms). Elaborations is a list of
%   elaboration(Base, Elab, Shared, Type, ConfidenceMax, ConfidenceJaccard, DirectionAsymmetry)
%   terms. Pairs with empty intersection are omitted.
%
%   Scoring:
%     ConfidenceMax      = |Shared| / max(|A|, |B|)     (matches Python's formula)
%     ConfidenceJaccard  = |Shared| / |A ∪ B|
%     DirectionAsymmetry = ||B\A| - |A\B||
%
%   Direction:
%     If |A \ B| > |B \ A|: A has more unique patterns, so B is the base and A elaborates B.
%     If |B \ A| > |A \ B|: B elaborates A.
%     If equal:             type = peer.
compute_elaborations(StrategyPatterns, Elaborations) :-
    findall(E,
            ( select(NameA-PatsA, StrategyPatterns, Rest),
              member(NameB-PatsB, Rest),
              NameA @< NameB,
              pair_relation(NameA, PatsA, NameB, PatsB, E)
            ),
            Elaborations).

pair_relation(NameA, PatsA, NameB, PatsB, Elab) :-
    ord_intersection(PatsA, PatsB, Shared),
    Shared \= [],
    ord_subtract(PatsA, PatsB, OnlyA),
    ord_subtract(PatsB, PatsA, OnlyB),
    ord_union(PatsA, PatsB, Union),
    length(PatsA, LA),
    length(PatsB, LB),
    length(Shared, LS),
    length(Union, LU),
    length(OnlyA, LOA),
    length(OnlyB, LOB),
    Max is max(LA, LB),
    CMax is LS / Max,
    CJac is LS / LU,
    Asym is abs(LOA - LOB),
    ( LOA > LOB ->
        Base = NameB, Elab0 = NameA, Type = elaboration
    ; LOB > LOA ->
        Base = NameA, Elab0 = NameB, Type = elaboration
    ;
        Base = NameA, Elab0 = NameB, Type = peer
    ),
    Elab = elaboration(Base, Elab0, Shared, Type, CMax, CJac, Asym).
