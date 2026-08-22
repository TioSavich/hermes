# The admission-pipeline template

This document names the shape one pipeline in this repo already runs and
states what to keep, what to swap, and what to skip when a new store of
work needs the same treatment. The canonical instance is the two teacher-
question stores this pipeline moved from `pending_human_review` to a
mechanical attributed store. Read the code, not this summary, before
building a new instance -- every claim below cites the file it comes from.

Canonical files:

- `scripts/questions/build_admission_candidates.py` (stage 0, candidates)
- `scripts/bigred/questions_admission/judge.sbatch` +
  `scripts/bigred/questions_admission/judge.py` (stage 2, the model pass)
- `curriculum/im/generated/questions_admission_verdicts.jsonl` (stage 3,
  the tracked evidence copy)
- `scripts/questions/emit_admitted_question_stores.py` (stage 4, the
  attributed store)
- `scripts/checks/admitted_question_stores.py` plus the
  `check_admitted_question_labels/0` and `check_admitted_guide_questions/0`
  predicates the emitted stores export themselves (the re-deriving check)
- Design record: `.superpowers/sdd/task-0820C-design.md` (a gitignored
  planning file; if it is absent when you read this, the code below is
  still the ground truth)
- Contrast instance, deterministic-only, no model pass:
  `scripts/research/promote_review_proposals.py` +
  `knowledge/index/admitted_review_proposals.pl`. A second deterministic-
  only instance exists at `scripts/checks/admitted_bridges_store.py` +
  `scripts/bigred/loops/admitted_bridges.pl`.

---

## 1. The shape, and why each stage exists

Candidates, then deterministic gates, then a bounded model pass, then an
attributed store, then a re-deriving check. Each stage exists because it
catches a failure class none of the others can reach.

**Candidates** exist because a source store's rows are not yet claims
anyone has re-checked -- they are what a prior builder wrote. Reading them
back through the actual interpreter (this pipeline loads the Prolog
modules through a live `swipl` process rather than parsing the `.pl` text
with a regex; `build_admission_candidates.py:167-212`) catches a stale or
hand-edited source file before any gate runs against it.

**Deterministic gates** exist because most defects are checkable without a
model at all: a cited file that no longer exists, a span that no longer
reproduces the stored text, a label a small rule can re-derive and check
against what the store already says. A row that fails here never reaches
the model pass -- it costs no GPU time and it never accumulates false
model testimony (`build_admission_candidates.py`'s D1-D7 checks per lane,
`check_labels_row` / `check_guide_row`).

**The bounded model pass** exists for the claims a deterministic rule
cannot check on its own -- whether a question's wording actually performs
the function a heading convention says it performs, for instance. It is
bounded on purpose: one sbatch job, a fixed prompt, a fixed token budget,
a pre-fixed decision rule for whether the pass is trustworthy at all
before it runs to completion (`judge.py`, `judge.sbatch`).

**The attributed store** exists because a row's disposition is not self-
evident from a JSONL line -- a person or a later check needs to read, next
to the row, exactly what checked it, exactly what model or rule spoke for
it, and exactly what that speaking licenses. `emit_admitted_question_stores.py`
writes two Prolog stores where every admitted row carries an `anchor`, a
`testimony`, and a `receipt`, and every held row stays in the store with a
named reason instead of disappearing.

**The re-deriving check** exists because an emitter that only ran once is
a claim, not a proof. `scripts/checks/admitted_question_stores.py` and the
stores' own `check_admitted_*` predicates read the tracked inputs fresh
and recompute every number the store states -- span text, source sha,
label re-derivation, the void statistics, the count pins -- rather than
trusting that the script which wrote the store ran correctly the one time
it ran.

---

## 2. Invariants -- not optional in a new instance

**The leakage boundary.** The model must never receive the label it is
being asked to corroborate. In `judge.py` this is a structural fact, not a
discipline: `build_prompt(row)` (`judge.py:124-126`) reads only `id`,
`lane`, `text` from a `model_input.jsonl` row. The file that carries the
stored label, `pilot_key.jsonl`, is read by exactly one function,
`lane_pilot_decision`, and only after verdicts already exist
(`judge.py:242-277`, and the module docstring names this rule explicitly).
A new instance keeps the same split: the file the model reads and the
file that carries ground truth are two files, and the prompt-builder
function never imports the second one. Every verdict row also carries a
`prompt_sha` (`judge.py:115-117,199-203`) so the exact template that ran
is auditable from the tracked evidence file after the fact, without
re-running the job.

**The pre-fixed void rule.** Decide the kill criterion before the run,
not after reading the numbers. `judge.py` fixes
`MODAL_SHARE_VOID_THRESHOLD = 0.95` and `KAPPA_VOID_THRESHOLD = 0.20`
(`judge.py:63-64`) before it ever judges a row, runs a pre-fixed pilot
slice first, and voids a lane -- writes `pass_void.json`, stops judging
that lane's remaining rows -- when the pilot crosses either threshold. A
fired void is a finding, worth recording as such, not a bug to route
around quietly. This is not a hypothetical: on this pipeline's real run
the labels lane voided at kappa 0.0212 and the guide lane voided at kappa
-0.0338 against a 326-row pilot (recorded in
`.superpowers/sdd/task-0820C-design.md` section 13 and pinned as
`EXPECTED_VOID` in `scripts/checks/admitted_question_stores.py:39-42`).
The reading recorded there: the assessing/advancing label is a positional
fact about where the curriculum prints a question, not a property a
text-only reader can recover from the words alone -- so a text-only second
reader was the wrong corroborator for that particular claim, and its
failure to agree is a finding about the corroboration channel, not
evidence against the underlying fact.

A voided lane does not have to mean "hold everything forever." What this
pipeline actually did after the void, read from
`emit_admitted_question_stores.py:102-185` and its `disposition_for_row`
(`emit_admitted_question_stores.py:328-374`), is instructive for a new
instance facing the same outcome: it separated two different things a
verified row can license. A row whose label comes from the curriculum's
own printed section heading (`label_origin == author_heading`) still
admits, on the strength of that heading alone -- no model testimony at
all, `testimony(im_author_heading(...), extraction(...), date(...))`. A
row whose label was assigned by the deterministic heading rule
(`machine_classification`) also still admits, but with a narrower claim:
`warrant(printed_region(Region))`, carrying `region(Region)` in the label
argument's place -- never an `assessing`/`advancing` atom, because nothing
in this pipeline corroborates that function claim for those rows anymore.
Nothing is deleted and nothing is held past what the deterministic checks
already required. The lesson for a new instance: when the model pass
voids, look for a narrower warrant the deterministic gates alone can
still support, before defaulting to holding the whole candidate set. Name
the narrower warrant honestly in the store rather than reusing the wider
label term for a claim the pipeline no longer backs.

**Honest refusals.** A row that does not admit stays in the store as a
held row with a reason drawn from a closed, named taxonomy -- never
deleted, never silently dropped. `emit_admitted_question_stores.py:291-307`
(`render_held`) raises if a caller passes a reason outside the closed set;
the taxonomy itself is enumerated in the emitted Prolog as
`valid_held_reason/1` facts (e.g.
`emit_admitted_question_stores.py:754-760`) and checked against by the
store's own `check_held_labels_row`. Extend the taxonomy only by editing
the emitter and its check together, in the same change.

**Attribution.** Every admitted row names what spoke for it: a model and
its checkpoint identity, or the curriculum's own heading text and the
builder script that read it, plus a job/run identifier and a date
(`testimony(...)` terms rendered by `render_testimony`,
`emit_admitted_question_stores.py:265-282`). `valid_testimony/1` in the
emitted check enumerates only the shapes that actually ran -- it is not a
type declaration, it is a receipt of what happened
(`collect_testimonies`, `emit_admitted_question_stores.py:1104-1114`).

**The re-deriving check trusts nothing about its own store.** The Python
check (`scripts/checks/admitted_question_stores.py`) re-runs the emitter
in `--check` mode (byte-compare against a fresh rebuild,
`emit_admitted_question_stores.py`'s `--check` branch near its `main`),
re-derives every admitted span from the sha-pinned source file
(`check_spans`, `admitted_question_stores.py:82-120`), and recomputes the
void statistics from the tracked verdict file rather than trusting the
number the emitter printed once
(`check_void_history`, `admitted_question_stores.py:123-146`). The
Prolog side does the same from inside the store itself: `check_admitted_
question_labels/0` and `check_admitted_guide_questions/0`
(`emit_admitted_question_stores.py`'s `LABELS_CHECK_CODE_TEMPLATE` /
`GUIDE_CHECK_CODE_TEMPLATE`) carry a second, independent copy of the
10-line heading rule (`SHARED_HEADING_RULE_CODE`,
`emit_admitted_question_stores.py:513-611`) so a divergence between the
Python builder's copy and the Prolog check's copy of that rule fails
loudly instead of passing by shared assumption. A tracked-inputs-only
rule applies throughout: the check must be able to rebuild from files
`git` tracks, never from local runtime state alone (section 5 below names
a gap where this instance does not yet fully meet its own rule).

---

## 3. Per stage -- what to keep, what is questions-specific, what to swap

### Stage 0 -- candidates (`build_admission_candidates.py`)

What it does: reads the source store(s) back through the real
interpreter, runs the named deterministic gates in a fixed order (first
failure wins, so a held row's reason names the first thing that actually
failed), assigns each candidate a content-derived id
(`make_id`, `build_admission_candidates.py:240-243` -- a sha256 prefix
over the fields that make a row's identity, not a row index, so the id is
stable across reruns and duplicate content collapses honestly), and
writes three files: the full candidate list with det verdicts and
anchors, a stripped model-input file carrying nothing but id/lane/text,
and a pilot-key file carrying id-to-stored-label pairs for the rows a
later void decision needs -- kept out of the model-input file on purpose.

What is questions-specific: the D1-D7 gate names, the heading-rule
re-derivation, the interrogative-text and markdown-debris checks -- these
encode what a *question row* can be wrong about.

What a new domain replaces: the gates, named after what your source rows
can be wrong about. A citation-link admission might gate on: does the
cited bibkey exist in the bibliography store, does the cited page/section
actually contain a string matching the claim, is the link's target module
still present in the tree. An orphan-module judgement admission might
gate on: does the module still parse, does it still export what its
registry row claims, is its listed caller still absent (re-derive the
"orphan" claim itself, do not trust it inherited). Keep the shape: a
named check per row, first-failure-wins, a held reason recorded rather
than a boolean, and an id built from content rather than position.

### Stage 1 -- ship (no canonical script; a controller step)

This instance ships to a GPU cluster via the delta-rsync and import-
verification steps named in the `bigred-operating-recipe` memory --
verify imports on the login node before submitting, not after. A new
instance that runs its model pass locally or through a hosted API skips
this stage outright; it exists only because this instance's model needed
a specific quantized checkpoint on a specific GPU node.

### Stage 2 -- the model pass (`judge.sbatch` + `judge.py`)

What it does: brings up a node-local model server, judges a pre-fixed
pilot slice first, computes modal-answer share and Cohen's kappa against
the pilot key, applies the pre-fixed void rule (section 2 above), and
only then continues through the rest of each lane that did not void.
Every verdict is appended and flushed per row
(`judge.py:373-388`), so a resume after interruption is "read what
`verdicts.jsonl` already has and skip those ids" (`done_ids`,
`judge.py:371,377-378,382`) -- there is no end-of-run dump to race a
SIGTERM against.

What is questions-specific: the two prompt templates
(`LABELS_PROMPT_TEMPLATE`, `GUIDE_PROMPT_TEMPLATE`,
`judge.py:74-113`), the answer vocabularies (`LABELS_CHOICES`,
`GUIDE_KINDS`), the specific checkpoint (`gemma-4-26B-A4B-it_Q4_K_M`,
matching the pilot-generating checkpoint so testimony names one model).

What a new domain replaces: the prompt and its answer vocabulary, carved
from the target domain's own structure the same way this pipeline's
prompt names only the two label families the heading rule already
distinguishes -- never a generic rubric a model brings from outside the
repo (a generic gate was the ground-truth failure this design's own
notes cite: the neurosymbolic ceiling report's finding that disposition-
free, fixed-schedule model calls outperform an agent deciding when to
call a tool). Keep the shape: one bounded job, one pre-fixed pilot, one
pre-fixed void threshold pair, append-and-flush per row, a `prompt_sha`
on every verdict.

An alternate shape worth naming, for a domain where the model's role is
to propose rather than to corroborate: `scripts/questions/linker.py`'s
`verify()` function (`linker.py:249-299`) has a model propose a link and
then a deterministic engine (a Prolog trace runner) re-proves the
specific claim the proposal makes -- three named checks
(`run_check`, `slot_check`, `label_check`), and a proposal that fails any
of them is quarantined with the failed check named rather than discarded.
This is the same admit-or-hold-with-a-name discipline as the canonical
instance, but the model's answer is a proposal the engine re-derives,
not an independent second reading the engine merely compares against a
stored label. Pick this shape when the target claim is something the
formal core can actually re-run (a link to a machine and an input); pick
the canonical instance's shape (independent second reading, compared
after the fact) when the claim is a judgment the formal core has no way
to re-execute.

For batch construction, a call ledger against a budget, and checkpoint-
resume against a hosted API (rather than a node-local server), read
`scripts/questions/glm_batches.py` (prompt/menu construction and reply
parsing) together with `scripts/questions/run_glm_links.py` (the ledger,
the checkpoint file that a rerun resumes from instead of re-paying for,
and the rule that a non-ok transport call is never parsed as an answer --
`run_glm_links.py:1-8,89-95,207,248-271`). The checkpoint-and-resume loop
itself lives in `run_glm_links.py`, not in `glm_batches.py`; the two
files divide the same responsibilities `judge.py` holds alone for the
canonical instance's node-local case.

### Stage 3 -- collect (no canonical script; a controller step)

Pull the run directory back (verdicts with the untrimmed `raw` field,
logs, `pass_void.json` if a lane voided) to a local collected-artifacts
directory, then copy a compact projection -- this instance drops `raw`
and `latency_s` -- to a tracked file inside `curriculum/im/generated/`.
That tracked copy, `questions_admission_verdicts.jsonl`, is the
reproducibility anchor stage 4 and the re-deriving check both read; the
full collected copy with `raw` stays off the tracked tree for size but
is not deleted, so an audit of an individual model reply is still
possible from the collected artifacts.

### Stage 4 -- emit the attributed store (`emit_admitted_question_stores.py`)

What it does: reads the candidates file, the tracked verdicts file, and
`pass_void.json` if present; applies the domain's agreement/warrant rule
per row (`disposition_for_row`, `emit_admitted_question_stores.py:328-374`);
renders two Prolog stores, byte-stably (`render_store` and its callers --
no timestamps in the row text itself, so running the emitter twice on
unchanged inputs produces byte-identical output); and writes, verbatim in
each store's header, the one or two sentences that state exactly what
admission licenses and what it does not
(`LABELS_LICENSE_SENTENCE`, `GUIDE_LICENSE_SENTENCE`,
`emit_admitted_question_stores.py:156-185`). `--check` mode reruns the
same rendering and byte-compares against what is on disk rather than
writing.

What is questions-specific: the two Prolog predicate shapes
(`admitted_question_label/6`, `admitted_guide_question/6`), the specific
warrant vocabulary (`im_author_heading`, `printed_region`).

What a new domain replaces: the row shape and the license sentence. Keep
the shape: `admitted_<thing>/N` and `held_<thing>/N` as sibling
predicates in one module, a `<thing>_summary/1` fact the check re-derives
field by field, a `check_<thing>/0` the module exports and the check
harness calls, and a header sentence that states the license in one place
so every downstream surface's copy has one sentence to match rather than
inventing its own.

### The re-deriving check (`scripts/checks/admitted_question_stores.py` + the stores' own `check_*/0`)

What it does: two layers. The Python check re-runs the emitter's
`--check`, then independently re-derives spans from sha-pinned source
files and recomputes the void statistics from the tracked verdicts file,
comparing every number against a pinned expectation
(`EXPECTED_STATUS`, `EXPECTED_HELD`, `EXPECTED_VOID`,
`admitted_question_stores.py:27-46`). The Prolog check, exported by the
store itself, re-derives the same claims from inside the running Prolog
process -- source sha, span text, the label re-derivation rule carried a
second time, testimony validity, held-reason validity, and the summary
counts -- and throws a named error term on the first claim that fails to
reproduce.

What is questions-specific: the pinned numeric expectations, the span-
reproduction method (`find_verbatim` for character-offset labels,
`cited_span_contains` for line-addressed guide text).

What a new domain replaces: the pinned numbers (these belong to the
domain, updated only when the emitter and the check move together in the
same change) and the specific re-derivation method for whatever
"reproduces the source" means in that domain. Keep the shape: a Python
check for the count pins and any Python-side re-derivation, a Prolog
check the store itself exports for anything that only the Prolog runtime
can verify, and both wired into the check harness
(`scripts/checks/run_all.sh:114,116-118` for this instance) in
regeneration order, after the source stores' own checks and before
anything downstream consumes the admitted store.

---

## 4. When to skip the model pass

Skip stage 2 entirely when the claim under admission is mechanical --
answerable from numbers a deterministic scorer already produced, with no
question left that only a reader (human or model) could settle.
`scripts/research/promote_review_proposals.py` is the canonical contrast:
it reads two JSON files of scored proposals and diagnostics, groups them
by signature, and assigns a band from fixed numeric rules
(`group_band`, `promote_review_proposals.py:53-71` -- a defect-free group
whose best clear score clears a fixed threshold admits; anything with a
named defect or a low score holds, by the defect or the band, no model
consulted anywhere). The result on this repo's real corpus: 2 of 539
proposals admitted, the rest held with a named band reason
(`held_no_clear`, `held_rank_0` through `held_rank_3`) -- a low admission
rate is not evidence the pipeline needs a model pass to loosen it; it is
what the deterministic bands actually support, stated honestly.
`scripts/checks/admitted_bridges_store.py` is a second deterministic-only
instance in this repo, admitting bridge candidates by adapter-license
class and companion-value checks with no model pass anywhere in its
chain.

The test for whether a new admission needs stage 2 at all: write the
deterministic gates first, run them, and read what is left in the
`det=pass` pile. If every remaining row's disposition already follows
from a fixed rule over fields the gates already checked, stop there --
emit the attributed store straight from the deterministic pass, name it
mechanical in the header, and do not add a model call whose corroboration
nothing downstream needs. Add stage 2 only for the residual claim a
deterministic rule genuinely cannot settle -- and be ready, per section 2,
for the pre-fixed void rule to find that the model cannot settle it
either, which is itself the answer to the question, not a failed attempt
to get one.

---

## 5. Checklist before a new store lands

1. Name the source store(s) and confirm they are read back through the
   real interpreter or format, not re-parsed by hand.
2. Write the deterministic gates first, named, first-failure-wins, each
   with a distinct held reason. Run them alone and read the held census
   before deciding whether a model pass is needed at all (section 4).
3. If a model pass is needed: write the prompt from the domain's own
   structure, never a generic rubric; keep the file that builds the
   prompt structurally unable to import the file that carries the ground-
   truth label; fix the pilot size and the void thresholds before the
   first run, not after seeing the numbers; make every verdict append-
   and-flush so a resume never re-asks a judged row.
4. Decide, before launch, what a fired void means for this domain --
   whether any narrower warrant the deterministic gates alone can support
   still admits (section 2's worked example), or whether a void really
   does mean every model-dependent row holds. Write that decision down
   before the run, alongside the thresholds.
5. Collect the model pass's full output somewhere durable, then copy a
   compact, tracked projection into the repo -- this is the file the
   emitter and the check both read; confirm they read the tracked copy,
   not a local-only runtime artifact (the next item names a gap this
   instance itself has not closed).
6. Wire the stage-0 builder into both the regen pipeline and the check
   harness, and guard it against any gitignored input it reads. This
   instance's `build_admission_candidates.py` runs in
   `scripts/regen_all.sh` immediately before the stage-4 emitter (so the
   tracked admitted stores are settled before the self-description tail
   reads them), and `scripts/checks/run_all.sh` runs its `--check`,
   which re-derives all three gitignored outputs in memory and compares
   them against the copies on disk -- re-reading the files alone would
   certify a stale artifact. One input stays outside `git`: the guide
   lane's per-row anchors are a gitignored docling tree, and a rebuild
   without it would replace every guide row with a `source_missing`
   hold. So when that tree is absent, the builder and its `--check`
   print one SKIP line, exit 0, and leave the existing outputs
   untouched: a docling-less clone keeps whatever candidates a prior
   run produced, cannot rebuild or verify them, and the SKIP line says
   so rather than pretending a check ran.
7. Write the emitter to produce byte-stable output (no timestamps in the
   row content) and give it a `--check` mode that rebuilds and compares.
8. Give the emitted store a `check_*/0` predicate it exports itself, that
   re-derives every claim -- source identity, span text, any label rule,
   testimony validity, held-reason validity, summary counts -- rather
   than trusting the emitter's one run.
9. Write, once, in the store's header, the sentence that states exactly
   what admission licenses and what it explicitly does not. Point every
   downstream surface's copy at that one sentence rather than letting
   each surface phrase the claim on its own.
10. Wire both the Python check and the Prolog check into the check
    harness, in order, after the source store's own checks and before
    anything that reads the admitted store.
