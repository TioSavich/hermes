#!/usr/bin/env python3
"""build_render_spec_ledger.py — 2026-08-18 coverage grind, render_spec mode.

Deterministic render coverage for every op-matched draw task in
draw_task_map.jsonl. Zero model calls: this script reads the census's own
`operand_note` / `matched_rule` / `ask_excerpt` fields and applies fixed,
inspectable rules to build a concrete request per row, then executes that
request through scripts/coverage/render_spec_gate.pl (a standalone Prolog
gate; loads one render module per request, answers frame_count or a
refusal). Only frame-producing specs enter the ledger; refusals are
recorded separately with the gate's own reason string.

Target rows: resolution == "op" (177 rows, an existing worker-reachable
render op already matches) plus resolution == "unwired" (7 rows: the
ratio_diagram_scene.pl / measurement_strip_scene.pl rows, wired into
hermes_worker.pl's dispatch_irregular/1 table on 2026-08-18 and now carried
by the extended gate too) = 184 target rows.

Per-row spec construction (per the task brief):
  1. If the statement's own numerals bind the op's operands unambiguously
     (a numeral binds only when the ask's phrasing ties it to that operand
     role directly, e.g. "3 rows of 4" -> rows=3, per_row=4; "Build 90" ->
     n=90), emit tier=render_bound with every operand the spec needs bound
     from the text. A spec is never half-bound: if any required operand
     lacks a clean textual tie, the row falls through to illustrative.
  2. Else, take the op's registered worked-example values (the exact
     defaults render_spec_gate.pl itself falls back to, read verbatim from
     hermes_worker.pl's spec builders) and emit tier=render_illustrative
     with the note that the task's own values are not stated in the text.

Op/kind resolution for a target row is a separate step from operand
binding: two families in draw_task_map.jsonl carry a dual candidate_op
("fraction_render / area_render", "geoboard_render / rigid_motion_render")
that this script resolves to the single op whose kind vocabulary the row's
own op_kind value names directly (area_model_fraction -> area_render;
stretch_polygon -> geoboard_render — fraction_render and *_compare ops
carry no dispatch entry in the standalone gate and are out of scope for
this pass). Several single-candidate families carry a *kind* menu
(pipe-separated in op_kind, e.g. area_render's
"array_multiplication|partial_products|area_model_fraction"); those are
resolved per matched_rule, with a small per-row keyword check where one
matched_rule genuinely covers more than one kind (area_array can name
partial_products; rigid_motion can name rotate).

Output (gitignored, nested path is real):
  hermes/app/runtime/experiments/coverage_grind/render_spec_ledger.jsonl
  hermes/app/runtime/experiments/coverage_grind/render_spec_refusals.jsonl
"""

import json
import re
import subprocess
import sys
from datetime import date
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
GRIND_DIR = REPO_ROOT / "hermes" / "app" / "runtime" / "experiments" / "coverage_grind"
DRAW_TASK_MAP = GRIND_DIR / "draw_task_map.jsonl"
GATE = REPO_ROOT / "scripts" / "coverage" / "render_spec_gate.pl"
LEDGER_OUT = GRIND_DIR / "render_spec_ledger.jsonl"
REFUSALS_OUT = GRIND_DIR / "render_spec_refusals.jsonl"

TODAY = "2026-08-18"
ILLUSTRATIVE_NOTE = "values illustrative; the task's own values are not stated in the text."

# =========================================================================
# 1. Op resolution for the two dual-candidate families (kind names the op).
# =========================================================================

DUAL_CANDIDATE_RESOLUTION = {
    "fraction_render / area_render": "area_render",          # op_kind == area_model_fraction
    "geoboard_render / rigid_motion_render": "geoboard_render",  # op_kind == stretch_polygon
}

# Unwired rows carry a .pl filename as candidate_op; the worker wired them
# today under these op names (hermes_worker.pl :303, :314).
UNWIRED_OP_RESOLUTION = {
    "ratio_diagram_scene.pl": "ratio_diagram_render",
    "measurement_strip_scene.pl": "measurement_strip_render",
}

# =========================================================================
# 2. matched_rule -> (op, default_args) for the illustrative fallback.
#    default_args are the exact worked-example values render_spec_gate.pl
#    itself defaults to (ported verbatim from hermes_worker.pl's spec
#    builders) — spelled out explicitly here so the ledger is
#    self-documenting rather than relying on the gate's silent defaulting.
# =========================================================================

FAMILY_TABLE = {
    "angle_draw": ("angle_circular_render", {"kind": "angle", "degrees": 120}),
    "area_array": ("area_render", {"kind": "array_multiplication", "a": 3, "b": 4}),
    "balance_hanger": ("balance_render", {"a": 2, "b": 3, "c": 11}),
    "base_ten_blocks": ("base_ten_render", {"kind": "represent", "n": 28, "base": 10}),
    "graph_a_line": ("coordinate_plane_render", {"kind": "plot_line", "slope": 2, "intercept": 1}),
    "coordinate_plot_points": (
        "coordinate_plane_render",
        {"kind": "plot_points", "points": [[-3, 2], [0, 0], [4, -1]]},
    ),
    "bar_graph": (
        "data_display_render",
        {"kind": "bar_chart", "pairs": [{"category": "red", "count": 4}, {"category": "blue", "count": 6}]},
    ),
    # picture_graph: data_display_render has no picture-graph kind; bar_chart
    # is the closest wired analogue (both are category/count displays).
    "picture_graph": (
        "data_display_render",
        {"kind": "bar_chart", "pairs": [{"category": "red", "count": 4}, {"category": "blue", "count": 6}]},
    ),
    "dot_line_plot": ("data_display_render", {"kind": "dot_plot", "values": [2, 3, 3, 5, 7]}),
    "shade_fraction_diagram": (
        "area_render",
        {"kind": "area_model_fraction", "na": 1, "da": 2, "nb": 1, "db": 3},
    ),
    "dot_grid_construction": ("geoboard_render", {"vertices": [[0, 0], [4, 0], [4, 3], [0, 3]]}),
    "polygon_construction": ("geoboard_render", {"vertices": [[0, 0], [4, 0], [4, 3], [0, 3]]}),
    "measurement_strip": (
        "measurement_strip_render",
        {"interval_count": 5, "subdivisions_per_unit": 4, "unit": "meter"},
    ),
    "notation_equation": (
        "notation_render",
        {"kind": "write_equation", "a": 2, "b": 3, "r": 5, "operator": "+"},
    ),
    "number_line_generic": (
        "number_line_render",
        {"mode": "jumps", "strategy": "COBO", "a": 28, "b": 47},
    ),
    "fraction_number_line": (
        "number_line_render",
        {"mode": "fraction", "numerator": 7, "denominator": 5},
    ),
    "double_number_line": (
        "ratio_diagram_render",
        {"first_label": "apples", "first_count": 2, "second_label": "oranges", "second_count": 3},
    ),
    "rigid_motion": (
        "rigid_motion_render",
        {"kind": "translate", "vertices": [[0, 0], [3, 0], [1, 2]], "dx": 2, "dy": 1},
    ),
    "equal_groups_draw": ("set_grouping_render", {"kind": "equal_groups", "g": 3, "s": 4}),
    "solid_net": (
        "solid_net_render",
        {"kind": "unit_cube_stack", "length": 3, "width": 2, "height": 2},
    ),
}

ROTATE_DEFAULT_ARGS = {
    "kind": "rotate",
    "vertices": [[0, 0], [3, 0], [1, 2]],
    "cx": 0,
    "cy": 0,
    "degrees": 90,
}
PARTIAL_PRODUCTS_DEFAULT_ARGS = {"kind": "partial_products", "a": 3, "b": 4}

# =========================================================================
# 3. Per-row bound overrides: numerals the ask's own phrasing ties directly
#    to a spec operand role, read by hand against each row's ask_excerpt
#    (see the task's own worked example: "3 rows of 4" -> rows=3, per_row=4).
#    Every row not listed here falls through to the family's illustrative
#    default. Comment on each entry names the exact phrase it binds.
# =========================================================================

BOUND_OVERRIDES = {
    # "Use cubes to make 6 groups of 5. Arrange them into an array."
    "im_defrag_4b70809f296525ab9c6604c3_1": (
        "area_render",
        {"kind": "array_multiplication", "a": 6, "b": 5},
    ),
    # "Draw an array for each multiplication expression. 1. 2 x 3 ..."
    "im_defrag_692e2cc799364e9b0ce2b895_1": (
        "area_render",
        {"kind": "array_multiplication", "a": 2, "b": 3},
    ),
    # Han: "My array has ... 2 rows with 6 counters in each row."
    "im_defrag_efcb84267297c701f9d7e78b_1": (
        "area_render",
        {"kind": "array_multiplication", "a": 2, "b": 6},
    ),
    # "Build 90. ... tens a. Build 90."
    "im_defrag_63da0e2c6579e3f90f6548f0_1": (
        "base_ten_render",
        {"kind": "represent", "n": 90, "base": 10},
    ),
    # "1. Show 297. a. Add ___ hundreds."
    "im_defrag_8fd444cc3ae4a94f3283cbd0_1": (
        "base_ten_render",
        {"kind": "represent", "n": 297, "base": 10},
    ),
    # "Use base-ten blocks or draw a base-ten diagram to represent 15,710."
    "im_defrag_ac300f195f77403f41269b9d_1": (
        "base_ten_render",
        {"kind": "represent", "n": 15710, "base": 10},
    ),
    # "2. Plot point T at (3,7)."
    "im_defrag_13bcbe8455886cc3f4f161b4_1": (
        "coordinate_plane_render",
        {"kind": "plot_points", "points": [[3, 7]]},
    ),
    # "Represent each equation on the number line. 1. 15 + 7 = 22 ..."
    "im_defrag_c3932c31a97ee002b52ad1ed_1": (
        "number_line_render",
        {"mode": "jumps", "strategy": "COBO", "a": 15, "b": 7},
    ),
    # "1. Locate and label 3/4 and 6/4."
    "im_defrag_679612916babdefaa52a3a9c_1": (
        "number_line_render",
        {"mode": "fraction", "numerator": 3, "denominator": 4},
    ),
}

# area_array rows whose ask_excerpt names "partial product(s)" explicitly
# rather than the family's generic array_multiplication default.
PARTIAL_PRODUCTS_ROW_IDS = {
    "im_defrag_27b09708d8720cb6a3142221_1",
    "im_defrag_915099e30baff31c5adb3ca8_1",
}

# rigid_motion rows whose ask_excerpt names "rotate" explicitly.
ROTATE_ROW_IDS = {
    "im_defrag_46877d20c6ac4383d03a11d6_1",
    "im_defrag_d78cd0ff1c143a3d2d57d71a_1",
}


def resolve_op(row):
    candidate_op = row["candidate_op"]
    if row["resolution"] == "unwired":
        return UNWIRED_OP_RESOLUTION[candidate_op]
    if candidate_op in DUAL_CANDIDATE_RESOLUTION:
        return DUAL_CANDIDATE_RESOLUTION[candidate_op]
    return candidate_op


def build_args(row):
    """Returns (op, args, tier, note)."""
    record_id = row["record_id"]
    matched_rule = row["matched_rule"]
    op = resolve_op(row)

    if record_id in BOUND_OVERRIDES:
        bound_op, bound_args = BOUND_OVERRIDES[record_id]
        assert bound_op == op, (record_id, bound_op, op)
        return op, dict(bound_args), "render_bound", None

    family_op, default_args = FAMILY_TABLE[matched_rule]
    assert family_op == op, (record_id, matched_rule, family_op, op)
    args = dict(default_args)

    if matched_rule == "area_array" and record_id in PARTIAL_PRODUCTS_ROW_IDS:
        args = dict(PARTIAL_PRODUCTS_DEFAULT_ARGS)
    if matched_rule == "rigid_motion" and record_id in ROTATE_ROW_IDS:
        args = dict(ROTATE_DEFAULT_ARGS)

    return op, args, "render_illustrative", ILLUSTRATIVE_NOTE


def run_gate(op, args):
    payload = json.dumps({"op": op, "request": args})
    proc = subprocess.run(
        ["swipl", str(GATE), "--root", str(REPO_ROOT)],
        input=payload,
        capture_output=True,
        text=True,
        timeout=60,
    )
    stdout = proc.stdout.strip()
    if not stdout:
        return {"ok": False, "reason": f"gate_produced_no_stdout(exit={proc.returncode})"}
    # The gate emits exactly one JSON line on stdout; consult warnings from
    # paths.pl's own load chain land on stderr and are ignored here.
    last_line = stdout.splitlines()[-1]
    try:
        return json.loads(last_line)
    except json.JSONDecodeError:
        return {"ok": False, "reason": f"unparseable_gate_stdout({last_line!r})"}


def main():
    rows = []
    with DRAW_TASK_MAP.open() as f:
        for line in f:
            row = json.loads(line)
            if row["resolution"] in ("op", "unwired"):
                rows.append(row)

    assert len(rows) == 184, f"expected 184 target rows, got {len(rows)}"

    ledger_entries = []
    refusal_entries = []

    for i, row in enumerate(rows, 1):
        op, args, tier, note = build_args(row)
        result = run_gate(op, args)

        base = {
            "record_id": row["record_id"],
            "lesson": row["lesson"],
            "grade": row["grade"],
            "op": op,
            "args": args,
            "tier": tier,
            "date": TODAY,
        }
        if note is not None:
            base["note"] = note

        if result.get("ok") is True:
            entry = dict(base)
            entry["frame_count"] = result["frame_count"]
            entry["provenance"] = "deterministic_mapping"
            ledger_entries.append(entry)
        else:
            entry = dict(base)
            entry["refusal_reason"] = result.get("reason", "unknown")
            entry["provenance"] = "deterministic_mapping"
            refusal_entries.append(entry)

        if i % 20 == 0 or i == len(rows):
            print(f"  ... {i}/{len(rows)} rows executed", file=sys.stderr)

    with LEDGER_OUT.open("w") as f:
        for entry in ledger_entries:
            f.write(json.dumps(entry) + "\n")

    with REFUSALS_OUT.open("w") as f:
        for entry in refusal_entries:
            f.write(json.dumps(entry) + "\n")

    print(f"ledger rows: {len(ledger_entries)}", file=sys.stderr)
    print(f"refusal rows: {len(refusal_entries)}", file=sys.stderr)
    print(f"wrote {LEDGER_OUT}", file=sys.stderr)
    print(f"wrote {REFUSALS_OUT}", file=sys.stderr)


if __name__ == "__main__":
    main()
