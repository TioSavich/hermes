#!/usr/bin/env python3
"""Build the demand-fit mathematics lexicon pilot.

Corpus text is downcased and sent through SWI-Prolog's tokenize_atom/2, the
same tokenizer used by hermes/math_claim_language.pl.  Webster entries supply
morphology and categories; unknown tokens remain counted findings.
"""

from __future__ import annotations

import argparse
import ast
import hashlib
import json
import re
import subprocess
from collections import Counter, defaultdict
from pathlib import Path
from typing import Iterable

from build_webster_lexicon import ARITIES, SOURCE as WEBSTER_SOURCE
from build_webster_lexicon import normalize_known_shape, parse_fact


REPO = Path(__file__).resolve().parents[2]
QUESTION_CORPUS = REPO / "hermes/app/runtime/experiments/questions/question_records.jsonl"
DATASET = REPO / "hermes/app/runtime/experiments/sidekick/datasets/mistake_location_full.json"
QUESTIONING_SOURCE = REPO / ".superpowers/sdd/questioning-paper/scale_recurrence.py"
OUTPUT = REPO / "knowledge/strategies/abstraction/math_lexicon_pilot.pl"
SUPPLEMENT = REPO / "knowledge/strategies/abstraction/lexicon_supplement_pilot.pl"

# Measured pins are filled after the bootstrap build.  They turn source drift
# into an explicit builder failure rather than a silent lexicon change.
EXPECTED_QUESTION_RECORDS = 2_621
EXPECTED_DATASET_RECORDS = 2_004
EXPECTED_MATH_TERMS = 78
EXPECTED_BASELINE_UNKNOWNS = 764
EXPECTED_BASELINE_UNKNOWN_OCCURRENCES = 12_529
EXPECTED_ML_WORDS = 5_006
EXPECTED_ML_UNKNOWNS = 19
EXPECTED_OUTPUT_SHA256 = "e69a7c7916a3225b329c7cee0c953a6601182bdbff59a7b72347c02b868f3a7a"

MATH_FIELDS = {"math", "arith", "geom", "alg"}
CATEGORY_ORDER = {
    name: i
    for i, name in enumerate(
        [
            "noun",
            "verb",
            "adjective",
            "adverb",
            "preposition",
            "pronoun",
            "conjunction",
            "interjection",
            "domain",
        ]
    )
}
RESIDUAL_CLASSES = {"tokenizer_artifact", "contraction_fragment"}


def file_sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def prolog_atom(value: str) -> str:
    return "'" + value.replace("\\", "\\\\").replace("'", "''") + "'"


def category_sort(key: tuple[str, str]) -> tuple[str, int, str]:
    base, category = key
    return base, CATEGORY_ORDER.get(category, len(CATEGORY_ORDER)), category


def swipl_tokens(texts: list[str]) -> list[list[object]]:
    """Tokenize all texts in one SWI process using tokenize_atom/2."""
    goal = (
        "use_module(library(http/json)),"
        "use_module(library(porter_stem)),"
        "json_read(user_input,Texts),"
        "maplist(tokenize_atom,Texts,Rows),"
        "json_write(user_output,Rows)"
    )
    result = subprocess.run(
        ["swipl", "-q", "-g", goal, "-t", "halt"],
        input=json.dumps([text.lower() for text in texts], ensure_ascii=False),
        text=True,
        capture_output=True,
        check=True,
    )
    return json.loads(result.stdout)


def lexical_tokens(rows: Iterable[list[object]], stop: set[str]) -> Counter[str]:
    counts: Counter[str] = Counter()
    for row in rows:
        for token in row:
            if not isinstance(token, str):
                continue
            word = token.lower()
            if word in stop or not any(ch.isalpha() for ch in word):
                continue
            counts[word] += 1
    return counts


def questioning_terms_and_stop(path: Path) -> tuple[list[tuple[str, str]], set[str]]:
    """Read the MATH_TERM alternatives and STOP words without importing code."""
    tree = ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
    pattern = None
    stop: set[str] | None = None
    for node in tree.body:
        if not isinstance(node, ast.Assign) or len(node.targets) != 1:
            continue
        target = node.targets[0]
        if not isinstance(target, ast.Name):
            continue
        if target.id == "STOP":
            call = node.value
            if (
                isinstance(call, ast.Call)
                and call.args
                and isinstance(call.args[0], ast.Call)
                and isinstance(call.args[0].func, ast.Attribute)
                and isinstance(call.args[0].func.value, ast.Constant)
            ):
                stop = set(str(call.args[0].func.value.value).split())
        if target.id == "MATH_TERM":
            call = node.value
            if isinstance(call, ast.Call) and call.args and isinstance(call.args[0], ast.Constant):
                pattern = str(call.args[0].value)
    if stop is None or pattern is None:
        raise ValueError(f"could not read STOP and MATH_TERM from {path}")
    if not pattern.startswith(r"\b(") or not pattern.endswith(r")\b"):
        raise ValueError("MATH_TERM no longer has the expected flat alternation")
    alternatives = pattern[3:-3].split("|")
    terms: list[tuple[str, str]] = []
    for raw in alternatives:
        display = raw.replace("[- ]", " ").replace("\\-", "-")
        terms.append((raw, display))
    return terms, stop


def load_webster():
    forms: dict[tuple[str, str], set[str]] = defaultdict(set)
    form_map: dict[str, set[tuple[str, str]]] = defaultdict(set)
    math_domains: dict[str, set[str]] = defaultdict(set)

    def add(base: str, category: str, surfaces: Iterable[str]) -> None:
        key = (base, category)
        for surface in surfaces:
            forms[key].add(surface)
            form_map[surface].add(key)

    for line_number, line in enumerate(WEBSTER_SOURCE.read_text(encoding="utf-8").splitlines(), 1):
        parsed = parse_fact(line, line_number)
        if parsed is None:
            continue
        tag, values = parsed
        if tag not in ARITIES:
            continue
        values, _ = normalize_known_shape(tag, values)
        values = [value.lower() for value in values]
        if tag == "noun1":
            add(values[0], "noun", values[:2])
        elif tag == "noun2":
            add(values[0], "noun", values)
        elif tag in {"verb-t", "verb-i"}:
            add(values[0], "verb", values[:5])
        elif tag == "verb":
            add(values[0], "verb", values)
        elif tag == "adj":
            add(values[0], "adjective", values)
        elif tag in {"comp", "superl"}:
            add(values[0], "adjective", values)
        elif tag in {"adverb", "prep", "pronoun", "conj", "interj"}:
            category = {
                "prep": "preposition",
                "pronoun": "pronoun",
                "conj": "conjunction",
                "interj": "interjection",
                "adverb": "adverb",
            }[tag]
            add(values[0], category, values)
        elif tag == "domain" and values[1] in MATH_FIELDS:
            math_domains[values[0]].add(values[1])
    return forms, form_map, math_domains


def load_supplement():
    """Consult the authored supplement and return its rows as JSON data."""
    goal = (
        "use_module(library(http/json)),"
        f"load_files({prolog_atom(str(SUPPLEMENT))},[silent(true)]),"
        "findall(_{word:W,class:C,morphology:MText,occurrences:N,pass:P},"
        "(lexicon_supplement_pilot:ls_word(W,C,M,E,_),"
        "(E=evidence(occurrences(N))->P=slice_2;"
        "E=evidence(occurrences(N),pass(P))),"
        "term_string(M,MText,[quoted(true)])),Words),"
        "findall(_{tokens:T,class:C},lexicon_supplement_pilot:ls_phrase(T,C,_),Phrases),"
        "json_write_dict(user_output,_{words:Words,phrases:Phrases})"
    )
    result = subprocess.run(
        ["swipl", "-q", "-g", goal, "-t", "halt"],
        text=True,
        capture_output=True,
        check=True,
    )
    return json.loads(result.stdout)


def supplement_morphology(text: str) -> tuple[str, list[str]]:
    if text == "none":
        return "none", []
    if text == "forms(invariant)":
        return "invariant", []
    match = re.fullmatch(r"expands_to\(([^()]+)\)", text)
    if match:
        return "expansion", [match.group(1)]
    match = re.fullmatch(r"forms\(noun\(([^(),]+),([^(),]+)\)\)", text)
    if match:
        return "noun", [part.strip() for part in match.groups()]
    match = re.fullmatch(
        r"forms\(verb\(([^(),]+),([^(),]+),([^(),]+),([^(),]+),([^(),]+)\)\)",
        text,
    )
    if match:
        return "verb", [part.strip() for part in match.groups()]
    raise ValueError(f"unsupported supplement morphology: {text}")


def extend_with_supplement(forms, form_map, supplement):
    classes_by_key: dict[tuple[str, str], set[str]] = defaultdict(set)

    def add(base: str, category: str, surfaces: Iterable[str], word_class: str) -> None:
        key = (base, category)
        classes_by_key[key].add(word_class)
        for surface in surfaces:
            forms[key].add(surface)
            form_map[surface].add(key)

    for row in supplement["words"]:
        word = str(row["word"])
        word_class = str(row["class"])
        kind, values = supplement_morphology(str(row["morphology"]))
        if word_class in RESIDUAL_CLASSES:
            continue
        if kind == "noun":
            add(values[0], "noun", values, word_class)
        elif kind == "verb":
            add(values[0], "verb", values, word_class)
        else:
            add(word, word_class, [word], word_class)
    return classes_by_key


def load_demands(stop: set[str], term_specs: list[tuple[str, str]]):
    question_rows = [json.loads(line) for line in QUESTION_CORPUS.read_text(encoding="utf-8").splitlines()]
    dataset_rows = json.loads(DATASET.read_text(encoding="utf-8"))
    if len(question_rows) != EXPECTED_QUESTION_RECORDS:
        raise ValueError(f"question records: measured {len(question_rows)}, expected {EXPECTED_QUESTION_RECORDS}")
    if len(dataset_rows) != EXPECTED_DATASET_RECORDS:
        raise ValueError(f"dataset records: measured {len(dataset_rows)}, expected {EXPECTED_DATASET_RECORDS}")

    question_texts = [str(row["text"]) for row in question_rows]
    dataset_texts: list[str] = []
    for row in dataset_rows:
        dataset_texts.append(str(row["question"]).replace("\\n", "\n"))
        dataset_texts.append(str(row["solution"]).replace("\\n", "\n"))
    term_texts = [display for _, display in term_specs]

    question_counts = lexical_tokens(swipl_tokens(question_texts), stop)
    dataset_counts = lexical_tokens(swipl_tokens(dataset_texts), stop)
    term_token_rows = swipl_tokens(term_texts)
    term_counts = lexical_tokens(term_token_rows, set())
    term_tokens = [
        [str(token).lower() for token in row if isinstance(token, str) and any(ch.isalpha() for ch in token)]
        for row in term_token_rows
    ]
    return question_counts, dataset_counts, term_counts, term_tokens


def demand_terms(
    counts: Counter[str], flags: set[str], fields: set[str], supplement_classes: set[str]
) -> list[str]:
    terms: list[str] = []
    if counts["question_corpus"]:
        terms.append(f"question_corpus({counts['question_corpus']})")
    if counts["dataset"]:
        terms.append(f"dataset({counts['dataset']})")
    if "questioning_paper_lexicon" in flags:
        terms.append("questioning_paper_lexicon")
    terms.extend(f"webster_domain({prolog_atom(field)})" for field in sorted(fields))
    terms.extend(
        f"supplement_class({prolog_atom(word_class)})"
        for word_class in sorted(supplement_classes)
    )
    return terms


def render(no_pin: bool) -> tuple[bytes, dict[str, object]]:
    term_specs, stop = questioning_terms_and_stop(QUESTIONING_SOURCE)
    forms, form_map, math_domains = load_webster()
    question, dataset, term_counts, term_token_rows = load_demands(stop, term_specs)

    if not no_pin and len(term_specs) != EXPECTED_MATH_TERMS:
        raise ValueError(f"MATH_TERM alternatives: measured {len(term_specs)}, expected {EXPECTED_MATH_TERMS}")

    def collect_evidence():
        counts: dict[tuple[str, str], Counter[str]] = defaultdict(Counter)
        flags: dict[tuple[str, str], set[str]] = defaultdict(set)
        absent: Counter[str] = Counter()
        for source_name, source_counts in [("question_corpus", question), ("dataset", dataset)]:
            for surface, count in source_counts.items():
                keys = form_map.get(surface)
                if not keys:
                    absent[surface] += count
                    continue
                for key in keys:
                    counts[key][source_name] += count
        for surface, count in term_counts.items():
            keys = form_map.get(surface)
            if not keys:
                absent[surface] += count
                continue
            for key in keys:
                flags[key].add("questioning_paper_lexicon")
        return counts, flags, absent

    _baseline_counts, _baseline_flags, baseline_unknown = collect_evidence()
    if len(baseline_unknown) != EXPECTED_BASELINE_UNKNOWNS:
        raise ValueError(
            f"baseline unknown rows: measured {len(baseline_unknown)}, "
            f"expected {EXPECTED_BASELINE_UNKNOWNS}"
        )
    if sum(baseline_unknown.values()) != EXPECTED_BASELINE_UNKNOWN_OCCURRENCES:
        raise ValueError(
            f"baseline unknown occurrences: measured {sum(baseline_unknown.values())}, "
            f"expected {EXPECTED_BASELINE_UNKNOWN_OCCURRENCES}"
        )

    supplement = load_supplement()
    baseline_rows = [row for row in supplement["words"] if row["pass"] == "slice_2"]
    supplement_word_rows = [str(row["word"]) for row in baseline_rows]
    if len(supplement_word_rows) != EXPECTED_BASELINE_UNKNOWNS:
        raise ValueError(
            f"supplement word rows: measured {len(supplement_word_rows)}, "
            f"expected {EXPECTED_BASELINE_UNKNOWNS}"
        )
    duplicates = sorted(
        word for word, count in Counter(supplement_word_rows).items() if count != 1
    )
    if duplicates:
        raise ValueError(f"supplement duplicate words: {duplicates}")
    supplement_counts = Counter(
        {str(row["word"]): int(row["occurrences"]) for row in baseline_rows}
    )
    if supplement_counts != baseline_unknown:
        missing = sorted(set(baseline_unknown) - set(supplement_counts))
        extra = sorted(set(supplement_counts) - set(baseline_unknown))
        mismatched = sorted(
            word for word in set(baseline_unknown) & set(supplement_counts)
            if baseline_unknown[word] != supplement_counts[word]
        )
        raise ValueError(
            f"supplement coverage differs: missing={missing}, extra={extra}, "
            f"count_mismatches={mismatched}"
        )
    expected_phrases = {tuple(tokens) for tokens in term_token_rows if len(tokens) > 1}
    supplement_phrase_rows = [tuple(row["tokens"]) for row in supplement["phrases"]]
    supplement_phrases = set(supplement_phrase_rows)
    if len(supplement_phrases) != len(supplement_phrase_rows):
        raise ValueError("supplement contains duplicate phrase rows")
    if supplement_phrases != expected_phrases:
        raise ValueError(
            f"supplement phrase coverage differs: measured={sorted(supplement_phrases)}, "
            f"expected={sorted(expected_phrases)}"
        )

    supplement_classes = extend_with_supplement(forms, form_map, supplement)
    evidence_counts, evidence_flags, unknown = collect_evidence()
    evidence_fields: dict[tuple[str, str], set[str]] = defaultdict(set)

    for word, fields in math_domains.items():
        keys = form_map.get(word)
        if not keys:
            key = (word, "domain")
            forms[key].add(word)
            form_map[word].add(key)
            keys = {key}
        for key in keys:
            evidence_fields[key].update(fields)

    demanded_keys = sorted(
        set(evidence_counts) | set(evidence_flags) | set(evidence_fields),
        key=category_sort,
    )
    if not no_pin and len(demanded_keys) != EXPECTED_ML_WORDS:
        raise ValueError(f"ml_word rows: measured {len(demanded_keys)}, expected {EXPECTED_ML_WORDS}")
    if not no_pin and len(unknown) != EXPECTED_ML_UNKNOWNS:
        raise ValueError(f"ml_unknown rows: measured {len(unknown)}, expected {EXPECTED_ML_UNKNOWNS}")

    lines = [
        ":- encoding(utf8).",
        "/** <module> Demand-fit mathematics lexicon pilot",
        " *",
        " * Generated from repository demand sources by",
        " * scripts/language/build_math_lexicon.py. Each row keeps Webster",
        " * morphology beside counted demand evidence. Unknowns remain findings.",
        " *",
        " * Check from the repository root:",
        " * `swipl -q -l paths.pl -l knowledge/strategies/abstraction/math_lexicon_pilot.pl -g math_lexicon_pilot:check_math_lexicon_pilot -t halt`",
        " */",
        ":- module(math_lexicon_pilot,",
        "          [ ml_word/4, ml_unknown/2, ml_baseline_unknown/2, ml_source_term/3,",
        "            math_lexicon_pilot_summary/1, check_math_lexicon_pilot/0",
        "          ]).",
        "",
        ":- use_module('english_morphology.pl').",
        "",
        "% GENERATED FILE. Rebuild with scripts/language/build_math_lexicon.py; do not edit.",
        f"% question_records.jsonl sha256: {file_sha(QUESTION_CORPUS)}",
        f"% mistake_location_full.json sha256: {file_sha(DATASET)}",
        f"% scale_recurrence.py sha256: {file_sha(QUESTIONING_SOURCE)}",
        f"% lexicon_supplement_pilot.pl sha256: {file_sha(SUPPLEMENT)}",
        "",
    ]

    for base, category in demanded_keys:
        listed_forms = ", ".join(prolog_atom(form) for form in sorted(forms[(base, category)]))
        demands = demand_terms(
            evidence_counts[(base, category)],
            evidence_flags[(base, category)],
            evidence_fields[(base, category)],
            supplement_classes[(base, category)],
        )
        lines.append(
            f"ml_word({prolog_atom(base)}, {category}, forms([{listed_forms}]), "
            f"demand([{', '.join(demands)}]))."
        )

    lines.extend(["", "% Tokens absent from Webster, counted across admitted demand sources."])
    for word, count in sorted(unknown.items(), key=lambda item: item[0]):
        lines.append(f"ml_unknown({prolog_atom(word)}, {count}).")

    lines.extend(["", "% Slice-1 Webster-only unknowns checked against the authored supplement."])
    for word, count in sorted(baseline_unknown.items(), key=lambda item: item[0]):
        lines.append(f"ml_baseline_unknown({prolog_atom(word)}, {count}).")

    lines.extend(["", "% The tracked questioning-paper alternatives absorbed by this store."])
    for (raw, display), tokens in zip(term_specs, term_token_rows):
        token_text = ", ".join(prolog_atom(token) for token in tokens)
        lines.append(
            f"ml_source_term(questioning_paper_lexicon, {prolog_atom(raw)}, tokens([{token_text}]))."
        )

    q_occ = sum(question.values())
    d_occ = sum(dataset.values())
    summary = (
        f"summary(ml_words({len(demanded_keys)}), ml_unknowns({len(unknown)}), "
        f"baseline_unknowns({len(baseline_unknown)}), "
        f"math_terms({len(term_specs)}), question_records({EXPECTED_QUESTION_RECORDS}), "
        f"dataset_records({EXPECTED_DATASET_RECORDS}), "
        f"token_occurrences(question_corpus({q_occ}), dataset({d_occ})))"
    )
    lines.extend(
        [
            "",
            f"math_lexicon_pilot_summary({summary}).",
            f"ml_expected_counts({len(demanded_keys)}, {len(unknown)}, {len(baseline_unknown)}, {len(term_specs)}).",
            "",
            "check_math_lexicon_pilot :-",
            "    ml_expected_counts(ExpectedWords, ExpectedUnknowns, ExpectedBaseline, ExpectedTerms),",
            "    aggregate_all(count, ml_word(_, _, _, _), ExpectedWords),",
            "    aggregate_all(count, ml_unknown(_, _), ExpectedUnknowns),",
            "    aggregate_all(count, ml_baseline_unknown(_, _), ExpectedBaseline),",
            "    aggregate_all(count, ml_source_term(questioning_paper_lexicon, _, _), ExpectedTerms),",
            "    forall(ml_baseline_unknown(Word, _), em_word_class(Word, _)),",
            "    forall(ml_word(Base, Category, forms(Forms), _),",
            "           forall(member(Form, Forms), morphology_receipt(Base, Category, Form))),",
            "    forall(ml_source_term(questioning_paper_lexicon, _, tokens(Tokens)),",
            "           forall(member(Token, Tokens), absorbed_questioning_token(Token))),",
            "    writeln('math_lexicon_pilot: all receipts passed').",
            "",
            "morphology_receipt(Base, noun, Form) :- em_noun_base(Form, Base), !.",
            "morphology_receipt(Base, verb, Form) :- em_verb_base(Form, Base, _), !.",
            "morphology_receipt(Base, adjective, Form) :- em_adjective_base(Form, Base, _), !.",
            "morphology_receipt(Base, domain, Form) :- Base == Form, em_math_domain(Form), !.",
            "morphology_receipt(Base, Category, Form) :-",
            "    memberchk(Category, [adverb, preposition, pronoun, conjunction, interjection]),",
            "    Base == Form, em_category(Form, Category), !.",
            "morphology_receipt(Base, Category, Form) :-",
            "    Base == Form, em_word_class(Form, Category), !.",
            "morphology_receipt(Base, Category, Form) :-",
            "    format(user_error, 'unresolved morphology: ~q ~q ~q~n', [Base, Category, Form]),",
            "    fail.",
            "",
            "absorbed_questioning_token(Token) :-",
            "    ml_word(_, _, forms(Forms), demand(Demand)),",
            "    memberchk(questioning_paper_lexicon, Demand), memberchk(Token, Forms), !.",
            "absorbed_questioning_token(Token) :- ml_unknown(Token, _), !.",
            "",
        ]
    )
    content = "\n".join(lines).encode("utf-8")
    metadata = {
        "math_terms": len(term_specs),
        "ml_words": len(demanded_keys),
        "ml_unknowns": len(unknown),
        "question_occurrences": q_occ,
        "dataset_occurrences": d_occ,
        "baseline_unknown_occurrences": sum(baseline_unknown.values()),
        "unknown_occurrences": sum(unknown.values()),
        "remaining_unknowns": sorted(unknown.items()),
        "top_unknowns": sorted(unknown.items(), key=lambda item: (-item[1], item[0]))[:30],
        "sha256": hashlib.sha256(content).hexdigest(),
    }
    return content, metadata


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--no-pin", action="store_true", help="bootstrap measured count and sha pins")
    args = parser.parse_args()
    content, metadata = render(args.no_pin)
    if not args.no_pin and metadata["sha256"] != EXPECTED_OUTPUT_SHA256:
        raise SystemExit(
            f"output sha256 changed: measured {metadata['sha256']}, expected {EXPECTED_OUTPUT_SHA256}"
        )
    OUTPUT.write_bytes(content)
    print(json.dumps(metadata, ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
