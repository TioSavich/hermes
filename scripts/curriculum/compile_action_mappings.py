#!/usr/bin/env python3
"""Compile source-cited lesson mappings without promoting guesses to facts.

High-confidence phrase rules and reviewed scope batches become executable lesson
attachments. Similarity suggestions and atom gaps are emitted only to a review
report. The generated Prolog is deterministic and supports ``--check``.
"""

from __future__ import annotations

import argparse
import json
import math
import pathlib
import re
import subprocess
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass

ROOT = pathlib.Path(__file__).resolve().parents[2]
DEFAULT_RULES = ROOT / "scripts/curriculum/action_mapping_rules.json"
DEFAULT_OUTPUT = ROOT / "lessons/im/generated/compiled_action_mappings.pl"
DEFAULT_TASK_OUTPUT = ROOT / "lessons/im/generated/compiled_task_instances.pl"

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


@dataclass(frozen=True)
class LessonDoc:
    code: str
    path: pathlib.Path
    title: str
    goals: tuple[str, ...]
    purpose: str
    line_by_text: dict[str, int]

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


@dataclass(frozen=True)
class StudentTaskSpan:
    code: str
    source: str
    heading_line: int
    end_line: int
    position: str
    lines: tuple[tuple[int, str], ...]

    @property
    def text(self) -> str:
        return " ".join(text for _, text in self.lines).strip()


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


def _grade_token(directory: str) -> str:
    token = directory.removeprefix("grade")
    return "K" if token == "k" or token == "kindergarten" else token


def _code_for_guide(path: pathlib.Path) -> str:
    grade = _grade_token(path.parents[1].name)
    unit = int(path.parent.name.removeprefix("unit"))
    lesson = int(path.stem.removeprefix("lesson"))
    return f"IM-G{grade}-U{unit}-L{lesson}"


def _section(lines: list[str], heading: str) -> list[tuple[int, str]]:
    start = next((i for i, line in enumerate(lines) if line.strip() == heading), None)
    if start is None:
        return []
    out = []
    for index in range(start + 1, len(lines)):
        line = lines[index].strip()
        if line.startswith("## "):
            break
        if line:
            out.append((index + 1, line.removeprefix("- ").strip()))
    return out


def read_teacher_guides(root: pathlib.Path = ROOT) -> list[LessonDoc]:
    docs = []
    guide_root = root / "geometry/corpus/im_teacher_guides"
    for path in sorted(guide_root.glob("*/unit*/lesson*.md")):
        grade_dir = path.parents[1].name
        if not (grade_dir.startswith("grade") or grade_dir == "kindergarten"):
            continue
        # Grade-6 teacher guides stay on the reader lane. They were converted for
        # per-lesson reading and figure-bound operands, not wired into the
        # one-lesson-per-file LessonDoc path pending a per-lesson-provenance
        # decision (2026-07-11 grade-6 corpus note). Their strategy mappings come
        # from scope batches, so excluding them here changes report categorization
        # only, not the emitted facts.
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
            )
        )
    return docs


def _student_column(line: str, right_column: int | None) -> str:
    clean = line.replace("\f", " ", 1)
    if right_column is not None and len(clean) > right_column:
        clean = clean[:right_column]
    return clean.strip()


def extract_student_task_spans(docs: list[LessonDoc]) -> list[StudentTaskSpan]:
    """Recover left-column student prompts without teacher launch commentary."""
    spans = []
    footer = re.compile(
        r"^(?:Grade [K0-8]|Unit \d+|Lesson \d+|CC BY NC \d{4}|Illustrative Mathematics)",
        re.IGNORECASE,
    )
    for doc in docs:
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
                )
            )
    return spans


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


def _whole_numbers_in_text(text: str) -> list[int]:
    return [
        int(match.group(0))
        for match in re.finditer(r"(?<![\d.,])\d+(?![\d.,])", text)
    ]


def _through_how_many_question(text: str) -> str:
    match = re.search(r"^.*?\bHow many\b[^?]*\?", text, re.IGNORECASE)
    return match.group(0) if match else text


def extract_task_candidates(
    spans: list[StudentTaskSpan], attachments: dict[str, set[tuple[str, str]]]
) -> list[TaskCandidate]:
    """Extract exact operand-bearing prompts for review, never direct promotion."""
    number = NUMBER_TOKEN
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
        if re.search(r"\bFind the value of each expression\b", span.text, re.IGNORECASE):
            expression_number = 0
            for line, text in span.lines:
                for match in re.finditer(r"(?<![\d.])(\d+)\s*\+\s*(\d+)(?![\d.])", text):
                    expression_number += 1
                    has_route = any(
                        operation == "addition"
                        for operation, _ in attachments.get(span.code, set())
                    )
                    candidates.add(
                        TaskCandidate(
                            span.code,
                            f"add({int(match.group(1))}, {int(match.group(2))})",
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
    return sorted(candidates)


TASK_GRAMMAR_ACTIONS = {
    "direct_addition_expression_list": ("addition", "count_on_from_larger"),
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
    "story_take_from_result_unknown": ("subtraction", "take_away_base_ones"),
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
        if not action or candidate.operation != action[0]:
            continue
        if candidate.status != "reviewable" and not candidate.reason.startswith(
            "lesson_has_no_"
        ):
            continue
        operation, kind = action
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
    for candidate in candidates:
        if candidate.status != "reviewable":
            decision = "rejected"
        elif candidate.parser_id not in promoted_parsers:
            decision = "quarantined"
        elif any(
            instance.code == candidate.code
            and instance.role == "productive"
            and instance.task == candidate.task
            and instance.source == candidate.source
            and instance.line <= candidate.end_line
            and candidate.line <= instance.end_line
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
    for path in sorted((root / "lessons/im").glob("grade_*.pl")):
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
    candidates = [(doc.line_by_text.get(text, 1), text) for text in (doc.title, *doc.goals, doc.purpose)]
    for pattern in patterns:
        regex = re.compile(pattern, re.IGNORECASE)
        for line, text in candidates:
            if regex.search(text):
                return line, text
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


def read_scope_titles(root: pathlib.Path = ROOT) -> dict[str, tuple[pathlib.Path, int, str]]:
    titles = {}
    for grade in (6, 7, 8):
        path = root / f"geometry/corpus/im_scope_and_sequence/grade{grade}.md"
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
    docs: list[LessonDoc], rules: dict, covered: set[str]
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
    return sorted(instances)


def _reviewed_provenance(entry, excerpt, default_source, label, inherited_pages=""):
    """Resolve a reviewed instance's source provenance.

    Two provenance forms are accepted. A markdown ``source`` string keeps the
    teacher-guide line-drift check: the excerpt must appear verbatim in the
    cited line range. An ``{"e343_pdf": {"file": ..., "pages": ...}}`` source
    records an E343 PDF page reference for a quantity the markdown extract lost
    to a figure; the PDF is not line-addressable and lives outside the repo, so
    the compiler records the reference and the excerpt without a drift check.
    Returns ``(source, line, end_line, pages)``.
    """
    raw = entry.get("source")
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
        evidence = (
            f"mapping_evidence(rule({_prolog_atom(mapping.rule_id)}), "
            f"source({_prolog_atom(mapping.source)}, line({mapping.line})), "
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
    for instance in instances:
        if instance.pages:
            source_term = (
                f"source(e343_pdf({_prolog_atom(instance.source)}, "
                f"pages({_prolog_string(instance.pages)})))"
            )
        else:
            source_term = (
                f"source({_prolog_atom(instance.source)}, "
                f"lines({instance.line}, {instance.end_line}))"
            )
        evidence = (
            f"task_evidence(rule({_prolog_atom(instance.rule_id)}), "
            f"{source_term}, "
            f"position({instance.position}), "
            f"excerpt({_prolog_string(instance.excerpt)}))"
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
    mappings = compile_rule_mappings(docs, rules, explicit)
    mappings += compile_scope_batches(rules, explicit, scope_titles)
    mappings = sorted(set(mappings))
    task_spans = extract_student_task_spans(docs)
    initial_attachments = {code: set(rows) for code, rows in explicit.items()}
    for mapping in mappings:
        initial_attachments.setdefault(mapping.code, set()).add(
            (mapping.operation, mapping.kind)
        )
    initial_task_candidates = extract_task_candidates(task_spans, initial_attachments)
    task_derived_mappings = compile_task_derived_mappings(
        initial_task_candidates, explicit, mappings
    )
    mappings = sorted(set(mappings + task_derived_mappings))
    invalid = sorted({(m.operation, m.kind) for m in mappings} - productive)
    if invalid:
        raise SystemExit(f"mapping rules reference non-productive registry kinds: {invalid}")
    covered = {mapping.code for mapping in mappings}
    attachments = {code: set(rows) for code, rows in explicit.items()}
    for mapping in mappings:
        attachments.setdefault(mapping.code, set()).add((mapping.operation, mapping.kind))
    task_candidates = extract_task_candidates(task_spans, attachments)
    task_covered = covered | set(explicit)
    task_instances = compile_task_instances(docs, rules, task_covered)
    task_instances, task_candidate_decisions = promote_task_candidates(
        task_instances, task_candidates, rules
    )
    teacher_codes = {doc.code for doc in docs}
    newly_attached = {code for code in covered & teacher_codes if not explicit.get(code)}
    augmented = {code for code in covered & teacher_codes if explicit.get(code)}
    scope_codes = covered - teacher_codes
    review = similarity_review(docs, explicit, productive, covered)
    atom_gaps = gap_review(docs, rules, attachments) + scope_gap_review(
        rules, covered, scope_titles
    )
    report = {
        "teacher_guides": len(docs),
        "accepted_lessons": len(covered),
        "accepted_mappings": len(mappings),
        "task_derived_mappings": len(task_derived_mappings),
        "newly_attached_teacher_lessons": len(newly_attached),
        "augmented_teacher_lessons": len(augmented),
        "scope_sequence_lessons": len(scope_codes),
        "accepted": [mapping.__dict__ for mapping in mappings],
        "accepted_task_instance_lessons": len({instance.code for instance in task_instances}),
        "accepted_productive_task_instances": sum(
            instance.role == "productive" for instance in task_instances
        ),
        "accepted_deformation_task_instances": sum(
            instance.role.startswith("deformation(") for instance in task_instances
        ),
        "accepted_task_instances": [instance.__dict__ for instance in task_instances],
        "student_task_spans": len(task_spans),
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
