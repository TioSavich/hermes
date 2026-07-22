#!/usr/bin/env python3
"""Offline render adapter for pass-1 material representation mentions.

This is deliberately a small projection onto the same Node drawer seam used by
the deformation-gallery exporters. It accepts only the five pass-1 kinds and
returns an explicit abstention instead of substituting a nearby picture.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[2]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))
from hermes.app import rendering

DRAWABLE_KINDS = frozenset({
    "tape_diagram", "number_line", "area_circle", "area_rectangle",
    "equation_chain",
})


def _positive_int(value: Any) -> int | None:
    return value if isinstance(value, int) and not isinstance(value, bool) and value > 1 else None


def _fraction(value: Any) -> tuple[int, int] | None:
    if not isinstance(value, dict):
        return None
    num, den = value.get("num"), value.get("den")
    if (isinstance(num, int) and isinstance(den, int) and not isinstance(num, bool)
            and not isinstance(den, bool) and num == 1 and den > 1):
        return num, den
    return None


def _frame(scene: dict[str, Any], caption: str) -> dict[str, Any]:
    return {"step": 1, "verb": "recorded_representation", "caption": caption,
            "sceneChanged": True, "scene": scene}


def compile_mention(mention: dict[str, Any], claims: list[dict[str, Any]] | None = None
                    ) -> dict[str, Any]:
    """Compile one mention or return an honest abstention record.

    Claims are joined by utterance as provenance, but no values are borrowed:
    the material mention itself must state the drawable numbers.
    """
    claim_ids = [str(item.get("id")) for item in claims or []
                 if str(item.get("utterance_id", "")).lower()
                 == str(mention.get("utterance_id", "")).lower()
                 and item.get("verdict") in {"holds", "refuted", "underdetermined"}]
    kind = str(mention.get("representation_kind", mention.get("kind", "")))
    surface = str(mention.get("surface", "")).strip()
    if kind not in DRAWABLE_KINDS:
        return {"status": "undrawable", "reason": "unsupported_kind", "surface": surface,
                "adjudicated_claim_ids": claim_ids}
    if not surface:
        return {"status": "undrawable", "reason": "missing_surface", "surface": surface,
                "adjudicated_claim_ids": claim_ids}
    parts = _positive_int(mention.get("partition_count"))
    unit = _fraction(mention.get("unit_fraction"))
    if kind != "equation_chain" and parts is None:
        return {"status": "undrawable", "reason": "missing_partition_count", "surface": surface,
                "adjudicated_claim_ids": claim_ids}
    if unit is not None and parts is not None and unit[1] != parts:
        return {"status": "undrawable", "reason": "unit_fraction_partition_mismatch", "surface": surface,
                "adjudicated_claim_ids": claim_ids}
    label = f"{kind.replace('_', ' ')}: {surface}"
    shade = [1] if unit else []
    if kind == "tape_diagram":
        splits = [{"x": i * 720 / parts, "y": 0, "w": 720 / parts, "h": 90,
                   "role": "highlight"} for i in shade]
        scene = {"format": "fraction-bars", "version": 2,
                 "bars": [{"x": 40, "y": 70, "w": 720, "h": 90,
                           "label": f"1/{parts}" if unit else "", "splits": splits}]}
    elif kind == "number_line":
        ticks = [i / parts for i in range(parts + 1)]
        scene = {"format": "number-line", "version": 2,
                 "axis": {"min": 0, "max": 1, "ticks": ticks},
                 "marks": ([{"at": 1 / parts, "label": f"1/{parts}", "role": "point"}]
                           if unit else [])}
    elif kind == "area_circle":
        scene = {"format": "hybridization-model", "version": 2,
                 "primitives": [
                     {"kind": "host-circle", "cx": 180, "cy": 150, "r": 100,
                      "label": "circle", "role": "whole"},
                     {"kind": "radial-partition", "host": "circle", "cx": 180,
                      "cy": 150, "r": 100, "segments": parts, "shade": shade,
                      "label": f"1/{parts}" if unit else "", "role": "iterated"},
                 ]}
    elif kind == "area_rectangle":
        scene = {"format": "hybridization-model", "version": 2,
                 "primitives": [
                     {"kind": "host-rect", "x": 40, "y": 70, "w": 360, "h": 160,
                      "label": "rectangle", "role": "whole"},
                     {"kind": "vertical-partition", "host": "rectangle", "x": 40,
                      "y": 70, "w": 360, "h": 160, "columns": parts, "shade": shade,
                      "label": f"1/{parts}" if unit else "", "role": "iterated"},
                 ]}
    else:
        chars = list(surface)
        if len(chars) > 48:
            return {"status": "undrawable", "reason": "equation_chain_too_long", "surface": surface,
                    "adjudicated_claim_ids": claim_ids}
        if not re.search(r"[=+\-*/]", surface):
            return {"status": "undrawable", "reason": "no_equation_notation", "surface": surface,
                    "adjudicated_claim_ids": claim_ids}
        scene = {"format": "notation", "version": 2,
                 "glyphs": [{"ch": char, "x": 36 + index * 24, "y": 50,
                             "size": 20, "flip": "none", "ghost": "none"}
                            for index, char in enumerate(chars)], "marks": []}
    return {"status": "drawable", "document": {"frames": [_frame(scene, label)]},
            "label": label, "surface": surface, "adjudicated_claim_ids": claim_ids}


def render_mentions(extractions: list[dict[str, Any]], out_dir: Path) -> list[dict[str, Any]]:
    """Attach render receipts and SVG filenames to representation extractions."""
    claims = [item for item in extractions if item.get("kind", "claim") == "claim"]
    pictures = out_dir / "representations"
    receipts = []
    for mention in (item for item in extractions if item.get("kind") == "representation"):
        compiled = compile_mention(mention, claims)
        receipt = {key: value for key, value in compiled.items() if key != "document"}
        if compiled["status"] == "drawable":
            name = f"{mention.get('utterance_id', 'u')}_{mention.get('id', 'r')}.svg"
            target = pictures / name
            rendering.render_svg(compiled["document"], "frame", target,
                                 ariaLabel=compiled["label"])
            receipt["svg"] = str(Path("representations") / name)
        mention["render"] = receipt
        receipts.append({"id": mention.get("id"), **receipt})
    return receipts


def _self_test() -> None:
    cases = [
        ({"kind": "tape_diagram", "surface": "a tape split into fourths", "partition_count": 4,
          "unit_fraction": {"num": 1, "den": 4}}, "drawable"),
        ({"kind": "number_line", "surface": "a number line in thirds", "partition_count": 3,
          "unit_fraction": {"num": 1, "den": 3}}, "drawable"),
        ({"kind": "area_circle", "surface": "pizza in sixths", "partition_count": 6,
          "unit_fraction": {"num": 1, "den": 6}}, "drawable"),
        ({"kind": "area_rectangle", "surface": "rectangle in fifths", "partition_count": 5,
          "unit_fraction": None}, "drawable"),
        ({"kind": "equation_chain", "surface": "3 + 4 = 7", "partition_count": None,
          "unit_fraction": None}, "drawable"),
        ({"kind": "number_line", "surface": "a number line", "partition_count": None,
          "unit_fraction": None}, "undrawable"),
        ({"kind": "area_circle", "surface": "circle in thirds", "partition_count": 3,
          "unit_fraction": {"num": 1, "den": 4}}, "undrawable"),
    ]
    for fixture, expected in cases:
        actual = compile_mention(fixture)["status"]
        assert actual == expected, (fixture, actual, expected)


if __name__ == "__main__":
    _self_test()
    print("representation_render self-test: ok")
