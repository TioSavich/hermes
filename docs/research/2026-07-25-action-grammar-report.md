# The grammar above the alphabet — a second genre, and the level where the two meet

Model: `claude-opus-5[1m]` (Opus 5, 1M context).
Date: 2026-07-25. Continues `2026-07-24-task-125-report.md`.

Files written: `knowledge/strategies/action_vocabulary_map.pl` (revised),
`knowledge/discourse/commitment_automata.pl` (new),
`knowledge/strategies/action_grammar.pl` (new, generated),
`scripts/research/build_action_grammar.py` (new),
`scripts/checks/action_grammar.py` (new),
`scripts/checks/action_vocabulary_map.py` (extended), this report.

## What the owner asked for, and what came back

Four things: split the overbroad action; find out whether the grammar around
the variants is diverse; take seriously that arithmetic computation is only one
genre of automaton, with the act of committing as another; and keep working the
parser problem — the tutoring intuition that some words, in some contexts, have
already lost it.

The short version of what came back:

- The overbroad action is seven actions now, and the two gaps the last report
  named are closed. 644 labels, 119 canonical actions, 787 mapping rows, no
  remainder.
- The second genre exists and runs: 18 machines over commitment, entitlement,
  and Brandom's meaning-use relations. It is not new machinery. Both halves were
  already here and had never been put in automaton form.
- The grammar around the variants is diverse to the point of being no grammar at
  all at the level of actions. 189 machines across both genres spell 187
  distinct action words. Almost nothing repeats.
- One level up it collapses hard. Replace each action by its normative bearing
  and collapse repeats, and the 189 machines spell **18 arcs**, five of them
  spelled by machines from both genres. That is the shared basis, and it is not
  the one I expected to find.
- The parser problem does not come out the way the intuition suggests, and the
  way it does come out is more useful. Below.

## The split

`substitute_available_relation` carried 27 labels and the last report flagged it
as too wide to carry a finding. The seam is what kind of thing gets put in place
of what the task requires:

| action | labels | what stands in for what |
|---|---:|---|
| `substitute_count_for_measure` | 7 | a discrete count of parts for the magnitude those parts make |
| `substitute_operation` | 7 | an operation the learner can already run for the one called for |
| `substitute_appearance_for_measure` | 5 | a figural property of the presentation for the measured quantity |
| `rename_in_place_of_transforming` | 3 | a change of name for the transformation it would have to accompany |
| `substitute_symbol_reading` | 2 | a reading of a sign for the relation that sign writes |
| `substitute_scalar_for_structured_quantity` | 2 | a bare value for a quantity carrying sign or spread |
| `substitute_additive_for_multiplicative` | 1 | an additive difference for a multiplicative or order relation |

Two of these were the gaps the last report left open. `rename_in_place_of_transforming`
takes the two rows that had been forced onto the catch-all at `confidence(low)`;
both are now high, and the low tier is empty because nothing is left in it.
`apply_quantity_change` closes the one unmapped remainder by being
direction-neutral on purpose, which is what recording that remainder was for.

The split costs something and the cost is worth naming. Finer actions share less:
pairs of witnessed automata with a non-empty shared action domain fall from 883
to 855, and the distinct action alphabet over the 69 rises from 74 to 78. Sharing
did not disappear; it moved up a level, which is the rest of this report.

## The second genre

`knowledge/discourse/commitment_automata.pl` holds 18 machines whose steps do
something to a deontic score rather than to a quantity: nine viable practices
and their deformation partners, in the same fact shape as the strategy
transition tables, so every tool that reads automata reads both.

They are not new machinery, and that mattered more than anything else in
designing them. `formal/learner/deontic_scorekeeper.pl` already carries
`undertake_commitment/2`, `grant_entitlement/2`, `withdraw_commitment/2`,
`incompatible/2`, `material_inference/3`, `ungrounded_grant_attempt/3`, and
`crisis_from_deontic_incoherence/3`. `formal/pml/mua_relations.pl` already
carries 24 vocabularies, 32 practices, and the meaning-use relations among
them — `pv_sufficient/2`, `vp_sufficient/2`, `pp_sufficient/3`, `lx_for/3`. What
was missing was the automaton reading. So each edge names which of the two it
answers to, and the ones the literature carries and no predicate here runs are
marked as such rather than quietly filled in:

- **61 of 85 edges** are `provenance(authored(grounded(Ref)))` — a predicate in
  this repository carries that step.
- **24 of 85 edges** are `provenance(authored(unmodelled(Ref)))` — Brandom
  names the step and nothing here runs it.

That 24 is the remainder this round opens as the last round's closes. Attending
to an utterance before it is complete, authorizing deferral, assuming the
vindication task, inheriting entitlement along a terminated chain: the
scorekeeper has commitment and entitlement as statuses and does not have the
moves by which they are taken up. Naming which 24 is the point of counting them.

The machines, by pair:

| viable | deformation |
|---|---|
| `assertional_commitment` | `assertion_without_vindication_task` |
| `entitlement_by_deferral` | `deferral_regress` |
| `entitlement_by_inference` | `entitlement_by_formal_schema` |
| `entitlement_by_authority` | `authority_where_inference_required` |
| `incompatibility_recognition` | `incompatible_commitments_held` |
| `attribution_and_acknowledgement_kept_apart` | `attribution_taken_as_acknowledgement` |
| `commitment_repair` | — |
| `algorithmic_elaboration` | — |
| `pragmatic_metavocabulary_construction` | — |
| `universally_lx_loop` | — |
| `tutorial_interruption_on_incompatible_token` | `utterance_run_to_its_loss` |

The last pair is the owner's tutoring move and its absence. It is in this genre
rather than in a note because it is a discursive practice with a viable and a
deformed run, and the corpus's own grammar is what says so.

## The two axes, and why there had to be two

The two genres share exactly one action name (`register_givens`). Comparing them
therefore cannot go through action names, and `action_register/4` is what it goes
through instead. Every canonical action carries a **register** — what kind of
doing it is, whatever material it works on — and a **stance** — its own normative
bearing.

| register | conserving | deforming | neutral | total |
|---|---:|---:|---:|---:|
| transformation | 11 | 2 | 8 | 21 |
| normative | 10 | 8 | 0 | 18 |
| operation | 2 | 2 | 14 | 18 |
| comparison | 0 | 3 | 12 | 15 |
| iteration | 1 | 4 | 9 | 14 |
| constitution | 0 | 3 | 10 | 13 |
| partition | 0 | 0 | 6 | 6 |
| inscription | 1 | 1 | 3 | 5 |
| delegation | 0 | 1 | 4 | 5 |
| search | 0 | 0 | 4 | 4 |
| **all** | **25** | **24** | **70** | **119** |

The axes have to be two because the corpus contains pairs that agree on one and
differ on the other, and collapsing either axis would lose exactly the
distinction those pairs carry:

- `assign_roles` and `conflate_roles` are both **constitution**, neutral against
  deforming. Binding roles and collapsing two of them are the same kind of
  doing.
- `set_aside_irrelevant_attribute` and `treat_relevant_as_irrelevant` are both
  **normative**, conserving against deforming. Ignoring orientation when
  classifying a shape and ignoring the referent whole are the same doing on
  material that bears differently.
- `halt_before_completion` and `interrupt_before_completion` are both
  **iteration**, deforming against conserving. This is the owner's point in one
  row: stopping before the end breaks a traversal that was required and keeps
  what is left of one whose relation had already gone. Same doing, opposite
  bearing, and which one it is depends on nothing about the stopping.

`action_kinship/3` records 14 pairs that do the same thing to different
material — `verify_invariant` with `test_compatibility`, `record_loss` with
`record_deontic_incoherence`, `dispatch_to_kernel` with `defer_to_asserter`,
`iterate_unit` with `elaborate_practice_algorithmically` (algorithmic elaboration
is iteration whose unit is a practice). Kinship is not identity: the
`halt_before_completion` / `interrupt_before_completion` pair is kin and differs
in stance, and the row says so.

The docstring states plainly that this is not PML. PML's modes of validity and
its compressive and expansive polarities classify discourse; these axes classify
automaton actions. Whether they line up is open, and nothing here answers it.

## Where the two genres meet

This is the result. The owner's image was a Fourier decomposition: the noise
decomposing onto a basis of simple waves. The decomposition exists, and the basis
is not made of actions.

| grain | distinct forms over 189 machines |
|---|---:|
| canonical action word | 187 |
| register word | 169 |
| stance word | 69 |
| **stance word, runs collapsed (the arc)** | **18** |

At action grain there is essentially no sharing — 187 forms for 189 machines. At
arc grain, 18 forms cover everything, **five of them spelled by machines from
both genres**:

| arc | machines | discursive members |
|---|---:|---|
| `work_then_keep` | 34 (24 + 10) | every viable discursive machine but one |
| `work_then_break` | 29 (24 + 5) | `attribution_taken_as_acknowledgement`, `authority_where_inference_required`, `deferral_regress`, `incompatible_commitments_held`, `utterance_run_to_its_loss` |
| `break_recover_break` | 20 (19 + 1) | `entitlement_by_formal_schema` |
| `keep_work_keep` | 7 (6 + 1) | `incompatibility_recognition` |
| `keep_then_break` | 4 (3 + 1) | `assertion_without_vindication_task` |

Three of these are worth reading slowly.

**`keep_then_break`** puts `assertion_without_vindication_task` with
`addition/make_ten_drop_leftover` and `algebraic/drop_distributed_term`. Asserting
and then declining the responsibility the assertion carries has the same
normative arc as making ten and then abandoning the leftover: the work is done,
the relation is genuinely secured, and then it is dropped. Not a metaphor — the
same order of conservation and loss.

**`keep_work_keep`** puts `incompatibility_recognition` with
`addition/make_ten_split_leftover`, `algebraic/balance_preserving_linear_solution`,
`multiplication/commute_factors_preserve_product`, and
`subtraction/decompose_base_for_ones`. Noticing two commitments cannot be held
together and withdrawing one has the arc of solving by balance-preserving steps.

**`break_recover_break`** is the corpus's commonest deformation arc, 20 machines,
and `entitlement_by_formal_schema` sits in it with `decimal_add_unaligned_numerals`
and `division/share_into_divisor_groups`. Matching a valid schema where a
material inference was required breaks something, the machine then does work
that looks perfectly ordinary, and breaks again at the close.

A shared arc licenses one claim and no more: the two machines agree on the order
in which conservation and loss arrive. The generated file says so where a reader
will meet it, because this is the layer that makes overreading easy.

### The arc distribution, and one finding that is about the tables

| arc | machines | | arc | machines |
|---|---:|---|---|---:|
| `unrecorded_run` | 47 | | `keep_first_work_keep` | 3 |
| `work_then_keep` | 34 | | `keep_first_then_work_on` | 2 |
| `work_then_break` | 29 | | `keep_work_keep_work_on` | 2 |
| `keep_then_work_on` | 20 | | `break_keep_break` | 2 |
| `break_recover_break` | 20 | | five arcs with one machine each | 5 |
| `break_then_work_on` | 9 | | | |
| `keep_work_keep` | 7 | | | |
| `break_first_work_break` | 5 | | | |
| `keep_then_break` | 4 | | | |

`unrecorded_run` — 47 machines, a quarter of the corpus, all computational — is
the arc of a machine with no step whose stance is conserving or deforming at all.
It does its work and stops without recording what it kept or lost. Twelve are
geometry, eight statistics. That is not a finding about mathematics; it is a gap
in the transition tables, and it means a quarter of the corpus cannot participate
in any conservation-based comparison. Worth a slice of its own.

## The phrase layer, and its honest thinness

`action_phrase/3` names 30 contiguous action sequences that recur across at least
two families: `bind_the_roles` (`assign_roles > assign_roles`, 7 machines, the
corpus's most shared opening), `partition_then_iterate` (the Steffe/Olive fraction
core), `skip_then_misname` (6 machines, the most shared deformation),
`measure_together_then_order`, `acknowledge_twice_then_test`.

The layer is thin and the numbers say so: **207 of 878 action slots, 23%, sit
inside a named phrase**. The other 671 are bare canonical actions the phrase
table does not reach, kept on the record in every `machine_grammar/6` row rather than
smoothed over. This is the same result as the 187-distinct-words finding seen
from below: action sequences mostly do not repeat, so a phrase basis over actions
cannot cover much. Inflating the phrase table by naming two-machine coincidences
would have hidden that instead of showing it.

## The parser problem

The intuition was: some words, used in some contexts, signal that the rest is
already lost, and the tutor's move is to stop there. `interruption_license/5`
tests that against the corpus. The verdicts are derived by rules stated in the
builder, and each row's basis carries its own n.

48 rows: 16 `stop`, 20 `watch`, 12 `continue`. And the shape of that split is the
answer:

**Almost every stop is a token whose own stance is already deforming.** Fifteen
of the sixteen. Which means the token names the break rather than predicting it —
useless for a tutor, who needs to know before the break lands.

**Exactly one context-sensitive stop survives the two-machine, two-family gate.**
`remove_quantity` after `register_givens`: subtracting straight off the givens,
with no role binding or unit choice between. Two machines
(`geometry/subtract_side_from_area`, `ratio/additive_extension_of_ratio`), neither
recovers. Two machines is thin evidence and the row says it is thin.

**The tokens the intuition is about are the `watch` rows, and they decide
nothing.** `register_givens` sits in 61 machines, 21 of which end on a break.
`remove_quantity` 14, 6 breaking. `retain_unchanged` 11, 5 breaking.
`combine_quantities` 12, 5. At this grain the token is not the signal; the context
is, and the corpus does not carry enough context to fix it.

So the intuition does not come out as a lookup table. What it does come out as is
sharper, and it is not a verdict:

**Of the 73 machines containing a deforming step, 4 have any conserving step
after it.** `fraction/gap_thinking_fraction_comparison`,
`fraction/number_line_count_marks_not_intervals`,
`subtraction/add_instead_of_subtract_column`,
`subtraction/smaller_from_larger_in_column` — and in all four the later
conserving step is a local one (`compare_residuals`, `align_to_common_unit`,
`recompose_total`) that does not repair the earlier break. **Recovery after a
break is essentially absent from this corpus.**

And: **the first break arrives one or two steps before the end in 74% of the
machines that break** (45 of 60), three or more steps early in 11 of 60.

Put together, those two say why stopping is right without saying the break can be
seen coming. Running on almost never recovers, and the break lands so late that
almost nothing is left to run on to. The warrant for "let me stop you right
there" is not that the token predicts the loss. It is that after the loss there
is nothing the utterance goes on to do.

What would change this is not a better rule over these tables. It is a different
corpus: utterance-level tokens with the context an automaton edge does not
carry — what the student has already committed to, what the task asked, what was
established two turns back. The discursive genre now has a machine shaped for
exactly that data (`tutorial_interruption_on_incompatible_token`) and no data to
run it on. That is a stalled input, named as one.

## Verification

- **Strict SWI load**, warnings fatal: `strategies(action_vocabulary_map)`,
  `strategies(action_grammar)`, and a `consult` of the discursive genre. All
  clean.
- **`scripts/checks/action_vocabulary_map.py`** (exit 0): 787 mapping rows over
  787 table triples and 638 census labels, none unmapped; 119 canonical actions
  (73 cited, 46 coined), none unused, where a discursive action earns its place
  by being fired rather than by carrying a mapping row; every action carries one
  genre, register, and stance from the closed sets; all 14 kinship pairs cross
  the genres; HIGH-risk citations record their disambiguation obligation; sharing
  and measuring stay disjoint.
- **`scripts/checks/action_grammar.py`** (exit 0): the builder rerun is
  byte-identical to the committed file, twice; all 189 machines have exactly one
  grammar row; no arc or phrase is unused; the discursive genre is deterministic
  by action, fully reachable, and terminating in an accepting state for all 18
  machines; **every `stances` row is recomputed from the machine's own word
  through `action_register/4` and every arc from that row collapsed**, so a hand
  edit to a derived row fails; every `phrases` row rebuilds its machine's action
  word exactly; every `stop` verdict is re-tested against its carriers.
- **Default analyzer path still byte-identical** to `HEAD`, after the split
  changed 27 mapping rows: JSON `45aee5ec…518039cc`, `summary.md`
  `f4563f76…8740ffd6`, both unchanged from yesterday's proof. Mapped JSON is now
  `3ba87030…f45cb065`.
- **Gate chain**: `transition_tables`, `vocabulary_licenses`, `strict_load`,
  `crosswalk_load`, `geometry_load`, `app_manifest --verify` all pass. The two
  failures from yesterday are unchanged and still outside this work:
  `extract_capability_registry` wants one line about `vocabulary_licenses.pl`
  left behind at commit `ee6f54d`, and `field_context_cache.py` reports IM cache
  drift for `IM-GK-U1-L1`. Neither new module appears in the registry
  extractor's output.
- Neither new check is wired into `scripts/checks/run_all.sh`. Two lines are the
  follow-up, along with the one for yesterday's check.

## Honest limits

- **The arcs are coarse by construction.** An arc is a stance word with repeats
  collapsed, so it throws away how long each run was and what the actions were.
  Two machines sharing `work_then_keep` may have nothing else in common, and 34
  machines share it. The arcs that carry information are the specific ones —
  `keep_then_break` with 4 machines, `keep_work_keep` with 7 — not the two big
  ones.
- **Stance is my judgment, 119 times.** The register/stance table is authored,
  and the whole cross-genre result rests on it. The pairs that differ only in
  stance are where a disagreement would bite hardest, and they are the rows I
  would defend first and want argued with first.
- **The discursive genre is 18 machines I wrote.** They are faithful to
  predicates that exist and to chapters I can cite, and they are not observed
  data. Nothing has run them against a transcript. That the five cross-genre arcs
  came out is a fact about two authored corpora, and the computational one has
  live probes behind 69 of its 171 machines while the discursive one has none.
- **The parser result rests on 60 breaking machines.** The recovery finding
  (4 of 73) and the lateness finding (74% within two steps) are corpus facts at
  that scale, not general claims about mathematical talk.
- **`unrecorded_run` covering a quarter of the corpus limits everything above.**
  47 machines carry no conservation record at all, so they contribute nothing to
  any stance-based comparison. Whether that is a gap in the tables or a real
  property of those strategies is not something this layer can tell.
- **Nothing here is wired into the application.** All of it is review-pending
  data; the analyzer reads the map only when asked, and the grammar module has no
  consumer yet at all.

## Result

- Alphabet: **119** canonical actions (87 computational, 32 discursive; 73 cited,
  46 coined) over **644** labels, **787** mapping rows, **0** remainders.
- Split: 1 overbroad action → **7**; both named gaps closed; the `low` confidence
  tier is now empty.
- Second genre: **18** machines, **85** edges, **61** grounded in predicates here
  and **24** carried only by the literature.
- Axes: **10** registers × **3** stances over all 119 actions; **14** kinship
  pairs crossing the genres.
- Grammar: **30** phrases covering **23%** of action slots; **18** normative arcs
  covering all 189 machines, **5** spelled by both genres; **48** interruption
  licenses (16 stop, 20 watch, 12 continue).
- The compression that answers the question: **187 distinct action words → 18
  arcs**, and the two genres meet at the arc and nowhere below it.
