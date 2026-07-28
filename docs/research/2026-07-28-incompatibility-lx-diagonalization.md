# Incompatibility, LX, diagonalization, vanishing points: the shape this repo can use

Date: 2026-07-28. Commission, in the owner's words: solidify the shape of
incompatibilities this repo can use; bring incompatibility, LX,
diagonalization, and vanishing points into something actionable. The
actionable half lives in
`plans/2026-07-28-incompatibility-actions.md` (project plans directory); this
report carries the evidence.

Method. Every claim marked *measured* was checked against this working tree
today: the query was run, the clause was read, or the rows were counted, in
short `swipl` sessions and greps. Where a number is quoted, the sentence says
what the reader that produced it believed about the rows it counted, per the
reader-was-wrong discipline. Claims marked *read* come from a named document.
Nothing here reruns the entailment impossibility argument: that earned
entailment is structurally unreachable for `{rule, licence, context}` triples
is settled (`docs/research/2026-07-28-why-entailment-does-not-move.md`, §2,
confirmed twice), and no proposal below treats corpus growth as a lever.

Two audiences. A reader who knows Brandom but not this repo: §1 is your map of
where incompatibility semantics actually runs here. A reader who knows this
repo but not Brandom: the one sentence of theory you need is that in
*Between Saying and Doing* incompatibility is the semantic primitive —
contents mean what they exclude — and entailment is inclusion of
incompatibility ranges; LX names the relation where a vocabulary is both
algorithmically **eL**aborated from a practice and makes e**X**plicit what
that practice was implicitly committed to.

## 1. The surfaces: what runs where (measured)

The repo does not have one incompatibility relation. It has four entailment
surfaces and six incoherence surfaces, deliberately layered, and the defects
found today are all at the joins between them, never inside one.

### 1.1 Entailment surfaces

| surface | semantics | data it ranges over | earns today? |
|---|---|---|---|
| `brandomian_incompatibility:incompatibility_entails/2` | replacement over declared edges, non-strict, vacuous case refused | `incompatible_set/1`: **5 seed edges at runtime** (measured); feeders load more only when explicitly run | on seeds only |
| `incompatibility_sets:incompatibility_entails/2` (+ witness/3, live worker op `incompatibility_entailment_witness`, POST /api/witness/formal) | replacement with inspectable profile witness, non-strict | `incompatibility_set/2` over `public_discovery_context/1` contexts: 618 `defeasible_inference` rows (90 error-rule + 528 Big Red), 44 registry-neighborhood, 2 finite-program | yes, but **not on the a-fortiori closure** (§1.3) |
| the generated register (`incompatibility_entailment_order.pl`) | **strict** earned entailment, minimality-reduced, support-marked | all 679 declared input hyperedges including the closure | 25 earned, 19 multi-profile / 6 sparse (measured today, `--check` green) |
| `sequent_engine:entails_via_incompatibility/2` (geometry pack, `axioms_geometry.pl:67-110`) | restriction-profile inclusion: P entails Q when P rejects every restriction Q rejects | the van Hiele shape × restriction table: 7 shapes, 6 restrictions, 22 `incompatible_pair/2` rows | yes — square entails rectangle, and the witness carries both profiles |

Four relations answer to the name "incompatibility entailment," two of them
live on the worker, with different strictness and different data. That split
is by design at the layer boundaries (the canonical-vocabulary module records
the principled refusal to merge, `knowledge/crosswalk/canonical_vocabulary.pl:163-171`)
— but nobody had put the four in one table, and two consequences of the split
were invisible until today (§1.3, §1.4).

The geometry row deserves a sentence it has never gotten in the
incompatibility reports: **it is the repo's one dense arity-2 incompatibility
corpus, and it earns entailment for exactly the reason the error-rule triples
cannot.** Its edges are pairs; its partners (the six restrictions) are shared
across shapes; absorption needs only one shared partner plus an asymmetry.
The 07-28 impossibility argument's dog/mammal mechanism is running code here,
in the corpus's own material. The contrast is the whole finding of the
entailment work made concrete: pairs with shared partners earn (geometry,
22 rows, dense); uniform triples with private pairs cannot (error rules, 90
rows, zero earned, proved invariant).

### 1.2 Incoherence surfaces

Measured in one `swipl` session against the live tree, on the Q1 singleton
`[o(eq(succ(3),0))]`:

- `sequent_engine:is_incoherent/1` — YES (negation-pair floor plus axiom-pack
  clauses; the robinson pack is include-compiled and enabled by default).
- `robinson_q:incoherent/1` — YES (the ungated Q1 clause, `robinson_q.pl:131`).
- `sequent_brandom_bridge:b_incoherent/1` — **NO**. Its classical arm is
  `incoherent_base/1` (the two negation-pair shapes only), per its stated
  contract (`sequent_brandom_bridge.pl:63-68`).
- `brandomian_incompatibility:brandomian_incoherent/1` — NO, and
  `add_incompatible_set/1` **throws** `domain_error(incompatible_set_arity, ...)`
  on the singleton (`brandomian_incompatibility.pl:269-276`).

The last refusal is a boundary, not a defect: the relational vocabulary can
say "cannot be held together" (arity ≥ 2 by contract) and cannot say "cannot
be held at all." The arity split of the no-saying analysis recurs at the
deepest layer, exactly as the 07-28 addendum recorded. The defect is the
wiring around it: `robinson_q:incoherent/1` is exported and imported by
nobody (its five `use_module` sites pull `is_recollection/2` or nothing —
measured), the Q1 clause exists twice (`robinson_q.pl:131` ungated;
`axioms_robinson.pl:348` pack-gated), and the worker's imported incoherence
surface (`b_incoherent/1`, imported at `hermes_worker.pl:106-108`, serving
the `brandomian_check` op) cannot recognize arithmetic incoherence that the
engine one import away recognizes. Among unifying surfaces only
`canonical_vocabulary:deontic_incoherent/3` (sequent route) and
`canonical_vocabulary:incoherent/2` reach it, because both call the engine
directly. Action 3 closes this at the bridge, where union is the module's
stated job.

One detail checked and found sound: the worker's source classifier
(`brandomian_incoherence_source/3`, `hermes_worker.pl:3677-3690`) has a
fallback clause for incoherence-base cases without a bare negation pair. I
suspected it unreachable; it is reachable for same-marker pairs
(`s(P)` with `s(neg(P))`), which `incoherent_base/1` covers and the
classifier's pair clause does not. The classifier fits the current union
exactly and needs one labeled clause added only if the union widens.

### 1.3 Found today: the a-fortiori closure loads but is not served (measured)

The 11 closure triples (`incompatibility_sets_a_fortiori_context_closure.pl`)
are consulted into `discovered_set_fact/2` at load under context
`a_fortiori_context_closure` — and that context is **not** in
`public_discovery_context/1` (`incompatibility_sets.pl:178-181`), so
`incompatibility_set/2` never serves them. Consequence, run today:

```
incompatibility_sets:incompatibility_entails(
    o(context(the_expansion_repeats_periodically)),
    o(context(the_expansion_does_not_terminate)))   →  NO   (live surface)
```

while the register earns exactly this pair with 3 witnesses. The register
generator reads *all* `discovered_set_fact/2` rows regardless of context
(`scripts/extract_incompatibility_entailment_order.py:69`); the live module
consults the same file and then filters its own serving predicate. Two
readers of one artifact with different beliefs about its scope, both green —
the week's defect shape, sitting on this week's proudest result. The four
earned entailments, the first in the register's history, exist offline only.

**The one fact is necessary and not sufficient, and the difference was
measured rather than predicted.** Adding
`public_discovery_context(a_fortiori_context_closure).` serves all 11 rows to
`incompatibility_set/2`, which previously served none of them — and moves the
entailment not at all. All four closure pairs still answer NO, at a 300-second
limit, so these are refusals rather than timeouts. The cause sits one layer
deeper: `incompatibility_entailment_witness/3` requires
`set_incompatible_witness(Context, ...)` to find its witness inside the *same*
context as the profile it answers, and `incompatibility_set/2` is
context-scoped. Closure rows carry context `a_fortiori_context_closure`; the
profiles they would have to witness carry `defeasible_inference`. A closure row
can therefore never witness the replacement it was generated to license.

Measured across the whole register: the runtime relation confirms **20 of the
25** earned pairs. The five it refuses are the four closure pairs and
`inference(measuring_stick_grounds_length) |= o(grounded(measuring_stick))`.

Publishing a context is safe in the direction that matters: it adds profiles,
and the test requires *every* profile to survive replacement, so it can only
withdraw entailments, never invent them. The register check reruns green and
unmoved at 25.

Whether a witness may be drawn from a context other than the profile's own is a
change to what an incompatibility set means — a context is what makes the set
finite and closed-world — so it is left as a decision, not taken here.
Strictness survives on the live surface for the divisor pair because two rules
are coded natively at the narrow context (4 grep hits = 2 triples, measured),
so the reverse replacement fails.

### 1.4 Found today: the canonical relation never carries the corpus (measured)

`brandomian_incompatibility:incompatible_set/1` holds **5 edges at runtime**
(measured: the three arithmetic seeds, the blackberry triple, the
incommensurability triple). Its feeders — registry adapter, discovery
install, literature bridge — are explicit-load by contract, and **no feeder
exists for the error-rule cache or the closure cache**. The register
generator bypasses the relation and reads the caches directly. So at worker
runtime:

- `brandomian_check` (b_incoherent, pairwise entailments, queried entailment)
  judges commitment sets against 5 seeds. An agent holding a complete coded
  triple — rule, licence, and divergence context together — is reported
  coherent.
- `deontic_scorekeeper:deontic_incoherent(Agent, hyperedge_incoherence(Set))`
  (`deontic_scorekeeper.pl:590-605`) reaches the same starved relation
  through `joint_hyperedge/1`, so the crisis pipeline
  (`crisis_from_deontic_incoherence/3` → execution handler → ORR
  reorganization) can never fire on the corpus's 90 warranted triples.

This is the consumption ethic's own case: the error-rule catalogue is
stalled pipeline input with respect to the deontic surface. The 90 triples
were built as a determinate-negation catalogue; the scoreboard's
hyperedge-incoherence shape is their natural consumer and was written for
exactly this emergent case ("the canonical emergent case has no incoherent
pair, only the triple" — the module's own comment); nothing connects them.
A feeder under the existing contract closes it (action 2).

## 2. The shape of incompatibility this repo can use

Given that earned entailment is closed for same-shape triple coding, the
usable shape is not one relation but a division of labor, all of it now
either live or one wiring fix from live:

**What the triples are for: determinate negation, not order.** The 94
warranted minimal incompatible sets, each with `error_rule_warrant/2`
provenance; `incompatibility_profile/2` hubs (eight divergence contexts
defeating two to four rules each — the counterexample classes);
`brandomian_neg/2` on a rule atom, returning the rule's {licence, context}
partner set as its concrete negation. These are viability-shaped per-rule
findings. Their proper consumers are retrieval, the teacher surface, and —
after action 2 — the deontic crisis path.

**What earns: shape change, not volume.** The one route that moved earned
entailment (21 → 25) was the a-fortiori context closure: reviewed
subclass judgments among contexts, each with warrant and basis, one refusal
recorded. Its extension is a data activity with receipt discipline (action
5, action 6), and its ceiling is the number of true nestings in the context
taxonomy — a measurement worth having, not a stall. The geometry table shows
the other earning shape the repo already owns: dense arity-2 restriction
profiles. Any future corpus that wants an entailment order should be coded
in one of these two shapes from the start; the emergence-maximizing triple
spec and the entailment-earning shape remain opposed, and choosing per
corpus is the design act.

**The guards, which are doing their jobs.** The vacuous-entailment refusal,
the arity-≥2 contract, the backstop's four explosion checks, the corrected
positive control (three materially true declared sets since `f5cb24b`), and
`incompatibility_earned_entailment_support/3` marking sparse witnesses from
inside. The register can mark thinness and cannot mark falsity; the
`even ⊨ composite` row stays as the standing reminder of which side of that
line is whose work.

**Shapes present but previously unnamed**, now named:

1. *The strict/non-strict split.* The live relations are plain replacement
   entailment; strictness (A earns B and B does not earn A) exists only in
   the offline register. A consumer that asks the live surface "does broad
   entail narrow" can get YES where the register says the earning runs the
   other way. Not a defect to fix by merging — the live witness op is
   honest about what it checks — but a distinction every downstream reader
   must carry, and none of the op documentation currently states it.
2. *Geometry as the existence proof* (§1.1): the repo already contains a
   corpus whose incompatibility data earns, and its shape is the reason.
3. *Refusals live only in commit messages.* The nestings file carries
   asserted rows only; the `the_divisor_is_not_ten` refusal — a true
   negative judgment that prevents a false entailment — is commit-attested
   and invisible to every artifact reader (action 5).
4. *The crisis pipeline as the corpus's natural consumer* (§1.4).

## 3. LX: what is actually LX for what here

The definition as this repo carries it (`formal/pml/mua_relations.pl:11-16,
352-360`): `lx_for(V_meta, V_base, Principle)` — the practices deploying
V_meta elaborate the practices deploying V_base, *and* V_meta makes explicit
the Principle merely implicit in V_base's practices. Both halves, L and X,
are required.

### 3.1 The claims with code behind them (measured)

The MUA graph holds 24 vocabularies, 32 practices, 28 `pv_sufficient/2`, 7
`pp_sufficient/3`, and **13 `lx_for/3` edges** (all counts from today).
Twelve of the thirteen relate strategy vocabularies (make-base explicates
associativity for counting-on; the column algorithm explicates carry
propagation for make-base; the cross-multiplication rule explicates product
invariance for the area model; and so on). One is deontic:
`lx_for(v_hermes_event_scoring, v_deontic_scorekeeper,
makes_explicit(runtime_event_deontics))`.

These edges are not decoration; three consumers give them inferential
consequences in running code:

- **The scorekeeper derives entitlement requirements from LX structure.**
  `requires_entitlement_via_mua/1` (`deontic_scorekeeper.pl:243-273`): any
  `result_of(Kind, ...)` whose practice deploys a vocabulary sitting on the
  meta side of an `lx_for/3` edge requires entitlement — holding the rule
  without the elaboration is committed-without-entitlement. Live on the
  worker at `hermes_worker.pl:467` and through the deontic ops.
- **Up-leveling's discharge check reads the LX witness.**
  `up_leveling.pl:112-125`: when the entitlement gap is MUA-witnessed, the
  witness names the base vocabulary whose deployment counts as the
  within-level grounding move, so objectivation is only offered when the LX
  route is genuinely exhausted.
- **The health layer demonstrates rather than asserts.**
  `mua_health.pl:96-110` accepts an `lx_for` edge as demonstrable only when
  executable practices deploy both vocabularies, and reports the specific
  failure otherwise (`:158-166`). The claims are checked against runnable
  kernels, not against themselves.

One dead wire found: `sequent_engine.pl:85` imports `lx_for/3` and
`grounding_metaphor/2` and no clause in the engine or its five included
axiom files calls either (measured by grep over the engine and every
include). Action 7 removes it.

### 3.2 The claims without code, answered sharply

**Is the incompatibility vocabulary LX for the strategy automata?** No — and
the failure is in L, not X. The X half is real and has a measured receipt:
`scripts/checks/error_rule_automaton_join.pl` proves for three divergence
contexts (gap order, written-numeral order, unaligned decimal operation)
that the atom the automaton computes and the context the coded triple
carries are one name — the triple vocabulary makes explicit the boundary
norm the automaton's practice holds implicitly, and a gate keeps them from
drifting apart. But the L half fails on the facts: the triples were coded
from research-corpus readings by the extraction pipeline, not algorithmically
elaborated from the practices sufficient for the automata. Explication
without elaboration is a real Brandomian status; it is not LX, and no
`lx_for` row should say it is. The a-fortiori battery sharpens this from the
other side: it proves the loaded automata decide *neither endpoint* of any
shipped nesting, so not even the closure's earned entailments are
elaborated from practice — they rest on named mathematical warrants. If a
future nesting is certified by running an automaton over an input battery,
that specific edge would have an honest L; the battery is already built to
record exactly that upgrade.

**Is PML LX for the deontic scoreboard?** Nothing in the tree claims it, and
the material relation runs the other way: the scoreboard is cell-free (its
module never touches the twelve operators — confirmed in today's PML status
report), and PML's twelve cells are not registered as a vocabulary in
`mua_relations.pl` at all. The one deontic LX edge points from event scoring
to the scoreboard, not from PML. If someone wanted the claim "PML makes
explicit the scoreboard's implicit structure," the honest test is the same
one `mua_health` applies everywhere: name the practices that deploy PML's
cells, show they elaborate scorekeeping practice, and show the cells
expressing what scorekeeping left implicit. On present evidence the cells
classify how contents are held (reader contract, polarity costs) and the
scoreboard tracks what holding commits one to; they are siblings over the
same discourse, not an LX pair.

**Where the L of LX genuinely lives:** in the practice-to-practice layer.
`pp_sufficient/3`'s mechanisms are named algorithmic elaborations, the
scorekeeper turns them into material inferences
(`mua_derived_material_inference/3`), and `up_leveling.pl` uses "the
within-level layer is algorithmic elaboration" as its structural trigger:
elaboration yields commitments, never entitlements, so an entitlement gap
that survives closure is provably beyond the within-level layer. That
argument is the manuscript's thesis running as a precondition check, and it
is the strongest LX-adjacent construction in the tree.

## 4. Diagonalization: making the citation honest

### 4.1 The dangling citations (measured)

Two in-tree artifacts cite research documents that exist only in the
read-only formalization archive:

- `formal/learner/up_leveling.pl:204` — the witness's `caveat` field cites
  `docs/research/2026-06-18-up-leveling-and-diagonalization.md` as the
  adversarial review backing its "self-reference, not Cantorian
  diagonalization" disclaimer.
- `curriculum/lesson_gap.pl:17` — the module doc cites
  `docs/research/2026-06-18-anticipation-and-the-unanticipated.md` for the
  "encoded but unanticipated" reading of its gap computation.

Neither path resolves in this tree (measured; `docs/research/` has no
2026-06-18 files). Both archive documents were read today. The up-leveling
review is the receipt for every honesty clause in the module: it records
that the first draft overclaimed, that the escape was once hard-coded, that
`objectivated/1` escapes by functor distinctness rather than diagonal
negation, and that the module is a detector. The anticipation document is
the argument that the licensed-but-unanticipated difference is structural
(sound anticipation cannot contain "the move you did not anticipate") and
names the monitoring chart as the anticipation and the registry as the
licensed set.

**What would make the citations honest: port the two documents,** with three
verified corrections, because the archive text describes the module as it
stood in June and the hermes copy has since grown:

1. The review's item 5 and its limits section say the discharge check exists
   "for the area-model case only." Stale: `up_leveling.pl` now carries three
   discharge verdicts including the MUA-witnessed case and the
   monotone-closure withdrawal case (`:127-160`, measured).
2. The review references `exploratory/up-leveling-spike/`,
   `more-zeeman/matrix.html`, and `design/00_PROJECT_OVERVIEW.md` — archive
   paths that must be marked as archive paths, not left looking in-tree.
3. The anticipation document's worked example (eighteen addition strategies,
   five anticipated, thirteen unanticipated) is a dated count; the port
   should date-mark it or re-run it against the live registry.

Action 4 carries the port. The third 2026-06-18 document, the deontic
diagonal argument, is cited from the 07-28 report by its explicit archive
path — an honest cross-repo citation needing no port.

### 4.2 What the repo would need for the diagonal itself, and why the port is enough

The 07-28 addendum §9.3 settled the scopes and is not re-argued here: the
register's blindness is invariance under relabeling, no self-reference
anywhere in it; the corpus is rich enough to pose the diagonal question
(Robinson Q instance-wise, prime utilities, Euclid's escape construction)
and has not posed it; a posed version would deliver a statement about
derivability in the composition, not about material adequacy, which stays
outside at every scope. The four missing pieces are recorded there
(content→numeral map, set coding, represented relation, arithmetized
syntax with substitution and derivability), and building them is not
proposed: the deliverable would be borrowed prestige.

What the repo already carries is better, and one of today's findings is
that it carries it in code nobody had connected to the argument:
**`curriculum/lesson_gap.pl` computes the finite form of the deontic
diagonal's conclusion.** The archived diagonal argument derives that a
sound anticipation cannot cover every licensed move; its own "next build"
section asks for the licensed set and the anticipation set computed
separately and their difference exhibited. `lesson_gap.pl` does exactly
that at lesson grain — registry coverage minus chart anticipation, per
lesson, with the vocabulary-mismatch and absent-source boundary cases
guarded — by set difference, with no self-reference, which is precisely
what §9.3 predicts a finite artifact can and should do. The port (action 4)
makes this lineage citable; nothing further needs building for the
diagonalization thread to be honest.

## 5. Vanishing points: the separation stands, the census is missing

### 5.1 The mechanism question, answered

The vanishing-point mark (`formal/sequent/automata.pl:58-85`) is an
attributed variable whose `attr_unify_hook` refuses every concrete binding
while letting the mark propagate variable-to-variable. Two consumers,
measured: the embodied prover's `construct_proof/4` turns any sequent
carrying the mark into `hollow(RuleName)` — the node stands, its warrant is
withdrawn, and hollowness propagates upward (`embodied_prover.pl:116-123`);
and the pragmatic pack uses the mark to model the I-feeling, generating the
one incoherence PML natively contributes: `n(represents(C_Id, I_f))` is
incoherent whenever the identity claim is finite and the I-feeling carries
the mark (`pragmatic_axioms.pl:109-130`). The mark is generative — a refusal
of binding that produces exclusions — not a declared edge.

`up_leveling.pl`'s `erasure` field is a string constant
(`pragmatic_metavocabulary_not_supplied_by_formalism`) in a witness dict.
Its module comment (`:20-27`) gives the reason it is kept separate from the
prover's mechanism: the up-level witness has no sequent and no proof search,
so deriving the field from the prover "would mean fabricating a marked
sequent purely to harvest a local atom."

**Verdict: the separation is still the right call.** The two marks stand in
different relations to the boundary. The vanishing point marks a *semantic*
limit — a reference that cannot be made concrete, and any proof that
touches it loses warrant. The erasure field marks a *pragmatic* hand-off —
the content of the next discursive level exists (people supply it; the
a-fortiori closure is a measured case of the practice doing so) and the
formalism does not carry it. Joining the mechanisms would encode the false
claim that these are one limit. The embodied prover's own header records
the same discrimination from the other side: it withdrew the word "erasure"
for hollow nodes because Derridean erasure keeps the crossed term legible
and the hollow mechanism does not. The vocabulary is already carved
correctly; the carving should not be undone.

### 5.2 What is genuinely missing: the limits have no census

What today's four-thread traversal kept running into is that the repo marks
its own limits in at least seven distinct, well-built forms — the hollow
proof node; the vanishing-point mark; the erasure field;
`sparse_witness` support marking; `discharge_status/2`'s
not-implemented verdict; the `authored(unmodelled(...))` provenance edges in
`commitment_automata.pl` ("the unmodelled edges are the finding, not the
filler"); the licensed-but-unanticipated difference — and no surface can
enumerate them. Each marker is a Gaifman jump: a later token saying truly
that an earlier one stops. The collection of jumps is itself a finding
about the system (it is the honest content of "built to break" for a
funder or reviewer), and today it is assembled only by hand, by reading
seven modules. Action 8 proposes a generated census, with the fault-line
caveat stated there: it must read code structure, not comment text, and it
earns its place as an abstraction deliverable under the counterweight
directive, not as ontology.

## 6. What could not be established

- Whether the a-fortiori closure's omission from `public_discovery_context/1`
  was deliberate. The module comment around the consult is silent on
  serving; the closure landed this week; I read it as an oversight, but the
  fix (action 1) is stated so that if there was a reason, refusing the brief
  surfaces it.
- Whether any consumer *wants* strict entailment on the live surface. The
  strict/non-strict split (§2, item 1) is documented here and in the ops'
  favor; no proposal changes live semantics, and the question of a strict
  live op is left open deliberately.
- The co-reference of `pml_wire.pl`'s `unlicensed(...)` atoms with registry
  misconception atoms (the §6 join in the entailment report) remains
  plausible and unconfirmed; I did not chase provenance today, and no action
  below depends on it.
- `mua_health`'s full report was not executed today (its clauses were read;
  the demonstrations were not run). The claim that LX edges are
  demonstrable-by-execution is the module's contract, verified by reading,
  not by a fresh run.
- The archived anticipation document's registry counts (eighteen/five/
  thirteen) were not re-verified against the live registry; the port brief
  requires doing so or date-marking them.
