# Strategy recognition benchmark

## Result

The recognizer reads the literature register well and the student register
badly on this benchmark.

| machine-level arm | items | recall@1 | recall@3 | recall@5 | family recall@1 | abstention | candidates per firing item |
|---|---:|---:|---:|---:|---:|---:|---:|
| literature | 860 | 89.9% | 97.4% | 97.7% | 96.7% | 2.2% | 1.45 |
| student | 139 | 6.5% | 6.5% | 7.9% | 10.8% | 77.0% | 3.91 |

Family recall counts an item when the top candidate names the gold family,
including exact machine matches. It separates family routing from signature
selection. Candidates per firing item is a precision proxy, not precision:
these data contain positive labels and no negative examples, so false-positive
precision cannot be calculated.

Abstention is not a failure by itself; an unwarranted firing is worse.
On the student arm the main result is abstention: 107 of 139 items return no
candidate. Nine student items place the gold machine first and fifteen place
its family first.

## Arms

The literature arm contains all 860 `attested_phrase/6` rows. Each row keeps the
family and signature assigned by the corpus mapper, along with the paper key in
`data/research/research_shared.db`. It tests routing from terms researchers use
for a strategy to the corpus-bound machine.

The student arm contains all 139 `attested_utterance/4` rows. These are quoted
or reported student utterances with the machine and paper key carried by the
same corpus source. It tests the recognizer against longer student-register
language without deriving new recognition phrases from those utterances.

The authored arm contains the 185 `canonical_phrase/2` rows. It is a
contaminated control because these phrases are recognition surfaces authored
for this repository. Its gold label is the canonical action, not a family or
signature.

## Authored control: action-level result

The top candidate recovers the gold canonical action for 151 of 185 authored
items, or 81.6%. Twenty-two items abstain. Firing items return 8.29 candidates
on average.

This arm measures a different thing at a different grain and is not comparable
to the machine-level arms. The scorer checks the top candidate's
`recovered_action_order` and `matched_spans` action fields, then projects those
local actions through the existing action map. It does not create or consult a
set of gold machines. The authored result is not included in recall@1, recall@3,
recall@5, or an average with the other arms.

## Construction and limits

The benchmark is generated from
`knowledge/strategies/attested_phrases.pl` and
`knowledge/strategies/canonical_phrases.pl`. The three arms have no normalized
text in common, so cross-arm deduplication removes zero rows and records an
overlap count of zero.

The literature arm is row-weighted. Its 860 corpus rows contain 193 distinct
normalized texts, and repeated text remains when the corpus carries another
binding or citation. A repeated text can therefore be scored more than once.
Four distinct literature texts carry more than one machine label. The artifact
records that count so this weighting is inspectable.

The literature phrases are already direct recognizer surfaces. Its high score
therefore measures whether those stored action phrases route back to the
corpus-bound machine; it is not a held-out estimate of transfer to unseen
research language. The student utterances are not recognition surfaces, which
makes the low student score the more relevant result for the next recognition
work. No recognizer, surface, transition table, or phrase file changed during
this measurement.

## Reproduce

From the repository root:

```bash
python3 scripts/research/score_recognition_benchmark.py
```

The scorer starts one SWI-Prolog process for the whole selected run with
`-g main -t halt`. The integrity check regenerates the JSON twice, validates
machine labels and article citations, then scores the same fixed subset twice.
It compares those two results without imposing a score threshold.
