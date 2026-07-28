# The Atlas sweep

One step of `f_{t,c}`, the transition function in
`formal/learner/task_transition.pl`, for every compiled task event in
`curriculum/im/generated/compiled_task_instances.pl`, crossed with
every learner stage the whole-number reorganization domain licenses, crossed with
the productive and licensed-deformation routes each lesson carries. The merged
record stream is `atlas_landscape.jsonl`, and the set of lesson codes appearing in
it is what `scripts/curriculum/build_lesson_evidence.py` counts as
`measured_transition` evidence.

Where `scripts/curriculum/mini_atlas.pl` runs the same transition function over
the declared basis, this pipeline runs it over the whole compiled alphabet and
shards it by lesson.

Ported from `scripts/bigred/iteration14/` in `umedcta-formalization`, which is
read-only. The transition logic, the merge, the sort key, and the JSON
serialization came across unchanged; what moved is the corpus vocabulary. That
tree calls the curriculum `lessons/` and the learner core `learner/`; Hermes
calls them `curriculum/` and `formal/learner/`. Each ported file names its paths
once, in a block at the top, because a path stated in two vocabularies is what
stalls a port of this shape.

## Files

| file | role |
|---|---|
| `generate_cells.pl` | emits `work/cells.json`: one cell per lesson with events |
| `export_atlas.pl` | `run/2` (one lesson shard) and `coverage/1` (the audit-coverage record) |
| `run_cell.sh` | run one lesson shard in one `swipl` process |
| `run.sh` | `--local`, `--cells`, `--merge`, `--coverage`, `--aggregate`, `--go` |
| `aggregate.py` | merge shards into landscape + fact module + summary |
| `job.slurm` | the cluster sweep, one array task per cell |
| `aggregate.slurm` | the cluster aggregate, `afterok` the array |

## Run it locally

```bash
bash scripts/bigred/atlas/run.sh --local        # all cells, sequential
bash scripts/bigred/atlas/run.sh --local 8      # first 8 cells
```

`--local` needs no scheduler. It generates the cell list, runs each lesson shard
in its own `swipl` process one after another, then merges. Over the 151 cells and
821 instances compiled on 2026-07-27, the shard loop took **35 minutes** on an
M-series laptop: about 5 of those are process startup (~2s per cell to load the
transition graph) and about 20 are per-transition timeouts running out their
20-second wall.

`--local` deliberately does not run coverage. The coverage record executes the
full traversal audit over every instanced lesson and does not finish inside ten
minutes here at the default grade ceiling of 6 (the cluster job allots four
hours). It feeds only the summary's gap accounting; the landscape does not depend
on it. Run it on its own when the summary needs it:

```bash
ATLAS_GRADE_MAX=1 bash scripts/bigred/atlas/run.sh --coverage   # ~13s
bash scripts/bigred/atlas/run.sh --merge                        # fold it in
```

## Refreshing `measured_transition`

After `scripts/curriculum/compile_action_mappings.py` writes new task instances:

```bash
ATLAS_WORK=scripts/bigred/iteration15/work/atlas \
  bash scripts/bigred/atlas/run.sh --local
python3 scripts/curriculum/build_lesson_evidence.py
```

`ATLAS_WORK` points the pipeline's work tree at the directory
`build_lesson_evidence.py` already reads, so the refreshed landscape lands where
the evidence ledger looks for it rather than beside a second copy. Run without
`ATLAS_WORK` first if you want to diff the new landscape against the tracked one
before replacing it; the default work tree is `scripts/bigred/atlas/work/`.

## Env knobs

| variable | default | meaning |
|---|---|---|
| `ATLAS_STAGES` | `1,2,3` | learner stages swept |
| `ATLAS_POLICY` | `accept_efficiency` | the reorganization policy |
| `ATLAS_CELL_SECONDS` | `20` | per-transition wall limit; timeouts are recorded |
| `ATLAS_GRADE_MAX` | `6` | audit ceiling for the coverage record |
| `ATLAS_CELL_WALL` | `4800` | whole-cell shell backstop (needs Linux `timeout`) |
| `ATLAS_STACK_LIMIT` | `4g` | Prolog stack bound; `run_cell.sh` records why the default is 4g |
| `ATLAS_WORK` | `scripts/bigred/atlas/work` | the work tree |

## Model version — the `(s, I)` state

- state `= learner_state(Stage, Inventory)`, `Inventory` a sorted set of
  `strategy(Op, Stage)`; every transition starts from `Inventory = []`.
- policy `= policy(accept_efficiency)` by default.
- stages `= [1, 2, 3]`, the reorganization-domain ladder
  (`reorganize:rd_level_above` caps it at 3).

## Honest register

- Every record computes one step of the **model's** local dynamics under the
  stated `(s, I)` state and policy. It certifies formal closure of that step
  only (`certifies: formal_closure_only` in the summary). It says nothing about
  a child.
- The stage ladder is model-given, not discovered. The sweep records where the
  licensed moves land; it does not claim the machine found the ladder.
- Lessons without compiled events are not shard cells. They appear as explicit
  gaps in the summary (`coverage_vs_audit.gap_lessons_...`), computed against the
  traversal audit, never silently skipped.
- Timeouts are logged, never dropped. A transition exceeding `ATLAS_CELL_SECONDS`
  is written with `status:timeout`; one exhausting a VM resource is written with
  `status:resource_error`. There are no silent caps. Timeout counts are a
  wall-clock measurement, so they are the part of the landscape a rerun on
  different hardware can move.
- `formal/learner/atlas/task_quotient.pl` has not been ported into this
  checkout, so the summary's `task_quotient_basis_certificate` reports itself
  unavailable and names that file. The atlas-wide quotient census beside it is
  computed from the per-record signatures and does not depend on the module.

## Faithfulness against the vendored landscape

`scripts/bigred/iteration15/work/atlas/atlas_landscape.jsonl` is the artifact the
cluster produced before this port existed: 2463 records over 151 lessons, from
the 821-instance alphabet compiled on 2026-07-27. A local sweep over that same
alphabet produces 2463 records over the same 151 lessons, aligned key for key,
with no record present on one side and absent on the other. Of those, 2313 are
byte-identical once the corpus prefix below is rewritten. The remaining 150
records fall into four accounted differences, and 432 records carry the corpus
prefix that the first row describes:

| records | difference | why |
|---:|---|---|
| 432 | `provenance` names `curriculum/im_teacher_guides/` where the vendored record names `geometry/corpus/im_teacher_guides/` | the corpus directory moved when the curriculum was vendored into Hermes. The sweep copies the compiled instance's provenance through; it does not construct it. |
| 96 | vendored `status:timeout`, every one of them `solved` here (108 timeouts there, 12 here) | the 20-second per-transition wall is wall-clock. This laptop finishes inside it where a Big Red general-partition core did not. No record moves the other way: nothing that resolved on the cluster times out here. |
| 27 | `crisis: dead_end(addition_instead_of_multiplication)` there, `impasse(deformation_route_not_executable)` here, on `IM-G3-U1-L12`, `IM-G3-U1-L13`, `IM-G4-U3-L1` | a missing input in this checkout, named below. |
| 27 | `grade: 0` there, `grade: "unknown"` here, on the four `IM-GK-*` cells | `grade_of/2` (carried over verbatim) parses the grade out of the lesson code with `number_string(G, "K")`, which fails under SWI-Prolog 9.2.9 and falls to the predicate's own `unknown`. The cluster's interpreter returned 0. Nothing downstream reads `grade` from the landscape. |

### The missing input behind the 27 deformation records

`lesson_deformation_license/4` in `formal/learner/activity_contract.pl` needs a
`lesson_misconception/4` fact. For these three lessons that fact comes from
`explicit_lesson_misconception(..., add_instead_of_multiply, ...)` in
`curriculum/im/grade_3.pl` and `grade_4.pl`, whose body calls
`misconception_registry_entry/5`. That predicate reaches the citation through
`misconception_batch_path/1`, which globs `knowledge/misconceptions/*_batch_*.csv`
— and that directory holds no CSVs. The eighteen `*_batch_*.csv` files under
`umedcta-formalization/misconceptions/` were not carried across; the specific row
these lessons need is `40284` in `whole_number_batch_4.csv`. Without it
`misconception_batch_row_witness/2` yields zero rows, the licence is absent, and
the deformation route reports itself not executable. This is a vendoring gap in
the curriculum data, upstream of the sweep, and closing it is a decision about
what belongs in `knowledge/misconceptions/`, not a change to this pipeline.
