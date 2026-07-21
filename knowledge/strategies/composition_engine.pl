/** <module> Composition Engine for Grounded Fractional Arithmetic
 *
 * This module implements the embodied act of grouping for fractional arithmetic.
 * It provides the core functionality for finding and extracting copies of units
 * from quantities, which is essential for the equivalence rules in fractional 
 * reasoning.
 *
 * The composition engine supports the grounded approach to fractional arithmetic
 * by treating grouping as a cognitive action with associated costs.
 *
 * @author FSM Engine System
 * @license MIT
 */

:- module(composition_engine, [
    find_and_extract_copies/4
]).

:- use_module(formalization(grounded_arithmetic), [incur_cost/1]).

%! find_and_extract_copies(+CountRec, +UnitType, +InputQty, -Remainder) is semidet.
%
% Finds and extracts a specific number of copies of a given unit type from
% an input quantity. This implements the embodied act of grouping units.
%
% @param CountRec The recollection structure specifying how many copies to extract
% @param UnitType The specific unit type to look for and extract
% @param InputQty The input quantity (list of units) to search in
% @param Remainder The remaining quantity after extraction
%
% This predicate fails if there are insufficient copies of UnitType in InputQty.
%
find_and_extract_copies(recollection(Tallies), UnitType, InputQty, Remainder) :-
    extract_recursive(Tallies, UnitType, InputQty, Remainder).

%! extract_recursive(+Tallies, +UnitType, +CurrentQty, -Remainder) is semidet.
%
% Recursively extracts units based on the tally structure.
% Each tally 't' represents one unit to extract.
%
% @param Tallies List of tallies (each 't' represents one unit to extract)
% @param UnitType The unit type to extract
% @param CurrentQty Current quantity being processed
% @param Remainder Final remainder after all extractions
%
extract_recursive([], _UnitType, CurrentQty, CurrentQty).
extract_recursive([t|Ts], UnitType, InputQty, Remainder) :-
    % select/3 finds and removes one instance of UnitType
    select(UnitType, InputQty, TempQty),
    incur_cost(unit_grouping),
    extract_recursive(Ts, UnitType, TempQty, Remainder).