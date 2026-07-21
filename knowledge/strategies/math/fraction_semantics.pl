/** <module> Fractional Semantics for Grounded Arithmetic
 *
 * This module defines the equivalence rules for the nested unit representation
 * used in grounded fractional arithmetic. It implements the core cognitive 
 * operations for fractional reasoning: grouping and composition.
 *
 * The equivalence rules are:
 * 1. Grouping: D copies of (1/D of P) equals P (reconstitution)
 * 2. Composition: (1/A of (1/B of P)) equals (1/(A*B) of P) (integration)
 *
 * @author FSM Engine System  
 * @license MIT
 */

:- module(fraction_semantics, [
    apply_equivalence_rule/3
]).

:- use_module(strategies(composition_engine), [find_and_extract_copies/4]).
:- use_module(formalization(grounded_arithmetic), [incur_cost/1, multiply_grounded/3]).

%! apply_equivalence_rule(+RuleName, +QtyIn, -QtyOut) is semidet.
%
% Applies a specific equivalence rule to transform a quantity.
% This implements the cognitive operations for fractional reasoning.
%
% @param RuleName The name of the rule to apply (grouping or composition)
% @param QtyIn Input quantity (list of units)
% @param QtyOut Output quantity after applying the rule
%

% Rule 1: Grouping (Reconstitution)
% D copies of (1/D of P) equals P.
% This rule implements the embodied understanding that collecting all parts
% of a partitioned whole reconstitutes the original whole.
apply_equivalence_rule(grouping, QtyIn, QtyOut) :-
    % Identify a unit fraction type (D_Rec and ParentUnit) present in the list
    UnitToGroup = unit(partitioned(D_Rec, ParentUnit)),
    member(UnitToGroup, QtyIn),

    % Try to find D copies of this specific unit
    find_and_extract_copies(D_Rec, UnitToGroup, QtyIn, Remainder),

    % If successful, they are replaced by the ParentUnit
    QtyOut = [ParentUnit|Remainder],
    incur_cost(equivalence_grouping).

% Rule 2: Composition (Integration/Coordination of Units)
% (1/A of (1/B of P)) equals (1/(A*B) of P).
% This handles the coordination of three levels of units by flattening
% nested partitions into a single partition with composite denominator.
apply_equivalence_rule(composition, QtyIn, QtyOut) :-
    % Look for a nested partition structure
    NestedUnit = unit(partitioned(A_Rec, unit(partitioned(B_Rec, ParentUnit)))),
    member(NestedUnit, QtyIn),

    % Calculate the new denominator A*B using fully grounded arithmetic
    multiply_grounded(A_Rec, B_Rec, AB_Rec),

    % Define the equivalent simple unit fraction
    SimpleUnit = unit(partitioned(AB_Rec, ParentUnit)),

    % Replace the nested unit with the simple unit
    select(NestedUnit, QtyIn, TempQty),
    QtyOut = [SimpleUnit|TempQty],
    incur_cost(equivalence_composition).