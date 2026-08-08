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


def singleton_machines() -> list[tuple[str, str]]:
    """Machines whose schema string no other machine shares.

    R2's receiver set is every machine sharing the EXACT schema string, so a
    singleton has no receiver at all. These are recorded as
    uninstantiated(no_receiver) rather than left out: a schema with one
    machine names a missing receiver, which is authoring work, and dropping
    the row would hide it.
    """
    goal = (
        "forall(( loop_driver:contracted_machine(machine(F,K)), "
        "  loop_driver:machine_schema(machine(F,K), S), "
        "  aggregate_all(count, loop_driver:machine_schema(_, S), 1) ), "
        "format('~w\\t~w~n', [F,K]))"
    )
    machines = []
    for line in swipl_lines(goal):
        fields = line.split("\t")
        if len(fields) == 2:
            machines.append((fields[0], fields[1]))
    return machines


def measured_pair_cost(collection: Path | None) -> dict[tuple[str, ...], int]:
    """Per-pair wall time from a completed R1 collection.

    R1 measured what each pair costs, and the spread is wide: addition pairs
    finish in seconds, multiplication pairs spend the whole budget. Dealing
    the expensive pairs across shards instead of letting them clump is the
    difference between a shard that finishes and a shard that is cut off at
    the wall.
    """
    costs: dict[tuple[str, ...], int] = {}
    if collection is None or not collection.is_dir():
        return costs
    for path in sorted(collection.rglob("*.jsonl")):
        for line in path.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if not line:
                continue
            try:
                row = json.loads(line)
            except json.JSONDecodeError:
                continue
            source = row.get("source") or {}
            target = row.get("target") or {}
            key = tuple(sorted([
                f"{source.get('family')}/{source.get('kind')}",
                f"{target.get('family')}/{target.get('kind')}",
            ]))
            elapsed = int((row.get("evidence") or {}).get("elapsed_ms") or 0)
            costs[key] = max(costs.get(key, 0), elapsed)
    return costs


def interleave_by_cost(pairs, costs, shard_count: int) -> list[list]:
    """Deal pairs into shards most-expensive-first, round robin.

    Round robin over a cost-ordered list puts one of the worst pairs in each
    shard before any shard gets a second, so no shard collects the tail.
    """
    ordered = sorted(
        pairs,
        key=lambda pair: -costs.get(
            tuple(sorted([f"{pair[0]}/{pair[1]}", f"{pair[2]}/{pair[3]}"])), 0
        ),
    )
    shards: list[list] = [[] for _ in range(max(shard_count, 1))]
    for index, pair in enumerate(ordered):
        shards[index % len(shards)].append(pair)
    return shards


def write_r2_shards(pairs, singletons, output_dir: Path, per_task: int,
                    budget: float, input_timeout: float, max_witnesses: int,
                    costs) -> list[Path]:
    output_dir.mkdir(parents=True, exist_ok=True)
    for stale in output_dir.glob("r2_shard_*.jsonl"):
        stale.unlink()
    shard_count = max(1, -(-len(pairs) // per_task))
    buckets = interleave_by_cost(pairs, costs, shard_count)

    # The no-receiver rows cost nothing to produce; they ride along evenly.
    for index, (family, kind) in enumerate(singletons):
        buckets[index % len(buckets)].append(("__singleton__", family, kind, ""))

    written = []
    for number, bucket in enumerate(buckets):
        shard = output_dir / f"r2_shard_{number:04d}.jsonl"
        with shard.open("w", encoding="utf-8") as handle:
            for entry in bucket:
                if entry[0] == "__singleton__":
                    _, family, kind, _ = entry
                    item = {
                        "run": "r2",
                        "key": f"r2:{family}/{kind}|no_receiver",
                        "source": {"family": family, "kind": kind},
                        "no_receiver": True,
                    }
                else:
                    family_a, kind_a, family_b, kind_b = entry
                    item = {
                        "run": "r2",
                        "key": f"r2:{family_a}/{kind_a}|{family_b}/{kind_b}",
                        "source": {"family": family_a, "kind": kind_a},
                        "target": {"family": family_b, "kind": kind_b},
                        "pair_budget_s": budget,
                        "input_timeout_s": input_timeout,
                        "max_witnesses": max_witnesses,
                    }
                handle.write(json.dumps(item, sort_keys=True) + "\n")
        written.append(shard)
    return written


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


def emit_r2(arguments) -> int:
    """R2's manifest: the R1 pair list, replayed with per-side retention.

    R2's filter is schema-only, ruled after R1. It needs no --pair-filter of
    its own: it replays exactly the pairs R1 walked, because the asymmetry it
    is measuring is the one R1's joint refusal count could not keep.
    """
    print("== R2 directed-replay manifest ==", flush=True)
    pairs = enumerate_pairs("schema_only")
    singletons = singleton_machines()
    costs = measured_pair_cost(arguments.r1_collection)

    print(f"unordered pairs (schema-only)  : {len(pairs)}", flush=True)
    print(f"directed rows they emit        : {2 * len(pairs)} "
          f"(one walk, two directions)", flush=True)
    print(f"machines with no receiver      : {len(singletons)} "
          f"-> uninstantiated(no_receiver)", flush=True)
    if costs:
        print(f"measured pair costs read       : {len(costs)} pairs from "
              f"{arguments.r1_collection}", flush=True)
    else:
        print(f"measured pair costs read       : none at "
              f"{arguments.r1_collection}; shards deal in enumeration order",
              flush=True)

    goal = ("findall(P, loop_driver:grid_plan(_, bounds(_, P), _), Ps), "
            "max_list(Ps, M), format('~w~n', [M])")
    largest = int(swipl_lines(goal)[0])
    ceiling = len(pairs) * largest
    print(f"point-evaluation ceiling       : {len(pairs)} walks x <={largest} "
          f"points = <={ceiling:,}", flush=True)

    if arguments.census:
        return 0

    shards = write_r2_shards(pairs, singletons, arguments.output_dir,
                             arguments.pairs_per_task, arguments.pair_budget_s,
                             arguments.input_timeout_s,
                             arguments.max_witnesses, costs)
    last = len(shards) - 1
    print(f"\nR2 manifest written under {arguments.output_dir}", flush=True)
    print(f"  {len(pairs)} pairs + {len(singletons)} no-receiver rows across "
          f"{len(shards)} shards at {arguments.pairs_per_task}/task, "
          f"cost-interleaved", flush=True)
    print(f"  sbatch array range: 0-{last}", flush=True)
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pair-filter", choices=PAIR_FILTERS, default=None,
                        help="R1's pair filter; there is no default, see the "
                             "module docstring")
    parser.add_argument("--output-dir", type=Path,
                        default=ROOT / ".bigred-output/2026-08-08-loops-wave1",
                        help="where the shard manifests are written")
    parser.add_argument("--pairs-per-task", type=int, default=None,
                        help="default 25 for R1, 12 for R2 (amendment B)")
    parser.add_argument("--pair-budget-s", type=float, default=600.0)
    parser.add_argument("--input-timeout-s", type=float, default=30.0)
    parser.add_argument("--max-witnesses", type=int, default=None,
                        help="default 0 for R1 (every separating input) and "
                             "200 for R2 (amendment B's cap, endpoints kept)")
    parser.add_argument("--harvest-root", type=Path, default=HARVEST_ROOT)
    parser.add_argument("--census", action="store_true",
                        help="measure and print only; write nothing")
    parser.add_argument("--r2", action="store_true",
                        help="write R2's directed-replay manifest instead of R1's")
    parser.add_argument("--r1-collection", type=Path,
                        default=ROOT / ".bigred-collected/2026-08-08-loops-wave1-r1/rows",
                        help="a completed R1 collection, read for measured "
                             "per-pair cost so shards interleave by it")
    arguments = parser.parse_args()

    # The two runs carry different defaults and neither should inherit the
    # other's: R1 keeps every separating input, R2 caps witnesses at 200.
    if arguments.r2:
        if arguments.pairs_per_task is None:
            arguments.pairs_per_task = 12
        if arguments.max_witnesses is None:
            arguments.max_witnesses = 200
        return emit_r2(arguments)
    if arguments.pairs_per_task is None:
        arguments.pairs_per_task = 25
    if arguments.max_witnesses is None:
        arguments.max_witnesses = 0

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
