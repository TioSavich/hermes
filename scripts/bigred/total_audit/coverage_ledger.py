#!/usr/bin/env python3
"""coverage_ledger.py — join the audit lanes into one ledger.

Inputs (all produced by earlier stages in the same OUTDIR):
  pl_census.jsonl     static term census (parse_census.pl)
  load_probe.jsonl    per-file fresh-load outcomes (load_probe.sh)
  closure.txt         absolute paths in source_file/1 after load_runtime/0
  cov_seg_*.dat       clause coverage segments (cov_worker.pl saves)
  http_results.jsonl  every page/file/route response (http_sweep.py)
  server_opens.jsonl  files the server opened, with timestamps (audit_boot.py)
  sweep_marker.json   boot/sweep timestamps for the startup/request split
  shipped.txt         repo-relative paths in the distribution manifest

Output: audit_ledger.json (per-file records) and audit_ledger.md (the
readable report). A row is COVERED when a coverage segment records its clause
entered at least once. Rows outside the load closure can never be covered by
the worker sweep; the ledger says which files those rows live in rather than
letting the denominator shrink.
"""
from __future__ import annotations

import argparse
import json
import re
from collections import defaultdict
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]

CL_RE = re.compile(r"^cl\((.+?),\d+,\d+,'([^']+)','[^']+':(\d+),.*,(\d+)\)\.$")
CS_RE = re.compile(r"^cs\((\d+),(\d+),(\d+)\)\.$")
# cs/4 records are per-call-site detail inside a clause; clause-level cs/3 is
# the row-coverage signal, so call sites are skipped deliberately.
CS_SITE_RE = re.compile(r"^cs\(\d+,\d+,\d+,\d+\)\.$")


def bucket_of(path: str) -> str:
    if path.startswith("scripts/"):
        return "scripts"
    if path.startswith("knowledge/strategies/abstraction/"):
        return "quarantine"
    if path.startswith("formal/learner/"):
        return "formal_learner"
    if path.startswith("third_party/"):
        return "third_party"
    if path.startswith("hermes/web/prolog/"):
        return "browser"
    return "fact_stores"


def load_jsonl(path: Path) -> list[dict]:
    rows = []
    if path.exists():
        for line in path.open():
            line = line.strip()
            if line:
                try:
                    rows.append(json.loads(line))
                except json.JSONDecodeError:
                    continue
    return rows


def relify(p: str) -> str | None:
    try:
        return str(Path(p).resolve().relative_to(REPO))
    except ValueError:
        return None


def parse_segments(outdir: Path):
    """Return (per-file per-pred covered clause counts, unparsed line count)."""
    covered: dict[str, dict[str, set]] = defaultdict(lambda: defaultdict(set))
    id_meta: dict[str, tuple[str, str, str]] = {}
    unparsed = 0
    for seg in sorted(outdir.glob("cov_seg_*.dat")):
        entered_ids: set[str] = set()
        pending: dict[str, tuple[str, str, str]] = {}
        for line in seg.open(encoding="utf-8", errors="replace"):
            line = line.rstrip()
            if line.startswith("cl("):
                m = CL_RE.match(line)
                if not m:
                    unparsed += 1
                    continue
                pi, file_abs, line_no, cid = m.groups()
                pred = pi.split(":", 1)[-1]
                rel = relify(file_abs)
                if rel:
                    pending[cid] = (rel, pred, line_no)
            elif line.startswith("cs("):
                m = CS_RE.match(line)
                if not m:
                    if not CS_SITE_RE.match(line):
                        unparsed += 1
                    continue
                cid, entered, _exited = m.groups()
                if int(entered) > 0:
                    entered_ids.add(cid)
        for cid, meta in pending.items():
            if cid in entered_ids:
                rel, pred, line_no = meta
                covered[rel][pred].add(line_no)
                id_meta[cid] = meta
    return covered, unparsed


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    args = ap.parse_args()
    outdir = Path(args.out)

    census = {r["path"]: r for r in load_jsonl(outdir / "pl_census.jsonl")}
    probe = {r["path"]: r for r in load_jsonl(outdir / "load_probe.jsonl")}
    closure: set[str] = set()
    cpath = outdir / "closure.txt"
    if cpath.exists():
        for line in cpath.open():
            rel = relify(line.strip()) if line.strip() else None
            if rel:
                closure.add(rel)
    shipped: set[str] = set()
    spath = outdir / "shipped.txt"
    if spath.exists():
        shipped = {l.strip() for l in spath.open() if l.strip()}

    covered, unparsed = parse_segments(outdir)

    marker = {}
    mpath = outdir / "sweep_marker.json"
    if mpath.exists():
        marker = json.loads(mpath.read_text())
    sweep_started = marker.get("sweep_started")
    opens = load_jsonl(outdir / "server_opens.jsonl")
    startup_reads = {o["path"] for o in opens
                     if sweep_started and o["first_ts"] < sweep_started}
    request_reads = {o["path"] for o in opens
                     if sweep_started and o["last_ts"] >= sweep_started}

    http = load_jsonl(outdir / "http_results.jsonl")
    http_bad = [r for r in http if r.get("status", 0) >= 500
                or r.get("status", 0) < 0]
    http_404 = [r for r in http if r.get("status") == 404]

    records = []
    for path, c in sorted(census.items()):
        cov_preds = covered.get(path, {})
        covered_rows = sum(len(v) for v in cov_preds.values())
        facts = c.get("facts", 0)
        rules = c.get("rules", 0)
        denom = facts + rules
        rec = {
            "path": path,
            "bucket": bucket_of(path),
            "terms": c.get("terms", 0),
            "facts": facts,
            "rules": rules,
            "parse_errors": c.get("parse_errors", 0),
            "in_closure": path in closure,
            "shipped": path in shipped,
            "load_status": probe.get(path, {}).get("status", "unprobed"),
            "covered_clauses": covered_rows,
            "clause_denominator": denom,
            "coverage_ratio": round(covered_rows / denom, 4) if denom else None,
            "python_read_at_request": path in request_reads,
            "python_read_at_startup": path in startup_reads,
        }
        records.append(rec)

    ledger = {
        "totals": {
            "files": len(records),
            "rows": sum(r["facts"] for r in records),
            "rows_in_closure": sum(r["facts"] for r in records if r["in_closure"]),
            "rows_covered": sum(r["covered_clauses"] for r in records),
            "files_load_error": sum(1 for r in records
                                    if r["load_status"] in ("load_error", "error",
                                                            "load_failed", "timeout")),
            "files_load_warnings": sum(1 for r in records
                                       if r["load_status"] == "warnings"),
            "cov_lines_unparsed": unparsed,
            "http_requests": len(http),
            "http_5xx_or_dead": len(http_bad),
            "http_404": len(http_404),
            "server_files_read_at_request": len(request_reads),
        },
        "files": records,
        "http_defects": http_bad[:200],
        "http_404": http_404[:500],
        "request_time_reads": sorted(request_reads),
    }
    (outdir / "audit_ledger.json").write_text(
        json.dumps(ledger, indent=1, ensure_ascii=False))

    by_bucket: dict[str, dict[str, int]] = defaultdict(lambda: defaultdict(int))
    for r in records:
        b = by_bucket[r["bucket"]]
        b["files"] += 1
        b["rows"] += r["facts"]
        b["covered"] += r["covered_clauses"]
        if r["in_closure"]:
            b["rows_in_closure"] += r["facts"]

    zero_touch = [r for r in records
                  if r["bucket"] == "fact_stores" and r["facts"] >= 50
                  and r["covered_clauses"] == 0
                  and not r["python_read_at_request"]]
    zero_touch.sort(key=lambda r: -r["facts"])

    lines = ["# Total audit ledger", ""]
    t = ledger["totals"]
    lines += [
        f"- files: {t['files']}; rows: {t['rows']:,} "
        f"({t['rows_in_closure']:,} in the load closure)",
        f"- rows covered by the op sweep: {t['rows_covered']:,}",
        f"- load probe: {t['files_load_error']} errors, "
        f"{t['files_load_warnings']} with warnings",
        f"- http: {t['http_requests']:,} requests; "
        f"{t['http_5xx_or_dead']} failed (5xx/dead); {t['http_404']} 404",
        f"- server read {t['server_files_read_at_request']} repo files at "
        f"request time",
        f"- coverage lines the parser could not read: {t['cov_lines_unparsed']}",
        "",
        "## Rows by bucket",
        "",
        "| bucket | files | rows | rows in closure | covered clauses |",
        "|---|---:|---:|---:|---:|",
    ]
    for b, v in sorted(by_bucket.items()):
        lines.append(f"| {b} | {v['files']} | {v['rows']:,} | "
                     f"{v['rows_in_closure']:,} | {v['covered']:,} |")
    lines += ["", "## Largest untouched fact stores "
              "(>=50 rows, zero clauses covered, not read by the server)", "",
              "| file | rows | in closure | shipped | load |",
              "|---|---:|---|---|---|"]
    for r in zero_touch[:40]:
        lines.append(f"| {r['path']} | {r['facts']:,} | {r['in_closure']} | "
                     f"{r['shipped']} | {r['load_status']} |")
    (outdir / "audit_ledger.md").write_text("\n".join(lines) + "\n")
    print(f"[ledger] {t['files']} files, {t['rows']:,} rows, "
          f"{t['rows_covered']:,} covered; report -> audit_ledger.md",
          flush=True)
    return 0


if __name__ == "__main__":
    main()
