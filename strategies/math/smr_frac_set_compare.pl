/** <module> Fraction ordering with discrete set models */

:- module(smr_frac_set_compare,
          [ run_set_model_compare/6,
            run_subset_size_focus_compare/6
          ]).

:- use_module(formalization(grounded_arithmetic), [integer_to_recollection/2]).
:- use_module(math(fraction_partitioning), [run_partition/5, run_disembed/4]).
:- use_module(math(fraction_iterating), [run_iterate/4]).
:- use_module(math(comparison_helpers),
              [valid_fraction/2, fraction_order/7, integer_order/3]).

run_set_model_compare(N1, D1, N2, D2, Result, History) :-
    set_quantity(first, N1, D1, Shares1, PH1, DH1, IH1),
    set_quantity(second, N2, D2, Shares2, PH2, DH2, IH2),
    fraction_order(N1, D1, N2, D2, Result, Cross1-XH1, Cross2-XH2),
    History = [
        hist(q_init, init(fraction(N1, D1), fraction(N2, D2))),
        hist(q_unitize_set, collections_as_single_wholes(first, second)),
        hist(q_verify_same_whole, commensurable_collections_certified),
        hist(q_partition_set, equal_shares(first, D1, PH1,
                                           second, D2, PH2)),
        hist(q_count_equal_sets, denominator_counts(D1, D2)),
        hist(q_disembed_subset, selected_shares(first, Shares1, DH1, IH1,
                                                second, Shares2, DH2, IH2)),
        hist(q_compare_relative_size,
             co_measure(cross_products(Cross1, XH1, Cross2, XH2), Result)),
        hist(q_emit, emit(Result)),
        hist(q_accept, accept(Result))
    ].

run_subset_size_focus_compare(N1, D1, N2, D2, Result, History) :-
    valid_fraction(N1, D1), valid_fraction(N2, D2),
    integer_order(N1, N2, Result),
    History = [
        hist(q_init, init(fraction(N1, D1), fraction(N2, D2))),
        hist(q_unitize_set, collections_as_single_wholes(first, second)),
        hist(q_verify_same_whole, commensurable_collections_not_checked),
        hist(q_partition_set, equal_share_structure_ignored),
        hist(q_count_equal_sets, confuse_counters_with_share_name(D1, D2)),
        hist(q_disembed_subset, focus_on_subset_counts(N1, N2)),
        hist(q_subset_size_focus, subset_count_replaces_fractional_share),
        hist(q_compare_relative_size, compare_raw_subset_sizes(N1, N2, Result)),
        hist(q_emit, emit(Result)),
        hist(q_accept, accept(Result))
    ].

set_quantity(Name, N, D, Shares, PH, DH, IH) :-
    valid_fraction(N, D), N > 0,
    integer_to_recollection(D, RD),
    integer_to_recollection(N, RN),
    Whole = collection(Name),
    run_partition(Whole, RD, Unit, _AllShares, PH),
    run_disembed(Unit, Whole, RD, DH),
    run_iterate(Unit, RN, Shares, IH).
