/** <module> Balance-scale scene compiler (relational equals / solve-for-unit)
 *
 * Compiles a one-unknown linear equation, or a plain weight comparison, into a
 * sequence of two-pan balance-beam scene frames. The direction is Prolog ->
 * picture, and it runs in two stages so the figure reads off the inspected
 * semantic surface, not off a re-solve. `balance_solve_witness/4` computes the
 * ordered balance-preserving steps (each carrying its pan composition, its
 * unit-equivalent pan totals, the computed tilt, the trace verb, and the
 * caption) plus the one operational-equals deformation step. `balance_render_
 * frames/2` then walks those witness steps into scene frames: it assembles the
 * picture from the witness, it does not solve the equation again.
 *
 * The figure draws the RELATIONAL reading of "=": the two sides name the same
 * quantity, so the beam is level. Solving means doing the SAME thing to both
 * pans (the balance-preserving move) until one x-box stands alone. This is the
 * corrective to the operational misconception that "=" means "compute the
 * answer" rather than "the two sides are equal". Every balance-preserving step
 * keeps the beam level (`beam.tilt = level`); the tilt is computed from the pan
 * totals, not asserted. `balance_compare_frames/2` draws the contrast: the level
 * equation, then the operational-equals deformation where B is taken off one pan
 * only and the beam tips (`beam.tilt = right_down`), with the untouched pan
 * carrying the `deformation` color role.
 *
 * Scene shape: the PB scene in docs/render-contract-v2.md:
 * `format:"balance-scale"`,
 * `version:2`, a `beam` carrying only its `tilt`, and `pans.{left,right}` as
 * arrays of aggregated `{kind, count, role}` rows. The compiler emits color
 * ROLES (`x-box`, `unit-weight`, `pan`, `deformation`; §3), never hex — the
 * token stylesheet (Gate E) maps each role to `--fig-<role>`. The drawer owns
 * the per-block layout; this compiler emits no pixel geometry.
 *
 * Scope: a single unknown, integer coefficients, an integer solution. What it
 * does NOT model: fractions on the pan, negative coefficients, negative
 * intermediate weights (subtracting B leaves a non-negative right pan by
 * construction here), more than one unknown, or division that does not come out
 * even. solve_linear(A,B,C) requires A \= 0 and (C - B) divisible by A with a
 * non-negative integer solution; calls outside that envelope fail rather than
 * faking a picture.
 *
 * ROUTING:
 *   The grounding edge is asserted in strategies/render/grounding_to_primitive.pl:
 *     primitive_renders_metaphor('PB', balance_preservation_schema, primary).
 *   'PB' is the justify-side / relational-equals primitive, grounded in
 *   "sameness is preserved when the same operation is applied to both sides",
 *   not in one of the four Lakoff & Núñez arithmetic grounding metaphors (Object
 *   Collection / Construction / Measuring Stick / Motion Along a Path).
 *   `p_relational_equals_balance_preservation` carries
 *   grounding_metaphor(_, balance_preservation_schema), so balance renders can
 *   surface the PB primitive without faking an L&N arithmetic footer.
 *
 * WORKER WIRING (do NOT register here — single later integration pass):
 *   Op names to register: balance_render (consuming balance_render_json/2) and
 *   balance_compare (consuming balance_compare_json/2). Dispatch clause shape,
 *   modelled on the fraction_render clause in the contract:
 *     dispatch_request(balance_render, Id, Request, Response) :-
 *         ( get_dict(spec, Request, SpecStr)
 *         -> term_string(Spec, SpecStr),
 *            balance_scale_scene:balance_render_json(Spec, Dict),
 *            ok_response(Id, Dict, Response)
 *         ; error_response(Id, missing_spec,
 *                          "balance_render requires spec", Response) ).
 */

:- module(balance_scale_scene,
          [ balance_render_frames/2,   % +Spec, -Frames
            balance_render_json/2,      % +Spec, -Dict
            balance_render_to_file/2,   % +Spec, +Path
            balance_compare_frames/2,   % +Spec, -Frames
            balance_compare_json/2,     % +Spec, -Dict
            balance_solve_witness/4     % +A, +B, +C, -Witness
          ]).

:- use_module(library(http/json), [json_write_dict/3]).
:- use_module(library(lists)).

% -----------------------------------------------------------------------------
% Canvas advisory size. The frozen PB scene (render-contract §2) carries no
% per-cell geometry: the compiler emits aggregated `{kind, count, role}` pan
% rows and the drawer owns the rod/x-box layout. Two pans hang from a beam whose
% tilt the drawer reads from `beam.tilt`.
% -----------------------------------------------------------------------------
canvas_w(700).
canvas_h(360).

% Item-kind and color-role atoms (render-contract §3 balance roles). A compiler
% emits roles, never hex; Gate E maps each role to `--fig-<role>` in the token
% sheet. `unit-weight` is a 1-weight block, `x-box` the unknown, `pan` the pan
% surface, `deformation` the mislabelled fill that breaks balance.
kind_for(unit, "unit").
kind_for(xbox, "x").

role_unit("unit-weight").
role_xbox("x-box").
role_pan("pan").
role_deformation("deformation").


% -----------------------------------------------------------------------------
% Public entry points.
% -----------------------------------------------------------------------------

%!  balance_render_frames(+Spec, -Frames) is semidet.
%
%   Spec is solve_linear(A,B,C) or show_relation(L,R). The render is driven FROM
%   the witness, not by re-solving: for solve_linear it consumes
%   `balance_solve_witness/4` (the ordered, balance-preserving steps it already
%   computed) and walks each witness step into a `balance-scale` v2 scene frame.
%   The equation is not solved again here — the witness owns the solution and the
%   step order; this predicate only turns each step into a picture.
%   solve_linear fails (no frames) when A=0, when (C-B) is not divisible by A,
%   or when the solution would be negative — those are outside the v1 envelope
%   and are not faked.
balance_render_frames(solve_linear(A, B, C), Frames) :-
    balance_solve_witness(A, B, C, Witness),
    get_dict(steps, Witness, Steps),
    maplist(step_to_frame, Steps, Frames).
balance_render_frames(show_relation(L, R), Frames) :-
    integer(L), integer(R),
    L >= 0, R >= 0,
    show_relation_frames(L, R, Frames).

%!  step_to_frame(+Step, -Frame) is det.
%
%   Turn one balance-preserving witness step into a scene frame. The step
%   already carries its pan composition (`pans` descriptor), its computed tilt,
%   the trace verb, and the caption; this predicate only assembles the scene and
%   wraps the frame. The picture is read off the witness, not recomputed.
step_to_frame(Step, Frame) :-
    get_dict(step, Step, StepNo),
    get_dict(verb, Step, VerbString),
    get_dict(caption, Step, Caption),
    get_dict(tilt, Step, Tilt),
    get_dict(pans, Step, Pans),
    get_dict(left, Pans, LeftRows),
    get_dict(right, Pans, RightRows),
    get_dict(left_total, Step, LeftTotal),
    get_dict(right_total, Step, RightTotal),
    scene_for(LeftRows, LeftTotal, RightRows, RightTotal, Tilt, Scene),
    frame(StepNo, VerbString, Caption, true, Scene, Frame).


% -----------------------------------------------------------------------------
% show_relation(L,R): two pans with L and R units, tilt from the totals. No
% solving — this teaches the relational reading of a comparison.
% -----------------------------------------------------------------------------

show_relation_frames(L, R, [F1]) :-
    unit_rows(L, LeftRows),
    unit_rows(R, RightRows),
    tilt_of(L, R, Tilt),
    scene_for(LeftRows, L, RightRows, R, Tilt, Scene),
    relation_caption(L, R, Tilt, Cap),
    frame(1, "show_relation", Cap, true, Scene, F1).

relation_caption(L, R, level, Cap) :-
    format(string(Cap), "~w and ~w name the same weight: the beam is level.",
           [L, R]).
relation_caption(L, R, left_down, Cap) :-
    format(string(Cap), "~w is more than ~w: the left pan goes down.", [L, R]).
relation_caption(L, R, right_down, Cap) :-
    format(string(Cap), "~w is less than ~w: the right pan goes down.", [L, R]).


% -----------------------------------------------------------------------------
% Pan rows. The frozen PB scene carries aggregated `{kind, count, role}` rows;
% the drawer owns the per-block layout. A pan is a list of such rows: x-boxes
% first (role `x-box`), then unit weights (role `unit-weight`). A row with
% count 0 is dropped so an empty pan is the empty list.
% -----------------------------------------------------------------------------

%!  xunit_rows(+NX, +NU, -Rows) is det.
%   NX x-boxes (role `x-box`) then NU unit weights (role `unit-weight`).
xunit_rows(NX, NU, Rows) :-
    kind_for(xbox, XKind), role_xbox(XRole),
    kind_for(unit, UKind), role_unit(URole),
    maybe_row(XKind, NX, XRole, XRows),
    maybe_row(UKind, NU, URole, URows),
    append(XRows, URows, Rows).

%!  unit_rows(+NU, -Rows) is det.
unit_rows(NU, Rows) :-
    kind_for(unit, UKind), role_unit(URole),
    maybe_row(UKind, NU, URole, Rows).

%!  deformation_unit_rows(+NU, -Rows) is det.
%   Unit weights coloured with the `deformation` role: the mislabelled fill on
%   the pan that was changed without changing the other (operational-equals).
deformation_unit_rows(NU, Rows) :-
    kind_for(unit, UKind), role_deformation(DRole),
    maybe_row(UKind, NU, DRole, Rows).

maybe_row(_Kind, 0, _Role, []) :- !.
maybe_row(Kind, Count, Role, [_{ kind: Kind, count: Count, role: Role }]) :-
    Count > 0.


% -----------------------------------------------------------------------------
% Scene assembly. The frozen PB scene (render-contract §2): a beam carrying only
% its tilt, and a `pans` object with `left`/`right` arrays of `{kind, count,
% role}` rows. No per-cell pixel geometry: the drawer owns the rod/x-box layout.
% The `pan` role names the pan surface itself. The tilt is supplied by the
% caller (read off the witness step), not recomputed here.
% -----------------------------------------------------------------------------

%!  scene_for(+LeftRows, +LeftTotal, +RightRows, +RightTotal, +Tilt, -Scene) is det.
scene_for(LeftRows, LeftTotal, RightRows, RightTotal, Tilt, Scene) :-
    atom_string(Tilt, TiltStr),
    role_pan(PanRole),
    Scene = _{ format: "balance-scale",
               version: 2,
               beam: _{ tilt: TiltStr },
               pan_role: PanRole,
               pans: _{ left: LeftRows, right: RightRows },
               totals: _{ left: LeftTotal, right: RightTotal } }.

%!  tilt_of(+LeftTotal, +RightTotal, -Tilt) is det.
%   level iff the sides are equal; otherwise the heavier side goes down.
tilt_of(L, R, level)      :- L =:= R, !.
tilt_of(L, R, left_down)  :- L > R, !.
tilt_of(_, _, right_down).


% -----------------------------------------------------------------------------
% Frame assembly.
% -----------------------------------------------------------------------------

%!  frame(+Step, +Verb, +Caption, +Changed, +Scene, -Frame) is det.
frame(Step, Verb, Caption, Changed, Scene, Frame) :-
    Frame = _{ step: Step, verb: Verb, caption: Caption,
               sceneChanged: Changed, scene: Scene }.


% -----------------------------------------------------------------------------
% Witness assembly. This is the inspected semantic surface that a balance
% primitive can consume before it asks for pictures.
% -----------------------------------------------------------------------------

%!  balance_solve_witness(+A, +B, +C, -Witness) is semidet.
%
%   Witness solve_linear(A,B,C) as the equation A*x + B = C: an explicit
%   read-equation term, an ordered list of balance-preserving steps (each
%   carrying its pan composition, tilt, trace verb, and caption), the integer
%   solution, and one non-balance-preserving deformation step. This is the
%   single source the renderer reads: `balance_render_frames/2` walks these
%   steps into pictures rather than re-deriving them.
balance_solve_witness(A, B, C, Witness) :-
    balance_solution(A, B, C, X, Diff),
    solve_steps(A, B, C, X, Diff, Steps),
    balance_deformation_step(A, B, C, Diff, DeformationStep),
    format(string(Equation), "~w*x + ~w = ~w", [A, B, C]),
    Witness = _{ kind: balance_solve_witness,
                 scope: closed_world_finite_one_unknown_integer_linear_equation,
                 eq: eq(A, B, C),
                 equation: Equation,
                 read_equation: read_equation(linear(A, B, C)),
                 source_predicate: balance_solve_witness/4,
                 derivation: balance_preserving_invariant_over_one_unknown,
                 solution: X,
                 steps: Steps,
                 deformation_step: DeformationStep },
    !.

balance_solution(A, B, C, X, Diff) :-
    integer(A), integer(B), integer(C),
    A =\= 0,
    Diff is C - B,
    Diff >= 0,
    0 =:= Diff mod A,
    X is Diff // A,
    X >= 0.

%!  solve_steps(+A, +B, +C, +X, +Diff, -Steps) is det.
%
%   The four ordered balance-preserving steps of A*x + B = C. Each step carries
%   its pan composition (the `pans` descriptor the renderer reads), the unit-
%   equivalent pan totals (equal at every step, since the equation is true), the
%   computed tilt (level throughout), the trace verb, and the caption. The pan
%   total is the balancing weight: a unit weighs 1, an x-box weighs X.
solve_steps(A, B, C, X, Diff, [S1, S2, S3, S4]) :-
    % Step 1 — the equation as a true balance: A x-boxes + B units vs C units.
    xunit_rows(A, B, P1Left),
    unit_rows(C, P1Right),
    format(string(Cap1),
           "~wx + ~w = ~w. The two sides name the same weight, so the beam is level.",
           [A, B, C]),
    solve_step(1, "show_equation_as_balance", read_equation, Cap1,
               P1Left, C, P1Right, C, S1),

    % Step 2 — remove B units from both pans: A x-boxes vs Diff units.
    xunit_rows(A, 0, P2Left),
    unit_rows(Diff, P2Right),
    ( B =:= 0
    -> format(string(Cap2),
              "Nothing to remove (B is 0). Left ~wx, right ~w; still level.",
              [A, Diff])
    ;  format(string(Cap2),
              "Take ~w units off BOTH pans. Left ~wx, right ~w; still level.",
              [B, A, Diff])
    ),
    solve_step(2, "subtract_units_from_both_pans", subtract_same_units_from_both_pans,
               Cap2, P2Left, Diff, P2Right, Diff, S2),

    % Step 3 — split each side into A equal groups (same scene, conceptual).
    ( A =:= 1
    -> format(string(Cap3),
              "One x-box already stands alone against ~w units.", [Diff])
    ;  format(string(Cap3),
              "Split each pan into ~w equal groups: one x-box balances ~w / ~w = ~w units.",
              [A, Diff, A, X])
    ),
    solve_step(3, "split_each_side_into_equal_groups", split_each_side_into_equal_groups,
               Cap3, P2Left, Diff, P2Right, Diff, S3),

    % Step 4 — the isolated unknown: one x-box vs X units.
    xunit_rows(1, 0, P4Left),
    unit_rows(X, P4Right),
    format(string(Cap4),
           "x = ~w. One x-box balances ~w units; the beam stays level.",
           [X, X]),
    solve_step(4, "isolate_the_unknown", isolate_the_unknown,
               Cap4, P4Left, X, P4Right, X, S4).

%!  solve_step(+No, +Verb, +Action, +Cap, +LeftRows, +LTotal, +RightRows, +RTotal, -Step) is det.
solve_step(No, Verb, Action, Cap, LeftRows, LTotal, RightRows, RTotal, Step) :-
    tilt_of(LTotal, RTotal, Tilt),
    Step = _{ step: No,
              action: Action,
              verb: Verb,
              caption: Cap,
              balance_preserving: true,
              pans: _{ left: LeftRows, right: RightRows },
              left_total: LTotal,
              right_total: RTotal,
              tilt: Tilt }.

%!  balance_deformation_step(+A, +B, +C, +Diff, -Step) is det.
%
%   The operational-equals deformation: B units are taken off the LEFT pan only
%   ("compute one side"), leaving the right pan untouched. The left pan now holds
%   A x-boxes (total Diff); the right keeps its C units but they carry the
%   `deformation` role — the untouched side that should have changed too. The
%   beam tips (right_down when B > 0). This is the step `balance_compare` draws.
balance_deformation_step(A, B, C, Diff, Step) :-
    xunit_rows(A, 0, LeftRows),
    deformation_unit_rows(C, RightRows),
    tilt_of(Diff, C, Tilt),
    format(string(Cap),
           "Taking ~w off the LEFT pan only leaves ~wx against ~w: the beam tips. \c
The same move was not done to both sides.",
           [B, A, C]),
    Step = _{ action: subtract_from_left_pan_only,
              verb: "subtract_from_left_pan_only",
              caption: Cap,
              balance_preserving: false,
              pans: _{ left: LeftRows, right: RightRows },
              left_total: Diff,
              right_total: C,
              tilt: Tilt,
              omitted_move: subtract_from_right_pan,
              omitted_amount: B,
              misconception: operational_equals_compute_one_side }.


% -----------------------------------------------------------------------------
% Compare: the operational-equals deformation. Two frames read off the witness —
% the equation as a level balance (the relational reading), then the deformation
% where B is taken off ONE pan and the beam tips. The productive/deformation
% contrast is the point: solving keeps the beam level by doing the same move to
% both pans; "compute one side" tips it.
% -----------------------------------------------------------------------------

%!  balance_compare_frames(+Spec, -Frames) is semidet.
%
%   Spec is solve_linear(A,B,C). Frame 1 is the first balance-preserving step
%   (the level equation); frame 2 is the operational-equals deformation step
%   (`subtract_from_left_pan_only`, beam tips). Both are read off
%   `balance_solve_witness/4`; nothing is re-solved.
balance_compare_frames(solve_linear(A, B, C), [F1, F2]) :-
    balance_solve_witness(A, B, C, Witness),
    get_dict(steps, Witness, [Step1 | _]),
    get_dict(deformation_step, Witness, Deform),
    step_to_frame(Step1, F1),
    deformation_to_frame(2, Deform, F2).

%!  deformation_to_frame(+No, +DeformStep, -Frame) is det.
%   Turn the witness deformation step into a scene frame. The tilt is the
%   deformation's tip; the right pan carries the `deformation` role.
deformation_to_frame(No, Deform, Frame) :-
    get_dict(verb, Deform, VerbString),
    get_dict(caption, Deform, Caption),
    get_dict(tilt, Deform, Tilt),
    get_dict(pans, Deform, Pans),
    get_dict(left, Pans, LeftRows),
    get_dict(right, Pans, RightRows),
    get_dict(left_total, Deform, LeftTotal),
    get_dict(right_total, Deform, RightTotal),
    scene_for(LeftRows, LeftTotal, RightRows, RightTotal, Tilt, Scene),
    frame(No, VerbString, Caption, true, Scene, Frame).

%!  balance_compare_json(+Spec, -Dict) is det.
%
%   The productive/deformation document for the operational-equals contrast.
%   Carries `productive`/`deformation`/`note` siblings (a permitted compare
%   document variant) plus the two-frame filmstrip. Outside the v1 envelope it
%   yields an explicit error and empty frames rather than a faked picture.
balance_compare_json(solve_linear(A, B, C), Dict) :-
    ( balance_compare_frames(solve_linear(A, B, C), Frames)
    -> spec_request(solve_linear(A, B, C), Request),
       spec_result(solve_linear(A, B, C), ResultStr),
       canvas_dict(Canvas),
       Dict = _{ kind: "balance_compare",
                 request: Request,
                 result: ResultStr,
                 canvas: Canvas,
                 productive: subtract_same_units_from_both_pans,
                 deformation: subtract_from_left_pan_only,
                 note: "Solving keeps the beam level by doing the same move to both pans; computing one side tips it.",
                 frames: Frames }
    ;  spec_request(solve_linear(A, B, C), Request),
       spec_error(solve_linear(A, B, C), Msg),
       Dict = _{ kind: "balance_compare",
                 request: Request,
                 error: Msg,
                 frames: [] } ).


% -----------------------------------------------------------------------------
% JSON assembly.
% -----------------------------------------------------------------------------

%!  balance_render_json(+Spec, -Dict) is det.
%
%   Assemble the full frame document: kind / request / result / canvas / frames.
%   A Spec outside the v1 envelope yields a Dict with an explicit error and no
%   frames rather than throwing.
balance_render_json(Spec, Dict) :-
    ( balance_render_frames(Spec, Frames)
    -> spec_kind(Spec, KindStr),
       spec_request(Spec, Request),
       spec_result(Spec, ResultStr),
       canvas_dict(Canvas),
       Dict = _{ kind: KindStr,
                 request: Request,
                 result: ResultStr,
                 canvas: Canvas,
                 frames: Frames }
    ;  spec_kind(Spec, KindStr),
       spec_request(Spec, Request),
       spec_error(Spec, Msg),
       Dict = _{ kind: KindStr,
                 request: Request,
                 error: Msg,
                 frames: [] } ).

spec_kind(solve_linear(_, _, _), "solve_linear").
spec_kind(show_relation(_, _), "show_relation").
spec_kind(_, "unknown").

spec_request(solve_linear(A, B, C),
             _{ form: "A*x + B = C", a: A, b: B, c: C }) :- !.
spec_request(show_relation(L, R),
             _{ form: "L vs R", l: L, r: R }) :- !.
spec_request(_, _{}).

spec_result(solve_linear(A, B, C), ResultStr) :-
    Diff is C - B,
    A =\= 0, 0 =:= Diff mod A,
    X is Diff // A,
    format(string(ResultStr), "x = ~w", [X]), !.
spec_result(show_relation(L, R), ResultStr) :-
    tilt_of(L, R, Tilt),
    format(string(ResultStr), "~w (~w, ~w)", [Tilt, L, R]), !.
spec_result(_, "unknown").

spec_error(solve_linear(A, B, C), Msg) :-
    A =:= 0, !,
    format(string(Msg), "A is 0 in ~wx + ~w = ~w; not a one-unknown linear equation.",
           [A, B, C]).
spec_error(solve_linear(A, B, C), Msg) :-
    Diff is C - B, ( Diff < 0 ; A =\= 0, 0 =\= Diff mod A ; A =\= 0, Diff // A < 0 ), !,
    format(string(Msg),
           "~wx + ~w = ~w has no non-negative integer solution drawable on the pan (v1: integer x >= 0).",
           [A, B, C]).
spec_error(Spec, Msg) :-
    format(string(Msg), "~w is not a balance-scale spec this renderer draws.", [Spec]).

%!  canvas_dict(-Canvas) is det.
canvas_dict(Canvas) :-
    canvas_w(W), canvas_h(H),
    Canvas = _{ width: W, height: H }.


%!  balance_render_to_file(+Spec, +Path) is det.
%
%   Render the frame document and write it as pretty-printed JSON to Path.
balance_render_to_file(Spec, Path) :-
    balance_render_json(Spec, Dict),
    setup_call_cleanup(
        open(Path, write, Stream),
        json_write_dict(Stream, Dict, [width(80)]),
        close(Stream)).
