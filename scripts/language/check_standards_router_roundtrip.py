#!/usr/bin/env python3
"""Round-trip serialized-table routes through both persistent JSONL workers."""

from __future__ import annotations

import json
import hashlib
import subprocess
from pathlib import Path
from typing import Any


REPO = Path(__file__).resolve().parents[2]
PUSU_RUNNER = REPO / "scripts/language/pusu_harness_runner.pl"
STANDARDS_RUNNER = REPO / "scripts/language/standards_router_runner.pl"
STAGED_CRASH = (
    REPO / ".superpowers/sdd/task-2026-08-18-g8-table-crash-request.json"
)
LEGACY_STANDARDS_STDOUT_SHA256 = (
    "cbd9cec919f7a6607f1fe612778ec4e0e40280b46a5f5dbe1a34ba0e001410a5"
)

TABLE_FIXTURES = [
    (
        "f1_relation",
        "IM-G8-U3-L3",
        "| salt (grams) | honey (grams) | |----------------|-----------------| | 10 | 14 | | 25 | 35 |",
    ),
    (
        "f2_labeled_measurements",
        "IM-G8-U6-L2",
        "| | right hand length (cm) | right foot length (cm) | |----------|--------------------------|--------------------------| | person A | 19 | 27 | | person B | 21 | 30 | | person C | 17 | 23 | | person D | 18 | 24 | | person E | 19 | 26 | 1.",
    ),
    (
        "f3_partial_two_way",
        "IM-G8-U6-L10",
        "| | plays instrument | does not play instrument | total | |---------------------|--------------------|----------------------------|---------| | plays sport | 5 | | 16 | | does not play sport | | | | | total | | 15 | 25 |",
    ),
    (
        "f4_three_function_tables",
        "IM-G8-U5-L1",
        "| input | output | |---------|----------| | | 7 | | 2.35 | | | 42 | | | input | output | |---------|----------| | | 7 | | 2.35 | | | 42 | | | input | output | |---------|----------| | | 7 | | 2.35 | | | 42 | |",
    ),
    (
        "shares_not_counts",
        "IM-G8-U6-L10",
        "| | plays an instrument | does not play an instrument | total | |-----------------------|-----------------------|-------------------------------|---------| | plays a sport | | 89% | 100% | | does not play a sport | 71% | | 100% |",
    ),
    (
        "complete_two_way_tie",
        "IM-G8-U6-L3",
        "| | red | blue | |---|---|---| | class A | 5 | 6 | | class B | 7 | 8 |",
    ),
    (
        "non_count_cells",
        "IM-G8-U6-L3",
        "| | red | blue | |---|---|---| | class A | 1.5 | 2.5 | | class B | 3.5 | 4.5 |",
    ),
    (
        "transposed_no_route",
        "IM-G8-U8-L3",
        "| side length, | 0.5 | | 1.5 | | 2.5 | | 3.5 | | |----------------|-------|----|-------|----|-------|----|-------|----| | area, | | 1 | | 4 | | 9 | | 16 |",
    ),
    (
        "complete_function_tie",
        "IM-G8-U5-L1",
        "| input | output | |---|---| | 1 | 2 | | 2 | 4 | | 3 | 6 |",
    ),
]

CRASH_PROGRAM = [
    'table_layout(s2_table_1,columns(3),rows(4),header([blank,words("height (inches)"),words("shadow length (inches)")]))',
    'table_cell(s2_table_1,1,1,words("younger boy"))',
    'table_cell(s2_table_1,1,2,numeral(43,"43"))',
    'table_cell(s2_table_1,1,3,numeral(29,"29"))',
    'table_cell(s2_table_1,2,1,words("man"))',
    'table_cell(s2_table_1,2,2,numeral(72,"72"))',
    'table_cell(s2_table_1,2,3,numeral(48,"48"))',
    'table_cell(s2_table_1,3,1,words("older boy"))',
    'table_cell(s2_table_1,3,2,numeral(51,"51"))',
    'table_cell(s2_table_1,3,3,numeral(34,"34"))',
    'table_cell(s2_table_1,4,1,words("lamppost"))',
    'table_cell(s2_table_1,4,2,blank)',
    'table_cell(s2_table_1,4,3,numeral(114,"114"))',
]

B6_PROGRAM = [
    'table_layout(s9_table_1,columns(4),rows(3),header([blank,words("plays instrument"),words("does not play instrument"),words("total")]))',
    'table_cell(s9_table_1,1,1,words("plays sport"))',
    'table_cell(s9_table_1,1,2,numeral(5,"5"))',
    'table_cell(s9_table_1,1,3,blank)',
    'table_cell(s9_table_1,1,4,numeral(16,"16"))',
    'table_cell(s9_table_1,2,1,words("does not play sport"))',
    'table_cell(s9_table_1,2,2,blank)',
    'table_cell(s9_table_1,2,3,blank)',
    'table_cell(s9_table_1,2,4,blank)',
    'table_cell(s9_table_1,3,1,words("total"))',
    'table_cell(s9_table_1,3,2,blank)',
    'table_cell(s9_table_1,3,3,numeral(15,"15"))',
    'table_cell(s9_table_1,3,4,numeral(25,"25"))',
]

DBF_PROGRAM = [
    'table_layout(s4_table_1,columns(4),rows(3),header([blank,words("plays an instrument"),words("does not play an instrument"),words("total")]))',
    'table_cell(s4_table_1,1,1,words("plays a sport"))',
    'table_cell(s4_table_1,1,2,blank)',
    'table_cell(s4_table_1,1,3,numeral(16,"16"))',
    'table_cell(s4_table_1,1,4,blank)',
    'table_cell(s4_table_1,2,1,words("does not play a sport"))',
    'table_cell(s4_table_1,2,2,numeral(5,"5"))',
    'table_cell(s4_table_1,2,3,blank)',
    'table_cell(s4_table_1,2,4,blank)',
    'table_cell(s4_table_1,3,1,words("total"))',
    'table_cell(s4_table_1,3,2,blank)',
    'table_cell(s4_table_1,3,3,blank)',
    'table_cell(s4_table_1,3,4,numeral(25,"25"))',
    'table_layout(s6_table_1,columns(4),rows(2),header([blank,words("plays an instrument"),words("does not play an instrument"),words("total")]))',
    'table_cell(s6_table_1,1,1,words("plays a sport"))',
    'table_cell(s6_table_1,1,2,blank)',
    'table_cell(s6_table_1,1,3,share(89,"89%"))',
    'table_cell(s6_table_1,1,4,share(100,"100%"))',
    'table_cell(s6_table_1,2,1,words("does not play a sport"))',
    'table_cell(s6_table_1,2,2,share(71,"71%"))',
    'table_cell(s6_table_1,2,3,blank)',
    'table_cell(s6_table_1,2,4,share(100,"100%"))',
]

B6_ASK_SPAN = {
    "path": "hermes/app/runtime/experiments/gemma4_tutor/docling/full-output/TeacherLessonGuides/Grade8/Grade8-6-10-Lesson-teacher-guide-/document.md",
    "line_start": 103,
    "line_end": 103,
    "byte_start": 6073,
    "byte_end": 6144,
    "sha256": "8b0de9282646666ae8f20d26d3bc3225ff80922495cb9b851eca29a1db920a1f",
}

DBF_ASK_SPAN = {
    "path": "hermes/app/runtime/experiments/gemma4_tutor/docling/full-output/TeacherLessonGuides/Grade8/Grade8-6-9-Lesson-teacher-guide-/document.md",
    "line_start": 669,
    "line_end": 669,
    "byte_start": 51834,
    "byte_end": 51897,
    "sha256": "2c05fb8351120a74cd40429d206965fffb6934cb808b60000c8213e0970c59d2",
}

NO_ASK_SPAN = {
    "path": "hermes/app/runtime/experiments/gemma4_tutor/docling/full-output/TeacherLessonGuides/Grade8/Grade8-4-11-Lesson-teacher-guide-/document.md",
    "line_start": 338,
    "line_end": 338,
    "byte_start": 25411,
    "byte_end": 25428,
    "sha256": "7e3cd0f4c1ebe9fca885dc9c39bfec6523467ac9cef0fe47720d5df34460a259",
}


def run_jsonl(
    command: list[str],
    requests: list[dict[str, Any]],
    expected_stdout_sha256: str | None = None,
) -> list[dict[str, Any]]:
    payload = "".join(
        json.dumps(request, separators=(",", ":")) + "\n" for request in requests
    )
    completed = subprocess.run(
        command,
        cwd=REPO,
        input=payload,
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode != 0:
        raise AssertionError(
            f"worker exited {completed.returncode}: "
            f"stdout={completed.stdout!r} stderr={completed.stderr!r}"
        )
    if expected_stdout_sha256 is not None:
        actual_sha256 = hashlib.sha256(completed.stdout.encode("utf-8")).hexdigest()
        if actual_sha256 != expected_stdout_sha256:
            raise AssertionError(
                "legacy worker replies changed bytes: "
                f"expected={expected_stdout_sha256} actual={actual_sha256}"
            )
    lines = completed.stdout.splitlines()
    if len(lines) != len(requests):
        raise AssertionError(
            f"worker returned {len(lines)} lines for {len(requests)} requests: "
            f"stdout={completed.stdout!r} stderr={completed.stderr!r}"
        )
    replies = [json.loads(line) for line in lines]
    if any(reply.get("status") == "error" or reply.get("ok") is False for reply in replies):
        raise AssertionError(f"worker error reply: {replies!r}")
    return replies


def pusu_request(case_id: str, surface: str) -> dict[str, Any]:
    span = {
        "path": f"fixtures/{case_id}.md",
        "line_start": 1,
        "line_end": 1,
        "byte_start": 0,
        "byte_end": len(surface.encode("utf-8")),
        "sha256": "fixture",
    }
    return {
        "sentences": [surface],
        "source_statement": surface,
        "complete_statement": surface,
        "source_statement_spans": [span],
        "referents": [],
        "sentence_spans": [[span]],
    }


def crash_request() -> dict[str, Any]:
    if STAGED_CRASH.exists():
        staged = json.loads(STAGED_CRASH.read_text(encoding="utf-8"))
        return {key: staged[key] for key in ("id", "lesson", "program")}
    return {
        "id": "im_defrag_390dc24835c9254e6fafa1f9_1",
        "lesson": "IM-G8-U2-L13",
        "program": CRASH_PROGRAM,
    }


def routed_sentence(
    index: int, text: str, form: str, spans: list[dict[str, Any]]
) -> dict[str, Any]:
    return {"index": index, "text": text, "form": form, "spans": spans}


def completion_requests() -> list[dict[str, Any]]:
    return [
        {
            "id": "im_defrag_b6c94497749a10a71bd962e3_1",
            "lesson": "IM-G8-U6-L10",
            "program": B6_PROGRAM,
            "sentences": [
                routed_sentence(
                    4,
                    "Complete the table, assuming that all students answered both questions.",
                    "directive",
                    [B6_ASK_SPAN],
                )
            ],
        },
        {
            "id": "im_defrag_dbf89012934421ee15f04d7d_1",
            "lesson": "IM-G8-U6-L9",
            "program": DBF_PROGRAM,
            "sentences": [
                routed_sentence(
                    2,
                    "Complete the two-way table to show the data from the bar graph.",
                    "directive",
                    [DBF_ASK_SPAN],
                )
            ],
        },
        {
            "id": "b6_no_matching_ask",
            "lesson": "IM-G8-U6-L10",
            "program": B6_PROGRAM,
            "sentences": [
                routed_sentence(
                    10,
                    "Who won the race?",
                    "question",
                    [NO_ASK_SPAN],
                )
            ],
        },
    ]


def require_abstention(reply: dict[str, Any], reason: str, detail: str) -> None:
    assert reply["status"] == "abstain", reply
    assert reply["reason"] == reason, reply
    assert detail in reply["detail"], reply


def main() -> None:
    pusu_replies = run_jsonl(
        [
            "swipl",
            "-q",
            "-l",
            str(PUSU_RUNNER),
            "-g",
            "pusu_harness_runner:main",
            "-t",
            "halt",
        ],
        [pusu_request(case_id, surface) for case_id, _lesson, surface in TABLE_FIXTURES],
    )
    standards_requests = []
    for (case_id, lesson, _surface), reply in zip(TABLE_FIXTURES, pusu_replies):
        standards_requests.append(
            {"id": case_id, "lesson": lesson, "program": reply["program"]}
        )
    standards_requests.append(crash_request())
    replies = run_jsonl(
        [
            "swipl",
            "-q",
            "-l",
            str(REPO / "paths.pl"),
            "-s",
            str(STANDARDS_RUNNER),
            "-g",
            "main",
            "-t",
            "halt",
        ],
        standards_requests,
        expected_stdout_sha256=LEGACY_STANDARDS_STDOUT_SHA256,
    )
    by_id = {reply["id"]: reply for reply in replies}

    f1 = by_id["f1_relation"]
    assert f1["status"] == "routed" and f1["route_basis"] == "table", f1
    assert f1["kind"] == "rate_of_change_from_two_observations", f1
    assert f1["table_id"] == "s0_table_1", f1
    assert f1["shape"] == {"columns": 2, "rows": 2}, f1

    f3 = by_id["f3_partial_two_way"]
    assert f3["status"] == "routed" and f3["route_basis"] == "table", f3
    assert f3["kind"] == "complete_two_way_table", f3
    assert f3["table_id"] == "s0_table_1", f3
    assert f3["shape"] == {"columns": 4, "rows": 3}, f3

    require_abstention(by_id["f2_labeled_measurements"], "undecided(machine)", "least_squares_line_from_pairs")
    require_abstention(by_id["f4_three_function_tables"], "holes_outside_completion_route", "columns(2),rows(3)")
    require_abstention(by_id["shares_not_counts"], "shares_not_counts", "columns(4),rows(2)")
    require_abstention(by_id["complete_two_way_tie"], "undecided(machine)", "relative_frequency_of_whole_table")
    require_abstention(by_id["non_count_cells"], "no_table_route", "counts_not_witnessed")
    require_abstention(by_id["transposed_no_route"], "no_table_route", "columns(9),rows(1)")
    require_abstention(by_id["complete_function_tie"], "undecided(machine)", "fit_linear_rule_to_table")

    crash = by_id["im_defrag_390dc24835c9254e6fafa1f9_1"]
    require_abstention(
        crash,
        "measurement_labels_do_not_witness_counts",
        'words("height (inches)")',
    )

    completion_replies = run_jsonl(
        [
            "swipl",
            "-q",
            "-l",
            str(REPO / "paths.pl"),
            "-s",
            str(STANDARDS_RUNNER),
            "-g",
            "main",
            "-t",
            "halt",
        ],
        completion_requests(),
    )
    completion_by_id = {reply["id"]: reply for reply in completion_replies}
    completed = completion_by_id["im_defrag_b6c94497749a10a71bd962e3_1"]
    assert completed["status"] == "routed", completed
    assert completed["ask"] == {
        "sentence_index": 4,
        "surface": "Complete the table, assuming that all students answered both questions.",
        "spans": [B6_ASK_SPAN],
    }, completed
    assert completed["completion"]["status"] == "completed", completed
    assert completed["completion"]["answers"] == [
        {
            "referent": "s9_table_1",
            "value": "completed_table([[5,11],[5,4]])",
            "derivation": "run_g8_action(complete_two_way_table)",
        }
    ], completed

    refused = completion_by_id["im_defrag_dbf89012934421ee15f04d7d_1"]
    assert refused["status"] == "routed", refused
    assert refused["ask"]["spans"] == [DBF_ASK_SPAN], refused
    assert refused["completion"] == {
        "status": "parsed_not_completed",
        "reason": "table_does_not_determine_its_missing_cells",
        "kind": "complete_two_way_table",
        "table_id": "s4_table_1",
    }, refused
    no_ask = completion_by_id["b6_no_matching_ask"]
    assert no_ask["status"] == "routed", no_ask
    assert "ask" not in no_ask and "completion" not in no_ask, no_ask

    routed = sum(reply["status"] == "routed" for reply in replies)
    abstained = sum(reply["status"] == "abstain" for reply in replies)
    print(
        "standards_router_roundtrip: ok "
        f"legacy_replies={len(replies)} routed={routed} abstentions={abstained} "
        "completion_shapes=2 no_ask_shape=unchanged "
        "answer=completed_table([[5,11],[5,4]]) "
        "crash=measurement_labels_do_not_witness_counts legacy_bytes=stable"
    )


if __name__ == "__main__":
    main()
