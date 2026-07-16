"""Read roster.csv and produce a name list Gemma can match against.

The roster CSV needs at minimum:

  Sortable Name      e.g. "Doe, Jane"
  User Login         e.g. jdoe

If the file already has `first_name`, `last_name`, `student_id` columns,
those are honored. Otherwise we derive them from Sortable Name (and use
the User Login as the stable `student_id`).

This module deliberately does NOT do fuzzy matching against student
names found in discussion text. That is Gemma's job in the parse stage.
"""

from __future__ import annotations

import csv
from dataclasses import dataclass
from pathlib import Path


@dataclass
class Student:
    student_id: str
    first_name: str
    last_name: str
    sortable_name: str
    user_login: str

    def display(self) -> str:
        return f"{self.first_name} {self.last_name}".strip()

    def file_slug(self) -> str:
        last = (self.last_name or "Unknown").replace(" ", "")
        first = (self.first_name or self.user_login or "Student").replace(" ", "")
        return f"{last}_{first}"


def _split_sortable(name: str) -> tuple[str, str]:
    if "," in name:
        last, _, first = name.partition(",")
        return last.strip(), first.strip()
    parts = name.strip().split()
    if not parts:
        return "", ""
    return parts[-1], " ".join(parts[:-1]).strip()


def read_roster(path: Path) -> list[Student]:
    if not path.exists():
        return []
    rows: list[Student] = []
    with path.open("r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        for r in reader:
            sortable = (r.get("Sortable Name") or r.get("sortable_name") or "").strip()
            login = (r.get("User Login") or r.get("user_login") or "").strip()
            if not sortable and not login:
                continue
            first = (r.get("first_name") or "").strip()
            last = (r.get("last_name") or "").strip()
            if not (first or last):
                last, first = _split_sortable(sortable)
            sid = (r.get("student_id") or login or sortable or "").strip()
            if not sid:
                continue
            rows.append(Student(
                student_id=sid,
                first_name=first,
                last_name=last,
                sortable_name=sortable or f"{last}, {first}".strip(", "),
                user_login=login,
            ))
    return rows


def roster_block_for_gemma(students: list[Student]) -> str:
    lines = []
    for s in students:
        lines.append(f"- student_id={s.student_id} | name={s.display()} | login={s.user_login}")
    return "\n".join(lines) if lines else "(empty)"
