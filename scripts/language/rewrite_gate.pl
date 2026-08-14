:- encoding(utf8).
/** <module> The Prolog gate for rewrite consultations
 *
 * One JSON request per line, one JSON reply per line.  Each request carries a
 * candidate sentence; the reply says whether the deterministic reader accepts
 * it and, if so, which facts it produced.  The gate decides nothing about
 * whether a rewrite is faithful — that is the caller's arithmetic over the
 * numerals.  The gate only answers: can the reader read this.
 */

:- module(rewrite_gate, []).

:- use_module(library(http/json)).
:- use_module(library(readutil), [read_line_to_string/2]).
:- use_module('../../knowledge/strategies/abstraction/word_problem_reader_pilot.pl').

:- initialization(main, main).

main :-
    repeat,
    read_line_to_string(user_input, Line),
    (   Line == end_of_file
    ->  !
    ;   catch(handle(Line, Reply), Error, error_reply(Error, Reply)),
        json_write_dict(user_output, Reply, [width(0)]), nl,
        flush_output(user_output),
        fail
    ).

handle(Line, Reply) :-
    atom_json_dict(Line, Request, []),
    get_dict(id, Request, Id),
    get_dict(text, Request, Text),
    (   catch(word_problem_reader_pilot:word_problem_facts(Text, Facts), _, fail)
    ->  maplist(fact_text, Facts, FactStrings),
        include(is_ask, Facts, Asks),
        length(Asks, AskCount),
        length(Facts, FactCount),
        Reply = _{ok:true, id:Id, parsed:true, facts:FactStrings,
                  fact_count:FactCount, ask_count:AskCount}
    ;   Reply = _{ok:true, id:Id, parsed:false, facts:[],
                  fact_count:0, ask_count:0}
    ).

is_ask(asks(_, _)).

fact_text(Fact, Text) :-
    format(string(Text), "~q", [Fact]).

error_reply(Error, _{ok:false, error:Text}) :-
    message_to_string(Error, Text).
