#!/usr/bin/env python3
"""Compile verbatim activity prompts, sequences, and reviewed guide questions.

The K-5 teacher guides are fixed-width Markdown extracts of two-column PDFs.
The grade 6-8 guides are linear Docling Markdown.  Prompt and sequence
extraction only accepts the labelled ``Student Task Statement``, ``Activity
Synthesis``, and ``Lesson Synthesis`` regions.  Guide questions are a separate,
narrow reviewed input: their exact text, source span, authored location, label
origin, and review status are checked against the source guide before emission.
"""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
GUIDES = ROOT / "curriculum/im_teacher_guides"
MIDDLE_GUIDES = (
    ROOT
    / "hermes/app/runtime/experiments/gemma4_tutor/docling/full-output"
    / "TeacherLessonGuides"
)
OUTPUT = ROOT / "curriculum/im/generated/compiled_lesson_context.pl"
L17_CODE = "IM-G1-U3-L17"
L17_SOURCE = "curriculum/im_teacher_guides/grade1/unit3/lesson17.md"

ANCHOR_RE = re.compile(r"_Anchor ID: `([^`]+)`")
MIDDLE_GUIDE_RE = re.compile(
    r"Grade([678])-(\d+)-(\d+)-Lesson-teacher-guide-$"
)
MIDDLE_TASK_RE = re.compile(
    r"^(?:## |- )Student Task Statement(?: \d+)?$"
)
MIDDLE_CUTOFF_RE = re.compile(
    r"^## (?:Lesson \d+ (?:Summary|Practice Problems)|Glossary)$"
)
PICTURE_DESCRIPTION_RE = re.compile(
    r"^!\[Picture \d+\]\([^\n]+\)\n\n(.*?)\n\nProvenance: `[^`]+`$",
    re.MULTILINE | re.DOTALL,
)
IMAGE_RE = re.compile(r"^!\[Image\]\([^\n]+\)$")
MAJOR_RE = re.compile(r"^\f?(Warm-up|Activity \d+|Lesson Synthesis|Cool-down)\b")
STOP_RE = re.compile(
    r"^(?:Student Response|Advancing Student Thinking|Suggested Centers|"
    r"Responding to Student Thinking|Required Materials|Required Preparation|"
    r"Observation|Section [A-Z] Summary|Narrative|Access for )\b"
)
PAGE_RE = re.compile(
    r"^(?:Grade (?:K|\d+)|Unit \d+|Lesson \d+|Illustrative Mathematics®|"
    r"CC BY(?: NC)? \d{4}|\d+)$"
)
ACTIVITY_SYNTHESIS_RE = re.compile(r"Activity Synthesis\s*$")
LAYOUT_FRAGMENT_RE = re.compile(
    r"(?:^(?:A|Ac|Act|Acti|Activ|Activi|Activit|Les|Less|Lesso|MLR\w*|"
    r"esson \d+|son \d+|on \d+)$| {3,}(?:Act\w*|Launch|MLR\w*)$)",
    re.MULTILINE,
)


@dataclass(frozen=True)
class Item:
    heading: str
    text: str
    line: int


@dataclass(frozen=True)
class LessonContext:
    code: str
    source: str
    prompts: tuple[Item, ...]
    sequences: tuple[Item, ...]


@dataclass(frozen=True)
class GuideQuestion:
    code: str
    purpose: str
    text: str
    source: str
    line_start: int
    line_end: int
    activity_location: str
    label_origin: str
    review_status: str
    author_heading: str | None = None
    author_heading_line: int | None = None
    reviewer: str | None = None


@dataclass(frozen=True)
class LessonAbsence:
    code: str
    source: str
    reason: str


# This is intentionally not a corpus classifier.  It is the reviewed L17 input
# named by the vertical-slice specification.  Human-classified advancing
# candidates remain pending until a reviewer is recorded.
REVIEWED_GUIDE_QUESTIONS = (
    GuideQuestion(
        code=L17_CODE,
        purpose="assessing",
        text=(
            "What is the sum? How do you know? What equation can I write to "
            "show the total?"
        ),
        source=L17_SOURCE,
        line_start=200,
        line_end=204,
        activity_location="Activity 1 — Launch",
        label_origin="author_heading",
        review_status="approved",
        author_heading="Launch",
        author_heading_line=179,
    ),
    GuideQuestion(
        code=L17_CODE,
        purpose="assessing",
        text="What did _____ do to represent the problem?",
        source=L17_SOURCE,
        line_start=294,
        line_end=297,
        activity_location="Activity 2 — Activity Synthesis",
        label_origin="author_heading",
        review_status="approved",
        author_heading="Activity Synthesis",
        author_heading_line=286,
    ),
    GuideQuestion(
        code=L17_CODE,
        purpose="advancing",
        text=(
            "How are the different strategies similar? How are they different?"
        ),
        source=L17_SOURCE,
        line_start=249,
        line_end=253,
        activity_location=(
            "Activity 2 — Access for English Language Learners, MLR7 Compare "
            "and Connect"
        ),
        label_origin="human_classification",
        review_status="approved",
        reviewer="Tio Savich (2026-08-12): approved as advancing",
    ),
    GuideQuestion(
        code=L17_CODE,
        purpose="advancing",
        text="If I add 7, how could we record the sum with an equation?",
        source=L17_SOURCE,
        line_start=316,
        line_end=323,
        activity_location="Lesson Synthesis",
        label_origin="human_classification",
        review_status="approved",
        reviewer="Tio Savich (2026-08-12): approved as advancing",
    ),
    GuideQuestion(
        code=L17_CODE,
        purpose="advancing",
        text=(
            "How can I write one equation to show that these two expressions "
            "are equivalent?"
        ),
        source=L17_SOURCE,
        line_start=316,
        line_end=323,
        activity_location="Lesson Synthesis",
        label_origin="human_classification",
        review_status="approved",
        reviewer="Tio Savich (2026-08-12): approved as advancing",
    ),
)


def raw_extract(text: str) -> tuple[list[str], int] | None:
    marker = "## Full Teacher Guide (raw extract)"
    marker_at = text.find(marker)
    if marker_at < 0:
        return None
    fence_at = text.find("```", marker_at + len(marker))
    if fence_at < 0:
        return None
    body_at = text.find("\n", fence_at)
    fence_end = text.find("\n```", body_at)
    if body_at < 0 or fence_end < 0:
        return None
    line_offset = text[: body_at + 1].count("\n")
    return text[body_at + 1 : fence_end].splitlines(), line_offset


def section_heading(line: str) -> str | None:
    match = MAJOR_RE.match(line)
    return match.group(1) if match else None


def page_furniture(line: str) -> bool:
    value = line.replace("\f", "").strip()
    return bool(
        PAGE_RE.fullmatch(value)
        or "Illustrative Mathematics®" in value
        or (re.search(r"\bGrade (?:K|\d+)\b", value) and "CC BY" in value)
        or re.fullmatch(r"(?:Grade (?:K|\d+)\s+)?Unit \d+", value)
        or re.fullmatch(r"Lesson \d+", value)
    )


def clean_lines(parts: list[str]) -> str:
    """Remove PDF furniture while retaining the guide's words and order."""
    kept: list[str] = []
    blank = False
    for raw in parts:
        value = raw.replace("\f", "").strip()
        if PAGE_RE.fullmatch(value):
            continue
        if not value:
            if kept:
                blank = True
            continue
        if blank and kept[-1] != "":
            kept.append("")
        kept.append(value)
        blank = False
    while kept and kept[-1] == "":
        kept.pop()
    return "\n".join(kept)


def task_statement(
    lines: list[str], start: int, heading: str
) -> tuple[Item | None, int]:
    marker = lines[start]
    task_col = marker.find("Student Task Statement")
    launch_col = marker.find("Launch", task_col + len("Student Task Statement"))
    boundary = max(task_col + len("Student Task Statement"), launch_col - 3) \
        if launch_col > task_col else None
    parts: list[str] = []
    crossed_page = False
    index = start + 1
    while index < len(lines):
        line = lines[index]
        if line.startswith("\f"):
            crossed_page = True
            break
        if page_furniture(line):
            index += 1
            continue
        left = line[:boundary] if boundary is not None else line
        stripped = left.replace("\f", "").strip()
        if section_heading(line) or STOP_RE.match(stripped):
            break
        if "Student Task Statement" in stripped or "Activity Synthesis" in stripped:
            break
        parts.append(left)
        index += 1
    text = clean_lines(parts)
    if crossed_page or LAYOUT_FRAGMENT_RE.search(text):
        text = ""
    if not text:
        return None, max(index, start + 1)
    return Item(f"{heading} — Student Task Statement", text, start + 1), index


def activity_synthesis(
    lines: list[str], start: int, heading: str
) -> tuple[Item | None, int]:
    marker = lines[start]
    column = marker.find("Activity Synthesis")
    parts: list[str] = []
    crossed_page = False
    index = start + 1
    while index < len(lines):
        line = lines[index]
        if line.startswith("\f"):
            crossed_page = True
            break
        if page_furniture(line):
            index += 1
            continue
        if section_heading(line):
            break
        full = line.replace("\f", "").strip()
        if STOP_RE.match(full) or "Student Task Statement" in full:
            break
        part = line[column:] if column > 0 and len(line) > column else ("" if column > 0 else line)
        parts.append(part)
        index += 1
    text = clean_lines(parts)
    if crossed_page or LAYOUT_FRAGMENT_RE.search(text):
        text = ""
    if text and not ("•" in text or "“" in text or '"' in text):
        text = ""
    if not text:
        return None, max(index, start + 1)
    return Item(f"{heading} — Activity Synthesis", text, start + 1), index


def lesson_synthesis(lines: list[str], start: int) -> tuple[Item | None, int]:
    parts: list[str] = []
    crossed_page = False
    index = start + 1
    while index < len(lines):
        line = lines[index]
        if line.startswith("\f"):
            crossed_page = True
            break
        if page_furniture(line):
            index += 1
            continue
        heading = section_heading(line)
        full = line.replace("\f", "").strip()
        if heading or STOP_RE.match(full):
            break
        parts.append(line)
        index += 1
    text = clean_lines(parts)
    if crossed_page or LAYOUT_FRAGMENT_RE.search(text):
        text = ""
    if not text:
        return None, max(index, start + 1)
    return Item("Lesson Synthesis", text, start + 1), index


def parse_guide(path: Path) -> tuple[LessonContext | None, Counter[str]]:
    failures: Counter[str] = Counter()
    text = path.read_text(encoding="utf-8")
    anchor = ANCHOR_RE.search(text)
    if not anchor:
        failures["missing_anchor"] += 1
        return None, failures
    raw = raw_extract(text)
    if raw is None:
        failures["missing_or_unclosed_raw_extract"] += 1
        return None, failures
    lines, line_offset = raw
    prompts: list[Item] = []
    sequences: list[Item] = []
    current = "Lesson"
    index = 0
    task_markers = 0
    synthesis_markers = 0
    discarded_task = False
    discarded_synthesis = False
    while index < len(lines):
        line = lines[index]
        major = section_heading(line)
        if major:
            current = major
            if major == "Lesson Synthesis":
                synthesis_markers += 1
                item, next_index = lesson_synthesis(lines, index)
                if item:
                    sequences.append(Item(item.heading, item.text, item.line + line_offset))
                else:
                    discarded_synthesis = True
                index = next_index
                continue
        if "Student Task Statement" in line:
            task_markers += 1
            item, next_index = task_statement(lines, index, current)
            if item:
                prompts.append(Item(item.heading, item.text, item.line + line_offset))
            else:
                discarded_task = True
            index = next_index
            continue
        if ACTIVITY_SYNTHESIS_RE.search(line):
            synthesis_markers += 1
            item, next_index = activity_synthesis(lines, index, current)
            if item:
                sequences.append(Item(item.heading, item.text, item.line + line_offset))
            else:
                discarded_synthesis = True
            index = next_index
            continue
        index += 1
    if task_markers and not prompts:
        failures["unrecoverable_task_statement_layout"] += 1
    elif not task_markers:
        failures["no_student_task_statement_heading"] += 1
    if synthesis_markers and not sequences:
        failures["unrecoverable_synthesis_layout"] += 1
    elif not synthesis_markers:
        failures["no_synthesis_heading"] += 1
    if discarded_task and prompts:
        failures["some_task_statements_cross_page_or_contain_layout_fragments"] += 1
    if discarded_synthesis and sequences:
        failures["some_syntheses_cross_page_or_contain_layout_fragments"] += 1
    source = path.relative_to(ROOT).as_posix()
    return LessonContext(anchor.group(1), source, tuple(prompts), tuple(sequences)), failures


def middle_guide_code(path: Path) -> str | None:
    match = MIDDLE_GUIDE_RE.fullmatch(path.parent.name)
    if not match:
        return None
    grade, unit, lesson = match.groups()
    return f"IM-G{grade}-U{int(unit)}-L{int(lesson)}"


def picture_description_lines(path: Path, lines: list[str]) -> set[int] | None:
    """Locate prior model annotations so none enter the verbatim artifact."""
    descriptions_path = path.with_name("picture_descriptions.md")
    if not descriptions_path.is_file():
        return None
    descriptions = PICTURE_DESCRIPTION_RE.findall(
        descriptions_path.read_text(encoding="utf-8")
    )
    excluded = {index for index, line in enumerate(lines) if IMAGE_RE.fullmatch(line)}
    for description in descriptions:
        description_lines = description.splitlines()
        found_at = None
        for index in range(len(lines) - len(description_lines) + 1):
            if any(
                candidate in excluded
                for candidate in range(index, index + len(description_lines))
            ):
                continue
            if lines[index : index + len(description_lines)] == description_lines:
                found_at = index
                break
        if found_at is None:
            return None
        excluded.update(range(found_at, found_at + len(description_lines)))
    return excluded


def middle_section_item(
    lines: list[str],
    start: int,
    end: int,
    excluded: set[int],
) -> Item | None:
    section_end = start + 1
    while section_end < end and not lines[section_end].startswith("## "):
        section_end += 1
    parts = [
        (index, line)
        for index, line in enumerate(lines[start + 1 : section_end], start + 1)
        if index not in excluded
    ]
    while parts and not parts[0][1].strip():
        parts.pop(0)
    while parts and not parts[-1][1].strip():
        parts.pop()
    if not parts:
        return None
    heading = lines[start].removeprefix("## ").removeprefix("- ").strip()
    return Item(heading, "\n".join(line for _, line in parts), parts[0][0] + 1)


def parse_middle_guide(
    path: Path,
) -> tuple[LessonContext | None, LessonAbsence | None, Counter[str]]:
    failures: Counter[str] = Counter()
    source = path.relative_to(ROOT).as_posix()
    code = middle_guide_code(path)
    if code is None:
        failures["middle_school_unrecognized_guide_path"] += 1
        return None, None, failures
    lines = path.read_text(encoding="utf-8").splitlines()
    excluded = picture_description_lines(path, lines)
    if excluded is None:
        failures["middle_school_unmatched_picture_annotations"] += 1
        return (
            None,
            LessonAbsence(code, source, "unmatched_picture_annotations"),
            failures,
        )
    body_start = next(
        (index for index, line in enumerate(lines) if line == "## Activity Narrative"),
        None,
    )
    if body_start is None:
        failures["middle_school_missing_activity_narrative"] += 1
        return (
            None,
            LessonAbsence(code, source, "missing_activity_narrative"),
            failures,
        )
    body_end = next(
        (
            index
            for index, line in enumerate(lines[body_start:], body_start)
            if MIDDLE_CUTOFF_RE.fullmatch(line)
        ),
        len(lines),
    )
    prompts: list[Item] = []
    sequences: list[Item] = []
    for index in range(body_start, body_end):
        line = lines[index]
        if MIDDLE_TASK_RE.fullmatch(line):
            item = middle_section_item(lines, index, body_end, excluded)
            if item:
                prompts.append(item)
            else:
                failures["middle_school_empty_or_model_only_task_statement"] += 1
        elif line in {
            "## Activity Synthesis",
            "- Activity Synthesis",
            "## Lesson Synthesis",
            "- Lesson Synthesis",
        }:
            item = middle_section_item(lines, index, body_end, excluded)
            if item:
                sequences.append(item)
            else:
                failures["middle_school_empty_or_model_only_synthesis"] += 1
    if not prompts:
        failures["middle_school_no_recoverable_task_statement"] += 1
        return (
            None,
            LessonAbsence(code, source, "no_recoverable_task_statement"),
            failures,
        )
    if not sequences:
        failures["middle_school_no_recoverable_synthesis"] += 1
    return LessonContext(code, source, tuple(prompts), tuple(sequences)), None, failures


def prolog_atom(value: str) -> str:
    return "'" + value.replace("\\", "\\\\").replace("'", "\\'") + "'"


def prolog_string(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def normalized_source_text(value: str) -> str:
    """Normalize PDF column wrapping without changing words or punctuation."""
    return " ".join(value.split())


def cited_span_contains(question_text: str, cited_lines: list[str]) -> bool:
    """Accept an exact question only in a fixed-column projection of its span."""
    expected = normalized_source_text(question_text)
    widest = max((len(line) for line in cited_lines), default=0)
    return any(
        expected in normalized_source_text("\n".join(line[column:] for line in cited_lines))
        for column in range(widest + 1)
    )


def validate_guide_question(question: GuideQuestion) -> None:
    if question.code != L17_CODE or question.source != L17_SOURCE:
        raise ValueError("guide-question input is restricted to the reviewed L17 guide")
    if question.purpose not in {"assessing", "advancing"}:
        raise ValueError(f"unsupported guide-question purpose: {question.purpose}")
    if question.label_origin not in {"author_heading", "human_classification"}:
        raise ValueError(
            f"unsupported guide-question label origin: {question.label_origin}"
        )
    if question.review_status not in {"approved", "pending_human_review"}:
        raise ValueError(
            f"unsupported guide-question review status: {question.review_status}"
        )

    source_path = ROOT / question.source
    try:
        # ``splitlines`` treats the PDF form-feed marker as a line boundary;
        # source citations use physical Markdown newline numbers instead.
        source_lines = source_path.read_text(encoding="utf-8").split("\n")
    except (OSError, UnicodeError) as exc:
        raise ValueError(f"guide-question source cannot be read: {question.source}") from exc
    if not (1 <= question.line_start <= question.line_end <= len(source_lines)):
        raise ValueError(
            f"guide-question span is outside its source: "
            f"{question.source}:{question.line_start}-{question.line_end}"
        )
    cited_lines = source_lines[question.line_start - 1 : question.line_end]
    if not cited_span_contains(question.text, cited_lines):
        raise ValueError(
            f"guide-question text is absent from its cited span: "
            f"{question.source}:{question.line_start}-{question.line_end}"
        )

    if question.label_origin == "author_heading":
        if question.author_heading is None or question.author_heading_line is None:
            raise ValueError("author_heading origin requires an exact heading and line")
        if not (1 <= question.author_heading_line <= len(source_lines)):
            raise ValueError("author heading line is outside the guide source")
        heading_line = source_lines[question.author_heading_line - 1]
        if question.author_heading not in heading_line:
            raise ValueError(
                f"claimed author heading is absent at {question.source}:"
                f"{question.author_heading_line}"
            )
        if question.reviewer is not None:
            raise ValueError("author-heading records do not carry a human reviewer")
    else:
        if question.author_heading is not None or question.author_heading_line is not None:
            raise ValueError("human classification cannot claim an author heading")
        if question.review_status == "approved" and not question.reviewer:
            raise ValueError("approved human classification requires reviewer evidence")
        if question.review_status == "pending_human_review" and question.reviewer is not None:
            raise ValueError("pending human classification cannot name a reviewer")


def validated_guide_questions() -> tuple[GuideQuestion, ...]:
    for question in REVIEWED_GUIDE_QUESTIONS:
        validate_guide_question(question)
    return REVIEWED_GUIDE_QUESTIONS


def item_term(item: Item) -> str:
    return (
        "context_item("
        f"{prolog_string(item.heading)}, {prolog_string(item.text)}, line({item.line}))"
    )


def list_term(items: tuple[Item, ...]) -> str:
    if not items:
        return "[]"
    return "[\n        " + ",\n        ".join(item_term(item) for item in items) + "\n    ]"


def review_evidence_term(question: GuideQuestion) -> str:
    if question.label_origin == "author_heading":
        assert question.author_heading is not None
        assert question.author_heading_line is not None
        return (
            f"author_heading({prolog_string(question.author_heading)}, "
            f"line({question.author_heading_line}))"
        )
    if question.reviewer:
        return f"human_review({prolog_string(question.reviewer)})"
    return "none"


def guide_question_term(question: GuideQuestion) -> str:
    return (
        "guide_question("
        f"{question.purpose}, {prolog_string(question.text)}, "
        f"source_guide({prolog_atom(question.source)}), "
        f"source_span({question.line_start}, {question.line_end}), "
        f"activity_location({prolog_string(question.activity_location)}), "
        f"label_origin({question.label_origin}), "
        f"review_status({question.review_status}), "
        f"review_evidence({review_evidence_term(question)}))"
    )


def render(
    contexts: list[LessonContext],
    questions: tuple[GuideQuestion, ...],
    absences: list[LessonAbsence],
    failures: Counter[str],
    guide_count: int,
) -> str:
    prompt_count = sum(bool(context.prompts) for context in contexts)
    sequence_count = sum(bool(context.sequences) for context in contexts)
    lines = [
        "/** <module> Generated verbatim IM lesson prompts, sequences, and guide questions",
        " *",
        " * Generated by scripts/research/extract_lesson_context.py.",
        " * Do not edit by hand; update the extractor or source guides and regenerate.",
        " */",
        ":- module(compiled_lesson_context,",
        "          [ compiled_lesson_context/4,",
        "            compiled_lesson_guide_question/2,",
        "            compiled_lesson_context_summary/3,",
        "            compiled_lesson_context_defeat/2,",
        "            compiled_lesson_context_absent/3",
        "          ]).",
        "",
        ":- dynamic compiled_lesson_context_absent/3.",
        ":- dynamic compiled_lesson_guide_question/2.",
        "",
        f"compiled_lesson_context_summary({guide_count}, {prompt_count}, {sequence_count}).",
    ]
    for pattern, count in sorted(failures.items()):
        lines.append(
            f"compiled_lesson_context_defeat({prolog_atom(pattern)}, {count})."
        )
    for absence in sorted(absences, key=lambda item: item.code):
        lines.append(
            "compiled_lesson_context_absent("
            f"{prolog_atom(absence.code)}, "
            f"source({prolog_atom(absence.source)}), "
            f"{prolog_atom(absence.reason)})."
        )
    lines.append("")
    for context in contexts:
        if not context.prompts and not context.sequences:
            continue
        lines.extend(
            [
                f"compiled_lesson_context({prolog_atom(context.code)},",
                f"    {list_term(context.prompts)},",
                f"    {list_term(context.sequences)},",
                f"    source({prolog_atom(context.source)})).",
                "",
            ]
        )
    for question in questions:
        lines.extend(
            [
                "compiled_lesson_guide_question(",
                f"    {prolog_atom(question.code)},",
                f"    {guide_question_term(question)}).",
                "",
            ]
        )
    return "\n".join(lines).rstrip() + "\n"


def compile_cache() -> tuple[
    str,
    list[LessonContext],
    list[LessonAbsence],
    Counter[str],
    int,
]:
    guides = sorted(GUIDES.rglob("*.md"))
    middle_guides = [
        path
        for grade in ("Grade6", "Grade7", "Grade8")
        for path in sorted((MIDDLE_GUIDES / grade).glob("*/document.md"))
    ]
    contexts: list[LessonContext] = []
    absences: list[LessonAbsence] = []
    failures: Counter[str] = Counter()
    for guide in guides:
        context, guide_failures = parse_guide(guide)
        failures.update(guide_failures)
        if context:
            contexts.append(context)
    for guide in middle_guides:
        context, absence, guide_failures = parse_middle_guide(guide)
        failures.update(guide_failures)
        if context:
            contexts.append(context)
        if absence:
            absences.append(absence)
    contexts.sort(key=lambda context: context.code)
    questions = validated_guide_questions()
    source_count = len(guides) + len(middle_guides)
    return (
        render(contexts, questions, absences, failures, source_count),
        contexts,
        absences,
        failures,
        source_count,
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="fail if the cache is stale")
    parser.add_argument("--output", type=Path, default=OUTPUT)
    args = parser.parse_args()
    rendered, contexts, absences, failures, source_count = compile_cache()
    output = args.output if args.output.is_absolute() else ROOT / args.output
    output_label = output.relative_to(ROOT) if output.is_relative_to(ROOT) else output
    if args.check:
        actual = output.read_text(encoding="utf-8") if output.is_file() else ""
        if actual != rendered:
            print(f"lesson context cache is stale: {output_label}")
            return 1
        print(f"lesson context cache is current: {output_label}")
    else:
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(rendered, encoding="utf-8")
        print(f"wrote {output_label}")
    print(
        "guides={guides} prompt_lessons={prompts} "
        "sequence_lessons={sequences} absent_lessons={absences}".format(
            guides=source_count,
            prompts=sum(bool(context.prompts) for context in contexts),
            sequences=sum(bool(context.sequences) for context in contexts),
            absences=len(absences),
        )
    )
    for pattern, count in sorted(failures.items()):
        print(f"defeated {pattern}={count}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
