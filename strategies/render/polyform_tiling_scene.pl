/** <module> Polyform-tiling scene compiler (spatial family)
 *
 * Compiles a tiling task into polyform-tiling scene frames on the render
 * contract (docs/render-contract-v2.md,
 * spatial family). The polyform-tiling language fits rigid lattice pieces —
 * unit cells and free polyominoes (the pentominoes vocabulary) — into a bounded
 * lattice region, edge to edge. It denotes composed/decomposed shapes (K.G.6,
 * 1.G.2, 2.G.1) and area by unit tiling (3.MD.5-7).
 *
 * The compiler emits LATTICE cells only: each cell is an integer (col, row)
 * index plus the piece it belongs to. The drawer owns the cell-square geometry
 * (it sizes and places the squares), exactly as the base-ten compiler emits
 * {place,count,base} columns and lets the drawer own the rod/flat/cube shapes.
 * The compiler never emits a pixel.
 *
 * Two productive Spec shapes, one format ("polyform-tiling", version 2):
 *
 *   - tile_region(cols(C), rows(R), Pieces) : Pieces is a list of placed(Id,
 *     Cells), each Cells a list of Col-Row edge-sharing lattice cells. The
 *     filmstrip lands one piece per frame, so the region fills piece by piece.
 *     Denotes tiling(region(C, R), Pieces).
 *   - tile_area(cols(C), rows(R)) : covers the C-by-R rectangle with unit cells,
 *     one row per frame, so area reads off as the cell count. Denotes
 *     area_by_tiling(region(C, R), C*R).
 *
 * This language carries the catalog's sharpest break — the erasure boundary —
 * through TWO deformation lanes, reachable ONLY through the compare form (no
 * productive Spec emits either):
 *
 *   (a) flip_needed_compare(Piece) : a chiral pentomino whose placement needs a
 *       flip, not a rotation. The productive strip seats the piece with the Flip
 *       button; the deformation strip stages the rotation-only attempt, whose
 *       cells fall outside the target footprint (role "deformation"). No rotation
 *       mirrors a chiral piece: violation reason(chirality_requires_flip_not_rotation).
 *
 *   (b) unfillable_by_parity_compare(cols(C), rows(R)) : the ARCHE-TRACE erasure
 *       boundary. The scene STAGES the repeated failure — a bounded region with a
 *       removed corner and a stalled partial domino cover — but the REASON the
 *       region cannot be tiled (a checkerboard-coloring parity count) leaves the
 *       spatial model and hands off to inference. The compiler NAMES the boundary
 *       (erasure: true, a plain note); it does not compute or assert the parity
 *       proof. violation reason(coloring_parity_imbalance).
 *
 * Semantic color ROLES only (the render contract): a placed polyomino cell carries role
 * "piece"; an empty/hole cell is drawn from the "holes" array (neutral); a
 * deformation cell (rotation overhang, the removed corner, the stalled residue)
 * carries role "deformation". This compiler never emits a hex string.
 *
 * Graceful degradation: a Spec with no drawable cells (an empty region, a piece
 * list with no in-region cells) yields an explicit error document with frames:[]
 * rather than a faked picture (contract, spatial family).
 */

:- module(polyform_tiling_scene,
          [ polyform_tiling_render_frames/2,   % +Spec, -Frames
            polyform_tiling_render_json/2,      % +Spec, -Dict
            polyform_tiling_compare_json/2,     % +Spec, -Dict (deformation lanes)
            polyform_tiling_render_to_file/2    % +Spec, +Path
          ]).

:- use_module(render(render_common),
              [render_frames/4, term_to_string/2, write_render_json/2]).
:- use_module(library(lists)).

% =============================================================================
% Public API
% =============================================================================

%!  polyform_tiling_render_frames(+Spec, -Frames) is det.
%
%   Walk Spec into a list of frame dicts. A Spec that cannot be tiled yields a
%   single annotation-only frame (sceneChanged:false), so nothing throws.
polyform_tiling_render_frames(Spec, Frames) :-
    render_frames(Spec, gen_frames, deferred_frame, Frames).

%!  polyform_tiling_render_json(+Spec, -Dict) is det.
%
%   The full render document: kind / request / result / canvas / frames
%   (the render contract). On an untileable Spec, an explicit error string and frames:[].
polyform_tiling_render_json(tile_region(cols(C), rows(R), Pieces), Dict) :-
    !,
    ( integer(C), integer(R), C >= 1, R >= 1,
      clean_pieces(Pieces, C, R, Clean), Clean \== []
    -> tile_region_frames(C, R, Clean, Frames),
       covered_cells(Clean, Covered), length(Covered, NCov),
       Total is C * R,
       length(Clean, NPieces),
       format(string(ResultStr),
              "~w piece(s) placed; ~w of ~w cells covered on a ~wx~w region",
              [NPieces, NCov, Total, C, R]),
       canvas_dict(Canvas),
       region_request(C, R, Clean, Request),
       Dict = _{ kind: "tile_region",
                 request: Request,
                 result: ResultStr,
                 canvas: Canvas,
                 frames: Frames }
    ;  Dict = _{ kind: "tile_region",
                 request: _{ cols: C, rows: R },
                 error: "No in-region lattice pieces to place for this polyform-tiling task.",
                 frames: [] }
    ).
polyform_tiling_render_json(tile_area(cols(C), rows(R)), Dict) :-
    !,
    ( integer(C), integer(R), C >= 1, R >= 1
    -> tile_area_frames(C, R, Frames),
       Area is C * R,
       format(string(ResultStr), "area_by_tiling: ~wx~w = ~w unit cells", [C, R, Area]),
       canvas_dict(Canvas),
       Dict = _{ kind: "tile_area",
                 request: _{ cols: C, rows: R, area: Area },
                 result: ResultStr,
                 canvas: Canvas,
                 frames: Frames }
    ;  Dict = _{ kind: "tile_area",
                 request: _{ cols: C, rows: R },
                 error: "A polyform-tiling area needs positive integer cols and rows.",
                 frames: [] }
    ).
polyform_tiling_render_json(Spec, Dict) :-
    polyform_tiling_render_frames(Spec, Frames),
    term_to_string(Spec, SpecStr),
    canvas_dict(Canvas),
    Dict = _{ kind: SpecStr,
              request: _{ spec: SpecStr },
              result: "unknown",
              canvas: Canvas,
              frames: Frames }.

%!  polyform_tiling_compare_json(+Spec, -Dict) is det.
%
%   The deformation compare documents for the two break lanes. Each returns a
%   productive filmstrip beside a deformation filmstrip, plus the named violation
%   and provenance. Both lanes are reachable ONLY here; no productive Spec emits
%   a flip overhang or a parity stall.
%
%   flip_needed_compare(Piece): the chiral-piece flip-vs-rotation break.
polyform_tiling_compare_json(flip_needed_compare(Piece), Dict) :-
    !,
    ( chiral_pentomino_cells(Piece, Cells)
    -> reflect_cells(Cells, Mirror),
       rotate180_cells(Cells, Rot),
       lattice_of([Mirror, Rot], Cols, Rows),
       flip_productive_frames(Piece, Mirror, Cols, Rows, ProdFrames),
       flip_deformation_frames(Piece, Mirror, Rot, Cols, Rows, DefFrames,
                               NMatched, NOverhang),
       flip_note(Piece, Note),
       term_to_string(Piece, PieceStr),
       canvas_dict(Canvas),
       Dict = _{ kind: "place_chiral_piece_flip_vs_rotation",
                 request: _{ piece: PieceStr },
                 productiveKind: "flip_places_mirror",
                 deformationKind: "rotation_only_attempt",
                 family: "flip_needed",
                 piece: PieceStr,
                 required_motion: flip,
                 attempted_motion: rotation,
                 cells_landed: NMatched,
                 cells_overhang: NOverhang,
                 violation: reason(chirality_requires_flip_not_rotation),
                 provenance: literature_only,
                 note: Note,
                 canvas: Canvas,
                 productive: _{ frames: ProdFrames },
                 deformation: _{ frames: DefFrames } }
    ;  Dict = _{ kind: "place_chiral_piece_flip_vs_rotation",
                 request: _{ piece: PieceAtom },
                 error: "This piece is not one of the six chiral pentominoes; no flip-vs-rotation break arises.",
                 productive: _{ frames: [] },
                 deformation: _{ frames: [] } },
       term_to_string(Piece, PieceAtom)
    ).
%   unfillable_by_parity_compare(cols(C), rows(R)): the arche-trace erasure
%   boundary. The tiles stage the stall; the parity reason hands off to inference.
polyform_tiling_compare_json(unfillable_by_parity_compare(cols(C), rows(R)), Dict) :-
    !,
    ( integer(C), integer(R), C >= 2, R >= 2
    -> Reserved = (C-R),
       parity_dominoes(C, R, Reserved, Dominoes),
       parity_productive_frames(C, R, ProdFrames),
       parity_deformation_frames(C, R, Reserved, Dominoes, DefFrames, NResidue),
       parity_note(Note),
       canvas_dict(Canvas),
       Dict = _{ kind: "tile_region_with_dominoes_vs_parity_obstruction",
                 request: _{ cols: C, rows: R },
                 productiveKind: "unit_area_tiling",
                 deformationKind: "stalled_domino_cover",
                 family: "unfillable_by_parity",
                 removed_corner: _{ col: C, row: R },
                 residue_cells: NResidue,
                 violation: reason(coloring_parity_imbalance),
                 erasure: true,
                 handoff: coloring_parity_argument,
                 provenance: literature_only,
                 note: Note,
                 canvas: Canvas,
                 productive: _{ frames: ProdFrames },
                 deformation: _{ frames: DefFrames } }
    ;  Dict = _{ kind: "tile_region_with_dominoes_vs_parity_obstruction",
                 request: _{ cols: C, rows: R },
                 error: "The parity-obstruction staging needs a region at least 2 by 2.",
                 productive: _{ frames: [] },
                 deformation: _{ frames: [] } }
    ).
polyform_tiling_compare_json(Spec, _{ kind: SpecStr,
                                      error: "Unknown polyform-tiling compare spec.",
                                      productive: _{ frames: [] },
                                      deformation: _{ frames: [] } }) :-
    term_to_string(Spec, SpecStr).

%!  polyform_tiling_render_to_file(+Spec, +Path) is det.
polyform_tiling_render_to_file(Spec, Path) :-
    polyform_tiling_render_json(Spec, Dict),
    write_render_json(Path, Dict).


% =============================================================================
% tile_region — one polyomino per frame.
% =============================================================================

%!  tile_region_frames(+C, +R, +Pieces, -Frames) is det.
%   One frame per piece, accumulating the pieces placed so far so the filmstrip
%   fills the region piece by piece. Every scene carries the full lattice, the
%   cells of every piece up to the current step (role "piece"), and the cells not
%   yet covered as holes (neutral).
tile_region_frames(C, R, Pieces, Frames) :-
    region_cells(C, R, All),
    tr_frames(Pieces, C, R, All, 1, [], Frames).

tr_frames([], _C, _R, _All, _Step, _Acc, []).
tr_frames([placed(Id, Cells)|Rest], C, R, All, Step, Acc, [Frame|Frames]) :-
    append(Acc, [placed(Id, Cells)], Acc1),
    placed_cell_dicts(Acc1, CellDicts),
    covered_cells(Acc1, Covered),
    subtract_cells(All, Covered, HoleCells),
    hole_dicts(HoleCells, Holes),
    region_label(C, R, Label),
    scene_dict(C, R, CellDicts, Holes, Label, Scene),
    length(Cells, NCells),
    length(Covered, NCov),
    Total is C * R,
    format(string(Caption),
           "Place piece ~w (~w cell(s)) edge to edge; ~w of ~w cells covered.",
           [Id, NCells, NCov, Total]),
    format(string(Verb), "place(~w)", [Id]),
    Frame = _{ step: Step, verb: Verb, caption: Caption,
               sceneChanged: true, scene: Scene },
    Step1 is Step + 1,
    tr_frames(Rest, C, R, All, Step1, Acc1, Frames).


% =============================================================================
% tile_area — one row of unit cells per frame (area by unit tiling).
% =============================================================================

%!  tile_area_frames(+C, +R, -Frames) is det.
%   One frame per row: each frame lands a full row of unit cells, so the count of
%   filled cells is the area. The remaining rows are holes until they fill.
tile_area_frames(C, R, Frames) :-
    region_cells(C, R, All),
    ta_frames(1, C, R, All, [], Frames).

ta_frames(Row, _C, R, _All, _Acc, []) :-
    Row > R,
    !.
ta_frames(Row, C, R, All, Acc, [Frame|Frames]) :-
    findall(Col-Row, between(1, C, Col), RowCells),
    append(Acc, RowCells, Acc1),
    unit_cell_dicts(Acc1, CellDicts),
    subtract_cells(All, Acc1, HoleCells),
    hole_dicts(HoleCells, Holes),
    region_label(C, R, Label),
    scene_dict(C, R, CellDicts, Holes, Label, Scene),
    length(Acc1, Filled),
    Total is C * R,
    format(string(Caption),
           "Tile row ~w with ~w unit cell(s); ~w of ~w cells covered.",
           [Row, C, Filled, Total]),
    format(string(Verb), "tile_row(~w)", [Row]),
    Frame = _{ step: Row, verb: Verb, caption: Caption,
               sceneChanged: true, scene: Scene },
    Row1 is Row + 1,
    ta_frames(Row1, C, R, All, Acc1, Frames).


% =============================================================================
% Break lane (a): flip_needed — a chiral piece needs the Flip button.
% =============================================================================
%
% The productive strip seats the piece in its mirror orientation (what the Flip
% button reaches). The deformation strip stages the rotation-only attempt: the
% 180-degree rotation lands some cells on the target footprint but pushes the
% rest outside it (role "deformation"), because no rotation of a chiral piece
% equals its mirror. Prolog computes every reflected and rotated cell; the drawer
% only inks them.

flip_productive_frames(Piece, Mirror, Cols, Rows, [F]) :-
    cell_dicts_role(Mirror, "piece", "flip", CellDicts),
    region_label(Cols, Rows, Label),
    scene_dict(Cols, Rows, CellDicts, [], Label, Scene),
    format(string(Caption),
           "With the Flip button, piece ~w seats in its mirror orientation, filling the footprint.",
           [Piece]),
    F = _{ step: 1, verb: "flip_place", caption: Caption,
           sceneChanged: true, scene: Scene }.

flip_deformation_frames(Piece, Mirror, Rot, Cols, Rows, [F1, F2],
                        NMatched, NOverhang) :-
    intersection_cells(Rot, Mirror, Matched),
    subtract_cells(Rot, Mirror, Overhang),
    subtract_cells(Mirror, Rot, Uncovered),
    length(Matched, NMatched),
    length(Overhang, NOverhang),
    region_label(Cols, Rows, Label),
    % Frame 1: the target footprint the piece must reach (neutral holes).
    hole_dicts(Mirror, MirrorHoles),
    scene_dict(Cols, Rows, [], MirrorHoles, Label, Scene1),
    format(string(Cap1),
           "The footprint piece ~w must fill — the mirror of the piece.",
           [Piece]),
    F1 = _{ step: 1, verb: "show_target", caption: Cap1,
            sceneChanged: true, scene: Scene1 },
    % Frame 2: the rotation-only attempt. Matched cells land (role piece); the
    % overhang cells fall outside the footprint (role deformation).
    cell_dicts_role(Matched, "piece", "rotate", MatchedDicts),
    cell_dicts_role(Overhang, "deformation", "rotate", OverhangDicts),
    append(MatchedDicts, OverhangDicts, Cells2),
    hole_dicts(Uncovered, UncoveredHoles),
    scene_dict(Cols, Rows, Cells2, UncoveredHoles, Label, Scene2),
    format(string(Cap2),
           "A rotation lands ~w cell(s) but pushes ~w cell(s) outside the footprint: no rotation mirrors a chiral piece. Only the Flip button reaches it.",
           [NMatched, NOverhang]),
    F2 = _{ step: 2, verb: "rotate_attempt", caption: Cap2,
            sceneChanged: true, scene: Scene2 }.

flip_note(Piece, Note) :-
    format(string(Note),
           "Piece ~w is chiral: its mirror image is a distinct orientation. The rotation gesture cycles a piece through its four turns, none of which equals the mirror; only the Flip button crosses to the reflected orientation. The tiles stage the mismatch precisely (the overhang cells), and the reason is a fact about the piece, not the drawer. (Flip-needed family.)",
           [Piece]).


% =============================================================================
% Break lane (b): unfillable_by_parity — the arche-trace erasure boundary.
% =============================================================================
%
% The deformation strip STAGES the repeated failure: a bounded region with one
% corner removed and a stalled partial domino cover, leaving a residue no domino
% completes. It does NOT prove impossibility — the REASON the region cannot be
% tiled is a checkerboard-coloring parity count, an inference that leaves the
% spatial model. The productive strip tiles the full rectangle with unit cells to
% show its area exists; the contrast is the point. The note names the boundary.

%!  parity_dominoes(+C, +R, +Reserved, -Dominoes) is det.
%   A deterministic partial cover: horizontal dominoes paired left to right in
%   each row, skipping any pair that would touch the removed corner.
parity_dominoes(C, R, Reserved, Dominoes) :-
    findall([Col-Row, Col1-Row],
            ( between(1, R, Row),
              between(1, C, Col),
              1 =:= Col mod 2,
              Col1 is Col + 1,
              Col1 =< C,
              Reserved \== (Col-Row),
              Reserved \== (Col1-Row)
            ),
            Dominoes).

parity_productive_frames(C, R, Frames) :-
    tile_area_frames(C, R, Frames).

parity_deformation_frames(C, R, Reserved, Dominoes, [F1, F2, F3], NResidue) :-
    region_cells(C, R, All),
    Reserved = (RCol-RRow),
    region_label(C, R, Label),
    % Frame 1: the mutilated board — one corner removed (role deformation).
    subtract_cells(All, [Reserved], OpenCells),
    hole_dicts(OpenCells, OpenHoles),
    cell_dicts_role([Reserved], "deformation", "removed", ReservedDicts),
    scene_dict(C, R, ReservedDicts, OpenHoles, Label, Scene1),
    format(string(Cap1),
           "Remove one corner of the ~wx~w board (cell ~w,~w). Try to cover the rest with dominoes.",
           [C, R, RCol, RRow]),
    F1 = _{ step: 1, verb: "remove_corner", caption: Cap1,
            sceneChanged: true, scene: Scene1 },
    % Frame 2: the partial domino cover (role piece); leftover cells are holes.
    domino_cells(Dominoes, DominoCells),
    domino_cell_dicts(Dominoes, DominoDicts),
    subtract_cells(All, [Reserved|DominoCells], Leftover),
    hole_dicts(Leftover, LeftoverHoles),
    append(DominoDicts, ReservedDicts, Cells2),
    scene_dict(C, R, Cells2, LeftoverHoles, Label, Scene2),
    length(Dominoes, NDom),
    format(string(Cap2),
           "Place ~w domino(s) edge to edge; cells remain uncovered around the removed corner.",
           [NDom]),
    F2 = _{ step: 2, verb: "cover_partial", caption: Cap2,
            sceneChanged: true, scene: Scene2 },
    % Frame 3: the stall. The residue is marked (role deformation); the reason it
    % cannot close is a parity argument that leaves the tiles (arche-trace).
    length(Leftover, NResidue),
    cell_dicts_role(Leftover, "deformation", "residue", ResidueDicts),
    append([DominoDicts, ReservedDicts, ResidueDicts], Cells3),
    scene_dict(C, R, Cells3, [], Label, Scene3),
    format(string(Cap3),
           "The cover stalls: ~w cell(s) remain that no domino completes. Whether the board tiles at all is settled by a checkerboard-coloring parity count, not by pushing tiles. The tiles stage the impossibility; the reason hands off to human judgment.",
           [NResidue]),
    F3 = _{ step: 3, verb: "stall", caption: Cap3,
            sceneChanged: true, scene: Scene3 }.

parity_note(Note) :-
    Note = "The tiles stage the repeated failure — a partial cover that cannot close around the removed corner — but they cannot deliver its reason. Whether the region admits any tiling is settled by a two-coloring that leaves the two colors' counts unequal, an argument that departs the spatial model and hands off to inference. This is the arche-trace boundary: the picture names the impossibility; human judgment carries the proof.".


% =============================================================================
% Scene assembly + cell dicts.
% =============================================================================

%!  scene_dict(+C, +R, +CellDicts, +Holes, +Label, -Scene) is det.
scene_dict(C, R, CellDicts, Holes, Label,
           _{ format: "polyform-tiling",
              version: 2,
              lattice: _{ cols: C, rows: R },
              cells: CellDicts,
              holes: Holes,
              regionLabel: Label }).

%!  placed_cell_dicts(+Pieces, -Dicts) is det.
%   Every cell of every placed piece as a "piece"-role cell dict, tagged with its
%   piece id.
placed_cell_dicts(Pieces, Dicts) :-
    findall(Dict,
            ( member(placed(Id, Cells), Pieces),
              term_to_string(Id, IdStr),
              member(Col-Row, Cells),
              Dict = _{ col: Col, row: Row, piece: IdStr, role: "piece" }
            ),
            Dicts).

%!  unit_cell_dicts(+Cells, -Dicts) is det.
%   Unit-tiling cells: every cell is its own unit_cell, piece id "unit".
unit_cell_dicts(Cells, Dicts) :-
    findall(_{ col: Col, row: Row, piece: "unit", role: "piece" },
            member(Col-Row, Cells),
            Dicts).

%!  cell_dicts_role(+Cells, +Role, +PieceId, -Dicts) is det.
cell_dicts_role(Cells, Role, PieceId, Dicts) :-
    findall(_{ col: Col, row: Row, piece: PieceId, role: Role },
            member(Col-Row, Cells),
            Dicts).

%!  hole_dicts(+Cells, -Dicts) is det.
%   Empty/hole cells carry col/row only (the drawer inks them neutral).
hole_dicts(Cells, Dicts) :-
    findall(_{ col: Col, row: Row }, member(Col-Row, Cells), Dicts).

%!  domino_cells(+Dominoes, -Cells) is det.
domino_cells(Dominoes, Cells) :-
    findall(Cell, ( member(D, Dominoes), member(Cell, D) ), Cells).

%!  domino_cell_dicts(+Dominoes, -Dicts) is det.
%   Each domino is a placed piece; its two cells carry role "piece".
domino_cell_dicts(Dominoes, Dicts) :-
    findall(_{ col: Col, row: Row, piece: PieceStr, role: "piece" },
            ( nth1(N, Dominoes, D),
              format(string(PieceStr), "d~w", [N]),
              member(Col-Row, D)
            ),
            Dicts).


% =============================================================================
% Lattice geometry — regions, cells, and rigid transforms.
% =============================================================================

%!  region_cells(+C, +R, -Cells) is det.
%   Every lattice cell of the C-by-R region, row major, as Col-Row pairs.
region_cells(C, R, Cells) :-
    findall(Col-Row, ( between(1, R, Row), between(1, C, Col) ), Cells).

%!  clean_pieces(+Raw, +C, +R, -Clean) is det.
%   Keep only well-formed placed(Id, Cells) whose cells are integer in-region
%   Col-Row lattice cells. A malformed piece is dropped rather than faked.
clean_pieces(Raw, C, R, Clean) :-
    is_list(Raw),
    findall(placed(Id, Cells1),
            ( member(P, Raw), valid_piece(P, C, R, Id, Cells1) ),
            Clean).

valid_piece(placed(Id, Cells), C, R, Id, Cells1) :-
    is_list(Cells),
    Cells \== [],
    findall(Col-Row,
            ( member(Cell, Cells), cell_in_region(Cell, C, R, Col, Row) ),
            Cells1),
    Cells1 \== [].

cell_in_region(Col-Row, C, R, Col, Row) :-
    integer(Col), integer(Row), Col >= 1, Col =< C, Row >= 1, Row =< R.
cell_in_region([Col, Row], C, R, Col, Row) :-
    integer(Col), integer(Row), Col >= 1, Col =< C, Row >= 1, Row =< R.

%!  covered_cells(+Pieces, -Covered) is det.
%   The sorted set of every cell covered by any placed piece.
covered_cells(Pieces, Covered) :-
    findall(Cell, ( member(placed(_, Cells), Pieces), member(Cell, Cells) ), All),
    sort(All, Covered).

%!  subtract_cells(+A, +B, -Diff) is det.
%   Set difference over cell lists, order preserved by A's order.
subtract_cells(A, B, Diff) :-
    findall(Cell, ( member(Cell, A), \+ memberchk(Cell, B) ), Diff).

%!  intersection_cells(+A, +B, -Both) is det.
intersection_cells(A, B, Both) :-
    findall(Cell, ( member(Cell, A), memberchk(Cell, B) ), Both).

%!  normalize_cells(+Cells, -Norm) is det.
%   Shift a cell set so its lowest col and row are 1, then sort into a set.
normalize_cells(Cells, Norm) :-
    cells_min(Cells, MinCol, MinRow),
    DX is 1 - MinCol,
    DY is 1 - MinRow,
    findall(NC-NR,
            ( member(Col-Row, Cells), NC is Col + DX, NR is Row + DY ),
            Shifted),
    sort(Shifted, Norm).

cells_min(Cells, MinCol, MinRow) :-
    findall(Col, member(Col-_, Cells), Cols),
    findall(Row, member(_-Row, Cells), Rows),
    min_list(Cols, MinCol),
    min_list(Rows, MinRow).

cells_max(Cells, MaxCol, MaxRow) :-
    findall(Col, member(Col-_, Cells), Cols),
    findall(Row, member(_-Row, Cells), Rows),
    max_list(Cols, MaxCol),
    max_list(Rows, MaxRow).

%!  reflect_cells(+Cells, -Mirror) is det.
%   Reflect across the vertical axis (the Flip button), then normalize.
reflect_cells(Cells, Mirror) :-
    cells_max(Cells, MaxCol, _),
    findall(NC-Row,
            ( member(Col-Row, Cells), NC is MaxCol + 1 - Col ),
            Reflected),
    normalize_cells(Reflected, Mirror).

%!  rotate180_cells(+Cells, -Rot) is det.
%   Rotate 180 degrees (two rotation-gesture turns), then normalize.
rotate180_cells(Cells, Rot) :-
    cells_max(Cells, MaxCol, MaxRow),
    findall(NC-NR,
            ( member(Col-Row, Cells),
              NC is MaxCol + 1 - Col,
              NR is MaxRow + 1 - Row ),
            Rotated),
    normalize_cells(Rotated, Rot).

%!  lattice_of(+CellLists, -Cols, -Rows) is det.
%   The bounding lattice (max col, max row) over the union of the cell sets. The
%   sets are normalized to min (1, 1), so the max is the extent.
lattice_of(CellLists, Cols, Rows) :-
    append(CellLists, Union),
    cells_max(Union, Cols, Rows).


% =============================================================================
% The six chiral pentominoes (normalized cell sets, min col/row = 1).
% =============================================================================
% Only the six pentominoes whose mirror image is a distinct orientation. The
% other six (I, T, U, V, W, X) are achiral and have no flip-vs-rotation break, so
% they are absent here — the misconception lane cannot reach them.

chiral_pentomino_cells(l, [1-1, 1-2, 1-3, 1-4, 2-4]).
chiral_pentomino_cells(f, [2-1, 3-1, 1-2, 2-2, 2-3]).
chiral_pentomino_cells(n, [2-1, 2-2, 1-3, 2-3, 1-4]).
chiral_pentomino_cells(p, [1-1, 2-1, 1-2, 2-2, 1-3]).
chiral_pentomino_cells(y, [2-1, 1-2, 2-2, 2-3, 2-4]).
chiral_pentomino_cells(z, [1-1, 2-1, 2-2, 2-3, 3-3]).


% =============================================================================
% Helpers.
% =============================================================================

%!  region_request(+C, +R, +Pieces, -Request) is det.
region_request(C, R, Pieces, _{ cols: C, rows: R, pieces: Str, pieceCount: N }) :-
    length(Pieces, N),
    term_to_string(Pieces, Str).

%!  region_label(+C, +R, -Label) is det.
region_label(C, R, Label) :-
    format(string(Label), "~wx~w region", [C, R]).

%!  gen_frames(+Spec, -Frames) for the frames-only entry point.
gen_frames(tile_region(cols(C), rows(R), Pieces), Frames) :-
    integer(C), integer(R), C >= 1, R >= 1,
    clean_pieces(Pieces, C, R, Clean), Clean \== [],
    !,
    tile_region_frames(C, R, Clean, Frames).
gen_frames(tile_area(cols(C), rows(R)), Frames) :-
    integer(C), integer(R), C >= 1, R >= 1,
    !,
    tile_area_frames(C, R, Frames).

%!  deferred_frame(+Spec, -Frame) is det.
%   An untileable spec is annotation-only: an empty lattice, no throw.
deferred_frame(Spec, Frame) :-
    term_to_string(Spec, SpecStr),
    format(string(Cap), "No polyform-tiling render for ~w; nothing drawn.", [SpecStr]),
    Scene = _{ format: "polyform-tiling", version: 2,
               lattice: _{ cols: 1, rows: 1 },
               cells: [], holes: [], regionLabel: "empty" },
    Frame = _{ step: 1, verb: SpecStr, caption: Cap,
               sceneChanged: false, scene: Scene }.

%!  canvas_dict(-Canvas) is det.
canvas_dict(_{ width: 560, height: 560 }).
