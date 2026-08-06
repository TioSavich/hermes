#!/usr/bin/env python3
"""Build deterministic domain-scene and family-composite SVGs for the compendium."""
from __future__ import annotations

import argparse
import html
import json
import math
import re
import subprocess
import sys
import tempfile
from collections import Counter, defaultdict, deque
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path
from typing import Iterable

from build_full_graph_json import UNREVIEWED_STATUSES, read_validity_ledger
from build_machine_typology import ROOT, Machine, parse_transition_tables
from build_transition_tables import Contract, contracts as read_contract_rows, prolog_input
from render_automaton_svg import action_semantics, palette, wrap_atom


OUTPUT_DIR = ROOT / "docs/research/assets/automata"
SCENE_SUFFIX = "-scene.svg"
COMPOSITE_FILENAME = "_composite.svg"
MONO = "ui-monospace, Menlo, Consolas, monospace"


@dataclass(frozen=True)
class Execution:
    status: str
    result: str | None
    expected: str | None
    classification: str | None
    validity: str | None
    trace: tuple[str, ...]


@dataclass(frozen=True)
class SceneRecord:
    family: str
    kind: str
    svg: str | None
    caption: str | None
    reach_limit: str | None
    representation: str | None


@dataclass(frozen=True)
class ProducerScene:
    scene: dict[str, object]
    caption: str


def esc(value: object) -> str:
    return html.escape(str(value), quote=True)


def read_contracts() -> dict[tuple[str, str], Contract]:
    return {(row.operation, row.kind): row for row in read_contract_rows()}


def term_value(text: str | None) -> str | int | float | None:
    if text is None:
        return None
    if re.fullmatch(r"-?\d+", text):
        return int(text)
    if re.fullmatch(r"-?(?:\d+\.\d*|\d*\.\d+)", text):
        return float(text)
    return text


def role_color(role: str | None, colors: dict[str, str]) -> str:
    if role in {"deformation", "error", "incorrect"}:
        return colors["rust"]
    if role in {"neutral", "hollow"}:
        return colors["muted"]
    if role in {"whole", "pan"}:
        return colors["surface"]
    if role in {"correct", "annotation", "point", "image", "pre-image"}:
        return colors["ink"]
    return colors["gold"]


def svg_document(title: str, desc: str, width: int, height: int, body: Iterable[str], colors: dict[str, str]) -> str:
    lines = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" '
        f'viewBox="0 0 {width} {height}" role="img" aria-labelledby="title desc">',
        f'  <title id="title">{esc(title)}</title>',
        f'  <desc id="desc">{esc(desc)}</desc>',
        f'  <rect width="100%" height="100%" fill="{colors["paper"]}"/>',
        *body,
        "</svg>",
    ]
    return "\n".join(lines) + "\n"


def svg_text(x: float, y: float, value: object, color: str, size: float = 13, anchor: str = "middle", weight: str = "normal") -> str:
    return (
        f'  <text x="{x:.1f}" y="{y:.1f}" text-anchor="{anchor}" font-family="{MONO}" '
        f'font-size="{size:.1f}" font-weight="{weight}" fill="{color}">{esc(value)}</text>'
    )


def estimated_text_width(value: object, size: float) -> float:
    """Estimate monospace text width using the factor used by label boxes."""
    return len(str(value)) * size * 0.66


def text_right_edge(x: float, value: object, size: float, anchor: str = "middle") -> float:
    width = estimated_text_width(value, size)
    if anchor == "start":
        return x + width
    if anchor == "end":
        return x
    return x + width / 2


def execution_harness(probes: list[tuple[str, str, str, str]]) -> str:
    facts = "\n".join(
        f"probe({family}, {kind}, {left}, {right})." for family, kind, left, right in probes
    )
    return f"""
:- use_module(library(http/json)).
:- use_module(library(time)).

{facts}

term_text(Term, Text) :- term_string(Term, Text, [quoted(true), numbervars(true)]).
field_text(Name, Fields, Text) :-
    Term =.. [Name, Value], memberchk(Term, Fields), !, term_text(Value, Text).
field_text(_, _, @(null)).

trace_texts(Trace, Texts) :-
    ( is_list(Trace) -> maplist(term_text, Trace, Texts) ; Texts = [] ).

probe_one(Family, Kind, Left, Right) :-
    catch((call_with_time_limit(2,
          once(action_automata_registry:run_action_automaton(
              Family, Kind, Left, Right, Outcome, Trace))) -> Status = "observed" ; Status = "failed"),
          Error, (Status = "error", term_text(Error, _ErrorText))),
    ( Status == "observed", Outcome = action_outcome(_, Fields)
    -> field_text(result, Fields, Result),
       field_text(expected, Fields, Expected),
       field_text(classification, Fields, Classification),
       field_text(validity, Fields, Validity),
       trace_texts(Trace, TraceTexts)
    ; Result = @(null), Expected = @(null), Classification = @(null),
      Validity = @(null), TraceTexts = []
    ),
    Dict = _{{family:Family, kind:Kind, status:Status, result:Result,
              expected:Expected, classification:Classification,
              validity:Validity, trace:TraceTexts}},
    json_write_dict(current_output, Dict, [width(0)]), nl.

main :- forall(probe(Family, Kind, Left, Right),
               probe_one(Family, Kind, Left, Right)), halt.
""".strip() + "\n"


def run_executions(machines: list[Machine], contracts: dict[tuple[str, str], Contract]) -> dict[tuple[str, str], Execution]:
    probes = []
    for machine in machines:
        contract = contracts[(machine.family, machine.kind)]
        left, right = prolog_input(contract.example)
        probes.append((machine.family, machine.kind, left, right))
    with tempfile.TemporaryDirectory(prefix="hermes-compendium-") as tmp:
        harness = Path(tmp) / "run_contracts.pl"
        harness.write_text(execution_harness(probes), encoding="utf-8")
        result = subprocess.run(
            ["swipl", "-q", "-l", str(ROOT / "paths.pl"),
             "-l", str(ROOT / "knowledge/strategies/math/action_automata_registry.pl"),
             "-l", str(harness), "-g", "main"],
            cwd=ROOT, text=True, capture_output=True, timeout=90, check=False,
        )
    if result.returncode:
        raise RuntimeError(f"contract scene batch failed ({result.returncode}): {result.stderr.strip()}")
    rows: dict[tuple[str, str], Execution] = {}
    for line in result.stdout.splitlines():
        if not line.startswith("{"):
            continue
        item = json.loads(line)
        key = (item["family"], item["kind"])
        rows[key] = Execution(
            item["status"], item.get("result"), item.get("expected"),
            item.get("classification"), item.get("validity"), tuple(item.get("trace", ())),
        )
    if set(rows) != {(m.family, m.kind) for m in machines}:
        missing = sorted({(m.family, m.kind) for m in machines} - set(rows))
        raise ValueError(f"contract scene batch omitted {len(missing)} machine(s): {missing[:5]}")
    return rows


def producer_requests(
    machines: list[Machine], contracts: dict[tuple[str, str], Contract]
) -> list[tuple[str, str, str]]:
    requests = []
    for machine in machines:
        example = contracts[(machine.family, machine.kind)].example
        tag = example.get("kind")
        spec: str | None = None
        if machine.family == "addition" and any(token in machine.kind for token in ("column", "carry", "regroup")):
            spec = f"place_value(add_with_carry({example['a']},{example['b']},10))"
        elif machine.family == "multiplication":
            spec = f"area(array_multiplication({example['a']},{example['b']}))"
        elif machine.family == "statistics":
            if tag == "categorical_frequencies":
                pairs = example["pairs"]
                encoded = ",".join(f"{p['category']}-{p['count']}" for p in pairs)
                spec = f"data(bar_chart([{encoded}]))"
            elif tag in {"numeric_data_display", "numeric_data_with_unit", "distribution_data"}:
                spec = f"data(dot_plot({json.dumps(example['values'], separators=(',', ':'))}))"
            elif tag == "box_plot_data":
                values = example["values"]
                spec = f"data(box_plot(five_number({','.join(str(v) for v in values)})))"
            elif tag == "histogram_data":
                values = [int(v) for v in example["values"]]
                bin_width = int(example["bin_width"])
                lower = min(values)
                bins = []
                while lower <= max(values):
                    upper = lower + bin_width
                    bins.append(f"bin({lower},{upper})-{sum(lower <= v < upper for v in values)}")
                    lower = upper
                spec = f"data(histogram([{','.join(bins)}]))"
        elif machine.family == "algebraic" and tag in {"linear_equation", "linear_context"}:
            a = example.get("a", example.get("coefficient"))
            b = example.get("b", example.get("offset"))
            c = example.get("c", example.get("total"))
            spec = f"balance(solve_linear({a},{b},{c}))"
        elif machine.family == "geometry":
            if tag == "angle_measure":
                spec = f"angle(angle({example['degrees']}))"
            elif tag == "angle_parts":
                spec = f"angle(angle({example['whole']}))"
            elif tag in {"coordinate_points", "coordinate_point_pair"}:
                points = example.get("points", [example.get("first"), example.get("second")])
                encoded = ",".join(f"{p['x']}-{p['y']}" for p in points if p)
                spec = f"coordinate(plot_points([{encoded}]))"
            elif tag == "solid_net":
                spec = f"solid(net_of({example['solid']}))"
            elif tag == "rectangular_prism":
                spec = f"solid(unit_cube_stack({example['length']},{example['width']},{example['height']}))"
            elif tag == "volume_known_base":
                base = int(example["length"]) * int(example["width"])
                if base and int(example["volume"]) % base == 0:
                    spec = f"solid(unit_cube_stack({example['length']},{example['width']},{int(example['volume']) // base}))"
            elif tag == "rigid_shape_composition":
                pieces = []
                for piece in example["pieces"]:
                    cells = ",".join(f"{cell['x']+1}-{cell['y']+1}" for cell in piece["cells"])
                    pieces.append(f"placed({piece['id']},[{cells}])")
                spec = f"polyform(tile_region(cols({example['columns']}),rows({example['rows']}),[{','.join(pieces)}]))"
            elif tag == "polygon_partition":
                vertices = ",".join(f"{point['x']}-{point['y']}" for point in example["vertices"])
                spec = f"geoboard(stretch_polygon([{vertices}]))"
        if spec:
            requests.append((machine.family, machine.kind, spec))
    return requests


def producer_harness(requests: list[tuple[str, str, str]]) -> str:
    facts = "\n".join(f"scene_request({family}, {kind}, {spec})." for family, kind, spec in requests)
    return f"""
:- use_module(library(http/json)).
:- use_module(render(place_value_chart_scene)).
:- use_module(render(area_model_scene)).
:- use_module(render(data_display_scene)).
:- use_module(render(balance_scale_scene)).
:- use_module(render(angle_circular_scene)).
:- use_module(render(coordinate_plane_scene)).
:- use_module(render(solid_net_scene)).
:- use_module(render(polyform_tiling_scene)).
:- use_module(render(geoboard_scene)).

{facts}

render_doc(place_value(Spec), Doc) :- place_value_chart_scene:place_value_chart_render_json(Spec, Doc).
render_doc(area(Spec), Doc) :- area_model_scene:area_render_json(Spec, Doc).
render_doc(data(Spec), Doc) :- data_display_scene:data_display_render_json(Spec, Doc).
render_doc(balance(Spec), Doc) :- balance_scale_scene:balance_render_json(Spec, Doc).
render_doc(angle(Spec), Doc) :- angle_circular_scene:angle_circular_render_json(Spec, Doc).
render_doc(coordinate(Spec), Doc) :- coordinate_plane_scene:coordinate_plane_render_json(Spec, Doc).
render_doc(solid(Spec), Doc) :- solid_net_scene:solid_net_render_json(Spec, Doc).
render_doc(polyform(Spec), Doc) :- polyform_tiling_scene:polyform_tiling_render_json(Spec, Doc).
render_doc(geoboard(Spec), Doc) :- geoboard_scene:geoboard_render_json(Spec, Doc).

last_changed_frame(Frames, Frame) :- reverse(Frames, Rev), member(Frame, Rev),
    get_dict(sceneChanged, Frame, true), !.

render_one(Family, Kind, Spec) :-
    catch(render_doc(Spec, Doc), Error,
          (term_string(Error, Err), Doc = _{{error:Err, frames:[]}})),
    ( get_dict(frames, Doc, Frames), last_changed_frame(Frames, Frame),
      get_dict(scene, Frame, Scene), get_dict(caption, Frame, Caption)
    -> Dict = _{{family:Family, kind:Kind, scene:Scene, caption:Caption}}
    ;  Dict = _{{family:Family, kind:Kind, error:"producer returned no changed frame"}}
    ),
    json_write_dict(current_output, Dict, [width(0)]), nl.

main :- forall(scene_request(Family, Kind, Spec), render_one(Family, Kind, Spec)), halt.
""".strip() + "\n"


def run_producers(
    machines: list[Machine], contracts: dict[tuple[str, str], Contract]
) -> dict[tuple[str, str], ProducerScene]:
    requests = producer_requests(machines, contracts)
    if not requests:
        return {}
    with tempfile.TemporaryDirectory(prefix="hermes-scenes-") as tmp:
        harness = Path(tmp) / "render_scenes.pl"
        harness.write_text(producer_harness(requests), encoding="utf-8")
        result = subprocess.run(
            ["swipl", "-q", "-l", str(ROOT / "paths.pl"), "-l", str(harness), "-g", "main"],
            cwd=ROOT, text=True, capture_output=True, timeout=90, check=False,
        )
    if result.returncode:
        raise RuntimeError(f"scene-producer batch failed ({result.returncode}): {result.stderr.strip()}")
    rows = {}
    for line in result.stdout.splitlines():
        if not line.startswith("{"):
            continue
        item = json.loads(line)
        if "scene" in item:
            rows[(item["family"], item["kind"])] = ProducerScene(item["scene"], item["caption"])
    return rows


def outcome_note(execution: Execution) -> tuple[str, bool]:
    result = execution.result or "not recorded"
    expected = execution.expected
    deformed = execution.classification == "deformation" or (expected is not None and result != expected)
    if deformed and expected:
        return f"The run produced {result}; the recorded expected result is {expected}.", True
    if deformed:
        return f"The run produced {result} on a deformation path.", True
    return f"The run produced {result}.", False


def draw_place_value(
    machine: Machine, producer: ProducerScene, execution: Execution, colors: dict[str, str]
) -> tuple[str, str]:
    scene = producer.scene
    columns = list(scene.get("columns", []))
    rows = [dict(row) for row in scene.get("rows", [])]
    carries = list(scene.get("carries", []))
    note, deformed = outcome_note(execution)
    actual = term_value(execution.result)
    if rows and isinstance(actual, int):
        digits = list(str(abs(actual)))
        width = max(len(columns), len(digits))
        if width > len(columns):
            columns = ([{"label": "overflow", "place": width - 1}] * (width - len(columns))) + columns
        glyphs = [""] * (width - len(digits)) + digits
        rows[-1] = {"role": "deformation" if deformed else "sum", "label": str(actual), "digitGlyphs": glyphs}
    if deformed and any(token in machine.kind for token in ("drop_carry", "without_carry", "append_column")):
        carries = []
    ncols = max(1, len(columns))
    cell_w, cell_h = 92, 52
    x0, y0 = 150, 70
    width = max(700, x0 + ncols * cell_w + 80)
    chart_max_y = y0 + (len(rows) + 1) * cell_h
    caption_y = chart_max_y + 36
    height = int(caption_y + 28)
    body = [svg_text(x0 - 28, 32, machine.kind, colors["ink"], 12, "start", "bold")]
    for i, column in enumerate(columns):
        x = x0 + i * cell_w
        body.append(f'  <rect x="{x}" y="{y0}" width="{cell_w}" height="{cell_h}" fill="{colors["surface"]}" stroke="{colors["muted"]}"/>')
        body.append(svg_text(x + cell_w / 2, y0 + 31, column.get("label", "place"), colors["muted"], 11))
    for r, row in enumerate(rows):
        y = y0 + (r + 1) * cell_h
        glyphs = list(row.get("digitGlyphs", row.get("digits", [])))
        glyphs = [""] * (ncols - len(glyphs)) + glyphs[-ncols:]
        row_color = colors["rust"] if row.get("role") == "deformation" else colors["ink"]
        body.append(svg_text(x0 - 15, y + 32, row.get("label", ""), colors["muted"], 10, "end"))
        for i, glyph in enumerate(glyphs):
            x = x0 + i * cell_w
            body.append(f'  <rect x="{x}" y="{y}" width="{cell_w}" height="{cell_h}" fill="none" stroke="{colors["muted"]}"/>')
            body.append(svg_text(x + cell_w / 2, y + 34, glyph, row_color, 24, weight="bold"))
    for carry in carries:
        place = int(carry.get("toPlace", 0))
        index = ncols - 1 - place
        x = x0 + index * cell_w + cell_w / 2
        body.append(svg_text(x, y0 - 12, carry.get("label", "carry"), colors["gold"], 10))
    body.append(svg_text(36, caption_y, note, colors["rust"] if deformed else colors["muted"], 12, "start"))
    return svg_document(f"Domain scene for {machine.family}/{machine.kind}", note, width, height, body, colors), note


def number_line_scene(
    machine: Machine, example: dict[str, object], execution: Execution, colors: dict[str, str]
) -> tuple[str, str] | None:
    points: list[tuple[float, str]] = []
    arcs: list[tuple[float, float, str, bool]] = []
    tag = example.get("kind")
    result = term_value(execution.result)
    expected = term_value(execution.expected)
    if machine.family in {"addition", "subtraction"} and "a" in example and "b" in example:
        a, b = float(example["a"]), float(example["b"])
        if machine.family == "addition":
            endpoint = float(result) if isinstance(result, (int, float)) else a + b
            points = [(0, "0"), (a, str(example["a"])), (endpoint, str(result or endpoint))]
            arcs = [(a, endpoint, f"{endpoint - a:+g}", execution.classification == "deformation")]
        else:
            endpoint = float(result) if isinstance(result, (int, float)) else a - b
            points = [(0, "0"), (a, str(example["a"])), (endpoint, str(result or endpoint))]
            arcs = [(a, endpoint, f"{endpoint - a:+g}", execution.classification == "deformation")]
    elif machine.family == "integer":
        if tag == "signed_number_list":
            points = [(float(v), str(v)) for v in example["values"]]
        elif tag == "inequality":
            bound = float(example["bound"])
            points = [(bound, f"{example['relation']} {example['bound']}")]
        else:
            points = [(float(example["a"]), str(example["a"])), (float(example["b"]), str(example["b"]))]
    elif machine.family == "decimal":
        if tag == "decimal_pair":
            left, right = example["left"], example["right"]
            lv = float(left["numeral"]) / (10 ** int(left["scale"]))
            rv = float(right["numeral"]) / (10 ** int(right["scale"]))
            points = [(lv, f"{lv:g}"), (rv, f"{rv:g}")]
        elif tag == "decimal_unit_conversion":
            value = float(example["count"]) / float(example["from_scale"])
            points = [(0, "0"), (value, f"{example['count']}/{example['from_scale']}")]
        else:
            points = [(float(example["a"]), str(example["a"])), (float(example["b"]), str(example["b"]))]
    elif machine.family == "measurement":
        if tag == "quantity_conversion":
            value = example["count"]
        elif tag == "measure_with_unit":
            value = example["interval_count"]
        elif tag == "measured_change":
            value = example["a"] + example["b"] if example.get("operation") == "add" else example["a"] - example["b"]
        else:
            value = example.get("value", example.get("measure", 0))
        if isinstance(value, (int, float)):
            points = [(0, "0"), (float(value), f"{value} {example.get('unit', '')}".strip())]
    elif machine.family == "counting":
        if tag == "cardinality":
            points = [(0, "0"), (float(example["count"]), str(example["count"]))]
        elif tag in {"count_pair", "collection_pair"}:
            points = [(float(example["left"]), str(example["left"])), (float(example["right"]), str(example["right"]))]
    if not points:
        return None
    if isinstance(expected, (int, float)) and all(abs(float(expected) - p[0]) > 1e-9 for p in points):
        points.append((float(expected), f"expected {expected}"))
    values = [p[0] for p in points] + [v for arc in arcs for v in arc[:2]]
    lo, hi = min(values), max(values)
    if lo == hi:
        lo, hi = lo - 1, hi + 1
    pad = max(1.0, (hi - lo) * 0.12)
    lo, hi = lo - pad, hi + pad
    x0, x1, y = 70.0, 690.0, 205.0
    sx = lambda value: x0 + (value - lo) / (hi - lo) * (x1 - x0)
    note, deformed = outcome_note(execution)
    body = [
        f'  <line x1="{x0}" y1="{y}" x2="{x1}" y2="{y}" stroke="{colors["ink"]}" stroke-width="2"/>',
    ]
    for value, label in sorted(points):
        x = sx(value)
        point_color = colors["rust"] if deformed and str(result) in label else colors["gold"]
        body.extend([
            f'  <line x1="{x:.1f}" y1="{y - 9}" x2="{x:.1f}" y2="{y + 9}" stroke="{colors["ink"]}" stroke-width="1.5"/>',
            f'  <circle cx="{x:.1f}" cy="{y:.1f}" r="5" fill="{point_color}" stroke="{colors["ink"]}"/>',
            svg_text(x, y + 31, label, colors["ink"], 11),
        ])
    for start, end, label, broken in arcs:
        xa, xb = sx(start), sx(end)
        mid, lift = (xa + xb) / 2, max(38, abs(xb - xa) * 0.24)
        body.append(
            f'  <path d="M {xa:.1f} {y - 5:.1f} Q {mid:.1f} {y - lift:.1f} {xb:.1f} {y - 5:.1f}" '
            f'fill="none" stroke="{colors["rust"] if broken else colors["gold"]}" stroke-width="3"/>'
        )
        body.append(svg_text(mid, y - lift + 15, label, colors["rust"] if broken else colors["ink"], 11))
    body.append(svg_text(36, 330, note, colors["rust"] if deformed else colors["muted"], 12, "start"))
    return svg_document(f"Domain scene for {machine.family}/{machine.kind}", note, 760, 360, body, colors), note


def fraction_parts(example: dict[str, object]) -> list[tuple[int, int, str]]:
    tag = example.get("kind")
    if tag in {"fraction_pair", "fraction_addend_pair", "fraction_minuend_subtrahend"}:
        found = []
        for side in ("left", "right"):
            value = example[side]
            if "whole" in value and len(value) == 1:
                found.append((int(value["whole"]), 1, side))
            else:
                found.append((int(value.get("n", 0)), int(value.get("d", 1)), side))
        return found
    if tag == "fraction_solve":
        value = example["coefficient"]
        return [(int(value["n"]), int(value["d"]), "coefficient")]
    if "a" in example and "b" in example and int(example["b"]) > 0:
        return [(int(example["a"]), int(example["b"]), "iterated unit")]
    return []


def draw_fraction_scene(
    machine: Machine, example: dict[str, object], execution: Execution, colors: dict[str, str]
) -> tuple[str, str] | None:
    bars = fraction_parts(example)
    if not bars:
        return None
    note, deformed = outcome_note(execution)
    body = []
    x0, total_w, bar_h = 150.0, 480.0, 52.0
    for row, (numerator, denominator, label) in enumerate(bars):
        if denominator <= 0 or denominator > 120:
            return None
        y = 72 + row * 102
        visible = max(denominator, numerator)
        cell = total_w / denominator
        full_w = max(total_w, visible * cell)
        body.append(svg_text(x0 - 18, y + 31, f"{label}: {numerator}/{denominator}", colors["ink"], 11, "end"))
        for i in range(visible):
            x = x0 + i * cell
            fill = colors["gold"] if i < numerator else colors["surface"]
            body.append(f'  <rect x="{x:.1f}" y="{y:.1f}" width="{cell:.1f}" height="{bar_h:.1f}" fill="{fill}" fill-opacity="0.72" stroke="{colors["ink"]}" stroke-width="1"/>')
        body.append(f'  <rect x="{x0:.1f}" y="{y:.1f}" width="{full_w:.1f}" height="{bar_h:.1f}" fill="none" stroke="{colors["ink"]}" stroke-width="2"/>')
    height = 72 + len(bars) * 102 + 70
    body.append(svg_text(36, height - 28, note, colors["rust"] if deformed else colors["muted"], 12, "start"))
    return svg_document(f"Domain scene for {machine.family}/{machine.kind}", note, 760, height, body, colors), note


def draw_area_scene(
    machine: Machine, producer: ProducerScene, execution: Execution, colors: dict[str, str]
) -> tuple[str, str]:
    scene = producer.scene
    note, deformed = outcome_note(execution)
    body = []
    rects = list(scene.get("rects", []))
    if rects:
        min_x = min(float(rect["x"]) for rect in rects)
        min_y = min(float(rect["y"]) for rect in rects)
        max_x = max(float(rect["x"]) + float(rect["w"]) for rect in rects)
        max_y = max(float(rect["y"]) + float(rect["h"]) for rect in rects)
        dx = (700 - (max_x - min_x)) / 2 - min_x
        dy = (440 - (max_y - min_y)) / 2 - min_y
    else:
        dx = dy = 0.0
    for rect in rects:
        fill = role_color(rect.get("role"), colors)
        body.append(
            f'  <rect x="{float(rect["x"])+dx:.1f}" y="{float(rect["y"])+dy:.1f}" '
            f'width="{float(rect["w"]):.1f}" height="{float(rect["h"]):.1f}" '
            f'fill="{fill}" fill-opacity="0.55" stroke="{colors["ink"]}" stroke-width="1.5"/>'
        )
    grid = scene.get("gridlines", {})
    if rects:
        r0 = rects[0]
        for x in grid.get("v", []):
            body.append(f'  <line x1="{float(x)+dx:.1f}" y1="{float(r0["y"])+dy:.1f}" x2="{float(x)+dx:.1f}" y2="{float(r0["y"])+float(r0["h"])+dy:.1f}" stroke="{colors["muted"]}" stroke-width="0.8"/>')
        for y in grid.get("h", []):
            body.append(f'  <line x1="{float(r0["x"])+dx:.1f}" y1="{float(y)+dy:.1f}" x2="{float(r0["x"])+float(r0["w"])+dx:.1f}" y2="{float(y)+dy:.1f}" stroke="{colors["muted"]}" stroke-width="0.8"/>')
    body.append(svg_text(36, 486, note, colors["rust"] if deformed else colors["muted"], 12, "start"))
    return svg_document(f"Domain scene for {machine.family}/{machine.kind}", note, 700, 520, body, colors), note


def draw_geometry_area(
    machine: Machine, example: dict[str, object], execution: Execution, colors: dict[str, str]
) -> tuple[str, str] | None:
    tag = example.get("kind")
    note, deformed = outcome_note(execution)
    body = []
    if tag in {"rectangle_with_unit", "rectangle_constraints", "area_known_side", "perimeter_known_side"}:
        width = float(example.get("width", example.get("known_width", example.get("side", 4))))
        height = float(example.get("height", example.get("known_height", example.get("other_side", 3))))
        if width <= 0 or height <= 0:
            return None
        scale = min(440 / width, 240 / height)
        rw, rh = width * scale, height * scale
        x, y = (700 - rw) / 2, 80
        body.append(f'  <rect x="{x:.1f}" y="{y:.1f}" width="{rw:.1f}" height="{rh:.1f}" fill="{colors["gold"]}" fill-opacity="0.38" stroke="{colors["ink"]}" stroke-width="2"/>')
        body.append(svg_text(x + rw / 2, y + rh + 24, f"{width:g}", colors["ink"], 12))
        body.append(svg_text(x - 18, y + rh / 2, f"{height:g}", colors["ink"], 12))
    elif tag in {"triangle_with_unit", "parallelogram_with_unit"}:
        base = float(example.get("base", 4)); height_v = float(example.get("height", 3))
        x, y, bw, hh = 145, 80, min(440, base * 60), min(240, height_v * 60)
        if tag == "triangle_with_unit":
            points = f"{x},{y+hh} {x+bw},{y+hh} {x+bw*.62},{y}"
        else:
            points = f"{x},{y+hh} {x+bw},{y+hh} {x+bw+70},{y} {x+70},{y}"
        body.append(f'  <polygon points="{points}" fill="{colors["gold"]}" fill-opacity="0.38" stroke="{colors["ink"]}" stroke-width="2"/>')
        body.append(svg_text(x + bw / 2, y + hh + 24, f"base {base:g}", colors["ink"], 12))
        body.append(svg_text(x + bw + 30, y + hh / 2, f"height {height_v:g}", colors["ink"], 12))
    elif tag == "covered_cells":
        cells = example.get("cells", [])
        cols = max((int(cell["x"]) for cell in cells), default=0) + 1
        rows = max((int(cell["y"]) for cell in cells), default=0) + 1
        if cols <= 0 or rows <= 0 or cols * rows > 200:
            return None
        cell = min(44, 440 / cols, 240 / rows)
        x0, y0 = 130, 70
        covered = {(int(cell["x"]), int(cell["y"])) for cell in cells}
        for r in range(rows):
            for c in range(cols):
                fill = colors["gold"] if (c, r) in covered or (c + 1, r + 1) in covered else colors["surface"]
                body.append(f'  <rect x="{x0+c*cell:.1f}" y="{y0+r*cell:.1f}" width="{cell:.1f}" height="{cell:.1f}" fill="{fill}" fill-opacity="0.55" stroke="{colors["muted"]}"/>')
    else:
        return None
    body.append(svg_text(36, 386, note, colors["rust"] if deformed else colors["muted"], 12, "start"))
    return svg_document(f"Domain scene for {machine.family}/{machine.kind}", note, 700, 420, body, colors), note


def draw_data_scene(
    machine: Machine, producer: ProducerScene, execution: Execution, colors: dict[str, str]
) -> tuple[str, str]:
    scene = producer.scene
    note, deformed = outcome_note(execution)
    body = []
    baseline = 340
    if scene.get("mode") == "box" and scene.get("boxPlot"):
        bp = scene["boxPlot"]
        y = float(bp["y"]); top, bottom = y - 30, y + 30
        body.extend([
            f'  <line x1="{bp["xMin"]}" y1="{y}" x2="{bp["xMax"]}" y2="{y}" stroke="{colors["ink"]}" stroke-width="2"/>',
            f'  <rect x="{bp["xQ1"]}" y="{top}" width="{float(bp["xQ3"])-float(bp["xQ1"]):.1f}" height="60" fill="{colors["gold"]}" fill-opacity="0.5" stroke="{colors["ink"]}"/>',
            f'  <line x1="{bp["xMedian"]}" y1="{top}" x2="{bp["xMedian"]}" y2="{bottom}" stroke="{colors["ink"]}" stroke-width="2"/>',
        ])
    else:
        body.extend([
            f'  <line x1="60" y1="40" x2="60" y2="{baseline}" stroke="{colors["ink"]}" stroke-width="1.5"/>',
            f'  <line x1="60" y1="{baseline}" x2="540" y2="{baseline}" stroke="{colors["ink"]}" stroke-width="1.5"/>',
        ])
        for bar in scene.get("bars", []):
            body.append(f'  <rect x="{bar["x"]}" y="{bar["y"]}" width="{bar["w"]}" height="{bar["h"]}" fill="{role_color(bar.get("role"), colors)}" fill-opacity="0.6" stroke="{colors["ink"]}"/>')
            body.append(svg_text(float(bar["x"]) + float(bar["w"]) / 2, baseline + 17, bar.get("label", ""), colors["ink"], 10))
        for dot in scene.get("dots", []):
            body.append(f'  <circle cx="{dot["x"]}" cy="{dot["y"]}" r="7" fill="{role_color(dot.get("role"), colors)}" stroke="{colors["ink"]}"/>')
        labels = scene.get("axes", {}).get("categoryLabels", [])
        if scene.get("mode") == "dot":
            for i, label in enumerate(labels):
                body.append(svg_text(60 + i * 40, baseline + 17, label, colors["ink"], 10))
    body.append(svg_text(28, 394, note, colors["rust"] if deformed else colors["muted"], 11, "start"))
    return svg_document(f"Domain scene for {machine.family}/{machine.kind}", note, 580, 420, body, colors), note


def draw_balance_scene(
    machine: Machine, producer: ProducerScene, execution: Execution, colors: dict[str, str]
) -> tuple[str, str]:
    scene = producer.scene
    note, deformed = outcome_note(execution)
    body = []
    tilt = scene.get("beam", {}).get("tilt", "level")
    dy = 0 if tilt == "level" else 18 if tilt == "left_down" else -18
    lx, ly, rx, ry = 210, 170 + dy, 490, 170 - dy
    body.extend([
        f'  <line x1="{lx}" y1="{ly}" x2="{rx}" y2="{ry}" stroke="{colors["ink"]}" stroke-width="5"/>',
        f'  <polygon points="350,185 320,300 380,300" fill="{colors["surface"]}" stroke="{colors["ink"]}" stroke-width="2"/>',
    ])
    for side, x, y in (("left", lx, ly), ("right", rx, ry)):
        body.append(f'  <path d="M {x-95} {y+65} Q {x} {y+105} {x+95} {y+65}" fill="none" stroke="{colors["ink"]}" stroke-width="3"/>')
        cursor = x - 76
        for row in scene.get("pans", {}).get(side, []):
            count = min(int(row.get("count", 0)), 20)
            for _ in range(count):
                fill = role_color(row.get("role"), colors)
                if row.get("kind") == "x":
                    body.append(f'  <rect x="{cursor}" y="{y+35}" width="28" height="28" rx="3" fill="{fill}" fill-opacity="0.65" stroke="{colors["ink"]}"/>')
                    body.append(svg_text(cursor + 14, y + 54, "x", colors["ink"], 11))
                else:
                    body.append(f'  <circle cx="{cursor+13}" cy="{y+49}" r="12" fill="{fill}" fill-opacity="0.65" stroke="{colors["ink"]}"/>')
                cursor += 31
    body.append(svg_text(28, 334, note, colors["rust"] if deformed else colors["muted"], 11, "start"))
    return svg_document(f"Domain scene for {machine.family}/{machine.kind}", note, 700, 360, body, colors), note


def draw_angle_scene(machine: Machine, producer: ProducerScene, execution: Execution, colors: dict[str, str]) -> tuple[str, str]:
    scene = producer.scene
    note, deformed = outcome_note(execution)
    vertex = scene["vertex"]
    vx, vy = float(vertex["x"]) + 110, float(vertex["y"]) - 20
    body = []
    for ray in scene.get("rays", []):
        angle = math.radians(float(ray["angleDeg"]))
        length = float(ray.get("length", 150))
        x, y = vx + math.cos(angle) * length, vy - math.sin(angle) * length
        body.append(f'  <line x1="{vx:.1f}" y1="{vy:.1f}" x2="{x:.1f}" y2="{y:.1f}" stroke="{role_color(ray.get("role"), colors)}" stroke-width="3"/>')
    arc = scene.get("arc")
    if arc:
        radius = float(arc["radius"])
        start = math.radians(float(arc["startDeg"]))
        sweep = float(arc["sweepDeg"])
        end = start + math.radians(sweep)
        x1, y1 = vx + math.cos(start) * radius, vy - math.sin(start) * radius
        x2, y2 = vx + math.cos(end) * radius, vy - math.sin(end) * radius
        large = 1 if abs(sweep) > 180 else 0
        body.append(f'  <path d="M {x1:.1f} {y1:.1f} A {radius:.1f} {radius:.1f} 0 {large} 0 {x2:.1f} {y2:.1f}" fill="none" stroke="{colors["gold"]}" stroke-width="4"/>')
        mid = start + math.radians(sweep) / 2
        body.append(svg_text(vx + math.cos(mid) * (radius + 30), vy - math.sin(mid) * (radius + 30), f'{scene.get("label", sweep)}°', colors["ink"], 14, weight="bold"))
    body.append(f'  <circle cx="{vx:.1f}" cy="{vy:.1f}" r="5" fill="{colors["ink"]}"/>')
    body.append(svg_text(30, 354, note, colors["rust"] if deformed else colors["muted"], 11, "start"))
    return svg_document(f"Domain scene for {machine.family}/{machine.kind}", note, 700, 380, body, colors), note


def coordinate_transform(bounds: dict[str, object], width: int = 700, height: int = 420):
    x_min, x_max = float(bounds["xMin"]), float(bounds["xMax"])
    y_min, y_max = float(bounds["yMin"]), float(bounds["yMax"])
    left, right, top, bottom = 70.0, width - 50.0, 40.0, height - 70.0
    sx = lambda x: left + (float(x) - x_min) / max(1.0, x_max - x_min) * (right - left)
    sy = lambda y: bottom - (float(y) - y_min) / max(1.0, y_max - y_min) * (bottom - top)
    return sx, sy


def draw_coordinate_scene(machine: Machine, producer: ProducerScene, execution: Execution, colors: dict[str, str]) -> tuple[str, str]:
    scene = producer.scene
    note, deformed = outcome_note(execution)
    axes = scene["axes"]
    sx, sy = coordinate_transform(axes)
    body = []
    for x in range(math.ceil(float(axes["xMin"])), math.floor(float(axes["xMax"])) + 1):
        body.append(f'  <line x1="{sx(x):.1f}" y1="40" x2="{sx(x):.1f}" y2="350" stroke="{colors["surface"]}" stroke-width="1"/>')
    for y in range(math.ceil(float(axes["yMin"])), math.floor(float(axes["yMax"])) + 1):
        body.append(f'  <line x1="70" y1="{sy(y):.1f}" x2="650" y2="{sy(y):.1f}" stroke="{colors["surface"]}" stroke-width="1"/>')
    body.append(f'  <line x1="70" y1="{sy(0):.1f}" x2="650" y2="{sy(0):.1f}" stroke="{colors["ink"]}" stroke-width="2"/>')
    body.append(f'  <line x1="{sx(0):.1f}" y1="40" x2="{sx(0):.1f}" y2="350" stroke="{colors["ink"]}" stroke-width="2"/>')
    path = scene.get("path", [])
    if len(path) > 1:
        points = " ".join(f'{sx(p["x"]):.1f},{sy(p["y"]):.1f}' for p in path)
        body.append(f'  <polyline points="{points}" fill="none" stroke="{colors["gold"]}" stroke-width="3"/>')
    for point in scene.get("points", []):
        x, y = sx(point["x"]), sy(point["y"])
        body.append(f'  <circle cx="{x:.1f}" cy="{y:.1f}" r="6" fill="{role_color(point.get("role"), colors)}" stroke="{colors["ink"]}" stroke-width="1.5"/>')
        body.append(svg_text(x + 10, y - 10, point.get("label", f'({point["x"]}, {point["y"]})'), colors["ink"], 10, "start"))
    body.append(svg_text(28, 398, note, colors["rust"] if deformed else colors["muted"], 11, "start"))
    return svg_document(f"Domain scene for {machine.family}/{machine.kind}", note, 700, 420, body, colors), note


def draw_solid_scene(machine: Machine, producer: ProducerScene, execution: Execution, colors: dict[str, str]) -> tuple[str, str]:
    scene = producer.scene
    note, deformed = outcome_note(execution)
    body = []
    for index, face in enumerate(scene.get("faces", [])):
        points = " ".join(f'{float(p["x"])+100:.1f},{float(p["y"])+15:.1f}' for p in face["points"])
        fill = colors["gold"] if index % 2 == 0 else colors["surface"]
        body.append(f'  <polygon points="{points}" fill="{fill}" fill-opacity="0.5" stroke="{colors["ink"]}" stroke-width="2"/>')
        xs = [float(p["x"]) + 100 for p in face["points"]]; ys = [float(p["y"]) + 15 for p in face["points"]]
        body.append(svg_text(sum(xs) / len(xs), sum(ys) / len(ys) + 4, face.get("label", "face"), colors["ink"], 9))
    for crease in scene.get("creases", []):
        body.append(f'  <line x1="{float(crease["x1"])+100:.1f}" y1="{float(crease["y1"])+15:.1f}" x2="{float(crease["x2"])+100:.1f}" y2="{float(crease["y2"])+15:.1f}" stroke="{colors["muted"]}" stroke-width="1.5" stroke-dasharray="6 4"/>')
    body.append(svg_text(28, 404, note, colors["rust"] if deformed else colors["muted"], 11, "start"))
    return svg_document(f"Domain scene for {machine.family}/{machine.kind}", note, 700, 430, body, colors), note


def draw_polyform_scene(machine: Machine, producer: ProducerScene, execution: Execution, colors: dict[str, str]) -> tuple[str, str]:
    scene = producer.scene
    note, deformed = outcome_note(execution)
    cols, rows = int(scene["lattice"]["cols"]), int(scene["lattice"]["rows"])
    cell = min(80.0, 480 / max(1, cols), 260 / max(1, rows))
    x0, y0 = (700 - cols * cell) / 2, 50.0
    pieces = {name: index for index, name in enumerate(sorted({str(c["piece"]) for c in scene.get("cells", [])}))}
    body = []
    for item in scene.get("cells", []):
        col, row = int(item["col"]) - 1, int(item["row"]) - 1
        fill = colors["gold"] if pieces[str(item["piece"])] % 2 == 0 else colors["surface"]
        body.append(f'  <rect x="{x0+col*cell:.1f}" y="{y0+row*cell:.1f}" width="{cell:.1f}" height="{cell:.1f}" fill="{fill}" fill-opacity="0.62" stroke="{colors["ink"]}" stroke-width="1.5"><title>{esc(item["piece"])}</title></rect>')
    body.append(svg_text(350, y0 + rows * cell + 26, scene.get("regionLabel", "tiled region"), colors["ink"], 11))
    body.append(svg_text(28, 384, note, colors["rust"] if deformed else colors["muted"], 11, "start"))
    return svg_document(f"Domain scene for {machine.family}/{machine.kind}", note, 700, 410, body, colors), note


def draw_geoboard_scene(machine: Machine, producer: ProducerScene, execution: Execution, colors: dict[str, str]) -> tuple[str, str]:
    scene = producer.scene
    note, deformed = outcome_note(execution)
    sx, sy = coordinate_transform(scene["lattice"], 700, 430)
    polygon = " ".join(f'{sx(p["x"]):.1f},{sy(p["y"]):.1f}' for p in scene.get("polygon", []))
    body = [f'  <polygon points="{polygon}" fill="{colors["gold"]}" fill-opacity="0.38" stroke="{colors["ink"]}" stroke-width="3"/>']
    for peg in scene.get("pegs", []):
        kind = peg.get("kind")
        fill = colors["ink"] if kind == "boundary" else colors["gold"] if kind == "interior" else colors["surface"]
        radius = 4 if kind != "outside" else 2.5
        body.append(f'  <circle cx="{sx(peg["x"]):.1f}" cy="{sy(peg["y"]):.1f}" r="{radius}" fill="{fill}" stroke="{colors["muted"]}" stroke-width="0.7"/>')
    body.append(svg_text(350, 32, f'area {scene.get("area", "not recorded")}', colors["ink"], 12, weight="bold"))
    body.append(svg_text(28, 408, note, colors["rust"] if deformed else colors["muted"], 11, "start"))
    return svg_document(f"Domain scene for {machine.family}/{machine.kind}", note, 700, 430, body, colors), note


def build_scene_record(
    machine: Machine,
    contract: Contract,
    execution: Execution,
    producer: ProducerScene | None,
    colors: dict[str, str],
) -> SceneRecord:
    key = (machine.family, machine.kind)
    rendered: tuple[str, str] | None = None
    representation: str | None = None
    if producer:
        fmt = producer.scene.get("format")
        if fmt == "place-value-chart":
            rendered, representation = draw_place_value(machine, producer, execution, colors), "place-value chart"
        elif fmt == "area-model":
            rendered, representation = draw_area_scene(machine, producer, execution, colors), "area model"
        elif fmt == "data-display":
            rendered, representation = draw_data_scene(machine, producer, execution, colors), "data display"
        elif fmt == "balance-scale":
            rendered, representation = draw_balance_scene(machine, producer, execution, colors), "balance scale"
        elif fmt == "angle-circular":
            rendered, representation = draw_angle_scene(machine, producer, execution, colors), "angle model"
        elif fmt == "coordinate-plane":
            rendered, representation = draw_coordinate_scene(machine, producer, execution, colors), "coordinate plane"
        elif fmt == "solid-net":
            rendered, representation = draw_solid_scene(machine, producer, execution, colors), "solid or net"
        elif fmt == "polyform-tiling":
            rendered, representation = draw_polyform_scene(machine, producer, execution, colors), "polyform tiling"
        elif fmt == "geoboard":
            rendered, representation = draw_geoboard_scene(machine, producer, execution, colors), "geoboard"
    if rendered is None and machine.family == "fraction":
        rendered = draw_fraction_scene(machine, contract.example, execution, colors)
        representation = "fraction bars" if rendered else None
    if rendered is None and machine.family == "ratio":
        example = dict(contract.example)
        if "a" in example and "b" in example:
            rendered = draw_fraction_scene(machine, example, execution, colors)
        elif example.get("kind") == "referent_pair":
            example = {"a": example.get("left", 1), "b": example.get("right", 1)}
            rendered = draw_fraction_scene(machine, example, execution, colors)
        representation = "ratio bars" if rendered else None
    if rendered is None and machine.family in {"addition", "subtraction", "integer", "decimal", "measurement", "counting"}:
        rendered = number_line_scene(machine, contract.example, execution, colors)
        representation = "number line" if rendered else None
    if rendered is None and machine.family == "geometry":
        rendered = draw_geometry_area(machine, contract.example, execution, colors)
        representation = "area model" if rendered else None
    if rendered is None:
        tag = contract.example.get("kind", "two-operand")
        reason = (
            f"No domain scene: the static scene emitter has no {machine.family} form for the "
            f"{tag} contract used by this automaton."
        )
        if execution.status != "observed":
            reason = f"No domain scene: the contract run returned {execution.status}, so no executed scene was admitted."
        return SceneRecord(*key, None, None, reason, None)
    svg, caption = rendered
    trace_count = len(execution.trace)
    caption = f"{caption} The scene is derived from the contract run ({trace_count} trace steps)."
    return SceneRecord(*key, svg, caption, None, representation)


@lru_cache(maxsize=1)
def scene_records() -> dict[tuple[str, str], SceneRecord]:
    machines = parse_transition_tables()
    contracts = read_contracts()
    executions = run_executions(machines, contracts)
    producers = run_producers(machines, contracts)
    colors = palette()
    return {
        (machine.family, machine.kind): build_scene_record(
            machine, contracts[(machine.family, machine.kind)],
            executions[(machine.family, machine.kind)], producers.get((machine.family, machine.kind)), colors,
        )
        for machine in machines
    }


def accepting_paths(machine: Machine) -> list[tuple[tuple[str, str, str], ...]]:
    """Enumerate simple accepting action paths; loop traversal is not invented."""
    adjacency: dict[str, list[tuple[str, str]]] = defaultdict(list)
    for before, action, after in machine.unique_edges:
        adjacency[before].append((action, after))
    found: list[tuple[tuple[str, str, str], ...]] = []

    def walk(
        state: str,
        seen: frozenset[str],
        transitions: tuple[tuple[str, str, str], ...],
    ) -> None:
        if state in machine.accepting:
            found.append(transitions)
        for action, after in adjacency.get(state, []):
            if after in seen:
                continue
            walk(after, seen | {after}, transitions + ((state, action, after),))

    walk(machine.start, frozenset({machine.start}), ())
    return sorted(set(found))


class TrieNode:
    def __init__(self) -> None:
        self.children: dict[str, TrieNode] = {}
        self.edge_kinds: dict[str, set[str]] = defaultdict(set)
        self.edge_validity: dict[str, list[dict[str, object]]] = defaultdict(list)
        self.terminal = False


def composite_graph(family: str, machines: list[Machine]) -> tuple[dict[int, dict[str, object]], list[dict[str, object]], list[str]]:
    canonical_map, stance_map = action_semantics()
    validity = read_validity_ledger()
    root = TrieNode()
    unaligned = []
    for machine in sorted(machines, key=lambda item: item.kind):
        paths = accepting_paths(machine)
        if not paths:
            unaligned.append(machine.kind)
            continue
        for transition_path in paths:
            canonical_path = tuple(
                canonical_map.get((family, machine.kind, action), action)
                for _before, action, _after in transition_path
            )
            node = root
            for (before, local_action, after), action in zip(transition_path, canonical_path):
                node.edge_kinds[action].add(machine.kind)
                validity_row = validity.get(
                    (family, machine.kind, local_action, before, after)
                )
                stance = stance_map.get(action, "neutral")
                if stance == "deforming" and validity_row is None:
                    raise ValueError(
                        f"deforming composite edge lacks validity row: "
                        f"{family}/{machine.kind}/{before}/{local_action}/{after}"
                    )
                if validity_row is not None:
                    node.edge_validity[action].append(validity_row)
                node = node.children.setdefault(action, TrieNode())
            node.terminal = True

    signatures: dict[tuple[object, ...], int] = {}
    node_ids: dict[int, int] = {}
    next_id = 1

    def intern(node: TrieNode, is_root: bool = False) -> tuple[object, ...]:
        nonlocal next_id
        children = tuple((action, intern(child)) for action, child in sorted(node.children.items()))
        signature: tuple[object, ...] = (node.terminal, children)
        if is_root:
            node_ids[id(node)] = 0
        else:
            if signature not in signatures:
                signatures[signature] = next_id
                next_id += 1
            node_ids[id(node)] = signatures[signature]
        return signature

    intern(root, True)
    nodes: dict[int, dict[str, object]] = {0: {"terminal": root.terminal}}
    edges: dict[tuple[int, str, int], dict[str, object]] = {}

    def collect(node: TrieNode) -> None:
        source = node_ids[id(node)]
        nodes.setdefault(source, {"terminal": node.terminal})
        nodes[source]["terminal"] = bool(nodes[source]["terminal"] or node.terminal)
        for action, child in sorted(node.children.items()):
            target = node_ids[id(child)]
            nodes.setdefault(target, {"terminal": child.terminal})
            edge = edges.setdefault(
                (source, action, target), {"kinds": set(), "validity": []}
            )
            edge["kinds"].update(node.edge_kinds[action])
            edge["validity"].extend(node.edge_validity[action])
            collect(child)

    collect(root)
    rendered_edges = [
        {"source": source, "action": action, "target": target,
         "kinds": tuple(sorted(values["kinds"])),
         "stance": stance_map.get(action, "neutral"),
         "validity_rows": tuple(values["validity"])}
        for (source, action, target), values in sorted(edges.items())
    ]
    return nodes, rendered_edges, unaligned


def render_composite(family: str, machines: list[Machine], colors: dict[str, str] | None = None) -> tuple[str, tuple[str, ...]]:
    colors = colors or palette()
    nodes, edges, unaligned = composite_graph(family, machines)
    adjacency: dict[int, list[int]] = defaultdict(list)
    indegree: Counter[int] = Counter()
    for edge in edges:
        source, target = int(edge["source"]), int(edge["target"])
        adjacency[source].append(target)
        indegree[target] += 1
    depth = {0: 0}
    queue = deque([0])
    while queue:
        source = queue.popleft()
        for target in adjacency.get(source, []):
            candidate = depth[source] + 1
            if candidate > depth.get(target, -1):
                depth[target] = candidate
                queue.append(target)
    max_layer = max(depth.values(), default=0)
    kind_order = {
        machine.kind: index
        for index, machine in enumerate(sorted(machines, key=lambda item: item.kind))
    }
    node_kinds: dict[int, set[str]] = defaultdict(set)
    for edge in edges:
        source, target = int(edge["source"]), int(edge["target"])
        node_kinds[source].update(edge["kinds"])
        node_kinds[target].update(edge["kinds"])
    node_kinds[0].update(kind_order)
    row_gap = 74.0
    top = 76.0
    layout_width = max(1080, 230 + max_layer * 250)
    height = max(390, int(top * 2 + max(1, len(kind_order) - 1) * row_gap))
    positions = {}
    for node in nodes:
        ranks = [kind_order[kind] for kind in node_kinds[node] if kind in kind_order]
        average_rank = sum(ranks) / len(ranks) if ranks else 0.0
        x = 82 + depth.get(node, 0) * ((layout_width - 164) / max(1, max_layer))
        y = top + average_rank * row_gap
        positions[node] = (x, y)
    outdegree = Counter(int(edge["source"]) for edge in edges)
    stance_colors = {"conserving": colors["ink"], "neutral": colors["muted"]}
    right_extents = [x + 16 for x, _y in positions.values()]
    body = ["  <defs>"]
    for stance, color in stance_colors.items():
        body.append(f'    <marker id="composite-{stance}" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto"><path d="M0 0 L10 5 L0 10 z" fill="{color}"/></marker>')
    body.append(f'    <marker id="composite-validity-blue" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto"><path d="M0 0 L10 5 L0 10 z" fill="{colors["validity-blue"]}"/></marker>')
    body.append(f'    <marker id="composite-validity-rust" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto"><path d="M0 0 L10 5 L0 10 z" fill="{colors["rust"]}"/></marker>')
    body.append(f'    <marker id="composite-validity-rust-mixed" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="4.5" markerHeight="4.5" orient="auto"><path d="M0 0 L10 5 L0 10 z" fill="{colors["rust"]}"/></marker>')
    body.append("  </defs>")
    rust_overlays: list[tuple[str, bool, str]] = []
    target_modes: dict[int, set[str]] = defaultdict(set)
    for edge in edges:
        source, target = int(edge["source"]), int(edge["target"])
        x1, y1 = positions[source]; x2, y2 = positions[target]
        sx, tx = x1 + 18, x2 - 22
        mx = (sx + tx) / 2
        path = f"M {sx:.1f} {y1:.1f} C {mx:.1f} {y1:.1f}, {mx:.1f} {y2:.1f}, {tx:.1f} {y2:.1f}"
        validity_rows = tuple(edge["validity_rows"])
        stance = str(edge["stance"])
        if stance == "deforming":
            if not validity_rows:
                raise ValueError(f"deforming composite action lacks validity rows: {family}/{edge['action']}")
            render_blue = any(
                row["review_status"] not in UNREVIEWED_STATUSES
                and "context_sensitive_or_inefficient" in row["validity_modes"]
                for row in validity_rows
            )
            render_rust = any(
                row["review_status"] in UNREVIEWED_STATUSES
                or "objective_invalid" in row["validity_modes"]
                for row in validity_rows
            )
            status_text = ", ".join(sorted({str(row["review_status"]) for row in validity_rows}))
            mode_text = ", ".join(sorted({
                str(mode) for row in validity_rows for mode in row["validity_modes"]
            }))
            title = (
                f'{esc(edge["action"])}: {esc(", ".join(edge["kinds"]))}; '
                f'modes {esc(mode_text)}; review status {esc(status_text)}'
            )
            color = colors["validity-blue"] if render_blue else colors["rust"]
            if render_blue:
                body.append(
                    f'  <path class="validity-blue-base" d="{path}" fill="none" '
                    f'stroke="{colors["validity-blue"]}" stroke-width="{3.2 if render_rust else 2.5}" '
                    f'stroke-linecap="round" marker-end="url(#composite-validity-blue)"><title>{title}</title></path>'
                )
                target_modes[target].add("blue")
            if render_rust:
                rust_overlays.append((path, render_blue, title))
                target_modes[target].add("rust")
        else:
            color = stance_colors[stance]
            body.append(
                f'  <path d="{path}" fill="none" stroke="{color}" stroke-width="2.2" '
                f'stroke-linecap="round" marker-end="url(#composite-{stance})"><title>'
                f'{esc(edge["action"])}: {esc(", ".join(edge["kinds"]))}</title></path>'
            )
        action_lines = wrap_atom(str(edge["action"]), 20)
        # Put labels at the destination lane, not halfway through a fan-out.
        # This keeps the authored kind names separated at large branch points.
        label_y = y2
        label_width = min(
            164,
            max(64, max(estimated_text_width(line, 8.5) for line in action_lines) + 12),
        )
        label_height = len(action_lines) * 10 + 8
        right_extents.append(mx + label_width / 2)
        body.append(
            f'  <rect x="{mx-label_width/2:.1f}" y="{label_y-label_height/2:.1f}" '
            f'width="{label_width:.1f}" height="{label_height:.1f}" rx="4" fill="{colors["paper"]}" '
            f'fill-opacity="0.94" stroke="{colors["surface"]}" stroke-width="0.8"/>'
        )
        first_y = label_y - (len(action_lines) - 1) * 5 + 3
        for i, line in enumerate(action_lines):
            body.append(svg_text(mx, first_y + i * 10, line, color, 8.5))
            right_extents.append(text_right_edge(mx, line, 8.5))
        if outdegree[source] > 1:
            kind_lines = []
            current = ""
            for kind in edge["kinds"]:
                candidate = f"{current}, {kind}" if current else str(kind)
                if current and len(candidate) > 38:
                    kind_lines.append(current); current = str(kind)
                else:
                    current = candidate
            if current:
                kind_lines.append(current)
            for i, line in enumerate(kind_lines):
                body.append(svg_text(mx, label_y + label_height / 2 + 10 + i * 9, line, colors["muted"], 7.2))
                right_extents.append(text_right_edge(mx, line, 7.2))
    for node, (x, y) in sorted(positions.items()):
        terminal = bool(nodes[node].get("terminal"))
        body.append(f'  <circle cx="{x:.1f}" cy="{y:.1f}" r="16" fill="{colors["surface"]}" stroke="{colors["ink"]}" stroke-width="2"/>')
        if terminal:
            body.append(f'  <circle cx="{x:.1f}" cy="{y:.1f}" r="11" fill="none" stroke="{colors["ink"]}" stroke-width="1.2"/>')
        node_label = "start" if node == 0 else f"p{node}"
        body.append(svg_text(x, y + 3, node_label, colors["ink"], 8))
        right_extents.append(text_right_edge(x, node_label, 8))
    for path, mixed, title in rust_overlays:
        body.append(
            f'  <path class="validity-rust-overlay" d="{path}" fill="none" '
            f'stroke="{colors["rust"]}" stroke-width="{1.4 if mixed else 2.2}" '
            f'stroke-linecap="round" marker-end="url(#composite-validity-rust{ "-mixed" if mixed else "" })">'
            f'<title>{title}</title></path>'
        )
    ring_radius = 20.5
    for node, modes in sorted(target_modes.items()):
        x, y = positions[node]
        if modes == {"blue"}:
            body.append(f'  <circle class="validity-blue-ring" cx="{x:.1f}" cy="{y:.1f}" r="{ring_radius:.1f}" fill="none" stroke="{colors["validity-blue"]}" stroke-width="1.5"/>')
        elif modes == {"rust"}:
            body.append(f'  <circle class="validity-rust-ring" cx="{x:.1f}" cy="{y:.1f}" r="{ring_radius:.1f}" fill="none" stroke="{colors["rust"]}" stroke-width="1.5"/>')
        else:
            body.append(f'  <path class="validity-blue-ring" d="M {x-ring_radius:.1f} {y:.1f} A {ring_radius:.1f} {ring_radius:.1f} 0 0 1 {x+ring_radius:.1f} {y:.1f}" fill="none" stroke="{colors["validity-blue"]}" stroke-width="1.7"/>')
            body.append(f'  <path class="validity-rust-ring" d="M {x+ring_radius:.1f} {y:.1f} A {ring_radius:.1f} {ring_radius:.1f} 0 0 1 {x-ring_radius:.1f} {y:.1f}" fill="none" stroke="{colors["rust"]}" stroke-width="1.7"/>')
    width = math.ceil(max(right_extents, default=layout_width) + 82)
    desc = (
        f"The {family} family path composite contains the action paths of all the family's "
        "automata, merged at shared prefixes and identical suffixes. Path points are not states "
        "of any single automaton. Loops are not unfolded."
    )
    return svg_document(f"{family} family path composite", desc, width, height, body, colors), tuple(unaligned)


@lru_cache(maxsize=1)
def composite_records() -> dict[str, tuple[str, tuple[str, ...]]]:
    grouped: dict[str, list[Machine]] = defaultdict(list)
    for machine in parse_transition_tables():
        grouped[machine.family].append(machine)
    colors = palette()
    return {family: render_composite(family, machines, colors) for family, machines in sorted(grouped.items())}


def render_all() -> dict[Path, str]:
    rendered = {
        Path(family) / f"{kind}{SCENE_SUFFIX}": record.svg
        for (family, kind), record in scene_records().items() if record.svg is not None
    }
    rendered.update({Path(family) / COMPOSITE_FILENAME: svg for family, (svg, _unaligned) in composite_records().items()})
    return rendered


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
    expected = set(rendered)
    existing = (
        {path.relative_to(args.output_dir) for path in args.output_dir.glob("*/*.svg")
         if path.name.endswith(SCENE_SUFFIX) or path.name == COMPOSITE_FILENAME}
        if args.output_dir.exists() else set()
    )
    unexpected = sorted(existing - expected)
    if args.check:
        failures.extend(str(args.output_dir / path) for path in unexpected)
        if failures:
            for failure in failures:
                print(f"stale or unexpected context SVG: {failure}", file=sys.stderr)
            return 1
    coverage = Counter(record.family for record in scene_records().values() if record.svg)
    totals = Counter(record.family for record in scene_records().values())
    for family in sorted(totals):
        print(f"{family}: scenes {coverage[family]}/{totals[family]}; composite 1")
    print(f"context SVGs: {sum(coverage.values())} scenes + {len(composite_records())} composites")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
