# Addendum — checking the table-gap claim, and what it cost

Model: `claude-opus-5[1m]` (Opus 5, 1M context).
Date: 2026-07-25. Continues `2026-07-25-action-grammar-report.md`.

Files changed: `knowledge/strategies/action_vocabulary_map.pl`,
`knowledge/strategies/action_grammar.pl`,
`scripts/research/build_action_grammar.py`,
`scripts/checks/action_vocabulary_map.py`,
`scripts/checks/action_grammar.py`, this report.

## Why this slice

The previous report closed with a finding stated as a fact about the tables: 47
machines, a quarter of the corpus, carry no step whose stance is conserving or
deforming, and that is a gap in the transition tables. Design studies in this
repository have overclaimed three times, so the finding got checked against the
live tree before it hardened.

Three of the 47 were my error, and all three came from one place.

## `retain_unchanged` was doing three jobs

It carried eleven rows. The words are the same across all of them — retain,
preserve, leave unchanged — and the doings are not:

- `division/measure_groups_of_size` keeps the leftover as the remainder. Its
  deformation partner, `share_into_divisor_groups`, ends on
  `lose_measurement_remainder`. The retention *is* the conservation.
- `measurement/unit_preserving_measured_quantity_change` keeps the unit through
  the change. Its partner discards it. Same thing.
- `algebraic/one_sided_equation_operation` leaves the right side unchanged after
  removing a constant from the left. The retention *is* the imbalance.
- `measurement/change_unit_label_without_scaling` keeps the numeral where the
  conversion factor obliged it to scale. Same thing.
- `geometry/rectangle_missing_side_from_area` keeps the known side to divide by.
  The retention is neither: the strategy owes that quantity nothing.

Stance is a property of a canonical action in this schema, so an action whose
members disagree about stance can carry neither reading. Three actions now:

| action | stance | rows | the retention |
|---|---|---:|---|
| `retain_what_must_survive` | conserving | 5 | keeps what the strategy is obliged not to lose |
| `retain_where_change_was_due` | deforming | 4 | keeps what the step obliged it to change |
| `retain_unchanged` | neutral | 4 | carries a quantity the strategy owes nothing to |

The inverting pair is the finding, not the bookkeeping. **Retaining is
conserving where change was not due and deforming where it was**, and nothing
about the word "retain" says which. This is the same shape as
`halt_before_completion` / `interrupt_before_completion` from the last round —
one doing, opposite bearings, decided by what the step owed rather than by what
the step did.

`preserve_turn` moved too, out of `register_givens`. In `angle_as_ray_length` the
turn is held fixed while the ray stretches, and the turn surviving unchanged is
the whole reason the machine is a deformation: nothing about the angle changed
and the closing edge reads the changed extent as a changed magnitude. Its arc
went from `work_then_break` to `keep_first_then_break`, which says what the
machine actually does.

## The audit that found it now runs every check

A local label saying preserve or retain, under an action whose stance is not
conserving, is usually a mistake. It was one eleven times. So
`scripts/checks/action_vocabulary_map.py` performs that audit on every run and
fails on drift.

Some inversions are deliberate, and the check consults an allowlist where each
one has to say why — because "the label says preserve and the stance is
deforming" is exactly what a mistake looks like, and the only thing separating
the two is an argument:

| action | why the inversion is deliberate |
|---|---|
| `set_aside_irrelevant_attribute` | the labels all begin `ignore_`, and setting aside a property the conclusion does not depend on is correct |
| `retain_where_change_was_due` | the labels all say retain or preserve, and the retention is the deformation |
| `record_loss` | two labels say `preserve_result_but_lose_X`; the map takes the loss clause |
| `exhaust_resource` | the label says `fail_to_retrieve`, and a resource at its limit is the ORR crisis, not a break |
| `filter_by_constraint` | retaining is set membership in a search, not a quantity owed |
| `name_result` | `certify_equivalent` and `retain_all_maximal_frequencies` describe the answer's content |
| `register_givens` | nine statistics machines open on `preserve_data_set`; the position rule decides these |
| `retain_unchanged` | the residue of the split: carried to the next step, owed nothing |
| `select_unit_scale` | `retain_lcm_as_composite_iteration_unit` chooses what to work in |

Writing that table forced the third correction. `geometry/ordered_pair_coordinate_plot`
had `preserve_coordinate_order` under `assign_roles`, and I could not write a
reason for the inversion, because there isn't one: ordered-pair plotting is
answerable for exactly that order — it is why (3,5) and (5,3) are two points —
and the machine has no other edge that records a conservation. It moved to
`retain_what_must_survive` and left the gap list.

The check also fails on a *stale* exemption, an action allowlisted that no longer
carries any keep-word or lose-word row. Two were stale on the first run and are
gone. An exemption that no longer applies hides real drift.

## The gap is now a work list, not a paragraph

`machine_conservation_gap/4` is derived on every build and names exactly the
machines whose every step is neutral, with the machine's whole word in the reason
so a reader can judge it. The grammar check verifies the census is exactly that
set — no more, so it cannot overstate the gap; no fewer, so a machine cannot slip
off the list by omission.

A prose finding has no consumer. This one shrinks by itself as the tables gain
the labels, and it is queryable now.

**44 machines** remain, down from 47: 11 geometry, 8 statistics, 4 fraction, 4
multiplication, 3 algebraic, 3 measurement, 2 each in addition, counting,
decimal, division, subtraction, 1 ratio. Every one of them conserves or loses
something; none has a label that says so. Filling that in means editing the
source action-pair files that `build_transition_tables.py` generates from, which
is a change to the strategy definitions and needs its own slice.

And the caution the list carries in its own preamble: three machines left it
because the conservation was in the tables all along, under a label the alphabet
had read as a working retention. Some of what remains may be the same kind of
mistake, so the list should be read machine by machine before any of it is read
as a table gap.

## What the corrections did to the arcs

| arc | before | after |
|---|---:|---:|
| `unrecorded_run` | 47 | **44** |
| `work_then_break` | 29 | 31 |
| `keep_then_work_on` | 20 | 23 |
| `break_recover_break` | 20 | 17 |
| `break_first_work_break` | 5 | 4 |
| eleven specific arcs | 0–2 | 1–2 each |

The two headline arcs are unchanged (`work_then_keep` 34, `keep_work_keep` 7),
and so are all five cross-genre arcs and their membership. The corrections moved
machines between arcs and did not touch the cross-genre result, which is what I
would have wanted either way and is worth stating: had the split changed the
five, the finding would have been an artifact of one action's stance.

Two arcs had to be named that had not existed before: `keep_first_then_break`
(one machine, `angle_as_ray_length`) and `break_three_times` (one machine,
`one_sided_equation_operation` — the most broken arc in the corpus, now that
leaving the right side unchanged reads as the break it is). The arc count went 18
to 20.

One phrase had to be redefined rather than retired. `carry_forward_and_name` was
`retain_unchanged > name_result` and after the split no machine carried it: all
three that had were the conserving case. It is `keep_what_survives_and_name` now,
over `retain_what_must_survive`, and the phrase had been hiding the conservation
it names.

## The gate is green end to end

Both failures the last two reports flagged as pre-existing are cleared, by the
other session working in this repository rather than by me: the capability
registry at `4ff6b19` and the Illustrative Mathematics field-context cache at
`6ad7d56` ("the cache returns from Big Red — 1,317 lessons, drift check green").
The alphabet and grammar checks are wired into `scripts/checks/run_all.sh` after
`vocabulary_licenses.py`, so `run_all.sh` reaches them and completes.

This slice's own verification:

- `scripts/checks/action_vocabulary_map.py` (exit 0), now also passing the
  stance-consistency audit: 121 canonical actions, 787 mapping rows, 729 high
  and 58 medium confidence, no remainder, 9 deliberate inversions each carrying
  its reason and none stale.
- `scripts/checks/action_grammar.py` (exit 0): byte-identical regeneration twice;
  every `stances` row recomputed from the machine's word; every arc recomputed
  from that row; the gap census exactly the 44.
- The analyzer's default path still hashes identical to the pre-flag version
  (`45aee5ec…518039cc` / `f4563f76…8740ffd6`), after this slice changed 12 more
  mapping rows.

## Result

- Corrections: **3 machines** wrongly counted as recording nothing; one action
  split into three because its members disagreed about stance; one action moved
  out of `register_givens`.
- Alphabet: 119 → **121** canonical actions. Mapping rows unchanged at 787, 12
  reassigned.
- The gap claim, corrected and made queryable: **44**, not 47, and carried by
  `machine_conservation_gap/4` rather than by a sentence in a report.
- Arcs: 18 → **20**; the five cross-genre arcs and their membership unchanged.
- The audit that caught all of this runs on every check, with an allowlist that
  has to argue for each deliberate inversion and fails when an exemption goes
  stale.
