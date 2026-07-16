/** <module> Grounded ENS Operations for Fractional Arithmetic
 *
 * This module implements the core Equal-N-Sharing (ENS) operations for
 * grounded fractional arithmetic. It provides the fundamental partitioning
 * operations that create nested unit structures.
 *
 * The ENS operations capture the embodied understanding of partitioning,
 * where a unit is divided into equal parts through structural representation
 * rather than numerical calculation.
 *
 * @author FSM Engine System
 * @license MIT
 */

:- module(grounded_ens_operations, [
    ens_partition/3,
    ens_disembed/2,
    ens_iterate/3
]).

:- use_module(grounded_arithmetic, [incur_cost/1]).

%! ens_partition(+InputUnit, +N_Rec, -PartitionedParts) is det.
%
% Partitions a single InputUnit into N equal parts using structural
% representation. This implements the embodied understanding of division
% as creating equal shares.
%
% @param InputUnit The unit to be partitioned
% @param N_Rec Recollection structure specifying the number of parts
% @param PartitionedParts List of N identical fractional units
%
% The partitioning creates a nested structure where each new unit is
% defined as 1/N of the InputUnit. This naturally handles recursive
% partitioning by creating increasingly nested structures.
%
% Example: Partitioning unit(whole) into 3 parts creates:
% [unit(partitioned(recollection([t,t,t]), unit(whole))), 
%  unit(partitioned(recollection([t,t,t]), unit(whole))),
%  unit(partitioned(recollection([t,t,t]), unit(whole)))]
%
ens_partition(InputUnit, N_Rec, PartitionedParts) :-
    % The new unit is defined structurally as 1/N of the InputUnit
    % This naturally handles recursive partitioning by creating nested structures
    NewUnit = unit(partitioned(N_Rec, InputUnit)),

    % The result is N copies of this new unit
    generate_copies(N_Rec, NewUnit, PartitionedParts),
    incur_cost(ens_partition).

%! ens_disembed(+PartitionedParts, -UnitFraction) is det.
%
% Selects one fractional unit from a partitioned whole while preserving the
% structural unit representation produced by ens_partition/3.
%
ens_disembed([UnitFraction | _], UnitFraction) :-
    !,
    incur_cost(ens_disembed).
ens_disembed([], _) :-
    throw(error(cannot_disembed_from_empty_partition, _)).

%! ens_iterate(+UnitFraction, +M_Rec, -IteratedUnits) is det.
%
% Iterates a disembedded unit M times as a list of identical structural units.
% This keeps iteration in the same unit(partitioned(...)) dialect as
% ens_partition/3 and ens_disembed/2.
%
ens_iterate(UnitFraction, M_Rec, IteratedUnits) :-
    generate_copies(M_Rec, UnitFraction, IteratedUnits),
    incur_cost(ens_iterate).

%! generate_copies(+N_Rec, +Unit, -Copies) is det.
%
% Generates N copies of a unit based on the recollection structure.
% Each tally 't' in the recollection corresponds to one copy.
%
% @param N_Rec Recollection structure with tallies
% @param Unit The unit to copy
% @param Copies List of N identical units
%
generate_copies(recollection(Tallies), Unit, Copies) :-
    generate_recursive(Tallies, Unit, [], Copies).

%! generate_recursive(+Tallies, +Unit, +Acc, -Copies) is det.
%
% Recursively generates copies by processing each tally.
%
% @param Tallies List of tallies to process
% @param Unit The unit to copy
% @param Acc Accumulator for building the result
% @param Copies Final list of copies
%
generate_recursive([], _Unit, Acc, Acc).
generate_recursive([t|Ts], Unit, Acc, Copies) :-
    generate_recursive(Ts, Unit, [Unit|Acc], Copies).
