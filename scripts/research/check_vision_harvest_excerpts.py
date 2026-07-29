#!/usr/bin/env python3
"""Measure vision-harvest excerpt presence in the local Docling lesson text.

This is deliberately a provenance measurement, not an ingestion step.  It
never changes either harvest, Docling output, or any compiler/evidence input.
The only comparison normalization is whitespace collapse: a run of whitespace
in either string becomes one ASCII space.  In particular, this script does not
fold case, change punctuation, replace Unicode characters, remove markdown, or
do fuzzy matching for a pass.

The two harvests use lesson records with nested task events.  The source-text
fields are discovered and reported rather than assumed.  At present,
``task_events[].excerpt`` and ``task_events[].deformation.excerpt`` are the
quoted fields.  ``boundary_note`` is also reported as a boundary-named field,
but is not checked: it is an interpretive lesson summary, not an attributed
quotation in either artifact.
"""
from __future__ import annotations

import argparse
import copy
import difflib
import hashlib
import json
import re
import sys
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable


REPO = Path(__file__).resolve().parents[2]
HARVEST_DIR = REPO / "scripts/curriculum/vision_harvest"
DOCLING_ROOT = (
    REPO
    / "hermes/app/runtime/experiments/gemma4_tutor/docling/full-output/TeacherLessonGuides"
)
DEFAULT_OUTPUT = REPO / "scripts/research/vision_excerpt_verification_out/g8_excerpt_check"
DOC_DIR_RE = re.compile(
    r"^Grade(?P<grade>[1-8])-(?P<unit>\d+)-(?P<lesson>\d+)-Lesson-teacher-guide-$"
)
SPACE_RE = re.compile(r"\s+")


def collapse_whitespace(value: str) -> str:
    """The sole matching normalization: all whitespace becomes one space."""
    return SPACE_RE.sub(" ", value).strip()


def stable_json(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"))


def canonical_json_bytes(value: Any) -> bytes:
    """Comparable JSON bytes for row-for-row overlap reporting."""
    return stable_json(value).encode("utf-8")


def sha256_bytes(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def source_field_inventory(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Describe quote- and boundary-named fields without guessing their status."""
    event_count = 0
    excerpt_count = 0
    deformation_count = 0
    boundary_count = 0
    for lesson in rows:
        if isinstance(lesson.get("boundary_note"), str) and lesson["boundary_note"].strip():
            boundary_count += 1
        for event in lesson.get("task_events", []):
            if not isinstance(event, dict):
                continue
            event_count += 1
            if isinstance(event.get("excerpt"), str) and event["excerpt"].strip():
                excerpt_count += 1
            deformation = event.get("deformation")
            if isinstance(deformation, dict) and isinstance(deformation.get("excerpt"), str) and deformation["excerpt"].strip():
                deformation_count += 1
    return [
        {
            "path": "task_events[].excerpt",
            "nonblank_values": excerpt_count,
            "classification": "quoted_source_text_checked",
            "reason": "Event-level source excerpt used by the harvest.",
        },
        {
            "path": "task_events[].deformation.excerpt",
            "nonblank_values": deformation_count,
            "classification": "quoted_source_text_checked",
            "reason": "Event-level source excerpt supporting a deformation record.",
        },
        {
            "path": "boundary_note",
            "nonblank_values": boundary_count,
            "classification": "boundary_interpretation_not_checked",
            "reason": "The value is a harvester's interpretive boundary summary, not a quoted source field.",
        },
        {
            "path": "quote",
            "nonblank_values": 0,
            "classification": "absent",
            "reason": "No quote field occurs in these lesson records or task events.",
        },
        {
            "path": "task_events[]",
            "nonblank_values": event_count,
            "classification": "container",
            "reason": "Nested reading/event container; not itself a source-text field.",
        },
    ]


def quote_rows(rows: Iterable[dict[str, Any]]) -> Iterable[dict[str, Any]]:
    """Yield one checkable source-text row for each nonblank quoted field."""
    for lesson in rows:
        for event_index, event in enumerate(lesson.get("task_events", [])):
            if not isinstance(event, dict):
                continue
            for field, value in (("task_events[].excerpt", event.get("excerpt")),
                                 ("task_events[].deformation.excerpt", (event.get("deformation") or {}).get("excerpt") if isinstance(event.get("deformation"), dict) else None)):
                if not isinstance(value, str) or not value.strip():
                    continue
                yield {
                    "code": lesson.get("code"),
                    "grade": lesson.get("grade"),
                    "unit": lesson.get("unit"),
                    "lesson": lesson.get("lesson"),
                    "event_index": event_index,
                    "field": field,
                    "task": event.get("task"),
                    "position": event.get("position"),
                    "quote": value,
                }


def index_documents(root: Path) -> tuple[dict[str, Path], dict[str, list[str]]]:
    """Index Docling files by the harvest's IM-Gn-Un-Ln code."""
    indexed: dict[str, Path] = {}
    duplicate_paths: dict[str, list[str]] = defaultdict(list)
    for path in root.glob("Grade*/Grade*-Lesson-teacher-guide-/document.md"):
        match = DOC_DIR_RE.match(path.parent.name)
        if not match:
            continue
        code = "IM-G{grade}-U{unit}-L{lesson}".format(**match.groupdict())
        duplicate_paths[code].append(str(path.relative_to(root)))
        if code not in indexed:
            indexed[code] = path
    duplicates = {code: paths for code, paths in duplicate_paths.items() if len(paths) != 1}
    return indexed, duplicates


def nearest_docling_text(quote: str, document: str) -> str:
    """Return an exhibit only; this fuzzy score is never a matching criterion."""
    blocks = [collapse_whitespace(block) for block in re.split(r"\n\s*\n", document)]
    blocks = [block for block in blocks if block]
    if not blocks:
        return ""
    quote_normalized = collapse_whitespace(quote)
    best = max(blocks, key=lambda block: difflib.SequenceMatcher(None, quote_normalized, block).ratio())
    return best[:900]


def check_rows(
    source_name: str,
    rows: list[dict[str, Any]],
    documents: dict[str, Path],
    duplicates: dict[str, list[str]],
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    results: list[dict[str, Any]] = []
    document_cache: dict[str, str] = {}
    for item in quote_rows(rows):
        code = str(item["code"] or "")
        result = dict(item)
        result["source"] = source_name
        result["quote_sha256"] = hashlib.sha256(item["quote"].encode("utf-8")).hexdigest()
        if code in duplicates or code not in documents:
            result["status"] = "unjoinable"
            result["join_reason"] = "duplicate_docling_paths" if code in duplicates else "no_docling_document"
            result["docling_path"] = None
            result["docling_exhibit"] = None
        else:
            if code not in document_cache:
                path = documents[code]
                document = path.read_text(encoding="utf-8")
                document_cache[code] = collapse_whitespace(document)
            normalized_document = document_cache[code]
            result["docling_path"] = str(documents[code].relative_to(REPO))
            result["join_reason"] = None
            result["status"] = "passed" if collapse_whitespace(item["quote"]) in normalized_document else "failed"
            # Nearest-text work is intentionally deferred to the two selected
            # exhibits per grade.  It is explanatory only, and doing it for
            # every failed row would turn a linear substring measurement into
            # a needlessly expensive fuzzy sweep.
            result["docling_exhibit"] = None
        results.append(result)

    summary = summarize(results, source_name)
    return results, summary


def summarize(results: list[dict[str, Any]], source_name: str) -> list[dict[str, Any]]:
    buckets: dict[tuple[Any, str], Counter[str]] = defaultdict(Counter)
    for result in results:
        buckets[(result["grade"], result["field"])][result["status"]] += 1
    records = []
    for (grade, field), counts in sorted(buckets.items(), key=lambda item: (int(item[0][0]), item[0][1])):
        checked = sum(counts.values())
        records.append({
            "source": source_name,
            "grade": int(grade),
            "field": field,
            "checked": checked,
            "passed": counts["passed"],
            "failed": counts["failed"],
            "unjoinable": counts["unjoinable"],
            "pass_rate_among_joined": round(
                100 * counts["passed"] / (counts["passed"] + counts["failed"]), 2
            ) if counts["passed"] + counts["failed"] else None,
        })
    return records


def overall(summary: list[dict[str, Any]]) -> dict[str, Any]:
    counts = Counter()
    for row in summary:
        for name in ("checked", "passed", "failed", "unjoinable"):
            counts[name] += row[name]
    joined = counts["passed"] + counts["failed"]
    return {**counts, "pass_rate_among_joined": round(100 * counts["passed"] / joined, 2) if joined else None}


def comparison(broad: list[dict[str, Any]], opus: list[dict[str, Any]]) -> dict[str, Any]:
    broad_by_code = {str(row.get("code")): row for row in broad}
    opus_by_code = {str(row.get("code")): row for row in opus}
    common = sorted(set(broad_by_code) & set(opus_by_code))
    exact = [code for code in common if canonical_json_bytes(broad_by_code[code]) == canonical_json_bytes(opus_by_code[code])]
    mismatches = [code for code in common if code not in set(exact)]
    event_comparisons = []
    for code in common:
        a = broad_by_code[code].get("task_events", [])
        b = opus_by_code[code].get("task_events", [])
        event_comparisons.append({
            "code": code,
            "broad_event_count": len(a),
            "opus_event_count": len(b),
            "event_rows_byte_identical": canonical_json_bytes(a) == canonical_json_bytes(b),
        })
    return {
        "broad_lessons": len(broad),
        "opus_lessons": len(opus),
        "shared_lessons": len(common),
        "shared_lesson_records_byte_identical": len(exact),
        "shared_lesson_records_different": len(mismatches),
        "broad_only_lessons": len(set(broad_by_code) - set(opus_by_code)),
        "opus_only_lessons": len(set(opus_by_code) - set(broad_by_code)),
        "shared_task_event_arrays_byte_identical": sum(x["event_rows_byte_identical"] for x in event_comparisons),
        "shared_task_event_arrays_different": sum(not x["event_rows_byte_identical"] for x in event_comparisons),
        "different_lesson_codes": mismatches[:20],
        "event_comparisons": event_comparisons,
    }


def failure_exhibits(results: list[dict[str, Any]], source_name: str) -> dict[str, list[dict[str, Any]]]:
    by_grade: dict[str, list[dict[str, Any]]] = {}
    for grade in sorted({int(result["grade"]) for result in results}):
        failed = [result for result in results if int(result["grade"]) == grade and result["status"] == "failed"]
        exhibits = []
        for result in failed[:2]:
            exhibit = {key: result[key] for key in ("code", "event_index", "field", "task", "position", "quote", "docling_path")}
            document = (REPO / result["docling_path"]).read_text(encoding="utf-8")
            exhibit["docling_exhibit"] = nearest_docling_text(result["quote"], document)
            exhibits.append(exhibit)
        by_grade[str(grade)] = exhibits
    return by_grade


def write_json(path: Path, value: Any) -> None:
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--self-bite", action="store_true", help="Corrupt one quote in memory and verify it fails.")
    args = parser.parse_args()

    broad_path = HARVEST_DIR / "im_g6_8_vision_harvest.json"
    opus_path = HARVEST_DIR / "im_g6g7_vision_harvest.json"
    broad = json.loads(broad_path.read_text(encoding="utf-8"))
    opus = json.loads(opus_path.read_text(encoding="utf-8"))
    documents, duplicates = index_documents(DOCLING_ROOT)

    broad_results, broad_summary = check_rows("im_g6_8_vision_harvest", broad, documents, duplicates)
    opus_results, opus_summary = check_rows("im_g6g7_vision_harvest", opus, documents, duplicates)
    opus_overall = overall(opus_summary)
    calibration_threshold = 90.0
    calibration_pass = bool(opus_overall["pass_rate_among_joined"] is not None and opus_overall["pass_rate_among_joined"] >= calibration_threshold)
    payload: dict[str, Any] = {
        "generated_at_utc": datetime.now(timezone.utc).replace(microsecond=0).isoformat(),
        "purpose": "Substring-presence provenance measurement only; no ingestion or evidence-admission decision.",
        "normalization": {
            "match_normalization": ["whitespace_collapse"],
            "whitespace_collapse": "Every run of Unicode whitespace becomes one ASCII space; leading and trailing whitespace is removed.",
            "other_normalizations": [],
            "not_used": ["case folding", "Unicode folding", "punctuation replacement", "markdown removal", "fuzzy matching"],
        },
        "inputs": {
            "broad_harvest": {"path": str(broad_path.relative_to(REPO)), "sha256": sha256_bytes(broad_path), "lesson_rows": len(broad)},
            "opus_harvest": {"path": str(opus_path.relative_to(REPO)), "sha256": sha256_bytes(opus_path), "lesson_rows": len(opus)},
            "docling_root": str(DOCLING_ROOT.relative_to(REPO)),
            "indexed_docling_documents": len(documents),
            "duplicate_docling_joins": duplicates,
        },
        "field_inventory": {
            "im_g6_8_vision_harvest": source_field_inventory(broad),
            "im_g6g7_vision_harvest": source_field_inventory(opus),
        },
        "calibration": {
            "control": "im_g6g7_vision_harvest (the separately Opus-verified set)",
            "threshold_percent": calibration_threshold,
            "overall": opus_overall,
            "verdict": "CALIBRATION_PASS" if calibration_pass else "CALIBRATION_FAIL",
            "interpretation": (
                "The control clears the predeclared 90% joined-row threshold."
                if calibration_pass else
                "The control does not clear the predeclared 90% joined-row threshold; broad-harvest results remain descriptive and do not establish that whitespace-only matching is adequate."
            ),
        },
        "summaries": {
            "im_g6_8_vision_harvest": broad_summary,
            "im_g6g7_vision_harvest": opus_summary,
        },
        "overalls": {
            "im_g6_8_vision_harvest": overall(broad_summary),
            "im_g6g7_vision_harvest": opus_overall,
        },
        "overlap": comparison(broad, opus),
        "failure_exhibits": {
            "im_g6_8_vision_harvest": failure_exhibits(broad_results, "im_g6_8_vision_harvest"),
            "im_g6g7_vision_harvest": failure_exhibits(opus_results, "im_g6g7_vision_harvest"),
        },
    }

    if args.self_bite:
        bite_rows = copy.deepcopy(broad)
        bite_target = next(quote_rows(bite_rows))
        bite_lesson = bite_rows[0]
        bite_event = bite_lesson["task_events"][bite_target["event_index"]]
        bite_event["excerpt"] += " [checker self-bite corruption]"
        # Retain just this one event so the self-bite count makes the injected
        # failure unambiguous even when its lesson has other source excerpts.
        bite_lesson["task_events"] = [bite_event]
        bite_results, bite_summary = check_rows("self_bite_corrupted_broad", [bite_lesson], documents, duplicates)
        payload["self_bite"] = {
            "method": "In-memory append of a unique corruption marker to the first broad-harvest event excerpt; source JSON is not written.",
            "target": {key: bite_target[key] for key in ("code", "grade", "event_index", "field", "quote")},
            "summary": overall(bite_summary),
            "result": bite_results[0],
            "verdict": "PASS" if bite_results[0]["status"] == "failed" else "FAIL",
        }

    args.output.mkdir(parents=True, exist_ok=True)
    write_json(args.output / "summary.json", payload)
    write_json(args.output / "broad_results.json", broad_results)
    write_json(args.output / "opus_results.json", opus_results)
    transcript = [
        "VISION EXCERPT CHECK",
        f"Docling documents indexed: {len(documents)}; duplicate joins: {len(duplicates)}",
        f"Calibration first: {payload['calibration']['verdict']} — {opus_overall['passed']}/{opus_overall['passed'] + opus_overall['failed']} joined rows passed ({opus_overall['pass_rate_among_joined']}%); {opus_overall['unjoinable']} unjoinable.",
    ]
    for source, rows in payload["summaries"].items():
        transcript.append(source + ":")
        for row in rows:
            transcript.append(
                f"  G{row['grade']} {row['field']}: checked={row['checked']} passed={row['passed']} failed={row['failed']} unjoinable={row['unjoinable']}"
            )
    if args.self_bite:
        bite = payload["self_bite"]
        transcript.append(f"Self-bite: {bite['verdict']} — checked={bite['summary']['checked']} passed={bite['summary']['passed']} failed={bite['summary']['failed']} unjoinable={bite['summary']['unjoinable']}")
    (args.output / "run_transcript.txt").write_text("\n".join(transcript) + "\n", encoding="utf-8")
    print("\n".join(transcript))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
