#!/usr/bin/env python3
"""Run every fixture-only questionnaire check through slice 3."""
from __future__ import annotations

import subprocess
import sys
import tempfile
from pathlib import Path


HERE = Path(__file__).resolve().parent


def run(*arguments: str) -> None:
    subprocess.run([sys.executable, *arguments], cwd=HERE.parents[2], check=True)


def main() -> int:
    run(str(HERE / "dry_run.py"))
    run(str(HERE / "fixture_checks.py"))
    with tempfile.TemporaryDirectory(prefix="questionnaire-smoke-") as directory:
        ledger = Path(directory) / "fixture.jsonl"
        run(str(HERE / "compliance_smoke.py"), "--fixture", "--output", str(ledger))
        run(str(HERE / "check_compliance_smoke.py"), str(ledger))
    print("QUESTIONNAIRE SANDBOX VERIFICATION: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
