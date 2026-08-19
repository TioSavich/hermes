#!/usr/bin/env python3
"""The two collections the coverage grind gathers beside its admissions.

1. render_spec proposals — every non-null scene proposal the model offered,
   counted by gate class and dumped verbatim for later adjudication.
2. missing_doing census — the full (term, count) demand list: what the
   declined and admitted rows say the statements need that arithmetic
   steps cannot express. This is the demand list future capability work
   follows; nothing here is admitted by being counted.
"""
from __future__ import annotations

import argparse
import json
from collections import Counter
from pathlib import Path


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--ledger", required=True)
    ap.add_argument("--outdir", required=True)
    args = ap.parse_args()
    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)

    render_rows = []
    render_by_gate: Counter = Counter()
    missing: Counter = Counter()
    for line in open(args.ledger, encoding="utf-8"):
        row = json.loads(line)
        analysis = row.get("analysis") or {}
        spec = analysis.get("render_spec")
        if spec not in (None, "", "null"):
            render_by_gate[row.get("gate")] += 1
            render_rows.append({"record_id": row["record_id"],
                                "lesson": row.get("lesson"),
                                "grade": row.get("grade"),
                                "gate": row.get("gate"),
                                "render_spec": spec})
        doing = analysis.get("missing_doing")
        if isinstance(doing, str):
            term = " ".join(doing.lower().split())
            if term and term not in ("none", "null"):
                missing[term] += 1

    with open(outdir / "render_spec_proposals.jsonl", "w", encoding="utf-8") as f:
        for r in render_rows:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")
    with open(outdir / "missing_doing_census.json", "w", encoding="utf-8") as f:
        json.dump({"distinct_terms": len(missing),
                   "total_mentions": sum(missing.values()),
                   "census": dict(missing.most_common())}, f,
                  ensure_ascii=False, indent=1)

    print(f"render_spec proposals: {len(render_rows)} "
          f"by gate {dict(render_by_gate.most_common())}")
    print(f"missing_doing: {len(missing)} distinct terms, "
          f"{sum(missing.values())} mentions")
    for term, count in missing.most_common(25):
        print(f"  {count:4d}  {term}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
