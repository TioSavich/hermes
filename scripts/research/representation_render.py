#!/usr/bin/env python3
"""Offline, claim-bound rendering for pass-1 material representation mentions."""
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
_VERDICTS = frozenset({"holds", "refuted", "underdetermined"})
_WINDOW_ID = re.compile(r"^w(\d+)", re.IGNORECASE)


def _positive_int(value: Any) -> int | None:
    return value if isinstance(value, int) and not isinstance(value, bool) and value > 1 else None


def _fraction(value: Any) -> tuple[int, int] | None:
    if not isinstance(value, dict):
        return None
    num, den = value.get("num"), value.get("den")
    if (isinstance(num, int) and isinstance(den, int) and not isinstance(num, bool)
            and not isinstance(den, bool) and num > 0 and den > 0):
        return num, den
    return None


def _window_id(record: dict[str, Any]) -> str | None:
    match = _WINDOW_ID.match(str(record.get("id", "")))
    return match.group(1) if match else None


def _in_range(mention: dict[str, Any], record: dict[str, Any]) -> str | None:
    if str(mention.get("utterance_id", "")).lower() == str(record.get("utterance_id", "")).lower():
        return "same_utterance"
    mention_window, record_window = _window_id(mention), _window_id(record)
    if mention_window and mention_window == record_window:
        return "same_window"
    return None


def _source(record: dict[str, Any], quantities: dict[str, Any]) -> dict[str, Any]:
    return {"id": str(record.get("id", "")), "kind": str(record.get("kind", "claim")),
            "utterance_id": str(record.get("utterance_id", "")), "quantities": quantities}


def _bound_action(mention: dict[str, Any], records: list[dict[str, Any]],
                  parts: int, unit: tuple[int, int]) -> dict[str, Any] | None:
    """Join a stated partition to an in-range split and iteration action.

    The drawer receives no inferred operand: its whole, counted extent, and
    iteration step each come from one of the retained action records.
    """
    splits, iterations = [], []
    for record in records:
        scope = _in_range(mention, record)
        arguments = record.get("arguments")
        if not scope or not isinstance(arguments, dict):
            continue
        if record.get("kind") == "fraction:splitting":
            split_unit = _fraction(arguments.get("unit_fraction"))
            if (arguments.get("equal_partition") == parts and split_unit == unit
                    and _positive_int(arguments.get("referent_whole"))):
                splits.append((record, scope))
        elif record.get("kind") == "fraction:unit_fraction_iteration":
            step = _fraction(arguments.get("unit_fraction"))
            count = _positive_int(arguments.get("iteration_count"))
            if step and count and step[1] == parts:
                iterations.append((record, scope))
    for split, split_scope in splits:
        whole = int(split["arguments"]["referent_whole"])
        for iteration, iteration_scope in iterations:
            arguments = iteration["arguments"]
            iteration_whole = _positive_int(arguments.get("referent_whole"))
            if iteration_whole is not None and iteration_whole != whole:
                continue
            step = _fraction(arguments["unit_fraction"])
            count = int(arguments["iteration_count"])
            return {
                "scope": "same_utterance" if {split_scope, iteration_scope} == {"same_utterance"}
                else "same_window",
                "partition": {"count": parts, "unit_fraction": {"num": unit[0], "den": unit[1]}},
                "extent": {"whole": whole, "iteration_count": count,
                           "iteration_unit": {"num": step[0], "den": step[1]}},
                "sources": [
                    _source(split, {"referent_whole": whole, "equal_partition": parts,
                                    "unit_fraction": split["arguments"]["unit_fraction"]}),
                    _source(iteration, {"iteration_count": count,
                                        "unit_fraction": arguments["unit_fraction"],
                                        **({"referent_whole": iteration_whole}
                                           if iteration_whole is not None else {})}),
                ],
            }
    return None


def _frame(scene: dict[str, Any], caption: str) -> dict[str, Any]:
    return {"step": 1, "verb": "recorded_representation", "caption": caption,
            "sceneChanged": True, "scene": scene}


def _number_line_scene(binding: dict[str, Any]) -> dict[str, Any]:
    extent = binding["extent"]
    whole, count = extent["whole"], extent["iteration_count"]
    step_num, step_den = extent["iteration_unit"]["num"], extent["iteration_unit"]["den"]
    step = step_num / step_den
    return {"format": "number-line", "version": 2,
            "axis": {"min": 0, "max": whole,
                     "ticks": [index / binding["partition"]["count"]
                               for index in range(whole * binding["partition"]["count"] + 1)]},
            "jumps": [{"from": index * step, "to": (index + 1) * step,
                       "by": step, "label": f"{step_num}/{step_den}", "role": "jump-add"}
                      for index in range(count)],
            "marks": [{"at": 0, "label": "0"}, {"at": whole, "label": str(whole)},
                      {"at": count * step, "label": f"{count} groups", "role": "point"}]}


def _rectangle_scene(binding: dict[str, Any]) -> dict[str, Any]:
    extent, partition = binding["extent"], binding["partition"]
    whole, count, parts = extent["whole"], extent["iteration_count"], partition["count"]
    columns, rows = 3, (whole + 2) // 3
    primitives: list[dict[str, Any]] = []
    for index in range(whole):
        x, y = 40 + (index % columns) * 180, 60 + (index // columns) * 105
        primitives.extend([
            {"kind": "host-rect", "x": x, "y": y, "w": 140, "h": 60,
             "label": f"whole {index + 1}", "role": "whole"},
            {"kind": "vertical-partition", "host": "rectangle", "x": x, "y": y,
             "w": 140, "h": 60, "columns": parts, "shade": list(range(1, parts + 1)),
             "label": f"{count} {'fourths' if parts == 4 else 'fifths'}" if index == 0 else "",
             "role": "iterated"},
        ])
    return {"format": "hybridization-model", "version": 2, "primitives": primitives,
            "layout": {"rows": rows, "columns": columns}}


def compile_mention(mention: dict[str, Any], records: list[dict[str, Any]] | None = None
                    ) -> dict[str, Any]:
    """Compile one mention only when its stated partition binds an act."""
    records = records or []
    claim_ids = [str(item.get("id")) for item in records
                 if item.get("verdict") in _VERDICTS and _in_range(mention, item)]
    kind = str(mention.get("representation_kind", mention.get("kind", "")))
    surface = str(mention.get("surface", "")).strip()
    base = {"surface": surface, "adjudicated_claim_ids": claim_ids}
    if kind not in DRAWABLE_KINDS:
        return {"status": "undrawable", "reason": "unsupported_kind", **base}
    if not surface:
        return {"status": "undrawable", "reason": "missing_surface", **base}
    parts, unit = _positive_int(mention.get("partition_count")), _fraction(mention.get("unit_fraction"))
    if kind == "equation_chain":
        return {"status": "undrawable_unbound", "reason": "no_partitioned_act", **base}
    if parts is None or unit is None or unit != (1, parts):
        return {"status": "undrawable_unbound", "reason": "missing_stated_partition_or_unit", **base}
    binding = _bound_action(mention, records, parts, unit)
    if binding is None:
        return {"status": "undrawable_unbound", "reason": "no_bound_extent_in_range", **base}
    if kind == "number_line":
        scene = _number_line_scene(binding)
    elif kind == "area_rectangle":
        scene = _rectangle_scene(binding)
    else:
        return {"status": "undrawable_unbound", "reason": "drawer_has_no_bound_extent_scene", **base,
                "binding": binding}
    extent = binding["extent"]
    label = (f"{kind.replace('_', ' ')}: {extent['whole']} wholes, "
             f"{extent['iteration_count']} groups of "
             f"{extent['iteration_unit']['num']}/{extent['iteration_unit']['den']}")
    return {"status": "drawable", "document": {"frames": [_frame(scene, label)]},
            "label": label, "binding": binding, **base}


def render_mentions(extractions: list[dict[str, Any]], out_dir: Path) -> list[dict[str, Any]]:
    """Attach binding receipts and SVG filenames to representation extractions."""
    pictures, receipts = out_dir / "representations", []
    for mention in (item for item in extractions if item.get("kind") == "representation"):
        compiled = compile_mention(mention, extractions)
        receipt = {key: value for key, value in compiled.items() if key != "document"}
        if compiled["status"] == "drawable":
            name = f"{mention.get('utterance_id', 'u')}_{mention.get('id', 'r')}.svg"
            target = pictures / name
            rendering.render_svg(compiled["document"], "frame", target, ariaLabel=compiled["label"])
            receipt["svg"] = str(Path("representations") / name)
        mention["render"] = receipt
        receipts.append({"id": mention.get("id"), **receipt})
    return receipts


def _self_test() -> None:
    mention = {"id": "w1r1", "kind": "representation", "representation_kind": "number_line",
               "utterance_id": "u0002", "surface": "partition in fourths", "partition_count": 4,
               "unit_fraction": {"num": 1, "den": 4}}
    records = [
        {"id": "w1a1", "kind": "fraction:splitting", "utterance_id": "u0002",
         "arguments": {"referent_whole": 9, "equal_partition": 4,
                       "unit_fraction": {"num": 1, "den": 4}}},
        {"id": "w1a2", "kind": "fraction:unit_fraction_iteration", "utterance_id": "u0003",
         "arguments": {"iteration_count": 36, "referent_whole": 9,
                       "unit_fraction": {"num": 1, "den": 4}}},
    ]
    bound = compile_mention(mention, records)
    assert bound["status"] == "drawable"
    assert bound["binding"]["extent"] == {"whole": 9, "iteration_count": 36,
                                             "iteration_unit": {"num": 1, "den": 4}}
    svg = rendering.render_svg(bound["document"], "frame", ariaLabel=bound["label"])
    assert "36 groups" in svg and ">9<" in svg, svg
    unbound = compile_mention({**mention, "id": "w2r1"}, [])
    assert unbound["status"] == "undrawable_unbound"


if __name__ == "__main__":
    _self_test()
    print("representation_render self-test: ok")
