% lessons/im/grade_k.pl - Strategy/misconception facts for grade k
:- multifile explicit_lesson_strategy/4.
:- discontiguous explicit_lesson_strategy/4.
:- multifile explicit_lesson_misconception/4.
:- discontiguous explicit_lesson_misconception/4.
:- multifile text_interpreter:explicit_lesson_text_source/2.
:- discontiguous text_interpreter:explicit_lesson_text_source/2.

text_interpreter:explicit_lesson_text_source('IM-GK-U1-L1', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit1/lesson1.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U1-L10', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit1/lesson10.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U1-L11', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit1/lesson11.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U1-L12', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-GK-U1-L12', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_misconception('IM-GK-U1-L12', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U1-L12', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit1/lesson12.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U1-L13', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-GK-U1-L13', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_misconception('IM-GK-U1-L13', Operation, count_on_off_by_one, Info) :-
    misconception_registry_entry(count_on_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_on_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-GK-U1-L13', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U1-L13', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit1/lesson13.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U1-L14', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-GK-U1-L14', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_misconception('IM-GK-U1-L14', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U1-L14', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit1/lesson14.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U1-L15', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-GK-U1-L15', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_misconception('IM-GK-U1-L15', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U1-L15', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit1/lesson15.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U1-L16', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U1-L16', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit1/lesson16.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U1-L17', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit1/lesson17.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U1-L2', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit1/lesson2.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U1-L3', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U1-L3', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit1/lesson3.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U1-L4', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit1/lesson4.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U1-L5', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit1/lesson5.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U1-L6', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U1-L6', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit1/lesson6.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U1-L7', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U1-L7', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit1/lesson7.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U1-L8', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit1/lesson8.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U1-L9', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit1/lesson9.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U2-L1', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-GK-U2-L1', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_misconception('IM-GK-U2-L1', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U2-L1', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit2/lesson1.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U2-L10', subtraction, compare_by_matching_difference, Info) :-
    strategy_info(subtraction, compare_by_matching_difference, Info).
explicit_lesson_misconception('IM-GK-U2-L10', Operation, count_on_off_by_one, Info) :-
    misconception_registry_entry(count_on_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_on_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U2-L10', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit2/lesson10.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U2-L11', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U2-L11', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit2/lesson11.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U2-L12', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U2-L12', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit2/lesson12.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U2-L13', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-GK-U2-L13', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_misconception('IM-GK-U2-L13', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U2-L13', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit2/lesson13.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U2-L14', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit2/lesson14.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U2-L15', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit2/lesson15.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U2-L16', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit2/lesson16.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U2-L17', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit2/lesson17.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U2-L18', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit2/lesson18.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U2-L19', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U2-L19', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit2/lesson19.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U2-L2', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-GK-U2-L2', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U2-L2', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit2/lesson2.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U2-L20', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit2/lesson20.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U2-L21', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-GK-U2-L21', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_misconception('IM-GK-U2-L21', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U2-L21', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit2/lesson21.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U2-L22', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit2/lesson22.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U2-L23', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit2/lesson23.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U2-L24', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit2/lesson24.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U2-L3', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-GK-U2-L3', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-GK-U2-L3', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U2-L3', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit2/lesson3.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U2-L4', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U2-L4', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit2/lesson4.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U2-L5', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-GK-U2-L5', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U2-L5', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit2/lesson5.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U2-L6', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit2/lesson6.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U2-L7', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U2-L7', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit2/lesson7.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U2-L8', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit2/lesson8.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U2-L9', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-GK-U2-L9', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-GK-U2-L9', addition, round_without_adjusting, Info) :-
    strategy_info(addition, round_without_adjusting, Info).
explicit_lesson_misconception('IM-GK-U2-L9', Operation, round_without_adjusting, Info) :-
    misconception_registry_entry(round_without_adjusting, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(round_without_adjusting, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U2-L9', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit2/lesson9.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U3-L1', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit3/lesson1.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U3-L10', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit3/lesson10.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U3-L11', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit3/lesson11.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U3-L12', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit3/lesson12.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U3-L13', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit3/lesson13.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U3-L14', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit3/lesson14.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U3-L15', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit3/lesson15.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U3-L2', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit3/lesson2.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U3-L3', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit3/lesson3.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U3-L4', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit3/lesson4.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U3-L5', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit3/lesson5.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U3-L6', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit3/lesson6.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U3-L7', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit3/lesson7.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U3-L8', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit3/lesson8.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U3-L9', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit3/lesson9.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U4-L1', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-GK-U4-L1', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_misconception('IM-GK-U4-L1', Operation, count_on_off_by_one, Info) :-
    misconception_registry_entry(count_on_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_on_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-GK-U4-L1', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U4-L1', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit4/lesson1.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U4-L10', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-GK-U4-L10', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_misconception('IM-GK-U4-L10', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U4-L10', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit4/lesson10.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U4-L11', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit4/lesson11.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U4-L12', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_misconception('IM-GK-U4-L12', Operation, minus_as_plus, Info) :-
    misconception_registry_entry(minus_as_plus, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(minus_as_plus, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U4-L12', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit4/lesson12.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U4-L13', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-GK-U4-L13', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_misconception('IM-GK-U4-L13', Operation, count_on_off_by_one, Info) :-
    misconception_registry_entry(count_on_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_on_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-GK-U4-L13', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U4-L13', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit4/lesson13.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U4-L14', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U4-L14', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit4/lesson14.md'), Path, [access(read)]).

explicit_lesson_misconception('IM-GK-U4-L15', Operation, minus_as_plus, Info) :-
    misconception_registry_entry(minus_as_plus, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(minus_as_plus, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U4-L15', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit4/lesson15.md'), Path, [access(read)]).

explicit_lesson_misconception('IM-GK-U4-L16', Operation, count_on_off_by_one, Info) :-
    misconception_registry_entry(count_on_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_on_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U4-L16', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit4/lesson16.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U4-L17', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-GK-U4-L17', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_misconception('IM-GK-U4-L17', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U4-L17', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit4/lesson17.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U4-L18', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-GK-U4-L18', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U4-L18', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit4/lesson18.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U4-L2', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-GK-U4-L2', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-GK-U4-L2', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_misconception('IM-GK-U4-L2', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U4-L2', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit4/lesson2.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U4-L3', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_misconception('IM-GK-U4-L3', Operation, count_on_off_by_one, Info) :-
    misconception_registry_entry(count_on_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_on_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-GK-U4-L3', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U4-L3', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit4/lesson3.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U4-L4', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-GK-U4-L4', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_misconception('IM-GK-U4-L4', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U4-L4', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit4/lesson4.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U4-L5', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U4-L5', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit4/lesson5.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U4-L6', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_misconception('IM-GK-U4-L6', Operation, count_back_off_by_one, Info) :-
    misconception_registry_entry(count_back_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_back_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-GK-U4-L6', Operation, count_on_off_by_one, Info) :-
    misconception_registry_entry(count_on_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_on_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-GK-U4-L6', Operation, minus_as_plus, Info) :-
    misconception_registry_entry(minus_as_plus, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(minus_as_plus, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U4-L6', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit4/lesson6.md'), Path, [access(read)]).

explicit_lesson_misconception('IM-GK-U4-L7', Operation, count_on_off_by_one, Info) :-
    misconception_registry_entry(count_on_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_on_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U4-L7', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit4/lesson7.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U4-L8', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_misconception('IM-GK-U4-L8', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U4-L8', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit4/lesson8.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U4-L9', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit4/lesson9.md'), Path, [access(read)]).

explicit_lesson_misconception('IM-GK-U5-L1', Operation, count_on_off_by_one, Info) :-
    misconception_registry_entry(count_on_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_on_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U5-L1', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit5/lesson1.md'), Path, [access(read)]).

% IM-GK-U5-L7 warm-up "Which One Doesn't Belong" (Red 5, Yellow 1): the productive
% compare_cardinalities_one_to_one contrasts the two collections. The spatial-extent
% substitution (judging "more" by how far a row reaches, ignoring one-to-one matching)
% is registry-licensed, not guide-attested for this lesson -- it is the counting-family
% deformation registered at corpus row 39409. It has no misconception_registry_entry, so
% it licenses through the strategy route (action_role reclassifies it as role=deformation).
explicit_lesson_strategy('IM-GK-U5-L7', counting, spatial_extent_as_cardinality, Info) :-
    strategy_info(counting, spatial_extent_as_cardinality, Info).

explicit_lesson_strategy('IM-GK-U5-L10', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U5-L10', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit5/lesson10.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U5-L11', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-GK-U5-L11', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U5-L11', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit5/lesson11.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U5-L12', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-GK-U5-L12', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U5-L12', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit5/lesson12.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U5-L13', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-GK-U5-L13', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U5-L13', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit5/lesson13.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U5-L14', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-GK-U5-L14', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_misconception('IM-GK-U5-L14', Operation, count_back_off_by_one, Info) :-
    misconception_registry_entry(count_back_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_back_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-GK-U5-L14', Operation, count_on_off_by_one, Info) :-
    misconception_registry_entry(count_on_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_on_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U5-L14', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit5/lesson14.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U5-L15', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit5/lesson15.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U5-L2', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit5/lesson2.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U5-L3', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit5/lesson3.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U5-L4', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_misconception('IM-GK-U5-L4', Operation, share_smaller_into_larger, Info) :-
    misconception_registry_entry(share_smaller_into_larger, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(share_smaller_into_larger, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-GK-U5-L4', Operation, count_back_off_by_one, Info) :-
    misconception_registry_entry(count_back_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_back_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-GK-U5-L4', Operation, count_on_off_by_one, Info) :-
    misconception_registry_entry(count_on_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_on_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U5-L4', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit5/lesson4.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U5-L5', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit5/lesson5.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U5-L6', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit5/lesson6.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U5-L7', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit5/lesson7.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U5-L8', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit5/lesson8.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U5-L9', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U5-L9', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit5/lesson9.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U6-L1', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-GK-U6-L1', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-GK-U6-L1', subtraction, smaller_from_larger_in_column, Info) :-
    strategy_info(subtraction, smaller_from_larger_in_column, Info).
explicit_lesson_misconception('IM-GK-U6-L1', Operation, smaller_from_larger_each_column, Info) :-
    misconception_registry_entry(smaller_from_larger_each_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(smaller_from_larger_each_column, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-GK-U6-L1', Operation, smaller_from_larger_in_column, Info) :-
    misconception_registry_entry(smaller_from_larger_in_column, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(smaller_from_larger_in_column, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-GK-U6-L1', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U6-L1', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit6/lesson1.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U6-L10', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-GK-U6-L10', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_misconception('IM-GK-U6-L10', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U6-L10', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit6/lesson10.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U6-L11', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-GK-U6-L11', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_misconception('IM-GK-U6-L11', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U6-L11', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit6/lesson11.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U6-L12', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-GK-U6-L12', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-GK-U6-L12', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-GK-U6-L12', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_misconception('IM-GK-U6-L12', Operation, count_on_off_by_one, Info) :-
    misconception_registry_entry(count_on_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_on_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-GK-U6-L12', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U6-L12', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit6/lesson12.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U6-L13', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit6/lesson13.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U6-L2', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-GK-U6-L2', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_misconception('IM-GK-U6-L2', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U6-L2', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit6/lesson2.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U6-L3', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit6/lesson3.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U6-L4', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-GK-U6-L4', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-GK-U6-L4', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U6-L4', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit6/lesson4.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U6-L5', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-GK-U6-L5', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U6-L5', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit6/lesson5.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U6-L6', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-GK-U6-L6', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_misconception('IM-GK-U6-L6', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U6-L6', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit6/lesson6.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U6-L7', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-GK-U6-L7', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_misconception('IM-GK-U6-L7', Operation, count_on_off_by_one, Info) :-
    misconception_registry_entry(count_on_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_on_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-GK-U6-L7', Operation, divide_by_half_as_by_two, Info) :-
    misconception_registry_entry(divide_by_half_as_by_two, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(divide_by_half_as_by_two, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-GK-U6-L7', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U6-L7', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit6/lesson7.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U6-L8', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-GK-U6-L8', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_misconception('IM-GK-U6-L8', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U6-L8', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit6/lesson8.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U6-L9', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-GK-U6-L9', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-GK-U6-L9', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_misconception('IM-GK-U6-L9', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U6-L9', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit6/lesson9.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U7-L1', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-GK-U7-L1', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_misconception('IM-GK-U7-L1', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U7-L1', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit7/lesson1.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U7-L10', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-GK-U7-L10', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U7-L10', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit7/lesson10.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U7-L11', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit7/lesson11.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U7-L12', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit7/lesson12.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U7-L13', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit7/lesson13.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U7-L14', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit7/lesson14.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U7-L15', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit7/lesson15.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U7-L16', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit7/lesson16.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U7-L2', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit7/lesson2.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U7-L3', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-GK-U7-L3', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_misconception('IM-GK-U7-L3', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U7-L3', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit7/lesson3.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U7-L4', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit7/lesson4.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U7-L5', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U7-L5', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit7/lesson5.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U7-L6', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-GK-U7-L6', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-GK-U7-L6', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_strategy('IM-GK-U7-L6', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U7-L6', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit7/lesson6.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U7-L7', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit7/lesson7.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U7-L8', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit7/lesson8.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U7-L9', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit7/lesson9.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U8-L1', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit8/lesson1.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U8-L10', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U8-L10', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit8/lesson10.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U8-L11', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit8/lesson11.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U8-L12', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-GK-U8-L12', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_misconception('IM-GK-U8-L12', Operation, count_back_off_by_one, Info) :-
    misconception_registry_entry(count_back_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_back_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-GK-U8-L12', Operation, count_on_off_by_one, Info) :-
    misconception_registry_entry(count_on_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_on_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-GK-U8-L12', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U8-L12', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit8/lesson12.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U8-L13', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-GK-U8-L13', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
explicit_lesson_misconception('IM-GK-U8-L13', Operation, count_back_off_by_one, Info) :-
    misconception_registry_entry(count_back_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_back_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-GK-U8-L13', Operation, count_on_off_by_one, Info) :-
    misconception_registry_entry(count_on_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_on_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-GK-U8-L13', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U8-L13', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit8/lesson13.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U8-L14', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-GK-U8-L14', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_misconception('IM-GK-U8-L14', Operation, count_back_off_by_one, Info) :-
    misconception_registry_entry(count_back_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_back_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-GK-U8-L14', Operation, count_on_off_by_one, Info) :-
    misconception_registry_entry(count_on_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_on_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-GK-U8-L14', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U8-L14', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit8/lesson14.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U8-L15', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U8-L15', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit8/lesson15.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U8-L16', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-GK-U8-L16', multiplication, repeat_equal_groups, Info) :-
    strategy_info(multiplication, repeat_equal_groups, Info).
explicit_lesson_misconception('IM-GK-U8-L16', Operation, count_back_off_by_one, Info) :-
    misconception_registry_entry(count_back_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_back_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-GK-U8-L16', Operation, count_on_off_by_one, Info) :-
    misconception_registry_entry(count_on_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_on_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-GK-U8-L16', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U8-L16', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit8/lesson16.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U8-L17', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-GK-U8-L17', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U8-L17', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit8/lesson17.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U8-L18', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-GK-U8-L18', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-GK-U8-L18', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U8-L18', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit8/lesson18.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U8-L19', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-GK-U8-L19', addition, make_ten_drop_leftover, Info) :-
    strategy_info(addition, make_ten_drop_leftover, Info).
explicit_lesson_strategy('IM-GK-U8-L19', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U8-L19', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit8/lesson19.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U8-L2', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U8-L2', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit8/lesson2.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U8-L20', addition, base_ones_chunking, Info) :-
    strategy_info(addition, base_ones_chunking, Info).
explicit_lesson_strategy('IM-GK-U8-L20', subtraction, decompose_base_for_ones, Info) :-
    strategy_info(subtraction, decompose_base_for_ones, Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U8-L20', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit8/lesson20.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U8-L21', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-GK-U8-L21', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_strategy('IM-GK-U8-L21', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).
explicit_lesson_misconception('IM-GK-U8-L21', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U8-L21', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit8/lesson21.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U8-L3', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_misconception('IM-GK-U8-L3', Operation, count_back_off_by_one, Info) :-
    misconception_registry_entry(count_back_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_back_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
explicit_lesson_misconception('IM-GK-U8-L3', Operation, count_on_off_by_one, Info) :-
    misconception_registry_entry(count_on_off_by_one, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_on_off_by_one, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U8-L3', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit8/lesson3.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U8-L4', addition, count_all_when_count_on_available, Info) :-
    strategy_info(addition, count_all_when_count_on_available, Info).
explicit_lesson_misconception('IM-GK-U8-L4', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(count_all_when_count_on_available, Citation, Commitment, EntitlementLacked, [], Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U8-L4', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit8/lesson4.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U8-L5', addition, round_then_adjust, Info) :-
    strategy_info(addition, round_then_adjust, Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U8-L5', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit8/lesson5.md'), Path, [access(read)]).

explicit_lesson_strategy('IM-GK-U8-L6', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
text_interpreter:explicit_lesson_text_source('IM-GK-U8-L6', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit8/lesson6.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U8-L7', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit8/lesson7.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U8-L8', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit8/lesson8.md'), Path, [access(read)]).

text_interpreter:explicit_lesson_text_source('IM-GK-U8-L9', Path) :-
    absolute_file_name(geometry('corpus/im_teacher_guides/kindergarten/unit8/lesson9.md'), Path, [access(read)]).

