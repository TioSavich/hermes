# Sourcing the phrases from the corpus — and an audit of my ear

Model: `claude-opus-5[1m]` (Opus 5, 1M context).
Date: 2026-07-25. Continues `2026-07-25-utterance-layers.md`.

Files changed: `scripts/research/build_attested_phrases.py` (new),
`knowledge/strategies/attested_phrases.pl` (new, generated),
`scripts/checks/attested_phrases.py` (new), `hermes/strategy_recognizer.pl`,
`scripts/checks/run_all.sh`, this report.

## The question

The last two reports flagged the same limit twice: `canonical_phrases.pl` holds
185 classroom phrasings written from one person's ear, checked for ordinary words
and nothing else. The owner's answer was that these strategies came from the
literature, so the corpus should carry the language they arose in.

It does, and the answer is yes with a substantial qualification.

## What the corpus holds

`data/research/research_shared.db`, 25 tables. The one that matters is
`automaton_instance_bindings`: 936 rows binding corpus rows to automaton
signatures, 68 signatures reached, each row carrying the `evidence` phrases that
justified the binding and a `bibtex_key` in its notes. Alongside it,
`strategy_instances` (2,276), `error_instances` (3,621), `strategy_moves` (8,950).

A binding looks like this:

```
strategy → addition/make_ten_split_leftover, confidence high, score 16.0
evidence: make ten; jump through 10; jump through ten; adding through 10;
          find the complement needed to make ten; partition the other addend
notes:    bibtex_key=MERJ_EllemorCollins_2009_Structuring
```

That is a phrase list with a citation. It was sitting unconsumed.

## What was built

`knowledge/strategies/attested_phrases.pl`, generated and byte-compared:

| | |
|---|---:|
| cited phrase rows | **860** |
| distinct phrase attachments | 226 |
| signatures reached | 52 of 214 |
| actions reached | 111 |
| distinct papers cited | **281** |
| quoted student utterances kept | 139 |

### The warrant is in two parts, and both are emitted

The citation warrants the phrase for the **signature** — that is what the corpus
row was bound to. It says nothing about which *step* of that signature the phrase
names. So each row also carries the content words the phrase shares with the
action's own label:

```prolog
attested_phrase(addition, count_on_from_larger, choose_larger_addend_as_start,
                [counting, on, from, first, or, larger],
                source('JMB_BoultonLewis_1998_Children\'s'),
                attachment(register(analyst), shared([larger]))).
```

A reader can reject the attachment and keep the citation. The check recomputes
every `shared` list from the phrase and the label and fails if the words are not
actually shared, so the step-level claim is never larger than what it shows.

Attachment needs two shared content words, or one that occurs in exactly one
action of that machine. That rule is conservative and it costs: **466 cited
phrases were dropped for overlapping no action label**, against 230 kept. Some of
those losses are morphology — "always subtracting the smaller digit" is cited for
`subtraction/smaller_from_larger_in_column`, and "subtracting" does not match
`subtract` in `subtract_smaller_from_larger_in_ones`, while "smaller" occurs in
two of that machine's actions and so fails the distinctness test. A stemmer would
recover a good number of those and would also start recovering wrong ones.

## The audit of my ear, which is the part worth reading

| | |
|---|---:|
| canonical actions I phrased | 90 |
| of those with any cited phrase attached | **44** |
| of those 44, where my wording shares a content word with a cited one | **11** |

So on 33 of the 44 actions where the literature does speak, my wording and the
literature's wording have no content word in common.

The reason is register, and I want to state it as the reading I believe rather
than as a finding I established. What the corpus supplies is what a researcher
calls a step: "appending the partial sums", "indiscriminately applying verbal
rules", "recognize the number combination". What I wrote was an attempt at what a
student says: "I made the bottoms match", "I gave them the same denominator".
Those are different registers, both turn up in a transcript, and non-overlap
between them is what you would expect rather than evidence that either is wrong.

What I cannot do from inside this corpus is prove that. The alternative reading —
that my phrasings are simply bad guesses — is not excluded by anything here. The
evidence I have for the register account is that where the literature *is* in
student register the two do converge: `make_ten_split_leftover` yields "make ten"
and "make one ten" from Sáenz-Ludlow 1998 and Brousseau 1999, and my authored
phrase for `regroup_to_base` was "made ten" / "make ten" / "got to ten". Eleven
of forty-four is the size of that convergence, and it is not large.

Every row is therefore marked `register(analyst)`, and the check fails if one
claims otherwise. The citation is not allowed to carry a claim about student voice
that the corpus does not support.

## The student voice the corpus does have

`error_instances.example` holds 1,540 rows with quoted utterances. 139 of them
belong to machines this repository runs, and they are emitted as
`attested_utterance/4` — cited, and deliberately **not** recognition surfaces,
because they are sentences and the recognizer matches phrases:

> "One-fourteenth… because you add one-seventh and another seventh it makes 14."
> — bound to `fraction/whole_number_grab`

> When asked to draw 7/5 of a candy bar, Bridget marked the bar into five parts,
> added two more pieces, and said "they turned into seven pieces instead of five
> pieces".

That is the register `canonical_phrases.pl` was reaching for, with a source
behind it. Mining those 139 into phrases is authoring work with a citation
underneath it, which is exactly why they are kept rather than summarized away.

## What the wiring changed, measured

`action_surface/2` now consults `attested_phrase/6`. Before and after, through the
MCP server:

| input | before | after |
|---|---:|---:|
| student, make ten | 7 candidates, `make_ten_split_leftover` 0.8 | unchanged |
| **literature wording** — "jump through ten and decompose the other addend" | **0 candidates** | 1 candidate |
| literature wording — "always subtracting the smaller digit" | 0 | 0 (dropped by the attachment rule) |
| student, denial | 8, make-ten absent | unchanged |
| noise | 0 | 0 |

Literature wording returned *nothing* before. It now returns something — and the
something is `base_ones_chunking` at 0.25 rather than `make_ten_split_leftover`,
because "decompose the other addend" reached that machine's own
`decompose_second_addend` first. So the gain is coverage, not accuracy, and it is
one case.

No regression: the round-trip check over all 69 signatures still passes, unrelated
text still abstains, and the student and denial cases are unchanged.

### The widening, stated

`action_spans/3` receives the action and not the signature, so a phrase cited for
one signature becomes a surface for the same-named action wherever it occurs. 138
of the 808 labels occur in more than one signature, and **159 of the 860 rows
touch an action whose name recurs**. The check counts them rather than leaving it
implied. Threading the signature through `action_spans/3` would remove the
widening and is a change to the recognizer's shape rather than to this data.

## Honest limits

- **52 signatures of 214, 111 actions, 44 canonical actions.** The corpus binds
  68 signatures; the tables hold 214.

  A claim in the first version of this line was wrong and is corrected here: I
  said the 43 automata registered earlier today were almost entirely unbound
  because the bindings predated their extractability. Running the mapper
  (`2026-07-25-running-the-corpus-mapper.md`) showed that **20 of the 43 were
  already bound**. The bindings were made by strategy name and knew about these
  strategies all along; what did not know about them was the transition tables. So
  the reason those 20 contribute no attested phrases is not that the corpus is
  silent about them — it is that `attested_phrases.pl` needs a machine to attach a
  phrase to, and until this morning there was none.
- **The analyst filter is a regex I wrote.** It drops phrases containing "scheme",
  "construct", "iterable", "coordination" and about twenty more, on the ground
  that a recognition surface has to be something said while working. That rule
  removes real research vocabulary and will remove some usable phrasing with it.
- **466 dropped against 230 kept.** The attachment rule loses more cited phrases
  than it keeps. Every one of those losses is a phrase the literature supplies and
  this file does not carry.
- **The register account is my reading.** 11 of 44 overlapping is the number; that
  the other 33 differ by register rather than by my error is an interpretation, and
  the report says so rather than asserting it.
- **139 utterances are unconsumed by design.** They are stalled input with a
  citation, marked as such, and the thing they are waiting for is authoring
  judgment about which phrase inside a sentence is the recognizable one.
- **Nothing here was checked against a transcript of a live classroom.** The
  corpus is published research about classrooms, which is a different thing and a
  better thing than my ear.

## Result

- **Yes, the phrases can be sourced.** 860 cited rows over 52 signatures and 111
  actions, from 281 papers, each carrying its citation and the shared words that
  attach it to a step.
- **139 quoted student utterances** recovered and cited, kept out of the surfaces
  because they are sentences.
- **The audit: 44 of my 90 phrased actions have literature support, and 11 of
  those 44 share wording with it.** The register account explains that and is not
  proved by it.
- Literature wording went from **recognizing nothing to recognizing something**,
  with no regression to the student cases or to abstention.
- The highest-yield follow-up is not more phrase work: it is re-running the
  corpus-to-automaton mapper now that 43 more signatures exist.
