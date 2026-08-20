#!/usr/bin/env python3
"""model_reader.py — a bounded model pass over the stores the sweep never
touched.

For each fact store the ledger marks untouched (zero covered clauses, not
read by the server at request time), a local llama-server model reads the
file header and a spread of sample rows and answers three bounded questions:
what the store holds (one sentence, product language), whether the sampled
rows are well formed, and whether one of a FIXED list of existing surfaces
could carry it. "none_fits" is an accepted answer; the model may not invent
features, endorse placement, or judge curriculum. Its output is a reading to
adjudicate, not a verdict.

Usage (llama-server already up):
  python3 scripts/bigred/total_audit/model_reader.py --out OUTDIR \
      [--llama http://127.0.0.1:8088] [--min-rows 20] [--max-stores 400]
"""
from __future__ import annotations

import argparse
import json
import time
from pathlib import Path

import requests

REPO = Path(__file__).resolve().parents[3]

SURFACES = [
    "lesson workspace (console lesson panel)",
    "monitoring chart",
    "questions page",
    "discussions review",
    "math tools (visualizers)",
    "MCP tool (frontier-model interface)",
    "research index (secondary entrance)",
]

PROMPT = """You are reading one Prolog fact store from a mathematics-teaching \
system. You get the file's opening lines and a sample of its rows.

Answer with ONLY a JSON object, no prose around it:
{{"holds": "<one sentence: what the rows record, in language a teacher or \
maintainer understands>",
 "well_formed": true/false,
 "anomalies": ["<anything malformed, duplicated, or self-contradicting in \
the sample; empty list if none>"],
 "candidate_surface": "<exactly one of: {surfaces}, or none_fits>",
 "reason": "<one sentence for the surface choice>"}}

Rules: describe only what the sample shows. Do not guess row counts. Do not \
propose new features. "none_fits" is a fully acceptable answer.

FILE: {path}
HEADER:
{header}

SAMPLE ROWS ({n} of {total}):
{rows}
"""


def sample_rows(path: Path, n: int = 12) -> tuple[str, str, int]:
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    header = "\n".join(lines[:25])
    fact_lines = [l for l in lines
                  if l and not l.startswith(("%", ":-", "?-"))][:200000]
    total = len(fact_lines)
    if total <= n:
        picks = fact_lines
    else:
        step = max(1, total // n)
        picks = fact_lines[::step][:n]
    return header, "\n".join(l[:300] for l in picks), total


def ask(llama: str, prompt: str, retries: int = 2) -> dict | None:
    for _ in range(retries + 1):
        try:
            r = requests.post(
                llama + "/v1/chat/completions",
                json={"messages": [{"role": "user", "content": prompt}],
                      "temperature": 0, "max_tokens": 500},
                timeout=300)
            r.raise_for_status()
            text = r.json()["choices"][0]["message"]["content"].strip()
            start, end = text.find("{"), text.rfind("}")
            if start >= 0 and end > start:
                return json.loads(text[start:end + 1])
        except (requests.RequestException, json.JSONDecodeError, KeyError):
            time.sleep(3)
    return None


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    ap.add_argument("--llama", default="http://127.0.0.1:8088")
    ap.add_argument("--min-rows", type=int, default=20)
    ap.add_argument("--max-stores", type=int, default=400)
    args = ap.parse_args()
    outdir = Path(args.out)

    ledger = json.loads((outdir / "audit_ledger.json").read_text())
    targets = [r for r in ledger["files"]
               if r["bucket"] in ("fact_stores", "quarantine")
               and r["facts"] >= args.min_rows
               and r["covered_clauses"] == 0
               and not r["python_read_at_request"]]
    targets.sort(key=lambda r: -r["facts"])
    if len(targets) > args.max_stores:
        print(f"[reader] TRUNCATED: {len(targets)} stores -> "
              f"{args.max_stores}", flush=True)
        targets = targets[: args.max_stores]

    out_path = outdir / "model_readings.jsonl"
    done = set()
    if out_path.exists():
        for line in out_path.open():
            try:
                done.add(json.loads(line)["path"])
            except (json.JSONDecodeError, KeyError):
                continue
    out = out_path.open("a")
    surfaces = "; ".join(SURFACES)

    for i, r in enumerate(targets):
        if r["path"] in done:
            continue
        p = REPO / r["path"]
        if not p.exists():
            continue
        header, rows, total = sample_rows(p)
        reply = ask(args.llama, PROMPT.format(
            surfaces=surfaces, path=r["path"], header=header,
            rows=rows, n=min(12, total), total=total))
        rec = {"path": r["path"], "rows": r["facts"],
               "in_closure": r["in_closure"], "shipped": r["shipped"],
               "reading": reply, "read_failed": reply is None}
        out.write(json.dumps(rec, ensure_ascii=False) + "\n")
        out.flush()
        print(f"[reader] {i + 1}/{len(targets)} {r['path']}"
              f"{' FAILED' if reply is None else ''}", flush=True)
    out.close()
    return 0


if __name__ == "__main__":
    main()
