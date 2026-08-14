#!/usr/bin/env python3
"""Build and verify the standards-router and enacted-doing receipts."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
from collections import Counter
from fractions import Fraction
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "hermes/app/runtime/experiments/language/pusu_results.jsonl"
OUTPUT = ROOT / "hermes/app/runtime/experiments/language/standards_bridge_slices34.json"
ROUTER = ROOT / "scripts/language/standards_router_runner.pl"

WORKED_EXAMPLE_IDS = [
    "im_defrag_9f0b94b9118888aa2a56a785_1",
    "im_defrag_2069bb842ec10f67b91cd3ce_1",
    "im_defrag_748d648a603084b18ef50728_1",
    "im_defrag_27b8c1d0df49a2a2c0ba6402_1",
    "im_defrag_a8ef3040648b31a223576c22_1",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    return parser.parse_args()


def read_rows() -> list[dict[str, Any]]:
    with SOURCE.open(encoding="utf-8") as handle:
        return [json.loads(line) for line in handle if line.strip()]


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def run_jsonl(command: list[str], requests: list[dict[str, Any]]) -> list[dict[str, Any]]:
    payload = "".join(
        json.dumps(request, sort_keys=True, separators=(",", ":")) + "\n"
        for request in requests
    )
    completed = subprocess.run(
        command,
        cwd=ROOT,
        input=payload,
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode != 0:
        raise RuntimeError(
            f"command failed ({completed.returncode}): {' '.join(command)}\n"
            f"{completed.stderr}"
        )
    responses = [
        json.loads(line) for line in completed.stdout.splitlines() if line.strip()
    ]
    if len(responses) != len(requests):
        raise RuntimeError(
            f"expected {len(requests)} responses, received {len(responses)}; "
            f"stderr={completed.stderr!r}"
        )
    errors = [response for response in responses if response.get("status") == "error"]
    if errors:
        raise RuntimeError(f"router returned errors: {errors[:3]}")
    return responses


def route_rows(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    requests = [
        {"id": row["record_id"], "lesson": row["lesson"], "program": row["program"]}
        for row in rows
    ]
    return run_jsonl(
        [
            "swipl",
            "--on-error=status",
            "--on-warning=status",
            "-q",
            "-l",
            "paths.pl",
            "-s",
            str(ROUTER.relative_to(ROOT)),
            "-g",
            "main",
            "-t",
            "halt",
        ],
        requests,
    )


def enact_routes(routes: list[dict[str, Any]]) -> dict[str, dict[str, Any]]:
    routed = [route for route in routes if route["status"] == "routed"]
    requests = [
        {
            "id": route["id"],
            "op": "strategy_trace",
            "strategy": route["kind"],
            "input": route["input"],
        }
        for route in routed
    ]
    responses = run_jsonl(
        ["swipl", "-q", "-l", "hermes_worker.pl", "-g", "worker_main"],
        requests,
    )
    return {response["id"]: response for response in responses}


def canonical_bytes(value: Any) -> bytes:
    return (json.dumps(value, sort_keys=True, separators=(",", ":")) + "\n").encode()


def scalar_value(value: Any) -> Fraction | None:
    text = str(value).strip()
    long_division = re.fullmatch(r"long_division_result\((-?\d+),0\)", text)
    if long_division:
        return Fraction(int(long_division.group(1)), 1)
    rational = re.fullmatch(r"(-?\d+)(?:r|/)(\d+)", text)
    if rational:
        return Fraction(int(rational.group(1)), int(rational.group(2)))
    if re.fullmatch(r"-?\d+", text):
        return Fraction(int(text), 1)
    return None


def saturator_values(row: dict[str, Any]) -> list[str]:
    return [str(answer["value"]) for answer in row.get("answer", []) if "value" in answer]


def machine_verified_values(row: dict[str, Any]) -> list[str]:
    return [str(value) for value in row.get("ground_truth", {}).get("expected_values", [])]


def three_way_comparison(
    row: dict[str, Any], worker_response: dict[str, Any]
) -> dict[str, Any]:
    saturator = saturator_values(row)
    verified = machine_verified_values(row)
    trace = worker_response.get("result", {})
    enacted = str(trace.get("result", ""))
    enacted_scalar = scalar_value(enacted)
    saturator_scalars = [scalar_value(value) for value in saturator]
    verified_scalars = [scalar_value(value) for value in verified]
    comparable = (
        trace.get("ok") is True
        and enacted_scalar is not None
        and len(saturator_scalars) == 1
        and len(verified_scalars) == 1
        and saturator_scalars[0] is not None
        and verified_scalars[0] is not None
    )
    agreement = bool(
        comparable
        and enacted_scalar == saturator_scalars[0] == verified_scalars[0]
    )
    return {
        "enacted_result": enacted,
        "saturator_answers": saturator,
        "machine_verified_answers": verified,
        "comparable": comparable,
        "three_way_agreement": agreement,
    }


def trace_summary(worker_response: dict[str, Any]) -> dict[str, Any]:
    trace = worker_response.get("result", {})
    steps = trace.get("steps", [])
    return {
        "worker_ok": worker_response.get("ok") is True,
        "machine_ok": trace.get("ok") is True,
        "representation": trace.get("representation", ""),
        "result": trace.get("result", ""),
        "expected": trace.get("expected", ""),
        "validity": trace.get("validity", ""),
        "step_count": len(steps),
        "first_step": steps[0].get("label", "") if steps else "",
        "last_step": steps[-1].get("label", "") if steps else "",
        "note": trace.get("note", ""),
    }


def receipt_row(
    source_row: dict[str, Any],
    route: dict[str, Any],
    enacted: dict[str, dict[str, Any]],
) -> dict[str, Any]:
    base: dict[str, Any] = {
        "record_id": source_row["record_id"],
        "completion_status": source_row["completion_status"],
        "lesson": source_row["lesson"],
        "route": route,
    }
    if route["status"] != "routed":
        reason = route["reason"]
        base["census_category"] = (
            "undecided(operation)"
            if reason == "undecided(operation)"
            else "contract_mismatch"
            if reason == "contract_underfilled"
            else "no_route"
        )
        base["failure_reason"] = {"reason": reason, "detail": route["detail"]}
        return base

    worker_response = enacted[route["id"]]
    summary = trace_summary(worker_response)
    comparison = three_way_comparison(source_row, worker_response)
    base["enacted_trace_summary"] = summary
    base["comparison"] = comparison
    if summary["machine_ok"]:
        base["census_category"] = "routed_cleanly"
    else:
        base["census_category"] = "contract_mismatch"
        base["failure_reason"] = {
            "reason": "machine_rejected_filled_contract",
            "detail": summary["note"],
        }
    return base


def worked_example_receipt(
    source_by_id: dict[str, dict[str, Any]],
) -> dict[str, Any]:
    rows = [source_by_id[record_id] for record_id in WORKED_EXAMPLE_IDS]
    first = route_rows(rows)
    second = route_rows(rows)
    first_bytes = canonical_bytes(first)
    second_bytes = canonical_bytes(second)
    observed_by_id = {route["id"]: route for route in first}
    expected_reasons = {
        WORKED_EXAMPLE_IDS[0]: "routed",
        WORKED_EXAMPLE_IDS[1]: "routed",
        WORKED_EXAMPLE_IDS[2]: "routed",
        WORKED_EXAMPLE_IDS[3]: "contract_underfilled",
        WORKED_EXAMPLE_IDS[4]: "thin_support",
    }
    comparisons = []
    for record_id in WORKED_EXAMPLE_IDS:
        observed = observed_by_id[record_id]
        actual = observed["status"] if observed["status"] == "routed" else observed["reason"]
        comparisons.append(
            {
                "record_id": record_id,
                "expected": expected_reasons[record_id],
                "actual": actual,
                "matches_design_reason": actual == expected_reasons[record_id],
                "route": observed,
            }
        )
    return {
        "runs_identical": first_bytes == second_bytes,
        "run_1_sha256": hashlib.sha256(first_bytes).hexdigest(),
        "run_2_sha256": hashlib.sha256(second_bytes).hexdigest(),
        "all_design_reasons_match": all(
            item["matches_design_reason"] for item in comparisons
        ),
        "examples": comparisons,
        "threshold_boundary": (
            "5.NBT.B.7 has no decimal_add row in the shipped support-at-least-three "
            "standard_doing store, so example 4 refuses at operation admission "
            "before its decimal_pair contract can be underfilled."
        ),
    }


def run_load_audit(command: list[str], forbidden: tuple[str, ...]) -> list[str]:
    completed = subprocess.run(
        command,
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode != 0:
        raise RuntimeError(completed.stderr or completed.stdout)
    loaded = [line for line in completed.stdout.splitlines() if line.strip()]
    violations = [
        path for path in loaded if any(fragment in path for fragment in forbidden)
    ]
    if violations:
        raise RuntimeError(f"forbidden eager loads: {violations}")
    return loaded


def build_receipt() -> dict[str, Any]:
    rows = read_rows()
    source_by_id = {row["record_id"]: row for row in rows}
    completed = [
        row for row in rows if row.get("completion_status", "").startswith("completed")
    ]
    completed_routes = route_rows(completed)
    enacted = enact_routes(completed_routes)
    route_by_id = {route["id"]: route for route in completed_routes}
    completed_receipts = [
        receipt_row(row, route_by_id[row["record_id"]], enacted) for row in completed
    ]
    completed_categories = Counter(
        row["census_category"] for row in completed_receipts
    )
    abstain_reasons = Counter(
        row["failure_reason"]["reason"]
        for row in completed_receipts
        if "failure_reason" in row
    )

    nonempty_program = [row for row in rows if row.get("program")]
    negative_routes = route_rows(nonempty_program)
    negative_statuses = Counter(
        "routed" if route["status"] == "routed" else route["reason"]
        for route in negative_routes
    )

    load_audit = subprocess.run(
        [
            "swipl",
            "--on-error=status",
            "--on-warning=status",
            "-q",
            "-l",
            "paths.pl",
            "-s",
            "knowledge/strategies/abstraction/standards_router_pilot.pl",
            "-g",
            "standards_router_pilot:check_standards_router_pilot",
            "-t",
            "halt",
        ],
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=False,
    )
    if load_audit.returncode != 0:
        raise RuntimeError(load_audit.stderr or load_audit.stdout)

    router_loaded_paths = run_load_audit(
        [
            "swipl",
            "--on-error=status",
            "--on-warning=status",
            "-q",
            "-l",
            "paths.pl",
            "-s",
            "knowledge/strategies/abstraction/standards_router_pilot.pl",
            "-g",
            "forall(source_file(F),writeln(F)),halt",
        ],
        ("/knowledge/standards/indiana/",),
    )
    worker_loaded_paths = run_load_audit(
        [
            "swipl",
            "--on-error=status",
            "--on-warning=status",
            "-q",
            "-l",
            "hermes_worker.pl",
            "-g",
            "load_runtime,forall(source_file(F),writeln(F)),halt",
        ],
        ("/knowledge/geometry/geometry_bridge.pl", "/formal/learner/server"),
    )

    return {
        "schema": "standards_bridge_slices34_v1",
        "sources": {
            str(SOURCE.relative_to(ROOT)): sha256(SOURCE),
            "knowledge/standards/standard_doing.pl": sha256(
                ROOT / "knowledge/standards/standard_doing.pl"
            ),
            "knowledge/strategies/abstraction/standards_router_pilot.pl": sha256(
                ROOT / "knowledge/strategies/abstraction/standards_router_pilot.pl"
            ),
            "scripts/language/standards_router_runner.pl": sha256(ROUTER),
            "scripts/language/check_standards_bridge.py": sha256(Path(__file__)),
        },
        "routing_boundary": {
            "source_files_loaded": len(router_loaded_paths),
            "indiana_standard_modules_loaded": 0,
        },
        "execution_path": {
            "operation": "strategy_trace",
            "entrypoint": "swipl -q -l hermes_worker.pl -g worker_main",
            "input_boundary": "JSON object with string-valued genre discriminator",
            "eager_server_modules": False,
            "geometry_bridge_loaded": False,
            "source_files_loaded": len(worker_loaded_paths),
        },
        "focused_router_check": load_audit.stdout.strip(),
        "worked_examples": worked_example_receipt(source_by_id),
        "completed_census": {
            "denominator": len(completed),
            "completion_statuses": dict(
                sorted(Counter(row["completion_status"] for row in completed).items())
            ),
            "categories": dict(sorted(completed_categories.items())),
            "failure_reasons": dict(sorted(abstain_reasons.items())),
            "routed_to_worker": len(enacted),
            "three_way_agreement": sum(
                1
                for row in completed_receipts
                if row.get("comparison", {}).get("three_way_agreement")
            ),
            "rows": completed_receipts,
        },
        "negative_receipt": {
            "denominator": len(nonempty_program),
            "statuses": dict(sorted(negative_statuses.items())),
        },
    }


def main() -> int:
    args = parse_args()
    receipt = build_receipt()
    rendered = json.dumps(receipt, indent=2, sort_keys=True) + "\n"
    if args.check:
        if not OUTPUT.exists():
            print(f"missing: {OUTPUT.relative_to(ROOT)}", file=sys.stderr)
            return 1
        if OUTPUT.read_text(encoding="utf-8") != rendered:
            print(f"stale: {OUTPUT.relative_to(ROOT)}", file=sys.stderr)
            return 1
        print(
            json.dumps(
                {
                    "fresh": True,
                    "completed": receipt["completed_census"]["denominator"],
                    "categories": receipt["completed_census"]["categories"],
                    "three_way_agreement": receipt["completed_census"][
                        "three_way_agreement"
                    ],
                    "negative": receipt["negative_receipt"]["denominator"],
                },
                sort_keys=True,
            )
        )
        return 0
    OUTPUT.write_text(rendered, encoding="utf-8")
    print(f"wrote {OUTPUT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
