/** <module> Arithmetic Machine Entry Point
 *
 * Public arithmetic facade for the isolated Prolog system.
 *
 * The default path uses the local Prolog Teacher provider and does not require
 * an elastic input, a catastrophe trigger, or a user-specified inference budget.
 * Developmental/crisis-driven execution remains available as an explicit mode.
 */
:- module(arithmetic_machine,
          [ solve_arithmetic/3,
            solve_arithmetic/4
          ]).

:- use_module(library(option)).
:- use_module(teacher).
:- use_module(fsm_synthesis_engine, [int_to_peano/2, peano_to_int/2]).

%!  solve_arithmetic(+Problem, -Result, -Report) is semidet.
%
%   Solves an arithmetic problem with default options.
%
%   Example:
%     ?- solve_arithmetic(divide(56,7), Result, Report).
solve_arithmetic(Problem, Result, Report) :-
    solve_arithmetic(Problem, [], Result, Report).

%!  solve_arithmetic(+Problem, +Options, -Result, -Report) is semidet.
%
%   Options:
%   - `mode(direct)` uses the Teacher's local Prolog strategy library. Default.
%   - `mode(developmental)` runs through `execution_handler` with a budget.
%   - `strategy(Name)` selects a concrete strategy.
%   - `teacher(Provider)` selects `local_prolog`, `disabled`, or `llm`.
%   - `budget(N)` sets the developmental inference budget. Default 1000.
solve_arithmetic(Problem, Options, Result, Report) :-
    normalize_problem(Problem, Op, A, B, Operation),
    option(mode(Mode), Options, direct),
    solve_arithmetic_by_mode(Mode, Op, A, B, Operation, Options, Result, Report).

solve_arithmetic_by_mode(direct, Op, A, B, Operation, Options, Result, Report) :-
    option(teacher(Provider), Options, local_prolog),
    select_strategy(Op, A, B, Options, Strategy),
    teacher:ask_teacher(Provider, Operation, Strategy, Result, Interpretation),
    Report = _{
        mode: direct,
        teacher: Provider,
        operation: Operation,
        strategy: Strategy,
        result: Result,
        interpretation: Interpretation
    }.

solve_arithmetic_by_mode(developmental, Op, A, B, _Operation, Options, Result, Report) :-
    use_module(learner(execution_handler)),
    option(budget(Budget), Options, 1000),
    int_to_peano(A, PA),
    int_to_peano(B, PB),
    Goal =.. [Op, PA, PB, PResult],
    execution_handler:run_computation(object_level:Goal, Budget),
    peano_to_int(PResult, Result),
    Report = _{
        mode: developmental,
        operation: Op,
        budget: Budget,
        result: Result
    }.

solve_arithmetic_by_mode(Mode, _Op, _A, _B, _Operation, _Options, _Result, _Report) :-
    throw(error(domain_error(arithmetic_mode, Mode),
                context(arithmetic_machine:solve_arithmetic/4,
                        'Expected mode(direct) or mode(developmental)'))).

select_strategy(_Op, _A, _B, Options, Strategy) :-
    option(strategy(Strategy), Options),
    !.
select_strategy(Op, A, B, _Options, Strategy) :-
    teacher:strategy_appropriate_for(Op, A+B, Strategy),
    !.
select_strategy(Op, _A, _B, _Options, Strategy) :-
    teacher:available_strategies(Op, [Strategy|_]).

normalize_problem(add(A, B), add, A, B, add(A, B)) :-
    must_be(integer, A),
    must_be(integer, B).
normalize_problem(add(A, B, _), add, A, B, add(A, B)) :-
    must_be(integer, A),
    must_be(integer, B).
normalize_problem(subtract(A, B), subtract, A, B, subtract(A, B)) :-
    must_be(integer, A),
    must_be(integer, B).
normalize_problem(subtract(A, B, _), subtract, A, B, subtract(A, B)) :-
    must_be(integer, A),
    must_be(integer, B).
normalize_problem(multiply(A, B), multiply, A, B, multiply(A, B)) :-
    must_be(integer, A),
    must_be(integer, B).
normalize_problem(multiply(A, B, _), multiply, A, B, multiply(A, B)) :-
    must_be(integer, A),
    must_be(integer, B).
normalize_problem(divide(A, B), divide, A, B, divide(A, B)) :-
    must_be(integer, A),
    must_be(integer, B),
    B =\= 0.
normalize_problem(divide(A, B, _), divide, A, B, divide(A, B)) :-
    must_be(integer, A),
    must_be(integer, B),
    B =\= 0.
