#!/usr/bin/env python3
"""Numerical bistability artifact and Prolog cross-verifier for the More Machine.

Provenance: the numerical core (canvas constants, ``gradient_vec``, the
equilibrium search and dedup) is carried over from the source project's
``bifurcation_verify.py``, which generated ``bifurcation_diagram.png`` with
matplotlib. This adaptation strips the figure generation and adds the
``--cross-check`` harness, which compares a fixed 7 by 7 control grid with
``hermes/web/prolog/zeeman_bifurcation.pl`` and reports the result without
treating agreement as a foregone conclusion.
"""
from __future__ import annotations

import argparse
import subprocess
from collections import Counter
from pathlib import Path

import numpy as np


CANVAS = 600
WHEEL_CX, WHEEL_CY = CANVAS / 2, CANVAS / 2
FIXED_X, FIXED_Y = CANVAS / 2, CANVAS * 0.1
# 0.083 is the source artifact's rim fraction; it normalizes to R = 0.996,
# not the Prolog core's r = 1.0. The 0.4% offset changes no equilibrium
# count on the pinned grid (checked at both radii) and is kept so this file
# stays numerically faithful to the artifact it derives from.
ATTACH_R = CANVAS * 0.083
PROLOG_SCALE = 50.0
SPRING_K = 2.0
NAT_LEN = 100
SAMPLE_COORDS = (60, 140, 220, 300, 380, 460, 540)
# The two cores agree at every pinned grid point. An earlier release pinned a
# three-point divergence at the upper control edge; that divergence was a
# wraparound artifact in THIS file's dedup (a single equilibrium straddling
# the theta = 0 seam counted once per side), not a Prolog undercount.
EXPECTED_MISMATCHES = ()


def gradient_vec(angles: np.ndarray, cx: float, cy: float) -> np.ndarray:
    """Return the potential gradient for angles at one control point."""
    px = ATTACH_R * np.cos(angles)
    py = ATTACH_R * np.sin(angles)
    fixed_x = FIXED_X - WHEEL_CX
    fixed_y = FIXED_Y - WHEEL_CY
    control_x = cx - WHEEL_CX
    control_y = cy - WHEEL_CY
    length_fixed = np.hypot(px - fixed_x, py - fixed_y)
    length_control = np.hypot(px - control_x, py - control_y)
    torque_fixed = np.where(
        (length_fixed > NAT_LEN) & (length_fixed > 1e-6),
        SPRING_K * (1 - NAT_LEN / length_fixed)
        * (fixed_x * np.sin(angles) - fixed_y * np.cos(angles)),
        0.0,
    )
    torque_control = np.where(
        (length_control > NAT_LEN) & (length_control > 1e-6),
        SPRING_K * (1 - NAT_LEN / length_control)
        * (control_x * np.sin(angles) - control_y * np.cos(angles)),
        0.0,
    )
    return ATTACH_R * (torque_fixed + torque_control)


def find_equilibria_fast(cx: float, cy: float, n_starts: int = 36) -> np.ndarray:
    """Find numerical stable equilibria by vectorized gradient descent."""
    angles = np.linspace(0, 2 * np.pi, n_starts, endpoint=False)
    for _ in range(400):
        gradient = gradient_vec(angles, cx, cy)
        angles -= np.clip(0.001 * gradient, -0.1, 0.1)
        angles %= 2 * np.pi
    delta = 0.01
    stability = (
        gradient_vec(angles + delta, cx, cy)
        - gradient_vec(angles - delta, cx, cy)
    ) / (2 * delta)
    stable = np.sort(angles[stability > 0] % (2 * np.pi))
    if len(stable) == 0:
        return stable
    keep = np.concatenate([[True], np.diff(stable) > 0.15])
    # The variable is an angle: merge across the 0 / 2*pi seam too, or a
    # single equilibrium near theta = 0 is counted once per side of the seam.
    # (The Prolog core closes this loop explicitly before scanning for sign
    # changes; this dedup must match that circular topology.)
    if len(stable) > 1 and (stable[0] + 2 * np.pi - stable[-1]) <= 0.15:
        keep[0] = False
    kept = stable[keep]
    return kept if len(kept) else stable[:1]


def python_counts() -> list[tuple[float, float, int]]:
    rows = []
    for cx in SAMPLE_COORDS:
        for cy in SAMPLE_COORDS:
            x = round((cx - WHEEL_CX) / PROLOG_SCALE, 10)
            y = round((cy - WHEEL_CY) / PROLOG_SCALE, 10)
            rows.append((x, y, len(find_equilibria_fast(cx, cy))))
    return rows


def prolog_counts(repo: Path, points: list[tuple[float, float]]) -> list[tuple[float, float, int]]:
    terms = ",".join(f"point({x},{y})" for x, y in points)
    goal = (
        "use_module(zeeman(zeeman_bifurcation)),"
        "zeeman_machine:default_params(P),"
        f"forall(member(point(X,Y),[{terms}]),"
        "(zeeman_bifurcation:stable_count(point(X,Y),P,N),"
        "format('~w ~w ~w~n',[X,Y,N]))),halt."
    )
    process = subprocess.run(
        ["swipl", "-q", "-l", "paths.pl", "-g", goal],
        cwd=repo,
        text=True,
        capture_output=True,
        check=True,
    )
    return [
        (float(x), float(y), int(count))
        for x, y, count in (line.split() for line in process.stdout.splitlines())
    ]


def count_summary(rows: list[tuple[float, float, int]]) -> str:
    counts = Counter(count for _x, _y, count in rows)
    return "{" + ",".join(f"{key}:{counts[key]}" for key in sorted(counts)) + "}"


def cross_check(repo: Path) -> int:
    numerical = python_counts()
    prolog = prolog_counts(repo, [(x, y) for x, y, _count in numerical])
    mismatches = tuple(
        (x, y, py_count, pl_count)
        for (x, y, py_count), (_px, _py, pl_count) in zip(numerical, prolog)
        if py_count != pl_count
    )
    verdict = "agreement" if not mismatches else "divergence"
    print(f"ZEEMAN_BIFURCATION_VERDICT {verdict}")
    print(
        f"sample_points={len(numerical)} "
        f"python_counts={count_summary(numerical)} "
        f"prolog_counts={count_summary(prolog)} mismatches={len(mismatches)}"
    )
    for x, y, py_count, pl_count in mismatches:
        print(f"mismatch control=point({x},{y}) python={py_count} prolog={pl_count}")
    if mismatches != EXPECTED_MISMATCHES:
        print(f"expected_mismatches={EXPECTED_MISMATCHES}")
        return 1
    print("zeeman bifurcation comparison is deterministic at the pinned grid")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cross-check", action="store_true")
    parser.add_argument("--repo", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    if args.cross_check:
        return cross_check(args.repo.resolve())
    parser.error("choose --cross-check")


if __name__ == "__main__":
    raise SystemExit(main())
