#!/usr/bin/env python3
"""Propose question-to-pattern links, then let the engine re-prove them.

Two proposers share one verification gate: the mechanical keyword baseline
(the floor any model has to clear) and glm-5.2 choosing from engine-carved
menus. A proposal becomes a stored move only when all three checks of the
design pass; everything else lands in quarantine with its failed check named,
because an unverified link is stalled pipeline input, not rubbish.
"""
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RUNTIME = ROOT / "hermes" / "app" / "runtime" / "experiments" / "questions"
PATTERN_INDEX = RUNTIME / "task_patterns.json"
MENU_INDEX = RUNTIME / "machine_menu.json"
ROW_MAP = ROOT / "curriculum" / "im" / "generated" / "wave5_row_machine_map.jsonl"
TRACE_RUNNER = ROOT / "scripts" / "sidekick" / "wave5_trace_runner.pl"

# Operation-hint family -> the row-map families it could name.
HINT_FAMILIES = {
    "add": {"add", "add_fractions", "decimal_add"},
    "subtract": {"subtract", "subtract_fractions"},
    "multiply": {"multiply"},
    "divide": {"divide", "unit_fraction"},
    "fraction": {"add_fractions", "subtract_fractions", "unit_fraction"},
    "decimal": {"decimal_add", "decimal_value", "decimal_compare"},
    "compare": {"compare_numerals_by_place_value", "decimal_compare", "compare_rectangle_areas"},
    "geometry": {
        "rectangle_perimeter", "rectangle_missing_side_from_perimeter",
        "rectangle_missing_side_from_area", "rectangle_side_lengths_for_area",
        "construct_rectangle_with_area", "compare_rectangle_areas", "unit_cube_volume",
    },
    "measurement": {"convert_measurement"},
}

ASSESSING_CUES = re.compile(
    r"^(what is|what are|how many|how much|what did you|how do you know|why do|why does|"
    r"why is|how did you|what do you notice about|which)\b", re.I)
ADVANCING_CUES = re.compile(
    r"\b(what equation|what expression|how could (?:we|you) record|how can (?:i|we|you) write|"
    r"what if|how could you use|how can you use|what would happen if|another way to|"
    r"a different strategy|how else|could you (?:show|write|use))\b", re.I)
ARTICULATE_CUES = re.compile(
    r"\b(how are (?:the|these).{0,40}(?:similar|different)|same and (?:what is )?different|"
    r"what is the same|why do .{0,40}have the same|what do (?:these|the) .{0,30}have in common|"
    r"connect(?:s|ed)? to|relate(?:s|d)? to)\b", re.I)


def load_patterns() -> dict:
    return json.loads(PATTERN_INDEX.read_text(encoding="utf-8"))


def load_menu() -> dict:
    return json.loads(MENU_INDEX.read_text(encoding="utf-8"))


def load_row_map() -> list[dict]:
    return [json.loads(line) for line in ROW_MAP.read_text(encoding="utf-8").splitlines() if line.strip()]


def lesson_pattern_numbers(rows: list[dict], patterns: dict) -> dict[tuple[str, str], dict]:
    """Numerals a lesson actually shows for a pattern, and what its machine answered."""
    from algebraicize import algebraicize

    table: dict[tuple[str, str], dict] = {}
    for row in rows:
        if not row.get("machine"):
            continue
        schema = algebraicize(row["family"], row.get("input"))
        if schema is None or schema["pattern_id"] not in patterns["patterns"]:
            continue
        key = (row["lesson"], schema["pattern_id"])
        entry = table.setdefault(
            key,
            {"parameters": {}, "results": set(), "rows": [],
             "witness_input": None, "witness_row": None, "machine": None},
        )
        for name, value in zip(schema["parameters"], schema["witness_values"]):
            entry["parameters"].setdefault(float(value), name)
        result = row["execution"].get("result_term") or ""
        for match in re.finditer(r"-?\d+(?:\.\d+)?", str(result)):
            entry["results"].add(float(match.group(0)))
        entry["rows"].append(row["id"])
        # The run check wants THIS lesson's numerals, not another lesson's
        # instance of the same region, so the witness is kept per lesson.
        if entry["witness_input"] is None and row["execution"].get("outcome") == "correct":
            entry["witness_input"] = row.get("input")
            entry["witness_row"] = row["id"]
            entry["machine"] = row["machine"]
    return table


class TraceRunner:
    """One persistent SWI-Prolog worker; the engine, not a reader, decides."""

    def __init__(self) -> None:
        self.process = subprocess.Popen(
            ["swipl", str(TRACE_RUNNER)],
            cwd=str(ROOT), stdin=subprocess.PIPE, stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL, text=True, encoding="utf-8",
        )
        self.cache: dict[str, dict] = {}

    def run(self, machine: str, machine_input: dict) -> dict:
        key = json.dumps([machine, machine_input], sort_keys=True)
        if key in self.cache:
            return self.cache[key]
        assert self.process.stdin and self.process.stdout
        self.process.stdin.write(
            json.dumps({"mode": "trace", "machine": machine, "input": machine_input}) + "\n")
        self.process.stdin.flush()
        line = self.process.stdout.readline()
        try:
            answer = json.loads(line)
        except json.JSONDecodeError:
            answer = {"ok": False, "outcome": "runner_failure", "validity": "", "result_term": ""}
        self.cache[key] = answer
        return answer

    def close(self) -> None:
        assert self.process.stdin
        try:
            self.process.stdin.write(json.dumps({"mode": "stop"}) + "\n")
            self.process.stdin.flush()
        except (BrokenPipeError, ValueError):
            pass
        self.process.wait(timeout=30)


def baseline_move_type(text: str) -> str:
    if ARTICULATE_CUES.search(text):
        return "advancing"
    if ADVANCING_CUES.search(text):
        return "advancing"
    if ASSESSING_CUES.search(text):
        return "assessing"
    return "general"


def baseline_effect(text: str, pattern_id: str, stronger: str | None, partners: list[str]) -> dict | None:
    """The licensed effect, in the three shapes the design and Q0 allow."""
    if ARTICULATE_CUES.search(text):
        return {"kind": "articulates", "value": f"constraint_of({pattern_id})"}
    if ADVANCING_CUES.search(text):
        if stronger:
            return {"kind": "raises", "value": stronger}
        return {"kind": "raises", "value": f"representation_of({pattern_id})"}
    if ASSESSING_CUES.search(text):
        return {"kind": "narrows", "value": partners}
    return None


def stronger_pattern(pattern_id: str, patterns: dict, lesson_patterns: list[str]) -> str | None:
    """A same-family region in this lesson whose guards are harder to satisfy."""
    here = patterns["patterns"][pattern_id]
    best: tuple[int, str] | None = None
    for candidate in lesson_patterns:
        if candidate == pattern_id:
            continue
        other = patterns["patterns"][candidate]
        if other["family"] != here["family"]:
            continue
        rank = sum(abs(int(value)) for value in other["witness"] if isinstance(value, (int, float)))
        mine = sum(abs(int(value)) for value in here["witness"] if isinstance(value, (int, float)))
        if rank > mine and (best is None or rank < best[0]):
            best = (rank, candidate)
    return best[1] if best else None


def propose_baseline(sentence, patterns: dict, menu: dict, numbers: dict) -> list[dict]:
    """Operation words pick a family, numerals pick a region, headings label the move."""
    lesson_patterns = [entry["pattern_id"] for entry in patterns["lesson_patterns"].get(sentence.lesson, [])]
    if not lesson_patterns:
        return []
    allowed: set[str] = set()
    for hint in sentence.operation_hints:
        allowed |= HINT_FAMILIES.get(hint, set())
    candidates = [
        pattern_id for pattern_id in lesson_patterns
        if not allowed or patterns["patterns"][pattern_id]["family"] in allowed
    ]
    if not candidates:
        return []
    if sentence.numerals:
        scored = []
        for pattern_id in candidates:
            entry = numbers.get((sentence.lesson, pattern_id))
            if not entry:
                continue
            bound = sum(
                1 for value in sentence.numerals
                if value in entry["parameters"] or value in entry["results"]
            )
            scored.append((-bound, pattern_id))
        if scored:
            scored.sort()
            if scored[0][0] < 0:
                candidates = [pattern_id for score, pattern_id in scored if score == scored[0][0]]
    pattern_id = sorted(candidates)[0]
    entry = patterns["patterns"][pattern_id]
    machine = entry["witness_machine"]
    registry_family = registry_family_of(machine, menu)
    partners = [
        item["kind"] for item in menu.get(registry_family, [])
        if item["polarity"] == "deformation"
    ]
    move_type = baseline_move_type(sentence.text)
    if move_type == "general":
        return []
    effect = baseline_effect(
        sentence.text, pattern_id,
        stronger_pattern(pattern_id, patterns, lesson_patterns), partners[:8])
    if effect is None:
        return []
    slot_map = {}
    numbers_entry = numbers.get((sentence.lesson, pattern_id), {"parameters": {}, "results": set()})
    for value in sentence.numerals:
        if value in numbers_entry["parameters"]:
            slot_map[repr(value)] = numbers_entry["parameters"][value]
        elif value in numbers_entry["results"]:
            slot_map[repr(value)] = "result_of(witness)"
    return [{
        "proposer": "keyword_baseline",
        "pattern_ids": [pattern_id],
        "machine": machine,
        "registry_family": registry_family,
        "context_polarity": "productive",
        "move_type": move_type,
        "effect": effect,
        "slot_map": slot_map,
        "rationale": "operation words chose the family; numerals chose the region",
    }]


def registry_family_of(machine: str, menu: dict) -> str:
    for family, kinds in menu.items():
        for item in kinds:
            if item["kind"] == machine:
                return family
    return "unregistered"


def verify(link: dict, sentence, patterns: dict, numbers: dict, runner: TraceRunner) -> dict:
    """The three checks. glm proposes; the machine re-proves or the link is quarantined."""
    failed: list[str] = []
    pattern_id = link["pattern_ids"][0] if link.get("pattern_ids") else None
    checks: dict[str, dict] = {}

    if pattern_id not in patterns["patterns"]:
        checks["run_check"] = {"passed": False, "reason": "unknown_pattern"}
        return {"verified": False, "failed": ["run_check"], "checks": checks}
    entry = patterns["patterns"][pattern_id]
    lesson_entry = numbers.get((sentence.lesson, pattern_id)) or {}
    machine = link.get("machine") or entry["witness_machine"]
    machine_input = lesson_entry.get("witness_input") or entry.get("witness_input")
    witness_row = lesson_entry.get("witness_row") or entry.get("witness_row")
    answer = runner.run(machine, machine_input)
    validity = answer.get("validity", "")
    wanted = "correct" if link["context_polarity"] == "productive" else "incorrect"
    run_ok = bool(answer.get("ok")) and validity == wanted
    checks["run_check"] = {
        "passed": run_ok, "machine": machine, "input": machine_input,
        "witness_row": witness_row,
        "witness_from_this_lesson": bool(lesson_entry.get("witness_input")),
        "validity": validity, "outcome": answer.get("outcome"),
        "claim": link["context_polarity"], "wanted_validity": wanted,
    }
    if not run_ok:
        failed.append("run_check")

    numbers_entry = numbers.get((sentence.lesson, pattern_id), {"parameters": {}, "results": set()})
    unbound = [
        value for value in sentence.numerals
        if value not in numbers_entry["parameters"] and value not in numbers_entry["results"]
    ]
    checks["slot_check"] = {
        "passed": not unbound, "numerals": sentence.numerals, "unbound": unbound,
        "slot_map": link.get("slot_map", {}),
    }
    if unbound:
        failed.append("slot_check")

    authored = sentence.label_origin == "author_heading"
    conflict = authored and link["move_type"] != sentence.record_type
    checks["label_check"] = {
        "passed": not conflict, "label_origin": sentence.label_origin,
        "authored_label": sentence.record_type if authored else None,
        "proposed": link["move_type"],
    }
    if conflict:
        failed.append("label_check")

    return {"verified": not failed, "failed": failed, "checks": checks}


def sorts_by_asymmetry(link: dict) -> bool:
    """F-Q2: assessing resolves Context, advancing raises TaskPattern or states its constraint."""
    kind = link["effect"]["kind"]
    if link["move_type"] == "assessing":
        return kind == "narrows"
    if link["move_type"] == "advancing":
        return kind in {"raises", "articulates"}
    return False
