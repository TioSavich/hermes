:- encoding(utf8).
/** <module> JSONL adapter for the quarantined standards router pilot */

:- use_module(library(http/json)).
:- use_module(library(readutil)).
:- use_module('../../knowledge/strategies/abstraction/standards_router_pilot',
              [route_statement/3]).

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
    atom_string(Lesson, LessonString),
    maplist(program_term, ProgramStrings, Program),
    route_statement(Program, Lesson, Route),
    findall(Code,
            standards_router_pilot:lesson_ccss_code(Lesson, Code),
            Codes0),
    sort(Codes0, Codes),
    route_dict(Id, Codes, Route, Response).

program_term(Source, Term) :-
    term_string(Term, Source, [syntax_errors(error)]).

route_dict(Id, _ResolvedCodes,
           route(Family, Kind, InputJSON,
                 because(Codes,
                         support(total(Total), selected(Selected),
                                 genre(Genre)))),
           _{id:Id,
             status:"routed",
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
