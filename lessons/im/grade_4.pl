% lessons/im/grade_4.pl - Strategy/misconception facts for grade 4
:- multifile explicit_lesson_strategy/4.
:- discontiguous explicit_lesson_strategy/4.
:- multifile explicit_lesson_misconception/4.
:- discontiguous explicit_lesson_misconception/4.
:- multifile text_interpreter:explicit_lesson_text_source/2.
:- discontiguous text_interpreter:explicit_lesson_text_source/2.

text_interpreter:explicit_lesson_text_source('IM-G4-U1-L1', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit1/lesson1.md'), Path, [access(read)]).

explicit_lesson_misconception('IM-G4-U1-L2', Operation, double_first_add_one, Info) :-
    misconception_registry_entry(double_first_add_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(double_first_add_one, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U1-L2', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit1/lesson2.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U1-L3', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_misconception('IM-G4-U1-L3', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U1-L3', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit1/lesson3.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U1-L4', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G4-U1-L4', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G4-U1-L4', multiplication, multiplication_fact_retrieval, Info) :-
    strategy_info(multiplication, multiplication_fact_retrieval, Info).
explicit_lesson_misconception('IM-G4-U1-L4', Operation, share_smaller_into_larger, Info) :-
    misconception_registry_entry(share_smaller_into_larger, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_smaller_into_larger, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U1-L4', Operation, double_first_add_one, Info) :-
    misconception_registry_entry(double_first_add_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(double_first_add_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U1-L4', Operation, fraction_of_as_division, Info) :-
    misconception_registry_entry(fraction_of_as_division, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(fraction_of_as_division, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U1-L4', Operation, whole_as_unit_fraction, Info) :-
    misconception_registry_entry(whole_as_unit_fraction, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(whole_as_unit_fraction, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U1-L4', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit1/lesson4.md'), Path, [access(read)]).

explicit_lesson_misconception('IM-G4-U1-L5', Operation, fraction_of_as_division, Info) :-
    misconception_registry_entry(fraction_of_as_division, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(fraction_of_as_division, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U1-L5', Operation, whole_as_unit_fraction, Info) :-
    misconception_registry_entry(whole_as_unit_fraction, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(whole_as_unit_fraction, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U1-L5', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit1/lesson5.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U1-L6', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-G4-U1-L6', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G4-U1-L6', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G4-U1-L6', multiplication, repeat_group_size_by_itself, Info) :-
    strategy_info(multiplication, repeat_group_size_by_itself, Info).
explicit_lesson_misconception('IM-G4-U1-L6', Operation, fraction_of_as_division, Info) :-
    misconception_registry_entry(fraction_of_as_division, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(fraction_of_as_division, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U1-L6', Operation, divide_by_half_as_by_two, Info) :-
    misconception_registry_entry(divide_by_half_as_by_two, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_by_half_as_by_two, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U1-L6', Operation, whole_as_unit_fraction, Info) :-
    misconception_registry_entry(whole_as_unit_fraction, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(whole_as_unit_fraction, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U1-L6', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U1-L6', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit1/lesson6.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U1-L7', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G4-U1-L7', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G4-U1-L7', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_misconception('IM-G4-U1-L7', Operation, fraction_of_as_division, Info) :-
    misconception_registry_entry(fraction_of_as_division, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(fraction_of_as_division, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U1-L7', Operation, whole_as_unit_fraction, Info) :-
    misconception_registry_entry(whole_as_unit_fraction, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(whole_as_unit_fraction, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U1-L7', Operation, divide_larger_by_smaller, Info) :-
    misconception_registry_entry(divide_larger_by_smaller, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_larger_by_smaller, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U1-L7', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit1/lesson7.md'), Path, [access(read)]).

explicit_lesson_misconception('IM-G4-U1-L8', Operation, whole_as_unit_fraction, Info) :-
    misconception_registry_entry(whole_as_unit_fraction, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(whole_as_unit_fraction, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U1-L8', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit1/lesson8.md'), Path, [access(read)]).

explicit_lesson_misconception('IM-G4-U2-L1', Operation, whole_as_unit_fraction, Info) :-
    misconception_registry_entry(whole_as_unit_fraction, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(whole_as_unit_fraction, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U2-L1', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit2/lesson1.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U2-L10', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U2-L10', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit2/lesson10.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U2-L11', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G4-U2-L11', fraction, unit_fraction_iteration, Info) :-
    strategy_info(fraction, unit_fraction_iteration, Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U2-L11', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit2/lesson11.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U2-L12', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G4-U2-L12', fraction, unit_fraction_iteration, Info) :-
    strategy_info(fraction, unit_fraction_iteration, Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U2-L12', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit2/lesson12.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U2-L13', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U2-L13', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit2/lesson13.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U2-L14', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U2-L14', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit2/lesson14.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U2-L15', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U2-L15', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit2/lesson15.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U2-L16', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit2/lesson16.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U2-L17', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_misconception('IM-G4-U2-L17', Operation, whole_as_unit_fraction, Info) :-
    misconception_registry_entry(whole_as_unit_fraction, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(whole_as_unit_fraction, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U2-L17', Operation, multiply_rule_on_add, Info) :-
    misconception_registry_entry(multiply_rule_on_add, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(multiply_rule_on_add, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U2-L17', Operation, add_denominators_unit_fractions, Info) :-
    misconception_registry_entry(add_denominators_unit_fractions, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_denominators_unit_fractions, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U2-L17', Operation, no_borrow_across_point, Info) :-
    misconception_registry_entry(no_borrow_across_point, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(no_borrow_across_point, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U2-L17', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit2/lesson17.md'), Path, [access(read)]).

explicit_lesson_misconception('IM-G4-U2-L2', Operation, whole_as_unit_fraction, Info) :-
    misconception_registry_entry(whole_as_unit_fraction, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(whole_as_unit_fraction, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U2-L2', Operation, add_denominators_unit_fractions, Info) :-
    misconception_registry_entry(add_denominators_unit_fractions, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_denominators_unit_fractions, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U2-L2', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit2/lesson2.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U2-L3', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit2/lesson3.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U2-L4', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U2-L4', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit2/lesson4.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U2-L5', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U2-L5', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit2/lesson5.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U2-L6', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G4-U2-L6', fraction, co_denominator_count_on_from_larger, Info) :-
    strategy_info(fraction, co_denominator_count_on_from_larger, Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U2-L6', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit2/lesson6.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U2-L7', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G4-U2-L7', fraction, unit_fraction_iteration, Info) :-
    strategy_info(fraction, unit_fraction_iteration, Info).
explicit_lesson_strategy('IM-G4-U2-L7', fraction, co_denominator_count_on_from_larger, Info) :-
    strategy_info(fraction, co_denominator_count_on_from_larger, Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U2-L7', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit2/lesson7.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U2-L8', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U2-L8', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit2/lesson8.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U2-L9', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U2-L9', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit2/lesson9.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U3-L1', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G4-U3-L1', fraction, unit_fraction_iteration, Info) :-
    strategy_info(fraction, unit_fraction_iteration, Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U3-L1', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit3/lesson1.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U3-L10', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G4-U3-L10', fraction, unit_fraction_iteration, Info) :-
    strategy_info(fraction, unit_fraction_iteration, Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U3-L10', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit3/lesson10.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U3-L11', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U3-L11', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit3/lesson11.md'), Path, [access(read)]).

% IM-G4-U3-L8 section 8.2 "What is the Sum?" (1/8 + 9/8, 11/8 + 9/8): iterating eighths
% past one whole is the productive improper_fraction_iteration. The chain-loss deformation
% (resetting the running total at each whole instead of accumulating) is registry/canon
% licensed -- the guide task asks for equivalent forms, not an error, so no guide
% attestation is claimed. improper_fraction_chain_loss has no misconception_registry_entry,
% so it licenses through the strategy route (action_role reclassifies it as role=deformation).
explicit_lesson_strategy('IM-G4-U3-L8', fraction, improper_fraction_chain_loss, Info) :-
    strategy_info(fraction, improper_fraction_chain_loss, Info).

text_interpreter:explicit_lesson_text_source('IM-G4-U3-L12', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit3/lesson12.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U3-L13', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U3-L13', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit3/lesson13.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U3-L14', fraction, co_denominator_count_on_from_larger, Info) :-
    strategy_info(fraction, co_denominator_count_on_from_larger, Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U3-L14', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit3/lesson14.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U3-L15', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit3/lesson15.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U3-L16', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit3/lesson16.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U3-L17', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit3/lesson17.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U3-L18', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit3/lesson18.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U3-L19', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit3/lesson19.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U3-L2', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G4-U3-L2', fraction, unit_fraction_iteration, Info) :-
    strategy_info(fraction, unit_fraction_iteration, Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U3-L2', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit3/lesson2.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U3-L20', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit3/lesson20.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U3-L3', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G4-U3-L3', fraction, unit_fraction_iteration, Info) :-
    strategy_info(fraction, unit_fraction_iteration, Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U3-L3', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit3/lesson3.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U3-L4', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G4-U3-L4', fraction, unit_fraction_iteration, Info) :-
    strategy_info(fraction, unit_fraction_iteration, Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U3-L4', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit3/lesson4.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U3-L5', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G4-U3-L5', fraction, unit_fraction_iteration, Info) :-
    strategy_info(fraction, unit_fraction_iteration, Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U3-L5', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit3/lesson5.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U3-L6', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G4-U3-L6', fraction, unit_fraction_iteration, Info) :-
    strategy_info(fraction, unit_fraction_iteration, Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U3-L6', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit3/lesson6.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U3-L7', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G4-U3-L7', fraction, unit_fraction_iteration, Info) :-
    strategy_info(fraction, unit_fraction_iteration, Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U3-L7', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit3/lesson7.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U3-L8', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit3/lesson8.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U3-L9', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
explicit_lesson_strategy('IM-G4-U3-L9', fraction, unit_fraction_iteration, Info) :-
    strategy_info(fraction, unit_fraction_iteration, Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U3-L9', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit3/lesson9.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U4-L1', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit4/lesson1.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U4-L10', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G4-U4-L10', addition, column_addition_with_carrying, Info) :-
    strategy_info(addition, column_addition_with_carrying, Info).
explicit_lesson_strategy('IM-G4-U4-L10', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G4-U4-L10', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
explicit_lesson_misconception('IM-G4-U4-L10', Operation, add_denominators_unit_fractions, Info) :-
    misconception_registry_entry(add_denominators_unit_fractions, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_denominators_unit_fractions, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U4-L10', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit4/lesson10.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U4-L11', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G4-U4-L11', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G4-U4-L11', subtraction, take_away_base_ones, Info) :-
    strategy_info(subtraction, take_away_base_ones, Info).
explicit_lesson_misconception('IM-G4-U4-L11', Operation, fraction_of_as_division, Info) :-
    misconception_registry_entry(fraction_of_as_division, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(fraction_of_as_division, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U4-L11', Operation, whole_as_unit_fraction, Info) :-
    misconception_registry_entry(whole_as_unit_fraction, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(whole_as_unit_fraction, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U4-L11', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit4/lesson11.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U4-L12', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G4-U4-L12', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U4-L12', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit4/lesson12.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U4-L13', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G4-U4-L13', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G4-U4-L13', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U4-L13', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit4/lesson13.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U4-L14', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G4-U4-L14', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U4-L14', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit4/lesson14.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U4-L15', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G4-U4-L15', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G4-U4-L15', addition, count_all_instead_of_known_fact, Info) :-
    strategy_info(addition, count_all_instead_of_known_fact, Info).
explicit_lesson_misconception('IM-G4-U4-L15', Operation, count_all_instead_of_known_fact, Info) :-
    misconception_registry_entry(count_all_instead_of_known_fact, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_instead_of_known_fact, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U4-L15', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit4/lesson15.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U4-L16', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G4-U4-L16', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G4-U4-L16', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G4-U4-L16', division, name_group_count_as_share_size, Info) :-
    strategy_info(division, name_group_count_as_share_size, Info).
explicit_lesson_misconception('IM-G4-U4-L16', Operation, name_group_count_as_share_size, Info) :-
    misconception_registry_entry(name_group_count_as_share_size, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(name_group_count_as_share_size, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U4-L16', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit4/lesson16.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U4-L17', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G4-U4-L17', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G4-U4-L17', subtraction, smaller_from_larger_in_column, Info) :-
    strategy_info(subtraction, smaller_from_larger_in_column, Info).
explicit_lesson_misconception('IM-G4-U4-L17', Operation, smaller_from_larger_each_column, Info) :-
    misconception_registry_entry(smaller_from_larger_each_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(smaller_from_larger_each_column, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U4-L17', Operation, smaller_from_larger_in_column, Info) :-
    misconception_registry_entry(smaller_from_larger_in_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(smaller_from_larger_in_column, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U4-L17', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit4/lesson17.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U4-L18', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G4-U4-L18', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G4-U4-L18', addition, column_addition_with_carrying, Info) :-
    strategy_info(addition, column_addition_with_carrying, Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U4-L18', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit4/lesson18.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U4-L19', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G4-U4-L19', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G4-U4-L19', addition, column_addition_with_carrying, Info) :-
    strategy_info(addition, column_addition_with_carrying, Info).
explicit_lesson_strategy('IM-G4-U4-L19', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
explicit_lesson_misconception('IM-G4-U4-L19', Operation, share_smaller_into_larger, Info) :-
    misconception_registry_entry(share_smaller_into_larger, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_smaller_into_larger, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U4-L19', Operation, whole_as_unit_fraction, Info) :-
    misconception_registry_entry(whole_as_unit_fraction, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(whole_as_unit_fraction, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U4-L19', Operation, adjust_to_make_smaller, Info) :-
    misconception_registry_entry(adjust_to_make_smaller, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(adjust_to_make_smaller, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U4-L19', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit4/lesson19.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U4-L2', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit4/lesson2.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U4-L20', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G4-U4-L20', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G4-U4-L20', addition, column_addition_with_carrying, Info) :-
    strategy_info(addition, column_addition_with_carrying, Info).
explicit_lesson_strategy('IM-G4-U4-L20', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_strategy('IM-G4-U4-L20', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
explicit_lesson_misconception('IM-G4-U4-L20', Operation, borrow_without_reducing_bases, Info) :-
    misconception_registry_entry(borrow_without_reducing_bases, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(borrow_without_reducing_bases, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U4-L20', Operation, smaller_from_larger_in_column, Info) :-
    misconception_registry_entry(smaller_from_larger_in_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(smaller_from_larger_in_column, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U4-L20', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit4/lesson20.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U4-L21', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G4-U4-L21', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G4-U4-L21', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G4-U4-L21', addition, column_addition_with_carrying, Info) :-
    strategy_info(addition, column_addition_with_carrying, Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U4-L21', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit4/lesson21.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U4-L22', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G4-U4-L22', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G4-U4-L22', addition, column_addition_with_carrying, Info) :-
    strategy_info(addition, column_addition_with_carrying, Info).
explicit_lesson_strategy('IM-G4-U4-L22', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U4-L22', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit4/lesson22.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U4-L23', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G4-U4-L23', addition, column_addition_with_carrying, Info) :-
    strategy_info(addition, column_addition_with_carrying, Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U4-L23', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit4/lesson23.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U4-L3', fraction, unit_fraction_partition, Info) :-
    strategy_info(fraction, unit_fraction_partition, Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U4-L3', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit4/lesson3.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U4-L4', fraction, co_denominator_count_on_from_larger, Info) :-
    strategy_info(fraction, co_denominator_count_on_from_larger, Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U4-L4', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit4/lesson4.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U4-L5', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit4/lesson5.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U4-L6', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_misconception('IM-G4-U4-L6', Operation, add_denominators_unit_fractions, Info) :-
    misconception_registry_entry(add_denominators_unit_fractions, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_denominators_unit_fractions, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U4-L6', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit4/lesson6.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U4-L7', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G4-U4-L7', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G4-U4-L7', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G4-U4-L7', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G4-U4-L7', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U4-L7', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit4/lesson7.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U4-L8', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G4-U4-L8', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-G4-U4-L8', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_misconception('IM-G4-U4-L8', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U4-L8', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit4/lesson8.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U4-L9', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_misconception('IM-G4-U4-L9', Operation, division_commutative, Info) :-
    misconception_registry_entry(division_commutative, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(division_commutative, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U4-L9', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit4/lesson9.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U5-L1', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit5/lesson1.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U5-L10', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit5/lesson10.md'), Path, [access(read)]).

explicit_lesson_misconception('IM-G4-U5-L11', Operation, share_smaller_into_larger, Info) :-
    misconception_registry_entry(share_smaller_into_larger, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_smaller_into_larger, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U5-L11', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit5/lesson11.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U5-L12', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_misconception('IM-G4-U5-L12', Operation, share_smaller_into_larger, Info) :-
    misconception_registry_entry(share_smaller_into_larger, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_smaller_into_larger, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U5-L12', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit5/lesson12.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U5-L13', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G4-U5-L13', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G4-U5-L13', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_misconception('IM-G4-U5-L13', Operation, whole_as_unit_fraction, Info) :-
    misconception_registry_entry(whole_as_unit_fraction, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(whole_as_unit_fraction, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U5-L13', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit5/lesson13.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U5-L14', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G4-U5-L14', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-G4-U5-L14', addition, make_base_transfer, Info) :-
    strategy_info(addition, make_base_transfer, Info).
explicit_lesson_strategy('IM-G4-U5-L14', subtraction, smaller_from_larger_in_column, Info) :-
    strategy_info(subtraction, smaller_from_larger_in_column, Info).
explicit_lesson_misconception('IM-G4-U5-L14', Operation, share_smaller_into_larger, Info) :-
    misconception_registry_entry(share_smaller_into_larger, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_smaller_into_larger, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U5-L14', Operation, smaller_from_larger_each_column, Info) :-
    misconception_registry_entry(smaller_from_larger_each_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(smaller_from_larger_each_column, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U5-L14', Operation, smaller_from_larger_in_column, Info) :-
    misconception_registry_entry(smaller_from_larger_in_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(smaller_from_larger_in_column, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U5-L14', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U5-L14', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit5/lesson14.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U5-L15', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_misconception('IM-G4-U5-L15', Operation, share_smaller_into_larger, Info) :-
    misconception_registry_entry(share_smaller_into_larger, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_smaller_into_larger, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U5-L15', Operation, divide_larger_by_smaller, Info) :-
    misconception_registry_entry(divide_larger_by_smaller, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_larger_by_smaller, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U5-L15', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit5/lesson15.md'), Path, [access(read)]).

explicit_lesson_misconception('IM-G4-U5-L16', Operation, whole_as_unit_fraction, Info) :-
    misconception_registry_entry(whole_as_unit_fraction, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(whole_as_unit_fraction, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U5-L16', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit5/lesson16.md'), Path, [access(read)]).

explicit_lesson_misconception('IM-G4-U5-L17', Operation, share_smaller_into_larger, Info) :-
    misconception_registry_entry(share_smaller_into_larger, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_smaller_into_larger, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U5-L17', Operation, divide_by_half_as_by_two, Info) :-
    misconception_registry_entry(divide_by_half_as_by_two, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_by_half_as_by_two, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U5-L17', Operation, whole_as_unit_fraction, Info) :-
    misconception_registry_entry(whole_as_unit_fraction, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(whole_as_unit_fraction, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U5-L17', Operation, divide_larger_by_smaller, Info) :-
    misconception_registry_entry(divide_larger_by_smaller, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_larger_by_smaller, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U5-L17', Operation, always_larger_into_smaller, Info) :-
    misconception_registry_entry(always_larger_into_smaller, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(always_larger_into_smaller, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U5-L17', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit5/lesson17.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U5-L18', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit5/lesson18.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U5-L2', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G4-U5-L2', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U5-L2', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit5/lesson2.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U5-L3', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G4-U5-L3', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U5-L3', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit5/lesson3.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U5-L4', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U5-L4', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit5/lesson4.md'), Path, [access(read)]).

explicit_lesson_misconception('IM-G4-U5-L5', Operation, add_instead_of_multiply, Info) :-
    misconception_registry_entry(add_instead_of_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_multiply, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U5-L5', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit5/lesson5.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U5-L6', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G4-U5-L6', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_misconception('IM-G4-U5-L6', Operation, share_smaller_into_larger, Info) :-
    misconception_registry_entry(share_smaller_into_larger, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_smaller_into_larger, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U5-L6', Operation, division_by_zero_numerical, Info) :-
    misconception_registry_entry(division_by_zero_numerical, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(division_by_zero_numerical, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U5-L6', Operation, always_larger_into_smaller, Info) :-
    misconception_registry_entry(always_larger_into_smaller, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(always_larger_into_smaller, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U5-L6', Operation, division_always_smaller, Info) :-
    misconception_registry_entry(division_always_smaller, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(division_always_smaller, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U5-L6', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit5/lesson6.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U5-L7', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit5/lesson7.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U5-L8', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit5/lesson8.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U5-L9', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit5/lesson9.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U6-L1', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G4-U6-L1', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G4-U6-L1', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G4-U6-L1', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G4-U6-L1', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G4-U6-L1', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
explicit_lesson_misconception('IM-G4-U6-L1', Operation, double_first_add_one, Info) :-
    misconception_registry_entry(double_first_add_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(double_first_add_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L1', Operation, multiply_rule_on_add, Info) :-
    misconception_registry_entry(multiply_rule_on_add, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(multiply_rule_on_add, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U6-L1', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit6/lesson1.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U6-L10', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_misconception('IM-G4-U6-L10', Operation, add_instead_of_multiply, Info) :-
    misconception_registry_entry(add_instead_of_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_multiply, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U6-L10', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit6/lesson10.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U6-L11', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G4-U6-L11', addition, column_addition_with_carrying, Info) :-
    strategy_info(addition, column_addition_with_carrying, Info).
explicit_lesson_strategy('IM-G4-U6-L11', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
explicit_lesson_misconception('IM-G4-U6-L11', Operation, add_instead_of_multiply, Info) :-
    misconception_registry_entry(add_instead_of_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_multiply, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U6-L11', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit6/lesson11.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U6-L12', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U6-L12', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit6/lesson12.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U6-L13', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G4-U6-L13', division, share_into_divisor_groups, Info) :-
    strategy_info(division, share_into_divisor_groups, Info).
explicit_lesson_strategy('IM-G4-U6-L13', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
explicit_lesson_misconception('IM-G4-U6-L13', Operation, share_into_divisor_groups, Info) :-
    misconception_registry_entry(share_into_divisor_groups, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_into_divisor_groups, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U6-L13', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit6/lesson13.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U6-L14', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G4-U6-L14', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G4-U6-L14', division, share_into_divisor_groups, Info) :-
    strategy_info(division, share_into_divisor_groups, Info).
explicit_lesson_misconception('IM-G4-U6-L14', Operation, add_instead_of_multiply, Info) :-
    misconception_registry_entry(add_instead_of_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_multiply, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L14', Operation, raw_quotient_with_remainder, Info) :-
    misconception_registry_entry(raw_quotient_with_remainder, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(raw_quotient_with_remainder, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L14', Operation, count_on_off_by_one, Info) :-
    misconception_registry_entry(count_on_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_on_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L14', Operation, fraction_of_as_division, Info) :-
    misconception_registry_entry(fraction_of_as_division, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(fraction_of_as_division, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L14', Operation, whole_as_unit_fraction, Info) :-
    misconception_registry_entry(whole_as_unit_fraction, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(whole_as_unit_fraction, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L14', Operation, divide_by_unit_fraction_as_multiply, Info) :-
    misconception_registry_entry(divide_by_unit_fraction_as_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_by_unit_fraction_as_multiply, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L14', Operation, division_must_be_smaller, Info) :-
    misconception_registry_entry(division_must_be_smaller, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(division_must_be_smaller, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L14', Operation, share_into_divisor_groups, Info) :-
    misconception_registry_entry(share_into_divisor_groups, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_into_divisor_groups, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U6-L14', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit6/lesson14.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U6-L15', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G4-U6-L15', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
explicit_lesson_strategy('IM-G4-U6-L15', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G4-U6-L15', division, share_into_divisor_groups, Info) :-
    strategy_info(division, share_into_divisor_groups, Info).
explicit_lesson_strategy('IM-G4-U6-L15', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
explicit_lesson_misconception('IM-G4-U6-L15', Operation, share_smaller_into_larger, Info) :-
    misconception_registry_entry(share_smaller_into_larger, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_smaller_into_larger, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L15', Operation, fraction_of_as_division, Info) :-
    misconception_registry_entry(fraction_of_as_division, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(fraction_of_as_division, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L15', Operation, whole_as_unit_fraction, Info) :-
    misconception_registry_entry(whole_as_unit_fraction, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(whole_as_unit_fraction, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L15', Operation, divide_by_unit_fraction_as_multiply, Info) :-
    misconception_registry_entry(divide_by_unit_fraction_as_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_by_unit_fraction_as_multiply, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L15', Operation, divide_larger_by_smaller, Info) :-
    misconception_registry_entry(divide_larger_by_smaller, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_larger_by_smaller, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L15', Operation, share_into_divisor_groups, Info) :-
    misconception_registry_entry(share_into_divisor_groups, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_into_divisor_groups, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U6-L15', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit6/lesson15.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U6-L16', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G4-U6-L16', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
explicit_lesson_strategy('IM-G4-U6-L16', subtraction, smaller_from_larger_in_column, Info) :-
    strategy_info(subtraction, smaller_from_larger_in_column, Info).
explicit_lesson_strategy('IM-G4-U6-L16', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G4-U6-L16', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
explicit_lesson_misconception('IM-G4-U6-L16', Operation, share_smaller_into_larger, Info) :-
    misconception_registry_entry(share_smaller_into_larger, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_smaller_into_larger, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L16', Operation, raw_quotient_with_remainder, Info) :-
    misconception_registry_entry(raw_quotient_with_remainder, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(raw_quotient_with_remainder, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L16', Operation, smaller_from_larger_each_column, Info) :-
    misconception_registry_entry(smaller_from_larger_each_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(smaller_from_larger_each_column, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L16', Operation, fraction_of_as_division, Info) :-
    misconception_registry_entry(fraction_of_as_division, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(fraction_of_as_division, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L16', Operation, whole_as_unit_fraction, Info) :-
    misconception_registry_entry(whole_as_unit_fraction, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(whole_as_unit_fraction, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L16', Operation, divide_by_unit_fraction_as_multiply, Info) :-
    misconception_registry_entry(divide_by_unit_fraction_as_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_by_unit_fraction_as_multiply, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L16', Operation, divide_larger_by_smaller, Info) :-
    misconception_registry_entry(divide_larger_by_smaller, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_larger_by_smaller, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L16', Operation, smaller_from_larger_in_column, Info) :-
    misconception_registry_entry(smaller_from_larger_in_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(smaller_from_larger_in_column, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U6-L16', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit6/lesson16.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U6-L17', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G4-U6-L17', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
explicit_lesson_strategy('IM-G4-U6-L17', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G4-U6-L17', division, share_into_divisor_groups, Info) :-
    strategy_info(division, share_into_divisor_groups, Info).
explicit_lesson_strategy('IM-G4-U6-L17', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
explicit_lesson_strategy('IM-G4-U6-L17', division, partial_quotient_chunking, Info) :-
    strategy_info(division, partial_quotient_chunking, Info).
explicit_lesson_misconception('IM-G4-U6-L17', Operation, fraction_of_as_division, Info) :-
    misconception_registry_entry(fraction_of_as_division, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(fraction_of_as_division, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L17', Operation, add_across_unlike, Info) :-
    misconception_registry_entry(add_across_unlike, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_across_unlike, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L17', Operation, whole_as_unit_fraction, Info) :-
    misconception_registry_entry(whole_as_unit_fraction, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(whole_as_unit_fraction, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L17', Operation, divide_by_unit_fraction_as_multiply, Info) :-
    misconception_registry_entry(divide_by_unit_fraction_as_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_by_unit_fraction_as_multiply, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L17', Operation, share_into_divisor_groups, Info) :-
    misconception_registry_entry(share_into_divisor_groups, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_into_divisor_groups, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U6-L17', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit6/lesson17.md'), Path, [access(read)]).

explicit_lesson_misconception('IM-G4-U6-L18', Operation, add_instead_of_multiply, Info) :-
    misconception_registry_entry(add_instead_of_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_multiply, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L18', Operation, raw_quotient_with_remainder, Info) :-
    misconception_registry_entry(raw_quotient_with_remainder, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(raw_quotient_with_remainder, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L18', Operation, fraction_of_as_division, Info) :-
    misconception_registry_entry(fraction_of_as_division, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(fraction_of_as_division, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L18', Operation, whole_as_unit_fraction, Info) :-
    misconception_registry_entry(whole_as_unit_fraction, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(whole_as_unit_fraction, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L18', Operation, divide_by_unit_fraction_as_multiply, Info) :-
    misconception_registry_entry(divide_by_unit_fraction_as_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_by_unit_fraction_as_multiply, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L18', Operation, divide_larger_by_smaller, Info) :-
    misconception_registry_entry(divide_larger_by_smaller, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_larger_by_smaller, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U6-L18', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit6/lesson18.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U6-L19', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G4-U6-L19', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G4-U6-L19', division, share_into_divisor_groups, Info) :-
    strategy_info(division, share_into_divisor_groups, Info).
explicit_lesson_strategy('IM-G4-U6-L19', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
explicit_lesson_misconception('IM-G4-U6-L19', Operation, raw_quotient_with_remainder, Info) :-
    misconception_registry_entry(raw_quotient_with_remainder, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(raw_quotient_with_remainder, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L19', Operation, share_into_divisor_groups, Info) :-
    misconception_registry_entry(share_into_divisor_groups, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_into_divisor_groups, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U6-L19', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit6/lesson19.md'), Path, [access(read)]).

explicit_lesson_misconception('IM-G4-U6-L2', Operation, add_instead_of_multiply, Info) :-
    misconception_registry_entry(add_instead_of_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_multiply, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L2', Operation, multiply_rule_on_add, Info) :-
    misconception_registry_entry(multiply_rule_on_add, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(multiply_rule_on_add, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U6-L2', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit6/lesson2.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U6-L20', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G4-U6-L20', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G4-U6-L20', division, stop_after_first_partial_quotient, Info) :-
    strategy_info(division, stop_after_first_partial_quotient, Info).
explicit_lesson_misconception('IM-G4-U6-L20', Operation, raw_quotient_with_remainder, Info) :-
    misconception_registry_entry(raw_quotient_with_remainder, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(raw_quotient_with_remainder, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L20', Operation, divide_by_half_as_by_two, Info) :-
    misconception_registry_entry(divide_by_half_as_by_two, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_by_half_as_by_two, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L20', Operation, stop_after_first_partial_quotient, Info) :-
    misconception_registry_entry(stop_after_first_partial_quotient, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(stop_after_first_partial_quotient, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U6-L20', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit6/lesson20.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U6-L21', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G4-U6-L21', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G4-U6-L21', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G4-U6-L21', division, share_into_divisor_groups, Info) :-
    strategy_info(division, share_into_divisor_groups, Info).
explicit_lesson_strategy('IM-G4-U6-L21', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
explicit_lesson_misconception('IM-G4-U6-L21', Operation, share_smaller_into_larger, Info) :-
    misconception_registry_entry(share_smaller_into_larger, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_smaller_into_larger, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L21', Operation, add_instead_of_multiply, Info) :-
    misconception_registry_entry(add_instead_of_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_multiply, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L21', Operation, raw_quotient_with_remainder, Info) :-
    misconception_registry_entry(raw_quotient_with_remainder, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(raw_quotient_with_remainder, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L21', Operation, fraction_of_as_division, Info) :-
    misconception_registry_entry(fraction_of_as_division, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(fraction_of_as_division, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L21', Operation, whole_as_unit_fraction, Info) :-
    misconception_registry_entry(whole_as_unit_fraction, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(whole_as_unit_fraction, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L21', Operation, divide_by_unit_fraction_as_multiply, Info) :-
    misconception_registry_entry(divide_by_unit_fraction_as_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_by_unit_fraction_as_multiply, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L21', Operation, divide_larger_by_smaller, Info) :-
    misconception_registry_entry(divide_larger_by_smaller, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_larger_by_smaller, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L21', Operation, division_must_be_smaller, Info) :-
    misconception_registry_entry(division_must_be_smaller, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(division_must_be_smaller, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L21', Operation, share_into_divisor_groups, Info) :-
    misconception_registry_entry(share_into_divisor_groups, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_into_divisor_groups, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U6-L21', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit6/lesson21.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U6-L22', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit6/lesson22.md'), Path, [access(read)]).

explicit_lesson_misconception('IM-G4-U6-L23', Operation, share_smaller_into_larger, Info) :-
    misconception_registry_entry(share_smaller_into_larger, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_smaller_into_larger, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L23', Operation, divide_larger_by_smaller, Info) :-
    misconception_registry_entry(divide_larger_by_smaller, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_larger_by_smaller, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U6-L23', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit6/lesson23.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U6-L24', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G4-U6-L24', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G4-U6-L24', addition, column_addition_with_carrying, Info) :-
    strategy_info(addition, column_addition_with_carrying, Info).
explicit_lesson_strategy('IM-G4-U6-L24', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_misconception('IM-G4-U6-L24', Operation, add_instead_of_multiply, Info) :-
    misconception_registry_entry(add_instead_of_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_multiply, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L24', Operation, difference_interpreted_as_sum, Info) :-
    misconception_registry_entry(difference_interpreted_as_sum, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(difference_interpreted_as_sum, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L24', Operation, raw_quotient_with_remainder, Info) :-
    misconception_registry_entry(raw_quotient_with_remainder, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(raw_quotient_with_remainder, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U6-L24', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit6/lesson24.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U6-L25', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G4-U6-L25', addition, column_addition_with_carrying, Info) :-
    strategy_info(addition, column_addition_with_carrying, Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U6-L25', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit6/lesson25.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U6-L26', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G4-U6-L26', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G4-U6-L26', division, measure_groups_of_size, Info) :-
    strategy_info(division, measure_groups_of_size, Info).
explicit_lesson_strategy('IM-G4-U6-L26', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U6-L26', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit6/lesson26.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U6-L3', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G4-U6-L3', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G4-U6-L3', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G4-U6-L3', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U6-L3', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit6/lesson3.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U6-L4', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G4-U6-L4', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G4-U6-L4', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G4-U6-L4', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
explicit_lesson_misconception('IM-G4-U6-L4', Operation, double_first_add_one, Info) :-
    misconception_registry_entry(double_first_add_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(double_first_add_one, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U6-L4', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit6/lesson4.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U6-L5', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G4-U6-L5', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G4-U6-L5', subtraction, smaller_from_larger_in_column, Info) :-
    strategy_info(subtraction, smaller_from_larger_in_column, Info).
explicit_lesson_strategy('IM-G4-U6-L5', subtraction, add_instead_of_subtract_column, Info) :-
    strategy_info(subtraction, add_instead_of_subtract_column, Info).
explicit_lesson_strategy('IM-G4-U6-L5', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G4-U6-L5', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
explicit_lesson_misconception('IM-G4-U6-L5', Operation, share_smaller_into_larger, Info) :-
    misconception_registry_entry(share_smaller_into_larger, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_smaller_into_larger, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L5', Operation, add_instead_of_multiply, Info) :-
    misconception_registry_entry(add_instead_of_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_multiply, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L5', Operation, smaller_from_larger_each_column, Info) :-
    misconception_registry_entry(smaller_from_larger_each_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(smaller_from_larger_each_column, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L5', Operation, smaller_from_larger_in_column, Info) :-
    misconception_registry_entry(smaller_from_larger_in_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(smaller_from_larger_in_column, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L5', Operation, add_instead_of_subtract_column, Info) :-
    misconception_registry_entry(add_instead_of_subtract_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_subtract_column, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U6-L5', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit6/lesson5.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U6-L6', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G4-U6-L6', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G4-U6-L6', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
explicit_lesson_strategy('IM-G4-U6-L6', subtraction, smaller_from_larger_in_column, Info) :-
    strategy_info(subtraction, smaller_from_larger_in_column, Info).
explicit_lesson_misconception('IM-G4-U6-L6', Operation, share_smaller_into_larger, Info) :-
    misconception_registry_entry(share_smaller_into_larger, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_smaller_into_larger, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L6', Operation, add_instead_of_multiply, Info) :-
    misconception_registry_entry(add_instead_of_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_multiply, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L6', Operation, smaller_from_larger_each_column, Info) :-
    misconception_registry_entry(smaller_from_larger_each_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(smaller_from_larger_each_column, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U6-L6', Operation, smaller_from_larger_in_column, Info) :-
    misconception_registry_entry(smaller_from_larger_in_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(smaller_from_larger_in_column, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U6-L6', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit6/lesson6.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U6-L7', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G4-U6-L7', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U6-L7', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit6/lesson7.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U6-L8', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G4-U6-L8', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U6-L8', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit6/lesson8.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U6-L9', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G4-U6-L9', addition, column_addition_with_carrying, Info) :-
    strategy_info(addition, column_addition_with_carrying, Info).
explicit_lesson_strategy('IM-G4-U6-L9', subtraction, take_away_base_ones, Info) :-
    strategy_info(subtraction, take_away_base_ones, Info).
explicit_lesson_strategy('IM-G4-U6-L9', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
explicit_lesson_misconception('IM-G4-U6-L9', Operation, share_smaller_into_larger, Info) :-
    misconception_registry_entry(share_smaller_into_larger, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_smaller_into_larger, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U6-L9', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit6/lesson9.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U7-L1', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit7/lesson1.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U7-L10', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G4-U7-L10', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G4-U7-L10', division, measure_groups_of_size, Info) :-
    strategy_info(division, measure_groups_of_size, Info).
explicit_lesson_strategy('IM-G4-U7-L10', division, share_into_divisor_groups, Info) :-
    strategy_info(division, share_into_divisor_groups, Info).
explicit_lesson_misconception('IM-G4-U7-L10', Operation, share_into_divisor_groups, Info) :-
    misconception_registry_entry(share_into_divisor_groups, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_into_divisor_groups, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U7-L10', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit7/lesson10.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U7-L11', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit7/lesson11.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U7-L12', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit7/lesson12.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U7-L13', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit7/lesson13.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U7-L14', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit7/lesson14.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U7-L15', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit7/lesson15.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U7-L16', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit7/lesson16.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U7-L2', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit7/lesson2.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U7-L3', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit7/lesson3.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U7-L4', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit7/lesson4.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U7-L5', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit7/lesson5.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U7-L6', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit7/lesson6.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U7-L7', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit7/lesson7.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U7-L8', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit7/lesson8.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U7-L9', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_strategy('IM-G4-U7-L9', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G4-U7-L9', division, measure_groups_of_size, Info) :-
    strategy_info(division, measure_groups_of_size, Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U7-L9', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit7/lesson9.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U8-L1', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit8/lesson1.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U8-L10', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit8/lesson10.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U8-L11', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit8/lesson11.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U8-L2', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit8/lesson2.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U8-L3', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit8/lesson3.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U8-L4', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit8/lesson4.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U8-L5', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit8/lesson5.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U8-L6', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit8/lesson6.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U8-L7', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit8/lesson7.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U8-L8', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit8/lesson8.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U8-L9', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit8/lesson9.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U9-L1', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit9/lesson1.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U9-L10', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit9/lesson10.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U9-L11', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U9-L11', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit9/lesson11.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U9-L12', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G4-U9-L12', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G4-U9-L12', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
explicit_lesson_strategy('IM-G4-U9-L12', division, share_into_divisor_groups, Info) :-
    strategy_info(division, share_into_divisor_groups, Info).
explicit_lesson_strategy('IM-G4-U9-L12', division, missing_factor_repeated_addition, Info) :-
    strategy_info(division, missing_factor_repeated_addition, Info).
explicit_lesson_misconception('IM-G4-U9-L12', Operation, add_instead_of_multiply, Info) :-
    misconception_registry_entry(add_instead_of_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_multiply, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U9-L12', Operation, adjust_dividend_for_division, Info) :-
    misconception_registry_entry(adjust_dividend_for_division, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(adjust_dividend_for_division, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U9-L12', Operation, fraction_of_as_division, Info) :-
    misconception_registry_entry(fraction_of_as_division, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(fraction_of_as_division, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U9-L12', Operation, whole_as_unit_fraction, Info) :-
    misconception_registry_entry(whole_as_unit_fraction, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(whole_as_unit_fraction, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U9-L12', Operation, divide_by_unit_fraction_as_multiply, Info) :-
    misconception_registry_entry(divide_by_unit_fraction_as_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_by_unit_fraction_as_multiply, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U9-L12', Operation, share_into_divisor_groups, Info) :-
    misconception_registry_entry(share_into_divisor_groups, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_into_divisor_groups, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U9-L12', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit9/lesson12.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U9-L2', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit9/lesson2.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U9-L3', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit9/lesson3.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U9-L4', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G4-U9-L4', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-G4-U9-L4', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-G4-U9-L4', addition, column_addition_with_carrying, Info) :-
    strategy_info(addition, column_addition_with_carrying, Info).
explicit_lesson_strategy('IM-G4-U9-L4', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_strategy('IM-G4-U9-L4', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
explicit_lesson_misconception('IM-G4-U9-L4', Operation, difference_interpreted_as_sum, Info) :-
    misconception_registry_entry(difference_interpreted_as_sum, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(difference_interpreted_as_sum, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U9-L4', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit9/lesson4.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U9-L5', multiplication, distribute_group_size_split, Info) :-
    strategy_info(multiplication, distribute_group_size_split, Info).
explicit_lesson_strategy('IM-G4-U9-L5', multiplication, regroup_to_base_preserving_total, Info) :-
    strategy_info(multiplication, regroup_to_base_preserving_total, Info).
explicit_lesson_strategy('IM-G4-U9-L5', multiplication, multiplication_fact_retrieval, Info) :-
    strategy_info(multiplication, multiplication_fact_retrieval, Info).
explicit_lesson_misconception('IM-G4-U9-L5', Operation, drop_second_partial_product, Info) :-
    misconception_registry_entry(drop_second_partial_product, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(drop_second_partial_product, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U9-L5', Operation, drop_regrouping_remainder, Info) :-
    misconception_registry_entry(drop_regrouping_remainder, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(drop_regrouping_remainder, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U9-L5', Operation, context_free_fact_family_guess, Info) :-
    misconception_registry_entry(context_free_fact_family_guess, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(context_free_fact_family_guess, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U9-L5', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit9/lesson5.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U9-L6', division, partial_quotient_chunking, Info) :-
    strategy_info(division, partial_quotient_chunking, Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U9-L6', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit9/lesson6.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U9-L7', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G4-U9-L7', decimal, positional_decimal_reading, Info) :-
    strategy_info(decimal, positional_decimal_reading, Info).
explicit_lesson_misconception('IM-G4-U9-L7', Operation, divide_by_half_as_by_two, Info) :-
    misconception_registry_entry(divide_by_half_as_by_two, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_by_half_as_by_two, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U9-L7', Operation, divide_to_find_decimal_of, Info) :-
    misconception_registry_entry(divide_to_find_decimal_of, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_to_find_decimal_of, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U9-L7', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit9/lesson7.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-G4-U9-L8', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-G4-U9-L8', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_strategy('IM-G4-U9-L8', division, fair_share_equal_groups, Info) :-
    strategy_info(division, fair_share_equal_groups, Info).
explicit_lesson_misconception('IM-G4-U9-L8', Operation, raw_quotient_with_remainder, Info) :-
    misconception_registry_entry(raw_quotient_with_remainder, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(raw_quotient_with_remainder, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-G4-U9-L8', Operation, division_story_as_multiplication, Info) :-
    misconception_registry_entry(division_story_as_multiplication, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(division_story_as_multiplication, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-G4-U9-L8', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit9/lesson8.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-G4-U9-L9', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/grade4/unit9/lesson9.md'), Path, [access(read)]).

% Source-attested deformation licenses (2026-07-11 license expansion).
% The teacher guide's anticipated-error prose licenses a registered deformation;
% the paired reviewed_task_instances entry supplies the operands and source line.
% IM-G4-U3-L1 guide: "If students write addition expressions to represent" (Clare's
% eggs: 3 baskets, 4 eggs each -- an equal-groups task, so add-instead-of-multiply fits).
explicit_lesson_misconception('IM-G4-U3-L1', Operation, add_instead_of_multiply, Info) :-
    misconception_registry_entry(add_instead_of_multiply, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(add_instead_of_multiply, Citation, Commitment, EntitlementLacked, [], Info).
% IM-G4-U5-L1 and IM-G4-U5-L2 are multiplicative-comparison lessons ("3 times as many
% as 2"); their additive error is a comparison-structure error, not equal-groups
% add-instead-of-multiply, and their charts already carry the factor-relation rows
% (commute_factors_preserve_product / rigid_factor_order_roles). Left on the worklist.
% IM-G4-U5-L3 guide: student represents "21 times as many as 3 books" -- names the
% reached total 21 as the multiplier/quotient. name_reached_total_as_quotient has no
% misconception_registry_entry, so it licenses through the strategy route (action_role
% reclassifies the deformation half as role=deformation), matching the grade_3 pattern.
explicit_lesson_strategy('IM-G4-U5-L3', division, name_reached_total_as_quotient, Info) :-
    strategy_info(division, name_reached_total_as_quotient, Info).
