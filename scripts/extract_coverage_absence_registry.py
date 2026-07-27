#!/usr/bin/env python3
"""Generate the bounded Hermes coverage-and-absence registry.

The registry records four live, finite subject sets: the joined metaphor
vocabulary, IM lessons with a compiled productive task, published IM lessons
with a native standard anchor, and the lesson-evidence pipeline inputs. It
records the receipt status rather than reducing every absence to a boolean.
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
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

# The receipt register has two readers. The ledger owns the rule for what counts
# as a fragment occurring in its source; this registry asks the ledger rather
# than keeping a second copy that can fall behind it.
from scripts.curriculum import build_lesson_evidence as evidence_ledger  # noqa: E402

OUTPUT = ROOT / "knowledge" / "index" / "coverage_absence_registry.pl"
ASSET_MANIFEST = ROOT / "hermes" / "representation" / "build_asset_manifest.py"
DRAWER = ROOT / "hermes" / "web" / "render" / "drawer.js"
METAPHOR_ART = ROOT / "hermes" / "web" / "metaphor-art.js"
MONITORING_VISUAL_CHECK = ROOT / "hermes" / "app" / "scripts" / "verify_monitoring_visuals.py"
NEGATIVE_RECEIPTS = ROOT / "scripts" / "curriculum" / "lesson_negative_receipts.json"

PIPELINE_INPUTS = (
    ("spine", "data/learningcommons/derived/im_k8_spine.json", None),
    ("standard_action_catalog", "data/learningcommons/derived/im_ccss_action_catalog.json", None),
    ("productive_deformation_catalog", "data/learningcommons/derived/im_productive_deformation_catalog.json", None),
    ("negative_receipts", "scripts/curriculum/lesson_negative_receipts.json", None),
    ("compiled_action_mappings", "curriculum/im/generated/compiled_action_mappings.pl", None),
    ("compiled_task_instances", "curriculum/im/generated/compiled_task_instances.pl", None),
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
use_module(formalization(grounding_metaphors)),
use_module(pml(mua_relations)),
use_module(render(grounding_to_primitive)),
use_module(render(representation_grammar)),
use_module(lessons('im/lesson_monitoring')),
use_module(lessons('im/generated/compiled_task_instances')),
use_module(index(im_lesson_identity)),
forall(lakoff_nunez_metaphor_family(F), format('family\t~w~n', [F])),
forall(grounding_metaphors:base_grounding_metaphor_definition(F, _, _, _), format('formal_metaphor\t~w~n', [F])),
forall(mua_relations:grounding_metaphor(_, M), format('mua_metaphor\t~w~n', [M])),
forall(grounding_to_primitive:metaphor_vocabulary_alias(C, S, N, Citation), format('alias\t~w\t~w\t~w\t~q~n', [C, S, N, Citation])),
forall(grounding_to_primitive:metaphor_vocabulary_noncorrespondence(S, N, Compared, Reason), format('noncorrespondence\t~w\t~w\t~q\t~w~n', [S, N, Compared, Reason])),
forall(grounding_to_primitive:primitive_renders_metaphor(P, M, Role), format('primitive\t~w\t~w\t~w~n', [P, M, Role])),
forall(representation_grammar:representation_render_status(R, renderable(Op)), format('renderer\t~w\t~w~n', [R, Op])),
forall((representation_grammar:representation_grounding(R, Grounding), sub_term(M, Grounding), atom(M)), format('grammar_grounding\t~w\t~w~n', [R, M])),
forall(compiled_task_instances:compiled_lesson_task_instance(L, productive-_, _), format('productive\t~w~n', [L])),
forall(compiled_task_instances:compiled_lesson_task_instance(L, deformation(_)-_, _), format('deformation\t~w~n', [L])),
forall(lesson_monitoring:explicit_lesson_misconception(L, _, _, _), format('explicit\t~w~n', [L])),
forall(im_lesson_identity:lesson_standard_reachability(L, Status, Evidence), format('standard_anchor\t~w\t~q\t~q~n', [L, Status, Evidence])),
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
    required = {
        "family",
        "formal_metaphor",
        "mua_metaphor",
        "alias",
        "noncorrespondence",
        "primitive",
        "renderer",
        "grammar_grounding",
        "productive",
        "deformation",
        "explicit",
        "standard_anchor",
    }
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


def python_assignment(path: Path, name: str) -> object:
    """Read one literal Python assignment without importing the module."""
    tree = ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
    mapping_node = next(
        (
            node.value
            for node in tree.body
            if isinstance(node, ast.Assign)
            and any(
                isinstance(target, ast.Name) and target.id == name
                for target in node.targets
            )
        ),
        None,
    )
    if mapping_node is None:
        raise RuntimeError(f"{name} is missing from {path.relative_to(ROOT)}")
    return ast.literal_eval(mapping_node)


def drawer_dispatch_formats() -> set[str]:
    """Parse the live drawer DISPATCH keys instead of carrying another list."""
    source = DRAWER.read_text(encoding="utf-8")
    match = re.search(r"\bvar\s+DISPATCH\s*=\s*\{(.*?)\n\s*\};", source, re.S)
    if match is None:
        raise RuntimeError("drawer.js has no parseable DISPATCH table")
    formats = set(re.findall(r"^\s*'([^']+)'\s*:", match.group(1), re.M))
    if not formats:
        raise RuntimeError("drawer.js DISPATCH table has no formats")
    return formats


def metaphor_art_keys() -> set[str]:
    """Read authored source-domain illustration methods from metaphor-art.js."""
    source = METAPHOR_ART.read_text(encoding="utf-8")
    keys = set(re.findall(r"^\s{2}([a-z][a-z0-9_]*)\(\)\s*\{", source, re.M))
    keys.discard("_fallback")
    if not keys:
        raise RuntimeError("metaphor-art.js has no illustration methods")
    return keys


def representation_scene_formats(dispatch_formats: set[str]) -> dict[str, set[str]]:
    """Join grammar names to scene formats, then require a live DISPATCH key."""
    declared = python_assignment(
        MONITORING_VISUAL_CHECK, "REPRESENTATION_SCENE_FORMATS"
    )
    if not isinstance(declared, dict):
        raise RuntimeError("REPRESENTATION_SCENE_FORMATS is not a dict")
    by_representation: dict[str, set[str]] = {}
    for representation, formats in declared.items():
        by_representation[str(representation)] = {
            str(scene_format)
            for scene_format in formats
            if str(scene_format) in dispatch_formats
        }
    # The seven spatial representations use the underscore-to-hyphen spelling
    # of their grammar id. This rule is checked against DISPATCH, not trusted.
    for scene_format in dispatch_formats:
        representation = scene_format.replace("-", "_")
        by_representation.setdefault(representation, set()).add(scene_format)
    return by_representation


def validate_receipt_path(receipt: dict) -> tuple[str, str | None]:
    """Classify a reviewed receipt's source path without repairing its record.

    Fragment verification is delegated, never restated. This reader once carried
    its own copy of the rule and fell behind the register twice: it knew only
    file-backed fragments after the v3 schema admitted fact-backed ones, and it
    still demanded a quotation sit on one physical line after the guides' hard
    wrapping was accounted for. Both faults were the same fault, so the two
    readers of one register now share one loader.
    """
    source = receipt["source"]
    expected = source["path"]
    if source.get("kind", "file") == "fact":
        return validate_receipt_facts(receipt)
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
    for fragment in source["fragments"]:
        line_number = fragment.get("line")
        if (
            not isinstance(line_number, int)
            or line_number < 1
            or line_number > len(lines)
            or not evidence_ledger._fragment_present(
                fragment.get("text", ""), lines, line_number
            )
        ):
            return "unknown", str(actual_path.relative_to(ROOT))
    return status, str(actual_path.relative_to(ROOT))


def validate_receipt_facts(receipt: dict) -> tuple[str, str | None]:
    """Classify a fact-backed receipt against the generated vision digest.

    A fact-backed fragment names an allowlisted generated predicate and quotes
    that fact's value. The digest is the source file, so a missing digest is a
    broken pipeline and a quotation absent from the named predicate is unknown.
    """
    digest_relative = str(evidence_ledger.VISION_DIGEST.relative_to(ROOT))
    if receipt["source"]["path"] != digest_relative:
        return "broken_pipeline", None
    if not evidence_ledger.VISION_DIGEST.is_file():
        return "broken_pipeline", None
    lesson_facts = _vision_facts().get(receipt["lesson"])
    if not lesson_facts:
        return "unknown", digest_relative
    for fragment in receipt["source"]["fragments"]:
        predicate = fragment.get("predicate")
        text = fragment.get("text")
        if predicate not in evidence_ledger.VISION_FACT_PREDICATES:
            return "unknown", digest_relative
        values = lesson_facts.get(predicate) or []
        if not isinstance(text, str) or not any(text in value for value in values):
            return "unknown", digest_relative
    return "present", digest_relative


_VISION_FACT_CACHE: dict[str, dict[str, list[str]]] | None = None


def _vision_facts() -> dict[str, dict[str, list[str]]]:
    global _VISION_FACT_CACHE
    if _VISION_FACT_CACHE is None:
        _VISION_FACT_CACHE = evidence_ledger._vision_fact_index()
    return _VISION_FACT_CACHE


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
    dispatch_formats = drawer_dispatch_formats()
    scene_formats = representation_scene_formats(dispatch_formats)
    art_keys = metaphor_art_keys()
    reviewed_receipts = load_negative_receipts()

    families = sorted(family[0] for family in inventory["family"])
    formal_metaphors = sorted(row[0] for row in inventory["formal_metaphor"])
    mua_values = sorted(row[0] for row in inventory["mua_metaphor"])
    source_names = {
        "geometry_inventory": set(families),
        "formal_definitions": set(formal_metaphors),
        "mua_relations": set(mua_values),
    }
    aliases = sorted(inventory["alias"])
    noncorrespondences = sorted(inventory["noncorrespondence"])
    alias_pairs = {(source, name) for _canonical, source, name, _citation in aliases}
    noncorrespondence_pairs = {
        (source, name)
        for source, name, _compared_sources, _reason in noncorrespondences
    }
    known_pairs = {
        (source, name)
        for source, names in source_names.items()
        for name in names
    }
    unknown_aliases = alias_pairs - known_pairs
    if unknown_aliases:
        raise RuntimeError(
            "metaphor aliases cite names absent from their source: "
            + ", ".join(f"{source}:{name}" for source, name in sorted(unknown_aliases))
        )
    overlap = alias_pairs & noncorrespondence_pairs
    if overlap:
        raise RuntimeError(
            "metaphor names are both aliased and non-corresponding: "
            + ", ".join(f"{source}:{name}" for source, name in sorted(overlap))
        )
    unexamined = known_pairs - alias_pairs - noncorrespondence_pairs
    if unexamined:
        raise RuntimeError(
            "metaphor names lack an alias or explicit non-correspondence: "
            + ", ".join(f"{source}:{name}" for source, name in sorted(unexamined))
        )

    canonical_for_pair = {
        (source, name): canonical
        for canonical, source, name, _citation in aliases
    }
    canonical_by_raw: dict[str, str] = {}
    for (_source, name), canonical in canonical_for_pair.items():
        prior = canonical_by_raw.setdefault(name, canonical)
        if prior != canonical:
            raise RuntimeError(
                f"metaphor name {name} maps to both {prior} and {canonical}"
            )

    metaphor_members: dict[str, list[tuple[str, str]]] = defaultdict(list)
    for source, names in source_names.items():
        for name in names:
            if name == "no_metaphor_grounding":
                continue
            canonical = canonical_for_pair.get((source, name), name)
            metaphor_members[canonical].append((source, name))

    def canonical_name(name: str) -> str:
        return canonical_by_raw.get(name, name)

    primitive_rows = sorted(inventory["primitive"])
    renderers = {representation: operation for representation, operation in inventory["renderer"]}
    primitive_routes: dict[str, list[str]] = defaultdict(list)
    for primitive, metaphor, role in primitive_rows:
        canonical = canonical_name(metaphor)
        if canonical not in metaphor_members:
            continue
        for representation in sorted(primitive_to_representations.get(primitive, ())):
            for scene_format in sorted(scene_formats.get(representation, ())):
                primitive_routes[canonical].append(
                    "live_scene_route(primitive_to_dispatch, "
                    f"{prolog_atom(primitive)}, {prolog_atom(metaphor)}, "
                    f"{prolog_atom(role)}, {prolog_atom(representation)}, "
                    f"{prolog_atom(scene_format)})"
                )

    grammar_routes: dict[str, list[str]] = defaultdict(list)
    for representation, metaphor in sorted(inventory["grammar_grounding"]):
        canonical = canonical_name(metaphor)
        operation = renderers.get(representation)
        if canonical not in metaphor_members or operation is None:
            continue
        for scene_format in sorted(scene_formats.get(representation, ())):
            grammar_routes[canonical].append(
                "live_scene_route(representation_grammar, "
                f"{prolog_atom(representation)}, {prolog_atom(metaphor)}, "
                f"{prolog_atom(operation)}, {prolog_atom(scene_format)})"
            )

    art_by_metaphor = {canonical_name(name) for name in art_keys}
    unknown_art = art_by_metaphor - metaphor_members.keys()
    if unknown_art:
        raise RuntimeError(
            "metaphor-art.js keys are outside the joined vocabulary: "
            + ", ".join(sorted(unknown_art))
        )

    rows: list[tuple[str, str, str]] = []
    metaphor_status_counts: Counter[str] = Counter()
    metaphor_route_subjects: dict[str, set[str]] = defaultdict(set)
    for metaphor in sorted(metaphor_members):
        primitive_evidence = sorted(set(primitive_routes.get(metaphor, ())))
        grammar_evidence = sorted(set(grammar_routes.get(metaphor, ())))
        has_art = metaphor in art_by_metaphor
        route_kinds = []
        if primitive_evidence:
            route_kinds.append("primitive_to_dispatch")
            metaphor_route_subjects["primitive_to_dispatch"].add(metaphor)
        if grammar_evidence:
            route_kinds.append("representation_grammar")
            metaphor_route_subjects["representation_grammar"].add(metaphor)
        if has_art:
            metaphor_route_subjects["source_domain_art"].add(metaphor)

        membership_evidence = [
            f"source_name({prolog_atom(source)}, {prolog_atom(name)})"
            for source, name in sorted(metaphor_members[metaphor])
        ]
        evidence_items = membership_evidence + primitive_evidence + grammar_evidence
        if has_art:
            evidence_items.append(
                "source_domain_art('hermes/web/metaphor-art.js', "
                f"{prolog_atom(metaphor)})"
            )
        subject = f"metaphor({prolog_atom(metaphor)})"
        if route_kinds:
            route_list = "[" + ", ".join(route_kinds) + "]"
            if has_art:
                status = (
                    f"present(live_scene_renderer({route_list}), "
                    "source_domain_art)"
                )
            else:
                status = f"present(live_scene_renderer({route_list}))"
            metaphor_status_counts["live_scene_renderer"] += 1
        elif has_art:
            status = "coverage_gap(source_domain_art_only)"
            metaphor_status_counts["source_domain_art_only"] += 1
        else:
            status = "coverage_gap(no_live_renderer)"
            metaphor_status_counts["no_live_renderer"] += 1
        evidence = "[" + ", ".join(evidence_items) + "]"
        rows.append((
            "metaphor_renderer",
            status.split("(", 1)[0],
            receipt_row(subject, "renderer", status, evidence),
        ))

    productive_lessons = {lesson[0] for lesson in inventory["productive"]}
    deformation_lessons = {lesson[0] for lesson in inventory["deformation"]}
    explicit_lessons = {lesson[0] for lesson in inventory["explicit"]}
    # A receipt may name any lesson the inventory knows, not only one carrying
    # a compiled productive task. IM-G1-U2-L18 is diagnostic-ready on all five
    # receipts and sits outside the productive set, so the narrower test
    # crashed the build on correct data. The error is kept for a receipt naming
    # a lesson no inventory records, which is still worth refusing.
    known_lessons = productive_lessons | deformation_lessons | explicit_lessons
    unknown_receipt_lessons = set(reviewed_receipts) - known_lessons
    if unknown_receipt_lessons:
        raise RuntimeError("reviewed negative receipts name lessons no inventory records: " + ", ".join(sorted(unknown_receipt_lessons)))
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

    standard_anchor_detail_counts: Counter[str] = Counter()
    standard_anchor_lessons: set[str] = set()
    for lesson, status, evidence in sorted(inventory["standard_anchor"]):
        if lesson in standard_anchor_lessons:
            raise RuntimeError(f"duplicate standard-anchor reachability row for {lesson}")
        standard_anchor_lessons.add(lesson)
        if status == "present(atom_spelling)":
            detail = "atom_spelling"
        elif status == "present(dash_spelling)":
            detail = "dash_spelling"
        elif status == "present(both_spellings)":
            detail = "both_spellings"
        elif status == "coverage_gap(no_standard_anchor)":
            detail = "no_standard_anchor"
        else:
            raise RuntimeError(
                f"unknown standard-anchor reachability status for {lesson}: {status}"
            )
        standard_anchor_detail_counts[detail] += 1
        rows.append((
            "im_lesson_standard_anchor",
            status.split("(", 1)[0],
            receipt_row(
                f"lesson({prolog_atom(lesson)})",
                "standard_anchor",
                status,
                evidence,
            ),
        ))

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
        "metaphor_renderer": len(metaphor_members),
        "productive_lesson_structured_negative": len(productive_lessons),
        "im_lesson_standard_anchor": len(standard_anchor_lessons),
        "lesson_evidence_pipeline": len(PIPELINE_INPUTS) + 1,
    }
    scope_counts: dict[str, Counter[str]] = {scope: Counter() for scope in scopes}
    for scope, status, _row in rows:
        scope_counts[scope][status] += 1

    lines = [
        "/** <module> Generated coverage and absence registry",
        " *",
        " * This bounded relation records receipt status for four live source sets:",
        " * the joined geometry/formal/MUA metaphor vocabulary, IM lessons with",
        " * compiled productive tasks, the published K-8 lesson spine, and the",
        " * lesson-evidence pipeline inputs.",
        " *",
        " * Metaphor status keeps live scene renderers separate from source-domain",
        " * card art. A present(...) metaphor receipt names its live route kinds;",
        " * source_domain_art_only remains a coverage gap for student representations.",
        " * The generator reads drawer.js DISPATCH keys before accepting a live route.",
        " *",
        " * Statuses preserve distinctions found in the current tree:",
        " *   - present: a named source fact or live render route supports the receipt.",
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
        "            metaphor_render_status_count/2,",
        "            metaphor_route_count/2,",
        "            standard_anchor_reachability_count/2,",
        "            drawer_dispatch_count/1,",
        "            metaphor_without_renderer/2,",
        "            lesson_without_standard_anchor/2,",
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
    lines.append("")
    for status in (
        "live_scene_renderer",
        "source_domain_art_only",
        "no_live_renderer",
    ):
        lines.append(
            f"metaphor_render_status_count({status}, "
            f"{metaphor_status_counts[status]})."
        )
    for route in (
        "primitive_to_dispatch",
        "representation_grammar",
        "source_domain_art",
    ):
        lines.append(
            f"metaphor_route_count({route}, "
            f"{len(metaphor_route_subjects[route])})."
        )
    for detail in (
        "atom_spelling",
        "dash_spelling",
        "both_spellings",
        "no_standard_anchor",
    ):
        lines.append(
            f"standard_anchor_reachability_count({detail}, "
            f"{standard_anchor_detail_counts[detail]})."
        )
    lines.append(f"drawer_dispatch_count({len(dispatch_formats)}).")
    lines.extend([
        "",
        "metaphor_without_renderer(Metaphor, Status) :-",
        "    coverage_receipt(metaphor(Metaphor), renderer, Status, _),",
        "    Status = coverage_gap(_).",
        "",
        "lesson_without_standard_anchor(Lesson, Status) :-",
        "    coverage_receipt(lesson(Lesson), standard_anchor, Status, _),",
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
