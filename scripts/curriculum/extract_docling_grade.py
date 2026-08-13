#!/usr/bin/env python3
"""Extract checkpointed Docling task and guide-question facts for one grade.

The extractor copies curriculum text from the line-addressable guide. It never
uses inline Granite descriptions as authored text. A task region whose text is
absent, or whose mathematical expression was dropped, stays present with a
named blocker and the available image-description provenance.
"""

from __future__ import annotations

import argparse
from collections import Counter, defaultdict
from dataclasses import asdict, dataclass
import hashlib
import json
import os
from pathlib import Path
import re
import sys
import tempfile
import time
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
from scripts.curriculum import vision_statement_contract  # noqa: E402


SOURCE_ROOT = (
    ROOT
    / "hermes/app/runtime/experiments/gemma4_tutor/docling/full-output"
    / "TeacherLessonGuides"
)
GENERATED = ROOT / "curriculum/im/generated"
DEFAULT_CHECKPOINT_ROOT = (
    ROOT / "hermes/app/runtime/experiments/docling_grade_extraction"
)
DEFAULT_QUESTION_CHECKPOINT_ROOT = (
    ROOT / "hermes/app/runtime/experiments/docling_grade_questions"
)
WIDENED_VISION_CHECKPOINT_DIR = (
    ROOT
    / "hermes/app/runtime/experiments/docling_grade8_recovery/vision_widened/checkpoints"
)
RUN_VERSION = "docling_grade_extraction_v1"
IMAGE_RE = re.compile(r"^!\[Image\]\((document_artifacts/[^)]+)\)$")
PICTURE_MODEL_RE = re.compile(r"Provenance: `([^`]+)`")
SIBLING_BULLET_RE = re.compile(
    r"^- (?:Student Response|Activity Synthesis|Lesson Synthesis|Launch|"
    r"Instructional Routines|Access for |Building on Student Thinking|"
    r"Responding to Student Thinking|Are You Ready for More\?)"
)
MISSING_EXPRESSION_PATTERNS = (
    re.compile(r"(?<!\.)\s+[.,;:](?!\.)"),
    re.compile(r",\s*,"),
    re.compile(
        r"\b(?:equation|expression|function|formula|ratio|angle|line|point|"
        r"variable|value)\s+(?:is|was|of|for|by|and|or)?\s*[.,;:?]",
        re.IGNORECASE,
    ),
    re.compile(r"\b(?:given|represented|defined) by\s*[.,;:?]", re.IGNORECASE),
    re.compile(r"\baspect ratio(?: of| is)?\s*[.,;:?]", re.IGNORECASE),
    re.compile(
        r"\b(?:graph|line|triangle|equation|expression|function|point|angle) "
        r"of\s+(?:is|are|and|or|[.,;:?])",
        re.IGNORECASE,
    ),
    re.compile(
        r"\b(?:triangle|line|angle|point|graph|function)\s+(?:and|or)\s+"
        r"(?:triangle|line|angle|point|graph|function)\s+(?:is|are)\b",
        re.IGNORECASE,
    ),
    re.compile(r"\b(?:where|let)\s+(?:is|are|represent|represents)\b", re.IGNORECASE),
    re.compile(r"\$\$\s*[-\u2212]?\s*\$\$"),
    re.compile(r"\b[a-f]\.\s*(?=(?:[a-f]\.\s*)+|[,;?])", re.IGNORECASE),
    re.compile(r"\ban?\s+-[A-Za-z]+\b", re.IGNORECASE),
    re.compile(r"\bnearest\s+of\b", re.IGNORECASE),
    re.compile(
        r"\b(?:triangle|line|angle|point|graph|function|figure)\s+"
        r"(?:and|to|from)\s+(?:one|two|another|the|triangle|line|angle|point|"
        r"graph|function|figure)\b",
        re.IGNORECASE,
    ),
)


@dataclass(frozen=True)
class QuestionGuide:
    code: str
    path: Path


def normalize_grade(value: str | int) -> str:
    token = str(value).strip().lower()
    if token in {"k", "kindergarten"}:
        return "k"
    if token.isdigit() and 1 <= int(token) <= 8:
        return str(int(token))
    raise ValueError(f"unsupported grade: {value}")


def grade_code_token(grade: str | int) -> str:
    token = normalize_grade(grade)
    return "K" if token == "k" else token


def grade_directory(grade: str | int) -> str:
    token = normalize_grade(grade)
    return "Kindergarten" if token == "k" else f"Grade{token}"


def _load_modules():
    from scripts.curriculum import compile_action_mappings as compiler
    from scripts.research import extract_lesson_context as context

    return compiler, context


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def atomic_write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    temporary = Path(name)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            handle.write(text)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary, path)
    finally:
        if temporary.exists():
            temporary.unlink()


def atomic_write_json(path: Path, value: Any) -> None:
    atomic_write(path, json.dumps(value, indent=2, ensure_ascii=False) + "\n")


def _prolog_atom(value: str) -> str:
    if re.fullmatch(r"[a-z][A-Za-z0-9_]*", value):
        return value
    return "'" + value.replace("'", "''") + "'"


def _prolog_string(value: str) -> str:
    return json.dumps(value, ensure_ascii=True)


def _task_heading_indices(lines: list[str], context: Any) -> list[int]:
    body_start = next(
        (index for index, line in enumerate(lines) if line == "## Activity Narrative"),
        None,
    )
    if body_start is None:
        return []
    body_end = next(
        (
            index
            for index, line in enumerate(lines[body_start:], body_start)
            if context.MIDDLE_CUTOFF_RE.fullmatch(line)
        ),
        len(lines),
    )
    return [
        index
        for index in range(body_start, body_end)
        if context.MIDDLE_TASK_RE.fullmatch(lines[index])
    ]


def _section_end(
    lines: list[str], start: int, body_end: int, excluded: set[int]
) -> int:
    index = start + 1
    while index < body_end:
        if index not in excluded and (
            lines[index].startswith("## ") or SIBLING_BULLET_RE.match(lines[index])
        ):
            break
        index += 1
    return index


def _picture_model(path: Path) -> str:
    text = path.read_text(encoding="utf-8")
    models = sorted(set(PICTURE_MODEL_RE.findall(text)))
    return ", ".join(models) if models else "unknown"


def _missing_expression(text: str) -> bool:
    return any(pattern.search(text) for pattern in MISSING_EXPRESSION_PATTERNS)


def _visual_provenance(
    guide: Path, lines: list[str], start: int, end: int
) -> list[dict[str, str]]:
    descriptions = guide.with_name("picture_descriptions.md")
    model = _picture_model(descriptions)
    rows = []
    for raw in lines[start:end]:
        match = IMAGE_RE.fullmatch(raw.strip())
        if match is None:
            continue
        asset = guide.parent / match.group(1)
        rows.append(
            {
                "asset": asset.relative_to(ROOT).as_posix(),
                "description": descriptions.relative_to(ROOT).as_posix(),
                "model": model,
            }
        )
    return rows


def _task_record(
    doc: Any,
    number: int,
    heading_index: int,
    section_end: int,
    span: Any | None,
) -> dict[str, Any]:
    lines = doc.path.read_text(encoding="utf-8").splitlines()
    visuals = _visual_provenance(doc.path, lines, heading_index + 1, section_end)
    if span is None:
        excerpt = lines[heading_index].removeprefix("## ").removeprefix("- ").strip()
        line_start = line_end = heading_index + 1
        status = "blocked_missing_visual" if visuals else "blocked_layout"
        blocker = (
            "curriculum_text_absent_after_docling"
            if visuals
            else "task_section_contains_no_curriculum_text"
        )
    else:
        excerpt = span.text
        line_start = span.lines[0][0]
        line_end = span.lines[-1][0]
        if _missing_expression(excerpt):
            status = "blocked_missing_visual" if visuals else "blocked_layout"
            blocker = (
                "expression_missing_from_markdown"
                if visuals
                else "expression_missing_without_visual"
            )
        else:
            status = "complete"
            blocker = "none"
    return {
        "lesson": doc.code,
        "task": f"curriculum_task(section({number}))",
        "rule": "docling_task_heading_exact_copy",
        "source": doc.path.relative_to(ROOT).as_posix(),
        "line_start": line_start,
        "line_end": line_end,
        "position": f"student_task_statement({number})",
        "excerpt": excerpt,
        "extraction_status": status,
        "blocker": blocker,
        "visual_provenance": visuals,
    }


def extract_lesson(doc: Any, compiler: Any, context: Any) -> dict[str, Any]:
    lines = doc.path.read_text(encoding="utf-8").splitlines()
    excluded = context.picture_description_lines(doc.path, lines)
    if excluded is None:
        raise ValueError(f"picture annotations cannot be separated: {doc.path}")
    headings = _task_heading_indices(lines, context)
    if not headings:
        raise ValueError(f"no in-scope Student Task Statement heading: {doc.path}")
    body_end = next(
        (
            index
            for index, line in enumerate(lines[headings[0] :], headings[0])
            if context.MIDDLE_CUTOFF_RE.fullmatch(line)
        ),
        len(lines),
    )
    spans, _reason, markers = compiler._segment_docling_task_regions(doc)
    if markers != len(headings):
        raise ValueError(
            f"task marker disagreement for {doc.code}: {markers} != {len(headings)}"
        )
    spans_by_position = {span.position: span for span in spans}
    tasks = []
    for number, heading_index in enumerate(headings, 1):
        end = _section_end(lines, heading_index, body_end, excluded)
        tasks.append(
            _task_record(
                doc,
                number,
                heading_index,
                end,
                spans_by_position.get(f"student_task_statement({number})"),
            )
        )
    questions = [
        asdict(question)
        for question in context.extract_middle_guide_questions(doc.path)
    ]
    return {
        "run_version": RUN_VERSION,
        "lesson": doc.code,
        "source": doc.path.relative_to(ROOT).as_posix(),
        "source_sha256": sha256_file(doc.path),
        "tasks": tasks,
        "guide_questions": questions,
        "model_calls": [],
    }


def extract_question_lesson(doc: QuestionGuide, context: Any) -> dict[str, Any]:
    questions, absences = context.extract_docling_guide_questions(
        doc.path, label_origin="machine_classification"
    )
    return {
        "run_version": RUN_VERSION,
        "lesson": doc.code,
        "source": doc.path.relative_to(ROOT).as_posix(),
        "source_sha256": sha256_file(doc.path),
        "guide_questions": [asdict(question) for question in questions],
        "guide_question_absences": [asdict(absence) for absence in absences],
        "model_calls": [],
    }


def discover_docs(grade: int, compiler: Any) -> list[Any]:
    prefix = f"IM-G{grade}-"
    docs = [
        doc
        for doc in compiler.read_teacher_guides(ROOT)
        if doc.code.startswith(prefix)
        and doc.source_corpus == compiler.DOCLING_GUIDE_CORPUS
    ]
    return sorted(docs, key=lambda item: tuple(map(int, re.findall(r"\d+", item.code))))


def discover_question_guides(grade: str | int) -> list[QuestionGuide]:
    directory = grade_directory(grade)
    token = grade_code_token(grade)
    guides = []
    for path in sorted((SOURCE_ROOT / directory).glob("*/document.md")):
        match = re.fullmatch(
            rf"{re.escape(directory)}-(\d+)-(\d+)-Lesson-teacher-guide-",
            path.parent.name,
        )
        if match is None:
            raise ValueError(f"unrecognized Docling guide directory: {path.parent}")
        unit, lesson = map(int, match.groups())
        guides.append(QuestionGuide(f"IM-G{token}-U{unit}-L{lesson}", path))
    return guides


def checkpoint_path(checkpoint_dir: Path, lesson: str) -> Path:
    return checkpoint_dir / "checkpoints" / f"{lesson}.json"


def compatible_checkpoint(path: Path, doc: Any) -> dict[str, Any] | None:
    if not path.is_file():
        return None
    payload = json.loads(path.read_text(encoding="utf-8"))
    if (
        payload.get("run_version") == RUN_VERSION
        and payload.get("lesson") == doc.code
        and payload.get("source_sha256") == sha256_file(doc.path)
    ):
        return payload
    return None


def _visual_term(row: dict[str, str]) -> str:
    return (
        "visual_source(asset({asset}), description_file({description}), model({model}))"
    ).format(
        asset=_prolog_atom(row["asset"]),
        description=_prolog_atom(row["description"]),
        model=_prolog_atom(row["model"]),
    )


def _recovery_item_term(row: dict[str, Any]) -> str:
    bbox = row.get("bbox")
    bbox_term = "none" if bbox is None else "bbox({l}, {t}, {r}, {b})".format(**bbox)
    page = "none" if row.get("page") is None else str(row["page"])
    return (
        "json_item(ref({ref}), index({index}), kind({kind}), page({page}), "
        "bbox({bbox}), bytes({start}, {end}), raw({raw}), normalized({normalized}))"
    ).format(
        ref=_prolog_atom(row["ref"]),
        index=row["index"],
        kind=_prolog_atom(row["kind"]),
        page=page,
        bbox=bbox_term,
        start=row["byte_start"],
        end=row["byte_end"],
        raw=_prolog_string(row["raw"]),
        normalized=_prolog_string(row["normalized"]),
    )


def _recovery_term(recovery: dict[str, Any]) -> str:
    items = "[" + ", ".join(_recovery_item_term(row) for row in recovery["items"]) + "]"
    return (
        "recovery(docling_json(source({source}), sha256({sha256}), "
        "heading(ref({heading_ref}), index({heading_index}), raw({heading_raw})), "
        "items({items}), normalized_statement({statement}), "
        "normalization({normalization})))"
    ).format(
        source=_prolog_atom(recovery["source"]),
        sha256=_prolog_atom(recovery["source_sha256"]),
        heading_ref=_prolog_atom(recovery["heading_ref"]),
        heading_index=recovery["heading_index"],
        heading_raw=_prolog_string(recovery["heading_raw"]),
        items=items,
        statement=_prolog_string(recovery["normalized_statement"]),
        normalization=_prolog_atom(recovery["normalization"]),
    )


def _vision_recovery_term(recovery: dict[str, Any]) -> str:
    provenance_class = vision_statement_contract.recovery_provenance_class(recovery)
    if provenance_class == vision_statement_contract.WIDENED_CHECKPOINT_CLASS:
        checkpoints = []
        checkpoint_paths = []
        for reading in recovery.get("readings", []):
            path = WIDENED_VISION_CHECKPOINT_DIR / f"{reading['call_id']}.json"
            if not path.is_file():
                raise ValueError(f"widened vision checkpoint is absent: {path}")
            checkpoints.append(json.loads(path.read_text(encoding="utf-8")))
            checkpoint_paths.append(path.relative_to(ROOT).as_posix())
        receipt = vision_statement_contract.widened_statement_receipt(
            recovery["statement"], recovery, checkpoints
        )
        receipt_terms = []
        for path, checkpoint, acceptance in zip(
            checkpoint_paths, checkpoints, receipt["acceptance_paths"]
        ):
            reading_sha256 = hashlib.sha256(
                json.dumps(checkpoint["reading"], sort_keys=True).encode()
            ).hexdigest()
            render_path = (checkpoint.get("render_receipt") or {}).get("path", "none")
            receipt_terms.append(
                "widened_receipt(call_id({call_id}), "
                "raw_response_checkpoint({checkpoint}), "
                "acceptance_path({channel}, {terminal}), "
                "response_sha256({response_sha256}), "
                "structured_reading_sha256({reading_sha256}), "
                "render_receipt({render_receipt}))".format(
                    call_id=_prolog_atom(checkpoint["call_id"]),
                    checkpoint=_prolog_atom(path),
                    channel=_prolog_atom(acceptance["accepted_channel"]),
                    terminal=_prolog_atom(acceptance["terminal_class"]),
                    response_sha256=_prolog_atom(
                        vision_statement_contract.response_sha256(
                            checkpoint["response"]
                        )
                    ),
                    reading_sha256=_prolog_atom(reading_sha256),
                    render_receipt=_prolog_atom(render_path),
                )
            )
        return (
            "recovery(vision(model({model}), call_id({call_id}), outcome(ok), "
            "asset({asset}), description_file({description}), "
            "provenance_class({provenance_class}), "
            "prompt_version({prompt_version}), method({method}), "
            "receipts([{receipts}]), response_sha256({response_sha256}), "
            "statement({statement})))"
        ).format(
            model=_prolog_atom(recovery["model"]),
            call_id=_prolog_atom(recovery["call_id"]),
            asset=_prolog_atom(recovery["asset"]),
            description=_prolog_atom(recovery["description_file"]),
            provenance_class=_prolog_atom(provenance_class),
            prompt_version=_prolog_atom(recovery["prompt_version"]),
            method=_prolog_atom(recovery["method"]),
            receipts=", ".join(receipt_terms),
            response_sha256=_prolog_atom(recovery["response_sha256"]),
            statement=_prolog_string(recovery["statement"]),
        )
    if provenance_class != vision_statement_contract.NARROW_DESCRIPTION_CLASS:
        raise ValueError(f"unknown vision provenance class: {provenance_class}")
    return (
        "recovery(vision(model({model}), call_id({call_id}), outcome(ok), "
        "asset({asset}), description_file({description}), "
        "response_sha256({response_sha256}), statement({statement})))"
    ).format(
        model=_prolog_atom(recovery["model"]),
        call_id=_prolog_atom(recovery["call_id"]),
        asset=_prolog_atom(recovery["asset"]),
        description=_prolog_atom(recovery["description_file"]),
        response_sha256=_prolog_atom(recovery["response_sha256"]),
        statement=_prolog_string(recovery["statement"]),
    )


def render_tasks(grade: int, payloads: list[dict[str, Any]]) -> str:
    tasks = [task for payload in payloads for task in payload["tasks"]]
    counts = Counter(task["extraction_status"] for task in tasks)
    module = f"grade_{grade}_extracted_task_instances"
    lines = [
        "/** <module> Generated source-backed Docling task instances",
        " *",
        " * Generated by scripts/curriculum/extract_docling_grade.py.",
        " * Do not edit by hand; blocked rows retain their named provenance.",
        " */",
        f":- module({module},",
        "          [ extracted_lesson_task_instance/3,",
        "            extracted_task_instance_summary/2",
        "          ]).",
        "",
        f"extracted_task_instance_summary({len(payloads)},",
        "    counts{"
        + ", ".join(f"{key}:{counts[key]}" for key in sorted(counts))
        + "}).",
        "",
    ]
    for task in tasks:
        visuals = (
            "["
            + ", ".join(_visual_term(row) for row in task["visual_provenance"])
            + "]"
        )
        if "recovery" in task:
            recovery = ", " + _recovery_term(task["recovery"])
        elif "vision_recovery" in task:
            recovery = ", " + _vision_recovery_term(task["vision_recovery"])
        else:
            recovery = ""
        evidence = (
            "task_evidence(rule({rule}), source({source}, lines({start}, {end})), "
            "position({position}), excerpt({excerpt}), extraction_status({status}), "
            "blocker({blocker}), visual_provenance({visuals}){recovery})"
        ).format(
            rule=_prolog_atom(task["rule"]),
            source=_prolog_atom(task["source"]),
            start=task["line_start"],
            end=task["line_end"],
            position=task["position"],
            excerpt=_prolog_string(task["excerpt"]),
            status=_prolog_atom(task["extraction_status"]),
            blocker=_prolog_atom(task["blocker"]),
            visuals=visuals,
            recovery=recovery,
        )
        lines.extend(
            [
                f"extracted_lesson_task_instance({_prolog_atom(task['lesson'])},",
                f"    {task['task']},",
                f"    {evidence}).",
                "",
            ]
        )
    return "\n".join(lines).rstrip() + "\n"


def render_questions(
    grade: str | int, payloads: list[dict[str, Any]], context: Any
) -> str:
    questions = [
        question for payload in payloads for question in payload["guide_questions"]
    ]
    absences = [
        absence
        for payload in payloads
        for absence in payload.get("guide_question_absences", [])
    ]
    counts = Counter(question["purpose"] for question in questions)
    absence_counts = Counter(absence["purpose"] for absence in absences)
    grade_key = normalize_grade(grade)
    module = f"grade_{grade_key}_extracted_guide_questions"
    lines = [
        "/** <module> Generated pending Docling guide-question records",
        " *",
        " * Generated by scripts/curriculum/extract_docling_grade.py.",
        " * Do not edit by hand; reviewer culls remain records.",
        " */",
        f":- module({module},",
        "          [ extracted_lesson_guide_question/2,",
        "            extracted_guide_question_absence/3,",
        "            extracted_guide_question_summary/2",
        "          ]).",
        "",
        ":- dynamic extracted_guide_question_absence/3.",
        "",
        f"extracted_guide_question_summary({len(payloads)},",
        "    counts{"
        + ", ".join(
            [
                *(f"{key}:{counts[key]}" for key in sorted(counts)),
                *(
                    f"missing_{key}:{absence_counts[key]}"
                    for key in sorted(absence_counts)
                ),
            ]
        )
        + "}).",
        "",
    ]
    for data in questions:
        question = context.GuideQuestion(**data)
        context.validate_guide_question(question)
        lines.extend(
            [
                "extracted_lesson_guide_question(",
                f"    {_prolog_atom(question.code)},",
                f"    {context.guide_question_term(question)}).",
                "",
            ]
        )
    for absence in absences:
        lines.extend(
            [
                "extracted_guide_question_absence(",
                f"    {_prolog_atom(absence['code'])},",
                f"    {_prolog_atom(absence['purpose'])},",
                f"    absence(source_guide({_prolog_atom(absence['source'])}), "
                f"reason({_prolog_atom(absence['reason'])}))).",
                "",
            ]
        )
    return "\n".join(lines).rstrip() + "\n"


def build_question_summary(
    grade: str | int,
    payloads: list[dict[str, Any]],
    *,
    resumed: int,
    wall_seconds: float,
) -> dict[str, Any]:
    per_unit: dict[int, dict[str, int]] = defaultdict(lambda: defaultdict(int))
    question_counts: Counter[str] = Counter()
    absence_counts: Counter[str] = Counter()
    for payload in payloads:
        unit = int(re.search(r"-U(\d+)-", payload["lesson"]).group(1))
        per_unit[unit]["lessons"] += 1
        for question in payload["guide_questions"]:
            question_counts[question["purpose"]] += 1
            per_unit[unit][question["purpose"]] += 1
        for absence in payload.get("guide_question_absences", []):
            absence_counts[absence["purpose"]] += 1
            per_unit[unit][f"missing_{absence['purpose']}"] += 1
    return {
        "run_version": RUN_VERSION,
        "grade": normalize_grade(grade),
        "lessons": len(payloads),
        "guide_questions": sum(question_counts.values()),
        "question_counts": dict(sorted(question_counts.items())),
        "question_absence_counts": dict(sorted(absence_counts.items())),
        "lessons_with_two_questions": sum(
            len(payload["guide_questions"]) == 2 for payload in payloads
        ),
        "per_unit": {
            str(unit): dict(values) for unit, values in sorted(per_unit.items())
        },
        "llm_calls": {"REALLMS": 0, "Big_Red": 0},
        "resumed_checkpoints": resumed,
        "wall_seconds": round(wall_seconds, 3),
    }


def build_summary(
    grade: int,
    payloads: list[dict[str, Any]],
    *,
    resumed: int,
    wall_seconds: float,
) -> dict[str, Any]:
    per_unit: dict[int, dict[str, int]] = defaultdict(lambda: defaultdict(int))
    blockers: Counter[str] = Counter()
    status_counts: Counter[str] = Counter()
    for payload in payloads:
        unit = int(re.search(r"-U(\d+)-", payload["lesson"]).group(1))
        per_unit[unit]["lessons"] += 1
        per_unit[unit]["guide_questions"] += len(payload["guide_questions"])
        for task in payload["tasks"]:
            per_unit[unit]["tasks"] += 1
            status_counts[task["extraction_status"]] += 1
            if task["blocker"] != "none":
                blockers[task["blocker"]] += 1
    return {
        "run_version": RUN_VERSION,
        "grade": grade,
        "lessons": len(payloads),
        "tasks": sum(status_counts.values()),
        "task_status_counts": dict(sorted(status_counts.items())),
        "blocked_counts": dict(sorted(blockers.items())),
        "guide_questions": sum(len(payload["guide_questions"]) for payload in payloads),
        "question_counts": {
            purpose: sum(
                question["purpose"] == purpose
                for payload in payloads
                for question in payload["guide_questions"]
            )
            for purpose in ("assessing", "advancing")
        },
        "per_unit": {
            str(unit): dict(values) for unit, values in sorted(per_unit.items())
        },
        "llm_calls": {"REALLMS": 0, "Big_Red": 0},
        "resumed_checkpoints": resumed,
        "wall_seconds": round(wall_seconds, 3),
    }


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--grade", required=True, help="K or a grade number from 1 to 8"
    )
    parser.add_argument("--lessons", help="comma-separated canonical lesson ids")
    parser.add_argument("--checkpoint-dir", type=Path)
    parser.add_argument("--task-output", type=Path)
    parser.add_argument("--question-output", type=Path)
    parser.add_argument("--summary-output", type=Path)
    parser.add_argument("--refresh", action="store_true")
    parser.add_argument("--check", action="store_true")
    parser.add_argument(
        "--questions-only",
        action="store_true",
        help="extract only guide questions; required for Kindergarten through Grade 5",
    )
    args = parser.parse_args(argv)
    try:
        args.grade = normalize_grade(args.grade)
    except ValueError as exc:
        parser.error(str(exc))
    if args.grade in {"k", "1", "2", "3", "4", "5"} and not args.questions_only:
        parser.error("--questions-only is required for Kindergarten through Grade 5")
    checkpoint_root = (
        DEFAULT_QUESTION_CHECKPOINT_ROOT
        if args.questions_only
        else DEFAULT_CHECKPOINT_ROOT
    )
    args.checkpoint_dir = args.checkpoint_dir or checkpoint_root / f"grade-{args.grade}"
    args.task_output = (
        args.task_output
        or GENERATED / f"grade_{args.grade}_extracted_task_instances.pl"
    )
    args.question_output = (
        args.question_output
        or GENERATED / f"grade_{args.grade}_extracted_guide_questions.pl"
    )
    args.summary_output = args.summary_output or args.checkpoint_dir / "summary.json"
    requested = (
        [] if not args.lessons else [item.strip() for item in args.lessons.split(",")]
    )
    if any(not item for item in requested):
        parser.error("--lessons must contain nonblank comma-separated ids")
    args.lessons = requested
    return args


def run(args: argparse.Namespace) -> dict[str, Any]:
    started = time.monotonic()
    compiler, context = _load_modules()
    docs = (
        discover_question_guides(args.grade)
        if args.questions_only
        else discover_docs(int(args.grade), compiler)
    )
    if args.lessons:
        wanted = set(args.lessons)
        docs = [doc for doc in docs if doc.code in wanted]
        missing = sorted(wanted - {doc.code for doc in docs})
        if missing:
            raise ValueError("unknown requested lessons: " + ", ".join(missing))
    payloads = []
    resumed = 0
    for doc in docs:
        path = checkpoint_path(args.checkpoint_dir, doc.code)
        payload = None if args.refresh else compatible_checkpoint(path, doc)
        if payload is None:
            payload = (
                extract_question_lesson(doc, context)
                if args.questions_only
                else extract_lesson(doc, compiler, context)
            )
            if not args.check:
                atomic_write_json(path, payload)
        else:
            resumed += 1
        payloads.append(payload)
    question_text = render_questions(args.grade, payloads, context)
    if args.questions_only:
        summary = build_question_summary(
            args.grade,
            payloads,
            resumed=resumed,
            wall_seconds=time.monotonic() - started,
        )
        outputs = (
            (args.question_output, question_text),
            (args.summary_output, json.dumps(summary, indent=2, sort_keys=True) + "\n"),
        )
    else:
        task_text = render_tasks(int(args.grade), payloads)
        summary = build_summary(
            int(args.grade),
            payloads,
            resumed=resumed,
            wall_seconds=time.monotonic() - started,
        )
        outputs = (
            (args.task_output, task_text),
            (args.question_output, question_text),
            (args.summary_output, json.dumps(summary, indent=2, sort_keys=True) + "\n"),
        )
    if args.check:
        stale = [
            path
            for path, text in outputs[:-1]
            if not path.is_file() or path.read_text(encoding="utf-8") != text
        ]
        if args.summary_output.is_file():
            stored_summary = json.loads(args.summary_output.read_text(encoding="utf-8"))
            stable_keys = set(summary) - {"resumed_checkpoints", "wall_seconds"}
            if any(stored_summary.get(key) != summary.get(key) for key in stable_keys):
                stale.append(args.summary_output)
        else:
            stale.append(args.summary_output)
        if stale:
            raise SystemExit(
                "stale extraction outputs: " + ", ".join(str(path) for path in stale)
            )
    else:
        for path, text in outputs:
            atomic_write(path, text)
    print(json.dumps(summary, sort_keys=True))
    return summary


def main(argv: list[str] | None = None) -> int:
    run(parse_args(argv))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
