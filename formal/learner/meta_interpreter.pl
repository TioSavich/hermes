/** <module> Embodied Tracing Meta-Interpreter
 *
 * This module provides the core "Observe" capability of the ORR cycle.
 * It contains a stateful meta-interpreter, `solve/4`, which executes goals
 * defined in the `object_level` module.
 *
 * This version is "embodied": it maintains a `ModalContext` (e.g., neutral,
 * compressive, expansive) that alters its reasoning behavior. For example,
 * in a `compressive` context, the cost of inferences increases, simulating
 * cognitive tension and narrowing the search. This context is switched when
 * the interpreter encounters modal operators defined in `sequent_engine`.
 *
 * It produces a detailed `Trace` of the execution, which is the primary
 * data source for the `reflective_monitor`.
 *
 * 
 * 
 */
:- module(meta_interpreter, [solve/4]).
:- use_module(object_level). % Ensure we can access the object-level code
:- use_module(strategies(hermeneutic_calculator)). % For strategic choice
:- use_module(sequent(sequent_engine), [s/1, 'comp_nec'/1, 'comp_poss'/1, 'exp_nec'/1, 'exp_poss'/1, check_norms/1]). % For modal operators and norm checking
:- use_module(formalization(grounded_arithmetic)). % For cognitive cost tracking
:- use_module(config). % For cognitive cost lookup
:- use_module(more_machine_learner,
              [ run_available_strategy/5,
                run_available_strategy/6
              ]).
:- use_module(tension_dynamics). % Continuous tension accumulator for catastrophe geometry
:- use_module(formalization(modal_costs), [get_inference_cost/2]).
:- use_module(peano_utils, [peano_to_int/2, int_to_peano/2]).

% Note: is_list/1 is a built-in, no need to import from library(lists).

% --- Embodied Cognition Helpers ---

%!      is_modal_operator(?Goal, ?ModalContext) is semidet.
%
%       Identifies an embodied modal operator and maps it to a context.
is_modal_operator(comp_nec(_), compressive).
is_modal_operator(comp_poss(_), compressive).
is_modal_operator(exp_nec(_), expansive).
is_modal_operator(exp_poss(_), expansive).

%!      get_inference_cost(+ModalContext, -Cost) is det.
%
%       Determines the inference cost based on the current modal context.
%       - `compressive`: Cost is 2 (cognitive narrowing).
%       - `neutral`, `expansive`: Cost is 1.
% get_inference_cost/2 imported from formalization(modal_costs).


% --- Arithmetic Goal Handling ---

%!      is_arithmetic_goal(?Goal, ?Op) is semidet.
%
%       Identifies arithmetic goals and maps them to standard operators.
%       This allows the meta-interpreter to intercept these goals and
%       handle them with the Hermeneutic Calculator instead of the
%       inefficient object-level definitions.
is_arithmetic_goal(add(_,_,_), +).
is_arithmetic_goal(multiply(_,_,_), *).
% Add other operations like subtract/3, divide/3 here if needed.


%!      solve(+Goal, +InferencesIn, -InferencesOut, -Trace) is nondet.
%
%       Public wrapper for the stateful meta-interpreter.
%       Initializes the `ModalContext` to `neutral` and calls the
%       internal `solve/6` predicate.
solve(Goal, I_In, I_Out, Trace) :-
    solve(Goal, neutral, _, I_In, I_Out, Trace).


%!      solve(+Goal, +CtxIn, -CtxOut, +I_In, -I_Out, -Trace) is nondet.
%
%       The core stateful, embodied meta-interpreter.
%
%       @param Goal The goal to be solved.
%       @param CtxIn The current `ModalContext`.
%       @param CtxOut The `ModalContext` after the goal is solved.
%       @param I_In The initial number of available inference steps.
%       @param I_Out The remaining number of inference steps.
%       @param Trace A list representing the execution trace.
%       @error perturbation(resource_exhaustion) if inference counter drops to zero.

% Base case: `true` always succeeds. Context is unchanged.
solve(true, Ctx, Ctx, I, I, []) :- !.

% Cognitive Cost Tracking: Intercept cost signals for embodied learning.
% P2-4: Costs are now context-sensitive — compressive context doubles all
% action costs, unifying System A's modal cost model (get_inference_cost/2)
% with System B's action cost model (cognitive_cost/2). A unit_count that
% costs 5 in neutral context costs 10 under compressive necessity.
solve(incur_cost(Action), Ctx, Ctx, I_In, I_Out, [cognitive_cost(Action, AdjustedCost)]) :-
    !,
    ( config:cognitive_cost(Action, BaseCost) -> true ; BaseCost = 0 ),
    get_inference_cost(Ctx, ContextMultiplier),
    AdjustedCost is BaseCost * ContextMultiplier,
    tension_dynamics:accumulate_tension(AdjustedCost, Ctx),
    check_viability(I_In, AdjustedCost),
    tension_dynamics:check_crisis,
    I_Out is I_In - AdjustedCost.

% Modal Operator: Detect a modal operator, switch context for the sub-proof,
% and restore it upon completion. Enhanced to capture detailed modal information.
% PHASE 6: Modal operators now consume inference budget (modal_shift cost).
% Thinking is not free - cognitive context shifts represent real cognitive events.
solve(s(ModalGoal), CtxIn, CtxIn, I_In, I_Out, [modal_trace(ModalGoal, Ctx, SubTrace, ModalInfo)]) :-
    is_modal_operator(ModalGoal, Ctx),
    !,
    % PHASE 6: Charge cost for modal context shift
    config:cognitive_cost(modal_shift, ModalCost),
    tension_dynamics:accumulate_tension(ModalCost, CtxIn),
    check_viability(I_In, ModalCost),
    tension_dynamics:check_crisis,
    I_AfterShift is I_In - ModalCost,
    
    ModalGoal =.. [_, InnerGoal],
    % Record modal transition information
    ModalInfo = modal_info(
        transition(CtxIn, Ctx),
        cost_impact(CtxIn, Ctx),
        goal(InnerGoal),
        modal_cost_charged(ModalCost)  % PHASE 6: Record cost in trace
    ),
    % The context is switched for the InnerGoal, but restored to CtxIn afterward.
    solve(InnerGoal, Ctx, _, I_AfterShift, I_Out, SubTrace).

% Conjunction: Solve `A` then `B`. The context flows from `A` to `B`.
solve((A, B), CtxIn, CtxOut, I_In, I_Out, [trace(A, A_Trace), trace(B, B_Trace)]) :-
    !,
    solve(A, CtxIn, CtxMid, I_In, I_Mid, A_Trace),
    solve(B, CtxMid, CtxOut, I_Mid, I_Out, B_Trace).

% System predicates: Use context-dependent cost. Context is unchanged.
solve(Goal, Ctx, Ctx, I_In, I_Out, [call(Goal)]) :-
    predicate_property(Goal, built_in),
    !,
    get_inference_cost(Ctx, Cost),
    tension_dynamics:accumulate_tension(Cost, Ctx),
    check_viability(I_In, Cost),
    tension_dynamics:check_crisis,
    I_Out is I_In - Cost,
    call(Goal).

% DISABLED: Arithmetic handler (forces arithmetic through object-level predicates for crisis testing)
% solve(Goal, Ctx, Ctx, I_In, I_Out, [arithmetic_trace(Strategy, Result, History)]) :-
%     is_arithmetic_goal(Goal, Op),
%     !,
%     get_inference_cost(Ctx, Cost),
%     check_viability(I_In, Cost),
%     I_Out is I_In - Cost,
%     Goal =.. [_, Peano1, Peano2, PeanoResult],
%     peano_to_int(Peano1, N1),
%     peano_to_int(Peano2, N2),
%     list_strategies(Op, Strategies),
%     ( is_list(Strategies), Strategies = [Strategy|_] -> true ; throw(error(no_strategy_found(Op), _)) ),
%     calculate(N1, Op, N2, Strategy, Result, History),
%     int_to_peano(Result, PeanoResult).

% PHASE 3.2: Learned Strategy Selection (LIFO Hierarchy)
% Try learned strategies BEFORE falling back to primordial object_level predicates.
% This implements the developmental hierarchy where newer strategies are tried first.
solve(object_level:add(A, B, Result), Ctx, Ctx, I_In, I_Out, [learned_strategy(StrategyName, StrategyTrace)]) :-
    !,  % Cut to prevent backtracking to object_level after trying learned strategies
    get_inference_cost(Ctx, Cost),
    check_viability(I_In, Cost),
    tension_dynamics:check_crisis,
    % Try to use a learned strategy (queries most recent first via Prolog's clause ordering)
    (
        more_machine_learner:run_available_strategy(add, A, B, Result,
                                                    StrategyName, StrategyTrace),
        format('      [Strategy Selection] Using learned strategy: ~w~n', [StrategyName]),
        strategy_runtime_cost(StrategyName, A, B, BaseCost),
        get_inference_cost(Ctx, CtxMul),
        StratCost is BaseCost * CtxMul,  % P2-4: context-sensitive strategy cost
        tension_dynamics:accumulate_tension(StratCost, Ctx),
        check_viability(I_In, StratCost),
        tension_dynamics:check_crisis,
        I_Out is I_In - StratCost
    ;
        % Fall back to foundational solving if no learned strategy applies
        format('      [Strategy Selection] No learned strategy applicable, using primordial ~w~n', [object_level:add(A,B,Result)]),
        get_inference_cost(Ctx, Cost), % Cost for falling back to primordial
        tension_dynamics:accumulate_tension(Cost, Ctx),
        check_viability(I_In, Cost),
        tension_dynamics:check_crisis,
        I_Mid is I_In - Cost,
        clause(object_level:add(A, B, Result), Body),
        solve(Body, Ctx, _, I_Mid, I_Out, _)
    ).

% Learned operations use the same strategy hierarchy as addition, but retain
% the operation at dispatch so paths with the same inputs cannot cross
% operation boundaries.
solve(object_level:Goal, Ctx, Ctx, I_In, I_Out,
      [learned_strategy(StrategyName, StrategyTrace)]) :-
    Goal =.. [Operation, A, B, Result],
    memberchk(Operation, [subtract, multiply, divide, fraction]),
    more_machine_learner:run_available_strategy(Operation, A, B, Result,
                                                StrategyName, StrategyTrace),
    !,
    strategy_runtime_cost(StrategyName, A, B, BaseCost),
    get_inference_cost(Ctx, CtxMul),
    Cost is BaseCost * CtxMul,
    tension_dynamics:accumulate_tension(Cost, Ctx),
    check_viability(I_In, Cost),
    tension_dynamics:check_crisis,
    I_Out is I_In - Cost.

% Object-level predicates: Use context-dependent cost. Context flows through sub-proof.
solve(Goal, CtxIn, CtxOut, I_In, I_Out, [clause(object_level:(Goal:-Body)), trace(Body, BodyTrace)]) :-
    % NORMATIVE CHECKING: Validate goal against current mathematical context
    catch(check_norms(Goal), normative_crisis(CrisisGoal, Context),
          throw(perturbation(normative_crisis(CrisisGoal, Context)))),

    get_inference_cost(CtxIn, Cost),
    tension_dynamics:accumulate_tension(Cost, CtxIn),
    check_viability(I_In, Cost),
    tension_dynamics:check_crisis,
    I_Mid is I_In - Cost,
    clause(object_level:Goal, Body),
    solve(Body, CtxIn, CtxOut, I_Mid, I_Out, BodyTrace).

% PHASE 2: Unknown operation detection
% When an arithmetic operation is attempted but not defined in object_level,
% throw an unknown_operation perturbation instead of silently failing.
% Handles both `object_level:Op(...)` and bare `Op(...)` forms.
solve(Goal, Ctx, Ctx, _I_In, _I_Out, _) :-
    % Extract the actual operation from module-qualified or bare goal
    (   Goal = object_level:ActualGoal
    ->  true
    ;   ActualGoal = Goal
    ),
    \+ predicate_property(ActualGoal, built_in),
    functor(ActualGoal, Functor, 3),
    member(Functor, [subtract, multiply, divide, fraction]),
    \+ clause(object_level:ActualGoal, _),
    !,
    % This is an unknown operation - trigger learning crisis
    throw(perturbation(unknown_operation(Functor, Goal))).

% Failure case: If a goal is not a built-in and has no matching clauses,
% record the failure. Context is unchanged.
solve(Goal, Ctx, Ctx, I, I, [fail(Goal)]) :-
    \+ predicate_property(Goal, built_in),
    \+ (Goal = s(_), functor(Goal, s, 1)), % Don't fail on modal operators here
    \+ clause(object_level:Goal, _), !.


% --- Viability Check ---

% check_viability(+Inferences, +Cost)
%
% Succeeds if the inference counter is sufficient for the next step's cost.
check_viability(I, Cost) :- 
    % format('      [DEBUG] check_viability: I=~w, Cost=~w~n', [I, Cost]),
    I >= Cost, !.
check_viability(I, Cost) :-
    % Constraint violated: PERTURBATION DETECTED
    format('      [CRISIS] Resource Exhaustion! I=~w < Cost=~w~n', [I, Cost]),
    throw(perturbation(resource_exhaustion)).

% === Strategy Runtime Costs ===
% Evaluates the theoretical inference cost of a learned strategy, so that the meta-interpreter
% appropriately deducts "effort" and can trigger subsequent crises if the problem scales up.
strategy_runtime_cost('COBO', object_level:add(A, B, _), _, Cost) :-
    fsm_synthesis_engine:peano_to_int(A, IntA),
    fsm_synthesis_engine:peano_to_int(B, IntB),
    Cost is min(IntA, IntB) + 1.

strategy_runtime_cost(reorganized_path(_, _, _, Cost), _, _, Cost) :- !.
strategy_runtime_cost(recognized_path(_, _, Cost), _, _, Cost) :- !.
strategy_runtime_cost(unit_action_path(_, _, Cost), _, _, Cost) :- !.

strategy_runtime_cost('COBO', A, B, Cost) :-
    fsm_synthesis_engine:peano_to_int(A, IntA),
    fsm_synthesis_engine:peano_to_int(B, IntB),
    Cost is min(IntA, IntB) + 1.

strategy_runtime_cost('RMB', A, B, Cost) :-
    fsm_synthesis_engine:peano_to_int(A, IntA),
    fsm_synthesis_engine:peano_to_int(B, IntB),
    DistA is abs(10 - IntA),
    DistB is abs(10 - IntB),
    % Cost depends on how far the number is from 10.
    Cost is min(DistA, DistB) * 2 + 3.

strategy_runtime_cost('Chunking', A, B, Cost) :-
    fsm_synthesis_engine:peano_to_int(A, IntA),
    fsm_synthesis_engine:peano_to_int(B, IntB),
    % Chunking cost scales with number of decades
    Cost is (IntA // 10) + (IntB // 10) + 3.

strategy_runtime_cost('Rounding', _, _, Cost) :-
    % Rounding up to tens is very cheap assuming large numbers
    Cost = 4.

strategy_runtime_cost(_, _, _, 1). % Default fallback cost
