#!/usr/bin/env python3
"""Offline synthetic fixtures for the Grade 6-8 text harvest lane."""

from __future__ import annotations

import hashlib
import json
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from scripts.curriculum.harvest_g68_tasks import (  # noqa: E402
    DEFAULT_BUDGET,
    FixtureResult,
    LessonSource,
    RunConfig,
    build_messages,
    evaluate_result,
    execute_run,
    parse_args,
    parse_task_content,
    select_lessons,
)
from scripts.curriculum.verify_g68_harvest import (  # noqa: E402
    CONTROL_EXCERPTS,
    ControlLeakError,
    calibrate_controls,
    cleaned_source_view,
    normalized_match_offset,
    sha256_text,
    verify_excerpt,
    verify_run,
)


SYNTHETIC_MARKDOWN = """# Synthetic Lesson

Students   compare
12 and 19, then explain how the two quantities are related.

Next, students arrange 24 counters into 6 equal groups.
"""

EMPTY_PICTURE_DESCRIPTIONS = """# Model-generated picture descriptions

These annotations were generated from synthetic images.
"""

IMAGE_SPLIT_DESCRIPTION = (
    "The generated annotation describes a rectangle divided into equal regions."
)
IMAGE_SPLIT_MARKDOWN = f"""# Synthetic Image-Split Lesson

Which statements describe the rectangle?

![Image](document_artifacts/rectangle.png)

{IMAGE_SPLIT_DESCRIPTION}

- A. Its opposite sides have equal lengths.
- B. Its area is measured in square units.
"""
IMAGE_SPLIT_PICTURE_DESCRIPTIONS = f"""# Model-generated picture descriptions

## Picture 1

![Picture 1](document_artifacts/rectangle.png)

{IMAGE_SPLIT_DESCRIPTION}

Provenance: `synthetic-fixture (auto_inline)`
"""

INLINE_IMAGE_OPERAND_MARKDOWN = """# Synthetic Inline-Operand Lesson

Select all statements that are true about the area.

- E. The area can be found by adding and .

![Image](document_artifacts/missing-inline-operands.png)
"""


def lesson_for(
    source_file: Path,
    *,
    lesson_id: str = "IM-G6-U1-L1",
    lesson_number: int = 1,
    source_text: str = SYNTHETIC_MARKDOWN,
    picture_descriptions: str = EMPTY_PICTURE_DESCRIPTIONS,
) -> LessonSource:
    source_file.write_text(source_text, encoding="utf-8")
    source_file.with_name("picture_descriptions.md").write_text(
        picture_descriptions, encoding="utf-8"
    )
    cleaned_source_text = cleaned_source_view(source_file, source_text)
    return LessonSource(
        lesson=lesson_id,
        grade=6,
        unit=1,
        lesson_number=lesson_number,
        source_file=source_file.resolve(),
        raw_source_sha256=hashlib.sha256(source_text.encode("utf-8")).hexdigest(),
        cleaned_source_sha256=sha256_text(cleaned_source_text),
        source_text=source_text,
    )


def fixture_result(excerpt: str) -> FixtureResult:
    return FixtureResult(
        outcome="ok",
        content=json.dumps({
            "tasks": [{
                "excerpt": excerpt,
                "doing": "Compare two quantities and explain their relationship.",
                "numeric_operands": ["12", "19"],
            }]
        }),
    )


def fixture_tasks_result(excerpts: list[str]) -> FixtureResult:
    return FixtureResult(
        outcome="ok",
        content=json.dumps({
            "tasks": [
                {
                    "excerpt": excerpt,
                    "doing": "Describe the mathematical work requested in this region.",
                    "numeric_operands": [],
                }
                for excerpt in excerpts
            ]
        }),
    )


def test_parse_and_accept() -> None:
    tasks = parse_task_content(fixture_result("unused").content)
    assert tasks[0]["doing"].startswith("Compare")
    with tempfile.TemporaryDirectory() as temporary:
        lesson = lesson_for(Path(temporary) / "document.md")
        checkpoint = evaluate_result(
            lesson,
            fixture_result(
                "Students compare 12 and 19, then explain how the two quantities are related."
            ),
        )
    assert checkpoint["verdict"] == "accepted"
    assert checkpoint["tasks"][0]["provenance"]["normalized_match_offset"] is not None
    print("PASS strict JSON parse and source-present excerpt acceptance")


def test_exact_fence_and_commentary_rejection() -> None:
    raw_json = fixture_result(
        "Students compare 12 and 19, then explain how the two quantities are related."
    ).content
    fenced = f"  \n```json\n{raw_json}\n```\n\t"
    tasks = parse_task_content(fenced)
    assert len(tasks) == 1

    with tempfile.TemporaryDirectory() as temporary:
        lesson = lesson_for(Path(temporary) / "document.md")
        fenced_checkpoint = evaluate_result(
            lesson, FixtureResult(outcome="ok", content=fenced)
        )
        commentary_checkpoint = evaluate_result(
            lesson,
            FixtureResult(
                outcome="ok",
                content=f"```json\n{raw_json}\n```\nExtraction complete.",
            ),
        )
        absent = evaluate_result(
            lesson,
            fixture_result("Students estimate the height of a cedar tree in meters."),
        )
    assert fenced_checkpoint["verdict"] == "accepted"
    assert commentary_checkpoint["failure"]["kind"] == "schema_rejection"
    assert absent["failure"]["kind"] == "provenance_rejection"
    assert absent["tasks"][0]["provenance"]["normalized_match_offset"] is None
    print("PASS one exact JSON fence unwraps; fence-plus-commentary stays rejected")


def test_partial_lesson_and_verifier() -> None:
    good_excerpt = (
        "Students compare 12 and 19, then explain how the two quantities are related."
    )
    bad_excerpt = "Students estimate the height of a cedar tree in meters."
    with tempfile.TemporaryDirectory() as temporary:
        root = Path(temporary)
        lesson = lesson_for(root / "document.md")
        result = fixture_tasks_result([good_excerpt, bad_excerpt])
        checkpoint = evaluate_result(lesson, result)
        assert checkpoint["verdict"] == "partial"
        assert checkpoint["failed_indices"] == [1]
        assert checkpoint["record_counts"] == {
            "accepted_records": 1,
            "failed_records": 1,
        }
        assert checkpoint["tasks"][0]["failure"] is None
        assert checkpoint["tasks"][1]["failure"]["kind"] == "provenance_rejection"

        output = root / "partial-run"
        config = RunConfig(
            grade=6,
            unit=None,
            limit=1,
            model="glm-5.2",
            budget=DEFAULT_BUDGET,
            endpoint_class="offline_fixture",
            dry_run=True,
        )

        def transport(
            _lesson: LessonSource, _messages: list[dict[str, str]]
        ) -> FixtureResult:
            return result

        summary = execute_run([lesson], output, config, transport)
        assert summary["partial"] == 1
        assert summary["lessons_by_verdict"]["partial"] == 1
        assert summary["accepted_records"] == 1
        assert summary["failed_records"] == 1
        verified = verify_run(output)
        assert verified["lessons_by_verdict"]["partial"] == 1
        assert verified["accepted_records"] == 1
        assert verified["failed_records"] == 1
        assert verified["accepted_records_verified"] == 1
    print("PASS partial lesson retains both records and re-verifies its accepted record")


def test_outcome_branching_and_failure_vocabulary() -> None:
    class NonOkResult:
        def __init__(self, outcome: str) -> None:
            self.outcome = outcome
            self.error = "fixture transport failure" if outcome == "transport_error" else None

        @property
        def content(self) -> str:
            raise AssertionError("non-ok content must not be read or parsed")

        def to_dict(self) -> dict[str, object]:
            return {"outcome": self.outcome, "content": "diagnostic-only fixture"}

    with tempfile.TemporaryDirectory() as temporary:
        lesson = lesson_for(Path(temporary) / "document.md")
        expected = {
            "transport_error": "transport",
            "http_error": "transport",
            "truncated": "truncated",
            "empty_content": "empty",
        }
        for outcome, failure_kind in expected.items():
            checkpoint = evaluate_result(lesson, NonOkResult(outcome))
            assert checkpoint["failure"]["kind"] == failure_kind
            assert checkpoint["tasks"] == []
    print("PASS non-ok outcomes branch before content parsing with structured failure kinds")


def test_whitespace_is_the_only_forgiveness() -> None:
    accepted = verify_excerpt(
        SYNTHETIC_MARKDOWN,
        "Students compare 12 and 19, then explain how the two quantities are related.",
    )
    punctuation_change = verify_excerpt(
        SYNTHETIC_MARKDOWN,
        "Students compare 12 and 19 then explain how the two quantities are related.",
    )
    case_change = verify_excerpt(
        SYNTHETIC_MARKDOWN,
        "students compare 12 and 19, then explain how the two quantities are related.",
    )
    assert accepted["verdict"] == "accepted"
    assert punctuation_change["verdict"] == "rejected"
    assert case_change["verdict"] == "rejected"
    assert normalized_match_offset(SYNTHETIC_MARKDOWN, "  \n\t") is None
    print("PASS whitespace runs collapse; punctuation and case receive no forgiveness")


def test_image_split_stem_and_options_accept() -> None:
    excerpt = (
        "Which statements describe the rectangle?\n\n"
        "- A. Its opposite sides have equal lengths.\n"
        "- B. Its area is measured in square units."
    )
    assert verify_excerpt(IMAGE_SPLIT_MARKDOWN, excerpt)["verdict"] == "rejected"
    with tempfile.TemporaryDirectory() as temporary:
        lesson = lesson_for(
            Path(temporary) / "document.md",
            source_text=IMAGE_SPLIT_MARKDOWN,
            picture_descriptions=IMAGE_SPLIT_PICTURE_DESCRIPTIONS,
        )
        user_prompt = build_messages(lesson)[1]["content"]
        assert "![Image]" not in user_prompt
        assert IMAGE_SPLIT_DESCRIPTION not in user_prompt
        checkpoint = evaluate_result(lesson, fixture_result(excerpt))
    assert checkpoint["verdict"] == "accepted"
    print("PASS image-split stem and answer choices accept against the cleaned view")


def test_text_incomplete_inline_image_operand_accepts() -> None:
    excerpt = "- E. The area can be found by adding and ."
    with tempfile.TemporaryDirectory() as temporary:
        lesson = lesson_for(
            Path(temporary) / "document.md",
            source_text=INLINE_IMAGE_OPERAND_MARKDOWN,
        )
        user_prompt = build_messages(lesson)[1]["content"]
        assert "![Image]" not in user_prompt
        assert excerpt in user_prompt
        checkpoint = evaluate_result(lesson, fixture_result(excerpt))
    assert checkpoint["verdict"] == "accepted"
    print("PASS source-incomplete inline-image operand text accepts in the cleaned view")


def test_control_calibration_and_leak_detection() -> None:
    control_annotation = CONTROL_EXCERPTS[0]
    raw_source = f"""# Synthetic Control Annotation

![Image](document_artifacts/control.png)

{control_annotation}

Students compare 12 and 19.
"""
    picture_descriptions = f"""# Model-generated picture descriptions

## Picture 1

![Picture 1](document_artifacts/control.png)

{control_annotation}

Provenance: `synthetic-fixture (auto_inline)`
"""
    with tempfile.TemporaryDirectory() as temporary:
        lesson = lesson_for(
            Path(temporary) / "document.md",
            source_text=raw_source,
            picture_descriptions=picture_descriptions,
        )
        cleaned = cleaned_source_view(lesson.source_file, lesson.source_text)
        assert normalized_match_offset(raw_source, control_annotation) is not None
        assert normalized_match_offset(cleaned, control_annotation) is None
        report = calibrate_controls({lesson.lesson: cleaned})
    assert report["checks"] == len(CONTROL_EXCERPTS)
    assert report["rejection_rate"] == 1.0
    try:
        calibrate_controls(
            {"IM-G6-U1-L1": SYNTHETIC_MARKDOWN},
            matcher=lambda _source, _excerpt: 0,
        )
    except ControlLeakError as exc:
        assert "CONTROL LEAK" in str(exc)
    else:
        raise AssertionError("manufactured control acceptance did not fail the gate")
    print("PASS controls use the cleaned view, reject 100 percent, and fail loudly on leaks")


def test_default_budget() -> None:
    assert DEFAULT_BUDGET == 32768
    assert parse_args(["--grade", "6"]).budget == 32768
    print("PASS harvest default completion budget is 32768")


def test_atomic_checkpoint_and_accepted_resume() -> None:
    with tempfile.TemporaryDirectory() as temporary:
        root = Path(temporary)
        lesson = lesson_for(root / "document.md")
        output = root / "run"
        config = RunConfig(
            grade=6,
            unit=None,
            limit=1,
            model="glm-5.2",
            budget=DEFAULT_BUDGET,
            endpoint_class="offline_fixture",
            dry_run=True,
        )
        calls = 0

        def first_transport(_lesson: LessonSource, _messages: list[dict[str, str]]) -> FixtureResult:
            nonlocal calls
            calls += 1
            assert (output / "manifest.json").is_file(), "manifest must precede the call"
            manifest = json.loads((output / "manifest.json").read_text(encoding="utf-8"))
            manifest_lesson = manifest["lessons"][0]
            assert manifest_lesson["raw_source_sha256"] == lesson.raw_source_sha256
            assert (
                manifest_lesson["cleaned_source_sha256"]
                == lesson.cleaned_source_sha256
            )
            return fixture_result(
                "Students compare 12 and 19, then explain how the two quantities are related."
            )

        first_summary = execute_run([lesson], output, config, first_transport)
        assert first_summary["accepted"] == 1
        assert calls == 1
        checkpoint_path = output / "checkpoints" / "IM-G6-U1-L1.json"
        checkpoint = json.loads(checkpoint_path.read_text(encoding="utf-8"))
        assert checkpoint["verdict"] == "accepted"
        assert checkpoint["budget"] == DEFAULT_BUDGET
        checkpoint.pop("budget")
        checkpoint_path.write_text(
            json.dumps(checkpoint, indent=2) + "\n", encoding="utf-8"
        )

        def forbidden_transport(
            _lesson: LessonSource, _messages: list[dict[str, str]]
        ) -> FixtureResult:
            raise AssertionError("accepted checkpoint should resume without another call")

        resumed_summary = execute_run([lesson], output, config, forbidden_transport)
        assert resumed_summary["accepted"] == 1
        assert calls == 1
        verified = verify_run(output)
        assert verified["source_fingerprints_verified"] == 1
    print(
        "PASS manifest-before-call, checkpoint budget, and legacy accepted resume"
    )


def test_filtered_retry_and_budget_raise() -> None:
    accepted_excerpt = (
        "Students compare 12 and 19, then explain how the two quantities are related."
    )
    rejected_excerpt = "Students estimate the height of a cedar tree in meters."
    with tempfile.TemporaryDirectory() as temporary:
        root = Path(temporary)
        first_dir = root / "first"
        second_dir = root / "second"
        first_dir.mkdir()
        second_dir.mkdir()
        first = lesson_for(first_dir / "document.md")
        second = lesson_for(
            second_dir / "document.md",
            lesson_id="IM-G6-U1-L2",
            lesson_number=2,
        )
        lessons = [first, second]
        output = root / "run"
        default_config = RunConfig(
            grade=6,
            unit=None,
            limit=2,
            model="glm-5.2",
            budget=DEFAULT_BUDGET,
            endpoint_class="offline_fixture",
            dry_run=True,
        )
        initial_calls: list[str] = []

        def initial_transport(
            lesson: LessonSource, _messages: list[dict[str, str]]
        ) -> FixtureResult:
            initial_calls.append(lesson.lesson)
            excerpt = accepted_excerpt if lesson is first else rejected_excerpt
            return fixture_result(excerpt)

        initial = execute_run(lessons, output, default_config, initial_transport)
        assert initial_calls == [first.lesson, second.lesson]
        assert initial["accepted"] == 1
        assert initial["rejected"] == 1
        manifest_path = output / "manifest.json"
        manifest_before_subset = manifest_path.read_text(encoding="utf-8")
        assert len(json.loads(manifest_before_subset)["lessons"]) == 2

        selected = select_lessons(lessons, [second.lesson])
        subset_calls: list[str] = []

        def subset_transport(
            lesson: LessonSource, _messages: list[dict[str, str]]
        ) -> FixtureResult:
            subset_calls.append(lesson.lesson)
            return fixture_result(rejected_excerpt)

        subset = execute_run(
            lessons,
            output,
            default_config,
            subset_transport,
            selected_lessons=selected,
        )
        assert subset_calls == [second.lesson]
        assert subset["total"] == 2
        assert subset["accepted"] == 1
        assert subset["rejected"] == 1
        assert manifest_path.read_text(encoding="utf-8") == manifest_before_subset

        raised_config = RunConfig(
            grade=6,
            unit=None,
            limit=2,
            model="glm-5.2",
            budget=65536,
            endpoint_class="offline_fixture",
            dry_run=True,
        )
        raised = execute_run(
            lessons,
            output,
            raised_config,
            lambda _lesson, _messages: fixture_result(accepted_excerpt),
            selected_lessons=selected,
        )
        assert raised["accepted"] == 2
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        assert manifest["budget"] == 65536
        assert len(manifest["budget_history"]) == 1
        history = manifest["budget_history"][0]
        assert history["from"] == DEFAULT_BUDGET
        assert history["to"] == 65536
        assert isinstance(history["raised_at"], str)
        second_checkpoint = json.loads(
            (output / "checkpoints" / f"{second.lesson}.json").read_text(
                encoding="utf-8"
            )
        )
        assert second_checkpoint["budget"] == 65536

        try:
            execute_run(
                lessons,
                output,
                default_config,
                lambda _lesson, _messages: fixture_result(accepted_excerpt),
                selected_lessons=selected,
            )
        except ValueError as exc:
            assert "below manifest budget" in str(exc)
        else:
            raise AssertionError("a budget decrease did not fail")

        try:
            select_lessons(lessons, ["NO-SUCH-ID"])
        except ValueError as exc:
            assert "NO-SUCH-ID" in str(exc)
        else:
            raise AssertionError("an unknown lesson id did not fail")
    print("PASS filtered retry preserves full accounting and records budget raises")


def main() -> int:
    test_parse_and_accept()
    test_exact_fence_and_commentary_rejection()
    test_partial_lesson_and_verifier()
    test_outcome_branching_and_failure_vocabulary()
    test_whitespace_is_the_only_forgiveness()
    test_image_split_stem_and_options_accept()
    test_text_incomplete_inline_image_operand_accepts()
    test_control_calibration_and_leak_detection()
    test_default_budget()
    test_atomic_checkpoint_and_accepted_resume()
    test_filtered_retry_and_budget_raise()
    print("PASS g68 harvest offline fixture suite")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
