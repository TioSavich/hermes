#!/usr/bin/env python3
"""Build and check the closed two-pass IM-guide saturation ledger."""

from __future__ import annotations

import hashlib
import json
from collections import Counter
from pathlib import Path

from build_math_lexicon import REPO, SUPPLEMENT, load_supplement


CENSUS = REPO / "hermes/app/runtime/experiments/language/im_guide_saturation.json"
OUTPUT = REPO / ".superpowers/sdd/language-lane/saturation_ledger.json"
PASS_1 = "guide_saturation_1"
PASS_2 = "guide_saturation_2"

BEFORE = {
    "distinct_unknown_words": 1_194,
    "unknown_occurrences": 222_078,
    "words_with_2_or_more_occurrences": 666,
    "singleton_words": 528,
    "lexical_tokens": 1_779_880,
    "known_tokens": 1_557_802,
}

PASS_1_AFTER = {
    "distinct_lexically_unresolved_words": 529,
    "lexically_unresolved_occurrences": 11_200,
    "distinct_undispositioned_words": 499,
    "undispositioned_occurrences": 499,
    "lexical_tokens": 1_779_880,
    "known_tokens": 1_768_680,
    "coverage_share": 0.993707440951,
}

# These repeated guide unknowns already had explicit slice-2 refusal rows.
PREEXISTING_REPEATED = {
    "didn": 175,
    "doesn": 246,
    "hadn": 3,
    "ll": 121,
    "nd": 51,
    "rd": 54,
    "re": 177,
    "st": 63,
    "th": 115,
    "ve": 167,
    "wasn": 31,
    "weren": 20,
}


def file_sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def ranked(rows: dict[str, int]) -> list[dict[str, int | str]]:
    return [
        {"word": word, "occurrences": count}
        for word, count in sorted(rows.items(), key=lambda item: (-item[1], item[0]))
    ]


def main() -> int:
    census = json.loads(CENSUS.read_text(encoding="utf-8"))
    if census.get("pass") != PASS_2:
        raise ValueError(f"expected a pass-2 census, found {census.get('pass')!r}")

    supplement = load_supplement()
    supplement_words = {str(row["word"]) for row in supplement["words"]}
    pass_1_rows = {
        str(row["word"]): int(row["occurrences"])
        for row in supplement["words"]
        if row["pass"] == PASS_1
    }
    pass_2_rows = {
        str(row["word"]): int(row["occurrences"])
        for row in supplement["words"]
        if row["pass"] == PASS_2
    }
    if len(pass_1_rows) != 654 or sum(pass_1_rows.values()) != 220_327:
        raise ValueError("pass-1 authored dispositions drifted")
    if len(pass_2_rows) != 499 or set(pass_2_rows.values()) != {1}:
        raise ValueError(
            f"pass-2 frontier drifted: rows={len(pass_2_rows)}, occurrences={sum(pass_2_rows.values())}"
        )
    if set(pass_1_rows) & set(pass_2_rows):
        raise ValueError("pass-1 and pass-2 dispositions overlap")

    unresolved = {
        str(row["word"]): int(row["occurrences"])
        for row in census["unknown_census"]["ranked"]
    }
    undispositioned = {
        word: count for word, count in unresolved.items() if word not in supplement_words
    }
    if undispositioned:
        raise ValueError(f"closed ledger has undispositioned words: {ranked(undispositioned)}")

    total = census["total"]
    after = {
        "distinct_lexically_unresolved_words": census["unknown_census"]["distinct_words"],
        "lexically_unresolved_occurrences": census["unknown_census"]["occurrences"],
        "distinct_undispositioned_words": 0,
        "undispositioned_occurrences": 0,
        "lexical_tokens": total["lexical_tokens"],
        "known_tokens": total["known_tokens"],
        "coverage_share": total["coverage_share"],
    }
    pass_2_classes = Counter(
        str(row["class"])
        for row in supplement["words"]
        if row["pass"] == PASS_2
    )
    pass_2_list = ranked(pass_2_rows)
    unresolved_but_dispositioned = ranked(unresolved)

    ledger = {
        "pass": 2,
        "evidence_pass": PASS_2,
        "state": "closed",
        "ordering": "frequency_descending_then_alphabetical",
        "before": {
            **BEFORE,
            "coverage_share": round(BEFORE["known_tokens"] / BEFORE["lexical_tokens"], 12),
        },
        "passes": [
            {
                "pass": 1,
                "evidence_pass": PASS_1,
                "authored_words": len(pass_1_rows),
                "preexisting_repeated_dispositions": len(PREEXISTING_REPEATED),
                "total_words_dispositioned": len(pass_1_rows) + len(PREEXISTING_REPEATED),
                "remaining_frontier_size": 499,
                "words": ranked(pass_1_rows),
                "after": PASS_1_AFTER,
            },
            {
                "pass": 2,
                "evidence_pass": PASS_2,
                "words_dispositioned": len(pass_2_rows),
                "occurrences_dispositioned": sum(pass_2_rows.values()),
                "class_counts": dict(sorted(pass_2_classes.items())),
                "remaining_frontier_size": 0,
                "words": pass_2_list,
                "after": after,
            },
        ],
        "words_dispositioned_this_pass_count": len(pass_2_rows),
        "words_dispositioned_this_pass": pass_2_list,
        "repeated_unknown_completion": {
            "baseline_words": BEFORE["words_with_2_or_more_occurrences"],
            "dispositioned_words": len(pass_1_rows) + len(PREEXISTING_REPEATED),
            "undispositioned_words": 0,
        },
        "singleton_frontier_completion": {
            "baseline_words": len(pass_2_rows),
            "dispositioned_words": len(pass_2_rows),
            "undispositioned_words": 0,
        },
        "after": after,
        "remaining_census_size": 0,
        "remaining_census_occurrences": 0,
        "exact_next_up_head": [],
        "new_undispositioned_words_after_remeasurement": [],
        "lexically_unresolved_but_dispositioned": unresolved_but_dispositioned,
        "source_sha256": {
            "im_guide_saturation.json": file_sha(CENSUS),
            "lexicon_supplement_pilot.pl": file_sha(SUPPLEMENT),
        },
    }
    OUTPUT.write_text(
        json.dumps(ledger, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(
        json.dumps(
            {
                "pass": 2,
                "state": "closed",
                "dispositioned_this_pass": len(pass_2_rows),
                "remaining_census_size": 0,
                "lexically_unresolved_but_dispositioned": len(unresolved),
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
