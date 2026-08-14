#!/usr/bin/env python3
"""Build the deterministic Webster morphology store used by language pilots.

The source is the public-domain Webster's Unabridged Dictionary data in the
read-only prolog-talk checkout.  This builder parses the small Lisp fact
syntax itself so bar-quoted domain labels remain one symbol.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from collections import Counter
from pathlib import Path


REPO = Path(__file__).resolve().parents[2]
SOURCE = Path("/Users/tio/Documents/GitHub/prolog-talk/dictionary.lisp")
STORE = REPO / "hermes/app/runtime/experiments/language/webster_lexicon.pl"
RESIDUE = STORE.with_name("webster_residue.jsonl")

EXPECTED_COUNTS = {
    "noun1": 56_171,
    "noun2": 1_509,
    "verb-t": 10_596,
    "verb-i": 4_720,
    "verb": 173,
    "adj": 26_182,
    "comp": 400,
    "superl": 395,
    "adverb": 3_944,
    "prep": 156,
    "pronoun": 83,
    "conj": 79,
    "interj": 122,
    "domain": 5_148,
}
EXPECTED_TOTAL_ROWS = 109_678
EXPECTED_RESIDUE_ROWS = 108
EXPECTED_SHAPE_NORMALIZATIONS = 135
EXPECTED_SOURCE_SHA256 = "2c04a6a476beb13480556a4a2313abe948e37db59018c12fab4f8737cb369336"
EXPECTED_STORE_SHA256 = "1368514d70580704c2ecc69529f5fb6d9ce3666c51962f447d730863c7966d33"

ARITIES = {
    "noun1": 2,
    "noun2": 1,
    "verb-t": 5,
    "verb-i": 5,
    "verb": 1,
    "adj": 1,
    "comp": 2,
    "superl": 2,
    "adverb": 1,
    "prep": 1,
    "pronoun": 1,
    "conj": 1,
    "interj": 1,
    "domain": 2,
}


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def lisp_symbols(body: str) -> list[str]:
    """Read whitespace-separated Lisp symbols, including |quoted symbols|."""
    values: list[str] = []
    i = 0
    while i < len(body):
        while i < len(body) and body[i].isspace():
            i += 1
        if i == len(body):
            break
        quoted = body[i] == "|"
        if quoted:
            i += 1
        chars: list[str] = []
        while i < len(body):
            ch = body[i]
            if ch == "\\" and i + 1 < len(body):
                chars.append(body[i + 1])
                i += 2
                continue
            if quoted and ch == "|":
                i += 1
                break
            if not quoted and ch.isspace():
                break
            chars.append(ch)
            i += 1
        values.append("".join(chars))
    return values


def parse_fact(line: str, line_number: int) -> tuple[str, list[str]] | None:
    stripped = line.strip()
    if ")) ;" in stripped:
        stripped = stripped.split(" ;", 1)[0]
    if not stripped.startswith("(*- (") or not stripped.endswith("))"):
        return None
    symbols = lisp_symbols(stripped[5:-2])
    if not symbols:
        raise ValueError(f"line {line_number}: empty fact")
    return symbols[0], symbols[1:]


def prolog_atom(value: str) -> str:
    lowered = value.lower().replace("\\", "\\\\").replace("'", "''")
    return f"'{lowered}'"


def target_fact(tag: str, values: list[str]) -> str:
    a = [prolog_atom(value) for value in values]
    if tag == "noun1":
        return f"wl_noun({a[0]}, {a[1]})."
    if tag == "noun2":
        return f"wl_noun_plural_only({a[0]})."
    if tag in {"verb-t", "verb-i"}:
        voice = "transitive" if tag == "verb-t" else "intransitive"
        return f"wl_verb({', '.join(a)}, {prolog_atom(voice)})."
    if tag == "verb":
        return f"wl_verb_defective({a[0]})."
    if tag == "adj":
        return f"wl_adjective({a[0]})."
    if tag == "comp":
        return f"wl_adj_comp({a[0]}, {a[1]})."
    if tag == "superl":
        return f"wl_adj_superl({a[0]}, {a[1]})."
    predicates = {
        "adverb": "wl_adverb",
        "prep": "wl_preposition",
        "pronoun": "wl_pronoun",
        "conj": "wl_conjunction",
        "interj": "wl_interjection",
        "domain": "wl_domain",
    }
    return f"{predicates[tag]}({', '.join(a)})."


def normalize_known_shape(tag: str, values: list[str]) -> tuple[list[str], bool]:
    """Normalize the source's 32 known arity exceptions without adding rows.

    Bare noun/comparison rows use identity as the missing counterpart.  Five
    noun rows carry a trailing legacy annotation or alternate after a complete
    pair; the source's first singular/plural pair is the morphology row.  The
    six-slot Zoutch row repeats its base before the ordinary past/ing/part
    sequence.  These rules keep the brief's one target row per source fact.
    """
    if tag == "domain" and len(values) >= 2:
        normalized = [values[0], " ".join(values[1:])]
        return normalized, normalized != values
    if tag == "noun1" and len(values) == 1:
        return [values[0], values[0]], True
    if tag == "noun1" and len(values) == 3:
        return values[:2], True
    if tag in {"comp", "superl"} and len(values) == 1:
        return [values[0], values[0]], True
    if tag == "verb-t" and len(values) == 6:
        return [values[0], values[1], values[3], values[4], values[5]], True
    return values, False


def render_store(source_bytes: bytes) -> tuple[bytes, list[dict[str, object]], Counter[str]]:
    source_sha = sha256(source_bytes)
    if source_sha != EXPECTED_SOURCE_SHA256:
        raise ValueError(
            f"source sha256 changed: measured {source_sha}, expected {EXPECTED_SOURCE_SHA256}"
        )
    source_text = source_bytes.decode("utf-8")
    converted: list[str] = []
    residue: list[dict[str, object]] = []
    counts: Counter[str] = Counter()
    residue_counts: Counter[str] = Counter()
    shape_normalizations = 0

    for line_number, line in enumerate(source_text.splitlines(), 1):
        parsed = parse_fact(line, line_number)
        if parsed is None:
            continue  # alphabet progress forms are not dictionary facts
        tag, values = parsed
        if tag not in ARITIES:
            residue.append({"line": line_number, "source": line, "tag": tag})
            residue_counts[tag] += 1
            continue
        values, normalized = normalize_known_shape(tag, values)
        shape_normalizations += int(normalized)
        if len(values) != ARITIES[tag]:
            raise ValueError(
                f"line {line_number}: {tag} has {len(values)} values, expected {ARITIES[tag]}"
            )
        converted.append(target_fact(tag, values))
        counts[tag] += 1

    if dict(counts) != EXPECTED_COUNTS:
        raise ValueError(f"row-count mismatch: measured {dict(counts)}, expected {EXPECTED_COUNTS}")
    if len(converted) != EXPECTED_TOTAL_ROWS:
        raise ValueError(f"total rows: measured {len(converted)}, expected {EXPECTED_TOTAL_ROWS}")
    if len(residue) != EXPECTED_RESIDUE_ROWS:
        raise ValueError(f"residue rows: measured {len(residue)}, expected {EXPECTED_RESIDUE_ROWS}")
    if shape_normalizations != EXPECTED_SHAPE_NORMALIZATIONS:
        raise ValueError(
            "known shape normalizations: "
            f"measured {shape_normalizations}, expected {EXPECTED_SHAPE_NORMALIZATIONS}"
        )

    source_date = os.stat(SOURCE).st_mtime
    from datetime import datetime

    date = datetime.fromtimestamp(source_date).date().isoformat()
    header = [
        ":- encoding(utf8).",
        ":- discontiguous wl_noun/2, wl_noun_plural_only/1, wl_verb/6,",
        "                 wl_verb_defective/1, wl_adjective/1, wl_adj_comp/2,",
        "                 wl_adj_superl/2, wl_adverb/1, wl_preposition/1,",
        "                 wl_pronoun/1, wl_conjunction/1, wl_interjection/1,",
        "                 wl_domain/2.",
        "% GENERATED FILE. Rebuild with scripts/language/build_webster_lexicon.py; do not edit.",
        "% Webster's Unabridged Dictionary, Project Gutenberg ebook 673 (public domain).",
        f"% Converted from {SOURCE}.",
        f"% Source file date: {date}. Builder: scripts/language/build_webster_lexicon.py.",
        "",
    ]
    summary = (
        f'wl_summary(total_rows({len(converted)}), residue_rows({len(residue)}), '
        f'source_sha256("{source_sha}")).'
    )
    content = "\n".join(header + converted + ["", summary, ""]).encode("utf-8")
    return content, residue, residue_counts


def residue_bytes(rows: list[dict[str, object]], counts: Counter[str]) -> bytes:
    records: list[dict[str, object]] = [
        {"kind": "summary", "tag_counts": dict(sorted(counts.items())), "total_rows": len(rows)}
    ]
    records.extend(rows)
    text = "".join(
        json.dumps(record, ensure_ascii=False, sort_keys=True, separators=(",", ":")) + "\n"
        for record in records
    )
    return text.encode("utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--no-pin", action="store_true", help="bootstrap the store sha256 pin")
    args = parser.parse_args()

    store, residue, tags = render_store(SOURCE.read_bytes())
    measured = sha256(store)
    if not args.no_pin and measured != EXPECTED_STORE_SHA256:
        raise SystemExit(
            f"store sha256 changed: measured {measured}, expected {EXPECTED_STORE_SHA256}"
        )
    STORE.parent.mkdir(parents=True, exist_ok=True)
    STORE.write_bytes(store)
    RESIDUE.write_bytes(residue_bytes(residue, tags))
    print(f"webster rows={EXPECTED_TOTAL_ROWS} residue={len(residue)} sha256={measured}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
