#!/usr/bin/env python3
"""Read explicit arithmetic equations from numbered or line-separated steps.

The reader only normalizes syntax. It does not infer missing operands, repair
incomplete expressions, or decide whether an equation holds.
"""
from __future__ import annotations

import re
from typing import TypedDict


class Equation(TypedDict):
    span: str
    left: str
    right: str


class Step(TypedDict):
    index: int
    text: str
    equations: list[Equation]


_NUMBER_CORE = r"(?:\d{1,3}(?:,\d{3})+|\d+)(?:\.\d+)?"
_NUMBER = rf"(?:[$£€]\s*)?{_NUMBER_CORE}"
_OPERATOR = r"(?:times|[xX+\-*/])"
_LEFT_EXPRESSION = rf"{_NUMBER}(?:\s*{_OPERATOR}\s*{_NUMBER})+"
_RIGHT_EXPRESSION = rf"{_NUMBER}(?:\s*{_OPERATOR}\s*{_NUMBER})*"
_RELATION = r"(?:=|equals?|is)"

_SYMBOLIC_EQUATION = re.compile(
    rf"(?<![\w.])(?P<left>{_LEFT_EXPRESSION})\s*{_RELATION}\s*"
    rf"(?P<right>{_RIGHT_EXPRESSION})(?![\w.%])",
    re.IGNORECASE,
)
_HALF_OF_EQUATION = re.compile(
    rf"(?<![\w.])half\s+of\s+(?P<quantity>{_NUMBER})\s*{_RELATION}\s*"
    rf"(?P<right>{_RIGHT_EXPRESSION})(?![\w.%])",
    re.IGNORECASE,
)
_PERCENT_OF_EQUATION = re.compile(
    rf"(?<![\w.])(?P<percent>{_NUMBER})\s*%\s+of\s+"
    rf"(?P<quantity>{_NUMBER})\s*{_RELATION}\s*"
    rf"(?P<right>{_RIGHT_EXPRESSION})(?![\w.%])",
    re.IGNORECASE,
)
_NUMBERED_STEP = re.compile(
    r"^\s*step\s+(\d+)\s*(?:[-:.]\s*|\)\s*|\s+)(.*)$",
    re.IGNORECASE,
)
_APPROXIMATE_PREFIX = re.compile(
    r"(?:about|approximately|roughly|nearly)\s*$",
    re.IGNORECASE,
)
_TOKEN_SPLIT = re.compile(r"\s*(times|[xX+\-*/])\s*", re.IGNORECASE)


def _normalize_number(token: str) -> str:
    """Remove notation that does not change the stated numeric literal."""
    return re.sub(r"[$£€,\s]", "", token)


def _render_expression(surface: str) -> str | None:
    """Render a complete numeric expression as an explicitly left fold."""
    parts = _TOKEN_SPLIT.split(surface.strip())
    if not parts or len(parts) % 2 == 0:
        return None
    operands = [_normalize_number(parts[index]) for index in range(0, len(parts), 2)]
    if not all(re.fullmatch(_NUMBER_CORE, operand) for operand in operands):
        return None
    operators = [
        "*" if parts[index].lower() in {"x", "times"} else parts[index]
        for index in range(1, len(parts), 2)
    ]
    rendered = operands[0]
    for position, (operator, operand) in enumerate(zip(operators, operands[1:])):
        if position:
            rendered = f"({rendered}) {operator} {operand}"
        else:
            rendered = f"{rendered} {operator} {operand}"
    return rendered


def _has_approximate_prefix(text: str, start: int) -> bool:
    return bool(_APPROXIMATE_PREFIX.search(text[max(0, start - 24):start]))


def _equations_from_text(text: str) -> list[Equation]:
    found: list[tuple[int, int, Equation]] = []
    occupied: list[tuple[int, int]] = []

    def available(start: int, end: int) -> bool:
        return not _has_approximate_prefix(text, start) and not any(
            start < used_end and end > used_start
            for used_start, used_end in occupied
        )

    for pattern, left_builder in (
        (
            _HALF_OF_EQUATION,
            lambda match: f"1 / 2 * {_normalize_number(match.group('quantity'))}",
        ),
        (
            _PERCENT_OF_EQUATION,
            lambda match: (
                f"{_normalize_number(match.group('percent'))} / 100"
                f" * {_normalize_number(match.group('quantity'))}"
            ),
        ),
    ):
        for match in pattern.finditer(text):
            if not available(*match.span()):
                continue
            right = _render_expression(match.group("right"))
            if right is None:
                continue
            equation: Equation = {
                "span": match.group(0),
                "left": left_builder(match),
                "right": right,
            }
            found.append((match.start(), match.end(), equation))
            occupied.append(match.span())

    for match in _SYMBOLIC_EQUATION.finditer(text):
        if not available(*match.span()):
            continue
        left = _render_expression(match.group("left"))
        right = _render_expression(match.group("right"))
        if left is None or right is None:
            continue
        equation = {"span": match.group(0), "left": left, "right": right}
        found.append((match.start(), match.end(), equation))
        occupied.append(match.span())

    found.sort(key=lambda item: item[0])
    return [equation for _start, _end, equation in found]


def _split_steps(text: str) -> list[tuple[int, str]]:
    lines = [line.strip() for line in text.splitlines() if line.strip()]
    if not lines:
        return []

    if not any(_NUMBERED_STEP.match(line) for line in lines):
        return [(index, line) for index, line in enumerate(lines, start=1)]

    steps: list[tuple[int, str]] = []
    current_index: int | None = None
    current_parts: list[str] = []
    for line in lines:
        numbered = _NUMBERED_STEP.match(line)
        if numbered:
            if current_index is not None:
                steps.append((current_index, " ".join(current_parts)))
            current_index = int(numbered.group(1))
            current_parts = [numbered.group(2).strip()]
        elif current_index is not None:
            current_parts.append(line)
    if current_index is not None:
        steps.append((current_index, " ".join(current_parts)))
    return steps


def read_steps(text: str) -> list[Step]:
    """Return source steps and only their complete, explicit equations."""
    return [
        {
            "index": index,
            "text": step_text,
            "equations": _equations_from_text(step_text),
        }
        for index, step_text in _split_steps(text)
    ]

