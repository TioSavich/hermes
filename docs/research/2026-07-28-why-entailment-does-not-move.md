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
structure; none of these has been run. (Later the same day, route 1 ran; §9.1
records what it did.)

**1. Context-taxonomy closure (a-fortiori edges).** *(Run later the same
day; §9.1.)* The corpus already
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

## 9. Addendum, later the same day: the closure ran, the control was false, and the vanishing point has a literature and a scope

§0–§8 stand as written this morning. Three things happened after: route 1 of
§7 ran and the count moved; the positive control turned out to rest on a
materially false declared set and was corrected; and the owner asked how the
boundary the morning report named stands to fixed points and diagonalization
— including the Robinson arithmetic and Gödel-numbering utilities this corpus
itself carries, and Cantor's diagonal read as an act of objectivation — to
Gaifman on self-reference, and to Carspecken on discourse that turns meta.
Each claim below is tagged measured (checked against the live tree today),
read (from a named text), or conjectured (and whose conjecture it is).

### 9.1 Route 1 ran: 21 → 25 (measured)

Commit dff031d declares the a-fortiori context closure: 11 closure triples in
`formal/incompatibility/incompatibility_sets_a_fortiori_context_closure.pl`,
generated by `scripts/extract_a_fortiori_context_closure.py` from four
reviewed nestings in
`formal/incompatibility/a_fortiori_context_nestings.json`. Declared input
hyperedges went 668 → 679; the 90 coded triples are untouched. Earned strict
entailment moved for the first time in the register's history, 21 → 25, and
the four new pairs are exactly the four nestings, with witness counts:

- `the_divisor_lies_between_zero_and_one` ⊨ `the_divisor_is_not_a_whole_number` (4)
- `the_expansion_repeats_nines_without_end` ⊨ `the_expansion_repeats_periodically` (4)
- `the_expansion_repeats_nines_without_end` ⊨ `the_expansion_does_not_terminate` (3)
- `the_expansion_repeats_periodically` ⊨ `the_expansion_does_not_terminate` (3)

Three of the four form a chain §7 did not promise: repeating nines is
periodic, and periodic is non-terminating. The receipt discipline §7 asked for
is present in the artifacts: every nesting row carries a warrant and a basis
(`arithmetic_interval_exclusion`, `decimal_expansion_definition`), and the
automaton battery
(`scripts/checks/a_fortiori_context_closure_automaton_battery.pl`) proves a
boundary rather than a blessing — it runs the loaded comparison automata on
hand-worked coinciding and diverging inputs, then proves that those automata
decide *neither endpoint of any shipped nesting*, so no closure warrant is
upgraded to an automaton certificate. One name-plausible nesting was refused
at review: `the_divisor_is_not_ten` and `the_divisor_is_not_a_whole_number`
nest in neither direction (commit-attested; the nestings file carries asserted
rows only, so the refusal lives in the commit account).

The register also now marks support:
`incompatibility_earned_entailment_support/3` tags 19 earned pairs
`multi_profile_witness` and 6 `sparse_witness` (measured; the commit message
says 5, the artifact says 6). `even ⊨ composite` is computed, kept, and tagged
`sparse_witness`: the register can mark structural thinness from inside. What
it cannot mark is falsity, which is §9.3's subject.

What this settles about the morning argument: the count moved the first time
a new *shape* of declared set arrived, and never for any quantity of
same-shape coding. §2's impossibility proof and §7's ranking are discharged in
the direction they predicted.

### 9.2 The control was false, and the correction sharpened the finding (measured)

The fixture in `scripts/extract_incompatibility_entailment_order.py` declared
`{mammal, feline}` — materially false, since a cat is both. So until today the
register's positive control derived a true conclusion (dog entails mammal)
partly from a false declared set, while its seeds derive a false conclusion
(`even ⊨ composite`) from three true ones — and the relation registered
"passed" and "earned" alike. The corrected fixture — `{dog, feline}`,
`{dog, cold_blooded}`, `{mammal, cold_blooded}` — declares three true sets,
keeps the same structure (shared partner `cold_blooded`; `feline` incompatible
with dog alone, since a cat is a mammal), and the control passes identically;
the register is byte-unchanged.

The correction strengthens the isomorphism observation of the HTML report
rather than retiring it. Fixture and seeds remain isomorphic label for label
(dog↔even, mammal↔composite, cold_blooded↔prime_greater_than_2, feline↔odd),
and the comparison is now clean: identical structure, one side materially
adequate, the other not. Where the falsity of `even ⊨ composite` sits is
exactly localizable: what is missing is a declared content that excludes
composite without excluding even — prime, with 2 included. The corpus declares
only `prime_greater_than_2`. The falsity is incompleteness of the declared
incompatibilities: not an error in any declared set (all three are true), and
not a defect in the algorithm (the control passes and should).

### 9.3 Fixed points and diagonalization: the resemblance, located at its scope

Is the relation's inability to distinguish its control from its embarrassment
a fixed-point or diagonal phenomenon? No — and saying no accurately requires
saying it at two scopes, because the corpus is far richer than the register,
and the tree itself records the riches. "The register" throughout this
subsection means the canonical relation (`brandomian_incompatibility.pl`)
together with the extracted entailment order: declared hyperedges over opaque
ground contents, and everything computed from them. Nothing below is a claim
about the corpus's arithmetic; that scope gets its own verdict.

**The register scope.** The blindness has a one-line mechanism. Every
predicate the register computes — incoherence, minimality, earned entailment,
equivalence, support — is invariant under relabeling of contents: a bijection
of content names carries declared sets to declared sets and therefore earned
pairs to earned pairs. Material adequacy is not invariant: the fixture and
the seeds are related by exactly such a relabeling, and one is adequate where
the other is not. So no computation the register can run separates them. Call
this the invariance argument; it takes five lines and uses no self-reference.

Diagonalization is the opposite pole, and the register sits below it. The
diagonal lemma manufactures a sentence that speaks of itself; a system rich
enough to do that fails at self-certification because it can pose the
question. The register fails because it cannot: contents are opaque ground
terms; no content denotes a set, an edge, the relation, or the register; and
nothing would break if a content named `the_register_itself` were coded — one
more opaque atom, with no interpretation to force it to mean the register.
The precise form of the poverty: the register's contents are structureless
labels, freely permutable, so every relabeling transports the whole register
onto an isomorphic one and every verdict rides along. Arithmetic's terms are
the opposite case — a numeral is a built term, S...S(0), and Q proves every
pair of distinct numerals distinct, so their identities are fixed by
structure the register's atoms lack. That theorematic individuation is
exactly the rigidity Gödel numbering spends. At this scope the owner's
"cannot appear inside its own enumeration" holds as a category fact, not a
theorem: not proved by a diagonal, just unposable.

**The corpus scope.** The owner pressed here — "the prolog code has robinson
arithmetic and godel numbering, so I am likely misinterpreting 'this
register'" — and his hedge was too generous: he was not misinterpreting. The
corpus is not too poor, and the tree says so in its own artifacts (the first
three measured against this tree; the fourth read in the archive):

- `formal/formalization/robinson_q.pl` and `formal/formalization/axioms_robinson.pl`
  carry Robinson Arithmetic instance-wise — Q1–Q7 derivable for concrete
  numerals, the pack include-compiled into the sequent engine and enabled by
  default — under the module's own claim that Q is "the minimal system to
  which Goedel's First Incompleteness Theorem applies." That claim is right
  about Q the theory.
- `formal/sequent/automata.pl` keeps prime utilities under the heading "for
  Gödel Numbering and Formal Analysis" (`is_prime/1`, `nth_prime/2`), and the
  crosswalk family `cw_godel_primes` unifies them with
  `sequent_engine:product_of_list/2` behind a live probe.
- The number-theory pack runs Euclid's construction as an incoherence frame —
  its header: "the claim to completeness defeats itself through construction"
  — with a machine-checked witness whose reason field reads
  `prime_equal_to_product_plus_one_cannot_be_one_of_the_product_factors`, and
  the learner holds a learned strategy keyed to `n(is_complete(A))` that
  introduces the Euclid number. The corpus already executes one
  escape-from-a-claimed-complete-enumeration construction.
- The formalization archive this code was ported from has posed the diagonal
  question outright, for a different register: the deontic diagonal argument
  (`umedcta-formalization/docs/research/2026-06-18-deontic-diagonal-argument.md`,
  read today) diagonalizes a sound-but-incomplete anticipation predicate
  `Antic` over coded acts and derives a licensed move the anticipation board
  cannot cover — Gödel's first theorem transposed, with a runnable witness,
  converged with Carspecken in the loop and marked by its own document as a
  shared object, not a closed result. `formal/learner/up_leveling.pl` in this
  tree descends from that work and carries its adversarial-review caveat
  (§9.6).

So the honest statement at corpus scope is not poverty but an absent join.
What encoding the incompatibility relation into Q's arithmetic would require,
against what exists (the absences established by search over the tree, and
exactly as strong as the search):

1. A content→numeral map. Absent; no artifact assigns numbers to contents.
2. A set→number coding. The prime-product utilities sit ready and are applied
   to nothing but Euclid's construction; no hyperedge is ever coded.
3. Representing the finite relation inside Q. Available in principle at no
   cost — every finite relation is representable in Q by a finite disjunction
   of equations, with numeral distinctness supplying the refutations
   (standard theory, reasoned, not run) — which is why representability alone
   settles nothing: the represented copy is a relabeled copy, and the
   invariance argument runs on it unchanged.
4. The genuinely diagonal layer: arithmetized syntax, a substitution
   function, a derivability predicate. Absent from the tree, and the
   `robinson_q` prover as coded could not host it — it derives positive
   ground `o(...)` atoms only, has no negation over them beyond the Q1
   incoherence recognizer, no quantifiers, no formula objects.

The corrected verdict. The mechanism claim stands: the blindness is
invariance under relabeling, which afflicts every purely structural formalism
however small, and no self-reference is anywhere in it. The scope claim is
now exact: the *register* is too poor to pose the diagonal question; the
*corpus* is rich enough to pose it — Q represents the recursive functions,
which is all the diagonal lemma needs (standard theory) — and has not posed
it for this relation, though the project has posed it for the anticipation
register elsewhere. At corpus scope, "cannot appear inside its own
enumeration" is therefore neither a category fact nor a theorem in the tree:
it is an unposed question, with the machinery a few modules from the register
and no artifact composing them.

And a posed version would deliver less than the borrowed prestige suggests. A
composed system's diagonal sentence would concern derivability in the
composition, not material adequacy. Adequacy, under the intended arithmetic
reading of the seed atoms (a reading this report supplies; the register holds
them opaque), is a universally quantified sentence — for the seed edge
{even, odd}, that no number is both — and Q decides instances of it while
failing the universal: the standard one-point extension of the naturals
models Q and carries an element that is both even and odd (standard theory,
reasoned, not run). So the corpus's own arithmetic, joined as tightly as one
likes, would certify the seed edges only instance-wise. The two artifacts
stop at the same boundary: the register approximates Brandom's relation
exactly as far as declared finite data reaches; Q certifies arithmetic
generality exactly as far as instances reach. The vanishing point recurs at
the universal quantifier in both, and that recurrence — not diagonalization —
is the theorem-shaped thing at corpus scope. Diagonalization begins above
that boundary, and what it defeats there is self-certification of
derivability; material adequacy stays outside at every scope, because the
interpretation map from atoms to student mathematics is held by the practice
and never by either formalism.

Nor is any fixed-point construction present: the generator is a terminating
finite computation with no iteration to a fixpoint. (The nearest neighbor in
the truth literature is Kripke's least fixed point of a monotone operator —
and Gaifman notes of his own richer algorithm that once gap and jump rules
are added the operators are not monotone and the fixed-point argument no
longer carries the result; 1992, 232 n. 6.)

The scope check surfaced one wiring finding, in the place where a wiring
defect would matter most (measured, one `swipl` session against the live
tree). `robinson_q:incoherent/1` and the canonical relation's incoherence are
not two names for one referent — they are two orders of explanation,
deliberately opposed and documented as such in the Brandomian module's
header: the Robinson side recognizes a single self-untenable content
(`[o(eq(succ(3),0))]` — Q1) and licenses explosion from it; the canonical
side refuses explosion by design, and refuses the very shape:
incompatibility there is relational, arity ≥ 2 by contract, and
`add_incompatible_set/1` throws `domain_error(incompatible_set_arity, ...)`
on the Q1 singleton. The relation can say "cannot be held together"; it
cannot say "cannot be held at all." That is the arity split of the no-saying
analysis recurring at the deepest layer, and it is a boundary, not a defect.
The week's actual defect shape sits one file over: the Q1 clause exists twice
(`robinson_q.pl`, ungated; `axioms_robinson.pl`, pack-gated), the standalone
module's `incoherent/1` is imported by nobody (its five `use_module` sites
import `is_recollection/2` or nothing), and the bridge's union incoherence
does not reach the pack — `sequent_engine:is_incoherent/1` recognizes the Q1
set (measured YES) while `sequent_brandom_bridge:b_incoherent/1` does not
(measured NO), because `b_incoherent/1` unions the Brandomian relation with
the negation-pair floor only, per its stated contract. Arithmetic incoherence
is thereby invisible to the worker's imported incoherence surface; among the
unifying surfaces, only the crosswalk routing view
(`canonical_vocabulary:deontic_incoherent/3`, sequent route) reaches it,
because that view calls `is_incoherent/1` directly. A wiring deliverable, on
the same retrieval side as §6's, and never an entailment fix.

The owner's conjecture, kept as his: the hyperedges are the finite computable
incompatibility structure; the vanishing point is what that structure is a
structure *of*; it cannot appear inside its own enumeration; finite and
infinite are a pair, not a hierarchy. The best precise reading this addendum
can give it, with the scopes above in force: material adequacy quantifies
over an open class of cases (all inputs, all counterexamples — the number 2
was enough), every declared corpus is a finite selection from that class, and
each extension of the corpus re-poses the adequacy question about the
extended corpus, one step out — a step no arithmetization closes, because
each coding relocates the interpretation map without discharging it.
Nothing here proves the pairing permanent; §9.4 carries the strongest reason
in the literature for expecting it to be ("rich languages must have holes"),
flagged there as plausible rather than proven. His "maybe" survives as a
maybe.

### 9.4 Gaifman, read directly (read)

Source: Haim Gaifman, "Pointers to Truth," *The Journal of Philosophy* 89(5),
1992, 223–261, read today in the author's posted scan (haimgaifman.net); page
numbers are the journal's. The owner offered "the ground of 'ground' is
~~ground~~" as his own reading and asked that it not be leaned on. Verdict
first: the phrase is a defensible gloss on a Kripke-shaped fact, and it is not
what Gaifman's paper contributes here; what Gaifman contributes is better for
this repository's case.

What the paper does. Truth values attach to tokens ("pointers"), not sentence
types: line 1 reads "The sentence on line 1 is not true," line 2 repeats the
very same sentence, and the evaluation assigns the line-1 token GAP and the
line-2 token True (223–225). GAP "signifies more than mere absence of a
standard value. It signifies *recognized failure*," and it is an active value:
"By making GAP an active value we can construct on top of the gap instead of
falling into it" (225–226). The machinery is an evaluation algorithm over the
pointer network — standard rules; a closed-loop rule that gaps an unresolvable
cycle all at once; and jump rules by which later tokens assert truly that a
failed token is not true, where "jump signifies here true ascent in the
metalinguistic hierarchy" (230–231). "What is inexpressible in the usual
denotational semantics is thus expressible through network evaluation" (232).
A Tarski-like hierarchy is recovered "after the fact, i.e., after the
assignment of truth values," in one language with one truth predicate;
Kripke's grounded sentences are exactly level 0, and "real climbing starts
where Kripke leaves off" (233).

Section II defines the black hole: a gap S is an (n+1)-hole when "S is true"
and "S is false" are gaps as well, and a black hole is an n-hole for every n —
black holes are "semantic untouchables. No semantic information about them can
be conveyed in any way, be it as indirect and across as many layers as one may
wish" (240–241). The load-bearing result for our case: in systems that assign
values to sentence *types* — Kripke's, Martin–Woodruff's, Gupta's,
Herzberger's — "every truth-value gap is a black hole" (241), whereas in
token-based evaluation every locally finite network satisfies: if p is a gap,
some pointer asserting that p is a gap is true (242). Failure is always
sayable one token out. And the limit Gaifman conjectures for the whole
program: eliminating holes from a sufficiently expressive language "will bring
us near to what one might consider a 'universal language' — a self-contained
system, one that includes its own semantics. For this reason alone it is
highly plausible that rich languages must have holes"; "holes are perhaps the
inevitable price for a powerful language capable of evolving" (243). A
footnote names the general shape an "infinity paradox: a contradiction that
results from an attempt to construct self-containing systems" (243 n. 31).

What applies. The register is type-like in exactly Gaifman's sense: its
verdicts depend only on declared structure, invariantly (§9.3), with no
position from which a verdict's own adequacy could be assessed. So its
failures are black-hole-shaped from inside: no layer of register computation,
however iterated, can say of `even ⊨ composite` that it is false. But the
practice around the register is pointer-like, and its artifacts have been
behaving like Gaifman's jump rules all day: the module comment that predicts
too-strong entailments from sparse data, the `sparse_witness` marking, the
morning report, the correction commit — each a later token making a true
assertion about a failed one. The distinction to keep sharp: `support/3` is
computed from declared structure, so it can mark thinness (inside, invariant)
and cannot mark falsity (outside, not invariant). Marking narrows the region
where outside judgment is required; it cannot close it.

The aphorism, assessed. Gaifman's text does not run on "ground"; groundedness
appears as Kripke's notion, relocated to level 0 of an after-the-fact
hierarchy. The fact the owner's phrase reaches for is real and Kripke-shaped:
the sorting that grounds evaluation is not itself an item of the sorted
fragment, and Gaifman quotes Kripke conceding that the sense in which one can
say a liar sentence is not true "must be thought of as associated with some
later stage in the development of natural language, one in which the speakers
reflect on the generation process" (242, quoting Kripke). Holding such a word
under erasure — used at full force, not cashable inside the system that uses
it — is a fair posture toward it. But the thrust of Gaifman's own paper runs
the other way, against mystifying the outside: the reflection Kripke defers to
a "later stage" is, for Gaifman, ordinary speech — Jack and Jill's exchange is
"first base" (242) — and the gap is a value one builds on. Applied here: the
vanishing point is not an ineffable whole. It is the difference between a
type-level artifact and the token-level practice around it, and the practice
crosses it routinely; §9.1 is a measurement of one crossing. If one sentence
of Gaifman belongs under the owner's aphorism, it is the self-containment
limit (rich languages must have holes); if one belongs under this repository's
method, it is the active gap.

### 9.5 Carspecken: the term is "up-leveling" (sourced)

The half-remembered "up-cycling in the inference field" resolves, per the
project's NotebookLM sources (notebook
`Husserl_Derrida_Carspecken_Maharaj_Diagonalization`, source "Content
Inference Fields in Intersubjective Space"), to **"up-leveling" a content
inference field**: Zhang & Carspecken, "Content Inference Fields in
Intersubjective Space: Transpersonal Position, Illocution, and Logic in the
Analysis of Human Interactions," *Counterpoints* 354 (2013). The definition,
as the notebook quotes the paper: "Content inference fields have levels, such
that paths of argumentation on one level must presuppose agreements on a
higher level - a level of presuppositions. 'Up-leveling' a content inference
field is a process of articulating previously assumed principles,
definitions, or truths in order to problematize them. … Up-leveling is
usually a process of articulating inference chains." The owner's "inference
field" was right; only the prefix drifted.

The same paper carries a sibling term for the other meta-move he described.
When the rules of the interaction itself break down and become the topic,
illocutionary infrastructure is **objectivated**: "illocutionary
infrastructure … can become objectivated and the inferential relations that
had been at work are now made the content of a new topic for discussion,"
with "a new illocutionary structure … bid for" in the process. Renegotiating
rule constitution is objectivation; articulating and testing presupposed
truths is up-leveling. What happened in this repository today is the second.

### 9.6 Is the closure an up-leveling? As product, yes; as agent, no

Set the definition beside the artifact. Up-leveling articulates previously
assumed principles, definitions, or truths in order to problematize them, and
usually proceeds by articulating inference chains. The closure articulated
previously assumed truths about the divergence contexts — that a divisor in
(0,1) excludes every whole number, that periodicity excludes termination —
precisely when the rule-level relation had provably stopped yielding (§2). It
problematized what it articulated: one name-plausible nesting was refused,
and the battery records what the automata cannot certify instead of
certifying by name. And its declared product is literally an inference chain,
nines → periodic → non-terminating. The level structure is Carspecken's own:
the 90 triples argue on one level; the nestings are the "agreements on a
higher level - a level of presuppositions" that the triples' arguments had
been resting on without stating.

The agent caveat, made with the care owed to a claim at the top of this
project's philosophical order: up-leveling is something participants do in
intersubjective space, with positions taken and bids made. The register does
not participate, and by §9.3 it cannot represent the presupposition level, let
alone articulate it. The up-leveling was performed by the people (and the
assisting model) maintaining the corpus, in the practice around the artifact;
what the artifact holds is the declared residue of that move, re-entered as
data of a new shape. The exact claim, then: the a-fortiori closure *encodes
the product of* an up-leveling of the coding practice's content inference
field; it does not and cannot perform one. (In this repository's older
vocabulary the shape is ORR: a resource limit recognized, then reorganization
at the level of the practice rather than inside the exhausted strategy.)

The owner's Cantor conjecture belongs here rather than in §9.3, because it is
a conjecture about objectivation: "diagonalization has something to do with
objectivation — cantor allows the matrix to become the referent, right?"
Developed against the texts and the tree, with his hedge kept: partly, and
the part that fails is the instructive part.

What holds. In Cantor's argument the enumeration is first the medium — a
list read along, row by row — until the diagonal construction traverses it
as a whole: the matrix is operated on as one completed object, and a
totality that had been in use is now mentioned. That conversion of medium
into topic is Carspecken's objectivation to the letter (§9.5: inferential
relations "at work" become "the content of a new topic"), and it is the
owner's shape exactly.

Where it breaks, twice. First, in Cantor's proof the matrix becomes the
referent of the *proof's* discourse, never of any row. The diagonal sequence
is built by traversing the whole, but as an object it is one more sequence —
the same kind of thing as the enumerated items — and it refers to nothing;
no row mentions the enumeration; the objectivating gesture is performed
entirely by the mathematician, outside the list. The construction whose rows
do come to speak of the matrix is Gödel's, and only because arithmetization
forces reference: a coded sentence is about the system, under the coding,
from inside the language. So the formal counterpart of objectivation is
Gödel's coding rather than Cantor's diagonal, and the asymmetry inverts
cleanly: Cantor's product is same-kind and lands *outside* the enumeration,
once for all — an escape, which is what makes it a cardinality proof —
while objectivation's product is new-level and stays *inside* the practice:
the objectivated rules re-enter as the content of continuing talk, a new
illocutionary structure is bid for, and the move is iterable, since the new
infrastructure can be objectivated in turn — Gaifman's one-token-out again
(§9.4). Escape versus re-entry is the whole difference. Second, the diagonal
requires the enumeration given as a completed totality — the assumed list of
the reductio — and a practice is never so given: its rules are indefinitely
articulable, and objectivation thematizes an articulated fragment, not a
finished matrix. Cantor totalizes and leaves; Carspecken articulates and
stays.

The tree already holds both poles, and holds them apart (measured). The
escape pole runs in the number-theory pack: Euclid's construction takes a
claimed-complete list whole (its product), steps outside it (product plus
one), and the pack's header records why it is framed as incoherence — "the
claim to completeness defeats itself through construction." It runs on prime
lists and cannot be re-aimed at the hyperedge enumeration, for the §9.3
reason: the construction spends arithmetic structure (product, successor,
divisibility) that hyperedge contents do not have. The re-entry pole is
`formal/learner/up_leveling.pl`, which models objectivation as a detector —
its witness cites Zhang & Carspecken by name — and whose adversarial-review
caveat draws exactly the line drawn here: its meta-object "escapes the
commitment set only by functor distinctness (`objectivated/1`), NOT by
diagonal self-application + pointwise negation," and the content of the new
level is not supplied by the formalism, marked as an `erasure` field. (A
port residue to record: the review document the caveat cites lives in the
formalization archive the module was ported from, not at the path named in
this tree.)

Does Gödel numbering mean the corpus contains machinery for a genuine
objectivation of its own enumeration? It contains the *reference* half:
applied, the prime utilities would put a name of the enumeration inside the
arithmetic — the matrix become referent, as the owner says. What no coding
supplies is the *stance* half. Objectivation in Carspecken is a position
taken in intersubjective space — presuppositions articulated in order to be
problematized, a bid that can be contested — and a Gödelized register would
hold a numeral where the practice holds a position. Reference without stance
is the product-not-agent verdict at one level up: the difference between
holding a name of the enumeration and taking a position on it is the same
hand-off `up_leveling.pl` marks as erasure. That is what separates the
corpus's machinery from the people who performed today's closure, and no
addition of coding machinery moves it, because it is not a shortage of
machinery.

That is what makes the vanishing point productive rather than merely honest,
and it closes the loop with §9.4: the boundary the register cannot state is
the place where the practice up-levels; the crossing happens outside; and the
outside is not a mystery — it is where the warrants, the bases, the refusal,
and the four new witness counts now sit as declared, checkable data.

### 9.7 Limits of the addendum

- Measured claims were checked against the live tree today: register counts
  (679 declared, 25 earned, 19/6 support split), the four earned nesting rows,
  the closure and nesting files, the corrected fixture. The `not_ten` refusal
  is commit-attested only.
- The §9.3 wiring measurements come from one sequential `swipl` session
  loading `sequent_engine`, `sequent_brandom_bridge`,
  `brandomian_incompatibility`, and `robinson_q` against the live tree: the
  Q1 singleton recognized by `sequent_engine:is_incoherent/1` (axiom-pack
  witness `q1_successor_not_zero`) and by `robinson_q:incoherent/1`, refused
  by `b_incoherent/1` and `brandomian_incoherent/1`, and rejected by
  `add_incompatible_set/1` with `domain_error(incompatible_set_arity, ...)`.
  The import claims come from reading every `use_module` site; the absence
  claims (no content→numeral map, no coded hyperedge, no formula objects)
  come from search over the tree and are exactly as strong as the search.
- Three §9.3 claims are standard-theory reasoning, not run anywhere in this
  tree: representability of finite relations in Q, Q's numeral-distinctness
  theorems, and the one-point extension model on which an element is both
  even and odd. Each is textbook and checkably wrong if wrong. The intended
  arithmetic reading of the seed atoms is this report's, not the register's.
- The deontic diagonal argument and the up-leveling review were read today in
  the formalization archive (`umedcta-formalization/docs/research/`,
  2026-06-18 pair); the runnable witness cited there was not run here.
  Euclid's construction was read in `axioms_number_theory.pl` and
  `learned_knowledge_v2.pl`; the learner was not exercised today.
- Gaifman was read in the 1992 paper alone, in scan; the 1988 TARK paper and
  the formal companion work were not read.
- The Carspecken quotations come through the project's NotebookLM notebook,
  from one paper; up-leveling's career elsewhere in Carspecken's corpus was
  not surveyed, and the sibling-term distinction rests on that one source.
  The Cantor/objectivation development in §9.6 is an argument from those
  sources' definitions, not from new reading.
- The invariance argument of §9.3 is mine and elementary; if it is wrong it is
  checkably wrong.
- The finite/infinite pairing remains the owner's conjecture and is marked so
  wherever it appears.
