#!/usr/bin/env python3
"""Deterministically tag Brandomian surface material in numbered transcripts.

This pre-processor deliberately records lexical material only.  In particular,
anaphoric spans are marked unresolved: the preceding utterance window is a
candidate resource for a later reader, not an antecedent resolution.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter
from pathlib import Path
from typing import Any, Iterable


HERE = Path(__file__).resolve().parent
DEFAULT_LEXICON = HERE / "brandomian_lexicons.json"
TRANSCRIPT_LINE = re.compile(r"^U(?P<number>\d+)\s+(?P<speaker>[^:]+):\s?(?P<text>.*)$")


def load_lexicon(path: Path) -> dict[str, list[str]]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict) or not all(isinstance(value, list) for value in data.values()):
        raise ValueError("lexicon must be an object of string lists")
    return {str(key): [str(item) for item in value] for key, value in data.items()}


def phrase_pattern(phrases: Iterable[str]) -> re.Pattern[str]:
    alternatives = sorted((re.escape(phrase) for phrase in phrases), key=len, reverse=True)
    return re.compile(r"(?<!\w)(?:" + "|".join(alternatives) + r")(?!\w)", re.IGNORECASE)


def span(kind: str, text: str, start: int, end: int) -> dict[str, Any]:
    return {"type": kind, "text": text[start:end], "start": start, "end": end}


def add_matches(spans: list[dict[str, Any]], kind: str, text: str, pattern: re.Pattern[str]) -> None:
    spans.extend(span(kind, text, match.start(), match.end()) for match in pattern.finditer(text))


def anaphoric_spans(text: str, pattern: re.Pattern[str]) -> list[dict[str, Any]]:
    """Mark an unresolved pronoun and, when present, its local candidate window."""
    found: list[dict[str, Any]] = []
    for match in pattern.finditer(text):
        found.append(span("anaphoric_unresolved", text, match.start(), match.end()))
        prefix = text[:match.start()].rstrip()
        words = list(re.finditer(r"\S+", prefix))
        if words:
            start = words[max(0, len(words) - 8)].start()
            found.append(span("anaphoric_candidate_window", text, start, len(prefix)))
    return found


def substitution_spans(text: str) -> list[dict[str, Any]]:
    """Capture the two non-empty terms in conservative copular substitution frames."""
    patterns = (
        re.compile(r"(?P<left>[^,;?.!]+?)\s+is\s+the\s+same\s+as\s+(?P<right>[^,;?.!]+)", re.IGNORECASE),
        re.compile(r"(?P<left>[^,;?.!]+?)\s+is\s+equal\s+to\s+(?P<right>[^,;?.!]+)", re.IGNORECASE),
        re.compile(r"(?P<left>[^,;?.!]+?)\s+means\s+(?P<right>[^,;?.!]+)", re.IGNORECASE),
        re.compile(r"(?P<left>[^,;?.!]+?)\s+is\s+(?P<right>[^,;?.!]+)", re.IGNORECASE),
    )
    found: list[dict[str, Any]] = []
    occupied: set[tuple[int, int]] = set()
    for pattern in patterns:
        for match in pattern.finditer(text):
            left_start, left_end = match.span("left")
            right_start, right_end = match.span("right")
            left_start, left_end = trim_term(text, left_start, left_end)
            right_start, right_end = trim_term(text, right_start, right_end)
            pair = (left_start, right_end)
            if left_start >= left_end or right_start >= right_end or pair in occupied:
                continue
            occupied.add(pair)
            found.append(span("substitution_inference_candidate", text, left_start, left_end))
            found.append(span("substitution_inference_candidate", text, right_start, right_end))
    return found


def trim_term(text: str, start: int, end: int) -> tuple[int, int]:
    """Remove a small set of discourse lead-ins without interpreting content."""
    value = text[start:end]
    value = re.sub(r"^\s*(?:and|so|but)\s+", "", value, flags=re.IGNORECASE)
    value = re.sub(r"^\s*(?:i think|i want you to see that|you said)\s+", "", value, flags=re.IGNORECASE)
    leading = len(text[start:end]) - len(value)
    start += leading
    while start < end and text[start].isspace():
        start += 1
    while end > start and text[end - 1].isspace():
        end -= 1
    return start, end


def tag_utterance(utterance_id: str, text: str, lexicon: dict[str, list[str]]) -> dict[str, Any]:
    spans: list[dict[str, Any]] = []
    for kind in ("deictic", "alethic_modal", "normative_deontic", "observational", "negation"):
        add_matches(spans, kind, text, phrase_pattern(lexicon[kind]))
    # These are candidate windows only; no antecedent is claimed here.
    spans.extend(anaphoric_spans(text, phrase_pattern(lexicon["anaphoric"])))
    if "?" in text or re.match(r"^\s*(what|why|how|when|where|who|can you|do you|are you|will you|did you|would you)\b", text, re.I):
        spans.append(span("interrogative", text, 0, len(text)))
    spans.extend(substitution_spans(text))
    spans.sort(key=lambda item: (item["start"], item["end"], item["type"]))
    return {"id": utterance_id, "spans": spans}


def numbered_utterances(transcript: str) -> list[tuple[str, str]]:
    utterances: list[tuple[str, str]] = []
    for line in transcript.splitlines():
        match = TRANSCRIPT_LINE.match(line)
        if match:
            utterances.append(("u" + match.group("number"), match.group("text")))
    if not utterances:
        raise ValueError("no numbered transcript lines found (expected 'U0001 Speaker: text')")
    return utterances


def transcript_from_input(path: Path) -> str:
    data = json.loads(path.read_text(encoding="utf-8"))
    if isinstance(data, dict):
        report = data.get("report") if isinstance(data.get("report"), dict) else data
        transcript = report.get("transcript")
        if isinstance(transcript, str):
            return transcript
    raise ValueError("input JSON must contain report.transcript or transcript")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path, help="report JSON containing a numbered transcript")
    parser.add_argument("--lexicon", type=Path, default=DEFAULT_LEXICON)
    parser.add_argument("--output", type=Path, help="write JSONL here instead of stdout")
    args = parser.parse_args()
    lexicon = load_lexicon(args.lexicon)
    rows = [tag_utterance(uid, text, lexicon) for uid, text in numbered_utterances(transcript_from_input(args.input))]
    rendered = "".join(json.dumps(row, ensure_ascii=False, sort_keys=True) + "\n" for row in rows)
    if args.output:
        args.output.write_text(rendered, encoding="utf-8")
    else:
        sys.stdout.write(rendered)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
