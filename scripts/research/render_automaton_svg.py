#!/usr/bin/env python3
"""Render deterministic state-diagram SVGs from transition-table facts."""
from __future__ import annotations

import argparse
import html
import math
import re
import sys
from collections import Counter, defaultdict, deque
from pathlib import Path

from build_machine_typology import (
    ROOT,
    Machine,
    Structure,
    parse_transition_tables,
    structure,
)


OUTPUT_DIR = ROOT / "docs/research/assets/automata"
HOST_CSS = ROOT / "hermes/web/render/host.css"
RADIUS = 48.0
COLS = 6
X_GAP = 230.0
Y_GAP = 160.0
MARGIN = 112.0


def palette(path: Path = HOST_CSS) -> dict[str, str]:
    """Read the CSS fallback palette used by the render host."""
    text = path.read_text(encoding="utf-8")
    found: dict[str, str] = {}
    for name, color in re.findall(r"var\(--([a-z0-9-]+),\s*(#[0-9a-fA-F]{6})\)", text):
        found.setdefault(name, color.lower())
    required = ("paper", "ink", "muted", "gold", "surface")
    missing = [name for name in required if name not in found]
    if missing:
        raise ValueError(f"host.css lacks required palette fallbacks: {missing}")
    return found


def graph_distances(machine: Machine) -> dict[str, int]:
    adjacency: dict[str, set[str]] = defaultdict(set)
    for before, _action, after in machine.unique_edges:
        adjacency[before].add(after)
    distances = {machine.start: 0}
    queue = deque([machine.start])
    while queue:
        current = queue.popleft()
        for nxt in sorted(adjacency.get(current, ())):
            if nxt not in distances:
                distances[nxt] = distances[current] + 1
                queue.append(nxt)
    distance = max(distances.values(), default=0) + 1
    for state in machine.states:
        if state not in distances:
            distances[state] = distance
            distance += 1
    return distances


def positions(row: Structure) -> tuple[dict[str, tuple[float, float]], float, float]:
    machine = row.machine
    placed: dict[str, tuple[float, float]] = {}
    if row.structural_class == "linear_trace":
        for index, state in enumerate(machine.states):
            band, col = divmod(index, COLS)
            placed[state] = (MARGIN + col * X_GAP, MARGIN + band * Y_GAP)
        bands = max(1, math.ceil(len(machine.states) / COLS))
        return placed, 2 * MARGIN + (min(COLS, len(machine.states)) - 1) * X_GAP, 2 * MARGIN + (bands - 1) * Y_GAP

    distances = graph_distances(machine)
    layers: dict[int, list[str]] = defaultdict(list)
    for state in machine.states:
        layers[distances[state]].append(state)
    band_offsets: dict[int, float] = {}
    running_y = MARGIN
    for band in range(max(layers, default=0) // COLS + 1):
        band_depths = [depth for depth in layers if depth // COLS == band]
        max_fan = max((len(layers[depth]) for depth in band_depths), default=1)
        band_offsets[band] = running_y
        running_y += max(1, max_fan) * Y_GAP + 100
    for depth in sorted(layers):
        band, col = divmod(depth, COLS)
        states = sorted(layers[depth], key=machine.states.index)
        for index, state in enumerate(states):
            placed[state] = (MARGIN + col * X_GAP, band_offsets[band] + index * Y_GAP)
    width = 2 * MARGIN + (min(COLS, max(layers, default=0) + 1) - 1) * X_GAP
    return placed, width, running_y - 40


def shortened_line(a: tuple[float, float], b: tuple[float, float]) -> tuple[float, float, float, float]:
    x1, y1 = a
    x2, y2 = b
    dx, dy = x2 - x1, y2 - y1
    distance = math.hypot(dx, dy) or 1.0
    ux, uy = dx / distance, dy / distance
    return x1 + ux * RADIUS, y1 + uy * RADIUS, x2 - ux * (RADIUS + 8), y2 - uy * (RADIUS + 8)


def edge_path(
    before: str,
    after: str,
    placed: dict[str, tuple[float, float]],
    loop: bool,
) -> tuple[str, float, float]:
    x1, y1 = placed[before]
    x2, y2 = placed[after]
    if before == after:
        path = (
            f"M {x1 - 23:.1f} {y1 - 42:.1f} "
            f"C {x1 - 72:.1f} {y1 - 104:.1f}, {x1 + 72:.1f} {y1 - 104:.1f}, "
            f"{x1 + 23:.1f} {y1 - 42:.1f}"
        )
        return path, x1, y1 - 58
    sx, sy, tx, ty = shortened_line((x1, y1), (x2, y2))
    if loop:
        lift = max(75.0, abs(x2 - x1) * 0.22)
        path = f"M {sx:.1f} {sy:.1f} Q {(sx + tx) / 2:.1f} {min(sy, ty) - lift:.1f} {tx:.1f} {ty:.1f}"
        return path, (sx + tx) / 2, min(sy, ty) - 12
    if x2 < x1 and y2 > y1:
        bend = max(x1, x2) + 90
        path = f"M {sx:.1f} {sy:.1f} C {bend:.1f} {sy:.1f}, {bend:.1f} {ty:.1f}, {tx:.1f} {ty:.1f}"
        return path, (sx + tx) / 2, (sy + ty) / 2 - 22
    path = f"M {sx:.1f} {sy:.1f} L {tx:.1f} {ty:.1f}"
    dx, dy = tx - sx, ty - sy
    distance = math.hypot(dx, dy) or 1.0
    normal_x, normal_y = -dy / distance, dx / distance
    if normal_y > 0:
        normal_x, normal_y = -normal_x, -normal_y
    label_offset = 20.0
    return (
        path,
        (sx + tx) / 2 + normal_x * label_offset,
        (sy + ty) / 2 + normal_y * label_offset,
    )


def text_size(
    atom: str,
    maximum: float = 12.0,
    target_width: float = 84.0,
    minimum: float = 6.0,
) -> float:
    return max(minimum, min(maximum, target_width / (max(1, len(atom)) * 0.62)))


def wrap_atom(atom: str, limit: int = 20) -> list[str]:
    """Wrap a full atom at underscores without dropping any characters."""
    if len(atom) <= limit:
        return [atom]
    pieces = re.findall(r"[^_]+_?", atom)
    lines: list[str] = []
    current = ""
    for piece in pieces:
        candidate = f"{current}{piece}"
        if current and len(candidate) > limit:
            lines.append(current)
            current = piece
        else:
            current = candidate
        while len(current) > limit:
            lines.append(current[:limit])
            current = current[limit:]
    if current:
        lines.append(current)
    return lines


def edge_label(atom: str, x: float, y: float, color: str, background: str) -> str:
    lines = wrap_atom(atom)
    size = text_size(max(lines, key=len), 9.5, 126.0, minimum=9.0)
    first_y = y - (len(lines) - 1) * (size + 1.5)
    tspans = "".join(
        f'<tspan x="{x:.1f}" y="{first_y + index * (size + 1.5):.1f}">{html.escape(line)}</tspan>'
        for index, line in enumerate(lines)
    )
    return (
        f'  <text text-anchor="middle" font-family="ui-monospace, Menlo, Consolas, monospace" '
        f'font-size="{size:.1f}" fill="{color}" stroke="{background}" '
        f'stroke-width="5" stroke-linejoin="round" paint-order="stroke fill">{tspans}</text>'
    )


def render_svg(row: Structure, colors: dict[str, str] | None = None) -> str:
    colors = colors or palette()
    machine = row.machine
    placed, width, height = positions(row)
    loops = set(row.loop_edges)
    grouped: dict[tuple[str, str, str], set[str]] = defaultdict(set)
    for edge in machine.transitions:
        grouped[(edge.before, edge.action, edge.after)].add(edge.provenance_kind)

    out = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        (
            f'<svg xmlns="http://www.w3.org/2000/svg" width="{width:.0f}" height="{height:.0f}" '
            f'viewBox="0 0 {width:.0f} {height:.0f}" role="img" '
            f'aria-labelledby="title desc">'
        ),
        f"  <title id=\"title\">{html.escape(machine.family)} / {html.escape(machine.kind)}</title>",
        (
            '  <desc id="desc">Solid dark edges have static provenance only; '
            'dashed gold edges have observed provenance only; solid gold edges '
            'have both static and observed provenance.</desc>'
        ),
        "  <defs>",
        (
            f'    <marker id="arrow-static" viewBox="0 0 10 10" refX="9" refY="5" '
            f'markerWidth="7" markerHeight="7" orient="auto-start-reverse">'
            f'<path d="M 0 0 L 10 5 L 0 10 z" fill="{colors["ink"]}"/></marker>'
        ),
        (
            f'    <marker id="arrow-observed" viewBox="0 0 10 10" refX="9" refY="5" '
            f'markerWidth="7" markerHeight="7" orient="auto-start-reverse">'
            f'<path d="M 0 0 L 10 5 L 0 10 z" fill="{colors["gold"]}"/></marker>'
        ),
        (
            f'    <marker id="arrow-combined" viewBox="0 0 10 10" refX="9" refY="5" '
            f'markerWidth="7" markerHeight="7" orient="auto-start-reverse">'
            f'<path d="M 0 0 L 10 5 L 0 10 z" fill="{colors["gold"]}"/></marker>'
        ),
        "  </defs>",
        f'  <rect width="100%" height="100%" fill="{colors["paper"]}"/>',
    ]

    for before, action, after in sorted(grouped):
        path, label_x, label_y = edge_path(before, after, placed, (before, action, after) in loops)
        sources = grouped[(before, action, after)]
        if sources == {"static"}:
            edge_class = "edge-static"
            stroke = colors["ink"]
            dash = ""
            marker = "arrow-static"
        elif sources == {"observed"}:
            edge_class = "edge-observed"
            stroke = colors["gold"]
            dash = ' stroke-dasharray="8 6"'
            marker = "arrow-observed"
        else:
            edge_class = "edge-static-observed"
            stroke = colors["gold"]
            dash = ""
            marker = "arrow-combined"
        out.append(
            f'  <path class="{edge_class}" d="{path}" fill="none" stroke="{stroke}" '
            f'stroke-width="2.2"{dash} marker-end="url(#{marker})"/>'
        )
        out.append(edge_label(action, label_x, label_y, colors["muted"], colors["paper"]))

    start_x, start_y = placed[machine.start]
    out.append(
        f'  <path d="M {start_x - 96:.1f} {start_y:.1f} L {start_x - RADIUS - 8:.1f} {start_y:.1f}" '
        f'fill="none" stroke="{colors["gold"]}" stroke-width="2.5" marker-end="url(#arrow-observed)"/>'
    )
    for state in machine.states:
        x, y = placed[state]
        out.append(
            f'  <circle cx="{x:.1f}" cy="{y:.1f}" r="{RADIUS:.1f}" fill="{colors["surface"]}" '
            f'stroke="{colors["ink"]}" stroke-width="2.2"/>'
        )
        if state in machine.accepting:
            out.append(
                f'  <circle cx="{x:.1f}" cy="{y:.1f}" r="{RADIUS - 6:.1f}" fill="none" '
                f'stroke="{colors["ink"]}" stroke-width="1.6"/>'
            )
        out.append(
            f'  <text x="{x:.1f}" y="{y + 4:.1f}" text-anchor="middle" '
            f'font-family="ui-monospace, Menlo, Consolas, monospace" font-size="{text_size(state):.1f}" '
            f'fill="{colors["ink"]}">{html.escape(state)}</text>'
        )
    out.append("</svg>")
    return "\n".join(out) + "\n"


def render_all() -> dict[Path, str]:
    colors = palette()
    return {
        Path(machine.family) / f"{machine.kind}.svg": render_svg(structure(machine), colors)
        for machine in parse_transition_tables()
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, default=OUTPUT_DIR)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    rendered = render_all()
    failures = []
    for relative, content in rendered.items():
        target = args.output_dir / relative
        if args.check:
            if not target.exists() or target.read_text(encoding="utf-8") != content:
                failures.append(str(target))
        else:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(content, encoding="utf-8")
    if args.check:
        existing = {path.relative_to(args.output_dir) for path in args.output_dir.glob("*/*.svg")} if args.output_dir.exists() else set()
        failures.extend(str(args.output_dir / path) for path in sorted(existing - set(rendered)))
        if failures:
            for failure in failures:
                print(f"stale or unexpected SVG: {failure}", file=sys.stderr)
            return 1
    counts = Counter(path.parts[0] for path in rendered)
    for family in sorted(counts):
        print(f"{family}: {counts[family]} SVGs")
    print(f"automaton SVGs: {len(rendered)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
