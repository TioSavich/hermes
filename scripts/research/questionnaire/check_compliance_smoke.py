#!/usr/bin/env python3
"""Check a questionnaire compliance-smoke JSONL ledger."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any, Iterable


RECOGNIZED_ABSTENTION_STATUSES = {"not_covered", "extraction_incomplete"}


def terminal_recognition(item: dict[str, Any]) -> dict[str, Any]:
    """Classify the item terminal from its runner receipt and ledger evidence."""
    status = item.get("result_status")
    runner = item.get("runner")
    if not isinstance(runner, dict) or runner.get("status") != status:
        return {"recognized": False, "status": status, "reason": "runner_status_mismatch"}
    ledger = runner.get("ledger")
    if not isinstance(ledger, list) or any(not isinstance(event, dict) for event in ledger):
        return {"recognized": False, "status": status, "reason": "malformed_runner_ledger"}
    leaf_events = [event for event in ledger if event.get("kind") == "leaf_call"]
    row_leaf_events = item.get("leaf_operation_invocations")
    if not isinstance(row_leaf_events, list) or row_leaf_events != leaf_events:
        return {"recognized": False, "status": status, "reason": "leaf_receipt_mismatch"}

    if status == "leaf_computed":
        complete = (
            len(leaf_events) == 1
            and runner.get("family") is not None
            and runner.get("schema_id") is not None
            and runner.get("leaf") is not None
        )
        return {
            "recognized": complete,
            "status": status,
            "reason": "leaf_receipt" if complete else "malformed_leaf_terminal",
        }

    if status not in RECOGNIZED_ABSTENTION_STATUSES:
        return {"recognized": False, "status": status, "reason": "unknown_terminal_status"}
    if leaf_events:
        return {"recognized": False, "status": status, "reason": "abstention_has_leaf_call"}
    terminal_events = [event for event in ledger if event.get("kind") == "terminal"]
    if any(event.get("status") != status or not event.get("reason") for event in terminal_events):
        return {"recognized": False, "status": status, "reason": "malformed_terminal_event"}
    system_abstentions = [event for event in ledger if event.get("kind") == "system_abstention"]
    evidence = system_abstentions or terminal_events
    return {
        "recognized": bool(evidence),
        "status": status,
        "reason": "abstention_receipt" if evidence else "missing_abstention_receipt",
    }


def load_rows(path: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not line.strip():
            continue
        value = json.loads(line)
        if not isinstance(value, dict):
            raise ValueError(f"ledger line {line_number} is not a JSON object")
        rows.append(value)
    return rows


def check_rows(rows: Iterable[dict[str, Any]]) -> dict[str, Any]:
    material = list(rows)
    summaries = [row for row in material if row.get("record_type") == "summary"]
    if len(summaries) != 1:
        raise AssertionError(f"expected one summary row, found {len(summaries)}")
    summary = summaries[0]
    if summary.get("schema") != "questionnaire_compliance_smoke_v3":
        raise AssertionError("compliance summary schema is not v3")
    items = [row for row in material if row.get("record_type") == "item"]
    if len(items) != summary.get("items_completed"):
        raise AssertionError("item-row count does not match the summary")

    terminal_rows = [terminal_recognition(item) for item in items]
    for item, recomputed in zip(items, terminal_rows):
        if item.get("terminal_recognition") != recomputed:
            raise AssertionError("item terminal-recognition record does not match its runner receipt")
    recognized = sum(row["recognized"] is True for row in terminal_rows)
    terminal_summary = summary.get("contract_compliance", {}).get("recognized_terminal", {})
    if terminal_summary.get("count") != recognized or terminal_summary.get("total") != len(items):
        raise AssertionError("recognized-terminal summary does not match item receipts")
    if recognized != len(items) or not terminal_summary.get("pass"):
        raise AssertionError("an item has an unrecognized or malformed terminal")
    leaf_items = sum(item.get("result_status") == "leaf_computed" for item in items)
    completion = summary.get("completion", {})
    if completion.get("leaf_items") != leaf_items or completion.get("items") != len(items):
        raise AssertionError("completion data does not match item terminals")
    expected_completion_rate = leaf_items / len(items) if items else 0.0
    if abs(float(completion.get("rate", -1.0)) - expected_completion_rate) > 1e-12:
        raise AssertionError("completion rate does not match item terminals")

    attempts = [attempt for item in items for attempt in item.get("model_attempts", [])]
    if len(attempts) != summary.get("model_calls"):
        raise AssertionError("model-attempt count does not match the summary")
    for attempt in attempts:
        if attempt.get("status") != "ok" and attempt.get("parsed_content") is not None:
            raise AssertionError("non-ok model content entered a parsed-content lane")

    compliance = summary.get("contract_compliance", {})
    valid = compliance.get("valid_letter", {})
    navigation = [
        attempt for attempt in attempts
        if attempt.get("response_kind") == "letter" and attempt.get("level") in {"L1", "L2"}
    ]
    exact_count = sum(attempt.get("raw_exact_one_letter") is True for attempt in navigation)
    exact_rate = exact_count / len(navigation) if navigation else 0.0
    if valid.get("count") != exact_count or valid.get("total") != len(navigation):
        raise AssertionError("valid-letter summary counts do not match the item records")
    if abs(float(valid.get("rate", -1.0)) - exact_rate) > 1e-12:
        raise AssertionError("valid-letter summary rate does not match the item records")
    if exact_rate < valid.get("threshold", 0.9):
        raise AssertionError("valid-letter rate is below the registered 90% gate")
    non_ok_content_parsed = sum(
        attempt.get("status") != "ok" and attempt.get("parsed_content") is not None
        for attempt in attempts
    )
    if compliance.get("non_ok_content_parsed") != non_ok_content_parsed:
        raise AssertionError("non-ok parsed-content summary does not match the item records")
    if non_ok_content_parsed != 0:
        raise AssertionError("non-ok content was parsed")
    probes = [probe for item in items for probe in item.get("question_sequence", [])]
    flips = sum(probe.get("flip") is True for probe in probes)
    if compliance.get("position_permutation", {}).get("flips") != flips:
        raise AssertionError("position-flip summary does not match the item records")
    if flips != 0:
        raise AssertionError("a position permutation changed a semantic answer")
    if any(probe.get("level") not in {"L1", "L2"} for probe in probes):
        raise AssertionError("position gate includes a non-navigation question")
    fidelity = compliance.get("transcription_fidelity", {})
    accepted = sum(item.get("binding_fidelity", {}).get("accepted_bindings", 0) for item in items)
    verified = sum(
        item.get("binding_fidelity", {}).get("verified_verbatim_bindings", 0)
        for item in items
    )
    if fidelity.get("accepted") != accepted or fidelity.get("verbatim_present") != verified:
        raise AssertionError("transcription-fidelity summary does not match item records")
    if accepted == 0 or verified != accepted or not fidelity.get("pass"):
        raise AssertionError("an accepted binding lacks verbatim source presence")
    if not summary.get("pass"):
        raise AssertionError("summary compliance gate is not passing")
    return summary


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("ledger", type=Path)
    args = parser.parse_args()
    summary = check_rows(load_rows(args.ledger))
    print(
        "QUESTIONNAIRE COMPLIANCE LEDGER: PASS "
        f"items={summary['items_completed']} calls={summary['model_calls']} "
        f"valid_letter_rate={summary['contract_compliance']['valid_letter']['rate']:.1%} "
        f"completion={summary['completion']['leaf_items']}/{summary['completion']['items']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
