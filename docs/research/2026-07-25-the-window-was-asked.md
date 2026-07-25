# The window was asked

Model: `claude-opus-5[1m]` (Opus 5, 1M context) as controller; the model under
test is `gemma-4-31B-it` via REALLMS.
Date: 2026-07-25. Closes the limit named in `2026-07-25-the-index-and-its-negation.md`
and in `2026-07-25-the-fractal-measured.md`.

Files: `scripts/research/ask_the_window.py`, `data/research/window_vs_shards.json`,
this report.

## The claim that was outstanding

Three reports in a row ended with the same admission. The index is 12,863 tokens
where the material behind it is roughly 727,000, and:

> Nobody has asked a model a question with this index, so its value is untested.
> Until that happens the ratio is arithmetic, not evidence.

It has now been asked.

## The design, and the one decision that shapes everything

Two prompts of **identical size** — 51,452 bytes:

| condition | what that budget buys |
|---|---:|
| **window** | the whole index: **232 of 232 machines**, plus the legend |
| **shards** | raw `automaton_transition/6` rows for the machines a keyword-overlap retriever ranks highest: **36 of 232** (median) |

One task, asked of both: a researcher's phrase for a student's method is given,
and the model must name the machine whose steps it describes, as `family/signature`,
or answer `none`.

Thirty items, one per machine, drawn from `automaton_instance_bindings.evidence` —
phrases the literature uses, each already bound to a signature and cited. Ground
truth is therefore not mine.

**The decision that shapes the result:** every item is filtered to share **no
content word** with any action label of its own machine. Without that filter, a
phrase like "make ten" reaches `regroup_to_base` by string overlap and the test
measures a keyword matcher rather than either prompt. With it, the questions are
hard on purpose — and, as the limits below say plainly, the filter removes the
shard retriever's own mechanism along with the shortcut.

## The result

```
window   exact  9/30    family 16/30    abstained 1
shards   exact  1/30    family  7/30    abstained 8
```

Paired, per item:

| | count |
|---|---:|
| both conditions exact | **0** |
| window only | **9** |
| shards only | 1 |
| neither | 20 |

McNemar exact, two-sided, on the ten discordant pairs: **p = 0.0215**. So the
difference is unlikely to be noise at n = 30, which is more than could be said for
a ratio.

**Both = 0 is the detail worth sitting with.** There is not one item the two
prompts both got right. They are not the same capability at different strengths;
they succeed on disjoint questions. The one item shards won —
`addition/column_addition_with_carrying` from "written algorithms" — is a phrase
so generic that the index's arc and step words give nothing to grip, while a raw
table happened to surface the machine.

## What this establishes

**The compression is no longer arithmetic.** A 12,863-token index of 232 machines
outperformed an equal-budget slice of the raw material at routing a description to
its machine, by 9 to 1 exact and 16 to 7 at the family level, significantly. The
stained-glass framing had a testable consequence and the consequence held.

**Abstention behaves the way the shape predicts.** The shard condition answered
`none` eight times against the window's one, which is what a prompt holding 36 of
232 machines should do when the answer is usually among the other 196. The window
almost never lacks the right machine; its failures are failures of discrimination,
not of coverage. Those are different problems and only the second is fixed by more
tokens.

## Honest limits

- **Better is not good. 9 of 30 is 30%.** As a router the index is right about a
  third of the time on deliberately hard items, and a system that acted on that
  without review would be wrong twice for every time it was right. The family-level
  16 of 30 is the more usable number and it is still barely half.
- **The filter handicaps the shard condition in a specific way, and I chose it.**
  Excluding lexically-matchable phrases removes exactly what a keyword retriever
  runs on. So this is a fair test of the window on hard cases and an unfair test of
  retrieval-over-shards in general. The honest statement of the finding: *when
  lexical matching cannot work, the structured index still routes and the keyword
  baseline abstains.* Read as "the window beats the shards" it overclaims.
- **The baseline is keyword overlap, not a good retriever.** An embedding retriever
  over the same shards would be the real competitor, and this repository has
  embedding indexes for four domains that were not used here. That comparison is
  the obvious next one and it may go the other way.
- **One model, one run, n = 30.** `gemma-4-31B-it`. No repeat, no second model, no
  prompt variation. p = 0.0215 speaks to the pairing, not to generality.
- **The window is not doing what the metaphor says.** It answers from action names
  and arcs, because that is all it carries. It holds no phrases, no citations, no
  student language. The nine it got right, it got right from step vocabulary alone,
  which is a fact about how legible the 122-action alphabet is and is arguably the
  most interesting thing here.
- **The driver is not checkpointed.** It writes its JSON at the end, so a failure
  at item 29 would have lost the run — the discipline applied to the 271-lesson
  driver and not to this one. It survived; the omission was still mine.

## Result

- Asked and answered: **9/30 against 1/30 exact, p = 0.0215**, at identical token
  budget, on items built to have no lexical shortcut.
- **Zero items were answered by both**, so the index and the raw slice are doing
  different work rather than the same work unevenly.
- The index's failures are discrimination, the slice's are coverage.
- Absolute accuracy is 30% exact and 53% family, and the next comparison worth
  running is against an embedding retriever rather than keyword overlap.
