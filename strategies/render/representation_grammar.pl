/** <module> Logical grammar for mathematical representations
 *
 * This layer answers a question the scene compilers should not have to answer:
 * may this representational language productively denote this task? A renderer
 * can still draw a deformation, but only when the deformation is named as a
 * misconception and carries the violated grammar rule as evidence.
 */

:- module(representation_grammar,
          [ representation_language/1,
            representation_object/2,
            representation_grounding/2,
            blend_entails/2,
            blend_breaks/3,
            valid_quantity_for_representation/2,
            valid_task_for_representation/2,
            representation_refusal/3,
            scene_denotes/2,
            render_spec_denotes/3,
            render_spec_preserves_task/3,
            deformation_spec_evidence/4,
            grammar_violation/3,
            productive_visual/3,
            misconception_visual/5,
            calculator_visual/4,
            calculator_refusal/3,
            visual_candidate/5,
            drawable_visual_candidate/5,
            visual_candidate_evidence/6,
            visual_refusal/6,
            representation_appropriate_for_lesson/4,
            representation_render_status/2,
            preferred_representation/3,
            standard_supports_representation/4,
            standard_warns_against_representation/4,
            methods_text_supports_representation/4,
            methods_text_warns_against_representation/4,
            write_equation_task/5,
            written_equation_correct/4,
            reversal_prone_digit/1,
            digit_appears_in/2
          ]).

% The spatial-family languages (coordinate_plane and its siblings, tallied in
% docs/research/2026-07-08-hermes-spatial-representation-gap-tally.md) register
% themselves in self-contained sections at the end of this file rather than
% threading a clause into each predicate group above. Declaring the registration
% predicates discontiguous keeps that layout legal without changing any clause's
% meaning or resolution order.
:- discontiguous
       representation_language/1,
       representation_object/2,
       representation_grounding/2,
       blend_entails/2,
       valid_quantity_for_representation/2,
       render_spec_denotes/3,
       representation_refusal/3,
       deformation_spec_evidence/4,
       representation_render_status/2,
       standard_supports_representation/4,
       methods_text_supports_representation/4,
       methods_supports_representation_for_grade/4,
       preferred_representation/3.

% --- Representation vocabularies -------------------------------------------

representation_language(set_grouping).
representation_language(base_ten_blocks).
representation_language(number_line).
representation_language(place_value_chart).
representation_language(fraction_bars).
representation_language(area_model).
representation_language(balance_scale).
% Notation is a real productive language: children correctly write 2+3=5. Its
% atom is an inscribed glyph, not a quantity model. Only its deformations live
% in the misconception lane (unlike hybridization, which is render-status-only).
representation_language(notation).

representation_object(set_grouping, counter).
representation_object(set_grouping, five_frame).
representation_object(set_grouping, ten_frame).
representation_object(set_grouping, pair).
representation_object(base_ten_blocks, unit_cube).
representation_object(base_ten_blocks, ten_rod).
representation_object(base_ten_blocks, hundred_flat).
representation_object(base_ten_blocks, thousand_cube).
representation_object(number_line, axis).
representation_object(number_line, jump).
representation_object(number_line, segment).
representation_object(number_line, scale_break).
representation_object(number_line, benchmark).
representation_object(place_value_chart, digit_column).
representation_object(place_value_chart, named_place).
representation_object(place_value_chart, regrouping_arrow).
representation_object(fraction_bars, whole_bar).
representation_object(fraction_bars, equal_part).
representation_object(fraction_bars, iterated_part).
representation_object(fraction_bars, common_unit).
representation_object(area_model, array_cell).
representation_object(area_model, unit_square).
representation_object(area_model, partition).
representation_object(area_model, overlap_rectangle).
representation_object(balance_scale, pan).
representation_object(balance_scale, weight).
representation_object(balance_scale, preserving_move).
representation_object(notation, digit_glyph).
representation_object(notation, operator_sign).
representation_object(notation, equals_sign).
representation_object(notation, glyph_flip).
representation_object(notation, strikethrough).
representation_object(notation, glyph_overwrite).
representation_object(notation, carry_mark).
representation_object(notation, running_chain_link).

% Lakoff/Nunez-style grounding blends. These are intentionally stated as
% logical affordances, not as decoration for a chart footer.
representation_grounding(set_grouping,
    blend(object_collection, object_construction)).
representation_grounding(base_ten_blocks,
    blend(object_collection, place_value_grouping)).
representation_grounding(number_line,
    blend(measuring_stick, source_path_goal)).
representation_grounding(place_value_chart,
    blend(writing_system, place_value_grouping)).
representation_grounding(fraction_bars,
    blend(measuring_stick, part_whole)).
representation_grounding(area_model,
    blend(container, measuring_stick)).
representation_grounding(balance_scale,
    blend(balance_equilibrium, equation_as_balance)).
% Notation grounds in writing_system (as place_value_chart does) blended with
% the inscription of a symbol string, so it denotes the symbol string a child
% wrote, not the quantity that string was meant to mean.
representation_grounding(notation,
    blend(writing_system, symbol_string_inscription)).

blend_entails(blend(object_collection, object_construction),
              discrete_countable_objects).
blend_entails(blend(object_collection, place_value_grouping),
              physical_grouping_units).
blend_entails(blend(measuring_stick, source_path_goal),
              ordered_magnitude_on_path).
blend_entails(blend(writing_system, place_value_grouping),
              positional_digit_places).
blend_entails(blend(measuring_stick, part_whole),
              common_partitioned_whole).
blend_entails(blend(container, measuring_stick),
              multiplicative_measure_region).
blend_entails(blend(balance_equilibrium, equation_as_balance),
              preserving_equality).
blend_entails(blend(writing_system, symbol_string_inscription),
              linear_symbol_sequence).

% --- Productive domain checks ----------------------------------------------

valid_quantity_for_representation(set_grouping, whole_number(N)) :-
    nonnegative_integer(N),
    N =< 20,
    !.

valid_quantity_for_representation(set_grouping, multiplication(Groups, Size)) :-
    nonnegative_integer(Groups),
    nonnegative_integer(Size),
    Total is Groups * Size,
    Total =< 20,
    !.

valid_quantity_for_representation(base_ten_blocks, whole_number(N)) :-
    nonnegative_integer(N),
    N =< 9999,
    !.

valid_quantity_for_representation(number_line, whole_number(N)) :-
    nonnegative_integer(N),
    !.

valid_quantity_for_representation(place_value_chart, whole_number(N)) :-
    nonnegative_integer(N),
    !.

valid_quantity_for_representation(notation, whole_number(N)) :-
    nonnegative_integer(N),
    !.

valid_quantity_for_representation(fraction_bars, fraction(N, D)) :-
    nonnegative_integer(N),
    positive_integer(D),
    !.

valid_quantity_for_representation(area_model, array(Rows, Cols)) :-
    positive_integer(Rows),
    positive_integer(Cols),
    Rows =< 12,
    Cols =< 12,
    !.

valid_quantity_for_representation(area_model, multiplication(A, B)) :-
    valid_quantity_for_representation(area_model, array(A, B)),
    !.

valid_quantity_for_representation(area_model, fraction_product(NA, DA, NB, DB)) :-
    nonnegative_integer(NA),
    positive_integer(DA),
    nonnegative_integer(NB),
    positive_integer(DB),
    !.

valid_quantity_for_representation(balance_scale, equation(linear(A, B, C))) :-
    nonnegative_integer(A),
    nonnegative_integer(B),
    nonnegative_integer(C),
    A > 0,
    !.

valid_task_for_representation(Representation, Task) :-
    valid_quantity_for_representation(Representation, Task),
    !.

valid_task_for_representation(set_grouping, kindergarten_counting_collection(N)) :-
    valid_quantity_for_representation(set_grouping, whole_number(N)),
    !.

valid_task_for_representation(set_grouping, subitizing(N)) :-
    positive_integer(N),
    N =< 10,
    !.

valid_task_for_representation(set_grouping, comparison(whole_number(A), whole_number(B))) :-
    valid_quantity_for_representation(set_grouping, whole_number(A)),
    valid_quantity_for_representation(set_grouping, whole_number(B)),
    !.

valid_task_for_representation(set_grouping, multiplication(Groups, Size)) :-
    valid_quantity_for_representation(set_grouping, multiplication(Groups, Size)),
    !.

valid_task_for_representation(Representation, whole_number_addition(A, B)) :-
    valid_quantity_for_representation(Representation, whole_number(A)),
    valid_quantity_for_representation(Representation, whole_number(B)),
    Sum is A + B,
    valid_quantity_for_representation(Representation, whole_number(Sum)).

valid_task_for_representation(Representation, whole_number_subtraction(A, B)) :-
    A >= B,
    valid_quantity_for_representation(Representation, whole_number(A)),
    valid_quantity_for_representation(Representation, whole_number(B)),
    Difference is A - B,
    valid_quantity_for_representation(Representation, whole_number(Difference)).

valid_task_for_representation(
        fraction_bars,
        fraction_addition(fraction(NA, DA), fraction(NB, DB))) :-
    valid_quantity_for_representation(fraction_bars, fraction(NA, DA)),
    valid_quantity_for_representation(fraction_bars, fraction(NB, DB)).

valid_task_for_representation(
        fraction_bars,
        fraction_subtraction(fraction(NA, DA), fraction(NB, DB))) :-
    valid_quantity_for_representation(fraction_bars, fraction(NA, DA)),
    valid_quantity_for_representation(fraction_bars, fraction(NB, DB)),
    NA * DB >= NB * DA.

% Notation denotes essentially any task with a written form. The generic
% whole_number_addition/subtraction clauses above already cover the K/G1
% arithmetic inscriptions; this clause admits a bare written equation as a task.
valid_task_for_representation(notation, equation(A, Op, B, R)) :-
    member(Op, [+, -, *, =]),
    nonnegative_integer(A),
    nonnegative_integer(B),
    nonnegative_integer(R).

% --- Refusal and blend-break policy ----------------------------------------

representation_refusal(set_grouping, whole_number(N),
        reason(exceeds_set_grouping_scope(N))) :-
    nonnegative_integer(N),
    N > 20,
    !.

representation_refusal(base_ten_blocks, whole_number(N),
        reason(no_physical_block_for_required_place_value(N))) :-
    nonnegative_integer(N),
    N > 9999,
    !.

representation_refusal(number_line, kindergarten_counting_collection(_N),
        reason(path_magnitude_model_not_default_for_early_counting_collections)) :-
    !.

representation_refusal(number_line, subitizing(_N),
        reason(path_magnitude_model_not_default_for_early_subitizing)) :-
    !.

representation_refusal(Representation, whole_number_addition(A, _B), Reason) :-
    representation_refusal(Representation, whole_number(A), Reason).
representation_refusal(Representation, whole_number_addition(_A, B), Reason) :-
    representation_refusal(Representation, whole_number(B), Reason).
representation_refusal(Representation, whole_number_addition(A, B), Reason) :-
    Sum is A + B,
    representation_refusal(Representation, whole_number(Sum), Reason).

representation_refusal(Representation, whole_number_subtraction(A, _B), Reason) :-
    representation_refusal(Representation, whole_number(A), Reason).
representation_refusal(Representation, whole_number_subtraction(_A, B), Reason) :-
    representation_refusal(Representation, whole_number(B), Reason).
representation_refusal(Representation, whole_number_subtraction(A, B),
        reason(negative_result_outside_whole_number_representation(A, B))) :-
    representation_language(Representation),
    A < B.

blend_breaks(Representation, Task, Reason) :-
    representation_refusal(Representation, Task, Reason).

% --- Denotation and mode separation ----------------------------------------

scene_denotes(scene(_Representation, Task), Task).
scene_denotes(scene(_Representation, Task, _Metadata), Task).
scene_denotes(render_spec(Representation, Spec), Task) :-
    render_spec_denotes(Representation, Spec, Task).

render_spec_denotes(set_grouping, ten_frame(N), whole_number(N)).
render_spec_denotes(set_grouping, make_ten(A, B), whole_number_addition(A, B)).
render_spec_denotes(set_grouping, subitize(_Pattern, N), subitizing(N)).
render_spec_denotes(set_grouping, parity(N), whole_number(N)).
render_spec_denotes(set_grouping, compare(A, B), comparison(whole_number(A), whole_number(B))).
render_spec_denotes(set_grouping, equal_groups(Groups, Size), multiplication(Groups, Size)).
render_spec_denotes(set_grouping, fair_share(Total, Groups), fair_sharing(Total, Groups)).

render_spec_denotes(base_ten_blocks, represent(N, _Base), whole_number(N)).
render_spec_denotes(base_ten_blocks, place_value_teen(N), whole_number(N)).
render_spec_denotes(base_ten_blocks, base_decomposition(N, _Base), whole_number(N)).
render_spec_denotes(base_ten_blocks, add_with_carry(A, B, _Base), whole_number_addition(A, B)).
render_spec_denotes(base_ten_blocks, subtract_with_borrow(A, B, _Base), whole_number_subtraction(A, B)).

render_spec_denotes(number_line, jumps(_Strategy, A, B), whole_number_addition(A, B)).
render_spec_denotes(number_line, rounding_length(addition, A, B), whole_number_addition(A, B)).
render_spec_denotes(number_line, magnitude_addition(A, B), whole_number_addition(A, B)).

render_spec_denotes(place_value_chart, add_with_carry(A, B, _Base), whole_number_addition(A, B)).

render_spec_denotes(fraction_bars, fraction_render(_Kind, N, D), fraction(N, D)).
render_spec_denotes(
        fraction_bars,
        fraction_arith(add, NA, DA, NB, DB),
        fraction_addition(fraction(NA, DA), fraction(NB, DB))).
render_spec_denotes(
        fraction_bars,
        fraction_arith(sub, NA, DA, NB, DB),
        fraction_subtraction(fraction(NA, DA), fraction(NB, DB))).

render_spec_denotes(area_model, array_multiplication(A, B), multiplication(A, B)).
render_spec_denotes(area_model, commutativity_by_transpose(A, B), multiplication(A, B)).
render_spec_denotes(area_model, partial_products(A, B), multiplication(A, B)).
render_spec_denotes(area_model, area_model_fraction(NA, DA, NB, DB), fraction_product(NA, DA, NB, DB)).

render_spec_denotes(balance_scale, solve_linear(A, B, C), equation(linear(A, B, C))).

% Notation's productive lane: a written equation denotes the arithmetic task its
% operator names. write_equation_task/5 maps + / - / = to the underlying task.
render_spec_denotes(notation, write_equation(A, Op, B, R), Task) :-
    write_equation_task(Op, A, B, R, Task),
    written_equation_correct(Op, A, B, R).

render_spec_preserves_task(Representation, Spec, Task) :-
    render_spec_denotes(Representation, Spec, Task),
    productive_visual(Task, Representation, scene(Representation, Task)),
    \+ deformation_spec_evidence(Representation, Spec, Task, _Evidence).

deformation_spec_evidence(
        base_ten_blocks,
        add_with_dropped_carry(A, B, Base),
        whole_number_addition(A, B),
        Evidence) :-
    dropped_carry_answer(A, B, Base, WrongAnswer),
    CorrectAnswer is A + B,
    WrongAnswer =\= CorrectAnswer,
    Evidence = _{
        mode: misconception,
        misconception: add_with_dropped_carry,
        representation: base_ten_blocks,
        correct_task: whole_number_addition(A, B),
        correct_answer: CorrectAnswer,
        wrong_answer: WrongAnswer,
        violation: reason(carry_not_preserved)
    }.
deformation_spec_evidence(
        base_ten_blocks,
        subtract_without_reducing_borrow(A, B, Base),
        whole_number_subtraction(A, B),
        Evidence) :-
    borrow_without_reducing_answer(A, B, Base, WrongAnswer),
    CorrectAnswer is A - B,
    WrongAnswer =\= CorrectAnswer,
    Evidence = _{
        mode: misconception,
        misconception: borrow_without_reducing_bases,
        representation: base_ten_blocks,
        correct_task: whole_number_subtraction(A, B),
        correct_answer: CorrectAnswer,
        wrong_answer: WrongAnswer,
        violation: reason(next_place_not_reduced_after_borrow)
    }.
deformation_spec_evidence(
        set_grouping,
        make_ten_drop_leftover(A, B),
        whole_number_addition(A, B),
        Evidence) :-
    CorrectAnswer is A + B,
    WrongAnswer = 10,
    CorrectAnswer =\= WrongAnswer,
    Evidence = _{
        mode: misconception,
        misconception: make_ten_drop_leftover,
        representation: set_grouping,
        correct_task: whole_number_addition(A, B),
        correct_answer: CorrectAnswer,
        wrong_answer: WrongAnswer,
        violation: reason(leftover_not_preserved)
    }.
deformation_spec_evidence(
        area_model,
        area_compare(NA, DA, NB, DB),
        fraction_product(NA, DA, NB, DB),
        Evidence) :-
    task_answer(fraction_product(NA, DA, NB, DB), Answer),
    Evidence = _{
        mode: misconception,
        misconception: cross_multiplication_rule_without_ground,
        representation: area_model,
        correct_task: fraction_product(NA, DA, NB, DB),
        correct_answer: Answer,
        unsupported_answer: Answer,
        violation: reason(omitted_area_overlap_grounding)
    }.
deformation_spec_evidence(
        fraction_bars,
        fraction_arith_componentwise(add, NA, DA, NB, DB),
        fraction_addition(fraction(NA, DA), fraction(NB, DB)),
        Evidence) :-
    WrongN is NA + NB,
    WrongD is DA + DB,
    CorrectN is NA * DB + NB * DA,
    CorrectD is DA * DB,
    WrongN * CorrectD =\= CorrectN * WrongD,
    Evidence = _{
        mode: misconception,
        misconception: add_numerators_and_denominators,
        representation: fraction_bars,
        correct_task: fraction_addition(fraction(NA, DA), fraction(NB, DB)),
        correct_answer: fraction(CorrectN, CorrectD),
        wrong_answer: fraction(WrongN, WrongD),
        violation: reason(common_unit_not_preserved)
    }.
deformation_spec_evidence(
        balance_scale,
        balance_compare(A, B, C),
        equation(linear(A, B, C)),
        Evidence) :-
    B > 0,
    task_answer(equation(linear(A, B, C)), CorrectAnswer),
    reduce_fraction(C, A, UnsupportedN, UnsupportedD),
    Evidence = _{
        mode: misconception,
        misconception: operational_equals_subtract_from_one_side,
        representation: balance_scale,
        correct_task: equation(linear(A, B, C)),
        correct_answer: CorrectAnswer,
        unsupported_equation: equation(linear(A, 0, C)),
        unsupported_answer: fraction(UnsupportedN, UnsupportedD),
        violation: reason(balance_not_preserved)
    }.
deformation_spec_evidence(
        hybridization,
        circle_partition_on_rectangle,
        hybridization_case(circle_radial_partition, rectangle_area_model),
        Evidence) :-
    Evidence = _{
        mode: misconception,
        family: transplant_deformation,
        misconception: hybridized_model,
        representation: hybridization,
        correct_task: hybridization_case(circle_radial_partition, rectangle_area_model),
        foreign_primitive: circle_radial_partition,
        licensed_home: circle_region,
        illicit_host: rectangle_area_model,
        wrong_denotation: undetermined_fraction_region,
        violation: reason(object_language_binding_violation)
    }.
deformation_spec_evidence(
        hybridization,
        vertical_partition_on_circle,
        hybridization_case(rectangle_vertical_partition, circle_region),
        Evidence) :-
    Evidence = _{
        mode: misconception,
        family: transplant_deformation,
        misconception: hybridized_model,
        representation: hybridization,
        correct_task: hybridization_case(rectangle_vertical_partition, circle_region),
        foreign_primitive: rectangle_vertical_partition,
        licensed_home: rectangle_area_model,
        illicit_host: circle_region,
        wrong_denotation: undetermined_fraction_region,
        violation: reason(object_language_binding_violation)
    }.
deformation_spec_evidence(
        hybridization,
        radial_partition_on_set,
        hybridization_case(circle_radial_partition, fractional_set_model),
        Evidence) :-
    Evidence = _{
        mode: misconception,
        family: transplant_deformation,
        misconception: hybridized_model,
        representation: hybridization,
        correct_task: hybridization_case(circle_radial_partition, fractional_set_model),
        foreign_primitive: circle_radial_partition,
        licensed_home: circle_region,
        illicit_host: fractional_set_model,
        wrong_denotation: undetermined_fraction_region,
        violation: reason(object_language_binding_violation)
    }.
deformation_spec_evidence(
        hybridization,
        parallel_partition_on_triangle,
        hybridization_case(rectangle_parallel_partition, triangle_region),
        Evidence) :-
    Evidence = _{
        mode: misconception,
        family: transplant_deformation,
        misconception: hybridized_model,
        representation: hybridization,
        correct_task: hybridization_case(rectangle_parallel_partition, triangle_region),
        foreign_primitive: rectangle_parallel_partition,
        licensed_home: rectangle_area_model,
        illicit_host: triangle_region,
        wrong_denotation: undetermined_fraction_region,
        violation: reason(object_language_binding_violation)
    }.

% --- Notation deformations (the misconception lane) ------------------------
% A legible arithmetic equation with the wrong result remains an inscription,
% but it does not preserve the arithmetic task. Keep it drawable as a named
% deformation rather than admitting it through the productive lane.
deformation_spec_evidence(
        notation,
        write_equation(A, Op, B, WrittenResult),
        Task,
        Evidence) :-
    write_equation_task(Op, A, B, WrittenResult, Task),
    nonnegative_integer(WrittenResult),
    \+ written_equation_correct(Op, A, B, WrittenResult),
    expected_equation_result(Op, A, B, ExpectedResult),
    Evidence = _{
        mode: misconception,
        misconception: false_equation,
        representation: notation,
        correct_task: Task,
        expected_answer: ExpectedResult,
        written_answer: WrittenResult,
        violation: reason(equation_truth_not_preserved),
        provenance: generated_from_arithmetic_invariant
    }.

% A reversed numeral renders ONLY when named here. There is no productive
% render_spec_denotes clause for mirror_written/5, so the only path to a flipped
% glyph is through this clause carrying mode: misconception. The reversal-prone
% digit is chosen in Prolog, never in the drawer.
deformation_spec_evidence(
        notation,
        mirror_written(Digit, A, Op, B, R),
        Task,
        Evidence) :-
    write_equation_task(Op, A, B, R, Task),
    reversal_prone_digit(Digit),
    digit_appears_in([A, B, R], Digit),
    Evidence = _{
        mode: misconception,
        misconception: mirror_written_numeral,
        representation: notation,
        correct_task: Task,
        reversed_digit: Digit,
        violation: reason(glyph_orientation_reversed),
        provenance: literature_only
    }.
% Equals-as-makes: the child chains a running total, reading = as "makes". The
% inscription form (multi-= chain) is attested in the corpus; the K/G1 instance
% is not. Provenance flag carries that distinction into the data.
deformation_spec_evidence(
        notation,
        operational_equals_chain(A, Op, B, RunningTotal),
        Task,
        Evidence) :-
    write_equation_task(Op, A, B, _R, Task),
    Evidence = _{
        mode: misconception,
        misconception: operational_equals_chain,
        representation: notation,
        correct_task: Task,
        running_total: RunningTotal,
        violation: reason(equals_read_as_makes),
        provenance: corpus_attested
    }.
% The full running chain (the literal 2+3=5+4=9 inscription). Same equals-as-makes
% violation and same corpus-attested provenance as the single-step form: the
% multi-= chain IS the corpus-attested inscription form (513 multi-= docling
% transcriptions). Steps is a list of Acc-Op-B links; the first link's
% Acc Op B must be a valid write task, which gates the whole chain through the
% misconception lane exactly like the single-step clause.
deformation_spec_evidence(
        notation,
        operational_equals_chain_full([Acc - Op - B | More], Final),
        Task,
        Evidence) :-
    write_equation_task(Op, Acc, B, _R, Task),
    Evidence = _{
        mode: misconception,
        misconception: operational_equals_chain,
        representation: notation,
        correct_task: Task,
        chain_links: [Acc - Op - B | More],
        chain_final: Final,
        violation: reason(equals_read_as_makes),
        provenance: corpus_attested
    }.
% Digit transposition: the child records the answer with its digits swapped (12
% written as 21). The wrong answer is computed in Prolog from the operands by
% transposing the correct sum's digits, never supplied by the drawer. The
% violation is positional order, distinct from the equals-as-makes chain and
% from place_value_chart's column-alignment failure. Literature-only: no
% instance in this corpus.
deformation_spec_evidence(
        notation,
        digit_transposition(A, Op, B, R),
        Task,
        Evidence) :-
    write_equation_task(Op, A, B, R, Task),
    transposed_answer(R, WrongAnswer),
    WrongAnswer =\= R,
    Evidence = _{
        mode: misconception,
        misconception: digit_transposition,
        representation: notation,
        correct_task: Task,
        correct_answer: R,
        wrong_answer: WrongAnswer,
        violation: reason(positional_order_not_preserved),
        provenance: literature_only
    }.
% Glyph overwrite (self-correction). The child inscribes one value in the result
% slot, strikes it, and rewrites another over it. This is CHARTED as a
% misconception ONLY when the rewritten (corrected) value is STILL wrong: a clean
% self-correction TO the right answer is a productive inscription and must never
% enter the misconception lane (the one notation error type that needs
% a non-trivial correctness condition). The struck under-value and the over-value
% are Prolog facts; the gate is Corrected =\= R. Struck =\= Corrected guards that
% an overwrite actually changed the inscription. Literature-only: no instance in
% this corpus.
deformation_spec_evidence(
        notation,
        glyph_overwrite(A, Op, B, R, Struck, Corrected),
        Task,
        Evidence) :-
    write_equation_task(Op, A, B, R, Task),
    nonnegative_integer(Struck),
    nonnegative_integer(Corrected),
    Struck =\= Corrected,        % an overwrite actually changed the inscription
    Corrected =\= R,             % THE GATE: the self-correction is still wrong
    Evidence = _{
        mode: misconception,
        misconception: glyph_overwrite,
        representation: notation,
        correct_task: Task,
        correct_answer: R,
        struck_value: Struck,
        corrected_value: Corrected,
        violation: reason(self_correction_still_wrong),
        provenance: literature_only
    }.
% Place-value writing error: the child inscribes the result with place value
% growing in the wrong direction — thirteen written 31, the decimal sibling
% 0.354 read as 3 tens / 5 hundreds. The mis-ordered answer is the FULL decimal
% reversal, computed in Prolog (mirror_place_value_answer/2), never supplied by
% the drawer. It shares the blend(writing_system, place_value_grouping) ->
% positional_digit_places entailment with place_value_chart, but the violation
% reason is the DIRECTION of place, distinct from place_value_chart's column
% drift and from digit_transposition's last-two-place swap. Corpus-anchored via
% the decimal sibling mirror_place_value/2 + arith_misconception(db_row(38397),
% decimal, mirror_image_place_value, ...) (misconceptions_decimal_batch_2.pl:318,
% 329; the source comment gives no grade band). The whole-number K/G1 instance is
% not itself in this corpus; the provenance flag carries the attested decimal
% sibling, the same honesty move operational_equals_chain makes.
deformation_spec_evidence(
        notation,
        place_value_writing_error(A, Op, B, R),
        Task,
        Evidence) :-
    write_equation_task(Op, A, B, R, Task),
    mirror_place_value_answer(R, WrongAnswer),
    WrongAnswer =\= R,
    Evidence = _{
        mode: misconception,
        misconception: place_value_writing_error,
        representation: notation,
        correct_task: Task,
        correct_answer: R,
        wrong_answer: WrongAnswer,
        violation: reason(positional_digit_places_reversed),
        provenance: corpus_attested
    }.
% Carry mark (dropped). A multi-digit addition whose units sum carries into the
% next place. The recorded answer is the dropped-carry answer dropped_carry_answer/4
% already computes for the base_ten_blocks lane; here the same arithmetic governs
% the glyph-level inscription, and carry_digit carries the units-place carry the
% notation compiler renders as the dropped superscript. The violation family
% reason(carry_not_preserved) is corpus-grounded through the base_ten_blocks
% add_with_dropped_carry clause; the carry-as-handwritten-mark inscription has no
% notation figure in this corpus, so the K/G1 instance itself is not corpus-counted.
deformation_spec_evidence(
        notation,
        carry_mark(A, Op, B, R),
        Task,
        Evidence) :-
    Op == '+',
    write_equation_task(Op, A, B, R, Task),
    dropped_carry_answer(A, B, 10, WrongAnswer),
    WrongAnswer =\= R,
    UnitsCarry is ((A mod 10) + (B mod 10)) // 10,
    Evidence = _{
        mode: misconception,
        misconception: dropped_carry_mark,
        representation: notation,
        correct_task: Task,
        correct_answer: R,
        wrong_answer: WrongAnswer,
        carry_digit: UnitsCarry,
        violation: reason(carry_not_preserved),
        provenance: corpus_attested
    }.

% transposed_answer(+N, -Swapped): swap the last two decimal digits of N. A
% two-digit answer 12 becomes 21; the units and tens digits trade places. Only
% the bottom two places move, so a longer answer keeps its higher places.
transposed_answer(N, Swapped) :-
    nonnegative_integer(N),
    N >= 10,
    Units is N mod 10,
    Tens is (N // 10) mod 10,
    Rest is (N // 100) * 100,
    Swapped is Rest + Units * 10 + Tens.

% mirror_place_value_answer(+N, -Reversed): the digits of N inscribed with place
% value growing rightward — the FULL decimal-digit reversal (13 -> 31, 120 -> 21).
% The notation cousin of misconceptions_decimal_batch_2:mirror_place_value/2.
% Distinct from transposed_answer/2, which swaps only the bottom two places, so
% the two coincide on two-digit numbers but diverge once there are three digits.
mirror_place_value_answer(N, Reversed) :-
    nonnegative_integer(N),
    N >= 10,
    number_codes(N, Codes),
    reverse(Codes, RevCodes),
    number_codes(Reversed, RevCodes).

grammar_violation(Representation, Scene, Reason) :-
    scene_denotes(Scene, Task),
    representation_refusal(Representation, Task, Reason).

productive_visual(Task, Representation, Scene) :-
    valid_task_for_representation(Representation, Task),
    scene_denotes(Scene, Task),
    \+ grammar_violation(Representation, Scene, _Reason),
    !.

misconception_visual(CorrectTask, Misconception, Representation, Scene, Evidence) :-
    misconception_deformation(Misconception, CorrectTask, Representation, Scene),
    scene_denotes(Scene, WrongTask),
    WrongTask \= CorrectTask,
    valid_task_for_representation(Representation, WrongTask),
    representation_refusal(Representation, CorrectTask, Refusal),
    Evidence = _{
        mode: misconception,
        misconception: Misconception,
        representation: Representation,
        correct_task: CorrectTask,
        wrong_task: WrongTask,
        violation: Refusal
    },
    !.

misconception_deformation(
    truncates_inaccessible_high_places,
    whole_number(Correct),
    base_ten_blocks,
    scene(base_ten_blocks, whole_number(Wrong))
) :-
    nonnegative_integer(Correct),
    Correct > 9999,
    collapsed_base_ten_block_value(Correct, Wrong).

% Subtraction whose correct result is negative, drawn as the absolute
% difference. base_ten_blocks refuses whole_number_subtraction(A,B) when A<B
% (negative_result_outside_whole_number_representation): a below-zero quantity
% has no block layout. The child who meets that wall swaps the operands and
% builds the in-scope difference B-A instead. The deformed scene denotes the
% well-formed whole_number_subtraction(B,A), which base_ten_blocks can draw,
% while the correct task it stands in for is refused. Attested:
% db_row(37796) flip_subtraction_order (Got is abs(A-B); 4-5 -> 1) and
% db_row(37842) smaller_from_larger_per_column; the violated commitment is
% c_subtraction_order_difference_relation (literature_vocabulary.pl).
misconception_deformation(
    subtracts_smaller_from_larger,
    whole_number_subtraction(A, B),
    base_ten_blocks,
    scene(base_ten_blocks, whole_number_subtraction(B, A))
) :-
    nonnegative_integer(A),
    nonnegative_integer(B),
    A < B,
    valid_quantity_for_representation(base_ten_blocks, whole_number(B)).

% A counting collection past the set-grouping ceiling (N>20), drawn as the
% largest collection the layout can actually hold. set_grouping refuses
% whole_number(N>20) (exceeds_set_grouping_scope); a child counting beyond what
% they can keep organized loses track and reports only the collection they
% could complete. Capping at the twenty-object ceiling is a stylization of that
% loss-of-track, not a claim the child always stops at 20. The deformed scene
% denotes whole_number(20), which a ten_frame set-grouping layout can draw.
% Attested as loss-of-track past manageable scope: db_row(37881) (hidden-item
% counts lost -> wrong total) and db_row(40602) (random-path counting loses the
% unit squares).
misconception_deformation(
    caps_collection_at_set_grouping_ceiling,
    whole_number(N),
    set_grouping,
    scene(set_grouping, whole_number(20))
) :-
    nonnegative_integer(N),
    N > 20.

calculator_visual(Task, Representation, Scene, Answer) :-
    productive_visual(Task, Representation, Scene),
    task_answer(Task, Answer).

calculator_refusal(Task, Representation, Reason) :-
    representation_refusal(Representation, Task, Reason).

% --- Lesson-aware visual candidates -----------------------------------------

visual_candidate(LessonContext, Task, Strategy, Misconception, Representation) :-
    visual_candidate_evidence(
        LessonContext,
        Task,
        Strategy,
        Misconception,
        Representation,
        _Evidence
    ).

drawable_visual_candidate(LessonContext, Task, Strategy, Misconception, Representation) :-
    visual_candidate(LessonContext, Task, Strategy, Misconception, Representation),
    representation_render_status(Representation, renderable(_Op)).

visual_candidate_evidence(
        LessonContext,
        Task,
        Strategy,
        Misconception,
        Representation,
        Evidence) :-
    representation_language(Representation),
    valid_task_for_representation(Representation, Task),
    representation_appropriate_for_lesson(
        Representation,
        LessonContext,
        standard(Standard, Purpose),
        method(MethodSource, MethodSupport)
    ),
    \+ visual_refusal(LessonContext, Task, Strategy, Misconception, Representation, _Reason),
    representation_grounding(Representation, Grounding),
    representation_render_status(Representation, RenderStatus),
    Evidence = [
        standard(Standard, Purpose),
        method(MethodSource, MethodSupport),
        grounding(Grounding),
        render_status(RenderStatus),
        strategy(Strategy),
        misconception(Misconception)
    ].

representation_appropriate_for_lesson(
        Representation,
        lesson_context(Grade, Standards),
        standard(Standard, Purpose),
        method(MethodSource, MethodSupport)) :-
    member(Standard, Standards),
    standard_supports_representation(Standard, Representation, Grade, Purpose),
    methods_supports_representation_for_grade(
        MethodSource,
        Representation,
        Grade,
        MethodSupport
    ).

visual_refusal(_LessonContext, Task, _Strategy, _Misconception, Representation, Reason) :-
    representation_refusal(Representation, Task, Reason).
visual_refusal(lesson_context(Grade, Standards), _Task, _Strategy, _Misconception,
        Representation, reason(Reason)) :-
    member(Standard, Standards),
    standard_warns_against_representation(Standard, Representation, Grade, Reason).
visual_refusal(lesson_context(Grade, _Standards), Task, _Strategy, _Misconception,
        Representation, reason(Reason)) :-
    methods_warns_against_representation_for_grade(Representation, Grade, Task, Reason).

representation_render_status(set_grouping, renderable(set_grouping_render)).
representation_render_status(base_ten_blocks, renderable(base_ten_render)).
representation_render_status(number_line, renderable(number_line_render)).
representation_render_status(fraction_bars, renderable(fraction_render)).
representation_render_status(area_model, renderable(area_render)).
representation_render_status(balance_scale, renderable(balance_render)).
representation_render_status(place_value_chart, renderable(place_value_chart_render)).
representation_render_status(hybridization, renderable(hybridization_render)).
representation_render_status(notation, renderable(notation_render)).

preferred_representation(whole_number(N), set_grouping, reason(small_counting_collection)) :-
    nonnegative_integer(N),
    N =< 20.
preferred_representation(subitizing(N), set_grouping, reason(perceptual_pattern_recognition)) :-
    positive_integer(N),
    N =< 10.
preferred_representation(whole_number(N), base_ten_blocks, reason(physical_place_value_blocks_available)) :-
    nonnegative_integer(N),
    N > 20,
    N =< 9999.
preferred_representation(whole_number(N), number_line, reason(large_magnitude_requires_scalable_measure_model)) :-
    nonnegative_integer(N),
    N > 9999.
preferred_representation(whole_number_addition(A, B), number_line,
        reason(large_magnitude_requires_scalable_measure_model)) :-
    Sum is A + B,
    ( A > 9999 ; B > 9999 ; Sum > 9999 ).

% These predicates are the hooks where standards files and methods texts can
% join the grammar without choosing renderers by string matching in Python.
standard_supports_representation(k_ns_3, set_grouping, kindergarten, cardinality).
standard_supports_representation(k_ns_4, set_grouping, kindergarten, subitizing_and_counting).
standard_supports_representation(k_ns_7, base_ten_blocks, kindergarten, teen_ten_and_ones).
standard_supports_representation('1_ns_2', base_ten_blocks, grade_1, two_digit_place_value).
standard_supports_representation('1_ca_1', set_grouping, grade_1, make_ten).
standard_supports_representation('1_ca_3', base_ten_blocks, grade_1, add_by_place_value).
standard_supports_representation('2_ca_2', base_ten_blocks, grade_2, three_digit_addition).
standard_supports_representation('3_ns_2', fraction_bars, grade_3, unit_fractions).
standard_supports_representation('3_ns_5', fraction_bars, grade_3, fraction_comparison).
standard_supports_representation('3_g_a_2', area_model, grade_3, equal_area_partitioning).
standard_supports_representation('4_nf_3', fraction_bars, grade_4, fraction_addition_and_subtraction).
standard_supports_representation('3_ca_3_4', area_model, grade_3, multiplication_and_division).
standard_supports_representation('4_nbt_b_4', number_line, grade_4, large_multi_digit_addition).
standard_supports_representation('4_nbt_b_4', place_value_chart, grade_4, multi_digit_place_value_algorithm).
standard_supports_representation('6_ee_b_5', balance_scale, grade_6, equation_balance).

standard_warns_against_representation('4_nbt_b_4', base_ten_blocks, grade_4,
    large_multi_digit_operands_exceed_physical_block_vocabulary).

methods_text_supports_representation(van_de_walle, set_grouping, early_counting,
    concrete_collections_before_abstract_measure_paths).
methods_text_supports_representation(van_de_walle, base_ten_blocks, place_value,
    tradeable_units_through_thousands).
methods_text_supports_representation(van_de_walle, number_line, whole_number_operations,
    scalable_magnitude_and_jump_reasoning).
methods_text_supports_representation(van_de_walle, fraction_bars, fractions,
    equal_part_wholes_and_unit_fraction_iteration).
methods_text_supports_representation(van_de_walle, area_model, multiplication,
    arrays_and_area_as_multiplicative_structure).
methods_text_supports_representation(lakoff_nunez, number_line, arithmetic,
    arithmetic_as_motion_along_a_path).
methods_text_supports_representation(lakoff_nunez, balance_scale, algebra,
    equation_as_balance).

methods_text_warns_against_representation(van_de_walle, number_line, kindergarten_counting,
    path_magnitude_model_not_default_for_early_counting_collections).
methods_text_warns_against_representation(lakoff_nunez, base_ten_blocks, large_whole_numbers,
    object_collection_blend_loses_physical_place_value_objects_above_thousands).

methods_supports_representation_for_grade(Source, set_grouping, kindergarten, Support) :-
    methods_text_supports_representation(Source, set_grouping, early_counting, Support).
methods_supports_representation_for_grade(Source, set_grouping, grade_1, Support) :-
    methods_text_supports_representation(Source, set_grouping, early_counting, Support).
methods_supports_representation_for_grade(Source, base_ten_blocks, Grade, Support) :-
    memberchk(Grade, [kindergarten, grade_1, grade_2]),
    methods_text_supports_representation(Source, base_ten_blocks, place_value, Support).
methods_supports_representation_for_grade(Source, number_line, Grade, Support) :-
    memberchk(Grade, [grade_2, grade_3, grade_4, grade_5]),
    methods_text_supports_representation(Source, number_line, whole_number_operations, Support).
methods_supports_representation_for_grade(Source, fraction_bars, Grade, Support) :-
    memberchk(Grade, [grade_3, grade_4, grade_5]),
    methods_text_supports_representation(Source, fraction_bars, fractions, Support).
methods_supports_representation_for_grade(Source, area_model, Grade, Support) :-
    memberchk(Grade, [grade_3, grade_4, grade_5]),
    methods_text_supports_representation(Source, area_model, multiplication, Support).
methods_supports_representation_for_grade(Source, balance_scale, Grade, Support) :-
    memberchk(Grade, [grade_6, grade_7, grade_8]),
    methods_text_supports_representation(Source, balance_scale, algebra, Support).
methods_supports_representation_for_grade(Source, place_value_chart, Grade, Support) :-
    memberchk(Grade, [grade_4, grade_5]),
    methods_text_supports_representation(Source, number_line, whole_number_operations, Support).

methods_warns_against_representation_for_grade(number_line, kindergarten,
        kindergarten_counting_collection(_N), Reason) :-
    methods_text_warns_against_representation(
        _Source,
        number_line,
        kindergarten_counting,
        Reason
    ).
methods_warns_against_representation_for_grade(number_line, kindergarten,
        subitizing(_N), path_magnitude_model_not_default_for_early_subitizing).
methods_warns_against_representation_for_grade(base_ten_blocks, Grade, whole_number(N), Reason) :-
    memberchk(Grade, [grade_4, grade_5]),
    N > 9999,
    methods_text_warns_against_representation(
        _Source,
        base_ten_blocks,
        large_whole_numbers,
        Reason
    ).
methods_warns_against_representation_for_grade(base_ten_blocks, Grade,
        whole_number_addition(A, B), Reason) :-
    memberchk(Grade, [grade_4, grade_5]),
    Sum is A + B,
    ( A > 9999 ; B > 9999 ; Sum > 9999 ),
    methods_text_warns_against_representation(
        _Source,
        base_ten_blocks,
        large_whole_numbers,
        Reason
    ).

% --- Helpers ----------------------------------------------------------------

nonnegative_integer(N) :-
    integer(N),
    N >= 0.

positive_integer(N) :-
    integer(N),
    N > 0.

% --- Notation helpers -------------------------------------------------------
% Map a written-equation operator to the arithmetic task it inscribes.
write_equation_task(+, A, B, _R, whole_number_addition(A, B)) :-
    nonnegative_integer(A),
    nonnegative_integer(B).
write_equation_task(-, A, B, _R, whole_number_subtraction(A, B)) :-
    nonnegative_integer(A),
    nonnegative_integer(B),
    A >= B.
write_equation_task(*, A, B, _R, multiplication(A, B)) :-
    nonnegative_integer(A),
    nonnegative_integer(B).
write_equation_task(=, A, B, R, equation(A, =, B, R)) :-
    nonnegative_integer(A),
    nonnegative_integer(B),
    nonnegative_integer(R).

%!  written_equation_correct(+Op, +A, +B, +R) is semidet.
%
%   Productive notation must preserve the truth of the inscription, not merely
%   name an arithmetic task. Deformation clauses continue to call
%   write_equation_task/5 directly so an incorrect inscription can still be
%   represented with an explicit misconception label.
written_equation_correct(+, A, B, R) :- integer(R), R =:= A + B.
written_equation_correct(-, A, B, R) :- integer(R), R =:= A - B.
written_equation_correct(*, A, B, R) :- integer(R), R =:= A * B.
written_equation_correct(=, _A, _B, _R).

expected_equation_result(+, A, B, R) :- R is A + B.
expected_equation_result(-, A, B, R) :- R is A - B.
expected_equation_result(*, A, B, R) :- R is A * B.

% Digits whose mirror image is a documented K/G1 reversal target.
reversal_prone_digit(3).
reversal_prone_digit(5).
reversal_prone_digit(7).
reversal_prone_digit(9).

% True when Digit appears as a decimal digit of any number in the list.
digit_appears_in(Numbers, Digit) :-
    member(N, Numbers),
    integer(N),
    number_has_digit(N, Digit),
    !.

number_has_digit(N, Digit) :-
    nonnegative_integer(N),
    ( N =:= Digit
    ; N >= 10,
      ( N mod 10 =:= Digit
      ; Rest is N // 10,
        number_has_digit(Rest, Digit)
      )
    ).

dropped_carry_answer(A, B, Base, Answer) :-
    positive_integer(Base),
    nonnegative_integer(A),
    nonnegative_integer(B),
    dropped_carry_answer_(A, B, Base, 1, 0, Answer).

dropped_carry_answer_(0, 0, _Base, _PlaceValue, Acc, Acc) :-
    !.
dropped_carry_answer_(A, B, Base, PlaceValue, Acc0, Answer) :-
    ADigit is A mod Base,
    BDigit is B mod Base,
    Digit is (ADigit + BDigit) mod Base,
    Acc1 is Acc0 + Digit * PlaceValue,
    ANext is A // Base,
    BNext is B // Base,
    NextPlaceValue is PlaceValue * Base,
    dropped_carry_answer_(ANext, BNext, Base, NextPlaceValue, Acc1, Answer).

borrow_without_reducing_answer(A, B, Base, Answer) :-
    positive_integer(Base),
    nonnegative_integer(A),
    nonnegative_integer(B),
    A >= B,
    borrow_without_reducing_answer_(A, B, Base, 1, 0, Answer).

borrow_without_reducing_answer_(0, 0, _Base, _PlaceValue, Acc, Acc) :-
    !.
borrow_without_reducing_answer_(A, B, Base, PlaceValue, Acc0, Answer) :-
    ADigit is A mod Base,
    BDigit is B mod Base,
    (   ADigit < BDigit
    ->  Digit is ADigit + Base - BDigit
    ;   Digit is ADigit - BDigit
    ),
    Acc1 is Acc0 + Digit * PlaceValue,
    ANext is A // Base,
    BNext is B // Base,
    NextPlaceValue is PlaceValue * Base,
    borrow_without_reducing_answer_(ANext, BNext, Base, NextPlaceValue, Acc1, Answer).

collapsed_base_ten_block_value(N, Collapsed) :-
    collapsed_base_ten_block_value(N, 0, 0, Collapsed).

collapsed_base_ten_block_value(0, _Place, Acc, Acc) :-
    !.
collapsed_base_ten_block_value(N, Place, Acc0, Collapsed) :-
    Digit is N mod 10,
    Rest is N // 10,
    place_weight_collapsed_to_available_block(Place, Weight),
    Acc1 is Acc0 + Digit * Weight,
    NextPlace is Place + 1,
    collapsed_base_ten_block_value(Rest, NextPlace, Acc1, Collapsed).

place_weight_collapsed_to_available_block(0, 1) :- !.
place_weight_collapsed_to_available_block(1, 10) :- !.
place_weight_collapsed_to_available_block(2, 100) :- !.
place_weight_collapsed_to_available_block(_PlaceAtOrAboveThousands, 1000).

task_answer(whole_number(N), N).
task_answer(subitizing(N), N).
task_answer(whole_number_addition(A, B), Sum) :-
    Sum is A + B.
task_answer(whole_number_subtraction(A, B), Difference) :-
    A >= B,
    Difference is A - B.
task_answer(multiplication(A, B), Product) :-
    Product is A * B.
task_answer(fraction_product(NA, DA, NB, DB), fraction(N, D)) :-
    N is NA * NB,
    D is DA * DB.
task_answer(fraction_addition(fraction(NA, DA), fraction(NB, DB)), fraction(N, D)) :-
    RawN is NA * DB + NB * DA,
    RawD is DA * DB,
    reduce_fraction(RawN, RawD, N, D).
task_answer(fraction_subtraction(fraction(NA, DA), fraction(NB, DB)), fraction(N, D)) :-
    RawN is NA * DB - NB * DA,
    RawN >= 0,
    RawD is DA * DB,
    reduce_fraction(RawN, RawD, N, D).
task_answer(equation(linear(A, B, C)), solution(X)) :-
    A =\= 0,
    Remainder is C - B,
    Remainder mod A =:= 0,
    X is Remainder // A.

reduce_fraction(0, _RawD, 0, 1) :-
    !.
reduce_fraction(RawN, RawD, N, D) :-
    G is gcd(RawN, RawD),
    N is RawN // G,
    D is RawD // G.


% ===========================================================================
% Spatial family — coordinate_plane
% ===========================================================================
% The Cartesian graphing surface: two crossed measuring sticks, a location is an
% ordered pair. It denotes point sets and linear graphs (5.G, 6.NS, 8.F/8.EE).
% Its break is the quadrant-sign error — dropping the sign of a coordinate so the
% pair lands in the wrong quadrant. Scene compiler: coordinate_plane_scene.pl.

representation_language(coordinate_plane).

representation_object(coordinate_plane, axis_pair).
representation_object(coordinate_plane, gridline).
representation_object(coordinate_plane, ordered_pair_point).
representation_object(coordinate_plane, plotted_path).
representation_object(coordinate_plane, quadrant).
representation_object(coordinate_plane, intercept).

% Two crossed measuring sticks: a location is an ordered pair (spaces are sets of
% points, each addressed by two magnitudes).
representation_grounding(coordinate_plane,
    blend(spaces_are_sets_of_points, measuring_stick)).
blend_entails(blend(spaces_are_sets_of_points, measuring_stick),
              ordered_pair_location).

valid_quantity_for_representation(coordinate_plane, point(X, Y)) :-
    integer(X),
    integer(Y),
    !.
valid_quantity_for_representation(coordinate_plane, point_set(Points)) :-
    is_list(Points),
    Points \== [],
    forall(member(P, Points), coordinate_pair(P, _, _)),
    !.
valid_quantity_for_representation(coordinate_plane, linear_graph(M, B)) :-
    integer(M),
    integer(B),
    !.

render_spec_denotes(coordinate_plane, plot_points(Points), point_set(Points)).
render_spec_denotes(coordinate_plane, plot_line(M, B), linear_graph(M, B)).

% The plane is doubly indexed: a bare magnitude has no second coordinate, so the
% coordinate plane refuses to denote a one-dimensional counting quantity.
representation_refusal(coordinate_plane, whole_number(N),
        reason(single_magnitude_has_no_second_coordinate)) :-
    nonnegative_integer(N),
    !.

% The break lane: the quadrant-sign error. A pair with a negative coordinate is
% plotted with that sign dropped, landing in the wrong quadrant. Reachable only
% here (no productive spec plots a sign-dropped point). Literature-only: the
% misconception is documented, with no row in this corpus.
deformation_spec_evidence(
        coordinate_plane,
        quadrant_sign_error(X, Y),
        point(X, Y),
        Evidence) :-
    integer(X),
    integer(Y),
    ( X < 0 -> true ; Y < 0 ),   % at least one sign to drop (deterministic guard)
    WrongX is abs(X),
    WrongY is abs(Y),
    cartesian_quadrant(X, Y, CorrectQuadrant),
    cartesian_quadrant(WrongX, WrongY, WrongQuadrant),
    Evidence = _{
        mode: misconception,
        misconception: quadrant_sign_error,
        representation: coordinate_plane,
        correct_task: point(X, Y),
        correct_point: point(X, Y),
        correct_quadrant: CorrectQuadrant,
        wrong_point: point(WrongX, WrongY),
        wrong_quadrant: WrongQuadrant,
        violation: reason(coordinate_sign_not_preserved),
        provenance: literature_only
    }.

representation_render_status(coordinate_plane, renderable(coordinate_plane_render)).

standard_supports_representation('5_g_a_1', coordinate_plane, grade_5,
    first_quadrant_plotting).
standard_supports_representation('6_ns_c_6', coordinate_plane, grade_6,
    four_quadrant_rational_coordinates).
standard_supports_representation('8_f_b_4', coordinate_plane, grade_8,
    linear_graph_slope_as_rate).

methods_text_supports_representation(lakoff_nunez, coordinate_plane, graphing,
    location_as_ordered_pair_on_crossed_measuring_sticks).
methods_supports_representation_for_grade(Source, coordinate_plane, Grade, Support) :-
    memberchk(Grade, [grade_5, grade_6, grade_7, grade_8]),
    methods_text_supports_representation(Source, coordinate_plane, graphing, Support).

preferred_representation(point(X, Y), coordinate_plane,
        reason(ordered_pair_requires_two_indices)) :-
    integer(X),
    integer(Y).
preferred_representation(linear_graph(M, B), coordinate_plane,
        reason(slope_reads_as_rate_on_the_plane)) :-
    integer(M),
    integer(B).

% coordinate_pair(+Pair, -X, -Y): the accepted written forms of an ordered pair.
coordinate_pair(X-Y, X, Y) :- integer(X), integer(Y).
coordinate_pair(point(X, Y), X, Y) :- integer(X), integer(Y).
coordinate_pair([X, Y], X, Y) :- integer(X), integer(Y).

% cartesian_quadrant(+X, +Y, -Quadrant): I (+,+), II (-,+), III (-,-), IV (+,-),
% with axis/origin labels when a coordinate is zero.
cartesian_quadrant(0, 0, origin) :- !.
cartesian_quadrant(0, _, y_axis) :- !.
cartesian_quadrant(_, 0, x_axis) :- !.
cartesian_quadrant(X, Y, 'I')   :- X > 0, Y > 0, !.
cartesian_quadrant(X, Y, 'II')  :- X < 0, Y > 0, !.
cartesian_quadrant(X, Y, 'III') :- X < 0, Y < 0, !.
cartesian_quadrant(_, _, 'IV').


% ===========================================================================
% Spatial family — rigid_motion
% ===========================================================================
% The transformation actuator for the K-8 spatial catalog: a small integer
% polygon moved by an isometry, the image beside the pre-image so the motion
% reads as a congruence. It denotes isometry images (4.G.3 line symmetry;
% 8.G.1-4, where congruence and similarity are defined through motions of the
% plane). Its break is the reflection-by-rotation error: a chiral tile's mirror
% image is not reachable by any in-plane rotation, because rotation preserves
% orientation and reflection reverses it. Scene compiler: rigid_motion_scene.pl.

representation_language(rigid_motion).

representation_object(rigid_motion, pre_image_figure).
representation_object(rigid_motion, image_figure).
representation_object(rigid_motion, mirror_line).
representation_object(rigid_motion, center_of_rotation).
representation_object(rigid_motion, lattice_vertex).
representation_object(rigid_motion, isometry).

% A figure imagined into motion (fictive motion) blended with the rigid motions
% of the plane: the motion carries the figure to a congruent image.
representation_grounding(rigid_motion,
    blend(fictive_motion, rigid_motion_of_the_plane)).
blend_entails(blend(fictive_motion, rigid_motion_of_the_plane),
              congruence_preserving_motion).

valid_quantity_for_representation(rigid_motion, isometry_image(Shape, Motion)) :-
    rigid_motion_parse(Shape, _),
    rigid_motion_isometry(Motion),
    !.

% The productive Specs the scene compiler accepts (its rigid_motion_render_json/2
% heads): a slide, a reflection across an axis, and a quarter-turn rotation. Each
% denotes the isometry image of the figure.
render_spec_denotes(rigid_motion, translate(Shape, DX, DY),
    isometry_image(Shape, translation(DX, DY))).
render_spec_denotes(rigid_motion, reflect(Shape, Mirror),
    isometry_image(Shape, reflection(Axis))) :-
    rigid_motion_mirror_axis(Mirror, Axis).
render_spec_denotes(rigid_motion, rotate(Shape, Center, Deg),
    isometry_image(Shape, rotation(Center, Deg))).

% A rigid motion preserves congruence: it moves a figure without changing its
% size, so it cannot denote a dilation, which scales length and is not an
% isometry (the honest boundary this language declines).
representation_refusal(rigid_motion, dilation(_Shape, K),
        reason(dilation_scales_length_and_is_not_an_isometry)) :-
    integer(K),
    K =\= 1,
    !.

% The break lane: reflection-by-rotation. A chiral figure (no line of symmetry)
% has a mirror image no rotation within the plane can reach. The deformation
% attempts the reflection across the y-axis by rotating 180 degrees about the
% origin; the rotated tile keeps the figure's orientation, so it does not land on
% the true mirror image. Reachable only here and only for a chiral figure (the
% guard is deterministic). Violation and provenance mirror rigid_motion_compare_json/2.
deformation_spec_evidence(
        rigid_motion,
        reflection_by_rotation(Shape),
        isometry_image(Shape, reflection(y)),
        Evidence) :-
    rigid_motion_parse(Shape, Verts),
    rigid_motion_chiral(Verts),
    Evidence = _{
        mode: misconception,
        misconception: reflection_by_rotation,
        representation: rigid_motion,
        correct_task: isometry_image(Shape, reflection(y)),
        attempted_motion: rotation(origin, 180),
        violation: reason(orientation_reversed_not_reachable_by_rotation),
        provenance: literature_only
    }.

representation_render_status(rigid_motion, renderable(rigid_motion_render)).

standard_supports_representation('4_g_a_3', rigid_motion, grade_4,
    line_symmetry).
standard_supports_representation('8_g_a_1', rigid_motion, grade_8,
    transformations_define_congruence).
standard_supports_representation('8_g_a_4', rigid_motion, grade_8,
    similarity_through_dilation).

methods_text_supports_representation(lakoff_nunez, rigid_motion, transformations,
    congruence_as_motion_of_the_plane).
methods_supports_representation_for_grade(Source, rigid_motion, Grade, Support) :-
    memberchk(Grade, [grade_4, grade_5, grade_6, grade_7, grade_8]),
    methods_text_supports_representation(Source, rigid_motion, transformations, Support).

preferred_representation(isometry_image(Shape, Motion), rigid_motion,
        reason(congruence_is_a_motion_of_the_plane)) :-
    rigid_motion_parse(Shape, _),
    rigid_motion_isometry(Motion).

% --- rigid_motion private helpers (language-unique names) -------------------

% rigid_motion_parse(+Shape, -Verts): read a polygon of three or more integer
% vertices into an ordered X-Y list, matching the scene compiler's parse_shape/2.
rigid_motion_parse(Shape, Verts) :-
    is_list(Shape),
    maplist(rigid_motion_vertex_pair, Shape, Verts),
    length(Verts, N),
    N >= 3.

rigid_motion_vertex_pair(X-Y, X-Y) :- integer(X), integer(Y).
rigid_motion_vertex_pair([X, Y], X-Y) :- integer(X), integer(Y).
rigid_motion_vertex_pair(point(X, Y), X-Y) :- integer(X), integer(Y).

% rigid_motion_isometry(+Motion): the isometries this format draws.
rigid_motion_isometry(translation(DX, DY)) :-
    integer(DX), integer(DY).
rigid_motion_isometry(reflection(Axis)) :-
    memberchk(Axis, [x, y]).
rigid_motion_isometry(rotation(Center, Deg)) :-
    memberchk(Deg, [90, 180, 270]),
    rigid_motion_center(Center).

rigid_motion_center(point(X, Y)) :- integer(X), integer(Y).
rigid_motion_center(X-Y) :- integer(X), integer(Y).
rigid_motion_center([X, Y]) :- integer(X), integer(Y).
rigid_motion_center(origin).

rigid_motion_mirror_axis(mirror_x, x).
rigid_motion_mirror_axis(mirror_y, y).

% rigid_motion_chiral(+Verts): no quarter-turn rotation of the figure's mirror
% image slides back onto the figure. The decidable scope for the break within the
% lattice-preserving isometries this format draws; a figure with a line of
% symmetry fails this guard, so no break is named for it.
rigid_motion_chiral(Verts) :-
    maplist(rigid_motion_reflect_y_pt, Verts, Mirror),
    \+ ( member(Deg, [0, 90, 180, 270]),
         rigid_motion_rotate_set(Deg, Mirror, Rotated),
         rigid_motion_congruent(Rotated, Verts) ).

rigid_motion_reflect_y_pt(X-Y, NX-Y) :- NX is -X.

rigid_motion_rotate_set(0, Verts, Verts) :- !.
rigid_motion_rotate_set(Deg, Verts, Rotated) :-
    maplist(rigid_motion_rotate_pt(Deg), Verts, Rotated).

rigid_motion_rotate_pt(90, X-Y, RX-RY)  :- !, RX is -Y, RY is X.
rigid_motion_rotate_pt(180, X-Y, RX-RY) :- !, RX is -X, RY is -Y.
rigid_motion_rotate_pt(270, X-Y, RX-RY) :- RX is Y, RY is -X.

rigid_motion_congruent(A, B) :-
    rigid_motion_normalize(A, NA),
    rigid_motion_normalize(B, NB),
    NA == NB.

rigid_motion_normalize(Verts, Norm) :-
    findall(X, member(X-_, Verts), Xs),
    findall(Y, member(_-Y, Verts), Ys),
    min_list(Xs, MinX),
    min_list(Ys, MinY),
    findall(DX-DY,
            ( member(X-Y, Verts), DX is X - MinX, DY is Y - MinY ),
            Shifted),
    sort(Shifted, Norm).

% ===========================================================================
% Spatial family — polyform_tiling
% ===========================================================================
% The rigid lattice-tiling surface: unit cells and free polyominoes (the
% pentomino vocabulary) seated edge to edge in a bounded lattice region. It
% denotes composed/decomposed shapes (K.G.6, 1.G.2, 2.G.1) and area by unit
% tiling (3.MD.6). Its two breaks are the chiral-piece flip-vs-rotation error and
% the arche-trace parity obstruction (a removed corner no domino cover can
% close, whose reason leaves the spatial model). Scene compiler:
% polyform_tiling_scene.pl.

representation_language(polyform_tiling).

representation_object(polyform_tiling, lattice_region).
representation_object(polyform_tiling, unit_cell).
representation_object(polyform_tiling, polyomino).
representation_object(polyform_tiling, pentomino).
representation_object(polyform_tiling, domino).
representation_object(polyform_tiling, hole).

% Rigid pieces fill a bounded region: object construction from congruent parts,
% inside a container that fixes the region's extent.
representation_grounding(polyform_tiling,
    blend(object_construction, container)).
blend_entails(blend(object_construction, container),
              rigid_pieces_fill_bounded_region).

valid_quantity_for_representation(polyform_tiling, region(C, R)) :-
    positive_integer(C),
    positive_integer(R),
    !.
valid_quantity_for_representation(polyform_tiling, tiling(region(C, R), Pieces)) :-
    positive_integer(C),
    positive_integer(R),
    is_list(Pieces),
    !.
valid_quantity_for_representation(polyform_tiling, area_by_tiling(region(C, R), _Area)) :-
    positive_integer(C),
    positive_integer(R),
    !.

render_spec_denotes(polyform_tiling,
    tile_region(cols(C), rows(R), Pieces), tiling(region(C, R), Pieces)).
render_spec_denotes(polyform_tiling,
    tile_area(cols(C), rows(R)), area_by_tiling(region(C, R), C*R)).

% A rigid tiling needs a bounded 2-D region: a bare count fixes no region shape
% (N could be 1-by-N, or any factor pair), so polyform_tiling refuses to denote a
% one-dimensional counting quantity.
representation_refusal(polyform_tiling, whole_number(N),
        reason(bare_count_fixes_no_bounded_region)) :-
    nonnegative_integer(N),
    !.

% Break lane (a): the chiral-piece flip-vs-rotation error. A chiral pentomino
% seats only with the Flip button; a rotation-only attempt lands some cells and
% pushes the rest outside the footprint. Reachable only through the compare form
% flip_needed_compare/1 (no productive spec emits a flip overhang). Same functor
% and violation the compiler's polyform_tiling_compare_json/2 carries.
% Literature-only: the misconception is documented, with no row in this corpus.
deformation_spec_evidence(
        polyform_tiling,
        flip_needed_compare(Piece),
        place_pentomino(Piece),
        Evidence) :-
    memberchk(Piece, [l, f, n, p, y, z]),   % a chiral pentomino (deterministic guard)
    Evidence = _{
        mode: misconception,
        misconception: flip_needed,
        representation: polyform_tiling,
        correct_task: place_pentomino(Piece),
        required_motion: flip,
        attempted_motion: rotation,
        violation: reason(chirality_requires_flip_not_rotation),
        provenance: literature_only
    }.
% Break lane (b): the arche-trace parity obstruction. A region with a removed
% corner stalls under a partial domino cover; whether it tiles at all is a
% checkerboard-coloring parity count that leaves the spatial model. Reachable
% only through unfillable_by_parity_compare/1. Same functor and violation the
% compiler carries; erasure:true names the boundary, it does not prove it.
deformation_spec_evidence(
        polyform_tiling,
        unfillable_by_parity_compare(cols(C), rows(R)),
        area_by_tiling(region(C, R), Area),
        Evidence) :-
    integer(C),
    integer(R),
    C >= 2,
    R >= 2,
    Area is C * R,
    Evidence = _{
        mode: misconception,
        misconception: unfillable_by_parity,
        representation: polyform_tiling,
        correct_task: area_by_tiling(region(C, R), Area),
        removed_corner: corner(C, R),
        erasure: true,
        handoff: coloring_parity_argument,
        violation: reason(coloring_parity_imbalance),
        provenance: literature_only
    }.

representation_render_status(polyform_tiling, renderable(polyform_tiling_render)).

standard_supports_representation('k_g_a_6', polyform_tiling, kindergarten,
    compose_shapes).
standard_supports_representation('2_g_a_1', polyform_tiling, grade_2,
    compose_decompose_shapes).
standard_supports_representation('3_md_c_6', polyform_tiling, grade_3,
    area_by_unit_tiling).

methods_text_supports_representation(van_de_walle, polyform_tiling, geometry,
    compose_from_rigid_parts).
methods_supports_representation_for_grade(Source, polyform_tiling, Grade, Support) :-
    memberchk(Grade, [kindergarten, grade_1, grade_2, grade_3]),
    methods_text_supports_representation(Source, polyform_tiling, geometry, Support).

preferred_representation(tiling(region(C, R), Pieces), polyform_tiling,
        reason(rigid_pieces_compose_a_bounded_region)) :-
    positive_integer(C),
    positive_integer(R),
    is_list(Pieces).
preferred_representation(area_by_tiling(region(C, R), _Area), polyform_tiling,
        reason(area_reads_as_a_unit_cell_count)) :-
    positive_integer(C),
    positive_integer(R).
% ===========================================================================
% Spatial family — angle_circular
% ===========================================================================
% A turning task: two rays from a shared vertex with an arc that records the
% amount of turn between them, optionally filled as a central-angle sector. An
% angle encodes an amount of turning, not a length; the rays can be drawn any
% length without changing the measure. It denotes angle measures and central
% angles (4.MD.5, 4.MD.7, 7.G.5). Its break is the ray-length error — reading an
% angle drawn with longer rays as a bigger angle, when ray length carries none of
% the measure. Scene compiler: angle_circular_scene.pl.

representation_language(angle_circular).

representation_object(angle_circular, vertex).
representation_object(angle_circular, ray).
representation_object(angle_circular, initial_ray).
representation_object(angle_circular, terminal_ray).
representation_object(angle_circular, turn_arc).
representation_object(angle_circular, central_angle_sector).

% A turn along a path toward a goal, run as a rotation: an angle is the amount of
% turning between the initial and terminal rays.
representation_grounding(angle_circular,
    blend(source_path_goal, rotation)).
blend_entails(blend(source_path_goal, rotation),
              angle_is_amount_of_turning).

valid_quantity_for_representation(angle_circular, angle_measure(Degrees)) :-
    angle_circular_valid_measure(Degrees),
    !.
valid_quantity_for_representation(angle_circular, central_angle(Degrees)) :-
    angle_circular_valid_measure(Degrees),
    !.

render_spec_denotes(angle_circular, angle(Degrees), angle_measure(Degrees)).
render_spec_denotes(angle_circular, sector(Degrees), angle_measure(Degrees)).

% An angle measure is a rotational magnitude, not a length: the rays can be drawn
% any length. So the circular-angle representation refuses to denote a linear
% length quantity — there is no length for the turn to carry.
representation_refusal(angle_circular, linear_length(L),
        reason(angle_measure_carries_no_length)) :-
    integer(L),
    L > 0,
    !.

% The break lane: the ray-length error. The same turn is redrawn with longer rays
% and read as a bigger angle, when ray length carries none of the measure.
% Reachable only here (no productive spec draws over-long rays and calls the angle
% bigger); it is the compiler's angle_circular_compare_json/2 lane. Literature-
% only: the misconception is documented, with no row in this corpus.
deformation_spec_evidence(
        angle_circular,
        ray_length_error(Degrees, ReferenceLen, StretchedLen),
        angle_measure(Degrees),
        Evidence) :-
    angle_circular_valid_measure(Degrees),
    integer(ReferenceLen),
    integer(StretchedLen),
    ReferenceLen > 0,
    StretchedLen > ReferenceLen,   % a longer draw length to stretch (deterministic guard)
    Evidence = _{
        mode: misconception,
        misconception: angle_confused_with_ray_length,
        representation: angle_circular,
        correct_task: angle_measure(Degrees),
        correct_measure: Degrees,
        reference_length: ReferenceLen,
        stretched_length: StretchedLen,
        read_as: bigger,
        violation: reason(ray_length_is_not_angle_measure),
        provenance: literature_only
    }.

representation_render_status(angle_circular, renderable(angle_circular_render)).

standard_supports_representation('4_md_c_5', angle_circular, grade_4,
    angle_measure_as_turn).
standard_supports_representation('4_md_c_7', angle_circular, grade_4,
    additive_angle_measure).
standard_supports_representation('7_g_b_5', angle_circular, grade_7,
    angle_relationships).

methods_text_supports_representation(van_de_walle, angle_circular, geometry,
    angle_as_rotation_amount).
methods_supports_representation_for_grade(Source, angle_circular, Grade, Support) :-
    memberchk(Grade, [grade_4, grade_5, grade_6, grade_7]),
    methods_text_supports_representation(Source, angle_circular, geometry, Support).

preferred_representation(angle_measure(Degrees), angle_circular,
        reason(turn_reads_as_the_arc_between_the_rays)) :-
    angle_circular_valid_measure(Degrees).
preferred_representation(central_angle(Degrees), angle_circular,
        reason(sector_reads_as_a_fraction_of_the_circle)) :-
    angle_circular_valid_measure(Degrees).

% angle_circular_valid_measure(+Degrees): a drawable angle measure is a whole
% number of degrees in 1..360 (language-private helper; named for the language to
% avoid colliding with the other spatial sections).
angle_circular_valid_measure(Degrees) :-
    integer(Degrees),
    Degrees > 0,
    Degrees =< 360.
% ===========================================================================
% Spatial family — data_display
% ===========================================================================
% A small family of statistical pictures under one language: the picture / bar
% graph (1.MD.4, 3.MD.3) and the dot plot / histogram / box plot (6.SP.4). A
% length denotes a count: a bar's extent, or a stacked column of dots, marks how
% many observations fall in a category or on a value. Its break is the
% bar/histogram conflation — categorical bars redrawn touching, the gaps closed,
% so discrete categories read as the evenly binned intervals of one continuous
% variable. Scene compiler: data_display_scene.pl.

representation_language(data_display).

representation_object(data_display, category_axis).
representation_object(data_display, frequency_axis).
representation_object(data_display, bar).
representation_object(data_display, bin).
representation_object(data_display, stacked_dot).
representation_object(data_display, category_gap).

% A measuring stick laid over a collection: the length of a mark measures the
% size of the collection it stands for, so a bar's extent denotes a count.
representation_grounding(data_display,
    blend(measuring_stick, object_collection)).
blend_entails(blend(measuring_stick, object_collection),
              mark_extent_denotes_a_count).

valid_quantity_for_representation(data_display, data_display(bar_chart, Pairs)) :-
    is_list(Pairs),
    Pairs \== [],
    forall(member(P, Pairs), data_display_pair(P, _, _)),
    !.
valid_quantity_for_representation(data_display, data_display(dot_plot, Values)) :-
    is_list(Values),
    Values \== [],
    forall(member(V, Values), integer(V)),
    !.

render_spec_denotes(data_display, bar_chart(Pairs), data_display(bar_chart, Pairs)).
render_spec_denotes(data_display, dot_plot(Values), data_display(dot_plot, Values)).

% The grounding fixes a mark's length as a *count*: mark_extent_denotes_a_count.
% A bare continuous magnitude carries no count, so a data display refuses to
% denote it — there is no frequency for an extent to mark. (A single measured
% quantity is not the same kind of thing as a distribution over categories.)
representation_refusal(data_display, continuous_magnitude(M),
        reason(an_extent_denotes_a_count_not_a_bare_magnitude)) :-
    number(M),
    !.

% The break lane: the bar/histogram conflation. The productive spaced bars are
% redrawn touching, the categorical gaps closed, so the discrete categories
% mis-signal the evenly binned intervals of one continuous variable. Reachable
% only here (no productive spec draws touching bars) and only via the
% misconception lane. Literature-only: the misconception is documented, with no
% row in this corpus. The guard is deterministic (a single count comparison), so
% the grammar tests do not warn.
deformation_spec_evidence(
        data_display,
        bar_histogram_conflation(Pairs),
        data_display(bar_chart, Pairs),
        Evidence) :-
    data_display_pair_count(Pairs, N),
    N >= 2,
    Evidence = _{
        mode: misconception,
        misconception: bar_histogram_conflation,
        representation: data_display,
        correct_task: data_display(bar_chart, Pairs),
        productive_kind: bar_chart,
        deformation_kind: pseudo_histogram,
        categories: N,
        violation: reason(categorical_spacing_read_as_continuous_bins),
        provenance: literature_only
    }.

representation_render_status(data_display, renderable(data_display_render)).

standard_supports_representation('1_md_c_4', data_display, grade_1,
    picture_and_bar_graphs).
standard_supports_representation('3_md_b_3', data_display, grade_3,
    scaled_bar_graphs).
standard_supports_representation('6_sp_b_4', data_display, grade_6,
    dot_plot_histogram_box_plot).

methods_text_supports_representation(van_de_walle, data_display, data_analysis,
    length_denotes_frequency).
methods_supports_representation_for_grade(Source, data_display, Grade, Support) :-
    memberchk(Grade,
        [grade_1, grade_2, grade_3, grade_4, grade_5, grade_6, grade_7, grade_8]),
    methods_text_supports_representation(Source, data_display, data_analysis, Support).

preferred_representation(data_display(bar_chart, Pairs), data_display,
        reason(a_bar_length_reads_off_a_category_count)) :-
    is_list(Pairs).
preferred_representation(data_display(dot_plot, Values), data_display,
        reason(a_dot_column_reads_off_a_value_frequency)) :-
    is_list(Values).

% data_display_pair(+Entry, -Category, -Count): the accepted written forms of a
% Category-Count entry, with a nonnegative integer count. Mirrors the scene
% compiler's pair_cat_count/3. Language-unique name (no collision with other
% spatial sections).
data_display_pair(Cat-Count, Cat, Count) :- integer(Count), Count >= 0.
data_display_pair([Cat, Count], Cat, Count) :- integer(Count), Count >= 0.

% data_display_pair_count(+Pairs, -N): how many well-formed Category-Count
% entries a would-be bar chart carries. Deterministic; N=0 when Pairs is not a
% list, so the deformation guard above never leaves a choice point.
data_display_pair_count(Pairs, N) :-
    ( is_list(Pairs)
    -> findall(C-K, ( member(P, Pairs), data_display_pair(P, C, K) ), Clean),
       length(Clean, N)
    ;  N = 0
    ).

% ===========================================================================
% Spatial family — solid_net
% ===========================================================================
% A solid unfolds to a planar net: an arrangement of flat polygonal faces joined
% at fold creases, plus an isometric unit-cube stack for volume. It denotes the
% net of a solid and a solid's volume in unit cubes (5.MD, 6.G, 7.G). Its break is
% the unfoldable arrangement — the right number of faces placed so folding lands
% two on the same side, so the tiles never close to the solid. Scene compiler:
% solid_net_scene.pl.

representation_language(solid_net).

representation_object(solid_net, planar_net).
representation_object(solid_net, face).
representation_object(solid_net, fold_crease).
representation_object(solid_net, solid).
representation_object(solid_net, unit_cube).
representation_object(solid_net, isometric_stack).

% A container whose walls are constructed from flat faces: the faces fold up from
% a planar net, so a 3-D solid is read off a 2-D arrangement joined at creases.
representation_grounding(solid_net, blend(container, object_construction)).
blend_entails(blend(container, object_construction), solid_folds_from_a_planar_net).

valid_quantity_for_representation(solid_net, net(Solid)) :-
    solid_net_supported_solid(Solid),
    !.
valid_quantity_for_representation(solid_net, solid_volume(L, W, H)) :-
    solid_net_positive_dim(L),
    solid_net_positive_dim(W),
    solid_net_positive_dim(H),
    !.

render_spec_denotes(solid_net, net_of(Solid), net(Solid)).
render_spec_denotes(solid_net, unit_cube_stack(L, W, H), solid_volume(L, W, H)).

% A net presupposes a polyhedron whose faces are flat polygons: a curved surface
% (a sphere) has no planar polygonal net, so solid_net refuses to denote it.
representation_refusal(solid_net, net(Solid),
        reason(curved_surface_has_no_planar_net)) :-
    solid_net_curved_surface(Solid),
    !.

% The break lane: the unfoldable arrangement. A layout carries the RIGHT number of
% faces for the named solid but placed so folding forces two onto the same side, so
% it never closes to the solid. Reachable only here (no productive spec emits an
% unfoldable arrangement). Literature-only: the misconception is documented, with
% no row in this corpus. The guard is a single deterministic lookup, not a
% disjunction.
deformation_spec_evidence(
        solid_net,
        net_does_not_fold(Solid, BadArrangement),
        net(Solid),
        Evidence) :-
    solid_net_unfoldable_arrangement(Solid, BadArrangement, FaceCount),
    !,
    Evidence = _{
        mode: misconception,
        misconception: net_does_not_fold,
        representation: solid_net,
        correct_task: net(Solid),
        solid: Solid,
        bad_arrangement: BadArrangement,
        face_count: FaceCount,
        violation: reason(net_faces_do_not_fold_to_solid),
        provenance: literature_only
    }.

representation_render_status(solid_net, renderable(solid_net_render)).

standard_supports_representation('5_md_c_4', solid_net, grade_5,
    volume_by_unit_cubes).
standard_supports_representation('6_g_a_4', solid_net, grade_6,
    nets_and_surface_area).
standard_supports_representation('7_g_b_6', solid_net, grade_7,
    surface_area_and_volume).

methods_text_supports_representation(van_de_walle, solid_net, geometry,
    solids_unfold_to_nets).
methods_supports_representation_for_grade(Source, solid_net, Grade, Support) :-
    memberchk(Grade, [grade_5, grade_6, grade_7, grade_8]),
    methods_text_supports_representation(Source, solid_net, geometry, Support).

preferred_representation(net(Solid), solid_net,
        reason(faces_and_folds_read_off_a_planar_net)) :-
    solid_net_supported_solid(Solid).
preferred_representation(solid_volume(L, W, H), solid_net,
        reason(volume_reads_as_a_count_of_unit_cubes)) :-
    solid_net_positive_dim(L),
    solid_net_positive_dim(W),
    solid_net_positive_dim(H).

% solid_net_supported_solid(+Solid): the solids whose planar net the compiler lays
% out (solid_net_scene.pl solid_net_shape/3).
solid_net_supported_solid(cube).
solid_net_supported_solid(square_pyramid).
solid_net_supported_solid(triangular_prism).
solid_net_supported_solid(rectangular_prism).

% solid_net_curved_surface(+Solid): a solid whose surface is curved, so it has no
% flat polygonal net.
solid_net_curved_surface(sphere).

% solid_net_positive_dim(+N): a positive integer stack dimension.
solid_net_positive_dim(N) :- integer(N), N > 0.

% solid_net_unfoldable_arrangement(+Solid, ?Name, ?FaceCount): the characteristic
% unfoldable arrangement (solid_net_scene.pl bad_arrangement/4). The cube's is a
% 2-by-3 block of six squares — the right count, but it holds a 2-by-2 sub-square,
% so folding lands two faces on the same side.
solid_net_unfoldable_arrangement(cube, two_by_three_block, 6).


% ===========================================================================
% Spatial family — geoboard
% ===========================================================================
% Pegs and a bounding band: a simple closed polygon on the integer lattice. It
% denotes a bounded region whose area and perimeter read off the pegs (3.MD.8 /
% 4.MD.3), the natural home for Pick's theorem A = I + B/2 - 1. Its break is the
% boundary-peg miscount: counting a peg on the band's edge as interior, which
% inflates Pick's area by one half. Scene compiler: geoboard_scene.pl.

representation_language(geoboard).

representation_object(geoboard, peg_lattice).
representation_object(geoboard, rubber_band_polygon).
representation_object(geoboard, boundary_peg).
representation_object(geoboard, interior_peg).
representation_object(geoboard, unit_area).
representation_object(geoboard, unit_segment).

% Pegs are the point-set; the band is a closed curve bounding a region with an
% area (a set-of-points space blended with the container schema).
representation_grounding(geoboard,
    blend(spaces_are_sets_of_points, container)).
blend_entails(blend(spaces_are_sets_of_points, container),
              band_bounds_region_on_a_peg_lattice).

valid_quantity_for_representation(geoboard, geoboard_polygon(Vertices)) :-
    geoboard_lattice_polygon(Vertices),
    !.

render_spec_denotes(geoboard, stretch_polygon(Vertices), geoboard_polygon(Vertices)).

% A bare magnitude has no bounded region: a single count cannot be a polygon, so
% the geoboard declines to denote a one-dimensional quantity (its honest boundary).
representation_refusal(geoboard, whole_number(N),
        reason(a_bare_magnitude_bounds_no_region)) :-
    nonnegative_integer(N),
    !.

% The break lane: the boundary-peg miscount. A peg on the band's edge, recounted
% as interior, inflates Pick's area by one half (an interior peg weighs twice a
% boundary peg). Reachable only here and only for a well-formed lattice polygon.
% Literature-only: the misconception is documented, with no row in this corpus.
deformation_spec_evidence(
        geoboard,
        boundary_peg_as_interior(Vertices),
        geoboard_polygon(Vertices),
        Evidence) :-
    geoboard_lattice_polygon(Vertices),
    Evidence = _{
        mode: misconception,
        misconception: boundary_peg_as_interior,
        representation: geoboard,
        correct_task: geoboard_polygon(Vertices),
        violation: reason(boundary_peg_miscounted_as_interior),
        provenance: literature_only
    }.

representation_render_status(geoboard, renderable(geoboard_render)).

standard_supports_representation('3_md_d_8', geoboard, grade_3,
    perimeter_and_area).
standard_supports_representation('4_md_a_3', geoboard, grade_4,
    area_perimeter_formulas).
standard_supports_representation('5_g_geoboard', geoboard, grade_5,
    picks_theorem_area).

methods_text_supports_representation(van_de_walle, geoboard, measurement,
    area_and_perimeter_on_a_lattice).
methods_supports_representation_for_grade(Source, geoboard, Grade, Support) :-
    memberchk(Grade, [grade_3, grade_4, grade_5, grade_6]),
    methods_text_supports_representation(Source, geoboard, measurement, Support).

preferred_representation(geoboard_polygon(Vertices), geoboard,
        reason(area_and_perimeter_read_off_the_peg_lattice)) :-
    geoboard_lattice_polygon(Vertices).

% --- geoboard private helpers (language-unique names) -----------------------

% geoboard_lattice_polygon(+Vertices): three or more distinct integer lattice
% pegs forming a non-self-intersecting polygon with nonzero area.
geoboard_lattice_polygon(Vertices) :-
    is_list(Vertices),
    maplist(geoboard_grammar_vertex_pair, Vertices, Pairs),
    length(Pairs, N),
    N >= 3,
    sort(Pairs, Distinct),
    length(Distinct, N),
    geoboard_grammar_area2(Pairs, Area2),
    Area2 > 0,
    \+ geoboard_grammar_has_crossing_edges(Pairs).

geoboard_grammar_pair(X-Y, X, Y) :- integer(X), integer(Y).
geoboard_grammar_pair(point(X, Y), X, Y) :- integer(X), integer(Y).
geoboard_grammar_pair([X, Y], X, Y) :- integer(X), integer(Y).

geoboard_grammar_vertex_pair(Vertex, X-Y) :-
    geoboard_grammar_pair(Vertex, X, Y).

geoboard_grammar_area2(Vertices, Area2) :-
    Vertices = [First|_],
    geoboard_grammar_area2_(Vertices, First, 0, Sum),
    Area2 is abs(Sum).

geoboard_grammar_area2_([X1-Y1], FX-FY, Acc, Sum) :-
    !,
    Sum is Acc + X1 * FY - Y1 * FX.
geoboard_grammar_area2_([X1-Y1, X2-Y2|Rest], First, Acc, Sum) :-
    Acc1 is Acc + X1 * Y2 - Y1 * X2,
    geoboard_grammar_area2_([X2-Y2|Rest], First, Acc1, Sum).

geoboard_grammar_has_crossing_edges(Vertices) :-
    geoboard_grammar_indexed_edges(Vertices, Edges),
    length(Edges, EdgeCount),
    member(E1, Edges),
    member(E2, Edges),
    E1 = edge(I, X1, Y1, X2, Y2),
    E2 = edge(J, X3, Y3, X4, Y4),
    I < J,
    \+ geoboard_grammar_adjacent_edges(I, J, EdgeCount),
    geoboard_grammar_segments_intersect(X1, Y1, X2, Y2, X3, Y3, X4, Y4).

geoboard_grammar_indexed_edges(Vertices, Edges) :-
    Vertices = [First|_],
    geoboard_grammar_indexed_edges_(Vertices, First, 1, Edges).

geoboard_grammar_indexed_edges_([X1-Y1], FX-FY, I, [edge(I, X1, Y1, FX, FY)]) :-
    !.
geoboard_grammar_indexed_edges_([X1-Y1, X2-Y2|Rest], First, I,
                                [edge(I, X1, Y1, X2, Y2)|Edges]) :-
    I1 is I + 1,
    geoboard_grammar_indexed_edges_([X2-Y2|Rest], First, I1, Edges).

geoboard_grammar_adjacent_edges(I, J, EdgeCount) :-
    ( J =:= I + 1
    ; I =:= 1, J =:= EdgeCount
    ).

geoboard_grammar_segments_intersect(X1, Y1, X2, Y2, X3, Y3, X4, Y4) :-
    geoboard_grammar_orientation(X1, Y1, X2, Y2, X3, Y3, O1),
    geoboard_grammar_orientation(X1, Y1, X2, Y2, X4, Y4, O2),
    geoboard_grammar_orientation(X3, Y3, X4, Y4, X1, Y1, O3),
    geoboard_grammar_orientation(X3, Y3, X4, Y4, X2, Y2, O4),
    ( O1 =\= O2, O3 =\= O4
    ; O1 =:= 0, geoboard_grammar_on_segment(X3, Y3, X1, Y1, X2, Y2)
    ; O2 =:= 0, geoboard_grammar_on_segment(X4, Y4, X1, Y1, X2, Y2)
    ; O3 =:= 0, geoboard_grammar_on_segment(X1, Y1, X3, Y3, X4, Y4)
    ; O4 =:= 0, geoboard_grammar_on_segment(X2, Y2, X3, Y3, X4, Y4)
    ).

geoboard_grammar_orientation(X1, Y1, X2, Y2, X3, Y3, Orientation) :-
    Cross is (X2 - X1) * (Y3 - Y1) - (Y2 - Y1) * (X3 - X1),
    ( Cross > 0
    -> Orientation = 1
    ;  Cross < 0
    -> Orientation = -1
    ;  Orientation = 0
    ).

geoboard_grammar_on_segment(PX, PY, X1, Y1, X2, Y2) :-
    min(X1, X2) =< PX,
    PX =< max(X1, X2),
    min(Y1, Y2) =< PY,
    PY =< max(Y1, Y2).
