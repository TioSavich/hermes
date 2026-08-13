:- encoding(utf8).
/** <module> K-7 pilot: equal groups and rectangles, drawn as a grid of unit squares
 *
 * WHAT THIS IS. A quarantined scene-emission sibling for the K-7 doings whose
 * enactment is a rectangle of unit squares: equal groups coordinated into a
 * total, an area covered by unit squares, and the two readings that lay the
 * two counts end to end instead of coordinating them. It runs the EXISTING
 * machines through `action_automata_registry:run_action_automaton/6`, modifies
 * none of them, and adds a scene in the coordinate-plane grapher's own JSON
 * genre (`hermes/web/coordinate-plane`, schema version 1).
 *
 * WHY IT EXISTS. Grade 3's multiplication rows ask for the drawing in their
 * own words — "Create a drawing or diagram for each situation", "Show your
 * thinking using diagrams, symbols, or other representations" — and the
 * machine those rows route to returns a number and nothing else. The array is
 * not decoration on the product; coordinating a count of groups with a count
 * of items IS what makes the product a product, and a machine that reports 20
 * without ever drawing the 4 by 5 has kept the answer and dropped the doing.
 *
 * WHY BOTH DRAWINGS. `add_instead_of_multiply` reports 8 where 3 groups of 5
 * make 15. Drawn, that reading is a single strip of 8 squares laid under the
 * 3-by-5 array, and the difference between the two pictures is the whole
 * conversation. `area_as_perimeter_count` reports 20 where a 4-by-6 rectangle
 * holds 24 square units. Drawn, it is the boundary traced and the interior
 * left empty. Neither picture is invented here: each is the machine's own
 * result, drawn.
 *
 * EXACT, NOT PLOTTED. Every count is an integer the machine named. The scene
 * carries floats only because the renderer's schema takes numbers.
 *
 * WHAT THE CHECK PROVES. For every receipt: (1) the number of unit squares
 * drawn equals the count the machine itself reported, so no drawing carries a
 * square the machine did not count; (2) the grid closes — the horizontal lines
 * number one more than the rows and the vertical lines one more than the
 * columns; (3) for a deformation, the two counts drawn are the machine's own
 * `result` and `expected`, and they genuinely differ; (4) the scene renders
 * through `grapher.js` under Node.
 *
 * REFUSALS, NAMED. A rectangle of more than 240 unit squares is refused rather
 * than drawn. Grade 5's 600 by 500 is a true multiplication and a false
 * drawing.
 *
 * QUARANTINE. Nothing imports this module. It modifies no machine, no
 * transition table, no input contract, and no state-vocabulary row.
 * Check: `check_k7_array_grid/0`.
 */

:- module(k7_array_grid,
          [ run_k7_array_grid/4,
            k7_grid_from_json/2,
            k7_grid_states/1,
            k7_grid_state_label/4,
            k7_grid_summary/1,
            k7_grid_receipt/6,
            k7_grid_scene/2,
            check_k7_array_grid/0
          ]).

:- use_module(strategies('math/action_automata_registry'),
              [ run_action_automaton/6 ]).
:- use_module(strategies('abstraction/k7_scene_common'),
              [ k7_scene_json/2, k7_render_scenes/1, k7_colour/2,
                k7_point/4, k7_labelled_segment/7, k7_segment/6 ]).
:- use_module(library(lists), [sum_list/2]).

% ==========================================================================
% 1. INPUT CONTRACT
%
%   {"kind":"array_grid","doing":"repeat_equal_groups","a":3,"b":5}
%
%   `doing` names an EXISTING registry automaton. `a` and `b` are the row's
%   own two numbers in that automaton's own order: groups then items per
%   group for the multiplicative doings, rows then columns for the area ones.
% ==========================================================================

k7_grid_input_contract(
    '{\"kind\":\"array_grid\",\"doing\":\"string\",\"a\":\"integer\",\"b\":\"integer\"}',
    '{\"kind\":\"array_grid\",\"doing\":\"repeat_equal_groups\",\"a\":3,\"b\":5}').

k7_grid_from_json(Dict, grid_task(Doing, Operation, A, B)) :-
    is_dict(Dict),
    get_dict(kind, Dict, "array_grid"),
    get_dict(doing, Dict, DoingText),
    atom_string(Doing, DoingText),
    k7_grid_doing(Doing, Operation, _),
    get_dict(a, Dict, A), integer(A), A > 0,
    get_dict(b, Dict, B), integer(B), B > 0.

%!  k7_grid_doing(?Doing, ?Operation, ?Classification) is nondet.
%
%   The registry automata this pilot draws. Every one exists already.
k7_grid_doing(repeat_equal_groups, multiplication, productive).
k7_grid_doing(coordinate_groups_items, multiplication, productive).
k7_grid_doing(add_instead_of_multiply, multiplication, deformation).
k7_grid_doing(add_counts_without_composite_unit, multiplication, deformation).
k7_grid_doing(rectangle_area_unit_iteration, geometry, productive).
k7_grid_doing(area_as_perimeter_count, geometry, deformation).

% ==========================================================================
% 2. STATES
% ==========================================================================

k7_grid_states(
    [ q_read_the_two_counts,
      q_run_the_existing_machine,
      q_read_the_rows_and_columns_off_the_trace,
      q_check_the_squares_match_the_count,
      q_draw_the_array_of_unit_squares,
      q_draw_the_student_count_beside_it,
      q_accept_the_drawing,
      q_refuse_too_many_squares ]).

k7_grid_state_label(q_read_the_two_counts, illustrative_mathematics,
    "the number of groups and the number in each group",
    "IM Grade 3 Unit 1 Lesson 2, Represent Equal Groups").
k7_grid_state_label(q_run_the_existing_machine, provisional,
    "run the machine that already enacts this doing",
    "provisional; names this pilot's own wrapping step, not a community term").
k7_grid_state_label(q_read_the_rows_and_columns_off_the_trace, steffe,
    "the composite unit and its iteration",
    "Steffe 1992, Schemes of action and operation involving composite units; via knowledge/strategies/math/state_vocabulary.pl").
k7_grid_state_label(q_check_the_squares_match_the_count, provisional,
    "check the drawing holds as many squares as the machine counted",
    "provisional; no community label sourced for this checking step").
k7_grid_state_label(q_draw_the_array_of_unit_squares, illustrative_mathematics,
    "an array of objects arranged in rows and columns",
    "IM Grade 3 Unit 1 Lesson 8, Represent Arrays").
k7_grid_state_label(q_draw_the_array_of_unit_squares, van_de_walle,
    "tiling a rectangle with unit squares",
    "Van de Walle, ch. 19, Developing Measurement Concepts, area").
k7_grid_state_label(q_draw_the_student_count_beside_it, van_de_walle,
    "the student's own representation of the count",
    "Van de Walle, ch. 9, Developing Meanings for the Operations").
k7_grid_state_label(q_accept_the_drawing, provisional,
    "the drawing the machine's own run produced",
    "provisional; names this pilot's output, not a community term").
k7_grid_state_label(q_refuse_too_many_squares, provisional,
    "refuse a rectangle too large to draw as unit squares",
    "provisional; names this pilot's own drawable bound").

% ==========================================================================
% 3. TRANSITIONS
% ==========================================================================

k7_grid_transition(draw_the_count_as_unit_squares,
    q_read_the_two_counts, run_the_existing_machine, q_run_the_existing_machine).
k7_grid_transition(draw_the_count_as_unit_squares,
    q_run_the_existing_machine, read_the_rows_and_columns_off_the_trace,
    q_read_the_rows_and_columns_off_the_trace).
k7_grid_transition(draw_the_count_as_unit_squares,
    q_read_the_rows_and_columns_off_the_trace, check_the_squares_match_the_count,
    q_check_the_squares_match_the_count).
k7_grid_transition(draw_the_count_as_unit_squares,
    q_check_the_squares_match_the_count, draw_the_array_of_unit_squares,
    q_draw_the_array_of_unit_squares).
k7_grid_transition(draw_the_count_as_unit_squares,
    q_draw_the_array_of_unit_squares, accept_the_drawing, q_accept_the_drawing).
k7_grid_transition(draw_the_count_as_unit_squares,
    q_draw_the_array_of_unit_squares, draw_the_student_count_beside_it,
    q_draw_the_student_count_beside_it).
k7_grid_transition(draw_the_count_as_unit_squares,
    q_read_the_rows_and_columns_off_the_trace, refuse_too_many_squares,
    q_refuse_too_many_squares).

% ==========================================================================
% 4. THE RUN
% ==========================================================================

k7_drawable_square_bound(240).

run_k7_array_grid(draw_the_count_as_unit_squares,
                  grid_task(Doing, Operation, A, B), Outcome, Trace) :-
    k7_grid_doing(Doing, Operation, Classification),
    run_action_automaton(Operation, Doing, A, B, Inner, InnerTrace),
    Inner = action_outcome(Doing, Properties),
    grid_reading(Doing, InnerTrace, Properties, Reading),
    reading_rows_columns(Reading, Rows, Columns),
    Squares is Rows * Columns,
    k7_drawable_square_bound(Bound),
    (   Squares > Bound
    ->  refusal_outcome(Doing, A, B, Squares, Bound, Outcome, Trace)
    ;   scene(Doing, Reading, Scene),
        squares_check(Reading, Scene, CheckName, Verdict),
        ( Verdict == holds -> Validity0 = certified ; Validity0 = unvindicated ),
        machine_validity(Classification, Validity0, Validity),
        reading_counts(Reading, DrawnCount, ExpectedCount),
        deformation_fields(Doing, Operation, Properties, Extra),
        Outcome = action_outcome(
            draw_the_count_as_unit_squares,
            [ classification(Classification),
              cluster(k7_array_grid),
              automaton_state(q_accept_the_drawing),
              vocabulary([array, row, column, unit_square, square_unit,
                          equal_group, composite_unit, area, boundary]),
              input(grid_task(Doing, Operation, A, B)),
              drawn_doing(Doing),
              wrapped_machine(Operation/Doing),
              reading(Reading),
              rows(Rows), columns(Columns),
              squares_drawn(DrawnCount),
              count_the_machine_named(ExpectedCount),
              squares_check(CheckName, Verdict),
              scene(Scene),
              validity(Validity)
            | Extra ]),
        Trace = [ read_the_two_counts(A, B),
                  run_the_existing_machine(Operation/Doing),
                  read_the_rows_and_columns_off_the_trace(Rows, Columns),
                  check_the_squares_match_the_count(CheckName, Verdict),
                  draw_the_array_of_unit_squares(Scene),
                  accept_the_drawing(DrawnCount) ]
    ).

refusal_outcome(Doing, A, B, Squares, Bound, Outcome, Trace) :-
    Outcome = action_outcome(
        draw_the_count_as_unit_squares,
        [ classification(refusal),
          cluster(k7_array_grid),
          automaton_state(q_refuse_too_many_squares),
          vocabulary([array, unit_square, drawable_bound]),
          input(grid_task(Doing, _, A, B)),
          result(refused(rectangle_too_large_to_draw_as_unit_squares)),
          refusal(refusal{kind: "square_count_exceeds_drawable_bound",
                          squares: Squares, bound: Bound}),
          validity(refused) ]),
    Trace = [ read_the_two_counts(A, B),
              refuse_too_many_squares(Squares, Bound) ].

%   A productive run whose drawing checks out is `correct`; a deformation's
%   drawing checking out does not make the deformation correct, so its own
%   verdict is carried through unchanged.
machine_validity(deformation, certified, incorrect).
machine_validity(productive, certified, correct).
machine_validity(_, unvindicated, unvindicated).

deformation_fields(Doing, Operation, Properties, Extra) :-
    memberchk(classification(deformation), Properties),
    !,
    memberchk(deformation_of(Productive), Properties),
    memberchk(expected(Expected), Properties),
    memberchk(result(Result), Properties),
    ( memberchk(misconception_family(Family), Properties)
    -> FamilyPart = [misconception_family(Family)]
    ;  memberchk(violated_invariant(Invariant), Properties),
       FamilyPart = [violated_invariant(Invariant)] ),
    attested_as(Doing, Row, Source),
    append([ [ result(Result), expected(Expected),
               deformation_of(Productive),
               productive_partner(Operation/Productive),
               attested_as(Row, Source) ], FamilyPart ], Extra).
deformation_fields(_, _, Properties, [result(Result), expected(Expected)]) :-
    memberchk(result(Result), Properties),
    memberchk(expected(Expected), Properties).

%!  attested_as(?Deformation, ?Row, ?Source) is nondet.
%
%   The citation the existing deformation machine already carries, repeated so
%   a reader of this file can find it without leaving it.
attested_as(add_instead_of_multiply,
    misconception_family(addition_instead_of_multiplication),
    "Carried by knowledge/strategies/math/smr_mult_action_pairs.pl as the deformation partner of repeat_equal_groups; IM Grade 3 Unit 1 Lesson 12 carries rows tagged with this deformation in the defrag pool.").
attested_as(add_counts_without_composite_unit,
    misconception_family(additive_count_for_multiplicative_structure),
    "Carried by knowledge/strategies/math/smr_mult_action_pairs.pl as the deformation partner of coordinate_groups_items.").
attested_as(area_as_perimeter_count,
    violated_invariant(area_counts_interior_square_units),
    "Carried by knowledge/strategies/math/geometry_action_pairs.pl as the deformation partner of rectangle_area_unit_iteration.").

% --- reading the rectangle off each machine's own trace -------------------

%!  grid_reading(+Doing, +Trace, +Properties, -Reading) is semidet.
grid_reading(repeat_equal_groups, Trace, Properties,
             array(Groups, Size, Total)) :-
    memberchk(hold_group_size_as_repeated_addend(Size), Trace),
    memberchk(hold_number_of_groups_as_iterations(Groups), Trace),
    memberchk(name_accumulated_total(Total), Trace),
    memberchk(result(Total), Properties).
grid_reading(coordinate_groups_items, Trace, Properties,
             array(Groups, Size, Total)) :-
    memberchk(coordinate_group_count_with_item_count(groups(Groups),
                                                     items_per_group(Size)),
              Trace),
    memberchk(name_total_items(Total), Trace),
    memberchk(result(Total), Properties).
grid_reading(rectangle_area_unit_iteration, Trace, Properties,
             array(Rows, Columns, Area)) :-
    memberchk(establish_rectangle(Rows, Columns), Trace),
    memberchk(count_square_units(Area), Trace),
    memberchk(result(square_units(Area)), Properties).
grid_reading(add_instead_of_multiply, Trace, Properties,
             array_and_strip(Groups, Size, Expected, Sum)) :-
    memberchk(read_equal_groups(groups(Groups), items_per_group(Size)), Trace),
    memberchk(add_uncoordinated_counts(_, _, Sum), Trace),
    memberchk(result(Sum), Properties),
    memberchk(expected(Expected), Properties).
grid_reading(add_counts_without_composite_unit, Trace, Properties,
             array_and_strip(Groups, Size, Expected, Sum)) :-
    memberchk(see_groups_and_items(groups(Groups), items_per_group(Size)),
              Trace),
    memberchk(add_uncoordinated_counts(_, _, Sum), Trace),
    memberchk(result(Sum), Properties),
    memberchk(expected(Expected), Properties).
grid_reading(area_as_perimeter_count, Trace, Properties,
             array_and_boundary(Rows, Columns, Area, Boundary)) :-
    memberchk(establish_rectangle(Rows, Columns), Trace),
    memberchk(traverse_boundary_instead(Boundary), Trace),
    memberchk(result(boundary_units(Boundary)), Properties),
    memberchk(expected(square_units(Area)), Properties).

reading_rows_columns(array(R, C, _), R, C).
reading_rows_columns(array_and_strip(R, C, _, _), R, C).
reading_rows_columns(array_and_boundary(R, C, _, _), R, C).

%!  reading_counts(+Reading, -Drawn, -Named) is det.
%
%   What the drawing holds, and what the machine said. For a productive run
%   these agree by construction and the check proves it. For a deformation
%   the drawing holds the student's count and the machine's `expected` is
%   drawn beside it.
reading_counts(array(R, C, Total), Squares, Total) :- Squares is R * C.
reading_counts(array_and_strip(_, _, _, Sum), Sum, Sum).
reading_counts(array_and_boundary(_, _, _, Boundary), Boundary, Boundary).

% --- the check on the drawing --------------------------------------------

%!  squares_check(+Reading, +Scene, -Name, -Verdict) is det.
%
%   Counted off the scene itself, not off the reading that built it: the
%   points and lines are re-tallied from the emitted dict, so a builder that
%   dropped or added a square fails here.
squares_check(array(Rows, Columns, Total), Scene,
              every_unit_square_drawn_is_one_the_machine_counted, Verdict) :-
    get_dict(points, Scene, Points), length(Points, PointCount),
    get_dict(lines, Scene, Lines), length(Lines, LineCount),
    Expected is Rows * Columns,
    (   PointCount =:= Total,
        PointCount =:= Expected,
        LineCount =:= (Rows + 1) + (Columns + 1)
    ->  Verdict = holds
    ;   Verdict = fails
    ).
squares_check(array_and_strip(Rows, Columns, Expected, Sum), Scene,
              the_array_and_the_strip_each_hold_their_own_count, Verdict) :-
    get_dict(points, Scene, Points),
    k7_colour(productive, ProductiveColour),
    k7_colour(student, StudentColour),
    include([P]>>(get_dict(color, P, ProductiveColour)), Points, ArrayPoints),
    include([P]>>(get_dict(color, P, StudentColour)), Points, StripPoints),
    length(ArrayPoints, ArrayCount), length(StripPoints, StripCount),
    Product is Rows * Columns,
    (   ArrayCount =:= Product,
        ArrayCount =:= Expected,
        StripCount =:= Sum,
        Sum =\= Expected
    ->  Verdict = holds
    ;   Verdict = fails
    ).
squares_check(array_and_boundary(Rows, Columns, Area, Boundary), Scene,
              the_interior_and_the_boundary_each_hold_their_own_count,
              Verdict) :-
    get_dict(points, Scene, Points), length(Points, PointCount),
    get_dict(lines, Scene, Lines), length(Lines, LineCount),
    Product is Rows * Columns,
    Perimeter is 2 * (Rows + Columns),
    (   PointCount =:= Product,
        PointCount =:= Area,
        LineCount =:= Perimeter,
        LineCount =:= Boundary,
        Boundary =\= Area
    ->  Verdict = holds
    ;   Verdict = fails
    ).

% ==========================================================================
% 5. THE DRAWING
% ==========================================================================

%!  scene(+Doing, +Reading, -Scene) is det.
scene(Doing, array(Rows, Columns, Total), Scene) :-
    k7_colour(productive, Colour),
    k7_colour(structure, LineColour),
    grid_lines(Rows, Columns, 0, LineColour, Lines),
    cell_points(Rows, Columns, 0, Colour, Points),
    format(string(Id), "k7-array-~w", [Doing]),
    format(string(Title), "~w by ~w, drawn as unit squares", [Rows, Columns]),
    format(string(Description),
           "~w rows of ~w unit squares, one point per square, ~w squares in all.",
           [Rows, Columns, Total]),
    Scene = scene{version: 1, id: Id, kind: "coordinate-plane",
                  title: Title, description: Description,
                  points: Points, lines: Lines}.
scene(Doing, array_and_strip(Rows, Columns, Expected, Sum), Scene) :-
    k7_colour(productive, ArrayColour),
    k7_colour(student, StripColour),
    k7_colour(structure, LineColour),
    grid_lines(Rows, Columns, 0, LineColour, ArrayLines),
    cell_points(Rows, Columns, 0, ArrayColour, ArrayPoints),
    StripBase is -3,
    grid_lines(1, Sum, StripBase, StripColour, StripLines),
    cell_points(1, Sum, StripBase, StripColour, StripPoints),
    append(ArrayLines, StripLines, Lines),
    append(ArrayPoints, StripPoints, Points),
    format(string(Id), "k7-array-strip-~w", [Doing]),
    format(string(Title),
           "~w by ~w coordinated, and ~w counted end to end", [Rows, Columns, Sum]),
    format(string(Description),
           "Above: ~w rows of ~w unit squares, ~w in all. Below: the same two numbers laid end to end as ~w squares.",
           [Rows, Columns, Expected, Sum]),
    Scene = scene{version: 1, id: Id, kind: "coordinate-plane",
                  title: Title, description: Description,
                  points: Points, lines: Lines}.
scene(Doing, array_and_boundary(Rows, Columns, Area, Boundary), Scene) :-
    k7_colour(productive, InteriorColour),
    k7_colour(student, BoundaryColour),
    boundary_unit_segments(Rows, Columns, BoundaryColour, Lines),
    cell_points(Rows, Columns, 0, InteriorColour, Points),
    format(string(Id), "k7-array-boundary-~w", [Doing]),
    format(string(Title),
           "~w square units inside, ~w unit segments around", [Area, Boundary]),
    format(string(Description),
           "The ~w unit squares covering a ~w by ~w rectangle, and the ~w unit segments traced around its edge.",
           [Area, Rows, Columns, Boundary]),
    Scene = scene{version: 1, id: Id, kind: "coordinate-plane",
                  title: Title, description: Description,
                  points: Points, lines: Lines}.

%!  grid_lines(+Rows, +Columns, +Base, +Colour, -Lines) is det.
%
%   The closed grid: one horizontal line per row boundary and one vertical
%   line per column boundary, so a rectangle of R rows and C columns is drawn
%   by R+1 and C+1 lines.
grid_lines(Rows, Columns, Base, Colour, Lines) :-
    Top is Rows,
    findall(L,
            ( between(0, Rows, R),
              Y is Base + R,
              k7_segment(0, Y, Columns, Y, Colour, L) ),
            Horizontal),
    findall(L,
            ( between(0, Columns, C),
              YTop is Base + Top,
              YBase is Base,
              k7_segment(C, YBase, C, YTop, Colour, L) ),
            Vertical),
    append(Horizontal, Vertical, Lines).

%!  cell_points(+Rows, +Columns, +Base, +Colour, -Points) is det.
%
%   One point at the middle of every unit square, which is what makes the
%   count in the picture countable.
cell_points(Rows, Columns, Base, Colour, Points) :-
    findall(P,
            ( between(1, Rows, R), between(1, Columns, C),
              X is C - 1r2,
              Y is Base + R - 1r2,
              k7_point(X, Y, Colour, P) ),
            Points).

%!  boundary_unit_segments(+Rows, +Columns, +Colour, -Lines) is det.
%
%   The 2*(Rows+Columns) unit-length segments a boundary traversal counts,
%   drawn one at a time so the picture holds exactly the count the machine
%   reported.
boundary_unit_segments(Rows, Columns, Colour, Lines) :-
    findall(L,
            ( between(1, Columns, C),
              From is C - 1,
              member(Y, [0, Rows]),
              unit_label(Colour, Label),
              k7_labelled_segment(From, Y, C, Y, Label, Colour, L) ),
            Horizontal),
    findall(L,
            ( between(1, Rows, R),
              From is R - 1,
              member(X, [0, Columns]),
              unit_label(Colour, Label),
              k7_labelled_segment(X, From, X, R, Label, Colour, L) ),
            Vertical),
    append(Horizontal, Vertical, Lines).

unit_label(_, "1").

%!  k7_grid_scene(+Outcome, -JSON) is semidet.
k7_grid_scene(action_outcome(_, Properties), JSON) :-
    memberchk(scene(Scene), Properties),
    k7_scene_json(Scene, JSON).

:- use_module(library(yall)).
:- use_module(library(apply), [include/3]).

% ==========================================================================
% 6. SELF-SUMMARY
% ==========================================================================

k7_grid_summary(
    summary{ module: k7_array_grid,
             status: authored_pilot,
             generated: false,
             grades: 'K-7',
             cluster: k7_array_grid,
             doings: [draw_the_count_as_unit_squares],
             wraps: [ multiplication/repeat_equal_groups,
                      multiplication/coordinate_groups_items,
                      multiplication/add_instead_of_multiply,
                      multiplication/add_counts_without_composite_unit,
                      geometry/rectangle_area_unit_iteration,
                      geometry/area_as_perimeter_count ],
             modifies_wrapped_machines: false,
             verification: [ every_unit_square_drawn_is_one_the_machine_counted,
                             the_grid_closes_at_one_more_line_than_rows_and_columns,
                             a_deformation_draws_its_own_count_and_the_expected_one,
                             scene_renders_through_the_coordinate_plane_grapher ],
             arithmetic: exact_integer,
             renderer: 'hermes/web/coordinate-plane/grapher.js (schema version 1)',
             deformation_draws_too: true,
             drawable_square_bound: 240,
             imported_by: none }).

% ==========================================================================
% 7. RECEIPTS
% ==========================================================================

% k7_grid_receipt(Row, Lesson, Doing, InputJSONDict, ExpectedDrawnCount, Note).
k7_grid_receipt(
    'im_defrag_af8d3ebeaed8af6e1779d9ee_1', 'IM-G3-U1-L12',
    repeat_equal_groups,
    _{kind: "array_grid", doing: "repeat_equal_groups", a: 3, b: 5},
    15, row_numbers).
k7_grid_receipt(
    'im_defrag_405bcea9deb44dd1669b06b7_1', 'IM-G3-U1-L12',
    repeat_equal_groups,
    _{kind: "array_grid", doing: "repeat_equal_groups", a: 4, b: 5},
    20, row_numbers).
k7_grid_receipt(
    'im_defrag_8af47c38f3dd84b44564024a_1', 'IM-G3-U1-L12',
    repeat_equal_groups,
    _{kind: "array_grid", doing: "repeat_equal_groups", a: 3, b: 10},
    30, row_numbers).
k7_grid_receipt(
    'im_defrag_c9c02d97fa8109096552f207_1', 'IM-G3-U1-L10',
    coordinate_groups_items,
    _{kind: "array_grid", doing: "coordinate_groups_items", a: 4, b: 2},
    8, row_numbers).
k7_grid_receipt(
    'im_defrag_bd8ccbd23a46ade715940827_1', 'IM-G3-U1-L12',
    coordinate_groups_items,
    _{kind: "array_grid", doing: "coordinate_groups_items", a: 4, b: 2},
    8, row_numbers).
k7_grid_receipt(
    'im_defrag_e7d4414bae4b81f4d3127d2f_1', 'IM-G3-U1-L12',
    add_instead_of_multiply,
    _{kind: "array_grid", doing: "add_instead_of_multiply", a: 3, b: 5},
    8, row_is_itself_a_deformation_row).
k7_grid_receipt(
    'im_defrag_65a98355f78d304e1505062d_1', 'IM-G3-U1-L12',
    add_instead_of_multiply,
    _{kind: "array_grid", doing: "add_instead_of_multiply", a: 4, b: 2},
    6, row_is_itself_a_deformation_row).
k7_grid_receipt(
    'im_defrag_c08782233b6bcb5cc3dcb23e_1', 'IM-G3-U1-L12',
    add_instead_of_multiply,
    _{kind: "array_grid", doing: "add_instead_of_multiply", a: 5, b: 10},
    15, row_is_itself_a_deformation_row).
k7_grid_receipt(
    'im_defrag_0faad87f0d143d9b121ea13f_1', 'IM-G3-U1-L12',
    add_instead_of_multiply,
    _{kind: "array_grid", doing: "add_instead_of_multiply", a: 7, b: 2},
    9, row_is_itself_a_deformation_row).
k7_grid_receipt(
    'im_defrag_b3ba9772539620b1c7d04ff8_1', 'IM-G3-U1-L12',
    add_instead_of_multiply,
    _{kind: "array_grid", doing: "add_instead_of_multiply", a: 3, b: 10},
    13, row_is_itself_a_deformation_row).
% The compare-areas row carries two rectangles in its own numbers; each is a
% receipt, and the row id appears twice for that reason.
k7_grid_receipt(
    'im_defrag_f814df555f748faf892da9ac_1', 'IM-G3-U2-L10',
    rectangle_area_unit_iteration,
    _{kind: "array_grid", doing: "rectangle_area_unit_iteration", a: 9, b: 2},
    18, row_numbers).
k7_grid_receipt(
    'im_defrag_f814df555f748faf892da9ac_1', 'IM-G3-U2-L10',
    rectangle_area_unit_iteration,
    _{kind: "array_grid", doing: "rectangle_area_unit_iteration", a: 4, b: 5},
    20, row_numbers).
% Three rows print an AREA and ask for side lengths rather than printing them.
% The pair drawn is not invented: it is one the extant
% geometry/rectangle_factor_pair_search returns on that row own number, and
% check_side_lengths_come_from_the_extant_search proves it for each.
% IM-G3-U2-L3 asks for the drawing in its own words: "Draw a rectangle with an
% area of 8 square units on the grid."
k7_grid_receipt(
    'im_defrag_76e618d31f8ca00ca037e327_1', 'IM-G3-U2-L3',
    rectangle_area_unit_iteration,
    _{kind: "array_grid", doing: "rectangle_area_unit_iteration", a: 2, b: 4},
    8, factor_pair_from_the_extant_search_on_the_row_area).
k7_grid_receipt(
    'im_defrag_a30d4dc40106c2480a511f14_1', 'IM-G4-U1-L2',
    rectangle_area_unit_iteration,
    _{kind: "array_grid", doing: "rectangle_area_unit_iteration", a: 3, b: 7},
    21, factor_pair_from_the_extant_search_on_the_row_area).
k7_grid_receipt(
    'im_defrag_fa6632bf91c417d284805a88_1', 'IM-G4-U1-L2',
    rectangle_area_unit_iteration,
    _{kind: "array_grid", doing: "rectangle_area_unit_iteration", a: 5, b: 10},
    50, factor_pair_from_the_extant_search_on_the_row_area).
% The boundary reading is a machine that already exists; this row supplies its
% numbers. The row does not attest that a student made this reading.
k7_grid_receipt(
    'im_defrag_f814df555f748faf892da9ac_1', 'IM-G3-U2-L10',
    area_as_perimeter_count,
    _{kind: "array_grid", doing: "area_as_perimeter_count", a: 4, b: 5},
    18, machine_exists_row_supplies_numbers).

% ==========================================================================
% 8. CHECK
% ==========================================================================

check_k7_array_grid :-
    check_receipts,
    check_scenes_render,
    check_squares_counted_off_the_scene,
    check_deformations_draw_their_own_count,
    check_side_lengths_come_from_the_extant_search,
    check_negative,
    format('k7_array_grid: all checks ok~n').

check_receipts :-
    findall(Lesson-Row-Drawn,
            ( k7_grid_receipt(Row, Lesson, Doing, Json, Drawn, _),
              k7_grid_from_json(Json, Task),
              Task = grid_task(Doing, _, _, _),
              run_k7_array_grid(draw_the_count_as_unit_squares, Task, Outcome, _),
              outcome_property(Outcome, drawn_doing(Doing)),
              outcome_property(Outcome, squares_drawn(Drawn)),
              outcome_property(Outcome, squares_check(_, holds))
            ), Passed),
    findall(R, k7_grid_receipt(R, _, _, _, _, _), All),
    length(All, Total), length(Passed, Count),
    Total =:= Count,
    format('  receipts: ~w/~w rectangles drawn, every square count re-tallied off the emitted scene~n',
           [Count, Total]),
    forall(member(Lesson-Row-Drawn, Passed),
           format('    ~w  ~w  ~w squares~n', [Lesson, Row, Drawn])).

check_scenes_render :-
    findall(JSON,
            ( k7_grid_receipt(_, _, _, Json, _, _),
              k7_grid_from_json(Json, Task),
              run_k7_array_grid(draw_the_count_as_unit_squares, Task, Outcome, _),
              k7_grid_scene(Outcome, JSON)
            ), Scenes),
    length(Scenes, Count),
    k7_render_scenes(Scenes),
    format('  drawings: ~w scenes rendered through hermes/web/coordinate-plane without error~n',
           [Count]).

check_squares_counted_off_the_scene :-
    % A 4 by 5 array holds 20 points and closes with 5 horizontal and 6
    % vertical lines. Counted here from the dict, not from the numbers that
    % built it.
    k7_grid_from_json(
        _{kind: "array_grid", doing: "repeat_equal_groups", a: 4, b: 5}, T),
    run_k7_array_grid(draw_the_count_as_unit_squares, T, O, _),
    outcome_property(O, scene(Scene)),
    get_dict(points, Scene, Points), length(Points, 20),
    get_dict(lines, Scene, Lines), length(Lines, 11),
    % every point sits at the middle of a unit square, so no two coincide
    findall(X-Y, ( member(P, Points), get_dict(x, P, X), get_dict(y, P, Y) ),
            Coords),
    sort(Coords, Sorted), length(Sorted, 20),
    format('  the drawing is countable: 20 distinct square middles and 11 grid lines for a 4 by 5 array~n').

check_deformations_draw_their_own_count :-
    % 3 groups of 5 make 15; the reading that adds the two counts makes 8.
    % Both are drawn, each holding its own count, and the machine's own
    % expected value is what the array holds.
    k7_grid_from_json(
        _{kind: "array_grid", doing: "add_instead_of_multiply", a: 3, b: 5}, T),
    run_k7_array_grid(draw_the_count_as_unit_squares, T, O, _),
    outcome_property(O, classification(deformation)),
    outcome_property(O, result(8)),
    outcome_property(O, expected(15)),
    outcome_property(O, validity(incorrect)),
    outcome_property(O, productive_partner(multiplication/repeat_equal_groups)),
    outcome_property(O, attested_as(_, _)),
    outcome_property(O, scene(Scene)),
    get_dict(points, Scene, Points), length(Points, 23),
    % the boundary reading draws 18 interior squares and 18 edge segments,
    % which is the disagreement the machine reported
    k7_grid_from_json(
        _{kind: "array_grid", doing: "area_as_perimeter_count", a: 4, b: 5}, B),
    run_k7_array_grid(draw_the_count_as_unit_squares, B, BO, _),
    outcome_property(BO, result(boundary_units(18))),
    outcome_property(BO, expected(square_units(20))),
    outcome_property(BO, scene(BScene)),
    get_dict(points, BScene, BPoints), length(BPoints, 20),
    get_dict(lines, BScene, BLines), length(BLines, 18),
    format('  the deformation draws too: 15 squares in the array beside 8 laid end to end, and 20 interior squares beside 18 edge segments~n').

check_side_lengths_come_from_the_extant_search :-
    % Three receipts draw a rectangle whose sides the row does not print. Each
    % pair is one the extant factor-pair machine returns on the row own area,
    % run here rather than asserted.
    forall(member(Area-(Rows-Columns), [8-(2-4), 21-(3-7), 50-(5-10)]),
           ( run_action_automaton(geometry, rectangle_factor_pair_search,
                                  Area, factor_scope(all),
                                  action_outcome(_, Props), _),
             memberchk(factor_pairs(Pairs), Props),
             memberchk(Rows-Columns, Pairs),
             Product is Rows * Columns, Product =:= Area )),
    format('  the side lengths the rows do not print come from the extant factor search: 2 by 4 in 8, 3 by 7 in 21, 5 by 10 in 50~n').

check_negative :-
    % Grade 5's 600 by 500 is a true product and a false drawing.
    k7_grid_from_json(
        _{kind: "array_grid", doing: "repeat_equal_groups", a: 600, b: 500}, Big),
    run_k7_array_grid(draw_the_count_as_unit_squares, Big, BigOutcome, _),
    outcome_property(BigOutcome, validity(refused)),
    outcome_property(BigOutcome, refusal(_)),
    % A doing this pilot does not wrap refuses at decode.
    \+ k7_grid_from_json(
           _{kind: "array_grid", doing: "long_division", a: 24, b: 8}, _),
    % A zero-sided rectangle refuses at decode rather than drawing nothing.
    \+ k7_grid_from_json(
           _{kind: "array_grid", doing: "repeat_equal_groups", a: 0, b: 5}, _),
    % The square check discriminates: an array claiming a count it does not
    % hold fails.
    k7_grid_from_json(
        _{kind: "array_grid", doing: "repeat_equal_groups", a: 3, b: 5}, T),
    run_k7_array_grid(draw_the_count_as_unit_squares, T, O, _),
    outcome_property(O, scene(S)),
    squares_check(array(3, 5, 16), S, _, fails),
    format('  negative tests: 600 by 500 refuses by name; an unwrapped doing and a zero side refuse at decode; a miscounted array fails the square check~n').

outcome_property(action_outcome(_, Props), Property) :-
    memberchk(Property, Props).
