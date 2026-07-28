#!/usr/bin/env python3
"""Generate the admitted misconception rows from the shared research corpus."""
from __future__ import annotations

import argparse
import difflib
import sqlite3
import sys
import tempfile
from collections import Counter
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATABASE = ROOT / "data" / "research" / "research_shared.db"
OUTPUT = ROOT / "knowledge" / "misconceptions" / "research_corpus_misconceptions.pl"

# The project-facing db_row keys for the high research-corpus id range were
# minted before the shared database was renumbered. Keep that public key space
# stable while recording the canonical database id alongside each row.
LEGACY_DATABASE_ID_MIN = 43_994
LEGACY_DATABASE_ID_OFFSET = 6_560


@dataclass(frozen=True)
class CorpusRow:
    database_id: int
    public_id: int
    error_description: str
    example: str
    domain: str
    topic: str
    subtopic: str
    population: str
    grade_band: str
    bibtex_key: str
    authors: str
    year: str
    journal: str
    orientation: str
    salience: str
    page_refs: str
    local_pdf_path: str


def text(value: object | None) -> str:
    return "" if value is None else str(value)


def atom(value: str) -> str:
    return "'" + value.replace("\\", "\\\\").replace("'", "''") + "'"


def public_id(database_id: int) -> int:
    if database_id >= LEGACY_DATABASE_ID_MIN:
        return database_id - LEGACY_DATABASE_ID_OFFSET
    return database_id


def admitted(row: sqlite3.Row) -> bool:
    return bool(
        text(row["mathematical_domain"]).strip()
        and text(row["error_description"]).strip()
        and text(row["bibtex_key"]).strip()
    )


def exclusion_reasons(row: sqlite3.Row) -> tuple[str, ...]:
    reasons = []
    if not text(row["mathematical_domain"]).strip():
        reasons.append("missing_domain")
    if not text(row["error_description"]).strip():
        reasons.append("missing_description")
    if not text(row["bibtex_key"]).strip():
        reasons.append("unresolvable_article")
    return tuple(reasons)


def load_rows() -> tuple[list[CorpusRow], list[tuple[int, str]]]:
    if not DATABASE.is_file():
        raise RuntimeError(f"research corpus database is absent: {DATABASE.relative_to(ROOT)}")
    connection = sqlite3.connect(DATABASE)
    connection.row_factory = sqlite3.Row
    try:
        source_rows = connection.execute(
            """
            SELECT e.id AS database_id,
                   e.error_description,
                   e.example,
                   e.mathematical_domain,
                   e.mathematical_topic,
                   e.mathematical_subtopic,
                   a.population_type,
                   a.grade_band_as_declared,
                   a.bibtex_key,
                   a.authors,
                   a.year,
                   a.journal,
                   e.orientation,
                   e.salience,
                   e.page_refs,
                   a.local_pdf_path
              FROM error_instances AS e
              LEFT JOIN articles AS a ON a.id = e.article_id
             ORDER BY e.id
            """
        ).fetchall()
    finally:
        connection.close()

    rows: list[CorpusRow] = []
    exclusions: list[tuple[int, str]] = []
    for source in source_rows:
        database_id = int(source["database_id"])
        reasons = exclusion_reasons(source)
        if admitted(source):
            rows.append(CorpusRow(
                database_id=database_id,
                public_id=public_id(database_id),
                error_description=text(source["error_description"]),
                example=text(source["example"]),
                domain=text(source["mathematical_domain"]),
                topic=text(source["mathematical_topic"]),
                subtopic=text(source["mathematical_subtopic"]),
                population=text(source["population_type"]),
                grade_band=text(source["grade_band_as_declared"]),
                bibtex_key=text(source["bibtex_key"]),
                authors=text(source["authors"]),
                year=text(source["year"]),
                journal=text(source["journal"]),
                orientation=text(source["orientation"]),
                salience=text(source["salience"]),
                page_refs=text(source["page_refs"]),
                local_pdf_path=text(source["local_pdf_path"]),
            ))
        for reason in reasons:
            exclusions.append((database_id, reason))

    if len(rows) + len({database_id for database_id, _reason in exclusions}) != len(source_rows):
        raise RuntimeError("admission and exclusion rows do not cover the research corpus")
    public_ids = [row.public_id for row in rows]
    if len(public_ids) != len(set(public_ids)):
        raise RuntimeError("database-to-public misconception row mapping is not one-to-one")
    return rows, exclusions


def row_term(row: CorpusRow) -> str:
    fields = (
        row.public_id, row.error_description, row.example, row.domain, row.topic,
        row.subtopic, row.population, row.grade_band, row.bibtex_key, row.authors,
        row.year, row.journal, row.orientation, row.salience, row.page_refs,
        row.local_pdf_path,
    )
    rendered = [str(fields[0])] + [atom(value) for value in fields[1:]]
    return "row(" + ", ".join(rendered) + ")"


def render_registry() -> str:
    rows, exclusions = load_rows()
    exclusion_counts = Counter(reason for _database_id, reason in exclusions)
    excluded_database_ids = {database_id for database_id, _reason in exclusions}
    lines = [
        "/** <module> Generated research-corpus misconception rows",
        " *",
        " * This finite registry is generated from data/research/research_shared.db.",
        " * A row is admitted when error_instances supplies a non-empty mathematical",
        " * domain and error description, and its joined articles row supplies a",
        " * resolvable non-empty bibtex_key. The generated row preserves the existing",
        " * public db_row key: high database ids use public_id = database_id - 6560;",
        " * lower ids retain their database id. canonical_database_id/2 records both.",
        " *",
        " * Excluded database rows remain typed data. A row can carry more than one",
        " * reason: missing_domain, missing_description, or unresolvable_article.",
        " *",
        " * Generated by scripts/extract_research_corpus_misconceptions.py.",
        " * Regenerate: python3 scripts/extract_research_corpus_misconceptions.py",
        " */",
        "",
        ":- module(research_corpus_misconceptions,",
        "          [ research_corpus_misconception_row/1,",
        "            canonical_database_id/2,",
        "            research_corpus_row_count/1,",
        "            research_corpus_excluded_row_count/1,",
        "            research_corpus_exclusion/2,",
        "            research_corpus_exclusion_count/2",
        "          ]).",
        "",
        f"research_corpus_row_count({len(rows)}).",
        f"research_corpus_excluded_row_count({len(excluded_database_ids)}).",
    ]
    for reason in ("missing_domain", "missing_description", "unresolvable_article"):
        lines.append(f"research_corpus_exclusion_count({reason}, {exclusion_counts[reason]}).")
    lines.append("")
    for row in rows:
        lines.append(f"research_corpus_misconception_row({row_term(row)}).")
    lines.append("")
    for row in rows:
        lines.append(f"canonical_database_id({row.public_id}, {row.database_id}).")
    lines.append("")
    for database_id, reason in exclusions:
        lines.append(f"research_corpus_exclusion({database_id}, {reason}).")
    lines.append("")
    return "\n".join(lines)


def check_output(expected: str, output: Path) -> int:
    actual = output.read_text(encoding="utf-8") if output.is_file() else ""
    if actual == expected:
        print(f"research corpus misconception registry is current: {output.relative_to(ROOT)}")
        return 0
    with tempfile.NamedTemporaryFile("w", encoding="utf-8", suffix=".pl", delete=False) as temporary:
        temporary.write(expected)
        temporary_path = Path(temporary.name)
    diff = list(difflib.unified_diff(actual.splitlines(), expected.splitlines(),
                                     fromfile=str(output), tofile=str(temporary_path), lineterm=""))
    print("research corpus misconception registry is stale; run python3 scripts/extract_research_corpus_misconceptions.py", file=sys.stderr)
    for line in diff[:12]:
        print(line, file=sys.stderr)
    temporary_path.unlink(missing_ok=True)
    return 1


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="fail if the generated registry is stale")
    parser.add_argument("--output", type=Path, default=OUTPUT, help=argparse.SUPPRESS)
    args = parser.parse_args()
    output = args.output if args.output.is_absolute() else ROOT / args.output
    rendered = render_registry()
    if args.check:
        return check_output(rendered, output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(rendered, encoding="utf-8")
    print(f"wrote {output.relative_to(ROOT)}: {len(rendered.splitlines())} lines")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
