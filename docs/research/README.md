# Research log

Reports written by Claude models working in this repository, each dated the
day its measurement ran. The folder holds findings: measurements, arguments,
and audits meant to stand on their own. The day-to-day engineering reports
that once sat beside them live on in git history and in a local, untracked
`internal/` log.

Conventions the reports share. "The owner" names the repository's author, who
commissions the work and rules on its carvings. "The brief" names the
commissioning document a report answers. A report's counts are measurements of
the corpus as it stood on the report's date; later reports correct earlier
ones by name rather than by silent edit. Every report ends with its limits,
and the limits are part of the finding.

## The corpus and its shape

- [The machines, typeset](2026-08-03-the-machines-typeset.md) — the corpus
  described as automata: five-tuples, tables, structural classes, and where
  its claims stop.
- [Automata compendium](2026-08-03-automata-compendium.html) ·
  [deformation graph](automata-graph.html) ·
  [vocabulary](automata-vocabulary.html) — the live pages: every automaton
  typeset by family, the two-color deformation graph, and the public
  vocabulary the pages share.
- [The fractal claim, measured](2026-07-25-the-fractal-measured.md) — the
  manuscript's Iterative Core + Strategic Shell pattern held against the
  corpus: 72% parse shell → core → closure, and 14 automata delegate to a
  subordinate loop.
- [The index and its negation](2026-07-25-the-index-and-its-negation.md) —
  the corpus window built: a 12,863-token retrieval surface over ~727,000
  tokens of source, with what it loses recorded beside what it keeps.
- [The window was asked](2026-07-25-the-window-was-asked.md) — the window
  tested against an equal-budget raw slice: 9/30 against 1/30 exact,
  p = 0.0215, zero items answered by both.
- [Show the money](2026-08-03-show-the-money.md) — live traces, tuple rows,
  and the separation rule, written for a reader who knows nothing about the
  project.
- [Purported-validity audit](2026-08-03-purported-validity-audit.md) —
  whether each automaton's own validity claim survives independent truth
  computation.

## Curriculum

- [The saying and doing of grade 8](2026-08-05-grade8-saying-and-doing.md) —
  all nine grade-8 units censused for what students say and what they do,
  read against the kernel–gate formula; the partitional conjecture given its
  steelman and its rebuttal.

## Negation, incompatibility, PML

- [Why entailment does not move](2026-07-28-why-entailment-does-not-move.md)
  — why the incompatibility encoding cannot earn entailment, and why
  emergence and entailment pull opposite ways.
- [Incompatibility, LX, diagonalization](2026-07-28-incompatibility-lx-diagonalization.md)
  — Brandom's incompatibility semantics mapped onto what this codebase can
  and cannot support.
- [PML status](2026-07-28-pml-status.md) — what the PML calculus does today,
  measured, and whether it should be flattened.
- [What refusals are for](2026-07-28-what-refusals-are-for.md) — six kinds of
  refusal, carved by what should happen to each.
- [No-saying vocabularies](2026-07-27-no-saying-vocabularies-and-incompatibility.md)
  — the field's published lexicon for negation, sorted by modal posture.
- [Arity and absorption](2026-07-28-arity-and-absorption.html) — an
  illustrated argument for why a corpus of triples cannot earn entailment.
- [Emergent hyperedge search](2026-07-02-emergent-hyperedge-search.md) — does
  any genuinely emergent hyperedge exist in the corpus; a negative result.
- [What the 569 non-emergent sets show](2026-07-27-what-the-569-non-emergent-sets-show.md)
  — 574 discovered sets turn out to be 17 facts transcribed 528 times.
- [The juncture and différance](2026-06-25-the-juncture-and-differance.md) —
  norm/outcome fixed points and the juncture, argued from the formal layer.
- [Answerability and incompatibility](2026-07-25-answerability-and-incompatibility.md)
  — two jobs retracted: the labelling already existed in the invariants and
  the pairings.

## Benchmarks, with their floors

Every number from these runs travels with its input-blind floor; a score
quoted without its floor is the first error these reports exist to prevent.

- [MathTutorBench, nine columns](2026-07-26-mathtutorbench-nine-columns.md) —
  the first full run, and the two protocol defects that governed every
  published number.
- [Held-out with floors](2026-08-01-mathtutorbench-heldout-with-floors.md) —
  most published leaderboard entries score at or below an input-blind floor.
- [Diagnosis benchmark](2026-08-01-diagnosis-benchmark.md) — seven-way error
  naming scored against majority-class floors.
- [The Prolog-assisted diagnosis arm](2026-08-01-diagnosis-prolog-arm.md) —
  one Prolog consultation per item does not move a checkpoint that diagnoses
  at its floor.
- [strategy_recognize discrimination](2026-08-01-strategy-recognize-discrimination.md)
  — a recognizer that returned identical candidates for math and non-math
  sentences, and the mechanism that fixed it.
- [Recognition benchmark](2026-07-25-recognition-benchmark.md) — recall@k on
  literature phrases against the student register, abstention counted.
- [The student register](2026-07-25-student-register.md) — 58,926 held-out
  student sentences; what the recognizer misses there and why nothing was
  added for it.
- [Task spans and the singleton tail](2026-07-27-task-span-singleton-tail.md)
  — word-problem prompt spans measured five ways; two-thirds carry no
  operand pair.

## Machinery kept beside the reports

- `2026-07-01-talkmoves-pass1-math-prompt.md` and
  `2026-07-01-talkmoves-pass2-posture-prompt.md` — prompt sources consumed by
  the TalkMoves pipeline scripts, kept verbatim where the scripts read them.
- `2026-07-25-what-the-repo-knows-about-itself.md` — generated
  self-description census; regenerated by
  `scripts/research/build_self_description_census.py`, never hand-edited.
- `2026-07-29-a-fortiori-input-nesting-settlement.md` — generated settlement
  record for the context-nesting sweep, held by its check.
- `2026-08-03-automata-abstraction-conversation.txt` — the conversation that
  generated the abstraction line of work; kept as provenance for
  `knowledge/strategies/abstraction/`.
- [proposals/](proposals/) — designs written before their code; each says so.
