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
    MAX_IMAGES_PER_CALL,
    REPORT_COUNTS,
    RUN_VERSION,
    FixtureResult,
    RunConfig,
    atomic_write_json,
    build_messages,
    checkpoint_path,
    derive_worklist,
    dry_run_result,
    evaluate_result,
    execute_run,
    select_call_images,
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
    assert len(worklist["spans"]) == 238
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
    assert len(image_parts) == min(len(first["images"]), MAX_IMAGES_PER_CALL)
    assert all(
        part["type"] == "image_url"
        and part["image_url"]["url"].startswith("data:image/")
        for part in image_parts
    )
    print("PASS multimodal request contains one data URL per call-selected source image")

    over_cap = next(span for span in worklist["spans"] if len(span["images"]) == 6)
    selected_images = select_call_images(over_cap)
    over_cap_messages = build_messages(over_cap, selected_images)
    assert len(over_cap_messages[1]["content"][1:]) == MAX_IMAGES_PER_CALL
    assert len(selected_images) == MAX_IMAGES_PER_CALL
    assert [
        (
            image["distance_from_task_anchor"],
            image["source_line"],
            image["file"],
        )
        for image in selected_images
    ] == sorted(
        (
            image["distance_from_task_anchor"],
            image["source_line"],
            image["file"],
        )
        for image in selected_images
    )
    over_cap_checkpoint = evaluate_result(
        over_cap,
        dry_run_result(over_cap),
        selected_images=selected_images,
    )
    assert over_cap_checkpoint["verdict"] == "accepted"
    assert len(over_cap_checkpoint["image_selection"]) == MAX_IMAGES_PER_CALL
    assert over_cap_checkpoint["image_overflow"] == 2
    over_cap_http_error = evaluate_result(
        over_cap,
        FixtureResult(outcome="http_error", content=""),
        selected_images=selected_images,
    )
    assert over_cap_http_error["verdict"] == "rejected"
    assert len(over_cap_http_error["image_selection"]) == MAX_IMAGES_PER_CALL
    assert over_cap_http_error["image_overflow"] == 2
    four_image = next(span for span in worklist["spans"] if len(span["images"]) == 4)
    assert "image_overflow" not in evaluate_result(
        four_image,
        dry_run_result(four_image),
    )
    print("PASS six-image fixture sends four proximity-ranked images and records overflow=2")

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

    selection = (over_cap["span_id"], four_image["span_id"])
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
        legacy_path = checkpoint_path(output, over_cap["span_id"])
        legacy_checkpoint = json.loads(legacy_path.read_text(encoding="utf-8"))
        legacy_checkpoint.pop("image_selection")
        legacy_checkpoint.pop("image_overflow")
        atomic_write_json(legacy_path, legacy_checkpoint)
        second_summary = execute_run(
            worklist, worklist_hash, output, config, transport
        )
        manifest = json.loads((output / "manifest.json").read_text(encoding="utf-8"))
        checkpoints = list((output / "checkpoints").glob("*.json"))
        checkpoint_payloads = [
            json.loads(path.read_text(encoding="utf-8")) for path in checkpoints
        ]
    assert first_summary["accepted"] == 2
    assert second_summary["accepted"] == 2
    assert calls == 2
    assert len(checkpoints) == 2
    assert manifest["run_version"] == RUN_VERSION
    assert manifest["control_calibration"]["rejection_rate"] == 1.0
    checkpoint_by_id = {
        payload["span_id"]: payload
        for payload in checkpoint_payloads
    }
    assert all(
        len(payload["image_selection"]) <= MAX_IMAGES_PER_CALL
        for payload in checkpoint_by_id.values()
    )
    assert checkpoint_by_id[over_cap["span_id"]]["image_overflow"] == 2
    print("PASS atomic checkpoints, 100% control rejection, and accepted-span resume")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
