#!/usr/bin/env python3
"""Mint, split, gate, and smoke Wave 5 solution programs."""
from __future__ import annotations

import argparse
import hashlib
import json
import random
import re
import subprocess
import sys
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any, Iterable

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[1]
for candidate in (str(SCRIPT_DIR), str(REPO_ROOT)):
    if candidate not in sys.path:
        sys.path.insert(0, candidate)

from build_wave5_row_map import (  # noqa: E402
    POOL, REPORT as ROW_MAP_REPORT, OUTPUT as ROW_MAP, USABLE,
    compound, load_pool_rows, sha256, split_args,
)
from contamination import (  # noqa: E402
    GRAM, SPLIT_GRAM, INDEX_PATH, REGISTER_LEXICON_PATH, OverlapGate,
    derive_register_lexicon, index_manifest, provenance_hits,
    register_aware_split_overlap, register_lexicon_bytes,
)
from training_text import WAVE5_CULLING_VERSION, cull_wave5_training_text  # noqa: E402

RUNTIME = REPO_ROOT / "hermes" / "app" / "runtime" / "experiments" / "sidekick"
DATASETS = RUNTIME / "datasets"
PAIRS = DATASETS / "wave5-solution-pairs.jsonl"
MINT_REPORT = DATASETS / "wave5-solution-mint-report.json"
SPLIT_MANIFEST = DATASETS / "wave5-split-manifest.json"
CALIBRATION = DATASETS / "wave5-admission-calibration.jsonl"
RUNNER = SCRIPT_DIR / "wave5_trace_runner.pl"
G8_ROW_MAP = REPO_ROOT / "curriculum/im/generated/wave5_g8_row_machine_map.jsonl"
BUILDER_VERSION = "wave5-solution-mint-v5-g8-scene-assembly"
SPLIT_SEED = 20260812
CALIBRATION_SEED = 20260813
SMOKE_SEED = 20260814
HELDOUT_FRACTION = 0.20
OUTPUT_TOKEN_BOUND = 256
V1_ASSIGNMENT_SHA256 = "d655bca1010356237d8a13cd7264309c1cdc553041ba15ef8cacd137fca02803"
NEWLY_USABLE_G8_LESSONS = (
    "IM-G8-U1-L14", "IM-G8-U1-L5", "IM-G8-U1-L9",
    "IM-G8-U2-L8", "IM-G8-U5-L15", "IM-G8-U8-L15",
)
NEWLY_USABLE_SCENE_LESSONS = ("IM-G3-U4-L14", "IM-G4-U5-L3")
SCENE_ADMISSION_EXCEPTIONS = {
    "im_defrag_cf10fdb1812467280bdb0cd0_1": {
        "reason": "statement_numbers_determine_a_5_by_15_array_scene",
        "scene_route": "array_grid", "doing": "repeat_equal_groups",
        "input": {"kind": "array_grid", "doing": "repeat_equal_groups", "a": 5, "b": 15},
        "result_term": "75", "family": "multiply",
    },
    "im_defrag_2c4f267512be836bf3b1a90d_1": {
        "reason": "statement_numbers_determine_a_3_by_4_array_scene",
        "scene_route": "array_grid", "doing": "repeat_equal_groups",
        "input": {"kind": "array_grid", "doing": "repeat_equal_groups", "a": 3, "b": 4},
        "result_term": "12", "family": "multiply",
    },
    "im_defrag_34a43048776c1449580fd37e_1": {
        "reason": "statement_numbers_determine_the_3_plus_4_deformation_beside_the_3_by_4_array",
        "scene_route": "array_grid", "doing": "add_instead_of_multiply",
        "input": {"kind": "array_grid", "doing": "add_instead_of_multiply", "a": 3, "b": 4},
        "result_term": "7", "family": "multiply",
    },
    "im_defrag_cdfdc977c2c2eacc034e7446_1": {
        "reason": "statement_numbers_determine_21_shared_equally_across_3_bars",
        "scene_route": "equal_share_bars", "doing": "fair_share_equal_groups",
        "input": {"kind": "equal_share_bars", "doing": "fair_share_equal_groups", "total": 21, "groups": 3},
        "result_term": "7", "family": "divide",
    },
}
PRE_AMENDMENT_COUNTS = {
    "pairs": 1152,
    "split_counts": {"held_out": 396, "train": 756},
    "duplicate_split_input_groups": 190,
    "differing_output_groups": 171,
    "held_out_differing_output_groups": 63,
}
REGISTER_GATE_BASELINES = {"pre_repair_pairs": 1531, "post_repair_strict_pairs": 1075}

DEMAND_TOKENS = (
    "analyze", "calculate", "choose", "compare", "complete", "construct",
    "convert", "describe", "determine", "draw", "estimate", "evaluate",
    "explain", "fill", "find", "give", "graph", "identify", "justify",
    "label", "list", "make", "match", "name", "order", "plot", "prove",
    "represent", "select", "show", "simplify", "solve", "sort", "state",
    "tell", "verify", "what", "when", "where", "which", "who", "why",
)
DEMAND_RE = re.compile(r"\b(?:" + "|".join(DEMAND_TOKENS) + r")\b", re.I)
HOW_MANY_RE = re.compile(r"\bhow\s+many\b", re.I)
IMAGE_KINDS = {"image", "diagram", "figure", "graph", "table", "picture"}
RESOLVED_REFERENT_STATUSES = {"carried_inline", "recovered", "resolved", "present", "available"}
REFERENT_FALLBACK_WORDS = (
    "expression", "equation", "number", "value", "area", "perimeter",
    "volume", "fraction", "decimal", "length", "width", "height", "distance",
    "time", "rate", "amount", "total", "difference", "product", "quotient",
)
NOUN_STOP = {
    "and", "or", "of", "to", "from", "more", "less", "than", "is", "are",
    "was", "were", "has", "have", "had", "in", "on", "at", "by", "for",
    "with", "each", "the", "a", "an", "another", "different", "same",
}
MEMBER_POSITION_RE = re.compile(
    r"(?:^|/)(?:expression|fraction_expression|printed_equation|"
    r"recovered_equation|compound_unit|item|equation)\(\d+\)"
    r"|(?:^|/)[a-z0-9_]*_item\(\d+\)",
    re.I,
)


def canonical_bytes(value: Any, *, pretty: bool = False) -> bytes:
    if pretty:
        return (json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n").encode()
    return (json.dumps(value, ensure_ascii=False, sort_keys=True,
                       separators=(",", ":")) + "\n").encode()


def file_sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def stable_rank(label: str, seed: int) -> str:
    return hashlib.sha256(f"{seed}:{label}".encode()).hexdigest()


def grade_of(lesson: str) -> str:
    return lesson.split("-", 2)[1][1:]


def genre_of(statement: str) -> str:
    return "word_problem" if "?" in statement else "expression_fragment"


def has_demand(row: dict[str, Any]) -> bool:
    statement = row["statement"]
    if "?" in statement or DEMAND_RE.search(statement) or HOW_MANY_RE.search(statement):
        return True
    for referent in row["referents"]:
        antecedent = str(referent.get("antecedent", ""))
        joined_kind = str(referent.get("kind", "")) in {"expression", "equation"}
        joined_surface = str(referent.get("surface", "")).casefold() in statement.casefold()
        if antecedent and joined_kind and joined_surface and (
            DEMAND_RE.search(antecedent) or HOW_MANY_RE.search(antecedent)
        ):
            return True
    return False


def compact_text(text: str) -> str:
    return " ".join(text.split())


def position_names_member(position: str) -> bool:
    """True when source provenance selects one member inside a task statement."""
    return bool(MEMBER_POSITION_RE.search(position))


def instruction_antecedent(row: dict[str, Any], span: str) -> str:
    """Recover the authored instruction carried by a defrag row, if present."""
    statement = compact_text(row["statement"])
    compact_span = compact_text(span)
    span_at = statement.find(compact_span) if compact_span else len(statement)
    prefix = statement[:span_at] if span_at >= 0 else statement
    sentence_candidates = []
    for match in re.finditer(
        r"(?:^|(?<=[.!?])\s+)(?P<sentence>.*?[.!?])(?=\s|$)", prefix
    ):
        sentence = re.sub(
            r"^(?:[•◦]\s*|\d+\.\s*|[a-z]\.\s*)", "", match.group("sentence")
        ).strip()
        if DEMAND_RE.search(sentence) or HOW_MANY_RE.search(sentence) or "?" in sentence:
            sentence_candidates.append(sentence)
    if sentence_candidates:
        return sentence_candidates[-1]
    for referent in row["referents"]:
        antecedent = compact_text(str(referent.get("antecedent", "")))
        if antecedent and re.search(r"[.!?]\s*$", antecedent):
            return antecedent
    if "?" in span or DEMAND_RE.search(span) or HOW_MANY_RE.search(span):
        return ""
    question_at = statement.find("?")
    if question_at >= 0 and (span_at < 0 or question_at < span_at):
        candidate = statement[: question_at + 1]
    else:
        candidate = re.split(r"\s*•\s*", statement, maxsplit=1)[0]
        candidate = re.split(r"\s+(?=\d+\.\s+)", candidate, maxsplit=1)[0]
        if span_at > 0 and candidate == statement:
            candidate = statement[:span_at]
    candidate = re.sub(r"(?:\s+[A-Z]){1,8}\s*$", "", candidate).strip(" ;:,-")
    if DEMAND_RE.search(candidate) or HOW_MANY_RE.search(candidate) or "?" in candidate:
        return candidate
    return ""


def numbered_item_span(statement: str, position: str) -> str:
    """Select an authored numbered task for provenance such as activity_2_item(3)."""
    selected = re.search(r"_item\((\d+)\)\s*$", position, re.I)
    if not selected:
        return ""
    item_number = selected.group(1)
    text = compact_text(statement)
    matches = list(re.finditer(r"(?<!\S)(\d+)\.\s+", text))
    for index, match in enumerate(matches):
        if match.group(1) != item_number:
            continue
        end = matches[index + 1].start() if index + 1 < len(matches) else len(text)
        return text[match.start():end].strip()
    return ""


def source_scoped_input(row: dict[str, Any], mapped: dict[str, Any]) -> tuple[str, dict[str, str]]:
    """Use one provenance member span while retaining the display statement elsewhere."""
    position = compact_text(str(mapped.get("source_position", "")))
    excerpt = compact_text(str(mapped.get("source_excerpt", ""))).lstrip("• ").strip()
    if not position_names_member(position) or not excerpt:
        return row["statement"], {
            "mode": "complete_statement",
            "source_position": position,
            "source_excerpt": excerpt,
            "instruction_antecedent": "",
        }
    statement = compact_text(row["statement"])
    if excerpt not in statement and has_demand(row):
        return statement, {
            "mode": "complete_statement_source_fallback",
            "source_position": position,
            "source_excerpt": excerpt,
            "instruction_antecedent": "",
        }
    list_markers = len(re.findall(r"(?<!\S)\d+\.\s+", statement))
    if excerpt == statement and ("•" in statement or list_markers >= 2):
        scope = {
            "mode": "item_source_span",
            "source_position": position,
            "source_excerpt": excerpt,
            "instruction_antecedent": instruction_antecedent(row, ""),
        }
        return operation_scoped_input(row, mapped, scope)
    task_item = numbered_item_span(row["statement"], position)
    if task_item and ("?" in task_item or DEMAND_RE.search(task_item) or HOW_MANY_RE.search(task_item)):
        return task_item, {
            "mode": "item_question_span",
            "source_position": position,
            "source_excerpt": excerpt,
            "instruction_antecedent": "",
        }
    antecedent = instruction_antecedent(row, excerpt)
    scoped = compact_text(" ".join(part for part in (antecedent, excerpt) if part))
    return scoped, {
        "mode": "item_source_span",
        "source_position": position,
        "source_excerpt": excerpt,
        "instruction_antecedent": antecedent,
    }


def display_term(term: str) -> str:
    """Render a mapped value as a compact mathematical span, not a new solution."""
    try:
        name, args = compound(term)
    except ValueError:
        return term
    if not args:
        return name
    if name == "frac" and len(args) == 2:
        return f"{display_term(args[0])}/{display_term(args[1])}"
    if name == "mixed" and len(args) == 3:
        return f"{args[0]} {args[1]}/{args[2]}"
    return f"{name}({', '.join(display_term(arg) for arg in args)})"


def mapped_operation_span(mapped: dict[str, Any]) -> str:
    if mapped.get("route") == "scene_satisfiable_exception":
        args = mapped["operand_terms"]
        return f"{mapped['doing']}({', '.join(args)})"
    family = mapped["family"]
    operands = [display_term(term) for term in mapped["operand_terms"]]
    symbol = {
        "add": "+", "add_fractions": "+", "decimal_add": "+",
        "subtract": "-", "subtract_fractions": "-",
        "multiply": "×", "divide": "÷",
    }.get(family)
    if symbol and len(operands) >= 2:
        return f"{operands[0]} {symbol} {operands[1]}"
    return f"{family}({', '.join(operands)})"


def operation_scoped_input(
    row: dict[str, Any], mapped: dict[str, Any], scope: dict[str, str]
) -> tuple[str, dict[str, str]]:
    """Narrow a still-ambiguous member to its one mechanically mapped operation."""
    operation = mapped_operation_span(mapped)
    if position_names_member(scope["source_position"]):
        antecedent = scope["instruction_antecedent"] or instruction_antecedent(row, operation)
        source_excerpt = compact_text(scope.get("source_excerpt", ""))
        relation = bool(re.search(r"(?:=|<|>)", source_excerpt))
        if relation and operation in source_excerpt:
            raw = compact_text(
                " • ".join(
                    part for part in (antecedent, source_excerpt, operation) if part
                )
            )
            mode = "item_relation_side"
        else:
            raw = compact_text(" ".join(part for part in (antecedent, operation) if part))
            mode = "item_mapped_operation"
    else:
        # These are compound single-demand tasks whose row map names more than
        # one scored operation. Preserve the authored task and name the one
        # mapped operation after the deterministic list separator.
        antecedent = ""
        raw = f"{row['statement']} • {operation}"
        mode = "compound_demand_mapped_operation"
    return raw, {
        **scope,
        "mode": mode,
        "mapped_operation_span": operation,
        "instruction_antecedent": antecedent or scope["instruction_antecedent"],
    }


def ambiguity_summary(pairs: Iterable[dict[str, Any]]) -> dict[str, int]:
    groups: defaultdict[tuple[str, str], list[dict[str, Any]]] = defaultdict(list)
    for pair in pairs:
        groups[(pair["split"], pair["input"])].append(pair)
    differing = [
        (key, group) for key, group in groups.items()
        if len({pair["output"] for pair in group}) > 1
    ]
    return {
        "duplicate_split_input_groups": sum(len(group) > 1 for group in groups.values()),
        "differing_output_groups": len(differing),
        "held_out_differing_output_groups": sum(key[0] == "held_out" for key, _ in differing),
        "pairs_in_differing_output_groups": sum(len(group) for _, group in differing),
    }


def admission(row: dict[str, Any]) -> tuple[bool, str]:
    if row["id"] in SCENE_ADMISSION_EXCEPTIONS:
        return (True, "scene_satisfiable_exception") if has_demand(row) else (False, "demand_gate")
    if row["status"] not in USABLE:
        return False, "status_gate"
    unresolved_image = any(
        str(ref.get("kind", "")).casefold() in IMAGE_KINDS
        and (str(ref.get("status", "")) not in RESOLVED_REFERENT_STATUSES
             or str(ref.get("absence_reason", "none")) != "none")
        for ref in row["referents"]
    )
    if row["visuals"] or unresolved_image:
        return False, "image_gate"
    unresolved_referent = any(
        str(ref.get("status", "")) not in RESOLVED_REFERENT_STATUSES
        or str(ref.get("absence_reason", "none")) != "none"
        for ref in row["referents"]
    )
    if unresolved_referent:
        return False, "referent_gate"
    if not has_demand(row):
        return False, "demand_gate"
    return True, "admitted"


def split_lessons(rows: list[dict[str, Any]]) -> tuple[dict[str, str], dict[str, Any]]:
    lesson_strata: defaultdict[str, set[tuple[str, str, str]]] = defaultdict(set)
    for row in rows:
        lesson_strata[row["lesson"]].add((grade_of(row["lesson"]), row["family"], row["genre"]))
    by_grade: defaultdict[str, list[str]] = defaultdict(list)
    for lesson in lesson_strata:
        by_grade[grade_of(lesson)].append(lesson)
    assignment: dict[str, str] = {}
    for grade, lessons in sorted(by_grade.items()):
        lessons = sorted(lessons)
        target_total = max(1, round(len(lessons) * HELDOUT_FRACTION)) if len(lessons) > 1 else 0
        target_total = min(target_total, max(0, len(lessons) - 1))
        stratum_lessons: defaultdict[tuple[str, str, str], set[str]] = defaultdict(set)
        for lesson in lessons:
            for stratum in lesson_strata[lesson]:
                stratum_lessons[stratum].add(lesson)
        targets = {
            stratum: (min(max(1, round(len(ids) * HELDOUT_FRACTION)), len(ids) - 1)
                      if len(ids) > 1 else 0)
            for stratum, ids in stratum_lessons.items()
        }
        chosen: set[str] = set()
        counts: Counter[tuple[str, str, str]] = Counter()
        while len(chosen) < target_total:
            candidates = [lesson for lesson in lessons if lesson not in chosen]
            def score(lesson: str) -> tuple[float, str]:
                gain = sum(max(0, targets[s] - counts[s]) / max(1, targets[s])
                           for s in lesson_strata[lesson])
                return (-gain, stable_rank(lesson, SPLIT_SEED))
            selected = min(candidates, key=score)
            chosen.add(selected)
            counts.update(lesson_strata[selected])
        for lesson in lessons:
            assignment[lesson] = "held_out" if lesson in chosen else "train"
    strata: defaultdict[str, Counter[str]] = defaultdict(Counter)
    for lesson, split in assignment.items():
        for grade, family, genre in lesson_strata[lesson]:
            strata[f"{grade}|{family}|{genre}"][split] += 1
    grade_counts: defaultdict[str, Counter[str]] = defaultdict(Counter)
    for lesson, split in assignment.items():
        grade_counts[grade_of(lesson)][split] += 1
    details = {
        "lesson_strata": {key: dict(value) for key, value in sorted(strata.items())},
        "lesson_counts_by_grade": {key: dict(value) for key, value in sorted(grade_counts.items())},
    }
    return assignment, details


def assignment_details(rows: list[dict[str, Any]], assignment: dict[str, str]) -> dict[str, Any]:
    strata: defaultdict[str, Counter[str]] = defaultdict(Counter)
    grade_counts: defaultdict[str, Counter[str]] = defaultdict(Counter)
    seen: set[tuple[str, str, str, str]] = set()
    for row in rows:
        lesson = row["lesson"]
        if lesson not in assignment:
            continue
        key = (lesson, grade_of(lesson), row["family"], row["genre"])
        if key in seen:
            continue
        seen.add(key)
        _, grade, family, genre = key
        strata[f"{grade}|{family}|{genre}"][assignment[lesson]] += 1
    for lesson, split in assignment.items():
        grade_counts[grade_of(lesson)][split] += 1
    return {
        "lesson_strata": {key: dict(value) for key, value in sorted(strata.items())},
        "lesson_counts_by_grade": {key: dict(value) for key, value in sorted(grade_counts.items())},
    }


def frozen_lesson_assignment() -> tuple[dict[str, str], dict[str, Any]]:
    """Read the v1 partition, including from a previously written v2 manifest."""
    if not SPLIT_MANIFEST.is_file():
        raise RuntimeError("frozen Wave 5 split manifest is missing")
    frozen = json.loads(SPLIT_MANIFEST.read_text(encoding="utf-8"))
    train_key = "v1_train_lesson_ids" if "v1_train_lesson_ids" in frozen else "train_lesson_ids"
    held_key = "v1_held_out_lesson_ids" if "v1_held_out_lesson_ids" in frozen else "held_out_lesson_ids"
    assignment = {
        **{lesson: "train" for lesson in frozen[train_key]},
        **{lesson: "held_out" for lesson in frozen[held_key]},
    }
    observed = hashlib.sha256(canonical_bytes({
        lesson: assignment[lesson] for lesson in sorted(assignment)
    })).hexdigest()
    if observed != V1_ASSIGNMENT_SHA256:
        raise RuntimeError(
            "stored lesson split changed: "
            f"expected {V1_ASSIGNMENT_SHA256}, observed {observed}"
        )
    return assignment, frozen


def referent_atom(row: dict[str, Any], mapped: dict[str, Any]) -> str | None:
    statement = row["statement"]
    for ref in row["referents"]:
        surface = " ".join(str(ref.get("surface", "")).split())
        if surface and surface.casefold() in statement.casefold():
            return atomize(surface)
    for term in mapped["operand_terms"]:
        if re.fullmatch(r"[A-Za-z][A-Za-z_]*", term) and term.casefold() in statement.casefold():
            return atomize(term)
    for match in re.finditer(r"(?<![A-Za-z])\d+(?:\.\d+)?\s+([A-Za-z][A-Za-z-]*)", statement):
        candidate = match.group(1).casefold()
        if candidate not in NOUN_STOP:
            return atomize(match.group(1))
    for word in REFERENT_FALLBACK_WORDS:
        if re.search(rf"\b{re.escape(word)}s?\b", statement, re.I):
            return atomize(word)
    return None


def atomize(text: str) -> str:
    atom = re.sub(r"[^a-z0-9]+", "_", text.casefold()).strip("_")
    if not atom:
        return ""
    if atom[0].isdigit():
        atom = "referent_" + atom
    return atom


def fact_value(term: str) -> str:
    name, args = compound(term)
    if name == "frac":
        return f"fraction({args[0]},{args[1]})"
    if name in {"mixed", "whole"}:
        return f"{name}({','.join(args)})"
    return term


def quantity_values(family: str, args: list[str]) -> list[tuple[str, str]]:
    if family in {"add_fractions", "subtract_fractions"}:
        return [("left", fact_value(args[0])), ("right", fact_value(args[1]))]
    if family in {"decimal_add", "decimal_compare"}:
        return [("left", f"decimal({args[0]},{args[1]})"),
                ("right", f"decimal({args[2]},{args[3]})")]
    if family == "decimal_value":
        return [("value", f"decimal({args[0]},{args[1]})")]
    if family == "unit_fraction":
        return [("value", f"fraction({args[0]},{args[1]})")]
    roles = {
        "compare_numerals_by_place_value": ["left", "right", "base"],
        "unit_cube_volume": ["length", "width", "height"],
        "rectangle_perimeter": ["length", "width"],
        "rectangle_missing_side_from_perimeter": ["perimeter", "known_side"],
        "rectangle_missing_side_from_area": ["area", "known_side"],
        "construct_rectangle_with_area": ["area"],
        "rectangle_side_lengths_for_area": ["area"],
        "convert_measurement": ["count", "conversion_factor"],
        "compare_rectangle_areas": ["first_length", "first_width", "second_length", "second_width"],
    }
    selected = args
    if family == "unit_cube_volume": selected = args[:3]
    elif family == "rectangle_perimeter": selected = args[:2]
    elif family in {"rectangle_missing_side_from_perimeter", "rectangle_missing_side_from_area"}: selected = args[:2]
    elif family == "convert_measurement": selected = [args[0], args[3]]
    elif family == "compare_rectangle_areas": selected = args[:4]
    names = roles.get(family, [f"operand_{index}" for index in range(1, len(selected) + 1)])
    return [(role, fact_value(value)) for role, value in zip(names, selected)]


def prolog_value(value: Any) -> str:
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, bool):
        return "true" if value else "false"
    if value is None:
        return "null"
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, list):
        return "[" + ",".join(prolog_value(item) for item in value) + "]"
    if isinstance(value, dict):
        return "_{" + ",".join(f"{key}:{prolog_value(value[key])}" for key in sorted(value)) + "}"
    raise TypeError(value)


def mint_program(row: dict[str, Any], ref: str) -> str:
    facts = [f"quantity({role},{value},{ref})."
             for role, value in quantity_values(row["family"], row["operand_terms"])]
    facts.append(f"asks(result,{ref}).")
    if row["route"] == "composition":
        rectangles = row["input"]["rectangles"]
        first, second = rectangles
        solve = (
            "solve(A) :- "
            f"hermes_encyclopedia:strategy_trace_dict(rectangle_area_unit_iteration,"
            f"_{{a:{first['length']},b:{first['width']}}},D1),"
            "get_dict(result,D1,R1),term_string(square_units(X),R1),"
            f"hermes_encyclopedia:strategy_trace_dict(rectangle_area_unit_iteration,"
            f"_{{a:{second['length']},b:{second['width']}}},D2),"
            "get_dict(result,D2,R2),term_string(square_units(Y),R2),"
            "(X<Y->A=less_than;X>Y->A=greater_than;A=equal_to)."
        )
    else:
        solve = (
            "solve(A) :- hermes_encyclopedia:strategy_trace_dict("
            f"{row['machine']},{prolog_value(row['input'])},D),get_dict(result,D,A)."
        )
    return "\n".join([*facts, solve])


def mint_g8_program(row: dict[str, Any]) -> str:
    if row.get("route") == "extant_machine":
        solve = (
            "solve(A) :- hermes_encyclopedia:strategy_trace_dict("
            f"{row['machine']},{prolog_value(row['input'])},D),get_dict(result,D,A)."
        )
    else:
        module = Path(row["module"]).stem
        solve = (
            "solve(A) :- wave5_pilot_route:g8_solution_result("
            f"{module},{row['machine']},{prolog_value(row['input'])},A)."
        )
    return "\n".join(["quantity(input,task_payload,task).", "asks(result,task).", solve])


def mint_scene_program(spec: dict[str, Any]) -> str:
    solve = (
        "solve(A) :- wave5_pilot_route:scene_solution_result("
        f"{spec['scene_route']},{prolog_value(spec['input'])},A)."
    )
    return "\n".join(["quantity(input,scene_payload,task).", "asks(result,task).", solve])


def load_g8_rows() -> tuple[list[dict[str, Any]], dict[str, Any]]:
    """Select one correct route per row; retain refused-only rows for accounting."""
    if not G8_ROW_MAP.is_file():
        raise RuntimeError(f"G8 row map is missing: {G8_ROW_MAP}")
    all_rows = [json.loads(line) for line in G8_ROW_MAP.read_text(encoding="utf-8").splitlines()
                if line.strip()]
    grouped: defaultdict[str, list[dict[str, Any]]] = defaultdict(list)
    for row in all_rows:
        grouped[row["id"]].append(row)
    selected: list[dict[str, Any]] = []
    refused_only: list[str] = []
    for row_id, options in sorted(grouped.items()):
        correct = [row for row in options if row["execution"]["outcome"] == "correct"]
        candidates = correct or options
        choice = min(candidates, key=lambda row: (
            row["machine"], json.dumps(row["input"], sort_keys=True, separators=(",", ":"))))
        selected.append(choice)
        if not correct:
            refused_only.append(row_id)
    if len(selected) != 95 or len(refused_only) != 2:
        raise RuntimeError(
            f"G8 route census changed: rows={len(selected)} refused_only={len(refused_only)}")
    return selected, {
        "map_lines": len(all_rows), "distinct_rows": len(selected),
        "correct_routed_rows": len(selected) - len(refused_only),
        "refused_only_rows": refused_only,
        "selection_law": "one correct route per row, lexical machine then canonical input; refused-only rows retained for exclusion accounting",
    }


class ProgramRunner:
    def __init__(self) -> None:
        self.process = subprocess.Popen(
            ["swipl", "-q", "-f", str(RUNNER)], cwd=REPO_ROOT, text=True,
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            bufsize=1,
        )

    def ask(self, request: dict[str, Any]) -> dict[str, Any]:
        assert self.process.stdin is not None and self.process.stdout is not None
        self.process.stdin.write(json.dumps(request, ensure_ascii=False, sort_keys=True) + "\n")
        self.process.stdin.flush()
        line = self.process.stdout.readline()
        if not line:
            stderr = self.process.stderr.read() if self.process.stderr else ""
            raise RuntimeError(f"program runner stopped: {stderr}")
        return json.loads(line)

    def run(self, program: str, expected: str) -> dict[str, Any]:
        return self.ask({"mode": "program", "program": program, "expected_term": expected})

    def close(self) -> None:
        if self.process.stdin and self.process.poll() is None:
            self.process.stdin.write('{"mode":"stop"}\n')
            self.process.stdin.flush()
            self.process.stdin.close()
        self.process.wait(timeout=10)
        if self.process.returncode:
            stderr = self.process.stderr.read() if self.process.stderr else ""
            raise RuntimeError(f"program runner failed: {stderr}")


def smoke_sample(pairs: list[dict[str, Any]], size: int = 100) -> list[dict[str, Any]]:
    groups: defaultdict[tuple[str, str], list[dict[str, Any]]] = defaultdict(list)
    for pair in pairs:
        groups[(pair["grade"], pair["family"])].append(pair)
    for group in groups.values():
        group.sort(key=lambda pair: stable_rank(pair["id"], SMOKE_SEED))
    selected: list[dict[str, Any]] = []
    keys = sorted(groups)
    index = 0
    while len(selected) < min(size, len(pairs)):
        progressed = False
        for key in keys:
            if index < len(groups[key]) and len(selected) < size:
                selected.append(groups[key][index])
                progressed = True
        if not progressed:
            break
        index += 1
    return selected


def calibration_rows(rows: list[dict[str, Any]], decisions: dict[str, str]) -> list[dict[str, Any]]:
    groups: defaultdict[tuple[str, str], list[dict[str, Any]]] = defaultdict(list)
    for row in rows:
        groups[(grade_of(row["lesson"]), decisions[row["id"]])].append(row)
    for group in groups.values():
        group.sort(key=lambda row: stable_rank(row["id"], CALIBRATION_SEED))
    selected: list[dict[str, Any]] = []
    index = 0
    keys = sorted(groups)
    while len(selected) < min(100, len(rows)):
        progressed = False
        for key in keys:
            if index < len(groups[key]) and len(selected) < 100:
                selected.append(groups[key][index])
                progressed = True
        if not progressed:
            break
        index += 1
    return [{
        "id": row["id"], "lesson": row["lesson"],
        "grade": grade_of(row["lesson"]), "decision": decisions[row["id"]],
        "statement": row["statement"], "referents": row["referents"],
        "visuals": row["visuals"], "review_status": "implementation_reviewed",
    } for row in selected]


def build() -> dict[Path, bytes]:
    if not ROW_MAP.is_file() or not ROW_MAP_REPORT.is_file():
        raise RuntimeError("row-map artifacts are missing; run build_wave5_row_map.py first")
    row_map_report = json.loads(ROW_MAP_REPORT.read_text(encoding="utf-8"))
    if row_map_report["pool_sha256"] != sha256(POOL):
        raise RuntimeError("row-map pool SHA does not match the frozen pool")
    mapped_rows = {row["id"]: row for row in (
        json.loads(line) for line in ROW_MAP.read_text(encoding="utf-8").splitlines() if line.strip()
    )}
    k7_pool_rows = load_pool_rows()
    g8_rows, g8_map_census = load_g8_rows()
    g8_by_id = {row["id"]: row for row in g8_rows}
    missing_g8_source_rows = sorted(set(g8_by_id) - {row["id"] for row in k7_pool_rows})
    if missing_g8_source_rows:
        raise RuntimeError(f"G8 routed rows missing from shared pool: {missing_g8_source_rows}")
    pool_rows = [g8_by_id.get(row["id"], row) for row in k7_pool_rows]
    for row in g8_rows:
        mapped_rows[row["id"]] = row
    k7_by_id = {row["id"]: row for row in k7_pool_rows}
    for row_id, spec in SCENE_ADMISSION_EXCEPTIONS.items():
        source_row = k7_by_id[row_id]
        operands = ([str(spec["input"]["a"]), str(spec["input"]["b"])]
                    if spec["scene_route"] == "array_grid"
                    else [str(spec["input"]["total"]), str(spec["input"]["groups"])])
        mapped_rows[row_id] = {
            "id": row_id, "family": spec["family"], "machine": f"scene:{spec['scene_route']}",
            "route": "scene_satisfiable_exception", "input": spec["input"],
            "doing": spec["doing"], "operand_terms": operands,
            "source_position": source_row["source_position"],
            "source_excerpt": source_row["source_excerpt"],
            "execution": {"outcome": "correct", "result_term": spec["result_term"]},
        }
    register_lexicon = derive_register_lexicon(
        ((row["lesson"], row["statement"]) for row in pool_rows),
        source=str(POOL.relative_to(REPO_ROOT)),
        source_sha256=sha256(POOL),
    )
    register_bytes = register_lexicon_bytes(register_lexicon)
    register_sha256 = hashlib.sha256(register_bytes).hexdigest()
    register_grams = {entry["gram"] for entry in register_lexicon["entries"]}
    decisions: dict[str, str] = {}
    admitted: list[dict[str, Any]] = []
    gate_counts: Counter[str] = Counter()
    g8_refused = set(g8_map_census["refused_only_rows"])
    for row in pool_rows:
        if row["id"] in g8_refused:
            decisions[row["id"]] = "g8_refused_by_name"
            gate_counts["g8_refused_by_name"] += 1
            continue
        passed, decision = admission(row)
        decisions[row["id"]] = decision
        if passed:
            mapped = mapped_rows[row["id"]]
            admitted.append({**row, "family": mapped["family"],
                             "genre": genre_of(row["statement"])})
        else:
            gate_counts[decision] += 1

    v1_assignment, frozen_manifest = frozen_lesson_assignment()
    newly_assignable = set(NEWLY_USABLE_G8_LESSONS) | set(NEWLY_USABLE_SCENE_LESSONS)
    new_rows = [row for row in admitted if row["lesson"] in newly_assignable]
    new_assignment, new_split_details = split_lessons(new_rows)
    if set(new_assignment) != newly_assignable:
        raise RuntimeError(f"new G8 split inputs changed: {sorted(new_assignment)}")
    assignment = {**v1_assignment, **new_assignment}
    unassigned_admitted = sorted({row["lesson"] for row in admitted if row["lesson"] not in assignment})
    if unassigned_admitted:
        raise RuntimeError(f"admitted lessons remain outside manifest v2: {unassigned_admitted}")
    assignment_body = {lesson: assignment[lesson] for lesson in sorted(assignment)}
    assignment_sha = hashlib.sha256(canonical_bytes(assignment_body)).hexdigest()
    v1_body = {lesson: v1_assignment[lesson] for lesson in sorted(v1_assignment)}
    v1_sha = hashlib.sha256(canonical_bytes(v1_body)).hexdigest()
    split_details = assignment_details(admitted, assignment)
    manifest = {
        "version": "wave5-lesson-split-v2", "seed": SPLIT_SEED,
        "heldout_fraction": HELDOUT_FRACTION,
        "pool": str(POOL.relative_to(REPO_ROOT)), "pool_sha256": sha256(POOL),
        "row_map_sha256": file_sha(ROW_MAP),
        "g8_row_map": str(G8_ROW_MAP.relative_to(REPO_ROOT)),
        "g8_row_map_sha256": file_sha(G8_ROW_MAP),
        "v1_assignment_sha256": v1_sha, "assignment_sha256": assignment_sha,
        "v1_train_lesson_ids": sorted(k for k, v in v1_assignment.items() if v == "train"),
        "v1_held_out_lesson_ids": sorted(k for k, v in v1_assignment.items() if v == "held_out"),
        "train_lesson_ids": sorted(k for k, v in assignment.items() if v == "train"),
        "held_out_lesson_ids": sorted(k for k, v in assignment.items() if v == "held_out"),
        "v2_added_lesson_assignments": {key: new_assignment[key] for key in sorted(new_assignment)},
        "v2_added_g8_lesson_assignments": {
            key: new_assignment[key] for key in NEWLY_USABLE_G8_LESSONS},
        "v2_added_scene_lesson_assignments": {
            key: new_assignment[key] for key in NEWLY_USABLE_SCENE_LESSONS},
        "v2_assignment_rule": {
            "law": "apply the manifest seeded grade-stratified greedy coverage rule to the newly usable lessons without changing any v1 assignment",
            "seed": SPLIT_SEED, "heldout_fraction": HELDOUT_FRACTION,
            "new_lesson_strata": new_split_details,
        },
        **split_details,
    }

    overlap = OverlapGate()
    prepared: list[dict[str, Any]] = []
    exclusions: Counter[str] = Counter(gate_counts)
    for name in (
        "status_gate", "image_gate", "referent_gate", "demand_gate",
        "unmapped_machine", "engine_guard_refused", "referent_extraction",
        "benchmark_13gram", "output_token_bound", "heldout_8gram",
        "g8_refused_by_name", "culling_invariant",
    ):
        exclusions[name] += 0
    exclusion_rows: defaultdict[str, list[str]] = defaultdict(list)
    culling = Counter()
    benchmark_hits: list[dict[str, Any]] = []
    token_drops: list[str] = []
    for row in admitted:
        mapped = mapped_rows[row["id"]]
        if not mapped["machine"]:
            exclusions["unmapped_machine"] += 1
            exclusion_rows["unmapped_machine"].append(row["id"])
            continue
        if mapped["execution"]["outcome"] in {"magnitude_refused", "execution_limit"}:
            exclusions["engine_guard_refused"] += 1
            exclusion_rows["engine_guard_refused"].append(row["id"])
            continue
        if mapped["execution"]["outcome"] != "correct":
            raise RuntimeError(f"silent execution exclusion for {row['id']}")
        if row["id"] in SCENE_ADMISSION_EXCEPTIONS:
            program = mint_scene_program(SCENE_ADMISSION_EXCEPTIONS[row["id"]])
        elif grade_of(row["lesson"]) == "8":
            program = mint_g8_program(mapped)
        else:
            ref = referent_atom(row, mapped)
            if not ref:
                exclusions["referent_extraction"] += 1
                exclusion_rows["referent_extraction"].append(row["id"])
                continue
            program = mint_program(mapped, ref)
        if len(program.split()) > OUTPUT_TOKEN_BOUND:
            exclusions["output_token_bound"] += 1
            exclusion_rows["output_token_bound"].append(row["id"])
            token_drops.append(row["id"])
            continue
        raw_input, input_scope = source_scoped_input(row, mapped)
        prepared.append({
            "row": row, "mapped": mapped, "program": program,
            "raw_input": raw_input, "input_scope": input_scope,
        })

    # First apply all provenance-declared member spans. If a scoped input still
    # maps to multiple programs, replace that span with the one operation that
    # the row map executed. This catches equation sides and compound tasks whose
    # evidence excerpt is shared across several rows.
    initial_groups: defaultdict[tuple[str, str], list[dict[str, Any]]] = defaultdict(list)
    culling_drops: set[str] = set()
    culling_survivors: list[dict[str, Any]] = []
    for item in prepared:
        row = item["row"]
        item["culled"] = cull_wave5_training_text(item["raw_input"])
        if not item["culled"].invariants_green:
            exclusions["culling_invariant"] += 1
            exclusion_rows["culling_invariant"].append(row["id"])
            culling_drops.add(row["id"])
            continue
        culling_survivors.append(item)
        initial_groups[(assignment[row["lesson"]], item["culled"].text)].append(item)
    prepared = culling_survivors
    refined_ids: set[str] = set()
    for group in initial_groups.values():
        if len({item["program"] for item in group}) <= 1:
            continue
        for item in group:
            row, mapped = item["row"], item["mapped"]
            item["raw_input"], item["input_scope"] = operation_scoped_input(
                row, mapped, item["input_scope"]
            )
            item["culled"] = cull_wave5_training_text(item["raw_input"])
            refined_ids.add(row["id"])

    pair_candidates: list[dict[str, Any]] = []
    scoped_input_by_id: dict[str, str] = {}
    scope_counts: Counter[str] = Counter()
    for item in prepared:
        row, mapped, culled = item["row"], item["mapped"], item["culled"]
        scope_counts[item["input_scope"]["mode"]] += 1
        culling["inputs_checked"] += 1
        culling["paired_dollar_spans_before"] += culled.paired_dollar_spans_before
        culling["paired_dollar_spans_after"] += culled.paired_dollar_spans_after
        culling["currency_dollars_before"] += culled.currency_dollars_before
        culling["currency_dollars_after"] += culled.currency_dollars_after
        culling["bullet_separators_before"] += culled.bullet_separators_before
        if not culled.invariants_green:
            raise RuntimeError(f"culling invariants failed for {row['id']}")
        scoped_input_by_id[row["id"]] = culled.text
        hits = overlap.hits(culled.text)
        if hits:
            exclusions["benchmark_13gram"] += 1
            exclusion_rows["benchmark_13gram"].append(row["id"])
            benchmark_hits.append({"id": row["id"], "grams": hits[:5]})
            continue
        source_map = G8_ROW_MAP if grade_of(row["lesson"]) == "8" else ROW_MAP
        provenance = {
            "source": str((G8_ROW_MAP if grade_of(row["lesson"]) == "8" else POOL).relative_to(REPO_ROOT)),
            "pool_sha256": file_sha(G8_ROW_MAP) if grade_of(row["lesson"]) == "8" else sha256(POOL),
            "row_evidence_sha256": row["evidence_sha256"],
            "row_map_sha256": file_sha(source_map),
            "mapping_builder": ("build_g8_row_machine_map.py" if grade_of(row["lesson"]) == "8"
                                else row_map_report["builder_version"]),
            "mint_builder": BUILDER_VERSION, "culling_version": WAVE5_CULLING_VERSION,
            "full_statement": row["statement"],
            "input_scope": item["input_scope"],
            "culling": {
                "paired_dollar_spans_before": culled.paired_dollar_spans_before,
                "paired_dollar_spans_after": culled.paired_dollar_spans_after,
                "currency_dollars_before": culled.currency_dollars_before,
                "currency_dollars_after": culled.currency_dollars_after,
                "bullet_separators_before": culled.bullet_separators_before,
                "bullet_normalization": "bullet_to_semicolon_v1",
            },
            "contamination_index": str(INDEX_PATH.relative_to(REPO_ROOT)),
            "contamination_index_sha256": file_sha(INDEX_PATH),
            "register_lexicon": str(REGISTER_LEXICON_PATH.relative_to(REPO_ROOT)),
            "register_lexicon_sha256": register_sha256,
            "lesson_split_version": manifest["version"],
            "lesson_split_assignment_sha256": assignment_sha,
        }
        if row["id"] in SCENE_ADMISSION_EXCEPTIONS:
            provenance["admission_exception"] = SCENE_ADMISSION_EXCEPTIONS[row["id"]]
        if provenance_hits(provenance):
            raise RuntimeError(f"forbidden benchmark provenance on {row['id']}")
        pair_candidates.append({
            "id": row["id"], "lesson": row["lesson"],
            "grade": grade_of(row["lesson"]), "family": mapped["family"],
            "genre": row["genre"], "split": assignment[row["lesson"]],
            "input": culled.text, "output": item["program"],
            "machine": mapped["machine"], "expected_answer": mapped["execution"]["result_term"],
            "provenance": provenance,
        })

    # The held-out side remains lesson-complete. Use item-scoped text wherever
    # a scored row was prepared; retain admitted source text for rows excluded
    # later by mapping, guard, or mechanical referent extraction.
    heldout_text: dict[str, str] = {}
    for row in admitted:
        if row["lesson"] not in assignment or assignment[row["lesson"]] != "held_out":
            continue
        if row["id"] in culling_drops:
            continue
        if row["id"] in scoped_input_by_id:
            heldout_text[row["id"]] = scoped_input_by_id[row["id"]]
            continue
        raw_input, _ = source_scoped_input(row, mapped_rows[row["id"]])
        heldout_text[row["id"]] = cull_wave5_training_text(raw_input).text
    training_text = {pair["id"]: pair["input"] for pair in pair_candidates if pair["split"] == "train"}
    overlap_result = register_aware_split_overlap(
        heldout_text, training_text, register_grams, SPLIT_GRAM
    )
    strict_shared = overlap_result["strict"]
    register_shared = overlap_result["register"]
    blocking_shared = overlap_result["blocking"]
    strict_touching = {hit["right"] for hit in strict_shared}
    touching = {hit["right"] for hit in blocking_shared}
    strict_pair_count = len(pair_candidates) - len(strict_touching)
    if touching:
        exclusions["heldout_8gram"] += len(touching)
        exclusion_rows["heldout_8gram"].extend(sorted(touching))
    pairs = [pair for pair in pair_candidates if pair["id"] not in touching]

    input_ambiguity = ambiguity_summary(pairs)
    if input_ambiguity["differing_output_groups"]:
        ambiguity_examples = []
        grouped_pairs: defaultdict[tuple[str, str], list[dict[str, Any]]] = defaultdict(list)
        for pair in pairs:
            grouped_pairs[(pair["split"], pair["input"])].append(pair)
        for key, group in grouped_pairs.items():
            if len({pair["output"] for pair in group}) > 1:
                ambiguity_examples.append({"split": key[0], "input": key[1],
                                           "ids": [pair["id"] for pair in group]})
        raise RuntimeError(
            "item-scoped-input invariant failed: "
            f"{input_ambiguity['differing_output_groups']} (split,input) groups have differing outputs: "
            f"{ambiguity_examples[:3]}"
        )

    smoke_rows = smoke_sample(pairs)
    runner = ProgramRunner()
    smoke_results: list[dict[str, Any]] = []
    try:
        for pair in smoke_rows:
            result = runner.run(pair["output"], pair["expected_answer"])
            smoke_results.append({"id": pair["id"], "grade": pair["grade"],
                                  "family": pair["family"], **result})
    finally:
        runner.close()
    smoke = {
        "sample_size": len(smoke_results),
        "grades": dict(sorted(Counter(row["grade"] for row in smoke_results).items())),
        "families": dict(sorted(Counter(row["family"] for row in smoke_results).items())),
        "parsed": sum(bool(row.get("parsed")) for row in smoke_results),
        "ran": sum(bool(row.get("ran")) for row in smoke_results),
        "answer_match": sum(bool(row.get("answer_match")) for row in smoke_results),
        "failures": [row for row in smoke_results if not row.get("answer_match")],
    }
    if smoke["parsed"] != 100 or smoke["ran"] != 100 or smoke["answer_match"] != 100:
        raise RuntimeError(f"100-program smoke failed: {smoke}")

    volumes: defaultdict[str, Counter[str]] = defaultdict(Counter)
    for pair in pairs:
        volumes[f"{pair['grade']}|{pair['family']}|{pair['genre']}"][pair["split"]] += 1
    reconciled = len(pairs) + sum(exclusions.values())
    if reconciled != len(pool_rows):
        raise RuntimeError(
            f"silent exclusion: pool={len(pool_rows)} pairs={len(pairs)} exclusions={dict(exclusions)}"
        )
    g8_ids = set(g8_by_id)
    g8_exclusions: Counter[str] = Counter(
        decisions[row_id] for row_id in g8_ids if decisions[row_id] != "admitted")
    for reason, row_ids in exclusion_rows.items():
        g8_exclusions[reason] += sum(row_id in g8_ids for row_id in row_ids)
    if sum(g8_exclusions.values()) + sum(pair["grade"] == "8" for pair in pairs) != 95:
        raise RuntimeError("G8 pair and exclusion accounting did not reconcile to 95 routed rows")
    report = {
        "builder_version": BUILDER_VERSION,
        "pool_total": len(pool_rows), "pool_sha256": sha256(POOL),
        "admitted_by_four_gates": len(admitted),
        "exclusion_counts": dict(sorted(exclusions.items())),
        "exclusion_row_examples": {key: value[:20] for key, value in sorted(exclusion_rows.items())},
        "silent_exclusions": len(pool_rows) - reconciled,
        "pairs": len(pairs),
        "split_counts": dict(sorted(Counter(pair["split"] for pair in pairs).items())),
        "volumes_by_grade_family_genre": {key: dict(value) for key, value in sorted(volumes.items())},
        "culling": {**dict(culling), "version": WAVE5_CULLING_VERSION,
                    "paired_dollar_residue_zero": culling["paired_dollar_spans_after"] == 0,
                    "currency_conserved": culling["currency_dollars_before"] == culling["currency_dollars_after"],
                    "bullet_normalization": "bullet_to_semicolon_v1"},
        "benchmark_gate": {**index_manifest(), "index_sha256": file_sha(INDEX_PATH),
                           "hits": len(benchmark_hits), "examples": benchmark_hits[:10]},
        "heldout_gate": {
            "gram": SPLIT_GRAM,
            "law": "exclude train pairs only for held-out 8-grams absent from the register lexicon",
            "heldout_rows": len(heldout_text),
            "training_pairs_checked": len(training_text),
            "strict_shared_gram_hits": len(strict_shared),
            "strict_pairs_blocked": len(strict_touching),
            "strict_pair_ids": sorted(strict_touching),
            "register_shared_gram_hits": len(register_shared),
            "register_pair_ids": sorted(strict_touching - touching),
            "blocking_shared_gram_hits": len(blocking_shared),
            "pairs_blocked": len(touching),
            "blocking_pair_ids": sorted(touching),
            "strict_examples": strict_shared[:10],
            "blocking_examples": blocking_shared[:10],
            "count_comparison": {
                "pre_repair_pairs": REGISTER_GATE_BASELINES["pre_repair_pairs"],
                "post_repair_strict_pairs": strict_pair_count,
                "post_repair_register_aware_pairs": len(pairs),
            },
            "register_lexicon": str(REGISTER_LEXICON_PATH.relative_to(REPO_ROOT)),
            "register_lexicon_sha256": register_sha256,
            "register_lexicon_size": register_lexicon["register_grams"],
        },
        "item_scoped_inputs": {
            "amendment": "wave5-s1-resume2-item-scoped-inputs",
            "scope_counts_before_8gram_gate": dict(sorted(scope_counts.items())),
            "operation_refinements": len(refined_ids),
            "full_statement_retained_in_provenance": True,
        },
        "input_ambiguity_invariant": {
            "law": "zero (split,input) groups with differing outputs",
            "before_amendment": PRE_AMENDMENT_COUNTS,
            "after_amendment": {"pairs": len(pairs), **input_ambiguity},
            "passed": input_ambiguity["differing_output_groups"] == 0,
        },
        "split_freeze": {
            "v1_assignment_sha256": v1_sha,
            "v1_expected_assignment_sha256": V1_ASSIGNMENT_SHA256,
            "v1_unchanged": v1_sha == V1_ASSIGNMENT_SHA256,
            "v2_assignment_sha256": assignment_sha,
            "added_assignments": manifest["v2_added_lesson_assignments"],
            "rule": manifest["v2_assignment_rule"],
        },
        "output_token_bound": OUTPUT_TOKEN_BOUND, "output_token_drops": token_drops,
        "g8_coverage": {
            **g8_map_census,
            "row_map": str(G8_ROW_MAP.relative_to(REPO_ROOT)),
            "row_map_sha256": file_sha(G8_ROW_MAP),
            "pair_count": sum(pair["grade"] == "8" for pair in pairs),
            "exclusion_counts": dict(sorted(g8_exclusions.items())),
            "silent_exclusions": 0,
        },
        "scene_satisfiable_readmission": {
            "rows": len(SCENE_ADMISSION_EXCEPTIONS),
            "row_ids": sorted(SCENE_ADMISSION_EXCEPTIONS),
            "reasons": {key: value["reason"] for key, value in sorted(SCENE_ADMISSION_EXCEPTIONS.items())},
        },
        "mapping_falsifier": row_map_report["legacy_falsifier"],
        "smoke": smoke,
        "artifacts": {
            "pairs": str(PAIRS.relative_to(REPO_ROOT)),
            "split_manifest": str(SPLIT_MANIFEST.relative_to(REPO_ROOT)),
            "calibration": str(CALIBRATION.relative_to(REPO_ROOT)),
        },
    }
    pair_bytes = b"".join(canonical_bytes(pair) for pair in pairs)
    calibration = calibration_rows(pool_rows, decisions)
    calibration_bytes = b"".join(canonical_bytes(row) for row in calibration)
    outputs = {
        PAIRS: pair_bytes,
        SPLIT_MANIFEST: canonical_bytes(manifest, pretty=True),
        CALIBRATION: calibration_bytes,
        REGISTER_LEXICON_PATH: register_bytes,
    }
    report["artifact_sha256"] = {
        str(path.relative_to(REPO_ROOT)): hashlib.sha256(data).hexdigest()
        for path, data in outputs.items()
    }
    outputs[MINT_REPORT] = canonical_bytes(report, pretty=True)
    return outputs


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="re-mint and require byte-identical artifacts")
    args = parser.parse_args()
    try:
        outputs = build()
    except (RuntimeError, subprocess.CalledProcessError) as error:
        print(str(error), file=sys.stderr)
        return 1
    if args.check:
        stale = [str(path) for path, data in outputs.items()
                 if not path.is_file() or path.read_bytes() != data]
        if stale:
            print("stale Wave 5 mint artifacts: " + ", ".join(stale), file=sys.stderr)
            return 1
        print(f"PASS Wave 5 double mint is byte-identical: {len(outputs)} artifacts")
        return 0
    for path, data in outputs.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
    report = json.loads(outputs[MINT_REPORT])
    print(json.dumps({
        "pairs": report["pairs"], "split_counts": report["split_counts"],
        "exclusion_counts": report["exclusion_counts"], "smoke": report["smoke"],
    }, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
