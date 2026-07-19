#!/usr/bin/env python3
"""Compile verbatim activity prompts and synthesis sequences from IM guides.

The teacher guides are fixed-width Markdown extracts of two-column PDFs.  This
compiler only accepts the labelled ``Student Task Statement``, ``Activity
Synthesis``, and ``Lesson Synthesis`` regions.  It emits nothing for a region
whose labelled boundaries cannot be recovered conservatively.
"""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
GUIDES = ROOT / "geometry/corpus/im_teacher_guides"
OUTPUT = ROOT / "lessons/im/generated/compiled_lesson_context.pl"

ANCHOR_RE = re.compile(r"_Anchor ID: `([^`]+)`")
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


def prolog_atom(value: str) -> str:
    return "'" + value.replace("\\", "\\\\").replace("'", "\\'") + "'"


def prolog_string(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def item_term(item: Item) -> str:
    return (
        "context_item("
        f"{prolog_string(item.heading)}, {prolog_string(item.text)}, line({item.line}))"
    )


def list_term(items: tuple[Item, ...]) -> str:
    if not items:
        return "[]"
    return "[\n        " + ",\n        ".join(item_term(item) for item in items) + "\n    ]"


def render(contexts: list[LessonContext], failures: Counter[str], guide_count: int) -> str:
    prompt_count = sum(bool(context.prompts) for context in contexts)
    sequence_count = sum(bool(context.sequences) for context in contexts)
    lines = [
        "/** <module> Generated verbatim IM lesson prompts and synthesis sequences",
        " *",
        " * Generated by scripts/research/extract_lesson_context.py.",
        " * Do not edit by hand; update the extractor or source guides and regenerate.",
        " */",
        ":- module(compiled_lesson_context,",
        "          [ compiled_lesson_context/4,",
        "            compiled_lesson_context_summary/3,",
        "            compiled_lesson_context_defeat/2",
        "          ]).",
        "",
        f"compiled_lesson_context_summary({guide_count}, {prompt_count}, {sequence_count}).",
    ]
    for pattern, count in sorted(failures.items()):
        lines.append(
            f"compiled_lesson_context_defeat({prolog_atom(pattern)}, {count})."
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
    return "\n".join(lines).rstrip() + "\n"


def compile_cache() -> tuple[str, list[LessonContext], Counter[str]]:
    guides = sorted(GUIDES.rglob("*.md"))
    contexts: list[LessonContext] = []
    failures: Counter[str] = Counter()
    for guide in guides:
        context, guide_failures = parse_guide(guide)
        failures.update(guide_failures)
        if context:
            contexts.append(context)
    contexts.sort(key=lambda context: context.code)
    return render(contexts, failures, len(guides)), contexts, failures


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="fail if the cache is stale")
    parser.add_argument("--output", type=Path, default=OUTPUT)
    args = parser.parse_args()
    rendered, contexts, failures = compile_cache()
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
        "guides={guides} prompt_lessons={prompts} sequence_lessons={sequences}".format(
            guides=len(list(GUIDES.rglob("*.md"))),
            prompts=sum(bool(context.prompts) for context in contexts),
            sequences=sum(bool(context.sequences) for context in contexts),
        )
    )
    for pattern, count in sorted(failures.items()):
        print(f"defeated {pattern}={count}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
