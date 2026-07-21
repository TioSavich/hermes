% curriculum/im/grade_1.pl - Strategy/misconception facts for grade 1
:- multifile explicit_lesson_strategy/4.
:- discontiguous explicit_lesson_strategy/4.
:- multifile explicit_lesson_misconception/4.
:- discontiguous explicit_lesson_misconception/4.
:- multifile text_interpreter:explicit_lesson_text_source/2.
:- discontiguous text_interpreter:explicit_lesson_text_source/2.

explicit_lesson_strategy('IM-G1-U1-L1', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U1-L1', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-G1-U1-L1', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_misconception('IM-G1-U1-L1', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U1-L1', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit1/lesson1.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U1-L10', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G1-U1-L10', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G1-U1-L10', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G1-U1-L10', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G1-U1-L10', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_misconception('IM-G1-U1-L10', Operation, count_back_off_by_one, Info) :-
    misconception_registry_entry(count_back_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_back_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G1-U1-L10', Operation, count_on_off_by_one, Info) :-
    misconception_registry_entry(count_on_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_on_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U1-L10', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit1/lesson10.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G1-U1-L11', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit1/lesson11.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G1-U1-L12', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit1/lesson12.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U1-L13', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_misconception('IM-G1-U1-L13', Operation, minus_as_plus, Info) :-
    misconception_registry_entry(minus_as_plus, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(minus_as_plus, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G1-U1-L13', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U1-L13', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit1/lesson13.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U1-L14', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U1-L14', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_misconception('IM-G1-U1-L14', Operation, minus_as_plus, Info) :-
    misconception_registry_entry(minus_as_plus, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(minus_as_plus, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U1-L14', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit1/lesson14.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G1-U1-L15', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit1/lesson15.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U1-L2', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U1-L2', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-G1-U1-L2', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_misconception('IM-G1-U1-L2', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U1-L2', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit1/lesson2.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U1-L3', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U1-L3', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-G1-U1-L3', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G1-U1-L3', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_misconception('IM-G1-U1-L3', Operation, count_on_off_by_one, Info) :-
    misconception_registry_entry(count_on_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_on_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G1-U1-L3', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U1-L3', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit1/lesson3.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U1-L4', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-G1-U1-L4', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_misconception('IM-G1-U1-L4', Operation, count_back_off_by_one, Info) :-
    misconception_registry_entry(count_back_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_back_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G1-U1-L4', Operation, count_on_off_by_one, Info) :-
    misconception_registry_entry(count_on_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_on_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G1-U1-L4', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U1-L4', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit1/lesson4.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U1-L5', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U1-L5', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-G1-U1-L5', addition, known_fact_retrieval, Info) :-
    strategy_info(addition, known_fact_retrieval, Info).
explicit_lesson_strategy('IM-G1-U1-L5', addition, count_all_instead_of_known_fact, Info) :-
    strategy_info(addition, count_all_instead_of_known_fact, Info).
explicit_lesson_strategy('IM-G1-U1-L5', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_misconception('IM-G1-U1-L5', Operation, count_back_off_by_one, Info) :-
    misconception_registry_entry(count_back_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_back_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G1-U1-L5', Operation, count_on_off_by_one, Info) :-
    misconception_registry_entry(count_on_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_on_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G1-U1-L5', Operation, count_all_instead_of_known_fact, Info) :-
    misconception_registry_entry(count_all_instead_of_known_fact, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_instead_of_known_fact, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G1-U1-L5', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U1-L5', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit1/lesson5.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U1-L6', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U1-L6', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G1-U1-L6', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G1-U1-L6', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_misconception('IM-G1-U1-L6', Operation, count_back_off_by_one, Info) :-
    misconception_registry_entry(count_back_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_back_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G1-U1-L6', Operation, count_on_off_by_one, Info) :-
    misconception_registry_entry(count_on_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_on_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U1-L6', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit1/lesson6.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G1-U1-L7', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit1/lesson7.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G1-U1-L8', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit1/lesson8.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U1-L9', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U1-L9', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_misconception('IM-G1-U1-L9', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U1-L9', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit1/lesson9.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U2-L1', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_misconception('IM-G1-U2-L1', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U2-L1', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit2/lesson1.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U2-L10', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U2-L10', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U2-L10', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit2/lesson10.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U2-L11', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G1-U2-L11', subtraction, compare_by_matching_difference, Info) :-
    strategy_info(subtraction, compare_by_matching_difference, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U2-L11', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit2/lesson11.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U2-L12', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U2-L12', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_strategy('IM-G1-U2-L12', subtraction, compare_by_matching_difference, Info) :-
    strategy_info(subtraction, compare_by_matching_difference, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U2-L12', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit2/lesson12.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U2-L13', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U2-L13', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_strategy('IM-G1-U2-L13', subtraction, compare_by_matching_difference, Info) :-
    strategy_info(subtraction, compare_by_matching_difference, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U2-L13', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit2/lesson13.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U2-L14', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U2-L14', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_strategy('IM-G1-U2-L14', subtraction, compare_by_matching_difference, Info) :-
    strategy_info(subtraction, compare_by_matching_difference, Info).
explicit_lesson_misconception('IM-G1-U2-L14', Operation, count_back_off_by_one, Info) :-
    misconception_registry_entry(count_back_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_back_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G1-U2-L14', Operation, count_on_off_by_one, Info) :-
    misconception_registry_entry(count_on_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_on_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U2-L14', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit2/lesson14.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U2-L15', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U2-L15', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_strategy('IM-G1-U2-L15', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U2-L15', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit2/lesson15.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U2-L16', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U2-L16', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U2-L16', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit2/lesson16.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U2-L17', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_strategy('IM-G1-U2-L17', subtraction, compare_by_matching_difference, Info) :-
    strategy_info(subtraction, compare_by_matching_difference, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U2-L17', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit2/lesson17.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U2-L18', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U2-L18', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_strategy('IM-G1-U2-L18', subtraction, compare_by_matching_difference, Info) :-
    strategy_info(subtraction, compare_by_matching_difference, Info).
explicit_lesson_strategy('IM-G1-U2-L18', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U2-L18', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit2/lesson18.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U2-L19', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G1-U2-L19', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G1-U2-L19', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_strategy('IM-G1-U2-L19', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U2-L19', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit2/lesson19.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U2-L2', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U2-L2', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_misconception('IM-G1-U2-L2', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U2-L2', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit2/lesson2.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U2-L20', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U2-L20', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_strategy('IM-G1-U2-L20', subtraction, add_instead_of_subtract_column, Info) :-
    strategy_info(subtraction, add_instead_of_subtract_column, Info).
explicit_lesson_strategy('IM-G1-U2-L20', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_misconception('IM-G1-U2-L20', Operation, add_instead_of_subtract_column, Info) :-
    misconception_registry_entry(add_instead_of_subtract_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_subtract_column, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U2-L20', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit2/lesson20.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U2-L21', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G1-U2-L21', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G1-U2-L21', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G1-U2-L21', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G1-U2-L21', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_strategy('IM-G1-U2-L21', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U2-L21', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit2/lesson21.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U2-L22', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_misconception('IM-G1-U2-L22', Operation, minus_as_plus, Info) :-
    misconception_registry_entry(minus_as_plus, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(minus_as_plus, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U2-L22', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit2/lesson22.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G1-U2-L23', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit2/lesson23.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U2-L3', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U2-L3', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U2-L3', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit2/lesson3.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U2-L4', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U2-L4', addition, known_fact_retrieval, Info) :-
    strategy_info(addition, known_fact_retrieval, Info).
explicit_lesson_strategy('IM-G1-U2-L4', addition, count_all_instead_of_known_fact, Info) :-
    strategy_info(addition, count_all_instead_of_known_fact, Info).
explicit_lesson_strategy('IM-G1-U2-L4', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_strategy('IM-G1-U2-L4', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_misconception('IM-G1-U2-L4', Operation, count_all_instead_of_known_fact, Info) :-
    misconception_registry_entry(count_all_instead_of_known_fact, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_instead_of_known_fact, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U2-L4', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit2/lesson4.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U2-L5', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U2-L5', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit2/lesson5.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U2-L6', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U2-L6', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_misconception('IM-G1-U2-L6', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U2-L6', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit2/lesson6.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U2-L7', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-G1-U2-L7', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G1-U2-L7', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G1-U2-L7', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_misconception('IM-G1-U2-L7', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U2-L7', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit2/lesson7.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U2-L8', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U2-L8', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-G1-U2-L8', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G1-U2-L8', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_strategy('IM-G1-U2-L8', subtraction, add_instead_of_subtract_column, Info) :-
    strategy_info(subtraction, add_instead_of_subtract_column, Info).
explicit_lesson_misconception('IM-G1-U2-L8', Operation, add_instead_of_subtract_column, Info) :-
    misconception_registry_entry(add_instead_of_subtract_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_subtract_column, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G1-U2-L8', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U2-L8', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit2/lesson8.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U2-L9', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U2-L9', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U2-L9', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit2/lesson9.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U3-L1', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U3-L1', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_misconception('IM-G1-U3-L1', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U3-L1', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit3/lesson1.md'), Path, [access(read)]).

explicit_lesson_misconception('IM-G1-U3-L10', Operation, double_first_add_one, Info) :-
    misconception_registry_entry(double_first_add_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(double_first_add_one, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U3-L10', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit3/lesson10.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U3-L11', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U3-L11', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-G1-U3-L11', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G1-U3-L11', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_misconception('IM-G1-U3-L11', Operation, double_first_add_one, Info) :-
    misconception_registry_entry(double_first_add_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(double_first_add_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G1-U3-L11', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U3-L11', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit3/lesson11.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U3-L12', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U3-L12', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-G1-U3-L12', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G1-U3-L12', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G1-U3-L12', subtraction, take_away_base_ones, Info) :-
    strategy_info(subtraction, take_away_base_ones, Info).
explicit_lesson_strategy('IM-G1-U3-L12', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
explicit_lesson_misconception('IM-G1-U3-L12', Operation, double_first_add_one, Info) :-
    misconception_registry_entry(double_first_add_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(double_first_add_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G1-U3-L12', Operation, count_on_off_by_one, Info) :-
    misconception_registry_entry(count_on_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_on_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G1-U3-L12', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U3-L12', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit3/lesson12.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U3-L13', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U3-L13', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-G1-U3-L13', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G1-U3-L13', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G1-U3-L13', subtraction, take_away_base_ones, Info) :-
    strategy_info(subtraction, take_away_base_ones, Info).
explicit_lesson_strategy('IM-G1-U3-L13', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
explicit_lesson_misconception('IM-G1-U3-L13', Operation, double_first_add_one, Info) :-
    misconception_registry_entry(double_first_add_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(double_first_add_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G1-U3-L13', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U3-L13', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit3/lesson13.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U3-L14', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U3-L14', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit3/lesson14.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U3-L15', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U3-L15', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-G1-U3-L15', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G1-U3-L15', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G1-U3-L15', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_misconception('IM-G1-U3-L15', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U3-L15', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit3/lesson15.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U3-L16', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G1-U3-L16', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G1-U3-L16', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_misconception('IM-G1-U3-L16', Operation, double_first_add_one, Info) :-
    misconception_registry_entry(double_first_add_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(double_first_add_one, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U3-L16', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit3/lesson16.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U3-L17', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U3-L17', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-G1-U3-L17', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G1-U3-L17', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G1-U3-L17', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G1-U3-L17', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_misconception('IM-G1-U3-L17', Operation, double_first_add_one, Info) :-
    misconception_registry_entry(double_first_add_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(double_first_add_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G1-U3-L17', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U3-L17', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit3/lesson17.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U3-L18', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-G1-U3-L18', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G1-U3-L18', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G1-U3-L18', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G1-U3-L18', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_misconception('IM-G1-U3-L18', Operation, double_first_add_one, Info) :-
    misconception_registry_entry(double_first_add_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(double_first_add_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G1-U3-L18', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U3-L18', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit3/lesson18.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U3-L19', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U3-L19', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-G1-U3-L19', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G1-U3-L19', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G1-U3-L19', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G1-U3-L19', addition, known_fact_retrieval, Info) :-
    strategy_info(addition, known_fact_retrieval, Info).
explicit_lesson_misconception('IM-G1-U3-L19', Operation, double_first_add_one, Info) :-
    misconception_registry_entry(double_first_add_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(double_first_add_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G1-U3-L19', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U3-L19', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit3/lesson19.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U3-L2', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U3-L2', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-G1-U3-L2', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_misconception('IM-G1-U3-L2', Operation, share_smaller_into_larger, Info) :-
    misconception_registry_entry(share_smaller_into_larger, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_smaller_into_larger, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G1-U3-L2', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U3-L2', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit3/lesson2.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U3-L20', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U3-L20', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-G1-U3-L20', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G1-U3-L20', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G1-U3-L20', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_misconception('IM-G1-U3-L20', Operation, double_first_add_one, Info) :-
    misconception_registry_entry(double_first_add_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(double_first_add_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G1-U3-L20', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U3-L20', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit3/lesson20.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U3-L21', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U3-L21', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G1-U3-L21', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G1-U3-L21', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U3-L21', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit3/lesson21.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U3-L22', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U3-L22', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G1-U3-L22', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G1-U3-L22', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G1-U3-L22', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_strategy('IM-G1-U3-L22', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
explicit_lesson_misconception('IM-G1-U3-L22', Operation, double_first_add_one, Info) :-
    misconception_registry_entry(double_first_add_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(double_first_add_one, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U3-L22', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit3/lesson22.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U3-L23', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U3-L23', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-G1-U3-L23', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G1-U3-L23', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G1-U3-L23', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G1-U3-L23', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_misconception('IM-G1-U3-L23', Operation, double_first_add_one, Info) :-
    misconception_registry_entry(double_first_add_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(double_first_add_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G1-U3-L23', Operation, count_on_off_by_one, Info) :-
    misconception_registry_entry(count_on_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_on_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G1-U3-L23', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U3-L23', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit3/lesson23.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U3-L24', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U3-L24', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G1-U3-L24', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G1-U3-L24', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U3-L24', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit3/lesson24.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U3-L25', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U3-L25', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-G1-U3-L25', subtraction, add_instead_of_subtract_column, Info) :-
    strategy_info(subtraction, add_instead_of_subtract_column, Info).
explicit_lesson_misconception('IM-G1-U3-L25', Operation, double_first_add_one, Info) :-
    misconception_registry_entry(double_first_add_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(double_first_add_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G1-U3-L25', Operation, add_instead_of_subtract_column, Info) :-
    misconception_registry_entry(add_instead_of_subtract_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_subtract_column, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G1-U3-L25', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U3-L25', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit3/lesson25.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U3-L26', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U3-L26', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G1-U3-L26', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_misconception('IM-G1-U3-L26', Operation, double_first_add_one, Info) :-
    misconception_registry_entry(double_first_add_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(double_first_add_one, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U3-L26', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit3/lesson26.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U3-L27', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U3-L27', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G1-U3-L27', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G1-U3-L27', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_misconception('IM-G1-U3-L27', Operation, flip_subtraction_order, Info) :-
    misconception_registry_entry(flip_subtraction_order, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(flip_subtraction_order, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U3-L27', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit3/lesson27.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G1-U3-L28', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit3/lesson28.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U3-L3', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G1-U3-L3', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U3-L3', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit3/lesson3.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U3-L4', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U3-L4', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G1-U3-L4', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G1-U3-L4', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G1-U3-L4', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_misconception('IM-G1-U3-L4', Operation, count_on_off_by_one, Info) :-
    misconception_registry_entry(count_on_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_on_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U3-L4', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit3/lesson4.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U3-L5', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U3-L5', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit3/lesson5.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U3-L6', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U3-L6', addition, known_fact_retrieval, Info) :-
    strategy_info(addition, known_fact_retrieval, Info).
explicit_lesson_strategy('IM-G1-U3-L6', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U3-L6', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit3/lesson6.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U3-L7', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U3-L7', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U3-L7', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit3/lesson7.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U3-L8', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U3-L8', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-G1-U3-L8', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G1-U3-L8', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_strategy('IM-G1-U3-L8', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
explicit_lesson_misconception('IM-G1-U3-L8', Operation, count_on_off_by_one, Info) :-
    misconception_registry_entry(count_on_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_on_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G1-U3-L8', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U3-L8', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit3/lesson8.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U3-L9', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_misconception('IM-G1-U3-L9', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U3-L9', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit3/lesson9.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U4-L1', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U4-L1', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G1-U4-L1', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G1-U4-L1', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G1-U4-L1', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U4-L1', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit4/lesson1.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U4-L10', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G1-U4-L10', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_misconception('IM-G1-U4-L10', Operation, share_smaller_into_larger, Info) :-
    misconception_registry_entry(share_smaller_into_larger, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_smaller_into_larger, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G1-U4-L10', Operation, always_larger_into_smaller, Info) :-
    misconception_registry_entry(always_larger_into_smaller, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(always_larger_into_smaller, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U4-L10', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit4/lesson10.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U4-L11', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U4-L11', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-G1-U4-L11', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G1-U4-L11', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_misconception('IM-G1-U4-L11', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U4-L11', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit4/lesson11.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U4-L12', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U4-L12', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G1-U4-L12', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G1-U4-L12', subtraction, take_away_base_ones, Info) :-
    strategy_info(subtraction, take_away_base_ones, Info).
explicit_lesson_misconception('IM-G1-U4-L12', Operation, always_larger_into_smaller, Info) :-
    misconception_registry_entry(always_larger_into_smaller, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(always_larger_into_smaller, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U4-L12', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit4/lesson12.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U4-L13', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G1-U4-L13', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G1-U4-L13', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_misconception('IM-G1-U4-L13', Operation, count_on_off_by_one, Info) :-
    misconception_registry_entry(count_on_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_on_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U4-L13', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit4/lesson13.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U4-L14', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G1-U4-L14', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
% IM-G1-U4-L14 Activity 2 "Elena and Noah Compare Numbers" (E343 teacher-guide PDF pp6-7):
% the guide attests the ones/tens digit-substitution error -- "Noah says 39 is greater
% than 41 because it has a 9 and 9 is the greatest number" with the corrective "9 is the
% greatest digit, but it is in the ones place." The productive place_value_comparison is
% already attached; the deformation compare_ones_digits_only has no
% misconception_registry_entry, so it licenses through the strategy route (action_role
% reclassifies it as role=deformation).
explicit_lesson_strategy('IM-G1-U4-L14', counting, compare_ones_digits_only, Info) :-
    strategy_info(counting, compare_ones_digits_only, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U4-L14', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit4/lesson14.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U4-L15', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G1-U4-L15', subtraction, take_away_base_ones, Info) :-
    strategy_info(subtraction, take_away_base_ones, Info).
explicit_lesson_strategy('IM-G1-U4-L15', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_misconception('IM-G1-U4-L15', Operation, share_smaller_into_larger, Info) :-
    misconception_registry_entry(share_smaller_into_larger, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_smaller_into_larger, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G1-U4-L15', Operation, always_larger_into_smaller, Info) :-
    misconception_registry_entry(always_larger_into_smaller, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(always_larger_into_smaller, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U4-L15', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit4/lesson15.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U4-L16', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G1-U4-L16', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U4-L16', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit4/lesson16.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U4-L17', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G1-U4-L17', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U4-L17', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit4/lesson17.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U4-L18', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G1-U4-L18', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U4-L18', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit4/lesson18.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U4-L19', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U4-L19', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G1-U4-L19', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U4-L19', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit4/lesson19.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U4-L2', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U4-L2', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit4/lesson2.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U4-L20', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G1-U4-L20', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G1-U4-L20', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U4-L20', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit4/lesson20.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U4-L21', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G1-U4-L21', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
explicit_lesson_strategy('IM-G1-U4-L21', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U4-L21', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit4/lesson21.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U4-L22', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G1-U4-L22', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U4-L22', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit4/lesson22.md'), Path, [access(read)]).

explicit_lesson_misconception('IM-G1-U4-L23', Operation, count_on_off_by_one, Info) :-
    misconception_registry_entry(count_on_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_on_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U4-L23', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit4/lesson23.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U4-L3', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U4-L3', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U4-L3', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit4/lesson3.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U4-L4', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U4-L4', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G1-U4-L4', subtraction, take_away_base_ones, Info) :-
    strategy_info(subtraction, take_away_base_ones, Info).
explicit_lesson_misconception('IM-G1-U4-L4', Operation, count_back_off_by_one, Info) :-
    misconception_registry_entry(count_back_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_back_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G1-U4-L4', Operation, double_first_add_one, Info) :-
    misconception_registry_entry(double_first_add_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(double_first_add_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G1-U4-L4', Operation, count_on_off_by_one, Info) :-
    misconception_registry_entry(count_on_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_on_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G1-U4-L4', Operation, minus_as_plus, Info) :-
    misconception_registry_entry(minus_as_plus, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(minus_as_plus, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U4-L4', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit4/lesson4.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U4-L5', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U4-L5', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit4/lesson5.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U4-L6', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U4-L6', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-G1-U4-L6', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G1-U4-L6', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_misconception('IM-G1-U4-L6', Operation, count_on_off_by_one, Info) :-
    misconception_registry_entry(count_on_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_on_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G1-U4-L6', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U4-L6', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit4/lesson6.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U4-L7', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U4-L7', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_misconception('IM-G1-U4-L7', Operation, count_on_off_by_one, Info) :-
    misconception_registry_entry(count_on_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_on_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U4-L7', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit4/lesson7.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U4-L8', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U4-L8', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit4/lesson8.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U4-L9', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_misconception('IM-G1-U4-L9', Operation, count_on_off_by_one, Info) :-
    misconception_registry_entry(count_on_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_on_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U4-L9', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit4/lesson9.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U5-L1', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U5-L1', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G1-U5-L1', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G1-U5-L1', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U5-L1', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit5/lesson1.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U5-L10', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U5-L10', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G1-U5-L10', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
explicit_lesson_misconception('IM-G1-U5-L10', Operation, difference_interpreted_as_sum, Info) :-
    misconception_registry_entry(difference_interpreted_as_sum, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(difference_interpreted_as_sum, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U5-L10', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit5/lesson10.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U5-L11', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G1-U5-L11', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G1-U5-L11', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U5-L11', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit5/lesson11.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U5-L12', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G1-U5-L12', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G1-U5-L12', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G1-U5-L12', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U5-L12', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit5/lesson12.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U5-L13', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U5-L13', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit5/lesson13.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U5-L14', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U5-L14', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit5/lesson14.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U5-L2', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U5-L2', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G1-U5-L2', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G1-U5-L2', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U5-L2', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit5/lesson2.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U5-L3', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U5-L3', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit5/lesson3.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G1-U5-L4', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit5/lesson4.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U5-L5', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U5-L5', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G1-U5-L5', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G1-U5-L5', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G1-U5-L5', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G1-U5-L5', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U5-L5', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit5/lesson5.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U5-L6', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U5-L6', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G1-U5-L6', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G1-U5-L6', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G1-U5-L6', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G1-U5-L6', addition, known_fact_retrieval, Info) :-
    strategy_info(addition, known_fact_retrieval, Info).
explicit_lesson_strategy('IM-G1-U5-L6', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_strategy('IM-G1-U5-L6', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U5-L6', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit5/lesson6.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U5-L7', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U5-L7', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G1-U5-L7', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G1-U5-L7', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G1-U5-L7', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_misconception('IM-G1-U5-L7', Operation, double_first_add_one, Info) :-
    misconception_registry_entry(double_first_add_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(double_first_add_one, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U5-L7', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit5/lesson7.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U5-L8', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U5-L8', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit5/lesson8.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U5-L9', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U5-L9', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-G1-U5-L9', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G1-U5-L9', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G1-U5-L9', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G1-U5-L9', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G1-U5-L9', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
explicit_lesson_misconception('IM-G1-U5-L9', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U5-L9', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit5/lesson9.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G1-U6-L1', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit6/lesson1.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U6-L10', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U6-L10', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit6/lesson10.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U6-L11', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U6-L11', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-G1-U6-L11', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G1-U6-L11', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G1-U6-L11', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_misconception('IM-G1-U6-L11', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U6-L11', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit6/lesson11.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U6-L12', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U6-L12', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G1-U6-L12', subtraction, compare_by_matching_difference, Info) :-
    strategy_info(subtraction, compare_by_matching_difference, Info).
explicit_lesson_misconception('IM-G1-U6-L12', Operation, count_on_off_by_one, Info) :-
    misconception_registry_entry(count_on_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_on_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U6-L12', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit6/lesson12.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U6-L13', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-G1-U6-L13', subtraction, take_away_base_ones, Info) :-
    strategy_info(subtraction, take_away_base_ones, Info).
explicit_lesson_misconception('IM-G1-U6-L13', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U6-L13', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit6/lesson13.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U6-L14', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U6-L14', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit6/lesson14.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G1-U6-L15', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit6/lesson15.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U6-L16', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G1-U6-L16', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U6-L16', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit6/lesson16.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G1-U6-L17', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit6/lesson17.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U6-L2', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G1-U6-L2', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U6-L2', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit6/lesson2.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G1-U6-L3', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit6/lesson3.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U6-L4', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G1-U6-L4', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G1-U6-L4', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U6-L4', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit6/lesson4.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G1-U6-L5', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit6/lesson5.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G1-U6-L6', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit6/lesson6.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G1-U6-L7', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit6/lesson7.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U6-L8', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U6-L8', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U6-L8', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit6/lesson8.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U6-L9', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G1-U6-L9', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U6-L9', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit6/lesson9.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U7-L1', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U7-L1', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit7/lesson1.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G1-U7-L10', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit7/lesson10.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U7-L11', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U7-L11', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_misconception('IM-G1-U7-L11', Operation, share_smaller_into_larger, Info) :-
    misconception_registry_entry(share_smaller_into_larger, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_smaller_into_larger, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G1-U7-L11', Operation, always_larger_into_smaller, Info) :-
    misconception_registry_entry(always_larger_into_smaller, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(always_larger_into_smaller, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U7-L11', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit7/lesson11.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G1-U7-L12', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit7/lesson12.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G1-U7-L13', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit7/lesson13.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U7-L14', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-G1-U7-L14', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G1-U7-L14', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_misconception('IM-G1-U7-L14', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U7-L14', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit7/lesson14.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U7-L15', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U7-L15', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit7/lesson15.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U7-L16', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G1-U7-L16', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G1-U7-L16', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G1-U7-L16', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U7-L16', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit7/lesson16.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G1-U7-L17', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit7/lesson17.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G1-U7-L18', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit7/lesson18.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G1-U7-L2', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit7/lesson2.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G1-U7-L3', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit7/lesson3.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G1-U7-L4', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit7/lesson4.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G1-U7-L5', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit7/lesson5.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U7-L6', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G1-U7-L6', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U7-L6', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit7/lesson6.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G1-U7-L7', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit7/lesson7.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U7-L8', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G1-U7-L8', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G1-U7-L8', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U7-L8', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit7/lesson8.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G1-U7-L9', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit7/lesson9.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U8-L1', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U8-L1', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-G1-U8-L1', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G1-U8-L1', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_misconception('IM-G1-U8-L1', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U8-L1', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit8/lesson1.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U8-L10', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U8-L10', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit8/lesson10.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G1-U8-L2', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit8/lesson2.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U8-L3', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G1-U8-L3', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G1-U8-L3', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G1-U8-L3', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U8-L3', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit8/lesson3.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U8-L4', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U8-L4', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G1-U8-L4', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G1-U8-L4', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U8-L4', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit8/lesson4.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U8-L5', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U8-L5', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G1-U8-L5', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G1-U8-L5', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G1-U8-L5', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U8-L5', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit8/lesson5.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G1-U8-L6', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit8/lesson6.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U8-L7', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G1-U8-L7', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-G1-U8-L7', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G1-U8-L7', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G1-U8-L7', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_misconception('IM-G1-U8-L7', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U8-L7', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit8/lesson7.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U8-L8', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U8-L8', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit8/lesson8.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G1-U8-L9', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G1-U8-L9', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G1-U8-L9', Path) :-
    absolute_file_name(lessons('im_teacher_guides/grade1/unit8/lesson9.md'), Path, [access(read)]).

% Source-attested deformation licenses (2026-07-11 license expansion).
% The teacher guide's anticipated-error prose licenses a registered deformation;
% the paired reviewed_task_instances entry supplies the operands and source line.
% IM-G1-U2-L3 guide: "If students add 6 and 8, consider asking:".
explicit_lesson_misconception('IM-G1-U2-L3', Operation, add_instead_of_subtract_column, Info) :-
    misconception_registry_entry(add_instead_of_subtract_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_subtract_column, Citation, Commitment, EntitlementLacked, [], Info).
% IM-G1-U3-L6 guide: "If students add 3 and 10, consider asking:".
explicit_lesson_misconception('IM-G1-U3-L6', Operation, add_instead_of_subtract_column, Info) :-
    misconception_registry_entry(add_instead_of_subtract_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_subtract_column, Citation, Commitment, EntitlementLacked, [], Info).

