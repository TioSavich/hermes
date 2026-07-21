#!/usr/bin/env python3
"""Build a cheap, typed evidence ledger for IM K-8 curriculum coverage.

The ledger separates standards-derived candidate actions from executable task
events.  A lesson aligned as ``addressing`` a CCSS standard inherits a
source-backed *candidate* action from that standard's wording.  Alignments
typed ``building_on`` or ``building_toward`` remain context only.  No standard
alignment supplies operands, a representation, or a deformation by itself.

The large Learning Commons node dump is needed only with ``--refresh-catalog``.
Normal builds use the compact, tracked standard-action catalog.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DERIVED = ROOT / "data" / "learningcommons" / "derived"
SPINE = DERIVED / "im_k8_spine.json"
CATALOG = DERIVED / "im_ccss_action_catalog.json"
PAIR_CATALOG = DERIVED / "im_productive_deformation_catalog.json"
OUTPUT = DERIVED / "im_lesson_evidence.json"
NEGATIVE_RECEIPTS = ROOT / "scripts" / "curriculum" / "lesson_negative_receipts.json"
NODES = ROOT / "data" / "learningcommons" / "nodes.jsonl"
COMPILED_MAPPINGS = ROOT / "lessons" / "im" / "generated" / "compiled_action_mappings.pl"
COMPILED_TASKS = ROOT / "lessons" / "im" / "generated" / "compiled_task_instances.pl"
ATLAS = ROOT / "scripts" / "bigred" / "iteration15" / "work" / "atlas" / "atlas_landscape.jsonl"

LESSON_ID_RE = re.compile(r"IM-G(K|[1-8])-U\d+-L\d+")
DIRECT_STRATEGY_RE = re.compile(
    r"(?:explicit_lesson_strategy|vision_lesson_strategy)\('([^']+)'"
)
COMPILED_STRATEGY_RE = re.compile(r"compiled_lesson_strategy\('([^']+)'\s*,")
DIRECT_STRATEGY_MAPPING_RE = re.compile(
    r"(?:explicit_lesson_strategy|vision_lesson_strategy)\(\s*'([^']+)'\s*,"
    r"\s*([a-z_]+)\s*,\s*([a-z_]+)\s*,"
)
COMPILED_STRATEGY_MAPPING_RE = re.compile(
    r"compiled_lesson_strategy\(\s*'([^']+)'\s*,\s*([a-z_]+)\s*,"
    r"\s*([a-z_]+)\s*,"
)
EXPLICIT_NEGATIVE_RE = re.compile(r"explicit_lesson_misconception\('([^']+)'\s*,")
PRODUCTIVE_TASK_RE = re.compile(
    r"compiled_lesson_task_instance\('([^']+)'\s*,\s*productive-"
)
DEFORMATION_TASK_RE = re.compile(
    r"compiled_lesson_task_instance\('([^']+)'\s*,\s*deformation\("
)

# These are lexical actions stated by standards, not mappings to executable
# automata.  Inflected forms are normalized only where the standard corpus uses
# them.  Keeping the lexical layer modest makes every inference inspectable.
ACTION_PATTERNS = {
    "add": r"\badd(?:ing)?\b",
    "analyze": r"\banaly(?:ze|zing)\b",
    "apply": r"\bapply(?:ing)?\b",
    "approximate": r"\bapproximat(?:e|ing)\b",
    "build": r"\bbuild(?:ing)?\b",
    "classify": r"\bclassif(?:y|ying)\b",
    "collect": r"\bcollect(?:ing)?\b",
    "compare": r"\bcompar(?:e|ing)\b",
    "compose": r"\bcompos(?:e|ing)\b",
    "compute": r"\bcomput(?:e|ing)\b",
    "construct": r"\bconstruct(?:ing)?\b",
    "convert": r"\bconvert(?:ing)?\b",
    "count": r"\bcount(?:ing)?\b",
    "cover": r"\bcover(?:ed|ing)?\b",
    "create": r"\bcreat(?:e|ing)\b",
    "decompose": r"\bdecompos(?:e|ing)\b",
    "describe": r"\bdescrib(?:e|ing)\b",
    "determine": r"\bdetermin(?:e|ing)\b",
    "develop": r"\bdevelop(?:ing)?\b",
    "display": r"\bdisplay(?:ing)?\b",
    "divide": r"\bdivid(?:e|ing)\b",
    "draw": r"\bdraw(?:ing)?\b",
    "estimate": r"\bestimat(?:e|ing)\b",
    "evaluate": r"\bevaluat(?:e|ing)\b",
    "explain": r"\bexplain(?:ing)?\b",
    "extend": r"\bextend(?:ing)?\b",
    "find": r"\bfind(?:ing)?\b",
    "gain": r"\bgain(?:ing)?\b",
    "generalize": r"\bgeneraliz(?:e|ing)\b",
    "generate": r"\bgenerat(?:e|ing)\b",
    "give": r"\bgiv(?:e|ing)\b",
    "graph": r"\bgraph(?:ing)?\b",
    "identify": r"\bidentif(?:y|ying)\b",
    "interpret": r"\binterpret(?:ing)?\b",
    "investigate": r"\binvestigat(?:e|ing)\b",
    "justify": r"\bjustif(?:y|ying)\b",
    "know": r"\bknow(?:ing)?\b",
    "make": r"\bmak(?:e|ing)\b",
    "measure": r"\bmeasur(?:e|ing)\b",
    "model": r"\bmodel(?:ing)?\b",
    "multiply": r"\bmultip(?:ly|lying)\b",
    "name": r"\bnam(?:e|ing)\b",
    "observe": r"\bobserv(?:e|ing)\b",
    "order": r"\border(?:ing)?\b",
    "pack": r"\bpack(?:ed|ing)?\b",
    "partition": r"\bpartition(?:ing)?\b",
    "perform": r"\bperform(?:ing)?\b",
    "prove": r"\bprov(?:e|ing)\b",
    "read": r"\bread(?:ing)?\b",
    "reason": r"\breason(?:ing)?\b",
    "recognize": r"\brecogniz(?:e|ing)\b",
    "record": r"\brecord(?:ing)?\b",
    "relate": r"\brelat(?:e|ing)\b",
    "report": r"\breport(?:ing)?\b",
    "represent": r"\brepresent(?:ing)?\b",
    "solve": r"\bsolv(?:e|ing)\b",
    "subtract": r"\bsubtract(?:ing)?\b",
    "summarize": r"\bsummariz(?:e|ing)\b",
    "understand": r"\bunderstand(?:ing)?\b",
    "use": r"\bus(?:e|ing)\b",
    "verify": r"\bverif(?:y|ying)\b",
    "work": r"\bwork(?:ing)?\b",
    "write": r"\bwrit(?:e|ing)\b",
}

REQUIRED_FOR_DIAGNOSIS = (
    "standard_action_candidate",
    "strategy_evidence",
    "executable_task",
    "structured_negative",
    "measured_transition",
)


def _standard_code(raw: str) -> str:
    return re.sub(r"\([^)]*\)$", "", raw)


def _action_terms(statement: str) -> list[str]:
    return [name for name, pattern in ACTION_PATTERNS.items()
            if re.search(pattern, statement, re.IGNORECASE)]


def _spine_codes(spine: list[dict]) -> set[str]:
    return {
        _standard_code(code)
        for lesson in spine
        for codes in lesson.get("ccss", {}).values()
        for code in codes
    }


def refresh_catalog(spine: list[dict]) -> dict:
    if not NODES.exists():
        raise SystemExit(f"cannot refresh standards catalog: missing {NODES}")
    wanted = _spine_codes(spine)
    best: dict[str, tuple[int, dict]] = {}
    for line in NODES.read_text(encoding="utf-8").splitlines():
        node = json.loads(line)
        if "StandardsFrameworkItem" not in node.get("labels", []):
            continue
        props = node.get("properties", {})
        code = props.get("statementCode")
        statement = (props.get("description") or "").strip()
        if code not in wanted or not statement:
            continue
        jurisdiction = props.get("jurisdiction") or "unknown"
        rank = 0 if jurisdiction == "Multi-State" else 1 if jurisdiction == "California" else 2
        entry = {
            "statement": statement,
            "actions": _action_terms(statement),
            "jurisdiction": jurisdiction,
            "source_identifier": node["identifier"],
        }
        if code not in best or rank < best[code][0]:
            best[code] = (rank, entry)
    missing = sorted(wanted - set(best))
    if missing:
        raise SystemExit(f"standards catalog missing descriptions: {missing}")
    no_actions = sorted(code for code, (_, entry) in best.items() if not entry["actions"])
    if no_actions:
        raise SystemExit(f"standards catalog has no lexical action for: {no_actions}")
    return {
        "schema": "im_ccss_action_catalog_v1",
        "register": "standard wording supplies candidate actions, not executable tasks",
        "source": "Learning Commons nodes.jsonl; CC BY 4.0",
        "standards": {code: best[code][1] for code in sorted(best)},
    }


def refresh_pair_catalog() -> dict:
    """Read the finite action-pair registry once into a cheap JSON catalog."""
    goal = (
        "use_module(strategies('math/action_automata_registry'))," 
        "forall(action_automata_registry:action_automaton_pair(Op,P,D,F),"
        "format('PAIR\\t~q\\t~q\\t~q\\t~q~n',[Op,P,D,F])),halt"
    )
    result = subprocess.run(
        ["swipl", "-q", "-l", str(ROOT / "paths.pl"), "-g", goal],
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=True,
    )
    pairs = []
    for line in result.stdout.splitlines():
        if not line.startswith("PAIR\t"):
            continue
        operation, productive, deformation, family = line.split("\t")[1:]
        pairs.append({
            "operation": operation,
            "productive": productive,
            "deformation": deformation,
            "family": family,
            "source": "strategies/math/action_automata_registry.pl:action_automaton_pair/4",
        })
    if not pairs:
        raise SystemExit("productive-deformation catalog refresh returned no pairs")
    return {
        "schema": "im_productive_deformation_catalog_v1",
        "register": (
            "Registry pairs nominate counterpossibilities for source-backed lesson actions; "
            "they are not lesson-specific negative receipts."
        ),
        "pairs": sorted(pairs, key=lambda row: (
            row["operation"], row["productive"], row["deformation"], row["family"]
        )),
    }


def _strategy_mappings(paths: list[Path], pattern: re.Pattern, origin: str) -> dict:
    mappings: dict[str, set[tuple[str, str, str]]] = {}
    for path in paths:
        if not path.exists():
            continue
        for lesson, operation, kind in pattern.findall(
            path.read_text(encoding="utf-8", errors="replace")
        ):
            mappings.setdefault(lesson, set()).add((operation, kind, origin))
    return mappings


def _merge_mappings(*groups: dict) -> dict:
    merged: dict[str, set[tuple[str, str, str]]] = {}
    for group in groups:
        for lesson, rows in group.items():
            merged.setdefault(lesson, set()).update(rows)
    return merged


def _validated_negative_receipts(
    lesson_ids: set[str], strategy_mappings: dict
) -> dict[str, list[dict]]:
    payload = json.loads(NEGATIVE_RECEIPTS.read_text(encoding="utf-8"))
    by_lesson: dict[str, list[dict]] = {}
    seen = set()
    for receipt in payload["receipts"]:
        lesson = receipt["lesson"]
        if lesson not in lesson_ids:
            raise SystemExit(f"negative receipt names unknown lesson: {lesson}")
        key = (lesson, receipt["alternative"])
        if key in seen:
            raise SystemExit(f"duplicate negative receipt: {key}")
        seen.add(key)
        intended = receipt["intended_action"]
        mapped = {
            (operation, kind)
            for operation, kind, _ in strategy_mappings.get(lesson, set())
        }
        intended_key = (intended["operation"], intended["kind"])
        if intended_key not in mapped:
            raise SystemExit(
                f"negative receipt intended action is not mapped for {lesson}: {intended_key}"
            )
        source = ROOT / receipt["source"]["path"]
        # Preserve the file's physical line numbering. ``splitlines()`` also
        # treats form-feed page markers as line breaks, which would drift from
        # the line numbers shown by editors and the existing compiler.
        lines = source.read_text(encoding="utf-8", errors="replace").split("\n")
        for fragment in receipt["source"]["fragments"]:
            line_number = fragment["line"]
            if fragment["text"] not in lines[line_number - 1]:
                raise SystemExit(
                    f"negative receipt excerpt drifted at {source}:{line_number}: "
                    f"{fragment['text']!r}"
                )
        by_lesson.setdefault(lesson, []).append(receipt)
    return by_lesson


def _lesson_ids(paths: list[Path], pattern: re.Pattern) -> set[str]:
    found: set[str] = set()
    for path in paths:
        if path.exists():
            found.update(pattern.findall(path.read_text(encoding="utf-8", errors="replace")))
    return found


def _measured_lessons() -> set[str]:
    found = set()
    if not ATLAS.exists():
        return found
    for line in ATLAS.read_text(encoding="utf-8").splitlines():
        try:
            lesson = json.loads(line).get("lesson")
        except json.JSONDecodeError:
            continue
        if lesson:
            found.add(lesson)
    return found


def build(spine: list[dict], catalog: dict, pair_catalog: dict) -> dict:
    grade_sources = sorted((ROOT / "lessons" / "im").glob("grade_*.pl"))
    direct_strategy = _lesson_ids(grade_sources, DIRECT_STRATEGY_RE)
    compiled_strategy = _lesson_ids([COMPILED_MAPPINGS], COMPILED_STRATEGY_RE)
    explicit_negative = _lesson_ids(grade_sources, EXPLICIT_NEGATIVE_RE)
    productive_task = _lesson_ids([COMPILED_TASKS], PRODUCTIVE_TASK_RE)
    deformation_task = _lesson_ids([COMPILED_TASKS], DEFORMATION_TASK_RE)
    measured = _measured_lessons()
    standards = catalog["standards"]
    strategy_mappings = _merge_mappings(
        _strategy_mappings(grade_sources, DIRECT_STRATEGY_MAPPING_RE, "direct_lesson_fact"),
        _strategy_mappings(
            [COMPILED_MAPPINGS], COMPILED_STRATEGY_MAPPING_RE, "compiled_source_mapping"
        ),
    )
    pair_index: dict[tuple[str, str], list[dict]] = {}
    for pair in pair_catalog["pairs"]:
        pair_index.setdefault((pair["operation"], pair["productive"]), []).append(pair)
    receipt_index = _validated_negative_receipts(
        {row["repo_id"] for row in spine}, strategy_mappings
    )

    lessons = []
    for row in spine:
        lesson_id = row["repo_id"]
        alignments = {}
        for relation in ("addressing", "building_on", "building_toward", "untyped"):
            codes = sorted({_standard_code(raw_code)
                            for raw_code in row.get("ccss", {}).get(relation, [])})
            if codes:
                # Fail here if a spine alignment cannot join to the compact
                # catalog. The lesson record stores codes only; statements and
                # lexical actions stay deduplicated in the catalog.
                for code in codes:
                    standards[code]
                alignments[relation] = codes
        addressed = alignments.get("addressing", [])
        standard_action_candidates = {
            code: standards[code]["actions"] for code in addressed
        }
        negative_candidates = []
        for operation, kind, origin in sorted(strategy_mappings.get(lesson_id, set())):
            for pair in pair_index.get((operation, kind), []):
                negative_candidates.append({
                    "operation": operation,
                    "productive": kind,
                    "deformation": pair["deformation"],
                    "family": pair["family"],
                    "mapping_origin": origin,
                    "pair_source": pair["source"],
                })
        negative_candidates = [
            dict(row) for row in {
                tuple(sorted(candidate.items())): candidate
                for candidate in negative_candidates
            }.values()
        ]
        negative_receipts = receipt_index.get(lesson_id, [])
        evidence = {
            "standard_action_candidate": bool(standard_action_candidates),
            "strategy_evidence": lesson_id in direct_strategy or lesson_id in compiled_strategy,
            "executable_task": lesson_id in productive_task,
            "negative_candidate": bool(negative_candidates),
            "structured_negative": (
                lesson_id in explicit_negative
                or lesson_id in deformation_task
                or bool(negative_receipts)
            ),
            "measured_transition": lesson_id in measured,
        }
        missing = [name for name in REQUIRED_FOR_DIAGNOSIS if not evidence[name]]
        if not missing:
            readiness = "diagnostic_ready"
        elif evidence["executable_task"] and evidence["strategy_evidence"]:
            readiness = "event_ready"
        elif evidence["executable_task"]:
            readiness = "executable_unlicensed"
        elif evidence["strategy_evidence"]:
            readiness = "strategy_attached"
        elif evidence["standard_action_candidate"]:
            readiness = "standard_action_candidate"
        else:
            readiness = "spine_only"
        lessons.append({
            "lesson": lesson_id,
            "grade": str(row["grade"]),
            "name": row["name"],
            "standard_alignments": alignments,
            "standard_action_candidates": standard_action_candidates,
            "negative_candidates": negative_candidates,
            "negative_receipts": negative_receipts,
            "evidence": evidence,
            "readiness": readiness,
            "missing_for_diagnosis": missing,
        })

    summary = Counter()
    by_grade: dict[str, Counter] = {}
    for lesson in lessons:
        grade = lesson["grade"]
        by_grade.setdefault(grade, Counter())["published"] += 1
        summary["published"] += 1
        for key, present in lesson["evidence"].items():
            if present:
                summary[key] += 1
                by_grade[grade][key] += 1
        if lesson["readiness"] == "diagnostic_ready":
            summary["diagnostic_ready"] += 1
            by_grade[grade]["diagnostic_ready"] += 1

    grade_order = ("K", "1", "2", "3", "4", "5", "6", "7", "8")
    return {
        "schema": "im_lesson_evidence_v1",
        "register": {
            "standard_action_candidate": "inferred only from an addressing alignment; not executable",
            "context_only": "building_on/building_toward alignment; no lesson action inferred",
            "negative_candidate": "registry-derived counterpossibility; requires lesson-source review",
            "structured_negative": "lesson-specific source receipt, explicit misconception, or compiled deformation",
            "diagnostic_ready": list(REQUIRED_FOR_DIAGNOSIS),
        },
        "sources": {
            "spine": str(SPINE.relative_to(ROOT)),
            "standard_catalog": str(CATALOG.relative_to(ROOT)),
            "productive_deformation_catalog": str(PAIR_CATALOG.relative_to(ROOT)),
            "negative_receipts": str(NEGATIVE_RECEIPTS.relative_to(ROOT)),
            "task_events": str(COMPILED_TASKS.relative_to(ROOT)),
            "atlas": str(ATLAS.relative_to(ROOT)),
        },
        "summary": dict(sorted(summary.items())),
        "by_grade": {grade: dict(sorted(by_grade.get(grade, {}).items())) for grade in grade_order},
        "lessons": lessons,
    }


def _render(payload: dict) -> str:
    return json.dumps(payload, indent=1, ensure_ascii=False, sort_keys=True) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--refresh-catalog", action="store_true")
    parser.add_argument("--refresh-pair-catalog", action="store_true")
    args = parser.parse_args()

    spine = json.loads(SPINE.read_text(encoding="utf-8"))
    if args.refresh_catalog:
        catalog = refresh_catalog(spine)
        rendered_catalog = _render(catalog)
        if args.check:
            if not CATALOG.exists() or CATALOG.read_text(encoding="utf-8") != rendered_catalog:
                print("stale generated standards catalog: run with --refresh-catalog", file=sys.stderr)
                return 1
        else:
            CATALOG.write_text(rendered_catalog, encoding="utf-8")
    else:
        catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
    if args.refresh_pair_catalog:
        pair_catalog = refresh_pair_catalog()
        rendered_pairs = _render(pair_catalog)
        if args.check:
            if not PAIR_CATALOG.exists() or PAIR_CATALOG.read_text(encoding="utf-8") != rendered_pairs:
                print(
                    "stale generated productive-deformation catalog: "
                    "run with --refresh-pair-catalog",
                    file=sys.stderr,
                )
                return 1
        else:
            PAIR_CATALOG.write_text(rendered_pairs, encoding="utf-8")
    else:
        pair_catalog = json.loads(PAIR_CATALOG.read_text(encoding="utf-8"))
    payload = build(spine, catalog, pair_catalog)
    rendered = _render(payload)
    if args.check:
        if not OUTPUT.exists() or OUTPUT.read_text(encoding="utf-8") != rendered:
            print(f"stale generated lesson evidence: run {Path(__file__).relative_to(ROOT)}", file=sys.stderr)
            return 1
    else:
        OUTPUT.write_text(rendered, encoding="utf-8")
    print(
        "lesson_evidence "
        + " ".join(f"{key}={value}" for key, value in payload["summary"].items())
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
