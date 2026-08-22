% render_spec_gate.pl — 2026-08-18 recovery wave, render_spec mode.
%
% A minimal, standalone executable gate for the render_spec mode's G3 (spec
% EXECUTES). It does NOT load hermes_worker.pl. It loads paths.pl (the file
% search path setup every module already depends on) and only the ONE render
% scene module the request names, then reconstructs the request -> Spec
% translation the worker performs at dispatch time — the small `*_spec/2`
% family and their `request_*` helpers, ported here verbatim from
% hermes_worker.pl (2026-08-18 read, lines 2247-2986) since those predicates
% live in the worker file itself and are not independently importable.
%
% Usage: swipl scripts/coverage/render_spec_gate.pl --root ROOT < request.json
%   stdin:  {"op": "area_render", "request": {"kind": "array_multiplication",
%            "a": 3, "b": 4}}
%   stdout: {"ok": true, "frame_count": 1} on success, or
%           {"ok": false, "reason": "..."} on any failure — a spec that fails
%           to build, a compiler that raises, or a document whose frames list
%           is empty (the render contract's own "explicit error document"
%           convention) are all reported false, never faked as true.
%
% This script never writes anything and never calls a model; it executes
% Prolog code that already ships in the repo, on inputs a model proposed.
%
% 2026-08-18 coverage-grind addendum: ratio_diagram_render and
% measurement_strip_render were wired into hermes_worker.pl's
% dispatch_irregular/1 table today (:303, :314). Their op_module/2,
% call_render/3, build_spec/3, and *_spec/2 clauses below are ported
% verbatim from hermes_worker.pl (2026-08-18 read, dispatch_request
% clauses :1007-1015/:1089-1097, spec builders :2761-2769/:2863-2870) the
% same way the original 13 were.

:- use_module(library(http/json)).

:- initialization(main, main).

main(Argv) :-
    ( select('--root', Argv, Argv1), Argv1 = [Root|_]
    -> true
    ;  Root = '.'
    ),
    catch(run(Root), E, report_fatal(E)).

run(Root) :-
    directory_file_path(Root, 'paths.pl', PathsFile),
    ( exists_file(PathsFile) -> consult(PathsFile) ; throw(error(missing_paths_file(PathsFile), _)) ),
    read_stdin_json(Request0),
    ( is_dict(Request0) -> Request = Request0 ; throw(error(bad_request_json, _)) ),
    ( get_dict(op, Request, OpRaw) -> to_atom(OpRaw, Op) ; throw(error(missing_op, _)) ),
    ( get_dict(request, Request, ArgsDict) -> true
    ; ArgsDict = _{} ),
    ( op_module(Op, Module) -> true
    ; throw(error(unsupported_op(Op), _)) ),
    use_module(Module, []),
    ( build_spec(Op, ArgsDict, Spec)
    -> true
    ;  throw(error(spec_build_failed(Op), _))
    ),
    ( call_render(Op, Spec, Dict)
    -> true
    ;  throw(error(compiler_failed(Op), _))
    ),
    ( frames_of(Dict, Frames), is_list(Frames), Frames \== []
    -> length(Frames, N),
       reply_ok(N)
    ;  reply_fail(empty_frames)
    ).

report_fatal(error(Formal, _)) :- !, term_string(Formal, S), reply_fail(S).
report_fatal(E) :- term_string(E, S), reply_fail(S).

reply_ok(N) :-
    format('{"ok": true, "frame_count": ~w}~n', [N]).
reply_fail(Reason) :-
    format(atom(A), "~w", [Reason]),
    json_escape(A, Esc),
    format('{"ok": false, "reason": "~w"}~n', [Esc]).

json_escape(A, Esc) :-
    atom_string(A, S0),
    split_string(S0, "\"", "", Parts),
    atomic_list_concat(Parts, '\\"', Esc0),
    atom_string(Esc, Esc0).

% --- stdin JSON ---------------------------------------------------------
read_stdin_json(Dict) :-
    read_string(user_input, _, Text),
    ( Text == "" -> throw(error(empty_stdin, _)) ; true ),
    atom_json_dict(Text, Dict, [value_string_as(string)]).

% --- op -> module --------------------------------------------------------
op_module(area_render, render(area_model_scene)).
op_module(base_ten_render, render(base_ten_scene)).
op_module(set_grouping_render, render(set_grouping_scene)).
op_module(number_line_render, render(number_line_scene)).
op_module(coordinate_plane_render, render(coordinate_plane_scene)).
op_module(rigid_motion_render, render(rigid_motion_scene)).
op_module(polyform_tiling_render, render(polyform_tiling_scene)).
op_module(angle_circular_render, render(angle_circular_scene)).
op_module(data_display_render, render(data_display_scene)).
op_module(solid_net_render, render(solid_net_scene)).
op_module(geoboard_render, render(geoboard_scene)).
op_module(notation_render, render(notation_scene)).
op_module(balance_render, render(balance_scale_scene)).
op_module(ratio_diagram_render, render(ratio_diagram_scene)).
op_module(measurement_strip_render, render(measurement_strip_scene)).

% --- op -> compiler call ---------------------------------------------------
call_render(area_render, Spec, Dict) :-
    area_model_scene:area_render_json(Spec, Dict).
call_render(base_ten_render, Spec, Dict) :-
    base_ten_scene:base_ten_render_json(Spec, Dict).
call_render(set_grouping_render, Spec, Dict) :-
    set_grouping_scene:set_grouping_render_json(Spec, Dict).
call_render(number_line_render, Spec, Dict) :-
    number_line_scene:number_line_render_json(Spec, Dict).
call_render(coordinate_plane_render, Spec, Dict) :-
    coordinate_plane_scene:coordinate_plane_render_json(Spec, Dict).
call_render(rigid_motion_render, Spec, Dict) :-
    rigid_motion_scene:rigid_motion_render_json(Spec, Dict).
call_render(polyform_tiling_render, Spec, Dict) :-
    polyform_tiling_scene:polyform_tiling_render_json(Spec, Dict).
call_render(angle_circular_render, Spec, Dict) :-
    angle_circular_scene:angle_circular_render_json(Spec, Dict).
call_render(data_display_render, Spec, Dict) :-
    data_display_scene:data_display_render_json(Spec, Dict).
call_render(solid_net_render, Spec, Dict) :-
    solid_net_scene:solid_net_render_json(Spec, Dict).
call_render(geoboard_render, Spec, Dict) :-
    geoboard_scene:geoboard_render_json(Spec, Dict).
% glyph_overwrite renders through the parametric deformation module, the same
% path the worker's notation_render_dispatch takes: notation_scene has no
% glyph_overwrite layout, and its deferred_frame fallback would otherwise
% report a placeholder frame as a drawn scene. The grammar admits the
% overwrite only while the corrected value still misses the correct answer.
call_render(notation_render, glyph_overwrite(A, Op, B, R, Struck, Corrected), Dict) :-
    !,
    use_module(render(parametric_notation_deformation), []),
    parametric_notation_deformation:deformed_notation_scene(
        glyph_overwrite(A, Op, B, R, Struck, Corrected),
        notation_error(glyph_overwrite), Dict).
call_render(notation_render, Spec, Dict) :-
    notation_scene:notation_render_json(Spec, Dict).
call_render(balance_render, Spec, Dict) :-
    balance_scale_scene:balance_render_json(Spec, Dict).
call_render(ratio_diagram_render, Spec, Dict) :-
    ratio_diagram_scene:ratio_diagram_render_json(Spec, Dict).
call_render(measurement_strip_render, Spec, Dict) :-
    measurement_strip_scene:measurement_strip_render_json(Spec, Dict).

frames_of(Dict, Frames) :- get_dict(frames, Dict, Frames).

% =========================================================================
% Spec builders — ported verbatim (request-parsing logic only) from
% hermes_worker.pl :2713-2938 and its helpers :2247-2986,3996,4089. Kept
% behaviourally identical: same field names, same defaults, same bounds.
% =========================================================================

build_spec(area_render, Request, Spec) :- !, area_spec(Request, Spec).
build_spec(base_ten_render, Request, Spec) :- !, base_ten_spec(Request, Spec).
build_spec(set_grouping_render, Request, Spec) :- !, set_grouping_spec(Request, Spec).
build_spec(number_line_render, Request, Spec) :- !, number_line_spec(Request, Spec).
build_spec(coordinate_plane_render, Request, Spec) :- !, coordinate_plane_spec(Request, Spec).
build_spec(rigid_motion_render, Request, Spec) :- !, rigid_motion_spec(Request, Spec).
build_spec(polyform_tiling_render, Request, Spec) :- !, polyform_tiling_spec(Request, Spec).
build_spec(angle_circular_render, Request, Spec) :- !, angle_circular_spec(Request, Spec).
build_spec(data_display_render, Request, Spec) :- !, data_display_spec(Request, Spec).
build_spec(solid_net_render, Request, Spec) :- !, solid_net_spec(Request, Spec).
build_spec(geoboard_render, Request, Spec) :- !, geoboard_spec(Request, Spec).
build_spec(notation_render, Request, Spec) :- !, notation_spec(Request, Spec).
build_spec(balance_render, Request, Spec) :- !, balance_spec(Request, Spec).
build_spec(ratio_diagram_render, Request, Spec) :- !, ratio_diagram_spec(Request, Spec).
build_spec(measurement_strip_render, Request, Spec) :- !, measurement_strip_spec(Request, Spec).

area_spec(Request, Spec) :-
    request_string_atom(Request, kind, array_multiplication, Kind),
    request_integer(Request, a, 3, A),
    request_integer(Request, b, 4, B),
    area_spec_for(Kind, A, B, Request, Spec).

area_spec_for(array_multiplication, A, B, _, array_multiplication(A, B)) :- !.
area_spec_for(commutativity_by_transpose, A, B, _, commutativity_by_transpose(A, B)) :- !.
area_spec_for(partial_products, A, B, _, partial_products(A, B)) :- !.
area_spec_for(area_model_fraction, _, _, Request, area_model_fraction(NA, DA, NB, DB)) :- !,
    request_integer(Request, na, 1, NA), request_integer(Request, da, 2, DA),
    request_integer(Request, nb, 1, NB), request_integer(Request, db, 3, DB).
area_spec_for(area_compare, _, _, Request, area_compare(NA, DA, NB, DB)) :- !,
    request_integer(Request, na, 1, NA), request_integer(Request, da, 2, DA),
    request_integer(Request, nb, 1, NB), request_integer(Request, db, 3, DB).
area_spec_for(_Other, A, B, _, array_multiplication(A, B)).

balance_spec(Request, Spec) :-
    request_integer(Request, a, 2, A),
    request_integer(Request, b, 3, B),
    request_integer(Request, c, 11, C),
    Spec = solve_linear(A, B, C).

base_ten_spec(Request, Spec) :-
    request_string_atom(Request, kind, add_with_carry, Kind),
    request_integer(Request, base, 10, Base),
    base_ten_spec_for(Kind, Base, Request, Spec).

base_ten_spec_for(represent, Base, Request, represent(N, Base)) :- !,
    request_integer(Request, n, 28, N).
base_ten_spec_for(place_value_teen, _Base, Request, place_value_teen(N)) :- !,
    request_integer(Request, n, 14, N).
base_ten_spec_for(add_with_carry, Base, Request, add_with_carry(A, B, Base)) :- !,
    request_integer(Request, a, 28, A), request_integer(Request, b, 47, B).
base_ten_spec_for(subtract_with_borrow, Base, Request, subtract_with_borrow(A, B, Base)) :- !,
    request_integer(Request, a, 52, A), request_integer(Request, b, 27, B).
base_ten_spec_for(subtract_without_reducing_borrow, Base, Request, subtract_without_reducing_borrow(A, B, Base)) :- !,
    request_integer(Request, a, 52, A), request_integer(Request, b, 27, B).
base_ten_spec_for(base_decomposition, Base, Request, base_decomposition(N, Base)) :- !,
    request_integer(Request, n, 234, N).
base_ten_spec_for(decimal_place_value, _Base, Request, decimal_place_value(I, F)) :- !,
    request_integer(Request, intPart, 3, I), request_integer(Request, fracDigits, 14, F).
base_ten_spec_for(_Other, Base, Request, add_with_carry(A, B, Base)) :-
    request_integer(Request, a, 28, A), request_integer(Request, b, 47, B).

set_grouping_spec(Request, Spec) :-
    request_string_atom(Request, kind, make_ten, Kind),
    set_grouping_spec_for(Kind, Request, Spec).

set_grouping_spec_for(ten_frame, Request, ten_frame(N)) :- !,
    request_integer(Request, n, 7, N).
set_grouping_spec_for(subitize, Request, subitize(Pattern, N)) :- !,
    request_string_atom(Request, pattern, auto, Pattern), request_integer(Request, n, 5, N).
set_grouping_spec_for(make_ten, Request, make_ten(A, B)) :- !,
    request_integer(Request, a, 7, A), request_integer(Request, b, 8, B).
set_grouping_spec_for(make_ten_drop_leftover, Request, make_ten_drop_leftover(A, B)) :- !,
    request_integer(Request, a, 7, A), request_integer(Request, b, 8, B).
set_grouping_spec_for(parity, Request, parity(N)) :- !,
    request_integer(Request, n, 7, N).
set_grouping_spec_for(compare, Request, compare(A, B)) :- !,
    request_integer(Request, a, 5, A), request_integer(Request, b, 3, B).
set_grouping_spec_for(equal_groups, Request, equal_groups(G, S)) :- !,
    request_integer(Request, g, 3, G), request_integer(Request, s, 4, S).
set_grouping_spec_for(fair_share, Request, fair_share(Total, Groups)) :- !,
    request_integer(Request, total, 12, Total), request_integer(Request, groups, 3, Groups).
set_grouping_spec_for(signed_chips, Request, signed_chips(A, B)) :- !,
    request_integer(Request, a, 3, A), request_integer(Request, b, -5, B).
set_grouping_spec_for(_Other, Request, make_ten(A, B)) :-
    request_integer(Request, a, 7, A), request_integer(Request, b, 8, B).

number_line_spec(Request, Spec) :-
    request_op_atom(Request, mode, jumps, Mode),
    number_line_spec_for(Mode, Request, Spec).

number_line_spec_for(length, Request, rounding_length(Op, A, B)) :- !,
    request_op_atom(Request, operation, addition, Op),
    request_integer(Request, a, 28, A), request_integer(Request, b, 47, B).
number_line_spec_for(rounding, Request, Spec) :- !, number_line_spec_for(length, Request, Spec).
number_line_spec_for(magnitude, Request, magnitude_addition(A, B)) :- !,
    request_integer(Request, a, 28, A), request_integer(Request, b, 47, B).
number_line_spec_for(magnitude_addition, Request, Spec) :- !, number_line_spec_for(magnitude, Request, Spec).
number_line_spec_for(fraction, Request, fraction_iteration(N, D)) :- !,
    request_integer(Request, numerator, 7, N), request_integer(Request, denominator, 5, D).
number_line_spec_for(fraction_iteration, Request, Spec) :- !, number_line_spec_for(fraction, Request, Spec).
number_line_spec_for(_Jumps, Request, jumps(Strategy, A, B)) :-
    request_string_atom(Request, strategy, 'COBO', Strategy),
    request_integer(Request, a, 28, A), request_integer(Request, b, 47, B).

coordinate_plane_spec(Request, Spec) :-
    request_op_atom(Request, kind, plot_points, Kind),
    coordinate_plane_spec_for(Kind, Request, Spec).

coordinate_plane_spec_for(plot_points, Request, plot_points(Points)) :-
    request_json_array(Request, points, [[-3,2],[0,0],[4,-1]], Raw),
    length_between(Raw, 1, 12),
    maplist(scene_lattice_point(-50, 50), Raw, Points).
coordinate_plane_spec_for(plot_line, Request, plot_line(Slope, Intercept)) :-
    request_integer(Request, slope, 2, Slope),
    request_integer(Request, intercept, 1, Intercept),
    between(-20, 20, Slope), between(-20, 20, Intercept).

rigid_motion_spec(Request, Spec) :-
    request_json_array(Request, vertices, [[0,0],[3,0],[1,2]], Raw),
    length_between(Raw, 3, 12),
    maplist(scene_lattice_point(-50, 50), Raw, Vertices),
    request_op_atom(Request, kind, translate, Kind),
    rigid_motion_spec_for(Kind, Request, Vertices, Spec).

rigid_motion_spec_for(translate, Request, Vertices, translate(Vertices, DX, DY)) :-
    request_integer(Request, dx, 2, DX), request_integer(Request, dy, 1, DY),
    between(-50, 50, DX), between(-50, 50, DY).
rigid_motion_spec_for(reflect, Request, Vertices, reflect(Vertices, Mirror)) :-
    request_op_atom(Request, mirror, mirror_y, Mirror),
    memberchk(Mirror, [mirror_x, mirror_y]).
rigid_motion_spec_for(rotate, Request, Vertices, rotate(Vertices, point(CX, CY), Degrees)) :-
    request_integer(Request, cx, 0, CX), request_integer(Request, cy, 0, CY),
    request_integer(Request, degrees, 90, Degrees),
    between(-50, 50, CX), between(-50, 50, CY), memberchk(Degrees, [90, 180, 270]).

polyform_tiling_spec(Request, tile_area(cols(Columns), rows(Rows))) :-
    request_integer(Request, cols, 5, Columns),
    request_integer(Request, rows, 3, Rows),
    between(1, 20, Columns), between(1, 20, Rows).

angle_circular_spec(Request, Spec) :-
    request_op_atom(Request, kind, angle, Kind),
    memberchk(Kind, [angle, sector]),
    request_integer(Request, degrees, 120, Degrees),
    between(1, 360, Degrees),
    Spec =.. [Kind, Degrees].

data_display_spec(Request, Spec) :-
    request_op_atom(Request, kind, dot_plot, Kind),
    data_display_spec_for(Kind, Request, Spec).

data_display_spec_for(dot_plot, Request, dot_plot(Values)) :-
    request_json_array(Request, values, [2,3,3,5,7], Values),
    length_between(Values, 1, 60),
    maplist(bounded_integer(-10000, 10000), Values).
data_display_spec_for(bar_chart, Request, bar_chart(Pairs)) :-
    request_json_array(Request, pairs, [_{category:"red",count:4}, _{category:"blue",count:6}], Raw),
    length_between(Raw, 1, 12),
    maplist(scene_category_count, Raw, Pairs).
data_display_spec_for(histogram, Request, histogram(Bins)) :-
    request_json_array(Request, bins, [_{lower:0,upper:2,count:3}, _{lower:2,upper:4,count:5}], Raw),
    length_between(Raw, 1, 20),
    maplist(scene_histogram_bin, Raw, Bins).
data_display_spec_for(box_plot, Request, box_plot(FiveNumber)) :-
    request_json_array(Request, summary, [2,4,5,7,9], Values),
    Values = [Minimum,Q1,Median,Q3,Maximum],
    maplist(bounded_integer(-10000, 10000), Values),
    FiveNumber = five_number(Minimum,Q1,Median,Q3,Maximum).

solid_net_spec(Request, Spec) :-
    request_op_atom(Request, kind, net_of, Kind),
    solid_net_spec_for(Kind, Request, Spec).

solid_net_spec_for(net_of, Request, net_of(Solid)) :-
    request_op_atom(Request, solid, cube, Solid),
    memberchk(Solid, [cube, square_pyramid, triangular_prism, rectangular_prism]).
solid_net_spec_for(unit_cube_stack, Request, unit_cube_stack(L, W, H)) :-
    request_integer(Request, length, 3, L), request_integer(Request, width, 2, W),
    request_integer(Request, height, 2, H), maplist(between(1, 20), [L,W,H]).

geoboard_spec(Request, stretch_polygon(Vertices)) :-
    request_json_array(Request, vertices, [[0,0],[4,0],[4,3],[0,3]], Raw),
    length_between(Raw, 3, 12),
    maplist(scene_lattice_point(-20, 20), Raw, Vertices).

ratio_diagram_spec(Request,
                   ratio(FirstLabel, FirstCount,
                         SecondLabel, SecondCount)) :-
    request_string_atom(Request, first_label, apples, FirstLabel),
    request_integer(Request, first_count, 2, FirstCount),
    request_string_atom(Request, second_label, oranges, SecondLabel),
    request_integer(Request, second_count, 3, SecondCount),
    FirstLabel \== SecondLabel,
    maplist(between(1, 20), [FirstCount, SecondCount]).

measurement_strip_spec(Request,
                       measure(IntervalCount, Subdivisions, Unit)) :-
    request_integer(Request, interval_count, 5, IntervalCount),
    request_integer(Request, subdivisions_per_unit, 4, Subdivisions),
    request_string_atom(Request, unit, meter, Unit),
    between(1, 256, IntervalCount),
    between(1, 256, Subdivisions),
    Unit \== ''.

notation_spec(Request, Spec) :-
    request_string_atom(Request, kind, write_equation, Kind),
    notation_spec_for(Kind, Request, Spec).

notation_spec_for(write_equation, Request, write_equation(A, Op, B, R)) :- !,
    request_integer(Request, a, 2, A), request_integer(Request, b, 3, B),
    request_integer(Request, r, 5, R), request_op_atom(Request, operator, +, Op0),
    op_symbol(Op0, Op).
notation_spec_for(mirror_written, Request, mirror_written(Digit, A, Op, B, R)) :- !,
    request_integer(Request, digit, 3, Digit),
    request_integer(Request, a, 2, A), request_integer(Request, b, 3, B),
    request_integer(Request, r, 5, R), request_op_atom(Request, operator, +, Op0),
    op_symbol(Op0, Op).
notation_spec_for(glyph_overwrite, Request,
                  glyph_overwrite(A, Op, B, R, Struck, Corrected)) :- !,
    request_integer(Request, a, 3, A), request_integer(Request, b, 2, B),
    request_integer(Request, r, 5, R), request_op_atom(Request, operator, +, Op0),
    op_symbol(Op0, Op),
    request_integer(Request, struck, 4, Struck),
    request_integer(Request, corrected, 6, Corrected).

op_symbol('+', +) :- !.
op_symbol('-', -) :- !.
op_symbol(Op, Op).

% --- request field helpers, ported verbatim (:2247-2986,3996,4089) --------

request_integer(Request, Key, Default, N) :-
    ( get_dict_opt(Key, Request, Value)
    -> ( integer(Value) -> N = Value
       ; ( string(Value) ; atom(Value) ), atom_number(Value, Num), integer(Num) -> N = Num
       ; N = Default
       )
    ;  N = Default
    ).

request_op_atom(Request, Key, Default, Atom) :-
    ( get_dict_opt(Key, Request, Value), Value \== ""
    -> string_or_atom_to_atom(Value, A0), downcase_atom(A0, Atom)
    ;  Atom = Default
    ).

request_string_atom(Request, Key, Default, Atom) :-
    ( get_dict_opt(Key, Request, Value), Value \== ""
    -> string_or_atom_to_atom(Value, Atom)
    ;  Atom = Default
    ).

request_json_array(Request, Key, Default, Values) :-
    ( get_dict_opt(Key, Request, Raw)
    -> json_array_value(Raw, Values)
    ;  Values = Default
    ).

json_array_value(Value, Value) :- is_list(Value), !.
json_array_value(Value, List) :-
    ( string(Value) ; atom(Value) ),
    catch(atom_json_term(Value, List, [value_string_as(string)]), _, fail),
    is_list(List).

scene_lattice_point(Low, High, [X,Y], X-Y) :- !,
    bounded_integer(Low, High, X), bounded_integer(Low, High, Y).
scene_lattice_point(Low, High, Dict, X-Y) :-
    is_dict(Dict), get_dict(x, Dict, X), get_dict(y, Dict, Y),
    bounded_integer(Low, High, X), bounded_integer(Low, High, Y).

scene_category_count(Dict, Category-Count) :-
    is_dict(Dict), get_dict(category, Dict, Category0),
    string_or_atom_to_atom(Category0, Category),
    get_dict(count, Dict, Count), bounded_integer(0, 1000, Count).

scene_histogram_bin(Dict, bin(Lower, Upper)-Count) :-
    is_dict(Dict), get_dict(lower, Dict, Lower), get_dict(upper, Dict, Upper),
    get_dict(count, Dict, Count),
    bounded_integer(-10000, 10000, Lower), bounded_integer(-10000, 10000, Upper),
    bounded_integer(0, 1000, Count).

bounded_integer(Low, High, Value) :- integer(Value), Value >= Low, Value =< High.

length_between(List, Low, High) :-
    is_list(List), length(List, Length), Length >= Low, Length =< High.

string_or_atom_to_atom(Value, Atom) :-
    ( atom(Value) -> Atom = Value
    ; string(Value) -> atom_string(Atom, Value)
    ; term_string(Value, String), atom_string(Atom, String)
    ).

get_dict_opt(Key, Dict, Val) :-
    get_dict(Key, Dict, Val0), Val0 \== null, Val = Val0.

to_atom(V, A) :- ( atom(V) -> A = V ; atom_string(A, V) ).
