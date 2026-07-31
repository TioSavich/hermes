#!/usr/bin/env python3
"""Build the executable IM lesson-capability census.

The identity spine supplies the canonical curriculum denominator.  The guide
reader, task candidate extractor, compiled task runtime, evidence ledger, and
PUSU pass each supply a different rung.  Keeping their denominators and
per-lesson memberships together prevents a source count from being mistaken
for an execution count.
"""

from __future__ import annotations

import argparse
from collections import Counter, defaultdict
import json
from pathlib import Path
import random
import re
import subprocess
import sys


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts" / "curriculum"))

import compile_action_mappings as compiler  # noqa: E402
import pusu_pass  # noqa: E402


OUTPUT = (
    ROOT
    / "data"
    / "learningcommons"
    / "derived"
    / "im_lesson_capability_census.json"
)
SPINE = ROOT / "data" / "learningcommons" / "derived" / "im_k8_spine.json"
EVIDENCE = (
    ROOT / "data" / "learningcommons" / "derived" / "im_lesson_evidence.json"
)
PUSU = ROOT / "data" / "learningcommons" / "derived" / "pusu_pass.json"
VISION = ROOT / "curriculum" / "im" / "generated" / "vision_lesson_digest.pl"
SEED = 208_20260730
SCHEMA = "im_lesson_capability_census_v1"
LESSON_RE = re.compile(r"^IM-G(K|[1-8])-U(\d+)-L(\d+)$")
VISION_LESSON_RE = re.compile(r"^vision_lesson\('([^']+)'", re.MULTILINE)
LIVE_CONTRAST_STATUSES = {
    "agrees_at_input",
    "normative_contrast",
    "separates",
}
CONTENT_DOMAIN_NAMES = {
    "CC": "counting_and_cardinality",
    "OA": "operations_and_algebraic_thinking",
    "NBT": "number_and_operations_base_ten",
    "NF": "number_and_operations_fractions",
    "MD": "measurement_and_data",
    "G": "geometry",
    "RP": "ratios_and_proportional_relationships",
    "NS": "number_system",
    "EE": "expressions_and_equations",
    "SP": "statistics_and_probability",
    "F": "functions",
}
EARLY_RUNGS = (
    "in_canonical_corpus",
    "readable",
    "has_candidates",
    "executable_task",
    "measured_transition",
    "diagnostic_ready",
)


def fail(message: str) -> "NoReturn":
    raise SystemExit(f"build_im_lesson_capability_census.py: {message}")


def load_json(path: Path) -> object:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        fail(f"cannot read {path}: {exc}")


def lesson_parts(lesson: str) -> tuple[str, int, int]:
    match = LESSON_RE.fullmatch(lesson)
    if match is None:
        fail(f"invalid IM lesson id: {lesson}")
    return match.group(1), int(match.group(2)), int(match.group(3))


def lesson_key(lesson: str) -> tuple[int, int, int]:
    grade, unit, number = lesson_parts(lesson)
    return (0 if grade == "K" else int(grade), unit, number)


def source_corpus() -> tuple[list[compiler.LessonDoc], set[str]]:
    docs = compiler.read_teacher_guides(ROOT)
    vision = set(VISION_LESSON_RE.findall(VISION.read_text(encoding="utf-8")))
    if len(docs) != len({doc.code for doc in docs}):
        fail("teacher-guide reader returned duplicate lesson identities")
    return docs, vision


def candidate_corpus(
    docs: list[compiler.LessonDoc],
) -> tuple[
    list[compiler.StudentTaskSpan],
    list[compiler.TaskCandidate],
    dict[str, set[tuple[str, str]]],
]:
    """Run the same attachment and task-candidate path as the compiler."""
    rules = load_json(compiler.DEFAULT_RULES)
    explicit = compiler.read_explicit_mappings(ROOT)
    scope_titles = compiler.read_scope_titles(ROOT)
    tracked = compiler.extract_student_task_spans(docs)
    recovered = compiler.read_recovered_task_spans(ROOT, tracked)

    legacy = compiler.compile_rule_mappings(docs, rules, explicit)
    baseline = sorted(
        set(
            legacy
            + compiler.compile_scope_batches(rules, explicit, scope_titles)
        )
    )
    attachments = {code: set(rows) for code, rows in explicit.items()}
    for mapping in baseline:
        attachments.setdefault(mapping.code, set()).add(
            (mapping.operation, mapping.kind)
        )
    initial = compiler.extract_task_candidates(
        tracked + recovered, attachments
    )
    derived = compiler.compile_task_derived_mappings(
        initial, explicit, baseline
    )
    baseline = sorted(set(baseline + derived))
    baseline_attached = set(explicit) | {
        mapping.code for mapping in baseline
    }
    span_mappings = compiler.compile_task_span_rule_mappings(
        docs, rules, baseline_attached, tracked
    )
    mappings = sorted(set(baseline + span_mappings))
    attachments = {code: set(rows) for code, rows in explicit.items()}
    for mapping in mappings:
        attachments.setdefault(mapping.code, set()).add(
            (mapping.operation, mapping.kind)
        )
    candidates = compiler.extract_task_candidates(
        tracked + recovered, attachments
    )
    return tracked, candidates, attachments


RUNTIME_PROBE = r"""
census_declared_absent(Evidence) :-
    sub_term(witness_class(declared_absent), Evidence), !.

census_trace(Goal, Outcome) :-
    Goal = action_automata_registry:run_action_automaton(_, _, _, _, _, Trace),
    is_list(Trace), !.
census_trace(_, Outcome) :-
    is_dict(Outcome), get_dict(trace, Outcome, Trace), is_list(Trace).

census_task(Code, Task, HasResult, HasTrace) :-
    pusu_run_productive(Code, Task, Outcome, Goal, _, _),
    ( pusu_result(Outcome, _) -> HasResult = true ; HasResult = false ),
    ( HasResult == true, census_trace(Goal, Outcome)
    -> HasTrace = true
    ;  HasTrace = false
    ).

census_scan(_, [], ResultTask, TraceTask, ResultTask, TraceTask).
census_scan(_, _, ResultTask, TraceTask, ResultTask, TraceTask) :-
    TraceTask \== "", !.
census_scan(Code, [Task|Rest], Result0, Trace0, Result, Trace) :-
    census_task(Code, Task, HasResult, HasTrace),
    pusu_text(Task, TaskText),
    ( Result0 == "", HasResult == true -> Result1 = TaskText ; Result1 = Result0 ),
    ( Trace0 == "", HasTrace == true -> Trace1 = TaskText ; Trace1 = Trace0 ),
    census_scan(Code, Rest, Result1, Trace1, Result, Trace).

census_code(Code, Row) :-
    findall(Task,
            ( compiled_task_instances:compiled_lesson_task_instance(
                  Code, productive-Task, Evidence),
              \+ census_declared_absent(Evidence)
            ),
            Tasks0),
    sort(Tasks0, Tasks),
    length(Tasks, TaskCount),
    census_scan(Code, Tasks, "", "", ResultTask, TraceTask),
    ( ResultTask == "" -> Executable = false ; Executable = true ),
    ( TraceTask == "" -> Measured = false ; Measured = true ),
    Row = _{lesson:Code, task_count:TaskCount, executable:Executable,
            measured_trace:Measured, result_task:ResultTask,
            trace_task:TraceTask}.

census_main(Codes) :-
    forall(member(Code, Codes),
           ( census_code(Code, Row),
             write('CENSUS\t'),
             json_write_dict(current_output, Row, [width(1000000)]), nl,
             flush_output
           )),
    halt.
"""


def runtime_probe(lessons: list[str]) -> dict[str, dict]:
    """Run every compiled productive lesson until a trace is found."""
    program = (
        pusu_pass.PROLOG_RUNNER
        + "\n"
        + RUNTIME_PROBE
        + "\n:- census_main("
        + pusu_pass.prolog_list(lessons)
        + ").\n"
    )
    try:
        proc = subprocess.run(
            [
                "swipl",
                "-q",
                "-l",
                str(ROOT / "paths.pl"),
                "-g",
                "consult(user),halt",
            ],
            cwd=ROOT,
            input=program,
            text=True,
            capture_output=True,
            check=False,
            timeout=max(30 * 60, 5 * 60 * len(lessons)),
        )
    except FileNotFoundError:
        fail("swipl is required for the executable lesson census")
    except subprocess.TimeoutExpired:
        fail("current runtime census exceeded its whole-process budget")
    if proc.returncode:
        fail(
            f"SWI-Prolog runtime census failed ({proc.returncode}): "
            f"{proc.stderr.strip()}"
        )
    rows: dict[str, dict] = {}
    for line in proc.stdout.splitlines():
        if not line.startswith("CENSUS\t"):
            continue
        row = json.loads(line.split("\t", 1)[1])
        rows[row["lesson"]] = row
    if set(rows) != set(lessons):
        fail(
            "runtime census returned the wrong lesson population: "
            f"expected={len(lessons)} actual={len(rows)}"
        )
    return rows


def current_pusu_spot_checks(
    pusu_rows: dict[str, dict],
) -> dict:
    """Re-run a deterministic random member of every PUSU claim class."""
    rng = random.Random(SEED)
    strata: dict[str, list[str]] = defaultdict(list)
    for lesson, row in pusu_rows.items():
        strata[f"verdict:{row['pusu']}"].append(lesson)
        for contrast in row["contrasts"]:
            if contrast.get("status") in LIVE_CONTRAST_STATUSES:
                strata[f"live_source:{contrast.get('source')}"].append(lesson)
    samples = {
        name: rng.choice(sorted(set(lessons), key=lesson_key))
        for name, lessons in sorted(strata.items())
        if lessons
    }
    selected = sorted(set(samples.values()), key=lesson_key)
    rerun = {
        row["lesson"]: row for row in pusu_pass.run_engine(selected)
    }
    failures = []
    for lesson in selected:
        expected = pusu_rows[lesson]
        actual = rerun[lesson]
        if actual["pusu"] != expected["pusu"]:
            failures.append(
                {
                    "lesson": lesson,
                    "expected": expected["pusu"],
                    "actual": actual["pusu"],
                }
            )
    return {
        "seed": SEED,
        "selection": "one pseudorandom lesson per verdict and live route source",
        "strata": samples,
        "sample_size": len(selected),
        "lessons": selected,
        "failures": failures,
    }


def content_domains(spine_row: dict) -> list[str]:
    domains = set()
    for code in spine_row.get("ccss", {}).get("addressing", []):
        parts = code.split(".")
        if len(parts) >= 2:
            domains.add(CONTENT_DOMAIN_NAMES.get(parts[1], parts[1].lower()))
    return sorted(domains or {"no_addressing_domain"})


def pusu_live(row: dict | None) -> bool:
    return bool(
        row
        and any(
            contrast.get("status") in LIVE_CONTRAST_STATUSES
            for contrast in row["contrasts"]
        )
    )


def rung_memberships(
    *,
    canonical: bool,
    readable: bool,
    candidates: int,
    runtime: dict | None,
    evidence: dict | None,
    pusu: dict | None,
) -> dict[str, bool]:
    diagnostic = bool(
        evidence and evidence["readiness"] == "diagnostic_ready"
    )
    strict = bool(pusu and pusu["pusu"] == "pass")
    wired = pusu_live(pusu)
    return {
        "in_canonical_corpus": canonical,
        "readable": canonical and readable,
        "has_candidates": canonical and candidates > 0,
        "executable_task": bool(
            canonical and runtime and runtime["executable"]
        ),
        "measured_transition": bool(
            canonical and runtime and runtime["measured_trace"]
        ),
        "diagnostic_ready": canonical and diagnostic,
        "strict_conjunction": canonical and strict,
        "wired_misconception_reachable": canonical and wired,
        "strict_and_wired": canonical and strict and wired,
    }


def rollup(rows: list[dict], label: str) -> dict:
    return {
        "label": label,
        "canonical_denominator": sum(
            row["identity_spine"] for row in rows
        ),
        "diagnostic_scope_denominator": sum(
            row["memberships"]["diagnostic_ready"] for row in rows
        ),
        "counts": {
            rung: sum(row["memberships"][rung] for row in rows)
            for rung in (
                *EARLY_RUNGS,
                "strict_conjunction",
                "wired_misconception_reachable",
                "strict_and_wired",
            )
        },
        "reader_status": {
            "unchecked_no_guide": sum(
                row["identity_spine"] and not row["sources"]["markdown_guide"]
                for row in rows
            ),
            "checked_and_empty_no_candidate": sum(
                row["memberships"]["readable"]
                and not row["memberships"]["has_candidates"]
                for row in rows
            ),
        },
    }


def cut_rollups(rows: list[dict]) -> dict:
    canonical = [row for row in rows if row["identity_spine"]]
    grades = {}
    for grade in ("K", "1", "2", "3", "4", "5", "6", "7", "8"):
        selected = [row for row in canonical if row["grade"] == grade]
        grade_row = rollup(selected, grade)
        grade_row["units"] = {
            str(unit): rollup(
                [row for row in selected if row["unit"] == unit],
                f"G{grade}U{unit}",
            )
            for unit in sorted({row["unit"] for row in selected})
        }
        grades[grade] = grade_row

    grade_bands = {
        "K-5": rollup(
            [row for row in canonical if row["grade"] in {"K", "1", "2", "3", "4", "5"}],
            "K-5",
        ),
        "6-8": rollup(
            [row for row in canonical if row["grade"] in {"6", "7", "8"}],
            "6-8",
        ),
    }

    operations = {}
    operation_names = sorted(
        {
            operation
            for row in canonical
            for operation in row["operation_attachments"]
        }
    )
    for operation in operation_names:
        selected = [
            row for row in canonical
            if operation in row["operation_attachments"]
        ]
        operations[operation] = rollup(selected, operation)
    operations["unattached"] = rollup(
        [row for row in canonical if not row["operation_attachments"]],
        "unattached",
    )

    domains = {}
    domain_names = sorted(
        {domain for row in canonical for domain in row["content_domains"]}
    )
    for domain in domain_names:
        domains[domain] = rollup(
            [row for row in canonical if domain in row["content_domains"]],
            domain,
        )
    return {
        "by_grade_band": grade_bands,
        "by_grade": grades,
        "by_operation_attachment": operations,
        "by_addressing_content_domain": domains,
        "multi_label_note": (
            "Operation and content-domain cuts overlap. Each cut prints its own "
            "canonical and diagnostic-scope denominators."
        ),
    }


def top_reason(reasons: Counter) -> dict:
    if not reasons:
        return {"reason": "none", "lessons": 0}
    reason, count = sorted(
        reasons.items(), key=lambda item: (-item[1], item[0])
    )[0]
    return {"reason": reason, "lessons": count}


def ladder(rows: list[dict], pusu_document: dict) -> list[dict]:
    canonical = [row for row in rows if row["identity_spine"]]
    canonical_count = len(canonical)
    diagnostic_count = sum(
        row["memberships"]["diagnostic_ready"] for row in canonical
    )
    entries = []

    definitions = {
        "in_canonical_corpus": (
            "Lesson identity occurs in the 1,308-row Learning Commons IM K-8 spine."
        ),
        "readable": (
            "The markdown guide reader returned the lesson and segmented at least "
            "one Student Task Statement span."
        ),
        "has_candidates": (
            "The live candidate extractor returned at least one operand-bearing "
            "task candidate from tracked or recovered spans."
        ),
        "executable_task": (
            "At least one non-declared-absent compiled productive task returned a "
            "result through the current registry-or-activity runtime."
        ),
        "measured_transition": (
            "At least one current compiled productive task returned a result and "
            "a concrete automaton trace list."
        ),
        "diagnostic_ready": (
            "The evidence ledger has standard action, strategy, compiled executable "
            "task, structured negative, and resolved Atlas transition fields."
        ),
        "strict_conjunction": (
            "The PUSU engine reports pass: all compiled productive tasks run and "
            "at least one active contrast route exists, with every active contrast "
            "separating, context-valid, or a verified normative trace."
        ),
        "strict_and_wired": (
            "The lesson passes PUSU and has a contrast route whose machine reached "
            "separates, agrees_at_input, or normative_contrast."
        ),
    }

    for rung in EARLY_RUNGS:
        reasons = Counter()
        for row in canonical:
            if row["memberships"][rung]:
                continue
            if rung == "readable":
                reasons["no_segmentable_markdown_guide"] += 1
            elif rung == "has_candidates":
                if not row["memberships"]["readable"]:
                    reasons["reader_unchecked_no_markdown_guide"] += 1
                else:
                    reasons["no_exact_operand_bearing_candidate"] += 1
            elif rung in {"executable_task", "measured_transition"}:
                runtime = row["runtime"]
                if runtime is None:
                    reasons["no_compiled_productive_task"] += 1
                elif not runtime["executable"]:
                    reasons["compiled_task_produced_no_current_result"] += 1
                else:
                    reasons["current_result_has_no_automaton_trace"] += 1
            elif rung == "diagnostic_ready":
                for missing in row["evidence"]["missing_for_diagnosis"]:
                    reasons[f"missing_{missing}"] += 1
        entries.append(
            {
                "id": rung,
                "count": sum(row["memberships"][rung] for row in canonical),
                "denominator": canonical_count,
                "denominator_source": str(SPINE.relative_to(ROOT)),
                "definition": definitions[rung],
                "binding_constraint": top_reason(reasons),
                "failure_reason_counts": dict(sorted(reasons.items())),
            }
        )

    verdicts = Counter(
        row["pusu"] for row in pusu_document["rows"]
        if row["pusu"] != "pass"
    )
    entries.append(
        {
            "id": "strict_conjunction",
            "count": sum(
                row["memberships"]["strict_conjunction"]
                for row in canonical
            ),
            "denominator": diagnostic_count,
            "denominator_source": (
                "data/learningcommons/derived/im_lesson_evidence.json "
                "diagnostic_ready population"
            ),
            "definition": definitions["strict_conjunction"],
            "binding_constraint": {
                "reason": "broken(contrast_cannot_run)",
                "lessons": verdicts["broken(contrast_cannot_run)"],
            },
            "failure_reason_counts": dict(sorted(verdicts.items())),
        }
    )

    wired_reasons = Counter()
    for row in canonical:
        if not row["memberships"]["diagnostic_ready"]:
            continue
        if not row["memberships"]["wired_misconception_reachable"]:
            wired_reasons["no_machine_reached_live_contrast"] += 1
        elif not row["memberships"]["strict_conjunction"]:
            wired_reasons["live_contrast_but_strict_conjunction_failed"] += 1
    entries.append(
        {
            "id": "strict_and_wired",
            "count": sum(
                row["memberships"]["strict_and_wired"]
                for row in canonical
            ),
            "denominator": diagnostic_count,
            "denominator_source": (
                "data/learningcommons/derived/im_lesson_evidence.json "
                "diagnostic_ready population"
            ),
            "definition": definitions["strict_and_wired"],
            "raw_wired_reachable_count": sum(
                row["memberships"]["wired_misconception_reachable"]
                for row in canonical
            ),
            "binding_constraint": top_reason(wired_reasons),
            "failure_reason_counts": dict(sorted(wired_reasons.items())),
        }
    )
    return entries


def cheapest_next_breadth(rows: list[dict], pusu_rows: dict[str, dict]) -> list[dict]:
    raw_only = set()
    share_after_raw = set()
    clean_no_route = set()
    for lesson, row in pusu_rows.items():
        if row["pusu"] == "pass":
            continue
        blockers = set()
        if not row["contrasts"]:
            blockers.add("no_route")
        if any(item["status"] != "runs" for item in row["productive"]):
            blockers.add("productive")
        for contrast in row["contrasts"]:
            if contrast.get("status") in {
                "rule_no_output",
                "cannot_run",
                "battery_absent",
                "context_unvalidated",
                "vacuous_pair",
                "attachment_unresolved",
            }:
                blockers.add(
                    contrast.get("kind")
                    or contrast.get("family")
                    or contrast["status"]
                )
            if contrast.get("diagnosis") in {
                "no_diagnosis",
                "recovered_different_error",
            }:
                blockers.add(f"diagnosis:{contrast['diagnosis']}")
        if blockers == {"raw_quotient_with_remainder"}:
            raw_only.add(lesson)
        if blockers in (
            {"share_smaller_into_larger"},
            {"raw_quotient_with_remainder", "share_smaller_into_larger"},
        ):
            share_after_raw.add(lesson)
        if blockers == {"no_route"}:
            clean_no_route.add(lesson)

    one_missing_negative = {
        row["lesson"]
        for row in rows
        if row["identity_spine"]
        and row["evidence"]["missing_for_diagnosis"]
        == ["structured_negative"]
    }
    return [
        {
            "rank": 1,
            "population": sorted(raw_only, key=lesson_key),
            "lessons": len(raw_only),
            "work_units": 1,
            "lessons_per_unit": len(raw_only),
            "next_rung": "strict_conjunction",
            "single_blocker": (
                "The registered raw_quotient_with_remainder rule produces no "
                "output at these lessons' compiled division inputs."
            ),
        },
        {
            "rank": 2,
            "population": sorted(share_after_raw, key=lesson_key),
            "lessons": len(share_after_raw),
            "work_units": 1,
            "lessons_per_unit": len(share_after_raw),
            "next_rung": "strict_conjunction",
            "dependency": (
                "Two of these lessons also need the rank-1 rule repair first."
            ),
            "single_blocker": (
                "The registered share_smaller_into_larger rule produces no "
                "output at the compiled division inputs."
            ),
        },
        {
            "rank": 3,
            "population": sorted(clean_no_route, key=lesson_key),
            "lessons": len(clean_no_route),
            "work_units": len(clean_no_route),
            "lessons_per_unit": 1,
            "next_rung": "strict_conjunction",
            "single_blocker": (
                "Each lesson has productive execution but no attached executable "
                "contrast route; each attachment requires lesson-specific evidence."
            ),
        },
        {
            "rank": 4,
            "population": sorted(one_missing_negative, key=lesson_key),
            "lessons": len(one_missing_negative),
            "work_units": len(one_missing_negative),
            "lessons_per_unit": 1,
            "next_rung": "diagnostic_ready",
            "single_blocker": (
                "Each lesson lacks only a source-backed structured negative; the "
                "registry candidate alone is not lesson-specific evidence."
            ),
        },
    ]


def build() -> dict:
    spine_rows = load_json(SPINE)
    evidence_document = load_json(EVIDENCE)
    pusu_document = load_json(PUSU)
    if not isinstance(spine_rows, list) or len(spine_rows) != 1308:
        fail("identity spine is not the expected 1,308-row list")
    if evidence_document.get("schema") != "im_lesson_evidence_v1":
        fail("unexpected lesson evidence schema")
    if pusu_document.get("schema") != "pusu_pass_v2":
        fail("unexpected PUSU schema")

    spine_by_id = {row["repo_id"]: row for row in spine_rows}
    evidence_by_id = {
        row["lesson"]: row for row in evidence_document["lessons"]
    }
    if set(evidence_by_id) != set(spine_by_id):
        fail("lesson evidence and identity spine populations disagree")
    pusu_by_id = {row["lesson"]: row for row in pusu_document["rows"]}
    diagnostic_ids = {
        lesson
        for lesson, row in evidence_by_id.items()
        if row["readiness"] == "diagnostic_ready"
    }
    if set(pusu_by_id) != diagnostic_ids:
        fail("PUSU scope and current diagnostic-ready population disagree")

    docs, vision_ids = source_corpus()
    doc_by_id = {doc.code: doc for doc in docs}
    tracked_spans, candidates, attachments = candidate_corpus(docs)
    spans_by_id: dict[str, list[compiler.StudentTaskSpan]] = defaultdict(list)
    for span in tracked_spans:
        spans_by_id[span.code].append(span)
    candidates_by_id: dict[str, list[compiler.TaskCandidate]] = defaultdict(list)
    for candidate in candidates:
        candidates_by_id[candidate.code].append(candidate)

    compiled_ids = {
        lesson
        for lesson, row in evidence_by_id.items()
        if row["evidence"]["executable_task"]
    }
    runtime = runtime_probe(sorted(compiled_ids, key=lesson_key))
    pusu_checks = current_pusu_spot_checks(pusu_by_id)
    if pusu_checks["failures"]:
        fail(f"PUSU spot checks disagreed: {pusu_checks['failures']}")

    union_ids = set(spine_by_id) | set(doc_by_id) | vision_ids
    rows = []
    for lesson in sorted(union_ids, key=lesson_key):
        grade, unit, number = lesson_parts(lesson)
        spine_row = spine_by_id.get(lesson)
        evidence_row = evidence_by_id.get(lesson)
        pusu_row = pusu_by_id.get(lesson)
        lesson_candidates = candidates_by_id.get(lesson, [])
        runtime_row = runtime.get(lesson)
        operations = sorted(
            {operation for operation, _ in attachments.get(lesson, set())}
        )
        memberships = rung_memberships(
            canonical=spine_row is not None,
            readable=bool(spans_by_id.get(lesson)),
            candidates=len(lesson_candidates),
            runtime=runtime_row,
            evidence=evidence_row,
            pusu=pusu_row,
        )
        rows.append(
            {
                "lesson": lesson,
                "grade": grade,
                "unit": unit,
                "lesson_number": number,
                "name": spine_row["name"] if spine_row else None,
                "identity_spine": spine_row is not None,
                "sources": {
                    "markdown_guide": lesson in doc_by_id,
                    "vision_digest": lesson in vision_ids,
                    "identity_spine": lesson in spine_by_id,
                },
                "reader": {
                    "span_count": len(spans_by_id.get(lesson, [])),
                    "status": (
                        "segmented"
                        if spans_by_id.get(lesson)
                        else "unchecked_no_markdown_guide"
                    ),
                },
                "candidates": {
                    "count": len(lesson_candidates),
                    "reviewable": sum(
                        candidate.status == "reviewable"
                        for candidate in lesson_candidates
                    ),
                    "rejected": sum(
                        candidate.status == "rejected"
                        for candidate in lesson_candidates
                    ),
                    "operations": sorted(
                        {candidate.operation for candidate in lesson_candidates}
                    ),
                },
                "runtime": runtime_row,
                "evidence": (
                    {
                        "readiness": evidence_row["readiness"],
                        "fields": evidence_row["evidence"],
                        "missing_for_diagnosis": evidence_row[
                            "missing_for_diagnosis"
                        ],
                    }
                    if evidence_row
                    else None
                ),
                "pusu": (
                    {
                        "verdict": pusu_row["pusu"],
                        "productive_runs": sum(
                            item["status"] == "runs"
                            for item in pusu_row["productive"]
                        ),
                        "productive_total": len(pusu_row["productive"]),
                        "contrast_count": len(pusu_row["contrasts"]),
                        "live_contrast_count": sum(
                            item.get("status") in LIVE_CONTRAST_STATUSES
                            for item in pusu_row["contrasts"]
                        ),
                        "live_sources": sorted(
                            {
                                item.get("source")
                                for item in pusu_row["contrasts"]
                                if item.get("status") in LIVE_CONTRAST_STATUSES
                            }
                        ),
                    }
                    if pusu_row
                    else None
                ),
                "operation_attachments": operations,
                "content_domains": (
                    content_domains(spine_row)
                    if spine_row
                    else ["outside_identity_spine"]
                ),
                "memberships": memberships,
            }
        )

    corpus_regions = Counter()
    for row in rows:
        sources = tuple(
            key
            for key in ("identity_spine", "markdown_guide", "vision_digest")
            if row["sources"][key]
        )
        corpus_regions["+".join(sources)] += 1

    artifact = {
        "schema": SCHEMA,
        "generated_by": (
            "scripts/curriculum/build_im_lesson_capability_census.py"
        ),
        "register": (
            "A denominator-explicit census of what Hermes can currently do with "
            "IM lessons. Source presence, parsing, compiled execution, measured "
            "traces, evidence readiness, strict PUSU, and live misconception "
            "routes remain separate claims."
        ),
        "source_populations": {
            "identity_spine": len(spine_by_id),
            "markdown_guides": len(doc_by_id),
            "vision_digest": len(vision_ids),
            "union": len(union_ids),
            "overlap_regions": dict(sorted(corpus_regions.items())),
            "vision_only_outside_spine": sorted(
                vision_ids - set(spine_by_id), key=lesson_key
            ),
        },
        "ladder": ladder(rows, pusu_document),
        "cuts": cut_rollups(rows),
        "cheapest_next_breadth": cheapest_next_breadth(rows, pusu_by_id),
        "spot_checks": {
            "in_canonical_corpus": {
                "sample_size": len(spine_by_id),
                "failures": 0,
                "method": "full identity-spine parse",
            },
            "readable": {
                "sample_size": len(doc_by_id),
                "failures": sum(
                    not spans_by_id[lesson] for lesson in doc_by_id
                ),
                "method": "full live guide-reader and span-segmenter run",
            },
            "has_candidates": {
                "sample_size": len(candidates_by_id),
                "failures": 0,
                "method": "full live candidate extractor run",
            },
            "executable_task": {
                "sample_size": len(runtime),
                "claimed_members_checked": sum(
                    row["executable"] for row in runtime.values()
                ),
                "claimed_member_failures": 0,
                "candidate_failures": sum(
                    not row["executable"] for row in runtime.values()
                ),
                "method": "full current compiled-task runtime probe",
            },
            "measured_transition": {
                "sample_size": len(runtime),
                "claimed_members_checked": sum(
                    row["measured_trace"] for row in runtime.values()
                ),
                "claimed_member_failures": 0,
                "candidate_failures": sum(
                    not row["measured_trace"] for row in runtime.values()
                ),
                "method": "full current result-plus-trace probe",
            },
            "diagnostic_ready": {
                "sample_size": len(diagnostic_ids),
                "failures": sum(
                    bool(evidence_by_id[lesson]["missing_for_diagnosis"])
                    for lesson in diagnostic_ids
                ),
                "method": "full five-field evidence conjunction",
            },
            "strict_and_wired": pusu_checks,
        },
        "lessons": rows,
    }
    return artifact


def render(payload: dict) -> str:
    return json.dumps(
        payload, indent=1, ensure_ascii=False, sort_keys=True
    ) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--output", type=Path, default=OUTPUT)
    args = parser.parse_args()

    payload = build()
    rendered = render(payload)
    if args.check:
        current = (
            args.output.read_text(encoding="utf-8")
            if args.output.exists()
            else ""
        )
        if current != rendered:
            print(
                "stale IM lesson capability census: run "
                "scripts/curriculum/build_im_lesson_capability_census.py",
                file=sys.stderr,
            )
            return 1
    else:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(rendered, encoding="utf-8")
    print(
        "im_lesson_capability_census "
        + " ".join(
            f"{row['id']}={row['count']}/{row['denominator']}"
            for row in payload["ladder"]
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
