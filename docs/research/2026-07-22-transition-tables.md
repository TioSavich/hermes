# Transition-table extraction

The generated fact files in `knowledge/strategies/transition_tables/` cover
171 of the registry's 172 signatures.  They retain direct action-pair lists
as `q_start` through `q_accept` paths and retain authored `q_` labels for the
six comparison-machine sources.  Every transition has a static source
location.

## Coverage

| Operation family | Signatures | Tables | Skipped |
| --- | ---: | ---: | ---: |
| addition | 11 | 11 | 0 |
| algebraic | 14 | 14 | 0 |
| counting | 8 | 7 | 1 |
| decimal | 16 | 16 | 0 |
| division | 9 | 9 | 0 |
| fraction | 18 | 18 | 0 |
| geometry | 46 | 46 | 0 |
| integer | 6 | 6 | 0 |
| measurement | 8 | 8 | 0 |
| multiplication | 11 | 11 | 0 |
| ratio | 4 | 4 | 0 |
| statistics | 14 | 14 | 0 |
| subtraction | 7 | 7 | 0 |
| **Total** | **172** | **171** | **1** |

The six comparison sources are represented by the fraction number-line,
area-model, set-model, benchmark, and common-unit machines, plus decimal
fraction/place-value comparison. Their named `q_` histories are preserved.

`counting/enumerate_collection_one_to_one` is skipped. Its trace is assembled
with `count_steps/2`, whose number of `pair_object_with_count_word/2` steps
depends on the runtime count; no contracted input witnesses that expansion.

## Static and observed spot checks

The following live calls were run through `run_action_automaton/6`.  The
printed observed trace and nearby generated table agree on the ordered state
or action path. No disagreement was found in these three cases.

### Addition: `count_on_from_larger(47, 28)`

Observed trace:

```prolog
[ choose_larger_addend_as_start(47),
  hold_other_addend_as_count(28),
  iterate_successor_ticks([48, ..., 75]),
  name_last_tick_as_sum(75) ]
```

Generated table:

```prolog
q_start --choose_larger_addend_as_start--> q_step_1
q_step_1 --hold_other_addend_as_count--> q_step_2
q_step_2 --iterate_successor_ticks--> q_step_3
q_step_3 --name_last_tick_as_sum--> q_accept
```

### Fraction: `set_model_fraction_comparison(3/4, 2/3)`

Observed trace states:

```prolog
[q_init, q_unitize_set, q_verify_same_whole, q_partition_set,
 q_count_equal_sets, q_disembed_subset, q_compare_relative_size,
 q_emit, q_accept]
```

Generated table:

```prolog
q_init --init--> q_unitize_set
q_unitize_set --collections_as_single_wholes--> q_verify_same_whole
q_verify_same_whole --commensurable_collections_certified--> q_partition_set
q_partition_set --equal_shares--> q_count_equal_sets
q_count_equal_sets --denominator_counts--> q_disembed_subset
q_disembed_subset --selected_shares--> q_compare_relative_size
q_compare_relative_size --co_measure--> q_emit
q_emit --emit--> q_accept
```

### Geometry: `rectangle_area_unit_iteration(3, 4)`

Observed trace:

```prolog
[ establish_rectangle(3,4), iterate_rows(3), iterate_columns(4),
  coordinate_square_units, count_square_units(12) ]
```

Generated table:

```prolog
q_start --establish_rectangle--> q_step_1
q_step_1 --iterate_rows--> q_step_2
q_step_2 --iterate_columns--> q_step_3
q_step_3 --coordinate_square_units--> q_step_4
q_step_4 --count_square_units--> q_accept
```

## Verification

- `python3 scripts/research/build_transition_tables.py` produced 171 tables
  and the one explicit skip above.
- A second `--check` run produced no changes.
- Every generated fact file loaded in SWI-Prolog together.

The generated facts use `provenance(static('path:line'))`; no transition was
guessed. Dynamic runs are used only for the stated spot cross-checks, so the
output does not claim an observed full-registry table.
