#!/usr/bin/env python3
"""Array wrapper for the Big Red connection loops.

One shard manifest in, one checkpoint JSONL out, one Prolog subprocess per
item. The design this implements is
`.superpowers/sdd/task-2026-08-08-engineer-bigred-loops.md`; the four Big Red
laws it obeys are worth naming, because each one is here for a run that went
wrong without it.

  Law 0  Nothing here contacts the cluster or the network. The login-node
         single-item rehearsal happens before any sbatch, and it is judged by
         whether the artifact exists, never by an exit status.

  Law 1  Checkpoint per item, fsync per row, resume by key. A shard that dies
         at item 900 of 1,000 resumes at 901 and adds no duplicate rows.

  Law 2  The watchdog lives HERE, in Python, not in Prolog. A Prolog time
         limit cannot preempt a native builtin, so the only reliable kill is
         killing the process. The driver's own per-pair budget is the polite
         stop that usually fires first; this is the one that always fires.

  Law 3  flush=True on every progress line. Buffered progress on a dead job
         tells you nothing about where it died.

A timeout, a refusal, a spent budget and a crash are all RETAINED rows. The
run's product includes what it could not do, and a row that went missing
because the work failed is a silent zero — a claim wearing no evidence.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
DRIVER = ROOT / "scripts/bigred/loops/loop_driver.pl"
PATHS = ROOT / "paths.pl"

# Filled at authoring time, per the design's rule that a row never carries a
# blank consumer. A row nobody is going to read is a stalled input.
CONSUMERS = {
    "r1": (
        "scripts/research/build_automata_compendium.py:read_r1_atlas_rows"
        " + scripts/research/separation_coverage_audit.py"
    ),
    "r2": (
        "the G_walk crisis_release candidate queue (admission ceremony, L2 and"
        " L3 first) + the rung-map seam report + the stage-2 gap report"
    ),
}

REQUIRED_ROW_FIELDS = (
    "run",
    "candidate_type",
    "source",
    "target",
    "input",
    "evidence",
    "outcome",
    "consumer",
)


def item_key(item: dict) -> str:
    """The resume key. Taken from the manifest when it carries one."""
    if item.get("key"):
        return str(item["key"])
    source = item.get("source") or {}
    target = item.get("target") or {}
    return "{}:{}/{}|{}/{}".format(
        item.get("run", "?"),
        source.get("family", "?"),
        source.get("kind", "?"),
        target.get("family", "?"),
        target.get("kind", "?"),
    )


def read_manifest(path: Path) -> list[dict]:
    items = []
    with path.open(encoding="utf-8") as handle:
        for number, line in enumerate(handle, start=1):
            line = line.strip()
            if not line:
                continue
            try:
                items.append(json.loads(line))
            except json.JSONDecodeError as error:
                raise SystemExit(
                    f"{path}:{number}: manifest line is not JSON: {error}"
                ) from error
    return items


def completed_keys(path: Path) -> set[str]:
    """Keys already on disk. A truncated final line is dropped and redone."""
    if not path.is_file():
        return set()
    keys = set()
    with path.open(encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            try:
                row = json.loads(line)
            except json.JSONDecodeError:
                continue
            # An item can emit more than one row (R2 walks a pair once and reports
            # both directions), so resume keys on the ITEM, never on the row.
            if row.get("item_key"):
                keys.add(str(row["item_key"]))
            elif row.get("key"):
                keys.add(str(row["key"]))
    return keys


def append_row(path: Path, row: dict) -> None:
    """Append one row and put it on the platter before returning."""
    with path.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(row, sort_keys=True) + "\n")
        handle.flush()
        os.fsync(handle.fileno())


def fallback_row(item: dict, outcome: str, candidate_type: str,
                 note: str, elapsed_ms: int) -> dict:
    """An R1 row for an item whose Prolog run produced none."""
    run = str(item.get("run", "?"))
    source = item.get("source") or {}
    target = item.get("target") or {}
    return {
        "run": run,
        "candidate_type": candidate_type,
        "source": {"family": source.get("family"), "kind": source.get("kind")},
        "target": {"family": target.get("family"), "kind": target.get("kind")},
        "input": {"schema": item.get("schema"), "bounds": None, "points": 0},
        "evidence": {
            "kind": "separating_input",
            "source_outcome": note,
            "target_outcome": note,
            "elapsed_ms": elapsed_ms,
        },
        "outcome": outcome,
        "consumer": CONSUMERS.get(run, CONSUMERS["r1"]),
    }


def r2_failure_row(item: dict, outcome: str, candidate_type: str,
                   failure_class: str, note: str, elapsed_ms: int,
                   *, reverse: bool = False) -> dict:
    """One directed R2 row when the external process yields no census."""
    source = item.get("source") or {}
    target = item.get("target") or {}
    if reverse:
        source, target = target, source
        source_outcome = "not_walked"
        target_outcome = "not_walked"
        walk = "not_walked"
        reason = f"sibling_{failure_class}"
        row_outcome = "not_walked"
        row_candidate_type = (
            "sibling_timeout" if outcome == "timeout" else "sibling_failure"
        )
    else:
        source_outcome = note
        target_outcome = note
        walk = failure_class
        reason = failure_class
        row_outcome = outcome
        row_candidate_type = candidate_type
    return {
        "run": "r2",
        "candidate_type": row_candidate_type,
        "source": {"family": source.get("family"), "kind": source.get("kind")},
        "target": {"family": target.get("family"), "kind": target.get("kind")},
        "input": {"schema": item.get("schema"), "bounds": None, "points": 0},
        "evidence": {
            "kind": "failed_derivation",
            "source_outcome": source_outcome,
            "target_outcome": target_outcome,
            "elapsed_ms": elapsed_ms,
            "walked_points": 0,
            "released_count": 0,
            "released_witnesses": [],
            "witnesses_truncated": False,
            "released_validity_counts": {},
            "release_quality": "not_assessed",
            "receiver_incorrect_out_of_region": 0,
            "out_of_region_incorrect_witness": None,
            "license": {},
            "lens_flags": {
                "l1": False,
                "l2": False,
                "l3": False,
                "receiver_is_registered_deformation": None,
                "strong_released_points": 0,
                "clean_released_points": 0,
                "l3_kernel_half": (
                    "not assessed because the direction was not walked"
                ),
            },
            "crossing_actions": [],
            "walk": walk,
            "reason": reason,
        },
        "outcome": row_outcome,
        "candidate_lens": "unlensed",
        "consumer": (
            "the R2 closure accounting and backfill queue; the direction has "
            "no crisis-release judgment"
        ),
    }


def run_item(item: dict, watchdog_s: float) -> tuple[list[dict], str]:
    """Run one item in its own Prolog process. Returns (rows, disposition).

    An item yields one row for R1 and two for R2. Reading every row the driver
    writes, rather than the first, is what keeps R2's second direction from
    being silently dropped.
    """
    started = time.monotonic()
    command = [
        "swipl", "-q",
        "-l", str(PATHS),
        "-l", str(DRIVER),
        "-g", "loop_driver:main_item",
        "-t", "halt",
    ]
    process = subprocess.Popen(
        command,
        cwd=str(ROOT),
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    try:
        stdout, stderr = process.communicate(
            input=json.dumps(item) + "\n", timeout=watchdog_s
        )
    except subprocess.TimeoutExpired:
        process.kill()
        # Reap it, or the shard accumulates zombies for the whole wall clock.
        try:
            process.communicate(timeout=30)
        except subprocess.TimeoutExpired:
            pass
        elapsed_ms = round((time.monotonic() - started) * 1000)
        note = f"killed by the watchdog after {watchdog_s:g}s"
        if str(item.get("run")) == "r2" and item.get("target"):
            rows = [
                r2_failure_row(
                    item, "timeout", "watchdog_kill", "watchdog_timeout",
                    note, elapsed_ms
                ),
                r2_failure_row(
                    item, "timeout", "watchdog_kill", "watchdog_timeout",
                    note, elapsed_ms, reverse=True
                ),
            ]
        else:
            rows = [
                fallback_row(item, "timeout", "watchdog_kill", note, elapsed_ms)
            ]
        return rows, "timeout"

    elapsed_ms = round((time.monotonic() - started) * 1000)
    lines = [ln for ln in stdout.splitlines() if ln.strip().startswith("{")]
    if not lines:
        note = (stderr.strip() or "the driver wrote no row")[:400]
        if str(item.get("run")) == "r2" and item.get("target"):
            return (
                [
                    r2_failure_row(
                        item, "resource_error", "no_row", "no_row",
                        note, elapsed_ms
                    ),
                    r2_failure_row(
                        item, "resource_error", "no_row", "no_row",
                        note, elapsed_ms, reverse=True
                    ),
                ],
                "no_row",
            )
        return (
            [fallback_row(item, "resource_error", "no_row", note, elapsed_ms)],
            "no_row",
        )

    rows = []
    for line in lines:
        try:
            row = json.loads(line)
        except json.JSONDecodeError as error:
            if str(item.get("run")) == "r2" and item.get("target"):
                note = f"{error}"
                return (
                    [
                        r2_failure_row(
                            item, "resource_error", "malformed_row",
                            "malformed_row", note, elapsed_ms
                        ),
                        r2_failure_row(
                            item, "resource_error", "malformed_row",
                            "malformed_row", note, elapsed_ms, reverse=True
                        ),
                    ],
                    "malformed",
                )
            return (
                [fallback_row(item, "resource_error", "malformed_row",
                              f"{error}", elapsed_ms)],
                "malformed",
            )
        missing = [field for field in REQUIRED_ROW_FIELDS if field not in row]
        if missing:
            if str(item.get("run")) == "r2" and item.get("target"):
                note = "row lacked " + ", ".join(missing)
                return (
                    [
                        r2_failure_row(
                            item, "resource_error", "incomplete_row",
                            "incomplete_row", note, elapsed_ms
                        ),
                        r2_failure_row(
                            item, "resource_error", "incomplete_row",
                            "incomplete_row", note, elapsed_ms, reverse=True
                        ),
                    ],
                    "incomplete",
                )
            return (
                [fallback_row(item, "resource_error", "incomplete_row",
                              "row lacked " + ", ".join(missing), elapsed_ms)],
                "incomplete",
            )
        if not row.get("consumer"):
            row["consumer"] = CONSUMERS.get(str(row.get("run")), CONSUMERS["r1"])
        rows.append(row)
    dispositions = sorted({str(row.get("outcome", "?")) for row in rows})
    return rows, "+".join(dispositions)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", required=True, type=Path,
                        help="shard manifest, one JSON item per line")
    parser.add_argument("--output", required=True, type=Path,
                        help="checkpoint JSONL for this shard")
    parser.add_argument("--watchdog-s", type=float, default=720.0,
                        help="external kill for one item; keep it above the "
                             "item's own budget so the polite stop wins first")
    parser.add_argument("--limit", type=int, default=0,
                        help="stop after this many items (0 = the whole shard)")
    arguments = parser.parse_args()

    if not arguments.manifest.is_file():
        print(f"manifest not found: {arguments.manifest}", flush=True)
        return 2
    if not DRIVER.is_file():
        print(f"driver not found: {DRIVER}", flush=True)
        return 2

    arguments.output.parent.mkdir(parents=True, exist_ok=True)
    items = read_manifest(arguments.manifest)
    already = completed_keys(arguments.output)
    print(f"shard {arguments.manifest.name}: {len(items)} items, "
          f"{len(already)} already on disk", flush=True)

    written = 0
    tally: dict[str, int] = {}
    for number, item in enumerate(items, start=1):
        key = item_key(item)
        if key in already:
            continue
        if arguments.limit and written >= arguments.limit:
            print(f"stopping at --limit {arguments.limit}", flush=True)
            break
        rows, disposition = run_item(item, arguments.watchdog_s)
        for index, row in enumerate(rows):
            row["item_key"] = key
            source = row.get("source") or {}
            target = row.get("target") or {}
            row["key"] = (
                f"{key}#{source.get('family')}/{source.get('kind')}"
                f"->{target.get('family')}/{target.get('kind')}"
                if len(rows) > 1 else key
            )
            append_row(arguments.output, row)
        written += len(rows)
        tally[disposition] = tally.get(disposition, 0) + 1
        elapsed = rows[0].get("evidence", {}).get("elapsed_ms", 0) if rows else 0
        print(f"[{number}/{len(items)}] {key} -> {disposition} "
              f"({len(rows)} row(s), {elapsed} ms)", flush=True)

    summary = ", ".join(f"{name}={count}" for name, count in sorted(tally.items()))
    print(f"shard done: {written} rows written; {summary or 'nothing to do'}",
          flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
