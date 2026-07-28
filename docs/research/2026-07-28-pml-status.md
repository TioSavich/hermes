# PML status: what the calculus does here, and whether to flatten it

Date: 2026-07-28. Question, in the owner's words: PML was always pictured as
something that would need to be flattened into genuine incompatibility
semantics; a clear report on its status is wanted; a prior attempt to figure
out what it could and could not do was not entirely convincing.

Method: every count in this report was produced today against this working
tree unless a source is named. Single sequential `swipl` queries and greps;
no generator, artifact, or database was modified. Where the report reasons
past what the artifacts settle, the passage says so. Three prior analyses
were read and are answered in §8: the modal characterization of 2026-04-20
(`pml-testing-bridge/diagnostics/PML_MODAL_STATUS.md`), the adversarial
review of 2026-07-01
(`umedcta-formalization/docs/research/2026-07-01-pml-talkmoves-adversarial-review.md`),
and §6 of yesterday's entailment report
(`docs/research/2026-07-28-why-entailment-does-not-move.md`). Which of the
first two is the analysis the owner was unconvinced by is my reconstruction,
not his statement; both are engaged.

One state note. The working tree moved this morning: an uncommitted
a-fortiori context closure
(`formal/incompatibility/incompatibility_sets_a_fortiori_context_closure.pl`,
generated from `data/research/a_fortiori_context_nestings.json`) added 11
hyperedges to the register and moved earned entailment 21 → 25. The four new
earned pairs are context-to-context nestings, every content `o(...)`-wrapped.
Numbers below are from this current state
(`python3 scripts/extract_incompatibility_entailment_order.py --check`:
hyperedges=679, minimal=294, contents=385, earned=25, vacuous=1536,
equivalent=9).

## 1. What PML is, as built

`formal/pml/pml_operators.pl` declares three mode-of-validity wrappers —
`s/1`, `o/1`, `n/1` — and four polarized prefix operators — `comp_nec`,
`exp_nec`, `exp_poss`, `comp_poss` — plus `neg/1` and the sequent arrow. The
twelve modal terms arise by nesting a mode over a polarity. Operationally the
wrappers are typed pass-throughs: `s(P)` succeeds when `P` is an
instantiated, acyclic, non-list, non-dict term, and the polarity operators
succeed on any argument. Nothing in the operator module decides truth,
accessibility, or exclusion. This matches the standing characterization: a
material-inference calculus in Brandom's sense, not a Kripke modal logic; the
appendix (`formal/pml/Modal_Logic/AppendixA_Unified_2.tex`, line 1349) states
as an open question whether the framework admits a model-theoretic semantics,
and the 2026-04 schema probe recorded 72 of 72 classical schema tests (K, T,
4, 5, D, B across all twelve compounds) failing mechanically.

Everything PML does in this repository, it does through one of four
machineries:

**(a) The reader contract.** `pml_score` and `validate_reader_axioms` are
live worker ops (`hermes/dispatch_spec.pl:725`, `:565`;
`hermes/encyclopedia.pl:1408-1520`). Gemma emits `reader_axiom/4` and
`passage_mode/3` facts in PML vocabulary; the Prolog side parses them
read-only, rejects anything outside the twelve legal operators, checks each
axiom's declared polarity against its operator, and compares the reading's
(mode, polarity) posture against the postures the lesson text itself licenses
(`formal/pml/text_interpreter.pl`, phrase-triggered, conservative). The
monitoring chart export carries the lesson's PML facts to the teacher surface
(`hermes_worker.pl:2808-2854`). This is the one place in the system where the
twelve-cell vocabulary is a working interface: it is the type system that
lets a small model's readings be checked at all.

**(b) The axiom packs and the embodied prover.** A finite, hand-authored
table of material inferences from the manuscript, reachable through live
dispatch ops (`semantic_material_witness`, `intersubjective_material_witness`,
`rhythm_transition_witness`, `proves`): the dialectical rhythm (8 transitions,
`formal/pml/rhythm_axioms.pl:43-50`), the S→O transfer pair and the N-mode
solidification/liquefaction pair (`formal/pml/semantic_axioms.pl`), the
hylomorphic O→N shift (`semantic_axioms.pl:171-183`), the elusive-subject
inversion and the unsatisfiable-desire incoherence
(`formal/pml/pragmatic_axioms.pl:70-130`), the oobleck transfer and the
confession→forgiveness rule (`formal/pml/intersubjective_praxis.pl`). The
embodied prover maps polarity to inference cost — compressive 2, expansive 1
(`formal/sequent/embodied_prover.pl:62-64`,
`formal/formalization/modal_costs.pl`) — and its rhythm rule fires only on
`s(_)`-wrapped premises. Roughly seventeen authored rows in total. Small, but
executable, and the only executable trace of the manuscript's tempo claims.

**(c) Mass annotation of two corpora.** All 820 rows of
`knowledge/misconceptions/pml_wire.pl` carry the identical signature
`s(comp_nec(unlicensed(_)))` (820 of 820, counted today); every `CONNECTS TO`
comment in `knowledge/misconceptions/*.pl` follows the same template with
zero departures. The error-rule corpus stamps `s(comp_nec(rule(R)))` on every
material-inference premise by generator constant
(`scripts/extract_error_rule_incompatibility.py:174-180`; 180 occurrences in
`formal/incompatibility/error_rule_inferences.pl`). Twenty-three strategy
automata call `s(comp_nec(...))` and `s(exp_poss(...))` inline in their
transition bodies (122 `s(exp_poss(` occurrences repo-wide, nearly all
there). Those calls type-check their argument and succeed; no collector reads
them, no trace or export carries them. They are authored annotation —
compression for committed execution steps, expansion for opening steps — that
the runtime consumes as a no-op beside an `incur_cost/1`.

**(d) Directory residence without dependence.** Most of `formal/pml/` by
line count does not use the twelve cells at all. `discourse_features.pl`,
`discourse_pragmatics.pl`, `media_alignment.pl`, `gesture_alignment.pl`,
`talkmoves_adapter.pl`, `trace_adjudication.pl`, `interactional_trace.pl`
each state in their own module headers that they assign no PML mode or
operator; they are deterministic evidence layers that prepare transcript
material *for* a reader who would. The deontic scorekeeper
(`formal/learner/deontic_scorekeeper.pl`) tracks commitment and entitlement
without the cells. The MUA relations are Brandom's *Between Saying and
Doing* practice/vocabulary relations, again cell-free.

## 2. The census, reproduced

Textual occurrences of `mode(operator(` over every `.pl` file in this
checkout, worktrees excluded:

| cell | count | | cell | count |
|---|---:|---|---|---:|
| `s(comp_nec` | 1,963 | | `o(comp_nec` | 6 |
| `s(exp_poss` | 122 | | `n(exp_poss` | 4 |
| `n(comp_nec` | 12 | | `n(comp_poss` | 4 |
| `n(exp_nec` | 10 | | `s(comp_poss` | 1 |
| `s(exp_nec` | 8 | | `o(exp_poss` | 0 |
| `o(exp_nec` | 8 | | `o(comp_poss` | 0 |

Total 2,138; the top cell is 91.8%; two cells are empty. (The briefing's
1,782/1,957 and yesterday's 1,962/2,137 are earlier snapshots of the same
shape; the growth since 07-27 is almost exactly the decimal slice's 180
generator-stamped premises.) The minority cells live almost entirely in the
axiom packs themselves — the definition site, not the corpus.

The register's contents, counted by loading the current
`incompatibility_entailment_order.pl`: 385 total; 196 `o(...)`, 102
`inference(...)`, 35 `strategy/2`, 47 bare atoms, 3 fixture `rule/1`, 1
`neg(o(p))`, 1 `result_of/3`. Zero `s(...)`. Zero `n(...)`.

Where the S and N modes went, traced in the generators: the coded triple's
`s(comp_nec(rule(R)))` premise enters the discovered-set cache as the fused
atom `inference(rule_R_licenses_L)`
(`scripts/extract_error_rule_incompatibility.py:59`), so the mode is not
recoverable from the relation's atoms (it remains recoverable through
`material_inference/3`, which keeps the wrapped premise — a join, not a
loss). The N-mode content is thinner than the briefing stated: what survives
into Prolog is `error_rule_warrant/2` with the two-valued kind
`community_sanctioned` (90 of 90 today); the *named* community's commitment
survives only in the corpus column `incompatible_with` of
`data/research/incompatibility_triples.json` (203 codings), reachable but not
loaded.

## 3. What PML does here that nothing else does

The briefing offered the sentence "PML sorts without ever adding an
exclusion, and incompatibility runs on exclusions alone." Measured against
running code, that sentence is nearly right and wrong in an instructive way.
PML contributes exactly three exclusion schemas to code that runs:

1. **Mode-relativized non-contradiction.** The sequent engine's base
   incoherence includes the same-marker pair: `s(P)` with `s(neg(P))`, and
   likewise for `o` and `n` (`formal/sequent/sequent_engine.pl:267-280`).
   The contrapositive is the interesting half: `s(P)` beside `o(neg(P))` is
   *coherent by construction*. The mode wrapper's one semantic act in the
   exclusion machinery is to relativize contradiction to a perspective — a
   student can hold what the mathematics negates without the context
   exploding. That is the viability commitment stated as a single rule.
2. **Contrary necessities.** `pml_incompatibilities/2`
   (`hermes/encyclopedia.pl`) flags `comp_nec` against `exp_nec` over the
   same content in the same mode.
3. **The unsatisfiable desire.** `n(represents(C_Id, I_f))` is incoherent
   whenever `C_Id` is finite and `I_f` carries the vanishing-point mark
   (`formal/pml/pragmatic_axioms.pl:109-130`) — the refusal of any finite
   identity claim to exhaust the I-feeling, contributed to
   `sequent_engine:is_incoherent/1` by the PML layer itself.

All three are schema-level, and all three are essentially idle against the
corpus: no misconception or error-rule fact wraps a negation (`o(neg(` occurs
zero times in the tree; `s(neg(` and `n(neg(` only in engine, fixture, and
audit files), and `exp_nec` readings — the other half of the
contrary-necessity pair — were emitted zero times in the one model run that
assigned operators per-item. So the corrected sentence is: **PML's exclusions
are schema-level and unexercised; the corpus's exclusions are content-level
and arrive without PML's help.** The 679-hyperedge relation, its 94 emergent
sets, and now its 25 earned entailments owe nothing to the twelve cells; the
canonical relation treats mode-wrapped atoms as opaque ground terms by
declared contract (`formal/incompatibility/brandomian_incompatibility.pl`,
module header).

Beyond the three schemas, what PML uniquely does today is: the reader
contract of §1(a) — the twelve cells as the legality gate and the (mode,
polarity) posture as the unit in which a model's reading of a lesson can be
compared with what the lesson licenses; the polarity-cost asymmetry and the
rhythm grammar of §1(b); and role-marking inside the coded triples — the
`s(comp_nec(rule(...)))` wrapper is how a human reading
`error_rule_inferences.pl` can tell which atom is the student's rule rather
than the licence or the context. The mass annotation of §1(c) does none of
these: for `pml_wire.pl` the information content of 820 identical wrappers is
the membership list itself, and the dispatch op that serves it hard-codes the
single signature (`hermes_worker.pl:1593-1594` matches
`sub_term(unlicensed(Name), ...)`).

## 4. Is the twelve-cell space earning its keep?

The question assumes the 91% concentration is a measurement. Mostly it is
not. A distribution measures discrimination only where assignment is per-item
and could have gone otherwise. Here, 820 wire rows and 180 error-rule
premises are generator constants; 837 `CONNECTS TO` comments follow one
template without exception; the automata annotations are authored but binary
by convention (execution steps compressive, openings expansive). The corpus
census records *coding policy* — the decision that student rules are held
subjectively and compressively — repeated at scale. It cannot tell whether
the space is finer than the corpus distinguishes, because the corpus was
never asked to distinguish.

The one per-item assignment on record is the TalkMoves run (tracked metrics,
`umedcta-formalization/docs/research/2026-06-15-pml-talkmoves-reviewer-metrics.json`,
re-read today): modes objective 51 / normative 2 / subjective 1; operators
comp_nec 42 / comp_poss 6 / exp_poss 6 / exp_nec 0. A collapse again — but
into a different cell (O, not S), and under a prompt that instructed the
model to treat "I think" and "maybe" as decorative wrappers, which plausibly
manufactured the objective skew by stripping the very subject-position
phenomenon the S-mode exists to record. The adversarial review named this
(H3) and posed the trilemma — fact about these transcripts, artifact of the
wrapper instruction, or categories that do not discriminate at this
resolution — and no run since has separated the three. That is still the
honest state: **whether the twelve cells discriminate classroom discourse has
never been measured cleanly.**

What the space's shape does say, from the field-vocabulary sort
(`docs/research/2026-07-27-no-saying-vocabularies-and-incompatibility.md`
§2-3, checked against its sources today): the no-saying vocabularies of
mathematics education sort into at least five distinct cells when sorted by
hand, including cells the corpus currently leaves near-empty
(`n(exp_nec(...))` for the overgeneralization family, `o(comp_nec(...))` for
diagnostic entitlement claims) — and at the same time Carspecken's fourth
validity domain, identity, has no cell at all, so identity-constitutive
no-saying sits off the space rather than in it. Two empty cells and one
missing dimension together read the same way: the grain of the space was set
by the manuscript's phenomenology, not induced from the corpus. That is not
an indictment — a theory-derived etic instrument is allowed to have cells its
first corpus leaves empty (`o(exp_poss)` and `o(comp_poss)` are empty because
this project never codes objective possibility; the O-realm enters only as
settled content). But it means the twelve-cell space is currently a
vocabulary held on the manuscript's warrant, not on the corpus's, and any
claim that the cells measure discourse awaits the clean per-item run.
(Interpretation beyond the artifacts: the last two sentences.)

## 5. Is flattening PML into genuine incompatibility semantics coherent?

Define the target first. "Genuine incompatibility semantics" in Brandom's
sense is what `brandomian_incompatibility.pl` models: incompatibility between
contents as the semantic primitive, recorded as hyperedges; incoherence as
containment of a declared edge; entailment as inclusion of incompatibility
ranges; negation as the minimal incompatible. Non-explosive, finite, exactly
as complete as its data. "Flattening PML into it" would mean: every content
PML sorts acquires a place in that relation — an exclusion profile — and the
mode/polarity structure either dissolves into atom names, survives as
provenance, or is re-coded as data.

The first thing to say is that **the flattening is not hypothetical; it is
the pipeline this repository built over the last week, and it works.** The §5
triple standard took contents that had sat for months under
`s(comp_nec(unlicensed(X)))` — sorted, exclusionless, structurally incapable
of a triple because `unlicensed/1` discards the valid domain — and re-coded
them as rule / licensed-consequence / divergence-context triples with
exclusion sets. Ninety emergent hyperedges, machine-checked minimal, each
carrying its warrant. The S-wrapper was fused into the inference name; the
N-content was routed to warrant kind and corpus column; polarity was dropped
entirely. And this morning's a-fortiori closure earned the register's first
materially true content entailments from that corpus — context nestings, all
of them `o(...)`. Nothing in that chain needed a mode to do semantic work,
and nothing broke when the modes were carried as provenance.

So the coherence question splits along PML's own joint, and the split is the
whole answer:

**The mode skeleton flattens cleanly, and mostly already has.** S and N are
scorekeeping data — *who holds* the content and *who sanctions* the
exclusion. In Brandom's own account that is exactly where they belong: the
deontic attitudes are kept by the scorekeeper, not written into the contents.
The register's design — S fused into the atom, N as `error_rule_warrant/2`
plus the named commitment in the corpus — is not a mutilation of PML; it is
the correct Brandomian carving, and calling the result "an incompatibility
relation with extra provenance" undersells what the provenance does. The one
genuine semantic act the modes perform — relativizing non-contradiction so
that cross-perspective disagreement is coherent — is expressible inside the
flattened vocabulary as a gating rule on which exclusions fire, and the triple
encoding already achieves the same effect by other means (the student's rule
and the sanctioned commitment never enter one edge as bare contradictories;
the divergence context mediates). For the modes, flattening is clarification.

**The polarity skeleton does not flatten, because it is not about exclusion
at all.** `comp_nec(P)` and `exp_poss(P)` do not differ in what they exclude
— the incompatibility relation cannot distinguish them, not for want of data
but categorially: polarity records the *tempo and cost of holding* (narrowing
against opening, fixation against release, 2 inferences against 1), and an
exclusion relation is atemporal and cost-free. The same holds for the rhythm
table (a trajectory, not a constraint set), the oobleck transfers and the
forgiveness rule (directed consequences between perspectives), and the
vanishing-point refusal (a bound on representation, coded as the one place
PML natively contributes an incoherence). Steelman for flattening anyway:
Brandom reconstructs consequence *from* incompatibility, so in principle
every material inference in the packs is recoverable from a rich enough
exclusion set. Rebuttal: that recovery requires dense incompatibility data
over actions, positions, and phases that no one has coded, that the
manuscript does not state, and that the 07-28 structural argument says
one-fact-deep corpora cannot supply — and even a successful recovery would
return the transitions without their costs and tempo, which are the content.
For the polarity half, flattening would be deletion carried out under
translation's name.

So the direct answers. *Coherent?* Yes for the mode skeleton — demonstrably,
because it has been done and the register runs. Not coherent as a total
program: applied to the polarity/rhythm half it is a category error, not an
ambitious reduction. *Desirable?* The mode half: yes, continue — every
PML-sorted content that can carry an exclusion profile should acquire one by
exactly the triple discipline now in place, and `s(comp_nec(unlicensed(X)))`
should be read from now on as a stalled input queue for that pipeline, not as
an analysis. The polarity half: no — not because it is sacred, but because
the thing it records is real in the reader contract and the prover, and no
exclusion set can carry it. *Already half-done?* Yes, and the half that is
done is precisely the half that should be.

## 6. What would be lost

Assessed layer by layer, since the owner expects the embodied and
existential layers to do work an exclusion relation cannot.

- **`discourse_features.pl`, `media_alignment.pl`, `gesture_alignment.pl`**
  (and `discourse_pragmatics.pl`, `trace_adjudication.pl`,
  `talkmoves_adapter.pl`): nothing would be lost, because these never touch
  the twelve cells. Each declares in its own limits block that temporal
  alignment, surface features, and pragmatic atoms establish no PML mode,
  operator, tension, or trace. They are deterministic evidence layers, and
  they would serve a flattened successor exactly as they serve PML — what
  they would lose is only the addressee their evidence is prepared *for*.
  The expectation that the embodied layers resist flattening is
  right in conclusion but mislocated in mechanism: they resist it by not
  depending on the thing being flattened.

- **`intersubjective_praxis.pl`**: this is PML-native and would genuinely
  not survive. Two oobleck transitions (aggressive action crystallizes the
  other; listening liquefies the other) and the mutual
  confession→forgiveness rule — Recognition's structure as a material
  inference whose premises are two agents' normative acts and whose
  conclusion is a normative release. An exclusion relation can state that
  certain stances cannot be held together; it cannot state that one agent's
  act *transforms the other's position*, which is what these rows encode.
  Honest size: three rules, much of whose content lives in the witness
  dicts. Thinness is a coverage fact about the packs, not evidence the
  vocabulary they are written in is dispensable.

- **`pragmatic_axioms.pl`**: the elusive-subject inversion (subjective
  fixation of the I-feeling dissolves objectively) and the
  unsatisfiable-desire incoherence. The second is the anti-presence
  commitment as running code, and it is the clearest single case of work an
  exclusion relation cannot do alone: the exclusion it contributes is
  *generated by* the vanishing-point mechanism — a refusal of binding, not a
  declared edge — and would have to be frozen into a static edge list to
  survive flattening, losing exactly the generativity that makes it a
  statement about every finite identity claim rather than some.

- **The rhythm/cost machinery**: the dialectical cycle and the 2:1
  compressive/expansive cost asymmetry. Lost entirely under flattening, as
  argued in §5. This is where the manuscript's Carspecken side lives in
  code, and Carspecken outranks Brandom in this project's own hierarchy —
  a flattening into Brandomian semantics alone would enforce the ranking's
  inverse.

- **The reader contract**: `pml_score` and `validate_reader_axioms` would
  need a successor type system. The twelve cells are currently the schema
  that makes a small model's readings checkable; posture comparison (does
  the reading's mode/polarity match what the lesson licenses?) has no
  incompatibility-semantics equivalent at the current data depth.

## 7. Worth keeping regardless, and scaffolding

Keep, on present evidence: the reader contract and its twelve-cell legality
gate (§1a) — the one live interface; the axiom packs as finite,
manuscript-derived tables, honestly labelled as such (§1b); the
mode-relativized non-contradiction rule in the sequent engine — one clause,
and it is the viability thesis; the `s(comp_nec(rule(R)))` wrapper inside
coded triples as a role marker; the coding standard's discipline of routing
S to atom names and N to warrant provenance at the relation's door.

Scaffolding, by the same evidence: the 820 identical signatures of
`pml_wire.pl` — per-row, the cell adds nothing; the file's value is the
source-tag join, and its PML dress is the one-place `unlicensed/1` that the
07-27 analysis correctly identified as the valid-domain gap wearing an
operator. It should be read as the stalled input queue for the triple
pipeline (its rows upgrade to triples or to a recorded `none_found`, which is
a real finding), not re-annotated. The automata's inline modal calls are
authored content with no consumer: either a collector someday carries them
into traces, or they remain a reading aid for humans in the source — both
defensible, but the current state should not be described as the automata
"emitting" modal signals, because nothing receives them. The two empty cells
need no action; an etic instrument may hold empty cells so long as no claim
is made that the corpus filled them.

## 8. The prior analyses, and where this report departs

**The 2026-04-20 modal characterization** (`PML_MODAL_STATUS.md`). Its
positive characterization holds up completely and is confirmed here: sort
tags, classification markers, no classical schema, consequence only by named
material rows. Two departures. First, it describes the incompatibility layer
as LNC-plus-explosion; that was true of the engine it read, but the canonical
relation has since moved to the non-explosive Brandomian module (the split
executed 2026-05-24), so its residual worry — that the engine carried no
persistence or minimal-incompatible negation — is now answered in code. Second,
and more to the point of the owner's dissatisfaction: the document reads the
3,257-of-3,260 proof-failure rate as "the predicted footprint of a Brandomian
material-inference calculus." The mechanism claim is right — unnamed
inferences do not go through — but the framing lets an almost-empty table
count as confirmation. The honest statement is that the corpus exercised a
calculus whose material table covered almost none of it, which is a coverage
measurement, not a vindication. If this is the analysis that did not
convince, the instinct was sound, and the correction is not that PML can do
more than it said, but that "the failure is predicted" and "the instrument
did work" are different claims and the document blurs them.

**The 2026-07-01 adversarial review** (H3 and M5). Full agreement with the
trilemma: the run could not distinguish a fact about the transcripts from a
prompt artifact from non-discriminating categories, and the wrapper
instruction is a real confound. This report adds the fourth fact the review
did not have: in the home repository the cells are assigned wholesale by
generators and templates, so the repo census cannot bear on discriminating
power in either direction (§4). The review's H3 remains the live open
question about PML-as-instrument, and it is still unrun.

**Yesterday's §6** (the libertine framework). Agreement on the mechanism:
the tripartition is not why entailment did not move; the projection into one
realm happened at generation; mode does no work inside the relation.
Departure on the summary: "multiplies names without adding
incompatibilities" is measurably too strong — three schema-level exclusions
exist in running code (§3), one of them contributed by PML's own pragmatic
layer, and the mode wrapper's relativization of contradiction is a semantic
act, not a name. What makes the sentence *feel* true is that all three
schemas are idle against this corpus. The precise claim is idleness, not
absence, and the distinction matters for the flattening verdict: a vocabulary
whose exclusions are idle needs data; a vocabulary with no exclusions would
need dissolving.

## 9. Limits

- The cell census counts textual occurrences in `.pl` files, not loaded
  clauses; comments and generated files are included by design (the corpus
  annotations under discussion live in both).
- The register census loads the current uncommitted working-tree artifact;
  the 21→25 movement is attributed to the a-fortiori closure by reading the
  new cache and the four new earned pairs, not by rerunning the closure
  generator.
- The TalkMoves distributions are read from the tracked metrics snapshot in
  the read-only formalization repo, not reproduced from the run directory.
- Which prior analysis the owner meant is a reconstruction; §8 answers the
  three candidates rather than guessing once.
- The judgments that polarity, rhythm, and the recognition rules are
  categorially outside an exclusion relation are argued from the semantics
  of the relation as coded, not measured; the steelman and rebuttal are
  given in §5 and stand or fall together.
