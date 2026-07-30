#!/usr/bin/env python3
"""Generate the census of stalled sidecar equations outside named lanes.

The survey population follows task 197's complete-equation test so movement in
that baseline remains measurable.  Each row also runs the stricter maximal
equation segmenter.  Keeping both readings makes false joins across flattened
sidecar items visible instead of silently treating them as equations.
"""

from __future__ import annotations

import argparse
from collections import Counter
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts" / "curriculum"))

import compile_action_mappings as compiler  # noqa: E402
import equation_verification as eqv  # noqa: E402

OUTPUT = ROOT / "scripts" / "curriculum" / "sidecar_other_equation_census.json"
SCHEMA = "sidecar_other_equation_census_v2"

COMPLETE_EQUATION_TEST_RE = re.compile(
    r"(?<![\d,./])\d+\s*[-−+×·÷]\s*\d+\s*=\s*\d+(?![\d,./])"
)

EQUATION_MATCHING_RULES = (
    re.compile(r"\bcircle\s+\d+\s+equations?\s+that\s+match\b", re.IGNORECASE),
    re.compile(r"\bwhich\s+group\s+of\s+equations\s+matches\b", re.IGNORECASE),
    re.compile(
        r"\bcircle\s+the\s+equation\s+each\s+number\s+line\s+represents\b",
        re.IGNORECASE,
    ),
)

LEFT_BLANK_EXPRESSION_RE = re.compile(
    rf"(?<!\d)(?P<item>\d+)\.\s*"
    rf"(?P<equation>=\s*{compiler.ARITHMETIC_NUMERAL}\s*"
    rf"[+\-−×·÷]\s*{compiler.ARITHMETIC_NUMERAL})(?![\d,])"
)


def stalled_bucket(text: str) -> str:
    if eqv.ROUTINE_PROMPT_RE.search(text):
        return "true_or_false"
    if re.search(r"\bfind the number that makes each equation true\b", text, re.I):
        return "missing_number"
    if any(rule.search(text) for rule in EQUATION_MATCHING_RULES):
        return "equation_matching"
    return "other_prompt_shape"


def prompt_class(text: str) -> str:
    rules = (
        (
            "notice_or_wonder_about_equations",
            r"\bwhat do you notice\?\s+what do you wonder\?",
        ),
        (
            "generate_problem_from_equation_or_work",
            r"\bwhat(?:'s| is) the question\b|\bwrite (?:a|new) (?:story problem|question)\b|"
            r"\bwrite a question that could be answered\b",
        ),
        (
            "select_or_place_equation_for_representation",
            r"\bcircle the \d+ equations that are true\b|"
            r"\bwhich equations go with each drawing\b|"
            r"\bpaste each equation next to the number line\b|"
            r"\bcircle the way you prefer\b",
        ),
        (
            "analyze_error_or_correctness",
            r"\bexplain .+ error\b|\bdid (?:she|he) find the correct value\b|"
            r"\bdo you agree\b",
        ),
        (
            "compare_shown_methods_or_work",
            r"\bcompare\b|\bwhat(?:'s| is) different\b|\bwhat(?:'s| is) the same\b|"
            r"\bmethods alike\b|\bways? to find\b",
        ),
        (
            "continue_or_use_partial_calculation",
            r"\bstarted by writing this equation\b|\btry .+ way\b|"
            r"\bshow what .+ could do to finish\b",
        ),
        (
            "justify_printed_equation",
            r"\bshow that each equation is true\b|\bequations? (?:that are|is) true\b",
        ),
        (
            "equation_grid_without_prompt",
            r"^\s*(?:•\s*)?\d+\s*[-−+×·÷=]",
        ),
        (
            "interpret_shown_work",
            r".*",
        ),
    )
    for name, pattern in rules:
        if re.search(pattern, text, re.IGNORECASE):
            return name
    raise AssertionError("fallback prompt class did not match")


def extractor_refusals(text: str) -> list[dict[str, str]]:
    refusals = [
        {
            "extractor_family": "printed_equation_list_fullmatch",
            "reason": "sidecar_pseudo_span_has_one_prompt_line_not_equation_only_lines",
        }
    ]
    list_prompt = re.search(
        r"\bFind the value of each (?:product|quotient|difference|sum|expression)\b",
        text,
        re.IGNORECASE,
    )
    if list_prompt is None:
        refusals.append(
            {
                "extractor_family": "direct_expression_list",
                "reason": "required_find_the_value_of_each_prompt_absent",
            }
        )
    else:
        if not re.search(r"\bmentally\b", text, re.IGNORECASE):
            refusals.append(
                {
                    "extractor_family": "direct_expression_list",
                    "reason": "required_word_mentally_absent",
                }
            )
        equation_only_bullet = re.compile(
            rf"\s*{compiler.ARITHMETIC_NUMERAL}\s*"
            rf"[-−×·÷]\s*{compiler.ARITHMETIC_NUMERAL}\s*"
        )
        if not any(
            equation_only_bullet.fullmatch(item) for item in text.split("•")[1:]
        ):
            refusals.append(
                {
                    "extractor_family": "direct_expression_list",
                    "reason": "required_equation_only_bullet_items_absent",
                }
            )
    refusals.extend(
        [
            {
                "extractor_family": "recovered_equation_items",
                "reason": "required_which_3_go_together_prompt_absent",
            },
            {
                "extractor_family": "equation_verification",
                "reason": "required_true_or_false_routine_prompt_absent",
            },
        ]
    )
    return refusals


def build(root: pathlib.Path) -> dict:
    docs = compiler.read_teacher_guides(root)
    tracked = compiler.extract_student_task_spans(docs)
    recovered = compiler.read_recovered_task_spans(root, tracked)
    candidates = compiler.extract_task_candidates(recovered, {})
    candidate_keys = {
        (row.code, row.position.split("/", 1)[0]) for row in candidates
    }

    complete = [
        span for span in recovered if COMPLETE_EQUATION_TEST_RE.search(span.text)
    ]
    stalled = [
        span
        for span in complete
        if (span.code, span.position) not in candidate_keys
    ]
    buckets = Counter(stalled_bucket(span.text) for span in stalled)
    missing_number = [
        span for span in complete if stalled_bucket(span.text) == "missing_number"
    ]
    newly_candidate_missing = [
        span
        for span in missing_number
        if (span.code, span.position) in candidate_keys
    ]
    missing_number_prompts = [
        span
        for span in recovered
        if re.search(
            r"\bFind the number that makes each equation true\b",
            span.text,
            re.IGNORECASE,
        )
    ]
    out_of_scope_shapes = []
    for span in missing_number_prompts:
        for match in LEFT_BLANK_EXPRESSION_RE.finditer(span.text):
            out_of_scope_shapes.append(
                {
                    "class": "left_blank_equals_expression",
                    "lesson": span.code,
                    "position": span.position,
                    "source": span.source,
                    "item": int(match.group("item")),
                    "excerpt": match.group("equation"),
                    "disposition": "recorded_out_of_scope_no_fullmatch_parser",
                }
            )
    out_of_scope_shapes.sort(
        key=lambda row: (row["lesson"], row["position"], row["item"])
    )
    out_of_scope_class_counts = Counter(
        row["class"] for row in out_of_scope_shapes
    )
    pre_task_206_stalled = stalled + newly_candidate_missing
    rows = []
    for span in stalled:
        if stalled_bucket(span.text) != "other_prompt_shape":
            continue
        maximal = eqv.find_equations(span.lines)
        rows.append(
            {
                "lesson": span.code,
                "position": span.position,
                "source": span.source,
                "prompt_class": prompt_class(span.text),
                "prompt": span.text,
                "printed_equations": [
                    match.group(0)
                    for match in COMPLETE_EQUATION_TEST_RE.finditer(span.text)
                ],
                "maximal_equations": [row[0] for row in maximal],
                "extractor_refusals": extractor_refusals(span.text),
            }
        )
    rows.sort(key=lambda row: (row["lesson"], row["position"]))
    if len(rows) != 23:
        raise SystemExit(
            f"sidecar other-prompt census moved: expected 23 rows, found {len(rows)}"
        )
    class_counts = Counter(row["prompt_class"] for row in rows)
    return {
        "schema": SCHEMA,
        "register": (
            "Every stalled sidecar span outside the True-or-False, equation-"
            "matching, and missing-number lanes. Printed-equation matches retain "
            "the task-197 survey test; maximal_equations records the stricter "
            "whole-equation reading so flattened cross-item joins remain visible."
        ),
        "summary": {
            "recovered_spans": len(recovered),
            "complete_equation_test_spans": len(complete),
            "complete_equation_test_lessons": len({span.code for span in complete}),
            "pre_task_206_stalled_spans": len(pre_task_206_stalled),
            "pre_task_206_stalled_lessons": len(
                {span.code for span in pre_task_206_stalled}
            ),
            "stalled_spans_after_task_206": len(stalled),
            "stalled_lessons_after_task_206": len({span.code for span in stalled}),
            "other_prompt_spans": len(rows),
            "missing_number_spans": len(missing_number),
            "missing_number_candidate_spans": len(newly_candidate_missing),
            "missing_number_withheld_spans": (
                len(missing_number) - len(newly_candidate_missing)
            ),
            "bucket_counts": dict(sorted(buckets.items())),
            "prompt_class_counts": dict(sorted(class_counts.items())),
            "out_of_scope_shape_counts": dict(
                sorted(out_of_scope_class_counts.items())
            ),
        },
        "out_of_scope_shapes": out_of_scope_shapes,
        "rows": rows,
    }


def render(payload: dict) -> str:
    return json.dumps(payload, indent=1, ensure_ascii=False, sort_keys=True) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--output", type=pathlib.Path, default=OUTPUT)
    args = parser.parse_args()

    payload = build(ROOT)
    rendered = render(payload)
    if args.check:
        current = args.output.read_text(encoding="utf-8") if args.output.exists() else ""
        if current != rendered:
            print(
                "stale sidecar equation census: run "
                "scripts/curriculum/build_sidecar_equation_census.py",
                file=sys.stderr,
            )
            return 1
    else:
        args.output.write_text(rendered, encoding="utf-8")
    summary = payload["summary"]
    print(
        "sidecar_equation_census "
        f"rows={summary['other_prompt_spans']} "
        f"complete_spans={summary['complete_equation_test_spans']} "
        f"stalled_spans={summary['stalled_spans_after_task_206']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
