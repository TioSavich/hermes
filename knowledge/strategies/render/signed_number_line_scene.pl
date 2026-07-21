/** <module> Lightweight signed-number and inequality number-line scenes */

:- module(signed_number_line_scene,
          [ signed_number_line_render_json/2
          ]).


signed_number_line_render_json(signed_locations(Values), Dict) :-
    ( signed_integer_values(Values, Sorted)
    -> signed_location_frame(Sorted, Frame),
       Dict = _{ kind: "signed_locations",
                 request: _{ values: Sorted },
                 result: "signed values located and ordered",
                 canvas: _{width: 720, height: 320},
                 frames: [Frame] }
    ;  Dict = _{ kind: "signed_locations",
                 request: _{ values: Values },
                 error: "Signed locations require a non-empty list of integers.",
                 frames: [] }
    ).
signed_number_line_render_json(inequality_solution(Relation, Bound), Dict) :-
    ( inequality_relation(Relation), integer(Bound)
    -> inequality_frame(Relation, Bound, Frame),
       Dict = _{ kind: "inequality_solution",
                 request: _{ relation: Relation, bound: Bound },
                 result: "solution set shown as a number-line ray",
                 canvas: _{width: 720, height: 320},
                 frames: [Frame] }
    ;  Dict = _{ kind: "inequality_solution",
                 request: _{ relation: Relation, bound: Bound },
                 error: "An inequality ray requires lt, lte, gt, or gte and an integer bound.",
                 frames: [] }
    ).


signed_integer_values([Value|Values], Sorted) :-
    integer(Value),
    maplist(integer, Values),
    sort([Value|Values], Sorted).

signed_location_frame(Values, Frame) :-
    min_list([0|Values], RawMin),
    max_list([0|Values], RawMax),
    Min is RawMin - 1,
    Max is RawMax + 1,
    integer_ticks(Min, Max, Ticks),
    maplist(signed_mark, Values, Marks),
    Scene = _{ format: "number-line", version: 2, mode: "signed-points",
               axis: _{ min: Min, max: Max, ticks: Ticks,
                        scaleBreak: false, breakEnd: 0 },
               jumps: [], intervals: [], marks: Marks },
    Frame = _{ step: 1, verb: "locate_signed_values",
               caption: "Locate each signed value relative to zero; left-to-right position gives numerical order.",
               sceneChanged: true, scene: Scene }.

integer_ticks(Min, Max, Ticks) :-
    Span is Max - Min,
    ( Span =< 20
    -> findall(Tick, between(Min, Max, Tick), Ticks)
    ;  Ticks = [Min, 0, Max]
    ).

signed_mark(Value, _{at: Value, label: Label, role: "point"}) :-
    format(string(Label), "~w", [Value]).

inequality_relation(lt).
inequality_relation(lte).
inequality_relation(gt).
inequality_relation(gte).

inequality_frame(Relation, Bound, Frame) :-
    Min is min(-1, Bound - 5),
    Max is max(1, Bound + 5),
    integer_ticks(Min, Max, Ticks),
    inequality_interval(Relation, Bound, Min, Max, Interval),
    Scene = _{ format: "number-line", version: 2, mode: "inequality-ray",
               axis: _{ min: Min, max: Max, ticks: Ticks,
                        scaleBreak: false, breakEnd: 0 },
               jumps: [], intervals: [Interval], marks: [] },
    Frame = _{ step: 1, verb: "draw_inequality_solution_set",
               caption: "Mark the boundary and extend through every value that satisfies the inequality.",
               sceneChanged: true, scene: Scene }.

inequality_interval(lt, Bound, Min, _,
                    _{from: Min, to: Bound, endpoint: "open",
                      arrow: "left", role: "iterated"}).
inequality_interval(lte, Bound, Min, _,
                    _{from: Min, to: Bound, endpoint: "closed",
                      arrow: "left", role: "iterated"}).
inequality_interval(gt, Bound, _, Max,
                    _{from: Bound, to: Max, endpoint: "open",
                      arrow: "right", role: "iterated"}).
inequality_interval(gte, Bound, _, Max,
                    _{from: Bound, to: Max, endpoint: "closed",
                      arrow: "right", role: "iterated"}).
