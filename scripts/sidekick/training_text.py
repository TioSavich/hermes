"""Text boundary shared by sidekick dataset builders before tokenization."""
from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Any


DISPLAY_MATH_MARKER_RE = re.compile(
    r"(?<!\\)\$([^$\n]*[+\-−×÷=<>/\\][^$\n]*)\$"
)
WAVE5_CULLING_VERSION = "wave5-culling-v1"
CURRENCY_DOLLAR_RE = re.compile(r"(?<!\\)\$(?=\d)")
MATH_OPERATOR_RE = re.compile(r"[+\-−×÷=<>/\\^_]")
COMPACT_MATH_RE = re.compile(r"[A-Za-z0-9.]+")


def cull_display_math_markers(value: Any) -> Any:
    """Remove display-only math delimiters before a value reaches training."""
    if isinstance(value, str):
        return DISPLAY_MATH_MARKER_RE.sub(lambda match: match.group(1), value)
    if isinstance(value, list):
        return [cull_display_math_markers(item) for item in value]
    if isinstance(value, tuple):
        return tuple(cull_display_math_markers(item) for item in value)
    if isinstance(value, dict):
        return {key: cull_display_math_markers(item) for key, item in value.items()}
    return value


@dataclass(frozen=True)
class Wave5CullResult:
    text: str
    version: str
    paired_dollar_spans_before: int
    paired_dollar_spans_after: int
    currency_dollars_before: int
    currency_dollars_after: int
    bullet_separators_before: int

    @property
    def invariants_green(self) -> bool:
        return (
            self.paired_dollar_spans_after == 0
            and self.currency_dollars_before == self.currency_dollars_after
        )


def cull_wave5_training_text(text: str) -> Wave5CullResult:
    """Apply the deterministic Wave 5 mint-time text contract.

    Paired math delimiters are recognized as operator-bearing spans or a
    single delimited numeral. Unpaired dollar signs before numerals remain
    currency. Bullets become semicolon separators and whitespace is folded.
    """
    spans = paired_dollar_spans(text)
    paired_before = len(spans)
    without_math = remove_spans(text, spans, keep_content=False)
    currency_before = len(CURRENCY_DOLLAR_RE.findall(without_math))
    bullets = text.count("•")
    culled = remove_spans(text, spans, keep_content=True)
    culled = culled.replace("•", " ; ")
    culled = " ".join(culled.split())
    after_spans = paired_dollar_spans(culled)
    paired_after = len(after_spans)
    currency_after = len(CURRENCY_DOLLAR_RE.findall(
        remove_spans(culled, after_spans, keep_content=False)
    ))
    return Wave5CullResult(
        text=culled,
        version=WAVE5_CULLING_VERSION,
        paired_dollar_spans_before=paired_before,
        paired_dollar_spans_after=paired_after,
        currency_dollars_before=currency_before,
        currency_dollars_after=currency_after,
        bullet_separators_before=bullets,
    )


def dollar_positions(text: str) -> list[int]:
    return [index for index, char in enumerate(text)
            if char == "$" and (index == 0 or text[index - 1] != "\\")]


def paired_dollar_spans(text: str) -> list[tuple[int, int]]:
    """Locate display-math pairs without pairing two currency markers."""
    positions = dollar_positions(text)
    spans: list[tuple[int, int]] = []
    cursor = 0
    while cursor + 1 < len(positions):
        start, end = positions[cursor], positions[cursor + 1]
        content = text[start + 1:end]
        closes_math = end + 1 >= len(text) or not text[end + 1].isdigit()
        same_line = "\n" not in content
        math_like = bool(MATH_OPERATOR_RE.search(content) or COMPACT_MATH_RE.fullmatch(content))
        if closes_math and same_line and content and math_like:
            spans.append((start, end + 1))
            cursor += 2
        else:
            cursor += 1
    return spans


def remove_spans(text: str, spans: list[tuple[int, int]], *, keep_content: bool) -> str:
    pieces: list[str] = []
    cursor = 0
    for start, end in spans:
        pieces.append(text[cursor:start])
        if keep_content:
            pieces.append(text[start + 1:end - 1])
        cursor = end
    pieces.append(text[cursor:])
    return "".join(pieces)
