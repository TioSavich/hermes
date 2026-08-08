#!/usr/bin/env python3
"""Load the frozen StepVerify pairs without exposing target-bearing fields."""
from __future__ import annotations

import hashlib
import json
import os
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable, Iterator, Mapping, Sequence


ROOT = Path(__file__).resolve().parents[3]
RESEARCH = ROOT / "scripts/research"
SUMMARY = RESEARCH / "quantity_binding_out/summary.json"
SUMMARY_SHA256 = "fbbde82688bcbbd749babcb557d3260ee072f5dee586a48a52c26fee0a3a0cd0"
TASK = "mistake_location"
SPLIT = "dev"
LIMIT = 60
EXCLUDED_FIELDS = frozenset({
    "incorrect_index",
    "incorrect_step",
    "error_category",
    "error_description",
    "dialog_history",
    "student_correct_response",
})
ALLOWED_FIELDS = frozenset({
    "problem",
    "student_incorrect_solution",
    "reference_solution",
})


@dataclass(frozen=True)
class RunItem:
    """One isolated arm input after the final-answer line is removed."""

    index: int
    side: str
    problem: str
    steps: tuple[str, ...]

    @property
    def key(self) -> tuple[int, str]:
        return self.index, self.side


def _stored_indexes(path: Path = SUMMARY) -> list[int]:
    payload = path.read_bytes()
    digest = hashlib.sha256(payload).hexdigest()
    if digest != SUMMARY_SHA256:
        raise RuntimeError(
            f"frozen index artifact sha256 mismatch: expected {SUMMARY_SHA256}, got {digest}"
        )
    value = json.loads(payload)
    indexes = value.get("indexes")
    if (
        not isinstance(indexes, list)
        or len(indexes) != LIMIT
        or any(isinstance(index, bool) or not isinstance(index, int) for index in indexes)
        or len(set(indexes)) != LIMIT
    ):
        raise RuntimeError("frozen index artifact does not hold 60 distinct integer indexes")
    return indexes


def _safe_row(row: Mapping[str, Any]) -> dict[str, Any]:
    leaked = sorted(EXCLUDED_FIELDS.intersection(row))
    if leaked:
        raise ValueError("excluded dataset field present: " + ", ".join(leaked))
    missing = sorted(ALLOWED_FIELDS.difference(row))
    if missing:
        raise ValueError("dataset row is missing required field: " + ", ".join(missing))
    return {name: row[name] for name in ALLOWED_FIELDS}


def _drop_incorrect_final(value: Any) -> tuple[str, ...]:
    if not isinstance(value, Sequence) or isinstance(value, (str, bytes)):
        raise TypeError("student_incorrect_solution must be a sequence of strings")
    lines = list(value)
    if any(not isinstance(line, str) for line in lines):
        raise TypeError("student_incorrect_solution must contain only strings")
    return tuple(lines[:-1])


def _drop_reference_final(value: Any) -> tuple[str, ...]:
    if not isinstance(value, str):
        raise TypeError("reference_solution must be a string")
    return tuple(value.splitlines()[:-1])


def pair_from_row(index: int, row: Mapping[str, Any]) -> tuple[RunItem, RunItem]:
    """Return isolated incorrect and correct inputs from one guarded row."""
    safe = _safe_row(row)
    problem = safe["problem"]
    if not isinstance(problem, str):
        raise TypeError("problem must be a string")
    incorrect = RunItem(
        index=index,
        side="incorrect",
        problem=problem,
        steps=_drop_incorrect_final(safe["student_incorrect_solution"]),
    )
    correct = RunItem(
        index=index,
        side="correct",
        problem=problem,
        steps=_drop_reference_final(safe["reference_solution"]),
    )
    return incorrect, correct


def items_from_rows(
    rows: Iterable[tuple[int, Mapping[str, Any]]],
) -> Iterator[RunItem]:
    """Guard each raw row before yielding either arm input."""
    for index, row in rows:
        yield from pair_from_row(index, row)


def load_corpus() -> list[RunItem]:
    """Load the offline dataset and verify its regenerated frozen selection."""
    if os.environ.get("HF_HUB_OFFLINE") != "1":
        raise RuntimeError("HF_HUB_OFFLINE=1 is required")
    stored = _stored_indexes()
    if str(RESEARCH) not in sys.path:
        sys.path.insert(0, str(RESEARCH))
    from datasets import load_dataset
    import mtb_official_runner

    raw = load_dataset("eth-nlped/stepverify", "default", split="train")
    regenerated = mtb_official_runner.select_indexes(TASK, len(raw), SPLIT, LIMIT, 0)
    if regenerated != stored:
        raise RuntimeError(
            "frozen index reproduction mismatch: "
            f"stored={stored!r} regenerated={regenerated!r}"
        )
    projected = raw.select_columns(sorted(ALLOWED_FIELDS))
    return list(items_from_rows((index, projected[index]) for index in stored))


def frozen_indexes() -> tuple[int, ...]:
    """Return the digest-checked index manifest without loading the dataset."""
    return tuple(_stored_indexes())


__all__ = [
    "EXCLUDED_FIELDS",
    "RunItem",
    "frozen_indexes",
    "items_from_rows",
    "load_corpus",
    "pair_from_row",
]
