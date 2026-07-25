# Can they parse — asking the running server instead of reading the source

Model: `claude-opus-5[1m]` (Opus 5, 1M context).
Date: 2026-07-25. Continues `2026-07-25-registering-the-43.md`.

Files changed: `hermes/strategy_recognizer.pl`,
`knowledge/strategies/canonical_phrases.pl` (new),
`scripts/checks/canonical_phrases.py` (new), `scripts/checks/run_all.sh`,
this report.

## The three questions

The owner asked whether the automata are recognizers as well as writers, whether
they can parse, and whether registering the 43 affords another abstraction step —
and suggested plugging into the Hermes MCP server to find out what is not
working, which is how the second and third answers arrived.

## Are they writers or recognizers

Both, and by two different mechanisms.

`run_action_automaton/6` is a **writer**: mode (+,+,+,+,-,-), given a strategy
kind and two inputs it produces an outcome and a trace. It cannot run backward —
the runners use `is/2` and guards that need bound arguments.

`hermes/strategy_recognizer.pl` is a **recognizer**, and it does parse. It
tokenizes a transcript, finds spans matching action surfaces, and walks the
matched actions through the automaton's transitions, reporting candidates with
token spans, a trace frontier, missing evidence, order conflicts, and
observed-transition provenance. An empty list is an abstention. That is a parse.

## What the MCP told me that the source did not

I drove `hermes/mcp/server.py` over stdio and asked it. Three things came back
that reading the Prolog had not made obvious.

**The tool description says five.** `strategy_recognize` announces itself as
aligning classroom language to *five* execution-observed traces. The source has 24
hand-written `action_phrase/2` facts, and they cover about five strategies.

**The recognition surface is the identifier.** Probing live:

| said | result |
|---|---|
| "choose larger addend as start hold other addend as count iterate successor ticks name last tick as sum" | `addition/count_on_from_larger`, confidence 1, accepting |
| "I started from the bigger number and counted on four more" | `[]` — abstention |

`action_surface/2` has three clauses: the authored phrase, the label split on
underscores, and a one-token synonym variant. So every label has *a* surface, and
for 784 of 808 that surface is the Prolog identifier. Speak the identifier and you
are recognized at confidence 1. Speak like a student and you are not recognized at
all.

**The newly registered 43 cannot be candidates, and get mis-attributed instead.**
`observed_strategy/3` yields 69 rows and `splitting` is not among them, because
registering a signature adds no input contract and therefore no observed edges.
Worse than invisible: speaking splitting's own labels returned
`fraction/unit_fraction_partition` at 0.4 and `fraction/unit_fraction_iteration`
at 0.2. A student doing splitting is read as doing something adjacent.

I also found a regression I had introduced in the previous slice. The recognizer
`:- include`s the transition tables by name, thirteen of them, and my registration
created `calculus.pl` and `probability.pl`. Those four automata had no recognition
surface at all. Two lines; the check now fails if a table exists that the
recognizer does not include.

None of that came from reading. It came from asking the server, which is the trick
the owner suggested and it paid for itself in the first probe — including catching
that the tool's parameter is `content` and not `text`, which a schema read would
also have given but a source read did not.

## The abstraction step, and it is the same one this arc opened with

The recognizer's wall is the wall the whole arc started at, in a different place.

- Then: 638 action labels, each needing individual treatment; 547 confined to one
  signature; no structure to compress. The fix was 122 canonical actions.
- Now: 808 action labels, each needing a classroom phrase; 24 authored, 3%. The
  fix is the same shape — author phrases for the **90 canonical actions that carry
  mapping rows**, and every local label inherits them through the map.

`knowledge/strategies/canonical_phrases.pl` holds 185 phrase variants over those
90 actions. One clause in `action_surface/2` reaches them:

```prolog
action_surface(Action, Phrase) :-
    canonical_action_of(Action, Canonical),
    canonical_phrase(Canonical, Phrase).
```

| | before | after |
|---|---:|---:|
| local labels with a classroom phrase | 24 of 808 | **808 of 808**, through 90 |
| authoring decisions to get there | 784 remaining | **90 done** |
| mapping rows reached | — | 1016 of 1016 |
| machines fully phrased | ~5 | **214 of 214** |

One phrase authored once for `align_to_common_unit` — "I gave them the same
denominator", "I put them in the same units", "I made the bottoms match" — now
serves the decimal, fraction and counting machines that each named that step
differently. That is the alphabet doing work rather than describing it, and it is
the first time in this arc the compression has produced a capability rather than a
measurement.

## What the live parse looks like now

Re-probed through MCP, on the phrasing that abstained before:

**"I started from the bigger number and counted on"** — 14 candidates.
`addition/count_on_from_larger` and `addition/count_all_when_count_on_available`
tied at 0.25, then twelve fraction and decimal comparison machines trailing from
0.17 down. The tie is honest: that sentence does not distinguish counting on from
the larger addend from counting all when counting on was available, and both are
in the list.

**"eight was close to ten so I split the other number, made ten, then added the
leftover and used both parts"** — 2 candidates:

| candidate | confidence | frontier |
|---|---:|---|
| `addition/make_ten_split_leftover` | 1 | accepting |
| `addition/make_ten_drop_leftover` | 0.6 | open |

That is the incompatible pair, live, from one utterance: the productive strategy
complete and its deformation partner still open. `reading_held_open/5` says both
readings of a diverged pair stay live and the corpus cannot say which is running;
here the recognizer says the same thing about an actual sentence, and the one that
is still open is the one whose divergence has not yet arrived in the words.

**"purple bicycle Tuesday"** — abstention. Widening the surface did not make it
answer everything, and the check asserts that on every run.

## What parsing over canonical words would buy, measured

Separately from the phrases, the canonical projection makes the corpus itself a
parser. Every one of the 232 machines across both genres spells a canonical word;
those words share prefixes, and the prefix tree is the parse.

| after n canonical actions | distinct prefixes | mean live candidates | median |
|---:|---:|---:|---:|
| 0 | 1 | 232.0 | 232 |
| 1 | 31 | 7.5 | 3 |
| 2 | 130 | 1.8 | 1 |
| 3 | 210 | 1.1 | 1 |

**82% of the corpus is uniquely identified after three canonical actions**: 4%
after one, 25% after two, 53% after three. 775 distinct prefixes carry 1107 action
slots. Seven machines never become unique — two pairs share a word outright
(`co_denominator_count_on_from_larger` with `co_denominator_make_base_transfer`,
and the two `count_marks_not_intervals` machines), and the rest are words that are
strict prefixes of another machine's.

The live set narrowing from 232 to a median of 1 over two actions, without ever
committing, is the shape the owner's rainbow image asked for. It is not built as a
runnable module yet; it is a measurement over data that exists, and the next slice
is the module.

## Two defects the probing turned up on the way

**A performance regression I introduced.** `canonical_action_of/2` reads
`action_maps/7`, which is per signature, so a label used by twelve signatures --
`emit` and `init` both are -- yielded its canonical action twelve times, and every
one of that action's phrases twelve times with it. The spans are sorted
downstream so the answers stayed right; the work multiplied. The recognizer's own
check went from finishing to not finishing inside two minutes. Wrapping the lookup
in `distinct/2` brought it to **0.26 seconds**, and `establish_base`, the one label
that genuinely carries two canonical actions, still yields both.

**A gate defect that predates this work.** Chasing that timeout, I found that
`scripts/checks/strategy_recognizer.pl` prints nothing and exits 0 — and always
had. `run_all.sh` invokes it as `swipl -q -l paths.pl -s check.pl`, and a file
whose entry point is `:- initialization(main, main)` does not run `main` when it is
merely loaded with `-s`. The same is true of
`scripts/checks/math_claim_language.pl`. **Both checks have been in the suite
contributing exit 0 without asserting anything.** Run properly, with `-g main -t
halt`, both pass — `PASS strategy recognizers: 69/69 execution-observed
signatures` and `PASS quotation-aware math claim language` — so nothing was
broken behind them. But nothing was being checked either, and the check that was
silent is exactly the one that would have caught the recognition-surface gap this
report is about. `run_all.sh` now passes `-g main -t halt` to both, with a comment
saying why so it does not get tidied away.

That is what the MCP trick was worth. I went looking for whether classroom
language parsed, and found a slow lookup and two checks that were not running.

## Honest limits

- **Precision fell where recall rose.** Fourteen candidates for a five-word
  sentence is noise. The trailing twelve are fraction and decimal comparison
  machines matching generic phrases like "I compared them" and "I counted them".
  The fix is weighting by span coverage or a confidence floor, and I did not do it
  because setting a threshold is a policy and the last slice removed a policy I had
  invented. The right version of it comes from watching real transcripts, not from
  me choosing a number.
- **The 43 still cannot be candidates.** They have no input contracts, so no
  observed edges, so `observed_strategy/3` does not yield them. The phrase layer
  covers all 214 machines' surfaces and only 69 can be proposed. Contracts are the
  next slice and they are what would let a student doing `splitting` be read as
  doing splitting.
- **185 phrases are one person's ear.** They are reviewed classroom phrasings in
  the sense that I wrote them to be plausible and the check enforces that they use
  ordinary words, contain no technical term the alphabet cites, and do not repeat
  their action's own name. Nothing has checked them against a transcript. Whether
  a real fourth-grader says "I made the bottoms match" is exactly the kind of
  question this corpus cannot answer.
- **A phrase matching is not a diagnosis.** The recognizer's own docstring says a
  complete alignment is evidence for a candidate strategy and not a claim that the
  strategy was used. Widening the surface widens the evidence and changes nothing
  about that.
- **The abstraction has a cost I can name and not measure.** Authoring per
  canonical action means a phrase cannot distinguish two local labels that share
  an action. `align_to_common_unit` covers 19 mapping rows across three families;
  a student's wording now aligns to all of them equally. Whether that costs more
  than the 784 unauthored labels cost is not something this corpus can settle.

## Result

- **They write and they recognize.** `run_action_automaton/6` generates;
  `strategy_recognizer.pl` parses transcripts into candidates with frontiers and
  abstains honestly.
- **They parsed only identifiers.** 24 of 808 labels had a classroom phrase, five
  strategies' worth, and the rest required speaking Prolog identifiers — found by
  probing the live server, not by reading.
- **The abstraction step is the arc's own, applied again**: 808 authoring
  decisions became 90. 185 phrases over 90 canonical actions now reach 1016 of
  1016 mapping rows and 214 of 214 machines.
- **The live parse holds both readings open**: make-ten returns its productive
  strategy accepting and its deformation partner open, from one sentence.
- **One regression fixed**: two transition tables my registration created were
  not included by the recognizer, and the check now catches that class.
- Next: input contracts for the 43, which is the one thing standing between the
  fraction schemes having a surface and their being proposable.
