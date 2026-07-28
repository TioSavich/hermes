#!/usr/bin/env python3
"""Generate a bounded audit of the IM 6-8 vision lesson digest.

The vision harvest is an irreplaceable record of one PDF-reading run.  This
audit does not repair its lesson records or discard them.  It gives every
harvest lesson a status against the published IM spine and keeps the harvest
metadata that can corroborate, but cannot settle, an attribution question
without the source PDFs.
"""
from __future__ import annotations

import argparse
import difflib
import json
import re
import sys
import tempfile
import unicodedata
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
HARVEST = ROOT / "scripts" / "curriculum" / "vision_harvest" / "im_g6_8_vision_harvest.json"
SPINE = ROOT / "data" / "learningcommons" / "derived" / "im_k8_spine.json"
NEGATIVE_RECEIPTS = ROOT / "scripts" / "curriculum" / "lesson_negative_receipts.json"
VISION_MODULES = {
    "grade_6": ROOT / "curriculum" / "im" / "grade_6_vision.pl",
    "grade_7": ROOT / "curriculum" / "im" / "grade_7_vision.pl",
}
OUTPUT = ROOT / "knowledge" / "index" / "vision_lesson_digest_audit.pl"

STATUS_KINDS = (
    "consistent",
    "cosmetic_title_variant",
    "content_assigned_elsewhere",
    "content_not_named_in_spine",
    "absent_from_spine",
)
STANDARD_RELATIONS = ("matches_assigned", "differs_from_assigned")
TARGET_STANDARD_RELATIONS = (
    "matches_a_named_target",
    "differs_from_named_targets",
    "not_applicable",
)

# These are deliberately few and span all three grades.  They are a positive
# control for the instrument, not an assertion that all other records agree.
POSITIVE_CONTROLS = {
    "IM-G6-U1-L1": "Tiling the Plane",
    "IM-G6-U3-L1": "Anchoring Units of Measurement",
    "IM-G7-U1-L1": "What Are Scaled Copies?",
    "IM-G7-U3-L1": "How Well Can You Measure?",
    "IM-G8-U1-L1": "Moving in the Plane",
    "IM-G8-U3-L1": "Understanding Proportional Relationships",
}

LESSON_CODE = re.compile(r"^IM-G(?P<grade>[6-8])-U(?P<unit>[1-9][0-9]*)-L(?P<lesson>[1-9][0-9]*)$")
EXPLICIT_CODE = re.compile(r"\bIM-G(?P<grade>[6-8])-U(?P<unit>[1-9][0-9]*)-L(?P<lesson>[1-9][0-9]*)\b", re.I)
UNIT_THEN_LESSON = re.compile(r"\bUnit\s+(?P<unit>[1-9][0-9]*)\b.{0,36}?\bLessons?\s+(?P<lessons>[0-9][0-9]*(?:\s*(?:,|and)\s*[0-9][0-9]*)*)", re.I)
LESSON_THEN_UNIT = re.compile(r"\bLesson\s+(?P<lesson>[1-9][0-9]*)\b.{0,52}?\bUnit\s+(?P<unit>[1-9][0-9]*)\b", re.I)


def prolog_atom(value: str) -> str:
    if re.fullmatch(r"[a-z][A-Za-z0-9_]*", value):
        return value
    return "'" + value.replace("'", "''") + "'"


def prolog_string(value: object) -> str:
    text = str(value or "")
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"').replace("\n", " ") + '"'


def title_key(value: str) -> str:
    """Compare presentation-only title variants without guessing content."""
    normalized = unicodedata.normalize("NFKD", value).lower()
    normalized = re.sub(r"\\(?:text|mathrm|mathit)\{([^}]*)\}", r"\1", normalized)
    normalized = normalized.replace("$", "")
    return " ".join(re.sub(r"[^a-z0-9]+", " ", normalized).split())


def without_locator(value: str) -> str:
    """Remove only a lesson locator attached to an otherwise complete title."""
    result = value.strip()
    result = re.sub(r"^\s*IM-G[6-8]-U[1-9][0-9]*-L[1-9][0-9]*\s*:\s*", "", result, flags=re.I)
    result = re.sub(
        r"^\s*IM\s+Grade\s+[6-8]\s*,?\s*Unit\s+[1-9][0-9]*\s*,?\s*Lesson\s+[1-9][0-9]*\s*[—:-]\s*",
        "",
        result,
        flags=re.I,
    )
    result = re.sub(r"^\s*Unit\s+[1-9][0-9]*\s*,?\s*Lesson\s+[1-9][0-9]*\s*:\s*", "", result, flags=re.I)
    result = re.sub(
        r"\s*\(\s*Grade\s+[6-8]\s*,?\s*Unit\s+[1-9][0-9]*(?:\s*,?\s*Lesson\s+[1-9][0-9]*)?\s*\)\s*$",
        "",
        result,
        flags=re.I,
    )
    return result.strip()


def standard_map(row: dict, key: str) -> tuple[tuple[str, tuple[str, ...]], ...]:
    standards = row.get(key, {}) or {}
    return tuple(
        (band, tuple(sorted(str(code) for code in standards.get(band, []) or [])))
        for band in ("building_on", "addressing", "building_toward")
    )


def parse_code(code: str) -> tuple[int, int, int]:
    match = LESSON_CODE.fullmatch(code)
    if match is None:
        raise RuntimeError(f"unparseable harvest lesson code: {code}")
    return tuple(int(match.group(field)) for field in ("grade", "unit", "lesson"))


def code_for(grade: int, unit: int, lesson: int) -> str:
    return f"IM-G{grade}-U{unit}-L{lesson}"


def named_targets(title: str, grade: int, own_code: str, spine: dict[str, dict], names: dict[str, list[str]]) -> list[str]:
    """Find only explicit references or an exact canonical title elsewhere."""
    targets: set[str] = set()
    for match in EXPLICIT_CODE.finditer(title):
        targets.add(code_for(int(match["grade"]), int(match["unit"]), int(match["lesson"])))
    for match in UNIT_THEN_LESSON.finditer(title):
        for lesson in re.findall(r"[0-9][0-9]*", match["lessons"]):
            targets.add(code_for(grade, int(match["unit"]), int(lesson)))
    for match in LESSON_THEN_UNIT.finditer(title):
        targets.add(code_for(grade, int(match["unit"]), int(match["lesson"])))
    targets.update(names.get(title_key(title), []))
    return sorted(target for target in targets if target != own_code and target in spine)


def harvest_binding(row: dict, grade: int, unit: int) -> str:
    """Check only internal harvest provenance, never the absent source PDFs."""
    pages = str(row.get("pages_range") or "").strip()
    unit_pdf = str(row.get("unit_pdf") or "").strip()
    expected = f"grade{grade}-{unit}-unit-teacher-guide-"
    if pages and unit_pdf.lower().startswith(expected):
        return "code_bound_metadata"
    return "incomplete_or_misaligned_metadata"


def source_pdf_count(harvest: list[dict]) -> int:
    """Count harvest unit-PDF filenames actually present in this checkout."""
    expected = {str(row.get("unit_pdf") or "") for row in harvest}
    present = {path.name for path in ROOT.rglob("*.pdf")}
    return len(expected & present)


def load_inputs() -> tuple[list[dict], dict[str, dict], list[dict]]:
    harvest = json.loads(HARVEST.read_text(encoding="utf-8"))
    spine_rows = json.loads(SPINE.read_text(encoding="utf-8"))
    receipts = json.loads(NEGATIVE_RECEIPTS.read_text(encoding="utf-8"))["receipts"]
    if not isinstance(harvest, list) or not isinstance(spine_rows, list) or not isinstance(receipts, list):
        raise RuntimeError("the harvest, spine, or receipt register has an unexpected shape")
    spine = {str(row["repo_id"]): row for row in spine_rows}
    if len(spine) != len(spine_rows):
        raise RuntimeError("the spine contains duplicate repo_id values")
    codes = [str(row.get("code") or "") for row in harvest]
    if len(codes) != len(set(codes)) or not all(codes):
        raise RuntimeError("the vision harvest contains missing or duplicate lesson codes")
    return harvest, spine, receipts


def measure() -> tuple[list[dict], dict[str, int], int, list[dict], list[dict], int]:
    harvest, spine, receipts = load_inputs()
    name_index: dict[str, list[str]] = {}
    for code, row in spine.items():
        name_index.setdefault(title_key(str(row["name"])), []).append(code)
    for codes in name_index.values():
        codes.sort()

    pdfs = source_pdf_count(harvest)
    rows: list[dict] = []
    for row in sorted(harvest, key=lambda item: parse_code(str(item["code"]))):
        code = str(row["code"])
        grade, unit, lesson = parse_code(code)
        if (row.get("grade"), row.get("unit"), row.get("lesson")) != (grade, unit, lesson):
            raise RuntimeError(f"harvest fields disagree with lesson code: {code}")
        spine_row = spine.get(code)
        if spine_row is None:
            status = "absent_from_spine"
            spine_title = ""
            standards = "not_applicable"
            target_standards = "not_applicable"
            targets: list[str] = []
        else:
            spine_title = str(spine_row["name"])
            standards = (
                "matches_assigned"
                if standard_map(row, "standards") == standard_map(spine_row, "ccss")
                else "differs_from_assigned"
            )
            if row.get("title") == spine_title:
                status = "consistent"
                targets = []
            elif title_key(str(row.get("title") or "")) == title_key(spine_title) or title_key(without_locator(str(row.get("title") or ""))) == title_key(spine_title):
                status = "cosmetic_title_variant"
                targets = []
            else:
                targets = named_targets(str(row.get("title") or ""), grade, code, spine, name_index)
                status = "content_assigned_elsewhere" if targets else "content_not_named_in_spine"
            if targets:
                target_standards = (
                    "matches_a_named_target"
                    if any(standard_map(row, "standards") == standard_map(spine[target], "ccss") for target in targets)
                    else "differs_from_named_targets"
                )
            else:
                target_standards = "not_applicable"
        rows.append({
            "code": code,
            "status": status,
            "title": str(row.get("title") or ""),
            "spine_title": spine_title,
            "standards": standards,
            "target_standards": target_standards,
            "targets": targets,
            "binding": harvest_binding(row, grade, unit),
            "goals": len(row.get("teacher_goals") or []),
            "purpose": "present" if str(row.get("purpose") or "").strip() else "absent",
        })

    counts = Counter(row["status"] for row in rows)
    if sum(counts.values()) != len(harvest):
        raise RuntimeError("audit status rows do not cover the harvest denominator")
    if any(counts[kind] == 0 for kind in ("consistent", "absent_from_spine", "content_not_named_in_spine")):
        raise RuntimeError("audit control failed: a required observed status class is empty")
    by_code = {row["code"]: row for row in rows}
    for code, expected_title in POSITIVE_CONTROLS.items():
        row = by_code.get(code)
        if row is None or row["status"] != "consistent" or row["title"] != expected_title or row["spine_title"] != expected_title:
            raise RuntimeError(f"positive control failed for {code}")

    flagged = [row for row in rows if row["status"] not in ("consistent", "cosmetic_title_variant")]
    fact_receipts = []
    for position, receipt in enumerate(receipts, start=1):
        if receipt.get("source", {}).get("kind") != "fact":
            continue
        audit = by_code.get(str(receipt.get("lesson") or ""))
        if audit and audit["status"] not in ("consistent", "cosmetic_title_variant"):
            action = receipt.get("intended_action", {})
            fact_receipts.append({
                "position": position,
                "lesson": audit["code"],
                "status": audit["status"],
                "action": f"{action.get('operation', 'unknown')}/{action.get('kind', 'unknown')}",
                "alternative": str(receipt.get("alternative") or ""),
            })
    fact_total = sum(receipt.get("source", {}).get("kind") == "fact" for receipt in receipts)

    module_rows = []
    for module, path in VISION_MODULES.items():
        source = path.read_text(encoding="utf-8")
        for code, audit in by_code.items():
            clauses = len(re.findall(r"vision_lesson_strategy\(\s*'" + re.escape(code) + r"'", source))
            if clauses and audit["status"] != "consistent":
                module_rows.append({"module": module, "code": code, "status": audit["status"], "clauses": clauses})
    return rows, counts, pdfs, fact_receipts, module_rows, fact_total


def render_registry() -> tuple[str, dict[str, int]]:
    rows, counts, pdfs, fact_receipts, module_rows, fact_total = measure()
    standard_counts = Counter(row["standards"] for row in rows if row["standards"] != "not_applicable")
    status_standard_counts = Counter(
        (row["status"], row["standards"])
        for row in rows
        if row["standards"] != "not_applicable"
    )
    target_standard_counts = Counter(row["target_standards"] for row in rows)
    binding_counts = Counter(row["binding"] for row in rows)
    lines = [
        "/** <module> Generated audit of the IM 6-8 vision lesson digest",
        " *",
        " * One row per vision-harvest lesson. The harvest is an input record of a",
        " * PDF-reading run, so this registry records mismatches rather than editing",
        " * or deleting the harvest. The published spine supplies lesson ids, names,",
        " * and standards; it has no teacher goals, purpose text, page contents, or",
        " * PDF pages. Metadata can therefore corroborate internal code binding and",
        " * standards agreement, but cannot establish what page a vision run read.",
        " *",
        " * Statuses partition the harvest denominator:",
        " *   - consistent: the harvest title exactly equals the assigned spine name.",
        " *   - cosmetic_title_variant: only locator or presentation formatting differs.",
        " *   - content_assigned_elsewhere: the harvest title explicitly names, or",
        " *     exactly equals, a different published spine lesson.",
        " *   - content_not_named_in_spine: the title is substantive and no different",
        " *     canonical spine lesson is named by the available title evidence.",
        " *   - absent_from_spine: the harvest lesson id has no published spine row.",
        " *",
        " * audit metadata stores the harvest's unit-PDF name, page range, goal count,",
        " * and purpose presence. source_pdf_count is the number of those unit-PDF",
        " * filenames in this checkout; zero means the stored metadata cannot be",
        " * checked against source pages here.",
        " *",
        " * Generated by scripts/extract_vision_lesson_digest_audit.py.",
        " * Regenerate: python3 scripts/extract_vision_lesson_digest_audit.py",
        " */",
        "",
        ":- module(vision_lesson_digest_audit,",
        "          [ vision_digest_audit/4,",
        "            vision_digest_audit_denominator/2,",
        "            vision_digest_audit_status_count/2,",
        "            vision_digest_audit_standard_count/2,",
        "            vision_digest_audit_status_standard_count/3,",
        "            vision_digest_audit_target_standard_count/2,",
        "            vision_digest_audit_binding_count/2,",
        "            vision_digest_audit_source_pdf_count/1,",
        "            vision_digest_audit_positive_control/2,",
        "            vision_digest_audit_fact_receipt/5,",
        "            vision_digest_audit_vision_module/4,",
        "            vision_digest_audit_flagged/3",
        "          ]).",
        "",
    ]
    for row in rows:
        spine = "none" if not row["spine_title"] else prolog_string(row["spine_title"])
        targets = "[" + ", ".join(prolog_atom(target) for target in row["targets"]) + "]"
        evidence = (
            f"evidence(harvest_title({prolog_string(row['title'])}), spine_title({spine}), "
            f"standards({row['standards']}, {row['target_standards']}), "
            f"harvest_metadata({row['binding']}, teacher_goals({row['goals']}), purpose({row['purpose']})), "
            f"named_targets({targets}))"
        )
        lines.append(f"vision_digest_audit({prolog_atom(row['code'])}, {row['status']}, {prolog_string(row['title'])}, {evidence}).")
    lines.extend(["", f"vision_digest_audit_denominator(harvest_lessons, {len(rows)})."])
    for status in STATUS_KINDS:
        lines.append(f"vision_digest_audit_status_count({status}, {counts[status]}).")
    lines.append("")
    for relation in STANDARD_RELATIONS:
        lines.append(f"vision_digest_audit_standard_count({relation}, {standard_counts[relation]}).")
    for status in STATUS_KINDS:
        for relation in STANDARD_RELATIONS:
            lines.append(
                f"vision_digest_audit_status_standard_count({status}, {relation}, "
                f"{status_standard_counts[status, relation]})."
            )
    for relation in TARGET_STANDARD_RELATIONS:
        lines.append(f"vision_digest_audit_target_standard_count({relation}, {target_standard_counts[relation]}).")
    for binding in ("code_bound_metadata", "incomplete_or_misaligned_metadata"):
        lines.append(f"vision_digest_audit_binding_count({binding}, {binding_counts[binding]}).")
    lines.extend(["", f"vision_digest_audit_source_pdf_count({pdfs}).", ""])
    for code in sorted(POSITIVE_CONTROLS):
        lines.append(f"vision_digest_audit_positive_control({prolog_atom(code)}, consistent).")
    lines.append("")
    for receipt in fact_receipts:
        lines.append(
            f"vision_digest_audit_fact_receipt({receipt['position']}, {prolog_atom(receipt['lesson'])}, "
            f"{receipt['status']}, {prolog_atom(receipt['action'])}, {prolog_atom(receipt['alternative'])})."
        )
    lines.append("")
    for module_row in sorted(module_rows, key=lambda row: (row["module"], parse_code(row["code"]))):
        lines.append(
            f"vision_digest_audit_vision_module({module_row['module']}, {prolog_atom(module_row['code'])}, "
            f"{module_row['status']}, {module_row['clauses']})."
        )
    lines.extend([
        "",
        "vision_digest_audit_flagged(Lesson, Status, Evidence) :-",
        "    vision_digest_audit(Lesson, Status, _, Evidence),",
        "    ( Status = content_assigned_elsewhere ;",
        "      Status = content_not_named_in_spine ;",
        "      Status = absent_from_spine ).",
        "",
    ])
    return "\n".join(lines), {
        "harvest": len(rows),
        "fact_total": fact_total,
        "fact_flagged": len(fact_receipts),
        "module_flagged": len(module_rows),
        "source_pdfs": pdfs,
        **{status: counts[status] for status in STATUS_KINDS},
    }


def check_output(expected: str, output: Path) -> int:
    actual = output.read_text(encoding="utf-8") if output.is_file() else ""
    if actual == expected:
        print(f"vision lesson digest audit is current: {output.relative_to(ROOT)}")
        return 0
    with tempfile.NamedTemporaryFile("w", encoding="utf-8", suffix=".pl", delete=False) as temporary:
        temporary.write(expected)
        temporary_path = Path(temporary.name)
    print("vision lesson digest audit is stale; run python3 scripts/extract_vision_lesson_digest_audit.py", file=sys.stderr)
    for line in list(difflib.unified_diff(actual.splitlines(), expected.splitlines(), fromfile=str(output), tofile=str(temporary_path), lineterm=""))[:12]:
        print(line, file=sys.stderr)
    temporary_path.unlink(missing_ok=True)
    return 1


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="fail if the generated audit is stale")
    parser.add_argument("--output", type=Path, default=OUTPUT, help=argparse.SUPPRESS)
    arguments = parser.parse_args()
    output = arguments.output if arguments.output.is_absolute() else ROOT / arguments.output
    rendered, measured = render_registry()
    if arguments.check:
        result = check_output(rendered, output)
        if result == 0:
            print("status_counts=" + ", ".join(f"{status}:{measured[status]}" for status in STATUS_KINDS))
        return result
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(rendered, encoding="utf-8")
    print(f"wrote {output.relative_to(ROOT)}: {len(rendered.splitlines())} lines")
    print("status_counts=" + ", ".join(f"{status}:{measured[status]}" for status in STATUS_KINDS))
    print(f"fact_receipts={measured['fact_flagged']}/{measured['fact_total']} vision_module_rows={measured['module_flagged']} source_pdfs={measured['source_pdfs']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
