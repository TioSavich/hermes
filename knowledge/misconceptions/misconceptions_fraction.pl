% Fraction misconceptions — native arithmetic layer.
%
% Multifile plumbing: arith_misconception/6 is owned by the `test_harness`
% module. We declare it multifile against that module so facts asserted
% here surface when test_harness queries arith_misconception/6. See
% knowledge/misconceptions/test_harness.pl header for the full pattern.
%
% Rule predicates do NOT need to be exported. Register them with a
% module-qualified RuleName so the harness calls into this module
% directly — that keeps the module's export list empty and avoids a
% merge-conflict surface when parallel agents append new rules.
%
% Fact template:
%   test_harness:arith_misconception(
%       db_row(7),                               % Source: db_row(ID) | asktm(Code)
%       fraction,                                % Domain
%       same_denom_add_numer,                    % Description (short snake_case atom)
%       misconceptions_fraction:buggy_add_fracs, % RuleName: Module:LocalName
%       frac_add(1/2, 1/3),                      % Input
%       5/6                                      % Expected (what the CORRECT rule would return)
%   ).
%
% Use % GROUNDED: ... and % SCHEMA: ... comments to annotate Lakoff & Núñez
% grounding and source schemas where relevant.

:- module(misconceptions_fraction, []).

:- use_module(library(lists)).
:- use_module(library(pairs)).
:- use_module(library(yall)).

:- multifile test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.

% Research-corpus batch modules (filled in by parallel agents in Task 6).
% Each batch exists as its own module for parallel dispatch without file-level conflicts.
:- use_module(misconceptions(misconceptions_fraction_batch_1)).
:- use_module(misconceptions(misconceptions_fraction_batch_2)).
:- use_module(misconceptions(misconceptions_fraction_batch_3)).
:- use_module(misconceptions(misconceptions_fraction_batch_4)).
:- use_module(misconceptions(misconceptions_fraction_batch_5)).
:- use_module(misconceptions(misconceptions_fraction_batch_6)).
:- use_module(misconceptions(misconceptions_fraction_batch_7)).

% Benny's rule deformations (Erlwanger 1973). Paired with coordinated
% automata in knowledge/strategies/math/{smr_div_long,smr_frac_equiv_cross_mult}.pl.
% See knowledge/misconceptions/BENNY.md for the theoretical frame.
:- use_module(misconceptions(benny)).

% =============================================================
% G4Q1: Fraction ordering — butterfly strategy + variants
% Task: Order frac(2,3), frac(3,4), frac(3,8) smallest to largest.
% Correct: [frac(3,8), frac(2,3), frac(3,4)]
% =============================================================

% --- Reference correct strategy (input unchanged: runs all three cross-products) ---
g4q1_correct([frac(2,3), frac(3,4), frac(3,8)], [frac(3,8), frac(2,3), frac(3,4)]).

% --- Helper: cross_product/3 ---
% cross_product(frac(N1,D1), frac(N2,D2), first_greater|second_greater|equal)
% SCHEMA: Measuring Stick — numerators and denominators as commensurable lengths
% GROUNDED: TODO — multiply_grounded(RN1, RD2, C1), multiply_grounded(RN2, RD1, C2)
cross_product(frac(N1,D1), frac(N2,D2), Result) :-
    C1 is N1 * D2,
    C2 is N2 * D1,
    (C1 > C2 -> Result = first_greater
    ; C2 > C1 -> Result = second_greater
    ; Result = equal).

% --- Pairwise score: +1 if F beats Other, -1 if Other beats F ---
% Helpers are g4q1-prefixed so Task 6 parallel agents can introduce their
% own score/delta helpers in the same file without collision.
g4q1_score(F, Pairs, Score) :-
    findall(D, g4q1_pair_delta(F, Pairs, D), Ds),
    sum_list(Ds, Score).

g4q1_pair_delta(F, Pairs, +1) :- member(pair(F,_,first_greater), Pairs).
g4q1_pair_delta(F, Pairs, -1) :- member(pair(F,_,second_greater), Pairs).
g4q1_pair_delta(F, Pairs, -1) :- member(pair(_,F,first_greater), Pairs).
g4q1_pair_delta(F, Pairs, +1) :- member(pair(_,F,second_greater), Pairs).

% --- Variant 06-03: skips (2/3, 3/8) comparison, defaults without computing ---
% The correct result for (2/3, 3/8) is first_greater (2/3 > 3/8).
% Student defaulted to second_greater (wrong) — skipped the computation and
% guessed, and the guess happens to disagree with the correct value.
% CONNECTS TO: s(comp_nec(unlicensed(skip_pair(frac(2,3), frac(3,8)))))
g4q1_06_03([frac(2,3), frac(3,4), frac(3,8)], Order) :-
    cross_product(frac(2,3), frac(3,4), R1),
    cross_product(frac(3,4), frac(3,8), R2),
    % Skip: (2/3, 3/8) — student defaulted to second_greater (wrong)
    Pairs = [pair(frac(2,3), frac(3,4), R1),
             pair(frac(3,4), frac(3,8), R2),
             pair(frac(2,3), frac(3,8), second_greater)],
    Fracs = [frac(2,3), frac(3,4), frac(3,8)],
    maplist([F, S-F]>>(g4q1_score(F, Pairs, S)), Fracs, Scored),
    keysort(Scored, Sorted),
    pairs_values(Sorted, Order).

% --- Variant 18-04: skips (2/3, 3/8), fills by magnitude transfer ---
% CONNECTS TO: s(comp_nec(unlicensed(magnitude_transfer(from_prior_pair, wrong_sign))))
g4q1_18_04([frac(2,3), frac(3,4), frac(3,8)], Order) :-
    cross_product(frac(2,3), frac(3,4), R1),
    cross_product(frac(3,4), frac(3,8), R2),
    % Transfer: infer (2/3 > 3/8) from "2/3 was larger in the first pair"
    Pairs = [pair(frac(2,3), frac(3,4), R1),
             pair(frac(3,4), frac(3,8), R2),
             pair(frac(2,3), frac(3,8), second_greater)],  % wrong inference
    Fracs = [frac(2,3), frac(3,4), frac(3,8)],
    maplist([F, S-F]>>(g4q1_score(F, Pairs, S)), Fracs, Scored),
    keysort(Scored, Sorted),
    pairs_values(Sorted, Order).

% --- Variant 06-20: all pairs compared but (2/3, 3/4) uses mutated products ---
% CONNECTS TO: s(comp_nec(unlicensed(mutation(scale(8->24, 9->18)))))
g4q1_06_20([frac(2,3), frac(3,4), frac(3,8)], Order) :-
    % Correct: 2*4=8 vs 3*3=9 → second_greater (3/4 > 2/3)
    % Student mutated: 8→24, 9→18, reversing the result.
    R1 = first_greater,
    cross_product(frac(3,4), frac(3,8), R2),
    cross_product(frac(2,3), frac(3,8), R3),
    Pairs = [pair(frac(2,3), frac(3,4), R1),
             pair(frac(3,4), frac(3,8), R2),
             pair(frac(2,3), frac(3,8), R3)],
    Fracs = [frac(2,3), frac(3,4), frac(3,8)],
    maplist([F, S-F]>>(g4q1_score(F, Pairs, S)), Fracs, Scored),
    keysort(Scored, Sorted),
    pairs_values(Sorted, Order).

% --- Registration (Task 2 plumbing: facts go to test_harness module) ---
test_harness:arith_misconception(asktm('06-03'), fraction, g4q1_skip_pair,
    misconceptions_fraction:g4q1_06_03,
    [frac(2,3), frac(3,4), frac(3,8)],
    [frac(3,8), frac(2,3), frac(3,4)]).
test_harness:arith_misconception(asktm('18-04'), fraction, g4q1_magnitude_transfer,
    misconceptions_fraction:g4q1_18_04,
    [frac(2,3), frac(3,4), frac(3,8)],
    [frac(3,8), frac(2,3), frac(3,4)]).
test_harness:arith_misconception(asktm('06-20'), fraction, g4q1_unlicensed_mutation,
    misconceptions_fraction:g4q1_06_20,
    [frac(2,3), frac(3,4), frac(3,8)],
    [frac(3,8), frac(2,3), frac(3,4)]).

% =============================================================
% G4Q3: Fraction equivalence — multiply numerator only
% Task: write a fraction equivalent to 3/4.
% Correct: scale both numerator and denominator by same factor.
% Error: scales only numerator -> frac(6,4) instead of frac(6,8).
% SCHEMA: Measuring Stick — a fraction is a ratio of two lengths; both must scale.
% GROUNDED: TODO — multiply_grounded(RN, RFactor, RNout), multiply_grounded(RD, RFactor, RDout)
% CONNECTS TO: s(comp_nec(unlicensed(partial_scaling(numerator_only))))
% =============================================================

g4q3_numerator_only(frac(N, D)-Factor, frac(NOut, D)) :-
    NOut is N * Factor.

test_harness:arith_misconception(asktm(g4q3_common), fraction, equivalence_numerator_only,
    misconceptions_fraction:g4q3_numerator_only,
    frac(3,4)-2,
    frac(6,8)).

% =============================================================
% G4Q7: Fraction x whole number — adds whole to numerator
% Task: 3 x 1/4
% Correct: frac(3,4)
% Error: adds whole to numerator -> frac(4,4)
% SCHEMA: Arithmetic is Object Collection — conflates combining with scaling.
% GROUNDED: TODO — multiply_grounded(rec(3), rec(N), RNOut)
% CONNECTS TO: s(comp_nec(unlicensed(operation_substitution(add_for_multiply))))
% =============================================================

g4q7_add_whole_to_numerator(frac(N, D)-Whole, frac(NOut, D)) :-
    NOut is N + Whole.

test_harness:arith_misconception(asktm(g4q7_common), fraction, whole_times_fraction_adds,
    misconceptions_fraction:g4q7_add_whole_to_numerator,
    frac(1,4)-3,
    frac(3,4)).

% =============================================================
% G5Q1: Fraction addition — numerator/denominator separately (butterfly error)
% Task: 1/3 + 2/3
% Correct: equals 1 (encoded as frac(1,1))
% Error: adds top and bottom separately -> frac(3,6)
% SCHEMA: Arithmetic is Object Collection — treats fractions as two independent counts.
% GROUNDED: TODO — add_grounded(RN1, RN2, RNSum), add_grounded(RD1, RD2, RDSum)
% CONNECTS TO: s(comp_nec(unlicensed(componentwise_addition)))
% =============================================================

g5q1_add_separately(frac(N1, D1)-frac(N2, D2), frac(NSum, DSum)) :-
    NSum is N1 + N2,
    DSum is D1 + D2.

test_harness:arith_misconception(asktm(g5q1_common), fraction, add_numerators_denominators_separately,
    misconceptions_fraction:g5q1_add_separately,
    frac(1,3)-frac(2,3),
    frac(1,1)).

% =============================================================
% G5Q7: Fraction of fraction — ignores outer scalar
% Task: 2/3 of 3/4 mile
% Correct: 3/4 * 2/3 = 1/2 -> frac(1,2)
% Error: treats "2/3 of the way" as 2/3 of 1, ignores the whole -> frac(2,3)
% SCHEMA: Measuring Stick — "of the way" = fraction of the whole journey, not fraction of 1.
% GROUNDED: TODO — multiply_grounded on both frac terms
% CONNECTS TO: s(comp_nec(unlicensed(referent_drop(outer_scalar))))
% =============================================================

g5q7_ignore_scalar(_Whole-frac(N, D), frac(N, D)).

test_harness:arith_misconception(asktm(g5q7_common), fraction, fraction_of_fraction_ignores_scalar,
    misconceptions_fraction:g5q7_ignore_scalar,
    frac(3,4)-frac(2,3),
    frac(1,2)).
