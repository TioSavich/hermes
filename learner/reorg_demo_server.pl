/** <module> reorg_demo_server — a tiny live server for the reorganization demo
 *
 * Minimal, dedicated server (separate from the heavy learner/server.pl) so a
 * skeptic can run ONE command and, in a browser, type their own fraction problem
 * and watch the engine get stuck, reorganize, build a method from primitives,
 * and re-run it. Same origin serves the page and the JSON, so there is no
 * staging layer between the page and the live Prolog engine.
 *
 * Run:  swipl -l paths.pl -l learner/reorg_demo_server.pl -g start_demo
 *       then open http://localhost:8090
 *
 * Every number you type is fed straight into reorganize/4 — there is no cache and
 * no canned answer. Change the base or the numerator and the same machinery runs
 * on a problem it has never seen.
 */

:- module(reorg_demo_server, [start_demo/0, start_demo/1]).

:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_json)).
:- use_module(library(http/http_parameters)).
:- use_module(library(http/http_cors)).
:- use_module(library(http/http_files)).
:- use_module(learner(fraction_band_ladder)).

:- set_setting(http:cors, [*]).

:- http_handler(root(.), serve_index, []).
:- http_handler(root('api/reorganize'), handle_reorganize, []).
:- http_handler(root('api/ladder'), handle_ladder, []).

%!  start_demo is det.
start_demo :- start_demo(8090).

%!  start_demo(+Port) is det.
start_demo(Port) :-
    http_server(http_dispatch, [port(Port)]),
    format("~n  Reorganization demo running:  http://localhost:~w~n~n", [Port]).

serve_index(Request) :-
    http_reply_file(learner('reorg_demo.html'), [], Request).

handle_reorganize(Request) :-
    http_parameters(Request,
                    [ domain(DomainAtom, [atom, default(fraction_splitting)]),
                      a(A, [integer, default(3)]),
                      b(B, [integer, default(8)]),
                      c(C, [integer, default(4)]),
                      d(D, [integer, default(5)]) ]),
    (   build_problem(DomainAtom, A, B, C, D, Domain, Problem),
        story_for(Domain, Problem, Story)
    ->  reply_json_dict(Story)
    ;   reply_json_dict(_{ error: true,
                           message: "Could not run that problem — check the inputs (e.g. improper fractions need the top number bigger than the bottom).",
                           domain: DomainAtom })
    ).

handle_ladder(_Request) :-
    ladder_json(J),
    reply_json_dict(J).

build_problem(fraction_splitting,     A, B, _, _, fraction_splitting,     reverse(A, B)).
build_problem(fraction_improper,      A, B, _, _, fraction_improper,      make_improper(A, B)).
build_problem(fraction_of_fraction,   A, B, C, D, fraction_of_fraction,   ff(A, B, C, D)).
build_problem(fraction_algebra,       A, B, _, _, fraction_algebra,       relate(A, B)).
