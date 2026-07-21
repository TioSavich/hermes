# knowledge/crosswalk/families

The 38 logical crosswalk families share this directory's seven files.

## Two kinds of family

**Data families (34).** `cw_edges.pl` holds the families in one keyed table.
`rule/2` records each family's derivation and witness clauses; `edge/6` names
the family, owner predicate, and probe archetype. Family groups are alphabetical,
and rows retain their original order within each group. `cw_driver.pl` supplies
the shared query surface (the `*_unified` and `*_witness` predicates) and runs
the recorded clauses in family context.

**Own-surface families (4).** `cw_counting_claim`, `cw_fraction_claim`,
`cw_place_value_number_claim`, and `cw_whole_number_claim` export their own
`*_unified`/`*_witness` predicates directly rather than routing through the
driver.

## The archetype enum

An `edge/6` row reads
`edge(Family, OwnerModule, Pred/Arity, ArgSpec, Extra, Archetype)`.
`Archetype` is one of the seven `archetype/1` values in `cw_driver.pl`:
`call_bind_out`, `call_match_ground`, `call_once_bind_out`,
`call_guarded_numeric`, `call_with_snapshot`, `call_aggregate`,
`registry_projection`. The archetype fixes how the driver calls the owner
predicate for that row.

## Loading and boundaries

`cw_driver.pl` loads `cw_edges.pl` and exposes its keys as `data_family/1`.
Witness dicts come from `witness_dict:witness_dict/4` (formalization), so every
family shares one witness shape. `knowledge/crosswalk/canonical_all.pl` re-exports the
family surface. A family answers from its own closed table; it does not compute
beyond the owner predicate its rows name.
