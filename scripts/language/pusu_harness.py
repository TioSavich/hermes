#!/usr/bin/env python3
"""Run the parsed-understood-solved-understood harness over IM task statements.

The harness processes every eligible defragged statement in source order.  It
checkpoints one JSONL row after each statement and resumes from that ledger.
No model or network service is involved.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
from collections import Counter, defaultdict
from fractions import Fraction
from functools import lru_cache
from pathlib import Path
from typing import Any

from probe_reader_coverage import sentences
from probe_task_statements import load_rows
from surface_normalizer import normalize_surface


REPO = Path(__file__).resolve().parents[2]
HARNESS = Path(__file__).resolve()
RUNNER = REPO / "scripts/language/pusu_harness_runner.pl"
STANDARDS_ROUTER = REPO / "scripts/language/standards_router_runner.pl"
SENTENCE_SPLITTER = REPO / "scripts/language/probe_reader_coverage.py"
TASK_PROBE = REPO / "scripts/language/probe_task_statements.py"
SOURCE = REPO / "curriculum/im/generated/compiled_defragged_task_instances.pl"
READER = REPO / "knowledge/strategies/abstraction/word_problem_reader_pilot.pl"
APE_READER = REPO / "knowledge/strategies/abstraction/ape_reader_pilot.pl"
FORCE_PILOT = REPO / "knowledge/strategies/abstraction/pedagogy_force_pilot.pl"
EXPRESSION_READER = (
    REPO
    / "knowledge/strategies/abstraction/printed_expression_reader_pilot.pl"
)
APE_LEXICON = REPO / "hermes/app/runtime/experiments/language/ape_user_lexicon.pl"
MORPHOLOGY = REPO / "knowledge/strategies/abstraction/english_morphology.pl"
SATURATOR = REPO / "scripts/sidekick/diagnosis_saturate.pl"
LEGACY_TRUTH = REPO / "curriculum/im/generated/wave5_row_machine_map.jsonl"
G8_TRUTH = REPO / "curriculum/im/generated/wave5_g8_row_machine_map.jsonl"
SURFACE_NORMALIZER = REPO / "scripts/language/surface_normalizer.py"
# Gitignored runtime stores the readers load if present. Their presence
# changes what a run measures, so they join the hash set (with an explicit
# sentinel when absent) and the summary records which condition ran.
WEBSTER_LEXICON = REPO / "hermes/app/runtime/experiments/language/webster_lexicon.pl"
LEXICAL_TYPINGS = REPO / "hermes/app/runtime/experiments/language/lexical_typings.pl"
DEFAULT_OUTPUT = REPO / "hermes/app/runtime/experiments/language/pusu_results.jsonl"
DEFAULT_SUMMARY = REPO / "hermes/app/runtime/experiments/language/pusu_summary.json"
SCHEMA = "pusu_harness_v7"
EXPECTED_ELIGIBLE = 4712

PLAIN_NUMBER = re.compile(r"^[+-]?(?:\d+(?:\.\d*)?|\.\d+)$")
RATIONAL_NUMBER = re.compile(r"^([+-]?\d+)r(\d+)$")
FRACTION_TEXT = re.compile(r"^([+-]?\d+)\s*/\s*(\d+)$")

ORDER_VERDICT_MAP = {
    # Fraction and rectangle-area order machines.
    "less_than": "less_than",
    "equivalent": "equal_to",
    "greater_than": "greater_than",
    # Decimal order machines.
    "less": "less_than",
    "equal": "equal_to",
    "more": "greater_than",
    # Counting order machines.
    "fewer": "less_than",
    "same_number": "equal_to",
}


def file_sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def source_hashes() -> dict[str, str]:
    hashes = {
        path.name: file_sha(path)
        for path in (
            HARNESS,
            RUNNER,
            STANDARDS_ROUTER,
            SENTENCE_SPLITTER,
            TASK_PROBE,
            SOURCE,
            READER,
            APE_READER,
            FORCE_PILOT,
            EXPRESSION_READER,
            APE_LEXICON,
            MORPHOLOGY,
            SATURATOR,
            SURFACE_NORMALIZER,
            LEGACY_TRUTH,
            G8_TRUTH,
        )
    }
    # A run without a gitignored store is legal but measures a different
    # reader; the sentinel makes the two conditions non-resumable into each
    # other instead of silently mixed.
    for optional in (WEBSTER_LEXICON, LEXICAL_TYPINGS):
        hashes[optional.name] = file_sha(optional) if optional.exists() else "absent"
    return hashes


def canonical_line(value: dict[str, Any]) -> str:
    return json.dumps(
        value, ensure_ascii=False, sort_keys=True, separators=(",", ":")
    ) + "\n"


def ratio(numerator: int, denominator: int) -> dict[str, int | float | None]:
    return {
        "numerator": numerator,
        "denominator": denominator,
        "rate": numerator / denominator if denominator else None,
    }


def grade_of(lesson: str) -> str:
    match = re.match(r"^IM-G(K|[1-8])-", lesson)
    if not match:
        raise ValueError(f"unexpected lesson id: {lesson}")
    return match.group(1)


def split_arguments(text: str) -> list[str]:
    parts: list[str] = []
    start = 0
    depth = 0
    quoted = False
    escaped = False
    for index, character in enumerate(text):
        if escaped:
            escaped = False
            continue
        if character == "\\" and quoted:
            escaped = True
            continue
        if character == '"':
            quoted = not quoted
            continue
        if quoted:
            continue
        if character in "([":
            depth += 1
        elif character in ")]":
            depth -= 1
        elif character == "," and depth == 0:
            parts.append(text[start:index].strip())
            start = index + 1
    parts.append(text[start:].strip())
    return parts


def compound(text: str) -> tuple[str, list[str]]:
    text = text.strip()
    if "(" not in text or not text.endswith(")"):
        return text, []
    name, rest = text.split("(", 1)
    return name, split_arguments(rest[:-1])


def unquote(text: str) -> str:
    text = text.strip()
    if len(text) >= 2 and text[0] == text[-1] == '"':
        return json.loads(text)
    return text


def exact_value(text: str) -> Fraction | None:
    text = unquote(text.strip())
    rational = RATIONAL_NUMBER.fullmatch(text)
    if rational:
        return Fraction(int(rational.group(1)), int(rational.group(2)))
    fraction = FRACTION_TEXT.fullmatch(text)
    if fraction:
        return Fraction(int(fraction.group(1)), int(fraction.group(2)))
    if PLAIN_NUMBER.fullmatch(text):
        return Fraction(text)
    return None


def normalize_order_verdict(term: str) -> str | None:
    """Map every registered order-result alphabet to one canonical one."""
    return ORDER_VERDICT_MAP.get(unquote(term.strip()))


# --- The completion guards --------------------------------------------------
#
# A completion can be arithmetically consistent and still answer a different
# question than the one asked. All 19 wrong StepVerify completions measured
# on 2026-08-15 derived through the rate lane on problems whose stated
# structure the program had not carried: printed numerals never bound, a
# stated percent never read, a difference asked and never taken, or a rate
# answering where an amount was asked. Four derived readings — never stored
# facts — let the ledger demote such a completion. Every check was verified
# to fire on all 19 and on zero truth-agreeing corpus completions before it
# shipped. A silent reading yields no opinion; the guards only ever demote,
# never create or alter an answer. Lemma-level typings live behind the
# lexical typing store seam
# (knowledge/strategies/abstraction/lexical_typing_store.pl); these guards
# read only the program and the statement's own surface.

# The asked kind is read from the REQUEST — the span from the last
# interrogative marker to the question mark — never from the whole
# sentence. "If you fold 5 shirts per minute for 8 minutes, how many
# shirts will you fold?" states a rate and requests an amount; the first
# guard shipped read the stated `per` as the request and demoted two
# truth-agreeing corpus completions before this narrowing (2026-08-15).
REQUEST_MARKER = re.compile(r"\bhow (?:many|much)\b|\bwhat\b")
REQUEST_RATE = re.compile(r"\bper\b|\brate\b|^how many times\b")
ASKED_CHANGE = re.compile(r"\bhow (?:many|much) (?:more|fewer|less)\b")
REQUEST_AMOUNT = re.compile(
    r"^how (?:many|much)\b|^what is the (?:total )?(?:cost|price|number|amount)\b"
)
RATE_KIND_QUANTITY = re.compile(r"^quantity\((?P<name>[^,]+),[^,]+,rate\(")
DEFINING_RELATION = re.compile(
    r"^relation\((?P<name>[^,]+),(?P<recipe>sum|difference|scale|quotient|convert)\("
)
QUOTIENT_OPERANDS = re.compile(
    r"^relation\([^,]+,quotient\((?P<a>[a-z0-9_]+),(?P<b>[a-z0-9_]+)\)"
)
KNOWN_QUANTITY = re.compile(r"^quantity\([^,]+,(-?\d+(?:\.\d+)?)")
TEXT_NUMERAL = re.compile(r"-?\d+(?:\.\d+)?")
NUMBER_WORDS = {
    "one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6,
    "seven": 7, "eight": 8, "nine": 9, "ten": 10, "eleven": 11,
    "twelve": 12, "thirteen": 13, "fourteen": 14, "fifteen": 15,
    "sixteen": 16, "seventeen": 17, "eighteen": 18, "nineteen": 19,
    "twenty": 20,
}
GUARD_REASONS = {
    "answer_kind_contradicts_ask_kind",
    "statement_numerals_unbound",
    "statement_percent_unread",
    "change_ask_without_difference",
}


def asked_kind(surface: str | None) -> str | None:
    """The kind of quantity a question's own request span asks for."""
    if not surface:
        return None
    text = surface.lower().strip()
    last = None
    for match in REQUEST_MARKER.finditer(text):
        last = match
    if last is None:
        return None
    request = text[last.start():]
    if REQUEST_RATE.search(request):
        return "rate"
    if ASKED_CHANGE.search(request):
        return "change"
    if REQUEST_AMOUNT.search(request):
        return "amount"
    return None


def quantity_kind_text(program: list[str], name: str) -> str | None:
    prefix = f"quantity({name},"
    for fact in program:
        if fact.startswith(prefix):
            return fact[len(prefix):].split(",", 1)[-1].rstrip(")")
    return None


def derived_kind(program: list[str], referent: str) -> str | None:
    """The kind of quantity a derivation produced, from program structure."""
    if not referent:
        return None
    for fact in program:
        match = RATE_KIND_QUANTITY.match(fact)
        if match and match.group("name") == referent:
            return "rate"
    for fact in program:
        match = DEFINING_RELATION.match(fact)
        if not match or match.group("name") != referent:
            continue
        recipe = match.group("recipe")
        if recipe == "difference":
            return "change"
        if recipe in {"sum", "scale"}:
            return "amount"
        if recipe == "quotient":
            operands = QUOTIENT_OPERANDS.match(fact)
            if operands:
                left = quantity_kind_text(program, operands.group("a"))
                right = quantity_kind_text(program, operands.group("b"))
                if left is not None and left == right:
                    return "rate"
            return None
        return None
    return None


def reading_kinds_contradict(derived: str, asked: str) -> bool:
    """Only the rate-versus-non-rate cell demotes; amount and change are
    mutually compatible readings of one counted holding."""
    non_rate = {"amount", "change"}
    return (derived == "rate" and asked in non_rate) or (
        derived in non_rate and asked == "rate"
    )


def statement_numerals(text: str) -> list[Fraction]:
    """Every numeral the statement prints, digits and small number words."""
    lowered = text.replace(",", "").lower()
    values = [Fraction(x) for x in TEXT_NUMERAL.findall(lowered)]
    values += [
        Fraction(NUMBER_WORDS[word])
        for word in re.findall(r"[a-z]+", lowered)
        if word in NUMBER_WORDS
    ]
    return values


def unbound_statement_numerals(text: str, program: list[str]) -> list[str]:
    """Printed numerals no known quantity binds. Ones are exempt: the rate
    lane legitimately supplies an implicit denominator of one."""
    bound = [
        Fraction(match.group(1))
        for fact in program
        if (match := KNOWN_QUANTITY.match(fact))
    ]
    missing: list[str] = []
    for value in statement_numerals(text):
        if value in bound:
            bound.remove(value)
        elif abs(value) != 1:
            missing.append(str(value))
    return missing


def statement_percent_unread(text: str, program: list[str]) -> bool:
    lowered = text.lower()
    if "percent" not in lowered and "%" not in lowered:
        return False
    return not any("percent" in fact or "hundredth" in fact for fact in program)


def scale_derived(answer: dict[str, Any]) -> bool:
    derivation = str(answer.get("derivation", ""))
    return derivation.startswith("scale(") or derivation.startswith("invert_scale(")


def completion_guard(
    completion: dict[str, Any],
    program: list[str],
    statement_text: str,
    ask_surface: str | None,
) -> tuple[str, dict[str, Any]] | None:
    """The first guard that objects to a single-answer completion, or None."""
    answer = (completion.get("answers") or [{}])[0]
    referent = str(answer.get("referent", ""))
    asked = asked_kind(ask_surface)
    derived = derived_kind(program, referent)
    if asked and derived and reading_kinds_contradict(derived, asked):
        return "answer_kind_contradicts_ask_kind", {
            "derived": derived, "asked": asked,
        }
    if scale_derived(answer):
        missing = unbound_statement_numerals(statement_text, program)
        if missing:
            return "statement_numerals_unbound", {"unbound": missing}
        if statement_percent_unread(statement_text, program):
            return "statement_percent_unread", {}
    if (
        ask_surface
        and ASKED_CHANGE.search(ask_surface.lower())
        and not any(",difference(" in fact for fact in program)
    ):
        return "change_ask_without_difference", {}
    return None


def result_value(term: str) -> Fraction | str | None:
    direct = exact_value(term)
    if direct is not None:
        return direct
    order_verdict = normalize_order_verdict(term)
    if order_verdict is not None:
        return order_verdict
    name, arguments = compound(term)
    if name == "fraction" and len(arguments) == 2:
        numerator = exact_value(arguments[0])
        denominator = exact_value(arguments[1])
        if numerator is not None and denominator not in (None, 0):
            return numerator / denominator
        return None
    if name == "long_division_result" and len(arguments) == 2:
        remainder = exact_value(arguments[1])
        return exact_value(arguments[0]) if remainder == 0 else None
    if name == "decimal" and len(arguments) == 3:
        whole = exact_value(arguments[0])
        digits_name, digits_args = compound(arguments[1])
        if whole is None or digits_name != "fractional_digits" or len(digits_args) != 2:
            return None
        digits = exact_value(digits_args[0])
        places = exact_value(digits_args[1])
        if digits is None or places is None or places.denominator != 1:
            return None
        return whole + digits / (10 ** int(places))
    first_argument = {
        "copies",
        "cubic_units",
        "exact_whole_number",
        "hypotenuse",
        "interior_angle",
        "length",
        "other_leg",
        "quantity",
        "rational",
        "remaining_angle",
        "side_length",
        "value",
        "volume_text",
    }
    if name in first_argument and arguments:
        return exact_value(arguments[0])
    if name == "one_solution" and len(arguments) == 2:
        return exact_value(arguments[1])
    if name == "output_at" and len(arguments) == 2:
        return exact_value(arguments[1])
    return None


def fraction_text(value: Fraction) -> str:
    if value.denominator == 1:
        return str(value.numerator)
    return f"{value.numerator}/{value.denominator}"


def load_ground_truth() -> dict[str, list[dict[str, Any]]]:
    by_id: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for path in (LEGACY_TRUTH, G8_TRUTH):
        with path.open(encoding="utf-8") as handle:
            for line_number, line in enumerate(handle, 1):
                if not line.strip():
                    continue
                row = json.loads(line)
                execution = row.get("execution") or {}
                if not execution.get("ok") or execution.get("validity") != "correct":
                    continue
                by_id[str(row["id"])].append(
                    {
                        "artifact": path.name,
                        "line": line_number,
                        "machine": row.get("machine"),
                        "operation": row.get("operation"),
                        "input": row.get("input"),
                        "source_position": row.get("source_position"),
                        "source_excerpt": row.get("source_excerpt"),
                        "referents": row.get("referents") or [],
                        "result_term": str(execution.get("result_term", "")),
                        "verification": row.get("verification"),
                    }
                )
    return dict(by_id)


SOURCE_BOUND_SELECTIONS = {
    "source_statement_bound",
    "source_statement_bound_deriving",
}

# A source statement that poses a question to a student.  A printed expression
# ("7 + 1") is not one, and neither is a bare premise; both are excluded from
# the guard below by the alphabetic-sentence test rather than by a name list.
PROSE_STATEMENT = re.compile(r"[A-Za-z]{3,}.*\.")


def compare_ground_truth(
    record_id: str,
    completion: dict[str, Any],
    truth_by_id: dict[str, list[dict[str, Any]]],
    source_statement: str = "",
    program_basis: dict[str, Any] | None = None,
    completion_carrier: str = "",
) -> dict[str, Any]:
    receipts = truth_by_id.get(record_id, [])
    base: dict[str, Any] = {"available": bool(receipts), "receipts": receipts}
    if not receipts:
        return {**base, "comparable": False, "verdict": "no_ground_truth",
                "reason": "no_verified_machine_result"}
    # A defragged row names one sub-problem of a statement that may pose
    # several.  When this row's own source statement asks nothing, and the
    # answer therefore came from a sibling sub-problem, the two numbers answer
    # different questions.  That is a category difference, not a disagreement,
    # so the row leaves the comparison rather than losing it.
    selection = str((program_basis or {}).get("selection", ""))
    if (
        completion_carrier == "complete_statement"
        and PROSE_STATEMENT.search(source_statement or "")
        and "?" not in source_statement
        and selection not in SOURCE_BOUND_SELECTIONS
    ):
        return {**base, "comparable": False, "verdict": "no_ground_truth",
                "reason": "source_statement_carries_no_ask"}
    expected_raw = [result_value(row["result_term"]) for row in receipts]
    if any(value is None for value in expected_raw):
        return {**base, "comparable": False, "verdict": "no_ground_truth",
                "reason": "verified_result_not_in_consumed_alphabet"}
    expected_values = [value for value in expected_raw if value is not None]
    target_classes = {
        "order" if isinstance(value, str) else "numeric"
        for value in expected_values
    }
    if len(target_classes) != 1:
        return {**base, "comparable": False, "verdict": "no_ground_truth",
                "reason": "verified_result_target_class_ambiguous"}
    target_class = next(iter(target_classes))
    expected = sorted(set(expected_values))
    if target_class == "order":
        base["expected_values"] = expected
        base["machine_target_class"] = "order_relation"
    else:
        base["expected_values"] = [fraction_text(value) for value in expected]
        base["machine_target_class"] = "numeric_scalar"
    ask_targets = completion.get("ask_targets") or []
    base["ask_targets"] = ask_targets
    if not ask_targets or any(
        str(target.get("target_kind")) != target_class for target in ask_targets
    ):
        return {**base, "comparable": False, "verdict": "no_ground_truth",
                "reason": "target_kind_mismatch"}
    referent_classes = {
        str(target.get("referent_class")) for target in ask_targets
        if target.get("referent_class") is not None
    }
    if len(referent_classes) != 1:
        return {**base, "comparable": False, "verdict": "no_ground_truth",
                "reason": "target_referent_class_ambiguous"}
    base["ask_target_class"] = (
        "order_relation" if target_class == "order" else "numeric_scalar"
    )
    base["ask_referent_class"] = next(iter(referent_classes))
    if completion.get("status") != "completed":
        return {**base, "comparable": True, "verdict": "not_completed",
                "reason": str(completion.get("reason", "not_completed"))}
    answer_rows = completion.get("answers") or []
    actual_raw = [result_value(str(row.get("value", ""))) for row in answer_rows]
    if any(value is None for value in actual_raw):
        return {**base, "comparable": True, "verdict": "disagree",
                "reason": "derived_answer_not_in_target_alphabet"}
    actual_values = [value for value in actual_raw if value is not None]
    actual_classes = {
        "order" if isinstance(value, str) else "numeric"
        for value in actual_values
    }
    if actual_classes != {target_class}:
        return {**base, "comparable": True, "verdict": "disagree",
                "reason": "derived_answer_target_class_mismatch"}
    actual = sorted(set(actual_values))
    if target_class == "order":
        base["actual_values"] = actual
    else:
        base["actual_values"] = [fraction_text(value) for value in actual]
    if actual == expected:
        return {**base, "comparable": True, "verdict": "agree",
                "reason": "exact_value_sets_match"}
    return {**base, "comparable": True, "verdict": "disagree",
            "reason": "exact_value_sets_differ"}


class PrologRunner:
    def __init__(self) -> None:
        self.process = subprocess.Popen(
            ["swipl", "-q", "-f", str(RUNNER)],
            cwd=REPO,
            text=True,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            bufsize=1,
        )

    def run(
        self,
        sentence_texts: list[str],
        source_row: dict[str, Any],
        sentence_spans: list[list[dict[str, Any]]] | None = None,
    ) -> dict[str, Any]:
        if self.process.stdin is None or self.process.stdout is None:
            raise RuntimeError("PUSU Prolog worker has no pipes")
        request = json.dumps(
            {
                "sentences": sentence_texts,
                "sentence_spans": sentence_spans
                or [[] for _ in sentence_texts],
                "source_statement": source_row["source_statement"],
                "complete_statement": source_row["complete_statement"],
                "referents": source_row["referents"],
                "source_statement_spans": source_row["source_statement_spans"],
            },
            ensure_ascii=False,
        )
        self.process.stdin.write(request + "\n")
        self.process.stdin.flush()
        line = self.process.stdout.readline()
        if not line:
            detail = self.process.stderr.read() if self.process.stderr else ""
            raise RuntimeError(f"PUSU Prolog worker stopped: {detail.strip()}")
        reply = json.loads(line)
        if not reply.get("ok"):
            raise RuntimeError(f"PUSU Prolog worker error: {reply.get('error')}")
        return reply

    def close(self) -> None:
        if self.process.stdin and self.process.poll() is None:
            self.process.stdin.close()
        self.process.wait(timeout=30)
        if self.process.returncode:
            detail = self.process.stderr.read() if self.process.stderr else ""
            raise RuntimeError(f"PUSU Prolog worker failed: {detail.strip()}")


class StandardsRouter:
    def __init__(self) -> None:
        self.process = subprocess.Popen(
            [
                "swipl", "-q", "-l", str(REPO / "paths.pl"),
                "-s", str(STANDARDS_ROUTER), "-g", "main", "-t", "halt",
            ],
            cwd=REPO,
            text=True,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            bufsize=1,
        )

    def run(
        self, record_id: str, lesson: str, program: list[str]
    ) -> dict[str, Any]:
        if self.process.stdin is None or self.process.stdout is None:
            raise RuntimeError("standards router has no pipes")
        request = json.dumps(
            {"id": record_id, "lesson": lesson, "program": program},
            ensure_ascii=False,
        )
        self.process.stdin.write(request + "\n")
        self.process.stdin.flush()
        line = self.process.stdout.readline()
        if not line:
            detail = self.process.stderr.read() if self.process.stderr else ""
            raise RuntimeError(f"standards router stopped: {detail.strip()}")
        reply = json.loads(line)
        if reply.get("status") == "error":
            raise RuntimeError(f"standards router error: {reply.get('error')}")
        return reply

    def close(self) -> None:
        if self.process.stdin and self.process.poll() is None:
            self.process.stdin.close()
        self.process.wait(timeout=30)
        if self.process.returncode:
            detail = self.process.stderr.read() if self.process.stderr else ""
            raise RuntimeError(f"standards router failed: {detail.strip()}")


@lru_cache(maxsize=None)
def source_file_bytes(relative_path: str) -> bytes:
    return (REPO / relative_path).read_bytes()


def statement_char_anchors(
    source_row: dict[str, Any],
) -> tuple[list[dict[str, Any]], list[tuple[int, int, int] | None]] | None:
    """Anchor each character of ``complete_statement`` to its file bytes.

    The defrag store records the ordered statement segments and the joiner
    that composed the complete statement.  This rebuilds the statement from
    the named bytes and returns one anchor per character: the segment index
    and the byte range that character was decoded from, or ``None`` for a
    synthetic joiner character.  It returns ``None`` for the whole row unless
    the rebuilt text equals ``complete_statement`` exactly and every segment
    hash matches its file slice -- that equality is the gate that keeps every
    anchor a fact about real bytes.  Rows whose segments need a non-utf8
    decoder fail the equality and stay unanchored.
    """
    spans = source_row.get("statement_spans") or []
    joiner = str(source_row.get("statement_joiner") or " ")
    complete = str(source_row["complete_statement"])
    if not spans:
        return None
    anchors: list[tuple[int, int, int] | None] = []
    pieces: list[str] = []
    for index, span in enumerate(spans):
        byte_start = int(span["byte_start"])
        raw = source_file_bytes(str(span["path"]))[byte_start:int(span["byte_end"])]
        if hashlib.sha256(raw).hexdigest() != str(span.get("sha256", "")):
            return None
        try:
            text = raw.decode("utf-8")
        except UnicodeDecodeError:
            return None
        if index:
            anchors.extend([None] * len(joiner))
        byte_cursor = byte_start
        for char in text:
            width = len(char.encode("utf-8"))
            anchors.append((index, byte_cursor, byte_cursor + width))
            byte_cursor += width
        pieces.append(text)
    if joiner.join(pieces) != complete:
        return None
    return spans, anchors


def source_char_indices(
    offset_rows: list[dict[str, Any]], start: int, end: int
) -> list[int]:
    """Character indices of ``complete_statement`` behind a normalized range."""
    indices: set[int] = set()
    for row in offset_rows:
        normalized_start = int(row["normalized_start"])
        normalized_end = int(row["normalized_end"])
        low = max(start, normalized_start)
        high = min(end, normalized_end)
        if low >= high:
            continue
        if row["mode"] == "copy":
            base = int(row["source_start"])
            indices.update(
                range(base + (low - normalized_start), base + (high - normalized_start))
            )
        else:
            indices.update(range(int(row["source_start"]), int(row["source_end"])))
    return sorted(indices)


def byte_runs(
    spans: list[dict[str, Any]],
    anchors: list[tuple[int, int, int] | None],
    char_indices: list[int],
) -> list[dict[str, Any]]:
    """Contiguous file byte ranges behind the given statement characters."""
    runs: list[list[int]] = []
    for char_index in char_indices:
        if char_index >= len(anchors):
            continue
        anchor = anchors[char_index]
        if anchor is None:
            continue
        span_index, byte_start, byte_end = anchor
        if runs and runs[-1][0] == span_index and runs[-1][2] == byte_start:
            runs[-1][2] = byte_end
        else:
            runs.append([span_index, byte_start, byte_end])
    out: list[dict[str, Any]] = []
    for span_index, byte_start, byte_end in runs:
        if byte_start >= byte_end:
            continue
        span = spans[span_index]
        data = source_file_bytes(str(span["path"]))
        segment_start = int(span["byte_start"])
        line_start = int(span["line_start"]) + data.count(
            b"\n", segment_start, byte_start
        )
        line_end = int(span["line_start"]) + data.count(
            b"\n", segment_start, byte_end - 1
        )
        out.append(
            {
                "path": str(span["path"]),
                "line_start": line_start,
                "line_end": line_end,
                "byte_start": byte_start,
                "byte_end": byte_end,
                "sha256": hashlib.sha256(data[byte_start:byte_end]).hexdigest(),
            }
        )
    return out


def sentence_source_spans(
    sentence_texts: list[str],
    normalization: dict[str, Any],
    source_row: dict[str, Any],
) -> list[list[dict[str, Any]]]:
    """Name the source bytes each sentence was decoded from, or [] for one
    whose bytes cannot be named.  The expression route refuses an unanchored
    sentence, so a missing anchor is a counted refusal, never a guess."""
    anchored = statement_char_anchors(source_row)
    if anchored is None:
        return [[] for _ in sentence_texts]
    spans, anchors = anchored
    normalized = str(normalization["text"])
    offset_rows = normalization["offset_map"]
    results: list[list[dict[str, Any]]] = []
    cursor = 0
    for text in sentence_texts:
        start = normalized.find(text, cursor)
        if start < 0:
            results.append([])
            continue
        end = start + len(text)
        cursor = end
        char_indices = source_char_indices(offset_rows, start, end)
        results.append(byte_runs(spans, anchors, char_indices))
    return results


def load_existing(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        return []
    rows: list[dict[str, Any]] = []
    with path.open(encoding="utf-8") as handle:
        for line_number, line in enumerate(handle, 1):
            if not line.strip():
                continue
            try:
                rows.append(json.loads(line))
            except json.JSONDecodeError as error:
                raise ValueError(f"invalid checkpoint {path}:{line_number}: {error}") from error
    return rows


def validate_resume(
    existing: list[dict[str, Any]], target: list[dict[str, Any]], hashes: dict[str, str]
) -> None:
    if len(existing) > len(target):
        raise ValueError(
            f"checkpoint has {len(existing)} rows but this run selects {len(target)}"
        )
    for index, row in enumerate(existing):
        expected_id = str(target[index]["id"])
        if row.get("schema") != SCHEMA or row.get("record_id") != expected_id:
            raise ValueError(
                f"checkpoint row {index} does not match selected corpus row {expected_id}"
            )
        if row.get("source_sha256") != hashes:
            raise ValueError(
                "checkpoint source hashes differ from the live tree; use --restart "
                "only after deciding to replace the prior run"
            )


def output_row(
    corpus_index: int,
    source_row: dict[str, Any],
    reply: dict[str, Any],
    normalization: dict[str, Any],
    normalized_sentences: list[str],
    truth_by_id: dict[str, list[dict[str, Any]]],
    hashes: dict[str, str],
    route: dict[str, Any] | None = None,
) -> dict[str, Any]:
    sentence_rows = []
    for sentence_index, (text, receipt) in enumerate(
        zip(normalized_sentences, reply["sentences"], strict=True)
    ):
        sentence_rows.append({"sentence_index": sentence_index, "text": text, **receipt})
    parsed_count = sum(bool(row["parsed"]) for row in sentence_rows)
    completion = dict(reply["completion"])
    # An answer whose whole derivation is `given` is an echo of an input, not a
    # solution. "Han collected 4 leaves. Priya gave him 5 more leaves. How many
    # leaves does Han have now?" returned 4 — the initial state — because the
    # transfer sentence left a loose quantity the ask never reached. Returning
    # a given as an answer is worse than refusing, so it refuses.
    derivations = [
        str(answer.get("derivation", ""))
        for answer in (completion.get("answers") or [])
    ]
    if (
        completion.get("status") == "completed"
        and derivations
        and all(derivation == "given" for derivation in derivations)
    ):
        completion["status"] = "parsed_not_completed"
        completion["reason"] = "answer_echoes_a_given"
    # The completion guards: demote a sentence-lane completion whose one
    # answer contradicts the statement's own stated structure. Scoped like
    # source_statement_carries_no_ask — the sentence lane only — and to
    # single-answer completions, so a silent reading leaves the completion
    # alone.
    if (
        completion.get("status") == "completed"
        and str(reply.get("completion_carrier", "")) == "complete_statement"
        and len(completion.get("answers") or []) == 1
    ):
        ask_surface = next(
            (
                text
                for text in reversed(normalized_sentences)
                if text.rstrip().endswith("?")
            ),
            None,
        )
        objection = completion_guard(
            completion,
            list(reply.get("program") or []),
            str(source_row["complete_statement"]),
            ask_surface,
        )
        if objection is not None:
            reason, evidence = objection
            completion["status"] = "parsed_not_completed"
            completion["reason"] = reason
            completion["guard_evidence"] = evidence
    if completion["status"] == "completed":
        completion_class = (
            "completed_full"
            if parsed_count == len(sentence_rows)
            else "completed_from_partial"
        )
        completion["class"] = completion_class
    else:
        completion_class = None
    comparison = compare_ground_truth(
        str(source_row["id"]),
        completion,
        truth_by_id,
        source_statement=str(source_row["source_statement"]),
        program_basis=reply["program_basis"],
        completion_carrier=str(reply.get("completion_carrier", "")),
    )
    return {
        "schema": SCHEMA,
        "corpus_index": corpus_index,
        "record_id": str(source_row["id"]),
        "lesson": str(source_row["lesson"]),
        "grade": grade_of(str(source_row["lesson"])),
        "task": str(source_row["task"]),
        "defrag_status": str(source_row["status"]),
        "complete_statement": str(source_row["complete_statement"]),
        "source_statement": str(source_row["source_statement"]),
        "normalization": normalization,
        "source_spans": source_row["source_spans"],
        "source_statement_spans": source_row["source_statement_spans"],
        "sentence_count": len(sentence_rows),
        "parsed_count": parsed_count,
        "parse_status": (
            "fully_parsed"
            if parsed_count == len(sentence_rows)
            else "partially_parsed"
            if parsed_count
            else "unparsed"
        ),
        "sentences": sentence_rows,
        "program": reply["program"],
        "programs": reply["programs"],
        "program_basis": reply["program_basis"],
        "printed_expression": reply["printed_expression"],
        "completion_carrier": reply["completion_carrier"],
        "route_basis": (route or {}).get("route_basis"),
        "completion_status": completion_class or completion["status"],
        "completion_class": completion_class,
        "completion_reason": completion["reason"],
        "answer": completion.get("answers", []),
        "completion": completion,
        "ground_truth_verdict": comparison["verdict"],
        "ground_truth": comparison,
        "source_sha256": hashes,
    }


def metric_rows(rows: list[dict[str, Any]]) -> dict[str, Any]:
    count = len(rows)
    fully = sum(row["parse_status"] == "fully_parsed" for row in rows)
    partial = sum(row["parse_status"] == "partially_parsed" for row in rows)
    unparsed = sum(row["parse_status"] == "unparsed" for row in rows)
    completed_full = sum(row["completion_status"] == "completed_full" for row in rows)
    completed_from_partial = sum(
        row["completion_status"] == "completed_from_partial" for row in rows
    )
    completed = completed_full + completed_from_partial
    question_sentences = [
        sentence
        for row in rows
        for sentence in row["sentences"]
        if sentence["sentence_form"] == "question"
    ]
    parsed_questions = sum(bool(sentence["parsed"]) for sentence in question_sentences)
    # `parsed` counts a sentence the reader accepted, including one it accepted
    # as carrying nothing it needs to read.  That is a defensible reading rule
    # and a flattering measure, so the strict counts sit beside it: a sentence
    # is READ only when it produced at least one fact, and a statement is read
    # in full only when every one of its sentences was.
    def has_facts(sentence: dict[str, Any]) -> bool:
        return bool(sentence["parsed"]) and bool(sentence.get("facts"))

    sentences_all = [sentence for row in rows for sentence in row["sentences"]]
    sentences_parsed = sum(bool(s["parsed"]) for s in sentences_all)
    sentences_with_facts = sum(has_facts(s) for s in sentences_all)
    read_in_full = sum(
        bool(row["sentences"]) and all(has_facts(s) for s in row["sentences"])
        for row in rows
    )
    yielded_nothing = sum(
        bool(row["sentences"]) and not any(has_facts(s) for s in row["sentences"])
        for row in rows
    )
    comparisons = [
        row for row in rows if row["ground_truth_verdict"] in {"agree", "disagree"}
    ]
    agreements = sum(row["ground_truth_verdict"] == "agree" for row in comparisons)
    disagreements = len(comparisons) - agreements
    admitted = [
        row for row in rows if row.get("task") == "rule_absent-absent(operation)"
    ]
    admitted_completed = [
        row
        for row in admitted
        if row["completion_status"] in {"completed_full", "completed_from_partial"}
    ]
    admitted_unverified_answers = [
        row
        for row in admitted_completed
        if row["ground_truth_verdict"] == "no_ground_truth"
    ]
    # The expression route reads segments both prose readers refused, so a
    # routed sentence was factless before routing existed.  A read-in-full
    # statement carrying one owes that standing to the route; the count sits
    # beside the total so the routed contribution stays separable.
    routed_sentences = sum(
        sentence.get("reader") == "printed_expression_segment"
        for sentence in sentences_all
    )
    read_in_full_with_routed = sum(
        bool(row["sentences"])
        and all(has_facts(sentence) for sentence in row["sentences"])
        and any(
            sentence.get("reader") == "printed_expression_segment"
            for sentence in row["sentences"]
        )
        for row in rows
    )
    return {
        "statements": count,
        "fully_parsed": ratio(fully, count),
        "partially_parsed": ratio(partial, count),
        "unparsed": ratio(unparsed, count),
        "read_in_full": ratio(read_in_full, count),
        "yielded_nothing": ratio(yielded_nothing, count),
        "sentences_parsed": ratio(sentences_parsed, len(sentences_all)),
        "sentences_with_facts": ratio(sentences_with_facts, len(sentences_all)),
        "completed": ratio(completed, count),
        "completed_full": ratio(completed_full, count),
        "completed_from_partial": ratio(completed_from_partial, count),
        "question_parsed": ratio(parsed_questions, len(question_sentences)),
        "agreeing": ratio(agreements, len(comparisons)),
        "disagreeing": ratio(disagreements, len(comparisons)),
        "comparison_coverage": ratio(len(comparisons), completed),
        "admitted_statements": len(admitted),
        "admitted_completed": ratio(len(admitted_completed), len(admitted)),
        "admitted_answered_without_verified_comparison": ratio(
            len(admitted_unverified_answers), len(admitted_completed)
        ),
        "sentences_expression_routed": ratio(
            routed_sentences, len(sentences_all)
        ),
        "read_in_full_with_routed_sentence": ratio(
            read_in_full_with_routed, count
        ),
        # Which optional-store condition this run measured, and how often the
        # completion guards demoted. A summary without these fields predates
        # the loud-seam rule; a run with a store absent is not comparable to
        # one with it present.
        "webster_lexicon_present": WEBSTER_LEXICON.exists(),
        "lexical_typing_store_present": LEXICAL_TYPINGS.exists(),
        "completion_guard_demotions": dict(
            Counter(
                str(row.get("completion_reason"))
                for row in rows
                if row.get("completion_reason") in GUARD_REASONS
            )
        ),
    }


def refusal_census(rows: list[dict[str, Any]]) -> dict[str, Any]:
    all_sentences = [sentence for row in rows for sentence in row["sentences"]]
    refused = [sentence for sentence in all_sentences if not sentence["parsed"]]
    form_totals = Counter(str(sentence["sentence_form"]) for sentence in all_sentences)
    form_refusals = Counter(str(sentence["sentence_form"]) for sentence in refused)
    form_force_totals = Counter(
        (str(sentence["sentence_form"]), str(sentence["force"]))
        for sentence in all_sentences
    )
    form_force_refusals = Counter(
        (str(sentence["sentence_form"]), str(sentence["force"]))
        for sentence in refused
    )
    bins: Counter[tuple[str, str, str]] = Counter()
    reasons: dict[tuple[str, str, str], Counter[str]] = defaultdict(Counter)
    for sentence in refused:
        form = str(sentence["sentence_form"])
        force = str(sentence["force"])
        ape = (sentence.get("refusals") or {}).get("ape") or {}
        token = str(ape.get("token") or "<empty>").casefold()
        bins[(form, force, token)] += 1
        reasons[(form, force, token)][
            str(ape.get("reason") or "unspecified")
        ] += 1
    bin_rows = []
    for (form, force, token), count in sorted(
        bins.items(), key=lambda item: (-item[1], item[0])
    ):
        bin_rows.append(
            {
                "sentence_form": form,
                "force": force,
                "refusal": f"refused({form},force({force}))",
                "failure_token": token,
                "frequency": ratio(count, len(refused)),
                "reasons": dict(sorted(reasons[(form, force, token)].items())),
            }
        )
    return {
        "refused_sentences": ratio(len(refused), len(all_sentences)),
        "by_sentence_form": {
            form: {
                "sentences": total,
                "refused": ratio(form_refusals[form], total),
            }
            for form, total in sorted(form_totals.items())
        },
        "by_form_and_force": [
            {
                "sentence_form": form,
                "force": force,
                "refusal": f"refused({form},force({force}))",
                "sentences": total,
                "refused": ratio(form_force_refusals[(form, force)], total),
            }
            for (form, force), total in sorted(form_force_totals.items())
        ],
        "failure_bins": bin_rows,
    }


def build_summary(
    rows: list[dict[str, Any]], target: list[dict[str, Any]], hashes: dict[str, str]
) -> dict[str, Any]:
    target_grades = Counter(grade_of(str(row["lesson"])) for row in target)
    processed_grades: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for row in rows:
        processed_grades[str(row["grade"])].append(row)
    per_grade = {}
    for grade in sorted(target_grades, key=lambda value: (value != "K", value)):
        grade_rows = processed_grades.get(grade, [])
        per_grade[grade] = {
            "progress": ratio(len(grade_rows), target_grades[grade]),
            **metric_rows(grade_rows),
        }
    return {
        "schema": SCHEMA,
        "corpus": {
            "usable_statuses": ["already_complete", "recovered"],
            "selected_statements": len(target),
            "full_corpus_statements": EXPECTED_ELIGIBLE,
            "selection": "source_order_prefix" if len(target) < EXPECTED_ELIGIBLE else "all",
            "prefilter": "none",
        },
        "progress": ratio(len(rows), len(target)),
        "total": metric_rows(rows),
        "per_grade": per_grade,
        "refusal_census": refusal_census(rows),
        "source_sha256": hashes,
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--summary", type=Path, default=DEFAULT_SUMMARY)
    parser.add_argument("--limit", type=int)
    parser.add_argument("--restart", action="store_true")
    parser.add_argument("--progress-every", type=int, default=25)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    eligible = load_rows()
    if len(eligible) != EXPECTED_ELIGIBLE:
        raise ValueError(
            f"eligible corpus drift: expected {EXPECTED_ELIGIBLE}, found {len(eligible)}"
        )
    if args.limit is not None and not 1 <= args.limit <= len(eligible):
        raise ValueError(f"--limit must be between 1 and {len(eligible)}")
    target = eligible[: args.limit] if args.limit is not None else eligible
    output = args.output if args.output.is_absolute() else REPO / args.output
    summary_path = args.summary if args.summary.is_absolute() else REPO / args.summary
    output.parent.mkdir(parents=True, exist_ok=True)
    summary_path.parent.mkdir(parents=True, exist_ok=True)
    hashes = source_hashes()
    existing = [] if args.restart else load_existing(output)
    validate_resume(existing, target, hashes)
    truth_by_id = load_ground_truth()

    mode = "w" if args.restart else "a"
    runner: PrologRunner | None = None
    router: StandardsRouter | None = None
    rows = list(existing)
    try:
        if len(rows) < len(target):
            runner = PrologRunner()
            router = StandardsRouter()
            with output.open(mode, encoding="utf-8") as checkpoint:
                for corpus_index in range(len(rows), len(target)):
                    source_row = target[corpus_index]
                    normalization = normalize_surface(
                        str(source_row["complete_statement"]), profile="im"
                    )
                    sentence_texts = sentences(str(normalization["text"]))
                    sentence_spans = sentence_source_spans(
                        sentence_texts, normalization, source_row
                    )
                    reply = runner.run(sentence_texts, source_row, sentence_spans)
                    route = router.run(
                        str(source_row["id"]), str(source_row["lesson"]),
                        list(reply["program"])
                    )
                    row = output_row(
                        corpus_index, source_row, reply, normalization,
                        sentence_texts, truth_by_id, hashes, route=route
                    )
                    checkpoint.write(canonical_line(row))
                    checkpoint.flush()
                    os.fsync(checkpoint.fileno())
                    rows.append(row)
                    completed = corpus_index + 1
                    if args.progress_every and (
                        completed % args.progress_every == 0 or completed == len(target)
                    ):
                        print(f"checkpointed {completed}/{len(target)} statements")
    finally:
        if runner is not None:
            runner.close()
        if router is not None:
            router.close()

    summary = build_summary(rows, target, hashes)
    summary_path.write_text(
        json.dumps(summary, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(json.dumps({"progress": summary["progress"], "total": summary["total"]},
                     sort_keys=True))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (BrokenPipeError, KeyboardInterrupt):
        print("PUSU harness interrupted; completed JSONL rows remain resumable", file=sys.stderr)
        raise SystemExit(130)
