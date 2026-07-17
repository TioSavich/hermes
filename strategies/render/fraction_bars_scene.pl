/** <module> Fraction-bars scene compiler
 *
 * Compiles a productive fraction automaton's trace into a sequence of
 * fraction-bar scene frames in the upstream "Fraction Bars" v2 save schema.
 * The direction is Prolog -> picture: an automaton runs (via
 * `fraction_action_pairs:run_fraction_action/5`), its flat verb trace is
 * walked, and each high-level verb is mapped to a scene effect on a canvas of
 * bar dicts. Geometry (equal-part split widths) is computed here in Prolog,
 * so the picture is genuinely produced by the Prolog side.
 *
 * Frames are valid v2 scene objects (`format:"fraction-bars"`, version 2),
 * so they can be fed to the upstream tool's loadState unchanged and the
 * return trip (bars -> analysis) stays open by construction.
 *
 * Scope: the productive slice (partition, iteration, splitting, recursive
 * partition). The compiler does not hard-fail on a deferred kind — verbs it
 * does not map are emitted annotation-only (`sceneChanged:false`, scene
 * unchanged) so the filmstrip narrates without throwing.
 *
 * Render contract: docs/render-contract-v2.md
 */

:- module(fraction_bars_scene,
          [ fraction_render_frames/4,   % +Kind, +Count, +Base, -Frames
            fraction_render_json/4,      % +Kind, +Count, +Base, -Dict
            fraction_plan_render_json/2, % +UnitPlan, -Dict
            fraction_scene_plan/3,       % +Scene, -UnitPlan, -Evidence
            fraction_scene_validation/5,
            fraction_render_to_file/4,   % +Kind, +Count, +Base, +Path
            fraction_arith_frames/6,     % +Op, +NumA, +DenA, +NumB, +DenB, -Frames
            fraction_arith_json/6,       % +Op, +NumA, +DenA, +NumB, +DenB, -Dict
            fraction_componentwise_add_json/5,
            fraction_compare_json/4      % +ProductiveKind, +A, +B, -Dict
          ]).

:- use_module(strategies(math/fraction_action_pairs),
              [ run_fraction_action/5,
                productive_fraction_deformation/3
              ]).
:- use_module(strategies(math/divaded_fractional_units),
              [ add_fractions_by_co_measurement/7,
                subtract_fractions_by_co_measurement/7
              ]).
:- use_module(formalization(grounded_arithmetic),
              [ integer_to_recollection/2,
                recollection_to_integer/2
              ]).
:- use_module(math(recursive_unit_actions), []).
:- use_module(library(http/json), [json_write_dict/3]).
:- use_module(library(lists)).

% -----------------------------------------------------------------------------
% Geometry constants (from the spec). UnitW=420 = 2^2*3*5*7 divides evenly for
% denominators 2-7, 10, 12, 14, 15 so split widths stay integral for common
% cases. Stacked bars step down by BarH + RowGap.
% -----------------------------------------------------------------------------
unit_x(40).
unit_y(40).
unit_w(420).
bar_h(48).
row_gap(24).

% Row y-coordinate for the Nth bar row (0-based). The unit bar sits at row 0.
row_y(Row, Y) :-
    unit_y(Y0),
    bar_h(H),
    row_gap(G),
    Y is Y0 + Row * (H + G).

% Semantic color roles. The drawer maps these to token CSS variables.
color_whole(whole).           % whole / unit bar fill
color_highlight(highlight).   % highlighted unit-fraction part
color_iterated(iterated).     % iterated copies
color_inner(inner).           % inner (recursive) part


%!  fraction_render_frames(+Kind, +Count, +Base, -Frames) is det.
%
%   Run the automaton for Kind/Count/Base and walk its trace into a list of
%   frame dicts. Succeeds with whatever frames the verb table can map; a
%   deferred or failing automaton yields an empty (or annotation-only) list
%   rather than throwing.
fraction_render_frames(Kind, Count, Base, Frames) :-
    ( run_fraction_action(Kind, Count, Base, _Outcome, Trace)
    -> true
    ;  Trace = []
    ),
    walk_trace(Trace, [], 0, Frames).

%!  walk_trace(+Verbs, +Canvas, +StepIn, -Frames) is det.
%
%   Fold over the flat trace. Each verb either updates the canvas (a list of
%   bar dicts) and snapshots a frame, or is skipped (nested kernel sub-trace),
%   or is rendered annotation-only.
walk_trace([], _Canvas, _Step, []).
walk_trace([Verb|Rest], Canvas0, Step0, Frames) :-
    ( skip_verb(Verb)
    -> Frames = FramesRest,
       Canvas1 = Canvas0,
       Step1 = Step0
    ;  Step1 is Step0 + 1,
       apply_verb(Verb, Canvas0, Canvas1, Changed),
       verb_caption(Verb, Caption),
       scene_dict(Canvas1, Scene),
       term_to_string(Verb, VerbStr),
       Frame = _{ step: Step1,
                  verb: VerbStr,
                  caption: Caption,
                  sceneChanged: Changed,
                  scene: Scene },
       Frames = [Frame|FramesRest]
    ),
    walk_trace(Rest, Canvas1, Step1, FramesRest).


%!  skip_verb(+Verb) is semidet.
%
%   Verbs that carry only a nested kernel sub-trace are skipped in v1 — they
%   are nested detail, not a high-level scene step.
skip_verb(kernel_trace(_)).
skip_verb(partition_trace(_)).
skip_verb(iterate_trace(_)).
skip_verb(recursive_partition_trace(_)).
skip_verb(solve_trace(_)).


% -----------------------------------------------------------------------------
% Verb -> scene effect. Each clause maps a high-level trace verb to a canvas
% update and a boolean Changed flag. Mapped verbs that move bars set
% Changed=true; annotation-only verbs set Changed=false and leave the canvas
% unchanged. Any verb with no clause here falls through to the catch-all,
% which is annotation-only — so nothing ever throws.
% -----------------------------------------------------------------------------

%!  apply_verb(+Verb, +Canvas0, -Canvas1, -Changed) is det.

% Establish the referent whole: a single unit bar with no splits.
apply_verb(establish_referent_whole(_), _Canvas0, Canvas1, true) :-
    !,
    unit_bar(Bar),
    Canvas1 = [Bar].

% Partition the whole into D equal splits.
apply_verb(partition_whole_into_equal_units(D), Canvas0, Canvas1, true) :-
    integer(D), D >= 1,
    !,
    ensure_unit_bar(Canvas0, Canvas1a, Bar0),
    partition_bar(Bar0, D, color_whole, Bar1),
    replace_unit_bar(Canvas1a, Bar1, Canvas1).

% Select one part as the unit fraction 1/D: recolor split 0 to highlight.
apply_verb(select_one_partition_as_unit_fraction(fraction(_, _)), Canvas0, Canvas1, true) :-
    !,
    ensure_unit_bar(Canvas0, Canvas1a, Bar0),
    highlight_split(Bar0, 0, Bar1),
    replace_unit_bar(Canvas1a, Bar1, Canvas1).

% Disembed the unit fraction 1/D: add a bar one row below of width UnitW/D.
apply_verb(disembed_unit_fraction(fraction(1, D)), Canvas0, Canvas1, true) :-
    integer(D), D >= 1,
    !,
    unit_w(UW),
    W is UW // D,
    next_row(Canvas0, Row),
    fraction_label(1, D, Label),
    part_bar(Row, W, 1, color_highlight, Label, Bar),
    append(Canvas0, [Bar], Canvas1).

% Recover the unit fraction 1/D: ensure the 1/D part bar exists.
apply_verb(recover_unit_fraction(fraction(1, D)), Canvas0, Canvas1, Changed) :-
    integer(D), D >= 1,
    !,
    fraction_label(1, D, Label),
    ( bar_with_label(Canvas0, Label, _)
    -> Canvas1 = Canvas0, Changed = false
    ;  unit_w(UW),
       W is UW // D,
       next_row(Canvas0, Row),
       part_bar(Row, W, 1, color_highlight, Label, Bar),
       append(Canvas0, [Bar], Canvas1),
       Changed = true
    ).

% Iterate 1/D N times to make N/D: add/replace a bar one row below of width
% N*UnitW/D with N equal splits and label N/D.
apply_verb(iterate_unit_fraction(N, fraction(1, D), _Result), Canvas0, Canvas1, true) :-
    integer(N), integer(D), D >= 1,
    !,
    iterated_bar(Canvas0, N, D, Canvas1).

% Iterate back to the whole (N=D): width UnitW, D splits, label D/D.
apply_verb(iterate_unit_fraction_back_to_whole(D, fraction(1, D)), Canvas0, Canvas1, true) :-
    integer(D), D >= 1,
    !,
    iterated_bar(Canvas0, D, D, Canvas1).

% Partition that part again into Inner equal parts: split the disembedded
% part bar (the most recent part bar) into Inner pieces.
apply_verb(partition_that_part_again(Inner), Canvas0, Canvas1, true) :-
    integer(Inner), Inner >= 1,
    !,
    last_part_bar(Canvas0, Idx, Bar0),
    partition_bar(Bar0, Inner, color_highlight, Bar1),
    replace_at(Canvas0, Idx, Bar1, Canvas1).

% Name the part of a part 1/C: recolor the inner part and label it 1/C.
apply_verb(name_part_of_part_relative_to_whole(fraction(1, C)), Canvas0, Canvas1, true) :-
    integer(C), C >= 1,
    !,
    last_part_bar(Canvas0, Idx, Bar0),
    fraction_label(1, C, Label),
    recolor_splits(Bar0, color_inner, BarRecolored),
    set_label(BarRecolored, Label, Bar1),
    replace_at(Canvas0, Idx, Bar1, Canvas1).

% Catch-all: annotation-only. Canvas unchanged, Changed=false. This is also
% how the explicitly annotation-only verbs (preserve_inside_and_iterable_status,
% recognize_partition_iterate_as_mutual_inverse, coordinate_...,
% recover_whole, open_improper_fraction_domain,
% recognize_composite_base_as_product) and any unmapped verb are handled, so
% nothing ever throws.
apply_verb(_Verb, Canvas, Canvas, false).


% -----------------------------------------------------------------------------
% Bar construction and canvas manipulation. Bars are SWI dicts so
% json_write_dict serializes them directly.
% -----------------------------------------------------------------------------

%!  unit_bar(-Bar) is det.
%   The whole / unit bar, no splits.
unit_bar(Bar) :-
    unit_x(X), unit_y(Y), unit_w(W), bar_h(H),
    color_whole(Role),
    Bar = _{ x: X, y: Y, w: W, h: H, size: W,
             role: Role, isUnitBar: true, fraction: "1/1",
             label: "", type: "bar", splits: [] }.

%!  part_bar(+Row, +W, +Splits, +ColorPred, +Label, -Bar) is det.
%   A non-unit (disembedded / iterated) bar at the given row with Splits equal
%   parts of width W/Splits each.
part_bar(Row, W, Splits, ColorPred, Label, Bar) :-
    unit_x(X), bar_h(H),
    row_y(Row, Y),
    call(ColorPred, Role),
    make_splits(Splits, 0, W, H, Role, SplitList),
    Bar = _{ x: X, y: Y, w: W, h: H, size: W,
             role: Role, isUnitBar: false, fraction: Label,
             label: Label, type: "bar", splits: SplitList }.

%!  partition_bar(+Bar0, +D, +ColorPred, -Bar1) is det.
%   Give Bar0 exactly D equal splits across its full width, each filled with
%   the color from ColorPred.
partition_bar(Bar0, D, ColorPred, Bar1) :-
    W = Bar0.w,
    H = Bar0.h,
    call(ColorPred, Role),
    make_splits(D, 0, W, H, Role, SplitList),
    Bar1 = Bar0.put(splits, SplitList).

%!  make_splits(+Count, +XPos, +TotalW, +H, +Role, -Splits) is det.
%   Build Count equal splits spanning TotalW starting at x=XPos. Each split is
%   TotalW//Count wide; the last split absorbs any integer remainder so the
%   splits exactly tile the bar width.
make_splits(Count, XPos, TotalW, H, Role, Splits) :-
    SplitW is TotalW // Count,
    EndX is XPos + TotalW,
    make_splits_(Count, XPos, SplitW, EndX, H, Role, Splits).

make_splits_(0, _XPos, _SplitW, _EndX, _H, _Role, []) :- !.
make_splits_(Count, XPos, SplitW, EndX, H, Role, [Split|Rest]) :-
    Count >= 1,
    ( Count =:= 1
    -> ThisW is EndX - XPos              % last split takes the remainder
    ;  ThisW = SplitW
    ),
    Split = _{ x: XPos, y: 0, w: ThisW, h: H, role: Role },
    NextX is XPos + ThisW,
    Count1 is Count - 1,
    make_splits_(Count1, NextX, SplitW, EndX, H, Role, Rest).

%!  iterated_bar(+Canvas0, +N, +D, -Canvas1) is det.
%   Add (or replace) a one-row-below bar of width N*UnitW/D with N equal
%   splits, color iterated, label N/D, aligned at UnitX.
iterated_bar(Canvas0, N, D, Canvas1) :-
    unit_w(UW),
    W is (N * UW) // D,
    fraction_label(N, D, Label),
    ( select_bar_by_kind(Canvas0, iterated, Idx, Bar0)
    -> Row = Bar0.row,
       build_iterated_bar(Row, W, N, Label, Bar1),
       replace_at(Canvas0, Idx, Bar1, Canvas1)
    ;  next_row(Canvas0, Row),
       build_iterated_bar(Row, W, N, Label, Bar1),
       append(Canvas0, [Bar1], Canvas1)
    ).

build_iterated_bar(Row, W, N, Label, Bar) :-
    unit_x(X), bar_h(H),
    row_y(Row, Y),
    color_iterated(Role),
    make_splits(N, 0, W, H, Role, SplitList),
    Bar = _{ x: X, y: Y, w: W, h: H, size: W,
             role: Role, isUnitBar: false, fraction: Label,
             label: Label, type: "bar", splits: SplitList,
             row: Row, kind: iterated }.

%!  highlight_split(+Bar0, +Idx, -Bar1) is det.
%   Recolor split Idx of Bar0 to the highlight color.
highlight_split(Bar0, Idx, Bar1) :-
    Splits0 = Bar0.splits,
    color_highlight(Role),
    nth0(Idx, Splits0, Split0),
    Split1 = Split0.put(role, Role),
    replace_at(Splits0, Idx, Split1, Splits1),
    Bar1 = Bar0.put(splits, Splits1).

%!  recolor_splits(+Bar0, +ColorPred, -Bar1) is det.
%   Recolor every split of Bar0.
recolor_splits(Bar0, ColorPred, Bar1) :-
    Splits0 = Bar0.splits,
    call(ColorPred, Role),
    maplist([S0, S1]>>(S1 = S0.put(role, Role)), Splits0, Splits1),
    Bar1 = Bar0.put(splits, Splits1).

%!  set_label(+Bar0, +Label, -Bar1) is det.
set_label(Bar0, Label, Bar1) :-
    Bar1 = Bar0.put(label, Label).put(fraction, Label).

%!  ensure_unit_bar(+Canvas0, -Canvas1, -UnitBar) is det.
%   Guarantee the canvas has a unit bar at index 0; return it.
ensure_unit_bar([], [Bar], Bar) :- !, unit_bar(Bar).
ensure_unit_bar([Bar0|Rest], [Bar0|Rest], Bar0) :-
    is_unit_bar(Bar0), !.
ensure_unit_bar(Canvas0, Canvas1, Bar) :-
    unit_bar(Bar),
    Canvas1 = [Bar|Canvas0].

is_unit_bar(Bar) :- get_dict(isUnitBar, Bar, true).

%!  replace_unit_bar(+Canvas0, +Bar, -Canvas1) is det.
%   Replace the unit bar (index 0) with Bar.
replace_unit_bar([_Old|Rest], Bar, [Bar|Rest]).

%!  next_row(+Canvas, -Row) is det.
%   The next free row index = number of bars currently on the canvas.
next_row(Canvas, Row) :-
    length(Canvas, Row).

%!  last_part_bar(+Canvas, -Index, -Bar) is det.
%   The most recently added non-unit bar.
last_part_bar(Canvas, Index, Bar) :-
    findall(I-B,
            ( nth0(I, Canvas, B),
              \+ is_unit_bar(B)
            ),
            Pairs),
    Pairs \= [],
    last(Pairs, Index-Bar).

%!  select_bar_by_kind(+Canvas, +Kind, -Index, -Bar) is semidet.
select_bar_by_kind(Canvas, Kind, Index, Bar) :-
    nth0(Index, Canvas, Bar),
    get_dict(kind, Bar, Kind),
    !.

%!  bar_with_label(+Canvas, +Label, -Bar) is semidet.
bar_with_label(Canvas, Label, Bar) :-
    member(Bar, Canvas),
    get_dict(label, Bar, Label),
    Label \== "",
    !.

%!  replace_at(+List, +Index, +Elem, -List1) is det.
replace_at(List, Index, Elem, List1) :-
    nth0(Index, List, _Old, Rest),
    nth0(Index, List1, Elem, Rest).

%!  fraction_label(+N, +D, -Label) is det.
%   "N/D" as a string.
fraction_label(N, D, Label) :-
    format(atom(A), '~w/~w', [N, D]),
    atom_string(A, Label).


% -----------------------------------------------------------------------------
% Scene assembly. Strip the bookkeeping keys (row, kind) so the emitted scene
% is a clean v2 object.
% -----------------------------------------------------------------------------

%!  scene_dict(+Canvas, -Scene) is det.
scene_dict(Canvas, Scene) :-
    maplist(clean_bar, Canvas, Bars),
    Scene = _{ format: "fraction-bars",
               version: 2,
               unitBarIndex: 0,
               mats: [],
               bars: Bars }.

%!  clean_bar(+Bar0, -Bar1) is det.
%   Drop the internal bookkeeping keys so the bar is a valid v2 bar object.
clean_bar(Bar0, Bar1) :-
    ( del_dict(row, Bar0, _, Bar1a) -> true ; Bar1a = Bar0 ),
    ( del_dict(kind, Bar1a, _, Bar1) -> true ; Bar1 = Bar1a ).


% -----------------------------------------------------------------------------
% Captions. Plain prose; no overclaiming. Mirrors the spec's caption column.
% -----------------------------------------------------------------------------

%!  verb_caption(+Verb, -Caption) is det.
verb_caption(establish_referent_whole(_), "Establish the referent whole.") :- !.
verb_caption(partition_whole_into_equal_units(D), Caption) :- !,
    format(string(Caption), "Partition the whole into ~w equal parts.", [D]).
verb_caption(select_one_partition_as_unit_fraction(fraction(N, D)), Caption) :- !,
    format(string(Caption), "Select one part as the unit fraction ~w/~w.", [N, D]).
verb_caption(preserve_inside_and_iterable_status(_),
             "Keep the part inside the whole and iterable.") :- !.
verb_caption(disembed_unit_fraction(fraction(N, D)), Caption) :- !,
    format(string(Caption), "Disembed the unit fraction ~w/~w.", [N, D]).
verb_caption(recover_unit_fraction(fraction(N, D)), Caption) :- !,
    format(string(Caption), "Recover the unit fraction ~w/~w.", [N, D]).
verb_caption(iterate_unit_fraction(N, fraction(1, D), _), Caption) :- !,
    format(string(Caption), "Iterate 1/~w ~w times to make ~w/~w.", [D, N, N, D]).
verb_caption(iterate_unit_fraction_back_to_whole(D, fraction(1, D)), Caption) :- !,
    format(string(Caption), "Iterate 1/~w back ~w times to recover the whole.", [D, D]).
verb_caption(recognize_partition_iterate_as_mutual_inverse(fraction(1, D), D), Caption) :- !,
    format(string(Caption), "Partition and iteration are inverses: 1/~w x ~w = 1.", [D, D]).
verb_caption(coordinate_iteration_with_completion_marker(fraction(D, D), Rel), Caption) :- !,
    format(string(Caption), "Coordinate with the completion marker ~w/~w (~w).", [D, D, Rel]).
verb_caption(recover_whole(_), "The whole is recovered.") :- !.
verb_caption(open_improper_fraction_domain, "The improper-fraction domain is now open.") :- !.
verb_caption(partition_that_part_again(Inner), Caption) :- !,
    format(string(Caption), "Partition that part again into ~w equal parts.", [Inner]).
verb_caption(name_part_of_part_relative_to_whole(fraction(N, C)), Caption) :- !,
    format(string(Caption), "Name the part of a part: ~w/~w of the whole.", [N, C]).
verb_caption(recognize_composite_base_as_product(O, I, C), Caption) :- !,
    format(string(Caption), "The composite base is ~w x ~w = ~w.", [O, I, C]).
% Default: humanize the verb functor (replace underscores with spaces).
verb_caption(Verb, Caption) :-
    humanize_verb(Verb, Caption).

%!  humanize_verb(+Verb, -Caption) is det.
%   Functor name with underscores -> spaces, capitalized, period.
humanize_verb(Verb, Caption) :-
    ( compound(Verb)
    -> functor(Verb, Name, _)
    ;  Name = Verb
    ),
    atom_string(Name, NameStr),
    split_string(NameStr, "_", "", Words),
    atomic_list_concat(Words, " ", Phrase),
    string_chars(Phrase, [First|Chars]),
    upcase_atom(First, FirstUp),
    string_chars(Capped, [FirstUp|Chars]),
    string_concat(Capped, ".", Caption).


% -----------------------------------------------------------------------------
% JSON assembly.
% -----------------------------------------------------------------------------

%!  fraction_render_json(+Kind, +Count, +Base, -Dict) is det.
%
%   Assemble the full frame document: kind / request / result / canvas /
%   frames per the render contract.
fraction_render_json(unit_fraction_iteration, Count, Base, Dict) :-
    !,
    ( recursive_unit_actions:fraction_unit_plan(Count, Base, Plan),
      fraction_plan_render_json(Plan, Dict)
    -> true
    ;  fraction_render_json_from_action(unit_fraction_iteration, Count, Base,
                                        Dict)
    ).
fraction_render_json(Kind, Count, Base, Dict) :-
    fraction_render_json_from_action(Kind, Count, Base, Dict).

fraction_render_json_from_action(Kind, Count, Base, Dict) :-
    ( run_fraction_action(Kind, Count, Base, Outcome, _Trace)
    -> outcome_result(Outcome, ResultStr)
    ;  ResultStr = "failed"
    ),
    fraction_render_frames(Kind, Count, Base, Frames),
    term_to_string(Kind, KindStr),
    request_dict(Kind, Count, Base, Request),
    canvas_dict(Canvas),
    Dict = _{ kind: KindStr,
              request: Request,
              result: ResultStr,
              canvas: Canvas,
              frames: Frames }.


%!  fraction_plan_render_json(+UnitPlan, -Dict) is semidet.
%
%   Compile a recursive partition-and-iterate plan through the existing
%   fraction renderer while retaining exact value and inscription projections.
fraction_plan_render_json(Plan, Dict) :-
    Plan = plan(unit(whole), [partition(D)], iterate(N)),
    recursive_unit_actions:run_unit_plan(Plan, Quantity, ActionTrace),
    Quantity = quantity(raw_value(fraction(N, D)),
                        canonical_value(fraction(CN, CD)), _, _, _, _),
    fraction_render_json_from_action(unit_fraction_iteration, N, D, BaseDict),
    fraction_inscription_base(D, InscriptionBase),
    recursive_unit_actions:unit_plan_numeral(Plan, InscriptionBase, Numeral),
    recursive_unit_actions:numeral_text(Numeral, NumeralText),
    recursive_unit_actions:plan_dict(Plan, PlanDict),
    maplist(term_to_string, ActionTrace, TraceStrings),
    Dict = BaseDict.put(_{
        request: BaseDict.request.put(unitPlan, PlanDict.plan),
        valueSemantics: _{
            rawNumerator: N, rawDenominator: D,
            canonicalNumerator: CN, canonicalDenominator: CD
        },
        inscription: _{base: InscriptionBase, text: NumeralText},
        actionTrace: TraceStrings
    }).


%!  fraction_scene_plan(+Scene, -Plan, -Evidence) is semidet.
%
%   Reconstruct N/D from bar geometry, not from its displayed fraction label.
fraction_scene_plan(Scene, Plan, Evidence) :-
    get_dict(bars, Scene, Bars),
    member(UnitBar, Bars),
    get_dict(isUnitBar, UnitBar, true),
    get_dict(w, UnitBar, UnitWidth),
    denominator_from_scene_bars(Bars, UnitBar, UnitWidth, D),
    last(Bars, IteratedBar),
    get_dict(isUnitBar, IteratedBar, false),
    get_dict(splits, IteratedBar, IteratedSplits),
    length(IteratedSplits, N),
    N > 0,
    get_dict(w, IteratedBar, IteratedWidth),
    GeometryError is abs(IteratedWidth * D - UnitWidth * N),
    GeometryError =< D,
    recursive_unit_actions:fraction_unit_plan(N, D, Plan),
    Evidence = scene_recollection(
                   denominator_from_whole_splits(D),
                   numerator_from_iterated_splits(N),
                   proportional_width_error(GeometryError),
                   referent_bar_width(UnitWidth)),
    !.

denominator_from_scene_bars(_Bars, UnitBar, _UnitWidth, D) :-
    get_dict(splits, UnitBar, UnitSplits),
    length(UnitSplits, D),
    D > 0,
    !.
denominator_from_scene_bars(Bars, _UnitBar, UnitWidth, D) :-
    member(UnitPart, Bars),
    get_dict(isUnitBar, UnitPart, false),
    get_dict(w, UnitPart, PartWidth),
    PartWidth > 0,
    D is round(UnitWidth / PartWidth),
    D > 0,
    abs(UnitWidth - D * PartWidth) =< D,
    !.


%!  fraction_scene_validation(+ExpectedN, +ExpectedD, +Scene,
%                             -Plan, -Validation) is det.
fraction_scene_validation(ExpectedN, ExpectedD, Scene, Plan, Validation) :-
    (   fraction_scene_plan(Scene, Plan0, Evidence)
    ->  Plan = Plan0,
        recursive_unit_actions:validate_fraction_candidate(
            ExpectedN, ExpectedD, Plan0, Verdict),
        Validation = scene_validation(Verdict, Evidence)
    ;   Plan = plan(unit(whole), [], iterate(1)),
        Validation = scene_validation(
                         unsupported(scene_does_not_recollect_fraction_plan),
                         no_geometry_evidence)
    ).

fraction_inscription_base(1, 10) :- !.
fraction_inscription_base(Denominator, Denominator).

%!  outcome_result(+Outcome, -ResultStr) is det.
%   Extract the result/1 field from the action outcome, as a string.
outcome_result(action_outcome(_Kind, Fields), ResultStr) :-
    ( member(result(R), Fields)
    -> term_to_string(R, ResultStr)
    ;  ResultStr = "unknown"
    ).
outcome_result(_, "unknown").

%!  request_dict(+Kind, +Count, +Base, -Request) is det.
request_dict(Kind, Count, Base, Request) :-
    term_to_string(Kind, KindStr),
    request_value(Count, CountV),
    request_value(Base, BaseV),
    Request = _{ kind: KindStr, count: CountV, base: BaseV }.

%   Integers pass through as numbers; compound terms become strings.
request_value(V, V) :- integer(V), !.
request_value(V, S) :- term_to_string(V, S).

%!  canvas_dict(-Canvas) is det.
%   Advisory canvas size; the viewer may auto-fit the viewBox.
canvas_dict(_{ width: 700, height: 320 }).

%!  term_to_string(+Term, -String) is det.
%   Canonical, quoted, operator-free string of a Prolog term, suitable for a
%   JSON string field.
term_to_string(Term, String) :-
    ( string(Term)
    -> String = Term
    ;  format(string(String), '~w', [Term])
    ).


%!  fraction_render_to_file(+Kind, +Count, +Base, +Path) is det.
%
%   Render the frame document and write it as pretty-printed JSON to Path.
fraction_render_to_file(Kind, Count, Base, Path) :-
    fraction_render_json(Kind, Count, Base, Dict),
    setup_call_cleanup(
        open(Path, write, Stream),
        json_write_dict(Stream, Dict, [width(80)]),
        close(Stream)).


% =============================================================================
% Binary fraction arithmetic as bars (the interactive-calculator path).
%
% Op = add | sub. Both run the productive co-measurement automaton in
% divaded_fractional_units (NOT a same-denominator shortcut): the two
% fractions are re-measured in a shared unit (the common denominator) and
% then joined or removed. The frames show exactly that move — the two
% addends, both re-measured in Sths, and the joined/removed result — which is
% the spatial payoff for unlike denominators (1/3 + 1/4 -> 4/12 + 3/12 = 7/12).
%
% Multiplication and division are out of this slice: the area model is 2-D and
% measurement division reads differently as bars. fraction_arith_json/6 returns
% an explicit, honest error for any Op it does not draw, so the UI degrades
% rather than faking a picture.
% =============================================================================

%!  fraction_arith_frames(+Op, +NumA, +DenA, +NumB, +DenB, -Frames) is semidet.
%
%   Build the filmstrip for Op applied to NumA/DenA and NumB/DenB. Fails when
%   the underlying co-measurement automaton fails (e.g. a subtraction whose
%   result would be negative — that cannot be shown as a bar).
fraction_arith_frames(Op, NumA, DenA, NumB, DenB, Frames) :-
    co_measure_op(Op, NumA, DenA, NumB, DenB, S, MA, MB, RC),
    color_highlight(CA),
    color_iterated(CB),
    op_symbol(Op, Sym),
    % Frame 1 — the two fractions in their own parts.
    colors_run(DenA, [run(0, NumA, CA)], ColA),
    colors_run(DenB, [run(0, NumB, CB)], ColB),
    fraction_label(NumA, DenA, LabA),
    fraction_label(NumB, DenB, LabB),
    whole_split_bar(0, DenA, ColA, LabA, BarA),
    whole_split_bar(1, DenB, ColB, LabB, BarB),
    scene_dict_multi([BarA, BarB], Scene1),
    format(string(Cap1), "~w ~w ~w. The parts are different sizes.", [LabA, Sym, LabB]),
    % Frame 2 — both re-measured in the shared unit 1/S.
    colors_run(S, [run(0, MA, CA)], ColAS),
    colors_run(S, [run(0, MB, CB)], ColBS),
    fraction_label(MA, S, LabAS),
    fraction_label(MB, S, LabBS),
    whole_split_bar(0, S, ColAS, LabAS, BarAS),
    whole_split_bar(1, S, ColBS, LabBS, BarBS),
    scene_dict_multi([BarAS, BarBS], Scene2),
    format(string(Cap2), "Measure both in ~wths: ~w = ~w and ~w = ~w.",
           [S, LabA, LabAS, LabB, LabBS]),
    % Frame 3 — join (add) or remove (sub) the shared ticks.
    fraction_label(RC, S, LabR),
    result_scene(Op, S, MA, MB, RC, CA, CB, LabR, Scene3),
    result_caption(Op, LabAS, LabBS, LabR, Cap3),
    Frames = [ _{ step: 1, verb: "show_addends", caption: Cap1,
                  sceneChanged: true, scene: Scene1 },
               _{ step: 2, verb: "co_measure_in_shared_unit", caption: Cap2,
                  sceneChanged: true, scene: Scene2 },
               _{ step: 3, verb: "combine_shared_ticks", caption: Cap3,
                  sceneChanged: true, scene: Scene3 } ].

%!  co_measure_op(+Op, +NA, +DA, +NB, +DB, -S, -MA, -MB, -RC) is semidet.
%   Run the productive co-measurement automaton and pull out integers: shared
%   base S, first measured count MA, second MB, result count RC.
co_measure_op(add, NA, DA, NB, DB, S, MA, MB, RC) :-
    to_rec(NA, RA), to_rec(DA, RDA), to_rec(NB, RB), to_rec(DB, RDB),
    add_fractions_by_co_measurement(RA, RDA, RB, RDB, mc3,
                                    fraction_sum_state(_, F), _),
    member(co_measurement(fraction(_, RS)), F),
    member(first_as(fraction(RMA, RS)), F),
    member(second_as(fraction(RMB, RS)), F),
    member(result_fraction(fraction(RRC, RS)), F),
    to_int(RS, S), to_int(RMA, MA), to_int(RMB, MB), to_int(RRC, RC).
co_measure_op(sub, NA, DA, NB, DB, S, MA, MB, RC) :-
    to_rec(NA, RA), to_rec(DA, RDA), to_rec(NB, RB), to_rec(DB, RDB),
    subtract_fractions_by_co_measurement(RA, RDA, RB, RDB, mc3,
                                         fraction_difference_state(_, F), _),
    member(co_measurement(fraction(_, RS)), F),
    member(minuend_as(fraction(RMA, RS)), F),
    member(subtrahend_as(fraction(RMB, RS)), F),
    member(result_fraction(fraction(RRC, RS)), F),
    to_int(RS, S), to_int(RMA, MA), to_int(RMB, MB), to_int(RRC, RC).

to_rec(I, R) :- integer_to_recollection(I, R).
to_int(R, I) :- recollection_to_integer(R, I).

op_symbol(add, "+").
op_symbol(sub, "−").

%!  result_scene(+Op, +S, +MA, +MB, +RC, +CA, +CB, +LabR, -Scene) is det.
%   Addition: one bar of S parts, first MA in colour A then MB in colour B (RC
%   shaded). Subtraction: one bar of S parts, RC shaded in colour A (what is
%   left after removing MB).
result_scene(add, S, MA, MB, _RC, CA, CB, LabR, Scene) :-
    colors_run(S, [run(0, MA, CA), run(MA, MB, CB)], Cols),
    whole_split_bar(0, S, Cols, LabR, Bar),
    scene_dict_multi([Bar], Scene).
result_scene(sub, S, _MA, _MB, RC, CA, _CB, LabR, Scene) :-
    colors_run(S, [run(0, RC, CA)], Cols),
    whole_split_bar(0, S, Cols, LabR, Bar),
    scene_dict_multi([Bar], Scene).

result_caption(add, LabAS, LabBS, LabR, Cap) :-
    format(string(Cap), "Join the shaded parts: ~w + ~w = ~w.", [LabAS, LabBS, LabR]).
result_caption(sub, LabAS, LabBS, LabR, Cap) :-
    format(string(Cap), "Remove ~w from ~w: ~w.", [LabBS, LabAS, LabR]).

%!  whole_split_bar(+Row, +D, +Colors, +Label, -Bar) is det.
%   A whole-width bar at Row partitioned into D parts, split i filled with the
%   i-th colour in Colors (length D). Splits tile the bar; the last absorbs the
%   integer remainder.
whole_split_bar(Row, D, Colors, Label, Bar) :-
    unit_x(X), unit_w(W), bar_h(H),
    row_y(Row, Y),
    SplitW is W // D,
    colored_splits(0, D, SplitW, W, H, Colors, Splits),
    color_whole(Base),
    Bar = _{ x: X, y: Y, w: W, h: H, size: W, role: Base,
             isUnitBar: false, fraction: Label, label: Label,
             type: "bar", splits: Splits }.

colored_splits(I, D, _SW, _W, _H, _Colors, []) :- I >= D, !.
colored_splits(I, D, SW, W, H, Colors, [S|Rest]) :-
    I < D,
    XPos is I * SW,
    Last is D - 1,
    ( I =:= Last -> ThisW is W - XPos ; ThisW = SW ),
    nth0(I, Colors, C),
    S = _{ x: XPos, y: 0, w: ThisW, h: H, role: C },
    I1 is I + 1,
    colored_splits(I1, D, SW, W, H, Colors, Rest).

%!  colors_run(+D, +Runs, -Colors) is det.
%   A length-D list of colours: each index covered by a run(Start,Count,Colour)
%   takes that colour; uncovered indices take the whole/background colour.
colors_run(D, Runs, Colors) :-
    Hi is D - 1,
    findall(C, ( between(0, Hi, I), color_at(I, Runs, C) ), Colors).

color_at(I, Runs, C) :-
    ( run_covering(I, Runs, Col) -> C = Col ; color_whole(C) ).

run_covering(I, Runs, Col) :-
    member(run(Start, Count, Col), Runs),
    I >= Start,
    End is Start + Count,
    I < End,
    !.

%!  scene_dict_multi(+Bars, -Scene) is det.
%   A v2 scene with no designated unit bar (arithmetic shows wholes, not a
%   measuring unit). Bookkeeping keys are already absent from these bars.
scene_dict_multi(Bars, Scene) :-
    Scene = _{ format: "fraction-bars",
               version: 2,
               unitBarIndex: null,
               mats: [],
               bars: Bars }.


%!  fraction_arith_json(+Op, +NumA, +DenA, +NumB, +DenB, -Dict) is det.
%
%   Assemble the calculator response. On success: op / a / b / result / frames.
%   On an unsupported Op or a failing operation (e.g. negative subtraction),
%   an explicit error and empty frames — never a faked picture.
fraction_arith_json(Op, NumA, DenA, NumB, DenB, Dict) :-
    ( supported_op(Op),
      fraction_arith_frames(Op, NumA, DenA, NumB, DenB, Frames),
      co_measure_op(Op, NumA, DenA, NumB, DenB, S, _MA, _MB, RC)
    -> fraction_label(RC, S, ResultLabel),
       term_to_string(Op, OpStr),
       canvas_dict(Canvas),
       Dict = _{ op: OpStr,
                 a: _{ num: NumA, den: DenA },
                 b: _{ num: NumB, den: DenB },
                 result: ResultLabel,
                 canvas: Canvas,
                 frames: Frames }
    ;  arith_error(Op, NumA, DenA, NumB, DenB, Msg),
       term_to_string(Op, OpStr),
       Dict = _{ op: OpStr,
                 a: _{ num: NumA, den: DenA },
                 b: _{ num: NumB, den: DenB },
                 error: Msg,
                 frames: [] }
    ).

supported_op(add).
supported_op(sub).

arith_error(Op, _, _, _, _, Msg) :-
    \+ supported_op(Op), !,
    format(string(Msg),
           "Operation ~w is not yet drawn as bars (only add and sub).", [Op]).
arith_error(sub, NA, DA, NB, DB, Msg) :-
    !,
    format(string(Msg),
           "~w/~w − ~w/~w is negative; it cannot be shown as bars.",
           [NA, DA, NB, DB]).
arith_error(_, _, _, _, _,
            "Could not render this operation as bars.").


%!  fraction_componentwise_add_json(+NA,+DA,+NB,+DB,-Dict) is det.
%
%   Render the common componentwise fraction-addition misconception: add the
%   numerators and denominators as bare whole-number components. This is a
%   deformation filmstrip, not a productive calculator path.
fraction_componentwise_add_json(NA, DA, NB, DB, Dict) :-
    fraction_componentwise_add_frames(NA, DA, NB, DB, Frames),
    WrongN is NA + NB,
    WrongD is DA + DB,
    CorrectN is NA * DB + NB * DA,
    CorrectD is DA * DB,
    fraction_label(WrongN, WrongD, WrongLabel),
    fraction_label(CorrectN, CorrectD, CorrectLabel),
    canvas_dict(Canvas),
    format(string(Result), "~w (correct: ~w)", [WrongLabel, CorrectLabel]),
    Dict = _{ kind: "add_numerators_and_denominators",
              result: Result,
              misconception: "add_numerators_and_denominators",
              wrong: _{ num: WrongN, den: WrongD },
              correct: _{ num: CorrectN, den: CorrectD },
              canvas: Canvas,
              frames: Frames }.

fraction_componentwise_add_frames(NA, DA, NB, DB, Frames) :-
    color_highlight(CA),
    color_iterated(CB),
    color_deformation(CD),
    colors_run(DA, [run(0, NA, CA)], ColA),
    colors_run(DB, [run(0, NB, CB)], ColB),
    fraction_label(NA, DA, LabA),
    fraction_label(NB, DB, LabB),
    whole_split_bar(0, DA, ColA, LabA, BarA),
    whole_split_bar(1, DB, ColB, LabB, BarB),
    scene_dict_multi([BarA, BarB], Scene1),
    format(string(Cap1), "~w + ~w. The parts are not the same size.", [LabA, LabB]),
    WrongN is NA + NB,
    WrongD is DA + DB,
    CorrectN is NA * DB + NB * DA,
    CorrectD is DA * DB,
    fraction_label(WrongN, WrongD, WrongLabel),
    fraction_label(CorrectN, CorrectD, CorrectLabel),
    colors_run(WrongD, [run(0, WrongN, CD)], WrongCols),
    whole_split_bar(0, WrongD, WrongCols, WrongLabel, WrongBar),
    scene_dict_multi([WrongBar], Scene2),
    format(
        string(Cap2),
        "Add numerator to numerator and denominator to denominator: ~w. This ignores the shared unit; co-measurement gives ~w.",
        [WrongLabel, CorrectLabel]
    ),
    Frames = [ _{ step: 1, verb: "show_addends", caption: Cap1,
                  sceneChanged: true, scene: Scene1 },
               _{ step: 2, verb: "combine_numerators_and_denominators",
                  caption: Cap2, sceneChanged: true, scene: Scene2 } ].


% =============================================================================
% Misconception compare: a productive scheme and its deformation, drawn from
% the same start so the divergence is visible.
%
% The visual argument (Tio's framing, grounded in Hackenberg/Norton/Steffe):
% a misconception is a DEFORMATION of a scheme — the same machine with one wire
% moved. Both filmstrips begin identically (the whole, then the unit fraction),
% then the productive scheme HOLDS the unit-fraction referent across iteration
% while the deformation LOSES it. The end frames show the same bar named two
% ways: 5/3 (three levels of units held — Iterative Fraction Scheme, Stage 3)
% vs 5/5 (the longer bar renamed as its own whole — Stage 2 limit).
%
% Grounding (NotebookLM "Hackenberg Norton Constructing Fractions"): a Stage-2
% student with the Measurement Scheme for Unit Fractions can disembed and
% iterate 1/D to remake the whole, but iterating PAST the whole they "lose track
% of the whole as D/D" and "make the new, longer bar the whole" — naming 5/3 as
% 5/5 (Hackenberg & Lee 2015; Tzur 1999). The Iterative Fraction Scheme (Stage 3)
% coordinates three levels — the unit fraction, the whole, and the fraction —
% so the result is 5/3, both "5 x 1/3" and "1 whole and 2/3" (Steffe & Olive 2010).
%
% The two DEONTIC families draw a different kind of divergence. Their gap is
% not in the bar's value (cross-multiplication without ground produces the
% correct number; the solve deformation produces no number at all) but in the
% deontic status of a step: a commitment undertaken with no entitlement backing
% it. That gap is drawn as fill. Grounded steps are filled; the claimed part a
% commitment names stays HOLLOW (role `hollow`, an unfilled state inside the
% bar frame) until an entitlement is deposited. The strips share their opening
% bars and part exactly where the deontic status parts. The frames carry the
% scorekeeper's vocabulary (`deontic` field; `commitment_without_entitlement`
% is the deontic_scorekeeper's own incoherence term) and the document carries a
% machine-readable `divergence` marker. The drawing shows the deontic structure
% the scorekeeper computes; it does not adjudicate it.
% =============================================================================

color_deformation(deformation). % the deformation's mislabelled bar
color_whole_part(highlight).    % the "one whole" portion of an improper fraction
color_extra_part(iterated).     % the parts beyond the whole
color_hollow(hollow).           % a commitment without entitlement: claimed, unfilled.
                                % The viewer resolves roles to --fig-<role> CSS
                                % variables and falls back to its neutral default
                                % for tokens a page does not define, so the hollow
                                % part stays distinct from filled roles either way.

%!  fraction_compare_json(+ProductiveKind, +A, +B, -Dict) is det.
%
%   Build a productive/deformation comparison for a fraction scheme. Returns
%   two filmstrips plus a grounded note. Five families draw. The three scheme
%   families diverge in the bar itself (same length, wrong name). The two
%   deontic families (rule_without_grounding on A=DenA, B=DenB unit fractions;
%   mc1_no_reversibility on A·x = B) diverge in fill: grounded steps are
%   filled, and the part a commitment names stays hollow when no entitlement
%   backs it; their documents carry a `divergence` marker and per-frame
%   `deontic` fields. A pair with no bar layout (splitting vs
%   iterate-given-overshoot) returns an explicit error rather than a faked
%   picture.
fraction_compare_json(ProductiveKind, A, B, Dict) :-
    productive_fraction_deformation(ProductiveKind, DefKind, Family),
    !,
    term_to_string(ProductiveKind, PKStr),
    term_to_string(DefKind, DKStr),
    term_to_string(Family, FamStr),
    canvas_dict(Canvas),
    (   compare_scenes(Family, A, B, ProdFrames, DefFrames)
    ->  family_note(Family, A, B, Note),
        Dict0 = _{ productiveKind: PKStr, deformationKind: DKStr, family: FamStr,
                   a: A, b: B, note: Note, canvas: Canvas,
                   productive: _{ frames: ProdFrames },
                   deformation: _{ frames: DefFrames } },
        (   family_divergence(Family, Divergence)
        ->  Dict = Dict0.put(divergence, Divergence)
        ;   Dict = Dict0
        )
    ;   Dict = _{ productiveKind: PKStr, deformationKind: DKStr, family: FamStr,
                  a: A, b: B, canvas: Canvas,
                  error: "This pair is not yet drawn as a one-dimensional bar divergence.",
                  productive: _{ frames: [] }, deformation: _{ frames: [] } }
    ).
fraction_compare_json(ProductiveKind, A, B, Dict) :-
    term_to_string(ProductiveKind, PKStr),
    Dict = _{ productiveKind: PKStr, a: A, b: B,
              error: "No paired deformation for this productive kind.",
              productive: _{ frames: [] }, deformation: _{ frames: [] } }.


% --- Per-family scene builders ----------------------------------------------
% Each returns a productive filmstrip and a deformation filmstrip. The scheme
% families share frames 1-2 (the whole, then the unit fraction) and diverge in
% the frame-3 bar. The deontic families share their opening bars and diverge
% in fill at the step named by family_divergence/2.

%!  compare_scenes(+Family, +A, +B, -ProdFrames, -DefFrames) is semidet.

% Iterate a unit fraction past the whole: 5/3 (referent held) vs 5/5 (reset).
compare_scenes(improper_fraction_reset, A, B, ProdFrames, DefFrames) :-
    A > B,
    Rem is A - B,
    whole_frame(B, F1),
    unit_frame(B, F2),
    % Productive: A parts at true length; first B are "one whole", the rest extra.
    bar_at_true_length(A, B, [run(0, B, color_whole_part), run(B, Rem, color_extra_part)],
                       LabAB, ProdBar),
    fraction_label(A, B, LabAB),
    prod_caption(improper_fraction_reset, A, B, ProdCap),
    make_frame(3, "name_improper_fraction_as_number", ProdCap, [ProdBar], F3p),
    % Deformation: the same-length bar, uniform, renamed A/A.
    bar_at_true_length(A, B, [run(0, A, color_deformation)], LabAA, DefBar),
    fraction_label(A, A, LabAA),
    def_caption(improper_fraction_reset, A, B, DefCap),
    make_frame(3, "rename_result_to_new_whole", DefCap, [DefBar], F3d),
    ProdFrames = [F1, F2, F3p],
    DefFrames  = [F1, F2, F3d].

% Iterate a unit fraction and name the count as a whole number: 4/3 vs "4".
compare_scenes(whole_number_grab, A, B, ProdFrames, DefFrames) :-
    whole_frame(B, F1),
    unit_frame(B, F2),
    bar_at_true_length(A, B, [run(0, A, color_extra_part)], LabAB, ProdBar),
    fraction_label(A, B, LabAB),
    prod_caption(whole_number_grab, A, B, ProdCap),
    make_frame(3, "iterate_unit_fraction", ProdCap, [ProdBar], F3p),
    % Deformation: the same A parts, but labelled with the bare count "A".
    format(string(BareLabel), "~w", [A]),
    bar_at_true_length(A, B, [run(0, A, color_deformation)], BareLabel, DefBar),
    def_caption(whole_number_grab, A, B, DefCap),
    make_frame(3, "name_count_as_whole_number", DefCap, [DefBar], F3d),
    ProdFrames = [F1, F2, F3p],
    DefFrames  = [F1, F2, F3d].

% Partition a part again — fraction of a fraction: 1/6 vs 1/3 (inner referent).
compare_scenes(referent_to_inner_whole_not_original, Outer, Inner, ProdFrames, DefFrames) :-
    Composite is Outer * Inner,
    whole_frame(Outer, F1),
    % Disembed 1/Outer, then partition it into Inner — frame 2 shows 1/Outer.
    unit_frame(Outer, F2),
    % Productive: the part-of-a-part is 1/(Outer*Inner) of the original whole.
    fraction_label(1, Composite, LabComposite),
    one_part_bar(Composite, color_extra_part, LabComposite, ProdBar),
    prod_caption(referent_to_inner_whole_not_original, Outer, Inner, ProdCap),
    make_frame(3, "name_part_of_part_relative_to_whole", ProdCap, [ProdBar], F3p),
    % Deformation: named 1/Inner relative to the inner whole, losing the outer.
    fraction_label(1, Inner, LabInner),
    one_part_bar(Composite, color_deformation, LabInner, DefBar),
    def_caption(referent_to_inner_whole_not_original, Outer, Inner, DefCap),
    make_frame(3, "name_inner_part_relative_to_outer_part", DefCap, [DefBar], F3d),
    ProdFrames = [F1, F2, F3p],
    DefFrames  = [F1, F2, F3d].

% Cross-multiplication on unit fractions: 1/DA × 1/DB. Both automata compute
% the same 1/(DA*DB); the divergence is deontic, not numeric. Frames 1-2 are
% the same bars on both sides — the pattern's claim enters HOLLOW on both.
% Frame 3 parts: the productive automaton deposits the area-model account and
% the claimed part fills; the deformation skips the justification step and the
% same-geometry part stays hollow. The bars slice draws the unit-fraction case
% (the two-integer compare signature carries the denominators); the 2-D area
% figure itself is the area-model compare's job, not this strip's.
compare_scenes(rule_without_grounding, DA, DB, ProdFrames, DefFrames) :-
    integer(DA), integer(DB),
    DA >= 2, DB >= 2,
    Pair = fraction_pair(1, DA, 1, DB),
    run_fraction_action(cross_multiplication_rule_from_pattern, Pair,
                        unit(whole), action_outcome(_, ProdProps), _),
    run_fraction_action(cross_multiplication_rule_without_ground, Pair,
                        unit(whole), action_outcome(_, DefProps), _),
    memberchk(components(fraction_multiplication_components(NumP, DenP, _)),
              ProdProps),
    % The deformation reports the same products — checked, not assumed.
    memberchk(components(fraction_multiplication_components(NumP, DenP, _)),
              DefProps),
    % Frame 1 — the two unit-fraction factors, shared.
    color_whole_part(CA),
    color_extra_part(CB),
    colors_run(DA, [run(0, 1, CA)], ColA),
    colors_run(DB, [run(0, 1, CB)], ColB),
    fraction_label(1, DA, LabA),
    fraction_label(1, DB, LabB),
    whole_split_bar(0, DA, ColA, LabA, BarA),
    whole_split_bar(1, DB, ColB, LabB, BarB),
    format(string(Cap1), "~w × ~w. Both strips start from the same factors.",
           [LabA, LabB]),
    make_frame(1, "show_factors", Cap1, [BarA, BarB], F1),
    % Frame 2 — the pattern proposes 1/(DA*DB); the claimed part is hollow on
    % BOTH sides. A commitment undertaken is just a commitment, whichever
    % automaton undertakes it.
    fraction_label(NumP, DenP, LabR),
    color_hollow(CH),
    colors_run(DenP, [run(0, NumP, CH)], HollowCols),
    whole_split_bar(2, DenP, HollowCols, LabR, HollowBar),
    format(string(Cap2),
           "Multiply across: 1 × 1 = ~w and ~w × ~w = ~w. The pattern proposes ~w. The claimed part is hollow: committed, not yet grounded.",
           [NumP, DA, DB, DenP, LabR]),
    make_deontic_frame(2, "apply_cross_multiplication_pattern", Cap2,
                       [BarA, BarB, HollowBar], "commitment_undertaken", F2),
    % Frame 3, productive — the area-model account is deposited; the claimed
    % part fills. The fill marks the entitlement, not its content.
    colors_run(DenP, [run(0, NumP, CA)], FilledCols),
    whole_split_bar(2, DenP, FilledCols, LabR, FilledBar),
    format(string(Cap3p),
           "The area-model account is deposited: ~w × ~w small parts tile the whole, so one part of one part is ~w. The fill marks the entitlement; the 2-D figure itself is drawn by the area-model compare.",
           [DA, DB, LabR]),
    make_deontic_frame(3, "justify_via_area_model_part_of_part", Cap3p,
                       [BarA, BarB, FilledBar], "entitlement_deposited", F3p),
    % Frame 3, deformation — the justification step is skipped; the same
    % geometry stays hollow.
    format(string(Cap3d),
           "The same ~w is produced, and the justification step is skipped. The part stays hollow: a commitment made without entitlement.",
           [LabR]),
    make_deontic_frame(3, "skip_area_model_justification", Cap3d,
                       [BarA, BarB, HollowBar], "commitment_without_entitlement", F3d),
    ProdFrames = [F1, F2, F3p],
    DefFrames  = [F1, F2, F3d].

% Solve P·x = Total, the whole-number-coefficient case of (P/Q)·x = Total with
% Q = 1 (the Sticker Problem shape; the compare signature carries P and Total).
% The unknown enters as a hollow bar on both sides: a commitment that some
% length x satisfies the equation. The productive automaton runs the inverse
% move — partition the total, disembed one part — and the hollow claim is
% discharged into a measured, filled bar. The MC1 deformation iterates forward
% only; partitioning is consumed in activity, no part can be disembedded to
% become x, and the unknown stays hollow in every frame.
compare_scenes(mc1_no_reversibility, P, Total, ProdFrames, DefFrames) :-
    integer(P), integer(Total),
    P >= 2, Total >= 1,
    run_fraction_action(solve_for_unit, solve(P, 1), Total,
                        action_outcome(_, _ProdProps), _),
    run_fraction_action(iterate_only_no_reverse, solve(P, 1), Total,
                        action_outcome(_, DefProps), _),
    memberchk(result(unknown_unrecovered), DefProps),
    unit_w(UW),
    color_hollow(CH),
    color_whole_part(CF),
    color_extra_part(CT),
    % Frame 1 — the equation, shared. The total is a known bar; x is a hollow
    % claim. Its extent is not yet determined; the hollow bar is drawn at the
    % total's extent as a placeholder, not as a measurement.
    format(string(LabT), "~w", [Total]),
    plain_bar(0, UW, CT, LabT, TotalBar),
    plain_bar(1, UW, CH, "x = ?", UnknownBar),
    format(string(Cap1),
           "~w·x = ~w: ~w copies of some length x make ~w. The unknown is hollow: committed to, not yet recovered. Its extent is not yet determined.",
           [P, Total, P, Total]),
    make_deontic_frame(1, "read_equation", Cap1, [TotalBar, UnknownBar],
                       "commitment_undertaken", F1),
    % Frame 2, productive — treat x as partitionable: cut the total into P
    % equal parts. One part is x.
    colors_run(P, [run(0, 1, CF)], PartCols),
    whole_split_bar(0, P, PartCols, LabT, PartedBar),
    format(string(Cap2p),
           "Treat x as a partitionable quantity: cut ~w into ~w equal parts. One part is x.",
           [Total, P]),
    make_frame(2, "partition_total_into_numerator_parts", Cap2p,
               [PartedBar, UnknownBar], F2p),
    % Frame 2, deformation — the same bars as frame 1; nothing can move.
    format(string(Cap2d),
           "Iterate forward only: ~w copies of a given part would build ~w, but partitioning is consumed in activity. No part can be disembedded to become x.",
           [P, Total]),
    make_frame(2, "iterate_forward_only_build_total_from_a_unit", Cap2d,
               [TotalBar, UnknownBar], F2d),
    % Frame 3, productive — disembed the part and name it: the hollow claim is
    % discharged into a measured, filled bar of the part's true length.
    XW is UW // P,
    solve_unknown_label(P, Total, LabX),
    plain_bar(1, XW, CF, LabX, SolvedBar),
    format(string(Cap3p),
           "Disembed one part and name it: ~w. The hollow claim is discharged; partition undoes iteration on the unknown.",
           [LabX]),
    make_deontic_frame(3, "recover_unknown", Cap3p, [PartedBar, SolvedBar],
                       "commitment_discharged", F3p),
    % Frame 3, deformation — the unknown is never recovered.
    Cap3d = "The unknown is never recovered. The commitment to x stands without the entitlement the inverse move would deposit: x stays hollow.",
    make_deontic_frame(3, "fail_to_solve", Cap3d, [TotalBar, UnknownBar],
                       "commitment_without_entitlement", F3d),
    ProdFrames = [F1, F2p, F3p],
    DefFrames  = [F1, F2d, F3d].


% --- Shared frame pieces -----------------------------------------------------

%!  whole_frame(+B, -Frame) is det.
whole_frame(B, Frame) :-
    colors_run(B, [], Cols),                 % all parts the whole colour
    fraction_label(B, B, Label),
    whole_split_bar(0, B, Cols, Label, Bar),
    format(string(Cap), "The whole, ~w/~w.", [B, B]),
    make_frame(1, "establish_referent_whole", Cap, [Bar], Frame).

%!  unit_frame(+B, -Frame) is det.
%   The whole partitioned into B parts with one shaded — the unit fraction 1/B.
unit_frame(B, Frame) :-
    color_whole_part(CW),
    colors_run(B, [run(0, 1, CW)], Cols),
    fraction_label(1, B, Label),
    whole_split_bar(0, B, Cols, Label, Bar),
    format(string(Cap), "Recover the unit fraction 1/~w (one part of the whole).", [B]),
    make_frame(2, "recover_unit_fraction", Cap, [Bar], Frame).

%!  bar_at_true_length(+A, +B, +Runs, +Label, -Bar) is det.
%   A bar of A parts each one B-th of the whole wide, so its length is the true
%   A/B of the whole. Splits coloured by Runs.
bar_at_true_length(A, B, Runs, Label, Bar) :-
    unit_w(UW),
    W is (A * UW) // B,
    bar_h(H),
    unit_x(X), unit_y(Y),
    SplitW is W // A,
    colored_splits_runs(0, A, SplitW, W, H, Runs, Splits),
    color_whole(Base),
    Bar = _{ x: X, y: Y, w: W, h: H, size: W, role: Base,
             isUnitBar: false, fraction: Label, label: Label,
             type: "bar", splits: Splits }.

%!  one_part_bar(+D, +ColourPred, +Label, -Bar) is det.
%   The whole partitioned into D parts with the first shaded in ColourPred.
one_part_bar(D, ColourPred, Label, Bar) :-
    call(ColourPred, C),
    colors_run(D, [run(0, 1, C)], Cols),
    whole_split_bar(0, D, Cols, Label, Bar).

%!  colored_splits_runs(+I, +D, +SW, +W, +H, +Runs, -Splits) is det.
%   Like colored_splits, but split i takes the colour from the covering run
%   (a colour predicate) or the whole colour if uncovered.
colored_splits_runs(I, D, _SW, _W, _H, _Runs, []) :- I >= D, !.
colored_splits_runs(I, D, SW, W, H, Runs, [S|Rest]) :-
    I < D,
    XPos is I * SW,
    Last is D - 1,
    ( I =:= Last -> ThisW is W - XPos ; ThisW = SW ),
    ( run_covering(I, Runs, ColourPred) -> call(ColourPred, C) ; color_whole(C) ),
    S = _{ x: XPos, y: 0, w: ThisW, h: H, role: C },
    I1 is I + 1,
    colored_splits_runs(I1, D, SW, W, H, Runs, Rest).

%!  make_frame(+Step, +Verb, +Caption, +Bars, -Frame) is det.
make_frame(Step, Verb, Caption, Bars, Frame) :-
    scene_dict_multi(Bars, Scene),
    Frame = _{ step: Step, verb: Verb, caption: Caption,
               sceneChanged: true, scene: Scene }.

%!  make_deontic_frame(+Step, +Verb, +Caption, +Bars, +Deontic, -Frame) is det.
%   A compare frame carrying the deontic status of its step in the
%   scorekeeper's vocabulary (commitment_undertaken, entitlement_deposited,
%   commitment_discharged, commitment_without_entitlement). The field is
%   additive scene metadata: it names the status the symbolic layer computes,
%   it does not adjudicate it.
make_deontic_frame(Step, Verb, Caption, Bars, Deontic, Frame) :-
    make_frame(Step, Verb, Caption, Bars, Frame0),
    Frame = Frame0.put(deontic, Deontic).

%!  plain_bar(+Row, +W, +Role, +Label, -Bar) is det.
%   An unsplit bar at Row of width W, filled with Role, labelled Label. Used by
%   the deontic families for quantities that are not (yet) partitioned: the
%   known total, the hollow unknown, the recovered unknown.
plain_bar(Row, W, Role, Label, Bar) :-
    unit_x(X), bar_h(H),
    row_y(Row, Y),
    Bar = _{ x: X, y: Y, w: W, h: H, size: W,
             role: Role, isUnitBar: false, fraction: Label,
             label: Label, type: "bar", splits: [] }.

%!  solve_unknown_label(+P, +Total, -Label) is det.
%   The recovered unknown's name: an integer when P divides Total, otherwise
%   the exact quotient as a fraction string.
solve_unknown_label(P, Total, Label) :-
    (   0 =:= Total mod P
    ->  X is Total // P,
        format(string(Label), "x = ~w", [X])
    ;   format(string(Label), "x = ~w/~w", [Total, P])
    ).

%!  family_divergence(+Family, -Divergence) is semidet.
%   The machine-readable divergence marker for the deontic families: the step
%   at which the strips part, the step at which the hollow claim enters, and
%   the deontic status each side carries after the parting. Only the deontic
%   families carry one; the scheme families' divergence is the bar itself.
family_divergence(rule_without_grounding,
                  _{ step: 3, hollowStep: 2,
                     productiveStatus: "entitlement_deposited",
                     deformationStatus: "commitment_without_entitlement" }).
family_divergence(mc1_no_reversibility,
                  _{ step: 2, hollowStep: 1,
                     productiveStatus: "commitment_discharged",
                     deformationStatus: "commitment_without_entitlement" }).


% --- Captions and grounded notes --------------------------------------------

prod_caption(improper_fraction_reset, A, B, Cap) :-
    Rem is A - B,
    format(string(Cap),
           "Iterate 1/~w past the whole: ~w/~w is one whole (~w/~w) and ~w/~w. \
The whole is held, so the result is a number in its own right.",
           [B, A, B, B, B, Rem, B]).
prod_caption(whole_number_grab, A, B, Cap) :-
    format(string(Cap),
           "Iterate 1/~w ~w times: ~w/~w. Each part is still one ~w-th.",
           [B, A, A, B, B]).
prod_caption(referent_to_inner_whole_not_original, Outer, Inner, Cap) :-
    Composite is Outer * Inner,
    format(string(Cap),
           "Partition the 1/~w part into ~w: the part of a part is 1/~w of the \
original whole.", [Outer, Inner, Composite]).

def_caption(improper_fraction_reset, A, B, Cap) :-
    format(string(Cap),
           "The whole as ~w/~w is lost; the longer bar is renamed ~w/~w — it \
becomes its own whole. The same bar, the wrong unit.", [B, B, A, A]).
def_caption(whole_number_grab, A, _B, Cap) :-
    format(string(Cap),
           "The denominator is dropped; the parts are counted as whole units and \
named '~w'. The fractional unit is lost.", [A]).
def_caption(referent_to_inner_whole_not_original, _Outer, Inner, Cap) :-
    format(string(Cap),
           "The part is named 1/~w relative to the inner whole, losing its \
relation to the original whole.", [Inner]).

%!  family_note(+Family, +A, +B, -Note) is det.
%   A grounded description of the misconception, with literature attribution.
family_note(improper_fraction_reset, _A, B, Note) :-
    format(string(Note),
           "Units coordination: a Stage-2 student (Measurement Scheme for Unit \
Fractions) can iterate 1/~w to remake the whole, but iterating past the whole \
loses the whole as ~w/~w and renames the bar as its own whole. Holding three \
levels of units — the unit fraction, the whole, and the fraction — is the \
Iterative Fraction Scheme (Stage 3). Hackenberg & Lee 2015; Tzur 1999; \
Steffe & Olive 2010.", [B, B, B]).
family_note(whole_number_grab, _A, B, Note) :-
    format(string(Note),
           "The count of iterations is named as a whole number, dropping the \
unit-fraction referent 1/~w. Productive iteration keeps each part as a ~w-th \
(the Measurement Scheme for Unit Fractions). Steffe & Olive 2010.", [B, B]).
family_note(referent_to_inner_whole_not_original, Outer, Inner, Note) :-
    Composite is Outer * Inner,
    format(string(Note),
           "Recursive partitioning (a part of a part) requires keeping the \
original whole as referent: 1/~w of 1/~w is 1/~w of the whole. Naming it 1/~w \
keeps only the inner whole. Steffe & Olive 2010; Hackenberg 2007.",
           [Inner, Outer, Composite, Inner]).
family_note(rule_without_grounding, DA, DB, Note) :-
    S is DA * DB,
    format(string(Note),
           "Multiply-across on unit fractions: both automata produce 1/~w, \
and the value is correct on both sides. The pair differs in inferential \
structure, not in number. The productive automaton deposits the area-model \
account of why ~w × ~w parts tile the whole; the deformation applies the \
recalled pattern with no ground, the state the deontic scorekeeper names \
commitment_without_entitlement. Hollow marks that state; fill marks a \
deposited entitlement. The strips draw the deontic structure the scorekeeper \
computes; they do not adjudicate it. Glade 2017.",
           [S, DA, DB]).
family_note(mc1_no_reversibility, P, Total, Note) :-
    format(string(Note),
           "Fractions to algebra: solving ~w·x = ~w by treating the unknown \
as a partitionable, iterable quantity is the splitting inverse applied to an \
unknown (Hackenberg & Lee 2015; Hackenberg 2013). An MC1 solver can iterate \
forward, but partitioning is consumed in activity: no part can be disembedded \
and re-iterated, so the unknown is never recovered. The hollow bar is that \
undischarged commitment. The strips draw the deontic structure the \
scorekeeper computes; they do not adjudicate it.",
           [P, Total]).
