#!/usr/bin/env python3
"""Gate the A-vs-Q run with short contract checks and offline fixtures."""
from __future__ import annotations

import argparse
import json
import logging
import re
import sys
import tempfile
from types import SimpleNamespace
from pathlib import Path
from typing import Any
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[3]
QUESTIONNAIRE = ROOT / "scripts/research/questionnaire"
HERE = Path(__file__).resolve().parent
for path in (str(QUESTIONNAIRE), str(HERE)):
    if path not in sys.path:
        sys.path.insert(0, path)

from build_choice_sets import Choice, compile_choice_sets  # noqa: E402
from openai_compat_client import OpenAICompatibleQuestionnaireClient  # noqa: E402
from runner import (  # noqa: E402
    Question,
    ResponseKind,
    StdioHermesClient,
    TransportStatus,
    load_call_contract,
    request_for_question,
)

import ab_score  # noqa: E402
import arm_compiler  # noqa: E402
import arm_questionnaire  # noqa: E402
from corpus import items_from_rows  # noqa: E402
from ledger import AppendLedger, SCHEMA, read_rows  # noqa: E402


DEFAULT_MODEL = "gemma-4-E2B-it"
DEFAULT_ENDPOINT = "http://127.0.0.1:8080/v1/chat/completions"
SPEC = ROOT / ".superpowers/sdd/task-2026-08-08-ab-experiment-spec.md"


class PreflightFailure(RuntimeError):
    pass


class LiveSymbolicGate:
    """Run the two registered symbolic checks through the live local stack."""

    def __init__(self, probe: Any) -> None:
        self.probe = probe
        self.client = StdioHermesClient()

    def check_solution_steps(self) -> tuple[bool, int | None]:
        first, event = arm_compiler.arithmetic_outcome(
            self.probe, ["2 + 2 = 5"],
        )
        return bool(event["success"]), first

    def strategy_trace(self) -> dict[str, Any] | None:
        return self.client.call_tool(
            "strategy_trace",
            {"strategy": "fair_share_equal_groups", "input": {"a": 12, "b": 3}},
        )

    def close(self) -> None:
        self.client.close()


class FixtureSymbolicGate:
    def __init__(self, *, abort: bool = False) -> None:
        self.abort = abort

    def check_solution_steps(self) -> tuple[bool, int | None]:
        return (False, None) if self.abort else (True, 1)

    def strategy_trace(self) -> dict[str, Any] | None:
        if self.abort:
            return None
        return {
            "ok": True,
            "strategy": "fair_share_equal_groups",
            "expected": "4",
            "result": "4",
            "validity": "correct",
        }

    def close(self) -> None:
        return None


def _letter_question(excerpt: str, question: str, labels: tuple[str, str]) -> Question:
    return Question(
        level="L1",
        text=question,
        excerpt=excerpt,
        page_index=0,
        page_count=1,
        choices=(
            Choice("A", "first", labels[0], labels[0]),
            Choice("B", "second", labels[1], labels[1]),
            Choice("X", "abstain", "none of these / cannot tell", None),
        ),
    )


def _transcription_question(excerpt: str) -> Question:
    return Question(
        level="L4/L5",
        text="Write the student's operation exactly as written.",
        excerpt=excerpt,
        page_index=0,
        page_count=1,
        context={"binding_mode": "symbol_equation"},
        response_kind=ResponseKind.TRANSCRIPTION.value,
    )


def _prompt(question: Question, contract: dict[str, Any]) -> str:
    if question.response_kind == ResponseKind.TRANSCRIPTION.value:
        return contract["binding_prompt_templates"]["symbol_equation"].format(
            excerpt=question.excerpt,
        )
    choices = "\n".join(f"{choice.letter} — {choice.label}" for choice in question.choices)
    return contract["prompt_template"].format(
        excerpt=question.excerpt,
        question=question.text,
        choices=choices,
    )


def authored_questions() -> tuple[Question, ...]:
    return (
        _letter_question("Student step: 3 + 4 = 7", "Which operation appears?", ("addition", "division")),
        _letter_question("Student step: 9 - 2 = 7", "Which operation appears?", ("subtraction", "multiplication")),
        _letter_question("Student step: 3 times 5 = 15", "Which operation appears?", ("multiplication", "addition")),
        _letter_question("Student step: 12 / 3 = 4", "Which operation appears?", ("division", "subtraction")),
        _transcription_question("Student step: 3 + 4 = 7"),
        _transcription_question("Student step: 9 - 2 = 7"),
    )


def run_preflight(
    *,
    client: OpenAICompatibleQuestionnaireClient,
    compiler_completion: arm_compiler.Completion,
    fixture: bool = False,
    symbolic_gate: Any | None = None,
) -> dict[str, int]:
    contract = load_call_contract()
    navigation = transcriptions = non_ok = 0
    for question in authored_questions():
        outcome = client.complete(
            question,
            _prompt(question, contract),
            request_for_question(contract, question),
        )
        if outcome.status is not TransportStatus.OK or outcome.parse_ok is not True:
            non_ok += 1
            continue
        if question.response_kind == ResponseKind.LETTER.value:
            navigation += int(outcome.content in {choice.letter for choice in question.choices})
        else:
            transcriptions += int(outcome.content in question.excerpt)
    if navigation / 4 < 0.9:
        raise PreflightFailure(f"navigation contract failed: {navigation}/4 valid letters")
    if transcriptions != 2:
        raise PreflightFailure(f"transcription contract failed: {transcriptions}/2 verbatim-present")
    if non_ok:
        raise PreflightFailure(f"model contract returned {non_ok} non-ok parses")

    probe = arm_compiler.load_probe(fixture=fixture)
    binding_cases = (
        ("There are 3 red counters and 4 blue counters.", "3 + 4 = 7"),
        ("Nine counters lose two counters.", "9 - 2 = 7"),
    )
    binding_pass = 0
    for problem, step in binding_cases:
        bindings, transport = arm_compiler.bindings_for(
            probe,
            problem,
            step,
            model=DEFAULT_MODEL,
            completion=compiler_completion,
        )
        if transport["status"] == "ok" and bindings and all(
            binding.magnitude and binding.kind and binding.span
            for binding in bindings
        ):
            binding_pass += 1
    if binding_pass != 2:
        raise PreflightFailure(f"compiler binding contract failed: {binding_pass}/2 well-formed")
    owned_gate = symbolic_gate is None
    symbolic_gate = symbolic_gate if symbolic_gate is not None else LiveSymbolicGate(probe)
    try:
        arithmetic_ok, first = symbolic_gate.check_solution_steps()
        if not arithmetic_ok or first != 1:
            raise PreflightFailure(
                f"symbolic check_solution_steps failed: success={arithmetic_ok} first={first}"
            )
        trace = symbolic_gate.strategy_trace()
        if not (
            isinstance(trace, dict)
            and trace.get("ok") is True
            and str(trace.get("expected")) == "4"
            and str(trace.get("result")) == "4"
            and trace.get("validity") == "correct"
        ):
            raise PreflightFailure(f"symbolic strategy_trace failed: {trace!r}")
    finally:
        if owned_gate:
            symbolic_gate.close()
    return {
        "navigation": navigation,
        "transcriptions": transcriptions,
        "non_ok": non_ok,
        "compiler_bindings": binding_pass,
        "symbolic_checks": 2,
    }


class FixtureOpenAITransport:
    def __init__(self, *, abort: bool = False) -> None:
        self.abort = abort
        self.payloads: list[dict[str, Any]] = []

    def __call__(self, payload: dict[str, Any], timeout: float) -> dict[str, Any]:
        del timeout
        self.payloads.append(payload)
        prompt = payload["messages"][0]["content"]
        if self.abort:
            content = "A because the first choice fits"
        elif "Write the student's operation exactly as written" in prompt:
            content = "9 - 2 = 7" if "9 - 2 = 7" in prompt else "3 + 4 = 7"
        else:
            content = "A"
        return {
            "choices": [{"message": {"content": content}, "finish_reason": "stop"}],
            "usage": {"prompt_tokens": 10, "completion_tokens": 1, "total_tokens": 11},
        }


class FixtureCompilerCompletion:
    def __init__(self) -> None:
        self.usage = arm_compiler.Usage()
        self.history: list[dict[str, Any]] = []
        self.prompts: list[str] = []

    def __call__(self, prompt: str, *, num_predict: int) -> str:
        assert num_predict == 2048
        self.prompts.append(prompt)
        self.usage.model_calls += 1
        self.usage.prompt_tokens += 12
        self.usage.completion_tokens += 6
        self.usage.total_tokens += 18
        self.history.append({"status": "ok", "attempts": [{"finish_reason": "stop"}]})
        step = prompt.split("Student step:\n", 1)[-1]
        for equation in (
            "12 / 3 = 5",
            "12 / 3 = 4",
            "47 + 28 = 615",
            "47 + 28 = 75",
        ):
            if equation in step:
                values = sorted(set(re.findall(r"\d+", equation)), key=equation.index)
                kind = "objects" if "+" in equation else "unbound"
                return "\n".join(f"{value}\t{kind}\t{value}" for value in values)
        if "3 + 4 = 7" in step:
            return "3\tcounters\t3\n4\tcounters\t4\n7\tcounters\t7"
        if "9 - 2 = 7" in step:
            return "9\tcounters\t9\n2\tcounters\t2\n7\tcounters\t7"
        return ""


class FixtureStepTransport:
    def __call__(self, payload: dict[str, Any], timeout: float) -> dict[str, Any]:
        del timeout
        prompt = payload["messages"][0]["content"]
        if "Write the student's operation exactly as written" in prompt:
            for equation in (
                "47 + 28 = 615",
                "47 + 28 = 75",
                "12 / 3 = 5",
                "12 / 3 = 4",
            ):
                if equation in prompt:
                    content = equation
                    break
            else:
                content = ""
        else:
            content = "A" if "fair share equal groups form" in prompt else "B"
        return {
            "choices": [{"message": {"content": content}, "finish_reason": "stop"}],
            "usage": {"prompt_tokens": 8, "completion_tokens": 5, "total_tokens": 13},
        }


def _synthetic_items() -> list[Any]:
    rows = [
        (9001, {
            "problem": "There are 47 objects and 28 more objects are added.",
            "student_incorrect_solution": ["47 + 28 = 615", "Final answer: 615"],
            "reference_solution": "47 + 28 = 75\nFinal answer: 75",
        }),
        (9002, {
            "problem": "Twelve objects are shared equally among three groups.",
            "student_incorrect_solution": ["12 / 3 = 5", "Final answer: 5"],
            "reference_solution": "12 / 3 = 4\nFinal answer: 4",
        }),
    ]
    return list(items_from_rows(rows))


def fixture_end_to_end(directory: Path) -> None:
    items = _synthetic_items()
    compiler_path = directory / "compiler.jsonl"
    q_path = directory / "questionnaire.jsonl"
    compiler_completion = FixtureCompilerCompletion()
    compiler_ledger = AppendLedger(compiler_path)
    first = arm_compiler.run_items(
        items,
        compiler_ledger,
        model="fixture-model",
        completion=compiler_completion,
        fixture=True,
    )
    second = arm_compiler.run_items(
        items,
        AppendLedger(compiler_path),
        model="fixture-model",
        completion=compiler_completion,
        fixture=True,
    )
    assert first == (4, 0) and second == (0, 4)

    client = OpenAICompatibleQuestionnaireClient(
        model="fixture-model", transport=FixtureStepTransport(),
    )
    symbolic = StdioHermesClient()
    try:
        q_first = arm_questionnaire.run_items(
            items,
            AppendLedger(q_path),
            client=client,
            symbolic=symbolic,
            compiled=compile_choice_sets(),
        )
        q_second = arm_questionnaire.run_items(
            items,
            AppendLedger(q_path),
            client=client,
            symbolic=symbolic,
            compiled=compile_choice_sets(),
        )
    finally:
        symbolic.close()
    assert q_first == (4, 0) and q_second == (0, 4)
    assert len(read_rows(compiler_path)) == 4 and len(read_rows(q_path)) == 4
    for arm_rows in (read_rows(compiler_path), read_rows(q_path)):
        for item in items[::2]:
            incorrect = next(
                row for row in arm_rows
                if row["index"] == item.index and row["side"] == "incorrect"
            )
            correct = next(
                row for row in arm_rows
                if row["index"] == item.index and row["side"] == "correct"
            )
            assert incorrect["receipts"], incorrect
            assert correct["receipts"] == [], correct

    try:
        list(items_from_rows([(1, {
            "problem": "fixture",
            "student_incorrect_solution": ["12 / 3 = 4", "4"],
            "reference_solution": "12 / 3 = 4\n4",
            "incorrect_index": 0,
        })]))
    except ValueError as exc:
        assert "incorrect_index" in str(exc)
    else:
        raise AssertionError("excluded-field guard accepted incorrect_index")
    print(
        "AB END-TO-END FIXTURES: PASS arms=compiler+questionnaire items=2 pairs=4 "
        "resume_appends=0 addition_incorrect_receipt=both_arms "
        "addition_correct_receipts=0 division_side_correctness=both_arms "
        "excluded_field_guard=incorrect_index sockets=0 swipl=local"
    )


def fixture_licensed_result_inversion() -> None:
    leaf = {
        "ok": True,
        "strategy": "append_column_sum_without_carrying",
        "expected": "75",
        "result": "615",
        "validity": "incorrect",
    }
    base = {
        "status": "leaf_computed",
        "leaf": leaf,
        "operand": {"a": 47, "b": 28},
        "ledger": [{
            "kind": "leaf_call",
            "tool": "strategy_trace",
            "strategy": "append_column_sum_without_carrying",
        }],
    }
    correct = SimpleNamespace(**base, got="75")
    planted = SimpleNamespace(**base, got="615")
    correct_receipt, correct_abstention = arm_questionnaire._receipt(
        correct, "47 + 28 = 75", 1,
    )
    planted_receipt, planted_abstention = arm_questionnaire._receipt(
        planted, "47 + 28 = 615", 1,
    )
    assert correct_receipt is None and correct_abstention is None
    assert planted_receipt is not None and planted_abstention is None
    assert planted_receipt["licensed_result"] == "75"
    assert planted_receipt["got"] == "615"
    assert arm_questionnaire._has_comparable_licensed_value(correct) is True
    assert arm_questionnaire._has_comparable_licensed_value(planted) is True
    assert str(correct.got) != str(leaf["result"])
    print(
        "LICENSED RESULT INVERSION FIXTURE: PASS expected=75 result=615 "
        "validity=incorrect incorrect_receipts=1 correct_receipts=0"
    )


def fixture_producer_dedup_and_normalization() -> None:
    item = next(iter(items_from_rows([(9101, {
        "problem": "There are 47 objects and 28 more objects are added.",
        "student_incorrect_solution": ["47 + 28 = 615", "Final answer: 615"],
        "reference_solution": "47 + 28 = 75\nFinal answer: 75",
    })])))
    row = arm_compiler.run_item(
        item,
        model="fixture-model",
        completion=FixtureCompilerCompletion(),
        fixture=True,
    )
    assert len(row["receipts"]) == 1, row
    assert row["receipts"][0]["normalized_claim"] == (
        "sum(quantity(objects),quantity(objects))=quantity(objects)"
    )
    duplicates = [
        event for event in row["events"]
        if event.get("kind") == "duplicate_accusation"
    ]
    assert len(duplicates) == 1
    assert duplicates[0]["receipt"]["normalized_claim"] == "operator(sum)"
    assert sum(
        event.get("kind") == "symbolic_leaf" and event.get("success") is True
        for event in row["events"]
    ) == 2
    print(
        "COMPILER PRODUCER DEDUP FIXTURE: PASS quantity_verdict=refuted "
        "arithmetic_verdict=refuted accusations=1 normalized_values=elided"
    )


def fixture_questionnaire_abstention_and_normalization() -> None:
    valid_leaf = {
        "ok": True,
        "strategy": "fair_share_equal_groups",
        "expected": "4",
        "result": "4",
        "validity": "correct",
    }
    result = SimpleNamespace(
        status="leaf_computed",
        leaf=valid_leaf,
        operand={"a": 12, "b": 3},
        got="5",
        ledger=[{
            "kind": "leaf_call",
            "tool": "strategy_trace",
            "strategy": "fair_share_equal_groups",
        }],
    )
    receipt, abstention = arm_questionnaire._receipt(result, "12 / 3 = 5", 1)
    assert abstention is None
    assert receipt is not None
    assert arm_questionnaire._has_comparable_licensed_value(result) is True
    assert json.loads(receipt["normalized_claim"]) == {
        "operator": "division",
        "strategy": "fair_share_equal_groups",
    }

    non_numeric = SimpleNamespace(
        status="leaf_computed",
        leaf={**valid_leaf, "expected": "four", "result": "four"},
        operand={"a": 12, "b": 3},
        got="five",
        ledger=[],
    )
    receipt, abstention = arm_questionnaire._receipt(
        non_numeric, "twelve / three = five", 1,
    )
    assert receipt is None
    assert abstention is not None
    assert abstention["reason"] == "licensed_value_non_numeric"
    assert arm_questionnaire._has_comparable_licensed_value(non_numeric) is False
    print(
        "QUESTIONNAIRE CLAIM FIXTURE: PASS normalized=(strategy,operator) "
        "noncomparable=abstention"
    )


def _row(
    arm: str,
    side: str,
    receipts: list[dict[str, Any]],
    *,
    calls: int = 0,
    tokens: int = 0,
    symbolic_ran: bool = True,
    symbolic_success: bool = True,
) -> dict[str, Any]:
    return {
        "schema": SCHEMA,
        "arm": arm,
        "index": 1,
        "side": side,
        "problem": "fixture",
        "steps": ["1 + 1 = 3", "2 + 2 = 5"],
        "receipts": receipts,
        "events": [{
            "kind": "symbolic_leaf",
            "tool": "fixture",
            "ran": symbolic_ran,
            "success": symbolic_success,
        }],
        "usage": {
            "model_calls": calls,
            "prompt_tokens": 0,
            "completion_tokens": tokens,
            "total_tokens": tokens,
        },
    }


def _r(
    claim: str,
    *,
    step: int = 1,
    span: str | None = None,
    verdict: str = "refuted",
    tool: str = "strategy_trace",
    accusation: bool | None = None,
) -> dict[str, Any]:
    if span is None:
        span = "1 + 1 = 3" if step == 1 else "2 + 2 = 5"
    return {
        "step": step,
        "source_span": span,
        "tool": tool,
        "verdict": verdict,
        "normalized_claim": claim,
        "accusation": verdict == "refuted" if accusation is None else accusation,
    }


def _fixture_expected(rows: list[dict[str, Any]]) -> dict[tuple[int, str], list[str]]:
    return {
        (row["index"], row["side"]): list(row["steps"])
        for row in rows
    }


def fixture_scorer() -> None:
    cases: list[tuple[str, list[dict[str, Any]], str]] = []
    cases.append(("T1", [
        _row("compiler", "incorrect", [_r("compiler-wrong")]),
        _row("compiler", "correct", [_r("compiler-false-positive")]),
        _row("questionnaire", "incorrect", [_r("q-wrong")]),
        _row("questionnaire", "correct", []),
    ], "questionnaire"))
    cases.append(("T2", [
        _row("compiler", "incorrect", [_r("compiler-one")]),
        _row("compiler", "correct", []),
        _row("questionnaire", "incorrect", [
            _r("q-one"),
            _r("q-two", step=2),
            _r("q-nonverbatim", span="not in the step", accusation=False),
            _r("q-not-checked", verdict="not_checked"),
        ]),
        _row("questionnaire", "correct", []),
    ], "questionnaire"))
    cases.append(("T3", [
        _row("compiler", "incorrect", [_r("compiler-one")], calls=4, tokens=40),
        _row("compiler", "correct", []),
        _row("questionnaire", "incorrect", [_r("q-one")], calls=2, tokens=20),
        _row("questionnaire", "correct", []),
    ], "questionnaire"))
    cases.append(("F", [
        _row("compiler", "incorrect", []),
        _row("compiler", "correct", []),
        _row("questionnaire", "incorrect", []),
        _row("questionnaire", "correct", []),
    ], ""))

    for name, rows, selected in cases:
        print(f"SCORER FIXTURE {name} TRACE")
        summary, trace = ab_score.score_rows(
            rows,
            indexes=[1],
            expected_steps=_fixture_expected(rows),
        )
        for line in trace:
            print(line)
        if selected:
            assert summary["decision"] == {"tier": name, "selected_arm": selected}
        if name == "T2":
            assert summary["rejected_receipts"]["questionnaire"] == {
                "non_verbatim_span": 1,
                "not_checked_verdict": 1,
            }
        if name == "F":
            assert ab_score.FALSIFIER_Q in trace
            assert ab_score.FALSIFIER_BOTH in trace
        print(f"SCORER FIXTURE {name}: PASS")

    instrument_rows = [
        _row("compiler", "incorrect", []),
        _row("compiler", "correct", []),
        _row(
            "questionnaire", "incorrect", [],
            symbolic_ran=True, symbolic_success=False,
        ),
        _row(
            "questionnaire", "correct", [],
            symbolic_ran=True, symbolic_success=False,
        ),
    ]
    print("SCORER FIXTURE INSTRUMENT TRACE")
    instrument, trace = ab_score.score_rows(
        instrument_rows,
        indexes=[1],
        expected_steps=_fixture_expected(instrument_rows),
    )
    for line in trace:
        print(line)
    assert instrument["decision"]["tier"] == "instrument_failure"
    assert "INSTRUMENT FAILURE: arm=questionnaire successful_symbolic_leaves=0" in trace
    assert ab_score.FALSIFIER_Q not in trace and ab_score.FALSIFIER_BOTH not in trace
    print(
        "SCORER FIXTURE INSTRUMENT: PASS ran_noncomparable=2 "
        "successful_symbolic_leaves=0 falsifier=suppressed"
    )

    blocked_rows = [
        _row("compiler", "incorrect", [
            _r("operator(sum)", tool="check_solution_steps"),
        ]),
        _row("compiler", "correct", [
            _r(
                "operator(sum)",
                tool="check_solution_steps",
                verdict="refuted",
                accusation=False,
            ),
        ]),
        _row("questionnaire", "incorrect", [_r("q-distinction")]),
        _row("questionnaire", "correct", []),
    ]
    blocked, _ = ab_score.score_rows(
        blocked_rows,
        indexes=[1],
        expected_steps=_fixture_expected(blocked_rows),
    )
    assert blocked["licensed_differentiating_receipts"]["compiler"] == 0
    assert blocked["rejected_receipts"]["compiler"] == {"present_on_paired_correct": 1}
    print("SCORER FIXTURE NORMALIZED TUPLE: PASS paired_nonaccusation_receipt=blocking")

    dedup_rows = [
        _row("compiler", "incorrect", [_r("quantity-shape"), _r("operator(sum)")]),
        _row("compiler", "correct", [_r("correct-a"), _r("correct-b")]),
        _row("questionnaire", "incorrect", [_r("q-one")]),
        _row("questionnaire", "correct", []),
    ]
    dedup, _ = ab_score.score_rows(
        dedup_rows,
        indexes=[1],
        expected_steps=_fixture_expected(dedup_rows),
    )
    assert dedup["licensed_differentiating_receipts"]["compiler"] == 1
    assert dedup["correct_solution_accusations"]["compiler"] == 1
    assert dedup["rejected_receipts"]["compiler"]["duplicate_accusation"] == 1
    print("SCORER FIXTURE ACCUSATION DEDUP: PASS incorrect=1 correct=1")

    licence_first_rows = [
        _row("compiler", "incorrect", [
            _r("rejected-first", span="not in the step"),
            _r("licensed-second"),
        ]),
        _row("compiler", "correct", []),
        _row("questionnaire", "incorrect", [_r("q-one")]),
        _row("questionnaire", "correct", []),
    ]
    licence_first, _ = ab_score.score_rows(
        licence_first_rows,
        indexes=[1],
        expected_steps=_fixture_expected(licence_first_rows),
    )
    assert licence_first["licensed_differentiating_receipts"]["compiler"] == 1
    assert licence_first["rejected_receipts"]["compiler"] == {
        "non_verbatim_span": 1,
    }
    print(
        "SCORER FIXTURE LICENCE-BEFORE-DEDUP: PASS "
        "rejected_first=ignored licensed_second=counted"
    )

    mismatch_rows = [dict(row) for row in cases[0][1]]
    mismatch_rows[0] = {**mismatch_rows[0], "steps": ["producer drift"]}
    try:
        ab_score.score_rows(
            mismatch_rows,
            indexes=[1],
            expected_steps=_fixture_expected(cases[0][1]),
        )
    except ValueError as exc:
        assert "scorer step mismatch" in str(exc)
    else:
        raise AssertionError("scorer accepted producer step drift")
    print("SCORER FIXTURE CORPUS STEP CHECK: PASS mismatch=rejected")


def fixture_ledger_resume(directory: Path) -> None:
    final_path = directory / "torn-final.jsonl"
    first_row = _row("compiler", "incorrect", [])
    next_row = _row("compiler", "correct", [])
    AppendLedger(final_path).append(first_row)
    with final_path.open("a", encoding="utf-8") as stream:
        stream.write('{"schema":"torn"')

    try:
        read_rows(final_path)
    except ValueError as exc:
        assert "invalid JSONL" in str(exc)
    else:
        raise AssertionError("read_rows skipped a torn final line without repair")

    records: list[logging.LogRecord] = []

    class Capture(logging.Handler):
        def emit(self, record: logging.LogRecord) -> None:
            records.append(record)

    logger = logging.getLogger("ledger")
    handler = Capture()
    logger.addHandler(handler)
    try:
        resumed = AppendLedger(final_path)
        assert len(resumed.rows) == 1
        assert resumed.append(next_row) is True
    finally:
        logger.removeHandler(handler)
    repaired_rows = read_rows(final_path)
    assert [row["side"] for row in repaired_rows] == ["incorrect", "correct"]
    assert any("scheduled for repair" in record.getMessage() for record in records)
    assert any("repaired torn final JSONL tail" in record.getMessage() for record in records)

    interior_path = directory / "torn-interior.jsonl"
    encoded = json.dumps(first_row, ensure_ascii=False, sort_keys=True)
    interior_path.write_text(
        encoded + "\n" + '{"schema":"torn"' + "\n" + encoded + "\n",
        encoding="utf-8",
    )
    try:
        read_rows(interior_path)
    except ValueError as exc:
        assert "invalid JSONL" in str(exc)
    else:
        raise AssertionError("ledger accepted a torn interior line")
    print(
        "LEDGER TORN-LINE FIXTURE: PASS final=repaired "
        "appended_row=survives interior=rejected"
    )


def fixture_empty_content() -> None:
    question = authored_questions()[0]
    contract = load_call_contract()
    request = request_for_question(contract, question)
    prompt = _prompt(question, contract)
    for label, content in (("null", None), ("empty", "")):
        def transport(
            payload: dict[str, Any], timeout: float, *, value: Any = content,
        ) -> dict[str, Any]:
            del payload, timeout
            return {
                "choices": [{"message": {"content": value}, "finish_reason": "stop"}],
                "usage": {"completion_tokens": 0},
            }

        client = OpenAICompatibleQuestionnaireClient(
            model="fixture-model", transport=transport,
        )
        outcome = client.complete(question, prompt, request)
        assert outcome.status is TransportStatus.EMPTY_CONTENT, (label, outcome)
    print("OPENAI CONTENT FIXTURE: PASS null=EMPTY_CONTENT empty=EMPTY_CONTENT")


def fixture_falsifier_constants_and_summary_path() -> None:
    text = SPEC.read_text(encoding="utf-8")
    section = text.split("## 3. The decision rule", 1)[1].split("## 4.", 1)[0]
    normalized_section = " ".join(section.split())
    assert ab_score.FALSIFIER_Q in normalized_section
    assert ab_score.FALSIFIER_BOTH in normalized_section
    default_path = ab_score.default_summary_path("fixture-run")
    assert default_path.name == "summary-fixture-run.json"
    assert default_path.parent == ab_score.RUNTIME_ROOT
    print(
        "SPEC CONSTANT FIXTURE: PASS falsifiers=section-3 "
        "default_summary=summary-fixture-run.json"
    )


def fixture_preflight() -> None:
    passing_transport = FixtureOpenAITransport()
    passing = OpenAICompatibleQuestionnaireClient(
        model="fixture-model", transport=passing_transport,
    )
    compiler_completion = FixtureCompilerCompletion()
    result = run_preflight(
        client=passing,
        compiler_completion=compiler_completion,
        fixture=True,
        symbolic_gate=FixtureSymbolicGate(),
    )
    assert result == {
        "navigation": 4,
        "transcriptions": 2,
        "non_ok": 0,
        "compiler_bindings": 2,
        "symbolic_checks": 2,
    }
    assert len(passing_transport.payloads) == 6
    assert [payload["max_tokens"] for payload in passing_transport.payloads] == [8, 8, 8, 8, 24, 24]
    assert all(
        payload["temperature"] == 0
        and payload["stream"] is False
        and list(payload) == ["model", "messages", "temperature", "max_tokens", "stream"]
        for payload in passing_transport.payloads
    )
    assert len(compiler_completion.prompts) == 2
    assert all(
        prompt.startswith("Bind each magnitude to the kind it measures. One line per magnitude: ")
        and "\n\nProblem:\n" in prompt
        and "\n\nStudent step:\n" in prompt
        for prompt in compiler_completion.prompts
    )
    print(
        "AB PREFLIGHT FIXTURE PASS: navigation=4/4 transcriptions=2/2 "
        "non_ok=0 compiler_bindings=2/2 symbolic_checks=2/2"
    )
    aborting = OpenAICompatibleQuestionnaireClient(
        model="fixture-model", transport=FixtureOpenAITransport(abort=True),
    )
    try:
        run_preflight(
            client=aborting,
            compiler_completion=FixtureCompilerCompletion(),
            fixture=True,
            symbolic_gate=FixtureSymbolicGate(),
        )
    except PreflightFailure as exc:
        print(f"AB PREFLIGHT FIXTURE ABORT: PASS reason={exc}")
    else:
        raise AssertionError("preflight abort fixture passed")
    symbolic_aborting = OpenAICompatibleQuestionnaireClient(
        model="fixture-model", transport=FixtureOpenAITransport(),
    )
    try:
        run_preflight(
            client=symbolic_aborting,
            compiler_completion=FixtureCompilerCompletion(),
            fixture=True,
            symbolic_gate=FixtureSymbolicGate(abort=True),
        )
    except PreflightFailure as exc:
        assert "symbolic check_solution_steps failed" in str(exc)
        print(f"AB PREFLIGHT SYMBOLIC ABORT FIXTURE: PASS reason={exc}")
    else:
        raise AssertionError("symbolic preflight abort fixture passed")


def run_fixture_suite() -> None:
    socket_count = 0

    def forbidden_socket(*unused_args: Any, **unused_kwargs: Any) -> Any:
        nonlocal socket_count
        socket_count += 1
        raise AssertionError("A-vs-Q fixture attempted to open a socket")

    with patch("socket.socket", forbidden_socket):
        with tempfile.TemporaryDirectory(prefix="ab_experiment_fixture_") as directory:
            fixture_directory = Path(directory)
            fixture_end_to_end(fixture_directory)
            fixture_ledger_resume(fixture_directory)
        fixture_licensed_result_inversion()
        fixture_producer_dedup_and_normalization()
        fixture_questionnaire_abstention_and_normalization()
        fixture_scorer()
        fixture_empty_content()
        fixture_falsifier_constants_and_summary_path()
        fixture_preflight()
    assert socket_count == 0
    print("AB EXPERIMENT FIXTURE SUITE: PASS sockets=0")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--fixture", action="store_true")
    parser.add_argument("--model", default=DEFAULT_MODEL)
    parser.add_argument("--endpoint", default=DEFAULT_ENDPOINT)
    parser.add_argument("--timeout", type=float, default=300.0)
    args = parser.parse_args()
    if args.fixture:
        run_fixture_suite()
        return 0
    client = OpenAICompatibleQuestionnaireClient(
        model=args.model,
        endpoint=args.endpoint,
        timeout=args.timeout,
    )
    completion = arm_compiler.LlamaCompletion(model=args.model, endpoint=args.endpoint)
    try:
        result = run_preflight(client=client, compiler_completion=completion)
    except PreflightFailure as exc:
        print(f"AB PREFLIGHT: ABORT {exc}")
        return 2
    print(
        "AB PREFLIGHT: PASS "
        f"navigation={result['navigation']}/4 "
        f"transcriptions={result['transcriptions']}/2 "
        f"non_ok={result['non_ok']} "
        f"compiler_bindings={result['compiler_bindings']}/2 "
        f"symbolic_checks={result['symbolic_checks']}/2"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
