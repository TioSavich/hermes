#!/usr/bin/env python3
"""Measure tokenizer, lexicon, and narrow-reader coverage on fixed corpus rows.

This probe does not call a model, produce answers, or compare with targets.
It writes a deterministic JSON receipt for the supplement report.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
from collections import Counter, defaultdict
from pathlib import Path
from typing import Match

from build_math_lexicon import (
    DATASET,
    QUESTION_CORPUS,
    REPO,
    SUPPLEMENT,
    extend_with_supplement,
    load_supplement,
    load_webster,
    swipl_tokens,
)


OUTPUT = REPO / "hermes/app/runtime/experiments/language/reader_coverage_probe.json"
APE_OUTPUT = REPO / "hermes/app/runtime/experiments/language/reader_coverage_probe_ape.json"
MATH_LEXICON = REPO / "knowledge/strategies/abstraction/math_lexicon_pilot.pl"
READER = REPO / "knowledge/strategies/abstraction/word_problem_reader_pilot.pl"
APE_READER = REPO / "knowledge/strategies/abstraction/ape_reader_pilot.pl"
APE_LEXICON = REPO / "hermes/app/runtime/experiments/language/ape_user_lexicon.pl"
DATASET_ITEMS = [0, 22, 246, 1250, 1224]
IM_ITEMS = [56, 510, 985, 1795, 2562]
ITEM_MARKER = re.compile(r"(?<!\S)(?P<label>\d{1,2}|[a-z])\.(?=\s)")


def file_sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def lexical(token: object) -> bool:
    return isinstance(token, str) and any(character.isalpha() for character in token)


def math_lexicon_surfaces() -> set[str]:
    surfaces: set[str] = set()
    for line in MATH_LEXICON.read_text(encoding="utf-8").splitlines():
        if not line.startswith("ml_word(") or "forms([" not in line:
            continue
        encoded = line.split("forms([", 1)[1].split("]), demand", 1)[0]
        for match in re.finditer(r"'((?:''|[^'])*)'", encoded):
            surfaces.add(match.group(1).replace("''", "'"))
    return surfaces


def known_surfaces() -> tuple[set[str], set[str], set[str]]:
    _forms, webster_map, _domains = load_webster()
    webster = set(webster_map)
    supplement = load_supplement()
    supplement_forms: dict[tuple[str, str], set[str]] = defaultdict(set)
    supplement_map: dict[str, set[tuple[str, str]]] = defaultdict(set)
    extend_with_supplement(supplement_forms, supplement_map, supplement)
    supplement_known = set(supplement_map)
    math_known = math_lexicon_surfaces()
    return webster, supplement_known, math_known


def _marker_value(label: str) -> tuple[str, int]:
    if label.isdigit():
        return "numeric", int(label)
    return "alphabetic", ord(label)


def _expression_run_fragment(text: str) -> bool:
    return (
        bool(re.search(r"\d", text))
        and bool(re.search(r"[+\-=×÷*/]", text))
        and not bool(re.search(r"[A-Za-z]", text))
    )


def _item_segments(text: str) -> list[str]:
    """Split before item markers and remove the marker from reader input.

    Ascending markers embedded in arithmetic runs carry the only boundary in
    the flattened corpus. Markers that terminal punctuation already isolates
    are left to the ordinary splitter, preserving prose-list context.
    """
    candidates = list(ITEM_MARKER.finditer(text))
    selected_indexes: set[int] = set()
    by_kind: dict[str, list[tuple[int, Match[str], int]]] = defaultdict(list)
    for index, candidate in enumerate(candidates):
        kind, value = _marker_value(candidate.group("label"))
        by_kind[kind].append((index, candidate, value))
    for same_kind in by_kind.values():
        for (left_index, left, left_value), (
            right_index,
            right,
            right_value,
        ) in zip(same_kind, same_kind[1:]):
            fragment = ITEM_MARKER.sub(" ", text[left.end():right.start()])
            if right_value == left_value + 1 and _expression_run_fragment(fragment):
                selected_indexes.update((left_index, right_index))

    selected = [
        candidate for index, candidate in enumerate(candidates) if index in selected_indexes
    ]

    if not selected:
        return [text]
    segments: list[str] = []
    cursor = 0
    for marker in selected:
        prefix = text[cursor:marker.start()].strip()
        if prefix:
            segments.append(prefix)
        cursor = marker.end()
    suffix = text[cursor:].strip()
    if suffix:
        segments.append(suffix)
    return segments


def sentences(text: str) -> list[str]:
    """Split item lists, line ends, and terminal punctuation."""
    result: list[str] = []
    for item in _item_segments(text):
        current: list[str] = []
        for index, character in enumerate(item):
            current.append(character)
            prior_digit = index > 0 and item[index - 1].isdigit()
            next_digit = index + 1 < len(item) and item[index + 1].isdigit()
            terminal = character in "!?" or (
                character == "." and not (prior_digit and next_digit)
            )
            if character == "\n" or terminal:
                sentence = "".join(current).strip()
                if sentence:
                    result.append(sentence)
                current = []
        sentence = "".join(current).strip()
        if sentence:
            result.append(sentence)
    return result


def check_sentence_segmentation() -> None:
    assert sentences("1. 15 - 10 = 2. = 13 - 3") == [
        "15 - 10 =",
        "= 13 - 3",
    ]
    assert sentences("1. 7 + 1 2. 9 - 2") == ["7 + 1", "9 - 2"]
    assert sentences("a. 4 + 5 b. 6 + 7") == ["4 + 5", "6 + 7"]
    assert sentences("There are 3. Students solve the next task.") == [
        "There are 3.",
        "Students solve the next task.",
    ]
    assert sentences("The measured value is 12. Next, compare it.") == [
        "The measured value is 12.",
        "Next, compare it.",
    ]
    assert sentences("1. There are 2. Students solve the next task.") == [
        "1.",
        "There are 2.",
        "Students solve the next task.",
    ]
    print("sentence_segmentation: marker receipts passed")


def parse_flags(all_sentences: list[str]) -> list[bool]:
    reader_atom = "'" + str(READER).replace("'", "''") + "'"
    goal = (
        "use_module(library(http/json)),"
        f"load_files({reader_atom},[silent(true)]),"
        "json_read(user_input,Sentences),"
        "findall(B,(member(S,Sentences),"
        "(word_problem_reader_pilot:word_problem_facts(S,_)->B=true;B=false)),Flags),"
        "json_write(user_output,Flags)"
    )
    result = subprocess.run(
        ["swipl", "-q", "-g", goal, "-t", "halt"],
        input=json.dumps(all_sentences, ensure_ascii=False),
        text=True,
        capture_output=True,
        check=True,
    )
    return [flag is True or flag == "true" for flag in json.loads(result.stdout)]


def union_verdicts(all_sentences: list[str]) -> list[dict[str, object]]:
    reader_atom = "'" + str(READER).replace("'", "''") + "'"
    ape_atom = "'" + str(APE_READER).replace("'", "''") + "'"
    goal = (
        "use_module(library(http/json)),use_module(library(porter_stem)),"
        f"load_files({reader_atom},[silent(true)]),"
        f"load_files({ape_atom},[silent(true)]),"
        "json_read(user_input,Sentences),findall(Row,(member(S,Sentences),"
        "(word_problem_reader_pilot:word_problem_facts(S,Facts)"
        "->maplist(term_string,Facts,FactStrings),"
        "Row=_{parsed:true,reader:incumbent,facts:FactStrings,fact_spans:[],"
        "rewrite_rules:[],refusals:_{}};"
        "string_lower(S,Lower),tokenize_atom(Lower,Tokens),"
        "(Tokens=[Entry|_]->term_string(Entry,EntryToken);EntryToken=\"\"),"
        "ape_reader_pilot:ape_reader_result(S,ApeResult),"
        "(ApeResult=parsed(ApeFacts,ApeSpans,Rules)"
        "->maplist(term_string,ApeFacts,ApeFactStrings),"
        "findall(_{fact_index:I,start:Start,end:End,text:Text},"
        "member(fact_span(I,Start,End,Text),ApeSpans),SpanRows),"
        "maplist(term_string,Rules,RuleStrings),"
        "Row=_{parsed:true,reader:ape,facts:ApeFactStrings,fact_spans:SpanRows,"
        "rewrite_rules:RuleStrings,refusals:_{incumbent:_{token:EntryToken,"
        "token_basis:sentence_entry_no_failure_api}}};"
        "ApeResult=refusal(Token,span(Start,End,Surface),Reason,Rules),"
        "term_string(Reason,ReasonString),maplist(term_string,Rules,RuleStrings),"
        "Row=_{parsed:false,reader:both_refused,facts:[],fact_spans:[],"
        "rewrite_rules:RuleStrings,refusals:_{incumbent:_{token:EntryToken,"
        "token_basis:sentence_entry_no_failure_api},ape:_{token:Token,start:Start,"
        "end:End,text:Surface,reason:ReasonString}}}))),Rows),"
        "json_write_dict(user_output,Rows,[width(0)])"
    )
    result = subprocess.run(
        ["swipl", "-q", "-g", goal, "-t", "halt"],
        input=json.dumps(all_sentences, ensure_ascii=False),
        text=True,
        capture_output=True,
        check=True,
    )
    return json.loads(result.stdout)


def selected_texts() -> list[dict[str, object]]:
    dataset = json.loads(DATASET.read_text(encoding="utf-8"))
    questions = [
        json.loads(line)
        for line in QUESTION_CORPUS.read_text(encoding="utf-8").splitlines()
    ]
    records: list[dict[str, object]] = []
    for index in DATASET_ITEMS:
        row = dataset[index]
        if int(row["index"]) != index:
            raise ValueError(f"dataset index drift at {index}")
        for field in ["question", "solution"]:
            records.append(
                {
                    "id": f"dataset_{index}_{field}",
                    "source": "mistake_location_full",
                    "item": index,
                    "field": field,
                    "text": str(row[field]).replace("\\n", "\n"),
                }
            )
    for index in IM_ITEMS:
        row = questions[index]
        if int(row["record_index"]) != index:
            raise ValueError(f"IM record index drift at {index}")
        records.append(
            {
                "id": f"im_{index}",
                "source": "im_question_records",
                "item": index,
                "field": "text",
                "lesson": row["lesson"],
                "text": str(row["text"]),
            }
        )
    return records


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--second-reader", choices=["ape"])
    parser.add_argument("--check", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.check:
        check_sentence_segmentation()
        return 0
    webster, supplement, math_lexicon = known_surfaces()
    records = selected_texts()
    token_rows = swipl_tokens([str(record["text"]) for record in records])
    sentence_rows = [sentences(str(record["text"])) for record in records]
    flat_sentences = [sentence for row in sentence_rows for sentence in row]
    verdicts = iter(union_verdicts(flat_sentences)) if args.second_reader == "ape" else None
    flags = iter(parse_flags(flat_sentences)) if verdicts is None else None

    totals = Counter()
    output_rows: list[dict[str, object]] = []
    for record, tokens, row_sentences in zip(records, token_rows, sentence_rows):
        known_counts = Counter()
        known_words: dict[str, set[str]] = defaultdict(set)
        unknown_counts = Counter()
        for token in tokens:
            if not lexical(token):
                continue
            word = str(token).lower()
            if word in webster:
                source = "webster"
            elif word in supplement:
                source = "supplement"
            elif word in math_lexicon:
                source = "math_lexicon"
            else:
                unknown_counts[word] += 1
                continue
            known_counts[source] += 1
            known_words[source].add(word)

        if verdicts is not None:
            sentence_receipts = [
                {"text": sentence, **next(verdicts)} for sentence in row_sentences
            ]
        else:
            assert flags is not None
            sentence_receipts = [
                {"text": sentence, "parsed": next(flags)} for sentence in row_sentences
            ]
        lexical_count = sum(1 for token in tokens if lexical(token))
        known_count = sum(known_counts.values())
        totals["texts"] += 1
        totals["tokens"] += len(tokens)
        totals["lexical_tokens"] += lexical_count
        totals["known_tokens"] += known_count
        totals["unknown_tokens"] += sum(unknown_counts.values())
        totals["sentences"] += len(sentence_receipts)
        totals["parsed_sentences"] += sum(row["parsed"] for row in sentence_receipts)
        if args.second_reader == "ape":
            for sentence_receipt in sentence_receipts:
                totals[f"{sentence_receipt['reader']}_sentences"] += 1

        output_rows.append(
            {
                **record,
                "token_count": len(tokens),
                "lexical_token_count": lexical_count,
                "known_token_count": known_count,
                "known_by_source": dict(sorted(known_counts.items())),
                "known_tokens_by_source": {
                    source: sorted(words) for source, words in sorted(known_words.items())
                },
                "unknown_tokens": dict(sorted(unknown_counts.items())),
                "sentences": sentence_receipts,
            }
        )

    source_sha = {
        "mistake_location_full.json": file_sha(DATASET),
        "question_records.jsonl": file_sha(QUESTION_CORPUS),
        "math_lexicon_pilot.pl": file_sha(MATH_LEXICON),
        "lexicon_supplement_pilot.pl": file_sha(SUPPLEMENT),
    }
    if args.second_reader == "ape":
        source_sha.update(
            {
                "ape_reader_pilot.pl": file_sha(APE_READER),
                "ape_user_lexicon.pl": file_sha(APE_LEXICON),
            }
        )
    receipt = {
        "role": "coverage_probe_not_training_or_scoring",
        "second_reader": args.second_reader,
        "dataset_items": DATASET_ITEMS,
        "im_items": IM_ITEMS,
        "source_sha256": source_sha,
        "totals": dict(sorted(totals.items())),
        "texts": output_rows,
    }
    selected_output = args.output or (APE_OUTPUT if args.second_reader == "ape" else OUTPUT)
    output = selected_output if selected_output.is_absolute() else REPO / selected_output
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(
        json.dumps(receipt, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(receipt["totals"], sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
