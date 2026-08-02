#!/usr/bin/env python3
"""The subtraction responder for mistake_location: transcribe, adjudicate.

The model's one job is stripping words: every step of the student solution
becomes bare equations or NONE. SWI-Prolog adjudicates each equation with
exact rational arithmetic through the same sandboxed prolog_query surface
the MCP tool serves. The answer is the first step whose transcribed
equation is false, or 0 when every computation checks. The model never
judges; the engine never reads prose.

Two guards keep the transcription honest, both learned from measured
failure: a fidelity check drops any equation whose numbers do not appear
in the step it claims to transcribe, and a rounding tolerance keeps a
two-decimal convention (70/24 = 2.92) from being scored as a false claim.
"""
from __future__ import annotations

import ast
import json
import re
import threading
import urllib.request
from fractions import Fraction
from pathlib import Path
from typing import Any

import mtb_responders
from mtb_kb_responder import KBQueryServer

REPO_ROOT = Path(__file__).resolve().parents[2]

PROMPT = """Rewrite every computation in the student's steps as bare \
equations. Do not judge anything. Do not solve anything. Only transcribe.

{steps}

Rules: output exactly one line per step, formatted:
k: EQUATION
or, when the step has no complete written computation:
k: NONE
Keep every term the student wrote; three-term sums stay three-term.
Use only numerals, fractions written like 3/4, decimals, parentheses,
and the operators + - * /. Several equations in one step are separated
by ; on the same line. A step using a letter or unknown gets NONE.
Write the lines and nothing else.
"""

STEP_LINE = re.compile(r"^\s*(\d+)\s*[:.\-]\s*(.+)$")
NUMBER = re.compile(r"\d+\.\d+|\d+")


def sanitize(text: str) -> str:
    text = text.replace("×", "*").replace("÷", "/").replace("$", "")
    text = re.sub(r"(?<=[\d\s)])x(?=[\s\d(])", "*", text)
    return re.sub(r"(\d),(\d{3})", r"\1\2", text)


def fraction_eval(expression: str) -> Fraction | None:
    try:
        tree = ast.parse(expression, mode="eval").body
    except SyntaxError:
        return None

    def walk(node):
        if isinstance(node, ast.BinOp):
            left, right = walk(node.left), walk(node.right)
            if isinstance(node.op, ast.Add):
                return left + right
            if isinstance(node.op, ast.Sub):
                return left - right
            if isinstance(node.op, ast.Mult):
                return left * right
            if isinstance(node.op, ast.Div):
                return left / right
            raise ValueError(node.op)
        if isinstance(node, ast.UnaryOp) and isinstance(node.op, ast.USub):
            return -walk(node.operand)
        if isinstance(node, ast.Constant) and isinstance(node.value, (int, float)):
            return Fraction(str(node.value))
        raise ValueError(node)

    try:
        return walk(tree)
    except (ValueError, ZeroDivisionError):
        return None


def rationalize(expression: str) -> str:
    """The expression with every decimal and division made exact."""
    def decimal_to_rdiv(match):
        value = Fraction(match.group(0))
        return f"({value.numerator} rdiv {value.denominator})"
    text = re.sub(r"\d+\.\d+", decimal_to_rdiv, expression)
    return text.replace("/", " rdiv ")


def within_rounding(left: Fraction, right: Fraction) -> bool:
    """A two-decimal or one-percent convention, not a false claim."""
    difference = abs(left - right)
    return difference <= max(Fraction(1, 100), abs(right) / 100)


def faithful(equation: str, step_text: str) -> bool:
    """At least half the equation's numbers appear in the step's text."""
    numbers = NUMBER.findall(equation)
    if not numbers:
        return False
    step = sanitize(step_text)
    present = sum(1 for token in numbers if token in step)
    return present * 2 >= len(numbers)


def _prolog_subtract(model: str, **options: str) -> mtb_responders.Responder:
    backend = options.get("backend", "ollama")
    endpoint = options.get("endpoint")
    num_predict = int(options.get("num_predict", 768))
    trace_path = options.get("trace")
    server = KBQueryServer(
        repo_root=Path(options.get("repo", REPO_ROOT)),
        swipl=options.get("swipl", "swipl"),
        watchdog_seconds=float(options.get("watchdog", 30.0)))
    trace_lock = threading.Lock()

    def trace(record: dict[str, Any]) -> None:
        if not trace_path:
            return
        with trace_lock:
            with Path(trace_path).open("a", encoding="utf-8") as handle:
                handle.write(json.dumps(record, ensure_ascii=False) + "\n")

    def engine_false(lhs: str, rhs: str) -> bool | None:
        goal = f"({rationalize(lhs)}) =:= ({rationalize(rhs)})"
        reply = server.query(goal)
        if reply.get("status") != "ok":
            return None
        return reply.get("solution_count", 0) == 0

    def respond(*, prompt: str, stop: list[str] | None,
                example: dict[str, Any], task_name: str) -> str:
        solution = example.get("student_solution", "")
        steps = [part for part in solution.split("\\n") if part.strip()]
        step_texts = {index + 1: text for index, text in enumerate(steps)}
        reply = mtb_responders.complete(
            PROMPT.format(steps="\n".join(steps)),
            model=model, backend=backend, endpoint=endpoint,
            stop=None, num_predict=num_predict, stop_mode="post")
        record: dict[str, Any] = {"steps": len(steps), "checked": [],
                                  "answer": "0",
                                  # A trace row must be joinable to its item
                                  # after a threaded run; the question head
                                  # is the join key the harness can carry.
                                  "question_head":
                                      example.get("question", "")[:80]}
        first_false = 0
        for line in reply.splitlines():
            matched = STEP_LINE.match(line.strip())
            if not matched:
                continue
            step_number = int(matched.group(1))
            if step_number not in step_texts:
                continue
            body = sanitize(matched.group(2))
            for part in body.split(";"):
                part = part.strip()
                if not part or "NONE" in part.upper() or "=" not in part:
                    continue
                lhs, _, rhs = part.partition("=")
                lhs, rhs = lhs.strip(), rhs.strip()
                left = fraction_eval(lhs)
                right = fraction_eval(rhs)
                if left is None or right is None:
                    continue
                if not faithful(part, step_texts[step_number]):
                    record["checked"].append(
                        {"step": step_number, "claim": part,
                         "verdict": "unfaithful_dropped"})
                    continue
                false = engine_false(lhs, rhs)
                if false and within_rounding(left, right):
                    false = False
                    verdict = "rounding"
                else:
                    verdict = "false" if false else "true"
                record["checked"].append(
                    {"step": step_number, "claim": part, "verdict": verdict})
                if false and (first_false == 0
                              or step_number < first_false):
                    first_false = step_number
        record["answer"] = str(first_false)
        trace(record)
        return record["answer"]

    return respond


mtb_responders.register("prolog_subtract", _prolog_subtract)
