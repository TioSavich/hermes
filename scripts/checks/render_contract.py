#!/usr/bin/env python3
"""Executable checks for the render contract and /api/render scalar rejection."""
from __future__ import annotations

import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO))

from hermes.app.rendering import RenderDocumentError, validate_render_document
from hermes.app.routes.logic import RouteLogic


def scene(step: int = 1) -> dict:
    return {
        "step": step,
        "verb": "establish_whole",
        "scene": {"format": "fraction-bars", "version": 2, "bars": []},
    }


def test_render_contract_v2() -> None:
    documents = (
        {"kind": "productive", "request": {}, "result": {}, "frames": [scene()]},
        {
            "kind": "comparison",
            "request": {},
            "result": {},
            "frames": [scene()],
            "productive": {"frames": [scene()]},
            "deformation": {"frames": [scene()]},
        },
        {"kind": "refusal", "error": "no licensed scene", "frames": []},
        # An error document may carry an annotation-only frame instead of an
        # empty array — the area_compare sourcing-failure fallback never
        # fakes a picture, but it still draws one frame naming the refusal.
        {"kind": "refusal", "error": "no licensed scene", "frames": [scene()]},
        {"kind": "empty", "request": {}, "result": {}, "frames": []},
    )
    for document in documents:
        assert validate_render_document(document) is document
    for value in (17, "scene", None, [], {"result": 17}):
        try:
            validate_render_document(value)
        except RenderDocumentError:
            pass
        else:
            raise AssertionError(f"accepted non-render value: {value!r}")

    # A part validates whenever it is present, even alongside valid top-level
    # frames: a malformed productive part must not slip through because the
    # document also happens to carry a drawable top-level frames array.
    malformed_part_document = {
        "kind": "comparison",
        "request": {},
        "result": {},
        "frames": [scene()],
        "productive": {"frames": "not-a-list"},
    }
    try:
        validate_render_document(malformed_part_document)
    except RenderDocumentError:
        pass
    else:
        raise AssertionError(
            "accepted a document with valid top-level frames but a malformed "
            "productive part"
        )

    # balance_compare ships productive/deformation as plain role-label
    # strings beside top-level frames; string parts are sibling metadata,
    # never rejected.
    string_label_document = {
        "kind": "comparison",
        "frames": [scene()],
        "productive": "balanced_moves",
        "deformation": "subtract_from_lighter_side",
    }
    validate_render_document(string_label_document)


class Context:
    def __init__(self) -> None:
        self.responses: list[tuple[dict, int]] = []

    def worker_request(self, _op: str, **_kwargs: object) -> int:
        return 17

    def _send_json(self, payload: dict, *, status: int = 200) -> None:
        self.responses.append((payload, status))


def test_render_endpoint_rejects_scalar() -> None:
    context = Context()
    RouteLogic(context)._handle_render({"op": "fraction_render", "kind": "unit_fraction"})
    payload, status = context.responses[-1]
    assert status == 400
    assert payload["ok"] is False
    assert "non-drawable render document" in payload["error"]

    for op in ("set_base", "get_base", "image_schema", "primitive_for_practice"):
        context = Context()
        RouteLogic(context)._handle_render({"op": op})
        payload, status = context.responses[-1]
        assert status == 400
        assert payload["error"] == f"unknown render op: {op}"


if __name__ == "__main__":
    test_render_contract_v2()
    test_render_endpoint_rejects_scalar()
    print("test_render_contract_v2: ok")
    print("test_render_endpoint_rejects_scalar: ok")
