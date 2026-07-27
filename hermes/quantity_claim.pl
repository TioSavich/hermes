/** <module> Quantity claims bound to measured kinds

This module encodes one consequence of the anaphoric account of numerals:
a magnitude is checked together with the kind measured in the particular
source span that supplied it.  It does not implement a philosophical account
of numerals.  In particular, two occurrences of `2` are not treated as the
same quantity merely because their magnitudes match; their measured kinds must
also agree.

Agreement is identity of the measured kind, and that fineness is the point.
Supplying a shared parent so that students without an A and students with a B
or a C combine as students was measured and lost on every axis: it reintroduces
the singular-term reading this account rejects, and it cost first-wrong-step
recovery without buying discrimination.

The kind an operation yields is recorded but never refutes.  What the operands
measure decides whether an operation is available; what the step called the
result is the step's own label.

Two entry points do the same adjudication.  `check_quantity_claim/2` takes one
operation with its claimed result.  `check_quantity_expression/3` takes a tree
of operations and the result the step claimed for the whole of it, so a caller
reading an equation does not have to compute intermediate kinds for itself.
*/
:- module(quantity_claim, [ check_quantity_claim/2, check_quantity_expression/3 ]).

:- use_module(library(lists), [ memberchk/2, append/3 ]).

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
    not_in_domain(Claim, Dict).

check_bound_quantity_claim(sum(Left, Right, Result), Dict) :-
    !,
    one_operation(sum, Left, Right, [], Result, Dict).
check_bound_quantity_claim(sum(Left, Right, Result, Conversions), Dict) :-
    !,
    one_operation(sum, Left, Right, Conversions, Result, Dict).
check_bound_quantity_claim(difference(Left, Right, Result), Dict) :-
    !,
    one_operation(difference, Left, Right, [], Result, Dict).
check_bound_quantity_claim(difference(Left, Right, Result, Conversions), Dict) :-
    !,
    one_operation(difference, Left, Right, Conversions, Result, Dict).
check_bound_quantity_claim(scaling(Scalar, Quantity, Result), Dict) :-
    !,
    one_operation(scaling, Scalar, Quantity, [], Result, Dict).
check_bound_quantity_claim(product(Left, Right, Result), Dict) :-
    !,
    one_operation(product, Left, Right, [], Result, Dict).
check_bound_quantity_claim(quotient(Left, Right, Result), Dict) :-
    !,
    one_operation(quotient, Left, Right, [], Result, Dict).
check_bound_quantity_claim(Claim, Dict) :-
    not_in_domain(Claim, Dict).

one_operation(Operation, Left, Right, Conversions, Claimed, Dict) :-
    (   operate(Operation, Left, Right, Conversions, Outcome)
    ->  outcome_against_claim(Operation, Outcome, Claimed, Dict)
    ;   operation_name(Operation, Name),
        unsupported(Name, "the operands are not typed quantities", Dict)
    ).

%!  check_quantity_expression(+Expression, +Claimed, -Dict) is det.
%
%   Expression is a tree whose leaves are quantity/3 and whose nodes are
%   sum/2, difference/2, product/2, quotient/2 or scaling/2.  Claimed is the
%   quantity written on the other side of the equals sign.  The first node
%   that blocks is what the dict reports; otherwise the value the tree
%   produces is checked against Claimed by the same test a single operation
%   gets.  A tree carrying any unbound quantity stays not_checked whole.

check_quantity_expression(Expression, Claimed, Dict) :-
    (   unbound_span(Expression, Span)
    ->  not_checked(Expression, Span, Dict)
    ;   unbound_span(Claimed, Span)
    ->  not_checked(Expression, Span, Dict)
    ;   evaluate(Expression, Outcome)
    ->  outcome_against_claim(expression, Outcome, Claimed, Dict)
    ;   unsupported("expression",
                    "the expression is not a tree of supported quantity operations",
                    Dict)
    ),
    !.
check_quantity_expression(Expression, _, Dict) :-
    not_in_domain(Expression, Dict).

evaluate(quantity(Magnitude, Kind, Span), produced(quantity(Magnitude, Kind, Span), [])) :-
    !.
evaluate(Node, Outcome) :-
    compound(Node),
    Node =.. [Operation, LeftExpression, RightExpression],
    operation_name(Operation, _),
    !,
    evaluate(LeftExpression, LeftOutcome),
    (   LeftOutcome = blocked(_)
    ->  Outcome = LeftOutcome
    ;   evaluate(RightExpression, RightOutcome),
        combine(Operation, LeftOutcome, RightOutcome, Outcome)
    ).

combine(_, _, blocked(Dict), blocked(Dict)) :- !.
combine(Operation, produced(Left, LeftTrace), produced(Right, RightTrace), Outcome) :-
    append(LeftTrace, RightTrace, Inherited),
    (   operate(Operation, Left, Right, [], Result)
    ->  carry_trace(Result, Inherited, Outcome)
    ;   operation_name(Operation, Name),
        unsupported(Name, "the operands are not typed quantities", Dict),
        Outcome = blocked(Dict)
    ).

carry_trace(produced(Quantity, Trace), Inherited, produced(Quantity, Whole)) :-
    !,
    append(Trace, Inherited, Whole).
carry_trace(blocked(Dict), Inherited, blocked(Whole)) :-
    (   get_dict(trace, Dict, Trace)
    ->  append(Trace, Inherited, Carried),
        Whole = Dict.put(trace, Carried)
    ;   Whole = Dict
    ).

% ---------------------------------------------------------------------------
% One operation, from typed operands to either a produced quantity or a dict
% saying why nothing was produced.  Every caller adjudicates through here, so
% the kind arithmetic is written once.
% ---------------------------------------------------------------------------

operate(Operation, Left, Right, Conversions, Outcome) :-
    memberchk(Operation, [sum, difference]),
    !,
    additive(Operation, Left, Right, Conversions, Outcome).
operate(scaling, Scalar, Quantity, _, Outcome) :-
    !,
    scale(Scalar, Quantity, Outcome).
operate(product, Left, Right, _, Outcome) :-
    !,
    Left = quantity(A, LeftKind, LeftSpan),
    Right = quantity(B, RightKind, RightSpan),
    (   numeric_magnitudes([A, B])
    ->  Product is A * B,
        compound_kind(LeftKind, RightKind, Kind),
        format(string(Trace),
               "\"~w\" measures ~w and \"~w\" measures ~w; their product has kind ~w",
               [LeftSpan, LeftKind, RightSpan, RightKind, Kind]),
        derived_span(product, LeftSpan, RightSpan, Span),
        Outcome = produced(quantity(Product, Kind, Span), [Trace])
    ;   unsupported("product", "product quantities need numeric magnitudes", Dict),
        Outcome = blocked(Dict)
    ).
operate(quotient, Left, Right, _, Outcome) :-
    !,
    Left = quantity(A, LeftKind, LeftSpan),
    Right = quantity(B, RightKind, RightSpan),
    (   numeric_magnitudes([A, B]), B =\= 0
    ->  Quotient is A / B,
        quotient_kind(LeftKind, RightKind, Kind),
        format(string(Trace),
               "\"~w\" measures ~w and \"~w\" measures ~w; their quotient has kind ~w",
               [LeftSpan, LeftKind, RightSpan, RightKind, Kind]),
        derived_span(quotient, LeftSpan, RightSpan, Span),
        Outcome = produced(quantity(Quotient, Kind, Span), [Trace])
    ;   unsupported("quotient",
                    "quotient quantities need numeric magnitudes and a nonzero divisor",
                    Dict),
        Outcome = blocked(Dict)
    ).

additive(Operation, Left, Right, Conversions, Outcome) :-
    Left = quantity(_, _, LeftSpan),
    Right = quantity(_, _, RightSpan),
    operation_name(Operation, Name),
    (   common_ground(Left, Right, Conversions, A, B, Ground, Trace)
    ->  (   numeric_magnitudes([A, B])
        ->  additive_magnitude(Operation, A, B, Magnitude),
            derived_span(Operation, LeftSpan, RightSpan, Span),
            Outcome = produced(quantity(Magnitude, Ground, Span), Trace)
        ;   unsupported(Name, "these quantities need numeric magnitudes", Dict),
            Outcome = blocked(Dict)
        )
    ;   incommensurable(Name, Left, Right, Dict),
        Outcome = blocked(Dict)
    ).

additive_magnitude(sum, A, B, Magnitude) :- Magnitude is A + B.
additive_magnitude(difference, A, B, Magnitude) :- Magnitude is A - B.

scale(quantity(Scalar, dimensionless, _), quantity(Magnitude, Kind, Span), Outcome) :-
    !,
    (   numeric_magnitudes([Scalar, Magnitude])
    ->  Product is Scalar * Magnitude,
        format(string(Trace),
               "~w scales ~w ~w from \"~w\"; the measured kind remains ~w",
               [Scalar, Magnitude, Kind, Span, Kind]),
        derived_span(scaling, Scalar, Span, DerivedSpan),
        Outcome = produced(quantity(Product, Kind, DerivedSpan), [Trace])
    ;   unsupported("scaling", "scaling needs numeric magnitudes", Dict),
        Outcome = blocked(Dict)
    ).
scale(quantity(_, Kind, Span), _, blocked(Dict)) :-
    format(string(Trace),
           "\"~w\" measures ~w, so it is not an unmarked dimensionless scalar",
           [Span, Kind]),
    Dict = _{ status: "not_checked", claim: "scaling", verdict: "not_checked",
              adjudication: "scalar_not_dimensionless", trace: [Trace] }.

% ---------------------------------------------------------------------------
% Commensurability.  A conversion is recorded in the claim rather than hidden
% in a global unit table: conversion(FromKind, ToKind, Factor, Provenance).
% These are measured kinds, not SI units, and an unrecorded relation is never
% inferred.  Absent a recorded conversion, two kinds still combine when they
% name a measure in common, and the ground they combine on is recorded.
% ---------------------------------------------------------------------------

common_ground(Left, Right, Conversions, A, B, Ground, Trace) :-
    Left = quantity(LeftMagnitude, LeftKind, _),
    Right = quantity(RightMagnitude, RightKind, _),
    (   convert_to_kind(Right, LeftKind, Conversions, quantity(Converted, _, _), Trace)
    ->  Ground = LeftKind, A = LeftMagnitude, B = Converted
    ;   convert_to_kind(Left, RightKind, Conversions, quantity(Converted, _, _), Trace)
    ->  Ground = RightKind, A = Converted, B = RightMagnitude
    ).

convert_to_kind(quantity(Magnitude, Kind, Span), Kind, _, quantity(Magnitude, Kind, Span), []) :- !.
convert_to_kind(quantity(Magnitude, FromKind, Span), ToKind, Conversions,
                quantity(Converted, ToKind, Span), [Trace]) :-
    memberchk(conversion(FromKind, ToKind, Factor, ConversionSpan), Conversions),
    numeric_magnitudes([Magnitude, Factor]),
    Converted is Magnitude * Factor,
    format(string(Trace),
           "recorded conversion from ~w to ~w at \"~w\" turns ~w into ~w",
           [FromKind, ToKind, ConversionSpan, Magnitude, Converted]).

% ---------------------------------------------------------------------------
% The claimed result, against what the operation produced.
% ---------------------------------------------------------------------------

outcome_against_claim(_, blocked(Dict), _, Dict) :- !.
outcome_against_claim(Operation, produced(quantity(Magnitude, Kind, _), Trace),
                      quantity(Claimed, ClaimedKind, ClaimedSpan), Dict) :-
    operation_name(Operation, Name),
    (   numeric_magnitudes([Magnitude, Claimed])
    ->  quantity_result(Name, Magnitude, Kind, Claimed, ClaimedKind, ClaimedSpan, Trace, Dict)
    ;   unsupported(Name, "the claimed result needs a numeric magnitude and a kind", Dict)
    ).
outcome_against_claim(Operation, produced(_, _), _, Dict) :-
    operation_name(Operation, Name),
    unsupported(Name, "the claimed result is not a typed quantity", Dict).

quantity_result(Claim, ExpectedMagnitude, ExpectedKind, ActualMagnitude,
                ActualKind, ResultSpan, Trace0, Dict) :-
    kind_note(ResultSpan, ActualKind, ExpectedKind, Trace0, Trace1),
    (   close_enough(ExpectedMagnitude, ActualMagnitude)
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
                  trace: [Trace|Trace1] }
    ).

%!  kind_note(+ResultSpan, +ActualKind, +ExpectedKind, +Trace0, -Trace) is det.
%
%   Records the kind an operation yields when the step named its result
%   otherwise, without refusing the step.  Refusing it was measured: on 60
%   correct reference solutions that test accused 33, because "12*5 = 60 square
%   feet" names an area where the operation yields length times length, and
%   "108/12 = 9 oranges" names oranges where it yields oranges per student.
%   The test cannot tell a badly named result from a wrongly computed one.

kind_note(_, Kind, Kind, Trace, Trace) :- !.
kind_note(ResultSpan, ActualKind, ExpectedKind, Trace0, [Note|Trace0]) :-
    format(string(Note),
           "\"~w\" is named ~w; this operation yields ~w, which is recorded and not held against the step",
           [ResultSpan, ActualKind, ExpectedKind]).

incommensurable(Claim, quantity(_, LeftKind, LeftSpan), quantity(_, RightKind, RightSpan), Dict) :-
    !,
    format(string(Trace),
           "\"~w\" measures ~w while \"~w\" measures ~w; these are different measured kinds and cannot be combined without a recorded conversion",
           [LeftSpan, LeftKind, RightSpan, RightKind]),
    Dict = _{ status: "domain_checked", claim: Claim, verdict: "incommensurable",
              adjudication: "incommensurable", left_kind: LeftKind,
              right_kind: RightKind, trace: [Trace] }.
incommensurable(Claim, _, _, Dict) :-
    unsupported(Claim, "the quantities are malformed", Dict).

% ---------------------------------------------------------------------------

claim_with_unbound(Claim, Span) :-
    unbound_span(Claim, Span).

unbound_span(Term, Span) :-
    sub_term(quantity(_, unbound, Span), Term),
    !.

not_checked(Claim, Span, Dict) :-
    format(string(ClaimText), "~w", [Claim]),
    format(string(Trace),
           "\"~w\" has no determined measured kind, so this claim is not checked",
           [Span]),
    Dict = _{ status: "not_checked", claim: ClaimText, verdict: "not_checked",
              adjudication: "unbound_quantity", trace: [Trace] }.

not_in_domain(Claim, Dict) :-
    format(string(ClaimText), "~w", [Claim]),
    Dict = _{ status: "not_checked", claim: ClaimText,
              verdict: "not_checked", adjudication: "not_in_quantity_domain",
              reason: "the claim is not a supported quantity operation" }.

unsupported(Claim, Reason, _{ status: "not_checked", claim: Claim,
                               verdict: "not_checked",
                               adjudication: "not_in_quantity_domain",
                               reason: Reason }).

operation_name(sum, "sum").
operation_name(difference, "difference").
operation_name(product, "product").
operation_name(quotient, "quotient").
operation_name(scaling, "scaling").
operation_name(expression, "expression").

% The span of a quantity no span supplied: how the operation reached it.
derived_span(Operation, LeftSpan, RightSpan, Span) :-
    operation_name(Operation, Name),
    format(string(Span), "the ~w of ~w and ~w", [Name, LeftSpan, RightSpan]).

%!  like_kinds(+KindA, +KindB) is semidet.
%
%   Two kinds measure the same thing when they are the same kind.  An unbound
%   kind measures nothing determinate and is like nothing, including itself.

like_kinds(Kind, Kind) :-
    Kind \== unbound.

numeric_magnitudes(Values) :-
    forall(member(Value, Values), number(Value)).

close_enough(A, B) :- abs(A - B) < 0.0000001.

compound_kind(dimensionless, Kind, Kind) :- !.
compound_kind(Kind, dimensionless, Kind) :- !.
compound_kind(LeftKind, RightKind, Compound) :-
    atomic_list_concat([LeftKind, times, RightKind], '_', Compound).

% Like measures divide to a bare ratio; unlike measures name a rate.
quotient_kind(LeftKind, RightKind, dimensionless) :-
    like_kinds(LeftKind, RightKind),
    !.
quotient_kind(LeftKind, RightKind, Rate) :-
    atomic_list_concat([LeftKind, per, RightKind], '_', Rate).
