% lessons/im/grade_2.pl - Strategy/misconception facts for grade 2
:- multifile explicit_lesson_strategy/4.
:- discontiguous explicit_lesson_strategy/4.
:- multifile explicit_lesson_misconception/4.
:- discontiguous explicit_lesson_misconception/4.
:- multifile text_interpreter:explicit_lesson_text_source/2.
:- discontiguous text_interpreter:explicit_lesson_text_source/2.

explicit_lesson_strategy('IM-G2-U1-L1', subtraction, smaller_from_larger_in_column, Info) :-
    strategy_info(subtraction, smaller_from_larger_in_column, Info).
explicit_lesson_strategy('IM-G2-U1-L1', subtraction, add_instead_of_subtract_column, Info) :-
    strategy_info(subtraction, add_instead_of_subtract_column, Info).
explicit_lesson_misconception('IM-G2-U1-L1', Operation, smaller_from_larger_each_column, Info) :-
    misconception_registry_entry(smaller_from_larger_each_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(smaller_from_larger_each_column, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G2-U1-L1', Operation, smaller_from_larger_in_column, Info) :-
    misconception_registry_entry(smaller_from_larger_in_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(smaller_from_larger_in_column, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G2-U1-L1', Operation, add_instead_of_subtract_column, Info) :-
    misconception_registry_entry(add_instead_of_subtract_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_subtract_column, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U1-L1', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit1/lesson1.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G2-U1-L10', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit1/lesson10.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U1-L11', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G2-U1-L11', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U1-L11', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit1/lesson11.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G2-U1-L12', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit1/lesson12.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U1-L13', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G2-U1-L13', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G2-U1-L13', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_misconception('IM-G2-U1-L13', Operation, share_smaller_into_larger, Info) :-
    misconception_registry_entry(share_smaller_into_larger, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_smaller_into_larger, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U1-L13', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit1/lesson13.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G2-U1-L14', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit1/lesson14.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U1-L15', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G2-U1-L15', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G2-U1-L15', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G2-U1-L15', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_misconception('IM-G2-U1-L15', Operation, share_smaller_into_larger, Info) :-
    misconception_registry_entry(share_smaller_into_larger, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_smaller_into_larger, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G2-U1-L15', Operation, adjust_to_make_smaller, Info) :-
    misconception_registry_entry(adjust_to_make_smaller, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(adjust_to_make_smaller, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U1-L15', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit1/lesson15.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U1-L16', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G2-U1-L16', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G2-U1-L16', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U1-L16', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit1/lesson16.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U1-L17', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U1-L17', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U1-L17', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit1/lesson17.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U1-L18', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U1-L18', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit1/lesson18.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U1-L2', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G2-U1-L2', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G2-U1-L2', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U1-L2', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G2-U1-L2', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U1-L2', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit1/lesson2.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U1-L3', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G2-U1-L3', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G2-U1-L3', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G2-U1-L3', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U1-L3', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit1/lesson3.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U1-L4', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G2-U1-L4', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-G2-U1-L4', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G2-U1-L4', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G2-U1-L4', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_misconception('IM-G2-U1-L4', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U1-L4', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit1/lesson4.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U1-L5', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G2-U1-L5', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G2-U1-L5', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G2-U1-L5', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U1-L5', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G2-U1-L5', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U1-L5', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit1/lesson5.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G2-U1-L6', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit1/lesson6.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U1-L7', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_misconception('IM-G2-U1-L7', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U1-L7', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit1/lesson7.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G2-U1-L8', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit1/lesson8.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G2-U1-L9', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit1/lesson9.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U2-L1', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G2-U2-L1', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-G2-U2-L1', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U2-L1', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_strategy('IM-G2-U2-L1', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
explicit_lesson_misconception('IM-G2-U2-L1', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U2-L1', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit2/lesson1.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U2-L10', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U2-L10', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G2-U2-L10', subtraction, take_away_base_ones, Info) :-
    strategy_info(subtraction, take_away_base_ones, Info).
explicit_lesson_strategy('IM-G2-U2-L10', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U2-L10', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit2/lesson10.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U2-L11', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G2-U2-L11', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U2-L11', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
explicit_lesson_misconception('IM-G2-U2-L11', Operation, difference_interpreted_as_sum, Info) :-
    misconception_registry_entry(difference_interpreted_as_sum, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(difference_interpreted_as_sum, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U2-L11', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit2/lesson11.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U2-L12', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U2-L12', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_strategy('IM-G2-U2-L12', subtraction, compare_by_matching_difference, Info) :-
    strategy_info(subtraction, compare_by_matching_difference, Info).
explicit_lesson_strategy('IM-G2-U2-L12', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U2-L12', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit2/lesson12.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U2-L13', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_strategy('IM-G2-U2-L13', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U2-L13', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit2/lesson13.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U2-L14', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G2-U2-L14', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G2-U2-L14', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U2-L14', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U2-L14', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit2/lesson14.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U2-L15', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U2-L15', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G2-U2-L15', addition, round_without_adjusting, Info) :-
    strategy_info(addition, round_without_adjusting, Info).
explicit_lesson_strategy('IM-G2-U2-L15', subtraction, add_instead_of_subtract_column, Info) :-
    strategy_info(subtraction, add_instead_of_subtract_column, Info).
explicit_lesson_strategy('IM-G2-U2-L15', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_misconception('IM-G2-U2-L15', Operation, round_without_adjusting, Info) :-
    misconception_registry_entry(round_without_adjusting, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(round_without_adjusting, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G2-U2-L15', Operation, add_instead_of_subtract_column, Info) :-
    misconception_registry_entry(add_instead_of_subtract_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_subtract_column, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U2-L15', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit2/lesson15.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G2-U2-L16', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit2/lesson16.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G2-U2-L17', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit2/lesson17.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U2-L2', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G2-U2-L2', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-G2-U2-L2', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G2-U2-L2', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G2-U2-L2', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U2-L2', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G2-U2-L2', subtraction, take_away_base_ones, Info) :-
    strategy_info(subtraction, take_away_base_ones, Info).
explicit_lesson_strategy('IM-G2-U2-L2', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_strategy('IM-G2-U2-L2', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
explicit_lesson_strategy('IM-G2-U2-L2', subtraction, add_instead_of_subtract_column, Info) :-
    strategy_info(subtraction, add_instead_of_subtract_column, Info).
explicit_lesson_misconception('IM-G2-U2-L2', Operation, add_instead_of_subtract_column, Info) :-
    misconception_registry_entry(add_instead_of_subtract_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_subtract_column, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G2-U2-L2', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U2-L2', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit2/lesson2.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U2-L3', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U2-L3', subtraction, take_away_base_ones, Info) :-
    strategy_info(subtraction, take_away_base_ones, Info).
explicit_lesson_strategy('IM-G2-U2-L3', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_strategy('IM-G2-U2-L3', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
explicit_lesson_misconception('IM-G2-U2-L3', Operation, count_on_off_by_one, Info) :-
    misconception_registry_entry(count_on_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_on_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U2-L3', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit2/lesson3.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U2-L4', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U2-L4', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U2-L4', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit2/lesson4.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U2-L5', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G2-U2-L5', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-G2-U2-L5', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U2-L5', subtraction, take_away_base_ones, Info) :-
    strategy_info(subtraction, take_away_base_ones, Info).
explicit_lesson_strategy('IM-G2-U2-L5', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_strategy('IM-G2-U2-L5', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
explicit_lesson_misconception('IM-G2-U2-L5', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U2-L5', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit2/lesson5.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U2-L6', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U2-L6', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G2-U2-L6', subtraction, take_away_base_ones, Info) :-
    strategy_info(subtraction, take_away_base_ones, Info).
explicit_lesson_strategy('IM-G2-U2-L6', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U2-L6', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit2/lesson6.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U2-L7', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U2-L7', subtraction, take_away_base_ones, Info) :-
    strategy_info(subtraction, take_away_base_ones, Info).
explicit_lesson_strategy('IM-G2-U2-L7', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
explicit_lesson_misconception('IM-G2-U2-L7', Operation, borrow_without_reducing_bases, Info) :-
    misconception_registry_entry(borrow_without_reducing_bases, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(borrow_without_reducing_bases, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U2-L7', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit2/lesson7.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U2-L8', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U2-L8', addition, known_fact_retrieval, Info) :-
    strategy_info(addition, known_fact_retrieval, Info).
explicit_lesson_strategy('IM-G2-U2-L8', subtraction, take_away_base_ones, Info) :-
    strategy_info(subtraction, take_away_base_ones, Info).
explicit_lesson_strategy('IM-G2-U2-L8', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U2-L8', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit2/lesson8.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U2-L9', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G2-U2-L9', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G2-U2-L9', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U2-L9', subtraction, compare_by_matching_difference, Info) :-
    strategy_info(subtraction, compare_by_matching_difference, Info).
explicit_lesson_strategy('IM-G2-U2-L9', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U2-L9', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit2/lesson9.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G2-U3-L1', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit3/lesson1.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U3-L10', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G2-U3-L10', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U3-L10', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit3/lesson10.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U3-L11', subtraction, take_away_base_ones, Info) :-
    strategy_info(subtraction, take_away_base_ones, Info).
explicit_lesson_strategy('IM-G2-U3-L11', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U3-L11', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit3/lesson11.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U3-L12', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U3-L12', subtraction, take_away_base_ones, Info) :-
    strategy_info(subtraction, take_away_base_ones, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U3-L12', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit3/lesson12.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U3-L13', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G2-U3-L13', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G2-U3-L13', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U3-L13', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U3-L13', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit3/lesson13.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G2-U3-L14', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit3/lesson14.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U3-L15', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-G2-U3-L15', division, measure_groups_of_size, Info) :-
    strategy_info(division, measure_groups_of_size, Info).
explicit_lesson_misconception('IM-G2-U3-L15', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U3-L15', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit3/lesson15.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U3-L16', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G2-U3-L16', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G2-U3-L16', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G2-U3-L16', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U3-L16', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit3/lesson16.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U3-L17', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U3-L17', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit3/lesson17.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U3-L18', division, measure_groups_of_size, Info) :-
    strategy_info(division, measure_groups_of_size, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U3-L18', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit3/lesson18.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G2-U3-L2', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit3/lesson2.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U3-L3', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G2-U3-L3', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U3-L3', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_strategy('IM-G2-U3-L3', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U3-L3', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit3/lesson3.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G2-U3-L4', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit3/lesson4.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U3-L5', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G2-U3-L5', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U3-L5', subtraction, take_away_base_ones, Info) :-
    strategy_info(subtraction, take_away_base_ones, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U3-L5', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit3/lesson5.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U3-L6', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U3-L6', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit3/lesson6.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U3-L7', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G2-U3-L7', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U3-L7', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit3/lesson7.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G2-U3-L8', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit3/lesson8.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G2-U3-L9', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit3/lesson9.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G2-U4-L1', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit4/lesson1.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U4-L10', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G2-U4-L10', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G2-U4-L10', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G2-U4-L10', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U4-L10', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U4-L10', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit4/lesson10.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U4-L11', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G2-U4-L11', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G2-U4-L11', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U4-L11', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_strategy('IM-G2-U4-L11', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U4-L11', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit4/lesson11.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U4-L12', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G2-U4-L12', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G2-U4-L12', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U4-L12', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit4/lesson12.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G2-U4-L13', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit4/lesson13.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U4-L14', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U4-L14', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U4-L14', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit4/lesson14.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G2-U4-L15', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit4/lesson15.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U4-L2', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G2-U4-L2', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U4-L2', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit4/lesson2.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U4-L3', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U4-L3', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit4/lesson3.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U4-L4', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U4-L4', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U4-L4', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit4/lesson4.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G2-U4-L5', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit4/lesson5.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U4-L6', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U4-L6', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit4/lesson6.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G2-U4-L7', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit4/lesson7.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G2-U4-L8', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit4/lesson8.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U4-L9', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G2-U4-L9', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U4-L9', subtraction, take_away_base_ones, Info) :-
    strategy_info(subtraction, take_away_base_ones, Info).
explicit_lesson_strategy('IM-G2-U4-L9', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_strategy('IM-G2-U4-L9', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
explicit_lesson_misconception('IM-G2-U4-L9', Operation, count_back_off_by_one, Info) :-
    misconception_registry_entry(count_back_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_back_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G2-U4-L9', Operation, count_on_off_by_one, Info) :-
    misconception_registry_entry(count_on_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_on_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U4-L9', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit4/lesson9.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U5-L1', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U5-L1', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U5-L1', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit5/lesson1.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U5-L10', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G2-U5-L10', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U5-L10', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U5-L10', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit5/lesson10.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U5-L11', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U5-L11', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U5-L11', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit5/lesson11.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U5-L12', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U5-L12', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit5/lesson12.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U5-L13', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U5-L13', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U5-L13', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit5/lesson13.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U5-L14', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U5-L14', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit5/lesson14.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U5-L2', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G2-U5-L2', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U5-L2', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit5/lesson2.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U5-L3', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U5-L3', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
explicit_lesson_misconception('IM-G2-U5-L3', Operation, share_smaller_into_larger, Info) :-
    misconception_registry_entry(share_smaller_into_larger, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_smaller_into_larger, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U5-L3', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit5/lesson3.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U5-L4', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U5-L4', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit5/lesson4.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U5-L5', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U5-L5', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit5/lesson5.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U5-L6', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U5-L6', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U5-L6', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit5/lesson6.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U5-L7', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U5-L7', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G2-U5-L7', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U5-L7', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit5/lesson7.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U5-L8', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G2-U5-L8', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U5-L8', subtraction, take_away_base_ones, Info) :-
    strategy_info(subtraction, take_away_base_ones, Info).
explicit_lesson_strategy('IM-G2-U5-L8', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U5-L8', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit5/lesson8.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U5-L9', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_misconception('IM-G2-U5-L9', Operation, add_across_unlike, Info) :-
    misconception_registry_entry(add_across_unlike, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_across_unlike, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U5-L9', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit5/lesson9.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G2-U6-L1', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit6/lesson1.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U6-L10', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U6-L10', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U6-L10', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit6/lesson10.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G2-U6-L11', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit6/lesson11.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U6-L12', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U6-L12', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit6/lesson12.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G2-U6-L13', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit6/lesson13.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G2-U6-L14', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit6/lesson14.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U6-L15', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G2-U6-L15', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G2-U6-L15', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G2-U6-L15', division, name_group_count_as_share_size, Info) :-
    strategy_info(division, name_group_count_as_share_size, Info).
explicit_lesson_misconception('IM-G2-U6-L15', Operation, name_group_count_as_share_size, Info) :-
    misconception_registry_entry(name_group_count_as_share_size, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(name_group_count_as_share_size, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U6-L15', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit6/lesson15.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U6-L16', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G2-U6-L16', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-G2-U6-L16', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U6-L16', division, name_group_count_as_share_size, Info) :-
    strategy_info(division, name_group_count_as_share_size, Info).
explicit_lesson_misconception('IM-G2-U6-L16', Operation, name_group_count_as_share_size, Info) :-
    misconception_registry_entry(name_group_count_as_share_size, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(name_group_count_as_share_size, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G2-U6-L16', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U6-L16', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit6/lesson16.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U6-L17', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G2-U6-L17', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G2-U6-L17', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G2-U6-L17', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U6-L17', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit6/lesson17.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G2-U6-L18', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit6/lesson18.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U6-L19', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G2-U6-L19', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G2-U6-L19', subtraction, compare_by_matching_difference, Info) :-
    strategy_info(subtraction, compare_by_matching_difference, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U6-L19', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit6/lesson19.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G2-U6-L2', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit6/lesson2.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U6-L20', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G2-U6-L20', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G2-U6-L20', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U6-L20', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_misconception('IM-G2-U6-L20', Operation, adjust_to_make_smaller, Info) :-
    misconception_registry_entry(adjust_to_make_smaller, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(adjust_to_make_smaller, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U6-L20', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit6/lesson20.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U6-L21', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G2-U6-L21', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U6-L21', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U6-L21', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit6/lesson21.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G2-U6-L22', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit6/lesson22.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G2-U6-L3', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit6/lesson3.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G2-U6-L4', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit6/lesson4.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U6-L5', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U6-L5', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U6-L5', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit6/lesson5.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G2-U6-L6', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit6/lesson6.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G2-U6-L7', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit6/lesson7.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U6-L8', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G2-U6-L8', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U6-L8', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit6/lesson8.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G2-U6-L9', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit6/lesson9.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U7-L1', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G2-U7-L1', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U7-L1', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U7-L1', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit7/lesson1.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U7-L10', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G2-U7-L10', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G2-U7-L10', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G2-U7-L10', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U7-L10', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_misconception('IM-G2-U7-L10', Operation, count_on_off_by_one, Info) :-
    misconception_registry_entry(count_on_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_on_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U7-L10', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit7/lesson10.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U7-L11', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U7-L11', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit7/lesson11.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U7-L12', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G2-U7-L12', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G2-U7-L12', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G2-U7-L12', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U7-L12', subtraction, take_away_base_ones, Info) :-
    strategy_info(subtraction, take_away_base_ones, Info).
explicit_lesson_strategy('IM-G2-U7-L12', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U7-L12', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit7/lesson12.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U7-L13', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G2-U7-L13', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G2-U7-L13', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U7-L13', subtraction, take_away_base_ones, Info) :-
    strategy_info(subtraction, take_away_base_ones, Info).
explicit_lesson_strategy('IM-G2-U7-L13', subtraction, compare_by_matching_difference, Info) :-
    strategy_info(subtraction, compare_by_matching_difference, Info).
explicit_lesson_strategy('IM-G2-U7-L13', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U7-L13', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit7/lesson13.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U7-L14', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G2-U7-L14', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G2-U7-L14', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U7-L14', subtraction, take_away_base_ones, Info) :-
    strategy_info(subtraction, take_away_base_ones, Info).
explicit_lesson_strategy('IM-G2-U7-L14', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
explicit_lesson_strategy('IM-G2-U7-L14', subtraction, add_instead_of_subtract_column, Info) :-
    strategy_info(subtraction, add_instead_of_subtract_column, Info).
explicit_lesson_misconception('IM-G2-U7-L14', Operation, add_instead_of_subtract_column, Info) :-
    misconception_registry_entry(add_instead_of_subtract_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_subtract_column, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U7-L14', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit7/lesson14.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U7-L15', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G2-U7-L15', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G2-U7-L15', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G2-U7-L15', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U7-L15', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
explicit_lesson_strategy('IM-G2-U7-L15', subtraction, add_instead_of_subtract_column, Info) :-
    strategy_info(subtraction, add_instead_of_subtract_column, Info).
explicit_lesson_misconception('IM-G2-U7-L15', Operation, add_instead_of_subtract_column, Info) :-
    misconception_registry_entry(add_instead_of_subtract_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_subtract_column, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U7-L15', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit7/lesson15.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U7-L16', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G2-U7-L16', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G2-U7-L16', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G2-U7-L16', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U7-L16', subtraction, take_away_base_ones, Info) :-
    strategy_info(subtraction, take_away_base_ones, Info).
explicit_lesson_strategy('IM-G2-U7-L16', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U7-L16', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit7/lesson16.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U7-L17', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U7-L17', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G2-U7-L17', addition, round_without_adjusting, Info) :-
    strategy_info(addition, round_without_adjusting, Info).
explicit_lesson_strategy('IM-G2-U7-L17', subtraction, take_away_base_ones, Info) :-
    strategy_info(subtraction, take_away_base_ones, Info).
explicit_lesson_strategy('IM-G2-U7-L17', subtraction, smaller_from_larger_in_column, Info) :-
    strategy_info(subtraction, smaller_from_larger_in_column, Info).
explicit_lesson_misconception('IM-G2-U7-L17', Operation, share_smaller_into_larger, Info) :-
    misconception_registry_entry(share_smaller_into_larger, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_smaller_into_larger, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G2-U7-L17', Operation, smaller_from_larger_each_column, Info) :-
    misconception_registry_entry(smaller_from_larger_each_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(smaller_from_larger_each_column, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G2-U7-L17', Operation, adjust_to_make_smaller, Info) :-
    misconception_registry_entry(adjust_to_make_smaller, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(adjust_to_make_smaller, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G2-U7-L17', Operation, smaller_from_larger_in_column, Info) :-
    misconception_registry_entry(smaller_from_larger_in_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(smaller_from_larger_in_column, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G2-U7-L17', Operation, round_without_adjusting, Info) :-
    misconception_registry_entry(round_without_adjusting, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(round_without_adjusting, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U7-L17', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit7/lesson17.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U7-L18', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U7-L18', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U7-L18', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit7/lesson18.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U7-L19', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U7-L19', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit7/lesson19.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U7-L2', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G2-U7-L2', subtraction, take_away_base_ones, Info) :-
    strategy_info(subtraction, take_away_base_ones, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U7-L2', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit7/lesson2.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U7-L3', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G2-U7-L3', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U7-L3', subtraction, take_away_base_ones, Info) :-
    strategy_info(subtraction, take_away_base_ones, Info).
explicit_lesson_strategy('IM-G2-U7-L3', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U7-L3', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit7/lesson3.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U7-L4', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G2-U7-L4', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U7-L4', subtraction, take_away_base_ones, Info) :-
    strategy_info(subtraction, take_away_base_ones, Info).
explicit_lesson_strategy('IM-G2-U7-L4', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U7-L4', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit7/lesson4.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U7-L5', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U7-L5', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U7-L5', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit7/lesson5.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U7-L6', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G2-U7-L6', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G2-U7-L6', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G2-U7-L6', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U7-L6', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U7-L6', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit7/lesson6.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U7-L7', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G2-U7-L7', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G2-U7-L7', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G2-U7-L7', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U7-L7', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U7-L7', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit7/lesson7.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U7-L8', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G2-U7-L8', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G2-U7-L8', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U7-L8', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit7/lesson8.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U7-L9', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G2-U7-L9', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G2-U7-L9', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U7-L9', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit7/lesson9.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U8-L1', subtraction, smaller_from_larger_in_column, Info) :-
    strategy_info(subtraction, smaller_from_larger_in_column, Info).
explicit_lesson_misconception('IM-G2-U8-L1', Operation, smaller_from_larger_each_column, Info) :-
    misconception_registry_entry(smaller_from_larger_each_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(smaller_from_larger_each_column, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G2-U8-L1', Operation, smaller_from_larger_in_column, Info) :-
    misconception_registry_entry(smaller_from_larger_in_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(smaller_from_larger_in_column, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U8-L1', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit8/lesson1.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U8-L10', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U8-L10', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit8/lesson10.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U8-L11', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G2-U8-L11', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G2-U8-L11', division, name_group_count_as_share_size, Info) :-
    strategy_info(division, name_group_count_as_share_size, Info).
explicit_lesson_misconception('IM-G2-U8-L11', Operation, unequal_array_columns, Info) :-
    misconception_registry_entry(unequal_array_columns, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(unequal_array_columns, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G2-U8-L11', Operation, name_group_count_as_share_size, Info) :-
    misconception_registry_entry(name_group_count_as_share_size, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(name_group_count_as_share_size, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U8-L11', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit8/lesson11.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U8-L12', division, name_group_count_as_share_size, Info) :-
    strategy_info(division, name_group_count_as_share_size, Info).
explicit_lesson_misconception('IM-G2-U8-L12', Operation, name_group_count_as_share_size, Info) :-
    misconception_registry_entry(name_group_count_as_share_size, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(name_group_count_as_share_size, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U8-L12', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit8/lesson12.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G2-U8-L13', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit8/lesson13.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U8-L14', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G2-U8-L14', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U8-L14', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit8/lesson14.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U8-L2', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G2-U8-L2', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U8-L2', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit8/lesson2.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U8-L3', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G2-U8-L3', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U8-L3', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit8/lesson3.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U8-L4', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G2-U8-L4', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U8-L4', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit8/lesson4.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U8-L5', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G2-U8-L5', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-G2-U8-L5', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G2-U8-L5', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
explicit_lesson_misconception('IM-G2-U8-L5', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U8-L5', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit8/lesson5.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U8-L6', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U8-L6', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit8/lesson6.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U8-L7', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G2-U8-L7', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
explicit_lesson_misconception('IM-G2-U8-L7', Operation, unequal_array_columns, Info) :-
    misconception_registry_entry(unequal_array_columns, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(unequal_array_columns, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U8-L7', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit8/lesson7.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U8-L8', addition, count_all_instead_of_known_fact, Info) :-
    strategy_info(addition, count_all_instead_of_known_fact, Info).
explicit_lesson_strategy('IM-G2-U8-L8', subtraction, compare_by_matching_difference, Info) :-
    strategy_info(subtraction, compare_by_matching_difference, Info).
explicit_lesson_strategy('IM-G2-U8-L8', subtraction, add_instead_of_subtract_column, Info) :-
    strategy_info(subtraction, add_instead_of_subtract_column, Info).
explicit_lesson_strategy('IM-G2-U8-L8', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G2-U8-L8', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
explicit_lesson_misconception('IM-G2-U8-L8', Operation, count_all_instead_of_known_fact, Info) :-
    misconception_registry_entry(count_all_instead_of_known_fact, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_instead_of_known_fact, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G2-U8-L8', Operation, add_instead_of_subtract_column, Info) :-
    misconception_registry_entry(add_instead_of_subtract_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_subtract_column, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U8-L8', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit8/lesson8.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U8-L9', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G2-U8-L9', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U8-L9', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit8/lesson9.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U9-L1', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U9-L1', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit9/lesson1.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U9-L10', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G2-U9-L10', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U9-L10', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit9/lesson10.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U9-L11', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G2-U9-L11', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G2-U9-L11', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G2-U9-L11', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_strategy('IM-G2-U9-L11', subtraction, compare_by_matching_difference, Info) :-
    strategy_info(subtraction, compare_by_matching_difference, Info).
explicit_lesson_misconception('IM-G2-U9-L11', Operation, difference_interpreted_as_sum, Info) :-
    misconception_registry_entry(difference_interpreted_as_sum, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(difference_interpreted_as_sum, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U9-L11', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit9/lesson11.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U9-L12', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-G2-U9-L12', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_misconception('IM-G2-U9-L12', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U9-L12', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit9/lesson12.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U9-L13', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G2-U9-L13', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U9-L13', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit9/lesson13.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U9-L2', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G2-U9-L2', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G2-U9-L2', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U9-L2', addition, known_fact_retrieval, Info) :-
    strategy_info(addition, known_fact_retrieval, Info).
explicit_lesson_strategy('IM-G2-U9-L2', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_misconception('IM-G2-U9-L2', Operation, flip_subtraction_order, Info) :-
    misconception_registry_entry(flip_subtraction_order, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(flip_subtraction_order, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U9-L2', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit9/lesson2.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U9-L3', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G2-U9-L3', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G2-U9-L3', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U9-L3', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit9/lesson3.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U9-L4', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G2-U9-L4', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U9-L4', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit9/lesson4.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U9-L5', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G2-U9-L5', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U9-L5', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
explicit_lesson_misconception('IM-G2-U9-L5', Operation, share_smaller_into_larger, Info) :-
    misconception_registry_entry(share_smaller_into_larger, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_smaller_into_larger, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U9-L5', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit9/lesson5.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U9-L6', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U9-L6', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
explicit_lesson_strategy('IM-G2-U9-L6', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U9-L6', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit9/lesson6.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U9-L7', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G2-U9-L7', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G2-U9-L7', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U9-L7', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_strategy('IM-G2-U9-L7', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U9-L7', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit9/lesson7.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U9-L8', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G2-U9-L8', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G2-U9-L8', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U9-L8', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G2-U9-L8', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_strategy('IM-G2-U9-L8', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U9-L8', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit9/lesson8.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G2-U9-L9', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G2-U9-L9', subtraction, take_away_base_ones, Info) :-
    strategy_info(subtraction, take_away_base_ones, Info).
explicit_lesson_strategy('IM-G2-U9-L9', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
text_interpreter:explicit_lesson_text_source('IM-G2-U9-L9', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade2/unit9/lesson9.md'), Path, [access(read)]).

% Source-attested deformation licenses (2026-07-11 license expansion).
% The teacher guide's anticipated-error prose licenses a registered deformation;
% the paired reviewed_task_instances entry supplies the operands and source line.
% IM-G2-U2-L1 guide: "find the sum of the cubes rather than the difference".
explicit_lesson_misconception('IM-G2-U2-L1', Operation, add_instead_of_subtract_column, Info) :-
    misconception_registry_entry(add_instead_of_subtract_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_subtract_column, Citation, Commitment, EntitlementLacked, [], Info).
% IM-G2-U2-L11 guide: "If students find the sum of Diego's and Jada's seeds".
explicit_lesson_misconception('IM-G2-U2-L11', Operation, add_instead_of_subtract_column, Info) :-
    misconception_registry_entry(add_instead_of_subtract_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_subtract_column, Citation, Commitment, EntitlementLacked, [], Info).
% IM-G2-U2-L11 cool-down (Tyler's seeds, 42 - 28): the guide anticipates a
% regrouping miscalculation ("find a value other than 14"); smaller-from-larger-in-column
% is the cited registry form of that error and fires on the trigger (ones 2 < 8).
% Operands recovered from the E343 teacher-guide PDF (figure-bound; see the paired
% reviewed_task_instances entry g2_tyler_seeds_regroup with e343_pdf provenance).
explicit_lesson_misconception('IM-G2-U2-L11', Operation, smaller_from_larger_in_column, Info) :-
    misconception_registry_entry(smaller_from_larger_in_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(smaller_from_larger_in_column, Citation, Commitment, EntitlementLacked, [], Info).
% IM-G2-U3-L11 guide: "If students add the known values instead of subtract".
explicit_lesson_misconception('IM-G2-U3-L11', Operation, add_instead_of_subtract_column, Info) :-
    misconception_registry_entry(add_instead_of_subtract_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_subtract_column, Citation, Commitment, EntitlementLacked, [], Info).
% IM-G2-U3-L10 guide: "Students say the length is 27 inches" (endpoint, not difference).
explicit_lesson_misconception('IM-G2-U3-L10', Operation, answer_as_endpoint_count_up, Info) :-
    misconception_registry_entry(answer_as_endpoint_count_up, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(answer_as_endpoint_count_up, Citation, Commitment, EntitlementLacked, [], Info).
