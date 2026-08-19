#!/usr/bin/env python3
"""Label K-5 teacher questions assessing or advancing by the trusted heading rule.

curriculum/im/generated/structure_teacher_questions.jsonl carries 11,202
byte-anchored teacher questions from the K-5 (plus two grade-6) guides, each
tagged with a `region_type` the extraction model named. This builder assigns
each row a label by testing its `region_type` against the one heading rule
the repository already trusts: `assessing_heading_order` and
`advancing_heading_order` in scripts/research/extract_lesson_context.py,
lines 668-681, reproduced verbatim below as ASSESSING_HEADINGS and
ADVANCING_HEADINGS.

The two vocabularies are not the same vocabulary read twice. The heading
rule names section headings copied from grade 6-8 Docling guide markdown
(`## Activity Synthesis`, `## Building on Student Thinking`, and so on); the
store's `region_type` values name a controlled list a local model applied to
K-5 fixed-width guide text (see REGION_TYPES in
scripts/curriculum/discover_lesson_structure.py). The two lists share some
names by accident of shared curriculum vocabulary and diverge on others.
Matching a region_type to a label on the strength of a shared word in its
name, rather than a literal identity with a heading the rule states, is an
invented correspondence, not a re-derivation of the rule -- this builder
does not make one. A region_type is labeled only when its normalized form
is byte-identical to a normalized heading string the rule already carries;
every other region_type is excluded and counted, never guessed.

One region_type is an exception to that boundary, by ruling rather than by
heading-string identity: `advancing_student_thinking` (1,098 rows) is
itself the IM curriculum's own published Five Practices section title --
"Advancing Student Thinking" names the function of the questions inside it
directly, the way "Activity Synthesis" and "Launch" do for the headings the
rule already reads. It is not a resemblance to another region_type's name;
it is the curriculum author's own label for what the section does. This
builder maps it to advancing, but marks the row's origin as
`author_heading('Advancing Student Thinking')` rather than
`machine_classification`, so the artifact keeps rule-licensed labels and
author-titled labels distinguishable rather than folding a different kind
of warrant into the same origin atom (see AUTHOR_HEADING_OVERRIDES below).
review_status stays pending_human_review for these rows too: the section
title names the function, but a row's membership in that section -- which
lesson, which line, which exact text -- is still the upstream local
model's assignment, unreviewed. No other excluded region_type is extended
this way; `activity`, `warm_up`, `activity_steps`, `next_day_supports`, and
the rest name no questioning function on their own and stay excluded.

This builder writes curriculum/im/generated/structure_teacher_question_labels.pl:
one `teacher_question_label/2` fact per labeled row (carrying its
label_origin), one `teacher_question_region_type_disposition/3` fact per
distinct region_type naming what became of it, and one
`teacher_question_label_summary/1` fact. Every excluded row is dropped from
the fact base and counted in the summary and the disposition table, never
silently lost.

A finding surfaced while building this: the store's `byte_start`/`byte_end`
fields are not byte offsets into the source file's bytes. They are Python
string (character) offsets from `str.find` against a `str` read with
`encoding="utf-8"` (scripts/curriculum/structure_to_task_rows.py,
`find_verbatim` and `line_of`). The two only coincide while every character
before the span is single-byte ASCII; IM guide text carries multi-byte
typographic quotes and bullets, so most spans drift once a smart quote
precedes them. This builder keeps the source field names for provenance
continuity and states the finding here rather than renaming the field; the
check in scripts/checks/assessing_advancing_labels.py validates spans as
character offsets against the UTF-8-decoded text, not raw bytes.

Deterministic: no model call, no timestamp. The only run-to-run marker is
the source file's SHA-256, carried in the summary fact for drift detection.
Idempotent: the same source file produces byte-identical output.
"""
from __future__ import annotations

import hashlib
import json
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "curriculum/im/generated/structure_teacher_questions.jsonl"
OUTPUT = ROOT / "curriculum/im/generated/structure_teacher_question_labels.pl"

# Copied verbatim from scripts/research/extract_lesson_context.py:668-681.
# Re-read that range before editing these tuples; they are the rule, not a
# paraphrase of it.
ASSESSING_HEADINGS = (
    "Building on Student Thinking",
    "Responding to Student Thinking",
    "Launch",
    "Activity Narrative",
    "Math Community",
    "Consider asking:",
    "Discuss with students:",
)
ADVANCING_HEADINGS = (
    "Activity Synthesis",
    "Lesson Synthesis",
    "More Chances",
)


def normalize_heading(value: str) -> str:
    """Map a heading string and a region_type value onto one comparable form.

    Lowercase, trailing colon dropped, internal whitespace and hyphens
    turned to underscores. Applied identically to both sides of the
    comparison so a match is a literal identity, never a guessed synonym.
    """
    return value.strip().rstrip(":").strip().lower().replace(" ", "_").replace("-", "_")


ASSESSING_REGION_TYPES = frozenset(normalize_heading(h) for h in ASSESSING_HEADINGS)
ADVANCING_REGION_TYPES = frozenset(normalize_heading(h) for h in ADVANCING_HEADINGS)

HEADING_RULE_SOURCE = "scripts/research/extract_lesson_context.py:668-681"

# Controller ruling, 2026-08-18: region_types whose string IS a published IM
# section title naming a questioning function, not merely a name resembling
# one the heading rule already licenses. Each entry maps a region_type to
# the (label, exact published title) the row is credited with. This table is
# reviewed one entry at a time -- it is not a second heading rule, and it is
# not to be grown by resemblance either.
AUTHOR_HEADING_OVERRIDES: dict[str, tuple[str, str]] = {
    "advancing_student_thinking": ("advancing", "Advancing Student Thinking"),
}

REQUIRED_KEYS = (
    "byte_start",
    "byte_end",
    "file_sha256",
    "lesson",
    "line",
    "model",
    "path",
    "region_type",
    "text",
)


def prolog_atom(value: str) -> str:
    return "'" + value.replace("\\", "\\\\").replace("'", "\\'") + "'"


def prolog_string(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def render_label_origin(label_origin: tuple[str, str | None]) -> str:
    kind, title = label_origin
    if kind == "machine_classification":
        return "label_origin(machine_classification)"
    if kind == "author_heading":
        assert title is not None
        return f"label_origin(author_heading({prolog_atom(title)}))"
    raise ValueError(f"unknown label_origin kind: {kind}")


def file_sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load_rows(path: Path) -> list[dict]:
    rows = []
    for line_number, line in enumerate(
        path.read_text(encoding="utf-8").splitlines(), start=1
    ):
        if not line.strip():
            continue
        row = json.loads(line)
        missing = [key for key in REQUIRED_KEYS if key not in row]
        if missing:
            raise ValueError(f"{path}:{line_number} missing keys {missing}")
        rows.append(row)
    return rows


def classify(rows: list[dict]) -> tuple[list[dict], dict[str, tuple[str, int]]]:
    """Split rows into labeled rows and a per-region_type disposition census.

    Returns the labeled rows (assessing/advancing only, unsorted; each
    carries a "label_origin" of either ("machine_classification", None) or
    ("author_heading", exact_title)) and a map from the exact source
    region_type string to (disposition, count), where disposition is
    "assessing", "advancing", or "excluded".
    """
    labeled: list[dict] = []
    region_type_disposition: dict[str, str] = {}
    region_type_count: Counter[str] = Counter()
    for row in rows:
        region_type = row["region_type"]
        region_type_count[region_type] += 1
        if region_type in AUTHOR_HEADING_OVERRIDES:
            disposition, title = AUTHOR_HEADING_OVERRIDES[region_type]
            label_origin = ("author_heading", title)
        else:
            normalized = normalize_heading(region_type)
            if normalized in ASSESSING_REGION_TYPES:
                disposition = "assessing"
            elif normalized in ADVANCING_REGION_TYPES:
                disposition = "advancing"
            else:
                disposition = "excluded"
            label_origin = ("machine_classification", None)
        region_type_disposition[region_type] = disposition
        if disposition != "excluded":
            labeled.append({**row, "label": disposition, "label_origin": label_origin})
    census = {
        region_type: (region_type_disposition[region_type], count)
        for region_type, count in region_type_count.items()
    }
    return labeled, census


def render(
    labeled_rows: list[dict],
    census: dict[str, tuple[str, int]],
    source_sha: str,
    total_rows: int,
) -> str:
    labeled_rows = sorted(
        labeled_rows,
        key=lambda row: (row["lesson"], row["byte_start"], row["byte_end"], row["region_type"]),
    )
    assessing = sum(1 for row in labeled_rows if row["label"] == "assessing")
    advancing = sum(1 for row in labeled_rows if row["label"] == "advancing")
    excluded = total_rows - len(labeled_rows)
    lessons_covered = len({row["lesson"] for row in labeled_rows})

    lines = [
        "/** <module> Generated assessing/advancing labels for K-5 teacher questions",
        " *",
        " * One row per teacher question from",
        " * curriculum/im/generated/structure_teacher_questions.jsonl whose",
        " * region_type has a literal counterpart in the deterministic heading",
        " * rule at " + HEADING_RULE_SOURCE + " (assessing_heading_order,",
        " * advancing_heading_order), or is named in AUTHOR_HEADING_OVERRIDES",
        " * below because the region_type string is itself a published IM",
        " * section title naming a questioning function. A region_type in",
        " * neither set carries no fact here; it is counted, by name, in",
        " * teacher_question_region_type_disposition/3 and in the summary below.",
        " * No mapping is inferred from a region_type's name alone -- a shared",
        " * word is never grounds for a match, only a literal heading identity",
        " * or an author's own section title is.",
        " *",
        " * label_origin distinguishes the two warrants a labeled row can carry:",
        " * machine_classification (the region_type matched the heading rule)",
        " * or author_heading(Title) (the region_type is itself Title, the IM",
        " * curriculum's own name for the section, per a controller ruling",
        " * 2026-08-18 -- see AUTHOR_HEADING_OVERRIDES). Both keep",
        " * review_status(pending_human_review): the upstream local model still",
        " * assigned the row to its section; only the section's own name is not",
        " * the model's invention.",
        " *",
        " * Source scope: K-5 plus two grade-6 lessons. Grades 6-8 guides are not",
        " * represented in the source store and carry no rows here.",
        " *",
        " * source_byte_span/2 fields are copied from the source store's",
        " * byte_start/byte_end. Despite the name, these are UTF-8 character",
        " * offsets from Python string indexing, not raw byte offsets --",
        " * see scripts/curriculum/structure_to_task_rows.py `find_verbatim`.",
        " * A row's span, read against the UTF-8-decoded source file, reproduces",
        " * its text exactly or under the source builder's own verbatim match",
        " * (scripts/curriculum/structure_to_task_rows.py `find_verbatim`, which",
        " * tolerates the column extract's variable inter-word spacing); never",
        " * bytewise.",
        " *",
        " * Generated by scripts/questions/build_assessing_advancing_labels.py",
        " * from curriculum/im/generated/structure_teacher_questions.jsonl",
        f" * (sha256 {source_sha}). Do not edit by hand.",
        " */",
        ":- module(structure_teacher_question_labels,",
        "          [ teacher_question_label/2,",
        "            teacher_question_region_type_disposition/3,",
        "            teacher_question_label_summary/1",
        "          ]).",
        "",
        "teacher_question_label_summary(",
        "    summary{",
        f"      source_file: {prolog_atom('curriculum/im/generated/structure_teacher_questions.jsonl')},",
        f"      source_file_sha256: {prolog_atom(source_sha)},",
        f"      heading_rule_source: {prolog_atom(HEADING_RULE_SOURCE)},",
        f"      source_rows: {total_rows},",
        f"      lessons_covered: {lessons_covered},",
        "      scope: k5_plus_two_grade6_lessons,",
        f"      labeled_rows: {len(labeled_rows)},",
        f"      assessing: {assessing},",
        f"      advancing: {advancing},",
        f"      excluded_rows: {excluded}",
        "    }).",
        "",
    ]

    for region_type in sorted(census):
        disposition, count = census[region_type]
        lines.append(
            "teacher_question_region_type_disposition("
            f"{prolog_atom(region_type)}, {disposition}, {count})."
        )
    lines.append("")

    for row in labeled_rows:
        lines.append("teacher_question_label(")
        lines.append(f"    {prolog_atom(row['lesson'])},")
        lines.append(
            "    labeled_question("
            f"{row['label']}, "
            f"{prolog_string(row['text'])}, "
            f"region_type({prolog_atom(row['region_type'])}), "
            f"source_path({prolog_atom(row['path'])}), "
            f"source_file_sha256({prolog_atom(row['file_sha256'])}), "
            f"source_byte_span({row['byte_start']}, {row['byte_end']}), "
            f"{render_label_origin(row['label_origin'])}, "
            "review_status(pending_human_review)))."
        )
        lines.append("")

    return "\n".join(lines).rstrip("\n") + "\n"


def main() -> int:
    rows = load_rows(SOURCE)
    labeled_rows, census = classify(rows)
    source_sha = file_sha256(SOURCE)
    rendered = render(labeled_rows, census, source_sha, len(rows))
    OUTPUT.write_text(rendered, encoding="utf-8")

    assessing = sum(1 for row in labeled_rows if row["label"] == "assessing")
    advancing = sum(1 for row in labeled_rows if row["label"] == "advancing")
    print(f"source rows: {len(rows)}")
    print(f"labeled: {len(labeled_rows)} (assessing {assessing}, advancing {advancing})")
    print(f"excluded: {len(rows) - len(labeled_rows)}")
    print(f"written: {OUTPUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
