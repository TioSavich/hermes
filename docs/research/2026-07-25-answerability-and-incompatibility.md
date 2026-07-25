# The labelling was already done — reading the invariants and the pairings

Model: `claude-opus-5[1m]` (Opus 5, 1M context).
Date: 2026-07-25. Continues `2026-07-25-retention-split-addendum.md`.

Files changed: `scripts/research/build_action_grammar.py`,
`knowledge/strategies/action_grammar.pl`, `scripts/checks/action_grammar.py`,
this report.

## Two jobs I had handed to the owner, and where they turned out to be

The last two reports left him two piles of work, and both were badly aimed.

**"Label the 44 machines with what they conserve."** The labels exist.
`knowledge/strategies/math/*_action_pairs.pl` carries `invariant(Name)` in the
outcome of most actions — `each_object_counted_once`,
`cardinality_independent_of_spatial_extent`,
`ray_length_does_not_change_angle_measure`, 94 occurrences over 91 signatures.
`build_transition_tables.py` carried states, actions, and provenance into the
tables and left the invariants behind. The question "what is this machine
answerable for" had been answered in the tree before I asked it.

**"Review my 121 stance assignments."** There is an independent source that can
test them, and it is the same one. Sixteen `productive_*_deformation/3`
predicates, 97 pairings, each naming which deformation stands opposite which
productive strategy and what it deforms. That pairing did not come from me. Over
the 65 pairings whose two sides both have an extracted automaton:

**No productive strategy carries a deforming step. Every deformation carries
one. 65 of 65.**

That is the one thing an independent source can say about a stance assignment,
and it says it about 65 pairs without anyone reading the stance table. It is now
a check that fails on drift.

## What the layer holds

Three families, all read from the sources rather than authored:

**`machine_answerability/5`** — 87 rows. What each machine is answerable for, with
the source file. Not my judgment; an extraction.

**`incompatible_pair/6`** — 65 rows. The productive strategy, its deformation,
what the deformation deforms, and the step at which the two projected words part
company, recomputed from the words on every build.

**`unpaired_reference/4`** — 43 rows. Signatures the pairings name that the
transition tables do not carry: 10 in fraction, 9 in `smr_mult`, 8 in `sar_sub`,
7 each in `sar_add` and `smr_div`, 2 each in calculus and probability. The
pairing exists and the machine it names has no extracted automaton, so nothing
can compare the two readings. Stalled input, named rather than dropped.

This is Brandom's incompatibility rather than a similarity relation, and it is
why the pairing does work no single machine can do. What
`angle_turn_measurement` conserves is not read off its own edges — it is fixed by
what `angle_as_ray_length` loses. Queried:

```
?- machine_answerability(_, geometry, angle_turn_measurement, invariant(I), source(S)).
   I = ray_length_does_not_change_angle_measure,  S = 'geometry_action_pairs.pl'

?- incompatible_pair(geometry, angle_turn_measurement, D, deforms(W), divergence(N,P,Q), class(C)).
   D = angle_as_ray_length,  W = angle_confused_with_ray_length,
   N = 1,  P = establish_reference_frame,  Q = retain_what_must_survive,
   C = substantive_keep
```

The invariant, the strategy that violates it, the name of the violation, and the
step at which the two readings become distinguishable. All of it from data that
was sitting unconsumed.

## The 44 gaps split in half

`machine_conservation_gap/4` now says which kind of gap each one is, and the check
verifies the classification against the sources:

- **22 are extraction gaps.** The invariant is declared and the tables did not
  carry it. `geometry/angle_turn_measurement` already declares
  `ray_length_does_not_change_angle_measure`. Fixable by extending
  `build_transition_tables.py` to put the invariant on an edge — mechanical, and
  it belongs in a slice that touches the table builder.
- **22 are authoring gaps.** No `invariant/1` for that signature anywhere. That
  is the real remainder, and it is 22 machines, not 44.

## The Möbius question, measured

The band's appeal is that the productive and deformed readings are one surface
with a twist rather than two separate things. The pairing gives the first
measurable version of that: same prefix, one divergent step, and after it you are
on the other side. So: **where is the twist, and does it arrive early enough to
be useful?**

I got this wrong on the first pass and want the correction on the record. My
first read of the numbers was that divergence and the recorded break sit at
opposite ends of the machine. They do not. Median divergence step 1, median first
deforming step 1. Mostly they coincide.

Classifying the 65 divergences by what kind of parting they are:

| class | pairs | what it means |
|---|---:|---|
| `substantive_break` | 36 | the divergent step is itself where something breaks; no warning, the parting *is* the break |
| `same_register_neutral` | 14 | both divergent actions are working steps in one register; whether the strategies part here or this alphabet draws a line they do not is not settleable from the tables |
| `register_divergence` | 11 | both are working steps and different kinds of doing; the readings part before anything breaks |
| `substantive_keep` | 4 | one side keeps something the other does not, before either records a loss |

**17 of 65 pairs have a genuine early-warning window** — the readings part before
the first deforming step. Twelve by one step, four by two, one by three. That is
the honest size of it.

The five with a window of two or more are worth having by name, because each is a
teachable case:

| pair | window | where they part |
|---|---:|---|
| `scale_ratio_unit` / `additive_extension_of_ratio` | 3 | `scale_multiplicatively` vs `remove_quantity` at step 2 |
| `linear_pattern_contextual_rule` / `guess_and_check_rule` | 2 | reading the given's properties vs taking a guessed rule as given |
| `rectangle_perimeter_boundary_traversal` / `perimeter_two_sides_only` | 2 | holding the rectangle vs starting straight into the traversal |
| `angle_turn_measurement` / `angle_as_ray_length` | 2 | setting up the frame vs holding the turn fixed while the ray moves |
| `mean_absolute_deviation` / `mean_deviation_without_absolute_value` | 2 | holding the data set vs going straight to the mean |

The ratio pair is the best of them. A student who subtracts where the strategy
scales has left the multiplicative reading at step 2, and the corpus does not
record a loss until step 5. Three steps in which the reading is already decided
and nothing has said so yet. That is Vergnaud's additive/multiplicative divide
with a measured window, and it is the strongest support the corpus gives to
stopping early.

### Where the twist sits

The register of the two divergent actions, over the 65:

| productive register | deformation register | pairs |
|---|---|---:|
| constitution | constitution | 16 |
| constitution | normative | 10 |
| constitution | transformation | 4 |
| iteration | iteration | 3 |
| constitution | operation | 3 |
| operation | constitution | 3 |
| ten further combinations | | 1–2 each |

**36 of 65 divergences have the productive side in the constitution register** —
how the givens are taken up, what is held as the unit, which quantity gets which
role. The deformation is usually already decided by how the problem was
constituted, before any operation runs. If the band has a twist, that is where it
is, and it is the least visible part of a student's work: constituting happens
before anything is written down.

I am not going to claim more for the Möbius framing than that. What the data
supports: one shared prefix, one divergent step, a register census of where the
divergence sits. What it does not yet support: a traversal that returns inverted,
which is the part of the image that would need a reading of an actual utterance
rather than a pair of authored machines.

## What the LLM-servable surface needs, and why it is not here yet

The compact end of this is close but not built. What an LLM can be handed today:
121 canonical actions with glosses and citations, 20 normative arcs, 30 phrases,
87 invariants, 65 incompatible pairs. What is missing is the retrieval shape — one
card per action carrying its inferential neighbourhood: which invariants it
serves, which pairs it sits at the divergence of, which arcs it appears in, what
it is kin to across genres. That is a projection over what now exists rather than
new judgment, which is why it is the next slice and not this one.

The detail end is intact and should stay that way: 787 mapping rows each naming
the states its edge connects, 644 local labels never overwritten, every phrase
row rebuilding its machine's word exactly. Nothing in the compression discards a
label.

## Verification

- `run_all.sh` passes end to end, both new checks included.
- `scripts/checks/action_grammar.py` (exit 0) now also asserts: the cross-source
  stance audit over 65 pairings; every `machine_answerability` invariant declared
  verbatim in an action-pair source; every divergence step recomputed from the two
  words, including that the words do not already differ earlier; every gap reason
  classified correctly as extraction or authoring against the sources.
- The check found a bug in itself on the first run. My `machine_answerability`
  regex was not spanning the two-line facts, so it matched zero rows and the
  answerability assertion was vacuous — and the gap classification then failed 22
  machines for declaring no invariant when they declare one. The classification
  check caught the regex bug. Both are fixed and the vacuous assertion is now a
  real one over 87 rows.
- `scripts/checks/action_vocabulary_map.py` (exit 0), unchanged this slice.
- The analyzer's default path is untouched by this slice; nothing in the alphabet
  changed.

## Honest limits

- **The 14 `same_register_neutral` divergences are a review queue, not a
  finding.** Ten of them are `register_givens` against `read_operand_attribute`.
  Whether those strategies genuinely part at that step or my alphabet separates
  two openings that the pairing treats as one cannot be settled from the tables —
  it needs the local labels read case by case. The class name says so and the
  builder's comment says why.
- **The stance audit tests one boundary.** It confirms the deforming/not-deforming
  line 65 times and says nothing about the conserving/neutral line. Twenty-six of
  the 63 productive machines in pairs have no conserving step at all, so for those
  the conserving boundary is not merely untested but untestable from the tables —
  and all 26 are in the gap census, which is where they should be.
- **43 pairings cannot be used.** Their signatures have no extracted automaton, so
  the largest bodies of pairing data in the repository — the `sar_*` and `smr_*`
  addition, subtraction, multiplication and division families — contribute nothing
  to the divergence analysis. The 65 usable pairs are the ones that happen to have
  tables, not a sample of anything.
- **Reading an invariant is not checking one.** `machine_answerability` says what
  the source declares a machine answerable for. Nothing here verifies the machine
  actually preserves it; that would be an execution claim and this is a vocabulary
  layer.

## Result

- Two jobs handed back to the owner, both retracted: the labelling existed
  (**87 invariants extracted**), and the stance review has an independent test
  (**65 of 65 pairings agree**, now a check).
- **44 gaps split into 22 extraction and 22 authoring**, with the classification
  verified against the sources on every build.
- **65 incompatible pairs** with the divergence step recomputed each build, and
  **43 named as unusable** because their machines were never extracted.
- The Möbius question given its first measurement: **17 of 65 pairs part before
  they break**, 5 with a window of two steps or more, and **36 of 65 divergences
  sit in the constitution register** — the deformation is mostly decided in how
  the problem is taken up.
- One correction on the record: my first reading of the divergence numbers was
  wrong, and the median gap between parting and breaking is zero, not the width of
  the machine.
