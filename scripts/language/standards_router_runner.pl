:- encoding(utf8).
/** <module> JSONL adapter for the quarantined standards router pilot */

:- use_module(library(http/json)).
:- use_module(library(readutil)).
:- use_module('../../knowledge/strategies/abstraction/standards_router_pilot',
              [route_statement/3]).
:- use_module('../../knowledge/strategies/abstraction/table_ask_binding_pilot',
              [routed_table_completion/3]).

% The 2026-08-18 ask-binding slice interleaves route_dict/4 with the ask and
% table dict builders it feeds; the clauses are one predicate on purpose.
:- discontiguous route_dict/4.

main :-
    read_line_to_string(user_input, Line),
    (   Line == end_of_file
    ->  true
    ;   route_line(Line),
        main
    ).

route_line(Line) :-
    catch(route_line_(Line, Response), Error, error_dict(Error, Response)),
    json_write_dict(current_output, Response, [width(0)]),
    nl,
    flush_output(current_output).

route_line_(Line, Response) :-
    atom_json_dict(Line, Request, [value_string_as(string)]),
    get_dict(id, Request, Id),
    get_dict(lesson, Request, LessonString),
    get_dict(program, Request, ProgramStrings),
    request_sentences(Request, Sentences),
    atom_string(Lesson, LessonString),
    maplist(program_term, ProgramStrings, Program),
    route_statement(Program, Lesson, Route),
    findall(Code,
            standards_router_pilot:lesson_ccss_code(Lesson, Code),
            Codes0),
    sort(Codes0, Codes),
    completion_route(Route, Sentences, ReplyRoute),
    ( route_dict(Id, Codes, ReplyRoute, Response)
    -> true
    ; throw(error(unserializable_route(Route), route_line_/2))
    ).

program_term(Source, Term) :-
    term_string(Term, Source, [syntax_errors(error)]).

request_sentences(Request, Sentences) :-
    (   get_dict(sentences, Request, SentenceDicts)
    ->  maplist(sentence_term, SentenceDicts, Sentences)
    ;   Sentences = []
    ).

sentence_term(Dict, sentence(Index, Text, Form, Spans)) :-
    get_dict(index, Dict, Index),
    get_dict(text, Dict, Text),
    get_dict(form, Dict, FormString),
    get_dict(spans, Dict, Spans),
    atom_string(Form, FormString).

completion_route(Route, Sentences, ReplyRoute) :-
    (   Sentences = [_|_],
        routed_table_completion(Route, Sentences, Completion)
    ->  ReplyRoute = route_with_table_completion(Route, Completion)
    ;   ReplyRoute = Route
    ).

route_dict(Id, ResolvedCodes,
           route_with_table_completion(
               route(Family, Kind, InputJSON,
                     because(table_reading(TableId), Shape)),
               table_completion(completed, Ask, Kind, TableId, Payload)),
           Response) :-
    table_route_dict(Id, ResolvedCodes,
                     route(Family, Kind, InputJSON,
                           because(table_reading(TableId), Shape)),
                     Base),
    ask_dict(Ask, AskDict),
    atom_string(Kind, KindString),
    atom_string(TableId, TableIdString),
    term_string(Payload, PayloadText, [quoted(true),numbervars(true)]),
    term_string(run_g8_action(Kind), DerivationText,
                [quoted(true),numbervars(true)]),
    Completion = _{
        status:"completed",
        reason:"answered_by_routed_machine",
        kind:KindString,
        table_id:TableIdString,
        answers:[_{referent:TableIdString,
                   value:PayloadText,
                   derivation:DerivationText}]
    },
    put_dict(_{ask:AskDict,completion:Completion}, Base, Response).
route_dict(Id, ResolvedCodes,
           route_with_table_completion(
               route(Family, Kind, InputJSON,
                     because(table_reading(TableId), Shape)),
               table_completion(refused, Ask, Kind, TableId, Reason)),
           Response) :-
    table_route_dict(Id, ResolvedCodes,
                     route(Family, Kind, InputJSON,
                           because(table_reading(TableId), Shape)),
                     Base),
    ask_dict(Ask, AskDict),
    atom_string(Kind, KindString),
    atom_string(TableId, TableIdString),
    term_string(Reason, ReasonText, [quoted(true),numbervars(true)]),
    Completion = _{
        status:"parsed_not_completed",
        reason:ReasonText,
        kind:KindString,
        table_id:TableIdString
    },
    put_dict(_{ask:AskDict,completion:Completion}, Base, Response).

ask_dict(ask(Index, Surface, Spans),
         _{sentence_index:Index,surface:Surface,spans:Spans}).

route_dict(Id, ResolvedCodes,
           route(Family, Kind, InputJSON,
                 because(table_reading(TableId),
                         shape(columns(Columns),rows(Rows)))),
           Response) :-
    table_route_dict(
        Id, ResolvedCodes,
        route(Family, Kind, InputJSON,
              because(table_reading(TableId),
                      shape(columns(Columns),rows(Rows)))),
        Response).

table_route_dict(Id, ResolvedCodes,
                 route(Family, Kind, InputJSON,
                       because(table_reading(TableId),
                               shape(columns(Columns),rows(Rows)))),
                 _{id:Id,
                   status:"routed",
                   route_basis:"table",
                   family:FamilyString,
                   kind:KindString,
                   input_json:InputJSON,
                   input:Input,
                   codes:CodeStrings,
                   table_id:TableIdString,
                   shape:_{columns:Columns,rows:Rows}}) :-
    atom_string(Family, FamilyString),
    atom_string(Kind, KindString),
    atom_string(TableId, TableIdString),
    maplist(atom_string, ResolvedCodes, CodeStrings),
    atom_json_dict(InputJSON, Input, [value_string_as(string)]).
route_dict(Id, _ResolvedCodes,
           route(Family, Kind, InputJSON,
                 because(Codes,
                         support(total(Total), selected(Selected),
                                 genre(Genre)))),
           _{id:Id,
             status:"routed",
             route_basis:"standards",
             family:FamilyString,
             kind:KindString,
             input_json:InputJSON,
             input:Input,
             codes:CodeStrings,
             total_support:Total,
             selected_support:Selected,
             genre:GenreString}) :-
    atom_string(Family, FamilyString),
    atom_string(Kind, KindString),
    maplist(atom_string, Codes, CodeStrings),
    atom_string(Genre, GenreString),
    atom_json_dict(InputJSON, Input, [value_string_as(string)]).
route_dict(Id, ResolvedCodes,
           route(Family, Kind, InputJSON,
                 because(pattern(PatternId), witnesses(Witnesses))),
           _{id:Id,
             status:"routed",
             route_basis:"pattern",
             family:FamilyString,
             kind:KindString,
             input_json:InputJSON,
             input:Input,
             codes:CodeStrings,
             pattern:PatternString,
             witnesses:Witnesses}) :-
    atom_string(Family, FamilyString),
    atom_string(Kind, KindString),
    maplist(atom_string, ResolvedCodes, CodeStrings),
    atom_string(PatternId, PatternString),
    atom_json_dict(InputJSON, Input, [value_string_as(string)]).
route_dict(Id, Codes, abstain(Reason, Detail),
           _{id:Id,
             status:"abstain",
             reason:ReasonString,
             detail:DetailString,
             codes:CodeStrings}) :-
    maplist(atom_string, Codes, CodeStrings),
    term_string(Reason, ReasonString, [quoted(true), numbervars(true)]),
    term_string(Detail, DetailString, [quoted(true), numbervars(true)]).

error_dict(Error,
           _{id:"unknown", status:"error", error:ErrorString}) :-
    message_to_string(Error, ErrorString).
