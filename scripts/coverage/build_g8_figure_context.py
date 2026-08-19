#!/usr/bin/env python3
"""Context build for the 117 g8_stripped_figure_table regrind (2026-08-18
recovery: the earlier lane that claimed this re-grind left zero output files
anywhere; this script and its sibling regrind driver call rebuild it from
files on disk).

Target set: figure_sources.jsonl's g8_stripped_figure_table rows EXCEPT the
8 generic_docling_lesson_material rows -- the same 117-row exclusion
build_vision_targets.py and build_recovery_wave_targets.py already assert
elsewhere, reproduced here as its own positive selection.

Context source: scripts/curriculum/vision_harvest/im_g6_8_vision_harvest.json,
a Haiku-read broad G6-8 harvest keyed by lesson CODE, never by statement --
matching figure_sources.jsonl's own note on these rows ("lesson-level match
only, not statement-level"). Every task_event this script uses is marked
figure_bound: true in the harvest; each becomes one page-anchored excerpt
line in the target's caption_context, exactly the same "context only, most
of it about other tasks on the page" role vision_wave_targets.jsonl's
recovered captions play for propose_verify_driver.py's figure_context gate
(PROMPT_FIGURE_CONTEXT already tells the model to use a description's
numbers only when they plainly belong to the problem being asked about).

Provenance is recorded as "model-read-unverified": the harvest's own
"verified" field marks a DIFFERENT check (Haiku's self-consistency against
its own extraction), never bytes independently re-derived by this pipeline's
gates -- the numeral-binding gate below is what actually earns "grounded".

Output: hermes/app/runtime/experiments/coverage_grind/g8_figure_context.jsonl,
one propose_verify_driver.py figure_context-mode target row per statement.
Every row's "vision_grounded" key is omitted (never set True), so an
admitted row's tier gets propose_verify_driver.py's "_context_grounded"
suffix, not "_vision_grounded" -- a lesson-level testimony source, not a
statement-bound image read.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
GRIND = REPO / "hermes" / "app" / "runtime" / "experiments" / "coverage_grind"
HARVEST = REPO / "scripts" / "curriculum" / "vision_harvest" / "im_g6_8_vision_harvest.json"

CAPTION_BYTE_BUDGET = 4000


def load_jsonl(path: Path) -> list[dict]:
    return [json.loads(l) for l in open(path, encoding="utf-8") if l.strip()]


def render_context(task_events: list[dict]) -> str:
    lines = []
    for ev in task_events:
        pages = ev.get("pages") or "?"
        excerpt = (ev.get("excerpt") or "").strip()
        if not excerpt:
            continue
        task = ev.get("task") or ""
        answer = ev.get("answer")
        piece = f"Page {pages}: {excerpt}"
        detail = []
        if task:
            detail.append(f"recorded task: {task}")
        if answer not in (None, ""):
            detail.append(f"recorded answer: {answer}")
        if detail:
            piece += " (" + "; ".join(detail) + ")"
        lines.append(piece)
    return "\n".join(lines)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--figure-sources", default=str(GRIND / "figure_sources.jsonl"))
    ap.add_argument("--uncovered-targets", default=str(GRIND / "uncovered_targets.jsonl"))
    ap.add_argument("--harvest", default=str(HARVEST))
    ap.add_argument("--out", default=str(GRIND / "g8_figure_context.jsonl"))
    args = ap.parse_args()

    figure_sources = load_jsonl(Path(args.figure_sources))
    uncovered_by_id = {r["record_id"]: r for r in load_jsonl(Path(args.uncovered_targets))}
    harvest = json.loads(Path(args.harvest).read_text(encoding="utf-8"))
    harvest_by_code = {h["code"]: h for h in harvest}

    g8_rows = [r for r in figure_sources
               if r.get("decline_class") == "g8_stripped_figure_table"
               and r.get("specificity") != "generic_docling_lesson_material"]
    assert len(g8_rows) == 117, f"expected 117 g8_stripped targets, got {len(g8_rows)}"

    missing_uncovered = [r["record_id"] for r in g8_rows if r["record_id"] not in uncovered_by_id]
    if missing_uncovered:
        raise SystemExit(f"{len(missing_uncovered)} g8 record_id(s) absent from "
                          f"uncovered_targets.jsonl: {missing_uncovered[:10]}")

    rows_out = []
    stats = {"harvest_matched": 0, "harvest_missing_lesson": 0,
              "has_figure_bound_events": 0, "zero_figure_bound_events": 0}
    for r in g8_rows:
        rid = r["record_id"]
        src = uncovered_by_id[rid]
        lesson = r.get("lesson") or src.get("lesson")
        h = harvest_by_code.get(lesson)
        task_events: list[dict] = []
        if h is None:
            stats["harvest_missing_lesson"] += 1
        else:
            stats["harvest_matched"] += 1
            task_events = [t for t in (h.get("task_events") or []) if t.get("figure_bound")]

        caption_context = render_context(task_events)
        if caption_context:
            stats["has_figure_bound_events"] += 1
        else:
            stats["zero_figure_bound_events"] += 1

        truncated = False
        if caption_context:
            encoded = caption_context.encode("utf-8")
            if len(encoded) > CAPTION_BYTE_BUDGET:
                caption_context = encoded[:CAPTION_BYTE_BUDGET].decode("utf-8", errors="ignore")
                truncated = True

        rows_out.append({
            "record_id": rid,
            "lesson": lesson,
            "grade": src.get("grade") or r.get("grade"),
            "mode": "figure_context",
            "statement": src["statement"],
            "oracle_expected": src.get("oracle_expected"),
            "oracle_class": src.get("oracle_class"),
            "receipts": src.get("receipts"),
            "decline_class": "g8_stripped_figure_table",
            "reason": r.get("reason"),
            "caption_context": caption_context,
            "caption_truncated": truncated,
            "caption_provenance": "model-read-unverified",
            "caption_provenance_detail": {
                "source": "scripts/curriculum/vision_harvest/im_g6_8_vision_harvest.json",
                "harvest_lesson_code": lesson if h is not None else None,
                "n_figure_bound_task_events": len(task_events),
                "harvest_model": "Haiku broad G6-8 harvest (lesson-level match, not statement-level)",
            },
            "targeting_scope": "g8_stripped_harvest_context",
        })

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        for row in rows_out:
            f.write(json.dumps(row, ensure_ascii=False) + "\n")

    print(f"wrote {len(rows_out)} rows -> {out_path}")
    print(f"stats: {json.dumps(stats)}")
    with_context = sum(1 for r in rows_out if r["caption_context"])
    print(f"rows with non-empty caption_context: {with_context}/{len(rows_out)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
