/** <module> Gate for the geometry enactment lane
 *
 * Loads curriculum/im/enactment/geometry_construction.pl strictly and asserts
 * four things the lane cannot be trusted without:
 *
 *   1. Every lesson in the subclass runs to an enactment with a verdict.
 *   2. Every step verb is a declared `enactment_move` at its own index.
 *   3. Every enactment serializes into the dict shape
 *      `hermes_encyclopedia:strategy_trace_dict/3` returns, with the keys that
 *      predicate's consumers read.
 *   4. The figure algebra still computes the three results the lane rests on:
 *      35 hexominoes with 11 folding to a cube, no equilateral triangle on the
 *      lattice, and exact symmetry counts on the canonical inventory.
 *
 *   swipl -q -l paths.pl -s scripts/checks/geometry_enactment.pl -g main -t halt
 */

:- use_module(im_lessons('enactment/geometry_construction')).
:- use_module(im_lessons('enactment/support/geometry_figures')).
:- use_module(library(lists)).

main :-
    check_every_lesson_runs,
    check_moves_declared,
    check_trace_dict_shape,
    check_figure_algebra.

fail_with(Format, Args) :-
    format(Format, Args), nl,
    halt(1).

check_every_lesson_runs :-
    geometry_construction:geometry_lane_coverage(
        report(Total, WellFormed, Partial, Refused, Failed, _)),
    (   Failed =:= 0
    ->  true
    ;   fail_with("FAIL ~w lessons have no runner for their form", [Failed])
    ),
    Enacted is WellFormed + Partial + Refused,
    (   Enacted =:= Total
    ->  format("PASS ~w of ~w subclass lessons enact: ~w well formed, ~w partial, ~w refused~n",
               [Enacted, Total, WellFormed, Partial, Refused])
    ;   fail_with("FAIL ~w of ~w lessons enact", [Enacted, Total])
    ).

check_moves_declared :-
    geometry_construction:lane_move_audit(Declared, Undeclared),
    (   Undeclared == []
    ->  format("PASS ~w step verbs are declared moves at their own index~n", [Declared])
    ;   length(Undeclared, N),
        fail_with("FAIL ~w step verbs are undeclared: ~p", [N, Undeclared])
    ).

check_trace_dict_shape :-
    geometry_construction:geometry_lane_lessons(Lessons),
    findall(Lesson,
            ( member(Lesson, Lessons),
              geometry_construction:lesson_inputs(Lesson, _, Inputs),
              geometry_construction:enact(Lesson, Inputs, Enactment),
              geometry_construction:enactment_trace_dict(Enactment, Dict),
              \+ trace_dict_well_formed(Dict) ),
            Bad),
    (   Bad == []
    ->  length(Lessons, N),
        format("PASS ~w enactments serialize into the strategy-trace dict shape~n", [N])
    ;   fail_with("FAIL these enactments do not serialize: ~p", [Bad])
    ).

trace_dict_well_formed(Dict) :-
    forall(member(Key, [strategy, ok, representation, result, steps, jumps, note]),
           get_dict(Key, Dict, _)),
    get_dict(steps, Dict, Steps),
    Steps \== [],
    forall(member(Step, Steps),
           forall(member(K, [n, label, value]), get_dict(K, Step, _))),
    get_dict(jumps, Dict, Jumps),
    is_list(Jumps).

check_figure_algebra :-
    findall(H, geometry_figures:hexomino(H), All),
    length(All, NAll),
    include(geometry_figures:cube_net_foldable, All, Folders),
    length(Folders, NFold),
    (   NAll =:= 35, NFold =:= 11
    ->  format("PASS the polyomino generator yields 35 hexominoes and the cube roll finds 11 nets~n", [])
    ;   fail_with("FAIL hexominoes=~w folding=~w; the generator or the roll changed", [NAll, NFold])
    ),
    (   \+ ( geometry_figures:canonical_figure(_, _, Vs),
             geometry_figures:fig_sides(Vs, 3),
             geometry_figures:fig_attribute(Vs, all_sides_equal) )
    ->  format("PASS no triangle in the inventory has three equal sides, as the lattice requires~n", [])
    ;   fail_with("FAIL an inventory triangle reports three equal sides on the integer lattice", [])
    ),
    (   geometry_figures:canonical_figure(sq_4, _, Square),
        geometry_figures:fig_symmetry_axis_count(Square, 4),
        geometry_figures:canonical_figure(rect_6x3, _, Rect),
        geometry_figures:fig_symmetry_axis_count(Rect, 2),
        geometry_figures:canonical_figure(trapezoid_iso, _, Trap),
        geometry_figures:fig_symmetry_axis_count(Trap, 1),
        geometry_figures:canonical_figure(parallelo_1, _, Para),
        geometry_figures:fig_symmetry_axis_count(Para, 0)
    ->  format("PASS symmetry counts hold: square 4, rectangle 2, isosceles trapezoid 1, parallelogram 0~n", [])
    ;   fail_with("FAIL the symmetry counts on the canonical inventory changed", [])
    ).
