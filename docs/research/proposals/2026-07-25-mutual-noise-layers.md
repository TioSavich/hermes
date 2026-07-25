# PROPOSAL — generating noise so the layers can filter each other

**This is a proposal. Nothing described in the future tense below exists.** What
exists today is stated in the present tense and is checkable now; everything else
is marked as proposed. Written 2026-07-25, model `claude-opus-5[1m]`, from the
owner's framing across two messages.

## The owner's framing, in his terms

Three things, which turn out to be one thing:

1. The repo is meant to be a fractal of determinate negation and the determinate
   negation of determinate negation — no, and ~~no~~. So the morphing predicates
   should apply at every layer, self-similarly, rather than at the mathematical
   layer only.
2. "Number lines" indicate the measuring-stick metaphor, and no part of this
   system's work is likely free of spatialized metaphor. Alongside a person layer
   there is a metaphor layer, and those metaphors switch mid-speech-act during
   transformative learning.
3. Subject positions move within one speech act — "I start with 'I' and go to
   'you' all the time in a CUSP." That movement is **signal for the PML layer and
   noise for the mathematical automata layer**.

And the reason for the adversarial construction: *generate the noise so we can
learn to filter it, where each layer counts the other as noise.*

That last clause is the design. Not "filter noise out" but "each layer's noise is
another layer's signal," so a filter for one layer is a detector for another. Noise
is not a residue to be discarded; it is misfiled signal.

## What already exists, verified today

| | where | what |
|---|---|---|
| deformation operators, named | `action_vocabulary_map.pl` | 26 canonical actions with `stance(deforming)` — `treat_relevant_as_irrelevant`, `conflate_roles`, `halt_before_completion`, `misname_result`, `omit_required_step`, and the seven `substitute_*` |
| viable/deformation pairs | `action_grammar.pl` | 97 `incompatible_pair/6` rows with the divergence step and its class |
| the person, force and polarity layers | `utterance_layers.pl` | 4 layers, 9 uptakes into the discursive genre, 4 substitutions |
| grounding metaphors | `formal/formalization/grounding_metaphors.pl` | **29** `grounding_metaphor_definition/4`, including `arithmetic_is_measuring_stick`, `arithmetic_is_motion_along_a_path`, `arithmetic_is_object_collection`, `arithmetic_is_object_construction`, and `numbers_are_points_on_a_line` |
| metaphor break points and repairs | same module | `metaphor_breaks_at/3`, `metaphor_repair/4`, `metaphor_repair_witness/5` |
| a discursive genre to land uptakes in | `commitment_automata.pl` | 18 machines, `acknowledge_commitment` / `attribute_commitment` among them |
| cited surfaces | `attested_phrases.pl` | 860 rows, 281 papers, and 139 quoted student utterances |

So the owner's guess was right on the point that mattered: **the measuring stick is
already in the repo programmatically and has never been written as an automaton.**
It sits in a Lakoff–Núñez formalization with its own break points and repairs, and
nothing in the recognizer or the vocabulary layers consults it.

## The gap this proposal is aimed at, measured

Three concrete holes, each checkable today.

**The person layer cannot see a movement.** `read_layer/3` uses `setof/3`, so
"i made ten first so you can see it works" returns `[first_singular, second]`
sorted. The I-then-you movement is not in the answer. The substitution rule *is*
recorded — `layer_substitution(person, first_singular, second, induces(uptake,
acknowledge_commitment, attribute_commitment), _)` — and nothing says this
utterance performed it. A CUSP shift is therefore invisible at exactly the layer
built to see person.

**There is no metaphor layer.** Twenty-nine metaphors, zero connection to any
utterance. "I moved five along the number line" and "I put five more in the pile"
are the same arithmetic under `arithmetic_is_motion_along_a_path` and
`arithmetic_is_object_collection`, and nothing here distinguishes them.

**Noise has no generator.** Every recognition test in this arc used a sentence I
wrote. There is no way to produce a string whose deformation is known, so there is
no way to measure a filter.

## The proposal

### 1. Morphing predicates as one operator set applied at every layer

The self-similar claim, made concrete: the deforming canonical actions are already
a small set of *operators*, and each has a reading on a sentence as well as on a
strategy.

| deforming canonical action | on a quantity | on a sentence |
|---|---|---|
| `treat_relevant_as_irrelevant` | drop a relation the answer depends on | drop the possessive: "my cat is named George" → "cat is named George" |
| `conflate_roles` | collapse group count with share size | swap two roled constituents: → "my George is named cat" |
| `halt_before_completion` | stop a required traversal | truncate: → "my cat is" |
| `misname_result` | name a value answering another question | wrong final term: → "my cat is named Tuesday" |
| `omit_required_step` | skip a step the strategy needs | drop a required constituent |
| `retain_where_change_was_due` | keep what the step obliged to change | leave agreement unchanged: → "my cats is named George" |
| `substitute_count_for_measure` | count parts for the magnitude | count for relation: → "my cat is named three" |

The owner's own examples are the first two rows, and his "3-2 → 2-3" is exactly
`conflate_roles` — an order swap over roled positions. Proposed:
`morphing_operator(CanonicalAction, layer(L), rewrite(Spec), gloss(Text))`, with
one operator set and a rewrite per layer it applies at. The fractal claim then has
a testable form: *the same operator name applies at the quantity layer, the sentence
layer, and the discourse layer, and the rewrite differs while the name does not.*
Where an operator has no reading at a layer, that absence is recorded, because a
fractal with a missing scale is a finding about the structure.

### 2. A metaphor layer, `Q_measuring_stick` and its siblings

Proposed: `metaphor_layer_form(MetaphorId, Words)` over the existing 29, drawing
its forms from the metaphors' own source domains — "along the line", "further up",
"how far" for `arithmetic_is_measuring_stick` and
`arithmetic_is_motion_along_a_path`; "put together", "how many altogether", "piles"
for `arithmetic_is_object_collection`; "build", "make" for
`arithmetic_is_object_construction`.

Then two things the existing module already supports and nothing consumes:

- **`metaphor_breaks_at/3` becomes a predictor.** A metaphor's break point is
  where its source domain stops licensing the target inference. If an utterance is
  running under a metaphor and reaches its break, that is a locatable moment rather
  than a general risk.
- **Metaphor switching becomes detectable.** Proposed
  `metaphor_shift(From, To, at(TokenIndex), repair(Mechanism))`, consulting
  `metaphor_repair/4` for whether the switch is one the formalization already
  records as a repair. The owner's hypothesis — that these switch mid-speech-act
  during transformative learning — becomes a thing to look for rather than a thing
  to believe. Marked as his hypothesis, hedged as he hedged it.

### 3. Layer trajectories, so a movement is in the answer

Proposed: replace the set-valued read with an ordered one.
`layer_trajectory(Layer, [value(V1, at(I1)), value(V2, at(I2)), ...])`, and
`layer_shift(Layer, From, To, at(Index), induces(...))` for each consecutive pair,
resolved against the `layer_substitution/5` rules that already exist.

Then "i made ten first so you can see it works" yields
`layer_shift(person, first_singular, second, at(5), induces(uptake,
acknowledge_commitment, attribute_commitment))` — the CUSP movement, named, with
the deontic consequence the rule already states.

### 4. The adversarial structure: mutual noise

This is the part that makes it worth building rather than merely tidy.

Proposed `noise_channel(Layer, signal_for(L1), noise_for(L2))`: what each layer
counts as signal and what it counts as another layer's noise. Concretely —

- A **person shift** is signal for the discursive genre (it performs
  acknowledge→attribute) and noise for the mathematical automata, which should
  recognize the same strategy across it. **Test: a person shift must not change the
  top mathematical candidate.** This test can run today, and running it produced
  the most useful thing in this document — see the next section.
- A **metaphor shift** is signal for the metaphor layer and noise for the
  mathematical automata — "I moved five along" and "I put five more in" are one
  strategy. **Test: a metaphor shift must not change the top candidate either.**
- A **mathematical deformation** is signal for the mathematical layer and noise for
  the person layer — deforming the arithmetic must not change who is speaking.
- **Polarity** is the interesting exception and worth stating: a denial is signal
  for *both*. It withdraws a commitment (discursive) and it removes a strategy
  candidate (mathematical). A layer scheme where every layer is noise to every
  other would predict otherwise, so polarity is where the mutual-noise picture is
  least clean, and that is worth knowing before building on it.

The generator then produces, from one canonical sentence, a family of variants each
carrying **which layer was perturbed and by which operator**. Ground truth for free,
because it was constructed rather than annotated. And the measurement is a
confusion matrix: for each layer, how often a perturbation at *another* layer moved
its answer. Every off-diagonal entry is a leak, and the leaks are the filter's work
list.

### 4a. Why the generator is needed, learned by getting the test wrong

The first version of this proposal claimed the person-shift test already passed.
It was run to check that claim and it **failed**: the top candidate moved from
`make_ten_split_leftover` at 0.8 to `make_ten_drop_leftover` at 0.4, which reads
as person noise leaking straight into the mathematical layer.

It was not. The two sentences I had written differed by more than the pronoun:

    i split the other number and made ten then i added the leftover and used both parts
    i split the other number and made ten so you can see how you add the leftover and use both parts

The second changes `added` to `add`, `used` to `use`, and inserts "so you can see
how". Three perturbations at two layers, reported as one. Re-run with the pronouns
and nothing else changed:

| | top candidate | confidence | candidates |
|---|---|---:|---:|
| first person | `make_ten_split_leftover` | 0.8 | 7 |
| second person | `make_ten_split_leftover` | 0.8 | 7 |
| third person | `make_ten_split_leftover` | 0.8 | 7 |
| **mixed, i then you** | `make_ten_split_leftover` | 0.8 | 7 |

Identical, including the CUSP shift. The mutual-noise property holds for person,
and the leak was my test.

This is the argument for the generator, arrived at by making the mistake it
prevents. **A hand-written pair is not a controlled perturbation.** I wrote two
sentences meaning to vary person, varied three things, and drew a false conclusion
that survived until it was run. A generator that applies one named operator to one
layer cannot make that mistake, and every measurement taken with hand-written pairs
in this arc — including the precision numbers in the two reports before this one —
is subject to it.

### 5. The hypothesis worth being wrong about

Proposed as the first experiment, because it is cheap and informative either way:

> Take a canonical sentence for a productive strategy. Apply the sentence-layer
> reading of the deformation operator that its `incompatible_pair` divergence
> names. Does the recognizer return that strategy's **deformation partner**?

If yes, the linguistic and mathematical deformation layers are the same operators
on different material, and the fractal claim has an instance rather than an
analogy. If no, the layers morph independently and the fractal claim is about the
repo's organization rather than about its content — which is still worth knowing
and is a smaller claim than the one currently being made.

I would expect mostly *no*, for a reason worth writing down: a divergence class is
`substantive_break` in 55 of 97 pairs, meaning the two strategies part exactly
where one of them breaks, and the sentence-layer operator has no way to know which
constituent carries that step. The interesting cases would be the 19
`register_divergence` pairs, where the readings part before anything breaks.

## Order of work, and what each step costs

1. **Layer trajectories** — smallest, self-contained, and unblocks the CUSP
   detection the owner named. No new authored vocabulary.
2. **Morphing operators at the sentence layer** — one rewrite per deforming action;
   authoring, and the rewrites are checkable by construction.
3. **The noise generator and the confusion matrix** — mechanical once 1 and 2 exist.
   This is the deliverable that turns the recognizer's precision question from a
   threshold I would have to choose into a number the data reports.
4. **The metaphor layer** — largest, because it needs forms authored for 29
   metaphors and because the switching hypothesis needs transcripts to test. The
   part that does not need transcripts is wiring `metaphor_breaks_at/3` to
   something, which is worth doing on its own.

Two items enter this order from section 6, and one of them moves ahead of the
rest:

0. **Generation-mode rules for `math_claim_language.pl`** — cheapest of anything
   here, because the grammar exists and only its numeral and operand nonterminals
   need a bound-first form. It is a precondition for step 3 rather than a
   parallel task, and it comes with its own check: every generated surface must
   re-parse to the term it came from.
5. **The TalkMoves agreement pass** — independent of 1 through 4 and answers a
   question already in the queue (do the 18 discourse machines meet a real
   transcript). Blocked on the licence decision, not on any code.

## 6. The generative machinery is already installed — Chomsky grammars, checked

The owner asked whether old-school automaton-based chat generators or Prolog
natural-language libraries in the Chomsky-grammar line could serve the noise
generator. The answer is that the line he is pointing at is *native to the
implementation language* and already runs in this repository, and the honest form
of the answer has a limit in it.

**Definite Clause Grammars are Chomsky grammars.** Pereira and Warren's 1980
result is that a DCG is a context-free grammar written as Horn clauses, and SWI
compiles `-->` into ordinary predicates with two threaded difference-list
arguments. Nothing needs importing; the notation is in the language.

**Three DCGs already exist here**, and two of them matter:

| file | what its grammar does |
|---|---|
| `formal/learner/reorganization_log.pl:61` | **generates** prose from ORR events: `phrase(narrative(Log), Tokens)` |
| `hermes/math_claim_language.pl:485` | **parses** math claims, with polarity, negation, and inverted questions |
| `knowledge/strategies/math/unit_coordination_viz.pl` | scene construction |

So the shape the noise generator needs is instanced twice over: a grammar that
turns automaton events into sentences, and a grammar over the register the
sentences have to land in.

### What I checked, including the part that failed

`math_claim_language.pl` declares itself a reader. Run backwards it generates,
and the surfaces are real English word order:

```
?- phrase(math_claim(T), Toks).
T    = arithmetic_equation(0+0/1+(0+0/1), 0+0/1)
Toks = [is,zero,and,zero,/,one,plus,zero,and,zero,/,one,equal,to,zero,and,zero,/,one]
```

**And with the term bound it does not terminate.** `phrase(math_claim(arithmetic_equation(8+5,13)), Toks)`
ran past 120 seconds and was killed. Unbound, the numeral rules enumerate
0, then 0/1, 0/2, 0/3 … and grind the leftmost position forever; bound, some
branch enumerates before it consults the structure it was given. Which is the
ordinary DCG mode problem: a grammar written for one direction is not
automatically usable in the other, whatever the theory says about reversibility.

That is the actual cost of this step, and it is smaller than writing a grammar:
**the generator needs generation-mode rules for the numeral and operand
nonterminals** — bind before enumerating, or a separate `realize//1` that shares
the vocabulary and not the recursion. Know-how before know-that, in the owner's
phrase: the repository can already say these sentences, and cannot yet say them
*on demand*.

### The register target exists too, and it is annotated

`~/Documents/GitHub/TalkMoves` is Sumner lab's released dataset: **567 K-12
mathematics lesson transcripts** (504 train, 63 test), segmented to the sentence,
each row `Turn / Speaker (T|S) / Sentence / Tag / StudentTag / Transcript`, with
teacher and student discourse moves already coded and the grade recoverable from
the transcript name (`7th grade math.xlsx`).

That is three things at once:

1. **The register the generator is aiming at**, in quantity, from real classrooms
   rather than from anyone's ear — which is the limit both phrase reports named.
2. **A test the 18 discourse machines have never had.** The handoff's queue item 4
   asks whether they meet a real transcript; this is a real transcript corpus with
   the moves already labeled, so agreement is measurable rather than judged.
3. **A rights question,** which has to be settled before any of it is used.
   TalkMoves is CC BY-NC-SA 4.0: attribution, non-commercial, share-alike. Under
   the literature ruling — full texts never in the public repo — the same
   treatment applies here by default: derived counts and agreement tables in the
   tree, transcripts stay out. Share-alike also reaches derivatives, which is a
   question about what a generated corpus inherits, and it is the owner's to
   answer and not mine.

## 7. MAYBE — deterministic weights, and generating slop on purpose

Filed at the owner's request and marked as a maybe, because it is a different
project from the one above and the honest thing is to say so.

**The idea, in his words:** generate the layers and weights of an LLM with the
noise generators. Deterministically generate AI slop.

**Why it is not idle.** Synthetic pretraining data is ordinary practice now, and
what is *not* ordinary is synthetic data with a derivation. Every sentence this
architecture emits would carry the automaton, the deformation operator, and the
citation that produced it. A model trained on it would have the property that
almost no model has: for any output, the generating structure is recoverable,
because the corpus was generated by structures rather than sampled from a
distribution. That is a strong claim about *provenance*, and provenance is the
thing the field cannot currently supply.

**Two readings of the idea, and they are different sizes.** The weaker one —
deterministically generate the training *corpus*, train ordinarily — is
approachable and is what the noise generator produces anyway at sufficient scale.
The stronger one — compute the weights themselves from the grammar without
gradient descent — is a research question in a field I should not pretend to
survey from here. Published deterministic constructions (weight-tying a
transformer to simulate an automaton, mechanistic-interpretability results that
run backwards) exist for toy languages, and the distance from a toy language to
this grammar is the whole problem.

**What would make it testable at this repository's scale**, if it is ever picked
up: the smallest version is not a language model. It is asking whether a fixed
matrix can be constructed, rather than trained, that maps a generated sentence to
its automaton — the recognizer's job, done in linear algebra, with the grammar
supplying the construction. If that works for six machines it is worth more
thought. If it does not, the corpus reading stands on its own and loses nothing.

**Why it stays a maybe.** It shares no code with steps 1 through 5, it needs
scale those steps do not need, and it would be the first thing here whose payoff
is outside mathematics education. It is recorded so it is not lost, and it should
not displace anything above it.

## What this proposal does not claim

- **Not that the repo is a fractal.** That is the owner's design intent. This
  proposal gives one testable consequence of it and says what a negative result
  would mean.
- **Not that generated noise resembles real noise.** It resembles *deformations of
  canonical sentences*, which is a narrow and known-provenance slice of what a
  classroom produces. A filter tuned on it would be tuned on my constructions.
  That limit does not go away by measuring, and the measurement is still better
  than the current position, which is examples I wrote and then judged.
- **Not that the metaphor switching hypothesis is established.** The owner hedged
  it and so does this. What exists is 29 metaphors with break points and repairs
  and no consumer.
- **Not that any of this needs doing before the corpus mapper's proposals are
  reviewed.** `data/research/corpus_binding_proposals.json` holds 268 rows waiting
  on human judgment, and no amount of layer work substitutes for that.
