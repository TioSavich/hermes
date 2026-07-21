/** <module> Grounded Partitive Fractional Scheme Implementation
 *
 * This module implements Jason's partitive fractional schemes using a
 * grounded arithmetic approach with nested unit representation.
 */

:- module(jason, [partitive_fractional_scheme/4]).

:- use_module(formalization(grounded_ens_operations), [ens_partition/3]).
:- use_module(strategies(normalization), [normalize/2]).
:- use_module(formalization(grounded_arithmetic), [incur_cost/1]).

partitive_fractional_scheme(M_Rec, D_Rec, InputQty, ResultQty) :-
    pfs_partition_quantity(D_Rec, InputQty, PartitionedParts),
    incur_cost(pfs_partitioning_stage),
    pfs_select_parts(M_Rec, PartitionedParts, SelectedPartsFlat),
    incur_cost(pfs_selection_stage),
    normalize(SelectedPartsFlat, ResultQty).

pfs_partition_quantity(_D_Rec, [], []).
pfs_partition_quantity(D_Rec, [Unit|RestUnits], [Parts|RestParts]) :-
    ens_partition(Unit, D_Rec, Parts),
    pfs_partition_quantity(D_Rec, RestUnits, RestParts).

pfs_select_parts(_M_Rec, [], []).
pfs_select_parts(M_Rec, [Parts|RestParts], SelectedPartsFlat) :-
    take_m(M_Rec, Parts, Selection),
    pfs_select_parts(M_Rec, RestParts, RestSelection),
    append(Selection, RestSelection, SelectedPartsFlat).

take_m(recollection([]), _List, []).
take_m(recollection([t|Ts]), [H|T], [H|RestSelection]) :-
    !,
    take_m(recollection(Ts), T, RestSelection).
take_m(recollection(_), [], []).
