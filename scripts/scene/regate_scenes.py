#!/usr/bin/env python3
"""Re-run the gates and the typesetter over saved scenes. Never calls the model.

Two jobs. It lets the cluster return scene JSON and nothing else: typesetting and
rasterising happen here afterwards, where the fonts and the rasteriser live. And
it lets a landed run catch up with a changed schema or a changed typesetter,
which matters because both changed twice during this build -- once when a cell
carrying only a carry digit turned out to be a legitimate thing to say, and once
when a row narrower than its column labels turned out to be right-aligned rather
than wrong.

Reads each item's saved reply, re-derives the verdict, rewrites results.jsonl and
the SVGs. The replies are never re-requested, so a re-gate costs nothing but CPU.

    python3 regate_scenes.py --run out/bigred-<jobid>
"""
from __future__ import annotations

import argparse
import json
import shutil
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from gate_scene import gate                              # noqa: E402

try:
    from gate_svg import find_rasteriser
except ImportError:                                       # pragma: no cover
    def find_rasteriser():
        return None, "none"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--run", required=True)
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    here = Path(__file__).resolve().parent
    run_dir = Path(args.run) if Path(args.run).is_absolute() else here / args.run
    results_path = run_dir / "results.jsonl"
    if not results_path.exists():
        sys.exit(f"no results.jsonl under {run_dir}")

    ras_exe, ras_label = find_rasteriser()
    rows = [json.loads(l) for l in results_path.read_text().splitlines() if l.strip()]
    print(f"re-gating {len(rows)} items in {run_dir.name} "
          f"(rasteriser {ras_label})")

    changed, out_rows = 0, []
    for rec in rows:
        iid = rec["item_id"]
        raw_path = run_dir / rec.get("raw_path", f"raw/{iid}.txt")
        if not raw_path.exists():
            print(f"  {iid}: no saved reply, left as is")
            out_rows.append(rec)
            continue
        v = gate(raw_path.read_text(), rasteriser=ras_exe)
        was = rec.get("valid")
        if not args.dry_run:
            if v.get("svg"):
                (run_dir / "svg").mkdir(exist_ok=True)
                (run_dir / "svg" / f"{iid}.svg").write_text(v["svg"])
                rec["svg_path"] = f"svg/{iid}.svg"
            elif rec.get("svg_path"):
                stale = run_dir / rec["svg_path"]
                if stale.exists():
                    stale.unlink()
                rec["svg_path"] = None
            if v.get("scene") is not None:
                (run_dir / "scene").mkdir(exist_ok=True)
                (run_dir / "scene" / f"{iid}.json").write_text(
                    json.dumps(v["scene"], indent=1))
                rec["scene_path"] = f"scene/{iid}.json"
        rec["valid"] = v["valid"]
        rec["checks"] = v["checks"]
        rec["schema_error"] = v.get("schema_error")
        rec["needed_stripping"] = v["needed_stripping"]
        out_rows.append(rec)
        if was != v["valid"]:
            changed += 1
            print(f"  {iid}: {was} -> {v['valid']}"
                  + (f"  {v['schema_error'][:80]}" if v.get("schema_error") else ""))

    if not args.dry_run:
        backup = results_path.with_suffix(".jsonl.pre-regate")
        if not backup.exists():
            shutil.copy(results_path, backup)
        with results_path.open("w") as fh:
            for rec in out_rows:
                fh.write(json.dumps(rec) + "\n")

    n_valid = sum(1 for r in out_rows if r["valid"])
    print(f"{'would be' if args.dry_run else 'now'} valid {n_valid}/{len(out_rows)}"
          f"; {changed} verdict(s) changed")
    if not args.dry_run:
        print(f"  previous verdicts kept at {backup.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
