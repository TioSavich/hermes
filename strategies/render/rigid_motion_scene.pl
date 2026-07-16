/** <module> Rigid-motion scene compiler (spatial family)
 *
 * Compiles a transformation task into rigid-motion scene frames on the frozen
 * render contract (docs/research_assets/specs/2026-06-23-render-contract-frozen.md,
 * §2 spatial family). The rigid-motion format is the transformation actuator for
 * the K-8 spatial catalog: 4.G.3 line symmetry, and 8.G.1-4, where congruence and
 * similarity are defined through motions of the plane.
 *
 * A small polygon is a list of integer X-Y vertices. The compiler moves it by an
 * isometry and reports the image beside the pre-image. Every coordinate it emits
 * is a MATH coordinate (a lattice vertex or an axis bound); the drawer maps
 * math -> pixels within its own band, exactly as it scales the number line and
 * the coordinate plane. The compiler never emits a pixel and never emits a hex
 * color: a pre-image polygon occupies the pre-image slot, the image polygon the
 * image slot, and the drawer resolves each slot to its --fig-<role> ink.
 *
 * Three productive Spec shapes, one format ("rigid-motion", version 2):
 *
 *   - translate(Shape, DX, DY)      : slide every vertex by (DX, DY).
 *     Denotes isometry_image(Shape, translation(DX, DY)).
 *   - reflect(Shape, mirror_x|mirror_y) : reflect across the x- or y-axis.
 *     Denotes isometry_image(Shape, reflection(Axis)).
 *   - rotate(Shape, Center, Deg), Deg in {90,180,270} : turn about Center.
 *     Denotes isometry_image(Shape, rotation(Center, Deg)).
 *
 * All three are lattice-preserving, so every image vertex stays an integer pair.
 * The filmstrip lands the pre-image first, then the image, so the motion reads as
 * a congruence: the image keeps the pre-image's size and shape.
 *
 * The characteristic break (the grammar's deformation lane) is
 * reflection_by_rotation(Shape): a chiral tile's mirror image cannot be reached
 * by any rotation within the plane. Rotation preserves orientation; reflection
 * reverses it. The deformation attempts the reflection by rotating 180 degrees
 * about the origin and shows the rotated tile does NOT coincide with the true
 * mirror image; reaching the mirror image needs a flip out of the plane. It is
 * reachable ONLY through rigid_motion_compare_json/2 and only for a chiral
 * figure; no productive Spec plots a rotation-as-reflection. The break carries
 * violation reason(orientation_reversed_not_reachable_by_rotation), provenance
 * literature_only. (Secondary honest note carried in the grammar: a dilation
 * scales length and so is not an isometry.)
 *
 * Semantic slots only (contract §3): the pre-image polygon is drawn with role
 * "pre-image", the image polygon with role "image", the deformation attempt with
 * role "deformation". This compiler never emits a hex string.
 *
 * Graceful degradation: a Spec with no drawable polygon (a non-list shape, a
 * shape under three vertices, a non-integer coordinate, a degree outside
 * {90,180,270}) yields an explicit error document with frames:[] rather than a
 * faked picture (contract §2).
 */

:- module(rigid_motion_scene,
          [ rigid_motion_render_frames/2,   % +Spec, -Frames
            rigid_motion_render_json/2,      % +Spec, -Dict
            rigid_motion_compare_json/2,     % +Spec, -Dict (reflection-by-rotation break)
            rigid_motion_render_to_file/2    % +Spec, +Path
          ]).

:- use_module(library(http/json), [json_write_dict/3]).
:- use_module(library(lists)).

% =============================================================================
% Public API
% =============================================================================

%!  rigid_motion_render_frames(+Spec, -Frames) is det.
%
%   Walk Spec into a list of frame dicts. A Spec that cannot be drawn yields a
%   single annotation-only frame (sceneChanged:false), so nothing throws.
rigid_motion_render_frames(Spec, Frames) :-
    ( gen_frames(Spec, Frames0)
    -> Frames = Frames0
    ;  deferred_frame(Spec, F),
       Frames = [F]
    ).

%!  rigid_motion_render_json(+Spec, -Dict) is det.
%
%   The full render document: kind / request / result / canvas / frames
%   (contract §1.1). On an undrawable Spec, an explicit error string and frames:[].
rigid_motion_render_json(translate(Shape, DX, DY), Dict) :-
    !,
    ( parse_shape(Shape, Verts), integer(DX), integer(DY)
    -> Motion = translation(DX, DY),
       motion_frames(Verts, Motion, Frames),
       motion_result(Motion, ResultStr),
       shape_string(Verts, ShapeStr),
       canvas_dict(Canvas),
       Dict = _{ kind: "translate",
                 request: _{ shape: ShapeStr, dx: DX, dy: DY },
                 result: ResultStr,
                 canvas: Canvas,
                 frames: Frames }
    ;  shape_string_raw(Shape, ShapeStr),
       Dict = _{ kind: "translate",
                 request: _{ shape: ShapeStr, dx: DX, dy: DY },
                 error: "A rigid-motion translation needs a polygon of three or more integer vertices and integer offsets.",
                 frames: [] }
    ).
rigid_motion_render_json(reflect(Shape, Mirror), Dict) :-
    !,
    ( parse_shape(Shape, Verts), reflect_axis(Mirror, Axis)
    -> Motion = reflection(Axis),
       motion_frames(Verts, Motion, Frames),
       motion_result(Motion, ResultStr),
       shape_string(Verts, ShapeStr),
       canvas_dict(Canvas),
       Dict = _{ kind: "reflect",
                 request: _{ shape: ShapeStr, mirror: Mirror },
                 result: ResultStr,
                 canvas: Canvas,
                 frames: Frames }
    ;  shape_string_raw(Shape, ShapeStr),
       Dict = _{ kind: "reflect",
                 request: _{ shape: ShapeStr, mirror: Mirror },
                 error: "A rigid-motion reflection needs a polygon of three or more integer vertices and a mirror of mirror_x or mirror_y.",
                 frames: [] }
    ).
rigid_motion_render_json(rotate(Shape, Center, Deg), Dict) :-
    !,
    ( parse_shape(Shape, Verts), parse_center(Center, CX, CY), rotation_deg(Deg)
    -> Motion = rotation(CX, CY, Deg),
       motion_frames(Verts, Motion, Frames),
       motion_result(Motion, ResultStr),
       shape_string(Verts, ShapeStr),
       canvas_dict(Canvas),
       Dict = _{ kind: "rotate",
                 request: _{ shape: ShapeStr, cx: CX, cy: CY, degrees: Deg },
                 result: ResultStr,
                 canvas: Canvas,
                 frames: Frames }
    ;  shape_string_raw(Shape, ShapeStr),
       Dict = _{ kind: "rotate",
                 request: _{ shape: ShapeStr, center: CenterStr, degrees: Deg },
                 error: "A rigid-motion rotation needs a polygon of three or more integer vertices, an integer center, and a quarter-turn degree in {90,180,270}.",
                 frames: [] },
       term_to_string(Center, CenterStr)
    ).
rigid_motion_render_json(Spec, Dict) :-
    rigid_motion_render_frames(Spec, Frames),
    term_to_string(Spec, SpecStr),
    canvas_dict(Canvas),
    Dict = _{ kind: SpecStr,
              request: _{ spec: SpecStr },
              result: "unknown",
              canvas: Canvas,
              frames: Frames }.

%!  rigid_motion_compare_json(+Spec, -Dict) is det.
%
%   The reflection-by-rotation compare document: a productive filmstrip that
%   reflects a chiral figure across the y-axis beside a deformation filmstrip that
%   attempts the same reflection by rotating 180 degrees about the origin. The
%   rotated tile does not coincide with the true mirror image, because rotation
%   preserves orientation and reflection reverses it. Spec is
%   reflection_by_rotation(Shape); it applies only to a chiral figure (one with no
%   line of symmetry). A figure with a line of symmetry has no such break: an
%   explicit error and empty filmstrips.
rigid_motion_compare_json(reflection_by_rotation(Shape), Dict) :-
    !,
    ( parse_shape(Shape, Verts), chiral_under_lattice_rotations(Verts)
    -> maplist(reflect_pt(y), Verts, MirrorVerts),        % the true image (reflection)
       maplist(rotate_pt(0, 0, 180), Verts, RotVerts),    % the misconception's attempt
       prod_reflection_frames(Verts, MirrorVerts, ProdFrames),
       def_break_frames(Verts, MirrorVerts, RotVerts, DefFrames),
       shape_string(Verts, ShapeStr),
       shape_string(MirrorVerts, MirrorStr),
       shape_string(RotVerts, RotStr),
       break_note(Note),
       canvas_dict(Canvas),
       Dict = _{ kind: "reflect_vs_rotate_180",
                 request: _{ shape: ShapeStr },
                 productiveKind: "reflect_across_y",
                 deformationKind: "rotate_180_instead_of_reflect",
                 family: reflection_by_rotation,
                 true_image: MirrorStr,
                 attempted_motion: "rotation of 180 degrees about the origin",
                 attempted_image: RotStr,
                 violation: reason(orientation_reversed_not_reachable_by_rotation),
                 provenance: literature_only,
                 note: Note,
                 canvas: Canvas,
                 productive: _{ frames: ProdFrames },
                 deformation: _{ frames: DefFrames } }
    ;  shape_string_raw(Shape, ShapeStr),
       Dict = _{ kind: "reflect_vs_rotate_180",
                 request: _{ shape: ShapeStr },
                 error: "The reflection-by-rotation break needs a chiral polygon (three or more integer vertices with no line of symmetry); a symmetric figure has no such break.",
                 productive: _{ frames: [] },
                 deformation: _{ frames: [] } }
    ).
rigid_motion_compare_json(Spec, _{ kind: SpecStr,
                                   error: "Unknown rigid-motion compare spec.",
                                   productive: _{ frames: [] },
                                   deformation: _{ frames: [] } }) :-
    term_to_string(Spec, SpecStr).

%!  rigid_motion_render_to_file(+Spec, +Path) is det.
rigid_motion_render_to_file(Spec, Path) :-
    rigid_motion_render_json(Spec, Dict),
    setup_call_cleanup(
        open(Path, write, Stream),
        json_write_dict(Stream, Dict, [width(80)]),
        close(Stream)).


% =============================================================================
% Productive filmstrip — pre-image first, then image.
% =============================================================================

%!  motion_frames(+Verts, +Motion, -Frames) is det.
%   Two frames: place the pre-image, then apply the isometry so the image lands
%   beside it. Every scene carries the same axis window so nothing shifts under
%   the motion.
motion_frames(Verts, Motion, [F1, F2]) :-
    motion_image(Verts, Motion, ImgVerts),
    motion_window(Verts, ImgVerts, Motion, Window),
    axes_dict(Window, Axes),
    motion_dict(Motion, MotionDict),
    motion_mirror_line(Motion, Window, MirrorLine),
    verts_dicts(Verts, PreDs),
    verts_dicts(ImgVerts, ImgDs),
    % Frame 1: the pre-image alone.
    Scene1 = _{ format: "rigid-motion", version: 2,
                axes: Axes, preImage: PreDs, image: [],
                motion: MotionDict, mirrorLine: MirrorLine },
    F1 = _{ step: 1, verb: "place_preimage",
            caption: "Place the pre-image: the figure before the motion.",
            sceneChanged: true, scene: Scene1 },
    % Frame 2: the image under the motion.
    Scene2 = _{ format: "rigid-motion", version: 2,
                axes: Axes, preImage: PreDs, image: ImgDs,
                motion: MotionDict, mirrorLine: MirrorLine },
    motion_verb(Motion, Verb2),
    motion_caption(Motion, Cap2),
    F2 = _{ step: 2, verb: Verb2, caption: Cap2, sceneChanged: true, scene: Scene2 }.

motion_verb(translation(_, _), "translate") :- !.
motion_verb(reflection(_), "reflect") :- !.
motion_verb(rotation(_, _, _), "rotate") :- !.

motion_caption(translation(DX, DY), Cap) :-
    !,
    format(string(Cap),
           "Slide every vertex by (~w, ~w). The image is congruent to the pre-image: the motion moves it without changing size or shape.",
           [DX, DY]).
motion_caption(reflection(Axis), Cap) :-
    !,
    format(string(Cap),
           "Reflect the figure across the ~w-axis. Each vertex keeps its distance to the mirror line, so the image is congruent with its orientation reversed.",
           [Axis]).
motion_caption(rotation(CX, CY, Deg), Cap) :-
    !,
    format(string(Cap),
           "Turn the figure ~w degrees about (~w, ~w). Rotation keeps every length and angle, so the image is congruent.",
           [Deg, CX, CY]).

motion_result(translation(DX, DY), Str) :-
    !,
    format(string(Str), "translation by (~w, ~w)", [DX, DY]).
motion_result(reflection(Axis), Str) :-
    !,
    format(string(Str), "reflection across the ~w-axis", [Axis]).
motion_result(rotation(CX, CY, Deg), Str) :-
    !,
    format(string(Str), "rotation of ~w degrees about (~w, ~w)", [Deg, CX, CY]).

motion_dict(translation(DX, DY), _{ kind: "translation", dx: DX, dy: DY }) :- !.
motion_dict(reflection(Axis), _{ kind: "reflection", axis: AxisStr }) :-
    !,
    atom_string(Axis, AxisStr).
motion_dict(rotation(CX, CY, Deg), _{ kind: "rotation", cx: CX, cy: CY, deg: Deg }) :- !.

%!  motion_mirror_line(+Motion, +Window, -MirrorLine) is det.
%   A reflection carries the axis it mirrors across as a stroke-only line spanning
%   the window; every other motion carries mirrorLine null.
motion_mirror_line(reflection(x), Window, _{ x1: XMin, y1: 0, x2: XMax, y2: 0 }) :-
    !,
    _{ x_min: XMin, x_max: XMax } :< Window.
motion_mirror_line(reflection(y), Window, _{ x1: 0, y1: YMin, x2: 0, y2: YMax }) :-
    !,
    _{ y_min: YMin, y_max: YMax } :< Window.
motion_mirror_line(_, _, null).


% =============================================================================
% Reflection-by-rotation break — the chiral tile's mirror image.
% =============================================================================

%!  prod_reflection_frames(+Verts, +MirrorVerts, -Frames) is det.
%   The honest reflection across the y-axis: pre-image, then the true mirror image.
prod_reflection_frames(Verts, MirrorVerts, [F1, F2]) :-
    motion_window(Verts, MirrorVerts, reflection(y), Window),
    axes_dict(Window, Axes),
    motion_mirror_line(reflection(y), Window, MirrorLine),
    motion_dict(reflection(y), MotionDict),
    verts_dicts(Verts, PreDs),
    verts_dicts(MirrorVerts, ImgDs),
    Scene1 = _{ format: "rigid-motion", version: 2,
                axes: Axes, preImage: PreDs, image: [],
                motion: MotionDict, mirrorLine: MirrorLine },
    F1 = _{ step: 1, verb: "place_preimage",
            caption: "Place the pre-image.",
            sceneChanged: true, scene: Scene1 },
    Scene2 = _{ format: "rigid-motion", version: 2,
                axes: Axes, preImage: PreDs, image: ImgDs,
                motion: MotionDict, mirrorLine: MirrorLine },
    F2 = _{ step: 2, verb: "reflect",
            caption: "Reflect across the y-axis. The image is congruent, with its orientation reversed.",
            sceneChanged: true, scene: Scene2 }.

%!  def_break_frames(+Verts, +MirrorVerts, +RotVerts, -Frames) is det.
%   The deformation: rotating 180 degrees about the origin (role deformation)
%   against the true mirror image (role image). The rotated tile keeps the
%   figure's orientation, so it does not land on the mirror image. The axis window
%   spans the pre-image, the true image, and the rotated attempt.
def_break_frames(Verts, MirrorVerts, RotVerts, [F1, F2]) :-
    break_window([Verts, MirrorVerts, RotVerts], Window),
    axes_dict(Window, Axes),
    motion_mirror_line(reflection(y), Window, MirrorLine),
    MotionDict = _{ kind: "rotation", cx: 0, cy: 0, deg: 180 },
    verts_dicts(Verts, PreDs),
    verts_dicts(MirrorVerts, ImgDs),
    verts_dicts(RotVerts, DefDs),
    Scene1 = _{ format: "rigid-motion", version: 2,
                axes: Axes, preImage: PreDs, image: [],
                motion: MotionDict, mirrorLine: MirrorLine },
    F1 = _{ step: 1, verb: "place_preimage",
            caption: "Place the chiral pre-image: a figure with no line of symmetry.",
            sceneChanged: true, scene: Scene1 },
    Scene2 = _{ format: "rigid-motion", version: 2,
                axes: Axes, preImage: PreDs, image: ImgDs, deformation: DefDs,
                motion: MotionDict, mirrorLine: MirrorLine },
    F2 = _{ step: 2, verb: "rotate_instead_of_reflect",
            caption: "Rotating 180 degrees about the origin keeps the figure's orientation, so the rotated tile (deformation) does not land on the true mirror image across the y-axis. A reflection reverses orientation and no in-plane rotation does, so the mirror image of a chiral tile is unreachable by rotation; reaching it needs a flip out of the plane.",
            sceneChanged: true, scene: Scene2 }.

break_note(Note) :-
    Note = "A chiral figure has no line of symmetry, so its mirror image cannot be produced by any rotation within the plane. The deformation attempts the reflection by rotating 180 degrees about the origin: because rotation preserves orientation and reflection reverses it, the rotated tile does not coincide with the true mirror image. Reaching the mirror image needs a flip through the third dimension. (Reflection-by-rotation family; literature-only.)".


% =============================================================================
% Isometry geometry — every image vertex stays an integer pair.
% =============================================================================

motion_image(Verts, translation(DX, DY), Img) :-
    !,
    maplist(translate_pt(DX, DY), Verts, Img).
motion_image(Verts, reflection(Axis), Img) :-
    !,
    maplist(reflect_pt(Axis), Verts, Img).
motion_image(Verts, rotation(CX, CY, Deg), Img) :-
    !,
    maplist(rotate_pt(CX, CY, Deg), Verts, Img).

translate_pt(DX, DY, X-Y, X1-Y1) :-
    X1 is X + DX,
    Y1 is Y + DY.

% reflect_pt(x): across the x-axis (mirror line y=0). reflect_pt(y): across the
% y-axis (mirror line x=0).
reflect_pt(x, X-Y, X-NY) :- !, NY is -Y.
reflect_pt(y, X-Y, NX-Y) :- !, NX is -X.

% Counterclockwise quarter turns about (CX, CY); each keeps integer coordinates.
rotate_pt(CX, CY, 90, X-Y, RX-RY) :-
    !,
    RX is CX - (Y - CY),
    RY is CY + (X - CX).
rotate_pt(CX, CY, 180, X-Y, RX-RY) :-
    !,
    RX is 2 * CX - X,
    RY is 2 * CY - Y.
rotate_pt(CX, CY, 270, X-Y, RX-RY) :-
    !,
    RX is CX + (Y - CY),
    RY is CY - (X - CX).


% =============================================================================
% Chirality under the lattice-preserving rigid motions this format draws.
% =============================================================================

%!  chiral_under_lattice_rotations(+Verts) is semidet.
%   True when no quarter-turn rotation of the figure's mirror image can be slid
%   back onto the figure. This is exactly the condition under which the reflection
%   is unreachable by rotation within the isometries this format draws (0/90/180/
%   270-degree turns): the honest, decidable scope for the break. A figure with a
%   line of symmetry fails this guard, so no break is drawn for it.
chiral_under_lattice_rotations(Verts) :-
    maplist(reflect_pt(y), Verts, Mirror),
    \+ ( member(Deg, [0, 90, 180, 270]),
         rotate_or_identity(Deg, Mirror, Rotated),
         congruent_by_translation(Rotated, Verts) ).

rotate_or_identity(0, Verts, Verts) :- !.
rotate_or_identity(Deg, Verts, Rotated) :-
    maplist(rotate_pt(0, 0, Deg), Verts, Rotated).

%!  congruent_by_translation(+A, +B) is semidet.
%   The two vertex sets coincide once each is slid so its lowest-left corner sits
%   at the origin. A sound test for "reachable by this rotation": if the sets do
%   not coincide under any of the four turns, the mirror image is not reachable.
congruent_by_translation(A, B) :-
    normalize_vertices(A, NA),
    normalize_vertices(B, NB),
    NA == NB.

normalize_vertices(Verts, Norm) :-
    findall(X, member(X-_, Verts), Xs),
    findall(Y, member(_-Y, Verts), Ys),
    min_list(Xs, MinX),
    min_list(Ys, MinY),
    findall(DX-DY,
            ( member(X-Y, Verts), DX is X - MinX, DY is Y - MinY ),
            Shifted),
    sort(Shifted, Norm).


% =============================================================================
% Axis window — an integer window that shows the origin and every drawn vertex.
% =============================================================================

%!  motion_window(+Verts, +ImgVerts, +Motion, -Window) is det.
%   The window spans zero and every pre-image and image vertex, plus the center of
%   a rotation, so the origin, the mirror lines, and both figures stay legible.
motion_window(Verts, ImgVerts, Motion, Window) :-
    motion_extra_points(Motion, Extra),
    append([Verts, ImgVerts, Extra], AllPoints),
    points_window(AllPoints, Window).

motion_extra_points(rotation(CX, CY, _), [CX-CY]) :- !.
motion_extra_points(_, []).

break_window(VertLists, Window) :-
    append(VertLists, AllPoints),
    points_window(AllPoints, Window).

points_window(Points, Window) :-
    findall(X, member(X-_, Points), Xs),
    findall(Y, member(_-Y, Points), Ys),
    bounds_with_zero(Xs, XMin, XMax),
    bounds_with_zero(Ys, YMin, YMax),
    Window = _{ x_min: XMin, x_max: XMax, y_min: YMin, y_max: YMax }.

%!  bounds_with_zero(+Values, -Min, -Max) is det.
%   The min and max of Values together with 0, each pushed out one unit so a
%   vertex never sits on the window edge.
bounds_with_zero(Values, Min, Max) :-
    Lo0 = [0|Values],
    min_list(Lo0, RawMin),
    max_list(Lo0, RawMax),
    Min is RawMin - 1,
    Max is RawMax + 1.

axes_dict(Window, _{ xMin: XMin, xMax: XMax, yMin: YMin, yMax: YMax }) :-
    _{ x_min: XMin, x_max: XMax, y_min: YMin, y_max: YMax } :< Window.


% =============================================================================
% Spec parsing + helpers.
% =============================================================================

%!  parse_shape(+Raw, -Verts) is semidet.
%   Read a polygon into an ordered X-Y vertex list. A malformed vertex fails the
%   whole parse (the drawer must never receive a partial polygon), so an unusable
%   shape drops to the graceful-degradation path. A polygon needs three vertices.
parse_shape(Raw, Verts) :-
    is_list(Raw),
    maplist(shape_vertex, Raw, Verts),
    length(Verts, N),
    N >= 3.

shape_vertex(X-Y, X-Y) :- integer(X), integer(Y).
shape_vertex([X, Y], X-Y) :- integer(X), integer(Y).
shape_vertex(point(X, Y), X-Y) :- integer(X), integer(Y).

reflect_axis(mirror_x, x).
reflect_axis(mirror_y, y).

parse_center(point(X, Y), X, Y) :- integer(X), integer(Y).
parse_center(X-Y, X, Y) :- integer(X), integer(Y).
parse_center([X, Y], X, Y) :- integer(X), integer(Y).
parse_center(origin, 0, 0).

rotation_deg(Deg) :- memberchk(Deg, [90, 180, 270]).

verts_dicts(Verts, Dicts) :- maplist(vert_dict, Verts, Dicts).
vert_dict(X-Y, _{ x: X, y: Y }).

shape_string(Verts, Str) :-
    findall([X, Y], member(X-Y, Verts), Pairs),
    term_to_string(Pairs, Str).

shape_string_raw(Raw, Str) :- term_to_string(Raw, Str).

%!  gen_frames(+Spec, -Frames) for the frames-only entry point.
gen_frames(translate(Shape, DX, DY), Frames) :-
    parse_shape(Shape, Verts), integer(DX), integer(DY),
    !,
    motion_frames(Verts, translation(DX, DY), Frames).
gen_frames(reflect(Shape, Mirror), Frames) :-
    parse_shape(Shape, Verts), reflect_axis(Mirror, Axis),
    !,
    motion_frames(Verts, reflection(Axis), Frames).
gen_frames(rotate(Shape, Center, Deg), Frames) :-
    parse_shape(Shape, Verts), parse_center(Center, CX, CY), rotation_deg(Deg),
    !,
    motion_frames(Verts, rotation(CX, CY, Deg), Frames).

%!  deferred_frame(+Spec, -Frame) is det.
%   An undrawable spec is annotation-only: an empty plane, no throw.
deferred_frame(Spec, Frame) :-
    term_to_string(Spec, SpecStr),
    format(string(Cap), "No rigid-motion picture for ~w; nothing drawn.", [SpecStr]),
    Scene = _{ format: "rigid-motion", version: 2,
               axes: _{ xMin: -1, xMax: 1, yMin: -1, yMax: 1 },
               preImage: [], image: [], motion: null, mirrorLine: null },
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
