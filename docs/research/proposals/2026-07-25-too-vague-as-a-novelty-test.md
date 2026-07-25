# PROPOSAL — `too_vague` is a novelty test, not a naming problem

Date: 2026-07-25. Records the owner's account of what `too_vague` is for, against
which an earlier description in this repository was wrong.

## The correction

I had `too_vague` as a placeholder name awaiting articulation — a name wearing
words while the real content sat elsewhere. That reading produced a wrong purpose
statement in `scripts/bigred/literature_embeddings/embed_corpus.py` and in the
message of commit `c5cb12e`, both since corrected in place.

The owner's account:

> `too_vague` actually meant that the text we mined in an earlier run contained a
> strategy or misconception but not enough detail to build an automaton. So, I had
> big red process the articles from pdf to markdown to try and find more details.
> Then the plan was to use consensus.ai to do citation mapping and use the automata
> derived from other literature to serve as the details that might make the
> too_vague description fall so we could see if the article contributed a new way
> of doing things.

So `too_vague` is **a verdict about evidence sufficiency**, recorded honestly at
the point where construction failed. The name is accurate: the text was too vague
*to build from*. Renaming it describes the error better and answers nothing, which
is why the 2026-07-22 ruling forbade mechanical renaming and why
`scripts/research/misconception_survey.py:129`'s `rename_rows` is dry-run only.

## What the pipeline actually is

Four stages, and the third is the one that makes it a test rather than a
cataloguing exercise.

**1. Get more detail.** The mined snippet was insufficient; the full text may not
be. 2,183 articles are converted from PDF to markdown on Big Red. Done.

**2. Find the detail.** Passage-level retrieval over those 2,183 documents, so the
paragraphs a `too_vague` row's citation points at can be recovered rather than
guessed. Big Red array `7785950` is building this now — the reason it needed to
exist at all.

**3. Offer the existing automata as the candidate details, and see what falls.**
This is the load-bearing step. For a `too_vague` description, the 232 automata the
repository already runs are the vocabulary in which the description might be
accounted for. Two outcomes:

- **It falls.** An existing automaton accounts for the description. The article
  documents a way of working the corpus already models, the row resolves to an
  instance rather than to a new machine, and the corpus grows a citation rather
  than a construction.
- **It stands.** No automaton accounts for it. *That* is where the article may
  have contributed a new way of doing things, and only there is authoring a new
  automaton licensed by evidence rather than by enthusiasm.

The shape is exclusion: what survives the attempt to account for it is the
candidate for novelty. It is the same structure as the repository's other honest
verdicts — a claim earns its standing by surviving an attempt to remove it.

**4. Citation mapping situates the novelty claim.** Consensus over what the
article cites and what cites it, so "this is new" is checkable against the
literature rather than against the corpus's own coverage. An automaton absent from
*this* corpus is not thereby absent from the field, and stage 3 alone cannot tell
those apart. Stage 4 is what keeps stage 3's survivors honest.

## What is already built for stage 3, unexpectedly

The index landed earlier today for a different reason and is the instrument this
stage needs:

- `knowledge/index/corpus_window.pl` — 232 machines, one row each, with the arc
  and the step vocabulary grouped. **The candidate details, in a form small enough
  to offer all of them at once** (12,863 tokens).
- `knowledge/index/relevance_negation.pl` — prunes candidates by topic with a
  recorded reason, so a `too_vague` row about integers is not tested against 232
  machines but against the ones a topic relation admits, and the exclusions can be
  shown.
- `docs/research/2026-07-25-the-window-was-asked.md` measured whether a model can
  route a cited literature phrase to its machine from the window alone: **9 of 30
  exact, 16 of 30 to the right family**, against a raw-slice baseline's 1 and 7.

That last number is the relevant one and it cuts both ways. Routing a phrase to a
machine and deciding whether a machine *accounts for* a description are different
tasks, and the second is harder. But 9 of 30 is also the honest ceiling to expect
from an unassisted first pass: **stage 3 cannot be a single model call whose answer
is taken.** A description ruled "new" because a model failed to recognise the
machine that accounts for it would manufacture novelty, which is the one failure
mode this design must not have.

So stage 3 needs the asymmetry built in: **a `falls` verdict may be accepted on
one pass, because it only ever removes a candidate for novelty. A `stands` verdict
must survive an adversarial pass** — several attempts to find an automaton that
accounts for it, from different angles, before the row is called a candidate for
new construction. Cheap where being wrong is harmless, expensive where being wrong
inflates the claim.

## Order of work

1. **Collect `7785950`** and build the local passage retriever over the 12
   journal indexes.
2. **Join the `too_vague` rows to their passages.** Each row carries an author, a
   year and a database row; the corpus is keyed by bibtex. Report the join rate
   before anything else — rows whose citation cannot be resolved to a converted
   document are the first honest loss, and their count belongs in the record.
3. **Stage 3 as an accounting test with the asymmetry above**, writing verdicts to
   a proposal file with the passage, the candidate automata offered, and the
   reason. Never into `knowledge/misconceptions/`.
4. **Stage 4 citation mapping** over whatever stands.

## What this proposal does not claim

- **Not that stage 3 will work.** The window's 9 of 30 is a routing result on a
  narrower task; accounting is harder and may need the passage plus the full
  transition table rather than the index row.
- **Not that a `stands` verdict means the article is novel.** It means this corpus
  does not account for it. Stage 4 exists because those are different claims.
- **Not that the 1,170 `lesson_resonance.pl` rows are 1,170 distinct problems.**
  They are lesson-scoped resonance hits and the same underlying misconception row
  recurs across lessons; the count of distinct database rows is what stage 2 must
  report, and it is smaller.
- **Not that renaming is ever the answer.** If a row falls, it takes the name of
  the automaton that accounts for it. If it stands and a new automaton is built,
  it takes that machine's name. Neither path passes through a slug.
