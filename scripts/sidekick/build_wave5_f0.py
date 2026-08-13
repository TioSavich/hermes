#!/usr/bin/env python3
"""Build and score the Wave 5 deterministic extractor floor.

F0 deliberately has little information: fixed keyword rules select a family,
training counts select that family's modal machine, and regular expressions
select numerals from the held-out input.  Its emitted programs go through the
same persistent, three-second SWI-Prolog program runner used by the S1 mint.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any, Iterable


REPO = Path(__file__).resolve().parents[2]
DATASETS = REPO / "hermes/app/runtime/experiments/sidekick/datasets"
FLOORS = REPO / "hermes/app/runtime/experiments/sidekick/floors"
PAIRS = DATASETS / "wave5-solution-pairs.jsonl"
RUNNER = REPO / "scripts/sidekick/wave5_trace_runner.pl"
RESULTS_NAME = "wave5-f0-results.jsonl"
SUMMARY_NAME = "wave5-f0-floor.json"
BUILDER_VERSION = "wave5-f0-regex-keyword-modal-v1"
BLOCK_THRESHOLD = 0.90

NUMBER = r"(?:\d+\s+\d+\s*/\s*\d+|\d+\s*/\s*\d+|\d+(?:\.\d+)?)"
NUMBER_RE = re.compile(rf"(?<![\w.])({NUMBER})(?![\w.])")
EXPRESSION_RE = re.compile(
    rf"({NUMBER})\s*([+\-−×*÷])\s*({NUMBER})", re.IGNORECASE
)
UNKNOWN_ADDEND_RE = re.compile(
    rf"({NUMBER})\s*=\s*({NUMBER})\s*\+\s*(?:$|[?.])", re.IGNORECASE
)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def load_jsonl(path: Path) -> list[dict[str, Any]]:
    return [
        json.loads(line)
        for line in path.read_text(encoding="utf-8").splitlines()
        if line.strip()
    ]


def compact_json(value: Any) -> str:
    return json.dumps(value, sort_keys=True, separators=(",", ":"))


def write_jsonl(path: Path, rows: Iterable[dict[str, Any]]) -> None:
    path.write_text("".join(compact_json(row) + "\n" for row in rows), encoding="utf-8")


def write_json(path: Path, value: Any) -> None:
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")


class ProgramRunner:
    """Persistent interface to S1's bounded program execution path."""

    def __init__(self) -> None:
        self.process = subprocess.Popen(
            ["swipl", "-q", "-s", str(RUNNER)],
            cwd=REPO,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=1,
        )

    def run(self, program: str, expected: str) -> dict[str, Any]:
        if self.process.stdin is None or self.process.stdout is None:
            raise RuntimeError("Wave 5 program runner has no pipes")
        request = {"mode": "program", "program": program, "expected_term": expected}
        self.process.stdin.write(compact_json(request) + "\n")
        self.process.stdin.flush()
        line = self.process.stdout.readline()
        if not line:
            stderr = self.process.stderr.read() if self.process.stderr else ""
            raise RuntimeError(f"Wave 5 program runner stopped: {stderr}")
        return json.loads(line)

    def close(self) -> None:
        if self.process.poll() is None and self.process.stdin is not None:
            self.process.stdin.write('{"mode":"stop"}\n')
            self.process.stdin.flush()
        try:
            self.process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            self.process.kill()
            self.process.wait(timeout=5)

    def __enter__(self) -> ProgramRunner:
        return self

    def __exit__(self, *_: object) -> None:
        self.close()


def modal_machines(training: list[dict[str, Any]]) -> dict[str, str]:
    counts: dict[str, Counter[str]] = defaultdict(Counter)
    for pair in training:
        counts[pair["family"]][pair["machine"]] += 1
    return {
        family: sorted(machine_counts.items(), key=lambda item: (-item[1], item[0]))[0][0]
        for family, machine_counts in sorted(counts.items())
    }


def classify_family(text: str) -> tuple[str, str]:
    """Return a fixed keyword family and the rule that selected it."""
    lowered = text.lower().replace("−", "-")
    if "rectang" in lowered and "perimeter" in lowered:
        return "rectangle_perimeter", "keyword:rectangle+perimeter"
    if "rectang" in lowered and "area" in lowered and (
        "side length" in lowered or "possible side" in lowered
    ):
        return "rectangle_side_lengths_for_area", "keyword:rectangle+area+side"
    if ("volume" in lowered or "cubic" in lowered) and any(
        word in lowered for word in ("length", "wide", "width", "tall", "height")
    ):
        return "unit_cube_volume", "keyword:volume+dimensions"
    unknown = UNKNOWN_ADDEND_RE.search(lowered)
    if unknown:
        return "subtract", "equation:unknown_addend"
    expression = EXPRESSION_RE.search(lowered)
    if expression:
        left, operator, right = expression.groups()
        fractional = "/" in left or "/" in right
        if operator == "+":
            return ("add_fractions" if fractional else "add"), "operator:+"
        if operator == "-":
            return ("subtract_fractions" if fractional else "subtract"), "operator:-"
        if operator in {"×", "*"}:
            return "multiply", f"operator:{operator}"
        if operator == "÷":
            return "divide", "operator:÷"
    if any(phrase in lowered for phrase in (
        "divided by", "divide ", "quotient", "shared equally", "equal groups",
        "how many groups", "how many piles", "in each group", "per group",
    )):
        return "divide", "keyword:division"
    if any(phrase in lowered for phrase in (
        "product", "multiply", "times as many", "groups of", "rows of",
        "each hand", "each bag", "each box", "each package", "each row",
    )):
        return "multiply", "keyword:multiplication"
    if any(phrase in lowered for phrase in (
        "how many fewer", "how many more", "difference", "are left", "is left",
        "remain", "takes out", "takes away", "gave away", "gives away",
        "spent", "decrease", "fewer than",
    )):
        return "subtract", "keyword:subtraction"
    if any(phrase in lowered for phrase in (
        "altogether", "in all", "total", "combined", "sum", "join",
        "added", "more people", "more books", "how many are",
    )):
        return "add", "keyword:addition"
    if "each" in lowered:
        return "multiply", "keyword:each-fallback"
    return "add", "fallback:add"


def parse_number(token: str) -> dict[str, int | str]:
    normalized = re.sub(r"\s+", " ", token.strip())
    mixed = re.fullmatch(r"(\d+) (\d+)\s*/\s*(\d+)", normalized)
    if mixed:
        return {
            "kind": "mixed",
            "whole": int(mixed.group(1)),
            "n": int(mixed.group(2)),
            "d": int(mixed.group(3)),
            "term": f"mixed({mixed.group(1)},{mixed.group(2)},{mixed.group(3)})",
        }
    fraction = re.fullmatch(r"(\d+)\s*/\s*(\d+)", normalized)
    if fraction:
        return {
            "kind": "fraction",
            "n": int(fraction.group(1)),
            "d": int(fraction.group(2)),
            "term": f"fraction({fraction.group(1)},{fraction.group(2)})",
        }
    return {"kind": "number", "term": normalized}


def extract_numbers(text: str, family: str) -> tuple[list[dict[str, int | str]], str]:
    cleaned = re.sub(r"^\s*\d+\.\s+", "", text)
    unknown = UNKNOWN_ADDEND_RE.search(cleaned)
    if family == "subtract" and unknown:
        return [parse_number(unknown.group(1)), parse_number(unknown.group(2))], "unknown-addend"
    expression = EXPRESSION_RE.search(cleaned)
    if expression:
        return [parse_number(expression.group(1)), parse_number(expression.group(3))], "explicit-expression"
    numbers = [parse_number(match.group(1)) for match in NUMBER_RE.finditer(cleaned)]
    if family == "subtract" and len(numbers) >= 2 and all(
        item["kind"] == "number" and re.fullmatch(r"\d+(?:\.\d+)?", str(item["term"]))
        for item in numbers[:2]
    ):
        first_two = sorted(numbers[:2], key=lambda item: float(str(item["term"])), reverse=True)
        return first_two, "first-two-largest-first"
    return numbers, "first-numbers"


def fraction_dict(value: dict[str, int | str]) -> str:
    if value["kind"] == "mixed":
        return f"_{{d:{value['d']},n:{value['n']},whole:{value['whole']}}}"
    return f"_{{d:{value['d']},n:{value['n']}}}"


def build_program(family: str, machine: str, numbers: list[dict[str, int | str]]) -> str | None:
    needed = 1 if family == "rectangle_side_lengths_for_area" else 3 if family == "unit_cube_volume" else 2
    if len(numbers) < needed:
        return None
    terms = [str(item["term"]) for item in numbers]
    if family in {"add", "subtract", "multiply", "divide"}:
        wire = f"_{{a:{terms[0]},b:{terms[1]}}}"
        facts = [f"quantity(operand_1,{terms[0]},floor_item).", f"quantity(operand_2,{terms[1]},floor_item)."]
    elif family in {"add_fractions", "subtract_fractions"}:
        if numbers[0]["kind"] not in {"fraction", "mixed"} or numbers[1]["kind"] not in {"fraction", "mixed"}:
            return None
        kind = "fraction_addend_pair" if family == "add_fractions" else "fraction_minuend_subtrahend"
        wire = f'_{{kind:"{kind}",left:{fraction_dict(numbers[0])},right:{fraction_dict(numbers[1])}}}'
        facts = [f"quantity(left,{terms[0]},floor_item).", f"quantity(right,{terms[1]},floor_item)."]
    elif family == "rectangle_perimeter":
        wire = f'_{{kind:"rectangle_with_unit",length:{terms[0]},unit:"floor_unit",width:{terms[1]}}}'
        facts = [f"quantity(length,{terms[0]},floor_unit).", f"quantity(width,{terms[1]},floor_unit)."]
    elif family == "rectangle_side_lengths_for_area":
        wire = f'_{{area:{terms[0]},kind:"area_scope",scope:"all"}}'
        facts = [f"quantity(area,{terms[0]},square_units)."]
    elif family == "unit_cube_volume":
        wire = f'_{{height:{terms[2]},kind:"rectangular_prism",length:{terms[0]},width:{terms[1]}}}'
        facts = [
            f"quantity(length,{terms[0]},floor_unit).",
            f"quantity(width,{terms[1]},floor_unit).",
            f"quantity(height,{terms[2]},floor_unit).",
        ]
    else:
        return None
    return "\n".join(
        facts
        + [
            "asks(result,floor_item).",
            f"solve(A) :- hermes_encyclopedia:strategy_trace_dict({machine},{wire},D),get_dict(result,D,A).",
        ]
    )


def rate(numerator: int, denominator: int) -> float | None:
    return round(numerator / denominator, 6) if denominator else None


def summarize(rows: list[dict[str, Any]], key_fields: tuple[str, ...]) -> list[dict[str, Any]]:
    grouped: dict[tuple[str, ...], list[dict[str, Any]]] = defaultdict(list)
    for row in rows:
        grouped[tuple(str(row[field]) for field in key_fields)].append(row)
    summaries = []
    for key, members in sorted(grouped.items()):
        total = len(members)
        executed = sum(bool(row["execute_match"]) for row in members)
        validity = sum(bool(row["validity_match"]) for row in members)
        answers = sum(bool(row["answer_match"]) for row in members)
        composite = sum(bool(row["validity_match"] and row["answer_match"]) for row in members)
        summaries.append(
            {
                **dict(zip(key_fields, key)),
                "n": total,
                "execute_count": executed,
                "execute_rate": rate(executed, total),
                "validity_match_count": validity,
                "validity_match": rate(validity, total),
                "answer_match_count": answers,
                "answer_match": rate(answers, total),
                "validity_answer_composite_count": composite,
                "validity_answer_composite": rate(composite, total),
            }
        )
    return summaries


def build(output_dir: Path) -> dict[str, Any]:
    pairs = load_jsonl(PAIRS)
    training = [pair for pair in pairs if pair["split"] == "train"]
    held_out = [pair for pair in pairs if pair["split"] == "held_out"]
    modes = modal_machines(training)
    results: list[dict[str, Any]] = []
    with ProgramRunner() as runner:
        for pair in held_out:
            predicted_family, family_rule = classify_family(pair["input"])
            numbers, number_rule = extract_numbers(pair["input"], predicted_family)
            machine = modes.get(predicted_family)
            program = build_program(predicted_family, machine, numbers) if machine else None
            execution = (
                runner.run(program, pair["expected_answer"])
                if program
                else {"ok": False, "parsed": False, "ran": False, "answer_match": False, "result_term": ""}
            )
            ran = bool(execution.get("parsed") and execution.get("ran"))
            results.append(
                {
                    "id": pair["id"],
                    "lesson": pair["lesson"],
                    "grade": pair["grade"],
                    "genre": pair["genre"],
                    "ground_family": pair["family"],
                    "predicted_family": predicted_family,
                    "family_rule": family_rule,
                    "family_match": predicted_family == pair["family"],
                    "number_rule": number_rule,
                    "numbers": numbers,
                    "machine": machine,
                    "program": program,
                    "expected_answer": pair["expected_answer"],
                    "result_term": execution.get("result_term", ""),
                    "execute_match": ran,
                    "validity_match": ran,
                    "answer_match": bool(execution.get("answer_match")),
                    "runner": execution,
                }
            )
    genre_strata = summarize(results, ("genre",))
    word = next(row for row in genre_strata if row["genre"] == "word_problem")
    composite = float(word["validity_answer_composite"] or 0.0)
    summary = {
        "builder": BUILDER_VERSION,
        "source": str(PAIRS.relative_to(REPO)),
        "source_sha256": sha256(PAIRS),
        "runner": str(RUNNER.relative_to(REPO)),
        "execution_cap_seconds": 3,
        "held_out_count": len(held_out),
        "modal_machines": modes,
        "metric_law": {
            "execute_rate": "program parsed and solve/1 ran in the bounded S1 runner",
            "validity_match": "successful productive-machine execution equals the solution row's correct validity",
            "answer_match": "runner result term equals expected_answer",
            "validity_answer_composite": "validity_match and answer_match on the same item",
            "pooling": "genre strata are reported separately and are never pooled",
        },
        "genre_strata": genre_strata,
        "genre_family_strata": summarize(results, ("genre", "ground_family")),
        "block_check": {
            "genre": "word_problem",
            "metric": "validity_answer_composite",
            "value": composite,
            "threshold": BLOCK_THRESHOLD,
            "blocked": composite >= BLOCK_THRESHOLD,
        },
    }
    output_dir.mkdir(parents=True, exist_ok=True)
    write_jsonl(output_dir / RESULTS_NAME, results)
    write_json(output_dir / SUMMARY_NAME, summary)
    return summary


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", type=Path, default=FLOORS)
    args = parser.parse_args()
    summary = build(args.output_dir)
    check = summary["block_check"]
    print(
        f"F0 word_problem validity+answer composite={check['value']:.6f} "
        f"threshold={check['threshold']:.2f} blocked={str(check['blocked']).lower()}"
    )
    print(args.output_dir / SUMMARY_NAME)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
