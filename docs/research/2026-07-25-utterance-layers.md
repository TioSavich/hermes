# Layers — and a denial that was counting as evidence

Model: `claude-opus-5[1m]` (Opus 5, 1M context).
Date: 2026-07-25. Continues `2026-07-25-can-they-parse.md`.

Files changed: `knowledge/strategies/utterance_layers.pl` (new),
`scripts/checks/utterance_layers.py` (new), `hermes/strategy_recognizer.pl`,
`scripts/checks/run_all.sh`, this report.

## The owner's idea, and what it found

The suggestion was that a phrase should call other parsers rather than be a flat
string of words — something like `q_anaphora_pronoun / q_claim_create /
q_make_base` — so that "I made a ten" and "You made a ten" are both recognizable
once grammatical and Brandomian parsers are on board. Layers. Colors. And then
substitution defines I → you. Framed as: an internally complex whole that the
data negates aspects of, information being the negation of possibilities.

The first thing to do with that was check whether the recognizer already had the
problem. It did, and worse than expected. Probed live through the MCP server, all
five of these returned `addition/make_ten_split_leftover` or its deformation
partner at comparable confidence:

| utterance | top candidate | confidence |
|---|---|---:|
| i split the other number and made ten … | `make_ten_split_leftover` | 0.8 |
| **you** split the other number and made ten … | `make_ten_split_leftover` | 0.8 |
| **she** split the other number and made ten … | `make_ten_split_leftover` | 0.8 |
| **did you** split the other number and make ten … | `make_ten_drop_leftover` | 0.4 |
| **i did not make ten** i just counted them all | `make_ten_drop_leftover` | 0.2 |

The first three differ in who is put in the commitment's place. The fourth is a
question rather than a claim. The fifth is a **denial**, and it scored in favour
of the strategy it denies: the recognizer matched "made ten" inside "did not make
ten" and counted it as evidence.

So the pronouns were not mis-parsed, they were discarded — and the negation was
worse than discarded, it was inverted. That is the owner's framing arriving as a
bug. Information that should have removed a possibility added one.

## What was built

`knowledge/strategies/utterance_layers.pl`, four layers read independently off
the same tokens:

| order | layer | values |
|---:|---|---|
| 1 | person | unmarked, first_singular, first_plural, second, third_singular, third_named |
| 2 | force | unmarked, assertion, question, report |
| 3 | polarity | affirmed, denied |
| 4 | action | a canonical action from the alphabet |

Every layer has an unmarked value, so a layer the utterance does not carry reads
as unread rather than as a guess.

**`layer_uptake/3`** says what a layer value commits the speaker to, in the
discursive genre's own vocabulary — so a layer parse lands in
`commitment_automata.pl` rather than in a set of tags. First person is
`acknowledge_commitment`; second and third are `attribute_commitment`; a question
is `challenge_entitlement`; a denial is `withdraw_commitment`. The check fails if
an uptake names an action no machine in that file fires.

**`layer_substitution/5`** records that a swap in one layer induces a swap in the
uptake while the mathematics stays put. That is what makes it a substitution
rather than a different utterance:

| layer | from → to | induces |
|---|---|---|
| person | first_singular → second | acknowledge_commitment → attribute_commitment |
| person | second → third_singular | attribute → attribute (unchanged) |
| force | assertion → question | undertake_commitment → challenge_entitlement |
| polarity | affirmed → denied | undertake_commitment → withdraw_commitment |

The first is the one the owner named, and it lands exactly where the discursive
genre already had a deformation waiting for it:
`attribution_taken_as_acknowledgement` is a machine in that file precisely because
those two are not interchangeable.

**`canonical_predicate/2`** holds the mathematical predicate with no person and
no auxiliary — "made ten", "got to ten", "split the other number". The 185
phrases in `canonical_phrases.pl` all begin "i", so they read a student
describing their own work and not a teacher revoicing it. A predicate carries no
person, so the same surface serves all three.

**`denied_span/3`** is the veto. `action_spans/3` in the recognizer now drops a
span inside a denial's reach instead of counting it.

## The negation, live

Re-probed through MCP after the veto:

| utterance | candidates |
|---|---|
| i split the other number and made ten then i added the leftover and used both parts | `make_ten_split_leftover` 0.8, `make_ten_drop_leftover` 0.4, `base_ones_chunking` 0.25 |
| **i did not make ten** i just counted them all | `area_model_part_of_part` 0.25, **`count_all_instead_of_known_fact` 0.25**, `count_all_when_count_on_available` 0.25 |
| **you** split the other number and made ten … | identical to the first row |

Both make-ten candidates are gone from the denial, and what remains is the
counting family — which is what the sentence actually asserts. The denial removed
the possibility it denies and the affirmed clause supplied the one it claims. That
is the whole of the owner's point in one row, and it did not work an hour ago.

Second person now returns exactly what first person returns, and the person layer
reads `second → attribute_commitment` alongside it rather than the pronoun being
silently dropped.

## Three bugs the layers had, and one they found

The layer reads were wrong three times before they were right, and each way of
being wrong is worth keeping on the record.

**"did" read as a question inside "did not".** `did` is a question form and `did
not` is a denial, and a bare form match read the denial's auxiliary as a question,
putting a challenge uptake on an utterance that denies. Fixed with a guard, then
made moot by the next fix.

**The denial's reach leaked past its clause.** With the scope defined as "until a
sentence end", "i did not make ten **i just counted them all**" denied the
counting too. The reach is now a stated three tokens — `denial_reach/1` — chosen
so that it catches "did not make ten" and does not catch the clause after it. A
clause parser would do this properly; a stated window is what is here, and the
alternative in force was no scope at all.

**And the one the layers found in the corpus.** A bare `not` denial form broke
`decimal/decimal_scale_loss_comparison`, whose identifier-derived surface is
"scales seen but **not** coordinated" — the veto dropped the span for the step
that utterance was reporting. Then `instead of` as a denial form broke
`decimal/decimal_point_rule_misapplication`, whose label is
`take_max_of_place_counts_instead_of_summing`.

Both of those are the entanglement the layers exist to separate, seen from the
other side: **polarity cannot be read off the same tokens as the action while the
action's own surface is its identifier, because the identifiers carry polarity
words.** The deformation labels say `not_checked`, `without`, `not_coordinated`,
`instead_of` — negation is part of how they name themselves. So the denial forms
are clause-level only, and `instead of` went back to being what it is: a
substitution marker, which the alphabet already carries as the `substitute_*`
family. Conflating substitution with denial was the same layer confusion in
miniature.

Both were caught by `scripts/checks/strategy_recognizer.pl` — the check that had
been silently not running until earlier today. It has now caught two things in its
first afternoon of actually executing.

## What this unlocks, and what it does not

**It unlocks the discursive genre from text.** `commitment_automata.pl` has held
`acknowledge_commitment` and `attribute_commitment` since it was written, with no
way to reach them from an utterance. The person layer is that way. Nine uptakes
now connect a reading of words to actions those machines fire.

**It makes the surface a product rather than a list.** Person by force by polarity
by predicate is a product, and writing a product out by hand is the mistake this
whole arc started by fixing — 638 labels each needing individual treatment. The
185 flat phrases were that mistake again in a smaller room: every one of them bakes
in first person, so covering teacher revoicing would have meant writing all of them
again with "you".

**It does not yet make the layers the parse.** The recognizer still returns a list
of strategy candidates; the layer values are readable with `read_layer/3` and are
not yet part of what `strategy_recognize` reports. The parse the owner described —
a stack of layer values per span, the whole narrowing as each layer is read —
needs the recognizer's candidate record to carry a layer stack. That is the next
slice and it is small now that the layers exist.

**And the reach is crude.** Three tokens is a number I chose, stated in one place
so it can be argued with. A real clause boundary would come from a syntactic
parser, which is the "other parsers on board" half of the owner's suggestion and
is not here.

## Honest limits

- **Fifteen predicates, not ninety.** `canonical_predicate/2` covers the canonical
  actions the make-ten, counting, comparison and fraction cases needed. The other
  75 in-use actions still reach text only through `canonical_phrases.pl`'s
  first-person forms. So second person and denial work for a slice of the corpus,
  not all of it, and the check reports the count rather than implying coverage.
- **The forms are closed sets I chose.** Six person forms, four force values, five
  denial forms. Not a grammar of English, and anything outside them reads as
  unmarked. That is the honest failure mode and it is still a failure mode.
- **`layer_uptake` is a mapping, not a derivation.** That first person acknowledges
  and second person attributes is Brandom's distinction, cited, and it is asserted
  here rather than derived from anything. A speaker can say "I" while attributing
  and "you" while acknowledging, and nothing here notices.
- **The substitutions are not applied.** `layer_substitution/5` records that I →
  you induces acknowledge → attribute. Nothing performs the substitution or checks
  that a corpus obeys it. It is the rule written down, which is where the
  vocabulary layers in this repository start and not where they end.
- **The denial veto changes confidences, not just candidates.** Dropping spans
  lowers `matched_count`, which feeds `support_level` and `confidence`. So the
  numbers in the affirmed rows moved a little too, and I have not checked whether
  any previously-clean run became partial for a reason other than a denial. The
  recognizer's round-trip check over all 69 signatures passes, which is the
  strongest thing I can say about that.

## Result

- The recognizer was **person-blind, force-blind, and inverted on negation**:
  "i did not make ten" returned a make-ten candidate at 0.2. Found by probing the
  live server.
- **Four layers** now read independently, each able to go unread; **9 uptakes**
  into the discursive genre; **4 substitutions** recorded, including the I → you
  one the owner named.
- **The denial veto works**: both make-ten candidates disappear from the denial
  and the counting family remains. Information negates a possibility.
- **Two corpus defects surfaced** by the polarity layer: the deformation labels
  carry negation words in their own identifiers, so polarity and action cannot be
  read off the same tokens while identifiers are the action surface.
- Next: put the layer stack into what `strategy_recognize` returns, so the parse
  is the layers narrowing rather than a strategy list with the layers readable
  beside it.
