/** <module> Deprecated oracle_server compatibility shim
 *
 * The strategy-provider implementation now lives behind the Teacher boundary
 * in `teacher_local_prolog.pl`. This module remains only for historical call
 * sites that still import `learner(oracle_server)`.
 */

:- module(oracle_server, [
    query_oracle/4,
    list_available_strategies/2,
    strategy_appropriate_for/3,
    estimate_strategy_cost/5
]).

:- use_module(teacher_local_prolog, [
    query_teacher/4,
    list_available_strategies/2,
    strategy_appropriate_for/3,
    estimate_strategy_cost/5
]).

query_oracle(Operation, StrategyName, Result, Interpretation) :-
    teacher_local_prolog:query_teacher(Operation, StrategyName, Result, Interpretation).
