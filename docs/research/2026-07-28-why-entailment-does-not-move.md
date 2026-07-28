# Why earned entailment does not move

Date: 2026-07-28. Subject: the finite incompatibility-entailment register
(`formal/incompatibility/incompatibility_entailment_order.pl`, regenerated and
independently recomputed today) read against the error-rule cache
(`formal/incompatibility/incompatibility_sets_error_rules.pl`), the canonical
relation (`formal/incompatibility/brandomian_incompatibility.pl`), and the two
prior analyses (`2026-07-27-what-the-569-non-emergent-sets-show.md`,
`2026-07-27-no-saying-vocabularies-and-incompatibility.md` §5).

The question: three corpus expansions moved emergent hyperedges from 4 to 94
and moved earned strict entailment not at all (21, 21, 21). Why, whether the
hypothesis offered for it survives, whether earned entailment is the right
target for this corpus, and what would move it honestly if anything should.

The short answer, stated up front: under the current encoding the corpus
**provably cannot** earn an entailment, no matter how many triples are coded,
because every triple carries two atoms private to itself and the replacement
semantics needs exact recurrence of partner *pairs*, not shared atoms. The
offered hypothesis survives in its diagnosis and fails in its mechanism. The
deeper finding is that the coding spec that maximizes emergence and the
structure that earns entailment pull in opposite directions, so the twentyfold
emergence rise beside a flat earned count is not a shortfall — it is the trade
the spec made, and made correctly for its purpose. Earned entailment is the
wrong target for this corpus at its current one-fact-per-content depth; the
relations it actually populates are named in §5, and the two honest routes to
earned entailment, if wanted, are in §7.

## 0. The numbers, regenerated

Every figure in this report was produced today unless marked otherwise.

`python3 scripts/extract_incompatibility_entailment_order.py --check`:

```
incompatibility entailment register current: hyperedges=668; minimal=283;
contents=385; earned=21; vacuous=1536; equivalent=9; wall_seconds=4.919
```

The register's own count facts agree: 668 declared input hyperedges, 283
minimal, 385 contents, 21 earned, 1,536 vacuous, 9 equivalent, 0
mutual-nonidentical; discovered kinds 524 defeated / 94 emergent / 45
incoherent / 1 nonterminating; 94 `incompatibility_emergent_hyperedge/1` rows.
The briefing's "90 emergent after decimals" counts the error-rule cache alone;
94 is that plus the 4 iteration7 emergents.

The error-rule cache, measured directly: **90 triples; 90 distinct
`inference(...)` atoms, each occurring in exactly one triple; 90 distinct
`o(licensed_consequence(...))` atoms, none shared; 76 distinct
`o(context(...))` atoms, 8 of them shared by two to four rules, covering 22
triples.** The shared contexts are the shared-divergence-context work landing
as designed.

Independent recomputation: I parsed `input_hyperedge/4` with my own reader and
re-ran the replacement test over all 385 × 384 ordered pairs, without reusing
any of the generator's code. Result: exactly the same 21 earned pairs, the
same 9 equivalent pairs, the same 4 empty-profile contents
(`o(grounded(cantors_metaphor))`, `o(grounded(functions_are_sets_of_ordered_pairs))`,
`o(grounded(spaces_are_sets_of_points))`, `o(unrelated_control)`; 1,536 = 4 ×
384). **Zero of the 21 earned pairs and zero of the 9 equivalent pairs involve
any of the 256 error-rule terms. The error-rule edges share zero vocabulary
with every other edge in the relation.** Of the 256 error-rule terms, 248 sit
in exactly one minimal edge; the other 8 (the shared contexts) sit in two to
four.

The emergent-hyperedge search (`swipl -q -l paths.pl -s
formal/incompatibility/find_emergent_hyperedges.pl -g run_search -t halt`) was
launched and was still in its live sweep (single process, full CPU, output
buffered) when this report was written; its printed report is not quoted here.
The count it re-checks was confirmed directly against its inputs instead:
`discovered_set_kind(..., emergent)` rows number 4 in
`incompatibility_sets_discovered.pl` and 90 in
`incompatibility_sets_error_rules.pl`, agreeing with the register. Nothing
below depends on the sweep: the emergent identity across the crosstalk
collapse is hash-attested in the briefing, and the register recomputation
above is the load-bearing check for every claim this report makes about the
order.

## 1. What earning requires under this relation

At the level of the relation, not the code. `incompatibility_entails(A, B)`
holds when B has at least one declared incompatible set and, for every such
set S, replacing B by A in S leaves an incoherent set. Incoherence is
containment of a declared set. So the condition decomposes: for every minimal
edge S containing B, the set (S − {B}) ∪ {A} must contain some declared edge
E. If E does not contain A, then E ⊆ S − {B}, contradicting S's minimality.
So E contains A, and the condition becomes:

> **Absorption.** For every partner-context of B (each S − {B}), there must be
> a declared edge through A whose *other members all sit inside that
> partner-context*. Call E − {A} the absorbing remainder.

Earned (strict) entailment is absorption one way and its failure the other
way. Two consequences of the absorption form settle everything that follows:

- **With arity-2 edges, the absorbing remainder is one atom.** A single shared
  partner suffices. The dog/mammal fixture is all arity-2: `{mammal, feline}`
  punctured at `mammal` leaves `{feline}`, and `{dog, feline}` absorbs it
  because the one atom `feline` is shared; `{dog, cold_blooded}` supplies the
  strictness, because `{mammal, cold_blooded}` is not declared. What does the
  work is not that dog is incompatible with *many* things — it is that dog's
  edges and mammal's edges share partner atoms, with an asymmetry.
- **With uniform arity-3 edges, the absorbing remainder is a pair, and a pair
  sits inside a two-element partner-context only by being equal to it.** So in
  a triples-only corpus, A earns B exactly when B's family of remainder pairs
  is properly contained in A's family of remainder pairs: exact pair
  recurrence across edges. Sharing one atom of a pair absorbs nothing.

## 2. Why this corpus cannot earn: the private pair

Every error-rule triple has the shape

```
{ inference(rule_R_licenses_L), o(licensed_consequence(L)), o(context(K)) }
```

and carries **two atoms that occur in no other edge in the entire relation**:
the inference atom (the fused `rule_R_licenses_L` name is per-triple by
construction, 90 of 90 measured) and the licensed-consequence atom (90 of 90
distinct, measured). Run the absorption condition through that structure:

- **A rule atom** has a one-edge profile. Its single remainder pair
  `{o(licensed_consequence(L)), o(context(K))}` contains the private
  consequence atom, so no other edge's remainder can equal it: the rule can
  absorb nothing and nothing can absorb it. It can neither earn, nor be
  earned, nor even be equivalent to anything.
- **A shared context atom** has a profile of up to four edges, and each of its
  remainder pairs `{inference_i, consequence_i}` is a private pair of a
  different rule — pairwise disjoint. To be earned, some A would need an
  absorbing remainder inside *each* of several disjoint pairs, which no single
  remainder can manage; with a one-edge profile it would need the edge
  `{A, inference_i, consequence_i}` to be declared, and no edge carries two
  rules' atoms. To earn something, the context's own remainders would have to
  absorb a target's remainders, and they are private pairs absorbable only by
  their own edge.
- **A consequence atom** mirrors the rule atom.

So: zero earned, zero equivalent, among all 256 error-rule terms — which is
what the recomputation measures — and the zero is **invariant under corpus
growth**, because every further triple coded under this encoding brings its
own private pair. Aggregation is not the lever. Neither was the
shared-divergence-context design, *for this target*: sharing one atom of a
two-atom remainder is not absorption. What the shared contexts did move is
real and is named in §5.

Two closures on the argument. Cross-cache absorption is also unavailable: the
error-rule edges share zero terms with the iteration7 cache, the registry
pairs, and the seeds (measured). And the crosstalk collapse cost nothing on
this front: the retained-crosstalk fraction state also earned 21 (briefing
table), which the private-pair argument predicts — a crosstalk row
`{inference(rule...), X, Y}` gives the rule atom extra edges, but the rule's
*own* triple still contains its private pair, and absorption must succeed on
every edge of the target, so the own-triple always blocks it.

## 3. The hypothesis, tested

The offered hypothesis: every coded triple has the shape
`{s(comp_nec(rule(R))), o(licensed_consequence(C)), o(context(K))}`, each rule
occurs in exactly one such set, a content's profile is essentially its own
triple's remainder, and containment between profiles then requires sharing a
set, which yields equivalence rather than strict entailment.

Verdict: **the diagnosis survives; the mechanism does not; the shape claim is
out of date.**

- *Shape.* The triples reach the relation as `inference(rule_R_licenses_L)`
  plus two `o(...)` terms. The `s(comp_nec(rule(R)))` wrapper of the §5 spec
  was replaced by the fused inference name at generation. For the entailment
  argument this is cosmetic; for the vocabulary-join question (§6) it is
  load-bearing.
- *"Each rule occurs in exactly one set"* — measured true, 90 of 90, and it
  correctly identifies why rule atoms cannot participate: a singleton
  remainder family can sit inside another only by equality.
- *"Containment requires sharing a set, which yields equivalence rather than
  strict entailment"* — not the general mechanism. At uniform arity 3, proper
  containment of remainder *families* yields strict entailment with no
  equivalence: a rule with remainders {r1, r2} strictly earns a rule with
  remainder {r1}. What forbids even that here is the private consequence
  atom, which makes remainder equality itself impossible across rules — so
  the corpus does not collapse into equivalence; it collapses into *nothing*.
  Zero equivalences among the 256 terms is the measured form of that
  distinction, and it matters for the remedy: the hypothesis's mechanism
  suggests de-duplicating sets; the actual mechanism requires sharing
  remainder pairs (§7, route 2).
- *"One hyperedge per rule makes nesting structurally impossible no matter how
  many rules are coded"* — true as stated for rule atoms, with the sharpening
  that even multiple hyperedges per rule would change nothing while each edge
  keeps a private consequence atom.
- *Dog/mammal* — right structure, wrong emphasis. The nesting is carried by
  shared partner atoms in arity-2 edges, not by the size of dog's
  incompatibility range. A corpus of ten thousand triples with private pairs
  has an enormous incompatibility range and no nesting anywhere.

## 4. Where the 21 earned pairs come from, and what they warn about

The 21 decompose (measured): 9 `inference(...)` → `o(...)` and 5 `o(...)` →
`o(...)` and 1 `inference` → `inference` from the iteration7 cache; 5 bare →
bare from the registry pairs and the seed lattice; 1 `strategy` → `strategy`.
Every one rides on dense atom reuse, and reading them closely is instructive
about what "moving the number" would actually buy.

The iteration7 earned pairs ride on the grid's crosstalk. Example, checked
against the register: `o(grounded(measuring_stick))` has 12 minimal edges, 11
of them crosstalk rows `{inference(I), o(grounded(measuring_stick)),
o(negative_demanded)}` for eleven different inferences I. Replacing the
grounding commitment by `inference(measuring_stick_grounds_length)` stays
incoherent because the size-2 row `{inference(measuring_stick_grounds_length),
o(negative_demanded)}` absorbs each of them — a one-atom absorbing remainder,
available only because the cache holds mixed-arity rows and reuses
`o(negative_demanded)` across dozens of edges. The rows that the 569-analysis
classified as saying nothing about their inference are the rows carrying most
of the register's earned entailments. The crosstalk collapse applied to the
error-rule cache removed exactly this row type — and, per §2, removed nothing
that could have earned there anyway.

The registry and seed earned pairs are sparseness artifacts, present in the
register today:

- `incompatibility_earned_entails(even, composite, 1)` — materially false (2
  is even and not composite). It holds because `composite`'s only declared
  incompatibility is `prime_greater_than_2`, which `even` shares, and `even`
  holds one extra edge. This is the too-strong entailment the module comment
  says sparse data yields, sitting in the current artifact.
- `add_instead_of_subtract_column`, `borrow_without_reducing_bases`, and
  `smaller_from_larger_in_column` — three materially distinct subtraction
  misconceptions — are pairwise **equivalent** in the register, because each
  has the identical singleton profile `{strategy(subtraction,
  decompose_base_for_ones)}`. `borrow_across_zero_no_cascade` strictly earns
  all three by holding one extra edge.

The warning: under this relation, thin shared vocabulary manufactures earned
pairs *before* it manufactures true ones. A push that moved the 90 toward
earned by light atom-sharing would first mint pairs of the `even ⊨ composite`
kind. The corpus's zero is the honest value of a corpus whose per-content
incompatibility data is one fact deep — and the register's guards (the
vacuous class, the positive control) are doing their job around it.

## 5. Is earned entailment the right target for this corpus?

Steelman for keeping it: incompatibility entailment is the discriminating
relation, the one Brandom reconstructs consequence from, and a register that
never earns from its newest corpus could be hiding a defect. Rebuttal: the
generator carries a hand-worked dog/mammal positive control, the register
earns 21 pairs from its other corpora, and §2 upgrades the zero from an
observation to a structural proof. The defect worry is discharged; what
remains is a category question, and the answer is that the target is wrong
for this data at this depth.

The triples encode a defeasibility structure: a rule, what it licenses, and
the context where the licence fails. Each is a fact about **one inference's
boundary** — determinate negation in the viability register, valid-somewhere
and defeated-there, which is what the coding rulings asked for. Entailment is
a relation **between contents**, and it becomes measurable only where contents
share incompatibility vocabulary several facts deep. One triple per rule
cannot found an order, and is not defective for that.

And there is a sharper way to put it, which I take to be the finding of this
report: **the coding spec that maximizes emergence and the structure that
earns entailment are in tension.** The 569-analysis's spec — code the triple,
not the pair; give the rule no binary break; keep every edge minimal at arity
3 — is exactly what guarantees private pairs and uniform arity, and §1-§2 say
those are exactly what foreclose absorption. Emergence wants each new edge
minimal and self-standing; earning wants mixed arity and dense partner reuse.
The corpus moved twentyfold on one axis and not at all on the other because
the two axes cannot be climbed by the same coding act under this encoding.
That is a boundary worth recording as a vanishing point: the place where this
formalization honestly stops, and where what stops it is the depth of the
declared data, not the relation or the corpus.

What the corpus does populate, in the repo's own vocabulary:

- **`minimal_incompatible_set/1` and the emergent classification** — 90
  machine-checked minimal triples, each carrying its community-sanctioned
  warrant through `error_rule_warrant/2`. This is a determinate-negation
  catalogue, and it is the result the three expansions actually built.
- **`incompatibility_profile/2` on the shared contexts** — the hub structure.
  `o(context(the_divisor_is_not_a_whole_number))` sits in four rules' triples;
  eight contexts sit in two to four each. A context that defeats four distinct
  student rules at once is a cross-rule finding that entailment cannot state,
  and pedagogically it is the high-leverage counterexample class: one input
  family that confronts four rules. This is what the shared-divergence-context
  work earned, and it is worth surfacing as its own result rather than
  mourning as a failed entailment lever.
- **`brandomian_neg/2` on a rule atom** — returns exactly the rule's
  {licence, divergence-context} partner set: the negation of the rule as its
  minimal incompatible, per-rule, concrete, viability-shaped rather than
  deficit-shaped.

## 6. The owner's PML hypothesis: single-realm projection and the libertine framework

The hypothesis, verbatim: "We might also not see entailments unless pml is
projected down into one realm instead of 3 (s, o, n). It's a libertine
framework on incompatibility."

Measured, over the current register:

- The register is **already single-realm**. Its 385 contents are 196 `o(...)`,
  102 `inference(...)`, 51 bare atoms, 35 `strategy(...)`, 1 `result_of(...)`
  — and zero `s(...)`, zero `n(...)`. (A parallel census that lumped the last
  three classes as 87 bare atoms agrees.)
- Cross-wrapper earning is not blocked: 9 of the 21 earned pairs cross from
  `inference(...)` to `o(...)`.

So the tripartition is not the mechanism. The projection into one realm has
already happened — silently, at generation — and earned did not move; and
wrapper heterogeneity does not obstruct absorption, because absorption is
atom-equality-wise, not realm-wise. If the hypothesis were the mechanism, the
projected register should have earned.

But the intuition behind "libertine" survives the failure of the mechanism,
in a form worth stating precisely. PML as this repository uses it is one cell
deep: my census over the Prolog tree counts 1,962 of 2,137 mode-operator
occurrences in `s(comp_nec(...))`, 122 in `s(exp_poss(...))`, every other
cell at 12 or fewer, with `o(comp_poss(...))` and `o(exp_poss(...))`
unoccupied. All 820 facts of `knowledge/misconceptions/pml_wire.pl` carry the
identical signature `s(comp_nec(unlicensed(_)))` (820 of 820, measured). And
the incompatibility engine, by its own module contract, treats mode-wrapped
atoms as opaque ground terms. Put those together: PML's cells classify how a
content is held; they impose no exclusions; and incompatibility semantics
runs on exclusions alone. The framework is libertine in exactly that sense —
it multiplies names without adding incompatibilities — and a sorting that
adds no exclusions can neither create nor block entailment. The S/O/N
distinction does no work inside this relation, and it was discarded precisely
at the door: the S-wrapper was projected away into the fused inference name,
and the N-mode content (the named community's sanction, the
`incompatible_with` column) was deliberately routed to edge provenance
(`error_rule_warrant/2`) rather than into the sets, to keep the triples
minimal. That was the right call for emergence, and it should be said plainly
in the register's documentation: the modes are load-bearing for the project's
reading of discourse and inert for this relation. If mode were ever to do
work here it would have to arrive as data — mode-bridging incompatibility
facts — which is a coding decision, not a projection.

The silent projection does leave a defect, just not an entailment defect. The
repository now holds two vocabularies over what are plausibly the same
referents with not one shared term: `pml_wire.pl` says
`s(comp_nec(unlicensed(smaller_from_larger_columnwise)))` while the register
carries the registry atom `smaller_from_larger_in_column` — near-identical
names, presumably one misconception, no join (co-reference would need the
registry row's provenance to confirm; I did not chase it). `pml_wire.pl`
feeds no hyperedges — it is not among the canonical relation's feeders, and
`unlicensed(` occurs nowhere under `formal/` — so joining it would add no
edges and move earned by nothing. The two vocabularies also answer different
questions: the wire records a deontic status (this commitment lacks a
licence — one-place, deficit-form, the arity finding of the no-saying
analysis), while the triple records semantic content (where the licence holds
and where it fails — viability-form). A merge of their *claims* would be
wrong. A join at the *referent* — one rule atom, two annotations — is the
union the subtraction ethic asks for, and its absence is the same
two-names-one-referent defect shape this repository has been curing all week.
It should be scored as a wiring deliverable, on the retrieval and aggregation
side, and never sold as an entailment fix.

## 7. What would move earned honestly, ranked

Beyond this point I am reasoning from the semantics against the measured
structure; none of these has been run.

**1. Context-taxonomy closure (a-fortiori edges).** The corpus already
contains materially nested context classes:
`o(context(the_divisor_lies_between_zero_and_one))` refines
`o(context(the_divisor_is_not_a_whole_number))` (a divisor in (0,1) is not a
whole number; two rules native to the narrow class, four to the broad), and
`o(context(the_expansion_repeats_periodically))` refines
`o(context(the_expansion_does_not_terminate))` (one rule against three; the
coder's reading must exclude eventually-zero repetends, a judgment call to
record). A rule defeated on a class is defeated on its subclasses, so the
closure triples `{inference_i, consequence_i, K_narrow}` are materially
sound; declaring them makes the narrow context strictly earn the broad one
under the replacement semantics — checked by hand: every broad-context edge
survives the narrow replacement via its closure triple, and the reverse fails
on the narrow context's native rules, which do not fail on the broad class.
These earned pairs would be materially true content entailments (the
dog/mammal structure in the corpus's own material), each with witness counts.
Two grades: an authored taxonomy (a handful of subclass judgments among 76
contexts, a small generator change; every judgment needs the same receipt
discipline as the codings, because a wrong subclass claim becomes a wrong
entailment), or automaton-certified nesting where the context atom is already
computed (`gap_viability/3` in
`knowledge/strategies/math/smr_frac_benchmark_compare.pl` and its siblings):
run the automata over a shared input battery and emit closure only where one
condition's satisfying inputs are contained in another's. Cost: an input
battery, a small driver, and reach limited to automata-backed contexts. What
it settles: earned entailment becomes a measurement of the context taxonomy —
the register would earn exactly as many entailments as the taxonomy has true
nestings, which is a claim worth having.

**2. Licence normalization plus multiple divergence contexts per rule.**
Unfuse the private pair: let distinct rules that license the same content
share one consequence atom (the corpus has candidates — three near-duplicate
licences around written-numeral order against decimal value — and the family
consolidation in `data/research/incompatibility_triples.json` already merged
203 codings into 90 families, so the union discipline exists), and code each
rule's several divergence contexts as separate triples. Then rule-to-rule
earning becomes possible exactly when one rule diverges everywhere another
does on a shared licence: an interpretable commitment order among student
rules (holding the cruder rule carries every incompatibility the finer rule
carries). Cost: a re-coding pass over the codings, reviewer judgment on which
licences are one content, regeneration — and an audit obligation, because §4
predicts the first earned pairs from thin sharing will be `even ⊨ composite`
-shaped. What it settles: whether any two coded rules stand in a real strict
order. The answer may be that none do, and that is reportable.

**3. Re-aim the deliverable; change no encoding.** Surface what the corpus
already earns — the 90 warranted minimal triples, the context-hub profile
(eight contexts, two to four rules deep), per-rule `brandomian_neg/2` — and
record in the register's module comment and the research docs that earned
entailment is structurally out of reach of one-triple-per-rule coding, with
§2's argument as the receipt. Cost: prose, and possibly a small surfacing of
profiles in the entailment view. What it settles: the next session does not
pull the aggregation lever again, and the flat 21 stops reading as a stall.

Not routes: more aggregation (proven no-op, §2); more shared contexts alone
(no-op for earned, real for hubs); giving rules binary breaks to create mixed
arity (the 569-analysis already established this floods the cache with
crosstalk and caps emergence — it would trade the earned result for the
emergent one, which is the tension of §5, not a resolution of it); joining
`pml_wire` to move entailment (adds no edges, §6).

My ranking is 3 first as the immediate act (it is cheap and stops a
recurring misdirection), 1 as the funded next step (it is the one route whose
earned pairs are true by the same warrant discipline the corpus already
keeps), 2 only if the rule-order question itself becomes a research target.

## 8. Limits

- Every count here was regenerated today from the tracked artifacts; the
  independent recomputation reproduced the generator's relation exactly, which
  is the check the report rests on. The two historical states in the briefing
  table (21 earned at baseline and after fractions) are briefing-attested; I
  verified only the current state and the structural argument that predicts
  all three.
- The emergent-hyperedge search was still running, single-threaded at full
  CPU with buffered output, when this report was finalized; its printed
  report is not quoted. No claim above depends on it.
- The impossibility argument of §2 is a proof about the current encoding of
  the declared corpus, and it quantifies over declared edges only — like the
  relation itself, it is exactly as strong as the closed world it ranges
  over. New edge shapes (closure triples, shared licences, mixed arity) void
  it by design; §7 is that observation made into options.
- Material-truth judgments in this report (`even ⊨ composite` false; the two
  context nestings true; the three subtraction misconceptions distinct) are
  mine and checkable, but they are human judgments; the register asserts none
  of them.
- The PML cell census spans `.pl` files in this checkout and counts textual
  occurrences, not loaded clauses; a census with different scope put the
  dominant cell at 1,782 of 1,957 with the same shape. The
  `smaller_from_larger` co-reference in §6 is flagged as plausible, not
  confirmed.
