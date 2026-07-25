# Lesson topic scan and build-time cache

## What landed, and what did not

Two implementations of the same scan were written today and only one is in the
tree.

The implementer's version replaced the `text_topic/2` clause wall with a keyword
automaton: four dynamic predicates assembled at load, token splitting that keeps
separators, adjacent-token matching for the ten multi-word keywords, and a
special case for the space-prefixed ` ratio`. It was byte-equivalent to the
original and **9.6% slower** on its sample, at +267/-105 lines.

The controller kept its keyword *table* and discarded its machinery. What is in
the tree is a flat table and one clause:

```prolog
text_topic(Text, Topic) :-
    topic_keyword(Keyword, Topic),
    sub_atom(Text, _, _, _, Keyword).
```

with 76 `topic_keyword/2` facts. Multi-word keywords (`dot plot`, `times as many`)
and ` ratio` with its leading space are ordinary substrings, so none of the
adjacent-token logic or the leading-space case is needed. Net against the
original: **105 insertions, 108 deletions** — the file is three lines shorter than
before either version was written, and the keyword set is now a flat table anyone
can edit rather than fifteen clauses of disjunction.

The reasoning: the automaton's only justification was speed, it did not deliver
speed, and it converted editable data into assembled state. What was worth keeping
was the extraction of keywords into facts, which is a real improvement in form.

## Matching decision

Substring semantics are preserved exactly. A single-word keyword still matches
inside a larger token, so `area` matches `areas` and `rate` matches `strategy`.
This is a reimplementation and not a retuning; no lesson's topics changed.

The keyword table was diffed mechanically against the original clause bodies
before either version landed: **76 (topic, keyword) pairs in the original, 76 in
the table, zero in one and not the other** — 65 single-word, 10 multi-word, and
` ratio`.

## Equivalence, through two independent implementations

The implementer wrote one cold SWI-Prolog process's topic output for every
coverage code before its change and another after. Both files were 79,837 bytes
with SHA-256

```text
d4e0343dfa3171f3c833e2f2354486cb80757cb4e4eaf7c5c423fcb55245396b
```

and `cmp` reported byte equality. The generated cache from that version had
SHA-256

```text
6d59248b2c2a598f12e1298307b650ebae3581a7d21257dda9d3e967ca436cf4
```

**The flat table reproduces that cache byte for byte**, same SHA, twice, and the
committed cache check recomputes all 1,317 lists and passes. So the chain holds
at both links: original ≡ automaton (the implementer's comparison) and automaton
≡ flat table (identical artifact). Two implementations written without reference
to each other converge on the same 1,317 facts.

## Denominators

`curriculum/im/coverage/im_coverage.json` holds 1,308 published lesson codes and
9 encoded-but-unpublished, for 1,317 cache keys. The live `im_lesson/6` surface
covers the 1,308; the 9 are cache-only and the negation index records each as
`source_gap(cache_only_lesson, Code)`. A first run of this work refused to build
until that difference was resolved, which was the correct call.

One counting trap, verified: **`im_lesson/6` yields 1,571 solutions for 1,308
distinct codes**, because vision variants share a code. Sort the codes;
`aggregate_all(count, im_lesson(...), N)` over-counts by 20%.

## Timing

| path | wall | note |
|---|---:|---|
| cached `lesson_topics/2`, 54 lessons | 0.000215 s | implementer's measurement |
| uncached, 54 lessons, original scanner | 0.297543 s | implementer's baseline |
| uncached, 54 lessons, automaton | 0.326008 s | 1.10× the original |
| uncached, all 1,317, flat table (builder) | 8.95 s | controller's measurement |

**The cache is where the gain is: about 1,385× on the cached path.** That number
does not depend on which scanner sits underneath it.

**The uncached comparison is unresolved and this report will not assert a ratio.**
The controller's 8.95 s over 1,317 lessons and the implementer's 0.2975 s over 54
are not comparable: they use different goals (`compute_lesson_topics/2` through
the builder versus `lesson_topics/2` directly) and different samples. An attempt
to time the original over the same 1,317 codes exceeded a 120-second wall and was
killed, and three further attempts to isolate `text_topic/2` alone also hung, so
no clean scanner-only figure was obtained. What can be said: the flat table
computes 1,317 lessons in under nine seconds, and the implementer's 54-lesson
sample was the first six codes per grade, which is short K-heavy text and may not
represent the corpus that the 30-second-per-lesson claim came from.

**That claim is now doubtful.** The 2026-07-25 handoff attributes ~30 s/lesson to
these `sub_atom` scans. 1,317 lessons compute in 8.95 s, which is about 7 ms each.
Whatever cost the field-context builder was paying, this scan is not it, and
optimizing here on the strength of that attribution would have been optimizing the
wrong thing.

## Existing field-context errors

The committed field-context cache still has 49 explicit error entries. This
work did not run `--retry-errors` and did not rewrite that artifact. The entries
currently comprise 36 external 600-second wall errors and 4 in-Prolog
120-second limit errors. The other 9 report `field_context_dict/2 failed`.

The implementer's reading was that the cache plausibly unblocks the 40
timeout-related entries, because `lesson_topics/2` now reads a generated fact
before the per-process memo or the computation.

**That reading rests on an assumption the timing above undercuts.** It only
follows if the topic scan was a large part of what those lessons spent their 600
seconds on, and 1,317 lessons now compute in 8.95 s — about 7 ms each. A stall
that hit a ten-minute external wall was not spending it here. Saving 7 ms per
lesson will not rescue a lesson that timed out at 600 s unless the scan was being
re-entered thousands of times per lesson, which nothing measured today shows.

So the honest position: the cache removes one recomputation from the path and may
help; the 49 entries stay error entries until a retry says otherwise; and the
lesson_topics memoization should stop being described as "the real cure" for those
stalls until something identifies where the 600 seconds actually go. The 9 plain
`field_context_dict/2 failed` entries do not name a timeout at all and this change
gives no basis for predicting them.

## Limits

The generated facts must be rebuilt when lesson text or standard evidence
changes. The check makes drift fail, but it does not update the artifact.
The timing sample measures this checkout on one machine and does not establish a
general speed ratio for uncached scanning.
