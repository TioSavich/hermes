# Wave findings — tasks 113 through 119, 2026-07-24

One document for the eight-lane wave that followed the task-112 improvement
plan. Each lane has its own report under `docs/research/`; this funnel keeps
the conclusions and the cross-lane pattern. Two controller-side runs (the
typed Qwen rerun and the embedding build) and the field-context array on Big
Red were still in flight when this was written; their results append below
when they land.

## What changed

- **Reader** (task 113, opus-reviewed, minor applied): parenthesized
  arithmetic with ordinary precedence, equation chains as ordered
  adjacent-pair claims, typed `ratio_statement`/`proportion_statement` that
  cannot be adjudicated as equality, and bounded interrupted-result frames.
  Red-band reads moved 10 → 12 of 470 blinded utterances with zero
  regressions and every abstention preserved. The review confirmed the
  misleading-suffix guard is structural (leftmost-longest cursor), and its
  one finding — a pragmatic-layer precedence slip that misattributed
  commitment on reported "would be" frames — is repaired with regression
  fixtures.
- **Recognizers** (task 115): every execution-witnessed automaton (69 of
  172 signatures) now carries a trace-alignment recognizer reporting matched
  spans, matched transitions, frontier, missing evidence, incompatible
  transitions, and support level. Round trips recover witnessed action
  order; an injected error cannot recognize as a clean run. Static
  generator tables were refused as transcript evidence: a named strategy
  still does not imply a student used it unless the witness route says so.
- **Articulation harness** (task 114): the six-field transform contract is
  replaced by five typed candidate kinds with paired probes, role floors,
  an explicit `abstains(Reason)` result, split
  `loads_and_terminates`/`reproduces_documented_behavior`, and
  syntax-only local retry. Seven offline regression checks pass with no
  API calls.
- **Field-context builder** (task 118): checkpointed per-lesson partials,
  `--resume`, flushed progress, deterministic merge — proven by an
  interrupt/resume/merge byte-equality probe. The rebuild that twice burned
  a Big Red wall without an artifact now cannot lose completed work. The
  grade-band array (job 7778951) builds the cache the pending ceremony
  needs.
- **Embedding interface** (task 117): one embedding engine now serves four
  domains; lessons (1,308), strategies (172), and registry ops (196) have
  exact, idempotent, hash-stamped payloads awaiting only the network leg.
- **Tables** (task 119, from the meta-analysis below): a builder fallback
  hardcoded `q_start` roots for divergent observed traces; six rows in
  three fraction-comparison tables were unreachable from their declared
  start. Fixed at the builder, regenerated, and gated by a new
  reachability check.

## The meta-mathematical result

Tio's standing directive: coverage growth must be offset by abstraction.
The first census-plus-algebra pass (task 116, Big Red job 7778459, rerun
locally after the table repair) says the compression problem precisely:

1. The label vocabulary is bespoke. 547 of 638 action labels occur in
   exactly one signature; conservative string clustering finds almost
   nothing to merge.
2. On honest tables, the 69 witnessed automata minimize to 4–10 states
   with **zero** structural-coincidence classes and **zero** rooted
   action-preserving homomorphisms between distinct strategies.

So there is no free structure to harvest: exact-label comparison cannot
compress this registry. Any real abstraction must begin with a semantic
action-vocabulary normalization — an authored, reviewed mapping of bespoke
labels onto a shared action alphabet — and only then rerun the structural
analysis (now trivially cheap) on the abstracted alphabet. The 91
exact-duplicate labels and 20 shared-role labels are the seed of that
mapping. This is a decision surface, not a computation.

The pass also demonstrated the method's value in the negative: the first
run's apparent findings (one coincidence class, 204 homomorphisms) were
artifacts of the six mis-rooted rows, caught because 204 factored exactly
as 3 × 68 trivial maps. The analysis found a data defect before it found
mathematics, which is what a verification instrument is for.

## The reader's strategic boundary

The new grammar forms are regression-covered but barely attested in the
470-utterance corpus: no parenthesized equation, no equation chain, no
unambiguous ratio statement occurs in it. The utterances that remain
silent need referent resolution, omitted-operand recovery, and inferred
wholes — places where the reader's abstention is currently correct.
Further grammar widening will not move classroom-talk coverage; the next
reader investment belongs to the bounded-antecedent and semantic-support
layer, connected to recognizer evidence rather than to more syntax.

## Operating lessons

- The codex `workspace-write` sandbox has no network. REALLMS and any API
  leg must run controller-side; two lanes correctly stopped at the API
  seam and delivered everything up to it.
- The codex workspace spend cap ends a lane at turn start with no work
  lost; rerouting the same brief to a Claude agent preserved the fence
  discipline unchanged.
- Any recompute longer than about thirty minutes must checkpoint and
  resume or it does not run (now recorded in the check-tiering plan).
- A monitor that cannot signal a process (`kill -0` under a different
  sandbox) reports death falsely; watch report files and the process
  table instead.

## The substitution-license seed (task 120, owner-supplied source)

Tio pointed the wave at his E343 vocabulary crosswalk (79 entries mapping
equivalent or competing terms across Van de Walle, Five Practices, CDM,
Indiana, CCSS, and Illustrative Mathematics, each with a confusion-risk
rating). It now lives as quarantined data:
`knowledge/crosswalk/vocabulary_licenses.pl`, 474 typed facts — 154
`substitutable_in_context` (LOW/MEDIUM same-concept terms), 134
`disambiguation_required` (HIGH-risk entries where the same word does
different work across frameworks; these must never become synonym
expansions), 186 `not_addressed`. Source notes are preserved verbatim;
the alignment graph's embedded crosswalk block proved byte-identical to
the standalone file, so there is one source, not two.

The conservative census join keeps the seed honest: it touches 15 of 638
automata action labels, 5 of 51 state labels, and 21 of 80 band-lexicon
anchors. The crosswalk speaks at problem-structure grain; most automata
labels sit below it at mechanism grain. So this is the first authored
layer of the semantic normalization, not the normalization itself — and a
looser join that claimed 451 of 638 labels was tried and rejected as
token coincidence. Wiring licenses into the reader or recognizers is
deferred to a reviewed formal-core slice.

## Appendix A — the typed Qwen rerun (complete)

Same 30 fraction rows as the task-112 pilot, same model, now measured by
the typed gate. All 30 responses returned. Support labels: 14
educated-guess, 1 source-articulation, 9 underdetermined-decline, 6
unlabelled. Gate outcomes: one candidate loads and terminates, zero
reproduce their documented behavior, zero are admissible.

The old pilot reported 3 mechanical passes; its review showed all three
were rewarded for executable wrong outputs unrelated to the documented
phenomenon. The typed gate now refuses exactly those, so the honest yield
went from 3 false passes to 0 true ones. Failures concentrate early —
15 of the 21 gated candidates die at static form or syntax, before
semantics is even tested — which says the next lever is the prompt's
module-form and constructor instruction, not more rows. One row was
recovered by the punctuation-only local repair. The batch also exposed
and fixed a harness defect: a gate subprocess timeout formerly escaped as
an unhandled exception; it is now a typed `inference_limit` result.

## Appendix B — the embedding indexes (complete)

All four domains built against `Qwen3-Embedding-8B` (4,096 dimensions):
misconceptions 2,056, lessons 1,308, strategies 172, registry ops 196.
Semantic spot probes return domain-appropriate neighbors (for example,
"make ten when adding two numbers" retrieves the make-ten strategy
cluster; "compare fractions using benchmark fractions" retrieves the
grade 4 same-denominator-or-numerator lesson). The tool-less retrieval
bridge for REALLMS models now spans the knowledge base; retrieval remains
advisory until a reader span or automaton trace supports the hit.

## Pending appendix

- Field-context array 7778951 (K-2 / 3-5 / 6-8): band 0 complete-with-
  cosmetic-FAILED (all 437 partials written; the one deprecation warning
  is root-caused and fixed); bands 1 and 2 running. The ceremony that
  commits this wave waits on the merged cache passing the drift check.
