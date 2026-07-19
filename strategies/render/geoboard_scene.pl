/** <module> Geoboard scene compiler (spatial family)
 *
 * Compiles a rubber-band-on-a-pegboard task into geoboard scene frames on the
 * render contract (docs/render-contract-v2.md). The spatial family extends the
 * catalog past the arithmetic/number region into the K-8 spatial representations
 * tallied in
 * docs/research/2026-07-08-hermes-spatial-representation-gap-tally.md.
 *
 * A geoboard denotes a simple closed polygon on the integer lattice. Its geometry
 * is a fact about the polygon, not the running history of an automaton: classify
 * every lattice peg in the bounding box as boundary (on an edge or vertex),
 * interior (strictly inside), or outside; read the enclosed area off the lattice
 * by the shoelace formula, which Pick's theorem re-derives as A = I + B/2 - 1.
 * Every coordinate the scene carries is a MATH lattice coordinate; the drawer maps
 * math -> pixels within its own band, exactly as it scales the coordinate plane.
 * The compiler never emits a pixel.
 *
 * One productive Spec, one format ("geoboard", version 2):
 *
 *   - stretch_polygon(Vertices) : Vertices is a list of X-Y integer pegs forming a
 *     simple closed polygon. The filmstrip places the vertices, closes the band,
 *     then classifies the pegs and reads Pick's area. Denotes geoboard_polygon(Vertices).
 *
 * The characteristic break (the grammar's deformation lane) is the boundary-peg
 * miscount: a peg on the band's edge counted as INTERIOR rather than BOUNDARY.
 * Pick's theorem weights an interior peg twice a boundary peg, so moving one unit
 * from B to I inflates the reported area by exactly 1/2. It is reachable ONLY
 * through geoboard_pick_compare/1 and only via the misconception lane; there is no
 * productive Spec that miscounts a peg.
 *
 * Semantic color ROLES only (the render contract): a lattice peg carries role "peg", the
 * miscounted peg carries role "deformation", the enclosed region fills with the
 * shared role "whole", and the band is drawn in the figure stroke color. This
 * compiler never emits a hex string.
 *
 * Graceful degradation: a Spec with fewer than three integer lattice vertices
 * yields an explicit error document with frames:[] rather than a faked picture
 * (the render contract); an unknown Spec yields a single annotation-only frame.
 */

:- module(geoboard_scene,
          [ geoboard_render_frames/2,   % +Spec, -Frames
            geoboard_render_json/2,      % +Spec, -Dict
            geoboard_compare_json/2,     % +Spec, -Dict (boundary-peg miscount)
            geoboard_render_to_file/2    % +Spec, +Path
          ]).

:- use_module(render(render_common),
              [render_frames/4, term_to_string/2, write_render_json/2]).
:- use_module(library(lists)).

% =============================================================================
% Public API
% =============================================================================

%!  geoboard_render_frames(+Spec, -Frames) is det.
%
%   Walk Spec into a list of frame dicts. A Spec that cannot be drawn yields a
%   single annotation-only frame (sceneChanged:false), so nothing throws.
geoboard_render_frames(Spec, Frames) :-
    render_frames(Spec, geoboard_gen_frames, geoboard_deferred_frame, Frames).

%!  geoboard_render_json(+Spec, -Dict) is det.
%
%   The full render document: kind / request / result / canvas / frames
%   (the render contract). On an unbuildable Spec, an explicit error string and frames:[].
geoboard_render_json(stretch_polygon(Vertices), Dict) :-
    !,
    ( geoboard_simple_closed(Vertices)
    -> geoboard_lattice(Vertices, Lattice),
       geoboard_shoelace2(Vertices, Area2),
       geoboard_area_value(Area2, Area),
       geoboard_classify_pegs(Vertices, Lattice, ClassPegs),
       geoboard_pick_counts(ClassPegs, I, B),
       geoboard_polygon_frames(Vertices, Lattice, Area, I, B, Frames),
       geoboard_vertex_list_string(Vertices, VStr),
       length(Vertices, NV),
       format(string(ResultStr),
              "geoboard polygon ~w: area ~w, ~w interior + ~w boundary pegs",
              [VStr, Area, I, B]),
       canvas_dict(Canvas),
       Dict = _{ kind: "stretch_polygon",
                 request: _{ vertices: VStr, vertex_count: NV },
                 result: ResultStr,
                 canvas: Canvas,
                 frames: Frames }
    ;  Dict = _{ kind: "stretch_polygon",
                 request: _{ vertices: "[]" },
                 error: "A geoboard polygon needs a simple closed lattice polygon with at least three distinct integer vertices.",
                 frames: [] }
    ).
geoboard_render_json(Spec, Dict) :-
    geoboard_render_frames(Spec, Frames),
    term_to_string(Spec, SpecStr),
    canvas_dict(Canvas),
    Dict = _{ kind: SpecStr,
              request: _{ spec: SpecStr },
              result: "unknown",
              canvas: Canvas,
              frames: Frames }.

%!  geoboard_compare_json(+Spec, -Dict) is det.
%
%   The boundary-peg-miscount compare document: a productive filmstrip that reads
%   Pick's area with the pegs counted correctly, beside a deformation filmstrip
%   that recounts one boundary peg as interior and reports the inflated area, so
%   the miscount is drawn against its grounded partner. Spec is
%   geoboard_pick_compare(Vertices). On a spec with no simple closed polygon, an
%   explicit error and empty filmstrips.
geoboard_compare_json(geoboard_pick_compare(Vertices), Dict) :-
    !,
    ( geoboard_simple_closed(Vertices)
    -> geoboard_lattice(Vertices, Lattice),
       geoboard_shoelace2(Vertices, Area2),
       geoboard_area_value(Area2, Area),
       geoboard_classify_pegs(Vertices, Lattice, ClassPegs),
       geoboard_pick_counts(ClassPegs, I, B),
       geoboard_pick_boundary_peg(ClassPegs, Vertices, MPX-MPY),
       geoboard_reflag_peg(ClassPegs, MPX-MPY, DefPegs),
       WrongArea2 is Area2 + 1,
       geoboard_area_value(WrongArea2, WrongArea),
       I1 is I + 1,
       B1 is B - 1,
       geoboard_polygon_points(Vertices, Poly),
       geoboard_prod_frames(ClassPegs, Poly, Lattice, Area, I, B, ProdFrames),
       geoboard_def_frames(ClassPegs, DefPegs, Poly, Lattice,
                           MPX, MPY, Area, WrongArea, I, B, I1, B1, DefFrames),
       geoboard_vertex_list_string(Vertices, VStr),
       geoboard_compare_note(MPX, MPY, Area, WrongArea, Note),
       canvas_dict(Canvas),
       Dict = _{ kind: "geoboard_pick_vs_boundary_miscount",
                 request: _{ vertices: VStr },
                 productiveKind: "geoboard_pick_area",
                 deformationKind: "boundary_peg_as_interior",
                 family: "boundary_peg_as_interior",
                 correct_area: Area,
                 correct_pick: _{ interior: I, boundary: B },
                 deformed_area: WrongArea,
                 deformed_pick: _{ interior: I1, boundary: B1 },
                 miscounted_peg: _{ x: MPX, y: MPY },
                 note: Note,
                 canvas: Canvas,
                 productive: _{ frames: ProdFrames },
                 deformation: _{ frames: DefFrames } }
    ;  Dict = _{ kind: "geoboard_pick_vs_boundary_miscount",
                 request: _{ vertices: "[]" },
                 error: "A geoboard Pick comparison needs a simple closed lattice polygon (three or more distinct integer vertices).",
                 productive: _{ frames: [] },
                 deformation: _{ frames: [] } }
    ).
geoboard_compare_json(Spec, _{ kind: SpecStr,
                               error: "Unknown geoboard compare spec.",
                               productive: _{ frames: [] },
                               deformation: _{ frames: [] } }) :-
    term_to_string(Spec, SpecStr).

%!  geoboard_render_to_file(+Spec, +Path) is det.
geoboard_render_to_file(Spec, Path) :-
    geoboard_render_json(Spec, Dict),
    write_render_json(Path, Dict).


% =============================================================================
% stretch_polygon — place the vertices, close the band, count the pegs.
% =============================================================================

%!  geoboard_polygon_frames(+Vertices, +Lattice, +Area, +I, +B, -Frames) is det.
%   Three frames: the bare lattice with the band open, the closed rubber band
%   bounding a region, then the pegs classified so Pick's area reads off the
%   lattice.
geoboard_polygon_frames(Vertices, Lattice, Area, I, B, [F1, F2, F3]) :-
    geoboard_lattice_pegs(Lattice, LatticePegs),
    geoboard_classify_pegs(Vertices, Lattice, ClassPegs),
    geoboard_polygon_points(Vertices, Poly),
    geoboard_vertex_list_string(Vertices, VStr),
    Pick = _{ interior: I, boundary: B },
    % Frame 1: the peg lattice, band not yet closed.
    Scene1 = _{ format: "geoboard", version: 2, lattice: Lattice,
                pegs: LatticePegs, polygon: [], area: Area, pick: Pick },
    format(string(Cap1),
           "Set the pegs out; stretch the band to the vertices ~w.", [VStr]),
    F1 = _{ step: 1, verb: "place_vertices", caption: Cap1,
            sceneChanged: true, scene: Scene1 },
    % Frame 2: close the rubber band; a region is bounded.
    Scene2 = _{ format: "geoboard", version: 2, lattice: Lattice,
                pegs: LatticePegs, polygon: Poly, area: Area, pick: Pick },
    F2 = _{ step: 2, verb: "close_band",
            caption: "Close the rubber band: it bounds a region on the peg lattice.",
            sceneChanged: true, scene: Scene2 },
    % Frame 3: classify the pegs and read Pick's area.
    Scene3 = _{ format: "geoboard", version: 2, lattice: Lattice,
                pegs: ClassPegs, polygon: Poly, area: Area, pick: Pick },
    geoboard_pick_caption(I, B, Area, Cap3),
    F3 = _{ step: 3, verb: "count_pegs", caption: Cap3,
            sceneChanged: true, scene: Scene3 }.

%!  geoboard_pick_caption(+I, +B, +Area, -Caption) is det.
geoboard_pick_caption(I, B, Area, Cap) :-
    format(string(Cap),
           "~w interior pegs and ~w boundary pegs; by Pick's theorem the area is ~w = ~w + ~w/2 - 1.",
           [I, B, Area, I, B]).


% =============================================================================
% Compare — the correct Pick count beside the boundary-peg miscount.
% =============================================================================

geoboard_prod_frames(ClassPegs, Poly, Lattice, Area, I, B, [F]) :-
    Scene = _{ format: "geoboard", version: 2, lattice: Lattice,
               pegs: ClassPegs, polygon: Poly, area: Area,
               pick: _{ interior: I, boundary: B } },
    geoboard_pick_caption(I, B, Area, Cap),
    F = _{ step: 1, verb: "count_pegs", caption: Cap,
           sceneChanged: true, scene: Scene }.

geoboard_def_frames(ClassPegs, DefPegs, Poly, Lattice,
                    MPX, MPY, Area, WrongArea, I, B, I1, B1, [F1, F2]) :-
    % Frame 1: the boundary peg for reference, counted correctly.
    Scene1 = _{ format: "geoboard", version: 2, lattice: Lattice,
                pegs: ClassPegs, polygon: Poly, area: Area,
                pick: _{ interior: I, boundary: B } },
    format(string(Cap1),
           "The peg (~w, ~w) sits on the band's edge: a boundary peg. Counted there, Pick gives area ~w.",
           [MPX, MPY, Area]),
    F1 = _{ step: 1, verb: "locate_boundary_peg", caption: Cap1,
            sceneChanged: true, scene: Scene1 },
    % Frame 2: the same peg recounted as interior; the reported area inflates.
    Scene2 = _{ format: "geoboard", version: 2, lattice: Lattice,
                pegs: DefPegs, polygon: Poly, area: WrongArea,
                pick: _{ interior: I1, boundary: B1 } },
    format(string(Cap2),
           "Recount (~w, ~w) as interior and the tally reads ~w interior, ~w boundary. Pick then reports area ~w, too large by one half.",
           [MPX, MPY, I1, B1, WrongArea]),
    F2 = _{ step: 2, verb: "miscount_peg", caption: Cap2,
            sceneChanged: true, scene: Scene2 }.

geoboard_compare_note(MPX, MPY, Area, WrongArea, Note) :-
    format(string(Note),
           "Pick's theorem reads area off the lattice as A = I + B/2 - 1. The peg (~w, ~w) \
lies on the band's edge, so it counts toward B. Recounting it as interior moves one unit from \
B to I; because an interior peg weighs twice a boundary peg, the reported area rises from ~w to \
~w, too large by one half. (Boundary-peg-as-interior family.)",
           [MPX, MPY, Area, WrongArea]).

%!  geoboard_pick_boundary_peg(+Pegs, +Vertices, -PX-PY) is det.
%   The boundary peg the miscount moves: a non-corner edge peg where one exists
%   (the classic Pick slip), else the first boundary peg (a corner).
geoboard_pick_boundary_peg(Pegs, Vertices, PX-PY) :-
    findall(X-Y,
            ( member(P, Pegs),
              get_dict(kind, P, "boundary"),
              get_dict(x, P, X),
              get_dict(y, P, Y) ),
            Bnd),
    ( ( member(PX-PY, Bnd), \+ member(PX-PY, Vertices) )
    -> true
    ;  Bnd = [PX-PY|_]
    ).

%!  geoboard_reflag_peg(+Pegs, +MX-MY, -Pegs1) is det.
%   Recolor the peg at (MX, MY) as a deformation counted interior; every other
%   peg keeps role "peg".
geoboard_reflag_peg([], _, []).
geoboard_reflag_peg([P|Ps], MX-MY, [P1|Ps1]) :-
    ( get_dict(x, P, MX), get_dict(y, P, MY)
    -> P1 = _{ x: MX, y: MY, kind: "interior", role: "deformation" }
    ;  P1 = P
    ),
    geoboard_reflag_peg(Ps, MX-MY, Ps1).


% =============================================================================
% Lattice, pegs, and classification.
% =============================================================================

%!  geoboard_lattice(+Vertices, -Lattice) is det.
%   The polygon's bounding box with a one-unit margin, so a peg on the outer edge
%   is legible inside the frame. Lattice is a dict of integer bounds.
geoboard_lattice(Vertices, Lattice) :-
    findall(X, member(X-_, Vertices), Xs),
    findall(Y, member(_-Y, Vertices), Ys),
    min_list(Xs, X0), max_list(Xs, X1),
    min_list(Ys, Y0), max_list(Ys, Y1),
    XMin is X0 - 1, XMax is X1 + 1,
    YMin is Y0 - 1, YMax is Y1 + 1,
    Lattice = _{ xMin: XMin, xMax: XMax, yMin: YMin, yMax: YMax }.

%!  geoboard_lattice_pegs(+Lattice, -Pegs) is det.
%   Every lattice peg, uncounted (kind "outside"): the bare board before the band
%   is closed. Each still carries role "peg".
geoboard_lattice_pegs(Lattice, Pegs) :-
    _{ xMin: XMin, xMax: XMax, yMin: YMin, yMax: YMax } :< Lattice,
    findall(_{ x: X, y: Y, kind: "outside", role: "peg" },
            ( between(XMin, XMax, X),
              between(YMin, YMax, Y) ),
            Pegs).

%!  geoboard_classify_pegs(+Vertices, +Lattice, -Pegs) is det.
%   Every lattice peg classified boundary / interior / outside against the closed
%   polygon. Each carries role "peg".
geoboard_classify_pegs(Vertices, Lattice, Pegs) :-
    geoboard_cyclic_edges(Vertices, Edges),
    _{ xMin: XMin, xMax: XMax, yMin: YMin, yMax: YMax } :< Lattice,
    findall(_{ x: X, y: Y, kind: Kind, role: "peg" },
            ( between(XMin, XMax, X),
              between(YMin, YMax, Y),
              geoboard_peg_kind(X, Y, Edges, Kind) ),
            Pegs).

%!  geoboard_peg_kind(+X, +Y, +Edges, -Kind) is det.
geoboard_peg_kind(X, Y, Edges, "boundary") :-
    once(( member(edge(X1, Y1, X2, Y2), Edges),
           geoboard_on_segment(X, Y, X1, Y1, X2, Y2) )),
    !.
geoboard_peg_kind(X, Y, Edges, "interior") :-
    geoboard_inside(X, Y, Edges),
    !.
geoboard_peg_kind(_, _, _, "outside").

%!  geoboard_pick_counts(+Pegs, -Interior, -Boundary) is det.
geoboard_pick_counts(Pegs, I, B) :-
    findall(x, ( member(P, Pegs), get_dict(kind, P, "interior") ), Is),
    length(Is, I),
    findall(x, ( member(P, Pegs), get_dict(kind, P, "boundary") ), Bs),
    length(Bs, B).

%!  geoboard_cyclic_edges(+Vertices, -Edges) is det.
%   The polygon edges as edge(X1,Y1,X2,Y2) terms, closing the last vertex back to
%   the first.
geoboard_cyclic_edges(Vertices, Edges) :-
    Vertices = [First|_],
    geoboard_cyclic_edges_(Vertices, First, Edges).

geoboard_cyclic_edges_([X1-Y1], FX-FY, [edge(X1, Y1, FX, FY)]) :- !.
geoboard_cyclic_edges_([X1-Y1, X2-Y2|Rest], First, [edge(X1, Y1, X2, Y2)|More]) :-
    geoboard_cyclic_edges_([X2-Y2|Rest], First, More).

%!  geoboard_on_segment(+PX, +PY, +X1, +Y1, +X2, +Y2) is semidet.
%   The lattice peg (PX, PY) lies on the closed segment (X1,Y1)-(X2,Y2): collinear
%   and inside the segment's bounding box.
geoboard_on_segment(PX, PY, X1, Y1, X2, Y2) :-
    Cross is (X2 - X1) * (PY - Y1) - (Y2 - Y1) * (PX - X1),
    Cross =:= 0,
    min(X1, X2) =< PX, PX =< max(X1, X2),
    min(Y1, Y2) =< PY, PY =< max(Y1, Y2).

%!  geoboard_inside(+PX, +PY, +Edges) is semidet.
%   The peg (PX, PY) is strictly inside the polygon by the even-odd ray test.
%   Callers screen off boundary pegs first, so the ray never grazes a vertex it
%   would have to special-case.
geoboard_inside(PX, PY, Edges) :-
    findall(x,
            ( member(edge(X1, Y1, X2, Y2), Edges),
              geoboard_crosses(PX, PY, X1, Y1, X2, Y2) ),
            Cs),
    length(Cs, N),
    1 is N mod 2.

%!  geoboard_crosses(+PX, +PY, +X1, +Y1, +X2, +Y2) is semidet.
%   The rightward ray from (PX, PY) crosses the edge (X1,Y1)-(X2,Y2). Pure integer
%   arithmetic: the horizontal straddle test plus a sign-aware cross-multiply.
geoboard_crosses(PX, PY, X1, Y1, X2, Y2) :-
    ( Y1 > PY -> A1 = 1 ; A1 = 0 ),
    ( Y2 > PY -> A2 = 1 ; A2 = 0 ),
    A1 =\= A2,
    Dy is Y2 - Y1,
    Lhs is (PX - X1) * Dy,
    Rhs is (X2 - X1) * (PY - Y1),
    ( Dy > 0 -> Lhs < Rhs ; Lhs > Rhs ).


% =============================================================================
% Shoelace area and shared helpers.
% =============================================================================

%!  geoboard_shoelace2(+Vertices, -Area2) is det.
%   Twice the enclosed area (an integer for integer vertices) by the shoelace sum.
geoboard_shoelace2(Vertices, Area2) :-
    geoboard_cyclic_edges(Vertices, Edges),
    findall(T,
            ( member(edge(X1, Y1, X2, Y2), Edges),
              T is X1 * Y2 - X2 * Y1 ),
            Ts),
    sum_list(Ts, S),
    Area2 is abs(S).

%!  geoboard_area_value(+Area2, -Area) is det.
%   The area as an integer when whole, else an "N.5" string (a half-unit area).
geoboard_area_value(Area2, Area) :-
    ( 0 =:= Area2 mod 2
    -> Area is Area2 // 2
    ;  Half is Area2 // 2,
       format(string(Area), "~w.5", [Half])
    ).

%!  geoboard_polygon_points(+Vertices, -Poly) is det.
geoboard_polygon_points(Vertices, Poly) :-
    findall(_{ x: X, y: Y }, member(X-Y, Vertices), Poly).

%!  geoboard_simple_closed(+Vertices) is semidet.
%   Three or more distinct integer X-Y lattice pegs forming a non-self-
%   intersecting polygon with nonzero area.
geoboard_simple_closed(Vertices) :-
    is_list(Vertices),
    length(Vertices, N),
    N >= 3,
    forall(member(V, Vertices), geoboard_peg_pair(V, _, _)),
    sort(Vertices, Distinct),
    length(Distinct, N),
    geoboard_shoelace2(Vertices, Area2),
    Area2 > 0,
    \+ geoboard_has_crossing_edges(Vertices).

geoboard_peg_pair(X-Y, X, Y) :- integer(X), integer(Y).

%!  geoboard_has_crossing_edges(+Vertices) is semidet.
%   True when two non-adjacent polygon edges intersect. Adjacent edges share a
%   vertex by construction and are ignored.
geoboard_has_crossing_edges(Vertices) :-
    geoboard_indexed_edges(Vertices, Edges),
    length(Edges, EdgeCount),
    member(E1, Edges),
    member(E2, Edges),
    E1 = edge(I, X1, Y1, X2, Y2),
    E2 = edge(J, X3, Y3, X4, Y4),
    I < J,
    \+ geoboard_adjacent_edge_indices(I, J, EdgeCount),
    geoboard_segments_intersect(X1, Y1, X2, Y2, X3, Y3, X4, Y4).

geoboard_indexed_edges(Vertices, Edges) :-
    Vertices = [First|_],
    geoboard_indexed_edges_(Vertices, First, 1, Edges).

geoboard_indexed_edges_([X1-Y1], FX-FY, I, [edge(I, X1, Y1, FX, FY)]) :- !.
geoboard_indexed_edges_([X1-Y1, X2-Y2|Rest], First, I,
                        [edge(I, X1, Y1, X2, Y2)|Edges]) :-
    I1 is I + 1,
    geoboard_indexed_edges_([X2-Y2|Rest], First, I1, Edges).

geoboard_adjacent_edge_indices(I, J, EdgeCount) :-
    ( J =:= I + 1
    ; I =:= 1, J =:= EdgeCount
    ).

geoboard_segments_intersect(X1, Y1, X2, Y2, X3, Y3, X4, Y4) :-
    geoboard_orientation(X1, Y1, X2, Y2, X3, Y3, O1),
    geoboard_orientation(X1, Y1, X2, Y2, X4, Y4, O2),
    geoboard_orientation(X3, Y3, X4, Y4, X1, Y1, O3),
    geoboard_orientation(X3, Y3, X4, Y4, X2, Y2, O4),
    ( O1 =\= O2, O3 =\= O4
    ; O1 =:= 0, geoboard_on_segment(X3, Y3, X1, Y1, X2, Y2)
    ; O2 =:= 0, geoboard_on_segment(X4, Y4, X1, Y1, X2, Y2)
    ; O3 =:= 0, geoboard_on_segment(X1, Y1, X3, Y3, X4, Y4)
    ; O4 =:= 0, geoboard_on_segment(X2, Y2, X3, Y3, X4, Y4)
    ).

geoboard_orientation(X1, Y1, X2, Y2, X3, Y3, Orientation) :-
    Cross is (X2 - X1) * (Y3 - Y1) - (Y2 - Y1) * (X3 - X1),
    ( Cross > 0
    -> Orientation = 1
    ;  Cross < 0
    -> Orientation = -1
    ;  Orientation = 0
    ).

%!  geoboard_vertex_list_string(+Vertices, -Str) is det.
geoboard_vertex_list_string(Vertices, Str) :-
    findall(S,
            ( member(X-Y, Vertices),
              format(string(S), "(~w, ~w)", [X, Y]) ),
            Ss),
    atomic_list_concat(Ss, ", ", Atom),
    atom_string(Atom, Str).

%!  geoboard_gen_frames(+Spec, -Frames) for the frames-only entry point.
geoboard_gen_frames(stretch_polygon(Vertices), Frames) :-
    geoboard_simple_closed(Vertices),
    !,
    geoboard_lattice(Vertices, Lattice),
    geoboard_shoelace2(Vertices, Area2),
    geoboard_area_value(Area2, Area),
    geoboard_classify_pegs(Vertices, Lattice, ClassPegs),
    geoboard_pick_counts(ClassPegs, I, B),
    geoboard_polygon_frames(Vertices, Lattice, Area, I, B, Frames).

%!  geoboard_deferred_frame(+Spec, -Frame) is det.
%   An unbuildable spec is annotation-only: a bare board, no throw.
geoboard_deferred_frame(Spec, Frame) :-
    term_to_string(Spec, SpecStr),
    format(string(Cap), "No geoboard polygon for ~w; nothing drawn.", [SpecStr]),
    Scene = _{ format: "geoboard", version: 2,
               lattice: _{ xMin: -1, xMax: 1, yMin: -1, yMax: 1 },
               pegs: [], polygon: [], area: 0,
               pick: _{ interior: 0, boundary: 0 } },
    Frame = _{ step: 1, verb: SpecStr, caption: Cap,
               sceneChanged: false, scene: Scene }.

%!  canvas_dict(-Canvas) is det.
canvas_dict(_{ width: 520, height: 520 }).
