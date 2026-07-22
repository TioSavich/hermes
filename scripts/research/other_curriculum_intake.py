#!/usr/bin/env python3
"""Offline, verify-first intake survey for the non-IM TalkMoves map.

The script reads the sibling checkout but writes only the report requested by
task 109.  It deliberately keeps curriculum-specific coverage proposals here,
rather than creating lesson facts for curricula that Hermes does not yet model.
"""
from __future__ import annotations

import argparse
import html.parser
import json
import re
import subprocess
import math
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
SIBLING = Path("/Users/tio/Documents/GitHub/umedcta-formalization")
MAP = SIBLING / "other_curriculum/transcript_map.json"
MANIFEST = SIBLING / "data/external/talkmoves/manifests/talkmoves_blind_manifest.json"
TALKMOVES = SIBLING / "data/external/talkmoves"
DEFAULT_REPORT = ROOT / "docs/research/2026-07-23-other-curriculum-intake.md"


@dataclass(frozen=True)
class Coverage:
    domains: str
    claim_shapes: str
    contracts: str
    resonance_seed: str | None
    verdict: str
    next_slice: str


# These are task statements, not curriculum facts.  Each operational name is
# checked against the live registry before it is rendered in the report.
COVERAGE: dict[str, Coverage] = {
    "VMC-WORLD-SERIES": Coverage("probability; combinatorial", "multiplication/3", "probability action automata; no outcome-sequence contract", "arrangement_as_combination_sum", "needs specific coverage: a best-of-seven outcome-sequence contract and probability claim shape", "Add one VMC task-statement fact with equal-team assumption, series length, and outcome space; then a compact probability monitoring chart."),
    "VMC-SHIRTS-PANTS": Coverage("counting; combinatorial", "multiplication/3", "counting and multiplication action automata; no Cartesian-product contract", "blind_combine_numbers", "needs specific coverage: an outfit/Cartesian-product task contract", "Add one VMC task-statement fact for shirt/pants choices and a counting-table monitoring chart."),
    "VMC-TOWERS": Coverage("counting; combinatorial", "arithmetic_equation/3", "counting action automata; no colored-tower enumeration contract", "guess_recursive_partition", "needs specific coverage: a height-and-colour tower generator with its count invariant", "Add one shared VMC Towers fact plus transcript-specific prompt evidence; chart the generate/count/prove moves."),
    "VMC-LADDER": Coverage("algebraic; geometry", "arithmetic_equation/3", "algebraic and geometry action automata; no ladder-growth contract", None, "needs specific coverage: a figural-growth/ladder rule contract", "Add one VMC ladder task-statement fact with figure index, units, and expected growth relation; then a pattern-rule chart."),
    "VMC-ONE-HALF-CUISENAIRE": Coverage("fraction", "equivalence/2; fraction_of/3", "fraction action automata", "loss_of_whole", "analyzable today for unit-relative fraction claims; needs a Cuisenaire referent fact for a lesson-grain chart", "Add one VMC task-statement fact naming rod relations and the chosen whole; reuse a fraction monitoring chart with a referent column."),
    "VMC-MARTINO-EQUIVALENCE": Coverage("fraction", "equivalence/2; multiplication/3", "fraction action automata", "additive_equivalence", "analyzable today for equivalence claims; needs the rod-composition task data to trace the transcript faithfully", "Add one VMC task-statement fact for rod compositions/equivalent units and a fraction-equivalence monitoring chart."),
    "VMC-ALANS-INFINITY": Coverage("fraction; calculus", "number_line_position/2", "fraction and calculus action automata; no density/infinite-subdivision contract", None, "needs specific coverage: a between-any-two-fractions/density contract", "Add one VMC task-statement fact for the interval and subdivision operation; propose a number-line/density chart after the contract exists."),
    "CMP-LFP-PROB1.1": Coverage("geometry; measurement", "shape_property/2; arithmetic_equation/3", "geometry and measurement action automata", None, "needs specific coverage: coordinate-distance/Pythagorean task facts and a theorem-justification claim shape", "Add one CMP task-statement fact for coordinates, route/park constraints, and distance relation; then a geometry monitoring chart."),
    "EM4-G4-L3.8": Coverage("fraction", "improper/1; equivalence/2", "fraction action automata", "whole_as_unit_fraction", "analyzable today for symbolic mixed/improper equivalence; needs EM4 representation details for lesson-grain treatment", "Add one EM4 lesson fact for the rename forms and fraction-circle/area-model referents; reuse a fraction monitoring chart."),
    "EM4-G4-L4.9": Coverage("multiplication; place value", "multiplication/3; arithmetic_equation/3", "multiplication action automata", "partial_products_no_shift", "analyzable today for partial-product arithmetic; needs the EM4 decomposition convention and examples", "Add one EM4 lesson fact for place-value decomposition and partial-product recombination; use a multiplication monitoring chart."),
    "EM4-G4-L5.10": Coverage("fraction; multiplication; geometry", "multiplication/3; fraction_of/3", "fraction and multiplication action automata", "area_model_count_addition", "analyzable today for fraction-product claims; needs the area-model partition contract", "Add one EM4 lesson fact for both factors, whole rectangle, and cross-hatched region; use an area-model monitoring chart."),
}


def cell(value: object) -> str:
    return str(value).replace("|", "\\|").replace("\n", " ")


def tokens(value: str) -> list[str]:
    return re.findall(r"[a-z0-9]+", value.lower().replace("theres", "there is"))


def normalized_filename(value: str) -> str:
    value = value.lower().replace("_with_dialog_acts.xlsx", "")
    value = value.replace(".xlsx", "")
    return re.sub(r"[^a-z0-9]+", "", value)


def source_status(relative: str) -> str:
    path = SIBLING / relative
    if not path.is_file() or path.stat().st_size == 0:
        return "missing"
    suffix = path.suffix.lower()
    if suffix == ".pdf":
        result = subprocess.run(["pdftotext", "-f", "1", "-l", "1", str(path), "-"], text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
        return "present; PDF parsed" if result.returncode == 0 else "present; PDF parse failed"
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return "present; UTF-8 parse failed"
    if suffix in {".html", ".htm"}:
        parser = html.parser.HTMLParser()
        try:
            parser.feed(text); parser.close()
        except Exception:
            return "present; HTML parse failed"
        return "present; HTML parsed"
    return "present; Markdown parsed" if text.strip() else "present; Markdown empty"


def manifest_matches(name: str, entries: list[dict[str, Any]]) -> list[dict[str, Any]]:
    wanted = normalized_filename(name)
    found = []
    for entry in entries:
        source = Path(str(entry.get("source_path", ""))).name
        if normalized_filename(source) == wanted:
            found.append(entry)
    return found


def prompt_evidence(prompt: str, markdown: Path) -> str | None:
    """Return a blind-markdown line with a substantial contiguous prompt span.

    A token-window match tolerates transcription punctuation and contractions,
    but requires at least four consecutive prompt words and 45% prompt-token
    coverage.  It fails closed when those conditions are not met.
    """
    if not markdown.is_file():
        return None
    prompt_words = tokens(prompt)
    if not prompt_words:
        return None
    best: tuple[int, int, str] | None = None
    markdown_lines = markdown.read_text(encoding="utf-8").splitlines()
    for line_index, line in enumerate(markdown_lines):
        # One spoken turn can be split across adjacent Markdown lines. The
        # retained evidence quotes that short window rather than silently
        # treating an incomplete single line as a match.
        line = " ".join(markdown_lines[line_index:line_index + 2])
        words = tokens(line)
        longest = 0
        for start in range(len(prompt_words)):
            for end in range(start + 4, len(prompt_words) + 1):
                phrase = prompt_words[start:end]
                size = len(phrase)
                if size <= longest or size > len(words):
                    continue
                if any(words[index:index + size] == phrase for index in range(len(words) - size + 1)):
                    longest = size
        if longest:
            candidate = (longest, len(words), line.strip())
            if best is None or candidate[0] > best[0]:
                best = candidate
    if best and best[0] >= 4 and best[0] / len(prompt_words) >= .45:
        return best[2]
    return None


def live_operations() -> set[str]:
    text = (ROOT / "knowledge/strategies/math/action_automata_registry.pl").read_text(encoding="utf-8")
    return set(re.findall(r"action_automaton_cluster\(([a-z_]+),", text))


def live_claim_shapes() -> set[str]:
    text = (ROOT / "hermes_worker.pl").read_text(encoding="utf-8")
    return set(re.findall(r"safe_math_claim_shape\(([a-z_]+)\(", text))


def coverage_status(coverage: Coverage, operations: set[str], shapes: set[str]) -> str:
    requested_operations = set(re.findall(r"\b(probability|counting|multiplication|fraction|calculus|algebraic|geometry|measurement)\b", coverage.contracts))
    requested_shapes = set(re.findall(r"\b(equivalence|fraction_of|multiplication|arithmetic_equation|number_line_position|shape_property|improper)\b", coverage.claim_shapes))
    absent = sorted((requested_operations - operations) | (requested_shapes - shapes))
    return "live names verified" if not absent else "unverified live names: " + ", ".join(absent)


def load_resonance(seeds: set[str]) -> dict[str, list[tuple[str, float]]]:
    """Compute stored-vector neighbours locally; no embedding endpoint is used."""
    try:
        if str(ROOT) not in sys.path:
            sys.path.insert(0, str(ROOT))
        from hermes.app.routes.misconception_search import load_index
        index = load_index(ROOT)
    except ImportError:
        return {}
    if index is None:
        return {}
    names = [entry["name"] for entry in index.entries]
    result: dict[str, list[tuple[str, float]]] = {}
    for name in seeds:
        if name not in names:
            continue
        seed_index = names.index(name)
        vector = index.vectors[seed_index]
        vector_norm = index.norms[seed_index]
        ranked = sorted(((other_name, sum(left * right for left, right in zip(vector, other_vector)) / (vector_norm * other_norm)) for other_name, other_vector, other_norm in zip(names, index.vectors, index.norms) if other_name not in {name, "too_vague"}), key=lambda item: (-item[1], item[0]))
        unique: list[tuple[str, float]] = []
        for candidate in ranked:
            if candidate[0] not in {existing[0] for existing in unique}:
                unique.append(candidate)
            if len(unique) == 3:
                break
        result[name] = unique
    return result


def render(records: list[dict[str, Any]], resonance: dict[str, list[tuple[str, float]]], operations: set[str], shapes: set[str]) -> str:
    lines = [
        "# Other-curriculum intake: VMC, CMP, and EM4 transcripts",
        "",
        "## Method",
        "",
        "This is an offline, read-only survey of the sibling checkout. For every map row it checks the named raw and converted files, resolves the transcript filename against the blind manifest, and accepts a pairing only when a substantial spoken-prompt span occurs in the corresponding blinded markdown. The source-path match alone is not treated as verification. Coverage names are checked against Hermes's current action-automata registry and `safe_math_claim_shape/1` surface. Resonance results use the stored misconception vectors locally; no embedding request is made.",
        "",
        "## Inventory and verified map",
        "",
        "| Transcript | Curriculum / grade | Task | Raw source | Converted source | Blind ID | Prompt evidence | Pairing |",
        "| --- | --- | --- | --- | --- | --- | --- | --- |",
    ]
    for record in records:
        lines.append("| {transcript} | {curriculum} / {grade} | {task} | {raw} | {converted} | {tm} | {evidence} | {pairing} |".format(
            transcript=cell(record["transcript_filename"]), curriculum=cell(record["curriculum_source"]), grade=cell(record["grade_level"]), task=cell(record["task_id"]), raw=cell(record["raw_status"]), converted=cell(record["converted_status"]), tm=cell(record["tm_id"]), evidence=cell(record["evidence"] or "—"), pairing=record["pairing"]))
    lines += ["", "## Coverage join and next-slice proposals", ""]
    for record in records:
        coverage = COVERAGE[record["task_id"]]
        lines += [
            f"### {record['task_id']} — {record['task_title']}",
            "",
            f"- Registry domains: {coverage.domains}.",
            f"- Fitting claim shapes: {coverage.claim_shapes}.",
            f"- Runnable seam: {coverage.contracts} ({coverage_status(coverage, operations, shapes)}).",
        ]
        if coverage.resonance_seed:
            neighbours = resonance.get(coverage.resonance_seed)
            if neighbours:
                formatted = ", ".join(f"`{name}` ({score:.3f})" for name, score in neighbours)
                lines.append(f"- Offline resonance: seed `{coverage.resonance_seed}`; nearest stored rows: {formatted}. This is a retrieval lead, not a diagnosis of a speaker.")
            else:
                lines.append(f"- Offline resonance: seed `{coverage.resonance_seed}` is not available in the stored vector index; no neighbour is claimed.")
        else:
            lines.append("- Offline resonance: no named row is close enough from the task statement alone; none is claimed.")
        lines += [f"- Verdict: {coverage.verdict}.", f"- Next slice: {coverage.next_slice}", ""]
    verified = sum(record["pairing"] == "verified" for record in records)
    lines += [
        "## Boundary",
        "",
        f"{verified} of {len(records)} map rows have a source-path match plus prompt evidence. No non-IM curriculum facts or monitoring charts were written. The proposals above are sized follow-on slices, not assertions that the current IM lesson machinery already covers these tasks.",
        "",
        "## Verified map table",
        "",
        "| Task | Blind ID | Verified pairing |",
        "| --- | --- | --- |",
    ]
    for record in records:
        lines.append(f"| {record['task_id']} | {record['tm_id']} | {record['pairing']} |")
    lines += ["", "IMPLEMENTATION_COMPLETE"]
    return "\n".join(lines) + "\n"


def survey() -> list[dict[str, Any]]:
    mapping = json.loads(MAP.read_text(encoding="utf-8"))["transcripts"]
    entries = json.loads(MANIFEST.read_text(encoding="utf-8"))["transcripts"]
    records = []
    for row in mapping:
        candidates = manifest_matches(row["transcript_filename"], entries)
        evidence = None
        tm_id = "unresolved"
        if len(candidates) == 1:
            candidate = candidates[0]
            tm_id = str(candidate["transcript_id"])
            evidence = prompt_evidence(row["spoken_prompt_sample"], TALKMOVES / candidate["markdown_path"])
        records.append({**row, "raw_status": source_status(row["raw_source_file"]), "converted_status": source_status(row["converted_markdown_file"]), "tm_id": tm_id, "evidence": evidence, "pairing": "verified" if evidence else "unverified"})
    return records


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--report", type=Path, default=DEFAULT_REPORT)
    parser.add_argument("--check", action="store_true", help="fail unless every map row has a verified pairing")
    args = parser.parse_args()
    records = survey()
    seeds = {coverage.resonance_seed for coverage in COVERAGE.values() if coverage.resonance_seed}
    report = render(records, load_resonance(seeds), live_operations(), live_claim_shapes())
    args.report.write_text(report, encoding="utf-8")
    if args.check and any(row["pairing"] != "verified" for row in records):
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
