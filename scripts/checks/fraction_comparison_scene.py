#!/usr/bin/env python3
"""Exercise every fraction and decimal comparison through the JSONL worker."""
from __future__ import annotations

import copy
import json
import os
import select
import subprocess
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
LEGAL_RESULTS = {"less_than", "equivalent", "greater_than"}
DRAWER_FORMATS = {
    "fraction-bars", "number-line", "area-model", "base-ten-columns",
    "place-value-chart", "set-grouping", "balance-scale",
    "hybridization-model", "notation", "coordinate-plane", "rigid-motion",
    "polyform-tiling", "angle-circular", "data-display", "solid-net",
    "geoboard",
}
CASES = (
    ("number_line_fraction_comparison", (1, 3, 2, 5), "number-line", True, True),
    ("area_model_fraction_comparison", (1, 3, 2, 5), "area-model", True, True),
    ("set_model_fraction_comparison", (1, 3, 2, 5), "set-grouping", True, True),
    ("benchmark_fraction_comparison", (1, 3, 2, 5), "fraction-bars", True, True),
    ("common_unit_fraction_comparison", (1, 3, 2, 5), "fraction-bars", True, True),
    ("decimal_fraction_place_value_comparison", (9, 10, 10, 100), "number-line", True, True),
    ("positional_decimal_reading", (37, 100, 0, 1), "number-line", True, False),
    ("decimal_comparison_by_aligned_units", (9, 10, 10, 100), "number-line", True, False),
    ("decimal_addition_by_aligned_units", (12, 10, 3, 100), "number-line", True, False),
    ("decimal_subtraction_by_aligned_units", (12, 10, 3, 100), "number-line", True, False),
    ("decimal_place_unit_regrouping", (3, 10, 100, 0), "number-line", True, False),
    ("decimal_multiplication_rule", (12, 10, 3, 10), "number-line", True, False),
)


def worker_command() -> list[str]:
    goal = (
        "catch(with_output_to(user_error, load_runtime), E, worker_fatal(E)), "
        "set_prolog_flag(on_warning, print), "
        "set_prolog_flag(on_error, print), worker_loop"
    )
    return [
        "swipl", "--on-error=halt", "--on-warning=halt", "-q",
        "-s", str(ROOT / "hermes_worker.pl"), "-g", goal,
    ]


def read_reply(process: subprocess.Popen[str], timeout: float) -> dict[str, Any]:
    assert process.stdout is not None
    ready, _, _ = select.select([process.stdout], [], [], timeout)
    if not ready:
        raise AssertionError(f"worker did not reply within {timeout:.1f}s")
    line = process.stdout.readline()
    if not line:
        stderr = process.stderr.read() if process.stderr is not None else ""
        raise AssertionError(
            f"worker closed stdout with status {process.poll()}: {stderr[-2000:]}"
        )
    return json.loads(line)


def send(process: subprocess.Popen[str], request: dict[str, Any]) -> dict[str, Any]:
    assert process.stdin is not None
    process.stdin.write(json.dumps(request, separators=(",", ":")) + "\n")
    process.stdin.flush()
    return read_reply(process, 30.0)


def stop_worker(process: subprocess.Popen[str]) -> None:
    if process.poll() is not None:
        return
    process.terminate()
    try:
        process.wait(timeout=2.0)
    except subprocess.TimeoutExpired:
        process.kill()
        process.wait(timeout=2.0)


def assert_drawn(
    doc: dict[str, Any], expected_format: str, needs_viability: bool,
    comparison_result: bool = True,
) -> None:
    if doc.get("error"):
        productive = doc.get("productive", {}).get("frames", [])
        deformation = doc.get("deformation", {}).get("frames", [])
        if productive or deformation:
            raise AssertionError("an explicit-error document must have empty frame lists")
        raise AssertionError(f"family was left undrawn: {doc['error']}")

    for side_name in ("productive", "deformation"):
        side = doc.get(side_name)
        if not isinstance(side, dict):
            raise AssertionError(f"missing {side_name} side")
        frames = side.get("frames")
        if not isinstance(frames, list) or not frames:
            raise AssertionError(f"{side_name} frames are empty")
        if comparison_result and side.get("result") not in LEGAL_RESULTS:
            raise AssertionError(f"{side_name} result is not a legal comparison atom")
        if not comparison_result and (side.get("result") is None or side.get("result") == ""):
            raise AssertionError(f"{side_name} result is empty")
        trace = side.get("trace")
        if not isinstance(trace, list) or not trace:
            raise AssertionError(f"{side_name} trace is empty")
        for frame in frames:
            scene = frame.get("scene") if isinstance(frame, dict) else None
            scene_format = scene.get("format") if isinstance(scene, dict) else None
            if scene_format not in DRAWER_FORMATS:
                raise AssertionError(f"unknown drawer format: {scene_format!r}")
            if scene_format != expected_format:
                raise AssertionError(
                    f"expected {expected_format!r}, received {scene_format!r}"
                )

    if needs_viability:
        viability = doc.get("viability")
        if not isinstance(viability, dict):
            raise AssertionError("arity-7 deformation lacks a viability record")
        if viability.get("status") not in {"contextual_success", "fails_in_context"}:
            raise AssertionError(f"invalid viability status: {viability!r}")
        if not viability.get("condition"):
            raise AssertionError("viability record lacks its condition")
        inputs = viability.get("inputs")
        if not isinstance(inputs, dict) or set(inputs) != {"n1", "d1", "n2", "d2"}:
            raise AssertionError("viability record does not name all four inputs")


def assert_mutation_guards(doc: dict[str, Any], expected_format: str) -> None:
    empty = copy.deepcopy(doc)
    empty["productive"]["frames"] = []
    try:
        assert_drawn(empty, expected_format, False)
    except AssertionError:
        pass
    else:
        raise AssertionError("empty-frame mutation escaped the check")

    unknown = copy.deepcopy(doc)
    unknown["deformation"]["frames"][0]["scene"]["format"] = "unknown-format"
    try:
        assert_drawn(unknown, expected_format, False)
    except AssertionError:
        pass
    else:
        raise AssertionError("unknown-format mutation escaped the check")


def assert_worker_error(reply: dict[str, Any], expected_type: str) -> None:
    actual = reply.get("error", {}).get("type")
    if reply.get("ok") is not False or actual != expected_type:
        raise AssertionError(f"expected {expected_type}, received {reply!r}")


def assert_scene_determinism() -> None:
    goal = (
        "use_module(strategies(render/fraction_comparison_scene)), "
        "aggregate_all(count, "
        "fraction_comparison_scene:fraction_comparison_compare_json("
        "compare_spec(number_line_fraction_comparison,1,3,2,5),_), FC), "
        "aggregate_all(count, "
        "fraction_comparison_scene:fraction_comparison_compare_json("
        "compare_spec(decimal_comparison_by_aligned_units,9,10,10,100),_), DC), "
        "format('~w ~w~n',[FC,DC]), halt"
    )
    completed = subprocess.run(
        ["swipl", "-q", "-l", str(ROOT / "paths.pl"), "-g", goal],
        cwd=ROOT, capture_output=True, text=True, check=False,
    )
    if completed.returncode != 0:
        raise AssertionError(f"determinism probe failed: {completed.stderr[-2000:]}")
    counts = completed.stdout.strip().split()
    if counts != ["1", "1"]:
        raise AssertionError(
            f"fraction comparison is nondeterministic: expected 1 1, received {counts!r}"
        )


def main() -> int:
    assert_scene_determinism()
    page = (ROOT / "hermes/web/fraction-comparison/compare.html").read_text(
        encoding="utf-8"
    )
    if 'data-input-field="d2"' not in page or "d2Input.disabled = d2Unused" not in page:
        raise AssertionError("unused decimal input is not hidden and disabled")
    if "[data-input-field][hidden] { display: none; }" not in page:
        raise AssertionError("flex layout overrides the hidden decimal input")
    compare_host = (ROOT / "hermes/web/render/compare.js").read_text(encoding="utf-8")
    if "node.disabled || node.closest('[hidden]')" not in compare_host:
        raise AssertionError("hidden comparison inputs can still enter the POST payload")
    for field in ("divergenceNote", "viabilityNote"):
        if f'id="{field}"' not in page:
            raise AssertionError(f"researcher panel does not surface {field}")

    env = os.environ.copy()
    env["UMEDCTA_ROOT"] = str(ROOT)
    process = subprocess.Popen(
        worker_command(), cwd=ROOT, env=env,
        stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        text=True, encoding="utf-8", bufsize=1,
    )
    try:
        boot = send(process, {"id": "__boot__", "op": "health"})
        if boot.get("ok") is not True:
            raise AssertionError(f"worker boot failed: {boot!r}")

        first_doc: dict[str, Any] | None = None
        for family, values, expected_format, needs_viability, comparison_result in CASES:
            n1, d1, n2, d2 = values
            payload = {
                "id": family, "op": "fraction_comparison_compare",
                "family": family, "n1": n1, "d1": d1, "n2": n2, "d2": d2,
            }
            if family in {"positional_decimal_reading", "decimal_place_unit_regrouping"}:
                del payload["d2"]
            reply = send(process, payload)
            doc = reply.get("result")
            if reply.get("ok") is not True or not isinstance(doc, dict):
                raise AssertionError(f"{family} lacked a result document: {reply!r}")
            assert_drawn(doc, expected_format, needs_viability, comparison_result)
            note = doc.get("note")
            if not isinstance(note, str) or "_" in note or not note.endswith("."):
                raise AssertionError(f"{family} lacks an authored sentence note: {note!r}")
            if first_doc is None:
                first_doc = doc

        assert first_doc is not None
        assert_mutation_guards(first_doc, "number-line")
        assert_worker_error(send(process, {
            "id": "unknown", "op": "fraction_comparison_compare",
            "family": "unknown_family", "n1": 1, "d1": 2, "n2": 1, "d2": 3,
        }), "unknown_family")
        assert_worker_error(send(process, {
            "id": "malformed", "op": "fraction_comparison_compare",
            "family": "number_line_fraction_comparison", "n1": 1,
            "d1": 2, "n2": 1,
        }), "malformed_inputs")

        print(
            f"PASS fraction comparison scene: {len(CASES)} worker-path families drawn; "
            "fraction/decimal determinism, results, traces, formats, viability, "
            "errors, and mutation guards checked"
        )
        return 0
    finally:
        stop_worker(process)


if __name__ == "__main__":
    raise SystemExit(main())
