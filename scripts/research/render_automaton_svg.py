#!/usr/bin/env python3
"""Render deterministic radial state-diagram SVGs from transition-table facts."""
from __future__ import annotations

import argparse
import html
import math
import re
import sys
from collections import Counter, defaultdict
from functools import lru_cache
from pathlib import Path

from build_machine_typology import ROOT, Machine, Structure, parse_transition_tables, structure


OUTPUT_DIR = ROOT / "docs/research/assets/automata"
HOST_CSS = ROOT / "hermes/web/render/host.css"
ACTION_MAP = ROOT / "knowledge/strategies/action_vocabulary_map.pl"
ACTION_GRAMMAR = ROOT / "knowledge/strategies/action_grammar.pl"
NODE_RADIUS = 18.0
EDGE_BOW = 34.0
ATOM = r"[a-z][a-z0-9_]*"
MAP_RE = re.compile(rf"^action_maps\(({ATOM}), ({ATOM}), ({ATOM}), ({ATOM}),", re.MULTILINE)
REGISTER_RE = re.compile(
    rf"^action_register\(({ATOM}), genre\(computational\), register\(({ATOM})\), stance\(({ATOM})\)\)\.",
    re.MULTILINE,
)
GRAMMAR_RE = re.compile(
    rf"machine_grammar\(computational, ({ATOM}), ({ATOM}), arc\([^)]*\),\s*"
    r"phrases\(\[[^\]]*\]\),\s*stances\(\[([^\]]*)\]\)\)\.",
    re.MULTILINE,
)


def palette(path: Path = HOST_CSS) -> dict[str, str]:
    """Read the CSS fallback palette used by the render host."""
    text = path.read_text(encoding="utf-8")
    found: dict[str, str] = {}
    for name, color in re.findall(r"var\(--([a-z0-9-]+),\s*(#[0-9a-fA-F]{6})\)", text):
        found.setdefault(name, color.lower())
    required = ("paper", "ink", "muted", "gold", "surface", "rust")
    missing = [name for name in required if name not in found]
    if missing:
        raise ValueError(f"host.css lacks required palette fallbacks: {missing}")
    return found


def action_semantics(path: Path = ACTION_MAP) -> tuple[dict[tuple[str, str, str], str], dict[str, str]]:
    """Return the authored local-to-canonical map and each canonical stance."""
    text = path.read_text(encoding="utf-8")
    canonical = {(family, kind, local): mapped for family, kind, local, mapped in MAP_RE.findall(text)}
    stances = {action: stance for action, _register, stance in REGISTER_RE.findall(text)}
    if not canonical or not stances:
        raise ValueError("action_vocabulary_map.pl lacks action_maps/7 or computational action_register/4 rows")
    return canonical, stances


@lru_cache(maxsize=1)
def grammar_stances(path: Path = ACTION_GRAMMAR) -> dict[tuple[str, str], tuple[str, ...]]:
    """Read the machine stance words used to audit edge coloring."""
    rows = {
        (family, kind): tuple(part.strip() for part in body.split(",") if part.strip())
        for family, kind, body in GRAMMAR_RE.findall(path.read_text(encoding="utf-8"))
    }
    if not rows:
        raise ValueError("action_grammar.pl lacks computational machine_grammar/6 rows")
    return rows


def validate_grammar_stances(
    machine: Machine,
    canonical_map: dict[tuple[str, str, str], str],
    stance_map: dict[str, str],
) -> None:
    """Match action_grammar's deterministic word before drawing its stances."""
    routes: dict[str, list[tuple[str, str]]] = defaultdict(list)
    for source, local, target in machine.unique_edges:
        canonical = canonical_map.get((machine.family, machine.kind, local), local)
        if canonical not in [action for action, _target in routes[source]]:
            routes[source].append((canonical, target))
    observed: list[str] = []
    state, seen = machine.start, {machine.start}
    while len(routes.get(state, [])) == 1:
        action, target = routes[state][0]
        observed.append(stance_map.get(action, "neutral"))
        if target in seen:
            break
        seen.add(target)
        state = target
    expected = grammar_stances().get((machine.family, machine.kind))
    if expected is None or tuple(observed) != expected:
        raise ValueError(
            f"action-grammar stance drift for {machine.family}/{machine.kind}: "
            f"renderer {tuple(observed)!r}, grammar {expected!r}"
        )


def wrap_atom(atom: str, limit: int = 22) -> list[str]:
    """Wrap a full atom at underscores without dropping any characters."""
    if len(atom) <= limit:
        return [atom]
    pieces = re.findall(r"[^_]+_?", atom)
    lines: list[str] = []
    current = ""
    for piece in pieces:
        candidate = current + piece
        if current and len(candidate) > limit:
            lines.append(current.rstrip("_"))
            current = piece.lstrip("_")
        else:
            current = candidate
        while len(current) > limit:
            lines.append(current[:limit])
            current = current[limit:]
    if current:
        lines.append(current.rstrip("_"))
    return lines


def geometry(machine: Machine) -> tuple[dict[str, tuple[float, float, float]], float, float, float, float]:
    """Place states evenly on a circle, starting at -pi/2 as fractal.html does."""
    count = max(1, len(machine.states))
    ring = max(108.0, min(300.0, 16.0 * count))
    # Long authored state atoms stay outside the ring without being clipped.
    label_reach = 184.0
    margin = 28.0
    size = 2 * (ring + label_reach + margin)
    cx = cy = size / 2
    placed = {}
    for index, state in enumerate(machine.states):
        angle = -math.pi / 2 + index / count * math.tau
        placed[state] = (cx + math.cos(angle) * ring, cy + math.sin(angle) * ring, angle)
    return placed, size, size, cx, cy


def point_toward(a: tuple[float, float], b: tuple[float, float], distance: float) -> tuple[float, float]:
    dx, dy = b[0] - a[0], b[1] - a[1]
    length = math.hypot(dx, dy) or 1.0
    return a[0] + dx / length * distance, a[1] + dy / length * distance


def quadratic_point(a: tuple[float, float], c: tuple[float, float], b: tuple[float, float], t: float) -> tuple[float, float]:
    u = 1 - t
    return (
        u * u * a[0] + 2 * u * t * c[0] + t * t * b[0],
        u * u * a[1] + 2 * u * t * c[1] + t * t * b[1],
    )


def edge_path(
    machine: Machine,
    before: str,
    after: str,
    placed: dict[str, tuple[float, float, float]],
    cx: float,
    cy: float,
    lane: float,
) -> tuple[str, float, float]:
    """Bow adjacent edges around the ring and let skips/back-edges cross it."""
    x1, y1, a1 = placed[before]
    x2, y2, a2 = placed[after]
    if before == after:
        outward = (math.cos(a1), math.sin(a1))
        tangent = (-outward[1], outward[0])
        p1 = (x1 + tangent[0] * 9 + outward[0] * NODE_RADIUS,
              y1 + tangent[1] * 9 + outward[1] * NODE_RADIUS)
        p2 = (x1 - tangent[0] * 9 + outward[0] * NODE_RADIUS,
              y1 - tangent[1] * 9 + outward[1] * NODE_RADIUS)
        c1 = (p1[0] + tangent[0] * 34 + outward[0] * 34,
              p1[1] + tangent[1] * 34 + outward[1] * 34)
        c2 = (p2[0] - tangent[0] * 34 + outward[0] * 34,
              p2[1] - tangent[1] * 34 + outward[1] * 34)
        label = (x1 + outward[0] * 72, y1 + outward[1] * 72)
        return (
            f"M {p1[0]:.1f} {p1[1]:.1f} C {c1[0]:.1f} {c1[1]:.1f}, "
            f"{c2[0]:.1f} {c2[1]:.1f}, {p2[0]:.1f} {p2[1]:.1f}",
            label[0], label[1],
        )

    start = point_toward((x1, y1), (x2, y2), NODE_RADIUS)
    end = point_toward((x2, y2), (x1, y1), NODE_RADIUS + 7)
    indices = {state: index for index, state in enumerate(machine.states)}
    i, j, n = indices[before], indices[after], len(machine.states)
    adjacent = (j - i) % n == 1 or (i - j) % n == 1
    if adjacent:
        # The angle bisector outside the ring makes consecutive edges follow its contour.
        ux, uy = x1 - cx, y1 - cy
        vx, vy = x2 - cx, y2 - cy
        mx, my = ux + vx, uy + vy
        length = math.hypot(mx, my) or 1.0
        ring = math.hypot(ux, uy)
        tangent_x, tangent_y = -my / length, mx / length
        control = (
            cx + mx / length * (ring + 28 + abs(lane) * 9) + tangent_x * lane * 26,
            cy + my / length * (ring + 28 + abs(lane) * 9) + tangent_y * lane * 26,
        )
    else:
        # Fractal's fixed perpendicular offset keeps the chord readable without hiding skips.
        dx, dy = end[0] - start[0], end[1] - start[1]
        length = math.hypot(dx, dy) or 1.0
        side = -1.0 if ((i + j) % 2) else 1.0
        offset = EDGE_BOW * side + lane * 18
        control = ((start[0] + end[0]) / 2 - dy / length * offset,
                   (start[1] + end[1]) / 2 + dx / length * offset)
    label_x, label_y = quadratic_point(start, control, end, 0.5)
    dx, dy = end[0] - start[0], end[1] - start[1]
    length = math.hypot(dx, dy) or 1.0
    label_x += -dy / length * (14 + lane * 48)
    label_y += dx / length * (14 + lane * 48)
    return (
        f"M {start[0]:.1f} {start[1]:.1f} Q {control[0]:.1f} {control[1]:.1f} {end[0]:.1f} {end[1]:.1f}",
        label_x, label_y,
    )


def edge_label(atom: str, canonical: str, x: float, y: float, color: str, background: str) -> str:
    lines = wrap_atom(atom, 20)
    size = 9.0
    first_y = y - (len(lines) - 1) * 5.2
    tspans = "".join(
        f'<tspan x="{x:.1f}" y="{first_y + index * 10.4:.1f}">{html.escape(line)}</tspan>'
        for index, line in enumerate(lines)
    )
    return (
        '  <text text-anchor="middle" font-family="ui-monospace, Menlo, Consolas, monospace" '
        f'font-size="{size:.1f}" fill="{color}" stroke="{background}" stroke-width="4" '
        f'stroke-linejoin="round" paint-order="stroke fill"><title>Canonical action: {html.escape(canonical)}</title>'
        f'{tspans}</text>'
    )


def state_label(state: str, index: int, x: float, y: float, angle: float, cx: float, cy: float, color: str) -> list[str]:
    radial = 58.0
    lx, ly = x + math.cos(angle) * radial, y + math.sin(angle) * radial
    cosine = math.cos(angle)
    anchor = "start" if cosine > 0.32 else "end" if cosine < -0.32 else "middle"
    lines = wrap_atom(state, 22)
    if anchor == "start":
        lx += 3
    elif anchor == "end":
        lx -= 3
    first_y = ly - (len(lines) - 1) * 5.5
    tspans = "".join(
        f'<tspan x="{lx:.1f}" y="{first_y + i * 11:.1f}">{html.escape(line)}</tspan>'
        for i, line in enumerate(lines)
    )
    return [
        f'  <text text-anchor="{anchor}" font-family="ui-monospace, Menlo, Consolas, monospace" '
        f'font-size="9.5" fill="{color}">{tspans}</text>',
        f'  <text x="{x:.1f}" y="{y + 3.5:.1f}" text-anchor="middle" '
        f'font-family="ui-monospace, Menlo, Consolas, monospace" font-size="9" fill="{color}">q{index}</text>',
    ]


def render_svg(
    row: Structure,
    colors: dict[str, str] | None = None,
    semantics: tuple[dict[tuple[str, str, str], str], dict[str, str]] | None = None,
) -> str:
    colors = colors or palette()
    canonical_map, stance_map = semantics or action_semantics()
    machine = row.machine
    validate_grammar_stances(machine, canonical_map, stance_map)
    placed, width, height, cx, cy = geometry(machine)
    grouped: dict[tuple[str, str, str], set[str]] = defaultdict(set)
    pair_actions: dict[tuple[str, str], list[str]] = defaultdict(list)
    for edge in machine.transitions:
        grouped[(edge.before, edge.action, edge.after)].add(edge.provenance_kind)
    for before, action, after in sorted(grouped):
        pair_actions[(before, after)].append(action)

    stance_colors = {
        "conserving": colors["ink"],
        "deforming": colors["rust"],
        "neutral": colors["muted"],
    }
    out = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width:.0f}" height="{height:.0f}" '
        f'viewBox="0 0 {width:.0f} {height:.0f}" role="img" aria-labelledby="title desc">',
        f'  <title id="title">{html.escape(machine.family)} / {html.escape(machine.kind)}</title>',
        '  <desc id="desc">States are arranged radially. Edge color records the authored stance: '
        'dark for conserving, rust for deforming, and muted for neutral. Dashed edges have observed-only provenance.</desc>',
        "  <defs>",
    ]
    for stance, color in stance_colors.items():
        out.append(
            f'    <marker id="arrow-{stance}" viewBox="0 0 10 10" refX="9" refY="5" '
            f'markerWidth="6" markerHeight="6" orient="auto-start-reverse">'
            f'<path d="M 0 0 L 10 5 L 0 10 z" fill="{color}"/></marker>'
        )
    out.append(
        f'    <marker id="arrow-start" viewBox="0 0 10 10" refX="9" refY="5" '
        f'markerWidth="6" markerHeight="6" orient="auto-start-reverse">'
        f'<path d="M 0 0 L 10 5 L 0 10 z" fill="{colors["gold"]}"/></marker>'
    )
    out.extend(["  </defs>", f'  <rect width="100%" height="100%" fill="{colors["paper"]}"/>'])

    for before, action, after in sorted(grouped):
        actions = pair_actions[(before, after)]
        lane = actions.index(action) - (len(actions) - 1) / 2
        path, label_x, label_y = edge_path(machine, before, after, placed, cx, cy, lane)
        canonical = canonical_map.get((machine.family, machine.kind, action), action)
        stance = stance_map.get(canonical, "neutral")
        stroke = stance_colors[stance]
        sources = grouped[(before, action, after)]
        dash = ' stroke-dasharray="7 5"' if sources == {"observed"} else ""
        out.append(
            f'  <path class="edge-{stance}" d="{path}" fill="none" stroke="{stroke}" '
            f'stroke-width="2.5" stroke-linecap="round"{dash} marker-end="url(#arrow-{stance})"><title>'
            f'{html.escape(action)} → {html.escape(canonical)} ({stance})</title></path>'
        )
        out.append(edge_label(action, canonical, label_x, label_y, stroke, colors["paper"]))

    start_x, start_y, start_angle = placed[machine.start]
    arrow_start = (start_x + math.cos(start_angle) * 64, start_y + math.sin(start_angle) * 64)
    arrow_end = (start_x + math.cos(start_angle) * (NODE_RADIUS + 7),
                 start_y + math.sin(start_angle) * (NODE_RADIUS + 7))
    out.append(
        f'  <path d="M {arrow_start[0]:.1f} {arrow_start[1]:.1f} L {arrow_end[0]:.1f} {arrow_end[1]:.1f}" '
        f'fill="none" stroke="{colors["gold"]}" stroke-width="2.6" marker-end="url(#arrow-start)"/>'
    )
    for index, state in enumerate(machine.states):
        x, y, angle = placed[state]
        stroke = colors["gold"] if state == machine.start else colors["ink"]
        out.append(
            f'  <circle cx="{x:.1f}" cy="{y:.1f}" r="{NODE_RADIUS:.1f}" fill="{colors["surface"]}" '
            f'stroke="{stroke}" stroke-width="{3 if state == machine.start else 2}"/>'
        )
        if state in machine.accepting:
            out.append(
                f'  <circle cx="{x:.1f}" cy="{y:.1f}" r="{NODE_RADIUS - 4.5:.1f}" fill="none" '
                f'stroke="{colors["ink"]}" stroke-width="1.4"/>'
            )
        out.extend(state_label(state, index, x, y, angle, cx, cy, colors["ink"]))
    out.append("</svg>")
    return "\n".join(out) + "\n"


def render_all() -> dict[Path, str]:
    colors = palette()
    semantics = action_semantics()
    return {
        Path(machine.family) / f"{machine.kind}.svg": render_svg(structure(machine), colors, semantics)
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
        existing = (
            {path.relative_to(args.output_dir) for path in args.output_dir.glob("*/*.svg")
             if not path.name.endswith("-scene.svg") and path.name != "_composite.svg"}
            if args.output_dir.exists() else set()
        )
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
