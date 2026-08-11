#!/usr/bin/env python3
"""Focused checks for the wave 2 exact-mix and assertion contracts."""
from __future__ import annotations

import os
import platform
import sys
from pathlib import Path

if sys.platform == "darwin" and platform.machine() == "x86_64":
    os.execvp("arch", ["arch", "-arm64", sys.executable, *sys.argv])

ROOT = Path(__file__).resolve().parents[2]
SIDEKICK = ROOT / "scripts" / "sidekick"
for candidate in (str(ROOT), str(SIDEKICK)):
    if candidate not in sys.path:
        sys.path.insert(0, candidate)

from build_dataset import (  # noqa: E402
    CLASS_C_ADMISSION_RATE_FLOOR,
    discounted_capacity,
    planned_framing_slots,
    require_capacity,
    require_exact,
    subjects_for_discounted_target,
)
from measure_floors import score_reply  # noqa: E402


def main() -> int:
    turn = "one third plus one third as two sixths"
    reply = "1/3 + 1/3 can be restated as 2/6."
    unsupported, _ = score_reply(reply, turn, "C")
    assert unsupported == [], (
        "slash notation derived from the turn's spelled fractions was rejected: "
        f"{unsupported}"
    )

    unsupported, _ = score_reply(
        reply + " A different claim is 3/7 under invented_registry_name.", turn, "C"
    )
    assert unsupported == ["3/7", "invented_registry_name"], (
        "the fraction restatement allowance admitted an unsupported assertion: "
        f"{unsupported}"
    )

    try:
        require_capacity("class D", 1200, 1199)
    except RuntimeError as failure:
        assert str(failure) == "class D: target 1200, available 1199"
    else:
        raise AssertionError("an exact-mix shortfall did not fail hard")

    try:
        require_exact("class C sub-kind C3 after gates", 960, 959)
    except RuntimeError as failure:
        assert str(failure) == "class C sub-kind C3 after gates: target 960, available 959"
    else:
        raise AssertionError("a post-gate sub-kind shortfall did not fail hard")

    assert CLASS_C_ADMISSION_RATE_FLOOR == 0.65
    assert discounted_capacity(615) == 399
    assert discounted_capacity(616) == 400
    assert subjects_for_discounted_target(400) == 154

    slot_units = [
        ("C:known_fact:0", [("cached-one", "", {})], "known_fact", 4),
        ("C:surface:0", [("cached-a", "", {}), ("cached-b", "", {})], "surface", 4),
        ("C:already_answered:0", [("uncached", "", {})], "already_answered", 4),
    ]
    slot_cache = {
        "framing:known_fact:cached-one": {"turns": ["first", "second"]},
        "framing:surface:cached-a|cached-b": {
            "subjects": {"cached-a": ["one"], "cached-b": ["one", "two", "three"]}
        },
    }
    slots, sources = planned_framing_slots(slot_units, slot_cache)
    assert slots == {"cached-one": 2, "cached-a": 1, "cached-b": 3, "uncached": 4}
    assert sources == {"cached": 6, "requested": 4}

    print(
        "PASS sidekick wave 2 contracts: spelled fractions support only their slash forms; "
        "unsupported assertions remain rejected; exact-mix shortfalls fail hard before and "
        "after gates; 616 raw slots clear a 400-row target only under the 0.65 admission floor; "
        "cached batches contribute their stored turns"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
