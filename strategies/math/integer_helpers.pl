/** <module> Integer arithmetic helpers (consolidation)
 *
 * Provides integer wrappers over the grounded-recollection arithmetic
 * primitives in formalization(grounded_arithmetic). These were previously
 * redefined locally in each of strategies/math/{sar_add,sar_sub,smr_mult,
 * smr_div}_action_pairs.pl with identical bodies. Predicate carving
 * (formal/tools/carving/predicate_carving.py) identified the redundancy.
 *
 * The bodies route through integer_to_recollection -> grounded operation
 * -> recollection_to_integer, so callers get integer in/out while
 * preserving the grounded-arithmetic semantics on the inside.
 */

:- module(integer_helpers,
          [ add_ints/3,
            subtract_ints/3,
            multiply_ints/3,
            positive_integer/1
          ]).

:- use_module(formalization(grounded_arithmetic),
              [ integer_to_recollection/2,
                recollection_to_integer/2,
                add_grounded/3,
                subtract_grounded/3,
                multiply_grounded/3
              ]).

add_ints(A, B, Sum) :-
    integer_to_recollection(A, RecA),
    integer_to_recollection(B, RecB),
    add_grounded(RecA, RecB, RecSum),
    recollection_to_integer(RecSum, Sum).

subtract_ints(A, B, Difference) :-
    integer_to_recollection(A, RecA),
    integer_to_recollection(B, RecB),
    subtract_grounded(RecA, RecB, RecDifference),
    recollection_to_integer(RecDifference, Difference).

multiply_ints(A, B, Product) :-
    integer_to_recollection(A, RecA),
    integer_to_recollection(B, RecB),
    multiply_grounded(RecA, RecB, RecProduct),
    recollection_to_integer(RecProduct, Product).

positive_integer(N) :-
    integer(N),
    N > 0.
