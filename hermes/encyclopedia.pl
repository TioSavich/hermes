/** <module> hermes_encyclopedia — JSON-safe aggregation layer for the Hermes console
 *
 * A thin, robust surface over machinery that already exists elsewhere in the
 * repo. Every exported predicate returns SWI dicts whose values are only
 * strings, numbers, the atoms `true`/`false`, lists, or nested dicts — so the
 * Hermes worker can hand them straight to `json_write_dict/3` and a JS
 * frontend can consume them without further coercion.
 *
 * This module owns no domain facts. It reads:
 *   - strategies(math/action_automata_registry) — the ~94 flat action-pair
 *     kinds (action_automaton_cluster/3, action_automaton_vocabulary/3).
 *   - learner(action_semantic_context)          — strategy_action_kind/3, the
 *     bridge from FSM display names ('COBO', 'Chunking', ...) to action-pair
 *     kinds. A kind is FSM-backed iff it appears here.
 *   - strategies(hermeneutic_calculator)        — calculate/6, run a named FSM
 *     strategy and capture its execution History.
 *   - strategies(visualization)                 — strategy_jumps/3, extract a
 *     number-line jump trace from a strategy's History (only some shapes).
 *   - misconceptions(test_harness)              — query_misconception/4.
 *   - formalization(grounding_metaphors)        — the L&N metaphor facts.
 *   - standards (ccss, indiana, im) Prolog files — standard_anchor/4 facts,
 *     consulted into `user` at load time.
 *
 * Honesty notes baked into the data shapes rather than prose:
 *   - representation is "fsm" only for kinds reachable through an FSM module;
 *     everything else is "action_pair".
 *   - a strategy trace's jumps[] is non-empty only for the handful of
 *     step-shapes visualization.pl knows how to read; otherwise the note says
 *     so and ok still reflects whether a result was produced.
 *   - a misconception is diagnosable=false when its rule is the `skip`
 *     placeholder (the too_vague convention).
 *   - grounding_for_operation_dict returns metaphors:[] with an explaining
 *     note when L&N do not ground the operation in any source domain; absence
 *     is meaningful and is not papered over with a catch-all.
 */

:- module(hermes_encyclopedia, [
       strategy_catalog_dict/1,         % -Dict
       strategy_trace_dict/3,           % +StrategyName, +InputDict, -Dict
       misconception_catalog_dict/2,    % +Filter, -Dict
       standards_catalog_dict/2,        % +Filter, -Dict
       grounding_catalog_dict/1,        % -Dict
       grounding_for_operation_dict/2,  % +Operation, -Dict
       ground_query_dict/2,             % +QueryText, -Dict
       literature_search_dict/2,        % +QueryText, -Dict
       pml_score_dict/2,                % +ClauseStrings, -Dict
       validate_reader_axioms_dict/3    % +LessonCode, +ClauseStrings, -Dict
   ]).

:- use_module(library(lists)).
:- use_module(library(apply)).
:- use_module(library(pairs)).

:- use_module(strategies(math/action_automata_registry)).
:- use_module(strategies(hermeneutic_calculator)).
:- use_module(strategies(visualization)).
:- use_module(math(algebraic_action_pairs),
              [ run_algebraic_action/5 ]).
:- use_module(learner(action_semantic_context)).
:- use_module(formalization(grounding_metaphors)).
:- use_module(hermes(math_claim_checker), [ check_math_claim/2 ]).
:- use_module(hermes(math_context), [ math_context_for_claim/2 ]).
:- use_module(pml(text_interpreter), [ interpret_lesson_text/2 ]).
:- use_module(misconceptions(test_harness)).
:- use_module(misconceptions(literature_incompatibility_facts),
              [ lit_derived/9, lit_derived_meta/4 ]).
:- use_module(misconceptions(literature_vocabulary),
              [ lit_incompatibility/7, canonical_commitment/2,
                literature_mapping_stats/4, literature_adjudicated_count/1 ]).
% Opt-in load of the literature -> deontic edge graph (see that module's
% header): the graph and its scorekeeper wiring are non-default with respect
% to the deontic engine, and this app-layer module is a caller that wants
% them. Loading here is what puts the lit-derived edges under chat grounding.
:- use_module(misconceptions(literature_deontic_bridge),
              [ lit_deontic_edge/3, lit_deontic_probe/2 ]).

% standard_anchor/4 facts live in plain (non-module) files loaded into `user`.
% The worker consults them via its geometry runtime; for standalone use
% (and for the verification command, which loads only paths.pl + this module)
% we ensure they are present here. Defensive: never fail module load if a
% standards file is missing.
:- multifile user:standard_anchor/4.
:- initialization(ensure_standards_loaded).

ensure_standards_loaded :-
    (   current_predicate(user:standard_anchor/4),
        once(user:standard_anchor(_, _, _, _))
    ->  true                        % already loaded by the worker
    ;   load_standards_files
    ).

load_standards_files :-
    catch(load_standards_files_, _, true).

load_standards_files_ :-
    forall(
        member(Pattern, [ standards('ccss/*.pl'),
                          standards('indiana/*.pl'),
                          standards('im/*.pl')
                        ]),
        consult_pattern(Pattern)
    ).

consult_pattern(Spec) :-
    % Spec is alias(RelGlob); resolve the alias to a base directory, then glob.
    Spec =.. [Alias, Rel],
    (   user:file_search_path(Alias, Base)
    ->  atomic_list_concat([Base, '/', Rel], FullPattern),
        expand_file_name(FullPattern, Files),
        forall(member(F, Files),
               catch(user:consult(F), _, true))
    ;   true
    ).


%% ======================================================================
%% term_text/2 — the local stringifier. Numbers stay numbers; everything
%% else becomes a string. Never produces a compound or an unbound var.
%% ======================================================================

%!  term_text(+Value, -Text) is det.
term_text(Value, Text) :-
    (   var(Value)
    ->  Text = ""
    ;   string(Value)
    ->  Text = Value
    ;   atom(Value)
    ->  atom_string(Value, Text)
    ;   number(Value)
    ->  Text = Value
    ;   term_string(Value, Text, [quoted(false), numbervars(true)])
    ).

%!  term_text_string(+Value, -String) is det.
%
%   Like term_text/2 but always a string, even for numbers (for use in
%   fields the schema types as Str).
term_text_string(Value, String) :-
    term_text(Value, T),
    (   number(T)
    ->  ( integer(T) -> atom_number(A, T), atom_string(A, String)
        ; format(string(String), "~w", [T]) )
    ;   String = T
    ).


%% ======================================================================
%% strategy_catalog_dict/1
%% ======================================================================

%!  strategy_catalog_dict(-Dict) is det.
%
%   Catalog of every action-pair kind across all operations. has_fsm marks
%   the kinds that an FSM module backs (via action_semantic_context).
strategy_catalog_dict(_{
        count: Count,
        operations: Operations,
        strategies: Strategies,
        runnable: Runnable
    }) :-
    findall(Op-Kind,
            action_automata_registry:action_automaton_cluster(Op, Kind, _),
            Pairs0),
    sort(Pairs0, Pairs),
    findall(SDict,
            ( member(Op-Kind, Pairs),
              strategy_entry_dict(Op, Kind, SDict)
            ),
            Strategies),
    length(Strategies, Count),
    findall(OpStr,
            ( member(Op-_, Pairs),
              term_text_string(Op, OpStr)
            ),
            OpStrs0),
    sort(OpStrs0, Operations),
    runnable_list(Runnable).

%!  runnable_list(-List) is det.
%
%   The curated set of FSM strategies that hermeneutic_calculator can RUN on a
%   sensible default input and that produce a non-empty number-line jump trace
%   with the correct result. This is the showcase: a user clicks one and
%   watches the automaton compute. Each entry carries the exact display name
%   strategy_trace_dict/3 accepts plus a default (a, b) for the operation.
runnable_list(List) :-
    findall(_{name: NameStr, operation: OpStr, op_symbol: SymStr,
              a: A, b: B, expression: ExprStr},
            ( runnable_strategy(Name, Op, A, B),
              term_text_string(Name, NameStr),
              term_text_string(Op, OpStr),
              op_display_symbol(Op, Sym), term_text_string(Sym, SymStr),
              format(string(ExprStr), "~w ~w ~w", [A, Sym, B])
            ),
            List).

op_display_symbol(addition, '+') :- !.
op_display_symbol(subtraction, '−') :- !.
op_display_symbol(multiplication, '×') :- !.
op_display_symbol(division, '÷') :- !.
op_display_symbol(_, '+').

%!  op_default_input(+Operation, -A, -B) is det.
%
%   A sensible default operand pair per operation, so a strategy can be run
%   without the user having to guess valid input.
op_default_input(addition,       47, 28) :- !.
op_default_input(subtraction,    53, 27) :- !.
op_default_input(multiplication,  7,  8) :- !.
op_default_input(division,       12,  3) :- !.
op_default_input(_,               8,  5).

%!  runnable_strategy(?DisplayName, ?Operation, ?A, ?B) is nondet.
%
%   Verified runnable + visualizable: each produces a number-line jump trace
%   and the correct result on (A, B). Names are the FSM display names the
%   hermeneutic calculator keys on. Strategies that run and yield a step trace
%   but no number-line jumps (division CGOB/IDP, whose group-conversion shape
%   the jump extractor does not read) are excluded here so this list stays the
%   jump showcase; they remain reachable through strategy_trace directly.
runnable_strategy('COBO',                  addition,       47, 28).
runnable_strategy('Chunking',              addition,       47, 28).
runnable_strategy('RMB',                   addition,       47, 28).
runnable_strategy('Rounding',              addition,       47, 28).
runnable_strategy('CBBO (Take Away)',      subtraction,    53, 27).
runnable_strategy('COBO (Missing Addend)', subtraction,    53, 27).
runnable_strategy('Chunking A',            subtraction,    53, 27).
runnable_strategy('Chunking C',            subtraction,    53, 27).
runnable_strategy('Decomposition',         subtraction,    53, 27).
runnable_strategy('Sliding',               subtraction,    53, 27).
runnable_strategy('Sub Rounding',          subtraction,    53, 27).
runnable_strategy('Commutative Reasoning', multiplication,  7,  8).
runnable_strategy('DR',                    multiplication,  7,  8).
runnable_strategy('Dealing by Ones',       division,       12,  3).
runnable_strategy('UCR',                   division,       12,  3).

strategy_entry_dict(Op, Kind, _{
        operation: OpStr,
        kind: KindStr,
        representation: RepStr,
        provenance: ProvStr,
        source: SourceStr,
        cluster: ClusterStr,
        has_fsm: HasFSM,
        trace_name: TraceName,
        default_a: DefA,
        default_b: DefB
    }) :-
    term_text_string(Op, OpStr),
    term_text_string(Kind, KindStr),
    ( kind_fsm_name(Op, Kind, FSMName)
    -> HasFSM = true, RepStr = "fsm",
       term_text_string(FSMName, TraceName),
       format(string(ProvStr), "FSM strategy: ~s", [TraceName])
    ;  HasFSM = false, RepStr = "action_pair", TraceName = "",
       ProvStr = "flat action-pair (no FSM module)"
    ),
    op_default_input(Op, DefA, DefB),
    ( action_automata_registry:action_automaton_cluster(Op, Kind, Cluster)
    -> term_text_string(Cluster, ClusterStr)
    ;  ClusterStr = ""
    ),
    ( action_automata_registry:action_automaton_vocabulary(Op, Kind, Vocab)
    -> vocab_source_text(Vocab, SourceStr)
    ;  SourceStr = ""
    ).

%!  kind_fsm_name(+Op, +Kind, -FSMName) is semidet.
%
%   First FSM display name bound to this action-pair kind, if any.
kind_fsm_name(Op, Kind, FSMName) :-
    once(action_semantic_context:strategy_action_kind(Op, FSMName, Kind)).

vocab_source_text(Vocab, Str) :-
    ( is_list(Vocab)
    -> maplist(term_text_string, Vocab, Toks),
       atomic_list_concat(Toks, ", ", Joined),
       format(string(Str), "vocabulary: ~w", [Joined])
    ;  term_text_string(Vocab, V),
       format(string(Str), "vocabulary: ~s", [V])
    ).


%% ======================================================================
%% strategy_trace_dict/3
%% ======================================================================

%!  strategy_trace_dict(+StrategyName, +InputDict, -Dict) is det.
%
%   Best-effort trace of a named FSM strategy on the supplied input. Never
%   throws. If the strategy can be run to a number-line jump trace, jumps[]
%   is filled. If it runs to a result but the step-shape isn't readable,
%   result is filled and the note explains. If it can't run, ok:false.
strategy_trace_dict(StrategyName0, Input, Dict) :-
    to_atom(StrategyName0, StrategyName),
    strategy_lookup_name(StrategyName, LookupName),
    term_text_string(LookupName, NameStr),
    trace_inputs(Input, A, B),
    (   catch(run_named_strategy(LookupName, A, B, Result, History),
              _Err, fail)
    ->  trace_result_dict(LookupName, NameStr, A, B, Result, History, Dict)
    ;   Dict = _{
            strategy: NameStr,
            ok: false,
            representation: "fsm",
            result: "",
            steps: [],
            jumps: [],
            note: "Strategy could not be run on the given input (no matching operator/strategy, or the run failed)."
        }
    ).

%!  strategy_lookup_name(+RawName, -LookupName) is det.
%
%   Resolve display names case-insensitively while preserving the canonical
%   display atom used by the calculator and catalog. Registry kind atoms still
%   pass through, with the same trim/case tolerance for string callers.
strategy_lookup_name(RawName, LookupName) :-
    normalize_space(atom(Trimmed), RawName),
    downcase_atom(Trimmed, Lower),
    (   runnable_strategy(Canonical, _, _, _),
        downcase_atom(Canonical, Lower),
        !
    ->  LookupName = Canonical
    ;   action_automata_registry:action_automaton_cluster(_, Kind, _),
        term_text_string(Kind, KindStr),
        atom_string(KindAtom, KindStr),
        downcase_atom(KindAtom, Lower),
        !
    ->  LookupName = Kind
    ;   LookupName = Trimmed
    ).

trace_result_dict(StrategyName, NameStr, _A, _B, Result0, History, _{
        strategy: NameStr,
        ok: true,
        representation: Representation,
        result: ResultStr,
        steps: Steps,
        jumps: Jumps,
        jump_witness: JumpWitness,
        note: Note
    }) :-
    trace_result_value(Result0, Result),
    trace_representation(Result0, Representation),
    term_text_string(Result, ResultStr),
    history_steps(History, Steps),
    (   catch(visualization:strategy_jumps_witness(StrategyName, History, JumpWitness0), _, fail)
    ->  get_dict(jumps, JumpWitness0, Jumps0),
        sanitize_jumps(Jumps0, Jumps),
        strategy_jump_witness_dict(JumpWitness0, JumpWitness)
    ;   Jumps = [],
        unavailable_jump_witness(StrategyName, JumpWitness)
    ),
    ( Jumps == []
    -> Note = "Ran to a result; number-line jump trace is not available for this strategy's step shape."
    ;  Note = "Number-line jump trace extracted from the strategy's execution history."
    ).

trace_result_value(action_outcome(_, Properties), Result) :-
    (   member(result(Result), Properties)
    ;   member(cgi_outcome(Nested), Properties),
        trace_result_value(Nested, Result)
    ;   member(expected(Nested), Properties),
        trace_result_value(Nested, Result)
    ),
    !.
trace_result_value(Result, Result).

trace_representation(action_outcome(_, _), "action_automaton") :- !.
trace_representation(_, "fsm").

%!  run_named_strategy(+Name, +A, +B, -Result, -History) is semidet.
%
%   Try each arithmetic operator with hermeneutic_calculator:calculate/6.
%   The calculator keys on (Num1, Op, Num2, StrategyName); the same display
%   name can belong to more than one operator (e.g. 'Rounding'), so we try
%   them in a stable order and take the first that succeeds.
run_named_strategy(Name, A, B, Result, History) :-
    member(Op, [+, -, *, /]),
    catch(hermeneutic_calculator:calculate(A, Op, B, Name, Result, History),
          _, fail),
    !.
%% Registry kind atoms (count_on_from_larger, make_ten_drop_leftover, ...)
%% run through the deployed dispatcher. The calculator above covers only the
%% 20 v2 display names; the registry carries the 90+ action-pair kinds the
%% console's misconception and deformation traces name. The cluster table
%% supplies each kind's operation family; backtracking tries families in
%% registry order until one runs.
run_named_strategy(Name, A, B, Result, History) :-
    action_automata_registry:action_automaton_cluster(Operation, Name, _),
    catch(action_automata_registry:run_action_automaton(
              Operation, Name, A, B, Result, History),
          _, fail),
    !.

%!  history_steps(+History, -Steps) is det.
%
%   Stringify each history step into _{n, label, value}. label is the state
%   name; value is the interpretation text where available.
history_steps(History, Steps) :-
    ( is_list(History) -> H = History ; H = [] ),
    history_steps_(H, 1, Steps).

history_steps_([], _, []).
history_steps_([Step | Rest], N, [_{n: N, label: Label, value: Value} | More]) :-
    step_label_value(Step, Label, Value),
    N1 is N + 1,
    history_steps_(Rest, N1, More).

step_label_value(Step, Label, Value) :-
    step_state_interp(Step, State, Interp),
    state_label(State, Label),
    term_text_string(Interp, Value).

% Recognize the common history step arities used across the strategy modules.
step_state_interp(step(S, _, I), S, I) :- !.
step_state_interp(step(S, _, _, _, I), S, I) :- !.       % COBO-style step/5
step_state_interp(step(S, _, _, I), S, I) :- !.          % legacy step/4
step_state_interp(step(S, _, _, _, _, I), S, I) :- !.
step_state_interp(step(S, _, _, _, _, _, I), S, I) :- !.
step_state_interp(hist(S, I), S, I) :- !.
step_state_interp(Step, Step, '').

state_label(state(Name, _), Label) :- !, term_text_string(Name, Label).
state_label(state(Name), Label) :- !, term_text_string(Name, Label).
state_label(Name, Label) :- atom(Name), !, term_text_string(Name, Label).
state_label(Other, Label) :- term_text_string(Other, Label).

%!  sanitize_jumps(+Jumps0, -Jumps) is det.
%
%   visualization:strategy_jumps/3 already returns _{from,to,label} dicts with
%   numeric from/to and a string label. Re-key defensively into the exact
%   schema shape and guarantee JSON-safety.
sanitize_jumps(Jumps0, Jumps) :-
    ( is_list(Jumps0) -> J = Jumps0 ; J = [] ),
    findall(_{from: From, to: To, label: Label},
            ( member(Jump, J),
              get_dict(from, Jump, From0), num_value(From0, From),
              get_dict(to, Jump, To0), num_value(To0, To),
              ( get_dict(label, Jump, L0) -> term_text_string(L0, Label) ; Label = "" )
            ),
            Jumps).

strategy_jump_witness_dict(Witness0, _{
        kind: Kind,
        scope: Scope,
        strategy: Strategy,
        extraction: Extraction,
        derivation: Derivation,
        sample_count: SampleCount,
        jump_count: JumpCount,
        sums: Sums,
        jumps: Jumps
    }) :-
    dict_text(Witness0, kind, Kind),
    dict_text(Witness0, scope, Scope),
    dict_text(Witness0, strategy, Strategy),
    dict_text(Witness0, extraction, Extraction),
    dict_text(Witness0, derivation, Derivation),
    dict_number(Witness0, sample_count, SampleCount),
    dict_number(Witness0, jump_count, JumpCount),
    ( get_dict(sums, Witness0, Sums0), is_list(Sums0) -> Sums = Sums0 ; Sums = [] ),
    ( get_dict(jumps, Witness0, Jumps0) -> sanitize_jumps(Jumps0, Jumps) ; Jumps = [] ).

unavailable_jump_witness(StrategyName, _{
        kind: "strategy_number_line_jumps_unavailable",
        scope: "closed_world_finite_strategy_history_step_shapes",
        strategy: Strategy,
        extraction: "",
        derivation: "no_known_running_sum_trace",
        sample_count: 0,
        jump_count: 0,
        sums: [],
        jumps: []
    }) :-
    term_text_string(StrategyName, Strategy).

dict_text(Dict, Key, Text) :-
    ( get_dict(Key, Dict, Value)
    -> term_text_string(Value, Text)
    ;  Text = ""
    ).

dict_number(Dict, Key, Number) :-
    ( get_dict(Key, Dict, Value), number(Value)
    -> Number = Value
    ;  Number = 0
    ).

num_value(V, V) :- number(V), !.
num_value(V, N) :- atom(V), atom_number(V, N), !.
num_value(V, N) :- string(V), number_string(N, V), !.
num_value(_, 0).

%!  trace_inputs(+Input, -A, -B) is det.
%
%   Pull a/b operands out of the input dict; default 0 when absent so a
%   strategy can at least be attempted.
trace_inputs(Input, A, B) :-
    ( is_dict(Input) -> D = Input ; D = _{} ),
    (   get_dict(kind, D, "fraction_pair"),
        get_dict(left, D, Left), get_dict(right, D, Right),
        dict_num(Left, n, 0, N1), dict_num(Left, d, 0, D1),
        dict_num(Right, n, 0, N2), dict_num(Right, d, 0, D2)
    ->  A = fraction_pair(N1, D1, N2, D2), B = unit(whole)
    ;   get_dict(kind, D, "decimal_pair"),
        get_dict(left, D, Left), get_dict(right, D, Right),
        dict_num(Left, numeral, 0, N1), dict_num(Left, scale, 1, S1),
        dict_num(Right, numeral, 0, N2), dict_num(Right, scale, 1, S2)
    ->  A = decimal_pair(N1, S1, N2, S2), B = ignored
    ;   dict_num(D, a, 0, A),
        dict_num(D, b, 0, B)
    ).

dict_num(Dict, Key, Default, Value) :-
    ( get_dict(Key, Dict, V0), num_value(V0, V) -> Value = V ; Value = Default ).


%% ======================================================================
%% misconception_catalog_dict/2
%% ======================================================================

%!  misconception_catalog_dict(+Filter, -Dict) is det.
%
%   Filter is `all` or a domain atom (e.g. fraction). diagnosable=false when
%   the rule is the `skip` placeholder (too_vague convention).
misconception_catalog_dict(Filter0, _{
        count: Count,
        domains: Domains,
        misconceptions: Misconceptions
    }) :-
    to_atom(Filter0, Filter),
    findall(MDict,
            ( query_misconception_safe(Filter, Domain, Desc, Source, Match),
              misconception_entry_dict(Domain, Desc, Source, Match, MDict)
            ),
            Misconceptions),
    length(Misconceptions, Count),
    findall(DomStr,
            ( member(M, Misconceptions), get_dict(domain, M, DomStr) ),
            DomStrs0),
    sort(DomStrs0, Domains).

%!  query_misconception_safe(+Filter, -Domain, -Desc, -Source, -Match) is nondet.
query_misconception_safe(all, Domain, Desc, Source, Match) :-
    !,
    catch(test_harness:query_misconception(Domain, Desc, Source, Match), _, fail).
query_misconception_safe(Filter, Filter, Desc, Source, Match) :-
    catch(test_harness:query_misconception(Filter, Desc, Source, Match), _, fail).

misconception_entry_dict(Domain, Desc, Source, Match, _{
        domain: DomStr,
        name: NameStr,
        rule: RuleStr,
        diagnosable: Diagnosable,
        citation: CitationStr,
        example: Example
    }) :-
    term_text_string(Domain, DomStr),
    term_text_string(Desc, NameStr),
    misconception_rule(Match, Rule),
    term_text_string(Rule, RuleStr),
    ( misconception_diagnosable(Rule) -> Diagnosable = true ; Diagnosable = false ),
    source_citation_text(Source, CitationStr),
    misconception_example(Domain, Desc, Example).

%!  misconception_example(+Domain, +Name, -Example) is det.
%
%   A concrete worked error this misconception produces: the operands, the
%   WRONG result the rule yields (via test_harness:classify_arith/5), and the
%   correct result. The pretty input/wrong/correct strings are for display;
%   input_term/got_term carry the same Input and Got in raw Prolog term syntax
%   (term_string), which is what /api/diagnose_error parses back — the pretty
%   forms ("1/7 − 1/7") do not round-trip. Empty strings when no runnable
%   arithmetic example exists. Never throws.
misconception_example(Domain, Name, _{input: InStr, wrong: WrongStr, correct: CorrectStr,
                                      input_term: InTermStr, got_term: GotTermStr}) :-
    catch(( once(test_harness:arith_misconception(_, Domain, Name, Rule, Input, Expected)),
            Rule \== skip,
            test_harness:classify_arith(Rule, Input, Expected, _Class, Got)
          ), _, fail),
    !,
    pretty_math(Input, InStr),
    pretty_math(Got, WrongStr),
    pretty_math(Expected, CorrectStr),
    term_string(Input, InTermStr),
    term_string(Got, GotTermStr).
misconception_example(_, _, _{input: "", wrong: "", correct: "",
                              input_term: "", got_term: ""}).

%!  pretty_math(+Term, -String) is det.
%
%   Render an arithmetic corpus term readably: frac(N,D) -> "N/D", binary
%   operators kept with a unicode symbol, everything else stringified.
% Guard against an unbound argument: a var unifies with `A + B` (and the other
% binary patterns below), so without this clause pretty_math(Var) binds Var to
% `_A + _B`, recurses into the fresh `_A`, and generates an unbounded term —
% observed blowing the 1Gb stack at depth ~13M and taking the catalog (and the
% live console) down. Render an unbound term as a plain placeholder instead.
pretty_math(X, S) :- var(X), !, term_string(X, S).
pretty_math(frac(N, D), S) :- number(N), number(D), !, format(string(S), "~w/~w", [N, D]).
pretty_math(A + B, S) :- !, pretty_math_bin(A, '+', B, S).
pretty_math(A - B, S) :- !, pretty_math_bin(A, '−', B, S).
pretty_math(A * B, S) :- !, pretty_math_bin(A, '×', B, S).
pretty_math(A / B, S) :- !, pretty_math_bin(A, '÷', B, S).
pretty_math(X, S) :- term_text_string(X, T), ( number(T) -> format(string(S), "~w", [T]) ; S = T ).

pretty_math_bin(A, Op, B, S) :-
    pretty_math(A, SA), pretty_math(B, SB),
    format(string(S), "~w ~w ~w", [SA, Op, SB]).

misconception_rule(Match, Rule) :-
    ( is_dict(Match), get_dict(rule, Match, R) -> Rule = R
    ; Rule = none                       % geometric entailment rows carry no rule
    ).

%!  misconception_diagnosable(+Rule) is semidet.
%
%   A row is diagnosable unless its rule is the `skip` placeholder or absent.
misconception_diagnosable(Rule) :-
    Rule \== skip,
    Rule \== none,
    nonvar(Rule),
    \+ rule_is_skip(Rule).

rule_is_skip(skip).
rule_is_skip(_:skip).

%!  source_citation_text(+Source, -Str) is det.
%
%   Human-facing citation for a misconception source. A db_row source joins
%   lit_derived_meta/4 so the text leads with the real author/year citation
%   and carries the plain-language gloss; the row id stays at the end as
%   provenance. Rows without a literature analysis keep the bare row label.
source_citation_text(Source, Str) :-
    ( var(Source) -> Str = ""
    ; Source = db_row(Id) -> db_row_citation_text(Id, Str)
    ; Source = erlwanger_1973 -> Str = "Erlwanger 1973 (Benny)"
    ; Source = asktm -> Str = "AskTM corpus"
    ; Source = vocabulary -> Str = "vocabulary-derived"
    ; term_text_string(Source, Str)
    ).

%!  db_row_citation_text(+Id, -Str) is det.
db_row_citation_text(Id, Str) :-
    term_text_string(Id, IdStr),
    (   db_row_literature_meta(Id, Citation, Gloss),
        Citation \== ""
    ->  (   Gloss == ""
        ->  format(string(Str), "~w (db row ~w)", [Citation, IdStr])
        ;   format(string(Str), "~w: ~w (db row ~w)", [Citation, Gloss, IdStr])
        )
    ;   format(string(Str), "literature DB row ~s", [IdStr])
    ).

%!  db_row_literature_meta(+Id, -Citation, -Gloss) is semidet.
%
%   Join a db_row source id to its lit_derived_meta/4 analysis. Meta ids are
%   either the row id itself ('37483') or the row id with an analysis suffix
%   ('290_a', '290_b'); the bare id wins, otherwise the first suffixed
%   analysis stands in for the row. Fails for rows with no analysis.
db_row_literature_meta(Id, Citation, Gloss) :-
    ( atom(Id) -> IdAtom = Id ; term_to_atom(Id, IdAtom) ),
    (   lit_derived_meta(IdAtom, _Bib, Citation0, Gloss0)
    ->  true
    ;   atom_concat(IdAtom, '_', Prefix),
        once(( lit_derived_meta(MetaId, _Bib2, Citation0, Gloss0),
               sub_atom(MetaId, 0, _, _, Prefix) ))
    ),
    term_text_string(Citation0, Citation),
    term_text_string(Gloss0, Gloss).


%% ======================================================================
%% standards_catalog_dict/2
%% ======================================================================

%!  standards_catalog_dict(+Filter, -Dict) is det.
%
%   Filter is `all` or a framework atom (ccss / indiana). Deduped by
%   (framework, code). The im_lesson framework anchors (lesson-title
%   pollution) are excluded. lesson_count is the number of distinct concept
%   anchors that cite the (framework, code) pair; example_lessons lists up to
%   a few of them.
standards_catalog_dict(Filter0, _{
        count: Count,
        frameworks: Frameworks,
        standards: Standards
    }) :-
    to_atom(Filter0, Filter),
    normalize_framework_filter(Filter, FilterFw),
    findall(Fw-Code,
            ( standard_anchor_safe(Concept, RawFw, Code, _Stmt),
              RawFw \== im_lesson,
              normalize_framework(RawFw, Fw),
              framework_matches(FilterFw, Fw),
              nonvar(Concept)
            ),
            FwCodePairs0),
    sort(FwCodePairs0, FwCodePairs),
    findall(StdDict,
            ( member(Fw-Code, FwCodePairs),
              standard_entry_dict(Fw, Code, StdDict)
            ),
            Standards),
    length(Standards, Count),
    findall(FwStr,
            ( member(Std, Standards), get_dict(framework, Std, FwStr) ),
            FwStrs0),
    sort(FwStrs0, Frameworks).

standard_anchor_safe(Concept, Fw, Code, Stmt) :-
    catch(user:standard_anchor(Concept, Fw, Code, Stmt), _, fail).

standard_entry_dict(Fw, Code, _{
        framework: FwStr,
        code: CodeStr,
        statement: StmtStr,
        grade: Grade,
        lesson_count: LessonCount,
        example_lessons: ExampleLessons
    }) :-
    term_text_string(Fw, FwStr),
    term_text_string(Code, CodeStr),
    % Collect every concept anchor for this (framework, code).
    findall(Concept-Stmt,
            ( standard_anchor_safe(Concept, RawFw, Code, Stmt),
              normalize_framework(RawFw, Fw)
            ),
            Anchors0),
    sort(Anchors0, Anchors),
    pairs_keys(Anchors, Concepts0),
    sort(Concepts0, Concepts),
    length(Concepts, LessonCount),
    example_lessons(Concepts, ExampleLessons),
    ( Anchors = [_-Stmt0 | _] -> term_text_string(Stmt0, StmtStr) ; StmtStr = "" ),
    code_grade(Code, Grade).

example_lessons(Concepts, Lessons) :-
    first_n(Concepts, 5, Some),
    maplist(term_text_string, Some, Lessons).

first_n(_, 0, []) :- !.
first_n([], _, []) :- !.
first_n([H | T], N, [H | R]) :-
    N > 0, N1 is N - 1,
    first_n(T, N1, R).

%!  code_grade(+Code, -Grade) is det.
%
%   Leading segment of a standard code is the grade. Numeric grades stay Int;
%   "K" (and anything non-numeric) stays a string.
code_grade(Code, Grade) :-
    term_text_string(Code, CodeStr),
    ( once(sub_string(CodeStr, Before, _, _, "."))
    -> sub_string(CodeStr, 0, Before, _, Head)
    ;  Head = CodeStr
    ),
    ( number_string(N, Head), integer(N)
    -> Grade = N
    ;  Grade = Head
    ).

normalize_framework(in_indiana, indiana) :- !.
normalize_framework(Fw, Fw).

normalize_framework_filter(all, all) :- !.
normalize_framework_filter(indiana, indiana) :- !.
normalize_framework_filter(in_indiana, indiana) :- !.
normalize_framework_filter(Fw, Fw).

framework_matches(all, _) :- !.
framework_matches(Fw, Fw).


%% ======================================================================
%% grounding_catalog_dict/1  and  grounding_for_operation_dict/2
%% ======================================================================

%!  grounding_catalog_dict(-Dict) is det.
grounding_catalog_dict(_{count: Count, metaphors: Metaphors}) :-
    findall(Id,
            grounding_metaphors:grounding_metaphor_definition(Id, _, _, _),
            Ids0),
    sort(Ids0, Ids),
    maplist(metaphor_dict, Ids, Metaphors),
    length(Metaphors, Count).

%!  metaphor_dict(+Id, -Dict) is det.
metaphor_dict(Id, _{
        id: IdStr,
        short_name: ShortStr,
        kind: KindStr,
        source_domain: SourceStr,
        target_domain: TargetStr,
        description: DescStr,
        mappings: Mappings,
        breaks: Breaks,
        repairs: Repairs
    }) :-
    term_text_string(Id, IdStr),
    ( grounding_metaphors:grounding_metaphor_definition(Id, Source, Target, Desc)
    -> true ; Source = '', Target = '', Desc = '' ),
    term_text_string(Source, SourceStr),
    term_text_string(Target, TargetStr),
    term_text_string(Desc, DescStr),
    ( catch(grounding_metaphors:metaphor_short_name(Id, Short), _, fail)
    -> term_text_string(Short, ShortStr) ; ShortStr = IdStr ),
    ( catch(grounding_metaphors:metaphor_kind(Id, Kind), _, fail)
    -> term_text_string(Kind, KindStr) ; KindStr = "" ),
    metaphor_mappings(Id, Mappings),
    metaphor_breaks(Id, Breaks),
    metaphor_repairs(Id, Repairs).

metaphor_mappings(Id, Mappings) :-
    findall(_{source: SrcStr, target: TgtStr, notes: NotesStr},
            ( grounding_metaphors:metaphor_mapping(Id, Src, Tgt, Notes),
              term_text_string(Src, SrcStr),
              term_text_string(Tgt, TgtStr),
              term_text_string(Notes, NotesStr)
            ),
            Mappings).

metaphor_breaks(Id, Breaks) :-
    findall(_{inference: InfStr, reason: ReasonStr},
            ( grounding_metaphors:metaphor_breaks_at(Id, Inf, Reason),
              term_text_string(Inf, InfStr),
              term_text_string(Reason, ReasonStr)
            ),
            Breaks).

metaphor_repairs(Id, Repairs) :-
    findall(_{broken_inference: InfStr, repair_metaphor: RepairStr, mechanism: MechStr},
            ( grounding_metaphors:metaphor_repair(Id, Inf, Repair, Mech),
              term_text_string(Inf, InfStr),
              term_text_string(Repair, RepairStr),
              term_text_string(Mech, MechStr)
            ),
            Repairs).

%!  grounding_for_operation_dict(+Operation, -Dict) is det.
%
%   Metaphors selected by L&N target-concept mapping for the operation. The
%   operation alias is normalized to the target-concept atom(s) L&N use; a
%   metaphor is included iff one of its metaphor_mapping/4 targets matches.
grounding_for_operation_dict(Operation0, _{
        operation: OpStr,
        metaphors: Metaphors,
        coverage_note: Note
    }) :-
    to_atom(Operation0, Operation),
    term_text_string(Operation, OpStr),
    operation_target_concepts(Operation, Targets),
    findall(Id,
            ( grounding_metaphors:metaphor_mapping(Id, _, Target, _),
              member(Target, Targets)
            ),
            Ids0),
    sort(Ids0, Ids),
    maplist(metaphor_dict, Ids, Metaphors),
    ( Metaphors == []
    ->  format(string(Note),
            "No L&N grounding metaphor maps ~w to a source domain in this module. Absence is meaningful: L&N do not ground that operation in any of the four source domains encoded here.",
            [Operation])
    ;   format(string(Note),
            "Metaphors selected by L&N target-concept mapping for ~w; absence of a metaphor here means L&N do not ground that operation in that source domain.",
            [Operation])
    ).

%!  operation_target_concepts(+Operation, -Targets) is det.
%
%   Map an arithmetic operation alias to the L&N target-concept atom(s)
%   used as the third argument of metaphor_mapping/4.
operation_target_concepts(Operation, Targets) :-
    ( operation_alias(Operation, Targets0)
    -> Targets = Targets0
    ;  Targets = [Operation]            % pass through; absence stays meaningful
    ).

operation_alias(add,            [addition]).
operation_alias(addition,       [addition]).
operation_alias(plus,           [addition]).
operation_alias(sub,            [subtraction]).
operation_alias(subtraction,    [subtraction]).
operation_alias(minus,          [subtraction]).
operation_alias(mult,           [multiplication, multiplication_of_positives, multiplication_by_negative_one]).
operation_alias(multiply,       [multiplication, multiplication_of_positives, multiplication_by_negative_one]).
operation_alias(multiplication, [multiplication, multiplication_of_positives, multiplication_by_negative_one]).
operation_alias(times,          [multiplication, multiplication_of_positives, multiplication_by_negative_one]).
operation_alias(div,            [division]).
operation_alias(divide,         [division]).
operation_alias(division,       [division]).
operation_alias(fraction,       [fraction_1_over_n, fraction_m_over_n]).
operation_alias(fractions,      [fraction_1_over_n, fraction_m_over_n]).


%% ======================================================================
%% ground_query_dict/2 — retrieval for the grounded chat
%% ======================================================================

%!  ground_query_dict(+QueryText, -Dict) is det.
%
%   Keyword retrieval over the encoded KB so the chat can ground a Gemma
%   answer in real symbolic facts instead of free-associating. Matches the
%   question's content words against strategy kinds/clusters, misconception
%   names, standard codes/statements, and grounding-metaphor names. Returns a
%   bounded, JSON-safe set of the facts found. Never throws; empty lists when
%   nothing matches (so the chat can honestly say Hermes has no model of it).
ground_query_dict(Query0, _{
        query: QStr,
        matched_terms: Terms,
        strategies: Strategies,
        misconceptions: Misconceptions,
        standards: Standards,
        metaphors: Metaphors,
        geometry: Geometry,
        literature: Literature,
        math_claims: MathClaims,
        total: Total
    }) :-
    term_text_string(Query0, QStr),
    ground_tokens(QStr, Terms),
    % Math claims parse from the raw text, not the tokens: "3/4 = 6/8"
    % tokenizes to nothing, but it is exactly the kind of utterance a teacher
    % brings to the chat, and the domain checker can adjudicate it.
    ground_math_claims(QStr, MathClaims),
    length(MathClaims, NC),
    ( Terms == []
    ->  Strategies = [], Misconceptions = [], Standards = [], Metaphors = [],
        Geometry = [], Literature = [], Total = NC
    ;   ground_strategies(Terms, Strategies),
        ground_misconceptions(Terms, Misconceptions),
        ground_standards(Terms, Standards),
        ground_metaphors(Terms, Metaphors),
        ground_geometry(Terms, Geometry),
        ground_literature(Terms, Literature),
        length(Strategies, NS), length(Misconceptions, NM),
        length(Standards, NSt), length(Metaphors, NMe),
        length(Geometry, NG), length(Literature, NL),
        Total is NS + NM + NSt + NMe + NG + NL + NC
    ).

%!  ground_math_claims(+QueryStr, -Claims) is det.
%
%   Fraction-equivalence claims written in the query text ("a/b = c/d"),
%   adjudicated by the domain checker and joined to the registry context.
%   Fields are flattened to strings so the dict is JSON-safe as built.
%   Other claim shapes (sums, comparisons) are not parsed here yet; the
%   checker's coverage is the boundary, and an unparsed claim simply does
%   not appear rather than appearing wrongly.
ground_math_claims(QStr, Claims) :-
    catch(re_foldl(ground_math_claim_,
                   "(\\d+)\\s*/\\s*(\\d+)\\s*=\\s*(\\d+)\\s*/\\s*(\\d+)",
                   QStr, [], Claims0, []),
          _,
          Claims0 = []),
    reverse(Claims0, Claims).

:- use_module(library(pcre), [re_foldl/6]).

ground_math_claim_(Match, Acc, [Dict|Acc]) :-
    number_string(N1, Match.1), number_string(D1, Match.2),
    number_string(N2, Match.3), number_string(D2, Match.4),
    D1 > 0, D2 > 0,
    ClaimTerm = equivalence(fraction(N1,D1), fraction(N2,D2)),
    check_math_claim(ClaimTerm, Check),
    term_text_string(ClaimTerm, ClaimText),
    ( get_dict(status, Check, Status0) -> term_text_string(Status0, Status) ; Status = "" ),
    ( get_dict(verdict, Check, Verdict0) -> term_text_string(Verdict0, Verdict) ; Verdict = "" ),
    ( get_dict(checker, Check, Checker0) -> term_text_string(Checker0, Checker) ; Checker = "" ),
    math_claim_context_texts(ClaimTerm, ContextTexts),
    Dict = _{ claim: ClaimText,
              status: Status,
              verdict: Verdict,
              checker: Checker,
              context: ContextTexts }.
ground_math_claim_(_, Acc, Acc).

%!  math_claim_context_texts(+ClaimTerm, -Texts) is det.
%
%   Registry context for the claim via math_context_for_claim/2, flattened
%   to a bounded list of strings. Degrades to [] when the context module is
%   not loaded or the claim has no candidates.
math_claim_context_texts(ClaimTerm, Texts) :-
    catch(
        ( math_context:math_context_for_claim(ClaimTerm, Ctx),
          ( get_dict(candidates, Ctx, Cands0), is_list(Cands0)
          -> length(Prefix, 3), ( append(Prefix, _, Cands0) -> Cands = Prefix ; Cands = Cands0 ),
             findall(T, ( member(C, Cands), term_text_string(C, T) ), Texts)
          ;  Texts = []
          )
        ),
        _,
        Texts = []).

%!  ground_tokens(+QueryStr, -Tokens) is det.
%   Lowercase content words (>= 3 chars, not stop-words) from the query.
ground_tokens(QStr, Tokens) :-
    string_lower(QStr, Lower),
    split_string(Lower, " \t\n.,;:!?()[]{}\"'/+-*=", "", Parts),
    findall(T,
            ( member(P, Parts),
              string_length(P, L), L >= 3,
              \+ stop_word(P),
              T = P
            ),
            Tokens0),
    % Teachers speak in halves and gaps; the catalog speaks in machine
    % names. The alias table bridges the community's words to catalog
    % vocabulary so grounding reaches the strategies it should.
    findall(A, ( member(P0, Tokens0), ground_alias(P0, A) ), Aliases),
    append(Tokens0, Aliases, Tokens1),
    list_to_set(Tokens1, Tokens).

%!  ground_alias(+SpokenToken, -CatalogToken) is nondet.
%   Community math-talk words mapped to catalog/machine vocabulary.
ground_alias(W, "fraction") :-
    member(W, ["half", "halves", "third", "thirds", "fourth", "fourths",
               "fifth", "fifths", "sixth", "sixths", "eighth", "eighths",
               "tenth", "tenths", "twelfth", "twelfths", "fifteenths",
               "numerator", "denominator", "denominators"]).
ground_alias(W, "comparison") :-
    member(W, ["compare", "compares", "comparing", "bigger", "smaller",
               "greater", "less", "larger", "order", "ordering", "between",
               "closer", "equivalent"]).
ground_alias("gap", "gap_thinking").
ground_alias("gaps", "gap_thinking").
ground_alias(W, "benchmark") :- member(W, ["half", "halves", "whole"]).
ground_alias(W, "decimal") :- member(W, ["decimal", "decimals", "point"]).
ground_alias(W, "number_line") :- member(W, ["line", "jump", "jumps"]).
ground_alias(W, "area_model") :- member(W, ["shaded", "shading", "pieces", "partition", "partitions", "partitioned"]).
ground_alias(W, "set_model") :- member(W, ["collection", "counters", "objects"]).

stop_word("the"). stop_word("and"). stop_word("for"). stop_word("are").
stop_word("you"). stop_word("how"). stop_word("why"). stop_word("what").
stop_word("does"). stop_word("can"). stop_word("with"). stop_word("that").
stop_word("this"). stop_word("when"). stop_word("they"). stop_word("them").
stop_word("students"). stop_word("student"). stop_word("kids"). stop_word("about").
stop_word("would"). stop_word("could"). stop_word("should"). stop_word("from").
stop_word("their"). stop_word("there"). stop_word("which"). stop_word("into").

%!  token_hits(+Tokens, +Haystack) is semidet.
%   Some token is a substring of the (lowercased) haystack string.
token_hits(Tokens, Haystack) :-
    string_lower(Haystack, H),
    member(T, Tokens),
    sub_string(H, _, _, _, T),
    !.

ground_strategies(Tokens, Out) :-
    strategy_catalog_dict(SC),
    get_dict(strategies, SC, All),
    findall(_{operation: Op, kind: Kind, cluster: Cluster, runnable: HasFSM},
            ( member(S, All),
              get_dict(kind, S, Kind), get_dict(operation, S, Op),
              get_dict(cluster, S, Cluster), get_dict(has_fsm, S, HasFSM),
              format(string(Hay), "~w ~w ~w", [Op, Kind, Cluster]),
              token_hits(Tokens, Hay)
            ),
            All0),
    first_n(All0, 6, Out).

%!  ground_misconceptions(+Tokens, -Out) is det.
%
%   Two additive sources. First the native catalog, by token overlap against
%   misconception names, exactly as before (same dict shape, same bound of 6).
%   Then the literature-derived head rules: matches from the deontic edge
%   graph (misconceptions/literature_deontic_bridge.pl), each labeled
%   `source: "literature"` so a teacher can tell which register a match came
%   from. The literature entries never displace catalog entries.
ground_misconceptions(Tokens, Out) :-
    misconception_catalog_dict(all, MC),
    get_dict(misconceptions, MC, All),
    findall(_{domain: Dom, name: Name, rule: Rule, example: Ex},
            ( member(M, All),
              get_dict(name, M, Name),
              token_hits(Tokens, Name),
              get_dict(domain, M, Dom), get_dict(rule, M, Rule), get_dict(example, M, Ex)
            ),
            All0),
    first_n(All0, 6, CatalogOut),
    ground_lit_head_misconceptions(Tokens, LitOut),
    append(CatalogOut, LitOut, Out).

%!  ground_lit_head_misconceptions(+Tokens, -Out) is det.
%
%   Conservative literature matches for the chat's misconception slot: only
%   the sr_* head rules that carry a derived deontic edge (high-confidence,
%   deficit-oriented, core-domain corpus rows) are candidates, and a head
%   matches only when at least two distinct query tokens hit its rule text.
%   The two-token floor keeps a single generic word ("fraction") from
%   surfacing the whole graph. Each entry carries the colliding canonical
%   commitment and a deontic verdict obtained by actually running the
%   scorekeeper on the head rule (lit_deontic_probe/2), so chat scoring
%   exercises the literature -> scorekeeper wire rather than reading a table.
%   Bounded (4), ranked by distinct-token hits; never throws — degrades to []
%   if the bridge is unavailable.
ground_lit_head_misconceptions(Tokens, Out) :-
    catch(lit_head_matches(Tokens, Out), _, Out = []).

lit_head_matches(Tokens, Out) :-
    findall(Sr, lit_deontic_edge(Sr, _, _), Srs0),
    sort(Srs0, Srs),
    findall(Score-Dict,
            ( member(Sr, Srs),
              lit_head_score(Tokens, Sr, Score),
              Score >= 2,
              lit_head_dict(Sr, Dict)
            ),
            Pairs),
    sort(0, @>=, Pairs, Ranked),
    pairs_values(Ranked, Dicts),
    first_n(Dicts, 4, Out).

%!  lit_head_score(+Tokens, +SrRule, -Score) is det.
%   Number of distinct query tokens that occur in the head rule's text
%   (underscores read as spaces).
lit_head_score(Tokens, Sr, Score) :-
    atomic_list_concat(Words, '_', Sr),
    atomic_list_concat(Words, ' ', HayAtom),
    atom_string(HayAtom, Hay),
    string_lower(Hay, H),
    % once/1 so a token repeated in the rule text ("larger ... larger")
    % still counts as one distinct hit.
    aggregate_all(count,
                  ( member(T, Tokens), once(sub_string(H, _, _, _, T)) ),
                  Score).

%!  lit_head_dict(+SrRule, -Dict) is semidet.
%
%   One chat entry per matched head. `name` is the canonical head rule;
%   `incompatible_with`/`commitment_label` name the colliding canonical
%   commitment (the edge with the most supporting rows when a head has
%   several); `support` counts that edge's corpus rows; `citation` is one
%   supporting row's citation; `deontic` is the scorekeeper verdict from
%   the probe.
lit_head_dict(Sr, _{ source: "literature",
                     name: NameStr,
                     domain: DomainStr,
                     incompatible_with: CommitmentStr,
                     commitment_label: LabelStr,
                     support: Support,
                     citation: Citation,
                     deontic: DeonticStr }) :-
    findall(N-(C-Ids),
            ( lit_deontic_edge(Sr, C, Ids), length(Ids, N) ),
            Weighted),
    sort(0, @>=, Weighted, [_N-(Commitment-SupportIds)|_]),
    term_text_string(Sr, NameStr),
    term_text_string(Commitment, CommitmentStr),
    (   canonical_commitment(Commitment, Label0)
    ->  term_text_string(Label0, LabelStr)
    ;   LabelStr = ""
    ),
    length(SupportIds, Support),
    lit_support_domains(SupportIds, Commitment, DomainStr),
    lit_support_citation(SupportIds, Citation),
    (   catch(lit_deontic_probe(Sr, Verdict), _, fail)
    ->  term_text_string(Verdict, DeonticStr)
    ;   DeonticStr = ""
    ).

%!  lit_support_domains(+Ids, +Commitment, -DomainStr) is det.
%   The canonical domains of the supporting rows, slash-joined.
lit_support_domains(Ids, Commitment, DomainStr) :-
    findall(D,
            ( member(Id, Ids),
              lit_incompatibility(Id, D, Commitment, _, _, deficit, high)
            ),
            Ds0),
    sort(Ds0, Ds),
    (   Ds == []
    ->  DomainStr = ""
    ;   atomic_list_concat(Ds, '/', DAtom),
        term_text_string(DAtom, DomainStr)
    ).

%!  lit_support_citation(+Ids, -Citation) is det.
%   First nonempty citation among the supporting rows; "" when none carries one.
lit_support_citation(Ids, Citation) :-
    (   member(Id, Ids),
        lit_derived_meta(Id, _, Citation0, _),
        Citation0 \== ''
    ->  term_text_string(Citation0, Citation)
    ;   Citation = ""
    ).

ground_standards(Tokens, Out) :-
    standards_catalog_dict(all, StC),
    get_dict(standards, StC, All),
    findall(_{framework: Fw, code: Code, statement: Stmt},
            ( member(S, All),
              get_dict(code, S, Code), get_dict(statement, S, Stmt), get_dict(framework, S, Fw),
              format(string(Hay), "~w ~w", [Code, Stmt]),
              token_hits(Tokens, Hay)
            ),
            All0),
    first_n(All0, 6, Out).

ground_metaphors(Tokens, Out) :-
    grounding_catalog_dict(GC),
    get_dict(metaphors, GC, All),
    findall(_{short_name: Short, description: Desc, breaks: BreakCount},
            ( member(Me, All),
              get_dict(short_name, Me, Short), get_dict(description, Me, Desc),
              get_dict(id, Me, Id), get_dict(breaks, Me, Breaks), length(Breaks, BreakCount),
              format(string(Hay), "~w ~w ~w", [Short, Id, Desc]),
              token_hits(Tokens, Hay)
            ),
            All0),
    first_n(All0, 4, Out).

ground_geometry(Tokens, Out) :-
    catch(
        ( user:matching_concepts(Tokens, any, Concepts),
          first_n(Concepts, 6, Top),
          maplist(ground_geometry_concept_dict, Top, Out)
        ),
        _,
        Out = []
    ).

ground_geometry_concept_dict(concept(Id, Name, Topic, Score),
                             _{concept: IdText,
                               name: NameText,
                               topic: TopicText,
                               score: ScoreValue}) :-
    term_text_string(Id, IdText),
    term_text_string(Name, NameText),
    term_text_string(Topic, TopicText),
    ( Score = score(ScoreValue) -> true ; ScoreValue = Score ).

%!  ground_literature(+Tokens, -Out) is det.
%
%   Bounded literature retrieval for the grounded chat: the four best-matching
%   literature-derived incompatibility analyses, compact form.
ground_literature(Tokens, Out) :-
    lit_top_cases(Tokens, 4, Cases),
    findall(_{id: IdStr, domain: Domain, student_rule: StudentRule,
              valid_domain: ValidDomain, incompatible_with: Incompat,
              commitment: Commitment, citation: Citation},
            ( member(Case, Cases),
              get_dict(id, Case, IdStr), get_dict(domain, Case, Domain),
              get_dict(student_rule, Case, StudentRule),
              get_dict(valid_domain, Case, ValidDomain),
              get_dict(incompatible_with, Case, Incompat),
              get_dict(commitment, Case, Commitment),
              get_dict(citation, Case, Citation)
            ),
            Out).


%% ======================================================================
%% literature_search_dict/2 — the derived-incompatibility corpus
%% ======================================================================

%!  literature_search_dict(+QueryText, -Dict) is det.
%
%   Keyword retrieval over the 3,711 literature-derived incompatibility
%   analyses (misconceptions/literature_incompatibility_facts.pl): each case
%   carries the Brandomian triple — the rule the student appears to follow,
%   the domain where that rule IS valid, and the normative commitment it
%   collides with — plus the canonical-commitment mapping, citation, and
%   bibtex key (empty for the many rows where no key is backfilled yet).
%   Bounded (12 cases); corpus stats ride along so a caller can present
%   coverage honestly. Never throws; empty cases for an empty query.
literature_search_dict(Query0, _{
        query: QStr,
        matched_terms: Terms,
        corpus: _{total: Total, mapped: Mapped, uncategorized: Uncategorized,
                  percent_mapped: PercentMapped, adjudicated: Adjudicated},
        count: Count,
        cases: Cases
    }) :-
    term_text_string(Query0, QStr),
    ground_tokens(QStr, Terms),
    literature_mapping_stats(Total, Mapped, Uncategorized, PercentMapped),
    literature_adjudicated_count(Adjudicated),
    (   Terms == []
    ->  Cases = []
    ;   lit_top_cases(Terms, 12, Cases)
    ),
    length(Cases, Count).

%!  lit_top_cases(+Tokens, +N, -Cases) is det.
%
%   The N case dicts whose haystacks match the most distinct query tokens.
%   Ranking by match count (not fact order) keeps a one-token wildcard like
%   "add" from crowding out the rows that match the whole question.
lit_top_cases(Tokens, N, Cases) :-
    findall(Score-Id,
            ( lit_derived(Id, Domain, Topic, StudentRule, ValidDomain,
                          IncompatRaw, _Orientation, _Scene, _Confidence),
              % The bibkey is deliberately not part of the search haystack:
              % it names a bibtex entry, not analysis text, and most rows
              % carry none. It rides on the case dicts instead.
              (   lit_derived_meta(Id, _, Citation, Gloss)
              ->  true
              ;   Citation = '', Gloss = ''
              ),
              format(string(Hay), "~w ~w ~w ~w ~w ~w ~w",
                     [Domain, Topic, StudentRule, ValidDomain, IncompatRaw,
                      Citation, Gloss]),
              lit_token_score(Tokens, Hay, Score),
              Score > 0
            ),
            Pairs),
    sort(0, @>=, Pairs, Ranked),
    first_n(Ranked, N, Top),
    findall(Case, ( member(_-Id, Top), lit_case_dict(Id, Case) ), Cases).

lit_token_score(Tokens, Haystack, Score) :-
    string_lower(Haystack, H),
    aggregate_all(count,
                  ( member(T, Tokens), sub_string(H, _, _, _, T) ),
                  Score).

%!  lit_case_dict(+Id, -Dict) is semidet.
lit_case_dict(Id, _{
        id: IdStr,
        domain: DomainStr,
        topic: TopicStr,
        student_rule: StudentRuleStr,
        valid_domain: ValidDomainStr,
        incompatible_with: IncompatStr,
        commitment: CommitmentStr,
        commitment_label: Label,
        citation: Citation,
        bibkey: Bibkey,
        gloss: Gloss,
        orientation: OrientationStr,
        confidence: ConfidenceStr
    }) :-
    lit_derived(Id, Domain, Topic, StudentRule, ValidDomain, IncompatRaw,
                Orientation, _Scene, Confidence),
    term_text_string(Id, IdStr),
    term_text_string(Domain, DomainStr),
    term_text_string(Topic, TopicStr),
    term_text_string(StudentRule, StudentRuleStr),
    term_text_string(ValidDomain, ValidDomainStr),
    term_text_string(IncompatRaw, IncompatStr),
    term_text_string(Orientation, OrientationStr),
    term_text_string(Confidence, ConfidenceStr),
    (   lit_derived_meta(Id, Bib0, Citation0, Gloss0)
    ->  term_text_string(Citation0, Citation), term_text_string(Gloss0, Gloss),
        term_text_string(Bib0, Bibkey)
    ;   Citation = "", Gloss = "", Bibkey = ""
    ),
    (   lit_incompatibility(Id, _CanonDomain, Commitment0, _SR, _VD, _O, _C),
        Commitment0 \== uncategorized
    ->  term_text_string(Commitment0, CommitmentStr),
        (   canonical_commitment(Commitment0, Label0)
        ->  term_text_string(Label0, Label)
        ;   Label = ""
        )
    ;   CommitmentStr = "uncategorized", Label = ""
    ).


%% ======================================================================
%% pml_score_dict/2 — validate + score model-emitted PML axioms
%% ======================================================================
%
%   The neuro-symbolic loop: Gemma emits reader_axiom/4 + passage_mode/3 facts
%   (the PML encoding of a text), and THIS validates and scores them against the
%   12 legal operators. SAFETY: clause strings are PARSED with term_string/2
%   (read-only) and matched structurally — they are never consulted or executed,
%   so an LLM emitting `:- shell(...)` cannot run anything. Anything that is not
%   a well-formed reader_axiom/4 or passage_mode/3 is rejected with a reason.

pml_mode(s, "subjective").
pml_mode(o, "objective").
pml_mode(n, "normative").

% Third arg is the operator's polarity in the SAME vocabulary the reader_axiom/4
% 4th argument uses (compressive/expansive), so the coherence check can compare
% them directly.
pml_modal_op(comp_nec,  necessity,   compressive).
pml_modal_op(exp_nec,   necessity,   expansive).
pml_modal_op(comp_poss, possibility, compressive).
pml_modal_op(exp_poss,  possibility, expansive).

%!  pml_score_dict(+ClauseStrings, -Dict) is det.
pml_score_dict(ClauseStrings0, Dict) :-
    ( is_list(ClauseStrings0) -> ClauseStrings = ClauseStrings0 ; ClauseStrings = [] ),
    findall(R, ( member(C, ClauseStrings), parse_pml_clause(C, R) ), Results),
    findall(A0, member(axiom(A0), Results), Axioms0),
    findall(MA, member(math_action(MA), Results), MathActionsInternal),
    findall(MC, member(math_claim(MC), Results), MathClaims),
    attach_math_actions(Axioms0, MathActionsInternal, Axioms1),
    attach_math_claims(Axioms1, MathClaims, Axioms),
    maplist(math_action_public_dict, MathActionsInternal, MathActions),
    findall(P, member(passage(P), Results), PassageModes),
    findall(_{clause: Cs, reason: Rn}, member(rejected(Cs, Rn), Results), Rejected),
    length(Axioms, ValidCount),
    length(ClauseStrings, Total),
    pml_incompatibilities(Axioms, Incompatibilities),
    pml_polarity_mismatches(Axioms, PolarityMismatches),
    pml_profile(Axioms, Incompatibilities, Profile),
    Dict = _{
        clause_count: Total,
        valid_count: ValidCount,
        axioms: Axioms,
        math_actions: MathActions,
        incompatibilities: Incompatibilities,
        polarity_mismatches: PolarityMismatches,
        passage_modes: PassageModes,
        rejected: Rejected,
        profile: Profile
    }.

%% validate_reader_axioms_dict/3 — SEAM 2 post-hoc reader_axiom validator
%
% Compare model-emitted reader_axiom/4 facts against the modal postures the
% lesson text itself licenses (the monitoring chart's PMLFacts, recovered here
% through text_interpreter:interpret_lesson_text/2). This is the cleanest
% demonstration that the Prolog layer adds something auditable: it says, per
% submitted axiom, whether the reading's (mode, polarity) posture is one the
% lesson anticipated, conflicts in polarity with an anticipated posture, or is
% novel. It does not decide whether a novel reading is insight or noise — that
% boundary is left to human judgment.

%!  validate_reader_axioms_dict(+LessonCode, +ClauseStrings, -Dict) is det.
validate_reader_axioms_dict(LessonCode, ClauseStrings0, Dict) :-
    ( is_list(ClauseStrings0) -> ClauseStrings = ClauseStrings0 ; ClauseStrings = [] ),
    lesson_licensed_postures(LessonCode, LicensedPostures),
    maplist(licensed_posture_dict, LicensedPostures, LicensedDicts),
    findall(R, ( member(C, ClauseStrings), validate_axiom_clause(C, LicensedPostures, R) ), Results),
    aggregate_verdicts(Results, Summary),
    ( atom(LessonCode) -> atom_string(LessonCode, CodeStr) ; term_text_string(LessonCode, CodeStr) ),
    length(ClauseStrings, Total),
    length(LicensedPostures, LicensedCount),
    Dict = _{
        lesson_code: CodeStr,
        licensed_posture_count: LicensedCount,
        licensed_postures: LicensedDicts,
        clause_count: Total,
        results: Results,
        summary: Summary
    }.

%!  lesson_licensed_postures(+LessonCode, -Postures) is det.
%   The sorted set of Mode-Polarity postures the lesson text licenses.
lesson_licensed_postures(LessonCode, Postures) :-
    ( catch(interpret_lesson_text(LessonCode, Facts), _, fail) -> true ; Facts = [] ),
    findall(P, ( member(F, Facts), chart_posture(F, P) ), P0),
    sort(P0, Postures).

%!  chart_posture(+ReaderAxiomTerm, -ModeStr-PolarityStr) is semidet.
chart_posture(reader_axiom(_Id, _Premises, Conclusion, _Polarity), ModeStr-PolStr) :-
    contains_functor(Conclusion, [s, o, n], ModeAtom),
    contains_functor(Conclusion, [comp_nec, exp_nec, comp_poss, exp_poss], OpAtom),
    pml_mode(ModeAtom, ModeStr),
    pml_modal_op(OpAtom, _Modality, PolAtom),
    atom_string(PolAtom, PolStr).

licensed_posture_dict(ModeStr-PolStr, _{mode: ModeStr, polarity: PolStr}).

%!  validate_axiom_clause(+String, +Licensed, -Result) is det.
validate_axiom_clause(String, Licensed, Result) :-
    parse_pml_clause(String, Parsed),
    ( Parsed = axiom(D)
    ->  get_dict(id, D, Id),
        get_dict(mode, D, Mode),
        get_dict(operator, D, Operator),
        get_dict(polarity, D, Polarity),
        posture_verdict(Mode, Polarity, Licensed, Verdict),
        Result = _{ id: Id, status: "checked", mode: Mode,
                    operator: Operator, polarity: Polarity, verdict: Verdict }
    ;   Parsed = rejected(Cs, Reason)
    ->  Result = _{ clause: Cs, status: "rejected", verdict: "not_checked", reason: Reason }
    ;   Result = _{ clause: String, status: "skipped", verdict: "not_checked",
                    reason: "not a reader_axiom/4 fact" }
    ).

%!  posture_verdict(+Mode, +Polarity, +Licensed, -Verdict) is det.
posture_verdict(_, _, [], "no_chart") :- !.
posture_verdict(Mode, Polarity, Licensed, "matched") :-
    memberchk(Mode-Polarity, Licensed), !.
posture_verdict(Mode, _, Licensed, "polarity_conflict") :-
    memberchk(Mode-_, Licensed), !.
posture_verdict(_, _, _, "novel").

%!  aggregate_verdicts(+Results, -Summary) is det.
aggregate_verdicts(Results, Summary) :-
    findall(V, ( member(R, Results), get_dict(verdict, R, V) ), Verdicts),
    count_value(Verdicts, "matched", Matched),
    count_value(Verdicts, "polarity_conflict", PolarityConflict),
    count_value(Verdicts, "novel", Novel),
    count_value(Verdicts, "no_chart", NoChart),
    count_value(Verdicts, "not_checked", NotChecked),
    Summary = _{
        matched: Matched,
        polarity_conflict: PolarityConflict,
        novel: Novel,
        no_chart: NoChart,
        not_checked: NotChecked
    }.

count_value([], _, 0).
count_value([X|Xs], Value, Count) :-
    count_value(Xs, Value, Count0),
    ( X == Value -> Count is Count0 + 1 ; Count = Count0 ).

math_action_public_dict(MA0, _{
        axiom_id: AxiomId,
        operation: Operation,
        kind: Kind,
        left: Left,
        right: Right
    }) :-
    get_dict(axiom_id, MA0, AxiomId),
    get_dict(operation, MA0, Operation),
    get_dict(kind, MA0, Kind),
    get_dict(left, MA0, Left),
    get_dict(right, MA0, Right).

%!  parse_pml_clause(+String, -Result) is det.
parse_pml_clause(String, Result) :-
    ( catch(term_string(Term, String), _, fail)
    ->  classify_pml_term(Term, String, Result)
    ;   Result = rejected(String, "not parseable as a Prolog term")
    ).

classify_pml_term(reader_axiom(Id, Premises, Conclusion, Polarity), String, Result) :-
    !,
    ( pml_axiom_dict(Id, Premises, Conclusion, Polarity, Dict)
    ->  Result = axiom(Dict)
    ;   Result = rejected(String, "reader_axiom has no legal mode/operator in its conclusion")
    ).
classify_pml_term(passage_mode(Id, Mode, Reading), _String, passage(Dict)) :-
    !,
    term_text_string(Id, IdStr),
    term_text_string(Mode, ModeStr),
    term_text_string(Reading, ReadStr),
    Dict = _{ id: IdStr, mode: ModeStr, reading: ReadStr }.
classify_pml_term(math_action(AxiomId, Operation, Kind, Left, Right), _String, math_action(Dict)) :-
    !,
    term_text_string(AxiomId, AxiomIdStr),
    term_text_string(Operation, OperationStr),
    term_text_string(Kind, KindStr),
    term_text_string(Left, LeftStr),
    term_text_string(Right, RightStr),
    Dict = _{
        axiom_id: AxiomIdStr,
        operation: OperationStr,
        kind: KindStr,
        left: LeftStr,
        right: RightStr,
        left_term: Left,
        right_term: Right
    }.
classify_pml_term(math_claim(AxiomId, ClaimTerm), _String, math_claim(Dict)) :-
    !,
    term_text_string(AxiomId, AxiomIdStr),
    check_math_claim(ClaimTerm, Validation),
    % Keep the raw claim term so attach_math_claims/3 can compute the
    % suggestive math_context. math_validation (truth) and math_context
    % (suggestive) stay SEPARATE fields (Hard Rule 4).
    Dict = _{ axiom_id: AxiomIdStr, validation: Validation, claim_term: ClaimTerm }.
classify_pml_term(_Other, String, rejected(String, "not a reader_axiom/4 or passage_mode/3 fact")).

%!  pml_axiom_dict(+Id, +Premises, +Conclusion, +Polarity, -Dict) is semidet.
%   Extract the mode (s/o/n) and modal operator (comp_nec/…/exp_poss) from the
%   conclusion term — they may nest in either order — and record whether the
%   stated polarity agrees with the operator's polarity (a coherence check).
pml_axiom_dict(Id, Premises, Conclusion, Polarity, _{
        id: IdStr,
        premises: PremiseStrs,
        mode: ModeStr,
        operator: OpStr,
        modality: ModalityStr,
        polarity: PolStr,
        content: ContentStr,
        stated_polarity: StatedPolStr,
        polarity_match: PolarityMatch,
        coherent: Coherent,
        math_validation: MathValidation,
        formal: FormalStr
    }) :-
    contains_functor(Conclusion, [s, o, n], ModeAtom),
    contains_functor(Conclusion, [comp_nec, exp_nec, comp_poss, exp_poss], OpAtom),
    pml_mode(ModeAtom, ModeStr),
    pml_modal_op(OpAtom, Modality, Polarity0),
    term_text_string(Id, IdStr),
    term_text_string(OpAtom, OpStr),
    term_text_string(Modality, ModalityStr),
    term_text_string(Polarity0, PolStr),
    pml_operator_content(Conclusion, OpAtom, ContentStr),
    term_text_string(Polarity, StatedPolStr),
    premise_strings(Premises, PremiseStrs),
    ( Polarity == Polarity0 -> PolarityMatch = true ; PolarityMatch = false ),
    % Deprecated compatibility alias: this used to be called "coherent".
    % It is only a polarity-slot agreement check, not logical coherence.
    Coherent = PolarityMatch,
    pml_math_validation(ContentStr, MathValidation),
    term_text_string(Conclusion, FormalStr).

premise_strings(Premises, PremiseStrs) :-
    ( is_list(Premises)
    -> maplist(term_text_string, Premises, PremiseStrs)
    ;  term_text_string(Premises, PremiseStr),
       PremiseStrs = [PremiseStr]
    ).

%!  pml_incompatibilities(+Axioms, -Incompatibilities) is det.
%   First-pass PML incompatibility semantics. This deliberately does not treat
%   polarity-slot mismatches as contradictions. It reports narrow material
%   clashes where two parsed axioms make contrary necessity claims over the same
%   content in the same validity mode.
pml_incompatibilities(Axioms, Incompatibilities) :-
    findall(I,
            ( select(A, Axioms, Rest),
              member(B, Rest),
              pml_axiom_incompatibility(A, B, I)
            ),
            Raw),
    sort(Raw, Incompatibilities).

pml_axiom_incompatibility(A, B, _{
        kind: "contrary_necessities_same_content",
        content: Content,
        mode: Mode,
        axiom_ids: [AId, BId],
        operators: [AOp, BOp],
        reason: "same content and mode are marked both compressive-necessary and expansive-necessary"
    }) :-
    get_dict(content, A, Content),
    get_dict(content, B, Content),
    Content \== "",
    get_dict(mode, A, Mode),
    get_dict(mode, B, Mode),
    get_dict(operator, A, AOp),
    get_dict(operator, B, BOp),
    contrary_necessity_ops(AOp, BOp),
    get_dict(id, A, AId0),
    get_dict(id, B, BId0),
    AId0 @< BId0,
    sort([AId0, BId0], [AId, BId]).

contrary_necessity_ops("comp_nec", "exp_nec").
contrary_necessity_ops("exp_nec", "comp_nec").

pml_polarity_mismatches(Axioms, Mismatches) :-
    findall(_{
                axiom_id: Id,
                content: Content,
                operator: Op,
                operator_polarity: Expected,
                stated_polarity: Stated,
                reason: "reader_axiom fourth argument does not match the polarity implied by the modal operator"
            },
            ( member(A, Axioms),
              get_dict(polarity_match, A, false),
              get_dict(id, A, Id),
              get_dict(content, A, Content),
              get_dict(operator, A, Op),
              get_dict(polarity, A, Expected),
              get_dict(stated_polarity, A, Stated)
            ),
            Mismatches).

%!  contains_functor(+Term, +Names, -Found) is semidet.
%   First subterm (pre-order) whose principal functor (arity 1) is in Names.
contains_functor(Term, Names, Found) :-
    compound(Term),
    functor(Term, F, 1),
    memberchk(F, Names),
    !,
    Found = F.
contains_functor(Term, Names, Found) :-
    compound(Term),
    arg(_, Term, Sub),
    contains_functor(Sub, Names, Found),
    !.

%!  pml_operator_content(+Conclusion, +OpAtom, -ContentStr) is det.
pml_operator_content(Conclusion, OpAtom, ContentStr) :-
    ( find_op_arg(Conclusion, OpAtom, Arg)
    ->  term_text_string(Arg, ContentStr)
    ;   ContentStr = ""
    ).
find_op_arg(Term, OpAtom, Arg) :-
    compound(Term),
    functor(Term, OpAtom, 1),
    !,
    arg(1, Term, Arg).
find_op_arg(Term, OpAtom, Arg) :-
    compound(Term),
    arg(_, Term, Sub),
    find_op_arg(Sub, OpAtom, Arg),
    !.

%!  pml_math_validation(+ContentStr, -Dict) is det.
%   Bridge selected opaque PML content atoms to domain automata. This is
%   intentionally partial: uncovered atoms say not_covered instead of pretending
%   that PML notation alone proves mathematical truth.
pml_math_validation(ContentStr, Dict) :-
    pml_math_validation_(ContentStr, Dict),
    !.
pml_math_validation(ContentStr, _{
        status: "not_covered",
        content: ContentStr,
        verdict: "not_checked",
        adjudication: "not_in_registered_domain",
        reason: "no domain checker is registered for this PML content atom"
    }).

pml_math_validation_(ContentStr, _{
        status: "domain_checked",
        content: ContentStr,
        domain: "algebraic_linear_patterns",
        checker: "algebraic_action_pairs:linear_pattern_contextual_rule",
        claim: "linear patterns can be instantiated by preserving a constant difference from row to row",
        verdict: "schema_instantiated",
        adjudication: "underdetermined",
        result: ResultStr,
        trace: TraceStrs
    }) :-
    memberchk(ContentStr, ["linear_means_constant_difference", "constant_rate_is_straight_line"]),
    once(run_algebraic_action(linear_pattern_contextual_rule,
                              linear_pattern(first(3), change(-1), row(5)),
                              transcript_claim(ContentStr),
                              Outcome,
                              Trace)),
    Outcome = action_outcome(linear_pattern_contextual_rule, Fields),
    member(result(Result), Fields),
    term_text_string(Result, ResultStr),
    maplist(term_text_string, Trace, TraceStrs).

%!  attach_math_claims(+Axioms, +MathClaims, -Axioms) is det.
%   A math_claim carries a truth-checked verdict (holds/refuted), so when one
%   exists for an axiom it becomes that axiom's math_validation, overriding any
%   weaker "action_executed" status from a math_action.
attach_math_claims([], _MathClaims, []).
attach_math_claims([A0|Rest0], MathClaims, [A|Rest]) :-
    get_dict(id, A0, Id),
    (   member(MC, MathClaims), get_dict(axiom_id, MC, Id)
    ->  get_dict(validation, MC, MV),
        A1 = A0.put(math_validation, MV),
        % Suggestive related context, computed from the raw claim term and kept
        % in a SEPARATE field from math_validation (truth). Guarded so a context
        % failure never blocks the verdict.
        (   get_dict(claim_term, MC, ClaimTerm),
            catch(math_context_for_claim(ClaimTerm, MathContext), _, fail)
        ->  A = A1.put(math_context, MathContext)
        ;   A = A1
        )
    ;   A = A0
    ),
    attach_math_claims(Rest0, MathClaims, Rest).

attach_math_actions([], _MathActions, []).
attach_math_actions([A0|Rest0], MathActions, [A|Rest]) :-
    get_dict(id, A0, Id),
    findall(MA, (member(MA, MathActions), get_dict(axiom_id, MA, Id)), Matches),
    (   Matches = [MA|_]
    ->  math_action_validation(MA, MV),
        A = A0.put(math_validation, MV)
    ;   A = A0
    ),
    attach_math_actions(Rest0, MathActions, Rest).

math_action_validation(MA, Dict) :-
    get_dict(operation, MA, OperationStr),
    get_dict(kind, MA, KindStr),
    get_dict(left_term, MA, Left),
    get_dict(right_term, MA, Right),
    atom_string(Operation, OperationStr),
    atom_string(Kind, KindStr),
    (   catch(action_automata_registry:run_action_automaton(Operation, Kind, Left, Right, Outcome, Trace), _, fail)
    ->  Outcome = action_outcome(_OutcomeKind, Fields),
        action_result_string(Fields, ResultStr),
        maplist(term_text_string, Trace, TraceStrs),
        action_hook_dict(Operation, Outcome, HookDict),
        Base = _{
            status: "domain_checked",
            operation: OperationStr,
            kind: KindStr,
            checker: "action_automata_registry:run_action_automaton",
            verdict: "action_executed",
            adjudication: "underdetermined",
            result: ResultStr,
            trace: TraceStrs
        },
        Dict = Base.put(_{hook: HookDict})
    ;   format(string(Reason), "math_action/5 did not match a registered executable action: ~s:~s", [OperationStr, KindStr]),
        Dict = _{
            status: "not_covered",
            operation: OperationStr,
            kind: KindStr,
            verdict: "not_checked",
            adjudication: "not_in_registered_domain",
            reason: Reason
        }
    ).

action_result_string(Fields, ResultStr) :-
    (   member(result(Result), Fields)
    ->  term_text_string(Result, ResultStr)
    ;   ResultStr = ""
    ).

action_hook_dict(Operation, Outcome, HookDict) :-
    (   catch(action_automata_registry:action_automaton_hook(Operation, Outcome, Family, Hook), _, fail)
    ->  term_text_string(Family, FamilyStr),
        term_text_string(Hook, HookStr),
        HookDict = _{family: FamilyStr, detail: HookStr}
    ;   HookDict = _{}
    ).

%!  pml_profile(+Axioms, +Incompatibilities, -Profile) is det.
pml_profile(Axioms, Incompatibilities, _{
        mode: _{ subjective: SubC, objective: ObjC, normative: NormC },
        modality: _{ necessity: NecC, possibility: PossC },
        polarity: _{ compressive: CompC, expansive: ExpC },
        dominant_mode: DomMode,
        dominant_polarity: DomPol,
        polarity_mismatches: PolarityMismatchCount,
        incompatibility_count: IncompatibilityCount,
        incoherent_axioms: IncoherentCount
    }) :-
    count_field(Axioms, mode, "subjective", SubC),
    count_field(Axioms, mode, "objective", ObjC),
    count_field(Axioms, mode, "normative", NormC),
    count_field(Axioms, modality, "necessity", NecC),
    count_field(Axioms, modality, "possibility", PossC),
    count_field(Axioms, polarity, "compressive", CompC),
    count_field(Axioms, polarity, "expansive", ExpC),
    dominant_label([SubC-"subjective", ObjC-"objective", NormC-"normative"], DomMode),
    dominant_label([CompC-"compressive", ExpC-"expansive"], DomPol),
    aggregate_all(count, ( member(A, Axioms), get_dict(polarity_match, A, false) ), PolarityMismatchCount),
    length(Incompatibilities, IncompatibilityCount),
    % Deprecated compatibility alias. Prefer polarity_mismatches.
    IncoherentCount = PolarityMismatchCount.

count_field(Axioms, Key, Value, Count) :-
    aggregate_all(count, ( member(A, Axioms), get_dict(Key, A, Value) ), Count).

dominant_label(Pairs, Label) :-
    ( max_member(MaxC-Label0, Pairs), MaxC > 0
    ->  Label = Label0
    ;   Label = "none"
    ).


%% ======================================================================
%% helpers
%% ======================================================================

%!  to_atom(+Value, -Atom) is det.
to_atom(V, A) :-
    ( atom(V) -> A = V
    ; string(V) -> atom_string(A, V)
    ; number(V) -> A = V
    ; A = V
    ).
