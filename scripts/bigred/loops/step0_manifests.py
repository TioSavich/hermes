#!/usr/bin/env python3
"""Step 0 for the Big Red connection loops: measure, then write the manifests.

Runs on the login node, touches no compute node, and makes no claim it has not
counted. Every number it prints comes from enumerating the live tree in this
checkout; nothing here carries an estimate forward.

TWO THINGS THIS SCRIPT REFUSES TO DO, and both refusals are the point.

  R1's pair filter has no default. The design defines the filter as "shared
  schema string AND shared crosswalk probe archetype", but this checkout
  carries no relation from an automaton family to an archetype; the closest
  derivation available (loop_driver:family_probe_archetype/2) drops four
  families entirely and severs addition from every other family on the shared
  integer-pair schema — which removes the cross-lineage comparisons R1 exists
  to make. Both readings are enumerable here and `--pair-filter` must name
  one. Run `--census` to see what each costs before choosing.

  R5 gets no manifest, because the corpus the design assigns it does not carry
  what the run needs. R5 asks which misconception machines reproduce a
  RECORDED WRONG ANSWER. The 6-8 harvest is a curriculum task harvest: each
  record carries the lesson excerpt, a prose description of the doing, and the
  numeric operands, and no answer of any kind. This script counts the corpus
  and reports the shortfall rather than shipping a manifest for a run that
  cannot be scored.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
DRIVER = ROOT / "scripts/bigred/loops/loop_driver.pl"
PATHS = ROOT / "paths.pl"
HARVEST_ROOT = ROOT / "hermes/app/runtime/experiments/g68_harvest"

PAIR_FILTERS = ("schema_only", "schema_and_archetype")

# A record can be scored for reproduction only if something in it records what
# the answer WAS. The names are read from the data rather than assumed: if the
# harvest ever grows one of these, this script starts producing a manifest
# instead of a refusal.
ANSWER_FIELDS = (
    "answer", "recorded_answer", "student_answer", "wrong_answer",
    "response_value", "given_answer", "result",
)


def swipl_lines(goal: str, timeout: int = 300) -> list[str]:
    """Run a goal against the driver and return its stdout lines."""
    completed = subprocess.run(
        ["swipl", "-q", "-l", str(PATHS), "-l", str(DRIVER), "-g", goal,
         "-t", "halt"],
        cwd=str(ROOT), text=True, capture_output=True, timeout=timeout,
        check=False,
    )
    if completed.returncode:
        raise SystemExit(
            f"step 0 query failed ({completed.returncode}): "
            f"{completed.stderr.strip()[:800]}"
        )
    return [line for line in completed.stdout.splitlines() if line.strip()]


def enumerate_pairs(pair_filter: str) -> list[tuple[str, str, str, str]]:
    goal = (
        "forall(loop_driver:pair(%s, machine(FA,KA), machine(FB,KB)), "
        "format('~w\\t~w\\t~w\\t~w~n', [FA,KA,FB,KB]))" % pair_filter
    )
    pairs = []
    for line in swipl_lines(goal):
        fields = line.split("\t")
        if len(fields) == 4:
            pairs.append(tuple(fields))
    return pairs


def schema_coverage() -> list[tuple[str, str, int, int]]:
    """(schema, status, authored points, machines) for every contract schema."""
    goal = (
        "forall(loop_driver:contract_schema(S), "
        "( loop_driver:grid_status(S, Status), "
        "  ( Status = instantiated(bounds(_, P)) -> true ; P = 0 ), "
        "  aggregate_all(count, loop_driver:machine_schema(_, S), M), "
        "  ( Status = instantiated(_) -> T = instantiated "
        "  ; T = uninstantiated ), "
        "  format('~w\\t~w\\t~w\\t~q~n', [T, P, M, S]) ))"
    )
    rows = []
    for line in swipl_lines(goal):
        fields = line.split("\t", 3)
        if len(fields) == 4:
            rows.append((fields[3], fields[0], int(fields[1]), int(fields[2])))
    return rows


def harvest_census(harvest_root: Path) -> dict:
    """Count the 6-8 harvest, and count what R5 would actually need."""
    census = {
        "root": str(harvest_root),
        "runs": [],
        "task_records": 0,
        "records_with_operands": 0,
        "records_with_answer": 0,
        "records_scorable": 0,
        "answer_fields_present": sorted(set()),
    }
    if not harvest_root.is_dir():
        census["error"] = "harvest root not found"
        return census
    seen_answer_fields: set[str] = set()
    for checkpoint_dir in sorted(harvest_root.glob("*/*/checkpoints")):
        run_records = 0
        for path in sorted(checkpoint_dir.glob("*.json")):
            try:
                record = json.loads(path.read_text(encoding="utf-8"))
            except (OSError, json.JSONDecodeError):
                continue
            for task in record.get("tasks") or []:
                run_records += 1
                census["task_records"] += 1
                operands = [
                    value for value in (task.get("numeric_operands") or [])
                    if str(value).strip()
                ]
                has_operands = len(operands) >= 2
                present = [f for f in ANSWER_FIELDS if task.get(f) not in (None, "")]
                seen_answer_fields.update(present)
                if has_operands:
                    census["records_with_operands"] += 1
                if present:
                    census["records_with_answer"] += 1
                if has_operands and present:
                    census["records_scorable"] += 1
        census["runs"].append({
            "run": str(checkpoint_dir.parent.relative_to(harvest_root)),
            "task_records": run_records,
        })
    census["answer_fields_present"] = sorted(seen_answer_fields)
    return census


def write_shards(pairs, output_dir: Path, per_task: int, budget: float,
                 input_timeout: float, max_witnesses: int) -> list[Path]:
    output_dir.mkdir(parents=True, exist_ok=True)
    for stale in output_dir.glob("r1_shard_*.jsonl"):
        stale.unlink()
    written = []
    for index in range(0, len(pairs), per_task):
        chunk = pairs[index:index + per_task]
        shard = output_dir / f"r1_shard_{index // per_task:04d}.jsonl"
        with shard.open("w", encoding="utf-8") as handle:
            for family_a, kind_a, family_b, kind_b in chunk:
                item = {
                    "run": "r1",
                    "key": f"r1:{family_a}/{kind_a}|{family_b}/{kind_b}",
                    "source": {"family": family_a, "kind": kind_a},
                    "target": {"family": family_b, "kind": kind_b},
                    "pair_budget_s": budget,
                    "input_timeout_s": input_timeout,
                    "max_witnesses": max_witnesses,
                }
                handle.write(json.dumps(item, sort_keys=True) + "\n")
        written.append(shard)
    return written


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pair-filter", choices=PAIR_FILTERS, default=None,
                        help="R1's pair filter; there is no default, see the "
                             "module docstring")
    parser.add_argument("--output-dir", type=Path,
                        default=ROOT / ".bigred-output/2026-08-08-loops-wave1",
                        help="where the shard manifests are written")
    parser.add_argument("--pairs-per-task", type=int, default=25)
    parser.add_argument("--pair-budget-s", type=float, default=600.0)
    parser.add_argument("--input-timeout-s", type=float, default=30.0)
    parser.add_argument("--max-witnesses", type=int, default=0,
                        help="0 keeps every separating input, as the design asks")
    parser.add_argument("--harvest-root", type=Path, default=HARVEST_ROOT)
    parser.add_argument("--census", action="store_true",
                        help="measure and print only; write nothing")
    arguments = parser.parse_args()

    print("== schema coverage ==", flush=True)
    coverage = schema_coverage()
    instantiated = [row for row in coverage if row[1] == "instantiated"]
    missing = [row for row in coverage if row[1] != "instantiated"]
    covered_machines = sum(row[3] for row in instantiated)
    missing_machines = sum(row[3] for row in missing)
    print(f"schemas with a grid plan : {len(instantiated)} "
          f"({covered_machines} machines)", flush=True)
    print(f"schemas with none        : {len(missing)} "
          f"({missing_machines} machines -> uninstantiated(schema))", flush=True)
    for schema, _, _, machines in missing:
        print(f"  uninstantiated ({machines} machine(s)): {schema[:96]}", flush=True)

    print("\n== pair census ==", flush=True)
    counts = {}
    for name in PAIR_FILTERS:
        counts[name] = len(enumerate_pairs(name))
        print(f"{name:22s}: {counts[name]} unordered pairs", flush=True)
    lost = counts["schema_only"] - counts["schema_and_archetype"]
    print(f"the archetype conjunct removes {lost} pairs "
          f"({lost / max(counts['schema_only'], 1):.0%})", flush=True)

    print("\n== R5 corpus census ==", flush=True)
    census = harvest_census(arguments.harvest_root)
    if census.get("error"):
        print(f"  {census['error']}: {census['root']}", flush=True)
    else:
        print(f"  runs                 : {len(census['runs'])}", flush=True)
        print(f"  task records         : {census['task_records']}", flush=True)
        print(f"  with >=2 operands    : {census['records_with_operands']}",
              flush=True)
        print(f"  with a recorded answer: {census['records_with_answer']}",
              flush=True)
        print(f"  scorable for R5      : {census['records_scorable']}", flush=True)
        print(f"  answer fields found  : "
              f"{census['answer_fields_present'] or 'none'}", flush=True)

    if arguments.census:
        return 0

    if census.get("records_scorable", 0) == 0:
        print("\nR5 manifest: NOT WRITTEN. The harvest records carry operands "
              "and no answer, so a reproduction census has nothing to score "
              "against. This is a corpus gap, not a script defect; R5 needs a "
              "corpus with recorded student answers before it can run.",
              flush=True)

    if arguments.pair_filter is None:
        print("\nR1 manifest: NOT WRITTEN. --pair-filter is unset and has no "
              "default. Pass schema_only or schema_and_archetype; the census "
              "above is what the choice costs.", flush=True)
        return 3

    pairs = enumerate_pairs(arguments.pair_filter)
    shards = write_shards(pairs, arguments.output_dir,
                          arguments.pairs_per_task, arguments.pair_budget_s,
                          arguments.input_timeout_s, arguments.max_witnesses)
    last = len(shards) - 1
    print(f"\nR1 manifest written under {arguments.output_dir}", flush=True)
    print(f"  filter {arguments.pair_filter}: {len(pairs)} pairs "
          f"across {len(shards)} shards at {arguments.pairs_per_task}/task",
          flush=True)
    print(f"  sbatch array range: 0-{last}", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
