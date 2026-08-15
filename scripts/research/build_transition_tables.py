#!/usr/bin/env python3
"""Build evidence-bearing transition tables from Hermes action automata.

The source registry is deliberately parsed rather than loaded: this builder
records source locations and does not execute arbitrary learner inputs.  The
action-pair trace lists provide the static transition sequence.  Comparison
machines retain their authored q_-state labels from ``hist/2`` traces.
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
import tempfile
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
REGISTRY = ROOT / "knowledge/strategies/math/action_automata_registry.pl"
PAIR_DIR = ROOT / "knowledge/strategies/math"
OUT_DIR = ROOT / "knowledge/strategies/transition_tables"

SIGNATURE = re.compile(
    r"action_automaton_signature\(\s*([a-z][a-z0-9_]*)\s*,\s*"
    r"([a-z][a-z0-9_]*)\s*,",
    re.MULTILINE,
)
RUNNER = re.compile(
    r"^\s*(run_[a-z0-9_]+)\(\s*([a-z][a-z0-9_]*)\s*,", re.MULTILINE
)
ELABORATES = re.compile(r"elaborates\((smr_[a-z0-9_]+):(run_[a-z0-9_]+)/")
HIST = re.compile(r"hist\((q_[a-z0-9_]+)\s*,\s*([a-z][a-z0-9_]*)")


CONTRACTS = ROOT / "knowledge/strategies/automaton_input_contracts.pl"
CONTRACT = re.compile(
    r"automaton_input_contract\(\s*([a-z][a-z0-9_]*)\s*,\s*"
    r"([a-z][a-z0-9_]*)\s*,\s*'((?:\\.|[^'])*)'\s*,\s*"
    r"'((?:\\.|[^'])*)'\s*,\s*verified\(([^)]*)\)\)\.",
    re.MULTILINE,
)
OBSERVED_TIMEOUT_SECONDS = 2


@dataclass(frozen=True)
class Table:
    operation: str
    kind: str
    states: tuple[str, ...]
    actions: tuple[str, ...]
    transitions: tuple[tuple[str, str, str, str], ...]
    source: str


@dataclass(frozen=True)
class Contract:
    operation: str
    kind: str
    example: dict[str, object]


@dataclass(frozen=True)
class Observation:
    operation: str
    kind: str
    source: str
    actions: tuple[str, ...]
    status: str
    reason: str = ""


def line_at(text: str, offset: int) -> int:
    return text.count("\n", 0, offset) + 1


def balanced_list(text: str, start: int) -> tuple[str, int] | None:
    """Return the bracketed list beginning at start, respecting quoted atoms."""
    if start >= len(text) or text[start] != "[":
        return None
    depth, quote = 0, False
    for pos in range(start, len(text)):
        char = text[pos]
        if char == "'":
            quote = not quote
        elif not quote and char == "[":
            depth += 1
        elif not quote and char == "]":
            depth -= 1
            if depth == 0:
                return text[start + 1 : pos], pos + 1
    return None


def top_level_terms(body: str) -> list[str]:
    parts: list[str] = []
    start = 0
    stack: list[str] = []
    quote = False
    pairs = {"(": ")", "[": "]", "{": "}"}
    for pos, char in enumerate(body):
        if char == "'":
            quote = not quote
        elif not quote and char in pairs:
            stack.append(pairs[char])
        elif not quote and stack and char == stack[-1]:
            stack.pop()
        elif not quote and not stack and char == ",":
            parts.append(body[start:pos].strip())
            start = pos + 1
    tail = body[start:].strip()
    return parts + ([tail] if tail else [])


def functor(term: str) -> str | None:
    match = re.match(r"\s*([a-z][a-z0-9_]*)", term)
    return match.group(1) if match else None


def table_from_trace(operation: str, kind: str, body: str, source: str) -> Table | None:
    labels = [label for label in map(functor, top_level_terms(body)) if label]
    if not labels:
        return None
    states = tuple(["q_start", *(f"q_step_{number}" for number in range(1, len(labels))), "q_accept"])
    transitions = tuple(
        (states[index], label, states[index + 1], source)
        for index, label in enumerate(labels)
    )
    return Table(operation, kind, states, tuple(labels), transitions, source)


def table_from_history(operation: str, kind: str, body: str, source: str) -> Table | None:
    entries = HIST.findall(body)
    ordered: list[tuple[str, str]] = []
    for entry in entries:
        if entry not in ordered:
            ordered.append(entry)
    if len(ordered) < 2:
        return None
    states = tuple(state for state, _ in ordered)
    transitions = tuple(
        (states[index], action, states[index + 1], source)
        for index, (_, action) in enumerate(ordered[:-1])
    )
    return Table(operation, kind, states, tuple(action for _, action in ordered[:-1]), transitions, source)


def source_clauses(path: Path) -> dict[str, tuple[Path, str, int, str, str | None]]:
    """Index static trace lists by strategy kind in one action-pair source."""
    text = path.read_text(encoding="utf-8")
    matches = list(RUNNER.finditer(text))
    found: dict[str, tuple[Path, str, int, str, str | None]] = {}
    for index, match in enumerate(matches):
        end = matches[index + 1].start() if index + 1 < len(matches) else len(text)
        clause = text[match.start() : end]
        trace_match = re.search(r"\bTrace\s*=\s*\[", clause)
        trace = None
        if trace_match:
            list_start = match.start() + trace_match.end() - 1
            trace = balanced_list(text, list_start)
        elaborates = ELABORATES.search(clause)
        found[match.group(2)] = (path,
            text,
            match.start(),
            trace[0] if trace else "",
            f"{elaborates.group(1)}:{elaborates.group(2)}" if elaborates else None,
        )
    return found


def comparison_history(module: str, predicate: str) -> tuple[str, int, str] | None:
    path = PAIR_DIR / f"{module}.pl"
    if not path.exists():
        return None
    text = path.read_text(encoding="utf-8")
    match = re.search(rf"^\s*{re.escape(predicate)}\(", text, re.MULTILINE)
    if not match:
        return None
    # Stop at the next exported run predicate. This keeps q-state collection
    # local to the requested comparison routine even when it assembles history
    # through several list fragments.
    next_match = re.search(r"^\s*run_[a-z0-9_]+\(", text[match.end() :], re.MULTILINE)
    end = match.end() + next_match.start() if next_match else len(text)
    return text, match.start(), text[match.start() : end]


def prolog_atom(value: str) -> str:
    if re.fullmatch(r"[a-z][a-z0-9_]*", value):
        return value
    escaped = value.replace("\\", "\\\\").replace("'", "\\'")
    return f"'{escaped}'"


def render_table(table: Table) -> str:
    states = ", ".join(prolog_atom(state) for state in table.states)
    actions = ", ".join(prolog_atom(action) for action in table.actions)
    lines = [
        f"automaton_tuple({table.operation}, {table.kind}, states([{states}]), "
        f"actions([{actions}]), start({table.states[0]}), accepting([{table.states[-1]}]))."
    ]
    for before, action, after, source in table.transitions:
        lines.append(
            f"automaton_transition({table.operation}, {table.kind}, {before}, {action}, {after}, "
            f"provenance(static('{source}')))."
        )
    return "\n".join(lines)


def render_tuple(table: Table) -> str:
    states = ", ".join(prolog_atom(state) for state in table.states)
    actions = ", ".join(prolog_atom(action) for action in table.actions)
    return (
        f"automaton_tuple({table.operation}, {table.kind}, states([{states}]), "
        f"actions([{actions}]), start({table.states[0]}), accepting([{table.states[-1]}]))."
    )


def render_transitions(table: Table) -> str:
    return "\n".join(
        f"automaton_transition({table.operation}, {table.kind}, {before}, {action}, {after}, "
        f"provenance(static('{source}')))."
        for before, action, after, source in table.transitions
    )


def contracts() -> list[Contract]:
    """Read checked JSON examples without loading the contracts module."""
    found: list[Contract] = []
    for operation, kind, _schema, example, _verification in CONTRACT.findall(
        CONTRACTS.read_text(encoding="utf-8")
    ):
        found.append(Contract(operation, kind, json.loads(example.replace(r'\"', '"'))))
    return found


def prolog_number(value: object) -> str:
    assert isinstance(value, (int, float)) and not isinstance(value, bool)
    return repr(value)


def prolog_list(values: object, encode=prolog_number) -> str:
    assert isinstance(values, list)
    return f"[{','.join(encode(value) for value in values)}]"


def prolog_expression(expression: object) -> str:
    assert isinstance(expression, dict)
    node = expression["node"]
    if node == "int":
        return f"int({prolog_number(expression['value'])})"
    if node == "var":
        return f"var({prolog_atom(str(expression['name']))})"
    if node in {"add", "mult"}:
        return (
            f"{node}({prolog_expression(expression['left'])},"
            f"{prolog_expression(expression['right'])})"
        )
    if node == "power":
        return (
            f"power({prolog_expression(expression['base'])},"
            f"{prolog_number(expression['exponent'])})"
        )
    raise ValueError(f"unsupported algebraic expression node: {node!r}")


def prolog_assignment(assignment: object) -> str:
    assert isinstance(assignment, dict)
    return (
        f"var({prolog_atom(str(assignment['variable']))})="
        f"int({prolog_number(assignment['value'])})"
    )


def prolog_point(point: object) -> str:
    assert isinstance(point, dict)
    return f"{prolog_number(point['x'])}-{prolog_number(point['y'])}"


def prolog_coordinate_point(point: object) -> str:
    assert isinstance(point, dict)
    return f"point({prolog_number(point['x'])},{prolog_number(point['y'])})"


def prolog_prism(prism: object) -> str:
    assert isinstance(prism, dict)
    return (
        f"prism({prolog_number(prism['length'])},{prolog_number(prism['width'])},"
        f"{prolog_number(prism['height'])})"
    )


def prolog_fraction_addend(addend: object) -> str:
    assert isinstance(addend, dict)
    if "whole" in addend and "n" in addend:
        return (
            f"mixed({prolog_number(addend['whole'])},{prolog_number(addend['n'])},"
            f"{prolog_number(addend['d'])})"
        )
    if "n" in addend:
        return f"frac({prolog_number(addend['n'])},{prolog_number(addend['d'])})"
    return f"whole({prolog_number(addend['whole'])})"


def prolog_diagram_expression(expression: object) -> str:
    assert isinstance(expression, dict)
    node = expression["node"]
    if node == "var":
        return f"var({prolog_atom(str(expression['name']))})"
    if node == "number":
        return f"number({prolog_number(expression['value'])})"
    if node == "add":
        return (
            f"add({prolog_diagram_expression(expression['left'])},"
            f"{prolog_diagram_expression(expression['right'])})"
        )
    raise ValueError(f"unsupported diagram expression node: {node!r}")


def prolog_signed_variable_item(item: object) -> str:
    assert isinstance(item, dict)
    operation = str(item["operation"])
    if operation not in {"add", "subtract"}:
        raise ValueError(f"unsupported signed-linear operation: {operation!r}")
    return (
        f"{operation}(term({prolog_number(item['coefficient'])},"
        f"var({prolog_atom(str(item['variable']))})))"
    )


def prolog_signed_constant_item(item: object) -> str:
    assert isinstance(item, dict)
    operation = str(item["operation"])
    if operation not in {"add", "subtract"}:
        raise ValueError(f"unsupported signed-linear operation: {operation!r}")
    return f"{operation}(constant({prolog_number(item['value'])}))"


def prolog_input(example: dict[str, object]) -> tuple[str, str]:
    """Mirror hermes_encyclopedia:trace_inputs/3 for checked examples."""
    kind = example.get("kind")
    if kind == "signed_subtraction":
        return (
            f"minuend({prolog_number(example['minuend'])})",
            f"subtrahend({prolog_number(example['subtrahend'])})",
        )
    if kind == "signed_multiplication":
        return (
            f"multiplier({prolog_number(example['multiplier'])})",
            f"multiplicand({prolog_number(example['multiplicand'])})",
        )
    if kind == "signed_division":
        return (
            f"dividend({prolog_number(example['dividend'])})",
            f"divisor({prolog_number(example['divisor'])})",
        )
    if kind == "ratio_pair_unit_rate":
        return (
            f"ratio_pair({prolog_number(example['first'])},"
            f"{prolog_number(example['second'])})",
            f"unit_rate({prolog_atom(str(example['referent']))})",
        )
    if kind == "ratio_pairs_proportionality_test":
        pairs = example["pairs"]
        assert isinstance(pairs, list)
        encoded_pairs = prolog_list(
            pairs,
            lambda pair: (
                f"ratio_pair({prolog_number(pair['first'])},"
                f"{prolog_number(pair['second'])})"
                if isinstance(pair, dict) else ""
            ),
        )
        return f"ratio_pairs({encoded_pairs})", "proportionality_test"
    if kind == "ratio_pair_solve_at_x":
        return (
            f"ratio_pair({prolog_number(example['first'])},"
            f"{prolog_number(example['second'])})",
            f"solve_at_x({prolog_number(example['target_x'])})",
        )
    if kind == "circle_co_measurement":
        pi_value = example["pi"]
        assert isinstance(pi_value, dict)
        given = str(example["given_measure"])
        requested = str(example["requested_measure"])
        if (given, requested) == ("diameter", "circumference"):
            request = "circumference_with_pi"
        elif (given, requested) == ("circumference", "diameter"):
            request = "diameter_with_pi"
        else:
            raise ValueError(
                f"unsupported circle co-measurement direction: {given!r}/{requested!r}"
            )
        return (
            f"circle_measure({prolog_atom(given)},{prolog_number(example['value'])},"
            f"{prolog_atom(str(example['unit']))})",
            f"{request}(rational({prolog_number(pi_value['n'])},"
            f"{prolog_number(pi_value['d'])}))",
        )
    if kind == "triangle_conditions":
        condition = str(example["condition"])
        if condition not in {"sss", "sas", "asa", "aas", "ssa", "aaa"}:
            raise ValueError(f"unsupported triangle condition: {condition!r}")
        measures = example["measures"]
        assert isinstance(measures, list) and len(measures) == 3
        return (
            f"triangle_conditions({condition}({','.join(prolog_number(value) for value in measures)}))",
            "classify",
        )
    if kind == "angle_relation":
        return (
            f"angle_relation(whole({prolog_number(example['whole'])}),"
            f"known_parts({prolog_list(example['known_parts'])}))",
            f"unknown({prolog_atom(str(example['unknown']))})",
        )
    if kind == "frequency_record":
        return (
            f"frequency_record({prolog_atom(str(example['event']))},"
            f"{prolog_number(example['successes'])},"
            f"{prolog_number(example['trials'])})",
            "estimate_context(repeated_experiment)",
        )
    if kind == "sample_population_distribution":
        sample = example["sample"]
        population = example["population"]
        tolerances = example["tolerances"]
        assert isinstance(sample, dict)
        assert isinstance(population, dict)
        assert isinstance(tolerances, dict)
        return (
            f"sample({prolog_list(sample['values'])},"
            f"shape({prolog_atom(str(sample['shape']))}))",
            f"population({prolog_list(population['values'])},"
            f"shape({prolog_atom(str(population['shape']))}),"
            f"tolerances(center({prolog_number(tolerances['center'])}),"
            f"spread({prolog_number(tolerances['spread'])})))",
        )
    if kind == "diagram_relation":
        return (
            f"diagram({prolog_atom(str(example['representation']))},"
            f"equal_groups({prolog_number(example['groups'])},"
            f"{prolog_diagram_expression(example['group_expression'])}),"
            f"additional(number({prolog_number(example['additional'])})),"
            f"total(number({prolog_number(example['total'])})))",
            f"equation_form({prolog_atom(str(example['equation_form']))})",
        )
    if kind == "percent_change":
        amount_role = str(example["amount_role"])
        if amount_role not in {"original_amount", "changed_amount"}:
            raise ValueError(f"unsupported percent-change amount role: {amount_role!r}")
        return (
            f"percent_change({amount_role}({prolog_number(example['amount'])}),"
            f"rate_percent({prolog_number(example['rate_percent'])}),"
            f"direction({prolog_atom(str(example['direction']))}))",
            f"target({prolog_atom(str(example['target']))})",
        )
    if kind == "signed_linear_expression":
        variable_terms = prolog_list(
            example["variable_terms"], prolog_signed_variable_item
        )
        constant_terms = prolog_list(
            example["constant_terms"], prolog_signed_constant_item
        )
        items = variable_terms[:-1] + (
            "," if variable_terms != "[]" and constant_terms != "[]" else ""
        ) + constant_terms[1:]
        return (
            f"signed_linear_expression({items})",
            "rewrite_direction(combine_like_terms)",
        )
    if kind == "decimal_unit_conversion":
        return (
            f"decimal_unit_conversion({prolog_number(example['count'])},"
            f"{prolog_number(example['from_scale'])},{prolog_number(example['to_scale'])})",
            "ignored",
        )
    if kind == "signed_number_list":
        return prolog_list(example["values"]), "number_line"
    if kind == "inequality":
        return (
            f"inequality({prolog_atom(str(example['variable']))},"
            f"{prolog_atom(str(example['relation']))},{prolog_number(example['bound'])})",
            "number_line",
        )
    if kind == "referent_pair":
        first = example["first"]
        second = example["second"]
        assert isinstance(first, dict) and isinstance(second, dict)
        return (
            f"referent({prolog_atom(str(first['label']))},{prolog_number(first['count'])})",
            f"referent({prolog_atom(str(second['label']))},{prolog_number(second['count'])})",
        )
    if kind == "measure_with_unit":
        return (
            f"measure({prolog_number(example['interval_count'])},"
            f"{prolog_number(example['subdivisions'])})",
            f"unit({prolog_atom(str(example['unit']))})",
        )
    if kind == "quantity_conversion":
        return (
            f"quantity({prolog_number(example['count'])},"
            f"{prolog_atom(str(example['from_unit']))})",
            f"conversion({prolog_atom(str(example['to_unit']))},"
            f"{prolog_number(example['factor'])})",
        )
    if kind == "measured_change":
        return (
            f"measured_change({prolog_atom(str(example['operation']))},"
            f"{prolog_number(example['a'])},{prolog_number(example['b'])},"
            f"{prolog_atom(str(example['unit']))})",
            "ignored",
        )

    if kind == "categorical_frequencies":
        pairs = example["pairs"]
        assert isinstance(pairs, list)
        encoded_pairs = prolog_list(
            pairs,
            lambda pair: (
                f"{prolog_atom(str(pair['category']))}-{prolog_number(pair['count'])}"
                if isinstance(pair, dict) else ""
            ),
        )
        return encoded_pairs, "display(bar_chart)"
    if kind == "numeric_data_display":
        return prolog_list(example["values"]), "display(dot_plot)"
    if kind == "statistical_question":
        return (
            f"question({prolog_atom(str(example['variable']))},expects_variability)",
            f"population({prolog_atom(str(example['population']))})",
        )
    if kind == "histogram_data":
        return (
            prolog_list(example["values"]),
            f"display(histogram({prolog_number(example['bin_width'])}))",
        )
    if kind == "numeric_data_with_unit":
        return (
            prolog_list(example["values"]),
            f"measurement_unit({prolog_atom(str(example['unit']))})",
        )
    if kind == "box_plot_data":
        return prolog_list(example["values"]), "display(box_plot)"
    if kind == "distribution_data":
        return (
            prolog_list(example["values"]),
            f"distribution({prolog_atom(str(example['profile']))})",
        )

    if kind in {"covered_cells", "placed_tiles"}:
        return (
            f"{kind}({prolog_list(example['cells'], prolog_point)})",
            f"unit({prolog_atom(str(example['unit']))})",
        )
    if kind == "area_unit_candidates":
        candidates = example["candidates"]
        assert isinstance(candidates, list)
        encoded_candidates = prolog_list(
            candidates,
            lambda candidate: (
                f"unit({prolog_atom(str(candidate['unit']))},"
                f"{prolog_atom(str(candidate['extent']))})"
                if isinstance(candidate, dict) else ""
            ),
        )
        return (
            f"area_extent({prolog_atom(str(example['extent']))})",
            f"candidates({encoded_candidates})",
        )
    if kind == "rectangle_with_unit":
        return (
            f"rectangle({prolog_number(example['length'])},{prolog_number(example['width'])})",
            f"unit({prolog_atom(str(example['unit']))})",
        )
    if kind == "polygon_sides_with_unit":
        return (
            f"sides({prolog_list(example['sides'])})",
            f"unit({prolog_atom(str(example['unit']))})",
        )
    if kind == "symmetry_side_orbits":
        known_orbits = example["known_orbits"]
        unknown_orbit = example["unknown_orbit"]
        assert isinstance(known_orbits, list) and isinstance(unknown_orbit, dict)
        encoded_orbits = [
            f"orbit({prolog_number(orbit['copies'])},known({prolog_number(orbit['length'])}))"
            for orbit in known_orbits if isinstance(orbit, dict)
        ]
        encoded_orbits.append(
            f"orbit({prolog_number(unknown_orbit['copies'])},"
            f"unknown({prolog_atom(str(unknown_orbit['name']))}))"
        )
        return (
            f"side_orbits([{','.join(encoded_orbits)}])",
            f"perimeter({prolog_number(example['perimeter'])},"
            f"{prolog_atom(str(example['unit']))})",
        )
    if kind == "perimeter_scope":
        return (
            prolog_number(example["perimeter"]),
            f"side_scope({prolog_atom(str(example['scope']))})",
        )
    if kind == "perimeter_known_side":
        return (
            f"perimeter({prolog_number(example['perimeter'])})",
            f"known_side({prolog_number(example['known_side'])})",
        )
    if kind == "area_scope":
        return (
            prolog_number(example["area"]),
            f"factor_scope({prolog_atom(str(example['scope']))})",
        )
    if kind == "rectangle_constraints":
        return (
            f"constraints(area({prolog_number(example['area'])}),"
            f"perimeter({prolog_number(example['perimeter'])}))",
            "constraint_scope(all)",
        )
    if kind == "area_known_side":
        return (
            f"area({prolog_number(example['area'])})",
            f"known_side({prolog_number(example['known_side'])})",
        )
    if kind == "rectangular_prism":
        return (
            f"prism({prolog_number(example['length'])},{prolog_number(example['width'])})",
            prolog_number(example["height"]),
        )
    if kind == "volume_known_base":
        return (
            f"volume({prolog_number(example['volume'])})",
            f"known_base({prolog_number(example['length'])},{prolog_number(example['width'])})",
        )
    if kind == "disjoint_prisms":
        return (
            f"certified_disjoint_prisms({prolog_list(example['prisms'], prolog_prism)})",
            f"unit({prolog_atom(str(example['unit']))})",
        )
    if kind == "overlapping_prisms":
        return (
            f"overlapping_prisms({prolog_list(example['prisms'], prolog_prism)},"
            f"{prolog_number(example['overlap_volume'])})",
            f"unit({prolog_atom(str(example['unit']))})",
        )
    if kind == "coordinate_points":
        return prolog_list(example["points"], prolog_coordinate_point), "axes(cartesian)"
    if kind == "coordinate_point_pair":
        return (
            f"points({prolog_coordinate_point(example['first'])},"
            f"{prolog_coordinate_point(example['second'])})",
            f"unit({prolog_atom(str(example['unit']))})",
        )
    if kind == "polygon_partition":
        pieces = example["pieces"]
        assert isinstance(pieces, list)
        encoded_pieces = prolog_list(
            pieces, lambda piece: prolog_list(piece, prolog_point)
        )
        partition = (
            f"certified_partition({encoded_pieces})"
            if example["certification"] == "certified"
            else f"decomposition({encoded_pieces})"
        )
        return f"polygon({prolog_list(example['vertices'], prolog_point)})", partition
    if kind == "parallelogram_with_unit":
        return (
            f"parallelogram({prolog_number(example['base'])},"
            f"{prolog_number(example['height'])},{prolog_number(example['slanted_side'])},"
            f"{prolog_number(example['offset'])})",
            f"unit({prolog_atom(str(example['unit']))})",
        )
    if kind == "triangle_with_unit":
        return (
            f"triangle({prolog_number(example['base'])},{prolog_number(example['height'])})",
            f"unit({prolog_atom(str(example['unit']))})",
        )
    if kind == "solid_net":
        return (
            f"net({prolog_atom(str(example['solid']))},{prolog_list(example['face_areas'])})",
            f"unit({prolog_atom(str(example['unit']))})",
        )
    if kind == "dimensional_measure":
        return (
            f"measure({prolog_atom(str(example['dimension']))},"
            f"{prolog_number(example['value'])})",
            f"unit({prolog_atom(str(example['unit']))})",
        )
    if kind == "shape_attributes":
        attributes = example["attributes"]
        assert isinstance(attributes, list)
        encoded_attributes = prolog_list(
            attributes,
            lambda attribute: (
                f"{prolog_atom(str(attribute['name']))}({prolog_number(attribute['value'])})"
                if isinstance(attribute, dict) else ""
            ),
        )
        return (
            f"shape({prolog_atom(str(example['shape']))},{encoded_attributes})",
            f"orientation({prolog_number(example['quarter_turns'])})",
        )
    if kind == "angle_measure":
        return prolog_number(example["degrees"]), "unit(degree)"
    if kind == "angle_parts":
        return (
            f"angle_parts({prolog_list(example['parts'])})",
            f"whole_angle({prolog_number(example['whole'])})",
        )
    if kind == "rigid_shape_composition":
        pieces = example["pieces"]
        assert isinstance(pieces, list)
        encoded_pieces = prolog_list(
            pieces,
            lambda piece: (
                f"placed({prolog_atom(str(piece['id']))},"
                f"{prolog_list(piece['cells'], prolog_point)})"
                if isinstance(piece, dict) else ""
            ),
        )
        return (
            f"region({prolog_number(example['columns'])},{prolog_number(example['rows'])})",
            encoded_pieces,
        )
    if kind == "solid_volume_comparison":
        return (
            f"solid_cube_counts({prolog_number(example['count_a'])},"
            f"{prolog_number(example['count_b'])})",
            f"visual_extents({prolog_number(example['extent_a'])},"
            f"{prolog_number(example['extent_b'])})",
        )

    if kind == "expression_assignment":
        return (
            prolog_expression(example["expression"]),
            prolog_list(example["assignments"], prolog_assignment),
        )
    if kind == "linear_context":
        return (
            f"linear_context({prolog_atom(str(example['unknown']))},"
            f"{prolog_number(example['coefficient'])},{prolog_number(example['offset'])},"
            f"{prolog_number(example['total'])},"
            f"{prolog_list(example['referent_roles'], lambda value: prolog_atom(str(value)))})",
            "equation_form(ax_plus_b_equals_c)",
        )
    if kind == "equation_assignment":
        return (
            f"equation({prolog_expression(example['left'])},"
            f"{prolog_expression(example['right'])})",
            prolog_list(example["assignments"], prolog_assignment),
        )
    if kind == "linear_equation":
        return (
            f"linear_equation({prolog_number(example['a'])},{prolog_number(example['b'])},"
            f"{prolog_number(example['c'])})",
            "solution_domain(nonnegative_integer)",
        )
    if kind == "quantity_relation":
        return (
            f"quantity_relation({prolog_atom(str(example['operator']))},"
            f"{prolog_expression(example['left'])},{prolog_expression(example['right'])},"
            f"{prolog_list(example['referent_roles'], lambda value: prolog_atom(str(value)))})",
            f"variable_scope({prolog_list(example['declared_variables'], lambda value: prolog_atom(str(value)))})",
        )
    if kind == "expression_rewrite":
        return (
            prolog_expression(example["expression"]),
            f"rewrite_direction({prolog_atom(str(example['direction']))})",
        )
    if kind == "power_notation":
        return (
            f"power({prolog_expression(example['base'])},{prolog_number(example['exponent'])})",
            "notation(expanded_product)",
        )
    if kind == "expression_pair":
        return (
            f"expression_pair({prolog_expression(example['left'])},"
            f"{prolog_expression(example['right'])})",
            "method(repeated_factor_expansion)",
        )
    if kind == "linear_pattern_context":
        return (
            f"linear_pattern(first({prolog_number(example['first'])}),"
            f"change({prolog_number(example['change'])}),row({prolog_number(example['row'])}))",
            prolog_atom(str(example["context"])),
        )
    if kind == "linear_pattern_empirical_rule":
        return (
            f"linear_pattern(first({prolog_number(example['first'])}),"
            f"change({prolog_number(example['change'])}),row({prolog_number(example['row'])}))",
            f"empirical_rule(multiplier({prolog_number(example['multiplier'])}),"
            f"constant({prolog_number(example['constant'])}),"
            f"checked_rows({prolog_list(example['checked_rows'])}))",
        )

    if kind == "fraction_pair":
        left = example["left"]
        right = example["right"]
        assert isinstance(left, dict) and isinstance(right, dict)
        return (
            f"fraction_pair({left['n']},{left['d']},{right['n']},{right['d']})",
            "unit(whole)",
        )
    if kind in {"fraction_addend_pair", "fraction_minuend_subtrahend"}:
        return (
            f"{kind}({prolog_fraction_addend(example['left'])},"
            f"{prolog_fraction_addend(example['right'])})",
            "unit(whole)",
        )
    if kind == "fraction_solve":
        coefficient = example["coefficient"]
        assert isinstance(coefficient, dict)
        return (
            f"solve({prolog_number(coefficient['n'])},{prolog_number(coefficient['d'])})",
            prolog_number(example["total"]),
        )
    if kind == "rational_limit":
        numerator = example["numerator"]
        denominator = example["denominator"]
        assert isinstance(numerator, dict) and isinstance(denominator, dict)
        return (
            f"rational_expression({prolog_list(numerator['coefficients'])},"
            f"{prolog_list(denominator['coefficients'])})",
            f"limit_at({prolog_number(example['at'])})",
        )
    if kind == "polynomial_limit":
        return (
            f"polynomial({prolog_list(example['coefficients'])})",
            f"limit_at({prolog_number(example['at'])})",
        )
    if kind == "bounded_sequence_limit":
        return (
            "sequence_term("
            f"bounded({prolog_atom(example['numerator'])},{prolog_number(example['bound'])}),"
            f"diverging({prolog_atom(example['denominator'])}))",
            "as_n_to_infinity",
        )
    if kind == "terminal_path_tree":
        paths = example["paths"]
        assert isinstance(paths, list)
        encoded_paths = prolog_list(
            paths,
            lambda path: (
                f"terminal({prolog_atom(str(path['winner']))},"
                f"probability({prolog_number(path['probability']['n'])},"
                f"{prolog_number(path['probability']['d'])}),"
                f"{prolog_list(path['events'], lambda value: prolog_atom(str(value)))})"
                if isinstance(path, dict) and isinstance(path.get("probability"), dict)
                else ""
            ),
        )
        return encoded_paths, f"stake({prolog_number(example['stake'])})"
    if kind == "decimal_pair":
        left = example["left"]
        right = example["right"]
        assert isinstance(left, dict) and isinstance(right, dict)
        return (
            f"decimal_pair({left['numeral']},{left['scale']},{right['numeral']},{right['scale']})",
            "ignored",
        )
    if kind == "count_pair":
        return (
            f"counts({example['left']},{example['right']})",
            f"base({example['base']})",
        )
    if kind == "cardinality":
        return str(example["count"]), f"base({example['base']})"
    if kind == "collection_pair":
        return (
            f"counts({example['left']},{example['right']})",
            f"extents({example['left_extent']},{example['right_extent']})",
        )
    return prolog_number(example["a"]), prolog_number(example["b"])


# Example shapes this extractor can encode as Prolog probe arguments. Task 201
# taught the extractor every structured operand decoded by
# hermes_encyclopedia:trace_inputs/3 on 2026-08-03. Unknown future tags remain
# explicitly skipped with a stderr notice rather than falling through to a/b.
# Tags added in Task 201 receive only their authored contract-example probe:
# derived perturbations add table rows but are not consumed by recognition.
# The five legacy tagged shapes retain their pre-201 perturbations because a
# single contract example does not exercise every runtime branch. In
# particular, the fraction_pair perturbation is the witness for
# benchmark_fraction_comparison's opposite_sides branch.
#
# The three counting shapes entered in 2026-08-01 with their input contracts.
# Until then the eight counting automata carried static provenance only, and
# hermes/strategy_recognizer.pl searches observed transitions alone, so no
# counting automaton could be proposed for any classroom sentence.
ENCODABLE_KINDS = frozenset({
    "signed_subtraction", "signed_multiplication", "signed_division",
    "ratio_pair_unit_rate", "ratio_pairs_proportionality_test",
    "ratio_pair_solve_at_x", "circle_co_measurement",
    "triangle_conditions", "angle_relation", "frequency_record",
    "sample_population_distribution", "diagram_relation",
    "percent_change", "signed_linear_expression",
    "decimal_unit_conversion", "signed_number_list", "inequality",
    "referent_pair", "measure_with_unit", "quantity_conversion",
    "measured_change", "categorical_frequencies", "numeric_data_display",
    "statistical_question", "histogram_data", "numeric_data_with_unit",
    "box_plot_data", "distribution_data", "covered_cells", "placed_tiles",
    "area_unit_candidates", "rectangle_with_unit", "polygon_sides_with_unit",
    "symmetry_side_orbits", "perimeter_scope", "perimeter_known_side",
    "area_scope", "rectangle_constraints", "area_known_side",
    "rectangular_prism", "volume_known_base", "disjoint_prisms",
    "overlapping_prisms", "coordinate_points", "coordinate_point_pair",
    "polygon_partition", "parallelogram_with_unit", "triangle_with_unit",
    "solid_net", "dimensional_measure", "shape_attributes", "angle_measure",
    "angle_parts", "rigid_shape_composition", "solid_volume_comparison",
    "expression_assignment", "linear_context", "equation_assignment",
    "linear_equation", "quantity_relation", "expression_rewrite",
    "power_notation", "expression_pair", "linear_pattern_context",
    "linear_pattern_empirical_rule", "fraction_pair", "fraction_addend_pair",
    "fraction_minuend_subtrahend", "fraction_solve", "rational_limit",
    "polynomial_limit", "bounded_sequence_limit",
    "terminal_path_tree", "decimal_pair", "count_pair", "cardinality",
    "collection_pair",
})

LEGACY_PERTURBED_KINDS = frozenset({
    "fraction_pair", "decimal_pair", "count_pair", "cardinality",
    "collection_pair",
})


# 2026-08-15. A kind tag is not by itself an operand shape. Two families write
# "angle_parts" and mean different objects: the geometry family lists the parts
# it knows under `parts`, and the grade 8 polygon pilot lists them under `known`
# (g8_polygon_angle_and_tessellation.pl:72-78). The encoder below reads `parts`,
# so the tag alone let a grade 8 example in and then raised KeyError on it. The
# tag now has to bring the field the encoder actually reads.
REQUIRED_EXAMPLE_FIELDS = {
    "angle_parts": ("parts",),
}


def encodable(example: dict[str, object]) -> bool:
    """True when prolog_input can handle this example."""
    kind = example.get("kind")
    if kind in ENCODABLE_KINDS:
        required = REQUIRED_EXAMPLE_FIELDS.get(str(kind), ())
        return all(field in example for field in required)
    return kind is None and "a" in example and "b" in example


def derived_example(example: dict[str, object]) -> dict[str, object]:
    """Make a small second probe without changing a contract's input shape."""
    result = json.loads(json.dumps(example))
    if result.get("kind") in {"fraction_pair", "decimal_pair"}:
        left = result["left"]
        assert isinstance(left, dict)
        key = "n" if result["kind"] == "fraction_pair" else "numeral"
        left[key] = int(left[key]) + 1
    elif result.get("kind") == "cardinality":
        result["count"] = int(result["count"]) + 1
    elif result.get("kind") in {"count_pair", "collection_pair"}:
        # Shift the left operand only. The two comparison deformations report a
        # relation exactly when it differs from the productive one, so moving
        # both operands can silently retire the second probe.
        result["left"] = int(result["left"]) + 1
        if result.get("kind") == "collection_pair":
            result["left_extent"] = int(result["left_extent"]) + 1
    else:
        result["a"] = int(result["a"]) + 1
    return result


PROLOG_PROBE = r'''
:- use_module(library(time)).

trace_actions([], []).
trace_actions([hist(_, Step) | Rest], Actions) :- !,
    trace_actions_hist(Rest, Step, Actions).
trace_actions([Step | Rest], [Action | Actions]) :-
    functor(Step, Action, _),
    trace_actions(Rest, Actions).

trace_actions_hist([], _, []).
trace_actions_hist([hist(_, Next) | Rest], Step, [Action | Actions]) :-
    functor(Step, Action, _),
    trace_actions_hist(Rest, Next, Actions).

probe_one(Source, Operation, Kind, Left, Right) :-
    catch(( call_with_time_limit(2,
                                 once(action_automata_registry:run_action_automaton(
                                     Operation, Kind, Left, Right, _Outcome, Trace)))
          -> true ; Trace = failed ),
          time_limit_exceeded, Trace = timeout),
    ( Trace == timeout
    -> Status = timeout, Actions = []
    ; Trace == failed
    -> Status = failed, Actions = []
    ; nonvar(Trace)
    -> Status = observed, trace_actions(Trace, Actions)
    ; Status = failed, Actions = []
    ),
    format('~w|~w|~w|~w|', [Source, Operation, Kind, Status]),
    write_canonical(Actions), nl.

main :- forall(probe(Source, Operation, Kind, Left, Right),
               probe_one(Source, Operation, Kind, Left, Right)).
'''


def observe(checked_contracts: list[Contract]) -> list[Observation]:
    """Run every contract and a bounded derived probe in one SWI process."""
    probes: list[str] = []
    skipped = [c for c in checked_contracts if not encodable(c.example)]
    if skipped:
        kinds = sorted({str(c.example.get("kind")) for c in skipped})
        print(f"skipping {len(skipped)} contract(s) this extractor cannot encode "
              f"as probe arguments; kinds: {', '.join(kinds)}", file=sys.stderr)
    for contract in checked_contracts:
        if not encodable(contract.example):
            continue
        examples = [("contract_example", contract.example)]
        if (contract.example.get("kind") is None
                or contract.example.get("kind") in LEGACY_PERTURBED_KINDS):
            examples.append(("derived_template", derived_example(contract.example)))
        for source, example in examples:
            left, right = prolog_input(example)
            probes.append(
                f"probe({source}, {contract.operation}, {contract.kind}, {left}, {right})."
            )
    with tempfile.TemporaryDirectory(prefix="hermes-transition-observe-") as directory:
        work = Path(directory)
        probe_file = work / "probes.pl"
        runner_file = work / "runner.pl"
        probe_file.write_text("\n".join(probes) + "\n", encoding="utf-8")
        runner_file.write_text(PROLOG_PROBE, encoding="utf-8")
        result = subprocess.run(
            ["swipl", "-q", "-l", "paths.pl", "-l",
             "knowledge/strategies/math/action_automata_registry.pl", "-l",
             str(probe_file), "-l", str(runner_file), "-g", "main", "-t", "halt"],
            cwd=ROOT, text=True, capture_output=True, timeout=180, check=False,
        )
    if result.returncode:
        raise RuntimeError(f"observed runner failed: {result.stderr.strip()}")
    observations: list[Observation] = []
    for line in (line for line in result.stdout.splitlines() if line.count("|") == 4):
        source, operation, kind, status, encoded_actions = line.split("|", 4)
        actions = tuple(re.findall(r"[a-z][a-z0-9_]*", encoded_actions))
        reason = "bounded timeout" if status == "timeout" else "run failed" if status == "failed" else ""
        observations.append(Observation(operation, kind, source, actions, status, reason))
    if len(observations) != len(probes):
        raise RuntimeError(
            "observed runner did not return one result per probe: "
            f"got {len(observations)} of {len(probes)}; stdout={result.stdout!r}; stderr={result.stderr!r}"
        )
    return observations


def render_observed_transitions(table: Table, observation: Observation) -> str:
    """Keep observed source separate from static extraction provenance.

    A reconstructed chain must still root at the signature's own declared
    start and accepting states (``table.states[0]`` / ``table.states[-1]``)
    rather than the literal atoms ``q_start``/``q_accept`` — those only
    coincide with the declared boundary for kinds whose static trace begins
    at ``q_start``. Kinds reconstructed from a comparison automaton's
    ``hist/2`` trace (see ``table_from_history``) declare ``start(q_init)``,
    and a hardcoded ``q_start`` here would silently root the observed rows
    off the declared start, disconnecting them for any consumer that walks
    the automaton from its tuple.
    """
    states = (table.states if observation.actions == table.actions else
              tuple([table.states[0],
                     *(f"q_observed_{n}" for n in range(1, len(observation.actions))),
                     table.states[-1]]))
    return "\n".join(
        f"automaton_transition({table.operation}, {table.kind}, {states[index]}, {action}, {states[index + 1]}, "
        f"provenance(observed({observation.source})))."
        for index, action in enumerate(observation.actions)
    )


def build() -> tuple[list[Table], list[tuple[str, str, str]], Counter[str]]:
    signatures = SIGNATURE.findall(REGISTRY.read_text(encoding="utf-8"))
    clauses: dict[str, tuple[Path, str, int, str, str | None]] = {}
    for path in sorted(PAIR_DIR.glob("*_action_pairs.pl")):
        clauses.update(source_clauses(path))

    tables: list[Table] = []
    skipped: list[tuple[str, str, str]] = []
    routes: Counter[str] = Counter()
    for operation, kind in signatures:
        row = clauses.get(kind)
        if not row:
            skipped.append((operation, kind, "no static action-pair clause"))
            continue
        source_path, text, offset, trace, elaboration = row
        source = f"{source_path.relative_to(ROOT)}:{line_at(text, offset)}"
        table = table_from_trace(operation, kind, trace, source) if trace else None
        if table:
            tables.append(table)
            routes[operation] += 1
            continue
        if elaboration:
            module, predicate = elaboration.split(":", 1)
            history = comparison_history(module, predicate)
            if history:
                history_text, history_offset, body = history
                history_source = f"{(PAIR_DIR / (module + '.pl')).relative_to(ROOT)}:{line_at(history_text, history_offset)}"
                table = table_from_history(operation, kind, body, history_source)
        if table:
            tables.append(table)
            routes[operation] += 1
        else:
            reason = "trace is delegated without a statically readable q-state history" if elaboration else "no static Trace list"
            skipped.append((operation, kind, reason))
    return tables, skipped, routes


def write(tables: list[Table], observations: list[Observation]) -> None:
    if OUT_DIR.exists():
        shutil.rmtree(OUT_DIR)
    OUT_DIR.mkdir(parents=True)
    by_operation: dict[str, list[Table]] = defaultdict(list)
    for table in tables:
        by_operation[table.operation].append(table)
    for operation, rows in sorted(by_operation.items()):
        header = (
            f"% Generated by scripts/research/build_transition_tables.py.\n"
            f"% Static extraction and bounded live observations; each transition retains its provenance.\n"
            ":- multifile automaton_tuple/6.\n"
            ":- multifile automaton_transition/6.\n\n"
        )
        ordered = sorted(rows, key=lambda row: row.kind)
        observed = {
            (item.operation, item.kind, item.source): item
            for item in observations if item.status == "observed"
        }
        observed_blocks = [
            render_observed_transitions(row, observed[key])
            for row in ordered
            for key in ((row.operation, row.kind, "contract_example"),
                        (row.operation, row.kind, "derived_template"))
            if key in observed
        ]
        content = (
            header
            + "\n".join(render_tuple(row) for row in ordered)
            + "\n\n"
            + "\n\n".join(render_transitions(row) for row in ordered)
            + ("\n\n% Bounded live traces reconstructed from returned step labels.\n"
               + "\n\n".join(observed_blocks) if observed_blocks else "")
            + "\n"
        )
        (OUT_DIR / f"{operation}.pl").write_text(content, encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="fail if generated facts are not current")
    parser.add_argument("--coverage", action="store_true", help="print every observed or skipped probe")
    args = parser.parse_args()
    tables, skipped, routes = build()
    observations = observe(contracts())
    if args.check:
        before = {path.name: path.read_text(encoding="utf-8") for path in OUT_DIR.glob("*.pl")} if OUT_DIR.exists() else {}
        write(tables, observations)
        after = {path.name: path.read_text(encoding="utf-8") for path in OUT_DIR.glob("*.pl")}
        if before != after:
            print("transition tables were regenerated; rerun without --check and inspect the diff")
            return 1
    else:
        write(tables, observations)
    print(f"extracted={len(tables)} skipped={len(skipped)}")
    for operation in sorted(set(routes) | {operation for operation, _, _ in skipped}):
        total = sum(1 for op, _ in SIGNATURE.findall(REGISTRY.read_text(encoding='utf-8')) if op == operation)
        print(f"{operation}: {routes[operation]}/{total}")
    for operation, kind, reason in skipped:
        print(f"SKIPPED {operation}/{kind}: {reason}")
    primary = [item for item in observations if item.source == "contract_example"]
    secondary = [item for item in observations if item.source == "derived_template"]
    print(f"contract-observed={sum(item.status == 'observed' for item in primary)}/{len(primary)} "
          f"derived-observed={sum(item.status == 'observed' for item in secondary)}/{len(secondary)}")
    if args.coverage:
        for observation in observations:
            detail = ",".join(observation.actions) if observation.status == "observed" else observation.reason
            print(f"OBSERVED {observation.operation}/{observation.kind} {observation.source}: {observation.status} {detail}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
