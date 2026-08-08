/** <module> Enactment lane: the 72 geometry construction and measure lessons
 *
 * The action-seam recut files 72 IM lessons under
 * `geometry_construction_or_measure`. None of them asks for an arithmetic
 * result an existing automaton computes, so the coverage census had them at
 * the ceiling: a doing named, no machine enacting it. This lane builds the
 * machines.
 *
 * An enactment is not a claim that software ran a lesson. It names the
 * structure a lesson asks a class to move through, runs that structure on
 * inputs, and prints an artifact a teacher can read together with a verdict
 * about what the artifact warrants. Where the guide prints the numbers, the
 * enactment uses them. Where the guide says "your teacher will give you a set
 * of cards" and prints no cards, the machine supplies a figure set of its own
 * and the row says so: `input_provenance` separates the two cases on every
 * emitted record, and no coverage number folds them together.
 *
 * Everything the forms decide is calculated. `geometry_figures` computes side
 * counts, parallel pairs, right angles, equal lengths, lines of symmetry and
 * area from vertex coordinates by exact integer arithmetic. A figure is a
 * square in this module because four equal sides carry four right angles when
 * the arithmetic runs, never because a row said `square`.
 *
 * Three results fell out of building it rather than being put in:
 *   - The lattice holds no equilateral triangle, no regular pentagon and no
 *     regular hexagon. Constructions that ask for one get the argument, not a
 *     near miss.
 *   - Rolling a cube over each of the 35 hexominoes finds exactly 11 that fold
 *     to a cube, which is what grade 2 unit 6 lesson 4 asks a class to find.
 *   - Some cells of the grade 5 triangle-sorting chart are empty for a reason
 *     the machine can state, and the lesson asks students to explain exactly
 *     that.
 *
 * Contract: `enactment_form/3`, `lesson_enactment_form/3`, `enactment_move/3`,
 * `enact/3`, `enactment_verdict/2` per the task-236 spec. `Steps` serialize
 * through `enactment_trace_dict/2` into the shape
 * `hermes_encyclopedia:strategy_trace_dict/3` already returns, so an enactment
 * shows up wherever a strategy trace shows up and needs no viewer of its own.
 */

:- module(geometry_construction,
          [ enactment_form/3,
            lesson_enactment_form/3,
            enactment_move/3,
            enact/3,
            enactment_verdict/2,
            enactment_trace_dict/2,
            enactment_artifact_dict/2,
            lesson_inputs/3,
            lesson_input_term/3,
            lesson_caveat/2,
            geometry_lane_lessons/1,
            geometry_lane_coverage/1,
            geometry_lane_refusal/2,
            lane_move_audit/2
          ]).

:- use_module(im_lessons('enactment/support/geometry_figures')).
:- use_module(render(geoboard_scene), []).
:- use_module(render(polyform_tiling_scene), []).
:- use_module(render(angle_circular_scene), []).
:- use_module(render(coordinate_plane_scene), []).
:- use_module(render(solid_net_scene), []).
:- use_module(render(measurement_strip_scene), []).
:- use_module(library(lists)).
:- use_module(library(apply)).
:- use_module(library(pairs)).
:- use_module(library(http/json), [json_write_dict/3]).

%   The aggregator in curriculum/im/lesson_enactment.pl imports these five
%   names; the multifile declarations let it either import or collect them.
:- multifile enactment_form/3.
:- multifile lesson_enactment_form/3.
:- multifile enactment_move/3.

:- discontiguous run_form/4.

% =============================================================================
% 1. The forms
% =============================================================================

%!  enactment_form(?Form, ?Gloss, ?Warrant) is nondet.
%
%   The structural shapes these 72 lessons take. Each warrant names a lesson
%   whose printed task exhibits the shape, with the line the span starts on.
enactment_form(attribute_sort,
    'A figure set is placed into named categories, and what fits none or more than one is reported.',
    warrant('IM-G4-U8-L3', 'curriculum/im_teacher_guides/grade4/unit8/lesson3.md', 172,
            "Find the quadrilaterals that have each of the following attributes. Record their letter names here.")).
enactment_form(construct_to_spec,
    'A figure is produced that satisfies a printed list of constraints, or the search reports what it exhausted.',
    warrant('IM-G4-U8-L6', 'curriculum/im_teacher_guides/grade4/unit8/lesson6.md', 158,
            "Draw 1 or more segments to create a figure with only 1 line of symmetry.")).
enactment_form(cover_and_count,
    'A region is covered with a repeated unit and the covering is counted, which is what makes the array equations true of it.',
    warrant('IM-G2-U8-L11', 'curriculum/im_teacher_guides/grade2/unit8/lesson11.md', 170,
            "Arrange all the tiles in an array. Then push them together to make a rectangle.")).
enactment_form(partition_equal_parts,
    'A whole is split into equal parts, the part is named, and the shaded amount is read as a fraction of the whole.',
    warrant('IM-G2-U6-L7', 'curriculum/im_teacher_guides/grade2/unit6/lesson7.md', 185,
            "Fold the rectangle to make 2 equal-size pieces. Cut them out. Each piece is called a ____.")).
enactment_form(compose_from_parts,
    'Smaller pieces are assembled into a target, and the distinct assemblies are enumerated.',
    warrant('IM-GK-U3-L12', 'curriculum/im_teacher_guides/kindergarten/unit3/lesson12.md', 292,
            "Display all the ways to make a hexagon.")).
enactment_form(measure_and_order,
    'A measure is computed for each object, and the ordering question the lesson asks is answered from the measures.',
    warrant('IM-G4-U7-L6', 'curriculum/im_teacher_guides/grade4/unit7/lesson6.md', 258,
            "Order the angles on the cards from smallest to largest.")).
enactment_form(angle_composition,
    'Angles add and subtract against a known whole, so copies of a part and the turn they fill determine each other.',
    warrant('IM-G4-U7-L13', 'curriculum/im_teacher_guides/grade4/unit7/lesson13.md', 390,
            "Three copies of Angle P make a straight line. How many degrees is Angle P?")).
enactment_form(describe_and_reproduce,
    'A description is generated from a figure, rebuilt from, and the figures the description still allows are counted.',
    warrant('IM-G3-U2-L4', 'curriculum/im_teacher_guides/grade3/unit2/lesson4.md', 162,
            "Partner A: Draw a rectangle. Describe the rectangle to your partner without telling the total number of grid squares it covers.")).
enactment_form(separating_attribute,
    'An attribute is searched for that splits a figure set the way the game asks, or the vocabulary is reported as too coarse.',
    warrant('IM-G5-U7-L4', 'curriculum/im_teacher_guides/grade5/unit7/lesson4.md', 159,
            "Partner B: Ask yes or no questions to determine which shape your partner chose.")).
enactment_form(hierarchy_claim,
    'A quantified claim about two shape classes is adjudicated against every figure in the inventory.',
    warrant('IM-G5-U7-L7', 'curriculum/im_teacher_guides/grade5/unit7/lesson7.md', 254,
            "Write always, sometimes, or never in each blank to make the statements true.")).
enactment_form(coordinate_locate,
    'A point is placed from its coordinates or read off its position, and a figure is named from its vertices.',
    warrant('IM-G5-U7-L2', 'curriculum/im_teacher_guides/grade5/unit7/lesson2.md', 156,
            "Partner B: Plot the point on the blank coordinate grid.")).
enactment_form(derive_unknown_measure,
    'An unlabelled length, area or volume is derived from labelled ones, or the sides that leave it undetermined are named.',
    warrant('IM-G4-U8-L7', 'curriculum/im_teacher_guides/grade4/unit8/lesson7.md', 259,
            "Mai says we cannot find the perimeter of any of these shapes. Andre says we can find the perimeters for C and D but not for A and B.")).

% =============================================================================
% 2. The moves
% =============================================================================

%!  enactment_move(?Form, ?Index, ?Move) is nondet.
%
%   The ordered doings each form asks for. Every move below is a verb the
%   runner executes on an operand and returns a result for; none is a label
%   stored beside a verb that never runs.
enactment_move(attribute_sort, 1, read_categories).
enactment_move(attribute_sort, 2, compute_attributes).
enactment_move(attribute_sort, 3, place_each_figure).
enactment_move(attribute_sort, 4, report_residue).

enactment_move(construct_to_spec, 1, read_constraints).
enactment_move(construct_to_spec, 2, search_figure_space).
enactment_move(construct_to_spec, 3, verify_witness).
enactment_move(construct_to_spec, 4, report_found_or_exhausted).

enactment_move(cover_and_count, 1, choose_unit).
enactment_move(cover_and_count, 2, lay_unit_over_region).
enactment_move(cover_and_count, 3, count_covering).
enactment_move(cover_and_count, 4, write_array_equations).

enactment_move(partition_equal_parts, 1, split_whole).
enactment_move(partition_equal_parts, 2, check_parts_equal).
enactment_move(partition_equal_parts, 3, name_the_part).
enactment_move(partition_equal_parts, 4, read_shaded_fraction).

enactment_move(compose_from_parts, 1, read_target).
enactment_move(compose_from_parts, 2, enumerate_candidates).
enactment_move(compose_from_parts, 3, check_exact_fit).
enactment_move(compose_from_parts, 4, count_distinct_ways).

enactment_move(measure_and_order, 1, measure_quantity).
enactment_move(measure_and_order, 2, order_by_magnitude).
enactment_move(measure_and_order, 3, answer_ordering_query).

enactment_move(angle_composition, 1, read_known_whole).
enactment_move(angle_composition, 2, compose_or_divide_turn).
enactment_move(angle_composition, 3, report_degree_measure).

enactment_move(describe_and_reproduce, 1, compute_source_attributes).
enactment_move(describe_and_reproduce, 2, state_description).
enactment_move(describe_and_reproduce, 3, rebuild_from_description).
enactment_move(describe_and_reproduce, 4, count_figures_still_allowed).

enactment_move(separating_attribute, 1, build_attribute_matrix).
enactment_move(separating_attribute, 2, search_separating_condition).
enactment_move(separating_attribute, 3, report_split_or_coarseness).

enactment_move(hierarchy_claim, 1, fix_definition).
enactment_move(hierarchy_claim, 2, test_criteria).
enactment_move(hierarchy_claim, 3, report_quantifier).

enactment_move(coordinate_locate, 1, place_or_read_points).
enactment_move(coordinate_locate, 2, name_figure_from_vertices).

enactment_move(derive_unknown_measure, 1, read_labelled_measures).
enactment_move(derive_unknown_measure, 2, apply_closure_constraint).
enactment_move(derive_unknown_measure, 3, report_determined_or_underdetermined).

% =============================================================================
% 3. The 72 lessons: form, warrant, inputs, caveat
% =============================================================================

%!  lesson_enactment_form(?Lesson, ?Form, ?Evidence) is nondet.
%
%   Evidence carries the guide file, the line the task span starts on, and the
%   span text that licensed the reading. Every line below is the
%   `task_209_evidence` row that put the lesson in this subclass, so the
%   citation and the classification rest on the same span.
%
%   Kindergarten
lesson_enactment_form('IM-GK-U3-L2', attribute_sort,
    evidence('curriculum/im_teacher_guides/kindergarten/unit3/lesson2.md', 139,
             "Match the shape. Draw a line.")).
lesson_enactment_form('IM-GK-U3-L8', describe_and_reproduce,
    evidence('curriculum/im_teacher_guides/kindergarten/unit3/lesson8.md', 124,
             "These dots will help us draw. Draw straight lines to connect the dots. This shape has 3 sides and 3 corners.")).
lesson_enactment_form('IM-GK-U3-L12', compose_from_parts,
    evidence('curriculum/im_teacher_guides/kindergarten/unit3/lesson12.md', 292,
             "Display all the ways to make a hexagon. Are these the same way to make a hexagon or are they different ways?")).
lesson_enactment_form('IM-GK-U3-L15', compose_from_parts,
    evidence('curriculum/im_teacher_guides/kindergarten/unit3/lesson15.md', 186,
             "Make an animal with shape stamps.")).

%   Grade 1
lesson_enactment_form('IM-G1-U1-L8', attribute_sort,
    evidence('curriculum/im_teacher_guides/grade1/unit1/lesson8.md', 246,
             "Show how you sorted the shape cards. The first category has ____ shapes. There are ____ shapes in all.")).
lesson_enactment_form('IM-G1-U7-L3', attribute_sort,
    evidence('curriculum/im_teacher_guides/grade1/unit7/lesson3.md', 351,
             "Han sorted some shapes. Draw each shape in the group in which it belongs.")).
lesson_enactment_form('IM-G1-U7-L4', describe_and_reproduce,
    evidence('curriculum/im_teacher_guides/grade1/unit7/lesson4.md', 160,
             "Pick a shape card. Draw the shape on the dot grid. Take turns describing the shape that you have drawn.")).
lesson_enactment_form('IM-G1-U7-L9', partition_equal_parts,
    evidence('curriculum/im_teacher_guides/grade1/unit7/lesson9.md', 244,
             "Cut out 1 circle and 1 square. Fold each shape so that there are 2 equal pieces. Fold each shape so that there are 4 equal pieces.")).
lesson_enactment_form('IM-G1-U7-L10', attribute_sort,
    evidence('curriculum/im_teacher_guides/grade1/unit7/lesson10.md', 247,
             "Sort your cards into these categories. A fourth or a quarter is shaded. A half is shaded. The whole shape is shaded. The pieces are not equal.")).
lesson_enactment_form('IM-G1-U7-L18', partition_equal_parts,
    evidence('curriculum/im_teacher_guides/grade1/unit7/lesson18.md', 132,
             "Designers plan a park. It will be split into 4 equal sections. The pool will have 4 lanes. A net splits the court into 2 equal pieces.")).

%   Grade 2
lesson_enactment_form('IM-G2-U6-L1', attribute_sort,
    evidence('curriculum/im_teacher_guides/grade2/unit6/lesson1.md', 277,
             "Gather clues to find out what kind of shapes belong in each category. triangle pentagon hexagon quadrilateral")).
lesson_enactment_form('IM-G2-U6-L2', construct_to_spec,
    evidence('curriculum/im_teacher_guides/grade2/unit6/lesson2.md', 150,
             "Complete the shape to make a quadrilateral. Then draw a different 4-sided shape. Complete the shape to make a pentagon.")).
lesson_enactment_form('IM-G2-U6-L3', construct_to_spec,
    evidence('curriculum/im_teacher_guides/grade2/unit6/lesson3.md', 149,
             "Diego draws a shape with fewer than 5 sides. Two sides are 3 centimeters long. Tyler draws a shape with 4 sides. Each side is 2 inches long.")).
lesson_enactment_form('IM-G2-U6-L4', compose_from_parts,
    evidence('curriculum/im_teacher_guides/grade2/unit6/lesson4.md', 195,
             "Which shape designs can you fold to make cubes? What is the name for a solid shape that has 6 faces that are all squares?")).
lesson_enactment_form('IM-G2-U6-L6', compose_from_parts,
    evidence('curriculum/im_teacher_guides/grade2/unit6/lesson6.md', 313,
             "Compose 3 different shapes. Use 2, 3, or 4 of the same equal-size shapes.")).
lesson_enactment_form('IM-G2-U6-L7', partition_equal_parts,
    evidence('curriculum/im_teacher_guides/grade2/unit6/lesson7.md', 185,
             "Fold the rectangle to make 2 equal-size pieces. Each piece is called a ____. Fold the rectangle to make 4 equal-size pieces.")).
lesson_enactment_form('IM-G2-U8-L11', cover_and_count,
    evidence('curriculum/im_teacher_guides/grade2/unit8/lesson11.md', 170,
             "Choose a number of tiles. 12 15 16 18 20. Arrange all the tiles in an array. How many rows? How many columns? Write 2 equations.")).

%   Grade 3
lesson_enactment_form('IM-G3-U2-L1', measure_and_order,
    evidence('curriculum/im_teacher_guides/grade3/unit2/lesson1.md', 160,
             "Here are 2 triangles. Which triangle is larger? In each pair of shapes, which shape is larger?")).
lesson_enactment_form('IM-G3-U2-L2', cover_and_count,
    evidence('curriculum/im_teacher_guides/grade3/unit2/lesson2.md', 177,
             "Take a handful of square tiles. Create a flat shape by connecting the tiles. As a group, order the shapes from smallest to largest.")).
lesson_enactment_form('IM-G3-U2-L3', cover_and_count,
    evidence('curriculum/im_teacher_guides/grade3/unit2/lesson3.md', 172,
             "Describe or show how to use the square tiles to measure the area of each rectangle. Andre says this rectangle has an area of 23 square units.")).
lesson_enactment_form('IM-G3-U2-L4', describe_and_reproduce,
    evidence('curriculum/im_teacher_guides/grade3/unit2/lesson4.md', 162,
             "Partner A: Draw a rectangle on 1 of the grids. Describe the rectangle to your partner without telling the total number of grid squares it covers.")).
lesson_enactment_form('IM-G3-U2-L8', cover_and_count,
    evidence('curriculum/im_teacher_guides/grade3/unit2/lesson8.md', 184,
             "Each square tile has a side length of 1 inch. How many tiles are needed to tile the whole rectangle?")).
lesson_enactment_form('IM-G3-U2-L9', construct_to_spec,
    evidence('curriculum/im_teacher_guides/grade3/unit2/lesson9.md', 147,
             "Use it to create a rectangle with your assigned area. Area A: 4 square feet. Area B: 6 square feet. Area C: 9 square feet.")).
lesson_enactment_form('IM-G3-U2-L14', derive_unknown_measure,
    evidence('curriculum/im_teacher_guides/grade3/unit2/lesson14.md', 134,
             "Tyler says that this figure's unknown side length is 5 meters because it looks longer than the sides that are 4 meters long.")).
lesson_enactment_form('IM-G3-U2-L15', derive_unknown_measure,
    evidence('curriculum/im_teacher_guides/grade3/unit2/lesson15.md', 242,
             "What is the area of the floorspace in the room that is not covered by furniture?")).
lesson_enactment_form('IM-G3-U4-L11', cover_and_count,
    evidence('curriculum/im_teacher_guides/grade3/unit4/lesson11.md', 160,
             "Mark or shade the rectangle to show a strategy for finding its area. Write 1 or more expressions that can represent how you find the area.")).
lesson_enactment_form('IM-G3-U4-L15', cover_and_count,
    evidence('curriculum/im_teacher_guides/grade3/unit4/lesson15.md', 171,
             "A rectangular mural has side lengths of 17 feet and 4 feet. What is the area of the mural?")).
lesson_enactment_form('IM-G3-U5-L10', attribute_sort,
    evidence('curriculum/im_teacher_guides/grade3/unit5/lesson10.md', 167,
             "Which shapes have shading that covers ___ of the shape? How can there be more than 1 way of shading a shape to show ___ ?")).
lesson_enactment_form('IM-G3-U6-L7', measure_and_order,
    evidence('curriculum/im_teacher_guides/grade3/unit6/lesson7.md', 190,
             "How many units do you think it takes to fill Container B? Record an estimate that is too low, about right, too high.")).
lesson_enactment_form('IM-G3-U7-L4', attribute_sort,
    evidence('curriculum/im_teacher_guides/grade3/unit7/lesson4.md', 155,
             "Which of the following are right triangles? Which of the following are rectangles? Select all of the quadrilaterals that are rhombuses.")).
lesson_enactment_form('IM-G3-U7-L6', measure_and_order,
    evidence('curriculum/im_teacher_guides/grade3/unit7/lesson6.md', 155,
             "Work with your group to find out which shape takes the most paper clips to build.")).
lesson_enactment_form('IM-G3-U7-L15', derive_unknown_measure,
    evidence('curriculum/im_teacher_guides/grade3/unit7/lesson15.md', 206,
             "Maya wants to get some chickens. The coop takes up 24 square feet of space. Each chicken needs 8 to 10 square feet outside the coop. She has 2 rolls of fencing, and each roll has 15 feet.")).
lesson_enactment_form('IM-G3-U8-L4', derive_unknown_measure,
    evidence('curriculum/im_teacher_guides/grade3/unit8/lesson4.md', 191,
             "Choose the type of rectangular tiny house you will design. shipping container 8 feet by 20. cabin 8 feet by 10.")).

%   Grade 4
lesson_enactment_form('IM-G4-U1-L1', construct_to_spec,
    evidence('curriculum/im_teacher_guides/grade4/unit1/lesson1.md', 311,
             "Elena builds rectangles with a width of 3 units and an area of 30 square units or less. Why is 28 square units not a possible area?")).
lesson_enactment_form('IM-G4-U1-L8', attribute_sort,
    evidence('curriculum/im_teacher_guides/grade4/unit1/lesson8.md', 272,
             "Describe which of the following you see in the area of the rectangles: all the factors of a number, at least 6 multiples, prime numbers, composite numbers.")).
lesson_enactment_form('IM-G4-U4-L17', measure_and_order,
    evidence('curriculum/im_teacher_guides/grade4/unit4/lesson17.md', 184,
             "Planes flying over the same area need to stay at least 1,000 feet apart in altitude. Round each altitude to the nearest thousand.")).
lesson_enactment_form('IM-G4-U6-L2', compose_from_parts,
    evidence('curriculum/im_teacher_guides/grade4/unit6/lesson2.md', 233,
             "Pattern A: Repeat circle, square. Pattern B: Repeat triangle, circle, square. What do you predict is the 25th shape in each pattern?")).
lesson_enactment_form('IM-G4-U6-L23', derive_unknown_measure,
    evidence('curriculum/im_teacher_guides/grade4/unit6/lesson23.md', 167,
             "A poster paper measures 36 inches by 24 inches. The banner is 8 inches tall and 8 feet long. Does she have enough paper?")).
lesson_enactment_form('IM-G4-U7-L1', describe_and_reproduce,
    evidence('curriculum/im_teacher_guides/grade4/unit7/lesson1.md', 191,
             "Describe the image on the card as clearly and precisely as possible so that your partner can draw it on a blank card.")).
lesson_enactment_form('IM-G4-U7-L3', construct_to_spec,
    evidence('curriculum/im_teacher_guides/grade4/unit7/lesson3.md', 178,
             "Three lines intersect to form a triangle. Can you draw a fourth line so that the four lines form a quadrilateral? A rectangle?")).
lesson_enactment_form('IM-G4-U7-L4', attribute_sort,
    evidence('curriculum/im_teacher_guides/grade4/unit7/lesson4.md', 212,
             "Use the words WHALE and JOY to find one or more letters that represent each description. a. No parallel segments")).
lesson_enactment_form('IM-G4-U7-L5', describe_and_reproduce,
    evidence('curriculum/im_teacher_guides/grade4/unit7/lesson5.md', 214,
             "Take turns describing and drawing the geometric figure on each card. Decide if each figure shows at least one angle.")).
lesson_enactment_form('IM-G4-U7-L6', measure_and_order,
    evidence('curriculum/im_teacher_guides/grade4/unit7/lesson6.md', 258,
             "You will need Cards A to P from an earlier activity. Order the angles on the cards from smallest to largest.")).
lesson_enactment_form('IM-G4-U7-L7', angle_composition,
    evidence('curriculum/im_teacher_guides/grade4/unit7/lesson7.md', 192,
             "Imagine both hands are pointing at the 12. Turn the minute hand so it's pointing at the 3. In each pair of angles, which angle is greater?")).
lesson_enactment_form('IM-G4-U7-L8', angle_composition,
    evidence('curriculum/im_teacher_guides/grade4/unit7/lesson8.md', 149,
             "A ray that turns all the way around its starting point has made a full turn. We say that the ray has turned 360 degrees.")).
lesson_enactment_form('IM-G4-U7-L11', construct_to_spec,
    evidence('curriculum/im_teacher_guides/grade4/unit7/lesson11.md', 281,
             "On each labeled card, draw an angle that meets the requirement with the same letter. Use a ruler and a protractor.")).
lesson_enactment_form('IM-G4-U7-L13', angle_composition,
    evidence('curriculum/im_teacher_guides/grade4/unit7/lesson13.md', 390,
             "Three copies of Angle P make a straight line. Three copies of Angle Q make a right angle. Noah puts Angle P and Angle Q together.")).
lesson_enactment_form('IM-G4-U7-L14', angle_composition,
    evidence('curriculum/im_teacher_guides/grade4/unit7/lesson14.md', 259,
             "The hour and minute hands form an angle at each of these times. How many degrees is each angle? a. 6 o'clock b. 8 o'clock c. 9 o'clock")).
lesson_enactment_form('IM-G4-U7-L15', angle_composition,
    evidence('curriculum/im_teacher_guides/grade4/unit7/lesson15.md', 169,
             "Find the measurement of each shaded angle. Show how you know.")).
lesson_enactment_form('IM-G4-U7-L16', angle_composition,
    evidence('curriculum/im_teacher_guides/grade4/unit7/lesson16.md', 157,
             "Draw a horizontal line and measure the angle that the street makes. Make the height of each step 1 unit tall.")).
lesson_enactment_form('IM-G4-U8-L3', attribute_sort,
    evidence('curriculum/im_teacher_guides/grade4/unit8/lesson3.md', 172,
             "Find the quadrilaterals that have each of the following attributes: no right angles, only 1 pair of parallel sides, same length for all sides, 2 obtuse angles.")).
lesson_enactment_form('IM-G4-U8-L6', construct_to_spec,
    evidence('curriculum/im_teacher_guides/grade4/unit8/lesson6.md', 264,
             "Can you connect the dots to create each of the following shapes? a triangle with only 1 line of symmetry, a quadrilateral with 2 pairs of parallel sides, a rectangle")).
lesson_enactment_form('IM-G4-U8-L7', derive_unknown_measure,
    evidence('curriculum/im_teacher_guides/grade4/unit8/lesson7.md', 259,
             "Mai says we cannot find the perimeter of any of these shapes. Andre says we can find the perimeters for C and D but not for A and B.")).
lesson_enactment_form('IM-G4-U8-L10', angle_composition,
    evidence('curriculum/im_teacher_guides/grade4/unit8/lesson10.md', 170,
             "When they fold their papers along the line of symmetry, they all produce the same shape. Without measuring, find the measurement of all angles.")).
lesson_enactment_form('IM-G4-U9-L11', separating_attribute,
    evidence('curriculum/im_teacher_guides/grade4/unit9/lesson11.md', 92,
             "Which 3 go together? A. 0, 4, 8, 12, 16  B. 3, 6, 9, 12, 15  C. 5, 105, 205, 305, 405  D. 6, 60, 600, 6,000, 60,000")).

%   Grade 5
lesson_enactment_form('IM-G5-U1-L1', measure_and_order,
    evidence('curriculum/im_teacher_guides/grade5/unit1/lesson1.md', 276,
             "Take 9 connecting cubes. Build an object. Order the objects by volume. Discuss your reasoning with your group.")).
lesson_enactment_form('IM-G5-U1-L2', describe_and_reproduce,
    evidence('curriculum/im_teacher_guides/grade5/unit1/lesson2.md', 172,
             "Partner A: Use at least 10 unit cubes to build a prism. Describe it to your partner. Partner B: Build the prism your partner describes.")).
lesson_enactment_form('IM-G5-U1-L7', attribute_sort,
    evidence('curriculum/im_teacher_guides/grade5/unit1/lesson7.md', 167,
             "For each object, choose the cubic unit you would use to measure the volume: cubic centimeter, cubic inch, or cubic foot.")).
lesson_enactment_form('IM-G5-U1-L8', compose_from_parts,
    evidence('curriculum/im_teacher_guides/grade5/unit1/lesson8.md', 169,
             "Partner A: Build a rectangular prism with 12 cubes. Partner B: Build a rectangular prism with 10 cubes. Put your 2 prisms together.")).
lesson_enactment_form('IM-G5-U3-L2', partition_equal_parts,
    evidence('curriculum/im_teacher_guides/grade5/unit3/lesson2.md', 251,
             "Priya shaded part of a square. Write a multiplication expression to represent the area of the shaded piece.")).
lesson_enactment_form('IM-G5-U7-L1', describe_and_reproduce,
    evidence('curriculum/im_teacher_guides/grade5/unit7/lesson1.md', 183,
             "Round 1: Shapes not on a grid. Round 2: Shapes on a grid without numbers. Round 3: Shapes on a numbered grid. Earn 2 points if your shape exactly matches.")).
lesson_enactment_form('IM-G5-U7-L2', coordinate_locate,
    evidence('curriculum/im_teacher_guides/grade5/unit7/lesson2.md', 156,
             "Partner B: Plot the point on the blank coordinate grid. What are the coordinates of point R? Plot point T at (3,7).")).
lesson_enactment_form('IM-G5-U7-L3', coordinate_locate,
    evidence('curriculum/im_teacher_guides/grade5/unit7/lesson3.md', 147,
             "Estimate to plot and label the location of each point. What do the points have in common?")).
lesson_enactment_form('IM-G5-U7-L4', separating_attribute,
    evidence('curriculum/im_teacher_guides/grade5/unit7/lesson4.md', 159,
             "Partner B: Ask yes or no questions to determine which shape your partner chose. What question can Mai ask to determine which shape Han chose?")).
lesson_enactment_form('IM-G5-U7-L5', hierarchy_claim,
    evidence('curriculum/im_teacher_guides/grade5/unit7/lesson5.md', 126,
             "Definition 1: exactly 1 pair of opposite sides parallel. Definition 2: at least 1 pair. All parallelograms are trapezoids. No trapezoids are parallelograms.")).
lesson_enactment_form('IM-G5-U7-L6', construct_to_spec,
    evidence('curriculum/im_teacher_guides/grade5/unit7/lesson6.md', 258,
             "Draw a rhombus that is not a square. Draw a rhombus that is a square. Diego says that it is impossible to draw a square that is not a rhombus.")).
lesson_enactment_form('IM-G5-U7-L7', hierarchy_claim,
    evidence('curriculum/im_teacher_guides/grade5/unit7/lesson7.md', 157,
             "Find a rhombus that is also a square. Find a square that is not a rectangle. A rhombus is ____ a square. A trapezoid is ____ a parallelogram.")).
lesson_enactment_form('IM-G5-U7-L8', attribute_sort,
    evidence('curriculum/im_teacher_guides/grade5/unit7/lesson8.md', 153,
             "Find a card that fits the description for each space in the chart. If you do not think it is possible to find a triangle that fits a space's descriptions, explain why not.")).
lesson_enactment_form('IM-G5-U7-L14', coordinate_locate,
    evidence('curriculum/im_teacher_guides/grade5/unit7/lesson14.md', 152,
             "Create a coordinate grid on your chosen figure. Decide which points you'll use to copy the figure and give the coordinates for each point.")).
lesson_enactment_form('IM-G5-U8-L6', derive_unknown_measure,
    evidence('curriculum/im_teacher_guides/grade5/unit8/lesson6.md', 155,
             "A company packages 126 sugar cubes in each box. The box is a rectangular prism. What are some possible ways to pack the cubes?")).
lesson_enactment_form('IM-G5-U8-L9', derive_unknown_measure,
    evidence('curriculum/im_teacher_guides/grade5/unit8/lesson9.md', 165,
             "Each month an average of 5 cm of rain falls on the house. There are 1,000 cubic cm in 1 liter. How many liters fall on the house each month?")).
lesson_enactment_form('IM-G5-U8-L18', separating_attribute,
    evidence('curriculum/im_teacher_guides/grade5/unit8/lesson18.md', 169,
             "Choose 3 shapes from the set of cards. Draw a fourth shape to complete the Which Three Go Together. For each group of 3 shapes, discuss one reason.")).

% =============================================================================
% 4. Inputs, with provenance
% =============================================================================

%!  lesson_inputs(?Lesson, ?Provenance, ?Inputs) is nondet.
%
%   The form comes first inside the input term, so `enact/3` reads which form to
%   run off its own arguments rather than off a lookup. A lesson that exhibits
%   two forms yields one row per form, and `enact/3` is nondet over them.
lesson_inputs(Lesson, Provenance, inputs(Form, Term)) :-
    lesson_input_term(Lesson, Provenance, Term),
    lesson_enactment_form(Lesson, Form, _).

%!  lesson_input_term(?Lesson, ?Provenance, ?Term) is nondet.
%
%   `curriculum` means every number and category below is printed in the guide
%   span cited above. `machine_supplied` means the guide names a card set, a
%   handout or a manipulative it does not print, and this module supplies a
%   figure set of its own so the structure can still run. The distinction is
%   carried onto every emitted record and into the verdict; the two are never
%   added together.

%   -- Kindergarten
lesson_input_term('IM-GK-U3-L2', machine_supplied,
    sort_task(all_shapes,
              [cat('triangle', sides(3)), cat('quadrilateral', sides(4)),
               cat('pentagon', sides(5)), cat('hexagon', sides(6))])).
lesson_input_term('IM-GK-U3-L8', curriculum,
    description_task(printed_description([sides(3)]), all_shapes)).
lesson_input_term('IM-GK-U3-L12', machine_supplied,
    assembly(pattern_blocks(6))).
lesson_input_term('IM-GK-U3-L15', machine_supplied,
    assembly(pattern_blocks(4))).

%   -- Grade 1
lesson_input_term('IM-G1-U1-L8', machine_supplied,
    sort_task(all_shapes,
              [cat('3 sides', sides(3)), cat('4 sides', sides(4)),
               cat('more than 4 sides', sides_more_than(4))])).
lesson_input_term('IM-G1-U7-L3', machine_supplied,
    sort_task(all_shapes,
              [cat('has a square corner', at_least(right_angles, 1)),
               cat('no square corner', exactly(right_angles, 0))])).
lesson_input_term('IM-G1-U7-L4', machine_supplied,
    description_task(figure(sq_4), all_shapes)).
lesson_input_term('IM-G1-U7-L9', curriculum,
    partition_task([whole(circle, 2, 1), whole(square, 2, 1),
                    whole(circle, 4, 1), whole(square, 4, 1)])).
lesson_input_term('IM-G1-U7-L10', curriculum,
    shaded_sort_task([whole(square, 2, 1), whole(square, 4, 1),
                      whole(square, 4, 4), whole(rectangle, 3, 1),
                      whole(circle, 2, 1)])).
lesson_input_term('IM-G1-U7-L18', curriculum,
    partition_task([whole(park, 4, 1), whole(pool, 4, 1),
                    whole(court, 2, 1), whole(pond, 2, 1),
                    whole(playground, 4, 1)])).

%   -- Grade 2
lesson_input_term('IM-G2-U6-L1', curriculum,
    sort_task(all_shapes,
              [cat('triangle', sides(3)), cat('quadrilateral', sides(4)),
               cat('pentagon', sides(5)), cat('hexagon', sides(6))])).
lesson_input_term('IM-G2-U6-L2', curriculum,
    construct_task([target('a quadrilateral', [sides(4)]),
                    target('a different 4-sided shape', [sides(4), exactly(right_angles, 0)]),
                    target('a pentagon', [sides(5)]),
                    target('a hexagon', [sides(6)])])).
lesson_input_term('IM-G2-U6-L3', curriculum,
    construct_task([target('fewer than 5 sides, two sides 3 units long',
                           [sides_fewer_than(5), side_length_count(3, 2)]),
                    target('4 sides, each side 2 units long',
                           [sides(4), side_length_count(2, 4)]),
                    target('more than 4 sides, only 1 side 2 units long',
                           [sides_more_than(4), side_length_count(2, 1)])])).
lesson_input_term('IM-G2-U6-L4', curriculum,
    assembly(cube_nets)).
lesson_input_term('IM-G2-U6-L6', curriculum,
    assembly(same_block_compositions([2, 3, 4]))).
lesson_input_term('IM-G2-U6-L7', curriculum,
    partition_task([whole(rectangle, 2, 1), whole(rectangle, 4, 1),
                    whole(rectangle, 3, 1), whole(circle, 3, 1)])).
lesson_input_term('IM-G2-U8-L11', curriculum,
    cover_task(tile_counts([12, 15, 16, 18, 20]))).

%   -- Grade 3
lesson_input_term('IM-G3-U2-L1', machine_supplied,
    order_task(figures_by(area, [tri_right_iso, tri_acute_scal, rect_6x3, sq_4]), rank)).
lesson_input_term('IM-G3-U2-L2', machine_supplied,
    cover_task(regions([region('A', 3, 2), region('B', 4, 2), region('C', 5, 3)]))).
lesson_input_term('IM-G3-U2-L3', curriculum,
    cover_task(claimed_area(23))).
lesson_input_term('IM-G3-U2-L8', machine_supplied,
    cover_task(regions([region('tile artwork', 6, 4), region('meter rectangle', 5, 3)]))).
lesson_input_term('IM-G3-U2-L4', machine_supplied,
    description_task(figure(rect_6x3), rectangles_to(8))).
lesson_input_term('IM-G3-U2-L9', curriculum,
    construct_task([target('Area A: 4 square feet', [sides(4), area(4)]),
                    target('Area B: 6 square feet', [sides(4), area(6)]),
                    target('Area C: 9 square feet', [sides(4), area(9)]),
                    target('Area D: 10 square feet', [sides(4), area(10)]),
                    target('Area E: 12 square feet', [sides(4), area(12)]),
                    target('Area F: 16 square feet', [sides(4), area(16)])])).
lesson_input_term('IM-G3-U2-L14', curriculum,
    measure_task(rectilinear_run([4, 4], [unknown(side)], 8))).
lesson_input_term('IM-G3-U2-L15', machine_supplied,
    measure_task(clear_floor(area(10, 12), [furniture(bed, 6, 4), furniture(desk, 4, 2)]))).
lesson_input_term('IM-G3-U4-L11', machine_supplied,
    cover_task(decompose(18, 5))).
lesson_input_term('IM-G3-U4-L15', curriculum,
    cover_task(regions([region('mural', 17, 4), region('mosaic', 12, 8),
                        region('patio', 6, 14), region('stickers', 5, 16)]))).
lesson_input_term('IM-G3-U5-L10', machine_supplied,
    shaded_sort_task([whole(square, 2, 1), whole(square, 4, 2),
                      whole(rectangle, 6, 3), whole(square, 4, 1),
                      whole(rectangle, 8, 4)])).
lesson_input_term('IM-G3-U6-L7', machine_supplied,
    order_task(objects([obj('Container A', 6), obj('Container B', 9)]),
               estimate_band(9, band(4, 9, 15)))).
lesson_input_term('IM-G3-U7-L4', curriculum,
    sort_task(all_shapes,
              [cat('right triangle', [sides(3), at_least(right_angles, 1)]),
               cat('rectangle', [sides(4), exactly(right_angles, 4)]),
               cat('rhombus', [sides(4), all_sides_equal])])).
lesson_input_term('IM-G3-U7-L6', machine_supplied,
    order_task(figures_by(perimeter, [sq_4, rect_6x3, tri_right_iso, rect_5x2]), rank)).
lesson_input_term('IM-G3-U7-L15', curriculum,
    measure_task(chicken_yard(coop_area(24), per_chicken(8, 10),
                              max_chickens(10), fencing(30)))).
lesson_input_term('IM-G3-U8-L4', curriculum,
    measure_task(tiny_houses([house('shipping container', 8, 20),
                              house('cabin', 8, 10)]))).

%   -- Grade 4
lesson_input_term('IM-G4-U1-L1', curriculum,
    construct_task([target('width 3, area 30 square units or less',
                           [sides(4), exactly(right_angles, 4), width_area(3, 30)]),
                    target('width 3, area exactly 28 square units',
                           [sides(4), exactly(right_angles, 4), width_area_exact(3, 28)])])).
lesson_input_term('IM-G4-U1-L8', machine_supplied,
    number_sort_task([1, 2, 3, 4, 6, 12, 5, 7, 10, 15, 20, 25],
                     [cat('all the factors of 12', factor_of(12)),
                      cat('a multiple of 5', multiple_of(5)),
                      cat('prime', prime),
                      cat('composite', composite)])).
lesson_input_term('IM-G4-U4-L17', curriculum,
    order_task(objects([obj('WN11', 35625), obj('SK51', 28999), obj('VT35', 15450),
                        obj('BQ64', 36000), obj('AL16', 31000), obj('AB25', 35175),
                        obj('CL48', 16600), obj('WN90', 30775), obj('NM44', 30245)]),
               within(1000))).
lesson_input_term('IM-G4-U6-L2', curriculum,
    assembly(repeating_unit([circle, square], [12, 25]))).
lesson_input_term('IM-G4-U6-L23', curriculum,
    measure_task(banner(poster(36, 24), banner(8, 96)))).
lesson_input_term('IM-G4-U7-L1', machine_supplied,
    description_task(figure(pent_1), all_shapes)).
lesson_input_term('IM-G4-U7-L3', machine_supplied,
    construct_task([target('a quadrilateral from four lines on a dot field', [sides(4)]),
                    target('a rectangle from four lines on a dot field',
                           [sides(4), exactly(right_angles, 4)])])).
lesson_input_term('IM-G4-U7-L4', curriculum,
    letter_sort_task("WHALEJOY",
                     [cat('no parallel segments', exactly(parallel_pairs, 0)),
                      cat('has parallel segments', at_least(parallel_pairs, 1)),
                      cat('has perpendicular segments', at_least(perpendicular_pairs, 1))])).
lesson_input_term('IM-G4-U7-L5', machine_supplied,
    description_task(figure(tri_right_scal), all_shapes)).
lesson_input_term('IM-G4-U7-L6', machine_supplied,
    order_task(objects([obj('A', 15), obj('B', 30), obj('C', 45), obj('D', 60),
                        obj('E', 75), obj('F', 90), obj('G', 105), obj('H', 120),
                        obj('I', 135), obj('J', 150), obj('K', 165), obj('L', 175),
                        obj('M', 20), obj('N', 100), obj('O', 55), obj('P', 145)]),
               rank)).
lesson_input_term('IM-G4-U7-L7', curriculum,
    angle_task(clock_times(['12:00', '3:00', '5:00', '1:15', '1:20', '2:50', '11:20', '8:58', '9:35']))).
lesson_input_term('IM-G4-U7-L8', curriculum,
    angle_task(turn_fractions(360, [2, 4, 8]))).
lesson_input_term('IM-G4-U7-L11', machine_supplied,
    construct_task([target('an angle less than 90 degrees', [angle_between(1, 89)]),
                    target('an angle between 90 and 180 degrees', [angle_between(91, 179)]),
                    target('an angle greater than 180 but less than 270', [angle_between(181, 269)]),
                    target('an angle greater than 270 but less than 360', [angle_between(271, 359)])])).
lesson_input_term('IM-G4-U7-L13', curriculum,
    angle_task(copies_fill([copies('Angle P', 3, 180), copies('Angle Q', 3, 90)],
                           [sum(['Angle P', 'Angle Q'])]))).
lesson_input_term('IM-G4-U7-L14', curriculum,
    angle_task(clock_times(['6:00', '8:00', '9:00', '11:00', '12:00']))).
lesson_input_term('IM-G4-U7-L15', machine_supplied,
    angle_task(fill_straight([complement(35), complement(140), complement(90)]))).
lesson_input_term('IM-G4-U7-L16', machine_supplied,
    angle_task(step_slope([30, 45, 60], 1))).
lesson_input_term('IM-G4-U8-L3', curriculum,
    sort_task(quadrilaterals,
              [cat('no right angles', exactly(right_angles, 0)),
               cat('only 1 pair of parallel sides', exactly(parallel_pairs, 1)),
               cat('only 1 pair of perpendicular sides', exactly(perpendicular_pairs, 1)),
               cat('same length for all sides', all_sides_equal),
               cat('same size for all angles', all_angles_equal),
               cat('same length for only 2 sides', exactly(equal_side_pairs, 1)),
               cat('no parallel sides', exactly(parallel_pairs, 0)),
               cat('2 obtuse angles', exactly(obtuse_angles, 2))])).
lesson_input_term('IM-G4-U8-L6', curriculum,
    construct_task([target('a triangle with only 1 line of symmetry',
                           [sides(3), exactly(lines_of_symmetry, 1)]),
                    target('a quadrilateral with only 1 line of symmetry',
                           [sides(4), exactly(lines_of_symmetry, 1)]),
                    target('a quadrilateral with 2 pairs of parallel sides',
                           [sides(4), exactly(parallel_pairs, 2)]),
                    target('a quadrilateral with 1 pair of perpendicular sides',
                           [sides(4), exactly(perpendicular_pairs, 1)]),
                    target('a rectangle', [sides(4), exactly(right_angles, 4)]),
                    target('a 6-sided figure with only 1 line of symmetry',
                           [sides(6), exactly(lines_of_symmetry, 1)])])).
lesson_input_term('IM-G4-U8-L7', curriculum,
    measure_task(perimeter_determinacy(
        [shape('A', [parallel_pairs(0), lines_of_symmetry(0)], 2),
         shape('B', [parallel_pairs(1), lines_of_symmetry(0)], 2),
         shape('C', [parallel_pairs(2), lines_of_symmetry(0)], 2),
         shape('D', [parallel_pairs(1), lines_of_symmetry(1)], 2)]))).
lesson_input_term('IM-G4-U8-L10', machine_supplied,
    angle_task(unfold_symmetry([50, 90, 40]))).
lesson_input_term('IM-G4-U9-L11', curriculum,
    separate_task(numbers([set('A', [0, 4, 8, 12, 16]), set('B', [3, 6, 9, 12, 15]),
                           set('C', [5, 105, 205, 305, 405]), set('D', [6, 60, 600, 6000, 60000])]),
                  three_go_together)).

%   -- Grade 5
lesson_input_term('IM-G5-U1-L1', curriculum,
    order_task(cube_objects(9), rank)).
lesson_input_term('IM-G5-U1-L2', curriculum,
    description_task(prism_from_cubes(10), prisms_to(12))).
lesson_input_term('IM-G5-U1-L7', machine_supplied,
    magnitude_sort_task([obj('a moving truck', 1000000), obj('a freezer', 500000),
                         obj('a juice box', 200), obj('a classroom', 200000000),
                         obj('a dumpster', 3000000), obj('a lunch box', 5000)],
                        [cat('cubic centimeter', below(10000)),
                         cat('cubic inch', between_units(10000, 1000000)),
                         cat('cubic foot', above(1000000))])).
lesson_input_term('IM-G5-U1-L8', curriculum,
    assembly(cube_join(12, 10))).
lesson_input_term('IM-G5-U3-L2', machine_supplied,
    partition_task([whole(square, 2, 1), whole(square, 6, 1), whole(square, 12, 1)])).
lesson_input_term('IM-G5-U7-L1', curriculum,
    grid_rounds_task(figure(rect_6x3), [round(1, no_grid), round(2, unnumbered_grid),
                                        round(3, numbered_grid)])).
lesson_input_term('IM-G5-U7-L2', curriculum,
    coordinate_task([plot('T', 3-7)], [read('R', 2-5)])).
lesson_input_term('IM-G5-U7-L3', machine_supplied,
    coordinate_task([plot('A', 1-4), plot('B', 3-4), plot('C', 6-4)], [common_attribute])).
lesson_input_term('IM-G5-U7-L4', machine_supplied,
    separate_task(figures(quadrilaterals), which_one)).
lesson_input_term('IM-G5-U7-L5', curriculum,
    claim_task([definition(1, exactly_one_parallel_pair),
                definition(2, at_least_one_parallel_pair)],
               [claim('All parallelograms are trapezoids', all, parallelogram, trapezoid),
                claim('No parallelograms are trapezoids', none, parallelogram, trapezoid),
                claim('All trapezoids are parallelograms', all, trapezoid, parallelogram),
                claim('Some trapezoids are parallelograms', some, trapezoid, parallelogram),
                claim('No trapezoids are parallelograms', none, trapezoid, parallelogram)])).
lesson_input_term('IM-G5-U7-L6', curriculum,
    construct_task([target('a square', [class(square)]),
                    target('a rhombus that is not a square',
                           [class(rhombus), not(class(square))]),
                    target('a rhombus that is a square',
                           [class(rhombus), class(square)]),
                    target('a square that is not a rhombus',
                           [class(square), not(class(rhombus))])])).
lesson_input_term('IM-G5-U7-L7', curriculum,
    claim_task([definition(2, at_least_one_parallel_pair)],
               [claim('A rhombus is ___ a square', quantifier, rhombus, square),
                claim('A square is ___ a rhombus', quantifier, square, rhombus),
                claim('A triangle is ___ a quadrilateral', quantifier, triangle, quadrilateral_class),
                claim('A square is ___ a rectangle', quantifier, square, rectangle),
                claim('A rectangle is ___ a parallelogram', quantifier, rectangle, parallelogram),
                claim('A parallelogram is ___ a rhombus', quantifier, parallelogram, rhombus),
                claim('A trapezoid is ___ a parallelogram', quantifier, trapezoid, parallelogram)])).
lesson_input_term('IM-G5-U7-L8', curriculum,
    chart_task(triangles,
               [row('Has a 90-degree angle', at_least(right_angles, 1)),
                row('Has an angle greater than 90 degrees', at_least(obtuse_angles, 1)),
                row('All 3 angles are less than 90 degrees',
                    [exactly(right_angles, 0), exactly(obtuse_angles, 0)])],
               [col('All 3 side lengths are equal', all_sides_equal),
                col('Exactly 2 of the side lengths are equal', exactly(equal_side_pairs, 1)),
                col('All 3 side lengths are different', exactly(equal_side_pairs, 0))])).
lesson_input_term('IM-G5-U7-L14', machine_supplied,
    coordinate_task([plot('P1', 0-0), plot('P2', 4-0), plot('P3', 4-3), plot('P4', 0-3)],
                    [name_figure])).
lesson_input_term('IM-G5-U8-L6', curriculum,
    measure_task(packing(126))).
lesson_input_term('IM-G5-U8-L9', curriculum,
    measure_task(rainfall(area(1000), depth(5), litre(1000)))).
lesson_input_term('IM-G5-U8-L18', machine_supplied,
    separate_task(figures([sq_4, rect_6x3, rhombus_5, trapezoid_iso]), three_go_together)).

% =============================================================================
% 5. What each row does not claim
% =============================================================================

%!  lesson_caveat(?Lesson, ?Sentence) is nondet.
%
%   One sentence per row, always present, carried onto the emitted record. The
%   directive moved honesty out of the refusal and into the verdict; this is
%   where it sits.
lesson_caveat(Lesson, Sentence) :-
    lesson_specific_caveat(Lesson, Sentence), !.
lesson_caveat(Lesson, Sentence) :-
    lesson_enactment_form(Lesson, Form, _),
    form_default_caveat(Form, Sentence).

form_default_caveat(attribute_sort,
    'It sorted a figure set by computed attributes; it did not watch a child pick up a card and decide where it goes.').
form_default_caveat(construct_to_spec,
    'It found figures inside a bounded search space; a search that finds nothing has exhausted that space, which is not the same as proving the figure impossible.').
form_default_caveat(cover_and_count,
    'It counted a covering it laid out itself; it did not watch anyone place tiles or notice a gap between them.').
form_default_caveat(partition_equal_parts,
    'It divided a whole into equal shares and named them; it did not fold paper, and it did not judge whether a hand-made fold is equal enough.').
form_default_caveat(compose_from_parts,
    'It enumerated assemblies that fit exactly by area; it did not watch a child fit the pieces, and identical area does not settle whether two arrangements read as the same way.').
form_default_caveat(measure_and_order,
    'It ordered objects by measures it was given or computed; it did not measure a physical object or judge an estimate a student actually made.').
form_default_caveat(angle_composition,
    'It did the additive angle arithmetic; it did not draw with a protractor or judge the precision of a drawn angle.').
form_default_caveat(describe_and_reproduce,
    'It generated a description and counted the figures that description still allows; it did not hear one partner speak or watch the other draw.').
form_default_caveat(separating_attribute,
    'It searched a stated attribute vocabulary for a split; a question outside that vocabulary might separate the set where this one reports it cannot.').
form_default_caveat(hierarchy_claim,
    'It adjudicated each claim over the figures in its inventory; a claim true of every figure held here is not thereby a theorem about every figure.').
form_default_caveat(coordinate_locate,
    'It placed and read integer lattice points; it did not judge a hand-plotted point or an estimate between grid lines.').
form_default_caveat(derive_unknown_measure,
    'It derived what the labelled measures force and named what they leave open; it did not measure the figure or supply a length the guide withheld.').

lesson_specific_caveat('IM-G2-U6-L4',
    'It rolled a cube over each six-square arrangement and found the eleven that fold; it did not cut or fold paper, and a net that folds in the arithmetic can still be cut wrong.').
lesson_specific_caveat('IM-G3-U5-L10',
    'The fraction this task shades is a filled outline in the source PDF and the markdown extraction drops it, so the machine sorted shaded figures it generated rather than the six the lesson prints.').
lesson_specific_caveat('IM-G5-U3-L2',
    'Both fractions in this task are filled outlines the markdown extraction drops, so the partitions here are supplied and the shaded amounts are the machine own.').
lesson_specific_caveat('IM-G4-U7-L8',
    'The degree values in this task are filled outlines the markdown extraction drops; the full turn of 360 degrees is printed and is what the halving chain starts from.').
lesson_specific_caveat('IM-G4-U7-L4',
    'The letters are printed in the lesson and the strokes are this module drawing of them; O, S, U and J are round in most typefaces, so those answers hold for this skeleton and not for every printing of the letter.').
lesson_specific_caveat('IM-G5-U1-L7',
    'The sort ran against typical volumes this module states for each object; those magnitudes are supplied, not derived, and a different classroom could reasonably sort a lunch box the other way.').
lesson_specific_caveat('IM-GK-U3-L15',
    'There is no target in this task: the animal is the child choice, so the machine enumerated what a small stamp set can compose rather than making the animal.').
lesson_specific_caveat('IM-G5-U7-L8',
    'Three cells of this chart stay empty here because the integer lattice carries no equilateral triangle, which is a fact about this representation as well as about the geometry the lesson asks students to explain.').

% =============================================================================
% 6. enact/3
% =============================================================================

%!  enact(+Lesson, +Inputs, -Enactment) is nondet.
%
%   Run the form named inside Inputs over the term beside it. Fails rather than
%   guessing when the term does not support the form, which is what makes the
%   pairing in `lesson_inputs/3` safe for a lesson that exhibits two forms.
enact(Lesson, inputs(Form, Term), enactment(Lesson, Form, Term, Steps, Artifact)) :-
    run_form(Form, Term, Steps, Artifact).

%!  enactment_verdict(+Enactment, -Verdict) is det.
%
%   well_formed when the guide printed the inputs and every move returned a
%   result. partial when the machine supplied a figure set, a magnitude or a
%   value the extraction dropped. refused when a move returned nothing to act
%   on.
enactment_verdict(enactment(Lesson, _Form, _Inputs, Steps, _Artifact), Verdict) :-
    (   Steps == []
    ->  Verdict = refused('no move returned a result on these inputs')
    ;   member(step(_, _, _, refused(Reason)), Steps)
    ->  Verdict = refused(Reason)
    ;   lesson_input_term(Lesson, machine_supplied, _)
    ->  supply_reason(Lesson, Reason),
        Verdict = partial(Reason)
    ;   member(step(_, _, _, summary(_, _, exhausted(NExh))), Steps), NExh > 0
    ->  format(atom(R), "~w of the constructions exhausted the bounded search space without a witness", [NExh]),
        Verdict = partial(R)
    ;   Verdict = well_formed
    ).

%!  supply_reason(+Lesson, -Reason) is det.
%
%   What the machine had to supply, named per lesson rather than in one phrase
%   for all of them. A card set the guide never prints and a magnitude the guide
%   never states are different gaps, and reporting both as "inputs supplied"
%   would hide the second behind the first.
supply_reason(Lesson, Reason) :- lesson_supply_reason(Lesson, Reason), !.
supply_reason(_, 'inputs supplied by the machine; the guide names a card set, handout or manipulative it does not print').

lesson_supply_reason('IM-G5-U1-L7',
    'the sort ran against typical object volumes this module states, which the guide does not print and does not derive').
lesson_supply_reason('IM-G5-U3-L2',
    'both fraction values in this task are filled outlines the markdown extraction drops, so the partitions here are the machine own').
lesson_supply_reason('IM-G3-U5-L10',
    'the target fraction is a filled outline the markdown extraction drops, so the shaded figures here are the machine own').
lesson_supply_reason('IM-G4-U7-L15',
    'the angle values sit in the lesson figure, which the markdown carries as an image, so the parts here are the machine own').
lesson_supply_reason('IM-G4-U7-L16',
    'the street angles sit in the lesson figures, so the slopes here are the machine own').
lesson_supply_reason('IM-G4-U7-L11',
    'the degree bounds on the four cards are filled outlines the markdown extraction drops, so the bands here are the machine own').
lesson_supply_reason('IM-G4-U8-L10',
    'the labelled angles sit in the origami diagram, so the folded angles here are the machine own').
lesson_supply_reason('IM-G4-U7-L6',
    'Cards A to P come from an earlier lesson and carry no printed measures, so the sixteen angles here are the machine own').
lesson_supply_reason('IM-G3-U2-L15',
    'the room, bed and desk dimensions sit in the lesson diagram, so the measures here are the machine own').
lesson_supply_reason('IM-G3-U2-L8',
    'the rectangle side lengths sit in the lesson figure, so the regions here are the machine own').
lesson_supply_reason('IM-G3-U4-L11',
    'the three ungridded rectangles carry no printed dimensions, so the region here is the machine own').

% =============================================================================
% 7. The runners
% =============================================================================

step(I, Verb, Operand, Result, step(I, Verb, Operand, Result)).

% ---- attribute_sort ---------------------------------------------------------

run_form(attribute_sort, sort_task(PoolName, Categories), Steps, printed(Record)) :-
    figure_pool(PoolName, Pool),
    length(Categories, NC),
    findall(Label, member(cat(Label, _), Categories), Labels),
    findall(Id-Placed,
            ( member(Id, Pool),
              canonical_figure(Id, _, Vs),
              findall(L, ( member(cat(L, Cond), Categories), holds_all(Vs, Cond) ), Placed) ),
            Placements),
    findall(Id, member(Id-[], Placements), Unplaced),
    findall(Id, ( member(Id-Ls, Placements), length(Ls, N), N > 1 ), Multiple),
    length(Pool, NP),
    Steps = [ step(1, read_categories, Labels, NC),
              step(2, compute_attributes, Pool, NP),
              step(3, place_each_figure, Placements, placed),
              step(4, report_residue, fits_none(Unplaced), fits_more_than_one(Multiple)) ],
    Record = sorted(Placements, Unplaced, Multiple).

run_form(attribute_sort, number_sort_task(Numbers, Categories), Steps, printed(Record)) :-
    findall(N-Placed,
            ( member(N, Numbers),
              findall(L, ( member(cat(L, Cond), Categories), number_holds(N, Cond) ), Placed) ),
            Placements),
    findall(N, member(N-[], Placements), Unplaced),
    findall(Label, member(cat(Label, _), Categories), Labels),
    length(Numbers, NN),
    Steps = [ step(1, read_categories, Labels, ok),
              step(2, compute_attributes, Numbers, NN),
              step(3, place_each_figure, Placements, placed),
              step(4, report_residue, fits_none(Unplaced), counted) ],
    Record = sorted(Placements, Unplaced, []).

run_form(attribute_sort, letter_sort_task(Word, Categories), Steps, printed(Record)) :-
    string_chars(Word, Chars),
    sort(Chars, Letters),
    findall(L-Placed,
            ( member(L, Letters), letterform(L, Segments),
              findall(Lab, ( member(cat(Lab, Cond), Categories),
                             segments_hold(Segments, Cond) ), Placed) ),
            Placements),
    findall(L, member(L-[], Placements), Unplaced),
    letterform_note(Note),
    length(Letters, NL),
    Steps = [ step(1, read_categories, Word, NL),
              step(2, compute_attributes, Letters, segments_measured),
              step(3, place_each_figure, Placements, placed),
              step(4, report_residue, fits_none(Unplaced), Note) ],
    Record = sorted(Placements, Unplaced, []).

run_form(attribute_sort, magnitude_sort_task(Objects, Categories), Steps, printed(Record)) :-
    findall(Label-Unit,
            ( member(obj(Label, Size), Objects),
              once(( member(cat(Unit, Cond), Categories), magnitude_holds(Size, Cond) )) ),
            Placements),
    length(Objects, NO),
    findall(U, member(cat(U, _), Categories), Units),
    Steps = [ step(1, read_categories, Units, ok),
              step(2, compute_attributes, Objects, NO),
              step(3, place_each_figure, Placements, placed),
              step(4, report_residue, fits_none([]), magnitudes_are_supplied) ],
    Record = sorted(Placements, [], []).

run_form(attribute_sort, chart_task(PoolName, Rows, Cols), Steps, printed(Record)) :-
    figure_pool(PoolName, Pool),
    findall(cell(RLabel, CLabel, Fits),
            ( member(row(RLabel, RCond), Rows),
              member(col(CLabel, CCond), Cols),
              findall(Id, ( member(Id, Pool), canonical_figure(Id, _, Vs),
                            holds_all(Vs, RCond), holds_all(Vs, CCond) ), Fits) ),
            Cells),
    findall(RLabel/CLabel, member(cell(RLabel, CLabel, []), Cells), Empty),
    empty_cell_reasons(Empty, Reasons),
    length(Cells, NCells),
    Steps = [ step(1, read_categories, chart(Rows, Cols), NCells),
              step(2, compute_attributes, Pool, measured),
              step(3, place_each_figure, Cells, filled),
              step(4, report_residue, empty_cells(Empty), Reasons) ],
    Record = chart(Cells, Empty, Reasons).

run_form(attribute_sort, shaded_sort_task(Wholes), Steps, Artifact) :-
    findall(shaded(Label, N, S, Fraction),
            ( member(whole(Label, N, S), Wholes), N > 0, reduce(S, N, Fraction) ),
            Shaded),
    shaded_categories(Categories),
    findall(Label-Placed,
            ( member(shaded(Label, N, S, Fraction), Shaded),
              findall(Cat,
                      ( member(cat(Cat, Test), Categories),
                        shaded_holds(N, S, Fraction, Test) ),
                      Placed) ),
            Placements),
    findall(L, member(L-[], Placements), Unplaced),
    findall(Lab, member(cat(Lab, _), Categories), Labels),
    length(Wholes, NW),
    Wholes = [whole(_, N0, S0) | _],
    Artifact = scene(measurement_strip_scene, measure(S0, N0, 'equal parts')),
    Steps = [ step(1, read_categories, Labels, ok),
              step(2, compute_attributes, Shaded, NW),
              step(3, place_each_figure, Placements, placed),
              step(4, report_residue, fits_none(Unplaced), counted) ].

shaded_categories([ cat('a half is shaded', half),
                    cat('a fourth or a quarter is shaded', fourth),
                    cat('the whole shape is shaded', whole),
                    cat('the pieces are not equal', unequal) ]).

shaded_holds(_, _, 1/2, half).
shaded_holds(_, _, 1/4, fourth).
shaded_holds(_, _, 1/1, whole).
shaded_holds(N, S, _, unequal) :- S > N.

% ---- construct_to_spec ------------------------------------------------------

run_form(construct_to_spec, construct_task(Targets), Steps, Artifact) :-
    findall(result(Label, Outcome),
            ( member(target(Label, Conditions), Targets),
              construct_outcome(Conditions, Outcome) ),
            Results),
    search_space_size(Size),
    length(Targets, NT),
    findall(1, member(result(_, found(_, _)), Results), Fs), length(Fs, NFound),
    findall(1, member(result(_, impossible(_)), Results), Is), length(Is, NImp),
    findall(1, ( member(result(_, O), Results), exhausted_outcome(O) ), Es), length(Es, NExh),
    construct_artifact(Results, Artifact),
    Steps = [ step(1, read_constraints, Targets, NT),
              step(2, search_figure_space, bounded_family, Size),
              step(3, verify_witness, Results, verified),
              step(4, report_found_or_exhausted, Results,
                    summary(found(NFound), impossible(NImp), exhausted(NExh))) ].

exhausted_outcome(exhausted(_)).
exhausted_outcome(exhausted_with_containment(_)).

construct_artifact(Results, scene(geoboard_scene, stretch_polygon(Vs))) :-
    member(result(_, found(_, Vs)), Results), is_list(Vs), !.
construct_artifact(Results, scene(angle_circular_scene, angle(D))) :-
    member(result(_, found(_, angle(D))), Results), !.
construct_artifact(Results, printed(constructions(Results))).

% ---- cover_and_count --------------------------------------------------------

run_form(cover_and_count, cover_task(regions(Regions)), Steps, Artifact) :-
    findall(covered(Label, C, R, Count, Eq1, Eq2),
            ( member(region(Label, C, R), Regions),
              Count is C * R,
              format(atom(Eq1), "~w rows of ~w = ~w", [R, C, Count]),
              format(atom(Eq2), "~w columns of ~w = ~w", [C, R, Count]) ),
            Covers),
    Regions = [region(_, C0, R0) | _],
    length(Regions, NR),
    Artifact = scene(polyform_tiling_scene, tile_area(cols(C0), rows(R0))),
    Steps = [ step(1, choose_unit, unit_square, 1),
              step(2, lay_unit_over_region, Regions, NR),
              step(3, count_covering, Covers, counted),
              step(4, write_array_equations, Covers, two_per_region) ].

run_form(cover_and_count, cover_task(tile_counts(Counts)), Steps, Artifact) :-
    findall(arrays(N, Pairs),
            ( member(N, Counts), rectangles_with_area(N, Pairs) ),
            Arrays),
    Counts = [First | _],
    rectangles_with_area(First, [W-H | _]),
    Artifact = scene(polyform_tiling_scene, tile_area(cols(W), rows(H))),
    length(Counts, NC),
    Steps = [ step(1, choose_unit, unit_tile, 1),
              step(2, lay_unit_over_region, Counts, NC),
              step(3, count_covering, Arrays, enumerated),
              step(4, write_array_equations, Arrays, two_per_array) ].

run_form(cover_and_count, cover_task(claimed_area(Claim)), Steps, printed(Record)) :-
    rectangles_with_area(Claim, Pairs),
    length(Pairs, NP),
    ( NP =:= 1 -> Reading = 'only one rectangle has this area, so the claim fixes the rectangle'
    ; Reading = 'more than one rectangle has this area, so the count does not fix the rectangle' ),
    Steps = [ step(1, choose_unit, unit_tile, 1),
              step(2, lay_unit_over_region, Claim, tiles_counted),
              step(3, count_covering, Pairs, NP),
              step(4, write_array_equations, Reading, adjudicated) ],
    Record = claim_check(Claim, Pairs, Reading).

run_form(cover_and_count, cover_task(decompose(W, H)), Steps, Artifact) :-
    Total is W * H,
    findall(split(A, B, ExprA, ExprB),
            ( between(1, W, A), A < W, B is W - A,
              ExprA is A * H, ExprB is B * H ),
            Splits),
    length(Splits, NS),
    Artifact = scene(polyform_tiling_scene, tile_area(cols(W), rows(H))),
    Steps = [ step(1, choose_unit, unit_square, 1),
              step(2, lay_unit_over_region, region(W, H), Total),
              step(3, count_covering, Splits, NS),
              step(4, write_array_equations, distributive(W, H, Total), Total) ].

% ---- partition_equal_parts --------------------------------------------------

run_form(partition_equal_parts, partition_task(Wholes), Steps, Artifact) :-
    findall(part(Label, N, Shaded, PartName, Fraction),
            ( member(whole(Label, N, Shaded), Wholes),
              N > 0,
              part_name(N, PartName),
              reduce(Shaded, N, Fraction) ),
            Parts),
    Wholes = [whole(_, N0, S0) | _],
    Artifact = scene(measurement_strip_scene, measure(S0, N0, 'equal parts')),
    length(Wholes, NW),
    findall(check(Label, equal_shares(N)),
            member(whole(Label, N, _), Wholes),
            Checks),
    Steps = [ step(1, split_whole, Wholes, NW),
              step(2, check_parts_equal, Checks, all_equal),
              step(3, name_the_part, Parts, named),
              step(4, read_shaded_fraction, Parts, read) ].

% ---- compose_from_parts -----------------------------------------------------

run_form(compose_from_parts, assembly(pattern_blocks(Target)), Steps, printed(Record)) :-
    findall(Units, pattern_block(_, Units, _), Sizes0),
    sort(Sizes0, Sizes),
    findall(Way, block_partition(Target, Sizes, Way), Ways),
    length(Ways, NWays),
    pattern_block_note(Note),
    Steps = [ step(1, read_target, hexagon_units(Target), Target),
              step(2, enumerate_candidates, Sizes, NWays),
              step(3, check_exact_fit, Ways, exact_by_area),
              step(4, count_distinct_ways, NWays, Note) ],
    Record = assemblies(Target, Ways, Note).

run_form(compose_from_parts, assembly(same_block_compositions(Counts)), Steps, printed(Record)) :-
    findall(composed(Block, K, Units),
            ( member(K, Counts), pattern_block(Block, U, _), Units is U * K ),
            Compositions),
    length(Compositions, NC),
    Steps = [ step(1, read_target, same_block_counts(Counts), NC),
              step(2, enumerate_candidates, Compositions, NC),
              step(3, check_exact_fit, Compositions, equal_size_pieces),
              step(4, count_distinct_ways, NC, done) ],
    Record = compositions(Compositions).

run_form(compose_from_parts, assembly(cube_nets), Steps, Artifact) :-
    findall(H, hexomino(H), All),
    length(All, NAll),
    include(cube_net_foldable, All, Folders),
    length(Folders, NFold),
    Artifact = scene(solid_net_scene, net_of(cube)),
    Steps = [ step(1, read_target, cube_six_square_faces, 6),
              step(2, enumerate_candidates, six_square_arrangements, NAll),
              step(3, check_exact_fit, roll_a_cube_over_each, NFold),
              step(4, count_distinct_ways, NFold, of(NAll)) ].

run_form(compose_from_parts, assembly(repeating_unit(Unit, Positions)), Steps, printed(Record)) :-
    length(Unit, L),
    findall(at(P, Element),
            ( member(P, Positions),
              Index is ((P - 1) mod L) + 1,
              nth1(Index, Unit, Element) ),
            Answers),
    length(Positions, NP),
    Steps = [ step(1, read_target, unit(Unit), L),
              step(2, enumerate_candidates, Positions, NP),
              step(3, check_exact_fit, position_modulo_unit_length, L),
              step(4, count_distinct_ways, Answers, answered) ],
    Record = pattern(Unit, Answers).

run_form(compose_from_parts, assembly(cube_join(V1, V2)), Steps, Artifact) :-
    Total is V1 + V2,
    boxes_with_volume(V1, B1),
    boxes_with_volume(V2, B2),
    boxes_with_volume(Total, BT),
    length(B1, N1), length(B2, N2), length(BT, NT),
    BT = [L-W-H | _],
    Artifact = scene(solid_net_scene, unit_cube_stack(L, W, H)),
    Steps = [ step(1, read_target, join(V1, V2), Total),
              step(2, enumerate_candidates, prisms(N1, N2), NT),
              step(3, check_exact_fit, volume_adds_when_prisms_do_not_overlap, Total),
              step(4, count_distinct_ways, BT, NT) ].

% ---- measure_and_order ------------------------------------------------------

run_form(measure_and_order, order_task(objects(Objects), Query), Steps, printed(Record)) :-
    findall(M-L, member(obj(L, M), Objects), Keyed),
    keysort(Keyed, Sorted),
    pairs_values(Sorted, Ranked),
    length(Objects, NO),
    order_answer(Query, Sorted, Answer),
    Steps = [ step(1, measure_quantity, Objects, NO),
              step(2, order_by_magnitude, Ranked, ordered),
              step(3, answer_ordering_query, Query, Answer) ],
    Record = ordering(Ranked, Query, Answer).

run_form(measure_and_order, order_task(figures_by(Measure, Ids), Query), Steps, printed(Record)) :-
    findall(obj(Id, M),
            ( member(Id, Ids), canonical_figure(Id, _, Vs),
              figure_measure(Measure, Vs, M) ),
            Objects),
    Objects \== [],
    run_form(measure_and_order, order_task(objects(Objects), Query), Steps, printed(Record)).

run_form(measure_and_order, order_task(cube_objects(N), Query), Steps, printed(Record)) :-
    boxes_with_volume(N, Boxes),
    findall(obj(Label, N),
            ( member(L-W-H, Boxes), format(atom(Label), "~wx~wx~w", [L, W, H]) ),
            Objects),
    length(Objects, NO),
    Steps = [ step(1, measure_quantity, Objects, NO),
              step(2, order_by_magnitude, all_equal(N), tie),
              step(3, answer_ordering_query, Query,
                    'every object built from the same number of cubes has the same volume, so the order is a tie') ],
    Record = ordering(Objects, Query, tie(N)).

% ---- angle_composition ------------------------------------------------------

run_form(angle_composition, angle_task(copies_fill(Copies, Sums)), Steps, Artifact) :-
    findall(solved(Name, N, Whole, Part),
            ( member(copies(Name, N, Whole), Copies),
              0 is Whole mod N,
              Part is Whole // N ),
            Solved),
    Solved \== [],
    findall(total(Names, Total),
            ( member(sum(Names), Sums),
              findall(P, ( member(Nm, Names), member(solved(Nm, _, _, P), Solved) ), Ps),
              sum_list(Ps, Total) ),
            Totals),
    Solved = [solved(_, _, _, FirstPart) | _],
    Artifact = scene(angle_circular_scene, angle(FirstPart)),
    length(Copies, NC),
    Steps = [ step(1, read_known_whole, Copies, NC),
              step(2, compose_or_divide_turn, Solved, divided),
              step(3, report_degree_measure, Totals, summed) ].

run_form(angle_composition, angle_task(clock_times(Times)), Steps, Artifact) :-
    findall(clock(T, Deg),
            ( member(T, Times), clock_angle(T, Deg) ),
            Angles),
    Angles \== [],
    (   member(clock(_, D0), Angles), integer(D0), D0 > 0
    ->  Artifact = scene(angle_circular_scene, angle(D0))
    ;   Artifact = printed(clock_angles(Angles))
    ),
    length(Times, NT),
    Steps = [ step(1, read_known_whole, full_turn(360), 360),
              step(2, compose_or_divide_turn, Times, NT),
              step(3, report_degree_measure, Angles, measured) ].

run_form(angle_composition, angle_task(turn_fractions(Whole, Divisors)), Steps, Artifact) :-
    findall(fraction(D, Deg),
            ( member(D, Divisors), 0 is Whole mod D, Deg is Whole // D ),
            Fractions),
    Fractions \== [],
    Fractions = [fraction(_, First) | _],
    Artifact = scene(angle_circular_scene, sector(First)),
    length(Divisors, ND),
    Steps = [ step(1, read_known_whole, full_turn(Whole), Whole),
              step(2, compose_or_divide_turn, Divisors, ND),
              step(3, report_degree_measure, Fractions, measured) ].

run_form(angle_composition, angle_task(fill_straight(Parts)), Steps, Artifact) :-
    findall(pair(Given, Rest),
            ( member(complement(Given), Parts), Rest is 180 - Given ),
            Pairs),
    Pairs \== [],
    Pairs = [pair(First, _) | _],
    Artifact = scene(angle_circular_scene, angle(First)),
    length(Parts, NP),
    Steps = [ step(1, read_known_whole, straight_angle(180), 180),
              step(2, compose_or_divide_turn, Parts, NP),
              step(3, report_degree_measure, Pairs, measured) ].

run_form(angle_composition, angle_task(step_slope(Angles, Rise)), Steps, Artifact) :-
    findall(slope(A, Rise, Steps10),
            ( member(A, Angles), Steps10 is Rise * 10 ),
            Slopes),
    Angles = [First | _],
    Artifact = scene(angle_circular_scene, angle(First)),
    length(Angles, NA),
    Steps = [ step(1, read_known_whole, right_angle(90), 90),
              step(2, compose_or_divide_turn, Angles, NA),
              step(3, report_degree_measure, Slopes, measured) ].

run_form(angle_composition, angle_task(unfold_symmetry(Angles)), Steps, Artifact) :-
    findall(unfolded(A, Doubled),
            ( member(A, Angles), Doubled is 2 * A ),
            Unfolded),
    sum_list(Angles, Sum),
    Angles = [First | _],
    Artifact = scene(angle_circular_scene, angle(First)),
    length(Angles, NA),
    Steps = [ step(1, read_known_whole, folded_half, NA),
              step(2, compose_or_divide_turn, Unfolded, doubled_across_the_fold),
              step(3, report_degree_measure, Sum, Unfolded) ].

% ---- describe_and_reproduce -------------------------------------------------

run_form(describe_and_reproduce, description_task(Source, PoolName), Steps, Artifact) :-
    description_source(Source, Description, SourceVs),
    figure_pool(PoolName, Pool),
    pool_vertices(Pool, PoolVs),
    include(matches_description(Description), PoolVs, Matches),
    length(Matches, NMatch),
    length(PoolVs, NPool),
    (   NMatch =:= 1
    ->  Reading = 'the description picks out one figure in the pool'
    ;   Reading = 'the description still allows more than one figure, which is what the partners find when their drawings differ'
    ),
    ( SourceVs == none -> Artifact = printed(descriptions(Description, Matches, Reading))
    ; Artifact = scene(geoboard_scene, stretch_polygon(SourceVs)) ),
    Steps = [ step(1, compute_source_attributes, Source, Description),
              step(2, state_description, Description, stated),
              step(3, rebuild_from_description, NPool, NMatch),
              step(4, count_figures_still_allowed, NMatch, Reading) ].

run_form(describe_and_reproduce, grid_rounds_task(figure(Id), Rounds), Steps, Artifact) :-
    canonical_figure(Id, _, Vs),
    figure_pool(all_shapes, Pool),
    pool_vertices(Pool, PoolVs),
    findall(round(N, Regime, Allowed, Score),
            ( member(round(N, Regime), Rounds),
              regime_description(Regime, Vs, Description),
              include(matches_description(Description), PoolVs, M),
              length(M, Allowed),
              ( Allowed =:= 1 -> Score = 2 ; Score = 1 ) ),
            Results),
    length(Rounds, NR),
    Artifact = scene(geoboard_scene, stretch_polygon(Vs)),
    Steps = [ step(1, compute_source_attributes, Id, measured),
              step(2, state_description, Rounds, NR),
              step(3, rebuild_from_description, Results, scored),
              step(4, count_figures_still_allowed, Results,
                    'the numbered grid is the regime that earns two points, because coordinates leave one figure standing') ].

run_form(describe_and_reproduce, description_task(prism_from_cubes(Min), prisms_to(Max)), Steps, printed(Record)) :-
    findall(prism(V, Boxes, N),
            ( between(Min, Max, V), boxes_with_volume(V, Boxes), length(Boxes, N) ),
            Prisms),
    findall(V, member(prism(V, _, 1), Prisms), Determined),
    length(Prisms, NP),
    Steps = [ step(1, compute_source_attributes, cubes_between(Min, Max), NP),
              step(2, state_description, volume_only, stated),
              step(3, rebuild_from_description, Prisms, rebuilt),
              step(4, count_figures_still_allowed, Determined,
                    'a volume alone fixes the prism only when it has a single factor triple; otherwise the partner needs the edge lengths') ],
    Record = prisms(Prisms, Determined).

% ---- separating_attribute ---------------------------------------------------

run_form(separating_attribute, separate_task(figures(PoolName), three_go_together), Steps, printed(Record)) :-
    figure_pool(PoolName, Pool),
    length(Pool, 4),
    figure_vocabulary(Vocabulary),
    findall(triple(Three, Out, Reasons),
            ( select(Out, Pool, Three),
              findall(Cond,
                      ( member(Cond, Vocabulary),
                        forall(member(I, Three),
                               ( canonical_figure(I, _, V), holds_all(V, Cond) )),
                        canonical_figure(Out, _, OV), \+ holds_all(OV, Cond) ),
                      Reasons) ),
            Triples),
    findall(T, member(triple(T, _, []), Triples), Unseparated),
    length(Triples, NT),
    Steps = [ step(1, build_attribute_matrix, Pool, measured),
              step(2, search_separating_condition, Vocabulary, NT),
              step(3, report_split_or_coarseness, Triples, Unseparated) ],
    Record = separations(Triples, Unseparated).

run_form(separating_attribute, separate_task(figures(PoolName), which_one), Steps, printed(Record)) :-
    figure_pool(PoolName, Pool),
    figure_vocabulary(Vocabulary),
    findall(question(A, B, Cond),
            ( member(A, Pool), member(B, Pool), A @< B,
              canonical_figure(A, _, VA), canonical_figure(B, _, VB),
              once(( member(Cond, Vocabulary), holds_all(VA, Cond), \+ holds_all(VB, Cond) )) ),
            Questions),
    findall(A-B,
            ( member(A, Pool), member(B, Pool), A @< B,
              \+ member(question(A, B, _), Questions) ),
            Indistinguishable),
    length(Questions, NQ),
    Steps = [ step(1, build_attribute_matrix, Pool, measured),
              step(2, search_separating_condition, Vocabulary, NQ),
              step(3, report_split_or_coarseness, Questions, Indistinguishable) ],
    Record = questions(Questions, Indistinguishable).

run_form(separating_attribute, separate_task(numbers(Sets), three_go_together), Steps, printed(Record)) :-
    number_vocabulary(Vocabulary),
    findall(Label, member(set(Label, _), Sets), Labels),
    findall(triple(Three, Out, Reasons),
            ( select(Out, Labels, Three),
              findall(Name,
                      ( member(Name-Test, Vocabulary),
                        forall(member(L, Three),
                               ( member(set(L, Ns), Sets), sequence_holds(Test, Ns) )),
                        member(set(Out, ONs), Sets),
                        \+ sequence_holds(Test, ONs) ),
                      Reasons) ),
            Triples),
    findall(T, member(triple(T, _, []), Triples), Unseparated),
    length(Triples, NT),
    Steps = [ step(1, build_attribute_matrix, Sets, measured),
              step(2, search_separating_condition, Vocabulary, NT),
              step(3, report_split_or_coarseness, Triples, Unseparated) ],
    Record = separations(Triples, Unseparated).

% ---- hierarchy_claim --------------------------------------------------------

run_form(hierarchy_claim, claim_task(Definitions, Claims), Steps, printed(Record)) :-
    findall(under(DefId, Verdicts),
            ( member(definition(DefId, Rule), Definitions),
              findall(verdict(Text, Answer),
                      ( member(claim(Text, Quantifier, ClassA, ClassB), Claims),
                        adjudicate_claim(Rule, Quantifier, ClassA, ClassB, Answer) ),
                      Verdicts) ),
            Results),
    length(Claims, NC),
    length(Definitions, ND),
    Steps = [ step(1, fix_definition, Definitions, ND),
              step(2, test_criteria, Claims, NC),
              step(3, report_quantifier, Results, adjudicated) ],
    Record = claims(Results).

% ---- coordinate_locate ------------------------------------------------------

run_form(coordinate_locate, coordinate_task(Plots, Queries), Steps, Artifact) :-
    findall(P, member(plot(_, P), Plots), Points),
    Points \== [],
    findall(answer(Q, A), ( member(Q, Queries), coordinate_answer(Q, Points, A) ), Answers),
    length(Points, NP),
    Artifact = scene(coordinate_plane_scene, plot_points(Points)),
    Steps = [ step(1, place_or_read_points, Plots, NP),
              step(2, name_figure_from_vertices, Answers, answered) ].

% ---- derive_unknown_measure -------------------------------------------------

run_form(derive_unknown_measure, measure_task(rectilinear_run(Known, Unknowns, Total)), Steps, printed(Record)) :-
    sum_list(Known, Sum),
    length(Unknowns, NU),
    (   NU =:= 1
    ->  Value is Total - Sum,
        Unknowns = [unknown(Name)],
        Outcome = determined(Name, Value)
    ;   Outcome = underdetermined(NU)
    ),
    Steps = [ step(1, read_labelled_measures, Known, Sum),
              step(2, apply_closure_constraint, opposite_runs_balance(Total), Total),
              step(3, report_determined_or_underdetermined, Outcome,
                    'the unknown side follows from the labelled ones, so how long it looks does not enter') ],
    Record = closure(Known, Total, Outcome).

run_form(derive_unknown_measure, measure_task(clear_floor(area(W, H), Furniture)), Steps, printed(Record)) :-
    Floor is W * H,
    findall(Label-A,
            ( member(furniture(Label, FW, FH), Furniture), A is FW * FH ),
            Pieces),
    pairs_values(Pieces, Areas),
    sum_list(Areas, Used),
    Clear is Floor - Used,
    length(Furniture, NF),
    Steps = [ step(1, read_labelled_measures, room(W, H), Floor),
              step(2, apply_closure_constraint, subtract_furniture(Pieces), NF),
              step(3, report_determined_or_underdetermined, clear_floor(Clear), Clear) ],
    Record = floor(Floor, Pieces, Clear).

run_form(derive_unknown_measure, measure_task(chicken_yard(coop_area(Coop), per_chicken(Lo, Hi), max_chickens(Max), fencing(Fence))), Steps, printed(Record)) :-
    findall(plan(N, NeedLo-NeedHi, W-H),
            ( between(1, Max, N),
              NeedLo is Coop + N * Lo,
              NeedHi is Coop + N * Hi,
              rectangles_with_area_atleast(NeedHi, Fence, W-H) ),
            Plans),
    length(Plans, NP),
    ( Plans == [] -> Reading = 'no rectangle inside the fencing holds the coop and the chickens'
    ; Reading = 'these chicken counts fit inside both the fencing and the space each chicken needs' ),
    Steps = [ step(1, read_labelled_measures, coop_and_fence(Coop, Fence), Fence),
              step(2, apply_closure_constraint, perimeter_bounds_area(Fence), NP),
              step(3, report_determined_or_underdetermined, Plans, Reading) ],
    Record = chickens(Plans, Reading).

run_form(derive_unknown_measure, measure_task(tiny_houses(Houses)), Steps, printed(Record)) :-
    findall(house(Label, W, H, Area, Perimeter),
            ( member(house(Label, W, H), Houses),
              Area is W * H, Perimeter is 2 * (W + H) ),
            Measured),
    length(Houses, NH),
    Steps = [ step(1, read_labelled_measures, Houses, NH),
              step(2, apply_closure_constraint, rectangle_area_and_perimeter, computed),
              step(3, report_determined_or_underdetermined, Measured, determined) ],
    Record = houses(Measured).

run_form(derive_unknown_measure, measure_task(banner(poster(PW, PH), banner(BH, BL))), Steps, printed(Record)) :-
    PosterArea is PW * PH,
    BannerArea is BH * BL,
    ( PosterArea >= BannerArea -> Answer = enough ; Answer = not_enough ),
    Difference is PosterArea - BannerArea,
    Steps = [ step(1, read_labelled_measures, poster(PW, PH), PosterArea),
              step(2, apply_closure_constraint, cut_and_rearrange_preserves_area, BannerArea),
              step(3, report_determined_or_underdetermined, Answer, Difference) ],
    Record = banner(PosterArea, BannerArea, Answer, Difference).

run_form(derive_unknown_measure, measure_task(perimeter_determinacy(Shapes)), Steps, printed(Record)) :-
    findall(shape(Label, Profile, Labelled, Outcome),
            ( member(shape(Label, Profile, Labelled), Shapes),
              perimeter_determined(Profile, Labelled, Outcome) ),
            Results),
    findall(L, member(shape(L, _, _, determined), Results), Determined),
    length(Shapes, NS),
    Steps = [ step(1, read_labelled_measures, Shapes, NS),
              step(2, apply_closure_constraint, equal_sides_from_parallels_and_symmetry, applied),
              step(3, report_determined_or_underdetermined, Results, Determined) ],
    Record = determinacy(Results, Determined).

run_form(derive_unknown_measure, measure_task(packing(N)), Steps, Artifact) :-
    boxes_with_volume(N, Boxes),
    length(Boxes, NB),
    Boxes = [L-W-H | _],
    Artifact = scene(solid_net_scene, unit_cube_stack(L, W, H)),
    Steps = [ step(1, read_labelled_measures, cubes(N), N),
              step(2, apply_closure_constraint, whole_number_edge_lengths, NB),
              step(3, report_determined_or_underdetermined, Boxes, NB) ].

run_form(derive_unknown_measure, measure_task(rainfall(area(A), depth(D), litre(Per))), Steps, printed(Record)) :-
    Volume is A * D,
    Litres is Volume // Per,
    Remainder is Volume mod Per,
    Steps = [ step(1, read_labelled_measures, roof(A), A),
              step(2, apply_closure_constraint, area_times_depth_is_volume, Volume),
              step(3, report_determined_or_underdetermined, litres(Litres), Remainder) ],
    Record = rainfall(A, D, Volume, Litres).

% =============================================================================
% 8. Support
% =============================================================================

figure_pool(all_shapes, Ids) :- !,
    findall(Id, canonical_figure(Id, _, _), Ids).
figure_pool(quadrilaterals, Ids) :- !,
    findall(Id, canonical_figure(Id, quadrilateral, _), Ids).
figure_pool(triangles, Ids) :- !,
    findall(Id, canonical_figure(Id, triangle, _), Ids).
figure_pool(rectangles_to(N), Ids) :- !,
    findall(Id, ( canonical_figure(Id, quadrilateral, Vs), fig_right_angle_count(Vs, 4),
                  fig_area(Vs, A), integer(A), A =< N*N ), Ids).
figure_pool(pool(Ids), Ids) :- is_list(Ids), !.
figure_pool(Ids, Ids) :- is_list(Ids).

pool_vertices(Ids, VsList) :-
    findall(Vs, ( member(Id, Ids), canonical_figure(Id, _, Vs) ), VsList).

holds_all(Vs, Conds) :- is_list(Conds), !, forall(member(C, Conds), cond_holds(Vs, C)).
holds_all(Vs, Cond) :- cond_holds(Vs, Cond).

%!  cond_holds(+Vertices, +Condition) is semidet.
%
%   The condition vocabulary the lesson rows use. The three clauses above the
%   delegation are the ones a lesson states in words a figure attribute does
%   not carry directly; everything else reaches `geometry_figures:fig_holds/2`,
%   where it becomes a calculation.
cond_holds(Vs, class(Class)) :- !,
    class_condition(Class, Conds),
    forall(member(C, Conds), cond_holds(Vs, C)).
cond_holds(Vs, not(Cond)) :- !,
    \+ cond_holds(Vs, Cond).
cond_holds(Vs, width_area(W, MaxArea)) :- !,
    fig_side_lengths2(Vs, [S | _]), S =:= W*W,
    fig_area(Vs, A), integer(A), A =< MaxArea.
cond_holds(Vs, width_area_exact(W, Area)) :- !,
    fig_side_lengths2(Vs, [S | _]), S =:= W*W,
    fig_area(Vs, Area).
cond_holds(_, angle_between(_, _)) :- !, fail.
cond_holds(Vs, Cond) :-
    fig_holds(Vs, Cond).

figure_measure(area, Vs, M)      :- fig_area(Vs, A), ( integer(A) -> M = A ; A = N/2, M is N ).
figure_measure(perimeter, Vs, M) :- ( fig_perimeter(Vs, P) -> M = P ; fig_side_lengths2(Vs, S), sum_list(S, M) ).
figure_measure(sides, Vs, M)     :- fig_sides(Vs, M).

%!  figure_vocabulary(-Conditions) is det.
%
%   The yes-or-no questions a class has available at this grade band. A report
%   that no question separates two figures is a report about this list, and the
%   verdict says so.
figure_vocabulary([ sides(3), sides(4), sides(5), sides(6),
                    all_sides_equal, convex, concave,
                    at_least(right_angles, 1), exactly(right_angles, 4),
                    at_least(parallel_pairs, 1), exactly(parallel_pairs, 2),
                    at_least(perpendicular_pairs, 1),
                    at_least(lines_of_symmetry, 1), at_least(obtuse_angles, 1) ]).

%!  number_vocabulary(-Tests) is det.
%
%   Properties of a whole sequence, not of a single term, because a Which Three
%   Go Together set is a skip count and the reason three of them go together
%   usually lives in the step rather than in the digits.
number_vocabulary([ 'every term is even'-every(even),
                    'every term is a multiple of 3'-every(multiple(3)),
                    'every term is a multiple of 5'-every(multiple(5)),
                    'the terms go up by the same amount each time'-constant_difference,
                    'each term is ten times the one before'-constant_ratio(10),
                    'the list includes 12'-includes(12),
                    'the list starts at 0'-starts_at(0),
                    'no term is greater than 100'-bounded_by(100) ]).

sequence_holds(every(P), Ns)          :- forall(member(N, Ns), term_property(P, N)).
sequence_holds(constant_difference, Ns) :-
    differences(Ns, [D | Ds]), forall(member(X, Ds), X =:= D).
sequence_holds(constant_ratio(R), Ns) :-
    forall(consecutive(Ns, A, B), ( A =\= 0, B =:= A * R )).
sequence_holds(includes(K), Ns)       :- memberchk(K, Ns).
sequence_holds(starts_at(K), [K | _]).
sequence_holds(bounded_by(K), Ns)     :- forall(member(N, Ns), N =< K).

term_property(even, N)        :- 0 is N mod 2.
term_property(multiple(M), N) :- 0 is N mod M.

differences(Ns, Ds) :- findall(D, ( consecutive(Ns, A, B), D is B - A ), Ds).

consecutive(Ns, A, B) :-
    nth0(I, Ns, A), J is I + 1, nth0(J, Ns, B).

number_holds(N, factor_of(M)) :- N > 0, 0 is M mod N.
number_holds(N, multiple_of(M)) :- 0 is N mod M.
number_holds(N, prime) :- N > 1, \+ ( between(2, N, D), D*D =< N, 0 is N mod D ).
number_holds(N, composite) :- N > 1, \+ number_holds(N, prime).

magnitude_holds(Size, below(K))              :- Size < K.
magnitude_holds(Size, between_units(Lo, Hi)) :- Size >= Lo, Size < Hi.
magnitude_holds(Size, above(K))              :- Size >= K.

segments_hold(Segments, exactly(parallel_pairs, N))      :- segment_parallel_pairs(Segments, N).
segments_hold(Segments, at_least(parallel_pairs, N))     :- segment_parallel_pairs(Segments, K), K >= N.
segments_hold(Segments, at_least(perpendicular_pairs, N)):- segment_perpendicular_pairs(Segments, K), K >= N.

segment_parallel_pairs(Segments, N) :-
    findall(1, ( segment_pair(Segments, A, B), seg_cross(A, B, 0) ), Ls),
    length(Ls, N).

segment_perpendicular_pairs(Segments, N) :-
    findall(1, ( segment_pair(Segments, A, B), seg_dot(A, B, 0) ), Ls),
    length(Ls, N).

segment_pair(Segments, A, B) :-
    nth0(I, Segments, A), nth0(J, Segments, B), I < J.

seg_cross((X1-Y1)-(X2-Y2), (X3-Y3)-(X4-Y4), C) :-
    DX1 is X2-X1, DY1 is Y2-Y1, DX2 is X4-X3, DY2 is Y4-Y3,
    C is DX1*DY2 - DY1*DX2.

seg_dot((X1-Y1)-(X2-Y2), (X3-Y3)-(X4-Y4), D) :-
    DX1 is X2-X1, DY1 is Y2-Y1, DX2 is X4-X3, DY2 is Y4-Y3,
    D is DX1*DX2 + DY1*DY2.

part_name(2, half).
part_name(3, third).
part_name(4, fourth).
part_name(5, fifth).
part_name(6, sixth).
part_name(8, eighth).
part_name(12, twelfth).
part_name(N, part_of(N)) :- \+ memberchk(N, [2, 3, 4, 5, 6, 8, 12]).

reduce(A, B, Num/Den) :-
    G is gcd(A, B), G > 0,
    Num is A // G, Den is B // G.

empty_cell_reasons(Empty, Reasons) :-
    findall(Cell-Reason,
            ( member(Cell, Empty), empty_cell_reason(Cell, Reason) ),
            Reasons).

%!  empty_cell_reason(+Cell, -Reason) is det.
%
%   Two kinds of empty, kept apart. A right or obtuse angle beside three equal
%   sides is impossible in the plane, and the angle sum says why: three equal
%   sides force three equal angles, and three equal angles summing to 180 are
%   60 each. Three equal sides beside three acute angles is possible in the
%   plane and absent here only because the integer lattice holds no equilateral
%   triangle. The chart looks the same in both cells; the reason does not.
empty_cell_reason('Has a 90-degree angle'/'All 3 side lengths are equal',
    'Three equal sides force three equal angles, and three equal angles adding to 180 degrees are 60 degrees each, so no equilateral triangle carries a right angle. This cell is empty in the plane, not only in this inventory.') :- !.
empty_cell_reason('Has an angle greater than 90 degrees'/'All 3 side lengths are equal',
    'The same angle sum: each angle of an equilateral triangle is 60 degrees, so none is greater than 90. This cell is empty in the plane, not only in this inventory.') :- !.
empty_cell_reason(_/'All 3 side lengths are equal', Reason) :- !,
    lattice_unrealizable(equilateral_triangle, Argument),
    format(atom(Reason),
           "An equilateral triangle with three acute angles exists in the plane; this cell is empty because the figures here have integer vertices. ~w",
           [Argument]).
empty_cell_reason(_, 'No figure in this inventory fits both descriptions. The inventory is finite, so that is not a proof that none exists.').

% -- construction search ------------------------------------------------------

%!  construct_outcome(+Conditions, -Outcome) is det.
%
%   found(Source, Vertices) when a figure in the search space satisfies every
%   condition; impossible(Reason) where an argument rules the figure out;
%   exhausted(N) when the bounded space ran out. The third is not the second,
%   and the code keeps them apart.
construct_outcome(Conditions, impossible(Reason)) :-
    construction_ruled_out(Conditions, Reason), !.
construct_outcome(Conditions, found(N, Example)) :-
    witnesses(Conditions, All),
    All \== [], !,
    length(All, N),
    All = [Example | _].
construct_outcome(Conditions, exhausted_with_containment(Reading)) :-
    containment_reading(Conditions, Reading), !.
construct_outcome(_, exhausted(Size)) :-
    search_space_size(Size).

%!  witnesses(+Conditions, -All) is det.
%
%   Every figure in the bounded space that satisfies all the conditions. Angle
%   constraints search the whole degrees instead of the polygons, because an
%   angle is not a polygon and pretending otherwise would return the wrong kind
%   of object.
witnesses(Conditions, All) :-
    memberchk(angle_between(_, _), Conditions), !,
    findall(angle(D),
            ( between(1, 359, D),
              forall(member(angle_between(Lo, Hi), Conditions), (D >= Lo, D =< Hi)) ),
            All).
witnesses(Conditions, All) :-
    findall(Vs,
            ( search_space_figure(Vs), holds_all(Vs, Conditions) ),
            Raw),
    sort(Raw, All).

search_space_figure(Vs) :- canonical_figure(_, _, Vs).
search_space_figure(Vs) :- generated_figure(Vs), fig_simple_closed(Vs).

%!  containment_reading(+Conditions, -Reading) is semidet.
%
%   The honest form of "impossible" when the argument is not to hand: the
%   positive part of the constraint has witnesses, and every one of them also
%   falls under the class the constraint excludes. That is a statement about
%   this search space, and it says so.
containment_reading(Conditions, contained(NPos, A, B)) :-
    select(not(class(B)), Conditions, Positive),
    memberchk(class(A), Positive),
    witnesses(Positive, Pos),
    Pos \== [],
    length(Pos, NPos).

construction_ruled_out(Conditions, Reason) :-
    memberchk(sides(3), Conditions),
    memberchk(all_sides_equal, Conditions),
    lattice_unrealizable(equilateral_triangle, Reason).
construction_ruled_out(Conditions, Reason) :-
    memberchk(not(C), Conditions),
    memberchk(C, Conditions),
    format(atom(Reason),
           "the constraint list asks for ~w and its negation at once, so nothing can satisfy it",
           [C]).
construction_ruled_out(Conditions, Reason) :-
    memberchk(width_area_exact(W, A), Conditions),
    \+ 0 is A mod W,
    format(atom(Reason),
           "an area of ~w is not a multiple of the width ~w, so no rectangle of whole tiles with that width has it",
           [A, W]).

%!  generated_figure(-Vertices) is nondet.
%
%   A bounded parametric family: rectangles, parallelograms, trapezoids, kites
%   and triangles over small integer parameters. This is the search space, and
%   it is smaller than every lattice polygon, so "exhausted" always names the
%   family rather than the plane.
generated_figure([0-0, W-0, W-H, 0-H]) :-
    between(1, 6, W), between(1, 6, H).
generated_figure([0-0, W-0, WS-H, S-H]) :-
    between(2, 5, W), between(1, 4, H), between(1, 3, S), WS is W + S.
generated_figure([0-0, B-0, TS-H, S-H]) :-
    between(3, 6, B), between(1, 4, H), between(1, 2, S),
    between(1, 4, T), T < B, TS is T + S.
generated_figure([0-0, A-B, 0-C, NA-B]) :-
    between(1, 4, A), between(1, 4, B), between(2, 8, C), B < C, NA is -A.
generated_figure([0-0, W-0, P-Q]) :-
    between(1, 6, W), between(-3, 5, P), between(1, 5, Q).
generated_figure([0-0, 4-0, 5-3, 2-5, -1-3]).
generated_figure([0-0, 3-0, 5-2, 4-5, 1-5, -1-2]).
%   Rectilinear six-sided figures: every side has whole-number length, which is
%   what a lesson asking for a specific side length on a six-sided figure needs.
generated_figure([0-0, A-0, A-B, C-B, C-D, 0-D]) :-
    between(2, 6, A), between(1, 4, B), between(1, 5, C), C < A,
    between(2, 6, D), B < D.
%   Pentagons with a rectangular base and one apex, so their side lengths vary.
generated_figure([0-0, W-0, W-H, P-T, 0-H]) :-
    between(2, 5, W), between(1, 4, H), between(1, 4, P), P < W,
    T is H + 2.

search_space_size(Size) :-
    (   nb_current(geometry_search_space, Size)
    ->  true
    ;   findall(1, ( generated_figure(V), fig_simple_closed(V) ), Ls),
        length(Ls, Size),
        nb_setval(geometry_search_space, Size)
    ).

% -- description --------------------------------------------------------------

description_source(figure(Id), Description, Vs) :-
    canonical_figure(Id, _, Vs), !,
    describe_figure(Vs, Description).
description_source(printed_description(Conds), Conds, none).

describe_figure(Vs, [sides(N), right_angles(R), parallel_pairs(P), lines_of_symmetry(S)]) :-
    fig_sides(Vs, N),
    fig_right_angle_count(Vs, R),
    fig_parallel_pairs(Vs, P),
    fig_symmetry_axis_count(Vs, S).

matches_description(Description, Vs) :-
    forall(member(C, Description), fig_holds(Vs, C)).

regime_description(no_grid, Vs, [sides(N)]) :-
    fig_sides(Vs, N).
regime_description(unnumbered_grid, Vs, [sides(N), right_angles(R), parallel_pairs(P)]) :-
    fig_sides(Vs, N), fig_right_angle_count(Vs, R), fig_parallel_pairs(Vs, P).
regime_description(numbered_grid, Vs, Description) :-
    describe_figure(Vs, Base),
    fig_area(Vs, A),
    append(Base, [area(A)], Description).

% -- ordering -----------------------------------------------------------------

order_answer(rank, Sorted, Ranked) :-
    pairs_values(Sorted, Ranked).
order_answer(within(Threshold), Sorted, TooClose) :-
    pairs_keys_values(Sorted, Keys, Values),
    findall(A-B,
            ( nth0(I, Keys, KA), nth0(J, Keys, KB), I < J,
              Diff is abs(KA - KB), Diff < Threshold,
              nth0(I, Values, A), nth0(J, Values, B) ),
            TooClose).
order_answer(estimate_band(Actual, band(Low, About, High)), _, Verdicts) :-
    findall(V,
            ( member(Label-Guess, ['too low'-Low, 'about right'-About, 'too high'-High]),
              band_verdict(Label, Guess, Actual, V) ),
            Verdicts).

band_verdict(Label, Guess, Actual, verdict(Label, Guess, Reading)) :-
    (   Guess < Actual -> Reading = 'below the measure'
    ;   Guess > Actual -> Reading = 'above the measure'
    ;   Reading = 'equal to the measure'
    ).

% -- clocks -------------------------------------------------------------------

%!  clock_angle(+Time, -Degrees) is semidet.
%
%   Half-degrees keep the arithmetic in the integers: the hour hand advances 60
%   half-degrees an hour plus 1 a minute, the minute hand 12 half-degrees a
%   minute. The smaller of the two arcs is the angle between the hands, and a
%   half-degree answer prints as Odd/2 instead of rounding.
clock_angle(Time, Degrees) :-
    split_string(Time, ":", "", [HS, MS]),
    number_string(H0, HS), number_string(M, MS),
    H is H0 mod 12,
    HourHalf is 60*H + M,
    MinuteHalf is 12*M,
    Raw is abs(HourHalf - MinuteHalf),
    Half is min(Raw, 720 - Raw),
    ( 0 is Half mod 2 -> Degrees is Half // 2 ; Degrees = Half/2 ).

% -- hierarchy ----------------------------------------------------------------

class_condition(square,               [sides(4), exactly(right_angles, 4), all_sides_equal]).
class_condition(rectangle,            [sides(4), exactly(right_angles, 4)]).
class_condition(rhombus,              [sides(4), all_sides_equal, at_least(parallel_pairs, 2)]).
class_condition(parallelogram,        [sides(4), at_least(parallel_pairs, 2)]).
class_condition(triangle,             [sides(3)]).
class_condition(quadrilateral_class,  [sides(4)]).

class_condition_under(trapezoid, exactly_one_parallel_pair,   [sides(4), exactly(parallel_pairs, 1)]).
class_condition_under(trapezoid, at_least_one_parallel_pair,  [sides(4), at_least(parallel_pairs, 1)]).
class_condition_under(Class, _, Cond) :- class_condition(Class, Cond).

adjudicate_claim(Rule, Quantifier, ClassA, ClassB, Answer) :-
    class_condition_under(ClassA, Rule, CondA),
    class_condition_under(ClassB, Rule, CondB),
    findall(Id, ( canonical_figure(Id, _, Vs), holds_all(Vs, CondA) ), AsAll),
    findall(Id, ( canonical_figure(Id, _, Vs), holds_all(Vs, CondA), holds_all(Vs, CondB) ), Both),
    length(AsAll, NA), length(Both, NB),
    (   NA =:= 0
    ->  Answer = vacuous('no figure in this inventory is in the first class')
    ;   quantifier_answer(Quantifier, NA, NB, AsAll, Both, Answer)
    ).

quantifier_answer(quantifier, NA, NB, _, _, Answer) :- !,
    (   NB =:= NA -> Answer = always
    ;   NB =:= 0  -> Answer = never
    ;   Answer = sometimes
    ).
quantifier_answer(all, NA, NB, _, _, Answer) :- !,
    ( NB =:= NA -> Answer = true ; Answer = false ).
quantifier_answer(none, _, NB, _, _, Answer) :- !,
    ( NB =:= 0 -> Answer = true ; Answer = false ).
quantifier_answer(some, _, NB, _, _, Answer) :-
    ( NB > 0 -> Answer = true ; Answer = false ).

% -- coordinates --------------------------------------------------------------

coordinate_answer(read(Label, X-Y), _, coordinates(Label, X, Y)).
coordinate_answer(common_attribute, Points, common(What)) :-
    (   findall(Y, member(_-Y, Points), Ys), sort(Ys, [Y0])
    ->  format(atom(What), "every point has y = ~w, so they lie on one horizontal line", [Y0])
    ;   findall(X, member(X-_, Points), Xs), sort(Xs, [X0])
    ->  format(atom(What), "every point has x = ~w, so they lie on one vertical line", [X0])
    ;   What = 'these points share no single coordinate'
    ).
coordinate_answer(name_figure, Points, figure(Name, Area)) :-
    fig_simple_closed(Points),
    fig_name(Points, Name),
    fig_area(Points, Area).

% -- determinacy --------------------------------------------------------------

%!  perimeter_determined(+Profile, +LabelledCount, -Outcome) is det.
%
%   A quadrilateral has four sides. Two pairs of parallel sides force opposite
%   sides equal, so two labels reach all four. One pair of parallel sides plus
%   a line of symmetry forces the two legs equal, so two labels again reach all
%   four. One pair alone, or neither, leaves a side no equality reaches.
perimeter_determined(Profile, Labelled, Outcome) :-
    memberchk(parallel_pairs(P), Profile),
    memberchk(lines_of_symmetry(S), Profile),
    forced_sides(P, S, Labelled, Forced),
    (   Forced >= 4
    ->  Outcome = determined
    ;   Missing is 4 - Forced,
        Outcome = underdetermined(Missing)
    ).

forced_sides(P, _, Labelled, Reach) :- P >= 2, !, Reach is Labelled * 2.
forced_sides(1, S, Labelled, Reach) :- S >= 1, !, Reach is Labelled * 2.
forced_sides(_, _, Labelled, Labelled).

% -- packing helper -----------------------------------------------------------

rectangles_with_area_atleast(Need, Fence, W-H) :-
    Half is Fence // 2,
    between(1, Half, W),
    H is Half - W,
    H >= W,
    Area is W * H,
    Area >= Need.

% -- pattern block partitions -------------------------------------------------

block_partition(0, _, []) :- !.
block_partition(N, Sizes, [S | Rest]) :-
    N > 0,
    member(S, Sizes),
    S =< N,
    N1 is N - S,
    block_partition_from(N1, Sizes, S, Rest).

block_partition_from(0, _, _, []) :- !.
block_partition_from(N, Sizes, Min, [S | Rest]) :-
    N > 0,
    member(S, Sizes),
    S >= Min,
    S =< N,
    N1 is N - S,
    block_partition_from(N1, Sizes, S, Rest).

% =============================================================================
% 9. Serialization: the seam a strategy trace already uses
% =============================================================================

%!  enactment_trace_dict(+Enactment, -Dict) is det.
%
%   The dict shape `hermes_encyclopedia:strategy_trace_dict/3` returns, built
%   here rather than through `history_steps/2`. That predicate reads a step term
%   as `step(State, _, _, Interp)`, so handing it `step(Index, Verb, Operand,
%   Result)` would silently label every row with its index and print the result
%   as the interpretation. Emitting the consumer dict directly keeps the step
%   term the spec fixed and still reaches the console, the MCP surface and the
%   charts without a viewer of its own.
enactment_trace_dict(enactment(Lesson, Form, Inputs, Steps, Artifact), Dict) :-
    enactment_verdict(enactment(Lesson, Form, Inputs, Steps, Artifact), Verdict),
    findall(_{n: I, label: LabelStr, value: ValueStr},
            ( member(step(I, Verb, Operand, Result), Steps),
              atom_string(Verb, LabelStr),
              format(string(ValueStr), "~q -> ~q", [Operand, Result]) ),
            StepDicts),
    atom_string(Form, FormStr),
    term_string(Verdict, VerdictStr),
    artifact_result_string(Artifact, ResultStr),
    artifact_jumps(Artifact, Jumps),
    ( lesson_caveat(Lesson, Caveat) -> true ; Caveat = '' ),
    format(string(Note), "~w. ~w", [VerdictStr, Caveat]),
    Dict = _{ strategy: FormStr,
              ok: true,
              representation: "im_lesson_enactment",
              result: ResultStr,
              steps: StepDicts,
              jumps: Jumps,
              note: Note }.

artifact_result_string(scene(Renderer, Term), Str) :- !,
    format(string(Str), "~w scene: ~q", [Renderer, Term]).
artifact_result_string(printed(Record), Str) :-
    format(string(Str), "~q", [Record]).

%!  artifact_jumps(+Artifact, -Jumps) is det.
%
%   A jump list is a number-line witness. Only the measurement strip among the
%   renderers this lane routes to carries one, so the others give the empty
%   list rather than a manufactured one.
artifact_jumps(scene(measurement_strip_scene, Spec), Jumps) :- !,
    (   catch(measurement_strip_scene:measurement_strip_render_json(Spec, Doc), _, fail),
        get_dict(frames, Doc, Frames), Frames \== [],
        last(Frames, Frame),
        get_dict(scene, Frame, Scene),
        get_dict(jumps, Scene, Jumps0)
    ->  Jumps = Jumps0
    ;   Jumps = []
    ).
artifact_jumps(_, []).

%!  enactment_artifact_dict(+Enactment, -Dict) is det.
%
%   The artifact in the shape the page builder reads. A scene artifact is run
%   through its own renderer, so the emitted row carries a frame count from a
%   real render rather than a promise of one. `scene_within_bounds/1` keeps
%   the call small: `measurement_strip_scene` carries the whole jump list on
%   every frame and so costs the square of its interval count, and the tiling
%   compilers emit a frame per row. A spec past the bound is printed instead.
enactment_artifact_dict(enactment(_, _, _, _, scene(Renderer, Spec)), Dict) :- !,
    term_string(Spec, SpecStr),
    (   scene_within_bounds(Spec),
        catch(render_scene(Renderer, Spec, Frames), _, fail)
    ->  Dict = _{kind: "scene", renderer: Renderer, term: SpecStr, frames: Frames}
    ;   Dict = _{kind: "scene", renderer: Renderer, term: SpecStr, frames: 0}
    ).
enactment_artifact_dict(enactment(_, _, _, _, printed(Record)), Dict) :-
    term_string(Record, RecordStr),
    Dict = _{kind: "printed", record: RecordStr}.

render_scene(Renderer, Spec, Frames) :-
    render_call(Renderer, Spec, Doc),
    get_dict(frames, Doc, FrameList),
    length(FrameList, Frames).

render_call(geoboard_scene, Spec, Doc) :-
    geoboard_scene:geoboard_render_json(Spec, Doc).
render_call(polyform_tiling_scene, Spec, Doc) :-
    polyform_tiling_scene:polyform_tiling_render_json(Spec, Doc).
render_call(angle_circular_scene, Spec, Doc) :-
    angle_circular_scene:angle_circular_render_json(Spec, Doc).
render_call(coordinate_plane_scene, Spec, Doc) :-
    coordinate_plane_scene:coordinate_plane_render_json(Spec, Doc).
render_call(solid_net_scene, Spec, Doc) :-
    solid_net_scene:solid_net_render_json(Spec, Doc).
render_call(measurement_strip_scene, Spec, Doc) :-
    measurement_strip_scene:measurement_strip_render_json(Spec, Doc).

%!  scene_within_bounds(+Spec) is semidet.
%
%   The bounds the renderers can be asked for without a long run. Each is a
%   frame count or a cell count, checked before the call rather than after a
%   wait.
scene_within_bounds(measure(Intervals, Subdivisions, _)) :- !,
    Intervals =< 24, Subdivisions =< 24.
scene_within_bounds(tile_area(cols(C), rows(R))) :- !,
    R =< 24, C * R =< 400.
scene_within_bounds(tile_region(cols(C), rows(R), Pieces)) :- !,
    R =< 24, C * R =< 400, length(Pieces, N), N =< 24.
scene_within_bounds(unit_cube_stack(L, W, H)) :- !,
    L * W * H =< 400.
scene_within_bounds(stretch_polygon(Vs)) :- !,
    lattice_box(Vs, Cells), Cells =< 400.
scene_within_bounds(plot_points(Points)) :- !,
    length(Points, N), N =< 40.
scene_within_bounds(_).

lattice_box(Vs, Cells) :-
    findall(X, member(X-_, Vs), Xs),
    findall(Y, member(_-Y, Vs), Ys),
    max_list(Xs, MaxX), min_list(Xs, MinX),
    max_list(Ys, MaxY), min_list(Ys, MinY),
    Cells is (MaxX - MinX + 1) * (MaxY - MinY + 1).

% =============================================================================
% 10. The census
% =============================================================================

%!  geometry_lane_lessons(-Lessons) is det.
geometry_lane_lessons(Lessons) :-
    findall(L, lesson_enactment_form(L, _, _), Raw),
    sort(Raw, Lessons).

%!  geometry_lane_coverage(-Report) is det.
%
%   Runs every lesson and counts what came back. `enacted_non_arithmetic` is
%   its own rung: nothing here is folded into `executable_task`, which means an
%   arithmetic computation ran.
geometry_lane_coverage(report(Total, WellFormed, Partial, Refused, Failed, ByForm)) :-
    geometry_lane_lessons(Lessons),
    length(Lessons, Total),
    findall(L-V, ( member(L, Lessons), lesson_outcome(L, V) ), Outcomes),
    findall(L, member(L-well_formed, Outcomes), WF), length(WF, WellFormed),
    findall(L, member(L-partial(_), Outcomes), P), length(P, Partial),
    findall(L, member(L-refused(_), Outcomes), R), length(R, Refused),
    findall(L, member(L-failed, Outcomes), F), length(F, Failed),
    findall(Form-N,
            ( enactment_form(Form, _, _),
              findall(1, ( member(L2, Lessons), lesson_enactment_form(L2, Form, _),
                           member(L2-V2, Outcomes), V2 \== failed ), Hits),
              length(Hits, N) ),
            ByForm).

lesson_outcome(Lesson, Verdict) :-
    (   lesson_inputs(Lesson, _, Inputs),
        catch(enact(Lesson, Inputs, Enactment), _, fail)
    ->  enactment_verdict(Enactment, Verdict)
    ;   Verdict = failed
    ).

%!  lane_move_audit(-Declared, -Undeclared) is det.
%
%   Every step verb every enactment emits, checked against `enactment_move/3` at
%   its own index of its own form. A verb that no move declares is a name the
%   code executes without the vocabulary admitting it, which is the failure this
%   audit exists to count.
lane_move_audit(Declared, Undeclared) :-
    geometry_lane_lessons(Lessons),
    findall(Lesson-Form-I-Verb,
            ( member(Lesson, Lessons),
              lesson_inputs(Lesson, _, Inputs),
              catch(enact(Lesson, Inputs, enactment(_, Form, _, Steps, _)), _, fail),
              member(step(I, Verb, _, _), Steps) ),
            All),
    findall(Row, ( member(Row, All), Row = _-Form-I-Verb,
                   enactment_move(Form, I, Verb) ), Good),
    findall(Row, ( member(Row, All), Row = _-Form-I-Verb,
                   \+ enactment_move(Form, I, Verb) ), Undeclared),
    length(Good, Declared).

%!  geometry_lane_refusal(?Lesson, -Machine) is nondet.
%
%   A lesson whose form did not run, with the machine that would lift it.
geometry_lane_refusal(Lesson, Machine) :-
    geometry_lane_lessons(Lessons),
    member(Lesson, Lessons),
    lesson_outcome(Lesson, Verdict),
    ( Verdict = failed -> true ; Verdict = refused(_) ),
    ( refusal_machine(Lesson, Machine) -> true
    ; Machine = 'no runner matched the input term for this form' ).

%!  refusal_machine(?Lesson, ?Machine) is nondet.
refusal_machine('IM-G3-U5-L10',
    'A figure reader for the filled-outline fraction glyphs docling drops, so the shaded target this task names becomes readable.').
refusal_machine('IM-G5-U3-L2',
    'The same glyph reader, plus a nested-partition model that shades a fraction of a fraction of one square.').
refusal_machine('IM-G4-U7-L15',
    'A diagram reader that lifts the labelled angle values out of the lesson figure, which the markdown carries as an image.').


% =============================================================================
% 11. Registration on curriculum/im/lesson_enactment.pl
% =============================================================================
%
% This lane wrote its machines before the contract module existed, so it keeps
% its own `enact/3` and its own verdict and joins through the contract's lane
% route: `enactment_run/3` finds the input term for a pair and runs it, and
% `enactment_lane_verdict/2` hands back the verdict computed above. The clauses
% below are the whole of the join; nothing in the lane changed to make it fit.
%
% The lane no longer writes its own emission file. `lesson_enactment` owns
% `data/learningcommons/derived/lesson_enactments/geometry_construction.jsonl`
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
       lesson_enactment:enactment_lesson_disclaimer/2,
       lesson_enactment:enactment_input_provenance/3,
       lesson_enactment:lesson_enactment_refusal/2.

lesson_enactment:enactment_lane(Form, geometry_construction_or_measure) :-
    enactment_form(Form, _, _).

lesson_enactment:enactment_form(Form, Gloss, Warrant) :-
    enactment_form(Form, Gloss, Warrant).

lesson_enactment:lesson_enactment_form(Lesson, Form, Evidence) :-
    lesson_enactment_form(Lesson, Form, Evidence).

lesson_enactment:enactment_move(Form, Index, Move) :-
    enactment_move(Form, Index, Move).

% One run per form. `lesson_inputs/3` pairs each of the lesson's input terms
% with each of its forms, and a term that does not support a form makes
% `run_form/4` fail, so the `once/1` takes the first pairing that runs rather
% than the first pairing offered.
% Every clause below is guarded on this lane's own forms. Without the guard a
% lane's verdict clause answers for every other lane's enactments too: these are
% multifile predicates in one namespace, and each lane's verdict predicate is
% total over enactment terms, so whichever lane loaded first would decide every
% verdict on the rung. The gate's list-artifact rule caught it, on an enactment
% of a fraction form reading well_formed out of a lane that never heard of it.

lesson_enactment:enactment_run(Form, Lesson, Enactment) :-
    enactment_form(Form, _, _),
    once(( lesson_inputs(Lesson, _Provenance, inputs(Form, Term)),
           enact(Lesson, inputs(Form, Term), Enactment) )).

lesson_enactment:enactment_lane_verdict(Enactment, Verdict) :-
    Enactment = enactment(_, Form, _, _, _),
    enactment_form(Form, _, _),
    once(enactment_verdict(Enactment, Verdict)).

lesson_enactment:enactment_disclaimer(Form, Sentence) :-
    form_default_caveat(Form, Sentence).

lesson_enactment:enactment_lesson_disclaimer(Lesson, Sentence) :-
    lesson_specific_caveat(Lesson, Sentence).

% Weakest marking wins, which is also the contract's own rule. A lesson here
% carries one input term, so the disjunction below is a guard rather than a
% common case; where it does fire it reports machine_supplied, which is the
% side that claims less.
lesson_enactment:enactment_input_provenance(Form, Lesson, Provenance) :-
    findall(P, lesson_inputs(Lesson, P, inputs(Form, _)), Marks),
    Marks \== [],
    (   memberchk(machine_supplied, Marks)
    ->  Provenance = machine_supplied
    ;   Marks = [Provenance | _]
    ).

lesson_enactment:lesson_enactment_refusal(Lesson, Machine) :-
    geometry_lane_refusal(Lesson, Machine).
