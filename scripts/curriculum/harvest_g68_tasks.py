#!/usr/bin/env python3
"""Harvest provenance-gated student tasks from Grade 6-8 guide markdown.

Lessons run sequentially through the shared channel-preserving REALLMS client.
The runner writes a manifest before its first call and atomically checkpoints
each lesson. Parsed task records are accepted or rejected independently. Only
checkpoints with verdict ``accepted`` are resumed without a new call. A lesson
filter can restrict calls without narrowing the manifest or progress totals.
"""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import os
import re
import sys
import tempfile
from dataclasses import dataclass
from datetime import date, datetime
from pathlib import Path
from typing import Any, Callable
from urllib.parse import urlparse


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from scripts.curriculum.verify_g68_harvest import (  # noqa: E402
    CONTROL_EXCERPTS,
    calibrate_controls,
    cleaned_source_view,
    sha256_file,
    sha256_text,
    verify_excerpt,
)


SOURCE_ROOT = (
    ROOT
    / "hermes"
    / "app"
    / "runtime"
    / "experiments"
    / "gemma4_tutor"
    / "docling"
    / "full-output"
    / "TeacherLessonGuides"
)
LLM_PATH = ROOT / "hermes" / "app" / "llm.py"
RUN_VERSION = "g68_text_harvest_v2"
DEFAULT_MODEL = "glm-5.2"
DEFAULT_BUDGET = 32768
MINIMUM_BUDGET = 8192
PROMPT_VERSION = "g68_student_task_regions_cleaned_source_v3"
LESSON_DIRECTORY_RE = re.compile(
    r"^Grade(?P<grade>[678])-(?P<unit>\d+)-(?P<lesson>\d+)-Lesson-teacher-guide-$"
)
NUMBER_RE = re.compile(r"(?<!\w)[+-]?(?:\d+/\d+|\d+(?:,\d{3})*(?:\.\d+)?)(?!\w)")
EXACT_JSON_FENCE_RE = re.compile(r"```(?:json)?\n(.*)\n```", re.DOTALL)

SYSTEM_PROMPT = """You extract student task regions from one mathematics teacher guide.
Reply with raw JSON only, no code fences, no commentary. Quote the task text
verbatim from the supplied guide. Describe what the task asks students to do in plain,
non-evaluative language. Do not classify student ability or use deficit language."""

USER_PROMPT_TEMPLATE = """Read the cleaned lesson guide below and identify every region
that directly asks students to do mathematical work. Return exactly one JSON object with
this shape:
{{"tasks":[{{"excerpt":"verbatim task text","doing":"free-text description of what the task asks","numeric_operands":["each numeric operand exactly as printed, in order"]}}]}}

Rules:
- excerpt must be copied verbatim from the guide, including spelling, punctuation, and case.
- doing names the mathematical doing in free text; do not apply a taxonomy.
- numeric_operands is a JSON list of strings and includes every numeric operand present in
  the excerpt. Use [] when the excerpt has no numeric operands.
- Return at least one task record. Use no keys other than those shown.

<lesson id="{lesson}">
{source}
</lesson>
"""

PROMPT_VERSION_HASH = hashlib.sha256(
    (SYSTEM_PROMPT + "\0" + USER_PROMPT_TEMPLATE.replace("{lesson}", "<LESSON>").replace(
        "{source}", "<SOURCE>"
    )).encode("utf-8")
).hexdigest()


class SchemaRejection(ValueError):
    """Raised when final content is not the required strict JSON schema."""


@dataclass(frozen=True)
class LessonSource:
    lesson: str
    grade: int
    unit: int
    lesson_number: int
    source_file: Path
    raw_source_sha256: str
    cleaned_source_sha256: str
    source_text: str


@dataclass(frozen=True)
class RunConfig:
    grade: int
    unit: int | None
    limit: int | None
    model: str
    budget: int
    endpoint_class: str
    dry_run: bool


@dataclass(frozen=True)
class FixtureResult:
    """Channel-shaped dry-run result with no network behavior."""

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


Transport = Callable[[LessonSource, list[dict[str, str]]], Any]


def utc_timestamp() -> str:
    return datetime.now().astimezone().isoformat(timespec="seconds")


def atomic_write_json(path: Path, payload: dict[str, Any]) -> None:
    """Write one JSON object durably, then atomically replace its destination."""
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


def discover_lessons(
    grade: int,
    *,
    unit: int | None = None,
    limit: int | None = None,
    source_root: Path = SOURCE_ROOT,
) -> list[LessonSource]:
    grade_root = source_root / f"Grade{grade}"
    if not grade_root.is_dir():
        raise ValueError(f"guide directory not found: {grade_root}")
    lessons: list[LessonSource] = []
    seen: set[str] = set()
    for source_file in grade_root.glob("*/document.md"):
        match = LESSON_DIRECTORY_RE.fullmatch(source_file.parent.name)
        if match is None or int(match.group("grade")) != grade:
            continue
        lesson_unit = int(match.group("unit"))
        lesson_number = int(match.group("lesson"))
        if unit is not None and lesson_unit != unit:
            continue
        lesson_id = f"IM-G{grade}-U{lesson_unit}-L{lesson_number}"
        if lesson_id in seen:
            raise ValueError(f"duplicate guide for {lesson_id}")
        seen.add(lesson_id)
        raw_source_text = source_file.read_text(encoding="utf-8", errors="strict")
        cleaned_source_text = cleaned_source_view(source_file, raw_source_text)
        lessons.append(LessonSource(
            lesson=lesson_id,
            grade=grade,
            unit=lesson_unit,
            lesson_number=lesson_number,
            source_file=source_file.resolve(),
            raw_source_sha256=sha256_file(source_file),
            cleaned_source_sha256=sha256_text(cleaned_source_text),
            source_text=raw_source_text,
        ))
    lessons.sort(key=lambda item: (item.unit, item.lesson_number))
    if limit is not None:
        lessons = lessons[:limit]
    if not lessons:
        filter_note = f" unit {unit}" if unit is not None else ""
        raise ValueError(f"no Grade {grade}{filter_note} lesson guides found")
    return lessons


def build_messages(lesson: LessonSource) -> list[dict[str, str]]:
    source_text = cleaned_source_view(lesson.source_file, lesson.source_text)
    return [
        {"role": "system", "content": SYSTEM_PROMPT},
        {
            "role": "user",
            "content": USER_PROMPT_TEMPLATE.format(
                lesson=lesson.lesson,
                source=source_text,
            ),
        },
    ]


def parse_task_content(content: str) -> list[dict[str, Any]]:
    """Parse raw JSON or one exact, otherwise-unadorned JSON fence."""
    stripped = content.strip()
    fenced = EXACT_JSON_FENCE_RE.fullmatch(stripped)
    json_content = fenced.group(1) if fenced is not None else content
    try:
        payload = json.loads(json_content)
    except json.JSONDecodeError as exc:
        raise SchemaRejection(f"final content is not JSON: {exc}") from exc
    if not isinstance(payload, dict) or set(payload) != {"tasks"}:
        raise SchemaRejection("root must be an object with exactly the key 'tasks'")
    tasks = payload["tasks"]
    if not isinstance(tasks, list) or not tasks:
        raise SchemaRejection("tasks must be a nonempty list")
    validated: list[dict[str, Any]] = []
    for index, task in enumerate(tasks):
        if not isinstance(task, dict) or set(task) != {
            "excerpt",
            "doing",
            "numeric_operands",
        }:
            raise SchemaRejection(
                f"task {index} must contain exactly excerpt, doing, and numeric_operands"
            )
        excerpt = task["excerpt"]
        doing = task["doing"]
        operands = task["numeric_operands"]
        if not isinstance(excerpt, str) or not excerpt.strip():
            raise SchemaRejection(f"task {index} excerpt must be a nonblank string")
        if not isinstance(doing, str) or not doing.strip():
            raise SchemaRejection(f"task {index} doing must be a nonblank string")
        if not isinstance(operands, list) or any(
            not isinstance(operand, str) or not operand.strip() for operand in operands
        ):
            raise SchemaRejection(
                f"task {index} numeric_operands must be a list of nonblank strings"
            )
        validated.append({
            "excerpt": excerpt,
            "doing": doing,
            "numeric_operands": operands,
        })
    return validated


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
    lesson: LessonSource,
    result: Any,
    *,
    budget: int = DEFAULT_BUDGET,
    failure_kind: str,
    detail: str,
    tasks: list[dict[str, Any]] | None = None,
) -> dict[str, Any]:
    checkpoint_tasks = tasks or []
    accepted_records = sum(
        1
        for task in checkpoint_tasks
        if isinstance(task, dict)
        and isinstance(task.get("provenance"), dict)
        and task["provenance"].get("verdict") == "accepted"
    )
    failed_indices = [
        index
        for index, task in enumerate(checkpoint_tasks)
        if isinstance(task, dict)
        and isinstance(task.get("provenance"), dict)
        and task["provenance"].get("verdict") == "rejected"
    ]
    return {
        "run_version": RUN_VERSION,
        "lesson": lesson.lesson,
        "source_file": str(lesson.source_file),
        "raw_source_sha256": lesson.raw_source_sha256,
        "cleaned_source_sha256": lesson.cleaned_source_sha256,
        "budget": budget,
        "verdict": "rejected",
        "failure": {"kind": failure_kind, "detail": detail},
        "response": response_dict(result),
        "tasks": checkpoint_tasks,
        "record_counts": {
            "accepted_records": accepted_records,
            "failed_records": len(failed_indices),
        },
        "failed_indices": failed_indices,
        "checkpointed_at": utc_timestamp(),
    }


def evaluate_result(
    lesson: LessonSource,
    result: Any,
    *,
    budget: int = DEFAULT_BUDGET,
) -> dict[str, Any]:
    """Branch on outcome before final content can reach the JSON parser."""
    outcome = getattr(result, "outcome", None)
    if outcome in {"transport_error", "http_error"}:
        detail = getattr(result, "error", None) or f"REALLMS outcome: {outcome}"
        return rejected_checkpoint(
            lesson,
            result,
            budget=budget,
            failure_kind="transport",
            detail=str(detail),
        )
    if outcome == "truncated":
        return rejected_checkpoint(
            lesson,
            result,
            budget=budget,
            failure_kind="truncated",
            detail="finish_reason length; final content was not parsed",
        )
    if outcome == "empty_content":
        return rejected_checkpoint(
            lesson,
            result,
            budget=budget,
            failure_kind="empty",
            detail="final content was empty; reasoning content was not parsed",
        )
    if outcome != "ok":
        return rejected_checkpoint(
            lesson,
            result,
            budget=budget,
            failure_kind="transport",
            detail=f"unknown REALLMS outcome: {outcome!r}",
        )

    content = getattr(result, "content", "")
    try:
        tasks = parse_task_content(content)
    except SchemaRejection as exc:
        return rejected_checkpoint(
            lesson,
            result,
            budget=budget,
            failure_kind="schema_rejection",
            detail=str(exc),
        )

    gated_tasks: list[dict[str, Any]] = []
    rejected_indices: list[int] = []
    cleaned_source_text = cleaned_source_view(lesson.source_file, lesson.source_text)
    for index, task in enumerate(tasks):
        provenance = verify_excerpt(cleaned_source_text, task["excerpt"])
        record_failure = None
        if provenance["verdict"] != "accepted":
            rejected_indices.append(index)
            record_failure = {
                "kind": "provenance_rejection",
                "detail": (
                    "excerpt is not an exact substring of the cleaned source after "
                    "whitespace normalization"
                ),
            }
        gated_tasks.append({
            **task,
            "provenance": provenance,
            "failure": record_failure,
        })
    accepted_records = len(gated_tasks) - len(rejected_indices)
    if accepted_records == 0:
        return rejected_checkpoint(
            lesson,
            result,
            budget=budget,
            failure_kind="provenance_rejection",
            detail=f"exact source match failed for task indices {rejected_indices}",
            tasks=gated_tasks,
        )
    verdict = "partial" if rejected_indices else "accepted"
    failure = None
    if rejected_indices:
        failure = {
            "kind": "provenance_rejection",
            "detail": f"exact source match failed for task indices {rejected_indices}",
        }
    return {
        "run_version": RUN_VERSION,
        "lesson": lesson.lesson,
        "source_file": str(lesson.source_file),
        "raw_source_sha256": lesson.raw_source_sha256,
        "cleaned_source_sha256": lesson.cleaned_source_sha256,
        "budget": budget,
        "verdict": verdict,
        "failure": failure,
        "response": response_dict(result),
        "tasks": gated_tasks,
        "record_counts": {
            "accepted_records": accepted_records,
            "failed_records": len(rejected_indices),
        },
        "failed_indices": rejected_indices,
        "checkpointed_at": utc_timestamp(),
    }


def endpoint_class(api_url: str) -> str:
    parsed = urlparse(api_url)
    if parsed.path.endswith("/direct/v1/chat/completions"):
        return "reallms_direct_chat_completions"
    return "openai_compatible_chat_completions"


def manifest_payload(
    lessons: list[LessonSource], config: RunConfig, calibration: dict[str, Any]
) -> dict[str, Any]:
    return {
        "run_version": RUN_VERSION,
        "created_at": utc_timestamp(),
        "model_id": config.model,
        "endpoint_class": config.endpoint_class,
        "prompt_version": PROMPT_VERSION,
        "prompt_version_hash": PROMPT_VERSION_HASH,
        "budget": config.budget,
        "budget_history": [],
        "grade": config.grade,
        "unit_filter": config.unit,
        "limit": config.limit,
        "dry_run": config.dry_run,
        "worker_count": 1,
        "control_calibration": calibration,
        "lessons": [
            {
                "lesson": lesson.lesson,
                "source_file": str(lesson.source_file),
                "raw_source_sha256": lesson.raw_source_sha256,
                "cleaned_source_sha256": lesson.cleaned_source_sha256,
            }
            for lesson in lessons
        ],
    }


def ensure_manifest(
    output_dir: Path,
    lessons: list[LessonSource],
    config: RunConfig,
    calibration: dict[str, Any],
    *,
    selected_lessons: list[LessonSource] | None = None,
) -> dict[str, Any]:
    path = output_dir / "manifest.json"
    proposed = manifest_payload(lessons, config, calibration)
    if not path.is_file():
        atomic_write_json(path, proposed)
        return proposed
    existing = json.loads(path.read_text(encoding="utf-8"))
    comparison_keys = {
        "run_version",
        "model_id",
        "endpoint_class",
        "prompt_version",
        "prompt_version_hash",
        "grade",
        "unit_filter",
        "limit",
        "dry_run",
        "worker_count",
    }
    differences = sorted(
        key for key in comparison_keys if existing.get(key) != proposed.get(key)
    )
    existing_lessons = existing.get("lessons")
    proposed_lessons = proposed["lessons"]
    if existing_lessons != proposed_lessons:
        differences.append("lessons")

    if isinstance(existing_lessons, list):
        manifest_lessons = {
            item.get("lesson"): item
            for item in existing_lessons
            if isinstance(item, dict) and isinstance(item.get("lesson"), str)
        }
    else:
        manifest_lessons = {}
    for lesson in selected_lessons if selected_lessons is not None else lessons:
        selected_entry = {
            "lesson": lesson.lesson,
            "source_file": str(lesson.source_file),
            "raw_source_sha256": lesson.raw_source_sha256,
            "cleaned_source_sha256": lesson.cleaned_source_sha256,
        }
        if manifest_lessons.get(lesson.lesson) != selected_entry:
            if "lessons" not in differences:
                differences.append("lessons")
            break

    if differences:
        raise ValueError(
            "output directory belongs to an incompatible run; differing manifest "
            f"fields: {sorted(differences)}"
        )

    existing_budget = existing.get("budget")
    if not isinstance(existing_budget, int):
        raise ValueError("existing manifest budget must be an integer")
    if config.budget < existing_budget:
        raise ValueError(
            "output directory belongs to an incompatible run; requested budget "
            f"{config.budget} is below manifest budget {existing_budget}"
        )
    if config.budget == existing_budget:
        return existing

    history = existing.get("budget_history", [])
    if not isinstance(history, list):
        raise ValueError("existing manifest budget_history must be a list")
    raised = dict(existing)
    raised["budget"] = config.budget
    raised["budget_history"] = [
        *history,
        {
            "from": existing_budget,
            "to": config.budget,
            "raised_at": utc_timestamp(),
        },
    ]
    atomic_write_json(path, raised)
    return raised


def checkpoint_path(output_dir: Path, lesson: str) -> Path:
    return output_dir / "checkpoints" / f"{lesson}.json"


def compatible_checkpoint(path: Path, lesson: LessonSource) -> dict[str, Any] | None:
    if not path.is_file():
        return None
    payload = json.loads(path.read_text(encoding="utf-8"))
    if payload.get("lesson") != lesson.lesson:
        raise ValueError(f"checkpoint lesson mismatch: {path}")
    if (
        payload.get("run_version") == RUN_VERSION
        and payload.get("raw_source_sha256") == lesson.raw_source_sha256
        and payload.get("cleaned_source_sha256") == lesson.cleaned_source_sha256
    ):
        return payload
    return None


def accepted_checkpoint(path: Path, lesson: LessonSource) -> dict[str, Any] | None:
    payload = compatible_checkpoint(path, lesson)
    if payload is not None and payload.get("verdict") == "accepted":
        return payload
    return None


def write_progress(
    output_dir: Path,
    lessons: list[LessonSource],
    checkpoints: dict[str, dict[str, Any]],
) -> dict[str, Any]:
    counts: dict[str, int] = {
        "accepted": 0,
        "partial": 0,
        "rejected": 0,
        "pending": 0,
    }
    accepted_records = 0
    failed_records = 0
    failures: dict[str, int] = {}
    for lesson in lessons:
        checkpoint = checkpoints.get(lesson.lesson)
        if checkpoint is None:
            counts["pending"] += 1
            continue
        verdict = checkpoint.get("verdict", "rejected")
        counts[verdict if verdict in counts else "rejected"] += 1
        for task in checkpoint.get("tasks", []):
            if not isinstance(task, dict) or not isinstance(task.get("provenance"), dict):
                continue
            record_verdict = task["provenance"].get("verdict")
            if record_verdict == "accepted":
                accepted_records += 1
            elif record_verdict == "rejected":
                failed_records += 1
        failure = checkpoint.get("failure")
        if isinstance(failure, dict) and isinstance(failure.get("kind"), str):
            kind = failure["kind"]
            failures[kind] = failures.get(kind, 0) + 1
    payload = {
        "updated_at": utc_timestamp(),
        "total": len(lessons),
        **counts,
        "lessons_by_verdict": dict(counts),
        "accepted_records": accepted_records,
        "failed_records": failed_records,
        "failure_counts": dict(sorted(failures.items())),
    }
    atomic_write_json(output_dir / "progress.json", payload)
    return payload


def execute_run(
    lessons: list[LessonSource],
    output_dir: Path,
    config: RunConfig,
    transport: Transport,
    *,
    selected_lessons: list[LessonSource] | None = None,
) -> dict[str, Any]:
    """Run one sequential harvest; dependency injection keeps checks offline."""
    sources = {
        lesson.lesson: cleaned_source_view(lesson.source_file, lesson.source_text)
        for lesson in lessons
    }
    calibration = calibrate_controls(sources)
    lessons_to_process = lessons if selected_lessons is None else selected_lessons
    ensure_manifest(
        output_dir,
        lessons,
        config,
        calibration,
        selected_lessons=lessons_to_process,
    )

    checkpoints: dict[str, dict[str, Any]] = {}
    for lesson in lessons:
        existing = compatible_checkpoint(
            checkpoint_path(output_dir, lesson.lesson), lesson
        )
        if existing is not None:
            checkpoints[lesson.lesson] = existing
    write_progress(output_dir, lessons, checkpoints)

    for index, lesson in enumerate(lessons_to_process, 1):
        existing = checkpoints.get(lesson.lesson)
        if existing is not None and existing.get("verdict") == "accepted":
            print(
                f"[{index}/{len(lessons_to_process)}] {lesson.lesson}: "
                "resumed accepted checkpoint"
            )
            continue
        result = transport(lesson, build_messages(lesson))
        checkpoint = evaluate_result(lesson, result, budget=config.budget)
        atomic_write_json(checkpoint_path(output_dir, lesson.lesson), checkpoint)
        checkpoints[lesson.lesson] = checkpoint
        write_progress(output_dir, lessons, checkpoints)
        failure = checkpoint.get("failure")
        suffix = f" ({failure['kind']})" if isinstance(failure, dict) else ""
        print(
            f"[{index}/{len(lessons_to_process)}] {lesson.lesson}: "
            f"{checkpoint['verdict']}{suffix}"
        )
    return write_progress(output_dir, lessons, checkpoints)


def select_lessons(
    lessons: list[LessonSource], requested_ids: list[str] | None
) -> list[LessonSource]:
    """Return requested lessons in source order after the other filters run."""
    if requested_ids is None:
        return lessons
    requested = set(requested_ids)
    selected = [lesson for lesson in lessons if lesson.lesson in requested]
    found = {lesson.lesson for lesson in selected}
    missing = sorted(requested - found)
    if missing:
        raise ValueError(
            "requested lesson ids not found after grade, unit, and limit filters: "
            + ", ".join(missing)
        )
    return selected


def dry_run_result(lesson: LessonSource) -> FixtureResult:
    """Build a deterministic mixed reply for the offline partial-verdict walk."""
    cleaned_source_text = cleaned_source_view(lesson.source_file, lesson.source_text)
    excerpt = ""
    for raw_line in cleaned_source_text.splitlines():
        candidate = raw_line.strip()
        if candidate.startswith("#"):
            candidate = candidate.lstrip("#").strip()
        if 24 <= len(candidate) <= 500 and not candidate.startswith(("![", "|")):
            excerpt = candidate
            break
    if not excerpt:
        excerpt = re.sub(r"\s+", " ", cleaned_source_text).strip()[:500]
    if not excerpt:
        return FixtureResult(outcome="empty_content", content="")
    absent_excerpt = CONTROL_EXCERPTS[0]
    payload = {
        "tasks": [
            {
                "excerpt": excerpt,
                "doing": "Identify the mathematical doing requested in the fixture excerpt.",
                "numeric_operands": NUMBER_RE.findall(excerpt),
            },
            {
                "excerpt": absent_excerpt,
                "doing": "Exercise the failed-record path in the offline fixture.",
                "numeric_operands": NUMBER_RE.findall(absent_excerpt),
            },
        ]
    }
    return FixtureResult(outcome="ok", content=json.dumps(payload, ensure_ascii=False))


def load_llm_module() -> Any:
    spec = importlib.util.spec_from_file_location("hermes_reallms_g68", LLM_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot import shared client: {LLM_PATH}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--grade", type=int, choices=(6, 7, 8), required=True)
    parser.add_argument("--unit", type=int, help="optional numeric unit filter")
    parser.add_argument("--limit", type=int, help="maximum lessons after sorting and filtering")
    parser.add_argument(
        "--lessons",
        help="comma-separated lesson ids to process after grade, unit, and limit filters",
    )
    parser.add_argument(
        "--out",
        type=Path,
        help=(
            "run directory (default: hermes/app/runtime/experiments/"
            "g68_harvest/<local-date>/)"
        ),
    )
    parser.add_argument("--model", default=DEFAULT_MODEL)
    parser.add_argument(
        "--budget",
        type=int,
        default=DEFAULT_BUDGET,
        help=(
            f"completion-token budget, at least {MINIMUM_BUDGET} "
            f"(default: {DEFAULT_BUDGET})"
        ),
    )
    parser.add_argument("--timeout", type=int, default=600)
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="make no API calls; use a deterministic source-present fixture reply",
    )
    args = parser.parse_args(argv)
    if args.limit is not None and args.limit < 1:
        parser.error("--limit must be at least 1")
    if args.unit is not None and args.unit < 1:
        parser.error("--unit must be at least 1")
    if args.budget < MINIMUM_BUDGET:
        parser.error(f"--budget must be at least {MINIMUM_BUDGET}")
    if args.timeout < 1:
        parser.error("--timeout must be at least 1")
    if args.lessons is not None:
        lesson_ids = [lesson_id.strip() for lesson_id in args.lessons.split(",")]
        if not lesson_ids or any(not lesson_id for lesson_id in lesson_ids):
            parser.error("--lessons must be a comma-separated list of lesson ids")
        args.lessons = list(dict.fromkeys(lesson_ids))
    if args.out is None:
        args.out = (
            ROOT
            / "hermes"
            / "app"
            / "runtime"
            / "experiments"
            / "g68_harvest"
            / date.today().isoformat()
            / f"grade-{args.grade}"
        )
    return args


def run(args: argparse.Namespace) -> int:
    lessons = discover_lessons(args.grade, unit=args.unit, limit=args.limit)
    lessons_to_process = select_lessons(lessons, args.lessons)
    if args.dry_run:
        config = RunConfig(
            grade=args.grade,
            unit=args.unit,
            limit=args.limit,
            model=args.model,
            budget=args.budget,
            endpoint_class="dry_run_fixture",
            dry_run=True,
        )

        def transport(lesson: LessonSource, _messages: list[dict[str, str]]) -> FixtureResult:
            return dry_run_result(lesson)
    else:
        llm = load_llm_module()
        llm.load_dotenv(ROOT)
        api_url = llm.resolve_api_url()
        api_key = llm.require_api_key()
        ssl_ctx = llm.build_ssl_context()
        config = RunConfig(
            grade=args.grade,
            unit=args.unit,
            limit=args.limit,
            model=args.model,
            budget=args.budget,
            endpoint_class=endpoint_class(api_url),
            dry_run=False,
        )

        def transport(lesson: LessonSource, messages: list[dict[str, str]]) -> Any:
            _ = lesson
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

    summary = execute_run(
        lessons,
        args.out.resolve(),
        config,
        transport,
        selected_lessons=lessons_to_process,
    )
    print(json.dumps({"run_dir": str(args.out.resolve()), **summary}, ensure_ascii=False))
    return 0 if summary["rejected"] == 0 else 2


if __name__ == "__main__":
    try:
        raise SystemExit(run(parse_args(sys.argv[1:])))
    except (OSError, RuntimeError, ValueError, json.JSONDecodeError) as exc:
        sys.stderr.write(f"error: {exc}\n")
        raise SystemExit(1)
