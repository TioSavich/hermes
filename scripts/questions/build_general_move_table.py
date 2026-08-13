#!/usr/bin/env python3
"""The general-move table, and the measurement that fixes its threshold.

F-Q1 in the design: a move licensed at more than a threshold share of states
carries no pattern signal, and counting it as pattern structure would repeat
the fact-extraction pilot's gate failure. Two populations reach this table.

The first is mechanical and needs no model: a sentence with no numeral, no
number word, no operation word, and no quantity-representation word cannot
name a region of input space, whatever else it is worth in a classroom.

The second is measured: among links the engine verified, a question wording
that turns up at many distinct states is licensed too broadly to be structure.
The share is reported so the threshold is fixed by the corpus rather than
asserted.
"""
from __future__ import annotations

import argparse
import collections
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from linker import RUNTIME  # noqa: E402
from question_corpus import build_sentences, load_records, mineable  # noqa: E402

TABLE = RUNTIME / "general_moves.jsonl"
REPORT = RUNTIME / "general_moves_report.json"
WORKING_LINE = 0.20


def normalize(text: str) -> str:
    text = re.sub(r"(?<![A-Za-z0-9])\d+(?:[.,]\d+)?(?![A-Za-z0-9])", "#", text.casefold())
    return " ".join(text.split()).strip(" ?.!")


def load_links() -> list[dict]:
    links: list[dict] = []
    for name in ("baseline_links.jsonl", "glm_pilot_links.jsonl", "glm_scale_links.jsonl"):
        path = RUNTIME / name
        if path.is_file():
            for line in path.read_text(encoding="utf-8").splitlines():
                if line.strip():
                    links.append(json.loads(line))
    return links


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.parse_args()

    records = load_records()
    sentences, prefiltered = build_sentences(records)
    links = load_links()

    states = {
        (link["pattern_ids"][0], "undetermined" if link["move_type"] == "assessing" else "productive")
        for link in links
    }
    breadth: dict[str, set] = collections.defaultdict(set)
    wording_rows: dict[str, list[dict]] = collections.defaultdict(list)
    for link in links:
        key = normalize(link["text"])
        state = (link["pattern_ids"][0],
                 "undetermined" if link["move_type"] == "assessing" else "productive")
        breadth[key].add(state)
        wording_rows[key].append(link)

    threshold_states = max(2, round(WORKING_LINE * len(states))) if states else 2
    too_broad = {key for key, seen in breadth.items() if len(seen) >= threshold_states}

    rows: list[dict] = []
    for sentence in sentences:
        if sentence.peer_work or mineable(sentence):
            continue
        rows.append({
            "identity": sentence.identity,
            "lesson": sentence.lesson,
            "grade": sentence.grade,
            "text": sentence.text,
            "label": sentence.record_type,
            "review_status": sentence.review_status,
            "activity_location": sentence.activity_location,
            "basis": "no_numeral_no_operation_no_representation_word",
            "source_span": [sentence.span_start, sentence.span_end],
            "sentence_index": sentence.sentence_index,
        })
    for key in sorted(too_broad):
        example = wording_rows[key][0]
        rows.append({
            "identity": example["identity"],
            "lesson": example["lesson"],
            "grade": example["grade"],
            "text": example["text"],
            "label": example["record_type"],
            "review_status": example["review_status"],
            "activity_location": example["activity_location"],
            "basis": "licensed_at_many_states",
            "wording": key,
            "states_licensed_at": len(breadth[key]),
            "occurrences": len(wording_rows[key]),
            "source_span": [example["span_start"], example["span_end"]],
            "sentence_index": example["sentence_index"],
        })

    TABLE.write_text(
        "".join(json.dumps(row, ensure_ascii=False, sort_keys=True) + "\n" for row in rows),
        encoding="utf-8")

    distribution = collections.Counter(len(seen) for seen in breadth.values())
    report = {
        "prefilter_exclusions": prefiltered,
        "sentences": len(sentences),
        "mechanical_general_moves": sum(1 for row in rows if row["basis"].startswith("no_numeral")),
        "verified_links_read": len(links),
        "distinct_states_in_verified_links": len(states),
        "distinct_wordings": len(breadth),
        "working_line": WORKING_LINE,
        "states_threshold": threshold_states,
        "wordings_over_the_threshold": len(too_broad),
        "states_per_wording": {str(key): value for key, value in sorted(distribution.items())},
        "widest_wordings": [
            {"wording": key, "states": len(breadth[key]), "occurrences": len(wording_rows[key])}
            for key in sorted(breadth, key=lambda item: -len(breadth[item]))[:10]
        ],
        "table": str(TABLE),
        "rows": len(rows),
    }
    REPORT.write_text(json.dumps(report, indent=1, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=1, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
