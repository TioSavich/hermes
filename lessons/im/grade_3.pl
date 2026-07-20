% lessons/im/grade_3.pl - Strategy/misconception facts for grade 3
:- multifile explicit_lesson_strategy/4.
:- discontiguous explicit_lesson_strategy/4.
:- multifile explicit_lesson_misconception/4.
:- discontiguous explicit_lesson_misconception/4.
:- multifile text_interpreter:explicit_lesson_text_source/2.
:- discontiguous text_interpreter:explicit_lesson_text_source/2.

text_interpreter:explicit_lesson_text_source('IM-G3-U1-L1', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit1/lesson1.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U1-L10', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G3-U1-L10', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U1-L10', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit1/lesson10.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U1-L11', subtraction, add_instead_of_subtract_column, Info) :-
    strategy_info(subtraction, add_instead_of_subtract_column, Info).
explicit_lesson_strategy('IM-G3-U1-L11', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G3-U1-L11', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
explicit_lesson_misconception('IM-G3-U1-L11', Operation, add_instead_of_subtract_column, Info) :-
    misconception_registry_entry(add_instead_of_subtract_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_subtract_column, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U1-L11', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit1/lesson11.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U1-L12', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G3-U1-L12', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
explicit_lesson_misconception('IM-G3-U1-L12', Operation, add_instead_of_multiply, Info) :-
    misconception_registry_entry(add_instead_of_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_multiply, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U1-L12', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit1/lesson12.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U1-L13', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G3-U1-L13', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
explicit_lesson_misconception('IM-G3-U1-L13', Operation, add_instead_of_multiply, Info) :-
    misconception_registry_entry(add_instead_of_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_multiply, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U1-L13', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit1/lesson13.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U1-L14', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G3-U1-L14', multiplication, coordinate_groups_items, Info) :-
    strategy_info(multiplication, coordinate_groups_items, Info).
explicit_lesson_strategy('IM-G3-U1-L14', multiplication, multiplication_fact_retrieval, Info) :-
    strategy_info(multiplication, multiplication_fact_retrieval, Info).
explicit_lesson_misconception('IM-G3-U1-L14', Operation, context_free_fact_family_guess, Info) :-
    misconception_registry_entry(context_free_fact_family_guess, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(context_free_fact_family_guess, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G3-U1-L14', Operation, rigid_factor_order_roles, Info) :-
    misconception_registry_entry(rigid_factor_order_roles, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(rigid_factor_order_roles, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U1-L14', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit1/lesson14.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U1-L15', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G3-U1-L15', addition, known_fact_retrieval, Info) :-
    strategy_info(addition, known_fact_retrieval, Info).
explicit_lesson_strategy('IM-G3-U1-L15', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G3-U1-L15', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
explicit_lesson_strategy('IM-G3-U1-L15', division, missing_factor_repeated_addition, Info) :-
    strategy_info(division, missing_factor_repeated_addition, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U1-L15', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit1/lesson15.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U1-L16', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G3-U1-L16', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U1-L16', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit1/lesson16.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U1-L17', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G3-U1-L17', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U1-L17', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit1/lesson17.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U1-L18', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G3-U1-L18', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G3-U1-L18', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U1-L18', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit1/lesson18.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U1-L19', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G3-U1-L19', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U1-L19', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit1/lesson19.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G3-U1-L2', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit1/lesson2.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U1-L20', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G3-U1-L20', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G3-U1-L20', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
explicit_lesson_misconception('IM-G3-U1-L20', Operation, add_instead_of_multiply, Info) :-
    misconception_registry_entry(add_instead_of_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_multiply, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U1-L20', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit1/lesson20.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U1-L21', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G3-U1-L21', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U1-L21', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit1/lesson21.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U1-L3', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G3-U1-L3', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U1-L3', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit1/lesson3.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G3-U1-L4', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit1/lesson4.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G3-U1-L5', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit1/lesson5.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G3-U1-L6', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit1/lesson6.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G3-U1-L7', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit1/lesson7.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G3-U1-L8', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit1/lesson8.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U1-L9', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G3-U1-L9', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G3-U1-L9', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U1-L9', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit1/lesson9.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U2-L1', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G3-U2-L1', division, measure_groups_of_size, Info) :-
    strategy_info(division, measure_groups_of_size, Info).
explicit_lesson_strategy('IM-G3-U2-L1', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U2-L1', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit2/lesson1.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U2-L10', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G3-U2-L10', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U2-L10', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit2/lesson10.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U2-L11', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U2-L11', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit2/lesson11.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U2-L12', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G3-U2-L12', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G3-U2-L12', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G3-U2-L12', subtraction, take_away_base_ones, Info) :-
    strategy_info(subtraction, take_away_base_ones, Info).
explicit_lesson_strategy('IM-G3-U2-L12', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_strategy('IM-G3-U2-L12', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
explicit_lesson_misconception('IM-G3-U2-L12', Operation, share_smaller_into_larger, Info) :-
    misconception_registry_entry(share_smaller_into_larger, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_smaller_into_larger, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G3-U2-L12', Operation, count_on_off_by_one, Info) :-
    misconception_registry_entry(count_on_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_on_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U2-L12', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit2/lesson12.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U2-L13', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G3-U2-L13', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G3-U2-L13', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G3-U2-L13', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_misconception('IM-G3-U2-L13', Operation, share_smaller_into_larger, Info) :-
    misconception_registry_entry(share_smaller_into_larger, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_smaller_into_larger, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G3-U2-L13', Operation, add_instead_of_multiply, Info) :-
    misconception_registry_entry(add_instead_of_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_multiply, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U2-L13', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit2/lesson13.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G3-U2-L14', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit2/lesson14.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G3-U2-L15', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit2/lesson15.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G3-U2-L2', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit2/lesson2.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G3-U2-L3', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit2/lesson3.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G3-U2-L4', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit2/lesson4.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U2-L5', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G3-U2-L5', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U2-L5', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit2/lesson5.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G3-U2-L6', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit2/lesson6.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G3-U2-L7', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit2/lesson7.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U2-L8', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G3-U2-L8', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G3-U2-L8', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
explicit_lesson_misconception('IM-G3-U2-L8', Operation, add_on_both_sides_of_dot, Info) :-
    misconception_registry_entry(add_on_both_sides_of_dot, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_on_both_sides_of_dot, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G3-U2-L8', Operation, count_on_off_by_one, Info) :-
    misconception_registry_entry(count_on_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_on_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U2-L8', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit2/lesson8.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U2-L9', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G3-U2-L9', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
explicit_lesson_misconception('IM-G3-U2-L9', Operation, add_on_both_sides_of_dot, Info) :-
    misconception_registry_entry(add_on_both_sides_of_dot, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_on_both_sides_of_dot, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U2-L9', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit2/lesson9.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U3-L1', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G3-U3-L1', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G3-U3-L1', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U3-L1', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit3/lesson1.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U3-L10', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G3-U3-L10', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G3-U3-L10', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U3-L10', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit3/lesson10.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U3-L11', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G3-U3-L11', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G3-U3-L11', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G3-U3-L11', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U3-L11', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit3/lesson11.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U3-L12', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G3-U3-L12', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G3-U3-L12', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_strategy('IM-G3-U3-L12', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G3-U3-L12', multiplication, multiplication_fact_retrieval, Info) :-
    strategy_info(multiplication, multiplication_fact_retrieval, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U3-L12', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit3/lesson12.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U3-L13', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G3-U3-L13', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U3-L13', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit3/lesson13.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U3-L14', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G3-U3-L14', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G3-U3-L14', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_strategy('IM-G3-U3-L14', subtraction, add_instead_of_subtract_column, Info) :-
    strategy_info(subtraction, add_instead_of_subtract_column, Info).
explicit_lesson_misconception('IM-G3-U3-L14', Operation, add_instead_of_multiply, Info) :-
    misconception_registry_entry(add_instead_of_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_multiply, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G3-U3-L14', Operation, add_instead_of_subtract_column, Info) :-
    misconception_registry_entry(add_instead_of_subtract_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_subtract_column, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U3-L14', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit3/lesson14.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U3-L15', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G3-U3-L15', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G3-U3-L15', subtraction, add_instead_of_subtract_column, Info) :-
    strategy_info(subtraction, add_instead_of_subtract_column, Info).
explicit_lesson_misconception('IM-G3-U3-L15', Operation, add_instead_of_multiply, Info) :-
    misconception_registry_entry(add_instead_of_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_multiply, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G3-U3-L15', Operation, add_instead_of_subtract_column, Info) :-
    misconception_registry_entry(add_instead_of_subtract_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_subtract_column, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U3-L15', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit3/lesson15.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U3-L16', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_misconception('IM-G3-U3-L16', Operation, add_instead_of_multiply, Info) :-
    misconception_registry_entry(add_instead_of_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_multiply, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G3-U3-L16', Operation, minus_as_plus, Info) :-
    misconception_registry_entry(minus_as_plus, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(minus_as_plus, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U3-L16', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit3/lesson16.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U3-L17', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_misconception('IM-G3-U3-L17', Operation, adjust_to_make_smaller, Info) :-
    misconception_registry_entry(adjust_to_make_smaller, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(adjust_to_make_smaller, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U3-L17', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit3/lesson17.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U3-L18', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U3-L18', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit3/lesson18.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U3-L19', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U3-L19', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit3/lesson19.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U3-L2', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G3-U3-L2', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G3-U3-L2', subtraction, take_away_base_ones, Info) :-
    strategy_info(subtraction, take_away_base_ones, Info).
explicit_lesson_strategy('IM-G3-U3-L2', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_strategy('IM-G3-U3-L2', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
explicit_lesson_strategy('IM-G3-U3-L2', subtraction, add_instead_of_subtract_column, Info) :-
    strategy_info(subtraction, add_instead_of_subtract_column, Info).
explicit_lesson_misconception('IM-G3-U3-L2', Operation, add_instead_of_subtract_column, Info) :-
    misconception_registry_entry(add_instead_of_subtract_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_subtract_column, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U3-L2', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit3/lesson2.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U3-L20', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G3-U3-L20', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U3-L20', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit3/lesson20.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U3-L21', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U3-L21', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit3/lesson21.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U3-L3', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G3-U3-L3', addition, column_addition_with_carrying, Info) :-
    strategy_info(addition, column_addition_with_carrying, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U3-L3', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit3/lesson3.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U3-L4', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U3-L4', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit3/lesson4.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U3-L5', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U3-L5', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit3/lesson5.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U3-L6', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G3-U3-L6', subtraction, take_away_base_ones, Info) :-
    strategy_info(subtraction, take_away_base_ones, Info).
explicit_lesson_strategy('IM-G3-U3-L6', subtraction, add_instead_of_subtract_column, Info) :-
    strategy_info(subtraction, add_instead_of_subtract_column, Info).
explicit_lesson_misconception('IM-G3-U3-L6', Operation, add_instead_of_subtract_column, Info) :-
    misconception_registry_entry(add_instead_of_subtract_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_subtract_column, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U3-L6', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit3/lesson6.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U3-L7', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G3-U3-L7', addition, column_addition_with_carrying, Info) :-
    strategy_info(addition, column_addition_with_carrying, Info).
explicit_lesson_strategy('IM-G3-U3-L7', subtraction, take_away_base_ones, Info) :-
    strategy_info(subtraction, take_away_base_ones, Info).
explicit_lesson_strategy('IM-G3-U3-L7', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U3-L7', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit3/lesson7.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U3-L8', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G3-U3-L8', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G3-U3-L8', subtraction, take_away_base_ones, Info) :-
    strategy_info(subtraction, take_away_base_ones, Info).
explicit_lesson_strategy('IM-G3-U3-L8', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U3-L8', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit3/lesson8.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U3-L9', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G3-U3-L9', subtraction, take_away_base_ones, Info) :-
    strategy_info(subtraction, take_away_base_ones, Info).
explicit_lesson_strategy('IM-G3-U3-L9', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
explicit_lesson_strategy('IM-G3-U3-L9', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_misconception('IM-G3-U3-L9', Operation, share_smaller_into_larger, Info) :-
    misconception_registry_entry(share_smaller_into_larger, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_smaller_into_larger, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G3-U3-L9', Operation, minus_as_plus, Info) :-
    misconception_registry_entry(minus_as_plus, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(minus_as_plus, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U3-L9', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit3/lesson9.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G3-U4-L1', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit4/lesson1.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U4-L10', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U4-L10', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit4/lesson10.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U4-L11', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_misconception('IM-G3-U4-L11', Operation, division_commutative, Info) :-
    misconception_registry_entry(division_commutative, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(division_commutative, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G3-U4-L11', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U4-L11', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit4/lesson11.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U4-L12', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-G3-U4-L12', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G3-U4-L12', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
explicit_lesson_misconception('IM-G3-U4-L12', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U4-L12', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit4/lesson12.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U4-L13', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G3-U4-L13', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
explicit_lesson_strategy('IM-G3-U4-L13', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G3-U4-L13', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
explicit_lesson_misconception('IM-G3-U4-L13', Operation, add_instead_of_multiply, Info) :-
    misconception_registry_entry(add_instead_of_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_multiply, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U4-L13', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit4/lesson13.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U4-L14', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G3-U4-L14', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
explicit_lesson_strategy('IM-G3-U4-L14', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G3-U4-L14', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U4-L14', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit4/lesson14.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U4-L15', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G3-U4-L15', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G3-U4-L15', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
explicit_lesson_misconception('IM-G3-U4-L15', Operation, share_smaller_into_larger, Info) :-
    misconception_registry_entry(share_smaller_into_larger, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_smaller_into_larger, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U4-L15', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit4/lesson15.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U4-L16', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-G3-U4-L16', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G3-U4-L16', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G3-U4-L16', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
explicit_lesson_strategy('IM-G3-U4-L16', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_misconception('IM-G3-U4-L16', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U4-L16', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit4/lesson16.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U4-L17', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U4-L17', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit4/lesson17.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U4-L18', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G3-U4-L18', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G3-U4-L18', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G3-U4-L18', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
explicit_lesson_strategy('IM-G3-U4-L18', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G3-U4-L18', division, share_into_divisor_groups, Info) :-
    strategy_info(division, share_into_divisor_groups, Info).
explicit_lesson_strategy('IM-G3-U4-L18', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
explicit_lesson_misconception('IM-G3-U4-L18', Operation, share_smaller_into_larger, Info) :-
    misconception_registry_entry(share_smaller_into_larger, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_smaller_into_larger, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G3-U4-L18', Operation, adjust_dividend_for_division, Info) :-
    misconception_registry_entry(adjust_dividend_for_division, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(adjust_dividend_for_division, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G3-U4-L18', Operation, divide_larger_by_smaller, Info) :-
    misconception_registry_entry(divide_larger_by_smaller, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_larger_by_smaller, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G3-U4-L18', Operation, adjust_to_make_smaller, Info) :-
    misconception_registry_entry(adjust_to_make_smaller, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(adjust_to_make_smaller, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G3-U4-L18', Operation, share_into_divisor_groups, Info) :-
    misconception_registry_entry(share_into_divisor_groups, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_into_divisor_groups, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U4-L18', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit4/lesson18.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U4-L19', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G3-U4-L19', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
explicit_lesson_strategy('IM-G3-U4-L19', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G3-U4-L19', division, share_into_divisor_groups, Info) :-
    strategy_info(division, share_into_divisor_groups, Info).
explicit_lesson_strategy('IM-G3-U4-L19', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
explicit_lesson_misconception('IM-G3-U4-L19', Operation, share_into_divisor_groups, Info) :-
    misconception_registry_entry(share_into_divisor_groups, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_into_divisor_groups, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U4-L19', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit4/lesson19.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U4-L2', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G3-U4-L2', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U4-L2', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit4/lesson2.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U4-L20', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G3-U4-L20', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G3-U4-L20', division, share_into_divisor_groups, Info) :-
    strategy_info(division, share_into_divisor_groups, Info).
explicit_lesson_strategy('IM-G3-U4-L20', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
explicit_lesson_misconception('IM-G3-U4-L20', Operation, double_first_add_one, Info) :-
    misconception_registry_entry(double_first_add_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(double_first_add_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G3-U4-L20', Operation, share_into_divisor_groups, Info) :-
    misconception_registry_entry(share_into_divisor_groups, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_into_divisor_groups, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U4-L20', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit4/lesson20.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U4-L21', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G3-U4-L21', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G3-U4-L21', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U4-L21', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit4/lesson21.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U4-L22', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G3-U4-L22', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U4-L22', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit4/lesson22.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U4-L3', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G3-U4-L3', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
explicit_lesson_misconception('IM-G3-U4-L3', Operation, division_story_as_multiplication, Info) :-
    misconception_registry_entry(division_story_as_multiplication, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(division_story_as_multiplication, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U4-L3', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit4/lesson3.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U4-L4', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G3-U4-L4', division, share_into_divisor_groups, Info) :-
    strategy_info(division, share_into_divisor_groups, Info).
explicit_lesson_strategy('IM-G3-U4-L4', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
explicit_lesson_misconception('IM-G3-U4-L4', Operation, add_instead_of_multiply, Info) :-
    misconception_registry_entry(add_instead_of_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_multiply, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G3-U4-L4', Operation, difference_interpreted_as_sum, Info) :-
    misconception_registry_entry(difference_interpreted_as_sum, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(difference_interpreted_as_sum, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G3-U4-L4', Operation, share_into_divisor_groups, Info) :-
    misconception_registry_entry(share_into_divisor_groups, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_into_divisor_groups, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U4-L4', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit4/lesson4.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U4-L5', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G3-U4-L5', division, share_into_divisor_groups, Info) :-
    strategy_info(division, share_into_divisor_groups, Info).
explicit_lesson_strategy('IM-G3-U4-L5', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
explicit_lesson_misconception('IM-G3-U4-L5', Operation, share_into_divisor_groups, Info) :-
    misconception_registry_entry(share_into_divisor_groups, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_into_divisor_groups, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U4-L5', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit4/lesson5.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U4-L6', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G3-U4-L6', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U4-L6', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit4/lesson6.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U4-L7', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G3-U4-L7', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G3-U4-L7', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U4-L7', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit4/lesson7.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U4-L8', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G3-U4-L8', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G3-U4-L8', multiplication, multiplication_fact_retrieval, Info) :-
    strategy_info(multiplication, multiplication_fact_retrieval, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U4-L8', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit4/lesson8.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U4-L9', subtraction, smaller_from_larger_in_column, Info) :-
    strategy_info(subtraction, smaller_from_larger_in_column, Info).
explicit_lesson_strategy('IM-G3-U4-L9', multiplication, multiplication_fact_retrieval, Info) :-
    strategy_info(multiplication, multiplication_fact_retrieval, Info).
explicit_lesson_misconception('IM-G3-U4-L9', Operation, double_first_add_one, Info) :-
    misconception_registry_entry(double_first_add_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(double_first_add_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G3-U4-L9', Operation, smaller_from_larger_each_column, Info) :-
    misconception_registry_entry(smaller_from_larger_each_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(smaller_from_larger_each_column, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G3-U4-L9', Operation, smaller_from_larger_in_column, Info) :-
    misconception_registry_entry(smaller_from_larger_in_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(smaller_from_larger_in_column, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U4-L9', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit4/lesson9.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U5-L1', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U5-L1', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit5/lesson1.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G3-U5-L10', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit5/lesson10.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U5-L11', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G3-U5-L11', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_misconception('IM-G3-U5-L11', Operation, share_smaller_into_larger, Info) :-
    misconception_registry_entry(share_smaller_into_larger, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_smaller_into_larger, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G3-U5-L11', Operation, whole_as_unit_fraction, Info) :-
    misconception_registry_entry(whole_as_unit_fraction, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(whole_as_unit_fraction, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U5-L11', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit5/lesson11.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U5-L12', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G3-U5-L12', fraction, co_denominator_count_on_from_larger, Info) :-
    strategy_info(fraction, co_denominator_count_on_from_larger, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U5-L12', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit5/lesson12.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U5-L13', fraction, co_denominator_count_on_from_larger, Info) :-
    strategy_info(fraction, co_denominator_count_on_from_larger, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U5-L13', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit5/lesson13.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U5-L14', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G3-U5-L14', fraction, co_denominator_count_on_from_larger, Info) :-
    strategy_info(fraction, co_denominator_count_on_from_larger, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U5-L14', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit5/lesson14.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G3-U5-L15', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit5/lesson15.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U5-L16', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U5-L16', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit5/lesson16.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U5-L17', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U5-L17', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit5/lesson17.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U5-L18', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U5-L18', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit5/lesson18.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U5-L2', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G3-U5-L2', fraction, unit_fraction_iteration, Info) :-
    strategy_info(fraction, unit_fraction_iteration, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U5-L2', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit5/lesson2.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U5-L3', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G3-U5-L3', fraction, unit_fraction_iteration, Info) :-
    strategy_info(fraction, unit_fraction_iteration, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U5-L3', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit5/lesson3.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U5-L4', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-G3-U5-L4', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G3-U5-L4', subtraction, answer_as_endpoint_count_up, Info) :-
    strategy_info(subtraction, answer_as_endpoint_count_up, Info).
explicit_lesson_strategy('IM-G3-U5-L4', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G3-U5-L4', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G3-U5-L4', fraction, unit_fraction_iteration, Info) :-
    strategy_info(fraction, unit_fraction_iteration, Info).
explicit_lesson_misconception('IM-G3-U5-L4', Operation, whole_as_unit_fraction, Info) :-
    misconception_registry_entry(whole_as_unit_fraction, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(whole_as_unit_fraction, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G3-U5-L4', Operation, answer_as_endpoint_count_up, Info) :-
    misconception_registry_entry(answer_as_endpoint_count_up, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(answer_as_endpoint_count_up, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G3-U5-L4', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U5-L4', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit5/lesson4.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U5-L5', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G3-U5-L5', fraction, unit_fraction_iteration, Info) :-
    strategy_info(fraction, unit_fraction_iteration, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U5-L5', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit5/lesson5.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U5-L6', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G3-U5-L6', fraction, unit_fraction_iteration, Info) :-
    strategy_info(fraction, unit_fraction_iteration, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U5-L6', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit5/lesson6.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U5-L7', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U5-L7', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit5/lesson7.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U5-L8', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G3-U5-L8', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_strategy('IM-G3-U5-L8', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G3-U5-L8', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G3-U5-L8', fraction, unit_fraction_iteration, Info) :-
    strategy_info(fraction, unit_fraction_iteration, Info).
explicit_lesson_misconception('IM-G3-U5-L8', Operation, count_on_off_by_one, Info) :-
    misconception_registry_entry(count_on_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_on_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G3-U5-L8', Operation, fraction_of_as_division, Info) :-
    misconception_registry_entry(fraction_of_as_division, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(fraction_of_as_division, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G3-U5-L8', Operation, divide_by_half_as_by_two, Info) :-
    misconception_registry_entry(divide_by_half_as_by_two, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_by_half_as_by_two, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G3-U5-L8', Operation, whole_as_unit_fraction, Info) :-
    misconception_registry_entry(whole_as_unit_fraction, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(whole_as_unit_fraction, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U5-L8', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit5/lesson8.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U5-L9', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G3-U5-L9', fraction, unit_fraction_iteration, Info) :-
    strategy_info(fraction, unit_fraction_iteration, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U5-L9', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit5/lesson9.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G3-U6-L1', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit6/lesson1.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G3-U6-L10', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit6/lesson10.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G3-U6-L11', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit6/lesson11.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G3-U6-L12', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit6/lesson12.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G3-U6-L13', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit6/lesson13.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U6-L14', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_misconception('IM-G3-U6-L14', Operation, add_instead_of_multiply, Info) :-
    misconception_registry_entry(add_instead_of_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_multiply, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U6-L14', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit6/lesson14.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U6-L15', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G3-U6-L15', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U6-L15', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit6/lesson15.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G3-U6-L16', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit6/lesson16.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G3-U6-L2', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit6/lesson2.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G3-U6-L3', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit6/lesson3.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G3-U6-L4', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit6/lesson4.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U6-L5', addition, column_addition_with_carrying, Info) :-
    strategy_info(addition, column_addition_with_carrying, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U6-L5', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit6/lesson5.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G3-U6-L6', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit6/lesson6.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G3-U6-L7', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit6/lesson7.md'), Path, [access(read)]).

% IM-G3-U6-L8 cool-down "Measure in Liters" (E343 teacher-guide PDF p20): the guide
% attests the volume-scale overcount -- "Students say the volume is 2 liters or 4 liters
% in the first container and 1 liter or 2 liters in the second container" -- against the
% productive liquid_volume_scale_reading already attached to this lesson. The deformation
% liquid_volume_count_marks_not_intervals has no misconception_registry_entry, so it
% licenses through the strategy route (action_role reclassifies the deformation half as
% role=deformation), matching the grade_4 IM-G4-U5-L3 pattern.
explicit_lesson_strategy('IM-G3-U6-L8', measurement, liquid_volume_count_marks_not_intervals, Info) :-
    strategy_info(measurement, liquid_volume_count_marks_not_intervals, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U6-L8', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit6/lesson8.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G3-U6-L9', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit6/lesson9.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G3-U7-L1', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit7/lesson1.md'), Path, [access(read)]).

explicit_lesson_misconception('IM-G3-U7-L10', Operation, double_first_add_one, Info) :-
    misconception_registry_entry(double_first_add_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(double_first_add_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G3-U7-L10', Operation, divide_by_half_as_by_two, Info) :-
    misconception_registry_entry(divide_by_half_as_by_two, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_by_half_as_by_two, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U7-L10', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit7/lesson10.md'), Path, [access(read)]).

explicit_lesson_misconception('IM-G3-U7-L11', Operation, add_instead_of_multiply, Info) :-
    misconception_registry_entry(add_instead_of_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_multiply, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G3-U7-L11', Operation, double_first_add_one, Info) :-
    misconception_registry_entry(double_first_add_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(double_first_add_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G3-U7-L11', Operation, divide_by_half_as_by_two, Info) :-
    misconception_registry_entry(divide_by_half_as_by_two, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_by_half_as_by_two, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U7-L11', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit7/lesson11.md'), Path, [access(read)]).

explicit_lesson_misconception('IM-G3-U7-L12', Operation, add_instead_of_multiply, Info) :-
    misconception_registry_entry(add_instead_of_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_multiply, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G3-U7-L12', Operation, double_first_add_one, Info) :-
    misconception_registry_entry(double_first_add_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(double_first_add_one, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U7-L12', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit7/lesson12.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G3-U7-L13', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit7/lesson13.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G3-U7-L14', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit7/lesson14.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G3-U7-L15', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit7/lesson15.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U7-L2', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G3-U7-L2', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G3-U7-L2', division, measure_groups_of_size, Info) :-
    strategy_info(division, measure_groups_of_size, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U7-L2', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit7/lesson2.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U7-L3', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G3-U7-L3', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G3-U7-L3', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_strategy('IM-G3-U7-L3', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_misconception('IM-G3-U7-L3', Operation, count_on_off_by_one, Info) :-
    misconception_registry_entry(count_on_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_on_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U7-L3', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit7/lesson3.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G3-U7-L4', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit7/lesson4.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U7-L5', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U7-L5', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit7/lesson5.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U7-L6', geometry, polygon_perimeter_boundary_accumulation, Info) :-
    geometry_strategy_info(perimeter_distance_around, polygon_perimeter_boundary_accumulation, Info).
explicit_lesson_misconception('IM-G3-U7-L6', geometry, perimeter_incomplete_traversal, Info) :-
    geometry_misconception_info(perimeter_distance_around,
                                polygon_perimeter_boundary_accumulation,
                                perimeter_incomplete_traversal,
                                Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U7-L6', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit7/lesson6.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U7-L7', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G3-U7-L7', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U7-L7', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit7/lesson7.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U7-L8', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_misconception('IM-G3-U7-L8', Operation, add_instead_of_multiply, Info) :-
    misconception_registry_entry(add_instead_of_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_multiply, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G3-U7-L8', Operation, double_first_add_one, Info) :-
    misconception_registry_entry(double_first_add_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(double_first_add_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G3-U7-L8', Operation, division_always_smaller, Info) :-
    misconception_registry_entry(division_always_smaller, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(division_always_smaller, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U7-L8', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit7/lesson8.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G3-U7-L9', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit7/lesson9.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U8-L1', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U8-L1', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit8/lesson1.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U8-L10', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G3-U8-L10', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U8-L10', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit8/lesson10.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U8-L11', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G3-U8-L11', division, share_into_divisor_groups, Info) :-
    strategy_info(division, share_into_divisor_groups, Info).
explicit_lesson_misconception('IM-G3-U8-L11', Operation, divide_by_half_as_by_two, Info) :-
    misconception_registry_entry(divide_by_half_as_by_two, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_by_half_as_by_two, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G3-U8-L11', Operation, share_into_divisor_groups, Info) :-
    misconception_registry_entry(share_into_divisor_groups, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_into_divisor_groups, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U8-L11', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit8/lesson11.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G3-U8-L12', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit8/lesson12.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U8-L13', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G3-U8-L13', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U8-L13', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit8/lesson13.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G3-U8-L14', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit8/lesson14.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U8-L15', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U8-L15', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit8/lesson15.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U8-L2', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G3-U8-L2', fraction, unit_fraction_iteration, Info) :-
    strategy_info(fraction, unit_fraction_iteration, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U8-L2', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit8/lesson2.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G3-U8-L3', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit8/lesson3.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G3-U8-L4', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit8/lesson4.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G3-U8-L5', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit8/lesson5.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G3-U8-L6', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit8/lesson6.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G3-U8-L7', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit8/lesson7.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U8-L8', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G3-U8-L8', multiplication, multiplication_fact_retrieval, Info) :-
    strategy_info(multiplication, multiplication_fact_retrieval, Info).
explicit_lesson_misconception('IM-G3-U8-L8', Operation, divide_because_smaller_expected, Info) :-
    misconception_registry_entry(divide_because_smaller_expected, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_because_smaller_expected, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U8-L8', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit8/lesson8.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G3-U8-L9', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G3-U8-L9', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G3-U8-L9', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G3-U8-L9', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade3/unit8/lesson9.md'), Path, [access(read)]).

% Source-attested deformation license (2026-07-11 license expansion).
% The teacher guide's anticipated-error prose licenses a registered deformation;
% the paired reviewed_task_instances entry supplies the operands and source line.
% IM-G3-U3-L9 guide: "it is common for students to subtract the smaller digit".
explicit_lesson_misconception('IM-G3-U3-L9', Operation, smaller_from_larger_in_column, Info) :-
    misconception_registry_entry(smaller_from_larger_in_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(smaller_from_larger_in_column, Citation, Commitment, EntitlementLacked, [], Info).
