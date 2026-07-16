/** <module> Solid-net scene compiler (spatial family)
 *
 * Compiles a solids task into solid-net scene frames on the frozen render
 * contract (docs/research_assets/specs/2026-06-23-render-contract-frozen.md,
 * §2 solid-net). The spatial family extends the catalog past the
 * arithmetic/number region into the K-8 spatial representations tallied in
 * docs/research/2026-07-08-hermes-spatial-representation-gap-tally.md.
 *
 * A solid unfolds to a planar net: an arrangement of its faces joined at fold
 * creases. Where the number-line compiler is driven by a strategy-trace witness,
 * this compiler computes its geometry directly from the named solid: the layout
 * of a cube net is a fact about the cube, not the running history of an automaton.
 *
 * The scene format uses PIXEL coordinates (unlike the coordinate-plane compiler,
 * which emits math coordinates). Each face is a polygon of integer pixel vertices;
 * the drawer draws one <polygon> per face and one dashed <line> per fold crease.
 *
 * Two productive Spec shapes, one format ("solid-net", version 2):
 *
 *   - net_of(Solid) : Solid in {cube, square_pyramid, triangular_prism,
 *     rectangular_prism}. The filmstrip lays out one face per frame, then a final
 *     frame marks the fold creases. Denotes the task net(Solid). mode "net".
 *   - unit_cube_stack(L, W, H) : an isometric drawing of an L-by-W-by-H stack of
 *     unit cubes (volume by unit cubes, 5.MD.3-5). Two frames: the front layer,
 *     then the depth that closes the box. Denotes solid_volume(L, W, H). mode
 *     "isometric".
 *
 * The characteristic break (the grammar's deformation lane) is the unfoldable
 * arrangement: net_does_not_fold(Solid, BadArrangement). An arrangement carries
 * the RIGHT NUMBER of faces for the named solid, but placed so two would land on
 * the same side when folded, so the tiles never close to the solid. For a cube
 * the named arrangement is a 2-by-3 block of six squares: it contains a 2-by-2
 * sub-square, and folding forces two faces to overlap. It is reachable ONLY
 * through the compare form and only via the misconception lane; no productive
 * Spec emits an unfoldable arrangement.
 *
 * Semantic color ROLES only (contract §3): a net or solid face carries role
 * "face"; the faces of an unfoldable arrangement carry role "deformation". Fold
 * creases and edges are stroke, not fill. This compiler never emits a hex string.
 *
 * Graceful degradation: a Spec with no net layout (an unsupported solid, a
 * non-positive dimension) yields an explicit error document with frames:[] rather
 * than a faked picture (contract §2).
 */

:- module(solid_net_scene,
          [ solid_net_render_frames/2,   % +Spec, -Frames
            solid_net_render_json/2,      % +Spec, -Dict
            solid_net_compare_json/2,     % +Spec, -Dict (unfoldable-arrangement break)
            solid_net_render_to_file/2    % +Spec, +Path
          ]).

:- use_module(library(http/json), [json_write_dict/3]).
:- use_module(library(lists)).

% =============================================================================
% Public API
% =============================================================================

%!  solid_net_render_frames(+Spec, -Frames) is det.
%
%   Walk Spec into a list of frame dicts. A Spec that cannot be drawn yields a
%   single annotation-only frame (sceneChanged:false), so nothing throws.
solid_net_render_frames(Spec, Frames) :-
    ( gen_frames(Spec, Frames0)
    -> Frames = Frames0
    ;  deferred_frame(Spec, F),
       Frames = [F]
    ).

%!  solid_net_render_json(+Spec, -Dict) is det.
%
%   The full render document: kind / request / result / canvas / frames
%   (contract §1.1). On an undrawable Spec, an explicit error string and frames:[].
solid_net_render_json(net_of(Solid), Dict) :-
    !,
    solid_string(Solid, SolidStr),
    ( supported_solid(Solid)
    -> net_layout(Solid, Faces, Creases),
       net_frames(Solid, Faces, Creases, Frames),
       length(Faces, N),
       format(string(ResultStr), "net of ~w (~w faces)", [SolidStr, N]),
       canvas_dict(Canvas),
       Dict = _{ kind: "net_of",
                 request: _{ solid: SolidStr },
                 result: ResultStr,
                 canvas: Canvas,
                 frames: Frames }
    ;  Dict = _{ kind: "net_of",
                 request: _{ solid: SolidStr },
                 error: "No net layout for this solid; supported solids are cube, square_pyramid, triangular_prism, rectangular_prism.",
                 frames: [] }
    ).
solid_net_render_json(unit_cube_stack(L, W, H), Dict) :-
    !,
    ( positive_int(L), positive_int(W), positive_int(H)
    -> stack_frames(L, W, H, Frames),
       Volume is L * W * H,
       format(string(ResultStr), "~wx~wx~w stack: ~w unit cubes", [L, W, H, Volume]),
       canvas_dict(Canvas),
       Dict = _{ kind: "unit_cube_stack",
                 request: _{ length: L, width: W, height: H, volume: Volume },
                 result: ResultStr,
                 canvas: Canvas,
                 frames: Frames }
    ;  Dict = _{ kind: "unit_cube_stack",
                 request: _{ length: L, width: W, height: H },
                 error: "A unit-cube stack needs positive integer length, width, and height.",
                 frames: [] }
    ).
solid_net_render_json(Spec, Dict) :-
    solid_net_render_frames(Spec, Frames),
    term_to_string(Spec, SpecStr),
    canvas_dict(Canvas),
    Dict = _{ kind: SpecStr,
              request: _{ spec: SpecStr },
              result: "unknown",
              canvas: Canvas,
              frames: Frames }.

%!  solid_net_compare_json(+Spec, -Dict) is det.
%
%   The unfoldable-arrangement compare document: a productive filmstrip that lays
%   out the true net of Solid beside a deformation filmstrip that lays out an
%   arrangement carrying the same number of faces but placed so it cannot fold to
%   the solid. Spec is net_fold_compare(Solid). On a solid with no named
%   unfoldable arrangement, an explicit error and empty filmstrips.
solid_net_compare_json(net_fold_compare(Solid), Dict) :-
    !,
    solid_string(Solid, SolidStr),
    ( supported_solid(Solid),
      bad_arrangement(Solid, BadName, BadFaces, BadCreases)
    -> net_layout(Solid, GoodFaces, GoodCreases),
       net_frames(Solid, GoodFaces, GoodCreases, ProdFrames),
       bad_frames(Solid, BadFaces, BadCreases, DefFrames),
       length(GoodFaces, FaceCount),
       solid_string(BadName, BadNameStr),
       compare_note(SolidStr, BadNameStr, FaceCount, Note),
       canvas_dict(Canvas),
       Dict = _{ kind: "net_vs_unfoldable_arrangement",
                 request: _{ solid: SolidStr },
                 productiveKind: "net_of",
                 deformationKind: "net_does_not_fold",
                 family: "net_fold_failure",
                 solid: SolidStr,
                 face_count: FaceCount,
                 bad_arrangement: BadNameStr,
                 violation: "net_faces_do_not_fold_to_solid",
                 provenance: "literature_only",
                 note: Note,
                 canvas: Canvas,
                 productive: _{ frames: ProdFrames },
                 deformation: _{ frames: DefFrames } }
    ;  Dict = _{ kind: "net_vs_unfoldable_arrangement",
                 request: _{ solid: SolidStr },
                 error: "No characteristic unfoldable arrangement is defined for this solid.",
                 productive: _{ frames: [] },
                 deformation: _{ frames: [] } }
    ).
solid_net_compare_json(Spec, _{ kind: SpecStr,
                                error: "Unknown solid-net compare spec.",
                                productive: _{ frames: [] },
                                deformation: _{ frames: [] } }) :-
    term_to_string(Spec, SpecStr).

%!  solid_net_render_to_file(+Spec, +Path) is det.
solid_net_render_to_file(Spec, Path) :-
    solid_net_render_json(Spec, Dict),
    setup_call_cleanup(
        open(Path, write, Stream),
        json_write_dict(Stream, Dict, [width(80)]),
        close(Stream)).


% =============================================================================
% net_of — lay out one face per frame, then mark the fold creases.
% =============================================================================

%!  net_frames(+Solid, +Faces, +Creases, -Frames) is det.
%   One frame per face laid out (creases still empty), then a final frame that
%   adds every fold crease. Every scene carries the faces placed so far; the last
%   frame carries all faces plus the dashed creases where they join.
net_frames(Solid, Faces, Creases, Frames) :-
    buildup_frames(Solid, "net", Faces, "face", net, 1, FaceFrames, AllFaceDicts),
    length(Faces, N),
    LastStep is N + 1,
    crease_dicts(Creases, CreaseDicts),
    scene_dict(Solid, "net", AllFaceDicts, CreaseDicts, Scene),
    solid_string(Solid, SolidStr),
    format(string(Cap),
           "Mark the fold creases (dashed) where the ~w faces of the ~w net join.",
           [N, SolidStr]),
    CreaseFrame = _{ step: LastStep, verb: "mark_creases",
                     caption: Cap, sceneChanged: true, scene: Scene },
    append(FaceFrames, [CreaseFrame], Frames).

%!  bad_frames(+Solid, +Faces, +Creases, -Frames) is det.
%   The deformation filmstrip: the same face count as the true net, laid out one
%   tile per frame with role "deformation", then a final frame whose creases would
%   force an overlap on folding.
bad_frames(Solid, Faces, Creases, Frames) :-
    buildup_frames(Solid, "net", Faces, "deformation", arrangement, 1, FaceFrames, AllFaceDicts),
    length(Faces, N),
    LastStep is N + 1,
    crease_dicts(Creases, CreaseDicts),
    scene_dict(Solid, "net", AllFaceDicts, CreaseDicts, Scene),
    solid_string(Solid, SolidStr),
    format(string(Cap),
           "Trace the folds (dashed): two of the ~w faces land on the same side, so this arrangement never closes to the ~w.",
           [N, SolidStr]),
    CreaseFrame = _{ step: LastStep, verb: "trace_overlap",
                     caption: Cap, sceneChanged: true, scene: Scene },
    append(FaceFrames, [CreaseFrame], Frames).

%!  buildup_frames(+Solid, +Mode, +Faces, +Role, +Kind, +Step0, -Frames, -AllFaceDicts).
%   Accumulate the faces one per frame, each frame carrying every face placed so
%   far (creases still empty). AllFaceDicts is the full accumulated face list, for
%   the caller's final crease frame.
buildup_frames(Solid, Mode, Faces, Role, Kind, Step0, Frames, AllFaceDicts) :-
    buildup_frames_(Faces, Solid, Mode, Role, Kind, Step0, [], Frames, AllFaceDicts).

buildup_frames_([], _Solid, _Mode, _Role, _Kind, _Step, Acc, [], Acc).
buildup_frames_([face(Pts, Label)|Rest], Solid, Mode, Role, Kind, Step, Acc,
                [Frame|Frames], AllFaceDicts) :-
    face_dict(face(Pts, Label), Role, FaceDict),
    append(Acc, [FaceDict], Acc1),
    scene_dict(Solid, Mode, Acc1, [], Scene),
    place_caption(Kind, Label, Solid, Cap),
    place_verb(Kind, Label, Verb),
    Frame = _{ step: Step, verb: Verb, caption: Cap,
               sceneChanged: true, scene: Scene },
    Step1 is Step + 1,
    buildup_frames_(Rest, Solid, Mode, Role, Kind, Step1, Acc1, Frames, AllFaceDicts).

place_caption(net, Label, Solid, Cap) :-
    label_string(Label, LabelStr),
    solid_string(Solid, SolidStr),
    format(string(Cap), "Lay out the ~w face of the ~w net.", [LabelStr, SolidStr]).
place_caption(arrangement, Label, Solid, Cap) :-
    label_string(Label, LabelStr),
    solid_string(Solid, SolidStr),
    format(string(Cap), "Place tile ~w of the six-face arrangement for the ~w.",
           [LabelStr, SolidStr]).

place_verb(net, Label, Verb) :-
    label_string(Label, LabelStr),
    format(string(Verb), "place_face(~w)", [LabelStr]).
place_verb(arrangement, Label, Verb) :-
    label_string(Label, LabelStr),
    format(string(Verb), "place_tile(~w)", [LabelStr]).


% =============================================================================
% unit_cube_stack — an isometric L-by-W-by-H stack of unit cubes.
% =============================================================================

%!  stack_frames(+L, +W, +H, -Frames) is det.
%   Two frames: the L-by-H front layer, then the depth W that closes the box. The
%   caption on the closing frame names the volume L*W*H in unit cubes. No fold
%   creases: an isometric solid is not a net (creases:[]).
stack_frames(L, W, H, [F1, F2]) :-
    stack_faces(L, W, H, FrontFace, TopFace, RightFace),
    face_dict(FrontFace, "face", FrontDict),
    face_dict(TopFace, "face", TopDict),
    face_dict(RightFace, "face", RightDict),
    Volume is L * W * H,
    % Frame 1: the front layer.
    scene_dict(stack, "isometric", [FrontDict], [], Scene1),
    format(string(Cap1), "Draw the ~wx~w front layer of the stack.", [L, H]),
    F1 = _{ step: 1, verb: "draw_front_layer",
            caption: Cap1, sceneChanged: true, scene: Scene1 },
    % Frame 2: add the depth that closes the box.
    scene_dict(stack, "isometric", [FrontDict, TopDict, RightDict], [], Scene2),
    format(string(Cap2),
           "Add the depth ~w: the ~wx~wx~w box holds ~w unit cubes.",
           [W, L, W, H, Volume]),
    F2 = _{ step: 2, verb: "close_box",
            caption: Cap2, sceneChanged: true, scene: Scene2 }.

%!  stack_faces(+L, +W, +H, -Front, -Top, -Right) is det.
%   The three visible faces of an L-by-W-by-H cuboid in a fixed oblique
%   projection: the unit is UNIT px along the width/height axes, and depth steps
%   up and to the right by (DX, DY) per unit. All vertices are integer pixels.
stack_faces(L, W, H, face(Front, front), face(Top, top), face(Right, right)) :-
    Unit = 40, DX = 20, DY = -20,
    OX = 140, OY = 300,
    RX is OX + L * Unit,          % right edge of the front face
    TY is OY - H * Unit,          % top edge of the front face
    BackX is OX + W * DX,         % how far depth shifts x
    BackDY is W * DY,             % how far depth shifts y (negative = up)
    BRX is RX + W * DX, BRY is TY + BackDY,     % top back-right corner
    BLX is BackX,       BLY is TY + BackDY,     % top back-left corner
    DBX is RX + W * DX, DBY is OY + BackDY,      % bottom back-right corner
    Front = [OX-OY, RX-OY, RX-TY, OX-TY],
    Top   = [OX-TY, RX-TY, BRX-BRY, BLX-BLY],
    Right = [RX-OY, DBX-DBY, BRX-BRY, RX-TY].


% =============================================================================
% Scene + primitive dicts.
% =============================================================================

%!  scene_dict(+Solid, +Mode, +FaceDicts, +CreaseDicts, -Scene) is det.
scene_dict(Solid, Mode, FaceDicts, CreaseDicts,
           _{ format: "solid-net", version: 2, mode: Mode,
              solid: SolidStr, faces: FaceDicts, creases: CreaseDicts }) :-
    solid_string(Solid, SolidStr).

%!  face_dict(+face(Points, Label), +Role, -Dict) is det.
%   A face is a polygon of integer pixel vertices carrying a semantic role atom.
face_dict(face(Points, Label), Role, _{ points: PointDicts, role: Role, label: LabelStr }) :-
    points_to_dicts(Points, PointDicts),
    label_string(Label, LabelStr).

points_to_dicts([], []).
points_to_dicts([X-Y|Rest], [_{ x: X, y: Y }|Dicts]) :-
    points_to_dicts(Rest, Dicts).

crease_dicts([], []).
crease_dicts([crease(X1, Y1, X2, Y2)|Rest],
             [_{ x1: X1, y1: Y1, x2: X2, y2: Y2 }|Dicts]) :-
    crease_dicts(Rest, Dicts).


% =============================================================================
% Solid net layouts — every coordinate an integer pixel.
% =============================================================================
% net_layout(+Solid, -Faces, -Creases): the faces (polygons) and fold creases
% (shared internal edges) of a supported solid's planar net. A net of N faces
% folds along N-1 internal edges (a spanning tree of the face adjacencies).

net_layout(Solid, Faces, Creases) :-
    solid_net_shape(Solid, Faces, Creases).

supported_solid(Solid) :- solid_net_shape(Solid, _, _).

% Cube — the Latin-cross net: a column of four squares with one square either
% side of the second (six faces, five fold creases). Unit square 80px.
solid_net_shape(cube,
    [ face([120-40, 200-40, 200-120, 120-120], top),
      face([120-120, 200-120, 200-200, 120-200], front),
      face([120-200, 200-200, 200-280, 120-280], bottom),
      face([120-280, 200-280, 200-360, 120-360], back),
      face([40-120, 120-120, 120-200, 40-200], left),
      face([200-120, 280-120, 280-200, 200-200], right)
    ],
    [ crease(120, 120, 200, 120),   % top / front
      crease(120, 200, 200, 200),   % front / bottom
      crease(120, 280, 200, 280),   % bottom / back
      crease(120, 120, 120, 200),   % left / front
      crease(200, 120, 200, 200)    % front / right
    ]).

% Square pyramid — a square base with a triangle folding up from each side
% (five faces, four fold creases).
solid_net_shape(square_pyramid,
    [ face([160-160, 240-160, 240-240, 160-240], base),
      face([160-160, 240-160, 200-80], face_up),
      face([160-240, 240-240, 200-320], face_down),
      face([160-160, 160-240, 80-200], face_left),
      face([240-160, 240-240, 320-200], face_right)
    ],
    [ crease(160, 160, 240, 160),   % base / up
      crease(160, 240, 240, 240),   % base / down
      crease(160, 160, 160, 240),   % base / left
      crease(240, 160, 240, 240)    % base / right
    ]).

% Triangular prism — three lateral rectangles in a row with a triangular base
% folding up above and below the middle rectangle (five faces, four creases).
solid_net_shape(triangular_prism,
    [ face([80-140, 160-140, 160-240, 80-240], lateral_left),
      face([160-140, 240-140, 240-240, 160-240], lateral_middle),
      face([240-140, 320-140, 320-240, 240-240], lateral_right),
      face([160-140, 240-140, 200-70], base_top),
      face([160-240, 240-240, 200-310], base_bottom)
    ],
    [ crease(160, 140, 160, 240),   % left / middle
      crease(240, 140, 240, 240),   % middle / right
      crease(160, 140, 240, 140),   % middle / top base
      crease(160, 240, 240, 240)    % middle / bottom base
    ]).

% Rectangular prism — a cross of six rectangles (front/back and left/right in a
% row, top and bottom folding off the front). Six faces, five fold creases.
solid_net_shape(rectangular_prism,
    [ face([40-120, 100-120, 100-200, 40-200], left),
      face([100-120, 200-120, 200-200, 100-200], front),
      face([200-120, 260-120, 260-200, 200-200], right),
      face([260-120, 360-120, 360-200, 260-200], back),
      face([100-60, 200-60, 200-120, 100-120], top),
      face([100-200, 200-200, 200-260, 100-260], bottom)
    ],
    [ crease(100, 120, 100, 200),   % left / front
      crease(200, 120, 200, 200),   % front / right
      crease(260, 120, 260, 200),   % right / back
      crease(100, 120, 200, 120),   % front / top
      crease(100, 200, 200, 200)    % front / bottom
    ]).


% =============================================================================
% The break — a right-count arrangement that cannot fold.
% =============================================================================
% bad_arrangement(+Solid, -Name, -Faces, -Creases): the characteristic unfoldable
% arrangement for a solid. It carries the SAME number of faces as the true net,
% but placed so folding forces an overlap. Cube: a 2-by-3 block of six squares —
% it contains a 2-by-2 sub-square, so two faces land on the same side and the
% block never closes to a cube.

bad_arrangement(cube, two_by_three_block, Faces, Creases) :-
    Faces = [
        face([60-80, 140-80, 140-160, 60-160], '(1,1)'),
        face([140-80, 220-80, 220-160, 140-160], '(2,1)'),
        face([220-80, 300-80, 300-160, 220-160], '(3,1)'),
        face([60-160, 140-160, 140-240, 60-240], '(1,2)'),
        face([140-160, 220-160, 220-240, 140-240], '(2,2)'),
        face([220-160, 300-160, 300-240, 220-240], '(3,2)')
    ],
    Creases = [
        crease(140, 80, 140, 160),
        crease(220, 80, 220, 160),
        crease(140, 160, 140, 240),
        crease(220, 160, 220, 240),
        crease(60, 160, 140, 160),
        crease(140, 160, 220, 160),
        crease(220, 160, 300, 160)
    ].

compare_note(SolidStr, BadNameStr, FaceCount, Note) :-
    format(string(Note),
           "The ~w-face arrangement ~w carries the right number of faces for a ~w, \
but it cannot fold to one: it holds a 2-by-2 sub-square, and folding lands two faces \
on the same side. The faces are all present; the arrangement is not foldable. \
(net_faces_do_not_fold_to_solid.)",
           [FaceCount, BadNameStr, SolidStr]).


% =============================================================================
% Helpers.
% =============================================================================

%!  gen_frames(+Spec, -Frames) for the frames-only entry point.
gen_frames(net_of(Solid), Frames) :-
    supported_solid(Solid),
    !,
    net_layout(Solid, Faces, Creases),
    net_frames(Solid, Faces, Creases, Frames).
gen_frames(unit_cube_stack(L, W, H), Frames) :-
    positive_int(L), positive_int(W), positive_int(H),
    !,
    stack_frames(L, W, H, Frames).

%!  deferred_frame(+Spec, -Frame) is det.
%   An undrawable spec is annotation-only: an empty net surface, no throw.
deferred_frame(Spec, Frame) :-
    term_to_string(Spec, SpecStr),
    format(string(Cap), "No solid-net picture for ~w; nothing drawn.", [SpecStr]),
    Scene = _{ format: "solid-net", version: 2, mode: "net",
               solid: "none", faces: [], creases: [] },
    Frame = _{ step: 1, verb: SpecStr, caption: Cap,
               sceneChanged: false, scene: Scene }.

%!  canvas_dict(-Canvas) is det.
canvas_dict(_{ width: 420, height: 420 }).

positive_int(N) :- integer(N), N > 0.

%!  solid_string(+Solid, -String) is det.
solid_string(Solid, String) :-
    ( string(Solid)
    -> String = Solid
    ;  format(string(String), '~w', [Solid])
    ).

%!  label_string(+Label, -String) is det.
label_string(Label, String) :-
    ( string(Label)
    -> String = Label
    ;  format(string(String), '~w', [Label])
    ).

%!  term_to_string(+Term, -String) is det.
term_to_string(Term, String) :-
    ( string(Term)
    -> String = Term
    ;  format(string(String), '~w', [Term])
    ).
