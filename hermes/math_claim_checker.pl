/** <module> PML -> math claim checker bridge
 *
 * Adjudicate a ground, typed mathematical claim extracted from a PML reading's
 * normalized_text, by routing it through the project's existing grounded
 * fraction predicates. The verdict is honest: "holds" (the claim is true under
 * the grounded model), "refuted" (it is false — a misconception surfaced), or
 * "not_covered" (no checker is registered for this claim shape). The truth value
 * is decided by grounded comparison (grounded_arithmetic:equal_to/2 over
 * recollections), never by is/2; the existing automaton supplies the trace.
 *
 * This is the domain-anchor -> checker layer Codex named: PML stays abstract,
 * the math stays grounded, and the audit can tell a checked-true claim from a
 * checked-false one.
 */
:- module(math_claim_checker, [ check_math_claim/2 ]).

% Helper predicates sit next to the claim families that use them.
:- discontiguous check_math_claim/2.

:- use_module(formalization(grounded_arithmetic),
              [ integer_to_recollection/2, equal_to/2,
                greater_than/2, smaller_than/2, add_grounded/3,
                subtract_grounded/3,
                multiply_grounded/3, zero/1 ]).
:- use_module(math(divaded_fractional_units),
              [ co_measure_fractions/7 ]).
:- use_module(math(fraction_iterating),
              [ partition_iterate_inverse/2 ]).
:- use_module(library(lists), [ append/3, member/2 ]).

%!  check_math_claim(+ClaimTerm, -Dict) is det.
%
%   ClaimTerm is a ground term naming a mathematical claim. Dict reports the
%   adjudication. Always succeeds: an unrecognized claim shape returns
%   status "not_covered".

% Fraction checkers construct recollections, whose components are natural
% counts. Reject an invalid fraction component before a clause reaches
% ints_to_recs/2, whose head cut would otherwise turn that domain boundary
% into silent failure.
check_math_claim(Claim, Dict) :-
    grounded_fraction_claim(Claim, ClaimName),
    invalid_fraction_component(Claim),
    !,
    not_covered(ClaimName,
                "fraction components must be non-negative integers; the grounded substrate carries non-negative recollections",
                Dict).

% --- fraction equivalence: a/b = c/d ---
check_math_claim(equivalence(fraction(N1,D1), fraction(N2,D2)), Dict) :-
    !,
    (   fraction_equivalence(N1,D1,N2,D2, Verdict, Trace)
    ->  format(string(Left), "~w/~w", [N1,D1]),
        format(string(Right), "~w/~w", [N2,D2]),
        Dict = _{ status: "domain_checked",
                  claim: "fraction_equivalence",
                  checker: "divaded_fractional_units:co_measure_fractions",
                  left: Left, right: Right,
                  verdict: Verdict, adjudication: Verdict, trace: Trace }
    ;   not_covered("fraction_equivalence", "co_measurement could not be coordinated for these fractions", Dict)
    ).

% --- n/n = 1 ---
check_math_claim(n_over_n_is_one(fraction(N,D)), Dict) :-
    !,
    ints_to_recs([N,D], [RN,RD]),
    verdict_of(equal_to(RN, RD), V),
    format(string(T), "completion: numerator ~w vs denominator ~w", [N,D]),
    checked_dict("n_over_n_is_one", "grounded_arithmetic:equal_to", V, [T], Dict).
check_math_claim(n_over_n_schema, Dict) :-
    !,
    checked_dict("n_over_n_schema", "SWI arithmetic schema N =\\= 0 -> N/N = 1",
                 "holds",
                 ["for any nonzero positive integer N, N/N evaluates to 1"],
                 Dict).
check_math_claim(division_by_n_is_unit_fraction(N), Dict) :-
    !,
    (   integer(N), N > 0
    ->  format(string(T), "1 divided by ~w is the unit fraction 1/~w", [N,N]),
        checked_dict("division_by_n_is_unit_fraction", "SWI arithmetic schema 1/N = 1/N",
                     "holds", [T], Dict)
    ;   not_covered("division_by_n_is_unit_fraction", "denominator is not a positive integer", Dict)
    ).

% --- improper fraction: N/D names more than one whole ---
check_math_claim(improper(fraction(N,D)), Dict) :-
    !,
    ints_to_recs([N,D], [RN,RD]),
    verdict_of(greater_than(RN, RD), V),
    format(string(T), "beyond-whole: numerator ~w vs denominator ~w", [N,D]),
    checked_dict("improper_fraction", "grounded_arithmetic:greater_than", V, [T], Dict).

% --- number line position: 0 < N/D < 1 ---
check_math_claim(number_line_position(fraction(N,D), between(0,1)), Dict) :-
    !,
    ints_to_recs([N,D], [RN,RD]),
    zero(Z),
    verdict_of((greater_than(RN, Z), smaller_than(RN, RD)), V),
    format(string(T), "within unit interval: 0 < ~w/~w < 1", [N,D]),
    checked_dict("number_line_position", "grounded_arithmetic:smaller_than", V, [T], Dict).

% --- midpoint of [0,1] is 1/2 (delegates to equivalence vs 1/2) ---
check_math_claim(midpoint(fraction(N,D)), Dict) :-
    !,
    check_math_claim(equivalence(fraction(N,D), fraction(1,2)), D0),
    Dict = D0.put(_{claim: "number_line_midpoint"}).

% --- fraction multiplication: a/b * c/d = p/q ---
check_math_claim(multiplication(fraction(A,B), fraction(C,D), fraction(P,Q)), Dict) :-
    !,
    ints_to_recs([A,B,C,D,P,Q], [RA,RB,RC,RD,RP,RQ]),
    (   B > 0, D > 0, Q > 0,
        multiply_grounded(RA, RC, NumProd),
        multiply_grounded(RB, RD, DenProd),
        multiply_grounded(NumProd, RQ, LeftScaled),
        multiply_grounded(RP, DenProd, RightScaled)
    ->  % Cross-scaled comparison, the same co-measure the difference
        % clause uses: a claimed product stated in lowest terms (1/2 of
        % 2/3 is 1/3) holds; componentwise comparison wrongly refuted
        % every simplified product.
        verdict_of(equal_to(LeftScaled, RightScaled), V),
        rec_int(NumProd, NP), rec_int(DenProd, DP),
        format(string(T), "numerator product ~w*~w=~w; denominator product ~w*~w=~w; cross-scaled against claimed ~w/~w",
               [A,C,NP, B,D,DP, P,Q]),
        checked_dict("fraction_multiplication", "grounded_arithmetic:multiply_grounded", V, [T], Dict)
    ;   not_covered("fraction_multiplication", "a zero denominator places this claim outside the grounded fraction domain", Dict)
    ).

% --- scalar times fraction: N * c/d = p/q coerces through N/1 ---
%   Covers the roadmap claim "13 * 2/3 = (13/1) * (2/3)": an integer left
%   factor is the fraction N/1, then the fraction-multiplication checker
%   adjudicates as usual.
check_math_claim(multiplication(N, fraction(C,D), Result), Dict) :-
    integer(N),
    !,
    check_math_claim(multiplication(fraction(N,1), fraction(C,D), Result), Dict).

% --- fraction of a quantity: (Num/Den) of N = Result ---
%   Covers the roadmap claims "fraction of n = (n/denominator)*numerator",
%   "three fifths of 15 is three units of one fifth", "n/5 = (1/5)*n".
%   Grounded reading is partitive: N splits into Den equal whole-number
%   shares, and Result is Num of those shares. When Den does not divide N,
%   no whole-number share exists in the grounded substrate, so the claim is
%   registered but the adjudication is honestly underdetermined rather than
%   forced to holds/refuted on arithmetic the grounding cannot enact.
check_math_claim(fraction_of(N, fraction(Num,Den), Result), Dict) :-
    !,
    (   nonneg_integers([N, Num, Den, Result]),
        Den > 0
    ->  (   0 =:= N mod Den
        ->  Share is N // Den,
            ints_to_recs([Share, Num, Result], [RShare, RNum, RResult]),
            multiply_grounded(RNum, RShare, Total),
            verdict_of(equal_to(Total, RResult), V),
            rec_int(Total, TotalInt),
            format(string(T),
                   "~w splits into ~w shares of ~w; ~w shares make ~w; claimed ~w",
                   [N, Den, Share, Num, TotalInt, Result]),
            checked_dict("fraction_of_quantity",
                         "grounded_arithmetic:multiply_grounded", V, [T], Dict)
        ;   format(string(T),
                   "~w does not split into ~w equal whole-number shares; the partitive grounding cannot enact this claim",
                   [N, Den]),
            Dict = _{ status: "domain_checked",
                      claim: "fraction_of_quantity",
                      checker: "grounded_arithmetic:partitive_share",
                      verdict: "not_checked",
                      adjudication: "underdetermined",
                      trace: [T] }
        )
    ;   not_covered("fraction_of_quantity",
                    "quantity, fraction parts, and result must be non-negative integers with a positive denominator",
                    Dict)
    ).

% --- fraction difference: a/b - c/d = p/q ---
check_math_claim(difference(fraction(A,B), fraction(C,D), fraction(P,Q)), Dict) :-
    !,
    (   B > 0, D > 0, Q > 0
    ->  ints_to_recs([A,B,C,D,P,Q], [RA,RB,RC,RD,RP,RQ]),
        (   multiply_grounded(RA, RD, LeftNumerator),
            multiply_grounded(RC, RB, RightNumerator),
            multiply_grounded(RB, RD, CommonDenominator),
            subtract_grounded(LeftNumerator, RightNumerator, DifferenceNumerator),
            multiply_grounded(DifferenceNumerator, RQ, LeftScaled),
            multiply_grounded(RP, CommonDenominator, RightScaled)
        ->  verdict_of(equal_to(LeftScaled, RightScaled), V),
            rec_int(LeftNumerator, LN), rec_int(RightNumerator, RN),
            rec_int(DifferenceNumerator, DN), rec_int(CommonDenominator, CD),
            rec_int(LeftScaled, LS), rec_int(RightScaled, RS),
            format(string(T),
                   "common denominator ~w: ~w/~w - ~w/~w leaves ~w/~w; scaled comparison ~w vs ~w",
                   [CD,LN,CD,RN,CD,DN,CD,LS,RS]),
            checked_dict("fraction_difference", "grounded_arithmetic:subtract_grounded", V, [T], Dict)
        ;   checked_dict("fraction_difference", "grounded_arithmetic:subtract_grounded",
                         "refuted", ["left-hand difference is negative or not groundable"], Dict)
        )
    ;   not_covered("fraction_difference",
                    "a zero denominator places this claim outside the grounded fraction domain",
                    Dict)
    ).

% --- iterate a part N/D, K times, to reconstitute the whole ---
check_math_claim(iterate_to_whole(fraction(N,D), times(K)), Dict) :-
    !,
    % The iteration count is the one non-fraction natural in the fraction
    % family; the up-front component guard inspects only fraction/2
    % sub-terms, so a negative count must be rejected here or ints_to_recs
    % fails after the cut and the always-succeeds contract breaks.
    (   \+ (integer(K), K >= 0)
    ->  not_covered("iterate_to_whole",
                    "iteration count must be a non-negative integer",
                    Dict)
    ;   check_iterate_to_whole(N, D, K, Dict)
    ).

check_iterate_to_whole(N, D, K, Dict) :-
    ints_to_recs([N,D,K], [RN,RD,RK]),
    (   multiply_grounded(RK, RN, Prod)
    ->  verdict_of(equal_to(Prod, RD), V),
        rec_int(Prod, PN),
        format(string(T), "~w copies of ~w/~w span ~w/~w; whole is ~w/~w", [K,N,D,PN,D,D,D]),
        ( V == "holds", N =:= 1, K =:= D,
          catch(partition_iterate_inverse(unit(whole), RD), _, fail)
        ->  Checker = "fraction_iterating:partition_iterate_inverse",
            Trace = ["partition(D) o iterate(D) = identity on the whole (splitting inverse confirmed)", T]
        ;   Checker = "grounded_arithmetic:multiply_grounded",
            Trace = [T]
        ),
        checked_dict("iterate_to_whole", Checker, V, Trace, Dict)
    ;   not_covered("iterate_to_whole", "grounded iteration could not be computed", Dict)
    ).

% --- Wave-5 whole-number addition: A + B = C (grounded count-on) ---
check_math_claim(sum(A, B, C), Dict) :-
    !,
    (   nonneg_integers([A,B,C])
    ->  ints_to_recs([A,B,C], [RA,RB,RC]),
        add_grounded(RA, RB, S),
        verdict_of(equal_to(S, RC), V),
        rec_int(S, SC),
        format(string(T), "count on from ~w by ~w reaches ~w; claimed ~w", [A,B,SC,C]),
        checked_dict("whole_number_sum", "grounded_arithmetic:add_grounded", V, [T], Dict)
    ;   not_covered("whole_number_sum", "addends and total must be non-negative integers", Dict)
    ).

% --- fraction addition: A/B + C/D = claimed result (fraction or whole) ---
% Grounded route, no is/2 for the verdict: the sum's numerator over the
% common denominator B*D is cross-multiplied against the claimed result and
% compared with grounded equality. whole(N) claims "N whole(s)", i.e. N/1.
% tm_0083's spine ("one half plus one half equals a whole") arrives here.
check_math_claim(fraction_sum(fraction(A,B), fraction(C,D), Claimed), Dict) :-
    !,
    (   nonneg_integers([A,C]), pos_integers([B,D]),
        fraction_sum_target(Claimed, P, Q, ClaimStr)
    ->  ints_to_recs([A,B,C,D,P,Q], [RA,RB,RC,RD,RP,RQ]),
        multiply_grounded(RA, RD, AD),
        multiply_grounded(RC, RB, CB),
        add_grounded(AD, CB, NumSum),
        multiply_grounded(RB, RD, Den),
        multiply_grounded(NumSum, RQ, Left),
        multiply_grounded(RP, Den, Right),
        verdict_of(equal_to(Left, Right), V),
        format(string(T), "grounded: ~w/~w + ~w/~w co-measured against claimed ~w",
               [A, B, C, D, ClaimStr]),
        checked_dict("fraction_sum",
                     "grounded_arithmetic:add_grounded+multiply_grounded",
                     V, [T], Dict)
    ;   not_covered("fraction_sum",
                    "claimed result must be fraction(P,Q) or whole(N) over nonneg integers",
                    Dict)
    ).

fraction_sum_target(whole(N), N, 1, ClaimStr) :-
    integer(N), N >= 0,
    format(string(ClaimStr), "~w whole", [N]).
fraction_sum_target(fraction(P,Q), P, Q, ClaimStr) :-
    integer(P), P >= 0, integer(Q), Q > 0,
    format(string(ClaimStr), "~w/~w", [P, Q]).

pos_integers(Xs) :-
    forall(member(X, Xs), (integer(X), X > 0)).

% --- Wave-5 whole-number subtraction: A - B = C (grounded take-away) ---
check_math_claim(subtraction(A, B, C), Dict) :-
    !,
    (   nonneg_integers([A,B,C])
    ->  ints_to_recs([A,B,C], [RA,RB,RC]),
        (   subtract_grounded(RA, RB, Diff)
        ->  verdict_of(equal_to(Diff, RC), V),
            rec_int(Diff, DC),
            format(string(T), "take ~w from ~w leaves ~w; claimed ~w", [B,A,DC,C]),
            checked_dict("whole_number_subtraction", "grounded_arithmetic:subtract_grounded", V, [T], Dict)
        ;   format(string(T), "cannot take ~w from ~w: subtracting more than is present", [B,A]),
            checked_dict("whole_number_subtraction", "grounded_arithmetic:subtract_grounded", "refuted", [T], Dict)
        )
    ;   not_covered("whole_number_subtraction", "minuend, subtrahend and result must be non-negative integers", Dict)
    ).

% --- fraction comparison: A/B Rel C/D (cross-multiplied, grounded order) ---
%   The pass-1 catalog offers comparison over fractions; this clause is the
%   checker for it. Cross-multiplication over grounded multiply keeps the
%   verdict inside the recollection substrate, the same route fraction_sum
%   takes. Mixed integer/fraction comparisons coerce the integer to N/1.
check_math_claim(comparison(fraction(A,B), Rel, fraction(C,D)), Dict) :-
    !,
    (   comparison_pred(Rel, Pred, RelText),
        nonneg_integers([A,C]), pos_integers([B,D])
    ->  ints_to_recs([A,B,C,D], [RA,RB,RC,RD]),
        multiply_grounded(RA, RD, Left),
        multiply_grounded(RC, RB, Right),
        Goal =.. [Pred, Left, Right],
        verdict_of(Goal, V),
        rec_int(Left, LN), rec_int(Right, RN),
        format(string(T), "cross-multiplied: ~w*~w=~w ~w ~w*~w=~w",
               [A, D, LN, RelText, C, B, RN]),
        checked_dict("fraction_comparison",
                     "grounded_arithmetic:multiply_grounded+order", V, [T], Dict)
    ;   not_covered("fraction_comparison",
                    "unrecognized relation, or fraction parts are not non-negative integers over a positive denominator",
                    Dict)
    ).
check_math_claim(comparison(N, Rel, fraction(C,D)), Dict) :-
    integer(N),
    !,
    check_math_claim(comparison(fraction(N,1), Rel, fraction(C,D)), Dict).
check_math_claim(comparison(fraction(A,B), Rel, N), Dict) :-
    integer(N),
    !,
    check_math_claim(comparison(fraction(A,B), Rel, fraction(N,1)), Dict).

% --- Wave-5 whole-number comparison: A Rel B (grounded order) ---
%   Rel is one of greater_than/less_than/equal_to (aliases gt/lt/eq, >/</=,
%   and the pass-1 catalog's greater/smaller/equal).
check_math_claim(comparison(A, Rel, B), Dict) :-
    !,
    (   comparison_pred(Rel, Pred, RelText),
        nonneg_integers([A,B])
    ->  ints_to_recs([A,B], [RA,RB]),
        Goal =.. [Pred, RA, RB],
        verdict_of(Goal, V),
        format(string(T), "grounded order: ~w ~w ~w", [A, RelText, B]),
        checked_dict("whole_number_comparison", "grounded_arithmetic:order", V, [T], Dict)
    ;   not_covered("whole_number_comparison", "unrecognized relation or non-integer operands", Dict)
    ).

% --- Wave-5 whole-number ordering: a sequence is strictly ascending/descending ---
check_math_claim(ordering(List, Direction), Dict) :-
    !,
    (   ordering_pred(Direction, Pred),
        is_list(List), List \== [], nonneg_integers(List)
    ->  ints_to_recs(List, Recs),
        verdict_of(grounded_chain(Recs, Pred), V),
        format(string(T), "sequence ~w is strictly ~w", [List, Direction]),
        checked_dict("whole_number_ordering", "grounded_arithmetic:order", V, [T], Dict)
    ;   not_covered("whole_number_ordering", "ordering needs a direction and a non-empty list of non-negative integers", Dict)
    ).

% --- quadrilateral class inclusion: every Sub is a Super ---
%   Adjudicated over the inclusive hierarchy the geometry KB encodes
%   (knowledge/geometry/concepts/classification.pl: square_as_rectangle,
%   rectangle_as_parallelogram, ...). Closed world over the registered
%   shapes: an inclusion the hierarchy does not license is refuted; a shape
%   outside the registry is not_covered. Claims that a parallelogram-family
%   shape is a trapezoid are underdetermined by design — inclusive and
%   exclusive trapezoid definitions disagree there, and the checker does
%   not settle a definitional dispute.
check_math_claim(class_inclusion(Sub, Super), Dict) :-
    !,
    (   ( \+ quad_shape(Sub) ; \+ quad_shape(Super) )
    ->  not_covered("quadrilateral_class_inclusion",
                    "shape is outside the registered quadrilateral hierarchy",
                    Dict)
    ;   Super == trapezoid, quad_inclusion(Sub, parallelogram)
    ->  format(string(T),
               "whether every ~w is a trapezoid depends on the trapezoid definition in force: inclusive (at least one pair of parallel sides) says yes, exclusive (exactly one pair) says no",
               [Sub]),
        Dict = _{ status: "domain_checked",
                  claim: "quadrilateral_class_inclusion",
                  checker: "geometry:quadrilateral_hierarchy",
                  verdict: "not_checked",
                  adjudication: "underdetermined",
                  trace: [T] }
    ;   quad_inclusion(Sub, Super)
    ->  quad_inclusion_note(Sub, Super, Note),
        format(string(T), "the inclusive hierarchy licenses ~w -> ~w (~w)",
               [Sub, Super, Note]),
        checked_dict("quadrilateral_class_inclusion",
                     "geometry:quadrilateral_hierarchy", "holds", [T], Dict)
    ;   quad_inclusion(Super, Sub)
    ->  format(string(T),
               "the inclusion runs the other way: every ~w is a ~w, not conversely",
               [Super, Sub]),
        checked_dict("quadrilateral_class_inclusion",
                     "geometry:quadrilateral_hierarchy", "refuted", [T], Dict)
    ;   format(string(T),
               "neither class contains the other in the inclusive hierarchy (~w vs ~w)",
               [Sub, Super]),
        checked_dict("quadrilateral_class_inclusion",
                     "geometry:quadrilateral_hierarchy", "refuted", [T], Dict)
    ).

% --- quadrilateral shape property: every Shape has Property ---
%   Universal property claims over the same registry. Properties attach to
%   the most general class that carries them and flow down the inclusion
%   hierarchy; a registered shape without a path to the property refutes
%   the universal claim (some such shape lacks it).
check_math_claim(shape_property(Shape, Property), Dict) :-
    !,
    (   \+ quad_shape(Shape)
    ->  not_covered("quadrilateral_shape_property",
                    "shape is outside the registered quadrilateral hierarchy",
                    Dict)
    ;   \+ quad_property_name(Property)
    ->  not_covered("quadrilateral_shape_property",
                    "property is outside the registered property vocabulary",
                    Dict)
    ;   quad_inclusion(Shape, Carrier), quad_property(Carrier, Property)
    ->  format(string(T), "every ~w is a ~w, and ~w carries ~w",
               [Shape, Carrier, Carrier, Property]),
        checked_dict("quadrilateral_shape_property",
                     "geometry:quadrilateral_hierarchy", "holds", [T], Dict)
    ;   format(string(T),
               "the hierarchy does not license ~w for every ~w (a counterexample ~w exists without it)",
               [Property, Shape, Shape]),
        checked_dict("quadrilateral_shape_property",
                     "geometry:quadrilateral_hierarchy", "refuted", [T], Dict)
    ).

% --- two-sided whole-number equations: fold both sides through counting ---
% The requested bound is part of the compiled term. It may narrow, but cannot
% widen beyond grounded_equation_ceiling/1.
% A side starts from one whole number and applies its printed operations from
% left to right. Signed magnitudes keep a subtraction such as 100-300 inside
% grounded add/subtract/order rather than asking SWI arithmetic for its verdict.
check_math_claim(
    equation_sides(grounded_counting_bound(Bound),
                   side(LeftStart, LeftSteps),
                   side(RightStart, RightSteps)),
    Dict
) :-
    !,
    (   \+ valid_equation_side_domain(Bound, LeftStart, LeftSteps,
                                      RightStart, RightSteps)
    ->  not_covered(
            "whole_number_equation_sides",
            "each side must start from a non-negative integer and use only add(N), subtract(N), or multiply(N) steps with non-negative integer operands",
            Dict)
    ;   grounded_equation_ceiling(Ceiling),
        Bound > Ceiling
    ->  format(
            string(Reason),
            "requested grounded counting bound ~w exceeds the checker ceiling of ~w",
            [Bound, Ceiling]),
        not_covered("whole_number_equation_sides", Reason, Dict)
    ;   side_grounded_bound_violation(Bound, LeftStart, LeftSteps,
                                      LeftViolation)
    ->  grounded_side_bound_reason(left, LeftViolation, Reason),
        not_covered("whole_number_equation_sides", Reason, Dict)
    ;   side_grounded_bound_violation(Bound, RightStart, RightSteps,
                                      RightViolation)
    ->  grounded_side_bound_reason(right, RightViolation, Reason),
        not_covered("whole_number_equation_sides", Reason, Dict)
    ;   fold_grounded_side(LeftStart, LeftSteps, LeftValue),
        fold_grounded_side(RightStart, RightSteps, RightValue),
        signed_value_text(LeftValue, LeftText),
        signed_value_text(RightValue, RightText),
        (   signed_equal(LeftValue, RightValue)
        ->  Verdict = "holds",
            format(string(Trace),
                   "left side has ~w; right side has ~w; both sides come to the same count",
                   [LeftText, RightText])
        ;   signed_order_gap(LeftValue, RightValue, Larger, Gap),
            rec_int(Gap, GapCount),
            Verdict = "refuted",
            format(string(Trace),
                   "left side has ~w; right side has ~w; ~w side is larger by a count of ~w",
                   [LeftText, RightText, Larger, GapCount])
        ),
        checked_dict(
            "whole_number_equation_sides",
            "grounded_equation_sides",
            Verdict,
            [Trace],
            Dict)
    ).

% --- SWI arithmetic red pen: numeric expression equality ---
check_math_claim(arithmetic_equation(Left, Right), Dict) :-
    !,
    swi_arithmetic_profile(Left, Right, Dict).

% --- SWI arithmetic relational rail: numeric expressions on both sides ---
% The printed-expression reader supplies the relation; exact_value/2 performs
% the same exact decimal/rational evaluation used by arithmetic equations.
% comparison_pred/3 keeps the admitted relation vocabulary shared with the
% grounded whole-number and fraction comparison clauses.
check_math_claim(arithmetic_comparison(Left, Relation, Right), Dict) :-
    !,
    swi_arithmetic_comparison_profile(Left, Relation, Right, Dict).

% --- fallback ---
check_math_claim(Claim, Dict) :-
    format(string(ClaimStr), "~w", [Claim]),
    Dict = _{ status: "not_covered",
              claim: ClaimStr,
              verdict: "not_checked",
              adjudication: "not_in_registered_domain",
              reason: "no domain checker is registered for this claim shape" }.

not_covered(Claim, Reason, _{ status: "not_covered", claim: Claim,
                              verdict: "not_checked",
                              adjudication: "not_in_registered_domain",
                              reason: Reason }).

grounded_fraction_claim(equivalence(_, _), "fraction_equivalence").
grounded_fraction_claim(n_over_n_is_one(_), "n_over_n_is_one").
grounded_fraction_claim(improper(_), "improper_fraction").
grounded_fraction_claim(number_line_position(_, _), "number_line_position").
grounded_fraction_claim(midpoint(_), "number_line_midpoint").
grounded_fraction_claim(multiplication(_, _, _), "fraction_multiplication").
grounded_fraction_claim(fraction_of(_, _, _), "fraction_of_quantity").
grounded_fraction_claim(difference(_, _, _), "fraction_difference").
grounded_fraction_claim(iterate_to_whole(_, _), "iterate_to_whole").
grounded_fraction_claim(fraction_sum(_, _, _), "fraction_sum").
grounded_fraction_claim(comparison(_, _, _), "fraction_comparison").

invalid_fraction_component(Claim) :-
    sub_term(fraction(N, D), Claim),
    ( \+ integer(N) ; \+ integer(D) ; N < 0 ; D < 0 ).

%!  fraction_equivalence(+N1,+D1,+N2,+D2, -Verdict, -Trace) is semidet.
%
%   Co-measure both fractions in a shared fractional unit (mc3 disposition:
%   the shared completion is available), then compare the two measured counts
%   by grounded equality. Equal measured counts -> "holds"; unequal -> "refuted".
fraction_equivalence(N1,D1,N2,D2, Verdict, Trace) :-
    integer_to_recollection(N1, CountA),
    integer_to_recollection(D1, BaseA),
    integer_to_recollection(N2, CountB),
    integer_to_recollection(D2, BaseB),
    catch(co_measure_fractions(CountA, BaseA, CountB, BaseB, mc3, CoState, CoTrace),
          _, fail),
    CoState = co_measurement_state(Fields),
    member(first_as(fraction(MeasuredA, Shared)), Fields),
    member(second_as(fraction(MeasuredB, Shared)), Fields),
    ( equal_to(MeasuredA, MeasuredB) -> Verdict = "holds" ; Verdict = "refuted" ),
    recollection_int(MeasuredA, MA), recollection_int(MeasuredB, MB), recollection_int(Shared, SB),
    format(string(Cmp), "in shared base ~w: ~w/~w vs ~w/~w", [SB, MA, SB, MB, SB]),
    trace_strings(CoTrace, CoStrs),
    Trace = [Cmp | CoStrs].

recollection_int(recollection(H), N) :- length(H, N).
rec_int(recollection(H), N) :- length(H, N).

%!  nonneg_integers(+List) is semidet.
%   True when every element is a non-negative integer (a grounded natural).
nonneg_integers(List) :-
    is_list(List),
    forall(member(X, List), (integer(X), X >= 0)).

%!  comparison_pred(+Rel, -GroundedPred, -RelText) is semidet.
%   Map a surface comparison relation to a grounded order predicate. The
%   greater/smaller/equal row is the vocabulary the pass-1 extraction
%   catalog advertises; before it was accepted here, every comparison claim
%   the model emitted came back not_covered.
comparison_pred(Rel, greater_than, ">") :- memberchk(Rel, [greater_than, gt, >, greater]).
comparison_pred(Rel, smaller_than, "<") :- memberchk(Rel, [less_than, lt, <, smaller, less]).
comparison_pred(Rel, equal_to, "=")     :- memberchk(Rel, [equal_to, eq, =, equal]).

%!  ordering_pred(+Direction, -GroundedPred) is semidet.
ordering_pred(ascending, smaller_than).
ordering_pred(descending, greater_than).

% ---------------------------------------------------------------------------
% Quadrilateral hierarchy (for class_inclusion and shape_property claims).
% Each direct edge cites the geometry KB concept that records it
% (knowledge/geometry/concepts/classification.pl); trapezoid_as_quadrilateral has no
% KB concept because no source disputes it.
% ---------------------------------------------------------------------------
quad_shape(square).
quad_shape(rectangle).
quad_shape(rhombus).
quad_shape(parallelogram).
quad_shape(trapezoid).
quad_shape(quadrilateral).

quad_direct_inclusion(square, rectangle, square_as_rectangle).
quad_direct_inclusion(square, rhombus, square_as_rhombus).
quad_direct_inclusion(rectangle, parallelogram, rectangle_as_parallelogram).
quad_direct_inclusion(rhombus, parallelogram, rhombus_as_parallelogram).
quad_direct_inclusion(parallelogram, quadrilateral, parallelogram_as_quadrilateral).
quad_direct_inclusion(trapezoid, quadrilateral, trapezoid_as_quadrilateral).

%!  quad_inclusion(?Sub, ?Super) is nondet.
%   Reflexive-transitive closure of the direct edges.
quad_inclusion(S, S) :- quad_shape(S).
quad_inclusion(Sub, Super) :-
    quad_direct_inclusion(Sub, Mid, _),
    quad_inclusion(Mid, Super).

quad_inclusion_note(Sub, Super, Note) :-
    (   quad_direct_inclusion(Sub, Super, Note)
    ->  true
    ;   Sub == Super
    ->  Note = same_class
    ;   Note = transitive_through_the_hierarchy
    ).

% Universal properties, attached at the most general carrier; shapes below
% inherit them through quad_inclusion.
quad_property_name(four_sides).
quad_property_name(four_right_angles).
quad_property_name(four_equal_sides).
quad_property_name(two_pairs_parallel_sides).
quad_property_name(opposite_sides_equal).

quad_property(quadrilateral, four_sides).
quad_property(parallelogram, two_pairs_parallel_sides).
quad_property(parallelogram, opposite_sides_equal).
quad_property(rectangle, four_right_angles).
quad_property(rhombus, four_equal_sides).

% Formal-core ceiling. A caller may request less in the claim term, but cannot
% authorize a larger recollection or multiplication budget.
grounded_equation_ceiling(10000).

% The corpus maximum is five. An adversarial 999-step side measured 7.81 seconds;
% using that side twice in one claim measured 15.96 seconds.
% This ceiling protects the recursive fold when steps carry little charged work.
grounded_equation_step_ceiling(1000).

% This is separate from the magnitude ceiling because it totals work across
% steps. The 30000 boundary admitted both refused grade-4 expanded-form shapes;
% the current corpus maximum is 3200 counting acts. The adversarial two-side
% claim measured above uses 29880 counting acts per side.
grounded_equation_add_subtract_work_ceiling(30000).

valid_equation_side_domain(Bound, LeftStart, LeftSteps,
                           RightStart, RightSteps) :-
    integer(Bound),
    Bound >= 0,
    valid_equation_side(LeftStart, LeftSteps),
    valid_equation_side(RightStart, RightSteps).

valid_equation_side(Start, Steps) :-
    integer(Start),
    Start >= 0,
    is_list(Steps),
    forall(member(Step, Steps), valid_equation_step(Step)).

valid_equation_step(add(N)) :-
    integer(N),
    N >= 0.
valid_equation_step(subtract(N)) :-
    integer(N),
    N >= 0.
valid_equation_step(multiply(N)) :-
    integer(N),
    N >= 0.

% This preflight protects the grounded fold from constructing work beyond its
% declared limits. Built-in arithmetic decides only route eligibility here;
% the verdict below is grounded. A violation records the first limit that fires
% so a refusal can name its actual cause.
side_grounded_bound_violation(Bound, Start, Steps, Violation) :-
    side_grounded_bound_status(Bound, Start, Steps, Status),
    Status \== within,
    Violation = Status.

side_grounded_bound_status(Bound, Start, Steps, Status) :-
    (   Start > Bound
    ->  Status = start_magnitude(Start, Bound)
    ;   side_bound_fold(Steps, Start, Bound, Status)
    ).

side_bound_fold(Steps, Current, Bound, Status) :-
    grounded_equation_step_ceiling(FormalStepCeiling),
    grounded_equation_add_subtract_work_ceiling(AddSubtractWorkCeiling),
    StepCeiling is min(Bound, FormalStepCeiling),
    side_bound_fold(Steps, Current, 0, 0, 0, Bound,
                    AddSubtractWorkCeiling, StepCeiling, Status).

side_bound_fold([], _, StepCount, AddSubtractWork, MultiplyCost,
                _, _, _, within) :-
    integer(StepCount),
    integer(AddSubtractWork),
    integer(MultiplyCost).
side_bound_fold([Step|Steps], Current, StepCount, AddSubtractWork,
                MultiplyCost, Bound, AddSubtractWorkCeiling, StepCeiling,
                Status) :-
    NextStepCount is StepCount + 1,
    (   NextStepCount > StepCeiling
    ->  Status = step_count(NextStepCount, StepCeiling)
    ;   equation_step_operand(Step, Operand),
        (   Operand > Bound
        ->  Status = step_operand(Operand, Bound)
        ;   side_bound_step_status(
                Step, Steps, Current, NextStepCount, AddSubtractWork,
                MultiplyCost, Bound, AddSubtractWorkCeiling, StepCeiling,
                Status)
        )
    ).

side_bound_step_status(
    Step, Steps, Current, NextStepCount, AddSubtractWork, MultiplyCost,
    Bound, AddSubtractWorkCeiling, StepCeiling, Status
) :-
    step_multiply_cost(Step, MultiplyCost, NextMultiplyCost),
    (   NextMultiplyCost > Bound
    ->  Status = multiply_cost(NextMultiplyCost, Bound)
    ;   step_add_subtract_work(Step, Current, AddSubtractWork,
                               NextAddSubtractWork),
        (   NextAddSubtractWork > AddSubtractWorkCeiling
        ->  Status = add_subtract_work(NextAddSubtractWork,
                                       AddSubtractWorkCeiling)
        ;   step_arithmetic_value(Step, Current, Next),
            NextMagnitude is abs(Next),
            (   NextMagnitude > Bound
            ->  Status = intermediate_magnitude(NextMagnitude, Bound)
            ;   side_bound_fold(
                    Steps, Next, NextStepCount, NextAddSubtractWork,
                    NextMultiplyCost, Bound, AddSubtractWorkCeiling,
                    StepCeiling, Status)
            )
        )
    ).

equation_step_operand(add(N), N).
equation_step_operand(subtract(N), N).
equation_step_operand(multiply(N), N).

step_multiply_cost(add(_), Cost, Cost).
step_multiply_cost(subtract(_), Cost, Cost).
step_multiply_cost(multiply(N), Cost, NextCost) :-
    NextCost is Cost + N.

step_add_subtract_work(add(_), Current, Cost, NextCost) :-
    NextCost is Cost + abs(Current).
step_add_subtract_work(subtract(_), Current, Cost, NextCost) :-
    NextCost is Cost + abs(Current).
step_add_subtract_work(multiply(_), _, Cost, Cost).

step_arithmetic_value(add(N), Current, Next) :-
    Next is Current + N.
step_arithmetic_value(subtract(N), Current, Next) :-
    Next is Current - N.
step_arithmetic_value(multiply(N), Current, Next) :-
    Next is Current * N.

grounded_side_bound_reason(Side, start_magnitude(Value, Limit), Reason) :-
    format(
        string(Reason),
        "~w side starts at ~w; the grounded magnitude limit is ~w",
        [Side, Value, Limit]).
grounded_side_bound_reason(Side, step_operand(Value, Limit), Reason) :-
    format(
        string(Reason),
        "~w side uses step operand ~w; the grounded magnitude limit is ~w",
        [Side, Value, Limit]).
grounded_side_bound_reason(Side, intermediate_magnitude(Value, Limit),
                           Reason) :-
    format(
        string(Reason),
        "~w side reaches intermediate magnitude ~w; the grounded magnitude limit is ~w",
        [Side, Value, Limit]).
grounded_side_bound_reason(Side, add_subtract_work(Value, Limit), Reason) :-
    format(
        string(Reason),
        "~w side needs ~w counting acts across its add/subtract steps; the grounded cumulative-work limit is ~w",
        [Side, Value, Limit]).
grounded_side_bound_reason(Side, multiply_cost(Value, Limit), Reason) :-
    format(
        string(Reason),
        "~w side needs ~w multiplication iterations across its steps; the grounded multiplication-cost limit is ~w",
        [Side, Value, Limit]).
grounded_side_bound_reason(Side, step_count(Value, Limit), Reason) :-
    format(
        string(Reason),
        "~w side has ~w steps; the grounded step-count ceiling is ~w",
        [Side, Value, Limit]).

fold_grounded_side(Start, Steps, Value) :-
    integer_to_recollection(Start, StartMagnitude),
    signed_from_positive_magnitude(StartMagnitude, Initial),
    fold_grounded_steps(Steps, Initial, Value).

fold_grounded_steps([], Value, Value).
fold_grounded_steps([Step|Steps], Current, Value) :-
    integer_step_recollection(Step, Operation, Operand),
    apply_signed_grounded_step(Operation, Current, Operand, Next),
    fold_grounded_steps(Steps, Next, Value).

integer_step_recollection(add(N), add, Recollection) :-
    integer_to_recollection(N, Recollection).
integer_step_recollection(subtract(N), subtract, Recollection) :-
    integer_to_recollection(N, Recollection).
integer_step_recollection(multiply(N), multiply, Recollection) :-
    integer_to_recollection(N, Recollection).

signed_from_positive_magnitude(recollection([]),
                               signed(zero, recollection([]))) :-
    !.
signed_from_positive_magnitude(Magnitude, signed(positive, Magnitude)).

signed_from_negative_magnitude(recollection([]),
                               signed(zero, recollection([]))) :-
    !.
signed_from_negative_magnitude(Magnitude, signed(negative, Magnitude)).

apply_signed_grounded_step(add, signed(zero, _), Operand, Value) :-
    signed_from_positive_magnitude(Operand, Value).
apply_signed_grounded_step(add, signed(positive, Magnitude), Operand,
                           signed(positive, Sum)) :-
    add_grounded(Magnitude, Operand, Sum).
apply_signed_grounded_step(add, signed(negative, Magnitude), Operand, Value) :-
    signed_difference(Operand, Magnitude, Value).

apply_signed_grounded_step(subtract, signed(zero, _), Operand, Value) :-
    signed_from_negative_magnitude(Operand, Value).
apply_signed_grounded_step(subtract, signed(positive, Magnitude), Operand,
                           Value) :-
    signed_difference(Magnitude, Operand, Value).
apply_signed_grounded_step(subtract, signed(negative, Magnitude), Operand,
                           signed(negative, Sum)) :-
    add_grounded(Magnitude, Operand, Sum).

apply_signed_grounded_step(multiply, signed(zero, Zero), _,
                           signed(zero, Zero)).
apply_signed_grounded_step(multiply, signed(positive, Magnitude), Operand,
                           Value) :-
    multiply_grounded(Magnitude, Operand, Product),
    signed_from_positive_magnitude(Product, Value).
apply_signed_grounded_step(multiply, signed(negative, Magnitude), Operand,
                           Value) :-
    multiply_grounded(Magnitude, Operand, Product),
    signed_from_negative_magnitude(Product, Value).

signed_difference(Left, Right, signed(zero, Zero)) :-
    equal_to(Left, Right),
    !,
    zero(Zero).
signed_difference(Left, Right, signed(positive, Difference)) :-
    greater_than(Left, Right),
    !,
    subtract_grounded(Left, Right, Difference).
signed_difference(Left, Right, signed(negative, Difference)) :-
    subtract_grounded(Right, Left, Difference).

signed_equal(signed(Sign, Left), signed(Sign, Right)) :-
    equal_to(Left, Right).

signed_order_gap(signed(positive, Left), signed(positive, Right),
                 Larger, Gap) :-
    signed_same_sign_gap(Left, Right, Larger, Gap).
signed_order_gap(signed(negative, Left), signed(negative, Right),
                 Larger, Gap) :-
    signed_same_sign_gap(Right, Left, Larger, Gap).
signed_order_gap(signed(positive, Left), signed(zero, _), left, Left).
signed_order_gap(signed(positive, Left), signed(negative, Right), left, Gap) :-
    add_grounded(Left, Right, Gap).
signed_order_gap(signed(zero, _), signed(positive, Right), right, Right).
signed_order_gap(signed(zero, _), signed(negative, Right), left, Right).
signed_order_gap(signed(negative, Left), signed(positive, Right), right, Gap) :-
    add_grounded(Left, Right, Gap).
signed_order_gap(signed(negative, Left), signed(zero, _), right, Left).

signed_same_sign_gap(Left, Right, left, Gap) :-
    greater_than(Left, Right),
    !,
    subtract_grounded(Left, Right, Gap).
signed_same_sign_gap(Left, Right, right, Gap) :-
    subtract_grounded(Right, Left, Gap).

signed_value_text(signed(zero, _), "a count of 0").
signed_value_text(signed(positive, Magnitude), Text) :-
    rec_int(Magnitude, Value),
    format(string(Text), "a count of ~w", [Value]).
signed_value_text(signed(negative, Magnitude), Text) :-
    rec_int(Magnitude, Value),
    format(string(Text), "a take-away shortfall of ~w", [Value]).

%!  grounded_chain(+Recollections, +Pred) is semidet.
%   True when each adjacent pair satisfies the grounded relation Pred (strict).
grounded_chain([_], _) :- !.
grounded_chain([A,B|Rest], Pred) :-
    Goal =.. [Pred, A, B],
    call(Goal),
    grounded_chain([B|Rest], Pred).

ints_to_recs([], []).
ints_to_recs([I|Is], [R|Rs]) :- integer_to_recollection(I, R), ints_to_recs(Is, Rs).

%!  verdict_of(:Goal, -Verdict) is det.
%   "holds" if the grounded truth goal succeeds, else "refuted".
verdict_of(Goal, "holds") :- call(Goal), !.
verdict_of(_, "refuted").

checked_dict(Claim, Checker, Verdict, Trace,
             _{ status: "domain_checked", claim: Claim, checker: Checker,
                verdict: Verdict, adjudication: Verdict, trace: Trace }).

%!  exactly_equal(+Left, +Right) is semidet.
%
%   Whether two arithmetic expressions denote the same number.
%
%   Floating-point =:=/2 answers this question wrongly for the decimals and
%   unit fractions the curriculum is written in. `1 - 0.07` evaluates to
%   0.9299999999999999 and `8/12 + 3/12 + 9/12 + 4/12` to 1.9999999999999998,
%   so a checker comparing floats refutes true statements and reports a
%   confident trace while doing it. Nothing internal to the pipeline can catch
%   that: the reader and the check evaluate the same expression the same way.
%   The teacher guides caught it from outside — every disagreement between the
%   guides' printed True/False and this checker was one of these.
%
%   The repair evaluates the leaves exactly and computes upward. Rationalizing
%   the *result* would not do: 1.9999999999999998 is not near a simple
%   fraction, and only the literals carry the decimal the author wrote.
%   Expressions this cannot evaluate exactly — anything outside +, -, *, / over
%   numbers — fall back to the float comparison rather than abstaining, so the
%   accepted domain is unchanged and only its precision moves.
exactly_equal(Left, Right) :-
    (   exact_value(Left, LeftValue),
        exact_value(Right, RightValue)
    ->  LeftValue =:= RightValue
    ;   catch(Left =:= Right, _, fail)
    ).

%!  exact_value(+Expression, -Value) is semidet.
%
%   Value is Expression as an integer or rational. A float literal becomes the
%   simplest rational sharing its representation, which is the decimal the
%   author wrote: rationalize(0.07) is 7/100, where rational(0.07) is the
%   binary artefact 1261007895663739/18014398509481984.
exact_value(Expression, Expression) :-
    rational(Expression),
    !.
exact_value(Expression, Value) :-
    float(Expression),
    !,
    Value is rationalize(Expression).
exact_value(Left + Right, Value) :-
    !,
    exact_value(Left, LeftValue),
    exact_value(Right, RightValue),
    Value is LeftValue + RightValue.
exact_value(Left - Right, Value) :-
    !,
    exact_value(Left, LeftValue),
    exact_value(Right, RightValue),
    Value is LeftValue - RightValue.
exact_value(Left * Right, Value) :-
    !,
    exact_value(Left, LeftValue),
    exact_value(Right, RightValue),
    Value is LeftValue * RightValue.
exact_value(Left / Right, Value) :-
    !,
    exact_value(Left, LeftValue),
    exact_value(Right, RightValue),
    RightValue =\= 0,
    Value is LeftValue rdiv RightValue.
exact_value(-Expression, Value) :-
    !,
    exact_value(Expression, Inner),
    Value is -Inner.

swi_arithmetic_profile(Left, Right, Dict) :-
    format(string(ClaimStr), "~w = ~w", [Left, Right]),
    (   \+ ground(arithmetic_equation(Left, Right))
    ->  Dict = _{ status: "underdetermined",
                  claim: "arithmetic_equation",
                  checker: "swi_builtin_arithmetic:=:=",
                  verdict: "not_checked",
                  adjudication: "underdetermined",
                  reason: "arithmetic equation contains unbound variables" }
    ;   exactly_equal(Left, Right)
    ->  format(string(T), "SWI arithmetic confirms ~w", [ClaimStr]),
        Dict = _{ status: "domain_checked",
                  claim: "arithmetic_equation",
                  checker: "swi_builtin_arithmetic:=:=",
                  verdict: "holds",
                  adjudication: "holds",
                  trace: [T] }
    ;   catch(_ is Left, _, fail),
        catch(_ is Right, _, fail)
    ->  (   arithmetic_deformation_profile(Left, Right, Deformation, DefTrace)
        ->  true
        ;   Deformation = _, DefTrace = _
        ),
        format(string(T), "SWI arithmetic refutes ~w", [ClaimStr]),
        (   nonvar(Deformation)
        ->  Dict = _{ status: "domain_checked",
                      claim: "arithmetic_equation",
                      checker: "swi_builtin_arithmetic:=:=",
                      verdict: "refuted",
                      adjudication: "holds_under_deformation",
                      deformation: Deformation,
                      trace: [T, DefTrace] }
        ;   Dict = _{ status: "domain_checked",
                      claim: "arithmetic_equation",
                      checker: "swi_builtin_arithmetic:=:=",
                      verdict: "refuted",
                      adjudication: "refuted",
                      trace: [T] }
        )
    ;   Dict = _{ status: "not_parseable",
                  claim: "arithmetic_equation",
                  checker: "swi_builtin_arithmetic:=:=",
                  verdict: "not_checked",
                  adjudication: "not_parseable",
                  reason: "expression could not be evaluated by SWI arithmetic" }
    ).

swi_arithmetic_comparison_profile(Left, Relation, Right, Dict) :-
    (   comparison_pred(Relation, Predicate, RelationText)
    ->  (   \+ ground(arithmetic_comparison(Left, Relation, Right))
        ->  Dict = _{ status: "underdetermined",
                      claim: "arithmetic_comparison",
                      checker: "swi_builtin_arithmetic:order",
                      verdict: "not_checked",
                      adjudication: "underdetermined",
                      reason: "arithmetic comparison contains unbound variables" }
        ;   exact_value(Left, LeftValue), exact_value(Right, RightValue)
        ->  (   exact_order_holds(Predicate, LeftValue, RightValue)
            ->  Verdict = "holds"
            ;   Verdict = "refuted"
            ),
            format(string(Trace),
                   "exact arithmetic compares ~w as ~w ~w ~w as ~w",
                   [Left, LeftValue, RelationText, Right, RightValue]),
            Dict = _{ status: "domain_checked",
                      claim: "arithmetic_comparison",
                      checker: "swi_builtin_arithmetic:order",
                      verdict: Verdict,
                      adjudication: Verdict,
                      trace: [Trace] }
        ;   Dict = _{ status: "not_parseable",
                      claim: "arithmetic_comparison",
                      checker: "swi_builtin_arithmetic:order",
                      verdict: "not_checked",
                      adjudication: "not_parseable",
                      reason: "comparison operands could not be evaluated exactly" }
        )
    ;   not_covered("arithmetic_comparison",
                    "unrecognized comparison relation", Dict)
    ).

exact_order_holds(greater_than, Left, Right) :- Left > Right.
exact_order_holds(smaller_than, Left, Right) :- Left < Right.
exact_order_holds(equal_to, Left, Right) :- Left =:= Right.

arithmetic_deformation_profile(A+B, Right, "digit_concat", Trace) :-
    integer(A),
    integer(B),
    integer(Right),
    number_codes(A, ACodes),
    number_codes(B, BCodes),
    append(ACodes, BCodes, RCodes),
    number_codes(Right, RCodes),
    !,
    format(string(Trace), "deformation digit_concat maps ~w and ~w to ~w", [A, B, Right]).

trace_strings(List, Strs) :-
    ( is_list(List) -> Items = List ; Items = [List] ),
    findall(S, ( member(T, Items), format(string(S), "~w", [T]) ), Strs).
