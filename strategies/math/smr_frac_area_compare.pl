/** <module> Fraction ordering with partitioned area models */

:- module(smr_frac_area_compare,
          [ run_area_model_compare/6,
            run_unequal_partition_piece_compare/6
          ]).

:- use_module(formalization(grounded_arithmetic), [integer_to_recollection/2]).
:- use_module(math(fraction_partitioning), [run_partition/5, run_disembed/4]).
:- use_module(math(fraction_iterating), [run_iterate/4]).
:- use_module(math(comparison_helpers),
              [valid_fraction/2, fraction_order/7, integer_order/3]).

run_area_model_compare(N1, D1, N2, D2, Result, History) :-
    area_quantity(first, N1, D1, Unit1, Parts1, PH1, DH1, IH1),
    area_quantity(second, N2, D2, Unit2, Parts2, PH2, DH2, IH2),
    fraction_order(N1, D1, N2, D2, Result, Cross1-XH1, Cross2-XH2),
    History = [
        hist(q_init, init(fraction(N1, D1), fraction(N2, D2))),
        hist(q_unitize_whole, congruent_unit_regions(first, second)),
        hist(q_verify_same_size_whole, same_size_wholes_certified),
        hist(q_partition, equal_partitions(first, D1, Unit1, PH1,
                                           second, D2, Unit2, PH2)),
        hist(q_disembed, shaded_parts(first, Parts1, DH1,
                                     second, Parts2, DH2)),
        hist(q_iterate_count_parts, iterations(first, N1, IH1,
                                               second, N2, IH2)),
        hist(q_compare_relative_size,
             co_measure(cross_products(Cross1, XH1, Cross2, XH2), Result)),
        hist(q_emit, emit(Result)),
        hist(q_accept, accept(Result))
    ].

run_unequal_partition_piece_compare(N1, D1, N2, D2, Result, History) :-
    valid_fraction(N1, D1), valid_fraction(N2, D2),
    integer_order(N1, N2, Result),
    History = [
        hist(q_init, init(fraction(N1, D1), fraction(N2, D2))),
        hist(q_unitize_whole, drawn_regions_treated_as_wholes),
        hist(q_verify_same_size_whole, same_size_wholes_not_checked),
        hist(q_partition, unequal_partitions_accepted_without_equality_check),
        hist(q_unequal_partition_piece_count,
             treat_unequal_pieces_as_equal_counts),
        hist(q_disembed, shaded_pieces_removed_from_partition_structure),
        hist(q_iterate_count_parts, raw_piece_counts(N1, N2)),
        hist(q_compare_relative_size,
             whole_number_dominance(compare_piece_counts(N1, N2, Result))),
        hist(q_emit, emit(Result)),
        hist(q_accept, accept(Result))
    ].

area_quantity(Name, N, D, Unit, Parts, PH, DH, IH) :-
    valid_fraction(N, D), N > 0,
    integer_to_recollection(D, RD),
    integer_to_recollection(N, RN),
    Whole = unit_region(Name),
    run_partition(Whole, RD, Unit, _AllParts, PH),
    run_disembed(Unit, Whole, RD, DH),
    run_iterate(Unit, RN, Parts, IH).
