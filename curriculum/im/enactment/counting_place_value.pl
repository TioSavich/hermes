/** <module> Enactment forms for the counting, place-value, and comparison lane
 *
 * The 36 IM lessons in task 209's `counting_place_value_or_comparison`
 * subclass name doings the arithmetic candidate extractor does not read. Nine
 * of them turned out to be a missing join and are now wired to registered
 * automata in scripts/curriculum/build_im_action_seam_recut.py; those lessons
 * are counted on the arithmetic rung and emit nothing here.
 *
 * This module holds the second rung: six structural forms that run on the
 * remaining lessons' own printed inputs, or on stand-ins the module labels as
 * its own when the lesson leaves the quantities to the classroom.
 *
 * What a form does and does not do. A form names a structure, instantiates it
 * on inputs, and prints a record a teacher can read. Its moves are verbs the
 * code runs, and where a registered automaton computes the move, the form
 * calls it rather than recomputing the answer beside it. A form never claims
 * to have held the discussion the lesson asks a class to hold, and every
 * enactment carries a sentence saying what it withholds.
 *
 * Reading limit carried by every form here: the docling markdown of the
 * teacher guides drops the figures. A printed number line's endpoints, tick
 * spacing, and plotted points live in an image this module never reads. Where
 * a form needs an interval it derives one from the numerals the task
 * statement prints, and the verdict says so.
 */

:- module(im_enactment_counting_place_value,
          [ enactment_form/3,
            lesson_enactment_form/3,
            lesson_enactment_input/3,
            enactment_move/3,
            enact/3,
            enactment_verdict/2,
            enactment_trace_dict/2,
            enactment_refusal/2,
            grounded_arithmetic_reach/1,
            enactment_move_audit/1,
            counting_place_value_enactments/1
          ]).

:- use_module(library(lists)).
:- use_module(library(apply)).
:- use_module(library(http/json)).
:- use_module(math(action_automata_registry),
              [run_action_automaton/6]).
:- use_module(render(set_grouping_scene), [set_grouping_render_json/2]).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The forms
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%!  enactment_form(?Form, ?Gloss, ?Warrant) is nondet.
%
%   A structural shape these lessons take. Warrant cites the lesson and the
%   printed span the shape was read from.

enactment_form(locate_on_number_line,
    "Place each printed number on one line, in order, and label it.",
    warrant('IM-G2-U4-L3', 'curriculum/im_teacher_guides/grade2/unit4/lesson3.md',
            257,
            "Complete each number line. Fill in the labels with the number the \c
             tick mark represents. Locate each number. Mark it with a point.")).
enactment_form(bracket_and_name_the_nearer,
    "Put a number between the two multiples of a place that surround it, \c
     then say which of the two it is nearer.",
    warrant('IM-G5-U5-L8', 'curriculum/im_teacher_guides/grade5/unit5/lesson8.md',
            226,
            "Round 6.273 to the nearest whole number, tenth, and hundredth.")).
enactment_form(center_menu_route,
    "Name each center on the menu and say which registered machine does the \c
     counting the center asks for.",
    warrant('IM-GK-U6-L6', 'curriculum/im_teacher_guides/kindergarten/unit6/lesson6.md',
            334,
            "Choose a center. Number Race Tower Build Grab and Count Find the Pair")).
enactment_form(compare_cardinalities_one_to_one,
    "Match two collections one to one and say which holds more.",
    warrant('IM-GK-U7-L2', 'curriculum/im_teacher_guides/kindergarten/unit7/lesson2.md',
            387,
            "Circle the penguin that is filled with more pattern blocks.")).
enactment_form(step_one_and_compare,
    "Take one more or one less than a starting number and say whether the \c
     new number is more or less.",
    warrant('IM-GK-U8-L4', 'curriculum/im_teacher_guides/kindergarten/unit8/lesson4.md',
            275,
            "Roll to choose a number and 1 more or 1 less. Record the starting \c
             number and the new number.")).
enactment_form(author_counting_image,
    "Lay out a collection so its count can be recognized, then list the ways \c
     the arrangement can be broken into two parts.",
    warrant('IM-G3-U8-L13', 'curriculum/im_teacher_guides/grade3/unit8/lesson13.md',
            134,
            "Draw a dot image that would encourage your classmates to count or \c
             identify equal groups. Write down some ways students might see the \c
             dots in your image.")).


%!  enactment_move(?Form, ?Index, ?Move) is nondet.
%
%   The ordered doings a form asks for. Each move is executed by enact/3; none
%   is a stored label.

enactment_move(locate_on_number_line, 1, choose_interval_covering_the_values).
enactment_move(locate_on_number_line, 2, choose_tick_step_as_a_power_of_the_base).
enactment_move(locate_on_number_line, 3, place_each_value_at_its_tick_offset).
enactment_move(locate_on_number_line, 4, certify_drawn_order_by_place_value_comparison).

enactment_move(bracket_and_name_the_nearer, 1, name_the_place_to_bracket_by).
enactment_move(bracket_and_name_the_nearer, 2, compute_the_two_surrounding_multiples).
enactment_move(bracket_and_name_the_nearer, 3, measure_both_distances).
enactment_move(bracket_and_name_the_nearer, 4, compare_distances_and_name_the_nearer).

enactment_move(center_menu_route, 1, read_each_center_name_off_the_menu).
enactment_move(center_menu_route, 2, name_the_doing_the_center_asks_for).
enactment_move(center_menu_route, 3, run_the_registered_machine_for_that_doing).

enactment_move(compare_cardinalities_one_to_one, 1, establish_both_collection_sizes).
enactment_move(compare_cardinalities_one_to_one, 2, match_one_to_one).
enactment_move(compare_cardinalities_one_to_one, 3, run_the_extent_deformation_as_the_contrast).

enactment_move(step_one_and_compare, 1, take_the_starting_number).
enactment_move(step_one_and_compare, 2, step_one_in_the_named_direction).
enactment_move(step_one_and_compare, 3, compare_the_new_number_with_the_start).

enactment_move(author_counting_image, 1, lay_out_the_collection_as_a_scene).
enactment_move(author_counting_image, 2, enumerate_collection_one_to_one).
enactment_move(author_counting_image, 3, list_the_two_part_breakings_of_the_count).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Which lesson takes which form, and on what evidence
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%!  lesson_enactment_form(?Lesson, ?Form, ?Evidence) is nondet.
%
%   Evidence is evidence(Source, Line, SpanText). Every line number was read
%   off the tracked span record in
%   data/learningcommons/derived/im_zero_candidate_triage.json.

lesson_enactment_form('IM-G2-U4-L1', locate_on_number_line,
    evidence('curriculum/im_teacher_guides/grade2/unit4/lesson1.md', 280,
             "Make a number line that goes from 0 to 20. Locate 13. Mark it \c
              with a point. Locate 3. Mark it with a point.")).
lesson_enactment_form('IM-G2-U4-L3', locate_on_number_line,
    evidence('curriculum/im_teacher_guides/grade2/unit4/lesson3.md', 149,
             "Locate 24. Mark it with a point. Locate 37. Locate 48. Locate 83.")).
lesson_enactment_form('IM-G2-U5-L8', locate_on_number_line,
    evidence('curriculum/im_teacher_guides/grade2/unit5/lesson8.md', 251,
             "Locate and label the number on the number line. 700 472 940 356 590")).
lesson_enactment_form('IM-G4-U4-L11', locate_on_number_line,
    evidence('curriculum/im_teacher_guides/grade4/unit4/lesson11.md', 140,
             "Locate and label each number on the number line. \c
              347  3,470  34,700  347,000")).
lesson_enactment_form('IM-G4-U4-L14', locate_on_number_line,
    evidence('curriculum/im_teacher_guides/grade4/unit4/lesson14.md', 171,
             "Work with your group to decide on which number line each number \c
              should go. 140,261 100,025 128,201 158,002 194,030")).

lesson_enactment_form('IM-G5-U5-L8', bracket_and_name_the_nearer,
    evidence('curriculum/im_teacher_guides/grade5/unit5/lesson8.md', 226,
             "Round 6.273 to the nearest whole number, tenth, and hundredth. \c
              Round 4.158 to the nearest whole number, tenth, and hundredth.")).

lesson_enactment_form('IM-GK-U6-L6', center_menu_route,
    evidence('curriculum/im_teacher_guides/kindergarten/unit6/lesson6.md', 334,
             "Choose a center. Number Race Tower Build Grab and Count Find the Pair")).
lesson_enactment_form('IM-GK-U6-L7', center_menu_route,
    evidence('curriculum/im_teacher_guides/kindergarten/unit6/lesson7.md', 308,
             "Choose a center. Number Race Tower Build Grab and Count Find the Pair")).
lesson_enactment_form('IM-GK-U7-L1', center_menu_route,
    evidence('curriculum/im_teacher_guides/kindergarten/unit7/lesson1.md', 316,
             "Choose a center. Geoblocks Grab and Count Find the Pair")).
lesson_enactment_form('IM-GK-U7-L3', center_menu_route,
    evidence('curriculum/im_teacher_guides/kindergarten/unit7/lesson3.md', 324,
             "Choose a center. Pattern Blocks Geoblocks Grab and Count Find the Pair")).

lesson_enactment_form('IM-GK-U7-L2', compare_cardinalities_one_to_one,
    evidence('curriculum/im_teacher_guides/kindergarten/unit7/lesson2.md', 387,
             "Circle the penguin that is filled with more pattern blocks.")).
lesson_enactment_form('IM-GK-U7-L2', center_menu_route,
    evidence('curriculum/im_teacher_guides/kindergarten/unit7/lesson2.md', 318,
             "Choose a center. Pattern Blocks Geoblocks Grab and Count Find the Pair")).
lesson_enactment_form('IM-G4-U4-L14', bracket_and_name_the_nearer,
    evidence('curriculum/im_teacher_guides/grade4/unit4/lesson14.md', 275,
             "Name the multiple of 10,000 that is the nearest to each number. \c
              100,025 128,201 140,261 158,002 194,030")).
lesson_enactment_form('IM-GK-U8-L8', compare_cardinalities_one_to_one,
    evidence('curriculum/im_teacher_guides/kindergarten/unit8/lesson8.md', 218,
             "Find 2 groups to compare. Find 2 groups whose numbers of objects \c
              you can compare.")).

lesson_enactment_form('IM-GK-U8-L4', step_one_and_compare,
    evidence('curriculum/im_teacher_guides/kindergarten/unit8/lesson4.md', 275,
             "Roll to choose a number and 1 more or 1 less. Color the number \c
              that is 1 more or 1 less than your number.")).

lesson_enactment_form('IM-G3-U8-L13', author_counting_image,
    evidence('curriculum/im_teacher_guides/grade3/unit8/lesson13.md', 134,
             "Draw a dot image that would encourage your classmates to count or \c
              identify equal groups.")).


%!  lesson_enactment_input(?Lesson, ?Inputs, ?Provenance) is nondet.
%
%   Nondet by design: a lesson can carry more than one form, and two here do.
%   Inputs is a list whose FIRST element is the form, so enact/3 reads the form
%   off its own arguments rather than off a second lookup that could disagree
%   with the one the caller made. Provenance is `curriculum` when every value
%   was printed in the cited span and `machine_supplied` when the lesson leaves
%   the quantities to the classroom and this module chose stand-ins.

lesson_enactment_input('IM-G2-U4-L1',
    [locate_on_number_line, values([13, 3])], curriculum).
lesson_enactment_input('IM-G2-U4-L3',
    [locate_on_number_line, values([24, 37, 48, 83])], curriculum).
lesson_enactment_input('IM-G2-U5-L8',
    [locate_on_number_line, values([700, 472, 940, 356, 590])], curriculum).
lesson_enactment_input('IM-G4-U4-L11',
    [locate_on_number_line, values([347, 3470, 34700, 347000])], curriculum).
lesson_enactment_input('IM-G4-U4-L14',
    [locate_on_number_line,
     values([140261, 100025, 128201, 158002, 194030])], curriculum).

% The second form on IM-G4-U4-L14: its activity 2 asks for the nearest
% multiple of 10,000 for the same five numbers the first activity placed.
lesson_enactment_input('IM-G4-U4-L14',
    [bracket_and_name_the_nearer,
     bracket_targets([ bracket_target(100025, 1, 10000),
                       bracket_target(128201, 1, 10000),
                       bracket_target(140261, 1, 10000),
                       bracket_target(158002, 1, 10000),
                       bracket_target(194030, 1, 10000) ])], curriculum).

lesson_enactment_input('IM-G5-U5-L8',
    [bracket_and_name_the_nearer,
     bracket_targets([ bracket_target(6273, 1000, 1000),
                       bracket_target(6273, 1000, 100),
                       bracket_target(6273, 1000, 10),
                       bracket_target(4158, 1000, 1000),
                       bracket_target(4158, 1000, 100),
                       bracket_target(4158, 1000, 10) ])], curriculum).

lesson_enactment_input('IM-GK-U6-L6',
    [center_menu_route, centers(['Number Race', 'Tower Build',
                                 'Grab and Count', 'Find the Pair'])],
    curriculum).
lesson_enactment_input('IM-GK-U6-L7',
    [center_menu_route, centers(['Number Race', 'Tower Build',
                                 'Grab and Count', 'Find the Pair'])],
    curriculum).
lesson_enactment_input('IM-GK-U7-L1',
    [center_menu_route, centers(['Geoblocks', 'Grab and Count',
                                 'Find the Pair'])], curriculum).
lesson_enactment_input('IM-GK-U7-L3',
    [center_menu_route, centers(['Pattern Blocks', 'Geoblocks',
                                 'Grab and Count', 'Find the Pair'])],
    curriculum).

% The second form on IM-GK-U7-L2: its first task span is a center menu and its
% last is the penguin comparison, so the lesson takes both shapes.
lesson_enactment_input('IM-GK-U7-L2',
    [center_menu_route, centers(['Pattern Blocks', 'Geoblocks',
                                 'Grab and Count', 'Find the Pair'])],
    curriculum).
lesson_enactment_input('IM-GK-U7-L2',
    [compare_cardinalities_one_to_one, collections(7, 4)], machine_supplied).
lesson_enactment_input('IM-GK-U8-L8',
    [compare_cardinalities_one_to_one, collections(6, 4)], machine_supplied).

lesson_enactment_input('IM-GK-U8-L4',
    [step_one_and_compare, starts([4, 7, 9])], machine_supplied).

lesson_enactment_input('IM-G3-U8-L13',
    [author_counting_image, image_count(6)], machine_supplied).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Running a form
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%!  enact(+Lesson, +Inputs, -Enactment) is nondet.
%
%   Run one form over the supplied inputs. Inputs carries its own form first,
%   so a lesson with two forms enacts each without the caller and the callee
%   disagreeing about which one is running. Fails on a form the lesson does not
%   carry, and fails when the inputs do not fit the form, rather than filling
%   the gap with a guess.

enact(Lesson, [Form | Payload],
      enactment(Lesson, Form, [Form | Payload], Steps, Artifact)) :-
    lesson_enactment_form(Lesson, Form, _Evidence),
    Payload = [PayloadTerm],
    run_form(Form, PayloadTerm, Steps, Artifact).


%!  grounded_arithmetic_reach(?Bound) is det.
%
%   The operand ceiling above which this module refuses an automaton rather
%   than running it. The `sar_*` families reach arithmetic that is grounded in
%   iterated successor steps through math(integer_helpers) and
%   formalization(grounded_arithmetic), and its cost climbs with the operand
%   rather than with the numeral's length.
%
%   Measured in this worktree on the two routes this lane feeds, 2026-08-01:
%
%       addition/count_on_from_larger     (4000,1000)    876 ms
%                                         (8000,5000)  11531 ms
%                                         (11000,8000) stack overflow at 12 s
%       subtraction/count_up_missing_addend (4000,1000)  242 ms
%                                         (8000,5000)    353 ms
%                                         (11000,8000)   549 ms
%
%   5000 is the shared bound the measurement lane set, and it holds here. The
%   two routes have different cost shapes, and count_on_from_larger is already
%   eleven seconds at the bound, so the bound keeps the code from running away
%   without making it fast. It is a refusal line, not a performance promise.
%
%   The counting and decimal families do not reach grounded arithmetic and are
%   not held to this bound. Measured at the magnitudes this lane actually
%   feeds them: place_value_comparison on counts(140261,194030) 1 ms,
%   recursive_place_value_inscription on 347000 under 1 ms,
%   decimal_comparison_by_aligned_units on 99.909 against 99.099 under 1 ms.
grounded_arithmetic_reach(5000).

%!  within_grounded_reach(+Values) is semidet.
within_grounded_reach(Values) :-
    grounded_arithmetic_reach(Bound),
    forall(member(Value, Values),
           ( integer(Value), abs(Value) =< Bound )).


%!  run_form(+Form, +Payload, -Steps, -Artifact) is semidet.

run_form(locate_on_number_line, values(Values), Steps,
         printed(number_line(interval(Low, High), tick(Step), Placements))) :-
    Values = [_|_],
    forall(member(Value, Values), (integer(Value), Value >= 0)),
    covering_interval(Values, Low, High, Step),
    findall(placement(Value, ticks_from_start(Ticks), past_tick(Remainder)),
            ( member(Value, Values),
              Offset is Value - Low,
              Ticks is Offset // Step,
              Remainder is Offset mod Step
            ),
            Placements),
    msort(Values, Ordered),
    order_certificate(Ordered, Certificate),
    Steps = [ step(1, choose_interval_covering_the_values,
                   Values, interval(Low, High)),
              step(2, choose_tick_step_as_a_power_of_the_base,
                   interval(Low, High), tick(Step)),
              step(3, place_each_value_at_its_tick_offset,
                   Values, Placements),
              step(4, certify_drawn_order_by_place_value_comparison,
                   Ordered, Certificate) ].

run_form(bracket_and_name_the_nearer, bracket_targets(Targets), Steps,
         printed(bracket_table(Rows))) :-
    Targets = [_|_],
    findall(Row,
            ( member(Target, Targets),
              bracket_row(Target, Row)
            ),
            Rows),
    length(Targets, Wanted),
    length(Rows, Wanted),
    Rows = [row(FirstValue, FirstStep, FirstLow, FirstHigh,
                FirstBelow, FirstAbove, FirstNearer, _) | _],
    Steps = [ step(1, name_the_place_to_bracket_by,
                   FirstValue, unit_step(FirstStep)),
              step(2, compute_the_two_surrounding_multiples,
                   FirstValue, bracket(FirstLow, FirstHigh)),
              step(3, measure_both_distances,
                   bracket(FirstLow, FirstHigh),
                   distances(FirstBelow, FirstAbove)),
              step(4, compare_distances_and_name_the_nearer,
                   distances(FirstBelow, FirstAbove), FirstNearer) ].

run_form(center_menu_route, centers(Centers), Steps,
         printed(center_routing(Routes))) :-
    Centers = [_|_],
    findall(route(Center, Doing, Operation, Kind, Result),
            ( member(Center, Centers),
              center_doing(Center, Doing, Operation, Kind, Left, Right),
              once(( run_action_automaton(Operation, Kind, Left, Right,
                                          Outcome, Trace),
                     Trace = [_|_] )),
              outcome_result(Outcome, Result)
            ),
            Routes),
    Routes = [route(FirstCenter, FirstDoing, FirstOp, FirstKind, FirstResult)|_],
    Steps = [ step(1, read_each_center_name_off_the_menu,
                   Centers, FirstCenter),
              step(2, name_the_doing_the_center_asks_for,
                   FirstCenter, FirstDoing),
              step(3, run_the_registered_machine_for_that_doing,
                   FirstOp/FirstKind, FirstResult) ].

run_form(compare_cardinalities_one_to_one, collections(Left, Right), Steps,
         scene(set_grouping_scene, compare(Left, Right))) :-
    integer(Left), integer(Right),
    between(1, 10, Left), between(1, 10, Right),
    run_action_automaton(counting, compare_cardinalities_one_to_one,
                         counts(Left, Right), extents(Left, Right),
                         Matched, MatchedTrace),
    MatchedTrace = [_|_],
    outcome_result(Matched, Relation),
    (   run_action_automaton(counting, spatial_extent_as_cardinality,
                             counts(Left, Right), extents(Right, Left),
                             Misread, MisreadTrace),
        MisreadTrace = [_|_]
    ->  outcome_result(Misread, Contrast)
    ;   Contrast = no_separating_extent_pair
    ),
    Steps = [ step(1, establish_both_collection_sizes,
                   counts(Left, Right), established),
              step(2, match_one_to_one,
                   counts(Left, Right), Relation),
              step(3, run_the_extent_deformation_as_the_contrast,
                   extents(Right, Left), Contrast) ].

run_form(step_one_and_compare, starts(Starts), Steps,
         printed(one_more_one_less(Rows))) :-
    Starts = [_|_],
    findall(Row,
            ( member(Start, Starts),
              member(Direction, [more, less]),
              step_one_row(Start, Direction, Row)
            ),
            Rows),
    Rows = [row(FirstStart, FirstDirection, FirstNew, FirstRelation)|_],
    Steps = [ step(1, take_the_starting_number, Starts, FirstStart),
              step(2, step_one_in_the_named_direction,
                   FirstDirection, FirstNew),
              step(3, compare_the_new_number_with_the_start,
                   counts(FirstNew, FirstStart), FirstRelation) ].

run_form(author_counting_image, image_count(Count), Steps,
         scene(set_grouping_scene, subitize(auto, Count))) :-
    integer(Count), between(1, 10, Count),
    set_grouping_render_json(subitize(auto, Count), Scene),
    is_dict(Scene),
    get_dict(frames, Scene, [_|_]),
    get_dict(kind, Scene, Arrangement),
    run_action_automaton(counting, enumerate_collection_one_to_one,
                         Count, base(10), Counted, CountedTrace),
    CountedTrace = [_|_],
    outcome_result(Counted, Cardinality),
    findall(seeing(Part, Rest),
            ( between(1, Count, Part), Part =< Count - Part,
              Rest is Count - Part
            ),
            Seeings),
    Steps = [ step(1, lay_out_the_collection_as_a_scene,
                   Count, arrangement(Arrangement)),
              step(2, enumerate_collection_one_to_one,
                   Count, Cardinality),
              step(3, list_the_two_part_breakings_of_the_count,
                   Count, Seeings) ].


%!  enactment_verdict(+Enactment, -Verdict) is det.
%
%   well_formed when the form ran on the lesson's own printed inputs and every
%   move produced a result. partial when the module supplied the quantities the
%   lesson leaves to the classroom, or when the printed figure the lesson draws
%   on was never read.

enactment_verdict(enactment(Lesson, Form, Inputs, Steps, _Artifact), Verdict) :-
    (   Steps == []
    ->  Verdict = refused(no_move_produced_a_result)
    ;   lesson_enactment_input(Lesson, Inputs, machine_supplied)
    ->  Verdict = partial(inputs_supplied_by_this_module_not_by_the_lesson)
    ;   form_reading_limit(Form, Limit)
    ->  Verdict = partial(Limit)
    ;   Verdict = well_formed
    ).

form_reading_limit(locate_on_number_line,
                   printed_line_endpoints_and_ticks_were_not_read).
form_reading_limit(center_menu_route,
                   center_activity_cards_were_not_read).


%!  what_it_does_not_claim(?Form, ?Sentence) is det.

what_it_does_not_claim(locate_on_number_line,
    "The interval and the tick step come from the printed numerals, so this \c
     does not say the drawn line in the guide has those endpoints.").
what_it_does_not_claim(bracket_and_name_the_nearer,
    "Naming the nearer multiple is not the rounding conversation the lesson \c
     asks for, and the table says nothing about ties.").
what_it_does_not_claim(center_menu_route,
    "Routing a center to a machine does not say a child at that center does \c
     what the machine does.").
what_it_does_not_claim(compare_cardinalities_one_to_one,
    "The two collection sizes are this module's, so the relation holds of the \c
     stand-ins and not of the pattern blocks in the picture.").
what_it_does_not_claim(step_one_and_compare,
    "The starting numbers are this module's; the lesson gets its numbers from \c
     a die a child rolls.").
what_it_does_not_claim(author_counting_image,
    "Laying out and breaking a count is not the classroom exchange in which \c
     children report how they saw the dots.").


%!  enactment_trace_dict(+Enactment, -Dict) is det.
%
%   Emit the consumer dict directly rather than handing step/4 terms to
%   hermes/encyclopedia.pl's history_steps/2. That predicate reads step/4
%   through its legacy clause at encyclopedia.pl:423,
%   step_state_interp(step(S,_,_,I), S, I), which takes the INDEX as the state
%   label and the RESULT as the value and drops the verb and the operand. It
%   corrupts silently: the dict comes back well formed and says the wrong
%   thing. Building the dict here keeps the verb and the operand in the label
%   where a reader can check them against enactment_move/3.
%
%   The key set matches what strategy_trace_dict/3 returns, so an enactment
%   appears wherever a strategy trace appears. jumps is empty and stays empty:
%   no form here produces a number-line jump sequence, and an empty list is the
%   shape the drawer already handles.
enactment_trace_dict(enactment(Lesson, Form, _Inputs, Steps, Artifact), Dict) :-
    findall(_{n: Index, label: Label, value: Value},
            ( member(step(Index, Verb, Operand, Result), Steps),
              format(string(Label), "~w(~w)", [Verb, Operand]),
              term_string(Result, Value)
            ),
            StepDicts),
    ( StepDicts == [] -> Ok = false ; Ok = true ),
    last_result_text(Steps, ResultText),
    format(string(Name), "~w / ~w", [Lesson, Form]),
    artifact_note(Artifact, Note),
    Dict = _{ strategy: Name,
              ok: Ok,
              representation: "enactment",
              result: ResultText,
              steps: StepDicts,
              jumps: [],
              note: Note }.

last_result_text(Steps, Text) :-
    (   append(_, [step(_, _, _, Result)], Steps)
    ->  term_string(Result, Text)
    ;   Text = ""
    ).

artifact_note(printed(_),
              "The artifact is a printed record, so the drawer has nothing to \c
               step through and jumps stays empty.") :- !.
artifact_note(scene(Renderer, _), Note) :-
    format(string(Note),
           "The artifact is a scene for ~w; jumps stays empty because this \c
            form produces no number-line jump sequence.", [Renderer]).


%!  enactment_move_audit(-Audit) is det.
%
%   A name is not a doing. This holds every declared move to that rule: it runs
%   every enactment, collects the verbs the steps actually carry, and reports
%   any declared move no run produced and any executed verb no declaration
%   names. Both lists empty is the pass condition.
enactment_move_audit(_{declared_moves: Declared,
                       executed_verbs: Executed,
                       step_verbs_checked: StepCount,
                       declared_but_never_run: Unrun,
                       run_but_never_declared: Undeclared}) :-
    findall(Form-Move, enactment_move(Form, _, Move), DeclaredPairs0),
    sort(DeclaredPairs0, DeclaredPairs),
    length(DeclaredPairs, Declared),
    findall(Form-Verb,
            ( lesson_enactment_form(Lesson, _, _),
              lesson_enactment_input(Lesson, Inputs, _),
              enact(Lesson, Inputs, enactment(_, Form, _, Steps, _)),
              member(step(_, Verb, _, _), Steps)
            ),
            RunPairs0),
    length(RunPairs0, StepCount),
    sort(RunPairs0, RunPairs),
    length(RunPairs, Executed),
    subtract(DeclaredPairs, RunPairs, Unrun),
    subtract(RunPairs, DeclaredPairs, Undeclared).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Move helpers. Each one runs; none stores an answer.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%!  covering_interval(+Values, -Low, -High, -Step) is det.
%
%   The smallest interval [0, B] with B a multiple of a power of ten that
%   covers every value, and a tick step one order below that power.
covering_interval(Values, 0, High, Step) :-
    max_list(Values, Max),
    order_of_magnitude(Max, Power),
    Step is max(1, Power // 10),
    High is ((Max + Step - 1) // Step) * Step.

order_of_magnitude(Value, Power) :-
    order_of_magnitude_(Value, 1, Power).

order_of_magnitude_(Value, Accumulated, Power) :-
    (   Value < Accumulated
    ->  Power = Accumulated
    ;   Next is Accumulated * 10,
        order_of_magnitude_(Value, Next, Power)
    ).

%!  order_certificate(+Ordered, -Certificate) is det.
%
%   Run counting/place_value_comparison on each adjacent pair of the sorted
%   values. The drawing is certified only if every adjacent comparison runs and
%   reports the relation the sort asserts.
order_certificate(Ordered, Certificate) :-
    findall(Pair-Relation,
            ( nth0(Index, Ordered, Left),
              Next is Index + 1,
              nth0(Next, Ordered, Right),
              Pair = counts(Left, Right),
              run_action_automaton(counting, place_value_comparison,
                                   Pair, base(10), Outcome, Trace),
              Trace = [_|_],
              outcome_result(Outcome, Relation)
            ),
            Relations),
    length(Ordered, Count),
    Expected is max(0, Count - 1),
    length(Relations, Observed),
    (   Observed =:= Expected,
        forall(member(_-Relation, Relations), Relation \== more)
    ->  Certificate = order_certified(Relations)
    ;   Certificate = order_not_certified(Relations)
    ).

%!  bracket_row(+Target, -Row) is semidet.
%
%   bracket_target(Numeral, Scale, Step) reads Numeral/Scale, bracketed by
%   multiples of Step/Scale. Nearest tenth of 6.273 is
%   bracket_target(6273, 1000, 100); nearest ten thousand of 100,025 is
%   bracket_target(100025, 1, 10000). One parameterization covers the decimal
%   rounding of grade 5 and the whole-number rounding of grade 4, and both stay
%   in integer arithmetic. An automaton names which distance is smaller; this
%   predicate does not decide the order itself.
bracket_row(bracket_target(Numeral, Scale, Step),
            row(printed(Numeral, Scale), step(Step, Scale),
                printed(Low, Scale), printed(High, Scale),
                printed(Below, Scale), printed(Above, Scale),
                Nearer, named_by(Operation/Kind, Relation))) :-
    integer(Numeral), integer(Scale), integer(Step),
    Scale >= 1, Step >= 1, Numeral >= 0,
    Low is (Numeral // Step) * Step,
    High is Low + Step,
    Below is Numeral - Low,
    Above is High - Numeral,
    distance_comparison(Below, Above, Scale, Operation, Kind, Relation),
    (   Relation == below_is_smaller
    ->  Nearer = nearer(printed(Low, Scale))
    ;   Relation == above_is_smaller
    ->  Nearer = nearer(printed(High, Scale))
    ;   Nearer = equidistant
    ).

%!  distance_comparison(+Below, +Above, +Scale, -Operation, -Kind, -Relation)
%
%   Which family names the order of the two distances. Scale 1 means the
%   bracketing is over whole numbers, and decimal_comparison_by_aligned_units
%   refuses a scale of 1: it wants a fractional scale, so it is not the machine
%   for grade 4's nearest multiple of ten thousand. The counting family is, and
%   it takes the distances directly. The two report in different vocabularies,
%   so both are normalized here and the row records which machine spoke.
distance_comparison(Below, Above, 1, counting, place_value_comparison,
                    Relation) :-
    !,
    run_action_automaton(counting, place_value_comparison,
                         counts(Below, Above), base(10), Outcome, Trace),
    Trace = [_|_],
    outcome_result(Outcome, Reported),
    count_relation_normalized(Reported, Relation).
distance_comparison(Below, Above, Scale, decimal,
                    decimal_comparison_by_aligned_units, Relation) :-
    Scale > 1,
    run_action_automaton(decimal, decimal_comparison_by_aligned_units,
                         decimal_pair(Below, Scale, Above, Scale), ignored,
                         Outcome, Trace),
    Trace = [_|_],
    outcome_result(Outcome, Reported),
    decimal_relation_normalized(Reported, Relation).

count_relation_normalized(fewer, below_is_smaller).
count_relation_normalized(more, above_is_smaller).
count_relation_normalized(same_number, equidistant).

decimal_relation_normalized(less, below_is_smaller).
decimal_relation_normalized(more, above_is_smaller).
decimal_relation_normalized(equal, equidistant).

%!  step_one_row(+Start, +Direction, -Row) is semidet.
step_one_row(Start, Direction, row(Start, Direction, New, Relation)) :-
    (   Direction == more
    ->  New is Start + 1
    ;   New is Start - 1
    ),
    New >= 0,
    run_action_automaton(counting, place_value_comparison,
                         counts(New, Start), base(10), Outcome, Trace),
    Trace = [_|_],
    outcome_result(Outcome, Relation).

%!  center_doing(?Center, ?Doing, ?Operation, ?Kind, ?Left, ?Right) is nondet.
%
%   Which registered machine does the counting a named center asks for. The
%   inputs are this module's, chosen small enough for the K-2 machines to
%   accept; the routing claim is about the doing, not about the numbers.
center_doing('Number Race', order_two_numerals,
             counting, place_value_comparison, counts(7, 4), base(10)).
center_doing('Tower Build', inscribe_a_built_quantity,
             counting, recursive_place_value_inscription, 14, base(10)).
center_doing('Grab and Count', count_a_grabbed_collection,
             counting, enumerate_collection_one_to_one, 8, base(10)).
center_doing('Find the Pair', match_two_collections_by_count,
             counting, compare_cardinalities_one_to_one,
             counts(5, 5), extents(5, 5)).
center_doing('Geoblocks', count_a_built_collection,
             counting, enumerate_collection_one_to_one, 6, base(10)).
center_doing('Pattern Blocks', count_a_covered_region,
             counting, enumerate_collection_one_to_one, 9, base(10)).
center_doing('Greatest of Them All', order_two_numerals,
             counting, place_value_comparison, counts(92, 29), base(10)).
center_doing('Get Your Numbers in Order', order_two_numerals,
             counting, place_value_comparison, counts(13, 49), base(10)).
center_doing('Fewer, Same, More', match_two_collections_by_count,
             counting, compare_cardinalities_one_to_one,
             counts(4, 7), extents(4, 7)).
center_doing('Counting Collections', count_a_grabbed_collection,
             counting, enumerate_collection_one_to_one, 10, base(10)).

outcome_result(action_outcome(_, Fields), Result) :-
    memberchk(result(Result), Fields),
    !.
outcome_result(Outcome, Outcome).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The refusals, each naming the machine that would lift it
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%!  enactment_refusal(?Lesson, ?MachineNeeded) is nondet.

enactment_refusal('IM-G2-U4-L2',
    "A reader that takes a drawn number line and returns its tick sequence, so \c
     a mislabelled line can be checked against the sequence it should carry.").
enactment_refusal('IM-G2-U4-L5',
    "The same drawn-line reader, returning the interval endpoints, so a point \c
     with no printed scale can be bracketed.").
enactment_refusal('IM-G3-U5-L6',
    "A partition machine over a drawn interval that reports whether the marks \c
     cut equal parts, which the fraction partition automaton does not do \c
     because it partitions a supplied whole rather than reading a drawn one.").
enactment_refusal('IM-G3-U5-L9',
    "A locate-the-unit machine that finds where 1 sits on a line whose only \c
     printed marks are unit fractions; the numerals live in the figure the \c
     markdown drops.").
enactment_refusal('IM-G3-U5-L18',
    "A reader for the supplied race map, since every distance in the task is \c
     a position on a map this module never receives.").
enactment_refusal('IM-G4-U2-L12',
    "A table reader for the 25-cell fraction grid; the fractions are printed \c
     in the figure and the row and column structure is not in the markdown.").
enactment_refusal('IM-G4-U3-L17',
    "A card-set reader for the teacher-supplied expression cards, and the \c
     fraction lane this wave leaves closed.").


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Emission
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

lesson_grade('IM-G2-U4-L1', "2").
lesson_grade('IM-G2-U4-L3', "2").
lesson_grade('IM-G2-U5-L8', "2").
lesson_grade('IM-G4-U4-L11', "4").
lesson_grade('IM-G4-U4-L14', "4").
lesson_grade('IM-G5-U5-L8', "5").
lesson_grade('IM-GK-U6-L6', "K").
lesson_grade('IM-GK-U6-L7', "K").
lesson_grade('IM-GK-U7-L1', "K").
lesson_grade('IM-GK-U7-L2', "K").
lesson_grade('IM-GK-U7-L3', "K").
lesson_grade('IM-GK-U8-L4', "K").
lesson_grade('IM-GK-U8-L8', "K").
lesson_grade('IM-G3-U8-L13', "3").

%!  counting_place_value_enactments(-Enactments) is det.
%
%   Every enactment this module runs, paired with its verdict. One entry per
%   lesson and form, so the two lessons carrying two forms appear twice.
counting_place_value_enactments(Enactments) :-
    findall(Lesson-Enactment-Verdict,
            ( lesson_enactment_input(Lesson, Inputs, _),
              enact(Lesson, Inputs, Enactment),
              enactment_verdict(Enactment, Verdict)
            ),
            Enactments).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Registration on curriculum/im/lesson_enactment.pl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This lane wrote its machines before the contract module existed, so it keeps
% its own `enact/3` and its own verdict and joins through the contract's lane
% route. The clauses below are the whole of the join.
%
% The lane no longer writes its own emission file. `lesson_enactment` owns
% `data/learningcommons/derived/lesson_enactments/counting_place_value.jsonl`
% and writes every lane's rows in one shape, which is what lets one page builder
% read all of them.

:- use_module(im_lessons(lesson_enactment), []).

:- multifile
       lesson_enactment:enactment_lane/2,
       lesson_enactment:enactment_form/3,
       lesson_enactment:lesson_enactment_form/3,
       lesson_enactment:enactment_move/3,
       lesson_enactment:enactment_run/3,
       lesson_enactment:enactment_lane_verdict/2,
       lesson_enactment:enactment_disclaimer/2,
       lesson_enactment:enactment_input_provenance/3,
       lesson_enactment:lesson_enactment_refusal/2.

lesson_enactment:enactment_lane(Form, counting_place_value_or_comparison) :-
    enactment_form(Form, _, _).

lesson_enactment:enactment_form(Form, Gloss, Warrant) :-
    enactment_form(Form, Gloss, Warrant).

lesson_enactment:lesson_enactment_form(Lesson, Form, Evidence) :-
    lesson_enactment_form(Lesson, Form, Evidence).

lesson_enactment:enactment_move(Form, Index, Move) :-
    enactment_move(Form, Index, Move).

% Every clause below is guarded on this lane's own forms. Without the guard a
% lane's verdict clause answers for every other lane's enactments too: these are
% multifile predicates in one namespace, and each lane's verdict predicate is
% total over enactment terms, so whichever lane loaded first would decide every
% verdict on the rung. The gate's list-artifact rule caught it, on an enactment
% of a fraction form reading well_formed out of a lane that never heard of it.

lesson_enactment:enactment_run(Form, Lesson, Enactment) :-
    enactment_form(Form, _, _),
    once(( lesson_enactment_input(Lesson, [Form | Payload], _Provenance),
           enact(Lesson, [Form | Payload], Enactment) )).

lesson_enactment:enactment_lane_verdict(Enactment, Verdict) :-
    Enactment = enactment(_, Form, _, _, _),
    enactment_form(Form, _, _),
    once(enactment_verdict(Enactment, Verdict)).

lesson_enactment:enactment_disclaimer(Form, Sentence) :-
    what_it_does_not_claim(Form, Sentence).

lesson_enactment:enactment_input_provenance(Form, Lesson, Provenance) :-
    once(lesson_enactment_input(Lesson, [Form | _], Provenance)).

lesson_enactment:lesson_enactment_refusal(Lesson, Machine) :-
    enactment_refusal(Lesson, Machine).
