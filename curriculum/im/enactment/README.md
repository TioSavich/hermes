# curriculum/im/enactment

Lane modules for the second rung of the IM coverage census: lessons that name a
doing no arithmetic automaton computes. An enactment names the structure a
lesson asks a class to move through, runs that structure on the lesson's own
printed inputs, and prints an artifact together with a verdict about what the
artifact warrants. It is not a claim that software ran a lesson.

The contract is `curriculum/im/lesson_enactment.pl`. The spec it answers is
`.superpowers/sdd/task-236-spec-lesson-enactment.md`.

## One file here is one lane

`scripts/curriculum/run_lesson_enactments.pl` and
`scripts/checks/lesson_enactment.pl` both glob every `.pl` directly in this
directory, so a lane lands a file and both the census and the gate pick it up
with no registration edit. Files a lane is built from rather than lanes
themselves live in `support/` and the glob does not reach them.

| Lane file | Subclass | Forms | Lessons enacted |
|---|---|---|---|
| `geometry_construction.pl` | `geometry_construction_or_measure` | 12 | 72 of 72 |
| `measurement.pl` | `measurement_task` | 10 | 48 of 50 |
| `data_representation.pl` | `data_representation_or_question` | 11 | 42 of 42, plus one measurement lesson whose doing is a routine |
| `counting_place_value.pl` | `counting_place_value_or_comparison` | 6 | 14 of 36 |
| `fraction_model_reasoning.pl` | `fraction_model_reasoning` | 1 | 3 of 26, and a reference rather than a lane |

`support/geometry_figures.pl` is the lattice figure algebra the geometry forms
read from. Sides, parallel pairs, right angles, equal lengths, lines of symmetry
and area are computed from vertex coordinates by exact integer arithmetic. No
attribute is stored as a label and no comparison is a float comparison.
`support/data_representation_lessons.pl` carries the data lane's lesson rows and
is included rather than loaded as a module.

The counts above come from
`data/learningcommons/derived/im_lesson_enactment_census.json`, which is
produced by running the machines.

## Two routes to a run

A lane on the **generic route** declares `enactment_verb/4` and
`enactment_passes/4` and lets the contract's runner drive the move sequence. The
fraction reference lane takes it.

A lane on the **lane route** supplies `enactment_run/3` and
`enactment_lane_verdict/2`: it derives its own inputs and runs its own move
sequence. The four breadth lanes take it, because each wrote its machines before
the contract existed and their move sequences vary per lesson rather than per
form. Both routes are run by `enact_lesson/2`, which is the only way the census
reaches a lane. Nothing on this rung reads a lane's emission file to count it.

Each lane's registration block sits at the end of its file under a heading that
names it.

## Input provenance

Three values, and every emitted row carries one.

- `curriculum` — the guide printed the numbers and categories the run used.
- `curriculum_sample` — the guide printed them as one worked sample of a task
  whose answer is open. Four data-lane lessons are of this kind. The values are
  curricular, so the verdict is not capped; the row says `curriculum_sample` so
  a reader does not take one worked case for the task's answer.
- `machine_supplied` — the guide names a card set, a handout, a manipulative or
  a value the markdown extraction drops, and the lane supplied one of its own so
  the structure could still run. This caps the verdict at `partial`, and the cap
  is applied by the contract rather than by each lane.

The three are never added together.

## The artifact

`scene(Renderer, Term)` routes to a compiler in `knowledge/strategies/render/`;
the contract compiles the document and carries it in the row, so one document
reaches the row, the trace dict, and the census scene check. `printed(Record)`
is a record rather than a picture. A list of both is the geometry case, where
the figure and the adjudication beside it are different things and folding
either into the other loses it.

Some compilers cost the square of their input. `measurement_strip_scene` carries
the whole jump list on every frame, and the tiling compilers emit a frame per
row. A lane bounds its own renderer input with `enactment_render_bound/2` and
prints past the bound rather than waiting.

## Running it

```
python3 scripts/curriculum/build_im_lesson_enactment_census.py
swipl -q -l paths.pl -s scripts/checks/lesson_enactment.pl -g main -t halt
swipl -q -l paths.pl -s scripts/checks/geometry_enactment.pl -g main -t halt
python3 scripts/checks/geometry_enactment_warrants.py
python3 scripts/checks/measurement_enactment.py
swipl -q -l paths.pl -s scripts/checks/data_representation_enactment_citations.pl -g check -t halt
python3 scripts/enactment/build_best_im.py
```

The census writes one JSONL file per subclass into
`data/learningcommons/derived/lesson_enactments/` and is the only writer of
those files. Its `--check` re-runs the machines, compares the census against the
committed one, and compares the rows against a fresh run. None of these reads
gitignored runtime data, so all of them are correct in a worktree.

## Boundary

`knowledge/geometry/geometry_bridge.pl` stays unloaded, and nothing here loads
it. The figure algebra is the geometry lane's own and does not read the geometry
knowledge base; the two answer different questions, and joining them is separate
work.
