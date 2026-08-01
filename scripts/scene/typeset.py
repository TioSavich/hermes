#!/usr/bin/env python3
"""Scene JSON in, SVG out. Every coordinate on the page is decided here.

The layout is measure-then-place. Each block draws itself into a local frame
whose origin is its own top-left and reports the width and height it actually
used; a panel stacks its blocks with a fixed gap and takes the widest; the
canvas is the bounding box of the panels plus a margin. Nothing is positioned
against a guessed page size, so nothing can fall off the edge -- the edge is
computed after the content, not before it.

Text width is approximated as character count times font size times a factor
slightly above the true average for this font stack. Approximating high means
boxes are a little roomy and never too tight, which is the failure direction
that stays readable.

Colours are the render lane's own variables, read from hermes/web/render/
host.css rather than invented here: ink #0d0c08, the deformation rust #b95238
that already marks a misconception in the notation drawer, the point blue
#4c6b8a for annotation, the bar green #6e8b5d for a correct partner, and the
paper #f4ead6. Matching them means a figure from this pilot sits beside a figure
from the live renderer without announcing itself as a different tool.

Standard library only.
"""
from __future__ import annotations

import re
import textwrap

from scene_schema import validate

# --- palette, from hermes/web/render/host.css ------------------------------

PAPER = "#f4ead6"
INK = "#0d0c08"
LABEL = "#1b1810"
ROLE_COLOR = {
    "ink": "#0d0c08",
    "error": "#b95238",        # --fig-deformation
    "annotation": "#4c6b8a",   # --fig-point
    "correct": "#6e8b5d",      # --fig-bar
    "muted": "#8a6f4c",        # --fig-pre-image
}
UNIT_FILL = {"flat": "#a97c24", "rod": "#d4a747", "cube": "#6e4f15"}
NEUTRAL = "#cabf9f"
WHOLE = "#ebdfc5"
RULE = "#b8ab8d"

# --- type sizes ------------------------------------------------------------

FS_TITLE = 18
FS_PANEL = 12
FS_DIGIT = 26
FS_TEXT = 13
FS_SMALL = 10.5
FS_TINY = 9

FONT = "Helvetica, 'DejaVu Sans', Arial, sans-serif"
WF, WF_BOLD = 0.60, 0.635      # width factor: chars * size * factor

MARGIN = 26.0
PANEL_PAD = 14.0
PANEL_GAP = 20.0
BLOCK_GAP = 16.0
MAX_PANEL_W = 620.0
MIN_CONTENT_W = 300.0


def esc(s) -> str:
    return (str(s).replace("&", "&amp;").replace("<", "&lt;")
            .replace(">", "&gt;").replace('"', "&quot;"))


def measure(s: str, size: float, bold: bool = False) -> float:
    return len(s or "") * size * (WF_BOLD if bold else WF)


def col_of(role: str) -> str:
    return ROLE_COLOR.get(role or "ink", INK)


class Box:
    """Elements drawn in a local frame, plus the extent they occupy."""

    __slots__ = ("w", "h", "els")

    def __init__(self, w: float, h: float, els: list[str]):
        self.w, self.h, self.els = float(w), float(h), els

    def at(self, dx: float, dy: float) -> str:
        return (f'<g transform="translate({dx:.1f},{dy:.1f})">'
                + "".join(self.els) + "</g>")


# --- primitives ------------------------------------------------------------

def _t(x, y, s, size, color=INK, anchor="start", bold=False, style="") -> str:
    return (f'<text x="{x:.1f}" y="{y:.1f}" font-family="{FONT}" '
            f'font-size="{size:.1f}" fill="{color}" text-anchor="{anchor}"'
            + (' font-weight="bold"' if bold else "")
            + (f' {style}' if style else "")
            + f'>{esc(s)}</text>')


def _line(x1, y1, x2, y2, color=INK, w=1.4, dash="") -> str:
    d = f' stroke-dasharray="{dash}"' if dash else ""
    return (f'<line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}" '
            f'stroke="{color}" stroke-width="{w}"{d}/>')


def _rect(x, y, w, h, stroke=INK, fill="none", sw=1.2, rx=0) -> str:
    return (f'<rect x="{x:.1f}" y="{y:.1f}" width="{max(w, 0):.1f}" '
            f'height="{max(h, 0):.1f}" fill="{fill}" stroke="{stroke}" '
            f'stroke-width="{sw}" rx="{rx}"/>')


def _circle(x, y, r, stroke=INK, fill="none", sw=1.2) -> str:
    return (f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r:.1f}" fill="{fill}" '
            f'stroke="{stroke}" stroke-width="{sw}"/>')


def _poly(pts, stroke=INK, fill="none", sw=1.5) -> str:
    p = " ".join(f"{x:.1f},{y:.1f}" for x, y in pts)
    return (f'<polygon points="{p}" fill="{fill}" stroke="{stroke}" '
            f'stroke-width="{sw}" stroke-linejoin="round"/>')


def _mark_over(cx, cy, w, h, mark, color) -> list[str]:
    """Decorate a glyph slot centred on (cx, cy). Never covers the glyph."""
    if mark == "strike":
        return [_line(cx - w / 2, cy, cx + w / 2, cy, color, 2.0)]
    if mark == "circle":
        return [f'<ellipse cx="{cx:.1f}" cy="{cy:.1f}" rx="{w * 0.62:.1f}" '
                f'ry="{h * 0.58:.1f}" fill="none" stroke="{color}" '
                f'stroke-width="1.6"/>']
    if mark == "box":
        return [_rect(cx - w * 0.6, cy - h * 0.55, w * 1.2, h * 1.1,
                      color, "none", 1.6, rx=2)]
    if mark == "underline":
        return [_line(cx - w / 2, cy + h * 0.52, cx + w / 2, cy + h * 0.52,
                      color, 1.8)]
    return []


# --- inline expressions: a/b becomes a stacked fraction --------------------

FRAC = re.compile(r"^(-?\d+)/(\d+)$")


def inline(text: str, size: float, color: str, bold: bool = False) -> Box:
    """Lay a line of text left to right, stacking any n/d token."""
    els: list[str] = []
    x = 0.0
    gap = size * 0.30
    asc = size * 0.74           # baseline sits this far below the local top
    h_frac = size * 2.05
    top_pad = (h_frac - size) / 2 if True else 0.0
    baseline = top_pad + asc
    for tok in (text or "").split(" "):
        if not tok:
            x += gap
            continue
        m = FRAC.match(tok)
        if m:
            n, d = m.group(1), m.group(2)
            wn, wd = measure(n, size, bold), measure(d, size, bold)
            w = max(wn, wd) + size * 0.30
            cx = x + w / 2
            bar_y = baseline - size * 0.28
            els.append(_t(cx, bar_y - size * 0.20, n, size, color, "middle", bold))
            els.append(_line(x + size * 0.06, bar_y, x + w - size * 0.06, bar_y,
                             color, 1.5))
            els.append(_t(cx, bar_y + size * 0.86, d, size, color, "middle", bold))
            x += w + gap
        else:
            els.append(_t(x, baseline, tok, size, color, "start", bold))
            x += measure(tok, size, bold) + gap
    return Box(max(x - gap, 0), h_frac, els)


def _wrap_width(avail: float, size: float) -> int:
    return max(18, int(avail / (size * WF)))


# --- blocks ----------------------------------------------------------------

def b_note(b, avail_w) -> Box:
    size = FS_TEXT if b.get("emphasis") != "strong" else FS_TEXT + 2
    bold = b.get("emphasis") == "strong"
    color = col_of(b.get("role"))
    lines = textwrap.wrap(b["text"], _wrap_width(avail_w, size)) or [""]
    lh = size * 1.42
    els = [_t(0, lh * 0.78 + i * lh, ln, size, color, "start", bold)
           for i, ln in enumerate(lines)]
    w = max(measure(ln, size, bold) for ln in lines)
    return Box(w, lh * len(lines), els)


def b_expr_lines(b) -> Box:
    els: list[str] = []
    y = 0.0
    w = 0.0
    for ln in b["lines"]:
        color = col_of(ln.get("role"))
        ib = inline(ln["text"], FS_TEXT + 4, color)
        els.append(ib.at(0, y))
        els += [e for e in _mark_over(ib.w / 2, y + ib.h / 2, ib.w, ib.h * 0.5,
                                      ln.get("mark", "none"), color)]
        w = max(w, ib.w)
        y += ib.h + 3
        if ln.get("note"):
            nc = col_of(ln.get("note_role", "annotation"))
            nl = textwrap.wrap(ln["note"], 58) or [""]
            for k, t in enumerate(nl):
                els.append(_t(12, y + FS_SMALL * 0.9 + k * FS_SMALL * 1.32, t,
                              FS_SMALL, nc))
                w = max(w, 12 + measure(t, FS_SMALL))
            y += FS_SMALL * 1.32 * len(nl) + 4
        y += 6
    return Box(w, max(y - 6, 0), els)


def b_column_calc(b) -> Box:
    rows = b["rows"]
    labels = b.get("columns")
    ncol = max([len(r["cells"]) for r in rows] + ([len(labels)] if labels else []))
    has_above = any(c.get("above") for r in rows for c in r["cells"])
    has_below = any(c.get("below") for r in rows for c in r["cells"])

    cell_w = 38.0
    for r in rows:
        for c in r["cells"]:
            cell_w = max(cell_w, measure(c.get("text") or "", FS_DIGIT) + 14)
    if labels:
        for lab in labels:
            cell_w = max(cell_w, measure(lab, FS_TINY) + 10)

    op_w = 30.0
    row_h = FS_DIGIT * 1.42
    above_h = FS_SMALL * 1.5 if has_above else 0.0
    below_h = FS_SMALL * 1.4 if has_below else 0.0
    grid_w = op_w + ncol * cell_w
    els: list[str] = []
    y = 0.0

    if labels:
        for i, lab in enumerate(labels):
            cx = op_w + i * cell_w + cell_w / 2
            els.append(_t(cx, FS_TINY, lab, FS_TINY, ROLE_COLOR["muted"], "middle"))
        els.append(_line(0, FS_TINY + 5, grid_w, FS_TINY + 5, RULE, 0.8))
        y = FS_TINY + 12

    rule_after = b.get("rule_after")
    if rule_after is None:
        idx = [i for i, r in enumerate(rows) if r.get("kind") == "result"]
        rule_after = (idx[0] - 1) if idx else len(rows) - 2
    grid_top = y

    for ri, r in enumerate(rows):
        cells = r["cells"]
        pad = ncol - len(cells)          # right-aligned, as columns are
        y_top = y + above_h
        base = y_top + row_h * 0.74
        if r.get("operator"):
            els.append(_t(op_w * 0.55, base, r["operator"], FS_DIGIT,
                          INK, "middle"))
        for ci, c in enumerate(cells):
            col = pad + ci
            cx = op_w + col * cell_w + cell_w / 2
            color = col_of(c.get("role"))
            if c.get("text"):
                els.append(_t(cx, base, c["text"], FS_DIGIT, color, "middle"))
            if c.get("above"):
                els.append(_t(cx, y + FS_SMALL * 0.95, c["above"], FS_SMALL,
                              col_of(c.get("role") if c.get("role") != "ink"
                                     else "annotation"), "middle"))
            if c.get("below"):
                els.append(_t(cx, y_top + row_h + FS_SMALL, c["below"],
                              FS_SMALL, col_of("annotation"), "middle"))
            els += _mark_over(cx, base - FS_DIGIT * 0.30,
                              cell_w * 0.62, FS_DIGIT * 0.80,
                              c.get("mark", "none"), color)
        y = y_top + row_h + below_h
        if ri == rule_after:
            els.append(_line(2, y + 3, grid_w - 2, y + 3, INK, 2.0))
            y += 9
    grid_bottom = y

    w = grid_w
    notes = b.get("column_notes") or []
    if notes:
        gutter = 13.0
        for n in notes:
            cx = op_w + n["column"] * cell_w + cell_w / 2
            c = col_of(n.get("role", "annotation"))
            els.append(_poly([(cx - 4, grid_bottom + gutter),
                              (cx + 4, grid_bottom + gutter),
                              (cx, grid_bottom + 3)], c, c, 0.8))
        y = grid_bottom + gutter + 4
        avail = max(grid_w, 330.0)
        for n in notes:
            c = col_of(n.get("role", "annotation"))
            lab = (labels[n["column"]] + ": ") if labels else ""
            body = lab + n["text"]
            for k, t in enumerate(textwrap.wrap(body, _wrap_width(avail, FS_SMALL))):
                els.append(_t(0, y + FS_SMALL * 0.9 + k * FS_SMALL * 1.35, t,
                              FS_SMALL, c))
                w = max(w, measure(t, FS_SMALL))
                if k == len(textwrap.wrap(body, _wrap_width(avail, FS_SMALL))) - 1:
                    y += FS_SMALL * 1.35 * (k + 1) + 4
    return Box(w, y, els)


def b_table(b) -> Box:
    rows = b["rows"]
    ncol = max(len(r) for r in rows)
    headers = b.get("headers")
    cw = 54.0
    for r in rows:
        for c in r:
            cw = max(cw, measure(c.get("text") or "", FS_TEXT) + 16)
    if headers:
        for hh in headers:
            cw = max(cw, measure(hh, FS_TINY) + 12)
    rh = FS_TEXT * 2.0
    els: list[str] = []
    y = 0.0
    if headers:
        for i, hh in enumerate(headers):
            els.append(_t(i * cw + cw / 2, FS_TINY, hh, FS_TINY,
                          ROLE_COLOR["muted"], "middle"))
        y = FS_TINY + 6
    top = y
    for r in rows:
        for ci, c in enumerate(r):
            x = ci * cw
            els.append(_rect(x, y, cw, rh, RULE, "none", 0.8))
            color = col_of(c.get("role"))
            cx, cy = x + cw / 2, y + rh * 0.68
            if c.get("text"):
                els.append(_t(cx, cy, c["text"], FS_TEXT, color, "middle"))
            els += _mark_over(cx, cy - FS_TEXT * 0.30, cw * 0.6,
                              FS_TEXT * 0.9, c.get("mark", "none"), color)
        y += rh
    return Box(ncol * cw, y - top + top, els)


def b_bar(b, bar_w) -> Box:
    parts = b["parts"]
    n = len(parts)
    pw = bar_w / n
    h = 46.0
    els: list[str] = []
    y = 0.0
    if b.get("label"):
        els.append(_t(0, FS_SMALL * 0.95, b["label"], FS_SMALL,
                      ROLE_COLOR["muted"]))
        y = FS_SMALL * 1.5
    for i, p in enumerate(parts):
        x = i * pw
        color = col_of(p.get("role"))
        fill = ROLE_COLOR["correct"] if (p.get("shaded") and
                                         p.get("role", "ink") == "ink") \
            else (color if p.get("shaded") else WHOLE)
        els.append(_rect(x, y, pw, h, INK, fill, 1.2))
        if p.get("text"):
            size = min(FS_TEXT, max(7.5, pw * 0.42))
            tb = inline(p["text"], size, INK if not p.get("shaded") else "#ffffff")
            els.append(tb.at(x + (pw - tb.w) / 2, y + (h - tb.h) / 2))
        els += _mark_over(x + pw / 2, y + h / 2, pw * 0.8, h * 0.8,
                          p.get("mark", "none"), ROLE_COLOR["error"])
    return Box(bar_w, y + h, els)


def b_number_line(b) -> Box:
    lanes = b["lanes"]
    nt = len(lanes[0]["ticks"])
    lab_w = 0.0
    for lane in lanes:
        if lane.get("label"):
            lab_w = max(lab_w, measure(lane["label"], FS_SMALL) + 12)
    span = max(340.0, (nt - 1) * 78.0)
    step = span / (nt - 1)
    arc_h = 26.0
    has_arc = bool(b.get("arcs"))
    lane_h = 62.0
    els: list[str] = []
    y = arc_h if has_arc else 0.0
    lane_y: list[float] = []
    # A label centred on the last tick reaches half its width past the axis end.
    # Measure that overhang now and hand it back in the block's width, or the
    # panel frame crops the number the whole figure is about.
    overhang = 0.0
    for lane in lanes:
        last = lane["ticks"][-1]
        if last.get("text"):
            overhang = max(overhang, measure(last["text"], FS_SMALL) / 2)
        for p in (lane.get("points") or []):
            if p.get("text") and p["at"] == nt - 1:
                overhang = max(overhang, measure(p["text"], FS_SMALL) / 2)
    for lane in lanes:
        ax = lab_w
        ay = y + 16
        lane_y.append(ay)
        els.append(_line(ax, ay, ax + span, ay, INK, 1.6))
        if lane.get("label"):
            els.append(_t(0, ay + 4, lane["label"], FS_SMALL,
                          ROLE_COLOR["muted"]))
        for i, t in enumerate(lane["ticks"]):
            tx = ax + i * step
            els.append(_line(tx, ay - 6, tx, ay + 6, INK, 1.3))
            if t.get("text"):
                els.append(_t(tx, ay + 20, t["text"], FS_SMALL, LABEL, "middle"))
        for p in (lane.get("points") or []):
            px = ax + p["at"] * step
            c = col_of(p.get("role"))
            els.append(_circle(px, ay, 5, INK, c, 1.2))
            if p.get("text"):
                els.append(_t(px, ay - 12, p["text"], FS_SMALL, c, "middle"))
        y = ay + lane_h - 16
    for a in (b.get("arcs") or []):
        li = a.get("lane", 0)
        ax = lab_w
        x1, x2 = ax + a["from"] * step, ax + a["to"] * step
        ay = lane_y[li]
        mid = (x1 + x2) / 2
        c = col_of(a.get("role", "annotation"))
        top = ay - arc_h - 4
        els.append(f'<path d="M {x1:.1f} {ay - 8:.1f} Q {mid:.1f} {top:.1f} '
                   f'{x2:.1f} {ay - 8:.1f}" fill="none" stroke="{c}" '
                   f'stroke-width="1.5"/>')
        if a.get("text"):
            els.append(_t(mid, top + 2, a["text"], FS_SMALL, c, "middle"))
    return Box(lab_w + span + overhang, y, els)


def b_base_ten(b) -> Box:
    cols = b["columns"]
    CUBE, ROD_W, ROD_H, FLAT = 13.0, 13.0, 92.0, 92.0
    gap = 5.0
    els: list[str] = []
    x = 0.0
    max_h = 0.0
    labelled = any(c.get("label") for c in cols)
    top = (FS_TINY + 8) if labelled else 0.0

    for col in cols:
        cx = x
        y = top
        colw = 0.0
        for grp in col["groups"]:
            unit, cnt = grp["unit"], grp["count"]
            marked = grp.get("marked") or 0
            role_c = col_of(grp.get("role"))
            fill = UNIT_FILL[unit] if grp.get("role", "ink") == "ink" else role_c
            gy = y
            gx = cx
            rowmax = 0.0
            for i in range(cnt):
                is_marked = i >= cnt - marked
                if unit == "cube":
                    if i and i % 5 == 0:
                        gy += CUBE + gap
                        gx = cx
                    els.append(_rect(gx, gy, CUBE, CUBE, INK, fill, 1.0))
                    if is_marked:
                        els += _mark_over(gx + CUBE / 2, gy + CUBE / 2,
                                          CUBE * 1.1, CUBE * 1.1,
                                          grp.get("mark", "strike"),
                                          ROLE_COLOR["error"])
                    gx += CUBE + gap
                    rowmax = max(rowmax, CUBE)
                elif unit == "rod":
                    els.append(_rect(gx, gy, ROD_W, ROD_H, INK, WHOLE, 1.0))
                    seg = ROD_H / 10
                    filled = 10
                    if grp.get("partial") is not None and i == cnt - 1:
                        filled = grp["partial"]
                    for s in range(10):
                        els.append(_rect(gx, gy + s * seg, ROD_W, seg, INK,
                                         fill if s < filled else WHOLE, 0.6))
                    if is_marked:
                        els += _mark_over(gx + ROD_W / 2, gy + ROD_H / 2,
                                          ROD_W * 1.3, ROD_H,
                                          grp.get("mark", "strike"),
                                          ROLE_COLOR["error"])
                    gx += ROD_W + gap
                    rowmax = max(rowmax, ROD_H)
                else:  # flat
                    els.append(_rect(gx, gy, FLAT, FLAT, INK, fill, 1.0))
                    for s in range(1, 10):
                        o = s * FLAT / 10
                        els.append(_line(gx, gy + o, gx + FLAT, gy + o, INK, 0.4))
                        els.append(_line(gx + o, gy, gx + o, gy + FLAT, INK, 0.4))
                    if is_marked:
                        els += _mark_over(gx + FLAT / 2, gy + FLAT / 2,
                                          FLAT, FLAT, grp.get("mark", "strike"),
                                          ROLE_COLOR["error"])
                    gx += FLAT + gap
                    rowmax = max(rowmax, FLAT)
            colw = max(colw, gx - cx)
            y = gy + rowmax + 10
        if col.get("label"):
            colw = max(colw, measure(col["label"], FS_TINY) + 10)
            els.append(_t(cx + colw / 2, FS_TINY, col["label"], FS_TINY,
                          ROLE_COLOR["muted"], "middle"))
        max_h = max(max_h, y)
        x = cx + colw + 26
    if labelled:
        els.append(_line(0, FS_TINY + 4, max(x - 26, 0), FS_TINY + 4, RULE, 0.8))
    return Box(max(x - 26, 0), max_h, els)


UNIT_POLY = {
    "trapezoid": [(0.22, 0), (0.78, 0), (1, 1), (0, 1)],
    "parallelogram": [(0.26, 0), (1, 0), (0.74, 1), (0, 1)],
    "rectangle": [(0, 0.12), (1, 0.12), (1, 0.88), (0, 0.88)],
    "square": [(0.1, 0), (0.9, 0), (0.9, 1), (0.1, 1)],
    "triangle": [(0.5, 0), (1, 1), (0, 1)],
    "right_triangle": [(0, 0), (0, 1), (1, 1)],
    "pentagon": [(0.5, 0), (1, 0.38), (0.81, 1), (0.19, 1), (0, 0.38)],
    "hexagon": [(0.25, 0), (0.75, 0), (1, 0.5), (0.75, 1), (0.25, 1), (0, 0.5)],
}
POLYOMINO = {
    "l_tromino": [(0, 0), (0, 1), (1, 1)],
    "l_tetromino": [(0, 0), (0, 1), (0, 2), (1, 2)],
    "t_tetromino": [(0, 0), (1, 0), (2, 0), (1, 1)],
    "s_tetromino": [(1, 0), (2, 0), (0, 1), (1, 1)],
    "square_tetromino": [(0, 0), (1, 0), (0, 1), (1, 1)],
}


def b_shape(b) -> Box:
    figs = b["figures"]
    CELL = 26.0
    SW, SH = 116.0, 96.0
    gap = 26.0
    els: list[str] = []
    x = 0.0
    tallest = 0.0
    for f in figs:
        kind, role = f["kind"], f.get("role", "ink")
        c = col_of(role)
        rot = f.get("rotation", 0)
        sub: list[str] = []
        if kind in POLYOMINO:
            cells = POLYOMINO[kind]
            cw = (max(cx for cx, _ in cells) + 1)
            ch = (max(cy for _, cy in cells) + 1)
            w, h = cw * CELL, ch * CELL
            if b.get("grid") == "dots":
                for gx in range(int(cw) + 1):
                    for gy in range(int(ch) + 1):
                        sub.append(_circle(gx * CELL, gy * CELL, 1.6,
                                           ROLE_COLOR["muted"],
                                           ROLE_COLOR["muted"], 0))
            for (ux, uy) in cells:
                sub.append(_rect(ux * CELL, uy * CELL, CELL, CELL, c,
                                 NEUTRAL if role == "ink" else c, 1.4))
        elif kind == "circle":
            w = h = 84.0
            sub.append(_circle(w / 2, h / 2, w / 2 - 2, c, "none", 1.6))
        else:
            w, h = SW, SH
            pts = [(px * w, py * h) for px, py in UNIT_POLY[kind]]
            sub.append(_poly(pts, c, "none", 1.6))
        body = "".join(sub)
        # A quarter turn swaps the extent, so the slot reserved for this figure
        # has to swap too; reserving the unrotated box is how a rotated shape
        # ends up sitting on its neighbour.
        rw, rh = (h, w) if rot in (90, 270) else (w, h)
        if rot:
            body = (f'<g transform="rotate({rot},{rw / 2:.1f},{rh / 2:.1f})">'
                    f'<g transform="translate({(rw - w) / 2:.1f},'
                    f'{(rh - h) / 2:.1f})">{body}</g></g>')
        els.append(f'<g transform="translate({x:.1f},0)">{body}</g>')
        fh = rh
        if f.get("label"):
            els.append(_t(x + rw / 2, rh + FS_SMALL * 1.5, f["label"], FS_SMALL,
                          c, "middle"))
            fh = rh + FS_SMALL * 2.0
        tallest = max(tallest, fh)
        x += rw + gap
    return Box(max(x - gap, 0), tallest, els)


# --- panels and canvas -----------------------------------------------------

PANEL_ACCENT = {"student": ROLE_COLOR["error"], "correct": ROLE_COLOR["correct"],
                "given": ROLE_COLOR["muted"], "contrast": ROLE_COLOR["annotation"]}
PANEL_WORD = {"student": "what the student wrote", "correct": "the exchange performed",
              "given": "given", "contrast": "for contrast"}


def build_panel(panel) -> Box:
    blocks = panel["blocks"]
    # First measure everything whose width does not depend on the panel.
    sized: list[tuple[str, object]] = []
    natural = 0.0
    for blk in blocks:
        t = blk["type"]
        if t == "column_calc":
            bx = b_column_calc(blk)
        elif t == "expr_lines":
            bx = b_expr_lines(blk)
        elif t == "number_line":
            bx = b_number_line(blk)
        elif t == "base_ten":
            bx = b_base_ten(blk)
        elif t == "table":
            bx = b_table(blk)
        elif t == "shape":
            bx = b_shape(blk)
        else:
            bx = None            # bar and note need the panel width first
        if bx is not None:
            natural = max(natural, bx.w)
        sized.append((t, bx))

    content_w = min(MAX_PANEL_W, max(MIN_CONTENT_W, natural))
    els: list[str] = []
    y = 0.0
    title = panel.get("title") or PANEL_WORD.get(panel.get("role", "given"), "")
    accent = PANEL_ACCENT.get(panel.get("role", "given"), ROLE_COLOR["muted"])
    if title:
        els.append(_t(0, FS_PANEL * 0.95, title, FS_PANEL, accent, "start", True))
        y = FS_PANEL * 1.75

    width = content_w
    for (t, bx), blk in zip(sized, blocks):
        if bx is None:
            bx = (b_bar(blk, content_w) if t == "bar"
                  else b_note(blk, content_w))
        els.append(bx.at(0, y))
        width = max(width, bx.w)
        y += bx.h + BLOCK_GAP
    y = max(y - BLOCK_GAP, 0)

    inner = Box(width, y, els)
    # Frame the panel so a wrong-vs-right pair reads as two things, not one.
    framed = [
        _rect(0, 0, width + 2 * PANEL_PAD, y + 2 * PANEL_PAD, RULE, PAPER, 0.9, rx=4),
        _rect(0, 0, 3.5, y + 2 * PANEL_PAD, accent, accent, 0, rx=0),
        inner.at(PANEL_PAD, PANEL_PAD),
    ]
    return Box(width + 2 * PANEL_PAD, y + 2 * PANEL_PAD, framed)


def typeset(scene: dict) -> str:
    """Validated scene in, complete SVG document out."""
    validate(scene)
    panels = [build_panel(p) for p in scene["panels"]]

    title_h = FS_TITLE * 1.7
    rows: list[list[Box]] = []
    row: list[Box] = []
    row_w = 0.0
    limit = 1180.0
    for pb in panels:
        add = pb.w + (PANEL_GAP if row else 0)
        if row and row_w + add > limit:
            rows.append(row)
            row, row_w = [pb], pb.w
        else:
            row.append(pb)
            row_w += add
    if row:
        rows.append(row)

    body_w = max(sum(p.w for p in r) + PANEL_GAP * (len(r) - 1) for r in rows)
    els: list[str] = []
    y = MARGIN
    els.append(_t(MARGIN, y + FS_TITLE * 0.9, scene["title"], FS_TITLE,
                  LABEL, "start", True))
    y += title_h

    for r in rows:
        x = MARGIN
        rh = max(p.h for p in r)
        for pb in r:
            els.append(pb.at(x, y))
            x += pb.w + PANEL_GAP
        y += rh + PANEL_GAP
    y -= PANEL_GAP

    if scene.get("caption"):
        cap = b_note({"text": scene["caption"], "role": "muted"}, body_w)
        y += 14
        els.append(cap.at(MARGIN, y))
        y += cap.h

    W = body_w + 2 * MARGIN
    H = y + MARGIN
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{W:.0f}" '
        f'height="{H:.0f}" viewBox="0 0 {W:.0f} {H:.0f}">'
        f'<rect x="0" y="0" width="{W:.0f}" height="{H:.0f}" fill="{PAPER}"/>'
        + "".join(els) + "</svg>"
    )
