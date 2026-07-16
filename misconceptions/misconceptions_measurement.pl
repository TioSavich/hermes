% Measurement misconceptions (area, perimeter, elapsed time) —
% native arithmetic layer.
%
% Multifile plumbing: arith_misconception/6 is owned by the `test_harness`
% module. Declare facts as `test_harness:arith_misconception(...)`. See
% misconceptions/test_harness.pl header for the full pattern.
%
% Rule predicates do NOT need to be exported. Register them with a
% module-qualified RuleName, e.g.
%   test_harness:arith_misconception(db_row(N), measurement, desc,
%       misconceptions_measurement:my_rule, Input, Expected).
% The harness reaches into this module directly, so the export list
% stays empty.

:- module(misconceptions_measurement, []).

:- multifile test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.

% Research-corpus batch modules (filled in by parallel agents in Task 8).
:- use_module(misconceptions(misconceptions_measurement_batch_1)).
:- use_module(misconceptions(misconceptions_measurement_batch_2)).

% =============================================================
% Module 5: Area / Perimeter / Elapsed-Time — Archetypal Vocabulary
% =============================================================
%
% Five archetypal misconceptions with explicit schema annotations.
% These document the schema-level incompatibilities that the 102
% corpus-encoded measurement rules (Task 8) invoke.
%
% Container schema (Lakoff & Nunez, Ch. 2):
%   In(unit, interior)   — unit lies INSIDE the shape (area)
%   On(unit, boundary)   — unit lies ON the shape's edge (perimeter)
%   is_incoherent({boundary_count(X,N), interior_coverage(X,N)})
%
% Measuring Stick schema:
%   A measuring unit laid end-to-end along a length, base-N for the unit.
%   Clock time is base-60, not base-10.
%
% Registration convention: module-qualified RuleName
%   test_harness:arith_misconception(..., misconceptions_measurement:rule_name, ...)

% ---- Reference correct predicates ----

area_of_rect(W, H, A) :- A is W * H.
perimeter_of_rect(W, H, P) :- P is 2 * (W + H).

% ---- Error 1: Count boundary units for area ---
% Student counts the unit squares around the edge instead of covering interior.
% SCHEMA: Container — In(unit, interior) required; student uses On(unit, boundary).
% GROUNDED: TODO — is_incoherent({boundary_count(X,N), interior_coverage(X,N)})
% CONNECTS TO: s(comp_nec(unlicensed(schema_substitution(boundary_for_interior))))

area_as_perimeter(W-H, A) :- A is 2 * (W + H).

test_harness:arith_misconception(
    vocabulary(container_schema), measurement, area_counted_as_perimeter,
    misconceptions_measurement:area_as_perimeter,
    4-3,
    12).   % correct area of 4x3 rect = 12; student returns 14 (perimeter)

% ---- Error 2: Incomplete boundary traversal for perimeter ---
% Student adds only two sides (L + W), missing the doubling.
% SCHEMA: Container — boundary traversal requires covering ALL edges.
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(partial_boundary_traversal)))

perimeter_two_sides(W-H, P) :- P is W + H.

test_harness:arith_misconception(
    vocabulary(container_schema), measurement, perimeter_incomplete_traversal,
    misconceptions_measurement:perimeter_two_sides,
    4-3,
    14).   % correct P = 14; student returns 7 (just L+W)

% ---- Error 3a: Area formula swapped with perimeter ---
% Student applies 2(L+W) when A = L*W is required.
% SCHEMA: Container — same surface confusion as area_counted_as_perimeter,
%   but here it's the FORMULA that's swapped, not the counting.
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(formula_substitution(perimeter_for_area))))

area_uses_perimeter_formula(W-H, A) :- A is 2 * (W + H).

test_harness:arith_misconception(
    vocabulary(container_schema), measurement, area_formula_inverted,
    misconceptions_measurement:area_uses_perimeter_formula,
    5-4,
    20).   % correct A = 20; student returns 18

% ---- Error 3b: Perimeter formula swapped with area ---
% Student applies L*W when P = 2(L+W) is required.
% SCHEMA: Container — mirror case of 3a.
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(formula_substitution(area_for_perimeter))))

perimeter_uses_area_formula(W-H, P) :- P is W * H.

test_harness:arith_misconception(
    vocabulary(container_schema), measurement, perimeter_formula_inverted,
    misconceptions_measurement:perimeter_uses_area_formula,
    5-4,
    18).   % correct P = 18; student returns 20

% ---- Error 4: Base-10 regrouping on elapsed time ---
% Student subtracts times using base-10 regrouping (1 hour = 100 min).
% SCHEMA: Measuring Stick — clock is base-60, not base-10.
% GROUNDED: TODO — base decomposition with wrong base
% CONNECTS TO: s(comp_nec(unlicensed(base_substitution(base10_for_base60))))

elapsed_base10_regroup(hours(H1,M1)-hours(H2,M2), hours(DH, DM)) :-
    ( M1 >= M2
    -> DM is M1 - M2, DH is H1 - H2
    ;  DM is (M1 + 100) - M2, DH is (H1 - 1) - H2
    ).

test_harness:arith_misconception(
    vocabulary(measuring_stick_schema), measurement, elapsed_time_base10_regroup,
    misconceptions_measurement:elapsed_base10_regroup,
    hours(7,8)-hours(2,53),
    hours(4,15)).   % correct 4h 15min (base-60); student returns hours(4,55) via base-10
