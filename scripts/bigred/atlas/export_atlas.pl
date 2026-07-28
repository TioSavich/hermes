/** <module> The Atlas sweep export driver (one lesson shard)
 *
 * This is the scaled counterpart of scripts/curriculum/mini_atlas.pl. Where the
 * mini-Atlas runs f_{t,c} (formal/learner/task_transition.pl) over the declared
 * basis, this driver runs it over EVERY compiled task event of ONE lesson x every
 * learner stage the reorganization domain supports x the productive and licensed-
 * deformation routes the lesson carries. One shard = one lesson; the aggregator
 * merges the shards into the Atlas landscape that
 * scripts/curriculum/build_lesson_evidence.py reads for measured_transition.
 *
 * Ported from scripts/bigred/iteration14/export_atlas.pl in umedcta-formalization
 * (read-only there). The transition logic is carried over unchanged; what moved is
 * the corpus vocabulary, named once in the block below.
 *
 * Loading discipline: consult THROUGH paths.pl (swipl -l paths.pl -l THIS), not
 * flat/direct. task_transition -> activity_contract pulls in lessons(), math(),
 * render(), standards(), geometry(), crosswalk() via file_search_path; flat-loading
 * would raise false "missing predicate" reports.
 *
 * Register: each record is one step of the model's local dynamics under the
 * stated (s, I) state and the stated policy. A record certifies formal closure
 * of that step only -- it says nothing about a child. A per-transition wall
 * limit guards the search; a transition that exceeds it is written with
 * status:timeout and is never dropped (no silent caps). Lessons without compiled
 * events are not shard cells at all; the aggregator surfaces them as explicit
 * gaps from the audit-coverage record this driver also emits (coverage/1).
 *
 * Entry points:
 *   run(+LessonCode, +OutPath)  one shard: JSONL, one line per (instance x stage)
 *   coverage(+OutPath)          audit-coverage JSON the summary compares against
 *
 * Model version (the (s, I) descriptor recorded in provenance):
 *   state  = learner_state(Stage, Inventory), Inventory a sorted set of
 *            strategy(Op, Stage); every transition starts from Inventory = [].
 *   policy = policy(accept_efficiency) by default (ATLAS_POLICY overrides).
 *   stages = [1, 2, 3] by default (ATLAS_STAGES overrides): the units-
 *            coordination ladder the whole-number reorganization domain licenses
 *            (reorganize:rd_level_above caps the ladder at 3). Model-given, not
 *            discovered -- the sweep records where the licensed moves land, it
 *            does not claim the machine found the ladder.
 */

:- module(atlas_export,
          [ run/2,
            coverage/1,
            atlas_stages/1,
            atlas_policy/1,
            cell_time_limit/1
          ]).

% ---- corpus vocabulary, named once ----------------------------------------
%
% Every corpus this driver reads is reached through a paths.pl alias, and each
% alias appears exactly once, here. Hermes resolves lessons() to curriculum/ and
% learner() to formal/learner/; the sweep was authored against a checkout where
% those trees were called lessons/ and learner/. A literal directory anywhere
% below would be the one thing that could quietly read a tree that no longer
% exists, so rerouting a corpus is an edit to paths.pl or to these three lines.
%
%   learner(...)  -> formal/learner/
%   lessons(...)  -> curriculum/
:- use_module(learner(task_transition),
              [ task_transition/4, classify_execution/2 ]).
:- use_module(learner(activity_contract),
              [ lesson_task_instance/3,
                curriculum_traversal_audit/2,
                reset_curriculum_capability_cache/0 ]).
:- use_module(lessons('im/generated/compiled_task_instances'),
              [ compiled_lesson_task_instance/3 ]).

:- use_module(library(http/json)).
:- use_module(library(lists)).
:- use_module(library(time)).
:- use_module(library(apply)).

% ---- configuration (env-overridable, all model-given defaults) -------------

%!  atlas_stages(-Stages) is det.
atlas_stages(Stages) :-
    (   getenv('ATLAS_STAGES', Raw), Raw \== ''
    ->  split_string(Raw, ",", " ", Parts),
        findall(N, ( member(P, Parts), P \== "", number_string(N, P) ), Stages)
    ;   Stages = [1, 2, 3]
    ).

%!  atlas_policy(-Policy) is det.
atlas_policy(policy(P)) :-
    (   getenv('ATLAS_POLICY', Raw), Raw \== ''
    ->  atom_string(P, Raw)
    ;   P = accept_efficiency
    ).

%!  cell_time_limit(-Seconds) is det.  Per-transition wall limit.
cell_time_limit(Seconds) :-
    (   getenv('ATLAS_CELL_SECONDS', Raw), Raw \== '', atom_number(Raw, Seconds)
    ->  true
    ;   Seconds = 20
    ).

%!  grade_max(-Max) is det.  Audit ceiling for coverage/1.
grade_max(Max) :-
    (   getenv('ATLAS_GRADE_MAX', Raw), Raw \== '', atom_number(Raw, Max)
    ->  true
    ;   Max = 6
    ).

% ---- one shard -------------------------------------------------------------

%!  run(+LessonCode, +OutPath) is det.
%   Write the JSONL shard for one lesson: one record per (task instance x stage).
run(Code, OutPath) :-
    atlas_stages(Stages),
    atlas_policy(Policy),
    setup_call_cleanup(
        open(OutPath, write, Out),
        emit_lesson(Code, Stages, Policy, Out),
        close(Out)).

emit_lesson(Code, Stages, Policy, Out) :-
    % The instance facts are enumerated directly (the same two sources
    % generate_cells.pl reads). The earlier lesson_traversal_row call gave the
    % identical list but ALSO executed every route unguarded to build an
    % executions field this export never used -- cell IM-G7-U2-L8 died there
    % (stack overflow on multiply(1500, 30000)) before the guarded
    % per-transition sweep could record anything.
    grade_of(Code, Grade),
    findall(instance(Role, Task, Prov),
            ( lesson_task_instance(Code, Role-Task, Prov)
            ; compiled_lesson_task_instance(Code, Role-Task, Prov)
            ),
            Instances),
    (   Instances == []
    ->  emit_empty_cell(Code, Grade, Out)
    ;   forall( ( member(instance(Role, Task, Prov), Instances),
                  member(Stage, Stages) ),
                emit_transition(Code, Grade, Stage, Role, Task, Prov, Policy, Out))
    ).

%!  emit_empty_cell(+Code, +Grade, +Stream) is det.
%   A shard was requested for a lesson with no executable instances. Not dropped:
%   one record marks it as an empty cell so the merge is auditable.
emit_empty_cell(Code, Grade, Out) :-
    Dict = _{ schema: atlas_transition_v1,
              lesson: Code, grade: Grade, status: empty_cell,
              atlas_fact: null },
    json_write_dict(Out, Dict, [width(0)]), nl(Out).

%!  emit_transition(+Code,+Grade,+Stage,+Role,+Task,+Prov,+Policy,+Stream) is det.
emit_transition(Code, Grade, Stage, Role, Task, Prov, Policy, Out) :-
    cell_time_limit(Limit),
    policy_atom(Policy, PolicyAtom),
    Goal = task_transition(learner_state(Stage, []),
                           task_event(Code, Role, Task, Prov),
                           Policy,
                           transition(State1, trace(Outcome, ReorgStep), Obs)),
    (   catch( ( call_with_time_limit(Limit, Goal) -> Res = ok ; Res = no_transition ),
               Err,
               transition_guard_status(Err, Res) )
    ->  true
    ;   Res = no_transition
    ),
    common_fields(Code, Grade, Stage, PolicyAtom, Role, Task, Prov, Common),
    (   Res == ok
    ->  resolved_fields(Stage, Role, State1, Outcome, ReorgStep, Obs, Fields),
        fact_string(Code, Stage, Role, Task, State1, Obs, FactS),
        put_dict(Fields, Common, D0),
        put_dict(_{ status_group: resolved, atlas_fact: FactS }, D0, Dict)
    ;   put_dict(_{ status: Res, status_group: unresolved,
                    crisis: null, observation: null, observation_class: null,
                    result_state: null, stage1: null, atlas_fact: null },
                 Common, Dict)
    ),
    json_write_dict(Out, Dict, [width(0)]), nl(Out).

%!  transition_guard_status(+Error, -Status) is det.
%
%   A transition that exhausts its wall clock or a VM resource (stack, memory)
%   becomes a recorded outcome row, never a dead shard: the cell process must
%   survive every per-transition failure so completed transitions are not
%   lost with it. Found live on cell IM-G7-U2-L8, where multiply(1500, 30000)
%   overflowed the stack inside smr_mult_commutative_reasoning and killed the
%   whole cell. Unknown errors rethrow -- a programming defect should still fail
%   loudly.
transition_guard_status(time_limit_exceeded, timeout) :- !.
transition_guard_status(error(resource_error(_), _), resource_error) :- !.
transition_guard_status(Err, _) :- throw(Err).

common_fields(Code, Grade, Stage, PolicyAtom, Role, Task, Prov,
              _{ schema: atlas_transition_v1,
                 lesson: Code, grade: Grade, stage0: Stage, policy: PolicyAtom,
                 role: RoleS, role_kind: RoleKind, family: Family,
                 task: TaskS, operation: Op, provenance: ProvS }) :-
    role_kind(Role, RoleKind),
    family_of(Role, Family),
    task_operation(Task, Op),
    term_string(Role, RoleS),
    term_string(Task, TaskS),
    term_string(Prov, ProvS).

%!  resolved_fields(+Stage,+Role,+State1,+Outcome,+ReorgStep,+Obs,-Fields)
%   The dynamics of one resolved step: successor state, crisis classification,
%   cost/trace shape, the execution/deformation outcome, the quotient signature.
%   The task itself is not part of the per-appearance signature (the quotient
%   groups tasks BY signature), so it does not appear here.
resolved_fields(Stage, Role, State1, Outcome, ReorgStep, Obs, Fields) :-
    classify_execution(Outcome, Signal),
    crisis_label(Signal, Crisis),
    role_kind(Role, RoleKind),
    observation_class_term(Obs, ObsClassTerm),
    status_of(Obs, Status),
    exec_fields(Outcome, ExecKind, ExecSource, ExecValidation, ExecResult, DeformKind),
    reorg_fields(ReorgStep, ReorgMode, ReorgCost, ReorgMoves),
    state_stage(State1, Stage1),
    state_inventory_strings(State1, Inv1),
    term_string(Signal, CrisisDetail),
    term_string(Obs, ObsS),
    term_string(ObsClassTerm, ObsClassS),
    term_string(State1, State1S),
    term_string(ReorgStep, ReorgS),
    term_string(sig(Stage, RoleKind, State1, ObsClassTerm), SigS),
    Fields = _{ status: Status,
                crisis: Crisis, crisis_detail: CrisisDetail,
                result_state: State1S, stage1: Stage1, inventory1: Inv1,
                observation: ObsS, observation_class: ObsClassS,
                reorg_mode: ReorgMode, reorg_cost: ReorgCost,
                reorg_moves: ReorgMoves, reorg_step: ReorgS,
                exec_kind: ExecKind, exec_source: ExecSource,
                exec_validation: ExecValidation, exec_result: ExecResult,
                deformation_kind: DeformKind,
                signature: SigS }.

% ---- small, total helpers --------------------------------------------------

policy_atom(policy(P), P) :- !.
policy_atom(P, P).

role_kind(productive, productive) :- !.
role_kind(deformation(_), deformation) :- !.
role_kind(_, other).

family_of(deformation(F), F) :- !.
family_of(_, null).

task_operation(Task, Op) :- compound(Task), !, functor(Task, Op, _).
task_operation(Task, Task) :- atomic(Task), !.
task_operation(_, unknown).

crisis_label(solved(_), solved) :- !.
crisis_label(dead_end(_), dead_end) :- !.
crisis_label(impasse(_), impasse) :- !.
crisis_label(_, other).

% observation_class_term/2 mirrors the task-equivalence quotient exactly: the
% signature the quotient uses is built from this class, so the two must agree.
observation_class_term(solved(_), solved) :- !.
observation_class_term(reorganized(Mode, _), reorganized(Mode)) :- !.
observation_class_term(no_reorganization_domain(_), no_reorganization_domain) :- !.
observation_class_term(Obs, Class) :- functor(Obs, Class, _).

status_of(solved(_), solved) :- !.
status_of(reorganized(accommodation, _), reorganized_accommodation) :- !.
status_of(reorganized(efficiency, _), reorganized_efficiency) :- !.
status_of(efficiency_declined, efficiency_declined) :- !.
status_of(needs_oracle, needs_oracle) :- !.
status_of(no_reorganization_domain(_), no_reorganization_domain) :- !.
status_of(Obs, Status) :- compound(Obs), !, functor(Obs, Status, _).
status_of(Obs, Obs).

exec_fields(Outcome, Kind, Source, Validation, Result, DeformKind) :-
    ( is_dict(Outcome, Kind0) -> Kind = Kind0 ; Kind = other ),
    ( get_dict(source, Outcome, S0) -> scalar_string(S0, Source)
    ; get_dict(reason, Outcome, R0) -> scalar_string(R0, Source)
    ; Source = null ),
    ( get_dict(validation, Outcome, V0) -> term_string(V0, Validation) ; Validation = null ),
    ( get_dict(result, Outcome, Rr0) -> term_string(Rr0, Result) ; Result = null ),
    ( get_dict(deformation_kind, Outcome, DK0) -> scalar_string(DK0, DeformKind) ; DeformKind = null ).

% ReorgStep is task_transition's raw reorganization outcome:
%   reorganized(Mode, Level, strat(Domain, Problem, StratLevel, path(Cost, Moves)))
%   | none | needs_oracle | reorganize_failed
reorg_fields(reorganized(Mode, _L, strat(_D, _P, _SL, path(Cost, Moves))),
             Mode, Cost, N) :- !, length(Moves, N).
reorg_fields(reorganized(Mode, _L, _S), Mode, null, null) :- !.
reorg_fields(none, none, null, null) :- !.
reorg_fields(Atom, Atom, null, null) :- atom(Atom), !.
reorg_fields(_, unknown, null, null).

state_stage(learner_state(S, _), S) :- !.
state_stage(_, null).

state_inventory_strings(learner_state(_, Inv), Strs) :-
    is_list(Inv), !, maplist([X, Y]>>term_string(X, Y), Inv, Strs).
state_inventory_strings(_, []).

scalar_string(X, X) :- atomic(X), !.
scalar_string(X, S) :- term_string(X, S).

fact_string(Code, Stage, Role, Task, State1, Obs, S) :-
    format(atom(S), "atlas_transition(~q, ~q, ~q, ~q, ~q, ~q)",
           [Code, Stage, Role, Task, State1, Obs]).

grade_of(Code, Grade) :-
    (   atom(Code),
        split_string(Code, "-", "", Parts),
        Parts = [_, GStr | _],
        string_concat("G", NStr, GStr),
        number_string(Grade, NStr)
    ->  true
    ;   Grade = unknown
    ).

% ---- audit coverage (consumed by the aggregator for coverage-vs-audit) ------

%!  coverage(+OutPath) is det.
%   The traversal audit through grade_max, one row per lesson, so the aggregator
%   can name lessons-without-compiled-events as explicit gaps rather than drop
%   them. This is the slow step (the full audit); it runs once at aggregate time,
%   never per shard.
coverage(OutPath) :-
    grade_max(Max),
    reset_curriculum_capability_cache,
    curriculum_traversal_audit(Max, Audit),
    findall(Row,
            ( member(R, Audit.rows),
              coverage_row(R, Row) ),
            LessonRows),
    Doc = _{ kind: atlas_audit_coverage_v1,
             through_grade: Max,
             lesson_count: Audit.lesson_count,
             traversable: Audit.traversable_activity_contracts,
             missing_task_instance: Audit.missing_task_instance_count,
             unexercised_dead_end: Audit.unexercised_dead_end_count,
             lessons: LessonRows },
    setup_call_cleanup(open(OutPath, write, Out),
                       json_write_dict(Out, Doc, [width(0)]),
                       close(Out)),
    length(LessonRows, N),
    format(user_error, "[atlas] coverage: ~w lessons through grade ~w -> ~w~n",
           [N, Max, OutPath]).

coverage_row(R,
             _{ lesson: L, grade: G, status: St,
                has_instances: HI,
                productive_status: PS, dead_end_status: DS }) :-
    L = R.lesson,
    G = R.grade,
    term_string(R.status, St),
    ( R.task_instances == [] -> HI = false ; HI = true ),
    term_string(R.productive_route_status, PS),
    term_string(R.dead_end_status, DS).
