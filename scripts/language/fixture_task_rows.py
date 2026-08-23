"""Load the tracked focused language-task fixture with provenance checks."""

from __future__ import annotations

import hashlib
import json
from functools import lru_cache
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
FIXTURE = ROOT / "scripts/language/fixtures/focused_task_rows.jsonl"
SCHEMA = "language_focused_task_rows_v1"
LEGACY_GUIDES = (
    "hermes/app/runtime/experiments/gemma4_tutor/docling/full-output/"
    "TeacherLessonGuides/"
)
TRACKED_GUIDES = "curriculum/im_teacher_guides_docling/"
FORBIDDEN_KEYS = {"sort", "sort_type", "lexical_type", "lemma_type"}


def _forbidden_key(value: object) -> str | None:
    if isinstance(value, dict):
        for key, member in value.items():
            if str(key).lower() in FORBIDDEN_KEYS:
                return str(key)
            found = _forbidden_key(member)
            if found:
                return found
    elif isinstance(value, list):
        for member in value:
            found = _forbidden_key(member)
            if found:
                return found
    return None


@lru_cache(maxsize=1)
def load_fixture_rows() -> list[dict[str, Any]]:
    payloads = [
        json.loads(line)
        for line in FIXTURE.read_text(encoding="utf-8").splitlines()
        if line.strip()
    ]
    if not payloads or set(payloads[0]) != {"fixture"}:
        raise ValueError("language fixture lacks its provenance header")
    header = payloads[0]["fixture"]
    if header.get("schema") != SCHEMA:
        raise ValueError(f"language fixture schema must be {SCHEMA}")
    rows = payloads[1:]
    ids = [str(row.get("id")) for row in rows]
    if ids != header.get("row_ids") or len(ids) != len(set(ids)):
        raise ValueError("language fixture row_ids do not match its rows")
    forbidden = _forbidden_key(payloads)
    if forbidden:
        raise ValueError(f"language fixture contains forbidden field {forbidden}")
    for row in rows:
        spans = row["source_statement_spans"]
        for span in spans:
            path = str(span["path"])
            if path.startswith(LEGACY_GUIDES):
                span["path"] = TRACKED_GUIDES + path.removeprefix(LEGACY_GUIDES)
        row["source_spans"] = spans
        row["statement_spans"] = spans
        row["statement_joiner"] = " "
    return rows


def fixture_row(record_id: str) -> dict[str, Any]:
    return next(row for row in load_fixture_rows() if row["id"] == record_id)


def fixture_source_hashes() -> dict[str, str]:
    return {FIXTURE.name: hashlib.sha256(FIXTURE.read_bytes()).hexdigest()}
