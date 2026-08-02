/** <module> Line-oriented JSON front end for the prolog_query surface
 *
 * A benchmark driver holds one of these processes open instead of paying
 * the knowledge-base load once per item. Each stdin line is a JSON object
 * handed to prolog_query:prolog_query_dict/2 unchanged, so the sandbox,
 * the read-only guard, the knowledge scope guard, and the recorded limits
 * are the same ones the MCP tool enforces; nothing here widens what a goal
 * may do, only how often one may be asked.
 *
 * Run from the repository root:
 *   swipl -q -l paths.pl -l scripts/research/kb_query_server.pl \
 *         -g kb_query_server_main
 *
 * The process prints KB_QUERY_SERVER_READY once loading finishes, then one
 * JSON reply line per request line. Binding values that are not JSON-safe
 * travel as their quoted Prolog text.
 */
:- use_module(library(http/json)).

% Loaded for the caller's vocabulary, not for this file's own code: the
% misconception corpus, the probes over it, and the query surface itself.
:- use_module(misconceptions(misconception_registry), []).
:- use_module(misconceptions(query_probes)).
:- use_module(hermes(prolog_query), []).

kb_query_server_main :-
    format("KB_QUERY_SERVER_READY~n"),
    flush_output,
    serve_lines.

serve_lines :-
    read_line_to_string(user_input, Line),
    (   Line == end_of_file
    ->  halt(0)
    ;   Line == ""
    ->  serve_lines
    ;   catch(serve_one(Line), Error, emit_server_error(Error)),
        serve_lines
    ).

serve_one(Line) :-
    atom_json_dict(Line, Request, [value_string_as(string)]),
    % Capture anything a called predicate writes to stdout so the reply
    % stream stays one JSON line per request.
    with_output_to(string(Captured),
                   prolog_query:prolog_query_dict(Request, Reply0)),
    (   Captured == ""
    ->  Reply1 = Reply0
    ;   Reply1 = Reply0.put(captured_stdout, Captured)
    ),
    json_safe(Reply1, Reply),
    emit_dict(Reply).

emit_server_error(Error) :-
    term_string(Error, ErrorText),
    emit_dict(_{kind: "server_error", status: "server_error",
                error: ErrorText}).

emit_dict(Dict) :-
    atom_json_dict(Text, Dict, [as(string), width(0)]),
    format("~w~n", [Text]),
    flush_output.

%!  json_safe(+Term, -Safe) is det.
%
%   Rewrite a reply so json_write_dict can serialize it: numbers, strings,
%   and the three JSON literals pass through, atoms become strings, lists
%   and dicts are rewritten element-wise, and any remaining term travels as
%   its quoted text.
json_safe(Term, Term) :-
    (   number(Term)
    ;   string(Term)
    ;   Term == true
    ;   Term == false
    ;   Term == null
    ),
    !.
json_safe(Term, Safe) :-
    atom(Term),
    !,
    atom_string(Term, Safe).
json_safe(Term, Safe) :-
    is_list(Term),
    !,
    maplist(json_safe, Term, Safe).
json_safe(Term, Safe) :-
    is_dict(Term),
    !,
    dict_pairs(Term, Tag, Pairs),
    maplist(json_safe_pair, Pairs, SafePairs),
    dict_pairs(Safe, Tag, SafePairs).
json_safe(Term, Safe) :-
    term_string(Term, Safe,
                [quoted(true), numbervars(true), max_depth(20)]).

json_safe_pair(Key-Value, Key-Safe) :-
    json_safe(Value, Safe).
