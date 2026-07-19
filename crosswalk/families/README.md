# crosswalk/families

The 38 crosswalk family files. Each declares `cw_family/1` and answers for one
canonical concept.

## Two kinds of family

**Data families (34).** Each file carries its concept as recorded clauses:
`cw_rule/1` holds the derivation and witness clauses, and `edge/5` rows name
which owner predicate each rule probes and under which archetype. These files
export only `cw_family/1`, `cw_rule/1`, `edge/5` — they hold no query logic.
`cw_driver.pl` supplies their shared query surface (the `*_unified` and
`*_witness` predicates) and runs the recorded clauses in family context.

**Own-surface families (4).** `cw_counting_claim`, `cw_fraction_claim`,
`cw_place_value_number_claim`, and `cw_whole_number_claim` export their own
`*_unified`/`*_witness` predicates directly rather than routing through the
driver.

## The archetype enum

An `edge/5` row reads `edge(OwnerModule, Pred/Arity, ArgSpec, Extra, Archetype)`.
`Archetype` is one of the seven `archetype/1` values in `cw_driver.pl`:
`call_bind_out`, `call_match_ground`, `call_once_bind_out`,
`call_guarded_numeric`, `call_with_snapshot`, `call_aggregate`,
`registry_projection`. The archetype fixes how the driver calls the owner
predicate for that row.

## Loading and boundaries

`cw_driver.pl` loads every data family and lists them as `data_family/1`.
Witness dicts come from `witness_dict:witness_dict/4` (formalization), so every
family shares one witness shape. `crosswalk/canonical_all.pl` re-exports the
family surface. A family answers from its own closed table; it does not compute
beyond the owner predicate its rows name.
