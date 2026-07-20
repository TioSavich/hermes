/** <module> Teacher Boundary
 *
 * A small provider facade for pedagogical intervention.
 *
 * The local implementation lives in `teacher_local_prolog.pl`. This module
 * gives the rest of the learner a Teacher vocabulary while keeping the
 * provider replaceable. The default provider is `local_prolog`: the existing
 * strategy library, isolated behind result + interpretation.
 */
:- module(teacher,
          [ ask_teacher/4,
            ask_teacher/5,
            available_strategies/2,
            strategy_appropriate_for/3,
            estimate_strategy_cost/5,
            current_teacher_provider/1,
            set_teacher_provider/1
          ]).

:- use_module(teacher_local_prolog, []).

:- dynamic teacher_provider/1.

teacher_provider(local_prolog).

%!  current_teacher_provider(-Provider) is det.
current_teacher_provider(Provider) :-
    teacher_provider(Provider),
    !.

%!  set_teacher_provider(+Provider) is det.
%
%   Supported providers:
%   - `local_prolog`: existing Prolog strategy library.
%   - `disabled`: no external pedagogical help.
%   - `llm`: reserved boundary for a future LLM-backed teacher.
set_teacher_provider(Provider) :-
    valid_provider(Provider),
    retractall(teacher_provider(_)),
    assertz(teacher_provider(Provider)).

valid_provider(local_prolog).
valid_provider(disabled).
valid_provider(llm).

%!  ask_teacher(+Operation, +StrategyName, -Result, -Interpretation) is semidet.
ask_teacher(Operation, StrategyName, Result, Interpretation) :-
    current_teacher_provider(Provider),
    ask_teacher(Provider, Operation, StrategyName, Result, Interpretation).

%!  ask_teacher(+Provider, +Operation, +StrategyName, -Result, -Interpretation) is semidet.
ask_teacher(local_prolog, Operation, StrategyName, Result, Interpretation) :-
    teacher_local_prolog:query_teacher(Operation, StrategyName, Result, Interpretation).
ask_teacher(disabled, Operation, StrategyName, _Result, _Interpretation) :-
    throw(error(permission_error(access, teacher, disabled),
                context(teacher:ask_teacher/5,
                        teacher_disabled(Operation, StrategyName)))).
ask_teacher(llm, Operation, StrategyName, _Result, _Interpretation) :-
    throw(error(existence_error(teacher_provider, llm),
                context(teacher:ask_teacher/5,
                        llm_teacher_not_configured(Operation, StrategyName)))).

%!  available_strategies(+Operation, -Strategies) is det.
available_strategies(Operation, Strategies) :-
    teacher_local_prolog:list_available_strategies(Operation, Strategies).

%!  strategy_appropriate_for(+Op, +Problem, -Strategy) is semidet.
strategy_appropriate_for(Op, Problem, Strategy) :-
    teacher_local_prolog:strategy_appropriate_for(Op, Problem, Strategy).

%!  estimate_strategy_cost(+Op, +Strategy, +A, +B, -Cost) is det.
estimate_strategy_cost(Op, Strategy, A, B, Cost) :-
    teacher_local_prolog:estimate_strategy_cost(Op, Strategy, A, B, Cost).
