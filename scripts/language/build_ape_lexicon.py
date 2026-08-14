#!/usr/bin/env python3
"""Build the deterministic APE user lexicon used by the second-reader pilot.

The bridge converts the generated Webster store and the two authored
supplement stores into APE user-lexicon facts.  It does not guess lexical
categories: source rows without an ACE category are counted and skipped.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
from collections import Counter
from pathlib import Path

from build_math_lexicon import load_supplement, supplement_morphology


REPO = Path(__file__).resolve().parents[2]
WEBSTER = REPO / "hermes/app/runtime/experiments/language/webster_lexicon.pl"
SUPPLEMENT = REPO / "knowledge/strategies/abstraction/lexicon_supplement_pilot.pl"
LOOP = REPO / "knowledge/strategies/abstraction/lexicon_loop_admitted_pilot.pl"
OUTPUT = REPO / "hermes/app/runtime/experiments/language/ape_user_lexicon.pl"

# These pins are filled from one bootstrap build, then checked on every build.
EXPECTED_SOURCE_SHA256 = {
    "webster_lexicon.pl": "1368514d70580704c2ecc69529f5fb6d9ce3666c51962f447d730863c7966d33",
    "lexicon_supplement_pilot.pl": "2fd972be923dce235df5d0b0b8a0ef61b2759e78df8ab8923e2ac76cd8883ffd",
    "lexicon_loop_admitted_pilot.pl": "772f014832420c7d985d56274530a1baf6159dbb32e7f7dc86ade1c732fd2e23",
}
EXPECTED_FACTS = 183_440
EXPECTED_OUTPUT_SHA256 = "e72651cb5ec29e6a80d1d4739529ab49558343b92a070a4a86a71e006fc623a5"

ATOM = r"'((?:''|\\\\|\\'|[^'])*)'"


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def file_sha(path: Path) -> str:
    return sha256(path.read_bytes())


def decode_atom(value: str) -> str:
    return value.replace("''", "'").replace("\\\\", "\\")


def prolog_atom(value: str) -> str:
    return "'" + value.replace("\\", "\\\\").replace("'", "''") + "'"


def fact(functor: str, *args: str) -> str:
    return f"{functor}({', '.join(prolog_atom(arg) for arg in args)})."


def parse_webster_line(line: str) -> tuple[str, list[str]] | None:
    match = re.fullmatch(r"(wl_[a-z_]+)\((.*)\)\.", line)
    if not match:
        return None
    return match.group(1), [decode_atom(value) for value in re.findall(ATOM, match.group(2))]


def add_webster(entries: set[str], counts: Counter[str], skipped: Counter[str]) -> None:
    for line in WEBSTER.read_text(encoding="utf-8").splitlines():
        parsed = parse_webster_line(line)
        if parsed is None:
            continue
        tag, values = parsed
        produced: list[str] = []
        if tag == "wl_noun" and len(values) == 2:
            produced = [fact("noun_sg", values[0], values[0], "neutr"),
                        fact("noun_pl", values[1], values[0], "neutr")]
        elif tag == "wl_noun_plural_only" and len(values) == 1:
            produced = [fact("noun_pl", values[0], values[0], "neutr")]
        elif tag == "wl_verb" and len(values) == 6:
            base, third, _past, _ing, participle, voice = values
            if voice == "transitive":
                produced = [fact("tv_finsg", third, base),
                            fact("tv_infpl", base, base),
                            fact("tv_pp", participle, base)]
            elif voice == "intransitive":
                produced = [fact("iv_finsg", third, base),
                            fact("iv_infpl", base, base)]
        elif tag == "wl_adjective" and len(values) == 1:
            produced = [fact("adj_itr", values[0], values[0])]
        elif tag == "wl_adj_comp" and len(values) == 2:
            produced = [fact("adj_itr_comp", values[1], values[0])]
        elif tag == "wl_adj_superl" and len(values) == 2:
            produced = [fact("adj_itr_sup", values[1], values[0])]
        elif tag == "wl_adverb" and len(values) == 1:
            produced = [fact("adv", values[0], values[0])]
        elif tag == "wl_preposition" and len(values) == 1:
            produced = [fact("prep", values[0], values[0])]
        if produced:
            before = len(entries)
            entries.update(produced)
            counts[f"webster:{tag}:facts"] += len(entries) - before
            counts[f"webster:{tag}:rows"] += 1
        else:
            skipped[f"webster:{tag or 'unrecognized'}"] += 1


NOUN_CLASSES = {"common_noun", "math_term", "pedagogy_term", "temporal_word"}
NAME_CLASSES = {"given_name", "family_name", "place_name", "named_entity"}


def supplement_facts(row: dict[str, object]) -> list[str]:
    word = str(row["word"])
    word_class = str(row["class"])
    morphology, forms = supplement_morphology(str(row["morphology"]))
    if word_class in NOUN_CLASSES and morphology == "noun":
        singular, plural = forms
        return [fact("noun_sg", singular, singular, "neutr"),
                fact("noun_pl", plural, singular, "neutr")]
    if word_class in NAME_CLASSES and morphology == "none":
        gender = "human" if word_class in {"given_name", "family_name"} else "neutr"
        return [fact("pn_sg", word[:1].upper() + word[1:], word, gender)]
    if word_class == "adjective" and morphology == "invariant":
        return [fact("adj_itr", word, word)]
    if word_class == "adverb" and morphology == "invariant":
        return [fact("adv", word, word)]
    if word_class == "unit_abbreviation" and morphology in {"invariant", "expansion"}:
        base = forms[0] if forms else word
        return [fact("noun_sg", word, base, "neutr"),
                fact("noun_pl", word, base, "neutr")]
    return []


def loop_rows() -> list[dict[str, object]]:
    loop_atom = prolog_atom(str(LOOP))
    goal = (
        "use_module(library(http/json)),"
        f"load_files({loop_atom},[silent(true)]),"
        "findall(_{word:W,class:C,morphology:MText},"
        "(lexicon_loop_admitted_pilot:loop_admitted_word(W,C,M,_,_,_,_),"
        "term_string(M,MText,[quoted(true)])),Rows),"
        "json_write_dict(user_output,Rows,[width(0)])"
    )
    result = subprocess.run(
        ["swipl", "-q", "-g", goal, "-t", "halt"],
        text=True,
        capture_output=True,
        check=True,
    )
    return json.loads(result.stdout)


def add_authored(
    source: str,
    rows: list[dict[str, object]],
    entries: set[str],
    counts: Counter[str],
    skipped: Counter[str],
) -> None:
    for row in rows:
        word_class = str(row["class"])
        produced = supplement_facts(row)
        if not produced:
            skipped[f"{source}:{word_class}"] += 1
            continue
        before = len(entries)
        entries.update(produced)
        counts[f"{source}:{word_class}:facts"] += len(entries) - before
        counts[f"{source}:{word_class}:rows"] += 1


def render() -> tuple[bytes, dict[str, object]]:
    entries: set[str] = set()
    counts: Counter[str] = Counter()
    skipped: Counter[str] = Counter()
    add_webster(entries, counts, skipped)
    supplement = load_supplement()["words"]
    add_authored("supplement", supplement, entries, counts, skipped)
    loops = loop_rows()
    add_authored("loop", loops, entries, counts, skipped)
    source_sha = {
        WEBSTER.name: file_sha(WEBSTER),
        SUPPLEMENT.name: file_sha(SUPPLEMENT),
        LOOP.name: file_sha(LOOP),
    }
    metadata: dict[str, object] = {
        "facts": len(entries),
        "fact_counts": dict(sorted(counts.items())),
        "skip_census": dict(sorted(skipped.items())),
        "source_sha256": source_sha,
    }
    header = [
        ":- encoding(utf8).",
        "% GENERATED FILE. Rebuild with scripts/language/build_ape_lexicon.py; do not edit.",
        "% Sources: Webster runtime store, authored supplement, admitted consultation loop.",
        "% Classes without an exact ACE user-lexicon category are skipped.",
        f"% bridge_metadata({json.dumps(metadata, sort_keys=True, separators=(',', ':'))}).",
        "",
    ]
    content = "\n".join(header + sorted(entries) + [""]).encode("utf-8")
    metadata["output_sha256"] = sha256(content)
    return content, metadata


def verify_pins(metadata: dict[str, object]) -> None:
    if metadata["source_sha256"] != EXPECTED_SOURCE_SHA256:
        raise ValueError(
            f"source sha256 drift: measured {metadata['source_sha256']}, "
            f"expected {EXPECTED_SOURCE_SHA256}"
        )
    if metadata["facts"] != EXPECTED_FACTS:
        raise ValueError(f"fact-count drift: measured {metadata['facts']}, expected {EXPECTED_FACTS}")
    if metadata["output_sha256"] != EXPECTED_OUTPUT_SHA256:
        raise ValueError(
            f"output sha256 drift: measured {metadata['output_sha256']}, "
            f"expected {EXPECTED_OUTPUT_SHA256}"
        )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--no-pin", action="store_true", help="bootstrap measured pins")
    parser.add_argument("--output", type=Path, default=OUTPUT)
    args = parser.parse_args()
    content, metadata = render()
    if not args.no_pin:
        verify_pins(metadata)
    output = args.output if args.output.is_absolute() else REPO / args.output
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(content)
    print(json.dumps(metadata, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
