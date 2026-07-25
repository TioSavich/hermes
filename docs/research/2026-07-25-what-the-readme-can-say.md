# The distance to the sentence the README is supposed to end up saying

Model: `claude-opus-5[1m]` (Opus 5, 1M context). Date: 2026-07-25.
Files changed: this one. Everything below is counted from the tree at `0f49453`.

## The target, in the owner's words

> Eventually I'd like the root README to say "all x, y, z… were analyzed. The
> results were minified through an adversarial fractal loop that preserved
> details but served abstract formulae for querying the prolog base" where x is
> the IM curricula, Y is the literature base

Four clauses, and they are at four different distances. This document measures
each so the sentence gets written when it is true rather than when it sounds
ready. Two lanes dispatched today (tasks 126 and 127) work on the third clause;
nothing yet works on the fourth.

## Clause 1 — "all the IM curricula were analyzed"

`curriculum/im/coverage/im_coverage.json` and its generated summary are the
authority. **1,308 published lessons, K through 8.** Reading the Total row:

| what | lessons | of 1,308 |
|---|---:|---:|
| carry their source text | 1,308 | **100%** |
| carry field context | 1,308 | **100%** |
| carry a standard (lesson- or unit-level) | 1,308 | **100%** |
| resolve to an automaton | 863 | 66% |
| carry a hand-authored pairing | 609 | 47% |
| carry a compiled context | 426 | 33% |
| carry a misconception | 296 | 23% |
| render anything | 522 | 40% |
| are diagnostic-ready | 59 | **4.5%** |

**What is already true and can be written today:** every published K-8 IM lesson
carries its verbatim text, its field context, and a standard anchor. That is a
100% claim with a generated ledger behind it, and it is not a small one.

**What is not true:** that the lessons were *analyzed*. Two thirds resolve to an
automaton and one in twenty-two is diagnostic-ready.

**Where the shortfall is concentrated**, which is the useful part:

| grade | lessons | strategy resolves | diagnostic ready |
|---|---:|---:|---:|
| K–5 | 879 | 729 (83%) | 50 |
| 6 | 152 | 128 (84%) | 3 |
| 7 | 143 | **6 (4%)** | 6 |
| 8 | 134 | **0** | 0 |

Grades 7 and 8 have complete text, complete context, complete standards, and
**almost no strategy resolution** — 6 of 277. Grade 8 has none. The middle-school
work that landed yesterday gave those lessons their activity statements; it did
not give them automata, and the coverage table has been saying so.

**Named gaps, so the sentence does not have to pretend:**

- **The IM activity sheets.** The owner names these as unfinished business and
  they are not in the tree. Lesson text is intaken; the student-facing sheets are
  a separate source.
- **High school.** IM 9-12 is organized by course rather than by grade, and the
  tree holds K-8 only. The handoff's queue item 7 is the intake study.
- **A counting trap for anyone measuring this later:** `im_lesson/6` yields
  **1,571 solutions for 1,308 distinct codes**, because vision variants share a
  code. `aggregate_all(count, im_lesson(...), N)` over-counts by 20%. Count
  distinct codes.

## Clause 2 — "all the literature base was analyzed"

| what | count |
|---|---:|
| articles in `research_shared.db` | 2,682 |
| with a bibtex key | 2,436 |
| converted to text on Big Red | **2,183** |
| conversion failures, recorded | 8 |
| automaton bindings made | 936 |
| **distinct automata those bindings reach** | **68 of 232** |
| distinct papers behind the bindings | 414 |
| papers cited in `attested_phrases.pl` | 281 |
| bindings carrying human review | **0** |

**What is true today:** 2,183 of 2,191 attempted items converted, with the 8
failures recorded by name rather than dropped.

**What is not true:** that the literature was analyzed. The bindings reach **68
of 232 machines**, which is 29%, and not one of the 936 has been reviewed by a
person. A further 268 candidate bindings sit in
`data/research/corpus_binding_proposals.json` waiting on exactly that review.

There is also a rights constraint the sentence has to survive: under the binding
ruling from `18d634d`, full texts never enter the public repo. Whatever the README
claims about the literature, it claims about material the repo describes and does
not contain.

## Clause 3 — "minified through an adversarial fractal loop"

This is the one with work in flight and the one where the honest word today is
*half*.

**What exists:** the shared alphabet (122 canonical actions over 1,016 mapping
rows), the arc layer (232 machines spelling 24 arcs), and the measurement that a
one-line-per-machine index plus its legend is ~8,900 tokens against ~727,000 for
the corpus served whole. That is the minification, computed.

**What does not exist yet:** the loop, and the adversary.

- Task 126 (dispatched) builds the index as a real artifact and the negation
  layer that prunes it — the owner's "if we know we're talking about thirds, we
  don't need the kindergarten standards or lessons." That is the *subtractive*
  half of adversarial: exclusion with a recorded reason.
- The *generative* half — noise produced by deforming canonical sentences so the
  layers can learn to filter each other — is proposed and unbuilt
  (`proposals/2026-07-25-mutual-noise-layers.md`). Section 6 of that proposal
  found the generative machinery already installed as DCGs and also found that
  the math-claim grammar does not terminate when run backwards from a bound term.
  So the adversary is one mode-fix away from possible, not built.
- **"Fractal" is measured and partial**: 168 of 232 machines (72%) parse
  shell → core → closure, 14 carry an explicit subroutine invocation, and 64 do
  not fit the shape and are undiagnosed.

The word "loop" is doing the most work in the owner's sentence and has the least
behind it. Nothing currently feeds a filter's output back to the generator.

## Clause 4 — "served abstract formulae for querying the prolog base"

**Nothing has been served.** No model has been asked a question with the index,
so the 81× ratio is arithmetic and not evidence. This clause has no work in
flight and it is the cheapest of the four to start: one question, asked twice,
once with the window and once with a slice of the shards, and a note on which
answer was better.

## What the README could honestly say tonight

> Every published K-8 Illustrative Mathematics lesson (1,308) carries its
> verbatim text, its field context, and a standard anchor; 863 resolve to a
> strategy automaton. 2,183 literature items were converted from PDF, and 936
> bindings connect them to 68 of the 232 automata the repository runs. The
> 638 bespoke action labels those automata used were mapped onto a shared
> alphabet of 122 canonical actions, and the 232 machines spell 24 normative
> arcs — a retrieval index of roughly 8,900 tokens over a corpus of roughly
> 727,000. What the index is worth has not been tested against a model.

Every number in that paragraph has a generated ledger or a check behind it. It is
narrower than the target sentence and it says "were converted" and "were mapped"
where the target says "were analyzed," because conversion and mapping are what
happened.

## The four things that would close the gap, cheapest first

1. **Ask a model one question with the index.** Closes clause 4 from "untested"
   to "tested once." Costs an afternoon.
2. **Review the 268 binding proposals.** Owner judgment, not code. Moves clause 2
   from 68 machines toward 76 and from zero reviewed to some.
3. **Grades 7 and 8 strategy resolution.** 277 lessons with complete text and no
   automata. The largest single coverage gap in the tree and the one the owner's
   "completeness is a concern" most directly names.
4. **The generator's mode fix and the filter loop.** Turns "adversarial" from a
   description of intent into a description of code.

## Honest limits

- **This is a census, not an audit.** It reports what the generated coverage
  ledger and the corpus database say. It does not check whether a lesson that
  "resolves to an automaton" resolves to the *right* one.
- **The 4.5% diagnostic-ready figure is the coverage builder's own definition**,
  and I have not read what that column requires.
- **"Analyzed" is doing unexamined work in the target sentence too.** For a
  lesson, it might mean any of: text present, standard anchored, automaton
  resolved, misconception attached, diagnostic ready. Those are 100%, 100%, 66%,
  23%, and 4.5%. The sentence should name which one it means.
