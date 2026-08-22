#!/usr/bin/env python3
"""Seed dated consumption attestations from one completed total audit."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
DEFAULT_AUDIT_DIR = REPO / ".bigred-collected/2026-08-19-total-audit"
DEFAULT_OUTPUT = REPO / "knowledge/index/consumption_attested_run2.pl"
AUDIT_TAG = "run2-2026-08-20"


def evidence_for(row: dict[str, object]) -> str | None:
    covered = int(row.get("covered_clauses", 0))
    if covered > 0:
        return f"covered({covered})"
    if row.get("python_read_at_request"):
        return "python_request"
    if row.get("python_read_at_startup"):
        return "python_startup"
    return None


def render(ledger_path: Path) -> str:
    ledger = json.loads(ledger_path.read_text(encoding="utf-8"))
    rows: list[tuple[str, str]] = []
    for row in ledger["files"]:
        if row["bucket"] not in {"fact_stores", "quarantine"}:
            continue
        evidence = evidence_for(row)
        if evidence is not None:
            rows.append((row["path"], evidence))
    rows.sort()

    lines = [
        "/** <module> Dated run-2 consumption attestations",
        " *",
        " * Seeded from the gitignored local source",
        " * .bigred-collected/2026-08-19-total-audit/audit_ledger.json on",
        " * 2026-08-22. Refresh this file only against a newer completed audit.",
        " * A dated attestation does not detect a consumer that stops reading after",
        " * the audit. A later audit or an authored lifecycle row covers that change.",
        " */",
        "",
        "% store_consumption_attested(Store, AuditTag, Evidence).",
        "% Evidence is covered(NClauses), python_request, or python_startup.",
        "",
    ]
    lines.extend(
        f"store_consumption_attested('{path}', '{AUDIT_TAG}', {evidence})."
        for path, evidence in rows
    )
    lines.append("")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--audit-dir", type=Path, default=DEFAULT_AUDIT_DIR)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    ledger_path = args.audit_dir / "audit_ledger.json"
    if not ledger_path.is_file():
        parser.error(f"audit ledger is absent: {ledger_path}")
    args.output.write_text(render(ledger_path), encoding="utf-8")
    print(f"seeded {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
