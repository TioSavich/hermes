/** <module> Quantity claims bound to measured kinds

This module encodes one consequence of the anaphoric account of numerals:
a magnitude is checked together with the kind measured in the particular
source span that supplied it.  It does not implement a philosophical account
of numerals.  In particular, two occurrences of `2` are not treated as the
same quantity merely because their magnitudes match; their measured kinds must
also agree.
*/
:- module(quantity_claim, [ check_quantity_claim/2 ]).

:- use_module(library(lists), [ memberchk/2 ]).

%!  check_quantity_claim(+Claim, -Dict) is det.
%
%   Claim is a typed arithmetic relation over quantity(Magnitude, Kind,
%   Provenance).  Provenance is the verbatim span from which the binding came.
%   The predicate always succeeds.  Unknown or unbound quantities remain
%   not_checked rather than becoming dimensionless numbers.

check_quantity_claim(Claim, Dict) :-
    (   claim_with_unbound(Claim, Span)
    ->  not_checked(Claim, Span, Dict)
    ;   check_bound_quantity_claim(Claim, Dict)
    ),
    !.
check_quantity_claim(Claim, Dict) :-
    format(string(ClaimText), "~w", [Claim]),
    Dict = _{ status: "not_checked", claim: ClaimText,
              verdict: "not_checked", adjudication: "not_in_quantity_domain",
              reason: "the claim is not a supported quantity operation" }.

check_bound_quantity_claim(sum(Left, Right, Result), Dict) :-
    !,
    sum_claim(Left, Right, Result, [], Dict).
check_bound_quantity_claim(sum(Left, Right, Result, Conversions), Dict) :-
    !,
    sum_claim(Left, Right, Result, Conversions, Dict).
check_bound_quantity_claim(difference(Left, Right, Result), Dict) :-
    !,
    difference_claim(Left, Right, Result, [], Dict).
check_bound_quantity_claim(difference(Left, Right, Result, Conversions), Dict) :-
    !,
    difference_claim(Left, Right, Result, Conversions, Dict).
check_bound_quantity_claim(scaling(Scalar, Quantity, Result), Dict) :-
    !,
    scaling_claim(Scalar, Quantity, Result, Dict).
check_bound_quantity_claim(product(Left, Right, Result), Dict) :-
    !,
    product_claim(Left, Right, Result, Dict).
check_bound_quantity_claim(quotient(Left, Right, Result), Dict) :-
    !,
    quotient_claim(Left, Right, Result, Dict).
check_bound_quantity_claim(Claim, Dict) :-
    format(string(ClaimText), "~w", [Claim]),
    Dict = _{ status: "not_checked", claim: ClaimText,
              verdict: "not_checked", adjudication: "not_in_quantity_domain",
              reason: "the claim is not a supported quantity operation" }.

% A conversion is recorded in the claim rather than hidden in a global unit
% table: conversion(FromKind, ToKind, Factor, Provenance).  These are measured
% kinds, not SI units, and an unrecorded relation is never inferred.
sum_claim(Left, Right, Result, Conversions, Dict) :-
    normalize_pair(Left, Right, Conversions, NormalLeft, NormalRight, Kind, Trace0),
    !,
    (   NormalLeft = quantity(A, Kind, _),
        NormalRight = quantity(B, Kind, _),
        Result = quantity(C, ResultKind, ResultSpan),
        numeric_magnitudes([A,B,C])
    ->  Sum is A + B,
        quantity_result("sum", Sum, Kind, C, ResultKind, ResultSpan, Trace0, Dict)
    ;   unsupported("sum", "sum quantities need numeric magnitudes and a typed result", Dict)
    ).
sum_claim(Left, Right, _, _, Dict) :-
    incommensurable("sum", Left, Right, Dict).

difference_claim(Left, Right, Result, Conversions, Dict) :-
    normalize_pair(Left, Right, Conversions, NormalLeft, NormalRight, Kind, Trace0),
    !,
    (   NormalLeft = quantity(A, Kind, _),
        NormalRight = quantity(B, Kind, _),
        Result = quantity(C, ResultKind, ResultSpan),
        numeric_magnitudes([A,B,C])
    ->  Difference is A - B,
        quantity_result("difference", Difference, Kind, C, ResultKind, ResultSpan, Trace0, Dict)
    ;   unsupported("difference", "difference quantities need numeric magnitudes and a typed result", Dict)
    ).
difference_claim(Left, Right, _, _, Dict) :-
    incommensurable("difference", Left, Right, Dict).

scaling_claim(quantity(Scalar, dimensionless, _ScalarSpan),
              quantity(Magnitude, Kind, QuantitySpan),
              quantity(ResultMagnitude, ResultKind, ResultSpan), Dict) :-
    !,
    (   numeric_magnitudes([Scalar,Magnitude,ResultMagnitude])
    ->  Product is Scalar * Magnitude,
        format(string(Trace),
               "~w scales ~w ~w from \"~w\"; the measured kind remains ~w",
               [Scalar, Magnitude, Kind, QuantitySpan, Kind]),
        quantity_result("scaling", Product, Kind, ResultMagnitude, ResultKind,
                        ResultSpan, [Trace], Dict)
    ;   unsupported("scaling", "scaling needs numeric magnitudes", Dict)
    ).
scaling_claim(quantity(_, Kind, Span), _, _, Dict) :-
    format(string(Trace),
           "\"~w\" measures ~w, so it is not an unmarked dimensionless scalar",
           [Span, Kind]),
    Dict = _{ status: "not_checked", claim: "scaling", verdict: "not_checked",
              adjudication: "scalar_not_dimensionless", trace: [Trace] }.
scaling_claim(_, _, _, Dict) :-
    unsupported("scaling", "scaling needs three typed quantities", Dict).

product_claim(quantity(A, LeftKind, LeftSpan), quantity(B, RightKind, RightSpan),
              quantity(C, ResultKind, ResultSpan), Dict) :-
    !,
    (   numeric_magnitudes([A,B,C])
    ->  Product is A * B,
        compound_kind(LeftKind, RightKind, ExpectedKind),
        format(string(Trace),
               "\"~w\" measures ~w and \"~w\" measures ~w; their product has kind ~w",
               [LeftSpan, LeftKind, RightSpan, RightKind, ExpectedKind]),
        quantity_result("product", Product, ExpectedKind, C, ResultKind,
                        ResultSpan, [Trace], Dict)
    ;   unsupported("product", "product quantities need numeric magnitudes", Dict)
    ).
product_claim(_, _, _, Dict) :-
    unsupported("product", "product needs three typed quantities", Dict).

quotient_claim(quantity(A, LeftKind, LeftSpan), quantity(B, RightKind, RightSpan),
               quantity(C, ResultKind, ResultSpan), Dict) :-
    !,
    (   numeric_magnitudes([A,B,C]), B =\= 0
    ->  Quotient is A / B,
        quotient_kind(LeftKind, RightKind, ExpectedKind),
        format(string(Trace),
               "\"~w\" measures ~w and \"~w\" measures ~w; their quotient has kind ~w",
               [LeftSpan, LeftKind, RightSpan, RightKind, ExpectedKind]),
        quantity_result("quotient", Quotient, ExpectedKind, C, ResultKind,
                        ResultSpan, [Trace], Dict)
    ;   unsupported("quotient", "quotient quantities need numeric magnitudes and a nonzero divisor", Dict)
    ).
quotient_claim(_, _, _, Dict) :-
    unsupported("quotient", "quotient needs three typed quantities", Dict).

normalize_pair(Left, Right, Conversions, Left, NormalRight, Kind, Trace) :-
    Left = quantity(_, Kind, _),
    convert_to_kind(Right, Kind, Conversions, NormalRight, Trace),
    !.
normalize_pair(Left, Right, Conversions, NormalLeft, Right, Kind, Trace) :-
    Right = quantity(_, Kind, _),
    convert_to_kind(Left, Kind, Conversions, NormalLeft, Trace).

convert_to_kind(quantity(Magnitude, Kind, Span), Kind, _, quantity(Magnitude, Kind, Span), []) :- !.
convert_to_kind(quantity(Magnitude, FromKind, Span), ToKind, Conversions,
                quantity(Converted, ToKind, Span), [Trace]) :-
    memberchk(conversion(FromKind, ToKind, Factor, ConversionSpan), Conversions),
    numeric_magnitudes([Magnitude, Factor]),
    Converted is Magnitude * Factor,
    format(string(Trace),
           "recorded conversion from ~w to ~w at \"~w\" turns ~w into ~w",
           [FromKind, ToKind, ConversionSpan, Magnitude, Converted]).

quantity_result(Claim, ExpectedMagnitude, ExpectedKind, ActualMagnitude,
                ActualKind, ResultSpan, Trace0, Dict) :-
    (   ActualKind \== ExpectedKind
    ->  format(string(Trace),
               "\"~w\" is named ~w, but this operation yields ~w",
               [ResultSpan, ActualKind, ExpectedKind]),
        Dict = _{ status: "domain_checked", claim: Claim, verdict: "refuted",
                  adjudication: "result_kind_mismatch", expected_kind: ExpectedKind,
                  actual_kind: ActualKind, trace: [Trace|Trace0] }
    ;   close_enough(ExpectedMagnitude, ActualMagnitude)
    ->  format(string(Trace), "computed magnitude ~w agrees with the claimed ~w ~w",
               [ExpectedMagnitude, ActualMagnitude, ActualKind]),
        Dict = _{ status: "domain_checked", claim: Claim, verdict: "holds",
                  adjudication: "holds", quantity: quantity(ActualMagnitude, ActualKind, ResultSpan),
                  trace: [Trace|Trace0] }
    ;   format(string(Trace), "computed magnitude ~w does not agree with claimed ~w ~w",
               [ExpectedMagnitude, ActualMagnitude, ActualKind]),
        Dict = _{ status: "domain_checked", claim: Claim, verdict: "refuted",
                  adjudication: "magnitude_mismatch", expected_magnitude: ExpectedMagnitude,
                  actual_magnitude: ActualMagnitude, expected_kind: ExpectedKind,
                  trace: [Trace|Trace0] }
    ).

incommensurable(Claim, quantity(_, LeftKind, LeftSpan), quantity(_, RightKind, RightSpan), Dict) :-
    !,
    format(string(Trace),
           "\"~w\" measures ~w while \"~w\" measures ~w; these quantities cannot be combined without a recorded conversion",
           [LeftSpan, LeftKind, RightSpan, RightKind]),
    Dict = _{ status: "domain_checked", claim: Claim, verdict: "incommensurable",
              adjudication: "incommensurable", left_kind: LeftKind,
              right_kind: RightKind, trace: [Trace] }.
incommensurable(Claim, _, _, Dict) :-
    unsupported(Claim, "the quantities are malformed", Dict).

claim_with_unbound(Claim, Span) :-
    sub_term(quantity(_, unbound, Span), Claim),
    !.

not_checked(Claim, Span, Dict) :-
    format(string(ClaimText), "~w", [Claim]),
    format(string(Trace),
           "\"~w\" has no determined measured kind, so this claim is not checked",
           [Span]),
    Dict = _{ status: "not_checked", claim: ClaimText, verdict: "not_checked",
              adjudication: "unbound_quantity", trace: [Trace] }.

unsupported(Claim, Reason, _{ status: "not_checked", claim: Claim,
                               verdict: "not_checked",
                               adjudication: "not_in_quantity_domain",
                               reason: Reason }).

numeric_magnitudes(Values) :-
    forall(member(Value, Values), number(Value)).

close_enough(A, B) :- abs(A - B) < 0.0000001.

compound_kind(dimensionless, Kind, Kind) :- !.
compound_kind(Kind, dimensionless, Kind) :- !.
compound_kind(LeftKind, RightKind, Compound) :-
    atomic_list_concat([LeftKind, times, RightKind], '_', Compound).

quotient_kind(Kind, Kind, dimensionless) :- !.
quotient_kind(LeftKind, RightKind, Rate) :-
    atomic_list_concat([LeftKind, per, RightKind], '_', Rate).
