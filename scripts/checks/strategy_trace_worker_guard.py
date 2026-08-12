#!/usr/bin/env python3
"""Check strategy_trace magnitude refusals through an isolated JSONL worker."""
from __future__ import annotations

import json
import os
import select
import subprocess
import time
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
REPLY_BOUND_SECONDS = 1.0
EXPECTED_MAGNITUDE_BOUND = 5000

BIG_REQUESTS = (
    {
        "id": "big_subtraction",
        "op": "strategy_trace",
        "strategy": "borrow_across_zero_cascade",
        "input": {"a": 920000, "b": 142571},
    },
    {
        "id": "big_multiplication",
        "op": "strategy_trace",
        "strategy": "multiplication_fact_retrieval",
        "input": {"a": 423450, "b": 275},
    },
    {
        "id": "big_division",
        "op": "strategy_trace",
        "strategy": "long_division",
        "input": {"a": 920000, "b": 8},
    },
)

NORMAL_REQUEST = {
    "id": "normal_addition",
    "op": "strategy_trace",
    "strategy": "count_on_from_larger",
    "input": {"a": 7, "b": 1},
}


def worker_command() -> list[str]:
    goal = (
        "catch(with_output_to(user_error, load_runtime), E, worker_fatal(E)), "
        "set_prolog_flag(on_warning, print), "
        "set_prolog_flag(on_error, print), worker_loop"
    )
    return [
        "swipl",
        "--on-error=halt",
        "--on-warning=halt",
        "-q",
        "-s",
        str(ROOT / "hermes_worker.pl"),
        "-g",
        goal,
    ]


def read_reply(process: subprocess.Popen[str], timeout: float) -> dict[str, Any]:
    assert process.stdout is not None
    ready, _, _ = select.select([process.stdout], [], [], timeout)
    if not ready:
        raise AssertionError(f"isolated worker did not reply within {timeout:.1f}s")
    line = process.stdout.readline()
    if not line:
        raise AssertionError(f"isolated worker closed stdout with status {process.poll()}")
    return json.loads(line)


def send(process: subprocess.Popen[str], request: dict[str, Any]) -> tuple[dict[str, Any], float]:
    assert process.stdin is not None
    started = time.monotonic()
    process.stdin.write(json.dumps(request, separators=(",", ":")) + "\n")
    process.stdin.flush()
    reply = read_reply(process, REPLY_BOUND_SECONDS)
    return reply, time.monotonic() - started


def stop_worker(process: subprocess.Popen[str]) -> None:
    if process.poll() is not None:
        return
    process.terminate()
    try:
        process.wait(timeout=2.0)
    except subprocess.TimeoutExpired:
        process.kill()
        process.wait(timeout=2.0)


def main() -> int:
    env = os.environ.copy()
    env["UMEDCTA_ROOT"] = str(ROOT)
    process = subprocess.Popen(
        worker_command(),
        cwd=ROOT,
        env=env,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        encoding="utf-8",
        bufsize=1,
    )
    try:
        assert process.stdin is not None
        process.stdin.write('{"id":"__boot__","op":"health"}\n')
        process.stdin.flush()
        boot = read_reply(process, 120.0)
        if boot.get("id") != "__boot__" or boot.get("ok") is not True:
            raise AssertionError(f"invalid isolated-worker boot reply: {boot!r}")

        timings: list[float] = []
        for request in BIG_REQUESTS:
            reply, elapsed = send(process, request)
            timings.append(elapsed)
            result = reply.get("result")
            if reply.get("ok") is not True or not isinstance(result, dict):
                raise AssertionError(f"{request['id']} lacked a structured result: {reply!r}")
            refusal = result.get("refusal")
            expected = {
                "kind": "grounded_arithmetic_magnitude_bound",
                "bound": EXPECTED_MAGNITUDE_BOUND,
            }
            if result.get("ok") is not False or not isinstance(refusal, dict):
                raise AssertionError(f"{request['id']} was not a structured refusal: {reply!r}")
            for key, value in expected.items():
                if refusal.get(key) != value:
                    raise AssertionError(
                        f"{request['id']} refusal {key}={refusal.get(key)!r}; expected {value!r}"
                    )
            if str(EXPECTED_MAGNITUDE_BOUND) not in str(result.get("note", "")):
                raise AssertionError(f"{request['id']} note did not name the bound: {result!r}")

        normal, normal_elapsed = send(process, NORMAL_REQUEST)
        normal_result = normal.get("result")
        if not (
            normal.get("ok") is True
            and isinstance(normal_result, dict)
            and normal_result.get("ok") is True
            and normal_result.get("validity") == "correct"
            and normal_result.get("result") == "8"
        ):
            raise AssertionError(f"normal strategy trace changed: {normal!r}")

        if process.poll() is not None:
            raise AssertionError("isolated worker exited after the guarded requests")
        print(
            "PASS isolated strategy_trace worker guard: "
            f"3 refusals <= {REPLY_BOUND_SECONDS:.1f}s "
            f"(max {max(timings):.4f}s); normal trace {normal_elapsed:.4f}s"
        )
        return 0
    finally:
        stop_worker(process)


if __name__ == "__main__":
    raise SystemExit(main())
