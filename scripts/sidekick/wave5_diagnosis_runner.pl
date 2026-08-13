#!/usr/bin/env swipl
:- initialization(main, main).

:- use_module(library(http/json)).
:- use_module(library(lists), [member/2]).
:- use_module(library(time), [call_with_time_limit/2]).

main(_) :-
    consult('paths.pl'),
    use_module('scripts/sidekick/wave5_diagnosis_route.pl'),
    use_module(strategies(automaton_input_contracts)),
    use_module(strategies(deformation_validity)),
    consult('knowledge/strategies/machine_typology.pl'),
    request_loop.

request_loop :-
    catch(json_read_dict(current_input, Request), Error,
          Request = error{message:Error}),
    (   Request == end_of_file
    ->  true
    ;   is_dict(Request), get_dict(mode, Request, "stop")
    ->  true
    ;   response(Request, Response),
        json_write_dict(current_output, Response, [width(0)]), nl,
        flush_output,
        request_loop
    ).

response(Request, Response) :-
    catch(call_with_time_limit(3, request_response(Request, Response0)),
          Error, exception_response(Error, Response0)),
    !,
    Response = Response0.
response(_, _{ok:false, outcome:"runner_failure"}).

request_response(Request, Response) :-
    get_dict(mode, Request, "inventory"),
    inventory_response(Response).
request_response(Request, Response) :-
    get_dict(mode, Request, "candidate"),
    get_dict(operation, Request, OperationString),
    atom_string(Operation, OperationString),
    get_dict(productive_machine, Request, ProductiveString),
    atom_string(Productive, ProductiveString),
    get_dict(contrast_machine, Request, ContrastString),
    atom_string(Contrast, ContrastString),
    get_dict(input, Request, Input),
    candidate_response(Operation, Productive, Contrast, Input, Response).
request_response(Request, Response) :-
    get_dict(mode, Request, "program"),
    get_dict(program, Request, Program),
    get_dict(expected_verdict, Request, Expected),
    program_response(Program, Expected, Response).

inventory_response(_{ok:true, deformation_validity_rows:ValidityRows,
                     machines:Machines}) :-
    aggregate_all(count,
                  deformation_validity:deformation_validity(_,_,_,_,_,_,_,_),
                  ValidityRows),
    findall(_{operation:OperationString, machine:KindString,
              schema:Schema, static_rows:Static, observed_rows:Observed,
              invalid_steps:InvalidSteps, inefficient_steps:InefficientSteps},
            inventory_machine(OperationString, KindString, Schema,
                              Static, Observed, InvalidSteps, InefficientSteps),
            Machines0),
    sort(Machines0, Machines).

inventory_machine(OperationString, KindString, Schema, Static, Observed,
                  InvalidSteps, InefficientSteps) :-
    machine_structure(Operation, Kind, _, _, _, _, _,
                      rows(static(Static), observed(Observed))),
    automaton_input_contracts:automaton_input_contract(
        Operation, Kind, Schema, _, verified(strategy_trace_ok)),
    atom_string(Operation, OperationString),
    atom_string(Kind, KindString),
    findall(StepString,
            validity_step(Operation, Kind, objective_invalid, StepString),
            Invalid0),
    sort(Invalid0, InvalidSteps),
    findall(StepString,
            validity_step(Operation, Kind, context_sensitive_or_inefficient,
                          StepString),
            Inefficient0),
    sort(Inefficient0, InefficientSteps).

validity_step(Operation, Kind, Mode, StepString) :-
    deformation_validity:deformation_validity(
        Operation, Kind, Step, _, _, Modes, _, _),
    member(Mode, Modes),
    term_string(Step, StepString, [quoted(false)]).

candidate_response(Operation, Productive, Contrast, Input, Response) :-
    candidate_observed(Operation, Contrast, Input, Observed, Validity),
    (   wave5_diagnosis_route:receipt_contrast_verdict(
            Operation, Productive, Contrast, Input, Observed, Verdict)
    ->  term_string(Observed, ObservedString,
                    [quoted(true), numbervars(true)]),
        term_string(Verdict, VerdictString,
                    [quoted(false), numbervars(true)]),
        Response = _{ok:true, observed_answer:ObservedString,
                     validity:Validity, verdict:VerdictString}
    ;   Response = _{ok:false, outcome:"verdict_route_refused",
                     validity:Validity}
    ).

candidate_observed(Operation, Kind, Input, Observed, ValidityString) :-
    get_dict(a, Input, A),
    get_dict(b, Input, B),
    action_automata_registry:run_action_automaton(
        Operation, Kind, A, B, action_outcome(_, Fields), _),
    outcome_field(Fields, result, Observed),
    outcome_field(Fields, validity, Validity),
    term_string(Validity, ValidityString, [quoted(false)]).

outcome_field(Fields, Name, Value) :-
    member(Term, Fields),
    compound(Term),
    compound_name_arguments(Term, Name, [Value]),
    !.

program_response(Program, Expected, Response) :-
    cleanup_program,
    catch(read_program(Program, Terms, StoredVerdict), Error,
          (cleanup_program, throw(Error))),
    maplist(assert_program_term, Terms),
    (   catch(once(wave5_program:test(Verdict)), Error,
              (cleanup_program, throw(Error)))
    ->  term_string(Verdict, Actual,
                    [quoted(false), numbervars(true)]),
        term_string(StoredVerdict, Stored,
                    [quoted(false), numbervars(true)]),
        (   Actual == Expected, Stored == Expected
        ->  VerdictMatch = true
        ;   VerdictMatch = false
        ),
        Response = _{ok:true, parsed:true, ran:true,
                     verdict_match:VerdictMatch, verdict:Actual}
    ;   Response = _{ok:false, parsed:true, ran:false,
                     verdict_match:false, verdict:""}
    ),
    cleanup_program.

read_program(Text, Terms, StoredVerdict) :-
    open_string(Text, Stream),
    read_terms(Stream, Terms, StoredVerdict),
    close(Stream).

read_terms(Stream, Terms, StoredVerdict) :-
    read_term(Stream, Term, [module(wave5_program)]),
    (   Term == end_of_file
    ->  Terms = [], StoredVerdict = no_verdict
    ;   is_dict(Term, verdict)
    ->  Terms = Rest, StoredVerdict = Term,
        read_terms_without_verdict(Stream, Rest)
    ;   Terms = [Term|Rest],
        read_terms(Stream, Rest, StoredVerdict)
    ).

read_terms_without_verdict(Stream, Terms) :-
    read_term(Stream, Term, [module(wave5_program)]),
    ( Term == end_of_file -> Terms = [] ; Terms = [Term|Rest],
      read_terms_without_verdict(Stream, Rest) ).

assert_program_term((Head :- Body)) :- !,
    assertz(wave5_program:(Head :- Body)).
assert_program_term(Fact) :-
    assertz(wave5_program:Fact).

cleanup_program :-
    forall(member(Name/Arity, [quantity/3,observed_answer/1,test/1]),
           catch(abolish(wave5_program:Name/Arity), _, true)).

exception_response(Error, _{ok:false, outcome:"exception", message:Message,
                            parsed:false, ran:false, verdict_match:false}) :-
    message_to_string(Error, Message).
