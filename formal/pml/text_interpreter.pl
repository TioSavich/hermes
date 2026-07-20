/** <module> PML text interpreter for encoded lesson text
 *
 * This module emits the reader-facing shape used by pml-discourse-instrument:
 * `reader_axiom/4` facts plus `passage_mode/3` facts. The current
 * implementation is intentionally conservative: it only emits facts when the
 * encoded lesson text contains the phrases that license the PML reading.
 */
:- module(text_interpreter,
          [ interpret_lesson_text/2,
            write_lesson_reader_facts/2,
            lesson_text_source/2,
            reader_axiom/4,
            passage_mode/3
          ]).

:- use_module(library(readutil)).
:- use_module(pml(pml_operators), []).


%!  interpret_lesson_text(+LessonCode, -Facts) is semidet.
%
%   Reads the encoded lesson text and emits PML reader facts.
interpret_lesson_text(Code, Facts) :-
    lesson_text_source(Code, Path),
    read_file_to_string(Path, Text, []),
    findall(Fact, pml_fact_from_text(Code, Text, Fact), Facts),
    Facts \== [].


%!  write_lesson_reader_facts(+LessonCode, +Path) is semidet.
%
%   Export the interpreted PML facts as the plain `*_axioms.pl` fact stream
%   consumed by pml-testing-bridge corpus analysis tools.
write_lesson_reader_facts(Code, Path) :-
    interpret_lesson_text(Code, Facts),
    setup_call_cleanup(
        open(Path, write, Stream, [encoding(utf8)]),
        ( format(Stream, "% Generated from formal/pml/text_interpreter.pl for ~q.~n", [Code]),
          forall(member(Fact, Facts),
                 ( write_term(Stream, Fact, [quoted(true), numbervars(true)]),
                   write(Stream, '.\n')
                 ))
        ),
        close(Stream)
    ).


%!  lesson_text_source(+LessonCode, -Path) is semidet.
lesson_text_source(Code, Path) :-
    nonvar(Code),
    explicit_lesson_text_source(Code, Path).
lesson_text_source(Code, Path) :-
    var(Code),
    enumerated_teacher_guide_source(Code, Path).
lesson_text_source(Code, Path) :-
    var(Code),
    enumerated_scope_sequence_source(Code, Path).
lesson_text_source(Code, Path) :-
    nonvar(Code),
    \+ explicit_lesson_text_source(Code, _),
    im_teacher_guide_relative_path(Code, RelativePath),
    absolute_file_name(
        geometry(RelativePath),
        Path,
        [ access(read),
          file_errors(fail)
        ]
    ).
lesson_text_source(Code, Path) :-
    nonvar(Code),
    \+ explicit_lesson_text_source(Code, _),
    scope_sequence_source(Code, Path).


:- multifile explicit_lesson_text_source/2.
:- discontiguous explicit_lesson_text_source/2.

explicit_lesson_text_source('IM-G1-U3-L17', Path) :-
    absolute_file_name(
        geometry('corpus/im_teacher_guides/grade1/unit3/lesson17.md'),

        Path,
        [access(read)]
    ).
explicit_lesson_text_source('IM-G2-U1-L3', Path) :-
    absolute_file_name(
        geometry('corpus/im_teacher_guides/grade2/unit1/lesson3.md'),
        Path,
        [access(read)]
    ).


%!  reader_axiom(?AxiomId, ?Premises, ?Conclusion, ?Polarity) is nondet.
%
%   Reader-compatible direct predicate surface.
reader_axiom(AxiomId, Premises, Conclusion, Polarity) :-
    interpret_lesson_text(_, Facts),
    member(reader_axiom(AxiomId, Premises, Conclusion, Polarity), Facts).


%!  passage_mode(?SpanId, ?Mode, ?Reading) is nondet.
passage_mode(SpanId, Mode, Reading) :-
    interpret_lesson_text(_, Facts),
    member(passage_mode(SpanId, Mode, Reading), Facts).


pml_fact_from_text('IM-G1-U3-L17',
                   Text,
                   reader_axiom(im_g1_u3_l17_purpose_make_ten,
                                [ lesson_purpose(decompose_one_addend_to_make_ten),
                                  lesson_purpose(add_within_20)
                                ],
                                n(comp_nec(make_ten_strategy_is_lesson_target)),
                                compressive)) :-
    text_contains_all(Text, ["decompose one addend", "make a ten"]).

pml_fact_from_text('IM-G1-U3-L17',
                   Text,
                   reader_axiom(im_g1_u3_l17_equation_recording,
                                [ representation(student_methods_recorded_with_equations)
                                ],
                                o(comp_nec(student_methods_are_recorded_with_equations)),
                                compressive)) :-
    text_contains_all(Text, ["Student methods are recorded with equations"]).

pml_fact_from_text('IM-G1-U3-L17',
                   Text,
                   reader_axiom(im_g1_u3_l17_student_strategy_explanation,
                                [ learning_goal(explain_strategies_within_20),
                                  teacher_prompt(how_do_you_know),
                                  n(comp_nec(make_ten_strategy_is_lesson_target))
                                ],
                                s(exp_poss(student_explains_own_make_ten_strategy)),
                                expansive)) :-
    text_contains_all(Text, ["Explain (orally) strategies", "How do you know"]).

pml_fact_from_text('IM-G1-U3-L17',
                   Text,
                   passage_mode(im_g1_u3_l17_lesson,
                                successful_rhythm,
                                "The lesson fixes make-ten as a target strategy, records student methods as equations, and opens space for students to explain how their own decomposition strategy works.")) :-
    text_contains_all(Text,
                      ["make 10", "Student methods are recorded with equations", "How do you know"]).

pml_fact_from_text('IM-G2-U1-L3',
                   Text,
                   reader_axiom(im_g2_u1_l3_unknown_addend_equations,
                                [ lesson_purpose(find_unknown_number_within_20),
                                  representation(addition_and_subtraction_equations)
                                ],
                                n(comp_nec(unknown_addend_equations_within_20)),
                                compressive)) :-
    text_contains_all(Text, ["find the number that makes equations true within 20"]).

pml_fact_from_text('IM-G2-U1-L3',
                   Text,
                   reader_axiom(im_g2_u1_l3_explain_add_sub_relation,
                                [ learning_goal(explain_strategy_for_unknown_addend),
                                  n(comp_nec(unknown_addend_equations_within_20))
                                ],
                                s(exp_poss(student_explains_add_sub_relation)),
                                expansive)) :-
    text_contains_all(Text, ["Explain (orally) a strategy", "relationship of addition and subtraction"]).

pml_fact_from_text('IM-G2-U1-L3',
                   Text,
                   passage_mode(im_g2_u1_l3_lesson,
                                successful_rhythm,
                                "The lesson fixes unknown-addend equations within 20, uses addition-subtraction relations as the bridge, and asks students to explain their methods.")) :-
    text_contains_all(Text,
                      ["find the numbers that make equations true", "relationship of addition and subtraction", "explain their methods"]).

pml_fact_from_text(Code,
                   Text,
                   reader_axiom(AxiomId,
                                [lesson_text_source(Code)],
                                n(comp_nec(lesson_purpose(Code))),
                                compressive)) :-
    nonvar(Code),
    lesson_fact_id(Code, lesson_purpose, AxiomId),
    teacher_guide_lesson_purpose_text(Text).

pml_fact_from_text(Code,
                   Text,
                   reader_axiom(AxiomId,
                                [n(comp_nec(lesson_purpose(Code)))],
                                s(exp_poss(student_orally_explains_strategy(Code))),
                                expansive)) :-
    nonvar(Code),
    lesson_fact_id(Code, oral_strategy_explanation, AxiomId),
    text_contains_all(Text, ["Explain (orally)", "strategies"]).

pml_fact_from_text(Code,
                   Text,
                   passage_mode(SpanId,
                                successful_rhythm,
                                "The lesson text fixes a lesson purpose and asks students to explain strategies orally.")) :-
    nonvar(Code),
    lesson_fact_id(Code, lesson_text, SpanId),
    teacher_guide_lesson_purpose_text(Text),
    text_contains_all(Text, ["Explain (orally)", "strategies"]).

pml_fact_from_text(Code,
                   Text,
                   reader_axiom(AxiomId,
                                [lesson_text_source(Code)],
                                n(comp_nec(teacher_guide_lesson(Code, Title))),
                                compressive)) :-
    nonvar(Code),
    lesson_fact_id(Code, teacher_guide_anchor, AxiomId),
    \+ teacher_guide_lesson_purpose_text(Text),
    teacher_guide_lesson_title(Code, Text, Title).

pml_fact_from_text(Code,
                   Text,
                   passage_mode(SpanId,
                                flat,
                                "The teacher-guide text supplies the lesson anchor and title, but no explicit lesson-purpose section.")) :-
    nonvar(Code),
    lesson_fact_id(Code, teacher_guide_text, SpanId),
    \+ teacher_guide_lesson_purpose_text(Text),
    teacher_guide_lesson_title(Code, Text, _Title).

pml_fact_from_text(Code,
                   Text,
                   reader_axiom(AxiomId,
                                [lesson_text_source(Code)],
                                n(comp_nec(scope_sequence_lesson(Code, Title))),
                                compressive)) :-
    nonvar(Code),
    lesson_fact_id(Code, scope_sequence_anchor, AxiomId),
    scope_sequence_lesson_title(Code, Text, Title).

pml_fact_from_text(Code,
                   Text,
                   passage_mode(SpanId,
                                flat,
                                "The scope-and-sequence text supplies the lesson anchor and title, but no teacher-guide lesson purpose or strategy-explanation text.")) :-
    nonvar(Code),
    lesson_fact_id(Code, scope_sequence_text, SpanId),
    scope_sequence_lesson_title(Code, Text, _Title).


im_teacher_guide_relative_path(Code, RelativePath) :-
    im_lesson_code_path_parts(Code, GradeDirectory, UnitNumber, LessonNumber),
    format(atom(RelativePath),
           'corpus/im_teacher_guides/~w/unit~d/lesson~d.md',
           [GradeDirectory, UnitNumber, LessonNumber]).

enumerated_teacher_guide_source(Code, Path) :-
    absolute_file_name(
        geometry('corpus/im_teacher_guides'),
        Root,
        [ file_type(directory),
          access(read)
        ]
    ),
    directory_files(Root, GradeDirectories),
    member(GradeDirectory, GradeDirectories),
    grade_directory_part(GradeDirectory, GradePart),
    directory_file_path(Root, GradeDirectory, GradePath),
    exists_directory(GradePath),
    directory_files(GradePath, UnitDirectories),
    member(UnitDirectory, UnitDirectories),
    directory_number(unit, UnitDirectory, UnitNumber),
    directory_file_path(GradePath, UnitDirectory, UnitPath),
    exists_directory(UnitPath),
    directory_files(UnitPath, LessonFiles),
    member(LessonFile, LessonFiles),
    file_name_extension(LessonBase, md, LessonFile),
    directory_number(lesson, LessonBase, LessonNumber),
    directory_file_path(UnitPath, LessonFile, Path),
    format(atom(UnitPart), 'U~d', [UnitNumber]),
    format(atom(LessonPart), 'L~d', [LessonNumber]),
    atomic_list_concat(['IM', GradePart, UnitPart, LessonPart], '-', Code).

scope_sequence_source(Code, Path) :-
    im_lesson_code_numbers(Code, Grade, _UnitNumber, _LessonNumber),
    between(6, 8, Grade),
    format(atom(RelativePath), 'corpus/im_scope_and_sequence/grade~d.md', [Grade]),
    absolute_file_name(
        geometry(RelativePath),
        Path,
        [ access(read),
          file_errors(fail)
        ]
    ).

enumerated_scope_sequence_source(Code, Path) :-
    between(6, 8, Grade),
    format(atom(RelativePath), 'corpus/im_scope_and_sequence/grade~d.md', [Grade]),
    absolute_file_name(
        geometry(RelativePath),
        Path,
        [ access(read),
          file_errors(fail)
        ]
    ),
    read_file_to_string(Path, Text, []),
    scope_sequence_lesson_title(Code, Text, _Title).

im_lesson_code_path_parts(Code, GradeDirectory, UnitNumber, LessonNumber) :-
    atom(Code),
    atomic_list_concat(['IM', GradePart, UnitPart, LessonPart], '-', Code),
    grade_part_directory(GradePart, GradeDirectory),
    lesson_part_number('U', UnitPart, UnitNumber),
    lesson_part_number('L', LessonPart, LessonNumber).

im_lesson_code_numbers(Code, Grade, UnitNumber, LessonNumber) :-
    atom(Code),
    atomic_list_concat(['IM', GradePart, UnitPart, LessonPart], '-', Code),
    grade_part_number(GradePart, Grade),
    lesson_part_number('U', UnitPart, UnitNumber),
    lesson_part_number('L', LessonPart, LessonNumber).

grade_part_directory('GK', kindergarten).
grade_part_directory(GradePart, GradeDirectory) :-
    atom_concat('G', GradeAtom, GradePart),
    atom_number(GradeAtom, GradeNumber),
    GradeNumber >= 1,
    format(atom(GradeDirectory), 'grade~d', [GradeNumber]).

grade_part_number('GK', 0).
grade_part_number(GradePart, GradeNumber) :-
    atom_concat('G', GradeAtom, GradePart),
    atom_number(GradeAtom, GradeNumber).

grade_directory_part(kindergarten, 'GK').
grade_directory_part(GradeDirectory, GradePart) :-
    atom_concat(grade, GradeAtom, GradeDirectory),
    atom_number(GradeAtom, GradeNumber),
    GradeNumber >= 1,
    format(atom(GradePart), 'G~d', [GradeNumber]).

directory_number(Prefix, Directory, Number) :-
    atom_concat(Prefix, NumberAtom, Directory),
    atom_number(NumberAtom, Number).

lesson_part_number(Prefix, Part, Number) :-
    atom_concat(Prefix, NumberAtom, Part),
    atom_number(NumberAtom, Number).

lesson_fact_id(Code, Suffix, FactId) :-
    lesson_code_id_base(Code, Base),
    atomic_list_concat([Base, Suffix], '_', FactId).

lesson_code_id_base(Code, Base) :-
    downcase_atom(Code, LowerCode),
    atom_chars(LowerCode, Chars),
    maplist(lesson_code_id_char, Chars, IdChars),
    atom_chars(Base, IdChars).

lesson_code_id_char('-', '_') :- !.
lesson_code_id_char(Char, Char).


text_contains_all(Text, Needles) :-
    forall(member(Needle, Needles), sub_string(Text, _, _, _, Needle)).

teacher_guide_lesson_purpose_text(Text) :-
    once((
        sub_string(Text, _, _, _, "## Lesson Purpose"),
        (   sub_string(Text, _, _, _, "The purpose of this lesson is")
        ;   sub_string(Text, _, _, _, "The mathematical purpose of this lesson is")
        ;   sub_string(Text, _, _, _, "The purpose of this optional lesson is")
        )
    )).

teacher_guide_lesson_title(Code, Text, Title) :-
    format(string(Anchor), "_Anchor ID: `~w`", [Code]),
    sub_string(Text, _, _, _, Anchor),
    markdown_h1_title(Text, Title).

markdown_h1_title(Text, Title) :-
    split_string(Text, "\n", "\r", Lines),
    member(Line, Lines),
    sub_string(Line, 0, 2, _, "# "),
    sub_string(Line, 2, _, 0, Title),
    string_length(Title, Length),
    Length > 0.

scope_sequence_lesson_title(Code, Text, Title) :-
    split_string(Text, "\n", "\r", Lines),
    member(Line, Lines),
    scope_sequence_lesson_line(Line, CodeString, Title),
    atom_string(Code, CodeString).

scope_sequence_lesson_line(Line, CodeString, Title) :-
    sub_string(Line, 0, _, _, "- **Lesson "),
    sub_string(Line, TitlePrefixStart, 4, _, ":** "),
    TitleStart is TitlePrefixStart + 4,
    sub_string(Line, CodeDelimiterStart, 3, _, "  `"),
    CodeDelimiterStart > TitleStart,
    TitleLength is CodeDelimiterStart - TitleStart,
    sub_string(Line, TitleStart, TitleLength, _, Title),
    CodeStart is CodeDelimiterStart + 3,
    string_length(Line, LineLength),
    CodeLength is LineLength - CodeStart - 1,
    CodeLength > 0,
    sub_string(Line, CodeStart, CodeLength, 1, CodeString).
