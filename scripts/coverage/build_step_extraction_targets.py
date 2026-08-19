#!/usr/bin/env python3
"""Target list for the 2026-08-18 targeted step-extraction grind.

The family-form lane (instantiate_explanations.py) already tried, for
every a_operation_justify / b_comparison / d_strategy_explanation row, to
find a step in merged_admitted_ledger.jsonl or recovery_wave_ledger.jsonl
that step_verifier.py can independently re-execute. 688 rows found none
and declined with reason no_verified_grounding -- the row's OWN prior
analysis carried no step step_verifier recognizes and reproduces, whether
because the model never proposed one, or proposed one under an operation
name step_verifier's vocabulary does not cover.

This script does not re-read those prior analyses. It builds one target
per declined record_id, joined to its own statement text, for a FRESH
extraction pass whose prompt is written to fit step_verifier's vocabulary.

Statement join: uncovered_targets.jsonl, keyed by record_id -- the same
file the family-form lane itself joined against (explanation_families_summary.json
records this as its join). All 688 declined record_ids are present there
(verified by assertion below); no corpus-store fallback was needed for
this batch.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
GRIND = REPO / "hermes" / "app" / "runtime" / "experiments" / "coverage_grind"


def load_jsonl(path: Path) -> list[dict]:
    return [json.loads(l) for l in open(path, encoding="utf-8") if l.strip()]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--explanation-ledger", default=str(GRIND / "explanation_ledger.jsonl"))
    ap.add_argument("--uncovered-targets", default=str(GRIND / "uncovered_targets.jsonl"))
    ap.add_argument("--families-summary", default=str(GRIND / "explanation_families_summary.json"))
    ap.add_argument("--out", default=str(GRIND / "step_extraction_targets.jsonl"))
    args = ap.parse_args()

    declined = [r for r in load_jsonl(Path(args.explanation_ledger))
                if r.get("status") == "declined" and r.get("reason") == "no_verified_grounding"]

    uncovered_by_id = {r["record_id"]: r for r in load_jsonl(Path(args.uncovered_targets))}

    families_summary = json.loads(Path(args.families_summary).read_text(encoding="utf-8"))
    label_by_family = {f["family"]: f["label"] for f in families_summary["families"]}

    missing = [r["record_id"] for r in declined if r["record_id"] not in uncovered_by_id]
    if missing:
        raise SystemExit(
            f"{len(missing)} declined record_id(s) absent from uncovered_targets.jsonl "
            f"(corpus-store fallback needed, not implemented in this build): "
            f"{missing[:10]}")

    rows_out = []
    for row in declined:
        rid = row["record_id"]
        src = uncovered_by_id[rid]
        rows_out.append({
            "record_id": rid,
            "lesson": row.get("lesson") or src.get("lesson"),
            "grade": row.get("grade") or src.get("grade"),
            "mode": "step_extraction",
            "statement": src["statement"],
            "family": row.get("family"),
            "family_label": label_by_family.get(row.get("family")),
            "prior_decline_detail": row.get("detail"),
        })

    out_path = Path(args.out)
    with open(out_path, "w", encoding="utf-8") as f:
        for r in rows_out:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")

    fam_ct: dict[str, int] = {}
    for r in rows_out:
        fam_ct[r["family"]] = fam_ct.get(r["family"], 0) + 1
    print(f"wrote {len(rows_out)} rows -> {out_path}")
    print(f"by family: {fam_ct}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
