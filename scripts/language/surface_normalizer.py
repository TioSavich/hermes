#!/usr/bin/env python3
"""Measured surface normalization shared by the PUSU readers.

Rules are restricted to section 5 of ``surface-form-audit.md``.  Every rule
definition and every emitted receipt carries its audit row.  Benchmark-only
rules are present but disabled unless ``profile="benchmark"`` is selected.

The returned text is the surface passed to both readers.  Exact decimal and
ordinal token terms are also emitted in ``tokens`` because rendering either
term back into prose would make it ungrammatical.  Character edits retain a
source-coordinate map, so a changed surface is never presented as an original
evidence span.
"""

from __future__ import annotations

import argparse
import json
import re
from dataclasses import dataclass
from typing import Callable, Match


AUDIT = ".superpowers/sdd/language-lane/surface-form-audit.md#5-normalization-spec"
WORD_PROBLEM_AUDIT = (
    ".superpowers/sdd/language-lane/"
    "codex-brief-word-problem-grammar.md#32-bracketed-authored-annotations-are-stripped-never-read"
)
BOUNDARY = "\ue000"
GUTTER = "\ue001"


@dataclass(frozen=True)
class Rule:
    rule_id: str
    audit_row: str
    scope: str
    measured_basis: str


# Each executable/no-op rule cites the measured row that authorizes it.
RULES = {
    "N1": Rule("N1", f"{AUDIT}-n1", "benchmark-only",
               "2,004/2,004 solutions; 6,207 literal \\n occurrences"),
    "N2": Rule("N2", f"{AUDIT}-n2", "benchmark-only",
               "8,211/8,211 Step N - markers; 2,004/2,004 solutions"),
    "N3": Rule("N3", f"{AUDIT}-n3", "both",
               "curly apostrophes measured in benchmark and IM rows"),
    "N4": Rule("N4", f"{AUDIT}-n4", "both",
               "curly double quotes measured in IM and benchmark rows"),
    "N5": Rule("N5", f"{AUDIT}-n5", "both",
               "en/em dashes measured in benchmark, IM, and MINT rows"),
    "N6": Rule("N6", f"{AUDIT}-n6", "both",
               "comma-grouped numerals measured in all audited corpora"),
    "N7": Rule("N7", f"{AUDIT}-n7", "both",
               "trailing-zero and leading-dot decimals measured in benchmark rows"),
    "N8": Rule("N8", f"{AUDIT}-n8", "both",
               "ordinal suffixes measured in benchmark and IM rows"),
    "N9": Rule("N9", f"{AUDIT}-n9", "benchmark-only",
               "attached unit abbreviations and superscripts measured in benchmark/MINT"),
    "N10": Rule("N10", f"{AUDIT}-n10", "IM-only",
                "IM page furniture and 58,903 measured bullet glyphs"),
    "N11": Rule("N11", f"{AUDIT}-n11", "IM-only",
                "65,225/249,460 IM lines with an interior four-space gutter"),
    "N12": Rule("N12", f"{AUDIT}-n12", "IM-only",
                "69,667/249,460 IM lines beginning with lowercase text"),
    "N13": Rule("N13", f"{AUDIT}-n13", "both",
                "interior repeated whitespace measured in benchmark and IM rows"),
    "N14": Rule("N14", f"{AUDIT}-n14", "both-no-op",
                "currency and percent frequency measured; preserve both glyphs"),
    "N15": Rule("N15", f"{AUDIT}-n15", "neither-no-op",
                "audited no-op row; no normalizer rewrite authorized"),
    "N16": Rule("N16", WORD_PROBLEM_AUDIT, "IM-only",
                "94 measured grade 6-7 annotation-shaped sentences"),
}


@dataclass
class MappedChar:
    value: str
    source_start: int
    source_end: int


Replacement = str | Callable[[Match[str]], str]


class Normalizer:
    def __init__(self, text: str, profile: str) -> None:
        if profile not in {"im", "benchmark"}:
            raise ValueError("profile must be 'im' or 'benchmark'")
        self.original = text
        self.profile = profile
        self.chars = [MappedChar(char, index, index + 1) for index, char in enumerate(text)]
        self.edits: list[dict[str, object]] = []

    @property
    def text(self) -> str:
        return "".join(char.value for char in self.chars)

    def replace(self, pattern: str, replacement: Replacement, rule_id: str,
                *, flags: int = 0) -> None:
        source = self.text
        matches = list(re.finditer(pattern, source, flags))
        if not matches:
            return
        output: list[MappedChar] = []
        cursor = 0
        for match in matches:
            if match.start() < cursor:
                continue
            output.extend(self.chars[cursor:match.start()])
            rendered = replacement(match) if callable(replacement) else match.expand(replacement)
            matched = self.chars[match.start():match.end()]
            if matched:
                source_start = min(char.source_start for char in matched)
                source_end = max(char.source_end for char in matched)
            else:
                source_start = source_end = self._boundary_source(match.start())
            normalized_start = len(output)
            output.extend(MappedChar(char, source_start, source_end) for char in rendered)
            normalized_end = len(output)
            original_surface = match.group(0)
            if original_surface != rendered:
                rule = RULES[rule_id]
                self.edits.append(
                    {
                        "rule": rule_id,
                        "audit_row": rule.audit_row,
                        "source_span": [source_start, source_end],
                        "normalized_span": [normalized_start, normalized_end],
                        "source_text": original_surface,
                        "normalized_text": rendered.replace(BOUNDARY, "\n").replace(GUTTER, "\n"),
                    }
                )
            cursor = match.end()
        output.extend(self.chars[cursor:])
        self.chars = output

    def _boundary_source(self, offset: int) -> int:
        if offset < len(self.chars):
            return self.chars[offset].source_start
        return len(self.original)

    def run(self) -> dict[str, object]:
        if self.profile == "benchmark":
            # N1: space plus a reader-consumable boundary; never concatenate lines.
            self.replace(r"\\n", f" {BOUNDARY}", "N1")
            # N2: preserve Step N and emit its boundary token in token receipts.
            self.replace(r"(?i)\bstep\s+(\d+)\s*-\s*",
                         lambda match: f"{BOUNDARY}Step {match.group(1)} ", "N2")

        # N3-N5 are character folds.  N5 remains a dash surface, not arithmetic.
        self.replace("[’‘]", "'", "N3")
        self.replace('[“”]', '"', "N4")
        self.replace("[–—]", "-", "N5")

        # N6 accepts one or more exact three-digit groups and rejects spaced lists.
        self.replace(r"(?<![\d,])(\d{1,3}(?:,\d{3})+)(?![\d,])",
                     lambda match: match.group(1).replace(",", ""), "N6")

        if self.profile == "benchmark":
            # N9 separates a numeral from its unit and makes exponents explicit.
            self.replace(r"(?<=\d)(?=[A-Za-z])", " ", "N9")
            self.replace("²", " ^ 2", "N9")
            self.replace("³", " ^ 3", "N9")

        if self.profile == "im":
            # N16 removes authored metadata before any reader can receive it.
            # The edit receipt retains the exact source span and source text.
            self.replace(r"\[[^\[\]]*\]", "", "N16")
            # N10 removes only the measured guide furniture classes.
            self.replace(r"(?m)^[ \t]*Illustrative Mathematics®[ \t]+\d+[ \t]*$",
                         "", "N10")
            self.replace(r"(?m)^[ \t]*CC BY NC 2024[ \t]*$", "", "N10")
            self.replace("[•◦▪●]", " ", "N10")
            # N11 uses a private boundary so N12 cannot rejoin unrelated columns.
            self.replace(r"(?<=\S)[ \t]{4,}(?=\S)", GUTTER, "N11")
            # N12 joins only hard wraps licensed by the measured continuation head.
            self.replace(r"(?<![.!?])\n(?=[a-z0-9\"'])", " ", "N12")

        # N13 collapses horizontal whitespace; semantic boundaries remain intact.
        self.replace(r"[ \t]{2,}", " ", "N13")
        self.replace(f"[{BOUNDARY}{GUTTER}]", "\n", "N13")

        return self.receipt()

    def receipt(self) -> dict[str, object]:
        applied_ids = list(dict.fromkeys(str(edit["rule"]) for edit in self.edits))
        return {
            "profile": self.profile,
            "text": self.text,
            "changed": self.text != self.original,
            "applied_rules": [rule_receipt(rule_id) for rule_id in applied_ids],
            "edits": self.edits,
            "offset_map": compress_offset_map(self.chars),
            "tokens": exact_token_receipts(
                self.text, self.chars, include_benchmark_tokens=self.profile == "benchmark"
            ),
            "preserved_no_op_rules": [rule_receipt("N14"), rule_receipt("N15")],
        }


def rule_receipt(rule_id: str) -> dict[str, str]:
    rule = RULES[rule_id]
    return {
        "rule": rule.rule_id,
        "audit_row": rule.audit_row,
        "scope": rule.scope,
        "measured_basis": rule.measured_basis,
    }


def compress_offset_map(chars: list[MappedChar]) -> list[dict[str, int | str]]:
    if not chars:
        return []
    rows: list[dict[str, int | str]] = []
    start = 0
    mode = "copy"
    for index in range(1, len(chars) + 1):
        if index == len(chars):
            boundary = True
        else:
            prior = chars[index - 1]
            current = chars[index]
            current_mode = (
                "copy"
                if current.source_start == prior.source_start + 1
                and current.source_end == prior.source_end + 1
                else "mapped"
            )
            boundary = current_mode != mode
        if boundary:
            group = chars[start:index]
            rows.append(
                {
                    "normalized_start": start,
                    "normalized_end": index,
                    "source_start": min(char.source_start for char in group),
                    "source_end": max(char.source_end for char in group),
                    "mode": mode,
                }
            )
            start = index
            if index < len(chars):
                mode = current_mode
    return rows


def exact_token_receipts(text: str, chars: list[MappedChar], *,
                         include_benchmark_tokens: bool) -> list[dict[str, object]]:
    tokens: list[dict[str, object]] = []
    decimal_pattern = re.compile(r"(?<![\w.])([+-]?)(\d*)\.(\d+)(?!\w|\.\d)")
    for match in decimal_pattern.finditer(text):
        sign, whole_text, fractional_text = match.groups()
        whole = int((sign or "") + (whole_text or "0"))
        fraction = int(fractional_text)
        tokens.append(token_receipt(match, chars, "N7",
                                    f"decimal({whole},{fraction},{len(fractional_text)})",
                                    fractional_digits=fractional_text))
    ordinal_pattern = re.compile(r"(?<!\w)(\d+)(st|nd|rd|th)\b", re.IGNORECASE)
    for match in ordinal_pattern.finditer(text):
        tokens.append(token_receipt(match, chars, "N8",
                                    f"ordinal({int(match.group(1))})"))
    if include_benchmark_tokens:
        step_pattern = re.compile(r"(?im)^Step\s+(\d+)\b")
        for match in step_pattern.finditer(text):
            tokens.append(token_receipt(match, chars, "N2",
                                        f"step_boundary({int(match.group(1))})"))
    return sorted(tokens, key=lambda row: (row["normalized_span"], row["rule"]))


def token_receipt(match: Match[str], chars: list[MappedChar], rule_id: str,
                  term: str, **extra: object) -> dict[str, object]:
    selected = chars[match.start():match.end()]
    source_start = min(char.source_start for char in selected)
    source_end = max(char.source_end for char in selected)
    return {
        "rule": rule_id,
        "audit_row": RULES[rule_id].audit_row,
        "surface": match.group(0),
        "term": term,
        "normalized_span": [match.start(), match.end()],
        "source_span": [source_start, source_end],
        **extra,
    }


def normalize_surface(text: str, *, profile: str = "im") -> dict[str, object]:
    """Normalize one document and return text plus provenance receipts."""
    return Normalizer(text, profile).run()


def check_surface_normalizer() -> None:
    im = normalize_surface("• Plane A travels 2,800 miles. It’s 12.50–13.00. 3rd", profile="im")
    assert im["text"] == " Plane A travels 2800 miles. It's 12.50-13.00. 3rd"
    applied = {row["rule"] for row in im["applied_rules"]}
    assert {"N3", "N5", "N6", "N10"} <= applied
    terms = {row["term"] for row in im["tokens"]}
    assert {"decimal(12,50,2)", "decimal(13,0,2)", "ordinal(3)"} <= terms
    assert all(row.get("audit_row") for row in im["applied_rules"])
    assert all(row.get("audit_row") for row in im["tokens"])
    benchmark = normalize_surface(r"Step 2 - Find 1,250cm³.\nStep 3 - Stop.",
                                  profile="benchmark")
    assert "Step 2 Find 1250 cm ^ 3." in benchmark["text"]
    assert "\nStep 3 Stop." in benchmark["text"]
    assert {"step_boundary(2)", "step_boundary(3)"} <= {
        row["term"] for row in benchmark["tokens"]
    }
    assert normalize_surface(r"Step 2 - Find 1,250cm³.\n", profile="im")["text"] == (
        r"Step 2 - Find 1250cm³.\n"
    )
    annotation = normalize_surface(
        "How far does the car travel? [solution: 140*7=980]", profile="im"
    )
    assert annotation["text"] == "How far does the car travel? "
    annotation_edits = [row for row in annotation["edits"] if row["rule"] == "N16"]
    assert annotation_edits == [
        {
            "rule": "N16",
            "audit_row": WORD_PROBLEM_AUDIT,
            "source_span": [29, 50],
            "normalized_span": [29, 29],
            "source_text": "[solution: 140*7=980]",
            "normalized_text": "",
        }
    ]
    assert "980" not in annotation["text"]
    assert normalize_surface(
        "How far does the car travel? [solution: 140*7=980]",
        profile="benchmark",
    )["text"].endswith("[solution: 140*7=980]")
    print("surface_normalizer: all receipts passed")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("text", nargs="?")
    parser.add_argument("--profile", choices=["im", "benchmark"], default="im")
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    if args.check:
        check_surface_normalizer()
        return 0
    if args.text is None:
        parser.error("text is required unless --check is used")
    print(json.dumps(normalize_surface(args.text, profile=args.profile),
                     ensure_ascii=False, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
