#!/usr/bin/env python3
"""Mint the questioning Prompt/Input/Output dataset.

The output side is the provenance spine: the question is IM's own text, culled
for typesetting and nothing else. The input side is assembled from the stores
wave 5 mints from, under the same four fragment gates, the same culling
contract, the same two contamination gates, and the same frozen lesson split —
a lesson held out of wave 5 is held out here.

Every row carries `admitted_for_training` with the condition that failed. The
line is the one the controller drew: IM's authored questions with mechanical
vetting train; extraction noise and unverifiable rows do not.
"""
from __future__ import annotations

import argparse
import collections
import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
for candidate in (str(Path(__file__).resolve().parent), str(ROOT / "scripts" / "sidekick"), str(ROOT)):
    if candidate not in sys.path:
        sys.path.insert(0, candidate)

from build_wave5_row_map import POOL, load_pool_rows, sha256  # noqa: E402
from build_wave5_solution_mint import SPLIT_MANIFEST, admission, genre_of  # noqa: E402
from contamination import (  # noqa: E402
    GRAM, SPLIT_GRAM, REGISTER_LEXICON_PATH, OverlapGate, index_manifest,
    load_register_lexicon, register_aware_split_overlap,
)
from training_text import cull_wave5_training_text  # noqa: E402

from question_corpus import build_sentences, load_records  # noqa: E402

RUNTIME = ROOT / "hermes" / "app" / "runtime" / "experiments" / "questions"
DATASET = RUNTIME / "question-pio-pairs.jsonl"
CENSUS = RUNTIME / "question-pio-census.json"
REPORT = RUNTIME / "question-pio-report.json"

PROMPT_VERSION = "question-pio-v1"
PROMPT = (
    "You are the teacher. A class is working on the task below, at the moment "
    "of the lesson named below. Ask one question that moves the mathematics. "
    "Reply with the question and nothing else."
)
BUILDER_VERSION = "question-pio-mint-v2-register-aware-gate"


def verified_links() -> dict[str, dict]:
    """Sentence identity -> the verified link, when the engine re-proved one."""
    table: dict[str, dict] = {}
    for name in ("baseline_links.jsonl", "glm_pilot_links.jsonl", "glm_scale_links.jsonl"):
        path = RUNTIME / name
        if not path.is_file():
            continue
        for line in path.read_text(encoding="utf-8").splitlines():
            if not line.strip():
                continue
            row = json.loads(line)
            table.setdefault(row["identity"], row)
    return table


def canonical_bytes(value: object, *, pretty: bool = False) -> bytes:
    if pretty:
        return (json.dumps(value, ensure_ascii=False, indent=1, sort_keys=True) + "\n").encode()
    return (json.dumps(value, ensure_ascii=False, sort_keys=True,
                       separators=(",", ":")) + "\n").encode()


def build() -> dict[Path, bytes]:
    records = load_records()
    sentences, prefiltered = build_sentences(records)
    pool = load_pool_rows()

    admitted_statements: dict[str, list[dict]] = collections.defaultdict(list)
    gate_counts: collections.Counter[str] = collections.Counter()
    for row in sorted(pool, key=lambda item: item["id"]):
        passed, decision = admission(row)
        if passed:
            admitted_statements[row["lesson"]].append(row)
        else:
            gate_counts[decision] += 1

    question_lessons = {sentence.lesson for sentence in sentences if not sentence.peer_work}
    statement_lessons = set(admitted_statements)
    joined = question_lessons & statement_lessons
    census = {
        "question_records": len(records),
        "prefilter_exclusions": prefiltered,
        "question_sentences": len(sentences),
        "requires_peer_work_sentences": sum(1 for s in sentences if s.peer_work),
        "lessons_with_questions": len(question_lessons),
        "pool_rows": len(pool),
        "four_gate_exclusions": dict(gate_counts),
        "lessons_with_a_gate_passing_statement": len(statement_lessons),
        "lessons_with_both": len(joined),
        "questions_in_joined_lessons": sum(
            1 for s in sentences if not s.peer_work and s.lesson in joined),
        "questions_lost_to_no_admitted_statement": sum(
            1 for s in sentences if not s.peer_work and s.lesson not in joined),
    }

    manifest = json.loads(SPLIT_MANIFEST.read_text(encoding="utf-8"))
    split_of = {lesson: "train" for lesson in manifest["train_lesson_ids"]}
    split_of.update({lesson: "held_out" for lesson in manifest["held_out_lesson_ids"]})

    links = verified_links()
    overlap = OverlapGate()

    rows: list[dict] = []
    for sentence in sentences:
        if sentence.peer_work or sentence.lesson not in joined:
            continue
        link = links.get(sentence.identity)
        source = None
        if link:
            # The statement the engine actually ran for this link, when the
            # four gates admitted it; otherwise the lesson's first admitted row.
            witness_row = link["verification"]["checks"]["run_check"].get("witness_row")
            for candidate in admitted_statements[sentence.lesson]:
                if candidate["id"] == witness_row:
                    source = candidate
                    break
        if source is None:
            source = admitted_statements[sentence.lesson][0]
        statement = cull_wave5_training_text(source["statement"])
        question = cull_wave5_training_text(sentence.text)
        parts = [
            f"Moment: {sentence.activity_location}.",
            f"Task: {statement.text}",
        ]
        if link:
            parts.append(
                "Reading so far: the class's work is being read as "
                f"{link['machine']} ({link['context_polarity']})."
            )
        model_input = " ".join(parts)
        split = split_of.get(sentence.lesson, "unassigned")
        rows.append({
            "identity": sentence.identity,
            "lesson": sentence.lesson,
            "grade": sentence.grade,
            "split": split,
            "prompt_version": PROMPT_VERSION,
            "prompt": PROMPT,
            "input": model_input,
            "output": question.text,
            "activity_location": sentence.activity_location,
            "genre": genre_of(source["statement"]),
            "label": sentence.record_type,
            "label_origin": sentence.label_origin,
            "review_status": sentence.review_status,
            "link_verification": (
                {
                    "state": "verified",
                    "proposer": link["proposer"],
                    "pattern_id": link["pattern_ids"][0],
                    "machine": link["machine"],
                    "move_type": link["move_type"],
                    "effect": link["effect"]["kind"],
                }
                if link else {"state": "none"}
            ),
            "curriculum_text": f"{statement.text} {question.text}",
            "provenance": {
                "source_guide": sentence.source_guide,
                "source_span": [sentence.span_start, sentence.span_end],
                "sentence_index": sentence.sentence_index,
                "record_index": sentence.record_index,
                "statement_row": source["id"],
                "statement_evidence_sha256": source["evidence_sha256"],
                "culling_version": statement.version,
                "builder": BUILDER_VERSION,
            },
        })

    # Contamination, in the order wave 5 runs it: the benchmark index first,
    # then the held-out lessons of the program's one split.
    benchmark_hits = 0
    for row in rows:
        hits = overlap.hits(row["input"]) + overlap.hits(row["output"])
        row["_benchmark_clean"] = not hits
        if hits:
            benchmark_hits += 1
    # The split gate reads the curriculum text only. The prompt scaffolding is
    # identical on every row, so including it would manufacture shared grams
    # out of my own boilerplate and call that a leak.
    train_text = {
        row["identity"]: row["curriculum_text"]
        for row in rows if row["split"] == "train" and row["_benchmark_clean"]
    }
    heldout_text = {
        row["identity"]: row["curriculum_text"]
        for row in rows if row["split"] == "held_out"
    }
    register_artifact, register_grams = load_register_lexicon()
    shared = register_aware_split_overlap(
        heldout_text, train_text, register_grams, SPLIT_GRAM)
    strict_shared = shared["strict"]
    register_shared = shared["register"]
    blocking_shared = shared["blocking"]
    strict_leaking = {item["right"] for item in strict_shared}
    leaking = {item["right"] for item in blocking_shared}

    admitted_rows = 0
    reasons: collections.Counter[str] = collections.Counter()
    for row in rows:
        failing: list[str] = []
        if not row["_benchmark_clean"]:
            failing.append("benchmark_13gram")
        if row["identity"] in leaking:
            failing.append("heldout_8gram")
        if row["split"] == "held_out":
            failing.append("held_out_split")
        elif row["split"] != "train":
            # A lesson the frozen wave-5 manifest does not assign. The pool
            # gained rows after the manifest was frozen; these wait for the
            # next split rather than being guessed into one.
            failing.append("outside_the_frozen_split")
        if row["review_status"] == "culled_by_reviewer":
            failing.append("culled_by_reviewer")
        row["admitted_for_training"] = not failing
        row["admission_failures"] = failing
        del row["_benchmark_clean"]
        del row["curriculum_text"]
        if failing:
            reasons[failing[0]] += 1
        else:
            admitted_rows += 1

    dataset_bytes = b"".join(canonical_bytes(row) for row in rows)

    admitted = [row for row in rows if row["admitted_for_training"]]
    report = {
        "builder": BUILDER_VERSION,
        "pool": str(POOL.relative_to(ROOT)),
        "pool_sha256": sha256(POOL),
        "split_manifest_assignment_sha256": manifest.get("assignment_sha256"),
        "prompt_version": PROMPT_VERSION,
        "census": census,
        "rows": len(rows),
        "rows_by_split": dict(collections.Counter(row["split"] for row in rows)),
        "rows_with_a_verified_link": sum(
            1 for row in rows if row["link_verification"]["state"] == "verified"),
        "rows_approved_by_review": sum(1 for row in rows if row["review_status"] == "approved"),
        "admitted_for_training": admitted_rows,
        "first_failing_condition": dict(reasons),
        "admitted_by_grade": dict(collections.Counter(row["grade"] for row in admitted)),
        "admitted_by_label": dict(collections.Counter(row["label"] for row in admitted)),
        "admitted_by_basis": dict(collections.Counter(
            "approved_by_review" if row["review_status"] == "approved" else "verified_link"
            for row in admitted)),
        "benchmark_gate": {**index_manifest(), "gram": GRAM, "rows_with_hits": benchmark_hits},
        "heldout_gate": {
            "gram": SPLIT_GRAM, "scope": "curriculum text only",
            "law": "exclude train rows only for held-out 8-grams absent from the shared register lexicon",
            "strict_shared_gram_hits": len(strict_shared),
            "strict_training_rows": len(strict_leaking),
            "register_shared_gram_hits": len(register_shared),
            "register_exempted_training_rows": len(strict_leaking - leaking),
            "blocking_shared_gram_hits": len(blocking_shared),
            "training_rows_excluded": len(leaking),
            "register_lexicon": str(REGISTER_LEXICON_PATH.relative_to(ROOT)),
            "register_lexicon_sha256": hashlib.sha256(REGISTER_LEXICON_PATH.read_bytes()).hexdigest(),
            "register_lexicon_size": register_artifact["register_grams"],
        },
        "duplicate_input_groups": sum(
            1 for _, count in collections.Counter(
                (row["split"], row["input"]) for row in rows).items() if count > 1),
        "dataset": str(DATASET),
        "dataset_sha256": hashlib.sha256(dataset_bytes).hexdigest(),
    }
    return {
        DATASET: dataset_bytes,
        CENSUS: canonical_bytes(census, pretty=True),
        REPORT: canonical_bytes(report, pretty=True),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true",
                        help="rebuild and require byte-identical artifacts")
    args = parser.parse_args()
    outputs = build()
    if args.check:
        stale = [str(path) for path, data in outputs.items()
                 if not path.is_file() or path.read_bytes() != data]
        if stale:
            print("stale question PIO artifacts: " + ", ".join(stale), file=sys.stderr)
            return 1
        print(f"PASS question PIO double-build is byte-identical: {len(outputs)} artifacts")
        return 0
    for path, data in outputs.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
    report = json.loads(outputs[REPORT])
    print(json.dumps(report, indent=1, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
