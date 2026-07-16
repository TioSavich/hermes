/** <module> MUA conjecture register
 *
 * Demonstrated MUA relations stay in `mua_relations.pl` and must keep passing
 * the health gate. Aspirational, stale, or not-yet-demonstrated relations go
 * here instead of weakening the demonstrated relation predicates.
 */

:- module(mua_conjectures,
          [ conjectured_relation/2,
            conjecture_register_status/1
          ]).

:- dynamic conjectured_relation/2.

%!  conjectured_relation(?Relation, ?Why) is nondet.
%
%   Empty by policy until a concrete relation needs an explicitly conjectural
%   home. Relation is the proposed MUA relation term; Why records why it cannot
%   yet live in `mua_relations.pl`.

%!  conjecture_register_status(-Status) is det.
conjecture_register_status(_{ kind: mua_conjecture_register,
                              location: 'pml/mua_conjectures.pl',
                              policy: separate_from_demonstrated_relations,
                              conjecture_count: Count }) :-
    aggregate_all(count, conjectured_relation(_, _), Count).
