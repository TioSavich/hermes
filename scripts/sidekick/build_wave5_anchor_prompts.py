#!/usr/bin/env python3
"""Build the wave-5 anchor prompt set: a forgetting guard for LoRA training.

Wave 5 tunes the base model on Prolog-program replies. Tuned that way alone,
a model can lose its ordinary teaching register. The anchor set holds ~500
rows whose target reply is the untuned base model's own answer to an
ordinary teacher-facing question, so mixing them into training keeps that
register present in the loss. Anchor prompts never ask for a Prolog program
and never repeat a solution-mint task statement; they ask the kind of
question a teacher asks a colleague (explain, plan, respond to a student,
describe a representation).

The prompts are template sentences authored here, filled with slot values
read from the curriculum store: lesson id, grade, topic words, and one task
statement fragment. Two store files are the only sources:

    curriculum/im/generated/compiled_defragged_task_instances.pl
        defragged_task_instance/4 facts; the fragment slot comes from each
        usable row's source_statement field.
    curriculum/im/lesson_topics_cache.pl
        lesson_topics_cached/2 facts; the topic-word slot.

Both files are Prolog source, read here with regular expressions tuned to
their generator's fixed layout, not a general Prolog parser. Field
boundaries were checked against the file's own summary counts before this
regex shape was adopted (see the builder's test run, not tracked here).

Every candidate prompt passes two gates before it is kept: the 13-gram
benchmark-overlap gate (scripts/sidekick/contamination.py OverlapGate) and
an 8-gram gate against text belonging to the held-out lessons named in
wave5-split-manifest.json, using the same register-aware exemption the
solution-mint pipeline already built (register_8grams.json), so generic
instructional phrasing shared across many lessons is not mistaken for a
held-out lesson's distinctive content. Candidate lessons are restricted to
the split manifest's train lessons from the start; the held-out gate is a
second, independent check on top of that restriction, not a replacement
for it.

No randomness is used anywhere in this file. Ordering comes from sorting
by the store's own row ids (content-hash strings, stable across runs), and
template assignment is a fixed round robin over that sorted order. A
second run over an unchanged store produces a byte-identical output file.
"""
from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[1]
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from contamination import (  # noqa: E402
    INDEX_PATH, REGISTER_LEXICON_PATH, SPLIT_GRAM, OverlapGate,
    load_register_lexicon, register_aware_split_overlap,
)

BUILDER_VERSION = "wave5-anchor-prompts-v1"

DEFRAG_PATH = REPO_ROOT / "curriculum" / "im" / "generated" / "compiled_defragged_task_instances.pl"
TOPICS_PATH = REPO_ROOT / "curriculum" / "im" / "lesson_topics_cache.pl"
SPLIT_MANIFEST_PATH = (
    REPO_ROOT / "hermes" / "app" / "runtime" / "experiments" / "sidekick" / "datasets" / "wave5-split-manifest.json"
)
SOLUTION_PAIRS_PATH = (
    REPO_ROOT / "hermes" / "app" / "runtime" / "experiments" / "sidekick" / "datasets" / "wave5-solution-pairs.jsonl"
)
DATASETS_DIR = REPO_ROOT / "hermes" / "app" / "runtime" / "experiments" / "sidekick" / "datasets"
OUTPUT_PATH = DATASETS_DIR / "wave5-anchor-prompts.jsonl"
REPORT_PATH = DATASETS_DIR / "wave5-anchor-prompts-report.json"

USABLE_STATUSES = ("already_complete", "recovered", "recovered_with_referent")
CAP_PER_LESSON = 2  # spreads candidates across lessons instead of a few busy ones
TARGET_ROWS = 500
FRAGMENT_LIMIT = 200

DEFRAG_CLAUSE_START = re.compile(r"\n(?=defragged_task_instance\()")
DEFRAG_ID = re.compile(r"^defragged_task_instance\(([a-zA-Z0-9_]+),")
DEFRAG_LESSON = re.compile(r"^defragged_task_instance\([a-zA-Z0-9_]+,\s*'([^']*)',")
DEFRAG_STATUS = re.compile(
    r'defragged_task\{evidence_sha256:"[a-f0-9]+", status:([a-zA-Z_]+), blocker:([a-zA-Z0-9_]+)'
)
DEFRAG_COMPLETE_STATEMENT = re.compile(r'complete_statement:"((?:[^"\\]|\\.)*)"')
DEFRAG_SOURCE_STATEMENT = re.compile(r'source_statement:"((?:[^"\\]|\\.)*)"')
TOPICS_FACT = re.compile(r"lesson_topics_cached\('([^']*)',\s*\[([^\]]*)\]\)\.")
GRADE_FROM_LESSON = re.compile(r"^IM-G(K|\d+)-U")
LEADING_NUMBER = re.compile(r"^\d{1,2}\.\s+")

# Topic words as they appear in lesson_topics_cache.pl, mapped to the noun
# phrase a template sentence reads naturally with. Covers every word the
# cache uses (checked against the file before writing this table).
TOPIC_PHRASE = {
    "addition": "addition", "subtraction": "subtraction", "multiplication": "multiplication",
    "division": "division", "fraction": "fractions", "decimal": "decimals", "ratio": "ratios",
    "proportional": "proportional relationships", "geometry": "geometry",
    "data": "data and measurement", "counting": "counting", "cardinality": "cardinality",
    "algebraic": "algebraic reasoning", "integer": "integers", "probability": "probability",
}
FALLBACK_TOPIC_PHRASE = "mathematics"

# Twelve teacher-facing templates. None asks for a Prolog program or any
# tool call; each asks the kind of question a teacher would ask a
# colleague. {article} is only used where the topic phrase sits right next
# to "a"/"an"; other templates put "grade" between the article and the
# topic, where "a" is always correct.
TEMPLATES: list[tuple[str, str]] = [
    ("ask_next",
     "A grade {grade} class is working on {topic}. One task on today's page reads: "
     "\"{fragment}\" What question would you ask a student who finishes it quickly?"),
    ("representation",
     "You are planning a grade {grade} lesson on {topic}. A task from the lesson is "
     "\"{fragment}\". Describe a classroom representation, drawing, or tool that would "
     "help students reason about it."),
    ("unexpected_answer",
     "A grade {grade} student just answered the task \"{fragment}\" from {article} {topic} "
     "lesson, but got a different number than you expected. What would you ask the student "
     "to say next, to find out how they were thinking?"),
    ("why_matters",
     "In a grade {grade} {topic} lesson, students are asked to work on \"{fragment}\". "
     "Explain in plain language why this kind of task matters for building their "
     "understanding of {topic}."),
    ("new_teacher",
     "A new teacher is about to run a grade {grade} lesson on {topic} that includes the "
     "task \"{fragment}\". What should they watch for while students work, and why?"),
    ("launch_line",
     "Write a short prompt you could say out loud to a grade {grade} class before they "
     "start the task \"{fragment}\" in a lesson on {topic}."),
    ("parent_question",
     "A parent asks why their grade {grade} child's homework includes a task like "
     "\"{fragment}\" as part of learning {topic}. How would you explain the purpose of "
     "this task in a few sentences?"),
    ("compare_strategies",
     "Two students in a grade {grade} class disagree about how to approach \"{fragment}\" "
     "during {article} {topic} lesson. What question would you ask to help them compare "
     "their strategies?"),
    ("stuck_student",
     "A grade {grade} student says they are stuck on \"{fragment}\" during {article} "
     "{topic} lesson. What is one question you could ask to help them get started without "
     "giving away the answer?"),
    ("introduce_task",
     "Describe how you would introduce the task \"{fragment}\" to a grade {grade} class "
     "studying {topic}, in two or three sentences."),
    ("synthesis_question",
     "A grade {grade} class has just finished the task \"{fragment}\" from {article} "
     "{topic} lesson. What follow-up question would move the discussion from individual "
     "answers to a shared strategy?"),
    ("coaching_feedback",
     "You are giving feedback to a student teacher who taught a grade {grade} {topic} "
     "lesson including the task \"{fragment}\". What is one specific thing you would tell "
     "them to try differently next time?"),
]
TEMPLATE_BY_ID = {template_id: text for template_id, text in TEMPLATES}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def repo_relative(path: Path) -> str:
    return str(path.relative_to(REPO_ROOT))


def decode_prolog_string(raw: str) -> str:
    """Decode a captured Prolog double-quoted-string body via JSON escaping.

    SWI-Prolog's string writer escapes the way JSON does for the characters
    this store uses (\\", \\\\, \\n, \\uXXXX); wrapping the captured body in
    quotes and handing it to json.loads reuses a correct decoder instead of
    writing a second one.
    """
    return json.loads('"' + raw + '"')


def load_defrag_rows(path: Path) -> list[dict[str, Any]]:
    text = path.read_text(encoding="utf-8")
    clauses = [part for part in DEFRAG_CLAUSE_START.split(text) if part.startswith("defragged_task_instance(")]
    rows = []
    for clause in clauses:
        row_id = DEFRAG_ID.match(clause).group(1)
        lesson = DEFRAG_LESSON.match(clause).group(1)
        status_match = DEFRAG_STATUS.search(clause)
        status = status_match.group(1)
        complete_statement = decode_prolog_string(DEFRAG_COMPLETE_STATEMENT.search(clause).group(1))
        source_statement = decode_prolog_string(DEFRAG_SOURCE_STATEMENT.search(clause).group(1))
        rows.append({
            "id": row_id, "lesson": lesson, "status": status,
            "complete_statement": complete_statement, "source_statement": source_statement,
        })
    return rows


def load_topics(path: Path) -> dict[str, list[str]]:
    text = path.read_text(encoding="utf-8")
    topics: dict[str, list[str]] = {}
    for match in TOPICS_FACT.finditer(text):
        lesson, raw_list = match.groups()
        words = sorted({word.strip() for word in raw_list.split(",") if word.strip()})
        topics[lesson] = words
    return topics


def topic_phrase_for(lesson: str, topics_by_lesson: dict[str, list[str]]) -> str:
    words = topics_by_lesson.get(lesson) or []
    phrases = [TOPIC_PHRASE.get(word, word) for word in words[:2]]
    if not phrases:
        return FALLBACK_TOPIC_PHRASE
    if len(phrases) == 1:
        return phrases[0]
    return f"{phrases[0]} and {phrases[1]}"


def article_for(phrase: str) -> str:
    return "an" if phrase[:1].lower() in "aeiou" else "a"


def grade_for(lesson: str) -> str:
    return GRADE_FROM_LESSON.match(lesson).group(1)


def clean_fragment(raw: str, limit: int = FRAGMENT_LIMIT) -> str:
    text = raw.replace("•", "").strip()
    text = re.sub(r"\s+", " ", text)
    text = LEADING_NUMBER.sub("", text)
    if len(text) > limit:
        text = text[:limit].rsplit(" ", 1)[0] + "..."
    return text.strip()


def fragment_is_suitable(raw: str, cleaned: str) -> bool:
    if not cleaned or not re.search(r"[a-zA-Z0-9]", cleaned):
        return False
    # Raw LaTeX markup reads as broken text inside a plain sentence; a
    # handful of source statements carry it (checked against the store: 4
    # of 1571 usable-train rows), so they are skipped rather than mangled.
    if "$$" in raw or "\\" in raw:
        return False
    return True


def build() -> tuple[list[dict[str, Any]], dict[str, Any]]:
    defrag_rows = load_defrag_rows(DEFRAG_PATH)
    topics_by_lesson = load_topics(TOPICS_PATH)
    split_manifest = json.loads(SPLIT_MANIFEST_PATH.read_text(encoding="utf-8"))
    train_lesson_ids = set(split_manifest["train_lesson_ids"])
    held_out_lesson_ids = set(split_manifest["held_out_lesson_ids"])

    solution_pair_inputs: set[str] = set()
    with SOLUTION_PAIRS_PATH.open(encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if line:
                solution_pair_inputs.add(json.loads(line)["input"])

    usable_train_rows = sorted(
        (row for row in defrag_rows if row["status"] in USABLE_STATUSES and row["lesson"] in train_lesson_ids),
        key=lambda row: row["id"],
    )

    drop_counts: dict[str, int] = {}

    def drop(reason: str) -> None:
        drop_counts[reason] = drop_counts.get(reason, 0) + 1

    eligible: list[dict[str, Any]] = []
    lesson_counts: dict[str, int] = {}
    for row in usable_train_rows:
        fragment = clean_fragment(row["source_statement"])
        if not fragment_is_suitable(row["source_statement"], fragment):
            drop("unsuitable_fragment")
            continue
        lesson = row["lesson"]
        if lesson_counts.get(lesson, 0) >= CAP_PER_LESSON:
            drop("lesson_cap_exceeded")
            continue
        lesson_counts[lesson] = lesson_counts.get(lesson, 0) + 1
        eligible.append({**row, "fragment": fragment})

    candidates: list[dict[str, Any]] = []
    for index, row in enumerate(eligible):
        template_id, template_text = TEMPLATES[index % len(TEMPLATES)]
        grade = grade_for(row["lesson"])
        topic = topic_phrase_for(row["lesson"], topics_by_lesson)
        prompt = template_text.format(
            grade=grade, topic=topic, fragment=row["fragment"], article=article_for(topic),
        )
        candidates.append({
            "source_row_id": row["id"], "lesson": row["lesson"], "grade": grade,
            "template_id": template_id, "prompt": prompt,
        })

    seen_prompts: set[str] = set()
    after_internal_dedupe: list[dict[str, Any]] = []
    for candidate in candidates:
        if candidate["prompt"] in seen_prompts:
            drop("duplicate_prompt_text")
            continue
        seen_prompts.add(candidate["prompt"])
        after_internal_dedupe.append(candidate)

    after_training_dedupe: list[dict[str, Any]] = []
    for candidate in after_internal_dedupe:
        if candidate["prompt"] in solution_pair_inputs:
            drop("duplicate_training_input")
            continue
        after_training_dedupe.append(candidate)

    overlap_gate = OverlapGate()
    after_benchmark_gate: list[dict[str, Any]] = []
    for candidate in after_training_dedupe:
        if overlap_gate.clean(candidate["prompt"]):
            after_benchmark_gate.append(candidate)
        else:
            drop("benchmark_13gram")

    held_out_text: dict[str, str] = {
        row["id"]: row["complete_statement"] + " " + row["source_statement"]
        for row in defrag_rows if row["lesson"] in held_out_lesson_ids
    }
    candidate_text = {
        f"{candidate['source_row_id']}::{candidate['template_id']}": candidate["prompt"]
        for candidate in after_benchmark_gate
    }
    register_artifact, register_lexicon = load_register_lexicon()
    overlap_result = register_aware_split_overlap(
        held_out_text, candidate_text, register_lexicon, size=SPLIT_GRAM
    )
    blocked_keys = {hit["right"] for hit in overlap_result["blocking"]}
    after_heldout_gate: list[dict[str, Any]] = []
    for candidate in after_benchmark_gate:
        key = f"{candidate['source_row_id']}::{candidate['template_id']}"
        if key in blocked_keys:
            drop("heldout_8gram")
        else:
            after_heldout_gate.append(candidate)

    final_candidates = after_heldout_gate[:TARGET_ROWS]
    for _ in after_heldout_gate[TARGET_ROWS:]:
        drop("surplus_beyond_target")

    rows: list[dict[str, Any]] = []
    seen_ids: set[str] = set()
    defrag_sha256 = sha256(DEFRAG_PATH)
    topics_sha256 = sha256(TOPICS_PATH)
    split_manifest_sha256 = sha256(SPLIT_MANIFEST_PATH)
    index_sha256 = sha256(INDEX_PATH)
    register_lexicon_sha256 = sha256(REGISTER_LEXICON_PATH)
    provenance_template = {
        "builder_version": BUILDER_VERSION,
        "source_defrag_path": repo_relative(DEFRAG_PATH),
        "source_defrag_sha256": defrag_sha256,
        "source_topics_path": repo_relative(TOPICS_PATH),
        "source_topics_sha256": topics_sha256,
        "split_manifest_path": repo_relative(SPLIT_MANIFEST_PATH),
        "split_manifest_sha256": split_manifest_sha256,
        "gates": {
            "benchmark_13gram": {
                "index_path": repo_relative(INDEX_PATH), "index_sha256": index_sha256,
            },
            "heldout_8gram": {
                "mode": "register_aware", "size": SPLIT_GRAM,
                "register_lexicon_path": repo_relative(REGISTER_LEXICON_PATH),
                "register_lexicon_sha256": register_lexicon_sha256,
                "register_lexicon_version": register_artifact.get("version"),
            },
        },
    }
    for candidate in final_candidates:
        row_id = "anchor_" + hashlib.sha1(candidate["prompt"].encode("utf-8")).hexdigest()[:12]
        if row_id in seen_ids:
            raise RuntimeError(f"anchor id collision: {row_id}")
        seen_ids.add(row_id)
        rows.append({
            "id": row_id,
            "prompt": candidate["prompt"],
            "template_id": candidate["template_id"],
            "grade": candidate["grade"],
            "lesson": candidate["lesson"],
            "provenance": {**provenance_template, "source_row_id": candidate["source_row_id"]},
        })

    template_inventory = {template_id: 0 for template_id, _ in TEMPLATES}
    for row in rows:
        template_inventory[row["template_id"]] += 1
    grade_inventory: dict[str, int] = {}
    for row in rows:
        grade_inventory[row["grade"]] = grade_inventory.get(row["grade"], 0) + 1

    considered = len(usable_train_rows)
    accounted = len(rows) + sum(drop_counts.values())
    report = {
        "builder_version": BUILDER_VERSION,
        "sources": {
            "defrag_task_instances": {
                "path": repo_relative(DEFRAG_PATH), "sha256": defrag_sha256,
                "total_records": len(defrag_rows),
            },
            "lesson_topics_cache": {
                "path": repo_relative(TOPICS_PATH), "sha256": topics_sha256,
                "lessons": len(topics_by_lesson),
            },
            "split_manifest": {
                "path": repo_relative(SPLIT_MANIFEST_PATH), "sha256": split_manifest_sha256,
                "train_lessons": len(train_lesson_ids), "held_out_lessons": len(held_out_lesson_ids),
            },
            "solution_pairs": {
                "path": repo_relative(SOLUTION_PAIRS_PATH), "input_rows": len(solution_pair_inputs),
            },
        },
        "gates": provenance_template["gates"],
        "cap_per_lesson": CAP_PER_LESSON,
        "target_rows": TARGET_ROWS,
        "usable_train_rows_considered": considered,
        "final_row_count": len(rows),
        "drop_counts": dict(sorted(drop_counts.items())),
        "reconciliation": {
            "considered": considered,
            "kept_plus_dropped": accounted,
            "balanced": considered == accounted,
        },
        "template_inventory": {
            template_id: {"text": TEMPLATE_BY_ID[template_id], "count": count}
            for template_id, count in sorted(template_inventory.items())
        },
        "grade_inventory": dict(sorted(grade_inventory.items())),
    }
    return rows, report


def write_jsonl(rows: list[dict[str, Any]], path: Path) -> str:
    path.parent.mkdir(parents=True, exist_ok=True)
    lines = [json.dumps(row, sort_keys=True, ensure_ascii=False) for row in rows]
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return sha256(path)


def main() -> int:
    rows, report = build()
    output_sha = write_jsonl(rows, OUTPUT_PATH)
    report["output_path"] = repo_relative(OUTPUT_PATH)
    report["output_sha256"] = output_sha
    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.write_text(
        json.dumps(report, sort_keys=True, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"anchor prompts: {len(rows)} rows -> {OUTPUT_PATH}")
    print(f"output sha256: {output_sha}")
    print(f"reconciliation balanced: {report['reconciliation']['balanced']}")
    if not report["reconciliation"]["balanced"]:
        print("WARNING: considered rows do not equal kept + dropped; see report.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
