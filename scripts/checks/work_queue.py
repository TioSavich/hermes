#!/usr/bin/env python3
"""Validate the tracked generated work queue and its carry-forward behavior."""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
from collections import Counter
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from scripts.research import build_work_queue as builder  # noqa: E402


REQUIRED_KEYS = {"id", "title", "rows_blocked", "tier", "source", "evidence"}
OPTIONAL_KEYS = {"hint_as_of"}
TIERS = {"structural", "store", "held", "defect", "authoring"}


def fail(message: str) -> int:
    print(f"work_queue.py: {message}", file=sys.stderr)
    return 1


def validate_schema(rows: Any) -> list[str]:
    errors: list[str] = []
    if not isinstance(rows, list):
        return ["work_queue.json must contain a list"]
    identifiers: list[str] = []
    for index, row in enumerate(rows):
        label = f"entry {index}"
        if not isinstance(row, dict):
            errors.append(f"{label} is not an object")
            continue
        keys = set(row)
        missing = REQUIRED_KEYS - keys
        extra = keys - REQUIRED_KEYS - OPTIONAL_KEYS
        if missing:
            errors.append(f"{label} missing keys: {sorted(missing)}")
        if extra:
            errors.append(f"{label} has unknown keys: {sorted(extra)}")
        identifier = row.get("id")
        if not isinstance(identifier, str) or not identifier.strip():
            errors.append(f"{label} id is absent")
        else:
            identifiers.append(identifier)
        if not isinstance(row.get("title"), str) or not row["title"].strip():
            errors.append(f"{label} title is absent")
        rows_blocked = row.get("rows_blocked")
        if (
            not isinstance(rows_blocked, int)
            or isinstance(rows_blocked, bool)
            or rows_blocked < 0
        ):
            errors.append(f"{label} rows_blocked is not a nonnegative integer")
        if row.get("tier") not in TIERS:
            errors.append(f"{label} has invalid tier: {row.get('tier')!r}")
        if not isinstance(row.get("source"), str) or not row["source"].strip():
            errors.append(f"{label} source provenance is absent")
        if row.get("evidence") in (None, "", [], {}):
            errors.append(f"{label} evidence is absent")
        hint = row.get("hint_as_of")
        if hint is not None and (not isinstance(hint, str) or not hint.strip()):
            errors.append(f"{label} hint_as_of is invalid")
    duplicates = sorted(name for name, count in Counter(identifiers).items() if count > 1)
    if duplicates:
        errors.append(f"duplicate queue ids: {duplicates}")
    if isinstance(rows, list) and rows != builder.sort_entries(rows):
        errors.append("queue rows are not ranked by rows_blocked")
    return errors


def check_dedup_unit() -> None:
    rows = [
        {"id": "completed", "op": "sample", "outcome": "ok"},
        {"id": "completed", "op": "sample", "outcome": "op_circuit_open"},
        {"id": "deferred", "op": "sample", "outcome": "op_circuit_open"},
        {"id": "deferred", "op": "sample", "outcome": "refused"},
        {"id": "circuit-only", "op": "sample", "outcome": "op_circuit_open"},
    ]
    outcomes = {row["id"]: row["outcome"] for row in builder.first_terminal_rows(rows)}
    expected = {
        "completed": "ok",
        "deferred": "refused",
        "circuit-only": "op_circuit_open",
    }
    if outcomes != expected:
        raise AssertionError(f"first-terminal dedup mismatch: {outcomes}")


def notation_totals(rows: list[dict[str, Any]]) -> tuple[Counter[str], Counter[str]]:
    first = Counter(
        row["outcome"]
        for row in builder.first_terminal_rows(rows)
        if row["op"] == "notation_monitoring_chart"
    )
    last_by_id: dict[str, dict[str, Any]] = {}
    for row in rows:
        last_by_id[row["id"]] = row
    last = Counter(
        row["outcome"]
        for row in last_by_id.values()
        if row["op"] == "notation_monitoring_chart"
    )
    return first, last


def carry_forward_check(json_bytes: bytes, md_bytes: bytes) -> None:
    with tempfile.TemporaryDirectory(prefix="hermes-work-queue-check-") as directory:
        root = Path(directory)
        json_output = root / "work_queue.json"
        md_output = root / "work_queue.md"
        json_output.write_bytes(json_bytes)
        md_output.write_bytes(md_bytes)
        absent = root / "absent-audit"
        completed = subprocess.run(
            [
                sys.executable,
                str(ROOT / "scripts/research/build_work_queue.py"),
                "--audit-dir",
                str(absent),
                "--json-output",
                str(json_output),
                "--md-output",
                str(md_output),
            ],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=False,
        )
        if completed.returncode:
            raise AssertionError(
                "carry-forward invocation failed: "
                + (completed.stderr or completed.stdout).strip()
            )
        if json_output.read_bytes() != json_bytes or md_output.read_bytes() != md_bytes:
            raise AssertionError("carry-forward invocation changed a tracked output")


def main() -> int:
    try:
        tracked_json_bytes = builder.DEFAULT_JSON_OUTPUT.read_bytes()
        tracked_md_bytes = builder.DEFAULT_MD_OUTPUT.read_bytes()
        tracked = json.loads(tracked_json_bytes)
        errors = validate_schema(tracked)
        if errors:
            return fail("; ".join(errors))

        ledger = builder.DEFAULT_AUDIT_DIR / builder.AUDIT_LEDGER_NAME
        if not ledger.is_file():
            # Audit collections are local-only (gitignored); a clone can
            # validate the tracked queue's schema but cannot rebuild it.
            print(
                "SKIP work-queue rebuild: "
                f"{ledger.relative_to(builder.ROOT)} absent locally "
                "(audit collections are local-only); "
                "tracked queue schema validated"
            )
            return 0

        rebuilt, resolved, prunable = builder.build_full(builder.DEFAULT_AUDIT_DIR)
        rebuilt_json = builder.render_json(rebuilt).encode("utf-8")
        rebuilt_md = builder.render_markdown(rebuilt, resolved, prunable).encode("utf-8")
        if rebuilt_json != tracked_json_bytes:
            return fail("work_queue.json differs from a byte-stable rebuild")
        if rebuilt_md != tracked_md_bytes:
            return fail("work_queue.md differs from a byte-stable rebuild")

        check_dedup_unit()
        sweep = builder.load_sweep(builder.DEFAULT_AUDIT_DIR / builder.SWEEP_RESULTS_NAME)
        first, last = notation_totals(sweep)
        if first["ok"] <= last["ok"]:
            return fail("notation first-terminal dedup did not recover earlier successes")
        carry_forward_check(tracked_json_bytes, tracked_md_bytes)
    except (OSError, ValueError, builder.WorkQueueError, AssertionError) as exc:
        return fail(str(exc))

    def totals_text(counts: Counter[str]) -> str:
        return ", ".join(
            f"{name}={counts[name]}"
            for name in ("ok", "refused", "timeout", "op_circuit_open")
        )

    print(
        f"PASS work queue: {len(tracked)} entries; byte-stable rebuild; "
        "carry-forward unchanged"
    )
    print(f"  notation first-terminal: {totals_text(first)}")
    print(f"  notation last-write: {totals_text(last)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
