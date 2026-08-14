#!/usr/bin/env python3
"""Turn a model's structural read of a lesson into candidate task rows.

The structure pass names each region of a lesson guide and copies out, for each
student task statement, the printed expressions and the ask verbatim.  That
testimony is worthless until it is anchored to bytes on disk, so this script
anchors it: every printed expression and every ask must be found verbatim in
the lesson file, and the row it produces carries the path, the line, the byte
range, and the file's SHA-256.

What the model says and cannot be found in the file is dropped and counted.
Nothing here decides an answer; a candidate row is a question with provenance,
which is what the readers already know how to take.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import re
from collections import Counter
from typing import Any

ROOT = pathlib.Path(__file__).resolve().parents[2]
DEFAULT_IN = (
    ROOT / "hermes/app/runtime/experiments/language/lesson_structure_bigred.jsonl"
)
#  The anchored rows are tracked, the model's raw testimony is not. Every row
#  below was found verbatim in a tracked lesson file and carries that file's
#  SHA-256, so the store can be re-verified without the model that proposed it.
DEFAULT_OUT = ROOT / "curriculum/im/generated/structure_task_rows.jsonl"
DEFAULT_QUESTIONS = ROOT / "curriculum/im/generated/structure_teacher_questions.jsonl"

EXPRESSION_SHAPE = re.compile(r"\d")
WHITESPACE = re.compile(r"\s+")


def file_sha(path: pathlib.Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def find_verbatim(text: str, needle: str) -> tuple[int, int] | None:
    """Byte-exact first, then whitespace-tolerant. Never fuzzy beyond that."""
    if not needle:
        return None
    index = text.find(needle)
    if index >= 0:
        return index, index + len(needle)
    # The guide is a column extract, so a copied span may carry different runs
    # of spaces.  Collapse runs on both sides and map the match back.
    collapsed_needle = WHITESPACE.sub(" ", needle).strip()
    if not collapsed_needle:
        return None
    pattern = re.compile(
        r"\s*".join(re.escape(part) for part in collapsed_needle.split(" ")),
        re.S,
    )
    match = pattern.search(text)
    return (match.start(), match.end()) if match else None


def line_of(text: str, offset: int) -> int:
    return text.count("\n", 0, offset) + 1


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=pathlib.Path, default=DEFAULT_IN)
    parser.add_argument("--out", type=pathlib.Path, default=DEFAULT_OUT)
    parser.add_argument(
        "--questions", type=pathlib.Path, default=DEFAULT_QUESTIONS
    )
    parser.add_argument("--report", action="store_true")
    args = parser.parse_args()

    if not args.input.exists():
        raise SystemExit(f"no structure ledger at {args.input}")

    stats: Counter = Counter()
    rows: list[dict[str, Any]] = []
    questions: list[dict[str, Any]] = []
    lesson_texts: dict[str, str] = {}

    for line in args.input.read_text(encoding="utf-8").splitlines():
        try:
            record = json.loads(line)
        except json.JSONDecodeError:
            stats["ledger_line_unreadable"] += 1
            continue
        if record.get("outcome") != "ok" or "structure" not in record:
            stats["lesson_without_structure"] += 1
            continue
        stats["lesson_read"] += 1
        path = ROOT / record["path"]
        if not path.exists():
            stats["lesson_file_missing"] += 1
            continue
        if record["path"] not in lesson_texts:
            lesson_texts[record["path"]] = path.read_text(
                encoding="utf-8", errors="replace"
            )
        text = lesson_texts[record["path"]]
        sha = file_sha(path)
        structure = record["structure"]

        for index, task in enumerate(structure.get("task_statements") or []):
            stats["task_statement_claimed"] += 1
            asks = [a for a in (task.get("asks") or []) if isinstance(a, str)]
            expressions = [
                e
                for e in (task.get("printed_expressions") or [])
                if isinstance(e, str) and EXPRESSION_SHAPE.search(e)
            ]
            anchored_ask = None
            for ask in asks:
                span = find_verbatim(text, ask.strip())
                if span:
                    anchored_ask = {
                        "text": ask.strip(),
                        "byte_start": span[0],
                        "byte_end": span[1],
                        "line": line_of(text, span[0]),
                    }
                    break
            if asks and not anchored_ask:
                stats["ask_not_found_in_file"] += 1

            anchored_expressions = []
            for expression in expressions:
                span = find_verbatim(text, expression.strip())
                if not span:
                    stats["expression_not_found_in_file"] += 1
                    continue
                anchored_expressions.append(
                    {
                        "text": expression.strip(),
                        "byte_start": span[0],
                        "byte_end": span[1],
                        "line": line_of(text, span[0]),
                    }
                )
            stats["expression_anchored"] += len(anchored_expressions)

            if not anchored_expressions and not anchored_ask:
                stats["task_statement_unanchored"] += 1
                continue
            stats["task_statement_anchored"] += 1
            stats[f"kind:{task.get('kind')}"] += 1
            rows.append(
                {
                    "lesson": record["lesson"],
                    "path": record["path"],
                    "file_sha256": sha,
                    "task_index": index,
                    "activity_index": task.get("activity_index"),
                    "kind": task.get("kind"),
                    "question_count": task.get("question_count"),
                    "ask": anchored_ask,
                    "printed_expressions": anchored_expressions,
                    "model": record.get("model"),
                    "testimony_line_range": [
                        task.get("line_start"),
                        task.get("line_end"),
                    ],
                    "extractor_statements": (record.get("referee") or {}).get(
                        "extractor_statements"
                    ),
                }
            )

        for question in structure.get("teacher_questions") or []:
            if not isinstance(question, dict):
                continue
            stats["teacher_question_claimed"] += 1
            asked = (question.get("text") or "").strip()
            span = find_verbatim(text, asked)
            if span:
                stats["teacher_question_anchored"] += 1
                stats[f"teacher_question_region:{question.get('region_type')}"] += 1
                questions.append(
                    {
                        "lesson": record["lesson"],
                        "path": record["path"],
                        "file_sha256": sha,
                        "region_type": question.get("region_type"),
                        "text": asked,
                        "byte_start": span[0],
                        "byte_end": span[1],
                        "line": line_of(text, span[0]),
                        "model": record.get("model"),
                    }
                )
            else:
                stats["teacher_question_not_found"] += 1

    args.out.parent.mkdir(parents=True, exist_ok=True)
    with args.out.open("w", encoding="utf-8") as handle:
        for row in rows:
            handle.write(json.dumps(row, ensure_ascii=False, sort_keys=True) + "\n")

    args.questions.parent.mkdir(parents=True, exist_ok=True)
    with args.questions.open("w", encoding="utf-8") as handle:
        for question in questions:
            handle.write(
                json.dumps(question, ensure_ascii=False, sort_keys=True) + "\n"
            )

    print(f"candidate task rows written: {len(rows)} -> {args.out}")
    print(f"anchored teacher questions: {len(questions)} -> {args.questions}")
    print(f"lessons carrying rows: {len({r['lesson'] for r in rows})}")
    print("\n== census ==")
    for name, count in sorted(stats.items()):
        print(f"{count:7d}  {name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
