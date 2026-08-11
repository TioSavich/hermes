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
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
DRIVER = ROOT / "scripts/bigred/loops/loop_driver.pl"
R3_DRIVER = ROOT / "scripts/bigred/loops/r3_driver.pl"
R4_DRIVER = ROOT / "scripts/bigred/loops/r4_driver.pl"
PATHS = ROOT / "paths.pl"
HARVEST_ROOT = ROOT / "hermes/app/runtime/experiments/g68_harvest"
R3_DEPTH1_COLLECTION = (
    ROOT / ".bigred-collected/2026-08-10-loops-wave3-r3/rows"
)

PAIR_FILTERS = ("schema_only", "schema_and_archetype")

# R3's shard arithmetic. The wall and the reserve are the sbatch request the
# design's wave table row 3 fixes; everything else follows from the run's own
# guards, and emit_r3 prints the division rather than asserting its answer.
R3_WALL_S = 4 * 60 * 60          # --time=4:00:00
R3_STARTUP_RESERVE_S = 30 * 60   # conda activate, swipl load, checkpoint writes
R3_WATCHDOG_MARGIN_S = 120       # the external kill sits above the polite stop
R3_REAP_GRACE_S = 30             # run_loop_array.py's wait on a killed child

# R4's shard arithmetic, the same shape as R3's. The wall is the wave table's
# row 4; the reserve is smaller than R3's because R4's per-item swipl load
# happens inside each item's own watchdog rather than once per shard, so what
# the reserve covers is the job's own setup — conda activate, the manifest
# read — and 10 minutes of a 2-hour wall is generous for that.
R4_WALL_S = 2 * 60 * 60
R4_STARTUP_RESERVE_S = 10 * 60
R4_WATCHDOG_MARGIN_S = 120
R4_REAP_GRACE_S = 30

# A record can be scored for reproduction only if something in it records what
# the answer WAS. The names are read from the data rather than assumed: if the
# harvest ever grows one of these, this script starts producing a manifest
# instead of a refusal.
ANSWER_FIELDS = (
    "answer", "recorded_answer", "student_answer", "wrong_answer",
    "response_value", "given_answer", "result",
)


def swipl_lines(goal: str, timeout: int = 300,
                extra_files: tuple[Path, ...] = ()) -> list[str]:
    """Run a goal against the driver and return its stdout lines."""
    loads: list[str] = []
    for path in (DRIVER,) + extra_files:
        loads += ["-l", str(path)]
    completed = subprocess.run(
        ["swipl", "-q", "-l", str(PATHS)] + loads + ["-g", goal, "-t", "halt"],
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


R3_DEPTH2_ELIGIBLE_TYPES = {
    "measured_resister",
    "measured_resister_thin_grid",
    "insufficient_computed_samples",
}
R3_DEPTH2_EXCLUSION_REASONS = {
    "kernel_dependency": "certified at depth 1",
    "kernel_dependency_thin_evidence": "certified at depth 1",
    "machine_never_computed": "unsearchable: machine never computed",
    "uninstantiated_schema": "unsearchable: schema has no authored grid",
}


def r3_depth2_collection_census(collection: Path) -> dict:
    """Read the depth-1 rows and account for every depth-2 decision.

    A duplicate machine or an unknown candidate type is a refusal, because
    either would make absence from the depth-2 manifest ambiguous.
    """
    if not collection.is_dir():
        raise SystemExit(f"R3 depth-1 collection not found: {collection}")
    rows: dict[str, dict] = {}
    counts: Counter[str] = Counter()
    for path in sorted(collection.glob("*.jsonl")):
        for number, line in enumerate(
                path.read_text(encoding="utf-8").splitlines(), start=1):
            line = line.strip()
            if not line:
                continue
            try:
                row = json.loads(line)
            except json.JSONDecodeError as error:
                raise SystemExit(
                    f"invalid R3 row at {path}:{number}: {error}"
                ) from error
            source = row.get("source") or {}
            key = f"{source.get('family')}/{source.get('kind')}"
            if key in rows:
                raise SystemExit(f"duplicate R3 depth-1 machine row: {key}")
            candidate_type = row.get("candidate_type")
            known = (candidate_type in R3_DEPTH2_ELIGIBLE_TYPES
                     or candidate_type in R3_DEPTH2_EXCLUSION_REASONS)
            if not known:
                raise SystemExit(
                    f"unclassified R3 depth-1 candidate_type for {key}: "
                    f"{candidate_type!r}"
                )
            rows[key] = row
            counts[candidate_type] += 1

    eligible = {
        key for key, row in rows.items()
        if row["candidate_type"] in R3_DEPTH2_ELIGIBLE_TYPES
    }
    excluded = {
        key: R3_DEPTH2_EXCLUSION_REASONS[row["candidate_type"]]
        for key, row in rows.items() if key not in eligible
    }
    return {
        "collection": collection,
        "rows": rows,
        "counts": counts,
        "eligible": eligible,
        "excluded": excluded,
    }


def print_r3_depth2_collection_census(census: dict) -> None:
    counts = census["counts"]
    resisters = (counts["measured_resister"]
                 + counts["measured_resister_thin_grid"])
    insufficient = counts["insufficient_computed_samples"]
    hits = (counts["kernel_dependency"]
            + counts["kernel_dependency_thin_evidence"])
    never = counts["machine_never_computed"]
    uninstantiated = counts["uninstantiated_schema"]
    print(f"depth-1 collection rows        : {len(census['rows'])} from "
          f"{census['collection']}", flush=True)
    print(f"  eligible resisters          : {resisters} -> searched at depth 2",
          flush=True)
    print(f"  eligible insufficient rows  : {insufficient} -> searched at depth 2",
          flush=True)
    print(f"  excluded depth-1 hits       : {hits} -> certified at depth 1",
          flush=True)
    print(f"  excluded never-computed     : {never} -> unsearchable; machine never "
          "computed", flush=True)
    print(f"  excluded uninstantiated     : {uninstantiated} -> unsearchable; schema "
          "has no authored grid", flush=True)
    accounted = len(census["eligible"]) + len(census["excluded"])
    print(f"  accounted                   : {accounted}/{len(census['rows'])}",
          flush=True)


def filter_r3_depth2_machines(machines: list[dict], census: dict) -> list[dict]:
    """Join the live machine census to the eligible depth-1 row keys."""
    by_key = {f"{row['family']}/{row['kind']}": row for row in machines}
    missing = sorted(census["eligible"] - set(by_key))
    if missing:
        raise SystemExit(
            "eligible depth-1 machines missing from the live tree: "
            + ", ".join(missing)
        )
    return [by_key[key] for key in sorted(census["eligible"])]


def machine_census(depth: int = 1) -> list[dict]:
    """One row per contracted machine: grid, input leaves, composition space.

    The composition count comes from r3_driver's own authored-language count
    on the first grid point of the machine's schema, so the manifest reports
    the space the run will actually walk rather than the design's estimate.
    """
    goal = (
        "r3_driver:default(max_leaves, MaxLeaves), "
        "forall(loop_driver:contracted_machine(machine(F,K)), "
        "( loop_driver:machine_schema(machine(F,K), S), "
        "  (   loop_driver:machine_grid_plan(machine(F,K), S, bounds(_, P), _), "
        "      once(loop_driver:machine_grid_input(machine(F,K), S, _, I)) "
        "  ->  T = instantiated, "
        "      r3_driver:input_leaves(I, MaxLeaves, "
        "                             leaves(Leaves, LeafCount, Others, _)), "
        f"      r3_driver:composition_count({depth}, Leaves, C) "
        "  ;   T = uninstantiated, P = 0, LeafCount = 0, Others = 0, C = 0 "
        "  ), "
        "  format('~w\\t~w\\t~w\\t~w\\t~w\\t~w\\t~w~n', "
        "         [F, K, T, P, LeafCount, Others, C]) ))"
    )
    rows = []
    for line in swipl_lines(goal, timeout=900, extra_files=(R3_DRIVER,)):
        fields = line.split("\t")
        if len(fields) != 7:
            continue
        rows.append({
            "family": fields[0],
            "kind": fields[1],
            "grid": fields[2],
            "points": int(fields[3]),
            "integer_leaves": int(fields[4]),
            "other_leaves": int(fields[5]),
            "compositions": int(fields[6]),
        })
    return rows


def measured_machine_cost(collection: Path | None) -> dict[str, int]:
    """Per-machine wall time read off a completed R1 or R2 collection.

    R3 runs one machine per item, so the pair costs R1 measured become a
    per-machine upper bound: the slowest walk a machine took part in. Dealing
    the slow machines across shards rather than letting them clump is the same
    reason R2's manifest interleaves.
    """
    costs: dict[str, int] = {}
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
            elapsed = int((row.get("evidence") or {}).get("elapsed_ms") or 0)
            for side in ("source", "target"):
                machine = row.get(side) or {}
                family = machine.get("family")
                kind = machine.get("kind")
                if not family or not kind:
                    continue
                key = f"{family}/{kind}"
                costs[key] = max(costs.get(key, 0), elapsed)
    return costs


def measured_r3_machine_cost(collection: Path | None) -> dict[str, int]:
    """Per-source-machine wall time from the completed R3 depth-1 rows."""
    costs: dict[str, int] = {}
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
            family = source.get("family")
            kind = source.get("kind")
            if not family or not kind:
                continue
            key = f"{family}/{kind}"
            elapsed = int((row.get("evidence") or {}).get("elapsed_ms") or 0)
            costs[key] = max(costs.get(key, 0), elapsed)
    return costs


def r3_machines_per_task(machine_budget: float) -> tuple[int, int, int]:
    """(machines per task, watchdog seconds, seconds each machine reserves)."""
    watchdog = int(machine_budget) + R3_WATCHDOG_MARGIN_S
    per_machine = watchdog + R3_REAP_GRACE_S
    usable = R3_WALL_S - R3_STARTUP_RESERVE_S
    return max(1, usable // per_machine), watchdog, per_machine


def write_r3_shards(machines, output_dir: Path, per_task: int, costs,
                    settings: dict) -> list[Path]:
    output_dir.mkdir(parents=True, exist_ok=True)
    for stale in output_dir.glob("r3_shard_*.jsonl"):
        stale.unlink()
    shard_count = max(1, -(-len(machines) // per_task))
    ordered = sorted(
        machines,
        key=lambda row: -costs.get(f"{row['family']}/{row['kind']}", 0),
    )
    buckets: list[list] = [[] for _ in range(shard_count)]
    for index, row in enumerate(ordered):
        buckets[index % shard_count].append(row)

    written = []
    for number, bucket in enumerate(buckets):
        shard = output_dir / f"r3_shard_{number:04d}.jsonl"
        with shard.open("w", encoding="utf-8") as handle:
            for row in bucket:
                item = {
                    "run": "r3",
                    "key": f"r3:{row['family']}/{row['kind']}",
                    "source": {"family": row["family"], "kind": row["kind"]},
                }
                item.update(settings)
                handle.write(json.dumps(item, sort_keys=True) + "\n")
        written.append(shard)
    return written


def emit_r3(arguments) -> int:
    """R3's manifest: one item per eligible machine at the requested depth.

    Depth 1 covers every contracted machine. Depth 2 joins the live census to
    the depth-1 collection and includes only resisters and insufficient-sample
    rows; every excluded class is printed with its reason before a manifest can
    be written.
    """
    depth = 2 if arguments.r3_depth2 else 1
    print(f"== R3 depth-{depth} kernel re-derivation manifest ==", flush=True)
    all_machines = machine_census(depth)
    if depth == 2:
        collection_census = r3_depth2_collection_census(
            arguments.r3_depth1_collection
        )
        print_r3_depth2_collection_census(collection_census)
        machines = filter_r3_depth2_machines(all_machines, collection_census)
    else:
        machines = all_machines
    gridded = [row for row in machines if row["grid"] == "instantiated"]
    ungridded = [row for row in machines if row["grid"] != "instantiated"]
    spaces = sorted(row["compositions"] for row in gridded)
    total_space = sum(spaces)
    median = spaces[len(spaces) // 2] if spaces else 0
    thin = [row for row in gridded
            if row["points"] < arguments.sample_count + arguments.verify_count]
    truncated = [row for row in gridded
                 if arguments.max_compositions > 0
                 and row["compositions"] > arguments.max_compositions]

    population_label = "eligible machines" if depth == 2 else "contracted machines"
    print(f"{population_label:<31}: {len(machines)}", flush=True)
    print(f"  with an authored grid        : {len(gridded)}", flush=True)
    print(f"  without one                  : {len(ungridded)} "
          f"-> uninstantiated(schema)", flush=True)
    print(f"depth-{depth} compositions per machine: median {median}, "
          f"max {spaces[-1] if spaces else 0}, total {total_space:,}",
          flush=True)
    if arguments.max_compositions > 0:
        print(f"  above --max-compositions {arguments.max_compositions}: "
              f"{len(truncated)} machine(s) -> search_truncated, never resister",
              flush=True)
    else:
        print("  composition cap             : none; the cumulative machine "
              "budget dominates", flush=True)
    print(f"grids under the design's {arguments.sample_count}+"
          f"{arguments.verify_count} inputs: {len(thin)} machine(s) "
          f"-> evidence_strength grid_limited", flush=True)

    per_task, watchdog, per_machine = r3_machines_per_task(
        arguments.machine_budget_s)
    if arguments.machines_per_task:
        per_task = arguments.machines_per_task
    shard_count = max(1, -(-len(machines) // per_task))
    print("\nshard arithmetic from the guards:", flush=True)
    print(f"  machine budget   {int(arguments.machine_budget_s)}s "
          f"(the design's 45 min)", flush=True)
    print(f"  + watchdog margin {R3_WATCHDOG_MARGIN_S}s "
          f"-> --watchdog-s {watchdog}", flush=True)
    print(f"  + reap grace      {R3_REAP_GRACE_S}s "
          f"-> {per_machine}s reserved per machine", flush=True)
    print(f"  wall {R3_WALL_S}s - startup reserve {R3_STARTUP_RESERVE_S}s "
          f"= {R3_WALL_S - R3_STARTUP_RESERVE_S}s usable", flush=True)
    print(f"  -> {(R3_WALL_S - R3_STARTUP_RESERVE_S) // per_machine} machines "
          f"fit a 4:00:00 shard; running {per_task}", flush=True)
    print(f"  -> {len(machines)} machines / {per_task} = {shard_count} shards, "
          f"sbatch array range 0-{shard_count - 1}", flush=True)

    if arguments.census:
        return 0

    cost_collection = (arguments.r3_depth1_collection
                       if depth == 2 else arguments.r1_collection)
    costs = (measured_r3_machine_cost(cost_collection)
             if depth == 2 else measured_machine_cost(cost_collection))
    if costs:
        print(f"measured machine costs read    : {len(costs)} machines from "
              f"{cost_collection}", flush=True)
    else:
        print(f"measured machine costs read    : none at "
              f"{cost_collection}; shards deal in enumeration order",
              flush=True)

    settings = {
        "depth": depth,
        "machine_budget_s": arguments.machine_budget_s,
        "composition_timeout_s": arguments.composition_timeout_s,
        "sample_count": arguments.sample_count,
        "verify_count": arguments.verify_count,
        "max_compositions": arguments.max_compositions,
    }
    shards = write_r3_shards(machines, arguments.output_dir, per_task, costs,
                             settings)
    last = len(shards) - 1
    print(f"\nR3 depth-{depth} manifest written under {arguments.output_dir}",
          flush=True)
    print(f"  {len(machines)} machines across {len(shards)} shards at "
          f"{per_task}/task, cost-interleaved", flush=True)
    print(f"  sbatch array range: 0-{last}", flush=True)
    print(f"  run_loop_array.py --driver scripts/bigred/loops/r3_driver.pl "
          f"--watchdog-s {watchdog}", flush=True)
    if shard_count != len(shards):
        print(f"  (shard count {len(shards)} differs from the predicted "
              f"{shard_count}; the written count is the one to submit)",
              flush=True)
    return 0


def bridge_census() -> dict:
    """R4's step 0, measured in one swipl pass.

    Two things are measured rather than read, and both are named on the way
    out. The output side of the design's "static schema filter" is a
    MEASUREMENT: the tree declares an input schema per machine and nothing at
    all about the result, so r4_driver runs each machine on the verified
    example its own contract row carries and classifies the result term through
    the authored carrier table. The input side is genuinely static — a join
    over schema strings.
    """
    goal = (
        "r4_driver:measure_signatures, "
        "forall(r4_driver:signature_memo(machine(F,K), Kind, _, _), "
        "  format('sig\\t~w\\t~w\\t~w~n', [F, K, Kind])), "
        "forall(r4_driver:unmeasured_source(machine(F,K), Reason), "
        "  format('unmeasured\\t~w\\t~w\\t~w~n', [F, K, Reason])), "
        "forall(r4_adapters:adapter_id(A), format('adapter\\t~w~n', [A])), "
        "r4_driver:bridge_manifest(Rows), "
        "forall(member(bridge(SF,SK,TF,TK,A,P), Rows), "
        "  format('item\\t~w\\t~w\\t~w\\t~w\\t~w\\t~w~n', [SF,SK,TF,TK,A,P]))"
    )
    census = {
        "signatures": [], "unmeasured": [], "adapters": [], "items": [],
    }
    for line in swipl_lines(goal, timeout=1800, extra_files=(R4_DRIVER,)):
        fields = line.split("\t")
        tag = fields[0]
        if tag == "sig" and len(fields) == 4:
            census["signatures"].append(tuple(fields[1:]))
        elif tag == "unmeasured" and len(fields) == 4:
            census["unmeasured"].append(tuple(fields[1:]))
        elif tag == "adapter" and len(fields) == 2:
            census["adapters"].append(fields[1])
        elif tag == "item" and len(fields) == 7:
            census["items"].append({
                "source": (fields[1], fields[2]),
                "target": (fields[3], fields[4]),
                "adapter": fields[5],
                "placements": int(fields[6]),
            })
    return census


def r4_items_per_task(pair_budget: float) -> tuple[int, int, int]:
    """(items per task, watchdog seconds, seconds each item reserves)."""
    watchdog = int(pair_budget) + R4_WATCHDOG_MARGIN_S
    per_item = watchdog + R4_REAP_GRACE_S
    usable = R4_WALL_S - R4_STARTUP_RESERVE_S
    return max(1, usable // per_item), watchdog, per_item


def write_r4_shards(items, output_dir: Path, per_task: int, costs,
                    settings: dict) -> list[Path]:
    output_dir.mkdir(parents=True, exist_ok=True)
    for stale in output_dir.glob("r4_shard_*.jsonl"):
        stale.unlink()
    shard_count = max(1, -(-len(items) // per_task))

    def cost_of(item) -> int:
        source = "{}/{}".format(*item["source"])
        target = "{}/{}".format(*item["target"])
        return max(costs.get(source, 0), costs.get(target, 0))

    ordered = sorted(items, key=lambda item: -cost_of(item))
    buckets: list[list] = [[] for _ in range(shard_count)]
    for index, item in enumerate(ordered):
        buckets[index % shard_count].append(item)

    written = []
    for number, bucket in enumerate(buckets):
        shard = output_dir / f"r4_shard_{number:04d}.jsonl"
        with shard.open("w", encoding="utf-8") as handle:
            for item in bucket:
                source_family, source_kind = item["source"]
                target_family, target_kind = item["target"]
                row = {
                    "run": "r4",
                    "key": (f"r4:{source_family}/{source_kind}"
                            f"|{target_family}/{target_kind}"
                            f"|{item['adapter']}"),
                    "source": {"family": source_family, "kind": source_kind},
                    "target": {"family": target_family, "kind": target_kind},
                    "adapter": item["adapter"],
                    "reachable_placements": item["placements"],
                }
                row.update(settings)
                handle.write(json.dumps(row, sort_keys=True) + "\n")
        written.append(shard)
    return written


def emit_r4(arguments) -> int:
    """R4's manifest: one item per (ordered pair, adapter) the filter admits.

    R4 needs no pair filter of R1's kind. Its filter is the contract-bridge
    one: can THIS adapter carry what the source machine measurably answers into
    a slot of the target machine's contract, with every other slot of that
    contract reachable from the schema's own literals or the source's own
    input? Every admitted combination gets an item and every attempted item
    produces a row.
    """
    print("== R4 contract-bridge adapter manifest ==", flush=True)
    census = bridge_census()
    signatures = census["signatures"]
    unmeasured = census["unmeasured"]
    items = census["items"]
    adapters = census["adapters"]

    by_kind: dict[str, int] = {}
    for _, _, kind in signatures:
        by_kind[kind] = by_kind.get(kind, 0) + 1
    never = [row for row in unmeasured if row[2] == "never_computed"]
    no_carrier = [row for row in unmeasured if row[2] == "no_carrier"]

    total_machines = len(signatures) + len(unmeasured)
    print(f"contracted machines             : {total_machines}", flush=True)
    print(f"  with a measured output carrier: {len(signatures)}", flush=True)
    for kind, count in sorted(by_kind.items(), key=lambda row: -row[1]):
        print(f"      {kind:26s}: {count}", flush=True)
    print(f"  computed, no authored carrier : {len(no_carrier)} "
          f"-> r4_adapters:uncarried/2 names the shapes", flush=True)
    print(f"  did not compute on their own verified example: {len(never)} "
          f"-> cannot be a bridge source", flush=True)

    pairs = {(item["source"], item["target"]) for item in items}
    print(f"\nstatically compatible ordered pairs : {len(pairs)} "
          f"(the design estimated <=5,000)", flush=True)
    print(f"(pair, adapter) items               : {len(items)}", flush=True)
    by_adapter: dict[str, int] = {name: 0 for name in adapters}
    for item in items:
        by_adapter[item["adapter"]] = by_adapter.get(item["adapter"], 0) + 1
    for name in adapters:
        count = by_adapter.get(name, 0)
        note = "  <- no compatible pair in this corpus" if count == 0 else ""
        print(f"    {name:36s}: {count}{note}", flush=True)
    runs = sum(min(item["placements"], arguments.max_placements)
               for item in items) * arguments.samples_per_bridge * 2
    print(f"upper bound on machine runs         : {runs:,} "
          f"({arguments.samples_per_bridge} samples x 2 machines x the "
          f"reachable placements)", flush=True)

    per_task, watchdog, per_item = r4_items_per_task(arguments.bridge_budget_s)
    if arguments.items_per_task:
        per_task = arguments.items_per_task
    shard_count = max(1, -(-len(items) // per_task))
    print(f"\nshard arithmetic from the guards:", flush=True)
    print(f"  (pair, adapter) budget {int(arguments.bridge_budget_s)}s "
          f"(the design's 5 min)", flush=True)
    print(f"  + watchdog margin {R4_WATCHDOG_MARGIN_S}s "
          f"-> --watchdog-s {watchdog}", flush=True)
    print(f"  + reap grace      {R4_REAP_GRACE_S}s "
          f"-> {per_item}s reserved per item", flush=True)
    print(f"  wall {R4_WALL_S}s - startup reserve {R4_STARTUP_RESERVE_S}s "
          f"= {R4_WALL_S - R4_STARTUP_RESERVE_S}s usable", flush=True)
    print(f"  -> {(R4_WALL_S - R4_STARTUP_RESERVE_S) // per_item} items fit a "
          f"2:00:00 shard; running {per_task}", flush=True)
    print(f"  -> {len(items)} items / {per_task} = {shard_count} shards, "
          f"sbatch array range 0-{shard_count - 1}", flush=True)
    wave_table_shards = max(1, -(-len(items) // 50))
    print(f"  the wave table's 50/task would be {wave_table_shards} shards "
          f"(0-{wave_table_shards - 1}) and reserve "
          f"{50 * per_item:,}s against a {R4_WALL_S}s wall; the guard "
          f"arithmetic above is what this manifest uses", flush=True)

    if arguments.census:
        return 0

    costs = measured_machine_cost(arguments.r1_collection)
    if costs:
        print(f"measured machine costs read     : {len(costs)} machines from "
              f"{arguments.r1_collection}", flush=True)
    else:
        print(f"measured machine costs read     : none at "
              f"{arguments.r1_collection}; shards deal in enumeration order",
              flush=True)

    settings = {
        "pair_budget_s": arguments.bridge_budget_s,
        "input_timeout_s": arguments.bridge_input_timeout_s,
        "sample_count": arguments.samples_per_bridge,
        "max_placements": arguments.max_placements,
    }
    shards = write_r4_shards(items, arguments.output_dir, per_task, costs,
                             settings)
    last = len(shards) - 1
    print(f"\nR4 manifest written under {arguments.output_dir}", flush=True)
    print(f"  {len(items)} items across {len(shards)} shards at "
          f"{per_task}/task, cost-interleaved", flush=True)
    print(f"  sbatch array range: 0-{last}", flush=True)
    print(f"  run_loop_array.py --driver scripts/bigred/loops/r4_driver.pl "
          f"--watchdog-s {watchdog}", flush=True)
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pair-filter", choices=PAIR_FILTERS, default=None,
                        help="R1's pair filter; there is no default, see the "
                             "module docstring")
    parser.add_argument("--output-dir", type=Path, default=None,
                        help="where the shard manifests are written; defaults "
                             "to the run's own wave directory (wave1 for R1, "
                             "wave2 for R2 — run_r2.slurm reads wave2, and the "
                             "2026-08-08 launch lost 64 shards to manifests "
                             "shipped into wave1)")
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
    parser.add_argument("--r3", action="store_true",
                        help="write R3's depth-1 kernel re-derivation manifest, "
                             "one item per machine")
    parser.add_argument("--r3-depth2", action="store_true",
                        help="write R3's depth-2 manifest from the eligible "
                             "depth-1 collection rows")
    parser.add_argument("--r4", action="store_true",
                        help="write R4's contract-bridge manifest, one item "
                             "per (ordered pair, adapter) the filter admits")
    parser.add_argument("--items-per-task", type=int, default=None,
                        help="R4 shard size; the default is computed from the "
                             "per-(pair, adapter) budget and the 2:00:00 wall "
                             "and printed")
    parser.add_argument("--bridge-budget-s", type=float, default=300.0,
                        help="R4's cumulative per-(pair, adapter) guard "
                             "(the design's 5 minutes). R1 and R2 keep their "
                             "own --pair-budget-s; the runs do not share one")
    parser.add_argument("--bridge-input-timeout-s", type=float, default=60.0,
                        help="R4's per-item inner bound (the design's 60 s)")
    parser.add_argument("--samples-per-bridge", type=int, default=20,
                        help="R4's sample inputs per (pair, adapter); the "
                             "design asks for 20")
    parser.add_argument("--max-placements", type=int, default=3,
                        help="R4's landing slots tried per item, in the "
                             "target contract's document order")
    parser.add_argument("--machines-per-task", type=int, default=None,
                        help="R3 shard size; the default is computed from the "
                             "machine budget and the 4:00:00 wall and printed")
    parser.add_argument("--machine-budget-s", type=float, default=2700.0,
                        help="R3's cumulative per-machine guard (45 minutes)")
    parser.add_argument("--composition-timeout-s", type=float, default=120.0,
                        help="R3's per-composition-sample inner bound")
    parser.add_argument("--sample-count", type=int, default=10,
                        help="R3's screen size")
    parser.add_argument("--verify-count", type=int, default=100,
                        help="R3's confirmation size, run before a row writes")
    parser.add_argument("--max-compositions", type=int, default=None,
                        help="R3's stop against a blown-up space; a machine "
                             "above it records search_truncated, not resister; "
                             "default 20000 at depth 1 and uncapped at depth 2")
    parser.add_argument("--r1-collection", type=Path,
                        default=ROOT / ".bigred-collected/2026-08-08-loops-wave1-r1/rows",
                        help="a completed R1 collection, read for measured "
                             "per-pair cost so shards interleave by it")
    parser.add_argument("--r3-depth1-collection", type=Path,
                        default=R3_DEPTH1_COLLECTION,
                        help="completed R3 depth-1 rows used to derive the "
                             "depth-2 population and measured shard costs")
    arguments = parser.parse_args()

    if arguments.r3 and arguments.r3_depth2:
        parser.error("choose --r3 or --r3-depth2, not both")

    # The three runs carry different defaults and none should inherit
    # another's: R1 keeps every separating input, R2 caps witnesses at 200, and
    # R3 has no witness list at all.
    if arguments.output_dir is None:
        if arguments.r4:
            arguments.output_dir = (
                ROOT / ".bigred-output/2026-08-10-loops-wave4-r4"
            )
        elif arguments.r3_depth2:
            arguments.output_dir = (
                ROOT / ".bigred-output/2026-08-10-loops-wave3-r3-depth2"
            )
        elif arguments.r3:
            arguments.output_dir = (
                ROOT / ".bigred-output/2026-08-10-loops-wave3-r3"
            )
        else:
            wave = "wave2" if arguments.r2 else "wave1"
            arguments.output_dir = (
                ROOT / f".bigred-output/2026-08-08-loops-{wave}"
            )
    if arguments.r4:
        return emit_r4(arguments)
    if arguments.r3 or arguments.r3_depth2:
        if arguments.max_compositions is None:
            arguments.max_compositions = 0 if arguments.r3_depth2 else 20000
        return emit_r3(arguments)
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
