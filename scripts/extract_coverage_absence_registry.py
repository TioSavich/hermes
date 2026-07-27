#!/usr/bin/env python3
"""Generate the bounded Hermes coverage-and-absence registry.

The registry records three live, finite subject sets: Lakoff--Nunez metaphor
families, IM lessons with a compiled productive task, and the lesson-evidence
pipeline inputs.  It records the receipt status rather than reducing every
absence to a boolean.
"""
from __future__ import annotations

import argparse
import ast
import difflib
import json
import re
import subprocess
import sys
import tempfile
from collections import Counter, defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "knowledge" / "index" / "coverage_absence_registry.pl"
ASSET_MANIFEST = ROOT / "hermes" / "representation" / "build_asset_manifest.py"
NEGATIVE_RECEIPTS = ROOT / "scripts" / "curriculum" / "lesson_negative_receipts.json"

PIPELINE_INPUTS = (
    ("spine", "data/learningcommons/derived/im_k8_spine.json", None),
    ("standard_action_catalog", "data/learningcommons/derived/im_ccss_action_catalog.json", None),
    ("productive_deformation_catalog", "data/learningcommons/derived/im_productive_deformation_catalog.json", None),
    ("negative_receipts", "scripts/curriculum/lesson_negative_receipts.json", None),
    ("compiled_action_mappings", "lessons/im/generated/compiled_action_mappings.pl", "curriculum/im/generated/compiled_action_mappings.pl"),
    ("compiled_task_instances", "lessons/im/generated/compiled_task_instances.pl", "curriculum/im/generated/compiled_task_instances.pl"),
    ("atlas_landscape", "scripts/bigred/iteration15/work/atlas/atlas_landscape.jsonl", None),
)
REFRESH_ONLY_INPUT = "data/learningcommons/nodes.jsonl"
STATUS_KINDS = (
    "present",
    "coverage_gap",
    "broken_pipeline",
    "path_drift",
    "not_applicable",
    "unknown",
)
PRIMITIVE_CONCEPT = re.compile(
    r"primitive_renders_metaphor\('([^']+)',\s*([a-z_]+),\s*([a-z_]+)\)"
)


def prolog_atom(value: str) -> str:
    if re.fullmatch(r"[a-z][A-Za-z0-9_]*", value):
        return value
    return "'" + value.replace("'", "''") + "'"


def run_prolog_inventory() -> dict[str, set[tuple[str, ...]]]:
    """Read each source relation through its supported Hermes loader."""
    goal = r"""
ensure_loaded(geometry(schema)),
use_module(render(grounding_to_primitive)),
use_module(render(representation_grammar)),
use_module(lessons('im/lesson_monitoring')),
use_module(lessons('im/generated/compiled_task_instances')),
forall(lakoff_nunez_metaphor_family(F), format('family\t~w~n', [F])),
forall(grounding_to_primitive:primitive_renders_metaphor(P, M, Role), format('primitive\t~w\t~w\t~w~n', [P, M, Role])),
forall(representation_grammar:representation_render_status(R, renderable(Op)), format('renderer\t~w\t~w~n', [R, Op])),
forall(compiled_task_instances:compiled_lesson_task_instance(L, productive-_, _), format('productive\t~w~n', [L])),
forall(compiled_task_instances:compiled_lesson_task_instance(L, deformation(_)-_, _), format('deformation\t~w~n', [L])),
forall(lesson_monitoring:explicit_lesson_misconception(L, _, _, _), format('explicit\t~w~n', [L])),
halt
"""
    result = subprocess.run(
        ["swipl", "-q", "-l", str(ROOT / "paths.pl"), "-g", goal],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or "SWI-Prolog inventory query failed")
    if result.stderr.strip():
        raise RuntimeError(result.stderr.strip())
    rows: dict[str, set[tuple[str, ...]]] = defaultdict(set)
    for line in result.stdout.splitlines():
        fields = tuple(line.split("\t"))
        if fields:
            rows[fields[0]].add(fields[1:])
    required = {"family", "primitive", "renderer", "productive", "deformation", "explicit"}
    missing = required - rows.keys()
    if missing:
        raise RuntimeError(f"Prolog inventory returned no rows for: {', '.join(sorted(missing))}")
    return rows


def primitive_renderer_join() -> dict[str, set[str]]:
    """Read the existing representation-to-primitive routing table as data."""
    tree = ast.parse(ASSET_MANIFEST.read_text(encoding="utf-8"), filename=str(ASSET_MANIFEST))
    mapping_node = next(
        (
            node.value
            for node in tree.body
            if isinstance(node, ast.Assign)
            and any(isinstance(target, ast.Name) and target.id == "REPRESENTATION_CONCEPTS" for target in node.targets)
        ),
        None,
    )
    if mapping_node is None:
        raise RuntimeError("REPRESENTATION_CONCEPTS is missing from the representation asset manifest")
    mapping = ast.literal_eval(mapping_node)
    by_primitive: dict[str, set[str]] = defaultdict(set)
    for representation, concepts in mapping.items():
        for concept in concepts:
            match = PRIMITIVE_CONCEPT.fullmatch(concept)
            if match:
                by_primitive[match.group(1)].add(representation)
    if not by_primitive:
        raise RuntimeError("representation asset manifest has no primitive renderer joins")
    return by_primitive


def validate_receipt_path(receipt: dict) -> tuple[str, str | None]:
    """Classify a reviewed receipt's source path without repairing its record."""
    expected = receipt["source"]["path"]
    expected_path = ROOT / expected
    actual_path: Path | None = None
    if expected_path.is_file():
        actual_path = expected_path
        status = "present"
    elif expected.startswith("geometry/corpus/"):
        candidate = ROOT / "curriculum" / expected.removeprefix("geometry/corpus/")
        if candidate.is_file():
            actual_path = candidate
            status = "path_drift"
        else:
            return "broken_pipeline", None
    else:
        return "broken_pipeline", None
    lines = actual_path.read_text(encoding="utf-8", errors="replace").split("\n")
    for fragment in receipt["source"]["fragments"]:
        line_number = fragment["line"]
        if line_number < 1 or line_number > len(lines) or fragment["text"] not in lines[line_number - 1]:
            return "unknown", str(actual_path.relative_to(ROOT))
    return status, str(actual_path.relative_to(ROOT))


def load_negative_receipts() -> dict[str, tuple[str, str, str | None]]:
    payload = json.loads(NEGATIVE_RECEIPTS.read_text(encoding="utf-8"))
    if not isinstance(payload.get("receipts"), list):
        raise RuntimeError("lesson_negative_receipts.json has no receipt list")
    results = {}
    for receipt in payload["receipts"]:
        lesson = receipt["lesson"]
        if lesson in results:
            raise RuntimeError(f"duplicate reviewed negative receipt for {lesson}")
        status, actual = validate_receipt_path(receipt)
        results[lesson] = (status, receipt["source"]["path"], actual)
    if not results:
        raise RuntimeError("lesson_negative_receipts.json has no reviewed receipts")
    return results


def status_term(kind: str, *arguments: str) -> str:
    if kind == "present":
        return "present"
    if not arguments:
        return kind
    return f"{kind}(" + ", ".join(prolog_atom(argument) for argument in arguments) + ")"


def receipt_row(subject: str, receipt: str, status: str, evidence: str) -> str:
    return f"coverage_receipt({subject}, {receipt}, {status}, {evidence})."


def render_registry() -> str:
    inventory = run_prolog_inventory()
    primitive_to_representations = primitive_renderer_join()
    reviewed_receipts = load_negative_receipts()

    families = sorted(family[0] for family in inventory["family"])
    primitive_rows = sorted(inventory["primitive"])
    renderers = {representation: operation for representation, operation in inventory["renderer"]}
    primitive_by_metaphor: dict[str, list[tuple[str, str]]] = defaultdict(list)
    for primitive, metaphor, role in primitive_rows:
        primitive_by_metaphor[metaphor].append((primitive, role))

    rows: list[tuple[str, str, str]] = []
    for family in families:
        candidates = []
        for primitive, role in primitive_by_metaphor.get(family, []):
            for representation in sorted(primitive_to_representations.get(primitive, ())):
                operation = renderers.get(representation)
                if operation:
                    candidates.append((primitive, role, representation, operation))
        subject = f"metaphor({prolog_atom(family)})"
        if candidates:
            primitive, role, representation, operation = candidates[0]
            status = "present"
            evidence = (
                "[source_fact(grounding_to_primitive, primitive_renders_metaphor, "
                f"{prolog_atom(primitive)}, {prolog_atom(family)}, {prolog_atom(role)}), "
                "source_table(representation_asset_manifest, representation_concepts), "
                f"source_fact(representation_grammar, representation_render_status, {prolog_atom(representation)}, {prolog_atom(operation)})]"
            )
        elif family not in primitive_by_metaphor:
            status = status_term("coverage_gap", "no_primitive_mapping")
            evidence = "[source_fact(geometry_schema, lakoff_nunez_metaphor_family)]"
        else:
            status = status_term("coverage_gap", "no_primitive_renderer_join")
            evidence = "[source_fact(grounding_to_primitive, primitive_renders_metaphor), source_table(representation_asset_manifest, representation_concepts)]"
        rows.append(("metaphor_renderer", status.split("(", 1)[0], receipt_row(subject, "renderer", status, evidence)))

    productive_lessons = {lesson[0] for lesson in inventory["productive"]}
    deformation_lessons = {lesson[0] for lesson in inventory["deformation"]}
    explicit_lessons = {lesson[0] for lesson in inventory["explicit"]}
    unknown_receipt_lessons = set(reviewed_receipts) - productive_lessons
    if unknown_receipt_lessons:
        raise RuntimeError("reviewed negative receipts are outside the productive lesson cohort: " + ", ".join(sorted(unknown_receipt_lessons)))
    for lesson in sorted(productive_lessons):
        subject = f"lesson({prolog_atom(lesson)})"
        if lesson in explicit_lessons:
            status = "present"
            evidence = "[source_fact(lesson_monitoring, explicit_lesson_misconception)]"
        elif lesson in deformation_lessons:
            status = "present"
            evidence = "[source_fact(compiled_task_instances, compiled_lesson_task_instance)]"
        elif lesson in reviewed_receipts:
            receipt_status, expected, actual = reviewed_receipts[lesson]
            if receipt_status == "present":
                status = "present"
                evidence = "[source_fact(lesson_negative_receipts, reviewed_source_fragment)]"
            elif receipt_status == "path_drift":
                status = status_term("path_drift", expected, actual or "")
                evidence = "[source_fact(lesson_negative_receipts, reviewed_source_fragment)]"
            elif receipt_status == "broken_pipeline":
                status = status_term("broken_pipeline", expected)
                evidence = "[source_fact(lesson_negative_receipts, reviewed_source_fragment)]"
            else:
                status = status_term("unknown", "reviewed_source_fragment_mismatch")
                evidence = "[source_fact(lesson_negative_receipts, reviewed_source_fragment)]"
        else:
            status = status_term("coverage_gap", "no_structured_negative_receipt")
            evidence = "[machinery(lesson_monitoring), machinery(compiled_task_instances), machinery(lesson_negative_receipts)]"
        rows.append(("productive_lesson_structured_negative", status.split("(", 1)[0], receipt_row(subject, "structured_negative", status, evidence)))

    for name, expected, relocated in PIPELINE_INPUTS:
        subject = "pipeline(build_lesson_evidence)"
        if (ROOT / expected).is_file():
            if name == "negative_receipts":
                receipt_count = len(reviewed_receipts)
                status = "present"
                evidence = f"[parsed_receipt_records({receipt_count})]"
            else:
                status = "present"
                evidence = "[source_file]"
        elif relocated and (ROOT / relocated).is_file():
            status = status_term("path_drift", expected, relocated)
            evidence = "[reader_path, relocated_source_file]"
        else:
            status = status_term("broken_pipeline", expected)
            evidence = "[reader_path, absent_source_file]"
        rows.append(("lesson_evidence_pipeline", status.split("(", 1)[0], receipt_row(subject, f"input({name})", status, evidence)))
    rows.append((
        "lesson_evidence_pipeline",
        "not_applicable",
        receipt_row(
            "pipeline(build_lesson_evidence)",
            "input(refresh_catalog_nodes)",
            status_term("not_applicable", "refresh_catalog_only"),
            f"[reader_path({prolog_atom(REFRESH_ONLY_INPUT)})]",
        ),
    ))

    scopes = {
        "metaphor_renderer": len(families),
        "productive_lesson_structured_negative": len(productive_lessons),
        "lesson_evidence_pipeline": len(PIPELINE_INPUTS) + 1,
    }
    scope_counts: dict[str, Counter[str]] = {scope: Counter() for scope in scopes}
    for scope, status, _row in rows:
        scope_counts[scope][status] += 1

    lines = [
        "/** <module> Generated coverage and absence registry",
        " *",
        " * This bounded relation records receipt status for three live source sets:",
        " * Lakoff--Nunez metaphor families, IM lessons with compiled productive", 
        " * tasks, and the lesson-evidence pipeline inputs.  It does not claim a", 
        " * complete curriculum inventory.",
        " *",
        " * Statuses preserve distinctions found in the current tree:",
        " *   - present: a named source fact or parsed source record supports the receipt.",
        " *   - coverage_gap: the relevant machinery loads, but no receipt joins this subject.",
        " *   - broken_pipeline: a required upstream input is absent from this checkout.",
        " *   - path_drift: the reader names an old path while the source is present elsewhere.",
        " *   - not_applicable: the receipt belongs only to an optional build mode.",
        " *   - unknown: the available source record cannot establish the receipt.",
        " *",
        " * Generated by scripts/extract_coverage_absence_registry.py.",
        " * Regenerate: python3 scripts/extract_coverage_absence_registry.py",
        " */",
        "",
        ":- module(coverage_absence_registry,",
        "          [ coverage_receipt/4,",
        "            receipt_denominator/2,",
        "            receipt_status_count/3,",
        "            metaphor_without_renderer/2,",
        "            lesson_without_structured_negative/2",
        "          ]).",
        "",
    ]
    lines.extend(row for _scope, _status, row in rows)
    lines.append("")
    for scope, denominator in scopes.items():
        lines.append(f"receipt_denominator({scope}, {denominator}).")
    lines.append("")
    for scope in scopes:
        for status in STATUS_KINDS:
            lines.append(f"receipt_status_count({scope}, {status}, {scope_counts[scope][status]}).")
    lines.extend([
        "",
        "metaphor_without_renderer(Family, Status) :-",
        "    coverage_receipt(metaphor(Family), renderer, Status, _),",
        "    Status = coverage_gap(_).",
        "",
        "lesson_without_structured_negative(Lesson, Status) :-",
        "    coverage_receipt(lesson(Lesson), structured_negative, Status, _),",
        "    ( Status = coverage_gap(_) ; Status = broken_pipeline(_) ;",
        "      Status = path_drift(_, _) ; Status = unknown(_) ).",
        "",
    ])
    return "\n".join(lines)


def check_output(expected: str, output: Path) -> int:
    actual = output.read_text(encoding="utf-8") if output.is_file() else ""
    if actual == expected:
        print(f"coverage absence registry is current: {output.relative_to(ROOT) if output.is_relative_to(ROOT) else output}")
        return 0
    with tempfile.NamedTemporaryFile("w", encoding="utf-8", suffix=".pl", delete=False) as temporary:
        temporary.write(expected)
        temporary_path = Path(temporary.name)
    diff = list(difflib.unified_diff(
        actual.splitlines(), expected.splitlines(),
        fromfile=str(output), tofile=str(temporary_path), lineterm="",
    ))
    print("coverage absence registry is stale; run python3 scripts/extract_coverage_absence_registry.py", file=sys.stderr)
    for line in diff[:12]:
        print(line, file=sys.stderr)
    temporary_path.unlink(missing_ok=True)
    return 1


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="fail if the generated registry is stale")
    parser.add_argument("--output", type=Path, default=OUTPUT, help=argparse.SUPPRESS)
    args = parser.parse_args()
    output = args.output if args.output.is_absolute() else ROOT / args.output
    rendered = render_registry()
    if args.check:
        return check_output(rendered, output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(rendered, encoding="utf-8")
    print(f"wrote {output.relative_to(ROOT) if output.is_relative_to(ROOT) else output}: {len(rendered.splitlines())} lines")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
