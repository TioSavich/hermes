#!/usr/bin/env python3
"""Generate the bounded student-task-span absence registry.

The IM teacher guides carry a finite set of student task statements. The
action-mapping compiler parses a small part of that set into executable task
candidates and says nothing about the rest, so a span the parsers cannot read
has looked the same as a span nobody read. This generator closes that by
giving every span a row: either the compiler's decision about it, or a typed
reason no task candidate came out of it.

The denominator is the span corpus itself, measured here rather than quoted.
The reasons are structural properties of the extracted text that a reader can
confirm against the cited line range, so each one names a next step. Some ask
for work on the markdown conversion, which lost content the parsers would
have used; some ask for a task grammar the parsers do not yet carry; and one
asks for nothing, because the span states no computation over the quantities
it carries and never could have yielded a task.
"""
from __future__ import annotations

import argparse
import difflib
import json
import re
import subprocess
import sys
import tempfile
from collections import Counter, defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "knowledge" / "index" / "task_span_absence_registry.pl"
LESSON_EVIDENCE = ROOT / "data" / "learningcommons" / "derived" / "im_lesson_evidence.json"
COMPILER_DIRECTORY = ROOT / "scripts" / "curriculum"
RULES = COMPILER_DIRECTORY / "action_mapping_rules.json"
DOCLING_GUIDES = (
    ROOT
    / "hermes/app/runtime/experiments/gemma4_tutor/docling/full-output"
    / "TeacherLessonGuides"
)

sys.path.insert(0, str(COMPILER_DIRECTORY))
import compile_action_mappings as compiler  # noqa: E402

LESSON_CODE = re.compile(r"^IM-G(K|[1-8])-U([1-9][0-9]*)-L([1-9][0-9]*)$")

# Section headings that belong to the teacher-facing columns and the
# lesson-level sections below a task. Their presence inside an extracted span
# means the span reader ran past the student prompt, so quantities in that
# span cannot be attributed to the student text.
TEACHER_SECTIONS = (
    "Lesson Synthesis",
    "Activity Synthesis",
    "Activity Narrative",
    "Responding to Student Thinking",
    "Building on Student Thinking",
    "Required Materials",
    "Suggested Centers",
    "Next Day Supports",
    "Access for",
    "Advances:",
    "quiet think time",
)
TEACHER_SECTION_PATTERNS = tuple(
    (name, re.compile(re.escape(name), re.IGNORECASE)) for name in TEACHER_SECTIONS
) + (("MLR", re.compile(r"\bMLR\d")),)

# A demand for a computed result. The list stays close to the imperatives the
# guides actually use; a phrase outside it costs the span its imperative
# marker, never its row.
COMPUTATIONAL_DEMAND = re.compile(
    r"\b(?:find the value"
    r"|value of"
    r"|find the (?:sum|difference|product|quotient|total)"
    r"|find the number that makes"
    r"|complete the (?:equation|expression|table)"
    r"|write an equation"
    r"|solve"
    r"|how many"
    r"|how much"
    r"|which is (?:greater|less)"
    r"|true or false"
    r"|make each statement true)\b",
    re.IGNORECASE,
)

# A list marker with nothing between it and the next marker, or a run of
# spaces closing a sentence. Both are what an expression rendered as an image
# leaves behind once the guide is converted to text.
VOID_SLOT = re.compile(
    r"•\s*(?=•|$)"
    r"|(?<![\d.])\d+\.\s*(?=\d+\.|$)"
    r"|(?<![A-Za-z])[a-eA-E]\.\s*(?=[a-eA-E]\.|$)"
    r"|[A-Za-z?.,)’]\s{3,}[.?]"
)
BLANK_AFTER_DEMAND = re.compile(r"\s{3,}[.?]")

ITEM_MARKER = re.compile(r"(?:^|\s)(?:\d+\.|[a-eA-E]\.)(?=\s)")
CURRICULAR_REFERENCE = re.compile(
    r"\b(?:Grade|Unit|Lesson|Activity|Stage|Warm-up)\s*[K0-9]+\b|\b\d+\s*min\b",
    re.IGNORECASE,
)
STANDALONE_QUANTITY = re.compile(r"(?<![\d.,/])\d+(?:\.\d+)?(?![\d.,/])")

# Two numerals with an arithmetic operator printed between them. The guides
# render an operation this way whenever they mean the student to perform it, so
# its absence from a span is what separates quantities that stand in an
# arithmetic relation from quantities that are merely listed. The slash stays
# out of the operator class: it separates the parts of a fraction here, not a
# dividend from a divisor.
NUMERAL = r"\d+(?:,\d{3})*(?:\.\d+)?"
PRINTED_ARITHMETIC = re.compile(
    rf"(?<![\d.,/]){NUMERAL}\s*[+×÷·−-]\s*{NUMERAL}(?![\d.,/])"
)

PAGE_FOOTER = re.compile(
    r"^(?:Grade [K0-8]|Unit \d+|Lesson \d+|CC BY NC \d{4}|Illustrative Mathematics)",
    re.IGNORECASE,
)

STATUS_KINDS = ("present", "coverage_gap", "broken_pipeline", "not_applicable", "unknown")

# Reason vocabulary, in cascade order. Each reason is decided by one property
# of the extracted span, and each names a different next step.
REASON_KIND = {
    "compiled_task_instance": "present",
    "existing_task_instance": "present",
    "parser_quarantined": "coverage_gap",
    "candidate_rejected": "coverage_gap",
    "empty_extract": "broken_pipeline",
    "extract_runs_past_prompt": "unknown",
    "void_operand_slots": "broken_pipeline",
    "quantities_carry_no_operand_pair": "not_applicable",
    "no_task_grammar_for_quantity_pair": "coverage_gap",
    "imperative_without_quantity": "broken_pipeline",
    "no_task_grammar_for_single_quantity": "coverage_gap",
    "prompt_states_no_computation": "not_applicable",
}
REASON_ORDER = tuple(REASON_KIND)
PARSED_REASONS = (
    "compiled_task_instance",
    "existing_task_instance",
    "parser_quarantined",
    "candidate_rejected",
)
PROMOTION_REASON = {
    "promoted": "compiled_task_instance",
    "duplicate_existing": "existing_task_instance",
    "quarantined": "parser_quarantined",
    "rejected": "candidate_rejected",
}

REGISTER = """/** <module> Generated student-task-span absence registry
 *
 * One row per student task statement in the IM teacher guides this checkout
 * carries. The span corpus is the denominator; the receipt says either what
 * the action-mapping compiler made of the span or why nothing came out of it.
 *
 * Reasons are properties of the extracted text, checkable against the line
 * range each row cites:
 *   - compiled_task_instance: a candidate from this span is a compiled task.
 *   - existing_task_instance: a candidate repeats a task already compiled.
 *   - parser_quarantined: a candidate parsed but its parser is not promoted.
 *   - candidate_rejected: a candidate parsed and the compiler declined it.
 *   - empty_extract: the span reader recovered no text at all.
 *   - extract_runs_past_prompt: teacher-facing sections are inside the span,
 *     so quantities in it cannot be attributed to the student prompt.
 *   - void_operand_slots: list markers or sentence-closing blanks stand where
 *     operands belong. The markdown conversion kept the frame of the item
 *     list and carries nothing inside it. Some K-5 expressions have been
 *     recovered into the checked sidecar, but this registry classifies the
 *     tracked markdown text only and does not yet consult that sidecar.
 *   - imperative_without_quantity: the prompt asks for a computed result and
 *     the extract carries no quantity to compute with.
 *   - quantities_carry_no_operand_pair: two or more quantities survive, and
 *     the extract carries no operator printed between two numerals, no demand
 *     for a computed result, and no void slot. The quantities are set members
 *     handed out for sorting, number-card decks, data-table cells, price
 *     lists, clock times, figure labels, category numbers, or page fragments,
 *     so no pair of them stands in an arithmetic relation the text states.
 *     Retyping a span here is not a coverage claim in either direction. It
 *     records that the span was never reachable, which is a different fact
 *     from having failed to reach it.
 *
 *     A question mark used to divert a span out of this reason and into the
 *     coverage gap below. It no longer does, because asking something is not
 *     stating an arithmetic relation: the diverted spans read "What do you
 *     notice? What do you wonder?", "How can you act out this story?", "Who do
 *     you agree with? Explain your reasoning", "Sort the pictures into these 3
 *     categories". No task grammar can reach any of them, and 225 of the 818
 *     spans in the gap were there on a question mark alone.
 *   - no_task_grammar_for_quantity_pair: two or more quantities survive, the
 *     extract states a computation over them — a demand phrase, printed
 *     arithmetic, or a void operand slot, never a bare question mark — and no
 *     task grammar matches the sentence shape. A parser would act here.
 *   - no_task_grammar_for_single_quantity: one quantity survives, so no
 *     operand pair can be formed from the text alone.
 *   - prompt_states_no_computation: no quantity and no computational demand.
 *
 * The reasons are decided in the order listed, so a row carries the first
 * property that holds of it and the remaining properties stay in its evidence.
 * A span the compiler read keeps every candidate it produced in its evidence,
 * including declined ones, so the four parsed reasons name what the span
 * amounts to rather than what each candidate did.
 *
 * Geometry evidence is genre-sensitive. Hand-templated K-5 guides report the
 * measured column cut and an integer page-footer crossing count. Single-column
 * Docling guides instead report column_cut(not_applicable(single_column_docling))
 * and page_boundary_crossings(not_applicable(no_page_footer_geometry)). These
 * terms distinguish an inapplicable measurement from a measured zero.
 *
 * task_span_reason_queue/3 ranks the reasons by how many lessons missing only
 * executable_task and measured_transition carry at least one span with that
 * reason. A lesson usually carries several reasons, so the counts overlap and
 * do not partition the cohort. The ranking counts lessons, not reachable work:
 * task_span_reason_kind/2 says which kind a rank carries, and a rank whose kind
 * is not_applicable names lessons no parser or conversion reaches. Read the two
 * together before treating a rank as a queue position.
 *
 * Generated by scripts/extract_task_span_absence_registry.py.
 * Regenerate: python3 scripts/extract_task_span_absence_registry.py
 */

:- module(task_span_absence_registry,
          [ task_span_receipt/4,             % ?Lesson, ?Position, ?Status, -Evidence
            task_span_denominator/2,         % ?Scope, ?Count
            task_span_status_count/2,        % ?StatusKind, ?Count
            task_span_reason_count/2,        % ?Reason, ?Count
            task_span_reason_kind/2,         % ?Reason, ?StatusKind
            task_span_grade_count/4,         % ?Grade, ?Spans, ?Resolved, ?Unresolved
            task_span_reason_grade_count/3,  % ?Reason, ?Grade, ?Count
            lesson_task_span_rollup/6,       % ?Lesson, ?Grade, ?Spans, ?Resolved,
                                             %   ?Readiness, ?PrimaryBlocker
            lesson_task_span_reason_count/3, % ?Lesson, ?Reason, ?Count
            lesson_missing_only_task_evidence/1,      % ?Lesson
            task_span_reason_queue/3,        % ?Rank, ?Reason, ?LessonCount
            task_span_unresolved/3,          % ?Lesson, ?Position, ?Status
            lesson_one_parser_away/3         % ?Lesson, ?Reason, ?SpanCount
          ]).
"""

RULES_BLOCK = """
task_span_unresolved(Lesson, Position, Status) :-
    task_span_receipt(Lesson, Position, Status, _),
    Status =.. [Kind, _],
    Kind \\== present.

lesson_one_parser_away(Lesson, Reason, SpanCount) :-
    lesson_missing_only_task_evidence(Lesson),
    lesson_task_span_reason_count(Lesson, Reason, SpanCount),
    task_span_reason_kind(Reason, coverage_gap).
"""


def prolog_atom(value: str) -> str:
    if re.fullmatch(r"[a-z][A-Za-z0-9_]*", value):
        return value
    return "'" + value.replace("'", "''") + "'"


def grade_of(lesson: str) -> str:
    match = LESSON_CODE.fullmatch(lesson)
    if match is None:
        raise RuntimeError(f"unparseable lesson code in the span corpus: {lesson}")
    return match.group(1)


def standalone_quantities(text: str) -> list[str]:
    """Count numerals that are neither item markers nor curricular references."""
    without_references = CURRICULAR_REFERENCE.sub(" ", text)
    return STANDALONE_QUANTITY.findall(ITEM_MARKER.sub(" ", without_references))


def void_slot_count(text: str) -> int:
    return len(VOID_SLOT.findall(text))


def demand_meets_void(text: str) -> bool:
    """A computational demand whose object position is blank in the extract."""
    for match in COMPUTATIONAL_DEMAND.finditer(text):
        tail = text[match.end() : match.end() + 45]
        if BLANK_AFTER_DEMAND.match(tail) or VOID_SLOT.search(tail):
            return True
    return False


def teacher_sections_in(text: str) -> list[str]:
    return sorted(name for name, pattern in TEACHER_SECTION_PATTERNS if pattern.search(text))


def span_geometry(root: Path) -> dict[tuple[str, str], tuple[int, str]]:
    """Measure column cuts and page-footer crossings for K-5 guide spans.

    This forward scan mirrors the compiler's hand-templated, two-column reader.
    Docling guides use a separate single-column reader and have no corresponding
    geometry measurement, so they are deliberately absent from this mapping.
    """
    geometry: dict[tuple[str, str], tuple[int, str]] = {}
    for doc in compiler.read_teacher_guides(root):
        if doc.source_corpus != compiler.HAND_TEMPLATED_GUIDE_CORPUS:
            continue
        lines = doc.path.read_text(encoding="utf-8", errors="replace").split("\n")
        span_number = 0
        for index, raw_heading in enumerate(lines):
            if not raw_heading.lstrip("\f ").startswith("Student Task Statement"):
                continue
            span_number += 1
            launch_column = raw_heading.find("Launch")
            right_column = max(launch_column - 2, 0) if launch_column >= 0 else None
            crossings = 0
            for next_index in range(index + 1, min(len(lines), index + 121)):
                stripped = lines[next_index].lstrip("\f ")
                if stripped.startswith("Student Response") or stripped.startswith(
                    "Student Task Statement"
                ):
                    break
                text = compiler._student_column(lines[next_index], right_column)
                if text and PAGE_FOOTER.match(text):
                    crossings += 1
            geometry[(doc.code, f"student_task_statement({span_number})")] = (
                crossings,
                "launch_header" if launch_column >= 0 else "none",
            )
    return geometry


def lesson_readiness(path: Path) -> tuple[dict[str, str], set[str]]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    lessons = payload.get("lessons")
    if not isinstance(lessons, list) or not lessons:
        raise RuntimeError(f"{path.relative_to(ROOT)} carries no lesson rows")
    readiness: dict[str, str] = {}
    missing_only_task_evidence: set[str] = set()
    for row in lessons:
        readiness[row["lesson"]] = row["readiness"]
        if set(row["missing_for_diagnosis"]) == {"executable_task", "measured_transition"}:
            missing_only_task_evidence.add(row["lesson"])
    if not missing_only_task_evidence:
        raise RuntimeError("no lesson is missing only executable_task and measured_transition")
    return readiness, missing_only_task_evidence


def classify(text: str, decisions: list[dict]) -> tuple[str, list[str]]:
    """Return the first reason that holds of this span and its evidence terms."""
    if decisions:
        promotions = {row["promotion"] for row in decisions}
        for promotion, reason in PROMOTION_REASON.items():
            if promotion in promotions:
                evidence = [
                    f"task_candidate({row['position']}, "
                    f"rule({prolog_atom(row['parser_id'])}), {row['task']}, "
                    f"{prolog_atom(row['promotion'])}, {prolog_atom(row['reason'])})"
                    for row in sorted(
                        decisions,
                        key=lambda row: (row["position"], row["parser_id"], row["task"]),
                    )
                ]
                return reason, evidence
        raise RuntimeError(f"unknown compiler promotion values: {sorted(promotions)}")

    if not text:
        return "empty_extract", []

    sections = teacher_sections_in(text)
    quantities = standalone_quantities(text)
    voids = void_slot_count(text)
    demand = bool(COMPUTATIONAL_DEMAND.search(text))
    arithmetic = bool(PRINTED_ARITHMETIC.search(text))
    question = "?" in text
    evidence = [
        f"quantities({len(quantities)})",
        f"void_slots({voids})",
        f"computational_demand({'true' if demand else 'false'})",
        f"printed_arithmetic({'true' if arithmetic else 'false'})",
        f"question_mark({'true' if question else 'false'})",
    ]
    if sections:
        evidence.append(
            "teacher_sections([" + ", ".join(prolog_atom(name) for name in sections) + "])"
        )
        return "extract_runs_past_prompt", evidence
    if demand_meets_void(text):
        return "void_operand_slots", evidence
    if len(quantities) >= 2 and not (arithmetic or demand or voids):
        return "quantities_carry_no_operand_pair", evidence
    if len(quantities) >= 2:
        return "no_task_grammar_for_quantity_pair", evidence
    if voids:
        return "void_operand_slots", evidence
    if demand and not quantities:
        return "imperative_without_quantity", evidence
    if len(quantities) == 1:
        return "no_task_grammar_for_single_quantity", evidence
    return "prompt_states_no_computation", evidence


def build_rows(root: Path) -> dict[str, object]:
    _mappings, _tasks, report = compiler.build(root, RULES)
    decisions_by_span: dict[tuple[str, str], list[dict]] = defaultdict(list)
    readiness, missing_only_task_evidence = lesson_readiness(LESSON_EVIDENCE)
    for row in report["task_candidates"]:
        decisions_by_span[(row["code"], row["position"].split("/")[0])].append(row)

    docs = compiler.read_teacher_guides(root)
    spans = compiler.extract_student_task_spans(docs)
    geometry = span_geometry(root)

    span_keys = {(span.code, span.position) for span in spans}
    if len(span_keys) != len(spans):
        raise RuntimeError("student task span positions are not unique within a lesson")
    orphan_decisions = sorted(set(decisions_by_span) - span_keys)
    if orphan_decisions:
        raise RuntimeError(
            "task candidates cite spans absent from the corpus: "
            + ", ".join(f"{lesson}/{position}" for lesson, position in orphan_decisions)
        )

    rows: list[tuple[str, str, str, str, str, str]] = []
    reason_counts: Counter[str] = Counter()
    reason_grade_counts: Counter[tuple[str, str]] = Counter()
    grade_spans: Counter[str] = Counter()
    grade_resolved: Counter[str] = Counter()
    lesson_spans: Counter[str] = Counter()
    lesson_resolved: Counter[str] = Counter()
    lesson_reason_counts: Counter[tuple[str, str]] = Counter()
    parsed_span_count = 0

    for span in sorted(spans, key=lambda span: (span.code, span.heading_line)):
        decisions = decisions_by_span.get((span.code, span.position), [])
        reason, evidence = classify(span.text, decisions)
        if decisions:
            parsed_span_count += 1
            if reason not in PARSED_REASONS:
                raise RuntimeError(
                    f"{span.code}/{span.position} parsed but was classified {reason}"
                )
        grade = grade_of(span.code)
        span_key = (span.code, span.position)
        if span.source_corpus == compiler.HAND_TEMPLATED_GUIDE_CORPUS:
            if span_key not in geometry:
                raise RuntimeError(
                    "the K-5 geometry scan and the compiler's span reader disagree about "
                    f"{span.code}/{span.position}"
                )
            crossings, column_cut = geometry[span_key]
            geometry_evidence = [
                f"column_cut({column_cut})",
                f"page_boundary_crossings({crossings})",
            ]
        elif span.source_corpus == compiler.DOCLING_GUIDE_CORPUS:
            if span_key in geometry:
                raise RuntimeError(
                    "Docling span unexpectedly carries K-5 geometry: "
                    f"{span.code}/{span.position}"
                )
            geometry_evidence = [
                "column_cut(not_applicable(single_column_docling))",
                "page_boundary_crossings(not_applicable(no_page_footer_geometry))",
            ]
        else:
            raise RuntimeError(
                "student task span carries an unsupported geometry corpus: "
                f"{span.code}/{span.position}/{span.source_corpus}"
            )
        evidence = [
            f"source({prolog_atom(span.source)}, "
            f"lines({span.heading_line}, {span.end_line}))",
            *geometry_evidence,
            *evidence,
        ]
        status = f"{REASON_KIND[reason]}({reason})"
        rows.append(
            (
                span.code,
                span.position,
                status,
                "[" + ", ".join(evidence) + "]",
                reason,
                grade,
            )
        )
        reason_counts[reason] += 1
        reason_grade_counts[(reason, grade)] += 1
        grade_spans[grade] += 1
        lesson_spans[span.code] += 1
        lesson_reason_counts[(span.code, reason)] += 1
        if REASON_KIND[reason] == "present":
            grade_resolved[grade] += 1
            lesson_resolved[span.code] += 1

    if parsed_span_count != len(decisions_by_span):
        raise RuntimeError(
            f"joined {parsed_span_count} spans against "
            f"{len(decisions_by_span)} span keys carrying compiler decisions"
        )
    emitted_candidates = sum(row[3].count("task_candidate(") for row in rows)
    if emitted_candidates != len(report["task_candidates"]):
        raise RuntimeError(
            f"{emitted_candidates} of {len(report['task_candidates'])} task candidates "
            "reached a span row"
        )
    if sum(reason_counts[reason] for reason in PARSED_REASONS) != parsed_span_count:
        raise RuntimeError("parsed spans carry a reason outside the parsed vocabulary")
    if not reason_counts["compiled_task_instance"]:
        raise RuntimeError("no span resolves to a compiled task instance")

    return {
        "rows": rows,
        "reason_counts": reason_counts,
        "reason_grade_counts": reason_grade_counts,
        "grade_spans": grade_spans,
        "grade_resolved": grade_resolved,
        "lesson_spans": lesson_spans,
        "lesson_resolved": lesson_resolved,
        "lesson_reason_counts": lesson_reason_counts,
        "readiness": readiness,
        "missing_only_task_evidence": missing_only_task_evidence,
        "compiler_decisions": len(report["task_candidates"]),
        "compiler_task_lessons": report["accepted_task_instance_lessons"],
        "guides": report["teacher_guides"],
    }


def primary_blocker(lesson: str, lesson_reason_counts: Counter) -> str:
    """The reason that accounts for most of a lesson's unresolved spans."""
    unresolved = [
        (count, -REASON_ORDER.index(reason), reason)
        for (code, reason), count in lesson_reason_counts.items()
        if code == lesson and REASON_KIND[reason] != "present"
    ]
    if not unresolved:
        return "none"
    return max(unresolved)[2]


def render_registry(root: Path = ROOT) -> tuple[str, dict[str, object]]:
    measured = build_rows(root)
    rows = measured["rows"]
    reason_counts: Counter[str] = measured["reason_counts"]
    lesson_reason_counts: Counter[tuple[str, str]] = measured["lesson_reason_counts"]
    missing_only = measured["missing_only_task_evidence"]

    status_counts: Counter[str] = Counter()
    for reason, count in reason_counts.items():
        status_counts[REASON_KIND[reason]] += count

    blocked_lessons: Counter[str] = Counter()
    for (lesson, reason), _count in lesson_reason_counts.items():
        if lesson in missing_only and REASON_KIND[reason] != "present":
            blocked_lessons[reason] += 1

    lines = [REGISTER.rstrip("\n"), ""]
    for lesson, position, status, evidence, _reason, _grade in rows:
        lines.append(
            f"task_span_receipt({prolog_atom(lesson)}, {position}, {status}, {evidence})."
        )

    lines.append("")
    lines.append(f"task_span_denominator(spans, {len(rows)}).")
    lines.append(f"task_span_denominator(lessons, {len(measured['lesson_spans'])}).")
    lines.append(f"task_span_denominator(teacher_guides, {measured['guides']}).")
    lines.append(
        "task_span_denominator(compiler_task_candidates, "
        f"{measured['compiler_decisions']})."
    )
    lines.append(
        "task_span_denominator(compiled_task_instance_lessons, "
        f"{measured['compiler_task_lessons']})."
    )

    lines.append("")
    for kind in STATUS_KINDS:
        lines.append(f"task_span_status_count({kind}, {status_counts[kind]}).")

    lines.append("")
    for reason in REASON_ORDER:
        lines.append(f"task_span_reason_kind({reason}, {REASON_KIND[reason]}).")

    lines.append("")
    for reason in REASON_ORDER:
        lines.append(f"task_span_reason_count({reason}, {reason_counts[reason]}).")

    lines.append("")
    for grade in sorted(measured["grade_spans"], key=lambda grade: (grade != "K", grade)):
        spans = measured["grade_spans"][grade]
        resolved = measured["grade_resolved"][grade]
        lines.append(
            f"task_span_grade_count({prolog_atom(grade)}, {spans}, "
            f"{resolved}, {spans - resolved})."
        )

    lines.append("")
    for reason in REASON_ORDER:
        for grade in sorted(measured["grade_spans"], key=lambda grade: (grade != "K", grade)):
            count = measured["reason_grade_counts"][(reason, grade)]
            if count:
                lines.append(
                    f"task_span_reason_grade_count({reason}, {prolog_atom(grade)}, {count})."
                )

    lines.append("")
    for lesson in sorted(measured["lesson_spans"]):
        readiness = measured["readiness"].get(lesson, "not_published")
        lines.append(
            f"lesson_task_span_rollup({prolog_atom(lesson)}, "
            f"{prolog_atom(grade_of(lesson))}, {measured['lesson_spans'][lesson]}, "
            f"{measured['lesson_resolved'][lesson]}, {prolog_atom(readiness)}, "
            f"{primary_blocker(lesson, lesson_reason_counts)})."
        )

    lines.append("")
    for lesson, reason in sorted(
        lesson_reason_counts, key=lambda key: (key[0], REASON_ORDER.index(key[1]))
    ):
        lines.append(
            f"lesson_task_span_reason_count({prolog_atom(lesson)}, {reason}, "
            f"{lesson_reason_counts[(lesson, reason)]})."
        )

    lines.append("")
    for lesson in sorted(missing_only):
        lines.append(f"lesson_missing_only_task_evidence({prolog_atom(lesson)}).")

    lines.append("")
    ranked = sorted(
        blocked_lessons.items(), key=lambda item: (-item[1], REASON_ORDER.index(item[0]))
    )
    for rank, (reason, count) in enumerate(ranked, 1):
        lines.append(f"task_span_reason_queue({rank}, {reason}, {count}).")

    lines.append(RULES_BLOCK)
    measured["status_counts"] = status_counts
    measured["blocked_lessons"] = blocked_lessons
    return "\n".join(lines), measured


def summary(output: Path, measured: dict[str, object], checked: bool) -> str:
    reason_counts: Counter[str] = measured["reason_counts"]
    blocked: Counter[str] = measured["blocked_lessons"]
    resolved = sum(reason_counts[reason] for reason in REASON_ORDER if REASON_KIND[reason] == "present")
    total = len(measured["rows"])
    location = output.relative_to(ROOT) if output.is_relative_to(ROOT) else output
    top = ", ".join(
        f"{reason}={count}"
        for reason, count in sorted(
            blocked.items(), key=lambda item: (-item[1], REASON_ORDER.index(item[0]))
        )[:3]
    )
    return (
        f"task span absence registry {'current' if checked else 'written'}: {location}; "
        f"spans={total}; lessons={len(measured['lesson_spans'])}; "
        f"resolved={resolved}; unresolved={total - resolved}; "
        f"lessons_missing_only_task_evidence={len(measured['missing_only_task_evidence'])}; "
        f"reason_queue={top}"
    )


def check_output(expected: str, output: Path) -> int:
    actual = output.read_text(encoding="utf-8") if output.is_file() else ""
    if actual == expected:
        return 0
    with tempfile.NamedTemporaryFile("w", encoding="utf-8", suffix=".pl", delete=False) as temporary:
        temporary.write(expected)
        temporary_path = Path(temporary.name)
    diff = list(
        difflib.unified_diff(
            actual.splitlines(),
            expected.splitlines(),
            fromfile=str(output),
            tofile=str(temporary_path),
            lineterm="",
        )
    )
    print(
        "task span absence registry is stale; run "
        "python3 scripts/extract_task_span_absence_registry.py",
        file=sys.stderr,
    )
    for line in diff[:12]:
        print(line, file=sys.stderr)
    temporary_path.unlink(missing_ok=True)
    return 1


def validate_tracked_output(output: Path) -> None:
    if not output.is_file():
        raise RuntimeError(f"tracked registry is absent: {output}")
    quoted = str(output).replace("'", "''")
    goal = (
        f"load_files('{quoted}',[silent(true)]),"
        "task_span_absence_registry:task_span_denominator(spans,Spans),"
        "aggregate_all(count,task_span_absence_registry:task_span_receipt(_,_,_,_),Spans),"
        "findall(C,task_span_absence_registry:task_span_status_count(_,C),Cs),"
        "sum_list(Cs,Spans),"
        "forall(task_span_absence_registry:task_span_receipt(_,_,Status,Evidence),"
        "(compound(Status),is_list(Evidence))),halt"
    )
    completed = subprocess.run(
        ["swipl", "-q", "-g", goal],
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode:
        raise RuntimeError(
            "tracked task-span registry failed load or denominator checks: "
            + (completed.stderr or completed.stdout).strip()
        )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="fail if the registry is stale")
    parser.add_argument("--output", type=Path, default=OUTPUT, help=argparse.SUPPRESS)
    arguments = parser.parse_args()
    output = arguments.output if arguments.output.is_absolute() else ROOT / arguments.output
    if arguments.check and not DOCLING_GUIDES.is_dir():
        validate_tracked_output(output)
        print(
            "SKIP task span absence registry re-derivation: "
            "hermes/app/runtime/experiments/gemma4_tutor/docling/full-output/"
            "TeacherLessonGuides absent locally (docling full-output); "
            "tracked registry loads and its row and status denominators reconcile"
        )
        return 0
    rendered, measured = render_registry()
    if arguments.check:
        result = check_output(rendered, output)
        if result == 0:
            print(summary(output, measured, True))
        return result
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(rendered, encoding="utf-8")
    print(summary(output, measured, False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
