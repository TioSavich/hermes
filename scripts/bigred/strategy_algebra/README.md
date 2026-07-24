# Strategy algebra on Big Red

This job analyzes the 69 execution-observed strategy signatures in the
extracted transition tables. It minimizes each finite labeled transition
structure, compares all \(69 \times 68 / 2 = 2{,}346\) pairs, records shared
bounded subtraces and candidate rooted homomorphisms, and constructs bounded
synchronous products when action domains overlap.

Pedagogically distinct strategies are preserved even when minimized structures
coincide. A coincidence is a finding, never a merge. The output does not alter
the registry or transition tables.

## Local smoke

Only the three-signature smoke is intended for a laptop:

```bash
smoke_dir="$(mktemp -d)"
python3 scripts/bigred/strategy_algebra/analyze_strategy_algebra.py \
  --smoke --output "$smoke_dir"
```

The smoke reads the same extracted tables and selects three fixed fraction
signatures with overlapping actions. It minimizes them, performs the three
pairwise comparisons, exercises the product path, and writes
`strategy_algebra.json` plus `summary.md`.

Do not run full mode locally.

## Submit

The Slurm log directory must exist before `sbatch`; Slurm opens its output
files before the job body can create directories. From the Big Red scratch
checkout root:

```bash
mkdir -p scripts/bigred/strategy_algebra/work/logs
```

Replace `REPLACE_WITH_BIG_RED_ACCOUNT` and `REPLACE_WITH_OWNER_EMAIL` in
`job.slurm`, then submit:

```bash
sbatch scripts/bigred/strategy_algebra/job.slurm
```

The environment block uses `set +u` while lmod and conda initialize, then
restores `set -u`. The job runs offline and defaults to
`.bigred-output/strategy-algebra/`. `STRATEGY_ALGEBRA_OUTPUT` can select a
different scratch output directory.

The request is sized at one CPU, 4 GB, and 30 minutes. Expected wall time is
about 2 to 10 minutes. The fixed work is 69 minimizations followed by 2,346
pairwise comparisons; bounded subtrace enumeration, rooted homomorphism
checks, and products add data-dependent work. The 30-minute request leaves
room for conda startup and unusually overlapping action domains without
treating the upper bound as an expected runtime.

## Output

`strategy_algebra.json` contains:

- the minimized structure for each signature;
- structural-coincidence classes;
- one row for each of the 2,346 pairs and their shared subtraces;
- candidate action-preserving rooted homomorphisms;
- bounded synchronous products over shared actions.

`summary.md` gives counts and elapsed time. All coincidence, homomorphism, and
product records carry finding-only semantics under the preservation policy.
