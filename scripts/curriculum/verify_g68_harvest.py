#!/usr/bin/env python3
"""Verify G6-8 harvested task excerpts against cleaned source markdown.

The shared source view excludes Docling image-reference lines and generated
picture-description blocks. The gate then has one matching rule: collapse each
run of whitespace in the cleaned source and excerpt to one ASCII space, then
require the normalized excerpt to occur verbatim in the normalized source. No
spelling, punctuation, case, or Unicode changes are forgiven. Match offsets are
offsets in the normalized cleaned source.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any, Callable, Mapping

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from scripts.research.extract_lesson_context import picture_description_lines


CONTROL_EXCERPTS = (
    "Students compare 731,942 and 608,517 and explain which quantity is greater.",
    "Students arrange 83 violet tiles into 7 equal groups and record every remainder.",
)


class ControlLeakError(RuntimeError):
    """Raised when a manufactured absent excerpt passes the gate."""


def normalize_whitespace(text: str) -> str:
    """Collapse whitespace runs and remove only leading/trailing whitespace."""
    return re.sub(r"\s+", " ", text).strip()


def cleaned_source_view(source_file: Path, raw_source_text: str) -> str:
    """Remove the same Docling picture lines excluded by the compiler."""
    lines = raw_source_text.splitlines()
    excluded = picture_description_lines(source_file, lines)
    if excluded is None:
        raise ValueError(
            f"Docling guide picture annotations cannot be separated: {source_file}"
        )
    return "\n".join(
        line for index, line in enumerate(lines) if index not in excluded
    )


def normalized_match_offset(source_text: str, excerpt: str) -> int | None:
    """Return the normalized-source offset for an exact normalized match."""
    normalized_excerpt = normalize_whitespace(excerpt)
    if not normalized_excerpt:
        return None
    offset = normalize_whitespace(source_text).find(normalized_excerpt)
    return offset if offset >= 0 else None


def verify_excerpt(source_text: str, excerpt: str) -> dict[str, Any]:
    """Return the deterministic provenance verdict for one excerpt."""
    offset = normalized_match_offset(source_text, excerpt)
    return {
        "verdict": "accepted" if offset is not None else "rejected",
        "normalized_match_offset": offset,
        "rule": "whitespace-normalized exact substring",
    }


Matcher = Callable[[str, str], int | None]


def calibrate_controls(
    sources: Mapping[str, str],
    *,
    controls: tuple[str, ...] = CONTROL_EXCERPTS,
    matcher: Matcher = normalized_match_offset,
) -> dict[str, Any]:
    """Require every manufactured excerpt to be rejected for every source."""
    leaks: list[dict[str, Any]] = []
    checks = 0
    for lesson, source_text in sources.items():
        for excerpt in controls:
            checks += 1
            offset = matcher(source_text, excerpt)
            if offset is not None:
                leaks.append({
                    "lesson": lesson,
                    "excerpt": excerpt,
                    "normalized_match_offset": offset,
                })
    if leaks:
        sample = json.dumps(leaks[:3], ensure_ascii=False)
        raise ControlLeakError(
            f"CONTROL LEAK: {len(leaks)} of {checks} manufactured excerpts passed: {sample}"
        )
    return {
        "verdict": "passed",
        "controls": len(controls),
        "sources": len(sources),
        "checks": checks,
        "rejected": checks,
        "rejection_rate": 1.0,
    }


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def sha256_text(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def verify_run(run_dir: Path) -> dict[str, Any]:
    """Re-run fingerprints, controls, and every stored accepted-record gate."""
    manifest_path = run_dir / "manifest.json"
    if not manifest_path.is_file():
        raise ValueError(f"manifest not found: {manifest_path}")
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    lessons = manifest.get("lessons")
    if not isinstance(lessons, list) or not lessons:
        raise ValueError("manifest lessons must be a nonempty list")

    sources: dict[str, str] = {}
    for lesson in lessons:
        lesson_id = lesson.get("lesson")
        source_path = Path(str(lesson.get("source_file", "")))
        expected_raw_hash = lesson.get("raw_source_sha256")
        expected_cleaned_hash = lesson.get("cleaned_source_sha256")
        if not isinstance(lesson_id, str) or not source_path.is_file():
            raise ValueError(f"missing source for manifest lesson: {lesson_id!r}")
        actual_raw_hash = sha256_file(source_path)
        if actual_raw_hash != expected_raw_hash:
            raise ValueError(
                "raw source fingerprint changed for "
                f"{lesson_id}: {actual_raw_hash} != {expected_raw_hash}"
            )
        raw_source_text = source_path.read_text(encoding="utf-8", errors="strict")
        cleaned_source_text = cleaned_source_view(source_path, raw_source_text)
        actual_cleaned_hash = sha256_text(cleaned_source_text)
        if actual_cleaned_hash != expected_cleaned_hash:
            raise ValueError(
                "cleaned source fingerprint changed for "
                f"{lesson_id}: {actual_cleaned_hash} != {expected_cleaned_hash}"
            )
        sources[lesson_id] = cleaned_source_text

    calibration = calibrate_controls(sources)
    lessons_by_verdict = {
        "accepted": 0,
        "partial": 0,
        "rejected": 0,
        "pending": 0,
    }
    accepted_records = 0
    failed_records = 0
    for lesson_id, source_text in sources.items():
        checkpoint_path = run_dir / "checkpoints" / f"{lesson_id}.json"
        if not checkpoint_path.is_file():
            lessons_by_verdict["pending"] += 1
            continue
        checkpoint = json.loads(checkpoint_path.read_text(encoding="utf-8"))
        if checkpoint.get("lesson") != lesson_id:
            raise ValueError(f"checkpoint lesson mismatch: {checkpoint_path}")
        verdict = checkpoint.get("verdict")
        if verdict not in {"accepted", "partial", "rejected"}:
            raise ValueError(f"invalid checkpoint verdict for {lesson_id}: {verdict!r}")
        lessons_by_verdict[verdict] += 1
        tasks = checkpoint.get("tasks")
        if not isinstance(tasks, list):
            raise ValueError(f"checkpoint tasks must be a list: {lesson_id}")
        checkpoint_accepted = 0
        checkpoint_failed = 0
        failed_indices: list[int] = []
        for index, task in enumerate(tasks):
            excerpt = task.get("excerpt") if isinstance(task, dict) else None
            if not isinstance(excerpt, str):
                raise ValueError(f"invalid task excerpt in {lesson_id} record {index}")
            stored_gate = task.get("provenance")
            if not isinstance(stored_gate, dict):
                raise ValueError(
                    f"missing stored provenance gate: {lesson_id} record {index}"
                )
            record_verdict = stored_gate.get("verdict")
            if record_verdict == "accepted":
                gate = verify_excerpt(source_text, excerpt)
                if gate["verdict"] != "accepted":
                    raise ValueError(
                        "accepted record no longer passes provenance: "
                        f"{lesson_id} record {index}"
                    )
                if (
                    stored_gate.get("normalized_match_offset")
                    != gate["normalized_match_offset"]
                ):
                    raise ValueError(
                        "stored match offset disagrees with gate: "
                        f"{lesson_id} record {index}"
                    )
                checkpoint_accepted += 1
                accepted_records += 1
                continue
            if record_verdict != "rejected":
                raise ValueError(
                    f"invalid stored provenance verdict: {lesson_id} record {index}"
                )
            record_failure = task.get("failure")
            if not isinstance(record_failure, dict) or not isinstance(
                record_failure.get("detail"), str
            ):
                raise ValueError(
                    f"rejected record lacks a failure reason: {lesson_id} record {index}"
                )
            checkpoint_failed += 1
            failed_records += 1
            failed_indices.append(index)

        if verdict == "accepted" and (
            checkpoint_accepted == 0 or checkpoint_failed != 0
        ):
            raise ValueError(f"accepted checkpoint is not all-accepted: {lesson_id}")
        if verdict == "partial" and (
            checkpoint_accepted == 0 or checkpoint_failed == 0
        ):
            raise ValueError(f"partial checkpoint is not mixed: {lesson_id}")
        if verdict == "rejected" and checkpoint_accepted != 0:
            raise ValueError(f"rejected checkpoint contains accepted records: {lesson_id}")

        expected_counts = {
            "accepted_records": checkpoint_accepted,
            "failed_records": checkpoint_failed,
        }
        if checkpoint.get("record_counts") != expected_counts:
            raise ValueError(f"checkpoint record counts disagree: {lesson_id}")
        if checkpoint.get("failed_indices") != failed_indices:
            raise ValueError(f"checkpoint failed indices disagree: {lesson_id}")

    return {
        "verdict": "passed",
        "run_dir": str(run_dir.resolve()),
        "source_fingerprints_verified": len(sources),
        "control_calibration": calibration,
        "lessons_by_verdict": lessons_by_verdict,
        "accepted_records": accepted_records,
        "failed_records": failed_records,
        "accepted_lessons_verified": lessons_by_verdict["accepted"],
        "partial_lessons_verified": lessons_by_verdict["partial"],
        "accepted_records_verified": accepted_records,
    }


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "run_dir",
        type=Path,
        help="harvest output directory containing manifest.json and checkpoints/",
    )
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    report = verify_run(parse_args(argv).run_dir)
    print(json.dumps(report, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except (ControlLeakError, OSError, ValueError, json.JSONDecodeError) as exc:
        sys.stderr.write(f"error: {exc}\n")
        raise SystemExit(1)
