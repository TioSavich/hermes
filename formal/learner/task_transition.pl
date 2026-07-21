/** <module> f_{t,c}: the local task-transition function of the curriculum dynamics
 *
 * PURPOSE: compose one step of the learner dynamical system. Given a learner
 * state (s, I) — a developmental stage s and an installed-strategy inventory I —
 * a source-backed task event t, and a policy c, execute the event through the
 * activity_contract machinery, classify the outcome against the crisis taxonomy,
 * invoke reorganize/4 only when the taxonomy calls for it, and return the updated
 * state with a trace. Learning happens through crisis: a productive success and
 * every honest boundary (needs_oracle, no reorganization domain, a declined
 * efficiency reorganization) leave (s, I) unchanged. This module introduces the
 * (s, I) term as an explicit, functionally-threaded abstraction; it holds no
 * global learner state of its own.
 *
 * State:   learner_state(Stage, Inventory)   Stage an integer stage on the
 *          units-coordination ladder; Inventory a sorted set of strategy(Op,Stage).
 * Event:   task_event(LessonCode, Role, Task, Provenance)   Role is productive or
 *          deformation(Family); Task is a runnable arithmetic term.
 * Policy:  policy(accept_efficiency) | policy(decline_efficiency).
 * Result:  transition(State1, trace(ExecutionOutcome, ReorganizationStep), Observation).
 */
:- module(task_transition,
          [ task_transition/4,
            classify_execution/2,
            task_reorganization_domain/3
          ]).

:- use_module(activity_contract, [activity_task_path/3]).
:- use_module(reorganize, [reorganize/4]).
:- use_module(reorg_domains/whole_number_operations, []).
:- use_module(library(lists)).

%!  task_transition(+State0, +Event, +Policy, -Transition) is det.
%
%   One step of f_{t,c}. Deterministic: the same state class and event class
%   yield the same transition, which is the (s, I)-sufficiency property.
task_transition(State0, task_event(Code, Role, Task, Provenance), Policy,
                transition(State1, trace(Outcome, ReorgStep), Observation)) :-
    State0 = learner_state(_Stage0, _Inventory0),
    execute_event(Code, Role, Task, Provenance, Outcome),
    classify_execution(Outcome, Signal),
    resolve(Signal, Task, State0, Policy, State1, ReorgStep, Observation),
    !.

%!  execute_event(+Code, +Role, +Task, +Provenance, -Outcome) is det.
%
%   Run the event through the activity_contract instance executor (productive or
%   deformation lane). Both lanes return a candidate_path or unsupported dict.
execute_event(Code, Role, Task, Provenance, Outcome) :-
    activity_contract:execute_lesson_instance(
        Code, instance(Role, Task, Provenance),
        execution(Role, Task, Provenance, Outcome)),
    !.
execute_event(_Code, _Role, Task, _Provenance,
              unsupported{task: Task, reason: instance_not_executable}).

%!  classify_execution(+Outcome, -Signal) is det.
%
%   Map an execution outcome to a crisis-taxonomy signal. A productive success is
%   solved(Result) and no crisis. A traversed deformation is a dead_end(Family)
%   crisis; an unsupported route is an impasse(Reason) crisis. Only crises reach
%   reorganize/4.
classify_execution(Outcome, dead_end(Family)) :-
    is_dict(Outcome, candidate_path),
    get_dict(validation, Outcome, deformation(Family, _Kind)),
    !.
classify_execution(Outcome, solved(Result)) :-
    is_dict(Outcome, candidate_path),
    get_dict(result, Outcome, Result),
    !.
classify_execution(Outcome, impasse(Reason)) :-
    is_dict(Outcome, unsupported),
    ( get_dict(reason, Outcome, Reason) -> true ; Reason = unspecified ),
    !.

% A productive success does not perturb the learner: state and inventory hold.
resolve(solved(Result), _Task, State0, _Policy, State0, none, solved(Result)) :- !.

% A crisis (dead end or impasse) consults reorganization, but only where the task
% names a reorganization domain. Otherwise it is an honest, named boundary.
resolve(Signal, Task, State0, Policy, State1, ReorgStep, Observation) :-
    crisis_signal(Signal),
    (   task_reorganization_domain(Task, Domain, Op)
    ->  reorganize_step(Domain, Op, Task, State0, Policy,
                        State1, ReorgStep, Observation)
    ;   task_operation(Task, Op),
        State1 = State0,
        ReorgStep = none,
        Observation = no_reorganization_domain(Op)
    ).

crisis_signal(dead_end(_)).
crisis_signal(impasse(_)).

%!  reorganize_step(+Domain, +Op, +Task, +State0, +Policy, -State1, -ReorgStep, -Observation)
%
%   Run reorganize/4 at the current stage and apply its outcome to (s, I) under
%   the policy. Accommodation advances the stage; an accepted efficiency
%   reorganization installs a cheaper same-stage strategy; needs_oracle and a
%   declined efficiency reorganization are boundaries that leave (s, I) unchanged.
reorganize_step(Domain, Op, Task, learner_state(Stage0, Inv0), Policy,
                State1, ReorgStep, Observation) :-
    (   reorganize(Domain, Task, Stage0, ReorgStep)
    ->  true
    ;   ReorgStep = reorganize_failed
    ),
    apply_reorganization(ReorgStep, Op, learner_state(Stage0, Inv0), Policy,
                         State1, Observation).

apply_reorganization(reorganized(accommodation, Stage1, strat(_, _, StratStage, _)),
                     Op, learner_state(_Stage0, Inv0), _Policy,
                     learner_state(Stage1, Inv1),
                     reorganized(accommodation, Strategy)) :-
    Strategy = strategy(Op, StratStage),
    ord_add_element(Inv0, Strategy, Inv1),
    !.
apply_reorganization(reorganized(efficiency, Stage0, strat(_, _, StratStage, _)),
                     Op, learner_state(Stage0, Inv0), policy(accept_efficiency),
                     learner_state(Stage0, Inv1),
                     reorganized(efficiency, Strategy)) :-
    Strategy = strategy(Op, StratStage),
    ord_add_element(Inv0, Strategy, Inv1),
    !.
apply_reorganization(reorganized(efficiency, _Stage, _Strat),
                     _Op, State0, policy(decline_efficiency),
                     State0, efficiency_declined) :- !.
apply_reorganization(needs_oracle, _Op, State0, _Policy, State0, needs_oracle) :- !.
apply_reorganization(reorganize_failed, _Op, State0, _Policy, State0, needs_oracle) :- !.

%!  task_reorganization_domain(+Task, -Domain, -Op) is semidet.
%
%   The reorg_domains/whole_number_operations interface models subtraction,
%   multiplication, and division as take-away, iteration, and sharing. Addition
%   is primitive here (no reorganization domain), so it has no clause.
task_reorganization_domain(subtract(_, _), whole_number(subtract, 10), subtract).
task_reorganization_domain(multiply(_, _), whole_number(multiply, 10), multiply).
task_reorganization_domain(divide(_, _),   whole_number(divide, 10),   divide).

task_operation(Task, Op) :- functor(Task, Op, _).
