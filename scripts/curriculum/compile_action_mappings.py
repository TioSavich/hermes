#!/usr/bin/env python3
"""Compile source-cited lesson mappings without promoting guesses to facts.

High-confidence phrase rules and reviewed scope batches become executable lesson
attachments. Similarity suggestions and atom gaps are emitted only to a review
report. The generated Prolog is deterministic and supports ``--check``.
"""

from __future__ import annotations

import argparse
from fractions import Fraction
import json
import math
import pathlib
import re
import subprocess
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass
from functools import lru_cache

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import equation_verification  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from scripts.research.extract_lesson_context import (  # noqa: E402
    MIDDLE_CUTOFF_RE,
    MIDDLE_GUIDE_RE,
    MIDDLE_TASK_RE,
    picture_description_lines,
)

# Every corpus this compiler reads and every artifact it writes is named once,
# here. The generated files already carried these Hermes paths as their recorded
# provenance while the compiler still addressed the pre-vendoring checkout, so a
# path stated in two vocabularies was the whole of what kept this script from
# running. Rerouting a corpus means editing one line below, and the byte
# comparison in ``--check`` is what says the reroute was faithful.
GUIDE_ROOT = ROOT / "curriculum/im_teacher_guides"
MIDDLE_GUIDE_ROOT = (
    ROOT
    / "hermes/app/runtime/experiments/gemma4_tutor/docling/full-output"
    / "TeacherLessonGuides"
)
SCOPE_ROOT = ROOT / "curriculum/scope_and_sequence"
LESSON_FACT_ROOT = ROOT / "curriculum/im"
GENERATED_ROOT = LESSON_FACT_ROOT / "generated"

# These names travel in Python objects and JSON review output. Generated Prolog
# keeps the source path as its runtime discriminator; it does not emit a
# source_corpus atom. A Docling path is line-addressable evidence only after the
# citation validator below confirms that the cited line contains its excerpt.
# Docling text enters the reader only after picture_description_lines() removes
# the separately generated Granite Vision captions and image references.
HAND_TEMPLATED_GUIDE_CORPUS = "im_teacher_guides_hand_templated"
DOCLING_GUIDE_CORPUS = "docling_2_114_0_teacher_lesson_guides"
RECOVERED_SPAN_CORPUS = "recovered_task_span_sidecar"
SCOPE_SEQUENCE_CORPUS = "im_scope_and_sequence"
VISION_HARVEST_CORPUS = "vision_harvest_pdf"

DEFAULT_RULES = ROOT / "scripts/curriculum/action_mapping_rules.json"
DEFAULT_OUTPUT = GENERATED_ROOT / "compiled_action_mappings.pl"
DEFAULT_TASK_OUTPUT = GENERATED_ROOT / "compiled_task_instances.pl"
RECOVERED_TASK_SPANS = GENERATED_ROOT / "recovered_task_spans.json"
TASK_READINGS = ROOT / "scripts" / "curriculum" / "lesson_task_readings.json"
EQUATION_VERIFICATIONS = (
    ROOT / "scripts" / "curriculum" / "lesson_equation_verifications.json"
)


def _source_corpus(source: str) -> str:
    """Name a source's conversion history without discarding its path."""
    docling_prefix = MIDDLE_GUIDE_ROOT.relative_to(ROOT).as_posix() + "/"
    hand_prefix = GUIDE_ROOT.relative_to(ROOT).as_posix() + "/"
    if source.startswith(docling_prefix):
        return DOCLING_GUIDE_CORPUS
    if source.startswith(hand_prefix):
        return HAND_TEMPLATED_GUIDE_CORPUS
    if source == RECOVERED_TASK_SPANS.relative_to(ROOT).as_posix():
        return RECOVERED_SPAN_CORPUS
    if source.startswith(SCOPE_ROOT.relative_to(ROOT).as_posix() + "/"):
        return SCOPE_SEQUENCE_CORPUS
    if source.lower().endswith(".pdf"):
        return VISION_HARVEST_CORPUS
    return "repo_source"


CODE_RE = re.compile(r"IM-G([K0-8])-U(\d+)-L(\d+)")
EXPLICIT_RE = re.compile(
    r"explicit_lesson_strategy\(\s*'([^']+)'\s*,\s*([a-z_]+)\s*,\s*([a-z_]+)\s*,",
    re.MULTILINE,
)
# Vision-attested demands (generated grade_*_vision.pl) count toward coverage
# exactly like explicit facts, but live in a distinct predicate so the
# monitoring-chart join never sees them (cluster charts keep their citations).
VISION_RE = re.compile(
    r"vision_lesson_strategy\(\s*'([^']+)'\s*,\s*([a-z_]+)\s*,\s*([a-z_]+)\s*,",
    re.MULTILINE,
)
TOKEN_RE = re.compile(r"[a-z0-9]+")
TASK_TERM_RE = re.compile(
    r"^(?P<operator>add|subtract|multiply|divide)\(\s*(?P<left>-?\d+)\s*,\s*"
    r"(?P<right>-?\d+)\s*\)$"
)
# Keep the lane's content scope on the same comma-aware whole-number spelling
# accepted by the candidate extractor.  The lookahead deliberately retains
# overlapping pairs: ``6 + 4 + 4`` contains both ``6 + 4`` and ``4 + 4``.
# These parsers operate over whole-number tasks.  A digit beside a solidus is
# a fraction component, not a standalone operand (for example, neither ``10``
# nor ``50`` in ``1/10 + 50/100`` may produce ``add(10, 50)``).
ARITHMETIC_NUMERAL = r"(?<!\d/)(?:\d{1,3}(?:,\d{3})+|\d+)(?!/\d)"
ARITHMETIC_EXPRESSION_RE = re.compile(
    rf"(?=(?<![\d.,])(?P<left>{ARITHMETIC_NUMERAL})\s*"
    rf"(?P<symbol>[+\-−×·÷/=])\s*(?P<right>{ARITHMETIC_NUMERAL})(?![\d,]|\.\d))"
)
RECOVERED_COMPLETE_EQUATION_RE = re.compile(
    r"(?<![\d,./])\d+\s*[-−+×·÷]\s*\d+\s*=\s*\d+(?![\d,./])"
)
# Fraction task lane.  An operand is a printed fraction, a space-separated
# mixed number, or a whole number beside a fraction.  The left lookbehinds
# refuse a start inside a numeral and refuse slicing the fraction part out
# of a spaced mixed number ("1 5/8" never yields a "5/8" operand).  Chains
# keep the whole-number lane's documented overlapping-pair semantics.
FRACTION_EXPRESSION_RE = re.compile(
    r"(?=(?<![\d.,/])(?<!\d )(?P<left>(?:\d+ )?\d+/\d+|\d+)\s*"
    r"(?P<symbol>[+\-−])\s*"
    r"(?P<right>(?:\d+ )?\d+/\d+|\d+)(?![\d,/]|\.\d))"
)
_FRACTION_OPERAND_RE = re.compile(
    r"(?:(?P<whole>\d+) )?(?P<num>\d+)/(?P<den>\d+)$|(?P<bare>\d+)$"
)


def _flattened_mixed_readings(numerator: str, denominator: int) -> list[tuple[int, int]]:
    """Whole/numerator splits a docling-flattened mixed number could carry.

    The guides print mixed numbers with a space ("12 1/2"); the markdown
    extraction drops it, so "121/2" arrives carrying two readings: the
    fraction 121/2 and the mixed number 12 1/2.  A split whose part would
    carry a leading zero or reach the denominator is not a printed mixed
    form and does not count as a reading.
    """
    readings = []
    for cut in range(1, len(numerator)):
        whole, part = numerator[:cut], numerator[cut:]
        if whole.startswith("0") or part.startswith("0"):
            continue
        if int(whole) >= 1 and 1 <= int(part) < denominator:
            readings.append((int(whole), int(part)))
    return readings


def _fraction_operand_term(token: str) -> tuple[str, Fraction] | None:
    """Read one printed addend, refusing every ambiguous flattened form."""
    match = _FRACTION_OPERAND_RE.fullmatch(token.strip())
    if match is None:
        return None
    if match.group("bare") is not None:
        value = int(match.group("bare"))
        return f"whole({value})", Fraction(value)
    num_str = match.group("num")
    den_str = match.group("den")
    if den_str.startswith("0") or (num_str.startswith("0") and num_str != "0"):
        return None
    denominator = int(den_str)
    numerator = int(num_str)
    if match.group("whole") is not None:
        whole_str = match.group("whole")
        if whole_str.startswith("0"):
            return None
        whole = int(whole_str)
        if whole < 1 or numerator < 1 or numerator >= denominator:
            return None
        return (
            f"mixed({whole}, {numerator}, {denominator})",
            Fraction(whole) + Fraction(numerator, denominator),
        )
    if _flattened_mixed_readings(num_str, denominator):
        return None
    return f"frac({numerator}, {denominator})", Fraction(numerator, denominator)


@dataclass(frozen=True)
class LessonDoc:
    code: str
    path: pathlib.Path
    title: str
    goals: tuple[str, ...]
    purpose: str
    line_by_text: dict[str, int]
    source_corpus: str = HAND_TEMPLATED_GUIDE_CORPUS

    @property
    def concise_text(self) -> str:
        return " ".join((self.title, *self.goals, self.purpose)).strip()


@dataclass(frozen=True, order=True)
class Mapping:
    code: str
    operation: str
    kind: str
    input_domain: str
    rule_id: str
    source: str
    line: int
    excerpt: str
    # Legacy rows retain their exact rendered evidence. Task-span rows carry
    # the field discriminator and the extractor's student-facing position.
    matched_field: str = ""
    span_position: str = ""
    end_line: int = 0

    @property
    def source_corpus(self) -> str:
        return _source_corpus(self.source)


@dataclass(frozen=True, order=True)
class TaskInstance:
    code: str
    task: str
    role: str
    rule_id: str
    source: str
    line: int
    end_line: int
    position: str
    excerpt: str
    # Provenance discriminator. Empty string keeps the teacher-guide markdown
    # form source('path.md', lines(L, E)). A non-empty page span selects the
    # E343 PDF form source(e343_pdf('path.pdf', pages("P"))): the operative
    # quantities live in figures the markdown extract dropped, so the compiler
    # records the page reference verbatim but cannot line-check it. Verifying the
    # excerpt against the cited PDF pages is a human step, not a compiler gate.
    pages: str = ""
    # Authored task readings carry whether a printed answer independently
    # witnesses the task. Legacy and parser-derived instances keep this empty.
    witness_class: str = ""

    @property
    def source_corpus(self) -> str:
        return _source_corpus(self.source)


@dataclass(frozen=True)
class StudentTaskSpan:
    code: str
    source: str
    heading_line: int
    end_line: int
    position: str
    lines: tuple[tuple[int, str], ...]
    source_corpus: str = HAND_TEMPLATED_GUIDE_CORPUS

    @property
    def text(self) -> str:
        return " ".join(text for _, text in self.lines).strip()

    @property
    def recovered(self) -> bool:
        return self.source == str(RECOVERED_TASK_SPANS.relative_to(ROOT))


@dataclass(frozen=True, order=True)
class TaskCandidate:
    code: str
    task: str
    operation: str
    parser_id: str
    source: str
    line: int
    end_line: int
    position: str
    excerpt: str
    status: str
    reason: str

    @property
    def source_corpus(self) -> str:
        return _source_corpus(self.source)


def _grade_token(directory: str) -> str:
    token = directory.removeprefix("grade")
    return "K" if token == "k" or token == "kindergarten" else token


def _code_for_guide(path: pathlib.Path) -> str:
    grade = _grade_token(path.parents[1].name)
    unit = int(path.parent.name.removeprefix("unit"))
    lesson = int(path.stem.removeprefix("lesson"))
    return f"IM-G{grade}-U{unit}-L{lesson}"


def _code_for_middle_guide(path: pathlib.Path) -> str:
    """Return the canonical identity using the shared Docling path grammar."""
    match = MIDDLE_GUIDE_RE.fullmatch(path.parent.name)
    if match is None:
        raise SystemExit(f"unrecognized Docling teacher-guide path: {path}")
    band = match.group("band")
    grade = "K" if band == "Kindergarten" else band.removeprefix("Grade")
    unit = match.group("unit")
    lesson = match.group("lesson")
    return f"IM-G{grade}-U{int(unit)}-L{int(lesson)}"


def _section(
    lines: list[str],
    headings: str | tuple[str, ...],
    *,
    excluded_lines: set[int] | None = None,
) -> list[tuple[int, str]]:
    """Read one declared heading vocabulary and retain physical line numbers."""
    accepted = (headings,) if isinstance(headings, str) else headings
    start = next(
        (i for i, line in enumerate(lines) if line.strip() in accepted),
        None,
    )
    if start is None:
        return []
    excluded = excluded_lines or set()
    out = []
    for index in range(start + 1, len(lines)):
        line = lines[index].strip()
        if line.startswith("## "):
            break
        if line and index not in excluded:
            out.append((index + 1, line.removeprefix("- ").strip()))
    return out


def _read_hand_templated_teacher_guides(root: pathlib.Path) -> list[LessonDoc]:
    docs = []
    guide_root = root / GUIDE_ROOT.relative_to(ROOT)
    for path in sorted(guide_root.glob("*/unit*/lesson*.md")):
        grade_dir = path.parents[1].name
        if not (grade_dir.startswith("grade") or grade_dir == "kindergarten"):
            continue
        # These sparse grade-6 extracts belong to a different conversion and
        # naming scheme. Grade 6-8 enters through the spine-exact Docling reader
        # below, where every span carries its own corpus discriminator.
        if grade_dir == "grade6":
            continue
        # Reader-lane files sharing the glob (lesson9_student_task_statements.md,
        # extract_*.md spanning several lessons) carry no single canonical lesson
        # code and would crash _code_for_guide; the LessonDoc path takes only
        # canonical lessonN.md stems.
        if not re.fullmatch(r"lesson\d+", path.stem):
            continue
        lines = path.read_text(encoding="utf-8", errors="replace").split("\n")
        title = lines[0].removeprefix("# ").strip() if lines else ""
        goals_with_lines = _section(lines, "## Learning Goals (teacher-facing)")
        purpose_with_lines = _section(lines, "## Lesson Purpose")
        if not goals_with_lines and not purpose_with_lines:
            raise SystemExit(
                f"teacher guide has no recognized hand-templated headings: {path}"
            )
        purpose = " ".join(text for _, text in purpose_with_lines)
        line_by_text = {text: line for line, text in goals_with_lines + purpose_with_lines}
        line_by_text[title] = 1
        docs.append(
            LessonDoc(
                _code_for_guide(path),
                path,
                title,
                tuple(text for _, text in goals_with_lines),
                purpose,
                line_by_text,
                HAND_TEMPLATED_GUIDE_CORPUS,
            )
        )
    return docs


def _read_docling_teacher_guides(root: pathlib.Path) -> list[LessonDoc]:
    """Read spine-exact grade 6-8 guides without admitting model captions."""
    docs = []
    guide_root = root / MIDDLE_GUIDE_ROOT.relative_to(ROOT)
    for grade in ("Grade6", "Grade7", "Grade8"):
        for path in sorted((guide_root / grade).glob("*/document.md")):
            code = _code_for_middle_guide(path)
            lines = path.read_text(
                encoding="utf-8", errors="replace"
            ).splitlines()
            excluded = picture_description_lines(path, lines)
            if excluded is None:
                raise SystemExit(
                    f"Docling guide picture annotations cannot be separated: {path}"
                )
            headings = {
                line.strip()
                for line in lines
                if line.strip().startswith("## ")
            }
            required = {"## Goals", "## Lesson Narrative"}
            missing = sorted(required - headings)
            if missing:
                raise SystemExit(
                    "Docling teacher guide has unrecognized or incomplete headings "
                    f"({', '.join(missing)}): {path}"
                )
            goals_with_lines = _section(
                lines, "## Goals", excluded_lines=excluded
            ) + _section(
                lines, "## Learning Targets", excluded_lines=excluded
            )
            narrative_with_lines = _section(
                lines,
                "## Lesson Narrative",
                excluded_lines=excluded,
            )
            if not goals_with_lines or not narrative_with_lines:
                raise SystemExit(
                    f"Docling teacher guide recognized headings but no curriculum text: {path}"
                )
            goals_heading = next(
                index for index, line in enumerate(lines) if line.strip() == "## Goals"
            )
            title_with_line = next(
                (
                    (index + 1, line.removeprefix("## ").strip())
                    for index, line in enumerate(lines[:goals_heading])
                    if line.startswith("## ") and index not in excluded
                ),
                None,
            )
            if title_with_line is None:
                raise SystemExit(f"Docling teacher guide has no lesson title: {path}")
            title_line, title = title_with_line
            purpose = " ".join(text for _, text in narrative_with_lines)
            line_by_text = {
                text: line
                for line, text in goals_with_lines + narrative_with_lines
            }
            line_by_text[title] = title_line
            docs.append(
                LessonDoc(
                    code,
                    path,
                    title,
                    tuple(text for _, text in goals_with_lines),
                    purpose,
                    line_by_text,
                    DOCLING_GUIDE_CORPUS,
                )
            )
    return docs


def read_teacher_guides(root: pathlib.Path = ROOT) -> list[LessonDoc]:
    """Read both declared guide corpora while refusing identity collisions."""
    # A read establishes one source snapshot. Segmentation is memoized only
    # inside that snapshot so a later build cannot reuse stale file contents.
    _DOCLING_TASK_REGION_CACHE.clear()
    docs = (
        _read_hand_templated_teacher_guides(root)
        + _read_docling_teacher_guides(root)
    )
    codes = [doc.code for doc in docs]
    duplicates = sorted(code for code, count in Counter(codes).items() if count > 1)
    if duplicates:
        raise SystemExit(
            f"teacher-guide corpora carry duplicate lesson identities: {duplicates}"
        )
    return sorted(docs, key=lambda doc: doc.code)


def _student_column(line: str, right_column: int | None) -> str:
    clean = line.replace("\f", " ", 1)
    if right_column is not None and len(clean) > right_column:
        clean = clean[:right_column]
    return clean.strip()


TASK_SPAN_STOP_HEADINGS = (
    "Lesson Synthesis",
    "Cool-down",
    "Required Materials",
    "Materials to Gather",
    "Materials to Copy",
    "Required Preparation",
    "Suggested Centers",
    "Observation",
)
TASK_SPAN_STOP_HEADING = re.compile(
    r"^(?:"
    + "|".join(re.escape(heading) for heading in TASK_SPAN_STOP_HEADINGS)
    + r")(?:\s*$|[.:\s])"
)
# The right-column heading sometimes begins a few characters left of the
# "Launch" header. Keep a gutter so such a heading never truncates a student
# prompt that continues down the left column.
TASK_SPAN_RIGHT_COLUMN_GUTTER = 10

# Docling flattens running headers, page numbers, and activity metadata into the
# same linear markdown stream as student prompts. None of these strings is task
# text. In particular, a bare page numeral must not become an operand when
# _task_chunks later joins the retained lines.
DOCLING_TASK_FURNITURE_RE = re.compile(
    r"^(?:"
    r"\d+|"
    r"\d+\s+min|"
    r"Instructional Routines|"
    r"Grade\s+[678](?:\s+Unit\s+\d+)?|"
    r"Unit\s+\d+|"
    r"Lesson\s+\d+|"
    r"Math, CC BY Open Up Resources\."
    r")$",
    re.IGNORECASE,
)


def _docling_task_furniture(text: str) -> bool:
    return bool(DOCLING_TASK_FURNITURE_RE.fullmatch(text.strip()))


def _student_task_span_stop(
    raw_line: str, student_text: str, right_column: int | None
) -> bool:
    """Whether a teacher-facing heading ends the left-column prompt."""
    if not TASK_SPAN_STOP_HEADING.match(student_text):
        return False
    indent = len(raw_line) - len(raw_line.lstrip("\f "))
    return (
        right_column is None
        or indent <= right_column - TASK_SPAN_RIGHT_COLUMN_GUTTER
    )


def _extract_hand_templated_student_task_spans(
    docs: list[LessonDoc],
) -> list[StudentTaskSpan]:
    """Recover K-5 left-column prompts without changing the legacy reading."""
    spans = []
    footer = re.compile(
        r"^(?:Grade [K0-8]|Unit \d+|Lesson \d+|CC BY NC \d{4}|Illustrative Mathematics)",
        re.IGNORECASE,
    )
    for doc in docs:
        if doc.source_corpus != HAND_TEMPLATED_GUIDE_CORPUS:
            continue
        raw_lines = doc.path.read_text(encoding="utf-8", errors="replace").split("\n")
        span_number = 0
        for index, raw_heading in enumerate(raw_lines):
            heading = raw_heading.lstrip("\f ")
            if not heading.startswith("Student Task Statement"):
                continue
            span_number += 1
            launch_column = raw_heading.find("Launch")
            right_column = max(launch_column - 2, 0) if launch_column >= 0 else None
            lines = []
            end_line = index + 1
            for next_index in range(index + 1, min(len(raw_lines), index + 121)):
                raw_line = raw_lines[next_index]
                stripped = raw_line.lstrip("\f ")
                if stripped.startswith("Student Response") or stripped.startswith(
                    "Student Task Statement"
                ):
                    end_line = next_index
                    break
                text = _student_column(raw_line, right_column)
                if _student_task_span_stop(raw_line, text, right_column):
                    end_line = next_index
                    break
                if text and not footer.match(text):
                    lines.append((next_index + 1, text))
                end_line = next_index + 1
            spans.append(
                StudentTaskSpan(
                    doc.code,
                    str(doc.path.relative_to(ROOT)),
                    index + 1,
                    end_line,
                    f"student_task_statement({span_number})",
                    tuple(lines),
                    HAND_TEMPLATED_GUIDE_CORPUS,
                )
            )
    return spans


_DOCLING_TASK_REGION_CACHE: dict[
    tuple[pathlib.Path, str],
    tuple[tuple[StudentTaskSpan, ...], str | None, int],
] = {}


def _segment_docling_task_regions(
    doc: LessonDoc,
) -> tuple[tuple[StudentTaskSpan, ...], str | None, int]:
    """Segment one Docling guide once, excluding annotations and furniture."""
    lines = doc.path.read_text(encoding="utf-8", errors="replace").splitlines()
    excluded = picture_description_lines(doc.path, lines)
    if excluded is None:
        raise SystemExit(
            f"Docling guide picture annotations cannot be separated: {doc.path}"
        )
    body_start = next(
        (index for index, line in enumerate(lines) if line == "## Activity Narrative"),
        None,
    )
    if body_start is None:
        return (), "missing_activity_narrative", 0
    body_end = next(
        (
            index
            for index, line in enumerate(lines[body_start:], body_start)
            if MIDDLE_CUTOFF_RE.fullmatch(line)
        ),
        len(lines),
    )
    spans = []
    markers = 0
    for index in range(body_start, body_end):
        if not MIDDLE_TASK_RE.fullmatch(lines[index]):
            continue
        markers += 1
        section_end = index + 1
        while section_end < body_end and not lines[section_end].startswith("## "):
            # In the flattened bullet-heading genre this marks a sibling
            # metadata block, not part of the student task. Bounding here also
            # removes its routine name instead of filtering only the banner.
            if (
                section_end not in excluded
                and lines[section_end].strip() == "- Instructional Routines"
            ):
                break
            section_end += 1
        span_lines = []
        for line_index in range(index + 1, section_end):
            if line_index in excluded:
                continue
            text = lines[line_index].strip().removeprefix("- ").strip()
            if text and not _docling_task_furniture(text):
                span_lines.append((line_index + 1, text))
        if not span_lines:
            continue
        spans.append(
            StudentTaskSpan(
                doc.code,
                str(doc.path.relative_to(ROOT)),
                index + 1,
                section_end,
                f"student_task_statement({markers})",
                tuple(span_lines),
                DOCLING_GUIDE_CORPUS,
            )
        )
    if spans:
        return tuple(spans), None, markers
    if markers:
        return (), "task_statements_contain_no_curriculum_text", markers
    return (), "no_student_task_statement_heading", 0


def _docling_task_region_result(
    doc: LessonDoc,
) -> tuple[tuple[StudentTaskSpan, ...], str | None, int]:
    key = (doc.path, doc.code)
    result = _DOCLING_TASK_REGION_CACHE.get(key)
    if result is None:
        result = _segment_docling_task_regions(doc)
        _DOCLING_TASK_REGION_CACHE[key] = result
    return result


def _docling_task_regions(
    doc: LessonDoc,
) -> tuple[list[StudentTaskSpan], str | None]:
    """Return a copy of the cached span list and its guide-level refusal."""
    spans, reason, _markers = _docling_task_region_result(doc)
    return list(spans), reason


def extract_student_task_spans(docs: list[LessonDoc]) -> list[StudentTaskSpan]:
    """Read task spans from both genres while retaining corpus provenance."""
    spans = _extract_hand_templated_student_task_spans(docs)
    for doc in docs:
        if doc.source_corpus != DOCLING_GUIDE_CORPUS:
            continue
        doc_spans, _reason = _docling_task_regions(doc)
        spans.extend(doc_spans)
    return sorted(spans, key=lambda span: (span.code, span.heading_line))


def docling_zero_span_reasons(
    docs: list[LessonDoc],
) -> dict[str, str]:
    """Return one explicit refusal reason for each readable guide with no span."""
    reasons = {}
    for doc in docs:
        if doc.source_corpus != DOCLING_GUIDE_CORPUS:
            continue
        spans, reason = _docling_task_regions(doc)
        if not spans:
            reasons[doc.code] = reason or "unknown"
    return reasons


def docling_task_section_metrics(
    docs: list[LessonDoc],
) -> dict[str, int]:
    """Count recognized sections, including caption-only sections withheld."""
    marker_count = 0
    span_count = 0
    for doc in docs:
        if doc.source_corpus != DOCLING_GUIDE_CORPUS:
            continue
        cached_spans, _reason, markers = _docling_task_region_result(doc)
        spans = list(cached_spans)
        marker_count += markers
        span_count += len(spans)
    return {
        "recognized_task_sections": marker_count,
        "docling_task_heading_spans_by_origin": span_count,
        "withheld_empty_or_model_only_sections": marker_count - span_count,
    }


def read_recovered_task_spans(
    root: pathlib.Path, tracked_spans: list[StudentTaskSpan]
) -> list[StudentTaskSpan]:
    """Read sidecar-only task text after checking its tracked-span join.

    The sidecar records expressions that the line-addressable markdown omits.
    Its ``tracked_text`` is retained as a join guard: a recovered row is usable
    only when it names one existing student-task span and repeats that span's
    words.  The returned pseudo-spans deliberately carry the sidecar path and
    line zero, so no downstream instance can cite a blank markdown line.
    """
    path = root / RECOVERED_TASK_SPANS.relative_to(ROOT)
    payload = json.loads(path.read_text(encoding="utf-8"))
    if payload.get("schema") != "recovered_task_spans_v1":
        raise SystemExit(
            f"unexpected recovered task span schema in {path.relative_to(root)}: "
            f"{payload.get('schema')!r}"
        )
    rows = payload.get("spans")
    if not isinstance(rows, list):
        raise SystemExit(f"{path.relative_to(root)} carries no spans list")
    tracked_by_key = {(span.code, span.position): span for span in tracked_spans}
    recovered_by_key = {}
    for row in rows:
        if not isinstance(row, dict):
            raise SystemExit(f"non-object recovered task span in {path.relative_to(root)}")
        code = row.get("lesson")
        position = row.get("position")
        recovered_text = row.get("recovered_text")
        tracked_text = row.get("tracked_text")
        if not all(isinstance(value, str) for value in (code, position, recovered_text, tracked_text)):
            raise SystemExit(f"malformed recovered task span in {path.relative_to(root)}: {row!r}")
        key = (code, position)
        if key in recovered_by_key:
            raise SystemExit(f"duplicate recovered task span key: {code}/{position}")
        tracked = tracked_by_key.get(key)
        if tracked is None:
            raise SystemExit(f"recovered task span does not join a tracked span: {code}/{position}")
        if " ".join(tracked.text.split()) != " ".join(tracked_text.split()):
            raise SystemExit(f"recovered task span tracked-text drift: {code}/{position}")
        recovered_by_key[key] = StudentTaskSpan(
            code,
            str(RECOVERED_TASK_SPANS.relative_to(ROOT)),
            0,
            0,
            position,
            ((0, recovered_text),),
            RECOVERED_SPAN_CORPUS,
        )
    return [recovered_by_key[key] for key in sorted(recovered_by_key)]


def _task_reading_task(task: object, reading_id: str) -> tuple[str, int, int]:
    """Parse the deliberately small arithmetic term accepted by task readings."""
    if not isinstance(task, str):
        raise SystemExit(f"lesson task reading {reading_id} task is not a string")
    match = TASK_TERM_RE.fullmatch(task)
    if match is None:
        raise SystemExit(
            f"lesson task reading {reading_id} has unsupported task term: {task!r}"
        )
    return match.group("operator"), int(match.group("left")), int(match.group("right"))


def _task_reading_value(operator: str, left: int, right: int) -> Fraction:
    if operator == "add":
        return Fraction(left + right)
    if operator == "subtract":
        return Fraction(left - right)
    if operator == "multiply":
        return Fraction(left * right)
    if right == 0:
        raise SystemExit("lesson task reading divides by zero")
    return Fraction(left, right)


def _task_reading_operand_present(operand: int, excerpt: str) -> bool:
    """Match a whole numeral after removing only thousands separators."""
    normalized = re.sub(r"(?<=\d),(?=\d)", "", excerpt)
    return re.search(rf"(?<!\d){re.escape(str(operand))}(?!\d)", normalized) is not None


def _printed_answer_states_value(value: Fraction, excerpt: str) -> bool:
    """Whether the cited response text actually prints the value it witnesses.

    Three checks used to stand for a printed-answer witness: the excerpt is at
    the cited line, the line is in the next Student Response block, and the
    stated value equals the computed task. None of them asks whether the
    excerpt says the value, so any verbatim sentence from the right block
    licensed any correctly-computed answer. A machine proposer found this on
    its first survivor (task-201): witness value 247 against the excerpt "and
    15, so it would be more than 200", from a response block that never prints
    247. The 71 authored readings all carry their value by discipline; this
    makes it a gate.

    The matching rule is a numeral-token match after thousands separators are
    removed, so the guides' "247", "$247" and "247 marbles" all witness 247
    while "2470" and "1247" do not. A non-integer value is witnessed by its
    printed fraction, by its terminating decimal, or by a mixed number whose
    parts are adjacent in the excerpt.
    """
    normalized = re.sub(r"(?<=\d),(?=\d)", "", excerpt)
    forms: list[str] = []
    if value.denominator == 1:
        forms.append(str(value.numerator))
    else:
        forms.append(f"{value.numerator}/{value.denominator}")
        decimal = _terminating_decimal(value)
        if decimal is not None:
            forms.append(decimal)
        whole, remainder = divmod(abs(value.numerator), value.denominator)
        if whole:
            sign = "-" if value < 0 else ""
            forms.append(f"{sign}{whole} {remainder}/{value.denominator}")
    for form in forms:
        if re.search(rf"(?<![\d.]){re.escape(form)}(?![\d.]?\d)", normalized):
            return True
    return False


def _terminating_decimal(value: Fraction) -> str | None:
    """The exact decimal spelling of a fraction, when it has one."""
    denominator = value.denominator
    for factor in (2, 5):
        while denominator % factor == 0:
            denominator //= factor
    if denominator != 1:
        return None
    text = f"{float(value):.10f}".rstrip("0").rstrip(".")
    return text or "0"


# A one-space predecessor is ordinary sentence punctuation in the extracted
# column text (for example, ``650 × 27. Is ...``).  Numbered item markers are
# line-initial or follow a layout whitespace run; _item_markers applies this
# expression to each physical student-task line before translating offsets to
# StudentTaskSpan.text.
ITEM_MARKER_RE = re.compile(r"•|(?:^|(?<=\s{2}))\d+\.(?=\s)")


def _item_markers(span: StudentTaskSpan) -> list[tuple[int, int]]:
    """Return marker ranges in the same offsets used by ``span.text``."""
    markers = []
    offset = 0
    for index, (_, text) in enumerate(span.lines):
        for marker in ITEM_MARKER_RE.finditer(text):
            markers.append((offset + marker.start(), offset + marker.end()))
        offset += len(text)
        if index + 1 < len(span.lines):
            offset += 1
    return markers


def _span_bound_markdown_provenance(
    citation: dict, span: StudentTaskSpan
) -> tuple[str, int, int, str] | None:
    """Resolve a markdown citation from the column-aware task span itself.

    Raw guide lines interleave the teacher column. Once a citation is bound to
    this span, the span's extracted text and its physical line membership are
    the stronger verbatim check; the raw-line join remains for unbound legacy
    provenance.
    """
    source = citation.get("source")
    line = citation.get("line")
    end_line = citation.get("end_line", line)
    excerpt = citation.get("excerpt")
    if not (
        isinstance(source, str)
        and isinstance(line, int)
        and isinstance(end_line, int)
        and isinstance(excerpt, str)
        and source == span.source
        and span.heading_line <= line <= end_line <= span.end_line
        and excerpt in span.text
    ):
        return None
    return source, line, end_line, ""


def _operands_scope_one_item(span: StudentTaskSpan, excerpt: str) -> bool:
    """Additional marker guard: keep an operand citation inside one list item."""
    markers = _item_markers(span)
    if len(markers) < 2:
        return True
    items = []
    for index, (_, marker_end) in enumerate(markers):
        end = markers[index + 1][0] if index + 1 < len(markers) else len(span.text)
        items.append(span.text[marker_end:end])
    matches = 0
    for item in items:
        start = item.find(excerpt)
        if start < 0:
            continue
        end = start + len(excerpt)
        if (
            excerpt[:1].isdigit()
            and start > 0
            and item[start - 1].isdigit()
        ) or (
            excerpt[-1:].isdigit()
            and end < len(item)
            and item[end].isdigit()
        ):
            continue
        matches += 1
    return matches == 1


def _operand_enclosing_texts(
    span: StudentTaskSpan, excerpt: str
) -> list[tuple[str, int]]:
    """Return the item text that contains an already item-scoped citation."""
    markers = _item_markers(span)
    if len(markers) < 2:
        return [(span.text, 0)]
    items = []
    for index, (marker_start, marker_end) in enumerate(markers):
        end = markers[index + 1][0] if index + 1 < len(markers) else len(span.text)
        item = span.text[marker_end:end]
        start = item.find(excerpt)
        if start < 0:
            continue
        excerpt_end = start + len(excerpt)
        if (
            excerpt[:1].isdigit()
            and start > 0
            and item[start - 1].isdigit()
        ) or (
            excerpt[-1:].isdigit()
            and excerpt_end < len(item)
            and item[excerpt_end].isdigit()
        ):
            continue
        items.append((item, marker_end))
    return items


def _operands_content_scope_matches(
    operator: str, left: int, right: int, excerpt: str
) -> bool:
    """Require exactly the binary expression claimed by an authored task.

    Marker-less grids do not provide reliable item boundaries.  A cited operand
    excerpt therefore has to contain one, and only one, compiler-shaped
    arithmetic pair, and that pair has to be the task term itself.  ``finditer``
    sees overlapping pairs so a three-term expression cannot quietly serve as
    a binary task citation.
    """
    symbols = {
        "add": {"+"},
        "subtract": {"-", "−"},
        "multiply": {"×", "·"},
        "divide": {"÷"},
    }[operator]
    expressions = [
        (
            _arithmetic_number(match.group("left")),
            match.group("symbol"),
            _arithmetic_number(match.group("right")),
        )
        for match in ARITHMETIC_EXPRESSION_RE.finditer(excerpt)
    ]
    return (
        len(expressions) == 1
        and expressions[0][0] == left
        and expressions[0][1] in symbols
        and expressions[0][2] == right
    )


def _operands_expression_is_maximal(
    span: StudentTaskSpan, excerpt: str, line: int | None = None, end_line: int | None = None
) -> bool:
    """Refuse an operand citation that slices a longer stated expression.

    A complete binary pair may be only a prefix or a middle of a displayed
    equation.  Check both a containing compiler-shaped pair and the immediate
    mathematical continuation that the pair scanner cannot itself consume (for
    example ``104 + 2 × 10 = n``).  Ordinary prose and sentence punctuation
    remain outside those continuation tokens.
    """
    cited_matches = list(ARITHMETIC_EXPRESSION_RE.finditer(excerpt))
    if len(cited_matches) != 1:
        return False
    cited = cited_matches[0]
    cited_start = cited.start("left")
    cited_end = cited.end("right")
    extension_tokens = "+-−×xX*÷/="
    cited_starts = set()
    offset = 0
    for index, (line_number, text) in enumerate(span.lines):
        if line is not None and line <= line_number <= (end_line if end_line is not None else line):
            occurrence = text.find(excerpt)
            while occurrence >= 0:
                cited_starts.add(offset + occurrence + cited_start)
                occurrence = text.find(excerpt, occurrence + 1)
        offset += len(text)
        if index + 1 < len(span.lines):
            offset += 1
    considered = False
    for enclosing, enclosing_offset in _operand_enclosing_texts(span, excerpt):
        occurrence = enclosing.find(excerpt)
        while occurrence >= 0:
            expression_start = occurrence + cited_start
            expression_end = occurrence + cited_end
            absolute_start = enclosing_offset + expression_start
            if cited_starts and absolute_start not in cited_starts:
                occurrence = enclosing.find(excerpt, occurrence + 1)
                continue
            considered = True
            candidates = list(ARITHMETIC_EXPRESSION_RE.finditer(enclosing))
            # Adjacent binary matches share an operand in a chain such as
            # ``104 + 2 × 10``.  Their union is a strictly longer
            # compiler-shaped expression even though each pair is found by a
            # separate overlapping regex match.
            containing_start = expression_start
            containing_end = expression_end
            changed = True
            while changed:
                changed = False
                for candidate in candidates:
                    candidate_start = candidate.start("left")
                    candidate_end = candidate.end("right")
                    if candidate_start < containing_end and containing_start < candidate_end:
                        new_start = min(containing_start, candidate_start)
                        new_end = max(containing_end, candidate_end)
                        if (new_start, new_end) != (containing_start, containing_end):
                            containing_start, containing_end = new_start, new_end
                            changed = True
            if (containing_start, containing_end) != (expression_start, expression_end):
                return False
            for candidate in candidates:
                candidate_start = candidate.start("left")
                candidate_end = candidate.end("right")
                if (
                    candidate_start <= expression_start
                    and expression_end <= candidate_end
                    and (candidate_start < expression_start or expression_end < candidate_end)
                ):
                    return False
            before = enclosing[:expression_start].rstrip()
            raw_after = enclosing[expression_end:]
            after = raw_after.lstrip()
            if before and before[-1] in extension_tokens:
                return False
            # ``=`` followed by a blank answer slot completes the printed
            # binary expression.  Recovered spans flatten several rows, so a
            # later row can follow the underscores without making this pair a
            # prefix of that later row.  A printed result still begins with a
            # numeral and remains a refusal below.
            if after == "=" or re.match(r"^=\s*(?:_+(?=\s|$)|$)", after):
                occurrence = enclosing.find(excerpt, occurrence + 1)
                continue
            if after and after[0] in extension_tokens:
                return False
            # A bare following letter is a variable continuation even across
            # whitespace (``2 n``); a numeral must be lexically attached so
            # whitespace-separated grid entries remain independent.
            if (raw_after and raw_after[0].isdigit()) or (
                after
                and re.match(r"[A-Za-z_](?![A-Za-z_])", after)
                and not re.match(r"[a-z]\.\s", after)
            ):
                return False
            occurrence = enclosing.find(excerpt, occurrence + 1)
    return considered


def _next_response_range(path: pathlib.Path, heading_line: int) -> tuple[int, int] | None:
    """The first Student Response block after a task statement, in document order."""
    lines = path.read_text(encoding="utf-8", errors="replace").split("\n")
    for index in range(heading_line, len(lines)):
        heading = lines[index].lstrip("\f ")
        if heading.startswith("Student Task Statement"):
            return None
        if heading.startswith("Student Response"):
            start = index + 1
            break
    else:
        return None
    for index in range(start, len(lines)):
        heading = lines[index].lstrip("\f ")
        if heading.startswith("Student Response") or heading.startswith("Student Task Statement"):
            return start, index
    return start, len(lines)


def _task_reading_uses_e343(citation: object) -> bool:
    """Whether a lane citation names the legacy uncheckable provenance form."""
    if not isinstance(citation, dict):
        return False
    source = citation.get("source")
    return "e343_pdf" in citation or (
        isinstance(source, dict) and "e343_pdf" in source
    )


def validate_lesson_task_readings(
    root: pathlib.Path,
    docs: list[LessonDoc],
    covered: set[str],
    attachments: dict[str, set[tuple[str, str]]],
    readings_path: pathlib.Path = TASK_READINGS,
) -> list[dict]:
    """Load the authored readings and refuse every unverifiable task claim.

    The legacy reviewed-task register admits an E343 PDF provenance form for
    figure-bound grade 6--8 work. This is a separate lane: every one of its
    citations is line-addressable markdown or a checked recovered-span join.
    """
    path = readings_path if readings_path.is_absolute() else root / readings_path
    payload = json.loads(path.read_text(encoding="utf-8"))
    if payload.get("schema") != "lesson_task_readings_v1":
        raise SystemExit(f"unexpected lesson task readings schema in {path}: {payload.get('schema')!r}")
    if not isinstance(payload.get("register"), str):
        raise SystemExit(f"lesson task readings lacks a register paragraph: {path}")
    readings = payload.get("readings")
    if not isinstance(readings, list):
        raise SystemExit(f"lesson task readings lacks a readings list: {path}")

    tracked = extract_student_task_spans(docs)
    tracked_by_key = {(span.code, span.position): span for span in tracked}
    recovered_by_key = {
        (span.code, span.position): span
        for span in read_recovered_task_spans(root, tracked)
    }
    seen = set()
    validated = []
    for reading in readings:
        if not isinstance(reading, dict):
            raise SystemExit(f"non-object lesson task reading in {path}: {reading!r}")
        reading_id = reading.get("id")
        lesson = reading.get("lesson")
        position = reading.get("position")
        if not all(isinstance(value, str) and value for value in (reading_id, lesson, position)):
            raise SystemExit(f"malformed lesson task reading identity: {reading!r}")
        operator, left, right = _task_reading_task(reading.get("task"), reading_id)
        expected_operation = {
            "add": "addition",
            "subtract": "subtraction",
            "multiply": "multiplication",
            "divide": "division",
        }[operator]
        if reading.get("operation") != expected_operation:
            raise SystemExit(
                f"lesson task reading {reading_id} operation disagrees with task: "
                f"{reading.get('operation')!r} != {expected_operation!r}"
            )
        key = (lesson, position, reading["task"])
        if key in seen:
            raise SystemExit(
                f"duplicate lesson task reading for {lesson}/{position}/{reading['task']}"
            )
        seen.add(key)

        span_position = position.split("/", 1)[0]
        span = tracked_by_key.get((lesson, span_position))
        if span is None:
            raise SystemExit(
                f"lesson task reading {reading_id} names no student task span: "
                f"{lesson}/{span_position}"
            )

        for field in ("prompt", "operands", "printed_answer"):
            if _task_reading_uses_e343(reading.get(field)):
                raise SystemExit(
                    f"lesson task reading {reading_id} e343_pdf provenance form is banned: {field}"
                )

        if "printed_answer" not in reading:
            raise SystemExit(
                f"lesson task reading {reading_id} printed-answer witness missing"
            )
        answer = reading["printed_answer"]
        absent_witness = isinstance(answer, dict) and answer.get("absent") is True
        if absent_witness:
            if not isinstance(answer.get("reason"), str) or not answer["reason"].strip():
                raise SystemExit(
                    f"lesson task reading {reading_id} absent-witness declaration lacks a reason"
                )
            if any(key in answer for key in ("source", "recovered_span", "excerpt", "value")):
                raise SystemExit(
                    f"lesson task reading {reading_id} absent-witness declaration mixes witness evidence"
                )

        citations = {}
        for field in ("prompt", "operands"):
            citation = reading.get(field)
            if not isinstance(citation, dict) or not isinstance(citation.get("excerpt"), str):
                raise SystemExit(f"lesson task reading {reading_id} lacks {field} provenance")
            bound = _span_bound_markdown_provenance(citation, span)
            if bound is not None:
                source, line, end_line, pages = bound
            else:
                source, line, end_line, pages = _reviewed_provenance(
                    citation,
                    citation["excerpt"],
                    "",
                    f"lesson task reading {reading_id} {field}",
                    recovered_spans=recovered_by_key,
                )
            if pages:
                raise SystemExit(
                    f"lesson task reading {reading_id} {field} uses banned e343_pdf provenance"
                )
            recovered = citation.get("recovered_span")
            if recovered is not None:
                recovered_key = (recovered.get("lesson"), recovered.get("position"))
                if recovered_key != (lesson, span_position):
                    raise SystemExit(
                        f"lesson task reading {reading_id} span-binding failed: {field} "
                        f"names {recovered_key[0]}/{recovered_key[1]}"
                    )
            elif (
                source != span.source
                or not (span.heading_line <= line <= end_line <= span.end_line)
                or citation["excerpt"] not in span.text
            ):
                raise SystemExit(
                    f"lesson task reading {reading_id} span-binding failed: {field}"
                )
            citations[field] = (citation, source, line, end_line)

        operands_excerpt = citations["operands"][0]["excerpt"]
        for operand in (left, right):
            if not _task_reading_operand_present(operand, operands_excerpt):
                raise SystemExit(
                    f"lesson task reading {reading_id} operands missing from excerpt: {operand}"
                )
        operands_span = span
        if citations["operands"][0].get("recovered_span") is not None:
            recovered_key = (lesson, span_position)
            operands_span = recovered_by_key[recovered_key]
            unit_match = re.search(r"/recovered_equation\((\d+)\)$", position)
            if unit_match is not None:
                units = _recovered_printed_equation_units(operands_span)
                unit_number = int(unit_match.group(1))
                if not (1 <= unit_number <= len(units)):
                    raise SystemExit(
                        f"lesson task reading {reading_id} names no recovered "
                        f"equation unit: {unit_number}"
                    )
                unit = units[unit_number - 1]
                if operands_excerpt not in unit:
                    raise SystemExit(
                        f"lesson task reading {reading_id} operands leave recovered "
                        f"equation unit {unit_number}"
                    )
                operands_span = StudentTaskSpan(
                    lesson,
                    recovered_by_key[recovered_key].source,
                    0,
                    0,
                    position,
                    ((0, unit),),
                )
        if not _operands_scope_one_item(operands_span, operands_excerpt):
            raise SystemExit(
                f"lesson task reading {reading_id} item-scope failed: operands cite multiple items"
            )
        if not _operands_content_scope_matches(operator, left, right, operands_excerpt):
            raise SystemExit(
                f"lesson task reading {reading_id} content-scope failed: operands do not cite exactly the task expression"
            )
        if not _operands_expression_is_maximal(
            operands_span,
            operands_excerpt,
            citations["operands"][2],
            citations["operands"][3],
        ):
            raise SystemExit(
                f"lesson task reading {reading_id} maximality failed: operands cite a truncated expression"
            )

        witness_class = "declared_absent" if absent_witness else "printed_answer"
        if not absent_witness:
            if not isinstance(answer, dict) or not isinstance(answer.get("excerpt"), str):
                raise SystemExit(f"lesson task reading {reading_id} has malformed printed_answer")
            source, line, end_line, pages = _reviewed_provenance(
                answer,
                answer["excerpt"],
                "",
                f"lesson task reading {reading_id} printed_answer",
                recovered_spans=recovered_by_key,
            )
            if pages:
                raise SystemExit(
                    f"lesson task reading {reading_id} printed_answer uses banned e343_pdf provenance"
                )
            value = answer.get("value")
            try:
                witness = Fraction(str(value))
            except (TypeError, ValueError, ZeroDivisionError):
                raise SystemExit(
                    f"lesson task reading {reading_id} has non-exact printed answer: {value!r}"
                ) from None
            computed = _task_reading_value(operator, left, right)
            if computed != witness:
                raise SystemExit(
                    f"lesson task reading {reading_id} printed answer disagrees: "
                    f"task={computed} witness={value}"
                )
            if not _printed_answer_states_value(witness, answer["excerpt"]):
                raise SystemExit(
                    f"lesson task reading {reading_id} printed answer is absent from "
                    f"its own witness excerpt: value={value} "
                    f"excerpt={answer['excerpt']!r}"
                )
            # A printed answer is a witness only when it is in the first response
            # block after the cited task span. This deliberately follows document
            # order rather than matching task and response ordinals.
            if source != span.source:
                raise SystemExit(
                    f"lesson task reading {reading_id} printed answer must cite the "
                    f"teacher guide for {lesson}/{span_position}"
                )
            response_range = _next_response_range(root / source, span.heading_line)
            if response_range is None or not (response_range[0] < line <= response_range[1]):
                raise SystemExit(
                    f"lesson task reading {reading_id} printed answer is not in the "
                    f"next Student Response block after {lesson}/{span_position}"
                )

        if lesson not in covered:
            raise SystemExit(
                f"lesson task reading {reading_id} references lesson without accepted mapping: {lesson}"
            )
        operation = expected_operation
        # The covered set grants a lesson an attachment; this operation check is
        # deliberately explicit so an authored task cannot borrow an unrelated route.
        if not any(attached_operation == operation for attached_operation, _ in attachments.get(lesson, set())):
            raise SystemExit(
                f"lesson task reading {reading_id} has no {operation} route: {lesson}"
            )
        operand_citation, source, line, end_line = citations["operands"]
        validated.append({
            "id": reading_id,
            "lesson": lesson,
            "task": reading["task"],
            "position": position,
            "excerpt": operand_citation["excerpt"],
            "source": source,
            "line": line,
            "end_line": end_line,
            "witness_class": witness_class,
        })
    return validated


def equation_witness_refusal(
    root: pathlib.Path,
    span: StudentTaskSpan,
    source: str,
    line: object,
    fragment: object,
    judgment: str,
    guide_lines: dict[str, list[str]] | None = None,
) -> str | None:
    """Why a cited printed judgment does not license the equation it is cited for.

    Returns ``None`` when the witness licenses, and otherwise the reason it does
    not.  Four things have to hold together, and each of them refuses something
    the others let through:

    * the excerpt has to *print* a judgment, opening with True or False, so that
      any sentence from the right block cannot stand in for an answer;
    * the judgment it prints has to be the judgment claimed, so the truth value
      is read off the guide rather than asserted beside it;
    * the excerpt has to be at the line it cites, so the text is the guide's;
    * that line has to be inside the first Student Response block after the task
      span, so a "True or False?" activity title elsewhere on the page is not a
      response to this prompt.

    This is the truth-value counterpart of the printed-answer rule tightened in
    ``_printed_answer_states_value``: a witness has to state what it licenses.
    """
    if not isinstance(fragment, str) or not fragment.strip():
        return "witness excerpt is empty"
    match = equation_verification.JUDGMENT_RE.match(fragment)
    if match is None:
        return "witness excerpt prints no leading True or False judgment"
    if match.group("judgment").lower() != judgment:
        return (
            f"witness excerpt states {match.group('judgment').lower()!r} "
            f"but the row claims {judgment!r}"
        )
    if not isinstance(line, int) or isinstance(line, bool) or line < 1:
        return "witness line is not a line number"
    if guide_lines is None:
        guide_lines = {}
    if source not in guide_lines:
        guide_lines[source] = (root / source).read_text(
            encoding="utf-8", errors="replace"
        ).split("\n")
    lines = guide_lines[source]
    if line > len(lines):
        return "witness line is outside the guide"
    if _normalize_fragment(fragment) not in _normalize_fragment(lines[line - 1]):
        return f"witness excerpt drifted at {source}:{line}"
    response_range = _next_response_range(root / source, span.heading_line)
    if response_range is None or not (response_range[0] < line <= response_range[1]):
        return "witness is not in the next Student Response block after the task span"
    return None


def validate_equation_verifications(
    root: pathlib.Path,
    docs: list[LessonDoc],
    covered: set[str],
    attachments: dict[str, set[tuple[str, str]]],
    ledger_path: pathlib.Path = EQUATION_VERIFICATIONS,
) -> list[dict]:
    """Re-derive the equation-verification ledger and refuse every claim it cannot prove.

    The ledger is generated, so the question here is not whether someone
    authored it carefully but whether the tree still says what it says.  The
    compiler re-reads the guides, re-segments the equations, re-parses the
    printed judgments, and accepts a row only when the ledger agrees with that
    reading in every field it could otherwise invent: the equation text, the
    claim term, the witness line, and the judgment printed on it.  The verdict
    is pinned from the other side, by requiring it to match a judgment the
    compiler read for itself out of the guide.
    """
    path = ledger_path if ledger_path.is_absolute() else root / ledger_path
    payload = json.loads(path.read_text(encoding="utf-8"))
    if payload.get("schema") != equation_verification.LEDGER_SCHEMA:
        raise SystemExit(
            f"unexpected equation verification schema in {path}: {payload.get('schema')!r}"
        )
    if not isinstance(payload.get("register"), str):
        raise SystemExit(f"equation verification ledger lacks a register paragraph: {path}")
    spans = extract_student_task_spans(docs)
    recovered = {
        (span.code, span.position): span
        for span in read_recovered_task_spans(root, spans)
    }
    derived = {
        (reading.lesson, reading.position): reading
        for reading in equation_verification.read_span_readings(
            root, spans, recovered, {doc.code: doc for doc in docs},
            attachments, _next_response_range,
        )
    }
    span_by_key = {(span.code, span.position): span for span in spans}
    guide_lines: dict[str, list[str]] = {}
    accepted: list[dict] = []
    for entry in payload.get("spans", []):
        lesson = entry.get("lesson")
        position = entry.get("position")
        if not isinstance(lesson, str) or not isinstance(position, str):
            raise SystemExit(f"malformed equation verification span identity: {entry!r}")
        label = f"equation verification {lesson}/{position}"
        reading = derived.get((lesson, position))
        if reading is None:
            raise SystemExit(f"{label} names no True-or-False routine span")
        if entry.get("refusal") != reading.refusal:
            raise SystemExit(
                f"{label} refusal disagrees with the corpus: "
                f"ledger {entry.get('refusal')!r} != {reading.refusal!r}"
            )
        rows = entry.get("rows")
        if not isinstance(rows, list) or len(rows) != len(reading.rows):
            raise SystemExit(f"{label} row count disagrees with the corpus")
        for row, derived_row in zip(rows, reading.rows):
            for key in ("equation", "claim", "position", "witness_line",
                        "witness_judgment", "witness_fragment", "witness_source"):
                if row.get(key) != getattr(derived_row, key):
                    raise SystemExit(
                        f"{label} {key} disagrees with the corpus: "
                        f"{row.get(key)!r} != {getattr(derived_row, key)!r}"
                    )
            if not row.get("accepted"):
                continue
            if reading.refusal:
                raise SystemExit(f"{label} accepts a row inside a refused span")
            verdict = row.get("verdict")
            expected = {"holds": "true", "refuted": "false"}.get(verdict)
            if expected is None:
                raise SystemExit(f"{label} accepted row carries no checked verdict")
            if expected != derived_row.witness_judgment:
                raise SystemExit(
                    f"{label} verdict {verdict!r} contradicts the printed judgment "
                    f"{derived_row.witness_judgment!r}"
                )
            checker = row.get("checker")
            if not isinstance(checker, str) or not checker:
                raise SystemExit(f"{label} accepted row names no checker")
            witness_line = derived_row.witness_line
            source = derived_row.witness_source
            span = span_by_key[(lesson, position)]
            refusal = equation_witness_refusal(
                root, span, source, witness_line, derived_row.witness_fragment,
                derived_row.witness_judgment, guide_lines,
            )
            if refusal is not None:
                raise SystemExit(f"{label} {refusal}")
            equation_span = recovered.get((lesson, position)) if (
                derived_row.equation_source == "recovered_task_spans"
            ) else span
            if derived_row.equation not in equation_span.text:
                raise SystemExit(f"{label} equation is absent from the span it names")
            if derived_row.equation_source == "markdown":
                # A markdown equation is line-addressable, so it gets the drift
                # check every other markdown citation in this compiler gets:
                # the excerpt has to be inside the student-facing lines it
                # cites, not merely somewhere in the span.
                printed = _normalize_fragment(" ".join(
                    text for number, text in span.lines
                    if derived_row.equation_line <= number <= derived_row.equation_end_line
                ))
                if _normalize_fragment(derived_row.equation) not in printed:
                    raise SystemExit(
                        f"{label} equation drifted at {derived_row.span_source}:"
                        f"{derived_row.equation_line}-{derived_row.equation_end_line}"
                    )
            for task in derived_row.tasks:
                if task.status != "reviewable":
                    continue
                # An adjudicated equation with a printed judgment is a record
                # either way; only a runnable task needs the lesson to carry a
                # route, so the coverage question is asked here and not above.
                if lesson not in covered:
                    raise SystemExit(
                        f"{label} runnable task on a lesson without accepted mapping"
                    )
                if not any(
                    operation == task.operation
                    for operation, _ in attachments.get(lesson, set())
                ):
                    raise SystemExit(
                        f"{label} task has no {task.operation} route: {lesson}"
                    )
                accepted.append({
                    "lesson": lesson,
                    "task": task.task,
                    "id": task.rule_id,
                    # The excerpt is the printed equation, so the cited source
                    # is where the equation is printed. The witness lives in the
                    # response block and travels in the position term, which is
                    # what keeps both halves independently addressable.
                    "source": derived_row.span_source,
                    "line": derived_row.equation_line,
                    "end_line": derived_row.equation_line,
                    "position": (
                        f"{derived_row.position}/side({task.side})"
                        f"/witness(line({witness_line}))"
                    ),
                    "excerpt": derived_row.equation,
                    "witness_class": equation_verification.WITNESS_CLASS,
                    "claim": row.get("claim"),
                    "verdict": verdict,
                    "checker": checker,
                    "reason_trace": row.get("reason_trace", []),
                    "witness_judgment": derived_row.witness_judgment,
                    "witness_fragment": derived_row.witness_fragment,
                    "equation_source": derived_row.equation_source,
                    "viability": row.get("viability", []),
                })
    return accepted


def _normalize_fragment(text: str) -> str:
    return re.sub(r"\s+", " ", text.replace("\f", " ")).strip()


NUMBER_WORDS = {
    "one": 1,
    "two": 2,
    "three": 3,
    "four": 4,
    "five": 5,
    "six": 6,
    "seven": 7,
    "eight": 8,
    "nine": 9,
    "ten": 10,
    "eleven": 11,
    "twelve": 12,
}
NUMBER_TOKEN = r"(?:\d+|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve)"
CONVERSION_FACTORS = {
    ("kilometer", "meter"): 1000,
    ("meter", "centimeter"): 100,
    ("kilogram", "gram"): 1000,
    ("liter", "milliliter"): 1000,
    ("pound", "ounce"): 16,
    ("hour", "minute"): 60,
}


def _number(token: str) -> int:
    return int(token) if token.isdigit() else NUMBER_WORDS[token.lower()]


def _arithmetic_number(token: str) -> int:
    """Parse a whole-number operand while retaining its cited comma spelling."""
    return int(token.replace(",", ""))


def _decimal_parts(token: str) -> tuple[int, int]:
    whole, fractional = token.split(".", 1)
    return int(whole + fractional), 10 ** len(fractional)


def _singular(noun: str) -> str:
    noun = noun.lower()
    if noun == "feet":
        return "foot"
    if noun.endswith("ies"):
        return noun[:-3] + "y"
    if noun.endswith(("ches", "shes", "xes", "zes")):
        return noun[:-2]
    return noun[:-1] if noun.endswith("s") else noun


def _counted_referent(group_phrase: str) -> str:
    head = re.split(r"\b(?:in|on|of|for|with)\b", group_phrase, maxsplit=1)[0]
    words = re.findall(r"[A-Za-z]+", head)
    return _singular(words[-1]) if words else ""


def _task_chunks(span: StudentTaskSpan) -> list[tuple[int, int, str, str]]:
    """Split a prompt into numbered items while retaining exact source ranges."""
    chunks: list[list[tuple[int, str]]] = []
    current: list[tuple[int, str]] = []
    for line_no, text in span.lines:
        if re.match(r"^\d+\.\s+", text) and current:
            chunks.append(current)
            current = []
        current.append((line_no, text))
    if current:
        chunks.append(current)
    return [
        (
            chunk[0][0],
            chunk[-1][0],
            f"{span.position}/item({index})",
            " ".join(text for _, text in chunk),
        )
        for index, chunk in enumerate(chunks, 1)
    ]


def _compound_expression_units(
    span: StudentTaskSpan,
) -> list[tuple[int, int, str, str]]:
    """Segment exact printed arithmetic units without slicing prose numerals.

    Physical bullet lines and numbered expression items provide explicit
    boundaries.  Runs of three or more spaces are the surviving column gutters
    in horizontally printed choice banks and cards.  A numbered marker is
    removed only when the remainder is itself a complete arithmetic unit, so
    ``1.`` is not an operand and ``2 rocks`` is not mistaken for one.  The
    fullmatch is equally important at the other boundary: ``6- 2`` survives
    Docling spacing, while a binary subexpression inside a longer expression
    does not become a standalone unit.

    This function segments only.  The prompt-specific caller decides whether a
    unit asks for computation, adjudication, matching, or generation.
    """
    numeral = ARITHMETIC_NUMERAL
    operator = r"[+\-−×·÷]"
    side = rf"{numeral}(?:\s*{operator}\s*{numeral})*"
    relation = rf"(?:{side})\s*(?:=|>|<)\s*(?:{side})"
    binary = rf"{numeral}\s*{operator}\s*{numeral}"
    unit_re = re.compile(rf"(?:{relation}|{binary})")
    item_marker_re = re.compile(r"^(?:[1-9]|[1-9]\d)\.\s+")
    units: list[tuple[int, int, str, str]] = []
    for line, text in span.lines:
        bullet_cells = re.split(r"\s*[•◦]\s*", text)
        cells = [
            cell
            for bullet_cell in bullet_cells
            for cell in re.split(r"\s{3,}", bullet_cell)
        ]
        for cell in cells:
            candidate = cell.strip()
            marker = item_marker_re.match(candidate)
            if marker is not None:
                candidate = candidate[marker.end():].strip()
            if not candidate or unit_re.fullmatch(candidate) is None:
                continue
            units.append(
                (
                    line,
                    line,
                    f"{span.position}/compound_unit({len(units) + 1})",
                    candidate,
                )
            )
    return units


def _whole_numbers_in_text(text: str) -> list[int]:
    return [
        int(match.group(0))
        for match in re.finditer(r"(?<![\d.,])\d+(?![\d.,])", text)
    ]


def _through_how_many_question(text: str) -> str:
    match = re.search(r"^.*?\bHow many\b[^?]*\?", text, re.IGNORECASE)
    return match.group(0) if match else text


def _narrative_referent(phrase: str) -> str:
    """Return the counted head carried by one bounded narrative phrase."""
    head = re.split(
        r"\b(?:at|in|on|of|for|with|to|from|are|is|was|were|does|do|did|"
        r"has|have|had|gets?|gives?|gave|puts?|put|brings?|brought|adds?|"
        r"join|joins|come|comes|swim|swims|fly|flies|sit|sits|long|now|"
        r"still|altogether|will|should|can)\b",
        phrase,
        maxsplit=1,
        flags=re.IGNORECASE,
    )[0]
    words = re.findall(r"[A-Za-z]+", head)
    return _singular(words[-1]) if words else ""


def _prior_quantity_has_referent(text: str, end: int, referent: str) -> bool:
    """Guard a local binary reading against an earlier same-referent operand."""
    if not referent:
        return False
    for match in re.finditer(
        rf"{ARITHMETIC_NUMERAL}\s+(?P<phrase>[A-Za-z][A-Za-z '-]{{0,40}})",
        text[:end],
    ):
        if _narrative_referent(match.group("phrase")) == referent:
            return True
    return False


def _narrative_referents_agree(left: str, right: str) -> bool:
    if left == right:
        return True
    human_referents = {
        "child",
        "children",
        "dancer",
        "kid",
        "people",
        "person",
        "student",
    }
    return left in human_referents and right in human_referents


def _narrative_phrase_referent(phrase: str) -> str:
    """Normalize a full group phrase while retaining distinguishing modifiers."""
    words = re.findall(r"[A-Za-z]+(?:-[A-Za-z]+)?", phrase.lower())
    if not words:
        return ""
    words[-1] = _singular(words[-1])
    return " ".join(words)


@lru_cache(maxsize=None)
def _narrative_quantity_specs(text: str) -> list[tuple[str, str, str, str]]:
    """Read named, binary whole-number narratives from one task chunk.

    Each shape ends at the question that requests its result.  Referent checks
    keep unrelated numerals from becoming operands, while the named shapes keep
    representation selection, estimation, and multi-step work outside this
    family.
    """
    numeral = ARITHMETIC_NUMERAL
    specs: set[tuple[str, str, str, str]] = set()

    join_more = re.compile(
        rf"(?P<a>{numeral}) (?P<a_group>[A-Za-z][^.?]{{0,70}})\.\s+"
        rf"(?P<change>[^.?]{{0,90}}?\b(?P<b>{numeral}) more"
        rf"(?P<b_group>[^.?]{{0,45}}))\.\s+How many(?P<q>[^?]*)\?",
        re.IGNORECASE,
    )
    for match in join_more.finditer(text):
        if not re.search(
            r"\b(?:gets?|gives?|gave|brings?|brought|adds?|puts?|put|"
            r"join|joins|come|comes|checks? out)\b",
            match.group("change"),
            re.IGNORECASE,
        ):
            continue
        left_ref = _narrative_referent(match.group("a_group"))
        right_ref = _narrative_referent(match.group("b_group"))
        question_ref = _narrative_referent(match.group("q"))
        if not left_ref or (right_ref and right_ref != left_ref):
            continue
        if question_ref and question_ref != left_ref:
            continue
        specs.add(
            (
                "narrative_join_more_result_unknown",
                "addition",
                f"add({_arithmetic_number(match.group('a'))}, "
                f"{_arithmetic_number(match.group('b'))})",
                match.group(0),
            )
        )

    two_actor_combine = re.compile(
        rf"\b(?:[A-Z][a-z]+|Her grandfather) "
        rf"(?:finds?|buys?|puts?|put|draws?|plants?) "
        rf"(?P<a>{numeral}) (?P<a_group>[A-Za-z][^.?]{{0,45}})\.\s+"
        rf"(?:Then )?(?:[A-Z][a-z]+|Her grandfather) "
        rf"(?:finds?|buys?|puts?|put|draws?|plants?) "
        rf"(?P<b>{numeral}) (?P<b_group>[A-Za-z][^.?]{{0,45}})\.\s+"
        rf"How many(?P<q>[^?]*)\?",
        re.IGNORECASE,
    )
    for match in two_actor_combine.finditer(text):
        if re.search(r"\b(?:all together|altogether|in all)\b", match.group("q"), re.IGNORECASE):
            continue
        left_ref = _narrative_referent(match.group("a_group"))
        right_ref = _narrative_referent(match.group("b_group"))
        question_ref = _narrative_referent(match.group("q"))
        if not left_ref or left_ref != right_ref or left_ref != question_ref:
            continue
        if _prior_quantity_has_referent(text, match.start(), left_ref):
            continue
        specs.add(
            (
                "narrative_two_actor_combine_result_unknown",
                "addition",
                f"add({_arithmetic_number(match.group('a'))}, "
                f"{_arithmetic_number(match.group('b'))})",
                match.group(0),
            )
        )

    same_unit_combine = re.compile(
        rf"\b[^.?]{{0,45}} is (?P<a>{numeral}) (?P<unit1>[A-Za-z]+) long\.\s+"
        rf"[^.?]{{0,45}} is (?P<b>{numeral}) (?P<unit2>[A-Za-z]+) long\.\s+"
        rf"How many (?P<question_unit>[A-Za-z]+) long [^?]*together\?",
        re.IGNORECASE,
    )
    for match in same_unit_combine.finditer(text):
        units = {
            _singular(match.group("unit1")),
            _singular(match.group("unit2")),
            _singular(match.group("question_unit")),
        }
        if len(units) != 1:
            continue
        specs.add(
            (
                "narrative_same_unit_combine_result_unknown",
                "addition",
                f"add({_arithmetic_number(match.group('a'))}, "
                f"{_arithmetic_number(match.group('b'))})",
                match.group(0),
            )
        )

    take_before_number = re.compile(
        rf"(?P<total>{numeral}) (?P<total_group>[A-Za-z][^.?]{{0,65}})\.\s+"
        rf"[^.?]{{0,65}}\b(?:takes?|took) (?P<removed>{numeral})"
        rf"(?: of the (?P<removed_group>[A-Za-z]+))?[^.?]*\.\s+"
        rf"How many(?P<q>[^?]*)\?",
        re.IGNORECASE,
    )
    take_after_number = re.compile(
        rf"(?P<total>{numeral}) (?P<total_group>[A-Za-z][^.?]{{0,65}})\.\s+"
        rf"(?P<removed>{numeral})(?: of the)? "
        rf"(?P<removed_group>[A-Za-z]+)[^.?]{{0,45}}\b"
        rf"(?:gets? off|fall|falls|leave|leaves)[^.?]*\.\s+"
        rf"How many(?P<q>[^?]*)\?",
        re.IGNORECASE,
    )
    for pattern in (take_before_number, take_after_number):
        for match in pattern.finditer(text):
            if len(re.findall(ARITHMETIC_NUMERAL, match.group(0))) != 2:
                continue
            total_ref = _narrative_referent(match.group("total_group"))
            removed_ref = _narrative_referent(match.group("removed_group") or "")
            question_ref = _narrative_referent(match.group("q"))
            if not total_ref or (removed_ref and removed_ref != total_ref):
                continue
            if question_ref and question_ref != total_ref:
                continue
            specs.add(
                (
                    "narrative_take_from_result_unknown",
                    "subtraction",
                    f"subtract({_arithmetic_number(match.group('total'))}, "
                    f"{_arithmetic_number(match.group('removed'))})",
                    match.group(0),
                )
            )

    missing_addend = re.compile(
        rf"(?P<known>{numeral}) (?P<known_group>[A-Za-z][^.?]{{0,45}})\.\s+"
        rf"(?P<change>[^.?]{{0,80}}some more[^.?]*)\.\s+Now [^.?]{{0,45}} "
        rf"(?P<total>{numeral}) (?P<total_group>[A-Za-z][^.?]{{0,45}})\.\s+"
        rf"How many(?P<q>[^?]*)\?",
        re.IGNORECASE,
    )
    starts_and_adds = re.compile(
        rf"\b[^.?]{{0,35}} starts with (?P<known>{numeral}) "
        rf"(?P<known_group>[A-Za-z]+) and adds some more\.\s+"
        rf"[^.?]{{0,40}} with (?P<total>{numeral}) "
        rf"(?P<total_group>[A-Za-z]+)\.\s+How many "
        rf"(?P<q>[A-Za-z]+)[^?]*\?",
        re.IGNORECASE,
    )
    for pattern in (missing_addend, starts_and_adds):
        for match in pattern.finditer(text):
            change = match.groupdict().get("change") or ""
            if re.search(ARITHMETIC_NUMERAL, change):
                continue
            if re.match(r"\s*more\b", match.group("q"), re.IGNORECASE):
                continue
            known_ref = _narrative_referent(match.group("known_group"))
            total_ref = _narrative_referent(match.group("total_group"))
            question_ref = _narrative_referent(match.group("q"))
            if not known_ref or {known_ref, total_ref, question_ref} != {known_ref}:
                continue
            known = _arithmetic_number(match.group("known"))
            total = _arithmetic_number(match.group("total"))
            if total <= known:
                continue
            specs.add(
                (
                    "narrative_add_to_change_unknown",
                    "subtraction",
                    f"subtract({total}, {known})",
                    match.group(0),
                )
            )

    hidden_part = re.compile(
        rf"There are (?P<known>{numeral}) (?P<known_group>[A-Za-z]+) "
        rf"outside [^.?]+\.\s+Some of the (?P<hidden_group>[A-Za-z]+) "
        rf"are under [^.?]+\.\s+There are (?P<total>{numeral}) "
        rf"(?P<total_group>[A-Za-z]+) total\.\s+How many "
        rf"(?P<q>[A-Za-z]+) are under [^?]+\?",
        re.IGNORECASE,
    )
    for match in hidden_part.finditer(text):
        refs = {
            _singular(match.group(name))
            for name in ("known_group", "hidden_group", "total_group", "q")
        }
        if len(refs) != 1:
            continue
        known = _arithmetic_number(match.group("known"))
        total = _arithmetic_number(match.group("total"))
        if total <= known:
            continue
        specs.add(
            (
                "narrative_total_known_part_missing_part",
                "subtraction",
                f"subtract({total}, {known})",
                match.group(0),
            )
        )

    groups_then_each = re.compile(
        rf"(?<!to )(?P<groups>{numeral}) "
        rf"(?P<group_phrase>[A-Za-z][^.?]{{0,45}})\.\s+"
        rf"[^.?]{{0,70}} (?P<size>{numeral}) "
        rf"(?P<item_phrase>[A-Za-z][A-Za-z -]{{0,30}}) "
        rf"(?:to|into|in|on) each (?P<each_group>[A-Za-z]+)\.\s+"
        rf"How many (?P<question_item>[A-Za-z]+)[^?]*(?:in all|altogether|"
        rf"put in|donate)[^?]*\?",
        re.IGNORECASE,
    )
    donated_each = re.compile(
        rf"[^.?]*\bto (?P<groups>{numeral}) "
        rf"(?P<group_phrase>[A-Za-z][A-Za-z -]{{0,25}})\.\s+"
        rf"[^.?]* (?P<size>{numeral}) (?P<item_phrase>[A-Za-z]+) "
        rf"to each (?P<each_group>[A-Za-z]+)\.\s+How many "
        rf"(?P<question_item>[A-Za-z]+)[^?]*(?:in all|altogether)\?",
        re.IGNORECASE,
    )
    for pattern in (groups_then_each, donated_each):
        for match in pattern.finditer(text):
            group_ref = _narrative_referent(match.group("group_phrase"))
            each_ref = _singular(match.group("each_group"))
            item_ref = _narrative_referent(match.group("item_phrase"))
            question_ref = _singular(match.group("question_item"))
            if not group_ref or group_ref != each_ref or item_ref != question_ref:
                continue
            specs.add(
                (
                    "narrative_equal_groups_total_unknown",
                    "multiplication",
                    f"multiply({_arithmetic_number(match.group('groups'))}, "
                    f"{_arithmetic_number(match.group('size'))})",
                    match.group(0),
                )
            )

    rate_statement = re.compile(
        rf"\bA (?P<group>[A-Za-z]+(?:[- ][A-Za-z]+){{0,3}}) has "
        rf"(?P<size>{numeral}) (?P<items>[A-Za-z]+)\.",
        re.IGNORECASE,
    )
    rate_question = re.compile(
        rf"How many (?P<question_items>[A-Za-z]+) are in "
        rf"(?P<groups>{numeral}) (?P<question_groups>[A-Za-z -]+)\?",
        re.IGNORECASE,
    )
    for question in rate_question.finditer(text):
        question_group_ref = _narrative_phrase_referent(
            question.group("question_groups")
        )
        question_item_ref = _singular(question.group("question_items"))
        matching_rates = [
            statement
            for statement in rate_statement.finditer(text[: question.start()])
            if _narrative_phrase_referent(statement.group("group"))
            == question_group_ref
            and _singular(statement.group("items")) == question_item_ref
        ]
        if len(matching_rates) != 1:
            continue
        statement = matching_rates[0]
        specs.add(
            (
                "narrative_rate_total_unknown",
                "multiplication",
                f"multiply({_arithmetic_number(question.group('groups'))}, "
                f"{_arithmetic_number(statement.group('size'))})",
                text[statement.start() : question.end()],
            )
        )

    measurement_group_patterns = (
        re.compile(
            rf"(?P<total>{numeral}) (?P<items>[A-Za-z]+) [^.?]*\.\s+"
            rf"[^.?]* (?P<size>{numeral}) (?P<each_items>[A-Za-z]+) "
            rf"in each (?P<group>[A-Za-z]+)\.\s+How many "
            rf"(?P<question_group>[A-Za-z]+)[^?]*\?",
            re.IGNORECASE,
        ),
        re.compile(
            rf"There are (?P<total>{numeral}) (?P<items>[A-Za-z]+) [^.?]*\.\s+"
            rf"[^.?]* in groups of (?P<size>{numeral}) "
            rf"(?P<each_items>[A-Za-z]+)\.\s+How many "
            rf"(?P<question_group>groups)[^?]*\?",
            re.IGNORECASE,
        ),
        re.compile(
            rf"[^.?]* has (?P<total>{numeral}) (?P<items>[A-Za-z -]+) in "
            rf"(?P<group>[A-Za-z]+)\.\s+There are (?P<size>{numeral}) "
            rf"(?P<each_items>[A-Za-z -]+) in each (?P<each_group>[A-Za-z]+)\.\s+"
            rf"[^?]*How many (?P<question_group>[A-Za-z]+)[^?]*\?",
            re.IGNORECASE,
        ),
        re.compile(
            rf"[^.?]* makes (?P<total>{numeral}) (?P<items>[A-Za-z -]+) [^.?]*\.\s+"
            rf"[^.?]* gives (?P<size>{numeral}) (?P<each_items>[A-Za-z -]+) "
            rf"to each (?P<group>[A-Za-z]+)[^.?]*\.\s+How many "
            rf"(?P<question_group>[A-Za-z]+)[^?]*\?",
            re.IGNORECASE,
        ),
        re.compile(
            rf"There (?:are|were) (?P<total>{numeral}) (?P<items>[A-Za-z]+) "
            rf"[^.?]*\.\s+How many (?P<question_group>groups) of "
            rf"(?P<size>{numeral}) (?P<each_items>[A-Za-z]+)[^?]*\?",
            re.IGNORECASE,
        ),
    )
    for pattern in measurement_group_patterns:
        for match in pattern.finditer(text):
            item_ref = _narrative_referent(match.group("items"))
            each_item_ref = _narrative_referent(match.group("each_items"))
            question_group_ref = _narrative_referent(match.group("question_group"))
            if not item_ref or not _narrative_referents_agree(
                item_ref, each_item_ref
            ):
                continue
            group = match.groupdict().get("group")
            if group is None:
                if question_group_ref != "group":
                    continue
            else:
                group_ref = _narrative_referent(group)
                each_group = match.groupdict().get("each_group") or group
                each_group_ref = _narrative_referent(each_group)
                if not group_ref or group_ref != each_group_ref:
                    continue
                if question_group_ref not in {group_ref, "group"}:
                    continue
            specs.add(
                (
                    "narrative_measurement_division_groups_unknown",
                    "division",
                    f"divide({_arithmetic_number(match.group('total'))}, "
                    f"{_arithmetic_number(match.group('size'))})",
                    match.group(0),
                )
            )

    partitive_boxes = re.compile(
        rf"[^.?]* packs (?P<total>{numeral}) (?P<items>[A-Za-z]+) in "
        rf"(?P<groups>{numeral}) (?P<groups_noun>[A-Za-z]+)\.\s+"
        rf"[^.?]*same number of (?P<each_items>[A-Za-z]+) in each "
        rf"(?P<each_group>[A-Za-z]+)\.\s+How many "
        rf"(?P<question_items>[A-Za-z]+) are in each "
        rf"(?P<question_group>[A-Za-z]+)\?",
        re.IGNORECASE,
    )
    shared_measure = re.compile(
        rf"There are (?P<groups>{numeral}) (?P<groups_noun>[A-Za-z]+)\.\s+"
        rf"They share (?P<total>{numeral}) (?P<unit>[A-Za-z]+) of "
        rf"(?P<items>[A-Za-z]+) equally\.\s+How much "
        rf"(?P<question_items>[A-Za-z]+) does each "
        rf"(?P<question_group>[A-Za-z]+) get\?",
        re.IGNORECASE,
    )
    for pattern in (partitive_boxes, shared_measure):
        for match in pattern.finditer(text):
            groups_ref = _singular(match.group("groups_noun"))
            question_group_ref = _singular(match.group("question_group"))
            each_group_ref = _singular(
                match.groupdict().get("each_group") or match.group("question_group")
            )
            items_ref = _singular(match.group("items"))
            question_items_ref = _singular(match.group("question_items"))
            each_items_ref = _singular(
                match.groupdict().get("each_items") or match.group("items")
            )
            if groups_ref != each_group_ref or groups_ref != question_group_ref:
                continue
            if items_ref != each_items_ref or items_ref != question_items_ref:
                continue
            specs.add(
                (
                    "narrative_partitive_division_share_unknown",
                    "division",
                    f"divide({_arithmetic_number(match.group('total'))}, "
                    f"{_arithmetic_number(match.group('groups'))})",
                    match.group(0),
                )
            )

    return sorted(specs)


def _recovered_printed_equation_units(span: StudentTaskSpan) -> list[str]:
    """Split a sidecar pseudo-line into equation-sized units.

    Recovered spans retain the workbook's horizontal spacing but have no
    physical line boundaries.  This segmenter identifies only units with a
    printed blank: either a binary-or-longer expression followed by ``=``, or
    a stated total followed by a known operand and a trailing operator.  It
    does not decide which task grammar the unit carries.  The existing
    fullmatch parsers make that decision after segmentation, so a three-term
    unit remains whole and is refused rather than truncated.

    Two or more spaces after ``=`` are the sidecar's surviving blank box.  A
    one- or two-digit number followed by a period marks the next item after a
    trailing operator, including at end of string.  After ``=``, a numbered
    marker is accepted only when the later item has an unresolved equation
    shape.  A sentence-ending result followed by prose or another completed
    equation is not a boundary.  Repeated expressions with the same starting
    numeral are segmented at each equals sign, preserving the blanks in
    printed calculation chains.  Other single-space numerals are printed
    results, not blanks; this distinction refuses the teacher-column fragment
    ``2 + 8 = 10`` in IM-G1-U5-L6.
    """
    if not span.recovered:
        return []
    numeral = ARITHMETIC_NUMERAL
    operator = r"[+\-−×·÷]"
    list_number = r"(?:[1-9]|[1-9]\d)\."
    numbered_item = rf"{list_number}(?:\s|$)"
    common_blank_boundary = (
        r"\s{2,}|\s+(?:[A-Za-z]+\b|[a-z]\.\s)|\s*[•◦]|\s*$"
    )
    later_blank_boundary = (
        rf"(?={common_blank_boundary}|\s+{numbered_item})"
    )
    unresolved_equation_start = (
        rf"(?:=|"
        rf"{numeral}(?:\s*{operator}\s*{numeral})+\s*=|"
        rf"{numeral}\s*=\s*{numeral}\s*{operator})"
    )
    unresolved_result_boundary = (
        rf"(?={common_blank_boundary}|"
        rf"\s+{list_number}\s+"
        rf"(?=(?:{list_number}\s+)*{unresolved_equation_start}))"
    )
    unresolved_equation = (
        rf"(?:=|"
        rf"{numeral}(?:\s*{operator}\s*{numeral})+\s*="
        rf"{unresolved_result_boundary}|"
        rf"{numeral}\s*=\s*{numeral}\s*{operator}{later_blank_boundary})"
    )
    numbered_equation_item = (
        rf"{list_number}\s+"
        rf"(?=(?:{list_number}\s+)*{unresolved_equation})"
    )
    result_blank_boundary = (
        rf"(?={common_blank_boundary}|\s+{numbered_equation_item})"
    )
    operand_blank_boundary = (
        rf"(?={common_blank_boundary}|\s+{numbered_item})"
    )
    pattern = re.compile(
        rf"(?<![\d,])(?:"
        rf"{numeral}(?:\s*{operator}\s*{numeral})+\s*="
        rf"{result_blank_boundary}|"
        rf"{numeral}\s*=\s*{numeral}\s*{operator}{operand_blank_boundary}"
        rf")(?![\d,])"
    )
    units = [
        (match.start(), match.group(0).strip())
        for match in pattern.finditer(span.text)
    ]

    if not re.search(
        r"\bFind the number that makes each equation true\b",
        span.text,
        re.IGNORECASE,
    ):
        return [unit for _, unit in sorted(set(units))]

    # A flattened calculation chain retains a trustworthy boundary when the
    # next expression restarts from the same first numeral.  Requiring that
    # repeated start distinguishes the chain from a completed equation whose
    # printed result happens to precede another expression.
    chain_pattern = re.compile(
        rf"(?<![\d,])(?P<expression>(?P<start>{numeral})"
        rf"(?:\s*{operator}\s*{numeral})+)\s*="
        rf"(?=\s+(?P<next>{numeral})\s*{operator})"
    )
    for match in chain_pattern.finditer(span.text):
        if _arithmetic_number(match.group("start")) != _arithmetic_number(
            match.group("next")
        ):
            continue
        units.append((match.start(), f"{match.group('expression').strip()} ="))
    return [unit for _, unit in sorted(set(units))]


def _printed_equation_items(equation: str) -> list[tuple[str, str, str]]:
    """Apply the existing equation-list fullmatch grammars to one unit."""
    direct_patterns = (
        (
            "printed_equation_list_direct_addition",
            "addition",
            "add",
            re.compile(
                rf"(?P<a>{ARITHMETIC_NUMERAL})\s*\+\s*"
                rf"(?P<b>{ARITHMETIC_NUMERAL})\s*=\s*$"
            ),
        ),
        (
            "printed_equation_list_direct_addition",
            "addition",
            "add",
            re.compile(
                rf"=\s*(?P<a>{ARITHMETIC_NUMERAL})\s*\+\s*"
                rf"(?P<b>{ARITHMETIC_NUMERAL})\s*$"
            ),
        ),
        (
            "printed_equation_list_direct_subtraction",
            "subtraction",
            "subtract",
            re.compile(
                rf"(?P<a>{ARITHMETIC_NUMERAL})\s*[-−]\s*"
                rf"(?P<b>{ARITHMETIC_NUMERAL})\s*=\s*$"
            ),
        ),
        (
            "printed_equation_list_direct_subtraction",
            "subtraction",
            "subtract",
            re.compile(
                rf"=\s*(?P<a>{ARITHMETIC_NUMERAL})\s*[-−]\s*"
                rf"(?P<b>{ARITHMETIC_NUMERAL})\s*$"
            ),
        ),
    )
    missing_addend_patterns = (
        re.compile(
            rf"(?P<total>{ARITHMETIC_NUMERAL})\s*=\s*"
            rf"(?P<known>{ARITHMETIC_NUMERAL})\s*\+\s*$"
        ),
        re.compile(
            rf"\+\s*(?P<known>{ARITHMETIC_NUMERAL})\s*=\s*"
            rf"(?P<total>{ARITHMETIC_NUMERAL})\s*$"
        ),
    )
    items = []
    for parser_id, operation, task_name, pattern in direct_patterns:
        match = pattern.fullmatch(equation)
        if match:
            items.append(
                (
                    parser_id,
                    operation,
                    f"{task_name}({_arithmetic_number(match.group('a'))}, "
                    f"{_arithmetic_number(match.group('b'))})",
                )
            )
    for pattern in missing_addend_patterns:
        match = pattern.fullmatch(equation)
        if match:
            items.append(
                (
                    "printed_equation_list_missing_addend",
                    "subtraction",
                    f"subtract({_arithmetic_number(match.group('total'))}, "
                    f"{_arithmetic_number(match.group('known'))})",
                )
            )
    return items


def _recovered_equation_items(span: StudentTaskSpan) -> list[tuple[str, str, str, str]]:
    """Segment complete binary equations restored by the sidecar.

    This is not a new task grammar.  It supplies item boundaries that the
    markdown reader normally obtains from physical lines, then delegates each
    shape to the existing printed-equation parser identities below.  A total on
    the left of addition stays a missing-addend relation, even when the sidecar
    also restored the difference on the right.
    """
    if not span.recovered or not re.search(r"\bWhich 3 go together\?", span.text, re.IGNORECASE):
        return []
    items = []
    patterns = (
        (
            "printed_equation_list_direct_addition",
            "addition",
            re.compile(rf"(?<![\d,])(?P<a>{ARITHMETIC_NUMERAL})\s*\+\s*(?P<b>{ARITHMETIC_NUMERAL})\s*=\s*(?P<result>{ARITHMETIC_NUMERAL})(?![\d,])"),
        ),
        (
            "printed_equation_list_direct_subtraction",
            "subtraction",
            re.compile(rf"(?<![\d,])(?P<a>{ARITHMETIC_NUMERAL})\s*[-−]\s*(?P<b>{ARITHMETIC_NUMERAL})\s*=\s*(?P<result>{ARITHMETIC_NUMERAL})(?![\d,])"),
        ),
        (
            "printed_equation_list_missing_addend",
            "subtraction",
            re.compile(rf"(?<![\d,])(?P<total>{ARITHMETIC_NUMERAL})\s*=\s*(?P<known>{ARITHMETIC_NUMERAL})\s*\+\s*(?P<difference>{ARITHMETIC_NUMERAL})(?![\d,])"),
        ),
    )
    for parser_id, operation, pattern in patterns:
        for match in pattern.finditer(span.text):
            if parser_id == "printed_equation_list_missing_addend":
                total = _arithmetic_number(match.group("total"))
                known = _arithmetic_number(match.group("known"))
                difference = _arithmetic_number(match.group("difference"))
                if total - known != difference:
                    continue
                task = f"subtract({total}, {known})"
            else:
                task_name = "add" if operation == "addition" else "subtract"
                left = _arithmetic_number(match.group("a"))
                right = _arithmetic_number(match.group("b"))
                result = _arithmetic_number(match.group("result"))
                if (operation == "addition" and left + right != result) or (
                    operation == "subtraction" and left - right != result
                ):
                    continue
                task = f"{task_name}({left}, {right})"
            items.append((parser_id, operation, task, match.group(0)))
    return sorted(items, key=lambda item: span.text.index(item[3]))


def extract_task_candidates(
    spans: list[StudentTaskSpan], attachments: dict[str, set[tuple[str, str]]]
) -> list[TaskCandidate]:
    """Extract exact operand-bearing prompts for review, never direct promotion."""
    number = NUMBER_TOKEN
    direct_binary_prompt = re.compile(
        rf"^\s*(?:\d+\.\s*)?(?P<excerpt>Find the value of (?P<a>{ARITHMETIC_NUMERAL})\s*"
        rf"(?P<symbol>[+\-−×·÷])\s*(?P<b>{ARITHMETIC_NUMERAL})\."
        r")(?:\s+.*)?$",
        re.IGNORECASE,
    )
    direct_operations = {
        "+": ("addition", "add"),
        "-": ("subtraction", "subtract"),
        "−": ("subtraction", "subtract"),
        "×": ("multiplication", "multiply"),
        "·": ("multiplication", "multiply"),
        "÷": ("division", "divide"),
    }
    patterns = [
        (
            "equal_groups_pronoun_each",
            re.compile(
                rf"\b[A-Z][a-z]+ has (?P<groups>{number}) (?P<group_phrase>[^.]+)\. "
                rf"(?:He|She|They) has (?P<size>{number}) [^.]+ (?:in|on) each "
                rf"(?P<each_noun>[A-Za-z]+)\b",
                re.IGNORECASE,
            ),
        ),
        (
            "equal_groups_each_has",
            re.compile(
                rf"\b(?:There are |[A-Z][a-z]+ has )(?P<groups>{number}) "
                rf"(?P<group_phrase>[^.]+)\. Each (?P<each_noun>[A-Za-z]+) "
                rf"has (?P<size>{number})\b",
                re.IGNORECASE,
            ),
        ),
        (
            "equal_groups_each_contains",
            re.compile(
                rf"\bThere are (?P<groups>{number}) (?P<group_phrase>[^.]+)\. "
                rf"(?P<size>{number}) [^.]+ (?:are|is) (?:in|on) each "
                rf"(?P<each_noun>[A-Za-z]+)\b",
                re.IGNORECASE,
            ),
        ),
    ]
    candidates = set()
    for span in spans:
        for line, end_line, position, text in _task_chunks(span):
            direct_binary = direct_binary_prompt.fullmatch(text)
            if direct_binary:
                operation, task_name = direct_operations[direct_binary.group("symbol")]
                has_route = any(
                    attached_operation == operation
                    for attached_operation, _ in attachments.get(span.code, set())
                )
                candidates.add(
                    TaskCandidate(
                        span.code,
                        f"{task_name}({_arithmetic_number(direct_binary.group('a'))}, "
                        f"{_arithmetic_number(direct_binary.group('b'))})",
                        operation,
                        "direct_binary_expression_prompt",
                        span.source,
                        line,
                        end_line,
                        position,
                        direct_binary.group("excerpt"),
                        "reviewable" if has_route else "rejected",
                        "exact_standalone_binary_expression_and_operation_route"
                        if has_route
                        else f"lesson_has_no_{operation}_attachment",
                    )
                )
            for parser_id, operation, task, excerpt in _narrative_quantity_specs(text):
                has_route = any(
                    attached_operation == operation
                    for attached_operation, _ in attachments.get(span.code, set())
                )
                candidates.add(
                    TaskCandidate(
                        span.code,
                        task,
                        operation,
                        parser_id,
                        span.source,
                        line,
                        end_line,
                        position,
                        excerpt,
                        "reviewable" if has_route else "rejected",
                        "exact_binary_narrative_operands_referents_and_operation_route"
                        if has_route
                        else f"lesson_has_no_{operation}_attachment",
                    )
                )
            for parser_id, pattern in patterns:
                match = pattern.search(text)
                if not match:
                    continue
                groups = _number(match.group("groups"))
                size = _number(match.group("size"))
                counted_referent = _counted_referent(match.group("group_phrase"))
                each_referent = _singular(match.group("each_noun"))
                referents_agree = counted_referent == each_referent
                has_route = any(
                    operation == "multiplication"
                    for operation, _ in attachments.get(span.code, set())
                )
                reviewable = referents_agree and has_route
                candidates.add(
                    TaskCandidate(
                        span.code,
                        f"multiply({groups}, {size})",
                        "multiplication",
                        parser_id,
                        span.source,
                        line,
                        end_line,
                        position,
                        match.group(0),
                        "reviewable" if reviewable else "rejected",
                        "exact_operands_referent_and_operation_route"
                        if reviewable
                        else (
                            "counted_group_does_not_match_each_group"
                            if not referents_agree
                            else "lesson_has_no_multiplication_attachment"
                        ),
                    )
                )
            grouping = re.search(
                rf"\bThere are (?P<total>{number}) [^.]+\. Each "
                rf"(?P<group_noun>[A-Za-z]+) has (?P<size>{number}) [^.]*\. "
                rf"How many (?P<question_group>[A-Za-z]+)\b",
                text,
                re.IGNORECASE,
            )
            if grouping:
                group_agrees = _singular(grouping.group("group_noun")) == _singular(
                    grouping.group("question_group")
                )
                has_route = any(
                    operation == "division"
                    for operation, _ in attachments.get(span.code, set())
                )
                reviewable = group_agrees and has_route
                candidates.add(
                    TaskCandidate(
                        span.code,
                        f"divide({_number(grouping.group('total'))}, "
                        f"{_number(grouping.group('size'))})",
                        "division",
                        "measurement_division_each_group_has",
                        span.source,
                        line,
                        end_line,
                        position,
                        grouping.group(0),
                        "reviewable" if reviewable else "rejected",
                        "exact_operands_referent_and_operation_route"
                        if reviewable
                        else (
                            "question_referent_does_not_match_group"
                            if not group_agrees
                            else "lesson_has_no_division_attachment"
                        ),
                    )
                )
            sharing = re.search(
                rf"\b[A-Z][a-z]+ has (?P<total>{number}) [^.]+\. "
                rf"(?:He|She|They) has (?P<groups>{number}) (?P<group_noun>[A-Za-z]+) "
                rf"and wants to put the same number [^.]+ in each "
                rf"(?P<each_noun>[A-Za-z]+)\b",
                text,
                re.IGNORECASE,
            )
            if sharing:
                group_agrees = _singular(sharing.group("group_noun")) == _singular(
                    sharing.group("each_noun")
                )
                has_route = any(
                    operation == "division"
                    for operation, _ in attachments.get(span.code, set())
                )
                reviewable = group_agrees and has_route
                candidates.add(
                    TaskCandidate(
                        span.code,
                        f"divide({_number(sharing.group('total'))}, "
                        f"{_number(sharing.group('groups'))})",
                        "division",
                        "partitive_division_same_number_each",
                        span.source,
                        line,
                        end_line,
                        position,
                        sharing.group(0),
                        "reviewable" if reviewable else "rejected",
                        "exact_operands_referent_and_operation_route"
                        if reviewable
                        else (
                            "each_referent_does_not_match_group"
                            if not group_agrees
                            else "lesson_has_no_division_attachment"
                        ),
                    )
                )
            direct_perimeter = re.search(
                r"\b(?:a )?(?:rectangle(?: with side lengths? of)?|rectangular [A-Za-z]+ (?:is|measures)) "
                r"(?P<length>\d+) (?P<unit1>yards?|feet|inches?|centimeters?|meters?|units?) "
                r"by (?P<width>\d+) (?P<unit2>yards?|feet|inches?|centimeters?|meters?|units?)"
                r"[^?]{0,180}(?:perimeter|fencing[^?]*fence)[^?]*\?",
                text,
                re.IGNORECASE,
            )
            if direct_perimeter:
                unit1 = _singular(direct_perimeter.group("unit1"))
                unit2 = _singular(direct_perimeter.group("unit2"))
                unit_agrees = unit1 == unit2
                has_route = any(
                    operation == "geometry"
                    for operation, _ in attachments.get(span.code, set())
                )
                candidates.add(
                    TaskCandidate(
                        span.code,
                        f"rectangle_perimeter({int(direct_perimeter.group('length'))}, "
                        f"{int(direct_perimeter.group('width'))}, {unit1})",
                        "geometry",
                        "rectangle_dimensions_perimeter",
                        span.source,
                        line,
                        end_line,
                        position,
                        direct_perimeter.group(0),
                        "reviewable" if unit_agrees and has_route else "rejected",
                        "exact_rectangle_dimensions_unit_and_perimeter_question"
                        if unit_agrees and has_route
                        else (
                            "rectangle_dimension_units_do_not_agree"
                            if not unit_agrees
                            else "lesson_has_no_geometry_attachment"
                        ),
                    )
                )
            prism_volume = re.search(
                r"\b(?:[A-Z][a-z]+(?:'s)? )?(?:[A-Za-z]+ )*(?:container|box|prism) "
                r"(?:is|measures) (?P<width>\d+) "
                r"(?P<unit1>yards?|feet|inches?|centimeters?|meters?|units?) wide, "
                r"(?P<length>\d+) "
                r"(?P<unit2>yards?|feet|inches?|centimeters?|meters?|units?) long, "
                r"and (?P<height>\d+) "
                r"(?P<unit3>yards?|feet|inches?|centimeters?|meters?|units?) high\. "
                r"What is the volume",
                text,
                re.IGNORECASE,
            )
            if prism_volume:
                units = {
                    _singular(prism_volume.group("unit1")),
                    _singular(prism_volume.group("unit2")),
                    _singular(prism_volume.group("unit3")),
                }
                units_agree = len(units) == 1
                unit = next(iter(units))
                has_route = any(
                    operation == "geometry"
                    for operation, _ in attachments.get(span.code, set())
                )
                candidates.add(
                    TaskCandidate(
                        span.code,
                        f"unit_cube_volume({int(prism_volume.group('length'))}, "
                        f"{int(prism_volume.group('width'))}, "
                        f"{int(prism_volume.group('height'))}, {unit})",
                        "geometry",
                        "rectangular_prism_dimensions_volume",
                        span.source,
                        line,
                        end_line,
                        position,
                        prism_volume.group(0),
                        "reviewable" if units_agree and has_route else "rejected",
                        "exact_prism_dimensions_unit_and_volume_question"
                        if units_agree and has_route
                        else (
                            "prism_dimension_units_do_not_agree"
                            if not units_agree
                            else "lesson_has_no_geometry_attachment"
                        ),
                    )
                )
            ordered_prism_volume = re.search(
                r"\b(?:if the |a |the )?(?:[A-Za-z]+ )*"
                r"(?:container|box|prism|wagon(?: bed)?)"
                r"(?: for (?:a|the) [A-Za-z]+)? "
                r"(?:is(?: approximately)?|measures) (?P<length>\d+) "
                r"(?P<unit1>yards?|feet|inches?|centimeters?|meters?|units?) long, "
                r"(?P<width>\d+) "
                r"(?P<unit2>yards?|feet|inches?|centimeters?|meters?|units?) wide, "
                r"and (?P<height>\d+) "
                r"(?P<unit3>yards?|feet|inches?|centimeters?|meters?|units?) "
                r"(?:high|tall|deep)[^?]{0,220}what is (?:the )?volume",
                text,
                re.IGNORECASE,
            )
            if ordered_prism_volume:
                units = {
                    _singular(ordered_prism_volume.group("unit1")),
                    _singular(ordered_prism_volume.group("unit2")),
                    _singular(ordered_prism_volume.group("unit3")),
                }
                units_agree = len(units) == 1
                unit = next(iter(units))
                has_route = any(
                    operation == "geometry"
                    for operation, _ in attachments.get(span.code, set())
                )
                candidates.add(
                    TaskCandidate(
                        span.code,
                        f"unit_cube_volume("
                        f"{int(ordered_prism_volume.group('length'))}, "
                        f"{int(ordered_prism_volume.group('width'))}, "
                        f"{int(ordered_prism_volume.group('height'))}, {unit})",
                        "geometry",
                        "ordered_prism_dimensions_volume",
                        span.source,
                        line,
                        end_line,
                        position,
                        ordered_prism_volume.group(0),
                        "reviewable" if units_agree and has_route else "rejected",
                        "exact_ordered_prism_dimensions_unit_and_volume_question"
                        if units_agree and has_route
                        else (
                            "prism_dimension_units_do_not_agree"
                            if not units_agree
                            else "lesson_has_no_geometry_attachment"
                        ),
                    )
                )
            rectangle_area_comparison = re.search(
                r"\bThe (?P<label1>[A-Za-z]+) fabric is (?P<length1>\d+) "
                r"(?P<unit1>yards?|feet|inches?|centimeters?|meters?) by "
                r"(?P<width1>\d+) (?P<unit2>yards?|feet|inches?|centimeters?|meters?)\. "
                r"The (?P<label2>[A-Za-z]+) fabric is (?P<length2>\d+) "
                r"(?P<unit3>yards?|feet|inches?|centimeters?|meters?) by "
                r"(?P<width2>\d+) (?P<unit4>yards?|feet|inches?|centimeters?|meters?)\. "
                r"Which piece of fabric has a larger area",
                text,
                re.IGNORECASE,
            )
            if rectangle_area_comparison:
                units = {
                    _singular(rectangle_area_comparison.group(name))
                    for name in ("unit1", "unit2", "unit3", "unit4")
                }
                units_agree = len(units) == 1
                unit = next(iter(units))
                has_route = any(
                    operation == "geometry"
                    for operation, _ in attachments.get(span.code, set())
                )
                candidates.add(
                    TaskCandidate(
                        span.code,
                        f"compare_rectangle_areas("
                        f"{int(rectangle_area_comparison.group('length1'))}, "
                        f"{int(rectangle_area_comparison.group('width1'))}, "
                        f"{int(rectangle_area_comparison.group('length2'))}, "
                        f"{int(rectangle_area_comparison.group('width2'))}, {unit})",
                        "geometry",
                        "two_rectangle_dimensions_area_comparison",
                        span.source,
                        line,
                        end_line,
                        position,
                        rectangle_area_comparison.group(0),
                        "reviewable" if units_agree and has_route else "rejected",
                        "exact_two_rectangle_dimensions_common_unit_and_area_question"
                        if units_agree and has_route
                        else (
                            "rectangle_dimension_units_do_not_agree"
                            if not units_agree
                            else "lesson_has_no_geometry_attachment"
                        ),
                    )
                )
            missing_side_area = re.search(
                r"\b(?:uses|used) (?P<area>\d+) square (?:tiles|sticky notes)"
                r"[^?]{0,260}?(?P<known>\d+) (?:tiles|square notes) "
                r"(?:wide|to cover the width)[^?]{0,180}?How many "
                r"(?:tiles|square notes)[^?]{0,60}?(?:long|height)",
                text,
                re.IGNORECASE,
            )
            if missing_side_area:
                area = int(missing_side_area.group("area"))
                known = int(missing_side_area.group("known"))
                divisible = area % known == 0
                has_route = any(
                    operation == "geometry"
                    for operation, _ in attachments.get(span.code, set())
                )
                candidates.add(
                    TaskCandidate(
                        span.code,
                        f"rectangle_missing_side_from_area({area}, {known}, tile)",
                        "geometry",
                        "rectangle_area_known_width_missing_length",
                        span.source,
                        line,
                        end_line,
                        position,
                        missing_side_area.group(0),
                        "reviewable" if divisible and has_route else "rejected",
                        "exact_area_known_side_exact_division_and_rectangle_route"
                        if divisible and has_route
                        else (
                            "area_not_divisible_by_known_side"
                            if not divisible
                            else "lesson_has_no_geometry_attachment"
                        ),
                    )
                )
            direct_conversion = re.search(
                rf"\b(?P<count>{number}) "
                r"(?P<from>kilometers?|meters?|kilograms?|liters?|pounds?|hours?)\b"
                r"[^?]{0,180}?What is (?:that|the) "
                r"(?:length|weight|volume|time|measurement) in "
                r"(?P<to>meters?|centimeters?|grams?|milliliters?|ounces?|minutes?)\?",
                text,
                re.IGNORECASE,
            )
            if direct_conversion:
                count = _number(direct_conversion.group("count"))
                from_unit = _singular(direct_conversion.group("from"))
                to_unit = _singular(direct_conversion.group("to"))
                factor = CONVERSION_FACTORS.get((from_unit, to_unit))
                has_route = any(
                    operation == "measurement"
                    for operation, _ in attachments.get(span.code, set())
                )
                reviewable = factor is not None and has_route
                task = (
                    f"convert_measurement({count}, {from_unit}, {to_unit}, {factor})"
                    if factor is not None
                    else f"unsupported_conversion({count}, {from_unit}, {to_unit})"
                )
                candidates.add(
                    TaskCandidate(
                        span.code,
                        task,
                        "measurement",
                        "direct_larger_to_smaller_unit_conversion",
                        span.source,
                        line,
                        end_line,
                        position,
                        direct_conversion.group(0),
                        "reviewable" if reviewable else "rejected",
                        "exact_quantity_units_factor_and_operation_route"
                        if reviewable
                        else (
                            "conversion_direction_or_factor_not_registered"
                            if factor is None
                            else "lesson_has_no_measurement_attachment"
                        ),
                    )
                )
            direct_decimal_comparison = re.search(
                r"\bcompare (?P<left>\d+\.\d+) and "
                r"(?P<right>\d+\.\d+)\b",
                text,
                re.IGNORECASE,
            )
            if direct_decimal_comparison:
                n1, s1 = _decimal_parts(direct_decimal_comparison.group("left"))
                n2, s2 = _decimal_parts(direct_decimal_comparison.group("right"))
                has_route = any(
                    operation == "decimal"
                    for operation, _ in attachments.get(span.code, set())
                )
                candidates.add(
                    TaskCandidate(
                        span.code,
                        f"decimal_compare({n1}, {s1}, {n2}, {s2})",
                        "decimal",
                        "direct_decimal_numeral_comparison",
                        span.source,
                        line,
                        end_line,
                        position,
                        direct_decimal_comparison.group(0),
                        "reviewable" if has_route else "rejected",
                        "exact_decimal_numerals_scales_and_operation_route"
                        if has_route
                        else "lesson_has_no_decimal_attachment",
                    )
                )
            for weight_index, weight_match in enumerate(
                re.finditer(
                    r"(?P<count>\d+) of the (?P<unit>0\.0*1)-ounce weights",
                    text,
                    re.IGNORECASE,
                ),
                1,
            ):
                unit_numeral, unit_scale = _decimal_parts(
                    weight_match.group("unit")
                )
                has_route = any(
                    operation == "decimal"
                    for operation, _ in attachments.get(span.code, set())
                )
                excerpt = weight_match.group(0)
                source_line = next(
                    (
                        source_line
                        for source_line, source_text in span.lines
                        if excerpt.lower() in source_text.lower()
                    ),
                    line,
                )
                reviewable = unit_numeral == 1 and has_route
                candidates.add(
                    TaskCandidate(
                        span.code,
                        f"decimal_value({int(weight_match.group('count'))}, "
                        f"{unit_scale})",
                        "decimal",
                        "decimal_unit_weight_count_inscription",
                        span.source,
                        source_line,
                        source_line,
                        f"{position}/decimal_weight({weight_index})",
                        excerpt,
                        "reviewable" if reviewable else "rejected",
                        "exact_unit_fraction_count_scale_and_operation_route"
                        if reviewable
                        else (
                            "decimal_weight_is_not_a_unit_fraction"
                            if unit_numeral != 1
                            else "lesson_has_no_decimal_attachment"
                        ),
                    )
                )
            direct_place_value_comparison = re.search(
                rf"\bCompare (?P<left>{number}) and (?P<right>{number})\b",
                text,
                re.IGNORECASE,
            )
            if direct_place_value_comparison:
                left = _number(direct_place_value_comparison.group("left"))
                right = _number(direct_place_value_comparison.group("right"))
                has_route = any(
                    operation == "counting"
                    for operation, _ in attachments.get(span.code, set())
                )
                candidates.add(
                    TaskCandidate(
                        span.code,
                        f"compare_numerals_by_place_value({left}, {right}, 10)",
                        "counting",
                        "direct_place_value_numeral_comparison",
                        span.source,
                        line,
                        end_line,
                        position,
                        direct_place_value_comparison.group(0),
                        "reviewable" if has_route else "rejected",
                        "exact_numerals_base_and_operation_route"
                        if has_route
                        else "lesson_has_no_counting_attachment",
                    )
                )
            fixed_perimeter = re.search(
                r"\bRectangle [A-Z] has a perimeter of (?P<perimeter>\d+) "
                r"(?P<unit>yards?|feet|inches?|centimeters?|meters?|units?)\. "
                r"(?:Name|Give|Record)[^?.]{0,100}(?:pair|possible)[^?.]{0,100}side lengths?",
                text,
                re.IGNORECASE,
            )
            if fixed_perimeter:
                has_route = any(
                    operation == "geometry"
                    for operation, _ in attachments.get(span.code, set())
                )
                unit = _singular(fixed_perimeter.group("unit"))
                candidates.add(
                    TaskCandidate(
                        span.code,
                        f"construct_rectangle_with_perimeter("
                        f"{int(fixed_perimeter.group('perimeter'))}, {unit})",
                        "geometry",
                        "rectangle_fixed_perimeter_side_pairs",
                        span.source,
                        line,
                        end_line,
                        position,
                        fixed_perimeter.group(0),
                        "reviewable" if has_route else "rejected",
                        "exact_perimeter_unit_and_side_pair_question"
                        if has_route
                        else "lesson_has_no_geometry_attachment",
                    )
                )
            missing_side = re.search(
                r"\bRectangle [A-Z] has a perimeter of (?P<perimeter>\d+) "
                r"(?P<unit1>yards?|feet|inches?|centimeters?|meters?|units?)[^.]*\."
                r"[^?]{0,220}?(?:length|width)[^?]{0,50}?(?P<known>\d+)\b "
                r"(?P<unit2>yards?|feet|inches?|centimeters?|meters?|units?)"
                r"[^?]{0,100}(?:width|length)[^?]*\?",
                text,
                re.IGNORECASE,
            )
            if missing_side:
                unit1 = _singular(missing_side.group("unit1"))
                unit2 = _singular(missing_side.group("unit2"))
                unit_agrees = unit1 == unit2
                has_route = any(
                    operation == "geometry"
                    for operation, _ in attachments.get(span.code, set())
                )
                candidates.add(
                    TaskCandidate(
                        span.code,
                        f"rectangle_missing_side_from_perimeter("
                        f"{int(missing_side.group('perimeter'))}, "
                        f"{int(missing_side.group('known'))}, {unit1})",
                        "geometry",
                        "rectangle_missing_side_from_perimeter",
                        span.source,
                        line,
                        end_line,
                        position,
                        missing_side.group(0),
                        "reviewable" if unit_agrees and has_route else "rejected",
                        "exact_perimeter_known_side_unit_and_unknown_question"
                        if unit_agrees and has_route
                        else (
                            "perimeter_and_side_units_do_not_agree"
                            if not unit_agrees
                            else "lesson_has_no_geometry_attachment"
                        ),
                    )
                )
            rectangular_missing_side = re.search(
                r"\bA rectangular [A-Za-z ]+ has a fence that measures "
                r"(?P<perimeter>\d+) (?P<unit1>yards?|feet|inches?|centimeters?|meters?|units?) around\. "
                r"One side[^.]{0,80}measures (?P<known>\d+) "
                r"(?P<unit2>yards?|feet|inches?|centimeters?|meters?|units?)\. "
                r"What are the lengths? of the other sides?\?",
                text,
                re.IGNORECASE,
            )
            if rectangular_missing_side:
                unit1 = _singular(rectangular_missing_side.group("unit1"))
                unit2 = _singular(rectangular_missing_side.group("unit2"))
                unit_agrees = unit1 == unit2
                has_route = any(
                    operation == "geometry"
                    for operation, _ in attachments.get(span.code, set())
                )
                candidates.add(
                    TaskCandidate(
                        span.code,
                        f"rectangle_missing_side_from_perimeter("
                        f"{int(rectangular_missing_side.group('perimeter'))}, "
                        f"{int(rectangular_missing_side.group('known'))}, {unit1})",
                        "geometry",
                        "rectangle_missing_side_from_perimeter",
                        span.source,
                        line,
                        end_line,
                        position,
                        rectangular_missing_side.group(0),
                        "reviewable" if unit_agrees and has_route else "rejected",
                        "exact_rectangular_referent_perimeter_known_side_and_unit"
                        if unit_agrees and has_route
                        else (
                            "perimeter_and_side_units_do_not_agree"
                            if not unit_agrees
                            else "lesson_has_no_geometry_attachment"
                        ),
                    )
                )
            grade_match = CODE_RE.fullmatch(span.code)
            grade = grade_match.group(1) if grade_match else ""
            operands = _whole_numbers_in_text(text)
            if grade in {"1", "2"} and len(operands) == 2:
                left, right = operands
                lowered = text.lower()
                join_result_unknown = (
                    re.search(r"how many[^?.]{0,100}(?:in all|altogether)\?", lowered)
                    and not re.search(
                        r"\beach\b|\btimes\b|equal groups|\babout\b|estimat",
                        lowered,
                    )
                )
                spaced_all_together_join_result_unknown = (
                    re.fullmatch(
                        r".*\bhow many[^?.]{0,100}\ball together\?"
                        r"(?:\s+show your thinking using drawings, numbers, or words\.)?",
                        lowered,
                    )
                    and not re.search(
                        r"\beach\b|\btimes\b|equal groups|\babout\b|estimat",
                        lowered,
                    )
                )
                comparison_question = bool(
                    re.search(r"how many (?:more|fewer)[^?]*\?", lowered)
                )
                add_to_change_unknown = bool(
                    comparison_question
                    and re.search(
                        r"(?:gets?|puts?) (?:some )?more|then some more|more [a-z ]+ (?:swim|come|arrive)",
                        lowered,
                    )
                )
                compare_difference_unknown = comparison_question and not add_to_change_unknown
                take_from_result_unknown = bool(
                    re.search(
                        r"(?:takes? out|gives? \d|cuts? off|\d+ left(?: to| the)|left the)",
                        lowered,
                    )
                    and re.search(r"how many[^?]*(?:left|still|now)[^?]*\?", lowered)
                )
                story_specs = []
                if join_result_unknown:
                    story_specs.append(
                        ("story_join_result_unknown", "addition", f"add({left}, {right})")
                    )
                if spaced_all_together_join_result_unknown:
                    story_specs.append(
                        (
                            "story_spaced_all_together_join_result_unknown",
                            "addition",
                            f"add({left}, {right})",
                        )
                    )
                if compare_difference_unknown:
                    larger, smaller = max(operands), min(operands)
                    story_specs.append(
                        (
                            "story_compare_difference_unknown",
                            "subtraction",
                            f"subtract({larger}, {smaller})",
                        )
                    )
                if add_to_change_unknown:
                    larger, smaller = max(operands), min(operands)
                    story_specs.append(
                        (
                            "story_add_to_change_unknown",
                            "subtraction",
                            f"subtract({larger}, {smaller})",
                        )
                    )
                if take_from_result_unknown:
                    story_specs.append(
                        (
                            "story_take_from_result_unknown",
                            "subtraction",
                            f"subtract({left}, {right})",
                        )
                    )
                for parser_id, operation, task in story_specs:
                    has_route = any(
                        attached_operation == operation
                        for attached_operation, _ in attachments.get(span.code, set())
                    )
                    candidates.add(
                        TaskCandidate(
                            span.code,
                            task,
                            operation,
                            parser_id,
                            span.source,
                            line,
                            end_line,
                            position,
                            _through_how_many_question(text),
                            "reviewable" if has_route else "rejected",
                            "exact_story_operands_question_and_operation_route"
                            if has_route
                            else f"lesson_has_no_{operation}_attachment",
                        )
                    )
        equation_list_prompt = re.search(
            r"\bFind (?:the unknown value|the number that makes each equation true|"
            r"the value of each sum)\b",
            span.text,
            re.IGNORECASE,
        )
        if equation_list_prompt:
            # The guide export omits the printed box.  An anchored line can
            # still distinguish a completed-result blank from a missing
            # addend: the latter is an inverse subtraction task.
            equation_lines = span.lines
            if span.recovered and re.search(
                r"\bFind the number that makes each equation true\b",
                span.text,
                re.IGNORECASE,
            ) and RECOVERED_COMPLETE_EQUATION_RE.search(span.text):
                equation_lines = tuple(
                    (0, unit) for unit in _recovered_printed_equation_units(span)
                )
            for equation_number, (line, text) in enumerate(equation_lines, 1):
                equation = re.sub(r"^(?:•|\d+\.)\s*", "", text.strip())
                equation = re.sub(r"^[a-z]\.?\s*", "", equation)
                for parser_id, operation, task in _printed_equation_items(equation):
                    has_route = any(
                        attached_operation == operation
                        for attached_operation, _ in attachments.get(span.code, set())
                    )
                    position = (
                        f"{span.position}/recovered_equation({equation_number})"
                        if span.recovered
                        else f"{span.position}/printed_equation({line})"
                    )
                    candidates.add(
                        TaskCandidate(
                            span.code,
                            task,
                            operation,
                            parser_id,
                            span.source,
                            line,
                            line,
                            position,
                            text.strip(),
                            "reviewable" if has_route else "rejected",
                            "exact_two_known_operand_equation_with_blank_result"
                            if has_route
                            and parser_id
                            != "printed_equation_list_missing_addend"
                            else (
                                "exact_total_known_addend_equation_with_blank_addend"
                                if has_route
                                else f"lesson_has_no_{operation}_attachment"
                            ),
                        )
                    )
        # Recovered text has no physical line breaks: its printed equations are
        # contiguous text where the markdown parser would otherwise see one
        # unmatchable line.  These are the same three printed-equation shapes
        # above, identified after sidecar-only segmentation.
        for equation_number, (parser_id, operation, task, excerpt) in enumerate(
            _recovered_equation_items(span), 1
        ):
            has_route = any(
                attached_operation == operation
                for attached_operation, _ in attachments.get(span.code, set())
            )
            candidates.add(
                TaskCandidate(
                    span.code,
                    task,
                    operation,
                    parser_id,
                    span.source,
                    0,
                    0,
                    f"{span.position}/recovered_equation({equation_number})",
                    excerpt,
                    "reviewable" if has_route else "rejected",
                    "exact_recovered_binary_equation_and_operation_route"
                    if has_route
                    else f"lesson_has_no_{operation}_attachment",
                )
            )
        if re.search(
            r"\bFind the value of each (?:expression|sum|difference|product|quotient)\b",
            span.text,
            re.IGNORECASE,
        ):
            expression_number = 0
            for line, text in span.lines:
                for match in re.finditer(
                    rf"(?<![\d.,])({ARITHMETIC_NUMERAL})\s*\+\s*({ARITHMETIC_NUMERAL})(?![\d.,])",
                    text,
                ):
                    expression_number += 1
                    has_route = any(
                        operation == "addition"
                        for operation, _ in attachments.get(span.code, set())
                    )
                    candidates.add(
                        TaskCandidate(
                            span.code,
                            f"add({_arithmetic_number(match.group(1))}, "
                            f"{_arithmetic_number(match.group(2))})",
                            "addition",
                            "direct_addition_expression_list",
                            span.source,
                            line,
                            line,
                            f"{span.position}/expression({expression_number})",
                            match.group(0),
                            "reviewable" if has_route else "rejected",
                            "exact_operands_and_operation_route"
                            if has_route
                            else "lesson_has_no_addition_attachment",
                        )
                    )
        # Fraction task lane: the same list-prompt idiom, read over printed
        # fraction addends.  An operand whose numerator admits a flattened
        # mixed-number split is refused by _fraction_operand_term rather
        # than promoted under either reading.  A pair with no fraction side
        # belongs to the whole-number lane and is skipped here.
        if re.search(
            r"\bFind the value of each (?:expression|sum|difference)\b",
            span.text,
            re.IGNORECASE,
        ):
            fraction_expression_number = 0
            for line, text in span.lines:
                for match in FRACTION_EXPRESSION_RE.finditer(text):
                    if "/" not in match.group("left") and "/" not in match.group("right"):
                        continue
                    left = _fraction_operand_term(match.group("left"))
                    right = _fraction_operand_term(match.group("right"))
                    if left is None or right is None:
                        continue
                    left_term, left_value = left
                    right_term, right_value = right
                    if match.group("symbol") == "+":
                        parser_id = "direct_fraction_addition_expression_list"
                        task = f"add_fractions({left_term}, {right_term})"
                        route_operations = {"fraction", "addition"}
                    else:
                        # The registered subtraction machine's domain is the
                        # nonnegative differences the K--5 guides print; a
                        # pair below that domain would compile to a fact no
                        # automaton can execute.
                        if left_value < right_value:
                            continue
                        parser_id = "direct_fraction_subtraction_expression_list"
                        task = f"subtract_fractions({left_term}, {right_term})"
                        route_operations = {"fraction", "subtraction"}
                    fraction_expression_number += 1
                    has_route = any(
                        attached_operation in route_operations
                        for attached_operation, _ in attachments.get(span.code, set())
                    )
                    candidates.add(
                        TaskCandidate(
                            span.code,
                            task,
                            "fraction",
                            parser_id,
                            span.source,
                            line,
                            line,
                            f"{span.position}/fraction_expression({fraction_expression_number})",
                            text[match.start("left"):match.end("right")],
                            "reviewable" if has_route else "rejected",
                            "exact_fraction_operands_and_operation_route"
                            if has_route
                            else "lesson_has_no_fraction_attachment",
                        )
                    )
        # A bullet item is deliberately required here.  It keeps a binary
        # expression distinct from a subexpression inside a longer chain, so
        # the emitted operands remain exactly the task the guide prints.
        if re.search(
            r"\bFind the value of each (?:expression|difference|sum|product|quotient) mentally\b",
            span.text,
            re.IGNORECASE,
        ):
            for parser_id, operation, symbol, task_name in (
                (
                    "direct_subtraction_expression_list",
                    "subtraction",
                    r"-",
                    "subtract",
                ),
                (
                    "direct_multiplication_expression_list",
                    "multiplication",
                    r"[×·]",
                    "multiply",
                ),
                (
                    "direct_division_expression_list",
                    "division",
                    r"÷",
                    "divide",
                ),
            ):
                expression_number = 0
                pattern = re.compile(
                    rf"\s*(?P<a>{ARITHMETIC_NUMERAL})\s*{symbol}\s*(?P<b>{ARITHMETIC_NUMERAL})\s*"
                )
                for line, text in span.lines:
                    for item in text.split("•")[1:]:
                        match = pattern.fullmatch(item)
                        if not match:
                            continue
                        expression_number += 1
                        has_route = any(
                            attached_operation == operation
                            for attached_operation, _ in attachments.get(span.code, set())
                        )
                        candidates.add(
                            TaskCandidate(
                                span.code,
                                f"{task_name}({_arithmetic_number(match.group('a'))}, "
                                f"{_arithmetic_number(match.group('b'))})",
                                operation,
                                parser_id,
                                span.source,
                                line,
                                line,
                                f"{span.position}/expression({expression_number})",
                                match.group(0).strip(),
                                "reviewable" if has_route else "rejected",
                                "exact_standalone_binary_expression_and_operation_route"
                                if has_route
                                else f"lesson_has_no_{operation}_attachment",
                            )
                        )
        # The non-"mentally" spelling is a distinct measured shape.  Segment
        # first, then accept only a complete binary unit.  Choice banks,
        # equation-building banks, relational claims, and longer expressions
        # may segment into units but cannot enter this computation route because
        # their prompts and fullmatch shapes differ.
        if re.search(
            r"\bFind the value of each (?:expression|difference|sum|product|quotient)\b",
            span.text,
            re.IGNORECASE,
        ) and not re.search(r"\bmentally\b", span.text, re.IGNORECASE):
            direct_patterns = (
                (
                    "segmented_direct_subtraction_expression_list",
                    "subtraction",
                    "subtract",
                    re.compile(
                        rf"(?P<a>{ARITHMETIC_NUMERAL})\s*[-−]\s*"
                        rf"(?P<b>{ARITHMETIC_NUMERAL})"
                    ),
                ),
            )
            for line, end_line, position, unit in _compound_expression_units(span):
                for parser_id, operation, task_name, pattern in direct_patterns:
                    match = pattern.fullmatch(unit)
                    if match is None:
                        continue
                    left = _arithmetic_number(match.group("a"))
                    right = _arithmetic_number(match.group("b"))
                    if operation == "subtraction" and left < right:
                        continue
                    has_route = any(
                        attached_operation == operation
                        for attached_operation, _ in attachments.get(span.code, set())
                    )
                    candidates.add(
                        TaskCandidate(
                            span.code,
                            f"{task_name}({left}, {right})",
                            operation,
                            parser_id,
                            span.source,
                            line,
                            end_line,
                            position,
                            unit,
                            "reviewable" if has_route else "rejected",
                            "exact_segmented_binary_expression_and_operation_route"
                            if has_route
                            else f"lesson_has_no_{operation}_attachment",
                        )
                    )
    return sorted(candidates)


TASK_GRAMMAR_ACTIONS = {
    "direct_binary_expression_prompt": {
        "addition": "count_on_from_larger",
        "subtraction": "take_away_base_ones",
        "multiplication": "repeat_equal_groups",
        "division": "measure_groups_of_size",
    },
    "direct_addition_expression_list": ("addition", "count_on_from_larger"),
    "direct_subtraction_expression_list": ("subtraction", "take_away_base_ones"),
    "direct_fraction_addition_expression_list": (
        "fraction",
        "common_denominator_fraction_addition",
    ),
    "direct_fraction_subtraction_expression_list": (
        "fraction",
        "common_denominator_fraction_subtraction",
    ),
    "printed_equation_list_direct_addition": ("addition", "count_on_from_larger"),
    "printed_equation_list_direct_subtraction": (
        "subtraction",
        "take_away_base_ones",
    ),
    "printed_equation_list_missing_addend": (
        "subtraction",
        "count_up_missing_addend",
    ),
    "direct_multiplication_expression_list": ("multiplication", "repeat_equal_groups"),
    "direct_division_expression_list": ("division", "measure_groups_of_size"),
    "segmented_direct_subtraction_expression_list": (
        "subtraction",
        "take_away_base_ones",
    ),
    "witnessed_true_false_equation_side": {
        "addition": "count_on_from_larger",
        "subtraction": "take_away_base_ones",
        "multiplication": "repeat_equal_groups",
        "division": "measure_groups_of_size",
    },
    "equal_groups_pronoun_each": ("multiplication", "repeat_equal_groups"),
    "equal_groups_each_has": ("multiplication", "repeat_equal_groups"),
    "equal_groups_each_contains": ("multiplication", "repeat_equal_groups"),
    "measurement_division_each_group_has": ("division", "measure_groups_of_size"),
    "partitive_division_same_number_each": ("division", "fair_share_equal_groups"),
    "story_add_to_change_unknown": ("subtraction", "count_up_missing_addend"),
    "story_compare_difference_unknown": (
        "subtraction",
        "compare_by_matching_difference",
    ),
    "story_join_result_unknown": ("addition", "count_on_from_larger"),
    "story_spaced_all_together_join_result_unknown": (
        "addition",
        "count_on_from_larger",
    ),
    "story_take_from_result_unknown": ("subtraction", "take_away_base_ones"),
    "narrative_join_more_result_unknown": ("addition", "count_on_from_larger"),
    "narrative_two_actor_combine_result_unknown": (
        "addition",
        "count_on_from_larger",
    ),
    "narrative_same_unit_combine_result_unknown": (
        "addition",
        "count_on_from_larger",
    ),
    "narrative_take_from_result_unknown": (
        "subtraction",
        "take_away_base_ones",
    ),
    "narrative_add_to_change_unknown": (
        "subtraction",
        "count_up_missing_addend",
    ),
    "narrative_total_known_part_missing_part": (
        "subtraction",
        "count_up_missing_addend",
    ),
    "narrative_equal_groups_total_unknown": (
        "multiplication",
        "repeat_equal_groups",
    ),
    "narrative_rate_total_unknown": (
        "multiplication",
        "repeat_equal_groups",
    ),
    "narrative_measurement_division_groups_unknown": (
        "division",
        "measure_groups_of_size",
    ),
    "narrative_partitive_division_share_unknown": (
        "division",
        "fair_share_equal_groups",
    ),
    "rectangle_dimensions_perimeter": (
        "geometry",
        "rectangle_perimeter_boundary_traversal",
    ),
    "rectangle_fixed_perimeter_side_pairs": (
        "geometry",
        "rectangle_perimeter_side_pair_search",
    ),
    "rectangle_missing_side_from_perimeter": (
        "geometry",
        "rectangle_missing_side_from_perimeter",
    ),
    "rectangular_prism_dimensions_volume": (
        "geometry",
        "rectangular_prism_volume_layer_iteration",
    ),
    "ordered_prism_dimensions_volume": (
        "geometry",
        "rectangular_prism_volume_layer_iteration",
    ),
    "two_rectangle_dimensions_area_comparison": (
        "geometry",
        "rectangle_area_unit_iteration",
    ),
    "rectangle_area_known_width_missing_length": (
        "geometry",
        "rectangle_missing_side_from_area",
    ),
    "direct_larger_to_smaller_unit_conversion": (
        "measurement",
        "unit_conversion_by_iteration",
    ),
    "direct_place_value_numeral_comparison": (
        "counting",
        "place_value_comparison",
    ),
    "direct_decimal_numeral_comparison": (
        "decimal",
        "decimal_comparison_by_aligned_units",
    ),
    "decimal_unit_weight_count_inscription": (
        "decimal",
        "positional_decimal_reading",
    ),
}


def compile_equation_verification_route_mappings(
    root: pathlib.Path,
    docs: list[LessonDoc],
    spans: list[StudentTaskSpan],
    recovered_by_key: dict[tuple[str, str], StudentTaskSpan],
    attachments: dict[str, set[tuple[str, str]]],
) -> list[Mapping]:
    """Attach only operation routes licensed by a bound EQV witness.

    The EQV reader performs the prompt, maximal-equation, response-block, and
    judgment-count gates before this function sees a row.  A row that passed
    those gates may supply a missing operation attachment for an exactly binary
    side.  The task itself is not promoted here; after the ledger is generated,
    ``validate_equation_verifications`` emits it with
    ``witness_class(printed_judgment)``.
    """
    parser_id = "witnessed_true_false_equation_side"
    actions = TASK_GRAMMAR_ACTIONS[parser_id]
    readings = equation_verification.read_span_readings(
        root,
        spans,
        recovered_by_key,
        {doc.code: doc for doc in docs},
        attachments,
        _next_response_range,
    )
    derived: set[Mapping] = set()
    attached = {code: set(rows) for code, rows in attachments.items()}
    for reading in readings:
        if reading.refusal:
            continue
        for row in reading.rows:
            for task in row.tasks:
                if task.reason != f"lesson_has_no_{task.operation}_attachment":
                    continue
                kind = actions.get(task.operation)
                if kind is None or (task.operation, kind) in attached.get(
                    reading.lesson, set()
                ):
                    continue
                mapping = Mapping(
                    reading.lesson,
                    task.operation,
                    kind,
                    _input_domain(task.operation),
                    f"task_grammar_{parser_id}",
                    row.span_source,
                    row.equation_line,
                    row.equation,
                )
                derived.add(mapping)
                attached.setdefault(reading.lesson, set()).add(
                    (task.operation, kind)
                )
    return sorted(derived)


def compile_task_derived_mappings(
    candidates: list[TaskCandidate],
    explicit: dict[str, set[tuple[str, str]]],
    mappings: list[Mapping],
) -> list[Mapping]:
    """Attach an action when an exact task grammar supplies stronger evidence."""
    attached = {code: set(rows) for code, rows in explicit.items()}
    for mapping in mappings:
        attached.setdefault(mapping.code, set()).add((mapping.operation, mapping.kind))
    derived = set()
    for candidate in candidates:
        action = TASK_GRAMMAR_ACTIONS.get(candidate.parser_id)
        if isinstance(action, dict):
            operation = candidate.operation
            kind = action.get(operation)
            if kind is None:
                continue
        elif action:
            operation, kind = action
            if candidate.operation != operation:
                continue
        else:
            continue
        if candidate.status != "reviewable" and not candidate.reason.startswith(
            "lesson_has_no_"
        ):
            continue
        if (operation, kind) in attached.get(candidate.code, set()):
            continue
        mapping = Mapping(
            candidate.code,
            operation,
            kind,
            _input_domain(operation),
            f"task_grammar_{candidate.parser_id}",
            candidate.source,
            candidate.line,
            candidate.excerpt,
        )
        derived.add(mapping)
        attached.setdefault(candidate.code, set()).add((operation, kind))
    return sorted(derived)


def promote_task_candidates(
    instances: list[TaskInstance], candidates: list[TaskCandidate], rules: dict
) -> tuple[list[TaskInstance], list[dict]]:
    """Promote allow-listed exact parsers while preserving reviewed evidence."""
    promoted_parsers = set(rules.get("promoted_task_parsers", []))
    result = set(instances)
    decisions = []
    recovered_source = str(RECOVERED_TASK_SPANS.relative_to(ROOT))
    for candidate in sorted(
        candidates, key=lambda row: (row.source == recovered_source, row)
    ):
        if candidate.status != "reviewable":
            decision = "rejected"
        elif candidate.parser_id not in promoted_parsers:
            decision = "quarantined"
        elif any(
            instance.code == candidate.code
            and instance.role == "productive"
            and instance.task == candidate.task
            and instance.position == candidate.position
            for instance in result
        ):
            decision = "duplicate_existing"
        else:
            result.add(
                TaskInstance(
                    candidate.code,
                    candidate.task,
                    "productive",
                    candidate.parser_id,
                    candidate.source,
                    candidate.line,
                    candidate.end_line,
                    candidate.position,
                    candidate.excerpt,
                )
            )
            decision = "promoted"
        decisions.append({**candidate.__dict__, "promotion": decision})
    return sorted(result), decisions


def read_explicit_mappings(root: pathlib.Path = ROOT) -> dict[str, set[tuple[str, str]]]:
    mappings: dict[str, set[tuple[str, str]]] = defaultdict(set)
    for path in sorted((root / LESSON_FACT_ROOT.relative_to(ROOT)).glob("grade_*.pl")):
        text = path.read_text(encoding="utf-8")
        for regex in (EXPLICIT_RE, VISION_RE):
            for code, operation, kind in regex.findall(text):
                mappings[code].add((operation, kind))
    return mappings


def _registry_rows(root: pathlib.Path = ROOT) -> set[tuple[str, str]]:
    goal = (
        "use_module(math(action_automata_registry)),"
        "findall(Op-Kind,(member(Op,[addition,subtraction,multiplication,division,fraction,"
        "decimal,integer,ratio,diagnostic,calculus,algebraic,probability,geometry,statistics,measurement,counting]),"
        "action_automata_registry:action_automaton_cluster(Op,Kind,_)),Rows0),sort(Rows0,Rows),"
        "forall(member(Op-Kind,Rows),"
        "(action_automata_registry:action_automaton_pair(Op,_,Kind,_)->true;"
        "format('REGISTRY\\t~w\\t~w~n',[Op,Kind]))),halt"
    )
    result = subprocess.run(
        ["swipl", "-q", "-l", "paths.pl", "-g", goal],
        cwd=root,
        text=True,
        capture_output=True,
        check=True,
    )
    rows = set()
    for line in result.stdout.splitlines():
        if line.startswith("REGISTRY\t"):
            _, operation, kind = line.split("\t")
            rows.add((operation, kind))
    return rows


def _first_match(doc: LessonDoc, patterns: list[str]) -> tuple[int, str] | None:
    candidates = (doc.title, *doc.goals, doc.purpose)
    for pattern in patterns:
        regex = re.compile(pattern, re.IGNORECASE)
        for text in candidates:
            if not regex.search(text):
                continue
            line = doc.line_by_text.get(text)
            if line is not None:
                return line, text
            # A joined purpose is useful for deciding whether the rule applies,
            # but it is not itself a physical source line. Cite the first
            # underlying line carrying the same match. If the match crosses a
            # line boundary, refuse instead of inventing a plausible location.
            physical = sorted(
                (source_line, source_text)
                for source_text, source_line in doc.line_by_text.items()
                if regex.search(source_text)
            )
            if physical:
                return physical[0]
            # The regex matched only across the spaces inserted while joining
            # physical lines. That synthetic adjacency has no citable source
            # location, so this candidate is withheld.
            continue
    return None


def validate_mapping_citations(
    root: pathlib.Path, mappings: list[Mapping]
) -> int:
    """Require every single-line markdown mapping to quote its cited line.

    Task-span mappings deliberately quote a match within a physical range.
    Legacy K-5 task-grammar mappings also predate range-bearing provenance, so
    their separate contracts remain with the task-span checks. New Docling
    task-grammar rows must satisfy this single-line validator.
    """
    checked = 0
    source_lines: dict[str, list[str]] = {}
    for mapping in mappings:
        if (
            mapping.line <= 0
            or mapping.matched_field == "task_span"
            or (
                mapping.rule_id.startswith("task_grammar_")
                and mapping.source_corpus != DOCLING_GUIDE_CORPUS
            )
            or not mapping.source.endswith(".md")
        ):
            continue
        lines = source_lines.get(mapping.source)
        if lines is None:
            path = root / mapping.source
            # Compiler citations count newline-delimited physical lines. Do not
            # use splitlines(), which also splits K-5 form-feed characters and
            # shifts every later citation.
            lines = path.read_text(encoding="utf-8", errors="replace").split("\n")
            source_lines[mapping.source] = lines
        if mapping.line > len(lines):
            raise SystemExit(
                "mapping citation line is outside its source file: "
                f"{mapping.source}:{mapping.line}"
            )
        cited = lines[mapping.line - 1].strip()
        if mapping.excerpt not in cited:
            raise SystemExit(
                "mapping excerpt is absent from its cited line: "
                f"{mapping.source}:{mapping.line} excerpt={mapping.excerpt!r}"
            )
        checked += 1
    return checked


def _first_task_span_match(
    spans: list[StudentTaskSpan], patterns: list[str]
) -> tuple[str, int, int, str, str] | None:
    """Return the first quoted, line-addressable student-task match.

    A text rule is still tried in its legacy title/goals/purpose fields first.
    This sibling entry point searches the extractor's complete task-span text,
    but returns the physical source-line range overlapping the quoted match.
    A new attachment can therefore cite a wrapped student prompt without
    citing concatenated text or any teacher-column text.
    """
    for pattern in patterns:
        regex = re.compile(pattern, re.IGNORECASE)
        for span in spans:
            match = regex.search(span.text)
            if match:
                offset = 0
                match_lines = []
                for line, text in span.lines:
                    text_end = offset + len(text)
                    if offset < match.end() and text_end > match.start():
                        match_lines.append(line)
                    # StudentTaskSpan.text joins physical lines with one space.
                    offset = text_end + 1
                if not match_lines:
                    raise SystemExit(
                        "task-span match has no physical source line: "
                        f"{span.code}/{span.position}/{pattern!r}"
                    )
                return (
                    span.source,
                    match_lines[0],
                    match_lines[-1],
                    span.position,
                    match.group(0),
                )
    return None


def _rule_match(doc: LessonDoc, rule: dict) -> tuple[int, str] | None:
    for pattern in rule.get("exclude_patterns", []):
        if re.search(pattern, doc.concise_text, re.IGNORECASE):
            return None
    return _first_match(doc, rule["patterns"])


def _input_domain(operation: str) -> str:
    return {
        "addition": "whole_number",
        "subtraction": "whole_number",
        "multiplication": "whole_number",
        "division": "whole_number",
        "fraction": "rational",
        "decimal": "decimal",
        "integer": "signed_number",
        "ratio": "ratio_pair",
        "algebraic": "symbolic_expression",
        "geometry": "spatial_measurement",
        "statistics": "data_set",
        "measurement": "measured_quantity",
        "counting": "discrete_collection",
    }.get(operation, "unspecified")


def compile_rule_mappings(
    docs: list[LessonDoc], rules: dict, explicit: dict[str, set[tuple[str, str]]]
) -> list[Mapping]:
    mappings = set()
    for doc in docs:
        for rule in rules["text_rules"]:
            match = _rule_match(doc, rule)
            key = (rule["operation"], rule["kind"])
            if match and key not in explicit.get(doc.code, set()):
                line, excerpt = match
                mappings.add(
                    Mapping(
                        doc.code,
                        *key,
                        rule.get("input_domain", _input_domain(rule["operation"])),
                        rule["id"],
                        str(doc.path.relative_to(ROOT)),
                        line,
                        excerpt,
                    )
                )
    return sorted(mappings)


def compile_task_span_rule_mappings(
    docs: list[LessonDoc],
    rules: dict,
    baseline_attached: set[str],
    task_spans: list[StudentTaskSpan],
) -> list[Mapping]:
    """Attach only strategy-empty lessons from their student task statements.

    ``baseline_attached`` is built before this pass. It prevents the widening
    from changing any attachment belonging to a lesson that already had one;
    task-span evidence is therefore strictly additive at the lesson level.
    """
    spans_by_code: dict[str, list[StudentTaskSpan]] = defaultdict(list)
    for span in task_spans:
        spans_by_code[span.code].append(span)
    mappings = set()
    for doc in docs:
        if doc.code in baseline_attached:
            continue
        for rule in rules["text_rules"]:
            # Keep the rule's existing exclusion surface unchanged. The task
            # statement widens positive evidence only; it does not make a
            # teacher-facing exclusion newly true.
            if any(
                re.search(pattern, doc.concise_text, re.IGNORECASE)
                for pattern in rule.get("exclude_patterns", [])
            ):
                continue
            match = _first_task_span_match(spans_by_code[doc.code], rule["patterns"])
            if not match:
                continue
            source, line, end_line, span_position, excerpt = match
            mappings.add(
                Mapping(
                    doc.code,
                    rule["operation"],
                    rule["kind"],
                    rule.get("input_domain", _input_domain(rule["operation"])),
                    rule["id"],
                    source,
                    line,
                    excerpt,
                    "task_span",
                    span_position,
                    end_line,
                )
            )
    return sorted(mappings)


def read_scope_titles(root: pathlib.Path = ROOT) -> dict[str, tuple[pathlib.Path, int, str]]:
    titles = {}
    for grade in (6, 7, 8):
        path = root / SCOPE_ROOT.relative_to(ROOT) / f"grade{grade}.md"
        for line_no, line in enumerate(path.read_text(encoding="utf-8").split("\n"), 1):
            match = re.search(r"\*\*Lesson (\d+):\*\* (.*?)  `(IM-G\d+-U\d+-L\d+)`", line)
            if match:
                titles[match.group(3)] = (path, line_no, match.group(2))
    return titles


def compile_scope_batches(
    rules: dict,
    explicit: dict[str, set[tuple[str, str]]],
    scope_titles: dict[str, tuple[pathlib.Path, int, str]],
) -> list[Mapping]:
    mappings = set()
    for batch in rules["scope_batches"]:
        for lesson in batch["lessons"]:
            code = f"IM-G{batch['grade']}-U{batch['unit']}-L{lesson}"
            key = (batch["operation"], batch["kind"])
            if key in explicit.get(code, set()):
                continue
            path, line, title = scope_titles[code]
            mappings.add(
                Mapping(
                    code,
                    *key,
                    batch.get("input_domain", _input_domain(batch["operation"])),
                    batch["id"],
                    str(path.relative_to(ROOT)),
                    line,
                    title,
                )
            )
    return sorted(mappings)


def compile_task_instances(
    docs: list[LessonDoc], rules: dict, covered: set[str],
    attachments: dict[str, set[tuple[str, str]]],
) -> list[TaskInstance]:
    """Compile only task statements whose quantities and action are explicit."""
    instances = set()
    draw_pattern = re.compile(
        r"^\s*Draw a rectangle with an area of (\d+) square units?\b",
        re.IGNORECASE,
    )
    all_pairs_pattern = re.compile(
        r"^\s*(\d+)\.\s*What are all of the possible side lengths of a rectangle "
        r"with an area of (\d+) square units?\?",
        re.IGNORECASE,
    )
    for doc in docs:
        if doc.code not in covered:
            continue
        source = str(doc.path.relative_to(ROOT))
        for line_no, line in enumerate(doc.path.read_text(encoding="utf-8", errors="replace").split("\n"), 1):
            draw = draw_pattern.search(line)
            if draw:
                area = int(draw.group(1))
                instances.add(
                    TaskInstance(
                        doc.code,
                        f"construct_rectangle_with_area({area})",
                        "productive",
                        "rectangle_area_construction_prompt",
                        source,
                        line_no,
                        line_no + 2,
                        f"source_sequence(line({line_no}))",
                        line.strip(),
                    )
                )
            all_pairs = all_pairs_pattern.search(line)
            if all_pairs:
                position = int(all_pairs.group(1))
                area = int(all_pairs.group(2))
                instances.add(
                    TaskInstance(
                        doc.code,
                        f"rectangle_side_lengths_for_area({area})",
                        "productive",
                        "rectangle_factor_pair_prompt",
                        source,
                        line_no,
                        line_no,
                        f"task_item({position})",
                        line.strip(),
                    )
                )
    docs_by_code = {doc.code: doc for doc in docs}
    for row in rules.get("reviewed_task_instances", []):
        code = row["code"]
        if code not in covered:
            raise SystemExit(f"reviewed task references lesson without accepted mapping: {code}")
        # A reviewed instance needs a LessonDoc only to derive a markdown default
        # source. An e343_pdf-sourced instance (a figure-bound operand recovered by
        # vision from a grade-6-8 guide) carries its own provenance and needs no
        # LessonDoc, so a covered scope-mapped lesson can hold executable task events
        # without being converted into a teacher-guide markdown file.
        doc = docs_by_code.get(code)
        default_source = str(doc.path.relative_to(ROOT)) if doc else ""
        source, line, end_line, pages = _reviewed_provenance(
            row, row["excerpt"], default_source, "reviewed task"
        )
        instances.add(
            TaskInstance(
                code,
                row["task"],
                "productive",
                row["id"],
                source,
                line,
                end_line,
                row["position"],
                row["excerpt"],
                pages,
            )
        )
        for deformation in row.get("deformations", []):
            d_source, d_line, d_end_line, d_pages = _reviewed_provenance(
                deformation, deformation["excerpt"], source, "reviewed deformation",
                inherited_pages=pages,
            )
            instances.add(
                TaskInstance(
                    code,
                    row["task"],
                    f"deformation({deformation['family']})",
                    deformation["id"],
                    d_source,
                    d_line,
                    d_end_line,
                    row["position"],
                    deformation["excerpt"],
                    d_pages,
                )
            )
    for reading in validate_lesson_task_readings(ROOT, docs, covered, attachments):
        instances.add(
            TaskInstance(
                reading["lesson"],
                reading["task"],
                "productive",
                reading["id"],
                reading["source"],
                reading["line"],
                reading["end_line"],
                reading["position"],
                reading["excerpt"],
                witness_class=reading["witness_class"],
            )
        )
    for row in validate_equation_verifications(ROOT, docs, covered, attachments):
        instances.add(
            TaskInstance(
                row["lesson"],
                row["task"],
                "productive",
                row["id"],
                row["source"],
                row["line"],
                row["end_line"],
                row["position"],
                row["excerpt"],
                witness_class=row["witness_class"],
            )
        )
    return sorted(instances)


def _reviewed_provenance(
    entry, excerpt, default_source, label, inherited_pages="", recovered_spans=None
):
    """Resolve a reviewed instance's source provenance.

    A markdown ``source`` string keeps the teacher-guide line-drift check: the
    excerpt must appear verbatim in the cited line range. A recovered-span
    source checks the excerpt against the already joined sidecar text. The
    legacy ``e343_pdf`` form remains for existing reviewed rows only; callers
    for the authored-readings lane reject it after this resolver returns.
    Returns ``(source, line, end_line, pages)``.
    """
    raw = entry.get("source")
    recovered = entry.get("recovered_span")
    if recovered is not None:
        if raw is not None:
            raise SystemExit(f"{label} mixes markdown and recovered-span provenance")
        if not isinstance(recovered, dict):
            raise SystemExit(f"{label} recovered_span is not an object: {recovered!r}")
        key = (recovered.get("lesson"), recovered.get("position"))
        span = recovered_spans.get(key) if recovered_spans is not None else None
        if span is None:
            raise SystemExit(f"{label} names no recovered task span: {key[0]}/{key[1]}")
        if excerpt not in span.text:
            raise SystemExit(
                f"{label} excerpt drifted in recovered span {key[0]}/{key[1]}: {excerpt!r}"
            )
        return str(RECOVERED_TASK_SPANS.relative_to(ROOT)), 0, 0, ""
    if raw is None and inherited_pages:
        # A deformation with no explicit source inherits the row's PDF provenance.
        return default_source, 0, 0, inherited_pages
    if isinstance(raw, dict):
        pdf = raw.get("e343_pdf")
        if pdf is None:
            raise SystemExit(f"{label} source object lacks e343_pdf key: {raw!r}")
        pdf_file = str(pdf["file"])
        pdf_pages = str(pdf["pages"])
        if not excerpt:
            raise SystemExit(f"{label} e343_pdf provenance requires a verbatim excerpt")
        return pdf_file, 0, 0, pdf_pages
    source = raw if raw is not None else default_source
    path = ROOT / source
    source_lines = path.read_text(encoding="utf-8", errors="replace").split("\n")
    line = entry["line"]
    end_line = entry.get("end_line", line)
    source_range = " ".join(part.strip() for part in source_lines[line - 1 : end_line])
    if excerpt not in source_range:
        raise SystemExit(
            f"{label} excerpt drifted at {source}:{line}-{end_line}: {excerpt!r}"
        )
    return source, line, end_line, ""


def _tokens(text: str) -> Counter[str]:
    return Counter(token for token in TOKEN_RE.findall(text.lower()) if len(token) > 2)


def similarity_review(
    docs: list[LessonDoc],
    explicit: dict[str, set[tuple[str, str]]],
    productive: set[tuple[str, str]],
    covered: set[str],
) -> list[dict]:
    vectors = {doc.code: _tokens(doc.concise_text) for doc in docs}
    df = Counter(token for vector in vectors.values() for token in vector)
    count = max(len(vectors), 1)

    def weighted(vector: Counter[str]) -> dict[str, float]:
        return {token: freq * (math.log((count + 1) / (df[token] + 1)) + 1) for token, freq in vector.items()}

    weighted_vectors = {code: weighted(vector) for code, vector in vectors.items()}

    def cosine(left: dict[str, float], right: dict[str, float]) -> float:
        common = left.keys() & right.keys()
        dot = sum(left[token] * right[token] for token in common)
        lnorm = math.sqrt(sum(value * value for value in left.values()))
        rnorm = math.sqrt(sum(value * value for value in right.values()))
        return dot / (lnorm * rnorm) if lnorm and rnorm else 0.0

    examples = [doc for doc in docs if explicit.get(doc.code)]
    review = []
    for doc in docs:
        if explicit.get(doc.code) or doc.code in covered:
            continue
        scores: dict[tuple[str, str], tuple[float, str]] = {}
        for example in examples:
            score = cosine(weighted_vectors[doc.code], weighted_vectors[example.code])
            if score < 0.18:
                continue
            for key in explicit[example.code] & productive:
                if score > scores.get(key, (0.0, ""))[0]:
                    scores[key] = (score, example.code)
        suggestions = [
            {"operation": op, "kind": kind, "similarity": round(score, 3), "example": example}
            for (op, kind), (score, example) in sorted(
                scores.items(), key=lambda item: (-item[1][0], item[0])
            )[:5]
        ]
        review.append(
            {
                "lesson": doc.code,
                "title": doc.title,
                "source": str(doc.path.relative_to(ROOT)),
                "source_corpus": doc.source_corpus,
                "goals": list(doc.goals),
                "purpose": doc.purpose,
                "suggestions": suggestions,
            }
        )
    return review


def gap_review(
    docs: list[LessonDoc],
    rules: dict,
    attachments: dict[str, set[tuple[str, str]]],
) -> list[dict]:
    gaps = []
    for doc in docs:
        matches = []
        for rule in rules["gap_rules"]:
            match = _first_match(doc, rule["patterns"])
            if not match:
                continue
            resolved_operations = set(rule.get("resolved_operations", []))
            lesson_operations = {
                operation for operation, _kind in attachments.get(doc.code, set())
            }
            if resolved_operations and lesson_operations & resolved_operations:
                continue
            if not resolved_operations and attachments.get(doc.code):
                continue
            line, excerpt = match
            matches.append({"family": rule["id"], "line": line, "excerpt": excerpt})
        if matches:
            gaps.append({"lesson": doc.code, "title": doc.title, "gaps": matches})
    return gaps


def scope_gap_review(
    rules: dict,
    covered: set[str],
    scope_titles: dict[str, tuple[pathlib.Path, int, str]],
) -> list[dict]:
    gaps = []
    for batch in rules.get("scope_gaps", []):
        for lesson in batch["lessons"]:
            code = f"IM-G{batch['grade']}-U{batch['unit']}-L{lesson}"
            if code in covered:
                continue
            path, line, title = scope_titles[code]
            gaps.append(
                {
                    "lesson": code,
                    "title": title,
                    "gaps": [
                        {
                            "family": batch["id"],
                            "source": str(path.relative_to(ROOT)),
                            "line": line,
                            "excerpt": title,
                        }
                    ],
                }
            )
    return gaps


def compile_review_batches(review: list[dict], atom_gaps: list[dict]) -> dict:
    atom_families: dict[str, dict[str, object]] = {}
    for row in atom_gaps:
        for gap in row["gaps"]:
            family = gap["family"]
            batch = atom_families.setdefault(
                family, {"family": family, "lessons": set(), "examples": []}
            )
            batch["lessons"].add(row["lesson"])
            if len(batch["examples"]) < 5:
                batch["examples"].append(
                    {"lesson": row["lesson"], "excerpt": gap["excerpt"]}
                )

    family_rows = []
    for batch in atom_families.values():
        lessons = sorted(batch["lessons"])
        family_rows.append(
            {
                "family": batch["family"],
                "lesson_count": len(lessons),
                "lessons": lessons,
                "examples": batch["examples"],
            }
        )
    family_rows.sort(key=lambda row: (-row["lesson_count"], row["family"]))

    units: dict[str, list[str]] = defaultdict(list)
    for row in review:
        match = CODE_RE.fullmatch(row["lesson"])
        if match:
            units[f"G{match.group(1)}-U{int(match.group(2))}"].append(row["lesson"])
    unit_rows = [
        {"unit": unit, "lesson_count": len(lessons), "lessons": sorted(lessons)}
        for unit, lessons in units.items()
    ]
    unit_rows.sort(key=lambda row: (-row["lesson_count"], row["unit"]))
    return {"atom_families": family_rows, "unmapped_units": unit_rows}


def _prolog_atom(value: str) -> str:
    if re.fullmatch(r"[a-z][a-zA-Z0-9_]*", value):
        return value
    return "'" + value.replace("'", "''") + "'"


def _prolog_string(value: str) -> str:
    return json.dumps(value, ensure_ascii=True)


def render_prolog(mappings: list[Mapping]) -> str:
    lesson_count = len({mapping.code for mapping in mappings})
    lines = [
        "/** <module> Generated source-backed curriculum action mappings",
        " *",
        " * Generated by scripts/curriculum/compile_action_mappings.py.",
        " * Do not edit by hand; update action_mapping_rules.json and regenerate.",
        " */",
        ":- module(compiled_action_mappings,",
        "          [ compiled_lesson_strategy/4,",
        "            compiled_mapping_summary/2",
        "          ]).",
        "",
        f"compiled_mapping_summary({lesson_count}, {len(mappings)}).",
        "",
    ]
    for mapping in mappings:
        task_span_provenance = (
            f", matched_field(task_span), span_position({_prolog_atom(mapping.span_position)})"
            if mapping.matched_field == "task_span"
            else ""
        )
        source = (
            f"source({_prolog_atom(mapping.source)}, lines({mapping.line}, {mapping.end_line}))"
            if mapping.matched_field == "task_span"
            else f"source({_prolog_atom(mapping.source)}, line({mapping.line}))"
        )
        evidence = (
            f"mapping_evidence(rule({_prolog_atom(mapping.rule_id)})"
            f"{task_span_provenance}, "
            f"{source}, "
            f"confidence(high), input_domain({mapping.input_domain}), "
            f"excerpt({_prolog_string(mapping.excerpt)}))"
        )
        lines.append(
            "compiled_lesson_strategy("
            f"{_prolog_atom(mapping.code)}, {mapping.operation}, {mapping.kind},\n"
            f"                         {evidence})."
        )
    lines.append("")
    return "\n".join(lines)


def render_task_prolog(instances: list[TaskInstance]) -> str:
    lesson_count = len({instance.code for instance in instances})
    lines = [
        "/** <module> Generated source-backed curriculum task instances",
        " *",
        " * Generated by scripts/curriculum/compile_action_mappings.py.",
        " * Do not edit by hand; extend the exact task parsers and regenerate.",
        " */",
        ":- module(compiled_task_instances,",
        "          [ compiled_lesson_task_instance/3,",
        "            compiled_task_instance_summary/2",
        "          ]).",
        "",
        f"compiled_task_instance_summary({lesson_count}, {len(instances)}).",
        "",
    ]
    recovered_source = str(RECOVERED_TASK_SPANS.relative_to(ROOT))
    for instance in instances:
        if instance.pages:
            source_term = (
                f"source(e343_pdf({_prolog_atom(instance.source)}, "
                f"pages({_prolog_string(instance.pages)})))"
            )
        elif instance.source == recovered_source:
            span_position = instance.position.split("/", 1)[0]
            source_term = (
                f"source(recovered_task_spans({_prolog_atom(instance.source)}, "
                f"lesson({_prolog_atom(instance.code)}), "
                f"position({_prolog_atom(span_position)})))"
            )
        else:
            source_term = (
                f"source({_prolog_atom(instance.source)}, "
                f"lines({instance.line}, {instance.end_line}))"
            )
        witness = (
            f", witness_class({instance.witness_class})"
            if instance.witness_class
            else ""
        )
        evidence = (
            f"task_evidence(rule({_prolog_atom(instance.rule_id)}), "
            f"{source_term}, "
            f"position({instance.position}), "
            f"excerpt({_prolog_string(instance.excerpt)}){witness})"
        )
        lines.append(
            "compiled_lesson_task_instance("
            f"{_prolog_atom(instance.code)}, {instance.role}-{instance.task},\n"
            f"                              {evidence})."
        )
    lines.append("")
    return "\n".join(lines)


def build(root: pathlib.Path, rules_path: pathlib.Path) -> tuple[str, str, dict]:
    rules = json.loads(rules_path.read_text(encoding="utf-8"))
    docs = read_teacher_guides(root)
    explicit = read_explicit_mappings(root)
    productive = _registry_rows(root)
    scope_titles = read_scope_titles(root)
    task_spans = extract_student_task_spans(docs)
    recovered_task_spans = read_recovered_task_spans(root, task_spans)
    parser_spans = task_spans + recovered_task_spans
    # Establish the pre-widening attachment set first. The task-span pass may
    # attach only a lesson absent from this set, preserving all existing
    # lesson-level strategy attachments byte-for-byte.
    legacy_mappings = compile_rule_mappings(docs, rules, explicit)
    baseline_mappings = sorted(
        set(legacy_mappings + compile_scope_batches(rules, explicit, scope_titles))
    )
    initial_attachments = {code: set(rows) for code, rows in explicit.items()}
    for mapping in baseline_mappings:
        initial_attachments.setdefault(mapping.code, set()).add(
            (mapping.operation, mapping.kind)
        )
    equation_route_mappings = compile_equation_verification_route_mappings(
        root,
        docs,
        task_spans,
        {
            (span.code, span.position): span
            for span in recovered_task_spans
        },
        initial_attachments,
    )
    baseline_mappings = sorted(set(baseline_mappings + equation_route_mappings))
    for mapping in equation_route_mappings:
        initial_attachments.setdefault(mapping.code, set()).add(
            (mapping.operation, mapping.kind)
        )
    initial_task_candidates = extract_task_candidates(parser_spans, initial_attachments)
    task_derived_mappings = compile_task_derived_mappings(
        initial_task_candidates, explicit, baseline_mappings
    )
    baseline_mappings = sorted(set(baseline_mappings + task_derived_mappings))
    baseline_attached = set(explicit) | {mapping.code for mapping in baseline_mappings}
    task_span_mappings = compile_task_span_rule_mappings(
        docs, rules, baseline_attached, task_spans
    )
    mappings = sorted(set(baseline_mappings + task_span_mappings))
    invalid = sorted({(m.operation, m.kind) for m in mappings} - productive)
    if invalid:
        raise SystemExit(f"mapping rules reference non-productive registry kinds: {invalid}")
    validated_mapping_citations = validate_mapping_citations(root, mappings)
    covered = {mapping.code for mapping in mappings}
    attachments = {code: set(rows) for code, rows in explicit.items()}
    for mapping in mappings:
        attachments.setdefault(mapping.code, set()).add((mapping.operation, mapping.kind))
    task_candidates = extract_task_candidates(parser_spans, attachments)
    task_covered = covered | set(explicit)
    task_instances = compile_task_instances(docs, rules, task_covered, attachments)
    task_instances, task_candidate_decisions = promote_task_candidates(
        task_instances, task_candidates, rules
    )
    task_candidate_decisions = [
        {**row, "source_corpus": _source_corpus(row["source"])}
        for row in task_candidate_decisions
    ]
    teacher_codes = {doc.code for doc in docs}
    newly_attached = {code for code in covered & teacher_codes if not explicit.get(code)}
    augmented = {code for code in covered & teacher_codes if explicit.get(code)}
    scope_codes = covered - teacher_codes
    review = similarity_review(docs, explicit, productive, covered)
    atom_gaps = gap_review(docs, rules, attachments) + scope_gap_review(
        rules, covered, scope_titles
    )
    guide_corpora = Counter(doc.source_corpus for doc in docs)
    span_corpora = Counter(span.source_corpus for span in task_spans)
    docling_docs = [
        doc for doc in docs if doc.source_corpus == DOCLING_GUIDE_CORPUS
    ]
    docling_span_lessons = {
        span.code
        for span in task_spans
        if span.source_corpus == DOCLING_GUIDE_CORPUS
    }
    zero_span_reasons = docling_zero_span_reasons(docs)
    docling_span_rows = [
        span
        for span in task_spans
        if span.source_corpus == DOCLING_GUIDE_CORPUS
    ]
    report = {
        "teacher_guides": len(docs),
        "teacher_guide_corpora": dict(sorted(guide_corpora.items())),
        "readable_middle_guides": len(docling_docs),
        "readable_middle_guides_by_grade": dict(sorted(Counter(
            CODE_RE.fullmatch(doc.code).group(1) for doc in docling_docs
        ).items())),
        "accepted_lessons": len(covered),
        "accepted_mappings": len(mappings),
        "validated_single_line_mapping_citations": validated_mapping_citations,
        "task_derived_mappings": len(task_derived_mappings),
        "newly_attached_teacher_lessons": len(newly_attached),
        "augmented_teacher_lessons": len(augmented),
        "scope_sequence_lessons": len(scope_codes),
        "accepted": [
            {**mapping.__dict__, "source_corpus": _source_corpus(mapping.source)}
            for mapping in mappings
        ],
        "accepted_task_instance_lessons": len({instance.code for instance in task_instances}),
        "accepted_productive_task_instances": sum(
            instance.role == "productive" for instance in task_instances
        ),
        "accepted_deformation_task_instances": sum(
            instance.role.startswith("deformation(") for instance in task_instances
        ),
        "accepted_task_instances": [
            {**instance.__dict__, "source_corpus": _source_corpus(instance.source)}
            for instance in task_instances
        ],
        "student_task_spans": len(task_spans),
        "student_task_span_corpora": dict(sorted(span_corpora.items())),
        "middle_guide_span_lessons": len(docling_span_lessons),
        "middle_guide_span_lessons_by_grade": dict(sorted(Counter(
            CODE_RE.fullmatch(code).group(1) for code in docling_span_lessons
        ).items())),
        "middle_guide_spans_by_grade": dict(sorted(Counter(
            CODE_RE.fullmatch(span.code).group(1) for span in docling_span_rows
        ).items())),
        "middle_guide_task_section_metrics": docling_task_section_metrics(docs),
        "middle_guide_zero_span_lessons": len(zero_span_reasons),
        "middle_guide_zero_span_reasons": zero_span_reasons,
        "recovered_task_spans": len(recovered_task_spans),
        "accepted_recovered_task_instances": sum(
            instance.source == str(RECOVERED_TASK_SPANS.relative_to(ROOT))
            for instance in task_instances
        ),
        "task_candidate_summary": dict(
            sorted(Counter(row["promotion"] for row in task_candidate_decisions).items())
        ),
        "task_candidates": task_candidate_decisions,
        "review": review,
        "atom_gaps": atom_gaps,
        "review_batches": compile_review_batches(review, atom_gaps),
    }
    return render_prolog(mappings), render_task_prolog(task_instances), report


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--rules", type=pathlib.Path, default=DEFAULT_RULES)
    parser.add_argument("--output", type=pathlib.Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--task-output", type=pathlib.Path, default=DEFAULT_TASK_OUTPUT)
    parser.add_argument("--review", type=pathlib.Path)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    content, task_content, report = build(ROOT, args.rules)
    if args.check:
        current = args.output.read_text(encoding="utf-8") if args.output.exists() else ""
        if current != content:
            print(f"stale generated mapping: {args.output.relative_to(ROOT)}", file=sys.stderr)
            return 1
        current_tasks = args.task_output.read_text(encoding="utf-8") if args.task_output.exists() else ""
        if current_tasks != task_content:
            print(f"stale generated task instances: {args.task_output.relative_to(ROOT)}", file=sys.stderr)
            return 1
    else:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(content, encoding="utf-8")
        args.task_output.parent.mkdir(parents=True, exist_ok=True)
        args.task_output.write_text(task_content, encoding="utf-8")
    if args.review:
        args.review.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(
        f"teacher_guides={report['teacher_guides']} "
        f"accepted_lessons={report['accepted_lessons']} "
        f"accepted_mappings={report['accepted_mappings']} "
        f"new_teacher_attachments={report['newly_attached_teacher_lessons']} "
        f"augmented_teacher_lessons={report['augmented_teacher_lessons']} "
        f"scope_lessons={report['scope_sequence_lessons']} "
        f"task_instance_lessons={report['accepted_task_instance_lessons']} "
        f"task_instances={len(report['accepted_task_instances'])} "
        f"task_candidates={len(report['task_candidates'])} "
        f"review={len(report['review'])} atom_gaps={len(report['atom_gaps'])}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
