# Brandomian vocabulary tagger

`scripts/research/brandomian_tagger.py` is a deterministic, standard-library
pre-processor for numbered transcripts. It emits one JSONL object per utterance:

```json
{"id":"u0072","spans":[{"type":"anaphoric_unresolved","text":"it","start":8,"end":10}]}
```

The output is surface material for a later reader or Prolog chain. It does not
identify commitments, resolve anaphora, establish an inference, or adjudicate a
speaker's claim. Untagged is the default.

## Vocabulary basis and limits

The categories are lexical proxies for distinctions that Brandom develops in
*Making It Explicit* (Harvard University Press, 1994), especially its account
of inferential articulation, anaphora, and normative scorekeeping, and in
*Between Saying and Doing* (Oxford University Press, 2008), especially its
account of pragmatic vocabulary and explicitating relations. They are not a
measurement instrument for Brandomian statuses.

| Surface category | Source distinction | Deterministic rule and limit |
| --- | --- | --- |
| `deictic` | Demonstratives and indexical vocabulary participate in anaphoric and inferential articulation (*Making It Explicit*). | `this`, `that`, `here`, `now`, and `these` are marked. The tag does not supply a referent. |
| `anaphoric_unresolved` and `anaphoric_candidate_window` | Brandom treats anaphora as an expressive resource whose antecedent relations matter for content (*Making It Explicit*). | `it`, `they`, and `one` are marked unresolved. Up to eight preceding tokens in the same utterance are supplied as a candidate window only; it is not an antecedent resolution. |
| `alethic_modal` | Modal vocabulary can make inferential necessity explicit (*Making It Explicit*; *Between Saying and Doing*). | `must`, `cannot`, and `has to be` are marked. No such lexical span occurs in this transcript. |
| `normative_deontic` | Normative statuses and the practices of attributing them are central to scorekeeping (*Making It Explicit*). | `should`, `allowed`, `supposed to`, and `have to` forms are marked. This is not a commitment attribution. |
| `observational` | Empirical vocabulary is distinguished from vocabulary that makes inferential or normative relations explicit (*Making It Explicit*). | The literal lexical markers `I see`, `count`, `measure`, and `got` are marked. The tag makes no epistemic assessment. |
| `interrogative` | Force and pragmatic role matter to an account of saying and doing (*Between Saying and Doing*). | A question mark or a conservative question opening marks the whole utterance as interrogative. It does not infer uptake or a speech-act classification. |
| `negation` | Negation is an expressive logical vocabulary in Brandom's inferentialist treatment (*Making It Explicit*). | A restricted list (`not`, `no`, `never`, and contracted forms) is marked; scope is not computed. |
| `substitution_inference_candidate` | Substitutional relations can articulate inferentially significant contents (*Making It Explicit*). | The two terms of `X is Y`, `X means Y`, `X is equal to Y`, and `X is the same as Y` frames are marked as candidates. The pairing records neither identity nor entitlement to substitute. |

The owner's PML modes already distinguish subjective (`S`), objective (`O`),
and normative (`N`) validity in `formal/pml/pml_operators.pl`. This pass
overlaps most directly with lexical normative-deontic material and may offer
surface material relevant to objective or subjective readings. It does not map
surface spans to an `S`/`O`/`N` mode, PML operator, force, uptake, or a
commitment. Deixis, anaphora, negation, questions, and substitution candidates
therefore remain non-overlapping input for later interpretation.

## Run

```sh
python3 scripts/research/brandomian_tagger.py \
  scripts/research/talkmoves_rerun_out/lesson_run3/tm_0007_lesson_report.json \
  --output tm_0007_brandomian.jsonl
```

The input is the embedded `report.transcript` in the specified lesson-run JSON.
The tagger validates numbered `U0001 Speaker: utterance` lines and writes JSONL
to stdout unless `--output` is provided. `brandomian_lexicons.json` is the
auditable lexical configuration.

## tm_0007 demonstration

The run processed 470 utterances: 294 contained at least one span and 176 were
left untagged. It produced 689 spans. The examples preserve source utterance
text; the right-hand column lists representative emitted spans.

| ID | Utterance | Tagged spans |
| --- | --- | --- |
| u0003 | Our lesson today is working with whole numbers and mixed numbers with fractions. | substitution candidates: `Our lesson today`; `working with whole numbers and mixed numbers with fractions` |
| u0007 | At this point, you have a couple strategies to be able to do this. | deictic: `this`, `this` |
| u0008 | Can you guys think of two strategies that you can use to be able to divide a whole number by a fraction? | interrogative whole utterance; deictic: `that` |
| u0017 | I think we were taught in fourth grade, to just do it like this. | candidate window: `were taught in fourth grade, to just do`; unresolved anaphoric: `it`; deictic: `this` |
| u0033 | I want you to see that the first group of 3/4 is done for you. | deictic: `that`; substitution candidates: `the first group of 3/4`; `done for you` |
| u0035 | This is one group of 3/4, okay? | deictic: `This`; unresolved anaphoric: `one`; substitution candidates: `This`; `one group of 3/4`; interrogative whole utterance |
| u0040 | It's not 1/4, okay? | unresolved anaphoric: `It`; negation: `not`; interrogative whole utterance |
| u0062 | What I can see is that 3/4 will fit into 14 at least 18 times, and then I have a little bit left over. | interrogative whole utterance; deictic: `that`; substitution candidates: `What I can see`; `that 3/4 will fit into 14 at least 18 times` |
| u0072 | I think it would be 18 and 1/2 because it was 3/4, and now there's only two of them, so it would be 2/4, and 2/4 is equal to 1/2. | unresolved anaphoric: `it` (three); deictic: `now`; substitution candidates: `2/4`; `1/2` |
| u0115 | 27 divided by one is 27, so that would give us 27 pizzas. | substitution candidates: `27 divided by one`; `27`; unresolved anaphoric: `one`; deictic: `that` |
| u0163 | I noticed that a lot of you over here, you said nine divided by 1/4 is equal to nine over one divided by 1/4, and then you multiplied the numerator and the denominator by four to get a common denominator which is equal to 36/4, divided by 1/4, which means 36 divided by one, which would be 36. | deictic: `that`, `here`; substitution candidates include `nine divided by 1/4`; `nine over one divided by 1/4`; `36/4`; `36 divided by one` |
| u0178 | When it's nine divided by 1/4, do you have to do all the work times four, or can you just do nine times the denominator? | interrogative whole utterance; unresolved anaphoric: `it`; normative-deontic: `you have to` |
| u0213 | No, we've been given the size of our groups. | negation: `No` |
| u0229 | What is my division sentence for this one | interrogative whole utterance; deictic: `this`; unresolved anaphoric: `one`; substitution candidates: `What`; `my division sentence for this one` |
| u0258 | I don't really get how you're supposed to set it up and stuff. | negation: `don't`; normative-deontic: `supposed to`; unresolved anaphoric: `it` |
| u0283 | If we count by fives, five, 10, 15, 20, 25, 30, 35, 40, 45. | observational: `count` |
| u0298 | What should we do? | interrogative whole utterance; normative-deontic: `should` |
| u0341 | You should have 13 groups, and then a half left over. | normative-deontic: `should` |
| u0353 | I think this is the same as that, because this as 2/3 | deictic: `this`, `that`, `this`; substitution candidates: `this`; `that` |
| u0451 | I have to see your best work, and for some reason, you're not doing that, and I'm not sure why. | normative-deontic: `have to`; negation: `not` (two); deictic: `that` |

### Distribution by emitted span type

| Type | Spans |
| --- | ---: |
| deictic | 200 |
| anaphoric_unresolved | 141 |
| anaphoric_candidate_window | 124 |
| alethic_modal | 0 |
| normative_deontic | 6 |
| observational | 10 |
| interrogative | 99 |
| negation | 17 |
| substitution_inference_candidate | 92 |
| **Total** | **689** |

IMPLEMENTATION_COMPLETE
