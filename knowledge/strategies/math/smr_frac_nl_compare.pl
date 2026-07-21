/** <module> Fraction comparison by number-line location
 *
 * Locates each fraction by partitioning the 0-to-1 unit interval and
 * iterating its unit-fraction length from the origin.  The endpoints are
 * co-measured on a shared subdivision and ordered as positions on the path.
 * Arithmetic result points use grounded recollections; no `is/2` arithmetic
 * occurs in the automaton.
 *
 * The paired deformation counts the origin mark as a traversed interval, so
 * each endpoint is overcounted by one subunit before the same position
 * comparison runs.  This is the Bright et al. / Shaughnessy "counts marks not
 * intervals" error family.
 */

:- module(smr_frac_nl_compare,
          [ run_number_line_compare/6,
            run_count_marks_compare/6
          ]).

:- use_module(formalization(grounded_arithmetic),
              [ integer_to_recollection/2, recollection_to_integer/2,
                equal_to/2, smaller_than/2, successor/2, incur_cost/1 ]).
:- use_module(math(fraction_partitioning), [run_partition/5]).
:- use_module(math(fraction_iterating), [run_iterate/4]).
:- use_module(math(smr_mult_commutative_reasoning),
              [run_commutative_mult/4]).

%! run_number_line_compare(+N1,+D1,+N2,+D2,-Result,-History) is semidet.
run_number_line_compare(N1, D1, N2, D2, Result, History) :-
    valid_fraction(N1, D1),
    valid_fraction(N2, D2),
    incur_cost(strategy_selection),
    rec_inputs(N1, D1, N2, D2, RN1, RD1, RN2, RD2),
    H0 = [hist(q_init, init(fraction(N1, D1), fraction(N2, D2))),
          hist(q_identify_unit, unit_interval(0, 1))],
    locate_on_unit_line(RN1, RD1, Unit1, Units1, PartHist1, IterHist1),
    locate_on_unit_line(RN2, RD2, Unit2, Units2, PartHist2, IterHist2),
    append(H0,
           [ hist(q_partition_interval,
                  partitions(fraction(N1, D1), PartHist1,
                             fraction(N2, D2), PartHist2)),
             hist(q_mark_off_lengths,
                  iterations(fraction(N1, D1), Unit1, Units1, IterHist1,
                             fraction(N2, D2), Unit2, Units2, IterHist2)),
             hist(q_locate_endpoint,
                  endpoints(fraction(N1, D1), fraction(N2, D2)))
           ],
           H1),
    common_positions(N1, D1, N2, D2, CommonBase, Position1, Position2,
                     BaseHist, ProductHist1, ProductHist2),
    append(H1,
           [ hist(q_measure_with_unit_fraction,
                  co_measure(unit_fraction(1, CommonBase), BaseHist,
                             position(fraction(N1, D1), Position1, ProductHist1),
                             position(fraction(N2, D2), Position2, ProductHist2))),
             hist(q_compare_positions,
                  compare(Position1, Position2, Result)),
             hist(q_emit, emit(Result)),
             hist(q_accept, accept(Result))
           ],
           History),
    compare_positions(Position1, Position2, Result).

%! run_count_marks_compare(+N1,+D1,+N2,+D2,-Result,-History) is semidet.
run_count_marks_compare(N1, D1, N2, D2, Result, History) :-
    valid_fraction(N1, D1),
    valid_fraction(N2, D2),
    incur_cost(strategy_selection),
    rec_inputs(N1, D1, N2, D2, RN1, RD1, RN2, RD2),
    successor(RN1, MarkCount1),
    successor(RN2, MarkCount2),
    locate_on_unit_line(MarkCount1, RD1, _Unit1, _Marks1, PartHist1, IterHist1),
    locate_on_unit_line(MarkCount2, RD2, _Unit2, _Marks2, PartHist2, IterHist2),
    common_positions_grounded(MarkCount1, RD1, MarkCount2, RD2,
                              CommonBase, Position1, Position2,
                              BaseHist, ProductHist1, ProductHist2),
    compare_positions(Position1, Position2, Result),
    History = [
        hist(q_init, init(fraction(N1, D1), fraction(N2, D2))),
        hist(q_identify_unit, unit_interval(0, 1)),
        hist(q_partition_interval,
             partitions(fraction(N1, D1), PartHist1,
                        fraction(N2, D2), PartHist2)),
        hist(q_count_marks_not_intervals,
             overcount(origin_mark_included,
                       fraction(N1, D1), mark_count(MarkCount1), IterHist1,
                       fraction(N2, D2), mark_count(MarkCount2), IterHist2)),
        hist(q_locate_endpoint,
             mislocated_endpoints(mark_count(MarkCount1, D1),
                                  mark_count(MarkCount2, D2))),
        hist(q_measure_with_unit_fraction,
             co_measure(unit_fraction(1, CommonBase), BaseHist,
                        position(mark_count(MarkCount1, D1), Position1, ProductHist1),
                        position(mark_count(MarkCount2, D2), Position2, ProductHist2))),
        hist(q_compare_positions, compare(Position1, Position2, Result)),
        hist(q_emit, emit(Result)),
        hist(q_accept, accept(Result))
    ].

locate_on_unit_line(Count, Base, UnitPart, Units, PartitionHistory,
                    IterationHistory) :-
    run_partition(unit_interval(0, 1), Base, UnitPart, _Parts,
                  PartitionHistory),
    iterate_or_origin(Count, UnitPart, Units, IterationHistory).

iterate_or_origin(Count, _UnitPart, [], [at_origin]) :-
    integer_to_recollection(0, Zero),
    equal_to(Count, Zero),
    !.
iterate_or_origin(Count, UnitPart, Units, History) :-
    run_iterate(UnitPart, Count, Units, History).

common_positions(N1, D1, N2, D2, CommonBase, Position1, Position2,
                 BaseHist, Hist1, Hist2) :-
    rec_inputs(N1, D1, N2, D2, RN1, RD1, RN2, RD2),
    common_positions_grounded(RN1, RD1, RN2, RD2,
                              CommonBase, Position1, Position2,
                              BaseHist, Hist1, Hist2).

common_positions_grounded(RN1, RD1, RN2, RD2,
                          CommonBase, Position1, Position2,
                          BaseHist, Hist1, Hist2) :-
    recollection_to_integer(RN1, N1),
    recollection_to_integer(RD1, D1),
    recollection_to_integer(RN2, N2),
    recollection_to_integer(RD2, D2),
    run_commutative_mult(D1, D2, CommonBase, BaseHist),
    run_commutative_mult(N1, D2, Position1, Hist1),
    run_commutative_mult(N2, D1, Position2, Hist2).

compare_positions(Position1, Position2, equivalent) :-
    integer_to_recollection(Position1, Rec1),
    integer_to_recollection(Position2, Rec2),
    equal_to(Rec1, Rec2),
    !.
compare_positions(Position1, Position2, less_than) :-
    integer_to_recollection(Position1, Rec1),
    integer_to_recollection(Position2, Rec2),
    smaller_than(Rec1, Rec2),
    !.
compare_positions(_, _, greater_than).

rec_inputs(N1, D1, N2, D2, RN1, RD1, RN2, RD2) :-
    integer_to_recollection(N1, RN1),
    integer_to_recollection(D1, RD1),
    integer_to_recollection(N2, RN2),
    integer_to_recollection(D2, RD2).

valid_fraction(N, D) :-
    integer(N), N >= 0,
    integer(D), D > 0.
