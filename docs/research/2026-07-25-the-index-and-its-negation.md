# The index and its negation

Date: 2026-07-25

## What was built

`scripts/research/build_corpus_window.py` reads the transition tables, the
discursive automata, the canonical action map, and the action grammar. One run
writes both forms of the index:

- `knowledge/index/corpus_window.pl` is the queryable form.
- `knowledge/index/corpus_window.txt` is the ASCII form intended for model
  input.

Each machine row carries its normative arc and four ordered action groups:
shell, core, closure, and other. The live action grammar assigns a machine to an
arc through `machine_grammar/6`. `normative_arc/3` declares the arc and its
collapsed stance word; it does not take family and signature arguments.

The brief names `window_row/6` and also requires a fourth action list. Six
arguments cannot carry family, signature, arc, and four lists. The generated
file therefore stores one lossless `window_row/7` fact per machine and provides
`window_row/6` as a projection over it. The projection returns every machine.
The seventh argument retains the delegation actions that otherwise have no
group.

`scripts/research/build_relevance_negation.py` writes
`knowledge/index/relevance_negation.pl`. Its `excludes/4` facts record
subtractions over grade bands, machine families, lessons, and standards.
`surviving_slices/3` returns the remaining slices and the excluded slices with
their reasons.

The lesson evidence comes from the live `encoded_im_lesson/6` and
`lesson_topics/2` predicates. Machine evidence comes from the generated index.
The topic vocabulary comes from `operation_topic/2` and the keyword terms in
`text_topic/2`. The Grade 2 floor for the commissioned thirds case comes from a
`2.G.A.3` standard anchor that names thirds.

Two checks hold these artifacts against their sources:

- `scripts/checks/corpus_window.py`
- `scripts/checks/relevance_negation.py`

Both checks run from `scripts/checks/run_all.sh`.

## Check results

The corpus index check reports:

| Claim | Result |
|---|---:|
| Machine rows | 232 of 232 |
| Legend actions | 122 |
| Normative arcs | 24 |
| Plain-text bytes | 51,452 |
| `bytes/4` estimate | 12,863 tokens |
| Actions in `Other` | 19 |
| Machines with `Other` | 14 |
| Registers in `Other` | `delegation` |

Both artifacts regenerate byte-identically twice. Every action carries the
exact genre, register, and stance from `action_register/4`. Every partition
reproduces the canonical action word.

The relevance check reports:

| Claim | Result |
|---|---:|
| Exclusion facts whose reasons resolve | 18,916 |
| Operation topics with surviving content | 15 of 15 |
| Kindergarten lessons excluded for `fraction/thirds` | 139 |
| Lessons surviving `fraction/thirds` | 209 |
| Live lesson predicate rows | 1,308 |
| Field-context cache rows | 1,317 |
| Cache-only gaps | 9 |

The representative subtraction counts are:

| Topic | Lessons | Standards | Machines |
|---|---:|---:|---:|
| `fraction` | 245 / 1,308 | 228 / 228 | 68 / 232 |
| `geometry` | 408 / 1,308 | 228 / 228 | 86 / 232 |
| `algebraic` | 384 / 1,308 | 228 / 228 | 54 / 232 |
| `probability` | 123 / 1,308 | 228 / 228 | 42 / 232 |

A caller asking why a kindergarten lesson is absent from the thirds query gets
ground terms such as:

```prolog
lesson_grade_below(
    2,
    0,
    standard_anchor_evidence(im_grade2_u6_l7, ccss, '2.G.A.3')
).
```

## What the index loses

The action lists preserve step order within each group. They do not preserve the
interleaving among shell, core, closure, and other. Describing this as a loss of
within-group order would be inaccurate.

The canonical projection also drops each edge's local label. It drops transition
provenance, including citations and observed-source tags. Mapping evidence,
confidence, and review status remain in `action_vocabulary_map.pl`, not in the
index. States and accepting paths also remain in the transition tables.

The index supports selection of a machine or arc. It does not replace the source
record needed to recover why an action was mapped or where an edge came from.

## What the negation layer cannot ground

The live lesson predicate yields 1,308 rows, not the 1,317 stated in the brief.
The cache has nine codes with no current `encoded_im_lesson/6` row:

- `IM-G6-U5-L16`
- `IM-G7-U7-L21`
- `IM-G7-U8-L21`
- `IM-G8-U2-L14`
- `IM-G8-U2-L15`
- `IM-G8-U6-L14`
- `IM-G8-U6-L17`
- `IM-G8-U6-L18`
- `IM-G8-U7-L20`

The generated file records each as `source_gap(cache_only_lesson, Code)`. They
are not treated as live slices.

`text_topic/2` has no keyword rule for `third` or `thirds`. The commissioned
query uses `fraction/thirds`, which normalizes through the existing `fraction`
keyword and receives a Grade 2 floor from the thirds standard. A bare `thirds`
query does not have enough predicate support and is not normalized.

No generic standard-topic mismatch is emitted. A standard anchor can bear on
more than one topic, and the absence of a keyword match does not establish
irrelevance. This is why all 228 standards survive the four representative
topic queries. The thirds query can exclude standards below Grade 2 because
that boundary has a named standard anchor.

Three machine families have no topic evidence under the present predicates:
`discourse`, `measurement`, and `statistics`. The generator does not infer a
mismatch for them. Likewise, 103 live lessons receive an empty topic list from
`lesson_topics/2`; they survive topic mismatch subtraction unless another
grounded reason excludes them.

## Honest limits

Nobody has yet asked a model a question with this index, so its value is
untested. The `bytes/4` number is an estimate rather than a tokenizer result.

Lesson subtraction is relative to what `lesson_topics/2` records. It establishes
that the query topic is absent from that bounded predicate result, not that the
lesson could never bear on the topic in another analysis.

The relevance file is query data, not model input. Its size does not measure the
prompt reduction. The check counts surviving slices and does not measure how
many source tokens a later retrieval step serves.

The earlier 8,900-token calculation used one compact line per machine. The
generated text includes closure, other, and a reading-oriented two-line machine
layout. Its current estimate is 12,863 tokens. No compression ratio is asserted.
