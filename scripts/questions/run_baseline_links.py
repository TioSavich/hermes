#!/usr/bin/env python3
"""The mechanical floor: keyword links, verified by the same three checks.

No mined yield is worth quoting without this number beside it. If glm-5.2
cannot beat what operation words and numerals already reach, the mining added
nothing and that is the finding.
"""
from __future__ import annotations

import argparse
import collections
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from linker import (  # noqa: E402
    RUNTIME, TraceRunner, load_menu, load_patterns, load_row_map,
    lesson_pattern_numbers, propose_baseline, sorts_by_asymmetry, verify,
)
from question_corpus import build_sentences, load_records, mineable  # noqa: E402

LINKS = RUNTIME / "baseline_links.jsonl"
QUARANTINE = RUNTIME / "baseline_quarantine.jsonl"
REPORT = RUNTIME / "baseline_report.json"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--limit", type=int, default=0)
    arguments = parser.parse_args()

    records = load_records()
    sentences, prefiltered = build_sentences(records)
    patterns = load_patterns()
    menu = load_menu()
    numbers = lesson_pattern_numbers(load_row_map(), patterns)

    lessons_with_patterns = set(patterns["lesson_patterns"])
    census = collections.Counter()
    candidates = []
    for sentence in sentences:
        if sentence.peer_work:
            census["requires_peer_work"] += 1
            continue
        if not mineable(sentence):
            census["general_move_candidate"] += 1
            continue
        if sentence.lesson not in lessons_with_patterns:
            census["lesson_without_patterns"] += 1
            continue
        census["mineable_in_mapped_lesson"] += 1
        candidates.append(sentence)
    if arguments.limit:
        candidates = candidates[: arguments.limit]

    runner = TraceRunner()
    verified_rows: list[dict] = []
    quarantined: list[dict] = []
    failures = collections.Counter()
    proposals = 0
    no_proposal = 0
    try:
        for sentence in candidates:
            links = propose_baseline(sentence, patterns, menu, numbers)
            if not links:
                no_proposal += 1
                continue
            for link in links:
                proposals += 1
                outcome = verify(link, sentence, patterns, numbers, runner)
                row = {**sentence.to_dict(), **link, "verification": outcome}
                if outcome["verified"]:
                    verified_rows.append(row)
                else:
                    quarantined.append(row)
                    for name in outcome["failed"]:
                        failures[name] += 1
    finally:
        runner.close()

    LINKS.write_text(
        "".join(json.dumps(row, ensure_ascii=False, sort_keys=True) + "\n" for row in verified_rows),
        encoding="utf-8")
    QUARANTINE.write_text(
        "".join(json.dumps(row, ensure_ascii=False, sort_keys=True) + "\n" for row in quarantined),
        encoding="utf-8")

    sorted_rows = sum(1 for row in verified_rows if sorts_by_asymmetry(row))
    report = {
        "records": len(records),
        "prefilter_exclusions": prefiltered,
        "sentences": len(sentences),
        "routing": dict(census),
        "proposals": proposals,
        "candidates_without_a_proposal": no_proposal,
        "verified": len(verified_rows),
        "quarantined": len(quarantined),
        "failed_check_counts": dict(failures),
        "verified_by_move_type": dict(collections.Counter(row["move_type"] for row in verified_rows)),
        "verified_by_effect": dict(collections.Counter(row["effect"]["kind"] for row in verified_rows)),
        "verified_by_grade": dict(collections.Counter(row["grade"] for row in verified_rows)),
        "sorts_by_asymmetry": sorted_rows,
        "asymmetry_share": round(sorted_rows / len(verified_rows), 4) if verified_rows else None,
        "links_path": str(LINKS),
        "quarantine_path": str(QUARANTINE),
    }
    REPORT.write_text(json.dumps(report, indent=1, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=1, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
