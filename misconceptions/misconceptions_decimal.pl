% Decimal misconceptions — native arithmetic layer.
%
% Multifile plumbing: arith_misconception/6 is owned by the `test_harness`
% module. Declare facts as `test_harness:arith_misconception(...)`. See
% misconceptions/test_harness.pl header for the full pattern.
%
% Rule predicates do NOT need to be exported. Register them with a
% module-qualified RuleName, e.g.
%   test_harness:arith_misconception(db_row(N), decimal, desc,
%       misconceptions_decimal:my_rule, Input, Expected).
% The harness reaches into this module directly, so the export list
% stays empty.

:- module(misconceptions_decimal, []).

:- multifile test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.

% Research-corpus batch modules (filled in by parallel agents in Task 7).
:- use_module(misconceptions(misconceptions_decimal_batch_1)).
:- use_module(misconceptions(misconceptions_decimal_batch_2)).
