/** <module> Parametric partition-rule transplant deformations
 *
 * The headline family. A documented student-work error — a child botches the
 * circle model of 1/4 by partitioning it with a rectangle's vertical-strip rule,
 * so the pieces come out unequal — is GENERALISED here into a function of the
 * fraction. The same transplant that botches 1/4 generates the botched model for
 * 1/5, 1/6, 1/8, and so on. The deformation is a rule, not a fixed picture.
 *
 * Three layers, all read-only over the grammar and the drawer contract:
 *
 *   1. productive_partition_scene(Host, N, FramesDict)
 *      The CORRECT unit-fraction 1/N model in the host's own licensed partition
 *      rule: a circle gets its radial partition, a rectangle/bar its vertical
 *      partition, an area host its grid. B/M/E frames with named verbs
 *      (establish_whole -> apply_partition -> shade_unit_part).
 *
 *   2. deformed_partition_scene(Host, N, transplant(ForeignRule), FramesDict)
 *      A foreign partition rule applied to the host, parametric over N. The
 *      vertical-strip rule on a circle, the radial rule on a rectangle, the grid
 *      rule on a circle, the radial rule on a set. role:deformation throughout,
 *      so the drawer dashes the foreign cut lines. This is the wrong-thing lane:
 *      a deformation is only ever a labeled misconception, never an unlabeled
 *      productive diagram.
 *
 *   3. replicate_deformation(Host, transplant(Rule), ListOfN, FramesList)
 *      The replication win: the SAME deformation across several fractions. The
 *      frame specs differ only in the segment/column/band count.
 *
 * deformation_evidence/2 grounds each transplant family in the three real
 * attested transplants in attested_deformations.pl. The frame dicts serialise
 * to drawer-compatible JSON via json_write_dict/3; the drawer's
 * 'hybridization-model' format already reads segments/columns/bands and dashes
 * a role:deformation partition.
 *
 * GROUNDING vs RENDER separation is preserved: the logic here decides what the
 * deformation IS and which fraction it is a function of; the drawer projects it.
 * This file does not edit representation_grammar.pl or drawer.js.
 *
 * Loaded through paths.pl (render-strategies search path).
 */

:- module(parametric_partition_deformation,
          [ productive_partition_scene/3,        % +Host, +N, -FramesDict
            deformed_partition_scene/4,          % +Host, +N, +Transplant, -FramesDict
            deformation_evidence/2,              % +Transplant, -Bibkeys
            replicate_deformation/4,             % +Host, +Transplant, +ListOfN, -FramesList
            partition_host/1,                    % ?Host
            attested_transplant_pair/2,          % ?Host, ?Transplant
            partition_scene_to_file/2,           % +FramesDict, +Path
            replication_to_file/2                % +FramesList, +Path
          ]).

:- use_module(library(http/json), [json_write_dict/3]).
:- use_module(library(lists), [member/2]).

% --- Canvas geometry (shared with hybridization_scene.pl so the frames sit in
% the same coordinate frame the drawer already lays out). ---------------------

canvas_dict(_{ width: 760, height: 420 }).

circle_geom(cx, 260).
circle_geom(cy, 181).
circle_geom(r, 94).

rect_geom(x, 110).
rect_geom(y, 86).
rect_geom(w, 300).
rect_geom(h, 190).

% --- Hosts and their licensed partition rule ---------------------------------
%
% partition_host(Host): the hosts this layer can establish as a whole.
% host_licensed_rule(Host, Rule): the partition rule LICENSED inside that host's
% own visual vocabulary (the productive one). A transplant is any other rule.

partition_host(circle).
partition_host(rectangle).
partition_host(bar).
partition_host(area).
partition_host(set).

host_licensed_rule(circle, radial).
host_licensed_rule(rectangle, vertical).
host_licensed_rule(bar, vertical).
host_licensed_rule(area, grid).
host_licensed_rule(set, set_radial).

% --- Drawer primitive kind for each (host, rule, N) --------------------------
%
% partition_primitive(Host, Rule, N, Role, Primitive): the drawer primitive that
% draws the Rule's partition on Host, cut into N pieces, with the given Role.
% Role is iterated for a licensed (productive) partition and deformation for a
% transplant; the drawer dashes a deformation partition.
%
% The count parameter (segments / columns / bands) IS the fraction's
% denominator N. This is the parametricity the task asks for: change N, and only
% the count field changes.

% Radial partition (N sectors). Licensed on a circle; a transplant on a
% rectangle (host: "rectangle" carries the host box so the drawer clips the rays
% to the rectangle edges, which is exactly why the sectors come out unequal).
partition_primitive(circle, radial, N, Role, P) :-
    circle_geom(cx, CX), circle_geom(cy, CY), circle_geom(r, R),
    P = _{ kind: "radial-partition",
           host: "circle",
           cx: CX, cy: CY, r: R,
           segments: N,
           role: Role,
           label: "" }.
partition_primitive(rectangle, radial, N, Role, P) :-
    circle_geom(cx, CX), circle_geom(cy, CY),
    rect_geom(x, RX), rect_geom(y, RY), rect_geom(w, RW), rect_geom(h, RH),
    P = _{ kind: "radial-partition",
           host: "rectangle",
           cx: CX, cy: CY, r: 110,
           hostX: RX, hostY: RY, hostW: RW, hostH: RH,
           segments: N,
           role: Role,
           label: "" }.

% Vertical partition (N columns). Licensed on a rectangle/bar; a transplant on a
% circle (host: "circle" makes the drawer cut N equal-width vertical strips
% across the disc — unequal-area pieces, the documented 1/4-on-circle error).
partition_primitive(rectangle, vertical, N, Role, P) :-
    rect_geom(x, X), rect_geom(y, Y), rect_geom(w, W), rect_geom(h, H),
    P = _{ kind: "vertical-partition",
           host: "rectangle",
           x: X, y: Y, w: W, h: H,
           columns: N,
           shade: [1],
           role: Role,
           label: "" }.
partition_primitive(bar, vertical, N, Role, P) :-
    partition_primitive(rectangle, vertical, N, Role, P).
partition_primitive(circle, vertical, N, Role, P) :-
    circle_geom(cx, CX), circle_geom(cy, CY), circle_geom(r, R),
    P = _{ kind: "vertical-partition",
           host: "circle",
           cx: CX, cy: CY, r: R,
           columns: N,
           shade: [1],
           role: Role,
           label: "" }.

% Grid partition (an N x 1 area grid). Licensed on an area host. A grid rule on a
% circle reuses the vertical-partition primitive on the circle host (the drawer's
% closest grid analogue for a disc), which is how the attested
% rectangle_grid_partition-on-circle case (Cadez 2018) reads.
partition_primitive(area, grid, N, Role, P) :-
    rect_geom(x, X), rect_geom(y, Y), rect_geom(w, W), rect_geom(h, H),
    P = _{ kind: "vertical-partition",
           host: "rectangle",
           x: X, y: Y, w: W, h: H,
           columns: N,
           shade: [1],
           role: Role,
           label: "" }.
partition_primitive(circle, grid, N, Role, P) :-
    circle_geom(cx, CX), circle_geom(cy, CY), circle_geom(r, R),
    P = _{ kind: "vertical-partition",
           host: "circle",
           cx: CX, cy: CY, r: R,
           columns: N,
           shade: [1],
           role: Role,
           label: "" }.

% Radial partition on the elements of a set (the radial-on-set transplant). N
% sectors carved into each of the set's circular elements.
partition_primitive(set, set_radial, N, Role, P) :-
    P = _{ kind: "radial-partition",
           host: "set",
           x: 160, y: 132, count: 3, r: 34,
           segments: N,
           shade: [1],
           role: Role,
           label: "" }.
partition_primitive(set, radial, N, Role, P) :-
    partition_primitive(set, set_radial, N, Role, P).

% --- Host whole primitives (frame 1: establish_whole) ------------------------

host_whole(circle, P) :-
    circle_geom(cx, CX), circle_geom(cy, CY), circle_geom(r, R),
    P = _{ kind: "host-circle", cx: CX, cy: CY, r: R,
           role: "whole", label: "one whole" }.
host_whole(rectangle, P) :-
    rect_geom(x, X), rect_geom(y, Y), rect_geom(w, W), rect_geom(h, H),
    P = _{ kind: "host-rect", x: X, y: Y, w: W, h: H,
           role: "whole", label: "one whole" }.
host_whole(bar, P) :-
    host_whole(rectangle, P).
host_whole(area, P) :-
    host_whole(rectangle, P).
host_whole(set, P) :-
    P = _{ kind: "set-host", x: 160, y: 132, count: 3, r: 34,
           role: "whole", label: "one whole (a set)" }.

% --- Productive (licensed) 1/N scene -----------------------------------------
%
% productive_partition_scene(Host, N, FramesDict): the CORRECT unit-fraction 1/N
% model, three B/M/E frames in the host's own licensed partition rule.

productive_partition_scene(Host, N, Dict) :-
    partition_host(Host),
    integer(N), N >= 2,
    host_licensed_rule(Host, Rule),
    host_whole(Host, Whole),
    partition_primitive(Host, Rule, N, "iterated", Part0),
    Part = Part0.put(_{ label: "" }),
    rule_phrase(Rule, RulePhrase),
    format(string(C1), "Establish one whole as a ~w.", [Host]),
    format(string(C2), "Apply the ~w's own ~w into ~w equal parts.",
           [Host, RulePhrase, N]),
    format(string(C3), "Shade one part: this is 1/~w.", [N]),
    make_frame(1, establish_whole(Host), C1, [Whole], F1),
    make_frame(2, apply_partition(Rule, N), C2, [Whole, Part], F2),
    make_frame(3, shade_unit_part(N), C3, [Whole, Part], F3),
    format(string(Kind), "productive_~w_1_over_~w", [Host, N]),
    format(string(Tuple), "productive_partition(~w, unit_fraction(1,~w))", [Host, N]),
    scene_dict(Kind, Tuple, "productive", [F1, F2, F3],
               _{ host: Host, denominator: N, rule: Rule, mode: productive },
               Dict).

% --- Deformed (transplant) 1/N scene -----------------------------------------
%
% deformed_partition_scene(Host, N, transplant(ForeignRule), FramesDict): the
% foreign partition rule applied to the host, parametric over N. The frames are
% the four canonical transplant frames: host, licensed home of the foreign rule,
% the transplant onto the host, the hybrid result. Every frame carrying the
% foreign partition marks it role:deformation, so it is a LABELED misconception,
% never an unlabeled productive diagram.

deformed_partition_scene(Host, N, transplant(ForeignRule), Dict) :-
    partition_host(Host),
    integer(N), N >= 2,
    foreign_rule(ForeignRule),
    \+ host_licensed_rule(Host, ForeignRule),
    rule_home(ForeignRule, HomeHost),
    host_whole(Host, HostWhole),
    host_whole(HomeHost, HomeWhole),
    partition_primitive(HomeHost, ForeignRule, N, "iterated", LicensedPart),
    partition_primitive(Host, ForeignRule, N, "deformation", BadPart),
    rule_phrase(ForeignRule, ForeignPhrase),
    format(string(C1), "Choose a ~w as the host.", [Host]),
    format(string(C2), "The ~w is licensed inside the ~w's own vocabulary.",
           [ForeignPhrase, HomeHost]),
    format(string(C3),
           "Transplant the ~w onto the ~w, cut into ~w: the pieces are unequal.",
           [ForeignPhrase, Host, N]),
    format(string(C4),
           "Hybridized model of 1/~w: a foreign partition rule on an illicit host.",
           [N]),
    make_frame(1, establish_whole(Host), C1, [HostWhole], F1),
    make_frame(2, licensed_home(ForeignRule, HomeHost), C2,
               [HomeWhole, LicensedPart], F2),
    make_frame(3, apply_foreign_partition(ForeignRule, Host, N), C3,
               [HostWhole, BadPart], F3),
    make_frame(4, hybrid_result(transplant(ForeignRule, Host), N), C4,
               [HostWhole, BadPart], F4),
    rule_to_foreign_primitive(ForeignRule, ForeignPrimitive),
    host_to_illicit(Host, IllicitHost),
    rule_home_token(ForeignRule, LicensedHomeToken),
    format(string(Kind), "transplant_~w_on_~w_1_over_~w", [ForeignRule, Host, N]),
    format(string(Tuple),
           "hybridization(~w, ~w, ~w) at unit_fraction(1,~w)",
           [ForeignPrimitive, LicensedHomeToken, IllicitHost, N]),
    scene_dict(Kind, Tuple, "misconception", [F1, F2, F3, F4],
               _{ host: Host, denominator: N, foreignRule: ForeignRule,
                  family: transplant_deformation,
                  foreignPrimitive: ForeignPrimitive,
                  licensedHome: LicensedHomeToken,
                  illicitHost: IllicitHost,
                  violation: object_language_binding_violation,
                  mode: misconception },
               Dict).

foreign_rule(radial).
foreign_rule(vertical).
foreign_rule(grid).

rule_home(radial, circle).
rule_home(vertical, rectangle).
rule_home(grid, area).

rule_phrase(radial, "radial partition rule") :- !.
rule_phrase(vertical, "vertical-strip partition rule") :- !.
rule_phrase(grid, "rectangular grid partition rule") :- !.
rule_phrase(set_radial, "radial partition rule") :- !.
rule_phrase(R, P) :- format(string(P), "~w partition rule", [R]).

rule_to_foreign_primitive(radial, circle_radial_partition).
rule_to_foreign_primitive(vertical, rectangle_vertical_partition).
rule_to_foreign_primitive(grid, rectangle_grid_partition).
rule_to_foreign_primitive(set_radial, circle_radial_partition).

rule_home_token(radial, circle_region).
rule_home_token(vertical, rectangle_area_model).
rule_home_token(grid, rectangle_area_model).
rule_home_token(set_radial, circle_region).

host_to_illicit(circle, circle_region).
host_to_illicit(rectangle, rectangle_area_model).
host_to_illicit(bar, rectangle_area_model).
host_to_illicit(area, rectangle_area_model).
host_to_illicit(set, fractional_set_model).

% --- Evidence: ground each transplant family in the attested corpus ----------
%
% deformation_evidence(transplant(ForeignRule, Host), Bibkeys): the bibkeys of
% the real attested transplants in attested_deformations.pl that this parametric
% family generalises. The three real transplants are:
%   rectangle_grid_partition  on circle_region     (Cadez 2018)   -> grid/circle
%   circle_radial_partition   on rectangle_area     (Zhang 2015)   -> radial/rect
%   circle_radial_partition   on submarine sandwich (Garderen 2014)-> radial/set-ish
% The vertical-rule-on-circle family is the canonical demonstrated case
% (vertical_partition_on_circle in hybridization_scene.pl); its corpus anchor is
% the same grid-on-circle figure read as equal-width strips, so it shares the
% Cadez bibkey as the closest attested witness, declared honestly here.

deformation_evidence(transplant(grid, circle), Bibkeys) :-
    attested_for(rectangle_grid_partition, circle_region, Bibkeys).
deformation_evidence(transplant(vertical, circle), Bibkeys) :-
    % vertical strips and an equal-width grid read the same on a disc; the
    % closest attested witness is the grid-on-circle figure.
    attested_for(rectangle_grid_partition, circle_region, Bibkeys).
deformation_evidence(transplant(radial, rectangle), Bibkeys) :-
    attested_for(circle_radial_partition, rectangle_area_model, Bibkeys).
deformation_evidence(transplant(grid, rectangle), Bibkeys) :-
    % grid on a rectangle is the rectangle's own licensed area grid; only counted
    % here when a foreign attested radial witness is wanted, so report empty.
    Bibkeys = [].
deformation_evidence(transplant(radial, set), Bibkeys) :-
    attested_for(circle_radial_partition, submarine_sandwich_region, B0),
    ( B0 == [] -> attested_for(circle_radial_partition, _AnyHost, Bibkeys)
    ; Bibkeys = B0 ).
deformation_evidence(transplant(vertical, area), Bibkeys) :-
    attested_for(rectangle_grid_partition, circle_region, Bibkeys).

% attested_for(ForeignPrimitive, IllicitHost, Bibkeys): collect the bibkeys from
% attested_deformations:attested_transplant/5 that match the foreign primitive
% on (an attested) illicit host. Read-only over the generated layer.
attested_for(ForeignPrimitive, IllicitHost, Bibkeys) :-
    ( catch(attested_deformations:attested_transplant(_, _, _, _, _), _, fail)
    -> findall(B,
               attested_deformations:attested_transplant(
                   _Lang, ForeignPrimitive, IllicitHost, B, _Fig),
               Bs)
    ;  Bs = [] ),
    sort(Bs, Bibkeys).

% attested_transplant_pair(Host, Transplant): the transplant families this layer
% can replicate, each one anchored to at least one real attested witness (or, for
% vertical-on-circle, to the grid-on-circle witness it shares). This is the set
% the replication test ranges over.
attested_transplant_pair(circle, transplant(vertical)).
attested_transplant_pair(circle, transplant(grid)).
attested_transplant_pair(rectangle, transplant(radial)).
attested_transplant_pair(set, transplant(radial)).

% --- Replication: the same deformation across several fractions --------------
%
% replicate_deformation(Host, transplant(Rule), ListOfN, FramesList): generate
% the SAME transplant deformation across a list of denominators. FramesList is a
% list of N-FramesDict pairs. The frame specs across the list differ ONLY in the
% segment/column/band count — that is the replication win this layer exists to
% demonstrate.

replicate_deformation(Host, transplant(Rule), ListOfN, FramesList) :-
    findall(N-Dict,
            ( member(N, ListOfN),
              deformed_partition_scene(Host, N, transplant(Rule), Dict) ),
            FramesList).

% --- Frame / scene dict construction (drawer-compatible) ---------------------

make_frame(Step, Verb, Caption, Primitives, Frame) :-
    term_to_text(Verb, VerbText),
    Scene = _{ format: "hybridization-model",
               version: 1,
               primitives: Primitives },
    Frame = _{ step: Step,
               verb: VerbText,
               caption: Caption,
               sceneChanged: true,
               scene: Scene }.

scene_dict(Kind, Tuple, Result, Frames, Meta, Dict) :-
    canvas_dict(Canvas),
    Base = _{ kind: Kind,
              request: _{ spec: Kind },
              result: Result,
              canvas: Canvas,
              frames: Frames,
              tuple: Tuple },
    Dict = Base.put(Meta).

% --- JSON serialisation to file ----------------------------------------------

partition_scene_to_file(Dict, Path) :-
    setup_call_cleanup(
        open(Path, write, Stream, [encoding(utf8)]),
        json_write_dict(Stream, Dict, [width(80)]),
        close(Stream)).

% replication_to_file(FramesList, Path): write the list of N-Dict pairs as one
% JSON object keyed by denominator, so a downstream harness can diff the frame
% specs across N.
replication_to_file(FramesList, Path) :-
    findall(Key-Dict,
            ( member(N-Dict, FramesList),
              format(atom(Key), "n_~w", [N]) ),
            Pairs),
    dict_pairs(Out, replication, Pairs),
    setup_call_cleanup(
        open(Path, write, Stream, [encoding(utf8)]),
        json_write_dict(Stream, Out, [width(80)]),
        close(Stream)).

% --- Helpers -----------------------------------------------------------------

term_to_text(Term, Text) :-
    ( string(Term)
    -> Text = Term
    ;  format(string(Text), "~w", [Term])
    ).
