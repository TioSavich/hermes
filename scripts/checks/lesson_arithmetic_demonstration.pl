/** Focused contract check for the IM-G1-U3-L17 arithmetic demonstration. */

:- use_module(im_lessons(lesson_arithmetic_demonstration)).

main :-
    lesson_arithmetic_demonstration_dict(
        'IM-G1-U3-L17', "", "", "", Catalog),
    get_dict(tasks, Catalog, Tasks),
    maplist(task_id, Tasks, TaskIds),
    TaskIds == ["add-3-9", "add-6-8", "add-7-5", "add-8-6"],
    forall(member(TaskId, TaskIds), productive_task_runs(TaskId)),
    reading_status("add-8-6", 14, "productive_trace"),
    reading_status("add-8-6", 10, "candidate_deformation"),
    reading_status("add-8-6", 999, "abstention"),
    lesson_arithmetic_demonstration_dict(
        'IM-G1-U3-L17', "add-8-6", "ten", "", Refused),
    Refused.status == "refused",
    Refused.reading.reason == invalid_observed_answer,
    lesson_arithmetic_demonstration_dict(
        'IM-G1-U3-L2', "add-8-6", 10, "", WrongLesson),
    WrongLesson.status == "refused",
    WrongLesson.reading.reason == unsupported_lesson,
    format("lesson arithmetic demonstration: 4 compiled tasks, productive/candidate/abstention/refusal PASS~n").

task_id(Task, TaskId) :-
    get_dict(task_id, Task, TaskId).

productive_task_runs(TaskId) :-
    lesson_arithmetic_demonstration_dict(
        'IM-G1-U3-L17', TaskId, 999, "", Result),
    Result.productive_trace.ok == true,
    Result.incorrect_trace.ok == true,
    Result.lesson_enactment_run_used == false.

reading_status(TaskId, Answer, Status) :-
    lesson_arithmetic_demonstration_dict(
        'IM-G1-U3-L17', TaskId, Answer, "", Result),
    Result.reading.status == Status.

