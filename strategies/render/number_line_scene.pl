/** <module> Number-line scene compiler (P1)
 *
 * Compiles a strategy's WITNESS trace into number-line scene frames on the
 * render contract (docs/render-contract-v2.md,
 * §2 P1). The direction is Prolog -> picture and, crucially, the picture is
 * driven by the worker's trace, NOT by re-deriving arithmetic from the raw
 * inputs:
 *
 *   - the productive "jumps" form reads
 *     hermes_encyclopedia:strategy_trace_dict/3, whose jumps[] come from
 *     visualization:strategy_jumps_witness/3 (the running-sum trace of an FSM
 *     strategy collapsed to deltas);
 *   - the rounding deformation "length" form reads
 *     visualization:misconception_jumps_witness/5, whose jumps, omitted_jumps,
 *     result, and expected come from the deformation action automaton's parsed
 *     trace, and reads the productive partner's adjust_back_by step from
 *     sar_add_action_pairs:run_additive_action/5 so the omitted
 *     compensation is drawn against its grounded partner.
 *
 * Two scene sub-shapes share one format ("number-line", version 2), selected by
 * `mode`:
 *
 *   - mode "jumps" — stacked base/unit arcs with a scale break and direction
 *     roles (the SAR_ADD_COBO norm). Tier "base" for jumps that move a whole
 *     base group, "unit" for single-unit jumps. role jump-add / jump-sub by
 *     direction; the scale-break glyph when the axis does not start at 0.
 *   - mode "length" — rounding as a Measuring-Stick length diagram
 *     (the SAR_SUB_Rounding length-diagram norm, Tio's preferred rounding form):
 *     known-whole / known-part / rounded-overshoot / adjustment rects. The
 *     deformation's omitted compensation is the adjustment segment drawn
 *     against the productive partner's grounded adjust-back step.
 *
 * Semantic color ROLES only (contract §3). This compiler never emits a hex
 * string; the token stylesheet (Gate E) maps role -> --fig-<role>.
 *
 * Graceful degradation: a strategy that cannot be run to a jump trace, or a
 * deformation with no drawable number-line trace, yields an explicit error
 * document with frames:[] rather than a faked picture (contract §2,
 * "Graceful degradation").
 *
 * Scope / honest limits:
 *   - The jumps form covers exactly the strategies whose running-sum trace the
 *     visualization witness can read (COBO, Chunking, RMB, Rounding, the
 *     subtraction families, and any generic state(Name, RunningValue, ...)
 *     shape). A strategy outside that closed world returns the error document.
 *   - Tier (base vs unit) is inferred from each jump's delta against the base,
 *     not from a separately proven place-value decomposition. It is a drawing
 *     hint, not a claim about the child's unit structure.
 *   - The length form is the additive rounding-without-compensation family
 *     only; it is not a general subtraction-by-rounding renderer.
 */

:- module(number_line_scene,
          [ number_line_render_frames/2,   % +Spec, -Frames
            number_line_render_json/2,      % +Spec, -Dict
            number_line_plan_json/2,        % +UnitPlan, -Dict
            number_line_scene_plan/3,       % +Scene, -UnitPlan, -Evidence
            number_line_compare_json/2,     % +Spec, -Dict   (rounding deformation)
            number_line_render_to_file/2    % +Spec, +Path
          ]).

:- use_module(hermes(encyclopedia), []).
:- use_module(strategies(visualization), []).
:- use_module(math(sar_add_action_pairs), [run_additive_action/5]).
:- use_module(math(recursive_unit_actions), []).
:- use_module(render(signed_number_line_scene),
              [signed_number_line_render_json/2]).
:- use_module(library(http/json), [json_write_dict/3]).
:- use_module(library(lists)).

% -----------------------------------------------------------------------------
% Geometry constants (the SAR_ADD_COBO / SAR_SUB_Rounding norms). Integer
% coordinates throughout; the JS drawer auto-fits the viewBox.
% -----------------------------------------------------------------------------
axis_x0(60).             % left edge of the drawable axis band
axis_x1(660).            % right edge of the drawable axis band
axis_y(220).             % baseline y of the number line
arc_base_h(70).          % apex height of a base-tier arc above the axis
arc_unit_h(34).          % apex height of a unit-tier arc above the axis

% Length-diagram (rounding) band.
len_x0(60).              % left edge of the length bars
len_unit_w(560).         % full drawable width a "whole" length spans
len_bar_h(40).           % height of each length bar
len_row_y0(60).          % y of the first (known-whole) bar
len_row_gap(20).         % vertical gap between stacked length bars

base_default(10).        % the operative base for tier classification


% =============================================================================
% Public API
% =============================================================================

%!  number_line_render_frames(+Spec, -Frames) is det.
%
%   Walk Spec into a list of frame dicts. The two Spec shapes:
%     - jumps(Strategy, A, B)        : the productive jumps form
%     - rounding_length(Op, A, B)    : the rounding length form (productive
%                                      grounded length diagram)
%   A Spec that cannot source a witness trace yields a single annotation-only
%   frame (sceneChanged:false), so nothing throws.
number_line_render_frames(Spec, Frames) :-
    ( gen_frames(Spec, Frames0)
    -> Frames = Frames0
    ;  deferred_frame(Spec, F),
       Frames = [F]
    ).

%!  number_line_render_json(+Spec, -Dict) is det.
%
%   The full render document: kind / request / result / canvas / frames
%   (contract §1.1). On a Spec whose witness trace is unavailable, an explicit
%   error string and frames:[].
number_line_render_json(jumps(Strategy, A, B), Dict) :-
    !,
    base_default(Base),
    ( strategy_jump_data(Strategy, A, B, ResultStr, Jumps), Jumps \== []
    -> jumps_frames(Jumps, Base, Frames),
       term_to_string(Strategy, KindStr),
       canvas_dict(Canvas),
       Dict = _{ kind: KindStr,
                 request: _{ strategy: KindStr, a: A, b: B },
                 result: ResultStr,
                 canvas: Canvas,
                 frames: Frames }
    ;  term_to_string(Strategy, KindStr),
       Dict = _{ kind: KindStr,
                 request: _{ strategy: KindStr, a: A, b: B },
                 error: "No number-line jump trace is available for this strategy's step shape.",
                 frames: [] }
    ).
number_line_render_json(rounding_length(Op, A, B), Dict) :-
    !,
    ( rounding_length_data(Op, A, B, Data)
    -> length_frames(Data, Frames),
       _{ result: ResultI, expected: ExpectedI } :< Data,
       format(string(ResultStr), "~w", [ExpectedI]),
       term_to_string(Op, OpStr),
       rounding_note(grounded, Note),
       canvas_dict(Canvas),
       Dict = _{ kind: "round_then_adjust",
                 request: _{ op: OpStr, a: A, b: B },
                 result: ResultStr,
                 note: Note,
                 grounded_result: ExpectedI,
                 rounded_result: ResultI,
                 canvas: Canvas,
                 frames: Frames }
    ;  term_to_string(Op, OpStr),
       Dict = _{ kind: "round_then_adjust",
                 request: _{ op: OpStr, a: A, b: B },
                 error: "No grounded rounding length diagram for this operation/inputs.",
                 frames: [] }
    ).
number_line_render_json(fraction_iteration(N, D), Dict) :-
    !,
    ( recursive_unit_actions:fraction_unit_plan(N, D, Plan),
      number_line_plan_json(Plan, PlanDict)
    -> get_dict(unitPlan, PlanDict.request, PlanString),
       Dict = PlanDict.put(request,
                           _{ numerator: N, denominator: D,
                              unitPlan: PlanString })
    ;  Dict = _{ kind: "fraction_iteration",
                 request: _{ numerator: N, denominator: D },
                 error: "Fraction number-line iteration requires positive integer numerator and denominator.",
                 frames: [] }
    ).
number_line_render_json(magnitude_addition(A, B), Dict) :-
    !,
    magnitude_addition_frames(A, B, Frames),
    Sum is A + B,
    format(string(ResultStr), "~w", [Sum]),
    canvas_dict(Canvas),
    Dict = _{ kind: "magnitude_addition",
              request: _{ op: "addition", a: A, b: B },
              result: ResultStr,
              note: "A bounded number-line length model: the second addend is appended to the first without unrolling unit jumps.",
              canvas: Canvas,
              frames: Frames }.
number_line_render_json(signed_locations(Values), Dict) :-
    !,
    signed_number_line_render_json(signed_locations(Values), Dict).
number_line_render_json(inequality_solution(Relation, Bound), Dict) :-
    !,
    signed_number_line_render_json(inequality_solution(Relation, Bound), Dict).
number_line_render_json(Spec, Dict) :-
    number_line_render_frames(Spec, Frames),
    term_to_string(Spec, SpecStr),
    canvas_dict(Canvas),
    Dict = _{ kind: SpecStr,
              request: _{ spec: SpecStr },
              result: "unknown",
              canvas: Canvas,
              frames: Frames }.



%!  number_line_plan_json(+UnitPlan, -Dict) is semidet.
%
%   Render the value enacted by a recursive unit plan. The drawing receives
%   the plan's raw unit ratio; it does not infer a denominator from a label.
number_line_plan_json(Plan, Dict) :-
    Plan = plan(unit(whole), [partition(D)], iterate(N)),
    recursive_unit_actions:run_unit_plan(Plan, Quantity, ActionTrace),
    Quantity = quantity(raw_value(fraction(N, D)),
                        canonical_value(fraction(CN, CD)), _, _, _, _),
    fraction_iteration_frames(N, D, Frames),
    fraction_inscription_base(D, InscriptionBase),
    recursive_unit_actions:unit_plan_numeral(Plan, InscriptionBase, Numeral),
    recursive_unit_actions:numeral_text(Numeral, NumeralText),
    recursive_unit_actions:plan_dict(Plan, PlanDict),
    maplist(term_to_string, ActionTrace, TraceStrings),
    format(string(ResultStr), "~w/~w", [N, D]),
    canvas_dict(Canvas),
    Dict = _{ kind: "fraction_iteration",
              request: _{ unitPlan: PlanDict.plan },
              result: ResultStr,
              valueSemantics: _{
                  rawNumerator: N, rawDenominator: D,
                  canonicalNumerator: CN, canonicalDenominator: CD
              },
              inscription: _{ base: InscriptionBase, text: NumeralText },
              actionTrace: TraceStrings,
              canvas: Canvas,
              frames: Frames }.


%!  number_line_scene_plan(+Scene, -UnitPlan, -Evidence) is semidet.
%
%   Recollect fraction iteration from coordinate geometry. Labels and the
%   optional inscription are not consulted.
number_line_scene_plan(Scene, Plan, Evidence) :-
    get_dict(format, Scene, "number-line"),
    get_dict(mode, Scene, "fraction-jumps"),
    get_dict(coordinateDenominator, Scene, D),
    get_dict(referentWholeAt, Scene, D),
    integer(D), D > 0,
    get_dict(jumps, Scene, Jumps),
    Jumps = [_|_],
    contiguous_unit_jumps(Jumps, 1),
    length(Jumps, N),
    recursive_unit_actions:fraction_unit_plan(N, D, Plan),
    Evidence = scene_recollection(
                   denominator_from_coordinate_scale(D),
                   numerator_from_unit_jumps(N),
                   referent_whole_at(D)).

contiguous_unit_jumps([], _Expected).
contiguous_unit_jumps([Jump|Jumps], ExpectedTo) :-
    ExpectedFrom is ExpectedTo - 1,
    get_dict(from, Jump, ExpectedFrom),
    get_dict(to, Jump, ExpectedTo),
    get_dict(by, Jump, 1),
    Next is ExpectedTo + 1,
    contiguous_unit_jumps(Jumps, Next).

fraction_inscription_base(1, 10) :- !.
fraction_inscription_base(Denominator, Denominator).

%!  number_line_compare_json(+Spec, -Dict) is det.
%
%   The rounding deformation compare document: a productive (grounded) length
%   filmstrip beside the deformation length filmstrip, so the omitted
%   compensation is drawn against its grounded partner. Spec is
%   rounding_compare(Op, A, B) (Op = addition for the live family).
%   On an undrawable pair, an explicit error and empty filmstrips.
number_line_compare_json(rounding_compare(Op, A, B), Dict) :-
    !,
    ( rounding_compare_data(Op, A, B, Prod, Def)
    -> length_frames(Prod, ProdFrames),
       def_length_frames(Def, DefFrames),
       _{ result: ResultI, expected: ExpectedI, omitted: OmittedI } :< Def,
       compare_note(Op, A, B, ResultI, ExpectedI, OmittedI, Note),
       term_to_string(Op, OpStr),
       canvas_dict(Canvas),
       Dict = _{ kind: "round_then_adjust_vs_round_without_adjusting",
                 request: _{ op: OpStr, a: A, b: B },
                 productiveKind: "round_then_adjust",
                 deformationKind: "round_without_adjusting",
                 family: "rounding_without_compensation",
                 grounded_result: ExpectedI,
                 deformed_result: ResultI,
                 omitted_adjustment: OmittedI,
                 note: Note,
                 canvas: Canvas,
                 productive: _{ frames: ProdFrames },
                 deformation: _{ frames: DefFrames } }
    ;  term_to_string(Op, OpStr),
       Dict = _{ kind: "round_then_adjust_vs_round_without_adjusting",
                 request: _{ op: OpStr, a: A, b: B },
                 error: "This rounding pair has no drawable number-line length divergence.",
                 productive: _{ frames: [] },
                 deformation: _{ frames: [] } }
    ).
number_line_compare_json(Spec, _{ kind: SpecStr,
                                  error: "Unknown compare spec.",
                                  productive: _{ frames: [] },
                                  deformation: _{ frames: [] } }) :-
    term_to_string(Spec, SpecStr).

%!  number_line_render_to_file(+Spec, +Path) is det.
number_line_render_to_file(Spec, Path) :-
    number_line_render_json(Spec, Dict),
    setup_call_cleanup(
        open(Path, write, Stream),
        json_write_dict(Stream, Dict, [width(80)]),
        close(Stream)).


% =============================================================================
% Witness sourcing — the jumps form reads the strategy trace witness.
% =============================================================================

%!  strategy_jump_data(+Strategy, +A, +B, -ResultStr, -Jumps) is semidet.
%
%   Run the named strategy through hermes_encyclopedia:strategy_trace_dict/3 and
%   pull out its result string and its number-line jumps. The jumps come from
%   visualization:strategy_jumps_witness/3 inside the trace dict — this compiler
%   does not re-derive them from A and B.
strategy_jump_data(Strategy, A, B, ResultStr, Jumps) :-
    catch(hermes_encyclopedia:strategy_trace_dict(Strategy, _{a: A, b: B}, Dict),
          _, fail),
    get_dict(ok, Dict, true),
    get_dict(jumps, Dict, Jumps0),
    Jumps0 \== [],
    ( get_dict(result, Dict, ResultStr0) -> ResultStr = ResultStr0 ; ResultStr = "" ),
    Jumps = Jumps0.


% =============================================================================
% jumps mode — stacked base/unit arcs over a scale-broken axis.
% =============================================================================

%!  jumps_frames(+Jumps, +Base, -Frames) is det.
%
%   One frame per jump, accumulating the arcs drawn so far so the filmstrip
%   builds the number line jump by jump. Each scene carries the full axis plus
%   every arc up to and including the current step; the running mark sits at the
%   current "to". The axis min/max span the full set of stops so the scale is
%   fixed across the filmstrip (no jitter), with a scale break when the axis
%   does not start at 0.
jumps_frames(Jumps, Base, Frames) :-
    jump_stops(Jumps, Stops),
    min_list(Stops, MinStop),
    max_list(Stops, MaxStop),
    axis_window(MinStop, MaxStop, Stops, AxisMin, AxisMax, Ticks, Break),
    jumps_frames_(Jumps, Base, AxisMin, AxisMax, Ticks, Break, 1, [], Frames).

%!  axis_window(+MinStop, +MaxStop, +Stops, -AxisMin, -AxisMax, -Ticks, -Break) is det.
%
%   Zero anchors the left end of the axis whenever the stops are non-negative;
%   a number line that opens mid-count reads as a different object. A scale
%   break is emitted only when it is necessary: the skipped stretch (0, MinStop)
%   must be both proportionally large (more than a third of the span, else the
%   full axis draws fine) and absolutely large (MaxStop > 30, else even a
%   mostly-empty axis stays readable). The skipped interval's upper end travels
%   as breakEnd so the drawer can compress that stretch honestly instead of
%   painting a glyph on a linear scale.
axis_window(MinStop, MaxStop, Stops, AxisMin, AxisMax, Ticks, Break) :-
    AxisMax = MaxStop,
    (   MinStop >= 0
    ->  AxisMin = 0,
        (   MinStop > 0, MinStop * 3 > MaxStop, MaxStop > 30
        ->  Break = break(true, MinStop)
        ;   Break = break(false, 0)
        ),
        ( MinStop > 0 -> Ticks = [0|Stops] ; Ticks = Stops )
    ;   % Negative stops: span them; zero is on the axis already.
        AxisMin = MinStop,
        Break = break(false, 0),
        Ticks = Stops
    ).

jumps_frames_([], _Base, _Min, _Max, _Ticks, _Break, _Step, _Acc, []).
jumps_frames_([Jump|Rest], Base, Min, Max, Ticks, Break, Step, Acc, [Frame|Frames]) :-
    jump_to_arc(Jump, Base, Arc),
    append(Acc, [Arc], Acc1),
    _{ from: From, to: To } :< Arc,
    running_marks(Min, Max, To, Marks),
    axis_dict(Min, Max, Ticks, Break, Axis),
    Scene = _{ format: "number-line",
               version: 2,
               mode: "jumps",
               axis: Axis,
               jumps: Acc1,
               marks: Marks },
    jump_caption(Jump, From, To, Caption),
    jump_verb(Jump, Verb),
    Frame = _{ step: Step,
               verb: Verb,
               caption: Caption,
               sceneChanged: true,
               scene: Scene },
    Step1 is Step + 1,
    jumps_frames_(Rest, Base, Min, Max, Ticks, Break, Step1, Acc1, Frames).

%!  jump_to_arc(+Jump, +Base, -Arc) is det.
%   A jump dict _{from,to,label,...} becomes a scene arc carrying its by-amount,
%   tier (base vs unit), and direction role.
jump_to_arc(Jump, Base, Arc) :-
    get_dict(from, Jump, From),
    get_dict(to, Jump, To),
    By is abs(To - From),
    jump_tier(By, Base, Tier),
    ( To >= From -> Role = "jump-add" ; Role = "jump-sub" ),
    Arc = _{ from: From, to: To, by: By, tier: Tier, role: Role }.

%!  jump_tier(+By, +Base, -Tier) is det.
%   A jump that moves a nonzero whole multiple of the base (e.g. +10, +20) is a
%   base-tier arc; anything else is a unit-tier arc. This is a drawing hint
%   derived from the jump magnitude, not a proven place-value decomposition.
jump_tier(By, Base, "base") :-
    By >= Base,
    Base > 0,
    0 =:= By mod Base,
    !.
jump_tier(_, _, "unit").

%!  jump_stops(+Jumps, -Stops) is det.
%   Every from/to value the jumps touch (the axis must span them all).
jump_stops(Jumps, Stops) :-
    findall(V,
            ( member(J, Jumps),
              ( get_dict(from, J, V) ; get_dict(to, J, V) )
            ),
            Stops0),
    sort(Stops0, Stops).

%!  axis_ticks(+Stops, -Ticks) is det.
%   The sorted distinct stops are the axis ticks (the meaningful number-line
%   landmarks: every place the running value paused at).
axis_ticks(Stops, Stops).

%!  axis_dict(+Min, +Max, +Ticks, +Break, -Axis) is det.
%
%   Break is break(ScaleBreak, BreakEnd): when ScaleBreak is true the axis
%   skips the interval (Min, BreakEnd) and the drawer compresses that stretch.
axis_dict(Min, Max, Ticks, break(ScaleBreak, BreakEnd),
          _{ min: Min, max: Max, ticks: Ticks,
             scaleBreak: ScaleBreak, breakEnd: BreakEnd }).

%!  running_marks(+Min, +Max, +To, -Marks) is det.
%   The endpoints labelled, plus the running position at the current "to".
running_marks(Min, Max, To, Marks) :-
    format(string(MinLab), "~w", [Min]),
    format(string(MaxLab), "~w", [Max]),
    format(string(ToLab), "~w", [To]),
    Base0 = [ _{ at: Min, label: MinLab },
              _{ at: Max, label: MaxLab } ],
    ( To =:= Min ; To =:= Max
    -> Marks = Base0
    ;  append(Base0, [_{ at: To, label: ToLab }], Marks)
    ).

%!  jump_caption(+Jump, +From, +To, -Caption) is det.
jump_caption(_Jump, From, To, Caption) :-
    Delta is To - From,
    ( Delta >= 0
    -> format(string(Caption), "Jump from ~w by +~w to ~w.", [From, Delta, To])
    ;  format(string(Caption), "Jump from ~w back ~w to ~w.", [From, Delta, To])
    ).

%!  jump_verb(+Jump, -Verb) is det.
%   Prefer the witness's own reason/label as the step verb; fall back to the
%   signed delta label.
jump_verb(Jump, Verb) :-
    ( get_dict(reason, Jump, Reason) -> term_to_string(Reason, Verb)
    ; get_dict(label, Jump, Label)   -> term_to_string(Label, Verb)
    ; Verb = "jump"
    ).


% =============================================================================
% length mode — rounding as a Measuring-Stick length diagram.
%
% The productive (grounded) story (round_then_adjust): a known whole (the true
% sum), a rounded overshoot that runs past it, and the adjustment segment that
% the productive scheme counts back. The length form makes the overshoot and the
% counted-back adjustment legible as lengths.
% =============================================================================

%!  rounding_length_data(+Op, +A, +B, -Data) is semidet.
%
%   Read the productive partner's trace from
%   sar_add_action_pairs:run_additive_action/5 and the deformation
%   witness for the rounded overshoot. Returns a dict with the integers the
%   length diagram needs.
rounding_length_data(Op, A, B, Data) :-
    productive_rounding_components(Op, A, B, Comp),
    _{ rounded_result: Rounded, expected: Expected, adjustment: Adj,
       known_a: KA, known_b: KB, rounded_a: RA } :< Comp,
    Data = _{ a: A, b: B,
              known_a: KA, known_b: KB, rounded_a: RA,
              result: Rounded, expected: Expected, adjustment: Adj }.

%!  productive_rounding_components(+Op, +A, +B, -Comp) is semidet.
%   Run the productive round_then_adjust automaton and pull the components and
%   the adjust_back_by grounded step out of its trace.
productive_rounding_components(Op, A, B, Comp) :-
    Op == addition,
    catch(run_additive_action(round_then_adjust, A, B, Outcome, Trace),
          _, fail),
    Outcome = action_outcome(round_then_adjust, Fields),
    member(components(rounding_components(KA, KB, _Base, RA, Adj, Rounded, Expected)), Fields),
    % Confirm the grounded compensation jump is present in the productive trace.
    member(adjust_back_by(Adj, Rounded, Expected), Trace),
    Comp = _{ known_a: KA, known_b: KB, rounded_a: RA,
              adjustment: Adj, rounded_result: Rounded, expected: Expected }.

%!  length_frames(+Data, -Frames) is det.
%
%   Three frames building the grounded length diagram:
%     1. the known whole (the true sum) as a length;
%     2. the rounded overshoot length running past the known whole;
%     3. the adjustment segment that brings the overshoot back to the whole.
length_frames(Data, [F1, F2, F3]) :-
    _{ expected: Expected, result: Rounded, adjustment: Adj,
       known_a: KA, known_b: KB, rounded_a: RA } :< Data,
    Max is max(Expected, Rounded),
    % Frame 1: the known whole.
    whole_bar(Expected, Max, WholeBar),
    format(string(Cap1),
           "The whole is ~w (~w + ~w). Measure it as a length.",
           [Expected, KA, KB]),
    length_frame(1, "establish_known_whole", Cap1, [WholeBar], F1),
    % Frame 2: round one part up; the rounded total overshoots the whole.
    part_bar(KB, Max, len_row(1), "highlight", "known part", KnownPart),
    overshoot_bar(Expected, Rounded, Max, OverBar),
    rounded_whole_bar(Rounded, Max, RoundedWholeBar),
    format(string(Cap2),
           "Round ~w up to ~w, then add ~w: the rounded total ~w runs past the whole.",
           [KA, RA, KB, Rounded]),
    length_frame(2, "round_and_overshoot", Cap2,
                 [WholeBar, KnownPart, RoundedWholeBar, OverBar], F2),
    % Frame 3: count the adjustment back, landing on the whole.
    adjustment_bar(Expected, Rounded, Max, AdjBar),
    format(string(Cap3),
           "Count back the adjustment of ~w: the rounded total ~w lands on the whole ~w.",
           [Adj, Rounded, Expected]),
    length_frame(3, "adjust_back_to_whole", Cap3,
                 [WholeBar, RoundedWholeBar, AdjBar], F3).

%!  def_length_frames(+Def, -Frames) is det.
%
%   The deformation length filmstrip: the same overshoot, but the adjustment
%   segment is the OMITTED compensation drawn against the grounded whole. The
%   final frame shows the rounded total kept as the answer with the omitted
%   segment marked, so the missing compensation is visible as the gap between
%   the deformed result and the grounded whole.
def_length_frames(Def, [F1, F2]) :-
    _{ expected: Expected, result: Rounded, omitted: Omitted,
       known_a: KA, known_b: KB, rounded_a: RA } :< Def,
    Max is max(Expected, Rounded),
    whole_bar(Expected, Max, WholeBar),
    rounded_whole_bar(Rounded, Max, RoundedWholeBar),
    overshoot_bar(Expected, Rounded, Max, OverBar),
    format(string(Cap1),
           "Round ~w up to ~w and add ~w: the rounded total is ~w.",
           [KA, RA, KB, Rounded]),
    length_frame(1, "round_and_overshoot", Cap1,
                 [WholeBar, RoundedWholeBar, OverBar], F1),
    % Frame 2: the adjustment is OMITTED — drawn as the deformation segment
    % against the grounded whole, so the gap is the conservation that was lost.
    omitted_bar(Expected, Rounded, Max, OmitBar),
    format(string(Cap2),
           "The adjustment of ~w is omitted; ~w is kept as the answer. It overshoots the whole ~w by ~w.",
           [Omitted, Rounded, Expected, Omitted]),
    length_frame(2, "omit_adjustment", Cap2,
                 [WholeBar, RoundedWholeBar, OmitBar], F2).

%!  rounding_compare_data(+Op, +A, +B, -Prod, -Def) is semidet.
%   Source both the productive length data and the deformation length data
%   (the latter from misconception_jumps_witness/5) for one input pair.
rounding_compare_data(Op, A, B, Prod, Def) :-
    rounding_length_data(Op, A, B, Prod),
    deformation_rounding_data(Op, A, B, Def).

%!  deformation_rounding_data(+Op, +A, +B, -Def) is semidet.
%   Read the deformation witness: result (the overshoot kept), expected (the
%   grounded whole), and the omitted compensation amount. Reuses the productive
%   components for the known-part / rounded-part labels.
deformation_rounding_data(Op, A, B, Def) :-
    catch(visualization:misconception_jumps_witness(Op, round_without_adjusting, A, B, W),
          _, fail),
    get_dict(result, W, Rounded),
    get_dict(expected, W, Expected),
    get_dict(omitted_jumps, W, OmittedJumps),
    OmittedJumps = [OJ|_],
    get_dict(from, OJ, OFrom),
    get_dict(to, OJ, OTo),
    Omitted is abs(OFrom - OTo),
    productive_rounding_components(Op, A, B, Comp),
    _{ known_a: KA, known_b: KB, rounded_a: RA } :< Comp,
    Def = _{ a: A, b: B, known_a: KA, known_b: KB, rounded_a: RA,
             result: Rounded, expected: Expected, omitted: Omitted }.


% =============================================================================
% Magnitude addition — a scale-broken number line for large whole numbers.
%
% This is intentionally bounded: the addend is one jump on a local axis from A
% to A+B, not hundreds of unit automaton steps.
% =============================================================================

magnitude_addition_frames(A, B, [F1, F2, F3]) :-
    Sum is A + B,
    magnitude_axis(A, Sum, Axis),
    magnitude_marks([A], Marks1),
    magnitude_scene(Axis, [], Marks1, Scene1),
    format(string(Cap1), "Start at ~D on a scale-broken number line.", [A]),
    F1 = _{ step: 1,
            verb: "locate_start",
            caption: Cap1,
            sceneChanged: true,
            scene: Scene1 },
    magnitude_jump(A, Sum, B, Jump),
    magnitude_marks([A, Sum], Marks2),
    magnitude_scene(Axis, [Jump], Marks2, Scene2),
    format(string(Cap2), "Append one jump of +~D to land at ~D.", [B, Sum]),
    F2 = _{ step: 2,
            verb: "append_addend",
            caption: Cap2,
            sceneChanged: true,
            scene: Scene2 },
    magnitude_scene(Axis, [Jump], Marks2, Scene3),
    format(string(Cap3), "~D + ~D = ~D.", [A, B, Sum]),
    F3 = _{ step: 3,
            verb: "read_sum",
            caption: Cap3,
            sceneChanged: true,
            scene: Scene3 }.

magnitude_axis(A, Sum, Axis) :-
    WindowMin is min(A, Sum),
    Max is max(A, Sum),
    % Magnitude additions live far from zero by construction; the axis still
    % anchors at 0 and the break compresses the empty stretch honestly.
    axis_dict(0, Max, [0, WindowMin, Max], break(true, WindowMin), Axis).

magnitude_jump(A, Sum, B,
    _{ from: A, to: Sum, by: B, tier: "magnitude", role: "jump-add" }).

magnitude_marks(Values, Marks) :-
    findall(_{ at: V, label: Label },
            ( member(V, Values),
              format(string(Label), "~D", [V])
            ),
            Marks).

magnitude_scene(Axis, Jumps, Marks,
    _{ format: "number-line",
       version: 2,
       mode: "magnitude-addition",
       axis: Axis,
       jumps: Jumps,
       marks: Marks }).


% =============================================================================
% Fraction iteration on a number line.
%
% Coordinates are integer counts of the current 1/D unit.  The scene carries D
% explicitly, so coordinate K denotes K/D rather than the whole number K.  This
% avoids floating-point coordinates while retaining the fixed referent at D/D.
% =============================================================================

fraction_iteration_frames(N, D, Frames) :-
    integer(N), N > 0,
    integer(D), D > 0,
    WholeCount is max(1, (N + D - 1) // D),
    AxisMax is WholeCount * D,
    numlist(0, AxisMax, Ticks),
    axis_dict(0, AxisMax, Ticks, break(false, 0), Axis),
    fraction_iteration_frames_(1, N, D, Axis, [], Frames).

fraction_iteration_frames_(K, N, _D, _Axis, _RevJumps, []) :-
    K > N,
    !.
fraction_iteration_frames_(K, N, D, Axis, RevJumps0, [Frame | Frames]) :-
    From is K - 1,
    format(string(UnitLabel), "1/~w", [D]),
    Jump = _{ from: From, to: K, by: 1, label: UnitLabel,
              tier: "unit", role: "jump-add" },
    reverse([Jump | RevJumps0], Jumps),
    fraction_iteration_marks(K, D, Marks),
    Scene = _{ format: "number-line",
               version: 2,
               mode: "fraction-jumps",
               coordinateDenominator: D,
               referentWholeAt: D,
               axis: Axis,
               jumps: Jumps,
               marks: Marks },
    format(string(Caption), "Iterate 1/~w to reach ~w/~w.", [D, K, D]),
    format(string(Verb), "iterate_unit_fraction(~w,1/~w)", [K, D]),
    Frame = _{ step: K,
               verb: Verb,
               caption: Caption,
               sceneChanged: true,
               scene: Scene },
    K1 is K + 1,
    fraction_iteration_frames_(K1, N, D, Axis, [Jump | RevJumps0], Frames).

fraction_iteration_marks(K, D, Marks) :-
    findall(_{ at: At, label: Label },
            ( between(0, K, At),
              fraction_landmark(At, K, D),
              fraction_landmark_label(At, D, Label)
            ),
            Marks).

fraction_landmark(0, _K, _D).
fraction_landmark(At, _K, D) :- At > 0, At mod D =:= 0.
fraction_landmark(At, K, D) :- At =:= K, At mod D =\= 0.

fraction_landmark_label(0, _D, "0") :- !.
fraction_landmark_label(K, D, Label) :-
    ( K mod D =:= 0
    -> Whole is K // D,
       format(string(Label), "~w/~w = ~w", [K, D, Whole])
    ;  format(string(Label), "~w/~w", [K, D])
    ).


% =============================================================================
% Length-bar geometry. A value V maps to a width proportional to V/Max of the
% full drawable length. Bars stack downward by row.
% =============================================================================

% len_row(Row) is a wrapper term passed to part_bar/5 to name a length-bar
% row; the y-coordinate is resolved by len_row_y/2.
len_row_y(Row, Y) :-
    len_row_y0(Y0),
    len_bar_h(H),
    len_row_gap(G),
    Y is Y0 + Row * (H + G).

%!  value_width(+V, +Max, -W) is det.
value_width(V, Max, W) :-
    len_unit_w(UW),
    ( Max =< 0 -> W = 0 ; W is (V * UW) // Max ).

%!  whole_bar(+Expected, +Max, -Bar) is det.
%   The known whole as a length at row 0, role whole.
whole_bar(Expected, Max, Bar) :-
    len_x0(X), len_bar_h(H),
    len_row_y(0, Y),
    value_width(Expected, Max, W),
    Bar = _{ x: X, y: Y, w: W, h: H, role: "whole", label: "known whole" }.

%!  part_bar(+Part, +Max, +RowTerm, +Role, +Label, -Bar) is det.
%   A known part length at the given row.
part_bar(Part, Max, len_row(Row), Role, Label, Bar) :-
    len_x0(X), len_bar_h(H),
    len_row_y(Row, Y),
    value_width(Part, Max, W),
    Bar = _{ x: X, y: Y, w: W, h: H, role: Role, label: Label }.

%!  rounded_whole_bar(+Rounded, +Max, -Bar) is det.
%   The full rounded total as a length at row 1.
rounded_whole_bar(Rounded, Max, Bar) :-
    len_x0(X), len_bar_h(H),
    len_row_y(1, Y),
    value_width(Rounded, Max, W),
    Bar = _{ x: X, y: Y, w: W, h: H, role: "deformation", label: "rounded total" }.

%!  overshoot_bar(+Expected, +Rounded, +Max, -Bar) is det.
%   The overshoot segment: the part of the rounded total beyond the whole.
%   Positioned at the whole's right edge, role deformation.
overshoot_bar(Expected, Rounded, Max, Bar) :-
    len_x0(X0), len_bar_h(H),
    len_row_y(1, Y),
    value_width(Expected, Max, WW),
    StartX is X0 + WW,
    Over is max(0, Rounded - Expected),
    value_width(Over, Max, W),
    Bar = _{ x: StartX, y: Y, w: W, h: H, role: "deformation", label: "rounded overshoot" }.

%!  adjustment_bar(+Expected, +Rounded, +Max, -Bar) is det.
%   The grounded adjustment segment counted back, role iterated. Drawn over the
%   overshoot region at row 2 so it reads as the move that lands on the whole.
adjustment_bar(Expected, Rounded, Max, Bar) :-
    len_x0(X0), len_bar_h(H),
    len_row_y(2, Y),
    value_width(Expected, Max, WW),
    StartX is X0 + WW,
    Over is max(0, Rounded - Expected),
    value_width(Over, Max, W),
    Bar = _{ x: StartX, y: Y, w: W, h: H, role: "iterated", label: "adjustment" }.

%!  omitted_bar(+Expected, +Rounded, +Max, -Bar) is det.
%   The OMITTED compensation segment: the same region as the adjustment, but
%   role deformation, marking the conservation the deformation dropped.
omitted_bar(Expected, Rounded, Max, Bar) :-
    len_x0(X0), len_bar_h(H),
    len_row_y(2, Y),
    value_width(Expected, Max, WW),
    StartX is X0 + WW,
    Over is max(0, Rounded - Expected),
    value_width(Over, Max, W),
    Bar = _{ x: StartX, y: Y, w: W, h: H, role: "deformation", label: "omitted adjustment" }.

%!  length_frame(+Step, +Verb, +Caption, +Bars, -Frame) is det.
length_frame(Step, Verb, Caption, Bars, Frame) :-
    Scene = _{ format: "number-line",
               version: 2,
               mode: "length",
               bars: Bars },
    term_to_string(Verb, VerbStr),
    Frame = _{ step: Step,
               verb: VerbStr,
               caption: Caption,
               sceneChanged: true,
               scene: Scene }.


% =============================================================================
% Notes and captions.
% =============================================================================

rounding_note(grounded,
  "Rounding then adjusting keeps the total: the overshoot is counted back so the answer lands on the whole.").

compare_note(_Op, A, B, Result, Expected, Omitted, Note) :-
    format(string(Note),
           "The grounded scheme rounds ~w + ~w, overshoots to ~w, then counts back ~w to land on ~w. \
Dropping the adjustment keeps ~w as the answer, losing the ~w of conservation. \
The same overshoot, drawn against the whole, shows the missing compensation as the gap. \
(Rounding-without-compensation family.)",
           [A, B, Result, Omitted, Expected, Result, Omitted]).


% =============================================================================
% Generators for number_line_render_frames/2 (frames-only entry point).
% =============================================================================

gen_frames(jumps(Strategy, A, B), Frames) :-
    base_default(Base),
    strategy_jump_data(Strategy, A, B, _Result, Jumps),
    Jumps \== [],
    !,
    jumps_frames(Jumps, Base, Frames).
gen_frames(rounding_length(Op, A, B), Frames) :-
    rounding_length_data(Op, A, B, Data),
    !,
    length_frames(Data, Frames).
gen_frames(magnitude_addition(A, B), Frames) :-
    !,
    magnitude_addition_frames(A, B, Frames).
gen_frames(fraction_iteration(N, D), Frames) :-
    !,
    recursive_unit_actions:fraction_unit_plan(N, D, Plan),
    recursive_unit_actions:run_unit_plan(Plan, _, _),
    fraction_iteration_frames(N, D, Frames).


% =============================================================================
% Shared helpers.
% =============================================================================

%!  deferred_frame(+Spec, -Frame) is det.
%   An undrawable spec is annotation-only: an empty scene, no throw.
deferred_frame(Spec, Frame) :-
    term_to_string(Spec, SpecStr),
    format(string(Cap), "No number-line trace for ~w; nothing drawn.", [SpecStr]),
    Scene = _{ format: "number-line", version: 2, mode: "jumps",
               axis: _{ min: 0, max: 0, ticks: [], scaleBreak: false, breakEnd: 0 },
               jumps: [], marks: [] },
    Frame = _{ step: 1,
               verb: SpecStr,
               caption: Cap,
               sceneChanged: false,
               scene: Scene }.

%!  canvas_dict(-Canvas) is det.
canvas_dict(_{ width: 720, height: 320 }).

%!  term_to_string(+Term, -String) is det.
term_to_string(Term, String) :-
    ( string(Term)
    -> String = Term
    ;  format(string(String), '~w', [Term])
    ).
