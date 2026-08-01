#!/usr/bin/env python3
"""The scene vocabulary: what a figure may say, with no way to say where.

Round 1 asked the model for SVG and got mathematics destroyed by coordinates --
labels printed on top of each other, a filled rectangle over its own caption,
text past the canvas edge. The content was mostly right and the placement made
it unreadable. So the model no longer places anything. It writes a scene: what
the panels are, what the digits are, which digit carries a strike or a carry,
what the note says. `typeset.py` decides every x and y.

The rule this module enforces: **no field anywhere in this schema is a
coordinate, a size, or a colour.** No x, y, width, height, font-size, fill.
Positions that do appear are indices into a list the scene itself declares --
"the note attaches to column 2", "the arc runs from tick 0 to tick 3" -- which
are semantic references, not placements. Every other field is either free text
or a member of a closed enum.

Validation names the path of a violation (`panels[1].blocks[0].rows[2].cells[3]
.mark`) so a failure is actionable rather than a shrug. A scene the schema
cannot express is a refusal at generation time; the typesetter never improvises
a rectangle to cover a gap.

This mirrors the split the render lane already runs on: notation_scene.pl
computes every glyph x in Prolog and the JS drawer does no arithmetic. Here the
model supplies content and the typesetter does all the arithmetic.

Standard library only.
"""
from __future__ import annotations

# --- closed vocabularies ---------------------------------------------------

ROLES = ("ink", "error", "annotation", "correct", "muted")
MARKS = ("none", "strike", "circle", "box", "underline")
PANEL_ROLES = ("student", "correct", "given", "contrast")
ROW_KINDS = ("operand", "result", "work")
UNITS = ("flat", "rod", "cube")
GRIDS = ("none", "dots")
EMPHASES = ("normal", "strong")
ROTATIONS = (0, 90, 180, 270)

# Canonical figures the typesetter can draw from a name alone. A shape outside
# this list is a refusal, not an approximation: the point of naming them is that
# the model never supplies a vertex.
SHAPE_KINDS = (
    "trapezoid", "parallelogram", "rectangle", "square", "triangle",
    "right_triangle", "pentagon", "hexagon", "circle",
    "l_tromino", "l_tetromino", "t_tetromino", "s_tetromino", "square_tetromino",
)

BLOCK_TYPES = (
    "column_calc", "expr_lines", "bar", "number_line",
    "base_ten", "table", "shape", "note",
)

MAX_PANELS = 4
MAX_BLOCKS_PER_PANEL = 6


class SchemaError(ValueError):
    """A scene that says something the vocabulary has no way to say."""


def _fail(path: str, msg: str) -> None:
    raise SchemaError(f"{path}: {msg}")


def _need_dict(v, path):
    if not isinstance(v, dict):
        _fail(path, f"expected an object, got {type(v).__name__}")


def _need_list(v, path, *, minlen=0, maxlen=None):
    if not isinstance(v, list):
        _fail(path, f"expected a list, got {type(v).__name__}")
    if len(v) < minlen:
        _fail(path, f"needs at least {minlen} entr{'y' if minlen == 1 else 'ies'}, got {len(v)}")
    if maxlen is not None and len(v) > maxlen:
        _fail(path, f"holds at most {maxlen} entries, got {len(v)}")


def _need_str(v, path, *, allow_empty=False):
    if not isinstance(v, str):
        _fail(path, f"expected text, got {type(v).__name__}")
    if not allow_empty and not v.strip():
        _fail(path, "is empty")


def _need_int(v, path, *, lo=None, hi=None):
    if isinstance(v, bool) or not isinstance(v, int):
        _fail(path, f"expected a whole number, got {type(v).__name__}")
    if lo is not None and v < lo:
        _fail(path, f"must be at least {lo}, got {v}")
    if hi is not None and v > hi:
        _fail(path, f"must be at most {hi}, got {v}")


def _need_enum(v, path, allowed):
    if v not in allowed:
        _fail(path, f"{v!r} is not one of {list(allowed)}")


def _reject_placement(obj, path) -> None:
    """The one structural rule: nothing here may carry a coordinate."""
    banned = {"x", "y", "cx", "cy", "width", "height", "w", "h", "top", "left",
              "size", "font_size", "fontsize", "fill", "color", "colour",
              "stroke", "transform", "viewbox", "dx", "dy", "px"}
    if isinstance(obj, dict):
        for k in obj:
            if isinstance(k, str) and k.lower() in banned:
                _fail(f"{path}.{k}",
                      "is a placement or styling field; the scene says what the "
                      "figure means and the typesetter decides how it looks")


def _cell(v, path) -> None:
    _need_dict(v, path)
    _reject_placement(v, path)
    # `text` is optional and defaults to blank. The first draft required it, and
    # the smoke showed the model writing {"above": "13"} for a column that holds
    # only a carry -- which is a reasonable thing to mean, and the retry that
    # quoted the path back did not change it. A cell carrying nothing but a mark
    # is legitimate, so the vocabulary accommodates it rather than refusing it.
    if v.get("text") is not None:
        _need_str(v["text"], f"{path}.text", allow_empty=True)
    _need_enum(v.get("role", "ink"), f"{path}.role", ROLES)
    _need_enum(v.get("mark", "none"), f"{path}.mark", MARKS)
    for opt in ("above", "below"):
        if v.get(opt) is not None:
            _need_str(v[opt], f"{path}.{opt}", allow_empty=True)


# --- per-block validators --------------------------------------------------

def _v_column_calc(b, path) -> None:
    _need_list(b.get("rows"), f"{path}.rows", minlen=1, maxlen=8)
    widths = set()
    for i, row in enumerate(b["rows"]):
        rp = f"{path}.rows[{i}]"
        _need_dict(row, rp)
        _reject_placement(row, rp)
        _need_enum(row.get("kind", "operand"), f"{rp}.kind", ROW_KINDS)
        if row.get("operator") is not None:
            _need_str(row["operator"], f"{rp}.operator", allow_empty=True)
            if len(row["operator"]) > 2:
                _fail(f"{rp}.operator", "is one or two characters, e.g. \"-\" or \"+\"")
        _need_list(row.get("cells"), f"{rp}.cells", minlen=1, maxlen=12)
        for j, c in enumerate(row["cells"]):
            _cell(c, f"{rp}.cells[{j}]")
        widths.add(len(row["cells"]))
    ncol = max(widths)
    if b.get("columns") is not None:
        _need_list(b["columns"], f"{path}.columns", minlen=1, maxlen=12)
        for i, lab in enumerate(b["columns"]):
            _need_str(lab, f"{path}.columns[{i}]", allow_empty=True)
        # The labels may declare a wider grid than any row fills -- rows are
        # right-aligned into it, which is how a two-digit subtrahend sits under
        # a three-digit minuend. Only the reverse is incoherent: a row cannot
        # hold more digits than the grid has columns.
        if ncol > len(b["columns"]):
            _fail(f"{path}.columns",
                  f"labels {len(b['columns'])} columns but a row holds {ncol} "
                  f"cells; a row cannot be wider than the grid")
        ncol = len(b["columns"])
    for i, n in enumerate(b.get("column_notes") or []):
        np_ = f"{path}.column_notes[{i}]"
        _need_dict(n, np_)
        _reject_placement(n, np_)
        _need_int(n.get("column"), f"{np_}.column", lo=0, hi=ncol - 1)
        _need_str(n.get("text"), f"{np_}.text")
        _need_enum(n.get("role", "annotation"), f"{np_}.role", ROLES)
    if b.get("rule_after") is not None:
        _need_int(b["rule_after"], f"{path}.rule_after", lo=0, hi=len(b["rows"]) - 1)


def _v_expr_lines(b, path) -> None:
    _need_list(b.get("lines"), f"{path}.lines", minlen=1, maxlen=10)
    for i, ln in enumerate(b["lines"]):
        lp = f"{path}.lines[{i}]"
        _need_dict(ln, lp)
        _reject_placement(ln, lp)
        _need_str(ln.get("text"), f"{lp}.text")
        _need_enum(ln.get("role", "ink"), f"{lp}.role", ROLES)
        _need_enum(ln.get("mark", "none"), f"{lp}.mark", MARKS)
        if ln.get("note") is not None:
            _need_str(ln["note"], f"{lp}.note")
            _need_enum(ln.get("note_role", "annotation"), f"{lp}.note_role", ROLES)


def _v_bar(b, path) -> None:
    _need_list(b.get("parts"), f"{path}.parts", minlen=1, maxlen=24)
    if b.get("label") is not None:
        _need_str(b["label"], f"{path}.label", allow_empty=True)
    for i, p in enumerate(b["parts"]):
        pp = f"{path}.parts[{i}]"
        _need_dict(p, pp)
        _reject_placement(p, pp)
        if p.get("text") is not None:
            _need_str(p["text"], f"{pp}.text", allow_empty=True)
        if p.get("shaded") is not None and not isinstance(p["shaded"], bool):
            _fail(f"{pp}.shaded", "is true or false")
        _need_enum(p.get("role", "ink"), f"{pp}.role", ROLES)
        _need_enum(p.get("mark", "none"), f"{pp}.mark", MARKS)


def _v_number_line(b, path) -> None:
    _need_list(b.get("lanes"), f"{path}.lanes", minlen=1, maxlen=3)
    tick_counts = []
    for i, lane in enumerate(b["lanes"]):
        lp = f"{path}.lanes[{i}]"
        _need_dict(lane, lp)
        _reject_placement(lane, lp)
        if lane.get("label") is not None:
            _need_str(lane["label"], f"{lp}.label", allow_empty=True)
        _need_list(lane.get("ticks"), f"{lp}.ticks", minlen=2, maxlen=21)
        for j, t in enumerate(lane["ticks"]):
            tp = f"{lp}.ticks[{j}]"
            _need_dict(t, tp)
            _reject_placement(t, tp)
            if t.get("text") is not None:
                _need_str(t["text"], f"{tp}.text", allow_empty=True)
        tick_counts.append(len(lane["ticks"]))
        for j, pt in enumerate(lane.get("points") or []):
            pp = f"{lp}.points[{j}]"
            _need_dict(pt, pp)
            _reject_placement(pt, pp)
            _need_int(pt.get("at"), f"{pp}.at", lo=0, hi=len(lane["ticks"]) - 1)
            if pt.get("text") is not None:
                _need_str(pt["text"], f"{pp}.text", allow_empty=True)
            _need_enum(pt.get("role", "ink"), f"{pp}.role", ROLES)
    if len(set(tick_counts)) > 1:
        _fail(f"{path}.lanes",
              f"every lane needs the same number of ticks so they line up; got "
              f"{tick_counts}")
    for i, a in enumerate(b.get("arcs") or []):
        ap = f"{path}.arcs[{i}]"
        _need_dict(a, ap)
        _reject_placement(a, ap)
        lane_i = a.get("lane", 0)
        _need_int(lane_i, f"{ap}.lane", lo=0, hi=len(b["lanes"]) - 1)
        n = tick_counts[lane_i]
        _need_int(a.get("from"), f"{ap}.from", lo=0, hi=n - 1)
        _need_int(a.get("to"), f"{ap}.to", lo=0, hi=n - 1)
        if a["from"] == a["to"]:
            _fail(f"{ap}.to", "an arc must span two different ticks")
        if a.get("text") is not None:
            _need_str(a["text"], f"{ap}.text", allow_empty=True)
        _need_enum(a.get("role", "annotation"), f"{ap}.role", ROLES)


def _v_base_ten(b, path) -> None:
    _need_list(b.get("columns"), f"{path}.columns", minlen=1, maxlen=4)
    for i, col in enumerate(b["columns"]):
        cp = f"{path}.columns[{i}]"
        _need_dict(col, cp)
        _reject_placement(col, cp)
        if col.get("label") is not None:
            _need_str(col["label"], f"{cp}.label", allow_empty=True)
        _need_list(col.get("groups"), f"{cp}.groups", minlen=1, maxlen=4)
        for j, g in enumerate(col["groups"]):
            gp = f"{cp}.groups[{j}]"
            _need_dict(g, gp)
            _reject_placement(g, gp)
            _need_enum(g.get("unit"), f"{gp}.unit", UNITS)
            _need_int(g.get("count"), f"{gp}.count", lo=0, hi=20)
            if g.get("marked") is not None:
                _need_int(g["marked"], f"{gp}.marked", lo=0, hi=g["count"])
            if g.get("partial") is not None:
                if g["unit"] != "rod":
                    _fail(f"{gp}.partial",
                          "only a rod has ten segments to fill partly")
                _need_int(g["partial"], f"{gp}.partial", lo=0, hi=10)
            _need_enum(g.get("role", "ink"), f"{gp}.role", ROLES)
            _need_enum(g.get("mark", "none"), f"{gp}.mark", MARKS)


def _v_table(b, path) -> None:
    _need_list(b.get("rows"), f"{path}.rows", minlen=1, maxlen=10)
    widths = set()
    for i, row in enumerate(b["rows"]):
        rp = f"{path}.rows[{i}]"
        _need_list(row, rp, minlen=1, maxlen=8)
        for j, c in enumerate(row):
            _cell(c, f"{rp}[{j}]")
        widths.add(len(row))
    if b.get("headers") is not None:
        _need_list(b["headers"], f"{path}.headers", minlen=1, maxlen=8)
        for i, hcell in enumerate(b["headers"]):
            _need_str(hcell, f"{path}.headers[{i}]", allow_empty=True)
        if len(b["headers"]) != max(widths):
            _fail(f"{path}.headers",
                  f"names {len(b['headers'])} columns but the widest row has "
                  f"{max(widths)} cells")


def _v_shape(b, path) -> None:
    _need_enum(b.get("grid", "none"), f"{path}.grid", GRIDS)
    _need_list(b.get("figures"), f"{path}.figures", minlen=1, maxlen=8)
    for i, f in enumerate(b["figures"]):
        fp = f"{path}.figures[{i}]"
        _need_dict(f, fp)
        _reject_placement(f, fp)
        _need_enum(f.get("kind"), f"{fp}.kind", SHAPE_KINDS)
        if f.get("label") is not None:
            _need_str(f["label"], f"{fp}.label", allow_empty=True)
        _need_enum(f.get("rotation", 0), f"{fp}.rotation", ROTATIONS)
        _need_enum(f.get("role", "ink"), f"{fp}.role", ROLES)


def _v_note(b, path) -> None:
    _need_str(b.get("text"), f"{path}.text")
    _need_enum(b.get("role", "ink"), f"{path}.role", ROLES)
    _need_enum(b.get("emphasis", "normal"), f"{path}.emphasis", EMPHASES)


_BLOCK_VALIDATORS = {
    "column_calc": _v_column_calc,
    "expr_lines": _v_expr_lines,
    "bar": _v_bar,
    "number_line": _v_number_line,
    "base_ten": _v_base_ten,
    "table": _v_table,
    "shape": _v_shape,
    "note": _v_note,
}


def _normalize_flat_base_ten(scene) -> None:
    """Accept the flat base_ten encoding the model reaches for and rewrite it
    to the canonical nested form, losslessly and only when unambiguous.

    Observed in the 7859280 batch on four items: columns as bare label
    strings beside one flat sibling groups list, one group per column in
    order. When len(groups) == len(columns) and every group is a dict, that
    carries exactly the canonical content, so it normalizes rather than
    refuses. Any other flat shape still falls through to the named refusal.
    """
    if not isinstance(scene, dict):
        return
    for panel in scene.get("panels") or []:
        if not isinstance(panel, dict):
            continue
        for b in panel.get("blocks") or []:
            if not (isinstance(b, dict) and b.get("type") == "base_ten"):
                continue
            cols, flat = b.get("columns"), b.get("groups")
            if (isinstance(cols, list) and cols
                    and all(isinstance(c, str) for c in cols)
                    and isinstance(flat, list)
                    and len(flat) == len(cols)
                    and all(isinstance(g, dict) for g in flat)):
                b["columns"] = [{"label": lab, "groups": [g]}
                                for lab, g in zip(cols, flat)]
                del b["groups"]


def validate(scene) -> dict:
    """Return the scene, or raise SchemaError naming the offending path."""
    _normalize_flat_base_ten(scene)
    _need_dict(scene, "scene")
    _reject_placement(scene, "scene")
    _need_str(scene.get("title"), "scene.title")
    if scene.get("caption") is not None:
        _need_str(scene["caption"], "scene.caption", allow_empty=True)
    _need_list(scene.get("panels"), "scene.panels", minlen=1, maxlen=MAX_PANELS)
    for i, panel in enumerate(scene["panels"]):
        pp = f"panels[{i}]"
        _need_dict(panel, pp)
        _reject_placement(panel, pp)
        _need_enum(panel.get("role", "given"), f"{pp}.role", PANEL_ROLES)
        if panel.get("title") is not None:
            _need_str(panel["title"], f"{pp}.title", allow_empty=True)
        _need_list(panel.get("blocks"), f"{pp}.blocks",
                   minlen=1, maxlen=MAX_BLOCKS_PER_PANEL)
        for j, block in enumerate(panel["blocks"]):
            bp = f"{pp}.blocks[{j}]"
            _need_dict(block, bp)
            _reject_placement(block, bp)
            t = block.get("type")
            if t not in BLOCK_TYPES:
                _fail(f"{bp}.type", f"{t!r} is not one of {list(BLOCK_TYPES)}")
            _BLOCK_VALIDATORS[t](block, bp)
    return scene


def check(scene) -> tuple[bool, str]:
    """Non-raising form: (ok, message)."""
    try:
        validate(scene)
        return True, ""
    except SchemaError as exc:
        return False, str(exc)
