#!/usr/bin/env python3
"""Assemble figure_context-mode regrind targets for the 2026-08-18 vision wave.

Reads vision_targets.jsonl (targeting) and vision_recovery_checkpoints.jsonl
(serving) and, for every one of the ~1,115 candidate statements, builds one
propose_verify_driver.py figure_context target row whose caption_context is
the STRUCTURED content recovered for THIS statement's own nearby images --
never the whole-lesson caption dump the earlier recovery wave used.

Every row carries "vision_grounded": true so propose_verify_driver.py's
figure_context tier logic tags an admitted row "_vision_grounded" rather than
reusing the earlier wave's "_context_grounded" suffix for a different
provenance claim (see propose_verify_driver.py's evaluate_analysis comment).

Output: hermes/app/runtime/experiments/coverage_grind/vision_wave_targets.jsonl
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
GRIND = REPO / "hermes" / "app" / "runtime" / "experiments" / "coverage_grind"

CAPTION_BYTE_BUDGET = 4000


def load_jsonl(path: Path) -> list[dict]:
    if not path.exists():
        return []
    return [json.loads(l) for l in open(path, encoding="utf-8") if l.strip()]


def group_key_str(lesson: str, refs: list[str]) -> str:
    return json.dumps([lesson, sorted(refs)], ensure_ascii=False)


def format_table_rows(rows: list) -> list[str]:
    """The vision model's raw pipe-serialized rows, normalized to one
    "| cell | cell |" string per row -- tolerant of a row that arrived as
    a bare string ("a | b") or as a list of cell strings."""
    out = []
    for row in rows:
        if isinstance(row, str):
            cells = [c.strip() for c in row.split("|")]
        elif isinstance(row, list):
            cells = [str(c).strip() for c in row]
        else:
            continue
        cells = [c for c in cells if c != ""]
        if cells:
            out.append(cells)
    return out


def markdown_flatten(rows: list[list[str]]) -> str | None:
    """Header + dash-separator + data rows, flattened to one space-joined
    line -- the exact convention serialized_table_reader_pilot.pl's fixtures
    use (docling flattens a table's line boundaries to spaces; the pipes
    survive). The vision prompt asks only for data rows with no separator,
    so this SYNTHESIZES the header/dash convention the reader requires
    rather than assuming the model supplied one."""
    if not rows:
        return None
    ncols = max(len(r) for r in rows)
    if ncols < 2:
        return None
    header = rows[0] + [""] * (ncols - len(rows[0]))
    dashes = ["---"] * ncols
    lines = ["| " + " | ".join(header) + " |",
             "| " + " | ".join(dashes) + " |"]
    for r in rows[1:]:
        padded = r + [""] * (ncols - len(r))
        lines.append("| " + " | ".join(padded) + " |")
    return " ".join(lines)


def render_recovered_content(content: dict) -> tuple[str, bool]:
    """(caption_context text, has_pipe_table). Renders the vision model's
    structured JSON into the same kind of prose-plus-numerals text the
    figure_context prompt already expects from picture_descriptions.md --
    the driver's gate reads verbatim spans out of this text exactly as it
    would out of any other caption source."""
    parts = []
    has_table = False
    counts = content.get("counts") or []
    if counts:
        pieces = []
        for c in counts:
            if isinstance(c, dict) and "n" in c:
                pieces.append(f"{c.get('n')} {c.get('group', 'items')}")
        if pieces:
            parts.append("Counts shown: " + "; ".join(pieces) + ".")
    table_rows = format_table_rows(content.get("table_rows") or [])
    if table_rows:
        flat = markdown_flatten(table_rows)
        if flat:
            has_table = True
            parts.append("Table shown: " + flat)
    labels = content.get("labels") or []
    if labels:
        pieces = []
        for l in labels:
            if isinstance(l, dict):
                label = l.get("label")
                value = l.get("value")
                if label and value not in (None, ""):
                    pieces.append(f"{label}: {value}")
                elif label:
                    pieces.append(str(label))
        if pieces:
            parts.append("Labels shown: " + "; ".join(pieces) + ".")
    expressions = content.get("expressions") or []
    if expressions:
        parts.append("Expressions shown: " + "; ".join(str(e) for e in expressions) + ".")
    summary = content.get("summary") or ""
    if summary:
        parts.append("Image summary: " + summary)
    return "\n".join(parts), has_table


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--targets", default=str(GRIND / "vision_targets.jsonl"))
    ap.add_argument("--recovery", default=str(GRIND / "vision_recovery_checkpoints.jsonl"))
    ap.add_argument("--out", default=str(GRIND / "vision_wave_targets.jsonl"))
    args = ap.parse_args()

    targets = load_jsonl(Path(args.targets))
    recovery = {r["group_key"]: r for r in load_jsonl(Path(args.recovery))}

    rows_out = []
    stats = {"inline": 0, "vision_ok": 0, "vision_failed": 0, "no_content": 0,
              "has_pipe_table": 0}
    for t in targets:
        inline = next((im["inline_description"] for im in t["images"]
                        if im.get("inline_description")), None)
        caption_context = ""
        caption_provenance = "none"
        provenance_detail = {}
        has_table = False
        if inline is not None:
            caption_context = inline
            caption_provenance = "inline_docling_description"
            provenance_detail = {"images": [im["path"] for im in t["images"]
                                             if im.get("inline_description")]}
            stats["inline"] += 1
        else:
            key = group_key_str(t["lesson"], [im["source_ref"] for im in t["images"]])
            rec = recovery.get(key)
            if rec and rec.get("outcome") == "ok":
                caption_context, has_table = render_recovered_content(rec["content"])
                caption_provenance = "vision_recovered"
                provenance_detail = {"model": rec.get("model"),
                                      "images": [im["path"] for im in t["images"]],
                                      "elapsed_s": rec.get("elapsed_s")}
                stats["vision_ok"] += 1
                if has_table:
                    stats["has_pipe_table"] += 1
            elif rec is not None:
                caption_provenance = f"vision_failed:{rec.get('outcome')}"
                stats["vision_failed"] += 1
            else:
                caption_provenance = "not_yet_served"
                stats["no_content"] += 1

        truncated = False
        if caption_context:
            encoded = caption_context.encode("utf-8")
            if len(encoded) > CAPTION_BYTE_BUDGET:
                caption_context = encoded[:CAPTION_BYTE_BUDGET].decode("utf-8", errors="ignore")
                truncated = True

        rows_out.append({
            "record_id": t["record_id"], "lesson": t["lesson"], "grade": t["grade"],
            "mode": "figure_context",
            "statement": t["statement"],
            "oracle_expected": t.get("oracle_expected"),
            "oracle_class": t.get("oracle_class"),
            "receipts": t.get("receipts"),
            "decline_class": t.get("decline_class"),
            "reason": t.get("reason"),
            "caption_context": caption_context,
            "caption_truncated": truncated,
            "caption_provenance": caption_provenance,
            "caption_provenance_detail": provenance_detail,
            "targeting_scope": t["targeting"]["scope"],
            "vision_grounded": True,
        })

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        for r in rows_out:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")

    print(f"wrote {len(rows_out)} rows -> {out_path}")
    print(f"caption provenance: {json.dumps(stats, indent=1)}")
    with_context = sum(1 for r in rows_out if r["caption_context"])
    print(f"rows with non-empty caption_context: {with_context}/{len(rows_out)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
