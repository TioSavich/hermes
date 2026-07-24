# Checkpointed field-context rebuild on Big Red

This directory runs one Slurm array task per grade band. Each task starts one
SWI-Prolog process with eight worker threads. Every completed lesson is written
atomically to the shared partial directory, so a timeout or cancellation keeps
finished work. A resumed task validates and skips its existing lesson partials.
Failures remain explicit lesson entries and are merged with successful entries.

No compute-node network access is required. The array does not replace
`curriculum/im/generated/field_context_cache.json`; collection, merge,
drift-check, and replacement remain controller steps.

## Configure and submit

Replace `REPLACE_WITH_BIG_RED_ACCOUNT` and `REPLACE_WITH_OWNER_EMAIL` in
`job.slurm`. Submit from the scratch checkout root. Pre-create the secondary
log directory before `sbatch`; the job also creates it before environment setup
and streams an unbuffered task log there.

```bash
mkdir -p scripts/bigred/field_context/work/logs
sbatch scripts/bigred/field_context/job.slurm
```

The default array is `0-2`, mapped to K-2, 3-5, and 6-8. All tasks share an
18-hour Slurm wall because a single array declaration cannot assign a distinct
wall to each element.

The observed runtime is strongly grade-dependent: the first 450 lessons took
about 97 minutes, while the remaining 863 did not finish in the next 8.4 hours.
Use these initial walls, then revise them from checkpoint timestamps:

- K-2: 4 hours. This band has 437 lessons and fits the observed early-lesson
  region with more than a twofold margin.
- 3-5: 12 hours. Middle-grade lessons need a separate allowance rather than an
  extrapolation from the first 450.
- 6-8: 18 hours. This is the slowest band and sets the default array wall.

For separate scheduler allocations with those walls, override the array and
time at submission:

```bash
sbatch --array=0 --time=04:00:00 scripts/bigred/field_context/job.slurm
sbatch --array=1 --time=12:00:00 scripts/bigred/field_context/job.slurm
sbatch --array=2 --time=18:00:00 scripts/bigred/field_context/job.slurm
```

Rerun the same command after a timeout or cancellation. `--resume` skips valid
partials and computes only missing lessons.

Two per-lesson bounds apply. The in-Prolog 120-second limit
(`call_with_time_limit/2`) is an asynchronous alarm; it cannot preempt a lesson
whose time is spent inside native string and clause-scan builtins (the topic
evidence over `curriculum/im/lesson_monitoring.pl` standard anchors), which is
how a wedged lesson previously held a worker past every in-Prolog wall. The
builder therefore also enforces an external wall, `--lesson-timeout` (default 600
seconds, overridable through `FIELD_CONTEXT_LESSON_TIMEOUT`). If a batch produces
no completed lesson within that window, Python terminates it, resumes from the
atomic partials, and — once no concurrency makes progress — drops to one worker
to isolate the single stalled lesson and record it as an explicit error before
continuing. Explicit error rows are preserved evidence of a failed computation,
never permission to omit the lesson; recompute them later with `--retry-errors`.

## Collect and merge

Collect `.bigred-output/field-context/partials/` without deleting the remote
copy. From the local checkout, point the merge helper at the collected
directory:

```bash
bash scripts/bigred/field_context/merge.sh \
  /path/to/collected/partials \
  .bigred-output/field-context/field_context_cache.json
```

The helper requires the complete coverage inventory and refuses an incomplete
or unexpected partial set. It writes outside the canonical cache location.
Run it twice against the same partial directory and compare SHA-256 digests if
transport integrity is in doubt; sorted lesson keys and stable JSON formatting
make the bytes deterministic.

After inspecting the merged artifact, the controller performs the one-file
replacement of `curriculum/im/generated/field_context_cache.json` and runs:

```bash
python3 scripts/checks/field_context_cache.py
```

Do not weaken that drift check. An explicit error entry is preserved evidence
of a failed lesson computation, not permission to omit the lesson.
