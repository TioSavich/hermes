# The 569 non-emergent sets: what the distribution is telling us

Date: 2026-07-27. Subject:
`formal/incompatibility/incompatibility_sets_discovered.pl` (Big Red iteration7
cache, 574 rows, harvested 2026-05-29), read against
`formal/incompatibility/defeasible_inference.pl` and
`formal/incompatibility/brandomian_incompatibility.pl`.

The question put to this analysis was whether the 569 non-emergent outcomes are
569 findings or 569 non-events. The short answer is that they are neither: they
are 17 facts transcribed 528 times, plus 44 registry pairs from a different
search, plus two toy fixtures. And the four emergent sets are not discoveries
either. They are the four break-points that were authored at arity 3, returned
once each.

## 1. The 574 are four searches, not one

The cache is keyed by discovery context, and the four kinds do not cross-cut the
contexts. They partition them.

| context | rows | kinds |
|---|---|---|
| `defeasible_inference` | 528 | 524 defeated, 4 emergent |
| `registry_neighborhood` | 44 | 44 incoherent |
| `finite_three_rule_program` | 1 | 1 incoherent |
| `finite_loop_program` | 1 | 1 nonterminating |

So the "45 incoherent (but not minimal)" bucket is not a minimality verdict at
all. It is 44 misconception-registry rows plus one toy fixture, from contexts
whose classifiers never run a minimality test. Of the 44 registry rows, 42 are
minimal pairs and 2 are triples containing an already-recorded pair. The
`incoherent` label records that `classify_scratch/4` returned
`incoherent(Witness)`, nothing more.

The registry context cannot produce an emergent set by construction. Its
incoherence predicate is `known_incompatible_pair_witness/2`: a set is incoherent
there iff it contains an incompatible *pair*. A set that contained no
incompatible pair would be classified coherent and never recorded.
`incompatibility_discovery.pl` states this limit in its own comment on
`candidate_set_core(registry_neighborhood, _)`.

Everything that follows concerns the 528 `defeasible_inference` rows, which are
the Lakoff-Núñez search.

## 2. The grid, reconstructed and checked

The cache records only outcomes of `incoherent(_)` or `nonterminating(_)`
(`discovered_outcome/1`). Coherent cells are computed and discarded. To answer
"were they ever candidates" the coherent branch has to be recovered, so I rebuilt
the iteration7 grid from the code and re-ran the classifier's semantics in
Python.

The iteration7 vocabulary is recoverable from the cache itself. Two atoms in the
current `compiled_break/2` table (`o(negative_product_demanded)`,
`o(irrational_destination_demanded)`) appear nowhere in the 574 rows, so their
two breaks postdate the harvest. That leaves:

- 12 `material_inference/3` rows (11 grounding metaphors + `commit_p_entitles_q`);
- 16 compiled breaks, 12 of arity 2 and 4 of arity 3;
- a defeater vocabulary of 31 atoms: 11 grounding commitments, 18 break triggers,
  `neg(o(p))`, `o(unrelated_control)`.

The grid is 12 inferences × (31 singletons + 465 pairs) = **5,952 cells**.

Re-running `classify_defeat/3`'s logic over that grid reproduces the cache
exactly: 528 non-coherent cells, the same sets, the same kinds, no row in one and
not the other, no kind disagreement. Every per-inference count matches (43, 43,
124, 69, 42×5, 13×3). The reconstruction is therefore sound enough to quote the
branch the cache does not carry:

**5,424 of 5,952 cells (91.1%) are coherent.** The inference survived; there was
no incompatibility to record.

## 3. "Defeated" is three things, and none of them is a near-miss

Sorting the 528 by what made the combined context incoherent:

| route | rows | share |
|---|---|---|
| a break uses the premise plus a defeater | 353 | 66.9% |
| a break sits wholly inside the defeater set; the premise is idle | 144 | 27.3% |
| structural negation pair (`o(p)` with `neg(o(p))`) | 31 | 5.9% |

The middle row is the one worth naming. 144 = 12 binary breaks × 12 inferences.
Every inference in the grid is crossed with every binary break, and whenever the
two conditions of a break both land in a defeater pair, the context is
incoherent regardless of which inference is being tested. The inference is a
bystander. Those 144 rows say nothing about the inference whose id they carry.

The 31 structural rows are the control atom `neg(o(p))` firing against the one
inference whose premise is `o(p)`: one singleton and 30 pairs, the same fact 31
times.

The remaining 349 defeated rows are the ones where the premise does work. Of
those, 12 are size-2 contexts (premise + the one trigger that completes a binary
break) and 337 are size-3 contexts where a second defeater rides along doing
nothing.

Passenger census over the 528:

| combined size | members removable while staying incoherent | kind | rows |
|---|---|---|---|
| 2 | 0 | defeated | 13 |
| 3 | 0 | emergent | 4 |
| 3 | 1 | defeated | 488 |
| 3 | 2 | defeated | 23 |

**511 of 528 (96.8%) contain a proper subset that is already incoherent.** 17 do
not. The 23 doubly-redundant rows are contexts where two authored breaks fire at
once.

The task asked for the split between "a proper subset is already incoherent" and
"the whole set is coherent, so there is no incompatibility at all". Over the full
grid: 5,424 coherent, 511 already-incoherent-below, 17 minimal. Restricted to
what the cache records, the second and third are 511 to 17.

The near-miss audit is the sharper result. Of the 511 arity-3 defeated sets,
**zero** fail minimality for any reason other than containing an authored break
of smaller arity. There is not one case in the grid where three commitments were
jointly unholdable and the one-element-removal check failed for a contingent
reason. Emergence was never nearly reached and then lost. It was reached exactly
where it was authored.

## 4. The distribution restates the break table

Which break did the work:

| break | rows |
|---|---|
| each of the 12 binary breaks | 42 |
| structural negation pair | 31 |
| each of the 4 arity-3 breaks | 1 |

Sum 539 against 528 rows, because 11 rows fire two breaks at once. So 528 rows
encode 16 authored breaks plus one structural law: **17 facts, about 31 rows
each.**

Atom frequency follows the same rule, with no residue. An atom's row count is
determined by how many breaks contain it:

- `o(zero_demanded)` and `o(irrational_demanded)` at 89 rows each — the only two
  triggers belonging to two breaks (object-collection and object-construction);
- `o(grounded(object_collection))` at 55 — the commitment with four breaks;
- `o(grounded(object_construction))`, `o(grounded(measuring_stick))` at 33 and 24
  — two breaks each;
- the eight atoms that occur only in an arity-3 break at 14 rows each, of which
  they are load-bearing in exactly **one**; passengers in the other 13;
- `o(unrelated_control)` at 13 rows, load-bearing in **zero**. The control behaves
  as a control should.

There is no clustering to report beyond break membership. No atom pair is
over-represented relative to what the break table predicts. The distribution
carries no information the 16 authored breaks do not already carry.

## 5. What distinguishes the four survivors

All four have the same structure, and it is checkable before running anything.

| inference | premise | the two defeaters | break |
|---|---|---|---|
| `measuring_stick_grounds_length` | `o(grounded(measuring_stick))` | `o(length_is_count_of_units)`, `o(diagonal_of_unit_square_measured)` | `measuring_stick_incommensurability` |
| `functions_are_ordered_pairs_grounds_functions` | `o(grounded(functions_are_sets_of_ordered_pairs))` | `o(two_rules_same_extension)`, `o(rules_conceptually_distinct)` | `ordered_pairs_rule_extension_collapse` |
| `spaces_are_point_sets_grounds_space` | `o(grounded(spaces_are_sets_of_points))` | `o(points_inherent_to_space)`, `o(space_constituted_by_points)` | `spaces_point_blend_inconsistency` |
| `cantors_metaphor_grounds_cardinality` | `o(grounded(cantors_metaphor))` | `o(everyday_same_number_comparison)`, `o(infinite_collection_compared)` | `cantor_same_number_reassignment` |

In every case the combined context is *identical* to the break's condition set.
The classifier is not composing anything. It is finding the arity-3 break that
was written down and reporting it once.

A candidate is classified emergent in this grid iff:

1. it is authored as a single break of arity 3;
2. one of its three conditions is the premise of a material inference (defeater
   sets are capped at size 2, so an arity-3 break can only fire for the inference
   whose premise supplies its third condition — which is why the three metaphors
   with no binary break record exactly 13 rows apiece);
3. its other two conditions are both in the defeater vocabulary, i.e. each occurs
   in some break;
4. no break of arity ≤ 2 sits inside the triple.

Condition 4 is the one that gets lost. Twelve arity-2 sets in this grid are
genuinely minimal — nothing smaller is incoherent — and all twelve are labelled
`defeated`, because `emergent_witness/4` requires `Len >= 3`. The kind labels do
not carve at minimality. They carve at minimality *and* arity ≥ 3. Anyone reading
"defeated" as "not minimal" reads it wrongly for 13 of the 528 rows.

The failure mode to design against is condition 4. If a content `P` carries both
an arity-2 break `{P, X}` and an arity-3 break `{P, C, D}`, then every pair
`{X, Y}` produces a defeated row with `Y` a passenger, and `P` contributes
crosstalk proportional to the vocabulary size while still yielding at most one
emergent set.

## 6. Lakoff-Núñez is not doing the work, and the repo already holds the proof

The concentration is real: 40 of the 43 names in the iteration7 search are
Lakoff-Núñez derived, and the three that are not (`commit_p_entitles_q`,
`neg(o(p))`, `o(unrelated_control)`) behave exactly as scaffolding.
`o(unrelated_control)` is load-bearing in none of its 13 rows.
`neg(o(p))` is load-bearing in 31 of 43, all against the one inference with
`o(p)` as premise, and what it demonstrates is the law of non-contradiction, not
a material incompatibility. `commit_p_entitles_q` records 43 rows, 31 structural
and 12 crosstalk, and contributes no emergent set.

So within iteration7 the answer looks like "only Lakoff-Núñez was ever in the
relation". But that is a fact about the vocabulary the search was given, not
about the genre. The mechanism that produced the four is arity-3 authorship with
no smaller break inside, and nothing in it is metaphor-specific.

`formal/incompatibility/incompatibility_sets_error_rules.pl`, generated locally
on 2026-07-27 from the fraction-comparison slice of
`data/research/incompatibility_triples.json`, already carries the counter-case.
Its 225 rows are **15 emergent and 210 defeated**, and not one of the 15 emergent
sets is Lakoff-Núñez. Every one has the shape

```
{ s(comp_nec(rule(R))),                    % the student rule
  o(licensed_consequence(L)),              % what the rule licenses
  o(context(K)) }                          % the input class where L diverges
```

all 15 of 15, with no proper subset of any of them a break. Each pair is
holdable on its own: the rule without having drawn the conclusion; the rule
without the awkward input class; the conclusion without commitment to the rule.
Only the three together fail.

The yield contrast is worth stating plainly. Twelve Lakoff-Núñez inferences
produced 4 emergent sets. Fifteen coded student rules produced 15. The
Lakoff-Núñez catalogue is not the source of emergence; it is a catalogue in which
most break-points happen to have been written at arity 2.

The crosstalk finding transfers exactly. All 210 defeated rows in the error-rule
cache are a binary Lakoff-Núñez break firing wholly inside the defeater pair with
the fraction rule idle — 210 = 15 rules × 14 binary breaks, verified row by row.
Not one of the 210 says anything about fractions. The error-rule grid is 15 ×
2,926 = 43,890 cells, of which 43,665 (99.49%) are coherent.

The reason the fraction rules produce no non-crosstalk defeats is condition 4
holding perfectly: no fraction-rule premise occurs in any binary break, so no
binary break can consume it, and the rule's only incoherence is its own triple.

## 7. Specification for the coding work

For whoever is filling `student_rule` / `valid_domain` / `incompatible_with`:

- Code the triple, not the pair. A rule with an empty `valid_domain` is
  incompatible with the sanctioned operation outright, which is an arity-2 fact,
  and arity-2 facts are excluded from `emergent` by the `Len >= 3` guard
  regardless of how minimal they are. The generator header in
  `error_rule_inferences.pl` records the same exclusion from the other side:
  rows coded `none_found` contribute nothing, because a rule valid nowhere yields
  a pair.
- The three parts are the rule, what it licenses, and the class where what it
  licenses diverges. `valid_domain` earns its place by making the second pair
  holdable: if the rule were wrong everywhere, rule-plus-conclusion would already
  be incoherent and the third member would be a passenger.
- Do not also give the rule a binary break. Every arity-2 break on the same
  content converts that content's whole neighbourhood into defeated rows with
  passengers.
- Expect a defeated:emergent ratio around 14:1 per rule from vocabulary crosstalk
  alone, and read none of it as a finding. The count that matters is the number
  of distinct authored triples the search returns, not the number of rows.

## 8. Limits

- The 5,424 coherent cells and the 5,952 grid size are my reconstruction, not
  numbers the Big Red run reported. They rest on the reconstruction reproducing
  all 528 recorded rows exactly, set for set and kind for kind. I did not run
  SWI-Prolog for this (an Atlas sweep holds the interpreter); the check is a
  Python re-implementation of `classify_defeat_witness/4`,
  `ctx_incoherent_witness/2` and `incoherent_base_witness/2` against the cache as
  ground truth.
- `sequent_engine:incoherent_witness/2` has two further clauses
  (`axiom_incoherence_witness/2` and `proves(Context => [])`) that the Python
  model does not carry. Neither fires on any of the 528 rows, since the
  reconstruction matches exactly; whether either could fire on some of the 5,424
  coherent cells is unchecked, so the coherent count is an upper bound in
  principle.
- `emergent_witness/4` proves minimality by one-element removal. At combined size
  3 that is full minimality, because `ctx_incoherent/1` has contains-semantics
  and is therefore monotone, so an incoherent singleton would make its
  size-2 superset incoherent too. For larger contexts one-element removal is
  weaker than minimality; the grid never produces one.
- `brandomian_incompatibility.pl` cites
  `docs/research/2026-07-02-emergent-hyperedge-search.md` for the search method.
  That file is not in the tree as of this reading.
- `incompatibility_entailment_order.pl` was regenerated while this analysis ran.
  As I read it, `incompatibility_order_count/2` records 803 declared input
  hyperedges, 418 minimal hyperedges, 174 contents, 21 earned entailments, 692
  vacuous, 9 equivalent, and `incompatibility_discovered_kind_count/2` records
  734 defeated / 19 emergent / 45 incoherent / 1 nonterminating across both
  caches. Those differ from the baseline figures this analysis was briefed with
  (512 vacuous, 129 contents, 193 minimal hyperedges), which describe an earlier
  state of the same generated file. Anyone using the register as a baseline
  should regenerate and re-read rather than quote either set.
