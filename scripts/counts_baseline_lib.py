#!/usr/bin/env python3
"""Read count expectations from the generated repository baseline."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
BASELINE_PATH = ROOT / "data/research/counts_baseline.json"
ENTRY_FIELDS = {"value", "derivation", "producer", "carried"}


class BaselineError(RuntimeError):
    """The baseline is absent or does not follow its declared entry schema."""


class BaselineInputUnavailable(BaselineError):
    """A local input needed to derive a count is absent or stale."""


def load_baseline(path: Path = BASELINE_PATH) -> dict[str, dict[str, Any]]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise BaselineError(f"cannot read {path}: {exc}") from exc
    if not isinstance(data, dict) or not data:
        raise BaselineError(f"{path} must contain a nonempty object")
    for key, entry in data.items():
        if not isinstance(key, str) or not key:
            raise BaselineError(f"{path} contains an invalid entry key")
        if not isinstance(entry, dict):
            raise BaselineError(f"{key} must be an object")
        missing = ENTRY_FIELDS - set(entry)
        if missing:
            raise BaselineError(f"{key} lacks fields: {sorted(missing)}")
        if not isinstance(entry["value"], int) or isinstance(entry["value"], bool):
            raise BaselineError(f"{key}.value must be an integer")
        if not isinstance(entry["derivation"], str) or not entry["derivation"]:
            raise BaselineError(f"{key}.derivation must be a nonempty string")
        if not isinstance(entry["producer"], str) or not entry["producer"]:
            raise BaselineError(f"{key}.producer must be a nonempty string")
        if not isinstance(entry["carried"], bool):
            raise BaselineError(f"{key}.carried must be boolean")
        reason = entry.get("carry_reason")
        if entry["carried"] and (not isinstance(reason, str) or not reason):
            raise BaselineError(f"{key}.carry_reason must explain a carried value")
        if not entry["carried"] and "carry_reason" in entry:
            raise BaselineError(f"{key}.carry_reason is only valid when carried")
    return data


def baseline_value(key: str) -> int:
    data = load_baseline()
    try:
        return data[key]["value"]
    except KeyError as exc:
        raise BaselineError(f"baseline lacks {key}") from exc

