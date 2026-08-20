#!/usr/bin/env python3
"""Compile verbatim activity prompts, sequences, and attributed guide questions.

The K-5 teacher guides are fixed-width Markdown extracts of two-column PDFs.
The grade 6-8 guides are linear Docling Markdown.  Prompt and sequence
extraction only accepts the labelled ``Student Task Statement``, ``Activity
Synthesis``, and ``Lesson Synthesis`` regions.  Guide questions are a separate,
narrow attributed input: their exact text, source span, authored location,
label origin, and admission status are checked against the source guide before
emission. Human-reviewed and mechanically admitted warrants stay distinct.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import tempfile
from collections import Counter
from dataclasses import dataclass, replace
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from scripts.curriculum import structure_to_task_rows as anchoring  # noqa: E402


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
    r"(?P<band>Kindergarten|Grade[1-8])-(?P<unit>\d+)-(?P<lesson>\d+)-"
    r"Lesson-teacher-guide-$"
)
MIDDLE_TASK_RE = re.compile(
    r"^(?:## |- )Student Task Statement(?: \d+)?$"
)
MIDDLE_CUTOFF_RE = re.compile(
    r"^## (?:Lesson \d+ (?:Summary|Practice Problems)|Glossary)$"
)
GUIDE_QUESTION_START_RE = re.compile(
    r"\b(?:What|How|Why|Which|Where|When|Who|Can|Could|Would|"
    r"Do|Does|Did|Is|Are|Was|Were|If)\b"
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
    mechanical_builder: str | None = None
    mechanical_date: str | None = None
    mechanical_warrant: str | None = None
    region_identity: str | None = None
    region_identity_kind: str | None = None
    held_reason: str | None = None


@dataclass(frozen=True)
class LessonAbsence:
    code: str
    source: str
    reason: str


@dataclass(frozen=True)
class GuideQuestionAbsence:
    code: str
    purpose: str
    source: str
    reason: str


def _admission_store_dump_script() -> str:
    """Return a Prolog reader for the two generated admission stores.

    The stores, rather than the stage-0 candidate file, are the serving
    authority. Reading them through SWI-Prolog also preserves the C1 emitter's
    widened labels id key and exact-duplicate collapse: the compiled cache gets
    one row for every emitted admitted/held row, never a second reconstruction
    of the candidate-id rules.
    """
    return r'''
:- use_module(library(http/json)).
:- use_module(curriculum/im/generated/admitted_teacher_question_labels, []).
:- use_module(curriculum/im/generated/admitted_guide_questions, []).
:- initialization(main).

origin_fields(machine_classification, machine_classification, none).
origin_fields(author_heading(Title), author_heading, Title).

write_row(Tag, Dict) :-
    format('~w ', [Tag]),
    json_write_dict(current_output, Dict, [width(0)]),
    nl.

main :-
    set_stream(user_output, encoding(utf8)),
    forall(
        admitted_teacher_question_labels:admitted_question_label(
            Lesson, Label, Text,
            anchor(source_path(Source), source_file_sha256(SourceSha),
                   char_span(Start, End), region_type(RegionType),
                   label_origin(author_heading(Heading)), warrant(im_author_heading)),
            testimony(im_author_heading(Heading), extraction(Builder), date(Date)), _),
        write_row('LABEL',
                    _{lesson:Lesson, label:Label, text:Text, source:Source,
                      source_sha256:SourceSha,
                      char_start:Start, char_end:End, region_type:RegionType,
                      label_origin:author_heading, origin_title:Heading,
                      warrant:im_author_heading, region_identity:none,
                      status:mechanically_admitted, heading:Heading,
                      builder:Builder, date:Date, held_reason:none})),
    forall(
        admitted_teacher_question_labels:admitted_question_label(
            Lesson, region(Region), Text,
            anchor(source_path(Source), source_file_sha256(SourceSha),
                   char_span(Start, End), region_type(RegionType),
                   label_origin(machine_classification),
                   warrant(printed_region(Region))),
            testimony(extraction(Builder), date(Date)), _),
        write_row('LABEL',
                    _{lesson:Lesson, label:Region, text:Text, source:Source,
                      source_sha256:SourceSha,
                      char_start:Start, char_end:End, region_type:RegionType,
                      label_origin:machine_classification, origin_title:none,
                      warrant:printed_region, region_identity:Region,
                      status:mechanically_admitted, heading:none,
                      builder:Builder, date:Date, held_reason:none})),
    forall(
        admitted_teacher_question_labels:held_question_label(
            Lesson, Label, Text,
            anchor(source_path(Source), source_file_sha256(SourceSha),
                   char_span(Start, End), region_type(RegionType),
                   label_origin(Origin), warrant(none)), _, held(HeldReason)),
        ( origin_fields(Origin, OriginKind, OriginTitle),
          term_string(HeldReason, HeldText, [quoted(false)]),
          write_row('LABEL',
                    _{lesson:Lesson, label:Label, text:Text, source:Source,
                      source_sha256:SourceSha,
                      char_start:Start, char_end:End, region_type:RegionType,
                      label_origin:OriginKind, origin_title:OriginTitle,
                      warrant:none, region_identity:RegionType,
                      status:mechanically_held, heading:none,
                      builder:none, date:none, held_reason:HeldText})
        )),
    forall(
        admitted_guide_questions:admitted_guide_question(
            Lesson, Label, Text,
            anchor(source_guide(Source), doc_sha256(DocSha), line_span(Start, End),
                   activity_location(Location), label_origin(author_heading(Heading)),
                   warrant(im_author_heading)),
            testimony(im_author_heading(Heading), extraction(Builder), date(Date)), _),
        write_row('GUIDE',
                    _{lesson:Lesson, label:Label, text:Text, source:Source,
                      doc_sha256:DocSha,
                      line_start:Start, line_end:End, activity_location:Location,
                      label_origin:author_heading, origin_title:Heading,
                      warrant:im_author_heading, region_identity:none,
                      status:mechanically_admitted, heading:Heading,
                      builder:Builder, date:Date, held_reason:none})),
    forall(
        admitted_guide_questions:admitted_guide_question(
            Lesson, region(Region), Text,
            anchor(source_guide(Source), doc_sha256(DocSha), line_span(Start, End),
                   activity_location(Location), label_origin(machine_classification),
                   warrant(printed_region(Region))),
            testimony(extraction(Builder), date(Date)), _),
        write_row('GUIDE',
                    _{lesson:Lesson, label:Region, text:Text, source:Source,
                      doc_sha256:DocSha,
                      line_start:Start, line_end:End, activity_location:Location,
                      label_origin:machine_classification, origin_title:none,
                      warrant:printed_region, region_identity:Region,
                      status:mechanically_admitted, heading:none,
                      builder:Builder, date:Date, held_reason:none})),
    forall(
        admitted_guide_questions:held_guide_question(
            Lesson, Label, Text,
            anchor(source_guide(Source), doc_sha256(DocSha), line_span(Start, End),
                   activity_location(Location), label_origin(Origin),
                   warrant(none)), _, held(HeldReason)),
        ( origin_fields(Origin, OriginKind, OriginTitle),
          term_string(HeldReason, HeldText, [quoted(false)]),
          write_row('GUIDE',
                    _{lesson:Lesson, label:Label, text:Text, source:Source,
                      doc_sha256:DocSha,
                      line_start:Start, line_end:End, activity_location:Location,
                      label_origin:OriginKind, origin_title:OriginTitle,
                      warrant:none, region_identity:Location,
                      status:mechanically_held, heading:none,
                      builder:none, date:none, held_reason:HeldText})
        )),
    halt.
'''


def admission_store_rows() -> tuple[list[dict], list[dict]]:
    """Read every emitted admitted/held row through its Prolog module."""
    with tempfile.NamedTemporaryFile(
        "w", suffix=".pl", delete=False, encoding="utf-8"
    ) as handle:
        handle.write(_admission_store_dump_script())
        script_path = Path(handle.name)
    try:
        completed = subprocess.run(
            ["swipl", "-q", "-l", "paths.pl", "-l", str(script_path)],
            cwd=ROOT,
            text=True,
            encoding="utf-8",
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
    finally:
        script_path.unlink(missing_ok=True)
    if completed.returncode != 0:
        raise RuntimeError(
            "admission-store read failed: " + (completed.stderr or completed.stdout)
        )
    labels: list[dict] = []
    guide: list[dict] = []
    for line in completed.stdout.splitlines():
        if line.startswith("LABEL "):
            labels.append(json.loads(line[6:]))
        elif line.startswith("GUIDE "):
            guide.append(json.loads(line[6:]))
        elif line.strip():
            raise RuntimeError(f"unrecognized admission-store line: {line[:120]!r}")
    if not labels or not guide:
        raise RuntimeError(
            f"admission stores came back too small: labels={len(labels)} guide={len(guide)}"
        )
    return labels, guide


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
        review_status="culled_by_reviewer",
        author_heading="Activity Synthesis",
        author_heading_line=286,
        reviewer=(
            "Tio Savich (2026-08-12): culled — the question requires another "
            "student's work; unsuitable for a solo student unless a work "
            "sample is shown"
        ),
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
    band = match.group("band")
    grade = "K" if band == "Kindergarten" else band.removeprefix("Grade")
    unit = match.group("unit")
    lesson = match.group("lesson")
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


def _middle_question_candidates(
    path: Path, *, include_student_tasks: bool
) -> list[tuple[str, str, int]]:
    """Return exact, single-line guide questions before the lesson appendix."""
    lines = path.read_text(encoding="utf-8").splitlines()
    excluded = picture_description_lines(path, lines)
    if excluded is None:
        raise ValueError(f"picture annotations cannot be separated: {path}")
    body_start = next(
        (index for index, line in enumerate(lines) if line == "## Activity Narrative"),
        0,
    )
    body_end = next(
        (
            index
            for index, line in enumerate(lines[body_start:], body_start)
            if MIDDLE_CUTOFF_RE.fullmatch(line)
        ),
        len(lines),
    )
    excluded_headings = (
        "Student Response",
        "Extension Student Response",
        "Are You Ready for More?",
        "Solution",
        "Goals",
        "Learning Targets",
    )
    candidates: list[tuple[str, str, int]] = []
    index = body_start
    while index < body_end:
        raw_heading = lines[index]
        if not (
            raw_heading.startswith("## ")
            or MIDDLE_TASK_RE.fullmatch(raw_heading)
            or raw_heading
            in {"- Activity Synthesis", "- Lesson Synthesis", "- Launch"}
        ):
            index += 1
            continue
        heading = raw_heading.removeprefix("## ").removeprefix("- ").strip()
        section_end = index + 1
        while section_end < body_end and not lines[section_end].startswith("## "):
            section_end += 1
        is_student_task = heading.startswith("Student Task Statement")
        excluded_section = any(heading.startswith(value) for value in excluded_headings)
        if not excluded_section and (include_student_tasks or not is_student_task):
            for line_index in range(index + 1, section_end):
                if line_index in excluded or lines[line_index].startswith("!["):
                    continue
                text = lines[line_index].strip().removeprefix("- ").strip()
                previous_end = 0
                for question_end in (
                    match.start() for match in re.finditer(r"\?", text)
                ):
                    starts = [
                        match.start()
                        for match in GUIDE_QUESTION_START_RE.finditer(
                            text, previous_end, question_end
                        )
                    ]
                    if starts:
                        question = text[starts[-1] : question_end + 1].strip(
                            " '\"\u201c\u201d"
                        )
                        if 8 <= len(question) <= 500:
                            candidates.append((heading, question, line_index + 1))
                    previous_end = question_end + 1
        index = section_end
    return candidates


def extract_docling_guide_questions(
    path: Path, *, label_origin: str
) -> tuple[tuple[GuideQuestion, ...], tuple[GuideQuestionAbsence, ...]]:
    """Select exact assessing and advancing candidates from one Docling guide."""
    code = middle_guide_code(path)
    if code is None:
        raise ValueError(f"unrecognized Docling guide path: {path}")
    def complete(candidate: tuple[str, str, int]) -> bool:
        text = candidate[1]
        return not (
            re.search(r"(?<!\.)\s+[.,;:](?!\.)", text)
            or re.search(
                r"\b(?:What|Which) does (?:represent|mean|equal)\b", text
            )
            or re.search(r"\b(?:of|by|to|from|with)\s*\?", text)
        )

    candidates = [
        candidate
        for candidate in _middle_question_candidates(
            path, include_student_tasks=False
        )
        if complete(candidate)
    ]
    if len(candidates) < 2:
        candidates = [
            candidate
            for candidate in _middle_question_candidates(
                path, include_student_tasks=True
            )
            if complete(candidate)
        ]
    source = path.relative_to(ROOT).as_posix()
    if len(candidates) < 2:
        absences = tuple(
            GuideQuestionAbsence(
                code=code,
                purpose=purpose,
                source=source,
                reason="fewer_than_two_exact_guide_questions",
            )
            for purpose in ("assessing", "advancing")
        )
        return (), absences

    assessing_heading_order = (
        "Building on Student Thinking",
        "Responding to Student Thinking",
        "Launch",
        "Activity Narrative",
        "Math Community",
        "Consider asking:",
        "Discuss with students:",
    )
    advancing_heading_order = (
        "Activity Synthesis",
        "Lesson Synthesis",
        "More Chances",
    )

    def first_for_headings(headings: tuple[str, ...]) -> tuple[str, str, int] | None:
        return next(
            (
                candidate
                for heading in headings
                for candidate in candidates
                if candidate[0] == heading
            ),
            None,
        )

    assessing = first_for_headings(assessing_heading_order) or candidates[0]
    advancing = first_for_headings(advancing_heading_order)
    if advancing is None or advancing == assessing:
        advancing = next(
            candidate for candidate in reversed(candidates) if candidate != assessing
        )
    def record(purpose: str, candidate: tuple[str, str, int]) -> GuideQuestion:
        heading, text, line = candidate
        return GuideQuestion(
            code=code,
            purpose=purpose,
            text=text,
            source=source,
            line_start=line,
            line_end=line,
            activity_location=heading,
            label_origin=label_origin,
            review_status="pending_human_review",
        )

    questions = (record("assessing", assessing), record("advancing", advancing))
    for question in questions:
        validate_guide_question(question)
    return questions, ()


def extract_middle_guide_questions(path: Path) -> tuple[GuideQuestion, GuideQuestion]:
    """Retain the Grade 8 extraction contract used by its pipeline.

    These questions are exact source quotes, but their assessing/advancing
    assignment comes from the heading rules, so the origin is the machine's.
    """
    questions, absences = extract_docling_guide_questions(
        path, label_origin="machine_classification"
    )
    if absences or len(questions) != 2:
        raise ValueError(f"fewer than two exact guide questions: {path}")
    return questions


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


REGION_DISPLAY_TITLES = {
    "building_on_student_thinking": "Building on Student Thinking",
    "responding_to_student_thinking": "Responding to Student Thinking",
    "launch": "Launch",
    "activity_narrative": "Activity Narrative",
    "math_community": "Math Community",
    "consider_asking": "Consider Asking",
    "discuss_with_students": "Discuss with Students",
    "activity_synthesis": "Activity Synthesis",
    "lesson_synthesis": "Lesson Synthesis",
    "more_chances": "More Chances",
    "advancing_student_thinking": "Advancing Student Thinking",
}


def _line_span_from_char_span(content: str, start: int, end: int) -> tuple[int, int]:
    if not (0 <= start <= end <= len(content)):
        raise ValueError(f"admission char span is outside its source: {start}-{end}")
    line_start = content.count("\n", 0, start) + 1
    last_char = start if end == start else end - 1
    line_end = content.count("\n", 0, last_char) + 1
    return line_start, line_end


def _author_heading_line(
    content: str, heading: str, before_line: int, source: str
) -> int:
    lines = content.split("\n")
    for index in range(min(before_line, len(lines)), 0, -1):
        if heading in lines[index - 1]:
            return index
    raise ValueError(
        f"author heading {heading!r} is absent before admitted row in {source}"
    )


def _label_store_question(row: dict) -> GuideQuestion:
    source = row["source"]
    content = (ROOT / source).read_text(encoding="utf-8")
    line_start, line_end = _line_span_from_char_span(
        content, row["char_start"], row["char_end"]
    )
    reproduced_span = anchoring.find_verbatim(content, row["text"])
    if reproduced_span != (row["char_start"], row["char_end"]):
        raise ValueError(
            f"admitted labels text is absent at its char span: {source}:"
            f"{row['char_start']}-{row['char_end']}"
        )
    origin = row["label_origin"]
    heading = row["origin_title"] if origin == "author_heading" else None
    # The attributed store carries the author title but not its source line.
    # Some fixed-width guide extracts split that heading across columns, so the
    # compiled row does not invent a line number. The store check re-derives the
    # exact author-heading origin; this builder re-derives the question span.
    heading_line = None
    status = row["status"]
    return GuideQuestion(
        code=row["lesson"],
        purpose=row["label"],
        text=row["text"],
        source=source,
        line_start=line_start,
        line_end=line_end,
        activity_location=REGION_DISPLAY_TITLES.get(
            row["region_type"], row["region_type"].replace("_", " ").title()
        ),
        label_origin=origin,
        review_status=status,
        author_heading=heading,
        author_heading_line=heading_line,
        mechanical_builder=row["builder"] if status == "mechanically_admitted" else None,
        mechanical_date=row["date"] if status == "mechanically_admitted" else None,
        mechanical_warrant=(
            row["warrant"] if status == "mechanically_admitted" else None
        ),
        region_identity=(
            row["region_identity"]
            if row["warrant"] == "printed_region"
            else None
        ),
        region_identity_kind=(
            "atom" if row["warrant"] == "printed_region" else None
        ),
        held_reason=row["held_reason"] if status == "mechanically_held" else None,
    )


def _guide_admission_key(row: dict) -> tuple[str, int, str, str]:
    return (
        row["source"], row["line_start"], row["text"], row["activity_location"]
    )


def _question_admission_key(question: GuideQuestion) -> tuple[str, int, str, str]:
    return (
        question.source,
        question.line_start,
        question.text,
        question.activity_location,
    )


def join_mechanical_admission(
    extracted: list[GuideQuestion], guide_rows: list[dict]
) -> tuple[GuideQuestion, ...]:
    """Join every extracted guide candidate to one emitted disposition."""
    by_key: dict[tuple[str, int, str, str], list[dict]] = {}
    for row in guide_rows:
        by_key.setdefault(_guide_admission_key(row), []).append(row)

    joined: list[GuideQuestion] = []
    for question in extracted:
        key = _question_admission_key(question)
        matches = by_key.get(key, [])
        if len(matches) != 1:
            raise ValueError(
                "guide-question admission join expected one emitted row, "
                f"found {len(matches)} for {key!r}"
            )
        row = matches.pop()
        if not matches:
            del by_key[key]
        status = row["status"]
        joined.append(
            replace(
                question,
                label_origin=row["label_origin"],
                review_status=status,
                author_heading=(
                    row["origin_title"]
                    if row["label_origin"] == "author_heading"
                    else None
                ),
                author_heading_line=None,
                reviewer=None,
                mechanical_builder=(
                    row["builder"] if status == "mechanically_admitted" else None
                ),
                mechanical_date=(
                    row["date"] if status == "mechanically_admitted" else None
                ),
                mechanical_warrant=(
                    row["warrant"] if status == "mechanically_admitted" else None
                ),
                region_identity=(
                    row["region_identity"]
                    if row["warrant"] == "printed_region"
                    else None
                ),
                region_identity_kind=(
                    "string" if row["warrant"] == "printed_region" else None
                ),
                held_reason=(
                    row["held_reason"] if status == "mechanically_held" else None
                ),
            )
        )
    leftovers = sum(len(rows) for rows in by_key.values())
    if leftovers:
        sample = next(iter(by_key))
        raise ValueError(
            f"guide admission store has {leftovers} unmatched emitted row(s); "
            f"first key {sample!r}"
        )
    return tuple(joined)


def validate_guide_question(question: GuideQuestion) -> None:
    tracked_match = re.fullmatch(
        r"curriculum/im_teacher_guides/(?P<band>kindergarten|grade[1-8])/"
        r"unit(?P<unit>\d+)/lesson(?P<lesson>\d+)\.md",
        question.source,
    )
    if tracked_match is not None:
        band = tracked_match.group("band")
        grade = "K" if band == "kindergarten" else band.removeprefix("grade")
        expected_code = (
            f"IM-G{grade}-U{int(tracked_match.group('unit'))}-"
            f"L{int(tracked_match.group('lesson'))}"
        )
        if question.code != expected_code:
            raise ValueError("guide-question lesson identity does not match its source")
    else:
        match = re.fullmatch(
            r"hermes/app/runtime/experiments/gemma4_tutor/docling/full-output/"
            r"TeacherLessonGuides/(?P<band>Kindergarten|Grade[1-8])/"
            r"(?P=band)-(?P<unit>\d+)-(?P<lesson>\d+)-"
            r"Lesson-teacher-guide-/document\.md",
            question.source,
        )
        if match is None:
            raise ValueError("guide-question source is outside the declared guide corpora")
        band = match.group("band")
        grade = "K" if band == "Kindergarten" else band.removeprefix("Grade")
        expected_code = (
            f"IM-G{grade}-U{int(match.group('unit'))}-L{int(match.group('lesson'))}"
        )
        if question.code != expected_code:
            raise ValueError("guide-question lesson identity does not match its source")
    if (
        question.mechanical_warrant != "printed_region"
        and question.purpose not in {"assessing", "advancing"}
    ):
        raise ValueError(f"unsupported guide-question purpose: {question.purpose}")
    if question.label_origin not in {
        "author_heading",
        "human_classification",
        "machine_classification",
    }:
        raise ValueError(
            f"unsupported guide-question label origin: {question.label_origin}"
        )
    if question.review_status not in {
        "approved",
        "pending_human_review",
        "culled_by_reviewer",
        "mechanically_admitted",
        "mechanically_held",
    }:
        raise ValueError(
            f"unsupported guide-question review status: {question.review_status}"
        )

    if question.review_status == "mechanically_admitted":
        if question.mechanical_builder is None or question.mechanical_date is None:
            raise ValueError("mechanical admission requires extraction and date evidence")
        if question.held_reason is not None or question.reviewer is not None:
            raise ValueError("mechanically admitted rows cannot carry held or review evidence")
        if question.mechanical_warrant == "im_author_heading":
            if question.label_origin != "author_heading" or question.author_heading is None:
                raise ValueError("author-heading admission requires its heading origin")
            if question.region_identity is not None or question.region_identity_kind is not None:
                raise ValueError("author-heading admission cannot carry a region label")
        elif question.mechanical_warrant == "printed_region":
            if question.label_origin != "machine_classification":
                raise ValueError("printed-region admission requires machine_classification origin")
            if question.region_identity is None:
                raise ValueError("printed-region admission requires a region identity")
            if question.region_identity_kind not in {"atom", "string"}:
                raise ValueError("printed-region admission requires a region term kind")
            if question.author_heading is not None:
                raise ValueError("printed-region admission cannot claim an author label")
        else:
            raise ValueError("mechanical admission requires a recognized warrant")
    elif question.review_status == "mechanically_held":
        if question.held_reason is None:
            raise ValueError("mechanically held rows require a named reason")
        if any(
            value is not None
            for value in (
                question.mechanical_builder,
                question.mechanical_date,
                question.mechanical_warrant,
                question.region_identity,
                question.region_identity_kind,
                question.reviewer,
            )
        ):
            raise ValueError("mechanically held rows cannot carry admission or review evidence")
    elif any(
        value is not None
        for value in (
            question.mechanical_builder,
            question.mechanical_date,
            question.mechanical_warrant,
            question.region_identity,
            question.region_identity_kind,
            question.held_reason,
        )
    ):
        raise ValueError("human/pending rows cannot carry mechanical evidence")

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
    tracked_mechanical = (
        tracked_match is not None
        and question.review_status in {"mechanically_admitted", "mechanically_held"}
    )
    if not tracked_mechanical and not cited_span_contains(question.text, cited_lines):
        raise ValueError(
            f"guide-question text is absent from its cited span: "
            f"{question.source}:{question.line_start}-{question.line_end}"
        )

    if question.label_origin == "author_heading":
        if question.author_heading is None:
            raise ValueError("author_heading origin requires an exact heading")
        if question.review_status in {"approved", "culled_by_reviewer"}:
            if question.author_heading_line is None:
                raise ValueError("human author_heading origin requires its source line")
            if not (1 <= question.author_heading_line <= len(source_lines)):
                raise ValueError("author heading line is outside the guide source")
            heading_line = source_lines[question.author_heading_line - 1]
            if question.author_heading not in heading_line:
                raise ValueError(
                    f"claimed author heading is absent at {question.source}:"
                    f"{question.author_heading_line}"
                )
        if question.review_status == "culled_by_reviewer":
            # Culling is a review act on serving suitability, not a claim
            # about label provenance; it is the one author-heading state
            # that carries reviewer evidence.
            if not question.reviewer:
                raise ValueError("a culled record requires reviewer evidence")
        elif question.reviewer is not None:
            raise ValueError("author-heading records do not carry a human reviewer")
    else:
        if question.author_heading is not None or question.author_heading_line is not None:
            raise ValueError("classified question cannot claim an author heading")
        if question.review_status == "approved" and not question.reviewer:
            raise ValueError("approved classification requires reviewer evidence")
        if question.review_status == "pending_human_review" and question.reviewer is not None:
            raise ValueError("pending classification cannot name a reviewer")


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
    if question.review_status == "mechanically_admitted":
        assert question.mechanical_builder is not None
        assert question.mechanical_date is not None
        if question.mechanical_warrant == "im_author_heading":
            assert question.author_heading is not None
            warrant_term = (
                f"im_author_heading({prolog_string(question.author_heading)})"
            )
        elif question.mechanical_warrant == "printed_region":
            warrant_term = f"printed_region({region_identity_term(question)})"
        else:
            raise ValueError("mechanical admission has no supported warrant")
        return (
            "mechanical_admission("
            f"{warrant_term}, "
            f"extraction({prolog_atom(question.mechanical_builder)}), "
            f"date({prolog_atom(question.mechanical_date)}))"
        )
    if question.review_status == "mechanically_held":
        assert question.held_reason is not None
        return f"held({question.held_reason})"
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


def region_identity_term(question: GuideQuestion) -> str:
    assert question.region_identity is not None
    if question.region_identity_kind == "atom":
        return prolog_atom(question.region_identity)
    if question.region_identity_kind == "string":
        return prolog_string(question.region_identity)
    raise ValueError("region identity is missing its Prolog term kind")


def guide_question_term(question: GuideQuestion) -> str:
    purpose_term = (
        f"region({region_identity_term(question)})"
        if question.mechanical_warrant == "printed_region"
        else question.purpose
    )
    return (
        "guide_question("
        f"{purpose_term}, {prolog_string(question.text)}, "
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
    question_absences: tuple[GuideQuestionAbsence, ...],
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
        "            compiled_lesson_guide_question_absent/3,",
        "            compiled_lesson_context_summary/3,",
        "            compiled_lesson_context_defeat/2,",
        "            compiled_lesson_context_absent/3",
        "          ]).",
        "",
        ":- dynamic compiled_lesson_context_absent/3.",
        ":- dynamic compiled_lesson_guide_question/2.",
        ":- dynamic compiled_lesson_guide_question_absent/3.",
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
    for absence in question_absences:
        lines.extend(
            [
                "compiled_lesson_guide_question_absent(",
                f"    {prolog_atom(absence.code)},",
                f"    {absence.purpose},",
                f"    absence(source_guide({prolog_atom(absence.source)}), "
                f"reason({prolog_atom(absence.reason)}))).",
                "",
            ]
        )
    return "\n".join(lines).rstrip() + "\n"


def compile_cache() -> tuple[
    str,
    list[LessonContext],
    list[LessonAbsence],
    tuple[GuideQuestionAbsence, ...],
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
    question_guides = [
        path
        for grade in (
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
        for path in sorted((MIDDLE_GUIDES / grade).glob("*/document.md"))
    ]
    extracted_questions: list[GuideQuestion] = []
    question_absences: list[GuideQuestionAbsence] = []
    for guide in question_guides:
        guide_questions, guide_absences = extract_docling_guide_questions(
            guide, label_origin="machine_classification"
        )
        extracted_questions.extend(guide_questions)
        question_absences.extend(guide_absences)
    labels_admission_rows, guide_admission_rows = admission_store_rows()
    labels_questions = tuple(
        _label_store_question(row) for row in labels_admission_rows
    )
    joined_guide_questions = join_mechanical_admission(
        extracted_questions, guide_admission_rows
    )
    questions = (
        *validated_guide_questions(),
        *labels_questions,
        *joined_guide_questions,
    )
    for question in (*labels_questions, *joined_guide_questions):
        validate_guide_question(question)
    source_count = len(guides) + len(middle_guides)
    return (
        render(
            contexts,
            questions,
            tuple(question_absences),
            absences,
            failures,
            source_count,
        ),
        contexts,
        absences,
        tuple(question_absences),
        failures,
        source_count,
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="fail if the cache is stale")
    parser.add_argument("--output", type=Path, default=OUTPUT)
    args = parser.parse_args()
    rendered, contexts, absences, question_absences, failures, source_count = compile_cache()
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
        "sequence_lessons={sequences} absent_lessons={absences} "
        "question_absences={question_absences}".format(
            guides=source_count,
            prompts=sum(bool(context.prompts) for context in contexts),
            sequences=sum(bool(context.sequences) for context in contexts),
            absences=len(absences),
            question_absences=len(question_absences),
        )
    )
    for pattern, count in sorted(failures.items()):
        print(f"defeated {pattern}={count}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
