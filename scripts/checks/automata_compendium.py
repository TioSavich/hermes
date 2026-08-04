#!/usr/bin/env python3
"""Byte-check the generated automata typology, diagrams, and compendium."""
from __future__ import annotations

import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
RESEARCH_SCRIPTS = ROOT / "scripts/research"
sys.path.insert(0, str(RESEARCH_SCRIPTS))

from build_automata_compendium import OUTPUT as COMPENDIUM, generate_compendium  # noqa: E402
from build_machine_typology import OUTPUT as TYPOLOGY, generate_typology, parse_transition_tables  # noqa: E402
from render_automaton_svg import OUTPUT_DIR as SVG_DIR, render_all  # noqa: E402


def compare_file(path: Path, expected: str, failures: list[str]) -> None:
    if not path.exists():
        failures.append(f"missing generated artifact: {path.relative_to(ROOT)}")
    elif path.read_text(encoding="utf-8") != expected:
        failures.append(f"stale generated artifact: {path.relative_to(ROOT)}")


def main() -> int:
    failures: list[str] = []
    machines = parse_transition_tables()
    compare_file(TYPOLOGY, generate_typology(), failures)

    rendered = render_all()
    for relative, expected in rendered.items():
        compare_file(SVG_DIR / relative, expected, failures)
    existing = (
        {path.relative_to(SVG_DIR) for path in SVG_DIR.glob("*/*.svg")}
        if SVG_DIR.exists()
        else set()
    )
    for relative in sorted(existing - set(rendered)):
        failures.append(f"unexpected generated SVG: {(SVG_DIR / relative).relative_to(ROOT)}")

    compare_file(COMPENDIUM, generate_compendium(), failures)
    if len(rendered) != len(machines):
        failures.append(
            f"tuple/SVG count mismatch: {len(machines)} tuples, {len(rendered)} SVGs"
        )
    if failures:
        for failure in failures:
            print(failure, file=sys.stderr)
        return 1
    family_count = len({machine.family for machine in machines})
    print(
        f"PASS automata compendium: {len(machines)} machines in {family_count} families; "
        "typology, SVGs, and HTML are byte-identical to in-memory rebuilds"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
