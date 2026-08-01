/** <module> Run every declared lesson enactment and emit its rows
 *
 * The driver behind `scripts/curriculum/build_im_lesson_enactment_census.py`.
 * It discovers lane modules by globbing every `.pl` directly in
 * `curriculum/im/enactment/`, so a lane lands a file and the census picks it up
 * with no registration edit anywhere else. It then runs
 * `lesson_enactment:enact_lesson/2` on every lesson any lane declared, writes
 * one JSONL file per subclass, and prints a JSON summary on standard output.
 *
 * The glob is flat on purpose: one file directly in that directory is one lane.
 * A file a lane is built from rather than a lane itself — the data lane's lesson
 * rows, which are included and carry no module header, and the geometry lane's
 * figure algebra, which registers no form — lives in `enactment/support/` and
 * the glob does not reach it. Without that split the loader tried to
 * `use_module` an include file, reported a domain error, and counted a lane
 * that had loaded fine as one that had not.
 *
 * The count the census publishes comes from this run. Nothing here reads a
 * table of what the machines were meant to do.
 *
 * Usage:
 *   swipl -q -l paths.pl -s scripts/curriculum/run_lesson_enactments.pl \
 *         -g "main('<output-dir>')" -t halt
 *
 * The emission timestamp honours HERMES_ENACTMENT_STAMP when it is set, so a
 * caller that wants byte-stable rows can pin it.
 */

:- use_module(hermes(encyclopedia), []).
:- use_module(library(http/json)).
% Nothing imported. Every call below is module-qualified, and putting the
% contract's names into `user` would put them in reach of any lane that calls
% an unqualified predicate it does not define. That is not hypothetical: it is
% how a free-variable lambda in the geometry figure algebra changed behaviour
% depending on what else the process had loaded.
:- use_module(im_lessons(lesson_enactment), []).

main(OutDir) :-
    load_lanes(LaneCount),
    lesson_enactment:enactment_declared_lessons(Lessons),
    findall(Row, ( member(L, Lessons), lesson_row(L, Row) ), Rows0),
    sort(Rows0, Rows),
    emit_by_subclass(OutDir, Written),
    % A refusal names the machine a lesson would need. A lesson another lane
    % already enacts needs no such machine, whatever the refusing lane knew when
    % it wrote the refusal: the measurement lane refused IM-G3-U8-L12 because
    % its doing is a Notice and Wonder routine rather than a measurement, and
    % the data lane runs exactly that routine. Reporting it as an open refusal
    % beside its own enactment would put one lesson on both sides of the rung.
    % The refusal stays in the lane that wrote it, where it records why THAT
    % lane declined; what is filtered is the rung-level list.
    findall(_{lesson: LessonStr, machine_needed: MachineStr},
            ( lesson_enactment:lesson_enactment_refusal(Lesson, Machine),
              \+ ( lesson_enactment:enact_lesson(Lesson, _) ),
              atom_string(Lesson, LessonStr),
              atom_string(Machine, MachineStr)
            ),
            Refusals),
    findall(FormRow, form_row(FormRow), Forms),
    length(Lessons, Declared),
    include_enacted(Rows, Enacted),
    findall(L, ( member(R, Enacted), get_dict(lesson, R, L) ), Ls0),
    sort(Ls0, DistinctLessons),
    length(DistinctLessons, EnactedCount),
    length(Enacted, EnactmentCount),
    lesson_enactment:enactment_move_check(MoveCheck),
    lesson_enactment:enactment_solution_check(SolutionCheck),
    Summary = _{
        solution_check: SolutionCheck,
        lane_modules: LaneCount,
        declared_lessons: Declared,
        enacted_lessons: EnactedCount,
        enactments: EnactmentCount,
        move_check: MoveCheck,
        forms: Forms,
        lessons: Rows,
        refusals: Refusals,
        emissions: Written
    },
    json_write_dict(current_output, Summary, [width(0)]),
    nl.

include_enacted(Rows, Enacted) :-
    findall(R, ( member(R, Rows), get_dict(enacted, R, true) ), Enacted).

%!  load_lanes(-Count) is det.
%
%   Every `curriculum/im/enactment/*.pl` is a lane. Loading is guarded so one
%   lane that will not load names itself instead of taking the census down with
%   it; the count it contributes is then zero, which is the honest reading.
%
%   Nothing is imported into `user`. Four lanes export the contract's own names
%   from their own modules, having each written an `enact/3` before the contract
%   existed, and importing two of them into one namespace raised a permission
%   error per name. Those names reach the runner through the lane's registration
%   block on `lesson_enactment:`, so importing them here would add nothing and
%   the errors were noise about a collision that does not matter.
load_lanes(Count) :-
    lane_dir(Dir),
    atom_concat(Dir, '/*.pl', Pattern),
    expand_file_name(Pattern, Files),
    findall(F,
            ( member(F, Files),
              (   catch(user:use_module(F, []), E,
                        ( print_message(error, E), fail ))
              ->  true
              ;   format(user_error, "lane did not load: ~w~n", [F]), fail
              )
            ),
            Loaded),
    length(Loaded, Count).

lane_dir(Dir) :-
    module_property(lesson_enactment, file(Self)),
    file_directory_name(Self, ImDir),
    atom_concat(ImDir, '/enactment', Dir).

%!  lesson_row(+Lesson, -Row) is nondet.
%
%   One row per enactment, and a lesson can take more than one form, so a
%   lesson can contribute more than one row. The census counts distinct lessons
%   for the rung and keeps the rows for everything else.
lesson_row(Lesson, Row) :-
    atom_string(Lesson, LessonStr),
    (   lesson_enactment:enact_lesson(Lesson, E)
    *-> E = enactment(_, Form, _, Steps, Artifact),
        length(Steps, StepCount),
        lesson_enactment:enactment_verdict(E, Verdict),
        lesson_enactment:enactment_verdict_text(Verdict, VerdictText),
        verdict_class(Verdict, Class),
        atom_string(Form, FormStr),
        (   lesson_enactment:enactment_lane(Form, Subclass)
        ->  atom_string(Subclass, SubclassStr)
        ;   SubclassStr = ""
        ),
        artifact_kind(Artifact, Kind),
        lesson_enactment:enactment_row_dict(E, RowDict),
        get_dict(input_provenance, RowDict, Provenance),
        Row = _{lesson: LessonStr, enacted: true, form: FormStr,
                subclass: SubclassStr, steps: StepCount,
                verdict: VerdictText, verdict_class: Class,
                artifact_kind: Kind, input_provenance: Provenance}
    ;   (   lesson_enactment:lesson_enactment_form(Lesson, Form, _)
        ->  atom_string(Form, FormStr),
            (   lesson_enactment:enactment_lane(Form, Subclass)
            ->  atom_string(Subclass, SubclassStr)
            ;   SubclassStr = ""
            )
        ;   FormStr = "", SubclassStr = ""
        ),
        Row = _{lesson: LessonStr, enacted: false, form: FormStr,
                subclass: SubclassStr, steps: 0,
                verdict: "refused: enact/3 found no run on this lesson's inputs",
                verdict_class: "refused",
                artifact_kind: "none", input_provenance: "none"}
    ).

verdict_class(well_formed, "well_formed") :- !.
verdict_class(partial(_), "partial") :- !.
verdict_class(refused(_), "refused") :- !.
verdict_class(_, "unknown").

artifact_kind(List, "scene_and_record") :- is_list(List), List \== [], !.
artifact_kind(scene(_, _, _), "scene") :- !.
artifact_kind(printed(_), "printed") :- !.
artifact_kind(_, "none").

%!  form_row(-Row) is nondet.
form_row(_{form: FormStr, lane: LaneStr, gloss: GlossStr,
           moves: MoveCount, lessons: LessonCount,
           warrant: _{source: SourceStr, line: Line, text: TextStr}}) :-
    lesson_enactment:enactment_form(Form, Gloss, Warrant),
    atom_string(Form, FormStr),
    atom_string(Gloss, GlossStr),
    (   lesson_enactment:enactment_lane(Form, Lane)
    ->  atom_string(Lane, LaneStr)
    ;   LaneStr = ""
    ),
    lesson_enactment:enactment_form_move_count(Form, MoveCount),
    aggregate_all(count,
                  lesson_enactment:lesson_enactment_form(_, Form, _),
                  LessonCount),
    (   Warrant = warrant(_, Source, Line, Text)
    ->  atom_string(Source, SourceStr), atom_string(Text, TextStr)
    ;   SourceStr = "", Line = 0, TextStr = ""
    ).

%!  emit_by_subclass(+OutDir, -Written) is det.
emit_by_subclass(OutDir, Written) :-
    lesson_enactment:enactment_declared_lessons(Lessons),
    findall(Subclass-E,
            ( member(L, Lessons),
              lesson_enactment:enact_lesson(L, E),
              E = enactment(_, Form, _, _, _),
              lesson_enactment:enactment_lane(Form, Subclass)
            ),
            Pairs0),
    sort(Pairs0, Pairs),
    findall(S, member(S-_, Pairs), Subclasses0),
    sort(Subclasses0, Subclasses),
    findall(_{subclass: SubclassStr, path: PathStr, rows: Count},
            ( member(Subclass, Subclasses),
              findall(E, member(Subclass-E, Pairs), Es),
              length(Es, Count),
              write_rows(OutDir, Subclass, Es, Path),
              atom_string(Subclass, SubclassStr),
              atom_string(Path, PathStr)
            ),
            Written).

write_rows(OutDir, Subclass, Enactments, Relative) :-
    format(atom(File), '~w.jsonl', [Subclass]),
    atomic_list_concat([OutDir, File], '/', Path),
    file_directory_name(Path, Dir),
    make_directory_path(Dir),
    setup_call_cleanup(
        open(Path, write, Stream, [encoding(utf8)]),
        forall(member(E, Enactments),
               ( lesson_enactment:enactment_row_json(E, Line),
                 write(Stream, Line), nl(Stream) )),
        close(Stream)),
    atomic_list_concat([OutDir, File], '/', Relative).
