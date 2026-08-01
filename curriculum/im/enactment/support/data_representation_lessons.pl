% Lesson rows for the data_representation_or_question enactment lane.
% Included by curriculum/im/enactment/data_representation.pl; not a module.
%
% THREE RELATIONS.
%   lane_lesson(Lesson, Grade, Source)
%     The 42 lessons the recut carries under this subclass, with the teacher
%     guide each was read from.
%   lesson_enactment_form(Lesson, Form, evidence(Source, Line, Text))
%     Which shape a lesson takes, and the printed line that licensed the
%     reading. The first clause for a lesson is its primary form.
%   lesson_inputs(Lesson, Form, Inputs, Provenance)
%     The operands the form runs on, and where they came from.
%
% PROVENANCE, WHICH IS THE POINT OF THIS FILE.
%   input_provenance-curriculum
%     Every operand is printed in the guide at a cited line. Most of these
%     were read out of the guide's own Student Response section, which prints
%     the answers a display's numbers imply even where the display itself is
%     an image the markdown does not carry.
%   input_provenance-machine_supplied  +  stand_in_note-Text
%     A class would generate these numbers. This file chose stand-ins so the
%     structure could run, and stand_in_note says in one sentence what was
%     chosen and on what basis. No enactment on a stand-in reports well_formed.
%
% Line citations are verbatim from the guide at the line named. These files
% are OCR'd from two-column PDFs, so a cited line often carries text from the
% facing column as well; the quotation is left as the file has it rather than
% tidied, so a reader can check it.

% =============================================================================
% The population
% =============================================================================

lane_lesson('IM-GK-U2-L24', 'K', 'curriculum/im_teacher_guides/kindergarten/unit2/lesson24.md').
lane_lesson('IM-G1-U1-L9',  '1', 'curriculum/im_teacher_guides/grade1/unit1/lesson9.md').
lane_lesson('IM-G1-U1-L11', '1', 'curriculum/im_teacher_guides/grade1/unit1/lesson11.md').
lane_lesson('IM-G1-U1-L12', '1', 'curriculum/im_teacher_guides/grade1/unit1/lesson12.md').
lane_lesson('IM-G1-U1-L15', '1', 'curriculum/im_teacher_guides/grade1/unit1/lesson15.md').
lane_lesson('IM-G1-U2-L17', '1', 'curriculum/im_teacher_guides/grade1/unit2/lesson17.md').
lane_lesson('IM-G1-U4-L23', '1', 'curriculum/im_teacher_guides/grade1/unit4/lesson23.md').
lane_lesson('IM-G1-U6-L7',  '1', 'curriculum/im_teacher_guides/grade1/unit6/lesson7.md').
lane_lesson('IM-G2-U1-L7',  '2', 'curriculum/im_teacher_guides/grade2/unit1/lesson7.md').
lane_lesson('IM-G2-U1-L8',  '2', 'curriculum/im_teacher_guides/grade2/unit1/lesson8.md').
lane_lesson('IM-G2-U1-L9',  '2', 'curriculum/im_teacher_guides/grade2/unit1/lesson9.md').
lane_lesson('IM-G2-U1-L10', '2', 'curriculum/im_teacher_guides/grade2/unit1/lesson10.md').
lane_lesson('IM-G2-U5-L14', '2', 'curriculum/im_teacher_guides/grade2/unit5/lesson14.md').
lane_lesson('IM-G2-U6-L16', '2', 'curriculum/im_teacher_guides/grade2/unit6/lesson16.md').
lane_lesson('IM-G3-U1-L1',  '3', 'curriculum/im_teacher_guides/grade3/unit1/lesson1.md').
lane_lesson('IM-G3-U1-L2',  '3', 'curriculum/im_teacher_guides/grade3/unit1/lesson2.md').
lane_lesson('IM-G3-U1-L4',  '3', 'curriculum/im_teacher_guides/grade3/unit1/lesson4.md').
lane_lesson('IM-G3-U1-L6',  '3', 'curriculum/im_teacher_guides/grade3/unit1/lesson6.md').
lane_lesson('IM-G3-U1-L7',  '3', 'curriculum/im_teacher_guides/grade3/unit1/lesson7.md').
lane_lesson('IM-G3-U1-L21', '3', 'curriculum/im_teacher_guides/grade3/unit1/lesson21.md').
lane_lesson('IM-G3-U2-L11', '3', 'curriculum/im_teacher_guides/grade3/unit2/lesson11.md').
lane_lesson('IM-G3-U3-L13', '3', 'curriculum/im_teacher_guides/grade3/unit3/lesson13.md').
lane_lesson('IM-G3-U3-L15', '3', 'curriculum/im_teacher_guides/grade3/unit3/lesson15.md').
lane_lesson('IM-G3-U6-L4',  '3', 'curriculum/im_teacher_guides/grade3/unit6/lesson4.md').
lane_lesson('IM-G3-U8-L6',  '3', 'curriculum/im_teacher_guides/grade3/unit8/lesson6.md').
lane_lesson('IM-G3-U8-L7',  '3', 'curriculum/im_teacher_guides/grade3/unit8/lesson7.md').
% Handed over by the measurement lane, which refused it: the doing is
% facilitating a routine, which is this lane's own shape. Not in the recut's 42
% for this subclass, so it is counted separately in lane_coverage/1.
lane_lesson('IM-G3-U8-L12', '3', 'curriculum/im_teacher_guides/grade3/unit8/lesson12.md').
lane_lesson('IM-G4-U1-L3',  '4', 'curriculum/im_teacher_guides/grade4/unit1/lesson3.md').
lane_lesson('IM-G4-U3-L13', '4', 'curriculum/im_teacher_guides/grade4/unit3/lesson13.md').
lane_lesson('IM-G4-U3-L14', '4', 'curriculum/im_teacher_guides/grade4/unit3/lesson14.md').
lane_lesson('IM-G4-U4-L7',  '4', 'curriculum/im_teacher_guides/grade4/unit4/lesson7.md').
lane_lesson('IM-G4-U4-L15', '4', 'curriculum/im_teacher_guides/grade4/unit4/lesson15.md').
lane_lesson('IM-G4-U5-L12', '4', 'curriculum/im_teacher_guides/grade4/unit5/lesson12.md').
lane_lesson('IM-G4-U6-L3',  '4', 'curriculum/im_teacher_guides/grade4/unit6/lesson3.md').
lane_lesson('IM-G4-U8-L1',  '4', 'curriculum/im_teacher_guides/grade4/unit8/lesson1.md').
lane_lesson('IM-G4-U9-L7',  '4', 'curriculum/im_teacher_guides/grade4/unit9/lesson7.md').
lane_lesson('IM-G5-U2-L5',  '5', 'curriculum/im_teacher_guides/grade5/unit2/lesson5.md').
lane_lesson('IM-G5-U4-L8',  '5', 'curriculum/im_teacher_guides/grade5/unit4/lesson8.md').
lane_lesson('IM-G5-U5-L10', '5', 'curriculum/im_teacher_guides/grade5/unit5/lesson10.md').
lane_lesson('IM-G5-U6-L14', '5', 'curriculum/im_teacher_guides/grade5/unit6/lesson14.md').
lane_lesson('IM-G5-U7-L9',  '5', 'curriculum/im_teacher_guides/grade5/unit7/lesson9.md').
lane_lesson('IM-G5-U7-L11', '5', 'curriculum/im_teacher_guides/grade5/unit7/lesson11.md').
lane_lesson('IM-G5-U7-L13', '5', 'curriculum/im_teacher_guides/grade5/unit7/lesson13.md').


% =============================================================================
% Grade 4 and grade 5
% =============================================================================

% --- IM-G4-U3-L14: complete a line plot, then read the extremes off it ------
lesson_enactment_form('IM-G4-U3-L14', display_question_set,
    evidence('curriculum/im_teacher_guides/grade4/unit3/lesson14.md', 204,
             "1. Complete the line plot with the missing data.                        • Monitor for the different ways students find the")).
lesson_enactment_form('IM-G4-U3-L14', notice_and_wonder,
    evidence('curriculum/im_teacher_guides/grade4/unit3/lesson14.md', 182,
             "Students in a fourth-grade class                              • Groups of 2")).
lesson_inputs('IM-G4-U3-L14', F,
    [ title-'shoe lengths, counted in eighths of an inch',
      values-[64, 66, 67, 68, 68, 69, 70, 70, 71, 72, 73, 74, 76],
      question_frame-measured ],
    [ input_provenance-machine_supplied,
      stand_in_note-'The line plot and every value on it are images the markdown does not carry, so thirteen lengths in eighths of an inch were chosen to span the range the lesson describes: seven plotted points and six missing ones.' ]) :-
    member(F, [display_question_set, notice_and_wonder]).

% --- IM-G4-U4-L7: how many thousands are in each number ---------------------
lesson_enactment_form('IM-G4-U4-L7', table_from_rule,
    evidence('curriculum/im_teacher_guides/grade4/unit4/lesson7.md', 222,
             "1. Complete the table to show how many                    • Groups of 2")).
lesson_inputs('IM-G4-U4-L7', table_from_rule,
    [ title-'how many thousands are in each number',
      rule-place_value_count(1000),
      second_rule-place_value_count(10000),
      source_values-[10000, 20000, 90000, 11000, 27000, 98000],
      columns-['number', 'number of thousands'],
      count-6 ],
    [ input_provenance-curriculum,
      cited-'curriculum/im_teacher_guides/grade4/unit4/lesson7.md:245-256 prints the six numbers 10,000 through 98,000 in the table, and the guide answers 10 thousands for 10,000.' ]).

% --- IM-G4-U4-L15: round to the nearest multiple ----------------------------
lesson_enactment_form('IM-G4-U4-L15', table_from_rule,
    evidence('curriculum/im_teacher_guides/grade4/unit4/lesson15.md', 185,
             "           Complete the table with the nearest multiple of          thousands—the hundreds, tens, and ones. If it is less")).
lesson_inputs('IM-G4-U4-L15', table_from_rule,
    [ title-'the nearest multiple of 1,000',
      rule-round_to_multiple(1000),
      source_values-[816, 3816, 73816, 573816, 425193],
      columns-['number', 'nearest 1,000'],
      count-5 ],
    [ input_provenance-curriculum,
      cited-'The five numbers are printed at lines 156-168 and 305 of the guide; the guide answers 1,000 for 816 at line 180 and 425,000 for 425,193 at line 331.' ]).

% --- IM-G4-U5-L12: hours become minutes -------------------------------------
lesson_enactment_form('IM-G4-U5-L12', table_from_rule,
    evidence('curriculum/im_teacher_guides/grade4/unit5/lesson12.md', 168,
             "      1. Complete the table to show how many minutes           of hours and fractional hours into minutes.")).
lesson_inputs('IM-G4-U5-L12', table_from_rule,
    [ title-'how many minutes Mai spends on each activity',
      rule-scale_by(60),
      source_values-[1, 8, 2],
      columns-['hours', 'minutes'],
      count-3 ],
    [ input_provenance-curriculum,
      cited-'Mai spends 1 hour on her morning routine, 8 hours at school, and 2 hours playing, printed at lines 142, 149, and 162; the guide answers 480 minutes for 8 hours at line 286.' ]).

% --- IM-G4-U6-L3: start with 9, keep adding 9 -------------------------------
lesson_enactment_form('IM-G4-U6-L3', table_from_rule,
    evidence('curriculum/im_teacher_guides/grade4/unit6/lesson3.md', 165,
             "Andre’s rule for a pattern is “start with 9, keep          • Groups of 2")).
lesson_inputs('IM-G4-U6-L3', table_from_rule,
    [ title-'Andre and Elena keep adding',
      rule-arithmetic_sequence(9, 9),
      second_rule-arithmetic_sequence(99, 99),
      count-10,
      columns-['term', 'value'],
      index_questions-[12, 15, 25] ],
    [ input_provenance-curriculum,
      cited-'Andre keeps adding 9 (line 165) and Elena keeps adding 99 (line 282); the guide answers 108, 135, and 225 for the 12th, 15th, and 25th terms at lines 348-352.' ]).

% --- IM-G4-U8-L1: guess the category ----------------------------------------
lesson_enactment_form('IM-G4-U8-L1', sort_into_bins,
    evidence('curriculum/im_teacher_guides/grade4/unit8/lesson1.md', 270,
             "• Find 3 figures that fit the category and 3 figures")).
lesson_inputs('IM-G4-U8-L1', sort_into_bins,
    [ items-[ 'I'-[obtuse_angle, four_sides], 'F'-[obtuse_angle, three_sides],
              'G'-[obtuse_angle, five_sides], 'A'-[right_angle, four_sides],
              'E'-[right_angle, four_sides], 'V'-[acute_angles, three_sides] ],
      bins-[ bin('fits the category', has_attribute(obtuse_angle)),
             bin('does not fit', lacks_attribute(obtuse_angle)) ],
      residue_bin-'unsorted' ],
    [ input_provenance-machine_supplied,
      stand_in_note-'The figures are images the markdown does not carry, so each of the six letters the guide names at lines 316-320 was given the attribute list the guide implies by placing it, and the sort then reproduces the guide printed grouping.' ]).

% --- IM-G4-U9-L7: two places, one list of prices ----------------------------
lesson_enactment_form('IM-G4-U9-L7', notice_and_wonder,
    evidence('curriculum/im_teacher_guides/grade4/unit9/lesson7.md', 99,
             "      What do you notice? What do you wonder?                    • Groups of 2")).
lesson_inputs('IM-G4-U9-L7', notice_and_wonder,
    [ title-'2023 prices in San Francisco compared with Fort Wayne',
      paired_rows-[ row('milk, one gallon', 5.99, 2.79),
                    row('bread, one loaf', 4.79, 3.99),
                    row('gasoline, one gallon', 6.02, 3.56),
                    row('a movie ticket', 17.00, 10.50),
                    row('internet for one month', 89.00, 60.00),
                    row('rent for a three-bedroom apartment', 5000, 1200),
                    row('the cost of a house', 1380000, 210000) ] ],
    [ input_provenance-curriculum,
      cited-'The price table is printed at lines 106-122 of the guide, and the warm-up at line 98 asks the class what it notices and wonders about exactly this table.' ]).

% --- IM-G5-U2-L5: choose numbers so each share lands in a band --------------
lesson_enactment_form('IM-G5-U2-L5', constraint_fill_table,
    evidence('curriculum/im_teacher_guides/grade5/unit2/lesson5.md', 181,
             "1. Fill in the blanks to match the rules in the table.")).
lesson_inputs('IM-G5-U2-L5', constraint_fill_table,
    [ title-'people sharing 7 pounds of blueberries, each getting more than one pound',
      constraint-quotient_band(more_than_one, 7),
      columns-['people', 'pounds'],
      count-5 ],
    [ input_provenance-curriculum,
      cited-'The seven pounds are fixed in the table at line 150 and the more-than-one rule at line 139; the guide sample answer, five people sharing seven pounds, is printed at line 218.' ]).

% --- IM-G5-U4-L8: floor area times a height range ---------------------------
lesson_enactment_form('IM-G5-U4-L8', table_from_rule,
    evidence('curriculum/im_teacher_guides/grade5/unit4/lesson8.md', 270,
             "Use the information from the table. Find the               • Groups of 2")).
lesson_inputs('IM-G5-U4-L8', table_from_rule,
    [ title-'the recommended range of volumes for each birdhouse',
      rule-multiply_pairs,
      source_pairs-[16-6, 16-10, 180-10, 180-24, 180-15, 180-18,
                    36-12, 36-15, 25-6, 25-12],
      columns-['floor area and height', 'volume in cubic inches'],
      count-10 ],
    [ input_provenance-curriculum,
      cited-'The floor side lengths and height ranges are printed at lines 150-172; the guide answers 96 to 160 cubic inches for the chickadee and 1,800 to 4,320 for the wood duck at lines 316-329.' ]).

% --- IM-G5-U5-L10: which speeds tie once they are rounded -------------------
lesson_enactment_form('IM-G5-U5-L10', sort_into_bins,
    evidence('curriculum/im_teacher_guides/grade5/unit5/lesson10.md', 270,
             "       2. Do any of these athletes have the same top")).
lesson_inputs('IM-G5-U5-L10', sort_into_bins,
    [ title-'top speeds rounded to the nearest tenth of a mile per hour',
      items-['Athlete 1'-8213, 'Athlete 2'-8275, 'Athlete 3'-8281,
             'Athlete 4'-8307, 'Athlete 5'-8280],
      bins-[ bin('82.1 mph', nearest_multiple_is(10, 8210)),
             bin('82.8 mph', nearest_multiple_is(10, 8280)),
             bin('83.1 mph', nearest_multiple_is(10, 8310)) ],
      residue_bin-'no tenth claims it' ],
    [ input_provenance-curriculum,
      cited-'The five speeds are printed at lines 258-266 of the guide; they are carried here in hundredths of a mile per hour so the rounding runs on whole numbers.' ]).

% --- IM-G5-U6-L14: the spinner game makes its own line plot -----------------
lesson_enactment_form('IM-G5-U6-L14', notice_and_wonder,
    evidence('curriculum/im_teacher_guides/grade5/unit6/lesson14.md', 196,
             "       4. What do you notice about the data you")).
lesson_inputs('IM-G5-U6-L14', notice_and_wonder,
    [ title-'twelve sums of two spins, counted in eighths of a whole',
      values-[3, 5, 6, 8, 4, 7, 9, 6, 5, 8, 7, 10] ],
    [ input_provenance-machine_supplied,
      stand_in_note-'The lesson tells each pair to spin until they hold twelve data points, so twelve sums in eighths were chosen to stand for one pair play; a real pair produces different sums and the same shape of plot.' ]).

% --- IM-G5-U7-L9: two rules side by side ------------------------------------
lesson_enactment_form('IM-G5-U7-L9', table_from_rule,
    evidence('curriculum/im_teacher_guides/grade5/unit7/lesson9.md', 169,
             "“Keep adding 4.”                                      • 1–2 minutes: quiet think time")).
lesson_inputs('IM-G5-U7-L9', table_from_rule,
    [ title-'Jada keeps adding 4 while Priya keeps adding 8',
      rule-arithmetic_sequence(0, 4),
      second_rule-arithmetic_sequence(0, 8),
      count-10,
      columns-['Jada', 'Priya'] ],
    [ input_provenance-curriculum,
      cited-'Jada starts at 0 and keeps adding 4 (line 169), Priya starts at 0 and keeps adding 8 (line 173); the guide asks the class to notice that each of Priya numbers is double the matching one of Jada at line 184.' ]).

% --- IM-G5-U7-L11: two rules, then the pairs as points ----------------------
lesson_enactment_form('IM-G5-U7-L11', table_from_rule,
    evidence('curriculum/im_teacher_guides/grade5/unit7/lesson11.md', 145,
             "Rule 1: Keep adding 8.                                       independently. After a couple minutes, work with")).
lesson_inputs('IM-G5-U7-L11', table_from_rule,
    [ title-'rule 1 keeps adding 8 while rule 2 keeps adding 2',
      rule-arithmetic_sequence(0, 8),
      second_rule-arithmetic_sequence(0, 2),
      count-6,
      columns-['rule 1', 'rule 2'] ],
    [ input_provenance-curriculum,
      cited-'Both patterns start at 0 (line 143), rule 1 keeps adding 8 (line 145) and rule 2 keeps adding 2 (line 146); the guide table runs the six columns A through F.' ]).

% --- IM-G5-U7-L13: every rectangle with a perimeter of 12 -------------------
lesson_enactment_form('IM-G5-U7-L13', constraint_fill_table,
    evidence('curriculum/im_teacher_guides/grade5/unit7/lesson13.md', 167,
             "1. Jada draws a rectangle with a perimeter of 12                  width?”")).
lesson_inputs('IM-G5-U7-L13', constraint_fill_table,
    [ title-'whole-number rectangles with a perimeter of 12 centimeters',
      constraint-perimeter_pairs(12),
      columns-['length (cm)', 'width (cm)'],
      count-5 ],
    [ input_provenance-curriculum,
      cited-'The perimeter of 12 centimeters and the request for five rows are printed at lines 167-172; the guide own five rows run 5 by 1 down to 1 by 5.' ]).


% =============================================================================
% Kindergarten through grade 3
% =============================================================================

% --- IM-G1-U1-L11: decide whether each statement about the survey is true ---
lesson_enactment_form('IM-G1-U1-L11', adjudicate_against_data,
    evidence('curriculum/im_teacher_guides/grade1/unit1/lesson11.md', 166,
             "Decide whether each statement is true or false.")).
lesson_inputs('IM-G1-U1-L11', adjudicate_against_data,
    [ title-'Which animal would make the best class pet?',
      categories-[rabbit-12, turtle-3, dog-5],
      claims-[ claim('There are 12 votes for rabbit.', count_is(rabbit, 12)),
               claim('There are 18 votes in all.', total_is(18)),
               claim('14 students voted for turtle or rabbit.', sum_is([turtle, rabbit], 14)),
               claim('8 students voted for dog or turtle.', sum_is([dog, turtle], 8)) ] ],
    [ input_provenance-machine_supplied,
      stand_in_note-'The graph is an image the markdown does not carry, so the three counts are the smallest whole numbers consistent with all four rulings the guide prints at lines 199-202, and the machine then reaches those same four rulings on its own.' ]).

% --- IM-G2-U1-L8: what the picture graph settles ----------------------------
lesson_enactment_form('IM-G2-U1-L8', display_question_set,
    evidence('curriculum/im_teacher_guides/grade2/unit1/lesson8.md', 166,
             "What can you learn about the sports children love         • 2 minutes: partner discussion")).
lesson_enactment_form('IM-G2-U1-L8', notice_and_wonder,
    evidence('curriculum/im_teacher_guides/grade2/unit1/lesson8.md', 161,
             "• “What can you learn about the sports children love")).
lesson_inputs('IM-G2-U1-L8', F,
    [ title-'Sports Adults Love',
      categories-[basketball-2, soccer-3, baseball-5, football-8] ],
    [ input_provenance-curriculum,
      cited-'The guide prints 2 for basketball at line 207, 8 + 5 = 13 for football or baseball at line 209, and 5 for baseball with 3 for soccer and 8 for football at lines 211-212.' ]) :-
    member(F, [display_question_set, notice_and_wonder]).

% --- IM-G2-U1-L9: use the bar graph to answer the questions -----------------
lesson_enactment_form('IM-G2-U1-L9', display_question_set,
    evidence('curriculum/im_teacher_guides/grade2/unit1/lesson9.md', 233,
             "1. How many students voted for summer?")).
lesson_inputs('IM-G2-U1-L9', display_question_set,
    [ title-'Our Favorite Seasons',
      categories-[winter-7, spring-3, summer-13, fall-3] ],
    [ input_provenance-curriculum,
      cited-'The four counts follow uniquely from the four answers the guide prints at lines 245-251: summer 13, spring with fall 6, winter with spring 10, and 26 in all.' ]).

% --- IM-G3-U1-L6: which scale should the bar graph use ----------------------
lesson_enactment_form('IM-G3-U1-L6', scale_choice,
    evidence('curriculum/im_teacher_guides/grade3/unit1/lesson6.md', 166,
             "• Mai says the scale of the bar graph should be")).
lesson_inputs('IM-G3-U1-L6', scale_choice,
    [ title-'Favorite Season of the Year',
      categories-[winter-24, spring-13, summer-40, fall-22],
      candidate_scales-[2, 5, 10] ],
    [ input_provenance-curriculum,
      cited-'The three candidate scales are Mai 2, Noah 5, and Priya 10 at lines 166-171. The four counts are printed in the same lesson at line 236, where the class builds a scaled bar graph of the favorite-season table; the pattern-block collection the scales are first argued over is an image the markdown does not carry.' ]).

% --- IM-G3-U6-L4: eight questions about the twig line plot ------------------
lesson_enactment_form('IM-G3-U6-L4', display_question_set,
    evidence('curriculum/im_teacher_guides/grade3/unit6/lesson4.md', 249,
             "1. How many twig lengths are represented in the")).
lesson_enactment_form('IM-G3-U6-L4', notice_and_wonder,
    evidence('curriculum/im_teacher_guides/grade3/unit6/lesson4.md', 245,
             "                                                               • “This line plot has data about the lengths of some")).
lesson_inputs('IM-G3-U6-L4', F,
    [ title-'Lengths in Inches',
      values-[3, 5, 4, 4, 5, 6, 7, 5, 3, 4, 4, 5, 6, 6, 4],
      question_frame-measured ],
    [ input_provenance-curriculum,
      cited-'The fifteen whole-inch lengths are printed in the warm-up list at line 84, which is the record the guide asks the class to notice and wonder about; the quarter-inch twig plot in the activity is an image and its lengths do not survive the extraction.' ]) :-
    member(F, [display_question_set, notice_and_wonder]).

% --- IM-GK-U2-L24: what you need to set the table ---------------------------
lesson_enactment_form('IM-GK-U2-L24', display_question_set,
    evidence('curriculum/im_teacher_guides/kindergarten/unit2/lesson24.md', 218,
             "Show items you use to set the table.                        • Groups of 2")).
lesson_inputs('IM-GK-U2-L24', display_question_set,
    [ title-'items needed to set the table',
      categories-[plates-6, spoons-6, forks-4, cups-3],
      question_frame-counted,
      partial-sample_response_and_not_a_class_record ],
    [ input_provenance-curriculum,
      cited-'6 plates and 6 spoons follow the warm-up 6 bowls at line 90 and the counter response at line 225; 4 forks and 3 cups are the guide own sample responses in the same section. Each child chart differs, so this is one family table rather than a class record.' ]).

% --- IM-G1-U1-L9: show the survey data on paper -----------------------------
lesson_enactment_form('IM-G1-U1-L9', survey_tally_display,
    evidence('curriculum/im_teacher_guides/grade1/unit1/lesson9.md', 269,
             "Show the survey data about our class’s favorite             • Groups of 2")).
lesson_inputs('IM-G1-U1-L9', survey_tally_display,
    [ title-'our class favorite fruit',
      question-'Which is your favorite fruit?',
      choices-[apple, banana, orange],
      responses-[apple, banana, apple, orange, apple, banana, apple, orange,
                 banana, apple, apple, orange, banana, apple, orange, apple,
                 banana, apple],
      display-bar_graph ],
    [ input_provenance-machine_supplied,
      stand_in_note-'The guide leaves the survey topic and its three categories blank for the teacher to fill in and never prints a count, so a three-choice question and eighteen responses stand in for a class own cubes.' ]).

% --- IM-G1-U1-L12: take the survey, tally it, question it -------------------
lesson_enactment_form('IM-G1-U1-L12', survey_tally_display,
    evidence('curriculum/im_teacher_guides/grade1/unit1/lesson12.md', 148,
             "Our Favorite                                              • Groups of 2")).
lesson_inputs('IM-G1-U1-L12', survey_tally_display,
    [ title-'Our Favorite Sport',
      question-'Which sport is your favorite?',
      choices-[lacrosse, soccer, basketball],
      responses-[lacrosse, soccer, lacrosse, basketball, lacrosse, soccer,
                 lacrosse, lacrosse, soccer, basketball, lacrosse, soccer,
                 lacrosse, basketball, lacrosse, soccer, lacrosse],
      display-tally ],
    [ input_provenance-machine_supplied,
      stand_in_note-'The class survey data is never printed, so seventeen responses were chosen to reproduce the two numbers the cool-down does print at lines 315-321: nine for lacrosse and seventeen respondents in all.' ]).

% --- IM-G1-U1-L15: collect and record ten responses -------------------------
lesson_enactment_form('IM-G1-U1-L15', survey_tally_display,
    evidence('curriculum/im_teacher_guides/grade1/unit1/lesson15.md', 155,
             "Collect and record 10 responses.")).
lesson_inputs('IM-G1-U1-L15', survey_tally_display,
    [ title-'what we like to do during free time',
      question-'Which activity do you like to do during free time?',
      choices-['a read aloud', 'board games', drawing],
      responses-['a read aloud', 'board games', 'a read aloud', drawing,
                 'a read aloud', 'a read aloud', 'board games', 'a read aloud',
                 drawing, 'a read aloud'],
      display-tally ],
    [ input_provenance-machine_supplied,
      stand_in_note-'The lesson asks each pair to choose three activities and collect ten responses from classmates, so ten responses were chosen to match the guide worked recommendation that six students chose a read aloud.' ]).

% --- IM-G1-U2-L17: which equations match the story --------------------------
lesson_enactment_form('IM-G1-U2-L17', sort_into_bins,
    evidence('curriculum/im_teacher_guides/grade1/unit2/lesson17.md', 383,
             "Circle 2 equations that match the story problem.")).
lesson_inputs('IM-G1-U2-L17', sort_into_bins,
    [ title-'equations that match Lin bingo chips',
      items-['5 + [] = 7'-sum(5, unknown, 7),
             '[] + 5 = 7'-sum(unknown, 5, 7),
             '7 - 5 = []'-difference(7, 5, unknown),
             '5 + 7 = []'-sum(5, 7, unknown),
             '7 + 5 = []'-sum(7, 5, unknown)],
      bins-[ bin('matches the story', unknown_solves_to(2)),
             bin('does not match', unknown_does_not_solve_to(2)) ],
      residue_bin-'cannot be solved' ],
    [ input_provenance-machine_supplied,
      stand_in_note-'The story is printed at lines 378-381, Lin has 5 chips on her board and 7 in all, but the equation cards are images, so five candidate equations were written and the sort solves each one rather than recalling which two are circled.' ]).

% --- IM-G1-U4-L23: sort the pictures by how many ----------------------------
lesson_enactment_form('IM-G1-U4-L23', sort_into_bins,
    evidence('curriculum/im_teacher_guides/grade1/unit4/lesson23.md', 256,
             "◦ less than 20: D, E, G")).
lesson_inputs('IM-G1-U4-L23', sort_into_bins,
    [ title-'sort the pictures into three bands',
      items-['A'-64, 'B'-25, 'C'-52, 'D'-12, 'E'-8, 'F'-30, 'G'-15, 'H'-48, 'I'-40],
      bins-[ bin('less than 20', less_than(20)),
             bin('20 to 50', between_values(20, 50)),
             bin('more than 50', greater_than(50)) ],
      residue_bin-'no band claims it' ],
    [ input_provenance-machine_supplied,
      stand_in_note-'The nine picture cards are images, so a count was chosen for each letter that lands it in the band the guide prints at lines 256-260, and the sort then reaches that same grouping by comparing each count with 20 and with 50.' ]).

% --- IM-G1-U6-L7: one foot, measured in different units ---------------------
lesson_enactment_form('IM-G1-U6-L7', display_question_set,
    evidence('curriculum/im_teacher_guides/grade1/unit6/lesson7.md', 184,
             "you chose and fill in the table.")).
lesson_inputs('IM-G1-U6-L7', display_question_set,
    [ title-'the length of Jeison foot, measured in four units',
      categories-['large paper clips'-8, 'small paper clips'-16,
                  'connecting cubes'-21, 'small cubes'-40],
      question_frame-incommensurable,
      partial-sample_response_and_not_a_class_record ],
    [ input_provenance-curriculum,
      cited-'The four measurements are the guide own sample response for the table: 21 connecting cubes, 40 small cubes, 16 small paper clips, 8 large paper clips. Groups choose three of the four units, so a class table carries three of these rows.' ]).

% --- IM-G2-U1-L7: collect the class data and represent it -------------------
lesson_enactment_form('IM-G2-U1-L7', survey_tally_display,
    evidence('curriculum/im_teacher_guides/grade2/unit1/lesson7.md', 337,
             "car     7")).
lesson_inputs('IM-G2-U1-L7', survey_tally_display,
    [ title-'How We Got to School Today',
      question-'How do we get to school?',
      choices-[car, bus, walk, train],
      responses-[car, car, car, car, car, car, car,
                 bus, bus, bus, bus, bus,
                 walk, walk, walk,
                 train, train, train, train, train, train, train, train],
      display-picture_graph,
      partial-sample_response_and_not_a_class_record ],
    [ input_provenance-curriculum,
      cited-'The guide prints the same data four ways in its sample responses, as tally marks at lines 324-327 and as a numbers table at lines 337-343: car 7, bus 5, walk 3, train 8. A real class collects its own.' ]).

% --- IM-G2-U1-L10: the same data as a picture graph and a bar graph ---------
lesson_enactment_form('IM-G2-U1-L10', two_displays_one_dataset,
    evidence('curriculum/im_teacher_guides/grade2/unit1/lesson10.md', 381,
             "Student shows 6 stars, 5 frogs, 3 bears, and 6 sharks in each graph.")).
lesson_inputs('IM-G2-U1-L10', two_displays_one_dataset,
    [ title-'team names',
      categories-[stars-6, frogs-5, bears-3, sharks-6],
      first_kind-picture_graph,
      second_kind-bar_graph,
      key-1 ],
    [ input_provenance-curriculum,
      cited-'The cool-down prints one line covering both graphs at line 381: the same four counts appear in Mai picture graph and in Lin bar graph.' ]).

% --- IM-G2-U5-L14: too low, about right, too high ---------------------------
lesson_enactment_form('IM-G2-U5-L14', adjudicate_against_data,
    evidence('curriculum/im_teacher_guides/grade2/unit5/lesson14.md', 90,
             "Record an estimate that is:")).
lesson_inputs('IM-G2-U5-L14', adjudicate_against_data,
    [ title-'school supplies on the table',
      categories-[pencils-24, erasers-16, notebooks-12, markers-18],
      claims-[ claim('35 is too low.', estimate_band(too_low, 35)),
               claim('70 is about right.', estimate_band(about_right, 70)),
               claim('110 is too high.', estimate_band(too_high, 110)),
               claim('95 is too low.', estimate_band(too_low, 95)) ] ],
    [ input_provenance-machine_supplied,
      stand_in_note-'The photograph carries no printed count, so four supply counts totalling seventy were chosen to sit inside the about-right band the guide names at lines 100-102, below 40 too low and 100 or more too high, and the machine then rules on four proposed estimates against that total.' ]).

% --- IM-G2-U6-L16: two different groups of coins for one value --------------
lesson_enactment_form('IM-G2-U6-L16', constraint_fill_table,
    evidence('curriculum/im_teacher_guides/grade2/unit6/lesson16.md', 182,
             "cents. Represent that value with 2 different groups")).
lesson_inputs('IM-G2-U6-L16', constraint_fill_table,
    [ title-'groups of coins worth 50 cents',
      constraint-coin_groups_for(50),
      columns-['value in cents', 'a group of coins'],
      count-12 ],
    [ input_provenance-curriculum,
      cited-'The guide prints two groups for the 50-cent row at lines 199-201, five dimes and one quarter with two dimes and one nickel, and both appear in the enumeration this constraint produces.' ]).

% --- IM-G3-U1-L1: how are the two graphs alike and different ----------------
lesson_enactment_form('IM-G3-U1-L1', two_displays_one_dataset,
    evidence('curriculum/im_teacher_guides/grade3/unit1/lesson1.md', 256,
             "     A group of students were asked, “How do you get           • Groups of 2")).
lesson_inputs('IM-G3-U1-L1', two_displays_one_dataset,
    [ title-'How do you get home?',
      categories-[bus-7, car-4, walk-3, bike-2],
      first_kind-picture_graph,
      second_kind-bar_graph,
      key-1 ],
    [ input_provenance-machine_supplied,
      stand_in_note-'Both graphs are images, so four counts were chosen that hold the one absolute figure the guide prints, seven for the bus, together with its statement that more students take the bus than ride bikes.' ]).

% --- IM-G3-U1-L2: the same class data twice --------------------------------
lesson_enactment_form('IM-G3-U1-L2', two_displays_one_dataset,
    evidence('curriculum/im_teacher_guides/grade3/unit1/lesson2.md', 174,
             "2. Represent the same data in a bar graph.                   bottom axis for bike, walk, bus, van, car, and train.")).
lesson_inputs('IM-G3-U1-L2', two_displays_one_dataset,
    [ title-'How We Get Home',
      categories-[bike-6, walk-4, bus-3, van-2, car-4, train-2],
      first_kind-picture_graph,
      second_kind-bar_graph,
      key-1 ],
    [ input_provenance-machine_supplied,
      stand_in_note-'The graph is built live from that day sticky notes, so counts were chosen for the six categories the guide names at line 174 that hold both differences its answers print: three more bike than bus, and two more car or van than walk.' ]).

% --- IM-G3-U1-L4: a scaled picture graph, two students per picture ----------
lesson_enactment_form('IM-G3-U1-L4', scale_choice,
    evidence('curriculum/im_teacher_guides/grade3/unit1/lesson4.md', 223,
             "Represent the class survey data in a scaled picture          • Groups of 2")).
lesson_inputs('IM-G3-U1-L4', scale_choice,
    [ title-'How would you like to travel?',
      categories-[car-7, train-4, boat-3, balloon-6, plane-5, helicopter-2],
      candidate_scales-[2] ],
    [ input_provenance-machine_supplied,
      stand_in_note-'The survey runs live and the guide prints answers vary, so counts were chosen for the six travel categories it lists with odd amounts among them, because the half picture an odd amount forces at a scale of two is what the lesson turns on.' ]).

% --- IM-G3-U1-L7: use the bar graph to answer the questions -----------------
lesson_enactment_form('IM-G3-U1-L7', display_question_set,
    evidence('curriculum/im_teacher_guides/grade3/unit1/lesson7.md', 160,
             "Use your Favorite Season bar graph to answer the          • Groups of 2")).
lesson_inputs('IM-G3-U1-L7', display_question_set,
    [ title-'Favorite Season of the Year',
      categories-[winter-24, spring-13, summer-40, fall-22] ],
    [ input_provenance-curriculum,
      cited-'The four counts follow uniquely from the four answers the guide prints: 99 students in all, 35 for spring or fall, summer 16 above winter, and spring 9 below fall. They are the same four the previous lesson prints in its table.' ]).

% --- IM-G3-U1-L21: the game night graph -------------------------------------
lesson_enactment_form('IM-G3-U1-L21', display_question_set,
    evidence('curriculum/im_teacher_guides/grade3/unit1/lesson21.md', 201,
             "• Game A - 2 players")).
lesson_inputs('IM-G3-U1-L21', display_question_set,
    [ title-'people playing each game at game night',
      categories-['Game A'-8, 'Game B'-16, 'Game C'-10, 'Game D'-10],
      question_frame-counted,
      partial-sample_response_and_not_a_class_record ],
    [ input_provenance-curriculum,
      cited-'The four game sizes are printed at lines 201-206 and the seating plan is open, so the guide prints one worked arrangement whose four counts this reads; a class that assumes differently graphs different counts.' ]).

% --- IM-G3-U2-L11: build a rectangle with an area of 24 ---------------------
lesson_enactment_form('IM-G3-U2-L11', constraint_fill_table,
    evidence('curriculum/im_teacher_guides/grade3/unit2/lesson11.md', 162,
             "with an area of 24")).
lesson_enactment_form('IM-G3-U2-L11', notice_and_wonder,
    evidence('curriculum/im_teacher_guides/grade3/unit2/lesson11.md', 147,
             "What do you notice? What do you wonder?                    • Groups of 2")).
lesson_inputs('IM-G3-U2-L11', constraint_fill_table,
    [ title-'rectangles in the multiplication table with an area of 24 square units',
      constraint-rectangles_with_area(24),
      columns-['rows', 'columns'],
      count-6 ],
    [ input_provenance-curriculum,
      cited-'The area of 24 square units is printed in the task at lines 160-163, and the table the class works in is the multiplication table, so a rectangle corner reads as a factor pair.' ]).
lesson_inputs('IM-G3-U2-L11', notice_and_wonder,
    [ title-'the multiple of 3 in the third row of each displayed table',
      values-[3, 6, 9, 12] ],
    [ input_provenance-curriculum,
      cited-'The warm-up displays four blank tables each showing a multiple of 3 in the third row, in order from 3 to 12, at lines 148-150.' ]).

% --- IM-G3-U3-L13: close to 0, close to 100, close to 200 -------------------
lesson_enactment_form('IM-G3-U3-L13', sort_into_bins,
    evidence('curriculum/im_teacher_guides/grade3/unit3/lesson13.md', 214,
             "close to 0       close to 100         close to 200")).
lesson_inputs('IM-G3-U3-L13', sort_into_bins,
    [ title-'people in different parts of a school at noon',
      items-[playground-94, classrooms-216, cafeteria-163, gymnasium-109,
             'art room'-36, 'music room'-52, library-49],
      bins-[ bin('close to 0', nearest_multiple_is(100, 0)),
             bin('close to 100', nearest_multiple_is(100, 100)),
             bin('close to 200', nearest_multiple_is(100, 200)) ],
      residue_bin-'set aside' ],
    [ input_provenance-curriculum,
      cited-'The seven locations and counts are printed at lines 178-184. Sorting by nearest hundred places the library at 49 and the music room at 52, which this lesson sample answer sets aside; the same two numbers are rounded to 0 and to 100 in the printed table of the next lesson, so the disagreement runs between the two lessons rather than between the machine and the guide.' ]).

% --- IM-G3-U3-L15: Andre rounds to hundreds, Lin rounds to tens -------------
lesson_enactment_form('IM-G3-U3-L15', table_from_rule,
    evidence('curriculum/im_teacher_guides/grade3/unit3/lesson15.md', 251,
             "people in the whole school. Andre plans to round             help Andre and Lin make estimates of the number of")).
lesson_inputs('IM-G3-U3-L15', table_from_rule,
    [ title-'Andre estimate to the nearest hundred beside Lin estimate to the nearest ten',
      rule-round_to_multiple(100),
      second_rule-round_to_multiple(10),
      source_values-[94, 163, 36, 49, 216, 109, 52],
      columns-['number', 'nearest hundred'],
      count-7 ],
    [ input_provenance-curriculum,
      cited-'The seven counts and both rounded columns are printed in the guide answer table, Andre 100, 200, 0, 0, 200, 100, 100 totalling 700 and Lin 90, 160, 40, 50, 220, 110, 50 totalling 720.' ]).

% --- IM-G3-U8-L6: write the survey -----------------------------------------
lesson_enactment_form('IM-G3-U8-L6', survey_tally_display,
    evidence('curriculum/im_teacher_guides/grade3/unit8/lesson6.md', 138,
             "Create a survey that you’ll use with a large group of      • Groups of 4")).
lesson_inputs('IM-G3-U8-L6', survey_tally_display,
    [ title-'favorite type of book',
      question-'What is your favorite type of book?',
      choices-['history books', 'how-to books', 'mystery books', 'story books'],
      responses-['mystery books', 'story books', 'mystery books', 'history books',
                 'story books', 'mystery books', 'how-to books', 'story books',
                 'mystery books', 'history books', 'story books', 'mystery books',
                 'how-to books', 'story books', 'mystery books', 'story books',
                 'history books', 'mystery books', 'story books', 'mystery books'],
      display-bar_graph ],
    [ input_provenance-machine_supplied,
      stand_in_note-'The question and its answer choices are the guide own sample at lines 148-150, and the responses are collected from a large group over the following days and never printed, so twenty responses stand in for that collection.' ]).

% --- IM-G3-U8-L12: build a Notice and Wonder and run it for another group ---
% Handed over by the measurement lane. Two forms: the group designs the routine
% it will facilitate, and the same group is the audience for the warm-up.
lesson_enactment_form('IM-G3-U8-L12', design_and_run_a_routine,
    evidence('curriculum/im_teacher_guides/grade3/unit8/lesson12.md', 157,
             "       1. Find an image that would encourage your              • Groups of 3 or 4")).
lesson_inputs('IM-G3-U8-L12', design_and_run_a_routine,
    [ title-'a Notice and Wonder about equal groups',
      routine-notice_and_wonder,
      stimulus-equal_groups(6, 4, plants, pot-pots) ],
    [ input_provenance-machine_supplied,
      stand_in_note-'The group finds its own image in a picture book, so an equal-groups arrangement was chosen to match the one the guide own warm-up describes at lines 107-114, pots of plants organized in rows.' ]).

% --- IM-G3-U8-L7: choose a scale for the survey bar graph -------------------
lesson_enactment_form('IM-G3-U8-L7', scale_choice,
    evidence('curriculum/im_teacher_guides/grade3/unit8/lesson7.md', 167,
             "Work with your group to create a bar graph that           • Groups of 4")).
lesson_inputs('IM-G3-U8-L7', scale_choice,
    [ title-'Favorite Colors',
      categories-[yellow-8, orange-10, blue-42],
      candidate_scales-[1, 2, 5, 10] ],
    [ input_provenance-curriculum,
      cited-'The three counts are printed in the cool-down answer at lines 330-331: 8 liked yellow, 10 liked orange, and 42 liked blue.' ]).

% --- IM-G4-U1-L3: prime or composite ----------------------------------------
lesson_enactment_form('IM-G4-U1-L3', sort_into_bins,
    evidence('curriculum/im_teacher_guides/grade4/unit1/lesson3.md', 299,
             "The table shows different areas. How many                   • Groups of 2")).
lesson_enactment_form('IM-G4-U1-L3', constraint_fill_table,
    evidence('curriculum/im_teacher_guides/grade4/unit1/lesson3.md', 303,
             "      Complete the table.                                           rectangle, how could you find out how")).
lesson_inputs('IM-G4-U1-L3', sort_into_bins,
    [ title-'is each area prime or composite',
      items-[2, 10, 48, 11, 21, 23, 60, 32, 42, 31, 56],
      bins-[ bin(prime, is_prime), bin(composite, is_composite) ],
      residue_bin-'neither prime nor composite' ],
    [ input_provenance-curriculum,
      cited-'The eleven areas and their prime or composite classification are printed in the guide answer table: 2, 11, 23, and 31 prime and the other seven composite.' ]).
lesson_inputs('IM-G4-U1-L3', constraint_fill_table,
    [ title-'rectangles with whole-number side lengths and an area of 48',
      constraint-rectangles_with_area(48),
      columns-['length', 'width'],
      count-6 ],
    [ input_provenance-curriculum,
      cited-'The guide answer table records 5 rectangles for an area of 48, and the enumeration that counts a pair of side lengths once produces exactly those five.' ]).

% --- IM-G4-U3-L13: measure the pencils, then measure them again -------------
lesson_enactment_form('IM-G4-U3-L13', measure_then_plot,
    evidence('curriculum/im_teacher_guides/grade4/unit3/lesson13.md', 210,
             "2. Create a line plot to represent the data your           nearest    inch. Record your measurements in the")).
lesson_inputs('IM-G4-U3-L13', measure_then_plot,
    [ title-'colored pencil lengths',
      objects-['pencil 1'-3.4, 'pencil 2'-4.1, 'pencil 3'-2.8, 'pencil 4'-5.3,
               'pencil 5'-4.6, 'pencil 6'-3.9, 'pencil 7'-6.2, 'pencil 8'-4.4,
               'pencil 9'-5.05, 'pencil 10'-3.15],
      unit-inches,
      precision-1/4,
      finer_precision-1/8 ],
    [ input_provenance-machine_supplied,
      stand_in_note-'Each group measures its own used pencils and every length in the guide is an inline fraction image the extraction drops, so ten lengths were chosen for the ten pencils the guide answer names, and the two passes run at the quarter inch and the eighth inch the lesson calls for.' ]).
