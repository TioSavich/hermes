# Total audit run — every file, every row, tested by execution

This package tests the whole tracked Prolog corpus and the whole served
surface by running them, on Big Red, and reporting what actually happened.
There is no declaration layer: the denominator is `git ls-files`, the
expectations are derived from the artifacts themselves (dispatch_spec's typed
parameters, the worker's self-reported op list, the route registry, the
manifest), and the output is a ledger of findings, not a config that could
drift.

## What "tested" means, per lane

| lane | instrument | claim it earns |
|---|---|---|
| parse census | `parse_census.pl` reads every term of every tracked `.pl`, no directive executed | every row was read; syntax health per file |
| load probe | `load_probe.sh` loads each file into a fresh SWI-Prolog (skip list carries reasons; skipped files still get records) | the file loads clean / with warnings / not at all |
| op sweep | `sweep_driver.py` + `cov_worker.pl`: every worker op, keyed ops enumerated across harvested domains, under `library(prolog_coverage)` | per-clause: this row was entered N times, or never |
| HTTP sweep | `http_sweep.py` + `audit_boot.py`: every static and generated file served once, every registered route exercised, lesson-keyed routes enumerated; server file-opens recorded with timestamps | the surface answers; which repo files the server reads at startup vs at request time |
| model pass | `model_reader.py` on a node-local gemma-4-26B: bounded reading of stores the sweep never touched | a draft description + anomaly flags to adjudicate; never a verdict |
| ledger | `coverage_ledger.py` joins all of the above | one report: rows total, rows covered, untouched stores, load failures, HTTP defects |

Known limits, stated rather than hidden: the op sweep's coverage instrument
wraps the directly driven worker, not the server's own worker, so Prolog
coverage comes from the op lane and route health from the HTTP lane; run 1's
domain harvest will not reach every keyed row, and its untouched list is the
work list for run 2, not a verdict of deadness; a store outside the load
closure can never be covered by the sweep — the ledger names those rows
instead of shrinking the denominator. Unconsumed rows are stalled pipeline
input, never vestige: nothing here deletes anything.

## Operating

```
bash scripts/bigred/total_audit/launch.sh    # sync, law zero, submit A + B
bash scripts/bigred/total_audit/collect.sh   # after the jobs finish
```

`launch.sh` refuses to run without the ControlMaster channel and runs law
zero on the login node before submitting: coverage library present, census
on three files, one coverage segment through clean EOF, the SIGTERM save
check (the requeue design depends on it; a `TERM-SAVE-MISSING` result means
kills lose their segment and the driver's one requeue pass is doing real
work), and a server boot under the audit hook. Stage A resumes by
done-markers and per-item checkpoints; resubmitting after a timeout is safe.
The load probe executes directives, so it runs only in the disposable
scratch checkout, never against a working laptop repo.
