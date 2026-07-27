#!/usr/bin/env python3
"""Measure whether typed quantity bindings locate StepVerify's first error.

The model is a parser here.  It gets one call for each student step and is
asked only to bind magnitudes to the measured kinds named in that step and its
problem.  Arithmetic remains the existing deterministic floor.  The optional
human map is kept below so the ceiling can be inspected and rerun without a
model call.
"""
from __future__ import annotations

import argparse
import ast
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
from collections import Counter
from dataclasses import dataclass
from typing import Any, Iterable

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "scripts/research"))

import mtb_official_runner  # noqa: E402
import mtb_responders  # noqa: E402
from datasets import load_dataset  # noqa: E402

MODEL = "gemma4:e2b"
TASK = "mistake_location"
DEFAULT_LIMIT = 60
PATHS = REPO_ROOT / "paths.pl"

# The kind an operation yields is decided once, in hermes/quantity_claim.pl.
# This side renders the parsed equation as a term and asks; it does not carry a
# second account of how kinds compose.
OPERATIONS = {ast.Add: "sum", ast.Sub: "difference",
              ast.Mult: "product", ast.Div: "quotient"}

# This map was written from the problem and labelled first-wrong step for the
# selected 60 raw StepVerify rows.  Keys are raw dataset indexes, then source
# step numbers.  A missing magnitude is deliberately unbound.  The ceiling is
# therefore a bound on this finite reading, not a claim that every numeral in
# a word problem has been resolved.
HUMAN_KIND_MAP: dict[int, dict[int, dict[str, str]]] = {
    1: {2: {"45": "red_candles", "5": "ratio_parts", "3": "ratio_parts", "5.625": "sets"}},
    4: {1: {"30": "april_days", "10": "dollars_per_day", "300": "dollars"}},
    7: {3: {"48": "sandwiches", "2": "croissants_per_sandwich", "96": "mini_croissants"}},
    14: {4: {"57": "rooms", "3": "cylindrical_structures", "15": "rooms"}},
    15: {3: {"3": "fraction_of_phoebes_age", "5": "fraction_parts", "10": "phoebes_future_age", "6": "jacobs_age"}},
    21: {2: {"2": "original_vampires", "10": "people_turned", "22": "vampires_after_first_night"}},
    22: {1: {"4": "legs_per_dog", "24": "legs_and_paws"}},
    24: {4: {"15": "singers_not_in_first_verse", "5": "singers_joining_second_verse", "10": "singers_not_in_second_verse"}},
    25: {4: {"40": "extra_pounds_needed", "4": "pounds_per_rock", "10": "rocks"}},
    27: {4: {"45": "minutes_first_two_steps", "2": "dimensionless", "90": "minutes_third_step"}},
    33: {4: {"24": "students_without_a", "6": "students_with_b_or_c", "8": "students_with_a", "10": "students_failed"}},
    34: {2: {"80": "kilograms_per_hand", "2": "dimensionless", "160": "kilograms_per_hand"}},
    36: {1: {"7": "days_in_week", "4": "days_elapsed", "3": "days_remaining"}},
    40: {1: {"2": "eggs_per_plate", "2x": "bacon_relation"}},
    45: {2: {"1": "quarters", "25": "cents"}},
    47: {1: {"45": "minutes_per_day", "4": "days_per_week", "180": "minutes_per_week"}},
    55: {5: {"15": "minutes", "25": "percent_charge"}},
    56: {1: {"3": "objects_first_week"}},
    57: {3: {"10": "first_class_capacity", "25": "economy_passengers"}},
    61: {2: {"31": "march_days", "21000": "toilet_paper_per_day", "651000": "toilet_paper"}},
    62: {3: {"4": "hours_per_week", "1": "dress", "12": "hours_per_dress", "3": "fraction_parts"}},
    67: {4: {"4": "basket_strawberries", "5": "picked_strawberries", "60": "basket_capacity"}},
    69: {4: {"3": "angle_count", "60": "degrees", "190": "degrees"}},
    71: {3: {"10": "tanyas_red_erasers", "3": "erasers", "7": "rachels_erasers"}},
    75: {2: {"8": "whole_sprigs", "6": "whole_sprigs", "14": "whole_sprigs"}},
    79: {2: {"6": "dozens_of_cupcakes", "12": "cupcakes_per_dozen", "0.5": "cans_per_dozen", "36": "half_cans"}},
    82: {4: {"22": "apples_given_or_eaten", "5": "apples_given_to_friends", "17": "apples_given_to_teachers"}},
    84: {5: {"16": "scallops", "6": "dollars_per_scallop", "96": "dollars"}},
    85: {2: {"40": "percent_boys", "100": "percent_total", "300": "boys"}},
    86: {4: {"5": "person_hours_each", "5": "hours_elapsed", "10": "hours"}},
    88: {4: {"50": "dollars_target", "5": "dollars_per_hamburger", "10": "hamburgers_needed"}},
    89: {3: {"25": "brents_score", "5": "brents_mistakes", "5": "points_per_correct_answer"}},
    94: {4: {"10": "percent_gratuity", "100": "percent_total", "140": "total_bill_dollars", "14": "gratuity_dollars"}},
    97: {3: {"8": "ounces_peanuts", "2": "ounces_oil", "20": "ounces_peanut_butter", "x": "unbound"}},
    98: {4: {"3": "pieces_per_cookie", "1": "m_and_ms_per_cookie", "2": "chocolate_chips_per_cookie"}},
    120: {3: {"2": "dimensionless", "3": "steps_forward_from_start", "6": "steps_forward"}},
    121: {1: {"2": "pounds_jelly_beans", "2": "pounds_box", "4": "pounds_total"}},
    124: {1: {"5": "days_per_week", "5": "classes", "25": "class_days"}},
    126: {5: {"36": "helium_balloons", "0": "air_balloons", "36": "balloon_difference"}},
    129: {3: {"72": "good_oranges", "12": "students", "6": "oranges_per_student"}},
    130: {2: {"9": "dollars_per_friend_gift", "2": "parents", "18": "dollars"}},
    138: {3: {"200": "dollars_original_tank", "240": "dollars_enlarged_tank"}},
    139: {4: {"10": "homework_hours", "5": "available_nights", "2": "homework_hours_per_night"}},
    140: {2: {"10": "minutes_to_airport", "20": "minutes_waiting", "3": "hours_drive_time", "15": "minutes_drive_time", "115": "minutes_flight_trip"}},
    143: {5: {"10": "first_month_dollars", "3": "months_two_to_four", "30": "dollars_per_month", "45": "month_four_dollars", "2": "months_five_to_six", "205": "dollars"}},
    150: {3: {"60": "nuts_per_day_busy_squirrels", "60": "nuts_per_day_busy_squirrels", "20": "nuts_per_day_sleepy_squirrel", "140": "nuts_per_day"}},
    151: {3: {"0": "unused_seed_area"}},
    157: {5: {"0.3": "fraction_of_class", "1": "fraction_parts", "3": "fraction_parts", "10": "dollars_per_card", "50": "dollars"}},
    164: {1: {"3": "cookies_eaten", "2": "cookies_returned", "1": "cookies_eaten"}},
    165: {3: {"40": "other_color_marbles", "95": "marbles_after_friend_takes_five"}},
    166: {1: {"40": "gallons", "2": "gallons_lost_per_hour", "38": "gallons"}},
    169: {3: {"50": "percent_second_week_gain", "100": "dollars_first_week_gain", "50": "dollars_second_week_gain"}},
    172: {2: {"13200": "square_feet", "2": "feet_swath_width", "6600": "swaths"}},
    176: {4: {"16": "goals_in_match", "8": "fifteen_minute_periods", "2": "goals_per_period"}},
    184: {4: {"2": "dimensionless", "12": "years_age_difference", "5": "years", "79": "tims_age"}},
    200: {6: {"200": "dollars_profit", "5": "dollars_per_cone", "40": "ice_cream_cones"}},
    202: {1: {"12": "skulls", "4": "broomsticks", "28": "decorations_before_pumpkins"}},
    203: {3: {"20": "dollars_overtime_per_day", "5": "days", "100": "dollars_overtime"}},
    204: {5: {"4": "hours_outbound", "6": "hours_return"}},
    205: {3: {"600": "square_feet", "60": "dollars_per_square_foot", "36000": "dollars"}},
}

NUMBER = r"(?:\$?\d+(?:,\d{3})*(?:\.\d+)?)"
EQUATION = re.compile(rf"(?P<left>[0-9$(),.\s+*/-]+)\s*=\s*(?P<right>{NUMBER})")
BINDING_LINE = re.compile(r"^([^\t]+)\t([^\t]+)\t(.+)$")
SAFE_KIND = re.compile(r"^[a-z][a-z0-9_]*$")


@dataclass(frozen=True)
class Binding:
    magnitude: str
    kind: str
    span: str


def normalize_magnitude(text: str) -> str:
    return text.strip().replace("$", "").replace(",", "")


def normalize_kind(text: str) -> str:
    kind = re.sub(r"[^a-z0-9]+", "_", text.lower()).strip("_")
    return kind if SAFE_KIND.fullmatch(kind) else "unbound"


def bindings_from_response(response: str) -> list[Binding]:
    bindings: list[Binding] = []
    # Gemma renders the requested delimiter literally on some turns.  Accept
    # that transcription while retaining the same three-field contract.
    for line in response.replace("<TAB>", "\t").splitlines():
        match = BINDING_LINE.match(line.strip())
        if not match:
            continue
        magnitude, kind, span = match.groups()
        bindings.append(Binding(normalize_magnitude(magnitude), normalize_kind(kind), span))
    return bindings


def human_bindings(raw_index: int, step_number: int, step: str) -> list[Binding]:
    mapping = HUMAN_KIND_MAP.get(raw_index, {}).get(step_number, {})
    bindings: list[Binding] = []
    for magnitude, kind in mapping.items():
        if magnitude == "x":
            continue
        bindings.append(Binding(normalize_magnitude(magnitude), kind, magnitude))
    # A named-but-unmapped numeral must stay unbound in the ceiling too.
    for token in re.findall(NUMBER, step):
        magnitude = normalize_magnitude(token)
        if not any(binding.magnitude == magnitude for binding in bindings):
            bindings.append(Binding(magnitude, "unbound", token))
    return bindings


def model_bindings(problem: str, step: str, *, model: str) -> list[Binding]:
    prompt = (
        "Bind each magnitude to the kind it measures. One line per magnitude: "
        "magnitude<TAB>kind<TAB>verbatim span. Use unbound when the kind is unknown.\n\n"
        f"Problem:\n{problem}\n\nStudent step:\n{step}"
    )
    response = mtb_responders.ollama_complete(
        prompt, model=model, stop=None, stop_mode="post", num_predict=2048,
    )
    return bindings_from_response(response)


def binding_for(value: float, bindings: Iterable[Binding], span: str) -> Binding:
    wanted = normalize_magnitude(str(value))
    for binding in bindings:
        if binding.magnitude == wanted:
            return binding
    for binding in bindings:
        try:
            if abs(float(binding.magnitude) - value) < 0.0000001:
                return binding
        except ValueError:
            pass
    return Binding(wanted, "unbound", span)


def prolog_atom(text: str) -> str:
    if not SAFE_KIND.fullmatch(text):
        return "unbound"
    return text


def prolog_string(text: str) -> str:
    return json.dumps(text, ensure_ascii=False)


def quantity_term(value: float, binding: Binding) -> str:
    value_text = repr(value)
    return f"quantity({value_text},{prolog_atom(binding.kind)},{prolog_string(binding.span)})"


def run_quantity_expression(expression: str, claimed: str) -> str:
    goal = (
        "use_module(hermes(quantity_claim)),"
        f"quantity_claim:check_quantity_expression({expression},{claimed},D),"
        "get_dict(verdict,D,V),writeln(V)"
    )
    result = subprocess.run(
        ["swipl", "-q", "-l", str(PATHS), "-g", goal, "-t", "halt"],
        cwd=REPO_ROOT,
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode:
        return "not_checked"
    return result.stdout.strip().splitlines()[-1] if result.stdout.strip() else "not_checked"


def expression_tree(text: str) -> ast.AST | None:
    cleaned = text.replace("$", "").replace(",", "").strip()
    if not cleaned or re.search(r"[^0-9.()+*/\-\s]", cleaned):
        return None
    try:
        return ast.parse(cleaned, mode="eval").body
    except SyntaxError:
        return None


def prolog_expression(node: ast.AST, bindings: list[Binding]) -> str | None:
    """Render the parsed left-hand side as a term over quantity/3 leaves."""
    if isinstance(node, ast.Constant) and isinstance(node.value, (int, float)):
        value = float(node.value)
        return quantity_term(value, binding_for(value, bindings, str(node.value)))
    if not isinstance(node, ast.BinOp):
        return None
    operation = OPERATIONS.get(type(node.op))
    if operation is None:
        return None
    left = prolog_expression(node.left, bindings)
    right = prolog_expression(node.right, bindings)
    if left is None or right is None:
        return None
    return f"{operation}({left},{right})"


def quantity_step_verdict(step: str, bindings: list[Binding]) -> str:
    for match in EQUATION.finditer(step):
        tree = expression_tree(match.group("left"))
        # A bare magnitude is not a claim about how quantities compose.
        if not isinstance(tree, ast.BinOp):
            continue
        expression = prolog_expression(tree, bindings)
        if expression is None:
            continue
        right_value = float(normalize_magnitude(match.group("right")))
        claimed = quantity_term(right_value, binding_for(right_value, bindings, match.group("right")))
        verdict = run_quantity_expression(expression, claimed)
        if verdict in {"refuted", "incommensurable"}:
            return verdict
    return "not_checked"


def arithmetic_first_wrong(steps: list[str]) -> int | None:
    """Use the existing arithmetic reader/checker, one numbered source text."""
    text = "\n".join(f"Step {index + 1} - {step}" for index, step in enumerate(steps))
    escaped = json.dumps(text, ensure_ascii=False)
    goal = (
        "use_module(hermes(solution_step_check)),"
        f"check_solution_steps({escaped},R),get_dict(first_refuted_step,R,F),writeln(F)"
    )
    result = subprocess.run(
        ["swipl", "-q", "-l", str(REPO_ROOT / "paths.pl"), "-g", goal, "-t", "halt"],
        cwd=REPO_ROOT,
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode or not result.stdout.strip() or result.stdout.strip() == "none":
        return None
    try:
        return int(result.stdout.strip().splitlines()[-1])
    except ValueError:
        return None


def first_flagged(steps: list[str], bindings_by_step: dict[int, list[Binding]]) -> int | None:
    arithmetic = arithmetic_first_wrong(steps)
    quantity = next((index for index, step in enumerate(steps, 1)
                     if quantity_step_verdict(step, bindings_by_step.get(index, []))
                     in {"refuted", "incommensurable"}), None)
    candidates = [index for index in (arithmetic, quantity) if index is not None]
    return min(candidates) if candidates else None


def measure_arm(items: list[tuple[int, dict[str, Any]]], arm: str, model: str) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    counts: Counter[str] = Counter()
    records: list[dict[str, Any]] = []
    for position, (raw_index, example) in enumerate(items, 1):
        steps = list(example["student_incorrect_solution"][:-1])
        target = int(example["incorrect_index"]) + 1
        bindings: dict[int, list[Binding]] = {}
        if arm == "model":
            for step_number, step in enumerate(steps, 1):
                bindings[step_number] = model_bindings(example["problem"], step, model=model)
        elif arm == "human":
            for step_number, step in enumerate(steps, 1):
                bindings[step_number] = human_bindings(raw_index, step_number, step)
        else:
            bindings = {step_number: [] for step_number in range(1, len(steps) + 1)}
        flagged = (arithmetic_first_wrong(steps) if arm == "arithmetic"
                   else first_flagged(steps, bindings))
        counts["items"] += 1
        if flagged is None:
            counts["flagged_nothing"] += 1
        elif flagged == target:
            counts["exact"] += 1
        else:
            counts["wrong_step"] += 1
        counts["unbound"] += sum(
            binding.kind == "unbound" for values in bindings.values() for binding in values)
        counts["bindings"] += sum(len(values) for values in bindings.values())
        records.append({"raw_index": raw_index, "target": target, "flagged": flagged,
                        "bindings": {str(key): [binding.__dict__ for binding in value]
                                     for key, value in bindings.items()}})
        print(f"{arm}: {position}/{len(items)} raw={raw_index} target={target} flagged={flagged}", flush=True)
    return dict(counts), records


def summarize(counts: dict[str, Any]) -> dict[str, Any]:
    n = counts["items"]
    return {
        **counts,
        "exact_match_rate": counts.get("exact", 0) / n,
        "unbound_rate": counts.get("unbound", 0) / max(counts.get("bindings", 0), 1),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--limit", type=int, default=DEFAULT_LIMIT)
    parser.add_argument("--model", default=MODEL)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--skip-model", action="store_true")
    args = parser.parse_args()

    raw = load_dataset("eth-nlped/stepverify", "default", split="train")
    indexes = mtb_official_runner.select_indexes(TASK, len(raw), "dev", args.limit, 0)
    items = [(index, dict(raw[index])) for index in indexes]
    args.out.mkdir(parents=True, exist_ok=True)
    results: dict[str, Any] = {"task": TASK, "split": "dev", "indexes": indexes,
                               "model": args.model, "arms": {}}
    for arm in ("arithmetic", "human"):
        counts, records = measure_arm(items, arm, args.model)
        results["arms"][arm] = summarize(counts)
        (args.out / f"{arm}.json").write_text(json.dumps(records, indent=2) + "\n", encoding="utf-8")
    if not args.skip_model:
        counts, records = measure_arm(items, "model", args.model)
        results["arms"]["model"] = summarize(counts)
        (args.out / "model.json").write_text(json.dumps(records, indent=2) + "\n", encoding="utf-8")
    if "model" in results["arms"]:
        results["model_vs_arithmetic_disagreements"] = sum(
            1 for baseline, model in zip(
                json.loads((args.out / "arithmetic.json").read_text()),
                json.loads((args.out / "model.json").read_text()))
            if baseline["flagged"] != model["flagged"])
    (args.out / "summary.json").write_text(json.dumps(results, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(results, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
