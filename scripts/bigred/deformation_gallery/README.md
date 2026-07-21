# Big Red deformation gallery

This package moves the all-lesson static render to an IU Big Red scratch
checkout. It does not submit a job, install software, or require credentials.
The owner supplies the allocation, email address, account hostname, and scratch
path.

## One-time preparation

On the local machine, copy the checkout to the owner's scratch directory. The
excludes keep local data, package managers, and prior generated output out of
the transfer.

```bash
export BIGRED_HOST='OWNER@bigred200.uits.iu.edu'
export BIGRED_DIR='/N/scratch/OWNER/hermes'
rsync -az --delete \
  --exclude='.git' --exclude='node_modules' --exclude='.venv' \
  --exclude='.bigred-output' --exclude='hermes/app/web/generated' \
  ./ "$BIGRED_HOST:$BIGRED_DIR/"
```

Big Red must already provide `swipl`, `python3`, and `node` through the
owner's environment. `job.slurm` follows the sibling job's `conda/25.3.0` and
`sqlite/3.50.3` module setup, then activates `HERMES_ENV` (default:
`umedcta`). Adjust that environment name only if the owner's existing Big Red
environment differs.

## Submit

Edit the two placeholders in `job.slurm`: `REPLACE_WITH_BIG_RED_ACCOUNT` and
`REPLACE_WITH_OWNER_EMAIL`. Then run:

```bash
ssh "$BIGRED_HOST"
cd "$BIGRED_DIR"
sbatch scripts/bigred/deformation_gallery/job.slurm
```

The job runs the lean deformation exporter for every charted lesson. A lesson
gets `chart.json`, `index.html`, one representative productive filmstrip, and
one representative filmstrip per admitted deformation kind (no more than 12
files per lesson). It also runs the notation-chart exporter by default; set
`INCLUDE_NOTATION_CHARTS=0` before `sbatch` to omit that optional tree.

Generated files land only in the scratch checkout at
`.bigred-output/task-75-deformation-gallery/`, with the two subtrees
`lesson_deformation_charts/` and `notation_lesson_charts/`.

## Collect

From the local Hermes checkout after the job completes:

```bash
export BIGRED_HOST='OWNER@bigred200.uits.iu.edu'
export BIGRED_DIR='/N/scratch/OWNER/hermes'
bash scripts/bigred/deformation_gallery/collect.sh
```

The collector rsyncs those trees into
`hermes/app/web/generated/lesson_deformation_charts/` and
`hermes/app/web/generated/notation_lesson_charts/`. It does not use `--delete`;
the controller decides which generated changes to stage and commit.

## Exemplar provenance

This package is shaped from the read-only sibling checkout:

- `scripts/bigred/iteration7/array.sbatch`: `general` partition, one CPU,
  modest memory, `SLURM_SUBMIT_DIR` checkout, Lmod fallback, `module purge`,
  `conda/25.3.0`, `sqlite/3.50.3`, and conda activation.
- `scripts/bigred/iteration7/push.sh`: rsync-based source upload with explicit
  exclusions for `.git`, data, node modules, and local job output.
- `scripts/bigred/iteration7/pull.sh`: rsync-based collection from scratch
  without remote execution from the local machine.
- `scripts/bigred/iteration7/submit.sh`: explicit `sbatch` submission from a
  scratch checkout after environment preparation.

The deformation gallery is a single job rather than Iteration 7's array because
the exporter already batches lesson charts through one SWI-Prolog process. The
account and email are intentionally not copied from the sibling exemplar.
