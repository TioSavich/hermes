#!/usr/bin/env python3
"""Append-only experiment ledger with one fsync per completed item."""
from __future__ import annotations

import json
import logging
import os
from pathlib import Path
from typing import Any, Iterable, Mapping


SCHEMA = "ab_experiment_item_v1"
ARMS = frozenset({"compiler", "questionnaire"})
SIDES = frozenset({"incorrect", "correct"})
REQUIRED = frozenset({
    "schema",
    "arm",
    "index",
    "side",
    "problem",
    "steps",
    "receipts",
    "events",
    "usage",
})
FORBIDDEN_KEYS = frozenset({
    "HUMAN_KIND_MAP",
    "incorrect_index",
    "incorrect_step",
    "error_category",
    "error_description",
    "dialog_history",
    "student_correct_response",
})
LOGGER = logging.getLogger(__name__)


def _forbidden_paths(value: Any, prefix: str = "") -> list[str]:
    found: list[str] = []
    if isinstance(value, Mapping):
        for key, child in value.items():
            name = str(key)
            path = f"{prefix}.{name}" if prefix else name
            if name in FORBIDDEN_KEYS:
                found.append(path)
            found.extend(_forbidden_paths(child, path))
    elif isinstance(value, list):
        for index, child in enumerate(value):
            found.extend(_forbidden_paths(child, f"{prefix}[{index}]"))
    return found


def key_for(row: Mapping[str, Any]) -> tuple[str, int, str]:
    return str(row["arm"]), int(row["index"]), str(row["side"])


def validate_row(row: Mapping[str, Any]) -> None:
    missing = sorted(REQUIRED.difference(row))
    if missing:
        raise ValueError("ledger row is missing: " + ", ".join(missing))
    if row["schema"] != SCHEMA:
        raise ValueError(f"unsupported ledger schema: {row['schema']!r}")
    if row["arm"] not in ARMS:
        raise ValueError(f"invalid arm: {row['arm']!r}")
    if row["side"] not in SIDES:
        raise ValueError(f"invalid side: {row['side']!r}")
    if isinstance(row["index"], bool) or not isinstance(row["index"], int):
        raise ValueError("ledger index must be an integer")
    if not isinstance(row["problem"], str):
        raise ValueError("ledger problem must be a string")
    if not isinstance(row["steps"], list) or any(
        not isinstance(step, str) for step in row["steps"]
    ):
        raise ValueError("ledger steps must be a list of strings")
    if not isinstance(row["receipts"], list) or not isinstance(row["events"], list):
        raise ValueError("ledger receipts and events must be lists")
    usage = row["usage"]
    if not isinstance(usage, Mapping):
        raise ValueError("ledger usage must be an object")
    for name in ("model_calls", "prompt_tokens", "completion_tokens", "total_tokens"):
        value = usage.get(name)
        if isinstance(value, bool) or not isinstance(value, int) or value < 0:
            raise ValueError(f"ledger usage {name} must be a non-negative integer")
    forbidden = _forbidden_paths(row)
    if forbidden:
        raise ValueError("forbidden ledger field present: " + ", ".join(forbidden))


def _scan_rows(
    path: Path, *, allow_torn_final: bool,
) -> tuple[list[dict[str, Any]], int | None]:
    if not path.exists():
        return [], None
    rows: list[dict[str, Any]] = []
    data = path.read_bytes()
    lines = data.splitlines(keepends=True)
    nonempty = [index for index, line in enumerate(lines) if line.strip()]
    last_nonempty = nonempty[-1] if nonempty else -1
    offset = 0
    last_valid_end = 0
    for index, line in enumerate(lines):
        if not line.strip():
            offset += len(line)
            continue
        line_number = index + 1
        try:
            row = json.loads(line)
        except (json.JSONDecodeError, UnicodeDecodeError) as exc:
            if allow_torn_final and index == last_nonempty:
                LOGGER.warning(
                    "torn final JSONL line scheduled for repair at %s:%s",
                    path,
                    line_number,
                )
                return rows, last_valid_end
            raise ValueError(f"invalid JSONL at {path}:{line_number}: {exc}") from exc
        if not isinstance(row, dict):
            raise ValueError(f"ledger row at {path}:{line_number} is not an object")
        validate_row(row)
        rows.append(row)
        offset += len(line)
        last_valid_end = offset
    return rows, None


def read_rows(path: Path) -> list[dict[str, Any]]:
    rows, unused_repair_offset = _scan_rows(path, allow_torn_final=False)
    assert unused_repair_offset is None
    return rows


class AppendLedger:
    """Scan completed keys once and append each new key at most once."""

    def __init__(self, path: Path) -> None:
        self.path = path
        self.rows, self._repair_offset = _scan_rows(path, allow_torn_final=True)
        keys = [key_for(row) for row in self.rows]
        if len(keys) != len(set(keys)):
            raise ValueError(f"ledger has duplicate completed keys: {path}")
        self.completed = set(keys)

    def append(self, row: dict[str, Any]) -> bool:
        validate_row(row)
        key = key_for(row)
        if key in self.completed:
            return False
        self.path.parent.mkdir(parents=True, exist_ok=True)
        if self._repair_offset is not None:
            with self.path.open("r+b") as stream:
                stream.truncate(self._repair_offset)
                stream.flush()
                os.fsync(stream.fileno())
            LOGGER.warning(
                "repaired torn final JSONL tail before append at %s:%s",
                self.path,
                self._repair_offset,
            )
            self._repair_offset = None
        encoded = json.dumps(row, ensure_ascii=False, sort_keys=True) + "\n"
        with self.path.open("a", encoding="utf-8") as stream:
            stream.write(encoded)
            stream.flush()
            os.fsync(stream.fileno())
        self.completed.add(key)
        self.rows.append(row)
        return True

    def has(self, arm: str, index: int, side: str) -> bool:
        return (arm, index, side) in self.completed


def combined_rows(paths: Iterable[Path]) -> list[dict[str, Any]]:
    rows = [row for path in paths for row in read_rows(path)]
    keys = [key_for(row) for row in rows]
    if len(keys) != len(set(keys)):
        raise ValueError("input ledgers contain duplicate completed keys")
    return rows


__all__ = ["AppendLedger", "SCHEMA", "combined_rows", "read_rows", "validate_row"]
