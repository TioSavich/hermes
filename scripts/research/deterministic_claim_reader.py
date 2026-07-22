#!/usr/bin/env python3
"""Compile explicit surface arithmetic statements into registered claim JSON.

This is deliberately a small, deterministic reader.  It does not infer an
unstated operation, repair an incomplete expression, or resolve referents.
Unsupported wording produces no record.
"""
from __future__ import annotations

import argparse
import json
import re
from typing import Any


_NUMBER_WORDS = {
    "zero": 0, "one": 1, "two": 2, "three": 3, "four": 4,
    "five": 5, "six": 6, "seven": 7, "eight": 8, "nine": 9,
    "ten": 10, "eleven": 11, "twelve": 12, "thirteen": 13,
    "fourteen": 14, "fifteen": 15, "sixteen": 16, "seventeen": 17,
    "eighteen": 18, "nineteen": 19, "twenty": 20,
}
_DENOMINATORS = {
    "half": 2, "halves": 2, "third": 3, "thirds": 3,
    "fourth": 4, "fourths": 4, "quarter": 4, "quarters": 4,
    "fifth": 5, "fifths": 5, "sixth": 6, "sixths": 6,
    "seventh": 7, "sevenths": 7, "eighth": 8, "eighths": 8,
    "ninth": 9, "ninths": 9, "tenth": 10, "tenths": 10,
}
_WORD = "(?:zero|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty(?:[- ](?:one|two|three|four|five|six|seven|eight|nine))?)"
_NUMBER = rf"(?:\d+|{_WORD})"
_FRACTION = rf"(?:\d+\s*/\s*\d+|{_WORD}\s+(?:half|halves|third|thirds|fourth|fourths|quarter|quarters|fifth|fifths|sixth|sixths|seventh|sevenths|eighth|eighths|ninth|ninths|tenth|tenths))"
_EXPLICIT_VALUE = rf"(?:{_NUMBER}|{_FRACTION})(?:\s+and\s+{_FRACTION})?"


def _integer(text: str) -> int | None:
    text = text.strip().lower()
    if text.isdigit():
        return int(text)
    if text in _NUMBER_WORDS:
        return _NUMBER_WORDS[text]
    match = re.fullmatch(r"twenty[- ](one|two|three|four|five|six|seven|eight|nine)", text)
    return 20 + _NUMBER_WORDS[match.group(1)] if match else None


def _value(text: str) -> int | dict[str, int] | None:
    text = text.strip().lower()
    numeric = _integer(text)
    if numeric is not None:
        return numeric
    match = re.fullmatch(r"(\d+)\s*/\s*(\d+)", text)
    if match and int(match.group(2)):
        return {"num": int(match.group(1)), "den": int(match.group(2))}
    match = re.fullmatch(rf"({_WORD})\s+([a-z]+)", text)
    if match:
        numerator = _NUMBER_WORDS[match.group(1)]
        denominator = _DENOMINATORS.get(match.group(2))
        if denominator:
            return {"num": numerator, "den": denominator}
    return None


def _fraction(text: str) -> dict[str, int] | None:
    value = _value(text)
    return value if isinstance(value, dict) else None


def _arithmetic_text(text: str) -> str | None:
    """Render one explicit numeric phrase as a checker-safe expression."""
    parts = re.split(r"\s+and\s+", text.strip(), maxsplit=1, flags=re.I)
    rendered: list[str] = []
    for part in parts:
        value = _value(part)
        if isinstance(value, int):
            rendered.append(str(value))
        elif isinstance(value, dict):
            rendered.append(f"{value['num']} / {value['den']}")
        else:
            return None
    return " + ".join(rendered)


def _claim(ident: int, utterance_id: str, surface: str, shape: str,
           args: dict[str, Any]) -> dict[str, Any]:
    return {"id": f"dcr{ident}", "kind": "claim", "utterance_id": utterance_id.lower(),
            "surface": surface, "shape": shape, "args": args}


def claims_from_utterance(utterance_id: str, text: str, *, start_id: int = 1) -> list[dict[str, Any]]:
    """Return claims only for complete, explicit equation-like statements."""
    patterns: list[tuple[str, re.Pattern[str]]] = [
        ("equivalence", re.compile(rf"\b({_FRACTION})\s+(?:is\s+)?equal\s+to\s+({_FRACTION})\b", re.I)),
        ("fraction_of", re.compile(rf"\b({_FRACTION})\s+of\s+({_NUMBER})\s+is\s+({_NUMBER})\b", re.I)),
        ("multiplication", re.compile(rf"\b({_NUMBER}|{_FRACTION})\s+(?:times|\*)\s+({_NUMBER}|{_FRACTION})\s+(?:is|equals|=)\s+({_NUMBER}|{_FRACTION})\b", re.I)),
        ("division", re.compile(rf"\b({_EXPLICIT_VALUE})\s+(?:divided\s+by|/)\s+({_EXPLICIT_VALUE})\s+(?:is|equals|=)\s+({_EXPLICIT_VALUE})\b", re.I)),
        ("sum", re.compile(rf"\b({_NUMBER})\s*(?:plus|\+)\s*({_NUMBER})\s+(?:is|equals|=)\s+({_NUMBER})\b", re.I)),
        ("subtraction", re.compile(rf"\b({_NUMBER})\s*(?:minus|-)\s*({_NUMBER})\s+(?:is|equals|=)\s+({_NUMBER})\b", re.I)),
    ]
    claims: list[dict[str, Any]] = []
    occupied: list[tuple[int, int]] = []
    for kind, pattern in patterns:
        for match in pattern.finditer(text):
            if any(match.start() < end and match.end() > begin for begin, end in occupied):
                continue
            parts = tuple(part.strip() for part in match.groups())
            left, right = parts[:2]
            result = parts[2] if len(parts) == 3 else None
            surface = match.group(0)
            if kind == "equivalence":
                args = {"left": _fraction(left), "right": _fraction(right)}
                shape = "equivalence"
            elif kind == "fraction_of":
                args = {"frac": _fraction(left), "n": _integer(right), "result": _integer(result)}
                shape = "fraction_of"
            elif kind == "multiplication":
                args = {"a": _value(left), "b": _value(right), "product": _value(result)}
                shape = "multiplication"
            elif kind == "division":
                # The catalog has no general division equation. Preserve this
                # explicit arithmetic statement in its registered generic form.
                numerator, denominator, quotient = (_arithmetic_text(value) for value in (left, right, result))
                args = {"left": f"{numerator} / ({denominator})", "right": quotient}
                shape = "arithmetic_equation"
            else:
                args = {"a": _integer(left), "b": _integer(right), "c": _integer(result)}
                shape = kind
            if any(value is None for value in args.values()):
                continue
            claims.append(_claim(start_id + len(claims), utterance_id, surface, shape, args))
            occupied.append(match.span())
    return claims


_NUMBERED = re.compile(r"^(U\d{4})\s+(?:S\d\d):\s*(.*)$")


def read_numbered_transcript(numbered_markdown: str) -> list[dict[str, Any]]:
    """Compile claims from the numbered transcript form used by two-pass."""
    claims: list[dict[str, Any]] = []
    for line in numbered_markdown.splitlines():
        match = _NUMBERED.match(line)
        if match:
            claims.extend(claims_from_utterance(match.group(1), match.group(2), start_id=len(claims) + 1))
    return claims


def self_test() -> None:
    fixtures = [
        ("nine times three is twenty-seven", "multiplication"),
        ("14 divided by 3/4 is 18 and 2/3", "arithmetic_equation"),
        ("2/4 is equal to 1/2", "equivalence"),
        ("three fourths of twelve is nine", "fraction_of"),
        ("I think that is probably right", None),
        ("three fourths of twelve", None),
    ]
    for index, (text, expected) in enumerate(fixtures, start=1):
        found = claims_from_utterance(f"U{index:04d}", text)
        assert [claim["shape"] for claim in found] == ([] if expected is None else [expected]), text


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--numbered", type=argparse.FileType("r", encoding="utf-8"))
    parser.add_argument("--out", type=argparse.FileType("w", encoding="utf-8"))
    args = parser.parse_args()
    if args.self_test:
        self_test()
        return 0
    if not args.numbered or not args.out:
        parser.error("--numbered and --out are required unless --self-test is used")
    json.dump(read_numbered_transcript(args.numbered.read()), args.out, indent=2)
    args.out.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
