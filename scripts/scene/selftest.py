#!/usr/bin/env python3
"""Exercise every node type, then check the result is a page with ink on it.

The typesetter's claim is that a valid scene cannot produce an unreadable
figure. That claim is only worth what it is tested against, so this walks the
whole vocabulary: each block type at least once, marks on digits, a carry above
a digit, a column note, a wrong-vs-right pair, a double number line with an arc,
partly filled rods, a dot grid. It also feeds the validator a handful of scenes
that should be refused, and checks each refusal names the offending path.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "t228"))
from scene_schema import SchemaError, validate          # noqa: E402
from typeset import typeset                             # noqa: E402
from gate_svg import _ink_fraction, rasterise_to_png    # noqa: E402

HERE = Path(__file__).resolve().parent

EVERY = {
    "title": "Every node type at once",
    "panels": [
        {"role": "student", "title": "what the student wrote", "blocks": [
            {"type": "column_calc",
             "columns": ["hundreds", "tens", "ones"],
             "rows": [
                 {"kind": "operand", "cells": [
                     {"text": "3"},
                     {"text": "6", "above": "5", "mark": "strike"},
                     {"text": "4", "above": "14"}]},
                 {"kind": "operand", "operator": "-", "cells": [
                     {"text": "2"}, {"text": "3"}, {"text": "6"}]},
                 {"kind": "result", "cells": [
                     {"text": "1"}, {"text": "2"},
                     {"text": "2", "role": "error", "mark": "circle"}]}],
             "column_notes": [
                 {"column": 2, "role": "error",
                  "text": "the regrouping is written above the 4, and then not "
                          "used: the ones are still taken smaller from larger."}]},
             {"type": "note", "role": "error", "emphasis": "strong",
              "text": "The exchange was inscribed but never spent."}]},
        {"role": "correct", "blocks": [
            {"type": "expr_lines", "lines": [
                {"text": "14 - 6 = 8", "role": "correct"},
                {"text": "2/7 + 3/7 = 5/7", "note": "like denominators: the unit "
                                                    "is already shared",
                 "note_role": "annotation"},
                {"text": "5/14", "role": "error", "mark": "strike",
                 "note": "the mediant is a different number"}]},
            {"type": "bar", "label": "one whole in sevenths", "parts": [
                {"text": "1/7", "shaded": True}, {"text": "1/7", "shaded": True},
                {"text": "1/7", "shaded": True}, {"text": "1/7", "shaded": True},
                {"text": "1/7", "shaded": True}, {"text": "1/7"},
                {"text": "1/7"}]}]},
        {"role": "given", "title": "the rest of the vocabulary", "blocks": [
            {"type": "number_line", "lanes": [
                {"label": "metres", "ticks": [{"text": "0"}, {"text": "1"},
                                              {"text": "2.5"}, {"text": "5"}],
                 "points": [{"at": 3, "text": "5 m", "role": "annotation"}]},
                {"label": "yen", "ticks": [{"text": "0"}, {"text": "?"},
                                           {"text": "100"}, {"text": "200"}]}],
             "arcs": [{"lane": 0, "from": 2, "to": 3, "text": "doubled",
                       "role": "annotation"}]},
            {"type": "base_ten", "columns": [
                {"label": "hundreds", "groups": [{"unit": "flat", "count": 1}]},
                {"label": "tens", "groups": [
                    {"unit": "rod", "count": 2, "partial": 4}]},
                {"label": "ones", "groups": [
                    {"unit": "cube", "count": 7, "marked": 3, "mark": "strike"}]}]},
            {"type": "table", "headers": ["tens", "ones"], "rows": [
                [{"text": "4"}, {"text": "0"}],
                [{"text": "3"}, {"text": "10", "role": "annotation"}]]},
            {"type": "shape", "grid": "dots", "figures": [
                {"kind": "trapezoid", "label": "trapezoid"},
                {"kind": "l_tetromino", "label": "1", "rotation": 90},
                {"kind": "circle", "label": "whole", "role": "muted"}]}]}],
    "caption": "A scene exercising every block the vocabulary defines.",
}

BAD = [
    ({"title": "t", "panels": [{"role": "student", "blocks": [
        {"type": "column_calc", "rows": [{"cells": [{"text": "1", "mark": "cross"}]}]}]}]},
     "mark"),
    ({"title": "t", "panels": [{"role": "student", "blocks": [
        {"type": "note", "text": "x", "x": 40}]}]}, ".x"),
    ({"title": "t", "panels": [{"role": "student", "blocks": [
        {"type": "column_calc", "columns": ["tens", "ones"],
         "rows": [{"cells": [{"text": "1"}, {"text": "2"}, {"text": "3"}]}]}]}]},
     "columns"),
    ({"title": "t", "panels": [{"role": "student", "blocks": [
        {"type": "number_line",
         "lanes": [{"ticks": [{"text": "0"}, {"text": "1"}]}],
         "arcs": [{"from": 0, "to": 7}]}]}]}, "arcs[0].to"),
    ({"title": "t", "panels": [{"role": "student", "blocks": [
        {"type": "shape", "figures": [{"kind": "dodecahedron"}]}]}]}, "kind"),
]


def main() -> int:
    validate(EVERY)
    svg = typeset(EVERY)
    out = HERE / "selftest.svg"
    out.write_text(svg)
    print(f"typeset every-node scene: {len(svg):,} bytes -> {out.name}")

    for scene, want in BAD:
        try:
            validate(scene)
        except SchemaError as exc:
            msg = str(exc)
            ok = want in msg
            print(f"  refused ({'names the path' if ok else 'PATH MISSING'}): {msg}")
            if not ok:
                return 1
        else:
            print(f"  NOT REFUSED but should have been: {json.dumps(scene)[:90]}")
            return 1

    png = HERE / "selftest.png"
    ok, detail = rasterise_to_png(svg, png, dpi=110)
    if not ok:
        print(f"RASTERISE FAILED: {detail}")
        return 1
    ink = _ink_fraction(png)
    print(f"rasterised: {detail}; ink fraction "
          f"{'unmeasurable' if ink is None else f'{ink:.3f}'} -> selftest.png")
    return 0 if (ink is None or ink >= 0.002) else 1


if __name__ == "__main__":
    raise SystemExit(main())
