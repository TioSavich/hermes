/** <module> More Machine Learner — Strategy Hierarchy & Foundational Solver
 *
 * Manages the strategy hierarchy (run_learned_strategy/5) and provides
 * the foundational counting solver. Pattern detection and reflective
 * learning were removed in Phase 5 refactoring; the original is at
 * archive/more_machine_learner.pl.
 */
:- module(more_machine_learner,
          [ run_learned_strategy/5,
            run_available_strategy/5,
            run_available_strategy/6,
            solve/4,
            save_knowledge/0
          ]).

% Use the semantics engine for validation
:- use_module(arche_trace(sequent_engine), [proves/1, set_domain/1, current_domain/1, is_recollection/2, normalize/2]).
:- use_module(library(random)).
:- use_module(library(lists)).
:- use_module(strategy_synthesis,
              [ run_synthesized_strategy/5,
                run_synthesized_strategy/6
              ]).

% Ensure operators are visible
:- op(1050, xfy, =>).
:- op(500, fx, neg).
:- op(550, xfy, rdiv).

%!      run_learned_strategy(?A, ?B, ?Result, ?StrategyName, ?Trace) is nondet.
%
%       A dynamic, multifile predicate that stores the collection of learned
%       strategies. Each clause of this predicate represents a single, efficient
%       strategy that the system has discovered and validated.
%
%       The `solve/4` predicate queries this predicate first, implementing a
%       hierarchy where learned, efficient strategies are preferred over
%       foundational, inefficient ones.
%
%       @param A The first input number.
%       @param B The second input number.
%       @param Result The result of the calculation.
%       @param StrategyName An atom identifying the learned strategy (e.g., `cob`, `rmb(10)`).
%       @param Trace A structured term representing the efficient execution path.
:- dynamic run_learned_strategy/5.

% =================================================================
% Part 0: Initialization and Persistence
% =================================================================

knowledge_file('learned_knowledge.pl').

% Load persistent knowledge when this module is loaded.
load_knowledge :-
    knowledge_file(File),
    (   exists_file(File)
    ->  consult(File),
        findall(_, clause(run_learned_strategy(_,_,_,_,_), _), Clauses),
        length(Clauses, Count),
        format('~N[Learner Init] Successfully loaded ~w learned strategies.~n', [Count])
    ;   format('~N[Learner Init] Knowledge file not found. Starting fresh.~n')
    ).

% Ensure initialization runs after the predicate is defined
:- initialization(load_knowledge, now).

%!      save_knowledge is det.
%
%       Saves all currently learned strategies (clauses of the dynamic
%       `run_learned_strategy/5` predicate) to the file specified by
%       `knowledge_file/1`. This allows for persistence of learning across sessions.
save_knowledge :-
    knowledge_file(File),
    setup_call_cleanup(
        open(File, write, Stream),
        (
            writeln(Stream, '% Automatically generated knowledge base.'),
            writeln(Stream, ':- op(550, xfy, rdiv).'),
            forall(clause(run_learned_strategy(A, B, R, S, T), Body),
                   portray_clause(Stream, (run_learned_strategy(A, B, R, S, T) :- Body)))
        ),
        close(Stream)
    ).

% =================================================================
% Part 1: The Unified Solver (Strategy Hierarchy)
% =================================================================

%!      solve(+A, +B, -Result, -Trace) is semidet.
%
%       Solves `A + B` using a strategy hierarchy.
%
%       It first attempts to use a highly efficient, learned strategy by
%       querying `run_learned_strategy/5`. If no applicable learned strategy
%       is found, it falls back to the foundational, inefficient counting
%       strategy (`solve_foundationally/4`).
%
%       @param A The first addend.
%       @param B The second addend.
%       @param Result The numerical result.
%       @param Trace The execution trace produced by the winning strategy.
solve(A, B, Result, Trace) :-
    (   run_available_strategy(A, B, Result, _StrategyName, Trace)
    ->  true
    ;
        solve_foundationally(A, B, Result, Trace)
    ).

%!  run_available_strategy(?A, ?B, ?Result, ?Name, ?Trace) is nondet.
%
%   Primitive-path syntheses are tried before teacher-backed or historical
%   dynamic clauses. Keeping this as a wrapper means reset utilities may clear
%   run_learned_strategy/5 without deleting the live synthesis bridge itself.
run_available_strategy(A, B, Result, Name, Trace) :-
    strategy_synthesis:run_synthesized_strategy(A, B, Result, Name, Trace).
run_available_strategy(A, B, Result, Name, Trace) :-
    run_learned_strategy(A, B, Result, Name, Trace).

run_available_strategy(Operation, A, B, Result, Name, Trace) :-
    strategy_synthesis:run_synthesized_strategy(Operation, A, B, Result,
                                                Name, Trace).
run_available_strategy(add, A, B, Result, Name, Trace) :-
    run_learned_strategy(A, B, Result, Name, Trace).

% =================================================================
% Part 2: Foundational Abilities & Trace Analysis
% =================================================================

% --- 3.1 Foundational Ability: Counting ---

successor(X, Y) :- proves([] => [o(plus(X, 1, Y))]).

% solve_foundationally(+A, +B, -Result, -Trace)
%
% The most basic, "unfolded" strategy. It solves addition by counting on
% from A, B times. This is deliberately inefficient to provide rich traces
% for the reflective process to analyze.
solve_foundationally(A, B, Result, Trace) :-
    is_recollection(A, _), is_recollection(B, _),
    integer(A), integer(B), B >= 0,
    count_loop(A, B, Result, Steps),
    Trace = trace{a_start:A, b_start:B, strategy:counting, steps:Steps}.

count_loop(CurrentA, 0, CurrentA, []) :- !.
count_loop(CurrentA, CurrentB, Result, [step(CurrentA, NextA)|Steps]) :-
    CurrentB > 0,
    NextB is CurrentB - 1,
    successor(CurrentA, NextA),
    count_loop(NextA, NextB, Result, Steps).

% --- 3.2 Trace Analysis Helpers ---

count_trace_steps(Trace, Count) :-
    (   member(Trace.strategy, [counting, doubles, rmb(_)])
    ->  length(Trace.steps, Count)
    ;   Trace.strategy = cob
    ->
        ( member(inner_trace(InnerTrace), Trace.steps)
          -> count_trace_steps(InnerTrace, Count)
          ; Count = 0
        )
    ;   Count = 1
    ).

get_calculation_trace(T, T) :- member(T.strategy, [counting, rmb(_), doubles]).
get_calculation_trace(T, CT) :-
    T.strategy = cob,
    member(inner_trace(InnerT), T.steps),
    get_calculation_trace(InnerT, CT).
