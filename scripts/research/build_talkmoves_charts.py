#!/usr/bin/env python3
"""Fold the local talk-move x PML alignment tables into one tracked
derived-counts artifact for the discussions page.

Inputs are the gitignored per-run alignment files
`scripts/research/talkmoves_rerun_out/lesson_run*/tm_*_talkmoves_alignment.md`.
Each holds markdown count tables computed locally AFTER a model run; the
TalkMoves gold labels never entered any prompt. Only those counts cross
into the artifact -- no transcript text, no utterances, no labels beyond
the coding scheme's own move names.

When the same transcript appears in several run directories the newest
file wins, and every table records which run it came from.

If no input exists on this machine the builder warns on stderr and exits
nonzero WITHOUT writing -- an absent artifact stays absent rather than
becoming a silent empty one.

License boundary: TalkMoves (Sumner lab) is CC BY-NC-SA 4.0; the standing
treatment in this repo is derived counts in the tree, transcripts out.
"""

from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
RUN_ROOT = REPO / "scripts/research/talkmoves_rerun_out"
OUT_DIR = REPO / "hermes/app/web/generated/talkmoves_charts"
OUT_PATH = OUT_DIR / "alignment_counts.json"

OPERATORS = ["comp_nec", "comp_poss", "exp_nec", "exp_poss"]


def parse_tables(text: str) -> list[dict]:
    """Parse every `## title` + markdown table pair into a table record."""
    tables = []
    section = None
    lines = text.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        if line.startswith("## "):
            section = line[3:].strip()
            i += 1
            continue
        if section and line.startswith("|"):
            header = [c.strip() for c in line.strip("|").split("|")]
            i += 1  # separator row
            rows = []
            while i + 1 <= len(lines):
                i += 1
                if i >= len(lines):
                    break
                row_line = lines[i].strip()
                if not row_line.startswith("|"):
                    break
                cells = [c.strip() for c in row_line.strip("|").split("|")]
                if all(set(c) <= {"-", " ", ":"} for c in cells):
                    continue
                label = cells[0]
                counts = []
                for c in cells[1:]:
                    try:
                        counts.append(int(c))
                    except ValueError:
                        counts.append(None)
                rows.append({"label": label, "counts": counts})
            columns = header[1:]
            kind = "crosstab" if columns == OPERATORS else "distribution"
            tables.append(
                {"title": section, "kind": kind, "columns": columns, "rows": rows}
            )
            section = None
            continue
        i += 1
    return tables


def alignment_note(text: str) -> str | None:
    for line in text.splitlines():
        if line.startswith("Alignment check:"):
            return line.strip()
    return None


def main() -> int:
    inputs = sorted(RUN_ROOT.glob("lesson_run*/tm_*_talkmoves_alignment.md"))
    if not inputs:
        sys.stderr.write(
            "build_talkmoves_charts: no alignment inputs under "
            f"{RUN_ROOT} -- these are local, gitignored run outputs. "
            "Nothing was written.\n"
        )
        return 2

    # Newest file per transcript id wins.
    newest: dict[str, Path] = {}
    for path in inputs:
        m = re.match(r"(tm_\d+)_talkmoves_alignment\.md", path.name)
        if not m:
            continue
        tid = m.group(1)
        if tid not in newest or path.stat().st_mtime > newest[tid].stat().st_mtime:
            newest[tid] = path

    transcripts = []
    for tid in sorted(newest):
        path = newest[tid]
        run_dir = path.parent.name
        text = path.read_text(encoding="utf-8")
        tables = parse_tables(text)
        for t in tables:
            t["source_run"] = run_dir
        entry = {
            "transcript_id": tid,
            "source_run": run_dir,
            "source_sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
            "alignment_note": alignment_note(text),
            "tables": tables,
        }
        manifest = path.parent / "run_manifest.json"
        if manifest.exists():
            m = json.loads(manifest.read_text(encoding="utf-8"))
            entry["model"] = m.get("model")
            entry["lesson"] = m.get("lesson")
            entry["gold_labels_in_prompts"] = m.get("gold_labels_in_prompts")
        transcripts.append(entry)

    artifact = {
        "attribution": {
            "corpus": "TalkMoves (Sumner lab, CU Boulder)",
            "license": "CC BY-NC-SA 4.0",
            "treatment": "derived counts only; no transcript text, no utterances",
            "gold_labels": "never entered any model prompt; alignment computed "
            "locally after each run",
        },
        "builder": "scripts/research/build_talkmoves_charts.py",
        "operators": OPERATORS,
        "transcripts": transcripts,
    }

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text(
        json.dumps(artifact, indent=1, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    total_tables = sum(len(t["tables"]) for t in transcripts)
    print(
        f"build_talkmoves_charts: {len(transcripts)} transcript(s), "
        f"{total_tables} table(s) -> {OUT_PATH.relative_to(REPO)}"
    )
    for t in transcripts:
        for tab in t["tables"]:
            cells = sum(c for r in tab["rows"] for c in r["counts"] if c)
            print(
                f"  {t['transcript_id']} [{tab['source_run']}] {tab['title']}: "
                f"{len(tab['rows'])} rows, {cells} counted"
            )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
