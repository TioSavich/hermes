#!/usr/bin/env python3
"""Merge coverage-grind ledgers and re-run every gate locally.

On-node gate results are never trusted at collection: each admitted row's
stored analysis is replayed through the same deterministic gates against the
local targets file. A row that fails replay is demoted with the replay reason.
Dedupe keeps one row per record_id, preferring the higher oracle tier.
"""
from __future__ import annotations

import argparse
import importlib.util
import json
import sys
from collections import Counter
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location(
    "pvd", REPO / "scripts" / "coverage" / "propose_verify_driver.py")
pvd = importlib.util.module_from_spec(spec)
spec.loader.exec_module(pvd)

TIER_RANK = {"oracle_matched": 0, "oracle_mismatched_held": 1,
             "unoracled_executable": 2}


def replay(row: dict, target: dict) -> dict:
    analysis = row.get("analysis")
    if not analysis:
        return row
    statement = target["statement"]
    ok2, why2 = pvd.gate2_numeral_binding(analysis, statement)
    if not ok2:
        return {**row, "gate": "replay_G2", "reason": why2}
    ok3, why3, executed = pvd.gate3_execution(analysis)
    if not ok3:
        return {**row, "gate": "replay_G3", "reason": why3}
    ok4, why4 = pvd.gate4_ask(analysis, statement)
    if not ok4:
        return {**row, "gate": "replay_G4", "reason": why4}
    tier = pvd.gate5_oracle(analysis, target, executed)
    return {**row, "gate": "admitted", "tier": tier, "executed": executed}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--targets", required=True)
    ap.add_argument("--inputs", nargs="+", required=True)
    ap.add_argument("--output", required=True)
    args = ap.parse_args()

    targets = {}
    for line in open(args.targets, encoding="utf-8"):
        t = json.loads(line)
        targets[t["record_id"]] = t

    best: dict[str, dict] = {}
    dropped_dupes = 0
    for path in args.inputs:
        for line in open(path, encoding="utf-8"):
            try:
                row = json.loads(line)
            except json.JSONDecodeError:
                continue
            rid = row.get("record_id")
            if rid not in targets:
                continue
            row["collected_from"] = str(path)
            if row.get("gate") == "admitted":
                row = replay(row, targets[rid])
            cur = best.get(rid)
            if cur is None:
                best[rid] = row
                continue
            dropped_dupes += 1
            cur_adm = cur.get("gate") == "admitted"
            new_adm = row.get("gate") == "admitted"
            if new_adm and not cur_adm:
                best[rid] = row
            elif new_adm and cur_adm:
                if TIER_RANK.get(row.get("tier"), 9) < TIER_RANK.get(cur.get("tier"), 9):
                    best[rid] = row

    counts: Counter = Counter()
    by_grade: dict[str, Counter] = {}
    with open(args.output, "w", encoding="utf-8") as out:
        for rid in sorted(best):
            row = best[rid]
            gate = row.get("gate")
            key = f"admitted:{row['tier']}" if gate == "admitted" else gate
            counts[key] += 1
            by_grade.setdefault(row.get("grade", "?"), Counter())[key] += 1
            out.write(json.dumps(row, ensure_ascii=False) + "\n")

    print(f"targets={len(targets)} merged={len(best)} dupes_resolved={dropped_dupes}")
    print("counts:", json.dumps(dict(counts.most_common()), indent=1))
    for g in sorted(by_grade):
        admitted = sum(v for k, v in by_grade[g].items() if k.startswith("admitted"))
        total = sum(by_grade[g].values())
        print(f"grade {g}: {admitted}/{total} admitted "
              f"{json.dumps(dict(by_grade[g].most_common(4)))}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
