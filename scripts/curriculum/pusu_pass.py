#!/usr/bin/env python3
"""Engine-only put-up-or-shut-up pass for diagnostic-ready IM lessons.

The script reads the generated lesson ledger and asks one local SWI-Prolog
process to execute the compiled task routes.  It never interprets lesson prose:
all inputs, routes, contrast rules, and verdict evidence come from existing
compiled facts and engine predicates.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
import time
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
LEDGER = ROOT / "data/learningcommons/derived/im_lesson_evidence.json"
OUTPUT = ROOT / "data/learningcommons/derived/pusu_pass.json"
OUTPUT_PL = ROOT / "data/learningcommons/derived/pusu_pass.pl"
CALIBRATION = (
    "IM-G1-U5-L5", "IM-G2-U9-L1", "IM-G4-U5-L3",
    "IM-G5-U4-L5", "IM-G2-U7-L15", "IM-G7-U5-L1", "IM-GK-U5-L7",
)


# This is intentionally a stdin program, not a checked-in second runner: the
# public artifact remains a compact fact file and the only implementation is
# this script.  Every predicate below delegates to an already loaded engine
# surface; it adds no mathematics or diagnosis rules of its own.
PROLOG_RUNNER = r'''
:- use_module(formal(learner/activity_contract)).
:- use_module(misconceptions(test_harness)).
:- use_module(lessons('im/generated/compiled_receipt_routes')).
:- use_module(library(http/json)).
:- use_module(library(apply)).
:- use_module(library(lists)).
:- use_module(library(time)).

% Measured bands: contract lookup takes 3.66--4.51s in known casualties;
% productive paths take 1.6--41s except the >45s magnitude wall.  All 235
% pre-179 contrast rows completed under the former two-second guard, so ten
% seconds isolates contrast and diagnosis failures without hiding them.
pusu_budget_seconds(contract_lookup, 30).
pusu_budget_seconds(productive_execution, 60).
pusu_budget_seconds(contrast_diagnosis, 10).

:- dynamic pusu_contract_memo/3.

pusu_text(Term, Text) :- term_string(Term, Text, [quoted(true), numbervars(true)]).
pusu_goal_text(Goal, Text) :- term_string(Goal, Text, [quoted(true), numbervars(true)]).
pusu_result(Outcome, Result) :- is_dict(Outcome), get_dict(result, Outcome, Result).
pusu_result(action_outcome(_, Fields), Result) :- member(result(Result), Fields).
pusu_operation_domain(addition, whole_number).
pusu_operation_domain(subtraction, whole_number).
pusu_operation_domain(multiplication, whole_number).
pusu_operation_domain(division, whole_number).
% The registry files fraction arithmetic under `rational`, so a fraction
% operation's registered rules and its public diagnosis index are reachable
% under that name.  No battery is declared for the operation: an agreeing
% fraction contrast still refuses with battery_absent rather than borrowing
% a whole-number probe list.
pusu_operation_domain(fraction, rational).
% Fraction tasks carry the operation direction in the operand compound and a
% referent-whole role marker in the second position.  Pairing the two would
% bury the numerals under a marker that names no input, so the compound
% itself is the input the diagnosis surfaces are asked about.
pusu_input(Operands, unit(whole), Operands) :-
    compound(Operands), functor(Operands, Direction, 2),
    memberchk(Direction, [fraction_addend_pair, fraction_minuend_subtrahend]), !.
pusu_input(Left, Right, Left-Right).
% A small number of registered rules carry a typed task wrapper rather than
% the operation's ordinary operand pair.  The battery still supplies the two
% numerals; this adapter preserves the rule's engine-defined input shape.
pusu_rule_input(share_smaller_into_larger, Left, Right, share(Left, Right)) :- !.
pusu_rule_input(_, Left, Right, Input) :- pusu_input(Left, Right, Input).

% Canonical whole-number contrast batteries.  These are deliberately short,
% ordered probes: they cross carry/regrouping, near-double, single-/multi-digit
% multiplier, and exact-/inexact-division boundaries without using a trailing
% zero as the only witness.
pusu_battery(addition, [1-1,1-2,2-3,3-7,4-5,5-6,6-4,8-2,8-7,9-2,12-8,14-15,18-19,
                        27-28,34-35,47-28,58-43,67-35,86-14,99-1,109-91,
                        126-74,247-158,389-211,478-356,16-30,47-30]).
pusu_battery(subtraction, [1-2,2-3,5-9,2-1,3-1,5-2,9-1,12-3,14-5,15-7,18-9,21-12,
                           32-14,43-19,52-27,71-38,101-1,109-87,123-45,
                           200-199,307-158,502-277]).
pusu_battery(multiplication, [2-2,3-2,4-3,7-4,9-6,12-2,23-3,47-5,122-3,
                              12-11,23-12,47-13,122-33,34-21,56-14,99-12,
                              123-45,205-13]).
pusu_battery(division, [2-3,3-5,5-12,6-2,7-2,12-3,13-3,15-5,17-5,21-7,22-7,35-5,
                         37-5,48-6,50-6,63-9,64-9,84-7,85-7,121-11,
                         122-11,143-13,145-13]).
pusu_batteries_enabled.
pusu_battery_for(Op, Battery) :-
    current_predicate(pusu_batteries_enabled/0), pusu_batteries_enabled, pusu_battery(Op, Battery).

% Authored agreement regions.  The predicates below are only candidate names;
% pusu_*_context_validated/5 proves their battery behaviour per row before a
% row may retain the name.
pusu_context(partial_products_no_shift, single_digit_multiplier, multiplication, _, Multiplier) :-
    integer(Multiplier), Multiplier >= 0, Multiplier < 10.
pusu_context(partial_products_no_place_shift, single_digit_multiplier, multiplication, _, Multiplier) :-
    integer(Multiplier), Multiplier >= 0, Multiplier < 10.
pusu_context(raw_quotient_with_remainder, exact_division, division, Dividend, Divisor) :-
    integer(Dividend), integer(Divisor), Divisor =\= 0, 0 =:= Dividend mod Divisor.
pusu_context(raw_quotient_with_remainder, nonzero_remainder, division, Dividend, Divisor) :-
    integer(Dividend), integer(Divisor), Divisor =\= 0, 0 =\= Dividend mod Divisor.
pusu_context(adjust_dividend_for_division, exact_division, division, Dividend, Divisor) :-
    integer(Dividend), integer(Divisor), Divisor =\= 0, 0 =:= Dividend mod Divisor.
pusu_context(divide_larger_by_smaller, given_dividend_at_least_given_divisor,
             division, Dividend, Divisor) :-
    integer(Dividend), integer(Divisor), Divisor > 0, Dividend >= Divisor.
pusu_context(double_first_add_one, addends_are_near_doubles, addition, A, B) :- B =:= A + 1.
pusu_context(flip_subtraction_order, minuend_at_least_subtrahend, subtraction, A, B) :- A >= B.
pusu_context(share_smaller_into_larger, dividend_at_least_divisor, division, A, B) :- A >= B.
pusu_context(make_ten_drop_leftover, smaller_addend_completes_next_base, addition, A, B) :-
    Larger is max(A, B), Smaller is min(A, B), Needed is 10 - (Larger mod 10), Smaller =:= Needed.
pusu_context(dropped_leftover_after_make_ten, smaller_addend_completes_next_base, addition, A, B) :-
    Larger is max(A, B), Smaller is min(A, B), Needed is 10 - (Larger mod 10), Smaller =:= Needed.
pusu_context(dropped_ones_chunk, second_addend_has_no_ones, addition, _, B) :- 0 =:= B mod 10.
pusu_context(dropped_remainder_chunk, second_addend_has_no_ones, addition, _, B) :- 0 =:= B mod 10.
pusu_context(name_group_count_as_share_size, quotient_equals_group_count, division, A, B) :- A =:= B * B.
pusu_context(group_count_as_share_size, quotient_equals_group_count, division, A, B) :- A =:= B * B.
pusu_context(add_counts_without_composite_unit, factors_are_two, multiplication, 2, 2).
pusu_context(additive_count_for_multiplicative_structure, factors_are_two, multiplication, 2, 2).

pusu_context_name(partial_products_no_shift, single_digit_multiplier, multiplication).
pusu_context_name(partial_products_no_place_shift, single_digit_multiplier, multiplication).
pusu_context_name(raw_quotient_with_remainder, exact_division, division).
pusu_context_name(raw_quotient_with_remainder, nonzero_remainder, division).
pusu_context_name(adjust_dividend_for_division, exact_division, division).
pusu_context_name(divide_larger_by_smaller,
                  given_dividend_at_least_given_divisor, division).
pusu_context_name(double_first_add_one, addends_are_near_doubles, addition).
pusu_context_name(flip_subtraction_order, minuend_at_least_subtrahend, subtraction).
pusu_context_name(share_smaller_into_larger, dividend_at_least_divisor, division).
pusu_context_name(make_ten_drop_leftover, smaller_addend_completes_next_base, addition).
pusu_context_name(dropped_leftover_after_make_ten, smaller_addend_completes_next_base, addition).
pusu_context_name(dropped_ones_chunk, second_addend_has_no_ones, addition).
pusu_context_name(dropped_remainder_chunk, second_addend_has_no_ones, addition).
pusu_context_name(name_group_count_as_share_size, quotient_equals_group_count, division).
pusu_context_name(group_count_as_share_size, quotient_equals_group_count, division).
pusu_context_name(add_counts_without_composite_unit, factors_are_two, multiplication).
pusu_context_name(additive_count_for_multiplicative_structure, factors_are_two, multiplication).

pusu_input_text(Op, Left, Right, Text) :-
    pusu_text_input(Op, Left, Right, Term), pusu_text(Term, Text).
pusu_text_input(addition, A, B, add(A,B)).
pusu_text_input(subtraction, A, B, subtract(A,B)).
pusu_text_input(multiplication, A, B, multiply(A,B)).
pusu_text_input(division, A, B, divide(A,B)).

pusu_outcome_result(Outcome, Result) :- pusu_result(Outcome, Result).
pusu_outcome_trace(Outcome, Trace) :-
    ( is_dict(Outcome), get_dict(trace, Outcome, Trace)
    ; Outcome = action_outcome(_, Fields), member(evidence(existing_trace(Trace)), Fields)
    ).
pusu_outcome_correct_strategy(action_outcome(_, Fields)) :-
    member(validity(correct_but_inefficient), Fields),
    member(classification(deformation), Fields).

pusu_action_probe(Op, Kind, Left, Right, Status, Outcome, Trace, Result) :-
    Goal = action_automata_registry:run_action_automaton(Op, Kind, Left, Right, Outcome, Trace),
    pusu_call(contrast_diagnosis, Goal, CallResult),
    ( CallResult == succeeded, pusu_outcome_result(Outcome, Result)
    -> Status = action_output
    ; CallResult == timed_out
    -> Status = action_times_out
    ; CallResult = failed(_)
    -> Status = action_errors
    ;  Status = action_no_output
    ).

pusu_action_run(Op, Kind, Left, Right, Outcome, Trace, Result) :-
    pusu_action_probe(Op, Kind, Left, Right, action_output, Outcome, Trace, Result).

pusu_action_separates(Op, Deformation, Productive, Left, Right) :-
    pusu_action_run(Op, Deformation, Left, Right, _, _, Wrong),
    pusu_action_run(Op, Productive, Left, Right, _, _, Correct),
    Wrong \=@= Correct.

pusu_action_separator(Op, Deformation, Productive, Left, Right) :-
    pusu_battery_for(Op, Battery), member(Left-Right, Battery),
    pusu_action_separates(Op, Deformation, Productive, Left, Right), !.

% A domain refusal is decisive only when it occurs on an input used to
% establish this particular claim: its agreement slice or its separator.
% Other battery inputs remain useful domain evidence but do not pre-empt an
% independently executable context or normative contrast.
pusu_action_claim_issue(Family, Op, Deformation, Productive,
                        SeparatorLeft-SeparatorRight, Status) :-
    pusu_context_name(Family, Context, Op),
    pusu_battery_for(Op, Battery),
    pusu_context_inputs(Family, Context, Op, Battery, Inputs),
    append(Inputs, [SeparatorLeft-SeparatorRight], ClaimInputs),
    member(Left-Right, ClaimInputs),
    ( pusu_action_probe(Op, Deformation, Left, Right, Status, _, _, _)
    ; pusu_action_probe(Op, Productive, Left, Right, Status, _, _, _)
    ),
    memberchk(Status, [action_no_output, action_times_out, action_errors]), !.

pusu_context_inputs(Family, Context, Op, Battery, Inputs) :-
    findall(Left-Right,
            ( member(Left-Right, Battery), pusu_context(Family, Context, Op, Left, Right) ),
            Inputs),
    Inputs \= [].

pusu_action_agrees(Op, Deformation, Productive, Left, Right) :-
    pusu_action_run(Op, Deformation, Left, Right, _, _, Wrong),
    pusu_action_run(Op, Productive, Left, Right, _, _, Correct),
    Wrong =@= Correct.

pusu_action_context_validated(Family, Op, Deformation, Productive, SeparatorLeft-SeparatorRight, Context) :-
    pusu_context_name(Family, Context, Op),
    pusu_battery_for(Op, Battery),
    pusu_context_inputs(Family, Context, Op, Battery, Inputs),
    forall(member(Left-Right, Inputs),
           pusu_action_agrees(Op, Deformation, Productive, Left, Right)),
    \+ pusu_context(Family, Context, Op, SeparatorLeft, SeparatorRight).

pusu_rule_expected(addition, A, B, Expected) :- Expected is A + B.
pusu_rule_expected(subtraction, A, B, Expected) :- Expected is A - B.
pusu_rule_expected(multiplication, A, B, Expected) :- Expected is A * B.
pusu_rule_expected(division, A, B, Expected) :- B =\= 0, Expected is A // B.

% Division output schemas are registry declarations, not interchangeable
% machine behaviours.  This table says only how an output may be read at the
% arithmetic-value layer.  Traces, states, and vocabularies never enter it.
% A schema that can discard exact value information stays explicitly
% untranslatable, so the caller retains the trace classifier's term verdict.
pusu_division_schema_translation(equal_share_size,
                                 translatable(integer_value)).
pusu_division_schema_translation(integer_quotient_and_remainder,
                                 translatable(quotient_remainder(input_divisor))).
pusu_division_schema_translation(magnitude_ordered_quotient_and_remainder,
                                 translatable(quotient_remainder(smaller_operand))).
pusu_division_schema_translation(remainder_insensitive_share_size,
                                 translatable(integer_value)).
pusu_division_schema_translation(group_count_as_incorrect_share_size,
                                 translatable(integer_value)).
pusu_division_schema_translation(long_division_quotient_and_remainder,
                                 untranslatable(truncated_decimal_numeral)).
pusu_division_schema_translation(integer_quotient,
                                 translatable(integer_value)).
pusu_division_schema_translation(reached_total_as_incorrect_quotient,
                                 translatable(integer_value)).
pusu_division_schema_translation(incomplete_integer_quotient_and_remainder,
                                 translatable(quotient_remainder(input_divisor))).
pusu_division_schema_translation(rejected_exact_quotient_match,
                                 untranslatable(rejected_value)).
pusu_division_schema_translation(sum_as_incorrect_quotient,
                                 translatable(wrapped_integer(digit_sum_numeral))).

% The runner's productive floor quotient carries the input's remainder
% implicitly.  Two older registered rules predate the action-schema registry,
% so their output schemas are declared here rather than guessed from a term
% inside the comparison.
pusu_division_schema_translation(productive_integer_quotient,
                                 translatable(quotient_with_implicit_remainder)).
pusu_division_schema_translation(adjusted_integer_quotient,
                                 translatable(integer_value)).
pusu_division_schema_translation(raw_quotient_plus_fraction,
                                 translatable(quotient_plus_fraction)).
pusu_division_rule_output_schema(adjust_dividend_for_division,
                                 adjusted_integer_quotient).
pusu_division_rule_output_schema(raw_quotient_with_remainder,
                                 raw_quotient_plus_fraction).
pusu_division_rule_output_schema(Kind, Schema) :-
    action_automata_registry:action_automaton_signature(
        division, Kind, _, Schema).

% This rule's value is (Dividend // Divisor) +
% (Dividend mod Divisor) / Divisor.  The divmod identity makes that exactly
% Dividend / Divisor throughout the rule's declared nonzero-remainder domain,
% so no arithmetic-value-layer separator exists.
pusu_rule_value_layer_separator_capability(
    raw_quotient_with_remainder,
    cannot_separate(structural_divmod_identity)).

pusu_division_registry_schema_covered(Schema, Translation) :-
    action_automata_registry:action_automaton_signature(
        division, _, _, Schema),
    pusu_division_schema_translation(Schema, Translation).

pusu_division_productive_kind(action_outcome(Kind, _), Kind).
pusu_division_productive_kind(Outcome, Kind) :-
    is_dict(Outcome), get_dict(action_kind, Outcome, Kind).
pusu_division_productive_kind(Outcome, Kind) :-
    is_dict(Outcome),
    get_dict(validation, Outcome,
             validated(_, action_automaton(Kind, _))).

pusu_division_productive_declared_kind(action_outcome(Kind, _), Kind).
pusu_division_productive_declared_kind(Outcome, Kind) :-
    is_dict(Outcome), get_dict(action_kind, Outcome, Kind).

pusu_division_productive_schema(Outcome, _, Schema) :-
    pusu_division_productive_declared_kind(Outcome, Kind),
    action_automata_registry:action_automaton_signature(
        division, Kind, _, Schema), !.

pusu_division_read_value(integer_value, _, _, Value,
                         arithmetic_value(Value, 1)) :-
    integer(Value).
pusu_division_read_value(quotient_with_implicit_remainder, Left, Right,
                         Quotient, arithmetic_value(Numerator, Right)) :-
    integer(Quotient), integer(Left), integer(Right), Right > 0,
    Remainder is Left mod Right,
    Numerator is Quotient * Right + Remainder.
pusu_division_read_value(quotient_remainder(input_divisor), _, Right,
                         quotient_remainder(Quotient, Remainder),
                         arithmetic_value(Numerator, Right)) :-
    integer(Quotient), integer(Remainder), integer(Right), Right > 0,
    Remainder >= 0, Remainder < Right,
    Numerator is Quotient * Right + Remainder.
pusu_division_read_value(quotient_remainder(smaller_operand), Left, Right,
                         quotient_remainder(Quotient, Remainder),
                         arithmetic_value(Numerator, Divisor)) :-
    integer(Quotient), integer(Remainder),
    integer(Left), integer(Right),
    Divisor is min(Left, Right), Divisor > 0,
    Remainder >= 0, Remainder < Divisor,
    Numerator is Quotient * Divisor + Remainder.
pusu_division_read_value(quotient_plus_fraction, _, _,
                         quot_plus_frac(Quotient, Remainder, Divisor),
                         arithmetic_value(Numerator, Divisor)) :-
    integer(Quotient), integer(Remainder), integer(Divisor), Divisor > 0,
    Remainder >= 0, Remainder < Divisor,
    Numerator is Quotient * Divisor + Remainder.
pusu_division_read_value(wrapped_integer(Functor), _, _, Wrapped,
                         arithmetic_value(Value, 1)) :-
    compound(Wrapped), Wrapped =.. [Functor, Value], integer(Value).

pusu_division_schema_value(Schema, Left, Right, Output, Value) :-
    pusu_division_schema_translation(Schema, translatable(Reader)),
    pusu_division_read_value(Reader, Left, Right, Output, Value).

pusu_rule_evidence_output(Evidence, Output) :-
    is_dict(Evidence), get_dict(got, Evidence, Output), !.
pusu_rule_evidence_output(Output, Output).

pusu_arithmetic_value_equal(arithmetic_value(LeftNumerator, LeftDenominator),
                            arithmetic_value(RightNumerator, RightDenominator)) :-
    LeftNumerator * RightDenominator =:=
        RightNumerator * LeftDenominator.

pusu_division_comparison_relation(Kind, ProductiveSchema, Left, Right,
                                  Expected, Evidence, Relation) :-
    ( pusu_division_rule_output_schema(Kind, RuleSchema),
      pusu_division_schema_value(
          ProductiveSchema, Left, Right, Expected, ProductiveValue),
      pusu_rule_evidence_output(Evidence, RuleOutput),
      pusu_division_schema_value(
          RuleSchema, Left, Right, RuleOutput, RuleValue)
    -> ( pusu_arithmetic_value_equal(ProductiveValue, RuleValue)
       -> Relation = arithmetic_value_agreement
       ;  Relation = arithmetic_value_separation )
    ;  Relation = untranslatable_term_fallback
    ).

pusu_rule_comparison_status(division, Kind, _, Left, Right, ProductiveSchema,
                            Expected, Evidence, _, Status, Relation) :-
    pusu_division_comparison_relation(
        Kind, ProductiveSchema, Left, Right, Expected, Evidence, Relation),
    Relation \== untranslatable_term_fallback, !,
    ( Relation == arithmetic_value_agreement
    -> Status = agrees
    ;  Status = separates ).
pusu_rule_comparison_status(division, Kind, Rule, Left, Right, ProductiveSchema,
                            Expected, Evidence, Class, Status,
                            untranslatable_term_fallback) :-
    pusu_division_comparison_relation(
        Kind, ProductiveSchema, Left, Right, Expected, Evidence,
        untranslatable_term_fallback), !,
    pusu_rule_class_status(
        division, Kind, Rule, Left, Right, Class, Status).
pusu_rule_comparison_status(Op, Kind, Rule, Left, Right, _, _, _, Class, Status,
                            term_classification) :-
    pusu_rule_class_status(Op, Kind, Rule, Left, Right, Class, Status).

% The action signature is the registry's declared input domain. Type names stay
% explicit: an unknown type is unavailable evidence, never a cue to infer a
% domain from its spelling.
pusu_declared_operand_type(nonnegative_integer_addend, Value) :- integer(Value), Value >= 0.
pusu_declared_operand_type(nonnegative_integer_minuend, Value) :- integer(Value), Value >= 0.
pusu_declared_operand_type(nonnegative_integer_subtrahend, Value) :- integer(Value), Value >= 0.
pusu_declared_operand_type(nonnegative_integer_dividend, Value) :- integer(Value), Value >= 0.
pusu_declared_operand_type(nonnegative_integer_total, Value) :- integer(Value), Value >= 0.
pusu_declared_operand_type(positive_integer_factor, Value) :- integer(Value), Value > 0.
pusu_declared_operand_type(positive_integer_group_count, Value) :- integer(Value), Value > 0.
pusu_declared_operand_type(positive_integer_group_size, Value) :- integer(Value), Value > 0.
pusu_declared_operand_type(positive_integer_divisor, Value) :- integer(Value), Value > 0.

pusu_known_declared_operand_type(Type) :-
    memberchk(Type,
              [nonnegative_integer_addend,
               nonnegative_integer_minuend,
               nonnegative_integer_subtrahend,
               nonnegative_integer_dividend,
               nonnegative_integer_total,
               positive_integer_factor,
               positive_integer_group_count,
               positive_integer_group_size,
               positive_integer_divisor]).

% Subtraction's registered automata uniformly require a nonnegative difference.
% The other operations have no operation-wide relational bound: in particular,
% division kinds disagree about whether a dividend below the divisor has a
% misconception form, so their same-kind action probes decide that case.
pusu_declared_operation_relation(subtraction, Left, Right) :- Left >= Right.
pusu_declared_operation_relation(addition, _, _).
pusu_declared_operation_relation(multiplication, _, _).
pusu_declared_operation_relation(division, _, _).

pusu_declared_rule_domain_status(Op, Kind, Left, Right, Status) :-
    ( action_automata_registry:action_automaton_signature(
          Op, Kind, inputs(LeftType, RightType), _)
    -> ( pusu_known_declared_operand_type(LeftType),
         pusu_known_declared_operand_type(RightType)
       -> ( pusu_declared_operand_type(LeftType, Left),
            pusu_declared_operand_type(RightType, Right),
            pusu_declared_operation_relation(Op, Left, Right)
          -> Status = inside_declared_domain
          ;  Status = outside_declared_domain )
       ;  Status = declaration_unavailable )
    ;  Status = declaration_unavailable
    ).

pusu_rule_predicate_exists(Module:Name) :-
    atom(Module), atom(Name), current_predicate(Module:Name/2), !.
pusu_rule_predicate_exists(Name) :-
    atom(Name), current_predicate(Name/2).

% An undefined classification is split by executable evidence. A missing rule
% is a defect. Outside-domain status comes from the registered signature plus
% the declared operation relation. Inside that domain, refusal by the action
% automaton for the same kind proves that the misconception has no form at the
% input. Missing declarations or an errored automaton remain explicitly
% unavailable rather than being assigned to either refusal class.
pusu_rule_refusal_status(_, _, Rule, _, _, rule_defect_no_output) :-
    \+ pusu_rule_predicate_exists(Rule), !.
pusu_rule_refusal_status(Op, Kind, _, Left, Right, rule_domain_refusal) :-
    pusu_declared_rule_domain_status(Op, Kind, Left, Right, outside_declared_domain), !.
pusu_rule_refusal_status(Op, Kind, _, Left, Right, rule_refusal_reason_unavailable) :-
    pusu_declared_rule_domain_status(Op, Kind, Left, Right, declaration_unavailable), !.
pusu_rule_refusal_status(Op, Kind, _, Left, Right, Status) :-
    pusu_action_probe(Op, Kind, Left, Right, ActionStatus, _, _, _),
    ( ActionStatus == action_output
    -> Status = rule_defect_no_output
    ; ActionStatus == action_no_output
    -> Status = rule_no_form_at_input
    ;  Status = rule_refusal_reason_unavailable
    ).

pusu_rule_probe(Op, Rule, Left, Right, Status) :-
    pusu_operation_domain(Op, Domain),
    test_harness:arith_misconception(_, Domain, Kind, Rule, _, _),
    pusu_rule_expected(Op, Left, Right, Expected), pusu_rule_input(Kind, Left, Right, Input),
    pusu_call(contrast_diagnosis,
              test_harness:classify_arith_by_trace(Rule, Input, Expected, Class, Evidence), Result),
    ( Result == succeeded
    -> ( Op == division
       -> ProductiveSchema = productive_integer_quotient
       ;  ProductiveSchema = not_applicable ),
       pusu_rule_comparison_status(
           Op, Kind, Rule, Left, Right, ProductiveSchema, Expected, Evidence,
           Class, Status, _)
    ; Result == timed_out
    -> Status = rule_times_out
    ;  Status = rule_errors
    ).

% Only an executed, output-agreeing trace class may validate an agreement
% context. Inference-limited rules remain execution defects; an undefined
% result is classified by declared-domain and same-kind automaton evidence.
pusu_rule_class_status(_, _, _, _, _, wrong_answer, separates).
pusu_rule_class_status(_, _, _, _, _, well_formed, agrees).
pusu_rule_class_status(_, _, _, _, _, trace_unavailable, agrees).
pusu_rule_class_status(_, _, _, _, _, trace_divergence, agrees).
pusu_rule_class_status(Op, Kind, Rule, Left, Right, undefined, Status) :-
    pusu_rule_refusal_status(Op, Kind, Rule, Left, Right, Status).
pusu_rule_class_status(_, _, _, _, _, loop_detected, rule_times_out).

pusu_rule_separates(Op, Rule, Left, Right) :-
    pusu_rule_probe(Op, Rule, Left, Right, separates).

pusu_rule_separator(Op, Rule, Left, Right) :-
    pusu_battery_for(Op, Battery), member(Left-Right, Battery),
    pusu_rule_separates(Op, Rule, Left, Right), !.

pusu_rule_context_validated(Family, Op, Rule, SeparatorLeft-SeparatorRight, Context) :-
    pusu_context_name(Family, Context, Op),
    pusu_battery_for(Op, Battery),
    pusu_context_inputs(Family, Context, Op, Battery, Inputs),
    forall(member(Left-Right, Inputs), pusu_rule_probe(Op, Rule, Left, Right, agrees)),
    \+ pusu_context(Family, Context, Op, SeparatorLeft, SeparatorRight).

pusu_rule_agreement_region_validated(Family, Op, Rule, Context) :-
    pusu_context_name(Family, Context, Op),
    pusu_battery_for(Op, Battery),
    pusu_context_inputs(Family, Context, Op, Battery, Inputs),
    forall(member(Left-Right, Inputs),
           pusu_rule_probe(Op, Rule, Left, Right, agrees)).

pusu_trace_classified(Family, Productive, action_outcome(_, Fields)) :-
    member(misconception_family(Family), Fields),
    member(deformation_of(Productive), Fields).

pusu_agreement_status_action(Family, Op, Deformation, Productive, TraceLeft, TraceRight,
                             Status, ContextText, SeparatorText, TraceRoundTrip) :-
    ( pusu_battery_for(Op, _)
    -> ( pusu_action_separator(Op, Deformation, Productive, SeparatorLeft, SeparatorRight)
       -> pusu_input_text(Op, SeparatorLeft, SeparatorRight, SeparatorText),
          ( pusu_action_claim_issue(Family, Op, Deformation, Productive,
                                    SeparatorLeft-SeparatorRight, Status)
          -> ContextText = "", TraceRoundTrip = false
          ;  pusu_action_context_validated(Family, Op, Deformation, Productive,
                                          SeparatorLeft-SeparatorRight, Context)
          -> atom_string(Context, ContextText), Status = "agrees_at_input", TraceRoundTrip = false
          ;  ContextText = "", Status = "context_unvalidated", TraceRoundTrip = false )
       ;  ContextText = "", SeparatorText = "",
          ( pusu_action_run(Op, Deformation, TraceLeft, TraceRight, Outcome, DeformationTrace, _),
            pusu_outcome_correct_strategy(Outcome),
            pusu_trace_classified(Family, Productive, Outcome),
            pusu_action_run(Op, Productive, TraceLeft, TraceRight, _, ProductiveTrace, _),
            DeformationTrace \=@= ProductiveTrace
          -> Status = "normative_contrast", TraceRoundTrip = true
          ;  Status = "vacuous_pair", TraceRoundTrip = false ) )
    ; ContextText = "", SeparatorText = "", Status = "battery_absent", TraceRoundTrip = false ).

pusu_agreement_status_rule(Family, Op, Rule, Status, ContextText, SeparatorText,
                           BatteryRefusals) :-
    pusu_rule_battery_refusals(Op, Rule, BatteryRefusals),
    ( pusu_battery_for(Op, _)
    -> ( pusu_rule_battery_issue(Op, Rule, Status)
       -> ContextText = "", SeparatorText = ""
       ;  pusu_rule_separator(Op, Rule, SeparatorLeft, SeparatorRight)
       -> pusu_input_text(Op, SeparatorLeft, SeparatorRight, SeparatorText),
          ( pusu_rule_context_validated(Family, Op, Rule, SeparatorLeft-SeparatorRight, Context)
          -> atom_string(Context, ContextText), Status = "agrees_at_input"
          ;  ContextText = "", Status = "context_unvalidated" )
       ;  pusu_rule_agreement_region_validated(Family, Op, Rule, Context)
       -> atom_string(Context, ContextText),
          SeparatorText = "",
          ( pusu_rule_value_layer_separator_capability(
                Family, cannot_separate(structural_divmod_identity))
          -> Status = "cannot_separate_at_value_layer"
          ;  Status = "vacuous_pair" )
       ;  ContextText = "", SeparatorText = "", Status = "vacuous_pair" )
    ; ContextText = "", SeparatorText = "", Status = "battery_absent" ).

pusu_rule_battery_issue(Op, Rule, Status) :-
    pusu_battery_for(Op, Battery), member(Left-Right, Battery),
    pusu_rule_probe(Op, Rule, Left, Right, Status),
    memberchk(Status, [rule_defect_no_output, rule_times_out, rule_errors]), !.

pusu_rule_battery_refusals(Op, Rule, Refusals) :-
    ( pusu_battery_for(Op, Battery)
    -> findall(_{input:InputText, status:Status},
               ( member(Left-Right, Battery),
                 pusu_rule_probe(Op, Rule, Left, Right, Status),
                 memberchk(Status,
                           [rule_domain_refusal, rule_no_form_at_input,
                            rule_refusal_reason_unavailable]),
                 pusu_input_text(Op, Left, Right, InputText)
               ),
               Refusals)
    ;  Refusals = []
    ).

% Synthetic predicates below are fixture-only. They add no registry rows to a
% normal pass; --refusal-fixtures calls the classifier directly.
pusu_fixture_delegated_result(Op, Kind, Left-Right, Got) :-
    action_automata_registry:run_action_automaton(
        Op, Kind, Left, Right, action_outcome(_, Fields), _),
    memberchk(result(Got), Fields).

pusu_fixture_borrow_without_reducing_bases(Input, Got) :-
    pusu_fixture_delegated_result(
        subtraction, borrow_without_reducing_bases, Input, Got).
pusu_fixture_unregistered_rule(_, _) :- fail.

pusu_refusal_fixture(missing_rule, subtraction, add_instead_of_subtract_column,
                     pusu_fixture_missing_rule, 10, 4, rule_defect_no_output).
pusu_refusal_fixture(domain_refusal, subtraction, add_instead_of_subtract_column,
                     misconceptions_whole_number_action_delegates:add_instead_of_subtract_column,
                     1, 2, rule_domain_refusal).
pusu_refusal_fixture(no_form, subtraction, borrow_without_reducing_bases,
                     pusu_fixture_borrow_without_reducing_bases,
                     25, 10, rule_no_form_at_input).
pusu_refusal_fixture(reason_unavailable, subtraction, pusu_fixture_unregistered_kind,
                     pusu_fixture_unregistered_rule,
                     25, 10, rule_refusal_reason_unavailable).
pusu_refusal_fixture(division_output_defect, division, measure_groups_of_size,
                     pusu_fixture_unregistered_rule,
                     2, 3, rule_defect_no_output).

pusu_refusal_fixture_row(Name, Row) :-
    pusu_refusal_fixture(Name, Op, Kind, Rule, Left, Right, Expected),
    pusu_rule_refusal_status(Op, Kind, Rule, Left, Right, Actual),
    pusu_declared_rule_domain_status(Op, Kind, Left, Right, DomainStatus),
    ( pusu_rule_predicate_exists(Rule) -> PredicateExists = true ; PredicateExists = false ),
    pusu_action_probe(Op, Kind, Left, Right, ActionStatus, _, _, _),
    pusu_input_text(Op, Left, Right, InputText),
    Row = _{fixture:Name, operation:Op, kind:Kind, input:InputText,
            expected:Expected, actual:Actual, predicate_exists:PredicateExists,
            declared_domain:DomainStatus, automaton_status:ActionStatus}.

pusu_refusal_fixture_main :-
    forall(pusu_refusal_fixture_row(_, Row),
           ( write('FIXTURE\t'),
             json_write_dict(current_output, Row, [width(1000000)]), nl )),
    flush_output.

pusu_call(Budget, Goal, Result) :-
    pusu_budget_seconds(Budget, Seconds),
    catch(
        ( call_with_time_limit(Seconds, call(Goal)) -> Result = succeeded ; Result = failed ),
        Error,
        pusu_call_exception(Error, Result)
    ).

pusu_call_exception(time_limit_exceeded, timed_out).
pusu_call_exception(error(time_limit_exceeded, _), timed_out).
pusu_call_exception(Error, failed(Failure)) :- pusu_text(Error, Failure).
pusu_failure(failed(Failure), Failure) :- !.
pusu_failure(_, "").
pusu_first_failure([Result|_], Failure) :-
    pusu_failure(Result, Failure), Failure \== "", !.
pusu_first_failure([_|Rest], Failure) :- pusu_first_failure(Rest, Failure).
pusu_first_failure([], "").
pusu_prefer_failure(First, _, First) :- First \== "", !.
pusu_prefer_failure(_, Second, Second).

pusu_registry_candidates(Code, Task, Candidates) :-
    findall(candidate(Goal, Outcome),
            ( activity_contract:task_action_operands(Task, Op, Left, Right),
              compiled_action_mappings:compiled_lesson_strategy(Code, Op, Kind, _),
              Goal = action_automata_registry:run_action_automaton(Op, Kind, Left, Right, Outcome, _) ),
            Candidates).

pusu_try_registry([], _, _, failed, []).
pusu_try_registry([candidate(CandidateGoal, CandidateOutcome)|Rest], Outcome, Goal, Result, Attempts) :-
    pusu_call(productive_execution, CandidateGoal, CandidateResult),
    ( CandidateResult == succeeded
    -> Outcome = CandidateOutcome, Goal = CandidateGoal, Result = succeeded, Attempts = [CandidateResult]
    ;  pusu_try_registry(Rest, Outcome, Goal, RestResult, RestAttempts),
       Attempts = [CandidateResult|RestAttempts],
       Result = RestResult
    ).

pusu_run_productive(Code, Task, Outcome, Goal, TimedOut, Failure) :-
    pusu_registry_candidates(Code, Task, RegistryCandidates),
    pusu_try_registry(RegistryCandidates, RegistryOutcome, RegistryGoal, RegistryResult, RegistryResults),
    ( RegistryResult == succeeded
    -> Outcome = RegistryOutcome, Goal = RegistryGoal, TimedOut = false, Failure = ""
    ;  Goal = activity_contract:activity_task_path(Code, Task, Outcome),
       pusu_call(productive_execution, Goal, PathResult),
       ( ( memberchk(timed_out, RegistryResults) ; PathResult == timed_out )
       -> TimedOut = true
       ;  TimedOut = false
       ),
       ( PathResult == succeeded -> true ; Outcome = unsupported{} ),
       pusu_failure(PathResult, PathFailure),
       pusu_first_failure(RegistryResults, RegistryFailure),
       pusu_prefer_failure(PathFailure, RegistryFailure, Failure)
    ), !.

pusu_productive(Code, Row) :-
    compiled_task_instances:compiled_lesson_task_instance(Code, productive-Task, _),
    pusu_run_productive(Code, Task, Outcome, Goal, TimedOut, Failure),
    pusu_text(Task, TaskText), pusu_goal_text(Goal, GoalText),
    ( pusu_result(Outcome, Result)
    -> pusu_text(Result, ResultText), Status = "runs"
    ;  ResultText = "", Status = "cannot_run"
    ),
    Row = _{task:TaskText, status:Status, result:ResultText, goal:GoalText,
            timed_out:TimedOut, failure:Failure}.

% too_vague is never served.  Fourteen rows from the 07-21 churn pass still
% carry that label with an executable rule behind them, so the public index
% can answer with it; a label that may not be served can neither name a
% recovery nor contradict one.  It is withheld from candidacy, and the
% withholding is recorded in the surface field rather than dropped in
% silence.
pusu_withheld_diagnosis(too_vague).

pusu_partition_withheld([], [], []).
pusu_partition_withheld([Name|Rest], Servable, Withheld) :-
    ( pusu_withheld_diagnosis(Name)
    -> Withheld = [Name|WithheldRest], Servable = ServableRest
    ;  Servable = [Name|ServableRest], Withheld = WithheldRest
    ),
    pusu_partition_withheld(Rest, ServableRest, WithheldRest).

pusu_surface_with_withheld(Surface, [], Surface) :- !.
pusu_surface_with_withheld(Surface, Withheld, Annotated) :-
    atomic_list_concat(Withheld, '+', Names),
    format(string(Annotated), "~w_after_withheld(~w)", [Surface, Names]).

pusu_public_diagnosis(Domain, Input, Wrong, Kind, Status, Detail, Withheld) :-
    findall(Description,
            ( test_harness:diagnose_error(Domain, Input, Wrong, Match),
              Description = Match.description ), Descriptions0),
    sort(Descriptions0, Descriptions1),
    pusu_partition_withheld(Descriptions1, Descriptions, Withheld),
    ( memberchk(Kind, Descriptions)
    -> Status = "recovered", Detail = Descriptions
    ; Descriptions = []
    -> Status = "no_diagnosis", Detail = []
    ;  Status = "recovered_different_error", Detail = Descriptions
    ).

% The action registry is a second existing diagnostic surface.  It is used only
% after diagnose_error/4 has no answer, and records that fallback explicitly.
pusu_inverse_action_diagnosis(Op, Left, Right, Wrong, Kind, Status, Detail) :-
    findall(Candidate,
            ( action_automata_registry:action_automaton_pair(Op, _, Candidate, _),
              catch(action_automata_registry:run_action_automaton(
                        Op, Candidate, Left, Right, Outcome, _), _, fail),
              pusu_result(Outcome, CandidateResult), CandidateResult =@= Wrong ),
            Candidates0),
    sort(Candidates0, Candidates),
    ( memberchk(Kind, Candidates)
    -> Status = "recovered", Detail = Candidates
    ; Candidates = []
    -> Status = "no_diagnosis", Detail = []
    ;  Status = "recovered_different_error", Detail = Candidates
    ).

pusu_diagnosis(Op, Left, Right, Wrong, Kind, Status, Detail, Surface) :-
    pusu_operation_domain(Op, Domain), pusu_input(Left, Right, Input),
    pusu_public_diagnosis(Domain, Input, Wrong, Kind, PublicStatus, PublicDetail, Withheld),
    ( PublicStatus == "no_diagnosis"
    -> pusu_inverse_action_diagnosis(Op, Left, Right, Wrong, Kind, Status, Detail),
       pusu_surface_with_withheld("action_automaton_inverse", Withheld, Surface)
    ;  Status = PublicStatus, Detail = PublicDetail,
       pusu_surface_with_withheld("diagnose_error", Withheld, Surface)
    ), !.
% An operation outside the registered rule domains still has a second
% diagnostic surface: the action registry runs the compiled operands
% directly.  Asking it here is what keeps measurement, geometry, counting
% and decimal contrasts from reaching the catch-all with neither surface
% consulted.
pusu_diagnosis(Op, Left, Right, Wrong, Kind, Status, Detail, "action_automaton_inverse") :-
    \+ pusu_operation_domain(Op, _),
    pusu_inverse_action_diagnosis(Op, Left, Right, Wrong, Kind, Status, Detail), !.
pusu_diagnosis(_, _, _, _, _, "no_diagnosis", [], "unavailable").

pusu_diagnosis_with_budget(Op, Left, Right, Wrong, Kind, Status, Detail, Surface, TimedOut, Failure) :-
    Goal = pusu_diagnosis(Op, Left, Right, Wrong, Kind, Status0, Detail0, Surface0),
    pusu_call(contrast_diagnosis, Goal, Result),
    ( Result == succeeded
    -> Status = Status0, Detail = Detail0, Surface = Surface0, TimedOut = false, Failure = ""
    ; Result == timed_out
    -> Status = "no_diagnosis", Detail = [], Surface = "timeout", TimedOut = true, Failure = ""
    ;  Status = "no_diagnosis", Detail = [], Surface = "none", TimedOut = false,
       pusu_failure(Result, Failure)
    ).

pusu_viability_field("agrees_at_input", Code, Family, ContextText, SeparatorText,
                     [_{lesson:Code, family:Family, context:Context,
                        separating_input:SeparatorText,
                        separation_witness:_{kind:found,
                                             input:SeparatorText}}]) :-
    atom_string(Context, ContextText), !.
pusu_viability_field("cannot_separate_at_value_layer", Code, Family,
                     ContextText, "",
                     [_{lesson:Code, family:Family, context:Context,
                        separating_input:"",
                        separation_witness:_{
                            kind:cannot_separate_at_value_layer,
                            reason:structural_divmod_identity}}]) :-
    atom_string(Context, ContextText), !.
pusu_viability_field(_, _, _, _, _, []).

pusu_norm_citation("normative_contrast", Evidence, Citation) :- pusu_text(Evidence, Citation), !.
pusu_norm_citation(_, _, "").

% The current input may not distinguish two registered diagnostic descriptions.
% Re-run both descriptions through the public rule surface and, when necessary,
% search the same canonical operation battery before calling that recovery wrong.
% A named diagnosis comparison uses an actual engine result.  A registered
% rule is never represented by an unbound output: failed, undefined, and
% inference-limited executions are explicit no-output markers.  Action-only
% kinds use their public action-automaton route so rule/action comparisons are
% meaningful as well.
pusu_computed_output(Value, value(Value)) :- ground(Value), !.
pusu_computed_output(_, no_output).

pusu_named_rule_output(Op, Kind, Left, Right, Output) :-
    pusu_operation_domain(Op, Domain), pusu_rule_input(Kind, Left, Right, Input),
    test_harness:arith_misconception(_, Domain, Kind, Rule, _, _),
    pusu_call(contrast_diagnosis,
              test_harness:classify_arith(Rule, Input, pusu_expected_marker, Class, Got), Result),
    ( Result == succeeded, memberchk(Class, [well_formed, wrong_answer])
    -> pusu_computed_output(Got, Output)
    ;  Output = no_output
    ), !.
pusu_named_rule_output(Op, Kind, Left, Right, Output) :-
    pusu_action_run(Op, Kind, Left, Right, _, _, Result),
    pusu_computed_output(Result, Output), !.
pusu_named_rule_output(_, _, _, _, no_output).

pusu_value_output(value(_)).

pusu_diagnosis_separator(Op, RunKind, RecoveredKind, Left, Right) :-
    pusu_battery_for(Op, Battery), member(Left-Right, Battery),
    pusu_named_rule_output(Op, RunKind, Left, Right, RunOutput),
    pusu_named_rule_output(Op, RecoveredKind, Left, Right, RecoveredOutput),
    pusu_value_output(RunOutput), pusu_value_output(RecoveredOutput),
    RunOutput \=@= RecoveredOutput, !.

% How a recovered name stands to the run kind, decided by execution rather
% than by reading the two names:
%   incomparable_at_input    -- the engine produced no value for this kind here
%   disagrees_at_input       -- it names a different behaviour at this input
%   separates_on_battery(I)  -- same answer here, different answer at I
%   no_battery               -- same answer here, and the operation declares
%                               no probe list, so indistinguishability is
%                               untested and may not be claimed
%   agrees_everywhere_tested -- same answer here, and the declared battery
%                               holds no input where the two differ
pusu_recovery_relation(Op, Left, Right, Kind, RunOutput, RecoveredKind, Relation) :-
    pusu_named_rule_output(Op, RecoveredKind, Left, Right, RecoveredOutput),
    ( \+ pusu_value_output(RecoveredOutput)
    -> Relation = incomparable_at_input
    ; RecoveredOutput \=@= RunOutput
    -> Relation = disagrees_at_input
    ; \+ pusu_battery_for(Op, _)
    -> Relation = no_battery
    ; pusu_diagnosis_separator(Op, Kind, RecoveredKind, SeparatorLeft, SeparatorRight)
    -> Relation = separates_on_battery(SeparatorLeft-SeparatorRight)
    ;  Relation = agrees_everywhere_tested
    ).

pusu_recovery_relations(Op, Left, Right, Kind, Detail, Relations) :-
    pusu_named_rule_output(Op, Kind, Left, Right, RunOutput),
    pusu_value_output(RunOutput),
    findall(Relation,
            ( member(RecoveredKind, Detail),
              pusu_recovery_relation(Op, Left, Right, Kind, RunOutput, RecoveredKind, Relation) ),
            Relations),
    % Every recovered name has to be assessed.  A name the relation predicate
    % could not classify would otherwise drop out of the list and let the
    % conjunction below read as unanimous when it is merely short.
    length(Detail, Assessed), length(Relations, Assessed).

% The reach of an equivalence claim, measured rather than asserted: the
% battery inputs where both kinds produced a value, out of the whole
% declared battery.  Where no separator exists those inputs are exactly the
% inputs where the two agreed.  A small count is not a defect; it is the
% honest extent of what the battery could test, and it travels with the
% claim so a reader can weigh it.
pusu_agreement_extent(Op, Kind, RecoveredKind, Compared, BatterySize) :-
    pusu_battery_for(Op, Battery),
    length(Battery, BatterySize),
    findall(Left-Right,
            ( member(Left-Right, Battery),
              pusu_named_rule_output(Op, Kind, Left, Right, RunOutput),
              pusu_named_rule_output(Op, RecoveredKind, Left, Right, RecoveredOutput),
              pusu_value_output(RunOutput), pusu_value_output(RecoveredOutput) ),
            Compared0),
    length(Compared0, Compared).

pusu_agreement_region(Op, Left, Right, Kind, Detail, RegionText) :-
    ( pusu_text_input(Op, Left, Right, Queried) -> true ; Queried = operands(Op, Left, Right) ),
    findall(equivalent_on_battery(RecoveredKind, compared(Compared), battery(BatterySize)),
            ( member(RecoveredKind, Detail),
              pusu_agreement_extent(Op, Kind, RecoveredKind, Compared, BatterySize) ),
            Extents),
    pusu_text(diagnosis_agreement_region(queried(Queried), run_kind(Kind), Extents), RegionText).

% A recovery that disagrees with the run kind somewhere the battery can see
% keeps the ambiguity upgrade.  A recovery set the battery cannot tell apart
% from the run kind anywhere names a behaviour the battery cannot separate,
% which is not the same as naming the wrong error: the row carries its
% measured agreement region and stops vetoing the lesson.  A disagreement at
% the input, an unrunnable kind, or an operation with no declared battery
% all leave the wrong-error verdict standing.
pusu_upgrade_diagnosis(Op, Left, Right, Kind, "recovered_different_error", Detail,
                       Status, Detail, SeparatorText, ContextText) :-
    Detail \== [],
    pusu_recovery_relations(Op, Left, Right, Kind, Detail, Relations),
    ( member(separates_on_battery(SeparatorLeft-SeparatorRight), Relations)
    -> Status = "diagnosis_ambiguous_at_input", ContextText = "",
       pusu_input_text(Op, SeparatorLeft, SeparatorRight, SeparatorText)
    ; forall(member(Relation, Relations), Relation == agrees_everywhere_tested)
    -> Status = "diagnosis_names_equivalent_error", SeparatorText = "",
       pusu_agreement_region(Op, Left, Right, Kind, Detail, ContextText)
    ), !.
pusu_upgrade_diagnosis(_, _, _, _, Status, Detail, Status, Detail, "", "").

% A registered misconception rule that the trace classifier itself just
% executed is a completed engine diagnosis even when the public inverse index
% has not yet named it.  This is deliberately limited to rule contrasts; it
% does not promote an action-route failure into a recovered diagnosis.
pusu_complete_rule_diagnosis("no_diagnosis", Kind, _, _, "classified_by_rule", [Kind],
                            "classify_arith_by_trace") :- !.
pusu_complete_rule_diagnosis(Status, _, Detail, Surface, Status, Detail, Surface).

pusu_action_contrast(Code, Family, Task, Row) :-
    activity_contract:task_action_operands(Task, Op, Left, Right),
    Goal = activity_contract:deformation_task_path(Code, Family, Task, Outcome),
    pusu_goal_text(Goal, GoalText), pusu_text(Task, TaskText),
    pusu_call(contrast_diagnosis, Goal, CallResult),
    ( CallResult == succeeded, pusu_result(Outcome, Wrong),
      get_dict(deformation_kind, Outcome, Kind)
    -> pusu_text(Wrong, WrongText),
       ( pusu_run_productive(Code, Task, Productive, _, ProductiveTimedOut, _),
         pusu_result(Productive, Correct), Wrong =@= Correct
       -> ( action_automata_registry:action_automaton_pair(Op, ProductiveKind, Kind, _)
          -> pusu_agreement_status_action(Family, Op, Kind, ProductiveKind, Left, Right,
                                          ContrastStatus, ContextText, SeparatorText, TraceRoundTrip)
          ;  ContrastStatus = "attachment_unresolved", ContextText = "", SeparatorText = "", TraceRoundTrip = false ),
          pusu_viability_field(ContrastStatus, Code, Family, ContextText, SeparatorText, Viability),
          Diagnosis = "not_applicable", Detail = [], Surface = "none",
          TimedOut = ProductiveTimedOut, Failure = ""
       ;  ContrastStatus = "separates",
          pusu_diagnosis_with_budget(Op, Left, Right, Wrong, Kind, Diagnosis0, Detail0, Surface0, TimedOut, Failure),
          pusu_upgrade_diagnosis(Op, Left, Right, Kind, Diagnosis0, Detail0, Diagnosis, Detail,
                                 SeparatorText, ContextText),
          Surface = Surface0, TraceRoundTrip = false, Viability = []
       )
    ;  Kind = Family, WrongText = "", ContrastStatus = "cannot_run",
       Diagnosis = "not_applicable", Detail = [], Surface = "none",
       ( CallResult == timed_out -> TimedOut = true ; TimedOut = false ),
       pusu_failure(CallResult, Failure), ContextText = "", SeparatorText = "", TraceRoundTrip = false, Viability = []
    ),
    pusu_text(Kind, KindText),
    Row = _{kind:KindText, family:Family, task:TaskText, source:"compiled_deformation_task",
            status:ContrastStatus, wrong_answer:WrongText, diagnosis:Diagnosis,
            diagnosis_detail:Detail, diagnosis_surface:Surface, goal:GoalText,
            timed_out:TimedOut, failure:Failure, agreement_context:ContextText,
            separating_input:SeparatorText, trace_round_trip:TraceRoundTrip, viability:Viability,
            norm_citation:""}.

pusu_contrast_relation(arithmetic_value_agreement, Productive, Kind,
                       distinct_automata, ProductiveKind) :-
    pusu_division_productive_kind(Productive, ProductiveKind),
    action_automata_registry:action_automaton_signature(
        division, Kind, _, _),
    ProductiveKind \== Kind, !.
pusu_contrast_relation(arithmetic_value_agreement, Productive, Kind,
                       same_automaton, Kind) :-
    pusu_division_productive_kind(Productive, Kind),
    action_automata_registry:action_automaton_signature(
        division, Kind, _, _), !.
pusu_contrast_relation(arithmetic_value_agreement, Productive, Kind,
                       distinct_rule_and_automaton, ProductiveKind) :-
    pusu_division_productive_kind(Productive, ProductiveKind),
    \+ action_automata_registry:action_automaton_signature(
           division, Kind, _, _), !.
pusu_contrast_relation(_, _, _, not_compared, not_available).

pusu_rule_contrast(Code, Obligation, Task, Row) :-
    Op = Obligation.operation, Kind = Obligation.kind,
    activity_contract:task_action_operands(Task, Op, Left, Right),
    pusu_operation_domain(Op, Domain), pusu_rule_input(Kind, Left, Right, Input),
    test_harness:arith_misconception(_, Domain, Kind, Rule, _, _),
    pusu_run_productive(Code, Task, Productive, _, ProductiveTimedOut, _), pusu_result(Productive, Expected),
    ( Op == division
    -> ( pusu_division_productive_schema(Productive, Expected, ProductiveSchema)
       -> true
       ;  ProductiveSchema = untranslatable_productive_schema )
    ;  ProductiveSchema = not_applicable ),
    Goal = test_harness:classify_arith_by_trace(Rule, Input, Expected, Class, Evidence),
    pusu_goal_text(Goal, GoalText), pusu_text(Task, TaskText), pusu_text(Kind, KindText),
    pusu_call(contrast_diagnosis, Goal, CallResult),
    ( CallResult == succeeded
    -> pusu_rule_comparison_status(
           Op, Kind, Rule, Left, Right, ProductiveSchema, Expected, Evidence,
           Class, RuleStatus, ComparisonRelation),
       ( RuleStatus == separates
       -> pusu_text(Evidence, WrongText), ContrastStatus = "separates",
          pusu_text(Expected, ExpectedText),
          pusu_diagnosis_with_budget(Op, Left, Right, Evidence, Kind, Diagnosis0, Detail0, Surface0, DiagnosisTimedOut, Failure),
          pusu_upgrade_diagnosis(Op, Left, Right, Kind, Diagnosis0, Detail0, Diagnosis1, Detail1,
                                 SeparatorText, ContextText),
          pusu_complete_rule_diagnosis(Diagnosis1, Kind, Detail1, Surface0, Diagnosis, Detail, Surface),
          TraceRoundTrip = false, Viability = [], BatteryRefusals = [],
          pusu_contrast_relation(
              ComparisonRelation, Productive, Kind, ContrastRelation,
              ProductiveKind),
          ( ( ProductiveTimedOut == true ; DiagnosisTimedOut == true ) -> TimedOut = true ; TimedOut = false )
       ;  pusu_text(Evidence, WrongText), pusu_text(Expected, ExpectedText),
          ( RuleStatus == agrees
          -> pusu_agreement_status_rule(Kind, Op, Rule, ContrastStatus, ContextText,
                                        SeparatorText, BatteryRefusals),
             pusu_viability_field(ContrastStatus, Code, Kind, ContextText, SeparatorText, Viability)
          ;  ContrastStatus = RuleStatus, ContextText = "", SeparatorText = "",
             Viability = [], BatteryRefusals = []
          ),
          pusu_contrast_relation(
              ComparisonRelation, Productive, Kind, ContrastRelation,
              ProductiveKind),
          Diagnosis = "not_applicable", Detail = [], Surface = "none", TimedOut = ProductiveTimedOut,
          Failure = "", TraceRoundTrip = false
       )
    ;  WrongText = "", ExpectedText = "",
       Class = not_available,
       ComparisonRelation = not_available,
       ContrastRelation = not_compared, ProductiveKind = not_available,
       ContrastStatus = "cannot_run", Diagnosis = "not_applicable",
       Detail = [], Surface = "none",
       ( ( CallResult == timed_out ; ProductiveTimedOut == true ) -> TimedOut = true ; TimedOut = false ),
       pusu_failure(CallResult, Failure), ContextText = "", SeparatorText = "",
       TraceRoundTrip = false, Viability = [], BatteryRefusals = []
    ),
    Row = _{kind:KindText, family:KindText, task:TaskText, operation:Op,
            source:"registered_misconception_rule", status:ContrastStatus,
            wrong_answer:WrongText, expected_answer:ExpectedText,
            diagnosis:Diagnosis, diagnosis_detail:Detail,
            diagnosis_surface:Surface, goal:GoalText,
            timed_out:TimedOut, failure:Failure, agreement_context:ContextText,
            separating_input:SeparatorText, trace_round_trip:TraceRoundTrip, viability:Viability,
            battery_refusals:BatteryRefusals,
            trace_class:Class,
            value_relation:ComparisonRelation,
            contrast_relation:ContrastRelation,
            productive_kind:ProductiveKind, norm_citation:""}.

pusu_receipt_contrast(Code, Op, AltKind, Family, Task, Row) :-
    compiled_receipt_routes:receipt_contrast_route(Code, Op, AltKind, Family, Task, Evidence),
    activity_contract:task_action_operands(Task, Op, Left, Right),
    Goal = action_automata_registry:run_action_automaton(Op, AltKind, Left, Right, Outcome, _),
    pusu_goal_text(Goal, GoalText), pusu_text(Task, TaskText), pusu_text(AltKind, KindText),
    pusu_call(contrast_diagnosis, Goal, CallResult),
    ( CallResult == succeeded, pusu_result(Outcome, Wrong)
    -> pusu_text(Wrong, WrongText),
       ( pusu_run_productive(Code, Task, Productive, _, ProductiveTimedOut, _),
         pusu_result(Productive, Correct), Wrong =@= Correct
       -> ( Evidence = receipt_evidence(intended(Op, ProductiveKind), _, _, _)
          -> pusu_agreement_status_action(Family, Op, AltKind, ProductiveKind, Left, Right,
                                          ContrastStatus, ContextText, SeparatorText, TraceRoundTrip)
          ;  ContrastStatus = "attachment_unresolved", ContextText = "", SeparatorText = "", TraceRoundTrip = false ),
          pusu_viability_field(ContrastStatus, Code, Family, ContextText, SeparatorText, Viability),
          Diagnosis = "not_applicable", Detail = [], Surface = "none", TimedOut = ProductiveTimedOut, Failure = ""
       ;  ContrastStatus = "separates",
          pusu_diagnosis_with_budget(Op, Left, Right, Wrong, AltKind, Diagnosis0, Detail0, Surface0, TimedOut, Failure),
          pusu_upgrade_diagnosis(Op, Left, Right, AltKind, Diagnosis0, Detail0, Diagnosis, Detail,
                                 SeparatorText, ContextText),
          Surface = Surface0, TraceRoundTrip = false, Viability = []
       )
    ;  WrongText = "", ContrastStatus = "cannot_run", Diagnosis = "not_applicable",
       Detail = [], Surface = "none",
       ( CallResult == timed_out -> TimedOut = true ; TimedOut = false ),
       pusu_failure(CallResult, Failure), ContextText = "", SeparatorText = "", TraceRoundTrip = false, Viability = []
    ),
    pusu_norm_citation(ContrastStatus, Evidence, NormCitation),
    Row = _{kind:KindText, family:Family, task:TaskText, source:"receipt_contrast_route",
            status:ContrastStatus, wrong_answer:WrongText, diagnosis:Diagnosis,
            diagnosis_detail:Detail, diagnosis_surface:Surface, goal:GoalText,
            timed_out:TimedOut, failure:Failure, agreement_context:ContextText,
            separating_input:SeparatorText, trace_round_trip:TraceRoundTrip, viability:Viability,
            norm_citation:NormCitation}.

pusu_defect_attempt(Op, AltKind, Left-Right, Status) :-
    Goal = action_automata_registry:run_action_automaton(Op, AltKind, Left, Right, _, _),
    pusu_call(contrast_diagnosis, Goal, Result),
    ( Result == succeeded -> Status = "automaton_runs_operands"
    ; Result == timed_out -> Status = "automaton_times_out_operands"
    ; Result = failed(_) -> Status = "automaton_errors_operands"
    ; Status = "automaton_refuses_operands" ).

pusu_defect_render(Op, AltKind, automaton_refuses_operands(Operands), TypedReason) :-
    findall(operand_status(Operand, Status),
            ( member(Operand, Operands), pusu_defect_attempt(Op, AltKind, Operand, Status) ),
            Attempts),
    pusu_text(automaton_operand_statuses(Attempts), TypedReason), !.
pusu_defect_render(_, _, Reason, TypedReason) :- pusu_text(Reason, TypedReason).

pusu_receipt_defect(Code, Row) :-
    compiled_receipt_routes:receipt_route_defect(Code, Op, ProductiveKind, AltKind, Reason),
    pusu_text(AltKind, KindText), pusu_defect_render(Op, AltKind, Reason, ReasonText),
    Row = _{kind:KindText, family:AltKind, task:"", source:"receipt_route_defect",
            status:"cannot_run", wrong_answer:"", diagnosis:"not_applicable",
            diagnosis_detail:[], diagnosis_surface:"none", goal:"", timed_out:false, failure:"",
            operation:Op, productive_kind:ProductiveKind, route_defect:ReasonText,
            agreement_context:"", separating_input:"", trace_round_trip:false, viability:[], norm_citation:""}.

pusu_contract_obligations(Code, Obligations, TimedOut, Failure) :-
    pusu_contract_memo(Code, Obligations, TimedOut-Failure), !.
pusu_contract_obligations(Code, Obligations, TimedOut, Failure) :-
    Goal = lesson_activity_contract(Code, Contract),
    pusu_call(contract_lookup, Goal, Result),
    ( Result == succeeded
    -> Obligations = Contract.misconception_obligations, TimedOut = false, Failure = ""
    ;  Obligations = [], ( Result == timed_out -> TimedOut = true ; TimedOut = false ),
       pusu_failure(Result, Failure)
    ),
    asserta(pusu_contract_memo(Code, Obligations, TimedOut-Failure)).

pusu_contract_timeout_row(Row) :-
    Row = _{kind:"lesson_activity_contract", family:"lesson_activity_contract",
            task:"", source:"lesson_activity_contract", status:"cannot_run",
            wrong_answer:"", diagnosis:"not_applicable", diagnosis_detail:[],
            diagnosis_surface:"timeout", goal:"lesson_activity_contract/2",
            timed_out:true, failure:""}.

pusu_contract_failure_row(Failure, Row) :-
    Row = _{kind:"lesson_activity_contract", family:"lesson_activity_contract",
            task:"", source:"lesson_activity_contract", status:"cannot_run",
            wrong_answer:"", diagnosis:"not_applicable", diagnosis_detail:[],
            diagnosis_surface:"none", goal:"lesson_activity_contract/2",
            timed_out:false, failure:Failure}.

pusu_contrasts(Code, Rows) :-
    findall(Row,
            ( compiled_task_instances:compiled_lesson_task_instance(Code, deformation(Family)-Task, _),
              pusu_action_contrast(Code, Family, Task, Row) ), ActionRows),
    pusu_contract_obligations(Code, Obligations, ContractTimedOut, ContractFailure),
    findall(Row,
            ( member(Obligation, Obligations),
              Op = Obligation.operation,
              compiled_task_instances:compiled_lesson_task_instance(Code, productive-Task, _),
              pusu_rule_contrast(Code, Obligation, Task, Row) ), RuleRows),
    findall(Row,
            pusu_receipt_contrast(Code, _, _, _, _, Row), ReceiptRows),
    findall(Row, pusu_receipt_defect(Code, Row), ReceiptDefectRows),
    ( ContractTimedOut == true -> pusu_contract_timeout_row(ContractTimeoutRow), ContractTimeoutRows = [ContractTimeoutRow] ; ContractTimeoutRows = [] ),
    ( ContractFailure \== "" -> pusu_contract_failure_row(ContractFailure, ContractFailureRow), ContractFailureRows = [ContractFailureRow] ; ContractFailureRows = [] ),
    append([ActionRows, RuleRows, ReceiptRows, ReceiptDefectRows, ContractTimeoutRows, ContractFailureRows], All), sort(All, Rows).

pusu_unseparated_rule_refusal(Contrasts, Status) :-
    member(Row, Contrasts),
    Row.source == "registered_misconception_rule",
    Row.status == Status,
    Kind = Row.kind,
    \+ ( member(Other, Contrasts),
         Other.source == "registered_misconception_rule",
         Other.kind == Kind,
         Other.status == "separates"
       ).

pusu_verdict(Productive, Contrasts, Verdict, Detail) :-
    ( Productive = []
    -> Verdict = "broken(no_instances)", Detail = "no compiled productive task instance"
    ; member(Row, Productive), Row.status == "cannot_run"
    -> Verdict = "broken(execute_mismatch)", Detail = "a productive task did not execute"
    ; Contrasts = []
    -> Verdict = "broken(contrast_cannot_run)", Detail = "no attached executable contrast route"
    ; member(Row, Contrasts), Row.status == "cannot_run"
    -> Verdict = "broken(contrast_cannot_run)", Detail = "an attached contrast could not run"
    ; member(Row, Contrasts), Row.status == "battery_absent"
    -> Verdict = "broken(battery_absent)", Detail = "an agreeing contrast has no declared operation battery"
    ; member(Row, Contrasts), memberchk(Row.status,
                                        [rule_defect_no_output, rule_times_out, rule_errors,
                                         action_no_output, action_times_out, action_errors])
    -> Verdict = "broken(contrast_cannot_run)", Detail = "an attached contrast route did not produce an executable output"
    ; pusu_unseparated_rule_refusal(Contrasts, rule_domain_refusal)
    -> Verdict = "rule_domain_refusal", Detail = "the lesson's numerals are outside the rule automaton's declared domain"
    ; pusu_unseparated_rule_refusal(Contrasts, rule_no_form_at_input)
    -> Verdict = "needs_rule_exercising_numerals", Detail = "the lesson's numerals do not exercise this misconception"
    ; pusu_unseparated_rule_refusal(Contrasts, rule_refusal_reason_unavailable)
    -> Verdict = "rule_refusal_reason_unavailable", Detail = "the available declarations and automaton evidence cannot distinguish this rule refusal"
    ; member(Row, Contrasts),
      Row.status == "cannot_separate_at_value_layer"
    -> Verdict = "cannot_separate_at_value_layer",
       Detail = "a registered rule agrees throughout its domain, so the arithmetic-value layer cannot separate this contrast"
    ; member(Row, Contrasts), Row.status == "vacuous_pair"
    -> Verdict = "broken(vacuous_pair)", Detail = "a contrast has no separating battery input"
    ; member(Row, Contrasts), Row.status == "normative_contrast", Row.trace_round_trip \== true
    -> Verdict = "broken(normative_trace_unverified)", Detail = "a correct-but-inefficient contrast lacks a distinct classified trace"
    % Diagnosis defects take precedence over an independent context failure:
    % changing numerals cannot repair a wrong recovered kind or absent recovery.
    ; member(Row, Contrasts), Row.diagnosis == "no_diagnosis"
    -> Verdict = "broken(diagnosis_missed)", Detail = "a wrong contrast answer was not recovered"
    ; member(Row, Contrasts), Row.diagnosis == "recovered_different_error"
    -> Verdict = "broken(diagnosis_wrong_error)", Detail = "a wrong contrast answer recovered another error"
    ; member(Row, Contrasts), Row.status == "attachment_unresolved"
    -> Verdict = "broken(contrast_attachment_missing)", Detail = "an agreeing contrast has no identified registry pair or intended receipt route"
    ; member(Row, Contrasts), Row.status == "context_unvalidated"
    -> Verdict = "needs_separating_numerals", Detail = "a separating input exists but its authored agreement context did not validate"
    ; Verdict = "pass", Detail = "all compiled productive and contrast routes separated, validated a viable agreement context, or completed a normative trace round-trip"
    ).

% A receipt whose route cannot bind stays on the books and stays in the
% artifact: the receipt-executability ruling keeps defect facts visible with
% the failed warrant named.  It is not, however, a live claim about the
% lesson, and a superseded defect cannot speak for routes that run and
% separate.  The verdict follows the active routes.  A lesson whose only
% receipt is defective has nothing live to follow and keeps its cannot_run
% verdict.
pusu_route_defect_row(Row) :- get_dict(source, Row, "receipt_route_defect").

pusu_active_verdict(Productive, Contrasts, Verdict, Detail) :-
    exclude(pusu_route_defect_row, Contrasts, Active),
    ( Active == []
    -> pusu_verdict(Productive, Contrasts, Verdict, Detail)
    ;  pusu_verdict(Productive, Active, Verdict, Detail)
    ).

pusu_lesson(Code, Row) :-
    findall(Productive, pusu_productive(Code, Productive), ProductiveRows),
    pusu_contrasts(Code, ContrastRows),
    pusu_active_verdict(ProductiveRows, ContrastRows, Verdict, Detail),
    Row = _{lesson:Code, pusu:Verdict, detail:Detail,
            productive:ProductiveRows, contrasts:ContrastRows}.

pusu_main([]).
pusu_main([Code|Rest]) :-
    pusu_lesson(Code, Row), write('PUSU\t'), json_write_dict(current_output, Row, [width(1000000)]), nl,
    flush_output, pusu_main(Rest).
'''


def diagnostic_ready_lessons() -> list[str]:
    ledger = json.loads(LEDGER.read_text(encoding="utf-8"))
    return [row["lesson"] for row in ledger["lessons"] if row["readiness"] == "diagnostic_ready"]


def prolog_list(lessons: list[str]) -> str:
    return "[" + ",".join(repr(lesson).replace('"', "'") for lesson in lessons) + "]"


def run_engine(
    lessons: list[str], productive_budget: int | None = None, batteries: bool = True
) -> list[dict]:
    runner = PROLOG_RUNNER
    if productive_budget is not None:
        runner = runner.replace(
            "pusu_budget_seconds(productive_execution, 60).",
            f"pusu_budget_seconds(productive_execution, {productive_budget}).",
            1,
        )
    if not batteries:
        runner = runner.replace("pusu_batteries_enabled.", "% benchmark: batteries disabled", 1)
    program = runner + "\n:- pusu_main(" + prolog_list(lessons) + "), halt.\n"
    # The whole-invocation ceiling scales with the batch: a heavy lesson's
    # tasks may legitimately spend many minutes inside the per-stage budgets
    # (the 2026-07-29 sweep measured single G4 lessons past twenty minutes),
    # so a flat ceiling misreads honest work as a hang.  Thirty minutes per
    # lesson holds a floor of twenty for tiny batches.
    proc = subprocess.run(
        ["swipl", "-q", "-l", str(ROOT / "paths.pl"), "-g", "consult(user),halt"],
        cwd=ROOT,
        input=program,
        text=True,
        capture_output=True,
        check=False,
        timeout=max(20 * 60, 30 * 60 * len(lessons)),
    )
    if proc.returncode:
        raise RuntimeError(f"SWI-Prolog failed ({proc.returncode}):\n{proc.stderr.strip()}")
    rows = []
    for line in proc.stdout.splitlines():
        if line.startswith("PUSU\t"):
            try:
                rows.append(json.loads(line.split("\t", 1)[1]))
            except json.JSONDecodeError as exc:
                raise RuntimeError(f"invalid engine JSON: {line}") from exc
    if len(rows) != len(lessons):
        raise RuntimeError(
            f"SWI-Prolog returned {len(rows)} rows for {len(lessons)} lessons.\n{proc.stderr.strip()}"
        )
    return rows


def run_refusal_fixtures() -> list[dict]:
    program = PROLOG_RUNNER + "\n:- pusu_refusal_fixture_main, halt.\n"
    proc = subprocess.run(
        ["swipl", "-q", "-l", str(ROOT / "paths.pl"), "-g", "consult(user),halt"],
        cwd=ROOT,
        input=program,
        text=True,
        capture_output=True,
        check=False,
        timeout=5 * 60,
    )
    if proc.returncode:
        raise RuntimeError(f"SWI-Prolog failed ({proc.returncode}):\n{proc.stderr.strip()}")
    rows = [
        json.loads(line.split("\t", 1)[1])
        for line in proc.stdout.splitlines()
        if line.startswith("FIXTURE\t")
    ]
    if len(rows) != 5:
        raise RuntimeError(
            f"SWI-Prolog returned {len(rows)} refusal fixtures.\n{proc.stderr.strip()}"
        )
    return rows


def stage(verdict: str) -> str:
    if verdict == "pass":
        return "pass"
    return verdict.removeprefix("broken(").removesuffix(")")


def compact_prolog(rows: list[dict]) -> str:
    lines = ["% Generated by scripts/curriculum/pusu_pass.py; do not edit.",
             ":- module(pusu_pass, [pusu/2, pusu_viability/4]).", ""]
    viability_seen: set[tuple[str, str, str, str]] = set()
    for row in rows:
        lesson = row["lesson"].replace("'", "\\'")
        verdict = row["pusu"]
        if verdict == "pass":
            term = "pass"
        elif verdict in {
            "needs_separating_numerals",
            "needs_rule_exercising_numerals",
            "rule_domain_refusal",
            "rule_refusal_reason_unavailable",
            "cannot_separate_at_value_layer",
        }:
            term = verdict + "(" + repr(row["detail"]).replace('"', "'") + ")"
        else:
            term = "broken(" + stage(verdict) + ", " + repr(row["detail"]).replace('"', "'") + ")"
        lines.append(f"pusu('{lesson}', {term}).")
        for contrast in row["contrasts"]:
            for fact in contrast.get("viability", []):
                family = str(fact["family"]).replace("'", "\\'")
                context = str(fact["context"]).replace("'", "\\'")
                witness = fact["separation_witness"]
                witness_kind = str(witness["kind"])
                if witness_kind == "found":
                    separator = str(witness["input"]).replace("'", "\\'")
                    witness_term = f"found('{separator}')"
                elif witness_kind == "cannot_separate_at_value_layer":
                    reason = str(witness["reason"]).replace("'", "\\'")
                    witness_term = (
                        "cannot_separate_at_value_layer("
                        f"'{reason}')"
                    )
                else:
                    raise ValueError(
                        f"unknown viability witness kind: {witness_kind}"
                    )
                key = (lesson, family, context, witness_term)
                if key in viability_seen:
                    continue
                viability_seen.add(key)
                lines.append(
                    f"pusu_viability('{lesson}', '{family}', "
                    f"o(context({context})), {witness_term})."
                )
    return "\n".join(lines) + "\n"


def previous_verdicts() -> dict[str, str]:
    if not OUTPUT.exists():
        return {}
    try:
        document = json.loads(OUTPUT.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return {}
    return {row["lesson"]: row["pusu"] for row in document.get("rows", [])}


def payload(rows: list[dict], selected: list[str], before: dict[str, str]) -> dict:
    distribution = Counter(stage(row["pusu"]) for row in rows)
    refusal_statuses = {
        "rule_defect_no_output",
        "rule_domain_refusal",
        "rule_no_form_at_input",
        "rule_refusal_reason_unavailable",
    }
    rule_refusal_distribution = Counter(
        contrast["status"]
        for row in rows
        for contrast in row["contrasts"]
        if contrast.get("status") in refusal_statuses
    )
    rule_battery_refusal_distribution = Counter(
        refusal["status"]
        for row in rows
        for contrast in row["contrasts"]
        for refusal in contrast.get("battery_refusals", [])
    )
    division_value_agreements = [
        (row["lesson"], contrast)
        for row in rows
        for contrast in row["contrasts"]
        if contrast.get("source") == "registered_misconception_rule"
        and contrast.get("operation") == "division"
        and contrast.get("value_relation") == "arithmetic_value_agreement"
    ]
    division_value_agreement_families = Counter(
        contrast["kind"] for _, contrast in division_value_agreements
    )
    division_schema_agreement_reclassifications = [
        (lesson, contrast)
        for lesson, contrast in division_value_agreements
        if contrast.get("trace_class") == "wrong_answer"
    ]
    value_agreement_examples: dict[str, dict] = {}
    for lesson, contrast in division_value_agreements:
        value_agreement_examples.setdefault(
            contrast["kind"],
            {
                "lesson": lesson,
                "task": contrast["task"],
                "expected_answer": contrast["expected_answer"],
                "rule_answer": contrast["wrong_answer"],
                "agreement_context": contrast["agreement_context"],
                "separating_input": contrast["separating_input"],
                "contrast_relation": contrast["contrast_relation"],
            },
        )
    raw_viability_facts = [
        fact for row in rows for contrast in row["contrasts"]
        for fact in contrast.get("viability", [])
    ]
    viability_facts = list({
        (str(fact["lesson"]), str(fact["family"]), str(fact["context"]),
         json.dumps(fact["separation_witness"], sort_keys=True)): fact
        for fact in raw_viability_facts
    }.values())
    return {
        "schema": "pusu_pass_v2",
        "register": (
            "put up or shut up: engine-only execution, material contrast, and diagnosis pass; "
            "pusu_viability facts carry real o(context(...)) terms for a later incompatibility layer; "
            "diagnosis reads recovered, recovered_different_error, diagnosis_ambiguous_at_input, "
            "diagnosis_names_equivalent_error (the declared battery separates the recovered names "
            "from the run kind nowhere; agreement_context carries the measured reach), "
            "classified_by_rule, no_diagnosis, or not_applicable, and a diagnosis_surface may carry "
            "an _after_withheld(...) annotation naming labels that may not be served; the lesson "
            "verdict follows the routes that run, so receipt_route_defect rows stay in the artifact "
            "without deciding it, except where a lesson's only receipt is the defective one; "
            "rule battery refusals remain on each registered-rule row as typed input/status records; "
            "rule_domain_refusal names an input outside the registered signature and operation domain, "
            "needs_rule_exercising_numerals names an in-domain input where the same-kind automaton "
            "refuses, and rule_refusal_reason_unavailable preserves an unresolved distinction; "
            "division output schemas translate only at the arithmetic-value layer; "
            "arithmetic_value_agreement records unequal output terms with equal values; "
            "contrast_relation distinguishes two automata from a registered rule compared with "
            "an automaton; cannot_separate_at_value_layer records a structural divmod identity "
            "and cannot license a pass"
        ),
        "scope": {"diagnostic_ready_lessons": len(selected), "lessons": selected},
        "verdict_distribution": dict(sorted(distribution.items())),
        "rule_refusal_distribution": dict(sorted(rule_refusal_distribution.items())),
        "rule_battery_refusal_distribution": dict(
            sorted(rule_battery_refusal_distribution.items())
        ),
        "division_value_agreement_count": len(division_value_agreements),
        "division_schema_agreement_reclassification_count": len(
            division_schema_agreement_reclassifications
        ),
        "division_value_agreement_families": dict(
            sorted(division_value_agreement_families.items())
        ),
        "division_value_agreement_examples": [
            example for _, example in sorted(value_agreement_examples.items())
        ],
        "verdict_motion": [
            {"lesson": row["lesson"], "before": before.get(row["lesson"], "not_in_prior_artifact"), "after": row["pusu"]}
            for row in rows
        ],
        "viability_facts": viability_facts,
        "rows": rows,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--calibration", action="store_true", help="run the seven audited lessons only")
    parser.add_argument("--lesson", action="append", metavar="ID", help="run one named lesson (repeatable)")
    parser.add_argument("--first", type=int, metavar="N", help="run the first N diagnostic-ready lessons")
    parser.add_argument("--offset", type=int, default=0, metavar="N", help="skip N diagnostic-ready lessons before --first")
    parser.add_argument("--productive-budget", type=int, metavar="SECONDS", help="override the productive budget for a focused regression run")
    parser.add_argument("--without-batteries", action="store_true", help="benchmark only: suppress battery sweeps (requires --stdout)")
    parser.add_argument("--merge", action="append", metavar="JSON", help="merge prior --stdout batch documents and write artifacts")
    parser.add_argument("--refusal-fixtures", action="store_true", help="run the five engine-backed rule-refusal fixtures")
    parser.add_argument("--stdout", action="store_true", help="emit JSON without writing artifacts")
    args = parser.parse_args()
    if args.refusal_fixtures:
        if args.calibration or args.lesson or args.first or args.offset or args.productive_budget or args.without_batteries or args.merge or args.stdout:
            parser.error("--refusal-fixtures cannot be combined with sweep options")
        rows = run_refusal_fixtures()
        json.dump({"fixtures": rows}, sys.stdout, indent=2, sort_keys=True)
        sys.stdout.write("\n")
        return 0 if all(row["actual"] == row["expected"] for row in rows) else 1
    if args.merge:
        if args.calibration or args.lesson or args.first or args.offset or args.stdout or args.without_batteries or args.refusal_fixtures:
            parser.error("--merge is only for writing prior batch documents")
        started = time.monotonic()
        documents = [json.loads(Path(path).read_text(encoding="utf-8")) for path in args.merge]
        rows = [row for document in documents for row in document["rows"]]
        lessons = [lesson for document in documents for lesson in document["scope"]["lessons"]]
        before = previous_verdicts()
        for item in documents:
            for motion in item.get("verdict_motion", []):
                prior = motion.get("before", "not_in_prior_artifact")
                if prior != "not_in_prior_artifact":
                    before[motion["lesson"]] = prior
        document = payload(rows, lessons, before)
        OUTPUT.write_text(json.dumps(document, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        OUTPUT_PL.write_text(compact_prolog(rows), encoding="utf-8")
        elapsed = time.monotonic() - started
        print(f"wrote {OUTPUT.relative_to(ROOT)} ({len(rows)} lessons, {elapsed:.3f}s)")
        return 0
    if args.lesson and (args.first or args.offset):
        parser.error("--lesson and --first cannot be combined")
    if args.productive_budget is not None and args.productive_budget < 1:
        parser.error("--productive-budget must be positive")
    if args.without_batteries and not args.stdout:
        parser.error("--without-batteries is a benchmark and requires --stdout")
    lessons = args.lesson or (list(CALIBRATION) if args.calibration else diagnostic_ready_lessons())
    if args.first is not None:
        if args.first < 1:
            parser.error("--first must be positive")
        lessons = diagnostic_ready_lessons()[args.offset:args.offset + args.first]
    elif args.offset:
        parser.error("--offset requires --first")
    start = time.monotonic()
    before = previous_verdicts()
    rows = run_engine(
        lessons, productive_budget=args.productive_budget, batteries=not args.without_batteries
    )
    document = payload(rows, lessons, before)
    elapsed = time.monotonic() - start
    if args.stdout:
        json.dump(document, sys.stdout, indent=2, sort_keys=True)
        sys.stdout.write("\n")
    else:
        OUTPUT.write_text(json.dumps(document, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        OUTPUT_PL.write_text(compact_prolog(rows), encoding="utf-8")
        print(f"wrote {OUTPUT.relative_to(ROOT)} ({len(rows)} lessons, {elapsed:.3f}s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
