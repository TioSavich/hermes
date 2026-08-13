#!/usr/bin/env python3
"""Sandbox-safe determinism verification for Wave 5 S3 artifacts."""
from __future__ import annotations

import tempfile
from pathlib import Path

from build_wave5_f0 import RESULTS_NAME as F0_RESULTS
from build_wave5_f0 import SUMMARY_NAME as F0_SUMMARY
from build_wave5_f0 import build as build_f0
from build_wave5_f2 import RESULTS_NAME as F2_RESULTS
from build_wave5_f2 import SUMMARY_NAME as F2_SUMMARY
from build_wave5_f2 import build as build_f2
from build_wave5_mtb_mini import FLOORS_NAME as MTB_FLOORS
from build_wave5_mtb_mini import MANIFEST_NAME as MTB_MANIFEST
from build_wave5_mtb_mini import build as build_mtb


ARTIFACTS = (F0_RESULTS, F0_SUMMARY, F2_RESULTS, F2_SUMMARY, MTB_MANIFEST, MTB_FLOORS)


def main() -> int:
    with tempfile.TemporaryDirectory(prefix="wave5-s3-a-") as first_name, tempfile.TemporaryDirectory(
        prefix="wave5-s3-b-"
    ) as second_name:
        first, second = Path(first_name), Path(second_name)
        first_f0 = build_f0(first)
        if first_f0["block_check"]["blocked"]:
            raise SystemExit("F0 saturation block triggered during determinism verification")
        build_f2(first)
        build_mtb(first)
        second_f0 = build_f0(second)
        if second_f0["block_check"] != first_f0["block_check"]:
            raise SystemExit("F0 block check changed between builds")
        build_f2(second)
        build_mtb(second)
        mismatches = [
            name for name in ARTIFACTS if (first / name).read_bytes() != (second / name).read_bytes()
        ]
        if mismatches:
            raise SystemExit(f"non-deterministic Wave 5 S3 artifacts: {mismatches}")
    print(f"PASS Wave 5 S3 double-build is byte-identical: {len(ARTIFACTS)} artifacts")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
