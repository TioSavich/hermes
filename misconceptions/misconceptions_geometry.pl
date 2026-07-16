% Geometry misconceptions — entailment classification layer.
%
% Uses entails_via_incompatibility/2 from formalization/axioms_geometry.pl
% (included into the sequent_engine module via arche-trace/load.pl).
%
% Multifile plumbing: entail_misconception/5 is owned by the `test_harness`
% module. Declare facts as `test_harness:entail_misconception(...)`. See
% misconceptions/test_harness.pl header for the full pattern.
%
% Geometry rows are shape-to-shape claims, not predicate calls, so there
% are no rule predicates to export or qualify — the fact itself carries
% the claim. The export list stays empty.
%
% Fact template:
%   test_harness:entail_misconception(
%       db_row(12),     % Source: db_row(ID) | asktm(Code)
%       rectangle_is_square,  % Description (short snake_case atom)
%       rectangle,      % Shape student starts from
%       square,         % Target shape student claims it entails
%       holds           % Claim: holds | fails — what the student asserts
%   ).

:- module(misconceptions_geometry, []).

:- multifile test_harness:entail_misconception/5.
:- discontiguous test_harness:entail_misconception/5.
:- dynamic test_harness:entail_misconception/5.

% Research-corpus batch modules (filled in by parallel agents in Task 8).
:- use_module(misconceptions(misconceptions_geometric_batch_1)).
:- use_module(misconceptions(misconceptions_geometric_batch_2)).
