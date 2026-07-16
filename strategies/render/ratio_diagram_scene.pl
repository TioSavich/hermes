/** <module> Referent-preserving ratio diagram scenes */

:- module(ratio_diagram_scene,
          [ ratio_diagram_render_json/2
          ]).

:- use_module(math(integer_helpers), [positive_integer/1]).


ratio_diagram_render_json(ratio(FirstLabel, FirstCount,
                                SecondLabel, SecondCount), Dict) :-
    !,
    ( valid_ratio_request(FirstLabel, FirstCount, SecondLabel, SecondCount)
    -> ratio_frames(FirstLabel, FirstCount, SecondLabel, SecondCount, Frames),
       format(string(Result), "~w ~w for every ~w ~w",
              [FirstCount, FirstLabel, SecondCount, SecondLabel]),
       Dict = _{kind: "referent_ratio_diagram",
                request: _{first_label: FirstLabel, first_count: FirstCount,
                           second_label: SecondLabel, second_count: SecondCount},
                result: Result,
                frames: Frames}
    ;  Dict = _{kind: "referent_ratio_diagram",
                error: "A ratio diagram needs two distinct labels and positive counts.",
                frames: []}
    ).
ratio_diagram_render_json(Spec,
                          _{kind: "referent_ratio_diagram",
                            request: Spec,
                            error: "Unknown ratio-diagram specification.",
                            frames: []}).


valid_ratio_request(FirstLabel, FirstCount, SecondLabel, SecondCount) :-
    atom(FirstLabel), atom(SecondLabel),
    FirstLabel \== SecondLabel,
    positive_integer(FirstCount), positive_integer(SecondCount),
    FirstCount =< 20, SecondCount =< 20.

ratio_frames(FirstLabel, FirstCount, SecondLabel, SecondCount,
             [CollectionFrame, RatioFrame]) :-
    ratio_scene(FirstLabel, FirstCount, SecondLabel, SecondCount, Scene),
    format(string(CollectionCaption),
           "Coordinate the two quantities: ~w ~w and ~w ~w.",
           [FirstCount, FirstLabel, SecondCount, SecondLabel]),
    CollectionFrame = _{step: 1, verb: "coordinate_ratio_referents",
                        caption: CollectionCaption, sceneChanged: true,
                        scene: Scene},
    format(string(RatioCaption),
           "The ordered ratio of ~w to ~w is ~w:~w.",
           [FirstLabel, SecondLabel, FirstCount, SecondCount]),
    RatioFrame = _{step: 2, verb: "inscribe_ordered_ratio",
                   caption: RatioCaption, sceneChanged: false,
                   scene: Scene}.

ratio_scene(FirstLabel, FirstCount, SecondLabel, SecondCount, Scene) :-
    UnitWidth = 34,
    FirstWidth is UnitWidth * FirstCount,
    SecondWidth is UnitWidth * SecondCount,
    format(string(FirstText), "~w ~w", [FirstCount, FirstLabel]),
    format(string(SecondText), "~w ~w", [SecondCount, SecondLabel]),
    FirstRect = _{x: 40, y: 40, w: FirstWidth, h: 64,
                  rows: 1, cols: FirstCount, role: "highlight",
                  label: FirstText},
    SecondRect = _{x: 40, y: 132, w: SecondWidth, h: 64,
                   rows: 1, cols: SecondCount, role: "iterated",
                   label: SecondText},
    Scene = _{format: "area-model", version: 2,
              model: "referent-ratio-tapes",
              orderedReferents: [FirstLabel, SecondLabel],
              ratioTerms: [FirstCount, SecondCount],
              rects: [FirstRect, SecondRect],
              gridlines: _{v: [], h: []}}.
