/** <module> Data-display scene compiler (spatial family)
 *
 * Compiles a statistical-display task into data-display scene frames on the
 * render contract (docs/render-contract-v2.md). Data display is a small family
 * of statistical pictures
 * under one language: picture/bar graphs and line plots (1.MD.4, 2.MD.9-10,
 * 3.MD.3-4), the dot plot / histogram / box plot (6.SP.4), the scatterplot
 * (8.SP.1). This compiler lands the two the slice needs: the bar chart and the
 * dot plot.
 *
 * Unlike the coordinate-plane compiler, whose geometry is a MATH lattice the
 * drawer scales, a data display is laid out in PIXELS directly, as the
 * fraction-bars compiler is: a bar's length is a rendered extent, so the
 * compiler emits x/y/w/h and the drawer draws the rect where it is told. Every
 * coordinate the scene carries is an integer pixel; the compiler never leaves a
 * float or a hex string in a scene.
 *
 * Four productive Spec shapes, one format ("data-display", version 2):
 *
 *   - bar_chart(Pairs) : Pairs is a list of Category-Count. The filmstrip raises
 *     one bar per frame, so the chart fills in category by category. Denotes the
 *     task data_display(bar_chart, Pairs).
 *   - dot_plot(Values) : Values is a list of integers. The filmstrip stacks one
 *     dot per frame above its value's column. Denotes data_display(dot_plot, Values).
 *   - histogram(Bins) : equal-width `bin(Lower,Upper)-Count` intervals rendered
 *     as touching bars. Denotes grouped numerical frequency, not categories.
 *   - box_plot(five_number(Min,Q1,Median,Q3,Max)) : one number-line frame with
 *     whiskers, quartile box, and median line.
 *
 * The characteristic break (the grammar's deformation lane) is the
 * bar/histogram conflation: categorical bars drawn touching, with the gaps
 * closed, so the discrete categories read as the evenly binned intervals of one
 * continuous variable. It is reachable ONLY through bar_histogram_conflation/1
 * and only via the misconception lane; no productive Spec draws touching bars.
 *
 * Semantic color ROLES only (the render contract): a bar, bin, or stacked dot carries
 * role "bar"; the conflated pseudo-histogram bars carry role "deformation". This
 * compiler never emits a hex string.
 *
 * Graceful degradation: a Spec with nothing to display (an empty list, a list
 * with no well-formed entry) yields an explicit error document with frames:[]
 * rather than a faked picture (the render contract).
 */

:- module(data_display_scene,
          [ data_display_render_frames/2,   % +Spec, -Frames
            data_display_render_json/2,      % +Spec, -Dict
            data_display_compare_json/2,     % +Spec, -Dict (conflation deformation)
            data_display_render_to_file/2    % +Spec, +Path
          ]).

:- use_module(library(http/json), [json_write_dict/3]).
:- use_module(library(lists)).
:- use_module(library(apply), [include/3]).

% =============================================================================
% Pixel layout constants. Kept in step with the drawer's own constants
% (drawDataDisplay in more-zeeman/render/drawer.js) so bars and axis tick
% labels line up; the drawer draws forward-only at the pixels emitted here.
% =============================================================================

dd_x0(60).            % left edge / y-axis
dd_y0(40).            % top of the plot band
dd_plot_h(300).       % plot height; baseline sits at y0 + plot_h
dd_bar_w(48).         % bar width
dd_bar_gap(24).       % gap between spaced categorical bars
dd_col_w(40).         % horizontal spacing per unit value in a dot plot
dd_dot_r(7).          % dot radius
dd_dot_step(18).      % vertical spacing between stacked dots

dd_baseline(Base) :- dd_y0(Y0), dd_plot_h(H), Base is Y0 + H.


% =============================================================================
% Public API
% =============================================================================

%!  data_display_render_frames(+Spec, -Frames) is det.
%
%   Walk Spec into a list of frame dicts. A Spec that cannot be displayed yields
%   a single annotation-only frame (sceneChanged:false), so nothing throws.
data_display_render_frames(Spec, Frames) :-
    ( gen_frames(Spec, Frames0)
    -> Frames = Frames0
    ;  deferred_frame(Spec, F),
       Frames = [F]
    ).

%!  data_display_render_json(+Spec, -Dict) is det.
%
%   The full render document: kind / request / result / canvas / frames
%   (the render contract). On an undisplayable Spec, an explicit error string and frames:[].
data_display_render_json(bar_chart(Pairs), Dict) :-
    !,
    ( clean_pairs(Pairs, Clean), Clean \== []
    -> pairs_freq_max(Clean, FreqMax),
       labels_of(Clean, Labels),
       bar_frames(Clean, FreqMax, Labels, Frames),
       length(Clean, N),
       plural_y(N, YStr),
       format(string(ResultStr), "~w categor~w charted", [N, YStr]),
       canvas_dict(Canvas),
       pairs_request(Clean, Request),
       Dict = _{ kind: "bar_chart",
                 request: Request,
                 result: ResultStr,
                 canvas: Canvas,
                 frames: Frames }
    ;  Dict = _{ kind: "bar_chart",
                 request: _{ pairs: "[]" },
                 error: "No well-formed Category-Count pairs to chart for this data display.",
                 frames: [] }
    ).
data_display_render_json(dot_plot(Values), Dict) :-
    !,
    ( clean_values(Values, Clean), Clean \== []
    -> value_labels(Clean, Labels),
       dot_freq_max(Clean, FreqMax),
       dot_frames(Clean, Labels, FreqMax, Frames),
       length(Clean, N),
       plural_s(N, SStr),
       format(string(ResultStr), "~w value~w plotted", [N, SStr]),
       canvas_dict(Canvas),
       values_request(Clean, Request),
       Dict = _{ kind: "dot_plot",
                 request: Request,
                 result: ResultStr,
                 canvas: Canvas,
                 frames: Frames }
    ;  Dict = _{ kind: "dot_plot",
                 request: _{ values: "[]" },
                 error: "No integer values to plot for this data display.",
                 frames: [] }
    ).
data_display_render_json(histogram(Bins), Dict) :-
    !,
    ( valid_histogram_bins(Bins)
    -> histogram_frames(Bins, Frames),
       length(Bins, Count),
       canvas_dict(Canvas),
       Dict = _{ kind: "histogram",
                 request: _{ bins: Count },
                 result: "equal-width numerical intervals charted",
                 canvas: Canvas,
                 frames: Frames }
    ;  Dict = _{ kind: "histogram",
                 request: _{ bins: 0 },
                 error: "A histogram needs ordered equal-width numerical bins with nonnegative counts.",
                 frames: [] }
    ).
data_display_render_json(box_plot(FiveNumber), Dict) :-
    !,
    ( valid_five_number(FiveNumber)
    -> box_plot_frame(FiveNumber, Frame),
       canvas_dict(Canvas),
       term_to_string(FiveNumber, Summary),
       Dict = _{ kind: "box_plot",
                 request: _{ five_number_summary: Summary },
                 result: "five-number summary rendered as a box plot",
                 canvas: Canvas,
                 frames: [Frame] }
    ;  Dict = _{ kind: "box_plot",
                 request: _{ five_number_summary: "invalid" },
                 error: "A box plot needs ordered numeric minimum, quartiles, median, and maximum.",
                 frames: [] }
    ).
data_display_render_json(Spec, Dict) :-
    data_display_render_frames(Spec, Frames),
    term_to_string(Spec, SpecStr),
    canvas_dict(Canvas),
    Dict = _{ kind: SpecStr,
              request: _{ spec: SpecStr },
              result: "unknown",
              canvas: Canvas,
              frames: Frames }.

%!  data_display_compare_json(+Spec, -Dict) is det.
%
%   The bar/histogram-conflation compare document: a productive filmstrip that
%   raises spaced categorical bars beside a deformation filmstrip that closes the
%   gaps and redraws the same bars touching, as one binned pseudo-histogram. The
%   dropped gaps mis-signal a continuous variable. Spec is
%   bar_histogram_conflation(Pairs). On a Spec with fewer than two categories
%   (no spacing to conflate), an explicit error and empty filmstrips.
data_display_compare_json(bar_histogram_conflation(Pairs), Dict) :-
    !,
    ( clean_pairs(Pairs, Clean), Clean \== [], length(Clean, N), N >= 2
    -> pairs_freq_max(Clean, FreqMax),
       labels_of(Clean, Labels),
       bar_frames(Clean, FreqMax, Labels, ProdFrames),
       conflation_def_frames(Clean, FreqMax, Labels, DefFrames),
       conflation_note(N, Note),
       canvas_dict(Canvas),
       pairs_request(Clean, Request),
       Dict = _{ kind: "bar_chart_vs_pseudo_histogram",
                 request: Request,
                 productiveKind: "bar_chart",
                 deformationKind: "pseudo_histogram",
                 family: "bar_histogram_conflation",
                 categories: N,
                 violation: "categorical_spacing_read_as_continuous_bins",
                 provenance: "literature_only",
                 note: Note,
                 canvas: Canvas,
                 productive: _{ frames: ProdFrames },
                 deformation: _{ frames: DefFrames } }
    ;  Dict = _{ kind: "bar_chart_vs_pseudo_histogram",
                 request: _{ pairs: "[]" },
                 error: "The conflation needs at least two categorical bars; one bar has no gap to close.",
                 productive: _{ frames: [] },
                 deformation: _{ frames: [] } }
    ).
data_display_compare_json(Spec, _{ kind: SpecStr,
                                   error: "Unknown data-display compare spec.",
                                   productive: _{ frames: [] },
                                   deformation: _{ frames: [] } }) :-
    term_to_string(Spec, SpecStr).

%!  data_display_render_to_file(+Spec, +Path) is det.
data_display_render_to_file(Spec, Path) :-
    data_display_render_json(Spec, Dict),
    setup_call_cleanup(
        open(Path, write, Stream),
        json_write_dict(Stream, Dict, [width(80)]),
        close(Stream)).


% =============================================================================
% bar_chart — one bar per frame, bars spaced apart (discrete categories).
% =============================================================================

%!  bar_frames(+Pairs, +FreqMax, +Labels, -Frames) is det.
%   One frame per category, accumulating the bars raised so far so the filmstrip
%   builds the chart category by category. Every scene carries the fixed axes
%   (all category labels, the overall freqMax) plus every bar up to the current step.
bar_frames(Pairs, FreqMax, Labels, Frames) :-
    bar_rects(Pairs, FreqMax, spaced, "bar", Rects),
    bar_frames_(Rects, FreqMax, Labels, 1, [], Frames).

bar_frames_([], _FreqMax, _Labels, _Step, _Acc, []).
bar_frames_([R|Rest], FreqMax, Labels, Step, Acc, [Frame|Frames]) :-
    append(Acc, [R], Acc1),
    axes_dict(Labels, FreqMax, Axes),
    Scene = _{ format: "data-display",
               version: 2,
               mode: "bar",
               axes: Axes,
               bars: Acc1,
               dots: [] },
    get_dict(label, R, Lbl),
    get_dict(count, R, Cnt),
    format(string(Caption),
           "Raise the ~w bar to ~w unit(s): its length marks a count of ~w.",
           [Lbl, Cnt, Cnt]),
    format(string(Verb), "bar(~w,~w)", [Lbl, Cnt]),
    Frame = _{ step: Step,
               verb: Verb,
               caption: Caption,
               sceneChanged: true,
               scene: Scene },
    Step1 is Step + 1,
    bar_frames_(Rest, FreqMax, Labels, Step1, Acc1, Frames).

%!  bar_rects(+Pairs, +FreqMax, +GapMode, +Role, -Rects) is det.
%   Every bar as an integer-pixel rect. GapMode `spaced` leaves the categorical
%   gap between bars; `touching` closes it (the conflation lane). Role is the
%   render contract's fill-role atom carried on each rect.
bar_rects(Pairs, FreqMax, GapMode, Role, Rects) :-
    dd_x0(X0), dd_bar_w(BarW), dd_bar_gap(Gap0),
    ( GapMode == touching -> Gap = 0 ; Gap = Gap0 ),
    Slot is BarW + Gap,
    safe_max(FreqMax, SafeMax),
    dd_plot_h(PlotH),
    UnitH is PlotH // SafeMax,
    dd_baseline(Base),
    bar_rects_(Pairs, 0, X0, Slot, BarW, UnitH, Base, Role, Rects).

bar_rects_([], _I, _X0, _Slot, _BarW, _UnitH, _Base, _Role, []).
bar_rects_([Cat-Count|Rest], I, X0, Slot, BarW, UnitH, Base, Role, [R|Rs]) :-
    X is X0 + I * Slot,
    H is Count * UnitH,
    Y is Base - H,
    cat_string(Cat, CatStr),
    R = _{ x: X, y: Y, w: BarW, h: H, role: Role, label: CatStr, count: Count },
    I1 is I + 1,
    bar_rects_(Rest, I1, X0, Slot, BarW, UnitH, Base, Role, Rs).


% =============================================================================
% dot_plot — one dot per frame, stacked above its value's column.
% =============================================================================

%!  dot_frames(+Values, +Labels, +FreqMax, -Frames) is det.
%   One frame per value, accumulating the dots stacked so far. The value order in
%   Points matches Values, so each step names the value it just stacked.
dot_frames(Values, Labels, FreqMax, Frames) :-
    dot_points(Values, Points),
    dot_frames_(Values, Points, Labels, FreqMax, 1, [], Frames).

dot_frames_([], [], _Labels, _FreqMax, _Step, _Acc, []).
dot_frames_([V|Vs], [P|Ps], Labels, FreqMax, Step, Acc, [Frame|Frames]) :-
    append(Acc, [P], Acc1),
    axes_dict(Labels, FreqMax, Axes),
    Scene = _{ format: "data-display",
               version: 2,
               mode: "dot",
               axes: Axes,
               bars: [],
               dots: Acc1 },
    format(string(Caption),
           "Stack a dot above ~w: each dot marks one value recorded at ~w.",
           [V, V]),
    format(string(Verb), "dot(~w)", [V]),
    Frame = _{ step: Step,
               verb: Verb,
               caption: Caption,
               sceneChanged: true,
               scene: Scene },
    Step1 is Step + 1,
    dot_frames_(Vs, Ps, Labels, FreqMax, Step1, Acc1, Frames).

%!  dot_points(+Values, -Points) is det.
%   One integer-pixel dot per value. A dot's column is its value's offset from the
%   least value; its height is its stack index (how many equal values came before
%   it), so equal values pile up into a frequency column. Every dot carries role
%   "bar" (a stacked-dot fill, per the render contract).
dot_points(Values, Points) :-
    dd_x0(X0), dd_col_w(ColW), dd_dot_r(R), dd_dot_step(Step), dd_baseline(Base),
    min_list(Values, MinV),
    dot_points_(Values, MinV, X0, ColW, R, Step, Base, [], Points).

dot_points_([], _MinV, _X0, _ColW, _R, _Step, _Base, _Placed, []).
dot_points_([V|Rest], MinV, X0, ColW, R, Step, Base, Placed, [P|Ps]) :-
    include(==(V), Placed, Same),
    length(Same, K),
    X is X0 + (V - MinV) * ColW,
    Y is Base - R - K * Step,
    P = _{ x: X, y: Y, role: "bar" },
    append(Placed, [V], Placed1),
    dot_points_(Rest, MinV, X0, ColW, R, Step, Base, Placed1, Ps).


% =============================================================================
% Conflation — the productive bars closed into a pseudo-histogram.
% =============================================================================

%!  conflation_def_frames(+Pairs, +FreqMax, +Labels, -Frames) is det.
%   Two frames: the grounded spaced chart for reference, then the same bars with
%   the gaps closed and role "deformation", redrawn as a binned pseudo-histogram.
conflation_def_frames(Pairs, FreqMax, Labels, [F1, F2]) :-
    bar_rects(Pairs, FreqMax, spaced, "bar", SpacedRects),
    bar_rects(Pairs, FreqMax, touching, "deformation", TouchRects),
    axes_dict(Labels, FreqMax, Axes),
    % Frame 1: the grounded categorical bars, standing apart.
    Scene1 = _{ format: "data-display", version: 2, mode: "bar",
                axes: Axes, bars: SpacedRects, dots: [] },
    F1 = _{ step: 1, verb: "stand_bars_apart",
            caption: "Categorical bars stand apart: each bar is a discrete category, and the gaps carry that separateness.",
            sceneChanged: true, scene: Scene1 },
    % Frame 2: the gaps closed, the categories redrawn as touching bins.
    Scene2 = _{ format: "data-display", version: 2, mode: "histogram",
                axes: Axes, bars: TouchRects, dots: [] },
    F2 = _{ step: 2, verb: "close_the_gaps",
            caption: "Closing the gaps redraws the same categories as touching bins, mis-signalling one continuous variable where the data are separate categories.",
            sceneChanged: true, scene: Scene2 }.

conflation_note(N, Note) :-
    format(string(Note),
           "A bar chart spaces ~w categorical bars apart; each bar is a discrete category and the \
gaps carry that discreteness. Drawing the same bars touching, evenly binned, redraws them as a \
histogram and mis-signals a continuous variable. A bar's length denotes a count, but a histogram's \
frequency is its bar's area over an interval, so reading the touching bins by height alone loses the \
area reading that unequal bins would demand. (Bar-histogram-conflation family.)",
           [N]).


% =============================================================================
% Axes + cleaning + helpers.
% =============================================================================

%!  axes_dict(+Labels, +FreqMax, -Axes) is det.
%   The shared axes dict: the category (or value tick) labels and the frequency
%   ceiling. The same shape serves bar and dot modes (the render contract's data-display shape).
axes_dict(Labels, FreqMax, _{ categoryLabels: Labels, freqMax: FreqMax }).

%!  clean_pairs(+Raw, -Clean) is det.
%   Keep only well-formed Category-Count pairs with a nonnegative integer count,
%   in order. A malformed entry is dropped rather than faked.
clean_pairs(Raw, Clean) :-
    is_list(Raw),
    findall(Cat-Count,
            ( member(P, Raw),
              pair_cat_count(P, Cat, Count)
            ),
            Clean).

pair_cat_count(Cat-Count, Cat, Count) :- integer(Count), Count >= 0.
pair_cat_count([Cat, Count], Cat, Count) :- integer(Count), Count >= 0.

%!  clean_values(+Raw, -Clean) is det.
%   Keep only integer values, in order. A non-integer entry is dropped.
clean_values(Raw, Clean) :-
    is_list(Raw),
    findall(V, ( member(V, Raw), integer(V) ), Clean).

%!  pairs_freq_max(+Pairs, -FreqMax) is det.
pairs_freq_max(Pairs, FreqMax) :-
    findall(C, member(_-C, Pairs), Counts),
    max_list(Counts, FreqMax).

%!  dot_freq_max(+Values, -FreqMax) is det.
%   The tallest stacked column: the frequency of the most common value.
dot_freq_max(Values, FreqMax) :-
    sort(Values, Distinct),
    findall(C,
            ( member(V, Distinct), include(==(V), Values, Occ), length(Occ, C) ),
            Counts),
    max_list(Counts, FreqMax).

%!  value_labels(+Values, -Labels) is det.
%   The integer tick labels from the least to the greatest value, as strings.
value_labels(Values, Labels) :-
    min_list(Values, MinV),
    max_list(Values, MaxV),
    numlist(MinV, MaxV, Ints),
    findall(S, ( member(I, Ints), term_to_string(I, S) ), Labels).

labels_of(Pairs, Labels) :-
    findall(S, ( member(C-_, Pairs), cat_string(C, S) ), Labels).

cat_string(Cat, Str) :- term_to_string(Cat, Str).

safe_max(Max, Safe) :- ( integer(Max), Max > 0 -> Safe = Max ; Safe = 1 ).

plural_s(1, "") :- !.
plural_s(_, "s").
plural_y(1, "y") :- !.
plural_y(_, "ies").

pairs_request(Pairs, _{ pairs: Str, count: N }) :-
    length(Pairs, N),
    term_to_string(Pairs, Str).

values_request(Values, _{ values: Str, count: N }) :-
    length(Values, N),
    term_to_string(Values, Str).

valid_histogram_bins([bin(Lower, Upper)-Count|Rest]) :-
    number(Lower), number(Upper), Upper > Lower,
    integer(Count), Count >= 0,
    Width is Upper - Lower,
    valid_histogram_bins_(Rest, Upper, Width).

valid_histogram_bins_([], _PreviousUpper, _Width).
valid_histogram_bins_([bin(Lower, Upper)-Count|Rest], PreviousUpper, Width) :-
    Lower =:= PreviousUpper,
    Upper > Lower,
    Upper - Lower =:= Width,
    integer(Count), Count >= 0,
    valid_histogram_bins_(Rest, Upper, Width).

histogram_frames(Bins, [Frame]) :-
    histogram_label_counts(Bins, LabelCounts),
    pairs_freq_max(LabelCounts, FreqMax),
    labels_of(LabelCounts, Labels),
    bar_rects(LabelCounts, FreqMax, touching, "bar", Bars),
    axes_dict(Labels, FreqMax, Axes),
    Scene = _{ format: "data-display", version: 2, mode: "histogram",
               axes: Axes, bars: Bars, dots: [] },
    Frame = _{ step: 1, verb: "group_equal_width_intervals",
               caption: "Group numerical values into equal-width intervals; touching bars preserve the continuous scale.",
               sceneChanged: true, scene: Scene }.

histogram_label_counts([], []).
histogram_label_counts([bin(Lower, Upper)-Count|Rest],
                       [Label-Count|LabelCounts]) :-
    format(atom(Label), '[~w,~w)', [Lower, Upper]),
    histogram_label_counts(Rest, LabelCounts).

valid_five_number(five_number(Minimum, Q1, Median, Q3, Maximum)) :-
    maplist(number, [Minimum, Q1, Median, Q3, Maximum]),
    Minimum =< Q1, Q1 =< Median, Median =< Q3, Q3 =< Maximum.

box_plot_frame(five_number(Minimum, Q1, Median, Q3, Maximum), Frame) :-
    box_x(Minimum, Minimum, Maximum, XMinimum),
    box_x(Q1, Minimum, Maximum, XQ1),
    box_x(Median, Minimum, Maximum, XMedian),
    box_x(Q3, Minimum, Maximum, XQ3),
    box_x(Maximum, Minimum, Maximum, XMaximum),
    BoxPlot = _{ xMin: XMinimum, xQ1: XQ1, xMedian: XMedian,
                 xQ3: XQ3, xMax: XMaximum, y: 190,
                 minimum: Minimum, q1: Q1, median: Median,
                 q3: Q3, maximum: Maximum, role: "bar" },
    Scene = _{ format: "data-display", version: 2, mode: "box",
               axes: _{ categoryLabels: [], freqMax: 0 },
               bars: [], dots: [], boxPlot: BoxPlot },
    Frame = _{ step: 1, verb: "mark_five_number_summary",
               caption: "Mark the minimum, quartiles, median, and maximum; the box spans the middle half of the data.",
               sceneChanged: true, scene: Scene }.

box_x(_Value, Minimum, Maximum, 300) :- Minimum =:= Maximum, !.
box_x(Value, Minimum, Maximum, X) :-
    X is round(80 + 400 * (Value - Minimum) / (Maximum - Minimum)).

%!  gen_frames(+Spec, -Frames) for the frames-only entry point.
gen_frames(bar_chart(Pairs), Frames) :-
    clean_pairs(Pairs, Clean), Clean \== [],
    !,
    pairs_freq_max(Clean, FreqMax),
    labels_of(Clean, Labels),
    bar_frames(Clean, FreqMax, Labels, Frames).
gen_frames(dot_plot(Values), Frames) :-
    clean_values(Values, Clean), Clean \== [],
    !,
    value_labels(Clean, Labels),
    dot_freq_max(Clean, FreqMax),
    dot_frames(Clean, Labels, FreqMax, Frames).
gen_frames(histogram(Bins), Frames) :-
    valid_histogram_bins(Bins), !,
    histogram_frames(Bins, Frames).
gen_frames(box_plot(FiveNumber), [Frame]) :-
    valid_five_number(FiveNumber), !,
    box_plot_frame(FiveNumber, Frame).

%!  deferred_frame(+Spec, -Frame) is det.
%   An undisplayable spec is annotation-only: an empty display band, no throw.
deferred_frame(Spec, Frame) :-
    term_to_string(Spec, SpecStr),
    format(string(Cap), "No data display for ~w; nothing drawn.", [SpecStr]),
    Scene = _{ format: "data-display", version: 2, mode: "bar",
               axes: _{ categoryLabels: [], freqMax: 0 },
               bars: [], dots: [] },
    Frame = _{ step: 1, verb: SpecStr, caption: Cap,
               sceneChanged: false, scene: Scene }.

%!  canvas_dict(-Canvas) is det.
canvas_dict(_{ width: 560, height: 420 }).

%!  term_to_string(+Term, -String) is det.
term_to_string(Term, String) :-
    ( string(Term)
    -> String = Term
    ;  format(string(String), '~w', [Term])
    ).
