#!/usr/bin/env python3
"""Classify every readable K-5 IM lesson with no live task candidate.

The instrument reruns the guide reader and candidate extractor, proves its
population against the capability census, and retains every extracted span.
Only student-task span text participates in classification.
"""

from __future__ import annotations

import argparse
from collections import Counter, defaultdict
import json
from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parents[2]
if not ROOT.is_absolute():
    raise SystemExit("build_im_zero_candidate_triage.py: root is not absolute")
sys.path.insert(0, str(ROOT / "scripts" / "curriculum"))

import build_im_lesson_capability_census as census  # noqa: E402
import compile_action_mappings as compiler  # noqa: E402


OUTPUT = ROOT / "data/learningcommons/derived/im_zero_candidate_triage.json"
CENSUS = ROOT / "data/learningcommons/derived/im_lesson_capability_census.json"
SCHEMA = "im_zero_candidate_triage_v1"
EXPECTED = 581
K5 = {"K", "1", "2", "3", "4", "5"}

# Evidence grammar, not a promotion grammar. It includes forms deliberately
# outside the live whole-number candidate extractor: decimals and answer slots.
NUMERAL = r"(?:\d{1,3}(?:,\d{3})+|\d+)(?:\.\d+)?(?:\s+\d+/\d+|/\d+)?"
UNKNOWN = r"(?:\?+|_{2,}|□)"
OPERAND = rf"(?:{NUMERAL}|{UNKNOWN})"
COMPUTATION_RE = re.compile(
    rf"(?<![\d./])(?P<left>{OPERAND})\s*(?P<symbol>[+\-−×·÷])\s*"
    rf"(?P<right>{OPERAND})(?:\s*=\s*(?P<result>{OPERAND}))?",
    re.IGNORECASE,
)
EQUALITY_RE = re.compile(
    rf"(?<![\d./])(?P<left>{OPERAND})\s*=\s*(?P<right>{OPERAND})(?![\d./])",
    re.IGNORECASE,
)
ITEM_RE = re.compile(r"(?:(?<=^)|(?<=\s))\d+\.(?=\s)")
QUANTITY_RE = re.compile(
    r"(?<![A-Za-z])(?:\$\s*)?\d[\d,]*(?:\.\d+)?(?:\s+\d+/\d+|/\d+)?"
)
QUESTION_RE = re.compile(
    r"(?:How many|How much|How far|How long|How tall|How wide|"
    r"What is (?:the )?(?:total|difference|sum|product|quotient|value|cost|"
    r"area|perimeter|volume)|Find (?:the )?(?:total|difference|sum|product|"
    r"quotient|value|cost|area|perimeter|volume))[^?]{0,220}\?",
    re.IGNORECASE,
)
RELATION_RE = re.compile(
    r"\b(?:more|fewer|less|left|remain(?:s|ing)?|altogether|total|each|"
    r"equal(?:ly)?|groups?|shared?|join(?:s|ed)?|adds?|added|put|takes?|took|"
    r"gives?|gave|buys?|bought|sells?|sold|costs?|times as many|difference|"
    r"in all|same number|both|together|finds?|found)\b",
    re.IGNORECASE,
)
BOUNDARY_RE = re.compile(
    r"(?:What do you notice\?|What do you wonder\?|Which \d+ go together\?|"
    r"Choose a center\.)",
    re.IGNORECASE,
)

DOMAINS = (
    (
        "fraction_model_reasoning",
        re.compile(
            r"\b(?:fraction|numerator|denominator|shaded region|partition|"
            r"equal parts|equivalent fractions?|unit fraction)\b",
            re.IGNORECASE,
        ),
    ),
    (
        "data_representation_or_question",
        re.compile(
            r"\b(?:bar graph|picture graph|line plot|graph|survey|data|chart|"
            r"table|dot plot)\b",
            re.IGNORECASE,
        ),
    ),
    (
        "geometry_construction_or_measure",
        re.compile(
            r"\b(?:shape|rectangle|triangle|quadrilateral|polygon|angle|"
            r"symmetr|parallel|perpendicular|area|perimeter|volume|prism|"
            r"unit cubes?|rectangular prism|coordinate|ray|line segment|"
            r"side length|square tile|geometric figures?)\b",
            re.IGNORECASE,
        ),
    ),
    (
        "measurement_task",
        re.compile(
            r"\b(?:measure|measurement|length|weight|mass|capacity|distance|"
            r"elapsed time|clock|inch|feet|foot|yard|meter|centimeter|liter|"
            r"gram|kilogram|minute|hour|money|coins?|cents?)\b",
            re.IGNORECASE,
        ),
    ),
    (
        "counting_place_value_or_comparison",
        re.compile(
            r"\b(?:count|how many do you see|more or fewer|greater than|"
            r"less than|place value|base-ten|tens and ones|compare the numbers|"
            r"number line|number pattern|sequence|least to greatest)\b",
            re.IGNORECASE,
        ),
    ),
)
DOMAIN_ACTION_RE = re.compile(
    r"\b(?:draw|construct|build|compose|decompose|partition|measure|represent|"
    r"create|make|sort|classify|compare|record|plot|graph|shade|fold|name|"
    r"describe|explain|decide|determine|find|complete|show|solve|write|circle|"
    r"order|locate|label)\b",
    re.IGNORECASE,
)
MISSING_PROMPT_RE = re.compile(
    r"\b(?:find the value of (?:each |the )?(?:expression|sum|difference|"
    r"product|quotient)|find the number that makes each equation true|"
    r"complete each equation|write an equation|match each expression|"
    r"find the number that makes the equation true)\b",
    re.IGNORECASE,
)
GAME_RE = re.compile(
    r"\b(?:choose a center|play (?:a round|a game|with your partner)|"
    r"shake and spill|choose 1 object|take turns|flip a card|roll|"
    r"spin the spinner|card sort|sort the cards|"
    r"your teacher will give you (?:a set of )?cards|choose numbers? .*fill in "
    r"the blanks)\b",
    re.IGNORECASE,
)
DISCUSSION_RE = re.compile(
    r"\b(?:what do you notice|what do you wonder|what do you know about|"
    r"discuss with your partner|be prepared to explain|which one does not "
    r"belong|would you rather)\b",
    re.IGNORECASE,
)
ESTIMATION_RE = re.compile(
    r"\b(?:record an estimate|make an estimate|estimate that is|"
    r"too low\s+about right|approximately)\b",
    re.IGNORECASE,
)
OPEN_INPUT_RE = re.compile(
    r"(?:\bsome\b[^?]{0,120}\bhow many\b[^?]*\?[^?]{0,40}\bhow many\b|"
    r"has squares and triangles[^?]*\bhow many squares\b[^?]*\?[^?]*"
    r"\bhow many triangles\b|_{3,}[^.]{0,160}\bchoose numbers?\b)",
    re.IGNORECASE,
)

FIXES = {
    "binary_expression_in_broader_prompt": (
        'Generalize beyond the exact "Find the value of A op B." sentence to '
        "lists and true-or-false prompts."
    ),
    "unknown_value_equation": (
        "Read equations with a question mark, blank, or box in an operand or "
        "result position."
    ),
    "decimal_expression": (
        "Tokenize printed decimals without slicing their integer parts."
    ),
    "fraction_expression": (
        "Use the fraction operand reader in the omitted prompt contexts."
    ),
    "compound_or_relational_expression": (
        "Segment equalities, inequalities, and multi-operation statements safely."
    ),
    "narrative_quantity_relation": (
        "Read fixed narrative operands and the requested quantity from one span."
    ),
}


def fail(message: str) -> "NoReturn":
    raise SystemExit(f"build_im_zero_candidate_triage.py: {message}")


def load(path: Path) -> object:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        fail(f"cannot read {path}: {exc}")


def parts(lesson: str) -> tuple[str, int, int]:
    match = compiler.CODE_RE.fullmatch(lesson)
    if match is None:
        fail(f"invalid lesson id: {lesson}")
    return match.group(1), int(match.group(2)), int(match.group(3))


def lesson_key(lesson: str) -> tuple[int, int, int]:
    grade, unit, number = parts(lesson)
    return 0 if grade == "K" else int(grade), unit, number


def around(text: str, start: int, end: int, radius: int = 230) -> str:
    left, right = max(0, start - radius), min(len(text), end + radius)
    excerpt = text[left:right].strip()
    if left and " " in excerpt:
        excerpt = excerpt.split(" ", 1)[1]
    if right < len(text) and " " in excerpt:
        excerpt = excerpt.rsplit(" ", 1)[0]
    return excerpt


def cite(span: compiler.StudentTaskSpan, excerpt: str, kind: str) -> dict:
    if excerpt not in span.text:
        fail(f"non-verbatim evidence in {span.code}/{span.position}")
    lines = [
        line
        for line, text in span.lines
        if excerpt and (text in excerpt or excerpt in text)
    ]
    return {
        "kind": kind,
        "source": span.source,
        "line": min(lines) if lines else span.heading_line,
        "end_line": max(lines) if lines else span.end_line,
        "position": span.position,
        "excerpt": excerpt,
    }


def computation_class(text: str, match: re.Match[str]) -> str:
    value = match.group(0)
    if re.search(r"\d+\.\d+", value):
        return "decimal_expression"
    if "/" in value:
        return "fraction_expression"
    if re.search(UNKNOWN, value, re.IGNORECASE):
        return "unknown_value_equation"
    window = around(text, match.start(), match.end(), 100)
    if re.search(r"[<>=]", window) or len(list(COMPUTATION_RE.finditer(window))) > 1:
        return "compound_or_relational_expression"
    return "binary_expression_in_broader_prompt"


def printed(spans: list[compiler.StudentTaskSpan]) -> tuple[str, dict] | None:
    for span in spans:
        match = COMPUTATION_RE.search(span.text)
        if match:
            return computation_class(span.text, match), cite(
                span,
                around(span.text, match.start(), match.end()),
                "printed_computation",
            )
        match = EQUALITY_RE.search(span.text)
        if match:
            return "compound_or_relational_expression", cite(
                span,
                around(span.text, match.start(), match.end()),
                "printed_computation",
            )
    return None


def narrative(spans: list[compiler.StudentTaskSpan]) -> tuple[str, dict] | None:
    """Require a question, two fixed quantities, and an explicit relation."""
    for span in spans:
        for question in QUESTION_RE.finditer(span.text):
            start = max(0, question.start() - 520)
            for boundary in BOUNDARY_RE.finditer(span.text[start : question.start()]):
                start = start + boundary.end()
            passage = span.text[start : question.end()].strip()
            normalized = ITEM_RE.sub(" ", passage)
            if (
                len(list(QUANTITY_RE.finditer(normalized))) < 2
                or RELATION_RE.search(normalized) is None
            ):
                continue
            for domain, pattern in DOMAINS[:4]:
                if pattern.search(normalized[-420:]):
                    return domain, cite(
                        span, passage, "fixed_non_arithmetic_task"
                    )
            return "narrative_quantity_relation", cite(
                span, passage, "printed_computation"
            )
    return None


def recovered(
    lesson: str,
    by_lesson: dict[str, list[compiler.StudentTaskSpan]],
) -> tuple[str, dict] | None:
    if not by_lesson.get(lesson):
        return None
    span = by_lesson[lesson][0]
    match = COMPUTATION_RE.search(span.text) or EQUALITY_RE.search(span.text)
    if match is None:
        return None
    excerpt = around(span.text, match.start(), match.end())
    return "sidecar_recovered_computation", cite(
        span, excerpt, "recovered_computation"
    )


def missing(spans: list[compiler.StudentTaskSpan]) -> tuple[str, dict] | None:
    for span in spans:
        prompt = MISSING_PROMPT_RE.search(span.text)
        if prompt:
            return "unrecovered_computation_layout", cite(
                span,
                around(span.text, prompt.start(), prompt.end()),
                "missing_layout_content",
            )
    return None


def domain_task(spans: list[compiler.StudentTaskSpan]) -> tuple[str, dict] | None:
    for span in spans:
        if DOMAIN_ACTION_RE.search(span.text) is None:
            continue
        for domain, pattern in DOMAINS:
            match = pattern.search(span.text)
            if match:
                return domain, cite(
                    span,
                    around(span.text, match.start(), match.end()),
                    "fixed_non_arithmetic_task",
                )
    return None


def residual(spans: list[compiler.StudentTaskSpan]) -> tuple[str, dict]:
    joined = " ".join(span.text for span in spans).strip()
    if not joined:
        return "empty_extracted_span", cite(
            spans[0], "", "indeterminate_source_text"
        )
    for name, pattern, kind in (
        ("center_or_game_generated_input", GAME_RE, "generated_input_routine"),
        (
            "learner_chosen_or_multiple_solution_input",
            OPEN_INPUT_RE,
            "generated_input_routine",
        ),
        ("discussion_or_notice_routine", DISCUSSION_RE, "discussion_routine"),
        ("estimation_or_comparison_routine", ESTIMATION_RE, "estimation_routine"),
    ):
        for span in spans:
            match = pattern.search(span.text)
            if match:
                return name, cite(
                    span, around(span.text, match.start(), match.end()), kind
                )
    span = max(spans, key=lambda item: len(item.text))
    return "open_response_or_source_ambiguous", cite(
        span, span.text[:500].strip(), "indeterminate_source_text"
    )


def classify(
    lesson: str,
    spans: list[compiler.StudentTaskSpan],
    recovered_by_lesson: dict[str, list[compiler.StudentTaskSpan]],
) -> tuple[str, str, dict]:
    result = printed(spans)
    if result:
        return "parser_gap", *result
    result = narrative(spans)
    if result:
        if result[0] in {name for name, _ in DOMAINS}:
            return "non_arithmetic_mathematical_task", *result
        return "parser_gap", *result
    result = recovered(lesson, recovered_by_lesson)
    if result:
        return "source_representation_gap", *result
    result = missing(spans)
    if result:
        return "source_representation_gap", *result
    result = domain_task(spans)
    if result:
        return "non_arithmetic_mathematical_task", *result
    result = domain_task(recovered_by_lesson.get(lesson, []))
    if result:
        return "non_arithmetic_mathematical_task", *result
    result = residual(spans)
    if result[0] in {"empty_extracted_span", "open_response_or_source_ambiguous"}:
        return "indeterminate", *result
    return "no_fixed_computable_task", *result


def description(name: str) -> str:
    return {
        "parser_gap": (
            "The tracked span prints fixed operands and a requested computation, "
            "but the live extractor emits no candidate."
        ),
        "source_representation_gap": (
            "Tracked markdown omits a named computation, or the checked sidecar "
            "restores a computation that the tracked span dropped."
        ),
        "non_arithmetic_mathematical_task": (
            "The span carries fixed mathematical work outside the arithmetic "
            "candidate extractor's task grammar."
        ),
        "no_fixed_computable_task": (
            "The spans carry discussion, estimation, center, or game work whose "
            "inputs are supplied in classroom activity rather than fixed in text."
        ),
        "indeterminate": (
            "The source text does not preserve enough of the student task for a "
            "supported classification."
        ),
    }[name]


def build() -> dict:
    census_doc = load(CENSUS)
    if census_doc.get("schema") != "im_lesson_capability_census_v1":
        fail("unexpected capability census schema")
    census_rows = {row["lesson"]: row for row in census_doc["lessons"]}
    expected_ids = {
        lesson
        for lesson, row in census_rows.items()
        if row["grade"] in K5
        and row["memberships"]["readable"]
        and not row["memberships"]["has_candidates"]
    }
    if len(expected_ids) != EXPECTED:
        fail(f"census target is {len(expected_ids)}, expected {EXPECTED}")

    docs, _ = census.source_corpus()
    tracked, candidates, _ = census.candidate_corpus(docs)
    candidate_ids = {candidate.code for candidate in candidates}
    live_zero = {
        doc.code
        for doc in docs
        if parts(doc.code)[0] in K5 and doc.code not in candidate_ids
    }
    if live_zero != expected_ids:
        fail(
            "live zero-candidate population disagrees with census: "
            f"live_only={sorted(live_zero - expected_ids, key=lesson_key)} "
            f"census_only={sorted(expected_ids - live_zero, key=lesson_key)}"
        )

    tracked_by_lesson: dict[str, list[compiler.StudentTaskSpan]] = defaultdict(list)
    for span in tracked:
        if span.code in expected_ids:
            tracked_by_lesson[span.code].append(span)
    if set(tracked_by_lesson) != expected_ids:
        fail("reader did not return spans for every target lesson")

    recovered_by_lesson: dict[str, list[compiler.StudentTaskSpan]] = defaultdict(list)
    for span in compiler.read_recovered_task_spans(ROOT, tracked):
        if span.code in expected_ids:
            recovered_by_lesson[span.code].append(span)

    rows = []
    for lesson in sorted(expected_ids, key=lesson_key):
        spans = tracked_by_lesson[lesson]
        class_name, subclass, witness = classify(
            lesson, spans, recovered_by_lesson
        )
        census_row = census_rows[lesson]
        rows.append(
            {
                "lesson": lesson,
                "grade": census_row["grade"],
                "class": class_name,
                "subclass": subclass,
                "class_description": description(class_name),
                "evidence": witness,
                "current": {
                    "candidate_count": 0,
                    "executable_task": census_row["memberships"]["executable_task"],
                },
                "tracked_spans": [
                    {
                        "source": span.source,
                        "heading_line": span.heading_line,
                        "end_line": span.end_line,
                        "position": span.position,
                        "text": span.text,
                    }
                    for span in spans
                ],
                "recovered_spans": [
                    {
                        "source": span.source,
                        "position": span.position,
                        "text": span.text,
                    }
                    for span in recovered_by_lesson.get(lesson, [])
                ],
            }
        )

    classes = Counter(row["class"] for row in rows)
    subclasses: dict[str, Counter] = defaultdict(Counter)
    for row in rows:
        subclasses[row["class"]][row["subclass"]] += 1
    if (
        len(rows) != EXPECTED
        or sum(classes.values()) != EXPECTED
        or len({row["lesson"] for row in rows}) != EXPECTED
    ):
        fail("classification is not a unique, exhaustive 611-row partition")

    parser_rows = [row for row in rows if row["class"] == "parser_gap"]
    ranking = []
    for rank, (subclass, count) in enumerate(
        sorted(
            Counter(row["subclass"] for row in parser_rows).items(),
            key=lambda item: (-item[1], item[0]),
        ),
        1,
    ):
        selected = [row for row in parser_rows if row["subclass"] == subclass]
        ranking.append(
            {
                "rank": rank,
                "fix": subclass,
                "lessons": count,
                "currently_executable": sum(
                    row["current"]["executable_task"] for row in selected
                ),
                "not_currently_executable": sum(
                    not row["current"]["executable_task"] for row in selected
                ),
                "change_required": FIXES[subclass],
                "lesson_ids": [row["lesson"] for row in selected],
            }
        )

    spot_rows = [
        row
        for row in parser_rows
        if row["evidence"]["kind"] == "printed_computation"
        and COMPUTATION_RE.search(row["evidence"]["excerpt"])
    ][:10]
    if len(spot_rows) != 10:
        fail("cannot produce ten parser-gap computation spot checks")
    spots = []
    for row in spot_rows:
        match = COMPUTATION_RE.search(row["evidence"]["excerpt"])
        spots.append(
            {
                "lesson": row["lesson"],
                "expression": (
                    f"{match.group('left')} {match.group('symbol')} "
                    f"{match.group('right')}"
                ),
                "source": row["evidence"]["source"],
                "line": row["evidence"]["line"],
                "position": row["evidence"]["position"],
                "excerpt": row["evidence"]["excerpt"],
                "verified": True,
            }
        )

    band = census_doc["cuts"]["by_grade_band"]["K-5"]["counts"]
    confirmed_classes = {
        "parser_gap",
        "source_representation_gap",
        "non_arithmetic_mathematical_task",
    }
    confirmed_zero = sum(row["class"] in confirmed_classes for row in rows)
    zero_candidate_executable = sum(
        row["current"]["executable_task"] for row in rows
    )
    confirmed_ceiling = band["has_candidates"] + confirmed_zero
    possible_ceiling = confirmed_ceiling + classes["indeterminate"]
    examples = {}
    for name in sorted(classes):
        row = next(row for row in rows if row["class"] == name)
        examples[name] = {
            "lesson": row["lesson"],
            "subclass": row["subclass"],
            **row["evidence"],
        }

    return {
        "schema": SCHEMA,
        "generated_by": "scripts/curriculum/build_im_zero_candidate_triage.py",
        "register": (
            "Exhaustive span-text triage of readable K-5 lessons for which the "
            "live candidate extractor returns no candidate. Each row retains all "
            "tracked spans and one verbatim classification witness."
        ),
        "sources": {
            "root_resolution": "Path(__file__).resolve().parents[2]",
            "capability_census": str(CENSUS.relative_to(ROOT)),
            "teacher_guides": str(compiler.GUIDE_ROOT.relative_to(ROOT)),
            "recovered_task_spans": str(
                compiler.RECOVERED_TASK_SPANS.relative_to(ROOT)
            ),
        },
        "population_check": {
            "expected": EXPECTED,
            "classified": len(rows),
            "live_extractor_rerun_lessons": len(expected_ids),
            "live_extractor_candidates": 0,
            "duplicate_lessons": 0,
            "unclassified_lessons": 0,
            "method": (
                "Absolute-root guide read, live tracked-plus-recovered candidate "
                "extraction, and exact membership comparison with the census."
            ),
        },
        "summary": {
            "class_counts": dict(sorted(classes.items())),
            "subclass_counts": {
                name: dict(sorted(counts.items()))
                for name, counts in sorted(subclasses.items())
            },
            "class_examples": examples,
            "parser_fix_ranking": ranking,
            "honest_ceiling": {
                "k5_identity_spine": 879,
                "has_candidates_today": band["has_candidates"],
                "executable_today": band["executable_task"],
                "zero_candidate_lessons_executable_today": (
                    zero_candidate_executable
                ),
                "confirmed_zero_candidate_lessons_with_fixed_tasks": confirmed_zero,
                "confirmed_zero_candidate_lessons_without_fixed_tasks": (
                    classes["no_fixed_computable_task"]
                ),
                "confirmed_maximum_executable_task_lessons": confirmed_ceiling,
                "possible_maximum_including_indeterminate": possible_ceiling,
                "indeterminate_lessons": classes["indeterminate"],
                "gap_from_executable_today_to_confirmed_maximum": (
                    confirmed_ceiling - band["executable_task"]
                ),
                "statement": (
                    f"{confirmed_ceiling} K-5 lessons are confirmed to carry a "
                    f"fixed task or current candidate; {possible_ceiling} is the "
                    f"upper bound if all {classes['indeterminate']} indeterminate "
                    f"lessons carry one. Hermes executes {band['executable_task']} "
                    "K-5 lessons today."
                ),
            },
        },
        "verification": {
            "class_count_sum": sum(classes.values()),
            "unique_lessons": len({row["lesson"] for row in rows}),
            "parser_gap_printed_computation_spot_checks": spots,
        },
        "lessons": rows,
    }


def render(payload: dict) -> str:
    return json.dumps(payload, indent=1, ensure_ascii=False, sort_keys=True) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--output", type=Path, default=OUTPUT)
    args = parser.parse_args()

    payload = build()
    rendered = render(payload)
    if args.check:
        current = (
            args.output.read_text(encoding="utf-8")
            if args.output.exists()
            else ""
        )
        if current != rendered:
            print(
                "stale IM zero-candidate triage: run "
                "scripts/curriculum/build_im_zero_candidate_triage.py",
                file=sys.stderr,
            )
            return 1
    else:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(rendered, encoding="utf-8")

    summary = payload["summary"]
    print(
        "im_zero_candidate_triage "
        + " ".join(
            f"{name}={count}"
            for name, count in summary["class_counts"].items()
        )
        + f" total={payload['population_check']['classified']}"
        + f" executable_today={summary['honest_ceiling']['executable_today']}"
        + f" confirmed_ceiling="
        f"{summary['honest_ceiling']['confirmed_maximum_executable_task_lessons']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
