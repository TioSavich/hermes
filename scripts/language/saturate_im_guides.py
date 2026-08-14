#!/usr/bin/env python3
"""Measure Webster and supplement coverage over the IM teacher-guide tree.

The measurement reuses the language lane's SWI-Prolog ``tokenize_atom/2``
helper.  It records lexical coverage only; it does not parse lesson sentences
or infer meanings for unknown words.
"""

from __future__ import annotations

import hashlib
import json
from collections import Counter, defaultdict
from pathlib import Path

from build_math_lexicon import (
    REPO,
    SUPPLEMENT,
    extend_with_supplement,
    load_supplement,
    load_webster,
    swipl_tokens,
)


GUIDES = REPO / "curriculum/im_teacher_guides"
OUTPUT = REPO / "hermes/app/runtime/experiments/language/im_guide_saturation.json"
PASS = "guide_saturation_2"
CONTEXT_WORDS = 8
CONTEXT_LIMIT = 3
TOKENIZE_BATCH_LINES = 4_000


def file_sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def lexical(token: object) -> bool:
    return isinstance(token, str) and any(character.isalpha() for character in token)


def guide_paths() -> list[Path]:
    """Return markdown files beneath grade directories in stable order."""
    return sorted(
        path
        for path in GUIDES.glob("*/*.md")
        if path.parent.parent == GUIDES
    ) + sorted(
        path
        for path in GUIDES.glob("*/*/*.md")
        if path.parents[2] == GUIDES
    )


def tree_sha(paths: list[Path]) -> str:
    digest = hashlib.sha256()
    for path in paths:
        relative = path.relative_to(REPO).as_posix().encode("utf-8")
        content = path.read_bytes()
        digest.update(len(relative).to_bytes(4, "big"))
        digest.update(relative)
        digest.update(len(content).to_bytes(8, "big"))
        digest.update(content)
    return digest.hexdigest()


def context_window(words: list[str], index: int) -> str:
    start = max(0, index - CONTEXT_WORDS // 2)
    end = min(len(words), start + CONTEXT_WORDS)
    start = max(0, end - CONTEXT_WORDS)
    return " ".join(words[start:end])


def counts_receipt(counts: Counter[str]) -> dict[str, int | float]:
    lexical_count = counts["lexical_tokens"]
    known_count = counts["known_tokens"]
    return {
        "guides": counts["guides"],
        "lines": counts["lines"],
        "tokens": counts["tokens"],
        "lexical_tokens": lexical_count,
        "webster_known_tokens": counts["webster_known_tokens"],
        "supplement_known_tokens": counts["supplement_known_tokens"],
        "known_tokens": known_count,
        "unknown_tokens": counts["unknown_tokens"],
        "coverage_share": round(known_count / lexical_count, 12) if lexical_count else 1.0,
    }


def main() -> int:
    paths = guide_paths()
    if not paths:
        raise SystemExit(f"no grade markdown files found beneath {GUIDES}")
    duplicates = [path for path, count in Counter(paths).items() if count != 1]
    if duplicates:
        raise ValueError(f"duplicate guide paths: {duplicates}")

    _forms, webster_map, _domains = load_webster()
    webster = set(webster_map)
    supplement_rows = load_supplement()
    supplement_forms: dict[tuple[str, str], set[str]] = defaultdict(set)
    supplement_map: dict[str, set[tuple[str, str]]] = defaultdict(set)
    extend_with_supplement(supplement_forms, supplement_map, supplement_rows)
    supplement = set(supplement_map)

    per_grade: dict[str, Counter[str]] = defaultdict(Counter)
    total: Counter[str] = Counter()
    unknowns: Counter[str] = Counter()
    samples: dict[str, list[dict[str, object]]] = defaultdict(list)

    line_records: list[tuple[Path, int, str]] = []
    for path in paths:
        grade = path.relative_to(GUIDES).parts[0]
        text = path.read_text(encoding="utf-8")
        lines = text.splitlines()
        grade_counts = per_grade[grade]
        grade_counts["guides"] += 1
        grade_counts["lines"] += len(lines)
        total["guides"] += 1
        total["lines"] += len(lines)
        line_records.extend(
            (path, line_number, line) for line_number, line in enumerate(lines, 1)
        )

    for offset in range(0, len(line_records), TOKENIZE_BATCH_LINES):
        batch = line_records[offset : offset + TOKENIZE_BATCH_LINES]
        token_rows = swipl_tokens([line for _path, _line_number, line in batch])
        for (path, line_number, _line), tokens in zip(batch, token_rows, strict=True):
            grade = path.relative_to(GUIDES).parts[0]
            grade_counts = per_grade[grade]
            grade_counts["tokens"] += len(tokens)
            total["tokens"] += len(tokens)
            words = [str(token).lower() for token in tokens if lexical(token)]
            grade_counts["lexical_tokens"] += len(words)
            total["lexical_tokens"] += len(words)
            relative = path.relative_to(REPO).as_posix()
            for index, word in enumerate(words):
                if word in webster:
                    source = "webster_known_tokens"
                elif word in supplement:
                    source = "supplement_known_tokens"
                else:
                    grade_counts["unknown_tokens"] += 1
                    total["unknown_tokens"] += 1
                    unknowns[word] += 1
                    sample = {
                        "guide": relative,
                        "line": line_number,
                        "window": context_window(words, index),
                    }
                    if len(samples[word]) < CONTEXT_LIMIT and sample not in samples[word]:
                        samples[word].append(sample)
                    continue
                grade_counts[source] += 1
                grade_counts["known_tokens"] += 1
                total[source] += 1
                total["known_tokens"] += 1

    grade_order = sorted(per_grade, key=lambda grade: (grade != "kindergarten", grade))
    ranked_unknowns = [
        {"word": word, "occurrences": count, "samples": samples[word]}
        for word, count in sorted(unknowns.items(), key=lambda item: (-item[1], item[0]))
    ]
    receipt = {
        "role": "dictionary_coverage_measurement_not_sentence_parsing",
        "pass": PASS,
        "corpus": "curriculum/im_teacher_guides grade directories",
        "boundary": {
            "included_markdown_files": len(paths),
            "excluded_root_markdown_files": sorted(
                path.relative_to(REPO).as_posix() for path in GUIDES.glob("*.md")
            ),
        },
        "source_sha256": {
            "guide_tree": tree_sha(paths),
            "lexicon_supplement_pilot.pl": file_sha(SUPPLEMENT),
        },
        "grades": {
            grade: counts_receipt(per_grade[grade]) for grade in grade_order
        },
        "total": counts_receipt(total),
        "unknown_census": {
            "distinct_words": len(unknowns),
            "occurrences": sum(unknowns.values()),
            "words_with_2_or_more_occurrences": sum(
                1 for count in unknowns.values() if count >= 2
            ),
            "singleton_words": sum(1 for count in unknowns.values() if count == 1),
            "ranked": ranked_unknowns,
        },
    }
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(
        json.dumps(receipt, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(
        json.dumps(
            {
                "guides": total["guides"],
                "lexical_tokens": total["lexical_tokens"],
                "known_tokens": total["known_tokens"],
                "unknown_occurrences": sum(unknowns.values()),
                "unknown_words": len(unknowns),
                "repeated_unknown_words": receipt["unknown_census"][
                    "words_with_2_or_more_occurrences"
                ],
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
