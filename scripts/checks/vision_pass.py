#!/usr/bin/env python3
"""Offline checks for the Grade 6-7 vision-pass producer."""

from __future__ import annotations

import json
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from scripts.curriculum.vision_pass import (  # noqa: E402
    DEFAULT_BUDGET,
    REPORT_COUNTS,
    RUN_VERSION,
    FixtureResult,
    RunConfig,
    build_messages,
    derive_worklist,
    dry_run_result,
    evaluate_result,
    execute_run,
    stable_hash,
    text_only_pairs,
)


def main() -> int:
    assert len(text_only_pairs()) == 76
    worklist = derive_worklist()
    assert worklist["derived_counts"] == REPORT_COUNTS
    assert worklist["difference_from_report"] == {
        "grade_6": 0,
        "grade_7": 0,
        "total": 0,
    }
    assert len(worklist["spans"]) == 203
    assert all(span["images"] for span in worklist["spans"])
    assert all(
        (ROOT / image["file"]).is_file()
        for span in worklist["spans"]
        for image in span["images"]
    )
    print("PASS current checkpoint/corpus worklist derives 145 Grade 6 and 58 Grade 7 spans")

    first = worklist["spans"][0]
    messages = build_messages(first)
    image_parts = messages[1]["content"][1:]
    assert len(image_parts) == len(first["images"])
    assert all(
        part["type"] == "image_url"
        and part["image_url"]["url"].startswith("data:image/")
        for part in image_parts
    )
    print("PASS multimodal request contains one data URL per selected source image")

    accepted = evaluate_result(first, dry_run_result(first))
    assert accepted["verdict"] == "accepted"
    image_payload = {
        "source_excerpt": first["fixture_source_excerpt"],
        "image_excerpt": "A fixture label copied from an attached image.",
        "doing": "Retain the bounded task wording.",
        "numeric_operands": [],
        "image_derived": True,
    }
    image_accepted = evaluate_result(
        first,
        FixtureResult(outcome="ok", content=json.dumps(image_payload)),
    )
    assert image_accepted["verdict"] == "accepted"
    assert image_accepted["provenance"]["image_derived"] is True
    paraphrase_payload = dict(image_payload)
    paraphrase_payload["source_excerpt"] = (
        "Students complete a rewritten task that is absent from the curriculum source."
    )
    rejected = evaluate_result(
        first,
        FixtureResult(outcome="ok", content=json.dumps(paraphrase_payload)),
    )
    assert rejected["failure"]["kind"] == "provenance_rejection"
    print("PASS image-derived records retain source exactness; source paraphrases reject")

    selection = tuple(span["span_id"] for span in worklist["spans"][:2])
    config = RunConfig(
        model="offline-fixture",
        budget=DEFAULT_BUDGET,
        endpoint_class="offline_fixture",
        dry_run=True,
        selected_span_ids=selection,
    )
    calls = 0

    def transport(span: dict, _messages: list[dict]) -> FixtureResult:
        nonlocal calls
        calls += 1
        return dry_run_result(span)

    with tempfile.TemporaryDirectory() as temporary:
        output = Path(temporary)
        worklist_hash = stable_hash(worklist)
        first_summary = execute_run(
            worklist, worklist_hash, output, config, transport
        )
        second_summary = execute_run(
            worklist, worklist_hash, output, config, transport
        )
        manifest = json.loads((output / "manifest.json").read_text(encoding="utf-8"))
        checkpoints = list((output / "checkpoints").glob("*.json"))
    assert first_summary["accepted"] == 2
    assert second_summary["accepted"] == 2
    assert calls == 2
    assert len(checkpoints) == 2
    assert manifest["run_version"] == RUN_VERSION
    assert manifest["control_calibration"]["rejection_rate"] == 1.0
    print("PASS atomic checkpoints, 100% control rejection, and accepted-span resume")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
