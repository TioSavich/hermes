# Articulation pilot: fraction-domain `too_vague` rows

## Purpose and boundary

`too_vague` remains a signal that a row could not yet be reconstructed as an automaton. It is not renamed. This pilot asks a drafting model either to articulate a runnable candidate from the row, its nearby named records, and related runnable fraction models, or to decline when those materials still underdetermine a task, output, referent whole, or procedure.

The harness does not modify `knowledge/`. A live response is stored only as `REVIEW-PENDING` under `scripts/research/articulation_out/`. The existing churn execution gate is reused as a mechanical screen. A passing screen does not admit a candidate: opus semantic review and the owner's read remain required.

## Selection and context method

The controller should start with these ten fraction-domain rows: 37441, 37585, 38281, 38451, 38478, 38645, 38842, 38961, 39596, and 40129. Their recorded accounts concern sharing, partitive or unit-fraction work, partitioning, a referent whole, or iteration, where the repository has particularly direct runnable case models.

For each row, the harness gathers its documented-error gloss, citation, provenance comments, four named nearest neighbours, one or two runnable source modules, and the state-vocabulary labels used by those modules. It verifies sidecar alignment before retrieval: exactly one `data/research/misconception_embeddings.*` entry must cite `db row <id>`. It then uses that entry's stored vector as the query vector, so dry runs require no embedding API call. Keyword selection is deliberately simple and inspectable: number-line words select `smr_frac_nl_compare.pl`; equivalence/repartitioning words select equivalence/common-unit modules; sharing/set words select `jason.pl` and set comparison; partition/piece/whole/unit words select `jason.pl` and area comparison; otherwise it selects area and common-unit comparison.

## Vocabulary note

The owner holds “misconception” under erasure. Candidate prose says “documented error” for behavior a study recorded as error; it does not use diagnostic language about children. The mediant lesson applies: a documented way of working that is contextually correct under its own referents is not thereby a deficit. Every commitment inferred beyond source text must be named explicitly, and a precise `DECLINE` is a successful outcome.

## Controller-run pilot

First inspect dry contexts without a network call:

```sh
python3 scripts/research/too_vague_articulation.py --dry-run 37441 37585 38451
```

Then run the ten-row live pilot only when REALLMS use is intended:

```sh
python3 scripts/research/too_vague_articulation.py --live 37441 37585 38281 38451 38478 38645 38842 38961 39596 40129
```

Review every `REVIEW-PENDING` response before considering any later change to `knowledge/`.

## Verification evidence

The following three named dry-run bundles are the sandbox-safe evidence required for this task. They are produced from the stored sidecar vectors; no embedding request is sent.

```text
$ python3 scripts/research/too_vague_articulation.py --dry-run 37441 37585 38451

db_row(37441)
  documented error: a person's share of 27 pieces among 3 people is 3/27 by counting people over pieces
  citation: Leslie P. Steffe (2004)
  offline neighbours: too_vague (39008, .8553); pieces_instead_of_fraction (40112, .8529);
    too_vague (37953, .8426); share_count_as_denom (39010, .8342)
  sources: knowledge/strategies/math/jason.pl; knowledge/strategies/math/smr_frac_set_compare.pl
  labels: q_unitize_set, q_partition_set, q_count_equal_sets, q_disembed_subset,
    q_subset_size_focus, q_verify_same_whole, q_compare_relative_size

db_row(37585)
  documented error: one-half is the act of cutting into two, not a quantity, so no shading is needed
  citation: Katherine E. Lewis (2014)
  offline neighbours: too_vague (38979, .8817); too_vague (40153, .8639);
    too_vague (38261, .8372); too_vague (38335, .8356)
  sources: knowledge/strategies/math/jason.pl; knowledge/strategies/math/smr_frac_area_compare.pl
  labels: q_unitize_whole, q_partition, q_disembed, q_iterate_count_parts,
    q_unequal_partition_piece_count, q_verify_same_size_whole, q_compare_relative_size

db_row(38451)
  documented error: draw a stick the same length as the given one and ignore the fractional language
  citation: Steven Boyce, Anderson Norton (2016)
  offline neighbours: too_vague (39654, .8225); too_vague (38554, .8152);
    too_vague (40257, .8132); too_vague (37513, .8091)
  sources: knowledge/strategies/math/smr_frac_nl_compare.pl; knowledge/strategies/math/smr_frac_area_compare.pl
  labels include q_identify_unit, q_partition_interval, q_mark_off_lengths,
    q_locate_endpoint, q_measure_with_unit_fraction, q_compare_positions,
    q_unitize_whole, q_partition, and q_unequal_partition_piece_count
```

The full default ten-row dry run also completed offline (`3008` output lines). The harness prints each selected source excerpt and the complete drafting prompt after the compact evidence above.

## Implementation report

Files changed: `scripts/research/too_vague_articulation.py`; `docs/research/2026-07-22-articulation-pilot-plan.md`.

Evidence: `python3 -m py_compile scripts/research/too_vague_articulation.py` exited 0. `python3 scripts/research/too_vague_articulation.py --dry-run 37441 37585 38451` exited 0 and printed the three bundles above. `python3 scripts/research/too_vague_articulation.py --dry-run --limit 10` exited 0. No live model call was made, no `knowledge/` file was changed, and no candidate was admitted.

IMPLEMENTATION_COMPLETE
