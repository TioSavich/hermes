/** <module> Normalization Engine for Grounded Fractional Arithmetic
 *
 * This module implements the normalization engine that repeatedly applies
 * equivalence rules until quantities are fully simplified. It provides the
 * cognitive process of iterative simplification in fractional reasoning.
 *
 * The normalization process continues until no more equivalence rules can
 * be applied, resulting in a canonical representation of the quantity.
 *
 * @author FSM Engine System
 * @license MIT
 */

:- module(normalization, [
    normalize/2
]).

:- use_module(math(fraction_semantics), [apply_equivalence_rule/3]).

%! normalize(+QtyIn, -QtyOut) is det.
%
% Normalizes a quantity by repeatedly applying equivalence rules until
% no more rules can be applied. This implements the cognitive process
% of iterative simplification.
%
% @param QtyIn Input quantity (list of units)
% @param QtyOut Normalized output quantity in canonical form
%
% The normalization process applies rules in the following priority:
% 1. Grouping rules (reconstitution of wholes from parts)
% 2. Composition rules (flattening of nested partitions)
%
% The final result is sorted to provide a canonical representation.
%
normalize(QtyIn, QtyOut) :-
    (   apply_normalization_step(QtyIn, QtyTemp)
    ->  % If a rule was applied, continue normalizing
        normalize(QtyTemp, QtyOut)
    ;   % No more rules apply, sort for canonical representation
        sort(QtyIn, QtyOut)
    ).

%! apply_normalization_step(+QtyIn, -QtyOut) is semidet.
%
% Attempts to apply one equivalence rule to the quantity.
% Uses once/1 to commit to the first successful rule application.
%
% @param QtyIn Input quantity
% @param QtyOut Quantity after applying one rule
%
% Rules are tried in priority order:
% 1. Grouping (e.g., 3/3 -> 1) - reconstitution of wholes
% 2. Composition (e.g., 1/4 of 1/3 -> 1/12) - flattening nested fractions
%
apply_normalization_step(QtyIn, QtyOut) :-
    % 1. Try Grouping first (reconstitution has higher priority)
    once(apply_equivalence_rule(grouping, QtyIn, QtyOut)).
    
apply_normalization_step(QtyIn, QtyOut) :-
    % 2. Try Composition (flattening nested structures)
    once(apply_equivalence_rule(composition, QtyIn, QtyOut)).