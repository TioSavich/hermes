/** <module> Unit-square covering scenes for area measurement */

:- module(area_unit_covering_scene,
          [ area_unit_covering_render_json/2
          ]).

:- use_module(library(lists), [nth1/3]).


area_unit_covering_render_json(cover(Cells, Unit), Dict) :-
    !,
    ( valid_cells(Cells, Unit), sort(Cells, Cells)
    -> cell_rects(Cells, Cells, Rects),
       length(Cells, Count),
       area_frame(Cells, Unit, Rects, Count, Count, Frame),
       format(string(Result), "~w square ~w units", [Count, Unit]),
       Dict = _{kind: "area_unit_covering",
                request: _{cells: Cells, unit: Unit}, result: Result,
                frames: [Frame]}
    ;  Dict = _{kind: "area_unit_covering",
                error: "A covering needs distinct nonnegative grid cells and a named unit.",
                frames: []}
    ).
area_unit_covering_render_json(overlap(Cells, Unit), Dict) :-
    !,
    ( valid_cells(Cells, Unit), sort(Cells, Unique),
      length(Cells, Placed), length(Unique, Covered), Placed > Covered
    -> cell_rects(Cells, Unique, Rects),
       area_frame(Cells, Unit, Rects, Placed, Covered, Frame),
       format(string(Result), "~w placed tiles over ~w covered square units",
              [Placed, Covered]),
       Dict = _{kind: "area_unit_covering_deformation",
                request: _{cells: Cells, unit: Unit}, result: Result,
                frames: [Frame]}
    ;  Dict = _{kind: "area_unit_covering_deformation",
                error: "An overlap scene needs at least one repeated grid cell.",
                frames: []}
    ).
area_unit_covering_render_json(Spec,
                               _{kind: "area_unit_covering",
                                 request: Spec,
                                 error: "Unknown area-covering specification.",
                                 frames: []}).


valid_cells([Cell|Cells], Unit) :-
    atom(Unit),
    maplist(valid_cell, [Cell|Cells]).

valid_cell(X-Y) :-
    integer(X), X >= 0, X =< 20,
    integer(Y), Y >= 0, Y =< 20.

cell_rects(Cells, Unique, Rects) :-
    findall(Rect,
            ( nth1(Index, Cells, Cell),
              cell_rect(Cell, Cells, Unique, Index, Rect)
            ),
            Rects).

cell_rect(X-Y, Cells, _Unique, Index, Rect) :-
    prior_occurrences(Cells, Index, X-Y, Prior),
    Offset is Prior * 6,
    PixelX is 40 + X * 58 + Offset,
    PixelY is 40 + Y * 58 - Offset,
    ( Prior =:= 0 -> Role = "highlight" ; Role = "deformation" ),
    Rect = _{x: PixelX, y: PixelY, w: 58, h: 58,
             rows: 1, cols: 1, role: Role, label: ""}.

prior_occurrences(Cells, Index, Cell, Count) :-
    findall(1,
            ( nth1(PriorIndex, Cells, Cell), PriorIndex < Index ),
            Matches),
    length(Matches, Count).

area_frame(Cells, Unit, Rects, Placed, Covered, Frame) :-
    Scene = _{format: "area-model", version: 2,
              model: "unit-square-covering", unit: Unit,
              placements: Cells, placedTileCount: Placed,
              coveredCellCount: Covered, rects: Rects,
              gridlines: _{v: [], h: []}},
    format(string(Caption),
           "~w unit-square placements cover ~w distinct square ~w units.",
           [Placed, Covered, Unit]),
    Frame = _{step: 1, verb: "cover_region_with_unit_squares",
              caption: Caption, sceneChanged: true, scene: Scene}.
