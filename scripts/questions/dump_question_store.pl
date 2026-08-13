#!/usr/bin/env swipl
% Read the compiled question records as terms and emit one JSON object per record.
:- initialization(main, main).
:- use_module(library(http/json)).

main([Source]) :-
    setup_call_cleanup(open(Source, read, Stream, [encoding(utf8)]),
                       read_records(Stream, 0),
                       close(Stream)).

read_records(Stream, N) :-
    read_term(Stream, Term, []),
    (   Term == end_of_file
    ->  format(user_error, "records: ~w~n", [N])
    ;   ( emit(Term, N) -> N1 is N + 1 ; N1 = N ),
        read_records(Stream, N1)
    ).

emit(compiled_lesson_guide_question(Lesson, Q), Index) :-
    Q = guide_question(Type, Text, source_guide(Guide), source_span(A, B),
                       activity_location(Loc), label_origin(Origin),
                       review_status(Status), review_evidence(Evidence)),
    term_string(Evidence, EvidenceText),
    atom_string(Lesson, LessonS), atom_string(Type, TypeS),
    atom_string(Guide, GuideS), atom_string(Origin, OriginS),
    atom_string(Status, StatusS),
    Dict = _{record_index: Index, lesson: LessonS, type: TypeS, text: Text,
             source_guide: GuideS, span_start: A, span_end: B,
             activity_location: Loc, label_origin: OriginS,
             review_status: StatusS, review_evidence: EvidenceText},
    json_write_dict(current_output, Dict, [width(0)]), nl.
