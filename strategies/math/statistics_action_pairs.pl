/** <module> Productive data and statistics action automata
 *
 * Exposes data representations, center and spread definitions, and the
 * decisions that coordinate them. Graph construction preserves the counted
 * collection; summary actions preserve the data set and measurement unit
 * while applying an explicit definition or declared distribution profile.
 */

:- module(statistics_action_pairs,
          [ run_statistics_action/5,
            statistics_action_cluster/2,
            statistics_action_vocabulary/2,
            productive_statistics_deformation/3,
            statistics_action_misconception_hook/3
          ]).

:- use_module(library(lists), [clumped/2]).
:- use_module(render(data_display_scene), [data_display_render_json/2]).


run_statistics_action(categorical_frequency_bar_representation, Pairs,
                      display(bar_chart), Outcome, Trace) :-
    valid_frequency_pairs(Pairs),
    data_display_render_json(bar_chart(Pairs), Scene),
    successful_scene(Scene),
    Outcome = action_outcome(
                  categorical_frequency_bar_representation,
                  [ classification(productive),
                    cluster(data_categorical_frequency_representation),
                    automaton_state(coordinate_categories_with_counted_bar_lengths),
                    vocabulary([categorical_data, category, frequency,
                                bar_graph, scale, axis, bar_length, count]),
                    input(Pairs),
                    result(frequency_representation(Pairs)),
                    expected(frequency_representation(Pairs)),
                    representation(Scene),
                    validity(correct)
                  ]),
    Trace = [ classify_observations_by_category,
              count_each_category(Pairs),
              establish_frequency_scale,
              raise_separated_bar_for_each_category
            ].
run_statistics_action(dot_plot_frequency_representation, Values,
                      display(dot_plot), Outcome, Trace) :-
    valid_data(Values),
    maplist(integer, Values),
    msort(Values, Sorted),
    clumped(Sorted, Frequencies),
    data_display_render_json(dot_plot(Values), Scene),
    successful_scene(Scene),
    Outcome = action_outcome(
                  dot_plot_frequency_representation,
                  [ classification(productive),
                    cluster(data_value_frequency_representation),
                    automaton_state(stack_one_mark_per_observation_at_value),
                    vocabulary([measurement_data, number_line, value,
                                frequency, dot_plot, line_plot, stacked_mark]),
                    input(Values),
                    frequencies(Frequencies),
                    result(dot_plot(Values)),
                    expected(dot_plot(Values)),
                    representation(Scene),
                    validity(correct)
                  ]),
    Trace = [ establish_value_axis,
              preserve_one_mark_per_observation,
              stack_marks_at_equal_values(Frequencies)
            ].
run_statistics_action(statistical_question_variability_classification,
                      question(Variable, expects_variability),
                      population(Population), Outcome, Trace) :-
    atom(Variable),
    nonvar(Population),
    Outcome = action_outcome(
                  statistical_question_variability_classification,
                  [ classification(productive),
                    cluster(data_question_as_anticipated_variability),
                    automaton_state(coordinate_variable_population_and_varied_responses),
                    vocabulary([statistical_question, population, variable,
                                observation, variability, anticipated_response]),
                    input(question(Variable, expects_variability)),
                    population(Population),
                    result(statistical_question(Variable, Population)),
                    expected(statistical_question(Variable, Population)),
                    validity(correct)
                  ]),
    Trace = [ identify_population(Population),
              identify_measured_variable(Variable),
              anticipate_varied_responses,
              classify_as_statistical_question
            ].
run_statistics_action(question_without_variability,
                      question(Variable, expects_variability),
                      population(Population), Outcome, Trace) :-
    atom(Variable),
    nonvar(Population),
    Outcome = action_outcome(
                  question_without_variability,
                  [ classification(deformation),
                    cluster(data_question_as_anticipated_variability),
                    automaton_state(treat_variable_as_one_fixed_answer),
                    vocabulary([question, answer, variable, variability]),
                    input(question(Variable, expects_variability)),
                    population(Population),
                    result(nonstatistical_question(Variable, Population)),
                    expected(statistical_question(Variable, Population)),
                    violation(anticipated_variability_erased),
                    validity(incorrect)
                  ]),
    Trace = [ identify_measured_variable(Variable),
              replace_varied_responses_with_one_fixed_answer,
              classify_as_nonstatistical_question
            ].
run_statistics_action(histogram_equal_interval_representation, Data,
                      display(histogram(BinWidth)), Outcome, Trace) :-
    valid_data(Data),
    positive_integer(BinWidth),
    equal_width_bins(Data, BinWidth, Bins),
    data_display_render_json(histogram(Bins), Scene),
    successful_scene(Scene),
    Outcome = action_outcome(
                  histogram_equal_interval_representation,
                  [ classification(productive),
                    cluster(data_distribution_equal_interval_grouping),
                    automaton_state(group_values_into_contiguous_equal_intervals),
                    vocabulary([measurement_data, distribution, interval,
                                equal_width, frequency, histogram, scale]),
                    input(Data),
                    bin_width(BinWidth),
                    bins(Bins),
                    result(histogram(Bins)),
                    expected(histogram(Bins)),
                    representation(Scene),
                    validity(correct)
                  ]),
    Trace = [ preserve_data_set(Data), choose_equal_bin_width(BinWidth),
              establish_contiguous_intervals(Bins),
              count_each_observation_once, draw_touching_interval_bars
            ].
run_statistics_action(mean_as_fair_share, Data, measurement_unit(Unit),
                      Outcome, Trace) :-
    valid_data(Data),
    sum_list(Data, Sum),
    length(Data, Count),
    reduced_rational(Sum, Count, Mean),
    Outcome = action_outcome(
                  mean_as_fair_share,
                  [ classification(productive),
                    cluster(data_center_as_fair_share),
                    automaton_state(collect_total_then_redistribute_equally),
                    vocabulary([data_set, total, count, fair_share,
                                equal_distribution, mean, measurement_unit]),
                    input(Data),
                    unit(Unit),
                    result(Mean),
                    expected(Mean),
                    validity(correct)
                  ]),
    Trace = [ preserve_data_set(Data), collect_total(Sum),
              count_values(Count), redistribute_total_equally(Mean)
            ].
run_statistics_action(mean_as_balance_point, Data, measurement_unit(Unit),
                      Outcome, Trace) :-
    valid_data(Data),
    mean_and_deviations(Data, Mean, Deviations),
    sum_rationals(Deviations, DeviationSum),
    DeviationSum = rational(0, 1),
    data_display_render_json(dot_plot(Data), Scene),
    successful_scene(Scene),
    Outcome = action_outcome(
                  mean_as_balance_point,
                  [ classification(productive),
                    cluster(data_center_as_balance_point),
                    automaton_state(balance_signed_distances_around_mean),
                    vocabulary([data_set, number_line, signed_deviation,
                                balance_point, mean, measurement_unit]),
                    input(Data), unit(Unit), deviations(Deviations),
                    result(Mean), expected(Mean), representation(Scene),
                    invariant(sum_signed_deviations(rational(0, 1))),
                    validity(correct)
                  ]),
    Trace = [ preserve_data_set(Data), locate_mean(Mean),
              measure_signed_deviations(Deviations),
              verify_balanced_deviations
            ].
run_statistics_action(mean_absolute_deviation, Data, measurement_unit(Unit),
                      Outcome, Trace) :-
    valid_data(Data),
    mean_and_deviations(Data, Mean, Deviations),
    maplist(rational_absolute, Deviations, AbsoluteDeviations),
    average_rationals(AbsoluteDeviations, MAD),
    Outcome = action_outcome(
                  mean_absolute_deviation,
                  [ classification(productive),
                    cluster(data_variability_as_average_distance),
                    automaton_state(average_absolute_distances_from_mean),
                    vocabulary([data_set, mean, deviation, absolute_value,
                                distance, variability, mean_absolute_deviation,
                                measurement_unit]),
                    input(Data), unit(Unit), center(Mean),
                    absolute_deviations(AbsoluteDeviations),
                    result(MAD), expected(MAD), validity(correct)
                  ]),
    Trace = [ preserve_data_set(Data), locate_mean(Mean),
              measure_signed_deviations(Deviations),
              take_absolute_distances(AbsoluteDeviations),
              average_distances(MAD)
            ].
run_statistics_action(mean_deviation_without_absolute_value, Data,
                      measurement_unit(Unit), Outcome, Trace) :-
    valid_data(Data),
    mean_and_deviations(Data, Mean, Deviations),
    average_rationals(Deviations, IncorrectSpread),
    mean_absolute_deviation_value(Data, ExpectedSpread),
    Outcome = action_outcome(
                  mean_deviation_without_absolute_value,
                  [ classification(deformation),
                    cluster(data_variability_as_average_distance),
                    automaton_state(cancel_signed_deviations_instead_of_measuring_distance),
                    vocabulary([mean, signed_deviation, distance,
                                mean_absolute_deviation, measurement_unit]),
                    input(Data), unit(Unit), center(Mean),
                    result(IncorrectSpread), expected(ExpectedSpread),
                    violation(signed_deviations_cancel_before_absolute_value),
                    validity(incorrect)
                  ]),
    Trace = [ locate_mean(Mean), measure_signed_deviations(Deviations),
              omit_absolute_value, average_signed_deviations(IncorrectSpread)
            ].
run_statistics_action(median_as_ordered_middle, Data, measurement_unit(Unit),
                      Outcome, Trace) :-
    valid_data(Data),
    msort(Data, Sorted),
    median_value(Sorted, Median, MiddleAction),
    Outcome = action_outcome(
                  median_as_ordered_middle,
                  [ classification(productive),
                    cluster(data_center_as_ordered_position),
                    automaton_state(order_values_then_locate_middle),
                    vocabulary([data_set, order, position, middle,
                                median, two_middle_values, measurement_unit]),
                    input(Data),
                    ordered_data(Sorted),
                    unit(Unit),
                    result(Median),
                    expected(Median),
                    validity(correct)
                  ]),
    Trace = [ preserve_data_set(Data), order_values(Sorted), MiddleAction ].
run_statistics_action(mode_as_maximal_frequency, Data, measurement_unit(Unit),
                      Outcome, Trace) :-
    valid_data(Data),
    msort(Data, Sorted),
    clumped(Sorted, Frequencies),
    maximal_frequency_values(Frequencies, Modes, MaxFrequency),
    Outcome = action_outcome(
                  mode_as_maximal_frequency,
                  [ classification(productive),
                    cluster(data_center_as_maximal_frequency),
                    automaton_state(count_equal_values_then_retain_frequency_maxima),
                    vocabulary([data_set, equal_value, frequency, maximum,
                                mode, multiple_modes, measurement_unit]),
                    input(Data),
                    frequencies(Frequencies),
                    unit(Unit),
                    result(modes(Modes)),
                    expected(modes(Modes)),
                    maximal_frequency(MaxFrequency),
                    validity(correct)
                  ]),
    Trace = [ preserve_data_set(Data), count_equal_values(Frequencies),
              retain_all_maximal_frequencies(Modes, MaxFrequency)
            ].
run_statistics_action(five_number_summary_and_iqr, Data, measurement_unit(Unit),
                      Outcome, Trace) :-
    valid_data(Data),
    msort(Data, Sorted),
    five_number_summary(Sorted, Summary, IQR),
    Outcome = action_outcome(
                  five_number_summary_and_iqr,
                  [ classification(productive),
                    cluster(data_variability_as_quartile_span),
                    automaton_state(order_split_and_measure_middle_half),
                    vocabulary([ordered_data, minimum, first_quartile, median,
                                third_quartile, maximum, interquartile_range,
                                measurement_unit]),
                    input(Data), ordered_data(Sorted), unit(Unit),
                    result(summary(Summary, iqr(IQR))),
                    expected(summary(Summary, iqr(IQR))), validity(correct)
                  ]),
    Trace = [ preserve_data_set(Data), order_values(Sorted),
              split_around_median, locate_quartiles(Summary),
              subtract_quartiles(IQR)
            ].
run_statistics_action(box_plot_from_five_number_summary, Data,
                      display(box_plot), Outcome, Trace) :-
    valid_data(Data),
    msort(Data, Sorted),
    five_number_summary(Sorted, Summary, IQR),
    numeric_five_number(Summary, NumericSummary),
    data_display_render_json(box_plot(NumericSummary), Scene),
    successful_scene(Scene),
    Outcome = action_outcome(
                  box_plot_from_five_number_summary,
                  [ classification(productive),
                    cluster(data_distribution_quartile_representation),
                    automaton_state(project_five_number_summary_to_common_scale),
                    vocabulary([number_line, five_number_summary, quartile,
                                median, interquartile_range, box_plot, whisker]),
                    input(Data), ordered_data(Sorted), summary(Summary), iqr(IQR),
                    result(box_plot(Summary)), expected(box_plot(Summary)),
                    representation(Scene), validity(correct)
                  ]),
    Trace = [ preserve_data_set(Data), order_values(Sorted),
              construct_five_number_summary(Summary),
              place_all_five_values_on_common_scale,
              draw_quartile_box_and_whiskers
            ].
run_statistics_action(distribution_summary_selection, Data,
                      distribution(Profile), Outcome, Trace) :-
    valid_data(Data),
    summary_for_profile(Profile, Data, Selection, Measures, SelectionAction),
    Outcome = action_outcome(
                  distribution_summary_selection,
                  [ classification(productive),
                    cluster(data_summary_coordinated_with_distribution_shape),
                    automaton_state(select_center_and_spread_by_declared_profile),
                    vocabulary([distribution_shape, symmetry, skew, outlier,
                                center, variability, mean, median,
                                mean_absolute_deviation, interquartile_range]),
                    input(Data), distribution_profile(Profile),
                    result(summary_choice(Selection, Measures)),
                    expected(summary_choice(Selection, Measures)),
                    validity(correct)
                  ]),
    Trace = [ preserve_data_set(Data), inspect_declared_profile(Profile),
              SelectionAction
            ].


statistics_action_cluster(categorical_frequency_bar_representation,
                          data_categorical_frequency_representation).
statistics_action_cluster(dot_plot_frequency_representation,
                          data_value_frequency_representation).
statistics_action_cluster(statistical_question_variability_classification,
                          data_question_as_anticipated_variability).
statistics_action_cluster(question_without_variability,
                          data_question_as_anticipated_variability).
statistics_action_cluster(histogram_equal_interval_representation,
                          data_distribution_equal_interval_grouping).
statistics_action_cluster(mean_as_fair_share, data_center_as_fair_share).
statistics_action_cluster(mean_as_balance_point, data_center_as_balance_point).
statistics_action_cluster(mean_absolute_deviation,
                          data_variability_as_average_distance).
statistics_action_cluster(mean_deviation_without_absolute_value,
                          data_variability_as_average_distance).
statistics_action_cluster(median_as_ordered_middle,
                          data_center_as_ordered_position).
statistics_action_cluster(mode_as_maximal_frequency,
                          data_center_as_maximal_frequency).
statistics_action_cluster(five_number_summary_and_iqr,
                          data_variability_as_quartile_span).
statistics_action_cluster(box_plot_from_five_number_summary,
                          data_distribution_quartile_representation).
statistics_action_cluster(distribution_summary_selection,
                          data_summary_coordinated_with_distribution_shape).

statistics_action_vocabulary(categorical_frequency_bar_representation,
                             [categorical_data, category, frequency, bar_graph,
                              scale, axis, bar_length, count]).
statistics_action_vocabulary(dot_plot_frequency_representation,
                             [measurement_data, number_line, value, frequency,
                              dot_plot, line_plot, stacked_mark]).
statistics_action_vocabulary(statistical_question_variability_classification,
                             [statistical_question, population, variable,
                              observation, variability, anticipated_response]).
statistics_action_vocabulary(question_without_variability,
                             [question, answer, variable, variability]).
statistics_action_vocabulary(histogram_equal_interval_representation,
                             [measurement_data, distribution, interval,
                              equal_width, frequency, histogram, scale]).
statistics_action_vocabulary(mean_as_fair_share,
                             [data_set, total, count, fair_share,
                              equal_distribution, mean, measurement_unit]).
statistics_action_vocabulary(mean_as_balance_point,
                             [data_set, number_line, signed_deviation,
                              balance_point, mean, measurement_unit]).
statistics_action_vocabulary(mean_absolute_deviation,
                             [data_set, mean, deviation, absolute_value,
                              distance, variability, mean_absolute_deviation,
                              measurement_unit]).
statistics_action_vocabulary(mean_deviation_without_absolute_value,
                             [mean, signed_deviation, distance,
                              mean_absolute_deviation, measurement_unit]).
statistics_action_vocabulary(median_as_ordered_middle,
                             [data_set, order, position, middle, median,
                              two_middle_values, measurement_unit]).
statistics_action_vocabulary(mode_as_maximal_frequency,
                             [data_set, equal_value, frequency, maximum, mode,
                              multiple_modes, measurement_unit]).
statistics_action_vocabulary(five_number_summary_and_iqr,
                             [ordered_data, minimum, first_quartile, median,
                              third_quartile, maximum, interquartile_range,
                              measurement_unit]).
statistics_action_vocabulary(box_plot_from_five_number_summary,
                             [number_line, five_number_summary, quartile, median,
                              interquartile_range, box_plot, whisker]).
statistics_action_vocabulary(distribution_summary_selection,
                             [distribution_shape, symmetry, skew, outlier,
                              center, variability, mean, median,
                              mean_absolute_deviation, interquartile_range]).

productive_statistics_deformation(
    statistical_question_variability_classification,
    question_without_variability,
    statistical_question_without_anticipated_variability).
productive_statistics_deformation(
    mean_absolute_deviation,
    mean_deviation_without_absolute_value,
    signed_deviation_cancellation).

statistics_action_misconception_hook(action_outcome(Kind, Fields),
                                     statistics_productive_monitoring(Kind), Hook) :-
    member(classification(productive), Fields),
    member(vocabulary(Vocabulary), Fields),
    Hook = action_misconception_hook(
               [ productive_statistics_action(Kind),
                 vocabulary(Vocabulary),
                 monitoring_focus(preserve_data_referent_and_definition(Kind)),
                 evidence(Fields)
               ]).
statistics_action_misconception_hook(action_outcome(Kind, Fields), Family, Hook) :-
    member(classification(deformation), Fields),
    member(violation(Violation), Fields),
    productive_statistics_deformation(ProductiveKind, Kind, Family),
    Hook = action_misconception_hook(
               [ deformation_statistics_action(Kind),
                 violation(Violation),
                 repair(recover_productive_action(ProductiveKind)),
                 evidence(Fields)
               ]).


valid_frequency_pairs([Category-Count|Rest]) :-
    atom(Category),
    integer(Count),
    Count >= 0,
    maplist(valid_frequency_pair, Rest).

valid_frequency_pair(Category-Count) :-
    atom(Category),
    integer(Count),
    Count >= 0.

valid_data([Value|Rest]) :-
    nonnegative_integer(Value),
    maplist(nonnegative_integer, Rest).

nonnegative_integer(Value) :- integer(Value), Value >= 0.
positive_integer(Value) :- integer(Value), Value > 0.

successful_scene(Scene) :-
    is_dict(Scene),
    \+ get_dict(error, Scene, _),
    get_dict(frames, Scene, Frames),
    Frames = [_|_].

reduced_rational(Numerator, Denominator, rational(ReducedNumerator, ReducedDenominator)) :-
    Denominator =\= 0,
    Sign is sign(Denominator),
    SignedNumerator is Numerator * Sign,
    PositiveDenominator is abs(Denominator),
    GCD is gcd(abs(SignedNumerator), PositiveDenominator),
    ReducedNumerator is SignedNumerator // GCD,
    ReducedDenominator is PositiveDenominator // GCD.

equal_width_bins(Data, Width, Bins) :-
    min_list(Data, Minimum),
    max_list(Data, Maximum),
    FirstLower is (Minimum // Width) * Width,
    LastLower is (Maximum // Width) * Width,
    bin_lowers(FirstLower, LastLower, Width, Lowers),
    maplist(bin_with_count(Data, Width), Lowers, Bins).

bin_lowers(Lower, Last, _, []) :- Lower > Last, !.
bin_lowers(Lower, Last, Width, [Lower|Rest]) :-
    Next is Lower + Width,
    bin_lowers(Next, Last, Width, Rest).

bin_with_count(Data, Width, Lower, bin(Lower, Upper)-Count) :-
    Upper is Lower + Width,
    include(in_half_open_interval(Lower, Upper), Data, Values),
    length(Values, Count).

in_half_open_interval(Lower, Upper, Value) :-
    Value >= Lower,
    Value < Upper.

mean_and_deviations(Data, Mean, Deviations) :-
    sum_list(Data, Sum),
    length(Data, Count),
    reduced_rational(Sum, Count, Mean),
    maplist(deviation_from(Mean), Data, Deviations).

deviation_from(rational(MeanNumerator, MeanDenominator), Value, Deviation) :-
    Numerator is Value * MeanDenominator - MeanNumerator,
    reduced_rational(Numerator, MeanDenominator, Deviation).

rational_absolute(rational(Numerator, Denominator), Absolute) :-
    AbsoluteNumerator is abs(Numerator),
    reduced_rational(AbsoluteNumerator, Denominator, Absolute).

sum_rationals(Rationals, Sum) :-
    foldl(add_rational, Rationals, rational(0, 1), Sum).

add_rational(rational(AN, AD), rational(BN, BD), Sum) :-
    Numerator is AN * BD + BN * AD,
    Denominator is AD * BD,
    reduced_rational(Numerator, Denominator, Sum).

average_rationals(Rationals, Average) :-
    Rationals = [_|_],
    sum_rationals(Rationals, rational(Numerator, Denominator)),
    length(Rationals, Count),
    AverageDenominator is Denominator * Count,
    reduced_rational(Numerator, AverageDenominator, Average).

mean_absolute_deviation_value(Data, MAD) :-
    mean_and_deviations(Data, _, Deviations),
    maplist(rational_absolute, Deviations, AbsoluteDeviations),
    average_rationals(AbsoluteDeviations, MAD).

median_value(Sorted, Median, Action) :-
    length(Sorted, Count),
    Middle is Count // 2,
    (   1 is Count mod 2
    ->  nth0(Middle, Sorted, Median),
        Action = locate_single_middle(Middle, Median)
    ;   LeftIndex is Middle - 1,
        nth0(LeftIndex, Sorted, Left),
        nth0(Middle, Sorted, Right),
        Sum is Left + Right,
        reduced_rational(Sum, 2, Median),
        Action = average_two_middle_values(Left, Right, Median)
    ).

median_rational(Sorted, Median) :-
    median_value(Sorted, RawMedian, _),
    exact_rational(RawMedian, Median).

exact_rational(rational(Numerator, Denominator),
               rational(Numerator, Denominator)) :- !.
exact_rational(Integer, rational(Integer, 1)) :- integer(Integer).

five_number_summary(Sorted,
                    five_number(Minimum, Q1, Median, Q3, Maximum), IQR) :-
    Sorted = [Minimum|_],
    last(Sorted, Maximum),
    length(Sorted, Count),
    Half is Count // 2,
    length(Lower, Half),
    append(Lower, Remainder, Sorted),
    (   0 is Count mod 2
    ->  Upper = Remainder
    ;   Remainder = [_Middle|Upper]
    ),
    Lower = [_|_],
    Upper = [_|_],
    median_rational(Sorted, Median),
    median_rational(Lower, Q1),
    median_rational(Upper, Q3),
    subtract_rational(Q3, Q1, IQR).

subtract_rational(rational(AN, AD), rational(BN, BD), Difference) :-
    Numerator is AN * BD - BN * AD,
    Denominator is AD * BD,
    reduced_rational(Numerator, Denominator, Difference).

numeric_five_number(five_number(Minimum, Q1, Median, Q3, Maximum),
                    five_number(Minimum, NumericQ1, NumericMedian,
                                NumericQ3, Maximum)) :-
    rational_number(Q1, NumericQ1),
    rational_number(Median, NumericMedian),
    rational_number(Q3, NumericQ3).

rational_number(rational(Numerator, Denominator), Number) :-
    Number is Numerator / Denominator.

summary_for_profile(symmetric_without_outliers, Data, mean_and_mad,
                    measures(mean(Mean), mad(MAD)),
                    select_mean_and_mean_absolute_deviation) :-
    mean_and_deviations(Data, Mean, _),
    mean_absolute_deviation_value(Data, MAD).
summary_for_profile(skewed_or_with_outliers, Data, median_and_iqr,
                    measures(median(Median), iqr(IQR)),
                    select_median_and_interquartile_range) :-
    msort(Data, Sorted),
    five_number_summary(Sorted,
                        five_number(_, _, Median, _, _), IQR).

maximal_frequency_values(Frequencies, Modes, Maximum) :-
    findall(Count, member(_-Count, Frequencies), Counts),
    max_list(Counts, Maximum),
    findall(Value, member(Value-Maximum, Frequencies), Modes).
