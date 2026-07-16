/** <module> Coordinated Fraction Equivalence via Cross-Multiplication
 *
 * Decides whether two fractions N1/D1 and N2/D2 are equivalent by computing
 * the cross products N1*D2 and N2*D1 and comparing. The module invokes the
 * multiplication automaton twice as a sub-routine, mirroring the
 * algorithmic-elaboration pattern of long division (smr_div_long).
 *
 * This is the correct companion to Benny's Rule 2 (`misconceptions/benny.pl`).
 * Benny replaces each multiplication with a single addition, collapsing the
 * same 5-state shape into a structurally identical machine that has been
 * emptied of its arithmetic content.
 *
 * `is_recollection` gates fire at every arithmetic-result point: the four
 * inputs, both cross products, and (via the comparison step) both products
 * are licensed before the compare.
 */
:- module(smr_frac_equiv_cross_mult,
          [ run_cross_mult_equiv/6 ]).

:- use_module(library(lists)).
:- use_module(formalization(grounded_arithmetic),
              [ integer_to_recollection/2, equal_to/2, incur_cost/1 ]).
:- use_module(formalization(robinson_q), [is_recollection/2]).
:- use_module(strategies(math/smr_mult_commutative_reasoning),
              [ run_commutative_mult/4 ]).

%! run_cross_mult_equiv(+N1, +D1, +N2, +D2, -Result, -History) is det.
%
%  Result ∈ {equivalent, not_equivalent}. History is a list of hist/2
%  entries recording each transition, including the sub-histories of the
%  two multiplication invocations.
%
%  Examples:
%    run_cross_mult_equiv(1, 2, 2, 4, R, _).  %  R = equivalent.
%    run_cross_mult_equiv(2, 3, 3, 4, R, _).  %  R = not_equivalent.
run_cross_mult_equiv(N1, D1, N2, D2, Result, History) :-
    D1 > 0, D2 > 0,
    incur_cost(strategy_selection),
    % q_init: license the four inputs.
    once(is_recollection(N1, _)),
    once(is_recollection(D1, _)),
    once(is_recollection(N2, _)),
    once(is_recollection(D2, _)),
    H0 = [hist(q_init, init(frac(N1,D1), frac(N2,D2)))],

    % q_multiply_cross_1: P1 = N1 × D2, via mult automaton.
    smr_mult_commutative_reasoning:run_commutative_mult(N1, D2, P1, Hist1),
    once(is_recollection(P1, _)),
    H1 = [hist(q_multiply_cross_1, cross(N1, D2, P1, Hist1))|H0],

    % q_multiply_cross_2: P2 = N2 × D1.
    smr_mult_commutative_reasoning:run_commutative_mult(N2, D1, P2, Hist2),
    once(is_recollection(P2, _)),
    H2 = [hist(q_multiply_cross_2, cross(N2, D1, P2, Hist2))|H1],

    % q_compare: grounded equality on recollections (not =:=).
    integer_to_recollection(P1, P1Rec),
    integer_to_recollection(P2, P2Rec),
    ( equal_to(P1Rec, P2Rec)
    -> Result = equivalent
    ;  Result = not_equivalent
    ),
    H3 = [hist(q_compare, compare(P1, P2, Result))|H2],

    % q_emit → q_accept.
    H4 = [hist(q_emit, emit(Result)), hist(q_accept, accept(Result))|H3],
    reverse(H4, History).

% --- Self-tests -----------------------------------------------------------

run_smr_frac_equiv_tests :-
    catch(
        ( test_equiv_case(1, 2, 2, 4, equivalent),
          test_equiv_case(2, 3, 3, 4, not_equivalent),
          format('[smr_frac_equiv_cross_mult] all self-tests passed.~n', [])
        ),
        E,
        ( format('[smr_frac_equiv_cross_mult] SELF-TEST FAILURE: ~w~n', [E]), throw(E))
    ).

test_equiv_case(N1, D1, N2, D2, Expected) :-
    run_cross_mult_equiv(N1, D1, N2, D2, Got, _),
    ( Got == Expected
    -> format('  PASS ~w/~w ~~ ~w/~w: ~w~n', [N1, D1, N2, D2, Got])
    ;  format('  FAIL ~w/~w ~~ ~w/~w: got ~w, expected ~w~n',
              [N1, D1, N2, D2, Got, Expected]),
       throw(test_failure(N1/D1 - N2/D2))
    ).
