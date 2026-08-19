#!/usr/bin/env python3
"""Merge the 2026-08-18 vision-wave shard(s) and re-run every gate locally.

Same discipline as collect_and_regate_recovery_wave.py: an on-node/on-process
gate result is never trusted at collection. Every admitted row's stored
analysis is replayed through evaluate_analysis() against the local targets
file -- nothing is served as a fact until it survives a second, independent
gate pass. Dedupe keeps one row per record_id, preferring admitted over not,
and among admitted rows preferring the higher-confidence tier (a
"_vision_grounded" or "_context_grounded" suffix ranks below its
statement-only counterpart at the same base oracle tier).
"""
from __future__ import annotations

import argparse
import importlib.util
import json
from collections import Counter
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location(
    "pvd", REPO / "scripts" / "coverage" / "propose_verify_driver.py")
pvd = importlib.util.module_from_spec(spec)
spec.loader.exec_module(pvd)

BASE_TIER_RANK = {"oracle_matched": 0, "oracle_mismatched_held": 1,
                  "unoracled_executable": 2}
CAPTION_SUFFIXES = ("_context_grounded", "_vision_grounded")


def tier_rank(tier: str | None) -> float:
    if tier is None:
        return 99
    base = tier
    suffixed = False
    for suf in CAPTION_SUFFIXES:
        if base.endswith(suf):
            base = base[: -len(suf)]
            suffixed = True
            break
    rank = BASE_TIER_RANK.get(base, 5)
    if suffixed:
        rank += 0.5
    return rank


def replay(row: dict, target: dict, swipl_bin: str, gate_script: str, root: str) -> dict:
    analysis = row.get("analysis")
    if not analysis:
        return {**row, "gate": "replay_no_analysis", "reason": "no_analysis_on_row"}
    mode = row.get("mode") or target.get("mode")
    statement = target["statement"]
    result = pvd.evaluate_analysis(mode, analysis, target, statement,
                                    swipl_bin=swipl_bin, gate_script=gate_script, root=root)
    if result is None:
        return {**row, "gate": "replay_unknown_mode", "reason": str(mode)}
    gate, reason, tier, executed, extra = result
    if gate == "admitted":
        return {**row, "gate": "admitted", "tier": tier, "executed": executed, **extra,
                "replayed": True}
    return {**row, "gate": f"replay_{gate}", "reason": reason, **extra, "replayed": True}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--targets", required=True)
    ap.add_argument("--inputs", nargs="+", required=True)
    ap.add_argument("--output", required=True)
    ap.add_argument("--swipl-bin", default="swipl")
    ap.add_argument("--render-gate-script",
                    default=str(REPO / "scripts" / "coverage" / "render_spec_gate.pl"))
    ap.add_argument("--root", default=str(REPO))
    args = ap.parse_args()

    targets = {}
    for line in open(args.targets, encoding="utf-8"):
        t = json.loads(line)
        targets[t["record_id"]] = t

    best: dict[str, dict] = {}
    dropped_dupes = 0
    unmatched_ids = 0
    for path in args.inputs:
        for line in open(path, encoding="utf-8"):
            line = line.strip()
            if not line:
                continue
            try:
                row = json.loads(line)
            except json.JSONDecodeError:
                continue
            rid = row.get("record_id")
            if rid not in targets:
                unmatched_ids += 1
                continue
            row["collected_from"] = str(path)
            if row.get("gate") == "admitted":
                row = replay(row, targets[rid], args.swipl_bin, args.render_gate_script, args.root)
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
                if tier_rank(row.get("tier")) < tier_rank(cur.get("tier")):
                    best[rid] = row

    counts: Counter = Counter()
    by_grade: dict[str, Counter] = {}
    by_tier_grade: dict[str, Counter] = {}
    by_class: dict[str, Counter] = {}
    with open(args.output, "w", encoding="utf-8") as out:
        for rid in sorted(best):
            row = best[rid]
            gate = row.get("gate")
            tier = row.get("tier")
            key = f"admitted:{tier}" if gate == "admitted" else gate
            counts[key] += 1
            grade = row.get("grade", "?")
            by_grade.setdefault(grade, Counter())[key] += 1
            if gate == "admitted":
                by_tier_grade.setdefault(tier, Counter())[grade] += 1
            decline_class = targets[rid].get("decline_class", "?")
            by_class.setdefault(decline_class, Counter())[key] += 1
            out.write(json.dumps(row, ensure_ascii=False) + "\n")

    print(f"targets={len(targets)} merged={len(best)} dupes_resolved={dropped_dupes} "
          f"unmatched_ids_in_shards={unmatched_ids}")
    print("counts overall:", json.dumps(dict(counts.most_common()), indent=1))
    for g in sorted(by_grade):
        admitted = sum(v for k, v in by_grade[g].items() if k.startswith("admitted"))
        total = sum(by_grade[g].values())
        print(f"grade {g}: {admitted}/{total} admitted "
              f"{json.dumps(dict(by_grade[g].most_common(6)))}")
    print("--- by decline_class ---")
    for c in sorted(by_class):
        admitted = sum(v for k, v in by_class[c].items() if k.startswith("admitted"))
        total = sum(by_class[c].values())
        print(f"class {c}: {admitted}/{total} admitted "
              f"{json.dumps(dict(by_class[c].most_common(6)))}")
    print("--- admitted rows, per tier, by grade ---")
    for tier in sorted(by_tier_grade):
        grade_counts = by_tier_grade[tier]
        total = sum(grade_counts.values())
        print(f"{tier}: total={total} {json.dumps(dict(sorted(grade_counts.items())))}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
