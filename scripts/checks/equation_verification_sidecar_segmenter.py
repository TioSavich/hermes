#!/usr/bin/env python3
"""Check sidecar equation segmentation, refusals, witnesses, and operation glue."""

from __future__ import annotations

import argparse
import json
import pathlib
import re
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
CURRICULUM = ROOT / "scripts" / "curriculum"
FIXTURE = (
    ROOT
    / "scripts"
    / "checks"
    / "fixtures"
    / "equation_verification_sidecar_segmenter_controls.json"
)
sys.path.insert(0, str(CURRICULUM))

import build_sidecar_equation_census as census  # noqa: E402
import compile_action_mappings as compiler  # noqa: E402
import equation_verification as eqv  # noqa: E402


def corpus():
    rules = json.loads(compiler.DEFAULT_RULES.read_text(encoding="utf-8"))
    docs = compiler.read_teacher_guides(ROOT)
    explicit = compiler.read_explicit_mappings(ROOT)
    mappings = compiler.compile_rule_mappings(docs, rules, explicit)
    mappings += compiler.compile_scope_batches(
        rules, explicit, compiler.read_scope_titles(ROOT)
    )
    mappings = sorted(set(mappings))
    attachments = {code: set(rows) for code, rows in explicit.items()}
    for mapping in mappings:
        attachments.setdefault(mapping.code, set()).add(
            (mapping.operation, mapping.kind)
        )
    covered = set(explicit) | {mapping.code for mapping in mappings}
    tracked = compiler.extract_student_task_spans(docs)
    recovered = compiler.read_recovered_task_spans(ROOT, tracked)
    return docs, covered, attachments, tracked, recovered


def parsed_tasks(span: compiler.StudentTaskSpan) -> list[str]:
    return [
        item[2]
        for unit in compiler._recovered_printed_equation_units(span)
        for item in compiler._printed_equation_items(unit)
    ]


def check_constructed_controls(fixture: dict) -> None:
    recovered_source = str(compiler.RECOVERED_TASK_SPANS.relative_to(ROOT))
    for control in fixture["constructed_controls"]:
        span = compiler.StudentTaskSpan(
            "CONSTRUCTED",
            recovered_source,
            0,
            0,
            f"constructed_control({control['id']})",
            ((0, control["text"]),),
        )
        units = compiler._recovered_printed_equation_units(span)
        if units != control["expected_units"]:
            raise SystemExit(
                f"constructed segmenter control drift for {control['id']}: "
                f"{units!r} != {control['expected_units']!r}"
            )
        print(f"constructed segmenter control {control['id']}: units={units!r}")


def check_segmenter(fixture: dict, recovered: list[compiler.StudentTaskSpan]) -> None:
    by_key = {(span.code, span.position): span for span in recovered}
    admission = fixture["admission"]
    span = by_key[(admission["lesson"], admission["position"])]
    units = compiler._recovered_printed_equation_units(span)
    tasks = parsed_tasks(span)
    if units != admission["expected_units"] or tasks != admission["expected_tasks"]:
        raise SystemExit(
            f"sidecar admission drift: units={units!r} tasks={tasks!r}"
        )
    print(f"sidecar admission witnessed: units={len(units)} tasks={len(tasks)}")

    refusal = fixture["refusal"]
    refused_span = by_key[(refusal["lesson"], refusal["position"])]
    refused_units = compiler._recovered_printed_equation_units(refused_span)
    refused_tasks = parsed_tasks(refused_span)
    if (
        refused_units != refusal["expected_units"]
        or refused_tasks != refusal["expected_tasks"]
    ):
        raise SystemExit(
            f"sidecar refusing fixture drift: units={refused_units!r} "
            f"tasks={refused_tasks!r}"
        )
    print(
        "sidecar refusing fixture refused "
        f"{refusal['lesson']}/{refusal['position']}: {refusal['reason']}"
    )

    for regression in fixture["named_regressions"]:
        key = (regression["lesson"], regression["position"])
        regression_units = compiler._recovered_printed_equation_units(by_key[key])
        if "expected_units" in regression:
            if regression_units != regression["expected_units"]:
                raise SystemExit(
                    f"named segmenter regression drift at {key[0]}/{key[1]}: "
                    f"{regression_units!r} != {regression['expected_units']!r}"
                )
            quoted = regression_units
        else:
            missing = [
                unit
                for unit in regression["expected_contains"]
                if unit not in regression_units
            ]
            if missing:
                raise SystemExit(
                    f"named segmenter regression missing units at {key[0]}/{key[1]}: "
                    f"{missing!r}"
                )
            quoted = regression["expected_contains"]
        print(f"segmenter regression {key[0]}/{key[1]}: units={quoted!r}")

    excluded = {
        (admission["lesson"], admission["position"]),
        (refusal["lesson"], refusal["position"]),
    }
    held_out = [span for span in recovered if (span.code, span.position) not in excluded]
    spans_with_units = 0
    unit_count = 0
    parser_shaped = 0
    admitted = 0
    actual_units_by_span = []
    for held_span in held_out:
        held_units = compiler._recovered_printed_equation_units(held_span)
        parsed = [
            item
            for unit in held_units
            for item in compiler._printed_equation_items(unit)
        ]
        if held_units:
            spans_with_units += 1
            actual_units_by_span.append(
                {
                    "lesson": held_span.code,
                    "position": held_span.position,
                    "units": held_units,
                }
            )
        unit_count += len(held_units)
        parser_shaped += len(parsed)
        if re.search(
            r"\bFind the number that makes each equation true\b",
            held_span.text,
            re.IGNORECASE,
        ) and compiler.RECOVERED_COMPLETE_EQUATION_RE.search(held_span.text):
            admitted += len(parsed)
    actual = {
        "population_spans": len(held_out),
        "spans_with_units": spans_with_units,
        "units": unit_count,
        "parser_shaped_units": parser_shaped,
        "admitted_by_missing_number_entry": admitted,
    }
    expected = {
        key: value
        for key, value in fixture["held_out"].items()
        if key != "expected_units_by_span"
    }
    if actual != expected:
        raise SystemExit(
            f"held-out sidecar population drift: {actual!r} != "
            f"{expected!r}"
        )
    if actual_units_by_span != fixture["held_out"]["expected_units_by_span"]:
        raise SystemExit(
            "held-out sidecar unit-content drift: "
            f"{actual_units_by_span!r} != "
            f"{fixture['held_out']['expected_units_by_span']!r}"
        )
    print(
        "held-out segmenter population: "
        + " ".join(f"{key}={value}" for key, value in actual.items())
    )


def check_live_witnesses(
    docs, covered: set[str], attachments: dict[str, set[tuple[str, str]]]
) -> None:
    rows = compiler.validate_lesson_task_readings(
        ROOT, docs, covered, attachments
    )
    sidecar_rows = [
        row
        for row in rows
        if row["id"].startswith(("task_206_", "task_206fw_"))
    ]
    if len(sidecar_rows) != 10:
        raise SystemExit(
            f"expected 10 witnessed sidecar rows, found {len(sidecar_rows)}"
        )
    if any(row["witness_class"] != "printed_answer" for row in sidecar_rows):
        raise SystemExit("a sidecar row lost its printed-answer witness")
    print("sidecar live rows: accepted=10 printed_answer=10 withheld=1")


def check_equation_matching_refusal(
    fixture: dict, tracked: list[compiler.StudentTaskSpan]
) -> None:
    by_key = {(span.code, span.position): span for span in tracked}
    for row in fixture["equation_matching_refusals"]:
        span = by_key[(row["lesson"], row["position"])]
        if census.stalled_bucket(span.text) != "equation_matching":
            raise SystemExit(
                f"equation-matching control lost its prompt class: "
                f"{row['lesson']}/{row['position']}"
            )
        response_range = compiler._next_response_range(
            ROOT / span.source, span.heading_line
        )
        if response_range is None:
            raise SystemExit(
                f"equation-matching control has no response block: {row['lesson']}"
            )
        raw = (ROOT / span.source).read_text(
            encoding="utf-8", errors="replace"
        ).split("\n")
        response_lines = tuple(
            (number, raw[number - 1])
            for number in range(response_range[0] + 1, response_range[1] + 1)
        )
        if eqv.find_equations(response_lines):
            raise SystemExit(
                f"equation-matching response unexpectedly prints a selected "
                f"equation: {row['lesson']}/{row['position']}"
            )
        print(
            "equation-matching control refused "
            f"{row['lesson']}/{row['position']}: response names no selected equation"
        )


def check_operation_glue(
    fixture: dict,
    docs,
    covered: set[str],
    attachments: dict[str, set[tuple[str, str]]],
) -> None:
    readings = []
    for index, row in enumerate(fixture["operation_glue"], 1):
        if not any(
            operation == row["operation"]
            for operation, _ in attachments.get(row["lesson"], set())
        ):
            raise SystemExit(
                f"operation glue absent: {row['lesson']}/{row['operation']}"
            )
        readings.append(
            {
                **row,
                "id": f"task_206_operation_glue_{index}",
                "printed_answer": {
                    "absent": True,
                    "reason": (
                        "Gate probe only. The guide does not print the value of "
                        "this exact intermediate expression."
                    ),
                },
                "read_by": "task-206-route-probe",
            }
        )
    payload = {
        "schema": "lesson_task_readings_v1",
        "register": "Task 206 operation-route probe; no rows are compiled.",
        "readings": readings,
    }
    with tempfile.NamedTemporaryFile(
        "w", encoding="utf-8", suffix=".json", dir=ROOT
    ) as temporary:
        json.dump(payload, temporary)
        temporary.flush()
        accepted = compiler.validate_lesson_task_readings(
            ROOT, docs, covered, attachments, pathlib.Path(temporary.name)
        )
    if len(accepted) != 3:
        raise SystemExit(f"operation glue gate accepted {len(accepted)} of 3 probes")
    print(
        "operation glue route gate: accepted=3 live_rows=0 "
        "withheld_no_printed_answer=3"
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--fixture", type=pathlib.Path, default=FIXTURE)
    args = parser.parse_args()
    fixture = json.loads(args.fixture.read_text(encoding="utf-8"))
    if (
        fixture.get("schema")
        != "equation_verification_sidecar_segmenter_controls_v3"
    ):
        raise SystemExit(f"unexpected sidecar segmenter fixture schema: {args.fixture}")
    docs, covered, attachments, tracked, recovered = corpus()
    check_constructed_controls(fixture)
    check_segmenter(fixture, recovered)
    check_live_witnesses(docs, covered, attachments)
    check_equation_matching_refusal(fixture, tracked)
    check_operation_glue(fixture, docs, covered, attachments)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
