% Whole-number arithmetic misconceptions — native arithmetic layer.
%
% Multifile plumbing: arith_misconception/6 is owned by the `test_harness`
% module. Declare facts as `test_harness:arith_misconception(...)`. See
% misconceptions/test_harness.pl header for the full pattern.
%
% Rule predicates do NOT need to be exported. Register them with a
% module-qualified RuleName, e.g.
%   test_harness:arith_misconception(db_row(N), whole_number, desc,
%       misconceptions_whole_number:my_rule, Input, Expected).
% The harness reaches into this module directly, so the export list
% stays empty.

:- module(misconceptions_whole_number, []).

:- multifile test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.

% Research-corpus batch modules (filled in by parallel agents in Task 7).
:- use_module(misconceptions(misconceptions_whole_number_batch_1)).
:- use_module(misconceptions(misconceptions_whole_number_batch_2)).
:- use_module(misconceptions(misconceptions_whole_number_batch_3)).
:- use_module(misconceptions(misconceptions_whole_number_batch_4)).
:- use_module(misconceptions(misconceptions_whole_number_batch_5)).
