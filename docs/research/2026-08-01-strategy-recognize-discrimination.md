# strategy_recognize: what its answers depended on, and what they depend on now

2026-08-01. Subject: `hermes/strategy_recognizer.pl`, reached by the worker op
`strategy_recognize` (`hermes/dispatch_spec.pl:698`) and by the MCP tool of the
same name.

## The reported finding, checked

Two sentences were put through the tool on current main:

- A: "I counted up from 235 by tens until I got to 341, and that was ten, then
  six more, so 106."
- B: "I got a new puppy yesterday and I got to name her."

Reproduced locally: both returned the **same candidates in the same order**,
topped by `fraction/measurement_division` at confidence 0.4 with
`support_level: partial_trace`, every matched span reading `i got`. The count
was 26, not the 25 reported; nothing else in the report differed.

Two corrections to the mechanism as it was stated.

1. The phrase is not authored per automaton. `canonical_phrase(name_result,
   [i,got])` (`knowledge/strategies/canonical_phrases.pl:244`) is authored once
   for one canonical action, and `canonical_action_of/2` sends it to every local
   action label that the vocabulary map routes to `name_result`. 26 of the 114
   execution-observed traces have such a step. `measurement_division` has two —
   `name_leftover_as_a_fraction_of_the_group_size` at step 4 and
   `name_quotient_and_remainder` at step 5 — and matching the same two words at
   two positions was enough for the old `support_level/6`, which asked only for
   two matches in any order. That is why one automaton reached `partial_trace`
   and the other 25 stopped at `lexical_hint`.

2. `Confidence is MatchedCount / ExpectedCount` was at the old line 238, and the
   ordering did fall to automaton length — but only where every candidate had
   the same matched count, which is the whole tail of this example. Coverage is
   not only brevity: two matched steps of three leaves less unsaid than two of
   eight. The defect was that coverage stood alone, with no floor under the
   quality of what matched.

The stronger claim in the brief — that the output does not depend on the
mathematics at all — holds for the first-person self-report register and does
not hold generally. Measured below.

## Pre-registration

Fixed after the minimal pair was reproduced and before the evaluation set was
scored.

- **No fix needed if**, on the held-out half: abstention on non-mathematical
  negatives ≥ 0.90 **and** top-1 on positives exceeds the best constant single
  answer by ≥ 0.10 absolute.
- **Otherwise the fix must reach**: abstention on non-mathematical negatives
  ≥ 0.90; `partial_trace` unreachable by non-mathematical English; top-1 on
  positives not more than 0.05 absolute below its current value, and any larger
  fall reported as a trade rather than dressed up.
- **Floor chosen** as the smallest value on a grid at which every negative
  stratum on the development half abstained completely.

The first condition failed: held-out negative abstention was 0.682. The floor
rule is the one place the pre-registration was departed from, recorded below.

## The evaluation set

1371 items, split dev/holdout by a hash of the item id.

| stratum | n | source |
|---|---|---|
| `P_literature` | 860 | `data/research/recognition_benchmark.json` literature arm — phrases cited to papers, gold = family + signature |
| `P_student` | 139 | same file, student arm — analyst prose describing student work |
| `P_canonical_canonical` | 114 | `generate_strategy_variant/4` canonical rendering of every observed trace |
| `P_canonical_synonym` | 114 | the same under the synonym map |
| `N_plain` | 60 | ordinary non-mathematical English, written without consulting the surface inventory |
| `N_self_report` | 60 | ordinary non-mathematical English in the first-person narrating register — the class the puppy sentence illustrates |
| `N_single_word` | 24 | ordinary sentences carrying one single-word recognition surface each; added after the first measurement, when that route was found |

The two canonical strata are the recognizer's own controlled language and are
circular by construction; they are kept because the gate requires them to stay
at `clean_run`, not as evidence of reading ability.

Two properties of the benchmark limit what its headline number means, and both
are stated rather than corrected. 447 of 860 literature items and 114 of 139
student items carry the same gold signature, `fraction/whole_number_grab`, so
the best constant single answer already scores 0.52 and 0.82 on those arms. And
87 of the 999 positive items are a **single word**, 56 of them the bare word
`denominator` and 15 more `round` or `rounded`. Per-signature macro accuracy and
a multi-word-only cut are reported beside the micro number for both reasons.

`~/Documents/GitHub/TalkMoves` was used only for derived counts, per its
CC BY-NC-SA terms; no transcript text was copied.

The set and every number below are re-derivable:
`python3 scripts/research/strategy_recognition_discrimination.py`. It holds the
three negative strata inline, generates the canonical renderings from the live
recognizer, scores in one SWI process, and prints each accuracy beside the best
constant answer for the same rows. Reading the "before" column again means
running it against the previous revision of `hermes/strategy_recognizer.pl`.

## Before: what the current recognizer was doing

Held-out half unless stated.

| | before |
|---|---|
| positives, top-1 signature (n=485) | 0.773 |
| positives, best constant single answer | 0.571 (always `whole_number_grab`) |
| positives, macro top-1 over 48 signatures | 0.692 (constant 0.021) |
| literature arm top-1 (n=414) | 0.896 |
| student-prose arm top-1 (n=71) | 0.056, constant 0.887 |
| canonical / synonym renderings | 1.000 / 1.000 |
| negatives, abstention (n=88) | 0.682 |
| negatives reaching `partial_trace` or better | 0.102 |
| mean candidates per negative | 3.25 |

So the recognizer was **not** invariant to mathematics across the board: on
cited literature wording it put the right signature first 90% of the time. What
it could not do was decline. Ordinary English written without reference to the
surface inventory abstained 0.98 of the time; ordinary English in the
first-person narrating register abstained 0.62, returned 7.0 candidates on
average, and reached `partial_trace` on 0.18 of items. On the student-prose arm
it was at the constant baseline: 0.056 against a macro constant of 0.125.

### A second route, found in the same pass

32 recognition surfaces are a **single ordinary word**. 17 are fragments of an
action identifier reached through `action_tokens/2` (`init`, `emit`, `second`,
`iterations`, `viability`); 15 are cited in `attested_phrases.pl` as bare words
(`round`, `split`, `stop`, `distance`, `endpoint`, `first`, `altogether`).
Reproductions on the unmodified recognizer:

- "First we went to the shop and then we came home." → 12 candidates, top
  `fraction/add_numerator_denominator_comparison`, **`partial_trace`**.
- "The second act was better than the first." → 12 candidates, `partial_trace`.
- "I have to stop and think about the distance to the endpoint." → 2 candidates,
  `partial_trace`.

Surface breadth cannot separate these: `second` fits one trace and `decompose`
fits two. This is a second instance of the governing pattern, and it is the
route the fix pays the most for.

### A third: a check that passed for a reason other than the one it stated

`scripts/checks/attested_phrases.py` asserted that
"jump through ten and decompose the other addend" returns candidates, under the
message "the cited surfaces are not reaching the recognizer". `jump through ten`
matches **no** observed trace; the whole of what reached the recognizer was the
bare word `decompose`. The probe has been replaced by two cited multi-word
phrases plus the opposite assertion about the bare word.

### A fourth: the recognizer does not separate a doing from talk about a doing

`knowledge/strategies/utterance_layers.pl` declares a `force` layer with values
`assertion`, `question`, `report` and `unmarked`, and forms for each
(`[did]`, `[do]`, `[how]`, `[why]`, `[what]`, `[said]`, `[told, me]`).
`hermes/strategy_recognizer.pl` imports `denied_span/3` and
`canonical_predicate/2` from that module and never consults force. On the
modified recognizer:

    "did you split the other number and make ten then add the leftover
     and use both parts"                       → 11 candidates, top
                                                  addition/make_ten_drop_leftover
    "who can tell me how to split the other number and make ten and add
     the leftover and use both parts"          → the same 11, the same top
    "next time you could split the other number and make ten then add
     the leftover and use both parts"          → the same 11, the same top

A teacher's question, a solicitation and a future suggestion are read as the
same evidence as a student's report of having done it. The layer that would
separate them is authored and unconsumed. Named, not fixed: consuming force
means deciding what a question about a strategy licenses, which is a change to
what the tool claims and not a defect in how it counts.

One thing inside it was a plain gap and is fixed here. `[did, not]`,
`[does, not]`, `[didnt]` and `[dont]` were all denial forms and `[do, not]` was
not, so `"do not split the other number or make ten"` was read as evidence for
splitting and making ten. `[do, not]` is added. The prohibition now drops from
11 candidates topped by `make_ten_drop_leftover` at 0.107 to 7 topped by a
multiplication trace at 0.036; the residue is the module's declared three-token
denial reach, which does not carry as far as the second conjunct. Every
measurement in the table below is unchanged by this addition.

## What changed

`hermes/strategy_recognizer.pl`: five predicates added, the confidence and the
support levels redefined, the two comparators re-keyed.

**Surface reach.** `surface_reach/2` counts how many of the 114
execution-observed traces have a step whose action language contains a surface.
The index is built once per process from the same `action_surface/2` the matcher
uses, so it cannot drift from what actually matches; it costs 14 ms and holds
1141 surfaces over 3090 surface–trace pairs. `i got` reaches 26, `i started` 12,
`the whole` 7, `made the bottoms match` 16, `added the leftover` 1.

**Surface weight.** A surface reaching *k* traces is worth 1/*k* to each of them.
A one-word surface is worth zero. The match itself is still recorded, so
`matched_count`, `missing_evidence` and the frontier are untouched, and only the
evidence the match contributes is zero. Distinct surfaces are weighed once each,
so a repeated generic phrase is one thing the speaker said rather than two. The
sum is the new `unshared_evidence` field.

**Admission floor.** `recognition_floor(0.1)`: a candidate is returned only when
its unshared evidence reaches a tenth of a step, so one surface fitting no more
than a tenth of the 114 traces, or several broader ones adding to as much.

**Confidence.** `confidence = min(1, unshared_evidence × trace_coverage)`, with
`trace_coverage` (matched steps over expected steps — the old confidence) also
emitted under its own name. In one sentence: *confidence is how much unshared
evidence the utterance supplies for this trace, multiplied by the share of the
trace that evidence reaches, so a lone generic phrase can no longer carry any
candidate and a short automaton no longer outranks a long one on the strength of
it.* Ranking uses the uncapped product.

**`support_level`.** `partial_trace` now states three things at once: two steps
reached **in the trace's own order**, by **two different surfaces**, carrying a
**full step's worth** of unshared evidence. The old rule asked for two matches in
any order, which one repeated phrase supplied alone.

Each matched span now carries `surface_reach` and `surface_weight`, so a
consumer can read why a span counted.

What the levels now separate, on three sentences:

    "the whole was split into equal parts and one of the equal parts is
     the unit fraction"
      fraction/unit_fraction_partition  partial_trace  conf 0.836
                                        evidence 1.393  coverage 0.600  3 surfaces
      nine others                       lexical_hint   conf 0.018 – 0.050

    "i made groups of 6 and kept subtracting 6 until there was nothing left"
      division/measure_groups_of_size   partial_trace  conf 0.500
                                        evidence 1.250  coverage 0.400  2 surfaces
      three others                      lexical_hint   conf 0.050 – 0.063

    "i split the other number and made ten"
      addition/make_ten_drop_leftover   lexical_hint   conf 0.1071
      addition/make_ten_split_leftover  lexical_hint   conf 0.1071
      six others                        lexical_hint   conf 0.029 – 0.036

The third is the tie stated rather than broken: that sentence is genuinely
ambiguous between dropping and splitting the leftover, the two candidates carry
identical evidence and identical coverage, and they now carry identical numbers
to say so.

`scripts/checks/attested_phrases.py`: the probe repaired, as above.

`knowledge/strategies/utterance_layers.pl`: `[do, not]` added to the denial
forms, as above.

`scripts/research/strategy_recognition_discrimination.py`: the measurement
driver, new.

### The floor, and where the pre-registration was departed from

Development-half sweep, with one-word surfaces already at zero:

| floor | `N_plain` | `N_self_report` | `N_single_word` | dev top-1 |
|---|---|---|---|---|
| 0.05 | 1.000 | 0.792 | 1.000 | 0.737 |
| 0.09 | 1.000 | 0.958 | 1.000 | 0.737 |
| **0.10** | **1.000** | **0.958** | **1.000** | **0.737** |
| 0.15 | 1.000 | 1.000 | 1.000 | 0.737 |
| 0.20 | 1.000 | 1.000 | 1.000 | 0.737 |

The pre-registered rule points at 0.15. 0.15 was set, and it emptied
`"i did not make ten i just counted them all"`, whose entire evidence is
`counted them all` fitting nine traces. That sentence is what
`scripts/checks/utterance_layers.py` uses to test that a denial's reach does not
swallow the clause after it; a floor that makes the test vacuous buys one
development sentence and loses a working check. The floor was set to 0.10 and
the departure is recorded here rather than hidden in the sweep.

What survives at 0.10, on the modified recognizer:

    "So it turns out the leak was coming from upstairs the whole time."
      → 7 candidates, all lexical_hint, confidence 0.018–0.036,
        every one carried by "the whole" (reach 7)

That is the shape of the residual limit: "the whole" is both a fraction phrase
and an ordinary quantifier, and a matcher without a parse cannot tell them
apart. It now says so at the weakest support level with numbers small enough to
act on, instead of manufacturing a `partial_trace`.

## After: the same measurements

Held-out half. `n` in the leftmost column.

| measurement | before | after |
|---|---|---|
| positives lit+student, top-1 (485) | 0.773 | 0.693 |
| **positives, multi-word items only, top-1 (431)** | **0.780** | **0.780** |
| positives multi-word, precision when answering | 0.911 | 0.928 |
| positives, macro top-1 over 48 signatures | 0.692 | 0.631 |
| best constant single answer (positives) | 0.571 | 0.571 |
| literature arm top-1 (414) | 0.896 | 0.804 |
| student-prose arm top-1 (71) | 0.056 | 0.042 |
| canonical rendering top-1 (61) | 1.000 | 1.000 |
| synonym rendering top-1 (58) | 1.000 | 1.000 |
| **negatives, abstention (88)** | **0.682** | **0.977** |
| **negatives reaching `partial_trace` or better** | **0.102** | **0.000** |
| mean candidates per negative | 3.25 | 0.16 |
| mean candidates per canonical rendering | 5.84 | 3.44 |
| balanced accuracy, multi-word positives vs negatives | 0.731 | 0.878 |

The best constant answerer on the combined set is "always abstain": 0.000 on
positives, 1.000 on negatives, balanced 0.500. The recognizer's lift over it was
0.231 and is now 0.378. Against the best constant single answer on the
multi-word positives alone (0.568, always `whole_number_grab`) the lift is 0.211
before and 0.211 after — unchanged, which is the same fact as the unchanged
multi-word top-1.

**Against the pre-registration.** Negative abstention ≥ 0.90: met, 0.977.
`partial_trace` unreachable by non-mathematical English: met, 0.000 on all three
negative strata in both halves. Top-1 within 0.05 of its previous value: **not
met on all positives**, which fell 0.080. It is met exactly on the multi-word
positives, where the fall is 0.000. Both numbers are above; the pre-registered
target was set on the whole positive set and the whole positive set is where it
was missed.

**Where the top-1 fall comes from.** Item by item, over all 999 positives:

    right → right     708        wrong → wrong      57
    abstain → abstain 125        wrong → abstain    29
    right → abstain    73        wrong → right       7

69 of the 73 `right → abstain` are single-word benchmark items. Restricted to
multi-word items the churn is: 334 right→right, 26 wrong→wrong, 5 wrong→abstain,
2 right→abstain, 2 wrong→right — a held-out top-1 of 0.7796 before and 0.7796
after, unchanged to four places.

So the honest statement is: **top-1 on multi-word utterances did not move; the
whole of the top-1 fall is the recognizer no longer naming a strategy from a
single word.** It was scoring 73 of those as correct. Nine benchmark items read
exactly `round`; eight are gold `round_without_adjusting` and one
`round_then_adjust`. `round` fits both traces equally, the old tie-break took
the alphabetically earlier, and so eight of the nine were already counted wrong
and one right. Being credited for the other 73 was the same coin landing the
other way.

**Where it did not help.** The student-prose arm is 0.042 after against a macro
constant of 0.125. Analyst prose describing student work is still outside what
this recognizer reads, and the fix moved that not at all; it abstains on 0.87 of
it now instead of 0.79.

**What was given up.** Where a whole family shares its language, the recognizer
now abstains rather than pick one. "made the bottoms match and compared the
numerators" returned candidates before and returns none now, because
`made the bottoms match` fits 16 fraction-comparison traces and 1/16 is under the
floor. The family-level reading that would be the right answer there is not an
output shape this tool has. Queued, not fixed.

### Real classroom speech

`scripts/research/talkmoves_recognizer_sweep.py` over 58,926 student sentences
from 564 TalkMoves transcripts, derived counts only.
`data/research/talkmoves_recognizer_sweep.json` is refreshed with the after
column; the before column is the version this commit replaces, and git history
holds it.

| | before (committed sweep) | after |
|---|---|---|
| sentence abstention rate | 0.9422 | 0.9846 |
| sentences with a candidate | 3407 | 908 |
| sentences whose best support is `partial_trace` | 1795 | 2 |
| candidate instances at `partial_trace` | 2395 | 2 |
| candidate instances at `lexical_hint` | 31347 | 4193 |
| distinct traces fired | 87 | 55 |
| distinct traces with two or more matched actions | 29 | 22 |

This is the measurement that carries the finding. Of 58,926 real classroom
student sentences, 1795 previously returned `partial_trace` as their best
support; 2 do now. The strong support level had been reachable by 3% of
arbitrary classroom speech and is now reachable by 0.003% of it. Firing at all
fell from 3407 sentences to 908, and 580 of the 4193 surviving candidate
instances still match two or more actions, so what remains is not only
single-span noise.

Nothing here says the 908 are correct. Correctness needs a reader and the sweep
has always said so. What it says is that the level a consumer was invited to
rely on no longer arrives 1795 times from talk that was never checked.

## Gates

- `scripts/checks/strategy_recognizer.pl` — PASS, 114/114 signatures: every
  canonical and synonym rendering still reaches `clean_run` with its full
  recovered order and accepting frontier, every injected-error rendering still
  produces a non-clean candidate with a boundary, and the five-utterance episode
  still assembles a `clean_run` with `ordered_action_count` 5.
- `scripts/checks/utterance_layers.py` — PASS, including the denial test and
  "purple bicycle tuesday" abstaining.
- `scripts/checks/canonical_phrases.py` — PASS.
- `scripts/checks/attested_phrases.py` — PASS with the repaired probe.
- `scripts/checks/strategy_task_span_refusal.py` — PASS.
- `scripts/checks/run_all.sh` — all 46 checks ran with no `FAIL`. The one thing
  that stopped it twice was `extract_research_measurement_registry`, which
  asserts the number of top-level research reports and indexes their lines.
  It found 72 where it expected 70, because two lanes added a report on
  2026-08-01: this one and the MathTutorBench held-out run. The assertion is now
  72 with both named. **If only one of the two lands in a commit, the number is
  71.**
- `python3 scripts/extract_capability_registry.py --check` — current, unchanged.
- `python3 scripts/bundle/app_manifest.py --verify` — OK, closure covered.

Two generated artifacts were regenerated rather than left stale:

- `knowledge/index/research_measurement_registry.pl`. It indexes this file by
  line number, so **it goes stale on any further edit to this report and must be
  regenerated last**, and its diff mixes this lane with an in-flight edit to
  `docs/research/2026-07-26-mathtutorbench-nine-columns.md` from the other lane.
- `knowledge/index/data_consumption_manifest.pl`, for the refreshed sweep file's
  hash and for the new reader the measurement driver gives
  `data/research/recognition_benchmark.json`.

Worker seam checked directly: `{"op":"strategy_recognize","content":"I got a new
puppy yesterday and I got to name her."}` returns `{"ok":true,"result":[]}`, a
clean abstention rather than an error, and a real strategy description returns
`division/measure_groups_of_size` at confidence 1.0 with four matched steps.

The **MCP tool served the pre-fix answer** after the edit, all 26 candidates at
`partial_trace` with the old provenance list, because the MCP server holds a
worker process started before the module changed. The tool needs the server
restarted, not another change; a fresh worker on the same tree abstains.

## What was refused

- **No hand-written blocklist.** The discriminator is reach, computed from the
  same surface generator the matcher uses. `i got` is nowhere in the code as a
  string; it falls out because it fits 26 traces.
- **No change to `hermes/mcp/server.py` or the worker's `query_misconception`
  dispatch**, both under another agent's hand. One thing there needs a hand: the
  MCP tool description for `strategy_recognize` (`hermes/mcp/server.py:78`) says
  "five execution-observed strategy traces". There are 114. The same docstring
  drift sits in `scripts/research/talkmoves_recognizer_sweep.py`, which says 106.
- **No new derived artifact for the reach index.** It is built in the process
  rather than written to a generated file, so it cannot fall out of step with
  the transition tables and needs no `--check` of its own.
- **No tie-break invented for candidates the recognizer cannot separate.** Where
  several traces share the whole matched surface set, their `unshared_evidence`
  is equal and the residual order is by trace coverage, which is trace length.
  That ordering is still there, as the seven fraction candidates above record
  (0.0357, 0.0286, 0.0286, 0.0286, 0.0238, 0.0238, 0.0179). The equal
  `unshared_evidence` is what tells a consumer they were not separated. Reporting
  a family-level candidate would be the real answer and is a change of output
  shape, not a fix.
- **No repair of the benchmark's skew.** 447 of 860 literature items carry one
  gold signature. That is a fact about `recognition_benchmark.json` and belongs
  to whoever built it; the macro and multi-word cuts are reported so the headline
  number cannot be read without it.

## Open

1. The single-word surfaces still exist and still match; they are weighed at
   zero, which is a treatment of the symptom. 17 of the 32 are action-identifier
   fragments (`init`, `emit`) that are automaton scaffolding rather than anything
   a student says, and 15 are single words cited from papers. Both sets deserve a
   decision at their source.
2. The `force` layer, authored in `utterance_layers.pl` and unconsumed by the
   recognizer. A question about a strategy, a solicitation and a suggestion all
   read as a report of the doing.
3. Family-level candidates for utterances whose evidence fits a whole family and
   no member of it.
4. The student-prose arm at 0.04. Nothing here moved it.
4. `whole_number_grab` carrying half the recognition benchmark.
