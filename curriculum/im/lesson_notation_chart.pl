/** <module> Lesson-specific notation monitoring charts
 *
 * The notation cousin of lesson_deformation_chart.pl. Given a real
 * Illustrative Mathematics lesson hosting addition, subtraction, or
 * multiplication, this assembles the monitoring chart a teacher would want
 * before the lesson runs: the PRODUCTIVE inscription
 * for a representative equation the lesson's operation produces, beside the
 * LIKELY written-work deformations to watch for on that inscription -- a
 * reversed numeral, an equals sign read as "makes", a transposed answer --
 * every deformation rendered over the SAME representative equation.
 *
 * This file is a PARALLEL chart to lesson_deformation_chart.pl, not an edit of
 * it. The fraction chart is keyed on frac(M,N) and emits
 * fraction/numerator/denominator fields; it backs the live grade-3 fraction
 * monitoring charts and is left byte-for-byte untouched. This chart is keyed on
 * equation(A, Op, B, R) and emits equation/operands fields. The two cell shapes
 * are deliberately distinct so the two pipelines never collide.
 *
 * An honesty boundary the chart must carry, not hide. Lessons host notation
 * charts through their encoded addition, subtraction, or multiplication
 * operation. Each lesson keeps one chart; if it hosts several operations, the
 * chart chooses addition, then subtraction, then multiplication. A notation
 * deformation appears only when cited evidence admits it through the grammar's
 * misconception gate. The chart is a PARAMETRIC render over a representative
 * equation, not a count of corpus instances of the deformation in the lesson.
 * Every deformation carries its provenance (corpus_attested | literature_only)
 * read off the grammar's own Evidence dict via notation_deformation_evidence/2.
 *
 * Three layers, all read-only over the grammar, the parametric notation
 * generators, and the lesson facts:
 *
 *   1. The hosting lessons. A real IM lesson hosts the chart when
 *      lesson_monitoring:specific_attachment_operation/2 attaches addition,
 *      subtraction, or multiplication. The representative equation is chosen
 *      from the selected operation and its encoded strategy range.
 *
 *   2. lesson_likely_notation_deformation(Code, Host, equation(A,Op,B,R),
 *      notation_error(Type)). For a hosting lesson and its representative
 *      equation, the notation deformations LIKELY on that inscription. Only
 *      deformations the grammar admits for the chosen equation are surfaced:
 *      mirror_written_numeral needs a reversal-prone digit in the operands,
 *      digit_transposition needs a multi-digit answer, operational_equals_chain
 *      applies to any written equation. Eligibility is the gate's, not a hard-coded
 *      list here.
 *
 *   3. notation_monitoring_chart(Code, Doc). The assembled chart dict: the
 *      lesson metadata, the representative-equation host note, and one cell per
 *      host carrying the productive notation scene plus the gated deformation
 *      scenes, each tagged with its provenance.
 *
 * GROUNDING vs RENDER separation is preserved: this file decides WHICH lessons
 * host a notation chart and WHICH representative equation each renders over; the
 * grammar decides whether a deformation is a labeled misconception; the notation
 * compiler places glyphs; the drawer projects. It edits neither the grammar nor
 * the drawer nor the fraction chart.
 *
 * Load through paths.pl (the render(...) and lessons(...) search paths).
 */

:- module(lesson_notation_chart,
          [ notation_chart_lesson/4,             % ?Code, ?Title, ?Standards, ?Hosts
            lesson_representative_equation/2,     % ?Code, ?equation(A,Op,B,R)
            lesson_likely_notation_deformation/4, % ?Code, ?Host, ?equation(A,Op,B,R), ?notation_error(Type)
            gated_as_notation_misconception/3,    % +equation(A,Op,B,R), +notation_error(Type), -Evidence
            productive_notation_cell_scene/3,     % +Code, +equation(A,Op,B,R), -Dict
            notation_deformation_cell_scene/4,    % +Code, +equation(A,Op,B,R), +notation_error(Type), -Dict
            notation_chart_cell/4,                % +Code, +Host, +equation(A,Op,B,R), -CellDict
            notation_monitoring_chart/2,          % +Code, -Doc
            notation_monitoring_chart_to_file/2   % +Doc, +Path
          ]).

:- use_module(library(http/json), [json_write_dict/3]).
:- use_module(library(lists)).

:- use_module(render(representation_grammar)).
:- use_module(render(notation_scene)).
:- use_module(render(parametric_notation_deformation)).
:- use_module(lessons('im/generated/compiled_task_instances')).

% The hosting lessons come from the encoded IM corpus. lesson_monitoring loads
% grade_k.pl through grade_8.pl and supplies the strategy_info/3 and
% misconception bodies the grade clauses call, so explicit_lesson_strategy/4 is
% actually CALLABLE here (not just defined). This is the same loading discipline
% the fraction chart relies on for its grade-3 facts.
:- use_module(lessons('im/lesson_monitoring')).

% =========================================================================
% 1. The hosting lessons and their representative equation.
% =========================================================================
%
% A real IM lesson hosts a notation chart when it carries an addition,
% subtraction, or multiplication attachment and has a registered productive
% task instance for that operation. The equation comes from that task; an
% absent lesson fact is never filled with a shared exemplar.
% The host is the inscription language itself (notation): the deformation is a
% written-work botch, drawn over a representative equation from the lesson's
% operation, not over a corpus instance.
%
% notation_chart_lesson(Code, Title, Standards, Hosts).
%   Code      : the IM lesson code (matches curriculum/im/grade_k.pl through
%               grade_8.pl).
%   Title     : a readable title built from the code (the grade facts carry
%               strategies and standards, not titles; the title is the code).
%   Standards : the standards the encoded lesson addresses, via lesson_monitoring.
%   Hosts     : [notation] -- the single host language for a written-equation
%               chart. Kept as a list to mirror the fraction chart's Hosts slot.

notation_chart_lesson(Code, Title, Standards, [notation]) :-
    hosting_lesson(Code, _Operation),
    lesson_title(Code, Title),
    lesson_standard_codes(Code, Standards).

% hosting_lesson(Code, Operation): the highest-priority operation with both a
% lesson attachment and an equation-bearing productive task instance.
hosting_lesson(Code, Operation) :-
    nonvar(Code),
    !,
    once(hosting_candidate(Code, Operation)).
hosting_lesson(Code, Operation) :-
    setof(C-O, hosting_candidate(C, O), Pairs),
    member(Code-Operation, Pairs).

hosting_candidate(Code, Operation) :-
    lesson_monitoring:im_lesson(Code, _, _, _, _, _),
    notation_operation(Operation),
    lesson_operation_with_registered_equation(Code, Operation, _),
    \+ higher_priority_hosting_operation(Code, Operation).

notation_operation(addition).
notation_operation(subtraction).
notation_operation(multiplication).

higher_priority_hosting_operation(Code, subtraction) :-
    lesson_operation_with_registered_equation(Code, addition, _).
higher_priority_hosting_operation(Code, multiplication) :-
    ( lesson_operation_with_registered_equation(Code, addition, _)
    ; lesson_operation_with_registered_equation(Code, subtraction, _)
    ).

% lesson_title(Code, Title): the grade facts do not carry lesson titles, so the
% title is the lesson code as a string. Honest about what the data holds.
lesson_title(Code, Title) :-
    atom_string(Code, Title).

% lesson_standard_codes(Code, Codes): the standard codes the encoded lesson
% addresses, read through lesson_monitoring. Empty list if none are encoded.
lesson_standard_codes(Code, StandardStrings) :-
    findall(SC,
            lesson_monitoring:explicit_lesson_standard(Code, _Framework, SC, _Stmt),
            SCs0),
    sort(SCs0, SCs),
    maplist(atom_string, SCs, StandardStrings).

% lesson_representative_equation(Code, equation(A, Op, B, R)): the equation the
% chart renders. It is the first registered productive task for the selected
% operation, preserving the compiled source order as the lesson's task order.
lesson_representative_equation(Code, Equation) :-
    hosting_lesson(Code, Operation),
    once(lesson_operation_with_registered_equation(Code, Operation, Equation)).

% The attachment keeps the chart aligned with the lesson's encoded strategy;
% the compiled task instance supplies the actual numbers and operation.
lesson_operation_with_registered_equation(Code, Operation, Equation) :-
    lesson_monitoring:specific_attachment_operation(Code, Operation),
    registered_task_equation(Code, Operation, Equation).

registered_task_equation(Code, addition, equation(A, '+', B, R)) :-
    compiled_task_instances:compiled_lesson_task_instance(Code, productive-add(A, B), _),
    R is A + B.
registered_task_equation(Code, subtraction, equation(A, '-', B, R)) :-
    compiled_task_instances:compiled_lesson_task_instance(Code, productive-subtract(A, B), _),
    R is A - B.
registered_task_equation(Code, multiplication, equation(A, '*', B, R)) :-
    compiled_task_instances:compiled_lesson_task_instance(Code, productive-multiply(A, B), _),
    R is A * B.

% =========================================================================
% 2. The likely notation deformations for a lesson's representative equation.
% =========================================================================
%
% lesson_likely_notation_deformation(Code, Host, equation(A,Op,B,R),
%   notation_error(Type)). The notation deformations to watch for on this
% lesson's representative inscription. A deformation is surfaced ONLY when the
% grammar admits it for the chosen equation (gated_as_notation_misconception/3
% succeeds). The notation error types:
%   mirror_written_numeral      -- a reversal-prone digit flips (needs 3,5,7,9 in
%                                  the operands/result)
%   operational_equals_chain    -- the equals sign is read as "makes" (any sum)
%   digit_transposition         -- the answer digits are swapped (needs a
%                                  multi-digit answer)
%   place_value_writing_error   -- the result digits are inscribed with reversed
%                                  place value (needs a multi-digit answer)
%   carry_mark                  -- a units carry is dropped (needs an addition
%                                  whose units sum carries into the next place)
% Host is always notation for this chart; it is carried so the cell shape and
% the gate signature line up with the fraction chart's (Code, Host, ...) shape.

lesson_likely_notation_deformation(Code, notation, Equation, notation_error(Type)) :-
    lesson_representative_equation(Code, Equation),
    notation_error_type(Type),
    gated_as_notation_misconception(Equation, notation_error(Type), _Evidence).

% notation_error_type(Type): the notation deformation families. The gate
% decides which apply to a given equation; this just enumerates the candidates.
notation_error_type(operational_equals_chain).
notation_error_type(mirror_written_numeral).
notation_error_type(digit_transposition).
notation_error_type(place_value_writing_error).
notation_error_type(carry_mark).

% =========================================================================
% The misconception gate.
% =========================================================================
%
% gated_as_notation_misconception(equation(A,Op,B,R), notation_error(Type),
%   Evidence). A notation deformation is admitted to a chart ONLY if it routes
% through the grammar's labeled-misconception lane
% (deformation_spec_evidence(notation, Spec, _, Ev) with mode: misconception).
% This is the same discipline the notation compiler enforces; we consult the
% grammar, we do not edit it. There is no path to a flipped glyph or a chain mark
% that does not pass this gate.
%
% Each error type maps the representative equation to the grammar Spec the gate
% indexes on:
%   mirror_written_numeral   -> mirror_written(Digit, A, Op, B, R), Digit the
%                               first reversal-prone digit in the operands/result
%   operational_equals_chain -> operational_equals_chain(A, Op, B, R)
%   digit_transposition      -> digit_transposition(A, Op, B, R)

gated_as_notation_misconception(equation(A, Op, B, R),
                                notation_error(mirror_written_numeral),
                                Evidence) :-
    reversal_prone_digit_in_equation([A, B, R], Digit),
    deformation_spec_evidence(notation,
                              mirror_written(Digit, A, Op, B, R),
                              _Task, Evidence),
    get_dict(mode, Evidence, misconception).
gated_as_notation_misconception(equation(A, Op, B, R),
                                notation_error(operational_equals_chain),
                                Evidence) :-
    deformation_spec_evidence(notation,
                              operational_equals_chain(A, Op, B, R),
                              _Task, Evidence),
    get_dict(mode, Evidence, misconception).
gated_as_notation_misconception(equation(A, Op, B, R),
                                notation_error(digit_transposition),
                                Evidence) :-
    deformation_spec_evidence(notation,
                              digit_transposition(A, Op, B, R),
                              _Task, Evidence),
    get_dict(mode, Evidence, misconception).
gated_as_notation_misconception(equation(A, Op, B, R),
                                notation_error(place_value_writing_error),
                                Evidence) :-
    deformation_spec_evidence(notation,
                              place_value_writing_error(A, Op, B, R),
                              _Task, Evidence),
    get_dict(mode, Evidence, misconception).
gated_as_notation_misconception(equation(A, Op, B, R),
                                notation_error(carry_mark),
                                Evidence) :-
    deformation_spec_evidence(notation,
                              carry_mark(A, Op, B, R),
                              _Task, Evidence),
    get_dict(mode, Evidence, misconception).

% reversal_prone_digit_in_equation(+Numbers, -Digit): the first reversal-prone
% digit (3, 5, 7, 9) that appears in the operand/result list, deterministically.
% Mirrors parametric_notation_deformation's own operand scan so the gate picks
% the same digit the compiler would flip.
reversal_prone_digit_in_equation(Numbers, Digit) :-
    member(N, Numbers),
    integer(N),
    number_codes(N, Codes),
    member(C, Codes),
    char_code(Ch, C),
    atom_number(Ch, D),
    reversal_prone_digit(D),
    Digit = D,
    !.

% =========================================================================
% 3a. The productive scene for a lesson's representative equation.
% =========================================================================
%
% productive_notation_cell_scene(Code, equation(A,Op,B,R), Dict): the CORRECT
% inscription -- every glyph straight, no flips, empty marks. Delegates to the
% parametric productive generator, which delegates to the notation compiler.

productive_notation_cell_scene(Code, equation(A, Op, B, R), Dict) :-
    lesson_representative_equation(Code, equation(A, Op, B, R)),
    productive_notation_scene(write_equation(A, Op, B, R), Dict).

% =========================================================================
% 3b. The deformation scene for a lesson's representative equation + error.
% =========================================================================
%
% notation_deformation_cell_scene(Code, equation(A,Op,B,R), notation_error(Type),
%   Dict): the labeled-misconception inscription for this error on the
% representative equation. Asserts the gate before building any scene, then
% routes to the parametric deformed generator. A scene the grammar does not admit
% as a misconception is never produced.

notation_deformation_cell_scene(Code, equation(A, Op, B, R),
                                notation_error(Type), Dict) :-
    lesson_likely_notation_deformation(Code, notation, equation(A, Op, B, R),
                                        notation_error(Type)),
    gated_as_notation_misconception(equation(A, Op, B, R),
                                    notation_error(Type), _Evidence),
    deformed_spec_for_error(Type, equation(A, Op, B, R), Spec),
    deformed_notation_scene(Spec, notation_error(Type), Dict).

% deformed_spec_for_error(+Type, +equation(A,Op,B,R), -Spec): the caller spec the
% parametric deformed generator expects for each error type. mirror_written_numeral
% hands a write_equation(...) spec, from which the generator chooses the
% reversal-prone digit; the other two hand their own functor.
deformed_spec_for_error(mirror_written_numeral, equation(A, Op, B, R),
                        write_equation(A, Op, B, R)).
deformed_spec_for_error(operational_equals_chain, equation(A, Op, B, R),
                        operational_equals_chain(A, Op, B, R)).
deformed_spec_for_error(digit_transposition, equation(A, Op, B, R),
                        digit_transposition(A, Op, B, R)).
deformed_spec_for_error(place_value_writing_error, equation(A, Op, B, R),
                        place_value_writing_error(A, Op, B, R)).
deformed_spec_for_error(carry_mark, equation(A, Op, B, R),
                        carry_mark(A, Op, B, R)).

% =========================================================================
% 3c. The assembled notation monitoring chart.
% =========================================================================
%
% notation_monitoring_chart(Code, Doc): one dict per hosting lesson. The lesson
% metadata, the representative-equation host note, and one cell per host (the
% single notation host) carrying the productive scene plus every gated
% deformation scene, each tagged with provenance.

notation_monitoring_chart(Code, Doc) :-
    notation_chart_lesson(Code, Title, Standards, Hosts),
    hosting_lesson(Code, Operation),
    atom_string(Operation, OperationStr),
    lesson_representative_equation(Code, Equation),
    equation_string(Equation, EquationStr),
    findall(CellDict,
            ( member(Host, Hosts),
              notation_chart_cell(Code, Host, Equation, CellDict) ),
            Cells),
    Doc = _{
        kind: lesson_notation_chart,
        lesson_code: Code,
        title: Title,
        standards: Standards,
        hosts: ["notation"],
        operation: OperationStr,
        representative_equation: EquationStr,
        host_note: HostNote,
        cells: Cells
    },
    notation_host_note(Code, Operation, HostNote).
notation_monitoring_chart(Code, Doc) :-
    lesson_monitoring:im_lesson(Code, _, _, _, _, _),
    \+ notation_chart_lesson(Code, _, _, _),
    lesson_title(Code, Title),
    lesson_standard_codes(Code, Standards),
    Doc = _{
        kind: no_lesson_notation_chart,
        lesson_code: Code,
        title: Title,
        standards: Standards,
        message: "No lesson-specific notation material is registered for this lesson."
    }.

% Preserve the established K/G1 addition chart payload apart from the new
% operation field. Other charts state the generalized hosting rule plainly.
notation_host_note(Code, addition,
                   "The IM K/G1 corpus has no number-writing lessons; this notation chart uses a registered addition task from the lesson. The chart renders that task rather than counting corpus instances of a deformation.") :-
    ( sub_atom(Code, 0, _, _, 'IM-GK')
    ; sub_atom(Code, 0, _, _, 'IM-G1')
    ),
    !.
notation_host_note(_Code, Operation, HostNote) :-
    format(string(HostNote),
           "This lesson hosts a notation chart through its ~w operation. Its equation comes from a registered lesson task; each deformation is admitted by cited evidence and is not counted as an instance in this lesson.",
           [Operation]).

% notation_chart_cell(Code, Host, equation(A,Op,B,R), CellDict): the productive
% scene and the gated deformation scenes for the lesson's representative
% equation. CellDict carries equation/operands fields -- NOT
% fraction/numerator/denominator -- so it is structurally distinct from the
% fraction chart's cell.
notation_chart_cell(Code, Host, equation(A, Op, B, R), CellDict) :-
    Equation = equation(A, Op, B, R),
    productive_notation_cell_scene(Code, Equation, Productive),
    findall(_{ deformation: TypeStr,
               family: "notation_error",
               provenance: ProvStr,
               host_note: "Rendered over a representative equation from the lesson's operation, not a corpus instance of this deformation in this lesson.",
               scene: DefScene },
            ( lesson_likely_notation_deformation(Code, Host, Equation,
                                                  notation_error(Type)),
              notation_deformation_cell_scene(Code, Equation,
                                              notation_error(Type), DefScene),
              notation_error_label(notation_error(Type), TypeStr),
              deformation_provenance(notation_error(Type), ProvStr) ),
            Deformations),
    equation_string(Equation, EquationStr),
    atom_string(Op, OpStr),
    atom_string(Host, HostStr),
    CellDict = _{
        host: HostStr,
        equation: EquationStr,
        operands: _{ a: A, op: OpStr, b: B, r: R },
        productive: Productive,
        deformations: Deformations
    }.

% deformation_provenance(+notation_error(Type), -ProvStr): the provenance string
% (corpus_attested | literature_only) read off the grammar's Evidence dict via
% the parametric layer's notation_deformation_evidence/2. The honesty boundary
% lives in the grammar; this only stringifies it.
deformation_provenance(notation_error(Type), ProvStr) :-
    notation_deformation_evidence(notation_error(Type), Prov),
    atom_string(Prov, ProvStr).

notation_error_label(notation_error(Type), Str) :-
    atom_string(Type, Str).

% =========================================================================
% Serialisation.
% =========================================================================

notation_monitoring_chart_to_file(Doc, Path) :-
    setup_call_cleanup(
        open(Path, write, Stream, [encoding(utf8)]),
        json_write_dict(Stream, Doc, [width(80)]),
        close(Stream)).

% =========================================================================
% Helpers.
% =========================================================================

equation_string(equation(A, Op, B, R), Str) :-
    format(atom(Atom), "~w ~w ~w = ~w", [A, Op, B, R]),
    atom_string(Atom, Str).
