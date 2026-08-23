#!/usr/bin/env python3
"""Check that the generated page index covers every shipped HTML entrance."""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def main() -> int:
    completed = subprocess.run(
        [sys.executable, str(ROOT / "scripts" / "build_html_surface_index.py"), "--check"],
        cwd=ROOT,
    )
    if completed.returncode:
        return completed.returncode
    dry_run = subprocess.run(
        ["bash", str(ROOT / "scripts" / "regen_all.sh"), "--dry-run"],
        cwd=ROOT, capture_output=True, text=True, check=True,
    ).stdout
    command = "python3 scripts/build_html_surface_index.py"
    if command not in dry_run.splitlines():
        raise AssertionError("regen_all omits the HTML surface index builder")
    print("PASS HTML surface index regeneration wiring")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
