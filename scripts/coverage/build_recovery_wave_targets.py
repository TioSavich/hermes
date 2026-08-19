#!/usr/bin/env python3
"""Target-and-mode assignment for the 2026-08-18 coverage-recovery wave.

Reads the three census artifacts already on disk (figure_sources.jsonl,
draw_task_map.jsonl, explanation_families.jsonl) plus the base wave's
uncovered_targets.jsonl and merged_admitted_ledger.jsonl, and assigns every
candidate record to exactly ONE of three modes:

  1. explanation_form  (priority 1) -- family d_strategy_explanation +
     b_comparison rows from explanation_families.jsonl.
  2. render_spec        (priority 2) -- draw_task_map rows with
     resolution == "op", minus anything explanation_form already claimed.
  3. figure_context     (priority 3) -- picture_routine + visual_general
     (figure_sources.jsonl) union interpret_given (draw_task_map.jsonl),
     minus the 117 g8_stripped records a parallel lane is re-grinding
     (figure_sources_figure_bound + task_level specificity, i.e. every
     g8_stripped_figure_table row EXCEPT the 8 generic_docling_lesson_material
     ones -- verified 96+21=117 against figure_sources_summary.json),
     minus whatever the two higher-priority modes already claimed.

For each assigned record this script resolves every prompt-time input LOCALLY
(picture captions read from the docling tree and truncated to a byte budget,
ledger steps joined by record_id, the resolved render op/kind) so the
Big Red job never needs the docling tree or the ledger file -- only the one
target file this script writes.

Output: hermes/app/runtime/experiments/coverage_grind/recovery_wave_targets.jsonl
(gitignored runtime data, not code).
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
GRIND = REPO / "hermes" / "app" / "runtime" / "experiments" / "coverage_grind"
DOCLING_BASE = (REPO / "hermes" / "app" / "runtime" / "experiments" /
                 "gemma4_tutor" / "docling" / "full-output" / "TeacherLessonGuides")

CAPTION_BYTE_BUDGET = 4000

LESSON_RE = re.compile(r"IM-G(K|\d+)-U(\d+)-L(\d+)")


def load_jsonl(path: Path) -> list[dict]:
    return [json.loads(l) for l in open(path, encoding="utf-8") if l.strip()]


def lesson_caption_path(lesson: str | None) -> Path | None:
    """The lesson's picture_descriptions.md path, resolved from its code.

    Verified 2026-08-18 against all 1,308 docling lesson directories: every
    IM-G{grade}-U{unit}-L{lesson} code maps to
    TeacherLessonGuides/{GradeDir}/{GradeDir}-{unit}-{lesson}-Lesson-teacher-guide-/
    with zero unmatched directories (grade K -> "Kindergarten", else "Grade{n}").
    """
    if not lesson:
        return None
    m = LESSON_RE.match(lesson)
    if not m:
        return None
    grade, unit, lnum = m.groups()
    grade_dir = "Kindergarten" if grade == "K" else f"Grade{grade}"
    subdir = f"{grade_dir}-{unit}-{lnum}-Lesson-teacher-guide-"
    return DOCLING_BASE / grade_dir / subdir / "picture_descriptions.md"


IMAGE_LINK_RE = re.compile(r"^\s*!\[.*\]\(.*\)\s*$")


def extract_captions(path: Path, byte_budget: int = CAPTION_BYTE_BUDGET):
    """(caption_text, truncated, source_path) -- the noisy image-link lines
    (long content-hash filenames, zero informational value for numeral
    binding) are stripped before the byte budget is applied, so the budget
    is spent on descriptive text, not path bytes."""
    if path is None or not path.exists():
        return "", False, None
    raw = path.read_text(encoding="utf-8", errors="ignore")
    kept = [ln for ln in raw.splitlines() if not IMAGE_LINK_RE.match(ln)]
    text = "\n".join(kept).strip()
    encoded = text.encode("utf-8")
    truncated = False
    if len(encoded) > byte_budget:
        text = encoded[:byte_budget].decode("utf-8", errors="ignore")
        truncated = True
    return text, truncated, str(path.relative_to(REPO))


# --- render_spec: disambiguate the two slash-joined candidate_op cases -----
# The census left these two families genuinely ambiguous between two ops;
# op_kind alone resolves both without a model call, since "area_model_fraction"
# is only a valid area_render kind (not a fraction_render kind) and
# "stretch_polygon" is only geoboard_render's spec functor (rigid_motion_render
# has no such kind) -- verified against render_op_inventory.md's op tables.
def resolve_op(candidate_op: str, op_kind: str) -> str:
    if candidate_op == "fraction_render / area_render":
        return "area_render"
    if candidate_op == "geoboard_render / rigid_motion_render":
        return "geoboard_render"
    return candidate_op


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=str(GRIND / "recovery_wave_targets.jsonl"))
    args = ap.parse_args()

    figure_sources = load_jsonl(GRIND / "figure_sources.jsonl")
    draw_task_map = load_jsonl(GRIND / "draw_task_map.jsonl")
    explanation_families = load_jsonl(GRIND / "explanation_families.jsonl")
    explanation_summary = json.loads((GRIND / "explanation_families_summary.json").read_text())
    ledger_rows = load_jsonl(GRIND / "merged_admitted_ledger.jsonl")
    uncovered = load_jsonl(GRIND / "uncovered_targets.jsonl")

    targets_by_id = {r["record_id"]: r for r in uncovered}
    ledger_by_id = {r["record_id"]: r for r in ledger_rows}
    fig_by_id = {r["record_id"]: r for r in figure_sources}
    draw_by_id = {r["record_id"]: r for r in draw_task_map}
    slot_by_family = {f["family"]: f["slot_structure"] for f in explanation_summary["families"]}
    ask_by_id_expl = {r["record_id"]: r for r in explanation_families}

    # --- exclusion: the 117 g8_stripped records a parallel lane re-grinds --
    g8_excluded = {
        r["record_id"] for r in figure_sources
        if r["decline_class"] == "g8_stripped_figure_table"
        and r["specificity"] != "generic_docling_lesson_material"
    }
    assert len(g8_excluded) == 117, f"expected 117 g8_stripped exclusions, got {len(g8_excluded)}"

    # --- priority 1: explanation_form ---------------------------------
    explanation_ids = {
        r["record_id"] for r in explanation_families
        if r["family"] in ("d_strategy_explanation", "b_comparison")
    }
    dupe_check = [r["record_id"] for r in explanation_families
                  if r["family"] in ("d_strategy_explanation", "b_comparison")]
    assert len(dupe_check) == len(set(dupe_check)), "duplicate record_id inside explanation family rows"

    # --- priority 2: render_spec ---------------------------------------
    render_ids_all = {r["record_id"] for r in draw_task_map if r["resolution"] == "op"}
    render_ids = render_ids_all - explanation_ids

    # --- priority 3: figure_context -------------------------------------
    fig_candidate_ids = {r["record_id"] for r in figure_sources
                          if r["decline_class"] in ("picture_routine", "visual_general")}
    interpret_ids = {r["record_id"] for r in draw_task_map if r["resolution"] == "interpret_given"}
    figure_ids_all = fig_candidate_ids | interpret_ids
    figure_ids = figure_ids_all - g8_excluded - explanation_ids - render_ids

    print(f"candidate pool sizes: explanation={len(explanation_ids)} "
          f"render_op={len(render_ids_all)} figure_all={len(figure_ids_all)} "
          f"g8_excluded={len(g8_excluded)}")
    print(f"after dedupe priority (explanation > render_spec > figure_context): "
          f"explanation_form={len(explanation_ids)} render_spec={len(render_ids)} "
          f"figure_context={len(figure_ids)}")
    print(f"total assigned = {len(explanation_ids) + len(render_ids) + len(figure_ids)}")

    rows_out = []
    missing_caption = 0
    caption_truncated_n = 0

    # explanation_form rows
    for rid in sorted(explanation_ids):
        tgt = targets_by_id.get(rid)
        if tgt is None:
            continue
        efam = ask_by_id_expl[rid]
        ledger = ledger_by_id.get(rid)
        ledger_analysis = None
        ledger_gate = None
        ledger_executed = None
        if ledger is not None:
            ledger_gate = ledger.get("gate")
            ledger_analysis = ledger.get("analysis")
            ledger_executed = ledger.get("executed")
        rows_out.append({
            "record_id": rid, "lesson": tgt.get("lesson"), "grade": tgt.get("grade"),
            "mode": "explanation_form",
            "statement": tgt["statement"],
            "oracle_expected": tgt.get("oracle_expected"),
            "oracle_class": tgt.get("oracle_class"),
            "receipts": tgt.get("receipts"),
            "family": efam["family"],
            "family_label": next((f["label"] for f in explanation_summary["families"]
                                   if f["family"] == efam["family"]), None),
            "slot_structure": slot_by_family.get(efam["family"]),
            "census_ask": efam.get("ask"),
            "ledger_gate": ledger_gate,
            "ledger_analysis": ledger_analysis,
            "ledger_executed": ledger_executed,
        })

    # render_spec rows
    for rid in sorted(render_ids):
        tgt = targets_by_id.get(rid)
        draw = draw_by_id.get(rid)
        if tgt is None or draw is None:
            continue
        op = resolve_op(draw["candidate_op"], draw["op_kind"])
        rows_out.append({
            "record_id": rid, "lesson": tgt.get("lesson"), "grade": tgt.get("grade"),
            "mode": "render_spec",
            "statement": tgt["statement"],
            "oracle_expected": tgt.get("oracle_expected"),
            "oracle_class": tgt.get("oracle_class"),
            "receipts": tgt.get("receipts"),
            "candidate_op": op,
            "op_kind": draw["op_kind"],
            "operand_note": draw.get("operand_note"),
            "numerals_in_statement": draw.get("numerals_in_statement"),
        })

    # figure_context rows
    for rid in sorted(figure_ids):
        tgt = targets_by_id.get(rid)
        if tgt is None:
            continue
        fig = fig_by_id.get(rid)
        draw = draw_by_id.get(rid)
        path = lesson_caption_path(tgt.get("lesson"))
        caption_text, truncated, source_path = extract_captions(path)
        if not caption_text:
            missing_caption += 1
        if truncated:
            caption_truncated_n += 1
        decline_class = fig.get("decline_class") if fig else (
            "interpret_given" if draw else None)
        reason = fig.get("reason") if fig else (draw.get("missing_doing") if draw else None)
        rows_out.append({
            "record_id": rid, "lesson": tgt.get("lesson"), "grade": tgt.get("grade"),
            "mode": "figure_context",
            "statement": tgt["statement"],
            "oracle_expected": tgt.get("oracle_expected"),
            "oracle_class": tgt.get("oracle_class"),
            "receipts": tgt.get("receipts"),
            "decline_class": decline_class,
            "reason": reason,
            "caption_context": caption_text,
            "caption_truncated": truncated,
            "caption_source_path": source_path,
        })

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        for r in rows_out:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")

    print(f"wrote {len(rows_out)} rows -> {out_path}")
    print(f"figure_context: {missing_caption} rows with no resolvable caption "
          f"(lesson missing or file absent); {caption_truncated_n} truncated at "
          f"{CAPTION_BYTE_BUDGET} bytes")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
