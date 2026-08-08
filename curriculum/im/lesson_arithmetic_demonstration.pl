/** <module> Lesson-bounded arithmetic demonstration for IM-G1-U3-L17
 *
 * This module composes existing compiled task evidence and additive action
 * automata for the monitoring-chart demonstration.  It admits only the four
 * unique productive addition tasks compiled from IM-G1-U3-L17.  An observed
 * answer may reproduce the productive make-ten trace, the dropped-leftover
 * deformation, or neither.  Reproduction is reported as a candidate reading,
 * never as a diagnosis of a student.
 *
 * The optional work transcription is request-local.  This module neither
 * stores nor returns its text and does not interpret free-form work.
 */

:- module(lesson_arithmetic_demonstration,
          [ lesson_arithmetic_demonstration_dict/5
          ]).

:- use_module(library(lists), [nth1/3]).
:- use_module(im_lessons('generated/compiled_task_instances')).
:- use_module(strategies(math/action_automata_registry)).

demonstration_lesson('IM-G1-U3-L17', "Make 10 to Add").

productive_strategy(make_ten_split_leftover).
incorrect_strategy(make_ten_drop_leftover).

%! lesson_arithmetic_demonstration_dict(+Lesson, +TaskId, +ObservedAnswer,
%!                                      +WorkTranscription, -Dict) is det.
%
%  Enumerate the compiled lesson tasks and, when a task and integer answer are
%  supplied, run the synchronized productive/incorrect action pair.  Every
%  refusal is data so the page can state it without falling back to a generic
%  worker failure.
lesson_arithmetic_demonstration_dict(Lesson, TaskId0, ObservedAnswer,
                                     WorkTranscription, Dict) :-
    demonstration_lesson(SupportedLesson, LessonName),
    lesson_task_dicts(Tasks),
    transcription_status(WorkTranscription, Transcription),
    normalize_task_id(TaskId0, TaskId),
    (   Lesson \== SupportedLesson
    ->  refusal_dict(Lesson, LessonName, Tasks, Transcription,
                     unsupported_lesson,
                     "This demonstration runs only IM-G1-U3-L17, Make 10 to Add.",
                     Dict)
    ;   TaskId == ""
    ->  interpretation_limit_text(Limit),
        Dict = _{
            lesson_code: SupportedLesson,
            lesson_name: LessonName,
            status: "ready",
            tasks: Tasks,
            work_transcription: Transcription,
            reading: _{
                status: "not_run",
                message: "Choose a compiled lesson task and enter the observed answer."
            },
            interpretation_limit: Limit
        }
    ;   \+ integer(ObservedAnswer)
    ->  refusal_dict(SupportedLesson, LessonName, Tasks, Transcription,
                     invalid_observed_answer,
                     "The observed answer must be a whole number.",
                     Dict)
    ;   \+ task_by_id(Tasks, TaskId, _)
    ->  refusal_dict(SupportedLesson, LessonName, Tasks, Transcription,
                     task_outside_lesson,
                     "That task is not one of the compiled tasks for this lesson.",
                     Dict)
    ;   task_by_id(Tasks, TaskId, Task),
        run_selected_task(Task, ObservedAnswer, Tasks, LessonName,
                          Transcription, Dict)
    ).

interpretation_limit_text(
    "A reproduced answer is a candidate explanation. It does not establish what a student was thinking.").

normalize_task_id(Value, TaskId) :-
    (   string(Value)
    ->  TaskId = Value
    ;   atom(Value)
    ->  atom_string(Value, TaskId)
    ;   TaskId = ""
    ).

transcription_status(Value, _{
        status: "not_supplied",
        message: "No work transcription was supplied."
    }) :-
    (Value == "" ; Value == null),
    !.
transcription_status(_Value, _{
        status: "received_not_interpreted",
        message: "The transcription stays in this request. This operation does not interpret it as evidence of a misconception."
    }).

refusal_dict(Lesson, LessonName, Tasks, Transcription, Reason, Message, Dict) :-
    interpretation_limit_text(Limit),
    Dict = _{
        lesson_code: Lesson,
        lesson_name: LessonName,
        status: "refused",
        tasks: Tasks,
        work_transcription: Transcription,
        reading: _{status: "refused", reason: Reason, message: Message},
        interpretation_limit: Limit
    }.

run_selected_task(Task, ObservedAnswer, Tasks, LessonName, Transcription, Dict) :-
    get_dict(a, Task, A),
    get_dict(b, Task, B),
    productive_strategy(ProductiveKind),
    incorrect_strategy(IncorrectKind),
    run_trace(ProductiveKind, A, B, ProductiveTrace),
    run_trace(IncorrectKind, A, B, IncorrectTrace),
    reading_for_traces(ObservedAnswer, ProductiveTrace, IncorrectTrace, Reading),
    interpretation_limit_text(Limit),
    Dict = _{
        lesson_code: 'IM-G1-U3-L17',
        lesson_name: LessonName,
        status: "complete",
        tasks: Tasks,
        selected_task: Task,
        observed_answer: ObservedAnswer,
        work_transcription: Transcription,
        productive_trace: ProductiveTrace,
        incorrect_trace: IncorrectTrace,
        reading: Reading,
        interpretation_limit: Limit,
        execution_rung: "lesson_bounded_arithmetic",
        lesson_enactment_run_used: false
    }.

run_trace(Kind, A, B, Dict) :-
    (   catch(action_automata_registry:run_action_automaton(
                  addition, Kind, A, B, Outcome, Trace), _, fail)
    ->  outcome_trace_dict(Kind, Outcome, Trace, Dict)
    ;   atom_string(Kind, KindString),
        Dict = _{
            strategy: KindString,
            ok: false,
            result: null,
            steps: [],
            message: "The existing action machine refused these task inputs."
        }
    ).

outcome_trace_dict(Kind, action_outcome(_OutcomeKind, Fields), Trace, Dict) :-
    atom_string(Kind, KindString),
    outcome_field(Fields, classification, unknown, Classification),
    outcome_field(Fields, result, null, Result),
    outcome_field(Fields, expected, null, Expected),
    outcome_field(Fields, validity, unknown, Validity),
    atom_or_term_string(Classification, ClassificationString),
    atom_or_term_string(Validity, ValidityString),
    trace_step_dicts(Trace, Steps),
    Dict0 = _{
        strategy: KindString,
        operation: "addition",
        ok: true,
        classification: ClassificationString,
        result: Result,
        expected: Expected,
        validity: ValidityString,
        steps: Steps,
        source: "knowledge/strategies/math/sar_add_action_pairs.pl"
    },
    optional_outcome_evidence(Fields, Dict0, Dict).

outcome_field(Fields, Functor, Default, Value) :-
    (   member(Field, Fields),
        compound(Field),
        compound_name_arguments(Field, Functor, [Value0])
    ->  Value = Value0
    ;   Value = Default
    ).

optional_outcome_evidence(Fields, Dict0, Dict) :-
    (   outcome_field(Fields, misconception_family, none, Family),
        Family \== none
    ->  atom_or_term_string(Family, FamilyString),
        Dict1 = Dict0.put(misconception_family, FamilyString)
    ;   Dict1 = Dict0
    ),
    (   outcome_field(Fields, viability_context, none, Viability),
        Viability \== none
    ->  term_string(Viability, ViabilityString, [quoted(false)]),
        Dict = Dict1.put(viability_context, ViabilityString)
    ;   Dict = Dict1
    ).

trace_step_dicts(Trace, Steps) :-
    findall(_{step: Index, action: ActionString},
            ( nth1(Index, Trace, Action),
              term_string(Action, ActionString, [quoted(false)])
            ),
            Steps).

atom_or_term_string(Value, String) :-
    (   atom(Value)
    ->  atom_string(Value, String)
    ;   string(Value)
    ->  String = Value
    ;   term_string(Value, String, [quoted(false)])
    ).

reading_for_traces(_Observed, Productive, Incorrect, _{
        status: "abstention",
        reason: "machine_refused",
        message: "The action machines did not both run on this compiled task."
    }) :-
    ( get_dict(ok, Productive, ProductiveOk), ProductiveOk \== true
    ; get_dict(ok, Incorrect, IncorrectOk), IncorrectOk \== true
    ),
    !.
reading_for_traces(Observed, Productive, _Incorrect, _{
        status: "productive_trace",
        candidate: "make_ten_split_leftover",
        message: "The productive make-ten trace reproduces the observed answer."
    }) :-
    get_dict(result, Productive, ProductiveResult),
    Observed =:= ProductiveResult,
    !.
reading_for_traces(Observed, _Productive, Incorrect, _{
        status: "candidate_deformation",
        candidate: "make_ten_drop_leftover",
        misconception_family: "dropped_leftover_after_make_ten",
        human_endorsement_required: true,
        message: "The dropped-leftover deformation reproduces the observed answer. Treat it as a candidate explanation, not a diagnosis."
    }) :-
    get_dict(result, Incorrect, IncorrectResult),
    Observed =:= IncorrectResult,
    !.
reading_for_traces(_Observed, _Productive, _Incorrect, _{
        status: "abstention",
        reason: "no_licensed_trace_matches",
        message: "Neither licensed trace reproduces the observed answer. Hermes abstains."
    }).

lesson_task_dicts(Tasks) :-
    setof(A-B,
          Evidence^(compiled_task_instances:compiled_lesson_task_instance(
                       'IM-G1-U3-L17', productive-add(A, B), Evidence)),
          OperandPairs),
    maplist(lesson_task_dict, OperandPairs, Tasks).

task_by_id(Tasks, TaskId, Task) :-
    member(Task, Tasks),
    get_dict(task_id, Task, TaskId),
    !.

lesson_task_dict(A-B, Dict) :-
    format(string(TaskId), "add-~d-~d", [A, B]),
    format(string(Expression), "~d + ~d", [A, B]),
    findall(Source,
            ( compiled_task_instances:compiled_lesson_task_instance(
                  'IM-G1-U3-L17', productive-add(A, B), Evidence),
              task_evidence_dict(Evidence, Source)
            ),
            Sources),
    Dict = _{
        task_id: TaskId,
        operation: "addition",
        a: A,
        b: B,
        expression: Expression,
        sources: Sources
    }.

task_evidence_dict(
    task_evidence(rule(Rule), source(Path, lines(Start, End)),
                  position(Position), excerpt(Excerpt)),
    _{rule: RuleString, source: PathString, lines: _{start: Start, end: End},
      position: PositionString, excerpt: Excerpt}) :-
    !,
    atom_or_term_string(Rule, RuleString),
    atom_or_term_string(Path, PathString),
    term_string(Position, PositionString, [quoted(false)]).
task_evidence_dict(Evidence, _{evidence: EvidenceString}) :-
    term_string(Evidence, EvidenceString, [quoted(false)]).
