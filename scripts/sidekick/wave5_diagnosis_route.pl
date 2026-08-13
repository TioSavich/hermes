/** <module> Closed Wave 5 receipt-contrast verdict route
 *
 * The route executes both registered machines on one wire-genre input.  It
 * emits a verdict only when the productive machine is correct and the
 * selected machine reproduces the observed answer.  Verdict fields come from
 * that fresh execution and the authored deformation-validity ledger.
 */

:- module(wave5_diagnosis_route,
          [ receipt_contrast_verdict/6
          ]).

:- use_module(library(lists), [last/2, member/2, memberchk/2, reverse/2]).
:- use_module(library(time), [call_with_time_limit/2]).
:- use_module(strategies(math/action_automata_registry)).
:- use_module(strategies(deformation_validity)).

%! receipt_contrast_verdict(+Operation, +ProductiveKind, +ContrastKind,
%!                          +Input, +Observed, -Verdict) is semidet.
%
%  Run the pair under the three-second cap and return the engine-grounded
%  verdict.  This predicate is the receipt-contrast alternative in the closed
%  Wave 5 diagnosis grammar.
receipt_contrast_verdict(Operation, ProductiveKind, ContrastKind,
                         Input, Observed, Verdict) :-
    wire_operands(Input, A, B),
    fresh_run(Operation, ProductiveKind, A, B,
              ProductiveFields, _ProductiveTrace),
    field(ProductiveFields, validity, correct),
    field(ProductiveFields, result, ProductiveResult),
    fresh_run(Operation, ContrastKind, A, B, Fields, Trace),
    field(Fields, result, Result),
    same_answer(Observed, Result),
    verdict_status(ProductiveKind, ContrastKind, Fields, Status),
    verdict_family(Status, ContrastKind, Fields, Family),
    verdict_step(Status, Operation, ContrastKind, Fields, Trace,
                 ProductiveResult, Step),
    verdict_context(Fields, Context),
    Verdict = verdict{
        status:Status,
        misconception_family:Family,
        located_step:Step,
        viability_context:Context
    }.

wire_operands(Input, A, B) :-
    is_dict(Input),
    get_dict(a, Input, A),
    get_dict(b, Input, B).

fresh_run(Operation, Kind, A, B, Fields, Trace) :-
    call_with_time_limit(
        3,
        action_automata_registry:run_action_automaton(
            Operation, Kind, A, B, action_outcome(_, Fields), Trace)).

field(Fields, Name, Value) :-
    member(Term, Fields),
    compound(Term),
    compound_name_arguments(Term, Name, [Value]),
    !.

same_answer(Observed, Result) :-
    (   number(Observed), number(Result)
    ->  Observed =:= Result
    ;   Observed =@= Result
    ).

verdict_status(Kind, Kind, Fields, productive_trace) :-
    field(Fields, validity, correct),
    !.
verdict_status(_, _, Fields,
               candidate_deformation(human_endorsement_required)) :-
    field(Fields, validity, incorrect),
    !.
verdict_status(_, _, Fields, correct_but_inefficient) :-
    field(Fields, validity, correct_but_inefficient).

verdict_family(productive_trace, _, _, not_applicable) :- !.
verdict_family(_, ContrastKind, Fields, Family) :-
    (   field(Fields, misconception_family, Family0)
    ->  Family = Family0
    ;   Family = ContrastKind
    ).

verdict_step(productive_trace, _, _, _, Trace, _, Step) :-
    last(Trace, Step),
    !.
verdict_step(Status, Operation, Kind, _Fields, Trace, _, Step) :-
    status_mode(Status, Mode),
    reverse(Trace, ReverseTrace),
    member(Step, ReverseTrace),
    compound_name_arity(Step, LocalAction, _),
    deformation_validity:deformation_validity(
        Operation, Kind, LocalAction, _, _, Modes, _, _),
    memberchk(Mode, Modes),
    !.
verdict_step(_, _, _, Fields, Trace, Expected, Step) :-
    (   field(Fields, expected, EngineExpected)
    ->  Expected0 = EngineExpected
    ;   Expected0 = Expected
    ),
    field(Fields, result, Produced),
    last(Trace, Last),
    Step = engine_located(Last, expected(Expected0), produced(Produced)).

status_mode(candidate_deformation(human_endorsement_required),
            objective_invalid).
status_mode(correct_but_inefficient, context_sensitive_or_inefficient).

verdict_context(Fields, Context) :-
    (   field(Fields, viability_context, Context0)
    ->  Context = Context0
    ;   Context = not_emitted
    ).
