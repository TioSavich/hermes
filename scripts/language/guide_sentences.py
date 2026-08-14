#!/usr/bin/env python3
"""Reconstruct sentence receipts from the IM teacher-guide text extracts.

The guide files are hard-wrapped PDF extracts.  This module removes page
furniture, splits flattened two-column rows, and rejoins likely continuation
lines.  Source line numbers count LF-delimited editor lines.  In particular,
U+000C page breaks remain characters within a line and never advance a source
line receipt.
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


REPO = Path(__file__).resolve().parents[2]
GUIDES = REPO / "curriculum/im_teacher_guides"

FOOTER = re.compile(r"^\s*Illustrative Mathematics®\s*\d*\s*$")
BULLET = re.compile(r"^\s*[•◦▪●◎◼]\s*")
GUTTER = re.compile(r" {4,}")
TERMINAL = re.compile(r"[.?!:”\"]\s*$")
SENTENCE_SPLIT = re.compile(r"(?<=[.?!])\s+(?=[“\"'(A-Z0-9])")


def editor_lines(text: str) -> list[str]:
    """Split only at normalized newline characters, never at form feeds."""
    return text.split("\n")


def fragments(path: Path) -> list[tuple[int, str]]:
    """Return line-numbered fragments after furniture and gutter handling."""
    out: list[tuple[int, str]] = []
    text = path.read_text(encoding="utf-8")
    for number, line in enumerate(editor_lines(text), start=1):
        if not line.strip() or FOOTER.match(line):
            continue
        for piece in GUTTER.split(line.strip()):
            piece = BULLET.sub("", piece).strip()
            if piece:
                out.append((number, piece))
    return out


def rejoin(pieces: list[tuple[int, str]]) -> list[tuple[int, str]]:
    """Join a long unterminated fragment to a likely continuation."""
    joined: list[tuple[int, str]] = []
    for number, piece in pieces:
        if joined:
            previous_number, previous = joined[-1]
            continues = (
                not TERMINAL.search(previous)
                and (
                    piece[0].islower()
                    or piece[0].isdigit()
                    or piece[0] in "”\")"
                )
            )
            if continues and len(previous) > 60:
                joined[-1] = (previous_number, previous + " " + piece)
                continue
        joined.append((number, piece))
    return joined


def sentences_of(path: Path) -> list[tuple[int, str]]:
    out: list[tuple[int, str]] = []
    for number, block in rejoin(fragments(path)):
        for sentence in SENTENCE_SPLIT.split(block):
            sentence = " ".join(sentence.split())
            if len(sentence) >= 12:
                out.append((number, sentence))
    return out


def all_sentences() -> list[tuple[str, int, str]]:
    out: list[tuple[str, int, str]] = []
    for path in sorted(GUIDES.rglob("*.md")):
        for number, sentence in sentences_of(path):
            out.append((str(path.relative_to(REPO)), number, sentence))
    return out


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    rows = all_sentences()
    if args.output:
        args.output.write_text(
            "".join(
                json.dumps({"path": path, "line": line, "text": text}) + "\n"
                for path, line, text in rows
            ),
            encoding="utf-8",
        )
    print(
        f"{len(rows)} reconstructed sentences from "
        f"{len(list(GUIDES.rglob('*.md')))} guides"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
