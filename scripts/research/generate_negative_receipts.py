#!/usr/bin/env python3
"""Propose and source-gate lesson-specific structured-negative receipts.

REALLMS drafts one v3 receipt from a lesson's registry candidates and either
its line-numbered teacher guide or its generated vision-digest facts. Before
any candidate reaches the drafting prompt, its alternative is executed through
run_action_automaton on the lesson's own op-matching compiled operand pairs;
a candidate whose alternative cannot execute anywhere is withheld with every
attempted run recorded, and a candidate whose alternative the curated register
already holds for the lesson is withheld under the register's (lesson,
alternative) dedup key. Each completed lesson is checkpointed separately.
Accepted proposals remain in a generated review file; this script never edits
the curated receipt register.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import re
import ssl
import subprocess
import sys
import tempfile
from collections import Counter
from dataclasses import dataclass
from fractions import Fraction
from pathlib import Path
from typing import Any, Callable


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from scripts.curriculum.build_lesson_evidence import (  # noqa: E402
    VISION_DIGEST,
    VISION_FACT_PREDICATES,
    _validated_negative_receipts,
    _vision_fact_index,
)
from scripts.checks.automaton_input_contracts import contracts, shape_errors  # noqa: E402


LEDGER = ROOT / "data" / "learningcommons" / "derived" / "im_lesson_evidence.json"
CURATED_RECEIPTS = ROOT / "scripts" / "curriculum" / "lesson_negative_receipts.json"
GUIDE_ROOT = ROOT / "curriculum" / "im_teacher_guides"
LLM_PATH = ROOT / "hermes" / "app" / "llm.py"
COMPILED_TASKS = ROOT / "curriculum" / "im" / "generated" / "compiled_task_instances.pl"
CONTRACTS = ROOT / "knowledge" / "strategies" / "automaton_input_contracts.pl"
CONTRACT_FILTER_FIXTURE = ROOT / "scripts" / "checks" / "fixtures" / "negative_receipt_candidate_contract_whole_domain.json"
DEFAULT_OUTPUT = ROOT / "scripts" / "research" / "negative_receipts_out"
DEFAULT_LIMIT = 3
RUN_VERSION = "alternative_execution_filter_v4"
CONTRACT_FILTER_OPERATIONS = frozenset({"addition", "subtraction", "multiplication", "division"})
# Per-call budget for one run_action_automaton execution inside the draft-time
# batch; matches the task-179 batch check that classified the curated register.
EXECUTION_TIME_LIMIT_SECONDS = 2
PROLOG_ATOM_RE = re.compile(r"^[a-z][a-z0-9_]*$")
# Pass-6 standing finding 1: vision_lesson_boundary strings record the
# pipeline's own mapping narrative, not the lesson, so the drafter neither
# receives nor may cite them. The curated register's validator keeps the full
# predicate tuple for receipts already merged.
DRAFTING_FACT_PREDICATES = tuple(
    predicate
    for predicate in VISION_FACT_PREDICATES
    if predicate != "vision_lesson_boundary"
)
# Full mirror of the task_action_operands/4 head-to-operation map
# (formal/learner/activity_contract.pl): a compiled productive task head
# carries an operation only when that predicate maps it to one. This is the
# join the task-179 batch check used to find the 25 receipts naming operations
# their lessons' tasks never carry. The execution batch re-derives this map
# from the live predicate on every run and raises on any difference, so the
# mirror cannot drift silently.
TASK_HEAD_OPERATIONS = {
    "add": "addition",
    "subtract": "subtraction",
    "multiply": "multiplication",
    "divide": "division",
    "unit_fraction": "fraction",
    "iterate_improper_fraction": "fraction",
    "decimal_value": "decimal",
    "decimal_multiply": "decimal",
    "decimal_compare": "decimal",
    "decimal_add": "decimal",
    "decimal_subtract": "decimal",
    "regroup_decimal_units": "decimal",
    "signed_add": "integer",
    "scale_ratio": "ratio",
    "evaluate_expression": "algebraic",
    "solve_linear": "algebraic",
    "classify_shape": "geometry",
    "angle_measure": "geometry",
    "rectangle_area": "geometry",
    "compare_rectangle_areas": "geometry",
    "rectangle_missing_side_from_area": "geometry",
    "select_area_unit": "geometry",
    "unit_cube_volume": "geometry",
    "compare_solid_volumes": "geometry",
    "rectangle_perimeter": "geometry",
    "polygon_perimeter": "geometry",
    "symmetry_missing_side": "geometry",
    "rectangle_side_lengths_for_perimeter": "geometry",
    "construct_rectangle_with_perimeter": "geometry",
    "rectangle_missing_side_from_perimeter": "geometry",
    "compare_cardinalities": "counting",
    "compare_numerals_by_place_value": "counting",
    "count_collection": "counting",
    "inscribe_cardinality": "counting",
    "inscribe_place_value": "counting",
    "convert_measurement": "measurement",
    "measure_length": "measurement",
    "measured_quantity_change": "measurement",
    "read_liquid_volume": "measurement",
}
LESSON_RE = re.compile(r"IM-G(K|[1-8])-U(\d+)-L(\d+)")
COMPILED_TASK_RE = re.compile(
    r"^compiled_lesson_task_instance\('([^']+)',\s*productive-([a-z_]+)\(([^)]*)\),",
    re.MULTILINE,
)
# Head-only variant for operation presence: nested-paren task arguments
# (classify_shape, evaluate_expression) defeat COMPILED_TASK_RE's operand
# group, and the operation join needs only the head.
COMPILED_TASK_HEAD_RE = re.compile(
    r"^compiled_lesson_task_instance\('([^']+)',\s*productive-([a-z_]+)\(",
    re.MULTILINE,
)
VISION_COMPUTATION_RE = re.compile(
    r"^vision_lesson_computation\('([^']+)',\s*(\"(?:\\.|[^\"\\])*\")\s*,",
    re.MULTILINE,
)
COMPUTATION_TERM_RE = re.compile(r"([a-z_]+)\(([^()]*)\)$")
RECEIPT_FIELDS = {
    "lesson",
    "intended_action",
    "alternative",
    "material_incompatibility",
    "source_kind",
    "source",
}


@dataclass(frozen=True)
class LessonInput:
    lesson: str
    title: str
    grade: str
    candidates: list[dict[str, Any]]
    provenance_kind: str
    guide_path: Path | None
    guide_relative: str | None
    guide_text: str | None
    digest_facts: dict[str, list[str]]


Transport = Callable[[LessonInput, list[dict[str, str]], int], str]


def _candidate_operation(task_operation: str) -> str | None:
    # The computation-term grammar currently covers add/subtract/multiply/divide.
    # Registry candidates outside the corresponding four operation labels pass
    # unfiltered and are counted in the run-report disclosure below.
    return {
        "add": "addition",
        "subtract": "subtraction",
        "multiply": "multiplication",
        "divide": "division",
    }.get(task_operation)


def _numeric_operands(term: str) -> tuple[str, tuple[int | float, int | float], tuple[str, str]] | None:
    """Parse the binary numeric vocabulary shared by compiled and digest facts."""
    match = COMPUTATION_TERM_RE.fullmatch(term)
    if match is None:
        return None
    operation = _candidate_operation(match.group(1))
    values = [value.strip() for value in match.group(2).split(",")]
    if operation is None or len(values) != 2:
        return None
    try:
        fractions = [Fraction(value) for value in values]
    except (ValueError, ZeroDivisionError):
        return None
    normalized: list[int | float] = []
    for value in fractions:
        normalized.append(value.numerator if value.denominator == 1 else float(value))
    return operation, (normalized[0], normalized[1]), (values[0], values[1])


def _compiled_operand_domains() -> dict[str, dict[str, list[tuple[tuple[int | float, int | float], tuple[str, str]]]]]:
    domains: dict[str, dict[str, list[tuple[tuple[int | float, int | float], tuple[str, str]]]]] = {}
    for lesson, task_operation, raw_operands in COMPILED_TASK_RE.findall(
        COMPILED_TASKS.read_text(encoding="utf-8", errors="strict")
    ):
        parsed = _numeric_operands(f"{task_operation}({raw_operands})")
        if parsed is None:
            continue
        operation, operands, display = parsed
        domains.setdefault(lesson, {}).setdefault(operation, []).append((operands, display))
    return domains


def _digest_operand_domains() -> dict[str, dict[str, list[tuple[tuple[int | float, int | float], tuple[str, str]]]]]:
    domains: dict[str, dict[str, list[tuple[tuple[int | float, int | float], tuple[str, str]]]]] = {}
    for lesson, quoted_term in VISION_COMPUTATION_RE.findall(
        VISION_DIGEST.read_text(encoding="utf-8", errors="strict")
    ):
        parsed = _numeric_operands(json.loads(quoted_term))
        if parsed is None:
            continue
        operation, operands, display = parsed
        domains.setdefault(lesson, {}).setdefault(operation, []).append((operands, display))
    return domains


def _contract_index() -> dict[tuple[str, str], dict[str, Any]]:
    return {(row["operation"], row["kind"]): row for row in contracts()}


def _drafting_facts(
    fact_index: dict[str, dict[str, list[str]]], lesson: str
) -> dict[str, list[str]]:
    """Digest facts the drafter may quote: the allowlist minus the boundary narrative."""
    facts = fact_index.get(lesson, {})
    return {
        predicate: facts[predicate]
        for predicate in DRAFTING_FACT_PREDICATES
        if facts.get(predicate)
    }


def _compiled_operation_index() -> dict[str, dict[str, set[str]]]:
    """Per lesson: operations its compiled productive tasks carry, plus unmapped heads."""
    index: dict[str, dict[str, set[str]]] = {}
    for lesson, head in COMPILED_TASK_HEAD_RE.findall(
        COMPILED_TASKS.read_text(encoding="utf-8", errors="strict")
    ):
        entry = index.setdefault(lesson, {"operations": set(), "unmapped_heads": set()})
        operation = TASK_HEAD_OPERATIONS.get(head)
        if operation is None:
            entry["unmapped_heads"].add(head)
        else:
            entry["operations"].add(operation)
    return index


def filter_candidate_operations(
    row: dict[str, Any],
    *,
    operation_index: dict[str, dict[str, set[str]]],
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    """Annotate, without deleting, candidates whose operation no compiled task carries.

    Task-179 found 25 curated receipts naming an operation the lesson's
    compiled productive tasks never carry, so no operand pair exists to run
    the named pair on. The flag is a visible annotation on the run record,
    never a silent drop; flagged candidates are withheld from the drafting
    prompt so the class cannot be minted again.
    """
    entry = operation_index.get(
        row["lesson"], {"operations": set(), "unmapped_heads": set()}
    )
    operations = entry["operations"]
    join_range = set(TASK_HEAD_OPERATIONS.values())
    usable: list[dict[str, Any]] = []
    annotated: list[dict[str, Any]] = []
    for candidate in row["negative_candidates"]:
        candidate_copy = dict(candidate)
        if candidate["operation"] in operations:
            usable.append(candidate_copy)
            annotated.append(candidate_copy)
            continue
        candidate_copy["annotation"] = "operation_unmatched"
        candidate_copy["operation_evidence"] = {
            "source": "compiled_task_instances",
            "join": "task_action_operands head map over productive rows",
            "compiled_operations": sorted(operations),
            "unmapped_task_heads": sorted(entry["unmapped_heads"]),
            "operation_in_join_range": candidate["operation"] in join_range,
            "reason": (
                "the lesson's compiled productive tasks carry no operation the join recognizes"
                if not operations
                else f"no compiled productive task of the lesson carries {candidate['operation']}"
            ),
        }
        annotated.append(candidate_copy)
    return usable, annotated


def operation_filter_controls() -> str:
    """Exercise a live flagged/kept split, the join-range disclosure, and the empty domain."""
    ledger = json.loads(LEDGER.read_text(encoding="utf-8"))
    operation_index = _compiled_operation_index()
    live = next(row for row in ledger["lessons"] if row["lesson"] == "IM-G2-U5-L12")
    usable, annotated = filter_candidate_operations(live, operation_index=operation_index)
    kept = {candidate["productive"] for candidate in usable}
    flagged = {
        candidate["productive"]
        for candidate in annotated
        if candidate.get("annotation") == "operation_unmatched"
    }
    if "take_away_base_ones" not in kept:
        raise RuntimeError("operation control lost the subtraction candidate IM-G2-U5-L12 carries tasks for")
    if "recursive_place_value_inscription" not in flagged:
        raise RuntimeError("operation control failed to flag the counting candidate on IM-G2-U5-L12")
    counting = next(
        candidate
        for candidate in annotated
        if candidate["productive"] == "recursive_place_value_inscription"
    )
    # Counting heads (count_collection, inscribe_cardinality, ...) are in the
    # live task_action_operands range; the flag stands because this lesson's
    # compiled tasks are subtraction only.
    if not counting["operation_evidence"]["operation_in_join_range"]:
        raise RuntimeError("counting has task_action_operands heads and the join-range disclosure must say so")
    if "no compiled productive task of the lesson carries counting" not in counting["operation_evidence"]["reason"]:
        raise RuntimeError("counting flag on IM-G2-U5-L12 must name the lesson's own task domain as the reason")
    synthetic = {
        "lesson": "IM-CONTROL-NO-TASKS",
        "negative_candidates": [
            {"operation": "addition", "productive": "count_on_from_larger", "deformation": "count_all_when_count_on_available"}
        ],
    }
    usable, annotated = filter_candidate_operations(synthetic, operation_index=operation_index)
    if usable or annotated[0].get("annotation") != "operation_unmatched":
        raise RuntimeError("empty-domain control was not flagged operation_unmatched")
    if "no operation the join recognizes" not in annotated[0]["operation_evidence"]["reason"]:
        raise RuntimeError("empty-domain control does not say the lesson carries no mappable operation")
    return (
        "IM-G2-U5-L12 keeps its subtraction candidate and flags counting "
        "(no counting task on this lesson); empty-domain synthetic flags with its own reason"
    )


def filter_candidate_register_duplicates(
    candidates: list[dict[str, Any]],
    *,
    lesson: str,
    register_keys: set[tuple[str, str]],
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    """Annotate, without deleting, candidates the curated register already holds.

    The register's uniqueness key is (lesson, alternative), and defective
    receipts stay on the books with their failed warrant named, so a repair
    receipt must bind a different candidate. A candidate whose alternative the
    register already holds for this lesson is withheld from the drafting
    prompt as a visible annotation, never a silent drop.
    """
    usable: list[dict[str, Any]] = []
    annotated: list[dict[str, Any]] = []
    for candidate in candidates:
        candidate_copy = dict(candidate)
        if (lesson, candidate["deformation"]) not in register_keys:
            usable.append(candidate_copy)
            annotated.append(candidate_copy)
            continue
        candidate_copy["annotation"] = "register_duplicate"
        candidate_copy["register_evidence"] = {
            "dedup_key": [lesson, candidate["deformation"]],
            "register": str(CURATED_RECEIPTS.relative_to(ROOT)),
            "reason": (
                "the curated register already holds a receipt for this lesson "
                "and alternative; the register dedup key is (lesson, "
                "alternative), so a repair must bind a different candidate"
            ),
        }
        annotated.append(candidate_copy)
    return usable, annotated


def register_dedup_controls(register_keys: set[tuple[str, str]]) -> str:
    """Exercise a live register-held withhold and a live pass-through."""
    ledger = json.loads(LEDGER.read_text(encoding="utf-8"))
    held = next(row for row in ledger["lessons"] if row["lesson"] == "IM-G2-U1-L12")
    usable, annotated = filter_candidate_register_duplicates(
        held["negative_candidates"], lesson=held["lesson"], register_keys=register_keys
    )
    flagged = {
        candidate["deformation"]
        for candidate in annotated
        if candidate.get("annotation") == "register_duplicate"
    }
    if "drop_ones_after_base_takeaway" not in flagged:
        raise RuntimeError(
            "register control failed: IM-G2-U1-L12's registered alternative was not withheld"
        )
    synthetic = [
        {
            "operation": "addition",
            "productive": "count_on_from_larger",
            "deformation": "alternative_never_registered",
        }
    ]
    kept, _ = filter_candidate_register_duplicates(
        synthetic, lesson="IM-G2-U1-L12", register_keys=register_keys
    )
    if not kept:
        raise RuntimeError("register control withheld a candidate the register does not hold")
    return (
        "IM-G2-U1-L12's register-held alternative withheld under the "
        "(lesson, alternative) key; unregistered synthetic passes through"
    )


# One swipl batch per run resolves each candidate's registry pair, joins the
# lesson's compiled productive tasks through task_action_operands/4, and runs
# the alternative on every op-matching operand pair under a per-call time
# limit -- the same probe the task-179 batch check ran over the curated
# register. The driver also emits the live head-to-operation map so the
# static mirror above is verified on every run.
_EXECUTION_DRIVER = rf"""% Draft-time executability probe for negative-receipt candidates.
:- use_module(formal(learner/activity_contract)).
:- use_module(library(time)).
:- use_module(library(lists)).
:- use_module(library(aggregate)).

pair_status(Op, Alt, L, R, Status) :-
    catch(call_with_time_limit({EXECUTION_TIME_LIMIT_SECONDS},
              ( action_automata_registry:run_action_automaton(Op, Alt, L, R, Outcome, _)
              -> ( Outcome = action_outcome(_, Fields), member(result(Res), Fields)
                 -> Status = ran(Res)
                 ;  Status = ran(no_result_field) )
              ;  Status = refused )),
          Err,
          ( Err = time_limit_exceeded -> Status = timeout ; Status = error )).

probe_one(Lesson, Op, Intended, Alt) :-
    ( action_automata_registry:action_automaton_pair(Op, Intended, Alt, Family)
    -> PairStatus = pair
    ;  PairStatus = no_registry_pair, Family = none
    ),
    findall(L-R,
            ( compiled_task_instances:compiled_lesson_task_instance(Lesson, productive-Task, _),
              activity_contract:task_action_operands(Task, Op, L, R) ),
            Pairs0),
    sort(Pairs0, Pairs),
    length(Pairs, NPairs),
    ( PairStatus = no_registry_pair
    -> Statuses = []
    ;  findall(L-R-Status,
               ( member(L-R, Pairs), pair_status(Op, Alt, L, R, Status) ),
               Statuses)
    ),
    aggregate_all(count, member(_-_-ran(_), Statuses), Ran),
    format('CHECK\t~w\t~w\t~w\t~w\t~w\t~q\t~d\t~d~n',
           [Lesson, Op, Intended, Alt, PairStatus, Family, NPairs, Ran]),
    forall(member(L-R-Status, Statuses),
           format('PAIRRUN\t~w\t~w\t~w\t~w\t~q\t~q\t~q~n',
                  [Lesson, Op, Intended, Alt, L, R, Status])).

probe_main(FactsFile) :-
    consult(FactsFile),
    forall(activity_contract:task_action_operands(Task, Operation, _, _),
           ( functor(Task, Head, _),
             format('HEADOP\t~w\t~w~n', [Head, Operation]) )),
    forall(probe_triple(Lesson, Op, Intended, Alt),
           probe_one(Lesson, Op, Intended, Alt)),
    halt.
"""


def run_execution_probes(
    probes: list[tuple[str, str, str, str]],
) -> tuple[dict[tuple[str, str, str, str], dict[str, Any]], dict[str, Any]]:
    """Execute candidate alternatives on their lessons' operand pairs in one batch.

    Returns a verdict catalog keyed by (lesson, operation, intended,
    alternative) and batch statistics. Raises when the static
    TASK_HEAD_OPERATIONS mirror differs from the live task_action_operands
    map, when the batch fails, or when any probe comes back unanswered.
    """
    unique = sorted(set(probes))
    for lesson, operation, intended, alternative in unique:
        if "'" in lesson or "\\" in lesson:
            raise ValueError(f"unquotable lesson id in probe: {lesson!r}")
        for atom in (operation, intended, alternative):
            if not PROLOG_ATOM_RE.fullmatch(atom):
                raise ValueError(f"probe field is not a plain Prolog atom: {atom!r}")
    with tempfile.TemporaryDirectory(prefix="receipt_exec_probe_") as workdir:
        facts_path = Path(workdir) / "probe_triples.pl"
        facts_path.write_text(
            "".join(
                f"probe_triple('{lesson}', {operation}, {intended}, {alternative}).\n"
                for lesson, operation, intended, alternative in unique
            )
            or "probe_triple('IM-NONE', none, none, none) :- fail.\n",
            encoding="utf-8",
        )
        driver_path = Path(workdir) / "probe_driver.pl"
        driver_path.write_text(_EXECUTION_DRIVER, encoding="utf-8")
        result = subprocess.run(
            [
                "swipl",
                "-q",
                "-l",
                str(ROOT / "paths.pl"),
                "-l",
                str(driver_path),
                "-g",
                f"probe_main('{facts_path}')",
            ],
            cwd=ROOT,
            text=True,
            capture_output=True,
        )
    if result.returncode != 0:
        tail = "\n".join(result.stderr.strip().splitlines()[-8:])
        raise RuntimeError(f"execution probe batch failed (exit {result.returncode}):\n{tail}")
    head_map: dict[str, str] = {}
    catalog: dict[tuple[str, str, str, str], dict[str, Any]] = {}
    for line in result.stdout.splitlines():
        parts = line.split("\t")
        if parts[0] == "HEADOP" and len(parts) == 3:
            head_map[parts[1]] = parts[2]
        elif parts[0] == "CHECK" and len(parts) == 9:
            _, lesson, operation, intended, alternative, pair_status, family, npairs, ran = parts
            catalog[(lesson, operation, intended, alternative)] = {
                "pair_registered": pair_status == "pair",
                "family": None if family == "none" else family,
                "operand_pair_count": int(npairs),
                "ran_count": int(ran),
                "operand_pairs": [],
            }
        elif parts[0] == "PAIRRUN" and len(parts) == 8:
            _, lesson, operation, intended, alternative, left, right, status = parts
            catalog[(lesson, operation, intended, alternative)]["operand_pairs"].append(
                {"left": left, "right": right, "outcome": status}
            )
    if head_map != TASK_HEAD_OPERATIONS:
        static_only = sorted(set(TASK_HEAD_OPERATIONS.items()) - set(head_map.items()))
        live_only = sorted(set(head_map.items()) - set(TASK_HEAD_OPERATIONS.items()))
        raise RuntimeError(
            "TASK_HEAD_OPERATIONS no longer mirrors task_action_operands/4; "
            f"static-only={static_only} live-only={live_only}. "
            "Update the mirror before drafting."
        )
    unanswered = sorted(set(unique) - set(catalog))
    if unanswered:
        raise RuntimeError(f"execution probes came back unanswered: {unanswered[:5]}")
    for verdict in catalog.values():
        verdict["executable"] = (
            verdict["pair_registered"]
            and verdict["operand_pair_count"] > 0
            and verdict["ran_count"] > 0
        )
    stats = {
        "probed_candidates": len(catalog),
        "pair_runs": sum(len(verdict["operand_pairs"]) for verdict in catalog.values()),
        "head_map_verified": True,
    }
    return catalog, stats


def filter_candidate_executability(
    candidates: list[dict[str, Any]],
    *,
    lesson: str,
    execution_catalog: dict[tuple[str, str, str, str], dict[str, Any]],
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    """Annotate, without deleting, candidates whose alternative cannot execute.

    Task-179 found 19 curated receipts naming alternatives that either lack a
    registry pair or refuse every operand pair their lesson supplies; nothing
    ran them at drafting time. Here each candidate's alternative has been
    executed on the lesson's own op-matching compiled operand pairs before the
    prompt is built. A candidate whose alternative cannot execute on any pair
    is withheld with the attempted runs recorded -- a visible annotation,
    never a silent drop.
    """
    usable: list[dict[str, Any]] = []
    annotated: list[dict[str, Any]] = []
    for candidate in candidates:
        candidate_copy = dict(candidate)
        key = (lesson, candidate["operation"], candidate["productive"], candidate["deformation"])
        verdict = execution_catalog.get(key)
        if verdict is None:
            raise RuntimeError(f"candidate was never probed for execution: {key}")
        if verdict["executable"]:
            usable.append(candidate_copy)
            annotated.append(candidate_copy)
            continue
        if not verdict["pair_registered"]:
            reason_class = "no_registry_pair"
            reason = (
                f"no action_automaton_pair/4 row registers {candidate['deformation']} "
                f"against {candidate['productive']} for {candidate['operation']}, "
                "so there is nothing to execute"
            )
        elif verdict["operand_pair_count"] == 0:
            reason_class = "no_operand_pair"
            reason = (
                "the pair is registered but no compiled productive task of the "
                f"lesson supplies a {candidate['operation']} operand pair"
            )
        else:
            reason_class = "automaton_refuses_all_operands"
            timeouts = sum(
                run["outcome"] == "timeout" for run in verdict["operand_pairs"]
            )
            reason = (
                "the automaton refuses every op-matching operand pair the lesson supplies"
                + (f" ({timeouts} at the {EXECUTION_TIME_LIMIT_SECONDS}s limit)" if timeouts else "")
            )
        candidate_copy["annotation"] = "alternative_not_executable"
        candidate_copy["execution_evidence"] = {
            "source": "run_action_automaton/6 batch over op-matching compiled productive operand pairs",
            "join": "task_action_operands/4 (formal/learner/activity_contract.pl)",
            "pair_registered": verdict["pair_registered"],
            "family": verdict["family"],
            "attempted_pairs": verdict["operand_pairs"],
            "time_limit_seconds": EXECUTION_TIME_LIMIT_SECONDS,
            "reason_class": reason_class,
            "reason": reason,
        }
        annotated.append(candidate_copy)
    return usable, annotated


def execution_filter_controls() -> str:
    """Exercise a live kept/flagged split, a whole-pool refusal, and an unregistered synthetic."""
    ledger = json.loads(LEDGER.read_text(encoding="utf-8"))
    rows = {row["lesson"]: row for row in ledger["lessons"]}
    split_row = rows["IM-G2-U3-L18"]
    runnable = next(
        candidate
        for candidate in split_row["negative_candidates"]
        if candidate["deformation"] == "count_all_when_count_on_available"
    )
    refusing = next(
        candidate
        for candidate in split_row["negative_candidates"]
        if candidate["deformation"] == "drop_ones_after_base_takeaway"
    )
    whole_row = rows["IM-G3-U4-L1"]
    probes = [
        (split_row["lesson"], c["operation"], c["productive"], c["deformation"])
        for c in (runnable, refusing)
    ]
    probes += [
        (whole_row["lesson"], c["operation"], c["productive"], c["deformation"])
        for c in whole_row["negative_candidates"]
    ]
    probes.append(
        (split_row["lesson"], "addition", "count_on_from_larger", "alternative_never_registered")
    )
    catalog, _ = run_execution_probes(probes)
    usable, annotated = filter_candidate_executability(
        [runnable, refusing], lesson=split_row["lesson"], execution_catalog=catalog
    )
    if [c["deformation"] for c in usable] != ["count_all_when_count_on_available"]:
        raise RuntimeError(
            "execution control lost IM-G2-U3-L18's runnable addition candidate"
        )
    flagged = next(
        candidate
        for candidate in annotated
        if candidate.get("annotation") == "alternative_not_executable"
    )
    evidence = flagged["execution_evidence"]
    if (
        evidence["reason_class"] != "automaton_refuses_all_operands"
        or not evidence["attempted_pairs"]
    ):
        raise RuntimeError(
            "execution control expected drop_ones_after_base_takeaway to refuse "
            "with its attempted operand pairs recorded"
        )
    whole_usable, whole_annotated = filter_candidate_executability(
        whole_row["negative_candidates"],
        lesson=whole_row["lesson"],
        execution_catalog=catalog,
    )
    if whole_usable or not all(
        candidate.get("annotation") == "alternative_not_executable"
        for candidate in whole_annotated
    ):
        raise RuntimeError(
            "execution control expected IM-G3-U4-L1's whole pool withheld "
            "(share_into_divisor_groups refuses its exact-quotient operands)"
        )
    synthetic = {
        "operation": "addition",
        "productive": "count_on_from_larger",
        "deformation": "alternative_never_registered",
    }
    _, synthetic_annotated = filter_candidate_executability(
        [synthetic], lesson=split_row["lesson"], execution_catalog=catalog
    )
    synthetic_evidence = synthetic_annotated[0].get("execution_evidence", {})
    if (
        synthetic_annotated[0].get("annotation") != "alternative_not_executable"
        or synthetic_evidence.get("reason_class") != "no_registry_pair"
        or synthetic_evidence.get("pair_registered")
    ):
        raise RuntimeError("unregistered synthetic alternative was not flagged no_registry_pair")
    return (
        "IM-G2-U3-L18 keeps its runnable addition candidate and flags its "
        "refusing subtraction candidate with attempted pairs; IM-G3-U4-L1's "
        "whole pool withheld; unregistered synthetic flags no_registry_pair; "
        "head map verified live"
    )


def drafting_provenance_kind(lesson: str) -> str:
    """Use the same source-mode decision for controls and production drafting."""
    return "file" if guide_path(lesson).is_file() else "fact"


def filter_candidate_contracts(
    row: dict[str, Any],
    *,
    provenance_kind: str,
    compiled_domains: dict[str, dict[str, list[tuple[tuple[int | float, int | float], tuple[str, str]]]]],
    digest_domains: dict[str, dict[str, list[tuple[tuple[int | float, int | float], tuple[str, str]]]]],
    contract_index: dict[tuple[str, str], dict[str, Any]],
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    """Annotate, without deleting, candidates whose live operands miss a contract.

    File-backed drafting uses the compiler's task instances. Fact-backed drafting
    uses the digest computations that are actually supplied to the drafter; if
    that source has no computation facts, compiled instances remain the fallback.
    Thus a missing domain never becomes a reason to remove a registry row.
    """
    lesson = row["lesson"]
    selected_source = "compiled_task_instances"
    domains = compiled_domains.get(lesson, {})
    if provenance_kind == "fact" and digest_domains.get(lesson):
        selected_source = "vision_digest"
        domains = digest_domains[lesson]
    elif not domains and digest_domains.get(lesson):
        selected_source = "vision_digest"
        domains = digest_domains[lesson]

    usable: list[dict[str, Any]] = []
    annotated: list[dict[str, Any]] = []
    for candidate in row["negative_candidates"]:
        candidate_copy = dict(candidate)
        contract = contract_index.get((candidate["operation"], candidate["productive"]))
        candidates = domains.get(candidate["operation"], [])
        checks: list[tuple[tuple[str, str], list[str]]] = []
        if contract is not None:
            for operands, display in candidates:
                errors = shape_errors(contract["shape"], {"a": operands[0], "b": operands[1]})
                checks.append((display, errors))
        compatible = [display for display, errors in checks if not errors]
        # A partial mismatch is usable evidence for the same candidate, not a
        # reason to remove it. Only a nonempty operation bucket with no
        # contract-compatible pair is a cannot-run candidate.
        if not checks or compatible:
            usable.append(candidate_copy)
            annotated.append(candidate_copy)
            continue
        candidate_copy["annotation"] = "contract_mismatch"
        candidate_copy["contract_evidence"] = {
            "source": selected_source,
            "incompatible_operands": [
                {"operands": list(display), "errors": errors}
                for display, errors in checks
            ],
            "contract": contract["shape"],
        }
        annotated.append(candidate_copy)
    return usable, annotated


def contract_filter_controls() -> str:
    """Exercise production provenance, partial compatibility, and whole-domain refusal."""
    ledger = json.loads(LEDGER.read_text(encoding="utf-8"))
    eligible = {row["lesson"]: row for row in eligible_lessons(ledger)}
    compiled_domains = _compiled_operand_domains()
    digest_domains = _digest_operand_domains()
    index = _contract_index()
    # Control lessons must sit in the current eligible pool; IM-G6-U5-L13
    # left it when its pass-7 receipt was merged, so IM-G6-U3-L9 carries the
    # long_division partial-domain class in its place.
    reclassified = {
        "IM-G6-U2-L4": ("multiplication_fact_retrieval", ("7", "7")),
        "IM-G6-U3-L9": ("long_division", ("308", "11")),
        "IM-G7-U4-L6": ("measure_groups_of_size", ("78", "4")),
    }
    for lesson, (productive, compatible_pair) in reclassified.items():
        _, annotated = filter_candidate_contracts(
            eligible[lesson],
            provenance_kind=drafting_provenance_kind(lesson),
            compiled_domains=compiled_domains,
            digest_domains=digest_domains,
            contract_index=index,
        )
        matched = next(
            (
                candidate for candidate in annotated
                if candidate["productive"] == productive
                and candidate.get("annotation") != "contract_mismatch"
            ),
            None,
        )
        if matched is None:
            raise RuntimeError(f"partial-domain control incorrectly excluded {lesson}/{productive}")
        domains = digest_domains[lesson] if drafting_provenance_kind(lesson) == "fact" else compiled_domains[lesson]
        contract = index[(matched["operation"], matched["productive"])]
        if compatible_pair not in [
            display
            for operands, display in domains[matched["operation"]]
            if not shape_errors(contract["shape"], {"a": operands[0], "b": operands[1]})
        ]:
            raise RuntimeError(f"partial-domain control lost compatible pair {lesson}/{compatible_pair}")

    merged_keep = next(row for row in ledger["lessons"] if row["lesson"] == "IM-G6-U5-L12")
    if merged_keep["lesson"] in eligible:
        raise RuntimeError("merged integer keep unexpectedly entered the drafter pool")
    _, annotated = filter_candidate_contracts(
        merged_keep,
        provenance_kind=drafting_provenance_kind(merged_keep["lesson"]),
        compiled_domains=compiled_domains,
        digest_domains=digest_domains,
        contract_index=index,
    )
    if any(candidate.get("annotation") == "contract_mismatch" for candidate in annotated):
        raise RuntimeError("IM-G6-U5-L12 integer control was incorrectly flagged")
    fixture = json.loads(CONTRACT_FILTER_FIXTURE.read_text(encoding="utf-8"))
    synthetic_domains = {
        fixture["lesson"]: {
            fixture["operation"]: [
                ((int(fixture["operands"][0]), float(Fraction(fixture["operands"][1]))), tuple(fixture["operands"]))
            ]
        }
    }
    _, annotated = filter_candidate_contracts(
        fixture,
        provenance_kind=fixture["provenance_kind"],
        compiled_domains={},
        digest_domains=synthetic_domains,
        contract_index=index,
    )
    if annotated[0].get("annotation") != "contract_mismatch":
        raise RuntimeError("synthetic whole-domain mismatch control did not refuse")
    return (
        "gold controls reclassified through compatible pairs; "
        "IM-G6-U5-L12 production-provenance keep unflagged; "
        "synthetic whole-domain mismatch refused"
    )


def load_llm_module() -> Any:
    """Load the shared Hermes REALLMS client without importing the app."""
    spec = importlib.util.spec_from_file_location("hermes_reallms", LLM_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot import {LLM_PATH}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def call_reallms(
    llm: Any,
    messages: list[dict[str, str]],
    *,
    api_key: str,
    api_url: str,
    model: str,
    ssl_ctx: ssl.SSLContext,
    timeout: int,
) -> str:
    """Call the shared transport with resumable-batch failure behavior."""
    return llm.call_api_messages(
        messages,
        api_key=api_key,
        api_url=api_url,
        model=model,
        ssl_ctx=ssl_ctx,
        retries=3,
        timeout=timeout,
        fail_on_error=False,
    )


def guide_path(lesson: str) -> Path:
    match = LESSON_RE.fullmatch(lesson)
    if match is None:
        raise ValueError(f"unexpected lesson id: {lesson}")
    grade, unit, lesson_number = match.groups()
    grade_directory = "kindergarten" if grade == "K" else f"grade{grade}"
    return GUIDE_ROOT / grade_directory / f"unit{unit}" / f"lesson{lesson_number}.md"


def eligible_lessons(ledger: dict[str, Any]) -> list[dict[str, Any]]:
    return [
        row
        for row in ledger["lessons"]
        if row["missing_for_diagnosis"] == ["structured_negative"]
    ]


def ledger_census(
    ledger: dict[str, Any],
    eligible: list[dict[str, Any]],
    fact_index: dict[str, dict[str, list[str]]],
) -> dict[str, Any]:
    required = ledger["register"]["diagnostic_ready"]
    lacking = {
        receipt: sum(not row["evidence"][receipt] for row in ledger["lessons"])
        for receipt in required
    }
    grades = Counter(row["grade"] for row in eligible)
    candidate_counts = [len(row["negative_candidates"]) for row in eligible]
    guides_present = sum(guide_path(row["lesson"]).is_file() for row in eligible)
    digest_sources = sum(
        not guide_path(row["lesson"]).is_file()
        and bool(_drafting_facts(fact_index, row["lesson"]))
        for row in eligible
    )
    usable_sources = guides_present + digest_sources
    grade_6_7 = [row for row in eligible if row["grade"] in {"6", "7"}]
    grade_6_7_in_digest = sum(
        bool(_drafting_facts(fact_index, row["lesson"])) for row in grade_6_7
    )
    return {
        "published": len(ledger["lessons"]),
        "diagnostic_ready": ledger["summary"]["diagnostic_ready"],
        "lacking": lacking,
        "exactly_one_structured_negative": len(eligible),
        "grades": dict(sorted(grades.items())),
        "candidate_min": min(candidate_counts, default=0),
        "candidate_max": max(candidate_counts, default=0),
        "candidate_zero": sum(count == 0 for count in candidate_counts),
        "guides_present": guides_present,
        "digest_sources": digest_sources,
        "usable_sources": usable_sources,
        "sources_missing": len(eligible) - usable_sources,
        "grade_6_7_targets": len(grade_6_7),
        "grade_6_7_in_digest": grade_6_7_in_digest,
        "all_receipts_projection": ledger["summary"]["diagnostic_ready"] + len(eligible),
    }


def lesson_input(
    row: dict[str, Any],
    fact_index: dict[str, dict[str, list[str]]],
) -> LessonInput:
    path = guide_path(row["lesson"])
    if path.is_file():
        return LessonInput(
            lesson=row["lesson"],
            title=row["name"],
            grade=row["grade"],
            candidates=row["negative_candidates"],
            provenance_kind="file",
            guide_path=path,
            guide_relative=str(path.relative_to(ROOT)),
            guide_text=path.read_text(encoding="utf-8", errors="replace"),
            digest_facts={},
        )
    return LessonInput(
        lesson=row["lesson"],
        title=row["name"],
        grade=row["grade"],
        candidates=row["negative_candidates"],
        provenance_kind="fact",
        guide_path=None,
        guide_relative=None,
        guide_text=None,
        digest_facts=_drafting_facts(fact_index, row["lesson"]),
    )


_DRAFTING_RULES_HEAD = """A receipt earns its place only when the quoted text carries the lesson's own
material: a quantity, a referent, a relation, or what the task asks students to
do, named closely enough that the alternative would have to discard it.

Boundary revision-log disqualifying-vocabulary rule: a fragment containing
"first pass", "reclassif", "re-tagged", "mis-tagged", "DELETED",
"CORRECTION", "no automaton", or "kind NONE", or a fragment opening
"None.", is a record of the reading or its revision rather than lesson
evidence. Do not quote it. Abstain when it would be needed, and name the
Boundary revision-log disqualifying-vocabulary rule in the abstention reason.

These quotations disqualify a receipt. Each one produced a rejected receipt in
the previous review round:
- Text reporting how this pipeline tagged, mapped, or corrected the lesson.
  Wording such as "maps to", "is tagged", "the first pass mistagged them",
  "correctly keep op", or an automaton name standing on its own describes a
  classification of the lesson, not the lesson. A fragment naming concrete
  quantities or student work stays quotable when a tag rides along with it.
- A phrase taken out of the negation that governs it. A clause saying the
  tasks map to neither X nor Y does not assert Y.
- Text saying the lesson works in an operation other than the candidate's. If
  the source says the lesson is entirely multiplication, no division candidate
  survives it.
- Text reporting what the reading itself could not find or could not model. A
  fact saying a goal is not present on the pages, or that a step has no fitting
  automaton and falls outside the controlled arithmetic vocabulary, records a
  limit of the reading. It cannot establish that the lesson asks students to
  carry out the action the candidate names, and a receipt built on it asserts
  what its own source denies."""


_CANDIDATE_SELECTION_GUIDANCE = """Two candidate-selection rules from the previous review round:
- A division task whose divisor names how many groups, and whose quotient
  comes out exact, wants the fair_share_equal_groups intended action with the
  name_group_count_as_share_size alternative when that pair is supplied. The
  measure_groups_of_size / share_into_divisor_groups pair reads the divisor as
  a group size, and share_into_divisor_groups needs a nonzero remainder to
  misplace, so it cannot deform an exact division on the lesson's own numbers.
- Select add_instead_of_multiply only when the quoted text itself carries both
  factors: the number of groups and the size of each group. With one factor or
  neither in the quotation, the receipt collapses into "multiplication is not
  addition", a sentence that fits every multiplication lesson. Abstain or
  select another candidate instead."""


_DRAFTING_RULES_TAIL = """Abstain rather than select a candidate whose incompatibility reduces to one
operation not being another with no quantity named.

material_incompatibility runs one or two sentences of present-tense prose that
name the quantity or relation the lesson supplies and the one the alternative
would have to ignore. Do not restate the identifiers, do not hedge, and do not
reach for metaphors of sight for what students come to know.

Test the sentence this way: could it have been written without reading this
lesson? A sentence of the form "the lesson requires <operation> and the
alternative <deformation>" names the two identifiers over again and fits every
lesson in the curriculum that shares the operation. Sentences of that form were
rejected on review. Write instead what the source puts in play — the amounts,
the units, what is counted, shared, measured, or compared, what a diagram is
built to carry — and then say which of those the alternative discards. A
quotation naming only the lesson topic will not support such a sentence, so
abstain rather than write around it."""


_FILE_DISQUALIFIER = """- A sample student response performing the alternative. A guide that prints a
  move as an acceptable answer shows the lesson admits it, which is the
  inverse of a counterpossibility. A sample response performing the intended
  action remains quotable."""


def drafting_rules(*, file_backed: bool) -> str:
    """Return the review-derived rules, with the guide-only disqualifier when apt."""
    bullets = f"{_DRAFTING_RULES_HEAD}\n{_FILE_DISQUALIFIER}" if file_backed else _DRAFTING_RULES_HEAD
    return f"{bullets}\n\n{_CANDIDATE_SELECTION_GUIDANCE}\n\n{_DRAFTING_RULES_TAIL}"


def build_messages(
    item: LessonInput,
    schema: str,
    register: str,
) -> list[dict[str, str]]:
    if item.provenance_kind == "fact":
        quotable_facts = [
            {"predicate": predicate, "text": text}
            for predicate in DRAFTING_FACT_PREDICATES
            for text in item.digest_facts.get(predicate, [])
        ]
        system = f"""You draft one review-pending lesson_negative_receipts_v3 record.
Use only the supplied lesson facts. Select exactly one supplied candidate,
copy its operation and productive action into intended_action, and copy its
deformation into alternative. Quote only verbatim text from a supplied fact
and identify that fact's predicate. The quotation must help establish the
selected counterpossibility, not merely name a standard or lesson topic.
Explain that specific incompatibility in material_incompatibility. If the
facts do not establish any supplied candidate, answer exactly ABSTAIN:
followed by a short reason. Use vision_digest as source_kind. Answer with one
JSON object and no Markdown or surrounding prose.

{drafting_rules(file_backed=False)}"""
        user = f"""Lesson id: {item.lesson}
Lesson title: {item.title}

Registry-derived candidates:
{json.dumps(item.candidates, indent=2, ensure_ascii=False)}

Return this exact top-level shape:
{{
  "schema": {json.dumps(schema)},
  "register": {json.dumps(register, ensure_ascii=False)},
  "receipts": [
    {{
      "lesson": "{item.lesson}",
      "intended_action": {{"operation": "<candidate operation>", "kind": "<candidate productive>"}},
      "alternative": "<candidate deformation>",
      "material_incompatibility": "<specific explanation grounded in the fragments>",
      "source_kind": "vision_digest",
      "source": {{
        "kind": "fact",
        "path": "{VISION_DIGEST.relative_to(ROOT)}",
        "fragments": [{{"predicate": "<supplied predicate>", "text": "<verbatim substring from that fact>"}}]
      }}
    }}
  ]
}}

Quotable lesson facts:
{json.dumps(quotable_facts, indent=2, ensure_ascii=False)}"""
        return [
            {"role": "system", "content": system},
            {"role": "user", "content": user},
        ]

    if item.guide_text is None or item.guide_relative is None:
        raise ValueError(f"file-backed lesson has no teacher guide: {item.lesson}")
    numbered_guide = "\n".join(
        f"{number:04d}: {line}"
        for number, line in enumerate(item.guide_text.split("\n"), 1)
    )
    system = f"""You draft one review-pending lesson_negative_receipts_v3 record.
Use only the supplied lesson guide. Select exactly one supplied candidate,
copy its operation and productive action into intended_action, and copy its
deformation into alternative. Quote only text that appears on the cited
physical line. The quotation must help establish the selected
counterpossibility, not merely discuss the lesson topic. Explain that specific
incompatibility in material_incompatibility. If the guide does not establish
any supplied candidate, answer exactly ABSTAIN: followed by a short reason.
Use responding_to_student_thinking only for a passage under that heading;
otherwise use activity_guidance. Answer with one JSON object and no Markdown
or surrounding prose.

{drafting_rules(file_backed=True)}"""
    user = f"""Lesson id: {item.lesson}
Lesson title: {item.title}

Registry-derived candidates:
{json.dumps(item.candidates, indent=2, ensure_ascii=False)}

Return this exact top-level shape:
{{
  "schema": {json.dumps(schema)},
  "register": {json.dumps(register, ensure_ascii=False)},
  "receipts": [
    {{
      "lesson": "{item.lesson}",
      "intended_action": {{"operation": "<candidate operation>", "kind": "<candidate productive>"}},
      "alternative": "<candidate deformation>",
      "material_incompatibility": "<specific explanation grounded in the fragments>",
      "source_kind": "activity_guidance",
      "source": {{
        "path": "{item.guide_relative}",
        "fragments": [{{"line": 1, "text": "<verbatim substring from that line>"}}]
      }}
    }}
  ]
}}

Teacher guide with physical line numbers:
{numbered_guide}"""
    return [
        {"role": "system", "content": system},
        {"role": "user", "content": user},
    ]


def clean_response(response: str) -> str:
    text = response.strip()
    fenced = re.fullmatch(r"```(?:json)?\s*(.*?)\s*```", text, re.DOTALL)
    return fenced.group(1).strip() if fenced else text


def parse_proposal(response: str) -> tuple[dict[str, Any] | None, str | None]:
    cleaned = clean_response(response)
    if cleaned.upper().startswith("ABSTAIN"):
        _, _, reason = cleaned.partition(":")
        return None, "model abstained" + (f": {reason.strip()}" if reason.strip() else "")
    try:
        payload = json.loads(cleaned)
    except json.JSONDecodeError as exc:
        return None, f"response is not JSON: {exc.msg} at line {exc.lineno} column {exc.colno}"
    if not isinstance(payload, dict):
        return None, "proposal top level is not an object"
    return payload, None


def _typed_shape_fault(
    item: LessonInput, payload: dict[str, Any], schema: str, register: str
) -> str | None:
    if payload.get("schema") != schema:
        return f"proposal schema is not {schema}"
    if payload.get("register") != register:
        return "proposal register differs from the curated v3 register"
    receipts = payload.get("receipts")
    if not isinstance(receipts, list) or len(receipts) != 1:
        return "proposal must contain exactly one receipt"
    receipt = receipts[0]
    if not isinstance(receipt, dict) or not RECEIPT_FIELDS <= receipt.keys():
        return "proposal receipt is missing required v3 fields"
    if receipt.get("lesson") != item.lesson:
        return f"proposal names {receipt.get('lesson')!r}, expected {item.lesson}"
    intended = receipt.get("intended_action")
    source = receipt.get("source")
    if (
        not isinstance(intended, dict)
        or not isinstance(intended.get("operation"), str)
        or not isinstance(intended.get("kind"), str)
    ):
        return "proposal intended_action is not a typed operation/kind object"
    if (
        not isinstance(receipt.get("alternative"), str)
        or not isinstance(receipt.get("material_incompatibility"), str)
        or not receipt["material_incompatibility"].strip()
        or receipt.get("source_kind")
        not in {
            "responding_to_student_thinking",
            "activity_guidance",
            "vision_digest",
        }
    ):
        return "proposal receipt has an invalid alternative, explanation, or source_kind"
    if not isinstance(source, dict):
        return "proposal source is not an object"
    fragments = source.get("fragments")
    if not isinstance(fragments, list) or not fragments:
        return "proposal source must contain at least one fragment"
    if item.provenance_kind == "file":
        if receipt.get("source_kind") not in {
            "responding_to_student_thinking",
            "activity_guidance",
        }:
            return "file-backed proposal has an invalid source_kind"
        if source.get("kind", "file") != "file":
            return "file-backed proposal source kind must be file"
        if source.get("path") != item.guide_relative:
            return f"proposal source path must be {item.guide_relative}"
        for fragment in fragments:
            if (
                not isinstance(fragment, dict)
                or not isinstance(fragment.get("line"), int)
                or isinstance(fragment.get("line"), bool)
                or not isinstance(fragment.get("text"), str)
                or not fragment["text"]
            ):
                return "proposal source fragment is not a typed line/text object"
    else:
        digest_relative = str(VISION_DIGEST.relative_to(ROOT))
        if receipt.get("source_kind") != "vision_digest":
            return "fact-backed proposal source_kind must be vision_digest"
        if source.get("kind") != "fact":
            return "fact-backed proposal source kind must be fact"
        if source.get("path") != digest_relative:
            return f"proposal source path must be {digest_relative}"
        for fragment in fragments:
            if (
                isinstance(fragment, dict)
                and fragment.get("predicate") in VISION_FACT_PREDICATES
                and fragment.get("predicate") not in DRAFTING_FACT_PREDICATES
            ):
                return (
                    f"proposal cites {fragment['predicate']}, which is outside "
                    "the drafting fact allowlist"
                )
            if (
                not isinstance(fragment, dict)
                or fragment.get("predicate") not in DRAFTING_FACT_PREDICATES
                or not isinstance(fragment.get("text"), str)
                or not fragment["text"]
            ):
                return "proposal source fragment is not a typed predicate/text object"
    candidate_keys = {
        (candidate["operation"], candidate["productive"], candidate["deformation"])
        for candidate in item.candidates
    }
    proposed_key = (
        intended["operation"],
        intended["kind"],
        receipt["alternative"],
    )
    if proposed_key not in candidate_keys:
        return f"proposal does not name a supplied registry candidate: {proposed_key}"
    return None


def gate_proposal(
    item: LessonInput,
    payload: dict[str, Any],
    *,
    lesson_ids: set[str],
    strategy_mappings: dict[str, set[tuple[str, str, str]]],
    schema: str,
    register: str,
) -> tuple[bool, str, dict[str, Any] | None]:
    """Apply v3 typing, candidate identity, and the curated source validator."""
    shape_fault = _typed_shape_fault(item, payload, schema, register)
    if shape_fault:
        return False, shape_fault, None
    try:
        _validated_negative_receipts(
            lesson_ids,
            strategy_mappings,
            receipts_payload=payload,
        )
    except (SystemExit, KeyError, TypeError, ValueError) as exc:
        reason = str(exc).strip() or exc.__class__.__name__
        prefix = "negative receipt validation failed:\n- "
        if reason.startswith(prefix):
            reason = reason[len(prefix):].replace("\n- ", "; ")
        return False, reason, payload["receipts"][0]
    return True, "accepted by the v3 source gate", payload["receipts"][0]


def atomic_write_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(
        json.dumps(payload, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    temporary.replace(path)


def checkpoint_path(output_dir: Path, lesson: str) -> Path:
    return output_dir / "checkpoints" / f"{lesson}.json"


def load_checkpoint(path: Path) -> dict[str, Any] | None:
    if not path.is_file():
        return None
    payload = json.loads(path.read_text(encoding="utf-8"))
    if payload.get("lesson") != path.stem:
        raise RuntimeError(f"checkpoint lesson mismatch: {path}")
    return payload


def _stub_candidate(item: LessonInput, index: int) -> dict[str, str]:
    preferred = {
        "IM-G2-U2-L13": "count_all_when_count_on_available",
        "IM-G3-U1-L10": "repeat_group_size_by_itself",
        "IM-G3-U1-L15": "count_all_instead_of_known_fact",
    }
    wanted = preferred.get(item.lesson)
    return next(
        (candidate for candidate in item.candidates if candidate["deformation"] == wanted),
        item.candidates[0],
    )


def stub_transport(item: LessonInput, _messages: list[dict[str, str]], index: int) -> str:
    """Return deterministic source-shaped proposals; call two fabricates text."""
    preferred_lines = {
        "IM-G2-U2-L13": [377, 378, 379],
        "IM-G3-U1-L10": [326, 327, 329],
        "IM-G3-U1-L15": [221, 222, 223, 224],
    }
    if item.provenance_kind == "file":
        if item.guide_text is None or item.guide_relative is None:
            raise ValueError(f"file-backed lesson has no teacher guide: {item.lesson}")
        lines = item.guide_text.split("\n")
        line_numbers = preferred_lines.get(item.lesson)
        if not line_numbers:
            line_numbers = [next(i for i, line in enumerate(lines, 1) if line.strip())]
        fragments = [
            {"line": number, "text": lines[number - 1].strip()}
            for number in line_numbers
        ]
        source_kind = "activity_guidance"
        source = {
            "path": item.guide_relative,
            "fragments": fragments,
        }
    else:
        predicate = next(
            (
                name
                for name in (
                    "vision_lesson_purpose",
                    "vision_lesson_goal",
                    "vision_lesson_standard",
                )
                if item.digest_facts.get(name)
            ),
            None,
        )
        if predicate is None:
            raise ValueError(f"fact-backed lesson has no quotable digest fact: {item.lesson}")
        fact_text = item.digest_facts[predicate][0]
        fragments = [{"predicate": predicate, "text": fact_text[:240]}]
        source_kind = "vision_digest"
        source = {
            "kind": "fact",
            "path": str(VISION_DIGEST.relative_to(ROOT)),
            "fragments": fragments,
        }
    if index == 2:
        fragments[0]["text"] += " [fabricated]"
    candidate = _stub_candidate(item, index)
    explanations = {
        "IM-G2-U2-L13": (
            "Counting every seed instead of adding the named tens and ones to "
            "the represented starting quantity does not preserve the grouped add-on relation."
        ),
        "IM-G3-U1-L10": (
            "Repeating the group size by itself does not preserve both the number "
            "of groups and the size of each group named by the situation."
        ),
        "IM-G3-U1-L15": (
            "Counting every object from one discards the known-factor relation "
            "the activity asks students to use for the unknown factor."
        ),
    }
    curated = json.loads(CURATED_RECEIPTS.read_text(encoding="utf-8"))
    payload = {
        "schema": curated["schema"],
        "register": curated["register"],
        "receipts": [
            {
                "lesson": item.lesson,
                "intended_action": {
                    "operation": candidate["operation"],
                    "kind": candidate["productive"],
                },
                "alternative": candidate["deformation"],
                "material_incompatibility": explanations.get(
                    item.lesson,
                    "The selected alternative does not preserve the intended action named by the lesson.",
                ),
                "source_kind": source_kind,
                "source": source,
            }
        ],
    }
    return json.dumps(payload, ensure_ascii=False)


def print_prompt_preview(
    item: LessonInput, messages: list[dict[str, str]], preview_chars: int
) -> None:
    total = sum(len(message["content"]) for message in messages)
    print(f"  prompt built: messages={len(messages)} chars={total}")
    if preview_chars <= 0:
        return
    joined = "\n\n".join(
        f"{message['role'].upper()}:\n{message['content']}" for message in messages
    )
    print("  prompt preview:")
    for line in joined[:preview_chars].splitlines():
        print(f"    {line}")
    if len(joined) > preview_chars:
        print("    ...")


def summarize(
    records: list[dict[str, Any]],
    census: dict[str, Any],
    *,
    model: str,
    limit: int,
    output_dir: Path,
    schema: str,
    register: str,
    execution_stats: dict[str, Any],
) -> dict[str, Any]:
    accepted = [record["receipt"] for record in records if record["status"] == "accepted"]
    proposed = sum(record["proposed"] for record in records)
    reasons = Counter(
        record["reason"] for record in records if record["status"] == "refused"
    )
    denominator = len(records)
    projected = census["diagnostic_ready"] + len(accepted)
    pool_effect_by_grade: dict[str, dict[str, int]] = {}
    for record in records:
        grade = record["grade"]
        effect = pool_effect_by_grade.setdefault(
            grade,
            {
                "lessons": 0,
                "candidates_before": 0,
                "candidates_after": 0,
                "contract_mismatch": 0,
                "operation_unmatched": 0,
                "register_duplicate": 0,
                "alternative_not_executable": 0,
            },
        )
        effect["lessons"] += 1
        effect["candidates_before"] += record.get("candidate_count_before", 0)
        effect["candidates_after"] += record.get("candidate_count_after", 0)
        effect["contract_mismatch"] += sum(
            candidate.get("annotation") == "contract_mismatch"
            for candidate in record.get("candidate_annotations", [])
        )
        effect["operation_unmatched"] += len(record.get("operation_unmatched", []))
        effect["register_duplicate"] += len(record.get("register_duplicates", []))
        effect["alternative_not_executable"] += len(
            record.get("alternative_not_executable", [])
        )
    needs_vocabulary = [
        record["lesson"] for record in records if record["status"] == "needs_vocabulary"
    ]
    operation_unmatched_lessons = [
        record["lesson"]
        for record in records
        if record["status"] == "operation_unmatched"
    ]
    operation_unmatched_annotations = sum(
        len(record.get("operation_unmatched", [])) for record in records
    )
    register_duplicate_annotations = sum(
        len(record.get("register_duplicates", [])) for record in records
    )
    execution_annotations = sum(
        len(record.get("alternative_not_executable", [])) for record in records
    )
    execution_withheld_reasons = Counter(
        candidate["execution_evidence"]["reason_class"]
        for record in records
        for candidate in record.get("candidate_annotations", [])
        if candidate.get("annotation") == "alternative_not_executable"
    )
    register_exhausted_lessons = [
        record["lesson"] for record in records if record["status"] == "register_exhausted"
    ]
    execution_refusal_lessons = [
        record["lesson"]
        for record in records
        if record["status"] == "alternative_not_executable"
    ]
    uncovered_operations = Counter(
        candidate["operation"]
        for record in records
        for candidate in record.get("candidate_annotations", [])
        if candidate["operation"] not in CONTRACT_FILTER_OPERATIONS
    )
    accepted_payload = {
        "schema": schema,
        "register": register,
        "receipts": accepted,
    }
    atomic_write_json(output_dir / "accepted_receipts.json", accepted_payload)
    report = {
        "schema": "generated_negative_receipt_run_v1",
        "model": model,
        "limit": limit,
        "ledger_census": census,
        "completed_lessons": denominator,
        "proposed_receipts": proposed,
        "accepted": len(accepted),
        "refused": denominator - len(accepted),
        "acceptance_rate": {
            "numerator": len(accepted),
            "denominator": denominator,
            "value": len(accepted) / denominator if denominator else 0.0,
            "denominator_definition": "completed lessons in this run, including pre-transport source refusals",
        },
        "proposal_acceptance_rate": {
            "numerator": len(accepted),
            "denominator": proposed,
            "value": len(accepted) / proposed if proposed else 0.0,
        },
        "refusal_reasons": dict(reasons.most_common()),
        "operation_match_filter": {
            "version": RUN_VERSION,
            "join": (
                "task_action_operands head map over compiled_lesson_task_instance "
                "productive rows (formal/learner/activity_contract.pl)"
            ),
            "operation_unmatched_annotations": operation_unmatched_annotations,
            "lessons_with_flags": sum(
                bool(record.get("operation_unmatched")) for record in records
            ),
            "pre_transport_operation_unmatched": operation_unmatched_lessons,
            "disclosure": (
                "A flagged candidate names an operation no compiled productive "
                "task of its lesson carries, so no operand pair exists to run "
                "the named pair on (the task-179 25-receipt defect class). "
                "Flags are visible annotations; flagged candidates are withheld "
                "from the drafting prompt, never silently dropped."
            ),
        },
        "register_dedup_filter": {
            "version": RUN_VERSION,
            "dedup_key": "(lesson, alternative) -- the curated register's uniqueness key",
            "register_duplicate_annotations": register_duplicate_annotations,
            "lessons_with_duplicates": sum(
                bool(record.get("register_duplicates")) for record in records
            ),
            "pre_transport_register_exhausted": register_exhausted_lessons,
            "disclosure": (
                "A flagged candidate names an alternative the curated register "
                "already holds for its lesson. Defective receipts stay on the "
                "books with their failed warrant named, so a repair receipt "
                "must bind a different executable candidate. Flags are visible "
                "annotations; flagged candidates are withheld from the "
                "drafting prompt, never silently dropped."
            ),
        },
        "alternative_execution_filter": {
            "version": RUN_VERSION,
            "engine": "run_action_automaton/6 (knowledge/strategies/math/action_automata_registry.pl)",
            "join": (
                "compiled_lesson_task_instance productive rows through "
                "task_action_operands/4 (formal/learner/activity_contract.pl), "
                "one swipl batch per run"
            ),
            "time_limit_seconds": EXECUTION_TIME_LIMIT_SECONDS,
            "batch": execution_stats,
            "alternative_not_executable_annotations": execution_annotations,
            "withheld_reason_classes": dict(execution_withheld_reasons.most_common()),
            "lessons_with_flags": sum(
                bool(record.get("alternative_not_executable")) for record in records
            ),
            "pre_transport_alternative_not_executable": execution_refusal_lessons,
            "disclosure": (
                "Every candidate that reaches the drafting prompt has had its "
                "alternative executed on at least one of the lesson's own "
                "op-matching compiled operand pairs before drafting. A "
                "candidate whose alternative cannot execute anywhere is "
                "withheld with the attempted runs recorded -- the task-179 "
                "unregistered-alternative and automaton-refusal defect "
                "classes, stopped at draft time. Flags are visible "
                "annotations, never silent drops."
            ),
        },
        "candidate_contract_filter": {
            "version": RUN_VERSION,
            "mismatch_annotations": sum(
                candidate.get("annotation") == "contract_mismatch"
                for record in records
                for candidate in record.get("candidate_annotations", [])
            ),
            "needs_vocabulary": needs_vocabulary,
            "pool_effect_by_grade": dict(sorted(pool_effect_by_grade.items())),
            "covered_candidate_operations": sorted(CONTRACT_FILTER_OPERATIONS),
            "uncovered_candidate_operations": dict(sorted(uncovered_operations.items())),
            "uncovered_candidate_count": sum(uncovered_operations.values()),
            "disclosure": (
                "The contract filter currently evaluates only addition, subtraction, "
                "multiplication, and division computation domains. Candidates in other "
                "registry operation categories pass unfiltered."
            ),
        },
        "ratchet_if_accepted_merged": projected,
        "records": records,
        "gate_scope": {
            "establishes": (
                "v3 shape, supplied candidate identity, known lesson, mapped action, "
                "and verbatim provenance: either an existing file with an in-range "
                "line or an allowlisted fact predicate with a matching fact value"
            ),
            "does_not_establish": (
                "whether an authentic quotation is relevant enough to establish the "
                "claimed counterpossibility; human review is required before curation"
            ),
        },
    }
    atomic_write_json(output_dir / "run_report.json", report)
    return report


def print_report(report: dict[str, Any], output_dir: Path) -> None:
    census = report["ledger_census"]
    print(
        "Ledger census: "
        f"published={census['published']} "
        f"diagnostic_ready={census['diagnostic_ready']} "
        f"exactly_one_structured_negative={census['exactly_one_structured_negative']} "
        f"candidate_range={census['candidate_min']}..{census['candidate_max']} "
        f"candidate_zero={census['candidate_zero']}"
    )
    print(
        "Lessons lacking required receipts: "
        + ", ".join(
            f"{name}={count}" for name, count in census["lacking"].items()
        )
    )
    print(
        "Exactly-one target grades: "
        + ", ".join(f"{grade}={count}" for grade, count in census["grades"].items())
    )
    print(
        "Usable sources for target cohort: "
        f"file={census['guides_present']} "
        f"fact={census['digest_sources']} "
        f"missing={census['sources_missing']} "
        f"denominator={census['exactly_one_structured_negative']}"
    )
    print(
        "Grade 6-7 digest join: "
        f"{census['grade_6_7_in_digest']}/{census['grade_6_7_targets']}"
    )
    print(
        "Source-availability ceiling: "
        f"{census['usable_sources']}/"
        f"{census['exactly_one_structured_negative']} targets; "
        f"ratchet={census['all_receipts_projection']}/{census['published']} "
        "if every source-backed target yields an accepted receipt"
    )
    operation_filter = report["operation_match_filter"]
    print(
        "Operation-match filter: "
        f"flags={operation_filter['operation_unmatched_annotations']} "
        f"lessons_with_flags={operation_filter['lessons_with_flags']} "
        f"pre_transport={', '.join(operation_filter['pre_transport_operation_unmatched']) or 'none'}"
    )
    register_filter = report["register_dedup_filter"]
    print(
        "Register-dedup filter: "
        f"flags={register_filter['register_duplicate_annotations']} "
        f"lessons_with_duplicates={register_filter['lessons_with_duplicates']} "
        f"pre_transport={', '.join(register_filter['pre_transport_register_exhausted']) or 'none'}"
    )
    execution_filter = report["alternative_execution_filter"]
    print(
        "Alternative-execution filter: "
        f"flags={execution_filter['alternative_not_executable_annotations']} "
        f"reasons={execution_filter['withheld_reason_classes'] or 'none'} "
        f"pre_transport={', '.join(execution_filter['pre_transport_alternative_not_executable']) or 'none'}"
    )
    contract_filter = report["candidate_contract_filter"]
    print(
        "Candidate-contract filter: "
        f"mismatches={contract_filter['mismatch_annotations']} "
        f"needs_vocabulary={', '.join(contract_filter['needs_vocabulary']) or 'none'}"
    )
    print("Candidate pool effect by grade:")
    for grade, effect in contract_filter["pool_effect_by_grade"].items():
        print(
            f"  grade {grade}: candidates={effect['candidates_before']}"
            f"->{effect['candidates_after']} contract={effect['contract_mismatch']}"
            f" operation={effect['operation_unmatched']}"
            f" register={effect['register_duplicate']}"
            f" execution={effect['alternative_not_executable']}"
            f" lessons={effect['lessons']}"
        )
    print(
        "Candidate-contract coverage: "
        f"covered={','.join(contract_filter['covered_candidate_operations'])} "
        f"uncovered={contract_filter['uncovered_candidate_count']} "
        f"operations={contract_filter['uncovered_candidate_operations'] or 'none'}"
    )
    print("Per lesson:")
    for record in report["records"]:
        proposed = "proposed" if record["proposed"] else "not-proposed"
        print(
            f"  {record['lesson']}: {proposed} / {record['status']} / "
            f"{record['reason']}"
        )
    rate = report["acceptance_rate"]
    print(
        "Acceptance rate: "
        f"{rate['numerator']}/{rate['denominator']} "
        f"({rate['value']:.1%}); denominator=completed lessons"
    )
    proposal_rate = report["proposal_acceptance_rate"]
    print(
        "Proposal acceptance rate: "
        f"{proposal_rate['numerator']}/{proposal_rate['denominator']} "
        f"({proposal_rate['value']:.1%}); denominator=parsed proposals"
    )
    print("Refusal reasons:")
    if report["refusal_reasons"]:
        for reason, count in report["refusal_reasons"].items():
            print(f"  {count}  {reason}")
    else:
        print("  none")
    print(
        "Ratchet if accepted set were merged: "
        f"{report['ratchet_if_accepted_merged']}/"
        f"{census['published']}"
    )
    print(f"Accepted review file: {output_dir / 'accepted_receipts.json'}")
    print(f"Run report: {output_dir / 'run_report.json'}")
    print(
        "Gate limit: verbatim source validation does not establish relevance. "
        "Accepted receipts still require human review before curated merge."
    )


def run(args: argparse.Namespace) -> int:
    ledger = json.loads(LEDGER.read_text(encoding="utf-8"))
    curated = json.loads(CURATED_RECEIPTS.read_text(encoding="utf-8"))
    eligible = eligible_lessons(ledger)
    fact_index = _vision_fact_index()
    census = ledger_census(ledger, eligible, fact_index)
    contract_controls = contract_filter_controls()
    print(f"Candidate-contract controls: {contract_controls}")
    operation_controls = operation_filter_controls()
    print(f"Operation-match controls: {operation_controls}")
    register_keys = {
        (receipt["lesson"], receipt["alternative"])
        for receipt in curated["receipts"]
    }
    register_controls = register_dedup_controls(register_keys)
    print(f"Register-dedup controls: {register_controls}")
    execution_controls = execution_filter_controls()
    print(f"Alternative-execution controls: {execution_controls}")
    if args.limit < 1:
        raise ValueError("--limit must be at least 1")
    selected_pool = eligible
    if args.grades:
        wanted_grades = {
            grade.strip()
            for grade in args.grades.split(",")
            if grade.strip()
        }
        invalid_grades = wanted_grades - {"K", "1", "2", "3", "4", "5", "6", "7", "8"}
        if invalid_grades:
            raise ValueError(f"unsupported --grades values: {sorted(invalid_grades)}")
        selected_pool = [
            row for row in eligible if row["grade"] in wanted_grades
        ]
    selected = selected_pool[: args.limit]
    compiled_domains = _compiled_operand_domains()
    digest_domains = _digest_operand_domains()
    input_contracts = _contract_index()
    operation_index = _compiled_operation_index()
    pending_rows = []
    for row in selected:
        existing = load_checkpoint(checkpoint_path(args.output_dir, row["lesson"]))
        if existing is None or existing.get("run_version") != RUN_VERSION:
            pending_rows.append(row)
    probe_specs: list[tuple[str, str, str, str]] = []
    for row in pending_rows:
        register_usable, _ = filter_candidate_register_duplicates(
            row["negative_candidates"],
            lesson=row["lesson"],
            register_keys=register_keys,
        )
        probe_row = dict(row)
        probe_row["negative_candidates"] = register_usable
        operation_usable, _ = filter_candidate_operations(
            probe_row, operation_index=operation_index
        )
        probe_specs += [
            (row["lesson"], c["operation"], c["productive"], c["deformation"])
            for c in operation_usable
        ]
    if probe_specs:
        execution_catalog, execution_stats = run_execution_probes(probe_specs)
        print(
            f"Execution batch: {execution_stats['probed_candidates']} candidates "
            f"probed, {execution_stats['pair_runs']} operand-pair runs, "
            "head map verified"
        )
    else:
        execution_catalog = {}
        execution_stats = {
            "probed_candidates": 0,
            "pair_runs": 0,
            "head_map_verified": True,
            "note": (
                "no pending candidates required probing (checkpoints resumed); "
                "the controls batch verified the head map"
            ),
        }
    lesson_ids = {row["lesson"] for row in ledger["lessons"]}
    strategy_mappings = {
        row["lesson"]: {
            (
                candidate["operation"],
                candidate["productive"],
                candidate["mapping_origin"],
            )
            for candidate in row["negative_candidates"]
        }
        for row in ledger["lessons"]
    }

    if args.stub_transport:
        transport: Transport = stub_transport
        model = "stubbed-transport"
    else:
        llm = load_llm_module()
        llm.load_dotenv(ROOT)
        api_key = llm.require_api_key()
        api_url = llm.resolve_api_url()
        model = args.model or llm.resolve_model()
        ssl_ctx = llm.build_ssl_context()

        def transport(
            _item: LessonInput, messages: list[dict[str, str]], _index: int
        ) -> str:
            return call_reallms(
                llm,
                messages,
                api_key=api_key,
                api_url=api_url,
                model=model,
                ssl_ctx=ssl_ctx,
                timeout=args.timeout,
            )

    records: list[dict[str, Any]] = []
    for index, row in enumerate(selected, 1):
        checkpoint = checkpoint_path(args.output_dir, row["lesson"])
        existing = load_checkpoint(checkpoint)
        if existing is not None and existing.get("run_version") == RUN_VERSION:
            print(f"[{index}/{len(selected)}] {row['lesson']}: resumed checkpoint")
            records.append(existing)
            continue
        path = guide_path(row["lesson"])
        provenance_kind = drafting_provenance_kind(row["lesson"])
        register_usable, register_annotated = filter_candidate_register_duplicates(
            row["negative_candidates"],
            lesson=row["lesson"],
            register_keys=register_keys,
        )
        operation_row = dict(row)
        operation_row["negative_candidates"] = register_usable
        operation_usable, operation_annotated = filter_candidate_operations(
            operation_row,
            operation_index=operation_index,
        )
        execution_usable, execution_annotated = filter_candidate_executability(
            operation_usable,
            lesson=row["lesson"],
            execution_catalog=execution_catalog,
        )
        contract_row = dict(row)
        contract_row["negative_candidates"] = execution_usable
        filtered_candidates, contract_annotations = filter_candidate_contracts(
            contract_row,
            provenance_kind=provenance_kind,
            compiled_domains=compiled_domains,
            digest_domains=digest_domains,
            contract_index=input_contracts,
        )
        operation_iterator = iter(operation_annotated)
        execution_iterator = iter(execution_annotated)
        contract_iterator = iter(contract_annotations)
        candidate_annotations = []
        for candidate in register_annotated:
            if candidate.get("annotation") == "register_duplicate":
                candidate_annotations.append(candidate)
                continue
            operation_candidate = next(operation_iterator)
            if operation_candidate.get("annotation") == "operation_unmatched":
                candidate_annotations.append(operation_candidate)
                continue
            execution_candidate = next(execution_iterator)
            if execution_candidate.get("annotation") == "alternative_not_executable":
                candidate_annotations.append(execution_candidate)
                continue
            candidate_annotations.append(next(contract_iterator))
        operation_unmatched = [
            {
                "operation": candidate["operation"],
                "productive": candidate["productive"],
                "deformation": candidate["deformation"],
                "reason": candidate["operation_evidence"]["reason"],
            }
            for candidate in candidate_annotations
            if candidate.get("annotation") == "operation_unmatched"
        ]
        register_duplicates = [
            {
                "operation": candidate["operation"],
                "productive": candidate["productive"],
                "deformation": candidate["deformation"],
                "reason": candidate["register_evidence"]["reason"],
            }
            for candidate in candidate_annotations
            if candidate.get("annotation") == "register_duplicate"
        ]
        alternative_not_executable = [
            {
                "operation": candidate["operation"],
                "productive": candidate["productive"],
                "deformation": candidate["deformation"],
                "reason_class": candidate["execution_evidence"]["reason_class"],
                "reason": candidate["execution_evidence"]["reason"],
            }
            for candidate in candidate_annotations
            if candidate.get("annotation") == "alternative_not_executable"
        ]
        record_fields = {
            "run_version": RUN_VERSION,
            "lesson": row["lesson"],
            "title": row["name"],
            "grade": row["grade"],
            "candidate_count_before": len(row["negative_candidates"]),
            "candidate_count_after": len(filtered_candidates),
            "candidate_annotations": candidate_annotations,
            "operation_unmatched": operation_unmatched,
            "register_duplicates": register_duplicates,
            "alternative_not_executable": alternative_not_executable,
        }
        if row["negative_candidates"] and not filtered_candidates:
            operation_flags = len(operation_unmatched)
            register_flags = len(register_duplicates)
            execution_flags = len(alternative_not_executable)
            contract_flags = sum(
                candidate.get("annotation") == "contract_mismatch"
                for candidate in candidate_annotations
            )
            flag_parts = ", ".join(
                f"{count} {name}"
                for name, count in (
                    ("alternative_not_executable", execution_flags),
                    ("register_duplicate", register_flags),
                    ("operation_unmatched", operation_flags),
                    ("contract_mismatch", contract_flags),
                )
                if count
            )
            if execution_flags:
                status = "alternative_not_executable"
                reason = (
                    f"no candidate survives the draft-time filters ({flag_parts}); "
                    "drafting would mint a receipt no automaton run can bind"
                )
            elif register_flags and not operation_flags and not contract_flags:
                status = "register_exhausted"
                reason = (
                    "every candidate's alternative is already held by the curated "
                    "register for this lesson; a repair needs a new executable "
                    "candidate the registry does not yet supply"
                )
            elif operation_flags and not contract_flags and not register_flags:
                status = "operation_unmatched"
                lesson_operations = operation_index.get(
                    row["lesson"], {"operations": set()}
                )["operations"]
                reason = (
                    "the lesson's compiled productive tasks carry no operation "
                    "the task_action_operands join recognizes"
                    if not lesson_operations
                    else "no compiled productive task of the lesson carries any candidate's operation"
                )
            elif contract_flags and not operation_flags and not register_flags:
                status = "needs_vocabulary"
                reason = "all registry candidates are contract_mismatch for the lesson operand domain"
            else:
                status = "no_usable_candidates"
                reason = f"no usable candidates: {flag_parts}"
            record = {
                **record_fields,
                "proposed": False,
                "status": status,
                "reason": reason,
                "receipt": None,
                "raw_response": None,
            }
            atomic_write_json(checkpoint, record)
            records.append(record)
            print(f"[{index}/{len(selected)}] {row['lesson']}: {status} before transport")
            continue
        if not path.is_file() and not _drafting_facts(fact_index, row["lesson"]):
            record = {
                **record_fields,
                "proposed": False,
                "status": "refused",
                "reason": (
                    "no usable lesson source: teacher guide missing and "
                    "no drafting-allowlisted vision-digest facts"
                ),
                "receipt": None,
                "raw_response": None,
            }
            atomic_write_json(checkpoint, record)
            records.append(record)
            print(f"[{index}/{len(selected)}] {row['lesson']}: refused before transport")
            continue
        filtered_row = dict(row)
        filtered_row["negative_candidates"] = filtered_candidates
        item = lesson_input(filtered_row, fact_index)
        messages = build_messages(
            item,
            curated["schema"],
            curated["register"],
        )
        print(f"[{index}/{len(selected)}] {item.lesson} — {item.title}")
        print_prompt_preview(item, messages, args.prompt_preview_chars)
        try:
            response = transport(item, messages, index)
        except RuntimeError as exc:
            record = {
                **record_fields,
                "lesson": item.lesson,
                "title": item.title,
                "proposed": False,
                "status": "refused",
                "reason": f"transport failure: {exc}",
                "receipt": None,
                "raw_response": None,
            }
        else:
            payload, parse_fault = parse_proposal(response)
            if payload is None:
                record = {
                    **record_fields,
                    "lesson": item.lesson,
                    "title": item.title,
                    "proposed": False,
                    "status": "refused",
                    "reason": parse_fault or "no proposal",
                    "receipt": None,
                    "raw_response": response,
                }
            else:
                accepted, reason, receipt = gate_proposal(
                    item,
                    payload,
                    lesson_ids=lesson_ids,
                    strategy_mappings=strategy_mappings,
                    schema=curated["schema"],
                    register=curated["register"],
                )
                record = {
                    **record_fields,
                    "lesson": item.lesson,
                    "title": item.title,
                    "proposed": True,
                    "status": "accepted" if accepted else "refused",
                    "reason": reason,
                    "receipt": receipt,
                    "raw_response": response,
                }
        atomic_write_json(checkpoint, record)
        records.append(record)
        print(f"  result: {record['status']} — {record['reason']}")

    report = summarize(
        records,
        census,
        model=model,
        limit=args.limit,
        output_dir=args.output_dir,
        schema=curated["schema"],
        register=curated["register"],
        execution_stats=execution_stats,
    )
    print_report(report, args.output_dir)
    return 0


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--limit",
        type=int,
        default=DEFAULT_LIMIT,
        help=f"maximum lessons to process (default: {DEFAULT_LIMIT})",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=DEFAULT_OUTPUT,
        help=f"checkpoint and review output directory (default: {DEFAULT_OUTPUT})",
    )
    parser.add_argument(
        "--model",
        help="REALLMS model id (default: REALLMS_MODEL from the repo .env)",
    )
    parser.add_argument(
        "--grades",
        help="optional comma-separated grade filter applied before --limit",
    )
    parser.add_argument("--timeout", type=int, default=600)
    parser.add_argument(
        "--stub-transport",
        action="store_true",
        help="use deterministic local proposals without loading credentials or using the network",
    )
    parser.add_argument(
        "--prompt-preview-chars",
        type=int,
        default=0,
        help="print this many characters of each built prompt",
    )
    return parser.parse_args(argv)


if __name__ == "__main__":
    try:
        raise SystemExit(run(parse_args(sys.argv[1:])))
    except (OSError, RuntimeError, ValueError) as exc:
        sys.stderr.write(f"error: {exc}\n")
        raise SystemExit(1)
