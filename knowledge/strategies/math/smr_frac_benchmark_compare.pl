/** <module> Fraction comparison through benchmarks and contextual gap thinking */

:- module(smr_frac_benchmark_compare,
          [ run_benchmark_compare/6,
            run_gap_thinking_compare/7
          ]).

:- use_module(math(comparison_helpers),
              [ valid_fraction/2, fraction_order/7, integer_order/3,
                absolute_difference/3 ]).

run_benchmark_compare(N1, D1, N2, D2, Result, History) :-
    valid_fraction(N1, D1), valid_fraction(N2, D2),
    select_benchmark(N1, D1, N2, D2, BN, BD, Benchmark),
    fraction_order(N1, D1, BN, BD, Side1, CP1-CH1, BP1-BH1),
    fraction_order(N2, D2, BN, BD, Side2, CP2-CH2, BP2-BH2),
    fraction_order(N1, D1, N2, D2, Result, Cross1-XH1, Cross2-XH2),
    transitive_evidence(Side1, Side2, Result, Transitive),
    residual_evidence(Side1, Side2, N1, D1, N2, D2, Result, Residual),
    History = [
        hist(q_init, init(fraction(N1, D1), fraction(N2, D2))),
        hist(q_select_benchmark, selected(Benchmark)),
        hist(q_benchmark_first,
             judgment(fraction(N1, D1), Side1, Benchmark,
                      cross_products(CP1, CH1, BP1, BH1))),
        hist(q_benchmark_second,
             judgment(fraction(N2, D2), Side2, Benchmark,
                      cross_products(CP2, CH2, BP2, BH2))),
        hist(q_transitive_compare, Transitive),
        hist(q_residual_compare,
             residual(Residual, cross_products(Cross1, XH1, Cross2, XH2))),
        hist(q_emit, emit(Result)),
        hist(q_accept, accept(Result))
    ].

run_gap_thinking_compare(N1, D1, N2, D2, Result, Viability, History) :-
    valid_fraction(N1, D1), valid_fraction(N2, D2),
    absolute_difference(N1, D1, Gap1),
    absolute_difference(N2, D2, Gap2),
    integer_order(Gap1, Gap2, GapOrder),
    invert_gap_order(GapOrder, Result),
    fraction_order(N1, D1, N2, D2, Expected, _-_, _-_),
    gap_viability(Expected, Result, Viability),
    History = [
        hist(q_init, init(fraction(N1, D1), fraction(N2, D2))),
        hist(q_select_benchmark, selected(one)),
        hist(q_benchmark_first, numerator_denominator_gap(first, Gap1)),
        hist(q_benchmark_second, numerator_denominator_gap(second, Gap2)),
        hist(q_gap_thinking, compare_absolute_gaps(Gap1, Gap2, Result)),
        hist(q_transitive_compare, omitted_external_value_relation),
        hist(q_residual_compare, unscaled_residuals(Gap1, Gap2)),
        hist(q_viability_context, Viability),
        hist(q_emit, emit(Result)),
        hist(q_accept, accept(Result))
    ].

select_benchmark(0, _, _, _, 0, 1, zero) :- !.
select_benchmark(_, _, 0, _, 0, 1, zero) :- !.
select_benchmark(N1, D1, N2, D2, 1, 2, one_half) :-
    N1 < D1, N2 < D2, !.
select_benchmark(_, _, _, _, 1, 1, one).

transitive_evidence(Side, Side, _, same_side_requires_residual) :- !.
transitive_evidence(Side1, Side2, Result,
                    opposite_sides(Side1, Side2, entails(Result))).

residual_evidence(Side, Side, N1, D1, N2, D2, Result,
                  compared(fraction(N1, D1), fraction(N2, D2), Result)) :- !.
residual_evidence(_, _, _, _, _, _, _, not_needed_opposite_sides).

invert_gap_order(equivalent, equivalent).
invert_gap_order(less_than, greater_than).
invert_gap_order(greater_than, less_than).

gap_viability(Expected, Expected,
              viability(contextual_success,
                        condition(gap_order_coincides_with_fraction_order),
                        validity(contextually_correct))) :- !.
gap_viability(Expected, Produced,
              viability(fails_in_context,
                        condition(gap_order_diverges_from_fraction_order),
                        expected(Expected), produced(Produced),
                        validity(incorrect))).
