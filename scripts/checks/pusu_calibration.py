#!/usr/bin/env python3
"""Fail when the recorded engine-only PUSU calibration verdicts drift."""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
HARNESS = ROOT / "scripts/curriculum/pusu_pass.py"

# Recorded 2026-07-29 from the engine-only calibration pass.  These are
# capability verdicts, not the hand audit's provenance/attestation judgments.
BASELINE = {
    "IM-G1-U5-L5": "broken(contrast_cannot_run)",
    "IM-G2-U9-L1": "broken(contrast_cannot_run)",
    "IM-G4-U5-L3": "pass",
    "IM-G5-U4-L5": "broken(contrast_vacuous)",
    "IM-G2-U7-L15": "broken(contrast_cannot_run)",
    "IM-G7-U5-L1": "broken(execute_mismatch)",
    "IM-GK-U5-L7": "broken(diagnosis_missed)",
}


def main() -> int:
    result = subprocess.run(
        [sys.executable, str(HARNESS), "--calibration", "--stdout"],
        cwd=ROOT, text=True, capture_output=True, check=False, timeout=120,
    )
    if result.returncode:
        print(result.stderr, file=sys.stderr)
        return result.returncode
    document = json.loads(result.stdout)
    actual = {row["lesson"]: row["pusu"] for row in document["rows"]}
    if actual != BASELINE:
        print("FAIL pusu calibration drift", file=sys.stderr)
        print(json.dumps({"expected": BASELINE, "actual": actual}, indent=2, sort_keys=True), file=sys.stderr)
        return 1
    print("PASS pusu calibration")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
