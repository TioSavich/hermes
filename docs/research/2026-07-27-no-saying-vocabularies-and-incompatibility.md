# The field's vocabularies for saying no, sorted by PML, and what each implies for an incompatibility triple

2026-07-27. Written before anyone fills `error_instances.student_rule`,
`.valid_domain`, and `.incompatible_with`, so that the filling is done against a
vocabulary derived from the material rather than one guessed at.

## Scope, method, and what this cannot establish

Read: `/Users/tio/Desktop/Theoretical Literature Review/22ways.tex` (a draft the
owner stopped writing and calls half-baked; treated here as evidence about the
field's published lexicon, never as a scheme to adopt), the 2,151 per-article
extraction JSONs under `extraction_results/`, `data/research/research_shared.db`,
`formal/incompatibility/*.pl`, `formal/pml/*`, `knowledge/misconceptions/pml_wire.pl`,
and `/Users/tio/Documents/GitHub/umedcta-formalization/design/07_PML_INTEGRATION.md`.

Every count below was derived by running against those files today. Counts I
could not derive, I do not state. Two places where I could not reproduce a
number from the draft are flagged in place.

What this cannot establish: the extraction corpus is itself the output of a
two-stage AI pipeline (NotebookLM, then a synthesis agent), and its
`vocabulary_used_raw` field records verbatim in-text phrasing rather than a coded
family. So every frequency here undercounts, and undercounts unevenly. Ratios
between families are more robust than any single rate. My candidate term list was
hand-built against 9,044 distinct comma-separated phrases in that field, so the
enumeration below is a floor, not a census. Nobody has read the 2,151 articles.

## 1. The count

The draft's title and abstract say 22. Its own method section says "over 35
distinct terms" (`22ways.tex:461`). Neither number is enumerated anywhere in the
document. Counting the distinct terms the draft actually lists across its three
term-lists — the four Carspecken scenes (§2.2), the six coding families (§3.3),
and the ten groups (§4.1) — gives **52**, with four more named in body prose and
in no list (syntactic bug, bilateral perturbation, dyadic negative,
incompatibility itself).

So 22 is not a finding about the field. It appears to be a legacy number the body
outgrew, and it should not organize anything.

Against the extraction corpus (3,241 error records, all carrying
`vocabulary_used_raw`):

- **At least ten of the draft's 52 have zero attestation anywhere in the 3,241
  records**, in any field: *task propensity, defective phenomenological analysis,
  identity of failure, productive struggle, Key Developmental Understanding,
  preformal production, meaning builder, Contingent Moment, illusion of
  understanding, mathematical pathologies*. (*Struggling learner* also measures
  zero in the database's vocabulary field.) The source articles are present —
  Heyd-Metzuyanim 2013, Karsenty et al. 2007, Streefland 1978 all have rows in
  `articles` and error records extracted from them. What is absent is the label.
  Streefland's records carry "defective understanding" and "dominance of
  meaning"; Heyd-Metzuyanim's carry "ritual participation", "syntactic routine",
  "identifying discourse". These terms are the draft's own second-order names for
  what those authors described, not the field's first-order vocabulary. I did not
  read the original PDFs, so I cannot say whether the authors ever used the
  labels; I can say the structured extraction of their articles does not contain
  them.
- Ten more are attested exactly once: *error pattern, slip, springboard for
  inquiry, child-method, canonically incorrect, falsely true, meaning blindness,
  dyscalculia, mediant/baseball addition, decontextualized ratio*.
- **At least 24 terms attested four or more times in `vocabulary_used_raw` are
  named nowhere in the draft's 52**: additive-versus-multiplicative reasoning
  (34), rote/instrumental learning (23), scheme constraint (19), rigidity or
  inflexibility (16), concept image / concept definition (16), conflation (15),
  representativeness and gambler's fallacy (14), surface features and key words
  (13), didactical contract (10), instrumental understanding (9), systematic
  error as distinct from slip (8), action/process conception (8), splitting
  failure (7), compartmentalization (7), lack of closure (6), equiprobability
  bias (5), intuitive rule (5), illusion of linearity (5), gap thinking (5), face
  value (4), lacuna (4), absolute-versus-relative thinking (4), calculational
  orientation (4), the "do something" signal (4). Four more appear one to three
  times: depletion, mathematics anxiety, commognitive conflict, didactical
  obstacle.

**Derived floor: about 69 distinct terms** (41 of the draft's 52 attested, plus
28 attested and unnamed). The ceiling is unknown and my method cannot find it.

### What of the draft's carving holds

The **negates / preserves** distinction holds and is the most useful thing in the
document. Asking of each term what it says no to and what it leaves standing does
separate terms that otherwise read as synonyms, and it is the question the
database columns are for.

The **objective / subjective / identity-constitutive** carving does not hold as a
carving. It is a one-dimensional ordering imposed on what is at least two
dimensions. Three specific failures:

1. It puts *perturbation* and *productive struggle* in the same box (Scene 3).
   These differ in what happens to the learner's commitment, not in whose
   validity is at stake. §2 below separates them.
2. It reads Scene 1 → Scene 4 as a progression of increasing constitutiveness,
   which makes *bug* (Scene 1) less constitutive than *perturbation* (Scene 3).
   But *bug* names a rule and *perturbation* names an episode, and it is the
   rule-naming that makes a term encodable. The ordering runs against the grain
   of the property that matters here.
3. It has no place for the largest attested family after the objective one. The
   normative-expansive terms (*overgeneralization*, *natural number bias*,
   *met-before*, *gap thinking*, *illusion of linearity*) are scattered across
   Scenes 2 and 3 and the "bias/interference" family, when they share one
   structure and it is the structure the engine can eat.

On the draft's distributional claims (objective ≈ 64%, perturbation ≈ 4%, ~470
relevant articles): I could not reproduce these and the denominators differ — the
database now holds 2,682 articles against the draft's 490. Measuring per-article
presence in `vocabulary_used_raw` across the 2,141 journal-directory extractions
gives the objective family at 15.1%, the normative family at 4.4%, the
experiential family at 1.3%, and *perturbation* alone at 0.3%. These measure a
stricter thing than the draft did and undercount throughout. The comparison worth
carrying forward is the ratio: objective to normative runs about 3.4:1 here, not
the 16:1 the abstract's figures imply. That matters, because the normative family
is the encodable one.

## 2. PML as the sorting space

Read from `formal/pml/pml_operators.pl`, `formal/pml/README.md`, and
`umedcta-formalization/design/07_PML_INTEGRATION.md`. PML is a material-inference
calculus in Brandom's sense; the operators tag and classify a payload rather than
quantifying over accessibility relations. Three modes of validity crossed with
four polarized operators give the twelve terms, formed by nesting a mode over a
polarity: `s(comp_nec(P))` and so on.

Modes, per the integration document:

- `s/1` Subjective: first-person, traces, embodied experience.
- `o/1` Objective: third-person, Prolog's native arithmetic, the world.
- `n/1` Normative: second-person, the teacher's vocabulary, community norms.

Polarities, per the same document:

- `comp_nec` (↓) compressive necessity: fixation, narrowing, crystallizing.
- `exp_nec` (↑) expansive necessity: release, opening, liquefying.
- `exp_poss` (↑) expansive possibility: potential for release.
- `comp_poss` (↓) compressive possibility: temptation to fixate.

The integration document already assigns no-saying: "Teacher's 'no' is `comp_nec`
in the normative domain," and its rhythm table gives "Teacher rejects a claim →
`comp_nec` — Ruling out, information, narrowing."

That yields two axes, which is the correction the four scenes need:

- **The mode says which validity the no-saying claims.** O-mode: the mathematics
  says no. N-mode: a community says no. S-mode: the learner's own prior
  expectation says no.
- **The polarity says whether the no forecloses or opens.** Compressive: the no
  narrows what remains available. Expansive: the no releases something into a
  domain where it holds.

The draft's "what is negated / what is preserved" is the payload and the mode;
its "what is elevated" is the polarity. PML carries the third column as a formal
position rather than as prose, which is the reason to use it here.

### What PML has no cell for

PML has three modes. Carspecken has four validity domains, and identity is the
one PML does not carry. So identity no-saying does not sort into a PML cell; it
sits off the space rather than in a corner of it. Two readings, both defensible:

*Steelman for the omission being correct.* PML's modes are modes of **validity** —
each answers a question of the form "on what ground could this be challenged?"
Identity claims are not challengeable on a ground; Heyd-Metzuyanim's point is that
the teacher's third-person narrative *constitutes* what it names. A constitutive
act has no validity mode because it is not answerable in the way a claim is.
Excluding it keeps PML honest about being a calculus of commitments.

*Rebuttal.* Carspecken treats identity as a validity domain precisely because
identity claims *are* redeemable and contestable, and a framework whose
philosophical hierarchy runs Carspecken above Brandom has some obligation to
carry all four. Dropping the fourth means every identity-constitutive no-saying
in the corpus must be either recoded into another mode, which distorts it, or
dropped, which loses it.

I do not resolve this. It is a real fork and it belongs to the owner. What I can
say is that the current repo takes the first branch by default, silently, and that
the silence should be replaced by a recorded decision.

### The cells actually occupied today

Counting `[son](comp_nec|exp_nec|exp_poss|comp_poss)(` across every `.pl` in the
repo, excluding worktrees: 1,957 occurrences, distributed

| cell | occurrences |
|---|---:|
| `s(comp_nec` | 1,782 |
| `s(exp_poss` | 122 |
| `n(comp_nec` | 12 |
| `n(exp_nec` | 10 |
| `s(exp_nec` | 8 |
| `o(exp_nec` | 8 |
| `o(comp_nec` | 6 |
| `n(exp_poss` | 4 |
| `n(comp_poss` | 4 |
| `s(comp_poss` | 1 |
| `o(exp_poss` | 0 |
| `o(comp_poss` | 0 |

Two cells of twelve carry 97% of the usage. Ten cells share the remaining 53
occurrences, and two are empty.

The concentration has a single cause. `knowledge/misconceptions/pml_wire.pl`
carries 820 `misconception_pml/2` rows, and **every one of the 820 has the
identical signature** `s(comp_nec(unlicensed(_)))`. One mode, one polarity, one
payload wrapper, for the entire wired misconception corpus. §4 argues this is the
same gap as the empty `valid_domain` column, appearing in a second place.

Separately, the Lakoff-Núñez grounding metaphors are carried as bare `o(...)`
with no polarity operator at all — 578 occurrences of `o(grounded(`. Their
polarity is carried structurally, by pairing a grounding commitment with a break
trigger, rather than by an operator. That structural choice is what makes them
searchable, and §6 returns to it.

## 3. The vocabularies, sorted

Columns: what the term negates, what it leaves standing, its PML cell, and the
shape of incompatibility set it implies. PML assignments are my reading applied to
the integration document's own mode and polarity glosses; where a term is
genuinely ambiguous I say so rather than forcing it.

Notation for shapes. A Hermes hyperedge is a sorted ground list that cannot be
jointly held. `|S| = 2` is a **pair**; `|S| ≥ 3` with every proper subset coherent
is an **emergent** set, and only emergent sets count as findings under
`find_emergent_hyperedges.pl`'s criterion. This is the single most consequential
fact for everything below: **a vocabulary that yields only pairs is structurally
excluded from the result, no matter how many rows carry it.**

### 3.1 Objective compressive — `o(comp_nec(...))`

**Terms.** misconception, error, mistake, incorrect, wrong answer, flawed
thinking, difficulty, deficiency, confusion, limited understanding, lack of
understanding.
**Sources.** Mack 1995; Harel & Sowder 2005; Park, Güçler & McCrory 2013; and by
a long way the default across the corpus (178 records name *error*, 132
*misconception*, 140 *confusion*, 108 *difficulty*).
**Negates.** The student's belief.
**Preserves.** The mathematical truth, taken as given.
**Shape.** `{student_belief(P), mathematical_fact(neg P)}` — a **pair**, and
necessarily a pair. The vocabulary asserts there is nowhere the belief holds;
that assertion *is* the term's content. A `valid_domain` is not missing from this
family, it is denied by it.
**Consequence.** Encodable and inert. Filling 2,400 deficit-coded rows into pairs
would add 2,400 hyperedges and zero emergent sets. This is the family the corpus
is mostly made of, and it is the family that cannot contribute.

### 3.2 Objective compressive, procedural variant — `o(comp_nec(...))`

**Terms.** bug, buggy algorithm, mal-rule, error pattern, faulty procedure, slip,
systematic error, syntactic bug.
**Sources.** Brown & VanLehn 1980; Ashlock 2010; Nesher & Peled 1986; Peled &
Segalis 2005. Attested at 23 records for *bug*/*buggy*, 8 for *systematic error*,
3 for *mal-rule*.
**Negates.** A subroutine in the student's procedure.
**Preserves.** The rest of the procedure.
**Shape.** Same cell as 3.1, but the payload is a **rule** rather than a belief,
and that difference is decisive. A bug survives because it agrees with the
sanctioned procedure on some input class — "always borrow left" is correct
whenever no zero is crossed. So a bug has a valid domain even though the
vocabulary does not name one, and the shape available is the **triple**
`{rule(R), consequence_R_licenses(C), input_where_C_fails}`.
**Consequence.** Tractable, but the valid domain has to be supplied by the coder,
because the term withholds it. Nesher & Peled's move from *bug* to *transitional
rule* is the field noticing exactly this.

### 3.3 Normative compressive — `n(comp_nec(...))`

**Terms.** violation, inappropriate strategy, didactical contract (as breach).
**Sources.** Brousseau via 10 records naming *didactical contract*; 7 records name
*violation*.
**Negates.** The student's conformity to a rule of the practice.
**Preserves.** The rule and the practice.
**Shape.** `{student_move(M), community_commitment(C)}` — a **pair**, but the
second relatum is a commitment held by someone nameable, which the pair in 3.1
lacks. Adding the community as a third element (`held_by(C, Community)`) does not
make it emergent, because the pair is already incoherent without it.
**Consequence.** Encodable, inert for the emergence search, valuable for the
deontic scorekeeper, which is where it already belongs.

### 3.4 Normative expansive — `n(exp_nec(...))`

**Terms.** overgeneralization, natural number bias, whole number bias,
epistemological obstacle, met-before, primitive model, intuitive rule, illusion
of linearity, gap thinking, equiprobability bias, decontextualized ratio,
additive-for-multiplicative reasoning, absolute-for-relative thinking, face value,
lack of closure, mediant / baseball addition, mathematical pathologies.
**Sources.** Van Hoof et al. 2015; Tall 2013; Fischbein; Stavy & Tirosh; De Bock
et al.; Clark, Berenson & Cavey 2003; Pearn & Stephens 2004 via Clarke & Roche
2009; Sriraman & Dickman 2017; Lecoutre. Attested at 60 records for
*overgeneralization*, 34 for additive-versus-multiplicative, 21 for number bias,
14 for primitive model, 13 for epistemological obstacle, and single digits for
each of the rest.
**Negates.** The scope of a rule's validity, not the rule.
**Preserves.** The rule, together with the domain where it holds.
**PML reading.** Normative, because what says no is a community's sanction rather
than the world. Expansive necessity rather than expansive possibility, because
the term *asserts* the rule holds elsewhere rather than allowing that it might —
that assertion is what makes an overgeneralization an overgeneralization rather
than an error. A reader who thinks the retention is only conjectural would put
these at `n(exp_poss)`; I do not think the corpus supports that, since the terms
name their valid domains (whole-number arithmetic, prior valid experience,
proportional contexts) rather than gesturing at one.
**Shape.** `{rule(R), sanctioned_in(R, D), current_context(D')}` with `D ≠ D'`.
Every pair coherent: the rule alone is fine, the rule with its domain is fine, the
context alone is fine. Only the triple fails. **This is an emergent set by the
search's own criterion**, and it is the same shape as the four Lakoff-Núñez
hyperedges already in the relation.
**Consequence.** This is the tractable family, and by attestation it is the second
largest. It is also the family that maps onto the database's three columns with no
interpretive leap, because the columns were evidently designed for it.

### 3.5 Subjective, at the tension node — `s(exp_poss)` against `s(comp_poss)`

**Terms.** perturbation, severe perturbation, bilateral perturbation,
disequilibrium, cognitive conflict, scheme constraint, depletion; and on the two
outcomes, productive struggle, accommodation, child-method (expansive) against
rigidity, inflexibility, rote repetition (compressive).
**Sources.** Olive & Steffe 2002; Steffe 2002, 2004; Hackenberg 2007, 2010;
Hackenberg & Tillema 2009; Warshauer 2015. Attested at 17 records for
*perturbation*, 19 for *constraint*, 12 for *cognitive conflict*, 16 for
rigidity, 3 for *depletion*.
**Negates.** The student's own prior expectation. Neither relatum is a community
norm; the conflict is internal to one learner.
**Preserves.** The learner's capacity to reorganize.
**PML reading, and the correction to the four scenes.** The integration
document's rhythm table puts tension at `exp_poss OR comp_poss` — a choice point,
not a cell. So *perturbation* names the node itself, and the field's terms for what
follows sort by polarity: *productive struggle* and *accommodation* are the
expansive branch, holding the not-knowing open; *rigidity* and rote repetition are
the compressive branch, the doubling-down the document calls the bad infinite.
The four-scene carving puts *perturbation* and *productive struggle* in the same
box. PML separates them, and the separation is the pedagogically consequential
one.
**Shape.** `{s(commitment_now), s(expectation_prior), o(observed_outcome)}` — a
genuine triple. But the atoms are indexed to one learner at one moment, and the
relation's contents are ground global terms. Encoded episodically, 3,241
perturbation records give roughly 3,241 singleton atoms with no shared structure,
and the emergence search finds nothing because emergence requires the same three
atoms to recur.
**The fix that makes it tractable.** Encode the **scheme**, not the episode. "The
part-whole fraction scheme cannot produce 8/7" is a fact about a scheme, shared
across every learner who holds it, and it has exactly the shape of 3.4:
`{scheme(part_whole), licenses(fraction_le_one), task(improper_fraction_demanded)}`.
Olive & Steffe's "severe perturbation" record (database row 43995, "How can a
fraction be bigger than itself?") is a scheme-level fact written as an episode.
This is my inference, not something the sources say; but the repo already carries
the machinery for it in the comparison automata and their viability contexts.

### 3.6 Developmental — no single cell

**Terms.** necessary error, transitional rule, preformal production, Key
Developmental Understanding, action/process conception.
**Sources.** Tzur 2004; Nesher & Peled 1986; Simon, Placa & Avitzur 2016;
Dubinsky's APOS via 8 records. Attested at 6 records for *necessary error*, 8 for
action/process conception, 2 for *transitional rule*.
**Negates.** The contingency of the error. It had to happen.
**Preserves.** The developmental trajectory.
**Shape, and where it stops.** The incompatibility half encodes as 3.4 does. The
*necessity* half does not, and this is a limit worth naming precisely:
`incompatible_set/1` is symmetric and atemporal, and the claim "R had to precede
U" is neither. A necessary error is not more incompatible than an ordinary one.
Forcing the trajectory into the relation would record an ordering the relation
cannot represent, and the reading back out would be false. The trajectory claim
belongs to the ORR cycle and the learning-trajectory machinery, and should be
carried there with a join to the hyperedge rather than inside it.

### 3.7 Hermeneutic, second-order — `n(exp_nec(neg(o(comp_nec(...)))))`

**Terms.** kernel of correctness, springboard for inquiry, canonically incorrect,
meaning builder, Contingent Moment.
**Sources.** Karsenty, Arcavi & Hadas 2007; Borasi 1994. Attested at 2 records for
*kernel of correctness*, 1 for *springboard*, 1 for *canonically incorrect*.
**Negates.** A prior reading — the deficit interpretation — not the student's
claim.
**Preserves.** The student's reasoning as partially correct.
**Shape.** Both relata are researcher commitments, so the payload of the negation
is itself a no-saying. The PML syntax expresses this by nesting, since payloads
are arbitrary terms: releasing an objective compression. **Nothing in the repo
currently nests operators this way.** The structure is available and unused.
**What it needs that the database lacks.** To encode a second-order negation you
must know whose first-order reading is being negated. `error_instances` has no
column for the attributing author, and `locus_of_attribution` records where the
error is placed, not who placed it. Without that, this family cannot be encoded
at all.

### 3.8 Representational — `n(comp_nec(...))` with an artifact payload

**Terms.** defective phenomenological analysis, meaning blindness, procedural
embodiment, task propensity, didactical contract, didactical obstacle.
**Sources.** Streefland 1978; Williams 1972 via Bell, Swan & Taylor 1981;
Gravemeijer et al. 2016; Brousseau. Attested at 3 records for *procedural
embodiment*, 10 for *didactical contract*, 1 for *meaning blindness*, 0 for the
other two.
**Negates.** The adequacy of a representation, task, or curriculum.
**Preserves.** The student. The problem is placed in the system.
**Shape.** `{curriculum_commitment(C), student_activity(A), mathematical_commitment(M)}`
— a genuine triple, and the only family whose hyperedges are about **artifacts**,
which are shared across learners and therefore aggregate. The database already
supports the attribution: `locus_of_attribution` is `curriculum` for 110 rows and
`task` for 53. This family is more tractable than its attestation suggests.
**One exception.** *Task propensity* is not a hyperedge. Gravemeijer et al. name a
feedback loop: tasks are designed to be completable by procedure, which trains
procedural thinking, which generates the errors the technical vocabulary then
diagnoses. That is a cycle, and a cycle is not a set that cannot be jointly held —
every element of it is held, which is the complaint. Encoding it as an
`incompatible_set/1` would misdescribe it.

### 3.9 Diagnostic — `o(comp_nec(...))` over an entitlement

**Terms.** falsely true, illusion of understanding, error pattern as data.
**Sources.** Named in the draft; 1 record attests *falsely true*.
**Negates.** The adequacy of the assessment, not the answer.
**Preserves.** The diagnostic information.
**Shape.** `{answer_is_correct, reasoning_is_R, commitment(correct_answer_entitles_understanding)}`
— a clean emergent triple. Each element alone is unobjectionable; the three cannot
be held together. Structurally this is as good a candidate as 3.4. It is rare in
the corpus, but rarity here is a sampling fact about a two-stage retrieval
pipeline, not a structural fact about the vocabulary.

### 3.10 Identity-constitutive — no PML cell

**Terms.** identity of failure, ritual rule following, dyscalculia, struggling
learner, positioning.
**Sources.** Heyd-Metzuyanim 2013. Attested at 7 records for *ritual*, 9 for
identity or positioning, 1 for *dyscalculia*, 0 for *identity of failure* itself.
**Negates.** The student's mathematical personhood.
**Preserves.** On the draft's own account, nothing.

This one I judge genuinely resistant, and I want to be exact about why rather than
gesturing at it.

The relata are not commitments about mathematics. "S is a certain kind of
mathematical person" is not a content that can be *held together* with other
contents — which is precisely the operation `incompatible_set/1` is about.
Heyd-Metzuyanim's finding is that the label constitutes what it claims to
describe. An incompatibility relation records what cannot be jointly held; it is
not constitutive of anything. Encoding an identity claim into it would model the
labelling as a **proposition about** the student rather than as an **act that
produces** the student, which inverts the finding the vocabulary was coined to
carry. That is a category error, and it is not repaired by care in the payload.

There is a partial encoding that is honest, and it does not encode the identity.
Put the incompatibility in the **teacher's** score, where the commitments actually
are:

```
{ n(comp_nec(teacher_narrative(S, unable))),
  o(evidence(S, did_X)),
  n(exp_nec(recognition_requires_attributing_reasons)) }
```

Every relatum is propositional, every relatum is somebody's commitment, and the
set is emergent. What it records is that a teacher cannot hold the deficit
narrative, the evidence, and the recognitive commitment together. Whether that
captures what Heyd-Metzuyanim documented is doubtful — she is describing a
process by which the narrative reshapes the interactions that then confirm it, and
the encoding above records a static incoherence, not a process. I would encode it
and label it as a partial reading, not present it as the thing.

### 3.11 Refusal — outside the relation entirely

**Terms.** the dyadic negative (Carspecken), opting out, "I forgot."
**Sources.** Empson 2003 (Pho); Carspecken 1999. The draft names this and says
plainly that no term in its taxonomy captures it.

This is the sharpest limit, and it is a structural one rather than a matter of
missing data.

A refusal is not a commitment that conflicts with another commitment. It is a
withdrawal from undertaking any commitment at all. In a relation whose only
primitive is "these cannot be held together," the empty commitment set is coherent
with everything. **Refusal is maximally compatible, and a relation defined by
incompatibility therefore has no way to register it.** It cannot be brought in by
adding data, because more data is more commitments and the refusal is the absence
of one.

This is the same shape of result the repo names elsewhere as the erasure boundary:
the place where the formalism stops and human judgment takes over is not a gap in
coverage but a property of the relation. Pho exercises the autonomy every account
of learning must presuppose and none can contain. The right response is to record
that the relation excludes it, not to find a clever encoding.

## 4. What can enter the engine, and the one gap that appears twice

Sorting §3 by the emergence criterion:

**Can enter and can produce emergent sets:** 3.2 (procedural, once the coder
supplies the agreement class), **3.4 (normative expansive)**, 3.5 (subjective,
once recoded from episode to scheme), **3.8 (representational, excluding task
propensity)**, **3.9 (diagnostic)**.

**Can enter, cannot produce emergent sets:** 3.1 (objective compressive) and 3.3
(normative compressive), because both are structurally pairs. They belong in the
relation for the deontic scorekeeper's use and should not be counted toward the
hyperedge result.

**Cannot enter as they stand:** 3.6's necessity claim (the relation is atemporal),
3.7 (no attribution column exists), 3.10 (category error, partial encoding
available and should be labelled as partial), 3.11 (structurally excluded).

### The `unlicensed/1` finding

The 820 rows of `pml_wire.pl` all read `s(comp_nec(unlicensed(X)))`. Take that
apart:

- `s(...)` places the commitment in the student's subjective field, which is a
  defensible reading of where a student's rule is held.
- `comp_nec(...)` marks it as compressively held. Also defensible.
- `unlicensed(X)` is a **one-place** predicate. It says X is not licensed. It does
  not say by whom, and it does not say where X *is* licensed.

That second omission is the whole problem. `unlicensed/1` discards the domain of
validity by construction, exactly as the objective-compressive vocabulary in §3.1
does. Any content wearing that wrapper can yield a pair at most, because there is
no third element to be had. Eight hundred and twenty rows are wired into a form
that cannot participate in the finding.

Compare the Lakoff-Núñez encoding, which is two-place in effect:
`o(grounded(M))` names the metaphor, and a separate `compiled_break/2` names the
trigger where it stops grounding. The valid domain is not in either fact; it is
the complement of the break set, and it is recoverable. That is the difference.

**So the empty `valid_domain` column and the `unlicensed/1` wrapper are one gap in
two places.** Both drop the "valid somewhere" half of a determinate negation. Both
are the reason the search finds only Lakoff-Núñez. Fixing one without the other
leaves the loop open.

## 5. The three columns

### What each must contain

**`student_rule`** — a rule stated as a **total operation on a stated input
class**, independent of the task that elicited it. Not a description of a wrong
answer; not a noun phrase for a deficiency. The test: could a reader run it on an
input the article never mentions? "Adds numerators and denominators" passes.
"Struggles with improper fractions" fails. This becomes the PML payload, and it is
what the current `unlicensed(X)` wrapper holds in an unreadable form.

The three rows already populated (ids 288, 290, 291) are the right shape. Row 288:
"Always subtract smaller from larger regardless of position." Runnable.

**`valid_domain`** — the input class or normative framework on which the rule
agrees with the sanctioned one. Two requirements the current schema does not meet:

1. It must be stated as a **class**, not an example. "Pairs with equal
   numerators," not "1/3 and 1/4."
2. **An empty valid domain must be distinguishable from an unfilled column.** A
   rule with no domain of validity is a real and reportable finding — it says the
   vocabulary really was objective no-saying and the term meant what it said.
   Recommend a companion column `valid_domain_status` taking `stated`, `inferred`,
   `none_found`, `not_yet_coded`, so that NULL never has to carry two meanings. As
   it stands, three rows have a non-null `valid_domain` and zero have a populated
   one, which is already the confusion in miniature.

**`incompatible_with`** — the **commitment** the rule conflicts with, named as
somebody's commitment together with the context in which it is held. Not "correct
fraction addition." Rather: "the community's commitment, in rational-number
addition, that combining fractions preserves a common unit." The named holder is
what makes the relation Brandomian rather than a comparison against a fact, and it
is what §3.7 needs and cannot get.

### The triple that goes to the relation

Matching the shape of `compiled_break(measuring_stick_incommensurability, ...)`,
which is `[the metaphor grounds, what it licenses, an input where the licensed
result fails]`:

```prolog
incompatible_set([ s(comp_nec(rule(R))),
                   o(licensed_consequence(C)),
                   o(context(K)) ]).
```

where `R` is `student_rule`, `C` is what `R` yields on the class named in
`valid_domain`, and `K` is a context in which `C` fails. Each pair coherent, the
triple not. `incompatible_with` supplies the normative commitment that makes `K`
a context where `C` fails, and is carried as provenance on the edge rather than as
a fourth element, so the set stays minimal and the emergence criterion still
applies.

Vocabulary correspondence: this is §3.4, normative expansive — the
overgeneralization / natural-number-bias / met-before / gap-thinking family, and
the draft's own proposed *incompatibility* vocabulary sits in the same cell.

### Worked example A — gap thinking (rows 44628, 45649, 46294, 46683)

Row 46683 reads: "Learners apply 'gap thinking' or whole-number reasoning
independently to the numerator and denominator, incorrectly concluding that two
fractions are equivalent," with the example "Four PTs demonstrated gap thinking by
incorrectly concluding that the fractions 8/9 and 12/13 were equivalent because
they were both one piece away from 1."

- **`student_rule`**: order two fractions by the additive difference between
  denominator and numerator; equal differences mean equal fractions.
- **`valid_domain`**: pairs on which gap order and fraction order coincide.
  Concretely this includes every equal-numerator pair (1/3 against 1/4: gaps 2 and
  3, and 1/3 > 1/4, correct). `valid_domain_status`: `inferred`.
- **`incompatible_with`**: the community's commitment, in rational-number
  comparison, that order is fixed by the multiplicative relation of part to whole
  rather than by the additive distance between the two numerals.
- **Triple**: `[s(comp_nec(rule(gap_by_absolute_difference))),
  o(gap_order_is_fraction_order), o(gap_order_diverges_from_fraction_order)]`.
- **Already half-built.** `knowledge/strategies/math/smr_frac_benchmark_compare.pl`
  carries `gap_viability/3`, which decides per input between
  `condition(gap_order_coincides_with_fraction_order)` /
  `validity(contextually_correct)` and
  `condition(gap_order_diverges_from_fraction_order)` / `validity(incorrect)`.
  The third element of the triple is that condition atom. The automaton computes
  the valid domain the database column is missing; the columns are the join
  between the two.

### Worked example B — the mediant (row 44013)

Row 44013 reads: "Students incorrectly add fractions by adding numerators together
and denominators together," example "1/2 + 1/3 = 2/5", `vocabulary_used_raw`:
"common mistake".

Note what that vocabulary field does. The row's own term is objective compressive
(§3.1) and by itself yields a pair and no finding. The columns are what convert
it. **This is the argument for keying the extraction prompt on shape rather than
on term**: the most encodable row in the corpus does not name an encodable
vocabulary.

- **`student_rule`**: `a/b ⊕ c/d = (a+c)/(b+d)` — the mediant.
- **`valid_domain`**: combining two ratios that share a referent trial scale,
  where each operand is a count of events over a count of trials. Farey sequences,
  mediants of continued fractions, combined batting averages. `valid_domain_status`:
  `stated` (the operation is named in mathematics).
- **`incompatible_with`**: the community's commitment, in rational-number
  addition, that addition is defined on a common unit, so that
  `a/b + c/d = (ad + cb)/bd`.
- **Triple**: `[s(comp_nec(rule(mediant))),
  o(operands_are_ratios_over_a_shared_trial_count),
  o(operands_are_quantities_over_a_common_unit)]`. The second and third cannot
  both hold of one pair of symbols, and the rule commits to the first.

### Worked example C — decimal length and value (row 44156)

Row 44156 reads: "Students confuse the length of a decimal fraction with its
value, believing that longer decimal fractions are either necessarily larger or
necessarily smaller," examples ".355 is more than .5 because 355 is more than 5"
and "0.1 is larger than 1.5."

This row carries **two rules and their inverse**, which is itself a schema
finding: the columns are per-rule and this row needs splitting before it can be
coded. Taking the first:

- **`student_rule`**: order decimals by the count of digits after the point; more
  digits is larger.
- **`valid_domain`**: natural-number numerals, where digit count does track
  magnitude. This is precisely what Tall's *met-before* names, and the term names
  its own valid domain — which is why §3.4 is the tractable family.
  `valid_domain_status`: `stated`.
- **`incompatible_with`**: the community's commitment that decimal place value
  assigns each position to the right of the point a weight of a decreasing power
  of ten, so digit count does not track magnitude there.
- **Triple**: `[s(comp_nec(rule(order_by_digit_count))),
  o(digit_count_tracks_magnitude),
  o(positions_right_of_point_carry_decreasing_weight)]`.

### How many rows are addressable

- 3,183 of 3,621 rows have a populated `example`, which is the minimum needed to
  recover a rule. That is the ceiling.
- 122 rows already name a §3.4-style domain shift in `vocabulary_used_raw`. That
  is the set that names itself, and it is small.
- 930 of the 2,141 journal-directory extractions carry
  `incompatibility_foregrounded: true` in the article record. That field is
  populated and, as far as I can find, consumed by nothing in this repo. Per the
  repo's own ethic that unconsumed data is stalled input rather than vestige,
  those 930 articles are where the extractor already judged an incompatibility
  structure was in the foreground, and they are the obvious place to start a pilot
  rather than coding 3,183 rows blind.
- Aggregation is the binding constraint, not row count. The rows spread across
  1,366 distinct `mathematical_topic` values and 2,625 subtopics; only 20
  domain-topic pairs hold 15 rows or more, the largest being whole-number
  subtraction at 66. Emergence needs the *same* atoms to recur, so the pilot
  should be run within one dense topic rather than across the corpus. Fraction
  comparison (31 + 25 + 20 rows across three near-duplicate topic spellings) is
  the natural first choice, and it is where the automata and viability contexts
  already exist.

## 6. Is Lakoff-Núñez special?

First, the search space as I measured it, which differs slightly from the figure
I was given. `formal/incompatibility/incompatibility_sets_discovered.pl` holds
**574** discovered sets, not 576 — 4 emergent, 45 incoherent but not minimal, 524
defeated, 1 nonterminating. The atom inventory is **43** distinct contents: 12
`inference(...)` atoms, 20 plain `o(...)` atoms, and 11 `o(grounded(...))` atoms
(the last group is missed by a grep for `o([a-z_]*)`, which is probably where the
"12 and 20" figure came from). Of the 43, **40 are Lakoff-Núñez derived**: 11
grounding inferences, 11 grounding commitments, 18 break triggers. The remaining
three are scaffolding — `commit_p_entitles_q`, `o(p)`, `o(unrelated_control)`.

So all four emergent hyperedges are Lakoff-Núñez, and given that inventory they
could not have been anything else. The question is whether that is a fact about
Lakoff-Núñez or a fact about the encoding.

**My answer: Lakoff-Núñez is not special as theory. It is special in this repo in
two respects that are fixable and one that is not.**

*Fixable — the encoding.* §4 above. `unlicensed/1` is one-place and discards the
valid domain; `grounded/1` paired with `compiled_break/2` keeps it. Eight hundred
and twenty misconception rows sit in a form that can yield pairs and nothing else.
This is not a property of misconceptions; it is a property of the wrapper chosen
for them.

*Fixable — the genre.* Lakoff and Núñez wrote a catalogue of the form (metaphor,
what it grounds, where it stops grounding). That genre is one rewrite from
`material_inference/3` plus `compiled_break/2`, which is why it encoded. But the
normative-expansive error vocabulary (§3.4) is written in the *same genre* and has
been since Streefland 1978: (rule, domain where it holds, domain where it fails).
"Natural number bias" is literally a claim that whole-number arithmetic grounds a
student's rational-number reasoning up to a break point. Nobody has extracted it
into that shape, but nothing about it resists the shape. On attestation this is
the field's second-largest family.

*Not fixable — the warrant.* Here is the steelman for Lakoff-Núñez being genuinely
special, and I think it is a serious argument. The four existing hyperedges are
jointly incoherent **as mathematics**. The diagonal of the unit square is
incommensurable with its side, so a count-of-units reading has no value for it,
and anyone can check this by doing the mathematics. An error triple is jointly
incoherent **relative to a community's sanction**. There is no proof that
whole-number ordering and fraction ordering cannot be held together; they are
incompatible because a community says so. The engine cannot tell the two apart. So
filling the columns would produce a hundred "emergent hyperedges" of which four
have proofs and ninety-six have coder judgments, and the word *emergent* would
quietly change meaning.

*Rebuttal.* This reverses Brandom's order of explanation, which
`brandomian_incompatibility.pl`'s own docstring states as the module's purpose:
incompatibility is semantically primitive and the classical engine is what gets
back-stopped, not the other way round. On that account material incompatibility
**is** normative in the first place and is not a species of provable
inconsistency. The Lakoff-Núñez cases are then the anomaly: they happen to be
*also* mathematically forced, which is a bonus rather than the criterion.
Requiring a proof would turn the relation into a fragment of classical
consequence, which is precisely what `formal/sequent/sequent_engine.pl` already is
and what this module was built not to be.

*Where I land.* Both are right about something and the disagreement is
bookkeeping, not a fork. Record the warrant per hyperedge — `mathematically_forced`
against `community_sanctioned`, with the sanctioning community named in the second
case. The four existing edges keep their stronger standing without the error edges
being excluded, and any claim built on the set can state which kind it rests on.
This matches what the repo already does with state labels, where every label
carries its citation and its tradition.

**Prediction, and its honesty.** I expect §3.4 to yield emergent hyperedges,
because I read the shape in the prose of rows 44628, 45649, 46683, 44156, and
44013, and because the gap-thinking automaton already computes the third element.
I have not run it, so I am predicting rather than reporting. Two things could
make me wrong. The bound: 43 atoms produced 574 candidate sets, and a few hundred
error atoms would produce a search that needs a candidate grid designed for it
rather than the current one. And the aggregation problem above — if the coded
rules turn out to be as topic-scattered as the raw rows, the atoms will not recur
and the search will return the same four.

The more interesting failure mode is the second one, and it would not mean
Lakoff-Núñez is special. It would mean the field's error vocabulary is
**individuating** in a way Lakoff-Núñez's metaphor catalogue is not: eleven
metaphors ground all of arithmetic, while three thousand student rules ground
nothing in common. That would be a finding about the vocabulary rather than about
the engine, and it is worth being able to report.

## Appendix: derived figures

| figure | value | derived from |
|---|---|---|
| extraction JSONs | 2,151 (2,141 in journal directories, 10 top-level) | `find extraction_results -name '*.json'` |
| error records in extractions | 3,241 | parsed `misconceptions[]` |
| articles with `incompatibility_foregrounded: true` | 930 of 2,141 | parsed `article` records |
| `error_instances` rows | 3,621 | `research_shared.db` |
| rows with `vocabulary_used_raw` | 3,329 | same |
| rows with `example` | 3,183 | same |
| rows with `student_rule` / `valid_domain` / `incompatible_with` | 3 / 0 / 0 | same |
| rows naming a §3.4 domain shift | 122 | same |
| `articles` rows | 2,682 | same |
| distinct `mathematical_topic` / `subtopic` | 1,366 / 2,625 | same |
| orientation split | deficit 2,424; uncoded 505; productive 452; sociocultural 128; mixed 112 | same |
| distinct comma-separated vocabulary phrases | 9,044 | tokenized `vocabulary_used_raw` |
| terms enumerated in `22ways.tex` lists | 52 (+4 in prose only) | §2.2, §3.3, §4.1 term lists |
| those with zero corpus attestation | at least 10 | regex over 3,241 records, all fields |
| attested terms the draft does not name | at least 24 at n≥4, 28 total | same |
| derived floor on distinct terms | about 69 | 41 attested-and-named + 28 attested-and-unnamed |
| `material_inference/3` rows | 12 (11 grounding metaphors, 1 scaffold) | `defeasible_inference.pl` |
| discovered sets | 574 (4 emergent, 45 incoherent, 524 defeated, 1 nonterminating) | `incompatibility_sets_discovered.pl` |
| distinct content atoms in the cache | 43 (12 inference, 20 plain `o`, 11 `o(grounded)`) | same |
| of those, Lakoff-Núñez derived | 40 | same |
| `misconception_pml/2` rows | 820, all `s(comp_nec(unlicensed(_)))` | `pml_wire.pl` |
| PML operator occurrences repo-wide | 1,957 across 10 of 12 cells; `s(comp_nec)` 1,782 | grep over `*.pl`, worktrees excluded |
| `o(grounded(` occurrences | 578 | same |
