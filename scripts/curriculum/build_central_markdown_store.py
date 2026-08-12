#!/usr/bin/env python3
"""Build a human-legible Markdown projection of the IM K-8 corpus."""

from __future__ import annotations

import argparse
from collections import Counter, defaultdict
from dataclasses import dataclass
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
from typing import Any, NoReturn
from urllib.parse import unquote, urlsplit


ROOT = Path(__file__).resolve().parents[2]
GUIDE_ROOT = (
    ROOT
    / "hermes/app/runtime/experiments/gemma4_tutor/docling/full-output"
    / "TeacherLessonGuides"
)
ARTIFACT = ROOT / "curriculum/im/generated/compiled_defragged_task_instances.pl"
HELPER = Path(__file__).with_name("central_markdown_store_rows.pl")
DEFAULT_DEST = Path("/Users/tio/Documents/GitHub/Prolog/IM-Curriculum/Markdown")

GRADE_DIRS = (
    "Kindergarten",
    "Grade1",
    "Grade2",
    "Grade3",
    "Grade4",
    "Grade5",
    "Grade6",
    "Grade7",
    "Grade8",
)
EXPECTED_GUIDES = {
    "Kindergarten": 139,
    "Grade1": 148,
    "Grade2": 150,
    "Grade3": 143,
    "Grade4": 151,
    "Grade5": 148,
    "Grade6": 152,
    "Grade7": 143,
    "Grade8": 134,
}
EXPECTED_ARTIFACT_COUNTS = {
    "already_complete": 547,
    "recovered": 1261,
    "recovered_with_referent": 3,
    "blocked_missing_visual": 23,
    "blocked_layout": 312,
}
USABLE_STATUSES = {
    "already_complete",
    "recovered",
    "recovered_with_referent",
}
BLOCKED_LABELS = {
    "blocked_layout": "layout-blocked in the source extraction",
    "blocked_missing_visual": "needs a visual the extraction does not carry",
}
MAX_IMAGE_BYTES = 6_000_000_000

LESSON_DIR_RE = re.compile(
    r"^(Kindergarten|Grade[1-8])-(\d+)-(\d+)-Lesson-teacher-guide-$"
)
LESSON_CODE_RE = re.compile(r"^IM-G(K|[1-8])-U(\d+)-L(\d+)$")
MARKDOWN_IMAGE_RE = re.compile(
    r"!\[[^\]\n]*\]\(\s*(?P<target><[^>\n]+>|[^)\s]+)"
)
HTML_IMAGE_RE = re.compile(
    r"<img\b[^>]*\bsrc\s*=\s*(?P<quote>['\"])(?P<target>.*?)(?P=quote)",
    re.IGNORECASE,
)
FORBIDDEN_MARKDOWN = {
    "artifact sha field": re.compile(r"\b(?:evidence_)?sha256\b", re.IGNORECASE),
    "byte offset field": re.compile(r"\bbyte_(?:start|end|offset)\b", re.IGNORECASE),
    "segment identifier": re.compile(r"\bseg_[0-9a-f]{8,}\b", re.IGNORECASE),
    "internal record identifier": re.compile(r"\bim_defrag_[0-9a-f]+", re.IGNORECASE),
}


class BuildBlocked(RuntimeError):
    """Raised when an input or safety condition contradicts the brief."""


@dataclass(frozen=True)
class Lesson:
    grade: str
    unit: int
    lesson: int
    code: str
    source: Path
    title: str

    @property
    def output_name(self) -> str:
        return f"U{self.unit}-L{self.lesson}"


@dataclass(frozen=True)
class ImagePlan:
    sources: tuple[Path, ...]
    projected_bytes: int
    external_refs: int
    absent_refs: int


def blocked(message: str) -> NoReturn:
    raise BuildBlocked(message)


def lesson_code_from_dir_name(name: str) -> str:
    match = LESSON_DIR_RE.fullmatch(name)
    if not match:
        raise ValueError(f"not an IM lesson directory name: {name}")
    grade_dir, unit, lesson = match.groups()
    grade_code = "K" if grade_dir == "Kindergarten" else grade_dir.removeprefix("Grade")
    return f"IM-G{grade_code}-U{int(unit)}-L{int(lesson)}"


def lesson_dir_name_from_code(code: str) -> str:
    match = LESSON_CODE_RE.fullmatch(code)
    if not match:
        raise ValueError(f"not an IM lesson code: {code}")
    grade_code, unit, lesson = match.groups()
    grade_dir = "Kindergarten" if grade_code == "K" else f"Grade{grade_code}"
    return f"{grade_dir}-{int(unit)}-{int(lesson)}-Lesson-teacher-guide-"


def display_term(value: Any) -> str:
    if isinstance(value, dict):
        functor = value["functor"]
        arguments = ", ".join(display_term(item) for item in value["args"])
        return f"{functor}({arguments})"
    return str(value)


def display_fraction(value: Any) -> str:
    if isinstance(value, dict) and value.get("functor") == "frac":
        numerator, denominator = value["args"]
        return f"{display_term(numerator)}/{display_term(denominator)}"
    if isinstance(value, dict) and value.get("functor") == "whole":
        return display_term(value["args"][0])
    return display_term(value)


def format_operation(functor: str, arguments: list[Any]) -> str:
    values = [display_term(value) for value in arguments]
    fractions = [display_fraction(value) for value in arguments]
    if functor == "add" and len(values) == 2:
        return f"Addition: {values[0]} + {values[1]}"
    if functor == "subtract" and len(values) == 2:
        return f"Subtraction: {values[0]} − {values[1]}"
    if functor == "multiply" and len(values) == 2:
        return f"Multiplication: {values[0]} × {values[1]}"
    if functor == "divide" and len(values) == 2:
        return f"Division: {values[0]} ÷ {values[1]}"
    if functor == "add_fractions" and len(fractions) == 2:
        return f"Fraction addition: {fractions[0]} + {fractions[1]}"
    if functor == "subtract_fractions" and len(fractions) == 2:
        return f"Fraction subtraction: {fractions[0]} − {fractions[1]}"
    if functor == "unit_fraction" and len(values) == 2:
        return f"Unit fraction: {values[0]}/{values[1]}"
    if functor == "iterate_improper_fraction" and len(values) == 2:
        return f"Improper fraction: {values[0]}/{values[1]}"
    if functor == "decimal_add" and len(values) == 4:
        return f"Decimal addition: {values[0]}/{values[1]} + {values[2]}/{values[3]}"
    if functor == "decimal_compare" and len(values) == 4:
        return f"Decimal comparison: {values[0]}/{values[1]} and {values[2]}/{values[3]}"
    if functor == "decimal_value" and len(values) == 2:
        return f"Decimal value: {values[0]}/{values[1]}"
    labels = {
        "compare_numerals_by_place_value": "Compare numerals by place value",
        "compare_rectangle_areas": "Compare rectangle areas",
        "construct_rectangle_with_area": "Construct a rectangle with area",
        "construct_rectangle_with_perimeter": "Construct a rectangle with perimeter",
        "convert_measurement": "Convert measurement",
        "read_liquid_volume": "Read liquid volume",
        "rectangle_missing_side_from_area": "Find a rectangle side from area",
        "rectangle_missing_side_from_perimeter": "Find a rectangle side from perimeter",
        "rectangle_perimeter": "Rectangle perimeter",
        "rectangle_side_lengths_for_area": "Rectangle side lengths for area",
        "unit_cube_volume": "Unit-cube volume",
    }
    if functor in labels:
        return f"{labels[functor]}: {', '.join(values)}"
    return f"{functor}({', '.join(values)})"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dest", type=Path, default=DEFAULT_DEST)
    parser.add_argument(
        "--grades",
        help="comma-separated grade directories, such as Grade1,Grade2",
    )
    parser.add_argument(
        "--limit",
        type=positive_int,
        help="use the first N lexicographically named lessons in each grade",
    )
    parser.add_argument(
        "--verify",
        action="store_true",
        help="recount and validate the generated tree after writing",
    )
    return parser.parse_args()


def positive_int(raw: str) -> int:
    value = int(raw)
    if value < 1:
        raise argparse.ArgumentTypeError("must be at least 1")
    return value


def selected_grades(raw: str | None) -> tuple[str, ...]:
    if raw is None:
        return GRADE_DIRS
    values = tuple(part.strip() for part in raw.split(",") if part.strip())
    if not values:
        blocked("--grades did not name a grade")
    unknown = [value for value in values if value not in GRADE_DIRS]
    if unknown:
        blocked(f"unknown grade directories: {', '.join(unknown)}")
    if len(values) != len(set(values)):
        blocked("--grades contains a duplicate grade")
    return tuple(grade for grade in GRADE_DIRS if grade in values)


def first_heading(document: Path) -> str:
    for line in document.read_text(encoding="utf-8").splitlines():
        if line.startswith("#") and line.lstrip("#").strip():
            return line.lstrip("#").strip()
    blocked(f"guide has no Markdown title heading: {document}")


def discover_lessons() -> dict[str, list[Lesson]]:
    if not GUIDE_ROOT.is_dir():
        blocked(f"Docling guide root is missing: {GUIDE_ROOT}")
    lessons: dict[str, list[Lesson]] = {}
    required = (
        "document.md",
        "picture_descriptions.md",
        "document.json",
        "conversion.ok.json",
    )
    for grade in GRADE_DIRS:
        grade_root = GUIDE_ROOT / grade
        directories = sorted(path for path in grade_root.iterdir() if path.is_dir())
        if len(directories) != EXPECTED_GUIDES[grade]:
            blocked(
                f"{grade} has {len(directories)} guide directories; "
                f"the brief requires {EXPECTED_GUIDES[grade]}"
            )
        grade_lessons: list[Lesson] = []
        for directory in directories:
            match = LESSON_DIR_RE.fullmatch(directory.name)
            if not match or match.group(1) != grade:
                blocked(f"unexpected lesson directory shape: {directory}")
            missing = [name for name in required if not (directory / name).is_file()]
            if missing or not (directory / "document_artifacts").is_dir():
                details = missing + ([] if (directory / "document_artifacts").is_dir() else ["document_artifacts/"])
                blocked(f"{directory} is missing: {', '.join(details)}")
            _, unit, lesson = match.groups()
            code = lesson_code_from_dir_name(directory.name)
            if lesson_dir_name_from_code(code) != directory.name:
                blocked(f"lesson mapping does not round-trip: {directory.name}")
            grade_lessons.append(
                Lesson(
                    grade=grade,
                    unit=int(unit),
                    lesson=int(lesson),
                    code=code,
                    source=directory,
                    title=first_heading(directory / "document.md"),
                )
            )
        lessons[grade] = grade_lessons
    return lessons


def read_artifact() -> tuple[dict[str, int], list[dict[str, Any]]]:
    if not ARTIFACT.is_file() or not HELPER.is_file():
        blocked("the defrag artifact or its JSON helper is missing")
    result = subprocess.run(
        ["swipl", "-q", "-s", str(HELPER), "--", str(ARTIFACT)],
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if result.returncode:
        blocked(f"SWI-Prolog artifact serialization failed: {result.stderr.strip()}")
    try:
        payload = json.loads(result.stdout)
    except json.JSONDecodeError as error:
        blocked(f"SWI-Prolog emitted invalid JSON: {error}")
    summary = payload.get("summary", {})
    rows = payload.get("rows", [])
    counts = summary.get("counts", {})
    if summary.get("total") != 2146 or counts != EXPECTED_ARTIFACT_COUNTS:
        blocked(
            "artifact summary contradicts the brief: "
            f"total={summary.get('total')}, counts={counts}"
        )
    actual = Counter(row.get("status") for row in rows)
    if len(rows) != summary["total"] or dict(actual) != counts:
        blocked(
            "artifact rows contradict their own summary: "
            f"rows={len(rows)}, status_counts={dict(actual)}"
        )
    required_row_fields = {
        "lesson",
        "class_label",
        "op_functor",
        "op_args",
        "status",
        "blocker",
        "complete_statement",
        "referents",
    }
    for index, row in enumerate(rows, start=1):
        missing = required_row_fields - row.keys()
        if missing:
            blocked(f"artifact row {index} lacks fields: {', '.join(sorted(missing))}")
        if row["status"] not in USABLE_STATUSES | BLOCKED_LABELS.keys():
            blocked(f"artifact row {index} has unknown status: {row['status']}")
    return counts, rows


def resolve_artifact_codes(
    all_lessons: dict[str, list[Lesson]], rows: list[dict[str, Any]]
) -> tuple[dict[str, Lesson], list[str], dict[str, list[str]]]:
    candidates: dict[str, list[Lesson]] = defaultdict(list)
    for grade_lessons in all_lessons.values():
        for lesson in grade_lessons:
            candidates[lesson.code].append(lesson)
    misses: list[str] = []
    ambiguous: dict[str, list[str]] = {}
    resolved: dict[str, Lesson] = {}
    for code in sorted({row["lesson"] for row in rows}):
        hits = candidates.get(code, [])
        if not hits:
            misses.append(code)
        elif len(hits) > 1:
            ambiguous[code] = [str(hit.source) for hit in hits]
        else:
            resolved[code] = hits[0]
    if ambiguous:
        blocked("ambiguous artifact lesson codes: " + json.dumps(ambiguous, sort_keys=True))
    if len(misses) > 5:
        blocked(f"{len(misses)} artifact lesson codes do not resolve: {', '.join(misses)}")
    return resolved, misses, ambiguous


def image_targets(text: str) -> list[str]:
    matches = [match.group("target") for match in MARKDOWN_IMAGE_RE.finditer(text)]
    matches.extend(match.group("target") for match in HTML_IMAGE_RE.finditer(text))
    return [target[1:-1] if target.startswith("<") and target.endswith(">") else target for target in matches]


def rewritten_guide_bytes(lesson: Lesson) -> bytes:
    text = (lesson.source / "document.md").read_bytes().decode("utf-8")
    matches = list(MARKDOWN_IMAGE_RE.finditer(text)) + list(HTML_IMAGE_RE.finditer(text))
    replacements: list[tuple[int, int, str]] = []
    artifact_root = (lesson.source / "document_artifacts").resolve()
    for match in sorted(matches, key=lambda item: item.start("target")):
        raw_target = match.group("target")
        angled = raw_target.startswith("<") and raw_target.endswith(">")
        target = raw_target[1:-1] if angled else raw_target
        split = urlsplit(target)
        if split.scheme or split.netloc or not split.path.startswith("document_artifacts/"):
            continue
        source = (lesson.source / unquote(split.path)).resolve()
        if source.parent != artifact_root or not source.is_file():
            continue
        suffix = (f"?{split.query}" if split.query else "") + (
            f"#{split.fragment}" if split.fragment else ""
        )
        rewritten = f"./images/{source.name}{suffix}"
        if angled:
            rewritten = f"<{rewritten}>"
        replacements.append((match.start("target"), match.end("target"), rewritten))
    for start, end, replacement in reversed(replacements):
        text = text[:start] + replacement + text[end:]
    return text.encode("utf-8")


def image_plan(lesson: Lesson) -> ImagePlan:
    document = lesson.source / "document.md"
    text = document.read_bytes().decode("utf-8")
    targets = image_targets(text)
    prefix_occurrences = text.count("document_artifacts/")
    document_targets = [target for target in targets if target.startswith("document_artifacts/")]
    if prefix_occurrences != len(document_targets):
        blocked(
            f"unrecognized document_artifacts reference syntax in {document}: "
            f"{prefix_occurrences} prefixes but {len(document_targets)} image targets"
        )
    sources: dict[str, Path] = {}
    external_refs = 0
    absent_refs = 0
    artifact_root = (lesson.source / "document_artifacts").resolve()
    for target in targets:
        split = urlsplit(target)
        if split.scheme or split.netloc or target.startswith(("#", "data:")):
            external_refs += 1
            continue
        clean_target = unquote(split.path)
        if not clean_target.startswith("document_artifacts/"):
            absent_refs += 1
            continue
        source = (lesson.source / clean_target).resolve()
        if source.parent != artifact_root:
            blocked(f"nested or escaping guide image reference in {document}: {target}")
        if not source.is_file():
            absent_refs += 1
            continue
        previous = sources.get(source.name)
        if previous is not None and previous != source:
            blocked(f"image basename collision in {document}: {source.name}")
        sources[source.name] = source
    ordered = tuple(sources[name] for name in sorted(sources))
    return ImagePlan(
        sources=ordered,
        projected_bytes=sum(source.stat().st_size for source in ordered),
        external_refs=external_refs,
        absent_refs=absent_refs,
    )


def blockquote(statement: str) -> str:
    return "\n".join(">" if line == "" else f"> {line}" for line in statement.split("\n"))


def referent_line(referent: dict[str, Any]) -> str:
    surface = referent["surface"]
    status = str(referent["status"]).replace("_", " ")
    line = f'Refers to: "{surface}" — {status}'
    antecedent = referent["antecedent"]
    absence = referent["absence_reason"]
    if antecedent:
        line += f' (antecedent: "{antecedent}")'
    elif absence and absence != "none":
        line += f" (absence: {str(absence).replace('_', ' ')})"
    return line


def render_tasks(code: str, rows: list[dict[str, Any]]) -> str:
    usable = [row for row in rows if row["status"] in USABLE_STATUSES]
    blocked_rows = [row for row in rows if row["status"] in BLOCKED_LABELS]
    parts = [f"# Tasks for {code}", ""]
    for row in usable:
        parts.extend(
            [
                f"### {format_operation(row['op_functor'], row['op_args'])}",
                "",
                blockquote(row["complete_statement"]),
                "",
            ]
        )
        for referent in row["referents"]:
            parts.extend([referent_line(referent), ""])
        parts.extend([f"Class: {row['class_label']}", ""])
    if blocked_rows:
        parts.extend(["## Not recovered", ""])
        for row in blocked_rows:
            operation = format_operation(row["op_functor"], row["op_args"])
            parts.append(f"- **{operation}**: {BLOCKED_LABELS[row['status']]}")
        parts.append("")
    return "\n".join(parts)


def render_index(grade: str, lessons: list[Lesson], rows_by_code: dict[str, list[dict[str, Any]]]) -> str:
    lines = [f"# {grade} lesson index", "", "| Lesson code | Title | Tasks |", "|---|---|---|"]
    for lesson in lessons:
        title = lesson.title.replace("|", "\\|")
        guide_link = f"{lesson.output_name}/guide.md"
        if rows_by_code.get(lesson.code):
            task_flag = f"[yes]({lesson.output_name}/tasks.md)"
        else:
            task_flag = "no"
        lines.append(f"| [{lesson.code}]({guide_link}) | {title} | {task_flag} |")
    lines.append("")
    return "\n".join(lines)


def render_readme(
    lessons_by_grade: dict[str, list[Lesson]], rows_by_code: dict[str, list[dict[str, Any]]]
) -> str:
    selected_rows = [
        row
        for lessons in lessons_by_grade.values()
        for lesson in lessons
        for row in rows_by_code.get(lesson.code, [])
    ]
    usable = sum(row["status"] in USABLE_STATUSES for row in selected_rows)
    blocked_count = sum(row["status"] in BLOCKED_LABELS for row in selected_rows)
    lines = [
        "# Central IM lesson guides",
        "",
        "This tree places the selected Illustrative Mathematics K-8 lesson guides and their available task statements in one Markdown store.",
        "",
        "## Contents",
        "",
        "| Grade | Guides | Lessons with tasks |",
        "|---|---:|---:|",
    ]
    for grade in GRADE_DIRS:
        if grade not in lessons_by_grade:
            continue
        lessons = lessons_by_grade[grade]
        with_tasks = sum(bool(rows_by_code.get(lesson.code)) for lesson in lessons)
        lines.append(f"| {grade} | {len(lessons)} | {with_tasks} |")
    lines.extend(
        [
            "",
            f"Task rows in this tree: {usable} usable and {blocked_count} blocked.",
            "",
            "## Provenance",
            "",
            "The lesson guides come from IM PDFs converted with Docling 2.114.0 on Big Red in July 2026. Each `guide.md` copies its Docling `document.md`, apart from local image-path rewrites. Each `captions.md` copies the corresponding Docling picture descriptions.",
            "",
            "Task statements are a legible projection of `curriculum/im/generated/compiled_defragged_task_instances.pl`. Statements are copied from that artifact and are not re-derived here.",
            "",
            "## Limits",
            "",
            "- Docling drops some filled-outline expressions to blanks or images.",
            "- Some Grade 6 and Grade 7 task rows cite source PDFs that the extraction did not read.",
            "- Grade 8 has lesson guides but no task rows yet.",
            "- `captions.md` contains machine-generated image descriptions, not curriculum-authored text.",
            "",
        ]
    )
    return "\n".join(lines)


def safe_destination(dest: Path) -> Path:
    resolved = dest.expanduser().resolve()
    protected = (ROOT.resolve(), GUIDE_ROOT.resolve(), (ROOT / "curriculum").resolve())
    if resolved == Path("/") or resolved == Path.home().resolve() or resolved == ROOT.resolve():
        blocked(f"unsafe destination: {resolved}")
    if any(resolved == path or resolved.is_relative_to(path) for path in protected[1:]):
        blocked(f"destination is inside a read-only input tree: {resolved}")
    return resolved


def clean_generated_tree(dest: Path) -> None:
    dest.mkdir(parents=True, exist_ok=True)
    readme = dest / "README.md"
    if readme.exists():
        readme.unlink()
    for grade in GRADE_DIRS:
        grade_dest = dest / grade
        if grade_dest.exists():
            shutil.rmtree(grade_dest)


def write_tree(
    dest: Path,
    lessons_by_grade: dict[str, list[Lesson]],
    rows_by_code: dict[str, list[dict[str, Any]]],
    image_plans: dict[str, ImagePlan],
) -> None:
    clean_generated_tree(dest)
    (dest / "README.md").write_text(
        render_readme(lessons_by_grade, rows_by_code), encoding="utf-8"
    )
    for grade, lessons in lessons_by_grade.items():
        grade_dest = dest / grade
        grade_dest.mkdir(parents=True)
        (grade_dest / "INDEX.md").write_text(
            render_index(grade, lessons, rows_by_code), encoding="utf-8"
        )
        for lesson in lessons:
            lesson_dest = grade_dest / lesson.output_name
            lesson_dest.mkdir()
            (lesson_dest / "guide.md").write_bytes(rewritten_guide_bytes(lesson))
            shutil.copyfile(
                lesson.source / "picture_descriptions.md", lesson_dest / "captions.md"
            )
            plan = image_plans[lesson.code]
            if plan.sources:
                images_dest = lesson_dest / "images"
                images_dest.mkdir()
                for source in plan.sources:
                    shutil.copyfile(source, images_dest / source.name)
            task_rows = rows_by_code.get(lesson.code, [])
            if task_rows:
                (lesson_dest / "tasks.md").write_text(
                    render_tasks(lesson.code, task_rows), encoding="utf-8"
                )


def verify_tree(
    dest: Path,
    lessons_by_grade: dict[str, list[Lesson]],
    rows_by_code: dict[str, list[dict[str, Any]]],
    image_plans: dict[str, ImagePlan],
    artifact_counts: dict[str, int],
    mapping_misses: list[str],
    mapping_ambiguous: dict[str, list[str]],
) -> tuple[bool, str]:
    problems: list[str] = []
    lessons = [lesson for grade_lessons in lessons_by_grade.values() for lesson in grade_lessons]
    expected_tasks = [lesson for lesson in lessons if rows_by_code.get(lesson.code)]
    selected_rows = [row for lesson in lessons for row in rows_by_code.get(lesson.code, [])]
    usable_rows = [row for row in selected_rows if row["status"] in USABLE_STATUSES]
    blocked_rows = [row for row in selected_rows if row["status"] in BLOCKED_LABELS]
    expected_images = sum(len(image_plans[lesson.code].sources) for lesson in lessons)
    projected_bytes = sum(image_plans[lesson.code].projected_bytes for lesson in lessons)
    external_refs = sum(image_plans[lesson.code].external_refs for lesson in lessons)
    absent_refs = sum(image_plans[lesson.code].absent_refs for lesson in lessons)

    guide_files = list(dest.glob("*/U*-L*/guide.md"))
    task_files = list(dest.glob("*/U*-L*/tasks.md"))
    image_files = list(dest.glob("*/U*-L*/images/*"))
    copied_bytes = sum(path.stat().st_size for path in image_files if path.is_file())
    if len(guide_files) != len(lessons):
        problems.append(f"guide count {len(guide_files)} != {len(lessons)}")
    if len(task_files) != len(expected_tasks):
        problems.append(f"task-file count {len(task_files)} != {len(expected_tasks)}")
    if len(image_files) != expected_images:
        problems.append(f"image count {len(image_files)} != {expected_images}")
    if copied_bytes != projected_bytes:
        problems.append(f"copied image bytes {copied_bytes} != projected {projected_bytes}")

    dangling_refs = 0
    for lesson in lessons:
        lesson_dest = dest / lesson.grade / lesson.output_name
        expected_guide = rewritten_guide_bytes(lesson)
        if (lesson_dest / "guide.md").read_bytes() != expected_guide:
            problems.append(f"guide bytes differ after path rewrite: {lesson.code}")
        if (lesson_dest / "captions.md").read_bytes() != (
            lesson.source / "picture_descriptions.md"
        ).read_bytes():
            problems.append(f"caption bytes differ: {lesson.code}")
        for source in image_plans[lesson.code].sources:
            copied = lesson_dest / "images" / source.name
            if not copied.is_file() or copied.read_bytes() != source.read_bytes():
                problems.append(f"copied image differs: {lesson.code}/{source.name}")
        guide_text = (lesson_dest / "guide.md").read_text(encoding="utf-8")
        for target in image_targets(guide_text):
            split = urlsplit(target)
            if split.scheme or split.netloc or target.startswith(("#", "data:")):
                continue
            local = (lesson_dest / unquote(split.path)).resolve()
            if not local.is_file():
                dangling_refs += 1
        task_rows = rows_by_code.get(lesson.code, [])
        tasks_path = lesson_dest / "tasks.md"
        if task_rows and tasks_path.read_text(encoding="utf-8") != render_tasks(
            lesson.code, task_rows
        ):
            problems.append(f"task rendering differs: {lesson.code}")
        if not task_rows and tasks_path.exists():
            problems.append(f"unexpected task file: {lesson.code}")

    expected_readme = render_readme(lessons_by_grade, rows_by_code)
    if (dest / "README.md").read_text(encoding="utf-8") != expected_readme:
        problems.append("README content differs")
    for grade, grade_lessons in lessons_by_grade.items():
        expected_index = render_index(grade, grade_lessons, rows_by_code)
        if (dest / grade / "INDEX.md").read_text(encoding="utf-8") != expected_index:
            problems.append(f"index content differs: {grade}")

    for markdown in dest.rglob("*.md"):
        text = markdown.read_text(encoding="utf-8")
        for label, pattern in FORBIDDEN_MARKDOWN.items():
            if pattern.search(text):
                problems.append(f"{label} appears in {markdown.relative_to(dest)}")

    if dangling_refs != absent_refs:
        problems.append(f"dangling refs {dangling_refs} != expected absent refs {absent_refs}")
    if mapping_misses:
        problems.append(
            "artifact lesson mapping misses remain: " + ", ".join(mapping_misses)
        )

    status_text = ", ".join(f"{key}={artifact_counts[key]}" for key in sorted(artifact_counts))
    miss_text = ", ".join(mapping_misses) if mapping_misses else "none"
    ambiguous_text = json.dumps(mapping_ambiguous, sort_keys=True) if mapping_ambiguous else "none"
    manifest = "\n".join(
        [
            "CENTRAL MARKDOWN STORE VERIFY",
            f"artifact rows: {sum(artifact_counts.values())}",
            f"artifact summary: {status_text}",
            f"mapping misses ({len(mapping_misses)}): {miss_text}",
            f"mapping ambiguities ({len(mapping_ambiguous)}): {ambiguous_text}",
            f"projected image bytes: {projected_bytes}",
            f"guides written: {len(guide_files)}",
            f"tasks files written: {len(task_files)}",
            f"usable rows placed: {len(usable_rows)}",
            f"blocked rows listed: {len(blocked_rows)}",
            f"image files copied: {len(image_files)}",
            f"copied image bytes: {copied_bytes}",
            f"external refs unchanged: {external_refs}",
            f"absent refs unchanged: {absent_refs}",
            f"dangling refs remaining: {dangling_refs}",
            f"verification: {'PASS' if not problems else 'FAIL'}",
        ]
    )
    if problems:
        manifest += "\nproblems:\n" + "\n".join(f"- {problem}" for problem in problems)
    return not problems, manifest


def main() -> int:
    args = parse_args()
    try:
        grades = selected_grades(args.grades)
        dest = safe_destination(args.dest)
        all_lessons = discover_lessons()
        artifact_counts, rows = read_artifact()
        _, mapping_misses, mapping_ambiguous = resolve_artifact_codes(all_lessons, rows)
        selected = {
            grade: all_lessons[grade][: args.limit] if args.limit else all_lessons[grade]
            for grade in grades
        }
        rows_by_code: dict[str, list[dict[str, Any]]] = defaultdict(list)
        for row in rows:
            rows_by_code[row["lesson"]].append(row)
        plans = {
            lesson.code: image_plan(lesson)
            for grade_lessons in selected.values()
            for lesson in grade_lessons
        }
        projected_bytes = sum(plan.projected_bytes for plan in plans.values())
        if projected_bytes > MAX_IMAGE_BYTES:
            blocked(
                f"projected image total is {projected_bytes} bytes, above the 6 GB limit"
            )
        write_tree(dest, selected, rows_by_code, plans)
        if args.verify:
            ok, manifest = verify_tree(
                dest,
                selected,
                rows_by_code,
                plans,
                artifact_counts,
                mapping_misses,
                mapping_ambiguous,
            )
            print(manifest)
            return 0 if ok else 1
        print(f"wrote central Markdown store to {dest}")
        print(f"projected image bytes: {projected_bytes}")
        return 0
    except BuildBlocked as error:
        print(f"BLOCKED: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
