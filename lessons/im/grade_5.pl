% lessons/im/grade_5.pl - Strategy/misconception facts for grade 5
:- multifile explicit_lesson_strategy/4.
:- discontiguous explicit_lesson_strategy/4.
:- multifile explicit_lesson_misconception/4.
:- discontiguous explicit_lesson_misconception/4.
:- multifile text_interpreter:explicit_lesson_text_source/2.
:- discontiguous text_interpreter:explicit_lesson_text_source/2.

text_interpreter:explicit_lesson_text_source('IM-G5-U1-L1', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit1/lesson1.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U1-L10', subtraction, compare_by_matching_difference, Info) :-
    strategy_info(subtraction, compare_by_matching_difference, Info).
explicit_lesson_misconception('IM-G5-U1-L10', Operation, share_smaller_into_larger, Info) :-
    misconception_registry_entry(share_smaller_into_larger, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_smaller_into_larger, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U1-L10', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit1/lesson10.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U1-L11', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit1/lesson11.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U1-L12', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit1/lesson12.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U1-L2', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit1/lesson2.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U1-L3', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit1/lesson3.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U1-L4', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G5-U1-L4', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U1-L4', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit1/lesson4.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U1-L5', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit1/lesson5.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U1-L6', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U1-L6', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit1/lesson6.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U1-L7', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit1/lesson7.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U1-L8', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit1/lesson8.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U1-L9', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit1/lesson9.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U2-L1', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit2/lesson1.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U2-L10', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G5-U2-L10', fraction, unit_fraction_iteration, Info) :-
    strategy_info(fraction, unit_fraction_iteration, Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U2-L10', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit2/lesson10.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U2-L11', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit2/lesson11.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U2-L12', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit2/lesson12.md'), Path, [access(read)]).

explicit_lesson_misconception('IM-G5-U2-L13', Operation, fraction_of_as_division, Info) :-
    misconception_registry_entry(fraction_of_as_division, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(fraction_of_as_division, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U2-L13', Operation, whole_as_unit_fraction, Info) :-
    misconception_registry_entry(whole_as_unit_fraction, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(whole_as_unit_fraction, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U2-L13', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit2/lesson13.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U2-L14', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit2/lesson14.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U2-L15', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit2/lesson15.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U2-L16', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit2/lesson16.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U2-L17', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit2/lesson17.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U2-L2', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G5-U2-L2', fraction, unit_fraction_iteration, Info) :-
    strategy_info(fraction, unit_fraction_iteration, Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U2-L2', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit2/lesson2.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U2-L3', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit2/lesson3.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U2-L4', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit2/lesson4.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U2-L5', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit2/lesson5.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U2-L6', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G5-U2-L6', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G5-U2-L6', fraction, unit_fraction_iteration, Info) :-
    strategy_info(fraction, unit_fraction_iteration, Info).
explicit_lesson_misconception('IM-G5-U2-L6', Operation, multiply_by_numerator_for_divide, Info) :-
    misconception_registry_entry(multiply_by_numerator_for_divide, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(multiply_by_numerator_for_divide, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U2-L6', Operation, fraction_of_as_division, Info) :-
    misconception_registry_entry(fraction_of_as_division, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(fraction_of_as_division, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U2-L6', Operation, division_story_as_multiplication, Info) :-
    misconception_registry_entry(division_story_as_multiplication, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(division_story_as_multiplication, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U2-L6', Operation, divide_by_half_as_by_two, Info) :-
    misconception_registry_entry(divide_by_half_as_by_two, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_by_half_as_by_two, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U2-L6', Operation, whole_as_unit_fraction, Info) :-
    misconception_registry_entry(whole_as_unit_fraction, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(whole_as_unit_fraction, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U2-L6', Operation, divide_by_unit_fraction_as_multiply, Info) :-
    misconception_registry_entry(divide_by_unit_fraction_as_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_by_unit_fraction_as_multiply, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U2-L6', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit2/lesson6.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U2-L7', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G5-U2-L7', fraction, unit_fraction_iteration, Info) :-
    strategy_info(fraction, unit_fraction_iteration, Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U2-L7', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit2/lesson7.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U2-L8', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G5-U2-L8', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G5-U2-L8', fraction, unit_fraction_iteration, Info) :-
    strategy_info(fraction, unit_fraction_iteration, Info).
explicit_lesson_misconception('IM-G5-U2-L8', Operation, add_instead_of_multiply, Info) :-
    misconception_registry_entry(add_instead_of_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_multiply, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U2-L8', Operation, double_first_add_one, Info) :-
    misconception_registry_entry(double_first_add_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(double_first_add_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U2-L8', Operation, fraction_of_as_division, Info) :-
    misconception_registry_entry(fraction_of_as_division, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(fraction_of_as_division, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U2-L8', Operation, whole_as_unit_fraction, Info) :-
    misconception_registry_entry(whole_as_unit_fraction, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(whole_as_unit_fraction, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U2-L8', Operation, divide_by_unit_fraction_as_multiply, Info) :-
    misconception_registry_entry(divide_by_unit_fraction_as_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_by_unit_fraction_as_multiply, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U2-L8', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit2/lesson8.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U2-L9', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G5-U2-L9', fraction, unit_fraction_iteration, Info) :-
    strategy_info(fraction, unit_fraction_iteration, Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U2-L9', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit2/lesson9.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U3-L1', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G5-U3-L1', fraction, unit_fraction_iteration, Info) :-
    strategy_info(fraction, unit_fraction_iteration, Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U3-L1', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit3/lesson1.md'), Path, [access(read)]).

explicit_lesson_misconception('IM-G5-U3-L10', Operation, whole_as_unit_fraction, Info) :-
    misconception_registry_entry(whole_as_unit_fraction, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(whole_as_unit_fraction, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U3-L10', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit3/lesson10.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U3-L11', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G5-U3-L11', fraction, unit_fraction_iteration, Info) :-
    strategy_info(fraction, unit_fraction_iteration, Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U3-L11', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit3/lesson11.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U3-L12', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G5-U3-L12', fraction, unit_fraction_iteration, Info) :-
    strategy_info(fraction, unit_fraction_iteration, Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U3-L12', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit3/lesson12.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U3-L13', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G5-U3-L13', fraction, unit_fraction_iteration, Info) :-
    strategy_info(fraction, unit_fraction_iteration, Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U3-L13', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit3/lesson13.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U3-L14', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G5-U3-L14', fraction, unit_fraction_iteration, Info) :-
    strategy_info(fraction, unit_fraction_iteration, Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U3-L14', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit3/lesson14.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U3-L15', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G5-U3-L15', fraction, unit_fraction_iteration, Info) :-
    strategy_info(fraction, unit_fraction_iteration, Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U3-L15', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit3/lesson15.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U3-L16', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G5-U3-L16', fraction, unit_fraction_iteration, Info) :-
    strategy_info(fraction, unit_fraction_iteration, Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U3-L16', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit3/lesson16.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U3-L17', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G5-U3-L17', fraction, unit_fraction_iteration, Info) :-
    strategy_info(fraction, unit_fraction_iteration, Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U3-L17', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit3/lesson17.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U3-L18', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G5-U3-L18', fraction, unit_fraction_iteration, Info) :-
    strategy_info(fraction, unit_fraction_iteration, Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U3-L18', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit3/lesson18.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U3-L19', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G5-U3-L19', fraction, unit_fraction_iteration, Info) :-
    strategy_info(fraction, unit_fraction_iteration, Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U3-L19', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit3/lesson19.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U3-L2', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G5-U3-L2', fraction, unit_fraction_iteration, Info) :-
    strategy_info(fraction, unit_fraction_iteration, Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U3-L2', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit3/lesson2.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U3-L20', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G5-U3-L20', fraction, unit_fraction_iteration, Info) :-
    strategy_info(fraction, unit_fraction_iteration, Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U3-L20', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit3/lesson20.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U3-L3', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G5-U3-L3', fraction, unit_fraction_iteration, Info) :-
    strategy_info(fraction, unit_fraction_iteration, Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U3-L3', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit3/lesson3.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U3-L4', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G5-U3-L4', fraction, unit_fraction_iteration, Info) :-
    strategy_info(fraction, unit_fraction_iteration, Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U3-L4', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit3/lesson4.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U3-L5', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G5-U3-L5', fraction, unit_fraction_iteration, Info) :-
    strategy_info(fraction, unit_fraction_iteration, Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U3-L5', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit3/lesson5.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U3-L6', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G5-U3-L6', fraction, unit_fraction_iteration, Info) :-
    strategy_info(fraction, unit_fraction_iteration, Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U3-L6', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit3/lesson6.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U3-L7', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit3/lesson7.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U3-L8', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit3/lesson8.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U3-L9', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G5-U3-L9', fraction, unit_fraction_iteration, Info) :-
    strategy_info(fraction, unit_fraction_iteration, Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U3-L9', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit3/lesson9.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U4-L1', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G5-U4-L1', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G5-U4-L1', addition, column_addition_with_carrying, Info) :-
    strategy_info(addition, column_addition_with_carrying, Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U4-L1', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit4/lesson1.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U4-L10', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G5-U4-L10', division, partial_quotient_chunking, Info) :-
    strategy_info(division, partial_quotient_chunking, Info).
explicit_lesson_misconception('IM-G5-U4-L10', Operation, raw_quotient_with_remainder, Info) :-
    misconception_registry_entry(raw_quotient_with_remainder, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(raw_quotient_with_remainder, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U4-L10', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit4/lesson10.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U4-L11', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G5-U4-L11', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G5-U4-L11', division, share_into_divisor_groups, Info) :-
    strategy_info(division, share_into_divisor_groups, Info).
explicit_lesson_strategy('IM-G5-U4-L11', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
explicit_lesson_strategy('IM-G5-U4-L11', division, partial_quotient_chunking, Info) :-
    strategy_info(division, partial_quotient_chunking, Info).
explicit_lesson_misconception('IM-G5-U4-L11', Operation, raw_quotient_with_remainder, Info) :-
    misconception_registry_entry(raw_quotient_with_remainder, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(raw_quotient_with_remainder, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U4-L11', Operation, share_into_divisor_groups, Info) :-
    misconception_registry_entry(share_into_divisor_groups, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_into_divisor_groups, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U4-L11', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit4/lesson11.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U4-L12', division, share_into_divisor_groups, Info) :-
    strategy_info(division, share_into_divisor_groups, Info).
explicit_lesson_strategy('IM-G5-U4-L12', division, partial_quotient_chunking, Info) :-
    strategy_info(division, partial_quotient_chunking, Info).
explicit_lesson_misconception('IM-G5-U4-L12', Operation, raw_quotient_with_remainder, Info) :-
    misconception_registry_entry(raw_quotient_with_remainder, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(raw_quotient_with_remainder, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U4-L12', Operation, share_into_divisor_groups, Info) :-
    misconception_registry_entry(share_into_divisor_groups, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_into_divisor_groups, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U4-L12', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit4/lesson12.md'), Path, [access(read)]).

explicit_lesson_misconception('IM-G5-U4-L13', Operation, raw_quotient_with_remainder, Info) :-
    misconception_registry_entry(raw_quotient_with_remainder, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(raw_quotient_with_remainder, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U4-L13', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit4/lesson13.md'), Path, [access(read)]).

explicit_lesson_misconception('IM-G5-U4-L14', Operation, raw_quotient_with_remainder, Info) :-
    misconception_registry_entry(raw_quotient_with_remainder, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(raw_quotient_with_remainder, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U4-L14', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit4/lesson14.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U4-L15', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_misconception('IM-G5-U4-L15', Operation, add_instead_of_multiply, Info) :-
    misconception_registry_entry(add_instead_of_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_multiply, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U4-L15', Operation, multiply_by_numerator_for_divide, Info) :-
    misconception_registry_entry(multiply_by_numerator_for_divide, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(multiply_by_numerator_for_divide, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U4-L15', Operation, division_must_be_smaller, Info) :-
    misconception_registry_entry(division_must_be_smaller, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(division_must_be_smaller, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U4-L15', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit4/lesson15.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U4-L16', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G5-U4-L16', division, share_into_divisor_groups, Info) :-
    strategy_info(division, share_into_divisor_groups, Info).
explicit_lesson_misconception('IM-G5-U4-L16', Operation, raw_quotient_with_remainder, Info) :-
    misconception_registry_entry(raw_quotient_with_remainder, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(raw_quotient_with_remainder, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U4-L16', Operation, fraction_of_as_division, Info) :-
    misconception_registry_entry(fraction_of_as_division, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(fraction_of_as_division, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U4-L16', Operation, whole_as_unit_fraction, Info) :-
    misconception_registry_entry(whole_as_unit_fraction, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(whole_as_unit_fraction, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U4-L16', Operation, share_into_divisor_groups, Info) :-
    misconception_registry_entry(share_into_divisor_groups, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_into_divisor_groups, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U4-L16', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit4/lesson16.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U4-L17', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit4/lesson17.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U4-L18', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G5-U4-L18', addition, column_addition_with_carrying, Info) :-
    strategy_info(addition, column_addition_with_carrying, Info).
explicit_lesson_strategy('IM-G5-U4-L18', division, measure_groups_of_size, Info) :-
    strategy_info(division, measure_groups_of_size, Info).
explicit_lesson_misconception('IM-G5-U4-L18', Operation, share_smaller_into_larger, Info) :-
    misconception_registry_entry(share_smaller_into_larger, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_smaller_into_larger, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U4-L18', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit4/lesson18.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U4-L19', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G5-U4-L19', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G5-U4-L19', division, measure_groups_of_size, Info) :-
    strategy_info(division, measure_groups_of_size, Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U4-L19', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit4/lesson19.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U4-L2', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G5-U4-L2', addition, column_addition_with_carrying, Info) :-
    strategy_info(addition, column_addition_with_carrying, Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U4-L2', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit4/lesson2.md'), Path, [access(read)]).

explicit_lesson_misconception('IM-G5-U4-L20', Operation, divide_by_half_as_by_two, Info) :-
    misconception_registry_entry(divide_by_half_as_by_two, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_by_half_as_by_two, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U4-L20', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit4/lesson20.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U4-L3', addition, column_addition_with_carrying, Info) :-
    strategy_info(addition, column_addition_with_carrying, Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U4-L3', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit4/lesson3.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U4-L4', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G5-U4-L4', addition, column_addition_with_carrying, Info) :-
    strategy_info(addition, column_addition_with_carrying, Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U4-L4', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit4/lesson4.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U4-L5', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G5-U4-L5', addition, column_addition_with_carrying, Info) :-
    strategy_info(addition, column_addition_with_carrying, Info).
explicit_lesson_misconception('IM-G5-U4-L5', Operation, add_instead_of_multiply, Info) :-
    misconception_registry_entry(add_instead_of_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_multiply, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U4-L5', Operation, partial_products_no_shift, Info) :-
    misconception_registry_entry(partial_products_no_shift, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(partial_products_no_shift, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U4-L5', Operation, partial_products_no_place_shift, Info) :-
    misconception_registry_entry(partial_products_no_place_shift, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(partial_products_no_place_shift, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U4-L5', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit4/lesson5.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U4-L6', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G5-U4-L6', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G5-U4-L6', addition, column_addition_with_carrying, Info) :-
    strategy_info(addition, column_addition_with_carrying, Info).
explicit_lesson_misconception('IM-G5-U4-L6', Operation, partial_products_no_shift, Info) :-
    misconception_registry_entry(partial_products_no_shift, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(partial_products_no_shift, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U4-L6', Operation, partial_products_no_place_shift, Info) :-
    misconception_registry_entry(partial_products_no_place_shift, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(partial_products_no_place_shift, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U4-L6', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit4/lesson6.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U4-L7', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G5-U4-L7', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G5-U4-L7', addition, column_addition_with_carrying, Info) :-
    strategy_info(addition, column_addition_with_carrying, Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U4-L7', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit4/lesson7.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U4-L8', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G5-U4-L8', addition, column_addition_with_carrying, Info) :-
    strategy_info(addition, column_addition_with_carrying, Info).
explicit_lesson_misconception('IM-G5-U4-L8', Operation, double_first_add_one, Info) :-
    misconception_registry_entry(double_first_add_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(double_first_add_one, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U4-L8', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit4/lesson8.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U4-L9', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G5-U4-L9', addition, column_addition_with_carrying, Info) :-
    strategy_info(addition, column_addition_with_carrying, Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U4-L9', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit4/lesson9.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U5-L1', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_misconception('IM-G5-U5-L1', Operation, whole_as_unit_fraction, Info) :-
    misconception_registry_entry(whole_as_unit_fraction, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(whole_as_unit_fraction, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U5-L1', Operation, add_denominators_unit_fractions, Info) :-
    misconception_registry_entry(add_denominators_unit_fractions, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_denominators_unit_fractions, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U5-L1', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit5/lesson1.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U5-L10', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G5-U5-L10', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G5-U5-L10', subtraction, add_instead_of_subtract_column, Info) :-
    strategy_info(subtraction, add_instead_of_subtract_column, Info).
explicit_lesson_strategy('IM-G5-U5-L10', decimal, positional_decimal_reading, Info) :-
    strategy_info(decimal, positional_decimal_reading, Info).
explicit_lesson_misconception('IM-G5-U5-L10', Operation, add_instead_of_subtract_column, Info) :-
    misconception_registry_entry(add_instead_of_subtract_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_subtract_column, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U5-L10', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit5/lesson10.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U5-L11', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G5-U5-L11', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
% IM-G5-U5-L11 cool-down "The Value of the Sum" (1.20 + 0.13, printed answer 1.33):
% the productive decimal_addition_by_aligned_units is already attached. The misalignment
% deformation decimal_add_unaligned_numerals is registry-licensed (the guide task states
% the correct value, not this error); it has no misconception_registry_entry, so it
% licenses through the strategy route (action_role reclassifies it as role=deformation).
explicit_lesson_strategy('IM-G5-U5-L11', decimal, decimal_add_unaligned_numerals, Info) :-
    strategy_info(decimal, decimal_add_unaligned_numerals, Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U5-L11', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit5/lesson11.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U5-L12', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G5-U5-L12', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G5-U5-L12', addition, column_addition_with_carrying, Info) :-
    strategy_info(addition, column_addition_with_carrying, Info).
explicit_lesson_strategy('IM-G5-U5-L12', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U5-L12', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit5/lesson12.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U5-L13', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G5-U5-L13', addition, column_addition_with_carrying, Info) :-
    strategy_info(addition, column_addition_with_carrying, Info).
explicit_lesson_strategy('IM-G5-U5-L13', decimal, positional_decimal_reading, Info) :-
    strategy_info(decimal, positional_decimal_reading, Info).
explicit_lesson_misconception('IM-G5-U5-L13', Operation, leading_digits_estimate, Info) :-
    misconception_registry_entry(leading_digits_estimate, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(leading_digits_estimate, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U5-L13', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit5/lesson13.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U5-L14', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G5-U5-L14', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G5-U5-L14', addition, column_addition_with_carrying, Info) :-
    strategy_info(addition, column_addition_with_carrying, Info).
explicit_lesson_misconception('IM-G5-U5-L14', Operation, add_instead_of_multiply, Info) :-
    misconception_registry_entry(add_instead_of_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_multiply, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U5-L14', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit5/lesson14.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U5-L15', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G5-U5-L15', addition, column_addition_with_carrying, Info) :-
    strategy_info(addition, column_addition_with_carrying, Info).
explicit_lesson_strategy('IM-G5-U5-L15', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_misconception('IM-G5-U5-L15', Operation, share_smaller_into_larger, Info) :-
    misconception_registry_entry(share_smaller_into_larger, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_smaller_into_larger, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U5-L15', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit5/lesson15.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U5-L16', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G5-U5-L16', addition, column_addition_with_carrying, Info) :-
    strategy_info(addition, column_addition_with_carrying, Info).
explicit_lesson_strategy('IM-G5-U5-L16', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U5-L16', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit5/lesson16.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U5-L17', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_misconception('IM-G5-U5-L17', Operation, share_smaller_into_larger, Info) :-
    misconception_registry_entry(share_smaller_into_larger, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_smaller_into_larger, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U5-L17', Operation, double_first_add_one, Info) :-
    misconception_registry_entry(double_first_add_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(double_first_add_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U5-L17', Operation, always_larger_into_smaller, Info) :-
    misconception_registry_entry(always_larger_into_smaller, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(always_larger_into_smaller, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U5-L17', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit5/lesson17.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U5-L18', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G5-U5-L18', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U5-L18', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit5/lesson18.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U5-L19', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G5-U5-L19', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G5-U5-L19', decimal, positional_decimal_reading, Info) :-
    strategy_info(decimal, positional_decimal_reading, Info).
explicit_lesson_misconception('IM-G5-U5-L19', Operation, add_instead_of_multiply, Info) :-
    misconception_registry_entry(add_instead_of_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_multiply, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U5-L19', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit5/lesson19.md'), Path, [access(read)]).

explicit_lesson_misconception('IM-G5-U5-L2', Operation, divide_by_half_as_by_two, Info) :-
    misconception_registry_entry(divide_by_half_as_by_two, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_by_half_as_by_two, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U5-L2', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit5/lesson2.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U5-L20', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U5-L20', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit5/lesson20.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U5-L21', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G5-U5-L21', decimal, positional_decimal_reading, Info) :-
    strategy_info(decimal, positional_decimal_reading, Info).
explicit_lesson_misconception('IM-G5-U5-L21', Operation, divide_to_find_decimal_of, Info) :-
    misconception_registry_entry(divide_to_find_decimal_of, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_to_find_decimal_of, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U5-L21', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit5/lesson21.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U5-L22', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G5-U5-L22', decimal, positional_decimal_reading, Info) :-
    strategy_info(decimal, positional_decimal_reading, Info).
explicit_lesson_misconception('IM-G5-U5-L22', Operation, fraction_of_as_division, Info) :-
    misconception_registry_entry(fraction_of_as_division, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(fraction_of_as_division, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U5-L22', Operation, whole_as_unit_fraction, Info) :-
    misconception_registry_entry(whole_as_unit_fraction, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(whole_as_unit_fraction, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U5-L22', Operation, divide_by_unit_fraction_as_multiply, Info) :-
    misconception_registry_entry(divide_by_unit_fraction_as_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_by_unit_fraction_as_multiply, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U5-L22', Operation, divide_to_find_decimal_of, Info) :-
    misconception_registry_entry(divide_to_find_decimal_of, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_to_find_decimal_of, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U5-L22', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit5/lesson22.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U5-L23', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G5-U5-L23', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G5-U5-L23', division, share_into_divisor_groups, Info) :-
    strategy_info(division, share_into_divisor_groups, Info).
explicit_lesson_misconception('IM-G5-U5-L23', Operation, add_instead_of_multiply, Info) :-
    misconception_registry_entry(add_instead_of_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_multiply, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U5-L23', Operation, divide_to_find_decimal_of, Info) :-
    misconception_registry_entry(divide_to_find_decimal_of, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_to_find_decimal_of, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U5-L23', Operation, multiply_when_divisor_is_decimal, Info) :-
    misconception_registry_entry(multiply_when_divisor_is_decimal, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(multiply_when_divisor_is_decimal, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U5-L23', Operation, share_into_divisor_groups, Info) :-
    misconception_registry_entry(share_into_divisor_groups, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_into_divisor_groups, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U5-L23', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit5/lesson23.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U5-L24', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G5-U5-L24', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G5-U5-L24', division, share_into_divisor_groups, Info) :-
    strategy_info(division, share_into_divisor_groups, Info).
explicit_lesson_strategy('IM-G5-U5-L24', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
explicit_lesson_strategy('IM-G5-U5-L24', decimal, positional_decimal_reading, Info) :-
    strategy_info(decimal, positional_decimal_reading, Info).
explicit_lesson_misconception('IM-G5-U5-L24', Operation, divide_by_half_as_by_two, Info) :-
    misconception_registry_entry(divide_by_half_as_by_two, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_by_half_as_by_two, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U5-L24', Operation, divide_to_find_decimal_of, Info) :-
    misconception_registry_entry(divide_to_find_decimal_of, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_to_find_decimal_of, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U5-L24', Operation, share_into_divisor_groups, Info) :-
    misconception_registry_entry(share_into_divisor_groups, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_into_divisor_groups, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U5-L24', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit5/lesson24.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U5-L25', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G5-U5-L25', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G5-U5-L25', division, share_into_divisor_groups, Info) :-
    strategy_info(division, share_into_divisor_groups, Info).
explicit_lesson_misconception('IM-G5-U5-L25', Operation, divide_to_find_decimal_of, Info) :-
    misconception_registry_entry(divide_to_find_decimal_of, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_to_find_decimal_of, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U5-L25', Operation, multiply_when_divisor_is_decimal, Info) :-
    misconception_registry_entry(multiply_when_divisor_is_decimal, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(multiply_when_divisor_is_decimal, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U5-L25', Operation, division_always_smaller, Info) :-
    misconception_registry_entry(division_always_smaller, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(division_always_smaller, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U5-L25', Operation, share_into_divisor_groups, Info) :-
    misconception_registry_entry(share_into_divisor_groups, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_into_divisor_groups, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U5-L25', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit5/lesson25.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U5-L26', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit5/lesson26.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U5-L3', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G5-U5-L3', decimal, positional_decimal_reading, Info) :-
    strategy_info(decimal, positional_decimal_reading, Info).
explicit_lesson_misconception('IM-G5-U5-L3', Operation, whole_as_unit_fraction, Info) :-
    misconception_registry_entry(whole_as_unit_fraction, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(whole_as_unit_fraction, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U5-L3', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit5/lesson3.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U5-L4', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G5-U5-L4', subtraction, smaller_from_larger_in_column, Info) :-
    strategy_info(subtraction, smaller_from_larger_in_column, Info).
explicit_lesson_misconception('IM-G5-U5-L4', Operation, smaller_from_larger_each_column, Info) :-
    misconception_registry_entry(smaller_from_larger_each_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(smaller_from_larger_each_column, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U5-L4', Operation, whole_as_unit_fraction, Info) :-
    misconception_registry_entry(whole_as_unit_fraction, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(whole_as_unit_fraction, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U5-L4', Operation, smaller_from_larger_in_column, Info) :-
    misconception_registry_entry(smaller_from_larger_in_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(smaller_from_larger_in_column, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U5-L4', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit5/lesson4.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U5-L5', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G5-U5-L5', decimal, positional_decimal_reading, Info) :-
    strategy_info(decimal, positional_decimal_reading, Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U5-L5', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit5/lesson5.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U5-L6', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G5-U5-L6', decimal, positional_decimal_reading, Info) :-
    strategy_info(decimal, positional_decimal_reading, Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U5-L6', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit5/lesson6.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U5-L7', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G5-U5-L7', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G5-U5-L7', division, measure_groups_of_size, Info) :-
    strategy_info(division, measure_groups_of_size, Info).
explicit_lesson_strategy('IM-G5-U5-L7', decimal, positional_decimal_reading, Info) :-
    strategy_info(decimal, positional_decimal_reading, Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U5-L7', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit5/lesson7.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U5-L8', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G5-U5-L8', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_misconception('IM-G5-U5-L8', Operation, whole_as_unit_fraction, Info) :-
    misconception_registry_entry(whole_as_unit_fraction, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(whole_as_unit_fraction, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U5-L8', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit5/lesson8.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U5-L9', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G5-U5-L9', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G5-U5-L9', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_strategy('IM-G5-U5-L9', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U5-L9', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit5/lesson9.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U6-L1', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_misconception('IM-G5-U6-L1', Operation, share_smaller_into_larger, Info) :-
    misconception_registry_entry(share_smaller_into_larger, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_smaller_into_larger, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U6-L1', Operation, divide_larger_by_smaller, Info) :-
    misconception_registry_entry(divide_larger_by_smaller, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_larger_by_smaller, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U6-L1', Operation, always_larger_into_smaller, Info) :-
    misconception_registry_entry(always_larger_into_smaller, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(always_larger_into_smaller, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U6-L1', Operation, division_always_smaller, Info) :-
    misconception_registry_entry(division_always_smaller, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(division_always_smaller, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U6-L1', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit6/lesson1.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U6-L10', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit6/lesson10.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U6-L11', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit6/lesson11.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U6-L12', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit6/lesson12.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U6-L13', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit6/lesson13.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U6-L14', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G5-U6-L14', fraction, unit_fraction_iteration, Info) :-
    strategy_info(fraction, unit_fraction_iteration, Info).
explicit_lesson_strategy('IM-G5-U6-L14', fraction, co_denominator_count_on_from_larger, Info) :-
    strategy_info(fraction, co_denominator_count_on_from_larger, Info).
explicit_lesson_strategy('IM-G5-U6-L14', fraction, co_denominator_make_base_transfer, Info) :-
    strategy_info(fraction, co_denominator_make_base_transfer, Info).
explicit_lesson_misconception('IM-G5-U6-L14', Operation, add_across_unlike, Info) :-
    misconception_registry_entry(add_across_unlike, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_across_unlike, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U6-L14', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit6/lesson14.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U6-L15', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit6/lesson15.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U6-L16', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G5-U6-L16', fraction, unit_fraction_iteration, Info) :-
    strategy_info(fraction, unit_fraction_iteration, Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U6-L16', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit6/lesson16.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U6-L17', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit6/lesson17.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U6-L18', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit6/lesson18.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U6-L19', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit6/lesson19.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U6-L2', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-G5-U6-L2', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G5-U6-L2', division, name_group_count_as_share_size, Info) :-
    strategy_info(division, name_group_count_as_share_size, Info).
explicit_lesson_misconception('IM-G5-U6-L2', Operation, name_group_count_as_share_size, Info) :-
    misconception_registry_entry(name_group_count_as_share_size, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(name_group_count_as_share_size, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U6-L2', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U6-L2', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit6/lesson2.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U6-L20', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_misconception('IM-G5-U6-L20', Operation, divide_by_half_as_by_two, Info) :-
    misconception_registry_entry(divide_by_half_as_by_two, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_by_half_as_by_two, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U6-L20', Operation, whole_as_unit_fraction, Info) :-
    misconception_registry_entry(whole_as_unit_fraction, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(whole_as_unit_fraction, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U6-L20', Operation, divide_by_unit_fraction_as_multiply, Info) :-
    misconception_registry_entry(divide_by_unit_fraction_as_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_by_unit_fraction_as_multiply, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U6-L20', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit6/lesson20.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U6-L21', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit6/lesson21.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U6-L3', subtraction, smaller_from_larger_in_column, Info) :-
    strategy_info(subtraction, smaller_from_larger_in_column, Info).
explicit_lesson_strategy('IM-G5-U6-L3', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_misconception('IM-G5-U6-L3', Operation, smaller_from_larger_each_column, Info) :-
    misconception_registry_entry(smaller_from_larger_each_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(smaller_from_larger_each_column, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U6-L3', Operation, divide_by_half_as_by_two, Info) :-
    misconception_registry_entry(divide_by_half_as_by_two, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_by_half_as_by_two, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U6-L3', Operation, whole_as_unit_fraction, Info) :-
    misconception_registry_entry(whole_as_unit_fraction, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(whole_as_unit_fraction, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U6-L3', Operation, divide_by_unit_fraction_as_multiply, Info) :-
    misconception_registry_entry(divide_by_unit_fraction_as_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_by_unit_fraction_as_multiply, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U6-L3', Operation, divide_larger_by_smaller, Info) :-
    misconception_registry_entry(divide_larger_by_smaller, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_larger_by_smaller, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U6-L3', Operation, divide_to_find_decimal_of, Info) :-
    misconception_registry_entry(divide_to_find_decimal_of, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_to_find_decimal_of, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U6-L3', Operation, smaller_from_larger_in_column, Info) :-
    misconception_registry_entry(smaller_from_larger_in_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(smaller_from_larger_in_column, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U6-L3', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit6/lesson3.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U6-L4', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G5-U6-L4', division, share_into_divisor_groups, Info) :-
    strategy_info(division, share_into_divisor_groups, Info).
explicit_lesson_strategy('IM-G5-U6-L4', decimal, positional_decimal_reading, Info) :-
    strategy_info(decimal, positional_decimal_reading, Info).
explicit_lesson_misconception('IM-G5-U6-L4', Operation, share_smaller_into_larger, Info) :-
    misconception_registry_entry(share_smaller_into_larger, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_smaller_into_larger, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U6-L4', Operation, divide_larger_by_smaller, Info) :-
    misconception_registry_entry(divide_larger_by_smaller, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_larger_by_smaller, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U6-L4', Operation, always_larger_into_smaller, Info) :-
    misconception_registry_entry(always_larger_into_smaller, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(always_larger_into_smaller, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U6-L4', Operation, divide_to_find_decimal_of, Info) :-
    misconception_registry_entry(divide_to_find_decimal_of, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_to_find_decimal_of, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U6-L4', Operation, multiply_when_divisor_is_decimal, Info) :-
    misconception_registry_entry(multiply_when_divisor_is_decimal, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(multiply_when_divisor_is_decimal, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U6-L4', Operation, division_always_smaller, Info) :-
    misconception_registry_entry(division_always_smaller, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(division_always_smaller, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U6-L4', Operation, share_into_divisor_groups, Info) :-
    misconception_registry_entry(share_into_divisor_groups, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_into_divisor_groups, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U6-L4', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit6/lesson4.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U6-L5', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G5-U6-L5', division, measure_groups_of_size, Info) :-
    strategy_info(division, measure_groups_of_size, Info).
explicit_lesson_misconception('IM-G5-U6-L5', Operation, add_instead_of_multiply, Info) :-
    misconception_registry_entry(add_instead_of_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_multiply, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U6-L5', Operation, divide_larger_by_smaller, Info) :-
    misconception_registry_entry(divide_larger_by_smaller, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_larger_by_smaller, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U6-L5', Operation, divide_to_find_decimal_of, Info) :-
    misconception_registry_entry(divide_to_find_decimal_of, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_to_find_decimal_of, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U6-L5', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit6/lesson5.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U6-L6', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_misconception('IM-G5-U6-L6', Operation, fraction_of_as_division, Info) :-
    misconception_registry_entry(fraction_of_as_division, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(fraction_of_as_division, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U6-L6', Operation, divide_by_half_as_by_two, Info) :-
    misconception_registry_entry(divide_by_half_as_by_two, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_by_half_as_by_two, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U6-L6', Operation, whole_as_unit_fraction, Info) :-
    misconception_registry_entry(whole_as_unit_fraction, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(whole_as_unit_fraction, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U6-L6', Operation, divide_to_find_decimal_of, Info) :-
    misconception_registry_entry(divide_to_find_decimal_of, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_to_find_decimal_of, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U6-L6', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit6/lesson6.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U6-L7', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit6/lesson7.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U6-L8', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit6/lesson8.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U6-L9', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit6/lesson9.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U7-L1', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit7/lesson1.md'), Path, [access(read)]).

explicit_lesson_misconception('IM-G5-U7-L10', Operation, double_first_add_one, Info) :-
    misconception_registry_entry(double_first_add_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(double_first_add_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U7-L10', Operation, fraction_of_as_division, Info) :-
    misconception_registry_entry(fraction_of_as_division, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(fraction_of_as_division, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U7-L10', Operation, divide_by_half_as_by_two, Info) :-
    misconception_registry_entry(divide_by_half_as_by_two, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_by_half_as_by_two, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U7-L10', Operation, multiply_rule_on_add, Info) :-
    misconception_registry_entry(multiply_rule_on_add, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(multiply_rule_on_add, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U7-L10', Operation, divide_by_unit_fraction_as_multiply, Info) :-
    misconception_registry_entry(divide_by_unit_fraction_as_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_by_unit_fraction_as_multiply, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U7-L10', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit7/lesson10.md'), Path, [access(read)]).

explicit_lesson_misconception('IM-G5-U7-L11', Operation, double_first_add_one, Info) :-
    misconception_registry_entry(double_first_add_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(double_first_add_one, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U7-L11', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit7/lesson11.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U7-L12', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U7-L12', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit7/lesson12.md'), Path, [access(read)]).

explicit_lesson_misconception('IM-G5-U7-L13', Operation, add_instead_of_multiply, Info) :-
    misconception_registry_entry(add_instead_of_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_multiply, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U7-L13', Operation, multiply_rule_on_add, Info) :-
    misconception_registry_entry(multiply_rule_on_add, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(multiply_rule_on_add, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U7-L13', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit7/lesson13.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U7-L14', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit7/lesson14.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U7-L2', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit7/lesson2.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U7-L3', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit7/lesson3.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U7-L4', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit7/lesson4.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U7-L5', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit7/lesson5.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U7-L6', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit7/lesson6.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U7-L7', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit7/lesson7.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U7-L8', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit7/lesson8.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U7-L9', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit7/lesson9.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U8-L1', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G5-U8-L1', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G5-U8-L1', addition, column_addition_with_carrying, Info) :-
    strategy_info(addition, column_addition_with_carrying, Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U8-L1', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit8/lesson1.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U8-L10', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit8/lesson10.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U8-L11', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit8/lesson11.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U8-L12', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G5-U8-L12', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U8-L12', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit8/lesson12.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U8-L13', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit8/lesson13.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U8-L14', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit8/lesson14.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U8-L15', addition, column_addition_with_carrying, Info) :-
    strategy_info(addition, column_addition_with_carrying, Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U8-L15', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit8/lesson15.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U8-L16', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_misconception('IM-G5-U8-L16', Operation, double_first_add_one, Info) :-
    misconception_registry_entry(double_first_add_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(double_first_add_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U8-L16', Operation, adjust_dividend_for_division, Info) :-
    misconception_registry_entry(adjust_dividend_for_division, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(adjust_dividend_for_division, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U8-L16', Operation, adjust_to_make_smaller, Info) :-
    misconception_registry_entry(adjust_to_make_smaller, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(adjust_to_make_smaller, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U8-L16', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit8/lesson16.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U8-L17', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit8/lesson17.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U8-L18', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit8/lesson18.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U8-L2', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G5-U8-L2', addition, column_addition_with_carrying, Info) :-
    strategy_info(addition, column_addition_with_carrying, Info).
explicit_lesson_misconception('IM-G5-U8-L2', Operation, partial_products_no_shift, Info) :-
    misconception_registry_entry(partial_products_no_shift, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(partial_products_no_shift, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U8-L2', Operation, partial_products_no_place_shift, Info) :-
    misconception_registry_entry(partial_products_no_place_shift, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(partial_products_no_place_shift, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U8-L2', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit8/lesson2.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U8-L3', addition, column_addition_with_carrying, Info) :-
    strategy_info(addition, column_addition_with_carrying, Info).
explicit_lesson_misconception('IM-G5-U8-L3', Operation, double_first_add_one, Info) :-
    misconception_registry_entry(double_first_add_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(double_first_add_one, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U8-L3', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit8/lesson3.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U8-L4', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G5-U8-L4', division, share_into_divisor_groups, Info) :-
    strategy_info(division, share_into_divisor_groups, Info).
explicit_lesson_misconception('IM-G5-U8-L4', Operation, share_into_divisor_groups, Info) :-
    misconception_registry_entry(share_into_divisor_groups, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_into_divisor_groups, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U8-L4', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit8/lesson4.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U8-L5', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_misconception('IM-G5-U8-L5', Operation, divide_larger_by_smaller, Info) :-
    misconception_registry_entry(divide_larger_by_smaller, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_larger_by_smaller, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U8-L5', Operation, division_must_be_smaller, Info) :-
    misconception_registry_entry(division_must_be_smaller, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(division_must_be_smaller, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U8-L5', Operation, division_always_smaller, Info) :-
    misconception_registry_entry(division_always_smaller, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(division_always_smaller, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U8-L5', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit8/lesson5.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U8-L6', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit8/lesson6.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U8-L7', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-G5-U8-L7', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G5-U8-L7', division, measure_groups_of_size, Info) :-
    strategy_info(division, measure_groups_of_size, Info).
explicit_lesson_misconception('IM-G5-U8-L7', Operation, count_on_off_by_one, Info) :-
    misconception_registry_entry(count_on_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_on_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U8-L7', Operation, whole_as_unit_fraction, Info) :-
    misconception_registry_entry(whole_as_unit_fraction, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(whole_as_unit_fraction, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U8-L7', Operation, divide_by_unit_fraction_as_multiply, Info) :-
    misconception_registry_entry(divide_by_unit_fraction_as_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_by_unit_fraction_as_multiply, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U8-L7', Operation, divide_to_find_decimal_of, Info) :-
    misconception_registry_entry(divide_to_find_decimal_of, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_to_find_decimal_of, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U8-L7', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U8-L7', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit8/lesson7.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G5-U8-L8', addition, column_addition_with_carrying, Info) :-
    strategy_info(addition, column_addition_with_carrying, Info).
explicit_lesson_misconception('IM-G5-U8-L8', Operation, add_instead_of_multiply, Info) :-
    misconception_registry_entry(add_instead_of_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_multiply, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G5-U8-L8', Operation, raw_quotient_with_remainder, Info) :-
    misconception_registry_entry(raw_quotient_with_remainder, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(raw_quotient_with_remainder, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G5-U8-L8', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit8/lesson8.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G5-U8-L9', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade5/unit8/lesson9.md'), Path, [access(read)]).
