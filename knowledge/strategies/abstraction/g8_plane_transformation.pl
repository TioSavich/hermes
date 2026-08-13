:- encoding(utf8).
/** <module> Grade 8 pilot: transformations of the coordinate plane, drawn
 *
 * WHAT THIS IS. A quarantined pilot automaton for the doing IM grade 8 units 1
 * and 2 are built on: move a figure by a translation, a rotation about a
 * point, a reflection over a line, or a dilation from a center, and report
 * where every vertex lands.
 *
 * WHY IT EXISTS AT ALL. An earlier pass in this lane called the dilation
 * cluster inherently visual and routed none of it. Tio reversed that, and the
 * reversal is right. A transformation of the plane is a coordinate map on
 * exact rationals — the most computable thing in grade 8 — and calling it
 * visual confused the ANSWER'S FORM with the answer's content. What the task
 * asks for is a drawing, so the solution to a drawing task IS the drawing
 * code. This pilot therefore returns two things at once: the exact image
 * coordinates, and a scene specification in the coordinate-plane grapher's own
 * JSON genre (`hermes/web/coordinate-plane`, schema version 1) that draws the
 * pre-image and the image together. The verification runs the spec through
 * that renderer.
 *
 * WHY BOTH DRAWINGS. A deformation emits a scene too. A teacher working with a
 * student draws their own idea and the student's thinking side by side, in the
 * spatial form the thinking actually took; a wrong reading that cannot be
 * drawn cannot be discussed. So `dilate_by_adding_a_constant` returns a scene
 * showing where the student's figure lands beside where the dilation puts it.
 * The vocabulary stays the engine's: the deformation carries `expected` and
 * `result` and an `attested_as` row, and it never calls a student anything.
 *
 * EXACT, NOT PLOTTED. Every image coordinate is an exact rational. The
 * defining relation is checked on SQUARED distances so no square root and no
 * float enters: a dilation by k multiplies every squared distance from the
 * center by k squared and keeps center, pre-image, and image collinear; a
 * rotation and a reflection keep every squared distance from the center or the
 * mirror; a translation keeps one difference vector for every vertex. The
 * scene carries floats only because the renderer's schema takes numbers, and
 * it is built from the exact values at the last step.
 *
 * WHERE THE COORDINATES COME FROM, SAID PLAINLY. The transformation rows name
 * their center, their scale factor, and their move in words, and they put the
 * COORDINATES in a figure the statement only points at. Two receipts below
 * carry a number the row prints — IM-G8-U2-L9's side lengths 2, 3, 4 against
 * 4, 5, 6, and IM-G8-U2-L12's scale factor 2 — on vertices this pilot places;
 * they are marked `printed_factor_witness_placement`. Three carry a witness
 * placement throughout and are marked `witness_placement`. The machine and its
 * verification are real and complete; what waits on the vision lane is the
 * figure's own coordinates, and when those land these receipts are replaced
 * rather than supplemented. No receipt here claims a coordinate the curriculum
 * printed.
 *
 * ROTATIONS ARE QUARTER TURNS. The corpus stays at multiples of 90 degrees, so
 * this pilot does too; any other angle refuses by name rather than reaching for
 * a trigonometric approximation that would break the exactness the rest of the
 * module keeps.
 *
 * DEFORMATION PARTNER. One, attested: `dilate_by_adding_a_constant` reproduces
 * db_row 38669 (Brousseau, Brousseau & Warfield 2008, Journal of Mathematical
 * Behavior, pp. 154-156), where students enlarge a figure by adding a constant
 * to every dimension instead of multiplying by a ratio — "almost all the
 * students think that the thing to do is to add 3 cm to every dimension".
 *
 * QUARANTINE. Nothing imports this module; it renames nothing; its rows are
 * authored and vetoable one by one. Check: `check_g8_plane_transformation/0`.
 */

:- module(g8_plane_transformation,
          [ run_g8_transformation/4,
            g8_transformation_from_json/2,
            g8_transformation_states/1,
            g8_transformation_state_label/4,
            g8_transformation_summary/1,
            g8_transformation_receipt/6,
            g8_transformation_scene/2,
            check_g8_plane_transformation/0
          ]).

:- use_module(strategies('abstraction/g8_quantity_input'),
              [ g8_quantity/2, g8_rational_text/2 ]).

% ==========================================================================
% 1. INPUT CONTRACT
%
%   {"kind":"plane_transformation","transformation":"dilation",
%    "figure":{"name":"Triangle A",
%              "vertices":[{"label":"P","x":1,"y":2},
%                          {"label":"Q","x":3,"y":2},
%                          {"label":"R","x":1,"y":5}]},
%    "center":{"x":0,"y":0},"scale_factor":2}
%   ... "transformation":"translation","vector":{"x":4,"y":-1}
%   ... "transformation":"rotation","center":{...},"degrees":90
%   ... "transformation":"reflection","line":{"axis":"x"}      (or "y",
%                                             or {"vertical":3} / {"horizontal":-2})
% ==========================================================================

g8_transformation_input_contract(
    '{\"kind\":\"plane_transformation\",\"transformation\":\"string\",\"figure\":{\"name\":\"string\",\"vertices\":[{\"label\":\"string\",\"x\":\"number\",\"y\":\"number\"}]},\"center\":{\"x\":\"number\",\"y\":\"number\"},\"scale_factor\":\"number\",\"vector\":{\"x\":\"number\",\"y\":\"number\"},\"degrees\":\"integer\",\"line\":{\"axis\":\"string\"}}',
    '{\"kind\":\"plane_transformation\",\"transformation\":\"dilation\",\"figure\":{\"name\":\"Triangle A\",\"vertices\":[{\"label\":\"P\",\"x\":1,\"y\":2},{\"label\":\"Q\",\"x\":3,\"y\":2},{\"label\":\"R\",\"x\":1,\"y\":5}]},\"center\":{\"x\":0,\"y\":0},\"scale_factor\":2}').

g8_transformation_from_json(Dict, transformation(Kind, Figure, Parameter)) :-
    is_dict(Dict),
    get_dict(kind, Dict, "plane_transformation"),
    get_dict(transformation, Dict, KindText),
    memberchk(KindText, ["dilation", "translation", "rotation", "reflection"]),
    atom_string(Kind, KindText),
    get_dict(figure, Dict, F), figure_of(F, Figure),
    parameter_of(Kind, Dict, Parameter).

figure_of(Dict, figure(Name, Vertices)) :-
    ( get_dict(name, Dict, N), string(N) -> Name = N ; Name = "figure" ),
    get_dict(vertices, Dict, Raw),
    length(Raw, Count), Count >= 2,
    vertices_of(Raw, Vertices).

vertices_of([], []).
vertices_of([D|T], [vertex(Label, X, Y)|R]) :-
    ( get_dict(label, D, L), string(L) -> Label = L ; Label = "" ),
    get_dict(x, D, X0), get_dict(y, D, Y0),
    g8_quantity(X0, X), g8_quantity(Y0, Y),
    vertices_of(T, R).

parameter_of(dilation, Dict, dilation(CX, CY, K)) :-
    get_dict(center, Dict, C), point_of(C, CX, CY),
    get_dict(scale_factor, Dict, K0), g8_quantity(K0, K), K =\= 0.
parameter_of(translation, Dict, translation(VX, VY)) :-
    get_dict(vector, Dict, V), point_of(V, VX, VY),
    \+ ( VX =:= 0, VY =:= 0 ).
parameter_of(rotation, Dict, rotation(CX, CY, Degrees)) :-
    get_dict(center, Dict, C), point_of(C, CX, CY),
    get_dict(degrees, Dict, D0), integer(D0),
    0 =:= D0 mod 90,
    Degrees is ((D0 mod 360) + 360) mod 360.
parameter_of(reflection, Dict, reflection(Line)) :-
    get_dict(line, Dict, L),
    (   get_dict(axis, L, "x") -> Line = horizontal_axis
    ;   get_dict(axis, L, "y") -> Line = vertical_axis
    ;   get_dict(vertical, L, V0) -> g8_quantity(V0, V), Line = vertical(V)
    ;   get_dict(horizontal, L, H0) -> g8_quantity(H0, H), Line = horizontal(H)
    ).

point_of(Dict, X, Y) :-
    get_dict(x, Dict, X0), get_dict(y, Dict, Y0),
    g8_quantity(X0, X), g8_quantity(Y0, Y).

% ==========================================================================
% 2. STATES
% ==========================================================================

g8_transformation_states(
    [ q_read_the_figure,
      q_name_the_center_or_line_or_vector,
      q_map_each_vertex,
      q_check_the_defining_relation,
      q_draw_the_pre_image_and_the_image,
      q_accept_the_image,
      q_refuse_unsupported_angle,
      q_add_a_constant_to_every_coordinate ]).

% g8_transformation_state_label(State, Tradition, Label, Citation).
g8_transformation_state_label(q_read_the_figure, illustrative_mathematics,
    "the original figure",
    "IM Grade 8 Unit 1 Lesson 3, Grid Moves").
g8_transformation_state_label(q_name_the_center_or_line_or_vector,
    illustrative_mathematics,
    "the center of the dilation, the line of reflection, or the directed line segment",
    "IM Grade 8 Unit 1 Lesson 4; Unit 2 Lesson 3, Dilations with no Grid").
g8_transformation_state_label(q_map_each_vertex, ccss,
    "a transformation takes each point of the plane to a point of the plane",
    "CCSS 8.G.A.3, via IM Grade 8 Units 1-2").
g8_transformation_state_label(q_map_each_vertex, van_de_walle,
    "the image of each vertex",
    "Van de Walle, ch. 18, Transformations").
g8_transformation_state_label(q_check_the_defining_relation, provisional,
    "check the transformation did what it says",
    "provisional; no community label sourced for this checking step").
g8_transformation_state_label(q_draw_the_pre_image_and_the_image,
    illustrative_mathematics,
    "draw the image of the figure",
    "IM Grade 8 Unit 1 Lesson 4, Making the Moves").
g8_transformation_state_label(q_accept_the_image, illustrative_mathematics,
    "the image", "IM Grade 8 Unit 1 Lesson 2, Naming the Moves").
g8_transformation_state_label(q_add_a_constant_to_every_coordinate, brousseau,
    "adding a constant to every dimension to enlarge",
    "db_row 38669; Brousseau, Brousseau & Warfield 2008, Journal of Mathematical Behavior, pp. 154-156").

% ==========================================================================
% 3. TRANSITIONS
% ==========================================================================

g8_transformation_transition(map_figure_through_transformation,
    q_read_the_figure, name_the_center_or_line_or_vector,
    q_name_the_center_or_line_or_vector).
g8_transformation_transition(map_figure_through_transformation,
    q_name_the_center_or_line_or_vector, map_each_vertex, q_map_each_vertex).
g8_transformation_transition(map_figure_through_transformation,
    q_map_each_vertex, check_the_defining_relation,
    q_check_the_defining_relation).
g8_transformation_transition(map_figure_through_transformation,
    q_check_the_defining_relation, draw_the_pre_image_and_the_image,
    q_draw_the_pre_image_and_the_image).
g8_transformation_transition(map_figure_through_transformation,
    q_draw_the_pre_image_and_the_image, report_the_image, q_accept_the_image).
g8_transformation_transition(map_figure_through_transformation,
    q_name_the_center_or_line_or_vector, refuse_unsupported_angle,
    q_refuse_unsupported_angle).
g8_transformation_transition(dilate_by_adding_a_constant,
    q_name_the_center_or_line_or_vector, add_a_constant_to_every_coordinate,
    q_add_a_constant_to_every_coordinate).

% ==========================================================================
% 4. THE RUN
% ==========================================================================

run_g8_transformation(map_figure_through_transformation,
                      transformation(Kind, figure(Name, Vertices), Parameter),
                      Outcome, Trace) :-
    map_vertices(Parameter, Vertices, Images),
    defining_relation(Parameter, Vertices, Images, Relation, RelationName),
    ( Relation == holds -> Validity = correct ; Validity = unvindicated ),
    image_name(Name, ImageName),
    scene(Name, Vertices, ImageName, Images, Kind, Scene),
    vertices_text(Images, ImagesText),
    Outcome = action_outcome(
        map_figure_through_transformation,
        [ classification(productive),
          cluster(g8_plane_transformations),
          automaton_state(q_accept_the_image),
          vocabulary([transformation, translation, rotation, reflection,
                      dilation, center, scale_factor, image, pre_image,
                      vertex, coordinate_plane]),
          input(transformation(Kind, figure(Name, Vertices), Parameter)),
          result(image(ImageName, ImagesText)),
          expected(image(ImageName, ImagesText)),
          image_vertices(Images),
          defining_relation(RelationName, Relation),
          scene(Scene),
          invariant(RelationName),
          validity(Validity) ]),
    Trace = [ read_the_figure(Name),
              name_the_center_or_line_or_vector(Parameter),
              map_each_vertex(ImagesText),
              check_the_defining_relation(RelationName, Relation),
              draw_the_pre_image_and_the_image(Scene),
              report_the_image(ImageName) ].
run_g8_transformation(map_figure_through_transformation,
                      transformation(rotation, figure(Name, Vertices),
                                     unsupported_angle(D)),
                      Outcome, Trace) :-
    Outcome = action_outcome(
        map_figure_through_transformation,
        [ classification(refusal),
          cluster(g8_plane_transformations),
          automaton_state(q_refuse_unsupported_angle),
          vocabulary([rotation, angle, quarter_turn]),
          input(transformation(rotation, figure(Name, Vertices),
                               unsupported_angle(D))),
          result(refused(rotation_angle_outside_quarter_turns)),
          refusal(refusal{kind: "rotation_angle_not_a_quarter_turn",
                          degrees: D}),
          validity(refused) ]),
    Trace = [ read_the_figure(Name), refuse_unsupported_angle(D) ].
run_g8_transformation(dilate_by_adding_a_constant,
                      transformation(dilation, figure(Name, Vertices),
                                     dilation(CX, CY, K)),
                      Outcome, Trace) :-
    % Attested locus: an enlargement, where adding a constant and multiplying
    % by a ratio genuinely part company.
    K > 1,
    map_vertices(dilation(CX, CY, K), Vertices, Productive),
    Constant is K - 1,
    add_constant(Constant, Vertices, Deformed),
    defining_relation(dilation(CX, CY, K), Vertices, Deformed, Relation, Name0),
    ( Relation == fails -> Validity = incorrect ; Validity = unvindicated ),
    image_name(Name, ImageName),
    scene(Name, Vertices, ImageName, Deformed, dilation_by_adding, Scene),
    vertices_text(Deformed, DeformedText),
    vertices_text(Productive, ProductiveText),
    g8_rational_text(Constant, ConstantText),
    Outcome = action_outcome(
        dilate_by_adding_a_constant,
        [ classification(deformation),
          cluster(g8_plane_transformations),
          automaton_state(q_add_a_constant_to_every_coordinate),
          vocabulary([dilation, scale_factor, enlargement, additive,
                      multiplicative, image]),
          input(transformation(dilation, figure(Name, Vertices),
                               dilation(CX, CY, K))),
          expected(image(ImageName, ProductiveText)),
          result(image(ImageName, DeformedText)),
          added_constant(ConstantText),
          defining_relation(Name0, Relation),
          scene(Scene),
          deformation_of(map_figure_through_transformation),
          violated_invariant(Name0),
          attested_as(db_row(38669),
                      "Brousseau, Brousseau & Warfield 2008, Journal of Mathematical Behavior, pp. 154-156"),
          validity(Validity) ]),
    Trace = [ read_the_figure(Name),
              add_a_constant_to_every_coordinate(ConstantText),
              draw_the_pre_image_and_the_image(Scene) ].

% --- the coordinate maps, all exact -------------------------------------

map_vertices(_, [], []).
map_vertices(P, [V|Vs], [I|Is]) :- map_vertex(P, V, I), map_vertices(P, Vs, Is).

map_vertex(dilation(CX, CY, K), vertex(L, X, Y), vertex(L, IX, IY)) :-
    IX is CX + K * (X - CX),
    IY is CY + K * (Y - CY).
map_vertex(translation(VX, VY), vertex(L, X, Y), vertex(L, IX, IY)) :-
    IX is X + VX, IY is Y + VY.
map_vertex(rotation(CX, CY, D), vertex(L, X, Y), vertex(L, IX, IY)) :-
    DX is X - CX, DY is Y - CY,
    quarter_turn(D, DX, DY, RX, RY),
    IX is CX + RX, IY is CY + RY.
map_vertex(reflection(Line), vertex(L, X, Y), vertex(L, IX, IY)) :-
    mirror(Line, X, Y, IX, IY).

quarter_turn(0, DX, DY, DX, DY).
quarter_turn(90, DX, DY, RX, RY) :- RX is -DY, RY is DX.
quarter_turn(180, DX, DY, RX, RY) :- RX is -DX, RY is -DY.
quarter_turn(270, DX, DY, RX, RY) :- RX is DY, RY is -DX.

mirror(horizontal_axis, X, Y, X, IY) :- IY is -Y.
mirror(vertical_axis, X, Y, IX, Y) :- IX is -X.
mirror(vertical(A), X, Y, IX, Y) :- IX is 2 * A - X.
mirror(horizontal(B), X, Y, X, IY) :- IY is 2 * B - Y.

add_constant(_, [], []).
add_constant(C, [vertex(L, X, Y)|T], [vertex(L, IX, IY)|R]) :-
    IX is X + C, IY is Y + C,
    add_constant(C, T, R).

% --- the defining relations, checked on squares --------------------------

defining_relation(dilation(CX, CY, K), Pre, Image, Verdict,
                  every_image_distance_from_the_center_scales_by_the_factor) :-
    KSquared is K * K,
    (   forall(nth0(N, Pre, vertex(_, X, Y)),
               ( nth0(N, Image, vertex(_, IX, IY)),
                 PreSquared is (X - CX) * (X - CX) + (Y - CY) * (Y - CY),
                 ImageSquared is (IX - CX) * (IX - CX) + (IY - CY) * (IY - CY),
                 ImageSquared =:= KSquared * PreSquared,
                 % center, pre-image, and image stay on one line
                 0 =:= (X - CX) * (IY - CY) - (Y - CY) * (IX - CX) ))
    ->  Verdict = holds
    ;   Verdict = fails
    ).
defining_relation(translation(VX, VY), Pre, Image, Verdict,
                  every_vertex_moves_by_the_same_vector) :-
    (   forall(nth0(N, Pre, vertex(_, X, Y)),
               ( nth0(N, Image, vertex(_, IX, IY)),
                 IX - X =:= VX, IY - Y =:= VY ))
    ->  Verdict = holds
    ;   Verdict = fails
    ).
defining_relation(rotation(CX, CY, _), Pre, Image, Verdict,
                  every_distance_from_the_center_is_preserved) :-
    (   forall(nth0(N, Pre, vertex(_, X, Y)),
               ( nth0(N, Image, vertex(_, IX, IY)),
                 PreSquared is (X - CX) * (X - CX) + (Y - CY) * (Y - CY),
                 ImageSquared is (IX - CX) * (IX - CX) + (IY - CY) * (IY - CY),
                 ImageSquared =:= PreSquared ))
    ->  Verdict = holds
    ;   Verdict = fails
    ).
defining_relation(reflection(Line), Pre, Image, Verdict,
                  the_mirror_bisects_every_vertex_and_its_image) :-
    (   forall(nth0(N, Pre, vertex(_, X, Y)),
               ( nth0(N, Image, vertex(_, IX, IY)),
                 mirror_check(Line, X, Y, IX, IY) ))
    ->  Verdict = holds
    ;   Verdict = fails
    ).

% The midpoint sits on the mirror and the segment runs perpendicular to it.
mirror_check(horizontal_axis, X, Y, IX, IY) :- IX =:= X, IY + Y =:= 0.
mirror_check(vertical_axis, X, Y, IX, IY) :- IY =:= Y, IX + X =:= 0.
mirror_check(vertical(A), X, Y, IX, IY) :- IY =:= Y, IX + X =:= 2 * A.
mirror_check(horizontal(B), X, Y, IX, IY) :- IX =:= X, IY + Y =:= 2 * B.

% --- the drawing ---------------------------------------------------------

image_name(Name, ImageName) :-
    format(string(ImageName), "~w image", [Name]).

%!  scene(+Name, +Pre, +ImageName, +Image, +Kind, -Scene) is det.
%
%   A coordinate-plane specification in the grapher's own genre
%   (hermes/web/coordinate-plane, schema version 1). It draws the pre-image
%   and the image together: labelled points for every vertex of both, and the
%   closed boundary of each as segments.
scene(Name, Pre, ImageName, Image, Kind, Scene) :-
    scene_points(Pre, "#2f7d6e", PrePoints),
    scene_points(Image, "#b5563f", ImagePoints),
    append(PrePoints, ImagePoints, Points),
    scene_edges(Pre, "#2f7d6e", Name, PreEdges),
    scene_edges(Image, "#b5563f", ImageName, ImageEdges),
    append(PreEdges, ImageEdges, Lines),
    format(string(Id), "g8-~w", [Kind]),
    format(string(Title), "~w and its ~w", [Name, Kind]),
    format(string(Description),
           "The vertices of ~w and the vertices of ~w, with each boundary drawn.",
           [Name, ImageName]),
    Scene = scene{version: 1, id: Id, kind: "coordinate-plane",
                  title: Title, description: Description,
                  points: Points, lines: Lines}.

scene_points([], _, []).
scene_points([vertex(L, X, Y)|T], Colour, [P|R]) :-
    FX is float(X), FY is float(Y),
    ( L == "" -> P = point{x: FX, y: FY, color: Colour}
    ; P = point{x: FX, y: FY, label: L, color: Colour} ),
    scene_points(T, Colour, R).

scene_edges(Vertices, Colour, Label, Lines) :-
    Vertices = [First|_],
    append(Vertices, [First], Closed),
    consecutive_segments(Closed, Colour, Label, Lines).

consecutive_segments([_], _, _, []) :- !.
consecutive_segments([vertex(_, X1, Y1), vertex(L2, X2, Y2)|T], Colour, Label,
                     [Segment|R]) :-
    FX1 is float(X1), FY1 is float(Y1),
    FX2 is float(X2), FY2 is float(Y2),
    Segment = line{type: "segment",
                   from: point{x: FX1, y: FY1},
                   to: point{x: FX2, y: FY2},
                   color: Colour, label: Label},
    consecutive_segments([vertex(L2, X2, Y2)|T], Colour, Label, R).

%!  g8_transformation_scene(+Outcome, -SceneJSON) is semidet.
%
%   Pull the scene out of an outcome as a JSON string, ready for the
%   grapher. Exposed so a caller can render without re-running the map.
g8_transformation_scene(action_outcome(_, Properties), JSON) :-
    memberchk(scene(Scene), Properties),
    with_output_to(string(JSON), json_write_dict(current_output, Scene,
                                                 [width(0)])).

:- use_module(library(http/json), [json_write_dict/3]).
:- use_module(library(lists), [nth0/3]).

vertices_text([], []).
vertices_text([vertex(L, X, Y)|T], [Text|R]) :-
    g8_rational_text(X, XT), g8_rational_text(Y, YT),
    ( L == "" -> format(string(Text), "(~w, ~w)", [XT, YT])
    ; format(string(Text), "~w(~w, ~w)", [L, XT, YT]) ),
    vertices_text(T, R).

% ==========================================================================
% 5. SELF-SUMMARY
% ==========================================================================

g8_transformation_summary(
    summary{ module: g8_plane_transformation,
             status: authored_pilot,
             generated: false,
             grade: 8,
             cluster: g8_plane_transformations,
             doings: [ map_figure_through_transformation,
                       dilate_by_adding_a_constant ],
             transformations: [dilation, translation, rotation, reflection],
             verification: [defining_relation_on_exact_squared_distances,
                            scene_renders_through_the_coordinate_plane_grapher],
             arithmetic: exact_rational,
             renderer: 'hermes/web/coordinate-plane/grapher.js (schema version 1)',
             deformation_draws_too: true,
             rotation_support: quarter_turns_only,
             imported_by: none,
             reverses: 'the round-two verdict that this cluster is inherently visual' }).

% ==========================================================================
% 6. RECEIPTS
% ==========================================================================

g8_transformation_receipt(
    'im_defrag_478d4d9911d24fc5a761ad13_1', 'IM-G8-U2-L9',
    % Triangle A with sides 2, 3, 4 is not similar to Triangle B with 4, 5,
    % 6; a dilation by 2 from the origin sends A's legs to 4 and 6, so the
    % image is the figure B would have to be.
    map_figure_through_transformation,
    _{kind: "plane_transformation", transformation: "dilation",
      figure: _{name: "Triangle A",
                vertices: [_{label: "P", x: 0, y: 0},
                           _{label: "Q", x: 2, y: 0},
                           _{label: "R", x: 0, y: 3}]},
      center: _{x: 0, y: 0}, scale_factor: 2},
    image("Triangle A image", ["P(0, 0)", "Q(4, 0)", "R(0, 6)"]),
    printed_factor_witness_placement).
g8_transformation_receipt(
    'im_defrag_7e9cb3185d65b294f0f028ce_1', 'IM-G8-U2-L12',
    % A dilation with scale factor 2 sends A to B.
    map_figure_through_transformation,
    _{kind: "plane_transformation", transformation: "dilation",
      figure: _{name: "Segment A",
                vertices: [_{label: "A", x: 1, y: 1},
                           _{label: "B", x: 3, y: 2}]},
      center: _{x: 0, y: 0}, scale_factor: 2},
    image("Segment A image", ["A(2, 2)", "B(6, 4)"]),
    printed_factor_witness_placement).
g8_transformation_receipt(
    'im_defrag_ccd5498a75daff77ea8539a5_1', 'IM-G8-U1-L3',
    map_figure_through_transformation,
    _{kind: "plane_transformation", transformation: "translation",
      figure: _{name: "Figure A",
                vertices: [_{label: "P", x: 1, y: 2},
                           _{label: "Q", x: 4, y: 2},
                           _{label: "R", x: 4, y: 5}]},
      vector: _{x: -3, y: 1}},
    image("Figure A image", ["P(-2, 3)", "Q(1, 3)", "R(1, 6)"]),
    witness_placement).
g8_transformation_receipt(
    'im_defrag_ecd05676adf7d67d0c21a5ba_1', 'IM-G8-U1-L2',
    map_figure_through_transformation,
    _{kind: "plane_transformation", transformation: "rotation",
      figure: _{name: "Figure B",
                vertices: [_{label: "P", x: 2, y: 1},
                           _{label: "Q", x: 5, y: 1},
                           _{label: "R", x: 5, y: 3}]},
      center: _{x: 0, y: 0}, degrees: 90},
    image("Figure B image", ["P(-1, 2)", "Q(-1, 5)", "R(-3, 5)"]),
    witness_placement).
g8_transformation_receipt(
    'im_defrag_fdecbab05ecd27849af654b4_1', 'IM-G8-U1-L11',
    map_figure_through_transformation,
    _{kind: "plane_transformation", transformation: "reflection",
      figure: _{name: "Left hand",
                vertices: [_{label: "P", x: 1, y: 1},
                           _{label: "Q", x: 4, y: 2},
                           _{label: "R", x: 2, y: 5}]},
      line: _{axis: "y"}},
    image("Left hand image", ["P(-1, 1)", "Q(-4, 2)", "R(-2, 5)"]),
    witness_placement).

% Final round: the widened vision fold-in supplied the figures' own
% coordinates. These receipts carry them, so their provenance is
% `recovered_figure` rather than a witness placement.
g8_transformation_receipt(
    'im_defrag_f28f98c13fc13f0a85b409b8_1', 'IM-G8-U2-L4',
    map_figure_through_transformation,
    _{kind: "plane_transformation", transformation: "dilation",
      figure: _{name: "Triangle QRS",
                vertices: [_{label: "Q", x: 6, y: 6},
                           _{label: "R", x: 6, y: 5},
                           _{label: "S", x: 5, y: 3}]},
      center: _{x: 3, y: 4}, scale_factor: 2},
    image("Triangle QRS image", ["Q(9, 8)", "R(9, 6)", "S(7, 2)"]),
    recovered_figure).
g8_transformation_receipt(
    'im_defrag_f85585fdc607bf5be02d2c70_1', 'IM-G8-U1-L5',
    map_figure_through_transformation,
    _{kind: "plane_transformation", transformation: "rotation",
      figure: _{name: "Segment AB",
                vertices: [_{label: "A", x: 0, y: 3},
                           _{label: "B", x: 4, y: 2}]},
      center: _{x: 0, y: 0}, degrees: 90},
    image("Segment AB image", ["A(-3, 0)", "B(-2, 4)"]),
    recovered_figure).
g8_transformation_receipt(
    'im_defrag_25fcddc4761f571ef533efdb_1', 'IM-G8-U1-L5',
    map_figure_through_transformation,
    _{kind: "plane_transformation", transformation: "reflection",
      figure: _{name: "Points O and R",
                vertices: [_{label: "O", x: 0, y: 0},
                           _{label: "R", x: 3, y: 2}]},
      line: _{axis: "x"}},
    image("Points O and R image", ["O(0, 0)", "R(3, -2)"]),
    recovered_figure).

% ==========================================================================
% 7. CHECK
% ==========================================================================

check_g8_plane_transformation :-
    check_receipts,
    check_scenes_render,
    check_attested_deformation_draws_too,
    check_negative,
    format('g8_plane_transformation: all checks ok~n').

check_receipts :-
    findall(Lesson-Row-Result,
            ( g8_transformation_receipt(Row, Lesson, Doing, Json, Expected, _),
              g8_transformation_from_json(Json, Figure),
              run_g8_transformation(Doing, Figure, Outcome, _),
              outcome_property(Outcome, result(Result)),
              Result = Expected,
              outcome_property(Outcome, validity(correct)),
              outcome_property(Outcome, defining_relation(_, holds))
            ), Rows),
    findall(R-L, g8_transformation_receipt(R, L, _, _, _, _), All),
    length(All, Total), length(Rows, Passed),
    Total =:= Passed,
    format('  receipts: ~w/~w figures mapped, each defining relation holding on exact squared distances~n',
           [Passed, Total]),
    forall(member(Lesson-Row-Result, Rows),
           format('    ~w  ~w  ~q~n', [Lesson, Row, Result])).

check_scenes_render :-
    % Every receipt's scene is written out and handed to the coordinate-plane
    % grapher. A spec the renderer rejects is a failed check, not a warning.
    findall(JSON,
            ( g8_transformation_receipt(_, _, Doing, Json, _, _),
              g8_transformation_from_json(Json, Figure),
              run_g8_transformation(Doing, Figure, Outcome, _),
              g8_transformation_scene(Outcome, JSON)
            ), Scenes),
    length(Scenes, Count),
    render_all(Scenes),
    format('  drawings: ~w scenes rendered through hermes/web/coordinate-plane without error~n',
           [Count]).

render_all(Scenes) :-
    setup_call_cleanup(
        tmp_file_stream(text, File, Stream),
        ( forall(member(S, Scenes), ( write(Stream, S), nl(Stream) )),
          close(Stream),
          render_through_grapher(File)
        ),
        catch(delete_file(File), _, true)).

render_through_grapher(File) :-
    Script = 'const fs=require("fs");const g=require("./hermes/web/coordinate-plane/grapher.js");\c
let n=0;for(const line of fs.readFileSync(process.argv[1],"utf8").split("\\n")){\c
if(!line.trim())continue;const spec=JSON.parse(line);g.validateSpec(spec);\c
const svg=g.renderSpec(spec);if(!svg||svg.indexOf("<svg")!==0)throw new Error("no svg");n++;}\c
console.log("rendered "+n);',
    process_create(path(node), ['-e', Script, File],
                   [stdout(pipe(Out)), stderr(pipe(Err)), process(PID)]),
    read_string(Out, _, Stdout), read_string(Err, _, Stderr),
    process_wait(PID, Status),
    (   Status == exit(0)
    ->  true
    ;   throw(error(grapher_rejected_scene(Stdout, Stderr), _))
    ).

check_attested_deformation_draws_too :-
    % db_row 38669: enlarging by adding a constant rather than multiplying.
    % The wrong reading gets a drawing of its own, so a teacher can put the
    % student's thinking beside the dilation.
    g8_transformation_from_json(
        _{kind: "plane_transformation", transformation: "dilation",
          figure: _{name: "Rectangle",
                    vertices: [_{label: "P", x: 0, y: 0},
                               _{label: "Q", x: 2, y: 0},
                               _{label: "R", x: 2, y: 3},
                               _{label: "S", x: 0, y: 3}]},
          center: _{x: 0, y: 0}, scale_factor: 3}, F),
    run_g8_transformation(dilate_by_adding_a_constant, F, O, _),
    outcome_property(O, result(image(_, ["P(2, 2)", "Q(4, 2)", "R(4, 5)",
                                         "S(2, 5)"]))),
    outcome_property(O, expected(image(_, ["P(0, 0)", "Q(6, 0)", "R(6, 9)",
                                           "S(0, 9)"]))),
    outcome_property(O, defining_relation(_, fails)),
    outcome_property(O, validity(incorrect)),
    g8_transformation_scene(O, JSON),
    render_all([JSON]),
    format('  the deformation draws too: db_row 38669 adds 2 to every coordinate where the dilation multiplies by 3, and its scene renders~n').

check_negative :-
    % A rotation that is not a quarter turn refuses at decode rather than
    % reaching for a trigonometric approximation.
    \+ g8_transformation_from_json(
           _{kind: "plane_transformation", transformation: "rotation",
             figure: _{vertices: [_{x: 1, y: 0}, _{x: 2, y: 0}]},
             center: _{x: 0, y: 0}, degrees: 45}, _),
    % A scale factor of zero collapses the figure and refuses.
    \+ g8_transformation_from_json(
           _{kind: "plane_transformation", transformation: "dilation",
             figure: _{vertices: [_{x: 1, y: 0}, _{x: 2, y: 0}]},
             center: _{x: 0, y: 0}, scale_factor: 0}, _),
    % Four quarter turns return the figure to itself, exactly.
    g8_transformation_from_json(
        _{kind: "plane_transformation", transformation: "rotation",
          figure: _{name: "F", vertices: [_{label: "A", x: 3, y: 5},
                                          _{label: "B", x: 1, y: 2}]},
          center: _{x: 2, y: 2}, degrees: 360}, R),
    run_g8_transformation(map_figure_through_transformation, R, O, _),
    outcome_property(O, result(image(_, ["A(3, 5)", "B(1, 2)"]))),
    % A reflection over the wrong axis fails the mirror relation for the
    % intended one, so the check discriminates rather than accepting both.
    g8_transformation_from_json(
        _{kind: "plane_transformation", transformation: "reflection",
          figure: _{name: "G", vertices: [_{label: "A", x: 2, y: 3},
                                          _{label: "B", x: 5, y: 1}]},
          line: _{axis: "x"}}, X),
    run_g8_transformation(map_figure_through_transformation, X, OX, _),
    outcome_property(OX, image_vertices(Reflected)),
    \+ defining_relation(reflection(vertical_axis),
                         [vertex("A", 2, 3), vertex("B", 5, 1)],
                         Reflected, holds, _),
    format('  negative tests: a 45 degree rotation and a zero scale factor refuse; four quarter turns return the figure exactly; the mirror relation separates the two axes~n').

outcome_property(action_outcome(_, Props), Property) :-
    memberchk(Property, Props).
