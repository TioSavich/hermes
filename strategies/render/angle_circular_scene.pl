/** <module> Angle / circular scene compiler (spatial family)
 *
 * Compiles a turning task into angle-circular scene frames on the frozen render
 * contract (docs/render-contract-v2.md,
 * §2 spatial family). This is a sibling of the coordinate-plane compiler: it
 * extends the catalog past the arithmetic/number region into the K-8 spatial
 * representations tallied in
 * docs/research/2026-07-08-hermes-spatial-representation-gap-tally.md (section 6).
 *
 * An angle encodes an amount of turning: two rays from a vertex with an arc that
 * marks the turn between them. The measure is a fact about the turn, not about
 * how far the rays are drawn. This compiler emits PIXELS for the vertex plus a
 * whole-degree angle and a pixel length per ray; the drawer computes each ray
 * endpoint via cos/sin, exactly as the coordinate-plane drawer scales math to its
 * own band. Every coordinate the compiler emits is an integer.
 *
 * Two productive Spec shapes, one format ("angle-circular", version 2):
 *
 *   - angle(Degrees)  : two rays from a vertex with an arc of Degrees. The
 *     filmstrip lands the initial ray, turns through the arc, then draws the
 *     terminal ray. Denotes the task angle_measure(Degrees).
 *   - sector(Degrees) : the same turn, then filled as a central-angle sector
 *     (role "sector"), so a slice reads as Degrees/360 of the circle. Denotes
 *     angle_measure(Degrees) and bridges to the pie/circle graph.
 *
 * The characteristic break (the grammar's deformation lane) is the ray-length
 * error: an angle drawn with much longer rays, read as a BIGGER angle. Ray length
 * is irrelevant to angle measure; the turn is unchanged. It is reachable ONLY
 * through angle_circular_compare_json/2 (the grammar's angle_as_ray_length lane);
 * no productive Spec draws over-long rays and calls the angle bigger.
 *
 * Semantic color ROLES only (contract §3): the filled central-angle sector
 * carries role "sector"; the over-long rays of the break carry role
 * "deformation". Productive rays and the arc are figure stroke and carry no role.
 * This compiler never emits a hex string.
 *
 * Graceful degradation: a Spec with no drawable angle (a non-integer or
 * out-of-range degree measure) yields an explicit error document with frames:[]
 * rather than a faked picture (contract §2).
 */

:- module(angle_circular_scene,
          [ angle_circular_render_frames/2,   % +Spec, -Frames
            angle_circular_render_json/2,      % +Spec, -Dict
            angle_circular_compare_json/2,     % +Spec, -Dict (ray-length deformation)
            angle_circular_render_to_file/2    % +Spec, +Path
          ]).

:- use_module(library(http/json), [json_write_dict/3]).
:- use_module(library(lists)).

% =============================================================================
% Fixed pixel geometry. The format is pixel-friendly: the compiler places the
% vertex and sizes the rays/arc/sector in px, and the drawer turns a whole-degree
% angle plus a px length into a ray endpoint via cos/sin. Every value is integer.
% =============================================================================

ac_vertex(220, 200).       % the shared vertex (px)
ac_ray_len(150).           % the reference ray length (px)
ac_long_len(300).          % the over-long ray length of the ray-length break (px)
ac_arc_radius(56).         % the turn-arc radius (px)
ac_sector_radius(96).      % the filled-sector radius (px)
ac_canvas(_{ width: 440, height: 380 }).

% =============================================================================
% Public API
% =============================================================================

%!  angle_circular_render_frames(+Spec, -Frames) is det.
%
%   Walk Spec into a list of frame dicts. A Spec that cannot be drawn yields a
%   single annotation-only frame (sceneChanged:false), so nothing throws.
angle_circular_render_frames(Spec, Frames) :-
    ( gen_frames(Spec, Frames0)
    -> Frames = Frames0
    ;  deferred_frame(Spec, F),
       Frames = [F]
    ).

%!  angle_circular_render_json(+Spec, -Dict) is det.
%
%   The full render document: kind / request / result / canvas / frames
%   (contract §1.1). On an undrawable Spec, an explicit error string and frames:[].
angle_circular_render_json(angle(Degrees), Dict) :-
    !,
    ( valid_angle(Degrees)
    -> angle_frames(Degrees, Frames),
       format(string(ResultStr), "~w-degree angle", [Degrees]),
       ac_canvas(Canvas),
       Dict = _{ kind: "angle",
                 request: _{ degrees: Degrees },
                 result: ResultStr,
                 canvas: Canvas,
                 frames: Frames }
    ;  Dict = _{ kind: "angle",
                 request: _{ degrees: Degrees },
                 error: "An angle needs a whole-number degree measure in 1..360.",
                 frames: [] }
    ).
angle_circular_render_json(sector(Degrees), Dict) :-
    !,
    ( valid_angle(Degrees)
    -> sector_frames(Degrees, Frames),
       format(string(ResultStr), "~w-degree central-angle sector", [Degrees]),
       ac_canvas(Canvas),
       Dict = _{ kind: "sector",
                 request: _{ degrees: Degrees },
                 result: ResultStr,
                 canvas: Canvas,
                 frames: Frames }
    ;  Dict = _{ kind: "sector",
                 request: _{ degrees: Degrees },
                 error: "A sector needs a whole-number degree measure in 1..360.",
                 frames: [] }
    ).
angle_circular_render_json(Spec, Dict) :-
    angle_circular_render_frames(Spec, Frames),
    term_to_string(Spec, SpecStr),
    ac_canvas(Canvas),
    Dict = _{ kind: SpecStr,
              request: _{ spec: SpecStr },
              result: "unknown",
              canvas: Canvas,
              frames: Frames }.

%!  angle_circular_compare_json(+Spec, -Dict) is det.
%
%   The ray-length-error compare document: a productive filmstrip that draws the
%   angle at the reference length beside a deformation filmstrip that redraws the
%   SAME turn with much longer rays and reads it as a bigger angle. Spec is
%   angle_length_compare(Degrees, ShortLen, LongLen). On a request with no longer
%   length to stretch (or an out-of-range angle), an explicit error and empty
%   filmstrips.
angle_circular_compare_json(angle_length_compare(Degrees, ShortLen, LongLen), Dict) :-
    !,
    ( valid_angle(Degrees),
      integer(ShortLen), integer(LongLen),
      ShortLen > 0, LongLen > ShortLen
    -> ac_vertex(VX, VY), ac_arc_radius(ArcR),
       Vertex = _{ x: VX, y: VY },
       prod_angle_frames(Degrees, ShortLen, ArcR, Vertex, ProdFrames),
       def_angle_frames(Degrees, ShortLen, LongLen, ArcR, Vertex, DefFrames),
       compare_note(Degrees, ShortLen, LongLen, Note),
       ac_canvas(Canvas),
       Dict = _{ kind: "angle_vs_ray_length_stretched_angle",
                 request: _{ degrees: Degrees, short_length: ShortLen, long_length: LongLen },
                 productiveKind: "angle",
                 deformationKind: "ray_length_stretched_angle",
                 family: "angle_confused_with_ray_length",
                 correct_angle: _{ degrees: Degrees, ray_length: ShortLen },
                 deformed_angle: _{ degrees: Degrees, drawn_length: LongLen, read_as: "bigger" },
                 note: Note,
                 canvas: Canvas,
                 productive: _{ frames: ProdFrames },
                 deformation: _{ frames: DefFrames } }
    ;  Dict = _{ kind: "angle_vs_ray_length_stretched_angle",
                 request: _{ degrees: Degrees },
                 error: "Ray-length comparison needs a valid angle (1..360 deg) and a longer draw length than the reference.",
                 productive: _{ frames: [] },
                 deformation: _{ frames: [] } }
    ).
angle_circular_compare_json(Spec, _{ kind: SpecStr,
                                     error: "Unknown angle-circular compare spec.",
                                     productive: _{ frames: [] },
                                     deformation: _{ frames: [] } }) :-
    term_to_string(Spec, SpecStr).

%!  angle_circular_render_to_file(+Spec, +Path) is det.
angle_circular_render_to_file(Spec, Path) :-
    angle_circular_render_json(Spec, Dict),
    setup_call_cleanup(
        open(Path, write, Stream),
        json_write_dict(Stream, Dict, [width(80)]),
        close(Stream)).


% =============================================================================
% angle(Degrees) — first ray, turn through the arc, second ray.
% =============================================================================

%!  angle_frames(+Degrees, -Frames) is det.
%   Three frames: draw the initial ray, turn through the arc of Degrees, then draw
%   the terminal ray so the arc records the turn between the two rays.
angle_frames(Degrees, [F1, F2, F3]) :-
    ac_vertex(VX, VY), ac_ray_len(L), ac_arc_radius(ArcR),
    Vertex = _{ x: VX, y: VY },
    ray_dict(0, L, R0),
    ray_dict(Degrees, L, R1),
    zero_arc(ArcR, ZeroArc),
    turn_arc(Degrees, ArcR, TurnArc),
    degree_label(Degrees, Label),
    % Frame 1: the initial ray along the baseline, no turn yet.
    Scene1 = _{ format: "angle-circular", version: 2, vertex: Vertex,
                rays: [R0], arc: ZeroArc, sector: null, label: "0" },
    F1 = _{ step: 1, verb: "draw_initial_ray",
            caption: "Start with one ray from the vertex along the baseline.",
            sceneChanged: true, scene: Scene1 },
    % Frame 2: turn through the arc; the angle is the amount of turn.
    Scene2 = _{ format: "angle-circular", version: 2, vertex: Vertex,
                rays: [R0], arc: TurnArc, sector: null, label: Label },
    format(string(Cap2),
           "Turn through ~w degrees: the angle is the amount of turn, not the length of the rays.",
           [Degrees]),
    F2 = _{ step: 2, verb: "turn", caption: Cap2, sceneChanged: true, scene: Scene2 },
    % Frame 3: the terminal ray; the arc records the turn between the rays.
    Scene3 = _{ format: "angle-circular", version: 2, vertex: Vertex,
                rays: [R0, R1], arc: TurnArc, sector: null, label: Label },
    format(string(Cap3),
           "Draw the second ray at ~w degrees; the arc records the turn between the rays.",
           [Degrees]),
    F3 = _{ step: 3, verb: "draw_terminal_ray", caption: Cap3, sceneChanged: true, scene: Scene3 }.


% =============================================================================
% sector(Degrees) — the same turn, filled as a central-angle sector.
% =============================================================================

%!  sector_frames(+Degrees, -Frames) is det.
%   Three frames: the initial ray, the turn to the terminal ray, then the filled
%   central-angle sector (role "sector") so the slice reads as Degrees/360.
sector_frames(Degrees, [F1, F2, F3]) :-
    ac_vertex(VX, VY), ac_ray_len(L), ac_arc_radius(ArcR), ac_sector_radius(SecR),
    Vertex = _{ x: VX, y: VY },
    ray_dict(0, L, R0),
    ray_dict(Degrees, L, R1),
    zero_arc(ArcR, ZeroArc),
    turn_arc(Degrees, ArcR, TurnArc),
    sector_dict(Degrees, SecR, Sector),
    degree_label(Degrees, Label),
    % Frame 1: the initial ray from the center.
    Scene1 = _{ format: "angle-circular", version: 2, vertex: Vertex,
                rays: [R0], arc: ZeroArc, sector: null, label: "0" },
    F1 = _{ step: 1, verb: "draw_initial_ray",
            caption: "Start with one ray from the center along the baseline.",
            sceneChanged: true, scene: Scene1 },
    % Frame 2: turn to the terminal ray, marking the central angle.
    Scene2 = _{ format: "angle-circular", version: 2, vertex: Vertex,
                rays: [R0, R1], arc: TurnArc, sector: null, label: Label },
    format(string(Cap2),
           "Turn through ~w degrees to the second ray, marking the central angle.",
           [Degrees]),
    F2 = _{ step: 2, verb: "turn", caption: Cap2, sceneChanged: true, scene: Scene2 },
    % Frame 3: fill the central-angle sector (role "sector").
    Scene3 = _{ format: "angle-circular", version: 2, vertex: Vertex,
                rays: [R0, R1], arc: TurnArc, sector: Sector, label: Label },
    format(string(Cap3),
           "Fill the central-angle sector: the slice is ~w/360 of the circle.",
           [Degrees]),
    F3 = _{ step: 3, verb: "fill_sector", caption: Cap3, sceneChanged: true, scene: Scene3 }.


% =============================================================================
% Compare — the productive angle beside the ray-length-stretched angle.
% =============================================================================

%!  prod_angle_frames(+Degrees, +L, +ArcR, +Vertex, -Frames) is det.
%   One frame: the angle drawn at the reference length, correctly measured.
prod_angle_frames(Degrees, L, ArcR, Vertex, [F]) :-
    ray_dict(0, L, R0),
    ray_dict(Degrees, L, R1),
    turn_arc(Degrees, ArcR, TurnArc),
    degree_label(Degrees, Label),
    Scene = _{ format: "angle-circular", version: 2, vertex: Vertex,
               rays: [R0, R1], arc: TurnArc, sector: null, label: Label },
    format(string(Cap),
           "Draw the ~w-degree angle: the arc is the turn between the rays.",
           [Degrees]),
    F = _{ step: 1, verb: "draw_angle", caption: Cap, sceneChanged: true, scene: Scene }.

%!  def_angle_frames(+Degrees, +ShortLen, +LongLen, +ArcR, +Vertex, -Frames) is det.
%   Two frames: the true angle at the reference length, then the SAME turn redrawn
%   with much longer rays (role "deformation") over the reference rays. The arc's
%   sweep is unchanged, so the picture names the error precisely: the rays got
%   longer, the angle did not.
def_angle_frames(Degrees, ShortLen, LongLen, ArcR, Vertex, [F1, F2]) :-
    ray_dict(0, ShortLen, S0),
    ray_dict(Degrees, ShortLen, S1),
    def_ray_dict(0, LongLen, L0),
    def_ray_dict(Degrees, LongLen, L1),
    turn_arc(Degrees, ArcR, TurnArc),
    degree_label(Degrees, Label),
    % Frame 1: the true angle at the reference length.
    Scene1 = _{ format: "angle-circular", version: 2, vertex: Vertex,
                rays: [S0, S1], arc: TurnArc, sector: null, label: Label },
    format(string(Cap1),
           "The angle measures ~w degrees, the amount of turn between the rays.",
           [Degrees]),
    F1 = _{ step: 1, verb: "measure_angle", caption: Cap1, sceneChanged: true, scene: Scene1 },
    % Frame 2: the same turn redrawn with longer rays, read as bigger (the error).
    Scene2 = _{ format: "angle-circular", version: 2, vertex: Vertex,
                rays: [S0, S1, L0, L1], arc: TurnArc, sector: null, label: Label },
    format(string(Cap2),
           "Redrawing the same ~w-degree turn with longer rays does not change the angle; reading the longer rays as a bigger angle is the ray-length error.",
           [Degrees]),
    F2 = _{ step: 2, verb: "stretch_rays", caption: Cap2, sceneChanged: true, scene: Scene2 }.

compare_note(Degrees, ShortLen, LongLen, Note) :-
    format(string(Note),
           "The angle measures ~w degrees whether the rays are drawn ~w px or ~w px long: \
angle measure is the amount of turn between the rays, and ray length carries none of it. \
Reading the longer-drawn rays as a bigger angle is the ray-length error. \
(Angle-confused-with-ray-length family.)",
           [Degrees, ShortLen, LongLen]).


% =============================================================================
% Primitive dicts.
% =============================================================================

%!  ray_dict(+AngleDeg, +Length, -Dict) is det.
%   A ray at AngleDeg (whole degrees, counterclockwise from the baseline) drawn
%   Length px from the vertex; the drawer computes the endpoint via cos/sin.
ray_dict(AngleDeg, Length, _{ angleDeg: AngleDeg, length: Length }).

%!  def_ray_dict(+AngleDeg, +Length, -Dict) is det.
%   A ray carrying role "deformation": the over-long ray of the ray-length break.
def_ray_dict(AngleDeg, Length, _{ angleDeg: AngleDeg, length: Length, role: "deformation" }).

%!  zero_arc(+Radius, -Dict) is det.  A degenerate arc: no turn drawn yet.
zero_arc(Radius, _{ radius: Radius, startDeg: 0, sweepDeg: 0 }).

%!  turn_arc(+Degrees, +Radius, -Dict) is det.  The arc marking a turn of Degrees.
turn_arc(Degrees, Radius, _{ radius: Radius, startDeg: 0, sweepDeg: Degrees }).

%!  sector_dict(+Degrees, +Radius, -Dict) is det.  The filled central-angle sector.
sector_dict(Degrees, Radius,
            _{ radius: Radius, startDeg: 0, sweepDeg: Degrees, role: "sector" }).

%!  degree_label(+Degrees, -Label) is det.  The degree label as a string.
degree_label(Degrees, Label) :- format(string(Label), "~w", [Degrees]).


% =============================================================================
% Helpers.
% =============================================================================

%!  valid_angle(+Degrees) is semidet.
%   A drawable angle measure: a whole number of degrees in 1..360.
valid_angle(Degrees) :-
    integer(Degrees),
    Degrees > 0,
    Degrees =< 360.

%!  gen_frames(+Spec, -Frames) for the frames-only entry point.
gen_frames(angle(Degrees), Frames) :-
    valid_angle(Degrees),
    !,
    angle_frames(Degrees, Frames).
gen_frames(sector(Degrees), Frames) :-
    valid_angle(Degrees),
    !,
    sector_frames(Degrees, Frames).

%!  deferred_frame(+Spec, -Frame) is det.
%   An undrawable spec is annotation-only: a bare vertex, no turn, no throw.
deferred_frame(Spec, Frame) :-
    term_to_string(Spec, SpecStr),
    format(string(Cap), "No angle-circular drawing for ~w; nothing drawn.", [SpecStr]),
    ac_vertex(VX, VY),
    Scene = _{ format: "angle-circular", version: 2,
               vertex: _{ x: VX, y: VY }, rays: [],
               arc: _{ radius: 0, startDeg: 0, sweepDeg: 0 },
               sector: null, label: "" },
    Frame = _{ step: 1, verb: SpecStr, caption: Cap,
               sceneChanged: false, scene: Scene }.

%!  term_to_string(+Term, -String) is det.
term_to_string(Term, String) :-
    ( string(Term)
    -> String = Term
    ;  format(string(String), '~w', [Term])
    ).
