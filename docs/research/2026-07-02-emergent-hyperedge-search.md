# Does the corpus attest an emergent hyperedge? (search record, 2026-07-02)

Register note: this is a research record of a completed search plus the code
decision it disposed. The code it names exists as of this date.

## The question

`formal/incompatibility/brandomian_incompatibility.pl` claims its central advantage over
the classical sequent engine is the EMERGENT hyperedge: a set of contents,
size >= 3, jointly incoherent while no proper subset is. Until this search,
that claim was carried by one seed — Brandom's ripe-blackberry triple — while
the misconception registry's real incompatibility facts are all pairs. The
sprint item asked whether any real emergent hyperedge exists in the repo's
data, with criteria checked by query, and ruled out authoring a fake triple.

## Method

Tool: `formal/incompatibility/find_emergent_hyperedges.pl`. Run:

```sh
swipl -q -l paths.pl -s formal/incompatibility/find_emergent_hyperedges.pl -g run_search -t halt
```

Uniform criterion, applied to every candidate: (a) size >= 3, (b) incoherent
under a runnable consequence relation in this repo, (c) every proper subset
coherent under that same relation. Checks (b) and (c) run as Prolog queries
(`ctx_incoherent/1` over the set and over every one-element removal; removal
coverage suffices because incoherence persists under superset).

Three sources searched:

1. **Misconception registry** (`incompatibility_with/2`). In this checkout:
   895 raw pairs, 175 distinct normalized sets, no degenerate rows. The count
   is a tracked-file floor — the `misconceptions/*_batch_*.csv` rows are
   local untracked files, and where present (the adapter test pins >= 2,000
   distinct sets) they widen the surface without changing its shape.
2. **Big Red iteration7 discovery cache**
   (`formal/incompatibility/incompatibility_sets_discovered.pl`; the tool also
   accepts the former path under `scripts/bigred/iteration7/work/`).
3. **Literature deontic edges** (`literature_deontic_bridge`): 33 derived
   edges over 15 `sr_*` heads, 18 distinct `c_*` commitments in this
   checkout.

## Result

- **Registry: 0 candidates, impossible by shape.** `incompatibility_with/2`
  is binary, so any size >= 3 set assembled from it contains its flagged
  pair and fails criterion (c). The 3-element registry variant
  `[misconception(N), C, E]` was checked by query: 0 entries whose triple
  contains no flagged pair. This holds at any scale of the batch CSVs.
- **Discovery layer: 4 emergent triples, all confirmed live.** The cache's
  four `discovered_set_kind(..., emergent)` rows re-derive under the current
  catalogue, and a live sweep finds exactly the same four combined contexts,
  each equal to one compiled Lakoff & Nunez break-point
  (`compiled_break/2` in `formal/incompatibility/defeasible_inference.pl`):
  `measuring_stick_incommensurability`, `cantor_same_number_reassignment`,
  `spaces_point_blend_inconsistency`,
  `ordered_pairs_rule_extension_collapse`.
- **Literature edges: 0 verifiable candidates.** The corpus supplies pair
  edges only, and neither runnable consequence relation ranges over `c_*`
  atoms (checked by query: no `c_*` atom occurs in any compiled break
  condition). A magnitude-belief triad in fraction/decimal land remains a
  plausible next candidate, but verifying one needs a checker that evaluates
  joint unsatisfiability of `c_*` commitments; asserting the triad without
  one would be the fake triple the item rules out.

## What was seeded, and the precise scope of the claim

The incommensurability triple is now a seed in
`formal/incompatibility/brandomian_incompatibility.pl`:

```prolog
incompatible_set([o(diagonal_of_unit_square_measured),
                  o(length_is_count_of_units),
                  o(grounded(measuring_stick))]).
```

It was chosen over the other three because its joint incoherence bottoms out
in a theorem (sqrt(2) is irrational) rather than in a conceptual
reassignment. Provenance chain, every link runnable: L&N catalogue row
(`base_metaphor_breaks_at/3`) -> `compiled_break/2` -> `emergent_defeat`
classification with a one-element-removal minimality witness
(`classify_defeat_witness/4`) -> Big Red iteration7 re-derivation. Tests:
`test_brandomian_incompatibility.pl` proves incoherence, minimality, and
pairwise coherence in the canonical relation;
`test_incompatibility_discovery.pl` cross-checks the same verdicts against
the consequence relation the provenance cites.

Scope, stated precisely: the emergent case is now **catalogue-attested and
machine-checked**, not only illustrated — but it is **not student-corpus
attested**. The compiled break was authored as a triple from the literature
catalogue, and the discovery sweep re-derives its emergence rather than
finding it in independent pairwise data. The registry (all pairs) cannot
attest emergence by construction. The other three triples stay in the
discovery layer with their witnesses; a caller records them into the
canonical relation explicitly via
`incompatibility_discovery:install_discovered_hyperedges/2`.

## Open lever

Cross-metaphor triples (incoherent only across two metaphors' commitments)
and a `c_*`-level joint-unsatisfiability checker are the two ways this search
could find something genuinely new. Both are judgment work, one candidate at
a time, and belong beside the catalogue before they are compiled.

---

Vendored into Hermes 2026-07-27 from `/Users/tio/Documents/GitHub/umedcta-formalization`.
Three modules cited this record and it had never been carried across, so the
provenance chain `formal/incompatibility/brandomian_incompatibility.pl` claims
for its incommensurability seed pointed at a file no reader could open.

The four code paths above were rewritten from the `arche-trace/` tree this
search ran against to their Hermes locations under `formal/incompatibility/`.
Only the paths changed; the findings, counts, and the disposition are the
record as written on 2026-07-02. That directory name is retired — the owner
now calls the boundary a vanishing point — and it survives here only as the
historical fact of where the code sat when the search ran.
