:- module(server_visualization,
          [ handle_cgi_dispatch/1,
            handle_cgi_base/1
          ]).

/** <module> Server Visualization Endpoints
 *
 * Implements HTTP handlers supporting CGI strategy execution and base switching.
 * Exposes /api/cgi_dispatch (POST) and /api/base (GET/POST).
 */

:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_json)).
:- use_module(library(http/http_cors)).

:- use_module(math(action_automata_registry), [run_action_automaton/6]).
:- use_module(math(cgi_base), [current_cgi_base/1, set_cgi_base/1]).

% Route registrations
:- http_handler(root(api/cgi_dispatch), handle_cgi_dispatch, []).
:- http_handler(root(api/base), handle_cgi_base, []).

%!  handle_cgi_dispatch(+Request) is det.
%
%   POST /api/cgi_dispatch
%   Body: {
%       "operation": "addition" | "fraction",
%       "kind": "make_ten_split_leftover",
%       "a": 7,
%       "b": 8,
%       "d": 10 (optional, denominator for fraction operation)
%   }
%
%   Executes the requested strategy automaton and returns the outcome
%   and transition trace.
handle_cgi_dispatch(Request) :-
    cors_enable(Request, [methods([post])]),
    http_read_json_dict(Request, Input),
    
    % Safely extract parameters
    json_atom(Input.get(operation, "addition"), Op),
    json_atom(Input.kind, Kind),
    A = Input.get(a),
    B = Input.get(b),
    D = Input.get(d, null),

    (   (Op == fraction ; D \== null)
    ->  % Fraction CGI dispatch
        (   D == null -> Denom = 10 ; Denom = D),
        (   sub_atom(Kind, 0, _, _, co_denominator_)
        ->  FullKind = Kind
        ;   atom_concat(co_denominator_, Kind, FullKind)
        ),
        (   catch(run_action_automaton(fraction, FullKind, fraction_pair(A, Denom, B, Denom), unit(whole), Outcome, Trace), _, fail)
        ->  Success = true
        ;   Success = false, Outcome = null, Trace = []
        )
    ;   % Whole number CGI dispatch
        (   catch(run_action_automaton(Op, Kind, A, B, Outcome, Trace), _, fail)
        ->  Success = true
        ;   Success = false, Outcome = null, Trace = []
        )
    ),

    (   Success == true
    ->  term_to_json_dict(Outcome, JsonOutcome),
        term_to_json_dict(Trace, JsonTrace),
        reply_json_dict(_{
            success: true,
            outcome: JsonOutcome,
            trace: JsonTrace
        })
    ;   reply_json_dict(_{
            success: false,
            error: "Failed to run action automaton for the given operands"
        }, [status(400)])
    ).

%!  handle_cgi_base(+Request) is det.
%
%   GET  /api/base
%   Returns current operative base: { "base": N }
%
%   POST /api/base
%   Body: { "base": N }
%   Sets operative base: { "success": true, "base": N }
handle_cgi_base(Request) :-
    cors_enable(Request, [methods([get, post])]),
    (   Request.method == post
    ->  http_read_json_dict(Request, Input),
        Base = Input.base,
        integer(Base), Base >= 2,
        set_cgi_base(Base),
        reply_json_dict(_{success: true, base: Base})
    ;   current_cgi_base(Base),
        reply_json_dict(_{base: Base})
    ).

% ═══════════════════════════════════════════════════════════════════════
% Helper Predicates
% ═══════════════════════════════════════════════════════════════════════

%!  json_atom(+Value, -Atom) is det.
%   Convert JSON string/atom to Prolog atom.
json_atom(Value, Atom) :-
    atom(Value),
    !,
    Atom = Value.
json_atom(Value, Atom) :-
    string(Value),
    !,
    atom_string(Atom, Value).

%!  term_to_json_dict(+Term, -JsonDict) is det.
%   Recursively translate any Prolog term to a JSON-compatible dict or list structure.
term_to_json_dict(Term, Dict) :-
    var(Term), !, Dict = null.
term_to_json_dict(Term, Dict) :-
    number(Term), !, Dict = Term.
term_to_json_dict(Term, Dict) :-
    atom(Term), !, Dict = Term.
term_to_json_dict(Term, Dict) :-
    string(Term), !, Dict = Term.
term_to_json_dict(Term, Dict) :-
    is_list(Term), !,
    maplist(term_to_json_dict, Term, Dict).
term_to_json_dict(Term, Dict) :-
    compound(Term),
    Term =.. [Functor|Args],
    maplist(term_to_json_dict, Args, JsonArgs),
    term_string(Term, Str),
    Dict = _{functor: Functor, args: JsonArgs, string: Str}.
