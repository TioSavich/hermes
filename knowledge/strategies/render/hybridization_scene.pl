/** <module> Canonical hybridization scene compiler
 *
 * A hybridized model is a transplant deformation: a primitive licensed in one
 * visual language is moved onto an illicit host. This compiler renders that
 * relation as a temporal proof object, not as an untyped picture.
 */

:- module(hybridization_scene,
          [ hybridization_render_frames/2,   % +Spec, -Frames
            hybridization_render_json/2,     % +Spec, -Dict
            hybridization_render_to_file/2   % +Spec, +Path
          ]).

:- use_module(library(http/json), [json_write_dict/3]).

%!  hybridization_render_frames(+Spec, -Frames) is det.
%
%   Known transplant cases emit the canonical four frames:
%   host, licensed home, transplant, resulting hybrid. Unknown specs emit a
%   single annotation-only frame so the worker never invents geometry.
hybridization_render_frames(Spec, Frames) :-
    ( hybridization_frames(Spec, Frames0)
    -> Frames = Frames0
    ;  unknown_frame(Spec, Frame),
       Frames = [Frame]
    ).

hybridization_frames(Spec, [F1, F2, F3, F4]) :-
    hybridization_case(
        Spec,
        ForeignPrimitive,
        LicensedHome,
        IllicitHost,
        HostSpec,
        HomeSpec,
        LicensedPartitionSpec,
        DeformedPartitionSpec
    ),
    primitive_for_spec(HostSpec, Host),
    primitive_for_spec(HomeSpec, Home),
    primitive_for_spec(LicensedPartitionSpec, HomePartition),
    primitive_for_spec(DeformedPartitionSpec, BadPartition),
    host_caption(IllicitHost, HostCaption),
    licensed_caption(ForeignPrimitive, LicensedHome, LicensedCaption),
    transplant_caption(ForeignPrimitive, IllicitHost, TransplantCaption),
    make_frame(
        1,
        host_shape(IllicitHost),
        HostCaption,
        true,
        [Host],
        F1
    ),
    make_frame(
        2,
        licensed_home(ForeignPrimitive, LicensedHome),
        LicensedCaption,
        true,
        [Home, HomePartition],
        F2
    ),
    make_frame(
        3,
        transplant(ForeignPrimitive, IllicitHost),
        TransplantCaption,
        true,
        [Host, BadPartition],
        F3
    ),
    make_frame(
        4,
        hybrid_result(Spec),
        "The result is a hybridized model: a foreign primitive on an illicit host.",
        true,
        [Host, BadPartition],
        F4
    ).

hybridization_case(
        circle_partition_on_rectangle,
        circle_radial_partition,
        circle_region,
        rectangle_area_model,
        shape(rectangle, host, whole, "rectangle host"),
        shape(circle, home, whole, "circle home"),
        radial_partition(circle, iterated, "licensed radial partition"),
        radial_partition(rectangle, deformation, "radial partition on rectangle")).
hybridization_case(
        vertical_partition_on_circle,
        rectangle_vertical_partition,
        rectangle_area_model,
        circle_region,
        shape(circle, host, whole, "circle host"),
        shape(rectangle, home, whole, "rectangle home"),
        vertical_partition(rectangle, iterated, "licensed vertical partition"),
        vertical_partition(circle, deformation, "vertical partition on circle")).
hybridization_case(
        radial_partition_on_set,
        circle_radial_partition,
        circle_region,
        fractional_set_model,
        shape(set, host, whole, "set host"),
        shape(circle, home, whole, "circle home"),
        radial_partition(circle, iterated, "licensed radial partition"),
        radial_partition(set, deformation, "radial partition on set")).
hybridization_case(
        parallel_partition_on_triangle,
        rectangle_parallel_partition,
        rectangle_area_model,
        triangle_region,
        shape(triangle, host, whole, "triangle host"),
        shape(rectangle, home, whole, "rectangle home"),
        parallel_partition(rectangle, iterated, "licensed parallel partition"),
        parallel_partition(triangle, deformation, "parallel bands on triangle")).

case_metadata(Spec, Metadata) :-
    case_metadata_from_spec(Spec, Metadata).

case_metadata_from_spec(Spec, Metadata) :-
    hybridization_case(Spec, ForeignPrimitive, LicensedHome, IllicitHost, _, _, _, _),
    atom_string(ForeignPrimitive, ForeignText),
    atom_string(LicensedHome, LicensedHomeText),
    atom_string(IllicitHost, IllicitHostText),
    Metadata = _{ family: "transplant_deformation",
                  foreignPrimitive: ForeignText,
                  licensedHome: LicensedHomeText,
                  illicitHost: IllicitHostText,
                  violation: "object_language_binding_violation" }.

host_rect(Role, Label, Primitive) :-
    role_atom(Role, RoleAtom),
    Primitive = _{ kind: "host-rect",
                   x: 110, y: 86, w: 300, h: 190,
                   role: RoleAtom,
                   label: Label }.

home_rect(Role, Label, Primitive) :-
    role_atom(Role, RoleAtom),
    Primitive = _{ kind: "home-rect",
                   x: 110, y: 86, w: 300, h: 190,
                   role: RoleAtom,
                   label: Label }.

host_circle(Role, Label, Primitive) :-
    role_atom(Role, RoleAtom),
    Primitive = _{ kind: "host-circle",
                   cx: 260, cy: 181, r: 94,
                   role: RoleAtom,
                   label: Label }.

home_circle(Role, Label, Primitive) :-
    role_atom(Role, RoleAtom),
    Primitive = _{ kind: "home-circle",
                   cx: 260, cy: 181, r: 94,
                   role: RoleAtom,
                   label: Label }.

set_host(Role, Label, Primitive) :-
    role_atom(Role, RoleAtom),
    Primitive = _{ kind: "set-host",
                   x: 160, y: 132, count: 3, r: 34,
                   role: RoleAtom,
                   label: Label }.

triangle_host(Role, Label, Primitive) :-
    role_atom(Role, RoleAtom),
    Primitive = _{ kind: "triangle-host",
                   x: 160, y: 76, w: 210, h: 188,
                   role: RoleAtom,
                   label: Label }.

radial_partition(circle, Role, Label, Primitive) :-
    role_atom(Role, RoleAtom),
    Primitive = _{ kind: "radial-partition",
                   host: "circle",
                   cx: 260, cy: 181, r: 94,
                   segments: 6,
                   role: RoleAtom,
                   label: Label }.
radial_partition(rectangle, Role, Label, Primitive) :-
    role_atom(Role, RoleAtom),
    Primitive = _{ kind: "radial-partition",
                   host: "rectangle",
                   cx: 260, cy: 181, r: 110,
                   hostX: 110, hostY: 86, hostW: 300, hostH: 190,
                   segments: 6,
                   role: RoleAtom,
                   label: Label }.
radial_partition(set, Role, Label, Primitive) :-
    role_atom(Role, RoleAtom),
    Primitive = _{ kind: "radial-partition",
                   host: "set",
                   x: 160, y: 132, count: 3, r: 34,
                   segments: 3,
                   shade: [1, 2],
                   role: RoleAtom,
                   label: Label }.

vertical_partition(rectangle, Role, Label, Primitive) :-
    role_atom(Role, RoleAtom),
    Primitive = _{ kind: "vertical-partition",
                   host: "rectangle",
                   x: 110, y: 86, w: 300, h: 190,
                   columns: 3,
                   shade: [2],
                   role: RoleAtom,
                   label: Label }.
vertical_partition(circle, Role, Label, Primitive) :-
    role_atom(Role, RoleAtom),
    Primitive = _{ kind: "vertical-partition",
                   host: "circle",
                   cx: 260, cy: 181, r: 94,
                   columns: 3,
                   shade: [2],
                   role: RoleAtom,
                   label: Label }.

parallel_partition(rectangle, Role, Label, Primitive) :-
    role_atom(Role, RoleAtom),
    Primitive = _{ kind: "parallel-partition",
                   host: "rectangle",
                   x: 110, y: 86, w: 300, h: 190,
                   bands: 3,
                   shade: [2, 3],
                   role: RoleAtom,
                   label: Label }.
parallel_partition(triangle, Role, Label, Primitive) :-
    role_atom(Role, RoleAtom),
    Primitive = _{ kind: "parallel-partition",
                   host: "triangle",
                   x: 160, y: 76, w: 210, h: 188,
                   bands: 3,
                   shade: [2, 3],
                   role: RoleAtom,
                   label: Label }.

primitive_for_spec(shape(rectangle, host, Role, Label), Primitive) :-
    host_rect(Role, Label, Primitive).
primitive_for_spec(shape(rectangle, home, Role, Label), Primitive) :-
    home_rect(Role, Label, Primitive).
primitive_for_spec(shape(circle, host, Role, Label), Primitive) :-
    host_circle(Role, Label, Primitive).
primitive_for_spec(shape(circle, home, Role, Label), Primitive) :-
    home_circle(Role, Label, Primitive).
primitive_for_spec(shape(set, host, Role, Label), Primitive) :-
    set_host(Role, Label, Primitive).
primitive_for_spec(shape(triangle, host, Role, Label), Primitive) :-
    triangle_host(Role, Label, Primitive).
primitive_for_spec(radial_partition(Host, Role, Label), Primitive) :-
    radial_partition(Host, Role, Label, Primitive).
primitive_for_spec(vertical_partition(Host, Role, Label), Primitive) :-
    vertical_partition(Host, Role, Label, Primitive).
primitive_for_spec(parallel_partition(Host, Role, Label), Primitive) :-
    parallel_partition(Host, Role, Label, Primitive).

host_caption(rectangle_area_model, "Choose a rectangle as the area-model host.") :- !.
host_caption(circle_region, "Choose a circle as the region host.") :- !.
host_caption(fractional_set_model, "Choose a collection as one fractional set host.") :- !.
host_caption(triangle_region, "Choose a triangle as the region host.") :- !.
host_caption(Host, Caption) :-
    format(string(Caption), "Choose ~w as the host.", [Host]).

licensed_caption(circle_radial_partition, circle_region,
                 "The radial partition is licensed inside the circle-region vocabulary.") :- !.
licensed_caption(rectangle_vertical_partition, rectangle_area_model,
                 "The vertical partition is licensed inside the rectangle area-model vocabulary.") :- !.
licensed_caption(rectangle_parallel_partition, rectangle_area_model,
                 "The parallel band partition is licensed inside the rectangle area-model vocabulary.") :- !.
licensed_caption(Primitive, Home, Caption) :-
    format(string(Caption), "The ~w primitive is licensed in ~w.", [Primitive, Home]).

transplant_caption(circle_radial_partition, rectangle_area_model,
                   "Transplant the circle partition rule onto the rectangle host.") :- !.
transplant_caption(circle_radial_partition, fractional_set_model,
                   "Transplant the circle's radial partition rule onto each element of the set host.") :- !.
transplant_caption(rectangle_vertical_partition, circle_region,
                   "Transplant the rectangle's vertical partition rule onto the circular host.") :- !.
transplant_caption(rectangle_parallel_partition, triangle_region,
                   "Transplant the rectangle's parallel partition rule onto the triangular host.") :- !.
transplant_caption(Primitive, Host, Caption) :-
    format(string(Caption), "Transplant ~w onto ~w.", [Primitive, Host]).

make_frame(Step, Verb, Caption, Changed, Primitives, Frame) :-
    term_to_text(Verb, VerbText),
    Scene = _{ format: "hybridization-model",
               version: 1,
               primitives: Primitives },
    Frame = _{ step: Step,
               verb: VerbText,
               caption: Caption,
               sceneChanged: Changed,
               scene: Scene }.

unknown_frame(Spec, Frame) :-
    term_to_text(Spec, SpecText),
    format(string(Caption), "No hybridization layout for ~w.", [SpecText]),
    Scene = _{ format: "hybridization-model",
               version: 1,
               primitives: [] },
    Frame = _{ step: 1,
               verb: SpecText,
               caption: Caption,
               sceneChanged: false,
               scene: Scene }.

%!  hybridization_render_json(+Spec, -Dict) is det.
hybridization_render_json(Spec, Dict) :-
    hybridization_render_frames(Spec, Frames),
    spec_kind(Spec, Kind),
    ( case_metadata(Spec, Metadata)
    -> Dict0 = Metadata
    ;  Metadata = _{},
       Dict0 = Metadata.put(_{ family: "unregistered_hybridization",
                               foreignPrimitive: "",
                               licensedHome: "",
                               illicitHost: "",
                               violation: "" })
    ),
    Dict = Dict0.put(_{ kind: Kind,
                        request: _{ spec: Kind },
                        result: "misconception",
                        canvas: _{ width: 760, height: 420 },
                        frames: Frames,
                        tuple: "hybridization(foreign_primitive, licensed_home, illicit_host)" }).

hybridization_render_to_file(Spec, Path) :-
    hybridization_render_json(Spec, Dict),
    setup_call_cleanup(
        open(Path, write, Stream, [encoding(utf8)]),
        json_write_dict(Stream, Dict, [width(80)]),
        close(Stream)
    ).

spec_kind(Spec, Kind) :-
    ( atom(Spec)
    -> atom_string(Spec, Kind)
    ;  term_to_text(Spec, Kind)
    ).

role_atom(Role, Role) :-
    atom(Role),
    !.
role_atom(Role, Atom) :-
    atom_string(Atom, Role).

term_to_text(Term, Text) :-
    ( string(Term)
    -> Text = Term
    ;  format(string(Text), "~w", [Term])
    ).
