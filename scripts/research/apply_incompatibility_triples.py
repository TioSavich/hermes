#!/usr/bin/env python3
"""Write reviewed incompatibility triples into the research corpus of record.

Extraction proposes and a human reviews; this step writes. Keeping the two apart
means the database is never the place a coding is first seen. The input is the
tracked reviewed file under data/research/, not the gitignored proposal
directory, so a rerun writes exactly what was reviewed.

The write is idempotent: it sets the same four columns to the same values every
time, and it adds `valid_domain_status` if the schema does not carry it yet.
That column exists so NULL in `valid_domain` never has to mean two things at
once — a rule with no domain of validity is a result, and an uncoded row is not.
"""

from __future__ import annotations

import argparse
import json
import sqlite3
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DB = ROOT / "data" / "research" / "research_shared.db"
REVIEWED = ROOT / "data" / "research" / "incompatibility_triples.json"

STATUS_VALUES = ("stated", "inferred", "none_found", "not_yet_coded")
COLUMN_SQL = (
    "ALTER TABLE error_instances ADD COLUMN valid_domain_status TEXT "
    "NOT NULL DEFAULT 'not_yet_coded' "
    f"CHECK(valid_domain_status IN ({', '.join(repr(value) for value in STATUS_VALUES)}))"
)


def column_present(connection: sqlite3.Connection) -> bool:
    return any(
        row[1] == "valid_domain_status"
        for row in connection.execute("PRAGMA table_info(error_instances)")
    )


def load_reviewed(path: Path) -> dict:
    payload = json.loads(path.read_text(encoding="utf-8"))
    codings = payload["codings"]
    seen: set[int] = set()
    for coding in codings:
        row_id = coding["row_id"]
        if row_id in seen:
            raise SystemExit(f"reviewed file names row {row_id} twice")
        seen.add(row_id)
        if coding["valid_domain_status"] not in {"stated", "inferred", "none_found"}:
            raise SystemExit(f"row {row_id} carries an unwritable status")
        if coding["valid_domain_status"] == "none_found" and coding["valid_domain"]:
            raise SystemExit(f"row {row_id} is none_found and carries a domain")
        if coding["valid_domain_status"] != "none_found" and not coding["valid_domain"]:
            raise SystemExit(f"row {row_id} claims a domain status without a domain")
        for field in ("student_rule", "incompatible_with"):
            if not (coding.get(field) or "").strip():
                raise SystemExit(f"row {row_id} has an empty {field}")
    return payload


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--reviewed", default=str(REVIEWED))
    parser.add_argument("--commit", action="store_true", help="write; without it, report the plan only")
    arguments = parser.parse_args()

    payload = load_reviewed(Path(arguments.reviewed))
    codings = payload["codings"]
    statuses = Counter(coding["valid_domain_status"] for coding in codings)
    slices = ", ".join(
        f"{entry['slice']} ({entry['rows_in_slice']} rows)" for entry in payload["slices"]
    )
    print(f"reviewed slices: {slices}; codings: {len(codings)}")
    print(f"valid_domain_status: {dict(statuses)}")

    connection = sqlite3.connect(DB)
    try:
        has_column = column_present(connection)
        print(f"valid_domain_status column present: {has_column}")
        row_ids = [coding["row_id"] for coding in codings]
        placeholders = ", ".join("?" for _ in row_ids)
        known = {
            row[0]
            for row in connection.execute(
                f"SELECT id FROM error_instances WHERE id IN ({placeholders})", row_ids
            )
        }
        missing = sorted(set(row_ids) - known)
        if missing:
            raise SystemExit(f"reviewed file names rows absent from the corpus: {missing}")
        if not arguments.commit:
            print(f"plan: add column={not has_column}; update {len(row_ids)} rows. Rerun with --commit.")
            return 0
        with connection:
            if not has_column:
                connection.execute(COLUMN_SQL)
            connection.executemany(
                """
                UPDATE error_instances
                   SET student_rule = ?, valid_domain = ?, valid_domain_status = ?,
                       incompatible_with = ?
                 WHERE id = ?
                """,
                [
                    (
                        coding["student_rule"],
                        coding["valid_domain"],
                        coding["valid_domain_status"],
                        coding["incompatible_with"],
                        coding["row_id"],
                    )
                    for coding in codings
                ],
            )
        written = connection.execute(
            "SELECT count(*) FROM error_instances WHERE valid_domain_status != 'not_yet_coded'"
        ).fetchone()[0]
        filled = connection.execute(
            "SELECT count(*) FROM error_instances "
            "WHERE incompatible_with IS NOT NULL AND trim(incompatible_with) != ''"
        ).fetchone()[0]
        print(f"written: valid_domain_status coded on {written} rows; incompatible_with on {filled}")
    finally:
        connection.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
