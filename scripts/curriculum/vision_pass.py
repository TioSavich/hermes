#!/usr/bin/env python3
"""Run the provenance-gated Grade 6-7 vision recovery pass.

The worklist is rebuilt from the three text-harvest checkpoint directories and
the local Docling corpus.  The stable worklist is written before calibration,
manifest creation, or transport.  Each selected span then receives one
multimodal call, one atomic checkpoint, and a structured acceptance verdict.

``--dry-run`` uses a deterministic channel-shaped fixture and never loads an
API key or network client.  Accepted checkpoints resume without another call.
"""

from __future__ import annotations

import argparse
import base64
import bisect
import hashlib
import importlib.util
import json
import mimetypes
import os
import re
import sys
import tempfile
from dataclasses import dataclass
from datetime import date, datetime
from pathlib import Path
from typing import Any, Callable, Mapping
from urllib.parse import urlparse


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from scripts.curriculum.verify_g68_harvest import (  # noqa: E402
    calibrate_controls,
    cleaned_source_view,
    normalize_whitespace,
    sha256_file,
    sha256_text,
    verify_excerpt,
)
from scripts.research.extract_lesson_context import (  # noqa: E402
    picture_description_lines,
)


SOURCE_ROOT = (
    ROOT
    / "hermes/app/runtime/experiments/gemma4_tutor/docling/full-output"
    / "TeacherLessonGuides"
)
LLM_PATH = ROOT / "hermes/app/llm.py"
RUN_VERSION = "g67_vision_pass_v1"
WORKLIST_VERSION = "g67_image_bearing_failed_spans_v1"
PROMPT_VERSION = "g67_vision_verbatim_split_source_image_v1"
DEFAULT_MODEL = "gemma-4-31B-it"
DEFAULT_BUDGET = 8192
MINIMUM_BUDGET = 2500
REPORT_COUNTS = {"grade_6": 145, "grade_7": 58, "total": 203}

RUN_SPECS = (
    (
        "grade_6_base",
        6,
        ROOT / "hermes/app/runtime/experiments/g68_harvest/2026-08-05/grade-6-full",
    ),
    (
        "grade_6_retry",
        6,
        ROOT
        / "hermes/app/runtime/experiments/g68_harvest/2026-08-07"
        / "grade-6-retry-gemma31b",
    ),
    (
        "grade_7_full",
        7,
        ROOT
        / "hermes/app/runtime/experiments/g68_harvest/2026-08-07"
        / "grade-7-full-gemma31b",
    ),
)

# These are the report's reviewed boundary decisions.  They are not a cached
# worklist: every identifier must still resolve to a current failed record, and
# every other failed record must resolve to local source text and an image.  The
# exclusions preserve the report's figure-boundary and G7 spreadsheet/
# restaurant disambiguations without treating lexical figure language as a
# sufficient image test.
TEXT_ONLY_RECORDS: Mapping[str, tuple[int, ...]] = {
    "IM-G6-U1-L7": (9,),
    "IM-G6-U2-L1": (2,),
    "IM-G6-U2-L12": (0, 9),
    "IM-G6-U2-L14": (1,),
    "IM-G6-U2-L15": (7,),
    "IM-G6-U2-L16": (7,),
    "IM-G6-U2-L5": (4,),
    "IM-G6-U2-L9": (1,),
    "IM-G6-U3-L1": (6,),
    "IM-G6-U3-L14": (1,),
    "IM-G6-U3-L15": (2, 3),
    "IM-G6-U3-L17": (7,),
    "IM-G6-U3-L2": (21,),
    "IM-G6-U3-L4": (6,),
    "IM-G6-U3-L5": (6,),
    "IM-G6-U4-L11": (10, 11, 12),
    "IM-G6-U4-L12": (1,),
    "IM-G6-U4-L15": (17, 20, 21),
    "IM-G6-U4-L7": (10,),
    "IM-G6-U5-L14": (14,),
    "IM-G6-U5-L15": (2, 3),
    "IM-G6-U6-L12": (12,),
    "IM-G6-U6-L13": (4, 7),
    "IM-G6-U6-L2": (7,),
    "IM-G6-U6-L3": (4,),
    "IM-G6-U6-L6": (7,),
    "IM-G6-U7-L3": (2, 4),
    "IM-G6-U8-L10": (17,),
    "IM-G6-U8-L11": (0,),
    "IM-G6-U8-L16": (1,),
    "IM-G6-U8-L3": (7,),
    "IM-G6-U9-L5": (1,),
    "IM-G7-U2-L1": (8,),
    "IM-G7-U2-L10": (1,),
    "IM-G7-U2-L5": (6,),
    "IM-G7-U2-L7": (5, 6, 7),
    "IM-G7-U3-L9": (5,),
    "IM-G7-U4-L10": (2,),
    "IM-G7-U4-L12": (1,),
    "IM-G7-U4-L15": (5, 7),
    "IM-G7-U4-L2": (9,),
    "IM-G7-U4-L4": (11,),
    "IM-G7-U5-L14": (5,),
    "IM-G7-U5-L17": (2,),
    "IM-G7-U5-L2": (7,),
    "IM-G7-U6-L21": (8, 9),
    "IM-G7-U6-L4": (4,),
    "IM-G7-U6-L6": (4,),
    "IM-G7-U6-L7": (3,),
    "IM-G7-U8-L1": (0,),
    "IM-G7-U8-L12": (10,),
    "IM-G7-U8-L13": (9,),
    "IM-G7-U8-L15": (2,),
    "IM-G7-U8-L2": (13,),
    "IM-G7-U8-L3": (0, 6),
    "IM-G7-U8-L8": (7,),
    "IM-G7-U9-L1": (0, 5),
    "IM-G7-U9-L2": (9, 10, 13, 14),
}

IMAGE_MARKER_RE = re.compile(r"^!\[Image\]\(([^)]+)\)$")
PICTURE_DESCRIPTION_RE = re.compile(
    r"^!\[Picture \d+\]\(([^\n]+)\)\n\n(.*?)\n\n"
    r"Provenance: `[^`]+`$",
    re.MULTILINE | re.DOTALL,
)
IMAGE_DIGEST_RE = re.compile(r"_([0-9a-f]{64})\.[A-Za-z0-9]+$")
LESSON_RE = re.compile(r"^IM-G(?P<grade>[67])-U(?P<unit>\d+)-L(?P<lesson>\d+)$")
EXACT_JSON_FENCE_RE = re.compile(r"```(?:json)?\n(.*)\n```", re.DOTALL)

SYSTEM_PROMPT = """You transcribe one student mathematics task from supplied source text and attached source images.
Reply with raw JSON only, with no code fence or commentary. Preserve source wording,
punctuation, case, labels, and values. Do not repair, summarize, or paraphrase the task."""

USER_PROMPT_TEMPLATE = """Transcribe the task in this bounded source region. Return exactly one JSON object:
{{"source_excerpt":"verbatim curriculum-authored text copied from the source region", "image_excerpt":"verbatim task text or labels read only from the attached image(s), or an empty string", "doing":"plain non-evaluative description", "numeric_operands":["each numeric operand exactly as printed, in order"], "image_derived":true}}

Rules:
- source_excerpt contains only text copied verbatim from the supplied source region.
- image_excerpt contains only task-bearing text or labels read from the images.
- image_derived is true exactly when image_excerpt is nonempty.
- Do not silently rewrite source text into image_excerpt.
- Use no keys other than the five shown.

<span id="{span_id}" lesson="{lesson}">
{region_text}
</span>
"""

PROMPT_VERSION_HASH = hashlib.sha256(
    (
        SYSTEM_PROMPT
        + "\0"
        + USER_PROMPT_TEMPLATE.replace("{span_id}", "<SPAN>")
        .replace("{lesson}", "<LESSON>")
        .replace("{region_text}", "<REGION>")
    ).encode("utf-8")
).hexdigest()


class SchemaRejection(ValueError):
    """Raised when final content is not the strict vision-task schema."""


@dataclass(frozen=True)
class FixtureResult:
    outcome: str
    content: str
    reasoning_content: str = ""
    finish_reason: str | None = "stop"

    def to_dict(self) -> dict[str, Any]:
        return {
            "outcome": self.outcome,
            "content": self.content,
            "reasoning_content": self.reasoning_content,
            "finish_reason": self.finish_reason,
            "usage": {"fixture": True},
            "raw_response": {"fixture": True},
            "error": None,
            "status_code": None,
            "attempts": 1,
            "retryable": False,
        }


@dataclass(frozen=True)
class RunConfig:
    model: str
    budget: int
    endpoint_class: str
    dry_run: bool
    selected_span_ids: tuple[str, ...]


Transport = Callable[[dict[str, Any], list[dict[str, Any]]], Any]


def utc_timestamp() -> str:
    return datetime.now().astimezone().isoformat(timespec="seconds")


def relative(path: Path) -> str:
    return path.resolve().relative_to(ROOT).as_posix()


def atomic_write_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    file_descriptor, temporary_name = tempfile.mkstemp(
        prefix=f".{path.name}.", suffix=".tmp", dir=path.parent
    )
    temporary = Path(temporary_name)
    try:
        with os.fdopen(file_descriptor, "w", encoding="utf-8") as handle:
            json.dump(payload, handle, indent=2, ensure_ascii=False)
            handle.write("\n")
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary, path)
    finally:
        if temporary.exists():
            temporary.unlink()


def stable_hash(payload: Any) -> str:
    encoded = json.dumps(
        payload, ensure_ascii=False, sort_keys=True, separators=(",", ":")
    ).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def lesson_key(lesson: str) -> tuple[int, int, int]:
    match = LESSON_RE.fullmatch(lesson)
    if match is None:
        raise ValueError(f"invalid lesson id: {lesson!r}")
    return tuple(int(match.group(key)) for key in ("grade", "unit", "lesson"))


def text_only_pairs() -> set[tuple[str, int]]:
    return {
        (lesson, index)
        for lesson, indices in TEXT_ONLY_RECORDS.items()
        for index in indices
    }


def resolve_source(checkpoint: Mapping[str, Any], grade: int) -> Path:
    lesson = str(checkpoint.get("lesson", ""))
    match = LESSON_RE.fullmatch(lesson)
    if match is None or int(match.group("grade")) != grade:
        raise ValueError(f"checkpoint carries an invalid Grade {grade} lesson: {lesson!r}")
    recorded = Path(str(checkpoint.get("source_file", "")))
    if recorded.is_file():
        return recorded.resolve()
    fallback = (
        SOURCE_ROOT
        / f"Grade{grade}"
        / f"Grade{grade}-{int(match.group('unit'))}-{int(match.group('lesson'))}-Lesson-teacher-guide-"
        / "document.md"
    )
    if not fallback.is_file():
        raise ValueError(f"source guide not found for {lesson}: {fallback}")
    return fallback.resolve()


def normalized_line_index(lines: list[str]) -> tuple[str, list[int]]:
    joined = ""
    starts: list[int] = []
    for line in lines:
        starts.append(len(joined))
        joined += normalize_whitespace(line).lower() + " "
    return joined, starts


def locate_excerpt(excerpt: str, joined: str, starts: list[int]) -> tuple[int | None, str]:
    words = normalize_whitespace(excerpt).lower().split()
    for width in range(min(20, len(words)), 3, -1):
        hits: list[int] = []
        for start in range(len(words) - width + 1):
            offset = joined.find(" ".join(words[start : start + width]))
            if offset >= 0:
                hits.append(offset)
        if hits:
            offset = hits[len(hits) // 2]
            return bisect.bisect_right(starts, offset) - 1, f"exact_{width}_word_anchor"
    for word in words:
        if len(word) < 9:
            continue
        offset = joined.find(word)
        if offset >= 0:
            return bisect.bisect_right(starts, offset) - 1, "exact_distinct_word_anchor"
    return None, "ordered_record_fallback"


def description_index(source_file: Path) -> dict[str, str]:
    descriptions_path = source_file.with_name("picture_descriptions.md")
    if not descriptions_path.is_file():
        raise ValueError(f"picture descriptions not found: {descriptions_path}")
    descriptions: dict[str, str] = {}
    for match in PICTURE_DESCRIPTION_RE.finditer(
        descriptions_path.read_text(encoding="utf-8", errors="strict")
    ):
        digest = IMAGE_DIGEST_RE.search(match.group(1))
        if digest is not None:
            descriptions[digest.group(1)] = match.group(2)
    return descriptions


def image_exclusion(description: str) -> str | None:
    """Return the report-method exclusion class for known non-task art."""
    if not description:
        return None
    text = normalize_whitespace(description).lower()[:800]
    task_terms = re.search(
        r"\b(?:task|worksheet|problem|diagram|graph|table|equation|grid)\b", text
    )
    if "logo" in text and task_terms is None:
        return "logo"
    if re.search(
        r"no (?:visible |other )?mathematical (?:objects|content|representations)",
        text,
    ) and re.search(r"\b(?:task|worksheet|problem)\b", text) is None:
        return "non_mathematical_art"
    if re.search(r"\b(?:clock|timer|hourglass)\b", text) and task_terms is None:
        return "duration_icon"
    if re.search(
        r"\b(?:section heading|section title|label or icon|version number)\b", text
    ) and task_terms is None:
        return "heading"
    if (
        re.search(r"^the image (?:contains|features|provided is) a simple graphic", text)
        and re.search(r"\b(?:circle|square)\b", text)
        and re.search(r"\b(?:text|number|numeral)\b", text)
        and task_terms is None
    ):
        return "heading"
    return None


def source_image_rows(source_file: Path, lines: list[str]) -> list[dict[str, Any]]:
    descriptions = description_index(source_file)
    rows: list[dict[str, Any]] = []
    for line_number, line in enumerate(lines):
        marker = IMAGE_MARKER_RE.fullmatch(line)
        if marker is None:
            continue
        image_file = (source_file.parent / marker.group(1)).resolve()
        if not image_file.is_file():
            raise ValueError(f"inline image not found: {image_file}")
        digest_match = IMAGE_DIGEST_RE.search(marker.group(1))
        digest = digest_match.group(1) if digest_match is not None else sha256_file(image_file)
        description = descriptions.get(digest, "")
        rows.append({
            "line": line_number,
            "source_ref": marker.group(1),
            "file": relative(image_file),
            "sha256": sha256_file(image_file),
            "description_status": "described" if description else "not_described",
            "excluded_as": image_exclusion(description),
        })
    return rows


def record_positions(tasks: list[dict[str, Any]], lines: list[str]) -> list[tuple[int | None, str]]:
    joined, starts = normalized_line_index(lines)
    positions = [locate_excerpt(str(task.get("excerpt", "")), joined, starts) for task in tasks]
    known = [position for position, _ in positions if position is not None]
    if not known:
        return positions
    for index, (position, method) in enumerate(positions):
        if position is not None:
            continue
        before = next(
            (positions[candidate][0] for candidate in range(index - 1, -1, -1)
             if positions[candidate][0] is not None),
            None,
        )
        after = next(
            (positions[candidate][0] for candidate in range(index + 1, len(positions))
             if positions[candidate][0] is not None),
            None,
        )
        if before is not None and after is not None:
            inferred = before + round((after - before) / (index + 2))
        elif before is not None:
            inferred = before + 20
        elif after is not None:
            inferred = max(0, after - 20)
        else:
            inferred = len(lines) // 2
        positions[index] = (min(len(lines) - 1, inferred), method)
    return positions


def task_bounds(
    positions: list[tuple[int | None, str]], index: int, line_count: int
) -> tuple[int, int, int, str]:
    position, method = positions[index]
    if position is None:
        position = line_count // 2
    before = next(
        (positions[candidate][0] for candidate in range(index - 1, -1, -1)
         if positions[candidate][0] is not None and positions[candidate][0] <= position),
        None,
    )
    after = next(
        (positions[candidate][0] for candidate in range(index + 1, len(positions))
         if positions[candidate][0] is not None and positions[candidate][0] >= position),
        None,
    )
    start = (before + position) // 2 if before is not None else max(0, position - 35)
    end = (position + after) // 2 if after is not None else min(line_count - 1, position + 35)
    start = max(start, position - 60)
    end = min(end, position + 60)
    return start, max(start, end), position, method


def select_images(
    images: list[dict[str, Any]], start: int, end: int, position: int
) -> list[dict[str, Any]]:
    eligible = [image for image in images if image["excluded_as"] is None]
    if not eligible:
        raise ValueError("lesson has no inline images after logo/heading exclusions")
    in_region = [image for image in eligible if start <= image["line"] <= end]
    pool = in_region or eligible
    nearest_distance = min(abs(image["line"] - position) for image in pool)
    selected = [
        image
        for image in pool
        if abs(image["line"] - position) <= nearest_distance + 12
    ]
    selected.sort(key=lambda image: (image["line"], image["file"]))
    return selected[:6]


def region_text(
    source_file: Path,
    lines: list[str],
    start: int,
    end: int,
    selected_images: list[dict[str, Any]],
) -> tuple[str, str]:
    excluded = picture_description_lines(source_file, lines)
    if excluded is None:
        raise ValueError(f"picture descriptions cannot be separated: {source_file}")
    selected_lines = {image["line"]: Path(image["file"]).name for image in selected_images}
    rendered: list[str] = []
    for line_number in range(start, end + 1):
        if line_number in selected_lines:
            rendered.append(f"[Attached source image: {selected_lines[line_number]}]")
        elif line_number not in excluded:
            rendered.append(lines[line_number])
    text = "\n".join(rendered).strip()
    cleaned = cleaned_source_view(source_file, "\n".join(lines))
    fixture_excerpt = next(
        (
            line.strip()
            for line in rendered
            if line.strip()
            and not line.lstrip().startswith(("#", "[Attached source image:"))
            and verify_excerpt(cleaned, line.strip())["verdict"] == "accepted"
        ),
        None,
    )
    if fixture_excerpt is None:
        fixture_excerpt = next(
            (line.strip() for line in cleaned.splitlines() if len(line.strip()) >= 8),
            "",
        )
    if not text or not fixture_excerpt:
        raise ValueError(f"empty source region for {source_file}:{start + 1}-{end + 1}")
    return text, fixture_excerpt


def derive_worklist() -> dict[str, Any]:
    reviewed_text_only = text_only_pairs()
    seen_text_only: set[tuple[str, int]] = set()
    failed_counts = {"grade_6": 0, "grade_7": 0, "total": 0}
    spans: list[dict[str, Any]] = []
    input_runs: list[dict[str, Any]] = []
    failed_lessons_by_origin: dict[str, set[str]] = {}

    for origin, grade, run_dir in RUN_SPECS:
        checkpoints_dir = run_dir / "checkpoints"
        checkpoint_files = sorted(checkpoints_dir.glob("*.json"))
        if not checkpoint_files:
            raise ValueError(f"checkpoint directory is empty or missing: {checkpoints_dir}")
        origin_lessons: set[str] = set()
        origin_failed_lessons: set[str] = set()
        input_runs.append({
            "origin": origin,
            "run_dir": relative(run_dir),
            "checkpoint_count": len(checkpoint_files),
            "manifest_sha256": sha256_file(run_dir / "manifest.json"),
        })
        for checkpoint_file in checkpoint_files:
            checkpoint = json.loads(checkpoint_file.read_text(encoding="utf-8"))
            lesson = str(checkpoint.get("lesson", ""))
            if lesson in origin_lessons:
                raise ValueError(f"duplicate checkpoint lesson in {origin}: {lesson}")
            origin_lessons.add(lesson)
            source_file = resolve_source(checkpoint, grade)
            raw_source = source_file.read_text(encoding="utf-8", errors="strict")
            lines = raw_source.splitlines()
            actual_raw_hash = sha256_file(source_file)
            actual_cleaned_hash = sha256_text(cleaned_source_view(source_file, raw_source))
            if checkpoint.get("raw_source_sha256") != actual_raw_hash:
                raise ValueError(f"raw source fingerprint changed for {lesson}")
            if checkpoint.get("cleaned_source_sha256") != actual_cleaned_hash:
                raise ValueError(f"cleaned source fingerprint changed for {lesson}")
            tasks = checkpoint.get("tasks")
            failed_indices = checkpoint.get("failed_indices")
            if not isinstance(tasks, list) or not isinstance(failed_indices, list):
                raise ValueError(f"checkpoint tasks/failed_indices malformed: {checkpoint_file}")
            positions = record_positions(tasks, lines)
            images = source_image_rows(source_file, lines)
            for record_index in failed_indices:
                if not isinstance(record_index, int) or not 0 <= record_index < len(tasks):
                    raise ValueError(f"invalid failed record index in {checkpoint_file}: {record_index}")
                key = (lesson, record_index)
                origin_failed_lessons.add(lesson)
                failed_counts[f"grade_{grade}"] += 1
                failed_counts["total"] += 1
                if key in reviewed_text_only:
                    seen_text_only.add(key)
                    continue
                start, end, position, alignment = task_bounds(
                    positions, record_index, len(lines)
                )
                selected_images = select_images(images, start, end, position)
                start = min(start, *(image["line"] for image in selected_images))
                end = max(end, *(image["line"] for image in selected_images))
                source_region, fixture_excerpt = region_text(
                    source_file, lines, start, end, selected_images
                )
                span_id = f"{origin}__{lesson}__{record_index:02d}"
                spans.append({
                    "span_id": span_id,
                    "grade": grade,
                    "origin": origin,
                    "lesson": lesson,
                    "record_index": record_index,
                    "checkpoint_file": relative(checkpoint_file),
                    "checkpoint_sha256": sha256_file(checkpoint_file),
                    "source_file": relative(source_file),
                    "raw_source_sha256": actual_raw_hash,
                    "cleaned_source_sha256": actual_cleaned_hash,
                    "failed_excerpt": str(tasks[record_index].get("excerpt", "")),
                    "failed_doing": str(tasks[record_index].get("doing", "")),
                    "alignment": {
                        "method": alignment,
                        "anchor_line": position + 1,
                        "region_start_line": start + 1,
                        "region_end_line": end + 1,
                    },
                    "region_text": source_region,
                    "fixture_source_excerpt": fixture_excerpt,
                    "source_text_required": True,
                    "images": [
                        {key: value for key, value in image.items() if key != "line"}
                        for image in selected_images
                    ],
                })
        failed_lessons_by_origin[origin] = origin_failed_lessons

    missing_exclusions = sorted(reviewed_text_only - seen_text_only)
    if missing_exclusions:
        raise ValueError(
            "reviewed text-only records no longer resolve as failed records: "
            + ", ".join(f"{lesson}#{index:02d}" for lesson, index in missing_exclusions)
        )
    if failed_lessons_by_origin["grade_6_base"] & failed_lessons_by_origin["grade_6_retry"]:
        raise ValueError("Grade 6 base and retry failed-record lesson sets overlap")

    origin_order = {origin: index for index, (origin, _, _) in enumerate(RUN_SPECS)}
    spans.sort(
        key=lambda span: (
            origin_order[span["origin"]],
            lesson_key(span["lesson"]),
            span["record_index"],
        )
    )
    derived_counts = {
        "grade_6": sum(span["grade"] == 6 for span in spans),
        "grade_7": sum(span["grade"] == 7 for span in spans),
        "total": len(spans),
    }
    difference = {
        key: derived_counts[key] - REPORT_COUNTS[key]
        for key in ("grade_6", "grade_7", "total")
    }
    return {
        "worklist_version": WORKLIST_VERSION,
        "method": {
            "checkpoint_rule": "current failed_indices from the three declared runs",
            "alignment_rule": "longest available exact word anchor with ordered-record fallback",
            "image_rule": "nearby inline image markers after picture-description logo/heading exclusions",
            "boundary_review": "76 report-reviewed text-only record exclusions",
        },
        "report_counts": REPORT_COUNTS,
        "failed_record_counts": failed_counts,
        "derived_counts": derived_counts,
        "difference_from_report": difference,
        "input_runs": input_runs,
        "spans": spans,
    }


def write_worklist(output_dir: Path, worklist: dict[str, Any]) -> str:
    digest = stable_hash(worklist)
    atomic_write_json(output_dir / "worklist.json", worklist)
    return digest


def print_reconciliation(worklist: Mapping[str, Any]) -> None:
    derived = worklist["derived_counts"]
    report = worklist["report_counts"]
    print(
        "worklist counts: "
        f"derived={derived['total']} report={report['total']}; "
        f"grade6={derived['grade_6']}/{report['grade_6']}; "
        f"grade7={derived['grade_7']}/{report['grade_7']}"
    )
    difference = worklist["difference_from_report"]
    if any(difference.values()):
        print(f"worklist/report difference: {json.dumps(difference, sort_keys=True)}")


def parse_content(content: str) -> dict[str, Any]:
    stripped = content.strip()
    fenced = EXACT_JSON_FENCE_RE.fullmatch(stripped)
    json_content = fenced.group(1) if fenced is not None else content
    try:
        payload = json.loads(json_content)
    except json.JSONDecodeError as exc:
        raise SchemaRejection(f"final content is not JSON: {exc}") from exc
    keys = {
        "source_excerpt",
        "image_excerpt",
        "doing",
        "numeric_operands",
        "image_derived",
    }
    if not isinstance(payload, dict) or set(payload) != keys:
        raise SchemaRejection(f"root must contain exactly: {', '.join(sorted(keys))}")
    for key in ("source_excerpt", "image_excerpt", "doing"):
        if not isinstance(payload[key], str):
            raise SchemaRejection(f"{key} must be a string")
    if not payload["doing"].strip():
        raise SchemaRejection("doing must be nonblank")
    operands = payload["numeric_operands"]
    if not isinstance(operands, list) or any(
        not isinstance(operand, str) or not operand.strip() for operand in operands
    ):
        raise SchemaRejection("numeric_operands must be a list of nonblank strings")
    if not isinstance(payload["image_derived"], bool):
        raise SchemaRejection("image_derived must be boolean")
    if payload["image_derived"] != bool(payload["image_excerpt"].strip()):
        raise SchemaRejection("image_derived must exactly track nonblank image_excerpt")
    if not payload["source_excerpt"].strip() and not payload["image_excerpt"].strip():
        raise SchemaRejection("at least one verbatim excerpt must be nonblank")
    return payload


def response_dict(result: Any) -> dict[str, Any]:
    if hasattr(result, "to_dict"):
        value = result.to_dict()
        if isinstance(value, dict):
            return value
    return {
        "outcome": getattr(result, "outcome", "transport_error"),
        "error": "transport returned an object without to_dict()",
    }


def rejected_checkpoint(
    span: Mapping[str, Any],
    result: Any,
    *,
    budget: int,
    failure_kind: str,
    detail: str,
    task: Mapping[str, Any] | None = None,
    provenance: Mapping[str, Any] | None = None,
) -> dict[str, Any]:
    return {
        "run_version": RUN_VERSION,
        "span_id": span["span_id"],
        "lesson": span["lesson"],
        "record_index": span["record_index"],
        "source_file": span["source_file"],
        "raw_source_sha256": span["raw_source_sha256"],
        "cleaned_source_sha256": span["cleaned_source_sha256"],
        "image_sha256": [image["sha256"] for image in span["images"]],
        "budget": budget,
        "verdict": "rejected",
        "failure": {"kind": failure_kind, "detail": detail},
        "response": response_dict(result),
        "task": task,
        "provenance": provenance,
        "checkpointed_at": utc_timestamp(),
    }


def evaluate_result(
    span: Mapping[str, Any], result: Any, *, budget: int = DEFAULT_BUDGET
) -> dict[str, Any]:
    outcome = getattr(result, "outcome", None)
    if outcome in {"transport_error", "http_error"}:
        detail = getattr(result, "error", None) or f"REALLMS outcome: {outcome}"
        return rejected_checkpoint(
            span, result, budget=budget, failure_kind="transport", detail=str(detail)
        )
    if outcome == "truncated":
        return rejected_checkpoint(
            span,
            result,
            budget=budget,
            failure_kind="truncated",
            detail="finish_reason length; final content was not parsed",
        )
    if outcome == "empty_content":
        return rejected_checkpoint(
            span,
            result,
            budget=budget,
            failure_kind="empty",
            detail="final content was empty; reasoning content was not parsed",
        )
    if outcome != "ok":
        return rejected_checkpoint(
            span,
            result,
            budget=budget,
            failure_kind="transport",
            detail=f"unknown REALLMS outcome: {outcome!r}",
        )
    try:
        task = parse_content(getattr(result, "content", ""))
    except SchemaRejection as exc:
        return rejected_checkpoint(
            span,
            result,
            budget=budget,
            failure_kind="schema_rejection",
            detail=str(exc),
        )
    source_path = ROOT / span["source_file"]
    raw_source = source_path.read_text(encoding="utf-8", errors="strict")
    cleaned = cleaned_source_view(source_path, raw_source)
    source_gate = verify_excerpt(cleaned, task["source_excerpt"])
    provenance = {
        "source_text": source_gate,
        "image_derived": task["image_derived"],
        "image_gate": "attached source image; transcription retained for review",
    }
    if span.get("source_text_required") and not task["source_excerpt"].strip():
        return rejected_checkpoint(
            span,
            result,
            budget=budget,
            failure_kind="provenance_rejection",
            detail="source-bearing span returned an empty source_excerpt",
            task=task,
            provenance=provenance,
        )
    if task["source_excerpt"].strip() and source_gate["verdict"] != "accepted":
        return rejected_checkpoint(
            span,
            result,
            budget=budget,
            failure_kind="provenance_rejection",
            detail=(
                "source_excerpt is not an exact substring of cleaned source after "
                "whitespace normalization"
            ),
            task=task,
            provenance=provenance,
        )
    return {
        "run_version": RUN_VERSION,
        "span_id": span["span_id"],
        "lesson": span["lesson"],
        "record_index": span["record_index"],
        "source_file": span["source_file"],
        "raw_source_sha256": span["raw_source_sha256"],
        "cleaned_source_sha256": span["cleaned_source_sha256"],
        "image_sha256": [image["sha256"] for image in span["images"]],
        "budget": budget,
        "verdict": "accepted",
        "failure": None,
        "response": response_dict(result),
        "task": task,
        "provenance": provenance,
        "checkpointed_at": utc_timestamp(),
    }


def image_data_url(path: Path) -> str:
    mime_type = mimetypes.guess_type(path.name)[0] or "application/octet-stream"
    encoded = base64.b64encode(path.read_bytes()).decode("ascii")
    return f"data:{mime_type};base64,{encoded}"


def build_messages(span: Mapping[str, Any]) -> list[dict[str, Any]]:
    content: list[dict[str, Any]] = [{
        "type": "text",
        "text": USER_PROMPT_TEMPLATE.format(
            span_id=span["span_id"],
            lesson=span["lesson"],
            region_text=span["region_text"],
        ),
    }]
    for image in span["images"]:
        content.append({
            "type": "image_url",
            "image_url": {"url": image_data_url(ROOT / image["file"])},
        })
    return [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": content},
    ]


def dry_run_result(span: Mapping[str, Any]) -> FixtureResult:
    payload = {
        "source_excerpt": span["fixture_source_excerpt"],
        "image_excerpt": "",
        "doing": "Retain the mathematical doing requested in the fixture source line.",
        "numeric_operands": re.findall(
            r"(?<!\w)[+-]?(?:\d+/\d+|\d+(?:,\d{3})*(?:\.\d+)?)(?!\w)",
            span["fixture_source_excerpt"],
        ),
        "image_derived": False,
    }
    return FixtureResult(outcome="ok", content=json.dumps(payload, ensure_ascii=False))


def checkpoint_path(output_dir: Path, span_id: str) -> Path:
    safe_name = re.sub(r"[^A-Za-z0-9_.-]+", "_", span_id)
    return output_dir / "checkpoints" / f"{safe_name}.json"


def compatible_checkpoint(
    path: Path, span: Mapping[str, Any]
) -> dict[str, Any] | None:
    if not path.is_file():
        return None
    payload = json.loads(path.read_text(encoding="utf-8"))
    if payload.get("span_id") != span["span_id"]:
        raise ValueError(f"checkpoint span mismatch: {path}")
    if (
        payload.get("run_version") == RUN_VERSION
        and payload.get("raw_source_sha256") == span["raw_source_sha256"]
        and payload.get("cleaned_source_sha256") == span["cleaned_source_sha256"]
        and payload.get("image_sha256") == [
            image["sha256"] for image in span["images"]
        ]
    ):
        return payload
    return None


def write_progress(
    output_dir: Path,
    selected: list[dict[str, Any]],
    checkpoints: Mapping[str, Mapping[str, Any]],
) -> dict[str, Any]:
    counts = {"accepted": 0, "rejected": 0, "pending": 0}
    failures: dict[str, int] = {}
    image_derived = 0
    for span in selected:
        checkpoint = checkpoints.get(span["span_id"])
        if checkpoint is None:
            counts["pending"] += 1
            continue
        verdict = checkpoint.get("verdict")
        counts[verdict if verdict in {"accepted", "rejected"} else "rejected"] += 1
        task = checkpoint.get("task")
        if isinstance(task, dict) and task.get("image_derived") is True:
            image_derived += 1
        failure = checkpoint.get("failure")
        if isinstance(failure, dict) and isinstance(failure.get("kind"), str):
            kind = failure["kind"]
            failures[kind] = failures.get(kind, 0) + 1
    payload = {
        "updated_at": utc_timestamp(),
        "total": len(selected),
        **counts,
        "image_derived": image_derived,
        "failure_counts": dict(sorted(failures.items())),
    }
    atomic_write_json(output_dir / "progress.json", payload)
    return payload


def endpoint_class(api_url: str) -> str:
    parsed = urlparse(api_url)
    if parsed.path.endswith("/direct/v1/chat/completions"):
        return "reallms_direct_chat_completions"
    return "openai_compatible_chat_completions"


def manifest_payload(
    worklist: Mapping[str, Any], worklist_hash: str, config: RunConfig, calibration: Mapping[str, Any]
) -> dict[str, Any]:
    return {
        "run_version": RUN_VERSION,
        "created_at": utc_timestamp(),
        "model_id": config.model,
        "endpoint_class": config.endpoint_class,
        "prompt_version": PROMPT_VERSION,
        "prompt_version_hash": PROMPT_VERSION_HASH,
        "budget": config.budget,
        "dry_run": config.dry_run,
        "worker_count": 1,
        "worklist_sha256": worklist_hash,
        "worklist_counts": worklist["derived_counts"],
        "report_counts": worklist["report_counts"],
        "difference_from_report": worklist["difference_from_report"],
        "selected_span_ids": list(config.selected_span_ids),
        "control_calibration": dict(calibration),
    }


def ensure_manifest(
    output_dir: Path,
    worklist: Mapping[str, Any],
    worklist_hash: str,
    config: RunConfig,
    calibration: Mapping[str, Any],
) -> dict[str, Any]:
    path = output_dir / "manifest.json"
    proposed = manifest_payload(worklist, worklist_hash, config, calibration)
    if not path.is_file():
        atomic_write_json(path, proposed)
        return proposed
    existing = json.loads(path.read_text(encoding="utf-8"))
    keys = {
        "run_version",
        "model_id",
        "endpoint_class",
        "prompt_version",
        "prompt_version_hash",
        "budget",
        "dry_run",
        "worker_count",
        "worklist_sha256",
        "selected_span_ids",
    }
    differences = sorted(key for key in keys if existing.get(key) != proposed.get(key))
    if differences:
        raise ValueError(
            "output directory belongs to an incompatible run; differing manifest "
            f"fields: {differences}"
        )
    return existing


def execute_run(
    worklist: dict[str, Any],
    worklist_hash: str,
    output_dir: Path,
    config: RunConfig,
    transport: Transport,
) -> dict[str, Any]:
    spans_by_id = {span["span_id"]: span for span in worklist["spans"]}
    selected = [spans_by_id[span_id] for span_id in config.selected_span_ids]
    sources = {
        span["span_id"]: cleaned_source_view(
            ROOT / span["source_file"],
            (ROOT / span["source_file"]).read_text(encoding="utf-8", errors="strict"),
        )
        for span in selected
    }
    calibration = calibrate_controls(sources)
    ensure_manifest(output_dir, worklist, worklist_hash, config, calibration)
    checkpoints: dict[str, dict[str, Any]] = {}
    for span in selected:
        existing = compatible_checkpoint(
            checkpoint_path(output_dir, span["span_id"]), span
        )
        if existing is not None:
            checkpoints[span["span_id"]] = existing
    write_progress(output_dir, selected, checkpoints)
    for index, span in enumerate(selected, 1):
        existing = checkpoints.get(span["span_id"])
        if existing is not None and existing.get("verdict") == "accepted":
            print(f"[{index}/{len(selected)}] {span['span_id']}: resumed accepted checkpoint")
            continue
        messages = build_messages(span)
        result = transport(span, messages)
        checkpoint = evaluate_result(span, result, budget=config.budget)
        atomic_write_json(checkpoint_path(output_dir, span["span_id"]), checkpoint)
        checkpoints[span["span_id"]] = checkpoint
        write_progress(output_dir, selected, checkpoints)
        failure = checkpoint.get("failure")
        suffix = f" ({failure['kind']})" if isinstance(failure, dict) else ""
        print(
            f"[{index}/{len(selected)}] {span['span_id']}: "
            f"{checkpoint['verdict']}{suffix}"
        )
    return write_progress(output_dir, selected, checkpoints)


def load_llm_module() -> Any:
    spec = importlib.util.spec_from_file_location("hermes_reallms_vision_pass", LLM_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot import shared client: {LLM_PATH}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def selected_span_ids(
    worklist: Mapping[str, Any], requested: list[str] | None, limit: int | None
) -> tuple[str, ...]:
    all_ids = [span["span_id"] for span in worklist["spans"]]
    if requested is not None:
        requested_set = set(requested)
        missing = sorted(requested_set - set(all_ids))
        if missing:
            raise ValueError("requested span ids not found: " + ", ".join(missing))
        all_ids = [span_id for span_id in all_ids if span_id in requested_set]
    if limit is not None:
        all_ids = all_ids[:limit]
    if not all_ids:
        raise ValueError("no spans selected")
    return tuple(all_ids)


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", type=Path, help="run directory")
    parser.add_argument("--model", default=DEFAULT_MODEL)
    parser.add_argument("--budget", type=int, default=DEFAULT_BUDGET)
    parser.add_argument("--timeout", type=int, default=600)
    parser.add_argument("--limit", type=int, help="select the first N spans")
    parser.add_argument("--spans", help="comma-separated stable span ids")
    parser.add_argument("--derive-only", action="store_true")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="make no API calls; use deterministic source-present fixture replies",
    )
    args = parser.parse_args(argv)
    if args.budget < MINIMUM_BUDGET:
        parser.error(f"--budget must be at least {MINIMUM_BUDGET}")
    if args.timeout < 1:
        parser.error("--timeout must be at least 1")
    if args.limit is not None and args.limit < 1:
        parser.error("--limit must be at least 1")
    if args.spans is not None:
        values = [value.strip() for value in args.spans.split(",")]
        if not values or any(not value for value in values):
            parser.error("--spans must be a comma-separated list of span ids")
        args.spans = list(dict.fromkeys(values))
    if args.out is None:
        args.out = (
            ROOT
            / "hermes/app/runtime/experiments/vision_pass"
            / date.today().isoformat()
            / ("dry-run" if args.dry_run else "gemma31b")
        )
    return args


def run(args: argparse.Namespace) -> int:
    output_dir = args.out.resolve()
    worklist = derive_worklist()
    worklist_hash = write_worklist(output_dir, worklist)
    print_reconciliation(worklist)
    if args.derive_only:
        print(json.dumps({"run_dir": str(output_dir), "worklist_sha256": worklist_hash}))
        return 0
    selection = selected_span_ids(worklist, args.spans, args.limit)
    if args.dry_run:
        config = RunConfig(
            model=args.model,
            budget=args.budget,
            endpoint_class="dry_run_fixture",
            dry_run=True,
            selected_span_ids=selection,
        )

        def transport(
            span: dict[str, Any], messages: list[dict[str, Any]]
        ) -> FixtureResult:
            image_parts = messages[1]["content"][1:]
            if len(image_parts) != len(span["images"]):
                raise RuntimeError("dry-run multimodal message omitted an image")
            return dry_run_result(span)

    else:
        llm = load_llm_module()
        llm.load_dotenv(ROOT)
        api_url = llm.resolve_api_url()
        api_key = llm.require_api_key()
        ssl_ctx = llm.build_ssl_context()
        config = RunConfig(
            model=args.model,
            budget=args.budget,
            endpoint_class=endpoint_class(api_url),
            dry_run=False,
            selected_span_ids=selection,
        )

        def transport(
            _span: dict[str, Any], messages: list[dict[str, Any]]
        ) -> Any:
            return llm.call_api_messages_result(
                messages,
                api_key=api_key,
                api_url=api_url,
                model=args.model,
                ssl_ctx=ssl_ctx,
                retries=3,
                timeout=args.timeout,
                max_tokens=args.budget,
            )

    summary = execute_run(worklist, worklist_hash, output_dir, config, transport)
    print(json.dumps({"run_dir": str(output_dir), **summary}, ensure_ascii=False))
    return 0 if summary["rejected"] == 0 else 2


if __name__ == "__main__":
    try:
        raise SystemExit(run(parse_args(sys.argv[1:])))
    except (OSError, RuntimeError, ValueError, json.JSONDecodeError) as exc:
        sys.stderr.write(f"error: {exc}\n")
        raise SystemExit(1)
