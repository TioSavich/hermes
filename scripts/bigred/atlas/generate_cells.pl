/** <module> The Atlas cell-list generator
 *
 * Emits work/cells.json: the shard list for the Atlas sweep. One cell per lesson
 * that carries at least one compiled or hand-authored task instance; each cell is
 * one array task (cluster) or one sequential step (local). Lessons WITHOUT
 * compiled events are deliberately absent here -- they are not shards. The
 * aggregator names them as explicit gaps from the audit-coverage record
 * (atlas_export:coverage/1), so a lesson with no events is a named gap in the
 * summary, never a silently skipped cell.
 *
 * Ported from scripts/bigred/iteration14/generate_cells.pl in
 * umedcta-formalization (read-only there). Only the corpus vocabulary and the
 * work path moved.
 *
 * Load through paths.pl. Provenance (commit, date, model version) is passed in by
 * the caller through the environment (ATLAS_COMMIT, ATLAS_DATE) and echoed here;
 * the authoritative provenance header is stamped onto the generated fact module
 * by the aggregator.
 *
 * Run:
 *   swipl -q -l paths.pl -l scripts/bigred/atlas/generate_cells.pl \
 *     -g 'atlas_cells:main, halt' -t 'halt(1)' \
 *     -- scripts/bigred/atlas/work/cells.json
 */

:- module(atlas_cells, [ main/0, cell/3, default_cells_path/1 ]).

% ---- corpus vocabulary, named once ----------------------------------------
%
% Both instance sources are reached through paths.pl aliases, named here and
% nowhere else in this file. Hermes resolves lessons() to curriculum/ and
% learner() to formal/learner/.
:- use_module(learner(activity_contract), [ lesson_task_instance/3 ]).
:- use_module(lessons('im/generated/compiled_task_instances'),
              [ compiled_lesson_task_instance/3 ]).

%!  default_cells_path(-Path) is det.
%   The one place this pipeline's work tree is named inside Prolog. Every caller
%   passes the path explicitly; this is the fallback for a bare -g run.
default_cells_path('scripts/bigred/atlas/work/cells.json').

:- use_module(library(http/json)).
:- use_module(library(lists)).
:- use_module(library(aggregate)).

main :-
    ( current_prolog_flag(argv, Argv) -> true ; Argv = [] ),
    ( Argv = [OutPath | _] -> true ; default_cells_path(OutPath) ),
    findall(_{ lesson: C, grade: G, instance_count: N },
            cell(C, G, N),
            Cells0),
    sort(lesson, @=<, Cells0, Cells),
    length(Cells, NC),
    env_or('ATLAS_COMMIT', unknown, Commit),
    env_or('ATLAS_DATE', unknown, Date),
    Doc = _{ kind: atlas_cells_v1,
             generator: 'scripts/bigred/atlas/generate_cells.pl',
             commit: Commit,
             date: Date,
             model_version: 'state=(s,I)=learner_state(Stage,Inventory); policy=accept_efficiency; stages default [1,2,3]',
             default_stages: [1, 2, 3],
             default_policy: accept_efficiency,
             cell_count: NC,
             cells: Cells },
    setup_call_cleanup(open(OutPath, write, Out),
                       json_write_dict(Out, Doc, [width(0)]),
                       close(Out)),
    format(user_error, "[atlas] cells: ~w lessons -> ~w~n", [NC, OutPath]).

%!  cell(-Lesson, -Grade, -InstanceCount) is nondet.
cell(Code, Grade, Count) :-
    setof(C, has_instance(C), Codes),
    member(Code, Codes),
    grade_of(Code, Grade),
    aggregate_all(count, has_instance_of(Code), Count).

has_instance(C) :- compiled_lesson_task_instance(C, _, _).
has_instance(C) :- lesson_task_instance(C, _, _).

has_instance_of(C) :- compiled_lesson_task_instance(C, _, _).
has_instance_of(C) :- lesson_task_instance(C, _, _).

grade_of(Code, Grade) :-
    (   atom(Code),
        split_string(Code, "-", "", Parts),
        Parts = [_, GStr | _],
        string_concat("G", NStr, GStr),
        number_string(Grade, NStr)
    ->  true
    ;   Grade = unknown
    ).

env_or(Var, Default, Val) :-
    ( getenv(Var, V), V \== '' -> Val = V ; Val = Default ).
