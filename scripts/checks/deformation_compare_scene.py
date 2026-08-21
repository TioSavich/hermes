#!/usr/bin/env python3
"""Exercise every orphan deformation emitter through its worker operation."""
from __future__ import annotations

import copy
import json
import os
import select
import subprocess
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
DRAWER_FORMATS = {
    "coordinate-plane", "rigid-motion", "polyform-tiling", "angle-circular",
    "data-display", "solid-net", "geoboard",
}
CASES: tuple[tuple[str, dict[str, Any], str], ...] = (
    ("quadrant_sign_error", {"x": -3, "y": 2}, "coordinate-plane"),
    ("reflection_by_rotation", {"vertices": "[[0,0],[4,0],[4,1],[2,1],[2,3],[0,3]]"}, "rigid-motion"),
    ("flip_needed", {"piece": "l"}, "polyform-tiling"),
    ("unfillable_by_parity", {"cols": 5, "rows": 5}, "polyform-tiling"),
    ("angle_confused_with_ray_length", {"degrees": 60, "short_length": 120, "long_length": 240}, "angle-circular"),
    ("bar_histogram_conflation", {"pairs": '[{"category":"red","count":4},{"category":"blue","count":6}]'}, "data-display"),
    ("net_fold_failure", {"solid": "cube"}, "solid-net"),
    ("boundary_peg_as_interior", {"vertices": "[[0,0],[4,0],[4,3],[0,3]]"}, "geoboard"),
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


def read_reply(process: subprocess.Popen[str], timeout: float = 30.0) -> dict[str, Any]:
    assert process.stdout is not None
    ready, _, _ = select.select([process.stdout], [], [], timeout)
    if not ready:
        raise AssertionError(f"worker did not reply within {timeout:.1f}s")
    line = process.stdout.readline()
    if not line:
        stderr = process.stderr.read() if process.stderr is not None else ""
        raise AssertionError(f"worker closed stdout: {stderr[-2000:]}")
    return json.loads(line)


def send(process: subprocess.Popen[str], request: dict[str, Any]) -> dict[str, Any]:
    assert process.stdin is not None
    process.stdin.write(json.dumps(request, separators=(",", ":")) + "\n")
    process.stdin.flush()
    return read_reply(process)


def assert_drawn(doc: dict[str, Any], expected_format: str) -> None:
    if doc.get("error"):
        raise AssertionError(f"emitter returned an explicit error: {doc['error']}")
    for side_name in ("productive", "deformation"):
        frames = doc.get(side_name, {}).get("frames")
        if not isinstance(frames, list) or not frames:
            raise AssertionError(f"{side_name} frames are empty")
        for frame in frames:
            if not isinstance(frame, dict) or not frame.get("caption"):
                raise AssertionError(f"{side_name} frame lacks a caption")
            if "(s)" in frame["caption"]:
                raise AssertionError(f"{side_name} frame uses a programmer plural")
            scene = frame.get("scene")
            scene_format = scene.get("format") if isinstance(scene, dict) else None
            if scene_format not in DRAWER_FORMATS:
                raise AssertionError(f"unknown drawer format: {scene_format!r}")
            if scene_format != expected_format:
                raise AssertionError(
                    f"expected {expected_format!r}, received {scene_format!r}"
                )


def assert_mutation_guards(doc: dict[str, Any], expected_format: str) -> None:
    empty = copy.deepcopy(doc)
    empty["productive"]["frames"] = []
    try:
        assert_drawn(empty, expected_format)
    except AssertionError:
        pass
    else:
        raise AssertionError("empty-frame mutation escaped the check")
    unknown = copy.deepcopy(doc)
    unknown["deformation"]["frames"][0]["scene"]["format"] = "unknown-format"
    try:
        assert_drawn(unknown, expected_format)
    except AssertionError:
        pass
    else:
        raise AssertionError("unknown-format mutation escaped the check")


def assert_worker_error(reply: dict[str, Any], expected_type: str) -> None:
    actual = reply.get("error", {}).get("type")
    if reply.get("ok") is not False or actual != expected_type:
        raise AssertionError(f"expected {expected_type}, received {reply!r}")


def assert_named_boundary(reply: dict[str, Any], phrase: str) -> dict[str, Any]:
    doc = reply.get("result")
    if reply.get("ok") is not True or not isinstance(doc, dict):
        raise AssertionError(f"named boundary was rejected by the worker: {reply!r}")
    if phrase not in str(doc.get("error", "")):
        raise AssertionError(f"named boundary sentence is missing: {doc!r}")
    if doc.get("productive", {}).get("frames") or doc.get("deformation", {}).get("frames"):
        raise AssertionError("named boundary must not carry drawable frames")
    return doc


def main() -> int:
    compare_host = (ROOT / "hermes/web/render/compare.js").read_text(encoding="utf-8")
    for required in (
        "DRAW.documentBounds(prod.concat(def), doc.canvas)",
        "This side has finished.",
        "setBoundary(doc.error)",
        "plainName(doc.productiveKind)",
    ):
        if required not in compare_host:
            raise AssertionError(f"shared compare host lacks regression guard: {required}")
    if "showStageError('prodStage', doc.error)" in compare_host:
        raise AssertionError("named boundaries still use the duplicated error treatment")
    for required in ("state.steps = 0", "prev0.disabled = true", "next0.disabled = true"):
        if required not in compare_host:
            raise AssertionError(f"boundary navigation is not reset: {required}")

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
        for family, inputs, expected_format in CASES:
            reply = send(process, {
                "id": family, "op": "deformation_compare", "family": family,
                **inputs,
            })
            doc = reply.get("result")
            if reply.get("ok") is not True or not isinstance(doc, dict):
                raise AssertionError(f"{family} lacked a result document: {reply!r}")
            assert_drawn(doc, expected_format)
            if family == "net_fold_failure":
                if doc.get("productiveKind") != "cube_net":
                    raise AssertionError("solid-net productive kind is not a complete phrase")
                note = str(doc.get("note", ""))
                if "two_by_three_block" in note or "net_faces_do_not_fold_to_solid" in note:
                    raise AssertionError("solid-net teacher note leaks identifiers")
            if first_doc is None:
                first_doc = doc
        assert first_doc is not None
        assert_mutation_guards(first_doc, "coordinate-plane")
        angle_boundary = assert_named_boundary(send(process, {
            "id": "angle-boundary", "op": "deformation_compare",
            "family": "angle_confused_with_ray_length", "degrees": 60,
            "short_length": 120, "long_length": 120,
        }), "longer draw length")
        if ".." in angle_boundary["error"] or " deg)" in angle_boundary["error"]:
            raise AssertionError("angle boundary still uses programmer range notation")
        assert_named_boundary(send(process, {
            "id": "bar-boundary", "op": "deformation_compare",
            "family": "bar_histogram_conflation",
            "pairs": '[{"category":"red","count":4}]',
        }), "at least two categorical bars")
        parity_singular = send(process, {
            "id": "parity-singular", "op": "deformation_compare",
            "family": "unfillable_by_parity", "cols": 2, "rows": 2,
        }).get("result", {})
        singular_caption = parity_singular.get("deformation", {}).get("frames", [])[-1]["caption"]
        if "1 cell remains" not in singular_caption:
            raise AssertionError(f"singular parity agreement regressed: {singular_caption!r}")
        assert_worker_error(send(process, {
            "id": "unknown", "op": "deformation_compare", "family": "unknown",
        }), "unknown_family")
        assert_worker_error(send(process, {
            "id": "malformed", "op": "deformation_compare",
            "family": "quadrant_sign_error", "x": -3,
        }), "malformed_inputs")
        catalog_reply = send(process, {
            "id": "catalog", "op": "deformation_visualizer_catalog",
        })
        catalog = catalog_reply.get("result")
        if catalog_reply.get("ok") is not True or not isinstance(catalog, dict):
            raise AssertionError(f"visualizer catalog failed: {catalog_reply!r}")
        representation_families = {
            row.get("family") for row in catalog.get("representationComparisons", [])
        }
        if representation_families != {family for family, _, _ in CASES}:
            raise AssertionError("visualizer catalog does not list every representation family")
        expected_galleries = {
            "misconception_demos", "real_transplants",
            "parametric_fraction_errors", "parametric_deformations",
            "fraction_cliff_demos", "best_IM_scenes", "fractal_loops",
        }
        galleries = catalog.get("galleries", [])
        if {row.get("gallery") for row in galleries} != expected_galleries:
            raise AssertionError("visualizer catalog does not list every gallery")
        if any(not isinstance(row.get("fileCount"), int) or row["fileCount"] < 1
               for row in galleries):
            raise AssertionError("visualizer catalog has an empty gallery")
        print(
            f"PASS deformation compare scene: {len(CASES)} worker-path lanes drawn; "
            "page-shaped JSON strings, named boundaries, captions, formats, "
            "catalog, and mutation guards checked"
        )
        return 0
    finally:
        if process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=2.0)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait(timeout=2.0)


if __name__ == "__main__":
    raise SystemExit(main())
