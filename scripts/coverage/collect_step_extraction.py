#!/usr/bin/env python3
"""Collect the step-extraction grind's raw driver output into
step_extraction_ledger.jsonl.

Mirrors collect_and_regate_recovery_wave.py's discipline: an on-node gate
label is never trusted at collection. Every row's stored analysis is
replayed through propose_verify_driver.evaluate_step_extraction() against
the LOCAL targets file's statement text before anything is written as
extraction_verified -- the same module the driver itself called, run again
here so a corrupted or hand-edited raw row cannot inherit a stale verdict.

Output rows carry a clean, minimal schema:
  record_id, lesson, grade, family, status (extraction_verified | declined),
  reason (declines only, names the failing step), steps (survivors only --
  the model's own step list, each already independently re-executed True
  under step_verifier.verify_step), testimony.
"""
from __future__ import annotations

import argparse
import datetime as _dt
import importlib.util
import json
from collections import Counter
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
GRIND = REPO / "hermes" / "app" / "runtime" / "experiments" / "coverage_grind"

spec = importlib.util.spec_from_file_location(
    "pvd", REPO / "scripts" / "coverage" / "propose_verify_driver.py")
pvd = importlib.util.module_from_spec(spec)
spec.loader.exec_module(pvd)


def load_jsonl(path: Path) -> list[dict]:
    out = []
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            out.append(json.loads(line))
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--targets", default=str(GRIND / "step_extraction_targets.jsonl"))
    ap.add_argument("--inputs", nargs="+",
                     default=[str(GRIND / "step_extraction_raw.jsonl")])
    ap.add_argument("--output", default=str(GRIND / "step_extraction_ledger.jsonl"))
    args = ap.parse_args()

    targets = {t["record_id"]: t for t in load_jsonl(Path(args.targets))}

    # Every candidate row per record_id, across every input file (a later
    # retry shard -- e.g. the same rows re-run at a higher token budget
    # after a transport:truncated failure -- may sit alongside an earlier
    # attempt for the same id). Dedupe happens AFTER replay, preferring
    # extraction_verified over any decline, so a retry can recover a row
    # its first attempt lost, never the reverse.
    candidates: dict[str, list[dict]] = {}
    unmatched = 0
    for path in args.inputs:
        for row in load_jsonl(Path(path)):
            rid = row.get("record_id")
            if rid not in targets:
                unmatched += 1
                continue
            candidates.setdefault(rid, []).append(row)
    dupes = sum(len(v) - 1 for v in candidates.values())

    stamp = _dt.date.today().isoformat()
    status_counts: Counter = Counter()
    by_family: dict[str, Counter] = {}
    by_grade: dict[str, Counter] = {}
    out_rows = []

    def resolve_one(row: dict, statement: str) -> dict:
        """(status, reason, steps, testimony_source_row) for one candidate
        row, replayed locally through evaluate_step_extraction -- never the
        row's own on-driver gate label."""
        if row.get("gate") == "transport":
            return {"status": "declined", "reason": f"transport:{row.get('reason')}"}
        analysis = row.get("analysis")
        if not isinstance(analysis, dict):
            return {"status": "declined", "reason": "no_analysis_on_row"}
        gate, reason, _tier, executed, _extra = pvd.evaluate_step_extraction(
            analysis, statement)
        if gate == "admitted":
            return {"status": "extraction_verified", "steps": executed,
                    "n_steps": len(executed), "_row": row}
        return {"status": "declined", "reason": f"{gate}:{reason}"}

    for rid in sorted(candidates):
        target = targets[rid]
        statement = target["statement"]
        family = target.get("family")
        grade = target.get("grade")

        base = {
            "record_id": rid, "lesson": target.get("lesson"), "grade": grade,
            "family": family, "date": stamp,
        }

        resolved = [resolve_one(row, statement) for row in candidates[rid]]
        verified = [r for r in resolved if r["status"] == "extraction_verified"]
        chosen = verified[0] if verified else resolved[0]

        if chosen["status"] == "extraction_verified":
            src_row = chosen.pop("_row")
            base.update(
                status="extraction_verified", steps=chosen["steps"],
                n_steps=chosen["n_steps"],
                testimony={
                    "steps": "model-extracted gate-verified",
                    "model": (src_row.get("testimony") or {}).get("model"),
                    "backend": (src_row.get("testimony") or {}).get("backend"),
                    "date": (src_row.get("testimony") or {}).get("date", stamp),
                    "source": "step_extraction_ledger.jsonl",
                })
            status_counts["extraction_verified"] += 1
            by_family.setdefault(family, Counter())["extraction_verified"] += 1
            by_grade.setdefault(grade, Counter())["extraction_verified"] += 1
        else:
            base.update(status="declined", reason=chosen["reason"])
            status_counts["declined"] += 1
            by_family.setdefault(family, Counter())["declined"] += 1
            by_grade.setdefault(grade, Counter())["declined"] += 1
        out_rows.append(base)

    with open(args.output, "w", encoding="utf-8") as f:
        for r in out_rows:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")

    print(f"targets={len(targets)} collected={len(candidates)} dupes_dropped={dupes} "
          f"unmatched_ids_in_inputs={unmatched}")
    print(f"wrote {len(out_rows)} rows -> {args.output}")
    print("status:", dict(status_counts))
    print("by family:")
    for fam in sorted(by_family):
        c = by_family[fam]
        print(f"  {fam:28s} {dict(c)}")
    print("by grade:")
    for g in sorted(by_grade, key=lambda x: (len(str(x)), str(x))):
        c = by_grade[g]
        print(f"  grade {str(g):3s} {dict(c)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
