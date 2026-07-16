/** <module> Coordinate-plane scene compiler (spatial family)
 *
 * Compiles a plotting task into coordinate-plane scene frames on the frozen
 * render contract (docs/research_assets/specs/2026-06-23-render-contract-frozen.md,
 * §2 coordinate-plane). The spatial family extends the catalog past the
 * arithmetic/number region into the K-8 spatial representations tallied in
 * docs/research/2026-07-08-hermes-spatial-representation-gap-tally.md.
 *
 * Unlike the number-line compiler, whose picture is driven by a strategy-trace
 * witness, this compiler computes its geometry directly from the plotting task:
 * a coordinate plane denotes a set of ordered pairs, and the location of a pair
 * is a fact about the pair, not the running history of an automaton. Every
 * coordinate the scene carries is a MATH coordinate (an integer lattice point or
 * axis bound); the drawer maps math -> pixels within its own band, exactly as it
 * scales the number line. The compiler never emits a pixel.
 *
 * Two productive Spec shapes, one format ("coordinate-plane", version 2):
 *
 *   - plot_points(Points)  : Points is a list of X-Y integer pairs. The filmstrip
 *     lands one point per frame, so the plane fills in pair by pair. Denotes the
 *     task point_set(Points).
 *   - plot_line(M, B)      : the line y = M*x + B drawn as a plotted_path across
 *     the axis window, with its two axis intercepts marked. Denotes linear_graph(M, B).
 *
 * The characteristic break (the grammar's deformation lane) is the quadrant-sign
 * error: a point (-3, 2) plotted at (3, 2), the sign of a coordinate dropped so
 * the pair lands in the wrong quadrant. It is reachable ONLY through
 * quadrant_sign_error/2 and only via the misconception lane; there is no
 * productive Spec that plots a sign-dropped point.
 *
 * Semantic color ROLES only (contract §3): a plotted pair carries role "point",
 * the sign-error pair carries role "deformation", the plotted line carries role
 * "iterated". This compiler never emits a hex string.
 *
 * Graceful degradation: a Spec with no drawable points (an empty list, a
 * non-integer coordinate) yields an explicit error document with frames:[]
 * rather than a faked picture (contract §2).
 */

:- module(coordinate_plane_scene,
          [ coordinate_plane_render_frames/2,   % +Spec, -Frames
            coordinate_plane_render_json/2,      % +Spec, -Dict
            coordinate_plane_compare_json/2,     % +Spec, -Dict (sign-error deformation)
            coordinate_plane_render_to_file/2    % +Spec, +Path
          ]).

:- use_module(library(http/json), [json_write_dict/3]).
:- use_module(library(lists)).

% =============================================================================
% Public API
% =============================================================================

%!  coordinate_plane_render_frames(+Spec, -Frames) is det.
%
%   Walk Spec into a list of frame dicts. A Spec that cannot be plotted yields a
%   single annotation-only frame (sceneChanged:false), so nothing throws.
coordinate_plane_render_frames(Spec, Frames) :-
    ( gen_frames(Spec, Frames0)
    -> Frames = Frames0
    ;  deferred_frame(Spec, F),
       Frames = [F]
    ).

%!  coordinate_plane_render_json(+Spec, -Dict) is det.
%
%   The full render document: kind / request / result / canvas / frames
%   (contract §1.1). On an unplottable Spec, an explicit error string and frames:[].
coordinate_plane_render_json(plot_points(Points), Dict) :-
    !,
    ( clean_points(Points, Clean), Clean \== []
    -> axis_window(Clean, Window),
       points_frames(Clean, Window, Frames),
       length(Clean, N),
       format(string(ResultStr), "~w plotted point(s)", [N]),
       canvas_dict(Canvas),
       points_request(Clean, Request),
       Dict = _{ kind: "plot_points",
                 request: Request,
                 result: ResultStr,
                 canvas: Canvas,
                 frames: Frames }
    ;  Dict = _{ kind: "plot_points",
                 request: _{ points: "[]" },
                 error: "No integer lattice points to plot for this coordinate-plane task.",
                 frames: [] }
    ).
coordinate_plane_render_json(plot_line(M, B), Dict) :-
    !,
    ( integer(M), integer(B)
    -> line_window(M, B, Window),
       line_frames(M, B, Window, Frames),
       line_equation_string(M, B, EqStr),
       canvas_dict(Canvas),
       Dict = _{ kind: "plot_line",
                 request: _{ slope: M, intercept: B, equation: EqStr },
                 result: EqStr,
                 canvas: Canvas,
                 frames: Frames }
    ;  Dict = _{ kind: "plot_line",
                 request: _{ slope: M, intercept: B },
                 error: "A coordinate-plane line needs integer slope and intercept for this scene.",
                 frames: [] }
    ).
coordinate_plane_render_json(Spec, Dict) :-
    coordinate_plane_render_frames(Spec, Frames),
    term_to_string(Spec, SpecStr),
    canvas_dict(Canvas),
    Dict = _{ kind: SpecStr,
              request: _{ spec: SpecStr },
              result: "unknown",
              canvas: Canvas,
              frames: Frames }.

%!  coordinate_plane_compare_json(+Spec, -Dict) is det.
%
%   The quadrant-sign-error compare document: a productive filmstrip that plots
%   the true pair (X, Y) beside a deformation filmstrip that plots the
%   sign-dropped pair (|X|, |Y|) in the wrong quadrant, so the dropped sign is
%   drawn against its grounded partner. Spec is quadrant_sign_compare(X, Y).
%   On a pair with no sign to drop (both coordinates already non-negative), an
%   explicit error and empty filmstrips.
coordinate_plane_compare_json(quadrant_sign_compare(X, Y), Dict) :-
    !,
    ( integer(X), integer(Y), ( X < 0 ; Y < 0 )
    -> WrongX is abs(X), WrongY is abs(Y),
       compare_window([X-Y, WrongX-WrongY], Window),
       prod_point_frames(X, Y, Window, ProdFrames),
       def_point_frames(X, Y, WrongX, WrongY, Window, DefFrames),
       quadrant_of(X, Y, CorrectQ),
       quadrant_of(WrongX, WrongY, WrongQ),
       compare_note(X, Y, WrongX, WrongY, CorrectQ, WrongQ, Note),
       canvas_dict(Canvas),
       Dict = _{ kind: "plot_pair_vs_sign_dropped_pair",
                 request: _{ x: X, y: Y },
                 productiveKind: "plot_pair",
                 deformationKind: "sign_dropped_pair",
                 family: "quadrant_sign_error",
                 correct_point: _{ x: X, y: Y, quadrant: CorrectQ },
                 deformed_point: _{ x: WrongX, y: WrongY, quadrant: WrongQ },
                 note: Note,
                 canvas: Canvas,
                 productive: _{ frames: ProdFrames },
                 deformation: _{ frames: DefFrames } }
    ;  Dict = _{ kind: "plot_pair_vs_sign_dropped_pair",
                 request: _{ x: X, y: Y },
                 error: "This pair has no negative coordinate to drop; the quadrant-sign error does not arise.",
                 productive: _{ frames: [] },
                 deformation: _{ frames: [] } }
    ).
coordinate_plane_compare_json(Spec, _{ kind: SpecStr,
                                       error: "Unknown coordinate-plane compare spec.",
                                       productive: _{ frames: [] },
                                       deformation: _{ frames: [] } }) :-
    term_to_string(Spec, SpecStr).

%!  coordinate_plane_render_to_file(+Spec, +Path) is det.
coordinate_plane_render_to_file(Spec, Path) :-
    coordinate_plane_render_json(Spec, Dict),
    setup_call_cleanup(
        open(Path, write, Stream),
        json_write_dict(Stream, Dict, [width(80)]),
        close(Stream)).


% =============================================================================
% plot_points — one lattice point per frame.
% =============================================================================

%!  points_frames(+Points, +Window, -Frames) is det.
%   One frame per point, accumulating the points landed so far so the filmstrip
%   builds the plane pair by pair. Every scene carries the full axes plus every
%   point up to and including the current step.
points_frames(Points, Window, Frames) :-
    points_frames_(Points, Window, 1, [], Frames).

points_frames_([], _Window, _Step, _Acc, []).
points_frames_([X-Y|Rest], Window, Step, Acc, [Frame|Frames]) :-
    point_dict(X, Y, "point", Point),
    append(Acc, [Point], Acc1),
    axes_dict(Window, Axes),
    Scene = _{ format: "coordinate-plane",
               version: 2,
               axes: Axes,
               points: Acc1,
               path: [] },
    format(string(Caption), "Plot (~w, ~w): count ~w along x, then ~w along y.",
           [X, Y, X, Y]),
    point_verb(X, Y, Verb),
    Frame = _{ step: Step,
               verb: Verb,
               caption: Caption,
               sceneChanged: true,
               scene: Scene },
    Step1 is Step + 1,
    points_frames_(Rest, Window, Step1, Acc1, Frames).

%!  point_verb(+X, +Y, -Verb) mirrors the trace verb for a plot step.
point_verb(X, Y, Verb) :- format(string(Verb), "plot(~w,~w)", [X, Y]).

%!  point_dict(+X, +Y, +Role, -Dict) is det.
point_dict(X, Y, Role, _{ x: X, y: Y, role: Role, label: Label }) :-
    format(string(Label), "(~w, ~w)", [X, Y]).


% =============================================================================
% plot_line — the line y = M*x + B across the axis window.
% =============================================================================

%!  line_frames(+M, +B, +Window, -Frames) is det.
%   Three frames: establish the axes, draw the line across the window, mark the
%   intercepts so slope-as-rate reads off the plotted_path.
line_frames(M, B, Window, [F1, F2, F3]) :-
    axes_dict(Window, Axes),
    % Frame 1: the empty plane.
    Scene1 = _{ format: "coordinate-plane", version: 2,
                axes: Axes, points: [], path: [] },
    F1 = _{ step: 1, verb: "establish_axes",
            caption: "Set up the coordinate plane with both axes through the origin.",
            sceneChanged: true, scene: Scene1 },
    % Frame 2: the line drawn as a path from left window edge to right.
    line_path(M, B, Window, Path),
    Scene2 = _{ format: "coordinate-plane", version: 2,
                axes: Axes, points: [], path: Path },
    line_equation_string(M, B, EqStr),
    format(string(Cap2), "Draw ~w: for every step right, the line rises ~w.",
           [EqStr, M]),
    F2 = _{ step: 2, verb: "draw_line",
            caption: Cap2, sceneChanged: true, scene: Scene2 },
    % Frame 3: mark the y-intercept (0, B), role point.
    point_dict(0, B, "point", Intercept),
    Scene3 = _{ format: "coordinate-plane", version: 2,
                axes: Axes, points: [Intercept], path: Path },
    format(string(Cap3), "Mark the y-intercept (0, ~w) where the line crosses the y-axis.",
           [B]),
    F3 = _{ step: 3, verb: "mark_intercept",
            caption: Cap3, sceneChanged: true, scene: Scene3 }.

%!  line_path(+M, +B, +Window, -Path) is det.
%   The two endpoints of the line clipped to the axis window's x-range.
line_path(M, B, Window, [_{x: XMin, y: YMin}, _{x: XMax, y: YMax}]) :-
    _{ x_min: XMin, x_max: XMax } :< Window,
    YMin is M * XMin + B,
    YMax is M * XMax + B.

line_equation_string(M, B, Str) :-
    ( B >= 0
    -> format(string(Str), "y = ~w x + ~w", [M, B])
    ;  AbsB is abs(B),
       format(string(Str), "y = ~w x - ~w", [M, AbsB])
    ).


% =============================================================================
% Compare — the productive pair beside the sign-dropped pair.
% =============================================================================

prod_point_frames(X, Y, Window, [F]) :-
    point_dict(X, Y, "point", Point),
    axes_dict(Window, Axes),
    Scene = _{ format: "coordinate-plane", version: 2,
               axes: Axes, points: [Point], path: [] },
    quadrant_of(X, Y, Q),
    format(string(Cap), "Plot (~w, ~w) in quadrant ~w, keeping both signs.", [X, Y, Q]),
    F = _{ step: 1, verb: "plot_pair", caption: Cap, sceneChanged: true, scene: Scene }.

def_point_frames(X, Y, WrongX, WrongY, Window, [F1, F2]) :-
    axes_dict(Window, Axes),
    point_dict(X, Y, "point", Correct),
    point_dict(WrongX, WrongY, "deformation", Wrong),
    % Frame 1: the correct pair for reference.
    Scene1 = _{ format: "coordinate-plane", version: 2,
                axes: Axes, points: [Correct], path: [] },
    quadrant_of(X, Y, CorrectQ),
    format(string(Cap1), "The pair (~w, ~w) belongs in quadrant ~w.", [X, Y, CorrectQ]),
    F1 = _{ step: 1, verb: "locate_pair", caption: Cap1, sceneChanged: true, scene: Scene1 },
    % Frame 2: the sign-dropped pair lands in the wrong quadrant.
    Scene2 = _{ format: "coordinate-plane", version: 2,
                axes: Axes, points: [Correct, Wrong], path: [] },
    quadrant_of(WrongX, WrongY, WrongQ),
    format(string(Cap2),
           "Dropping the sign plots (~w, ~w) instead: it lands in quadrant ~w, the wrong quadrant.",
           [WrongX, WrongY, WrongQ]),
    F2 = _{ step: 2, verb: "drop_sign", caption: Cap2, sceneChanged: true, scene: Scene2 }.

compare_note(X, Y, WrongX, WrongY, CorrectQ, WrongQ, Note) :-
    format(string(Note),
           "The pair (~w, ~w) belongs in quadrant ~w. Dropping the sign of a coordinate \
plots (~w, ~w) in quadrant ~w instead. The plane is doubly indexed: the sign of each \
coordinate chooses the side of its axis, and losing it moves the point to a different quadrant. \
(Quadrant-sign-error family.)",
           [X, Y, CorrectQ, WrongX, WrongY, WrongQ]).


% =============================================================================
% Axis window — an integer window that shows the origin and every point.
% =============================================================================

%!  axis_window(+Points, -Window) is det.
%   The window spans zero and every plotted coordinate with a one-unit margin, so
%   the origin and all touched quadrants are legible. Window is a dict of integer
%   bounds x_min/x_max/y_min/y_max.
axis_window(Points, Window) :-
    findall(X, member(X-_, Points), Xs),
    findall(Y, member(_-Y, Points), Ys),
    bounds_with_zero(Xs, XMin, XMax),
    bounds_with_zero(Ys, YMin, YMax),
    Window = _{ x_min: XMin, x_max: XMax, y_min: YMin, y_max: YMax }.

compare_window(Points, Window) :- axis_window(Points, Window).

line_window(M, B, Window) :-
    % A symmetric window a few units either side of zero, tall enough to hold the
    % line's rise across it. The y-bounds are taken at the final (pushed-out)
    % x-bounds so the plotted_path's endpoints stay inside the window.
    XSpan = 5,
    bounds_with_zero([-XSpan, XSpan], XMin, XMax),
    Y1 is M * XMin + B,
    Y2 is M * XMax + B,
    bounds_with_zero([Y1, Y2, B], YMin, YMax),
    Window = _{ x_min: XMin, x_max: XMax, y_min: YMin, y_max: YMax }.

%!  bounds_with_zero(+Values, -Min, -Max) is det.
%   The min and max of Values together with 0, each pushed out one unit so a
%   point never sits on the window edge.
bounds_with_zero(Values, Min, Max) :-
    Lo0 = [0|Values],
    min_list(Lo0, RawMin),
    max_list(Lo0, RawMax),
    Min is RawMin - 1,
    Max is RawMax + 1.

%!  axes_dict(+Window, -Axes) is det.
axes_dict(Window, _{ xMin: XMin, xMax: XMax, yMin: YMin, yMax: YMax }) :-
    _{ x_min: XMin, x_max: XMax, y_min: YMin, y_max: YMax } :< Window.


% =============================================================================
% Helpers.
% =============================================================================

%!  clean_points(+Raw, -Clean) is det.
%   Keep only well-formed integer X-Y pairs, in order. A malformed entry is
%   dropped rather than faked, so a partly-bad list still plots its good points.
clean_points(Raw, Clean) :-
    is_list(Raw),
    findall(X-Y,
            ( member(P, Raw),
              point_pair(P, X, Y)
            ),
            Clean).

point_pair(X-Y, X, Y) :- integer(X), integer(Y).
point_pair(point(X, Y), X, Y) :- integer(X), integer(Y).
point_pair([X, Y], X, Y) :- integer(X), integer(Y).

points_request(Points, _{ points: Str, count: N }) :-
    length(Points, N),
    term_to_string(Points, Str).

%!  quadrant_of(+X, +Y, -Quadrant) is det.
%   The Cartesian quadrant (1..4) of a pair, or an axis label when a coordinate
%   is zero. Quadrant I is (+,+), II is (-,+), III is (-,-), IV is (+,-).
quadrant_of(0, 0, "origin") :- !.
quadrant_of(0, _, "y-axis") :- !.
quadrant_of(_, 0, "x-axis") :- !.
quadrant_of(X, Y, "I")   :- X > 0, Y > 0, !.
quadrant_of(X, Y, "II")  :- X < 0, Y > 0, !.
quadrant_of(X, Y, "III") :- X < 0, Y < 0, !.
quadrant_of(_, _, "IV").

%!  gen_frames(+Spec, -Frames) for the frames-only entry point.
gen_frames(plot_points(Points), Frames) :-
    clean_points(Points, Clean), Clean \== [],
    !,
    axis_window(Clean, Window),
    points_frames(Clean, Window, Frames).
gen_frames(plot_line(M, B), Frames) :-
    integer(M), integer(B),
    !,
    line_window(M, B, Window),
    line_frames(M, B, Window, Frames).

%!  deferred_frame(+Spec, -Frame) is det.
%   An unplottable spec is annotation-only: an empty plane, no throw.
deferred_frame(Spec, Frame) :-
    term_to_string(Spec, SpecStr),
    format(string(Cap), "No coordinate-plane plot for ~w; nothing drawn.", [SpecStr]),
    Scene = _{ format: "coordinate-plane", version: 2,
               axes: _{ xMin: -1, xMax: 1, yMin: -1, yMax: 1 },
               points: [], path: [] },
    Frame = _{ step: 1, verb: SpecStr, caption: Cap,
               sceneChanged: false, scene: Scene }.

%!  canvas_dict(-Canvas) is det.
canvas_dict(_{ width: 520, height: 520 }).

%!  term_to_string(+Term, -String) is det.
term_to_string(Term, String) :-
    ( string(Term)
    -> String = Term
    ;  format(string(String), '~w', [Term])
    ).
