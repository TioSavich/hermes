/** <module> Lightweight linear-measurement strip scene
 *
 * Emits the existing number-line v2 fraction-jumps contract without loading
 * Hermes or the action registry. Coordinates count equal subintervals: K means
 * K/D of the named unit, so the representation preserves both the continuous
 * extent and the unit referent.
 */

:- module(measurement_strip_scene,
          [ measurement_strip_render_json/2
          ]).

:- use_module(library(lists), [numlist/3, reverse/2]).


measurement_strip_render_json(measure(IntervalCount, Subdivisions, Unit), Dict) :-
    !,
    ( valid_request(IntervalCount, Subdivisions, Unit)
    -> measurement_frames(IntervalCount, Subdivisions, Unit, Frames),
       format(string(Result), "~w/~w ~w", [IntervalCount, Subdivisions, Unit]),
       Dict = _{ kind: "linear_measurement",
                 request: _{interval_count: IntervalCount,
                            subdivisions_per_unit: Subdivisions,
                            unit: Unit},
                 result: Result,
                 frames: Frames }
    ;  Dict = _{ kind: "linear_measurement",
                 error: "Linear measurement needs positive interval and subdivision counts plus a named unit.",
                 frames: [] }
    ).
measurement_strip_render_json(Spec,
                              _{kind: "linear_measurement",
                                request: Spec,
                                error: "Unknown linear-measurement specification.",
                                frames: []}).


valid_request(IntervalCount, Subdivisions, Unit) :-
    integer(IntervalCount), IntervalCount > 0,
    integer(Subdivisions), Subdivisions > 0,
    atom(Unit).

measurement_frames(IntervalCount, Subdivisions, Unit, Frames) :-
    WholeCount is max(1, (IntervalCount + Subdivisions - 1) // Subdivisions),
    AxisMax is WholeCount * Subdivisions,
    numlist(0, AxisMax, Ticks),
    Axis = _{min: 0, max: AxisMax, ticks: Ticks,
             scaleBreak: _{enabled: false, at: 0}},
    measurement_frames_(1, IntervalCount, Subdivisions, Unit,
                        Axis, [], Frames).

measurement_frames_(K, IntervalCount, _Subdivisions, _Unit,
                    _Axis, _ReverseJumps, []) :-
    K > IntervalCount,
    !.
measurement_frames_(K, IntervalCount, Subdivisions, Unit,
                    Axis, ReverseJumps0, [Frame|Frames]) :-
    From is K - 1,
    format(string(UnitLabel), "1/~w ~w", [Subdivisions, Unit]),
    Jump = _{from: From, to: K, by: 1, label: UnitLabel,
             tier: "unit", role: "jump-add"},
    reverse([Jump|ReverseJumps0], Jumps),
    measurement_marks(K, Subdivisions, Unit, Marks),
    Scene = _{format: "number-line", version: 2,
              mode: "fraction-jumps",
              coordinateDenominator: Subdivisions,
              referentWholeAt: Subdivisions,
              measurementUnit: Unit,
              axis: Axis, jumps: Jumps, marks: Marks},
    format(string(Caption), "Iterate one ~w of ~w equal parts to reach ~w/~w ~w.",
           [Unit, Subdivisions, K, Subdivisions, Unit]),
    format(string(Verb), "iterate_measurement_interval(~w,1/~w,~w)",
           [K, Subdivisions, Unit]),
    Frame = _{step: K, verb: Verb, caption: Caption,
              sceneChanged: true, scene: Scene},
    K1 is K + 1,
    measurement_frames_(K1, IntervalCount, Subdivisions, Unit,
                        Axis, [Jump|ReverseJumps0], Frames).

measurement_marks(K, Subdivisions, Unit, Marks) :-
    findall(_{at: At, label: Label},
            ( between(0, K, At),
              landmark(At, K, Subdivisions),
              landmark_label(At, Subdivisions, Unit, Label)
            ),
            Marks).

landmark(0, _K, _Subdivisions).
landmark(At, _K, Subdivisions) :-
    At > 0,
    0 is At mod Subdivisions.
landmark(At, K, Subdivisions) :-
    At =:= K,
    At mod Subdivisions =\= 0.

landmark_label(0, _Subdivisions, _Unit, "0") :- !.
landmark_label(K, Subdivisions, Unit, Label) :-
    ( 0 is K mod Subdivisions
    -> Whole is K // Subdivisions,
       format(string(Label), "~w ~w", [Whole, Unit])
    ;  format(string(Label), "~w/~w ~w", [K, Subdivisions, Unit])
    ).
