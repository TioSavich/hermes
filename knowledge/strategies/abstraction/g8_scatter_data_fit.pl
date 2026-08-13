:- encoding(utf8).
/** <module> Grade 8 pilot: fitting a line to a table of paired measurements
 *
 * WHAT THIS IS. A quarantined pilot automaton for the doing IM grade 8 unit 6
 * asks for, and unit 9 returns to with latitude and temperature: given a table
 * of paired numerical measurements, fit a line to the data, say which way the
 * association runs, report each point's residual, and name the point that sits
 * furthest from the line.
 *
 * WHY IT IS NEW. `g8_linear_model_from_observations` fits a line through TWO
 * observations exactly, which is what units 3 and 5 ask for. A scatter plot
 * has eighteen or twenty-four points and no two of them determine the line;
 * the doing is a fit over all of them. No registered machine takes a list of
 * paired measurements at all: the statistics machines summarise one variable
 * at a time. This pilot supplies the two-variable fit and leaves both the
 * round-one pilot and every registered machine untouched.
 *
 * THE FIT IS EXACT. The least-squares line is computed from exact rational
 * sums, never from floats, so the slope of the twenty-four-city latitude and
 * temperature table is an exact fraction rather than a rounded decimal. A
 * rounded decimal sits beside it, labelled an approximation.
 *
 * VERIFICATION IS THE NORMAL EQUATIONS. A least-squares line is defined by two
 * conditions: the residuals sum to zero, and the residuals weighted by their
 * inputs sum to zero. This pilot computes every residual and checks both sums
 * are exactly zero. That is a real check rather than a restatement — an
 * arithmetic slip anywhere in the sums breaks it — and it is only available
 * because nothing was rounded on the way.
 *
 * ASSOCIATION IS REPORTED, NEVER ADJUDICATED. The automaton reports the sign
 * of the slope and each residual. It does not decide whether a point is an
 * outlier; it names the point with the largest absolute residual and leaves
 * the judgement where it belongs. Deciding what counts as far enough is a
 * judgement about a situation, and this engine computes rather than judges.
 *
 * REFUSALS. Fewer than three points is not a scatter plot and refuses by name;
 * two points are the round-one pilot's doing, not this one. Inputs that all
 * share one x value determine no line and refuse.
 *
 * DEFORMATION PARTNER. One, attested in this repository's research corpus:
 * `steepness_read_as_segment_length` reproduces db_row 38411 (Stump 2001,
 * Journal of Mathematical Behavior, p. 216), where a student measures the
 * slanted line's own length instead of forming the ratio of rise to run, and
 * reports that length where the slope was asked for.
 *
 * QUARANTINE. Nothing imports this module; it renames nothing; its rows are
 * authored and vetoable one by one. Check: `check_g8_scatter_data_fit/0`.
 */

:- module(g8_scatter_data_fit,
          [ run_g8_scatter_fit/4,
            g8_scatter_from_json/2,
            g8_scatter_states/1,
            g8_scatter_state_label/4,
            g8_scatter_summary/1,
            g8_scatter_receipt/5,
            check_g8_scatter_data_fit/0
          ]).

:- use_module(strategies('abstraction/g8_quantity_input'),
              [ g8_quantity/2, g8_rational_text/2,
                g8_decimal_approximation/3 ]).

% ==========================================================================
% 1. INPUT CONTRACT
%
%   {"kind":"paired_measurements",
%    "input_name":"right hand length (cm)",
%    "output_name":"right foot length (cm)",
%    "labels":["person A","person B","person C","person D","person E"],
%    "pairs":[[19,27],[21,30],[17,23],[18,24],[19,26]]}
% ==========================================================================

g8_scatter_input_contract(
    '{\"kind\":\"paired_measurements\",\"input_name\":\"string\",\"output_name\":\"string\",\"labels\":[\"string\"],\"pairs\":[[\"number\"]]}',
    '{\"kind\":\"paired_measurements\",\"input_name\":\"hand\",\"output_name\":\"foot\",\"labels\":[\"A\",\"B\",\"C\"],\"pairs\":[[19,27],[21,30],[17,23]]}').

g8_scatter_from_json(Dict, paired(Xs, Ys, Labels, names(In, Out))) :-
    is_dict(Dict),
    get_dict(kind, Dict, "paired_measurements"),
    get_dict(pairs, Dict, Raw),
    length(Raw, N), N >= 3,
    pairs_of(Raw, Xs, Ys),
    \+ all_same(Xs),
    (   get_dict(labels, Dict, L), is_list(L), length(L, N)
    ->  Labels = L
    ;   numbered_labels(N, Labels)
    ),
    ( get_dict(input_name, Dict, A), string(A) -> In = A ; In = "input" ),
    ( get_dict(output_name, Dict, B), string(B) -> Out = B ; Out = "output" ).

g8_scatter_from_json(Dict, queried(Paired, Queries)) :-
    is_dict(Dict),
    get_dict(kind, Dict, "paired_measurements_with_queries"),
    get_dict(data, Dict, Data),
    g8_scatter_from_json(Data.put(kind, "paired_measurements"), Paired),
    get_dict(queries, Dict, Raw), Raw \== [],
    query_pairs(Raw, Queries).

query_pairs([], []).
query_pairs([q(L, X, Y)|T], [q(L, X, Y)|R]) :- !, query_pairs(T, R).
query_pairs([D|T], [q(Label, X, Y)|R]) :-
    get_dict(label, D, Label),
    get_dict(input, D, X0), get_dict(actual, D, Y0),
    g8_quantity(X0, X), g8_quantity(Y0, Y),
    query_pairs(T, R).

pairs_of([], [], []).
pairs_of([[X0, Y0]|T], [X|Xs], [Y|Ys]) :-
    g8_quantity(X0, X), g8_quantity(Y0, Y),
    pairs_of(T, Xs, Ys).

all_same([]).
all_same([H|T]) :- forall(member(V, T), V =:= H).

numbered_labels(N, Labels) :-
    numlist(1, N, Ns),
    numbered_labels_(Ns, Labels).
numbered_labels_([], []).
numbered_labels_([N|Ns], [L|Ls]) :-
    format(string(L), "point ~w", [N]),
    numbered_labels_(Ns, Ls).

% ==========================================================================
% 2. STATES
% ==========================================================================

g8_scatter_states(
    [ q_read_the_paired_measurements,
      q_name_the_two_variables,
      q_accumulate_the_sums,
      q_form_the_slope,
      q_form_the_vertical_intercept,
      q_compute_every_residual,
      q_verify_the_normal_equations,
      q_accept_the_fitted_line,
      q_report_association_direction,
      q_name_the_largest_residual,
      q_report_the_range_of_each_variable,
      q_refuse_undetermined_line,
      q_measure_the_segment_instead_of_the_ratio ]).

% g8_scatter_state_label(State, Tradition, Label, Citation).
g8_scatter_state_label(q_read_the_paired_measurements, illustrative_mathematics,
    "each row holds two measurements of the same thing",
    "IM Grade 8 Unit 6 Lesson 1, Organizing Data").
g8_scatter_state_label(q_name_the_two_variables, ccss,
    "bivariate measurement data",
    "CCSS 8.SP.A.1, via IM Grade 8 Unit 6 Lesson 3").
g8_scatter_state_label(q_accept_the_fitted_line, illustrative_mathematics,
    "a line that fits the data",
    "IM Grade 8 Unit 6 Lesson 5, Describing Trends in Scatter Plots").
g8_scatter_state_label(q_accept_the_fitted_line, ccss,
    "informally fit a straight line",
    "CCSS 8.SP.A.2, via IM Grade 8 Unit 6 Lesson 5").
g8_scatter_state_label(q_compute_every_residual, illustrative_mathematics,
    "how far each point sits above or below the line",
    "IM Grade 8 Unit 6 Lesson 5, Describing Trends in Scatter Plots").
g8_scatter_state_label(q_verify_the_normal_equations, provisional,
    "check that the residuals balance",
    "provisional; no community label sourced for this checking step").
g8_scatter_state_label(q_report_association_direction, illustrative_mathematics,
    "as one increases the other tends to increase or decrease",
    "IM Grade 8 Unit 6 Lesson 6, The Slope of a Fitted Line").
g8_scatter_state_label(q_name_the_largest_residual, illustrative_mathematics,
    "the point that sits furthest from the line",
    "IM Grade 8 Unit 6 Lesson 8, Observing More Patterns in Scatter Plots").
g8_scatter_state_label(q_measure_the_segment_instead_of_the_ratio, stump,
    "steepness measured as the line's own length",
    "db_row 38411; Stump 2001, Journal of Mathematical Behavior, p. 216").

% ==========================================================================
% 3. TRANSITIONS
% ==========================================================================

g8_scatter_transition(least_squares_line_from_pairs,
    q_read_the_paired_measurements, name_the_two_variables,
    q_name_the_two_variables).
g8_scatter_transition(least_squares_line_from_pairs,
    q_name_the_two_variables, accumulate_the_sums, q_accumulate_the_sums).
g8_scatter_transition(least_squares_line_from_pairs,
    q_accumulate_the_sums, form_the_slope, q_form_the_slope).
g8_scatter_transition(least_squares_line_from_pairs,
    q_form_the_slope, form_the_vertical_intercept,
    q_form_the_vertical_intercept).
g8_scatter_transition(least_squares_line_from_pairs,
    q_form_the_vertical_intercept, compute_every_residual,
    q_compute_every_residual).
g8_scatter_transition(least_squares_line_from_pairs,
    q_compute_every_residual, verify_the_normal_equations,
    q_verify_the_normal_equations).
g8_scatter_transition(least_squares_line_from_pairs,
    q_verify_the_normal_equations, report_the_fitted_line,
    q_accept_the_fitted_line).
g8_scatter_transition(least_squares_line_from_pairs,
    q_accumulate_the_sums, refuse_undetermined_line, q_refuse_undetermined_line).
g8_scatter_transition(association_direction_from_the_fit,
    q_accept_the_fitted_line, read_the_sign_of_the_slope,
    q_report_association_direction).
g8_scatter_transition(furthest_point_from_the_fitted_line,
    q_compute_every_residual, name_the_largest_residual,
    q_name_the_largest_residual).
g8_scatter_transition(range_of_each_variable,
    q_read_the_paired_measurements, report_the_range_of_each_variable,
    q_report_the_range_of_each_variable).
g8_scatter_transition(steepness_read_as_segment_length,
    q_accumulate_the_sums, measure_the_segment_instead_of_the_ratio,
    q_measure_the_segment_instead_of_the_ratio).

% ==========================================================================
% 4. THE RUN
% ==========================================================================

run_g8_scatter_fit(least_squares_line_from_pairs,
                   paired(Xs, Ys, Labels, names(In, Out)), Outcome, Trace) :-
    fit(Xs, Ys, Slope, Intercept, Residuals, SumResiduals, SumWeighted),
    (   SumResiduals =:= 0, SumWeighted =:= 0
    ->  Validity = correct, NormalEquations = closed
    ;   Validity = unvindicated, NormalEquations = open
    ),
    g8_rational_text(Slope, SlopeText),
    g8_rational_text(Intercept, InterceptText),
    g8_decimal_approximation(Slope, 4, SlopeDecimal),
    g8_decimal_approximation(Intercept, 4, InterceptDecimal),
    length(Xs, N),
    Outcome = action_outcome(
        least_squares_line_from_pairs,
        [ classification(productive),
          cluster(g8_scatter_plots_and_line_fit),
          automaton_state(q_accept_the_fitted_line),
          vocabulary([scatter_plot, bivariate_data, line_of_fit,
                      slope, vertical_intercept, residual]),
          input(paired(Xs, Ys, Labels, names(In, Out))),
          result(fitted_line(SlopeText, InterceptText)),
          expected(fitted_line(SlopeText, InterceptText)),
          model(Slope, Intercept),
          point_count(N),
          residuals(Residuals),
          normal_equations(NormalEquations),
          decimal_approximation(SlopeDecimal, InterceptDecimal),
          invariant(the_residuals_and_their_weighted_sum_are_both_zero),
          validity(Validity) ]),
    Trace = [ read_the_paired_measurements(N),
              name_the_two_variables(In, Out),
              accumulate_the_sums(N),
              form_the_slope(SlopeText),
              form_the_vertical_intercept(InterceptText),
              compute_every_residual(N),
              verify_the_normal_equations(SumResiduals, SumWeighted),
              report_the_fitted_line(SlopeText, InterceptText) ].
run_g8_scatter_fit(association_direction_from_the_fit,
                   paired(Xs, Ys, Labels, Names), Outcome, Trace) :-
    fit(Xs, Ys, Slope, Intercept, _, SumResiduals, SumWeighted),
    ( SumResiduals =:= 0, SumWeighted =:= 0 -> Validity = correct
    ; Validity = unvindicated ),
    (   Slope > 0 -> Direction = positive_association
    ;   Slope < 0 -> Direction = negative_association
    ;   Direction = no_linear_association
    ),
    g8_rational_text(Slope, SlopeText),
    Outcome = action_outcome(
        association_direction_from_the_fit,
        [ classification(productive),
          cluster(g8_scatter_plots_and_line_fit),
          automaton_state(q_report_association_direction),
          vocabulary([scatter_plot, association, positive, negative, slope]),
          input(paired(Xs, Ys, Labels, Names)),
          result(Direction),
          expected(Direction),
          model(Slope, Intercept),
          slope(SlopeText),
          invariant(the_residuals_and_their_weighted_sum_are_both_zero),
          validity(Validity) ]),
    Trace = [ read_the_sign_of_the_slope(SlopeText),
              report_association_direction(Direction) ].
run_g8_scatter_fit(furthest_point_from_the_fitted_line,
                   paired(Xs, Ys, Labels, Names), Outcome, Trace) :-
    fit(Xs, Ys, Slope, Intercept, Residuals, SumResiduals, SumWeighted),
    ( SumResiduals =:= 0, SumWeighted =:= 0 -> Validity = correct
    ; Validity = unvindicated ),
    furthest(Residuals, Labels, Label, Residual),
    g8_rational_text(Residual, ResidualText),
    Outcome = action_outcome(
        furthest_point_from_the_fitted_line,
        [ classification(productive),
          cluster(g8_scatter_plots_and_line_fit),
          automaton_state(q_name_the_largest_residual),
          vocabulary([scatter_plot, residual, line_of_fit, distance_from_line]),
          input(paired(Xs, Ys, Labels, Names)),
          result(furthest_point(Label, ResidualText)),
          expected(furthest_point(Label, ResidualText)),
          model(Slope, Intercept),
          residuals(Residuals),
          invariant(the_residuals_and_their_weighted_sum_are_both_zero),
          validity(Validity) ]),
    Trace = [ compute_every_residual(Residuals),
              name_the_largest_residual(Label, ResidualText) ].
run_g8_scatter_fit(range_of_each_variable,
                   paired(Xs, Ys, Labels, names(In, Out)), Outcome, Trace) :-
    min_max(Xs, XLow, XHigh), min_max(Ys, YLow, YHigh),
    XRange is XHigh - XLow, YRange is YHigh - YLow,
    Rebuilt is XLow + XRange,
    ( Rebuilt =:= XHigh -> Validity = correct ; Validity = unvindicated ),
    g8_rational_text(XRange, XText), g8_rational_text(YRange, YText),
    Outcome = action_outcome(
        range_of_each_variable,
        [ classification(productive),
          cluster(g8_scatter_plots_and_line_fit),
          automaton_state(q_report_the_range_of_each_variable),
          vocabulary([range, minimum, maximum, variable, spread]),
          input(paired(Xs, Ys, Labels, names(In, Out))),
          result(ranges(In-XText, Out-YText)),
          expected(ranges(In-XText, Out-YText)),
          bounds(XLow, XHigh, YLow, YHigh),
          invariant(the_low_plus_the_range_is_the_high),
          validity(Validity) ]),
    Trace = [ read_the_paired_measurements(In, Out),
              report_the_range_of_each_variable(XText, YText) ].
run_g8_scatter_fit(steepness_read_as_segment_length,
                   paired(Xs, Ys, Labels, Names), Outcome, Trace) :-
    % Attested locus: a fitted line with a non-zero rise AND run, where the
    % segment's length and the rise-over-run ratio genuinely differ.
    fit(Xs, Ys, Slope, Intercept, _, _, _),
    Slope =\= 0,
    min_max(Xs, XLow, XHigh),
    Run is XHigh - XLow,
    Run > 0,
    Rise is Slope * Run,
    SegmentSquared is Run * Run + Rise * Rise,
    g8_rational_text(Slope, SlopeText),
    g8_rational_text(SegmentSquared, SegmentText),
    ( SegmentSquared =\= Slope * Slope -> Validity = incorrect
    ; Validity = unvindicated ),
    Outcome = action_outcome(
        steepness_read_as_segment_length,
        [ classification(deformation),
          cluster(g8_scatter_plots_and_line_fit),
          automaton_state(q_measure_the_segment_instead_of_the_ratio),
          vocabulary([slope, steepness, rise, run, segment_length]),
          input(paired(Xs, Ys, Labels, Names)),
          expected(slope(SlopeText)),
          result(steepness_as_squared_segment_length(SegmentText)),
          model(Slope, Intercept),
          deformation_of(least_squares_line_from_pairs),
          violated_invariant(slope_is_a_ratio_not_a_length),
          attested_as(db_row(38411),
                      "Stump 2001, Journal of Mathematical Behavior, p. 216"),
          validity(Validity) ]),
    Trace = [ accumulate_the_sums(Run, Rise),
              measure_the_segment_instead_of_the_ratio(SegmentText) ].

run_g8_scatter_fit(predict_and_compare_at_queries,
                   queried(paired(Xs, Ys, Labels, names(In, Out)), Queries),
                   Outcome, Trace) :-
    fit(Xs, Ys, Slope, Intercept, _, SumResiduals, SumWeighted),
    predictions(Queries, Slope, Intercept, Predictions, Closes),
    (   SumResiduals =:= 0, SumWeighted =:= 0,
        forall(member(C, Closes), C == closes)
    ->  Validity = correct
    ;   Validity = unvindicated
    ),
    furthest_query(Predictions, Label, Residual),
    g8_rational_text(Residual, ResidualText),
    predictions_text(Predictions, Reported),
    g8_rational_text(Slope, SlopeText),
    g8_rational_text(Intercept, InterceptText),
    Outcome = action_outcome(
        predict_and_compare_at_queries,
        [ classification(productive),
          cluster(g8_scatter_plots_and_line_fit),
          automaton_state(q_name_the_largest_residual),
          vocabulary([linear_model, prediction, actual_value, residual,
                      outlier, scatter_plot]),
          input(queried(paired(Xs, Ys, Labels, names(In, Out)), Queries)),
          result(predictions(Reported)),
          expected(predictions(Reported)),
          model(Slope, Intercept),
          model_text(SlopeText, InterceptText),
          furthest_query(Label, ResidualText),
          reconstruction(Closes),
          invariant(prediction_plus_residual_is_the_actual_value),
          validity(Validity) ]),
    Trace = [ read_the_paired_measurements(In, Out),
              report_the_fitted_line(SlopeText, InterceptText),
              compute_every_residual(Reported),
              name_the_largest_residual(Label, ResidualText) ].

% Predicted value, residual, and the exact reconstruction check per query.
predictions([], _, _, [], []).
predictions([q(L, X, Y)|T], Slope, Intercept,
            [p(L, Predicted, Residual)|Ps], [Close|Cs]) :-
    Predicted is Slope * X + Intercept,
    Residual is Y - Predicted,
    Rebuilt is Predicted + Residual,
    ( Rebuilt =:= Y -> Close = closes ; Close = fails ),
    predictions(T, Slope, Intercept, Ps, Cs).

predictions_text([], []).
predictions_text([p(L, P, R)|T], [L-PT-RT|Rest]) :-
    g8_decimal_approximation(P, 2, PF), g8_decimal_approximation(R, 2, RF),
    atom_string(PF, PT0), atom_string(RF, RT0),
    PT = PT0, RT = RT0,
    predictions_text(T, Rest).

furthest_query([p(L, _, R)|T], Label, Residual) :-
    Size is abs(R),
    furthest_query_(T, Size, L, R, Label, Residual).
furthest_query_([], _, L, R, L, R).
furthest_query_([p(L, _, R)|T], Best, BL, BR, Label, Residual) :-
    Size is abs(R),
    ( Size > Best -> furthest_query_(T, Size, L, R, Label, Residual)
    ; furthest_query_(T, Best, BL, BR, Label, Residual) ).

%!  fit(+Xs, +Ys, -Slope, -Intercept, -Residuals, -SumR, -SumWeighted) is semidet.
%
%   Exact rational least squares. The two sums returned are the left sides of
%   the normal equations; both are zero for a correct fit.
fit(Xs, Ys, Slope, Intercept, Residuals, SumResiduals, SumWeighted) :-
    length(Xs, N), N >= 3,
    sum_list(Xs, Sx), sum_list(Ys, Sy),
    dot(Xs, Xs, Sxx), dot(Xs, Ys, Sxy),
    Denominator is N * Sxx - Sx * Sx,
    Denominator =\= 0,
    Slope is (N * Sxy - Sx * Sy) rdiv Denominator,
    Intercept is (Sy - Slope * Sx) rdiv N,
    residuals(Xs, Ys, Slope, Intercept, Residuals),
    sum_list(Residuals, SumResiduals),
    dot(Xs, Residuals, SumWeighted).

dot([], [], 0).
dot([A|As], [B|Bs], Total) :-
    dot(As, Bs, Rest),
    Total is Rest + A * B.

residuals([], [], _, _, []).
residuals([X|Xs], [Y|Ys], Slope, Intercept, [R|Rs]) :-
    R is Y - (Slope * X + Intercept),
    residuals(Xs, Ys, Slope, Intercept, Rs).

furthest([R|Rs], [L|Ls], Label, Residual) :-
    Size is abs(R),
    furthest_(Rs, Ls, Size, L, R, Label, Residual).

furthest_([], [], _, Label, Residual, Label, Residual).
furthest_([R|Rs], [L|Ls], Best, BestLabel, BestResidual, Label, Residual) :-
    Size is abs(R),
    (   Size > Best
    ->  furthest_(Rs, Ls, Size, L, R, Label, Residual)
    ;   furthest_(Rs, Ls, Best, BestLabel, BestResidual, Label, Residual)
    ).

min_max([H|T], Low, High) :- min_max_(T, H, H, Low, High).
min_max_([], Low, High, Low, High).
min_max_([H|T], Low0, High0, Low, High) :-
    ( H < Low0 -> Low1 = H ; Low1 = Low0 ),
    ( H > High0 -> High1 = H ; High1 = High0 ),
    min_max_(T, Low1, High1, Low, High).

% ==========================================================================
% 5. SELF-SUMMARY
% ==========================================================================

g8_scatter_summary(
    summary{ module: g8_scatter_data_fit,
             status: authored_pilot,
             generated: false,
             grade: 8,
             cluster: g8_scatter_plots_and_line_fit,
             doings: [ least_squares_line_from_pairs,
                       association_direction_from_the_fit,
                       furthest_point_from_the_fitted_line,
                       range_of_each_variable,
                       steepness_read_as_segment_length ],
             verification: both_normal_equations_are_exactly_zero,
             arithmetic: exact_rational,
             adjudication: none_the_engine_names_the_furthest_point_only,
             imported_by: none,
             extant_machines_left_untouched:
                 [ 'statistics/mean_as_fair_share',
                   'statistics/dot_plot_frequency_representation' ],
             sibling_pilot_left_untouched: g8_linear_model_from_observations }).

% ==========================================================================
% 6. RECEIPTS
% ==========================================================================

g8_scatter_receipt(
    'im_defrag_1d7ef1e1994dd1ac3ecda619_1', 'IM-G8-U6-L2',
    least_squares_line_from_pairs,
    _{kind: "paired_measurements",
      input_name: "right hand length (cm)",
      output_name: "right foot length (cm)",
      labels: ["person A", "person B", "person C", "person D", "person E"],
      pairs: [[19, 27], [21, 30], [17, 23], [18, 24], [19, 26]]},
    fitted_line("20/11", "-90/11")).
g8_scatter_receipt(
    'im_defrag_1d7ef1e1994dd1ac3ecda619_1', 'IM-G8-U6-L2',
    association_direction_from_the_fit,
    _{kind: "paired_measurements",
      input_name: "right hand length (cm)",
      output_name: "right foot length (cm)",
      labels: ["person A", "person B", "person C", "person D", "person E"],
      pairs: [[19, 27], [21, 30], [17, 23], [18, 24], [19, 26]]},
    positive_association).
g8_scatter_receipt(
    'im_defrag_6e6162c3162d953d082475ed_1', 'IM-G8-U6-L1',
    association_direction_from_the_fit,
    _{kind: "paired_measurements",
      input_name: "length of short side (in)",
      output_name: "length of perimeter (in)",
      labels: ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j"],
      pairs: [[0.25, 1], [2, 7.5], [6.5, 22], [3, 9.5], [0.5, 2],
              [1.25, 3.5], [3.5, 12.5], [1.5, 5], [4, 14], [1, 2.5]]},
    positive_association).
g8_scatter_receipt(
    'im_defrag_ad3822a6e4930163f8087660_1', 'IM-G8-U6-L1',
    least_squares_line_from_pairs,
    _{kind: "paired_measurements",
      input_name: "length of short sides (in)",
      output_name: "length of perimeter (in)",
      labels: ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j"],
      pairs: [[0.25, 1], [2, 7.5], [6.5, 22], [3, 9.5], [0.5, 2],
              [1.25, 3.5], [3.5, 12.5], [1.5, 5], [4, 14], [1, 2.5]]},
    fitted_line("2301/668", "-387/2672")).
g8_scatter_receipt(
    'im_defrag_44c7804894be1605517eac9d_1', 'IM-G8-U6-L3',
    association_direction_from_the_fit,
    _{kind: "paired_measurements",
      input_name: "weight (kg)", output_name: "fuel efficiency (mpg)",
      labels: ["A", "B", "C", "D", "E", "F", "G", "H", "I",
               "J", "K", "L", "M", "N", "O", "P", "Q", "R"],
      pairs: [[1549, 25], [1610, 20], [1737, 21], [1777, 20], [1486, 23],
              [1962, 16], [2384, 16], [1957, 19], [2212, 16], [1115, 29],
              [2068, 18], [1663, 19], [2216, 18], [1432, 25], [1987, 18],
              [1580, 26], [1234, 30], [1656, 23]]},
    negative_association).
g8_scatter_receipt(
    'im_defrag_43bc387461307a4a71bd7989_1', 'IM-G8-U6-L3',
    furthest_point_from_the_fitted_line,
    _{kind: "paired_measurements",
      input_name: "weight (kg)", output_name: "fuel efficiency (mpg)",
      labels: ["A", "B", "C", "D", "E", "F", "G", "H", "I",
               "J", "K", "L", "M", "N", "O", "P", "Q", "R"],
      pairs: [[1549, 25], [1610, 20], [1737, 21], [1777, 20], [1486, 23],
              [1962, 16], [2384, 16], [1957, 19], [2212, 16], [1115, 29],
              [2068, 18], [1663, 19], [2216, 18], [1432, 25], [1987, 18],
              [1580, 26], [1234, 30], [1656, 23]]},
    furthest_point("L", "-120033466/36419021")).
g8_scatter_receipt(
    'im_defrag_ee04bc96728cabda39bc9596_1', 'IM-G8-U9-L5',
    range_of_each_variable,
    _{kind: "paired_measurements",
      input_name: "latitude (degrees north)",
      output_name: "temperature (degrees Fahrenheit)",
      labels: ["Atlanta", "Belmopan", "Boston", "Chinandega", "Dallas",
               "Denver", "Edmonton", "Fairbanks", "Juneau", "Kansas City",
               "Lincoln", "Miami", "Minneapolis", "New York City", "Orlando",
               "Philadelphia", "Portland", "Puerto Morelos", "San Antonio",
               "San Francisco", "Seattle", "Tampa", "Tucson", "Yellowknife"],
      pairs: [[33.75, 84], [17.31, 87], [42.36, 73], [12.36, 91],
              [32.78, 87], [39.74, 81], [53.55, 62], [64.84, 55],
              [58.34, 56], [39.10, 80], [40.81, 80], [25.76, 89],
              [44.98, 73], [40.71, 76], [28.54, 92], [39.95, 79],
              [43.66, 71], [20.89, 89], [29.42, 90], [37.78, 70],
              [47.61, 72], [27.95, 89], [32.25, 96], [62.45, 50]]},
    ranges("latitude (degrees north)"-"1312/25",
           "temperature (degrees Fahrenheit)"-"46")).
g8_scatter_receipt(
    'im_defrag_ee04bc96728cabda39bc9596_1', 'IM-G8-U9-L5',
    association_direction_from_the_fit,
    _{kind: "paired_measurements",
      input_name: "latitude (degrees north)",
      output_name: "temperature (degrees Fahrenheit)",
      labels: ["Atlanta", "Belmopan", "Boston", "Chinandega", "Dallas",
               "Denver", "Edmonton", "Fairbanks", "Juneau", "Kansas City",
               "Lincoln", "Miami", "Minneapolis", "New York City", "Orlando",
               "Philadelphia", "Portland", "Puerto Morelos", "San Antonio",
               "San Francisco", "Seattle", "Tampa", "Tucson", "Yellowknife"],
      pairs: [[33.75, 84], [17.31, 87], [42.36, 73], [12.36, 91],
              [32.78, 87], [39.74, 81], [53.55, 62], [64.84, 55],
              [58.34, 56], [39.10, 80], [40.81, 80], [25.76, 89],
              [44.98, 73], [40.71, 76], [28.54, 92], [39.95, 79],
              [43.66, 71], [20.89, 89], [29.42, 90], [37.78, 70],
              [47.61, 72], [27.95, 89], [32.25, 96], [62.45, 50]]},
    negative_association).

% Round 3: rows routed through this machine after the residue sweep.
g8_scatter_receipt(
    'im_defrag_bc03620bcc50745dbd8a8664_1', 'IM-G8-U6-L3',
    association_direction_from_the_fit,
    _{kind: "paired_measurements",
      input_name: "quarterback rating", output_name: "number of wins",
      labels: ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L",
               "M", "N", "O", "P", "Q"],
      pairs: [[93.8, 4], [102.2, 12], [93.6, 6], [89, 8], [88.2, 5],
              [97, 7], [88.7, 6], [91.1, 7], [92.7, 10], [88, 10],
              [101.6, 9], [104.6, 13], [84.2, 6], [99.4, 15], [110.1, 10],
              [95.4, 11], [88.7, 11]]},
    positive_association).
g8_scatter_receipt(
    'im_defrag_8b2513acecb61a389c0a85db_1', 'IM-G8-U9-L6',
    % The model is the line fitted to IM-G8-U9-L5's own 24-city table; the
    % three query latitudes and their actual temperatures are printed in
    % this row.
    predict_and_compare_at_queries,
    _{kind: "paired_measurements_with_queries",
      data: _{input_name: "latitude (degrees north)",
              output_name: "temperature (degrees Fahrenheit)",
              pairs: [[33.75, 84], [17.31, 87], [42.36, 73], [12.36, 91],
                      [32.78, 87], [39.74, 81], [53.55, 62], [64.84, 55],
                      [58.34, 56], [39.10, 80], [40.81, 80], [25.76, 89],
                      [44.98, 73], [40.71, 76], [28.54, 92], [39.95, 79],
                      [43.66, 71], [20.89, 89], [29.42, 90], [37.78, 70],
                      [47.61, 72], [27.95, 89], [32.25, 96], [62.45, 50]]},
      queries: [_{label: "Detroit", input: 42.33, actual: 74},
                _{label: "Albuquerque", input: 35.09, actual: 82},
                _{label: "Nome", input: 64.50, actual: 49}]},
    predictions(["Detroit"-"74.44"-"-0.44", "Albuquerque"-"80.69"-"1.31",
                 "Nome"-"55.29"-"-6.29"])).

% ==========================================================================
% 7. CHECK
% ==========================================================================

check_g8_scatter_data_fit :-
    check_receipts,
    check_normal_equations_close,
    check_attested_deformation,
    check_negative,
    format('g8_scatter_data_fit: all checks ok~n').

check_receipts :-
    findall(Lesson-Row-Doing-Result,
            ( g8_scatter_receipt(Row, Lesson, Doing, Json, Expected),
              g8_scatter_from_json(Json, Figure),
              run_g8_scatter_fit(Doing, Figure, Outcome, _),
              outcome_property(Outcome, result(Result)),
              Result = Expected,
              outcome_property(Outcome, validity(correct))
            ), Rows),
    findall(R-L, g8_scatter_receipt(R, L, _, _, _), All),
    length(All, Total), length(Rows, Passed),
    Total =:= Passed,
    format('  receipts: ~w/~w real grade 8 rows fitted, both normal equations exactly zero~n',
           [Passed, Total]),
    forall(member(Lesson-Row-Doing-Result, Rows),
           format('    ~w  ~w  ~w -> ~q~n', [Lesson, Row, Doing, Result])).

check_normal_equations_close :-
    % A line laid exactly through collinear points has zero residuals, and
    % a scattered set still balances its residuals to exactly zero.
    g8_scatter_from_json(
        _{kind: "paired_measurements",
          pairs: [[1, 3], [2, 5], [3, 7], [4, 9]]}, Exact),
    run_g8_scatter_fit(least_squares_line_from_pairs, Exact, O1, _),
    outcome_property(O1, result(fitted_line("2", "1"))),
    outcome_property(O1, residuals(Rs)),
    forall(member(R, Rs), R =:= 0),
    g8_scatter_from_json(
        _{kind: "paired_measurements",
          pairs: [[1, 3], [2, 4], [3, 8], [4, 9]]}, Scattered),
    run_g8_scatter_fit(least_squares_line_from_pairs, Scattered, O2, _),
    outcome_property(O2, normal_equations(closed)),
    outcome_property(O2, residuals(Ss)),
    sum_list(Ss, Zero), Zero =:= 0,
    \+ forall(member(S, Ss), S =:= 0),
    format('  normal equations: collinear points give zero residuals; scattered points give non-zero residuals summing to exactly zero~n').

check_attested_deformation :-
    % db_row 38411 at the fitted-line locus: the segment measured instead of
    % the ratio formed.
    g8_scatter_from_json(
        _{kind: "paired_measurements",
          pairs: [[0, 0], [1, 1], [2, 2]]}, F),
    run_g8_scatter_fit(steepness_read_as_segment_length, F, O, _),
    outcome_property(O, expected(slope("1"))),
    outcome_property(O, result(steepness_as_squared_segment_length("8"))),
    outcome_property(O, validity(incorrect)),
    format('  attested deformation: db_row 38411 reports the squared segment length 8 where the slope is 1~n').

check_negative :-
    % Two points are the two-observation pilot's doing, not this one.
    \+ g8_scatter_from_json(
           _{kind: "paired_measurements", pairs: [[1, 2], [3, 4]]}, _),
    % Points sharing one input determine no line and refuse.
    \+ g8_scatter_from_json(
           _{kind: "paired_measurements",
             pairs: [[5, 1], [5, 2], [5, 3]]}, _),
    % A flat set gives slope zero and no linear association.
    g8_scatter_from_json(
        _{kind: "paired_measurements", pairs: [[1, 7], [2, 7], [3, 7]]}, F),
    run_g8_scatter_fit(association_direction_from_the_fit, F, O, _),
    outcome_property(O, result(no_linear_association)),
    % IM-G8-U9-L6 asks whether there are outliers: Nome misses the model
    % fitted on IM-G8-U9-L5's cities by far more than the other two cities.
    g8_scatter_from_json(
        _{kind: "paired_measurements_with_queries",
          data: _{pairs: [[33.75, 84], [17.31, 87], [42.36, 73], [12.36, 91],
                          [32.78, 87], [39.74, 81], [53.55, 62], [64.84, 55],
                          [58.34, 56], [39.10, 80], [40.81, 80], [25.76, 89],
                          [44.98, 73], [40.71, 76], [28.54, 92], [39.95, 79],
                          [43.66, 71], [20.89, 89], [29.42, 90], [37.78, 70],
                          [47.61, 72], [27.95, 89], [32.25, 96], [62.45, 50]]},
          queries: [_{label: "Detroit", input: 42.33, actual: 74},
                    _{label: "Albuquerque", input: 35.09, actual: 82},
                    _{label: "Nome", input: 64.50, actual: 49}]}, Q),
    run_g8_scatter_fit(predict_and_compare_at_queries, Q, OQ, _),
    outcome_property(OQ, furthest_query("Nome", _)),
    outcome_property(OQ, reconstruction(Closes)),
    forall(member(C, Closes), C == closes),
    format('  negative tests: two points and a single shared input both refuse; a flat set reports no linear association; Nome is the furthest prediction and every residual reconstructs~n').

outcome_property(action_outcome(_, Props), Property) :-
    memberchk(Property, Props).
