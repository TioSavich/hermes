# Student-register recognition from held-out TalkMoves

## Boundary

The source for this change is the TalkMoves corpus at
`~/Documents/GitHub/TalkMoves/data`, released under CC BY-NC-SA 4.0
(Jacobs et al. 2022; Suresh et al. 2021). The analysis used 58,926 student
sentences across 564 transcripts. It stores counts and short pattern names, not
transcript sentences.

The 139-item student benchmark remained a sealed test set. It was scored only
through `scripts/research/score_recognition_benchmark.py`, which prints aggregate
metrics. The benchmark file was not regenerated.

## Divergence in the held-out corpus

The baseline recognizer abstained on 55,773 of the 58,926 student sentences.
The sweep now counts a bounded set of mathematical constructions only inside
those abstentions. The groups can overlap when one sentence contains more than
one construction.

| uncovered construction | intended canonical action | abstained sentences | disposition |
|---|---|---:|---|
| division operator | `compute_quotient` | 279 | not added; the action occurs in no execution-observed recognizer trace |
| magnitude relation | `compare_magnitudes` | 123 | not added; a relation alone would widen thirteen live machine-action positions |
| multiplication operator | `compute_product` | 69 | added as inflected two-token forms |
| take-away process | `remove_quantity` | 60 | added as inflected two-token forms |
| deictic addition | `combine_quantities` | 47 | added with the bounded object `it` |
| measurement-division wording | `measure_out_group_size` | 45 | not added; the two-token forms also occur outside mathematical action descriptions |
| count-by process | `iterate_composite_unit` | 44 | added as inflected two-token forms |
| number-line reference | `establish_reference_frame` | 44 | not added; it names an object without saying what was done with it |
| deictic division | `compute_quotient` | 41 | not added; the target action has no execution-observed recognizer trace |
| totalizing phrase | `accumulate_total` | 38 | added as two bounded forms |
| operand decomposition | `decompose_operand` | 7 | not added in this pass |
| equal pieces | `partition_into_equal_parts` | 1 | not added in this pass |

The largest gap is therefore not a missing synonym. Division language has a
canonical action in the vocabulary map, but that action does not occur in the
106 execution-observed traces from which recognizer candidates are built. A
phrase attached there cannot affect recognition.

## Surfaces added

Fourteen short surfaces were added to five live canonical actions:

| canonical action | corpus-derived pattern forms |
|---|---|
| `iterate_composite_unit` | `count by`, `counted by`, `counting by` |
| `accumulate_total` | `in all`, `all together` |
| `combine_quantities` | `add it`, `added it`, `adding it` |
| `remove_quantity` | `take away`, `took away`, `taking away` |
| `compute_product` | `multiply by`, `multiplied by`, `multiplying by` |

Each surface is an exact multi-token span. None is a transcript sentence, and
no bare operator or number word was added. The comments beside the facts in
`canonical_phrases.pl` record the motivating full-corpus frequency bands.

## Fixed TalkMoves subsample

The before-and-after precision proxy uses the first 64 transcripts selected by
the sweep, held fixed at 5,282 student sentences. This sample was chosen before
the surface edit.

| measure | before | after |
|---|---:|---:|
| sentences with a candidate | 181 | 212 |
| abstention | 96.57% | 95.99% |
| `lexical_hint` candidates | 1,585 | 1,769 |
| `partial_trace` candidates | 100 | 177 |
| `partial_trace` / `lexical_hint` | 0.0631 | 0.1001 |

Hints increased by 11.6%, while partial traces increased by 77.0%. The ratio
therefore moved in the required direction. This does not establish correctness;
it says the added surfaces assembled multi-action evidence faster than they
created isolated hints on this fixed corpus slice.

The same direction holds over the full corpus:

| measure | before | after |
|---|---:|---:|
| sentences with a candidate | 3,153 | 3,407 |
| abstention | 94.65% | 94.22% |
| `lexical_hint` candidates | 29,464 | 31,347 |
| `partial_trace` candidates | 1,762 | 2,395 |
| `partial_trace` / `lexical_hint` | 0.0598 | 0.0764 |
| machines assembling at least two actions | 24 | 29 |

Across the full corpus, hints increase by 6.4% and partial traces by 35.9%.

## Fixed benchmark

### Machine-level arms

| arm | n | recall@1 before | recall@1 after | recall@3 before | recall@3 after | family@1 before | family@1 after | abstention before | abstention after |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| literature | 860 | 89.9% | 89.9% | 97.4% | 97.4% | 96.7% | 96.7% | 2.2% | 2.2% |
| student | 139 | 6.5% | 6.5% | 6.5% | 6.5% | 10.8% | 11.5% | 77.0% | 76.3% |

Recall@5 is unchanged at 97.7% for literature and 7.9% for students.
Candidates per firing item are unchanged at 1.45 for literature and rise from
3.91 to 4.12 for students.

### Authored contaminated control

| measure | before | after |
|---|---:|---:|
| items | 185 | 185 |
| top-candidate action recovery | 81.6% | 81.6% |
| abstention | 11.9% | 11.9% |
| candidates per firing item | 8.29 | 8.29 |

The unrelated-text check returns zero recognitions before and after. The
canonical phrase check also passes the generated-language round trip, and the
strategy recognizer check passes all 106 execution-observed signatures.

## Reading

This is a near-null benchmark result. Student recall@1 does not move. Family@1
moves by one item, and one fewer item abstains, but the recognizer does not
identify more gold student strategies at rank one.

The corpus result shows that inflected process language was one surface-level
constraint: the fixed-sample trace-to-hint ratio improves. It was not the
binding constraint on top-ranked benchmark recognition. The deeper obstacle is
the candidate construction. It can only propose machines with
execution-observed traces, and a canonical surface is inherited by every local
action mapped to that canonical action. The first rule leaves common student
division language with no live target. The second turns one ordinary phrase
into evidence for several machines without enough surrounding action order to
rank the intended one first.

## Episode-level recognition

The corpus unit does not match the automaton unit. The median student sentence
has four words, an observed trace usually expects six or seven ordered actions,
and 78% of consecutive-student runs contain one sentence. A sentence-level call
therefore cannot usually supply a trace even when its vocabulary is covered.

`recognize_strategy_episode/2` accepts a transcript's student utterances in
order. It carries the candidate frontier across utterance boundaries and records
the zero-based utterance index that supplies each ordered step. The existing
`recognize_strategies/2` predicate is unchanged.

The full-corpus episode sweep compares 564 transcript episodes with the stored
58,926-sentence baseline:

| measure | sentence calls | transcript episodes |
|---|---:|---:|
| `lexical_hint` candidate instances | 31,347 | 11,475 |
| `partial_trace` candidate instances | 2,395 | 1,761 |
| `partial_trace` / `lexical_hint` | 0.076403 | 0.153464 |
| distinct machines reaching 3+ ordered actions | not measured | 1 |
| transcript-machine instances reaching 3+ ordered actions | not measured | 4 |
| distinct machines reaching an accepting state | not measured | 0 |

The candidate counts use different call units, so their raw totals are not a
rate comparison. The ratio doubles when sentence boundaries stop resetting the
frontier, and one machine assembles three ordered actions in four transcripts.
No machine reaches acceptance.

Sentence boundaries were a constraint on trace assembly. Removing that
constraint is not sufficient for complete recognition on this corpus. Observed
trace coverage, surface specificity, and ranking remain open constraints.
Adding broader one-token surfaces would raise firing rates, but these results
do not support an expectation that they would raise student recall@1.
