/** <module> ORR Cycle HTTP Server

    Minimal HTTP server exposing the ORR cycle as a JSON API.
    Serves the frontend and handles computation requests.

    Usage:
        swipl server.pl
        % Server starts on http://localhost:8080
*/

:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_json)).
:- use_module(library(http/http_parameters)).
:- use_module(library(http/http_cors)).
:- use_module(library(http/html_write)).
:- use_module(library(http/http_files)).

:- use_module(execution_handler).
:- use_module(teacher).
:- use_module(arithmetic_machine).
:- use_module(event_log).
:- use_module(more_machine_learner, []).
:- use_module(strategy_synthesis, []).
:- use_module(reflective_monitor, []).
:- use_module(crisis_processor, []).
:- use_module(curriculum_processor, []).
:- use_module(knowledge_manager, []).
:- ensure_loaded(learned_knowledge_v2).
:- use_module(tension_dynamics).
:- use_module(action_semantic_context).
:- use_module(strategies(hermeneutic_calculator)).
:- use_module(strategies(visualization)).
:- use_module(math(unit_coordination_viz)).
:- use_module(render(fraction_bars_scene)).
:- use_module(server_visualization).
:- use_module(peano_utils, [int_to_peano/2, peano_to_int/2]).

% Route definitions
:- http_handler(root(api/compute), handle_compute, []).
:- http_handler(root(api/strategies), handle_strategies, []).
:- http_handler(root(api/action/topology/gaps), handle_action_topology_gaps, []).
:- http_handler(root(api/strategy/run), handle_strategy_run, []).
:- http_handler(root(api/knowledge), handle_knowledge, []).
:- http_handler(root(api/tension), handle_tension, []).
:- http_handler(root(api/reset), handle_reset, []).
:- http_handler(root(api/visualize/coordination), handle_viz_coordination, []).
:- http_handler(root(api/fraction/render), handle_fraction_render, []).
:- http_handler(root(api/fraction/arith), handle_fraction_arith, []).
:- http_handler(root(api/fraction/compare), handle_fraction_compare, []).
:- http_handler(root(bridge), serve_bridge, []).
:- http_handler(root(fractal), serve_fractal, []).
:- http_handler(root(landing), serve_landing, []).
:- http_handler(root('reorg-demo'), serve_reorg_demo, []).
:- http_handler(root(coordination), serve_coordination_page, []).
:- http_handler(root(strategies), serve_strategy_page, [prefix]).
:- http_handler(root(assets), serve_zeeman_asset, [prefix]).
:- http_handler(root(.), serve_frontend, [prefix]).

% CORS for local dev
:- set_setting(http:cors, [*]).

%!  server_port(-Port) is det.
%   Port for the arithmetic server. Defaults to 8080, but accepts
%   `--port N` or `PORT=N` so a running local server does not block testing.
server_port(Port) :-
    current_prolog_flag(argv, Argv),
    append(_, ['--port', PortAtom|_], Argv),
    atom_number(PortAtom, Port),
    !.
server_port(Port) :-
    getenv('PORT', PortAtom),
    atom_number(PortAtom, Port),
    !.
server_port(8080).

%!  start_server is det.
%   Start the HTTP server on the default port.
start_server :-
    server_port(Port),
    http_server(http_dispatch, [port(Port)]),
    format('Arithmetic Machine Explorer running at http://localhost:~w~n', [Port]).

% ═══════════════════════════════════════════════════════════════════════
% API Handlers
% ═══════════════════════════════════════════════════════════════════════

%!  handle_compute(+Request) is det.
%
%   POST /api/compute
%   Body: {"operation": "add", "a": 3, "b": 2, "limit": 20}
%   Returns: {"success": bool, "problem": {...}, "events": [...]}
%
handle_compute(Request) :-
    cors_enable(Request, [methods([post])]),
    http_read_json_dict(Request, Input),
    json_atom(Input.operation, Op),
    A = Input.a,
    B = Input.b,
    Limit = Input.get(limit, 20),
    json_atom(Input.get(mode, "direct"), Mode),

    reset_events,
    (   Mode == developmental
    ->  run_developmental_compute(Op, A, B, Limit, Success)
    ;   run_direct_compute(Op, A, B, Success)
    ),
    reply_compute_json(Success, Mode, Op, A, B, Limit).

run_developmental_compute(Op, A, B, Limit, Success) :-
    build_goal(Op, A, B, Goal),
    (   catch(
            with_output_to(string(_Stdout),
                run_computation(Goal, Limit)),
            Error,
            (   emit(computation_failed, _{goal: Goal, error: Error}),
                fail
            )
        )
    ->  Success = true
    ;   Success = false
    ).

run_direct_compute(Op, A, B, Success) :-
    Problem =.. [Op, A, B],
    emit(computation_start, _{operation: Op, a: A, b: B, mode: direct}),
    (   catch(
            arithmetic_machine:solve_arithmetic(Problem, Result, Report),
            Error,
            (   emit(computation_failed, _{problem: Problem, error: Error}),
                fail
            )
        )
    ->  emit(computation_success, _{
            result: Result,
            inferences_used: 0,
            strategy: Report.strategy,
            interpretation: Report.interpretation,
            teacher: Report.teacher,
            mode: direct
        }),
        Success = true
    ;   emit(computation_failed, _{problem: Problem, error: 'no direct strategy'}),
        Success = false
    ).

reply_compute_json(Success, Mode, Op, A, B, Limit) :-
    get_events(Events),
    maplist(event_to_dict, Events, EventDicts),
    get_learned_strategies(Knowledge),
    tension_dynamics:get_tension_state(TensionState),
    tension_dynamics:get_tension_history(TensionHistory),
    reply_json_dict(_{
        success: Success,
        mode: Mode,
        problem: _{operation: Op, a: A, b: B},
        budget: Limit,
        events: EventDicts,
        knowledge: Knowledge,
        tension: TensionState,
        tension_history: TensionHistory
    }).

json_atom(Value, Atom) :-
    atom(Value),
    !,
    Atom = Value.
json_atom(Value, Atom) :-
    string(Value),
    !,
    atom_string(Atom, Value).

%!  handle_strategies(+Request) is det.
handle_strategies(Request) :-
    cors_enable(Request, [methods([get])]),
    http_parameters(Request, [operation(OpStr, [])]),
    atom_string(Op, OpStr),
    (   teacher:available_strategies(Op, Strategies)
    ->  action_semantic_context:strategy_context_summaries(Op, Strategies, StrategyContexts),
        reply_json_dict(_{
            operation: Op,
            strategies: Strategies,
            strategy_contexts: StrategyContexts
        })
    ;   reply_json_dict(_{operation: Op, strategies: [], strategy_contexts: []})
    ).


%!  handle_action_topology_gaps(+Request) is det.
handle_action_topology_gaps(Request) :-
    cors_enable(Request, [methods([get])]),
    http_parameters(Request, [limit(Limit0, [integer, default(10)])]),
    Limit is max(0, min(Limit0, 50)),
    action_semantic_context:grounding_gap_queue(All),
    action_semantic_context:top_grounding_gaps(Limit, Gaps),
    length(All, Total),
    reply_json_dict(_{
        total: Total,
        limit: Limit,
        gaps: Gaps
    }).


%!  handle_strategy_run(+Request) is det.
%
%   POST /api/strategy/run
%   Body: {"strategy": "Chunking", "op": "+", "a": 46, "b": 37}
%   Returns: {"success": bool, "result": Int, "jumps": [...], "history": [...]}
%
%   Directly executes a named strategy via hermeneutic_calculator:calculate/6
%   without going through the ORR cycle. This is the authoritative path for
%   strategy-specific visualization.
%
%   This route never fails silently: every success:false reply carries an
%   `error` field with a teacher-legible reason naming the actual cause.
%   Results that ran on the demonstration times table (IDP division) carry
%   `kb: demo_facts` provenance so a demo-backed result is never mistaken
%   for a learned one.
handle_strategy_run(Request) :-
    cors_enable(Request, [methods([post])]),
    http_read_json_dict(Request, Input),
    atom_string(Strategy, Input.strategy),
    atom_string(Op, Input.op),
    A = Input.a,
    B = Input.b,
    strategy_action_topology(Op, Strategy, ActionTopology),
    strategy_run_outcome(Op, Strategy, A, B, Outcome),
    reply_strategy_outcome(Outcome, Op, Strategy, A, B, ActionTopology).

%!  strategy_run_outcome(+Op, +Strategy, +A, +B, -Outcome) is det.
%
%   Runs the named strategy and reports what happened. Outcome is one of:
%   - ran(Result, History): calculate/6 produced a result.
%   - refused(Status, Reason): no result; Reason is a teacher-legible
%     atom naming the actual cause, Status the HTTP status to reply with
%     (400 for a request naming no runnable strategy, 200 for a
%     well-formed request the strategy honestly could not answer).
strategy_run_outcome(Op, Strategy, A, B, Outcome) :-
    (   \+ strategy_known_for_op(Op, Strategy)
    ->  unknown_strategy_reason(Op, Strategy, Reason),
        Outcome = refused(400, Reason)
    ;   catch(hermeneutic_calculator:calculate(A, Op, B, Strategy, Result, History),
              Error,
              true)
    ->  (   nonvar(Error)
        ->  format(user_error, 'strategy_run error: ~w~n', [Error]),
            strategy_error_reason(Error, Strategy, Reason),
            Outcome = refused(200, Reason)
        ;   error_terminal_run(Result, History, Strategy, A, Op, B, Reason)
        ->  Outcome = refused(200, Reason)
        ;   Outcome = ran(Result, History)
        )
    ;   format(atom(Reason),
               'The ~w strategy did not produce a result for ~w ~w ~w. Its finite-state model does not cover these operands.',
               [Strategy, A, Op, B]),
        Outcome = refused(200, Reason)
    ).

%!  strategy_known_for_op(+Op, +Strategy) is semidet.
strategy_known_for_op(Op, Strategy) :-
    hermeneutic_calculator:list_strategies(Op, Strategies),
    memberchk(Strategy, Strategies),
    !.
% Dispatcher alias kept for older clients.
strategy_known_for_op(-, 'Sub Rounding').

%!  unknown_strategy_reason(+Op, +Strategy, -Reason) is det.
unknown_strategy_reason(Op, Strategy, Reason) :-
    (   \+ hermeneutic_calculator:list_strategies(Op, _)
    ->  format(atom(Reason),
               'No strategies are registered for operation ~w. Supported operations: +, -, *, /.',
               [Op])
    ;   renamed_strategy(Op, Strategy, NewName, Note)
    ->  available_strategies_atom(Op, AvailableAtom),
        format(atom(Reason),
               '~w Retry with strategy ~w. Strategies available for ~w: ~w.',
               [Note, NewName, Op, AvailableAtom])
    ;   available_strategies_atom(Op, AvailableAtom),
        format(atom(Reason),
               'No strategy named ~w is available for operation ~w. Available: ~w.',
               [Strategy, Op, AvailableAtom])
    ).

available_strategies_atom(Op, AvailableAtom) :-
    hermeneutic_calculator:list_strategies(Op, Available),
    atomic_list_concat(Available, ', ', AvailableAtom).

%   CBO (division) was renamed CGOB when the strategy acronyms were
%   corrected against the N101 canon; older clients may still send CBO.
renamed_strategy(/, 'CBO', 'CGOB',
    'For division this strategy is named CGOB (Conversion to Groups Other than Bases); CBO names the multiplication strategy.').

%!  error_terminal_run(+Result, +History, +Strategy, +A, +Op, +B, -Reason) is semidet.
%
%   calculate/6 can succeed with the FSM parked in its error state; the
%   dispatcher then binds Result to the atom `error`. That run is a refusal,
%   not a result, so the reply must say so instead of labeling it a success.
%   The FSM's own final message (for example 'Error: Subtrahend > Minuend.')
%   is the most teacher-legible reason available, so it rides along.
error_terminal_run(error, History, Strategy, A, Op, B, Reason) :-
    (   error_step_message(History, Message)
    ->  format(atom(Reason),
               'The ~w strategy stopped without an answer for ~w ~w ~w. ~w',
               [Strategy, A, Op, B, Message])
    ;   format(atom(Reason),
               'The ~w strategy stopped without an answer for ~w ~w ~w.',
               [Strategy, A, Op, B])
    ).

%   The last history step's final argument is the FSM's own message text.
error_step_message(History, Message) :-
    is_list(History),
    last(History, Step),
    compound(Step),
    Step =.. [step|Args],
    last(Args, Message),
    (   atom(Message)
    ->  true
    ;   string(Message)
    ),
    Message \== ''.

%!  strategy_error_reason(+Error, +Strategy, -Reason) is det.
strategy_error_reason(error(prerequisite_gap(_), context(_, Message)), _Strategy, Reason) :-
    !,
    Reason = Message.
strategy_error_reason(error(resource_error(stack), _), Strategy, Reason) :-
    !,
    format(atom(Reason),
           'The ~w strategy did not finish for these numbers: its step-by-step model kept working without reaching an answer. Try smaller operands or a different strategy for this operation.',
           [Strategy]).
strategy_error_reason(Error, Strategy, Reason) :-
    term_to_atom(Error, ErrorAtom0),
    truncate_reason_atom(ErrorAtom0, 160, ErrorAtom),
    format(atom(Reason),
           'The ~w strategy stopped with an error: ~w.',
           [Strategy, ErrorAtom]).

%   Cap the raw-term fallback so an unexpected error never dumps pages of
%   internals into the teacher-facing error field.
truncate_reason_atom(Atom, Max, Truncated) :-
    atom_length(Atom, Len),
    (   Len =< Max
    ->  Truncated = Atom
    ;   sub_atom(Atom, 0, Max, _, Prefix),
        atom_concat(Prefix, '...', Truncated)
    ).

%!  reply_strategy_outcome(+Outcome, +Op, +Strategy, +A, +B, +ActionTopology) is det.
reply_strategy_outcome(refused(Status, Reason), Op, Strategy, A, B, ActionTopology) :-
    reply_json_dict(_{
        success: false,
        strategy: Strategy,
        op: Op,
        a: A, b: B,
        error: Reason,
        action_topology: ActionTopology
    }, [status(Status)]).
reply_strategy_outcome(ran(Result, History), Op, Strategy, A, B, ActionTopology) :-
    (   is_list(History)
    ->  visualization:strategy_jumps(Strategy, History, Jumps),
        visualization:history_to_dicts(Strategy, History, HistoryDicts),
        Reply0 = _{
            success: true,
            strategy: Strategy,
            op: Op,
            a: A, b: B,
            result: Result,
            jumps: Jumps,
            history: HistoryDicts,
            action_topology: ActionTopology
        },
        (   hermeneutic_calculator:demo_kb_strategy(Op, Strategy)
        ->  put_dict(_{
                kb: demo_facts,
                kb_note: 'IDP recalls multiplication facts. This demonstration runs on a provided times table for the divisor; in the learner\'s crisis pipeline those facts must be learned before IDP will answer.'
            }, Reply0, Reply)
        ;   Reply = Reply0
        ),
        reply_json_dict(Reply)
    ;   % Dispatcher bound History to a non-list. Surface honestly
        % rather than crash.
        term_to_atom(History, HAtom),
        reply_json_dict(_{
            success: false,
            strategy: Strategy,
            op: Op,
            a: A, b: B,
            result: Result,
            jumps: [],
            history: [],
            error: 'dispatcher does not return a step history for this strategy',
            raw_history_value: HAtom,
            action_topology: ActionTopology
        })
    ).


strategy_action_topology(Op, Strategy, Context) :-
    (   action_semantic_context:strategy_action_context(Op, Strategy, Found)
    ->  Context = Found
    ;   Context = _{available: false}
    ).

%!  serve_strategy_page(+Request) is det.
%
%   GET /strategies/<name>.html — serves files from hermes/web/strategies/
%   with a <base> tag pointing at /assets/strategies/ so relative CSS loads.
serve_strategy_page(Request) :-
    cors_enable(Request, [methods([get])]),
    memberchk(path(Path), Request),
    ( Path == '/strategies' ; Path == '/strategies/' ),
    !,
    source_file(serve_bridge(_), ThisFile),
    file_directory_name(ThisFile, PrologDir),
    file_directory_name(PrologDir, RepoRoot),
    atom_concat(RepoRoot, '/hermes/web/strategies/index.html', IndexPath),
    ( exists_file(IndexPath) ->
        read_file_to_string(IndexPath, HTML, []),
        inject_strategies_base_tag(HTML, Patched),
        serve_html_string(Patched)
    ;
        reply_json_dict(_{error: 'no index.html'}, [status(404)])
    ).
serve_strategy_page(Request) :-
    cors_enable(Request, [methods([get])]),
    memberchk(path(Path), Request),
    atom_concat('/strategies/', RelPath, Path),
    \+ sub_atom(RelPath, _, _, _, '..'),
    source_file(serve_bridge(_), ThisFile),
    file_directory_name(ThisFile, PrologDir),
    file_directory_name(PrologDir, RepoRoot),
    atomic_list_concat([RepoRoot, '/hermes/web/strategies/', RelPath], FullPath),
    ( exists_file(FullPath) ->
        ( atom_concat(_, '.html', RelPath) ->
            read_file_to_string(FullPath, HTML, []),
            inject_strategies_base_tag(HTML, Patched),
            serve_html_string(Patched)
        ;
            % Non-HTML assets served directly from same folder
            asset_content_type(RelPath, CT),
            format('Content-type: ~w~n~n', [CT]),
            setup_call_cleanup(
                open(FullPath, read, In, [type(binary)]),
                copy_stream_data(In, current_output),
                close(In))
        )
    ;
        reply_json_dict(_{error: 'strategy page not found', path: RelPath},
                        [status(404)])
    ).

inject_strategies_base_tag(HTML, Patched) :-
    ( sub_string(HTML, Before, _, _, "<head>") ->
        HeadEnd is Before + 6,
        sub_string(HTML, 0, HeadEnd, _, Prefix),
        sub_string(HTML, HeadEnd, _, 0, Suffix),
        atomic_list_concat([Prefix,
            '\n<base href="/strategies/">\n', Suffix], Patched)
    ;
        Patched = HTML
    ).

%!  handle_knowledge(+Request) is det.
%
%   GET /api/knowledge
%   Returns learned strategies per operation.
%
handle_knowledge(Request) :-
    cors_enable(Request, [methods([get])]),
    get_learned_strategies(Knowledge),
    reply_json_dict(Knowledge).

%!  handle_tension(+Request) is det.
%
%   GET /api/tension
%   Returns current tension state and full history for visualization.
%   The tension history is the data that drives the More Machine bridge.
%
handle_tension(Request) :-
    cors_enable(Request, [methods([get])]),
    tension_dynamics:get_tension_state(State),
    tension_dynamics:get_tension_history(History),
    reply_json_dict(_{state: State, history: History}).

%!  handle_reset(+Request) is det.
%
%   POST /api/reset
%   Resets the machine to primordial state (forgets all learned strategies).
%   Also resets tension to zero — a full clean slate.
%
handle_reset(Request) :-
    cors_enable(Request, [methods([post])]),
    retractall(more_machine_learner:run_learned_strategy(_,_,_,_,_)),
    strategy_synthesis:reset_synthesized_strategies,
    reflective_monitor:reset_success_reflection,
    reset_events,
    tension_dynamics:reset_tension,
    reply_json_dict(_{status: reset}).

% ═══════════════════════════════════════════════════════════════════════
% Knowledge Tracking
% ═══════════════════════════════════════════════════════════════════════

get_learned_strategies(Knowledge) :-
    findall(
        _{operation: Op, learned: Learned},
        (   member(Op, [add, subtract, multiply, divide]),
            teacher:available_strategies(Op, Available),
            findall(Label, (
                member(S, Available),
                clause(more_machine_learner:run_learned_strategy(_,_,_,S,_), _),
                term_string(S, Label)
            ), TeacherBacked),
            findall(Label, (
                strategy_synthesis:synthesized_strategy(Op, _, _, _, Name, _, _),
                term_string(Name, Label)
            ), PrimitivePaths),
            append(TeacherBacked, PrimitivePaths, Learned0),
            sort(Learned0, Learned)
        ),
        Knowledge
    ).

% ═══════════════════════════════════════════════════════════════════════
% Goal Construction
% ═══════════════════════════════════════════════════════════════════════

build_goal(add, A, B, object_level:add(PA, PB, _)) :-
    int_to_peano(A, PA), int_to_peano(B, PB).
build_goal(subtract, A, B, object_level:subtract(PA, PB, _)) :-
    int_to_peano(A, PA), int_to_peano(B, PB).
build_goal(multiply, A, B, object_level:multiply(PA, PB, _)) :-
    int_to_peano(A, PA), int_to_peano(B, PB).
build_goal(divide, A, B, object_level:divide(PA, PB, _)) :-
    int_to_peano(A, PA), int_to_peano(B, PB).

% ═══════════════════════════════════════════════════════════════════════
% Event Serialization
% ═══════════════════════════════════════════════════════════════════════

event_to_dict(Event, SafeDict) :-
    dict_pairs(Event, Tag, Pairs),
    maplist(safe_pair, Pairs, SafePairs),
    dict_pairs(SafeDict, Tag, SafePairs).

safe_pair(Key-Value, Key-SafeValue) :-
    safe_value(Value, SafeValue).

safe_value(V, V) :- number(V), !.
safe_value(V, V) :- atom(V), !.
safe_value(V, V) :- string(V), !.
safe_value(V, S) :- is_dict(V), !, event_to_dict(V, S).
safe_value(V, S) :- is_list(V), !, maplist(safe_value, V, S).
safe_value(V, S) :- peano_to_int(V, S), !.
safe_value(V, S) :- term_to_atom(V, S).

% ═══════════════════════════════════════════════════════════════════════
% Frontend
% ═══════════════════════════════════════════════════════════════════════

%!  serve_bridge(+Request) is det.
%   GET /bridge — serves bridge.html with a <base> tag so relative
%   asset paths (shared.js, more-machine.js) resolve to /assets/.
serve_bridge(Request) :-
    cors_enable(Request, [methods([get])]),
    source_file(serve_bridge(_), ThisFile),
    file_directory_name(ThisFile, PrologDir),
    file_directory_name(PrologDir, RepoRoot),
    atom_concat(RepoRoot, '/hermes/web/bridge.html', BridgePath),
    (   exists_file(BridgePath)
    ->  read_file_to_string(BridgePath, HTML, []),
        inject_base_tag(HTML, Patched),
        serve_html_string(Patched)
    ;   reply_json_dict(_{error: 'bridge.html not found'}, [status(404)])
    ).

%!  serve_fractal(+Request) is det.
%   GET /fractal — serves fractal.html with base tag for asset resolution.
serve_fractal(Request) :-
    cors_enable(Request, [methods([get])]),
    source_file(serve_bridge(_), ThisFile),
    file_directory_name(ThisFile, PrologDir),
    file_directory_name(PrologDir, RepoRoot),
    atom_concat(RepoRoot, '/hermes/web/fractal.html', FractalPath),
    (   exists_file(FractalPath)
    ->  read_file_to_string(FractalPath, HTML, []),
        inject_base_tag(HTML, Patched),
        serve_html_string(Patched)
    ;   reply_json_dict(_{error: 'fractal.html not found'}, [status(404)])
    ).

%!  serve_landing(+Request) is det.
%   GET /landing — serves the unified landing page with base tag.
serve_landing(Request) :-
    cors_enable(Request, [methods([get])]),
    source_file(serve_bridge(_), ThisFile),
    file_directory_name(ThisFile, PrologDir),
    file_directory_name(PrologDir, RepoRoot),
    atom_concat(RepoRoot, '/hermes/web/landing.html', LandingPath),
    (   exists_file(LandingPath)
    ->  read_file_to_string(LandingPath, HTML, []),
        inject_base_tag(HTML, Patched),
        serve_html_string(Patched)
    ;   reply_json_dict(_{error: 'landing.html not found'}, [status(404)])
    ).

%!  serve_reorg_demo(+Request) is det.
%   GET /reorg-demo — serves the fraction reorganization demo from this server.
serve_reorg_demo(Request) :-
    cors_enable(Request, [methods([get])]),
    source_file(serve_bridge(_), ThisFile),
    file_directory_name(ThisFile, PrologDir),
    atom_concat(PrologDir, '/reorg_demo.html', ReorgDemoPath),
    (   exists_file(ReorgDemoPath)
    ->  http_reply_file(ReorgDemoPath, [], Request)
    ;   reply_json_dict(_{error: 'reorg_demo.html not found'}, [status(404)])
    ).

%!  serve_coordination_page(+Request) is det.
%   GET /coordination — serves coordination.html with base tag for asset resolution.
serve_coordination_page(Request) :-
    cors_enable(Request, [methods([get])]),
    source_file(serve_bridge(_), ThisFile),
    file_directory_name(ThisFile, PrologDir),
    file_directory_name(PrologDir, RepoRoot),
    atom_concat(RepoRoot, '/hermes/web/coordination.html', CoordinationPath),
    (   exists_file(CoordinationPath)
    ->  read_file_to_string(CoordinationPath, HTML, []),
        inject_base_tag(HTML, Patched),
        serve_html_string(Patched)
    ;   reply_json_dict(_{error: 'coordination.html not found'}, [status(404)])
    ).

%!  handle_viz_coordination(+Request) is det.
%
%   GET /api/visualize/coordination?base=B&val_up=ValUp&val_down=ValDown
%   Serves the generated SVG directly.
handle_viz_coordination(Request) :-
    cors_enable(Request, [methods([get])]),
    http_parameters(Request,
                    [ base(Base, [integer, default(10)]),
                      val_up(ValUp, [integer, default(0)]),
                      val_down(ValDownStr, [string, default("1")])
                    ]),
    parse_val_down_str(ValDownStr, ValDown),
    (   catch(
            unit_coordination_viz:generate_coordination_svg(Base, ValUp, ValDown, SVGString),
            Error,
            (   format(string(Msg), "Error: ~w", [Error]),
                SVGString = Msg
            )
        )
    ->  format('Content-type: image/svg+xml; charset=utf-8~n~n'),
        current_output(Out),
        stream_property(Out, encoding(OldEnc)),
        set_stream(Out, encoding(utf8)),
        write(Out, SVGString),
        set_stream(Out, encoding(OldEnc))
    ;   reply_json_dict(_{error: 'failed to generate svg'}, [status(400)])
    ).

% helper to parse fraction string e.g. "7/5" into fraction(7, 5) or integer
parse_val_down_str(Str, fraction(Num, Den)) :-
    sub_string(Str, Before, _, _, "/"),
    !,
    sub_string(Str, 0, Before, _, NumStr),
    Before1 is Before + 1,
    sub_string(Str, Before1, _, 0, DenStr),
    number_string(Num, NumStr),
    number_string(Den, DenStr).
parse_val_down_str(Str, Val) :-
    number_string(Val, Str),
    !.
parse_val_down_str(Str, Str).

%!  handle_fraction_render(+Request) is det.
%
%   GET /api/fraction/render?kind=Kind&n=N&d=D
%   Compiles a fraction automaton trace into v2 bar-scene frames and
%   returns them as JSON. The live/secondary delivery path for the
%   fraction-bars viewer (the file dump is the primary path).
%   Returns: the frame Dict from fraction_render_json/4.
handle_fraction_render(Request) :-
    cors_enable(Request, [methods([get])]),
    http_parameters(Request,
                    [ kind(Kind, [atom, default(splitting)]),
                      n(N, [integer, default(1)]),
                      d(D, [integer, default(4)])
                    ]),
    (   catch(
            fraction_render_json(Kind, N, D, Dict),
            Error,
            (   format(user_error,
                       'fraction_render error: ~w~n', [Error]),
                fail
            )
        )
    ->  reply_json_dict(Dict)
    ;   reply_json_dict(_{error: 'fraction render failed'}, [status(400)])
    ).

%!  handle_fraction_arith(+Request) is det.
%
%   GET /api/fraction/arith?op=Op&an=NumA&ad=DenA&bn=NumB&bd=DenB
%   Runs the productive co-measurement automaton for Op (add|sub) on the two
%   fractions and returns v2 bar-scene frames showing the common-denominator
%   move. fraction_arith_json/6 itself returns an explicit {error,frames:[]}
%   for unsupported ops or a negative subtraction, so the 200 body always
%   carries either frames or an honest message for the calculator UI.
handle_fraction_arith(Request) :-
    cors_enable(Request, [methods([get])]),
    http_parameters(Request,
                    [ op(Op, [atom, default(add)]),
                      an(AN, [integer, default(1)]),
                      ad(AD, [integer, default(3)]),
                      bn(BN, [integer, default(1)]),
                      bd(BD, [integer, default(4)])
                    ]),
    (   catch(
            fraction_arith_json(Op, AN, AD, BN, BD, Dict),
            Error,
            (   format(user_error,
                       'fraction_arith error: ~w~n', [Error]),
                fail
            )
        )
    ->  reply_json_dict(Dict)
    ;   reply_json_dict(_{error: 'fraction arith failed'}, [status(400)])
    ).

%!  handle_fraction_compare(+Request) is det.
%
%   GET /api/fraction/compare?kind=ProductiveKind&a=A&b=B
%   Returns two filmstrips (productive vs its paired deformation) plus a
%   grounded units-coordination note. This is the wire that lets Hermes or the
%   Prolog code display a misconception spatially: the same bar named two ways
%   (e.g. 5/3 with the whole held vs 5/5 with the whole lost).
handle_fraction_compare(Request) :-
    cors_enable(Request, [methods([get])]),
    http_parameters(Request,
                    [ kind(Kind, [atom, default(improper_fraction_iteration)]),
                      a(A, [integer, default(5)]),
                      b(B, [integer, default(3)])
                    ]),
    (   catch(
            fraction_compare_json(Kind, A, B, Dict),
            Error,
            (   format(user_error,
                       'fraction_compare error: ~w~n', [Error]),
                fail
            )
        )
    ->  reply_json_dict(Dict)
    ;   reply_json_dict(_{error: 'fraction compare failed'}, [status(400)])
    ).

%!  inject_base_tag(+HTML, -Patched) is det.
%   Inserts <base href="/assets/"> after <head> so relative script/link
%   paths resolve to /assets/ when served via the Prolog server.
inject_base_tag(HTML, Patched) :-
    (   sub_string(HTML, Before, _, _, "<head>")
    ->  HeadEnd is Before + 6,
        sub_string(HTML, 0, HeadEnd, _, Prefix),
        sub_string(HTML, HeadEnd, _, 0, Suffix),
        atomic_list_concat([Prefix, '\n<base href="/assets/">\n', Suffix], Patched)
    ;   Patched = HTML
    ).

%!  serve_html_string(+HTML) is det.
%   Write an HTML string to the HTTP response with correct UTF-8 encoding.
%   Temporarily sets UTF-8 encoding on the output stream, then restores it.
serve_html_string(HTML) :-
    format('Content-type: text/html; charset=utf-8~n~n'),
    current_output(Out),
    stream_property(Out, encoding(OldEnc)),
    set_stream(Out, encoding(utf8)),
    write(Out, HTML),
    set_stream(Out, encoding(OldEnc)).

%!  serve_zeeman_asset(+Request) is det.
%   GET /assets/* — serves static files from hermes/web/ (shared.js, etc.)
%   so that pages served via the Prolog server can load their JS dependencies.
serve_zeeman_asset(Request) :-
    cors_enable(Request, [methods([get])]),
    memberchk(path(Path), Request),
    atom_concat('/assets/', RelPath, Path),
    \+ sub_atom(RelPath, _, _, _, '..'),
    source_file(serve_bridge(_), ThisFile),
    file_directory_name(ThisFile, PrologDir),
    file_directory_name(PrologDir, RepoRoot),
    atomic_list_concat([RepoRoot, '/hermes/web/', RelPath], AssetPath),
    (   exists_file(AssetPath)
    ->  asset_content_type(RelPath, ContentType),
        format('Content-type: ~w~n~n', [ContentType]),
        setup_call_cleanup(
            open(AssetPath, read, In, [type(binary)]),
            copy_stream_data(In, current_output),
            close(In))
    ;   reply_json_dict(_{error: 'asset not found'}, [status(404)])
    ).

asset_content_type(Path, 'application/javascript') :- atom_concat(_, '.js', Path), !.
asset_content_type(Path, 'text/css') :- atom_concat(_, '.css', Path), !.
asset_content_type(Path, 'text/html') :- atom_concat(_, '.html', Path), !.
asset_content_type(Path, 'image/png') :- atom_concat(_, '.png', Path), !.
asset_content_type(_, 'application/octet-stream').

serve_frontend(Request) :-
    memberchk(path(Path), Request),
    (   Path == '/'
    ->  serve_index(Request)
    ;   \+ sub_atom(Path, _, _, _, '..'),
        atom_concat('public', Path, FilePath),
        exists_file(FilePath)
    ->  http_reply_file(FilePath, [], Request)
    ;   serve_index(Request)
    ).

serve_index(_Request) :-
    inline_frontend(HTML),
    format('Content-type: text/html~n~n'),
    format('~w', [HTML]).

inline_frontend(HTML) :-
    HTML = '<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Arithmetic Machine Explorer</title>
<style>
:root {
  --bg: #0f0f1a;
  --surface: #1a1a2e;
  --surface2: #16213e;
  --border: #2a2a4a;
  --text: #d4d4e0;
  --text-dim: #7a7a9a;
  --accent: #e94560;
  --success: #4ecca3;
  --warn: #f0a050;
  --oracle: #9b7aed;
  --mono: "SF Mono", "Fira Code", "Cascadia Code", "Consolas", monospace;
  --sans: -apple-system, "Segoe UI", sans-serif;
}
* { box-sizing: border-box; margin: 0; padding: 0; }
body {
  font-family: var(--sans);
  background: var(--bg);
  color: var(--text);
  min-height: 100vh;
  line-height: 1.6;
}

.container { max-width: 720px; margin: 0 auto; padding: 2rem 1.5rem; }

header { margin-bottom: 2rem; }
h1 { font-size: 1.5rem; font-weight: 600; margin-bottom: 0.25rem; }
.subtitle { color: var(--text-dim); font-size: 0.9rem; }

/* Controls */
.controls {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 8px;
  padding: 1.25rem;
  margin-bottom: 1.5rem;
}
.controls-row {
  display: flex; gap: 0.75rem; align-items: end; flex-wrap: wrap;
}
.field label {
  display: block; font-size: 0.7rem; color: var(--text-dim);
  text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 0.25rem;
}
.field select, .field input {
  background: var(--bg); border: 1px solid var(--border);
  color: var(--text); padding: 0.45rem 0.6rem; border-radius: 4px;
  font-family: var(--mono); font-size: 0.85rem; width: 100%;
}
.field select { width: 130px; }
.field input[type=number] { width: 65px; }
.controls-row .spacer { flex: 1; }
button.run {
  background: var(--accent); color: white; border: none;
  padding: 0.45rem 1.5rem; border-radius: 4px; cursor: pointer;
  font-family: var(--sans); font-size: 0.85rem; font-weight: 600;
  white-space: nowrap;
}
button.run:hover { filter: brightness(1.1); }
button.run:disabled { opacity: 0.4; cursor: not-allowed; }
button.reset {
  background: none; border: 1px solid var(--border); color: var(--text-dim);
  padding: 0.45rem 0.75rem; border-radius: 4px; cursor: pointer;
  font-size: 0.8rem;
}
button.reset:hover { border-color: var(--text-dim); }
.limit-warning {
  font-size: 0.75rem; color: var(--warn); margin-top: 0.5rem;
  display: none;
}

/* Narrative cards */
.narrative { display: flex; flex-direction: column; gap: 0; }
.card {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 8px;
  padding: 1.25rem 1.5rem;
  margin-bottom: 0;
  position: relative;
  animation: fadeIn 0.3s ease both;
}
.card + .connector {
  width: 2px; height: 24px; background: var(--border);
  margin: 0 auto;
}
.card + .connector + .card { }
@keyframes fadeIn { from { opacity: 0; transform: translateY(8px); } to { opacity: 1; } }
.card:nth-child(1)  { animation-delay: 0s; }
.card:nth-child(3)  { animation-delay: 0.15s; }
.card:nth-child(5)  { animation-delay: 0.3s; }
.card:nth-child(7)  { animation-delay: 0.45s; }
.card:nth-child(9)  { animation-delay: 0.6s; }

.card-phase {
  font-size: 0.65rem; font-weight: 700; text-transform: uppercase;
  letter-spacing: 0.12em; margin-bottom: 0.5rem; display: flex;
  align-items: center; gap: 0.5rem;
}
.card-phase .dot {
  width: 8px; height: 8px; border-radius: 50%; display: inline-block;
}
.card p { margin-bottom: 0.5rem; font-size: 0.9rem; }
.card p:last-child { margin-bottom: 0; }
.card .dim { color: var(--text-dim); }
.card .emph { font-weight: 600; }

/* Phase colors */
.card.observe .card-phase { color: var(--text-dim); }
.card.observe .dot { background: var(--text-dim); }
.card.crisis .card-phase { color: var(--warn); }
.card.crisis .dot { background: var(--warn); }
.card.crisis { border-color: rgba(240,160,80,0.3); }
.card.reorganize .card-phase { color: var(--oracle); }
.card.reorganize .dot { background: var(--oracle); }
.card.reorganize { border-color: rgba(155,122,237,0.2); }
.card.resolve .card-phase { color: var(--success); }
.card.resolve .dot { background: var(--success); }
.card.resolve { border-color: rgba(78,204,163,0.3); }
.card.direct-success .card-phase { color: var(--success); }
.card.direct-success .dot { background: var(--success); }
.card.failure .card-phase { color: var(--accent); }
.card.failure .dot { background: var(--accent); }
.card.failure { border-color: rgba(233,69,96,0.3); }

/* Tallies */
.tallies {
  font-family: var(--mono); font-size: 1rem;
  letter-spacing: 0.15em; margin: 0.5rem 0;
  line-height: 1.8;
}
.tallies .group { display: inline; margin-right: 0.4em; }
.tallies .mark { color: var(--text); }
.tallies .mark.counted { color: var(--success); }
.tallies .mark.uncounted { color: var(--border); opacity: 0.5; }
.tallies .op { color: var(--text-dim); margin: 0 0.3em; }
.tallies .bracket { color: var(--oracle); font-weight: bold; }

/* Resource bar */
.resource-bar {
  margin: 0.75rem 0 0.25rem;
  display: flex; align-items: center; gap: 0.5rem;
  font-family: var(--mono); font-size: 0.75rem; color: var(--text-dim);
}
.bar-track {
  flex: 1; height: 6px; background: var(--bg);
  border-radius: 3px; overflow: hidden; max-width: 200px;
}
.bar-fill {
  height: 100%; border-radius: 3px;
  transition: width 0.5s ease;
}
.bar-fill.ok { background: var(--success); }
.bar-fill.warn { background: var(--warn); }
.bar-fill.exhausted { background: var(--accent); }

/* Oracle quote */
.oracle-quote {
  background: rgba(155,122,237,0.08);
  border-left: 3px solid var(--oracle);
  padding: 0.5rem 0.75rem;
  margin: 0.5rem 0;
  font-size: 0.85rem;
  font-style: italic;
  color: var(--text);
}

/* Synthesis checklist */
.checklist { list-style: none; margin: 0.5rem 0; }
.checklist li {
  font-size: 0.85rem; padding: 0.15rem 0;
  display: flex; align-items: center; gap: 0.4rem;
}
.checklist .ok { color: var(--success); }
.checklist .fail { color: var(--accent); }

/* Knowledge panel */
.knowledge-panel {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 8px;
  padding: 1.25rem 1.5rem;
  margin-top: 2rem;
}
.knowledge-panel h2 {
  font-size: 0.9rem; font-weight: 600; margin-bottom: 0.75rem;
}
.knowledge-op {
  display: flex; align-items: baseline; gap: 0.5rem;
  margin-bottom: 0.4rem; font-size: 0.85rem;
}
.knowledge-op .op-name {
  font-family: var(--mono); font-weight: 600;
  min-width: 70px; color: var(--text-dim);
}
.knowledge-op .strategies { color: var(--text); }
.knowledge-op .primordial {
  font-style: italic; color: var(--text-dim); font-size: 0.8rem;
}
.knowledge-op .arrow { color: var(--success); margin: 0 0.2rem; }

/* Empty state */
.empty-state {
  text-align: center; padding: 3rem 1rem; color: var(--text-dim);
}
.empty-state p { font-size: 0.9rem; margin-bottom: 0.5rem; }
.empty-state .suggestion {
  font-size: 0.8rem; font-family: var(--mono);
  background: var(--surface); display: inline-block;
  padding: 0.3rem 0.6rem; border-radius: 4px; margin-top: 0.5rem;
}

/* Tension readout */
.tension-readout {
  margin: 0.5rem 0 0.25rem;
  display: flex; align-items: center; gap: 0.5rem;
  font-family: var(--mono); font-size: 0.75rem; color: var(--text-dim);
}
.tension-bar-track {
  flex: 0 0 80px; height: 6px; background: var(--bg);
  border-radius: 3px; overflow: hidden;
}
.tension-bar-fill {
  height: 100%; border-radius: 3px;
  transition: width 0.5s ease;
}
.tension-bar-fill.stable { background: var(--success); }
.tension-bar-fill.inflection { background: var(--warn); }
.tension-bar-fill.unstable { background: var(--accent); }
.tension-label {
  font-size: 0.7rem; color: var(--text-dim);
}
.tension-label .stability-tag {
  font-weight: 600; margin-left: 0.25rem;
}
.tension-label .stability-tag.stable { color: var(--success); }
.tension-label .stability-tag.inflection { color: var(--warn); }
.tension-label .stability-tag.unstable { color: var(--accent); }
.tension-relaxation {
  font-size: 0.72rem; color: var(--warn); font-style: italic;
  margin-top: 0.2rem;
}

/* Bridge link */
.bridge-link {
  display: inline-flex; align-items: center; gap: 0.4rem;
  color: var(--warn); text-decoration: none;
  font-family: var(--mono); font-size: 0.8rem;
  padding: 0.35rem 0.75rem;
  border: 1px solid rgba(240,160,80,0.3);
  border-radius: 4px;
  transition: border-color 0.2s, color 0.2s;
}
.bridge-link:hover {
  border-color: var(--warn); color: #f5c070;
}
.bridge-link .arrow { font-size: 0.9rem; }
.bridge-subtitle {
  font-size: 0.65rem; color: var(--text-dim);
  margin-top: 0.15rem;
}

/* About */
.about {
  margin-top: 2rem; border-top: 1px solid var(--border);
  padding-top: 1rem;
}
.about summary {
  font-size: 0.8rem; color: var(--text-dim); cursor: pointer;
  list-style: none;
}
.about summary::before { content: "+ "; font-family: var(--mono); }
.about[open] summary::before { content: "- "; }
.about .about-body {
  font-size: 0.8rem; color: var(--text-dim); line-height: 1.7;
  margin-top: 0.75rem;
}
.about .about-body h3 {
  font-size: 0.8rem; color: var(--text); margin: 1rem 0 0.25rem;
}
.about .about-body p { margin-bottom: 0.5rem; }
.about .about-body a {
  color: var(--warn); text-decoration: none;
}
.about .about-body a:hover { text-decoration: underline; }
.about .about-body .limitation {
  border-left: 2px solid var(--border);
  padding-left: 0.75rem;
  margin: 0.4rem 0;
}
</style>
</head>
<body>
<div class="container">

<header>
  <div style="display:flex;justify-content:space-between;align-items:flex-start;flex-wrap:wrap;gap:0.75rem">
    <div>
      <h1>Arithmetic Machine Explorer</h1>
      <p class="subtitle">Solve directly or run the ORR crisis cycle</p>
    </div>
    <div style="text-align:right;display:flex;flex-direction:column;align-items:flex-end;gap:0.4rem">
      <a href="/bridge" class="bridge-link" title="See the formalization''s tension dynamics as catastrophe geometry">
        Watch in Bridge <span class="arrow">&#8594;</span>
      </a>
      <div class="bridge-subtitle">Tension dynamics as catastrophe geometry</div>
      <a href="/reorg-demo" class="bridge-link" title="Run the live fraction reorganization demo">
        Fraction Reorganization Demo <span class="arrow">&#8594;</span>
      </a>
      <div class="bridge-subtitle">Live fraction crisis and recovery</div>
    </div>
  </div>
</header>

<div class="controls">
  <div class="controls-row">
    <div class="field">
      <label>Mode</label>
      <select id="mode" onchange="checkWarnings()">
        <option value="direct">direct</option>
        <option value="developmental">developmental</option>
      </select>
    </div>
    <div class="field">
      <label>Operation</label>
      <select id="op" onchange="checkWarnings()">
        <option value="add">add</option>
        <option value="subtract">subtract</option>
        <option value="multiply">multiply</option>
        <option value="divide" selected>divide</option>
      </select>
    </div>
    <div class="field">
      <label>A</label>
      <input type="number" id="a" value="56" min="0" max="99" onchange="checkWarnings()">
    </div>
    <div class="field">
      <label>B</label>
      <input type="number" id="b" value="7" min="0" max="99" onchange="checkWarnings()">
    </div>
    <div class="field">
      <label>Limit</label>
      <input type="number" id="limit" value="20" min="5" max="500">
    </div>
    <div class="spacer"></div>
    <button class="run" id="run" onclick="compute()">Run</button>
    <button class="reset" onclick="resetMachine()">Reset</button>
  </div>
  <div class="limit-warning" id="warning">
    Numbers above ~15 use Peano representation (tally marks) and will be slow by design.
    This slowness triggers crisis and learning.
  </div>
</div>

<div id="narrative" class="narrative">
  <div class="empty-state">
    <p>Direct mode uses the Teacher-backed arithmetic facade.</p>
    <p>Developmental mode runs the ORR cycle with an inference budget.</p>
    <div class="suggestion">Try direct: 56 ÷ 7</div>
  </div>
</div>

<div id="knowledge-panel" class="knowledge-panel">
  <h2>What the machine knows</h2>
  <div id="knowledge"></div>
</div>

<details class="about">
  <summary>About this system</summary>
  <div class="about-body">
    <h3>The ORR Cycle</h3>
    <p>Observe, React, Reorganize. The machine attempts a computation using what it knows.
    When its approach fails (resource exhaustion or unknown operation), it enters crisis.
    Crisis triggers teacher intervention, strategy synthesis, and retry.</p>

    <h3>Direct Arithmetic</h3>
    <p>Direct mode goes through <code>arithmetic_machine.pl</code>. It can show the
    Teacher-backed strategy choice without requiring elastic input or an inference-budget
    catastrophe. Developmental mode keeps the older ORR path available when crisis is the
    object of study.</p>

    <h3>Counting All</h3>
    <p>The machine starts with one strategy: build both numbers as tallies (successor applications),
    then count the total from 1. This is how young children add before learning shortcuts.
    It works, but it is expensive: adding 8 + 5 requires constructing 13 tally marks and counting
    each one, which exceeds a tight inference budget.</p>

    <h3>The Teacher</h3>
    <p>The teacher creates conditions under which the learner''s current approach breaks down.
    What the system receives is a result and a description of the method, but not
    its internal workings. The machine must reconstruct the strategy from its own primitives
    (successor, predecessor, decompose). The strategies come from Carpenter and Fennema''s
    Cognitively Guided Instruction research.</p>

    <h3>Tension Dynamics</h3>
    <p>Each inference step accumulates tension. The tension system tracks not just a level but
    its acceleration: when the second derivative goes negative, the system has entered an
    unstable zone where any perturbation can trigger a snap. After crisis, tension partially
    relaxes but does not reset to zero. The system remembers it was stressed. This
    hysteresis means successive crises hit differently.</p>

    <h3>The Bridge</h3>
    <p>The <a href="/bridge">Bridge</a> connects this explorer to a Zeeman catastrophe machine
    visualization. Each inference step accumulates tension in the Prolog meta-interpreter.
    When stability drops below zero, the learner has entered the catastrophe zone &mdash;
    any perturbation triggers a discontinuous snap. The Bridge visualizes this geometry in
    real time, mapping the formalization''s internal dynamics onto catastrophe surface
    coordinates.</p>

    <h3>Where This Stops Working</h3>
    <p>These limitations are not bugs. They mark the boundary where the formalism honestly
    stops being able to say anything.</p>
    <div class="limitation">
      <p><strong>The fraction crisis.</strong> The system handles whole-number arithmetic
      through the ORR cycle. Fractions need three-level unit coordination (unit, fractional
      part, whole); the current system only manages two. The fraction representation
      (<code>fraction/2</code>) is structurally incompatible with
      <code>recollection/1</code>. What does &ldquo;encountering a fraction&rdquo; mean
      for a system that started with tally marks?</p>
    </div>
    <div class="limitation">
      <p><strong>The synthesis gap.</strong> Current synthesis wraps teacher-provided
      results rather than building genuine FSM strategies from ENS primitives. The machine
      says it synthesized a strategy, but it memorized a phone number, not a method.
      Strategy ordering also ignores developmental prerequisites.</p>
    </div>
    <div class="limitation">
      <p><strong>The hollow boundary.</strong> The sequent calculus (incompatibility
      semantics) has a precise point where formal proof goes hollow. When sequent
      variables carry the vanishing-point mark, the prover returns a hollow node
      instead of a proof. The derivation succeeds structurally, but its warrant is
      withdrawn. These are points where the formalization hands the question to
      human judgment.</p>
    </div>

    <h3>Why this matters</h3>
    <p>This is not a calculator. It is a formal model of crisis-driven learning from the
    manuscript <em>Understanding Mathematics as an Emancipatory Discipline: A Critical Theory
    Approach</em>. The interesting thing is not the arithmetic but the structure of the
    developmental crisis and the limits of what formal systems can capture about learning.
    The <a href="/bridge">Bridge visualization</a> and the
    <a href="https://github.com/TioSavich/umedcta-portfolio" target="_blank">More Machine</a>
    in the portfolio are experiential companions to what the Prolog formalizes here.</p>
  </div>
</details>

</div>

<script>
const OP_SYMBOLS = { add: "+", subtract: "\\u2212", multiply: "\\u00d7", divide: "\\u00f7" };

const STRATEGY_NAMES = {
  "COBO": "Count On by Bases and Ones",
  "RMB": "Rearranging to Make Bases",
  "Chunking": "Chunking",
  "Rounding": "Rounding to Nearest Ten",
  "COBO (Missing Addend)": "Count On (Missing Addend)",
  "CBBO (Take Away)": "Count Back (Take Away)",
  "Decomposition": "Decomposition",
  "Sliding": "Sliding",
  "Chunking A": "Chunking (variant A)",
  "Chunking B": "Chunking (variant B)",
  "Chunking C": "Chunking (variant C)",
  "C2C": "Coordinating Two Counts",
  "CBO": "Conversion to Bases and Ones",
  "Commutative Reasoning": "Commutative Reasoning",
  "DR": "Distributive Reasoning",
  "Dealing by Ones": "Dealing By Ones",
  "CGOB": "Conversion to Groups Other than Bases",
  "IDP": "Inverse of the Distributive Property",
  "UCR": "Using Commutative Reasoning"
};

const CRISIS_EXPLANATIONS = {
  efficiency_crisis: (a, b, op, limit) =>
    `The machine can ${op} by counting, but ${a} ${OP_SYMBOLS[op]} ${b} requires more ` +
    `counting steps than its ${limit}-inference budget allows. ` +
    `Counting All touches every unit one at a time \\u2014 it works, but at a cost ` +
    `proportional to the size of the numbers.`,
  unknown_operation: (a, b, op) =>
    `The machine has never encountered ${op}. It has no concept of this operation ` +
    `and cannot even begin to attempt it. This is not an efficiency problem \\u2014 ` +
    `the operation is entirely absent from the machine''s repertoire.`
};

function strategyDisplay(abbrev) {
  const full = STRATEGY_NAMES[abbrev];
  return full ? `${full} (${abbrev})` : abbrev;
}

function tallies(n) {
  if (n > 25) return `[${n}]`;
  let html = "";
  for (let i = 0; i < n; i++) {
    if (i > 0 && i % 5 === 0) html += " ";
    html += "\\u2758";
  }
  return html;
}

function resourceBar(used, total) {
  const pct = Math.min(100, Math.round((used / total) * 100));
  const cls = pct >= 100 ? "exhausted" : pct > 70 ? "warn" : "ok";
  return `<div class="resource-bar">
    <div class="bar-track"><div class="bar-fill ${cls}" style="width:${pct}%"></div></div>
    <span>${used}/${total} inferences${pct >= 100 ? " (exhausted)" : ""}</span>
  </div>`;
}

function tensionReadout(tensionState, tensionHistory) {
  if (!tensionState) return "";
  const level = tensionState.level || 0;
  const stability = tensionState.stability || 0;
  const stClass = stability > 0.5 ? "stable" : stability > -0.5 ? "inflection" : "unstable";
  const stLabel = stability > 0.5 ? "stable" : stability > -0.5 ? "inflection" : "unstable";
  // Tension bar: normalize level to 0-100 range (cap at 50 for display)
  const barPct = Math.min(100, Math.round((level / 50) * 100));
  let html = `<div class="tension-readout">
    <span>Tension</span>
    <div class="tension-bar-track"><div class="tension-bar-fill ${stClass}" style="width:${barPct}%"></div></div>
    <span class="tension-label">${level.toFixed(1)}
      <span class="stability-tag ${stClass}">${stLabel}</span>
    </span>
  </div>`;
  // Check for relaxation events in the history
  if (tensionHistory && tensionHistory.length > 0) {
    const relaxations = tensionHistory.filter(h => h.context === "relaxation");
    if (relaxations.length > 0) {
      const last = relaxations[relaxations.length - 1];
      // Find the tension level just before the relaxation
      const idx = tensionHistory.indexOf(last);
      const before = idx > 0 ? tensionHistory[idx - 1] : null;
      if (before) {
        html += `<div class="tension-relaxation">Crisis resolved \\u2014 tension relaxed from ${before.level.toFixed(1)} to ${last.level.toFixed(1)}</div>`;
      }
    }
  }
  return html;
}

function makeCard(phase, cls, content) {
  return `<div class="card ${cls}">
    <div class="card-phase"><span class="dot"></span>${phase}</div>
    ${content}
  </div>`;
}

function connector() { return \'<div class="connector"></div>\'; }

function checkWarnings() {
  const mode = document.getElementById("mode").value;
  const a = parseInt(document.getElementById("a").value) || 0;
  const b = parseInt(document.getElementById("b").value) || 0;
  const warn = document.getElementById("warning");
  warn.style.display = (mode === "developmental" && (a > 15 || b > 15)) ? "block" : "none";
}

async function compute() {
  const btn = document.getElementById("run");
  const narr = document.getElementById("narrative");
  btn.disabled = true;
  narr.innerHTML = "<p class=\\"dim\\" style=\\"text-align:center;padding:2rem\\">Computing...</p>";

  const problem = {
    mode: document.getElementById("mode").value,
    operation: document.getElementById("op").value,
    a: parseInt(document.getElementById("a").value),
    b: parseInt(document.getElementById("b").value),
    limit: parseInt(document.getElementById("limit").value)
  };

  try {
    const res = await fetch("/api/compute", {
      method: "POST",
      headers: {"Content-Type": "application/json"},
      body: JSON.stringify(problem)
    });
    const data = await res.json();
    renderNarrative(data, problem);
    renderKnowledge(data.knowledge);
  } catch (e) {
    narr.innerHTML = `<div class="card failure">
      <div class="card-phase"><span class="dot"></span>Error</div>
      <p>${e.message}</p>
    </div>`;
  } finally {
    btn.disabled = false;
  }
}

function renderNarrative(data, problem) {
  const narr = document.getElementById("narrative");
  const events = data.events;
  const op = problem.operation;
  const a = problem.a, b = problem.b;
  const sym = OP_SYMBOLS[op];
  const limit = problem.budget || problem.limit;
  const mode = data.mode || problem.mode;
  const tState = data.tension || null;
  const tHistory = data.tension_history || [];

  const cards = [];
  let resolveEvent = null;

  // Process events into cards
  let i = 0;
  while (i < events.length) {
    const e = events[i];

    if (e.type === "computation_start" && i + 1 < events.length) {
      const next = events[i + 1];

      if (next.type === "computation_success") {
        // Direct success
        const used = next.inferences_used || "?";
        const result = next.result != null ? next.result : "?";
        const isRetry = cards.length > 0;

        if (isRetry) {
          // This is the resolution after learning
          const strategy = resolveEvent ? resolveEvent.strategy : null;
          cards.push(makeCard("Resolve", "resolve", `
            <p class="emph" style="font-size:1.3rem">${a} ${sym} ${b} = ${result}</p>
            ${strategy ? `<p>Using ${strategyDisplay(strategy)}</p>` : ""}
            ${strategy ? renderStrategyVisual(op, a, b, result, strategy) : ""}
            ${resourceBar(used, limit)}
            ${tensionReadout(tState, tHistory)}
          `));
        } else {
          const strategy = next.strategy || null;
          const interpretation = next.interpretation || "";
          cards.push(makeCard("Observe", "direct-success", `
            <p>The machine computes <span class="emph">${a} ${sym} ${b} = ${result}</span></p>
            ${strategy ? `<p>Strategy: ${strategyDisplay(strategy)}</p>` : ""}
            ${interpretation ? `<div class="oracle-quote">${interpretation}</div>` : ""}
            <p class="dim">${mode === "direct"
              ? "Solved through the Teacher-backed arithmetic facade, without elastic input or a crisis budget."
              : "Solved directly with current knowledge."}</p>
            ${mode === "direct" ? "" : resourceBar(used, limit)}
            ${tensionReadout(tState, tHistory)}
          `));
        }
        i += 2;
        continue;
      }

      if (next.type === "crisis_detected") {
        // Failed attempt
        cards.push(makeCard("Observe", "observe", `
          <p>The machine attempts <span class="emph">${a} ${sym} ${b}</span>
          using its only approach: <span class="emph">Counting All</span>.</p>
          <p class="dim">Build both numbers as tallies, then count the total from 1.</p>
          <div class="tallies">${tallies(a)} <span class="op">${sym}</span> ${tallies(b)}</div>
          <p class="dim">Each tally mark costs an inference. The meta-interpreter adds overhead
          for each step of the computation.</p>
          ${resourceBar(limit, limit)}
        `));
        i += 2;

        // Crisis classification
        if (i < events.length && events[i].type === "crisis_classified") {
          const cls = events[i];
          const crisisType = cls.classification || "unclassified";
          const explanation = CRISIS_EXPLANATIONS[crisisType]
            ? CRISIS_EXPLANATIONS[crisisType](a, b, op, limit)
            : cls.signal || "The machine''s current approach has failed.";
          cards.push(makeCard("Crisis", "crisis", `
            <p class="emph">${crisisType.replace(/_/g, " ")}</p>
            <p>${explanation}</p>
            <p class="dim">The machine''s current way of being is inadequate.
            It must learn or fail.</p>
            ${tensionReadout(tState, tHistory)}
          `));
          i++;
        }

        // Reorganize: collect oracle + synthesis events
        const reorgParts = [];
        let synthesisOk = false;
        let validationOk = false;
        let oracleStrategy = null;
        let oracleResult = null;
        let oracleInterp = null;

        while (i < events.length && events[i].type !== "computation_start"
               && events[i].type !== "computation_failed") {
          const re = events[i];
          if (re.type === "oracle_consulted") {
            oracleStrategy = re.strategy;
            oracleResult = re.result;
            oracleInterp = re.interpretation;
          }
          if (re.type === "oracle_exhausted") {
            reorgParts.push(`<p class="dim">The teacher has no further interventions for this operation.</p>`);
          }
          if (re.type === "synthesis_succeeded") synthesisOk = true;
          if (re.type === "synthesis_failed") synthesisOk = false;
          if (re.type === "validation_passed") validationOk = true;
          if (re.type === "validation_failed") validationOk = false;
          if (re.type === "retry") resolveEvent = { strategy: oracleStrategy };
          i++;
        }

        if (oracleStrategy) {
          cards.push(makeCard("Reorganize", "reorganize", `
            <p class="emph">Teacher intervention</p>
            <p>Strategy: ${strategyDisplay(oracleStrategy)}</p>
            <div class="oracle-quote">${oracleInterp || ""}</div>
            <p class="dim">The teacher created conditions for this strategy to emerge.
            The system receives a result (${oracleResult}) and a description of
            the method, but not its internal workings. It must reconstruct the practice from
            its own primitives (successor, predecessor, decompose).</p>
            <ul class="checklist">
              <li><span class="${synthesisOk ? "ok" : "fail"}">${synthesisOk ? "\\u2713" : "\\u2717"}</span>
                Strategy synthesized from primitives</li>
              <li><span class="${validationOk ? "ok" : "fail"}">${validationOk ? "\\u2713" : "\\u2717"}</span>
                Validation: result matches Teacher result</li>
            </ul>
            ${reorgParts.join("")}
          `));
        } else {
          cards.push(makeCard("Reorganize", "failure", `
            <p class="emph">No intervention available</p>
            ${reorgParts.join("")}
            <p class="dim">No strategy available. The crisis remains unresolved.</p>
          `));
        }
        continue;
      }
    }

    // Fallback for computation_failed at top level
    if (e.type === "computation_failed") {
      cards.push(makeCard("Failed", "failure", `
        <p>The computation failed. The machine could not solve
        ${a} ${sym} ${b} within its constraints.</p>
      `));
      i++;
      continue;
    }

    i++;
  }

  // Join cards with connectors
  narr.innerHTML = cards.join(connector());
}

function renderStrategyVisual(op, a, b, result, strategy) {
  if (!strategy) return "";

  if (strategy === "COBO" && op === "add") {
    // COBO decomposes B into tens (bases) and ones, then counts on
    const bases = Math.floor(b / 10);
    const ones = b % 10;
    const baseSteps = [];
    let cur = a;
    for (let s = 0; s < bases; s++) { cur += 10; baseSteps.push(cur); }
    const oneSteps = [];
    for (let s = 0; s < ones; s++) { cur += 1; oneSteps.push(cur); }
    let viz = `<div class="tallies"><span class="bracket">[${a}]</span>`;
    if (bases > 0) viz += `<span class="dim"> +${bases} tens: ${baseSteps.join(", ")}</span>`;
    if (ones > 0) viz += `<span class="dim"> +${ones} ones: ${oneSteps.join(", ")}</span>`;
    viz += `<span class="dim"> \\u2192 ${result}</span></div>`;
    return viz;
  }

  if (strategy === "COBO (Missing Addend)" && op === "subtract") {
    const steps = [];
    for (let s = b + 1; s <= a; s++) steps.push(s);
    return `<div class="tallies">
      <span class="bracket">[${b}]</span>
      <span class="dim"> count up to ${a}: ${steps.join(", ")} \\u2192 gap = ${result}</span>
    </div>`;
  }

  return "";
}

function renderKnowledge(knowledge) {
  const el = document.getElementById("knowledge");
  if (!knowledge) { el.innerHTML = "<p class=\\"dim\\">Loading...</p>"; return; }

  let html = "";
  for (const k of knowledge) {
    const learned = k.learned || [];
    const display = learned.length > 0
      ? "Counting All <span class=\\"arrow\\">\\u2192</span> " +
        learned.map(s => strategyDisplay(s)).join(", ")
      : "<span class=\\"primordial\\">Counting All only</span>";
    html += `<div class="knowledge-op">
      <span class="op-name">${k.operation}</span>
      <span class="strategies">${display}</span>
    </div>`;
  }
  el.innerHTML = html;
}

async function resetMachine() {
  if (!confirm("Reset the machine to primordial state? All learned strategies will be forgotten.")) return;
  await fetch("/api/reset", { method: "POST" });
  document.getElementById("narrative").innerHTML = `
    <div class="empty-state">
      <p>Machine reset to primordial state.</p>
      <p>It knows only Counting All.</p>
    </div>`;
  // Refresh knowledge
  const res = await fetch("/api/knowledge");
  const knowledge = await res.json();
  renderKnowledge(knowledge);
}

// Load initial knowledge state
(async function() {
  try {
    const res = await fetch("/api/knowledge");
    const knowledge = await res.json();
    renderKnowledge(knowledge);
  } catch(e) {}
})();

checkWarnings();
</script>
</body>
</html>'.

% ═══════════════════════════════════════════════════════════════════════
% Auto-start
% ═══════════════════════════════════════════════════════════════════════

:- initialization((start_server, thread_get_message(_)), main).
