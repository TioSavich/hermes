/** <module> Enactment of the IM measurement lessons
 *
 * The breadth lane for the 50 IM lessons the action seam recut classifies as
 * `measurement_task`. It answers one question per lesson: what doing does the
 * lesson ask a class to carry out, and can this repository carry out a version
 * of that doing on the lesson's own numbers?
 *
 * Measurement is iteration of a unit, and iteration of a unit is what the
 * measurement automata in `knowledge/strategies/math/measurement_action_pairs.pl`
 * already do. So most of the work here is a join, not a new machine: ten
 * structural forms, each routed to automata and renderers that already exist.
 *
 * ## What an enactment does not settle
 *
 * Running `iterate_unit_along_extent` on IM-G1-U6-L6 reports a length in paper
 * clips. No paper clip was laid against a strip of tape. The enactment models
 * the count-and-report structure of the task and prints the arithmetic that
 * structure commits a class to; the physical act stays with the class. Every
 * row this module emits carries a `what_it_does_not_claim` sentence saying so
 * for its own form.
 *
 * ## Input provenance
 *
 * Measurement is where "the lesson gives no numbers" bites hardest, because the
 * lesson says "measure your desk". Every input carries a provenance term:
 *
 *   - `curriculum(File, Line)`: the value is printed in the teacher guide at
 *     that line, and a checker re-reads the file to confirm it.
 *   - `stand_in(Reason)`: the machine chose the value because the curriculum
 *     defers to the classroom. The reason names what the classroom would have
 *     supplied.
 *   - `derived(Rule)`: the enactment computed the value from other inputs.
 *
 * A stand-in anywhere in the input list caps the verdict at `partial`. The
 * field is load-bearing, not decorative: of the input sets here, the ones that
 * carry a stand-in can never report `well_formed`.
 *
 * ## Registration
 *
 * The contract module `curriculum/im/lesson_enactment.pl` registers this lane
 * by importing it; `enactment_lane/2` names the pair. This module declares no
 * predicate inside the contract module's namespace, so the two files can load
 * in either order.
 *
 * Run: swipl -q -l paths.pl -s curriculum/im/enactment/measurement.pl \
 *            -g measurement_enactment_report -t halt
 */

:- module(im_enactment_measurement,
          [ enactment_form/3,              % ?Form, ?Gloss, ?Warrant
            lesson_enactment_form/3,       % ?Lesson, ?Form, ?Evidence
            enactment_move/3,              % ?Form, ?Index, ?Move
            enact/3,                       % +Lesson, +Inputs, -Enactment
            enactment_verdict/2,           % +Enactment, -Verdict
            enactment_input/3,             % ?Lesson, ?Form, ?Inputs
            enactment_refusal/3,           % ?Lesson, ?Reason, ?MachineThatWouldLift
            form_does_not_claim/2,         % ?Form, ?Sentence
            lesson_source/2,               % ?Lesson, ?RelativePath
            lesson_grade/2,                % ?Lesson, ?Grade
            enactment_trace_dict/2,        % +Enactment, -Dict
            enactment_artifact_dict/2,     % +Enactment, -Dict
            measurement_enactment_report/0,
            measurement_enactment_report/1 % -Dict
          ]).

:- use_module(math(action_automata_registry), []).
:- use_module(render(measurement_strip_scene), []).
:- use_module(render(area_unit_covering_scene), []).
:- use_module(render(angle_circular_scene), []).
:- use_module(library(lists)).
:- use_module(library(apply)).



%% ======================================================================
%% The forms
%% ======================================================================

%!  enactment_form(?Form, ?Gloss, ?Warrant) is nondet.
%
%   A structural shape the IM measurement lessons take. The warrant names one
%   lesson that exhibits the shape and the file, line, and printed text the
%   reading came from. `scripts/checks/check_measurement_enactment.py` re-reads
%   every line cited here and requires the snippet back.

enactment_form(iterate_unit_along_extent,
               'Lay one unit end to end along an extent and report how many \c
                intervals it took.',
               warrant('IM-G1-U6-L6',
                       'curriculum/im_teacher_guides/grade1/unit6/lesson6.md',
                       312,
                       "Use paper clips to measure each strip of tape.")).
enactment_form(reunitize_same_extent,
               'Measure one extent twice with units of different size and \c
                relate the two counts by the factor between the units.',
               warrant('IM-G2-U3-L9',
                       'curriculum/im_teacher_guides/grade2/unit3/lesson9.md',
                       209,
                       "1. Work with your group. Measure the tape strips")).
enactment_form(partition_extent_into_unit_pieces,
               'Cut an extent into pieces of a stated size and count the \c
                pieces, keeping any leftover as a remainder.',
               warrant('IM-G5-U3-L13',
                       'curriculum/im_teacher_guides/grade5/unit3/lesson13.md',
                       154,
                       "These diagrams show strips of different colored")).
enactment_form(pack_region_with_unit,
               'Cover a region with a square or cubic unit and count the \c
                copies it takes.',
               warrant('IM-G5-U8-L8',
                       'curriculum/im_teacher_guides/grade5/unit8/lesson8.md',
                       132,
                       "The wagon bed is approximately 27 feet long, 13")).
enactment_form(change_measured_quantity,
               'Add or take away a measured amount and keep the unit on the \c
                result.',
               warrant('IM-G3-U3-L2',
                       'curriculum/im_teacher_guides/grade3/unit3/lesson2.md',
                       199,
                       "Solve each problem. Explain or show your")).
enactment_form(compose_value_from_denominations,
               'Convert each denomination to a common unit of value, total \c
                them, and take a purchase away from the total.',
               warrant('IM-G2-U6-L15',
                       'curriculum/im_teacher_guides/grade2/unit6/lesson15.md',
                       149,
                       "Name the coins in each collection. Find the value in")).
enactment_form(read_circular_scale,
               'Read a time from two hands on one dial, where the minute hand \c
                iterates five-minute intervals and the hour hand carries the \c
                coarser count.',
               warrant('IM-G2-U6-L12',
                       'curriculum/im_teacher_guides/grade2/unit6/lesson12.md',
                       169,
                       "1. Discuss 2 ways to read the time on this clock.")).
enactment_form(bracket_unknown_measure,
               'Put a measure between a too-low and a too-high landmark, name \c
                an about-right value, and test whether the bracket holds.',
               warrant('IM-G3-U8-L14',
                       'curriculum/im_teacher_guides/grade3/unit8/lesson14.md',
                       91,
                       "What is the length of this earthworm?")).
enactment_form(sort_against_benchmark,
               'Hold a referent quantity fixed and place candidate quantities \c
                in the band each one falls into.',
               warrant('IM-G3-U6-L6',
                       'curriculum/im_teacher_guides/grade3/unit6/lesson6.md',
                       168,
                       "This paper clip          This basket of apples weighs")).
enactment_form(resolve_measure_to_scale_grain,
               'Round measures to the finest interval a scale offers and say \c
                what that scale can and cannot settle.',
               warrant('IM-G5-U5-L7',
                       'curriculum/im_teacher_guides/grade5/unit5/lesson7.md',
                       158,
                       "1728 weigh 6.867 grams.")).


%!  form_does_not_claim(?Form, ?Sentence) is nondet.
%
%   One sentence per form, carried on every emitted row.

form_does_not_claim(iterate_unit_along_extent,
    'The count came from the lesson text or from a machine stand-in; no unit \c
     was laid against a physical object.').
form_does_not_claim(reunitize_same_extent,
    'The conversion factor was taken from the lesson, not measured; the \c
     enactment does not establish that the two units relate as stated.').
form_does_not_claim(partition_extent_into_unit_pieces,
    'The pieces were counted in arithmetic, not cut; nothing here settles \c
     whether the cuts a class makes come out even.').
form_does_not_claim(pack_region_with_unit,
    'The covering is a count of unit copies over stated dimensions; no region \c
     was tiled and no leftover shape was fitted.').
form_does_not_claim(change_measured_quantity,
    'The unit is carried through the arithmetic by construction, so the \c
     enactment cannot be evidence that a learner would carry it.').
form_does_not_claim(compose_value_from_denominations,
    'The coin counts were read from the lesson text or supplied by the \c
     machine; the enactment does not identify coins from an image.').
form_does_not_claim(read_circular_scale,
    'The hand positions were computed from a stated time; the enactment does \c
     not read a time off a drawn or physical clock face.').
form_does_not_claim(bracket_unknown_measure,
    'The bracket is built from a stated actual value, so it tests arithmetic \c
     containment rather than a learner''s sense of size.').
form_does_not_claim(sort_against_benchmark,
    'The band boundaries were stated as input; the enactment does not judge \c
     whether the boundaries are the ones a class would choose.').
form_does_not_claim(resolve_measure_to_scale_grain,
    'Rounding to a stated grain models what a scale reports; it does not \c
     model the physical behaviour of any instrument.').


%% ======================================================================
%% The moves
%% ======================================================================

%!  enactment_move(?Form, ?Index, ?Move) is nondet.
%
%   The ordered doings each form asks for. `Move` is `Verb(OperandKey)`: the
%   functor is the verb `enact/3` emits in its step list, and the argument names
%   the operand the verb acts on. `measurement_enactment_report/1` checks that
%   every emitted step verb is declared here, so a move cannot be a label for a
%   verb the code never runs.

enactment_move(iterate_unit_along_extent, 1, establish_unit(unit)).
enactment_move(iterate_unit_along_extent, 2, partition_unit_into_equal_intervals(subdivisions)).
enactment_move(iterate_unit_along_extent, 3, iterate_interval_from_zero(unit_count)).
enactment_move(iterate_unit_along_extent, 4, read_accumulated_length(measure)).
enactment_move(iterate_unit_along_extent, 5, recount_boundary_marks_as_intervals(overcount)).

enactment_move(reunitize_same_extent, 1, establish_equivalence(conversion_factor)).
enactment_move(reunitize_same_extent, 2, iterate_conversion_group(unit_count)).
enactment_move(reunitize_same_extent, 3, multiply_unit_count(converted)).
enactment_move(reunitize_same_extent, 4, relabel_as_smaller_unit(to_unit)).
enactment_move(reunitize_same_extent, 5, contrast_relabel_without_iterating(unscaled)).

enactment_move(partition_extent_into_unit_pieces, 1, set_group_size(piece_size)).
enactment_move(partition_extent_into_unit_pieces, 2, repeatedly_remove_group_size(extent)).
enactment_move(partition_extent_into_unit_pieces, 3, count_measured_groups(piece_count)).
enactment_move(partition_extent_into_unit_pieces, 4, preserve_leftover_as_remainder(leftover)).

enactment_move(pack_region_with_unit, 1, name_unit_region(unit)).
enactment_move(pack_region_with_unit, 2, tile_region_with_unit(dimensions)).
enactment_move(pack_region_with_unit, 3, count_unit_regions(unit_region_count)).
enactment_move(pack_region_with_unit, 4, compare_count_to_capacity(capacity)).

enactment_move(change_measured_quantity, 1, establish_common_measurement_unit(unit)).
enactment_move(change_measured_quantity, 2, perform_grounded_quantity_change(operands)).
enactment_move(change_measured_quantity, 3, retain_measurement_unit(result)).
enactment_move(change_measured_quantity, 4, contrast_bare_numeral(unit_dropped)).

enactment_move(compose_value_from_denominations, 1, establish_equivalence(denominations)).
enactment_move(compose_value_from_denominations, 2, iterate_conversion_group(holding)).
enactment_move(compose_value_from_denominations, 3, accumulate_total_value(total)).
enactment_move(compose_value_from_denominations, 4, spend_from_total(remainder)).

enactment_move(read_circular_scale, 1, place_hour_hand(hour)).
enactment_move(read_circular_scale, 2, iterate_five_minute_intervals(minute)).
enactment_move(read_circular_scale, 3, read_hand_separation(dial_angle)).
enactment_move(read_circular_scale, 4, name_half_day_period(period)).

enactment_move(bracket_unknown_measure, 1, propose_too_low(low_landmark)).
enactment_move(bracket_unknown_measure, 2, propose_about_right(nearest_landmark)).
enactment_move(bracket_unknown_measure, 3, propose_too_high(high_landmark)).
enactment_move(bracket_unknown_measure, 4, test_bracket_contains(actual)).
enactment_move(bracket_unknown_measure, 5, report_bracket_width(width)).

enactment_move(sort_against_benchmark, 1, fix_benchmark(benchmark)).
enactment_move(sort_against_benchmark, 2, compare_candidate_to_benchmark(candidates)).
enactment_move(sort_against_benchmark, 3, place_candidate_in_band(bands)).
enactment_move(sort_against_benchmark, 4, report_bands(band_report)).

enactment_move(resolve_measure_to_scale_grain, 1, fix_scale_grain(grain)).
enactment_move(resolve_measure_to_scale_grain, 2, round_measure_to_grain(measures)).
enactment_move(resolve_measure_to_scale_grain, 3, test_separation_at_grain(separation)).
enactment_move(resolve_measure_to_scale_grain, 4, report_what_the_scale_settles(verdict)).


%% ======================================================================
%% Lesson to form, with the evidence that licensed the reading
%% ======================================================================

%!  lesson_enactment_form(?Lesson, ?Form, ?Evidence) is nondet.
%
%   `Evidence` is `evidence(File, Line, Snippet)`. Snippet is the literal text
%   of that line in the live tree. A lesson may carry more than one form when
%   its task statement asks for more than one doing.

lesson_enactment_form('IM-G1-U6-L6', iterate_unit_along_extent,
    evidence('curriculum/im_teacher_guides/grade1/unit6/lesson6.md', 312,
             "Use paper clips to measure each strip of tape.")).
lesson_enactment_form('IM-G1-U6-L6', resolve_measure_to_scale_grain,
    evidence('curriculum/im_teacher_guides/grade1/unit6/lesson6.md', 217,
             "Andre says the workbook is 5 paper clips long.")).
lesson_enactment_form('IM-G1-U6-L8', iterate_unit_along_extent,
    evidence('curriculum/im_teacher_guides/grade1/unit6/lesson8.md', 157,
             "Represent your measurement using drawings,")).
lesson_enactment_form('IM-G1-U6-L9', iterate_unit_along_extent,
    evidence('curriculum/im_teacher_guides/grade1/unit6/lesson9.md', 161,
             "Give each group centimeter cubes.")).
lesson_enactment_form('IM-G1-U7-L13', read_circular_scale,
    evidence('curriculum/im_teacher_guides/grade1/unit7/lesson13.md', 409,
             "1. Circle the 3 clocks that show 5 o")).
lesson_enactment_form('IM-G2-U3-L1', iterate_unit_along_extent,
    evidence('curriculum/im_teacher_guides/grade2/unit3/lesson1.md', 160,
             "Use straws to measure your string. The string")).
lesson_enactment_form('IM-G2-U3-L1', resolve_measure_to_scale_grain,
    evidence('curriculum/im_teacher_guides/grade2/unit3/lesson1.md', 372,
             "2. Clare got 6 when she measured the same rectangle.")).
lesson_enactment_form('IM-G2-U3-L2', reunitize_same_extent,
    evidence('curriculum/im_teacher_guides/grade2/unit3/lesson2.md', 187,
             "1. Measure the length of the bearded dragon")).
lesson_enactment_form('IM-G2-U3-L4', bracket_unknown_measure,
    evidence('curriculum/im_teacher_guides/grade2/unit3/lesson4.md', 173,
             "1. Record an estimate that is:")).
lesson_enactment_form('IM-G2-U3-L5', iterate_unit_along_extent,
    evidence('curriculum/im_teacher_guides/grade2/unit3/lesson5.md', 162,
             "The tape pieces on the floor represent the lengths")).
lesson_enactment_form('IM-G2-U3-L5', sort_against_benchmark,
    evidence('curriculum/im_teacher_guides/grade2/unit3/lesson5.md', 396,
             "He measured it and said it was about 13")).
lesson_enactment_form('IM-G2-U3-L8', iterate_unit_along_extent,
    evidence('curriculum/im_teacher_guides/grade2/unit3/lesson8.md', 175,
             "1. Find 2 items that are about an inch long.")).
lesson_enactment_form('IM-G2-U3-L9', reunitize_same_extent,
    evidence('curriculum/im_teacher_guides/grade2/unit3/lesson9.md', 209,
             "1. Work with your group. Measure the tape strips")).
lesson_enactment_form('IM-G2-U3-L14', iterate_unit_along_extent,
    evidence('curriculum/im_teacher_guides/grade2/unit3/lesson14.md', 173,
             "1. Trace your hand. (Spread your fingers wide.)")).
lesson_enactment_form('IM-G2-U6-L11', read_circular_scale,
    evidence('curriculum/im_teacher_guides/grade2/unit6/lesson11.md', 177,
             "1. Circle the clock that shows 4 o")).
lesson_enactment_form('IM-G2-U6-L12', read_circular_scale,
    evidence('curriculum/im_teacher_guides/grade2/unit6/lesson12.md', 169,
             "1. Discuss 2 ways to read the time on this clock.")).
lesson_enactment_form('IM-G2-U6-L13', read_circular_scale,
    evidence('curriculum/im_teacher_guides/grade2/unit6/lesson13.md', 287,
             "Label each activity with a.m. or p.m.")).
lesson_enactment_form('IM-G2-U6-L15', compose_value_from_denominations,
    evidence('curriculum/im_teacher_guides/grade2/unit6/lesson15.md', 149,
             "Name the coins in each collection. Find the value in")).
lesson_enactment_form('IM-G2-U6-L18', compose_value_from_denominations,
    evidence('curriculum/im_teacher_guides/grade2/unit6/lesson18.md', 174,
             "pack of pencils     75")).
lesson_enactment_form('IM-G2-U6-L22', compose_value_from_denominations,
    evidence('curriculum/im_teacher_guides/grade2/unit6/lesson22.md', 141,
             "Han has $40 to spend this weekend. He and his")).
lesson_enactment_form('IM-G2-U9-L3', iterate_unit_along_extent,
    evidence('curriculum/im_teacher_guides/grade2/unit9/lesson3.md', 178,
             "Draw 3 lines on the map to show each trip. Each line")).
lesson_enactment_form('IM-G2-U9-L3', change_measured_quantity,
    evidence('curriculum/im_teacher_guides/grade2/unit9/lesson3.md', 178,
             "Draw 3 lines on the map to show each trip. Each line")).
lesson_enactment_form('IM-G3-U2-L7', sort_against_benchmark,
    evidence('curriculum/im_teacher_guides/grade3/unit2/lesson7.md', 149,
             "make sense to measure with square meters.")).
lesson_enactment_form('IM-G3-U3-L2', change_measured_quantity,
    evidence('curriculum/im_teacher_guides/grade3/unit3/lesson2.md', 199,
             "Solve each problem. Explain or show your")).
lesson_enactment_form('IM-G3-U3-L21', compose_value_from_denominations,
    evidence('curriculum/im_teacher_guides/grade3/unit3/lesson21.md', 177,
             "Imagine our class received $1,000 to spend on")).
lesson_enactment_form('IM-G3-U5-L12', partition_extent_into_unit_pieces,
    evidence('curriculum/im_teacher_guides/grade3/unit5/lesson12.md', 150,
             "Some students ran on the same trail at a park.")).
lesson_enactment_form('IM-G3-U5-L17', bracket_unknown_measure,
    evidence('curriculum/im_teacher_guides/grade3/unit5/lesson17.md', 88,
             "What is the length of this ladybug?")).
lesson_enactment_form('IM-G3-U6-L1', iterate_unit_along_extent,
    evidence('curriculum/im_teacher_guides/grade3/unit6/lesson1.md', 156,
             "Use the ruler from your teacher to measure the")).
lesson_enactment_form('IM-G3-U6-L2', bracket_unknown_measure,
    evidence('curriculum/im_teacher_guides/grade3/unit6/lesson2.md', 96,
             "What is the length of the paper clip?")).
lesson_enactment_form('IM-G3-U6-L3', iterate_unit_along_extent,
    evidence('curriculum/im_teacher_guides/grade3/unit6/lesson3.md', 105,
             "Look at the rulers you have been using to measure")).
lesson_enactment_form('IM-G3-U6-L3', resolve_measure_to_scale_grain,
    evidence('curriculum/im_teacher_guides/grade3/unit6/lesson3.md', 105,
             "Look at the rulers you have been using to measure")).
lesson_enactment_form('IM-G3-U6-L6', sort_against_benchmark,
    evidence('curriculum/im_teacher_guides/grade3/unit6/lesson6.md', 168,
             "This paper clip          This basket of apples weighs")).
lesson_enactment_form('IM-G3-U6-L9', bracket_unknown_measure,
    evidence('curriculum/im_teacher_guides/grade3/unit6/lesson9.md', 82,
             "This clock only has an hour hand.")).
lesson_enactment_form('IM-G3-U6-L10', change_measured_quantity,
    evidence('curriculum/im_teacher_guides/grade3/unit6/lesson10.md', 154,
             "1. Kiran arrived at the bus stop")).
lesson_enactment_form('IM-G3-U8-L5', compose_value_from_denominations,
    evidence('curriculum/im_teacher_guides/grade3/unit8/lesson5.md', 286,
             "What is the cost of kitchen plumbing and 18 square feet of tile?")).
lesson_enactment_form('IM-G3-U8-L14', bracket_unknown_measure,
    evidence('curriculum/im_teacher_guides/grade3/unit8/lesson14.md', 91,
             "What is the length of this earthworm?")).
lesson_enactment_form('IM-G4-U4-L23', sort_against_benchmark,
    evidence('curriculum/im_teacher_guides/grade4/unit4/lesson23.md', 139,
             "Here are some facts about insects.")).
lesson_enactment_form('IM-G4-U5-L9', reunitize_same_extent,
    evidence('curriculum/im_teacher_guides/grade4/unit5/lesson9.md', 321,
             "1.   a. Estimate: How many times do we fill the")).
lesson_enactment_form('IM-G4-U5-L10', reunitize_same_extent,
    evidence('curriculum/im_teacher_guides/grade4/unit5/lesson10.md', 162,
             "How are the three units related?")).
lesson_enactment_form('IM-G4-U5-L15', reunitize_same_extent,
    evidence('curriculum/im_teacher_guides/grade4/unit5/lesson15.md', 282,
             "While on an outing, a group of friends had a stone-")).
lesson_enactment_form('IM-G4-U6-L22', compose_value_from_denominations,
    evidence('curriculum/im_teacher_guides/grade4/unit6/lesson22.md', 151,
             "1. There are 45 students going on a field trip to a")).
lesson_enactment_form('IM-G4-U6-L26', iterate_unit_along_extent,
    evidence('curriculum/im_teacher_guides/grade4/unit6/lesson26.md', 145,
             "Follow these steps to make paper flowers:")).
lesson_enactment_form('IM-G4-U9-L10', bracket_unknown_measure,
    evidence('curriculum/im_teacher_guides/grade4/unit9/lesson10.md', 295,
             "Exploration activity for another group:")).
lesson_enactment_form('IM-G5-U2-L7', partition_extent_into_unit_pieces,
    evidence('curriculum/im_teacher_guides/grade5/unit2/lesson7.md', 155,
             "Solve each problem. Draw a diagram if it is helpful.")).
lesson_enactment_form('IM-G5-U2-L16', pack_region_with_unit,
    evidence('curriculum/im_teacher_guides/grade5/unit2/lesson16.md', 148,
             "Priya has enough materials to build a rectangular")).
lesson_enactment_form('IM-G5-U3-L13', partition_extent_into_unit_pieces,
    evidence('curriculum/im_teacher_guides/grade5/unit3/lesson13.md', 154,
             "These diagrams show strips of different colored")).
lesson_enactment_form('IM-G5-U3-L17', partition_extent_into_unit_pieces,
    evidence('curriculum/im_teacher_guides/grade5/unit3/lesson17.md', 252,
             "Solve each problem. Explain or show your")).
lesson_enactment_form('IM-G5-U4-L15', partition_extent_into_unit_pieces,
    evidence('curriculum/im_teacher_guides/grade5/unit4/lesson15.md', 146,
             "A Chinese food company cooked a single noodle")).
lesson_enactment_form('IM-G5-U4-L18', sort_against_benchmark,
    evidence('curriculum/im_teacher_guides/grade5/unit4/lesson18.md', 167,
             "1. Mai walked around a soccer field 2 times. She")).
lesson_enactment_form('IM-G5-U5-L7', resolve_measure_to_scale_grain,
    evidence('curriculum/im_teacher_guides/grade5/unit5/lesson7.md', 158,
             "1728 weigh 6.867 grams.")).
lesson_enactment_form('IM-G5-U6-L16', partition_extent_into_unit_pieces,
    evidence('curriculum/im_teacher_guides/grade5/unit6/lesson16.md', 133,
             "Kiran, Noah, and Elena each ran as far as they could")).
lesson_enactment_form('IM-G5-U8-L8', pack_region_with_unit,
    evidence('curriculum/im_teacher_guides/grade5/unit8/lesson8.md', 132,
             "The wagon bed is approximately 27 feet long, 13")).
lesson_enactment_form('IM-G5-U8-L15', bracket_unknown_measure,
    evidence('curriculum/im_teacher_guides/grade5/unit8/lesson15.md', 200,
             "1. Display your image for your classmates.")).


%!  enactment_refusal(?Lesson, ?Reason, ?MachineThatWouldLift) is nondet.
%
%   Lessons in the population that no form here reaches, each with the machine
%   that would be needed. A refusal is a standing task, not a verdict on the
%   lesson.

enactment_refusal('IM-G1-U5-L13',
    'The task statement is a center menu, so the lesson prescribes no \c
     measurement doing and the subclass label does not hold for it.',
    'A center-activity enactor that reads a named center from the center \c
     descriptions and runs its turn structure over the stage the lesson names.').
enactment_refusal('IM-G3-U8-L12',
    'The task statement asks a group to run a Notice and Wonder routine for \c
     another group, so the doing is facilitation rather than measurement.',
    'A classroom-routine enactor that instantiates the Notice and Wonder move \c
     sequence over a stated stimulus and drafts candidate noticings.').


%% ======================================================================
%% Lesson metadata
%% ======================================================================

lesson_source(L, P) :- lesson_meta(L, _, P).
lesson_grade(L, G) :- lesson_meta(L, G, _).

lesson_meta('IM-G1-U5-L13', '1', 'curriculum/im_teacher_guides/grade1/unit5/lesson13.md').
lesson_meta('IM-G1-U6-L6',  '1', 'curriculum/im_teacher_guides/grade1/unit6/lesson6.md').
lesson_meta('IM-G1-U6-L8',  '1', 'curriculum/im_teacher_guides/grade1/unit6/lesson8.md').
lesson_meta('IM-G1-U6-L9',  '1', 'curriculum/im_teacher_guides/grade1/unit6/lesson9.md').
lesson_meta('IM-G1-U7-L13', '1', 'curriculum/im_teacher_guides/grade1/unit7/lesson13.md').
lesson_meta('IM-G2-U3-L1',  '2', 'curriculum/im_teacher_guides/grade2/unit3/lesson1.md').
lesson_meta('IM-G2-U3-L2',  '2', 'curriculum/im_teacher_guides/grade2/unit3/lesson2.md').
lesson_meta('IM-G2-U3-L4',  '2', 'curriculum/im_teacher_guides/grade2/unit3/lesson4.md').
lesson_meta('IM-G2-U3-L5',  '2', 'curriculum/im_teacher_guides/grade2/unit3/lesson5.md').
lesson_meta('IM-G2-U3-L8',  '2', 'curriculum/im_teacher_guides/grade2/unit3/lesson8.md').
lesson_meta('IM-G2-U3-L9',  '2', 'curriculum/im_teacher_guides/grade2/unit3/lesson9.md').
lesson_meta('IM-G2-U3-L14', '2', 'curriculum/im_teacher_guides/grade2/unit3/lesson14.md').
lesson_meta('IM-G2-U6-L11', '2', 'curriculum/im_teacher_guides/grade2/unit6/lesson11.md').
lesson_meta('IM-G2-U6-L12', '2', 'curriculum/im_teacher_guides/grade2/unit6/lesson12.md').
lesson_meta('IM-G2-U6-L13', '2', 'curriculum/im_teacher_guides/grade2/unit6/lesson13.md').
lesson_meta('IM-G2-U6-L15', '2', 'curriculum/im_teacher_guides/grade2/unit6/lesson15.md').
lesson_meta('IM-G2-U6-L18', '2', 'curriculum/im_teacher_guides/grade2/unit6/lesson18.md').
lesson_meta('IM-G2-U6-L22', '2', 'curriculum/im_teacher_guides/grade2/unit6/lesson22.md').
lesson_meta('IM-G2-U9-L3',  '2', 'curriculum/im_teacher_guides/grade2/unit9/lesson3.md').
lesson_meta('IM-G3-U2-L7',  '3', 'curriculum/im_teacher_guides/grade3/unit2/lesson7.md').
lesson_meta('IM-G3-U3-L2',  '3', 'curriculum/im_teacher_guides/grade3/unit3/lesson2.md').
lesson_meta('IM-G3-U3-L21', '3', 'curriculum/im_teacher_guides/grade3/unit3/lesson21.md').
lesson_meta('IM-G3-U5-L12', '3', 'curriculum/im_teacher_guides/grade3/unit5/lesson12.md').
lesson_meta('IM-G3-U5-L17', '3', 'curriculum/im_teacher_guides/grade3/unit5/lesson17.md').
lesson_meta('IM-G3-U6-L1',  '3', 'curriculum/im_teacher_guides/grade3/unit6/lesson1.md').
lesson_meta('IM-G3-U6-L2',  '3', 'curriculum/im_teacher_guides/grade3/unit6/lesson2.md').
lesson_meta('IM-G3-U6-L3',  '3', 'curriculum/im_teacher_guides/grade3/unit6/lesson3.md').
lesson_meta('IM-G3-U6-L6',  '3', 'curriculum/im_teacher_guides/grade3/unit6/lesson6.md').
lesson_meta('IM-G3-U6-L9',  '3', 'curriculum/im_teacher_guides/grade3/unit6/lesson9.md').
lesson_meta('IM-G3-U6-L10', '3', 'curriculum/im_teacher_guides/grade3/unit6/lesson10.md').
lesson_meta('IM-G3-U8-L5',  '3', 'curriculum/im_teacher_guides/grade3/unit8/lesson5.md').
lesson_meta('IM-G3-U8-L12', '3', 'curriculum/im_teacher_guides/grade3/unit8/lesson12.md').
lesson_meta('IM-G3-U8-L14', '3', 'curriculum/im_teacher_guides/grade3/unit8/lesson14.md').
lesson_meta('IM-G4-U4-L23', '4', 'curriculum/im_teacher_guides/grade4/unit4/lesson23.md').
lesson_meta('IM-G4-U5-L9',  '4', 'curriculum/im_teacher_guides/grade4/unit5/lesson9.md').
lesson_meta('IM-G4-U5-L10', '4', 'curriculum/im_teacher_guides/grade4/unit5/lesson10.md').
lesson_meta('IM-G4-U5-L15', '4', 'curriculum/im_teacher_guides/grade4/unit5/lesson15.md').
lesson_meta('IM-G4-U6-L22', '4', 'curriculum/im_teacher_guides/grade4/unit6/lesson22.md').
lesson_meta('IM-G4-U6-L26', '4', 'curriculum/im_teacher_guides/grade4/unit6/lesson26.md').
lesson_meta('IM-G4-U9-L10', '4', 'curriculum/im_teacher_guides/grade4/unit9/lesson10.md').
lesson_meta('IM-G5-U2-L7',  '5', 'curriculum/im_teacher_guides/grade5/unit2/lesson7.md').
lesson_meta('IM-G5-U2-L16', '5', 'curriculum/im_teacher_guides/grade5/unit2/lesson16.md').
lesson_meta('IM-G5-U3-L13', '5', 'curriculum/im_teacher_guides/grade5/unit3/lesson13.md').
lesson_meta('IM-G5-U3-L17', '5', 'curriculum/im_teacher_guides/grade5/unit3/lesson17.md').
lesson_meta('IM-G5-U4-L15', '5', 'curriculum/im_teacher_guides/grade5/unit4/lesson15.md').
lesson_meta('IM-G5-U4-L18', '5', 'curriculum/im_teacher_guides/grade5/unit4/lesson18.md').
lesson_meta('IM-G5-U5-L7',  '5', 'curriculum/im_teacher_guides/grade5/unit5/lesson7.md').
lesson_meta('IM-G5-U6-L16', '5', 'curriculum/im_teacher_guides/grade5/unit6/lesson16.md').
lesson_meta('IM-G5-U8-L8',  '5', 'curriculum/im_teacher_guides/grade5/unit8/lesson8.md').
lesson_meta('IM-G5-U8-L15', '5', 'curriculum/im_teacher_guides/grade5/unit8/lesson15.md').


%% ======================================================================
%% Inputs, with provenance
%% ======================================================================

%!  enactment_input(?Lesson, ?Form, ?Inputs) is nondet.
%
%   `Inputs` is a list of `input(Key, Value, Provenance)` whose first element is
%   always `input(form, Form, derived(lesson_enactment_form))`, so `enact/3` can
%   read the form off the input list and stay semidet. A lesson may carry more
%   than one input set for the same form when the lesson poses the same doing
%   at two settings (IM-G5-U5-L7 weighs its coins on two scales).

enactment_input(L, F, [input(form, F, derived(lesson_enactment_form))|Rest]) :-
    lesson_inputs(L, F, Rest).

% --- iterate_unit_along_extent -----------------------------------------
lesson_inputs('IM-G1-U6-L6', iterate_unit_along_extent,
    [ input(unit, paper_clip, curriculum('curriculum/im_teacher_guides/grade1/unit6/lesson6.md', 312)),
      input(subdivisions, 1, derived(whole_units_only)),
      input(unit_count, 5, curriculum('curriculum/im_teacher_guides/grade1/unit6/lesson6.md', 217))
    ]).
lesson_inputs('IM-G1-U6-L8', iterate_unit_along_extent,
    [ input(unit, centimeter_cube, curriculum('curriculum/im_teacher_guides/grade1/unit6/lesson8.md', 51)),
      input(subdivisions, 1, derived(whole_units_only)),
      input(unit_count, 110, stand_in('The string is cut in the classroom. 110 is the upper bound the lesson states for the lengths it expects.'))
    ]).
lesson_inputs('IM-G1-U6-L9', iterate_unit_along_extent,
    [ input(unit, centimeter_cube, curriculum('curriculum/im_teacher_guides/grade1/unit6/lesson9.md', 161)),
      input(subdivisions, 1, derived(whole_units_only)),
      input(unit_count, 24, stand_in('The animal strip is taped up in the classroom, so the machine supplies a length of 24 cubes.'))
    ]).
lesson_inputs('IM-G2-U3-L1', iterate_unit_along_extent,
    [ input(unit, centimeter_cube, curriculum('curriculum/im_teacher_guides/grade2/unit3/lesson1.md', 363)),
      input(subdivisions, 1, derived(whole_units_only)),
      input(unit_count, 6, curriculum('curriculum/im_teacher_guides/grade2/unit3/lesson1.md', 372))
    ]).
lesson_inputs('IM-G2-U3-L5', iterate_unit_along_extent,
    [ input(unit, meter, curriculum('curriculum/im_teacher_guides/grade2/unit3/lesson5.md', 162)),
      input(subdivisions, 1, derived(whole_units_only)),
      input(unit_count, 3, stand_in('The reptile tapes are laid on the classroom floor, so the machine supplies a Gila monster of 3 meters.'))
    ]).
lesson_inputs('IM-G2-U3-L8', iterate_unit_along_extent,
    [ input(unit, inch, curriculum('curriculum/im_teacher_guides/grade2/unit3/lesson8.md', 175)),
      input(subdivisions, 1, derived(whole_units_only)),
      input(unit_count, 7, stand_in('The marker and the book come from the room, so the machine supplies a marker of 7 inches.'))
    ]).
lesson_inputs('IM-G2-U3-L14', iterate_unit_along_extent,
    [ input(unit, inch, curriculum('curriculum/im_teacher_guides/grade2/unit3/lesson14.md', 173)),
      input(subdivisions, 1, derived(whole_units_only)),
      input(unit_count, 6, curriculum('curriculum/im_teacher_guides/grade2/unit3/lesson14.md', 391))
    ]).
lesson_inputs('IM-G2-U9-L3', iterate_unit_along_extent,
    [ input(unit, centimeter, curriculum('curriculum/im_teacher_guides/grade2/unit9/lesson3.md', 178)),
      input(subdivisions, 1, derived(whole_units_only)),
      input(unit_count, 8, stand_in('The line from Trenton to Harrisburg is drawn by the student, so the machine supplies 8 centimeters.'))
    ]).
lesson_inputs('IM-G3-U6-L1', iterate_unit_along_extent,
    [ input(unit, inch, curriculum('curriculum/im_teacher_guides/grade3/unit6/lesson1.md', 156)),
      input(subdivisions, 2, curriculum('curriculum/im_teacher_guides/grade3/unit6/lesson1.md', 238)),
      input(unit_count, 7, stand_in('The objects come from the room, so the machine supplies an object of seven half-inches.'))
    ]).
lesson_inputs('IM-G3-U6-L3', iterate_unit_along_extent,
    [ input(unit, inch, curriculum('curriculum/im_teacher_guides/grade3/unit6/lesson3.md', 105)),
      input(subdivisions, 4, curriculum('curriculum/im_teacher_guides/grade3/unit6/lesson3.md', 9)),
      input(unit_count, 14, stand_in('The objects come from the room, so the machine supplies an object of fourteen quarter-inches.'))
    ]).
lesson_inputs('IM-G4-U6-L26', iterate_unit_along_extent,
    [ input(unit, inch, curriculum('curriculum/im_teacher_guides/grade4/unit6/lesson26.md', 145)),
      input(subdivisions, 1, derived(whole_units_only)),
      input(unit_count, 11, stand_in('The tissue paper is handed out in class, so the machine supplies a sheet that takes eleven one-inch folds.'))
    ]).

% --- reunitize_same_extent ---------------------------------------------
lesson_inputs('IM-G2-U3-L2', reunitize_same_extent,
    [ input(from_unit, ten_centimeter_tool, curriculum('curriculum/im_teacher_guides/grade2/unit3/lesson2.md', 187)),
      input(to_unit, centimeter, curriculum('curriculum/im_teacher_guides/grade2/unit3/lesson2.md', 187)),
      input(conversion_factor, 10, curriculum('curriculum/im_teacher_guides/grade2/unit3/lesson2.md', 187)),
      input(unit_count, 2, stand_in('The bearded dragon picture is handed out, so the machine supplies a length of two ten-centimeter tools.'))
    ]).
lesson_inputs('IM-G2-U3-L9', reunitize_same_extent,
    [ input(from_unit, foot, curriculum('curriculum/im_teacher_guides/grade2/unit3/lesson9.md', 219)),
      input(to_unit, inch, curriculum('curriculum/im_teacher_guides/grade2/unit3/lesson9.md', 219)),
      input(conversion_factor, 12, curriculum('curriculum/im_teacher_guides/grade2/unit3/lesson9.md', 219)),
      input(unit_count, 16, curriculum('curriculum/im_teacher_guides/grade2/unit3/lesson9.md', 473))
    ]).
lesson_inputs('IM-G4-U5-L9', reunitize_same_extent,
    [ input(from_unit, kilogram, curriculum('curriculum/im_teacher_guides/grade4/unit5/lesson9.md', 187)),
      input(to_unit, gram, curriculum('curriculum/im_teacher_guides/grade4/unit5/lesson9.md', 187)),
      input(conversion_factor, 1000, curriculum('curriculum/im_teacher_guides/grade4/unit5/lesson9.md', 187)),
      input(unit_count, 2, curriculum('curriculum/im_teacher_guides/grade4/unit5/lesson9.md', 187))
    ]).
lesson_inputs('IM-G4-U5-L9', reunitize_same_extent,
    [ input(from_unit, liter, curriculum('curriculum/im_teacher_guides/grade4/unit5/lesson9.md', 321)),
      input(to_unit, hundred_milliliter_glass, curriculum('curriculum/im_teacher_guides/grade4/unit5/lesson9.md', 321)),
      input(conversion_factor, 10, curriculum('curriculum/im_teacher_guides/grade4/unit5/lesson9.md', 321)),
      input(unit_count, 1, curriculum('curriculum/im_teacher_guides/grade4/unit5/lesson9.md', 321))
    ]).
lesson_inputs('IM-G4-U5-L10', reunitize_same_extent,
    [ input(from_unit, meter, curriculum('curriculum/im_teacher_guides/grade4/unit5/lesson10.md', 162)),
      input(to_unit, centimeter, curriculum('curriculum/im_teacher_guides/grade4/unit5/lesson10.md', 162)),
      input(conversion_factor, 100, curriculum('curriculum/im_teacher_guides/grade4/unit5/lesson10.md', 162)),
      input(unit_count, 30, curriculum('curriculum/im_teacher_guides/grade4/unit5/lesson10.md', 163))
    ]).
lesson_inputs('IM-G4-U5-L15', reunitize_same_extent,
    [ input(from_unit, foot, curriculum('curriculum/im_teacher_guides/grade4/unit5/lesson15.md', 285)),
      input(to_unit, inch, curriculum('curriculum/im_teacher_guides/grade4/unit5/lesson15.md', 285)),
      input(conversion_factor, 12, curriculum('curriculum/im_teacher_guides/grade4/unit5/lesson15.md', 285)),
      input(unit_count, 4, curriculum('curriculum/im_teacher_guides/grade4/unit5/lesson15.md', 285))
    ]).

% --- partition_extent_into_unit_pieces ---------------------------------
lesson_inputs('IM-G3-U5-L12', partition_extent_into_unit_pieces,
    [ input(unit, trail, curriculum('curriculum/im_teacher_guides/grade3/unit5/lesson12.md', 150)),
      input(subunits_per_whole, 8, stand_in('The fractions are absent from the extracted text, so the machine partitions the trail into eighths.')),
      input(extent_in_subunits, 8, derived(one_whole_trail)),
      input(piece_in_subunits, 2, stand_in('The machine reads Elena''s share as two eighths of the trail.'))
    ]).
lesson_inputs('IM-G5-U2-L7', partition_extent_into_unit_pieces,
    [ input(unit, mile, curriculum('curriculum/im_teacher_guides/grade5/unit2/lesson7.md', 157)),
      input(subunits_per_whole, 3, stand_in('The fraction of the road is absent from the extracted text, so the machine reads it as thirds.')),
      input(extent_in_subunits, 27, curriculum('curriculum/im_teacher_guides/grade5/unit2/lesson7.md', 157)),
      input(piece_in_subunits, 1, derived(unit_fraction_piece))
    ]).
lesson_inputs('IM-G5-U3-L13', partition_extent_into_unit_pieces,
    [ input(unit, foot, curriculum('curriculum/im_teacher_guides/grade5/unit3/lesson13.md', 156)),
      input(subunits_per_whole, 3, stand_in('The piece size is absent from the extracted text, so the machine cuts the strip into thirds of a foot.')),
      input(extent_in_subunits, 6, curriculum('curriculum/im_teacher_guides/grade5/unit3/lesson13.md', 156)),
      input(piece_in_subunits, 1, derived(unit_fraction_piece))
    ]).
lesson_inputs('IM-G5-U3-L17', partition_extent_into_unit_pieces,
    [ input(unit, gram, curriculum('curriculum/im_teacher_guides/grade5/unit3/lesson17.md', 254)),
      input(subunits_per_whole, 11, derived(one_grain_per_eleventh)),
      input(extent_in_subunits, 11, curriculum('curriculum/im_teacher_guides/grade5/unit3/lesson17.md', 254)),
      input(piece_in_subunits, 1, derived(one_grain_of_rice))
    ]).
lesson_inputs('IM-G5-U4-L15', partition_extent_into_unit_pieces,
    [ input(unit, foot, curriculum('curriculum/im_teacher_guides/grade5/unit4/lesson15.md', 146)),
      input(subunits_per_whole, 1, derived(whole_units_only)),
      input(extent_in_subunits, 10119, curriculum('curriculum/im_teacher_guides/grade5/unit4/lesson15.md', 147)),
      input(piece_in_subunits, 400, curriculum('curriculum/im_teacher_guides/grade5/unit4/lesson15.md', 147))
    ]).
lesson_inputs('IM-G5-U6-L16', partition_extent_into_unit_pieces,
    [ input(unit, mile, curriculum('curriculum/im_teacher_guides/grade5/unit6/lesson16.md', 135)),
      input(subunits_per_whole, 8, stand_in('The three fractions of the trail are absent from the extracted text, so the machine partitions into eighths.')),
      input(extent_in_subunits, 40, derived(five_mile_trail_in_eighths)),
      input(piece_in_subunits, 5, derived(one_eighth_of_five_miles))
    ]).

% --- pack_region_with_unit ---------------------------------------------
lesson_inputs('IM-G5-U2-L16', pack_region_with_unit,
    [ input(unit, square_foot, curriculum('curriculum/im_teacher_guides/grade5/unit2/lesson16.md', 148)),
      input(region, rectangle_from_area(36, 9), curriculum('curriculum/im_teacher_guides/grade5/unit2/lesson16.md', 148)),
      input(capacity, none, derived(no_capacity_stated))
    ]).
lesson_inputs('IM-G5-U8-L8', pack_region_with_unit,
    [ input(unit, cubic_foot, curriculum('curriculum/im_teacher_guides/grade5/unit8/lesson8.md', 132)),
      input(region, box(27, 13, 2), curriculum('curriculum/im_teacher_guides/grade5/unit8/lesson8.md', 132)),
      input(capacity, 9, curriculum('curriculum/im_teacher_guides/grade5/unit8/lesson8.md', 134))
    ]).

% --- change_measured_quantity ------------------------------------------
lesson_inputs('IM-G2-U9-L3', change_measured_quantity,
    [ input(unit, centimeter, curriculum('curriculum/im_teacher_guides/grade2/unit9/lesson3.md', 178)),
      input(operation, add, curriculum('curriculum/im_teacher_guides/grade2/unit9/lesson3.md', 191)),
      input(left, 8, stand_in('The lines are drawn by the student, so the machine supplies 8 centimeters for the first leg.')),
      input(right, 5, stand_in('The machine supplies 5 centimeters for the second leg.'))
    ]).
lesson_inputs('IM-G3-U3-L2', change_measured_quantity,
    [ input(unit, foot, curriculum('curriculum/im_teacher_guides/grade3/unit3/lesson2.md', 205)),
      input(operation, add, curriculum('curriculum/im_teacher_guides/grade3/unit3/lesson2.md', 205)),
      input(left, 115, curriculum('curriculum/im_teacher_guides/grade3/unit3/lesson2.md', 205)),
      input(right, 131, curriculum('curriculum/im_teacher_guides/grade3/unit3/lesson2.md', 205))
    ]).
lesson_inputs('IM-G3-U6-L10', change_measured_quantity,
    [ input(unit, minute_past_midnight, curriculum('curriculum/im_teacher_guides/grade3/unit6/lesson10.md', 156)),
      input(operation, add, curriculum('curriculum/im_teacher_guides/grade3/unit6/lesson10.md', 159)),
      input(left, 927, curriculum('curriculum/im_teacher_guides/grade3/unit6/lesson10.md', 156)),
      input(right, 24, curriculum('curriculum/im_teacher_guides/grade3/unit6/lesson10.md', 159))
    ]).

% --- compose_value_from_denominations ----------------------------------
lesson_inputs('IM-G2-U6-L15', compose_value_from_denominations,
    [ input(value_unit, cent, curriculum('curriculum/im_teacher_guides/grade2/unit6/lesson15.md', 149)),
      input(denominations, [d(dime, 10), d(nickel, 5), d(penny, 1)],
            curriculum('curriculum/im_teacher_guides/grade2/unit6/lesson15.md', 149)),
      input(holding, [h(dime, 0), h(nickel, 2), h(penny, 0)],
            stand_in('Andre''s collection is an image the extraction drops, so the machine supplies two nickels, one of the two ways the task asks for to make ten cents.')),
      input(cost, none, derived(no_purchase_in_this_task))
    ]).
lesson_inputs('IM-G2-U6-L18', compose_value_from_denominations,
    [ input(value_unit, cent, curriculum('curriculum/im_teacher_guides/grade2/unit6/lesson18.md', 174)),
      input(denominations, [d(dime, 10), d(nickel, 5), d(penny, 1)],
            curriculum('curriculum/im_teacher_guides/grade2/unit6/lesson18.md', 174)),
      input(holding, [h(dime, 7), h(nickel, 2), h(penny, 3)],
            stand_in('Lin''s coins are an image the extraction drops, so the machine supplies a collection worth 83 cents.')),
      input(cost, 45, curriculum('curriculum/im_teacher_guides/grade2/unit6/lesson18.md', 176))
    ]).
lesson_inputs('IM-G2-U6-L22', compose_value_from_denominations,
    [ input(value_unit, dollar, curriculum('curriculum/im_teacher_guides/grade2/unit6/lesson22.md', 141)),
      input(denominations, [d(dollar, 1)],
            curriculum('curriculum/im_teacher_guides/grade2/unit6/lesson22.md', 141)),
      input(holding, [h(dollar, 40)],
            curriculum('curriculum/im_teacher_guides/grade2/unit6/lesson22.md', 141)),
      input(cost, 23, curriculum('curriculum/im_teacher_guides/grade2/unit6/lesson22.md', 144))
    ]).
lesson_inputs('IM-G3-U3-L21', compose_value_from_denominations,
    [ input(value_unit, dollar, curriculum('curriculum/im_teacher_guides/grade3/unit3/lesson21.md', 177)),
      input(denominations, [d(dollar, 1)],
            curriculum('curriculum/im_teacher_guides/grade3/unit3/lesson21.md', 177)),
      input(holding, [h(dollar, 1000)],
            curriculum('curriculum/im_teacher_guides/grade3/unit3/lesson21.md', 177)),
      input(cost, 664, stand_in('The purchase plan is the student''s to make, so the machine spends on a box of 25 markers, a set of history books, and a nature set: 5 + 259 + 400 dollars.'))
    ]).
lesson_inputs('IM-G3-U8-L5', compose_value_from_denominations,
    [ input(value_unit, dollar, curriculum('curriculum/im_teacher_guides/grade3/unit8/lesson5.md', 307)),
      input(denominations, [d(square_foot_of_tile, 5), d(kitchen_plumbing_job, 253)],
            curriculum('curriculum/im_teacher_guides/grade3/unit8/lesson5.md', 307)),
      input(holding, [h(square_foot_of_tile, 18), h(kitchen_plumbing_job, 1)],
            curriculum('curriculum/im_teacher_guides/grade3/unit8/lesson5.md', 286)),
      input(cost, none, derived(the_task_asks_for_the_total_not_the_change))
    ]).
lesson_inputs('IM-G4-U6-L22', compose_value_from_denominations,
    [ input(value_unit, dollar, curriculum('curriculum/im_teacher_guides/grade4/unit6/lesson22.md', 151)),
      input(denominations, [d(dollar, 1)],
            curriculum('curriculum/im_teacher_guides/grade4/unit6/lesson22.md', 152)),
      input(holding, [h(dollar, 900)],
            curriculum('curriculum/im_teacher_guides/grade4/unit6/lesson22.md', 152)),
      input(cost, 810, curriculum('curriculum/im_teacher_guides/grade4/unit6/lesson22.md', 151))
    ]).

% --- read_circular_scale -----------------------------------------------
lesson_inputs('IM-G1-U7-L13', read_circular_scale,
    [ input(hour, 5, curriculum('curriculum/im_teacher_guides/grade1/unit7/lesson13.md', 409)),
      input(minute, 0, curriculum('curriculum/im_teacher_guides/grade1/unit7/lesson13.md', 409)),
      input(period, unstated, derived(the_task_states_no_half_day))
    ]).
lesson_inputs('IM-G2-U6-L11', read_circular_scale,
    [ input(hour, 7, curriculum('curriculum/im_teacher_guides/grade2/unit6/lesson11.md', 180)),
      input(minute, 30, curriculum('curriculum/im_teacher_guides/grade2/unit6/lesson11.md', 180)),
      input(period, unstated, derived(the_task_states_no_half_day))
    ]).
lesson_inputs('IM-G2-U6-L12', read_circular_scale,
    [ input(hour, 4, curriculum('curriculum/im_teacher_guides/grade2/unit6/lesson12.md', 170)),
      input(minute, 30, curriculum('curriculum/im_teacher_guides/grade2/unit6/lesson12.md', 170)),
      input(period, unstated, derived(the_task_states_no_half_day))
    ]).
lesson_inputs('IM-G2-U6-L13', read_circular_scale,
    [ input(hour, 7, curriculum('curriculum/im_teacher_guides/grade2/unit6/lesson13.md', 172)),
      input(minute, 0, curriculum('curriculum/im_teacher_guides/grade2/unit6/lesson13.md', 172)),
      input(period, am, curriculum('curriculum/im_teacher_guides/grade2/unit6/lesson13.md', 172))
    ]).

% --- bracket_unknown_measure -------------------------------------------
lesson_inputs('IM-G2-U3-L4', bracket_unknown_measure,
    [ input(unit, centimeter, curriculum('curriculum/im_teacher_guides/grade2/unit3/lesson4.md', 168)),
      input(grain, 10, derived(round_to_tens_of_centimeters)),
      input(actual, 18, stand_in('The notebook is on the desk in front of the class, so the machine supplies 18 centimeters, inside the 5 to 30 centimeter band the lesson prepares.'))
    ]).
lesson_inputs('IM-G3-U5-L17', bracket_unknown_measure,
    [ input(unit, millimeter, curriculum('curriculum/im_teacher_guides/grade3/unit5/lesson17.md', 88)),
      input(grain, 5, derived(round_to_five_millimeters)),
      input(actual, 8, stand_in('The ladybug picture carries no stated length, so the machine supplies 8 millimeters.'))
    ]).
lesson_inputs('IM-G3-U6-L2', bracket_unknown_measure,
    [ input(unit, quarter_inch, curriculum('curriculum/im_teacher_guides/grade3/unit6/lesson2.md', 96)),
      input(grain, 4, derived(round_to_whole_inches)),
      input(actual, 5, stand_in('The paper clip picture carries no stated length, so the machine supplies five quarter-inches.'))
    ]).
lesson_inputs('IM-G3-U6-L9', bracket_unknown_measure,
    [ input(unit, minute_past_the_hour, curriculum('curriculum/im_teacher_guides/grade3/unit6/lesson9.md', 82)),
      input(grain, 15, derived(round_to_quarter_hours)),
      input(actual, 20, stand_in('The clock in the image has only an hour hand, so the machine supplies 20 minutes past the hour as the time it is set to.'))
    ]).
lesson_inputs('IM-G3-U8-L14', bracket_unknown_measure,
    [ input(unit, centimeter, curriculum('curriculum/im_teacher_guides/grade3/unit8/lesson14.md', 91)),
      input(grain, 5, derived(round_to_five_centimeters)),
      input(actual, 12, stand_in('The earthworm picture carries no stated length, so the machine supplies 12 centimeters.'))
    ]).
lesson_inputs('IM-G4-U9-L10', bracket_unknown_measure,
    [ input(unit, item, curriculum('curriculum/im_teacher_guides/grade4/unit9/lesson10.md', 298)),
      input(grain, 50, derived(round_to_fifties)),
      input(actual, 175, stand_in('The image is the group''s own, so the machine supplies a count of 175 items for the quantity being estimated.'))
    ]).
lesson_inputs('IM-G5-U8-L15', bracket_unknown_measure,
    [ input(unit, umbrella, curriculum('curriculum/im_teacher_guides/grade5/unit8/lesson15.md', 85)),
      input(grain, 25, derived(round_to_twenty_fives)),
      input(actual, 88, stand_in('The umbrella image carries no stated count, so the machine supplies 88 umbrellas.'))
    ]).

% --- sort_against_benchmark --------------------------------------------
lesson_inputs('IM-G2-U3-L5', sort_against_benchmark,
    [ input(base_unit, centimeter, curriculum('curriculum/im_teacher_guides/grade2/unit3/lesson5.md', 396)),
      input(benchmark, band_bounds([30, 300], [handheld, room_sized, larger_than_a_room]),
            derived(bands_around_a_held_animal_and_a_classroom)),
      input(candidates, [c(noah_gecko_claim, 1300), c(a_gecko_that_fits_in_two_hands, 15)],
            curriculum('curriculum/im_teacher_guides/grade2/unit3/lesson5.md', 396))
    ]).
lesson_inputs('IM-G3-U2-L7', sort_against_benchmark,
    [ input(base_unit, square_centimeter, curriculum('curriculum/im_teacher_guides/grade3/unit2/lesson7.md', 149)),
      input(benchmark, band_bounds([100, 10000], [square_centimeters, square_feet, square_meters]),
            curriculum('curriculum/im_teacher_guides/grade3/unit2/lesson7.md', 240)),
      input(candidates, [c(playing_card, 58), c(sticky_note, 55),
                         c(top_of_a_student_desk, 5100), c(classroom_floor, 30000)],
            curriculum('curriculum/im_teacher_guides/grade3/unit2/lesson7.md', 240))
    ]).
lesson_inputs('IM-G3-U6-L6', sort_against_benchmark,
    [ input(base_unit, gram, curriculum('curriculum/im_teacher_guides/grade3/unit6/lesson6.md', 168)),
      input(benchmark, band_bounds([1, 100, 1000],
                                   [less_than_one_gram, one_to_a_hundred_grams,
                                    a_hundred_grams_to_a_kilogram, more_than_a_kilogram]),
            curriculum('curriculum/im_teacher_guides/grade3/unit6/lesson6.md', 183)),
      input(candidates, [c(paper_clip, 1), c(basket_of_apples, 1000)],
            curriculum('curriculum/im_teacher_guides/grade3/unit6/lesson6.md', 168))
    ]).
lesson_inputs('IM-G4-U4-L23', sort_against_benchmark,
    [ input(base_unit, tenth_of_a_millimeter, curriculum('curriculum/im_teacher_guides/grade4/unit4/lesson23.md', 145)),
      input(benchmark, band_bounds([40, 100], [ant_sized, termite_sized, bee_sized]),
            curriculum('curriculum/im_teacher_guides/grade4/unit4/lesson23.md', 145)),
      input(candidates, [c(odorous_house_ant, 15), c(termite, 40), c(honey_bee, 100)],
            curriculum('curriculum/im_teacher_guides/grade4/unit4/lesson23.md', 145))
    ]).
lesson_inputs('IM-G5-U4-L18', sort_against_benchmark,
    [ input(base_unit, meter, curriculum('curriculum/im_teacher_guides/grade5/unit4/lesson18.md', 167)),
      input(benchmark, band_bounds([800, 1200],
                                   [less_than_a_kilometer, about_a_kilometer, more_than_a_kilometer]),
            curriculum('curriculum/im_teacher_guides/grade5/unit4/lesson18.md', 170)),
      input(candidates, [c(two_laps_of_a_soccer_field, 700),
                         c(school_room_to_the_restroom, 40),
                         c(across_the_state, 400000)],
            stand_in('The distances are the class''s own, so the machine supplies a soccer field of 350 meters per lap and a school corridor of 40 meters.'))
    ]).

% --- resolve_measure_to_scale_grain ------------------------------------
lesson_inputs('IM-G5-U5-L7', resolve_measure_to_scale_grain,
    [ input(scale_base, thousandth_of_a_gram, curriculum('curriculum/im_teacher_guides/grade5/unit5/lesson7.md', 158)),
      input(reading_mode, distinct_objects, curriculum('curriculum/im_teacher_guides/grade5/unit5/lesson7.md', 162)),
      input(grain, 100, curriculum('curriculum/im_teacher_guides/grade5/unit5/lesson7.md', 162)),
      input(measures, [m(minted_before_1728, 6867), m(minted_after_1728, 6766)],
            curriculum('curriculum/im_teacher_guides/grade5/unit5/lesson7.md', 158))
    ]).
lesson_inputs('IM-G5-U5-L7', resolve_measure_to_scale_grain,
    [ input(scale_base, thousandth_of_a_gram, curriculum('curriculum/im_teacher_guides/grade5/unit5/lesson7.md', 158)),
      input(reading_mode, distinct_objects, curriculum('curriculum/im_teacher_guides/grade5/unit5/lesson7.md', 165)),
      input(grain, 1000, curriculum('curriculum/im_teacher_guides/grade5/unit5/lesson7.md', 165)),
      input(measures, [m(minted_before_1728, 6867), m(minted_after_1728, 6766)],
            curriculum('curriculum/im_teacher_guides/grade5/unit5/lesson7.md', 158))
    ]).
lesson_inputs('IM-G1-U6-L6', resolve_measure_to_scale_grain,
    [ input(scale_base, paper_clip, curriculum('curriculum/im_teacher_guides/grade1/unit6/lesson6.md', 312)),
      input(reading_mode, same_object, curriculum('curriculum/im_teacher_guides/grade1/unit6/lesson6.md', 217)),
      input(grain, 1, derived(one_paper_clip_is_the_finest_interval)),
      input(measures, [m(andre, 5), m(tyler, 7), m(clare, 8)],
            curriculum('curriculum/im_teacher_guides/grade1/unit6/lesson6.md', 217))
    ]).
lesson_inputs('IM-G2-U3-L1', resolve_measure_to_scale_grain,
    [ input(scale_base, centimeter_cube, curriculum('curriculum/im_teacher_guides/grade2/unit3/lesson1.md', 363)),
      input(reading_mode, same_object, curriculum('curriculum/im_teacher_guides/grade2/unit3/lesson1.md', 372)),
      input(grain, 1, derived(one_cube_is_the_finest_interval)),
      input(measures, [m(clare, 6), m(the_reader, 5)],
            stand_in('The lesson prints Clare''s 6 and leaves the reader''s own count blank, so the machine supplies 5 as the count the reader would record.'))
    ]).
lesson_inputs('IM-G3-U6-L3', resolve_measure_to_scale_grain,
    [ input(scale_base, quarter_inch, curriculum('curriculum/im_teacher_guides/grade3/unit6/lesson3.md', 9)),
      input(reading_mode, same_object, curriculum('curriculum/im_teacher_guides/grade3/unit6/lesson3.md', 295)),
      input(grain, 2, derived(a_half_inch_ruler_reads_two_quarter_inches_at_a_time)),
      input(measures, [m(on_the_fourths_ruler, 6), m(on_the_halves_ruler, 6)],
            stand_in('The object list is filled in class, so the machine supplies a length of six quarter-inches read on both rulers.'))
    ]).


%% ======================================================================
%% enact/3
%% ======================================================================

%!  enact(+Lesson, +Inputs, -Enactment) is semidet.
%
%   Run the form named in `Inputs` over the values in `Inputs`. Fails rather
%   than guessing when a value the form needs is missing or out of range.

:- discontiguous run_form/4.

enact(Lesson, Inputs, enactment(Lesson, Form, Inputs, Steps, Artifact)) :-
    memberchk(input(form, Form, _), Inputs),
    run_form(Form, Inputs, Steps, Artifact),
    Steps = [_|_].


in(Inputs, Key, Value) :- memberchk(input(Key, Value, _), Inputs).


% --- form 1 -------------------------------------------------------------
run_form(iterate_unit_along_extent, In, Steps, Artifact) :-
    in(In, unit, Unit), in(In, subdivisions, D), in(In, unit_count, N),
    integer(D), D > 0, integer(N), N > 0,
    action_automata_registry:run_action_automaton(
        measurement, linear_unit_iteration, measure(N, D), unit(Unit),
        action_outcome(_, Fields), _),
    memberchk(result(Length), Fields),
    action_automata_registry:run_action_automaton(
        measurement, count_marks_not_intervals, measure(N, D), unit(Unit),
        action_outcome(_, DFields), _),
    memberchk(result(Overcount), DFields),
    Steps = [ step(1, establish_unit, Unit, unit(Unit)),
              step(2, partition_unit_into_equal_intervals, D, equal_intervals(D)),
              step(3, iterate_interval_from_zero, N, intervals_covered(N)),
              step(4, read_accumulated_length, measure(N, D, Unit), Length),
              step(5, recount_boundary_marks_as_intervals, marks(N, D, Unit), Overcount)
            ],
    strip_artifact(N, D, Unit, Length, Artifact).

% --- form 2 -------------------------------------------------------------
run_form(reunitize_same_extent, In, Steps, Artifact) :-
    in(In, from_unit, From), in(In, to_unit, To),
    in(In, conversion_factor, F), in(In, unit_count, N),
    integer(F), F > 1, integer(N), N >= 0,
    action_automata_registry:run_action_automaton(
        measurement, unit_conversion_by_iteration, quantity(N, From),
        conversion(To, F), action_outcome(_, Fields), _),
    memberchk(result(Converted), Fields),
    action_automata_registry:run_action_automaton(
        measurement, change_unit_label_without_scaling, quantity(N, From),
        conversion(To, F), action_outcome(_, DFields), _),
    memberchk(result(Unscaled), DFields),
    Converted = quantity(CN, _),
    Steps = [ step(1, establish_equivalence, one(From), equals(F, To)),
              step(2, iterate_conversion_group, group(N, F), groups_iterated(N)),
              step(3, multiply_unit_count, product(N, F), CN),
              step(4, relabel_as_smaller_unit, To, Converted),
              step(5, contrast_relabel_without_iterating, quantity(N, From), Unscaled)
            ],
    Artifact = printed(unit_conversion_chain(quantity(N, From), factor(F), Converted,
                                             without_iterating(Unscaled))).

% --- form 3 -------------------------------------------------------------
run_form(partition_extent_into_unit_pieces, In, Steps, Artifact) :-
    in(In, unit, Unit), in(In, subunits_per_whole, D),
    in(In, extent_in_subunits, E), in(In, piece_in_subunits, P),
    integer(D), D > 0, integer(E), E > 0, integer(P), P > 0,
    action_automata_registry:run_action_automaton(
        division, measure_groups_of_size, E, P,
        action_outcome(_, Fields), _),
    memberchk(result(quotient_remainder(Q, R)), Fields),
    Steps = [ step(1, set_group_size, piece(P, D, Unit), group_size(P)),
              step(2, repeatedly_remove_group_size, extent(E, D, Unit), removed_to(R)),
              step(3, count_measured_groups, E, pieces(Q)),
              step(4, preserve_leftover_as_remainder, R, leftover(R, D, Unit))
            ],
    strip_artifact(E, D, Unit, pieces(Q, remainder(R)), Artifact).

%!  strip_artifact(+IntervalCount, +Subdivisions, +Unit, +Reading, -Artifact) is det.
%
%   The measurement strip renderer emits one frame per interval and carries the
%   whole jump list on every frame, so its cost grows with the square of the
%   interval count. Above the cap the enactment prints the reading instead of
%   routing to the renderer. A strip of 10,119 marked intervals carries no more
%   than the count already stated.
strip_artifact(N, D, Unit, _, scene(measurement_strip_scene, measure(N, D, Unit))) :-
    N =< 40, !.
strip_artifact(N, D, Unit, Reading,
               printed(measurement_beyond_strip_scale(intervals(N), subdivisions(D),
                                                      Unit, Reading))).

% --- form 4 -------------------------------------------------------------
run_form(pack_region_with_unit, In, Steps, Artifact) :-
    in(In, unit, Unit), in(In, region, Region), in(In, capacity, Cap),
    region_extent(Region, Count, Shape),
    capacity_step(Cap, Count, CapResult),
    Steps = [ step(1, name_unit_region, Unit, unit_region(Unit)),
              step(2, tile_region_with_unit, Region, Shape),
              step(3, count_unit_regions, Region, copies(Count, Unit)),
              step(4, compare_count_to_capacity, Cap, CapResult)
            ],
    pack_artifact(Region, Unit, Count, Artifact).

region_extent(rectangle_from_area(Area, Side), Area, rows(Side, Other)) :-
    integer(Area), integer(Side), Side > 0, 0 is Area mod Side,
    Other is Area // Side.
region_extent(box(L, W, D), Count, layers(L, W, D)) :-
    integer(L), integer(W), integer(D),
    Count is L * W * D.

capacity_step(none, _, no_capacity_stated) :- !.
capacity_step(Per, Count, fills(Loads, remainder(Rem))) :-
    integer(Per), Per > 0,
    Loads is (Count + Per - 1) // Per,
    Rem is Count mod Per.

pack_artifact(rectangle_from_area(Area, Side), Unit, _, scene(area_unit_covering_scene, cover(Cells, Unit))) :-
    !,
    Other is Area // Side,
    LastX is Side - 1, LastY is Other - 1,
    findall(X-Y, (between(0, LastX, X), between(0, LastY, Y)), Cells).
pack_artifact(Region, Unit, Count, printed(unit_region_count(Region, Count, Unit))).

% --- form 5 -------------------------------------------------------------
run_form(change_measured_quantity, In, Steps, Artifact) :-
    in(In, unit, Unit), in(In, operation, Op),
    in(In, left, A), in(In, right, B),
    memberchk(Op, [add, subtract]),
    action_automata_registry:run_action_automaton(
        measurement, unit_preserving_measured_quantity_change,
        measured_change(Op, A, B, Unit), ignored,
        action_outcome(_, Fields), _),
    memberchk(result(Result), Fields),
    action_automata_registry:run_action_automaton(
        measurement, drop_unit_from_measured_quantity_change,
        measured_change(Op, A, B, Unit), ignored,
        action_outcome(_, DFields), _),
    memberchk(result(Bare), DFields),
    Steps = [ step(1, establish_common_measurement_unit, Unit, shared_unit(Unit)),
              step(2, perform_grounded_quantity_change, change(Op, A, B), Result),
              step(3, retain_measurement_unit, Unit, Result),
              step(4, contrast_bare_numeral, Unit, dropped_to(Bare))
            ],
    Artifact = printed(unit_bearing_equation(Op, quantity(A, Unit), quantity(B, Unit),
                                             Result, without_unit(Bare))).

% --- form 6 -------------------------------------------------------------
run_form(compose_value_from_denominations, In, Steps, Artifact) :-
    in(In, value_unit, VU), in(In, denominations, Ds),
    in(In, holding, Hs), in(In, cost, Cost),
    Ds = [_|_], Hs = [_|_],
    foldl(denomination_subtotal(VU, Ds), Hs, 0-[], Total-RevLines),
    reverse(RevLines, Lines),
    grounded_arithmetic_reach(Total),
    spend_step(VU, Cost, Total, Remainder),
    Steps = [ step(1, establish_equivalence, Ds, in_units(VU, Ds)),
              step(2, iterate_conversion_group, Hs, subtotals(Lines)),
              step(3, accumulate_total_value, Lines, total(Total, VU)),
              step(4, spend_from_total, Cost, Remainder)
            ],
    Artifact = printed(value_table(Lines, total(Total, VU), Remainder)).

%!  grounded_arithmetic_reach(+N) is semidet.
%
%   `unit_preserving_measured_quantity_change` routes its addition and
%   subtraction through `formalization(grounded_arithmetic)`, whose recollection
%   representation costs grow with the square of the subtrahend. Measured here:
%   20,000 less 15,000 takes about a second, and 90,000 less 81,000 does not
%   return in any time a lesson page can wait for. So the value unit of a money
%   enactment is the largest denomination the lesson uses, and this guard names
%   the boundary rather than letting the arithmetic run away.
grounded_arithmetic_reach(N) :- integer(N), N =< 5000.

denomination_subtotal(VU, Ds, h(Name, Count),
                      Acc0-Lines0, Acc-[line(Name, Count, Sub)|Lines0]) :-
    memberchk(d(Name, Worth), Ds),
    integer(Count), Count >= 0, integer(Worth), Worth >= 1,
    (   Worth > 1, Count > 0
    ->  action_automata_registry:run_action_automaton(
            measurement, unit_conversion_by_iteration, quantity(Count, Name),
            conversion(VU, Worth), action_outcome(_, Fields), _),
        memberchk(result(quantity(Sub, VU)), Fields)
    ;   Sub is Count * Worth
    ),
    Acc is Acc0 + Sub.

spend_step(_, none, Total, kept(Total)) :- !.
spend_step(VU, Cost, Total, Remainder) :-
    integer(Cost), Cost >= 0,
    grounded_arithmetic_reach(Cost),
    (   Cost =< Total
    ->  action_automata_registry:run_action_automaton(
            measurement, unit_preserving_measured_quantity_change,
            measured_change(subtract, Total, Cost, VU), ignored,
            action_outcome(_, Fields), _),
        memberchk(result(quantity(Left, VU)), Fields),
        Remainder = left_over(Left, VU)
    ;   Short is Cost - Total,
        Remainder = short_by(Short, VU)
    ).

% --- form 7 -------------------------------------------------------------
run_form(read_circular_scale, In, Steps, Artifact) :-
    in(In, hour, H), in(In, minute, M), in(In, period, Period),
    integer(H), H >= 1, H =< 12, integer(M), M >= 0, M =< 59,
    K is M // 5, Rest is M mod 5,
    (   K > 0
    ->  action_automata_registry:run_action_automaton(
            measurement, linear_unit_iteration, measure(K, 12), unit(turn),
            action_outcome(_, Fields), _),
        memberchk(result(Turn), Fields)
    ;   Turn = length(rational(0, 12), turn)
    ),
    MinuteDegrees is 6 * M,
    HourDegrees is (30 * (H mod 12)) + (M // 2),
    Sep0 is abs(HourDegrees - MinuteDegrees),
    ( Sep0 > 180 -> Separation is 360 - Sep0 ; Separation = Sep0 ),
    Steps = [ step(1, place_hour_hand, H, degrees(HourDegrees)),
              step(2, iterate_five_minute_intervals, K, Turn),
              step(3, read_hand_separation, minutes(M, Rest), degrees(Separation)),
              step(4, name_half_day_period, Period, reading(H, M, Period))
            ],
    Artifact = scene(angle_circular_scene, angle(Separation)).

% --- form 8 -------------------------------------------------------------
run_form(bracket_unknown_measure, In, Steps, Artifact) :-
    in(In, unit, Unit), in(In, grain, G), in(In, actual, A),
    integer(G), G > 0, integer(A), A >= 0,
    Below is ((A - 1) // G) * G,
    Above is (((A + G) // G) * G),
    Nearest is ((A + G // 2) // G) * G,
    ( Below >= A -> Low is Below - G ; Low = Below ),
    ( Above =< A -> High is Above + G ; High = Above ),
    ( Low < A, A < High -> Holds = bracket_holds ; Holds = bracket_fails ),
    Width is High - Low,
    Steps = [ step(1, propose_too_low, G, quantity(Low, Unit)),
              step(2, propose_about_right, G, quantity(Nearest, Unit)),
              step(3, propose_too_high, G, quantity(High, Unit)),
              step(4, test_bracket_contains, quantity(A, Unit), Holds),
              step(5, report_bracket_width, bracket(Low, High), quantity(Width, Unit))
            ],
    Artifact = printed(estimate_bracket(too_low(Low), about_right(Nearest),
                                        too_high(High), actual(A), Unit, Holds)).

% --- form 9 -------------------------------------------------------------
run_form(sort_against_benchmark, In, Steps, Artifact) :-
    in(In, base_unit, Unit), in(In, benchmark, band_bounds(Bounds, Labels)),
    in(In, candidates, Cands),
    Bounds = [_|_], Cands = [_|_],
    length(Bounds, NB), length(Labels, NL), NL =:= NB + 1,
    maplist(place_candidate(Bounds, Labels), Cands, Placed),
    findall(band(Label, Members),
            ( member(Label, Labels),
              findall(Name, member(placed(Name, _, Label), Placed), Members)
            ),
            Bands),
    Steps = [ step(1, fix_benchmark, band_bounds(Bounds, Labels), in_units(Unit)),
              step(2, compare_candidate_to_benchmark, Cands, Placed),
              step(3, place_candidate_in_band, Placed, Bands),
              step(4, report_bands, Bands, bands_reported(Bands))
            ],
    Artifact = printed(benchmark_bands(Unit, Bands)).

place_candidate(Bounds, Labels, c(Name, Value), placed(Name, Value, Label)) :-
    integer(Value),
    band_index(Bounds, Value, 0, Index),
    nth0(Index, Labels, Label).

band_index([], _, I, I).
band_index([B|Bs], V, I0, I) :-
    (   V >= B
    ->  I1 is I0 + 1, band_index(Bs, V, I1, I)
    ;   I = I0
    ).

% --- form 10 ------------------------------------------------------------
run_form(resolve_measure_to_scale_grain, In, Steps, Artifact) :-
    in(In, scale_base, Base), in(In, reading_mode, Mode),
    in(In, grain, G), in(In, measures, Ms),
    integer(G), G > 0, Ms = [_,_|_],
    memberchk(Mode, [same_object, distinct_objects]),
    maplist(round_to_grain(G), Ms, Rounded),
    findall(V, member(rounded(_, _, V), Rounded), Values),
    sort(Values, Distinct),
    length(Values, NV), length(Distinct, ND),
    findall(R, member(m(_, R), Ms), Raw),
    max_list(Raw, Hi), min_list(Raw, Lo), Spread is Hi - Lo,
    scale_verdict(Mode, NV, ND, Spread, G, Verdict),
    Steps = [ step(1, fix_scale_grain, G, grain(G, Base)),
              step(2, round_measure_to_grain, Ms, Rounded),
              step(3, test_separation_at_grain, Distinct,
                   readings(NV, distinct_after_rounding(ND))),
              step(4, report_what_the_scale_settles, spread(Spread), Verdict)
            ],
    Artifact = printed(scale_resolution(Base, grain(G), Rounded, Verdict)).

round_to_grain(G, m(Name, V), rounded(Name, V, R)) :-
    integer(V),
    R is ((V + G // 2) // G) * G.

scale_verdict(distinct_objects, NV, ND, _, G, Verdict) :-
    (   NV =:= ND
    ->  Verdict = scale_separates_every_reading(G)
    ;   Verdict = scale_collapses_distinct_readings(G)
    ).
scale_verdict(same_object, _, ND, Spread, G, Verdict) :-
    (   ND =:= 1
    ->  Verdict = readings_agree_at_this_grain(G)
    ;   Verdict = readings_disagree_by_more_than_the_grain(Spread, G)
    ).


%% ======================================================================
%% enactment_verdict/2
%% ======================================================================

%!  enactment_verdict(+Enactment, -Verdict) is det.
%
%   `well_formed` only when every input came from the curriculum or was derived
%   from inputs that did. One machine-supplied value caps the verdict at
%   `partial`, because the enactment then reports about a quantity the
%   curriculum never stated.

enactment_verdict(enactment(_, _, _, [], _), refused(no_move_ran)) :- !.
enactment_verdict(enactment(_, _, Inputs, _, _), Verdict) :-
    !,
    findall(Key, member(input(Key, _, stand_in(_)), Inputs), StandIns),
    (   StandIns == []
    ->  Verdict = well_formed
    ;   Verdict = partial(inputs_supplied_by_machine(StandIns))
    ).
enactment_verdict(_, refused(malformed_enactment_term)).


%% ======================================================================
%% Serialization: the same dict shape strategy_trace_dict/3 produces
%% ======================================================================

%!  enactment_trace_dict(+Enactment, -Dict) is det.
%
%   The enactment in the dict shape `hermes_encyclopedia:strategy_trace_dict/3`
%   returns, so an enactment reaches every consumer a strategy trace reaches
%   without a second viewer. `steps` carries `_{n, label, value}` as that
%   predicate's own `history_steps/2` does; `label` is the verb and `value` is
%   the operand and result the verb produced. `jumps` comes from the artifact
%   when the artifact routes to a renderer whose frames carry jumps.

enactment_trace_dict(enactment(Lesson, Form, Inputs, Steps, Artifact), Dict) :-
    atom_string(Form, FormStr),
    maplist(step_dict, Steps, StepDicts),
    productive_result(Steps, FinalResult),
    term_string(FinalResult, ResultStr),
    artifact_jumps(Artifact, Jumps),
    enactment_verdict(enactment(Lesson, Form, Inputs, Steps, Artifact), Verdict),
    verdict_note(Verdict, Note),
    Dict = _{ strategy: FormStr,
              ok: true,
              representation: "im_lesson_enactment",
              result: ResultStr,
              steps: StepDicts,
              jumps: Jumps,
              note: Note }.

%!  productive_result(+Steps, -Result) is det.
%
%   Three forms end on a contrast step that runs the deformation partner beside
%   the productive reading, so the last step's result is the error the automaton
%   pair models rather than the enactment's answer. The reported result is the
%   last step that is not a contrast.
productive_result(Steps, Result) :-
    include([step(_, V, _, _)]>>(\+ contrast_move(V)), Steps, Productive),
    (   Productive == []
    ->  last(Steps, step(_, _, _, Result))
    ;   last(Productive, step(_, _, _, Result))
    ).

contrast_move(recount_boundary_marks_as_intervals).
contrast_move(contrast_relabel_without_iterating).
contrast_move(contrast_bare_numeral).

step_dict(step(N, Verb, Operand, Result), _{n: N, label: VerbStr, value: ValueStr}) :-
    atom_string(Verb, VerbStr),
    format(string(ValueStr), "~q -> ~q", [Operand, Result]).

verdict_note(well_formed,
             "Every input is printed in the lesson; the steps are the automata's own.") :- !.
verdict_note(partial(inputs_supplied_by_machine(Keys)), Note) :-
    !,
    term_string(Keys, KeyStr),
    format(string(Note),
           "The curriculum leaves these to the classroom, so the machine supplied them: ~w.",
           [KeyStr]).
verdict_note(Verdict, Note) :-
    term_string(Verdict, Note).

artifact_jumps(scene(measurement_strip_scene, Spec), Jumps) :-
    !,
    (   measurement_strip_scene:measurement_strip_render_json(Spec, Doc),
        get_dict(frames, Doc, Frames),
        Frames \== [],
        last(Frames, Frame),
        get_dict(scene, Frame, Scene),
        get_dict(jumps, Scene, Jumps)
    ->  true
    ;   Jumps = []
    ).
artifact_jumps(_, []).


%!  enactment_artifact_dict(+Enactment, -Dict) is det.
%
%   The artifact in the shape the page builder consumes. A scene artifact is
%   rendered by its own renderer so the emitted row carries the render document,
%   not a promise of one.

enactment_artifact_dict(enactment(_, _, _, _, scene(Renderer, Spec)), Dict) :-
    !,
    atom_string(Renderer, RendererStr),
    term_string(Spec, SpecStr),
    (   render_scene(Renderer, Spec, Doc0),
        json_safe(Doc0, Doc)
    ->  Dict = _{kind: "scene", renderer: RendererStr, term: SpecStr, document: Doc}
    ;   Dict = _{kind: "scene", renderer: RendererStr, term: SpecStr,
                 document: _{error: "The renderer refused this specification.", frames: []}}
    ).
enactment_artifact_dict(enactment(_, _, _, _, printed(Record)), Dict) :-
    term_string(Record, RecordStr),
    Dict = _{kind: "printed", record: RecordStr}.

%!  json_safe(+Term, -Safe) is det.
%
%   Render documents carry Prolog pair terms (`0-0` grid cells, for one), which
%   no JSON writer accepts. This walks a document and writes any term JSON has
%   no shape for as its printed form, so the emitted row keeps the value rather
%   than dropping the field.
json_safe(D, Safe) :-
    is_dict(D), !,
    dict_pairs(D, Tag, Pairs),
    maplist([K-V, K-S]>>json_safe(V, S), Pairs, SafePairs),
    dict_pairs(Safe, Tag, SafePairs).
json_safe(L, Safe) :-
    is_list(L), !,
    maplist(json_safe, L, Safe).
json_safe(N, N) :- number(N), !.
json_safe(S, S) :- string(S), !.
json_safe(A, A) :- atom(A), !.
json_safe(T, S) :- term_string(T, S).

render_scene(measurement_strip_scene, Spec, Doc) :-
    measurement_strip_scene:measurement_strip_render_json(Spec, Doc).
render_scene(area_unit_covering_scene, Spec, Doc) :-
    area_unit_covering_scene:area_unit_covering_render_json(Spec, Doc).
render_scene(angle_circular_scene, Spec, Doc) :-
    angle_circular_scene:angle_circular_render_json(Spec, Doc).


%% ======================================================================
%% The census
%% ======================================================================

%!  measurement_enactment_report(-Dict) is det.
%
%   The measured coverage. Every count comes from running `enact/3`, never from
%   counting facts. `move_check` re-reads every emitted step verb against
%   `enactment_move/3`, so a step whose verb is not a declared move of its form
%   fails the report rather than passing quietly.

measurement_enactment_report(Dict) :-
    findall(L, lesson_meta(L, _, _), AllLessons),
    length(AllLessons, Population),
    findall(Lesson-Form-Verdict,
            ( enactment_input(Lesson, Form, Inputs),
              lesson_enactment_form(Lesson, Form, _),
              enact(Lesson, Inputs, E),
              enactment_verdict(E, Verdict)
            ),
            Runs),
    findall(L, member(L-_-_, Runs), RunLessons0),
    sort(RunLessons0, RunLessons),
    length(RunLessons, Enacted),
    length(Runs, RunCount),
    findall(L, member(L-_-well_formed, Runs), WF0), sort(WF0, WF),
    length(WF, WellFormed),
    findall(L, ( member(L-_-partial(_), Runs) ), P0), sort(P0, P1),
    subtract(P1, WF, PartialOnly), length(PartialOnly, PartialCount),
    findall(L, ( lesson_meta(L, _, _), \+ memberchk(L, RunLessons) ), NotRun),
    length(NotRun, NotRunCount),
    findall(L, enactment_refusal(L, _, _), Refused),
    length(Refused, RefusedCount),
    findall(F, enactment_form(F, _, _), Forms), length(Forms, FormCount),
    move_check(MoveCheck),
    Dict = _{ population: Population,
              forms: FormCount,
              enactments_run: RunCount,
              lessons_enacted: Enacted,
              lessons_well_formed: WellFormed,
              lessons_partial_only: PartialCount,
              lessons_not_enacted: NotRunCount,
              not_enacted: NotRun,
              named_refusals: RefusedCount,
              move_check: MoveCheck }.

%!  move_check(-Dict) is det.
%
%   Every step verb an enactment emits must be the functor of a declared move at
%   that index of that form. This is the gate against a move that names a doing
%   the code never runs.
move_check(_{steps_checked: N, undeclared: Bad}) :-
    findall(Form-Index-Verb,
            ( enactment_input(Lesson, Form, Inputs),
              lesson_enactment_form(Lesson, Form, _),
              enact(Lesson, Inputs, enactment(_, _, _, Steps, _)),
              member(step(Index, Verb, _, _), Steps)
            ),
            All),
    length(All, N),
    findall(F-I-V,
            ( member(F-I-V, All),
              \+ ( enactment_move(F, I, Move), functor(Move, V, _) )
            ),
            Bad0),
    sort(Bad0, Bad).

measurement_enactment_report :-
    measurement_enactment_report(Dict),
    format("IM measurement lane, enactment census~n"),
    format("  population (measurement_task lessons) : ~w~n", [Dict.population]),
    format("  forms                                : ~w~n", [Dict.forms]),
    format("  enactments that ran                  : ~w~n", [Dict.enactments_run]),
    format("  lessons enacted                      : ~w~n", [Dict.lessons_enacted]),
    format("    of those, well formed              : ~w~n", [Dict.lessons_well_formed]),
    format("    of those, partial only             : ~w~n", [Dict.lessons_partial_only]),
    format("  lessons not enacted                  : ~w~n", [Dict.lessons_not_enacted]),
    format("  named refusals                       : ~w~n", [Dict.named_refusals]),
    format("  step verbs checked against moves     : ~w~n", [Dict.move_check.steps_checked]),
    format("  step verbs with no declared move     : ~w~n", [Dict.move_check.undeclared]),
    forall(member(L, Dict.not_enacted),
           ( enactment_refusal(L, Reason, Machine)
           -> format("  refused ~w: ~w~n            would need: ~w~n", [L, Reason, Machine])
           ;  format("  not enacted, no refusal recorded: ~w~n", [L])
           )).


%% ======================================================================
%% Registration on curriculum/im/lesson_enactment.pl
%% ======================================================================
%
% This lane wrote its machines before the contract module existed, so it keeps
% its own `enact/3` and its own verdict and joins through the contract's lane
% route. The clauses below are the whole of the join.
%
% Two things the join changed here. The lane's own `enactment_lane/2` said
% `(Subclass, Module)` where the contract's says `(Form, Subclass)`; one name
% for two relations is how a row silently loses its subclass, so the lane's
% clause is gone and the contract's is below. And the lane no longer writes its
% own emission file: `lesson_enactment` owns
% `data/learningcommons/derived/lesson_enactments/measurement.jsonl` and writes
% every lane's rows in one shape.
%
% One reading is not carried across. `enactment_input/3` gives IM-G5-U5-L7 two
% input sets for one form, because the lesson weighs its coins on two scales.
% The contract branches on the form and only on the form, so `once/1` below
% takes the first set. The lesson is still enacted and still counted; the second
% setting reaches `measurement_enactment_report/1` and not the emitted row. A
% lane that wants both readings on the rung declares them as two forms.

:- use_module(im_lessons(lesson_enactment), []).

:- multifile
       lesson_enactment:enactment_lane/2,
       lesson_enactment:enactment_form/3,
       lesson_enactment:lesson_enactment_form/3,
       lesson_enactment:enactment_move/3,
       lesson_enactment:enactment_run/3,
       lesson_enactment:enactment_lane_verdict/2,
       lesson_enactment:enactment_disclaimer/2,
       lesson_enactment:lesson_enactment_refusal/2.

lesson_enactment:enactment_lane(Form, measurement_task) :-
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
    once(( enactment_input(Lesson, Form, Inputs),
           enact(Lesson, Inputs, Enactment) )).

lesson_enactment:enactment_lane_verdict(Enactment, Verdict) :-
    Enactment = enactment(_, Form, _, _, _),
    enactment_form(Form, _, _),
    once(enactment_verdict(Enactment, Verdict)).

lesson_enactment:enactment_disclaimer(Form, Sentence) :-
    form_does_not_claim(Form, Sentence).

% The lane's inputs carry `stand_in(Why)` on every value the machine chose, so
% the contract reads the provenance off the input list itself and needs no
% `enactment_input_provenance/3` clause here.

lesson_enactment:lesson_enactment_refusal(Lesson, Machine) :-
    enactment_refusal(Lesson, _Reason, Machine).
