#!/usr/bin/env python3
"""Fail when the recorded engine-only PUSU calibration verdicts drift."""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
HARNESS = ROOT / "scripts/curriculum/pusu_pass.py"

# Re-pinned 2026-07-29 after material contrast semantics v2.  The G5 anchor
# now records validated single-digit-multiplier viability rather than treating
# agreement on x3 as a vacuous attachment.
# These are capability verdicts, not the hand audit's provenance/attestation
# judgments.
BASELINE = {
    # Receipt route now executes make_ten_drop_leftover on the compiled task.
    "IM-G1-U5-L5": "pass",
    # Receipt route now executes answer_as_endpoint_count_up on compiled tasks.
    "IM-G2-U9-L1": "pass",
    "IM-G4-U5-L3": "pass",
    "IM-G5-U4-L5": "pass",
    "IM-G2-U7-L15": "broken(contrast_cannot_run)",
    # Receipt route now runs after the 60-second productive path clears this casualty.
    "IM-G7-U5-L1": "pass",
    # Task 177 removed the manufactured IM-GK-U5-L7 task/deformation pair.
    "IM-GK-U5-L7": "broken(no_instances)",
}

TIMEOUT_REGRESSION_LESSON = "IM-G4-U4-L20"


def main() -> int:
    result = subprocess.run(
        [sys.executable, str(HARNESS), "--calibration", "--stdout"],
        cwd=ROOT, text=True, capture_output=True, check=False, timeout=15 * 60,
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
    timeout_result = subprocess.run(
        [
            sys.executable, str(HARNESS), "--lesson", TIMEOUT_REGRESSION_LESSON,
            "--productive-budget", "2", "--stdout",
        ],
        cwd=ROOT, text=True, capture_output=True, check=False, timeout=5 * 60,
    )
    if timeout_result.returncode:
        print(timeout_result.stderr, file=sys.stderr)
        return timeout_result.returncode
    timeout_row = json.loads(timeout_result.stdout)["rows"]
    if len(timeout_row) != 1 or timeout_row[0]["pusu"] != "broken(execute_mismatch)" or not any(
        row["timed_out"] for row in timeout_row[0]["productive"]
    ):
        print("FAIL pusu timeout regression", file=sys.stderr)
        print(json.dumps(timeout_row, indent=2, sort_keys=True), file=sys.stderr)
        return 1
    print("PASS pusu calibration")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
