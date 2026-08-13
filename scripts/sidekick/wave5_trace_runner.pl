#!/usr/bin/env swipl
:- initialization(main, main).

:- use_module(library(http/json)).
:- use_module(library(time)).

main(_) :-
    consult('paths.pl'),
    use_module(hermes(encyclopedia)),
    use_module('scripts/sidekick/wave5_pilot_route.pl'),
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
response(_, _{ok:false, outcome:"runner_failure", result_term:""}).

request_response(Request, Response) :-
    get_dict(mode, Request, "trace"),
    get_dict(machine, Request, Machine),
    get_dict(input, Request, Input),
    (   Machine == "rectangle_area_unit_iteration_composition"
    ->  composition_response(Input, Response)
    ;   Machine == "known_product_adjustment"
    ->  known_product_adjustment_response(Input, Response)
    ;   hermes_encyclopedia:strategy_trace_dict(Machine, Input, Dict),
        trace_response(Dict, Response)
    ).
request_response(Request, Response) :-
    get_dict(mode, Request, "program"),
    get_dict(program, Request, Program),
    get_dict(expected_term, Request, Expected),
    program_response(Program, Expected, Response).
request_response(Request, Response) :-
    get_dict(mode, Request, "g8_solution"),
    get_dict(module, Request, ModuleText), atom_string(Module, ModuleText),
    get_dict(doing, Request, DoingText), atom_string(Doing, DoingText),
    get_dict(input, Request, Input),
    (   wave5_pilot_route:g8_solution_result(Module, Doing, Input, Result)
    ->  text_value(Result, ResultText),
        Response = _{ok:true, available_count:1, results:[ResultText]}
    ;   Response = _{ok:true, available_count:0, results:[]}
    ).
request_response(Request, Response) :-
    get_dict(mode, Request, "g8_partner"),
    get_dict(module, Request, ModuleText), atom_string(Module, ModuleText),
    get_dict(doing, Request, DoingText), atom_string(Doing, DoingText),
    get_dict(variant, Request, VariantText), atom_string(Variant, VariantText),
    get_dict(input, Request, Input),
    findall(ResultText,
            ( wave5_pilot_route:g8_partner_result(
                  Module, Doing, Variant, Input, Result),
              text_value(Result, ResultText) ),
            Results),
    length(Results, Count),
    Response = _{ok:true, available_count:Count, results:Results}.

trace_response(Dict, Response) :-
    get_dict(ok, Dict, Ok),
    ( get_dict(validity, Dict, V0) -> text_value(V0, Validity) ; Validity = "" ),
    ( get_dict(result, Dict, R0) -> text_value(R0, Result) ; Result = "" ),
    ( get_dict(note, Dict, N0) -> text_value(N0, Note) ; Note = "" ),
    (   Ok == true, Validity == "correct"
    ->  Outcome = "correct"
    ;   sub_string(Note, _, _, _, "magnitude")
    ->  Outcome = "magnitude_refused"
    ;   Outcome = "refused_or_error"
    ),
    ( get_dict(refusal, Dict, Refusal) -> RefusalPart = _{refusal:Refusal} ; RefusalPart = _{} ),
    Response0 = _{ok:Ok, outcome:Outcome, validity:Validity,
                  result_term:Result, note:Note},
    Response = Response0.put(RefusalPart).

known_product_adjustment_response(Input, Response) :-
    get_dict(a, Input, A), get_dict(b, Input, B),
    catch(call_with_time_limit(
              5,
              action_automata_registry:run_action_automaton(
                  multiplication, known_product_adjustment, A, B,
                  Result, History)),
          Error,
          known_product_adjustment_exception(Error, Response0)),
    (   var(Response0)
    ->  hermes_encyclopedia:trace_result_dict(
            known_product_adjustment, "known_product_adjustment",
            A, B, Result, History, Dict),
        trace_response(Dict, Response)
    ;   Response = Response0
    ).

known_product_adjustment_exception(time_limit_exceeded,
        _{ok:false, outcome:"execution_limit", validity:"", result_term:"",
          note:"Strategy execution exceeded the 5 second admitted-work bound.",
          refusal:_{kind:"strategy_execution_time_bound",
                    input_kind:"known_product_adjustment",bound_seconds:5}}) :- !.
known_product_adjustment_exception(error(time_limit_exceeded, _), Response) :- !,
    known_product_adjustment_exception(time_limit_exceeded, Response).
known_product_adjustment_exception(Error, _) :- throw(Error).

composition_response(Input, Response) :-
    get_dict(rectangles, Input, [First, Second]),
    rectangle_trace(First, FirstResult),
    rectangle_trace(Second, SecondResult),
    get_dict(outcome, FirstResult, "correct"),
    get_dict(outcome, SecondResult, "correct"),
    get_dict(result_term, FirstResult, A0), area_result_number(A0, A),
    get_dict(result_term, SecondResult, B0), area_result_number(B0, B),
    compare_relation(A, B, Relation),
    Response = _{ok:true, outcome:"correct", validity:"correct",
                 result_term:Relation, note:"two verified rectangle-area traces"}.

rectangle_trace(Rectangle, Response) :-
    get_dict(length, Rectangle, Length),
    get_dict(width, Rectangle, Width),
    hermes_encyclopedia:strategy_trace_dict(
        "rectangle_area_unit_iteration", _{a:Length,b:Width}, Dict),
    trace_response(Dict, Response).

compare_relation(A, B, "less_than") :- A < B, !.
compare_relation(A, B, "greater_than") :- A > B, !.
compare_relation(_, _, "equal_to").

area_result_number(Text, Number) :-
    term_string(square_units(Number), Text), !.
area_result_number(Text, Number) :-
    number_string(Number, Text).

program_response(Program, Expected, Response) :-
    cleanup_program,
    catch(read_program(Program, Terms), Error,
          (cleanup_program, throw(Error))),
    maplist(assert_program_term, Terms),
    (   catch(once(wave5_program:solve(Answer)), Error,
              (cleanup_program, throw(Error)))
    ->  text_value(Answer, Actual),
        ( Actual == Expected -> Match = true ; Match = false ),
        Response = _{ok:true, parsed:true, ran:true, answer_match:Match,
                     result_term:Actual}
    ;   Response = _{ok:false, parsed:true, ran:false, answer_match:false,
                     result_term:""}
    ),
    cleanup_program.

read_program(Text, Terms) :-
    open_string(Text, Stream),
    read_terms(Stream, Terms),
    close(Stream).

read_terms(Stream, Terms) :-
    read_term(Stream, Term, [module(wave5_program)]),
    ( Term == end_of_file -> Terms = [] ; Terms = [Term|Rest], read_terms(Stream, Rest) ).

assert_program_term((Head :- Body)) :- !,
    assertz(wave5_program:(Head :- Body)).
assert_program_term(Fact) :-
    assertz(wave5_program:Fact).

cleanup_program :-
    forall(member(Name/Arity, [quantity/3,asks/2,solve/1]),
           catch(abolish(wave5_program:Name/Arity), _, true)).

exception_response(Error, _{ok:false, outcome:"exception", validity:"",
                            result_term:"", note:Message,
                            parsed:false, ran:false, answer_match:false}) :-
    message_to_string(Error, Message).

text_value(Value, Text) :-
    ( string(Value) -> Text = Value
    ; atom(Value) -> atom_string(Value, Text)
    ; term_string(Value, Text, [quoted(true), numbervars(true)])
    ).
