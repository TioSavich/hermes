#!/usr/bin/env python3
"""Byte-check the generated automata typology, diagrams, and compendium."""
from __future__ import annotations

import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
RESEARCH_SCRIPTS = ROOT / "scripts/research"
sys.path.insert(0, str(RESEARCH_SCRIPTS))

from build_automata_compendium import (  # noqa: E402
    FAMILY_OUTPUT_DIR,
    OUTPUT as COMPENDIUM,
    generate_compendium_pages,
)
from build_machine_typology import OUTPUT as TYPOLOGY, generate_typology, parse_transition_tables  # noqa: E402
from render_automaton_context_svg import (  # noqa: E402
    composite_records,
    render_all as render_context,
    scene_records,
)
from render_automaton_svg import OUTPUT_DIR as SVG_DIR, render_all as render_radial  # noqa: E402


def compare_file(path: Path, expected: str, failures: list[str]) -> None:
    if not path.exists():
        failures.append(f"missing generated artifact: {path.relative_to(ROOT)}")
    elif path.read_text(encoding="utf-8") != expected:
        failures.append(f"stale generated artifact: {path.relative_to(ROOT)}")


def main() -> int:
    failures: list[str] = []
    machines = parse_transition_tables()
    compare_file(TYPOLOGY, generate_typology(), failures)

    radial = render_radial()
    context = render_context()
    rendered = {**radial, **context}
    for relative, expected in rendered.items():
        compare_file(SVG_DIR / relative, expected, failures)
    existing = (
        {path.relative_to(SVG_DIR) for path in SVG_DIR.glob("*/*.svg")}
        if SVG_DIR.exists()
        else set()
    )
    for relative in sorted(existing - set(rendered)):
        failures.append(f"unexpected generated SVG: {(SVG_DIR / relative).relative_to(ROOT)}")

    compendium_pages = generate_compendium_pages()
    for path, expected in compendium_pages.items():
        compare_file(path, expected, failures)
    existing_pages = (
        set(FAMILY_OUTPUT_DIR.glob("*.html"))
        if FAMILY_OUTPUT_DIR.exists()
        else set()
    )
    expected_family_pages = set(compendium_pages) - {COMPENDIUM}
    for path in sorted(existing_pages - expected_family_pages):
        failures.append(
            f"unexpected generated compendium page: {path.relative_to(ROOT)}"
        )
    if len(compendium_pages) != 16:
        failures.append(
            f"compendium page-count mismatch: expected 16, got {len(compendium_pages)}"
        )
    hub = compendium_pages.get(COMPENDIUM, "")
    for fragment in (
        "the claim is false on its own",
        "a correct doing the context makes insufficient",
        "blue base with a rust overlay drawn last",
        "reviewed and",
        "unreviewed deforming transitions",
    ):
        if fragment not in hub:
            failures.append(f"compendium legend lacks validity fragment: {fragment}")
    for path in sorted(expected_family_pages):
        page = compendium_pages[path]
        if "<th>Validity</th>" not in page:
            failures.append(f"family page lacks transition validity column: {path.relative_to(ROOT)}")
        if "Validity review for this family:" not in page:
            failures.append(f"family page lacks review counts: {path.relative_to(ROOT)}")
    for relative, svg in radial.items():
        blue_at = svg.find('class="validity-blue-base"')
        rust_at = svg.find('class="validity-rust-overlay"')
        if blue_at >= 0 and rust_at >= 0 and blue_at > rust_at:
            failures.append(f"radial SVG does not draw blue before rust: {relative}")
    for family, (svg, _unaligned) in composite_records().items():
        blue_at = svg.find('class="validity-blue-base"')
        rust_at = svg.find('class="validity-rust-overlay"')
        if blue_at >= 0 and rust_at >= 0 and blue_at > rust_at:
            failures.append(f"composite SVG does not draw blue before rust: {family}")
    if len(radial) != len(machines):
        failures.append(
            f"tuple/radial-SVG count mismatch: {len(machines)} tuples, {len(radial)} SVGs"
        )
    scenes = scene_records()
    scene_count = sum(record.svg is not None for record in scenes.values())
    if len(scenes) != len(machines):
        failures.append(
            f"tuple/scene-decision mismatch: {len(machines)} tuples, {len(scenes)} decisions"
        )
    family_count = len({machine.family for machine in machines})
    if len(composite_records()) != family_count:
        failures.append(
            f"family/composite mismatch: {family_count} families, {len(composite_records())} composites"
        )
    if failures:
        for failure in failures:
            print(failure, file=sys.stderr)
        return 1
    print(
        f"PASS automata compendium: {len(machines)} machines in {family_count} families; "
        f"{scene_count} domain scenes and {family_count} composites; "
        f"typology, SVGs, and {len(compendium_pages)} HTML pages are byte-identical "
        "to in-memory rebuilds"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
