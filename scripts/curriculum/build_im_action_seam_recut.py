#!/usr/bin/env python3
"""Measure task 209's 226 lessons against the live action seam.

An enacted lesson must supply its own machine inputs in a tracked task span and
must produce a live nonempty trace with those inputs.  Registry coverage and
named-but-unregistered surfaces are recorded separately.
"""

from __future__ import annotations

import argparse
from collections import Counter
from dataclasses import dataclass
import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile
from typing import NoReturn


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "data/learningcommons/derived/im_zero_candidate_triage.json"
OUTPUT = ROOT / "data/learningcommons/derived/im_action_seam_recut.json"
REGISTRY = ROOT / "knowledge/strategies/math/action_automata_registry.pl"
CONTRACTS = ROOT / "knowledge/strategies/automaton_input_contracts.pl"
CONTRACT_CHECK = ROOT / "scripts/checks/automaton_input_contracts.py"
VOCABULARY = ROOT / "knowledge/strategies/action_vocabulary_map.pl"
GRAMMAR = ROOT / "knowledge/strategies/action_grammar.pl"
TRANSITIONS = ROOT / "knowledge/strategies/transition_tables"
FRACTION_ACTIONS = ROOT / "knowledge/strategies/math/fraction_action_pairs.pl"
FRACTION_SCENE = ROOT / "knowledge/strategies/render/fraction_bars_scene.pl"
BASE_TEN_SCENE = ROOT / "knowledge/strategies/render/base_ten_scene.pl"
SET_GROUPING_SCENE = ROOT / "knowledge/strategies/render/set_grouping_scene.pl"
GEOMETRY_ACTIONS = ROOT / "knowledge/strategies/math/geometry_action_pairs.pl"
GEOMETRY_SCENES = (
    ROOT / "knowledge/strategies/render/area_unit_covering_scene.pl",
    ROOT / "knowledge/strategies/render/coordinate_plane_scene.pl",
    ROOT / "knowledge/strategies/render/geoboard_scene.pl",
    ROOT / "knowledge/strategies/render/rigid_motion_scene.pl",
)
SCHEMA = "im_action_seam_recut_v2"
EXPECTED = 226


SIGNATURE_RE = re.compile(
    r"action_automaton_signature\(\s*([a-z][a-z0-9_]*)\s*,\s*"
    r"([a-z][a-z0-9_]*)\s*,",
    re.MULTILINE,
)
NUMBER_RE = re.compile(r"(?<![\w/])\$?(-?\d[\d,]*(?:\.\d+)?)(?![\w/])")
FRACTION_RE = re.compile(r"(?<!\d)(\d+)\s*/\s*(\d+)(?!\d)")
PAIR_RE = re.compile(r"\(\s*(-?\d+)\s*,\s*(-?\d+)\s*\)")


@dataclass(frozen=True)
class Candidate:
    probe_id: str
    lesson: str | None
    origin: str
    doing: str
    operation: str
    kind: str
    left: str
    right: str
    input_evidence: dict


def fail(message: str) -> NoReturn:
    raise SystemExit(f"build_im_action_seam_recut.py: {message}")


def load(path: Path) -> dict:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        fail(f"cannot read {path}: {exc}")
    if not isinstance(value, dict):
        fail(f"expected an object at {path}")
    return value


def source_line(path: Path, token: str) -> int:
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if token in line:
            return number
    fail(f"cannot find {token!r} in {path}")


def registry_signatures() -> list[dict]:
    text = REGISTRY.read_text(encoding="utf-8")
    rows = [
        {
            "operation": match.group(1),
            "kind": match.group(2),
            "source": str(REGISTRY.relative_to(ROOT)),
            "line": text.count("\n", 0, match.start()) + 1,
        }
        for match in SIGNATURE_RE.finditer(text)
    ]
    keys = [(row["operation"], row["kind"]) for row in rows]
    if len(rows) != 219 or len(keys) != len(set(keys)):
        fail(f"expected 219 unique signatures, found {len(rows)}")
    return rows


def checked_registry_runs() -> dict:
    """Run every checked contract through the repository's live worker."""
    with tempfile.TemporaryDirectory(prefix="hermes-action-contracts-") as directory:
        output = Path(directory) / "traces.json"
        result = subprocess.run(
            [sys.executable, str(CONTRACT_CHECK), "--trace-output", str(output)],
            cwd=ROOT,
            text=True,
            capture_output=True,
            timeout=240,
            check=False,
        )
        if result.returncode:
            fail(
                f"input-contract check exited {result.returncode}: "
                f"{result.stdout.strip()} {result.stderr.strip()}"
            )
        payload = load(output)
    traces = payload.get("traces", [])
    # 131 from 2026-08-03: the contract-gap slice added seven contracts the
    # existing seam could already decode (four decimal, two co-denominator
    # fraction dispatches, one integer deformation).
    if payload.get("contracts") != 131 or len(traces) != 131:
        fail("expected 131 live checked-contract traces")
    if any(
        row.get("response", {}).get("ok") is not True
        or not row.get("response", {}).get("steps")
        for row in traces
    ):
        fail("a checked contract did not produce a live trace")
    return payload


ACTION_CLAUSE_HEAD = re.compile(
    r"^run_[a-z_]*action\(\s*([a-z][a-z0-9_]*)\s*,", re.MULTILINE
)


def scene_request_requesting_kinds() -> dict[str, set[str]]:
    """Map a scene-request name to the registry kinds whose clause requests it.

    A third correspondence route, added 2026-08-01. The two routes above ask
    whether a name IS a registered kind or is authored onto one through the
    canonical alphabet. Neither reaches a scene request: `subitize` is neither
    a kind nor a transition label, yet counting/enumerate_collection_one_to_one
    calls set_grouping_render_json(subitize(auto, Count), Scene) and carries the
    result as its representation. Reading the call is mechanical, so this route
    records a correspondence nobody had to assert. It says the machine requests
    the surface. It does not say the machine's transitions do what the surface
    name says.
    """
    requesting: dict[str, set[str]] = {}
    for path in sorted((ROOT / "knowledge/strategies/math").glob("*.pl")):
        text = path.read_text(encoding="utf-8")
        heads = list(ACTION_CLAUSE_HEAD.finditer(text))
        for index, head in enumerate(heads):
            end = heads[index + 1].start() if index + 1 < len(heads) else len(text)
            body = text[head.end():end]
            kind = head.group(1)
            for call in re.finditer(
                r"_render_json\(\s*([a-z][a-z0-9_]*)\(", body
            ):
                requesting.setdefault(call.group(1), set()).add(kind)
    return requesting


def named_surface_inventory(signatures: list[dict]) -> dict:
    """Census live names while keeping correspondence distinct from enactment."""
    signature_keys = {(row["operation"], row["kind"]) for row in signatures}
    vocabulary_text = VOCABULARY.read_text(encoding="utf-8")
    canonical_to_signatures: dict[str, set[tuple[str, str]]] = {}
    for match in re.finditer(
        r"action_maps\(\s*([a-z][a-z0-9_]*)\s*,\s*"
        r"([a-z][a-z0-9_]*)\s*,\s*[a-z][a-z0-9_]*\s*,\s*"
        r"([a-z][a-z0-9_]*)\s*,",
        vocabulary_text,
        re.MULTILINE,
    ):
        canonical_to_signatures.setdefault(match.group(3), set()).add(
            (match.group(1), match.group(2))
        )

    requesting_kinds = scene_request_requesting_kinds()

    records: list[dict] = []

    def add(path: Path, match: re.Match[str], surface: str, name: str) -> None:
        exact = sorted(
            [list(key) for key in signature_keys if key[1] == name]
        )
        mapped = sorted(
            [
                list(key)
                for key in canonical_to_signatures.get(name, set())
                if key in signature_keys
            ]
        )
        requested = sorted(
            [
                list(key)
                for key in signature_keys
                if key[1] in requesting_kinds.get(name, set())
            ]
        )
        records.append(
            {
                "action_name": name,
                "surface": surface,
                "source": str(path.relative_to(ROOT)),
                "line": path.read_text(encoding="utf-8").count("\n", 0, match.start()) + 1,
                "registry_signature_matches": exact,
                "canonical_mapping_signature_matches": mapped,
                "requesting_signature_matches": requested,
                "registered_automaton_correspondence": bool(
                    exact or mapped or requested
                ),
            }
        )

    for path, surface, pattern in (
        (
            VOCABULARY,
            "canonical_action",
            re.compile(r"^canonical_action\(([a-z][a-z0-9_]*)\s*,", re.MULTILINE),
        ),
        (
            GRAMMAR,
            "action_phrase",
            re.compile(r"^action_phrase\(([a-z][a-z0-9_]*)\s*,", re.MULTILINE),
        ),
    ):
        text = path.read_text(encoding="utf-8")
        for match in pattern.finditer(text):
            add(path, match, surface, match.group(1))

    tuple_pattern = re.compile(
        r"^automaton_tuple\(\s*[a-z][a-z0-9_]*\s*,\s*"
        r"([a-z][a-z0-9_]*)\s*,",
        re.MULTILINE,
    )
    for path in sorted(TRANSITIONS.glob("*.pl")):
        text = path.read_text(encoding="utf-8")
        for match in tuple_pattern.finditer(text):
            add(path, match, "transition_table_automaton", match.group(1))

    for path, surface, predicate in (
        (FRACTION_ACTIONS, "fraction_action", "run_fraction_action"),
        (GEOMETRY_ACTIONS, "geometry_action", "run_geometry_action"),
    ):
        text = path.read_text(encoding="utf-8")
        pattern = re.compile(
            rf"^{predicate}\(\s*([a-z][a-z0-9_]*)\s*,", re.MULTILINE
        )
        for match in pattern.finditer(text):
            add(path, match, surface, match.group(1))

    scene_paths = (
        FRACTION_SCENE,
        BASE_TEN_SCENE,
        SET_GROUPING_SCENE,
        *GEOMETRY_SCENES,
    )
    literal_verb = re.compile(r'verb\s*:\s*"([a-z][a-z0-9_]*)"')
    request_functor = re.compile(r"^build_frames\(\s*([a-z][a-z0-9_]*)\(", re.MULTILINE)
    for path in scene_paths:
        text = path.read_text(encoding="utf-8")
        for match in literal_verb.finditer(text):
            add(path, match, "scene_verb", match.group(1))
        if path == SET_GROUPING_SCENE:
            for match in request_functor.finditer(text):
                add(path, match, "scene_request", match.group(1))

    records.sort(key=lambda row: (row["source"], row["line"], row["action_name"]))
    uncorresponded = [
        row for row in records if not row["registered_automaton_correspondence"]
    ]
    return {
        "interpretation": (
            "A name is uncorresponded when no exact registry kind, no authored "
            "canonical-action mapping, and no registered clause that requests the "
            "surface as a scene connects it to a registered machine."
        ),
        "action_name_occurrences": len(records),
        "unique_action_names": len({row["action_name"] for row in records}),
        "uncorresponded_occurrences": len(uncorresponded),
        "uncorresponded_unique_names": len(
            {row["action_name"] for row in uncorresponded}
        ),
        "records": records,
        "uncorresponded": uncorresponded,
        "fraction_api_surfaces": [
            {
                "predicate": predicate,
                "source": str(path.relative_to(ROOT)),
                "line": source_line(path, predicate + "("),
            }
            for path, predicate in (
                (FRACTION_ACTIONS, "run_fraction_action"),
                (FRACTION_SCENE, "fraction_render_frames"),
                (FRACTION_SCENE, "fraction_scene_plan"),
            )
        ],
    }


def numeric_tokens(text: str) -> list[str]:
    values = []
    for match in NUMBER_RE.finditer(text):
        # Numbered directions such as "1. Draw" are structure, not task input.
        tail = text[match.end():]
        if "." not in match.group(1) and re.match(r"\.\s+[A-Za-z]", tail):
            continue
        values.append(match.group(1))
    return values


def span_refusal(lesson: str, span: dict) -> str | None:
    text = span["text"]
    lower = text.lower()
    if "choose a center" in lower:
        return "center_menu_not_task"
    if lesson == "IM-GK-U3-L12" and span["position"] == "student_task_statement(3)":
        return "teacher_synthesis_not_student_task"
    if lesson == "IM-GK-U3-L8" and span["position"] == "student_task_statement(2)":
        return "teacher_move_not_student_task"
    if re.search(r"activity synthesis|display the|invite students|seconds:.*work time", lower):
        return "teacher_move_not_student_task"
    if len(text.strip()) < 12:
        return "insufficient_task_text"
    return None


def span_witness(row: dict, span: dict, refusal: str | None = None) -> dict:
    evidence = row["evidence"]
    same_position = (
        span["source"] == evidence["source"]
        and span["position"] == evidence["position"]
    )
    return {
        "source": span["source"],
        "line": span["heading_line"],
        "end_line": span["end_line"],
        "position": span["position"],
        "text": span["text"],
        "numeric_tokens": numeric_tokens(span["text"]),
        "task_209_evidence_position": same_position,
        "task_209_evidence_excerpt": evidence["excerpt"] if same_position else None,
        "refusal": refusal,
    }


UNIT_CONVERSIONS = {
    "kilometer": ("meter", 1000),
    "meter": ("centimeter", 100),
    "yard": ("foot", 3),
    "foot": ("inch", 12),
    "liter": ("milliliter", 1000),
    "kilogram": ("gram", 1000),
}
UNIT_ALIASES = {
    "kilometers": "kilometer", "kilometer": "kilometer",
    "meters": "meter", "meter": "meter",
    "yards": "yard", "yard": "yard",
    "feet": "foot", "foot": "foot",
    "inches": "inch", "inch": "inch",
    "liters": "liter", "liter": "liter",
    "milliliters": "milliliter", "milliliter": "milliliter",
    "kilograms": "kilogram", "kilogram": "kilogram",
    "grams": "gram", "gram": "gram",
    "centimeters": "centimeter", "centimeter": "centimeter",
}


# Operand ceiling for the sar_* families, which reach arithmetic grounded in
# iterated successor steps through math(integer_helpers) and
# formalization(grounded_arithmetic). Cost climbs with the operand, not with the
# numeral's length, and the failure is a stall or a stack overflow rather than a
# clean failure, so a probe past the bound is never proposed. Measured here
# 2026-08-01: addition/count_on_from_larger runs (4000,1000) in 876 ms,
# (8000,5000) in 11.5 s, and overflows the stack on (11000,8000);
# subtraction/count_up_missing_addend stays under 600 ms across the same range.
# The counting and decimal families do not reach it and are not bounded:
# place_value_comparison on counts(140261,194030) and
# decimal_comparison_by_aligned_units on 99.909 against 99.099 both run in
# about a millisecond.
GROUNDED_ARITHMETIC_REACH = 5000

DECIMAL_TOKEN = r"\d+\.\d+"
DECIMAL_COMPARISON_RE = re.compile(
    rf"({DECIMAL_TOKEN})\s*(?:_+|<|>|=)\s*({DECIMAL_TOKEN})"
    rf"|({DECIMAL_TOKEN})\s*is\s+(?:greater|less)\s+than\s+({DECIMAL_TOKEN})"
)
ORDERED_LIST_RE = re.compile(
    r"(?:in order from least to greatest|numbers in order|order from least)"
)
NEAREST_MULTIPLE_RE = re.compile(
    r"is\s+(\d[\d,]*)\s+closer\s+to\s+(\d[\d,]*)\s+or\s+(\d[\d,]*)"
)
BUILD_COLLECTION_RE = re.compile(
    r"(?:create a collection of|how many ways can you make|"
    r"choose \d+ numbers to represent|show \d+ different ways to make)"
    r"[^\d]{0,60}?(\d[\d,]*)"
)
# The height chain crosses a sentence break and a bullet in the printed guide,
# so this pattern spans punctuation where the others stop at it.
MEASURED_INCREASE_RE = re.compile(
    r"(\d[\d,]*)\s+inches\s+tall[\s\S]{0,90}?(\d[\d,]*)\s+inches\s+(taller|shorter)"
)
SOLID_COUNT_RE = re.compile(
    r"(\d+)\s+(?:cubes?|cylinders?|cones?|counters?|blocks?|connecting cubes)\b"
)
DIGIT_CARD_RE = re.compile(
    r"cards? for\s+(\d)\s*,\s*(\d)\s*,?\s*and\s+(\d)"
)


def decimal_operand(token: str) -> tuple[int, int]:
    """Read a printed decimal as the numeral and scale the automata take."""
    whole, fraction = token.split(".", 1)
    scale = 10 ** len(fraction)
    return int(whole) * scale + int(fraction), scale


def counting_lane_adapters(text: str, lower: str, add) -> None:
    """Extract counting, place-value, and comparison inputs from one span.

    Written 2026-08-01 for the counting_place_value_or_comparison subclass,
    where 31 of 36 lessons had produced no candidate at all. The gap sat in
    this extraction layer, not in the automata: the whole-number comparison
    reader above matches integers only, and no reader offered a decimal pair,
    a bracketing distance, or a collection to build. Each adapter below
    proposes inputs the registry family already accepts; whether the automaton
    then runs is decided by the live probe, never here.
    """
    for match in DECIMAL_COMPARISON_RE.finditer(lower):
        left_token, right_token = (
            (match.group(1), match.group(2))
            if match.group(1) is not None
            else (match.group(3), match.group(4))
        )
        left_numeral, left_scale = decimal_operand(left_token)
        right_numeral, right_scale = decimal_operand(right_token)
        add(
            "compare_fixed_decimals", "decimal",
            "decimal_comparison_by_aligned_units",
            f"decimal_pair({left_numeral},{left_scale},"
            f"{right_numeral},{right_scale})",
            "ignored",
            {"left": left_token, "right": right_token,
             "left_scale": left_scale, "right_scale": right_scale},
        )
        break

    if ORDERED_LIST_RE.search(lower):
        printed = numeric_tokens(text)
        decimals = [raw for raw in printed if "." in raw]
        wholes = [int(raw.replace(",", "")) for raw in printed if "." not in raw]
        if len(decimals) >= 2:
            left_numeral, left_scale = decimal_operand(decimals[0])
            right_numeral, right_scale = decimal_operand(decimals[1])
            add(
                "compare_adjacent_members_of_a_printed_ordering", "decimal",
                "decimal_comparison_by_aligned_units",
                f"decimal_pair({left_numeral},{left_scale},"
                f"{right_numeral},{right_scale})",
                "ignored",
                {"ordering_members": decimals[:2], "position": "first_pair"},
            )
        elif len(wholes) >= 2 and min(wholes[:2]) >= 0:
            add(
                "compare_adjacent_members_of_a_printed_ordering", "counting",
                "place_value_comparison",
                f"counts({wholes[0]},{wholes[1]})", "base(10)",
                {"ordering_members": wholes[:2], "position": "first_pair",
                 "base": 10},
            )

    bracket = NEAREST_MULTIPLE_RE.search(lower)
    if bracket:
        target, lower_multiple, upper_multiple = (
            int(raw.replace(",", "")) for raw in bracket.groups()
        )
        below = abs(target - lower_multiple)
        above = abs(upper_multiple - target)
        add(
            "compare_distances_to_bracketing_multiples", "counting",
            "place_value_comparison",
            f"counts({below},{above})", "base(10)",
            {"target": target, "lower_multiple": lower_multiple,
             "upper_multiple": upper_multiple,
             "distance_below": below, "distance_above": above, "base": 10},
        )

    build = BUILD_COLLECTION_RE.search(lower)
    if build:
        value = int(build.group(1).replace(",", ""))
        add(
            "inscribe_fixed_cardinality", "counting",
            "recursive_place_value_inscription", str(value), "base(10)",
            {"cardinality": value, "base": 10,
             "trigger": "collection_or_regrouping_task"},
        )

    increase = MEASURED_INCREASE_RE.search(lower)
    if increase:
        base_height = int(increase.group(1).replace(",", ""))
        change = int(increase.group(2).replace(",", ""))
        if max(base_height, change) > GROUNDED_ARITHMETIC_REACH:
            # Refuse rather than run away. This is the only adapter in the lane
            # that routes to a grounded-arithmetic family.
            pass
        elif increase.group(3) == "taller":
            add(
                "add_fixed_measured_increase", "addition", "count_on_from_larger",
                str(base_height), str(change),
                {"height": base_height, "change": change, "unit": "inch",
                 "direction": "taller"},
            )
        else:
            add(
                "subtract_fixed_measured_decrease", "subtraction",
                "count_up_missing_addend", str(base_height), str(change),
                {"height": base_height, "change": change, "unit": "inch",
                 "direction": "shorter"},
            )

    solid = SOLID_COUNT_RE.search(lower)
    if solid and "how many" in lower:
        count = int(solid.group(1))
        if 1 <= count <= 10:
            add(
                "enumerate_fixed_collection", "counting",
                "enumerate_collection_one_to_one", str(count), "base(10)",
                {"collection_size": count, "base": 10,
                 "note": "one named part of the set, not the whole set"},
            )

    cards = DIGIT_CARD_RE.search(lower)
    if cards and re.search(r"compare|greater|less|> or <|< or >", lower):
        digits = sorted(int(digit) for digit in cards.groups())
        smallest = int("".join(str(digit) for digit in digits))
        largest = int("".join(str(digit) for digit in reversed(digits)))
        if smallest != largest:
            add(
                "compare_numerals_built_from_fixed_digits", "counting",
                "place_value_comparison",
                f"counts({smallest},{largest})", "base(10)",
                {"digits": digits, "left": smallest, "right": largest,
                 "base": 10,
                 "arrangement": "machine_selected_least_and_greatest"},
            )


def lesson_candidates(row: dict, span: dict, start: int) -> list[Candidate]:
    text = span["text"]
    lower = text.lower()
    lesson = row["lesson"]
    witness = span_witness(row, span)
    candidates: list[Candidate] = []

    def add(doing: str, operation: str, kind: str, left: str, right: str,
            values: dict) -> None:
        probe_id = f"lesson_{start + len(candidates):04d}"
        candidates.append(
            Candidate(
                probe_id, lesson, "lesson_span", doing, operation, kind,
                left, right, {"span": witness, "extracted": values},
            )
        )

    fractions = [(int(a), int(b)) for a, b in FRACTION_RE.findall(text) if int(b) > 0]
    integers = [int(raw.replace(",", "")) for raw in numeric_tokens(text)
                if "." not in raw]

    unit_matches = list(re.finditer(
        r"(\d[\d,]*)[-\s]*(kilometers?|meters?|yards?|feet|foot|inches?|"
        r"liters?|milliliters?|kilograms?|grams?|centimeters?)\b",
        lower,
    ))
    distinct_units = {UNIT_ALIASES[item.group(2)] for item in unit_matches}
    if (
        len(distinct_units) >= 2
        and re.search(
            r"order|compare|convert|equivalent|relationship|complete the table|"
            r"shortest|longest|less than|more than",
            lower,
        )
    ):
        match = next(
            (
                item for item in unit_matches
                if UNIT_ALIASES[item.group(2)] in UNIT_CONVERSIONS
            ),
            None,
        )
        if match:
            count = int(match.group(1).replace(",", ""))
            from_unit = UNIT_ALIASES[match.group(2)]
            to_unit, factor = UNIT_CONVERSIONS[from_unit]
            add(
                "convert_measurement_unit_by_iteration", "measurement",
                "unit_conversion_by_iteration", f"quantity({count},{from_unit})",
                f"conversion({to_unit},{factor})",
                {"quantity": count, "from_unit": from_unit,
                 "to_unit": to_unit, "factor": factor},
            )

    if len(fractions) >= 2 and re.search(r"compare|greater|less|order", lower):
        (a, b), (c, d) = fractions[:2]
        term = f"fraction_pair({a},{b},{c},{d})"
        for kind in (
            "benchmark_fraction_comparison",
            "common_unit_fraction_comparison",
            "area_model_fraction_comparison",
        ):
            add(
                "compare_fixed_fractions", "fraction", kind, term, "unit(whole)",
                {"fractions": [f"{a}/{b}", f"{c}/{d}"]},
            )
    elif (
        fractions
        and "toss" not in lower
        and re.search(r"number line|locate and label", lower)
    ):
        numerator, denominator = fractions[0]
        add(
            "iterate_fixed_unit_fraction", "fraction", "unit_fraction_iteration",
            str(numerator), str(denominator),
            {"fraction": f"{numerator}/{denominator}"},
        )

    partition_match = re.search(r"(?:split|fold|partition|divide)[^.!?]{0,100}(\d+)\s+equal", lower)
    word_parts = {"halves": 2, "thirds": 3, "fourths": 4, "eighths": 8}
    denominator = int(partition_match.group(1)) if partition_match else next(
        (value for word, value in word_parts.items() if word in lower), None
    )
    if (
        denominator
        and "whose partitioning" not in lower
        and re.search(r"split|fold|partition|divide|equal parts", lower)
    ):
        add(
            "partition_fixed_whole", "fraction", "unit_fraction_partition",
            "1", str(denominator), {"parts": denominator},
        )

    group_match = re.search(r"(\d+)\s+(?:equal\s+)?groups?\s+of\s+(\d+)", lower)
    if group_match:
        groups, size = map(int, group_match.groups())
        add(
            "iterate_fixed_equal_groups", "multiplication", "repeat_equal_groups",
            str(groups), str(size), {"groups": groups, "group_size": size},
        )

    perimeter_target = re.search(r"perimeter(?:\s+of)?\s+(\d+)", lower)
    if perimeter_target and re.search(r"possible|length and width|side lengths", lower):
        perimeter = int(perimeter_target.group(1))
        if perimeter >= 4 and perimeter % 2 == 0:
            add(
                "search_fixed_perimeter_side_pairs", "geometry",
                "rectangle_perimeter_side_pair_search", str(perimeter),
                "side_scope(all)", {"perimeter": perimeter},
            )

    area_target = re.search(r"(?:area(?:\s+of)?\s+|covers?\s+)(\d+)\s+square", lower)
    if area_target and re.search(r"possible|side lengths|length and width", lower):
        area = int(area_target.group(1))
        add(
            "search_fixed_area_factor_pairs", "geometry", "rectangle_factor_pair_search",
            str(area), "factor_scope(all)", {"area": area},
        )

    three_dims = re.search(
        r"(\d+)\s*(?:feet|foot|inches?|units?)?\s*(?:by|×|x)\s*"
        r"(\d+)\s*(?:feet|foot|inches?|units?)?\s*(?:by|×|x)\s*"
        r"(\d+)", lower,
    )
    if not three_dims:
        three_dims = re.search(
            r"(\d+)\s*(?:inches?|feet)?\s+by\s+(\d+)\s*(?:inches?|feet)?"
            r"[^.!?]{0,180}?height[^.!?]{0,60}?(\d+)", lower,
        )
    if three_dims and re.search(r"volume|rectangular prism|pack|cubes", lower):
        length, width, height = map(int, three_dims.groups())
        add(
            "iterate_fixed_prism_layers", "geometry",
            "rectangular_prism_volume_layer_iteration",
            f"prism({length},{width})", str(height),
            {"length": length, "width": width, "height": height},
        )
        height_range = re.search(r"height[^.!?]{0,40}?(\d+)\s*(?:inches?|feet)?\s+to\s+(\d+)", lower)
        if height_range:
            lower_height, upper_height = map(int, height_range.groups())
            if upper_height != height:
                add(
                    "iterate_fixed_prism_layers", "geometry",
                    "rectangular_prism_volume_layer_iteration",
                    f"prism({length},{width})", str(upper_height),
                    {"length": length, "width": width, "height": upper_height,
                     "range_endpoint": "upper"},
                )

    two_dims = re.search(
        r"(?:side lengths? of\s+)?(\d+)\s*(?:feet|foot|inches?|units?)?\s+"
        r"(?:and|by|×|x)\s+(\d+)\s*(?:feet|foot|inches?|units?)?",
        lower,
    )
    if two_dims and "rectang" in lower:
        length, width = map(int, two_dims.groups())
        if re.search(r"what is the area|find[^.!?]{0,50}area|calculate[^.!?]{0,50}area|area of", lower):
            add(
                "iterate_fixed_rectangle_area_units", "geometry",
                "rectangle_area_unit_iteration", str(length), str(width),
                {"length": length, "width": width},
            )
        if "perimeter" in lower:
            add(
                "traverse_fixed_rectangle_boundary", "geometry",
                "rectangle_perimeter_boundary_traversal",
                f"rectangle({length},{width})", "unit(foot)",
                {"length": length, "width": width, "unit": "foot"},
            )

    pair_values = PAIR_RE.findall(text)
    if pair_values and re.search(r"coordinate|grid|plot|represent", lower):
        points = ",".join(f"point({int(x)},{int(y)})" for x, y in pair_values)
        add(
            "plot_fixed_ordered_pairs", "geometry", "ordered_pair_coordinate_plot",
            f"[{points}]", "axes(cartesian)",
            {"points": [[int(x), int(y)] for x, y in pair_values]},
        )

    liquid = re.search(r"(\d+)\s*(milliliters?|liters?)", lower)
    if liquid and re.search(r"liquid|filled|fill level|scale", lower):
        count = int(liquid.group(1))
        unit = UNIT_ALIASES[liquid.group(2)]
        add(
            "read_fixed_liquid_volume_scale", "measurement",
            "liquid_volume_scale_reading", f"measure({count},1)", f"unit({unit})",
            {"interval_count": count, "subdivision": 1, "unit": unit},
        )

    place_value = re.search(r"(?:represent|show|build)[^.!?]{0,80}?(\d[\d,]+)", lower)
    if place_value and re.search(r"base-ten|place value|tens and ones|hundreds", lower):
        value = int(place_value.group(1).replace(",", ""))
        add(
            "inscribe_fixed_cardinality", "counting",
            "recursive_place_value_inscription", str(value), "base(10)",
            {"cardinality": value, "base": 10},
        )

    comparison = re.search(
        r"(?<![./])\b(\d[\d,]*)_+(\d[\d,]*)\b|"
        r"(?<![./])\b(\d[\d,]*)\b\s*(?:<|>|is\s+(?:greater|less)\s+than)"
        r"\s*(\d[\d,]*)\b",
        lower,
    )
    if row["subclass"] == "counting_place_value_or_comparison" and comparison:
        raw_left, raw_right = (
            comparison.group(1), comparison.group(2)
        ) if comparison.group(1) is not None else (
            comparison.group(3), comparison.group(4)
        )
        left, right = (
            int(raw_left.replace(",", "")),
            int(raw_right.replace(",", "")),
        )
        if left >= 0 and right >= 0:
            add(
                "compare_fixed_whole_numbers", "counting", "place_value_comparison",
                f"counts({left},{right})", "base(10)",
                {"left": left, "right": right, "base": 10},
            )

    if row["subclass"] == "counting_place_value_or_comparison":
        counting_lane_adapters(text, lower, add)

    count_question = re.search(r"(\d+)\s+bowls?[^.!?]{0,120}how many\s+spoons?", lower)
    if count_question:
        count = int(count_question.group(1))
        if 0 <= count <= 10:
            add(
                "enumerate_fixed_collection", "counting",
                "enumerate_collection_one_to_one", str(count), "base(10)",
                {"collection_size": count, "base": 10},
            )

    pattern = re.search(
        r"start (?:with|at)\s+(\d+)[^.!?]{0,100}add(?:ing)?\s+(\d+)"
        r"[^.!?]{0,160}(?:row|term)\s+(\d+)",
        lower,
    )
    if pattern:
        first, change, requested = map(int, pattern.groups())
        add(
            "extend_fixed_constant_change_pattern", "algebraic",
            "linear_pattern_contextual_rule",
            f"linear_pattern(first({first}),change({change}),row({requested}))",
            "context(sequence)",
            {"first": first, "change": change, "row": requested},
        )

    return candidates


REVIEWER_PROBES = (
    ("review_unit_conversion", "measurement", "unit_conversion_by_iteration",
     "quantity(40,kilometer)", "conversion(meter,1000)"),
    ("review_benchmark_fraction", "fraction", "benchmark_fraction_comparison",
     "fraction_pair(3,8,5,8)", "unit(whole)"),
    ("review_common_unit_fraction", "fraction", "common_unit_fraction_comparison",
     "fraction_pair(3,8,5,8)", "unit(whole)"),
    ("review_area_model_fraction", "fraction", "area_model_fraction_comparison",
     "fraction_pair(1,2,1,3)", "unit(whole)"),
    ("review_median", "statistics", "median_as_ordered_middle",
     "[1,2,3,4,5]", "measurement_unit(inch)"),
    ("review_round_then_adjust", "addition", "round_then_adjust", "349", "400"),
)


PROLOG_RUNNER = r'''
:- use_module(library(http/json)).
:- use_module(library(time)).

trace_actions([], []).
trace_actions([hist(_, Step)|Rest], Actions) :- !,
    hist_actions([hist(_, Step)|Rest], Actions).
trace_actions([Step|Rest], [Action|Actions]) :-
    functor(Step, Action, _), trace_actions(Rest, Actions).
hist_actions([], []).
hist_actions([hist(_, Step)|Rest], [Action|Actions]) :-
    functor(Step, Action, _), hist_actions(Rest, Actions).

probe(Id, Operation, Kind, Left, Right) :-
    Goal = action_automata_registry:run_action_automaton(
               Operation, Kind, Left, Right, Outcome, Trace),
    catch(call_with_time_limit(5, once(Goal)), Error,
          (message_to_string(Error, Message), failed(Id, Operation, Kind, Message))),
    is_list(Trace), Trace = [_|_], !,
    trace_actions(Trace, Actions),
    term_string(Left, LeftText, [quoted(true)]),
    term_string(Right, RightText, [quoted(true)]),
    term_string(Outcome, OutcomeText, [quoted(true)]),
    term_string(Trace, TraceText, [quoted(true)]),
    format(string(GoalText),
           "action_automata_registry:run_action_automaton(~w,~w,~w,~w,Outcome,Trace)",
           [Operation, Kind, LeftText, RightText]),
    json_write_dict(current_output,
                    _{id:Id, operation:Operation, kind:Kind, status:"observed",
                      goal:GoalText, outcome:OutcomeText, trace:TraceText,
                      trace_actions:Actions}, [width(0)]), nl.
probe(Id, Operation, Kind, _Left, _Right) :-
    failed(Id, Operation, Kind, "goal failed").
failed(Id, Operation, Kind, Message) :-
    json_write_dict(current_output,
                    _{id:Id, operation:Operation, kind:Kind, status:"failed",
                      error:Message}, [width(0)]), nl.
main :- forall(probe_spec(Id, Operation, Kind, Left, Right),
               probe(Id, Operation, Kind, Left, Right)).
'''


def run_direct_probes(candidates: list[Candidate]) -> dict[str, dict]:
    facts = "\n".join(
        f"probe_spec('{item.probe_id}', {item.operation}, {item.kind}, "
        f"{item.left}, {item.right})."
        for item in candidates
    )
    with tempfile.TemporaryDirectory(prefix="hermes-action-lessons-") as directory:
        probes = Path(directory) / "probes.pl"
        runner = Path(directory) / "runner.pl"
        probes.write_text(facts + "\n", encoding="utf-8")
        runner.write_text(PROLOG_RUNNER, encoding="utf-8")
        result = subprocess.run(
            [
                "swipl", "-q", "-l", "paths.pl", "-l",
                "knowledge/strategies/math/action_automata_registry.pl",
                "-l", str(probes), "-l", str(runner),
                "-g", "main", "-t", "halt",
            ],
            cwd=ROOT,
            text=True,
            capture_output=True,
            timeout=240,
            check=False,
        )
    if result.returncode:
        fail(f"lesson probe runner exited {result.returncode}: {result.stderr.strip()}")
    observations = {}
    for line in result.stdout.splitlines():
        if line.startswith("{"):
            row = json.loads(line)
            observations[row["id"]] = row
    if len(observations) != len(candidates):
        fail(f"probe runner returned {len(observations)} of {len(candidates)} results")
    return observations


MIDDLE_BINDINGS = (
    {
        "surface": "place_vertices",
        "pattern": re.compile(
            r"(?:copy|draw|make|complete)[^.!?]{0,120}(?:shape|figure|animal)|shape stamps",
            re.IGNORECASE,
        ),
        "exclude": re.compile(
            r"pattern|always|sometimes|never|symmetr|angle|measure|clock|"
            r"sorted|sort the shapes|circle shapes|what makes a shape|"
            r"rectangular prism|volume|make a poster|how many shapes|count",
            re.IGNORECASE,
        ),
        "doing": "construct_or_copy_figure",
        "boundary": (
            "The scene verb places supplied vertices. The lesson asks the learner "
            "to supply or copy the figure."
        ),
    },
    {
        "surface": "subitize",
        "pattern": re.compile(r"draw[^.!?]{0,80}(?:dot image|dots)", re.IGNORECASE),
        "exclude": None,
        "doing": "author_counting_image",
        "boundary": (
            "The scene request consumes a pattern and count. It does not author "
            "the requested arrangement."
        ),
    },
    {
        "surface": "draw_line",
        "pattern": re.compile(
            r"draw (?:a|another|new) line[^.!?]{0,120}"
            r"(?:points?|intersect|parallel|perpendicular|vertical|horizontal)",
            re.IGNORECASE,
        ),
        "exclude": re.compile(r"clock|time|measure the length|match the shape", re.IGNORECASE),
        "doing": "draw_unspecified_line",
        "boundary": (
            "The coordinate scene can draw a supplied line description. The span "
            "does not supply a machine-ready line."
        ),
    },
)


def middle_match(row: dict, surfaces: dict) -> dict | None:
    uncorresponded = surfaces["uncorresponded"]
    combined_text = " ".join(span["text"] for span in row["tracked_spans"])
    for span in row["tracked_spans"]:
        refusal = span_refusal(row["lesson"], span)
        if refusal:
            continue
        for binding in MIDDLE_BINDINGS:
            excluded = binding["exclude"]
            if excluded and excluded.search(combined_text):
                continue
            match = binding["pattern"].search(span["text"])
            if not match:
                continue
            sites = [
                item for item in uncorresponded
                if item["action_name"] == binding["surface"]
            ]
            if not sites:
                continue
            return {
                "doing": binding["doing"],
                "matched_surface": binding["surface"],
                "naming_sites": sites,
                "span": span_witness(row, span),
                "matched_text": match.group(0),
                "non_enactment_boundary": binding["boundary"],
                "mechanical_result": "no_exact_or_authored_mapping_to_registry",
            }
    return None


def input_availability(row: dict, successful_candidates: list[Candidate]) -> dict:
    valid = []
    refused = []
    for span in row["tracked_spans"]:
        reason = span_refusal(row["lesson"], span)
        record = span_witness(row, span, reason)
        (refused if reason else valid).append(record)
    richest = max(valid, key=lambda item: len(item["numeric_tokens"]), default=None)
    classroom_pattern = re.compile(
        r"your teacher will give|your group|your data|survey in (?:his|her|your) class|"
        r"find (?:things|items)|objects? in the room|measure (?:the|each|your)[^.!?]{0,80}"
        r"(?:around the room|you choose)|record your|create your own",
        re.IGNORECASE,
    )
    classroom_span = next(
        (item for item in valid if classroom_pattern.search(item["text"])), None
    )
    if successful_candidates:
        status = "machine_ready_inputs_extracted"
    elif any("choose a center" in item["text"].lower() for item in refused):
        status = "center_menu_not_fixed_task"
    elif classroom_span:
        status = "classroom_supplied_or_student_generated_inputs"
    elif richest and richest["numeric_tokens"]:
        status = "fixed_values_present_no_successful_adapter"
    elif richest is None:
        status = "no_accepted_task_span"
    else:
        status = "fixed_non_numeric_or_unparsed_task"
    return {
        "status": status,
        "richest_accepted_span": richest,
        "classroom_supplied_witness": classroom_span,
        "refused_spans": refused,
        "accepted_span_count": len(valid),
        "refused_span_count": len(refused),
    }


REVIEW_LESSONS = (
    "IM-GK-U3-L12",
    "IM-GK-U3-L8",
    "IM-G3-U3-L21",
    "IM-G4-U6-L2",
    "IM-G3-U6-L7",
    "IM-G5-U4-L8",
)


def build() -> dict:
    source = load(SOURCE)
    if source.get("schema") != "im_zero_candidate_triage_v1":
        fail("unexpected task-209 schema")
    source_rows = [
        row for row in source["lessons"]
        if row["class"] == "non_arithmetic_mathematical_task"
    ]
    if len(source_rows) != EXPECTED:
        fail(f"expected {EXPECTED} source rows, found {len(source_rows)}")

    signatures = registry_signatures()
    contract_runs = checked_registry_runs()
    surfaces = named_surface_inventory(signatures)

    candidates: list[Candidate] = []
    candidates_by_lesson: dict[str, list[Candidate]] = {}
    for row in source_rows:
        lesson_items: list[Candidate] = []
        evidence = row["evidence"]
        ordered_spans = sorted(
            row["tracked_spans"],
            key=lambda span: not (
                span["source"] == evidence["source"]
                and span["position"] == evidence["position"]
            ),
        )
        for span in ordered_spans:
            if span_refusal(row["lesson"], span):
                continue
            extracted = lesson_candidates(row, span, len(candidates) + len(lesson_items))
            lesson_items.extend(extracted)
        candidates.extend(lesson_items)
        candidates_by_lesson[row["lesson"]] = lesson_items

    reviewer_candidates = [
        Candidate(
            probe_id, None, "reviewer_fixture", kind, operation, kind, left, right,
            {"reviewer_fixture": {"left": left, "right": right}},
        )
        for probe_id, operation, kind, left, right in REVIEWER_PROBES
    ]
    all_direct = candidates + reviewer_candidates
    observations = run_direct_probes(all_direct)
    reviewer_results = [
        {"probe": item.input_evidence["reviewer_fixture"], "operation": item.operation,
         "kind": item.kind, "run": observations[item.probe_id]}
        for item in reviewer_candidates
    ]
    if any(item["run"]["status"] != "observed" for item in reviewer_results):
        fail("one of the six reviewer probes did not run")

    rows = []
    for source_row in source_rows:
        lesson = source_row["lesson"]
        lesson_candidates_all = candidates_by_lesson[lesson]
        successful = [
            item for item in lesson_candidates_all
            if observations[item.probe_id]["status"] == "observed"
        ]
        availability = input_availability(source_row, successful)
        middle = None if successful else middle_match(source_row, surfaces)
        if successful:
            action_class = "enacted_with_lesson_inputs"
        elif middle:
            action_class = "named_surface_without_registered_correspondence"
        elif availability["status"] in {
            "center_menu_not_fixed_task",
            "classroom_supplied_or_student_generated_inputs",
            "no_accepted_task_span",
        }:
            action_class = "no_fixed_inputs_in_accepted_span"
        else:
            action_class = "not_enacted_by_measured_inventory"

        row = {
            "lesson": lesson,
            "grade": source_row["grade"],
            "task_209_subclass": source_row["subclass"],
            "task_209_evidence": source_row["evidence"],
            "action_class": action_class,
            "input_availability": availability,
            "candidate_attempts": [
                {
                    "doing": item.doing,
                    "operation": item.operation,
                    "kind": item.kind,
                    "input_evidence": item.input_evidence,
                    "run": observations[item.probe_id],
                }
                for item in lesson_candidates_all
            ],
        }
        if successful:
            chosen = successful[0]
            row["enactment"] = {
                "doing": chosen.doing,
                "operation": chosen.operation,
                "kind": chosen.kind,
                "lesson_input": chosen.input_evidence,
                "run": observations[chosen.probe_id],
                "other_successful_candidates": len(successful) - 1,
            }
            span = chosen.input_evidence["span"]
            row["witness_relation_to_task_209"] = (
                "same_position" if span["task_209_evidence_position"]
                else "different_tracked_task_span_with_extractable_inputs"
            )
        elif middle:
            row["middle_class_evidence"] = middle
        rows.append(row)

    counts = Counter(row["action_class"] for row in rows)
    if (
        len(rows) != EXPECTED
        or len({row["lesson"] for row in rows}) != EXPECTED
        or sum(counts.values()) != EXPECTED
    ):
        fail("re-cut is not a unique exhaustive partition")
    enacted = counts["enacted_with_lesson_inputs"]
    if enacted == 0:
        fail("no lesson-specific enactments were measured")

    contract_by_key = {
        (row["operation"], row["kind"]): row for row in contract_runs["traces"]
    }
    successful_direct: dict[tuple[str, str], list[dict]] = {}
    for item in all_direct:
        observation = observations[item.probe_id]
        if observation["status"] == "observed":
            successful_direct.setdefault((item.operation, item.kind), []).append(
                {
                    "origin": item.origin,
                    "lesson": item.lesson,
                    "input_evidence": item.input_evidence,
                    "run": observation,
                }
            )
    coverage_rows = []
    for signature in signatures:
        key = (signature["operation"], signature["kind"])
        contract = contract_by_key.get(key)
        direct = successful_direct.get(key, [])
        exercised = contract is not None or bool(direct)
        coverage_rows.append(
            {
                **signature,
                "status": "exercised" if exercised else "unexercised",
                "checked_contract_run": contract,
                "direct_runs": direct,
                "unexercised_reason": None if exercised else (
                    "no checked input contract and no lesson-derived or reviewer "
                    "fixture produced a successful run"
                ),
            }
        )
    coverage_count = sum(row["status"] == "exercised" for row in coverage_rows)

    task209_summary = source["summary"]
    arithmetic_base = (
        task209_summary["honest_ceiling"]["has_candidates_today"]
        + task209_summary["class_counts"]["parser_gap"]
        + task209_summary["class_counts"]["source_representation_gap"]
    )
    arithmetic_ceiling = task209_summary["honest_ceiling"][
        "confirmed_maximum_executable_task_lessons"
    ]
    measured_floor = arithmetic_base + enacted

    input_split = Counter(
        row["input_availability"]["status"] for row in rows
    )
    numeric_six_or_more = [
        row for row in rows
        if len(
            (row["input_availability"]["richest_accepted_span"] or {}).get(
                "numeric_tokens", []
            )
        ) >= 6
    ]
    numeric_six_by_class = Counter(row["action_class"] for row in numeric_six_or_more)
    divergence = Counter(
        row.get("witness_relation_to_task_209", "not_enacted") for row in rows
    )
    reviewed = []
    for lesson in REVIEW_LESSONS:
        row = next(item for item in rows if item["lesson"] == lesson)
        reviewed.append(
            {
                "lesson": lesson,
                "task_209_evidence": row["task_209_evidence"],
                "action_class": row["action_class"],
                "input_availability": row["input_availability"],
                "enactment": row.get("enactment"),
                "disposition": {
                    "IM-GK-U3-L12": "Center-menu match refused; no lesson-input run claimed.",
                    "IM-GK-U3-L8": "Center-menu match refused; no collection count claimed.",
                    "IM-G3-U3-L21": "Budget wording no longer routes to collection comparison.",
                    "IM-G4-U6-L2": "The 31st-shape task has no extracted pattern input; no count claimed.",
                    "IM-G3-U6-L7": "Estimation without a fixed scale no longer routes to scale reading.",
                    "IM-G5-U4-L8": "The header match is discarded; only a complete tracked volume task can qualify.",
                }[lesson],
            }
        )

    return {
        "schema": SCHEMA,
        "generated_by": "scripts/curriculum/build_im_action_seam_recut.py",
        "register": (
            "Measured partial action-seam inventory. Enacted membership requires "
            "inputs extracted from that lesson's accepted tracked span and a live trace."
        ),
        "sources": {
            "task_209": str(SOURCE.relative_to(ROOT)),
            "registry": str(REGISTRY.relative_to(ROOT)),
            "checked_contracts": str(CONTRACTS.relative_to(ROOT)),
            "contract_runner": str(CONTRACT_CHECK.relative_to(ROOT)),
            "root_resolution": "Path(__file__).resolve().parents[2]",
        },
        "population_check": {
            "expected": EXPECTED,
            "classified": len(rows),
            "unique_lessons": len({row["lesson"] for row in rows}),
            "duplicate_lessons": 0,
            "unclassified_lessons": 0,
            "class_count_sum": sum(counts.values()),
        },
        "summary": {
            "class_counts": dict(sorted(counts.items())),
            "input_availability_split": dict(sorted(input_split.items())),
            "lessons_with_six_or_more_numeric_tokens": len(numeric_six_or_more),
            "six_or_more_numeric_tokens_by_class": dict(
                sorted(numeric_six_by_class.items())
            ),
            "witness_relation_split": dict(sorted(divergence.items())),
            "measured_lesson_specific_enactments": enacted,
            "reach": {
                "shared_task_209_population": arithmetic_base,
                "measured_action_seam_floor": measured_floor,
                "task_209_fixed_task_upper_bound": arithmetic_ceiling,
                "unresolved_interval": arithmetic_ceiling - measured_floor,
                "statement": (
                    "This is a measured floor, not a ceiling, because registry and "
                    "lesson-input coverage remain incomplete."
                ),
            },
        },
        "registry_probe_inventory": {
            "registered_signatures": len(signatures),
            "checked_contracts_run": contract_runs["contracts"],
            "exercised_signatures": coverage_count,
            "unexercised_signatures": len(signatures) - coverage_count,
            "coverage": coverage_rows,
            "reviewer_six": reviewer_results,
        },
        "named_surface_inventory": surfaces,
        "reviewed_blocker_lessons": reviewed,
        "lessons": rows,
    }


def render(payload: dict) -> str:
    return json.dumps(payload, indent=1, ensure_ascii=False, sort_keys=True) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--output", type=Path, default=OUTPUT)
    args = parser.parse_args()

    payload = build()
    rendered = render(payload)
    if args.check:
        current = args.output.read_text(encoding="utf-8") if args.output.exists() else ""
        if current != rendered:
            print(
                "stale IM action-seam re-cut: run "
                "scripts/curriculum/build_im_action_seam_recut.py",
                file=sys.stderr,
            )
            return 1
    else:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(rendered, encoding="utf-8")

    summary = payload["summary"]
    registry = payload["registry_probe_inventory"]
    counts = summary["class_counts"]
    print(
        "im_action_seam_recut "
        + " ".join(f"{name}={count}" for name, count in counts.items())
        + f" total={payload['population_check']['classified']}"
        + f" measured_floor={summary['reach']['measured_action_seam_floor']}"
        + f" registry_exercised={registry['exercised_signatures']}/"
          f"{registry['registered_signatures']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
