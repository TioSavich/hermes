/** <module> task_quotient: the task-equivalence quotient of the curriculum dynamics
 *
 * PURPOSE: the definition-of-done condition that the task-equivalence quotient be
 * "derived from complete transition signatures and checked as a congruence under
 * state update". This module reads the generated basis_transition/6 facts (the
 * mini-Atlas of f_{t,c} over the declared basis) and does three things:
 *
 *   1. transition_signature/2  the COMPLETE signature of a task: the operand-
 *      abstracted set of (Stage0, RoleKind, State1, ObservationClass) tuples it
 *      induces across the basis. Operands are abstracted (solved(7) -> solved),
 *      but the successor state State1 and the reorganization mode are kept, because
 *      they are structural, not operand detail.
 *
 *   2. quotient_class/2  the quotient itself: tasks grouped by identical complete
 *      signature. Two tasks in one class are interchangeable in the model's local
 *      dynamics; the quotient collapses operand-distinct tasks that move the
 *      learner state the same way.
 *
 *   3. the congruence check, at two granularities:
 *        - state_update_congruent/0: the state-update map is a well-defined
 *          function on the complete-signature quotient (a class and starting stage
 *          determine one successor state). This is the congruence the definition of
 *          done asks for; it holds here.
 *        - observable_congruence_violation/1: the COARSER diagnostic projection
 *          (Stage0, RoleKind, ObservationClass) is NOT in general a congruence:
 *          the same observed reorganization installs an operation-specific strategy,
 *          so the bare observation underdetermines the state update. Each such class
 *          is recorded as a named finding, never silently widened -- the same
 *          discipline the (s, I)-sufficiency audit uses for the observation level.
 *
 * This module derives everything on demand from basis_transition/6; it holds no
 * generated state of its own. Regenerate the substrate with mini_atlas.pl.
 */
:- module(task_quotient,
          [ transition_signature/2,
            quotient_class/2,
            quotient_summary/1,
            state_update_congruent/0,
            state_update_violation/1,
            observable_congruence_violation/1
          ]).

:- use_module(library(lists)).
:- use_module(library(apply)).
:- use_module(library(pairs)).
:- use_module(learner('atlas/basis_transitions'), [basis_transition/6]).

role_kind(productive, productive).
role_kind(deformation(_), deformation).

%!  observation_class(+Observation, -Class) is det.
%   Abstract an observation to its structural class: strip numeric operands from
%   solved/1, keep the reorganization mode, keep boundary functors whole.
observation_class(solved(_), solved) :- !.
observation_class(reorganized(Mode, _), reorganized(Mode)) :- !.
observation_class(no_reorganization_domain(_), no_reorganization_domain) :- !.
observation_class(Observation, Class) :- functor(Observation, Class, _).

%!  atlas_task(-Task) is nondet.  Each distinct task appearing in the basis atlas.
atlas_task(Task) :-
    findall(T, basis_transition(_, _, _, T, _, _), Ts),
    sort(Ts, Sorted),
    member(Task, Sorted).

%!  transition_signature(+Task, -Signature) is det.
%   The complete, operand-abstracted transition signature of a task.
transition_signature(Task, Signature) :-
    findall(sig(Stage0, RoleKind, State1, ObsClass),
            ( basis_transition(_Lesson, Stage0, Role, Task, State1, Obs),
              role_kind(Role, RoleKind),
              observation_class(Obs, ObsClass) ),
            Entries),
    sort(Entries, Signature).

%!  quotient_class(-Signature, -Tasks) is nondet.
%   One equivalence class of the quotient: all tasks sharing Signature.
quotient_class(Signature, Tasks) :-
    findall(Signature1-Task,
            ( atlas_task(Task), transition_signature(Task, Signature1) ),
            Pairs0),
    keysort(Pairs0, Pairs),
    group_pairs_by_key(Pairs, Grouped),
    member(Signature-Tasks, Grouped).

% ---- congruence under state update ---------------------------------------

%!  state_update_key(-Signature, -Stage0, -RoleKind) is nondet.
%   The state-update map is keyed by (quotient class, starting stage, role kind).
state_update_key(Signature, Stage0, RoleKind) :-
    quotient_class(Signature, _),
    member(sig(Stage0, RoleKind, _, _), Signature).

%!  state_update_violation(-violation(Signature, Stage0, RoleKind, States)) is nondet.
%   A class + stage + role that maps to more than one successor state: the state
%   update would not be a function on the quotient there. None occur here (the
%   complete signature already fixes State1), so this is the passing witness.
state_update_violation(violation(Signature, Stage0, RoleKind, States)) :-
    quotient_class(Signature, Tasks),
    member(sig(Stage0, RoleKind, _, _), Signature),
    findall(State1,
            ( member(Task, Tasks),
              basis_transition(_, Stage0, Role, Task, State1, _),
              role_kind(Role, RoleKind) ),
            States0),
    sort(States0, States),
    States = [_, _ | _].

%!  state_update_congruent is semidet.
%   True when the state-update map is well-defined on the quotient.
state_update_congruent :-
    \+ state_update_violation(_).

%!  observable_congruence_violation(-finding(Stage0, RoleKind, ObsClass, States)) is nondet.
%   The coarser diagnostic projection (Stage0, RoleKind, ObservationClass) that
%   maps to more than one successor state: the observation alone underdetermines
%   the state update (the operation is the hidden variable). A named finding.
observable_congruence_violation(finding(Stage0, RoleKind, ObsClass, States)) :-
    setof(key(S, RK, OC),
            L^T^St1^Obs^Role^( basis_transition(L, S, Role, T, St1, Obs),
                               role_kind(Role, RK),
                               observation_class(Obs, OC) ),
            Keys),
    member(key(Stage0, RoleKind, ObsClass), Keys),
    findall(State1,
            ( basis_transition(_, Stage0, Role, _, State1, Obs),
              role_kind(Role, RoleKind),
              observation_class(Obs, ObsClass) ),
            States0),
    sort(States0, States),
    States = [_, _ | _].

% ---- summary -------------------------------------------------------------

%!  quotient_summary(-Summary) is det.
quotient_summary(quotient_summary{
                     tasks: TaskCount,
                     classes: ClassCount,
                     nontrivial_classes: NontrivialCount,
                     largest_class: LargestClass,
                     state_update_congruence: StateVerdict,
                     observable_congruence_violations: ObsViolationCount
                 }) :-
    findall(T, atlas_task(T), Tasks), length(Tasks, TaskCount),
    findall(Sig-Members, quotient_class(Sig, Members), Classes),
    length(Classes, ClassCount),
    findall(N, ( member(_-Members, Classes), length(Members, N), N >= 2 ), NontrivialSizes),
    length(NontrivialSizes, NontrivialCount),
    foldl([_-Ms, A, B]>>(length(Ms, L), B is max(A, L)), Classes, 0, LargestClass),
    ( state_update_congruent -> StateVerdict = holds ; StateVerdict = violated ),
    findall(F, observable_congruence_violation(F), ObsViolations),
    length(ObsViolations, ObsViolationCount).
