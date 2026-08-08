#!/usr/bin/env python3
"""Recover G6-8 harvest checkpoints rejected by JSON string escaping.

The tool reads stored ``response.content`` values, repairs JSON serialization
inside string tokens, and sends the repaired text through the existing strict
task parser and provenance gate. It preserves the raw response in each
checkpoint and records an auditable repair receipt. No model call is made.
"""

from __future__ import annotations

import argparse
import copy
import hashlib
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from scripts.curriculum.harvest_g68_tasks import (  # noqa: E402
    EXACT_JSON_FENCE_RE,
    LessonSource,
    SchemaRejection,
    atomic_write_json,
    evaluate_result,
    parse_task_content,
    utc_timestamp,
    write_progress,
)
from scripts.curriculum.verify_g68_harvest import (  # noqa: E402
    verify_excerpt,
    verify_run,
)


DEFAULT_ROUTES = (
    ROOT
    / "docs"
    / "research"
    / "internal"
    / "2026-08-08-reject-repair-routes.json"
)
REJECTION_CLASS = "malformed_json_latex_escape"
REPAIR_VERSION = "g68_json_string_escape_v1"
JSON_SIMPLE_ESCAPES = frozenset('"\\/bfnrt')
HEX_DIGITS = frozenset("0123456789abcdefABCDEF")
NEXT_KEY_RE = re.compile(r',(?P<space>[ \t\r\n]+)"(?:[^"\\]|\\.)+"[ \t\r\n]*:')
LATEX_COMMANDS_WITH_JSON_ESCAPE_PREFIX = frozenset({
    "backslash",
    "bar",
    "begin",
    "beta",
    "bf",
    "binom",
    "bot",
    "bullet",
    "frac",
    "nabla",
    "neg",
    "neq",
    "not",
    "nu",
    "rangle",
    "rbrace",
    "rceil",
    "rfloor",
    "rho",
    "right",
    "rightarrow",
    "rm",
    "mathrm",
    "tan",
    "tanh",
    "tau",
    "text",
    "textbf",
    "textit",
    "theta",
    "times",
    "top",
})


@dataclass(frozen=True)
class RepairCounts:
    invalid_simple_escape: int = 0
    invalid_unicode_escape: int = 0
    latex_command_escape: int = 0
    dangling_backslash: int = 0

    @property
    def total(self) -> int:
        return (
            self.invalid_simple_escape
            + self.invalid_unicode_escape
            + self.latex_command_escape
            + self.dangling_backslash
        )

    def to_dict(self) -> dict[str, int]:
        return {
            "invalid_simple_escape": self.invalid_simple_escape,
            "invalid_unicode_escape": self.invalid_unicode_escape,
            "latex_command_escape": self.latex_command_escape,
            "dangling_backslash": self.dangling_backslash,
            "total": self.total,
        }


@dataclass(frozen=True)
class StoredResponse:
    """Expose repaired content to evaluation while retaining the raw response."""

    raw: dict[str, Any]
    content: str

    @property
    def outcome(self) -> Any:
        return self.raw.get("outcome")

    @property
    def error(self) -> Any:
        return self.raw.get("error")

    def to_dict(self) -> dict[str, Any]:
        return copy.deepcopy(self.raw)


def sha256_text(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def looks_like_dangling_backslash(content: str, quote_index: int) -> bool:
    """Return whether an escaped quote has the shape of a closing JSON quote.

    A genuine escaped quote stays untouched. The exceptional case requires the
    quote to be followed by a container close or by a comma, whitespace that
    includes a line break, and the next JSON object key. This is the stored
    pretty-printed boundary produced for IM-G6-U8-L2.
    """
    tail = content[quote_index + 1 :]
    stripped = tail.lstrip(" \t\r\n")
    if stripped.startswith(("}", "]")):
        return True
    match = NEXT_KEY_RE.match(tail)
    return match is not None and any(
        character in match.group("space") for character in "\r\n"
    )


def repair_json_string_escapes(content: str) -> tuple[str, RepairCounts]:
    """Double only malformed JSON backslashes found inside string tokens."""
    stripped = content.strip()
    fenced = EXACT_JSON_FENCE_RE.fullmatch(stripped)
    json_content = fenced.group(1) if fenced is not None else content

    output: list[str] = []
    inside_string = False
    index = 0
    invalid_simple_escape = 0
    invalid_unicode_escape = 0
    latex_command_escape = 0
    dangling_backslash = 0

    while index < len(json_content):
        character = json_content[index]
        if character == '"':
            inside_string = not inside_string
            output.append(character)
            index += 1
            continue
        if character != "\\" or not inside_string:
            output.append(character)
            index += 1
            continue

        if index + 1 >= len(json_content):
            output.append("\\\\")
            dangling_backslash += 1
            index += 1
            continue

        escaped = json_content[index + 1]
        if escaped == '"' and looks_like_dangling_backslash(
            json_content, index + 1
        ):
            output.append("\\\\")
            dangling_backslash += 1
            index += 1
            continue

        if escaped == "u":
            unicode_digits = json_content[index + 2 : index + 6]
            valid_unicode = len(unicode_digits) == 4 and all(
                digit in HEX_DIGITS for digit in unicode_digits
            )
            if not valid_unicode:
                output.append("\\\\")
                invalid_unicode_escape += 1
                index += 1
                continue
        elif escaped in "bfnrt":
            command_end = index + 1
            while (
                command_end < len(json_content)
                and json_content[command_end].isalpha()
                and json_content[command_end].isascii()
            ):
                command_end += 1
            command = json_content[index + 1 : command_end]
            if command in LATEX_COMMANDS_WITH_JSON_ESCAPE_PREFIX:
                output.append("\\\\")
                latex_command_escape += 1
                index += 1
                continue
        elif escaped not in JSON_SIMPLE_ESCAPES:
            output.append("\\\\")
            invalid_simple_escape += 1
            index += 1
            continue

        output.extend((character, escaped))
        index += 2

    repaired_json = "".join(output)
    if fenced is not None:
        fence_label = "json" if stripped.startswith("```json\n") else ""
        repaired = f"```{fence_label}\n{repaired_json}\n```"
    else:
        repaired = repaired_json
    return repaired, RepairCounts(
        invalid_simple_escape=invalid_simple_escape,
        invalid_unicode_escape=invalid_unicode_escape,
        latex_command_escape=latex_command_escape,
        dangling_backslash=dangling_backslash,
    )


def load_routes(path: Path) -> list[dict[str, Any]]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    lessons = payload.get("lessons")
    if not isinstance(lessons, list):
        raise ValueError("repair routes must contain a lessons list")
    selected: list[dict[str, Any]] = []
    seen: set[str] = set()
    for row in lessons:
        if not isinstance(row, dict) or row.get("rejection_class") != REJECTION_CLASS:
            continue
        lesson = row.get("id")
        grade = row.get("grade")
        if not isinstance(lesson, str) or not isinstance(grade, int):
            raise ValueError("serialization route rows require string ids and integer grades")
        if lesson in seen:
            raise ValueError(f"duplicate serialization route: {lesson}")
        seen.add(lesson)
        selected.append(row)
    if not selected:
        raise ValueError(f"no {REJECTION_CLASS} routes found: {path}")
    return selected


def load_manifest(run_dir: Path) -> tuple[dict[str, Any], dict[str, dict[str, Any]]]:
    path = run_dir / "manifest.json"
    manifest = json.loads(path.read_text(encoding="utf-8"))
    lessons = manifest.get("lessons")
    if not isinstance(lessons, list) or not lessons:
        raise ValueError(f"manifest lessons must be a nonempty list: {path}")
    by_id = {
        row["lesson"]: row
        for row in lessons
        if isinstance(row, dict) and isinstance(row.get("lesson"), str)
    }
    if len(by_id) != len(lessons):
        raise ValueError(f"manifest contains invalid or duplicate lesson rows: {path}")
    return manifest, by_id


def lesson_source(row: dict[str, Any], grade: int) -> LessonSource:
    lesson_id = row["lesson"]
    source_file = Path(str(row.get("source_file", "")))
    if not source_file.is_file():
        raise ValueError(f"source file not found for {lesson_id}: {source_file}")
    match = re.fullmatch(r"IM-G([678])-U(\d+)-L(\d+)", lesson_id)
    if match is None or int(match.group(1)) != grade:
        raise ValueError(f"lesson id and manifest grade disagree: {lesson_id}")
    return LessonSource(
        lesson=lesson_id,
        grade=grade,
        unit=int(match.group(2)),
        lesson_number=int(match.group(3)),
        source_file=source_file,
        raw_source_sha256=str(row.get("raw_source_sha256", "")),
        cleaned_source_sha256=str(row.get("cleaned_source_sha256", "")),
        source_text=source_file.read_text(encoding="utf-8", errors="strict"),
    )


def run_dirs_by_grade(run_dirs: list[Path]) -> dict[int, Path]:
    resolved: dict[int, Path] = {}
    for run_dir in run_dirs:
        manifest, _ = load_manifest(run_dir)
        grade = manifest.get("grade")
        if grade not in {6, 7, 8}:
            raise ValueError(f"manifest grade must be 6, 7, or 8: {run_dir}")
        if grade in resolved:
            raise ValueError(f"multiple run directories supplied for Grade {grade}")
        resolved[grade] = run_dir.resolve()
    return resolved


def existing_repair(checkpoint: dict[str, Any]) -> bool:
    receipt = checkpoint.get("serialization_repair")
    return (
        isinstance(receipt, dict)
        and receipt.get("serialization_repaired") is True
        and receipt.get("repair_version") == REPAIR_VERSION
    )


def repair_checkpoint(
    checkpoint: dict[str, Any],
    lesson: LessonSource,
) -> tuple[dict[str, Any], RepairCounts]:
    if checkpoint.get("lesson") != lesson.lesson:
        raise ValueError(f"checkpoint lesson mismatch: {lesson.lesson}")
    if checkpoint.get("verdict") != "rejected" or checkpoint.get("tasks") != []:
        raise ValueError(
            f"serialization source checkpoint must be recordless and rejected: {lesson.lesson}"
        )
    failure = checkpoint.get("failure")
    if not isinstance(failure, dict) or failure.get("kind") != "schema_rejection":
        raise ValueError(
            f"serialization source checkpoint must be a schema rejection: {lesson.lesson}"
        )
    response = checkpoint.get("response")
    if not isinstance(response, dict) or response.get("outcome") != "ok":
        raise ValueError(f"stored response is not replayable: {lesson.lesson}")
    raw_content = response.get("content")
    if not isinstance(raw_content, str) or not raw_content:
        raise ValueError(f"stored response content is empty: {lesson.lesson}")

    repaired_content, counts = repair_json_string_escapes(raw_content)
    if counts.total == 0:
        raise ValueError(f"no malformed JSON string escapes found: {lesson.lesson}")

    repaired = evaluate_result(
        lesson,
        StoredResponse(raw=copy.deepcopy(response), content=repaired_content),
        budget=int(checkpoint.get("budget", 0)),
    )
    accepted_records = repaired["record_counts"]["accepted_records"]
    if accepted_records == 0:
        detail = repaired.get("failure")
        raise ValueError(f"no records recovered for {lesson.lesson}: {detail}")
    if repaired.get("response") != response:
        raise ValueError(f"raw response was not preserved for {lesson.lesson}")

    for task in repaired["tasks"]:
        provenance = task.get("provenance")
        if not isinstance(provenance, dict):
            raise ValueError(f"missing evaluated provenance for {lesson.lesson}")
        provenance["serialization_repaired"] = True

    repaired["serialization_repair"] = {
        "serialization_repaired": True,
        "repair_version": REPAIR_VERSION,
        "source_field": "response.content",
        "raw_response_preserved": True,
        "original_content_sha256": sha256_text(raw_content),
        "repaired_content_sha256": sha256_text(repaired_content),
        "repair_counts": counts.to_dict(),
        "previous_failure": copy.deepcopy(failure),
        "repaired_from_checkpointed_at": checkpoint.get("checkpointed_at"),
        "repaired_at": utc_timestamp(),
    }
    return repaired, counts


def refresh_progress(run_dir: Path, manifest: dict[str, Any]) -> dict[str, Any]:
    grade = manifest["grade"]
    lessons = [lesson_source(row, grade) for row in manifest["lessons"]]
    checkpoints: dict[str, dict[str, Any]] = {}
    for lesson in lessons:
        path = run_dir / "checkpoints" / f"{lesson.lesson}.json"
        if path.is_file():
            checkpoints[lesson.lesson] = json.loads(path.read_text(encoding="utf-8"))
    return write_progress(run_dir, lessons, checkpoints)


def execute(
    routes_path: Path,
    run_dirs: list[Path],
    *,
    dry_run: bool,
) -> tuple[dict[str, Any], int]:
    routes = load_routes(routes_path)
    grade_runs = run_dirs_by_grade(run_dirs)
    missing_grades = sorted({row["grade"] for row in routes} - set(grade_runs))
    if missing_grades:
        raise ValueError(
            "missing run directories for grades: "
            + ", ".join(str(grade) for grade in missing_grades)
        )

    manifests: dict[int, dict[str, Any]] = {}
    manifest_lessons: dict[int, dict[str, dict[str, Any]]] = {}
    for grade, run_dir in grade_runs.items():
        manifests[grade], manifest_lessons[grade] = load_manifest(run_dir)

    proposed: list[tuple[Path, dict[str, Any]]] = []
    lesson_reports: list[dict[str, Any]] = []
    recovered_by_grade = {6: 0, 7: 0, 8: 0}
    unrecovered: list[dict[str, str]] = []

    for route in routes:
        lesson_id = route["id"]
        grade = route["grade"]
        run_dir = grade_runs[grade]
        manifest_row = manifest_lessons[grade].get(lesson_id)
        if manifest_row is None:
            raise ValueError(f"route lesson absent from Grade {grade} manifest: {lesson_id}")
        checkpoint_path = run_dir / "checkpoints" / f"{lesson_id}.json"
        checkpoint = json.loads(checkpoint_path.read_text(encoding="utf-8"))

        if existing_repair(checkpoint):
            recovered_by_grade[grade] += 1
            lesson_reports.append({
                "lesson": lesson_id,
                "grade": grade,
                "status": "already_repaired",
                "verdict": checkpoint.get("verdict"),
                "record_counts": checkpoint.get("record_counts"),
                "repair_counts": checkpoint["serialization_repair"].get(
                    "repair_counts"
                ),
            })
            continue

        try:
            repaired, counts = repair_checkpoint(
                checkpoint, lesson_source(manifest_row, grade)
            )
        except (KeyError, OSError, SchemaRejection, TypeError, ValueError) as exc:
            unrecovered.append({"lesson": lesson_id, "cause": str(exc)})
            lesson_reports.append({
                "lesson": lesson_id,
                "grade": grade,
                "status": "unrecovered",
                "cause": str(exc),
            })
            continue

        proposed.append((checkpoint_path, repaired))
        recovered_by_grade[grade] += 1
        lesson_reports.append({
            "lesson": lesson_id,
            "grade": grade,
            "status": "dry_run_recovered" if dry_run else "recovered",
            "verdict": repaired["verdict"],
            "record_counts": repaired["record_counts"],
            "repair_counts": counts.to_dict(),
        })

    verification: list[dict[str, Any]] = []
    progress: dict[str, Any] = {}
    if not dry_run:
        for checkpoint_path, checkpoint in proposed:
            atomic_write_json(checkpoint_path, checkpoint)
        for grade, run_dir in sorted(grade_runs.items()):
            progress[str(grade)] = refresh_progress(run_dir, manifests[grade])
            verification.append(verify_run(run_dir))

    summary = {
        "repair_version": REPAIR_VERSION,
        "dry_run": dry_run,
        "routes": str(routes_path.resolve()),
        "targeted_lessons": len(routes),
        "recovered_lessons": sum(recovered_by_grade.values()),
        "recovered_by_grade": {
            str(grade): recovered_by_grade[grade] for grade in sorted(recovered_by_grade)
        },
        "unrecovered_lessons": unrecovered,
        "progress": progress,
        "verification": verification,
        "lessons": lesson_reports,
    }
    return summary, 0 if not unrecovered else 2


def self_test() -> None:
    valid = (
        r'{"text":"quote: \"yes\"; slash: \\; controls: '
        r'\b\f\n\r\t; solidus: \/","unicode":"\u0041"}'
    )
    repaired, counts = repair_json_string_escapes(valid)
    assert repaired == valid and counts.total == 0
    assert json.loads(repaired)["unicode"] == "A"

    malformed = r'{"text":"$\frac{1}{2}$ and \u12G4"}'
    repaired, counts = repair_json_string_escapes(malformed)
    assert json.loads(repaired) == {"text": r"$\frac{1}{2}$ and \u12G4"}
    assert counts.latex_command_escape == 1
    assert counts.invalid_unicode_escape == 1

    escaped_quote = r'{"text":"He said \", then left."}'
    repaired, counts = repair_json_string_escapes(escaped_quote)
    assert repaired == escaped_quote and counts.total == 0

    dangling = '{\n  "text": "blank \\_\\",\n  "next": true\n}'
    repaired, counts = repair_json_string_escapes(dangling)
    assert json.loads(repaired) == {"text": "blank \\_\\", "next": True}
    assert counts.dangling_backslash == 1

    extra_root = r'{"tasks":[],"extra":"\frac"}'
    repaired, _ = repair_json_string_escapes(extra_root)
    try:
        parse_task_content(repaired)
    except SchemaRejection:
        pass
    else:
        raise AssertionError("serialization repair must not weaken the root schema")

    invented = verify_excerpt("Students compare 12 and 19.", "Invented excerpt.")
    assert invented["verdict"] == "rejected"
    print("PASS valid JSON escapes and escaped quotes remain unchanged")
    print("PASS malformed LaTeX and Unicode escapes become literal string content")
    print("PASS dangling pretty-printed string boundary repairs conservatively")
    print("PASS strict schema and unchanged verbatim gate still reject bad candidates")


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "run_dirs",
        nargs="*",
        type=Path,
        help="affected harvest run directories, one for each routed grade",
    )
    parser.add_argument("--routes", type=Path, default=DEFAULT_ROUTES)
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="evaluate stored responses without writing checkpoints or progress",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="run offline parser and gate regression fixtures",
    )
    args = parser.parse_args(argv)
    if not args.self_test and not args.run_dirs:
        parser.error("provide the affected run directories or use --self-test")
    return args


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    if args.self_test:
        self_test()
        if not args.run_dirs:
            return 0
    summary, exit_code = execute(
        args.routes.resolve(),
        [run_dir.resolve() for run_dir in args.run_dirs],
        dry_run=args.dry_run,
    )
    print(json.dumps(summary, indent=2, ensure_ascii=False))
    return exit_code


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except (json.JSONDecodeError, OSError, ValueError) as exc:
        sys.stderr.write(f"error: {exc}\n")
        raise SystemExit(1)
