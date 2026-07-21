/** <module> mini_atlas: run f_{t,c} over the declared basis and record the local
 * transition dynamics, with an (s, I)-sufficiency audit.
 *
 * PURPOSE: this is the local, deterministic "Atlas" of the curriculum dynamics
 * program. It reads the declared basis (scripts/curriculum/basis_set.json), takes
 * each basis lesson's productive and deformation events, and runs each through
 * f_{t,c} (learner/task_transition.pl) from every starting stage in STAGES. It
 * generates a checked-in fact module (learner/atlas/basis_transitions.pl) of the
 * resulting basis_transition/6 facts and atlas_sufficiency_finding/4 facts, and
 * emits one JSON line per transition on stdout.
 *
 * The (s, I)-sufficiency audit records — it does not hide — every event class
 * whose outcome the (stage, operation, role) abstraction fails to determine, so a
 * violation is a named finding, not a silently widened state.
 *
 * Usage:
 *   swipl -q -l paths.pl -g mini_atlas:main -t halt scripts/curriculum/mini_atlas.pl
 *   swipl -q -l paths.pl -g mini_atlas:main -t halt scripts/curriculum/mini_atlas.pl -- --check
 */
:- module(mini_atlas, [main/0, atlas_rows/1, sufficiency_findings/2]).

:- use_module(learner(activity_contract),
              [lesson_traversal_row/2]).
:- use_module(learner(task_transition), [task_transition/4]).
:- use_module(library(http/json)).
:- use_module(library(lists)).
:- use_module(library(apply)).

stages([1, 2]).
generated_module('learner/atlas/basis_transitions.pl').
basis_manifest('scripts/curriculum/basis_set.json').

main :-
    ( current_prolog_flag(argv, Argv), memberchk('--check', Argv)
    ->  check
    ;   generate
    ).

%!  basis_lessons(-Lessons) is det.  Lessons declared in the basis manifest.
basis_lessons(Lessons) :-
    basis_manifest(Path),
    setup_call_cleanup(open(Path, read, Stream),
                       json_read_dict(Stream, Manifest, [value_string_as(atom)]),
                       close(Stream)),
    findall(L, member(_{lesson:L, grade:_, operation:_,
                        productive_task:_, deformation_family:_}, Manifest.entries),
            Lessons0),
    ( Lessons0 == [] -> maplist(get_dict(lesson), Manifest.entries, Lessons) ; Lessons = Lessons0 ).

%!  basis_event(-Lesson, -Role, -Task) is nondet.
%   The productive and exercised-deformation events of each basis lesson.
basis_event(Lesson, Role, Task) :-
    basis_lessons(Lessons),
    member(Lesson, Lessons),
    lesson_traversal_row(Lesson, Row),
    member(execution(Role, Task, _Prov, _Outcome), Row.executions).

%!  atlas_rows(-Rows) is det.  One row per (basis event x starting stage).
atlas_rows(Rows) :-
    stages(Stages),
    findall(row(Lesson, Stage, Role, Task, State1, Observation),
            ( basis_event(Lesson, Role, Task),
              member(Stage, Stages),
              task_transition(learner_state(Stage, []),
                              task_event(Lesson, Role, Task, atlas),
                              policy(accept_efficiency),
                              transition(State1, _Trace, Observation)) ),
            Rows0),
    sort(Rows0, Rows).

%!  sufficiency_findings(+Rows, -Findings) is det.
%   Group rows by the (stage, operation, role-kind) abstraction and flag every
%   class whose observations do not all share one functor: the abstraction fails
%   to determine the outcome there, so operand-level detail is a hidden variable.
sufficiency_findings(Rows, Findings) :-
    findall(class(Stage, Op, RoleKind),
            ( member(row(_, Stage, Role, Task, _, _), Rows),
              functor(Task, Op, _),
              role_kind(Role, RoleKind) ),
            Classes0),
    sort(Classes0, Classes),
    findall(finding(Op, RoleKind, Stage, ObservationKinds),
            ( member(class(Stage, Op, RoleKind), Classes),
              findall(OK,
                      ( member(row(_, Stage, Role, Task, _, Obs), Rows),
                        functor(Task, Op, _), role_kind(Role, RoleKind),
                        functor(Obs, OK, _) ),
                      OKs0),
              sort(OKs0, ObservationKinds),
              ObservationKinds = [_, _|_] ),
            Findings).

role_kind(productive, productive).
role_kind(deformation(_), deformation).

% ---- generation ----------------------------------------------------------

generate :-
    module_string(String),
    generated_module(Path),
    setup_call_cleanup(open(Path, write, Out),
                       write(Out, String),
                       close(Out)),
    emit_jsonl,
    atlas_rows(Rows), length(Rows, N),
    sufficiency_findings(Rows, Findings), length(Findings, F),
    format(user_error,
           "mini_atlas: ~w transitions written to ~w; ~w sufficiency finding(s)~n",
           [N, Path, F]).

module_string(String) :-
    atlas_rows(Rows),
    sufficiency_findings(Rows, Findings),
    with_output_to(string(String), emit_module(Rows, Findings)).

emit_module(Rows, Findings) :-
    format("/** <module> Generated basis transitions of the curriculum dynamics.~n"),
    format(" *~n"),
    format(" * Do not edit by hand. Regenerate with scripts/curriculum/mini_atlas.pl.~n"),
    format(" * basis_transition(Lesson, Stage0, Role, Task, State1, Observation): one run~n"),
    format(" * of f_{t,c} over a basis event. atlas_sufficiency_finding(Op, RoleKind,~n"),
    format(" * Stage, ObservationKinds): an event class the (stage, operation, role)~n"),
    format(" * abstraction fails to determine (operand detail is a hidden variable).~n"),
    format(" */~n"),
    format(":- module(basis_transitions, [basis_transition/6, atlas_sufficiency_finding/4]).~n~n"),
    forall(member(row(Lesson, Stage, Role, Task, State1, Obs), Rows),
           format("basis_transition(~q, ~q, ~q, ~q, ~q, ~q).~n",
                  [Lesson, Stage, Role, Task, State1, Obs])),
    nl,
    forall(member(finding(Op, RoleKind, Stage, Kinds), Findings),
           format("atlas_sufficiency_finding(~q, ~q, ~q, ~q).~n",
                  [Op, RoleKind, Stage, Kinds])).

emit_jsonl :-
    atlas_rows(Rows),
    forall(member(row(Lesson, Stage, Role, Task, State1, Obs), Rows),
           ( term_string(Role, RoleS), term_string(Task, TaskS),
             term_string(State1, StateS), term_string(Obs, ObsS),
             json_write_dict(user_output,
                             _{lesson: Lesson, stage0: Stage, role: RoleS,
                               task: TaskS, state1: StateS, observation: ObsS},
                             [width(0)]),
             nl )).

% ---- check ---------------------------------------------------------------

check :-
    module_string(Fresh),
    generated_module(Path),
    ( exists_file(Path)
    ->  read_file_to_string(Path, OnDisk, []),
        ( Fresh == OnDisk
        ->  format(user_error, "mini_atlas --check: up to date~n", []), halt(0)
        ;   format(user_error, "mini_atlas --check: ~w is stale; regenerate~n", [Path]),
            halt(1) )
    ;   format(user_error, "mini_atlas --check: ~w missing; generate it~n", [Path]),
        halt(1) ).
